// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ThisForm.ReadOnly = True;
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		If Not SessionParameters.CurrentHotel.Vauchers Then
			Items.GroupHotelVouchers.Visible = False;
		EndIf;
	EndIf;

	// Form appearance
	SetFormAppearance();
	
	// Tourist tax (RU)
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		If SessionParameters.CurrentHotel.TouristTaxIsUsed Then
			Items.GroupTouristTax.Visible = True;
		Else
			Items.GroupTouristTax.Visible = False;
		EndIf;
	Else
		Items.GroupTouristTax.Visible = True;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearance()
	If Object.AutoGenerationOfVoucherNumbers Then
		Items.VoucherType.Enabled = True;
	Else
		Items.VoucherType.Enabled = False;
		If ValueIsFilled(Object.VoucherType) Then
			Object.VoucherType = Undefined;
		EndIf;
	EndIf;
EndProcedure // SetFormAppearance

// --------------------------------------------------------------------------------
&AtClient
Procedure AutoGenerationOfVoucherNumbersOnChange(pItem)
	SetFormAppearance();
EndProcedure // AutoGenerationOfVoucherNumbersOnChange
