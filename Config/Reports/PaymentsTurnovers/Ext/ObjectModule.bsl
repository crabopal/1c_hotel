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
		PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg of month
		PeriodTo = EndOfDay(CurrentSessionDate());
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
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Firmengruppe ';en='Customers folder ';ru='Группа контрагентов '") + 
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
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelgruppe '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qIsEmptyCompany", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qSettlement", Catalogs.PaymentMethods.Settlement);
	ReportBuilder.Parameters.Insert("qPrintDebitors", PrintDebitors);
	ReportBuilder.Parameters.Insert("qDepositTransfer", Catalogs.PaymentMethods.DepositTransfer);
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	Try
		ReportBuilder.Put(pSpreadsheet);
	Except
		tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
	EndTry;
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
	
	// Add chart 
	If pAddChart Then
		cmAddReportChart(pSpreadsheet, ThisObject);
	EndIf;
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	Payments.Hotel AS Hotel,
	|	Payments.Company AS Company,
	|	Payments.PaymentCurrency AS PaymentCurrency,
	|	Payments.PaymentSection AS PaymentSection,
	|	Payments.PaymentMethod AS PaymentMethod,
	|	Payments.CashRegister AS CashRegister,
	|	Payments.Payer AS Payer,
	|	Payments.Author AS Author,
	|	Payments.AccountingDate AS AccountingDate,
	|	Payments.ParentDoc AS ParentDoc,
	|	Payments.Sum AS Sum,
	|	Payments.VATSum AS VATSum,
	|	Payments.SumExpense AS SumExpense,
	|	Payments.VATSumExpense AS VATSumExpense,
	|	Payments.SumReceipt AS SumReceipt,
	|	Payments.VATSumReceipt AS VATSumReceipt
	|{SELECT
	|	Hotel.*,
	|	Company.*,
	|	PaymentCurrency.*,
	|	PaymentSection.*,
	|	PaymentMethod.*,
	|	CashRegister.*,
	|	Payer.*,
	|	Author.*,
	|	ParentDoc.*,
	|	Payments.ParentDoc.RoomType.* AS RoomType,
	|	Sum,
	|	VATSum,
	|	SumExpense,
	|	VATSumExpense,
	|	SumReceipt,
	|	VATSumReceipt,
	|	AccountingDate,
	|	(WEEK(Payments.AccountingDate)) AS AccountingWeek,
	|	(MONTH(Payments.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(Payments.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(Payments.AccountingDate)) AS AccountingYear}
	|FROM
	|	AccumulationRegister.Payments AS Payments
	|WHERE
	|	Payments.Period >= &qPeriodFrom
	|	AND Payments.Period <= &qPeriodTo
	|	AND Payments.Hotel IN HIERARCHY(&qHotel)
	|	AND (Payments.ParentDoc.Customer IN HIERARCHY (&qCustomer)
	|			OR &qIsEmptyCustomer)
	|	AND (Payments.ParentDoc.Contract = &qContract
	|			OR &qIsEmptyContract)
	|	AND (Payments.ParentDoc.GuestGroup = &qGuestGroup
	|			OR &qIsEmptyGuestGroup)
	|	AND (Payments.Company IN HIERARCHY (&qCompany)
	|			OR &qIsEmptyCompany)
	|	AND (Payments.PaymentMethod <> &qSettlement
	|			OR &qPrintDebitors)
	|	AND Payments.PaymentMethod <> &qDepositTransfer
	|	AND NOT Payments.Recorder REFS Document.DepositTransfer
	|{WHERE
	|	Payments.Hotel.*,
	|	Payments.Company.*,
	|	Payments.PaymentCurrency.*,
	|	Payments.PaymentSection.*,
	|	Payments.PaymentMethod.*,
	|	Payments.CashRegister.*,
	|	Payments.Payer.*,
	|	Payments.Author.*,
	|	Payments.ParentDoc.*,
	|	Payments.ParentDoc.RoomType.* AS RoomType,
	|	Payments.Sum AS Sum,
	|	Payments.VATSum AS VATSum,
	|	Payments.SumExpense AS SumExpense,
	|	Payments.VATSumExpense AS VATSumExpense,
	|	Payments.SumReceipt AS SumReceipt,
	|	Payments.VATSumReceipt AS VATSumReceipt,
	|	Payments.AccountingDate,
	|	(WEEK(Payments.Period)) AS AccountingWeek,
	|	(MONTH(Payments.Period)) AS AccountingMonth,
	|	(QUARTER(Payments.Period)) AS AccountingQuarter,
	|	(YEAR(Payments.Period)) AS AccountingYear}
	|
	|ORDER BY
	|	PaymentCurrency,
	|	PaymentMethod
	|{ORDER BY
	|	Hotel.*,
	|	Company.*,
	|	PaymentCurrency.*,
	|	PaymentSection.*,
	|	PaymentMethod.*,
	|	CashRegister.*,
	|	Payer.*,
	|	Author.*,
	|	ParentDoc.*,
	|	Payments.ParentDoc.RoomType.* AS RoomType,
	|	Sum,
	|	VATSum,
	|	SumExpense,
	|	VATSumExpense,
	|	SumReceipt,
	|	VATSumReceipt,
	|	AccountingDate,
	|	(WEEK(Payments.AccountingDate)) AS AccountingWeek,
	|	(MONTH(Payments.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(Payments.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(Payments.AccountingDate)) AS AccountingYear}
	|TOTALS
	|	SUM(Sum),
	|	SUM(VATSum),
	|	SUM(SumExpense),
	|	SUM(VATSumExpense),
	|	SUM(SumReceipt),
	|	SUM(VATSumReceipt)
	|BY
	|	OVERALL,
	|	PaymentCurrency,
	|	PaymentMethod HIERARCHY
	|{TOTALS BY
	|	Hotel.*,
	|	Company.*,
	|	PaymentCurrency.*,
	|	PaymentSection.*,
	|	PaymentMethod.*,
	|	CashRegister.*,
	|	Payer.*,
	|	Author.*,
	|	ParentDoc.*,
	|	Payments.ParentDoc.RoomType.* AS RoomType,
	|	AccountingDate,
	|	(WEEK(Payments.AccountingDate)) AS AccountingWeek,
	|	(MONTH(Payments.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(Payments.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(Payments.AccountingDate)) AS AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Payments turnovers';RU='Обороты по платежам';de='Umsätze nach Zahlungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sum" 
	   Or pName = "VATSum" 
	   Or pName = "SumExpense" 
	   Or pName = "VATSumExpense" 
	   Or pName = "SumReceipt" 
	   Or pName = "VATSumReceipt" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
