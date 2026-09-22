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
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfYear(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfQuarter(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(Company) Then
			Company = Hotel.Company;
		EndIf;
		If Not ValueIsFilled(RussiaCountry) Then
			RussiaCountry = Hotel.Citizenship;
		EndIf;
	EndIf;
	If Not ValueIsFilled(CurrencyUSD) Then
		CurrencyUSD = Catalogs.Currencies.FindByCode(840, False);
	EndIf;
	If Not ValueIsFilled(ServicesClassifierCode) Then
		ServicesClassifierCode = Enums.VESServicesClassifier.HotelServices;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report");
	
	// Report header
	vHeaderArea = vTemplate.GetArea("Header");
	
	// 1. Header parameters
	vHeaderArea.Parameters.mPeriodStr = PeriodPresentation(BegOfQuarter(PeriodTo), EndOfDay(PeriodTo), cmLocalizationCode());
	vHeaderArea.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vHeaderArea.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vHeaderArea.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	
	// Put header
	pSpreadsheet.Put(vHeaderArea);
	
	// Add page break
	pSpreadsheet.PutHorizontalPageBreak();
	
	// 2. Part 1 header
	vPart1HeaderArea = vTemplate.GetArea("Part1Header");
	
	// Put part 1 header
	pSpreadsheet.Put(vPart1HeaderArea);
	
	// 2.2 Get USD currency
	If Not ValueIsFilled(CurrencyUSD) Then
		CurrencyUSD = Catalogs.Currencies.FindByCode(840, False);
	EndIf;
	
	// 2.5 Get total sales per country 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GeographicSalesTurnovers.Client.Citizenship AS Country,
	|	GeographicSalesTurnovers.ReportingCurrency AS Currency,
	|	SUM(GeographicSalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection AND Hotel = &qHotel
	|				AND Company = &qCompany
	|				AND Client.Citizenship <> &qRussiaCountry
	|				AND (Service IN HIERARCHY (&qIncomeServices)
	|					OR (NOT &qUseServicesList))) AS GeographicSalesTurnovers
	|
	|GROUP BY
	|	GeographicSalesTurnovers.Client.Citizenship,
	|	GeographicSalesTurnovers.ReportingCurrency
	|
	|ORDER BY
	|	GeographicSalesTurnovers.Client.Citizenship.Code";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRussiaCountry", RussiaCountry);
	vQry.SetParameter("qCompany", Company);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(IncomeServiceGroup) And Not IncomeServiceGroup.IncludeAll Then
		vUseServicesList = True;
		vServicesList = cmGetServiceGroupServices(IncomeServiceGroup);
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qIncomeServices", vServicesList);
	vQryResult = vQry.Execute().Unload();
	
	// Recalculate currencies to USD
	For Each vQryResultRow In vQryResult Do
		vQryResultRow.SalesWithoutVATTurnover = cmConvertCurrencies(vQryResultRow.SalesWithoutVATTurnover, vQryResultRow.Currency, , ?(ValueIsFilled(CurrencyUSD), CurrencyUSD, vQryResultRow.Currency), , CurrentSessionDate(), Hotel);
	EndDo;
	vQryResult.GroupBy("Country", "SalesWithoutVATTurnover");
	
	// 2.6 Put row for each country
	vPart1RowArea = vTemplate.GetArea("Part1Row");
	
	For Each vQryResultRow In vQryResult Do
		If ValueIsFilled(vQryResultRow.Country) And vQryResultRow.SalesWithoutVATTurnover <> 0 Then
			vPart1RowArea.Parameters.mCountry = TrimAll(vQryResultRow.Country);
			vPart1RowArea.Parameters.mCountryCode = TrimAll(vQryResultRow.Country.Code);
			If ServicesClassifierCode = Enums.VESServicesClassifier.HotelServices Then
				vPart1RowArea.Parameters.mServicesClassifierName = "Услуги гостиниц";
				vPart1RowArea.Parameters.mServicesClassifierCode = "996411";
			ElsIf ServicesClassifierCode = Enums.VESServicesClassifier.MotelServices Then
				vPart1RowArea.Parameters.mServicesClassifierName = "Услуги мотелей";
				vPart1RowArea.Parameters.mServicesClassifierCode = "996412";
			ElsIf ServicesClassifierCode = Enums.VESServicesClassifier.AccommodationServices Then
				vPart1RowArea.Parameters.mServicesClassifierName = "Услуги прочих мест проживания";
				vPart1RowArea.Parameters.mServicesClassifierCode = "996419";
			EndIf;
			vPart1RowArea.Parameters.mSum = Round(vQryResultRow.SalesWithoutVATTurnover/1000, 1);
			// Put part 1 header
			pSpreadsheet.Put(vPart1RowArea);
		EndIf;
	EndDo;
	
	// 3. Part 1 footer
	vPart1FooterArea = vTemplate.GetArea("Part1Footer");
	
	// Put part 1 header
	pSpreadsheet.Put(vPart1FooterArea);
EndProcedure // pmGenerate
