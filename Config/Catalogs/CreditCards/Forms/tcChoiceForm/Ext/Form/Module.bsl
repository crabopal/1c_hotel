
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToViewCreditCardsData") Then
		pCancel = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.List.ChangeRowSet = False;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
