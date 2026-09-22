// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user permissions
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		If ValueIsFilled(Object.Ref) Then
			ThisObject.ReadOnly = True;
		Else
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure
