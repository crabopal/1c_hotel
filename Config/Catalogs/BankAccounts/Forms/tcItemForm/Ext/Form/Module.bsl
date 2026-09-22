
#Region FormEventHandlers

// ----------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Fill default parameters
	If Not cmCheckUserPermissions("HavePermissionToEditCustomer") Then
		ReadOnly = True;
	EndIf;
	If Not ValueIsFilled(Object.Ref) Then
		If IsBlankString(Object.AccountNumber) Then
			Object.IsDirectPayments = True;
			If IsBlankString(Object.Description) Then
				Object.Description = NStr("en = 'Main'; de = 'Grundlegend'; ru = 'Основной'");
			EndIf;
			If Not ValueIsFilled(Object.AccountCurrency) Then
				If ValueIsFilled(Object.Owner) And 
					TypeOf(Object.Owner) = Type("CatalogRef.Customers") Then
					AccountCurrency = Object.Owner.AccountingCurrency;
				EndIf;
				If Not ValueIsFilled(Object.AccountCurrency) Then
					If ValueIsFilled(SessionParameters.CurrentHotel) Then
						Object.AccountCurrency = SessionParameters.CurrentHotel.BaseCurrency;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If Parameters.Property("Owner") Then
			Object.Owner = Parameters.Owner;
		EndIf;
	EndIf;
	SetAttributesAppearance();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// ----------------------------------------------------------------------------------
&AtClient
Procedure IsDirectPaymentsOnChange(pItem)
	SetAttributesAppearance();
EndProcedure

// ----------------------------------------------------------------------------------
&AtClient
Procedure BankAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	pStandardProcessing = False;
	#If Not WebClient And Not MobileClient Then
		FillAddresDadata(pText, pChoiceData);
		If pChoiceData = Undefined Or TypeOf(pChoiceData) = Type("ValueList") And pChoiceData.Count() = 0 Then
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;	
	#Else
		pStandardProcessing = True;
		pChoiceData = Undefined;
	#EndIf
	Modified = True;
EndProcedure

// ----------------------------------------------------------------------------------
&AtClient
Procedure BankTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	pStandardProcessing = False;
	#If Not WebClient And Not MobileClient Then
		FillAddresDadata(pText, pChoiceData);
		If pChoiceData = Undefined Or TypeOf(pChoiceData) = Type("ValueList") And pChoiceData.Count() = 0 Then
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;	
	#Else
		pStandardProcessing = True;
		pChoiceData = Undefined;
	#EndIf
	Modified = True;
EndProcedure

// ----------------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If TypeOf(pSelectedValue) = Type("Structure") Then
		pStandardProcessing = False;
		Try
		   Object.BankName = ?(IsBlankString(pSelectedValue.name.short), pSelectedValue.name.payment, pSelectedValue.name.short);
		   Object.BankCity = pSelectedValue.payment_city;
		   Object.BankBIC  = pSelectedValue.bic;
		   Object.BankTINCode  = pSelectedValue.inn;
		   Object.BankSWIFTCode  = pSelectedValue.swift;
		   Object.BankCorrAccountNumber  = pSelectedValue.correspondent_account;
		Except	
		EndTry;
	EndIf;
EndProcedure

#EndRegion

#Region Private

// ----------------------------------------------------------------------------------
Procedure SetAttributesAppearance()
	If Object.IsDirectPayments Then
		Items.CorrBankBIC.Enabled = False;
		Items.CorrBankCity.Enabled = False;
		Items.CorrBankCorrAccountNumber.Enabled = False;
		Items.CorrBankName.Enabled = False;
		Items.CorrBankSWIFTCode.Enabled = False;
		Items.CorrBankTINCode.Enabled = False;
	Else
		Items.CorrBankBIC.Enabled = True;
		Items.CorrBankCity.Enabled = True;
		Items.CorrBankCorrAccountNumber.Enabled = True;
		Items.CorrBankName.Enabled = True;
		Items.CorrBankSWIFTCode.Enabled = True;
		Items.CorrBankTINCode.Enabled = True;
	EndIf;
EndProcedure // SetAttributesAppearance

// ----------------------------------------------------------------------------------
&AtClient
Procedure FillAddresDadata(Val pText, pList)
	If StrLen(pText) >= 4 Then
		pList = GetAddressFromDadata(pText);
	EndIf;
EndProcedure

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function GetAddressFromDadata(pText)
	Return cmGetDataFromDadata(TrimAll(pText), "bank");
EndFunction	

#EndRegion
