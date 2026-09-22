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
	If Not ValueIsFilled(Company) Then
		If ValueIsFilled(Hotel) Then
			Company = Hotel.Company;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg. of month
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfMonth(CurrentSessionDate()); // For end of month
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
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа гостей '; en = 'Guest group '; de = 'Gruppe '") + 
							 TrimAll(TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description)) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Набор услуг '; en = 'Service group '; de = 'Dienstgruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа наборов услуг '; en = 'Service groups folder '; de = 'Dienstgruppegruppen '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Фирма '; en = 'Company '; de = 'Kompanie '") + 
			                     Company.GetObject().pmGetCompanyPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа фирм '; en = 'Companies folder '; de = 'Kompaniegruppe '") + 
			                     Company.GetObject().pmGetCompanyPrintName(SessionParameters.CurrentLanguage) + 
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
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qIsEmptyCompany", Not ValueIsFilled(Company));
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
	|	CurrentAccountsReceivable.Company AS Company,
	|	CurrentAccountsReceivable.Customer AS Customer,
	|	CurrentAccountsReceivable.Contract AS Contract,
	|	CurrentAccountsReceivable.GuestGroup AS GuestGroup,
	|	CurrentAccountsReceivable.FolioClient AS FolioClient,
	|	CurrentAccountsReceivable.FolioRoom AS FolioRoom,
	|	CurrentAccountsReceivable.Service AS Service,
	|	CurrentAccountsReceivable.CommissionSumOpeningBalance AS CommissionSumOpeningBalance,
	|	CurrentAccountsReceivable.SumOpeningBalance AS SumOpeningBalance,
	|	CurrentAccountsReceivable.QuantityOpeningBalance AS QuantityOpeningBalance,
	|	CurrentAccountsReceivable.CommissionSumTurnover AS CommissionSumTurnover,
	|	CurrentAccountsReceivable.SumTurnover AS SumTurnover,
	|	CurrentAccountsReceivable.VATSumTurnover AS VATSumTurnover,
	|	CurrentAccountsReceivable.QuantityTurnover AS QuantityTurnover,
	|	CurrentAccountsReceivable.CommissionSumClosingBalance AS CommissionSumClosingBalance,
	|	CurrentAccountsReceivable.SumClosingBalance AS SumClosingBalance,
	|	CurrentAccountsReceivable.QuantityClosingBalance AS QuantityClosingBalance,
	|	CurrentAccountsReceivable.CommissionSumReceipt AS CommissionSumReceipt,
	|	CurrentAccountsReceivable.SumReceipt AS SumReceipt,
	|	CurrentAccountsReceivable.CommissionSumExpense AS CommissionSumExpense,
	|	CurrentAccountsReceivable.SumExpense AS SumExpense,
	|	CurrentAccountsReceivable.VATSumReceipt AS VATSumReceipt,
	|	CurrentAccountsReceivable.VATSumExpense AS VATSumExpense,
	|	CurrentAccountsReceivable.QuantityReceipt AS QuantityReceipt,
	|	CurrentAccountsReceivable.QuantityExpense AS QuantityExpense
	|{SELECT
	|	Company.*,
	|	CurrentAccountsReceivable.Hotel.*,
	|	CurrentAccountsReceivable.FolioCurrency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	CurrentAccountsReceivable.ParentDoc.* AS ParentDoc,
	|	CurrentAccountsReceivable.Folio.* AS Folio,
	|	FolioClient.* AS FolioClient,
	|	FolioRoom.* AS FolioRoom,
	|	CurrentAccountsReceivable.RoomType.* AS RoomType,
	|	Service.* AS Service,
	|	CurrentAccountsReceivable.Charge.* AS Charge,
	|	CurrentAccountsReceivable.VATRate.* AS VATRate,
	|	CurrentAccountsReceivable.IsCheckedOutAtThePeriodEnd AS IsCheckedOutAtThePeriodEnd,
	|	CurrentAccountsReceivable.ChangeInPreviousAccountingPeriod AS ChangeInPreviousAccountingPeriod,
	|	CommissionSumOpeningBalance AS CommissionSumOpeningBalance,
	|	SumOpeningBalance AS SumOpeningBalance,
	|	QuantityOpeningBalance AS QuantityOpeningBalance,
	|	CommissionSumTurnover AS CommissionSumTurnover,
	|	SumTurnover AS SumTurnover,
	|	VATSumTurnover AS VATSumTurnover,
	|	QuantityTurnover AS QuantityTurnover,
	|	CommissionSumClosingBalance AS CommissionSumClosingBalance,
	|	SumClosingBalance AS SumClosingBalance,
	|	QuantityClosingBalance AS QuantityClosingBalance,
	|	CommissionSumReceipt,
	|	SumReceipt,
	|	CommissionSumExpense,
	|	SumExpense,
	|	VATSumReceipt,
	|	VATSumExpense,
	|	QuantityReceipt,
	|	QuantityExpense}
	|FROM
	|	(SELECT
	|		CurrentAccountsReceivableBalanceAndTurnovers.Hotel AS Hotel,
	|		CurrentAccountsReceivableBalanceAndTurnovers.Company AS Company,
	|		CASE
	|			WHEN CurrentAccountsReceivableBalanceAndTurnovers.Customer = VALUE(Catalog.Customers.EmptyRef)
	|				THEN CurrentAccountsReceivableBalanceAndTurnovers.Hotel.IndividualsCustomer
	|			ELSE CurrentAccountsReceivableBalanceAndTurnovers.Customer
	|		END AS Customer,
	|		CASE
	|			WHEN CurrentAccountsReceivableBalanceAndTurnovers.Customer = VALUE(Catalog.Customers.EmptyRef)
	|				THEN CurrentAccountsReceivableBalanceAndTurnovers.Hotel.IndividualsContract
	|			ELSE CurrentAccountsReceivableBalanceAndTurnovers.Contract
	|		END AS Contract,
	|		CurrentAccountsReceivableBalanceAndTurnovers.GuestGroup AS GuestGroup,
	|		CurrentAccountsReceivableBalanceAndTurnovers.Charge.ParentDoc AS ParentDoc,
	|		CurrentAccountsReceivableBalanceAndTurnovers.FolioCurrency AS FolioCurrency,
	|		CurrentAccountsReceivableBalanceAndTurnovers.Charge.Folio AS Folio,
	|		CurrentAccountsReceivableBalanceAndTurnovers.Charge.Folio.Client AS FolioClient,
	|		CurrentAccountsReceivableBalanceAndTurnovers.Charge.Folio.Room AS FolioRoom,
	|		CurrentAccountsReceivableBalanceAndTurnovers.Charge AS Charge,
	|		CurrentAccountsReceivableBalanceAndTurnovers.Charge.Service AS Service,
	|		CurrentAccountsReceivableBalanceAndTurnovers.Charge.VATRate AS VATRate,
	|		CurrentAccountsReceivableBalanceAndTurnovers.Charge.RoomType AS RoomType,
	|		CASE
	|			WHEN CurrentAccountsReceivableBalanceAndTurnovers.Charge.Date < BEGINOFPERIOD(&qPeriodFrom, MONTH)
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS ChangeInPreviousAccountingPeriod,
	|		CASE
	|			WHEN ISNULL(CurrentAccountsReceivableBalanceAndTurnovers.Charge.Folio.DateTimeTo, &qEmptyDate) <= &qPeriodTo
	|					AND ISNULL(CurrentAccountsReceivableBalanceAndTurnovers.Charge.Folio.DateTimeTo, &qEmptyDate) > &qEmptyDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS IsCheckedOutAtThePeriodEnd,
	|		CurrentAccountsReceivableBalanceAndTurnovers.CommissionSumOpeningBalance AS CommissionSumOpeningBalance,
	|		CurrentAccountsReceivableBalanceAndTurnovers.SumOpeningBalance AS SumOpeningBalance,
	|		CurrentAccountsReceivableBalanceAndTurnovers.QuantityOpeningBalance AS QuantityOpeningBalance,
	|		CurrentAccountsReceivableBalanceAndTurnovers.CommissionSumTurnover AS CommissionSumTurnover,
	|		CurrentAccountsReceivableBalanceAndTurnovers.SumTurnover AS SumTurnover,
	|		CurrentAccountsReceivableBalanceAndTurnovers.VATSumTurnover AS VATSumTurnover,
	|		CurrentAccountsReceivableBalanceAndTurnovers.QuantityTurnover AS QuantityTurnover,
	|		CurrentAccountsReceivableBalanceAndTurnovers.CommissionSumClosingBalance AS CommissionSumClosingBalance,
	|		CurrentAccountsReceivableBalanceAndTurnovers.SumClosingBalance AS SumClosingBalance,
	|		CurrentAccountsReceivableBalanceAndTurnovers.QuantityClosingBalance AS QuantityClosingBalance,
	|		CurrentAccountsReceivableBalanceAndTurnovers.CommissionSumReceipt AS CommissionSumReceipt,
	|		CurrentAccountsReceivableBalanceAndTurnovers.SumReceipt AS SumReceipt,
	|		CurrentAccountsReceivableBalanceAndTurnovers.CommissionSumExpense AS CommissionSumExpense,
	|		CurrentAccountsReceivableBalanceAndTurnovers.SumExpense AS SumExpense,
	|		CurrentAccountsReceivableBalanceAndTurnovers.VATSumReceipt AS VATSumReceipt,
	|		CurrentAccountsReceivableBalanceAndTurnovers.VATSumExpense AS VATSumExpense,
	|		CurrentAccountsReceivableBalanceAndTurnovers.QuantityReceipt AS QuantityReceipt,
	|		CurrentAccountsReceivableBalanceAndTurnovers.QuantityExpense AS QuantityExpense
	|	FROM
	|		AccumulationRegister.CurrentAccountsReceivable.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Period,
	|				RegisterRecordsAndPeriodBoundaries,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Company IN HIERARCHY (&qCompany)
	|						OR &qIsEmptyCompany)
	|					AND (Customer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (Contract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (Charge.Service IN (&qServicesList)
	|						OR NOT &qUseServicesList)) AS CurrentAccountsReceivableBalanceAndTurnovers) AS CurrentAccountsReceivable
	|{WHERE
	|	CurrentAccountsReceivable.Company.*,
	|	CurrentAccountsReceivable.Hotel.*,
	|	CurrentAccountsReceivable.FolioCurrency.*,
	|	CurrentAccountsReceivable.Customer.* AS Customer,
	|	CurrentAccountsReceivable.Contract.* AS Contract,
	|	CurrentAccountsReceivable.GuestGroup.*,
	|	CurrentAccountsReceivable.Service.* AS Service,
	|	CurrentAccountsReceivable.Folio.* AS Folio,
	|	CurrentAccountsReceivable.FolioClient.* AS FolioClient,
	|	CurrentAccountsReceivable.FolioRoom.* AS FolioRoom,
	|	CurrentAccountsReceivable.RoomType.* AS RoomType,
	|	CurrentAccountsReceivable.VATRate.* AS VATRate,
	|	CurrentAccountsReceivable.ParentDoc.* AS ParentDoc,
	|	CurrentAccountsReceivable.Charge.*,
	|	CurrentAccountsReceivable.IsCheckedOutAtThePeriodEnd AS IsCheckedOutAtThePeriodEnd,
	|	CurrentAccountsReceivable.ChangeInPreviousAccountingPeriod AS ChangeInPreviousAccountingPeriod,
	|	CurrentAccountsReceivable.CommissionSumTurnover,
	|	CurrentAccountsReceivable.SumTurnover,
	|	CurrentAccountsReceivable.VATSumTurnover,
	|	CurrentAccountsReceivable.QuantityTurnover,
	|	CurrentAccountsReceivable.CommissionSumOpeningBalance,
	|	CurrentAccountsReceivable.SumOpeningBalance,
	|	CurrentAccountsReceivable.CommissionSumClosingBalance,
	|	CurrentAccountsReceivable.SumClosingBalance,
	|	CurrentAccountsReceivable.QuantityOpeningBalance,
	|	CurrentAccountsReceivable.QuantityClosingBalance,
	|	CurrentAccountsReceivable.CommissionSumReceipt,
	|	CurrentAccountsReceivable.SumReceipt,
	|	CurrentAccountsReceivable.CommissionSumExpense,
	|	CurrentAccountsReceivable.SumExpense,
	|	CurrentAccountsReceivable.VATSumReceipt,
	|	CurrentAccountsReceivable.VATSumExpense,
	|	CurrentAccountsReceivable.QuantityReceipt,
	|	CurrentAccountsReceivable.QuantityExpense}
	|
	|ORDER BY
	|	Company,
	|	Customer,
	|	Contract,
	|	GuestGroup,
	|	FolioClient,
	|	FolioRoom,
	|	Service
	|{ORDER BY
	|	CurrentAccountsReceivable.Hotel.*,
	|	Company.*,
	|	CurrentAccountsReceivable.FolioCurrency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Service.* AS Service,
	|	CurrentAccountsReceivable.Folio.* AS Folio,
	|	FolioClient.* AS FolioClient,
	|	FolioRoom.* AS FolioRoom,
	|	CurrentAccountsReceivable.RoomType.* AS RoomType,
	|	CurrentAccountsReceivable.VATRate.* AS VATRate,
	|	CurrentAccountsReceivable.ParentDoc.* AS ParentDoc,
	|	CurrentAccountsReceivable.Charge.*,
	|	CurrentAccountsReceivable.IsCheckedOutAtThePeriodEnd AS IsCheckedOutAtThePeriodEnd,
	|	CurrentAccountsReceivable.ChangeInPreviousAccountingPeriod AS ChangeInPreviousAccountingPeriod,
	|	CommissionSumTurnover,
	|	SumTurnover,
	|	VATSumTurnover,
	|	QuantityTurnover,
	|	CommissionSumOpeningBalance,
	|	SumOpeningBalance,
	|	CommissionSumClosingBalance,
	|	SumClosingBalance,
	|	QuantityOpeningBalance,
	|	QuantityClosingBalance,
	|	CommissionSumReceipt,
	|	SumReceipt,
	|	CommissionSumExpense,
	|	SumExpense,
	|	VATSumReceipt,
	|	VATSumExpense,
	|	QuantityReceipt,
	|	QuantityExpense}
	|TOTALS
	|	SUM(CommissionSumOpeningBalance),
	|	SUM(SumOpeningBalance),
	|	SUM(QuantityOpeningBalance),
	|	SUM(CommissionSumTurnover),
	|	SUM(SumTurnover),
	|	SUM(VATSumTurnover),
	|	SUM(QuantityTurnover),
	|	SUM(CommissionSumClosingBalance),
	|	SUM(SumClosingBalance),
	|	SUM(QuantityClosingBalance),
	|	SUM(CommissionSumReceipt),
	|	SUM(SumReceipt),
	|	SUM(CommissionSumExpense),
	|	SUM(SumExpense),
	|	SUM(VATSumReceipt),
	|	SUM(VATSumExpense),
	|	SUM(QuantityReceipt),
	|	SUM(QuantityExpense)
	|BY
	|	OVERALL,
	|	Company,
	|	Customer HIERARCHY,
	|	Contract,
	|	GuestGroup,
	|	FolioClient,
	|	FolioRoom,
	|	Service
	|{TOTALS BY
	|	CurrentAccountsReceivable.Hotel.*,
	|	Company.*,
	|	CurrentAccountsReceivable.FolioCurrency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Service.* AS Service,
	|	CurrentAccountsReceivable.Folio.* AS Folio,
	|	FolioClient.*,
	|	FolioRoom.*,
	|	CurrentAccountsReceivable.RoomType.* AS RoomType,
	|	CurrentAccountsReceivable.VATRate.* AS VATRate,
	|	CurrentAccountsReceivable.ParentDoc.* AS ParentDoc,
	|	CurrentAccountsReceivable.Charge.*,
	|	CurrentAccountsReceivable.IsCheckedOutAtThePeriodEnd AS IsCheckedOutAtThePeriodEnd,
	|	CurrentAccountsReceivable.ChangeInPreviousAccountingPeriod AS ChangeInPreviousAccountingPeriod}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Current accounts receivable';RU='Текущая реализация услуг';de='Aktuelle Realisation von Diensten'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "SumOpeningBalance" 
	   Or pName = "CommissionSumOpeningBalance" 
	   Or pName = "QuantityOpeningBalance" 
	   Or pName = "CommissionSumClosingBalance" 
	   Or pName = "SumClosingBalance" 
	   Or pName = "QuantityClosingBalance" 
	   Or pName = "CommissionSumTurnover" 
	   Or pName = "SumTurnover" 
	   Or pName = "VATSumTurnover" 
	   Or pName = "QuantityTurnover" 
	   Or pName = "SumReceipt" 
	   Or pName = "SumExpense" 
	   Or pName = "VATSumReceipt" 
	   Or pName = "VATSumExpense" 
	   Or pName = "QuantityReceipt" 
	   Or pName = "QuantityExpense" 
	   Or pName = "CommissionSumReceipt" 
	   Or pName = "CommissionSumExpense" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
