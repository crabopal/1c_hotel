// -----------------------------------------------------------------------------
Procedure pmRun(pIsInteractive = False) Export
	vEmployee = SessionParameters.CurrentUser;

	vHOSTHttpAddress = TrimAll(Constants.InfoBaseHostAddress.Get());
	If Right(vHOSTHttpAddress, 1) <> "/" Then
		vHOSTHttpAddress = vHOSTHttpAddress + "/";
	EndIf;
	
	vSendEMailNotification = True;
	If IsBlankString(EMail) Then
		vSendEMailNotification = False;
	EndIf;
	If Not ValueIsFilled(vEmployee) Then
		vSendEMailNotification = False;
	EndIf;
	
	vDeletedTagsMessage = "";
	vDeletedTagsCount = 0;
	
	// Get list of tags to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Tags.Ref,
	|	Tags.Code AS Code,
	|	Tags.Description AS Description,
	|	Tags.SegmentationAlgorithmType AS AlgorithmType
	|FROM
	|	Catalog.Tags AS Tags
	|WHERE
	|	NOT Tags.DeletionMark
	|	AND NOT Tags.IsManual
	|	AND (&qAllTags
	|			OR NOT &qAllTags
	|				AND Tags.Ref = &qTag)
	|
	|ORDER BY
	|	Code";
	vQry.SetParameter("qAllTags", Not ValueIsFilled(Tag));
	vQry.SetParameter("qTag", Tag);
	vQry.SetParameter("qEmptyString", "");
	vTags = vQry.Execute().Unload();
	For Each vTagsRow In vTags Do
		TagToCheck = vTagsRow.Ref;
		TagClients = New ValueList();
		vTagClients = New ValueTable();
		
		vMessage = "";
		
		// Execute algorithm
		If ValueIsFilled(TagToCheck.SegmentationAlgorithmType) Then
			vSearchQry = New Query();
			If TagToCheck.SegmentationAlgorithmType.Predefined Then
				vSearchQry.Text = Catalogs.AutoSegmentationAlgorithms.GetPredefinedQuery(TagToCheck.SegmentationAlgorithmType);
			EndIf;
			If Not IsBlankString(TagToCheck.SegmentationAlgorithmType.ExternalQueryText) Then
				vSearchQry.Text = TrimAll(TagToCheck.SegmentationAlgorithmType.ExternalQueryText);
			EndIf;
			For Each vQParametersRow In TagToCheck.Parameters Do
				vSearchQry.SetParameter(TrimAll(vQParametersRow.Parameter), vQParametersRow.Value);
			EndDo;
			vSearchQry.SetParameter("qTag", TagToCheck);
			vTagClients = vSearchQry.Execute().Unload();
		Else
			Continue;
		EndIf;
		
		// Fill list of new clients
		vAllTagClients = New ValueList();
		For Each vTagClientsRow In vTagClients Do
			If ValueIsFilled(vTagClientsRow.Client) Then
				vAllTagClients.Add(vTagClientsRow.Client);
				If vTagClientsRow.Tag = Null Then
					TagClients.Add(vTagClientsRow.Client);
				EndIf;
			EndIf;
		EndDo;
		
		// Process clients being found
		If TagClients.Count() > 0 Then
			For Each vTagClientsItem In TagClients Do
				vClientRef = vTagClientsItem.Value;
				
				vRcdMgr = InformationRegisters.ClientTags.CreateRecordManager();
				vRcdMgr.Client = vClientRef;
				vRcdMgr.Tag = TagToCheck;
				vRcdMgr.Write(True);
				
				WriteLogEvent(NStr("en='Tag autoassigned to client'; ru='Автоматическое добавление тега клиенту'; de='Automatisch hinzufügen Client-Tag'"), EventLogLevel.Information, vClientRef.Metadata(), vClientRef, TrimAll(TagToCheck));
				
				If vSendEMailNotification Then
					FillTagAssignmentEMailMessage(vClientRef, TagToCheck, vMessage, vHOSTHttpAddress);
				EndIf;
			EndDo;
		EndIf;
		
		// Check if we have to remove this tag from some clients because some conditions has changed like reservation cancellation e.t.c.
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ClientTags.Client,
		|	ClientTags.Tag
		|FROM
		|	InformationRegister.ClientTags AS ClientTags
		|WHERE
		|	ClientTags.Tag = &qTag
		|	AND NOT ClientTags.Client IN (&qTagClientsList)
		|
		|ORDER BY
		|	ClientTags.Client.FullName";
		vQry.SetParameter("qTag", TagToCheck);
		vQry.SetParameter("qTagClientsList", vAllTagClients);
		vClients = vQry.Execute().Unload();
		For Each vClientsRow In vClients Do
			vClientRef = vClientsRow.Client;
			
			vRcdMgr = InformationRegisters.ClientTags.CreateRecordManager();
			vRcdMgr.Client = vClientRef;
			vRcdMgr.Tag = TagToCheck;
			vRcdMgr.Read();
			If vRcdMgr.Selected() Then
				vRcdMgr.Client = vClientRef;
				vRcdMgr.Tag = TagToCheck;
				vRcdMgr.Delete();
				
				WriteLogEvent(NStr("en='Tag autoremoved from client'; ru='Автоматическое удаление тега у клиента'; de='Automatisch entfernen Client-Tag'"), EventLogLevel.Information, vClientRef.Metadata(), vClientRef, TrimAll(TagToCheck));
				
				vDeletedTagsCount = vDeletedTagsCount + 1;
				If vSendEMailNotification Then
					FillDeletedTagsEMailMessage(vClientRef, TagToCheck, vDeletedTagsMessage, vHOSTHttpAddress);
				EndIf;
			EndIf;
		EndDo;
		
		// Send tag assignment message
		If vSendEMailNotification And Not IsBlankString(vMessage) Then
			SendTagAssignmentEMail(vMessage, TagToCheck, TagClients.Count());
		EndIf;
	EndDo; // By tags
	
	// Send tags removed message
	If vSendEMailNotification And Not IsBlankString(vDeletedTagsMessage) Then
		SendDeletedTagsEMail(vDeletedTagsMessage, vDeletedTagsCount);
	EndIf;
	
	// Process tags marked for deletion
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientTags.Client,
	|	ClientTags.Tag
	|FROM
	|	InformationRegister.ClientTags AS ClientTags
	|WHERE
	|	ClientTags.Tag.DeletionMark
	|
	|ORDER BY
	|	ClientTags.Client.FullName";
	vClientTagsToDelete = vQry.Execute().Unload();
	For Each vClientTagsToDeleteRow In vClientTagsToDelete Do
		vRcdMgr = InformationRegisters.ClientTags.CreateRecordManager();
		vRcdMgr.Client = vClientTagsToDeleteRow.Client;
		vRcdMgr.Tag = vClientTagsToDeleteRow.Tag;
		vRcdMgr.Read();
		If vRcdMgr.Selected() Then
			vRcdMgr.Client = vClientTagsToDeleteRow.Client;
			vRcdMgr.Tag = vClientTagsToDeleteRow.Tag;
			vRcdMgr.Delete();
		EndIf;
	EndDo;
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure FillTagAssignmentEMailMessage(pClient, pTag, pMessage, pHostHTTPAddress)
	pMessage = pMessage + ?(IsBlankString(pMessage), "", "<br>") + 
	           "<a href='" + pHOSTHttpAddress + "#" + GetURL(pClient) + "'>" + TrimAll(pClient.FullName) + " (" + TrimAll(pClient.Code) + ")</a>";
EndProcedure // FillTagAssignmentEMailMessage

// -----------------------------------------------------------------------------
Procedure SendTagAssignmentEMail(pMessage, pTag, pCount)
	vEmployee = SessionParameters.CurrentUser;
	
	// Add ReplyTo address
	vReplyToEMail = New Array;
	If Not IsBlankString(vEmployee.ReplyToEMail) Then
		vEMailsList = cmParseEMailAddress(TrimAll(vEmployee.ReplyToEMail));
		For Each vEMailItem In vEMailsList Do
			vReplyToEMail.Add(TrimAll(vEMailItem.Value));
		EndDo;
	EndIf;  
	
	// Add to address
	vToEMail = New Array;
	vEMailsList = cmParseEMailAddress(EMail);
	For Each vEMailItem In vEMailsList Do
		vToEMail.Add(TrimAll(vEMailItem.Value));
	EndDo;  
	
	// Add Bcc address  
	vBccEMail = New Array;
	If Not IsBlankString(vEmployee.BccEMail) Then
		vEMailsList = cmParseEMailAddress(vEmployee.BccEMail);
		For Each vEMailItem In vEMailsList Do
			vBccEMail.Add(TrimAll(vEMailItem.Value));
		EndDo;
	EndIf;
	
	// Build message subject and text
	vSubject = NStr("en='Tag autoassignment: '; ru='Автоматическое добавление тега: '; de='Automatisch hinzufügen Client-Tag: '") + TrimAll(pTag);
	
	vMessage = "<HTML>" + Chars.LF + "<BODY>" + Chars.LF + NStr("en='Hi, '; ru='Здравствуйте, '; de='Hi, '") + "<br>" + "<br>";
	vMessage = vMessage + NStr("en='Tag ""'; ru='Тег ""'; de='Tag ""'") + TrimAll(pTag) + 
	           NStr("en='"" was assigned to '; ru='"" был установлен у '; de='"" auf '") + pCount + NStr("en=' clients:'; ru=' клиентов:'; de=' Kunde gesetzt wurde:'") + "<br>" + "<br>";
	vMessage = vMessage + pMessage + "<br>" + "<br>" + "--" + "<br>" + "1C:Hotel" + Chars.LF + "</BODY>" + Chars.LF + "</HTML>";
		
	EMail.Send(vEmployee, TrimAll(vEmployee), TrimAll(vEmployee.EMail), TrimAll(vSubject), TrimAll(vMessage), , , , , , , , vToEMail, vReplyToEMail, , vBccEMail); 
EndProcedure // SendTagAssignmentEMail

// -----------------------------------------------------------------------------
Procedure FillDeletedTagsEMailMessage(pClient, pTag, pMessage, pHostHTTPAddress)
	pMessage = pMessage + ?(IsBlankString(pMessage), "", "<br>") + 
	           "<a href='" + pHOSTHttpAddress + "#" + GetURL(pClient) + "'>" + TrimAll(pClient.FullName) + " (" + TrimAll(pClient.Code) + ")</a>" + " - " + TrimAll(pTag);
EndProcedure // FillDeletedTagsEMailMessage

// -----------------------------------------------------------------------------
Procedure SendDeletedTagsEMail(pMessage, pCount)
	vEmployee = SessionParameters.CurrentUser;
	
	// Add ReplyTo address
	vReplyToEMail = New Array;
	If Not IsBlankString(vEmployee.ReplyToEMail) Then
		vEMailsList = cmParseEMailAddress(TrimAll(vEmployee.ReplyToEMail));
		For Each vEMailItem In vEMailsList Do
			vReplyToEMail.Add(TrimAll(vEMailItem.Value));
		EndDo;
	EndIf;
	
	// Add to address
	vToEMail = New Array;
	vEMailsList = cmParseEMailAddress(EMail);
	For Each vEMailItem In vEMailsList Do
		vToEMail.Add(TrimAll(vEMailItem.Value));
	EndDo; 
	
	// Add Bcc address
	vBccEMail = New Array;
	If Not IsBlankString(vEmployee.BccEMail) Then
		vEMailsList = cmParseEMailAddress(vEmployee.BccEMail);
		For Each vEMailItem In vEMailsList Do
			vBccEMail.Add(TrimAll(vEMailItem.Value));
		EndDo;
	EndIf;
	
	// Build message subject and text
	vSubject = NStr("en='Tags autoremoved'; ru='Автоматическое удаление тегов'; de='Automatisch Client-Tagen entfernen'");
	
	vMessage = "<HTML>" + Chars.LF + "<BODY>" + Chars.LF + NStr("en='Hi, '; ru='Здравствуйте, '; de='Hi, '") + "<br>" + "<br>";
	vMessage = vMessage + NStr("en='The following tags were removed from clients ('; ru='Ниже приведен список удаленных тегов ('; de='Die folgenden Tags wurden von Clients entfernt ('") + pCount + NStr("en=' cases):'; ru=' тегов):'; de=' Tagen):'") + "<br>" + "<br>";
	vMessage = vMessage + pMessage + "<br>" + "<br>" + "--" + "<br>" + "1C:Hotel" + Chars.LF + "</BODY>" + Chars.LF + "</HTML>";
	 
	EMail.Send(vEmployee, TrimAll(vEmployee), TrimAll(vEmployee.EMail), TrimAll(vSubject), TrimAll(vMessage), , , , , , , , vToEMail, vReplyToEMail, , vBccEMail);
EndProcedure // SendDeletedTagsEMail

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues