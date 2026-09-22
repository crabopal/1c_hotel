#Region FormEventHandlers

// --------------------------------------------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	PutSpreadsheetDocument();
EndProcedure // OnOpen

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	InvoiceSpreadsheet.Print();
	ThisForm.Close();
EndProcedure // Print

// --------------------------------------------------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	InvoiceSpreadsheet.Print(PrintDialogUseMode.Use);
EndProcedure // ChoosePrinter

// --------------------------------------------------------------------------------------------------------------------
&AtClient
Procedure SaveAs(pCommand)
	vFilePath = "";
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, InvoiceSpreadsheet);
EndProcedure // SaveAs

#EndRegion

#Region Private

// --------------------------------------------------------------------------------------------------------------------
&AtServer
Procedure PutSpreadsheetDocument()
	vRub = Catalogs.Currencies.FindByCode(643);
	vRusLanguage = Catalogs.Languages.RU;
	vAmount = SMSQuantity*SMSPrice;
	Company = Constants.SMSCompany.Get();
	If NOT ValueIsFilled(Company) Then
		vHotel = SessionParameters.CurrentHotel;
		If ValueIsFilled(vHotel) AND ValueIsFilled(vHotel.Company) Then
			vCompany = vHotel.Company.GetObject();
		Else
			Return;
		EndIf;
	Else
		vCompany = Company.GetObject();
	EndIf;			
	vCompanyFullAddress = vCompany.pmGetCompanyPrintName(vRusLanguage)+", ИНН "+vCompany.TIN+", КПП "
								+vCompany.KPP+", "+vCompany.pmGetCompanyLegacyAddressPresentation(vRusLanguage)
								+?(ValueIsFilled(vCompany.Phones),", тел.: "+TrimAll(vCompany.Phones), "")
								+?(ValueIsFilled(vCompany.Fax),", факс: "+TrimAll(vCompany.Fax), "");
	InvoiceSpreadsheet.Clear();
	vSpreadsheet = New SpreadsheetDocument;
	vSpreadsheet.Read(ResponseFileName);
	vSpreadsheet.TemplateLanguageCode = "RU";
	vArea = vSpreadsheet.GetArea("Invoice");
	vParams = New Structure;
	vLogin = Constants.SMSLogin.Get();
	vParams.Insert("mInvoiceNumber",Constants.SMSLogin.Get());
	vParams.Insert("mDocNumber",Upper(Left(Constants.SMSLogin.Get(),2))+"-"+Format(CurrentSessionDate(),"DF=ddmm"));
	vParams.Insert("mCustomer",vCompanyFullAddress);
	vParams.Insert("mQuantity",SMSQuantity);
	vParams.Insert("mPrice",cmFormatSum(SMSPrice, vRub));
	vParams.Insert("mAmount",cmFormatSum(vAmount, vRub));
	vParams.Insert("mAmountInWords",cmSumInWords(vAmount, vRub, vRusLanguage));
	FillPropertyValues(vArea.Parameters, vParams);
	InvoiceSpreadsheet.Put(vArea);
	// Setup default attributes
	cmSetDefaultPrintFormSettings(InvoiceSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(InvoiceSpreadsheet);
EndProcedure // PutSpreadsheetDocument

#EndRegion
