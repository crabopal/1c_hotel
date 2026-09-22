
#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeeOnChange(pItem)
	EmployeeOnChangeAtServer();
EndProcedure


#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure EmployeeOnChangeAtServer()
	If ValueIsFilled(Record.Employee) Then
		If Not ValueIsFilled(Record.Department) Then
			Record.Department = Record.Employee.Department;
		EndIf;
		If Not ValueIsFilled(Record.RoomSection) Then
			Record.RoomSection = Record.Employee.RoomSection;
		EndIf;
		If Not ValueIsFilled(Record.Hotel) Then
			If ValueIsFilled(Record.Employee.Hotel) Then
				Record.Hotel = Record.Employee.Hotel;
			Else
				Record.Hotel = SessionParameters.CurrentHotel;
			EndIf;
		EndIf;
	EndIf; 
EndProcedure

#EndRegion
