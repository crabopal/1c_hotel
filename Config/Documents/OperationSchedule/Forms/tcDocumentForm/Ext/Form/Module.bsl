#Region Variables

// ----------------------------------------------------------------------------
&AtClient
Var HTMLOperationSchedule;

#EndRegion

#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vObj = FormAttributeToValue("Object");
	If vObj.IsNew() Then
		If Parameters.Property("SelHotel") Then
			vObj.Hotel = Parameters.SelHotel;
		EndIf;
		// Use current time by default
		vObj.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
		If ValueIsFilled(vObj.Author) Then
			If ValueIsFilled(vObj.Author.Room) Then
				vObj.Room = vObj.Author.Room;
			EndIf;
			If ValueIsFilled(vObj.Author.RoomSection) Then
				vObj.RoomSection = vObj.Author.RoomSection;
			EndIf;
		EndIf;
		ThisForm.Modified = True;
	Else
		// Printing button appearance
		FillPrintingButton();
	EndIf;
	
	// Check edit prohibited date
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Hotel.EditProhibitedDate) And 
			BegOfDay(vObj.Hotel.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
	
	// Fill employees list
	SetEmployeesChoiceList(vObj);
	// Fill operations list
	SetOperationsChoiceList(vObj);
	// Set totals presentation
	SetTotalsPresentation(vObj);
	// Set printing forms appearance
	SetPrintingFormsAppearance();
	// Fill room statuses filter
	FillSelRoomStatuses();
	// Fill room filter
	FillSelRooms(vObj);
	// Fill room type filter
	FillSelRoomTypes(vObj);
	// Fill shortcuts filter
	FillSelShortcuts();
	// Fill operations filter
	FillSelOperations();
	// Fill employees filter
	FillSelEmployees();
	// Save current document date
	OldDate = vObj.Date;
	
	HTML = vObj.GetTemplate("HTML").GetText();
	
	FillPictureInHTML();
	
	// Set hotel color
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(vObj.Hotel, "BackgroundColorImportant");
	
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	vCurSession = GetCurrentInfoBaseSession();
	IsMobileDeviceMode = CachedCommonFunctions.cmGetAppRunMode(vCurSession.SessionNumber, vCurSession.SessionStarted).MobileDeviceMode;
	
	If IsMobileDeviceMode Then
		Items.GroupFolderHeader.ShowTitle = True;
		Items.GroupFolderHeader.Behavior = UsualGroupBehavior.PopUp;
	EndIf;
	
	Seed = 2345678901;
	
	// Old document opening
	If BegOfDay(CurrentSessionDate()) > BegOfDay(Object.Date) And ValueIsFilled(Object.Date) Then
		Items.FormFillOperations.Enabled = False;
		Items.FormUpdateOperations.Enabled = False;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Catalog.Rooms.Write" Then
		vRoomStatus = UpdateRoomStatusAtServer(pParameter);
		HTMLOperationSchedule.updateRoomStatus(vRoomStatus.idRoom, vRoomStatus.imgRoomStatus, vRoomStatus.colorRoomStatus);
	ElsIf pEventName = "OperationSchedule.EmployeeAssignment" And pSource = ThisForm Then
		HTMLOperationSchedule.updateEmployee(GetHTMLObj(UpdateRoomEmployeeAtServer(pParameter)));
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// APDEX
		vKeyOperation = "Document.OperationSchedule.Form.tcDocumentForm.Posting";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	EndIf;
EndProcedure // BeforeWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeesEmployeeOnChange(pItem)
	vCurRow = Items.Employees.CurrentData;
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.Employee) Then
			vEmployeeStruct = tcOnServer.cmGetAtributeAsArray(vCurRow.Employee);
			vCurRow.Department = vEmployeeStruct.Department;
			vCurRow.EmployeeSortCode = vEmployeeStruct.SortCode;
			If ValueIsFilled(vEmployeeStruct.RoomSection) Then
				vCurRow.RoomSection = vEmployeeStruct.RoomSection;
			EndIf;
			If ValueIsFilled(vEmployeeStruct.Room) Then
				vCurRow.Room = vEmployeeStruct.Room;
			EndIf;
			If ValueIsFilled(vEmployeeStruct.RoomFolderFrom) Then
				vCurRow.RoomFolderFrom = vEmployeeStruct.RoomFolderFrom;
			EndIf;
			If ValueIsFilled(vEmployeeStruct.RoomFolderTo) Then
				vCurRow.RoomFolderTo = vEmployeeStruct.RoomFolderTo;
			EndIf;
		Else
			vCurRow.Department = PredefinedValue("Catalog.Departments.EmptyRef");
			vCurRow.EmployeeSortCode = 0;
		EndIf;
	EndIf;
EndProcedure // EmployeesEmployeeOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure EmployeesOnEditEnd(pItem, pNewRow, pCancelEdit)
	SetEmployeesChoiceList();
EndProcedure // EmployeesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeesAfterDeleteRow(pItem)
	SetEmployeesChoiceList();
EndProcedure // EmployeesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeesChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If TypeOf(pSelectedValue) = Type("Array") Then
		For Each vEmployee In pSelectedValue Do
			vCurRow = Object.Employees.Add();
			vCurRow.Employee = vEmployee;
			vEmployeeStruct = tcOnServer.cmGetAtributeAsArray(vCurRow.Employee);
			vCurRow.Department = vEmployeeStruct.Department;
			vCurRow.EmployeeSortCode = vEmployeeStruct.SortCode;
			If ValueIsFilled(vEmployeeStruct.RoomSection) Then
				vCurRow.RoomSection = vEmployeeStruct.RoomSection;
			EndIf;
			If ValueIsFilled(vEmployeeStruct.Room) Then
				vCurRow.Room = vEmployeeStruct.Room;
			EndIf;
			If ValueIsFilled(vEmployeeStruct.RoomFolderFrom) Then
				vCurRow.RoomFolderFrom = vEmployeeStruct.RoomFolderFrom;
			EndIf;
			If ValueIsFilled(vEmployeeStruct.RoomFolderTo) Then
				vCurRow.RoomFolderTo = vEmployeeStruct.RoomFolderTo;
			EndIf;
		EndDo;
	ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.Employees") And ValueIsFilled(pSelectedValue) Then
		vCurRow = Object.Employees.Add();
		vCurRow.Employee = pSelectedValue;
		vEmployeeStruct = tcOnServer.cmGetAtributeAsArray(vCurRow.Employee);
		vCurRow.Department = vEmployeeStruct.Department;
		vCurRow.EmployeeSortCode = vEmployeeStruct.SortCode;
		If ValueIsFilled(vEmployeeStruct.RoomSection) Then
			vCurRow.RoomSection = vEmployeeStruct.RoomSection;
		EndIf;
		If ValueIsFilled(vEmployeeStruct.Room) Then
			vCurRow.Room = vEmployeeStruct.Room;
		EndIf;
		If ValueIsFilled(vEmployeeStruct.RoomFolderFrom) Then
			vCurRow.RoomFolderFrom = vEmployeeStruct.RoomFolderFrom;
		EndIf;
		If ValueIsFilled(vEmployeeStruct.RoomFolderTo) Then
			vCurRow.RoomFolderTo = vEmployeeStruct.RoomFolderTo;
		EndIf;
	EndIf;
	SetEmployeesChoiceList();
EndProcedure // EmployeesChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	For i = 0 To (SelRooms.Count() - 1) Do
		vSelRoomsItem = SelRooms.Get(i);
		If i = pSelectedRow Then
			vSelRoomsItem.Check = True;
		Else
			vSelRoomsItem.Check = False;
		EndIf;
	EndDo;
EndProcedure // SelRoomsSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	For i = 0 To (SelRoomTypes.Count() - 1) Do
		vSelRoomTypesItem = SelRoomTypes.Get(i);
		If i = pSelectedRow Then
			vSelRoomTypesItem.Check = True;
		Else
			vSelRoomTypesItem.Check = False;
		EndIf;
	EndDo;
EndProcedure // SelRoomTypesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomStatusesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	For i = 0 To (SelRoomStatuses.Count() - 1) Do
		vSelRoomStatusesItem = SelRoomStatuses.Get(i);
		If i = pSelectedRow Then
			vSelRoomStatusesItem.Check = True;
		Else
			vSelRoomStatusesItem.Check = False;
		EndIf;
	EndDo;
EndProcedure // SelRoomStatusesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SelOperationsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	For i = 0 To (SelOperations.Count() - 1) Do
		vSelOperationsItem = SelOperations.Get(i);
		If i = pSelectedRow Then
			vSelOperationsItem.Check = True;
		Else
			vSelOperationsItem.Check = False;
		EndIf;
	EndDo;
EndProcedure // SelOperationsSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SelEmployeesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If pSelectedRow <> Undefined Then
		vSelectedRow = SelEmployees.FindByID(pSelectedRow);
		If vSelectedRow <> Undefined Then
			For i = 0 To (SelEmployees.Count() - 1) Do
				vSelEmployeesItem = SelEmployees.Get(i);
				If vSelEmployeesItem.Value = vSelectedRow.Value Then
					vSelEmployeesItem.Check = True;
				Else
					vSelEmployeesItem.Check = False;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // SelEmployeesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShortcutsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	For i = 0 To (SelShortcuts.Count() - 1) Do
		vSelRoomTypesItem = SelShortcuts.Get(i);
		If i = pSelectedRow Then
			vSelRoomTypesItem.Check = True;
		Else
			vSelRoomTypesItem.Check = False;
		EndIf;
	EndDo;
EndProcedure // SelShortcutsSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SelShortcutsOnChange(pItem)
	vShowAllRooms = SelShortcuts.FindByValue("ShowAllRooms");
	vShowDirtyRooms = SelShortcuts.FindByValue("ShowDirtyRooms");
	vShowCleanRooms = SelShortcuts.FindByValue("ShowCleanRooms");
	vShowVacantRooms = SelShortcuts.FindByValue("ShowVacantRooms");
	vShowOccupiedRooms = SelShortcuts.FindByValue("ShowOccupiedRooms");
	vShowPlannedCheckIn = SelShortcuts.FindByValue("ShowPlannedCheckIn");
	vShowPlannedCheckOut = SelShortcuts.FindByValue("ShowPlannedCheckOut");
	vShowCheckedIn = SelShortcuts.FindByValue("ShowCheckedIn");
	vShowCheckedOut = SelShortcuts.FindByValue("ShowCheckedOut");
	vShowRoomsWithTasks = SelShortcuts.FindByValue("ShowRoomsWithTasks");
	vShowRoomsWithDiscrepancies = SelShortcuts.FindByValue("ShowRoomsWithDiscrepancies");
	vShowRoomsBlock = SelShortcuts.FindByValue("ShowRoomsBlock");
	vShowRoomsStopSale = SelShortcuts.FindByValue("ShowRoomsStopSale");
	If pItem.CurrentData.Value = "ShowAllRooms" Then
		vShowAllRooms.Check = ?(Not vShowAllRooms.Check, True, vShowAllRooms.Check);
		vOldCheck = vShowAllRooms.Check;
		SelShortcuts.FillChecks(False);
		vShowAllRooms.Check = vOldCheck;
		SelRoomStatuses.FillChecks(True);
	ElsIf pItem.CurrentData.Value = "ShowDirtyRooms" Then
		If vShowDirtyRooms.Check Then
			vShowAllRooms.Check = False;
			CheckDirtyStatuses(SelRoomStatuses, Object.Hotel);
			vShowCleanRooms.Check = False;
		Else
			vShowAllRooms.Check = True;
			SelRoomStatuses.FillChecks(True);
			vShowCleanRooms.Check = False;
		EndIf;
		vShowRoomsWithTasks.Check = False;
		vShowRoomsWithDiscrepancies.Check = False;
	ElsIf pItem.CurrentData.Value = "ShowCleanRooms" Then
		If vShowCleanRooms.Check Then
			vShowAllRooms.Check = False;
			CheckCleanStatuses(SelRoomStatuses, Object.Hotel);
			vShowDirtyRooms.Check = False;
		Else
			vShowAllRooms.Check = True;
			SelRoomStatuses.FillChecks(True);
			vShowDirtyRooms.Check = False;
		EndIf;
		vShowRoomsWithTasks.Check = False;
		vShowRoomsWithDiscrepancies.Check = False;
	ElsIf pItem.CurrentData.Value = "ShowVacantRooms" Then
		vShowAllRooms.Check = ?(vShowVacantRooms.Check, False, vShowAllRooms.Check);
		vShowOccupiedRooms.Check = False;
		vShowDirtyRooms.Check = False;
		vShowCleanRooms.Check = False;
		vShowRoomsWithTasks.Check = False;
		vShowRoomsWithDiscrepancies.Check = False;
		SelRoomStatuses.FillChecks(True);
	ElsIf pItem.CurrentData.Value = "ShowOccupiedRooms" Then
		vShowAllRooms.Check = ?(vShowOccupiedRooms.Check, False, vShowAllRooms.Check);
		vShowVacantRooms.Check = False;
		vShowDirtyRooms.Check = False;
		vShowCleanRooms.Check = False;
		vShowRoomsWithTasks.Check = False;
		vShowRoomsWithDiscrepancies.Check = False;
		SelRoomStatuses.FillChecks(True);
	ElsIf pItem.CurrentData.Value = "ShowPlannedCheckIn" Then
		vShowAllRooms.Check = ?(vShowPlannedCheckIn.Check, False, vShowAllRooms.Check);
		vShowDirtyRooms.Check = False;
		vShowCleanRooms.Check = False;
		SelRoomStatuses.FillChecks(True);
	ElsIf pItem.CurrentData.Value = "ShowPlannedCheckOut" Then
		vShowAllRooms.Check = ?(vShowPlannedCheckOut.Check, False, vShowAllRooms.Check);
		vShowDirtyRooms.Check = False;
		vShowCleanRooms.Check = False;
		SelRoomStatuses.FillChecks(True);
	ElsIf pItem.CurrentData.Value = "ShowCheckedIn" Then
		vShowAllRooms.Check = ?(vShowCheckedIn.Check, False, vShowAllRooms.Check);
		vShowCheckedOut.Check = False;
		vShowDirtyRooms.Check = False;
		vShowCleanRooms.Check = False;
		SelRoomStatuses.FillChecks(True);
	ElsIf pItem.CurrentData.Value = "ShowCheckedOut" Then
		vShowAllRooms.Check = ?(vShowCheckedOut.Check, False, vShowAllRooms.Check);
		vShowCheckedIn.Check = False;
		vShowDirtyRooms.Check = False;
		vShowCleanRooms.Check = False;
		SelRoomStatuses.FillChecks(True);
	ElsIf pItem.CurrentData.Value = "ShowRoomsWithTasks" Then		
		vShowAllRooms.Check = ?(vShowRoomsWithTasks.Check, False, vShowAllRooms.Check);
		vShowDirtyRooms.Check = False;
		vShowCleanRooms.Check = False;
		vShowVacantRooms.Check = False;
		vShowOccupiedRooms.Check = False;
		SelRoomStatuses.FillChecks(True);
	ElsIf pItem.CurrentData.Value = "ShowRoomsWithDiscrepancies" Then
		vShowAllRooms.Check = ?(vShowRoomsWithDiscrepancies.Check, False, vShowAllRooms.Check);
		vShowDirtyRooms.Check = False;
		vShowCleanRooms.Check = False;
		vShowVacantRooms.Check = False;
		vShowOccupiedRooms.Check = False;
		SelRoomStatuses.FillChecks(True);
	ElsIf pItem.CurrentData.Value = "ShowRoomsBlock" Then
		vShowAllRooms.Check = ?(vShowRoomsBlock.Check, False, vShowAllRooms.Check);
	ElsIf pItem.CurrentData.Value = "ShowRoomsStopSale" Then
		vShowAllRooms.Check = ?(vShowRoomsStopSale.Check, False, vShowAllRooms.Check);
	EndIf;
EndProcedure // SelShortcutsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SearchLineStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	HTMLOperationSchedule.Search(pItem.EditText);
EndProcedure // SearchLineStartChoice 

// -----------------------------------------------------------------------------
&AtClient
Procedure SearchLineClearing(pItem, pStandardProcessing)
	HTMLOperationSchedule.Search("");
EndProcedure // SearchLineClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure SearchLineTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	HTMLOperationSchedule.Search(pText);
EndProcedure // SearchLineTextEditEnd

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FillOperations(pCommand)
	If Object.Operations.Count() > 0 Then
		ShowQueryBox(New NotifyDescription("FillOperationsAfterConfirmation", ThisForm), NStr("en='Do you confirm that list of operations will be cleared and refilled? All employee assignments will be cleared too!';ru='Очистить таблицу работ и заполнить ее заново? Внимание: Все назначения будут очищены!';de='Arbeitstabelle löschen und sie neu ausfüllen? Achtung! Alle Bestimmungen werden gelöscht!'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	Else  
		vJsonArr = FillOperationsAtServer();
		// Draw operations in the document
		DrawOperations(vJsonArr);
	EndIf;
EndProcedure // FillOperations

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateOperations(pCommand)
	vJsonArr = UpdateOperationsAtServer();
	// Draw operations in the document  
	DrawOperations(vJsonArr);
EndProcedure // UpdateOperations

// -----------------------------------------------------------------------------
&AtClient
Procedure FillEmployeesByWorkingSchedule(pCommand)
	FillEmployeesByWorkingScheduleAtServer();
EndProcedure // FillEmployeesByWorkingSchedule

// -----------------------------------------------------------------------------
&AtClient
Procedure FillEmployeesByQuantity(pCommand)
	// Ask for number of housemaids and number of working hours per shift
	ShowInputNumber(New NotifyDescription("AfterInputOfNumberOfHousemaids", ThisForm), 0, NStr("en='Housemaids q-ty? (per shift)';ru='Кол-во горничных? (в смене))';de='Anzahl Zimmermädchen? (in der Schicht)'"), 3, 0);
EndProcedure // FillEmployeesByQuantity

// -----------------------------------------------------------------------------
&AtClient
Procedure ManualEmployeeAssignment(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	vEmployeeList = GetEmployeeList();
	If vEmployeeList.Count() > 0 Then
		vOperations = New Array();
		vTotalOperations = GetTotalOperations(vOperations);
		vParams = New Structure("Hotel, Operations, NumberOfEmployees, TotalEmployees, DocumentDate, TotalOperations, AveragePerEmployee, CheckedOutLabel, OccupiedLabel, RepairLabel, VacantLabel, OtherLabel, CheckOutCleaningCount, OccupiedRoomCleaningCount, RepairEndCleaningCount, VacantRoomCleaningCount, OtherOperationsCount, EmployeeList, CloseOnOwnerClose", 
		Object.Hotel,
		vOperations, 
		vOperations.Count(), 
		vEmployeeList.Count(), 
		Format(Object.Date, "DF=dd.MM.yyyy"), 
		Format(vTotalOperations.TotalOperationsCount, "ND=10;NFD=0;NZ="), 
		Format(RoundUp(vTotalOperations.TotalOperationsCount/?(vEmployeeList.Count() = 0, 1, vEmployeeList.Count()), 0), "ND=10;NFD=0;NZ=") + NStr("en=' opr.';ru=' работ';de=' Arbeiten'"),
		Format(RoundUp(vTotalOperations.CheckOutCleaningCount/?(vEmployeeList.Count() = 0, 1, vEmployeeList.Count()), 0), "ND=10;NFD=0;NZ=") + NStr("en=' checked-out';ru=' выезд';de=' Abreise'"),
		Format(RoundUp(vTotalOperations.RegularCleaningCount/?(vEmployeeList.Count() = 0, 1, vEmployeeList.Count()), 0), "ND=10;NFD=0;NZ=") + NStr("en=' occupied';ru=' занят';de=' Besetzt'"),
		Format(RoundUp(vTotalOperations.RepairEndCleaningCount/?(vEmployeeList.Count() = 0, 1, vEmployeeList.Count()), 0), "ND=10;NFD=0;NZ=") + NStr("en=' repair';ru=' ремонт';de=' Reparatur'"),
		Format(RoundUp(vTotalOperations.VacantRoomCleaningCount/?(vEmployeeList.Count() = 0, 1, vEmployeeList.Count()), 0), "ND=10;NFD=0;NZ=") + NStr("en=' vacant';ru=' своб.';de=' Frei'"),
		Format(RoundUp(vTotalOperations.OtherOperationsCount/?(vEmployeeList.Count() = 0, 1, vEmployeeList.Count()), 0), "ND=10;NFD=0;NZ=") + NStr("en=' other';ru=' другие';de=' Andere'"),
		vTotalOperations.CheckOutCleaningCount,
		vTotalOperations.RegularCleaningCount,
		vTotalOperations.RepairEndCleaningCount,  
		vTotalOperations.VacantRoomCleaningCount,
		vTotalOperations.OtherOperationsCount,
		vEmployeeList,
		True);
		If Not IsMobileDeviceMode Then
			OpenForm("Document.OperationSchedule.Form.tcRoomAssignment", vParams, ThisForm);
		Else
			OpenForm("Document.OperationSchedule.Form.mcRoomAssignment", vParams, ThisForm);
		EndIf;
	Else
		ShowMessageBox(, NStr("en='Fill employees available list!';ru='Заполните список доступных сотрудников!';de='Liste verfügbarer Mitarbeiter ausfüllen!'"));
	EndIf;
EndProcedure // ManualEmployeeAssignment

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectEmployees(pCommand)
	OpenForm("Catalog.Employees.ChoiceForm", New Structure("MultipleChoice", True), Items.Employees, ThisForm, , , , FormWindowOpeningMode.LockWholeInterface);
EndProcedure // SelectEmployees

// -----------------------------------------------------------------------------
&AtClient
Procedure AssignEmployeesByWorkingTime(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	HTMLOperationSchedule.updateEmployee(GetHTMLObj(AssignEmployeesByWorkingTimeAtServer(GetVisibleRooms())));
EndProcedure // AssignEmployeesByWorkingTime

// -----------------------------------------------------------------------------
&AtClient
Procedure AssignEmployeesBalanced(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	rEmpCount = 0;
	vAvgQuantity = GetInitialAverageQuantity(rEmpCount);
	If rEmpCount = 0 Then
		Return;
	EndIf;
	OpenForm("Document.OperationSchedule.Form.tcInputAverageNumberOfOperationsForm", vAvgQuantity, ThisForm, UUID, , , New NotifyDescription("AfterInputOfAverageQuantity", ThisForm, New Structure("EmployeesCount, InitAvgQuantity", rEmpCount, vAvgQuantity)));
EndProcedure // AssignEmployeesBalanced

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearEmployees(pCommand)
	HTMLOperationSchedule.updateEmployee(GetHTMLObj(ClearEmployeesAtServer(GetVisibleRooms())));
EndProcedure // ClearEmployees

// -----------------------------------------------------------------------------
&AtClient
Procedure ApplyFilter(pCommand)
	vOperationsArr = DrawOperationsAtServer();
	DrawOperations(vOperationsArr);
	CurrentItem = Items.HTML;
	Items.GroupRoomsFilter.Hidden();
EndProcedure // ApplyFilter

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintByEmployees(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Open printing form
	vParams = New Structure("SelHotel, SelRoom, SelRoomSection, SelEmployee, SelOperationSchedule, SelObjectPrintForm, SelShowDuration, SelShowNotAssigned, SelGroupBy", 
	Object.Hotel, Undefined, Undefined, Undefined, Object.Ref, PredefinedValue("Catalog.ObjectPrintingForms.OperationSchedulePrintOperationsByEmployees"), False, False, "");
	OpenForm("Document.OperationSchedule.Form.tcPrintOperations", vParams, ThisForm);
EndProcedure // PrintByEmployees

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintByEmployeesShort(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Open printing form
	vParams = New Structure("SelHotel, SelRoom, SelRoomSection, SelEmployee, SelOperationSchedule, SelObjectPrintForm, SelShowDuration, SelShowNotAssigned, SelGroupBy", 
	Object.Hotel, Undefined, Undefined, Undefined, Object.Ref, PredefinedValue("Catalog.ObjectPrintingForms.OperationSchedulePrintOperationsByEmployeesShort"), False, False, "");
	OpenForm("Document.OperationSchedule.Form.tcPrintOperations", vParams, ThisForm);
EndProcedure // PrintByEmployeesShort

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintNotAssignedOperations(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Open printing form
	vParams = New Structure("SelHotel, SelRoom, SelRoomSection, SelEmployee, SelOperationSchedule, SelObjectPrintForm, SelShowDuration, SelShowNotAssigned, SelGroupBy", 
	Object.Hotel, Undefined, Undefined, Undefined, Object.Ref, PredefinedValue("Catalog.ObjectPrintingForms.OperationSchedulePrintOperationsByEmployees"), False, True, "");
	OpenForm("Document.OperationSchedule.Form.tcPrintOperations", vParams, ThisForm);
EndProcedure // PrintNotAssignedOperations

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintByOperations(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Open printing form
	vParams = New Structure("SelHotel, SelRoom, SelRoomSection, SelEmployee, SelOperationSchedule, SelObjectPrintForm, SelShowDuration, SelShowNotAssigned, SelGroupBy", 
	Object.Hotel, Undefined, Undefined, Undefined, Object.Ref, PredefinedValue("Catalog.ObjectPrintingForms.OperationSchedulePrintOperationsByOperations"), False, False, "ByOperations");
	OpenForm("Document.OperationSchedule.Form.tcPrintOperations", vParams, ThisForm);
EndProcedure // PrintByOperations

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintByRooms(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Open printing form
	vParams = New Structure("SelHotel, SelRoom, SelRoomSection, SelEmployee, SelOperationSchedule, SelObjectPrintForm, SelShowDuration, SelShowNotAssigned, SelGroupBy", 
	Object.Hotel, Undefined, Undefined, Undefined, Object.Ref, PredefinedValue("Catalog.ObjectPrintingForms.OperationSchedulePrintOperationsByRooms"), False, False, "ByRooms");
	OpenForm("Document.OperationSchedule.Form.tcPrintOperations", vParams, ThisForm);
EndProcedure // PrintByRooms

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintEmployees(pCommand)
	// Save document first
	If ThisForm.Modified Then
		If Not ThisForm.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Open printing form
	vParams = New Structure("SelHotel, SelRoom, SelRoomSection, SelEmployee, SelOperationSchedule, SelObjectPrintForm, SelShowDuration, SelShowNotAssigned, SelGroupBy", 
	Object.Hotel, Undefined, Undefined, Undefined, Object.Ref, PredefinedValue("Catalog.ObjectPrintingForms.OperationSchedulePrintEmployees"), False, False, "");
	OpenForm("Document.OperationSchedule.Form.tcPrintOperations", vParams, ThisForm);
EndProcedure // PrintEmployees

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	// Save document first
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	// Choose processing type
	vPrintNumber = StrReplace(pCommand.Name, "Print", "");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to load external print form!';de = 'Das externe Druckformular konnte nicht geladen werden!';ru = 'Не удалось загрузить внешнюю печатную форму!'"));
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to load external print form!';de = 'Das externe Druckformular konnte nicht geladen werden!';ru = 'Не удалось загрузить внешнюю печатную форму!'"));
		EndTry;
	ElsIf vPrintForm.PredefinedDataName = "MessagePrintForm" Then
		OpenForm("Document.Message.Form.tcMessagePrintForm", New Structure("InputParameter, ObjectPrintingForm", Object.Ref, vPrintForm.Ref), ThisObject, Object.Ref);
	EndIf;
EndProcedure // PrintButtonClick

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName,
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
	Query.SetParameter("ObjectType", Documents.OperationSchedule.EmptyRef());
	QueryResult = Query.Execute();
	SelectionRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = SessionParameters.CurrentLanguage;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language Or Not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf Not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisForm,Items.FormGroupPrintingNotDefaultExtra,"Print"+SelectionRecords.Language,"FormGroup",
			New Structure("Type,Title",
			FormGroupType.Popup,SelectionRecords.Language));
		EndIf;
		
		While SelectionDetailRecords.Next() Do
			If SelectionDetailRecords.PredefinedDataName = "" Then
				vNewRow = PrintForms.Add();
				vNewRow.PrintForm = SelectionDetailRecords.Ref;
				vNewRow.IsDefault = SelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("Print"+vID);
				vCommand.Action = "PrintButtonClick";
				If SelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefault;
				Else
					vParent = vParentLang;
				EndIf;
				vStructure = New Structure("Title,CommandName",
				TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.ref),"Print"+vID);
				
				tcOnServer.cmCreateItem(ThisForm,vParent,"Print"+vID,"FormButton",vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure //  FillPrintingButton

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction // GetPrintFormForNumber

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage");
	vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef,"FileName")));
	vParams = New Structure("InputParameter, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
	OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef)
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef, "Report"), "ExternalProcessingStorage");
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("Document, ObjectPrintingForm", Object.Ref, pPrintFormTypeRef);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr);	
EndFunction // GetExternalProcessingValidName

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// ----------------------------------------------------------------------------
&AtServer
Procedure FillPictureInHTML()
	HTML = StrReplace(HTML, "{cake}", GetPictureIsBase64HTMLString(PictureLib.Cake));
	HTML = StrReplace(HTML, "{empty}", GetPictureIsBase64HTMLString(PictureLib.Empty));
	HTML = StrReplace(HTML, "{occupied}", GetPictureIsBase64HTMLString(PictureLib.Occupied));
	HTML = StrReplace(HTML, "{occupieddirty}", GetPictureIsBase64HTMLString(PictureLib.OccupiedDirty));
	HTML = StrReplace(HTML, "{roomstatuscleaning}", GetPictureIsBase64HTMLString(PictureLib.RoomStatusCleaning));
	HTML = StrReplace(HTML, "{roomstatusluggage}", GetPictureIsBase64HTMLString(PictureLib.RoomStatusLuggage));
	HTML = StrReplace(HTML, "{roomstatusmalfunction}", GetPictureIsBase64HTMLString(PictureLib.RoomStatusMalfunction));
	HTML = StrReplace(HTML, "{roomstatusrepair}", GetPictureIsBase64HTMLString(PictureLib.RoomStatusRepair));
	HTML = StrReplace(HTML, "{roomstatusreserved}", GetPictureIsBase64HTMLString(PictureLib.RoomStatusReserved));
	HTML = StrReplace(HTML, "{tidyingup}", GetPictureIsBase64HTMLString(PictureLib.TidyingUp));
	HTML = StrReplace(HTML, "{vacant}", GetPictureIsBase64HTMLString(PictureLib.Vacant));
	HTML = StrReplace(HTML, "{waiting}", GetPictureIsBase64HTMLString(PictureLib.Waiting));
	HTML = StrReplace(HTML, "{reserved}", GetPictureIsBase64HTMLString(PictureLib.Reserved));
	HTML = StrReplace(HTML, "{attention}", GetPictureIsBase64HTMLString(PictureLib.Attention));
	HTML = StrReplace(HTML, "{clients}", GetPictureIsBase64HTMLString(PictureLib.Clients));
	HTML = StrReplace(HTML, "{usercalendar}", GetPictureIsBase64HTMLString(PictureLib.UserCalendar));
	HTML = StrReplace(HTML, "{checkout}", GetPictureIsBase64HTMLString(PictureLib.CheckOut));
EndProcedure // FillPictureInHTML

// ----------------------------------------------------------------------------
&AtServer
Function GetPictureIsBase64HTMLString(pPicture)
	Return StrTemplate("data:image/%1;base64,%2", GetImageType(pPicture.Format()), StrReplace(Base64String(pPicture.GetBinaryData()), Chars.CR + Chars.LF, ""));
EndFunction // GetPictureIsBase64HTMLString

// ---------------------------------------------------------------------------- 
&AtServer
Function GetImageType(pFormat)
	vImageType = "png";	
	If pFormat = PictureFormat.JPEG Then
		vImageType = "jpeg";
	ElsIf pFormat = PictureFormat.SVG Then
		vImageType = "svg+xml";
	ElsIf pFormat = PictureFormat.GIF Then
		vImageType = "gif";
	ElsIf pFormat = PictureFormat.BMP Then
		vImageType = "bmp";
	EndIf;
	Return vImageType;
EndFunction //  GetImageType

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	// Automatically assign new document number if year has changed
	If ValueIsFilled(Object.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(Object.Date) Then
			vObj = FormAttributeToValue("Object");
			vObj.SetNewNumber();
			ValueToFormAttribute(vObj, "Object");
		EndIf;
		OldDate = Object.Date;
	EndIf;
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetEmployeesChoiceList(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	FillEmployees(vObj.Employees.Unload(, "Employee"));
	EmployeesList.Clear();
	For Each vEmpRow In vObj.Employees Do
		If ValueIsFilled(vEmpRow.Employee) Then
			If EmployeesList.FindByValue(vEmpRow.Employee) = Undefined Then
				EmployeesList.Add(vEmpRow.Employee, vObj.pmGetEmployeePresentation(vEmpRow));
			EndIf;
		EndIf;
	EndDo;
	EmployeesList.Add(Catalogs.Employees.EmptyRef(), vObj.pmGetEmployeePresentation(Undefined));
	// Fill employees filter
	FillSelEmployees();
EndProcedure // SetEmployeesChoiceList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEmployees(pEmployees)
	Employees.Clear();
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	Employees.Ref AS Employee,
	|	Employees.Description AS Description,
	|	Employees.Color AS Color
	|FROM
	|	Catalog.Employees AS Employees
	|WHERE
	|	NOT Employees.DeletionMark
	|	AND NOT Employees.IsFolder
	|	AND Employees.Ref IN(&qEmployees)";
	vQ.SetParameter("qEmployees", pEmployees);
	vResult = vQ.Execute().Unload();
	For Each vRow In vResult Do
		vNewRow = Employees.Add();
		FillPropertyValues(vNewRow, vRow,, "Color");
		vColor = vRow.Color.Get();
		If TypeOf(vColor) = Type("Color") Then
			vColor = cmGetRGB4WebColor(vColor);
			vNewRow.Color = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")";
		Else
			vNewRow.Color = "";
		EndIf;
	EndDo;
EndProcedure // FillEmployees

// -----------------------------------------------------------------------------
&AtServer
Procedure SetOperationsChoiceList(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	OperationsList.Clear();
	vAllOperations = cmGetAllOperations(vObj.Hotel);
	For Each vAllOperationsRow In vAllOperations Do
		OperationsList.Add(vAllOperationsRow.Operation, , , GetImgOperationPicture(vAllOperationsRow.Operation));
	EndDo;
	FillColorOperations(OperationsList);
	OperationsList.Add("DELETE", NStr("en = 'Delete operation';de = 'Arbeit löschen';ru = 'Удалить работу'"), , PictureLib.Delete);
EndProcedure // SetOperationsChoiceList 

// -----------------------------------------------------------------------------
&AtServer
Procedure FillColorOperations(pOperations)
	Operations.Clear();
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	Operations.Ref AS Operation,
	|	Operations.Color AS Color,
	|	Operations.Code AS Description
	|FROM
	|	Catalog.Operations AS Operations
	|WHERE
	|	NOT Operations.IsFolder
	|	AND NOT Operations.DeletionMark
	|	AND Operations.Ref IN(&qOperations)";
	vQ.SetParameter("qOperations", pOperations);
	vResult = vQ.Execute().Unload();
	For Each vRow In vResult Do
		vNewRow = Operations.Add();
		FillPropertyValues(vNewRow, vRow,, "Color");
		vColor = vRow.Color.Get();
		If TypeOf(vColor) = Type("Color") Then
			vColor = cmGetRGB4WebColor(vColor);
			vNewRow.Color = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")";
		Else
			vNewRow.Color = "";
		EndIf;
	EndDo;
EndProcedure // FillColorOperations

// -----------------------------------------------------------------------------
&AtServer
Procedure SetTotalsPresentation(pObj)
	// Calculate average totals per operations
	TOperationTotals = "";
	If pObj.Employees.Count() > 0 Then
		vTotalOperationsCount = pObj.Operations.Total("CheckOutCleaningCount") + pObj.Operations.Total("RegularCleaningCount") + pObj.Operations.Total("RepairEndCleaningCount") + pObj.Operations.Total("VacantRoomCleaningCount") + pObj.Operations.Total("OtherOperationsCount");
		TOperationTotals = NStr("EN='Total ';RU='В смене ';de='In der Schicht '") + pObj.Employees.Count() + NStr("EN=' employees';RU=' сотрудника';de=' Mitarbeiters'") + 
		", " + Format(vTotalOperationsCount, "ND=10;NFD=0;NZ=") + NStr("en=' oper. ';ru=' работ. ';de=' Arbeiten. '") + 
		NStr("EN='Average per employee ';RU='В среднем на 1 чел. ';de='Durchschnittlich pro Person '") + 
		cmFormatDurationInHours(Round((pObj.Operations.Total("Duration")/60)/pObj.Employees.Count(), 3)) + 
		" (" + Format(Round(pObj.Operations.Total("RoomSpace")/pObj.Employees.Count(), 2), "ND=8;NFD=2;NZ=")+ NStr("en=' sq.m)';ru=' кв.м)';de=' m2)'") + 
		", " + Format(RoundUp(vTotalOperationsCount/pObj.Employees.Count(), 0), "ND=10;NFD=0;NZ=") + NStr("en=' opr., incl. ';ru=' работ, в т.ч. ';de=' arbeiten, darunter '") + 
		Format(RoundUp(pObj.Operations.Total("CheckOutCleaningCount")/pObj.Employees.Count(), 0), "ND=10;NFD=0;NZ=") + NStr("en=' checked-out, ';ru=' выезд., ';de=' abreise., '") + 
		Format(RoundUp(pObj.Operations.Total("RegularCleaningCount")/pObj.Employees.Count(), 0), "ND=10;NFD=0;NZ=") + NStr("en=' occupied, ';ru=' занят., ';de=' besetzt., '") + 
		Format(RoundUp(pObj.Operations.Total("RepairEndCleaningCount")/pObj.Employees.Count(), 0), "ND=10;NFD=0;NZ=") + NStr("en=' repair, ';ru=' ремонт., ';de=' reparatur., '") + 
		Format(RoundUp(pObj.Operations.Total("VacantRoomCleaningCount")/pObj.Employees.Count(), 0), "ND=10;NFD=0;NZ=") + NStr("en=' vacant, ';ru=' своб., ';de=' frei, '")+ 
		Format(RoundUp(pObj.Operations.Total("OtherOperationsCount")/pObj.Employees.Count(), 0), "ND=10;NFD=0;NZ=") + NStr("en=' other';ru=' другие';de=' andere'");
	EndIf;
	// Set total duration presentation for operations
	TTotalOperationsDuration = cmFormatDurationInHours(pObj.Operations.Total("Duration")/60);
	// Set totals hours/duration presentation for employees
	Items.EmployeesHours.FooterText = cmFormatDurationInHours(pObj.Employees.Total("Hours"));
	Items.EmployeesDuration.FooterText = cmFormatDurationInHours(pObj.Employees.Total("Duration"));
	Items.EmployeesCheckOutCleaningCount.FooterText = Format(pObj.Employees.Total("CheckOutCleaningCount"), "NFD=0;NG=");
	Items.EmployeesRegularCleaningCount.FooterText = Format(pObj.Employees.Total("RegularCleaningCount"), "NFD=0;NG=");
	Items.EmployeesRepairEndCleaningCount.FooterText = Format(pObj.Employees.Total("RepairEndCleaningCount"), "NFD=0;NG=");
	Items.EmployeesVacantRoomCleaningCount.FooterText = Format(pObj.Employees.Total("VacantRoomCleaningCount"), "NFD=0;NG=");
	Items.EmployeesOtherOperationsCount.FooterText = Format(pObj.Employees.Total("OtherOperationsCount"), "NFD=0;NG=");
EndProcedure // SetTotalsPresentation

// -----------------------------------------------------------------------------
&AtServer
Procedure SetPrintingFormsAppearance()
	If Not Catalogs.ObjectPrintingForms.OperationSchedulePrintOperationsByRooms.IsActive Then
		Items.FormPrintByRooms.Visible = False;
	EndIf;
	If Not Catalogs.ObjectPrintingForms.OperationSchedulePrintOperationsByOperations.IsActive Then
		Items.FormPrintByOperations.Visible = False;
	EndIf;
	If Not Catalogs.ObjectPrintingForms.OperationSchedulePrintOperationsByEmployees.IsActive Then
		Items.FormPrintByEmployees.Visible = False;
	EndIf;
	If Not Catalogs.ObjectPrintingForms.OperationSchedulePrintEmployees.IsActive Then
		Items.PrintEmployees.Visible = False;
	EndIf;
EndProcedure // SetPrintingFormsAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure FillSelRoomStatuses()
	vRoomStatuses = cmGetAllRoomStatuses();
	SelRoomStatuses.Clear();
	SelRoomStatuses.Add(Catalogs.RoomStatuses.EmptyRef(), NStr("en='<No status>';ru='<Без статуса>';de='<Kein Status>'"), True, PictureLib.Empty);
	For Each vRoomStatusesRow In vRoomStatuses Do
		SelRoomStatuses.Add(vRoomStatusesRow.RoomStatus, TrimAll(vRoomStatusesRow.Description), True, cmGetRoomStatusIcon(vRoomStatusesRow.RoomStatus));
	EndDo;
	FillRoomStatuses(SelRoomStatuses);
EndProcedure // FillSelEmployees 

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomStatuses(pRoomStatuses)
	RoomStatuses.Clear();
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	RoomStatuses.Ref AS RoomStatus,
	|	RoomStatuses.Color AS Color
	|FROM
	|	Catalog.RoomStatuses AS RoomStatuses
	|WHERE
	|	NOT RoomStatuses.DeletionMark
	|	AND NOT RoomStatuses.IsFolder
	|	AND RoomStatuses.Ref IN(&qRoomStatuses)";
	vQ.SetParameter("qRoomStatuses", pRoomStatuses);
	vResult = vQ.Execute().Unload();
	For Each vRow In vResult Do
		vNewRow = RoomStatuses.Add();
		FillPropertyValues(vNewRow, vRow,, "Color");
		vColor = vRow.Color.Get();
		If TypeOf(vColor) = Type("Color") Then
			vColor = cmGetRGB4WebColor(vColor);
			vNewRow.Color = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")";
		Else
			vNewRow.Color = "";
		EndIf;
	EndDo;
EndProcedure // FillColorOperations

// -----------------------------------------------------------------------------
&AtServer
Procedure FillSelRooms(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	Rooms.Ref AS Room,
	|	Rooms.Description AS Description,
	|	Rooms.SortCode AS SortCode
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND (Rooms.Owner = &qHotel
	|			OR Rooms.Owner = &qEmptyHotel)
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQuery.SetParameter("qHotel", vObj.Hotel);
	vQuery.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vRooms = vQuery.Execute().Unload();
	SelRooms.Clear();
	For Each vRoomsRow In vRooms Do
		SelRooms.Add(vRoomsRow.Room, TrimAll(vRoomsRow.Description), True);
	EndDo;
EndProcedure // FillSelRooms

// -----------------------------------------------------------------------------
&AtServer
Procedure FillSelRoomTypes(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	RoomTypes.Ref AS RoomType,
	|	RoomTypes.Description AS Description,
	|	RoomTypes.SortCode AS SortCode
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|WHERE
	|	NOT RoomTypes.DeletionMark
	|	AND NOT RoomTypes.IsFolder
	|	AND (RoomTypes.Owner = &qHotel
	|			OR RoomTypes.Owner = &qEmptyHotel)
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQuery.SetParameter("qHotel", vObj.Hotel);
	vQuery.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vRoomTypes = vQuery.Execute().Unload();
	SelRoomTypes.Clear();
	For Each vRoomTypesRow In vRoomTypes Do
		SelRoomTypes.Add(vRoomTypesRow.RoomType, TrimAll(vRoomTypesRow.Description), True);
	EndDo;
EndProcedure // FillSelRoomTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure FillSelShortcuts()
	SelShortcuts.Add("ShowAllRooms", NStr("en = 'All rooms';de = 'Alle Zimmern';ru = 'Все номера'"), True);
	SelShortcuts.Add("ShowDirtyRooms", NStr("en = 'Dirty rooms';de = 'Schmutzige Zimmern';ru = 'Грязные номера'"), False);
	SelShortcuts.Add("ShowCleanRooms", NStr("en = 'Clean rooms';de = 'Rein Zimmern';ru = 'Чистые номера'"), False);
	SelShortcuts.Add("ShowVacantRooms", NStr("en = 'Vacant rooms';de = 'Frei Zimmern';ru = 'Свободные номера'"), False);
	SelShortcuts.Add("ShowOccupiedRooms", NStr("en = 'In-house rooms';de = 'In-house Zimmern';ru = 'Занятые номера'"), False);
	SelShortcuts.Add("ShowPlannedCheckIn", NStr("en = 'Expected arrival';de = 'Erwartete Ankunft';ru = 'Ожидаемый заезд'"), False);
	SelShortcuts.Add("ShowPlannedCheckOut", NStr("en = 'Expected departure';de = 'Erwartete Abreise';ru = 'Ожидаемый выезд'"), False);
	SelShortcuts.Add("ShowCheckedIn", NStr("en = 'All checked-in';de = 'Tatsächliche Anreise';ru = 'Фактический заезд'"), False);
	SelShortcuts.Add("ShowCheckedOut", NStr("en = 'All checked-out';de = 'Tatsächliche Abreise';ru = 'Фактический выезд'"), False);
	SelShortcuts.Add("ShowRoomsWithTasks", NStr("en = 'Rooms with tasks';de = 'Zimmern mit Aufgaben';ru = 'Номера с задачами'"), False);
	SelShortcuts.Add("ShowRoomsWithDiscrepancies", NStr("en = 'Discrepancies';de = 'Diskrepanzen';ru = 'Расхождения'"), False);
	SelShortcuts.Add("ShowRoomsBlock", NStr("en = 'Blocked rooms';de = 'Blockierte Zimmern';ru = 'Номера с блокировкой'"), False);
	SelShortcuts.Add("ShowRoomsStopSale", NStr("en = 'Stop sale rooms';de = 'Stop Verkaufszimmern';ru = 'Номера снятые с продажи'"), False);
EndProcedure // FillSelShortcuts

// -----------------------------------------------------------------------------
&AtServer
Procedure FillSelOperations()
	vOperations = cmGetAllOperations(Object.Hotel);
	SelOperations.Clear();
	SelOperations.Add(Catalogs.Operations.EmptyRef(), NStr("en='<No operation>';ru='<Нет работы>';de='<Kein Arbeit>'"), True, PictureLib.Empty);
	For Each vOperationsRow In vOperations Do
		SelOperations.Add(vOperationsRow.Operation, TrimAll(vOperationsRow.Description), True, GetImgOperationPicture(vOperationsRow.Operation));
	EndDo;
EndProcedure // FillSelOperations

// -----------------------------------------------------------------------------
&AtServer
Procedure FillSelEmployees()
	vEmployeeList = GetEmployeeList();
	SelEmployees.Clear();
	SelEmployees.Add(Catalogs.Employees.EmptyRef(), NStr("en='<No housemaid>';ru='<Без горничной>';de='<Kein Hausmädchen>'"), True);
	For Each vEmployeeListItem In vEmployeeList Do
		SelEmployees.Add(vEmployeeListItem.Value, TrimAll(vEmployeeListItem.Value), True);
	EndDo;
EndProcedure // FillSelEmployees 

// -----------------------------------------------------------------------------
&AtServer
Function GetStrOperationPicture(pOperation)
	vOperationIcon = "operation-empty";
	If ValueIsFilled(pOperation) Then
		If pOperation = Object.CheckOutCleaning Or pOperation.IsCheckOutCleaning Then
			vOperationIcon = "operation-checkout";
		ElsIf pOperation = Object.RegularCleaning Or pOperation.IsRegularCleaning Then
			vOperationIcon = "operation-occupieddirty";
		ElsIf pOperation = Object.VacantRoomCleaning Or pOperation.IsVacantRoomCleaning Then
			vOperationIcon = "operation-vacant";
		ElsIf pOperation = Object.RepairEndCleaning Or pOperation.IsRepairEndCleaning Then
			vOperationIcon = "operation-roomstatusrepair";
		EndIf;
	EndIf;
	Return vOperationIcon;
EndFunction // GetStrOperationPicture

// -----------------------------------------------------------------------------
&AtServer
Function GetImgOperationPicture(pOperation)
	vOperationIcon = PictureLib.Empty;
	If ValueIsFilled(pOperation) Then
		If pOperation = Object.CheckOutCleaning Or pOperation.IsCheckOutCleaning Then
			vOperationIcon = PictureLib.CheckOut;
		ElsIf pOperation = Object.RegularCleaning Or pOperation.IsRegularCleaning Then
			vOperationIcon = PictureLib.OccupiedDirty;
		ElsIf pOperation = Object.VacantRoomCleaning Or pOperation.IsVacantRoomCleaning Then
			vOperationIcon = PictureLib.Vacant;
		ElsIf pOperation = Object.RepairEndCleaning Or pOperation.IsRepairEndCleaning Then
			vOperationIcon = PictureLib.RoomStatusRepair;
		EndIf;
	EndIf;
	Return vOperationIcon;
EndFunction // GetImgOperationPicture

// -----------------------------------------------------------------------------
&AtServer
Function RoundUp(pNumber, pRoundDigits)
	Return cmRoundUp(pNumber, pRoundDigits);
EndFunction // RoundUp

// -----------------------------------------------------------------------------
&AtServer
Function GetEmployeeList()
	vObj = FormAttributeToValue("Object");
	vEmployeeList = New ValueList;
	vEmployees = vObj.Employees.Unload(, "Employee");
	vEmployees.GroupBy("Employee");
	For Each vEmployeeRow In vEmployees Do
		If ValueIsFilled(vEmployeeRow.Employee) Then
			vEmployeeList.Add(vEmployeeRow.Employee);
		EndIf;
	EndDo;
	vOperations = vObj.Operations.Unload(, "Employee");
	vOperations.GroupBy("Employee");
	For Each vOperationsRow In vOperations Do
		If ValueIsFilled(vOperationsRow.Employee) Then
			If vEmployeeList.FindByValue(vOperationsRow.Employee) = Undefined Then
				vEmployeeList.Add(vOperationsRow.Employee);
			EndIf;
		EndIf;
	EndDo;
	// Return
	Return vEmployeeList;
EndFunction // GetEmployeeList 

// -------------------------------------------------------------------------------------
&AtServer
Procedure CheckShowAllRooms(pShortcuts, pSelRoomStatuses)
	vShowAllRooms = pShortcuts.FindByValue("ShowAllRooms");
	vShowDirtyRooms = pShortcuts.FindByValue("ShowDirtyRooms");
	vShowCleanRooms = pShortcuts.FindByValue("ShowCleanRooms");
	vShowVacantRooms = pShortcuts.FindByValue("ShowVacantRooms");
	vShowOccupiedRooms = pShortcuts.FindByValue("ShowOccupiedRooms");
	vShowPlannedCheckIn = pShortcuts.FindByValue("ShowPlannedCheckIn");
	vShowPlannedCheckOut = pShortcuts.FindByValue("ShowPlannedCheckOut");
	vShowCheckedIn = pShortcuts.FindByValue("ShowCheckedIn");
	vShowCheckedOut = pShortcuts.FindByValue("ShowCheckedOut");
	vShowRoomsWithTasks = pShortcuts.FindByValue("ShowRoomsWithTasks");
	vShowRoomsWithDiscrepancies = pShortcuts.FindByValue("ShowRoomsWithDiscrepancies");
	vShowRoomsBlock = pShortcuts.FindByValue("ShowRoomsBlock");
	vShowRoomsStopSale = pShortcuts.FindByValue("ShowRoomsStopSale");
	// Check if all shortcuts are off
	If Not vShowCheckedIn.Check And Not vShowCheckedOut.Check And 
		Not vShowPlannedCheckIn.Check And Not vShowPlannedCheckOut.Check And 
		Not vShowDirtyRooms.Check And Not vShowCleanRooms.Check And 
		Not vShowVacantRooms.Check And Not vShowOccupiedRooms.Check And 
		Not vShowRoomsWithTasks.Check And Not vShowRoomsWithDiscrepancies.Check And
		Not vShowRoomsBlock.Check And Not vShowRoomsStopSale.Check Then
		vShowAllRooms.Check = True;
	EndIf;
	// Check if all statuses are selected
	For Each vItem In pSelRoomStatuses Do
		If Not vItem.Check Then
			vShowAllRooms.Check = False;
			Break;
		EndIf;
	EndDo;
	If vShowAllRooms.Check Then
		If vShowCheckedIn.Check Or vShowCheckedOut.Check Or 
			vShowPlannedCheckIn.Check Or vShowPlannedCheckOut.Check Or 
			vShowDirtyRooms.Check Or vShowCleanRooms.Check Or 
			vShowVacantRooms.Check Or vShowOccupiedRooms.Check Or 
			vShowRoomsWithTasks.Check Or vShowRoomsWithDiscrepancies.Check And
			vShowRoomsBlock.Check And vShowRoomsStopSale.Check Then
			vShowAllRooms.Check = False;
		EndIf;
	EndIf;
EndProcedure // CheckShowAllRooms

// -------------------------------------------------------------------------------------
&AtServer
Procedure FillMessagesForObject(pParentDocList)
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	Messages.Object AS Ref
	|FROM
	|	InformationRegister.Messages AS Messages
	|WHERE
	|	NOT Messages.IsClosed
	|	AND (Messages.Object IN (&qParentDoc)
	|			OR Messages.Object IN (&qRoom))
	|	AND (Messages.ValidToDate = DATETIME(1, 1, 1, 0, 0, 0)
	|			OR Messages.ValidToDate >= &qDate)
	|	AND Messages.ValidFromDate <= &qDate
	|	AND (&qShowAllMessages
	|			OR NOT &qShowAllMessages
	|				AND Messages.ForDepartment = &qCurrentUserDepartment
	|				AND Messages.ForDepartment <> VALUE(Catalog.Departments.EmptyRef)
	|			OR NOT &qShowAllMessages
	|				AND Messages.ForEmployee = &qCurrentEmployee
	|				AND Messages.ForEmployee <> VALUE(Catalog.Employees.EmptyRef)
	|			OR NOT &qShowAllMessages
	|				AND Messages.Author = &qCurrentEmployee
	|				AND Messages.Author <> VALUE(Catalog.Employees.EmptyRef))
	|
	|GROUP BY
	|	Messages.Object";
	vQ.SetParameter("qParentDoc", pParentDocList);
	vQ.SetParameter("qRoom", SelRooms);
	vQ.SetParameter("qDate", CurrentSessionDate());
	vQ.Setparameter("qShowAllMessages", cmCheckUserPermissions("HavePermissionToSeeAllMessages"));
	vQ.Setparameter("qCurrentUserDepartment", ?(ValueIsFilled(Sessionparameters.CurrentUser), Sessionparameters.CurrentUser.Department, Catalogs.Departments.EmptyRef()));
	vQ.Setparameter("qCurrentEmployee", Sessionparameters.CurrentUser);
	ValueToFormAttribute(vQ.Execute().Unload(), "MessagesForParentDoc");
EndProcedure // FillMessagesForObject

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function FillRoomGuests(pRooms)
	// Build and run query to get room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomInventory.Room AS Room,
	|	RoomInventory.Customer AS Customer,
	|	CASE
	|		WHEN RoomInventory.CheckOutDate >= &qDateFrom
	|				AND RoomInventory.CheckOutDate <= &qDateTo
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CheckOutToday,
	|	RoomInventory.IsInHouse AS IsInHouse,
	|	SUM(RoomInventory.NumberOfPersons) AS NumberOfPersons
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.IsAccommodation
	|	AND RoomInventory.IsInHouse
	|	AND RoomInventory.Room IN(&qRooms)
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.PeriodFrom < &qDateTo
	|	AND RoomInventory.PeriodTo > &qDateFrom
	|	AND RoomInventory.Period = RoomInventory.PeriodFrom
	|
	|GROUP BY
	|	RoomInventory.Room,
	|	RoomInventory.Customer,
	|	CASE
	|		WHEN RoomInventory.CheckOutDate >= &qDateFrom
	|				AND RoomInventory.CheckOutDate <= &qDateTo
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	RoomInventory.IsInHouse
	|
	|ORDER BY
	|	RoomInventory.Room.SortCode";
	
	vQry.SetParameter("qRooms", pRooms);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qDateFrom", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qDateTo", EndOfDay(CurrentSessionDate()));
	Return vQry.Execute().Unload();
EndFunction // FillRoomGuests

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function FillHousekeepingRemarksByParentDoc(pParentDocList)
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	Accommodation.Ref AS ParentDoc,
	|	MAX(CAST(Accommodation.HousekeepingRemarks AS STRING(999))) AS HousekeepingRemarks,
	|	MAX(Accommodation.NumberOfAdults) AS NumberOfAdults,
	|	MAX(Accommodation.NumberOfTeenagers) AS NumberOfTeenagers,
	|	MAX(Accommodation.NumberOfChildren) AS NumberOfChildren,
	|	MAX(Accommodation.NumberOfInfants) AS NumberOfInfants,
	|	Accommodation.GuestGroup AS GuestGroup,
	|	Accommodation.Guest AS Guest,
	|	Accommodation.ClientType AS ClientType
	|INTO DocList
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Ref IN(&qParentDoc)
	|
	|GROUP BY
	|	Accommodation.Ref,
	|	Accommodation.GuestGroup,
	|	Accommodation.Guest,
	|	Accommodation.ClientType
	|
	|UNION ALL
	|
	|SELECT
	|	Reservation.Ref,
	|	MAX(CAST(Reservation.HousekeepingRemarks AS STRING(999))),
	|	MAX(Reservation.NumberOfAdults),
	|	MAX(Reservation.NumberOfTeenagers),
	|	MAX(Reservation.NumberOfChildren),
	|	MAX(Reservation.NumberOfInfants),
	|	Reservation.GuestGroup,
	|	Reservation.Guest,
	|	Reservation.ClientType
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Ref IN(&qParentDoc)
	|
	|GROUP BY
	|	Reservation.GuestGroup,
	|	Reservation.Ref,
	|	Reservation.Guest,
	|	Reservation.ClientType
	|
	|INDEX BY
	|	GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroups.Color AS GuestGroupColor,
	|	DocList.HousekeepingRemarks AS HousekeepingRemarks,
	|	DocList.NumberOfAdults AS NumberOfAdults,
	|	DocList.NumberOfTeenagers AS NumberOfTeenagers,
	|	DocList.NumberOfChildren AS NumberOfChildren,
	|	DocList.NumberOfInfants AS NumberOfInfants,
	|	GuestGroups.Ref AS GuestGroup,
	|	DocList.ParentDoc AS ParentDoc,
	|	DocList.Guest AS Guest,
	|	DocList.Guest.DateOfBirth AS DateOfBirth,
	|	DocList.ClientType AS ClientType,
	|	DocList.ClientType.Color AS ClientTypeColor,
	|	DocList.ClientType.Code AS ClientTypeCode
	|FROM
	|	DocList AS DocList
	|		LEFT JOIN Catalog.GuestGroups AS GuestGroups
	|		ON DocList.GuestGroup = GuestGroups.Ref";
	vQ.SetParameter("qParentDoc", pParentDocList);
	Return vQ.Execute().Unload();
EndFunction // FillHousekeepingRemarksByParentDoc

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function FillRoomType(pRooms)
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	RoomTypes.Ref AS Ref,
	|	RoomTypes.Code AS Code
	|INTO RoomTypes
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|WHERE
	|	NOT RoomTypes.DeletionMark
	|	AND NOT RoomTypes.IsFolder
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Rooms.Ref AS Room,
	|	ISNULL(RoomTypes.Code, """") AS RoomTypeCode,
	|	RoomTypes.Ref AS RoomType
	|FROM
	|	Catalog.Rooms AS Rooms
	|		LEFT JOIN RoomTypes AS RoomTypes
	|		ON Rooms.RoomType = RoomTypes.Ref
	|WHERE
	|	Rooms.Ref IN(&qRooms)";
	vQ.SetParameter("qRooms", pRooms);
	Return vQ.Execute().Unload();
EndFunction // FillRoomType

// -------------------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomParents(pHotel)
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	Rooms.Description AS Description,
	|	Rooms.Ref AS Ref,
	|	Rooms.Parent AS Parent
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	Rooms.IsFolder
	|	AND NOT Rooms.DeletionMark
	|	AND Rooms.Owner = &qHotel";
	vQ.SetParameter("qHotel", pHotel);
	Return vQ.Execute().Unload();
EndFunction // GetRoomParent

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetHouseKeepingRemarksByReservation(pRoomsArray, pDate, pHotel)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ReservationStatuses.Ref AS ReservationStatusRef
	|INTO ActiveAndIsInWaitingListRoomStatuses
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	ReservationStatuses.IsActive
	|
	|UNION ALL
	|
	|SELECT
	|	ReservationStatuses.Ref
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	ReservationStatuses.IsInWaitingList
	|
	|INDEX BY
	|	ReservationStatusRef
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservation.Ref AS Ref,
	|	Reservation.Room AS Room,
	|	MAX(CAST(Reservation.HousekeepingRemarks AS STRING(999))) AS Remarks,
	|	Reservation.GuestGroup AS GuestGroup,
	|	Reservation.ClientType AS ClientType,
	|	MAX(Reservation.NumberOfAdults) AS NumberOfAdults,
	|	MAX(Reservation.NumberOfTeenagers) AS NumberOfTeenagers,
	|	MAX(Reservation.NumberOfChildren) AS NumberOfChildren,
	|	MAX(Reservation.NumberOfInfants) AS NumberOfInfants,
	|	Reservation.Guest AS Guest
	|INTO Reservations
	|FROM
	|	Document.Reservation AS Reservation
	|		INNER JOIN ActiveAndIsInWaitingListRoomStatuses AS ActiveAndIsInWaitingListRoomStatuses
	|		ON Reservation.ReservationStatus = ActiveAndIsInWaitingListRoomStatuses.ReservationStatusRef
	|WHERE
	|	Reservation.Posted
	|	AND Reservation.Hotel = &qHotel
	|	AND BEGINOFPERIOD(Reservation.CheckInDate, DAY) = &qCheckInDate
	|	AND Reservation.Room IN(&qRooms)
	|
	|GROUP BY
	|	Reservation.Ref,
	|	Reservation.Room,
	|	Reservation.GuestGroup,
	|	Reservation.ClientType,
	|	Reservation.Guest
	|
	|INDEX BY
	|	GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroups.Color AS GuestGroupColor,
	|	Reservations.Remarks AS HousekeepingRemarks,
	|	Reservations.NumberOfAdults AS NumberOfAdults,
	|	Reservations.NumberOfTeenagers AS NumberOfTeenagers,
	|	Reservations.NumberOfChildren AS NumberOfChildren,
	|	Reservations.NumberOfInfants AS NumberOfInfants,
	|	GuestGroups.Ref AS GuestGroup,
	|	Reservations.Guest AS Guest,
	|	Reservations.Guest.DateOfBirth AS DateOfBirth,
	|	Reservations.ClientType AS ClientType,
	|	Reservations.ClientType.Color AS ClientTypeColor,
	|	Reservations.ClientType.Code AS ClientTypeCode,
	|	Reservations.Room AS Room
	|FROM
	|	Reservations AS Reservations
	|		LEFT JOIN Catalog.GuestGroups AS GuestGroups
	|		ON Reservations.GuestGroup = GuestGroups.Ref";
	vQuery.SetParameter("qCheckInDate", BegOfDay(pDate));
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qRooms", pRoomsArray);
	
	Return vQuery.Execute().Unload();
EndFunction // GetHouseKeepingRemarksByReservation

// --------------------------------------------------------------------------------
&AtServer
Function DrawOperationsAtServer()
	CheckShowAllRooms(SelShortcuts, SelRoomStatuses);
	vOperationsTable = Object.Operations.Unload(,"ParentDoc, Room");
	vOperationsTable.GroupBy("ParentDoc, Room");
	vEmptyParentDoc = vOperationsTable.FindRows(New Structure("ParentDoc", Undefined));
	For Each vRow In vEmptyParentDoc Do
		vOperationsTable.Delete(vRow);
	EndDo;
	vParentDoc = vOperationsTable.UnloadColumn("ParentDoc");
	vRoomArray = vOperationsTable.UnloadColumn("Room");
	FillMessagesForObject(vParentDoc);
	vHouseKeepingRemarksByReservations = GetHouseKeepingRemarksByReservation(vRoomArray, Object.Date, Object.Hotel);
	vHousekeepingRemarksForParentDoc = FillHousekeepingRemarksByParentDoc(vParentDoc);
	vRoomTypeCodeForRoom = FillRoomType(SelRooms);
	vHotelGuests = FillRoomGuests(SelRooms);
	vCheckOutAndCheckIn = Undefined;
	If (SelShortcuts.FindByValue("ShowPlannedCheckIn").Check Or SelShortcuts.FindByValue("ShowPlannedCheckOut").Check Or SelShortcuts.FindByValue("ShowCheckedIn").Check Or 
		SelShortcuts.FindByValue("ShowCheckedOut").Check Or SelShortcuts.FindByValue("ShowRoomsBlock").Check Or SelShortcuts.FindByValue("ShowRoomsStopSale").Check) Then
		vCheckOutAndCheckIn = CheckOutAndCheckIn();
	EndIf;
	vRoomParents = GetRoomParents(Object.Hotel);
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Rooms.Ref AS Room,
	|	Rooms.Parent AS Parent
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	Rooms.Ref IN(&qRoomList)
	|
	|ORDER BY
	|	Rooms.Parent.SortCode,
	|	Rooms.SortCode";
	vQuery.SetParameter("qRoomList", SelRooms);
	SelectionDetailRecords = vQuery.Execute().Select();
	vOperationsArr = New Array;
	While SelectionDetailRecords.Next() Do
		vUseAttention = False;
		vRoom = SelectionDetailRecords.Room;
		vRoomOperations = Object.Operations.FindRows(New Structure("Room", vRoom));
		If vRoomOperations.Count() > 0 And CheckDrawRoom(vRoom, vRoomOperations, vRoomTypeCodeForRoom, vHotelGuests, vCheckOutAndCheckIn, vUseAttention) Then
			vOperationsArr.Add(DrawRoomAtServer(vRoom, SelectionDetailRecords.Parent, vRoomParents, vRoomOperations, vRoomTypeCodeForRoom, vHousekeepingRemarksForParentDoc, vHouseKeepingRemarksByReservations,vUseAttention));
		EndIf;
	EndDo;
	Return vOperationsArr;
EndFunction // DrawOperationsAtServer

// --------------------------------------------------------------------------------
&AtServer
Function GetRoomStatusIcon(pRoomStatus)
	vPicture = "room-status-empty";
	If ValueIsFilled(pRoomStatus) Then
		If ValueIsFilled(pRoomStatus.RoomStatusIcon) Then
			If pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.None Then
				vPicture = "room-status-empty";
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
				vPicture = "room-status-roomstatusreserved";
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
				vPicture = "room-status-occupied";
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
				vPicture = "room-status-occupieddirty";
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
				vPicture = "room-status-waiting";
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
				vPicture = "room-status-roomstatuscleaning";
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
				vPicture = "room-status-tidyingup";
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
				vPicture = "room-status-vacant";
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
				vPicture = "room-status-roomstatusrepair";
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
				vPicture = "room-status-roomstatusluggage";
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
				vPicture = "room-status-roomstatusmalfunction";
			EndIf;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // cmGetRoomStatusIcon

// --------------------------------------------------------------------------------
&AtServer
Function GetRoomPresentation(pRoom)
	vRoomNameLength = 25;
	vItem = SelRooms.FindByValue(pRoom);
	If vItem <> Undefined Then
		vRoom = vItem.Presentation 	
	Else
		vRoom = TrimAll(pRoom)	
	EndIf;
	If StrLen(vRoom) > vRoomNameLength Then
		vRoom = Left(vRoom, vRoomNameLength);
	EndIf;
	Return TrimAll(vRoom);
EndFunction // GetRoomPresentation

// --------------------------------------------------------------------------------
&AtServer
Function GetRoomTypePresentation(pRoom, pRoomTypeCodeForRoom)
	vRoomTypeCodeArr = pRoomTypeCodeForRoom.FindRows(New Structure("Room", pRoom));
	vRoomType = "";
	If vRoomTypeCodeArr.Count() > 0 Then
		vRoomType = vRoomTypeCodeArr[0].RoomTypeCode;	
	Else
		vRoomType = TrimAll(pRoom.RoomType.Code);
	EndIf;
	If StrLen(vRoomType) > 5 Then
		vRoomType = Left(vRoomType, 5);
	EndIf;
	Return TrimAll(vRoomType);
EndFunction // GetRoomTypePresentation

// -------------------------------------------------------------------------------------
&AtServer
Function CheckSelShortcutsFilter(pRoom, pShortcuts, pTasksVisible, pSelHotelGuests, pCheckOutAndCheckIn)
	vCheck = pShortcuts.FindByValue("ShowAllRooms").Check;
	If vCheck Then
		Return True;
	EndIf;
	vShowVacantRooms = pShortcuts.FindByValue("ShowVacantRooms");
	vShowOccupiedRooms = pShortcuts.FindByValue("ShowOccupiedRooms");
	vShowPlannedCheckIn = pShortcuts.FindByValue("ShowPlannedCheckIn");
	vShowPlannedCheckOut = pShortcuts.FindByValue("ShowPlannedCheckOut");
	vShowCheckedIn = pShortcuts.FindByValue("ShowCheckedIn");
	vShowCheckedOut = pShortcuts.FindByValue("ShowCheckedOut");
	vShowRoomsWithTasks = pShortcuts.FindByValue("ShowRoomsWithTasks");
	vShowRoomsWithDiscrepancies = pShortcuts.FindByValue("ShowRoomsWithDiscrepancies");
	vShowRoomsBlock = pShortcuts.FindByValue("ShowRoomsBlock");
	vShowRoomsStopSale = SelShortcuts.FindByValue("ShowRoomsStopSale");
	If vShowVacantRooms.Check Then
		vRoomGuests = pSelHotelGuests.FindRows(New Structure("Room", pRoom));
		If vRoomGuests.Count() < 0 Then
			Return False;
		EndIf;
	EndIf;
	If vShowOccupiedRooms.Check Then
		vRoomGuests = pSelHotelGuests.FindRows(New Structure("Room", pRoom));
		If vRoomGuests.Count() <> 0 Then
			Return False;
		EndIf;
	EndIf;
	If vShowRoomsWithTasks.Check Then
		If Not pTasksVisible Then
			Return False;
		EndIf;
	EndIf;
	If vShowRoomsWithDiscrepancies.Check Then
		vRoom = pRoom;
		vHotel = vRoom.Owner;
		vRoomGuests = pSelHotelGuests.FindRows(New Structure("Room", vRoom));
		vDiscrepancy = False;
		If vRoomGuests.Count() > 0 Then
			// There are in-house guests
			If vRoom.RoomStatus = vHotel.VacantRoomStatus And ValueIsFilled(vHotel.VacantRoomStatus) Or 
				ValueIsFilled(vRoom.RoomStatus) And vRoom.RoomStatus.RoomIsVacantClear Or
				vRoom.RoomStatus = vHotel.OutOfOrderRoomStatus And ValueIsFilled(vHotel.OutOfOrderRoomStatus) Or
				vRoom.RoomStatus = vHotel.RoomStatusAfterCheckOut And ValueIsFilled(vHotel.RoomStatusAfterCheckOut) Or
				vRoom.RoomStatus = vHotel.RoomStatusAfterRoomBlock And ValueIsFilled(vHotel.RoomStatusAfterRoomBlock) Or
				vRoom.RoomStatus = vHotel.RoomStatusInspection And ValueIsFilled(vHotel.RoomStatusInspection) Or
				ValueIsFilled(vRoom.RoomStatus) And vRoom.RoomStatus.InspectionIsInProgress Then
				vDiscrepancy = True;
			EndIf;
		Else
			// Nobody at home :-)
			If vRoom.RoomStatus = vHotel.OccupiedRoomStatus And ValueIsFilled(vHotel.OccupiedRoomStatus) Or 
				vRoom.RoomStatus = vHotel.OccupiedDirtyRoomStatus And ValueIsFilled(vHotel.OccupiedDirtyRoomStatus) Or
				vRoom.RoomStatus = vHotel.RoomStatusAfterEarlyCheckIn And ValueIsFilled(vHotel.RoomStatusAfterEarlyCheckIn) Or
				vRoom.RoomStatus = vHotel.RoomStatusDueOut And ValueIsFilled(vHotel.RoomStatusDueOut) Then
				vDiscrepancy = True;
			EndIf;
		EndIf;
		If Not vDiscrepancy Then
			If vRoom.RoomStatus = vHotel.OutOfOrderRoomStatus And ValueIsFilled(vHotel.OutOfOrderRoomStatus) Then
				If Not vRoom.HasRoomBlocks Then
					vDiscrepancy = True;
				EndIf;
			EndIf;
		EndIf;
		If Not vDiscrepancy Then
			Return False;
		EndIf;
	EndIf;
	If (vShowPlannedCheckIn.Check Or vShowPlannedCheckOut.Check Or vShowCheckedIn.Check Or vShowCheckedOut.Check Or vShowRoomsBlock.Check Or vShowRoomsStopSale.Check) Then
		If pCheckOutAndCheckIn.FindRows(New Structure("Ref", pRoom)).Count() = 0 Then
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction // CheckSelShortcutsFilter

// -------------------------------------------------------------------------------------
&AtServer
Function CheckOutAndCheckIn()
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	RoomsStopSalePeriods.Ref AS Room
	|INTO StopSales
	|FROM
	|	Catalog.Rooms.StopSalePeriods AS RoomsStopSalePeriods
	|WHERE
	|	RoomsStopSalePeriods.StopSale
	|	AND RoomsStopSalePeriods.PeriodFrom < &qDate
	|	AND RoomsStopSalePeriods.PeriodTo > &qDate
	|	AND NOT RoomsStopSalePeriods.Ref.DeletionMark
	|	AND NOT RoomsStopSalePeriods.Ref.IsFolder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetRoomBlock.Ref AS Ref,
	|	SetRoomBlock.Room AS Room
	|INTO RoomBlocks
	|FROM
	|	Document.SetRoomBlock AS SetRoomBlock
	|WHERE
	|	NOT SetRoomBlock.DeletionMark
	|	AND (SetRoomBlock.DateTo >= &qDate
	|			OR SetRoomBlock.DateTo = DATETIME(1, 1, 1, 0, 0, 0)
	|				AND SetRoomBlock.DateFrom < &qDate)
	|	AND SetRoomBlock.Room IN (&qRoom)
	|	AND (NOT &qHotelIsEmpty
	|				AND SetRoomBlock.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND NOT SetRoomBlock.IsFinished
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservations.Room AS Room,
	|	Reservations.NumberOfAdults + Reservations.NumberOfTeenagers + Reservations.NumberOfChildren + Reservations.NumberOfInfants AS NumberOfGuestsOnArrival
	|INTO ExpectedCheckInGuests
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Posted
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|	AND Reservations.CheckInDate >= &qBegOfToday
	|	AND Reservations.CheckInDate <= &qEndOfToday
	|	AND Reservations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Reservations.Hotel = &qHotel)
	|	AND Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Reservations.Room,
	|	Reservations.NumberOfAdults + Reservations.NumberOfTeenagers + Reservations.NumberOfChildren + Reservations.NumberOfInfants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants AS NumberOfCheckOutGuests
	|INTO ExpectedCheckOutGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckOut
	|	AND Accommodations.CheckOutDate >= &qBegOfToday
	|	AND Accommodations.CheckOutDate <= &qEndOfToday
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Accommodations.Hotel = &qHotel)
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants AS NumberOfCheckedOutGuests
	|INTO CheckedOutGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND NOT Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckOut
	|	AND Accommodations.CheckOutDate >= &qBegOfToday
	|	AND Accommodations.CheckOutDate <= &qEndOfToday
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Accommodations.Hotel = &qHotel)
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants AS NumberOfCheckedInGuests
	|INTO CheckedInGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckIn
	|	AND Accommodations.CheckInDate >= &qBegOfToday
	|	AND Accommodations.CheckInDate <= &qEndOfToday
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Accommodations.Hotel = &qHotel)
	|	AND Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|GROUP BY
	|	Accommodations.Room,
	|	Accommodations.NumberOfAdults + Accommodations.NumberOfTeenagers + Accommodations.NumberOfChildren + Accommodations.NumberOfInfants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Rooms.Ref AS Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|		LEFT JOIN RoomBlocks AS RoomBlocks
	|		ON (RoomBlocks.Room = Rooms.Ref)
	|		LEFT JOIN ExpectedCheckInGuests AS ExpectedCheckInGuests
	|		ON (ExpectedCheckInGuests.Room = Rooms.Ref)
	|		LEFT JOIN CheckedInGuests AS CheckedInGuests
	|		ON (CheckedInGuests.Room = Rooms.Ref)
	|		LEFT JOIN ExpectedCheckOutGuests AS ExpectedCheckOutGuests
	|		ON (ExpectedCheckOutGuests.Room = Rooms.Ref)
	|		LEFT JOIN CheckedOutGuests AS CheckedOutGuests
	|		ON (CheckedOutGuests.Room = Rooms.Ref)
	|		LEFT JOIN StopSales AS StopSales
	|		ON (StopSales.Room = Rooms.Ref)
	|WHERE
	|	Rooms.Ref IN (&qRoom)
	|	AND NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND (NOT &qExpectedCheckInOnly
	|			OR &qExpectedCheckInOnly
	|				AND ExpectedCheckInGuests.NumberOfGuestsOnArrival > 0)
	|	AND (NOT &qCheckedInOnly
	|			OR &qCheckedInOnly
	|				AND CheckedInGuests.NumberOfCheckedInGuests > 0)
	|	AND (NOT &qExpectedCheckOutOnly
	|			OR &qExpectedCheckOutOnly
	|				AND ExpectedCheckOutGuests.NumberOfCheckOutGuests > 0)
	|	AND (NOT &qCheckedOutOnly
	|			OR &qCheckedOutOnly
	|				AND CheckedOutGuests.NumberOfCheckedOutGuests > 0)
	|	AND (NOT &qCheckedRoomBlock
	|			OR &qCheckedRoomBlock
	|				AND RoomBlocks.Ref <> VALUE(Document.SetRoomBlock.EmptyRef))
	|	AND (NOT &qCheckedStopSales
	|			OR &qCheckedStopSales
	|				AND StopSales.Room <> VALUE(Catalog.Rooms.EmptyRef))";
	vQ.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Object.Hotel));
	vQ.SetParameter("qHotel", Object.Hotel);
	vQ.SetParameter("qRoom", SelRooms);
	vQ.SetParameter("qCheckedInOnly", SelShortcuts.FindByValue("ShowCheckedIn").Check);
	vQ.SetParameter("qCheckedOutOnly", SelShortcuts.FindByValue("ShowCheckedOut").Check);
	vQ.SetParameter("qExpectedCheckInOnly", SelShortcuts.FindByValue("ShowPlannedCheckIn").Check);
	vQ.SetParameter("qExpectedCheckOutOnly", SelShortcuts.FindByValue("ShowPlannedCheckOut").Check);
	vQ.SetParameter("qCheckedRoomBlock", SelShortcuts.FindByValue("ShowRoomsBlock").Check);
	vQ.SetParameter("qCheckedStopSales", SelShortcuts.FindByValue("ShowRoomsStopSale").Check);
	vQ.SetParameter("qBegOfToday", BegOfDay(CurrentSessionDate()));
	vQ.SetParameter("qEndOfToday", EndOfDay(CurrentSessionDate()));
	vQ.SetParameter("qDate", CurrentSessionDate());
	Return vQ.Execute().Unload();
EndFunction // CheckOutAndCheckIn

// -----------------------------------------------------------------------------
&AtServer
Function GetEmployeePresentation(pEmployee)
	vEmployeeDescr = NStr("en='<Choose a maid>';ru='<Выб. горничную>';de='<Mädchen ausw.>'");
	If ValueIsFilled(pEmployee) Then
		vEmployeeNameLength = 18;
		vEmployeeArr = Employees.FindRows(New Structure("Employee", pEmployee));
		If vEmployeeArr.Count() > 0 Then
			vEmployeeDescr = vEmployeeArr[0].Description;
		Else
			vEmployeeDescr = TrimAll(pEmployee);
		EndIf;
		If StrLen(vEmployeeDescr) > vEmployeeNameLength Then
			vEmployeeDescr = Left(vEmployeeDescr, vEmployeeNameLength) + "...";
		EndIf;
	EndIf;
	Return vEmployeeDescr;
EndFunction // GetEmployeePresentation

// --------------------------------------------------------------------------------
&AtServer
Function DrawRoomAtServer(pRoom, pParent, pRoomParents, pRoomOperations, pRoomTypeCodeForRoom, pHousekeepingRemarksForParentDoc, pHousekeepingRemarksByReservations, pUseAttention)
	vItems = New Structure("idParent, nameParent, idRoom, isNew, colorItemRow, imgRoomStatus, colorRoomStatus, nameRoom, typeRoom, refRoom, clientType, colorClientType, useReserved, useAttention, useClient, clientsCount, useUserCalendar, calendarCount, checkOutTimeRemarks, housekeepingRemarks, useBirthday, roomRemarks, operations",
	"", "", "", False, "", "", "", "", "", "", "", "", False, pUseAttention, False, "", False, "", "", "", False, "", New Array);
	
	If CurParent <> pParent Then
		CurParent = pParent;
		If ValueIsFilled(pParent) Then
			CurUUIDParent = TrimAll(pParent.UUID());
			
			vRoomParentsArr = New Array;
			vRoomsParent = pParent;
			While ValueIsFilled(vRoomsParent) Do
				vArrRoomParents = pRoomParents.FindRows(New Structure("Ref", vRoomsParent));
				If vArrRoomParents.Count() > 0 Then
					vRoomParentsArr.Insert(0, vArrRoomParents[0].Description);
					vRoomsParent = vArrRoomParents[0].Parent;
				Else
					vRoomParentsArr.Insert(0, vRoomsParent.Description);
					vRoomsParent = vRoomsParent.Parent;
				EndIf;
			EndDo;
			
			vItems.nameParent = StrConcat(vRoomParentsArr, " > ");
		Else
			CurUUIDParent = "";
		EndIf;
	EndIf;
	
	If ValueIsFilled(CurUUIDParent) Then
		vItems.idParent = CurUUIDParent;
	EndIf;
	
	// Room identifier
	vItems.idRoom = TrimAll(pRoom.UUID());
	
	// Get first room operation row
	vOp1Row = pRoomOperations[0];
	
	vCheckUseOperation = New ValueList;
	vCheckUseOperationByRoom = New ValueList;
	For Each vOpRow In pRoomOperations Do
		vAddRoomToList = False;
		vDataArray = pHousekeepingRemarksByReservations.FindRows(New Structure("Room", vOpRow.Room));
		If vDataArray.Count() = 0 Then
			vDataArray = pHousekeepingRemarksForParentDoc.FindRows(New Structure("ParentDoc, ClientType, Guest", vOpRow.ParentDoc, vOpRow.ClientType, vOpRow.Guest));
		Else
			vAddRoomToList = True;
		EndIf;
		
		If vCheckUseOperation.FindByValue(vOpRow.ParentDoc) = Undefined And vCheckUseOperationByRoom.FindByValue(vOpRow.Room) = Undefined Then
			If ValueIsFilled(vOpRow.Guest) Then
				If vDataArray.Count() > 0 Then
					vDateOfBirth = vDataArray[0].DateOfBirth;
				Else
					vDateOfBirth = vOpRow.Guest.DateOfBirth;
				EndIf;
				If ValueIsFilled(vDateOfBirth) Then
					If Format(vDateOfBirth, "DF=dd.MM") = Format(Object.Date, "DF=dd.MM") Then
						vItems.useBirthday = True;
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(vOpRow.ParentDoc) Then
				
				vParentDoc = vOpRow.ParentDoc;
				If ValueIsFilled(vParentDoc) And TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") And BegOfDay(Object.Date) = BegOfDay(vParentDoc.CheckOutDate) Then
					vRoomRate = vParentDoc.RoomRate;
					If ValueIsFilled(vRoomRate) Then
						If Date(1, 1, 1, Hour(vParentDoc.CheckOutDate), Minute(vParentDoc.CheckOutDate), Second(vParentDoc.CheckOutDate)) > vRoomRate.ReferenceHour Then
							vItems.checkOutTimeRemarks = NStr("en = 'Check out time:'; de = 'Abfahrtszeit:'; ru = 'Время выезда: '") + Format(vParentDoc.CheckOutDate, "DF=HH:mm");
						EndIf;
					EndIf;
				EndIf;
				
				If vDataArray.Count() > 0 Then
					If vAddRoomToList Then
						For vInd = 0 To vDataArray.Count() - 1 Do
							vItems.housekeepingRemarks = vItems.housekeepingRemarks + ?(vInd = 0, "", Chars.LF) + TrimAll(vDataArray[vInd].HousekeepingRemarks);
						EndDo;
					Else
						vParentDocRemarks = TrimAll(vDataArray[0].HousekeepingRemarks);
						If Not IsBlankString(vParentDocRemarks) Then
							If IsBlankString(vItems.housekeepingRemarks) Then
								vItems.housekeepingRemarks = vParentDocRemarks;
							Else
								If StrFind(vItems.housekeepingRemarks, vParentDocRemarks) = 0 Then
									vItems.housekeepingRemarks = vItems.housekeepingRemarks + Chars.LF + vParentDocRemarks;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(TrimAll(vOpRow.Remarks)) Then
				vItems.roomRemarks = vOpRow.Remarks;
			EndIf;
			vCheckUseOperation.Add(vOpRow.ParentDoc);
			If vAddRoomToList Then
				vCheckUseOperationByRoom.Add(vOpRow.Room);
			EndIf;
		EndIf;
		
		vItems.isNew = ?(vItems.isNew, vItems.isNew, vOpRow.IsNew);
		
		If ValueIsFilled(vOpRow.Operation) Then
			vItemsOperation = New Structure("idOperation, imgOperation, nameOperation, colorOperation, nameEmployee, colorEmployee", "", "", "", "", "", "");
			// Operation and employee
			If Not ValueIsFilled(vOpRow.UUID) Or vOpRow.UUID = EmptyUUID Then
				vOpRow.UUID = New UUID();
			EndIf;
			vItemsOperation.idOperation = TrimAll(vOpRow.UUID);
			vItemsOperation.imgOperation = GetStrOperationPicture(vOpRow.Operation);
			vEmployee = vOpRow.Employee;
			If ValueIsFilled(vEmployee) Then
				vEmployeeArr = Employees.FindRows(New Structure("Employee", vEmployee));
				If vEmployeeArr.Count() > 0 Then
					vItemsOperation.colorEmployee = vEmployeeArr[0].Color;	
				Else
					vColor = vEmployee.Color.Get();
					If TypeOf(vColor) = Type("Color") Then
						vColor = cmGetRGB4WebColor(vColor);
						vItemsOperation.colorEmployee = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")"
					EndIf;
				EndIf;
			EndIf;
			
			vColorOperations = Operations.FindRows(New Structure("Operation", vOpRow.Operation));
			If vColorOperations.Count() > 0 Then
				vItemsOperation.colorOperation = vColorOperations[0].Color;
				vItemsOperation.nameOperation = TrimAll(vColorOperations[0].Description);
			Else
				vColor = vOpRow.Operation.Color.Get();
				If TypeOf(vColor) = Type("Color") Then
					vColor = cmGetRGB4WebColor(vColor);
					vItemsOperation.colorOperation = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")"
				EndIf;	
			EndIf;
			
			If Not ValueIsFilled(vItemsOperation.nameOperation) Then
				vItemsOperation.nameOperation = TrimAll(vOpRow.Operation.Code);
			EndIf;
			vItemsOperation.nameEmployee = GetEmployeePresentation(vEmployee);	
			vItems.operations.Add(vItemsOperation);
		EndIf;
	EndDo;
	
	vItems.clientsCount = Format(vOp1Row.NumberOfGuests, "NFD=0;NG=");
	vItems.useReserved = vOp1Row.IsCheckInWaiting;
	If vItems.useReserved Then
		vItems.clientsCount = Format(vOp1Row.ExpectedNumberOfGuests, "NFD=0;NG=");
		vHousekeepingRemarksForParentDocArr = pHousekeepingRemarksByReservations.FindRows(New Structure("Room", vOp1Row.Room));
		If vHousekeepingRemarksForParentDocArr.Count() = 0 Then
			If ValueIsFilled(vOp1Row.ParentDoc) And TypeOf(vOp1Row.ParentDoc) = Type("DocumentRef.Reservation") Then
				vHousekeepingRemarksForParentDocArr = pHousekeepingRemarksForParentDoc.FindRows(New Structure("ParentDoc", vOp1Row.ParentDoc, vOpRow.Guest));
			EndIf;
		Endif;
		If vHousekeepingRemarksForParentDocArr.Count() > 0 Then
			vNumberOfGuestsFromDoc = vHousekeepingRemarksForParentDocArr[0].NumberOfAdults + vHousekeepingRemarksForParentDocArr[0].NumberOfTeenagers + vHousekeepingRemarksForParentDocArr[0].NumberOfChildren + vHousekeepingRemarksForParentDocArr[0].NumberOfInfants;
			If vNumberOfGuestsFromDoc <> 0 Then
				vItems.clientsCount = Format(vNumberOfGuestsFromDoc, "NFD=0;NG=");
			EndIf;
		EndIf;
	Else
		vHousekeepingRemarksForParentDocArr = pHousekeepingRemarksByReservations.FindRows(New Structure("Room", vOp1Row.Room));
		If vHousekeepingRemarksForParentDocArr.Count() = 0 Then
			If ValueIsFilled(vOp1Row.ParentDoc) And TypeOf(vOp1Row.ParentDoc) = Type("DocumentRef.Accommodation") Then
				vHousekeepingRemarksForParentDocArr = pHousekeepingRemarksForParentDoc.FindRows(New Structure("ParentDoc, Guest", vOp1Row.ParentDoc));
			EndIf;
		EndIf;
		If vHousekeepingRemarksForParentDocArr.Count() > 0 Then
			vNumberOfGuestsFromDoc = vHousekeepingRemarksForParentDocArr[0].NumberOfAdults + vHousekeepingRemarksForParentDocArr[0].NumberOfTeenagers + vHousekeepingRemarksForParentDocArr[0].NumberOfChildren + vHousekeepingRemarksForParentDocArr[0].NumberOfInfants;
			If vNumberOfGuestsFromDoc <> 0 Then
				vItems.clientsCount = Format(vNumberOfGuestsFromDoc, "NFD=0;NG=");
			EndIf;
		EndIf;
	EndIf;
	vItems.useClient = ValueIsFilled(vItems.clientsCount);
	
	// Get formatting string room status	
	vItems.imgRoomStatus = GetRoomStatusIcon(vOp1Row.RoomStatus);
	
	vRoomStatus = RoomStatuses.FindRows(New Structure("RoomStatus", vOp1Row.RoomStatus));
	If vRoomStatus.Count() > 0 Then
		vItems.colorRoomStatus = vRoomStatus[0].Color;
	Else
		vColor = vOp1Row.RoomStatus.Color.Get();
		If TypeOf(vColor) = Type("Color") Then
			vColor = cmGetRGB4WebColor(vColor);
			vItems.colorRoomStatus = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")"
		EndIf;	
	EndIf;
	
	vItems.nameRoom = GetRoomPresentation(pRoom);
	vItems.typeRoom = GetRoomTypePresentation(pRoom, pRoomTypeCodeForRoom);
	vItems.refRoom = GetURL(pRoom);
	
	// Get formatting string for client type
	If ValueIsFilled(vOp1Row.ClientType) Then
		
		vClientTypeArr = pHousekeepingRemarksByReservations.FindRows(New Structure("Room, ClientType, Guest", vOp1Row.Room));
		If vClientTypeArr.Count() = 0 Then
			vClientTypeArr = pHousekeepingRemarksForParentDoc.FindRows(New Structure("ParentDoc, ClientType, Guest", vOp1Row.ParentDoc, vOp1Row.ClientType, vOp1Row.Guest));
		EndIf;
		If vClientTypeArr.Count() > 0 Then
			vClientTypeCode = TrimAll(vClientTypeArr[0].ClientTypeCode);
			vCTColor = vClientTypeArr[0].ClientTypeColor.Get();
		Else  
			vClientTypeCode = TrimAll(vOp1Row.ClientType.Code);
			vCTColor = vOp1Row.ClientType.Color.Get();
		EndIf;
		If TypeOf(vCTColor) = Type("Color") Then			
			vCTColor = cmGetRGB4WebColor(vCTColor);
			vItems.colorClientType = "rgb(" + vCTColor.R + ", " + vCTColor.G + ", " + vCTColor.B + ")";
		EndIf;
		vItems.clientType = vClientTypeCode;
	EndIf;
	
	If ValueIsFilled(vOp1Row.ParentDoc) Then
		vHousekeepingRemarksForParentDocArr = pHousekeepingRemarksByReservations.FindRows(New Structure("Room", vOp1Row.Room));
		If vHousekeepingRemarksForParentDocArr.Count() = 0 Then
			vHousekeepingRemarksForParentDocArr = pHousekeepingRemarksForParentDoc.FindRows(New Structure("ParentDoc", vOp1Row.ParentDoc));
		EndIf;
		If vHousekeepingRemarksForParentDocArr.Count() > 0 Then
			vGuestGroup = vHousekeepingRemarksForParentDocArr[0].GuestGroup;
			If ValueIsFilled(vGuestGroup) Then
				vColor = vHousekeepingRemarksForParentDocArr[0].GuestGroupColor.Get();
				If TypeOf(vColor) = Type("Color") Then
					vColor = cmGetRGB4WebColor(vColor);
					vItems.colorItemRow = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")";
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Stay day
	vStayDay = vOp1Row.StayDay;
	If ValueIsFilled(vOp1Row.Operation) And vStayDay > 0 Then
		vItems.useUserCalendar = True;
		vItems.calendarCount = Format(vStayDay, "NFD=0");
	EndIf;
	Return vItems;
EndFunction // DrawRoomAtServer 

// --------------------------------------------------------------------------------
&AtServer
Function CheckDrawRoom(pRoom, pRoomOperations, pRoomTypeCodeForRoom, pHotelGuests, pCheckOutAndCheckIn, rUseAttention)
	vOperationsCheck = False;
	vEmployeesCheck = False;
	vCountOperations = 0;
	
	vTaskByRoom = MessagesForParentDoc.FindRows(New Structure("Ref", pRoom));
	If vTaskByRoom.Count() > 0 Then
		rUseAttention = True;
	EndIf;
	
	For Each vOpRow In pRoomOperations Do
		If ValueIsFilled(vOpRow.Operation) Then
			vCountOperations = vCountOperations + 1;
			
			If Not rUseAttention Then
				If ValueIsFilled(vOpRow.ParentDoc) Then
					vTaskByDoc = MessagesForParentDoc.FindRows(New Structure("Ref", vOpRow.ParentDoc));
					If vTaskByDoc.Count() > 0 Then
						rUseAttention = True;
					EndIf;
				EndIf;
			EndIf;
			
			// Apply filter by operations list 
			If Not vOperationsCheck Then
				vSelOperationsItem = SelOperations.FindByValue(vOpRow.Operation);
				If vSelOperationsItem <> Undefined Then
					vOperationsCheck = vSelOperationsItem.Check;	
				EndIf;
			EndIf;
			
			// Apply filter by employees list 
			If Not vEmployeesCheck Then
				vSelEmployeesItem = SelEmployees.FindByValue(vOpRow.Employee);
				If vSelEmployeesItem <> Undefined Then
					vEmployeesCheck = vSelEmployeesItem.Check
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	vDrawRoom = CheckSelShortcutsFilter(pRoom, SelShortcuts, rUseAttention, pHotelGuests, pCheckOutAndCheckIn);
	
	vSelRoomsItem = SelRooms.FindByValue(pRoom);
	If vSelRoomsItem <> Undefined Then
		If Not vSelRoomsItem.Check Then
			vDrawRoom = False;
		EndIf;
	EndIf;
	
	vRoomType = Catalogs.RoomTypes.EmptyRef();
	vRoomTypeArr = pRoomTypeCodeForRoom.FindRows(New Structure("Room", pRoom));
	If vRoomTypeArr.Count() > 0 Then
		vRoomType = vRoomTypeArr[0].RoomType;
	Else
		vRoomType = pRoom.RoomType;
	EndIf;
	vSelRoomTypesItem = SelRoomTypes.FindByValue(vRoomType);
	If vSelRoomTypesItem <> Undefined Then
		If Not vSelRoomTypesItem.Check Then
			vDrawRoom = False;
		EndIf;
	EndIf;
	
	// Apply filter by rooms folder
	If ValueIsFilled(Object.Room) Then
		If Not pRoom.BelongsToItem(Object.Room) Then
			vDrawRoom = False;
		EndIf;
	EndIf;
	
	// Apply filter by section
	If ValueIsFilled(Object.RoomSection) Then
		vRoomSection = pRoom.RoomSection;
		If ValueIsFilled(vRoomSection) Then
			If Object.RoomSection.IsFolder Then
				If Not vRoomSection.BelongsToItem(Object.RoomSection) Then
					vDrawRoom = False;
				EndIf;
			Else
				If vRoomSection <> Object.RoomSection Then
					vDrawRoom = False;
				EndIf;
			EndIf;
		Else
			vDrawRoom = False;
		EndIf;
	EndIf;
	
	// Apply filter by room statuses list
	vSelRoomStatusesItem = SelRoomStatuses.FindByValue(pRoomOperations[0].RoomStatus);
	If vSelRoomStatusesItem <> Undefined Then
		If Not vSelRoomStatusesItem.Check Then
			vDrawRoom = False;
		EndIf;
	EndIf;
	
	If Not vOperationsCheck And (vCountOperations > 0 Or Not SelOperations.FindByValue(Catalogs.Operations.EmptyRef()).Check) Then
		vDrawRoom = False;
	ElsIf Not vEmployeesCheck And (vCountOperations > 0 Or Not SelEmployees.FindByValue(Catalogs.Employees.EmptyRef()).Check) Then
		vDrawRoom = False;
	EndIf;
	Return vDrawRoom;
EndFunction // CheckDrawRoom

// -----------------------------------------------------------------------------
&AtServer
Function UpdateRoomEmployeeAtServer(pOperations)
	vResult = New Array;
	For Each vOperation In pOperations Do 
		vCurRows = Object.Operations.FindRows(New Structure("Room, UUID", vOperation.Room, vOperation.UUID));
		If vCurRows.Count() = 1 Then
			vCurRow = vCurRows[0];
		Else
			Continue;
		EndIf;
		
		vResultStr = New Structure("idOperation, nameEmployee, colorEmployee", TrimAll(vOperation.UUID), GetEmployeePresentation(vOperation.Employee), "");
		
		vEmployeeColor = New Color();
		If ValueIsFilled(vOperation.Employee) Then
			vEmployeeArr = Employees.FindRows(New Structure("Employee", vOperation.Employee));
			If vEmployeeArr.Count() > 0 Then
				vResultStr.colorEmployee = vEmployeeArr[0].Color;	
			Else
				vColor = vOperation.Employee.Color.Get();
				If TypeOf(vColor) = Type("Color") Then
					vColor = cmGetRGB4WebColor(vColor);
					vResultStr.colorEmployee = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")";
				EndIf;
			EndIf;
		EndIf;
		vCurRow.Employee = vOperation.Employee;
		If ValueIsFilled(vCurRow.Employee) Then
			vCurRow.EmployeeSortCode = vCurRow.Employee.SortCode;
		Else
			vCurRow.EmployeeSortCode = 0;
		EndIf;
		vArrED = New Array;
		If ValueIsFilled(vCurRow.Operation) Then
			vResult.Add(vResultStr);
		EndIf;
		// Get operation standards
		If ValueIsFilled(vCurRow.Operation) Then
			vStds = Catalogs.Operations.GetOperationStandards(vCurRow.Operation, Object.Hotel, vCurRow.RoomType, vCurRow.Room, vCurRow.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vCurRow.Duration = vStdsRow.Duration;
				vCurRow.RoomSpace = vStdsRow.RoomSpace;
				vCurRow.Price = vStdsRow.Price;
			EndIf;
		EndIf;
	EndDo;
	CalculateTotalsAtServer();
	Modified = True;
	Return vResult;
EndFunction // UpdateRoomEmployeeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function UpdateRoomOperationAtServer(pRoom, pOperationUUID, pOperation)
	vCurRows = Object.Operations.FindRows(New Structure("Room, UUID", pRoom, pOperationUUID));
	If vCurRows.Count() = 1 Then
		vCurRow = vCurRows[0];
	Else
		Return Undefined;
	EndIf;
	
	vResult = New Structure("idRoom, idOperation, imgOperation, nameOperation, colorOperation, delOperation, isNew", TrimAll(pRoom.UUID()), TrimAll(pOperationUUID), "", "", "", False, False);
	
	If TypeOf(pOperation) = Type("String") And pOperation = "DELETE" Then
		If vCurRow.IsManual Then
			Object.Operations.Delete(vCurRow);
		Else
			vCurRow.Operation = Catalogs.Operations.EmptyRef();
			vCurRow.Employee = Catalogs.Employees.EmptyRef();
			vCurRow.OperationSortCode = 0;
			vCurRow.CheckOutCleaningCount = 0;
			vCurRow.RegularCleaningCount = 0;
			vCurRow.RepairEndCleaningCount = 0;
			vCurRow.VacantRoomCleaningCount = 0;
			vCurRow.OtherOperationsCount = 0;
			vCurRow.Duration = 0;
			vCurRow.RoomSpace = 0;
			vCurRow.EmployeeSortCode = 0;
		EndIf;
		vResult.delOperation = True;
	Else
		vCurRow.Operation = pOperation;
		If ValueIsFilled(pOperation) Then
			vCurRow.IsNew = False;
			vCurRow.OperationSortCode = pOperation.SortCode;
			If pOperation = Object.CheckOutCleaning Or pOperation.IsCheckOutCleaning Then
				vCurRow.CheckOutCleaningCount = 1;
			Else
				vCurRow.CheckOutCleaningCount = 0;
			EndIf;
			If pOperation = Object.RegularCleaning Or pOperation.IsRegularCleaning Then
				vCurRow.RegularCleaningCount = 1;
			Else
				vCurRow.RegularCleaningCount = 0;
			EndIf;
			If (pOperation = Object.RepairEndCleaning Or pOperation.IsRepairEndCleaning) And vCurRow.Operation <> Object.CheckOutCleaning Then
				vCurRow.RepairEndCleaningCount = 1;
			Else
				vCurRow.RepairEndCleaningCount = 0;
			EndIf;
			If pOperation = Object.VacantRoomCleaning Or pOperation.IsVacantRoomCleaning Then
				vCurRow.VacantRoomCleaningCount = 1;
			Else
				vCurRow.VacantRoomCleaningCount = 0;
			EndIf;
			If ValueIsFilled(Object.RegularOperationGroup) Then
				If vCurRow.Operation <> Object.CheckOutCleaning And 
					vCurRow.Operation <> Object.RegularCleaning And
					vCurRow.Operation <> Object.RepairEndCleaning And
					vCurRow.Operation <> Object.VacantRoomCleaning Then
					If Object.RegularOperationGroup.RegularOperations.Find(vCurRow.Operation, "RegularOperation") <> Undefined Then
						vCurRow.RegularCleaningCount = 1;
					Else
						vCurRow.RegularCleaningCount = 0;
					EndIf;
				EndIf;
			EndIf;
			If vCurRow.CheckOutCleaningCount = 0 And 
				vCurRow.RegularCleaningCount = 0 And 
				vCurRow.RepairEndCleaningCount = 0 And 
				vCurRow.VacantRoomCleaningCount = 0 Then
				vCurRow.OtherOperationsCount = 1;
			Else
				vCurRow.OtherOperationsCount = 0;
			EndIf;
			vOprStds = Catalogs.Operations.GetOperationStandards(pOperation, Object.Hotel, vCurRow.RoomType, vCurRow.Room, vCurRow.Employee);
			If vOprStds.Count() > 0 Then
				vOprStdsRow = vOprStds.Get(0);
				vCurRow.RoomSpace = vOprStdsRow.RoomSpace;
				vCurRow.Duration = vOprStdsRow.Duration;
				vCurRow.Price = vOprStdsRow.Price;
			EndIf;
		Else
			vCurRow.OperationSortCode = 999999;
			vCurRow.CheckOutCleaningCount = 0;
			vCurRow.RegularCleaningCount = 0;
			vCurRow.RepairEndCleaningCount = 0;
			vCurRow.VacantRoomCleaningCount = 0;
			vCurRow.OtherOperationsCount = 0;
			vCurRow.Duration = 0;
			vCurRow.RoomSpace = 0;
		EndIf;
		
		vResult.imgOperation = GetStrOperationPicture(pOperation);
		
		vColorOperations = Operations.FindRows(New Structure("Operation", pOperation));
		If vColorOperations.Count() > 0 Then
			vResult.colorOperation = vColorOperations[0].Color;
			vResult.nameOperation = TrimAll(vColorOperations[0].Description);
		Else
			vColor = pOperation.Color.Get();
			If TypeOf(vColor) = Type("Color") Then
				vColor = cmGetRGB4WebColor(vColor);
				vResult.colorOperation = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")"
			EndIf;	
		EndIf;
		
		If Not ValueIsFilled(vResult.nameOperation) Then
			vResult.nameOperation = TrimAll(pOperation.Code);
		EndIf;
		
		vRoomOperations = Object.Operations.FindRows(New Structure("Room", pRoom));
		vResult.isNew = vCurRow.IsNew;
		For Each Operation In vRoomOperations Do
			vResult.isNew = ?(vResult.isNew, vResult.isNew, Operation.IsNew);	
		EndDo;
	EndIf;
	CalculateTotalsAtServer();
	Modified = True;
	Return vResult;
EndFunction // UpdateRoomOperationAtServer

// -----------------------------------------------------------------------------
&AtServer
Function AddRoomOperationAtServer(pRoom, pOperation)
	vResult = Undefined;
	vNewOperation = Undefined;
	vRoomOperations = Object.Operations.FindRows(New Structure("Room", pRoom));
	If vRoomOperations.Count() > 0 Then
		vNewOperation = Object.Operations.Add();
		vNewOperation.UUID = New UUID();
		vNewOperation.IsNew = True;
		vNewOperation.IsManual = True;
		FillPropertyValues(vNewOperation, vRoomOperations[0], , "UUID, LineNumber, IsManual, IsNew, Guest");
	EndIf;
	If vNewOperation <> Undefined Then
		vNewOperation.Operation = pOperation;
		If ValueIsFilled(pOperation) Then
			vNewOperation.OperationSortCode = pOperation.SortCode;
			If pOperation = Object.CheckOutCleaning Or pOperation.IsCheckOutCleaning Then
				vNewOperation.CheckOutCleaningCount = 1;
			Else
				vNewOperation.CheckOutCleaningCount = 0;
			EndIf;
			If pOperation = Object.RegularCleaning Or pOperation.IsRegularCleaning Then
				vNewOperation.RegularCleaningCount = 1;
			Else
				vNewOperation.RegularCleaningCount = 0;
			EndIf;
			If (pOperation = Object.RepairEndCleaning Or pOperation.IsRepairEndCleaning) And vNewOperation.Operation <> Object.CheckOutCleaning Then
				vNewOperation.RepairEndCleaningCount = 1;
			Else
				vNewOperation.RepairEndCleaningCount = 0;
			EndIf;
			If pOperation = Object.VacantRoomCleaning Or pOperation.IsVacantRoomCleaning Then
				vNewOperation.VacantRoomCleaningCount = 1;
			Else
				vNewOperation.VacantRoomCleaningCount = 0;
			EndIf;
			If ValueIsFilled(Object.RegularOperationGroup) Then
				If vNewOperation.Operation <> Object.CheckOutCleaning And 
					vNewOperation.Operation <> Object.RegularCleaning And
					vNewOperation.Operation <> Object.RepairEndCleaning And
					vNewOperation.Operation <> Object.VacantRoomCleaning Then
					If Object.RegularOperationGroup.RegularOperations.Find(vNewOperation.Operation, "RegularOperation") <> Undefined Then
						vNewOperation.RegularCleaningCount = 1;
					Else
						vNewOperation.RegularCleaningCount = 0;
					EndIf;
				EndIf;
			EndIf;
			If vNewOperation.CheckOutCleaningCount = 0 And 
				vNewOperation.RegularCleaningCount = 0 And 
				vNewOperation.RepairEndCleaningCount = 0 And 
				vNewOperation.VacantRoomCleaningCount = 0 Then
				vNewOperation.OtherOperationsCount = 1;
			Else
				vNewOperation.OtherOperationsCount = 0;
			EndIf;
			vOprStds = Catalogs.Operations.GetOperationStandards(pOperation, Object.Hotel, vNewOperation.RoomType, vNewOperation.Room, vNewOperation.Employee);
			If vOprStds.Count() > 0 Then
				vOprStdsRow = vOprStds.Get(0);
				vNewOperation.RoomSpace = vOprStdsRow.RoomSpace;
				vNewOperation.Duration = vOprStdsRow.Duration;
				vNewOperation.Price = vOprStdsRow.Price;
			EndIf;
		Else
			vNewOperation.OperationSortCode = 999999;
			vNewOperation.CheckOutCleaningCount = 0;
			vNewOperation.RegularCleaningCount = 0;
			vNewOperation.RepairEndCleaningCount = 0;
			vNewOperation.VacantRoomCleaningCount = 0;
			vNewOperation.OtherOperationsCount = 0;
			vNewOperation.Duration = 0;
			vNewOperation.RoomSpace = 0;
		EndIf;
		vNewOperation.Employee = Catalogs.Employees.EmptyRef();
		vNewOperation.EmployeeSortCode = 0;
		// Get operation standards
		If ValueIsFilled(vNewOperation.Operation) Then
			vStds = Catalogs.Operations.GetOperationStandards(vNewOperation.Operation, Object.Hotel, vNewOperation.RoomType, vNewOperation.Room, vNewOperation.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vNewOperation.Duration = vStdsRow.Duration;
				vNewOperation.RoomSpace = vStdsRow.RoomSpace;
				vNewOperation.Price = vStdsRow.Price;
			EndIf;
		EndIf;
		
		vResult = New Structure("idRoom, idOperation, imgOperation, nameOperation, colorOperation, nameEmployee, colorEmployee, isNew", 
		TrimAll(pRoom.UUID()), 
		TrimAll(vNewOperation.UUID), 
		GetStrOperationPicture(vNewOperation.Operation), 
		"",
		"",
		GetEmployeePresentation(vNewOperation.Employee), 
		"", 
		False);
		
		vColorOperations = Operations.FindRows(New Structure("Operation", vNewOperation.Operation));
		If vColorOperations.Count() > 0 Then
			vResult.colorOperation = vColorOperations[0].Color;
			vResult.nameOperation = TrimAll(vColorOperations[0].Description);
		Else
			vColor = vNewOperation.Operation.Color.Get();
			If TypeOf(vColor) = Type("Color") Then
				vColor = cmGetRGB4WebColor(vColor);
				vResult.colorOperation = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")"
			EndIf;	
		EndIf;
		
		If Not ValueIsFilled(vResult.nameOperation) Then
			vResult.nameOperation = TrimAll(vNewOperation.Operation.Code);
		EndIf;
		
		If ValueIsFilled(vNewOperation.Employee) Then
			vEmployeeArr = Employees.FindRows(New Structure("Employee", vNewOperation.Employee));
			If vEmployeeArr.Count() > 0 Then
				vEmployeeArr.colorEmployee = vEmployeeArr[0].Color;	
			Else						
				vColor = vNewOperation.Employee.Color.Get();
				If TypeOf(vColor) = Type("Color") Then
					vColor = cmGetRGB4WebColor(vColor);
					vResult.colorEmployee = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")";
				EndIf;
			EndIf;
		EndIf;
		
		vResult.isNew = vNewOperation.IsNew;
		For Each Operation In vRoomOperations Do
			vResult.isNew = ?(vResult.isNew, vResult.isNew, Operation.IsNew);	
		EndDo;
		
		Object.Operations.Sort("HotelSortCode, RoomSortCode, IsManual, OperationSortCode");
		CalculateTotalsAtServer();
		Modified = True;
	EndIf;
	Return vResult;
EndFunction // AddRoomOperationAtServer

// --------------------------------------------------------------------------------
&AtServer
Function GetRoomRefByUUID(pUUID)
	vRoom = Undefined;
	Try 
		vUUID = New UUID(pUUID);
		vRoom = Catalogs.Rooms.GetRef(vUUID);
		If vRoom.IsEmpty() Or vRoom.GetObject() = Undefined Then
			vRoom = Undefined;
		EndIf;
	Except
	EndTry;
	Return vRoom;
EndFunction // GetRoomRefByUUID

// -----------------------------------------------------------------------------
&AtServer
Function GetParentDocAtServer(pRoom)
	vRoomOperations = Object.Operations.FindRows(New Structure("Room", pRoom));
	If vRoomOperations <> Undefined And vRoomOperations.Count() > 0 Then
		For Each vOperRow In vRoomOperations Do
			If ValueIsFilled(vOperRow.ParentDoc) Then
				Return vOperRow.ParentDoc;
			EndIf;
		EndDo;
	EndIf;
	Return Undefined;
EndFunction // GetParentDocAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetRemarksOperationByRoom(pRoom)
	vRemarks = "";
	vRoomOperations = Object.Operations.FindRows(New Structure("Room", pRoom));
	For Each vItem In vRoomOperations Do
		If ValueIsFilled(TrimAll(vItem.Remarks)) Then
			vRemarks = vItem.Remarks;
			Break;
		EndIf;
	EndDo;
	Return vRemarks;
EndFunction // GetRemarksOperationByRoom

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterShowInputText(pText, pRoom) Export
	If pText <> Undefined Then
		vRoomOperations = Object.Operations.FindRows(New Structure("Room, IsManual", pRoom, False));
		For vNumber = 0 To vRoomOperations.Count() - 1 Do
			If vNumber = 0 Then
				vRoomOperations[vNumber].Remarks = pText;
			Else
				vRoomOperations[vNumber].Remarks = "";
			EndIf;
		EndDo;
		FillRoomEmployeeRmks(pText, GetUUIDByRef(pRoom));
	EndIf;
EndProcedure // AfterShowInputText

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetUUIDByRef(pRef)
	Return pRef.UUID();
EndFunction // GetUUIDByRef

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChooseTask(pUC, pExtraParams) Export
	If pUC <> Undefined Then
		OpenForm("DataProcessor.Messages.Form", New Structure("SetParamObject", pUC.Value), ThisForm, UUID);
	EndIf;
EndProcedure // AfterOperationChoice

// -----------------------------------------------------------------------------
&AtServer
Function CheckTask(pRef, rList)
	vResult = False;
	rList = New ValueList();
	If TypeOf(pRef) = Type("CatalogRef.Rooms") Then
		vTask = MessagesForParentDoc.FindRows(New Structure("Ref", pRef));
		If vTask.Count() > 0 Then
			vResult = True;
			rList.Add(pRef, NStr("en = 'Tasks for room: ';de = 'Aufgaben für das Zimmer: ';ru = 'Задачи на номер: '") + pRef.Description);
		EndIf;
		vRoomOperations = Object.Operations.FindRows(New Structure("Room, RoomType, IsManual", pRef, pRef.RoomType, False));
		For Each vItem In vRoomOperations Do
			If ValueIsFilled(vItem.ParentDoc) Then
				vTaskByDoc = MessagesForParentDoc.FindRows(New Structure("Ref", vItem.ParentDoc));
				If vTaskByDoc.Count() > 0 Then
					vResult = True;
					rList.Add(vItem.ParentDoc, NStr("en = 'Tasks for: ';de = 'Aufgaben für: ';ru = 'Задачи на: '") + vItem.ParentDoc);
				Else
					vResult = ?(vResult, True, False);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vResult;
EndFunction // CheckTask

// --------------------------------------------------------------------------------
&AtClient
Procedure FillOperationsAfterConfirmation(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	vJsonArr = FillOperationsAtServer();
	// Draw operations in the document
	DrawOperations(vJsonArr);
EndProcedure // FillOperationsAfterConfirmation

// --------------------------------------------------------------------------------
&AtServer
Function FillOperationsAtServer()
	vObj = FormAttributeToValue("Object");
	vOldOperations = vObj.Operations.Unload();
	// Clear list of operations
	vObj.Operations.Clear();
	// Get list of operations
	vOperations = vObj.pmGetOperations();
	// Resources
	vStandardsByRoom = Undefined;
	vStandardsByRoomType = Undefined;
	vStandardsByHotel = Undefined;
	vStandardsByOperation = Undefined;
	GetOperationStandards(Object.Hotel, SelOperations, SelRooms, SelRoomTypes, vStandardsByRoom, vStandardsByRoomType, vStandardsByHotel, vStandardsByOperation);
	// Fill operations tabular part 	 	
	vCurRoom = Undefined;
	For Each vOprRow In vOperations Do
		If SelShowRoomsWithOperationsOnly Then
			If Not ValueIsFilled(vOprRow.Operation) Then
				Continue;
			EndIf;
		EndIf;
		// Add row
		vRow = vObj.Operations.Add();
		FillPropertyValues(vRow, vOprRow);
		If Not ValueIsFilled(vRow.UUID) Or vRow.UUID = EmptyUUID Then
			vRow.UUID = New UUID();
		EndIf;
		vOldRows = vOldOperations.FindRows(New Structure("Room, RoomType, IsManual", vOprRow.Room, vOprRow.RoomType, False));
		For Each vOldOprRow In vOldRows Do
			If ValueIsFilled(TrimAll(vOldOprRow.Remarks)) Then
				vRow.Remarks = vOldOprRow.Remarks;
				vOldOprRow.Remarks = "";
				Break;
			EndIf;
		EndDo;
		// Fill current room block type
		If Not ValueIsFilled(vRow.RoomBlockType) Then
			vRow.RoomBlockType = vOprRow.CurrentRoomBlockType;
		EndIf;
		// Fill number of guests per room
		If ValueIsFilled(vRow.ParentDoc) Then
			vGuestList = New ValueList;
			vGuestArr = vOperations.FindRows(New Structure("Room", vRow.Room));
			For Each vGuestRow In vGuestArr Do
				If vRow.ParentDoc <> vGuestRow.ParentDoc Then
					If vGuestList.FindByValue(vGuestRow.ParentDoc) = Undefined Then	 
						vRow.NumberOfGuests = vRow.NumberOfGuests + vGuestRow.NumberOfGuests;
						vGuestList.Add(vGuestRow.ParentDoc);
					EndIf;
				EndIf;
			EndDo;
		Else
			vRow.NumberOfGuests = 0;
		EndIf;
		// Fill stay day number
		If ValueIsFilled(vRow.ParentDoc) And TypeOf(vRow.ParentDoc) = Type("DocumentRef.Accommodation") Then
			If ValueIsFilled(vRow.CheckInDate) And BegOfDay(vRow.CheckInDate) <= BegOfDay(vObj.Date) Then
				vRow.StayDay = (BegOfDay(vObj.Date) - BegOfDay(vRow.CheckInDate))/(24*3600);
			EndIf;
		EndIf;
		// Fill resources
		FillOperationRowResources(vRow, vOprRow);
		// Fill standards
		FillOperationRowStandards(vRow, vStandardsByRoom, vStandardsByRoomType, vStandardsByHotel, vStandardsByOperation);
	EndDo;
	// Calculate totals
	CalculateTotalsAtServer(vObj);
	// Fill back form attribute
	ValueToFormAttribute(vObj, "Object");
	Modified = True;
	vOperationsArr = DrawOperationsAtServer();
	Return vOperationsArr;
EndFunction // FillOperationsAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure GetOperationStandards(pHotel, pOperations, pRooms, pRoomTypes, rStandardsByRoom, rStandardsByRoomType, rStandardsByHotel, rStandardsByOperation)	
	// Build and run query to get data for the room
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	OperationStandards.Operation AS Operation,
	|	OperationStandards.Employee AS Employee,
	|	SUM(OperationStandards.Duration) AS Duration,
	|	SUM(OperationStandards.RoomSpace) AS RoomSpace,
	|	SUM(OperationStandards.Price) AS Price,
	|	OperationStandards.Room AS Room
	|FROM
	|	InformationRegister.OperationStandards AS OperationStandards
	|WHERE
	|	OperationStandards.Operation IN(&qOperation)
	|	AND OperationStandards.Hotel = &qHotel
	|	AND OperationStandards.Room IN(&qRoom)
	|
	|GROUP BY
	|	OperationStandards.Operation,
	|	OperationStandards.Employee,
	|	OperationStandards.Room";
	vQry.SetParameter("qOperation", pOperations);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoom", pRooms);
	rStandardsByRoom = vQry.Execute().Unload();
	
	// Run query to get data for the room type
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	OperationStandards.Operation AS Operation,
	|	OperationStandards.Employee AS Employee,
	|	SUM(OperationStandards.Duration) AS Duration,
	|	SUM(OperationStandards.RoomSpace) AS RoomSpace,
	|	SUM(OperationStandards.Price) AS Price,
	|	OperationStandards.RoomType AS RoomType
	|FROM
	|	InformationRegister.OperationStandards AS OperationStandards
	|WHERE
	|	OperationStandards.Operation IN(&qOperation)
	|	AND OperationStandards.Hotel = &qHotel
	|	AND OperationStandards.RoomType IN(&qRoomType)
	|
	|GROUP BY
	|	OperationStandards.Operation,
	|	OperationStandards.Employee,
	|	OperationStandards.RoomType";
	vQry.SetParameter("qOperation", pOperations);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomTypes);
	rStandardsByRoomType = vQry.Execute().Unload();
	
	// Run query to get data for the empty room and room type
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	OperationStandards.Operation AS Operation,
	|	OperationStandards.Employee AS Employee,
	|	SUM(OperationStandards.Duration) AS Duration,
	|	SUM(OperationStandards.RoomSpace) AS RoomSpace,
	|	SUM(OperationStandards.Price) AS Price
	|FROM
	|	InformationRegister.OperationStandards AS OperationStandards
	|WHERE
	|	OperationStandards.Operation IN(&qOperation)
	|	AND OperationStandards.Hotel = &qHotel
	|	AND OperationStandards.RoomType = &qRoomType
	|
	|GROUP BY
	|	OperationStandards.Operation,
	|	OperationStandards.Employee";
	vQry.SetParameter("qOperation", pOperations);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", Catalogs.RoomTypes.EmptyRef());
	vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
	rStandardsByHotel = vQry.Execute().Unload();
	
	// Run query to get data for the empty hotel, room and room type
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	OperationStandards.Operation AS Operation,
	|	OperationStandards.Employee AS Employee,
	|	SUM(OperationStandards.Duration) AS Duration,
	|	SUM(OperationStandards.RoomSpace) AS RoomSpace,
	|	SUM(OperationStandards.Price) AS Price
	|FROM
	|	InformationRegister.OperationStandards AS OperationStandards
	|WHERE
	|	OperationStandards.Operation IN(&qOperation)
	|	AND OperationStandards.Hotel = &qHotel
	|	AND OperationStandards.RoomType = &qRoomType
	|
	|GROUP BY
	|	OperationStandards.Operation,
	|	OperationStandards.Employee";
	vQry.SetParameter("qOperation", pOperations);
	vQry.SetParameter("qHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qRoomType", Catalogs.RoomTypes.EmptyRef());
	vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
	rStandardsByOperation = vQry.Execute().Unload();
EndProcedure // GetOperationStandards

// -----------------------------------------------------------------------------
&AtServer
Procedure FillOperationRowResources(pRow, pOprRow)
	pRow.CheckOutCleaningCount = 0;
	pRow.RegularCleaningCount = 0;
	pRow.RepairEndCleaningCount = 0;
	pRow.VacantRoomCleaningCount = 0;
	If ValueIsFilled(pRow.Operation) Then
		If pOprRow.CheckOutCleaning = Object.CheckOutCleaning And ValueIsFilled(Object.CheckOutCleaning) Then
			pRow.CheckOutCleaningCount = 1;
		ElsIf ValueIsFilled(pOprRow.RegularOperation) And ValueIsFilled(Object.RegularOperationGroup) Then
			pRow.RegularCleaningCount = 1;
		ElsIf pOprRow.RegularCleaning = Object.RegularCleaning And ValueIsFilled(Object.RegularCleaning) Then
			pRow.RegularCleaningCount = 1;
		ElsIf pOprRow.RepairEndCleaning = Object.RepairEndCleaning And ValueIsFilled(Object.RepairEndCleaning) Then
			pRow.RepairEndCleaningCount = 1;
		ElsIf pOprRow.VacantRoomCleaning = Object.VacantRoomCleaning And ValueIsFilled(Object.VacantRoomCleaning) Then
			pRow.VacantRoomCleaningCount = 1;
		EndIf;
	EndIf;
EndProcedure // FillOperationRowResources

// -----------------------------------------------------------------------------
&AtServer
Procedure FillOperationRowStandards(pRow, pStandardsByRoom, pStandardsByRoomType, pStandardsByHotel, pStandardsByOperation)
	pRow.RoomSpace = 0;
	pRow.Duration = 0;
	pRow.Price = 0;
	If ValueIsFilled(pRow.Operation) Then
		vOprStds = New Array();
		If ValueIsFilled(pRow.Employee) Then
			vOprStds = pStandardsByRoom.FindRows(New Structure("Employee, Operation, Room", pRow.Employee, pRow.Operation, pRow.Room));
			If vOprStds.Count() = 0 Then
				vOprStds = pStandardsByRoomType.FindRows(New Structure("Employee, Operation, RoomType", pRow.Employee, pRow.Operation, pRow.RoomType));
				If vOprStds.Count() = 0 Then
					vOprStds = pStandardsByHotel.FindRows(New Structure("Employee, Operation", pRow.Employee, pRow.Operation));
					If vOprStds.Count() = 0 Then
						vOprStds = pStandardsByOperation.FindRows(New Structure("Employee, Operation", pRow.Employee, pRow.Operation));
						If vOprStds.Count() = 0 Then
							vEmployeeGroup = pRow.Employee.Parent;
							If ValueIsFilled(vEmployeeGroup) Then
								vOprStds = pStandardsByRoom.FindRows(New Structure("Employee, Operation, Room", vEmployeeGroup, pRow.Operation, pRow.Room));
								If vOprStds.Count() = 0 Then
									vOprStds = pStandardsByRoomType.FindRows(New Structure("Employee, Operation, RoomType", vEmployeeGroup, pRow.Operation, pRow.RoomType));
									If vOprStds.Count() = 0 Then
										vOprStds = pStandardsByHotel.FindRows(New Structure("Employee, Operation", vEmployeeGroup, pRow.Operation));
										If vOprStds.Count() = 0 Then
											vOprStds = pStandardsByOperation.FindRows(New Structure("Employee, Operation", vEmployeeGroup, pRow.Operation));
										EndIf;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If vOprStds.Count() = 0 Then
			vOprStds = pStandardsByRoom.FindRows(New Structure("Employee, Operation, Room", Catalogs.Employees.EmptyRef(), pRow.Operation, pRow.Room));
			If vOprStds.Count() = 0 Then
				vOprStds = pStandardsByRoomType.FindRows(New Structure("Employee, Operation, RoomType", Catalogs.Employees.EmptyRef(), pRow.Operation, pRow.RoomType));
				If vOprStds.Count() = 0 Then
					vOprStds = pStandardsByHotel.FindRows(New Structure("Employee, Operation", Catalogs.Employees.EmptyRef(), pRow.Operation));
					If vOprStds.Count() = 0 Then
						vOprStds = pStandardsByOperation.FindRows(New Structure("Employee, Operation", Catalogs.Employees.EmptyRef(), pRow.Operation));
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If vOprStds.Count() > 0 Then
			vOprStdsRow = vOprStds.Get(0);
			pRow.RoomSpace = vOprStdsRow.RoomSpace;
			pRow.Duration = vOprStdsRow.Duration;
			pRow.Price = vOprStdsRow.Price;
		EndIf;
	EndIf;
EndProcedure // FillOperationRowStandards

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateTotalsAtServer(pObj = Undefined) 
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Calculate totals
	vObj.RoomSpace = vObj.Operations.Total("RoomSpace");
	vObj.Duration = Round(vObj.Operations.Total("Duration")/60, 3);
	vObj.CheckOutCleaningCount = vObj.Operations.Total("CheckOutCleaningCount");
	vObj.RegularCleaningCount = vObj.Operations.Total("RegularCleaningCount");
	vObj.RepairEndCleaningCount = vObj.Operations.Total("RepairEndCleaningCount");
	vObj.VacantRoomCleaningCount = vObj.Operations.Total("VacantRoomCleaningCount");
	vObj.OtherOperationsCount = vObj.Operations.Total("OtherOperationsCount");
	// Calculate totals per employee
	For Each vEmpRow In vObj.Employees Do
		// Reset employee resources
		vEmpRow.Duration = 0;
		vEmpRow.RoomSpace = 0;
		vEmpRow.CheckOutCleaningCount = 0;
		vEmpRow.RegularCleaningCount = 0;
		vEmpRow.RepairEndCleaningCount = 0;
		vEmpRow.VacantRoomCleaningCount = 0;
		vEmpRow.OtherOperationsCount = 0;
		// Find operations for the current employee
		vOpRows = vObj.Operations.FindRows(New Structure("Employee", vEmpRow.Employee));
		vDuration = 0;
		For Each vOpRow In vOpRows Do
			vDuration = vDuration + vOpRow.Duration;
			vEmpRow.RoomSpace = vEmpRow.RoomSpace + vOpRow.RoomSpace;
			vEmpRow.CheckOutCleaningCount = vEmpRow.CheckOutCleaningCount + vOpRow.CheckOutCleaningCount;
			vEmpRow.RegularCleaningCount = vEmpRow.RegularCleaningCount + vOpRow.RegularCleaningCount;
			vEmpRow.RepairEndCleaningCount = vEmpRow.RepairEndCleaningCount + vOpRow.RepairEndCleaningCount;
			vEmpRow.VacantRoomCleaningCount = vEmpRow.VacantRoomCleaningCount + vOpRow.VacantRoomCleaningCount;
			vEmpRow.OtherOperationsCount = vEmpRow.OtherOperationsCount + vOpRow.OtherOperationsCount;
		EndDo;
		vEmpRow.Duration = Round(vDuration/60, 3);
	EndDo;
	// Set employees list
	SetEmployeesChoiceList(vObj);
	// Set totals presentation
	SetTotalsPresentation(vObj);
	// Fill back form attribute
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // CalculateTotalsAtServer

// --------------------------------------------------------------------------------
&AtServer
Function UpdateOperationsAtServer()
	vObj = FormAttributeToValue("Object");
	// Save current operations
	vOldOperations = vObj.Operations.Unload();
	// Resources
	vStandardsByRoom = Undefined;
	vStandardsByRoomType = Undefined;
	vStandardsByHotel = Undefined;
	vStandardsByOperation = Undefined;
	GetOperationStandards(Object.Hotel, SelOperations, SelRooms, SelRoomTypes, vStandardsByRoom, vStandardsByRoomType, vStandardsByHotel, vStandardsByOperation);
	// Clear list of operations but save the manual ones
	vOpRows = vObj.Operations.FindRows(New Structure("IsManual", False));
	For Each vOpRow In vOpRows Do
		vObj.Operations.Delete(vOpRow);
	EndDo;
	// Get list of operations
	vOperations = vObj.pmGetOperations();
	// Fill operations tabular part
	vCurRoom = Undefined;
	For Each vOprRow In vOperations Do
		// Add operation
		vRow = vObj.Operations.Add();
		FillPropertyValues(vRow, vOprRow);
		// Fill remarks
		vOldRows = vOldOperations.FindRows(New Structure("Room, RoomType, IsManual", vOprRow.Room, vOprRow.RoomType, False));
		For Each vOldOprRow In vOldRows Do
			If ValueIsFilled(TrimAll(vOldOprRow.Remarks)) Then
				vRow.Remarks = vOldOprRow.Remarks;
				vOldOprRow.Remarks = "";
				Break;
			EndIf;
		EndDo;
		// Fill current room block type
		If Not ValueIsFilled(vRow.RoomBlockType) Then
			vRow.RoomBlockType = vOprRow.CurrentRoomBlockType;
		EndIf;
		// Fill number of guests per room
		If ValueIsFilled(vRow.ParentDoc) Then
			vGuestList = New ValueList;
			vGuestArr = vOperations.FindRows(New Structure("Room", vRow.Room));
			For Each vGuestRow In vGuestArr Do
				If vRow.ParentDoc <> vGuestRow.ParentDoc Then
					If vGuestList.FindByValue(vGuestRow.ParentDoc) = Undefined Then	 
						vRow.NumberOfGuests = vRow.NumberOfGuests + vGuestRow.NumberOfGuests;
						vGuestList.Add(vGuestRow.ParentDoc);
					EndIf;
				EndIf;
			EndDo;
		Else
			vRow.NumberOfGuests = 0;
		EndIf;
		// Fill stay day number
		If ValueIsFilled(vRow.ParentDoc) And TypeOf(vRow.ParentDoc) = Type("DocumentRef.Accommodation") Then
			If ValueIsFilled(vRow.CheckInDate) And BegOfDay(vRow.CheckInDate) <= BegOfDay(vObj.Date) Then
				vRow.StayDay = (BegOfDay(vObj.Date) - BegOfDay(vRow.CheckInDate))/(24*3600);
			EndIf;
		EndIf;
		// Fill resources
		FillOperationRowResources(vRow, vOprRow);
	EndDo;
	// Sort operations
	vObj.Operations.Sort("HotelSortCode, RoomSortCode, IsManual, OperationSortCode");
	// Try to match old and new rows and reset is new flag
	For Each vRow In vObj.Operations Do
		vOldRows = vOldOperations.FindRows(New Structure("Room, RoomType", vRow.Room, vRow.RoomType));
		If vOldRows.Count() > 0 Then
			For Each vOldRow In vOldRows Do 
				If vRow.IsNew And vRow.Operation = vOldRow.Operation Then
					vRow.IsNew = False;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	// Remove old rows without employee and operation
	i = 0;
	While i < vOldOperations.Count() Do
		vOldRow = vOldOperations.Get(i);
		If Not ValueIsFilled(vOldRow.Operation) Then
			vOldOperations.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Sort operations
	vObj.Operations.Sort("HotelSortCode, RoomSortCode, IsManual, OperationSortCode");
	// Try to restore employee assignments
	vOperationIndexInRoom = 0;
	vCurRoom = Undefined;
	For Each vRow In vObj.Operations Do
		If vCurRoom = vRow.Room Then
			If Not ValueIsFilled(vRow.Operation) Then
				Continue;
			EndIf;
			vOperationIndexInRoom = vOperationIndexInRoom + 1;
		Else
			vCurRoom = vRow.Room;
			vOperationIndexInRoom = 0;
		EndIf;
		vOldRows = vOldOperations.FindRows(New Structure("Room, RoomType, IsManual", vRow.Room, vRow.RoomType, False));
		If vOldRows.Count() > 0 Then
			// Match found. Restore employee
			If vOperationIndexInRoom < vOldRows.Count() Then
				vOldRow = vOldRows.Get(vOperationIndexInRoom);
				If Not ValueIsFilled(vRow.Operation) Then
					vRow.Operation = vOldRow.Operation;
					vRow.OperationSortCode = vOldRow.OperationSortCode;
					vRow.CheckOutCleaningCount = vOldRow.CheckOutCleaningCount;
					vRow.RegularCleaningCount = vOldRow.RegularCleaningCount;
					vRow.VacantRoomCleaningCount = vOldRow.VacantRoomCleaningCount;
					vRow.OtherOperationsCount = vOldRow.OtherOperationsCount;
					vRow.RepairEndCleaningCount = vOldRow.RepairEndCleaningCount;
					vRow.IsNew = False;
				EndIf;
				If ValueIsFilled(vOldRow.Employee) And ValueIsFilled(vOldRow.Operation) Then
					vRow.Employee = vOldRow.Employee;
					vRow.EmployeeSortCode = vOldRow.EmployeeSortCode;
				EndIf;
				If Not ValueIsFilled(vRow.UUID) And ValueIsFilled(vOldRow.UUID) Then
					vRow.UUID = vOldRow.UUID;
				Else
					vRow.UUID = New UUID;
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vRow.UUID) Or vRow.UUID = EmptyUUID Then
			vRow.UUID = New UUID();
		EndIf;
		// Fill standards
		FillOperationRowStandards(vRow, vStandardsByRoom, vStandardsByRoomType, vStandardsByHotel, vStandardsByOperation);
	EndDo;
	// Remove rows without operations
	If SelShowRoomsWithOperationsOnly Then
		i = 0;
		While i < vObj.Operations.Count() Do 
			vOprRow = vObj.Operations.Get(i);
			If Not ValueIsFilled(vOprRow.Operation) Then
				vObj.Operations.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	// Calculate totals
	CalculateTotalsAtServer(vObj);
	// Fill back form attribute
	ValueToFormAttribute(vObj, "Object");
	Modified = True;
	vOperationsArr = DrawOperationsAtServer();
	Return vOperationsArr;
EndFunction // UpdateOperationsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CalculateTotals() Export  
	CalculateTotalsAtServer();
EndProcedure // CalculateTotals

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEmployeesByWorkingScheduleAtServer()
	vObj = FormAttributeToValue("Object");
	// Clear employees list
	vObj.Employees.Clear();
	// Get list of employees available according to the working time schedule
	vEmployees = vObj.pmGetAvailableEmployees();
	// Fill employees list
	For Each vEmpRow In vEmployees Do
		vRow = vObj.Employees.Add();
		FillPropertyValues(vRow, vEmpRow);
		If ValueIsFilled(vRow.Employee.RoomSection) Then
			vRow.RoomSection = vRow.Employee.RoomSection;
		EndIf;
		If ValueIsFilled(vRow.Employee.Room) Then
			vRow.Room = vRow.Employee.Room;
		EndIf;
		If ValueIsFilled(vRow.Employee.RoomFolderFrom) Then
			vRow.RoomFolderFrom = vRow.Employee.RoomFolderFrom;
		EndIf;
		If ValueIsFilled(vRow.Employee.RoomFolderTo) Then
			vRow.RoomFolderTo = vRow.Employee.RoomFolderTo;
		EndIf;
	EndDo;
	// Calculate totals
	CalculateTotalsAtServer(vObj);
	// Set employees list for operations
	SetEmployeesChoiceList(vObj);
	// Oject to form attributes
	ValueToFormAttribute(vObj, "Object");
EndProcedure // FillEmployeesByWorkingScheduleAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterInputOfNumberOfHousemaids(pValue, pExraParameters) Export
	If pValue <> Undefined Then
		ShowInputNumber(New NotifyDescription("AfterInputOfHours", ThisForm, pValue), 0, NStr("en='Working hours? (per shift)';ru='Рабочих часов? (в смене)';de='Arbeitsstunden? (in der Schicht)'"), 2, 0);
	EndIf;
EndProcedure // AfterInputOfNumberOfHousemaids

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterInputOfHours(pHours, pQuantity) Export
	If pHours <> Undefined Then
		FillEmployeesByQuantityAtServer(pQuantity, pHours);
	EndIf;
EndProcedure // AfterInputOfHours

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEmployeesByQuantityAtServer(pQuantity, pHours)
	vObj = FormAttributeToValue("Object");
	// Clear employees list
	vObj.Employees.Clear();
	// Hotel code
	vHotelCode = "";
	If ValueIsFilled(vObj.Hotel) Then
		vHotelCode = TrimAll(vObj.Hotel.Code);
	EndIf;
	// Fill employees list
	For i = 1 To pQuantity Do
		// Get employee name
		vName = NStr("en='Housemaid ';ru='Горничная ';de='Hausmädchen '") + Format(i, "NFD=0;NZ=;NG=");
		vCode = "HM" + Format(i, "NFD=0;NZ=;NG=") + "-" + vHotelCode;
		
		vEmployee = FindEmployeeByCode(vCode);
		If Not ValueIsFilled(vEmployee) Then
			vEmployeeObj = Catalogs.Employees.CreateItem();
			vEmployeeObj.Code = vCode;
			vEmployeeObj.Description = vName;
			vEmployeeObj.SortCode = i;
			vEmployeeObj.Color = New ValueStorage(GetNewEmployeeColor());
			vEmployeeObj.Hotel = vObj.Hotel;
			vEmployeeObj.DeletionMark = False;
			vEmployeeObj.Write();
			
			vEmployee = vEmployeeObj.Ref;
		EndIf;
		
		vRow = vObj.Employees.Add();
		vRow.Employee = vEmployee;
		FillPropertyValues(vRow, vEmployee);
		vRow.EmployeeSortCode = vEmployee.SortCode;
		vRow.Hours = pHours;
	EndDo;
	// Calculate totals
	CalculateTotalsAtServer(vObj);
	// Set employees list for operations
	SetEmployeesChoiceList(vObj);
	// Oject to form attributes
	ValueToFormAttribute(vObj, "Object");
EndProcedure // FillEmployeesByQuantityAtServer

// -----------------------------------------------------------------------------
&AtServer
Function FindEmployeeByCode(pCode)
	vEmployee = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Employees.Ref AS Ref
	|FROM
	|	Catalog.Employees AS Employees
	|WHERE
	|	NOT Employees.DeletionMark
	|	AND NOT Employees.IsFolder
	|	AND Employees.Code = &qCode
	|	AND Employees.Hotel = &qHotel
	|
	|ORDER BY
	|	Employees.SortCode,
	|	Employees.Description";
	vQry.SetParameter("qCode", pCode);
	vQry.SetParameter("qHotel", Object.Hotel);
	vEmployees = vQry.Execute().Unload();
	If vEmployees.Count() > 0 Then
		vEmployee = vEmployees.Get(0).Ref;
	EndIf;
	Return vEmployee;
EndFunction // FindEmployeeByCode

// -----------------------------------------------------------------------------
&AtServer
Function GetNewEmployeeColor()
	vRG = New RandomNumberGenerator(Seed);
	Seed = Seed + 65535;
	
	vRed = vRG.RandomNumber(186, 255);
	vBlue = vRG.RandomNumber(186, 255);
	vGreen = vRG.RandomNumber(186, 255);
	
	Return New Color(vRed, vGreen, vBlue);
EndFunction // GetNewEmployeeColor

// -----------------------------------------------------------------------------
&AtServer
Function GetTotalOperations(rOperations)
	vTotals = New Structure("TotalOperationsCount, CheckOutCleaningCount, RegularCleaningCount, RepairEndCleaningCount, VacantRoomCleaningCount, OtherOperationsCount", 0, 0, 0, 0, 0, 0);
	vTotals.CheckOutCleaningCount = Object.Operations.Total("CheckOutCleaningCount");
	vTotals.RegularCleaningCount = Object.Operations.Total("RegularCleaningCount");
	vTotals.RepairEndCleaningCount = Object.Operations.Total("RepairEndCleaningCount");
	vTotals.VacantRoomCleaningCount = Object.Operations.Total("VacantRoomCleaningCount");
	vTotals.OtherOperationsCount = Object.Operations.Total("OtherOperationsCount");
	vTotals.TotalOperationsCount = vTotals.CheckOutCleaningCount + vTotals.RegularCleaningCount + vTotals.RepairEndCleaningCount + vTotals.VacantRoomCleaningCount + vTotals.OtherOperationsCount;
	For Each vOperationsRow In Object.Operations Do
		If ValueIsFilled(vOperationsRow.Operation) Then
			vOpStruct = New Structure("Room, Employee, RoomType, Operation, IsCheckInWaiting, NumberOfGuests, Guest, ClientType, Duration, RoomSpace, Price, UUID");
			FillPropertyValues(vOpStruct, vOperationsRow);
			rOperations.Add(vOpStruct);
		EndIf;
	EndDo;
	Return vTotals;
EndFunction // GetTotalOperations

// -----------------------------------------------------------------------------
&AtServer
Function UpdateRoomStatusAtServer(pRoom)
	vRoomOperations = Object.Operations.FindRows(New Structure("Room", pRoom));
	For Each vCurRow In vRoomOperations Do  
		vCurRow.RoomStatus = pRoom.RoomStatus;
	EndDo;
	CalculateTotalsAtServer();
	Modified = True;
	vColorRoomStatus = "";
	vRoomStatus = RoomStatuses.FindRows(New Structure("RoomStatus", pRoom.RoomStatus));
	If vRoomStatus.Count() > 0 Then
		vColorRoomStatus = vRoomStatus[0].Color;
	Else
		vColor = pRoom.RoomStatus.Color.Get();
		If TypeOf(vColor) = Type("Color") Then
			vColor = cmGetRGB4WebColor(vColor);
			vColorRoomStatus = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")"
		EndIf;	
	EndIf;
	Return New Structure("idRoom, imgRoomStatus, colorRoomStatus", TrimAll(pRoom.UUID()), GetRoomStatusIcon(pRoom.RoomStatus), vColorRoomStatus);
EndFunction // UpdateRoomStatusAtServer

// -----------------------------------------------------------------------------
&AtServer
Function AssignEmployeesByWorkingTimeAtServer(pRooms) 
	vResult = New Array;
	vObj = FormAttributeToValue("Object");
	// Get list of employees available according to the working time schedule
	If vObj.Employees.Count() = 0 Then
		vEmployees = vObj.pmGetAvailableEmployees();
		// Fill employees list
		For Each vEmpRow In vEmployees Do
			vRow = vObj.Employees.Add();
			FillPropertyValues(vRow, vEmpRow);
		EndDo;
	EndIf;
	If vObj.Employees.Count() = 0 Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Available employees list is not filled!';ru='Не заполнена таблица доступных сотрудников!';de='Die Tabelle verfügbarer Mitarbeiter ist nicht ausgefüllt!'"));
		Return vResult;
	EndIf;
	// Clear employees column in the operations
	For Each vOpRow In vObj.Operations Do
		If ValueIsFilled(vOpRow.Employee) Then
			vOpRow.Employee = Catalogs.Employees.EmptyRef();
			vOpRow.EmployeeSortCode = 0;
			// Get operation standards
			If ValueIsFilled(vOpRow.Operation) Then
				vStds = Catalogs.Operations.GetOperationStandards(vOpRow.Operation, vObj.Hotel, vOpRow.RoomType, vOpRow.Room, vOpRow.Employee);
				If vStds.Count() > 0 then
					vStdsRow = vStds.Get(0);
					vOpRow.Duration = vStdsRow.Duration;
					vOpRow.RoomSpace = vStdsRow.RoomSpace;
					vOpRow.Price = vStdsRow.Price;
				EndIf;
			EndIf;
		Endif;
	EndDo;
	// Recalculate totals
	CalculateTotalsAtServer(vObj);
	// Create working table with operations
	vOperationsAll = vObj.Operations.Unload();
	
	// Remove rows with the same rooms
	i = 0;
	While i < vOperationsAll.Count() Do
		vOprRow = vOperationsAll.Get(i);
		If Not ValueIsFilled(vOprRow.Operation) Then
			vOperationsAll.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	vOperations = vOperationsAll.CopyColumns();
	For Each vOperationRow In vOperationsAll Do 
		If pRooms.FindByValue(TrimAll(vOperationRow.Room.UUID())) <> Undefined Then
			vNewOperationRow = vOperations.Add();
			FillPropertyValues(vNewOperationRow, vOperationRow);
		EndIf;
	EndDo;
	
	// Calculate total operations time
	vAverageWorkingTimePerEmployee = 9999999999;
	vTotalOperationsTime = Round(vOperations.Total("Duration")/60, 3);
	vEmployeesCount = vObj.Employees.Count();
	If vEmployeesCount > 0 And vTotalOperationsTime > 0 Then
		vAverageWorkingTimePerEmployee = vTotalOperationsTime/vEmployeesCount;
	EndIf;
	vUsedEmployees = New ValueList();
	// Reset employee working time
	For Each vEmpRow In vObj.Employees Do
		vEmpRow.Duration = 0;
	EndDo;
	vOperations.GroupBy("Room, Employee, EmployeeSortCode","Duration");
	// Use all available working time for the employees in the list
	vRunCount = 1;
	While vRunCount < 3 Do
		For Each vEmpRow In vObj.Employees Do
			For Each vOpRow In vOperations Do
				If Not ValueIsFilled(vOpRow.Employee) And vOpRow.Duration <> 0 Then
					// Check employee room folder/section restrictions
					If vRunCount < 2 Or vObj.AssignEmployees2OperationsStrictlyByRoomSectionsOrFolders Then
						If ValueIsFilled(vEmpRow.RoomSection) And ValueIsFilled(vOpRow.Room) And 
							(vEmpRow.RoomSection.IsFolder And ValueIsFilled(vOpRow.Room.RoomSection) And Not vOpRow.Room.RoomSection.BelongsToItem(vEmpRow.RoomSection) Or 
							Not vEmpRow.RoomSection.IsFolder And vOpRow.Room.RoomSection <> vEmpRow.RoomSection) Then
							Continue;
						ElsIf ValueIsFilled(vEmpRow.Room) And ValueIsFilled(vOpRow.Room) And 
							Not vOpRow.Room.BelongsToItem(vEmpRow.Room) Then
							Continue;
						ElsIf ValueIsFilled(vEmpRow.RoomFolderFrom) And ValueIsFilled(vOpRow.Room) And 
							vOpRow.Room.SortCode < vEmpRow.RoomFolderFrom.SortCode Then
							Continue;
						ElsIf ValueIsFilled(vEmpRow.RoomFolderTo) And ValueIsFilled(vOpRow.Room) And 
							vOpRow.Room.SortCode > vEmpRow.RoomFolderTo.SortCode Then
							Continue;
						EndIf;
					EndIf;
					
					vOperationsByRoom = vOperationsAll.FindRows(New Structure("Room, Employee, EmployeeSortCode", vOpRow.Room, vOpRow.Employee, vOpRow.EmployeeSortCode));
					
					// Check duration
					vEmpRowDuration = vEmpRow.Duration + Round(vOpRow.Duration/60, 3);
					If vEmpRowDuration > vEmpRow.Hours Then
						Continue;
					ElsIf vEmpRowDuration > vAverageWorkingTimePerEmployee Then
						vUsedEmployeesItem = vUsedEmployees.FindByValue(vOpRow.Employee);
						If vUsedEmployeesItem = Undefined Then
							vUsedEmployees.Add(vEmpRow.Employee);
							For Each vRowOperationByRoom In vOperationsByRoom Do
								vRowOperationByRoom.Employee = vEmpRow.Employee;
								vRowOperationByRoom.EmployeeSortCode = vEmpRow.EmployeeSortCode;
								// Get operation standards
								If ValueIsFilled(vRowOperationByRoom.Operation) Then
									vStds = Catalogs.Operations.GetOperationStandards(vRowOperationByRoom.Operation, vObj.Hotel, vRowOperationByRoom.RoomType, vRowOperationByRoom.Room, vRowOperationByRoom.Employee);
									If vStds.Count() > 0 then
										vStdsRow = vStds.Get(0);
										vRowOperationByRoom.Duration = vStdsRow.Duration;
										vRowOperationByRoom.RoomSpace = vStdsRow.RoomSpace;
										vRowOperationByRoom.Price = vStdsRow.Price;
									EndIf;
								EndIf;
							EndDo;
							vOpRow.Employee = vEmpRow.Employee;
							vOpRow.EmployeeSortCode = vEmpRow.EmployeeSortCode;
							vEmpRow.Duration = vEmpRowDuration;
						Else
							Continue;
						EndIf;
					Else
						For Each vRowOperationByRoom In vOperationsByRoom Do
							vRowOperationByRoom.Employee = vEmpRow.Employee;
							vRowOperationByRoom.EmployeeSortCode = vEmpRow.EmployeeSortCode;
							// Get operation standards
							If ValueIsFilled(vRowOperationByRoom.Operation) Then
								vStds = Catalogs.Operations.GetOperationStandards(vRowOperationByRoom.Operation, vObj.Hotel, vRowOperationByRoom.RoomType, vRowOperationByRoom.Room, vRowOperationByRoom.Employee);
								If vStds.Count() > 0 then
									vStdsRow = vStds.Get(0);
									vRowOperationByRoom.Duration = vStdsRow.Duration;
									vRowOperationByRoom.RoomSpace = vStdsRow.RoomSpace;
									vRowOperationByRoom.Price = vStdsRow.Price;
								EndIf;
							EndIf;
						EndDo;
						vOpRow.Employee = vEmpRow.Employee;
						vOpRow.EmployeeSortCode = vEmpRow.EmployeeSortCode;
						vEmpRow.Duration = vEmpRowDuration;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
		vRunCount = vRunCount + 1;
	EndDo;
	// Copy assignement to the initial operations value table
	For Each vAsnOpRow In vOperationsAll Do
		// Try to find appropriate initial row
		vOprRows = vObj.Operations.FindRows(New Structure("Room, UUID", vAsnOpRow.Room, vAsnOpRow.UUID));
		If vOprRows.Count() = 1 Then
			vOprRow = vOprRows[0];
			vOprRow.Employee = vAsnOpRow.Employee;
			vOprRow.EmployeeSortCode = vAsnOpRow.EmployeeSortCode;
			vOprRow.Duration = vAsnOpRow.Duration;
			vOprRow.RoomSpace = vAsnOpRow.RoomSpace;
			vOprRow.Price = vAsnOpRow.Price;
			
			vResultStr = New Structure("idOperation, nameEmployee, colorEmployee", TrimAll(vOprRow.UUID), GetEmployeePresentation(vAsnOpRow.Employee), "");
			
			If ValueIsFilled(vAsnOpRow.Employee) Then
				vEmployeeArr = Employees.FindRows(New Structure("Employee", vAsnOpRow.Employee));
				If vEmployeeArr.Count() > 0 Then
					vResultStr.colorEmployee = vEmployeeArr[0].Color;	
				Else
					vColor = vAsnOpRow.Employee.Color.Get();
					If TypeOf(vColor) = Type("Color") Then
						vColor = cmGetRGB4WebColor(vColor);
						vResultStr.colorEmployee = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")";
					EndIf;
				EndIf;
			EndIf;
			vResult.Add(vResultStr);
		EndIf;
	EndDo;
	// Calculate totals
	CalculateTotalsAtServer(vObj);
	// Fill employees list
	SetEmployeesChoiceList(vObj);
	// Set object back to form attribute
	ValueToFormAttribute(vObj, "Object");
	Modified = True;
	Return vResult;
EndFunction // AssignEmployeesByWorkingTimeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetInitialAverageQuantity(rEmpCount)
	vObj = FormAttributeToValue("Object");
	// Get list of employees available according to the working time schedule
	If vObj.Employees.Count() = 0 Then
		vEmployees = vObj.pmGetAvailableEmployees();
		// Fill employees list
		For Each vEmpRow In vEmployees Do
			vRow = vObj.Employees.Add();
			FillPropertyValues(vRow, vEmpRow);
		EndDo;
	EndIf;
	If vObj.Employees.Count() = 0 Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Available employees list is not filled!';ru='Не заполнена таблица доступных сотрудников!';de='Die Tabelle verfügbarer Mitarbeiter ist nicht ausgefüllt!'"));
	EndIf;
	// Recalculate totals
	CalculateTotalsAtServer();
	// Average opeartion quantity
	vAvgQuantity = New Structure("CheckOutCleaningCount, RegularCleaningCount, RepairEndCleaningCount, VacantRoomCleaningCount, OtherOperationsCount",
	0, 0, 0, 0, 0);
	rEmpCount = vObj.Employees.Count();
	If rEmpCount > 0 Then
		vAvgQuantity.CheckOutCleaningCount = cmRoundUp(vObj.Operations.Total("CheckOutCleaningCount") / rEmpCount, 0);
		vAvgQuantity.RegularCleaningCount = cmRoundUp(vObj.Operations.Total("RegularCleaningCount") / rEmpCount, 0);
		vAvgQuantity.RepairEndCleaningCount = cmRoundUp(vObj.Operations.Total("RepairEndCleaningCount") / rEmpCount, 0);
		vAvgQuantity.VacantRoomCleaningCount = cmRoundUp(vObj.Operations.Total("VacantRoomCleaningCount") / rEmpCount, 0);
		vAvgQuantity.OtherOperationsCount = cmRoundUp(vObj.Operations.Total("OtherOperationsCount") / rEmpCount, 0);
	EndIf;
	// Set object back to form attribute
	ValueToFormAttribute(vObj, "Object");
	Return vAvgQuantity;
EndFunction // GetInitialAverageQuantity

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputOfAverageQuantity(pAvgQuantity, pExtraParams) Export
	If pAvgQuantity <> Undefined Then
		HTMLOperationSchedule.updateEmployee(GetHTMLObj(AssignEmployeesBalancedAtServer(GetVisibleRooms(), pAvgQuantity, pExtraParams.EmployeesCount, pExtraParams.InitAvgQuantity)));
	EndIf;
EndProcedure // AfterInputOfAverageQuantity

// -----------------------------------------------------------------------------
&AtServer
Function AssignEmployeesBalancedAtServer(pRooms, pAvgQuantity, pEmployeesCount, pInitAvgQuantity)
	vResult = New Array;
	vObj = FormAttributeToValue("Object");
	// Clear employees column in the operations
	For Each vOpRow In vObj.Operations Do
		If ValueIsFilled(vOpRow.Employee) Then
			vOpRow.Employee = Catalogs.Employees.EmptyRef();
			vOpRow.EmployeeSortCode = 0;
			// Get operation standards
			If ValueIsFilled(vOpRow.Operation) Then
				vStds = Catalogs.Operations.GetOperationStandards(vOpRow.Operation, vObj.Hotel, vOpRow.RoomType, vOpRow.Room, vOpRow.Employee);
				If vStds.Count() > 0 then
					vStdsRow = vStds.Get(0);
					vOpRow.Duration = vStdsRow.Duration;
					vOpRow.RoomSpace = vStdsRow.RoomSpace;
					vOpRow.Price = vStdsRow.Price;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	// Process parameters
	vAvgQuantity = pAvgQuantity;
	vEmpCount = pEmployeesCount;
	vInitAvgQuantity = pInitAvgQuantity;
	// Create working table with operations
	vOperationsAll = vObj.Operations.Unload();
	// Remove rows with the same rooms
	i = 0;
	While i < vOperationsAll.Count() Do
		vOprRow = vOperationsAll.Get(i);
		If Not ValueIsFilled(vOprRow.Operation) Then
			vOperationsAll.Delete(i);
		Else
			If ValueIsFilled(vObj.RegularCleaning) And vOprRow.RegularCleaningCount > 0 Then
				vOprRow.Operation = vObj.RegularCleaning;
				vOprRow.OperationSortCode = vObj.RegularCleaning.SortCode;
			EndIf;
			i = i + 1;
		EndIf;
	EndDo;
	vOperations = vOperationsAll.CopyColumns();
	For Each vOperationRow In vOperationsAll Do
		If pRooms.FindByValue(TrimAll(vOperationRow.Room.UUID())) <> Undefined Then
			vNewOperationRow = vOperations.Add();
			FillPropertyValues(vNewOperationRow, vOperationRow);
		EndIf;
	EndDo;
	
	// Build value table of employees
	vEmployees = vObj.Employees.Unload();
	vEmployees.Columns.Add("TotalOperationsCount", cmGetNumberTypeDescription(10,0));
	// Calculate average number of operations per employee for each room type and operation type
	vAverages = vOperations.Copy();
	vAverages.GroupBy("Operation, OperationSortCode", "CheckOutCleaningCount, RegularCleaningCount, RepairEndCleaningCount, VacantRoomCleaningCount, OtherOperationsCount");
	vAverages.Sort("OperationSortCode");
	For Each vAvgOprRow In vAverages Do
		If vAvgOprRow.CheckOutCleaningCount > 0 Then
			vAvgOprRow.CheckOutCleaningCount = cmRoundUp(vAvgOprRow.CheckOutCleaningCount / vEmpCount, 0);
		EndIf;
		If vAvgOprRow.RegularCleaningCount > 0 Then
			vAvgOprRow.RegularCleaningCount = cmRoundUp(vAvgOprRow.RegularCleaningCount / vEmpCount, 0);
		EndIf;
		If vAvgOprRow.RepairEndCleaningCount > 0 Then
			vAvgOprRow.RepairEndCleaningCount = cmRoundUp(vAvgOprRow.RepairEndCleaningCount / vEmpCount, 0);
		EndIf;
		If vAvgOprRow.VacantRoomCleaningCount > 0 Then
			vAvgOprRow.VacantRoomCleaningCount = cmRoundUp(vAvgOprRow.VacantRoomCleaningCount / vEmpCount, 0);
		EndIf;
		If vAvgOprRow.OtherOperationsCount > 0 Then
			vAvgOprRow.OtherOperationsCount = cmRoundUp(vAvgOprRow.OtherOperationsCount / vEmpCount, 0);
		EndIf;
	EndDo;
	vAverages.Columns.Add("Employee", cmGetCatalogTypeDescription("Employees"));
	// Add employees to average operations table
	vEmpAverages = vAverages.Copy();
	For Each vEmpRow In vEmployees Do
		If vEmployees.IndexOf(vEmpRow) = 0 Then
			For Each vEmpAvgOprRow In vEmpAverages Do
				vEmpAvgOprRow.Employee = vEmpRow.Employee;
			EndDo;
		Else
			vWrkEmpAverages = vAverages.Copy();
			For Each vWrkEmpAvgOprRow In vWrkEmpAverages Do
				vEmpAvgOprRow = vEmpAverages.Add();
				FillPropertyValues(vEmpAvgOprRow, vWrkEmpAvgOprRow);
				vEmpAvgOprRow.Employee = vEmpRow.Employee;
			EndDo;
		EndIf;
	EndDo;
	// Calculate average number of operations per employee for each room type and operation type
	vAvgOperations = vOperations.Copy();
	vAvgOperations.GroupBy("HotelSortCode, RoomType, RoomTypeSortCode, Operation, OperationSortCode", "CheckOutCleaningCount, RegularCleaningCount, RepairEndCleaningCount, VacantRoomCleaningCount, OtherOperationsCount");
	vAvgOperations.Sort("HotelSortCode, RoomTypeSortCode, OperationSortCode");
	For Each vAvgOprRow In vAvgOperations Do
		If vAvgOprRow.CheckOutCleaningCount > 0 Then
			vAvgOprRow.CheckOutCleaningCount = cmRoundUp(vAvgOprRow.CheckOutCleaningCount/vEmpCount, 0);
		EndIf;
		If vAvgOprRow.RegularCleaningCount > 0 Then
			vAvgOprRow.RegularCleaningCount = cmRoundUp(vAvgOprRow.RegularCleaningCount/vEmpCount, 0);
		EndIf;
		If vAvgOprRow.RepairEndCleaningCount > 0 Then
			vAvgOprRow.RepairEndCleaningCount = cmRoundUp(vAvgOprRow.RepairEndCleaningCount/vEmpCount, 0);
		EndIf;
		If vAvgOprRow.VacantRoomCleaningCount > 0 Then
			vAvgOprRow.VacantRoomCleaningCount = cmRoundUp(vAvgOprRow.VacantRoomCleaningCount/vEmpCount, 0);
		EndIf;
		If vAvgOprRow.OtherOperationsCount > 0 Then
			vAvgOprRow.OtherOperationsCount = cmRoundUp(vAvgOprRow.OtherOperationsCount/vEmpCount, 0);
		EndIf;
	EndDo;
	vAvgOperations.Columns.Add("Employee", cmGetCatalogTypeDescription("Employees"));
	// Add employees to average operations table
	vEmpAvgOperations = vAvgOperations.Copy();
	For Each vEmpRow In vEmployees Do
		If vEmployees.IndexOf(vEmpRow) = 0 Then
			For Each vEmpAvgOprRow In vEmpAvgOperations Do
				vEmpAvgOprRow.Employee = vEmpRow.Employee;
			EndDo;
		Else
			vWrkEmpAvgOperations = vAvgOperations.Copy();
			For Each vWrkEmpAvgOprRow In vWrkEmpAvgOperations Do
				vEmpAvgOprRow = vEmpAvgOperations.Add();
				FillPropertyValues(vEmpAvgOprRow, vWrkEmpAvgOprRow);
				vEmpAvgOprRow.Employee = vEmpRow.Employee;
			EndDo;
		EndIf;
	EndDo;
	// Assign employees to operations
	vFilterByOperation = Undefined;
	vFilterByRepairEndCleaning = False;
	vRunCount = 1;
	For Each vEmpRow In vEmployees Do
		vEmpRow.CheckOutCleaningCount = 0;
		vEmpRow.RegularCleaningCount = 0;
		vEmpRow.RepairEndCleaningCount = 0;
		vEmpRow.VacantRoomCleaningCount = 0;
		vEmpRow.OtherOperationsCount = 0;
		vEmpRow.Duration = 0;
		vEmpRow.TotalOperationsCount = 0;
	EndDo;
	vOperations.GroupBy("Room, Employee, EmployeeSortCode", "Duration");
	While True Do
		vNotAssignedOperationsAreNotFound = True;
		For Each vOprRow In vOperations Do
			If Not ValueIsFilled(vOprRow.Employee) Then
				vNotAssignedOperationsAreNotFound = False;
				For Each vEmpRow In vEmployees Do
					// Check employee room folder/section restrictions
					If vRunCount < 3 Or vObj.AssignEmployees2OperationsStrictlyByRoomSectionsOrFolders Then
						If ValueIsFilled(vEmpRow.RoomSection) And ValueIsFilled(vOprRow.Room) And 
							(vEmpRow.RoomSection.IsFolder And ValueIsFilled(vOprRow.Room.RoomSection) And Not vOprRow.Room.RoomSection.BelongsToItem(vEmpRow.RoomSection) Or 
							Not vEmpRow.RoomSection.IsFolder And vOprRow.Room.RoomSection <> vEmpRow.RoomSection) Then
							Continue;
						ElsIf ValueIsFilled(vEmpRow.Room) And ValueIsFilled(vOprRow.Room) And 
							Not vOprRow.Room.BelongsToItem(vEmpRow.Room) Then
							Continue;
						ElsIf ValueIsFilled(vEmpRow.RoomFolderFrom) And ValueIsFilled(vOprRow.Room) And 
							vOprRow.Room.SortCode < vEmpRow.RoomFolderFrom.SortCode Then
							Continue;
						ElsIf ValueIsFilled(vEmpRow.RoomFolderTo) And ValueIsFilled(vOprRow.Room) And 
							vOprRow.Room.SortCode > vEmpRow.RoomFolderTo.SortCode Then
							Continue;
						EndIf;
					EndIf;
					vOperationsByRoom = vOperationsAll.FindRows(New Structure("Room, Employee, EmployeeSortCode", vOprRow.Room, vOprRow.Employee, vOprRow.EmployeeSortCode));
					vNextEmployees = False;
					For Each vRowOperationByRoom In vOperationsByRoom Do  
						// Check maximum number of operations per employee
						If vRowOperationByRoom.CheckOutCleaningCount = 1 And vEmpRow.CheckOutCleaningCount >= vAvgQuantity.CheckOutCleaningCount Then
							vNextEmployees = True;
							Break;
						ElsIf vRowOperationByRoom.RegularCleaningCount = 1 And vEmpRow.RegularCleaningCount >= vAvgQuantity.RegularCleaningCount Then
							vNextEmployees = True;
							Break;
						ElsIf vRowOperationByRoom.RepairEndCleaningCount = 1 And vEmpRow.RepairEndCleaningCount >= vAvgQuantity.RepairEndCleaningCount Then
							vNextEmployees = True;
							Break;
						ElsIf vRowOperationByRoom.VacantRoomCleaningCount = 1 And vEmpRow.VacantRoomCleaningCount >= vAvgQuantity.VacantRoomCleaningCount Then
							vNextEmployees = True;
							Break;
						ElsIf vRowOperationByRoom.OtherOperationsCount = 1 And vEmpRow.OtherOperationsCount >= vAvgQuantity.OtherOperationsCount Then
							vNextEmployees = True;
							Break;
						EndIf;
					EndDo;
					If vNextEmployees Then
						Continue;
					EndIf;
					vNextOpr = False;
					// Try to check if current employee can do this operation
					vOprCouldBeAssigned = False;
					For Each vRowOperationByRoom In vOperationsByRoom Do
						vEmpAvgRows = vEmpAverages.FindRows(New Structure("Employee, Operation", vEmpRow.Employee, vRowOperationByRoom.Operation));
						vEmpOprRows = vEmpAvgOperations.FindRows(New Structure("Employee, RoomType, Operation", vEmpRow.Employee, vRowOperationByRoom.RoomType, vRowOperationByRoom.Operation));
						If Not vOprCouldBeAssigned Then
							If vEmpAvgRows.Count() > 0 And vEmpOprRows.Count() > 0 Then
								vEmpAvgRow = vEmpAvgRows.Get(0);
								vEmpOprRow = vEmpOprRows.Get(0);
								If vRowOperationByRoom.Operation = vObj.CheckOutCleaning Then
									If (vEmpAvgRow.CheckOutCleaningCount > 0 Or vRunCount > 16) And (vEmpOprRow.CheckOutCleaningCount > 0 Or 
										vRunCount > 2 Or (vInitAvgQuantity <> vAvgQuantity And vRunCount > 1)) Then
										vEmpAvgRow.CheckOutCleaningCount = vEmpAvgRow.CheckOutCleaningCount - 1;
										vEmpOprRow.CheckOutCleaningCount = vEmpOprRow.CheckOutCleaningCount - 1;
										vEmpRow.CheckOutCleaningCount = vEmpRow.CheckOutCleaningCount + 1;
										vOprCouldBeAssigned = True;
									EndIf;
								ElsIf vRowOperationByRoom.Operation = vObj.RegularCleaning Then
									If (vEmpAvgRow.RegularCleaningCount > 0 Or vRunCount > 16) And (vEmpOprRow.RegularCleaningCount > 0 Or
										vRunCount > 2 Or (vInitAvgQuantity <> vAvgQuantity And vRunCount > 1)) Then
										vEmpAvgRow.RegularCleaningCount = vEmpAvgRow.RegularCleaningCount - 1;
										vEmpOprRow.RegularCleaningCount = vEmpOprRow.RegularCleaningCount - 1;
										vEmpRow.RegularCleaningCount = vEmpRow.RegularCleaningCount + 1;
										vOprCouldBeAssigned = True;
									EndIf;
								ElsIf vRowOperationByRoom.Operation = vObj.RepairEndCleaning Then
									If (vEmpAvgRow.RepairEndCleaningCount > 0 Or vRunCount > 16) And (vEmpOprRow.RepairEndCleaningCount > 0 Or 
										vRunCount > 2 Or (vInitAvgQuantity <> vAvgQuantity And vRunCount > 1)) Then
										vEmpAvgRow.RepairEndCleaningCount = vEmpAvgRow.RepairEndCleaningCount - 1;
										vEmpOprRow.RepairEndCleaningCount = vEmpOprRow.RepairEndCleaningCount - 1;
										vEmpRow.RepairEndCleaningCount = vEmpRow.RepairEndCleaningCount + 1;
										vOprCouldBeAssigned = True;
									EndIf;
								ElsIf vRowOperationByRoom.Operation = vObj.VacantRoomCleaning Then
									If (vEmpAvgRow.VacantRoomCleaningCount > 0 Or vRunCount > 16) And (vEmpOprRow.VacantRoomCleaningCount > 0 Or 
										vRunCount > 2 Or (vInitAvgQuantity <> vAvgQuantity And vRunCount > 1)) Then
										vEmpAvgRow.VacantRoomCleaningCount = vEmpAvgRow.VacantRoomCleaningCount - 1;
										vEmpOprRow.VacantRoomCleaningCount = vEmpOprRow.VacantRoomCleaningCount - 1;
										vEmpRow.VacantRoomCleaningCount = vEmpRow.VacantRoomCleaningCount + 1;
										vOprCouldBeAssigned = True;
									EndIf;
								Else
									If (vEmpAvgRow.OtherOperationsCount > 0 Or vRunCount > 16) And (vEmpOprRow.OtherOperationsCount > 0 Or 
										vRunCount > 2 Or (vInitAvgQuantity <> vAvgQuantity And vRunCount > 1)) Then
										vEmpAvgRow.OtherOperationsCount = vEmpAvgRow.OtherOperationsCount - 1;
										vEmpOprRow.OtherOperationsCount = vEmpOprRow.OtherOperationsCount - 1;
										vEmpRow.OtherOperationsCount = vEmpRow.OtherOperationsCount + 1;
										vOprCouldBeAssigned = True;
									EndIf;
								EndIf;
								// Assign employee
								If vOprCouldBeAssigned Then
									vRowOperationByRoom.Employee = vEmpRow.Employee;
									vRowOperationByRoom.EmployeeSortCode = vEmpRow.EmployeeSortCode;
									// Get operation standards
									If ValueIsFilled(vRowOperationByRoom.Operation) Then
										vStds = Catalogs.Operations.GetOperationStandards(vRowOperationByRoom.Operation, vObj.Hotel, vRowOperationByRoom.RoomType, vRowOperationByRoom.Room, vRowOperationByRoom.Employee);
										If vStds.Count() > 0 then
											vStdsRow = vStds.Get(0);
											vRowOperationByRoom.Duration = vStdsRow.Duration;
											vRowOperationByRoom.RoomSpace = vStdsRow.RoomSpace;
											vRowOperationByRoom.Price = vStdsRow.Price;
										EndIf;
									EndIf;
									
									vEmpRow.Duration = vEmpRow.Duration + vRowOperationByRoom.Duration;
									vEmpRow.TotalOperationsCount = vEmpRow.TotalOperationsCount + 1;
									vNextOpr = True;
								EndIf;
							EndIf;
						Else
							If vEmpAvgRows.Count() > 0 And vEmpOprRows.Count() > 0 Then
								vEmpAvgRow = vEmpAvgRows.Get(0);
								vEmpOprRow = vEmpOprRows.Get(0);
								If vRowOperationByRoom.Operation = vObj.CheckOutCleaning Then
									vEmpAvgRow.CheckOutCleaningCount = vEmpAvgRow.CheckOutCleaningCount - 1;
									vEmpOprRow.CheckOutCleaningCount = vEmpOprRow.CheckOutCleaningCount - 1;
									vEmpRow.CheckOutCleaningCount = vEmpRow.CheckOutCleaningCount + 1;
								ElsIf vRowOperationByRoom.Operation = vObj.RegularCleaning Then
									vEmpAvgRow.RegularCleaningCount = vEmpAvgRow.RegularCleaningCount - 1;
									vEmpOprRow.RegularCleaningCount = vEmpOprRow.RegularCleaningCount - 1;
									vEmpRow.RegularCleaningCount = vEmpRow.RegularCleaningCount + 1;
								ElsIf vRowOperationByRoom.Operation = vObj.RepairEndCleaning Then
									vEmpAvgRow.RepairEndCleaningCount = vEmpAvgRow.RepairEndCleaningCount - 1;
									vEmpOprRow.RepairEndCleaningCount = vEmpOprRow.RepairEndCleaningCount - 1;
									vEmpRow.RepairEndCleaningCount = vEmpRow.RepairEndCleaningCount + 1;
								ElsIf vRowOperationByRoom.Operation = vObj.VacantRoomCleaning Then
									vEmpAvgRow.VacantRoomCleaningCount = vEmpAvgRow.VacantRoomCleaningCount - 1;
									vEmpOprRow.VacantRoomCleaningCount = vEmpOprRow.VacantRoomCleaningCount - 1;
									vEmpRow.VacantRoomCleaningCount = vEmpRow.VacantRoomCleaningCount + 1;
								Else
									vEmpAvgRow.OtherOperationsCount = vEmpAvgRow.OtherOperationsCount - 1;
									vEmpOprRow.OtherOperationsCount = vEmpOprRow.OtherOperationsCount - 1;
									vEmpRow.OtherOperationsCount = vEmpRow.OtherOperationsCount + 1;
								EndIf;
								// Assign employee
								vRowOperationByRoom.Employee = vEmpRow.Employee;
								vRowOperationByRoom.EmployeeSortCode = vEmpRow.EmployeeSortCode;
								// Get operation standards
								If ValueIsFilled(vRowOperationByRoom.Operation) Then
									vStds = Catalogs.Operations.GetOperationStandards(vRowOperationByRoom.Operation, vObj.Hotel, vRowOperationByRoom.RoomType, vRowOperationByRoom.Room, vRowOperationByRoom.Employee);
									If vStds.Count() > 0 then
										vStdsRow = vStds.Get(0);
										vRowOperationByRoom.Duration = vStdsRow.Duration;
										vRowOperationByRoom.RoomSpace = vStdsRow.RoomSpace;
										vRowOperationByRoom.Price = vStdsRow.Price;
									EndIf;
								EndIf;
								
								vEmpRow.Duration = vEmpRow.Duration + vRowOperationByRoom.Duration;
								vEmpRow.TotalOperationsCount = vEmpRow.TotalOperationsCount + 1;
								vNextOpr = True;
							EndIf;
						EndIf;
					EndDo;
					If vNextOpr Then
						vOprRow.Employee = vEmpRow.Employee;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		vRunCount = vRunCount + 1;
		If vInitAvgQuantity.CheckOutCleaningCount <> vAvgQuantity.CheckOutCleaningCount Or 
			vInitAvgQuantity.RegularCleaningCount <> vAvgQuantity.RegularCleaningCount Or 
			vInitAvgQuantity.RepairEndCleaningCount <> vAvgQuantity.RepairEndCleaningCount Or
			vInitAvgQuantity.VacantRoomCleaningCount <> vAvgQuantity.VacantRoomCleaningCount Or
			vInitAvgQuantity.OtherOperationsCount <> vAvgQuantity.OtherOperationsCount Or
			vObj.AssignEmployees2OperationsStrictlyByRoomSectionsOrFolders Then
			If vRunCount > 2 Then
				Break;
			EndIf;
		Else
			If vNotAssignedOperationsAreNotFound Then
				Break;
			EndIf;
		EndIf;
		If vRunCount > 32 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to assign employees to some room operations! Please do manual assignment';ru='Не удалось назначить сотрудников работам в некоторых номерах! Пожалуйста для этих номеров выполните назначение вручную';de='Die Mitarbeiter für Arbeiten in einigen Zimmern konnten nicht zugewiesen werden! Bitte führen Sie für diese Zimmer eine manuelle Zuweisung aus'"));
			WriteLogEvent(NStr("en='Operation schedule auto assignment failure';ru='Зацикливание алгоритма автоматического назначения сотрудников';de='Schleifendurchlauf des Algorithmus der automatischen Bestellung von Mitarbeitern'"), EventLogLevel.Error, vObj.Metadata(), vObj.Ref, NStr("en='Assignment failed in 32 cycles!';ru='На выполнение алгоритма потребовалось более 32 циклов!';de='Zum Ausführen des Algorithmus waren mehr als 32 Zyklen erforderlich!'"));
			Break;
		EndIf;
	EndDo;
	// Copy assignement to the initial operations value table
	For Each vAsnOpRow In vOperationsAll Do
		// Try to find appropriate initial row
		vOprRows = vObj.Operations.FindRows(New Structure("Room, UUID", vAsnOpRow.Room, vAsnOpRow.UUID));
		If vOprRows.Count() = 1 Then
			vOprRow = vOprRows[0];
			vOprRow.Employee = vAsnOpRow.Employee;
			vOprRow.EmployeeSortCode = vAsnOpRow.EmployeeSortCode;
			vOprRow.Duration = vAsnOpRow.Duration;
			vOprRow.RoomSpace = vAsnOpRow.RoomSpace;
			vOprRow.Price = vAsnOpRow.Price;
			
			vResultStr = New Structure("idOperation, nameEmployee, colorEmployee", TrimAll(vOprRow.UUID), GetEmployeePresentation(vAsnOpRow.Employee), "");
			
			If ValueIsFilled(vAsnOpRow.Employee) Then
				vEmployeeArr = Employees.FindRows(New Structure("Employee", vAsnOpRow.Employee));
				If vEmployeeArr.Count() > 0 Then
					vResultStr.colorEmployee = vEmployeeArr[0].Color;	
				Else
					vColor = vAsnOpRow.Employee.Color.Get();
					If TypeOf(vColor) = Type("Color") Then
						vColor = cmGetRGB4WebColor(vColor);
						vResultStr.colorEmployee = "rgb(" + vColor.R + ", " + vColor.G + ", " + vColor.B + ")";
					EndIf;
				EndIf;
			EndIf;
			vResult.Add(vResultStr);
		EndIf;
	EndDo;
	// Calculate totals
	CalculateTotalsAtServer(vObj);
	// Fill employees list
	SetEmployeesChoiceList(vObj);
	// Set object back to form attribute
	ValueToFormAttribute(vObj, "Object");
	Modified = True;
	Return vResult;
EndFunction // AssignEmployeesBalancedAtServer

// -----------------------------------------------------------------------------
&AtServer
Function ClearEmployeesAtServer(pRooms)
	vResult = New Array;
	vObj = FormAttributeToValue("Object");
	// Clear employees column in the operations
	For Each vOpRow In vObj.Operations Do
		If pRooms.FindByValue(TrimAll(vOpRow.Room.UUID())) = Undefined Then
			Continue;
		EndIf;
		If ValueIsFilled(vOpRow.Employee) Then
			vOpRow.Employee = Catalogs.Employees.EmptyRef();
			vOpRow.EmployeeSortCode = 0;
			
			vResultStr = New Structure("idOperation, nameEmployee, colorEmployee", TrimAll(vOpRow.UUID), GetEmployeePresentation(vOpRow.Employee), "");
			
			vResult.Add(vResultStr);
		Endif;
		// Get operation standards
		If ValueIsFilled(vOpRow.Operation) Then
			vStds = Catalogs.Operations.GetOperationStandards(vOpRow.Operation, vObj.Hotel, vOpRow.RoomType, vOpRow.Room, vOpRow.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vOpRow.Duration = vStdsRow.Duration;
				vOpRow.RoomSpace = vStdsRow.RoomSpace;
				vOpRow.Price = vStdsRow.Price;
			EndIf;
		EndIf;
	EndDo;
	// Calculate totals
	CalculateTotalsAtServer(vObj);
	// Fill employees list
	SetEmployeesChoiceList(vObj);
	// Set object back to form attribute
	ValueToFormAttribute(vObj, "Object");
	Return vResult;
EndFunction // ClearEmployeesAtServer

// -------------------------------------------------------------------------------------
&AtServer
Procedure CheckDirtyStatuses(pRoomStatuses, pHotel)
	pRoomStatuses.FillChecks(False);
	vHotelsList = GetHotelsList(pHotel);
	For Each vStatusItem In pRoomStatuses Do
		vCurStatus = vStatusItem.Value;
		If vCurStatus.OperationIsInProgress Or vCurStatus.InspectionIsInProgress Then
			vStatusItem.Check = True;
		Else
			For Each vHotelsListItem In vHotelsList Do
				vCurHotel = vHotelsListItem.Value;
				If ValueIsFilled(vCurHotel.RoomStatusDueOut) And vCurHotel.RoomStatusDueOut = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.RoomStatusAfterCheckOut) And vCurHotel.RoomStatusAfterCheckOut = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.RoomStatusAfterRoomBlock) And vCurHotel.RoomStatusAfterRoomBlock = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.RoomStatusAfterEarlyCheckIn) And vCurHotel.RoomStatusAfterEarlyCheckIn = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.OccupiedDirtyRoomStatus) And vCurHotel.OccupiedDirtyRoomStatus = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure // CheckDirtyStatuses

// -------------------------------------------------------------------------------------
&AtServer
Function GetHotelsList(pHotel)
	vHotelsList = New ValueList();
	If ValueIsFilled(pHotel) Then
		vHotelsList.Add(pHotel);
	Else
		vHotels = cmGetAllHotels();
		For Each vHotelsRow In vHotels Do
			vHotelsList.Add(vHotelsRow.Hotel);
		EndDo;
	EndIf;
	Return vHotelsList;
EndFunction // GetHotelsList

// -------------------------------------------------------------------------------------
&AtServer
Procedure CheckCleanStatuses(pRoomStatuses, pHotel)
	pRoomStatuses.FillChecks(False);
	vHotelsList = GetHotelsList(pHotel);
	For Each vStatusItem In pRoomStatuses Do
		vCurStatus = vStatusItem.Value;
		If vCurStatus.RoomIsVacantClear Then
			vStatusItem.Check = True;
		Else
			For Each vHotelsListItem In vHotelsList Do
				vCurHotel = vHotelsListItem.Value;
				If vCurHotel.VacantRoomStatus = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.ReservedRoomStatus) And vCurHotel.ReservedRoomStatus = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
				If ValueIsFilled(vCurHotel.RoomStatusInspection) And vCurHotel.RoomStatusInspection = vCurStatus Then
					vStatusItem.Check = True;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure // CheckCleanStatuses


#EndRegion

#Region HTML_API

// -----------------------------------------------------------------------------
&AtClient
Procedure HTMLDocumentComplete(pItem)
	HTMLOperationSchedule = GetHTMLDocument(Items.HTML.Document);
	
	// Draw operations 
	If Object.Operations.Count() > 0 Then
		vOperationsArr = DrawOperationsAtServer();
		DrawOperations(vOperationsArr);
	EndIf;
EndProcedure // HTMLDocumentComplete

// -----------------------------------------------------------------------------
&AtClient
Function GetIDByHTML(pID)
	vID = pID;
	Try
		vIDAR = StrSplit(pID, "_", False);
		vID = vIDAR[1];
	Except
	EndTry;
	Return vID;
EndFunction // GetIDByHTML

// -----------------------------------------------------------------------------
&AtClient
Procedure HTMLOnClick(pItem, pEventData, pStandardProcessing)
	pStandardProcessing = False;
	vElement = pEventData.Element;
	If vElement = Undefined Then
		vElement = pEventData.Document.activeElement;		
	EndIf;
	vHref = Right(pEventData.Href, StrLen(pEventData.Href) - StrFind(pEventData.Href, "/", SearchDirection.FromEnd));
	If ValueIsFilled(pEventData.Href) Then
		If vHref = "ChangeRoomStatus" Then
			vRoom = GetRoomRefByUUID(GetIDByHTML(vElement.id));
			If Not vRoom = Undefined Then
				OpenForm("Catalog.Rooms.ObjectForm", New Structure("Key", vRoom), ThisForm);
			EndIf;
		ElsIf vHref = "OpenParentDoc" Then
			vRoom = GetRoomRefByUUID(GetIDByHTML(vElement.id));
			If Not vRoom = Undefined Then
				vParentDoc = GetParentDocAtServer(vRoom);
				If ValueIsFilled(vParentDoc) Then
					If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
						OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", vParentDoc), ThisForm);
					ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
						OpenForm("Document.Reservation.ObjectForm", New Structure("Key", vParentDoc), ThisForm);
					EndIf;
				EndIf;
			EndIf;
		ElsIf vHref = "EditRemarksOperation" Then
			vRoom = GetRoomRefByUUID(GetIDByHTML(vElement.id));
			If Not vRoom = Undefined Then
				vRemarks = GetRemarksOperationByRoom(vRoom);
				OpenForm("CommonForm.tcInputText", New Structure("Text", vRemarks),,,,, New NotifyDescription("AfterShowInputText", ThisForm, vRoom), FormWindowOpeningMode.LockWholeInterface);
			EndIf;
		ElsIf vHref = "ShowTasksByRoom" Then
			vRoom = GetRoomRefByUUID(GetIDByHTML(vElement.id));
			If vRoom <> Undefined Then
				vListTask = Undefined;
				vCheckTask = CheckTask(vRoom, vListTask);
				If vCheckTask Then
					If vListTask.Count() > 0 Then
						If vListTask.Count() = 1 Then
							OpenForm("DataProcessor.Messages.Form", New Structure("SetParamObject", vListTask[0].Value), ThisForm, UUID);
						Else
							vNotifyDescription = New NotifyDescription("AfterChooseTask", ThisForm);
							vParams = New Structure("ValueList, MultipleChoice, Title", vListTask, False, NStr("en = 'Choose a task';de = 'Wählen Sie eine Aufgabe';ru = 'Выберите задачу'"));
							OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		ElsIf vHref = "AddRoomOperation" Then
			vRoom = GetRoomRefByUUID(GetIDByHTML(vElement.id));
			If vRoom <> Undefined Then
				// Ask user to choose operation from the list
				vNewOperationsList = New ValueList();
				For Each vItem In OperationsList Do
					If TypeOf(vItem.Value) = Type("CatalogRef.Operations") Then
						vNewOperationsList.Add(vItem.Value, vItem.Presentation, vItem.Check, vItem.Picture);	
					EndIf;
				EndDo;
				vNotifyDescription = New NotifyDescription("AfterAddOperation", ThisForm, New Structure("Room", vRoom));
				vParams = New Structure("ValueList, MultipleChoice, Title", vNewOperationsList, False, NStr("en = 'Choose a operation';de = 'Wählen Sie eine Operation aus';ru = 'Выберите работу'"));
				OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
			EndIf;
		ElsIf vHref = "ChangeRoomOperation" Then
			vParentElement = vElement.parentElement;
			While vParentElement <> Undefined And vParentElement.className <> "room-item-column" And vParentElement.className <> "room-item-column-hidden" Do
				vParentElement = vParentElement.parentElement;
			EndDo;
			If vParentElement <> Undefined Then
				vRoom = GetRoomRefByUUID(GetIDByHTML(vParentElement.id));
				If vRoom <> Undefined Then
					vNotifyDescription = New NotifyDescription("AfterOperationChoice", ThisForm, New Structure("Room, OperationUUID", vRoom, New UUID(GetIDByHTML(vElement.id))));
					vParams = New Structure("ValueList, MultipleChoice, Title", OperationsList, False, NStr("en = 'Choose a operation';de = 'Wählen Sie eine Operation aus';ru = 'Выберите работу'"));
					OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
				EndIf;
			EndIf;
		ElsIf vHref = "ChangeRoomEmployee" Then
			vParentElement = vElement.parentElement;
			While vParentElement <> Undefined And vParentElement.className <> "room-item-column" And vParentElement.className <> "room-item-column-hidden" Do
				vParentElement = vParentElement.parentElement;
			EndDo;
			If vParentElement <> Undefined Then
				vRoom = GetRoomRefByUUID(GetIDByHTML(vParentElement.id));
				If vRoom <> Undefined Then
					vNotifyDescription = New NotifyDescription("AfterEmployeeChoice", ThisForm, New Structure("Room, OperationUUID", vRoom, New UUID(GetIDByHTML(vElement.id))));
					vParams = New Structure("ValueList, MultipleChoice, Title", EmployeesList, False, NStr("en = 'Choose an employee';de = 'Wähle einen Mitarbeiter';ru = 'Выберите сотрудника'"));
					OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
				EndIf;
			EndIf;
		Else
			GotoURL(pEventData.Href);
		EndIf;
	EndIf;
EndProcedure // HTMLOnClick

// -----------------------------------------------------------------------------
&AtClient
Procedure DrawOperations(pOperationsArr)
	HTMLOperationSchedule.Clear();
	
	vObj = GetHTMLObj(pOperationsArr);
	HTMLOperationSchedule.addJSRoom(vObj);
	
	HTMLOperationSchedule.Search(SearchLine);
EndProcedure // DrawOperations

// -----------------------------------------------------------------------------
&AtClient
Procedure FillRoomEmployeeRmks(pText, pRoom)
	HTMLOperationSchedule.updateRemarks(TrimAll(pRoom), pText);
EndProcedure //  FillRoomEmployeeRmks

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterAddOperation(pUC, pExtraParams) Export
	If pUC <> Undefined Then
		vNewOperation = AddRoomOperationAtServer(pExtraParams.Room, pUC.Value);
		If vNewOperation <> Undefined Then
			HTMLOperationSchedule.addOperation(vNewOperation.idRoom, vNewOperation.idOperation, vNewOperation.imgOperation, vNewOperation.nameOperation, vNewOperation.colorOperation, vNewOperation.nameEmployee, vNewOperation.colorEmployee);
			HTMLOperationSchedule.updateColor(vNewOperation.idRoom, vNewOperation.isNew);
		EndIf;
	EndIf;
EndProcedure // AfterOperationChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterOperationChoice(pUC, pExtraParams) Export
	If pUC <> Undefined Then
		vOperation = UpdateRoomOperationAtServer(pExtraParams.Room, pExtraParams.OperationUUID, pUC.Value);
		If vOperation <> Undefined Then
			HTMLOperationSchedule.updateOperation(vOperation.idOperation, vOperation.imgOperation, vOperation.nameOperation, vOperation.colorOperation, vOperation.delOperation);
			HTMLOperationSchedule.updateColor(vOperation.idRoom, vOperation.isNew);
		EndIf;
	EndIf;
EndProcedure // AfterOperationChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterEmployeeChoice(pUC, pExtraParams) Export
	If pUC <> Undefined Then
		vOperationsArr = New Array();
		vOperationsArr.Add(New Structure("Room, Employee, UUID", pExtraParams.Room, pUC.Value, pExtraParams.OperationUUID));
		HTMLOperationSchedule.updateEmployee(GetHTMLObj(UpdateRoomEmployeeAtServer(vOperationsArr)));
	EndIf;
EndProcedure // AfterEmployeeChoice

// -----------------------------------------------------------------------------
&AtClient
Function GetVisibleRooms()
	vResult = New ValueList;
	vRooms = HTMLOperationSchedule.document.querySelectorAll("li.room-item-column");
	For Each vRoom In vRooms Do
		vResult.Add(GetIDByHTML(vRoom.id));
	EndDo;
	Return vResult;
EndFunction // GetVisibleRooms

// -----------------------------------------------------------------------------
&AtClient
Function GetHTMLDocument(pDocument)
	vDoc = pDocument.parentWindow;
	If vDoc = Undefined Then
		vDoc = pDocument.defaultView;
	EndIf;
	Return vDoc.OperationSchedule;
EndFunction // GetHTMLDocument

// ----------------------------------------------------------------------------
&AtClient
Function GetHTMLObj(pData)
	vObj = Undefined;
	If TypeOf(pData) = Type("Structure") Then
		vObj = HTMLOperationSchedule.createObj();
		For Each vItem In pData Do
			If TypeOf(vItem.Value) = Type("Structure") Or TypeOf(vItem.Value) = Type("Array") Then
				HTMLOperationSchedule.setToObj(vObj, vItem.Key, GetHTMLObj(vItem.Value));
			Else
				HTMLOperationSchedule.setToObj(vObj, vItem.Key, vItem.Value);
			EndIf;
		EndDo;
	ElsIf TypeOf(pData) = Type("Array") Then
		vObj = HTMLOperationSchedule.createArr();
		For Each vItem In pData Do
			If TypeOf(vItem) = Type("Structure") Or TypeOf(vItem) = Type("Array") Then
				HTMLOperationSchedule.setToArr(vObj, GetHTMLObj(vItem));
			Else
				HTMLOperationSchedule.setToArr(vObj, vItem);
			EndIf;
		EndDo;
	EndIf;
	Return vObj;
EndFunction // getHTMLObj

#EndRegion