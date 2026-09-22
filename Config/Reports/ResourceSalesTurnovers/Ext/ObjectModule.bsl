
#Region Public

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
	If ValueIsFilled(Resource) Then
		vParamPresentation = vParamPresentation + NStr("en='Resource ';ru='Ресурс ';de='Ressource '") + 
							 TrimAll(Resource.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(ResourceType) Then
		If Not ResourceType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Resource type ';ru='Тип ресурса ';de='Ressourcentyp '") + 
			                     TrimAll(ResourceType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Resource types folder ';ru='Группа типов ресурсов ';de='Ressourcentypengruppe '") + 
			                     TrimAll(ResourceType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Service) Then
		If Not Service.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Service ';ru='Услуга ';de='Dienstleistung '") + 
								 TrimAll(Service.Description) + 
								 ";" + Chars.LF;
		 Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа услуг '; en = 'Services folder '; de = 'Dienstleistungengruppe '") + 
								 TrimAll(Service.Description) + 
								 ";" + Chars.LF;
		 EndIf;							 
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
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
			                     TrimAll(Hotel.Description) + 
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
	ReportBuilder.Parameters.Insert("qResource", Resource);
	ReportBuilder.Parameters.Insert("qIsEmptyResource", Not ValueIsFilled(Resource));
	ReportBuilder.Parameters.Insert("qResourceType", ResourceType);
	ReportBuilder.Parameters.Insert("qIsEmptyResourceType", Not ValueIsFilled(ResourceType));
	ReportBuilder.Parameters.Insert("qEmptyResourceType", Catalogs.ResourceTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qIsEmptyService", Not ValueIsFilled(Service));
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(ServiceGroup);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qUseServicesList", vUseServicesList);
	ReportBuilder.Parameters.Insert("qServicesList", vServicesList);
	
	// Check report dimensions being used in current report settings
	vReportDimensionsUsage = New ValueTable();
	vReportDimensionsUsage.Columns.Add("Name");
	vReportDimensionsUsage.Columns.Add("IsUsed", cmGetBooleanTypeDescription());
	For Each vDim In Metadata.AccumulationRegisters.Sales.Dimensions Do
		vReportDimensionsUsageRow = vReportDimensionsUsage.Add();
		vReportDimensionsUsageRow.Name = vDim.Name;
		vReportDimensionsUsageRow.IsUsed = False;
	EndDo;
	vSelectedFields = cmGetReportUsedFields(ReportBuilder);
	For Each vReportDimensionsUsageRow In vReportDimensionsUsage Do
		For Each vReportField In vSelectedFields Do
			If vReportField.DataPath = vReportDimensionsUsageRow.Name Or Left(vReportField.DataPath, StrLen(vReportDimensionsUsageRow.Name)) = vReportDimensionsUsageRow.Name Then
				vReportDimensionsUsageRow.IsUsed = True;
			EndIf;
			If vReportDimensionsUsageRow.Name = "AccountingDate" Then
				If vReportField.DataPath = "AccountingWeek" Or vReportField.DataPath = "AccountingWeekday" Or vReportField.DataPath = "AccountingWeekdayName" Or 
				   vReportField.DataPath = "AccountingMonth" Or vReportField.DataPath = "AccountingQuarter" Or vReportField.DataPath = "AccountingYear" Or
				   vReportField.DataPath = "AccountingDay" Then
					vReportDimensionsUsageRow.IsUsed = True;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	vRBSettings = ReportBuilder.GetSettings(True, True, True, True, True);
	vQryText = ReportBuilder.Text;
	For Each vReportDimensionsUsageRow In vReportDimensionsUsage Do
		If Not vReportDimensionsUsageRow.IsUsed Then
			vQryText = StrReplace(vQryText, "ResourceSales." + vReportDimensionsUsageRow.Name + " AS ", "NULL AS ");
			vQryText = StrReplace(vQryText, "ResourceSales." + vReportDimensionsUsageRow.Name + ".*,", "");
			If vReportDimensionsUsageRow.Name = "AccountingDate" Then
				vQryText = StrReplace(vQryText, "WEEK(ResourceSales.AccountingDate)", "0");
				vQryText = StrReplace(vQryText, "MONTH(ResourceSales.AccountingDate)", "0");
				vQryText = StrReplace(vQryText, "QUARTER(ResourceSales.AccountingDate)", "0");
				vQryText = StrReplace(vQryText, "YEAR(ResourceSales.AccountingDate)", "0");
			EndIf;				
		EndIf;
	EndDo;
	ReportBuilder.Text = vQryText;
	ReportBuilder.FillSettings();
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	cmFillReportAttributesPresentations(ThisObject);
	ReportBuilder.Template = Undefined;
	
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
	
	// Restore report default query text
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	cmFillReportAttributesPresentations(ThisObject);
	ReportBuilder.Template = Undefined;
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	ResourceSales.Company AS Company,
	|	ResourceSales.Hotel AS Hotel,
	|	ResourceSales.ReportingCurrency AS ReportingCurrency,
	|	ResourceSales.Resource AS Resource,
	|	ResourceSales.ResourceType AS ResourceType,
	|	ResourceSales.EventActivity AS EventActivity,
	|	ResourceSales.ClientType AS ClientType,
	|	ResourceSales.Service AS Service,
	|	ResourceSales.AccountingDate AS AccountingDate,
	|	ResourceSales.ParentDoc AS ParentDoc,
	|	ResourceSales.SalesTurnover AS Sum,
	|	ResourceSales.ResourceRevenueTurnover AS ResourceRevenue,
	|	ResourceSales.SalesWithoutVATTurnover AS SumWithoutVAT,
	|	ResourceSales.ResourceRevenueWithoutVATTurnover AS ResourceRevenueWithoutVAT,
	|	ResourceSales.CommissionSumTurnover AS CommissionSum,
	|	ResourceSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|	ResourceSales.DiscountSumTurnover AS DiscountSum,
	|	ResourceSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|	CASE
	|		WHEN ResourceSales.Service.RoomRevenueAmountsOnly
	|			THEN 0
	|		ELSE ResourceSales.HoursRentedTurnover
	|	END AS HoursRented,
	|	ResourceSales.QuantityTurnover AS Quantity,
	|	ResourceSales.ParentDoc.NumberOfPersons AS NumberOfPersons
	|{SELECT
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Resource.*,
	|	ResourceType.*,
	|	EventActivity.*,
	|	ClientType.*,
	|	ResourceSales.ParentDoc.ResourceTariff.* AS ResourceTariff,
	|	ResourceSales.MarketingCode.*,
	|	ResourceSales.SourceOfBusiness.*,
	|	ResourceSales.Agent.*,
	|	ResourceSales.Customer.*,
	|	ResourceSales.Contract.*,
	|	ResourceSales.GuestGroup.*,
	|	ResourceSales.Company.*,
	|	Service.*,
	|	ParentDoc.*,
	|	Sum,
	|	ResourceRevenue,
	|	SumWithoutVAT,
	|	ResourceRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	HoursRented,
	|	Quantity,
	|	AccountingDate,
	|	(WEEK(ResourceSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(ResourceSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(ResourceSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(ResourceSales.AccountingDate)) AS AccountingYear,
	|	NumberOfPersons}
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			NOT IsCorrection
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (Resource = &qResource
	|					OR &qIsEmptyResource)
	|				AND (ResourceType IN HIERARCHY (&qResourceType)
	|					OR &qIsEmptyResourceType)
	|				AND ResourceType <> &qEmptyResourceType
	|				AND (Service IN HIERARCHY (&qService)
	|					OR &qIsEmptyService)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS ResourceSales
	|{WHERE
	|	ResourceSales.Company.*,
	|	ResourceSales.Hotel.*,
	|	ResourceSales.ReportingCurrency.*,
	|	ResourceSales.Resource.*,
	|	ResourceSales.ResourceType.*,
	|	ResourceSales.ParentDoc.ResourceTariff.* AS ResourceTariff,
	|	ResourceSales.EventActivity.* AS EventActivity,
	|	ResourceSales.ClientType.*,
	|	ResourceSales.MarketingCode.* AS MarketingCode,
	|	ResourceSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	ResourceSales.ParentDoc.*,
	|	ResourceSales.Service.*,
	|	ResourceSales.SalesTurnover AS Sum,
	|	ResourceSales.ResourceRevenueTurnover AS ResourceRevenue,
	|	ResourceSales.SalesWithoutVATTurnover AS SumWithoutVAT,
	|	ResourceSales.ResourceRevenueWithoutVATTurnover AS ResourceRevenueWithoutVAT,
	|	ResourceSales.CommissionSumTurnover AS CommissionSum,
	|	ResourceSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|	ResourceSales.DiscountSumTurnover AS DiscountSum,
	|	ResourceSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|	(CASE
	|			WHEN ResourceSales.Service.RoomRevenueAmountsOnly
	|				THEN 0
	|			ELSE ResourceSales.HoursRentedTurnover
	|		END) AS HoursRented,
	|	ResourceSales.QuantityTurnover AS Quantity,
	|	ResourceSales.AccountingDate,
	|	(WEEK(ResourceSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(ResourceSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(ResourceSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(ResourceSales.AccountingDate)) AS AccountingYear,
	|	ResourceSales.Agent.*,
	|	ResourceSales.Customer.*,
	|	ResourceSales.Contract.*,
	|	ResourceSales.GuestGroup.*,
	|	ResourceSales.Company.*}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Resource
	|{ORDER BY
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Resource.*,
	|	ResourceType.*,
	|	EventActivity.*,
	|	ClientType.*,
	|	ResourceSales.ParentDoc.ResourceTariff.* AS ResourceTariff,
	|	ResourceSales.MarketingCode.* AS MarketingCode,
	|	ResourceSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	Service.*,
	|	ParentDoc.*,
	|	Sum,
	|	ResourceRevenue,
	|	SumWithoutVAT,
	|	ResourceRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	HoursRented,
	|	AccountingDate,
	|	(WEEK(ResourceSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(ResourceSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(ResourceSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(ResourceSales.AccountingDate)) AS AccountingYear,
	|	ResourceSales.Agent.*,
	|	ResourceSales.Customer.*,
	|	ResourceSales.Contract.*,
	|	ResourceSales.GuestGroup.*,
	|	ResourceSales.Company.*}
	|TOTALS
	|	SUM(Sum),
	|	SUM(ResourceRevenue),
	|	SUM(SumWithoutVAT),
	|	SUM(ResourceRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(HoursRented),
	|	SUM(Quantity),
	|	SUM(NumberOfPersons)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Resource HIERARCHY
	|{TOTALS BY
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Resource.*,
	|	ResourceType.*,
	|	EventActivity.*,
	|	ClientType.*,
	|	ResourceSales.ParentDoc.ResourceTariff.* AS ResourceTariff,
	|	ResourceSales.MarketingCode.* AS MarketingCode,
	|	ResourceSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	ParentDoc.*,
	|	Service.*,
	|	AccountingDate,
	|	(WEEK(ResourceSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(ResourceSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(ResourceSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(ResourceSales.AccountingDate)) AS AccountingYear,
	|	ResourceSales.Agent.*,
	|	ResourceSales.Customer.*,
	|	ResourceSales.Contract.*,
	|	ResourceSales.GuestGroup.*,
	|	ResourceSales.Company.*,
	|	NumberOfPersons}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Resource sales turnovers';RU='Обороты по продажам ресурсов';de='Umsätze zu Ressourcenverkäufen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sum" 
	   Or pName = "ResourceRevenue" 
	   Or pName = "SumWithoutVAT" 
	   Or pName = "ResourceRevenueWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "HoursRented" 
	   Or pName = "Quantity" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

#EndRegion
