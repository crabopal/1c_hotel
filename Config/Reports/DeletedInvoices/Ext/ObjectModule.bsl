
#Region Public

// -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
		If Not ValueIsFilled(PeriodFrom) Then
			PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg. of month
			PeriodTo = EndOfDay(CurrentSessionDate());
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vLanguage = Customer.Language;
			If Not ValueIsFilled(vLanguage) Then
				vLanguage = SessionParameters.CurrentLanguage;
			EndIf;
			vCustomerLegacyName = TrimAll(Customer.LegacyName);
			If IsBlankString(vCustomerLegacyName) Then
				vCustomerLegacyName = TrimAll(Customer.Description);
			EndIf;
			vCustomerLegacyAddress = cmGetAddressPresentation(Customer.LegacyAddress);
			vCustomerPostAddress = cmGetAddressPresentation(Customer.PostAddress);
			If lower(vCustomerPostAddress) = lower(vCustomerLegacyAddress) Then
				vCustomerPostAddress = "";
			EndIf;
			vCustomerTIN = TrimAll(Customer.TIN);
			vCustomerKPP = TrimAll(Customer.KPP);
			vCustomerVATC = TrimAll(Customer.VATC);
			vCustomerCodes = "";
			If Not IsBlankString(vCustomerTIN) Then
				vCustomerCodes = cmNStr("en='Reg. N';de='Reg. N';ru='ИНН'", vLanguage) + ?(IsBlankString(vCustomerKPP), " ", "/" + cmNStr("en='KPP ';de='KPP ';ru='КПП '", vLanguage)) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP);
			EndIf;
			If Not IsBlankString(vCustomerVATC) Then
				vCustomerCodes = vCustomerCodes + ?(IsBlankString(vCustomerCodes), "", ", ") + cmNStr("EN='VAT Code ';RU='код НДС ';de='Mw.St. Code '", vLanguage) + vCustomerVATC;
			EndIf;
			// Fax and E-Mail
			vCustomerPhones = TrimAll(Customer.Phone);
			vCustomerFax = TrimAll(Customer.Fax);
			vCustomerEMail = TrimAll(Customer.EMail);
			vCustomerPhones = vCustomerPhones + 
			                  ?(IsBlankString(vCustomerFax), "", ?(IsBlankString(vCustomerPhones), "", ", ") + cmNStr("en='fax ';de='fax ';ru='факс '", vLanguage) + vCustomerFax);
			vCustomerPhones = vCustomerPhones + 
							  ?(IsBlankString(vCustomerEMail), "", ?(IsBlankString(vCustomerPhones), "", ", ") + cmNStr("en='e-mail ';de='e-mail ';ru='e-mail '", vLanguage) + vCustomerEMail);
			// Name
			vCustomerLegacyName = vCustomerLegacyName + ?(IsBlankString(vCustomerCodes), "", ", " + vCustomerCodes) + Chars.LF + 
			                      ?(IsBlankString(vCustomerLegacyAddress), "", vCustomerLegacyAddress + Chars.LF) + 
								  ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + 
								  ?(IsBlankString(vCustomerPhones), "", vCustomerPhones);
			vCustomerLegacyName = TrimAll(vCustomerLegacyName);

			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
				                     vCustomerLegacyName + 
				                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Firmen ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Contract) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract ';ru='Договор ';de='Vertrag '") + 
							 TrimAll(Contract.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа гостей '; en = 'Guest group '; de = 'Gastgruppe '") + 
							 TrimAll(TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description)) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(Currency) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Валюта '; en = 'Currency '; de = 'Währung '") + 
							 TrimAll(Currency.Description) + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vLanguage = Undefined;
			If ValueIsFilled(Customer) Then
				If Not Customer.IsFolder Then
					vLanguage = Customer.Language;
				EndIf;
			EndIf;
			If Not ValueIsFilled(vLanguage) Then
				vLanguage = SessionParameters.CurrentLanguage;
			EndIf;
			vCompanyObj = Company.GetObject();
			vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(vLanguage);
			vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(vLanguage);
			vCompanyPostAddress = vCompanyObj.pmGetCompanyPostAddressPresentation(vLanguage);
			If lower(vCompanyPostAddress) = lower(vCompanyLegacyAddress) Then
				vCompanyPostAddress = "";
			EndIf;
			vCompanyTIN = TrimAll(vCompanyObj.TIN);
			vCompanyKPP = TrimAll(vCompanyObj.KPP);
			vCompanyVATC = TrimAll(vCompanyObj.VATC);
			vCompanyCodes = "";
			If Not IsBlankString(vCompanyTIN) Then
				vCompanyCodes = cmNStr("en='Reg. N';de='Reg. N';ru='ИНН'", vLanguage) + ?(IsBlankString(vCompanyKPP), " ", "/" + cmNStr("en='KPP ';de='KPP ';ru='КПП '", vLanguage)) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
			EndIf;
			If Not IsBlankString(vCompanyVATC) Then
				vCompanyCodes = vCompanyCodes + ?(IsBlankString(vCompanyCodes), "", ", ") + cmNStr("en='VAT Code ';ru='код НДС ';de='Mw.St. Code ';lv='PVN '", vLanguage) + vCompanyVATC;
			EndIf;
			vCompanyPhones = TrimAll(vCompanyObj.Phones);
			vCompanyPhones = vCompanyPhones + 
			                 ?(IsBlankString(vCompanyObj.Fax), "", ?(IsBlankString(vCompanyPhones), "", ", ") + cmNStr("en='fax ';de='fax ';ru='факс '", vLanguage) + TrimAll(vCompanyObj.Fax));
			vCompanyLegacyName = TrimAll(vCompanyLegacyName + ?(IsBlankString(vCompanyCodes), "", ", " + vCompanyCodes) + Chars.LF + vCompanyLegacyAddress + Chars.LF + ?(IsBlankString(vCompanyPostAddress), "", vCompanyPostAddress + Chars.LF) + vCompanyPhones);
			vCompanyLegacyName = TrimAll(vCompanyLegacyName);

			vParamPresentation = vParamPresentation + NStr("ru = 'Фирма '; en = 'Company '; de = 'Kompanie '") + 
			                     vCompanyLegacyName + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа фирм '; en = 'Companies folder '; de = 'Kompaniegruppe '") + 
			                     TrimAll(Company.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     TrimAll(Hotel.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", ?(ValueIsFilled(PeriodFrom), PeriodFrom, '00010101010101'));
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235959'));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qIsEmptyCompany", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qCurrency", Currency);
	ReportBuilder.Parameters.Insert("qIsEmptyCurrency", Not ValueIsFilled(Currency));
	ReportBuilder.Parameters.Insert("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qByInvoiceDeletionDate", ?(PeriodSelectionType = 1, True, False));
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT DISTINCT
	|	DeletedInvoices.Invoice AS Invoice,
	|	DeletedInvoices.Invoice.Hotel AS Hotel,
	|	DeletedInvoices.Invoice.Company AS Company,
	|	DeletedInvoices.Invoice.AccountingCurrency AS Currency,
	|	DeletedInvoices.Invoice.AccountingCustomer AS Customer,
	|	DeletedInvoices.Invoice.AccountingContract AS Contract,
	|	DeletedInvoices.GuestGroup AS GuestGroup,
	|	DeletedInvoices.Invoice.Sum AS Sum,
	|	DeletedInvoices.Invoice.SumDue AS SumDue
	|INTO DeletedInvoices
	|FROM
	|	(SELECT
	|		UnpostedInvoiceServices.Ref AS Invoice,
	|		UnpostedInvoiceServices.GuestGroup AS GuestGroup
	|	FROM
	|		Document.Settlement.Services AS UnpostedInvoiceServices
	|	WHERE
	|		NOT UnpostedInvoiceServices.Ref.Posted
	|		AND (NOT &qByInvoiceDeletionDate
	|					AND UnpostedInvoiceServices.Ref.Date >= &qPeriodFrom
	|					AND UnpostedInvoiceServices.Ref.Date <= &qPeriodTo
	|				OR &qByInvoiceDeletionDate
	|					AND UnpostedInvoiceServices.Ref.ChangeDate >= &qPeriodFrom
	|					AND UnpostedInvoiceServices.Ref.ChangeDate <= &qPeriodTo)
	|		AND (UnpostedInvoiceServices.Ref.Hotel IN HIERARCHY (&qHotel)
	|				OR &qIsEmptyHotel)
	|		AND (UnpostedInvoiceServices.Ref.Company IN HIERARCHY (&qCompany)
	|				OR &qIsEmptyCompany)
	|		AND (UnpostedInvoiceServices.Ref.AccountingCustomer IN HIERARCHY (&qCustomer)
	|				OR &qIsEmptyCustomer)
	|		AND (UnpostedInvoiceServices.Ref.AccountingContract IN HIERARCHY (&qContract)
	|				OR &qIsEmptyContract)
	|		AND (UnpostedInvoiceServices.GuestGroup = &qGuestGroup
	|				OR &qIsEmptyGuestGroup)
	|		AND (UnpostedInvoiceServices.Ref.AccountingCurrency = &qCurrency
	|				OR &qIsEmptyCurrency)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		UnpostedInvoices.Ref,
	|		UnpostedInvoices.GuestGroup
	|	FROM
	|		Document.Settlement AS UnpostedInvoices
	|	WHERE
	|		NOT UnpostedInvoices.Posted
	|		AND (NOT &qByInvoiceDeletionDate
	|					AND UnpostedInvoices.Date >= &qPeriodFrom
	|					AND UnpostedInvoices.Date <= &qPeriodTo
	|				OR &qByInvoiceDeletionDate
	|					AND UnpostedInvoices.ChangeDate >= &qPeriodFrom
	|					AND UnpostedInvoices.ChangeDate <= &qPeriodTo)
	|		AND (UnpostedInvoices.Hotel IN HIERARCHY (&qHotel)
	|				OR &qIsEmptyHotel)
	|		AND (UnpostedInvoices.Company IN HIERARCHY (&qCompany)
	|				OR &qIsEmptyCompany)
	|		AND (UnpostedInvoices.AccountingCustomer IN HIERARCHY (&qCustomer)
	|				OR &qIsEmptyCustomer)
	|		AND (UnpostedInvoices.AccountingContract IN HIERARCHY (&qContract)
	|				OR &qIsEmptyContract)
	|		AND (UnpostedInvoices.GuestGroup = &qGuestGroup
	|				OR &qIsEmptyGuestGroup)
	|		AND (UnpostedInvoices.AccountingCurrency = &qCurrency
	|				OR &qIsEmptyCurrency)) AS DeletedInvoices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeletedInvoices.Invoice.Date AS InvoiceDate,
	|	DeletedInvoices.Invoice.Author AS InvoiceAuthor,
	|	DeletedInvoices.Invoice.ChangeDate AS DeleteDate,
	|	DeletedInvoices.Invoice.ChangeAuthor AS DeleteAuthor,
	|	DeletedInvoices.Invoice AS Invoice,
	|	DeletedInvoices.Currency AS Currency,
	|	DeletedInvoices.Customer AS Customer,
	|	DeletedInvoices.Contract AS Contract,
	|	DeletedInvoices.GuestGroup AS GuestGroup,
	|	DeletedInvoices.Sum AS Sum,
	|	DeletedInvoices.SumDue AS SumDue
	|{SELECT
	|	InvoiceDate,
	|	InvoiceAuthor,
	|	DeleteDate,
	|	DeleteAuthor,
	|	Invoice.*,
	|	DeletedInvoices.Hotel.*,
	|	DeletedInvoices.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	DeletedInvoices.Invoice.Remarks AS Remarks,
	|	Sum,
	|	SumDue}
	|FROM
	|	DeletedInvoices AS DeletedInvoices
	|{WHERE
	|	DeletedInvoices.Invoice.Date AS InvoiceDate,
	|	DeletedInvoices.Invoice.Author AS InvoiceAuthor,
	|	DeletedInvoices.Invoice.ChangeDate AS DeleteDate,
	|	DeletedInvoices.Invoice.ChangeAuthor AS DeleteAuthor,
	|	DeletedInvoices.Invoice.*,
	|	DeletedInvoices.Hotel.*,
	|	DeletedInvoices.Company.*,
	|	DeletedInvoices.Currency.*,
	|	DeletedInvoices.Customer.*,
	|	DeletedInvoices.Contract.*,
	|	DeletedInvoices.GuestGroup.*,
	|	DeletedInvoices.Invoice.Remarks AS Remarks,
	|	DeletedInvoices.Sum AS Sum,
	|	DeletedInvoices.SumDue AS SumDue}
	|
	|ORDER BY
	|	Currency,
	|	Customer,
	|	Contract,
	|	InvoiceDate
	|{ORDER BY
	|	InvoiceDate,
	|	InvoiceAuthor,
	|	DeleteDate,
	|	DeleteAuthor,
	|	Invoice.*,
	|	DeletedInvoices.Hotel.*,
	|	DeletedInvoices.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Sum,
	|	SumDue}
	|TOTALS
	|	SUM(Sum),
	|	SUM(SumDue)
	|BY
	|	OVERALL,
	|	Currency,
	|	Customer,
	|	Contract,
	|	Invoice
	|{TOTALS BY
	|	InvoiceAuthor,
	|	DeleteAuthor,
	|	Invoice.*,
	|	DeletedInvoices.Hotel.*,
	|	DeletedInvoices.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Deleted invoices';ru='Удаленные акты';de='Gelöschte Rechnungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

#EndRegion
