
// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.List.ChangeRowSet = False;
	EndIf; 
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionSliceLastAtServer()
	If Not Items.FormActionSliceLast.Check Then
		List.MainTable = "InformationRegister.ServicePackageRecords.SliceLast";
		Items.FormActionSliceLast.Check = True;
	Else
		List.MainTable = "InformationRegister.ServicePackageRecords";
		Items.FormActionSliceLast.Check = False;
	EndIf;     
EndProcedure // ActionSliceLastAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionSliceLast(pCommand)
	ActionSliceLastAtServer();
EndProcedure // ActionSliceLast   
