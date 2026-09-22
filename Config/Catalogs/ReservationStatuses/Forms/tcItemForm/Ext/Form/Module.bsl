
#Region FormEventHandlers

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManageRoomInventory") And Object.Ref.IsEmpty() Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
		pCancel = True;
	EndIf;	
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Reservation status color
	vColor = GetColor();
	If vColor <> Undefined Then
		ItemColor = vColor;
		ItemColorIsSet = True;
		Items.FormSetColor.BackColor = vColor;
	Else
		ItemColor = Undefined;
		ItemColorIsSet = False;
	EndIf;
	
	// Visibility
	DeliveryTypeOnChangeAtServer();
EndProcedure // OnCreateAtServer

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManageRoomInventory") Then
		ShowMessageBox(,NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
		ReadOnly = True;
	EndIf;	
	RefreshDisplay()
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If ItemColorIsSet Then
		pCurrentObject.ColorHexString = tcOnServer.ColorToHex(ItemColor);
		pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(pCurrentObject.ColorHexString));
	Else
		pCurrentObject.ColorHexString = "";
		pCurrentObject.Color = Undefined;
	EndIf;
EndProcedure // BeforeWriteAtServer


#EndRegion

#Region FormHeaderItemsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm",New Structure("Text",Object.DescriptionTranslations), pItem);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ReservationConditionsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm",New Structure("Text", Object.ReservationConditions), pItem);
EndProcedure // ReservationConditionsOpening

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure DeliveryTypeOnChange(pItem)
	DeliveryTypeOnChangeAtServer();
EndProcedure // DeliveryTypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = ItemColor;
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisObject))
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	ItemColor = Undefined;
	ItemColorIsSet = False;
	Items.FormSetColor.BackColor = Items.FormClearColor.BackColor;
EndProcedure // ClearColor

#EndRegion

#Region Private

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure RefreshDisplay()
	If Not Object.IsActive And Not Object.IsCheckIn Then
		Items.IsAnnulation.Enabled = True;
	Else
		Items.IsAnnulation.Enabled = False;
		If Object.IsAnnulation Then
			Object.IsAnnulation = False;
		EndIf;
	EndIf;
	If Object.DoCharging Then
		Items.DoChargingIfRoomIsFilled.Enabled = True;
		Items.AlwaysChargeInAdvanceServicesOnly.Enabled = True;
		If Object.DoNotChargeForecastServices Then
			Object.DoNotChargeForecastServices = False;
		EndIf;
		Items.DoNotChargeForecastServices.Enabled = False;
	Else
		If Object.DoChargingIfRoomIsFilled Then
			Object.DoChargingIfRoomIsFilled = False;
		EndIf;
		Items.DoChargingIfRoomIsFilled.Enabled = False;
		Items.AlwaysChargeInAdvanceServicesOnly.Enabled = False;
		Items.DoNotChargeForecastServices.Enabled = True;
	EndIf;
	If Object.DoNotChargeForecastServices Then
		If Object.DoCharging Then
			Object.DoCharging = False;
		EndIf;
		Items.DoCharging.Enabled = False;
	Else
		Items.DoCharging.Enabled = True;
	EndIf;
EndProcedure // RefreshDisplay

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetColor()
	vColor = Undefined;
	If Not IsBlankString(Object.ColorHexString) Then
		vColor = tcOnServer.HexToColor(Object.ColorHexString);
		If TypeOf(vColor) <> Type("Color") Then
			vColor = Undefined;
		EndIf;
	EndIf;
	Return vColor;
EndFunction // GetColor

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		If pColor.Type = ColorType.WebColor Or pColor.Type = ColorType.Absolute Then
			ItemColor = pColor;
			ItemColorIsSet = True;
			Items.FormSetColor.BackColor = pColor;
		Else
			ShowMessageBox(, NStr("en='You can choose web or absolute colors only! Style and windows colors are not supported.';ru='Можете выбирать только абсолютные цвета (по названию или по RGB)! Выбор цветов из стилей не поддерживается.';de='Sie dürfen nur absolute Farben wählen (nach Bezeichnung oder nach RGB)! Die Farbenauswahl aus Stilen wird nicht unterstützt.'"));
		EndIf;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure DeliveryTypeOnChangeAtServer()
	If Object.DeliveryType = Enums.DeliveryTypes.EMail Or Object.DeliveryType = Enums.DeliveryTypes.Both Then
		Items.GroupPrintForms.Enabled = True;
	Else
		Items.GroupPrintForms.Enabled = False;
	EndIf;
	If Object.DeliveryType = Enums.DeliveryTypes.SMS Or Object.DeliveryType = Enums.DeliveryTypes.EMail Or 
	   Object.DeliveryType = Enums.DeliveryTypes.Both Or Object.DeliveryType = Enums.DeliveryTypes.Unisender Then
		Items.SMSTemplate.Enabled = True;
	Else
		Items.SMSTemplate.Enabled = False;
	EndIf;
EndProcedure // DeliveryTypeOnChangeAtServer

#EndRegion
