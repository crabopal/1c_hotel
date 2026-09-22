
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	cmSetSpreadsheetProtection(Items.PrintingSpreadsheet);
	FillPropertyValues(ThisForm, Parameters, "SelHotel, SelDoc, SelObjectPrintForm");
	If Not ValueIsFilled(SelObjectPrintForm) Then
		SelObjectPrintForm = Catalogs.ObjectPrintingForms.IssueHotelProductsPrintHotelProductsLog;
	EndIf;
	// Generate print form
	rDoPrint = Undefined;
	GenerateAtServer(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	PrintingSpreadsheet.Print(PrintDialogUseMode.DontUse);
	ThisForm.Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	PrintingSpreadsheet.Print(PrintDialogUseMode.Use);
	ThisForm.Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand) 		
	vFilePath = GetFilePath();
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, PrintingSpreadsheet);
EndProcedure // SaveAsPDF

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateAtServer(rDoPrint = Undefined)
	If SelObjectPrintForm = Catalogs.ObjectPrintingForms.IssueHotelProductsPrintHotelProductsLog Then
		PrintHotelProductsLog(rDoPrint);
		ThisForm.Title = "Печать реестра использованных бланков путевок и курсовок "; 
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.IssueHotelProductsPrintBillOfShipment Then
		PrintBillOfShipment(rDoPrint);
		ThisForm.Title = "Печать накладной на отгрузку путевок"; 
	EndIf;
EndProcedure // GenerateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GetHotelProductPayments(pHotelProduct, rCash, rCreditCard, rBankTransfer)
	rCash = 0;
	rCreditCard = 0;
	rBankTransfer = 0;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	HotelProductPayments.AccountingCurrency,
	|	SUM(CASE
	|			WHEN ISNULL(HotelProductPayments.Recorder.PaymentMethod.IsByCash, FALSE)
	|				THEN HotelProductPayments.Sum
	|			ELSE 0
	|		END) AS CashSum,
	|	SUM(CASE
	|			WHEN ISNULL(HotelProductPayments.Recorder.PaymentMethod.IsByCreditCard, FALSE)
	|				THEN HotelProductPayments.Sum
	|			ELSE 0
	|		END) AS CreditCardSum,
	|	SUM(CASE
	|			WHEN ISNULL(HotelProductPayments.Recorder.PaymentMethod.IsByBankTransfer, FALSE)
	|				THEN HotelProductPayments.Sum
	|			ELSE 0
	|		END) AS BankTransferSum
	|FROM
	|	AccumulationRegister.CustomerAccounts AS HotelProductPayments
	|WHERE
	|	HotelProductPayments.RecordType = VALUE(AccumulationrecordType.Expense)
	|	AND (HotelProductPayments.PaymentSection = &qPaymentSection
	|			OR &qPaymentSectionIsEmpty)
	|	AND HotelProductPayments.Hotel IN HIERARCHY(&qHotel)
	|	AND HotelProductPayments.AccountingCurrency = &qCurrency
	|	AND (HotelProductPayments.Folio.HotelProduct = &qHotelProduct
	|			OR HotelProductPayments.Folio.ParentDoc.HotelProduct = &qHotelProduct
	|			OR HotelProductPayments.ParentDoc.HotelProduct = &qHotelProduct)
	|
	|GROUP BY
	|	HotelProductPayments.AccountingCurrency";
	vQry.SetParameter("qHotelProduct", pHotelProduct);
	vQry.SetParameter("qHotel", SelDoc.Hotel);
	vQry.SetParameter("qCurrency", SelDoc.Currency);
	vPaymentSection = Catalogs.PaymentSections.EmptyRef();
	If ValueIsFilled(pHotelProduct.Parent) Then
		vPaymentSection = pHotelProduct.Parent.PaymentSection;
	EndIf;
	vQry.SetParameter("qPaymentSection", vPaymentSection);
	vQry.SetParameter("qPaymentSectionIsEmpty", Not ValueIsFilled(vPaymentSection));
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() = 1 Then
		vQryResRow = vQryRes.Get(0);
		rCash = vQryResRow.CashSum;
		rCreditCard = vQryResRow.CreditCardSum;
		rBankTransfer = vQryResRow.BankTransferSum;
	EndIf;
EndProcedure // GetHotelProductPayments

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintHotelProductsLog(rDoPrint = Undefined)
	vCash = 0;
	vCreditCard = 0;
	vBankTransfer = 0;
	
	// Basic checks
	If Not ValueIsFilled(SelDoc) Then
		Raise NStr("ru='Не задана отгрузка путевок!';de='Verschicken von Reiseschecks ist nicht angegeben!';en='Issue hotel products should be selected!'");
	EndIf;
	SelHotel = SelDoc.Hotel;
	If Not ValueIsFilled(SelHotel) Then
		Raise NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	vDocObj = SelDoc.GetObject();
	vSpreadsheet =PrintingSpreadsheet;
	vSpreadsheet.Clear();
	vTemplate = vDocObj.GetTemplate("HotelProductsLogRu");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Header
	vHeader = vTemplate.GetArea("Header");
	// Hotel
	vHotelObj = SelHotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(SelLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SelLanguage);
	vHotelPhones = TrimAll(SelHotel.Phones);
	vHotelFax = TrimAll(SelHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vHotelFax);
	// Doc date and number
	mDocNumber = cmGetDocumentNumberPresentation(SelDoc.Number);
	mDocDate = cmGetDocumentDatePresentation(SelDoc.Date);
	// Set parameters and put report section
	vHeader.Parameters.mHotelPrintName = mHotelPrintName;
	vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeader.Parameters.mHotelPhones = mHotelPhones;
	vHeader.Parameters.mDocNumber = mDocNumber;
	vHeader.Parameters.mDocDate = mDocDate;
	vSpreadsheet.Put(vHeader);
	
	// Initialize totals
	vTotalSum = 0;
	vTotalCash = 0;
	vTotalCreditCard = 0;
	vTotalBankTransfer = 0;
	vCount = 0;
	vLineNumber = 0;
	
	// Get rows
	vRow = Undefined;
	vParent = vTemplate.GetArea("ProductParent");
	vCurParent = Undefined;
	For Each vHPRow In SelDoc.HotelProducts Do
		If Not ValueIsFilled(vHPRow.HotelProduct) Then
			Continue;
		EndIf;
		
		// Count hotel products within one type
		vLineNumber = vLineNumber + 1;
		
		// Put product type header
		If ValueIsFilled(vHPRow.HotelProduct.Parent) And vCurParent <> vHPRow.HotelProduct.Parent Then
			vCurParent = vHPRow.HotelProduct.Parent;
			vParent.Parameters.mProductParent = vCurParent;
			vLineNumber = 1;
			// Put parent
			vSpreadsheet.Put(vParent);
		EndIf;
			
		// Get row area
		If vHPRow.HotelProduct.DeletionMark Then
			vRow = vTemplate.GetArea("DeletedRow");
		Else
			vRow = vTemplate.GetArea("Row");
		EndIf;
		
		// Get hotel product payments
		GetHotelProductPayments(vHPRow.HotelProduct, vCash, vCreditCard, vBankTransfer);
		
		// Fill row parameters
		mProductPeriod = Format(vHPRow.CheckInDate, "DF=dd.MM.yy") + " - " + 
		                 Format(vHPRow.CheckOutDate, "DF=dd.MM.yy");
		
		// Set parameters
		vRow.Parameters.mLineNumber = Format(vLineNumber, "ND=6; NFD=0; NG=");
		vRow.Parameters.mProductCode = TrimAll(vHPRow.HotelProduct.Code);
		vRow.Parameters.mProduct = vHPRow.HotelProduct;
		vRow.Parameters.mClient = vHPRow.Client;
		vRow.Parameters.mProductPeriod = mProductPeriod;
		vRow.Parameters.mSum = Format(vHPRow.Sum, "ND=17; NFD=2");
		vRow.Parameters.mCash = Format(vCash, "ND=17; NFD=2");
		vRow.Parameters.mCreditCard = Format(vCreditCard, "ND=17; NFD=2");
		vRow.Parameters.mBankTransfer = Format(vBankTransfer, "ND=17; NFD=2");
		
		vTotalSum = vTotalSum + vHPRow.Sum;
		vTotalCash = vTotalCash + vCash;
		vTotalCreditCard = vTotalCreditCard + vCreditCard;
		vTotalBankTransfer = vTotalBankTransfer + vBankTransfer;
		vCount = vCount + 1;
		
		// Put row
		vSpreadsheet.Put(vRow);
	EndDo;
	
	// Footer
	vFooter = vTemplate.GetArea("Footer");
	// Fill parameters
	mTotalSum = cmFormatSum(vTotalSum, SelDoc.Currency);
	mTotalSumInWords = cmSumInWords(vTotalSum, SelDoc.Currency, SelLanguage);
	// Set parameters
	vFooter.Parameters.mTotalSum = mTotalSum;
	vFooter.Parameters.mTotalSumInWords = mTotalSumInWords;
	vFooter.Parameters.mCount = vCount;
	// Put footer
	vSpreadsheet.Put(vFooter);
	
	// Signatures
	vSignatures = vTemplate.GetArea("Signatures");
	vSignatures.Parameters.mRemarks = TrimAll(SelDoc.Remarks);
	vSpreadsheet.Put(vSignatures);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", SelObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Hotel products log';ru='Реестр использованных бланков';de='Register verwendeter Vordrucke'")) + " " + mDocNumber;
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, SelLanguage, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintHotelProductsLog

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintBillOfShipment(rDoPrint = Undefined)
	// Basic checks
	If Not ValueIsFilled(SelDoc) Then
		Raise NStr("ru='Не задана отгрузка путевок!';de='Verschicken von Reiseschecks ist nicht angegeben!';en='Issue hotel products should be selected!'");
	EndIf;
	SelHotel = SelDoc.Hotel;
	If Not ValueIsFilled(SelHotel) Then
		Raise NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf; 
	SelCompany = SelDoc.Company;
	If Not ValueIsFilled(SelCompany) Then
		Raise NStr("ru='Не задана фирма!';de='Die Firma ist nicht angegeben!';en='Company should be filled!'");
	EndIf;
	
	// Choose template
	vDocObj = SelDoc.GetObject();
	vSpreadsheet = PrintingSpreadsheet;
	vSpreadsheet.Clear();
	vTemplate = vDocObj.GetTemplate("BillOfShipmentRu");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Header
	vHeader = vTemplate.GetArea("Header");
	// Hotel
	vHotelObj = SelHotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(SelLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SelLanguage);
	vHotelPhones = TrimAll(SelHotel.Phones);
	vHotelFax = TrimAll(SelHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vHotelFax);
	// Company
	vCompanyObj = SelCompany.GetObject();
	vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
	vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
	vCompanyTIN = TrimAll(SelCompany.TIN);
	vCompanyKPP = TrimAll(SelCompany.KPP);
	vCompanyTIN = cmNStr("en=', TIN ';de=', TIN ';ru=', ИНН '", SelLanguage) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
	mCompany = TrimAll(vCompanyLegacyName + vCompanyTIN + Chars.LF + vCompanyLegacyAddress);
	// Doc date and number
	mDocNumber = cmGetDocumentNumberPresentation(SelDoc.Number);
	mDocDate = cmGetDocumentDatePresentation(SelDoc.Date);
	// Customer
	vCustomer = SelDoc.Customer;
	vCustomerLegacyName = "";
	vCustomerLegacyAddress = "";
	vCustomerTIN = "";
	vCustomerPhones = "";
	If ValueIsFilled(vCustomer) Then
		vCustomerLegacyName = TrimAll(vCustomer.LegacyName);
		If IsBlankString(vCustomerLegacyName) Then
			vCustomerLegacyName = TrimAll(vCustomer.Description);
		EndIf;
		vCustomerLegacyAddress = cmGetAddressPresentation(vCustomer.LegacyAddress);
		vCustomerTIN = TrimAll(vCustomer.TIN);
		vCustomerKPP = TrimAll(vCustomer.KPP);
		vCustomerTIN = cmNStr("en=', TIN ';de=', TIN ';ru=', ИНН '", SelLanguage) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP);
		// Fax and E-Mail
		vCustomerPhones = TrimAll(vCustomer.Phone);
		vCustomerFax = TrimAll(vCustomer.Fax);
		vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
	EndIf;
	mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + vCustomerPhones);
	mContract = "";
	If ValueIsFilled(SelDoc.Contract) Then
		mContract = TrimAll(SelDoc.Contract.Description);
	EndIf;
	mCurrency = "";
	If ValueIsFilled(SelDoc.Currency) Then
		vCurrencyObj = SelDoc.Currency.GetObject();
		mCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
	EndIf;
	// Set parameters and put report section
	vHeader.Parameters.mHotelPrintName = mHotelPrintName;
	vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeader.Parameters.mHotelPhones = mHotelPhones;
	vHeader.Parameters.mDocNumber = mDocNumber;
	vHeader.Parameters.mDocDate = mDocDate;
	vHeader.Parameters.mCompany = mCompany;
	vHeader.Parameters.mCustomer = mCustomer;
	vHeader.Parameters.mContract = mContract;
	vHeader.Parameters.mCurrency = mCurrency;
	vHeader.Parameters.mRemarks = TrimAll(SelDoc.Remarks);
	vSpreadsheet.Put(vHeader);
	
	// Get template areas
	vRow = vTemplate.GetArea("Row");
	
	vTotalSum = 0;
	vTotalVATSum = 0;
	vTotalQuantity = 0;
	
	// Get rows
	For Each vHPRow In SelDoc.HotelProducts Do
		// Fill row parameters
		If TrimAll(vHPRow.ProductStartCode) = TrimAll(vHPRow.ProductEndCode) Or IsBlankString(vHPRow.ProductEndCode) Then
			mProductCodes = TrimAll(TrimAll(vHPRow.HotelProductParent) + " " + TrimAll(vHPRow.ProductStartCode));
		Else
			mProductCodes = TrimAll(TrimAll(vHPRow.HotelProductParent) + Chars.LF + TrimAll(vHPRow.ProductStartCode) + " - " + TrimAll(vHPRow.ProductEndCode));
		EndIf;
		mProductPeriod = Format(vHPRow.CheckInDate, "DF=dd.MM.yy") + " - " + 
		                 Format(vHPRow.CheckOutDate, "DF=dd.MM.yy") + ", " + 
						 vHPRow.Duration + cmNStr("en=' d.';ru=' д.';de=' Tag'", SelLanguage);
		mPrice = Format(vHPRow.Price, "ND=17; NFD=2");
		mQuantity = vHPRow.Quantity;
		mSum = Format(vHPRow.Sum, "ND=17; NFD=2");
		
		vTotalSum = vTotalSum + vHPRow.Sum;
		vTotalVATSum = vTotalVATSum + vHPRow.VATSum;
		vTotalQuantity = vTotalQuantity + vHPRow.Quantity;
		
		// Set parameters
		vRow.Parameters.mProductCodes = mProductCodes;
		vRow.Parameters.mProductPeriod = mProductPeriod;
		vRow.Parameters.mPrice = mPrice;
		vRow.Parameters.mQuantity = mQuantity;
		vRow.Parameters.mSum = mSum;
		
		// Put row
		vSpreadsheet.Put(vRow);
	EndDo;
	
	// Footer
	vFooter = vTemplate.GetArea("Footer");
	// Fill parameters
	mTotalSum = cmFormatSum(vTotalSum, SelDoc.Currency);
	mTotalVATSum = "";
	If vTotalVATSum <> 0 Then
		mTotalVATSum = cmNStr("EN='Including VAT ';RU='В том числе НДС ';de='Darunter MwSt. '", SelLanguage) + cmFormatSum(vTotalVATSum, SelDoc.Currency);
	Else
		mTotalVATSum = cmNStr("EN='No VAT';RU='НДС не облагается';de='MwSt. wird nicht berechnet'", SelLanguage);
	EndIf;
	mTotalSumInWords = cmSumInWords(vTotalSum, SelDoc.Currency, SelLanguage);
	mTotalQuantity = vTotalQuantity;
	// Set parameters
	vFooter.Parameters.mTotalSum = mTotalSum;
	vFooter.Parameters.mTotalVATSum = mTotalVATSum;
	vFooter.Parameters.mTotalSumInWords = mTotalSumInWords;
	vFooter.Parameters.mTotalQuantity = mTotalQuantity;
	// Put footer
	vSpreadsheet.Put(vFooter);
	
	// Signatures
	vSignatures = vTemplate.GetArea("Signatures");
	vSpreadsheet.Put(vSignatures);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", SelObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Bill of shipment';ru='Накладная';de='Begleitschein'")) + " " + mDocNumber;
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, SelLanguage, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintByOperations

// -----------------------------------------------------------------------------
&AtServer
Function GetFilePath()
	vFilePath ="Print_Form";
	If SelObjectPrintForm = Catalogs.ObjectPrintingForms.IssueHotelProductsPrintHotelProductsLog Then
		vFilePath = "Hotel_Products_Log"; 
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.IssueHotelProductsPrintBillOfShipment Then
		vFilePath = "Bill_Of_Shipment";
	EndIf;	
	Return vFilePath;
EndFunction

#EndRegion
