
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use group
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
		EndIf;
		// Fill attributes with default values
		If Not ValueIsFilled(Object.Owner) Then
			vObj = FormAttributeToValue("Object",Type("CatalogObject.RoomTypes"));
			vObj.pmFillAttributesWithDefaultValues();
			vObj.Write();
			ValueToFormAttribute(vObj,"Object");
		EndIf;
	EndIf;
	// Check user rights to edit room type
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		ThisForm.ReadOnly = True;
	EndIf;

EndProcedure

#EndRegion
