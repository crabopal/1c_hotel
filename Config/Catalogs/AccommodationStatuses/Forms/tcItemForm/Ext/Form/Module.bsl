
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Check permissions
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManageRoomInventory") And Object.Ref.IsEmpty() Then 
		vMsg = NStr("en='You do not have rights for room inventory management!';
					|ru='Нет прав на управление номерным фондом!';
					|de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
		pCancel = True;
		Return;
	EndIf;	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);  
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManageRoomInventory") Then     
		vMsg = NStr("en='You do not have rights for room inventory management!';
					|ru='Нет прав на управление номерным фондом!';
					|de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'");
		ShowMessageBox(, vMsg);
		ReadOnly = True;
	EndIf;	
EndProcedure

#EndRegion
