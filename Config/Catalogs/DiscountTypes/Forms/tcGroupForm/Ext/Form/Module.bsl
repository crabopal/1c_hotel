
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use item
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
		Else
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

