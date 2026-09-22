
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use item
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for prices management!';ru='Нет прав на управление ценами!';de='Sie haben keine Rechte, Preise zu verwalten!'"));
		EndIf;
	Else
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

