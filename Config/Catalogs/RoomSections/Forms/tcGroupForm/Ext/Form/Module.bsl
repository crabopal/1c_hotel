
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to edit item
	If Not cmCheckUserPermissions("HavePermissionToManageHousekeeping") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit housekeeping settings!';ru='Нет прав на управление службой горничных!';de='Sie haben keine Rechte, die Einstellungen des Reinigungsdienstes zu verwalten!'"));
			Return;
		Else
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
EndProcedure // OnCreateAtServer

#EndRegion

