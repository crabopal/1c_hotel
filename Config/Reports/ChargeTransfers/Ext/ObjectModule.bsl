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
		vParamPresentation = vParamPresentation + NStr("en='Guest group ';ru='Группа ';de='Gruppe '") + 
							 TrimAll(GuestGroup.Code) + 
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
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
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
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qCompanyIsEmpty", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qContractIsEmpty", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	
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
	|	ChargeTransfer.Date AS Date,
	|	ChargeTransfer.Ref AS ChargeTransfer,
	|	ChargeTransfer.ParentCharge AS ParentCharge,
	|	ChargeTransfer.ParentCharge.Service AS Service,
	|	ChargeTransfer.ParentCharge.Quantity AS Quantity,
	|	ChargeTransfer.ParentCharge.Sum - ChargeTransfer.ParentCharge.DiscountSum AS Sum,
	|	ChargeTransfer.FolioFrom.FolioCurrency AS FolioCurrency,
	|	ChargeTransfer.FolioFrom.Customer,
	|	ChargeTransfer.FolioFrom.Contract,
	|	ChargeTransfer.FolioFrom.GuestGroup,
	|	ChargeTransfer.FolioFrom.Client,
	|	ChargeTransfer.FolioFrom.Room,
	|	ChargeTransfer.FolioFrom.DateTimeFrom,
	|	ChargeTransfer.FolioFrom.DateTimeTo,
	|	ChargeTransfer.FolioTo.Customer,
	|	ChargeTransfer.FolioTo.Contract,
	|	ChargeTransfer.FolioTo.GuestGroup,
	|	ChargeTransfer.FolioTo.Client,
	|	ChargeTransfer.FolioTo.Room,
	|	ChargeTransfer.FolioTo.DateTimeFrom,
	|	ChargeTransfer.FolioTo.DateTimeTo,
	|	ChargeTransfer.Remarks,
	|	ChargeTransfer.Author
	|{SELECT
	|	Date,
	|	ChargeTransfer.*,
	|	ChargeTransfer.FolioFrom.*,
	|	ParentCharge.*,
	|	Service.*,
	|	Quantity,
	|	Sum,
	|	FolioCurrency.*,
	|	ChargeTransfer.FolioFrom.PaymentMethod.* AS FolioFromPaymentMethod,
	|	FolioFromCustomer.*,
	|	FolioFromContract.*,
	|	FolioFromGuestGroup.*,
	|	FolioFromClient.*,
	|	FolioFromRoom.*,
	|	FolioFromDateTimeFrom,
	|	FolioFromDateTimeTo,
	|	ChargeTransfer.FolioTo.*,
	|	ChargeTransfer.FolioTo.PaymentMethod.* AS FolioToPaymentMethod,
	|	FolioToCustomer.*,
	|	FolioToContract.*,
	|	FolioToGuestGroup.*,
	|	FolioToClient.*,
	|	FolioToRoom.*,
	|	FolioToDateTimeFrom,
	|	FolioToDateTimeTo,
	|	ChargeTransfer.ParentDoc.*,
	|	Remarks,
	|	Author.*,
	|	ChargeTransfer.Hotel.*,
	|	(BEGINOFPERIOD(ChargeTransfer.Date, DAY)) AS AccountingDate,
	|	(WEEK(ChargeTransfer.Date)) AS AccountingWeek,
	|	(MONTH(ChargeTransfer.Date)) AS AccountingMonth,
	|	(QUARTER(ChargeTransfer.Date)) AS AccountingQuarter,
	|	(YEAR(ChargeTransfer.Date)) AS AccountingYear}
	|FROM
	|	Document.ChargeTransfer AS ChargeTransfer
	|WHERE
	|	(ChargeTransfer.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (ChargeTransfer.FolioFrom.Customer IN HIERARCHY (&qCustomer)
	|			OR ChargeTransfer.FolioTo.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomerIsEmpty)
	|	AND (ChargeTransfer.FolioFrom.Contract = &qContract
	|			OR ChargeTransfer.FolioTo.Contract = &qContract
	|			OR &qContractIsEmpty)
	|	AND (ChargeTransfer.FolioFrom.GuestGroup = &qGuestGroup
	|			OR ChargeTransfer.FolioTo.GuestGroup = &qGuestGroup
	|			OR &qGuestGroupIsEmpty)
	|	AND ChargeTransfer.Date >= &qPeriodFrom
	|	AND ChargeTransfer.Date < &qPeriodTo
	|	AND ChargeTransfer.Posted
	|	AND (ChargeTransfer.FolioFrom.Company IN HIERARCHY (&qCompany)
	|			OR ChargeTransfer.FolioTo.Company IN HIERARCHY (&qCompany)
	|			OR &qCompanyIsEmpty)
	|{WHERE
	|	ChargeTransfer.Date,
	|	ChargeTransfer.Ref.* AS ChargeTransfer,
	|	ChargeTransfer.FolioFrom.* AS FolioFrom,
	|	ChargeTransfer.ParentCharge.* AS ParentCharge,
	|	ChargeTransfer.ParentCharge.Service.* AS Service,
	|	ChargeTransfer.ParentCharge.Quantity AS Quantity,
	|	(ChargeTransfer.ParentCharge.Sum - ChargeTransfer.ParentCharge.DiscountSum) AS Sum,
	|	ChargeTransfer.FolioFrom.FolioCurrency.* AS FolioCurrency,
	|	ChargeTransfer.FolioFrom.PaymentMethod.* AS FolioFromPaymentMethod,
	|	ChargeTransfer.FolioFrom.Customer.* AS FolioFromCustomer,
	|	ChargeTransfer.FolioFrom.Contract.* AS FolioFromContract,
	|	ChargeTransfer.FolioFrom.GuestGroup.* AS FolioFromGuestGroup,
	|	ChargeTransfer.FolioFrom.Client.* AS FolioFromClient,
	|	ChargeTransfer.FolioFrom.Room.* AS FolioFromRoom,
	|	ChargeTransfer.FolioFrom.DateTimeFrom AS FolioFromDateTimeFrom,
	|	ChargeTransfer.FolioFrom.DateTimeTo AS FolioFromDateTimeTo,
	|	ChargeTransfer.FolioTo.* AS FolioTo,
	|	ChargeTransfer.FolioTo.PaymentMethod.* AS FolioToPaymentMethod,
	|	ChargeTransfer.FolioTo.Customer.* AS FolioToCustomer,
	|	ChargeTransfer.FolioTo.Contract.* AS FolioToContract,
	|	ChargeTransfer.FolioTo.GuestGroup.* AS FolioToGuestGroup,
	|	ChargeTransfer.FolioTo.Client.* AS FolioToClient,
	|	ChargeTransfer.FolioTo.Room.* AS FolioToRoom,
	|	ChargeTransfer.FolioTo.DateTimeFrom AS FolioToDateTimeFrom,
	|	ChargeTransfer.FolioTo.DateTimeTo AS FolioToDateTimeTo,
	|	ChargeTransfer.ParentDoc.* AS ParentDoc,
	|	ChargeTransfer.Remarks AS Remarks,
	|	ChargeTransfer.Author.* AS Author,
	|	ChargeTransfer.Hotel.* AS Hotel}
	|
	|ORDER BY
	|	Date
	|{ORDER BY
	|	Date,
	|	ChargeTransfer.*,
	|	ChargeTransfer.FolioFrom.*,
	|	ParentCharge.*,
	|	Service.*,
	|	Quantity,
	|	Sum,
	|	FolioCurrency.*,
	|	ChargeTransfer.FolioFrom.PaymentMethod.* AS FolioFromPaymentMethod,
	|	FolioFromCustomer.*,
	|	FolioFromContract.*,
	|	FolioFromGuestGroup.*,
	|	FolioFromClient.*,
	|	FolioFromRoom.*,
	|	FolioFromDateTimeFrom,
	|	FolioFromDateTimeTo,
	|	ChargeTransfer.FolioTo.*,
	|	ChargeTransfer.FolioTo.PaymentMethod.* AS FolioToPaymentMethod,
	|	FolioToCustomer.*,
	|	FolioToContract.*,
	|	FolioToGuestGroup.*,
	|	FolioToClient.*,
	|	FolioToRoom.*,
	|	FolioToDateTimeFrom,
	|	FolioToDateTimeTo,
	|	ChargeTransfer.ParentDoc.*,
	|	Author.*,
	|	ChargeTransfer.Hotel.*}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(Sum)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	ChargeTransfer.*,
	|	ChargeTransfer.FolioFrom.*,
	|	ParentCharge.*,
	|	Service.*,
	|	FolioCurrency.*,
	|	ChargeTransfer.FolioFrom.PaymentMethod.* AS FolioFromPaymentMethod,
	|	FolioFromCustomer.*,
	|	FolioFromContract.*,
	|	FolioFromGuestGroup.*,
	|	FolioFromClient.*,
	|	FolioFromRoom.*,
	|	FolioFromDateTimeFrom,
	|	FolioFromDateTimeTo,
	|	ChargeTransfer.FolioTo.*,
	|	ChargeTransfer.FolioTo.PaymentMethod.* AS FolioToPaymentMethod,
	|	FolioToCustomer.*,
	|	FolioToContract.*,
	|	FolioToGuestGroup.*,
	|	FolioToClient.*,
	|	FolioToRoom.*,
	|	FolioToDateTimeFrom,
	|	FolioToDateTimeTo,
	|	ChargeTransfer.ParentDoc.*,
	|	Author.*,
	|	ChargeTransfer.Hotel.*,
	|	(BEGINOFPERIOD(ChargeTransfer.Date, DAY)) AS AccountingDate,
	|	(WEEK(ChargeTransfer.Date)) AS AccountingWeek,
	|	(MONTH(ChargeTransfer.Date)) AS AccountingMonth,
	|	(QUARTER(ChargeTransfer.Date)) AS AccountingQuarter,
	|	(YEAR(ChargeTransfer.Date)) AS AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Charge transfers';RU='Перемещения начислений';de='Verschiebungen der Anrechnungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
