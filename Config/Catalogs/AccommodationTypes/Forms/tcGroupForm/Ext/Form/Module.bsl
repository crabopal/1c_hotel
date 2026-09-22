
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
		ElsIf Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
		EndIf;
		If NOT pCancel Then
			vObj 			= FormAttributeToValue("Object", Type("CatalogObject.AccommodationTypes"));
			vObj.SortCode 	= vObj.pmSetSortCode(); 
			ValueToFormAttribute(vObj, "Object");
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		ReadOnly = True;
	ElsIf Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	vResultAtServer = BeforeWrite_AtServer();
	pCancel 		= vResultAtServer.Cancel;
	If ValueIsFilled(vResultAtServer.ErrorText) And ValueIsFilled(vResultAtServer.ErrorField) Then
		vMessage 		= New UserMessage;
		vMessage.Field 	= "Object." + vResultAtServer.ErrorField;
		vMessage.Text 	= NStr(vResultAtServer.ErrorText);
		vMessage.Message();
		Return;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function BeforeWrite_AtServer()
	vResult = New Structure("Cancel, ErrorField, ErrorText", False, "", "");
	vObj = FormAttributeToValue("Object", Type("CatalogObject.AccommodationTypes"));
	vResult.Cancel = vObj.pmCheckAccommodationTypeAttributes(vResult.ErrorText, vResult.ErrorField);
	Return vResult;
EndFunction

#EndRegion
