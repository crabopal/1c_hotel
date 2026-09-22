
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;

	// Check user rights to use item
	If Object.Ref.IsEmpty() Then
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
		EndIf;
	EndIf;

	// Check user rights to edit service
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;

	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Form appearance
	ApplyFormAppearance();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations), pItem);
EndProcedure // DescriptionTranslationsOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure ConfirmationTextOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.ConfirmationText), pItem);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ConfirmationTextForGuaranteedReservationOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.ConfirmationTextForGuaranteedReservation), pItem);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NoShowChargeWholePeriodOnChange(pItem)
	If Object.NoShowChargeWholePeriod Then
		If Object.NoShowChargeNDays <> 0 Then
			Object.NoShowChargeNDays = 0;
		EndIf;
	EndIf;
	ApplyFormAppearance();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NoShowChargeNDaysOnChange(pItem)
	If Object.NoShowChargeNDays <> 0 Then
		If Object.NoShowChargeWholePeriod Then
			Object.NoShowChargeWholePeriod = False;
		EndIf;
	EndIf;
	ApplyFormAppearance();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ApplyFormAppearance()
	If Object.NoShowChargeWholePeriod Then
		Items.NoShowChargeNDays.Enabled = False;
	Else
		Items.NoShowChargeNDays.Enabled = True;
	EndIf;
	If Object.NoShowChargeNDays <> 0 Then
		Items.NoShowChargeWholePeriod.Enabled = False;
	Else
		Items.NoShowChargeWholePeriod.Enabled = True;
	EndIf;
EndProcedure // ApplyFormAppearance

#EndRegion