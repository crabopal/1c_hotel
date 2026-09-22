
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vEMails = ""; 
	vFileName = "";
	If Parameters.Property("SelHotel") Then
		SelHotel = Parameters.SelHotel;
	EndIf;          
	If Not ValueIsFilled(SelHotel) Then
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Parameters.Property("SelDocument") Then
		SelDocument = Parameters.SelDocument;
	EndIf; 
	If Parameters.Property("SelLanguage") Then
		SelLanguage = Parameters.SelLanguage;
	EndIf; 
	If Not ValueIsFilled(SelLanguage) Then                                               
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	If Parameters.Property("SelEMails") Then
		If ValueIsFilled(Parameters.SelEMails) Then
			SelTo = SelTo + Parameters.SelEMails + ";"; 
			vEMails = Parameters.SelEMails; 
		EndIf;
	EndIf;
	If Parameters.Property("SelMessageSubject") Then
		SelSubject = TrimAll(Parameters.SelMessageSubject);	
	EndIf;  
	vMessageText = "";
	If Parameters.Property("SelMessageText") Then
		vMessageText = TrimAll(Parameters.SelMessageText); 
	EndIf;
	If ValueIsFilled(SelDocument) Then
		FillEMailParameters(SelSubject, vMessageText, SelDocument); 
	EndIf;
	If Parameters.Property("IsHTML") And Parameters.IsHTML Then
		SelHTMLText.SetHTML(vMessageText, New Structure());		
	Else
		SelHTMLText.SetFormattedString(New FormattedString(vMessageText));
	EndIf;
	If Parameters.Property("SelGuestGroup") Then
		SelGuestGroup = Parameters.SelGuestGroup;
	EndIf;
	If Parameters.Property("SelToList") Then
		If Parameters.SelToList.Count() > 0 Then 
			SelToList = Parameters.SelToList;
			If Not ValueIsFilled(TrimAll(SelTo)) Then
				SelTo = SelTo + SelToList.Get(0).Value + ";";	
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("SelFile") Then
		If TypeOf(Parameters.SelFile) = Type("Structure") Then 
			vAttachment = Attachments.Add();
			vAttachment.Id = 1;
			If Parameters.SelFile.Property("FileName") Then
				vAttachment.FileName = Parameters.SelFile.FileName;
				vFileName = Parameters.SelFile.FileName;
			EndIf;
			If Parameters.SelFile.Property("FullFileNameAtClient") Then
				vAttachment.FullFileNameAtClient = Parameters.SelFile.FullFileNameAtClient;
			EndIf;
			If Parameters.SelFile.Property("FullFileNameAtServer") Then
				vAttachment.FullFileNameAtServer = Parameters.SelFile.FullFileNameAtServer;
			EndIf;
			If Parameters.SelFile.Property("CheckRemoveAtClient") Then
				vAttachment.CheckRemoveAtClient = Parameters.SelFile.CheckRemoveAtClient;
			EndIf;
			If Parameters.SelFile.Property("CheckRemoveAtServer") Then
				vAttachment.CheckRemoveAtServer = Parameters.SelFile.CheckRemoveAtServer;
			EndIf;
			vAttachment.CheckPredefined = True;
		ElsIf TypeOf(Parameters.SelFile) = Type("Array") Then
			vNumber = 1;
			For Each vFile In Parameters.SelFile Do
				vAttachment = Attachments.Add();
				vAttachment.Id = vNumber;
				If vFile.Property("FileName") Then
					vAttachment.FileName = vFile.FileName;
				EndIf;
				If vFile.Property("FullFileNameAtClient") Then
					vAttachment.FullFileNameAtClient = vFile.FullFileNameAtClient;
				EndIf;
				If vFile.Property("FullFileNameAtServer") Then
					vAttachment.FullFileNameAtServer = vFile.FullFileNameAtServer;
				EndIf;
				If vFile.Property("CheckRemoveAtClient") Then
					vAttachment.CheckRemoveAtClient = vFile.CheckRemoveAtClient;
				EndIf;
				If vFile.Property("CheckRemoveAtServer") Then
					vAttachment.CheckRemoveAtServer = vFile.CheckRemoveAtServer;
				EndIf;
				vAttachment.CheckPredefined = True;
				vNumber = vNumber + 1;
			EndDo;
		EndIf;
	EndIf;
	SelEmployees = SessionParameters.CurrentUser;
	If Not ValueIsFilled(SelEmployees) Then
		If ValueIsFilled(vFileName) And ValueIsFilled(vEMails) Then
			vError = NStr("ru = 'Невозможно отправить файл " + TrimAll(vFileName) + " по электронной почте на адрес " + TrimAll(vEMails) + "! Не определен текущий пользователь!'; 
			              |de = 'Unable to send file " + TrimAll(vFileName) + " by e-mail to " + TrimAll(vEMails) + "! Current user is not defined!'; 
			              |en = 'Unable to send file " + TrimAll(vFileName) + " by e-mail to " + TrimAll(vEMails) + "! Current user is not defined!'");
		Else
			vError = NStr("en = 'Current user is not defined!'; de = 'Current user is not defined!'; ru = 'Не определен текущий пользователь!'");	
		EndIf;
		WriteLogEvent(NStr("en = 'InternetMail.SendFile'; de = 'InternetMail.SendFile'; ru = 'ЭлектроннаяПочта.ОтправитьФайл'"), EventLogLevel.Warning, , , vError);
		ErrorMessage = vError;
		IsError = True;
	EndIf;  
	FillExternalSystem();  
	FillSMSTemplates();
	If Parameters.Property("SelSMSTemplates") Then
		SelSMSTemplates = Parameters.SelSMSTemplates;	
	EndIf;
	If ValueIsFilled(SelSMSTemplates) And Not ValueIsFilled(SelExternalSystem) Then
		SelExternalSystem = InformationRegisters.ExternalSystemIntegrationData.GetExternalSystem("SMSTemplates", "SMSTemplates", SelSMSTemplates);	
	EndIf;
	If Not IsError Then 
		If Parameters.Property("SelSenderName") Then
			SelSenderName = Parameters.SelSenderName;
		EndIf;
		If Not ValueIsFilled(SelSenderName) Then
			SelSenderName = SelEmployees.GetObject().pmGetEmployeeDescription(SelLanguage);	
		EndIf;
		If ValueIsFilled(SelEmployees.BccEMail) Then
			SelBCC = SelBCC + SelEmployees.BccEMail + ";";	
		EndIf;
		vDecorationSendArray = New Array();
		vDecorationSendArray.Add(NStr("en = 'From whom: '; de = 'Von wem: '; ru = 'От кого: '"));
		If ValueIsFilled(SelSenderName) Then 
			vDecorationSendArray.Add(New FormattedString(" " + SelSenderName, tcCommonFunctionOnClientServer.FontConstructor(, , True)));
			If ValueIsFilled(SelEmployees.EMail) Then
				Items.DecorationSend.ToolTip = SelEmployees.EMail;
			EndIf;
		Else
			If ValueIsFilled(SelEmployees.EMail) Then
				vDecorationSendArray.Add(New FormattedString(" " + SelEmployees.EMail, tcCommonFunctionOnClientServer.FontConstructor(, , True)));
			EndIf;
		EndIf;
		vDecorationSendText = New FormattedString(vDecorationSendArray);
		Items.DecorationSend.Title =  vDecorationSendText; 
		GetExternalHTMLText();
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Not IsError Then
		CheckCompliance();
		GenerateAttachments();
		SelToList = RemoveDuplicates(SelToList);
		ValidAddress(Items.SelTo);
		ValidAddress(Items.SelCC);
		ValidAddress(Items.SelBCC);
	Else
		AfterCompletionOperation(ErrorMessage);
	EndIf;
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If ValueIsFilled(pSelectedValue) Then
		SelTo = TrimAll(SelTo) + TrimAll(tcOnServer.cmGetAttributeByRef(pSelectedValue, "EMail")) + ";";		
	EndIf;
	ValidAddress(Items.SelTo);
EndProcedure // ChoiceProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing) 
	// ACC:561-off
	vItemsArray = Attachments.FindRows(New Structure("CheckPredefined", True));
	If vItemsArray.Count() > 0 Then
		For Each vFile In vItemsArray Do
			If ValueIsFilled(vFile.FullFileNameAtClient) And vFile.CheckRemoveAtClient Then 
				vFileCheck = New File(vFile.FullFileNameAtClient);
				If tcCommonFunctionOnClientServer.cmExists(vFileCheck) Then 
					DeleteFiles(vFile.FullFileNameAtClient); 
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If ValueIsFilled(SelDirectoryArClient) Then
		DeleteFiles(Left(SelDirectoryArClient, StrLen(SelDirectoryArClient) - 1)); 
	EndIf; 
	If Not pExit Then
		BeforeCloseAtServer();
	EndIf;             
	// ACC:561-on
EndProcedure // BeforeClose

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SelExternalSystemOnChange(pItem)
	GetExternalHTMLText();	
EndProcedure // SelExternalSystemOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelSMSTemplatesOnChange(pItem)
	GetExternalHTMLText(True);
EndProcedure // SelSMSTemplatesOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelExternalSystemClearing(pItem, pStandardProcessing)
	GetExternalHTMLText();	
EndProcedure // SelExternalSystemClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure SelToStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	FillSelToFromDocuments();
EndProcedure // SelToStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure AddressOnChange(pItem)
	ValidAddress(pItem);
EndProcedure // AddressOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelExternalHTMLTextOnClick(pItem, pEventData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelExternalHTMLTextOnClick

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AddPicture(pCommand)
	vParams = tcOnClientWorkWithFiles.cmGetEmptyParamsForLoadFiles();
	vParams.Filter = tcOnClientWorkWithFiles.cmGetChooseFilterForAllPictures();
	vParams.NotifyDescription = New NotifyDescription("SetImageToFormattedDocument", ThisObject); 
	tcOnClientWorkWithFiles.LoadFile(vParams);
EndProcedure // AddPicture

// --------------------------------------------------------------------------------
&AtClient
Procedure VisibleBCC(pCommand)
	Items.VisibleBCC.Visible = False;
	Items.SelBCC.Visible = True;
EndProcedure // VisibleBCC

// --------------------------------------------------------------------------------
&AtClient
Procedure VisibleCC(pCommand)
	Items.VisibleCC.Visible = False;
	Items.SelCC.Visible = True;
EndProcedure // VisibleCC

// --------------------------------------------------------------------------------
&AtClient
Procedure AddAttachments(pCommand)
	BeginAttachingFileSystemExtension(New NotifyDescription("AddAttachmentsFileSystemExtensionResult", ThisObject));	
EndProcedure // AddAttachments

// --------------------------------------------------------------------------------
&AtClient
Procedure RemoveAttachment(pCommand)           
	// ACC:561-off
	vID = Number(StrReplace(pCommand.Name, "Remove", ""));
	vItemsArray = Attachments.FindRows(New Structure("Id", vID));
	If vItemsArray.Count() > 0 Then
		If Not vItemsArray[0].CheckPredefined Then
			If vItemsArray[0].CheckRemoveAtClient Then
				vFile = New File(vItemsArray[0].FullFileNameAtClient);
				If tcCommonFunctionOnClientServer.cmExists(vFile) Then
					DeleteFiles(vItemsArray[0].FullFileNameAtClient);
				EndIf;
			EndIf;
			If vItemsArray[0].CheckRemoveAtServer Then
				DeleteFileAtServer(vItemsArray[0].FullFileNameAtServer);
			EndIf;
			Attachments.Delete(Attachments.IndexOf(vItemsArray[0]));
		EndIf;
	EndIf;                 
	// ACC:561-on
	GenerateAttachments();
EndProcedure // RemoveAttachment

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenAttachment(pCommand)
	vID = Number(StrReplace(pCommand.Name, "Open", ""));
	vItemsArray = Attachments.FindRows(New Structure("Id", vID));
	If vItemsArray.Count() > 0 Then 
		BeginRunningApplication(New NotifyDescription, TrimAll(vItemsArray[0].FullFileNameAtClient)); 
	EndIf;
EndProcedure // OpenAttachment
 
// --------------------------------------------------------------------------------
&AtClient
Procedure RemoveAllAttachments(pCommand)
	vItemsArray = Attachments.FindRows(New Structure("CheckPredefined", False)); 
	If vItemsArray.Count() > 0 Then
		For Each vAttachment In vItemsArray Do  
			If Not vAttachment.CheckPredefined Then
				If vAttachment.CheckRemoveAtClient Then
					DeleteFiles(vAttachment.FullFileNameAtClient); // ACC:561
				EndIf;
				If vAttachment.CheckRemoveAtServer Then
					DeleteFileAtServer(vAttachment.FullFileNameAtServer);
				EndIf;
				Attachments.Delete(Attachments.IndexOf(vAttachment));
			EndIf;
		EndDo;
	EndIf;
	GenerateAttachments();
EndProcedure // RemoveAllAttachments

// --------------------------------------------------------------------------------
&AtClient
Procedure Send(pCommand)
	vResult = SendAtServer();
	If vResult.Result Then
		ShowMessageBox(New NotifyDescription("AfterCompletionOperation", ThisObject, vResult.ErrorText), NStr("ru='Электронное письмо было успешно отправлено!';de='Die E-Mail wurde erfolgreich verschickt!';en='E-Mail was successfully sent!'"));	
	Else
		ShowMessageBox(, vResult.ErrorText);	
	EndIf;
EndProcedure // Send

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillSMSTemplates()
	Items.SelSMSTemplates.ChoiceList.Clear();
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	SMSTemplates.Ref AS Ref,
	|	SMSTemplates.Description AS Description
	|FROM
	|	Catalog.SMSTemplates AS SMSTemplates
	|WHERE
	|	NOT SMSTemplates.DeletionMark
	|	AND NOT SMSTemplates.IsFolder
	|	AND SMSTemplates.ObjectType IN (&qObjectTypes)"; 
	vObjectTypes = New Array;
	If ValueIsFilled(SelDocument) Then
		vObjectTypes.Add(Documents[SelDocument.Metadata().Name].EmptyRef());
	EndIf;
	vObjectTypes.Add(Undefined);
	vQ.SetParameter("qObjectTypes", vObjectTypes);   	
	vResult = vQ.Execute().Unload();
	For Each vRow In vResult Do 
		Items.SelSMSTemplates.ChoiceList.Add(vRow.Ref, cmNStr(vRow.Description, SelLanguage));
	EndDo;
EndProcedure // FillSMSTemplates

// --------------------------------------------------------------------------------
&AtServer
Procedure FillExternalSystem()
	Items.SelExternalSystem.ChoiceList.Clear();
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	ExternalSystemInteractions.Ref AS Ref,
	|	ExternalSystemInteractions.Description AS Description
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	NOT ExternalSystemInteractions.DeletionMark
	|	AND NOT ExternalSystemInteractions.IsFolder
	|	AND ExternalSystemInteractions.IntegrationType IN(&qIntegrationType)
	|	AND ExternalSystemInteractions.IsActive
	|	AND (ExternalSystemInteractions.Hotel = &qHotel
	|			OR ExternalSystemInteractions.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|
	|GROUP BY
	|	ExternalSystemInteractions.Ref,
	|	ExternalSystemInteractions.Description
	|
	|ORDER BY
	|	ExternalSystemInteractions.Description";
	vQ.SetParameter("qHotel", SelHotel);
	vIntegrationType = New Array;
	vIntegrationType.Add(Enums.Integrations.UnisenderGO);
	vQ.SetParameter("qIntegrationType", vIntegrationType);
	vResult = vQ.Execute().Unload();
	Items.SelExternalSystem.ChoiceList.Add(Catalogs.ExternalSystemInteractions.EmptyRef(), "SMTP");
	For Each vRow In vResult Do
		Items.SelExternalSystem.ChoiceList.Add(vRow.Ref, TrimAll(vRow.Description));
	EndDo;
EndProcedure // FillExternalSystem

// --------------------------------------------------------------------------------
&AtServer
Procedure FillEMailParameters(rSubject, rText, pDocument) 
	rSubject = StrReplace(TrimAll(rSubject), "&amp;", "&");
	rTexts = StrReplace(TrimAll(rTexts), "&amp;", "&");
	vEMailParameters = EMail.GetEMailParameters(pDocument); 
	For Each vEMailParameter In vEMailParameters Do 	
		EMail.SetParameter(rSubject, vEMailParameter);
		EMail.SetParameter(rText, vEMailParameter);	
	EndDo;		
EndProcedure // FillEMailParameters

// --------------------------------------------------------------------------------
&AtServer
Procedure GetExternalHTMLText(pIsChangeSMSTemplate = False)
	SelExternalHTMLText = "";
	SelExternalSubject = "";
	Items.SelHTMLText.Visible = True;
	Items.SelSubject.Visible = True;
	Items.GroupHTMLButtons.Visible = True;
	Items.SelExternalHTMLText.Visible = False;
	Items.SelExternalSubject.Visible = False; 
	If pIsChangeSMSTemplate And ValueIsFilled(SelSMSTemplates) Then 
		SelSubject = StrReplace(TrimAll(cmNStr(SelSMSTemplates.Description, SelLanguage)), "&amp;", "&");
		vMessageText = SMS.GetHTMLTextByLanguage(SelSMSTemplates, SelLanguage); 
		vIsHTML = True;
		If IsBlankString(vMessageText) Then
			vMessageText = SMS.GetSMSTextByLanguage(SelSMSTemplates, SelLanguage);
			vIsHTML = False;
		EndIf;
		If ValueIsFilled(SelDocument) Then
			FillEMailParameters(SelSubject, vMessageText, SelDocument);
		EndIf;
		If vIsHTML Then
			SelHTMLText.SetHTML(vMessageText, New Structure());		
		Else
			SelHTMLText.SetFormattedString(New FormattedString(vMessageText));
		EndIf;
	EndIf;
	If ValueIsFilled(SelExternalSystem) And ValueIsFilled(SelSMSTemplates) Then
		
		vDP = SelExternalSystem.DataProcessor;
		If Not ValueIsFilled(vDP) Then
			tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'"));
			Return;
		EndIf;

		vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
		If vDPO = Undefined Then
			tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'"));	
			Return;
		EndIf;
		
		vDataList = InformationRegisters.ExternalSystemIntegrationData.GetData(SelExternalSystem, "SMSTemplates", "SMSTemplates", SelSMSTemplates); 
		If vDataList.Count() > 0 Then
			SelExternalTemplateID = vDataList[0].ExternalSystemDataCode; 
		Else
			SelExternalTemplateID = "";
			Return;
		EndIf; 
		
		vSubject = Undefined;
		vHTML = Undefined; 
		vMessage = "";    
		
		vArrayParameters = New Array;
		If ValueIsFilled(SelSMSTemplates) Then
			vDataList = InformationRegisters.ExternalSystemIntegrationData.GetData(SelExternalSystem, "String", "Parameter", SelSMSTemplates); 
			If vDataList.Count() > 0 Then
				vArrayParameters = vDataList.UnloadColumn("RefKey2");
			EndIf;
		EndIf;
		
		If ValueIsFilled(SelDocument) Then
			If TypeOf(SelDocument) = Type("DocumentRef.Accommodation") Or TypeOf(SelDocument) = Type("DocumentRef.Reservation") Then
				vEMailParameters = EMail.GetEMailParameters(SelDocument, SelDocument.Guest, , , vArrayParameters); 
			ElsIf TypeOf(SelDocument) <> Type("DocumentRef.ProformaInvoice") Then
				vEMailParameters = EMail.GetEMailParameters(SelDocument, SelDocument.Client, , , vArrayParameters); 
			EndIf;
		EndIf;
		
		If Not vDPO.GetExternalTemplate(SelExternalTemplateID, , vSubject, vHTML, vEMailParameters, vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
			Return;
		EndIf;
		
		If vSubject <> Undefined And ValueIsFilled(vSubject) Then
			SelExternalSubject = vSubject;
			Items.SelExternalSubject.Visible = True;
			Items.SelSubject.Visible = False;
		EndIf;
		
		If vHTML <> Undefined And ValueIsFilled(vHTML) Then
			Items.SelExternalHTMLText.Visible = True;	
			Items.SelHTMLText.Visible = False;
			Items.GroupHTMLButtons.Visible = False;
			
			SelExternalHTMLText = TrimAll(vHTML);	
		EndIf;
	EndIf;
EndProcedure // GetExternalHTMLText

// --------------------------------------------------------------------------------
&AtClient
Function RemoveDuplicates(pList = Undefined, pArray = Undefined, pReturnString = False)
	If pList <> Undefined Then 
		vArr = pList.UnloadValues();
	ElsIf pArray <> Undefined Then
		vArr = pArray;	
	Else	
		Return Undefined;	
	EndIf;
	vIndex1 = 0; 
	ItemsCount = vArr.Count(); 
	While vIndex1 < ItemsCount Do 
		vIndex2 = vIndex1 + 1; 
		While vIndex2 < ItemsCount Do 
			If vArr[vIndex2] = vArr[vIndex1] Then 
				vArr.Delete(vIndex2); 
				ItemsCount = ItemsCount - 1; 
			Else 
				vIndex2 = vIndex2 + 1; 
			EndIf;
		EndDo; 
		vIndex1 = vIndex1 + 1; 
	EndDo;
	If Not pReturnString Then 
		vResult = New ValueList();
		vResult.LoadValues(vArr);
	Else
		vResult = "";
		For Each vItem In vArr Do
			vResult = vResult + TrimAll(vItem) + ";"; 	
		EndDo;
	EndIf;
	Return vResult;
EndFunction // RemoveDuplicates

// --------------------------------------------------------------------------------
&AtServer
Function PutFromClientToServer(pAddres, pName)	
	vBinaryData = GetFromTempStorage(pAddres);
	If Not ValueIsFilled(SelDirectoryAtServer) Then
		SelDirectoryAtServer = TempFilesDir() + TrimAll(New UUID()) + "\";
		CreateDirectory(Left(SelDirectoryAtServer, StrLen(SelDirectoryAtServer) - 1)); // ACC:561	
	EndIf;
	vName = StrReplace(pName, """", "");
	vName = StrReplace(pName, "''", "");
	vAddresServer = TrimAll(SelDirectoryAtServer) + StrReplace(pName, """", "");
	vBinaryData.Write(vAddresServer); 
	Return vAddresServer;
EndFunction // FromClientToServer

// --------------------------------------------------------------------------------
&AtServer
Function PutFromServerToClient(pAddres)
	vBinaryData = New BinaryData(pAddres);
	vAddressTemp = PutToTempStorage(vBinaryData, UUID);
	Return vAddressTemp;
EndFunction // FromServerToClient

// --------------------------------------------------------------------------------
&AtServer
Procedure PictureAdd(pPicture, pSelectionBound)  
	vNewDocumentPicture = SelHTMLText.Insert(pSelectionBound, pPicture, Type("FormattedDocumentPicture"));	
EndProcedure // PictureAdd

// --------------------------------------------------------------------------------
&AtServer
Procedure GenerateAttachments()
	While Items.GroupAttachmentItems.ChildItems.Count() > 0 Do
		While Items.GroupAttachmentItems.ChildItems[0].ChildItems.Count() > 0 Do
			vCommand = Commands.Find("Remove" + StrReplace(Items.GroupAttachmentItems.ChildItems[0].ChildItems[0].Name, "FormGroupGroupItems_", ""));
			If vCommand <> Undefined Then
				Commands.Delete(vCommand);
			EndIf;
			vCommand = Commands.Find("Open" + StrReplace(Items.GroupAttachmentItems.ChildItems[0].ChildItems[0].Name, "FormGroupGroupItems_", ""));
			If vCommand <> Undefined Then
				Commands.Delete(vCommand);
			EndIf;
			Items.Delete(Items.GroupAttachmentItems.ChildItems[0].ChildItems[0]);
		EndDo;
		Items.Delete(Items.GroupAttachmentItems.ChildItems[0]);
	EndDo;
	vNumberItem = 0;
	vNumber = 0;
	For Each vAttachment In Attachments Do
		If vNumberItem = 0 Then
			vStructure = New Structure("Type, Visible, Representation, ShowTitle, Group", FormGroupType.UsualGroup, True, UsualGroupRepresentation.None, False, ChildFormItemsGroup.AlwaysHorizontal);		
			vGroupAttachments = tcOnServer.cmCreateItem(ThisObject, Items.GroupAttachmentItems, "GroupAttachments_" + vNumber, "FormGroup", vStructure);
			vNumber = vNumber + 1;
		EndIf;
		vStructure = New Structure("Type, Visible, Representation, ShowTitle, Group", FormGroupType.UsualGroup, True, UsualGroupRepresentation.None, False, ChildFormItemsGroup.AlwaysHorizontal);		
		vGroupItems = tcOnServer.cmCreateItem(ThisObject, vGroupAttachments, "GroupItems_" + vAttachment.Id, "FormGroup", vStructure);
		
		vCommand = Commands.Add("Open" + vAttachment.Id);
		vCommand.Action = "OpenAttachment";
		vStructure = New Structure("Title, CommandName, Representation, Type, Font, AutoMaxWidth", vAttachment.FileName, "Open" + vAttachment.Id, ButtonRepresentation.Text, FormButtonType.Hyperlink, tcCommonFunctionOnClientServer.FontConstructor(,12), False);		
		tcOnServer.cmCreateItem(ThisObject, vGroupItems, "Open_" + vAttachment.Id, "FormButton", vStructure);
		
		If Not vAttachment.CheckPredefined Then 
			vCommand = Commands.Add("Remove" + vAttachment.Id);
			vCommand.Action = "RemoveAttachment";
			vCommand.ToolTip = NStr("en = 'Remove'; de = 'Entfernen'; ru = 'Удалить'");
			vStructure = New Structure("Title, CommandName, Representation, Picture, Type", NStr("en = 'Remove'; de = 'Entfernen'; ru = 'Удалить'"), "Remove" + vAttachment.Id, ButtonRepresentation.Picture, PictureLib.Remove, FormButtonType.Hyperlink);		
			tcOnServer.cmCreateItem(ThisObject, vGroupItems, "Remove_" + vAttachment.Id, "FormButton", vStructure);
		EndIf;
		If vNumberItem = 3 Then
			vNumberItem = 0;	
		Else
			vNumberItem = vNumberItem + 1;	
		EndIf;
	EndDo;
	WindowOptionsKey = UUID;
EndProcedure // GenerateAttachments

// --------------------------------------------------------------------------------
&AtServer
Procedure DeleteFileAtServer(pAddres) 
	// ACC:561-off
	If ValueIsFilled(pAddres) Then
		vFile = New File(pAddres);
		If tcCommonFunctionOnClientServer.cmExists(vFile) Then
			DeleteFiles(pAddres);
		EndIf;
	EndIf;      
	// ACC:561-on
EndProcedure // DeleteFileAtServer

// --------------------------------------------------------------------------------
&AtServer
Function SendAtServer()
	Try
        vReplyToEMail = New Array;
		If Not IsBlankString(SelEmployees.ReplyToEMail) Then
			vEMailsList = StrSplit(TrimAll(SelEmployees.ReplyToEMail), ";", False);
			For Each vEMailItem In vEMailsList Do
				vReplyToEMail.Add(TrimAll(vEMailItem));
			EndDo;
		EndIf;
				
		vToEMail = New Array;
		If ValueIsFilled(SelTo) Then
			vEMailsList = StrSplit(TrimAll(SelTo), ";", False);
			For Each vEMailItem In vEMailsList Do
				vToEMail.Add(TrimAll(vEMailItem));
			EndDo; 
		EndIf;   
		
		vCCEMail = New Array;	
		If ValueIsFilled(SelCC) Then
			vEMailsList = StrSplit(TrimAll(SelCC), ";", False);
			For Each vEMailItem In vEMailsList Do
				vCCEMail.Add(TrimAll(vEMailItem));
			EndDo;
		EndIf;  
		
		vBCCEMail = New Array;
		If ValueIsFilled(SelBCC) Then
			vEMailsList = StrSplit(TrimAll(SelBCC), ";", False);
			For Each vEMailItem In vEMailsList Do
				vBCCEMail.Add(TrimAll(vEMailItem));
			EndDo;
		EndIf;
		
		vHTMLText = "";
		vHTMLTextAttachments = New Structure();
		SelHTMLText.GetHTML(vHTMLText, vHTMLTextAttachments);
		
		vAttachments = New Map;
		For Each vRow In Attachments Do
			vAttachments.Insert(cmGetValidFileName(StrReplace(vRow.FileName, "SENDEMAIL_" + TrimAll(vRow.Id), "")), vRow.FullFileNameAtServer);
		EndDo;
		
		vSubject = TrimAll(SelSubject); 
		
		EMail.Send(SelEmployees, SelSenderName, TrimAll(SelEmployees.EMail), vSubject, vHTMLText, SelSMSTemplates, 
		           SelDocument, , , , vHTMLTextAttachments, vAttachments, vToEMail, vReplyToEMail, vCCEMail, vBCCEMail, SelExternalSystem, SelExternalTemplateID, , , True);
	Except
		vErrorInfo = ErrorInfo();
		vError = NStr("ru = 'Описание ошибки: '; de = 'Error description: '; en = 'Error description: '");
		WriteLogEvent(NStr("en='InternetMail.SendFile';ru='ЭлектроннаяПочта.ОтправитьФайл';de='InternetMail.SendFile'"), EventLogLevel.Error, , , vError + DetailErrorDescription(vErrorInfo));
		Return New Structure("Result, ErrorText", False, vError + BriefErrorDescription(vErrorInfo));
	EndTry;
	
	// Write guest group attachment that message was sent
	Try
		If ValueIsFilled(SelGuestGroup) Then 
			vFullFileName = "";
			vFileName = "";
			AttachmentsArray = Attachments.FindRows(New Structure("CheckPredefined", True));
			If AttachmentsArray.Count() > 0 Then
				vFullFileName = AttachmentsArray[0].FullFileNameAtServer;
				vFileName = cmGetValidFileName(AttachmentsArray[0].FileName);
			EndIf;  
			// Write attachment 
			For Each vRow In vHTMLTextAttachments Do    
				vTextHTML = StrReplace(vTextHTML, vRow.Key, EMail.GetPictureIsBase64HTMLString(vRow.Value));	
			EndDo;

			InformationRegisters.GuestGroupAttachments.WriteData(, SelGuestGroup, , , , , , SelTo, SelGuestGroup.Client.Fax, Enums.AttachmentTypes.EMail, Enums.AttachmentStatuses.Sent, TrimAll(vHTMLText), SelSMSTemplates, SelDocument, , , vFullFileName, vFileName, , TrimAll(vSubject));       
		EndIf;
	Except
		vErrorInfo = ErrorInfo();
		vError = NStr("ru = 'Ошибка регистрации факта отправки сообщения! Описание ошибки: '; 
		              |de = 'Failed to write guest group attachment for e-mail message! Error description: ';
		              |en = 'Failed to write guest group attachment for e-mail message! Error description: '");
		WriteLogEvent(NStr("en='InternetMail.SendFile';ru='ЭлектроннаяПочта.ОтправитьФайл';de='InternetMail.SendFile'"), EventLogLevel.Error, , , vError + DetailErrorDescription(vErrorInfo));
		Return New Structure("Result, ErrorText", True, vError + BriefErrorDescription(vErrorInfo));	
	EndTry;
	Return New Structure("Result, ErrorText", True, "");
EndFunction // SendAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeCloseAtServer()
	// ACC:561-off
	vItemsArray = Attachments.FindRows(New Structure("CheckPredefined", True));
	If vItemsArray.Count() > 0 Then
		For Each vFile In vItemsArray Do
			If ValueIsFilled(vFile.FullFileNameAtServer) And vFile.CheckRemoveAtServer Then 
				vFileCheck = New File(vFile.FullFileNameAtServer);
				If tcCommonFunctionOnClientServer.cmExists(vFileCheck) Then 
					DeleteFiles(vFile.FullFileNameAtServer);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If ValueIsFilled(SelDirectoryAtServer) Then
		DeleteFiles(Left(SelDirectoryAtServer, StrLen(SelDirectoryAtServer) - 1));
	EndIf;  
	// ACC:561-on
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ValidAddress(pItem)
	vValue = ThisObject[pItem.Name];	
	While StrFind(vValue, " ") <> 0 Do
		vValue = StrReplace(vValue, " ", ";");	
	EndDo;
	While StrFind(vValue, ",") <> 0 Do
		vValue = StrReplace(vValue, ",", ";");	
	EndDo;
	While StrFind(vValue, ";;") <> 0 Do
		vValue = StrReplace(vValue, ";;", ";");	
	EndDo;
	vArr = StrSplit(vValue, ";", False); 
	vValue = RemoveDuplicates(, vArr, True);
	ThisObject[pItem.Name] = vValue;
EndProcedure // ValidAddress

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckCompliance()
	vDeleteAttachmentItem = New Array();
	For Each vAttachment In Attachments Do			
		If Not ValueIsFilled(vAttachment.FullFileNameAtClient) And Not ValueIsFilled(vAttachment.FullFileNameAtServer) Then
			vDeleteAttachmentItem.Add(Attachments.IndexOf(vAttachment));
			Continue;
		EndIf;
		If ValueIsFilled(vAttachment.FullFileNameAtClient) And Not ValueIsFilled(vAttachment.FullFileNameAtServer) Then
			vBinaryData = New BinaryData(vAttachment.FullFileNameAtClient);
			vAddressTemp = PutToTempStorage(vBinaryData, UUID);	
			vAttachment.FullFileNameAtServer = PutFromClientToServer(vAddressTemp, vAttachment.FileName); 
			DeleteFromTempStorage(vAddressTemp);
			vAttachment.CheckRemoveAtServer = True;
		ElsIf Not ValueIsFilled(vAttachment.FullFileNameAtClient) And ValueIsFilled(vAttachment.FullFileNameAtServer) Then
			vAddressTemp = PutFromServerToClient(vAttachment.FullFileNameAtServer);
			vBinaryData = GetFromTempStorage(vAddressTemp);
			If Not ValueIsFilled(SelDirectoryArClient) Then
				SelDirectoryArClient = TempFilesDir() + TrimAll(New UUID()) + "\";
				CreateDirectory(Left(SelDirectoryArClient, StrLen(SelDirectoryArClient) - 1)); // ACC:561	
			EndIf;
			vAddresClient = TrimAll(SelDirectoryArClient) + StrReplace(vAttachment.FileName, """", "");
			vBinaryData.Write(vAddresClient);
			vAttachment.FullFileNameAtClient = vAddresClient;
			DeleteFromTempStorage(vAddressTemp);
			vAttachment.CheckRemoveAtClient = True;
		EndIf;		
	EndDo;
	For Each vItem In vDeleteAttachmentItem Do
		Attachments.Delete(vItem);	
	EndDo;	
EndProcedure // CheckCompliance

// --------------------------------------------------------------------------------
&AtClient
Procedure FillSelToFromDocuments()	
	If SelToList.Count() > 0 Then
		If ValueIsFilled(TrimAll(SelTo)) Then
			vEmails = New ValueList();
			vEMailsList = "";
			vEMailsListOne = StrSplit(TrimAll(SelTo), ";", False);
			For Each vItem In SelToList Do 
				If vEMailsListOne.Find(vItem.Value) = Undefined Then 
					vEmails.Add(vItem);
				EndIf;
			EndDo;
		Else
			vEmails = SelToList; 	
		EndIf;
		If vEmails.Count() > 0 Then		
			ShowChooseFromList(New NotifyDescription("SendByEMailAfterUserChoice", ThisObject, New Structure()), vEmails, Items.SelTo);
		EndIf;
	EndIf;
EndProcedure // FillSelToFromDocuments

// --------------------------------------------------------------------------------
&AtClient
Procedure SendByEMailAfterUserChoice(pEMail, pExtraParams) Export
	If pEmail <> Undefined Then
		SelTo = TrimAll(SelTo) + TrimAll(pEmail) + ";";  
	EndIf;
	ValidAddress(Items.SelTo);
EndProcedure // SendByEMailAfterUserChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure SetImageToFormattedDocument(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vStart = Undefined;
		vEnd = Undefined;
		Items.SelHTMLText.GetTextSelectionBounds(vStart, vEnd);
		vPicture = New Picture(pFileArray[0]);
		PictureAdd(vPicture, vStart); 
	EndIf;
EndProcedure // SetImageToFormattedDocument

// --------------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogAddAttachments();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File system extension is being installing on your browser...'; de = 'Dateisystemerweiterung wird in Ihrem Browser installiert...'; ru = 'В браузер устанавливается расширение по работе с файлами...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("AddAttachmentsFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // AddAttachmentsFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("AddAttachmentsInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // AddAttachmentsFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogAddAttachments();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // AddAttachmentsInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogAddAttachments()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Load file';ru='Загрузить файл';de='Datei laden'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogAddAttachmentsCompleted", ThisObject));
EndProcedure // OpenFileDialogAddAttachments

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogAddAttachmentsCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		If Attachments.Count() > 0 Then
			vId = Attachments.Get(Attachments.Count() - 1).Id + 1;		
		Else
			vId = 1;	
		EndIf;
		vFileNeme = Right(pFileArray[0], StrLen(pFileArray[0]) - StrFind(pFileArray[0], "\", SearchDirection.FromEnd));
		vCheckFileName = Attachments.FindRows(New Structure("FileName", vFileNeme));
		If vCheckFileName.Count() > 0 Then
			vLastFileName = vFileNeme; 
			vFileNeme = Left(vLastFileName, StrFind(vLastFileName, ".", SearchDirection.FromEnd) - 1) + " (" + TrimAll(vCheckFileName.Count()) + ")" + Right(vLastFileName, StrLen(vLastFileName) - StrFind(vLastFileName, ".", SearchDirection.FromEnd) + 1);   	
		EndIf;
		vAttachment = Attachments.Add();
		vAttachment.Id = vId;
		vAttachment.FileName = vFileNeme;
		vAttachment.FullFileNameAtClient = pFileArray[0];
		vAttachment.CheckPredefined = False;
		CheckCompliance();
		GenerateAttachments();
	EndIf;
EndProcedure // OpenFileDialogAddAttachmentsCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterCompletionOperation(pErrorText) Export 
	If ValueIsFilled(pErrorText) Then
		ShowMessageBox(New NotifyDescription("AfterCompletionOperation", ThisObject), pErrorText);
	Else
		If ValueIsFilled(SelTo) And ValueIsFilled(SelDocument) Then
			vEMailsList = StrSplit(TrimAll(SelTo), ";", False);
			If vEMailsList.Count() > 0 Then
				Notify("CommonForm.tcSendMail.Send", vEMailsList.Get(0), SelDocument);
			EndIf;
		EndIf;
		Close();
	EndIf;                                      
EndProcedure // AfterCompletionOperation

#EndRegion                        
