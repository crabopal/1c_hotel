// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManagePrices") Then
		pCancel = True;
		ShowMessageBox(, NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
	EndIf;
EndProcedure
