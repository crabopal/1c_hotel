#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Settlement
	If Object.Ref = Catalogs.PaymentMethods.Settlement Then
		If Not Object.IsByBankTransfer Then
			Object.IsByBankTransfer = True;
			ThisObject.Modified = True;
		EndIf;
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	VisibilityManaging();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations), pItem);	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BookByCashRegisterOnChange(Item)
	VisibilityManaging();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsByCashOnChange(Item)
	If Object.IsByCash Then
		If Object.IsViaInternetAcquiring Then
			Object.IsViaInternetAcquiring = False;
		EndIf;
		If Object.IsByCreditCard Then
			Object.IsByCreditCard = False;
		EndIf;
		If Object.IsByBankTransfer Then
			Object.IsByBankTransfer = False;
		EndIf;
		If Object.IsByBonuses Then
			Object.IsByBonuses = False;
		EndIf;
		If Object.IsByGiftCertificate Then
			Object.IsByGiftCertificate = False;
		EndIf;
		If Object.IsCloseToTheRoom Then
			Object.IsCloseToTheRoom = False;
		EndIf;
		If Object.IsCloseToTheFolio Then
			Object.IsCloseToTheFolio = False;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsViaInternetAcquiringOnChange(Item)
	If Object.IsViaInternetAcquiring Then
		If Object.IsByCash Then
			Object.IsByCash = False;
		EndIf;
		If Object.IsByCreditCard Then
			Object.IsByCreditCard = False;
		EndIf;
		If Object.IsByBankTransfer Then
			Object.IsByBankTransfer = False;
		EndIf;
		If Object.IsByBonuses Then
			Object.IsByBonuses = False;
		EndIf;
		If Object.IsByGiftCertificate Then
			Object.IsByGiftCertificate = False;
		EndIf;
		If Object.IsCloseToTheRoom Then
			Object.IsCloseToTheRoom = False;
		EndIf;
		If Object.IsCloseToTheFolio Then
			Object.IsCloseToTheFolio = False;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsByCreditCardOnChange(Item)
	If Object.IsByCreditCard Then
		If Object.IsByCash Then
			Object.IsByCash = False;
		EndIf;
		If Object.IsViaInternetAcquiring Then
			Object.IsViaInternetAcquiring = False;
		EndIf;
		If Object.IsByBankTransfer Then
			Object.IsByBankTransfer = False;
		EndIf;
		If Object.IsByBonuses Then
			Object.IsByBonuses = False;
		EndIf;
		If Object.IsByGiftCertificate Then
			Object.IsByGiftCertificate = False;
		EndIf;
		If Object.IsCloseToTheRoom Then
			Object.IsCloseToTheRoom = False;
		EndIf;
		If Object.IsCloseToTheFolio Then
			Object.IsCloseToTheFolio = False;
		EndIf;
	EndIf;
	VisibilityManaging();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsByBankTransferOnChange(Item)
	If Object.IsByBankTransfer Then
		If Object.IsByCash Then
			Object.IsByCash = False;
		EndIf;
		If Object.IsViaInternetAcquiring Then
			Object.IsViaInternetAcquiring = False;
		EndIf;
		If Object.IsByCreditCard Then
			Object.IsByCreditCard = False;
		EndIf;
		If Object.IsByBonuses Then
			Object.IsByBonuses = False;
		EndIf;
		If Object.IsByGiftCertificate Then
			Object.IsByGiftCertificate = False;
		EndIf;
		If Object.IsCloseToTheRoom Then
			Object.IsCloseToTheRoom = False;
		EndIf;
		If Object.IsCloseToTheFolio Then
			Object.IsCloseToTheFolio = False;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsByBonusesOnChange(Item)
	If Object.IsByBonuses Then
		If Object.IsByCash Then
			Object.IsByCash = False;
		EndIf;
		If Object.IsViaInternetAcquiring Then
			Object.IsViaInternetAcquiring = False;
		EndIf;
		If Object.IsByCreditCard Then
			Object.IsByCreditCard = False;
		EndIf;
		If Object.IsByBankTransfer Then
			Object.IsByBankTransfer = False;
		EndIf;
		If Object.IsByGiftCertificate Then
			Object.IsByGiftCertificate = False;
		EndIf;
		If Object.IsCloseToTheRoom Then
			Object.IsCloseToTheRoom = False;
		EndIf;
		If Object.IsCloseToTheFolio Then
			Object.IsCloseToTheFolio = False;
		EndIf;
	EndIf;
	VisibilityManaging();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsCloseToTheFolioOnChange(Item)
	If Object.IsCloseToTheFolio Then
		If Object.IsByCash Then
			Object.IsByCash = False;
		EndIf;
		If Object.IsViaInternetAcquiring Then
			Object.IsViaInternetAcquiring = False;
		EndIf;
		If Object.IsByCreditCard Then
			Object.IsByCreditCard = False;
		EndIf;
		If Object.IsByBankTransfer Then
			Object.IsByBankTransfer = False;
		EndIf;
		If Object.IsByBonuses Then
			Object.IsByBonuses = False;
		EndIf;
		If Object.IsByGiftCertificate Then
			Object.IsByGiftCertificate = False;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsForExtraServiceFolioOnlyOnChange(Item)
	VisibilityManaging();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsCloseToTheRoomOnChange(Item)
	If Object.IsCloseToTheRoom Then
		If Object.IsByCash Then
			Object.IsByCash = False;
		EndIf;
		If Object.IsViaInternetAcquiring Then
			Object.IsViaInternetAcquiring = False;
		EndIf;
		If Object.IsByCreditCard Then
			Object.IsByCreditCard = False;
		EndIf;
		If Object.IsByBankTransfer Then
			Object.IsByBankTransfer = False;
		EndIf;
		If Object.IsByBonuses Then
			Object.IsByBonuses = False;
		EndIf;
		If Object.IsByGiftCertificate Then
			Object.IsByGiftCertificate = False;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsByGiftCertificateOnChange(Item)
	If Object.IsByGiftCertificate Then
		If Object.IsByCash Then
			Object.IsByCash = False;
		EndIf;
		If Object.IsViaInternetAcquiring Then
			Object.IsViaInternetAcquiring = False;
		EndIf;
		If Object.IsByCreditCard Then
			Object.IsByCreditCard = False;
		EndIf;
		If Object.IsByBankTransfer Then
			Object.IsByBankTransfer = False;
		EndIf;
		If Object.IsByBonuses Then
			Object.IsByBonuses = False;
		EndIf;
		If Object.IsCloseToTheRoom Then
			Object.IsCloseToTheRoom = False;
		EndIf;
		If Object.IsCloseToTheFolio Then
			Object.IsCloseToTheFolio = False;
		EndIf;
	EndIf;
	VisibilityManaging();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DeliveryTypeOnChange(Item)
	If Object.DeliveryType = PredefinedValue("Enum.DeliveryTypes.Unisender") Then
		Object.DeliveryType = Undefined;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterChequeCloseTypeOnChange(Item)
	VisibilityManaging();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintChequeOnChange(Item)
	If Object.PrintCheque Then
		Object.ChequesArePrintedAtExternalCashRegister = False;
	EndIf;
	VisibilityManaging();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChequesArePrintedAtExternalCashRegisterOnChange(pItem)
	If Object.ChequesArePrintedAtExternalCashRegister Then
		Object.PrintCheque = False;
	EndIf;
	VisibilityManaging();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalSystemOnChange(pItem)
	FillDiscountTypeByExternalSystem();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDiscountTypeByExternalSystem()
	Object.DiscountType = Catalogs.DiscountTypes.EmptyRef();
	Try
		If ValueIsFilled(Object.ExternalSystem) Then
			Object.DiscountType = Object.ExternalSystem.DiscountType;	
		EndIf;
	Except
		Object.DiscountType = Catalogs.DiscountTypes.EmptyRef();
	EndTry;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FillChequeTemplate(Command)
	vTemplate = TrimAll(Object.NonFiscalChequeTemplate);
	If IsBlankString(vTemplate) Then
		vTemplate = 
		"&Document
		|&CurrentDate &CurrentTime
		|&Hotel
		|&Cashier
		|&FolioHeader
		|&Type
		|Сумма с НДС &VATRate = &Amount
		|--------------------------------------------------------------------------------
		|
		|Подпись: _____________________
		|
		|&Cliche";
	EndIf;
	
	ShowInputString(New NotifyDescription("AfterFillChequeTemplate", ThisObject), vTemplate, NStr("en='Input cheque template'; ru='Введите шаблон чека'; de='Kassenbon template'"), 0, True);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure  AfterFillChequeTemplate(pAnswer, pAddParams) Export 
	If Not pAnswer = Undefined And ValueIsFilled(pAnswer) Then
		Object.NonFiscalChequeTemplate = TrimAll(pAnswer);
	EndIf;	
EndProcedure	

// -----------------------------------------------------------------------------
&AtClient
Procedure VisibilityManaging()
	If Object.IsByBonuses Then
		Items.GroupBonusesRule.Enabled = True;
	Else
		Items.GroupBonusesRule.Enabled = False;
		If ValueIsFilled(Object.DiscountType) Then
			Object.DiscountType = PredefinedValue("Catalog.DiscountTypes.EmptyRef");
		EndIf;
	EndIf;
	If Object.BookByCashRegister Then
		Items.PrintCheque.Enabled = True;
		Items.CashRegisterCode.Enabled = True;
		If Object.PrintCheque Then
			Items.CashRegisterChequeCloseType.Enabled = True;
			Items.ElectronicChequeOnly.Enabled = True;
			Items.ChequePaymentMode.Enabled = True;
			Items.PrintNonFiscalCheque.Enabled = True;
			Items.ChequesArePrintedAtExternalCashRegister.Enabled = False;
			If Object.ChequesArePrintedAtExternalCashRegister Then
				Object.ChequesArePrintedAtExternalCashRegister = False;
			EndIf;
		Else
			Items.CashRegisterChequeCloseType.Enabled = False;
			Items.ElectronicChequeOnly.Enabled = False;
			If Object.ElectronicChequeOnly Then
				Object.ElectronicChequeOnly = False;
			EndIf;
			Items.ChequePaymentMode.Enabled = False;
			Items.PrintNonFiscalCheque.Enabled = False;
			If Object.PrintNonFiscalCheque Then
				Object.PrintNonFiscalCheque = False;
			EndIf;
			Items.ChequesArePrintedAtExternalCashRegister.Enabled = True;
		EndIf;
	Else
		Items.PrintCheque.Enabled = False;
		If Object.PrintCheque Then
			Object.PrintCheque = False;
		EndIf;
		Items.CashRegisterChequeCloseType.Enabled = False;
		Items.ElectronicChequeOnly.Enabled = False;
		If Object.ElectronicChequeOnly Then
			Object.ElectronicChequeOnly = False;
		EndIf;
		Items.ChequePaymentMode.Enabled = False;
		Items.PrintNonFiscalCheque.Enabled = False;
		If Object.PrintNonFiscalCheque Then
			Object.PrintNonFiscalCheque = False;
		EndIf;
		Items.FillChequeTemplate.Enabled = False;
		Items.CashRegisterCode.Enabled = False;
		If Object.CashRegisterCode <> 0 Then
			Object.CashRegisterCode = 0;
		EndIf;
		Items.ChequesArePrintedAtExternalCashRegister.Enabled = True;
	EndIf;
	If Object.ChequesArePrintedAtExternalCashRegister Then
		Items.ChequesArePrintedAtExternalCashRegister.Enabled = True;
		Items.PrintCheque.Enabled = False;
		If Object.PrintCheque Then
			Object.PrintCheque = False;
		EndIf;
		Items.CashRegisterChequeCloseType.Enabled = False;
		Items.ElectronicChequeOnly.Enabled = False;
		If Object.ElectronicChequeOnly Then
			Object.ElectronicChequeOnly = False;
		EndIf;
		Items.ChequePaymentMode.Enabled = False;
		Items.PrintNonFiscalCheque.Enabled = False;
		If Object.PrintNonFiscalCheque Then
			Object.PrintNonFiscalCheque = False;
		EndIf;
	EndIf;
	If Object.IsByCreditCard Then
		Items.ExternalBankTerminalIsUsed.Enabled = True;
		Items.ReferenceCodeIsRequired.Enabled = True;
		Items.AuthorizationCodeIsRequired.Enabled = True;
		Items.CardType.Enabled = True;
		Items.CardOwner.Enabled = True;
	Else
		Items.ExternalBankTerminalIsUsed.Enabled = False;
		Items.ReferenceCodeIsRequired.Enabled = False;
		Items.AuthorizationCodeIsRequired.Enabled = False;
		Items.CardType.Enabled = False;
		Items.CardOwner.Enabled = False;
	EndIf;
	If Object.IsByBonuses Or Object.IsByGiftCertificate Or Object.IsByCreditCard Then 
		Items.ExternalSystem.Enabled = True;
	Else
		Items.ExternalSystem.Enabled = False;
	EndIf;	
EndProcedure	

#EndRegion
