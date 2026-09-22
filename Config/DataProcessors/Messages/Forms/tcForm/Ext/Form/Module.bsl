
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	SelHotel = SessionParameters.CurrentHotel;
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;
	SelHotelOnChangeAtServer();

	If Parameters.Property("SetParamObject") Then
		ByObject = Parameters.SetParamObject;
	EndIf;
	If Parameters.Property("ShowPopUpOnly") Then
		SelShowPopUpOnly = Parameters.ShowPopUpOnly;
	EndIf;
	If Parameters.Property("ShowClosedMessages") Then
		ShowClosedMessages = Parameters.ShowClosedMessages;
	EndIf;
		
	// Check if there are any message types defined
	vMessageTypes = cmGetAllMessageTypes();
	If vMessageTypes.Count() = 0 Then
		Items.MessagesMessageType.Visible = False;
	Else
		Items.MessagesMessageType.Visible = True;
	EndIf;
	
	// Check current employee rights
	vShowDocumentsJournal = True;
	If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		vShowDocumentsJournal = False;
	ElsIf Not cmCheckUserPermissions("HavePermissionToSeeAllMessages") Then
		vShowDocumentsJournal = False;
	EndIf;
	If Not vShowDocumentsJournal Then
		Items.ShowMesagesList.Enabled = False;
		Items.ShowMesagesList.Visible = False;
	EndIf;
	
	// Check if statuses are used
	vStatuses = GetAllMessageStatuses();
	If vStatuses.Count() > 0 Then
		Items.MessagesMessageStatus.Visible = True;
		Items.MessagesIsClosed.ReadOnly = True;
		Items.FormGroupOpenClose.Visible = False;
		Items.FormChangeStatusForSelectedCommand.Visible = True;
	Else
		Items.MessagesMessageStatus.Visible = False;
		Items.MessagesIsClosed.ReadOnly = False;
		Items.FormGroupOpenClose.Visible = True;
		Items.FormChangeStatusForSelectedCommand.Visible = False;
	EndIf;
	
	// Load saved options
	vNumberOfDaysToWarnBeforeExpire = SystemSettingsStorage.Load("Document.Message.ListForm", "NumberOfDaysToWarnBeforeExpire");
	If vNumberOfDaysToWarnBeforeExpire <> Undefined And TypeOf(vNumberOfDaysToWarnBeforeExpire) = Type("Number") Then
		SelNumberOfDaysToWarnBeforeExpire = vNumberOfDaysToWarnBeforeExpire;
	Else
		SelNumberOfDaysToWarnBeforeExpire = 3;
	EndIf;
	
	// Fill printing commands
	FillPrintingButton();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	// Fill messages list
	ShowMessages();
	// Turn on messages auto refresh
	AttachIdleHandler("ShowMessagesClient", 20);
	If tcOnClient.IsHomePageWindow(ThisObject) Then
		vPrefix = NStr("en = 'Tasks: '; de = 'Aufgaben: '; ru = 'Задачи: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
	EndIf;
	// List commands availability
	#If MobileClient Then 
		Items.MessagesChange.Visible = False;
		Items.MessagesAssignedTo.Visible = False;
		Items.MessagesAuthorAndDate.Visible = False;
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "MessageWrite" Then
		AttachIdleHandler("ShowMessagesClient", 1, True);
	ElsIf pEventName = "DataProcessor.Messages.Form.Open" And TypeOf(pParameter) = Type("Structure") Then
		If pParameter.Property("SetParamObject") Then
			vByObject = pParameter.SetParamObject;
			If ValueIsFilled(vByObject) And vByObject <> ByObject Then
				ByObject = vByObject;
			EndIf;
		EndIf;
		If pParameter.Property("SelDate") Then
			vSelDate = pParameter.SelDate;
			If ValueIsFilled(vSelDate) And vSelDate <> SelDate Then
				SelDate = vSelDate;
			EndIf;
		EndIf;
		ShowMessagesClient();
	ElsIf pEventName = "System.Hotel.Changed" Then
		If ValueIsFilled(pParameter) Then
			ShowMessagesClient();
			If tcOnClient.IsHomePageWindow(ThisObject) Then
				vPrefix = NStr("en = 'Tasks: '; de = 'Aufgaben: '; ru = 'Задачи: '");
				tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
			EndIf;	
		EndIf;		
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure MessagesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If Not (pField.Name = "MessagesObject") Then
		If ValueIsFilled(pItem.CurrentData.Message) Then
			pStandardProcessing = False;
			OpenForm("Document.Message.ObjectForm", New Structure("Key, SetParamObject", pItem.CurrentData.Message, pItem.CurrentData.Object), , , , , , FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	ElsIf ValueIsFilled(pItem.CurrentData.Object) Then
		pStandardProcessing = False;
		#If ThickClientOrdinaryApplication Then 
			vFrm = pItem.CurrentData.Object.GetForm();
			vFrm.Open();
		#Else 
			vRowData = Items.Messages.RowData(pSelectedRow);
			OpenForm(GetObjectMetadataName(vRowData.Object) + ".ObjectForm", New Structure("Key", vRowData.Object));
		#EndIf
	EndIf;
EndProcedure // MessagesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure MessagesIsClosedOnChange(pItem)
	If pItem <> Undefined Then
		vCurrentData = pItem.Parent.CurrentData;
		If Not MessagesIsClosedOnChangeAtServer(vCurrentData.AccountingDate, vCurrentData.Message) Then
			vCurrentData.IsClosed = Not vCurrentData.IsClosed;
		Else
			Notify("MessageWrite", , ThisObject);
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MessagesBeforeRowChange(pItem, pCancel)
	If Items.Messages.CurrentItem.Name <> "MessagesIsClosed" Then
		pCancel = True;
		vStandardProcessing = True;
		MessagesSelection(pItem, Items.Messages.SelectedRows.Get(0), Items.Messages.CurrentItem, vStandardProcessing)
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MessagesMessageStatusOnChange(pItem)
	If pItem <> Undefined Then
		vCurrentData = pItem.Parent.CurrentData;
		If Not ValueIsFilled(vCurrentData.MessageStatus) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Task status should be filled!'; ru='Статус задач должен быть указан!'; de='Aufgabenstatus sollte ausgefüllt werden!'"));
		EndIf;
		MessagesStatusOnChangeAtServer(vCurrentData.AccountingDate, vCurrentData.Message, vCurrentData.MessageStatus, vCurrentData);
		Notify("MessageWrite", , ThisObject);
	EndIf;
EndProcedure // MessagesMessageStatusOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateOnChange(pItem)
	ShowMessagesClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowClosedMessagesOnChange(pItem)
	ShowMessagesClient();
EndProcedure // ShowClosedMessagesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowPopUpOnlyOnChange(pItem)
	ShowMessagesClient();
EndProcedure // ShowPopUpOnlyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
	ShowMessagesClient();
EndProcedure		   

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = tcOnServer.CheckIfHotelCouldBeCleared();
	If pStandardProcessing Then
		SelHotelOnChangeAtServer();
	EndIf;
EndProcedure // SelHotelClearing

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure NewMessage(Command)
	If ValueIsFilled(ByObject) Then
		stParam = New Structure("SetParamObject", ByObject);
		OpenForm("Document.Message.Form.tcDocumentForm", stParam, , , , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // NewMessage

// -----------------------------------------------------------------------------
&AtClient
Procedure NewReminding(pCommand)
	vCurrentEmployee = GetCurrentEmployee();
	If ValueIsFilled(vCurrentEmployee) Then
		stParam = New Structure("SetEmployee, Type", vCurrentEmployee, PredefinedValue("Enum.MessageTypes.Task"));
		OpenForm("Document.Message.Form.tcDocumentForm", stParam, , , , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // NewReminding

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyMessage(pCommand)
	vCurData = Items.Messages.CurrentData;
	If vCurData <> Undefined And ValueIsFilled(vCurData.Message) Then
		stParam = New Structure("CopyingValue", vCurData.Message);
		If ValueIsFilled(ByObject) Then
			stParam.Insert("SetParamObject", ByObject);
		EndIf;
		OpenForm("Document.Message.Form.tcDocumentForm", stParam, , , , , , FormWindowOpeningMode.LockOwnerWindow);
	Else
		ShowMessageBox(, NStr("en='Select document first!'; ru='Сначала выберите документ!'; de='Zuerst Dokument auswählen!'"));
	EndIf;
EndProcedure // CopyMessage

// -----------------------------------------------------------------------------
&AtClient
Procedure EditMessage(pCommand)
	vCurData = Items.Messages.CurrentData;
	If vCurData <> Undefined And ValueIsFilled(vCurData.Message) Then
		stParam = New Structure("Key", vCurData.Message);
		OpenForm("Document.Message.Form.tcDocumentForm", stParam, , , , , , FormWindowOpeningMode.LockOwnerWindow);
	Else
		ShowMessageBox(, NStr("en='Select document first!'; ru='Сначала выберите документ!'; de='Zuerst Dokument auswählen!'"));
	EndIf;
EndProcedure // EditMessage

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowMesagesList(Command)
	#If ThickClientOrdinaryApplication Then 
		vFrm = Documents.Message.GetListForm();
		vFrm.Open();
	#Else 
		OpenForm("Document.Message.ListForm");
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Refresh(Command)
	ShowMessagesClient();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SendMessageClick(Command)
	OpenForm("CommonForm.tcSMSSending", , ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	vMessagesList = New ValueList;
	
	If Items.Messages.SelectedRows.Count() > 0 Then
		For Each vCurRowID In Items.Messages.SelectedRows Do
			If vCurRowID <> Undefined Then
				vCurRow = Items.Messages.RowData(vCurRowID);
				If vCurRow <> Undefined And ValueIsFilled(vCurRow.Message) Then
					vRef = vCurRow.Message;
					vMessagesList.Add(vRef);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Choose processing type
	vPrintNumber = StrReplace(pCommand.Name, "Print", "");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref, vMessagesList);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to load external print form!'; de = 'Das externe Druckformular konnte nicht geladen werden!'; ru = 'Не удалось загрузить внешнюю печатную форму!'"));
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref, vMessagesList);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to load external print form!'; de = 'Das externe Druckformular konnte nicht geladen werden!'; ru = 'Не удалось загрузить внешнюю печатную форму!'"));
		EndTry;
	Else
		If vPrintForm.PredefinedDataName = "MessagePrintForm" Then
			OpenForm("Document.Message.Form.tcMessagePrintForm", New Structure("InputParameter, ObjectPrintingForm", vMessagesList, vPrintForm.Ref), ThisObject);
		EndIf;
	EndIf;
EndProcedure // PrintButtonClick

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseSelectedCommand(pCommand)
	vMessagesList = New ValueList;
	For Each vSelRow In Items.Messages.SelectedRows Do
		vCurData = Messages.FindByID(vSelRow);
		If ValueIsFilled(vCurData.Message) Then
			vMessagesList.Add(vCurData.Message);
		EndIf;
	EndDo;
	
	If vMessagesList.Count() > 0 Then
		CloseSelectedDocumentsAtServer(vMessagesList);
	EndIf;
EndProcedure // CloseSelectedCommand

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteMessage(pCommand)
	vMessagesList = New ValueList;
	For Each vSelRow In Items.Messages.SelectedRows Do
		vCurData = Messages.FindByID(vSelRow);
		If ValueIsFilled(vCurData.Message) Then
			vMessagesList.Add(vCurData.Message);
		EndIf;
	EndDo;
	
	If vMessagesList.Count() > 0 Then
		DeleteMessagesAtServer(vMessagesList);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenSelectedCommand(pCommand)
	vMessagesList = New ValueList;
	For Each vSelRow In Items.Messages.SelectedRows Do
		vCurData = Messages.FindByID(vSelRow);
		If ValueIsFilled(vCurData.Message) Then
			vMessagesList.Add(vCurData.Message);
		EndIf;
	EndDo;
	
	If vMessagesList.Count() > 0 Then
		OpenSelectedDocumentsAtServer(vMessagesList);
	EndIf;
EndProcedure // OpenSelectedCommand

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeStatusForSelectedCommand(pCommand)
	vType = Undefined;
	vMessagesList = New ValueList;
	For Each vSelRow In Items.Messages.SelectedRows Do
		vCurData = Messages.FindByID(vSelRow);
		If ValueIsFilled(vCurData.Message) Then
			If vType = Undefined Then
				vType = vCurData.Type;
			EndIf;
				
			vMessagesList.Add(vCurData.Message);
		EndIf;
	EndDo;
	If Not ValueIsFilled(vType) Then
		ShowMessageBox(, NStr("en='Nothing is selected or messages type is undefined!'; ru='Ничего не выбрано или тип сообщения не определен!'; de='Es ist nichts ausgewählt oder der Nachrichtentyp ist nicht definiert!'"));
		Return;
	EndIf;

	vExtraParams = New Structure("MessagesList", vMessagesList);
	vStatusesList = New ValueList();
	vStatusesList.LoadValues(GetAllMessageStatuses(vType));
	If vStatusesList.Count() = 0 Then
		ShowMessageBox(, NStr("en='No statuses are configured for the type: '; ru='Не настроены статусы для типа: '; de='Sind keine Status konfiguriert für den Typ: '") + String(vType) + "!");
		Return;
	EndIf;

	vStatusesList.ShowChooseItem(New NotifyDescription("MessageStatusAfterChoice", ThisObject, vExtraParams), NStr("en='Select status'; ru='Выбеите статус'; de='Status auswählen'"));
EndProcedure // ChangeStatusForSelectedCommand

// -----------------------------------------------------------------------------
&AtClient
Procedure MessageStatusAfterChoice(pUC, pExtraParams) Export
	If pUC <> Undefined Then
		ChangeStatusForSelectedAtServer(pExtraParams.MessagesList, pUC.Value);
	EndIf;
EndProcedure // MessageStatusAfterChoice

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowMessagesClient() 
	// Get current list position
	vCurDate = Undefined;
	vCurMessage = Undefined;
	vCurData = Items.Messages.CurrentData;
	If vCurData <> Undefined Then
		vCurDate = vCurData.AccountingDate;
		vCurMessage = vCurData.Message;
	EndIf;
	// Refresh list
	ShowMessages(vCurDate, vCurMessage);
EndProcedure	

// -----------------------------------------------------------------------------
&AtServer
Procedure ShowMessages(pCurDate = Undefined, pCurMessage = Undefined)
	// Clear messages
	Messages.Clear();
	vNewCurData = Undefined;
	
	// Read messages
	vInt = 1;
	vCurAccountingDate = '00010101';
	If Not ValueIsFilled(ByObject) Then
		ByObject = SessionParameters.CurrentUser;
	EndIf; 
	vHotelFilter = Undefined;
	If ValueIsFilled(SelHotel) Then
		vHotelFilter = New Array;	
		vHotelFilter.Add(SelHotel);
		vHotelFilter.Add(Catalogs.Hotels.EmptyRef());	
	EndIf;	
	vMsgTab = cmGetMessagesForObject(ByObject, ShowClosedMessages, SelDate, True, SelShowPopUpOnly, , , vHotelFilter);
	For Each vMsgTabRow In vMsgTab Do
		vRow = Messages.Add();
		vRow.AccountingDate = vMsgTabRow.AccountingDate;
		vRow.LineNumber = vMsgTabRow.Counter;
		If ValueIsFilled(vMsgTabRow.Recorder) Then
			If vCurAccountingDate <> vMsgTabRow.AccountingDate Then
				vCurAccountingDate = vMsgTabRow.AccountingDate;
				vInt = 1;
			EndIf;
			vRow.LineNumber = vInt;
			vRow.Period = vMsgTabRow.Period;
			vRow.Object = vMsgTabRow.Object;
			vRow.Remarks = TrimAll(vMsgTabRow.Remarks);
			vRow.LastComment = TrimAll(vMsgTabRow.LastComment);
			vRow.LastCommentPeriod = vMsgTabRow.LastCommentPeriod;
			vRow.LastCommentAuthor = vMsgTabRow.LastCommentAuthor;
			vRow.Type = vMsgTabRow.Type;
			vRow.MessageType = vMsgTabRow.MessageType;
			vRow.MessageStatus = vMsgTabRow.MessageStatus;
			vRow.PopUp = vMsgTabRow.PopUp;
			vRow.IsClosed = vMsgTabRow.IsClosed;
			vRow.ValidFromDate = vMsgTabRow.ValidFromDate;
			vRow.ValidToDate = vMsgTabRow.ValidToDate;
			vRow.CloseToDate = vMsgTabRow.CloseToDate;
			vRow.Author = vMsgTabRow.Author;
			vRow.Message = vMsgTabRow.Recorder;
			vRow.ForEmployee = vMsgTabRow.ForEmployee;
			vRow.ForDepartment = vMsgTabRow.ForDepartment;
			vRow.ContactPerson = vMsgTabRow.ContactPerson;
			vRow.Hotel = vMsgTabRow.Hotel;
			vRow.SMSIsSent = vMsgTabRow.Recorder.SMSIsSent;
			vRow.IsExpired = 0; 
			If ValueIsFilled(vRow.CloseToDate) Then
				If BegOfDay(vRow.CloseToDate) < BegOfDay(CurrentSessionDate()) Then
					vRow.IsExpired = 32;
				ElsIf SelNumberOfDaysToWarnBeforeExpire <> 0 And BegOfDay(vRow.CloseToDate) <= (BegOfDay(CurrentSessionDate()) + 24*3600*SelNumberOfDaysToWarnBeforeExpire) Then
					vRow.IsExpired = 31;
				EndIf;
			EndIf;
			If vMsgTabRow.Color <> Undefined And vMsgTabRow.Color <> Null Then
				vRow.Color = vMsgTabRow.Color.Get();
			EndIf;
			If vNewCurData = Undefined Then
				If vRow.Message = pCurMessage And ValueIsFilled(pCurMessage) Then
					vNewCurData = vRow;
				ElsIf vRow.AccountingDate = pCurDate And pCurDate <> Undefined And Not ValueIsFilled(pCurMessage) Then
					vNewCurData = vRow;
				EndIf;
			EndIf;
			
			vInt = vInt + 1;
		EndIf;
	EndDo;
	
	// Try to restore list position
	If vNewCurData <> Undefined Then
		Items.Messages.CurrentRow = vNewCurData.GetID();
	EndIf;
EndProcedure // ShowMessages

// -----------------------------------------------------------------------------
Function GetObjectMetadataName(pObject)
	Return pObject.Metadata().FullName();
EndFunction // GetObjectMetadataName

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCurrentEmployee()
	Return SessionParameters.CurrentUser;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function MessagesIsClosedOnChangeAtServer(pAccountingDate, pMessageRef)
	vHavePermissionToCloseOpenTasks = cmCheckUserPermissions("HavePermissionToCloseOpenTasks");
	If ValueIsFilled(pMessageRef) Then
		vMessageObj = pMessageRef.GetObject();
		If Not vMessageObj.IsClosed And Not vHavePermissionToCloseOpenTasks Then  
			vErr = NStr("en = 'You do not have permissions to close open tasks!'; de = 'Sie haben keine Rechte, offene Aufgaben zu schließen!'; ru = 'Нет прав на закрытие открытых задач!'");
			tcCommonFunctionOnClientServer.TextMessage(vErr);
			Return False;
		EndIf;
		vMessageObj.IsClosed = Not vMessageObj.IsClosed;
		vMessageObj.Write(DocumentWriteMode.Posting);
	Else
		// Do for each message row in date selected
		For Each vMsgRow In Messages Do
			If ValueIsFilled(vMsgRow.Message) And vMsgRow.AccountingDate = pAccountingDate Then
				vMessageObj = vMsgRow.Message.GetObject();
				If Not vMessageObj.IsClosed And Not vHavePermissionToCloseOpenTasks Then  
					vErr = NStr("en = 'You do not have permissions to close open tasks!'; de = 'Sie haben keine Rechte, offene Aufgaben zu schließen!'; ru = 'Нет прав на закрытие открытых задач!'");
					tcCommonFunctionOnClientServer.TextMessage(vErr);
					Return False;
				EndIf;
				vMessageObj.IsClosed = Not vMessageObj.IsClosed;
				vMessageObj.Write(DocumentWriteMode.Posting);
			EndIf;
		EndDo;
	EndIf;
	Return True;
EndFunction // MessagesIsClosedOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure MessagesStatusOnChangeAtServer(pAccountingDate, pMessageRef, pMessageStatus, pCurrentData)
	If ValueIsFilled(pMessageRef) Then
		If ValueIsFilled(pMessageStatus) Then
			vMessageObj = pMessageRef.GetObject();
			vMessageObj.MessageStatus = pMessageStatus;
			vMessageObj.IsClosed = pMessageStatus.IsClosed;
			vMessageObj.Write(DocumentWriteMode.Posting);
		Else
			pCurrentData.MessageStatus = pMessageRef.MessageStatus;
		EndIf;
	Else
		// Do for each message row in date selected
		If ValueIsFilled(pMessageStatus) Then
			For Each vMsgRow In Messages Do
				If ValueIsFilled(vMsgRow.Message) And vMsgRow.AccountingDate = pAccountingDate Then
					vMessageObj = vMsgRow.Message.GetObject();
					vMessageObj.IsClosed = Not vMessageObj.IsClosed;
					vMessageObj.Write(DocumentWriteMode.Posting);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // MessagesStatusOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName AS PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND ObjectPrintingForms.ObjectType = &ObjectType
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	
	Query.SetParameter("ObjectType", Documents.Message.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = SessionParameters.CurrentLanguage;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language Or Not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf Not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, Items.FormGroupPrintingNotDefaultExtra, "Print" + SelectionRecords.Language, "FormGroup",
			New Structure("Type,Title",
			FormGroupType.Popup, SelectionRecords.Language));
		EndIf;
		
		While SelectionDetailRecords.Next() Do
			vNewRow = PrintForms.Add();
			vNewRow.PrintForm = SelectionDetailRecords.Ref;
			vNewRow.IsDefault = SelectionDetailRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Print" + vID);
			vCommand.Action = "PrintButtonClick";
			If SelectionDetailRecords.IsDefault Then
				vParent = Items.FormGroupPrintingDefault;
			Else
				vParent = vParentLang;
			EndIf;
			vStructure = New Structure("Title, CommandName",
										TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.ref), 
										"Print" + vID);
			        
			tcOnServer.cmCreateItem(ThisObject, vParent, "Print" + vID, "FormButton", vStructure);
		EndDo;
	EndDo;
EndProcedure // FillPrintingButton

// -----------------------------------------------------------------------------
//
// Parameters:
//  pActionsNumber	 - String - Choosed print form number
// 
// Returns:
// 	Structure - Print form data 
//
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref", vPrintForms);
	vStruct.Insert("PredefinedDataName", vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing", vPrintForms.ExternalProcessing);
	vStruct.Insert("Report", vPrintForms.Report);
	vStruct.Insert("Language", vPrintForms.Language);
	
	Return vStruct;
EndFunction // GetPrintFormForNumber

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef, pMessagesList)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage");
	vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef, "FileName")));
	vParams = New Structure("InputParameter, ObjectPrintingForm", pMessagesList, pPrintFormTypeRef);
	OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef, pMessagesList)
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef, "Report"), "ExternalProcessingStorage"); 
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("Document, ObjectPrintingForm", pMessagesList, pPrintFormTypeRef);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPath		 - String - Path to external data processor
//  pName		 - String - Data processor name
//  pUseSafeMode - Boolean - Use safe mode
// 
// Returns:
//  String - Name of data processor to open it
//
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
//
// Parameters:
//  pStr - String - External processing name to validate 
// 
// Returns:
//  String - Valid name
//
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPath		 - String - Path to external report
//  pName		 - String - Report name
//  pUseSafeMode - Boolean - Use safe mode
// 
// Returns:
//  String - Name of report to open it 
//
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAllMessageStatuses(pType = Undefined)
	vStatuses = cmGetAllMessageStatuses(pType);
	Return vStatuses.UnloadColumn("MessageStatus");
EndFunction // GetAllMessageStatuses

// -----------------------------------------------------------------------------
&AtServer
Procedure CloseSelectedDocumentsAtServer(pDocsList)
	For Each vListItem In pDocsList Do
		vDocObj = vListItem.Value.GetObject();
		If vDocObj.Posted Then
			vDocObj.IsClosed = True;
			vDocObj.Write(DocumentWriteMode.Posting);
		Endif;
	EndDo;
	ShowMessages();
EndProcedure // CloseSelectedDocumentsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure OpenSelectedDocumentsAtServer(pDocsList)
	For Each vListItem In pDocsList Do
		vDocObj = vListItem.Value.GetObject();
		vDocObj.IsClosed = False;
		vDocObj.DeletionMark = False;
		vDocObj.Write(DocumentWriteMode.Posting);
	EndDo;
	ShowMessages();
EndProcedure // CloseSelectedDocumentsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeStatusForSelectedAtServer(pDocsList, pStatus)
	For Each vListItem In pDocsList Do
		vDocObj = vListItem.Value.GetObject();
		If pStatus.Type = vDocObj.Type Then
			vDocObj.MessageStatus = pStatus;
			vDocObj.IsClosed = pStatus.IsClosed;
			vDocObj.DeletionMark = False;
			vDocObj.Write(DocumentWriteMode.Posting);
		EndIf;
	EndDo;
	ShowMessages();
EndProcedure // ChangeStatusForSelectedAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()
	// Hotel color
	If Not ValueIsFilled(SelHotel) Or ValueIsFilled(SelHotel) And SelHotel.IsFolder Then
		Items.GroupHotel.BackColor = Items.GroupMessagesList.BackColor;
	Else
		Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	EndIf;
EndProcedure // SelHotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteMessagesAtServer(pDocsList)
	For Each vListItem In pDocsList Do
		vDocObj = vListItem.Value.GetObject();
		If Not vDocObj.Posted And Not vDocObj.DeletionMark Or 
		   vDocObj.Posted And Not vDocObj.IsClosed Then
			vDocObj.SetDeletionMark(True);
		Else
			If vDocObj.DeletionMark Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Document is already deleted!'; ru='Документ уже помечен на удаление!'; de='Das Dokument ist bereits zum Löschen markiert!'") + " - " + TrimAll(vDocObj.Ref), MessageStatus.Information);
			ElsIf vDocObj.IsClosed Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Document is closed! Could not be deleted'; ru='Документ закрыт! Помечать на удаление запрещено'; de='Das Dokument ist geschlossen! Das Markieren zum Löschen ist verboten'") + " - " + TrimAll(vDocObj.Ref), MessageStatus.Information);
			EndIf;
		Endif;
	EndDo;
	ShowMessages();
EndProcedure // DeleteMessagesAtServer

#EndRegion
