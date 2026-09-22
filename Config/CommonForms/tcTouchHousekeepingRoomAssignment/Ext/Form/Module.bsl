
#Region FormEventHandlers

//-----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	WorkingHours = 12;
	Hotel = SessionParameters.CurrentHotel;
	Items.ChoiceHotel.Title = Hotel;
	
	Department = Hotel.HousekeepingDepartment;
	SetRoomsSections(SessionParameters.CurrentUser.RoomSection);
	RefreshTables();	
	
	// Set hotel color          
	Items.ChoiceHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	If Not IsInRole("RightsToChooseHotel") Then
		Items.ChoiceHotel.Enabled = False;
	EndIf;
	
	FreeWorkHead = NStr("en = 'Unassigned tasks'; ru = 'Неназначенные работы'; de = 'Nicht zugewiesene Aufgaben'");	
	EmployeesHead = NStr("en = 'Attendants in the shift'; ru = 'Сотрудники в смене'; de = 'Mitarbeiter in der Schicht'");
	CheckNotification();	
	CheckRoomSections();
	CheckRoomGroup();
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	#IF MobileClient THEN
		Items.WorkOn.Visible = False;
		Items.WorkOut.Visible = False;
	#ENDIF
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

//-----------------------------------------------------------------------------
&AtClient
Procedure EmployeeSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.CurrentData <> Undefined Then
		SetEmployee(pItem.CurrentData.Employee);
	EndIf;	
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(Item)
	HotelOnChangeAtServer();
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure NotAssignedOperationsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	WorkOn();
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure EmployeeOpertionsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	WorkOut();
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure ShowCompletedOperationsOnChange(pItem)
	RefreshTables();
	CurrentItem = Items.GroupTable;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

//-----------------------------------------------------------------------------
&AtClient
Procedure WorkOut(pCommand = Undefined)
	If ValueIsFilled(CurrentEmployee) Then 
		ItemCount = Items.EmployeeOperations.SelectedRows.Count();
		WorkOutAtServer();
		For Each vRow In Employee Do 
			If vRow.Employee = CurrentEmployee Then
				vRow.WorkNumber = vRow.WorkNumber -	ItemCount;
				vRow.Operations = EmployeeOperationsTypeText; 
			EndIf;
		EndDo;
	EndIf;
	CurrentItem = Items.GroupTable;
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure DeleteEmployee(pCommand)
	If EmployeeOperations.Count() > 0 Then
		ShowQueryBox(New NotifyDescription("DeleteEmployeeUserAnswer", ThisObject), NStr("en='Do you whant to clear all employee assignments?'; ru='Отменить все назначения сотруднику?'; de='Möchten Sie einen Mitarbeiter alle arbeiten Abbrechen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
	Else
		ShowQueryBox(New NotifyDescription("DeleteEmployeeUserAnswer", ThisObject), NStr("en='Do you whant to delete employee from the shift?'; ru='Удалить сотрудника из смены?'; de='Möchten Sie einen Mitarbeiter aus der Schicht entfernen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
	EndIf;
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure WorkOn(pCommand = Undefined)
	If ValueIsFilled(CurrentEmployee) Then 	
		ItemCount = Items.NotAssignedOperations.SelectedRows.Count();	
		WorkOnAtServer();		
		For Each vRow In Employee Do 
			If vRow.Employee = CurrentEmployee Then
				vRow.WorkNumber = vRow.WorkNumber +	ItemCount;
				vRow.Operations = EmployeeOperationsTypeText;
			EndIf;
		EndDo;
	EndIf;
	CurrentItem = Items.GroupTable;
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure ClearRoomGroup(pCommand)
	SetRoomsGroup(Undefined);
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure ClearRoomSections(pCommand)
	SetRoomsSections(Undefined);
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure ChoiceHotel(pCommand)
	OpenForm("Catalog.Hotels.Form.tcTouchChoiceForm", , ThisObject);
	CurrentItem = Items.GroupTable;
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure ChoiceRoomGroup(pCommand)
	OpenForm("Catalog.Rooms.Form.tcTouchChoiceForm", New Structure("Filter, ChoiceFoldersAndItems", New Structure("IsFolder, Owner", True, Hotel), FoldersAndItemsUse.Folders), ThisObject);
	CurrentItem = Items.GroupTable;	
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure ChoiceRoomSections(pCommand)
	OpenForm("Catalog.RoomSections.Form.tcTouchChoiceForm",New Structure("Filter, ChoiceFoldersAndItems", New Structure("IsFolder, Hotel", False, Hotel), FoldersAndItemsUse.Items), ThisObject);
	CurrentItem = Items.GroupTable;	
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	If ValueIsFilled(CurrentEmployee) Then
		OpenForm("CommonForm.tcPrintEmployeeRoomAssignment", New Structure("Hotel, Room, RoomSection, HousekeepingDepartment, WorkingHours, Employee, EmployeeIndex", Hotel, , , , WorkingHours, CurrentEmployee));
		CurrentItem = Items.GroupTable;	
	EndIf;	
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure PrintAll(pCommand)
	If Employee.Total("WorkNumber") > 0 Then
		OpenForm("CommonForm.tcPrintEmployeeRoomAssignment", New Structure("Hotel, Room, RoomSection, HousekeepingDepartment, WorkingHours, Employee, EmployeeIndex", Hotel, , , , WorkingHours, Undefined, 0));	
		CurrentItem = Items.GroupTable;	
	EndIf;
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure AddEmployee(pCommand)
	OpenForm("Catalog.Employees.Form.tcTouchChoiceForm", New Structure("Filter", New Structure("Department, IsFolder", Department, False)), ThisObject);
	CurrentItem = Items.GroupTable;
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure SendNotify(pCommand)
	SendNotifyAtServer();
EndProcedure	

//-----------------------------------------------------------------------------
&AtClient
Procedure RefreshTable(pCommand)
	RefreshTables();
	CurrentItem = Items.GroupTable;
EndProcedure

#EndRegion

#Region Private

//-----------------------------------------------------------------------------
&AtServer
Procedure RefreshTables(pEmployee = True, pEmployeeOperations = True, pFreeOperations = True)
	If pEmployee Then
		FillEmployeeTable();
	EndIf;	
	If pEmployeeOperations Then		
		FillEmployeeOperations(CurrentEmployee);
	EndIf;	
	If pFreeOperations Then	
		FillNotAssignedOperations();
	EndIf;	
	CheckNotification();
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure SetEmployee(pEmployee)
	If ValueIsFilled(pEmployee) Then
		CurrentEmployee = pEmployee;
		FillEmployeeOperations(CurrentEmployee);
		Items.DeleteEmployee.Enabled = True;
		Items.Print.Enabled = True;
	Else
		CurrentEmployee = Undefined;
		FillEmployeeOperations(CurrentEmployee);
		Items.DeleteEmployee.Enabled = False;
		Items.Print.Enabled = False;
	EndIf;	
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure FillEmployeeTable() 
	SetEmployee(Undefined);
	EmployeeOperationsTypeText = "";
	Employee.Clear();	
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ShiftOperations.Employee AS Employee,
	|	ShiftOperations.Operation AS Operation,
	|	ShiftOperations.Room AS Room,
	|	ShiftOperations.RoomType AS RoomType,
	|	ShiftOperations.Hotel AS Hotel,
	|	SUM(CASE
	|			WHEN ShiftOperations.Quantity = 0
	|				THEN 1
	|			ELSE ShiftOperations.Quantity
	|		END) AS OperationsCount
	|INTO ShiftOperations
	|FROM
	|	Document.EmployeeOperation AS ShiftOperations
	|		INNER JOIN InformationRegister.HousekeepingShift AS HousekeepingShift
	|		ON ShiftOperations.Employee = HousekeepingShift.Employee
	|			AND ShiftOperations.Hotel = HousekeepingShift.Hotel
	|WHERE
	|	ShiftOperations.OperationEndConfirmedTime = &qEmptyDate
	|	AND NOT ShiftOperations.DeletionMark
	|	AND ShiftOperations.Posted
	|	AND (ShiftOperations.OperationEndTime = &qEmptyDate
	|			OR &qShowCompleted
	|				AND ShiftOperations.OperationEndTime <> &qEmptyDate
	|				AND ShiftOperations.OperationEndTime <= &qWorkingPeriodTo
	|				AND ShiftOperations.OperationEndTime >= &qWorkingPeriodFrom)
	|	AND ShiftOperations.Hotel = &qHotel
	|
	|GROUP BY
	|	ShiftOperations.Employee,
	|	ShiftOperations.Operation,
	|	ShiftOperations.Room,
	|	ShiftOperations.RoomType,
	|	ShiftOperations.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShiftOperations.Operation AS Operation,
	|	ShiftOperations.Employee AS Employee,
	|	ShiftOperations.Hotel AS Hotel,
	|	ShiftOperations.RoomType AS RoomType,
	|	ShiftOperations.Room AS Room,
	|	ShiftOperations.OperationsCount AS OperationsCount,
	|	CASE
	|		WHEN ShiftOperations.Employee = OperationStandards.Employee
	|				AND OperationStandards.Employee <> VALUE(Catalog.Employees.EmptyRef)
	|			THEN CASE
	|					WHEN ShiftOperations.Room = OperationStandards.Room
	|							AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|						THEN 250
	|					WHEN ShiftOperations.Room.Parent = OperationStandards.Room
	|							AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
	|							AND ShiftOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|						THEN 240
	|					WHEN ShiftOperations.RoomType = OperationStandards.RoomType
	|							AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|						THEN 230
	|					WHEN ShiftOperations.RoomType.Parent = OperationStandards.RoomType
	|							AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
	|							AND ShiftOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|						THEN 220
	|					ELSE 210
	|				END
	|		WHEN ShiftOperations.Employee.Parent = OperationStandards.Employee
	|				AND ISNULL(OperationStandards.Employee.IsFolder, FALSE)
	|				AND ShiftOperations.Employee <> VALUE(Catalog.Employees.EmptyRef)
	|			THEN CASE
	|					WHEN ShiftOperations.Room = OperationStandards.Room
	|							AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|						THEN 150
	|					WHEN ShiftOperations.Room.Parent = OperationStandards.Room
	|							AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
	|							AND ShiftOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|						THEN 140
	|					WHEN ShiftOperations.RoomType = OperationStandards.RoomType
	|							AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|						THEN 130
	|					WHEN ShiftOperations.RoomType.Parent = OperationStandards.RoomType
	|							AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
	|							AND ShiftOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|						THEN 120
	|					ELSE 110
	|				END
	|		ELSE CASE
	|				WHEN ShiftOperations.Room = OperationStandards.Room
	|						AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|					THEN 50
	|				WHEN ShiftOperations.Room.Parent = OperationStandards.Room
	|						AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
	|						AND ShiftOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|					THEN 40
	|				WHEN ShiftOperations.RoomType = OperationStandards.RoomType
	|						AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|					THEN 30
	|				WHEN ShiftOperations.RoomType.Parent = OperationStandards.RoomType
	|						AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
	|						AND ShiftOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|					THEN 20
	|				ELSE 10
	|			END
	|	END AS Weight,
	|	ISNULL(OperationStandards.Duration, 0) AS OperationsDuration,
	|	ISNULL(OperationStandards.RoomSpace, 0) AS RoomSpace,
	|	ISNULL(OperationStandards.Price, 0) AS Price
	|INTO ShiftOperationsWithAllStandards
	|FROM
	|	ShiftOperations AS ShiftOperations
	|		LEFT JOIN InformationRegister.OperationStandards AS OperationStandards
	|		ON ShiftOperations.Operation = OperationStandards.Operation
	|			AND (OperationStandards.Operation <> VALUE(Catalog.Operations.EmptyRef))
	|			AND (ShiftOperations.Employee = OperationStandards.Employee
	|					AND OperationStandards.Employee <> VALUE(Catalog.Employees.EmptyRef)
	|				OR ShiftOperations.Employee.Parent = OperationStandards.Employee
	|					AND ISNULL(OperationStandards.Employee.IsFolder, FALSE)
	|					AND ShiftOperations.Employee <> VALUE(Catalog.Employees.EmptyRef)
	|				OR OperationStandards.Employee = VALUE(Catalog.Employees.EmptyRef))
	|			AND (ShiftOperations.Room = OperationStandards.Room
	|					AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|				OR ShiftOperations.Room.Parent = OperationStandards.Room
	|					AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
	|					AND ShiftOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|				OR OperationStandards.Room = VALUE(Catalog.Rooms.EmptyRef))
	|			AND (ShiftOperations.RoomType = OperationStandards.RoomType
	|					AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR ShiftOperations.RoomType.Parent = OperationStandards.RoomType
	|					AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
	|					AND ShiftOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR OperationStandards.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (OperationStandards.Duration <> 0
	|				OR OperationStandards.Price <> 0
	|				OR OperationStandards.RoomSpace <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WeightedShiftOperations.Operation AS Operation,
	|	WeightedShiftOperations.Employee AS Employee,
	|	WeightedShiftOperations.Hotel AS Hotel,
	|	WeightedShiftOperations.RoomType AS RoomType,
	|	WeightedShiftOperations.Room AS Room,
	|	MAX(WeightedShiftOperations.Weight) AS MaxWeight
	|INTO WeightedShiftOperations
	|FROM
	|	ShiftOperationsWithAllStandards AS WeightedShiftOperations
	|
	|GROUP BY
	|	WeightedShiftOperations.Operation,
	|	WeightedShiftOperations.Employee,
	|	WeightedShiftOperations.Hotel,
	|	WeightedShiftOperations.RoomType,
	|	WeightedShiftOperations.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShiftOperationsWithStandards.Operation AS Operation,
	|	ShiftOperationsWithStandards.Employee AS Employee,
	|	ShiftOperationsWithStandards.Hotel AS Hotel,
	|	ShiftOperationsWithStandards.RoomType AS RoomType,
	|	ShiftOperationsWithStandards.Room AS Room,
	|	ShiftOperationsWithStandards.OperationsCount AS OperationsCount,
	|	ShiftOperationsWithStandards.OperationsCount * ShiftOperationsWithStandards.OperationsDuration AS OperationsDuration,
	|	ShiftOperationsWithStandards.OperationsCount * ShiftOperationsWithStandards.RoomSpace AS RoomSpace,
	|	ShiftOperationsWithStandards.OperationsCount * ShiftOperationsWithStandards.Price AS Price
	|INTO ShiftOperationsWithStandards
	|FROM
	|	ShiftOperationsWithAllStandards AS ShiftOperationsWithStandards
	|		INNER JOIN WeightedShiftOperations AS WeightedShiftOperations
	|		ON ShiftOperationsWithStandards.Operation = WeightedShiftOperations.Operation
	|			AND ShiftOperationsWithStandards.Employee = WeightedShiftOperations.Employee
	|			AND ShiftOperationsWithStandards.Hotel = WeightedShiftOperations.Hotel
	|			AND ShiftOperationsWithStandards.RoomType = WeightedShiftOperations.RoomType
	|			AND ShiftOperationsWithStandards.Room = WeightedShiftOperations.Room
	|			AND ShiftOperationsWithStandards.Weight = WeightedShiftOperations.MaxWeight
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShiftOperationsWithStandards.Employee AS Employee,
	|	ShiftOperationsWithStandards.Operation AS Operation,
	|	ShiftOperationsWithStandards.Operation.Code AS OperationCode,
	|	SUM(ShiftOperationsWithStandards.RoomSpace) AS RoomSpace,
	|	SUM(ShiftOperationsWithStandards.Price) AS Price,
	|	SUM(ShiftOperationsWithStandards.OperationsCount) AS OperationsCount,
	|	SUM(ShiftOperationsWithStandards.OperationsDuration) AS OperationsDuration
	|FROM
	|	ShiftOperationsWithStandards AS ShiftOperationsWithStandards
	|
	|GROUP BY
	|	ShiftOperationsWithStandards.Employee,
	|	ShiftOperationsWithStandards.Operation,
	|	ShiftOperationsWithStandards.Operation.Code
	|
	|ORDER BY
	|	ShiftOperationsWithStandards.Employee.SortCode,
	|	ShiftOperationsWithStandards.Employee.Description,
	|	ShiftOperationsWithStandards.Operation.SortCode";
	vQuery.SetParameter("qEmptyDate", Date(1, 1, 1));
	vQuery.SetParameter("qHotel", Hotel);	
	vQuery.SetParameter("qShowCompleted", ShowCompletedOperations);
	vQuery.SetParameter("qWorkingPeriodFrom", CurrentSessionDate() - WorkingHours*3600);
	vQuery.SetParameter("qWorkingPeriodTo", CurrentSessionDate() + WorkingHours*3600);
	
	vQueryResult = vQuery.Execute();	
	vSelectionDetailRecords = vQueryResult.Select();
		
	vFirst = True;	
	vEmp = Undefined;
	vEmpRow = Undefined;
	vEmpOperations = "";
	vEmpOperationsCount = 0;
	vEmpOperationsDuration = 0;
	vEmpRoomSpace = 0;
	vEmpPrice = 0;
	While vSelectionDetailRecords.Next() Do
		If vEmp <> vSelectionDetailRecords.Employee Then
			If vEmpRow <> Undefined Then
				vEmpRow.WorkNumber = vEmpOperationsCount;
				If Not IsBlankString(vEmpOperations) Then
					vEmpRow.Operations = vEmpOperations + NStr("en='T. '; ru='Вр. '; de='Zt. '") + 
				                           (Int(vEmpOperationsDuration/60)) + NStr("en='h '; ru='ч '; de='h '") + 
				                           (vEmpOperationsDuration - Int(vEmpOperationsDuration/60)*60) + NStr("en='m'; ru='м'; de='m'");
				If vEmpRoomSpace > 0 Then
					If ValueIsFilled(vEmpRow.Operations) Then
						vEmpRow.Operations = vEmpRow.Operations + ", "	
					EndIf;
					vEmpRow.Operations = vEmpRow.Operations + NStr("en = 'Sq. '; de = 'Sq. '; ru = 'Пл. '") + vEmpRoomSpace;
				EndIf;
				If vEmpPrice > 0 Then
					If ValueIsFilled(vEmpRow.Operations) Then
						vEmpRow.Operations = vEmpRow.Operations + ", "	
					EndIf;
		            vEmpRow.Operations = vEmpRow.Operations + NStr("en = 'Sum. '; de = 'Sum. '; ru = 'Ст. '") + cmFormatSum(vEmpPrice, Hotel.BaseCurrency);
				EndIf;
				EndIf;
				vEmpOperations = "";
				vEmpOperationsCount = 0;
				vEmpOperationsDuration = 0;
				vEmpRoomSpace = 0;
				vEmpPrice = 0;
			EndIf;
			
			vEmp               = vSelectionDetailRecords.Employee;
			vEmpRow            = Employee.Add();
			vEmpRow.Employee   = vEmp;
			
			If ValueIsFilled(vSelectionDetailRecords.Operation) Then
				vEmpOperationsCount = vSelectionDetailRecords.OperationsCount;
				vEmpOperations = TrimAll(vSelectionDetailRecords.OperationCode) + " = " + vSelectionDetailRecords.OperationsCount + "; ";
				vEmpOperationsDuration = vSelectionDetailRecords.OperationsDuration;
				vEmpRoomSpace = vEmpRoomSpace + vSelectionDetailRecords.RoomSpace; 
				vEmpPrice = vEmpPrice + vSelectionDetailRecords.Price;
			EndIf;
		Else
			If ValueIsFilled(vSelectionDetailRecords.Operation) Then
				vEmpOperationsCount = vEmpOperationsCount + vSelectionDetailRecords.OperationsCount;
				vEmpOperations = vEmpOperations + TrimAll(vSelectionDetailRecords.OperationCode) + " = " + vSelectionDetailRecords.OperationsCount + "; ";
				vEmpOperationsDuration = vEmpOperationsDuration + vSelectionDetailRecords.OperationsDuration;
				vEmpRoomSpace = vEmpRoomSpace + vSelectionDetailRecords.RoomSpace;
				vEmpPrice = vEmpPrice + vSelectionDetailRecords.Price;
			EndIf;
		EndIf;	
		
		If vFirst Then			
			CurrentEmployee = vEmp; 
			vFirst          = False;
		EndIf;	
	EndDo;
	If vEmpRow <> Undefined Then
		vEmpRow.WorkNumber = vEmpOperationsCount;
		If Not IsBlankString(vEmpOperations) Then
			vEmpRow.Operations = vEmpOperations + NStr("en='T. '; ru='Вр. '; de='Zt. '") + 
		                           (Int(vEmpOperationsDuration/60)) + NStr("en='h '; ru='ч '; de='h '") + 
		                           (vEmpOperationsDuration - Int(vEmpOperationsDuration/60)*60) + NStr("en='m'; ru='м'; de='m'");
			If vEmpRoomSpace > 0 Then
				If ValueIsFilled(vEmpRow.Operations) Then
					vEmpRow.Operations = vEmpRow.Operations + ", "	
				EndIf;
				vEmpRow.Operations = vEmpRow.Operations + NStr("en = 'Sq. '; de = 'Sq. '; ru = 'Пл. '") + vEmpRoomSpace;
			EndIf;
			If vEmpPrice > 0 Then
				If ValueIsFilled(vEmpRow.Operations) Then
					vEmpRow.Operations = vEmpRow.Operations + ", "	
				EndIf;
	            vEmpRow.Operations = vEmpRow.Operations + NStr("en = 'Sum. '; de = 'Sum. '; ru = 'Ст. '") + cmFormatSum(vEmpPrice, Hotel.BaseCurrency);
			EndIf;						   
		EndIf;
		vEmpOperations = "";
		vEmpOperationsCount = 0;
		vEmpOperationsDuration = 0;
		vEmpRoomSpace = 0;
		vEmpPrice = 0;
	EndIf;
	
	EmployeesHead2 = NStr("en='Count: '; ru='Всего: '; de='Anzahl: '") + Employee.Count();
		
	If ValueIsFilled(CurrentEmployee) Then
		SetEmployee(CurrentEmployee);
	EndIf;
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure FillEmployeeOperations(pEmployee)
	EmployeeOperationsTypeText = "";
	vEmployeeDuration = 0;
	vTotalRoomSpace = 0;
	vTotalPrice = 0;
	
	EmployeeOperations.Clear();	
	If ValueIsFilled(pEmployee) Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT DISTINCT
		|	EmployeeOperations.Ref AS Ref,
		|	EmployeeOperations.Hotel AS Hotel,
		|	EmployeeOperations.Employee AS Employee,
		|	EmployeeOperations.Room AS Room,
		|	EmployeeOperations.RoomType AS RoomType,
		|	EmployeeOperations.OperationIntentTime AS OperationIntentTime,
		|	EmployeeOperations.EmployeeAssignmentTime AS EmployeeAssignmentTime,
		|	EmployeeOperations.OperationStartTime AS OperationStartTime,
		|	EmployeeOperations.OperationEndTime AS OperationEndTime,
		|	EmployeeOperations.Operation AS Operation,
		|	EmployeeOperations.Operation.Code AS OperationCode,
		|	CASE
		|		WHEN EmployeeOperations.Quantity = 0
		|			THEN 1
		|		ELSE EmployeeOperations.Quantity
		|	END AS OperationsCount,
		|	CASE
		|		WHEN NOT Reservations.Ref IS NULL
		|			THEN 41
		|		ELSE 0
		|	END AS CheckInWaitingIcon,
		|	CASE
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.None)
		|			THEN 5
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Reserved)
		|			THEN 6
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Occupied)
		|			THEN 2
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.OccupiedDirty)
		|			THEN 7
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Repair)
		|			THEN 8
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Luggage)
		|			THEN 9
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Malfunction)
		|			THEN 10
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Waiting)
		|			THEN 1
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.TidyingUp)
		|			THEN 0
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.CheckOut)
		|			THEN 3
		|		WHEN EmployeeOperations.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Vacant)
		|			THEN 4
		|		ELSE 5
		|	END AS RoomStatusIcon
		|INTO EmployeeOperations
		|FROM
		|	Document.EmployeeOperation AS EmployeeOperations
		|		LEFT JOIN Document.Reservation AS Reservations
		|		ON (Reservations.Posted)
		|			AND (Reservations.ReservationStatus.IsActive)
		|			AND (Reservations.CheckInDate >= &qPeriodFrom)
		|			AND (Reservations.CheckInDate <= &qPeriodTo)
		|			AND (Reservations.Room = EmployeeOperations.Room)
		|WHERE
		|	EmployeeOperations.OperationEndConfirmedTime = &qEmptyDate
		|	AND NOT EmployeeOperations.DeletionMark
		|	AND EmployeeOperations.Posted
		|	AND (EmployeeOperations.OperationEndTime = &qEmptyDate
		|			OR &qShowCompleted
		|				AND EmployeeOperations.OperationEndTime <> &qEmptyDate
		|				AND EmployeeOperations.OperationEndTime <= &qWorkingPeriodTo
		|				AND EmployeeOperations.OperationEndTime >= &qWorkingPeriodFrom)
		|	AND EmployeeOperations.Employee = &qEmployee
		|	AND EmployeeOperations.Hotel = &qHotel
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	EmployeeOperations.Ref AS Ref,
		|	EmployeeOperations.Room AS Room,
		|	EmployeeOperations.RoomType AS RoomType,
		|	EmployeeOperations.OperationIntentTime AS OperationIntentTime,
		|	EmployeeOperations.EmployeeAssignmentTime AS EmployeeAssignmentTime,
		|	EmployeeOperations.OperationStartTime AS OperationStartTime,
		|	EmployeeOperations.OperationEndTime AS OperationEndTime,
		|	EmployeeOperations.Operation AS Operation,
		|	EmployeeOperations.OperationCode AS OperationCode,
		|	EmployeeOperations.OperationsCount AS OperationsCount,
		|	EmployeeOperations.CheckInWaitingIcon AS CheckInWaitingIcon,
		|	EmployeeOperations.RoomStatusIcon AS RoomStatusIcon,
		|	CASE
		|		WHEN EmployeeOperations.Employee = OperationStandards.Employee
		|				AND OperationStandards.Employee <> VALUE(Catalog.Employees.EmptyRef)
		|			THEN CASE
		|					WHEN EmployeeOperations.Room = OperationStandards.Room
		|							AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
		|						THEN 250
		|					WHEN EmployeeOperations.Room.Parent = OperationStandards.Room
		|							AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
		|							AND EmployeeOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
		|						THEN 240
		|					WHEN EmployeeOperations.RoomType = OperationStandards.RoomType
		|							AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
		|						THEN 230
		|					WHEN EmployeeOperations.RoomType.Parent = OperationStandards.RoomType
		|							AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
		|							AND EmployeeOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
		|						THEN 220
		|					ELSE 210
		|				END
		|		WHEN EmployeeOperations.Employee.Parent = OperationStandards.Employee
		|				AND ISNULL(OperationStandards.Employee.IsFolder, FALSE)
		|				AND EmployeeOperations.Employee <> VALUE(Catalog.Employees.EmptyRef)
		|			THEN CASE
		|					WHEN EmployeeOperations.Room = OperationStandards.Room
		|							AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
		|						THEN 150
		|					WHEN EmployeeOperations.Room.Parent = OperationStandards.Room
		|							AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
		|							AND EmployeeOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
		|						THEN 140
		|					WHEN EmployeeOperations.RoomType = OperationStandards.RoomType
		|							AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
		|						THEN 130
		|					WHEN EmployeeOperations.RoomType.Parent = OperationStandards.RoomType
		|							AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
		|							AND EmployeeOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
		|						THEN 120
		|					ELSE 110
		|				END
		|		ELSE CASE
		|				WHEN EmployeeOperations.Room = OperationStandards.Room
		|						AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
		|					THEN 50
		|				WHEN EmployeeOperations.Room.Parent = OperationStandards.Room
		|						AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
		|						AND EmployeeOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
		|					THEN 40
		|				WHEN EmployeeOperations.RoomType = OperationStandards.RoomType
		|						AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
		|					THEN 30
		|				WHEN EmployeeOperations.RoomType.Parent = OperationStandards.RoomType
		|						AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
		|						AND EmployeeOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
		|					THEN 20
		|				ELSE 10
		|			END
		|	END AS Weight,
		|	ISNULL(OperationStandards.Duration, 0) AS OperationDuration,
		|	ISNULL(OperationStandards.RoomSpace, 0) AS RoomSpace,
		|	ISNULL(OperationStandards.Price, 0) AS Price
		|INTO EmployeeOperationsWithAllStandards
		|FROM
		|	EmployeeOperations AS EmployeeOperations
		|		LEFT JOIN InformationRegister.OperationStandards AS OperationStandards
		|		ON EmployeeOperations.Operation = OperationStandards.Operation
		|			AND (EmployeeOperations.Operation <> VALUE(Catalog.Operations.EmptyRef))
		|			AND (EmployeeOperations.Employee = OperationStandards.Employee
		|					AND OperationStandards.Employee <> VALUE(Catalog.Employees.EmptyRef)
		|				OR EmployeeOperations.Employee.Parent = OperationStandards.Employee
		|					AND ISNULL(OperationStandards.Employee.IsFolder, FALSE)
		|					AND EmployeeOperations.Employee <> VALUE(Catalog.Employees.EmptyRef)
		|				OR OperationStandards.Employee = VALUE(Catalog.Employees.EmptyRef))
		|			AND (EmployeeOperations.Room = OperationStandards.Room
		|					AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
		|				OR EmployeeOperations.Room.Parent = OperationStandards.Room
		|					AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
		|					AND EmployeeOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
		|				OR OperationStandards.Room = VALUE(Catalog.Rooms.EmptyRef))
		|			AND (EmployeeOperations.RoomType = OperationStandards.RoomType
		|					AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
		|				OR EmployeeOperations.RoomType.Parent = OperationStandards.RoomType
		|					AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
		|					AND EmployeeOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
		|				OR OperationStandards.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
		|			AND (OperationStandards.Duration <> 0
		|				OR OperationStandards.Price <> 0
		|				OR OperationStandards.RoomSpace <> 0)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	WeightedEmployeeOperations.Ref AS Ref,
		|	MAX(WeightedEmployeeOperations.Weight) AS MaxWeight
		|INTO WeightedEmployeeOperations
		|FROM
		|	EmployeeOperationsWithAllStandards AS WeightedEmployeeOperations
		|
		|GROUP BY
		|	WeightedEmployeeOperations.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	EmployeeOperations.Ref AS Ref,
		|	EmployeeOperations.Room AS Room,
		|	EmployeeOperations.RoomType AS RoomType,
		|	EmployeeOperations.OperationIntentTime AS OperationIntentTime,
		|	EmployeeOperations.EmployeeAssignmentTime AS EmployeeAssignmentTime,
		|	EmployeeOperations.OperationStartTime AS OperationStartTime,
		|	EmployeeOperations.OperationEndTime AS OperationEndTime,
		|	EmployeeOperations.Operation AS Operation,
		|	EmployeeOperations.OperationCode AS OperationCode,
		|	EmployeeOperations.OperationsCount AS OperationsCount,
		|	EmployeeOperations.CheckInWaitingIcon AS CheckInWaitingIcon,
		|	EmployeeOperations.RoomStatusIcon AS RoomStatusIcon,
		|	MAX(EmployeeOperations.OperationDuration) AS OperationDuration,
		|	MAX(EmployeeOperations.RoomSpace) AS RoomSpace,
		|	MAX(EmployeeOperations.Price) AS Price
		|FROM
		|	EmployeeOperationsWithAllStandards AS EmployeeOperations
		|		INNER JOIN WeightedEmployeeOperations AS WeightedEmployeeOperations
		|		ON EmployeeOperations.Ref = WeightedEmployeeOperations.Ref
		|			AND EmployeeOperations.Weight = WeightedEmployeeOperations.MaxWeight
		|
		|GROUP BY
		|	EmployeeOperations.Ref,
		|	EmployeeOperations.Room,
		|	EmployeeOperations.RoomType,
		|	EmployeeOperations.OperationIntentTime,
		|	EmployeeOperations.EmployeeAssignmentTime,
		|	EmployeeOperations.OperationStartTime,
		|	EmployeeOperations.OperationEndTime,
		|	EmployeeOperations.Operation,
		|	EmployeeOperations.OperationCode,
		|	EmployeeOperations.OperationsCount,
		|	EmployeeOperations.CheckInWaitingIcon,
		|	EmployeeOperations.RoomStatusIcon
		|
		|ORDER BY
		|	EmployeeOperations.Room.SortCode";		
		vQuery.SetParameter("qEmptyDate", Date(1, 1, 1));
		vQuery.SetParameter("qPeriodFrom", BegOfDay(CurrentSessionDate()));
		vQuery.SetParameter("qPeriodTo", EndOfDay(CurrentSessionDate()));
		vQuery.SetParameter("qEmployee", pEmployee);
		vQuery.SetParameter("qHotel", Hotel);
		vQuery.SetParameter("qShowCompleted", ShowCompletedOperations);
		vQuery.SetParameter("qWorkingPeriodFrom", CurrentSessionDate() - WorkingHours*3600);
		vQuery.SetParameter("qWorkingPeriodTo", CurrentSessionDate() + WorkingHours*3600);
		
		vQueryResult = vQuery.Execute();
		
		vSelectionDetailRecords = vQueryResult.Select();
		While vSelectionDetailRecords.Next() Do
			vNewRow = EmployeeOperations.Add();
			vNewRow.Doc = vSelectionDetailRecords.Ref;
			vNewRow.Room = vSelectionDetailRecords.Room;
			vNewRow.RoomType = vSelectionDetailRecords.RoomType;
			vNewRow.OperationIntentTime = vSelectionDetailRecords.OperationIntentTime;
			vNewRow.EmployeeAssignmentTime = vSelectionDetailRecords.EmployeeAssignmentTime;
			vNewRow.OperationStartTime = vSelectionDetailRecords.OperationStartTime;
			vNewRow.OperationEndTime = vSelectionDetailRecords.OperationEndTime;
			vNewRow.Operation = vSelectionDetailRecords.Operation;
			vNewRow.OperationCode = vSelectionDetailRecords.OperationCode;		
			vNewRow.OperationsCount = vSelectionDetailRecords.OperationsCount;
			vNewRow.CheckInWaitingIcon = vSelectionDetailRecords.CheckInWaitingIcon;
			vNewRow.RoomStatusIcon = vSelectionDetailRecords.RoomStatusIcon;
			vNewRow.OperationDuration = vSelectionDetailRecords.OperationDuration;
			
			vEmployeeDuration = vEmployeeDuration + vSelectionDetailRecords.OperationDuration;
			vTotalRoomSpace = vTotalRoomSpace + vSelectionDetailRecords.RoomSpace;
			vTotalPrice = vTotalPrice + vSelectionDetailRecords.Price;
		EndDo;
		
		vT = EmployeeOperations.Unload(, "Operation, OperationCode, OperationsCount");
		vT.GroupBy("Operation, OperationCode", "OperationsCount");
		For Each vRow In vT Do
			EmployeeOperationsTypeText = EmployeeOperationsTypeText + TrimAll(vRow.OperationCode) + " = " + vRow.OperationsCount + "; "; 
		EndDo;
		If vEmployeeDuration <> 0 Then
			EmployeeOperationsTypeText = EmployeeOperationsTypeText + NStr("en='T. '; ru='Вр. '; de='Zt. '") + 
			                           (Int(vEmployeeDuration/60)) + NStr("en='h '; ru='ч '; de='h '") + 
			                           (vEmployeeDuration - Int(vEmployeeDuration/60)*60) + NStr("en='m'; ru='м'; de='m'");
		EndIf;
		If vTotalRoomSpace > 0 Then
			If ValueIsFilled(EmployeeOperationsTypeText) Then
				EmployeeOperationsTypeText = EmployeeOperationsTypeText + ", "	
			EndIf;
			EmployeeOperationsTypeText = EmployeeOperationsTypeText + NStr("en = 'Sq. '; de = 'Sq. '; ru = 'Пл. '") + vTotalRoomSpace;
		EndIf;
		If vTotalPrice > 0 Then
			If ValueIsFilled(EmployeeOperationsTypeText) Then
				EmployeeOperationsTypeText = EmployeeOperationsTypeText + ", "	
			EndIf;
            EmployeeOperationsTypeText = EmployeeOperationsTypeText + NStr("en = 'Sum. '; de = 'Sum. '; ru = 'Ст. '") + cmFormatSum(vTotalPrice, Hotel.BaseCurrency);
		EndIf;
		If EmployeeOperations.Count() > 0 Then
			Items.DeleteEmployee.BackColor = WebColors.LightGoldenRodYellow;
			Items.DeleteEmployee.Picture = PictureLib.SpreadsheetDeletePageBreak;
		Else
			Items.DeleteEmployee.BackColor = WebColors.MistyRose;                            
			Items.DeleteEmployee.Picture = PictureLib.Delete;	
		EndIf;		
	EndIf;
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure FillNotAssignedOperations()
	NotAssignedOperations.Clear();
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	EmployeeOperation.Ref AS Ref,
	|	EmployeeOperation.Room AS Room,
	|	EmployeeOperation.RoomType AS RoomType,
	|	EmployeeOperation.OperationIntentTime AS OperationIntentTime,
	|	EmployeeOperation.EmployeeAssignmentTime AS EmployeeAssignmentTime,
	|	EmployeeOperation.OperationStartTime AS OperationStartTime,
	|	EmployeeOperation.OperationEndTime AS OperationEndTime,
	|	EmployeeOperation.Operation AS Operation,
	|	EmployeeOperation.Operation.Code AS OperationCode,
	|	CASE
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.None)
	|			THEN 5
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Reserved)
	|			THEN 6
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Occupied)
	|			THEN 2
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.OccupiedDirty)
	|			THEN 7
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Repair)
	|			THEN 8
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Luggage)
	|			THEN 9
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Malfunction)
	|			THEN 10
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Waiting)
	|			THEN 1
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.TidyingUp)
	|			THEN 0
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.CheckOut)
	|			THEN 3
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Vacant)
	|			THEN 4
	|		ELSE 5
	|	END AS RoomStatusIcon,
	|	1 AS OperationsCount,
	|	CASE
	|		WHEN NOT Reservations.Ref IS NULL
	|			THEN 41
	|		ELSE 0
	|	END AS CheckInWaitingIcon,
	|	EmployeeOperation.RoomSpace AS RoomSpace,
	|	EmployeeOperation.Price AS Price
	|FROM
	|	Document.EmployeeOperation AS EmployeeOperation
	|		LEFT JOIN Document.Reservation AS Reservations
	|		ON (Reservations.Posted)
	|			AND (Reservations.ReservationStatus.IsActive)
	|			AND (Reservations.CheckInDate >= &qPeriodFrom)
	|			AND (Reservations.CheckInDate <= &qPeriodTo)
	|			AND (Reservations.Room = EmployeeOperation.Room)
	|WHERE
	|	EmployeeOperation.Employee = &qEmptyEmployee
	|	AND NOT EmployeeOperation.DeletionMark
	|	AND EmployeeOperation.Posted
	|	AND EmployeeOperation.Hotel = &qHotel
	|	AND CASE
	|			WHEN &qUseRoom
	|				THEN EmployeeOperation.Room IN HIERARCHY (&qRoom)
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qUseRoomSection
	|				THEN EmployeeOperation.Room.RoomSection = &qRoomSection
	|			ELSE TRUE
	|		END
	|	AND EmployeeOperation.OperationEndTime = &qEmptyDate
	|
	|GROUP BY
	|	EmployeeOperation.Ref,
	|	EmployeeOperation.Room,
	|	EmployeeOperation.RoomType,
	|	EmployeeOperation.OperationIntentTime,
	|	EmployeeOperation.EmployeeAssignmentTime,
	|	EmployeeOperation.OperationStartTime,
	|	EmployeeOperation.OperationEndTime,
	|	EmployeeOperation.Operation,
	|	EmployeeOperation.Operation.Code,
	|	CASE
	|		WHEN NOT Reservations.Ref IS NULL
	|			THEN 41
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.None)
	|			THEN 5
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Reserved)
	|			THEN 6
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Occupied)
	|			THEN 2
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.OccupiedDirty)
	|			THEN 7
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Repair)
	|			THEN 8
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Luggage)
	|			THEN 9
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Malfunction)
	|			THEN 10
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Waiting)
	|			THEN 1
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.TidyingUp)
	|			THEN 0
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.CheckOut)
	|			THEN 3
	|		WHEN EmployeeOperation.Room.RoomStatus.RoomStatusIcon = VALUE(Enum.RoomStatusesIcons.Vacant)
	|			THEN 4
	|		ELSE 5
	|	END,
	|	EmployeeOperation.RoomSpace,
	|	EmployeeOperation.Price
	|
	|ORDER BY
	|	EmployeeOperation.Room.SortCode";
	vQuery.SetParameter("qHotel", Hotel);
	vQuery.SetParameter("qEmptyDate", Date(1, 1, 1));
	vQuery.SetParameter("qEmptyEmployee", Catalogs.Employees.EmptyRef());
	vQuery.SetParameter("qPeriodFrom", BegOfDay(CurrentSessionDate()));
	vQuery.SetParameter("qPeriodTo", EndOfDay(CurrentSessionDate()));
	If ValueIsFilled(RoomsGroup) Then			
		vQuery.SetParameter("qUseRoom", True);
		vQuery.SetParameter("qRoom", RoomsGroup);			
	Else
		vQuery.SetParameter("qUseRoom", False);	
		vQuery.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
	EndIf;
	If ValueIsFilled(RoomSections) Then	
		vQuery.SetParameter("qUseRoomSection", True);
		vQuery.SetParameter("qRoomSection", RoomSections);	
	Else
		vQuery.SetParameter("qUseRoomSection", False);	
		vQuery.SetParameter("qRoomSection",  Catalogs.RoomSections.EmptyRef());
	EndIf;		
	vQueryResult = vQuery.Execute();
	
	vTotalRoomSpace = 0;
	vTotalPrice = 0;
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		vNewRow = NotAssignedOperations.Add();
		vNewRow.Doc = vSelectionDetailRecords.Ref;
		vNewRow.Room = vSelectionDetailRecords.Room;
		vNewRow.RoomType = vSelectionDetailRecords.RoomType;
		vNewRow.OperationIntentTime = vSelectionDetailRecords.OperationIntentTime;
		vNewRow.EmployeeAssignmentTime = vSelectionDetailRecords.EmployeeAssignmentTime;
		vNewRow.OperationStartTime = vSelectionDetailRecords.OperationStartTime;
		vNewRow.OperationEndTime = vSelectionDetailRecords.OperationEndTime;
		vNewRow.Operation = vSelectionDetailRecords.Operation;
		vNewRow.OperationCode = vSelectionDetailRecords.OperationCode;
		vNewRow.OperationsCount = vSelectionDetailRecords.OperationsCount;
		vNewRow.CheckInWaitingIcon = vSelectionDetailRecords.CheckInWaitingIcon;
		vNewRow.RoomStatusIcon = vSelectionDetailRecords.RoomStatusIcon;
		vTotalRoomSpace = vTotalRoomSpace + vSelectionDetailRecords.RoomSpace;
		vTotalPrice = vTotalPrice + vSelectionDetailRecords.Price;
	EndDo;	
	
	vT = NotAssignedOperations.Unload(, "Operation, OperationCode, OperationsCount");
	vT.GroupBy("Operation, OperationCode", "OperationsCount");
	
	NotAssignedOperationsTypeText = "";	
	For Each vRow In vT Do
		NotAssignedOperationsTypeText = NotAssignedOperationsTypeText + TrimAll(vRow.OperationCode) + " = " + vRow.OperationsCount + "; ";
	EndDo;
	If vTotalRoomSpace > 0 Then
		If ValueIsFilled(NotAssignedOperationsTypeText) Then
			NotAssignedOperationsTypeText = NotAssignedOperationsTypeText + ", "	
		EndIf;
		NotAssignedOperationsTypeText = NotAssignedOperationsTypeText + NStr("en = 'Sq. '; de = 'Sq. '; ru = 'Пл. '") + vTotalRoomSpace;
	EndIf;
	If vTotalPrice > 0 Then
		If ValueIsFilled(NotAssignedOperationsTypeText) Then
			NotAssignedOperationsTypeText = NotAssignedOperationsTypeText + ", "	
		EndIf;
        NotAssignedOperationsTypeText = NotAssignedOperationsTypeText + NStr("en = 'Sum. '; de = 'Sum. '; ru = 'Ст. '") + cmFormatSum(vTotalPrice, Hotel.BaseCurrency);
	EndIf;
EndProcedure // FillNotAssignedOperations

//-----------------------------------------------------------------------------
&AtServer
Procedure WorkOnAtServer()
	For Each vRow in Items.NotAssignedOperations.SelectedRows Do
		vDocObj = NotAssignedOperations.FindByID(vRow).Doc.GetObject();
		vDocObj.Employee = CurrentEmployee;
		vDocObj.EmployeeAssignmentTime = CurrentSessionDate();
		// Get operation standards
		If ValueIsFilled(vDocObj.Operation) Then
			vStds = Catalogs.Operations.GetOperationStandards(vDocObj.Operation, vDocObj.Hotel, vDocObj.RoomType, vDocObj.Room, vDocObj.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vDocObj.Duration = vStdsRow.Duration;
				vDocObj.RoomSpace = ?(vDocObj.Quantity = 0, 1, vDocObj.Quantity) * vStdsRow.RoomSpace;
				vDocObj.Price = ?(vDocObj.Quantity = 0, 1, vDocObj.Quantity) * vStdsRow.Price;
			EndIf;
		EndIf;
		// Recalculate durations
		vDocObj.pmCalculateDurations();
		// Save operation
		vDocObj.Write(DocumentWriteMode.Posting);
	EndDo;	
	RefreshTables(False);
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure WorkOutAtServer()
	For Each vRow in Items.EmployeeOperations.SelectedRows Do
		vDocObj = EmployeeOperations.FindByID(vRow).Doc.GetObject();
		vDocObj.Employee = Catalogs.Employees.EmptyRef();
		vDocObj.EmployeeAssignmentTime = '00010101';
		// Get operation standards
		If ValueIsFilled(vDocObj.Operation) Then
			vStds = Catalogs.Operations.GetOperationStandards(vDocObj.Operation, vDocObj.Hotel, vDocObj.RoomType, vDocObj.Room, vDocObj.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vDocObj.Duration = vStdsRow.Duration;
				vDocObj.RoomSpace = ?(vDocObj.Quantity = 0, 1, vDocObj.Quantity) * vStdsRow.RoomSpace;
				vDocObj.Price = ?(vDocObj.Quantity = 0, 1, vDocObj.Quantity) * vStdsRow.Price;
			EndIf;
		EndIf;
		// Recalculate durations
		vDocObj.pmCalculateDurations();
		// Save operation
		vDocObj.Write(DocumentWriteMode.Posting);
	EndDo;
	RefreshTables(False);
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	RefreshTables();
	CheckRoomSections();
	CheckRoomGroup();
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("CatalogRef.Employees") Then
		AddEmployeeAtServer(pSelectedValue);	
	ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.Rooms") Then
		SetRoomsGroup(pSelectedValue); 
	ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.RoomSections") Then
		SetRoomsSections(pSelectedValue);
	ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.Hotels") Then
		Hotel = pSelectedValue;
		Items.ChoiceHotel.Title = pSelectedValue;
		RefreshTables(); 
		// Set hotel color          
		Items.ChoiceHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	EndIf; 
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure SetRoomsGroup(pRoom)
	RoomsGroup = pRoom;
	If ValueIsFilled(RoomsGroup) Then
		Items.ChoiceRoomGroup.Title     = pRoom;
		Items.ChoiceRoomGroup.BackColor = WebColors.HoneyDew;
		Items.ClearRoomGroup.Visible    = True;
	Else
		Items.ChoiceRoomGroup.Title     = NStr("en = 'All rooms'; ru = 'Все номера'; de = 'Alle Zimmeren'");
		Items.ChoiceRoomGroup.BackColor = WebColors.White;
		Items.ClearRoomGroup.Visible    = False;		
	EndIf;
	RefreshTables(False,False);	
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure SetRoomsSections(pSections)
	RoomSections = pSections;
	If ValueIsFilled(RoomSections) Then
		Items.ChoiceRoomSections.Title  = pSections;
		Items.ChoiceRoomSections.BackColor = WebColors.HoneyDew;
		Items.ClearRoomSections.Visible = True;	
	Else
		Items.ChoiceRoomSections.Title  = NStr("en = 'All sections'; ru = 'Все секции'; de = 'Alle Abschnitten'");
		Items.ChoiceRoomSections.BackColor = WebColors.White;
		Items.ClearRoomSections.Visible = False;
	EndIf;
	RefreshTables(False,False);	
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure AddEmployeeAtServer(pEmployee)
	vRM = InformationRegisters.HousekeepingShift.CreateRecordManager();	
	vRM.Hotel = Hotel;
	vRM.Employee = pEmployee;
	vRM.Write();
	RefreshTables();
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure DeleteEmployeeUserAnswer(vUC, vExtraParams) Export
	If vUC = DialogReturnCode.Yes Then
		DeleteEmployeeAtServer();
	EndIf;
EndProcedure // DeleteEmployeeUserAnswer

//-----------------------------------------------------------------------------
&AtServer
Procedure DeleteEmployeeAtServer()
	If EmployeeOperations.Count() > 0 Then	
		For Each vRow in EmployeeOperations Do
			vDocObj = vRow.Doc.GetObject();
			vDocObj.Employee = Catalogs.Employees.EmptyRef();
			vDocObj.EmployeeAssignmentTime = '00010101';
			// Get operation standards
			If ValueIsFilled(vDocObj.Operation) Then
				vStds = Catalogs.Operations.GetOperationStandards(vDocObj.Operation, vDocObj.Hotel, vDocObj.RoomType, vDocObj.Room, vDocObj.Employee);
				If vStds.Count() > 0 then
					vStdsRow = vStds.Get(0);
					vDocObj.Duration = vStdsRow.Duration;
					vDocObj.RoomSpace = ?(vDocObj.Quantity = 0, 1, vDocObj.Quantity) * vStdsRow.RoomSpace;
					vDocObj.Price = ?(vDocObj.Quantity = 0, 1, vDocObj.Quantity) * vStdsRow.Price;
				EndIf;
			EndIf;
			// Recalculate durations
			vDocObj.pmCalculateDurations();
			// Save operation
			vDocObj.Write(DocumentWriteMode.Posting);
		EndDo;
		vRow = Employee.FindByID(Items.Employee.CurrentRow);
		vRow.WorkNumber = 0;
		vRow.Operations = "";
		RefreshTables(False);
	Else	
		vRM = InformationRegisters.HousekeepingShift.CreateRecordManager();	
		vRM.Hotel    = Hotel;
		vRM.Employee = CurrentEmployee;
		vRM.Read();
		vRM.Delete();
		CurrentEmployee = Undefined;
		RefreshTables();
	EndIf;	
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure CheckRoomGroup()	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Rooms.Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	Rooms.IsFolder
	|	AND Rooms.Owner = &qHotel
	|	AND NOT Rooms.DeletionMark";	
	vQuery.SetParameter("qHotel", Hotel);	
	vQueryResult = vQuery.Execute();	
	If vQueryResult.Unload().Count() > 0 Then
		Items.GroupRoomGroup.Visible = True;
	Else
		Items.GroupRoomGroup.Visible = False;
	EndIf;	
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure CheckRoomSections()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	RoomSections.Ref
	|FROM
	|	Catalog.RoomSections AS RoomSections
	|WHERE
	|	NOT RoomSections.IsFolder
	|	AND RoomSections.Hotel = &qHotel
	|	AND NOT RoomSections.DeletionMark";
	vQuery.SetParameter("qHotel", Hotel);	
	vQueryResult = vQuery.Execute();	
	If vQueryResult.Unload().Count() > 0 Then
		Items.GroupRoomSection.Visible = True;
	Else
		Items.GroupRoomSection.Visible = False;		
	EndIf;	
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure CheckNotification()		
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	NotificationQueue.Recipient
		|FROM
		|	InformationRegister.NotificationQueue AS NotificationQueue
		|
		|GROUP BY
		|	NotificationQueue.Recipient";	
	vQueryResult = vQuery.Execute();	
	If vQueryResult.Unload().Count() > 0 Then
		Items.SendNotify.Enabled = True;
		Items.SendNotify.Title = NStr("en = 'Send notifications: '; ru = 'Отправить уведомления: '; de = 'Benachrichtigungen senden: '") + vQueryResult.Unload().Count();
	Else	 	
		Items.SendNotify.Enabled = False;
		Items.SendNotify.Title = NStr("en = 'No notifications'; ru = 'Уведомлений нет'; de = 'Keine Benachrichtigungen'");
	EndIf;	
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure SendNotifyAtServer()
	Catalogs.ChatBots.SendNotification(Hotel);
	CheckNotification();
EndProcedure

#EndRegion
