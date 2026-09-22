
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure PresentationGetProcessing(pData, pPresentation, pStandardProcessing)
	pStandardProcessing = False;
	If pData.Ref.Type = Enums.MessageTypes.Activity Then
		pPresentation = NStr("en='Activity N'; ru='Действие N'; de='Aktivität Nr'");
	ElsIf pData.Ref.Type = Enums.MessageTypes.Message Then
		pPresentation = NStr("en='Message N'; ru='Сообщение N'; de='Nachricht Nr'");
	Else
		pPresentation = NStr("en='Task N'; ru='Задача N'; de='Aufgabe Nr'");
	EndIf;
	pPresentation = pPresentation + TrimAll(pData.Number) + NStr("en=' from '; ru=' от '; de=' vom '") + Format(pData.Date, "DF='dd.MM.yyyy HH:mm'") + ", " + TrimAll(pData.Ref.Author);
EndProcedure // PresentationGetProcessing

// --------------------------------------------------------------------------------
Procedure FormGetProcessing(pFormType, pParameters, pSelectedForm, pAdditionalInformation, pStandardProcessing)
	SetPrivilegedMode(True);
	vCurSession = GetCurrentInfoBaseSession();
	SetPrivilegedMode(False);
	vSessionNumber = vCurSession.SessionNumber;
	vSessionStartTime = vCurSession.SessionStarted;
	vAppRunMode = CachedCommonFunctions.cmGetAppRunMode(vSessionNumber, vSessionStartTime);
	If vAppRunMode.MobileDeviceMode Then 
		If pFormType = "ObjectForm" Or pSelectedForm = "tcDocumentForm" Then
			pStandardProcessing = False;
			pSelectedForm = "mcDocumentForm";
		EndIf; 
	EndIf;
EndProcedure // FormGetProcessing     

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
// Procedure - Print message
//
// Parameters:
//  pMessagesList		 - ValueList - Lits of message references
//  pSelLanguage		 - CatalogRef.Languages - Display language 
//  pSelObjectPrintForm	 - CatalogRef.ObjectPrintingForms - Object printing form
//  pSpreadsheet		 - SpreadsheetDocument - Spreadsheet to form output
//  pTemplate			 - SpreadsheetDocument - Form template
//
Procedure PrintMessage(pMessagesList, pSelLanguage, pSelObjectPrintForm, pSpreadsheet, pTemplate) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pSelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	Else
		vTemplate = pTemplate;
	EndIf;
	
	vMessagesAttachements = GetMessagesAttachements(pMessagesList);
	
	For Each vItem In pMessagesList Do
		pMsg = vItem.Value;
		vHeader = vTemplate.GetArea("Header");
		
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			mHotelPrintName = SessionParameters.CurrentHotel.PrintName;
		EndIf;
		mMessageInfo = "" + pMsg.Type + " " + pMsg.Number + " от " + pMsg.Date;
		If ValueIsFilled(pMsg.ByObject) Then
			If TypeOf(pMsg.ByObject) = Type("CatalogRef.Rooms") Then
				mByObject = NStr("en = 'By room: '; de = 'Nach Zimmer:'; ru = 'По номеру: '") + pMsg.ByObject.Description;
			Else
				vObjMetadata = pMsg.ByObject.Metadata();
				vDescription = False;
				vNumber = False;
				vCode = False;
				For Each vStAttr In vObjMetadata.StandardAttributes Do
					If vStAttr.Name = "Description" Then
						vDescription = True;
					ElsIf vStAttr.Name = "Number" Then
						vNumber = True;
					ElsIf vStAttr.Name = "Code" Then
						vCode = True;
					EndIf;
				EndDo;
				mByObject = NStr("en = 'By object: '; de = 'Nach Objekt:'; ru = 'По объекту: '") + String(TypeOf(pMsg.ByObject)) 
							+ ?(vDescription, " " + pMsg.ByObject.Description, "")  
							+ ?(vNumber, NStr("en = ' N'; de = ' N'; ru = ' №'") + pMsg.ByObject.Number, ?(vCode, " " + pMsg.ByObject.Code, ""));
			EndIf;
		EndIf;
		mStatus = pMsg.MessageStatus;
		mType = pMsg.MessageType;
		mDeadline = pMsg.CloseToDate;
		mForEmployee = pMsg.ForEmployee;
		If pMsg.ForEmployees.Count() > 0 Then
			For Each vEmployee In pMsg.ForEmployees Do 
				mForEmployee = "" + mForEmployee + ", " + vEmployee.Employee;
			EndDo;
		EndIf;
		mForDepartment = pMsg.ForDepartment;
		If pMsg.ForDepartments.Count() > 0 Then
			For Each vDepartment In pMsg.ForDepartments Do 
				mForDepartment = "" + mForDepartment + ", " + vDepartment.Department;
			EndDo;
		EndIf;
		mAuthor = pMsg.Author;
		If ValueIsFilled(pMsg.ValidFromDate) Then
			mShowTimeFrom = Format(pMsg.ValidFromDate, "DF='dd.MM.yyyy HH:mm'");
		EndIf;
		If ValueIsFilled(pMsg.ValidToDate) Then
			mShowTimeTo = Format(pMsg.ValidToDate, "DF='dd.MM.yyyy HH:mm'");
		EndIf;
		mBasis = pMsg.ParentDoc;
		
		If pMsg.Type <> Enums.MessageTypes.Activity Then
			vPopUp = ?(pMsg.PopUp, NStr("en = ' automatically pop up message'; de = ' automatisch pop-up Nachricht'; ru = ' всплывающее сообщение'"), ""); 
			If pMsg.PopUp Then
				vAnd = ",";
			Else
				vAnd = "";
			EndIf;
			vSendBySMS = ?(pMsg.SendBySMS, vAnd + NStr("en = ' SMS'; de = ' SMS'; ru = ' СМС'"), "");
			If ValueIsFilled(vPopUp) Or ValueIsFilled(vSendBySMS) Then
				mNotification = NStr("en = 'Notification via'; de = 'Benachrichtigung über'; ru = 'Уведомление через'") + vPopUp + vSendBySMS;
			EndIf;
		EndIf;
		
		vHeaderStructure = New Structure;
		vHeaderStructure.Insert("mHotelPrintName", mHotelPrintName);
		vHeaderStructure.Insert("mMessageInfo", mMessageInfo);
		vHeaderStructure.Insert("mByObject", mByObject);
		vHeaderStructure.Insert("mStatus", mStatus);
		vHeaderStructure.Insert("mType", mType);
		vHeaderStructure.Insert("mDeadline", mDeadline);
		vHeaderStructure.Insert("mForEmployee", mForEmployee);
		vHeaderStructure.Insert("mForDepartment", mForDepartment);
		vHeaderStructure.Insert("mAuthor", mAuthor);
		vHeaderStructure.Insert("mShowTimeFrom", mShowTimeFrom);
		vHeaderStructure.Insert("mShowTimeTo", mShowTimeTo);
		vHeaderStructure.Insert("mBasis", mBasis);
		vHeaderStructure.Insert("mNotification", mNotification);
		
		FillPropertyValues(vHeader.Parameters, vHeaderStructure);
		pSpreadsheet.Put(vHeader);
		
		If pMsg.Type = Enums.MessageTypes.Activity Then
			vForActivity = vTemplate.GetArea("ForActivity");
			mPosition = pMsg.Position;
			vPhone1 = pMsg.Phone;
			vPhone2 = pMsg.Phone2;
			If ValueIsFilled(vPhone1) Then
				vPhones = " " + vPhone1;
			EndIf;
			If Not IsBlankString(vPhones) Then
				vPhones = vPhones + ?(ValueIsFilled(vPhone2), ", " + vPhone2, "");
			Else
				vPhones = ?(ValueIsFilled(vPhone2), " " + vPhone2, "");
			EndIf;
			mEMail = pMsg.EMail;
			
			vForActivity.Parameters.mPosition = mPosition;
			vForActivity.Parameters.mPhones = vPhones;
			vForActivity.Parameters.mEMail= mEMail;
			pSpreadsheet.Put(vForActivity);
		EndIf;
		
		// Text
		vText = vTemplate.GetArea("Text");
		vText.Parameters.mText = pMsg.Remarks;
		pSpreadsheet.Put(vText);
		
		If pMsg.Comments.Count() > 0 Then
			// Comments table
			vCommentsTableHeader = vTemplate.GetArea("CommentsTableHeader");
			If Not pSpreadsheet.CheckPut(vCommentsTableHeader) Then
				pSpreadsheet.PutHorizontalPageBreak();
			EndIf;
			pSpreadsheet.Put(vCommentsTableHeader);
			
			For Each vRow In pMsg.Comments Do
				vCommentsTableRow = vTemplate.GetArea("CommentsTableRow");
				vCommentsTableRow.Parameters.mDate = vRow.Period;
				vCommentsTableRow.Parameters.mAuthor = vRow.Employee;
				vCommentsTableRow.Parameters.mComment = vRow.Comments;
				If Not pSpreadsheet.CheckPut(vCommentsTableRow) Then
					pSpreadsheet.PutHorizontalPageBreak();
					pSpreadsheet.Put(vCommentsTableHeader);
				EndIf;	
				pSpreadsheet.Put(vCommentsTableRow);
			EndDo;
		EndIf;
		
		vTableOfAttach = vMessagesAttachements.FindRows(New Structure("Message", pMsg));
		
		If vTableOfAttach.Count() > 0 Then
			// Files table
			vFilesTableHeader = vTemplate.GetArea("FilesTableHeader");
			If Not pSpreadsheet.CheckPut(vFilesTableHeader) Then
				pSpreadsheet.PutHorizontalPageBreak();
			EndIf;
			pSpreadsheet.Put(vFilesTableHeader);
			
			For Each vRow In vTableOfAttach Do
				vFilesTableRow = vTemplate.GetArea("FilesTableRow");
				vFilesTableRow.Parameters.mDate = vRow.Period;
				vFilesTableRow.Parameters.mAuthor = vRow.Author;
				vFilesTableRow.Parameters.mFileName = vRow.FileName;
				vFilesTableRow.Parameters.mRemarks = vRow.Remarks;
				If Not pSpreadsheet.CheckPut(vFilesTableRow) Then
					pSpreadsheet.PutHorizontalPageBreak();
					pSpreadsheet.Put(vFilesTableRow);
				EndIf;
				pSpreadsheet.Put(vFilesTableRow);
			EndDo;
		EndIf;
		
		pSpreadsheet.PutHorizontalPageBreak();
	EndDo;
	
	pSpreadsheet.FitToPage = True;
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current report
			vFilter = New Structure("ObjectPrintingForm, IsActive", pSelObjectPrintForm, True);
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(pSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings);
						cmDoSpreadsheetOutput(pSpreadsheet, vPrintSettings, vName);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function GetMessagesAttachements(pMessagesList)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	MessageAttachments.Period AS Period,
	|	MessageAttachments.Author AS Author,
	|	MessageAttachments.FileName AS FileName,
	|	MessageAttachments.Remarks AS Remarks,
	|	MessageAttachments.Message AS Message
	|FROM
	|	InformationRegister.MessageAttachments AS MessageAttachments
	|WHERE
	|	MessageAttachments.Message IN(&qMessagesList)";
	vQuery.SetParameter("qMessagesList", pMessagesList);
	vQueryResult = vQuery.Execute().Unload();
	
	Return vQueryResult;
EndFunction // GetMessagesAttachements

#EndRegion