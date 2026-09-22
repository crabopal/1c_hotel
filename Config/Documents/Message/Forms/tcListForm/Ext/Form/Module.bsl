
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelHotel = SessionParameters.CurrentHotel;
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;  
	SelHotelOnChangeAtServer();
	// Check if statuses are used
	vStatuses = GetAllMessageStatuses();
	If vStatuses.Count() > 0 Then
		Items.SelStatus.Visible = True;
		Items.MessageStatus.Visible = True;
		Items.FormGroupOpenClose.Visible = False;
		Items.FormChangeStatusForSelectedCommand.Visible = True;
	Else
		Items.SelStatus.Visible = False;
		Items.MessageStatus.Visible = False;
		Items.FormGroupOpenClose.Visible = True;
		Items.FormChangeStatusForSelectedCommand.Visible = False;
	EndIf;
	// Load saved options
	vType = SystemSettingsStorage.Load("Document.Message.ListForm", "Type");
	If vType <> Undefined Then
		SelType = vType;
	EndIf;
	vNumberOfDaysToWarnBeforeExpire = SystemSettingsStorage.Load("Document.Message.ListForm", "NumberOfDaysToWarnBeforeExpire");
	If vNumberOfDaysToWarnBeforeExpire <> Undefined And TypeOf(vNumberOfDaysToWarnBeforeExpire) = Type("Number") Then
		SelNumberOfDaysToWarnBeforeExpire = vNumberOfDaysToWarnBeforeExpire;
	Else
		SelNumberOfDaysToWarnBeforeExpire = 3;
	EndIf;
	// Set list parameters
	List.Parameters.SetParameterValue("qDateFrom", SelDateFrom);
	List.Parameters.SetParameterValue("qDateTo", ?(ValueIsFilled(SelDateTo), EndOfDay(SelDateTo), '39991231235959'));
	List.Parameters.SetParameterValue("qType", SelType);
	List.Parameters.SetParameterValue("qTypeIsFilled", ValueIsFilled(SelType));
	List.Parameters.SetParameterValue("qShowClosed", SelShowClosed);
	List.Parameters.SetParameterValue("qStatus", SelStatus);
	List.Parameters.SetParameterValue("qStatusIsFilled", ValueIsFilled(SelStatus));
	List.Parameters.SetParameterValue("qDepartment", SelDepartment);
	List.Parameters.SetParameterValue("qDepartmentIsFilled", ValueIsFilled(SelDepartment));
	List.Parameters.SetParameterValue("qEmployee", SelEmployee);
	List.Parameters.SetParameterValue("qEmployeeIsFilled", ValueIsFilled(SelEmployee));
	List.Parameters.SetParameterValue("qMessageType", SelMessageType);
	List.Parameters.SetParameterValue("qMessageTypeIsFilled", ValueIsFilled(SelMessageType));
	List.Parameters.SetParameterValue("qByObject", SelByObject);
	List.Parameters.SetParameterValue("qByObjectIsFilled", ValueIsFilled(SelByObject));
	List.Parameters.SetParameterValue("qRoom", SelRoom);
	List.Parameters.SetParameterValue("qRoomIsFilled", ValueIsFilled(SelRoom));
	List.Parameters.SetParameterValue("qResource", SelResource);
	List.Parameters.SetParameterValue("qResourceIsFilled", ValueIsFilled(SelResource));
	List.Parameters.SetParameterValue("qGuestGroup", SelGuestGroup);
	List.Parameters.SetParameterValue("qGuestGroupIsFilled", ValueIsFilled(SelGuestGroup));
	List.Parameters.SetParameterValue("qAuthor", SelAuthor);
	List.Parameters.SetParameterValue("qAuthorIsFilled", ValueIsFilled(SelAuthor));
	List.Parameters.SetParameterValue("qClosedBy", SelClosedBy);
	List.Parameters.SetParameterValue("qClosedByIsFilled", ValueIsFilled(SelClosedBy));
	List.Parameters.SetParameterValue("qCustomer", SelCustomer);
	List.Parameters.SetParameterValue("qCustomerIsFilled", ValueIsFilled(SelCustomer));
	List.Parameters.SetParameterValue("qContactPerson", SelContactPerson);
	List.Parameters.SetParameterValue("qContactPersonIsFilled", ValueIsFilled(SelContactPerson));
	List.Parameters.SetParameterValue("qShowExpiredOnly", SelShowExpiredOnly);
	List.Parameters.SetParameterValue("qShowPopUpOnly", SelShowPopUpOnly);
	List.Parameters.SetParameterValue("qNumberOfDaysToWarnBeforeExpire", SelNumberOfDaysToWarnBeforeExpire);
	List.Parameters.SetParameterValue("qEmptyDate", '00010101');
	List.Parameters.SetParameterValue("qCurrentDate", BegOfDay(CurrentSessionDate()));
	// Printing
	FillPrintingButton(); 
EndProcedure

#EndRegion 

#Region FormHeaderItemsEventHandlers
		   
// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
	List.Parameters.SetParameterValue("qHotel", SelHotel);
	List.Parameters.SetParameterValue("qHotelIsFilled", ValueIsFilled(SelHotel));
EndProcedure // SelHotelOnChange		   

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = tcOnServer.CheckIfHotelCouldBeCleared();
	If pStandardProcessing Then
		SelHotelOnChangeAtServer();
	EndIf;
EndProcedure // SelHotelClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateFromOnChange(pItem)
	If SelDateFrom > SelDateTo Then
		SelDateTo = '00010101';
	EndIf;
	List.Parameters.SetParameterValue("qDateFrom", SelDateFrom);
	List.Parameters.SetParameterValue("qDateTo", ?(ValueIsFilled(SelDateTo), EndOfDay(SelDateTo), '39991231235959'));
EndProcedure // SelDateFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateToOnChange(pItem)
	If SelDateFrom <= SelDateTo Or Not ValueIsFilled(SelDateTo) Then
		List.Parameters.SetParameterValue("qDateFrom", SelDateFrom);
		List.Parameters.SetParameterValue("qDateTo", ?(ValueIsFilled(SelDateTo), EndOfDay(SelDateTo), '39991231235959'));
	EndIf;
EndProcedure // SelDateToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelTypeOnChange(pItem)
	SelTypeOnChangeAtServer();
EndProcedure // SelTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelStatusOnChange(pItem)
	If ValueIsFilled(SelStatus) And tcOnServer.cmGetAttributeByRef(SelStatus, "IsClosed") Then
		SelShowClosed = True;
	EndIf;
	List.Parameters.SetParameterValue("qShowClosed", SelShowClosed);
	List.Parameters.SetParameterValue("qStatus", SelStatus);
	List.Parameters.SetParameterValue("qStatusIsFilled", ValueIsFilled(SelStatus));
EndProcedure // SelStatusOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDepartmentOnChange(pItem)
	List.Parameters.SetParameterValue("qDepartment", SelDepartment);
	List.Parameters.SetParameterValue("qDepartmentIsFilled", ValueIsFilled(SelDepartment));
EndProcedure // SelDepartmentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelEmployeeOnChange(pItem)
	List.Parameters.SetParameterValue("qEmployee", SelEmployee);
	List.Parameters.SetParameterValue("qEmployeeIsFilled", ValueIsFilled(SelEmployee));
EndProcedure // SelEmployeeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelMessageTypeOnChange(pItem)
	List.Parameters.SetParameterValue("qMessageType", SelMessageType);
	List.Parameters.SetParameterValue("qMessageTypeIsFilled", ValueIsFilled(SelMessageType));
EndProcedure // SelMessageTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelByObjectOnChange(pItem)
	List.Parameters.SetParameterValue("qByObject", SelByObject);
	List.Parameters.SetParameterValue("qByObjectIsFilled", ValueIsFilled(SelByObject));
EndProcedure // SelByObjectOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	List.Parameters.SetParameterValue("qRoom", SelRoom);
	List.Parameters.SetParameterValue("qRoomIsFilled", ValueIsFilled(SelRoom));
EndProcedure // SelRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelResourceOnChange(pItem)
	List.Parameters.SetParameterValue("qResource", SelResource);
	List.Parameters.SetParameterValue("qResourceIsFilled", ValueIsFilled(SelResource));
EndProcedure // SelResourceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	List.Parameters.SetParameterValue("qGuestGroup", SelGuestGroup);
	List.Parameters.SetParameterValue("qGuestGroupIsFilled", ValueIsFilled(SelGuestGroup));
EndProcedure // SelGuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowAllOnChange(pItem)
	List.Parameters.SetParameterValue("qShowClosed", SelShowClosed);
EndProcedure // SelShowAllOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAuthorOnChange(pItem)
	List.Parameters.SetParameterValue("qAuthor", SelAuthor);
	List.Parameters.SetParameterValue("qAuthorIsFilled", ValueIsFilled(SelAuthor));
EndProcedure // SelAuthorOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClosedByOnChange(pItem)
	List.Parameters.SetParameterValue("qClosedBy", SelClosedBy);
	List.Parameters.SetParameterValue("qClosedByIsFilled", ValueIsFilled(SelClosedBy));
EndProcedure // SelClosedByOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(pItem)
	List.Parameters.SetParameterValue("qCustomer", SelCustomer);
	List.Parameters.SetParameterValue("qCustomerIsFilled", ValueIsFilled(SelCustomer));
EndProcedure // SelCustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelContactPersonOnChange(pItem)
	List.Parameters.SetParameterValue("qContactPerson", SelContactPerson);
	List.Parameters.SetParameterValue("qContactPersonIsFilled", ValueIsFilled(SelContactPerson));
EndProcedure // SelContactPersonOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowExpiredOnlyOnChange(pItem)
	List.Parameters.SetParameterValue("qShowExpiredOnly", SelShowExpiredOnly);
EndProcedure // SelShowExpiredOnlyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShowPopUpOnlyOnChange(pItem)
	List.Parameters.SetParameterValue("qShowPopUpOnly", SelShowPopUpOnly);
EndProcedure // SelShowPopUpOnlyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNumberOfDaysToWarnBeforeExpireOnChange(pItem)
	SelNumberOfDaysToWarnBeforeExpireOnChangeAtServer();
EndProcedure // SelNumberOfDaysToWarnBeforeExpireOnChange
		   
#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	vMessagesList = New ValueList;
	
	For Each vSelRow In Items.List.SelectedRows Do
		vMessagesList.Add(vSelRow);
	EndDo;
	
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
	ElsIf vPrintForm.PredefinedDataName = "MessagePrintForm" Then
		OpenForm("Document.Message.Form.tcMessagePrintForm", New Structure("InputParameter, ObjectPrintingForm", vMessagesList, vPrintForm.Ref), ThisObject);
	EndIf;
EndProcedure // PrintButtonClick

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseSelectedCommand(pCommand)
	vMessagesList = New ValueList;
	
	For Each vSelRow In Items.List.SelectedRows Do
		vMessagesList.Add(vSelRow);
	EndDo;
	
	If vMessagesList.Count() > 0 Then
		CloseSelectedDocumentsAtServer(vMessagesList);
	EndIf;
EndProcedure // CloseSelectedCommand

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenSelectedCommand(pCommand)
	vMessagesList = New ValueList;
	
	For Each vSelRow In Items.List.SelectedRows Do
		vMessagesList.Add(vSelRow);
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
	For Each vSelRow In Items.List.SelectedRows Do
		If vType = Undefined Then
			vType = tcOnServer.cmGetAttributeByRef(vSelRow, "Type");
		EndIf;
			
		vMessagesList.Add(vSelRow);
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

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodCommand(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = SelDateFrom;
	vChoosePeriodDialog.Period.EndDate = SelDateTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisObject));
EndProcedure // ChoosePeriodCommand

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		SelDateFrom = pPeriod.StartDate;
		SelDateTo = pPeriod.EndDate;
		If SelDateTo >= SelDateFrom Or Not ValueIsFilled(SelDateTo) Then
			List.Parameters.SetParameterValue("qDateFrom", SelDateFrom);
			List.Parameters.SetParameterValue("qDateTo", ?(ValueIsFilled(SelDateTo), EndOfDay(SelDateTo), '39991231235959'));
		EndIf;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

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
	Items.List.Refresh();
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
	Items.List.Refresh();
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
	Items.List.Refresh();
EndProcedure // ChangeStatusForSelectedAtServer

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
			vStructure = New Structure("Title,CommandName",
			TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.ref), "Print" + vID);
			        
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
&AtServer
Procedure SelHotelOnChangeAtServer()
	List.Parameters.SetParameterValue("qHotel", SelHotel);
	List.Parameters.SetParameterValue("qHotelIsFilled", ValueIsFilled(SelHotel));
	// Hotel color
	If Not ValueIsFilled(SelHotel) Or ValueIsFilled(SelHotel) And SelHotel.IsFolder Then
		Items.GroupHotel.BackColor = Items.GroupSearchMode.BackColor;
	Else
		Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	EndIf;
EndProcedure // SelHotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAllMessageStatuses(pType = Undefined)
	vStatuses = cmGetAllMessageStatuses(pType);
	Return vStatuses.UnloadColumn("MessageStatus");
EndFunction // GetAllMessageStatuses

// -----------------------------------------------------------------------------
&AtServer
Procedure SelTypeOnChangeAtServer()
	List.Parameters.SetParameterValue("qType", SelType);
	List.Parameters.SetParameterValue("qTypeIsFilled", ValueIsFilled(SelType));
	SystemSettingsStorage.Save("Document.Message.ListForm", "Type", SelType);
EndProcedure // SelTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SelNumberOfDaysToWarnBeforeExpireOnChangeAtServer()
	List.Parameters.SetParameterValue("qNumberOfDaysToWarnBeforeExpire", SelNumberOfDaysToWarnBeforeExpire);
	SystemSettingsStorage.Save("Document.Message.ListForm", "NumberOfDaysToWarnBeforeExpire", SelNumberOfDaysToWarnBeforeExpire);
EndProcedure // SelNumberOfDaysToWarnBeforeExpireOnChangeAtServer

#EndRegion
