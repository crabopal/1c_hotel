// -----------------------------------------------------------------------------
// Description: Finds employee by it's PBX account code
// Parameters: PBX account code
// Return value: Employee reference
// -----------------------------------------------------------------------------
Function cmGetEmployeeByPBXAccountCode(pPBXAccountCode) Export
	vEmployee = Catalogs.Employees.EmptyRef();
	If pPBXAccountCode = 0 Then
		Return vEmployee;
	EndIf;
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Employees.Ref AS Employee
	|FROM
	|	Catalog.Employees AS Employees
	|WHERE
	|	Employees.PBXAccountCode = &qPBXAccountCode
	|	AND (NOT Employees.DeletionMark)
	|	AND (NOT Employees.IsFolder)
	|ORDER BY
	|	Employees.SortCode";
	vQry.SetParameter("qPBXAccountCode", pPBXAccountCode);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vEmployee = vQryResRow.Employee;
		Break;
	EndDo;
	
	Return vEmployee;
EndFunction // cmGetEmployeeByPBXAccountCode

// -----------------------------------------------------------------------------
// Description: Finds operation by it's PBX phone number
// Parameters: PBX phone number
// Return value: Operation item reference
// -----------------------------------------------------------------------------
Function cmGetOperationByPBXPhoneNumber(pPBXPhoneNumber, rIsStart = True) Export
	vOperation = Catalogs.Operations.EmptyRef();
	If pPBXPhoneNumber = 0 Then
		Return vOperation;
	EndIf;
	rIsStart = True;
	
	// Run query to find operation
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Operations.Ref AS Operation,
	|	Operations.PBXStartCode AS PBXStartCode,
	|	Operations.PBXEndCode AS PBXEndCode
	|FROM
	|	Catalog.Operations AS Operations
	|WHERE
	|	(Operations.PBXStartCode = &qPBXPhoneNumber OR Operations.PBXEndCode = &qPBXPhoneNumber)
	|	AND (NOT Operations.DeletionMark)
	|	AND (NOT Operations.IsFolder)
	|ORDER BY
	|	Operations.SortCode";
	vQry.SetParameter("qPBXPhoneNumber", pPBXPhoneNumber);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vOperation = vQryResRow.Operation;
		If TrimAll(vQryResRow.PBXEndCode) = TrimAll(pPBXPhoneNumber) Then
			rIsStart = False;
		EndIf;
		Break;
	EndDo;
	
	Return vOperation;
EndFunction // cmGetOperationByPBXPhoneNumber

// -----------------------------------------------------------------------------
// Description: Finds room status by it's PBX phone number
// Parameters: PBX phone number
// Return value: Room status item reference
// -----------------------------------------------------------------------------
Function cmGetRoomStatusByPBXPhoneNumber(pPBXPhoneNumber) Export
	vRoomStatus = Catalogs.RoomStatuses.EmptyRef();
	If pPBXPhoneNumber = 0 Then
		Return vRoomStatus;
	EndIf;
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomStatuses.Ref AS RoomStatus
	|FROM
	|	Catalog.RoomStatuses AS RoomStatuses
	|WHERE
	|	RoomStatuses.PBXCode = &qPBXPhoneNumber
	|	AND (NOT RoomStatuses.DeletionMark)
	|	AND (NOT RoomStatuses.IsFolder)
	|ORDER BY
	|	RoomStatuses.SortCode";
	vQry.SetParameter("qPBXPhoneNumber", pPBXPhoneNumber);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vRoomStatus = vQryResRow.RoomStatus;
		Break;
	EndDo;
	
	Return vRoomStatus;
EndFunction // cmGetRoomStatusByPBXPhoneNumber

// -----------------------------------------------------------------------------
// Description: Returns employee and operation by PBX account code
// Parameters: PBX account code
// Return value: "Employee PBX codes" information register record data as Structure
// -----------------------------------------------------------------------------
Function cmGetEmployeeAndOperationByPBXCode(pPBXCode) Export
	vStruct = New Structure("Employee, Operation, RoomStatus, IsOperationStart, IsOperationEnd", 
	                        Catalogs.Employees.EmptyRef(), 
	                        Catalogs.Operations.EmptyRef(),
	                        Catalogs.RoomStatuses.EmptyRef(),
	                        False, False);
	
	// Run query to get data from the information register
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EmployeePBXCodes.Employee,
	|	EmployeePBXCodes.Operation,
	|	EmployeePBXCodes.RoomStatus,
	|	EmployeePBXCodes.IsOperationStart,
	|	EmployeePBXCodes.IsOperationEnd
	|FROM
	|	InformationRegister.EmployeePBXCodes AS EmployeePBXCodes
	|WHERE
	|	EmployeePBXCodes.PBXCode = &qPBXCode";
	vQry.SetParameter("qPBXCode", pPBXCode);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		FillPropertyValues(vStruct, vQryResRow);
		Break;
	EndDo;
	
	Return vStruct;
EndFunction // cmGetEmployeeAndOperationByPBXCode

// -----------------------------------------------------------------------------
// Description: Returns employee by PBX employee account code
// Parameters: PBX account code
// Return value: Reference to the employee item
// -----------------------------------------------------------------------------
Function cmGetEmployeeByPBXCode(pPBXCode) Export
	vEmployee = Undefined;
	If pPBXCode = 0 Then
		Return vEmployee;
	EndIf;
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Employees.Ref AS Employee
	|FROM
	|	Catalog.Employees AS Employees
	|WHERE
	|	Employees.PBXAccountCode = &qPBXCode
	|	AND (NOT Employees.DeletionMark)
	|	AND (NOT Employees.IsFolder)";
	vQry.SetParameter("qPBXCode", pPBXCode);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vEmployee = vQryResRow.Employee;
		Break;
	EndDo;
	
	Return vEmployee;
EndFunction // cmGetEmployeeByPBXCode 

// -----------------------------------------------------------------------------
// Description: Returns pending employee operation (started but not finished)
// Parameters: Employee, Operation, Date
// Return value: Employee operation document reference
// -----------------------------------------------------------------------------
Function cmGetPendingEmployeeOperation(pEmployee, pOperation, pPeriod, pRoom) Export
	// Run query to get pending employee operation
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EmployeeOperationsHistorySliceLast.Recorder
	|FROM
	|	InformationRegister.EmployeeOperationsHistory.SliceLast(
	|			&qPeriod,
	|			Employee = &qEmployee
	|				AND Operation = &qOperation
	|				AND OperationEndTime = &qEmptyTime) AS EmployeeOperationsHistorySliceLast";
	vQry.SetParameter("qEmployee", pEmployee);
	vQry.SetParameter("qOperation", pOperation);
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qEmptyTime", '00010101');
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vEmpOpr = vQryResRow.Recorder;
		Break;
	EndDo;
	// Try to find the same operation started by another employee
	If Not ValueIsFilled(vEmpOpr) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	EmployeeOperationsHistory.Recorder
		|FROM
		|	InformationRegister.EmployeeOperationsHistory AS EmployeeOperationsHistory
		|WHERE
		|	EmployeeOperationsHistory.Room = &qRoom
		|	AND EmployeeOperationsHistory.Operation = &qOperation
		|	AND EmployeeOperationsHistory.OperationStartTime <= &qPeriod
		|	AND EmployeeOperationsHistory.OperationEndTime = &qEmptyTime
		|
		|ORDER BY
		|	EmployeeOperationsHistory.OperationStartTime DESC";
		vQry.SetParameter("qRoom", pRoom);
		vQry.SetParameter("qOperation", pOperation);
		vQry.SetParameter("qPeriod", pPeriod);
		vQry.SetParameter("qEmptyTime", '00010101');
		vQryRes = vQry.Execute().Unload();
		For Each vQryResRow In vQryRes Do
			vEmpOpr = vQryResRow.Recorder;
			Break;
		EndDo;
	EndIf;
	Return vEmpOpr;
EndFunction // cmGetPendingEmployeeOperation

// -----------------------------------------------------------------------------
// Description: Returns value table of all pending employee operations for the 
//              given rooms list
// Parameters: Rooms value list
// Return value: Value table with employee operations data
// -----------------------------------------------------------------------------
Function cmGetPendingEmployeeOperations(pRooms) Export
	// Run query to get pending employee operations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EmployeeOperationsHistorySliceLast.Room,
	|	EmployeeOperationsHistorySliceLast.OperationStartTime,
	|	EmployeeOperationsHistorySliceLast.Employee,
	|	EmployeeOperationsHistorySliceLast.Remarks
	|FROM
	|	InformationRegister.EmployeeOperationsHistory.SliceLast(
	|			&qPeriod,
	|			Room IN (&qRooms)
	|				AND OperationEndTime = &qEmptyTime) AS EmployeeOperationsHistorySliceLast";
	vQry.SetParameter("qRooms", pRooms);
	vQry.SetParameter("qPeriod", CurrentSessionDate());
	vQry.SetParameter("qEmptyTime", '00010101');
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetPendingEmployeeOperations

// -----------------------------------------------------------------------------
// Description: Returns value table of all employee operations for the 
//              given operation and operation start time
// Parameters: Employee, Operation, Operation start time
// Return value: Value table with employee operation documents
// -----------------------------------------------------------------------------
Function cmGetEmployeeOperation(pEmployee, pOperation, pOperationStartTime) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EmployeeOperationsHistory.Recorder
	|FROM
	|	InformationRegister.EmployeeOperationsHistory AS EmployeeOperationsHistory
	|WHERE
	|	EmployeeOperationsHistory.Employee = &qEmployee
	|	AND EmployeeOperationsHistory.Operation = &qOperation
	|	AND EmployeeOperationsHistory.OperationStartTime = &qOperationStartTime
	|ORDER BY
	|	EmployeeOperationsHistory.PointInTime";
	vQry.SetParameter("qEmployee", pEmployee);
	vQry.SetParameter("qOperation", pOperation);
	vQry.SetParameter("qOperationStartTime", pOperationStartTime);
	vEmpOperations = vQry.Execute().Unload();
	Return vEmpOperations;
EndFunction // cmGetEmployeeOperation

// -----------------------------------------------------------------------------
// Description: Returns value table with room status last change author and date 
//              for the given rooms list
// Parameters: Rooms value list
// Return value: Value table with room status change data
// -----------------------------------------------------------------------------
Function cmGetAuthorAndDateOfLastChangeOfRoomStatuses(pRooms) Export
	// Run query to get pending employee operations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomStatusChangeHistory.Period,
	|	RoomStatusChangeHistory.User,
	|	RoomStatusChangeHistory.Room,
	|	RoomStatusChangeHistory.RoomStatus,
	|	RoomStatusChangeHistory.Remarks
	|FROM
	|	InformationRegister.RoomStatusChangeHistory AS RoomStatusChangeHistory
	|		INNER JOIN InformationRegister.RoomStatusChangeHistory.SliceLast(&qPeriod, Room IN (&qRooms)) AS RoomStatusChangeHistorySliceLast
	|		ON RoomStatusChangeHistory.Period = RoomStatusChangeHistorySliceLast.Period
	|			AND RoomStatusChangeHistory.Room = RoomStatusChangeHistorySliceLast.Room
	|WHERE
	|	RoomStatusChangeHistory.Room IN(&qRooms)";
	vQry.SetParameter("qRooms", pRooms);
	vQry.SetParameter("qPeriod", CurrentSessionDate());
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetAuthorAndDateOfLastChangeOfRoomStatuses

// -----------------------------------------------------------------------------
// Description: Returns value table with all operations
// Parameters: None
// Return value: Value table with operations
// -----------------------------------------------------------------------------
Function cmGetAllOperations(pHotel = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Operations.Ref AS Operation,
	|	Operations.Code AS Code,
	|	Operations.Description AS Description,
	|	Operations.SortCode AS SortCode
	|FROM
	|	Catalog.Operations AS Operations
	|WHERE
	|	Operations.DeletionMark = FALSE
	|	AND Operations.IsFolder = FALSE
	|	AND (NOT &qHotelIsEmptyRef
	|		AND (Operations.Hotel = &qHotel
	|					OR Operations.Hotel = &qEmptyHotel)
	|		OR &qHotelIsEmptyRef)
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qHotel", ?(pHotel = Undefined, SessionParameters.CurrentHotel, pHotel));
	vQry.SetParameter("qHotelIsEmptyRef", ?(pHotel = Catalogs.Hotels.EmptyRef(), True, False));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllOperations

// -----------------------------------------------------------------------------
// Function - Cm get employee operation queue
//
// Parameters:
//  pDay		 Date 
//  pEmployee	 Employee 
// 
// Returns:
//   - ValueTable
// -----------------------------------------------------------------------------
Function cmGetEmployeeOperationQueue(pDay, pEmployee = Undefined, WhoToAppoint = Undefined) Export
	If pEmployee = Undefined Then 
		pEmployee = Catalogs.Employees.EmptyRef();
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	NestedSelect.Ref AS RefDoc,
		|	NestedSelect.Ref.Room,
		|	NestedSelect.Ref.Room.RoomStatus,
		|	NestedSelect.Ref.RoomType.SortCode AS RefRoomTypeSortCode,
		|	NestedSelect.Ref.Room.RoomSection.SortCode,
		|	CheckIns.CheckInDate AS CheckInDate,
		|	CheckIns.Recorder,
		|	CASE
		|		WHEN CheckIns.Recorder IS NULL
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Sort,
		|	NestedSelect.Ref.Employee AS Field1
		|FROM
		|	(SELECT TOP 1
		|		EmployeeOperation.Employee AS Employee,
		|		EmployeeOperation.Hotel AS Hotel,
		|		MAX(EmployeeOperation.Date) AS Date
		|	FROM
		|		Document.EmployeeOperation AS EmployeeOperation
		|	WHERE
		|		EmployeeOperation.DeletionMark = FALSE
		|		AND EmployeeOperation.Employee = &WhoToAppoint
		|	
		|	GROUP BY
		|		EmployeeOperation.Employee,
		|		EmployeeOperation.Hotel
		|	
		|	ORDER BY
		|		Date DESC) AS LastOper
		|		LEFT JOIN (SELECT
		|			EmployeeOperation.Ref AS Ref
		|		FROM
		|			Document.EmployeeOperation AS EmployeeOperation
		|		WHERE
		|			EmployeeOperation.OperationEndTime = DATETIME(1, 1, 1, 0, 0, 0)
		|			AND EmployeeOperation.DeletionMark = FALSE
		|			AND EmployeeOperation.Date >= &qDateFrom
		|			AND EmployeeOperation.Date <= &qDateTo) AS NestedSelect
		|			LEFT JOIN (SELECT
		|				RoomInventory.Recorder AS Recorder,
		|				RoomInventory.Room AS Room,
		|				RoomInventory.Customer AS Customer,
		|				RoomInventory.CheckInDate AS CheckInDate,
		|				RoomInventory.RoomType.SortCode AS RoomTypeSortCode,
		|				RoomInventory.Room.RoomSection.SortCode AS RoomRoomSectionSortCode,
		|				RoomInventory.Room.RoomStatus AS RoomRoomStatus
		|			FROM
		|				AccumulationRegister.RoomInventory AS RoomInventory
		|			WHERE
		|				RoomInventory.IsReservation
		|				AND RoomInventory.RecordType = &qExpense
		|				AND RoomInventory.CheckInDate >= &qDateFrom
		|				AND RoomInventory.CheckInDate <= &qDateTo
		|			
		|			GROUP BY
		|				RoomInventory.Room,
		|				RoomInventory.Customer,
		|				RoomInventory.RoomType.SortCode,
		|				RoomInventory.Room.RoomSection.SortCode,
		|				RoomInventory.CheckInDate,
		|				RoomInventory.Recorder,
		|				RoomInventory.Room.RoomStatus) AS CheckIns
		|			ON (CheckIns.Room = NestedSelect.Ref.Room)
		|		ON (NestedSelect.Ref.Room.Owner = LastOper.Hotel)
		|WHERE
		|	NestedSelect.Ref.Employee = &Employee
		|	AND (NestedSelect.Ref.Room.RoomStatus = NestedSelect.Ref.Room.Owner.OccupiedDirtyRoomStatus
		|			OR NestedSelect.Ref.Room.Owner.RoomStatusAfterCheckOut = NestedSelect.Ref.Room.Owner.RoomStatusAfterCheckOut)		
		|ORDER BY
		|	Sort DESC,
		|	CheckInDate,
		|	RefRoomTypeSortCode DESC";
		vQuery.SetParameter("Employee", pEmployee);
		vQuery.SetParameter("WhoToAppoint", WhoToAppoint);
		vQuery.SetParameter("qDateFrom", BegOfDay(pDay));		
		vQuery.SetParameter("qDateTo", EndOfDay(pday));
		vQuery.SetParameter("qExpense", AccumulationRecordType.Expense);
		vQueryResult = vQuery.Execute().Unload();
	Else
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	NestedSelect.Ref AS RefDoc,
		|	NestedSelect.Ref.Room,
		|	NestedSelect.Ref.Room.RoomStatus,
		|	NestedSelect.Ref.RoomType.SortCode AS RefRoomTypeSortCode,
		|	NestedSelect.Ref.Room.RoomSection.SortCode,
		|	CheckIns.CheckInDate AS CheckInDate,
		|	CheckIns.Recorder,
		|	CASE
		|		WHEN CheckIns.Recorder IS NULL
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Sort,
		|	NestedSelect.Ref.Employee AS Field1
		|FROM
		|	(SELECT
		|		EmployeeOperation.Ref AS Ref
		|	FROM
		|		Document.EmployeeOperation AS EmployeeOperation
		|	WHERE
		|		EmployeeOperation.OperationEndTime = DATETIME(1, 1, 1, 0, 0, 0)
		|		AND EmployeeOperation.DeletionMark = FALSE
		|		AND EmployeeOperation.Date >= &qDateFrom
		|		AND EmployeeOperation.Date <= &qDateTo) AS NestedSelect
		|		LEFT JOIN (SELECT
		|			RoomInventory.Recorder AS Recorder,
		|			RoomInventory.Room AS Room,
		|			RoomInventory.Customer AS Customer,
		|			RoomInventory.CheckInDate AS CheckInDate,
		|			RoomInventory.RoomType.SortCode AS RoomTypeSortCode,
		|			RoomInventory.Room.RoomSection.SortCode AS RoomRoomSectionSortCode,
		|			RoomInventory.Room.RoomStatus AS RoomRoomStatus
		|		FROM
		|			AccumulationRegister.RoomInventory AS RoomInventory
		|		WHERE
		|			RoomInventory.IsReservation
		|			AND RoomInventory.RecordType = &qExpense
		|			AND RoomInventory.CheckInDate >= &qDateFrom
		|			AND RoomInventory.CheckInDate <= &qDateTo
		|		
		|		GROUP BY
		|			RoomInventory.Room,
		|			RoomInventory.Customer,
		|			RoomInventory.RoomType.SortCode,
		|			RoomInventory.Room.RoomSection.SortCode,
		|			RoomInventory.CheckInDate,
		|			RoomInventory.Recorder,
		|			RoomInventory.Room.RoomStatus) AS CheckIns
		|		ON (CheckIns.Room = NestedSelect.Ref.Room)
		|		LEFT JOIN (SELECT
		|			EmployeeOperation.Employee AS Employee,
		|			EmployeeOperation.Hotel AS Hotel
		|		FROM
		|			Document.EmployeeOperation AS EmployeeOperation
		|		WHERE
		|			EmployeeOperation.DeletionMark = FALSE
		|			AND EmployeeOperation.Employee = &Employee
		|		
		|		GROUP BY
		|			EmployeeOperation.Employee,
		|			EmployeeOperation.Hotel) AS LastOper
		|		ON NestedSelect.Ref.Room.Owner = LastOper.Hotel
		|WHERE
		|	NestedSelect.Ref.Employee = &Employee
		|	AND (NestedSelect.Ref.Room.RoomStatus = NestedSelect.Ref.Room.Owner.OccupiedDirtyRoomStatus
		|			OR NestedSelect.Ref.Room.Owner.RoomStatusAfterCheckOut = NestedSelect.Ref.Room.Owner.RoomStatusAfterCheckOut)
		|
		|ORDER BY
		|	Sort DESC,
		|	CheckInDate,
		|	RefRoomTypeSortCode DESC";
		vQuery.SetParameter("Employee", pEmployee);
		vQuery.SetParameter("qDateFrom", BegOfDay(pDay));		
		vQuery.SetParameter("qDateTo", EndOfDay(pday));
		vQuery.SetParameter("qExpense", AccumulationRecordType.Expense);
		vQueryResult = vQuery.Execute().Unload();
	EndIf;
	Return vQueryResult;
EndFunction // cmGetEmployeeOperationQueue

// -----------------------------------------------------------------------------
// Function - Cm get free maids
//
// Parameters:
//  pEmployee	Employee
// 
// Returns:
//   - ValueTable
// -----------------------------------------------------------------------------
Function cmGetFreeMaids(pEmployee = Undefined) Export
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Employees.Ref AS Employee,
	|	EmplLastOp.OperationEndTime,
	|	DATEDIFF(EmplLastOp.OperationEndTime, &CurrentTime, MINUTE) AS DateDiff,
	|	EmpCurOp.Ref
	|FROM
	|	(SELECT
	|		EmployeeOperation.Employee AS Employee,
	|		MAX(EmployeeOperation.OperationEndTime) AS OperationEndTime
	|	FROM
	|		Document.EmployeeOperation AS EmployeeOperation
	|	WHERE
	|		EmployeeOperation.DeletionMark = FALSE
	|		AND NOT EmployeeOperation.DeletionMark
	|	GROUP BY
	|		EmployeeOperation.Employee) AS EmplLastOp
	|		FULL JOIN Catalog.Employees AS Employees
	|			LEFT JOIN (SELECT
	|				COUNT(DISTINCT EmployeeOperation.Ref) AS Ref,
	|				EmployeeOperation.Employee AS Employee
	|			FROM
	|				Document.EmployeeOperation AS EmployeeOperation
	|			WHERE
	|				EmployeeOperation.OperationEndTime = &OperationEndTime
	|				AND EmployeeOperation.Employee IN HIERARCHY(&Employee)
	|				AND NOT EmployeeOperation.DeletionMark
	|			
	|			GROUP BY
	|				EmployeeOperation.Employee) AS EmpCurOp
	|			ON (EmpCurOp.Employee = Employees.Ref)
	|		ON EmplLastOp.Employee = Employees.Ref
	|WHERE
	|	Employees.Ref IN(&Employee)
	|	AND EmpCurOp.Ref IS NULL
	|
	|ORDER BY
	|	DateDiff DESC";
	vQuery.SetParameter("Employee",  pEmployee);
	vQuery.SetParameter("CurrentTime", CurrentSessionDate());
	vQuery.SetParameter("OperationEndTime",Дата(1,1,1)); 
	vQueryResult = vQuery.Execute().Unload();
	Return vQueryResult;
EndFunction // cmGetFreeMaids

// -----------------------------------------------------------------------------
// Function - Cm get maids
// 
// Returns:
//   - Array 
// -----------------------------------------------------------------------------
Function cmGetMaids(pHotel = Undefined) Export
	// Get employees from auth register
	vQry = New Query;
	qText = 
	"SELECT
	|	Operations.Employee,
	|	Operations.Hotel,
	| 	SUM(Operations.Quantity) AS Quantity
	|FROM
	|	Document.EmployeeOperation AS Operations
	|WHERE
	|	Operations.Posted
	|	AND Operations.Employee <> &qEmptyEmployee
	|	AND Operations.Date >= &qPeriodFrom
	|	AND Operations.Date <= &qPeriodTo
	|GROUP BY
	|	Operations.Hotel,
	|	Operations.Employee
	|
	|ORDER BY
	|	Operations.Hotel.SortCode,
	|	Operations.Employee.SortCode,
	|	Operations.Employee.Department.SortCode,
	|	Operations.Employee.Description";
	vQry.Text = qText;
	vQry.SetParameter("qPeriodFrom", CurrentSessionDate() - 12*3600);
	vQry.SetParameter("qPeriodTo", CurrentSessionDate() + 12*3600);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyEmployee", Catalogs.Employees.EmptyRef());
	vQry.SetParameter("qEmptyDate",'00010101');
	vTEmployees = vQry.Execute().Unload().UnloadColumn("Employee");;
	Return vTEmployees;	
EndFunction // cmGetMaids
