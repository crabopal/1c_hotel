
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
		ElsIf Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
		EndIf;
		If NOT pCancel Then
			vObj 			= FormAttributeToValue("Object",Type("CatalogObject.AccommodationTypes"));
			vObj.SortCode 	= vObj.pmSetSortCode(); 
			ValueToFormAttribute(vObj, "Object");
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		ReadOnly = True;
	ElsIf Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;
	If Not ReadOnly Then
		If Object.PostToRoomMainFolio Then
			Items.DoNotCreatePersonalFolios.Enabled = True;
		Else
			Object.DoNotCreatePersonalFolios 		= False;
			Items.DoNotCreatePersonalFolios.Enabled = False;
		EndIf;
	EndIf;
	
	// Tourist tax (RU)
	If ValueIsFilled(Object.Hotel) Then
		If Object.Hotel.TouristTaxIsUsed Then
			Items.GroupTouristTax.Visible = True;
		Else
			Items.GroupTouristTax.Visible = False;
		EndIf;
	Else
		Items.GroupTouristTax.Visible = True;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Not ValueIsFilled(Object.Type) Then
		pCancel = True;  
		vMsg = NStr("en = 'Type should be filled!'; de = 'Typ muss ausgefüllt werden!'; ru = 'Тип должен быть заполнен!'");
		tcCommonFunctionOnClientServer.UserMessage(vMsg, , "Object.Type");
		Return;
	EndIf;
	
	vResultAtServer = BeforeWrite_AtServer();
	pCancel 		= vResultAtServer.Cancel;
	If ValueIsFilled(vResultAtServer.ErrorText) And ValueIsFilled(vResultAtServer.ErrorField) Then  
		tcCommonFunctionOnClientServer.UserMessage(NStr(vResultAtServer.ErrorText), , "Object." + vResultAtServer.ErrorField);
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

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If Not ReadOnly Then
		OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations) , pItem, ThisObject, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PostToRoomMainFolioOnChange(pItem)
	If Object.PostToRoomMainFolio Then
		Items.DoNotCreatePersonalFolios.Enabled = True;
	Else
		Object.DoNotCreatePersonalFolios 		= False;
		Items.DoNotCreatePersonalFolios.Enabled = False;
	EndIf;
EndProcedure

#EndRegion
