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
			vParamPresentation = vParamPresentation + NStr("ru = 'Набор услуг '; en = 'Service group '; de = 'Dientsgruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа наборов услуг '; en = 'Service groups folder '; de = 'Dientsgruppengruppe '") + 
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
	ReportBuilder.Parameters.Insert("qService", Service);
	
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
			vQryText = StrReplace(vQryText, "ServiceSales." + vReportDimensionsUsageRow.Name + " AS ", "NULL AS ");
			vQryText = StrReplace(vQryText, "ServiceSales." + vReportDimensionsUsageRow.Name + ".*,", "");
			If vReportDimensionsUsageRow.Name = "AccountingDate" Then
				vQryText = StrReplace(vQryText, "WEEK(ServiceSales.AccountingDate)", "0");
				vQryText = StrReplace(vQryText, "MONTH(ServiceSales.AccountingDate)", "0");
				vQryText = StrReplace(vQryText, "QUARTER(ServiceSales.AccountingDate)", "0");
				vQryText = StrReplace(vQryText, "YEAR(ServiceSales.AccountingDate)", "0");
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
	|	ServiceSales.Hotel AS Hotel,
	|	ServiceSales.Company AS Company,
	|	ServiceSales.ReportingCurrency AS ReportingCurrency,
	|	ServiceSales.Service AS Service,
	|	ServiceSales.PaymentMethod AS PaymentMethod,
	|	ServiceSales.ClientType AS ClientType,
	|	ServiceSales.MarketingCode AS MarketingCode,
	|	ServiceSales.SourceOfBusiness AS SourceOfBusiness,
	|	ServiceSales.Price AS Price,
	|	ServiceSales.AccountingDate AS AccountingDate,
	|	ServiceSales.ServiceDate AS ServiceDate,
	|	ServiceSales.ParentDoc AS ParentDoc,
	|	ServiceSales.Folio AS Folio,
	|	ServiceSales.QuantityTurnover AS Quantity,
	|	ServiceSales.SalesTurnover AS Sum,
	|	ServiceSales.SalesWithoutVATTurnover AS SumWithoutVAT,
	|	ServiceSales.CommissionSumTurnover AS CommissionSum,
	|	ServiceSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|	ServiceSales.DiscountSumTurnover AS DiscountSum,
	|	ServiceSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT
	|{SELECT
	|	Hotel.*,
	|	Company.*,
	|	ReportingCurrency.*,
	|	Service.*,
	|	PaymentMethod.*,
	|	ClientType.*,
	|	MarketingCode.*,
	|	SourceOfBusiness.*,
	|	ServiceSales.ServicePackage.*,
	|	ServiceSales.RoomType.*,
	|	Price,
	|	ParentDoc.*,
	|	Folio.*,
	|	Quantity,
	|	Sum,
	|	SumWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	(CASE
	|			WHEN NOT ServiceSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	AccountingDate,
	|	ServiceDate,
	|	(WEEK(ServiceSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(ServiceSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(ServiceSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(ServiceSales.AccountingDate)) AS AccountingYear}
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (ParentDoc.Customer IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (ParentDoc.Contract = &qContract
	|					OR &qIsEmptyContract)
	|				AND (ParentDoc.GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|				AND Service IN HIERARCHY (&qService)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS ServiceSales
	|{WHERE
	|	ServiceSales.Hotel.*,
	|	ServiceSales.Company.*,
	|	ServiceSales.ReportingCurrency.*,
	|	ServiceSales.Service.*,
	|	ServiceSales.PaymentMethod.*,
	|	ServiceSales.ClientType.*,
	|	ServiceSales.MarketingCode.*,
	|	ServiceSales.SourceOfBusiness.*,
	|	ServiceSales.ServicePackage.*,
	|	ServiceSales.RoomType.*,
	|	ServiceSales.Price,
	|	ServiceSales.ParentDoc.*,
	|	ServiceSales.Folio.*,
	|	ServiceSales.QuantityTurnover AS Quantity,
	|	ServiceSales.SalesTurnover AS Sum,
	|	ServiceSales.SalesWithoutVATTurnover AS SumWithoutVAT,
	|	ServiceSales.CommissionSumTurnover AS CommissionSum,
	|	ServiceSales.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|	ServiceSales.DiscountSumTurnover AS DiscountSum,
	|	ServiceSales.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|	(CASE
	|			WHEN NOT ServiceSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	ServiceSales.ServiceDate,
	|	(WEEK(ServiceSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(ServiceSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(ServiceSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(ServiceSales.AccountingDate)) AS AccountingYear}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Service
	|{ORDER BY
	|	Hotel.*,
	|	Company.*,
	|	ReportingCurrency.*,
	|	Service.*,
	|	PaymentMethod.*,
	|	ClientType.*,
	|	MarketingCode.*,
	|	SourceOfBusiness.*,
	|	ServiceSales.ServicePackage.*,
	|	ServiceSales.RoomType.*,
	|	Price,
	|	ParentDoc.*,
	|	Folio.*,
	|	Quantity AS Quantity,
	|	Sum AS Sum,
	|	SumWithoutVAT AS SumWithoutVAT,
	|	CommissionSum AS CommissionSum,
	|	CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	DiscountSum AS DiscountSum,
	|	DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	(CASE
	|			WHEN NOT ServiceSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	AccountingDate,
	|	ServiceDate,
	|	(WEEK(ServiceSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(ServiceSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(ServiceSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(ServiceSales.AccountingDate)) AS AccountingYear}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(Sum),
	|	SUM(SumWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Service HIERARCHY
	|{TOTALS BY
	|	Hotel.*,
	|	Company.*,
	|	ReportingCurrency.*,
	|	Service.*,
	|	PaymentMethod.*,
	|	ClientType.*,
	|	MarketingCode.*,
	|	SourceOfBusiness.*,
	|	ServiceSales.ServicePackage.*,
	|	ServiceSales.RoomType.*,
	|	ParentDoc.*,
	|	Folio.*,
	|	Price,
	|	(CASE
	|			WHEN NOT ServiceSales.GuestGroup.GroupType.Code IS NULL
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsGroupReservation,
	|	AccountingDate,
	|	ServiceDate,
	|	(WEEK(ServiceSales.AccountingDate)) AS AccountingWeek,
	|	(MONTH(ServiceSales.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(ServiceSales.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(ServiceSales.AccountingDate)) AS AccountingYear}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Service sales turnovers';ru='Обороты продаж услуг';de='Umsätze der Dienstleistungsverkäufe'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sum" 
	   Or pName = "SumWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "Quantity" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
