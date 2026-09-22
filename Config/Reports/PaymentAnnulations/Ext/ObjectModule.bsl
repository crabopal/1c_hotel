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
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For today
		PeriodTo = EndOfDay(PeriodFrom);
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
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(PaymentMethod) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Способ оплаты '; en = 'Payment method '; de = 'Zahlungsmethode '") + 
							 TrimAll(PaymentMethod.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Фирма '; en = 'Company '; de = 'Kompanie '") + 
			                     TrimAll(Company.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа фирм '; en = 'Companies folder '; de = 'Kompaniegruppe '") + 
			                     TrimAll(Company.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(PaymentSection) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Кассовая секция '; en = 'Payment section '; de = 'Zahlung Abschnitt '") + 
							 TrimAll(PaymentSection.Description) + 
							 ";" + Chars.LF;
	EndIf;					 
	If ValueIsFilled(CashRegister) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'ККМ '; en = 'Cash register '; de = 'Kasse '") + 
							 TrimAll(CashRegister.Description) + 
							 ";" + Chars.LF;
	EndIf;					 
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Employee) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Mitarbeiterengruppe '") + 
			                     TrimAll(Employee) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelgruppe '") + 
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
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qEmptyEmployee", Catalogs.Employees.EmptyRef());
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qPaymentMethod", PaymentMethod);
	ReportBuilder.Parameters.Insert("qPaymentMethodIsEmpty", Not ValueIsFilled(PaymentMethod));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qCompanyIsEmpty", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qPaymentSection", PaymentSection);
	ReportBuilder.Parameters.Insert("qPaymentSectionIsEmpty", Not ValueIsFilled(PaymentSection));
	ReportBuilder.Parameters.Insert("qCashRegister", CashRegister);
	ReportBuilder.Parameters.Insert("qCashRegisterIsEmpty", Not ValueIsFilled(CashRegister));
	ReportBuilder.Parameters.Insert("qSettlement", Catalogs.PaymentMethods.Settlement);
	
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
	"SELECT
	|	AnnulatedPayments.TypeOfAnnulation AS TypeOfAnnulation,
	|	AnnulatedPayments.DateOfAnnulation AS DateOfAnnulation,
	|	AnnulatedPayments.AuthorOfAnnulation AS AuthorOfAnnulation,
	|	AnnulatedPayments.Date AS Date,
	|	AnnulatedPayments.Ref AS Payment,
	|	AnnulatedPayments.PaymentCurrency AS PaymentCurrency,
	|	AnnulatedPayments.PaymentMethod AS PaymentMethod,
	|	AnnulatedPayments.Payer AS Payer,
	|	AnnulatedPayments.PaymentSection AS PaymentSection,
	|	AnnulatedPayments.CashRegister AS CashRegister,
	|	AnnulatedPayments.Remarks,
	|	AnnulatedPayments.Author AS Author,
	|	AnnulatedPayments.Sum AS Sum,
	|	AnnulatedPayments.VATSum AS VATSum,
	|	1 AS Quantity
	|{SELECT
	|	TypeOfAnnulation,
	|	DateOfAnnulation,
	|	AuthorOfAnnulation.*,
	|	Date,
	|	Payment.*,
	|	PaymentCurrency.*,
	|	PaymentMethod.*,
	|	Payer.*,
	|	CashRegister.*,
	|	PaymentSection.*,
	|	Remarks,
	|	Author.*,
	|	AnnulatedPayments.Company.*,
	|	AnnulatedPayments.Hotel.*,
	|	AnnulatedPayments.ParentDoc.*,
	|	AnnulatedPayments.VATRate.*,
	|	Sum,
	|	VATSum,
	|	Quantity,
	|	(BEGINOFPERIOD(AnnulatedPayments.Date, DAY)) AS AccountingDate,
	|	(WEEK(AnnulatedPayments.Date)) AS AccountingWeek,
	|	(MONTH(AnnulatedPayments.Date)) AS AccountingMonth,
	|	(QUARTER(AnnulatedPayments.Date)) AS AccountingQuarter,
	|	(YEAR(AnnulatedPayments.Date)) AS AccountingYear}
	|FROM
	|	(SELECT
	|		Payments.TypeOfAnnulation AS TypeOfAnnulation,
	|		Payments.DateOfAnnulation AS DateOfAnnulation,
	|		Payments.AuthorOfAnnulation AS AuthorOfAnnulation,
	|		Payments.Date AS Date,
	|		Payments.Ref AS Ref,
	|		Payments.PaymentCurrency AS PaymentCurrency,
	|		Payments.PaymentMethod AS PaymentMethod,
	|		Payments.Payer AS Payer,
	|		Payments.CashRegister AS CashRegister,
	|		Payments.PaymentSection AS PaymentSection,
	|		Payments.Remarks AS Remarks,
	|		Payments.Author AS Author,
	|		Payments.Company AS Company,
	|		Payments.Hotel AS Hotel,
	|		Payments.ParentDoc AS ParentDoc,
	|		Payments.VATRate AS VATRate,
	|		Payments.Sum AS Sum,
	|		Payments.VATSum AS VATSum
	|	FROM
	|		Document.Payment AS Payments
	|	WHERE
	|		(NOT Payments.Posted)
	|		AND Payments.DateOfAnnulation >= &qPeriodFrom
	|		AND Payments.DateOfAnnulation < &qPeriodTo
	|		AND Payments.PaymentMethod <> &qSettlement
	|		AND (Payments.AuthorOfAnnulation IN HIERARCHY (&qEmployee)
	|				OR Payments.AuthorOfAnnulation = &qEmptyEmployee)
	|		AND (Payments.Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|		AND (Payments.PaymentSection = &qPaymentSection
	|				OR &qPaymentSectionIsEmpty)
	|		AND (Payments.PaymentMethod = &qPaymentMethod
	|				OR &qPaymentMethodIsEmpty)
	|		AND (Payments.Company IN HIERARCHY (&qCompany)
	|				OR &qCompanyIsEmpty)
	|		AND (Payments.CashRegister = &qCashRegister
	|				OR &qCashRegisterIsEmpty)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerPayments.TypeOfAnnulation,
	|		CustomerPayments.DateOfAnnulation,
	|		CustomerPayments.AuthorOfAnnulation,
	|		CustomerPayments.Date,
	|		CustomerPayments.Ref,
	|		CustomerPayments.PaymentCurrency,
	|		CustomerPayments.PaymentMethod,
	|		CustomerPayments.AccountingCustomer,
	|		CustomerPayments.CashRegister,
	|		CustomerPayments.PaymentSection,
	|		CustomerPayments.Remarks,
	|		CustomerPayments.Author,
	|		CustomerPayments.Company,
	|		CustomerPayments.Hotel,
	|		CustomerPayments.ParentDoc,
	|		CustomerPayments.VATRate,
	|		CustomerPayments.Sum,
	|		CustomerPayments.VATSum
	|	FROM
	|		Document.CustomerPayment AS CustomerPayments
	|	WHERE
	|		(NOT CustomerPayments.Posted)
	|		AND CustomerPayments.DateOfAnnulation >= &qPeriodFrom
	|		AND CustomerPayments.DateOfAnnulation < &qPeriodTo
	|		AND CustomerPayments.PaymentMethod <> &qSettlement
	|		AND (CustomerPayments.AuthorOfAnnulation IN HIERARCHY (&qEmployee)
	|				OR CustomerPayments.AuthorOfAnnulation = &qEmptyEmployee)
	|		AND (CustomerPayments.Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|		AND (CustomerPayments.PaymentSection = &qPaymentSection
	|				OR &qPaymentSectionIsEmpty)
	|		AND (CustomerPayments.PaymentMethod = &qPaymentMethod
	|				OR &qPaymentMethodIsEmpty)
	|		AND (CustomerPayments.Company IN HIERARCHY (&qCompany)
	|				OR &qCompanyIsEmpty)
	|		AND (CustomerPayments.CashRegister = &qCashRegister
	|				OR &qCashRegisterIsEmpty)) AS AnnulatedPayments
	|{WHERE
	|	AnnulatedPayments.TypeOfAnnulation AS TypeOfAnnulation,
	|	AnnulatedPayments.DateOfAnnulation AS DateOfAnnulation,
	|	AnnulatedPayments.AuthorOfAnnulation.* AS AuthorOfAnnulation,
	|	AnnulatedPayments.Hotel.*,
	|	AnnulatedPayments.Company.*,
	|	AnnulatedPayments.PaymentCurrency.*,
	|	AnnulatedPayments.PaymentSection.*,
	|	AnnulatedPayments.PaymentMethod.*,
	|	AnnulatedPayments.CashRegister.*,
	|	AnnulatedPayments.Payer.*,
	|	AnnulatedPayments.Author.*,
	|	AnnulatedPayments.ParentDoc.*,
	|	(BEGINOFPERIOD(AnnulatedPayments.Date, DAY)) AS AccountingDate,
	|	(WEEK(AnnulatedPayments.Date)) AS AccountingWeek,
	|	(MONTH(AnnulatedPayments.Date)) AS AccountingMonth,
	|	(QUARTER(AnnulatedPayments.Date)) AS AccountingQuarter,
	|	(YEAR(AnnulatedPayments.Date)) AS AccountingYear,
	|	AnnulatedPayments.Ref.* AS Payment,
	|	AnnulatedPayments.Date,
	|	AnnulatedPayments.Sum,
	|	AnnulatedPayments.VATSum,
	|	AnnulatedPayments.VATRate.*,
	|	AnnulatedPayments.Remarks}
	|
	|ORDER BY
	|	DateOfAnnulation
	|{ORDER BY
	|	TypeOfAnnulation,
	|	DateOfAnnulation,
	|	AuthorOfAnnulation.*,
	|	Date,
	|	Author.*,
	|	AnnulatedPayments.Hotel.*,
	|	AnnulatedPayments.Company.*,
	|	PaymentCurrency.*,
	|	PaymentSection.*,
	|	PaymentMethod.*,
	|	CashRegister.*,
	|	Payer.*,
	|	AnnulatedPayments.ParentDoc.*,
	|	Payment.*,
	|	AnnulatedPayments.VATRate.*,
	|	Sum,
	|	VATSum}
	|TOTALS
	|	SUM(Sum),
	|	SUM(VATSum),
	|	SUM(Quantity)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	TypeOfAnnulation,
	|	AuthorOfAnnulation.*,
	|	Author.*,
	|	AnnulatedPayments.Hotel.*,
	|	AnnulatedPayments.Company.*,
	|	PaymentCurrency.*,
	|	PaymentSection.*,
	|	PaymentMethod.*,
	|	CashRegister.*,
	|	Payer.*,
	|	AnnulatedPayments.ParentDoc.*,
	|	Payment.*,
	|	AnnulatedPayments.VATRate.*,
	|	(BEGINOFPERIOD(AnnulatedPayments.Date, DAY)) AS AccountingDate,
	|	(WEEK(AnnulatedPayments.Date)) AS AccountingWeek,
	|	(MONTH(AnnulatedPayments.Date)) AS AccountingMonth,
	|	(QUARTER(AnnulatedPayments.Date)) AS AccountingQuarter,
	|	(YEAR(AnnulatedPayments.Date)) AS AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Payment annualations audit';RU='Аудит аннуляций платежей';de='Buchprüfung der Annullierungen von Zahlungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
