
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	If Parameters.Property("Operations") Then
		For Each vOpStruct In Parameters.Operations Do
			vOpRow = Operations.Add();
			FillPropertyValues(vOpRow, vOpStruct);
			vOpRow.Count = 1;
		EndDo;
	EndIf;
	If Parameters.Property("Hotel") Then
		Hotel = Parameters.Hotel;	
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;	
	EndIf;
	If Parameters.Property("EmployeeList") Then
		EmployeeList = Parameters.EmployeeList;	
	EndIf;
	FreeWorkHead = NStr("en = 'Unassigned tasks'; ru = 'Неназначенные работы'; de = 'Nicht zugewiesene Aufgaben'");	
	EmployeesHead = NStr("en = 'Attendants in the shift'; ru = 'Сотрудники в смене'; de = 'Mitarbeiter in der Schicht'");
	
	FillEmployeeTable();
	FillEmployeeOperations(CurrentEmployee);
	FillNotAssignedOperations();
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeeSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.CurrentData <> Undefined Then
		SetEmployee(Items.Employee.CurrentData.Employee);
	EndIf;	
EndProcedure // EmployeeSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeeOpertionsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(CurrentEmployee) Then 
		If ValueIsFilled(CurrentEmployee) Then 
			vCurData =  Items.EmployeeOperations.CurrentData; 
			If WorkOutAtServer(vCurData.UUID) Then
				vDragOperations = DragOperationsList.FindRows(New Structure("Room, UUID", vCurData.Room, vCurData.UUID));
				If vDragOperations.Count() > 0 Then
					vDragOperations[0].Employee = PredefinedValue("Catalog.Employees.EmptyRef"); 	
				Else
					vNewDragOperations = DragOperationsList.Add();
					vNewDragOperations.Room = vCurData.Room;
					vNewDragOperations.Employee = PredefinedValue("Catalog.Employees.EmptyRef");
					vNewDragOperations.UUID = vCurData.UUID;
				EndIf;
				FillEmployeeOperations(CurrentEmployee);
				FillNotAssignedOperations();
				vEmployeeRow = Employee.FindRows(New Structure("Employee", CurrentEmployee));
				For Each vRow In vEmployeeRow Do 
					vRow.WorkNumber = vRow.WorkNumber -	1;
					vRow.Operations = EmployeeOperationsTypeText;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	CurrentItem = Items.GroupTable;
EndProcedure // EmployeeOpertionsSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure NotAssignedOperationsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(CurrentEmployee) Then 
		vCurData =  Items.NotAssignedOperations.CurrentData; 
		If WorkOnAtServer(vCurData.UUID) Then
			vDragOperations = DragOperationsList.FindRows(New Structure("Room, UUID", vCurData.Room, vCurData.UUID));
			If vDragOperations.Count() > 0 Then
				vDragOperations[0].Employee = CurrentEmployee; 	
			Else
				vNewDragOperations = DragOperationsList.Add();
				vNewDragOperations.Room = vCurData.Room;
				vNewDragOperations.Employee = CurrentEmployee;
				vNewDragOperations.UUID = vCurData.UUID;
			EndIf;
			FillEmployeeOperations(CurrentEmployee);
			FillNotAssignedOperations();
			vEmployeeRow = Employee.FindRows(New Structure("Employee", CurrentEmployee));
			For Each vRow In vEmployeeRow Do 
				vRow.WorkNumber = vRow.WorkNumber +	1;
				vRow.Operations = EmployeeOperationsTypeText;
			EndDo;
		EndIf;
	EndIf;
	CurrentItem = Items.GroupTable;
EndProcedure // NotAssignedOperationsSelection

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandSave(pCommand)
	vOperationArr = New Array();
	For Each DragOperationsRow In DragOperationsList Do
		vOperationArr.Add(New Structure("Room, Employee, UUID", DragOperationsRow.Room, DragOperationsRow.Employee, DragOperationsRow.UUID));	
	EndDo;
	If vOperationArr.Count() > 0 Then	
		Notify("OperationSchedule.EmployeeAssignment", vOperationArr, FormOwner);	
	EndIf;
	Close();
EndProcedure // CommandSave

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetEmployee(pEmployee)
	If ValueIsFilled(pEmployee) Then
		CurrentEmployee = pEmployee;
		FillEmployeeOperations(CurrentEmployee);
	Else
		CurrentEmployee = Undefined;
		FillEmployeeOperations(CurrentEmployee);
	EndIf;	
EndProcedure // SetEmployee

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEmployeeTable() 
	SetEmployee(Undefined);
	EmployeeOperationsTypeText = "";
	Employee.Clear();	
			
	vFirst = True;	
	vEmpOperations = "";
	vEmpOperationsCount = 0;
	vEmpOperationsDuration = 0;
	vEmpRoomSpace = 0;
	vEmpPrice = 0;
	vNewOperations = Operations.Unload();
	vNewOperations.GroupBy("Employee, Operation", "Count, Duration, RoomSpace, Price");
	For Each vEmployeeRow In EmployeeList Do
		If vFirst Then			
			CurrentEmployee = vEmployeeRow.Value; 
			vFirst          = False;
		EndIf;
		vEmpRow            = Employee.Add();
		vEmpRow.Employee   = vEmployeeRow.Value;
		
		vOperationsByEmployee = vNewOperations.FindRows(New Structure("Employee", vEmployeeRow.Value));
		For Each vOperationsRow In vOperationsByEmployee Do
			If ValueIsFilled(vOperationsRow.Operation) Then
				vEmpOperationsCount = vEmpOperationsCount + vOperationsRow.Count;
				vEmpOperations = vEmpOperations + TrimAll(vOperationsRow.Operation.Code) + " = " + vOperationsRow.Count + "; ";
				vEmpOperationsDuration = vEmpOperationsDuration + vOperationsRow.Duration;
				vEmpRoomSpace = vEmpRoomSpace + vOperationsRow.Duration;
				vEmpPrice = vEmpPrice + vOperationsRow.Duration;
			EndIf;	
		EndDo;
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
	EndDo;
	
	EmployeesHead2 = NStr("en='Count: '; ru='Всего: '; de='Anzahl: '") + EmployeeList.Count();
	
	If ValueIsFilled(CurrentEmployee) Then
		SetEmployee(CurrentEmployee);
	EndIf;
EndProcedure // FillEmployeeTable

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEmployeeOperations(pEmployee)
	EmployeeOperationsTypeText = "";
	vEmployeeDuration = 0;
	vTotalRoomSpace = 0;
	vTotalPrice = 0;
	EmployeeOperations.Clear();
	If ValueIsFilled(pEmployee) Then
		vOperationsByEmployee = Operations.FindRows(New Structure("Employee", pEmployee));
		For Each vOperationsRow In vOperationsByEmployee Do
			If ValueIsFilled(vOperationsRow.Operation) Then  
				vNewRow = EmployeeOperations.Add();
				vNewRow.Room = vOperationsRow.Room;
				vNewRow.RoomType = vOperationsRow.RoomType;
				vNewRow.Operation = vOperationsRow.Operation;		
				vNewRow.Count = vOperationsRow.Count;
				If vOperationsRow.IsCheckInWaiting = True Then 
					vNewRow.CheckInWaitingIcon = 41;
				Else
					vNewRow.CheckInWaitingIcon = 0;	
				EndIf;
				vNewRow.RoomStatusIcon = cmGetRoomStatusIcon(vOperationsRow.Room.RoomStatus);
				vNewRow.Duration = vOperationsRow.Duration;
				
				vEmployeeDuration = vEmployeeDuration + vOperationsRow.Duration;
				vTotalRoomSpace = vTotalRoomSpace + vOperationsRow.RoomSpace;
				vTotalPrice = vTotalPrice + vOperationsRow.Price;
				vNewRow.UUID = vOperationsRow.UUID;
			EndIf;
		EndDo;
		vT = EmployeeOperations.Unload(, "Operation, Count");
		vT.GroupBy("Operation", "Count");
		For Each vRow In vT Do
			EmployeeOperationsTypeText = EmployeeOperationsTypeText + TrimAll(vRow.Operation.Code) + " = " + vRow.Count + "; "; 
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
	EndIf;
EndProcedure // FillEmployeeOperations

// -----------------------------------------------------------------------------
&AtServer
Procedure FillNotAssignedOperations()
	NotAssignedOperations.Clear();
	vOperationsByEmployee = Operations.FindRows(New Structure("Employee", Catalogs.Employees.EmptyRef()));
	For Each vOperationsRow In vOperationsByEmployee Do
		If ValueIsFilled(vOperationsRow.Operation) Then 
			vNewRow = NotAssignedOperations.Add();
			vNewRow.Room = vOperationsRow.Room;
			vNewRow.RoomType = vOperationsRow.RoomType;
			vNewRow.Operation = vOperationsRow.Operation;
			vNewRow.Count = vOperationsRow.Count;
			If vOperationsRow.IsCheckInWaiting = True Then 
				vNewRow.CheckInWaitingIcon = 41;
			Else
				vNewRow.CheckInWaitingIcon = 0;	
			EndIf;
			vNewRow.RoomStatusIcon = cmGetRoomStatusIcon(vOperationsRow.Room.RoomStatus);
			vNewRow.Duration = vOperationsRow.Duration;
			vNewRow.UUID = vOperationsRow.UUID; 
		EndIf;
	EndDo;	
	
	vT = NotAssignedOperations.Unload(, "Operation, Count");
	vT.GroupBy("Operation", "Count");
	
	NotAssignedOperationsTypeText = "";	
	For Each vRow In vT Do
		NotAssignedOperationsTypeText = NotAssignedOperationsTypeText + TrimAll(vRow.Operation.Code) + " = " + vRow.Count + "; "; 
	EndDo;
EndProcedure // FillNotAssignedOperations

// -----------------------------------------------------------------------------
&AtServer
Function WorkOnAtServer(pUUID)
	vResult = True;
	vOperationsRows = Operations.FindRows(New Structure("UUID", pUUID));
	If vOperationsRows.Count() > 0 Then
		vOperationsRow = vOperationsRows.Get(0);
		vOperationsRow.Employee = CurrentEmployee;
		// Get operation standards
		If ValueIsFilled(vOperationsRow.Operation) Then
			vStds = Catalogs.Operations.GetOperationStandards(vOperationsRow.Operation, Hotel, vOperationsRow.RoomType, vOperationsRow.Room, vOperationsRow.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vOperationsRow.Duration = vStdsRow.Duration;
				vOperationsRow.RoomSpace = vStdsRow.RoomSpace;
				vOperationsRow.Price = vStdsRow.Price;
			EndIf;
		EndIf;
	Else
		vResult = False;	
	EndIf;
	Return vResult;
EndFunction // WorkOnAtServer

// -----------------------------------------------------------------------------
&AtServer
Function WorkOutAtServer(pUUID)
	vResult = True;
	vOperationsRows = Operations.FindRows(New Structure("UUID", pUUID));
	If vOperationsRows.Count() > 0 Then
		vOperationsRow = vOperationsRows.Get(0);
		vOperationsRow.Employee = Catalogs.Employees.EmptyRef();
		// Get operation standards
		If ValueIsFilled(vOperationsRow.Operation) Then
			vStds = Catalogs.Operations.GetOperationStandards(vOperationsRow.Operation, Hotel, vOperationsRow.RoomType, vOperationsRow.Room, vOperationsRow.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vOperationsRow.Duration = vStdsRow.Duration;
				vOperationsRow.RoomSpace = vStdsRow.RoomSpace;
				vOperationsRow.Price = vStdsRow.Price;
			EndIf;
		EndIf;
	Else
		vResult = False;	
	EndIf;
	Return vResult;
EndFunction // WorkOutAtServer

#EndRegion
