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
		ShowUsed = True;
		ShowIssuedButNotUsed = True;
		ShowMarkedDeleted = True;
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
	If ShowUsed Then
			vParamPresentation = vParamPresentation + NStr("en='Show used products';ru='Показывать использованные путевки';de='Nur verwendete Reisen anzeigen'") + 
			                     ";" + Chars.LF;
	EndIf;
	If ShowIssuedButNotUsed Then
			vParamPresentation = vParamPresentation + NStr("en='Show issued but not used products';ru='Показывать отгруженные но не использованные путевки';de='Versandte, aber nicht genutzte Reisen anzeigen'") + 
			                     ";" + Chars.LF;
	EndIf;
	If ShowMarkedDeleted Then
			vParamPresentation = vParamPresentation + NStr("en='Show marked as deleted products';ru='Показывать испорченные путевки';de='ungültige Reiseunterlagen anzeigen'") + 
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
			                     TrimAll(Hotel.Description) + ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qPeriodToIsEmpty", Not ValueIsFilled(PeriodTo));
	ReportBuilder.Parameters.Insert("qHotelProductType", HotelProduct);
	ReportBuilder.Parameters.Insert("qHotelProductTypeIsEmpty", Not ValueIsFilled(HotelProduct));
	ReportBuilder.Parameters.Insert("qShowUsed", ShowUsed);
	ReportBuilder.Parameters.Insert("qShowIssuedButNotUsed", ShowIssuedButNotUsed);
	ReportBuilder.Parameters.Insert("qShowMarkedDeleted", ShowMarkedDeleted);
	ReportBuilder.Parameters.Insert("qEmptyString", "");
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qEmptyPaymentMethod", Catalogs.PaymentMethods.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyPaymentSection", Catalogs.PaymentSections.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	
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
	|	HotelProducts.HotelProductType,
	|	HotelProducts.Code,
	|	HotelProducts.Description,
	|	HotelProducts.Hotel,
	|	HotelProducts.RoomQuota,
	|	HotelProducts.RoomType,
	|	HotelProducts.Client,
	|	HotelProducts.CheckInDate,
	|	HotelProducts.Duration,
	|	HotelProducts.CheckOutDate,
	|	HotelProducts.FixProductPeriod,
	|	HotelProducts.FixPlannedPeriod,
	|	HotelProducts.FixProductCost,
	|	HotelProducts.Sum AS Sum,
	|	HotelProducts.SumWithoutCommission AS SumWithoutCommission,
	|	HotelProducts.Price AS Price,
	|	HotelProducts.PaymentSum AS PaymentSum,
	|	HotelProducts.CashSum AS CashSum,
	|	HotelProducts.CreditCardSum AS CreditCardSum,
	|	HotelProducts.BankTransferSum AS BankTransferSum,
	|	HotelProducts.Currency,
	|	HotelProducts.PaymentDate,
	|	HotelProducts.PaymentMethod,
	|	HotelProducts.Remarks,
	|	HotelProducts.ExternalCode,
	|	HotelProducts.SocialGroup,
	|	HotelProducts.CreateDateTime AS CreateDateTime,
	|	HotelProducts.Author,
	|	HotelProducts.DeletionMark,
	|	HotelProducts.DeletionMarkDateTime,
	|	HotelProducts.DeletionMarkAuthor,
	|	HotelProducts.Counter AS Counter
	|{SELECT
	|	HotelProductType.*,
	|	Code,
	|	Description,
	|	Hotel.*,
	|	RoomQuota.*,
	|	RoomType.*,
	|	Client.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	FixProductPeriod,
	|	FixPlannedPeriod,
	|	FixProductCost,
	|	Sum,
	|	SumWithoutCommission,
	|	Price,
	|	PaymentSum,
	|	CashSum,
	|	CreditCardSum,
	|	BankTransferSum,
	|	Currency.*,
	|	PaymentDate,
	|	PaymentMethod.*,
	|	HotelProducts.PaymentSection.*,
	|	Remarks,
	|	ExternalCode,
	|	SocialGroup.*,
	|	CreateDateTime,
	|	(BEGINOFPERIOD(HotelProducts.CreateDateTime, DAY)) AS CreateDate,
	|	Author.*,
	|	DeletionMark,
	|	DeletionMarkDateTime,
	|	(BEGINOFPERIOD(HotelProducts.DeletionMarkDateTime, DAY)) AS DeletionMarkDate,
	|	DeletionMarkAuthor.*,
	|	Counter}
	|FROM
	|	(SELECT
	|		UsedHotelProducts.Parent AS HotelProductType,
	|		UsedHotelProducts.Code AS Code,
	|		UsedHotelProducts.Description AS Description,
	|		UsedHotelProducts.Hotel AS Hotel,
	|		UsedHotelProducts.RoomQuota AS RoomQuota,
	|		UsedHotelProducts.RoomType AS RoomType,
	|		UsedHotelProducts.Client AS Client,
	|		UsedHotelProducts.CheckInDate AS CheckInDate,
	|		UsedHotelProducts.Duration AS Duration,
	|		UsedHotelProducts.CheckOutDate AS CheckOutDate,
	|		UsedHotelProducts.FixProductPeriod AS FixProductPeriod,
	|		UsedHotelProducts.FixPlannedPeriod AS FixPlannedPeriod,
	|		UsedHotelProducts.FixProductCost AS FixProductCost,
	|		HotelProductTotalSales.Sum AS Sum,
	|		HotelProductTotalSales.Sum - HotelProductTotalSales.CommissionSum AS SumWithoutCommission,
	|		UsedHotelProducts.Sum AS Price,
	|		UsedHotelProducts.Currency AS Currency,
	|		UsedHotelProducts.PaymentDate AS PaymentDate,
	|		UsedHotelProducts.PaymentMethod AS PaymentMethod,
	|		HotelProductPaymentTotals.PaymentSection AS PaymentSection,
	|		UsedHotelProducts.Remarks AS Remarks,
	|		UsedHotelProducts.ExternalCode AS ExternalCode,
	|		UsedHotelProducts.SocialGroup AS SocialGroup,
	|		UsedHotelProducts.CreateDate AS CreateDateTime,
	|		UsedHotelProducts.Author AS Author,
	|		UsedHotelProducts.DeletionMark AS DeletionMark,
	|		UsedHotelProducts.DeletionMarkDate AS DeletionMarkDateTime,
	|		UsedHotelProducts.DeletionMarkAuthor AS DeletionMarkAuthor,
	|		1 AS Counter,
	|		HotelProductPaymentTotals.PaymentSum AS PaymentSum,
	|		HotelProductPaymentTotals.CashSum AS CashSum,
	|		HotelProductPaymentTotals.CreditCardSum AS CreditCardSum,
	|		HotelProductPaymentTotals.BankTransferSum AS BankTransferSum
	|	FROM
	|		Catalog.HotelProducts AS UsedHotelProducts
	|			LEFT JOIN (SELECT
	|				HotelProductSalesTurnovers.HotelProduct AS HotelProduct,
	|				HotelProductSalesTurnovers.SalesTurnover AS Sum,
	|				HotelProductSalesTurnovers.CommissionSumTurnover AS CommissionSum
	|			FROM
	|				AccumulationRegister.HotelProductSales.Turnovers(
	|						,
	|						,
	|						Period,
	|						(HotelProduct IN HIERARCHY (&qHotelProductType)
	|							OR &qHotelProductTypeIsEmpty)
	|							AND (Hotel IN HIERARCHY (&qHotel)
	|								OR &qHotelIsEmpty)) AS HotelProductSalesTurnovers) AS HotelProductTotalSales
	|			ON (HotelProductTotalSales.HotelProduct = UsedHotelProducts.Ref)
	|			LEFT JOIN (SELECT
	|				HotelProductPayments.PaymentSection AS PaymentSection,
	|				HotelProductPayments.AccountingCurrency AS AccountingCurrency,
	|				CASE
	|					WHEN NOT HotelProductPayments.Folio.HotelProduct IS NULL 
	|							AND HotelProductPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|						THEN HotelProductPayments.Folio.HotelProduct
	|					WHEN NOT HotelProductPayments.Folio.ParentDoc.HotelProduct IS NULL 
	|							AND HotelProductPayments.Folio.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|						THEN HotelProductPayments.Folio.ParentDoc.HotelProduct
	|					ELSE HotelProductPayments.ParentDoc.HotelProduct
	|				END AS HotelProduct,
	|				SUM(HotelProductPayments.Sum) AS PaymentSum,
	|				SUM(CASE
	|						WHEN ISNULL(HotelProductPayments.Recorder.PaymentMethod.IsByCash, FALSE)
	|							THEN HotelProductPayments.Sum
	|						ELSE 0
	|					END) AS CashSum,
	|				SUM(CASE
	|						WHEN ISNULL(HotelProductPayments.Recorder.PaymentMethod.IsByCreditCard, FALSE)
	|							THEN HotelProductPayments.Sum
	|						ELSE 0
	|					END) AS CreditCardSum,
	|				SUM(CASE
	|						WHEN ISNULL(HotelProductPayments.Recorder.PaymentMethod.IsByBankTransfer, FALSE)
	|							THEN HotelProductPayments.Sum
	|						ELSE 0
	|					END) AS BankTransferSum
	|			FROM
	|				AccumulationRegister.CustomerAccounts AS HotelProductPayments
	|			WHERE
	|				HotelProductPayments.RecordType = VALUE(AccumulationrecordType.Expense)
	|				AND (HotelProductPayments.Hotel IN HIERARCHY (&qHotel)
	|						OR &qHotelIsEmpty)
	|			
	|			GROUP BY
	|				HotelProductPayments.PaymentSection,
	|				HotelProductPayments.AccountingCurrency,
	|				CASE
	|					WHEN NOT HotelProductPayments.Folio.HotelProduct IS NULL 
	|							AND HotelProductPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|						THEN HotelProductPayments.Folio.HotelProduct
	|					WHEN NOT HotelProductPayments.Folio.ParentDoc.HotelProduct IS NULL 
	|							AND HotelProductPayments.Folio.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|						THEN HotelProductPayments.Folio.ParentDoc.HotelProduct
	|					ELSE HotelProductPayments.ParentDoc.HotelProduct
	|				END) AS HotelProductPaymentTotals
	|			ON (HotelProductPaymentTotals.HotelProduct = UsedHotelProducts.Ref)
	|				AND (HotelProductPaymentTotals.PaymentSection = UsedHotelProducts.Parent.PaymentSection
	|					OR UsedHotelProducts.Parent.PaymentSection = &qEmptyPaymentSection)
	|				AND (HotelProductPaymentTotals.AccountingCurrency = UsedHotelProducts.Currency)
	|	WHERE
	|		NOT UsedHotelProducts.IsFolder
	|		AND UsedHotelProducts.CreateDate >= &qPeriodFrom
	|		AND (UsedHotelProducts.CreateDate <= &qPeriodTo
	|				OR &qPeriodToIsEmpty)
	|		AND (UsedHotelProducts.Ref IN HIERARCHY (&qHotelProductType)
	|				OR &qHotelProductTypeIsEmpty)
	|		AND (UsedHotelProducts.Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|		AND (&qShowUsed
	|					AND NOT UsedHotelProducts.DeletionMark
	|				OR &qShowMarkedDeleted
	|					AND UsedHotelProducts.DeletionMark)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		IssuedHotelProducts.HotelProductParent,
	|		IssuedHotelProducts.ProductCode,
	|		&qEmptyString,
	|		IssuedHotelProducts.Hotel,
	|		IssuedHotelProducts.RoomQuota,
	|		IssuedHotelProducts.RoomType,
	|		IssuedHotelProducts.ParentDoc.Guest,
	|		IssuedHotelProducts.CheckInDate,
	|		IssuedHotelProducts.Duration,
	|		IssuedHotelProducts.CheckOutDate,
	|		IssuedHotelProducts.FixProductPeriod,
	|		IssuedHotelProducts.FixPlannedPeriod,
	|		IssuedHotelProducts.FixProductCost,
	|		0,
	|		0,
	|		IssuedHotelProducts.Price,
	|		IssuedHotelProducts.Currency,
	|		&qEmptyDate,
	|		&qEmptyPaymentMethod,
	|		&qEmptyPaymentSection,
	|		IssuedHotelProducts.BillOfShipment,
	|		&qEmptyString,
	|		IssuedHotelProducts.SocialGroup,
	|		IssuedHotelProducts.Recorder.Date,
	|		IssuedHotelProducts.Recorder.Author,
	|		FALSE,
	|		&qEmptyDate,
	|		NULL,
	|		1,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		InformationRegister.IssuedHotelProducts AS IssuedHotelProducts
	|	WHERE
	|		&qShowIssuedButNotUsed
	|		AND IssuedHotelProducts.Recorder.Date >= &qPeriodFrom
	|		AND (IssuedHotelProducts.Recorder.Date <= &qPeriodTo
	|				OR &qPeriodToIsEmpty)
	|		AND (IssuedHotelProducts.HotelProductParent IN HIERARCHY (&qHotelProductType)
	|				OR &qHotelProductTypeIsEmpty)
	|		AND (IssuedHotelProducts.Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|		AND NOT IssuedHotelProducts.ProductCode IN
	|					(SELECT
	|						AllHotelProducts.Code
	|					FROM
	|						Catalog.HotelProducts AS AllHotelProducts
	|					WHERE
	|						(AllHotelProducts.Hotel = &qHotel
	|							OR &qHotelIsEmpty)
	|						AND NOT AllHotelProducts.IsFolder)) AS HotelProducts
	|{WHERE
	|	HotelProducts.HotelProductType.*,
	|	HotelProducts.Code,
	|	HotelProducts.Description,
	|	HotelProducts.Hotel.*,
	|	HotelProducts.RoomQuota.*,
	|	HotelProducts.RoomType.*,
	|	HotelProducts.Client.*,
	|	HotelProducts.CheckInDate,
	|	HotelProducts.Duration,
	|	HotelProducts.CheckOutDate,
	|	HotelProducts.FixProductPeriod,
	|	HotelProducts.FixPlannedPeriod,
	|	HotelProducts.FixProductCost,
	|	HotelProducts.Sum,
	|	HotelProducts.SumWithoutCommission,
	|	HotelProducts.Price,
	|	HotelProducts.PaymentSum,
	|	HotelProducts.CashSum,
	|	HotelProducts.CreditCardSum,
	|	HotelProducts.BankTransferSum,
	|	HotelProducts.Currency.*,
	|	HotelProducts.PaymentDate,
	|	HotelProducts.PaymentMethod.*,
	|	HotelProducts.PaymentSection.*,
	|	HotelProducts.Remarks,
	|	HotelProducts.ExternalCode,
	|	HotelProducts.SocialGroup.*,
	|	HotelProducts.CreateDateTime,
	|	HotelProducts.Author.*,
	|	HotelProducts.DeletionMarkDateTime,
	|	HotelProducts.DeletionMarkAuthor.*}
	|
	|ORDER BY
	|	CreateDateTime
	|{ORDER BY
	|	HotelProductType.*,
	|	Code,
	|	Description,
	|	Hotel.*,
	|	RoomQuota.*,
	|	RoomType.*,
	|	Client.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	FixProductPeriod,
	|	FixPlannedPeriod,
	|	FixProductCost,
	|	Sum,
	|	SumWithoutCommission,
	|	Price,
	|	PaymentSum,
	|	CashSum,
	|	CreditCardSum,
	|	BankTransferSum,
	|	Currency.*,
	|	PaymentDate,
	|	PaymentMethod.*,
	|	HotelProducts.PaymentSection.*,
	|	Remarks,
	|	ExternalCode,
	|	SocialGroup.*,
	|	CreateDateTime,
	|	Author.*,
	|	DeletionMark,
	|	DeletionMarkDateTime,
	|	DeletionMarkAuthor.*}
	|TOTALS
	|	SUM(Sum),
	|	SUM(SumWithoutCommission),
	|	SUM(Price),
	|	SUM(PaymentSum),
	|	SUM(CashSum),
	|	SUM(CreditCardSum),
	|	SUM(BankTransferSum),
	|	SUM(Counter)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	HotelProductType.*,
	|	Code,
	|	Description,
	|	Hotel.*,
	|	RoomQuota.*,
	|	RoomType.*,
	|	Client.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	FixProductPeriod,
	|	FixPlannedPeriod,
	|	FixProductCost,
	|	Currency.*,
	|	PaymentDate,
	|	PaymentMethod.*,
	|	HotelProducts.PaymentSection.*,
	|	Remarks,
	|	ExternalCode,
	|	SocialGroup.*,
	|	CreateDateTime,
	|	(BEGINOFPERIOD(HotelProducts.CreateDateTime, DAY)) AS CreateDate,
	|	Author.*,
	|	DeletionMark,
	|	DeletionMarkDateTime,
	|	(BEGINOFPERIOD(HotelProducts.DeletionMarkDateTime, DAY)) AS DeletionMarkDate,
	|	DeletionMarkAuthor.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Hotel products register';RU='Реестр использованных бланков путевок';de='Verzeichnis der verwendeten Reisescheckformulare'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
