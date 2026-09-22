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
	If ValueIsFilled(HotelProduct) Then
		If Not HotelProduct.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Путевка '; en = 'Hotel product '; de = 'Einweisung '") + 
			                     TrimAll(HotelProduct.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Тип путевок/курсовок '; en = 'Vauchers type '; de = 'Einweisungtyp '") + 
			                     TrimAll(HotelProduct.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
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
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Набор услуг '; en = 'Service group '; de = 'Dienstgruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа наборов услуг '; en = 'Service groups folder '; de = 'Dienstgruppengruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
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
			                     TrimAll(Hotel.Description) + ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qHotelProduct", HotelProduct);
	ReportBuilder.Parameters.Insert("qIsEmptyHotelProduct", Not ValueIsFilled(HotelProduct));
	ReportBuilder.Parameters.Insert("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList= cmGetServiceGroupServices(ServiceGroup);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qUseServicesList", vUseServicesList);
	ReportBuilder.Parameters.Insert("qServicesList", vServicesList);
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
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
	|	HotelProductSales.ReportingCurrency AS ReportingCurrency,
	|	HotelProductSales.Hotel AS Hotel,
	|	HotelProductSales.RoomType AS RoomType,
	|	HotelProductSales.HotelProduct AS HotelProduct,
	|	HotelProductSales.Agent AS Agent,
	|	HotelProductSales.Customer AS Customer,
	|	HotelProductSales.Contract AS Contract,
	|	HotelProductSales.GuestGroup AS GuestGroup,
	|	HotelProductSales.AccountingDate AS AccountingDate,
	|	HotelProductSales.ParentDoc,
	|	HotelProductSales.Service AS Service,
	|	HotelProductSales.SalesTurnover AS Sales,
	|	HotelProductSales.RoomRevenueTurnover AS RoomRevenue,
	|	HotelProductSales.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|	HotelProductSales.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|	HotelProductSales.CommissionSumTurnover AS CommissionSum,
	|	HotelProductSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|	HotelProductSales.DiscountSumTurnover AS DiscountSum,
	|	HotelProductSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|	HotelProductSales.RoomsRentedTurnover AS RoomsRented,
	|	HotelProductSales.BedsRentedTurnover AS BedsRented,
	|	HotelProductSales.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|	HotelProductSales.GuestDaysTurnover AS GuestDays,
	|	HotelProductSales.GuestsCheckedInTurnover AS GuestsCheckedIn,
	|	HotelProductSales.RoomsCheckedInTurnover AS RoomsCheckedIn,
	|	HotelProductSales.BedsCheckedInTurnover AS BedsCheckedIn,
	|	HotelProductSales.AdditionalBedsCheckedInTurnover AS AdditionalBedsCheckedIn,
	|	HotelProductSales.QuantityTurnover AS Quantity
	|{SELECT
	|	ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	Hotel.*,
	|	RoomType.*,
	|	HotelProduct.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Service.*,
	|	ParentDoc.*,
	|	Sales,
	|	RoomRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	Quantity,
	|	AccountingDate,
	|	(WEEK(HotelProductSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(HotelProductSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(HotelProductSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(HotelProductSales.AccountingDate)) AS AccountingYear,
	|	HotelProductSales.Folio.*,
	|	HotelProductSales.Client.*,
	|	HotelProductSales.Price,
	|	HotelProductSales.RoomRate.*,
	|	HotelProductSales.Room.*,
	|	HotelProductSales.AccommodationType.*,
	|	HotelProductSales.ClientType.*,
	|	HotelProductSales.TripPurpose.*,
	|	HotelProductSales.MarketingCode.*,
	|	HotelProductSales.SourceOfBusiness.*,
	|	HotelProductSales.Resource.*,
	|	HotelProductSales.ResourceType.*,
	|	HotelProductSales.Author.*,
	|	HotelProductSales.Discount,
	|	HotelProductSales.DiscountType.*,
	|	HotelProductSales.DiscountCard.*,
	|	HotelProductSales.AgentCommission,
	|	HotelProductSales.AgentCommissionType.*,
	|	HotelProductSales.PaymentMethod.*,
	|	HotelProductSales.VATRate.*,
	|	HotelProductSales.Company.*}
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (Customer IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (Contract = &qContract
	|					OR &qIsEmptyContract)
	|				AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|					OR &qIsEmptyHotelProduct)
	|				AND (HotelProduct <> &qEmptyHotelProduct)
	|				AND (Service IN (&qServicesList)
	|					OR (NOT &qUseServicesList))) AS HotelProductSales
	|{WHERE
	|	HotelProductSales.ReportingCurrency.*,
	|	HotelProductSales.Hotel.*,
	|	HotelProductSales.RoomType.*,
	|	HotelProductSales.HotelProduct.*,
	|	HotelProductSales.Agent.*,
	|	HotelProductSales.Customer.*,
	|	HotelProductSales.Contract.*,
	|	HotelProductSales.GuestGroup.*,
	|	HotelProductSales.AccountingDate,
	|	HotelProductSales.ParentDoc.*,
	|	HotelProductSales.Service.*,
	|	HotelProductSales.SalesTurnover,
	|	HotelProductSales.RoomRevenueTurnover,
	|	HotelProductSales.SalesWithoutVATTurnover,
	|	HotelProductSales.RoomRevenueWithoutVATTurnover,
	|	HotelProductSales.CommissionSumTurnover,
	|	HotelProductSales.CommissionSumWithoutVATTurnover,
	|	HotelProductSales.DiscountSumTurnover,
	|	HotelProductSales.DiscountSumWithoutVATTurnover,
	|	HotelProductSales.RoomsRentedTurnover,
	|	HotelProductSales.BedsRentedTurnover,
	|	HotelProductSales.AdditionalBedsRentedTurnover,
	|	HotelProductSales.GuestDaysTurnover,
	|	HotelProductSales.GuestsCheckedInTurnover,
	|	HotelProductSales.RoomsCheckedInTurnover,
	|	HotelProductSales.BedsCheckedInTurnover,
	|	HotelProductSales.AdditionalBedsCheckedInTurnover,
	|	HotelProductSales.QuantityTurnover,
	|	HotelProductSales.Folio.*,
	|	HotelProductSales.Client.*,
	|	HotelProductSales.Price,
	|	HotelProductSales.Service.*,
	|	HotelProductSales.RoomRate.*,
	|	HotelProductSales.Room.*,
	|	HotelProductSales.AccommodationType.*,
	|	HotelProductSales.ClientType.*,
	|	HotelProductSales.TripPurpose.*,
	|	HotelProductSales.MarketingCode.*,
	|	HotelProductSales.SourceOfBusiness.*,
	|	HotelProductSales.Resource.*,
	|	HotelProductSales.ResourceType.*,
	|	HotelProductSales.Author.*,
	|	HotelProductSales.Discount,
	|	HotelProductSales.DiscountType.*,
	|	HotelProductSales.DiscountCard.*,
	|	HotelProductSales.AgentCommission,
	|	HotelProductSales.AgentCommissionType.*,
	|	HotelProductSales.PaymentMethod.*,
	|	HotelProductSales.VATRate.*,
	|	HotelProductSales.Company.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	RoomType,
	|	HotelProduct
	|{ORDER BY
	|	ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	Hotel.*,
	|	RoomType.*,
	|	HotelProduct.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Service.*,
	|	ParentDoc.*,
	|	Sales,
	|	RoomRevenue,
	|	SalesWithoutVAT,
	|	RoomRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	Quantity,
	|	AccountingDate,
	|	(WEEK(HotelProductSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(HotelProductSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(HotelProductSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(HotelProductSales.AccountingDate)) AS AccountingYear,
	|	HotelProductSales.Folio.*,
	|	HotelProductSales.Client.*,
	|	HotelProductSales.Price,
	|	HotelProductSales.Service.*,
	|	HotelProductSales.RoomRate.*,
	|	HotelProductSales.Room.*,
	|	HotelProductSales.AccommodationType.*,
	|	HotelProductSales.ClientType.*,
	|	HotelProductSales.TripPurpose.*,
	|	HotelProductSales.MarketingCode.*,
	|	HotelProductSales.SourceOfBusiness.*,
	|	HotelProductSales.Resource.*,
	|	HotelProductSales.ResourceType.*,
	|	HotelProductSales.Author.*,
	|	HotelProductSales.Discount,
	|	HotelProductSales.DiscountType.*,
	|	HotelProductSales.DiscountCard.*,
	|	HotelProductSales.AgentCommission,
	|	HotelProductSales.AgentCommissionType.*,
	|	HotelProductSales.PaymentMethod.*,
	|	HotelProductSales.VATRate.*,
	|	HotelProductSales.Company.*}
	|TOTALS
	|	SUM(Sales),
	|	SUM(RoomRevenue),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(RoomsRented),
	|	SUM(BedsRented),
	|	SUM(AdditionalBedsRented),
	|	SUM(GuestDays),
	|	SUM(GuestsCheckedIn),
	|	SUM(RoomsCheckedIn),
	|	SUM(BedsCheckedIn),
	|	SUM(AdditionalBedsCheckedIn),
	|	SUM(Quantity)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	RoomType HIERARCHY,
	|	HotelProduct HIERARCHY
	|{TOTALS BY
	|	HotelProductSales.ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	HotelProductSales.Hotel.*,
	|	HotelProductSales.RoomType.*,
	|	HotelProductSales.HotelProduct.*,
	|	HotelProductSales.Agent.*,
	|	HotelProductSales.Customer.*,
	|	HotelProductSales.Contract.*,
	|	HotelProductSales.GuestGroup.*,
	|	HotelProductSales.ParentDoc.*,
	|	HotelProductSales.Service.*,
	|	HotelProductSales.AccountingDate,
	|	(WEEK(HotelProductSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(HotelProductSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(HotelProductSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(HotelProductSales.AccountingDate)) AS AccountingYear,
	|	HotelProductSales.Folio.*,
	|	HotelProductSales.Client.*,
	|	HotelProductSales.Price,
	|	HotelProductSales.RoomRate.*,
	|	HotelProductSales.Room.*,
	|	HotelProductSales.AccommodationType.*,
	|	HotelProductSales.ClientType.*,
	|	HotelProductSales.TripPurpose.*,
	|	HotelProductSales.MarketingCode.*,
	|	HotelProductSales.SourceOfBusiness.*,
	|	HotelProductSales.Resource.*,
	|	HotelProductSales.ResourceType.*,
	|	HotelProductSales.Author.*,
	|	HotelProductSales.Discount,
	|	HotelProductSales.DiscountType.*,
	|	HotelProductSales.DiscountCard.*,
	|	HotelProductSales.AgentCommission,
	|	HotelProductSales.AgentCommissionType.*,
	|	HotelProductSales.PaymentMethod.*,
	|	HotelProductSales.VATRate.*,
	|	HotelProductSales.Company.*,
	|	HotelProductSales.Hotel.*,
	|	HotelProductSales.ReportingCurrency.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Hotel product sales turnovers';RU='Обороты продаж путевок и курсовок';de='Umsätze der Verkäufe von Reiseschecks und Kurkarten'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sales" 
	   Or pName = "RoomRevenue" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "RoomsRented" 
	   Or pName = "BedsRented" 
	   Or pName = "AdditionalBedsRented" 
	   Or pName = "GuestDays" 
	   Or pName = "GuestsCheckedIn" 
	   Or pName = "RoomsCheckedIn" 
	   Or pName = "BedsCheckedIn" 
	   Or pName = "AdditionalBedsCheckedIn" 
	   Or pName = "Quantity" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
