
// -----------------------------------------------------------------------------
&AtServer
Procedure ActionSliceLastAtServer()
	If Not Items.FormActionSliceLast.Check Then
		List.MainTable = "InformationRegister.EmployeeOperationsHistory.SliceLast";
		Items.FormActionSliceLast.Check = True;
	Else
		List.MainTable = "InformationRegister.EmployeeOperationsHistory";
		Items.FormActionSliceLast.Check = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionSliceLast(pCommand)
	ActionSliceLastAtServer();
EndProcedure // ActionSliceLast
