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
		PeriodFrom = BegOfDay(CurrentSessionDate());
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
			vParamPresentation = vParamPresentation + NStr("ru = 'Путевка '; en = 'Vaucher '; de = 'Einweisung '") + 
			                     TrimAll(HotelProduct.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Тип путевок/курсовок '; en = 'Vaucher type '; de = 'Einweisungtyp '") + 
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
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа гостей '; en = 'Guest group '; de = 'Gastgruppe '") + 
							 TrimAll(TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description)) + 
							 ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qIsEmptyPeriodTo", Not ValueIsFilled(PeriodTo));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qHotelProduct", HotelProduct);
	ReportBuilder.Parameters.Insert("qIsEmptyHotelProduct", Not ValueIsFilled(HotelProduct));
	ReportBuilder.Parameters.Insert("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	
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
	|	IssuedHotelProducts.Recorder.Date AS RecorderDate,
	|	IssuedHotelProducts.ProductCode AS ProductCode,
	|	IssuedHotelProducts.Recorder,
	|	IssuedHotelProducts.Company,
	|	IssuedHotelProducts.Customer,
	|	IssuedHotelProducts.Contract,
	|	IssuedHotelProducts.GuestGroup,
	|	IssuedHotelProducts.BillOfShipment,
	|	IssuedHotelProducts.HotelProductParent,
	|	IssuedHotelProducts.CheckInDate,
	|	IssuedHotelProducts.Duration,
	|	IssuedHotelProducts.CheckOutDate,
	|	IssuedHotelProducts.Price,
	|	IssuedHotelProducts.Currency,
	|	IssuedHotelProducts.Price AS Sum,
	|	1 AS Count
	|{SELECT
	|	RecorderDate,
	|	ProductCode,
	|	Recorder.*,
	|	(BEGINOFPERIOD(IssuedHotelProducts.Recorder.Date, DAY)) AS ShipmentDate,
	|	(WEEK(IssuedHotelProducts.Recorder.Date)) AS ShipmentWeek,
	|	(MONTH(IssuedHotelProducts.Recorder.Date)) AS ShipmentMonth,
	|	(QUARTER(IssuedHotelProducts.Recorder.Date)) AS ShipmentQuarter,
	|	(YEAR(IssuedHotelProducts.Recorder.Date)) AS ShipmentYear,
	|	IssuedHotelProducts.Hotel.*,
	|	Company.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	BillOfShipment,
	|	HotelProductParent.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	Price,
	|	Currency.*,
	|	Sum,
	|	Count}
	|FROM
	|	InformationRegister.IssuedHotelProducts AS IssuedHotelProducts
	|WHERE
	|	(IssuedHotelProducts.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (IssuedHotelProducts.Customer IN HIERARCHY (&qCustomer)
	|			OR &qIsEmptyCustomer)
	|	AND (IssuedHotelProducts.Contract = &qContract
	|			OR &qIsEmptyContract)
	|	AND (IssuedHotelProducts.GuestGroup = &qGuestGroup
	|			OR &qIsEmptyGuestGroup)
	|	AND (IssuedHotelProducts.HotelProductParent IN HIERARCHY (&qHotelProduct)
	|			OR &qIsEmptyHotelProduct)
	|	AND IssuedHotelProducts.Recorder.Date >= &qPeriodFrom
	|	AND (IssuedHotelProducts.Recorder.Date <= &qPeriodTo
	|			OR &qIsEmptyPeriodTo)
	|{WHERE
	|	IssuedHotelProducts.Recorder.Date AS RecorderDate,
	|	IssuedHotelProducts.ProductCode,
	|	IssuedHotelProducts.Recorder.*,
	|	IssuedHotelProducts.Hotel.*,
	|	IssuedHotelProducts.Company.*,
	|	IssuedHotelProducts.Customer.*,
	|	IssuedHotelProducts.Contract.*,
	|	IssuedHotelProducts.GuestGroup.*,
	|	IssuedHotelProducts.BillOfShipment,
	|	IssuedHotelProducts.HotelProductParent.*,
	|	IssuedHotelProducts.CheckInDate,
	|	IssuedHotelProducts.Duration,
	|	IssuedHotelProducts.CheckOutDate,
	|	IssuedHotelProducts.Price,
	|	IssuedHotelProducts.Currency.*,
	|	IssuedHotelProducts.Price AS Sum,
	|	(1) AS Count}
	|
	|ORDER BY
	|	RecorderDate,
	|	ProductCode
	|{ORDER BY
	|	RecorderDate,
	|	ProductCode,
	|	Recorder.*,
	|	IssuedHotelProducts.Hotel.*,
	|	Company.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	BillOfShipment,
	|	HotelProductParent.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	Price,
	|	Currency.*,
	|	Sum,
	|	Count}
	|TOTALS
	|	SUM(Sum),
	|	SUM(Count)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Recorder.*,
	|	(BEGINOFPERIOD(IssuedHotelProducts.Recorder.Date, DAY)) AS ShipmentDate,
	|	(WEEK(IssuedHotelProducts.Recorder.Date)) AS ShipmentWeek,
	|	(MONTH(IssuedHotelProducts.Recorder.Date)) AS ShipmentMonth,
	|	(QUARTER(IssuedHotelProducts.Recorder.Date)) AS ShipmentQuarter,
	|	(YEAR(IssuedHotelProducts.Recorder.Date)) AS ShipmentYear,
	|	IssuedHotelProducts.Hotel.*,
	|	Company.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	BillOfShipment,
	|	HotelProductParent.*,
	|	Currency.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Issued hotel products';RU='Отгруженные путевки';de='Verschickte Reiseschecks'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
