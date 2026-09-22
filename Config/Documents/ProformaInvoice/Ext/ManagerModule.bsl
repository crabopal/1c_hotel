
#Region Public

// -----------------------------------------------------------------------------
Procedure pmPrintPaymentOrder(pPaymentOrderSpreadsheet, pSelInvoice, pSelLanguage, pSelObjectPrintForm, pClear = True) Export 
	If Not ValueIsFilled(pSelLanguage) Then
		pSelLanguage = SessionParameters.CurrentLanguage;
	EndIf;

	// Choose template
	vInvObj = pSelInvoice.GetObject();
	If pClear Then
		pPaymentOrderSpreadsheet.Clear();
	EndIf;
	vTemplate = vInvObj.GetTemplate("PaymentOrderRu");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pSelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Print form parameter
	vParameter = Upper(TrimAll(pSelObjectPrintForm.Parameter));
	vPrintQRCode = (Find(vParameter, "SHOW_QRCODE") > 0);
	
	// Get template area
	vArea = vTemplate.GetArea("PaymentOrder");
	
	// Initialize area parameters
	mCompanyName = "";
	mCompanyBank = "";
	mCompanyBankAccount = "";
	mCompanyBankAttributes = "";
	mClientName = "";
	mClientAddress = "";
	mPaymentText = "";
	mSum = "";
	
	// Guest group code
	mGuestGroupCode = TrimAll(pSelInvoice.GuestGroup.Code);
	vHotelPrefix = Catalogs.Hotels.pmGetPrefix(pSelInvoice.Hotel);
	If Not IsBlankString(vHotelPrefix) And pSelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
		mGuestGroupCode = vHotelPrefix + mGuestGroupCode;
	EndIf;
	
	// Company
	If ValueIsFilled(pSelInvoice.Company) Then
		vCompanyObj = pSelInvoice.Company.GetObject();
		mCompanyName = vCompanyObj.pmGetCompanyPrintName(pSelLanguage);
		
		mCompanyTIN = TrimAll(vCompanyObj.TIN);
		mCompanyKPP = TrimAll(vCompanyObj.KPP);
		mCompanyCBC = TrimAll(vCompanyObj.KBK);
		mCompanyOKTMO = TrimAll(vCompanyObj.OKTMO);
		
		If ValueIsFilled(vCompanyObj.BankAccount) Then
			vAccount = vCompanyObj.BankAccount;
			mCompanyBank = vAccount.BankName;
			mCompanyBankAccount = vAccount.AccountNumber;
			mCompanyBankAttributes = "к/с №" + vAccount.BankCorrAccountNumber + " " + 
			                         TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity) + 
			                         " БИК " + TrimAll(vAccount.BankBIC) + " ИНН " + TrimAll(vCompanyObj.TIN);
		EndIf;
	EndIf;
	
	// Build table of all guest group services
	vServices = pSelInvoice.Services.Unload();
	vTotalSum = 0;
	vTotalCommissionSum = 0;
	If vServices <> Undefined Then
		vTotalSum = vServices.Total("Sum");
		vTotalVATSum = vServices.Total("VATSum");
		vTotalCommissionSum = vServices.Total("CommissionSum");
		If vTotalCommissionSum <> 0 And 
		   ValueIsFilled(pSelInvoice.AccountingCustomer) And Not pSelInvoice.AccountingCustomer.DoNotPostCommission Then
			vTotalSum = vTotalSum - vTotalCommissionSum;
		EndIf;
	EndIf;
	
	// Get payment order sum
	mSum = cmFormatSum(vTotalSum, pSelInvoice.AccountingCurrency);
	
	// No VAT
	vNoVAT = "";
	If vTotalVATSum = 0 Then
		vNoVAT = tcOnServer.cmNStrAtServer("en='. No VAT';de='. No VAT';ru='. Без НДС'", pSelLanguage);
	EndIf;
	
	// Payment text
	mPaymentText = NStr("en='Payment for invoice N';ru='Оплата счета №';de='Bezahlung der Rechnung Nr.'", pSelLanguage) + cmGetDocumentNumberPresentation(pSelInvoice.Number) + 
	               NStr("en=', reservation confirmation N';de=', reservation confirmation N';ru=', подтверждение брони №'", pSelLanguage) + mGuestGroupCode + vNoVAT + ".";
	
	// Client name and address
	If ValueIsFilled(pSelInvoice.AccountingCustomer) Then
		mClientName = TrimAll(pSelInvoice.AccountingCustomer.LegacyName);
		If IsBlankString(mClientName) Then
			mClientName = TrimAll(pSelInvoice.AccountingCustomer.Description);
		EndIf;
		vClientAddress = cmParseAddress(pSelInvoice.AccountingCustomer.LegacyAddress);
		mClientAddress = "";
		If ValueIsFilled(vClientAddress.PostCode) Then
			mClientAddress = vClientAddress.PostCode;
		EndIf;
		If ValueIsFilled(vClientAddress.Region) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vClientAddress.Region;
		EndIf;
		If ValueIsFilled(vClientAddress.Area) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vClientAddress.Area;
		EndIf;
		If ValueIsFilled(vClientAddress.City) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vClientAddress.City;
		EndIf;
		If ValueIsFilled(vClientAddress.Street) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vClientAddress.Street;
		EndIf;
		If ValueIsFilled(vClientAddress.House) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vClientAddress.House;
		EndIf;
		If ValueIsFilled(vClientAddress.Flat) Then
			mClientAddress = TrimAll(mClientAddress) + " " + vClientAddress.Flat;
		EndIf;
	EndIf;
	
	// Set parameters and put payment order section
	vArea.Parameters.mCompanyName = mCompanyName;
	vArea.Parameters.mCompanyBank = mCompanyBank;
	vArea.Parameters.mCompanyBankAccount = mCompanyBankAccount;
	vArea.Parameters.mCompanyBankAttributes = mCompanyBankAttributes;
	vArea.Parameters.mClientName = mClientName;
	vArea.Parameters.mClientAddress = mClientAddress;
	vArea.Parameters.mPaymentText = mPaymentText;
	vArea.Parameters.mSum = mSum;
	
	// Genarate QR-Code
	If vPrintQRCode Then
		vStructOutputData = New Structure;
		vStructOutputData.Insert("Name", 		mCompanyName);
		vStructOutputData.Insert("PersonalAcc", mCompanyBankAccount);
		vStructOutputData.Insert("CorrespAcc", 	vAccount.BankCorrAccountNumber);
		vStructOutputData.Insert("BankName", 	mCompanyBank);
		vStructOutputData.Insert("BIC", 		TrimAll(vAccount.BankBIC));
		vStructOutputData.Insert("Purpose", 	mPaymentText);
		vStructOutputData.Insert("PayeeINN", 	mCompanyTIN);
		vStructOutputData.Insert("KPP", 		mCompanyKPP);
		vStructOutputData.Insert("CBC", 		mCompanyCBC);
		vStructOutputData.Insert("OKTMO", 		mCompanyOKTMO);
		vStructOutputData.Insert("lastName",	mClientName);
		vStructOutputData.Insert("payerAddress",mClientAddress);
		vStructOutputData.Insert("contract", 	TrimAll(pSelInvoice.GuestGroup.Code)); 
		vStructOutputData.Insert("Sum", 		vTotalSum);
		
		vQRCodeString =  tcCommonFunctions.cmGenerateBankFormattedString(vStructOutputData);
		If Not IsBlankString(vQRCodeString) Then
			Try
				vQRCodePic =  cmGetQRCodePicture(vQRCodeString);
				vQRCodeControl = vArea.Drawings.QRCodeControl;
				vQRCodeControl.Picture = vQRCodePic;
			Except
				tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Failed to generate a QR code, possibly no internet connection'; de = 'Fehler beim Erzeugen eines QR-Codes, möglicherweise keine Internetverbindung'; ru = 'Не удалось сформировать QR-code, возможно отсутствует соединение с интернетом'"));
			EndTry;	
		EndIf;
	EndIf;
	
	pPaymentOrderSpreadsheet.Put(vArea);
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(pPaymentOrderSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(pPaymentOrderSpreadsheet);
EndProcedure // PrintPaymentOrder

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
