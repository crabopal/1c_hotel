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
	If PeriodSelectionByDocumentTimestamp Then
		vParamPresentation = vParamPresentation + NStr("en='Selection by date and time of the operation';ru='Отбор по дате и времени операции';de='Auswahl nach Datum und Uhrzeit der Operation'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Selection by accounting date';ru='Отбор по учетной дате';de='Auswahl nach Rechnungsdatum'") + 
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
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа '; en = 'Guest group '; de = 'Gästegruppe '") + 
							 Format(GuestGroup.Code, "ND=12; NFD=0; NG=") + 
							 ";" + Chars.LF;
	EndIf;					 
	If ValueIsFilled(Folio) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Лицевой счет '; en = 'Folio '; de = 'Folio '") + 
							 TrimAll(Folio.Number) + 
							 ";" + Chars.LF;
	EndIf;					 
	If ValueIsFilled(CheckInDateFrom) And Not ValueIsFilled(CheckInDateTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Заезд c '; en = 'Check-in from '; de = 'Anreisedatum von '") + 
		                     Format(CheckInDateFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(CheckInDateFrom) And ValueIsFilled(CheckInDateTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Заезд по '; en = 'Check-in to '; de = 'Anreisedatum bis '") + 
		                     Format(CheckInDateTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf CheckInDateFrom = CheckInDateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Заезд '; en = 'Check-in '; de = 'Anreisedatum '") + 
		                     Format(CheckInDateFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf CheckInDateFrom < CheckInDateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Заезд '; en = 'Check-in '; de = 'Anreise '") + PeriodPresentation(CheckInDateFrom, CheckInDateTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(CheckInDateFrom) And ValueIsFilled(CheckInDateTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Check-in period is wrong!';ru='Неправильно задан период заезда!';de='Der Check-in-Zeitraum ist falsch eingestellt!'") + 
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
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	If PeriodSelectionByDocumentTimestamp Then
		ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
		ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	Else
		ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodFrom));
		ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	EndIf;
	ReportBuilder.Parameters.Insert("qByDocumentTimestamp", PeriodSelectionByDocumentTimestamp);
	ReportBuilder.Parameters.Insert("qPaymentMethod", PaymentMethod);
	ReportBuilder.Parameters.Insert("qPaymentMethodIsEmpty", Not ValueIsFilled(PaymentMethod));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qCompanyIsEmpty", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qEmployeeIsEmpty", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qPaymentSection", PaymentSection);
	ReportBuilder.Parameters.Insert("qPaymentSectionIsEmpty", Not ValueIsFilled(PaymentSection));
	ReportBuilder.Parameters.Insert("qCashRegister", CashRegister);
	ReportBuilder.Parameters.Insert("qCashRegisterIsEmpty", Not ValueIsFilled(CashRegister));
	ReportBuilder.Parameters.Insert("qSettlement", Catalogs.PaymentMethods.Settlement);
	ReportBuilder.Parameters.Insert("qPrintDebitors", PrintDebitors);
	ReportBuilder.Parameters.Insert("qEmptyCreditCardType", Catalogs.CreditCardTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", tcOnServer.GetForecastStartDate(Hotel));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", '39991231235959');
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qFolio", Folio);
	ReportBuilder.Parameters.Insert("qFolioIsEmpty", Not ValueIsFilled(Folio));
	ReportBuilder.Parameters.Insert("qCheckInDateFrom", CheckInDateFrom);
	ReportBuilder.Parameters.Insert("qCheckInDateFromIsEmpty", Not ValueIsFilled(CheckInDateFrom));
	ReportBuilder.Parameters.Insert("qCheckInDateTo", CheckInDateTo);
	ReportBuilder.Parameters.Insert("qCheckInDateToIsEmpty", Not ValueIsFilled(CheckInDateTo));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
		
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
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	PaymentGuestGroups.ParentDoc.GuestGroup AS GuestGroup
	|INTO ReportGuestGroups
	|FROM
	|	AccumulationRegister.Payments AS PaymentGuestGroups
	|WHERE
	|	(&qByDocumentTimestamp
	|				AND PaymentGuestGroups.Recorder.Date >= &qPeriodFrom
	|				AND PaymentGuestGroups.Recorder.Date <= &qPeriodTo
	|			OR NOT &qByDocumentTimestamp
	|				AND PaymentGuestGroups.Period >= &qPeriodFrom
	|				AND PaymentGuestGroups.Period <= &qPeriodTo)
	|	AND PaymentGuestGroups.Period <= &qPeriodTo
	|	AND (PaymentGuestGroups.PaymentMethod <> &qSettlement
	|			OR &qPrintDebitors)
	|	AND (PaymentGuestGroups.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (PaymentGuestGroups.PaymentSection = &qPaymentSection
	|			OR &qPaymentSectionIsEmpty)
	|	AND (PaymentGuestGroups.PaymentMethod = &qPaymentMethod
	|			OR &qPaymentMethodIsEmpty)
	|	AND (PaymentGuestGroups.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND (PaymentGuestGroups.CashRegister = &qCashRegister
	|			OR &qCashRegisterIsEmpty)
	|	AND (PaymentGuestGroups.Author = &qEmployee
	|			OR &qEmployeeIsEmpty)
	|
	|GROUP BY
	|	PaymentGuestGroups.ParentDoc.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroupSales.GuestGroup AS GuestGroup,
	|	GuestGroupSales.ReportingCurrency AS ReportingCurrency,
	|	SUM(GuestGroupSales.SalesTurnover) AS Sales,
	|	SUM(GuestGroupSales.SalesWithoutVATTurnover) AS SalesWithoutVAT
	|INTO GuestGroupSales
	|FROM
	|	(SELECT
	|		SalesTurnovers.GuestGroup AS GuestGroup,
	|		SalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		SalesTurnovers.SalesTurnover AS SalesTurnover,
	|		SalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				,
	|				,
	|				Period,
	|				GuestGroup IN
	|					(SELECT
	|						ReportGuestGroups.GuestGroup
	|					FROM
	|						ReportGuestGroups AS ReportGuestGroups)) AS SalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.GuestGroup,
	|		SalesForecastTurnovers.ReportingCurrency,
	|		SalesForecastTurnovers.SalesTurnover,
	|		SalesForecastTurnovers.SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				GuestGroup IN
	|					(SELECT
	|						ReportGuestGroups.GuestGroup
	|					FROM
	|						ReportGuestGroups AS ReportGuestGroups)) AS SalesForecastTurnovers) AS GuestGroupSales
	|
	|GROUP BY
	|	GuestGroupSales.GuestGroup,
	|	GuestGroupSales.ReportingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Payments.Period AS Period,
	|	Payments.Recorder AS Recorder,
	|	CASE
	|		WHEN Payments.Recorder REFS Document.DepositTransfer
	|				AND Payments.Sum = -Payments.Recorder.SumInFolioFromCurrency
	|			THEN Payments.Recorder.FolioFrom
	|		WHEN Payments.Recorder REFS Document.DepositTransfer
	|				AND Payments.Sum = Payments.Recorder.SumInFolioToCurrency
	|			THEN Payments.Recorder.FolioTo
	|		ELSE Payments.Recorder.Folio
	|	END AS Folio,
	|	Payments.PaymentCurrency AS PaymentCurrency,
	|	Payments.PaymentMethod AS PaymentMethod,
	|	Payments.Payer AS Payer,
	|	Payments.PaymentSection AS PaymentSection,
	|	Payments.CashRegister AS CashRegister,
	|	Payments.Remarks AS Remarks,
	|	Payments.Author AS Author,
	|	Payments.Sum AS Sum,
	|	Payments.VATSum AS VATSum,
	|	Payments.SumReceipt AS SumReceipt,
	|	Payments.VATSumReceipt AS VATSumReceipt,
	|	Payments.SumExpense AS SumExpense,
	|	Payments.VATSumExpense AS VATSumExpense,
	|	Payments.Hotel AS Hotel,
	|	ISNULL(GuestGroupSales.Sales, 0) AS GuestGroupSales,
	|	ISNULL(GuestGroupSales.SalesWithoutVAT, 0) AS GuestGroupSalesWithoutVAT,
	|	CASE
	|		WHEN NOT Payments.Recorder.CardType.CommissionPercent IS NULL
	|			THEN CAST(Payments.Sum * Payments.Recorder.CardType.CommissionPercent / 100 AS NUMBER(17, 2))
	|		WHEN NOT Payments.PaymentMethod.CardType.CommissionPercent IS NULL
	|			THEN CAST(Payments.Sum * Payments.PaymentMethod.CardType.CommissionPercent / 100 AS NUMBER(17, 2))
	|		ELSE 0
	|	END AS CardTypeCommissionSum,
	|	1 AS Counter
	|{SELECT
	|	Period,
	|	Recorder.*,
	|	PaymentCurrency.*,
	|	PaymentMethod.*,
	|	Payer.*,
	|	(CASE
	|			WHEN Payments.Payer.FullName IS NULL
	|				THEN Payments.Payer.LegacyName
	|			ELSE Payments.Payer.FullName
	|		END) AS PayerName,
	|	Payments.Recorder.AccountingCustomer.* AS AccountingCustomer,
	|	Payments.Recorder.AccountingContract.* AS AccountingContract,
	|	Payments.ParentDoc.GuestGroup.* AS GuestGroup,
	|	Folio.* AS Folio,
	|	Payments.Recorder.Invoice.* AS Invoice,
	|	CashRegister.*,
	|	PaymentSection.*,
	|	(CASE
	|			WHEN NOT Payments.Recorder.CardType IS NULL
	|					AND Payments.Recorder.CardType <> &qEmptyCreditCardType
	|				THEN Payments.Recorder.CardType
	|			ELSE Payments.PaymentMethod.CardType
	|		END).* AS CardType,
	|	(CASE
	|			WHEN NOT Payments.Recorder.CardType.CommissionPercent IS NULL
	|				THEN Payments.Recorder.CardType.CommissionPercent
	|			WHEN NOT Payments.PaymentMethod.CardType.CommissionPercent IS NULL
	|				THEN Payments.PaymentMethod.CardType.CommissionPercent
	|			ELSE 0
	|		END) AS CardTypeCommissionPercent,
	|	(CASE
	|			WHEN Payments.ParentDoc REFS Document.ResourceReservation
	|				THEN BEGINOFPERIOD(Payments.ParentDoc.DateTimeFrom, DAY)
	|			WHEN Payments.ParentDoc REFS Document.Folio
	|				THEN BEGINOFPERIOD(Payments.ParentDoc.DateTimeFrom, DAY)
	|			WHEN Payments.ParentDoc REFS Document.Reservation
	|				THEN BEGINOFPERIOD(Payments.ParentDoc.CheckInDate, DAY)
	|			WHEN Payments.ParentDoc REFS Document.Accommodation
	|				THEN BEGINOFPERIOD(Payments.ParentDoc.CheckInDate, DAY)
	|			ELSE &qEmptyDate
	|		END) AS CheckInDate,
	|	(CASE
	|			WHEN Payments.ParentDoc REFS Document.ResourceReservation
	|				THEN BEGINOFPERIOD(Payments.ParentDoc.DateTimeTo, DAY)
	|			WHEN Payments.ParentDoc REFS Document.Folio
	|				THEN BEGINOFPERIOD(Payments.ParentDoc.DateTimeTo, DAY)
	|			WHEN Payments.ParentDoc REFS Document.Reservation
	|				THEN BEGINOFPERIOD(Payments.ParentDoc.CheckOutDate, DAY)
	|			WHEN Payments.ParentDoc REFS Document.Accommodation
	|				THEN BEGINOFPERIOD(Payments.ParentDoc.CheckOutDate, DAY)
	|			ELSE &qEmptyDate
	|		END) AS CheckOutDate,
	|	Remarks,
	|	Author.*,
	|	Payments.Company.*,
	|	Hotel.*,
	|	Payments.ParentDoc.*,
	|	Payments.ParentDoc.HotelProduct.* AS HotelProduct,
	|	(CASE
	|			WHEN ISNULL(Payments.ParentDoc.HotelProduct.IsFolder, FALSE)
	|				THEN Payments.ParentDoc.HotelProduct
	|			ELSE Payments.ParentDoc.HotelProduct.Parent
	|		END).* AS HotelProductType,
	|	Payments.VATRate.*,
	|	(CASE
	|			WHEN Payments.Recorder REFS Document.Settlement
	|				THEN Payments.Recorder.Number
	|			WHEN Payments.Recorder REFS Document.CustomerPayment
	|				THEN Payments.Recorder.ParentDoc.Number
	|			ELSE Payments.Recorder.Folio.Number
	|		END) AS SettledInvoiceNumber,
	|	Sum,
	|	VATSum,
	|	SumReceipt,
	|	VATSumReceipt,
	|	SumExpense,
	|	VATSumExpense,
	|	GuestGroupSales,
	|	GuestGroupSalesWithoutVAT,
	|	CardTypeCommissionSum,
	|	Payments.AccountingDate,
	|	(WEEK(Payments.AccountingDate)) AS AccountingWeek,
	|	(MONTH(Payments.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(Payments.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(Payments.AccountingDate)) AS AccountingYear,
	|	CloseCashRegisterDays.Author.* AS CloseCashRegisterDayAuthor,
	|	CloseCashRegisterDays.Date AS CloseCashRegisterDate,
	|	(BEGINOFPERIOD(CloseCashRegisterDays.Date, DAY)) AS CloseCashRegisterDay,
	|	Counter}
	|FROM
	|	AccumulationRegister.Payments AS Payments
	|		LEFT JOIN Document.CloseOfCashRegisterDay AS CloseCashRegisterDays
	|		ON Payments.CashRegister = CloseCashRegisterDays.CashRegister
	|			AND Payments.Period >= CloseCashRegisterDays.DateFrom
	|			AND Payments.Period < CloseCashRegisterDays.Date
	|			AND (CloseCashRegisterDays.Posted)
	|		LEFT JOIN GuestGroupSales AS GuestGroupSales
	|		ON Payments.ParentDoc.GuestGroup = GuestGroupSales.GuestGroup
	|			AND Payments.PaymentCurrency = GuestGroupSales.ReportingCurrency
	|WHERE
	|	(&qByDocumentTimestamp
	|				AND Payments.Recorder.Date >= &qPeriodFrom
	|				AND Payments.Recorder.Date <= &qPeriodTo
	|			OR NOT &qByDocumentTimestamp
	|				AND Payments.Period >= &qPeriodFrom
	|				AND Payments.Period <= &qPeriodTo)
	|	AND (Payments.PaymentMethod <> &qSettlement
	|			OR &qPrintDebitors)
	|	AND (Payments.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (Payments.PaymentSection = &qPaymentSection
	|			OR &qPaymentSectionIsEmpty)
	|	AND (Payments.PaymentMethod = &qPaymentMethod
	|			OR &qPaymentMethodIsEmpty)
	|	AND (Payments.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND (Payments.CashRegister = &qCashRegister
	|			OR &qCashRegisterIsEmpty)
	|	AND (Payments.Author = &qEmployee
	|			OR &qEmployeeIsEmpty)
	|	AND CASE
	|			WHEN Payments.Recorder REFS Document.DepositTransfer
	|					AND Payments.Recorder.FolioFrom = &qFolio
	|					AND Payments.Sum = -Payments.Recorder.SumInFolioFromCurrency
	|					AND NOT &qFolioIsEmpty
	|				THEN TRUE
	|			WHEN Payments.Recorder REFS Document.DepositTransfer
	|					AND Payments.Recorder.FolioTo = &qFolio
	|					AND Payments.Sum = Payments.Recorder.SumInFolioToCurrency
	|					AND NOT &qFolioIsEmpty
	|				THEN TRUE
	|			WHEN Payments.Recorder.Folio = &qFolio
	|					AND NOT &qFolioIsEmpty
	|				THEN TRUE
	|			WHEN NOT &qFolioIsEmpty
	|				THEN FALSE
	|			ELSE TRUE
	|		END
	|	AND (Payments.ParentDoc.GuestGroup = &qGuestGroup
	|			OR &qGuestGroupIsEmpty)
	|	AND (CASE
	|				WHEN Payments.ParentDoc REFS Document.ResourceReservation
	|					THEN BEGINOFPERIOD(Payments.ParentDoc.DateTimeFrom, DAY)
	|				WHEN Payments.ParentDoc REFS Document.Folio
	|					THEN BEGINOFPERIOD(Payments.ParentDoc.DateTimeFrom, DAY)
	|				WHEN Payments.ParentDoc REFS Document.Reservation
	|					THEN BEGINOFPERIOD(Payments.ParentDoc.CheckInDate, DAY)
	|				WHEN Payments.ParentDoc REFS Document.Accommodation
	|					THEN BEGINOFPERIOD(Payments.ParentDoc.CheckInDate, DAY)
	|				ELSE &qEmptyDate
	|			END >= &qCheckInDateFrom
	|			OR &qCheckInDateFromIsEmpty)
	|	AND (CASE
	|				WHEN Payments.ParentDoc REFS Document.ResourceReservation
	|					THEN BEGINOFPERIOD(Payments.ParentDoc.DateTimeFrom, DAY)
	|				WHEN Payments.ParentDoc REFS Document.Folio
	|					THEN BEGINOFPERIOD(Payments.ParentDoc.DateTimeFrom, DAY)
	|				WHEN Payments.ParentDoc REFS Document.Reservation
	|					THEN BEGINOFPERIOD(Payments.ParentDoc.CheckInDate, DAY)
	|				WHEN Payments.ParentDoc REFS Document.Accommodation
	|					THEN BEGINOFPERIOD(Payments.ParentDoc.CheckInDate, DAY)
	|				ELSE &qEmptyDate
	|			END <= &qCheckInDateTo
	|			OR &qCheckInDateToIsEmpty)
	|{WHERE
	|	Payments.Hotel.*,
	|	Payments.Company.*,
	|	Payments.PaymentCurrency.*,
	|	Payments.PaymentSection.*,
	|	Payments.PaymentMethod.*,
	|	Payments.Recorder.*,
	|	Payments.Recorder.AccountingCustomer.* AS AccountingCustomer,
	|	Payments.Recorder.AccountingContract.* AS AccountingContract,
	|	Payments.ParentDoc.GuestGroup.* AS GuestGroup,
	|	Payments.Recorder.Invoice.* AS Invoice,
	|	Payments.CashRegister.*,
	|	Payments.Payer.*,
	|	(CASE
	|			WHEN Payments.Payer.FullName IS NULL
	|				THEN Payments.Payer.LegacyName
	|			ELSE Payments.Payer.FullName
	|		END) AS PayerName,
	|	Payments.Author.*,
	|	Payments.ParentDoc.*,
	|	Payments.ParentDoc.HotelProduct.* AS HotelProduct,
	|	(CASE
	|			WHEN ISNULL(Payments.ParentDoc.HotelProduct.IsFolder, FALSE)
	|				THEN Payments.ParentDoc.HotelProduct
	|			ELSE Payments.ParentDoc.HotelProduct.Parent
	|		END).* AS HotelProductType,
	|	Payments.AccountingDate,
	|	(WEEK(Payments.Period)) AS AccountingWeek,
	|	(MONTH(Payments.Period)) AS AccountingMonth,
	|	(QUARTER(Payments.Period)) AS AccountingQuarter,
	|	(YEAR(Payments.Period)) AS AccountingYear,
	|	Payments.Period,
	|	Payments.Sum,
	|	Payments.VATSum,
	|	Payments.SumExpense,
	|	Payments.VATSumExpense,
	|	Payments.SumReceipt,
	|	Payments.VATSumReceipt,
	|	(ISNULL(GuestGroupSales.Sales, 0)) AS GuestGroupSales,
	|	(ISNULL(GuestGroupSales.SalesWithoutVAT, 0)) AS GuestGroupSalesWithoutVAT,
	|	Payments.VATRate.*,
	|	Payments.Remarks,
	|	CloseCashRegisterDays.Author.* AS CloseCashRegisterDayAuthor,
	|	CloseCashRegisterDays.Date AS CloseCashRegisterDate,
	|	(CASE
	|			WHEN NOT Payments.Recorder.CardType.CommissionPercent IS NULL
	|				THEN CAST(Payments.Sum * Payments.Recorder.CardType.CommissionPercent / 100 AS NUMBER(17, 2))
	|			WHEN NOT Payments.PaymentMethod.CardType.CommissionPercent IS NULL
	|				THEN CAST(Payments.Sum * Payments.PaymentMethod.CardType.CommissionPercent / 100 AS NUMBER(17, 2))
	|			ELSE 0
	|		END) AS CardTypeCommissionSum,
	|	(CASE
	|			WHEN NOT Payments.Recorder.CardType IS NULL
	|					AND Payments.Recorder.CardType <> &qEmptyCreditCardType
	|				THEN Payments.Recorder.CardType
	|			ELSE Payments.PaymentMethod.CardType
	|		END).* AS CardType,
	|	(CASE
	|			WHEN NOT Payments.Recorder.CardType.CommissionPercent IS NULL
	|				THEN Payments.Recorder.CardType.CommissionPercent
	|			WHEN NOT Payments.PaymentMethod.CardType.CommissionPercent IS NULL
	|				THEN Payments.PaymentMethod.CardType.CommissionPercent
	|			ELSE 0
	|		END) AS CardTypeCommissionPercent,
	|	(BEGINOFPERIOD(CloseCashRegisterDays.Date, DAY)) AS CloseCashRegisterDay}
	|
	|ORDER BY
	|	Period
	|{ORDER BY
	|	Period,
	|	Hotel.*,
	|	Payments.Company.*,
	|	PaymentCurrency.*,
	|	PaymentSection.*,
	|	PaymentMethod.*,
	|	CashRegister.*,
	|	Payer.*,
	|	(CASE
	|			WHEN Payments.Payer.FullName IS NULL
	|				THEN Payments.Payer.LegacyName
	|			ELSE Payments.Payer.FullName
	|		END) AS PayerName,
	|	Author.*,
	|	Payments.ParentDoc.*,
	|	Payments.ParentDoc.HotelProduct.* AS HotelProduct,
	|	(CASE
	|			WHEN ISNULL(Payments.ParentDoc.HotelProduct.IsFolder, FALSE)
	|				THEN Payments.ParentDoc.HotelProduct
	|			ELSE Payments.ParentDoc.HotelProduct.Parent
	|		END).* AS HotelProductType,
	|	Recorder.*,
	|	Payments.Recorder.AccountingCustomer.* AS AccountingCustomer,
	|	Payments.Recorder.AccountingContract.* AS AccountingContract,
	|	Payments.ParentDoc.GuestGroup.* AS GuestGroup,
	|	Payments.Recorder.Invoice.* AS Invoice,
	|	Payments.VATRate.*,
	|	Sum,
	|	VATSum,
	|	SumExpense,
	|	VATSumExpense,
	|	SumReceipt,
	|	GuestGroupSales,
	|	GuestGroupSalesWithoutVAT,
	|	VATSumReceipt,
	|	CloseCashRegisterDays.Author.* AS CloseCashRegisterDayAuthor,
	|	CloseCashRegisterDays.Date AS CloseCashRegisterDate,
	|	(CASE
	|			WHEN NOT Payments.Recorder.CardType IS NULL
	|					AND Payments.Recorder.CardType <> &qEmptyCreditCardType
	|				THEN Payments.Recorder.CardType
	|			ELSE Payments.PaymentMethod.CardType
	|		END).* AS CardType,
	|	(CASE
	|			WHEN NOT Payments.Recorder.CardType.CommissionPercent IS NULL
	|				THEN Payments.Recorder.CardType.CommissionPercent
	|			WHEN NOT Payments.PaymentMethod.CardType.CommissionPercent IS NULL
	|				THEN Payments.PaymentMethod.CardType.CommissionPercent
	|			ELSE 0
	|		END) AS CardTypeCommissionPercent,
	|	CardTypeCommissionSum,
	|	(BEGINOFPERIOD(CloseCashRegisterDays.Date, DAY)) AS CloseCashRegisterDay}
	|TOTALS
	|	SUM(Sum),
	|	SUM(VATSum),
	|	SUM(SumReceipt),
	|	SUM(VATSumReceipt),
	|	SUM(SumExpense),
	|	SUM(VATSumExpense),
	|	SUM(GuestGroupSales),
	|	SUM(GuestGroupSalesWithoutVAT),
	|	SUM(CardTypeCommissionSum),
	|	SUM(Counter)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Hotel.*,
	|	Payments.Company.*,
	|	PaymentCurrency.*,
	|	PaymentSection.*,
	|	PaymentMethod.*,
	|	CashRegister.*,
	|	Payer.*,
	|	(CASE
	|			WHEN Payments.Payer.FullName IS NULL
	|				THEN Payments.Payer.LegacyName
	|			ELSE Payments.Payer.FullName
	|		END) AS PayerName,
	|	Author.*,
	|	Payments.ParentDoc.*,
	|	Payments.ParentDoc.HotelProduct.* AS HotelProduct,
	|	(CASE
	|			WHEN ISNULL(Payments.ParentDoc.HotelProduct.IsFolder, FALSE)
	|				THEN Payments.ParentDoc.HotelProduct
	|			ELSE Payments.ParentDoc.HotelProduct.Parent
	|		END).* AS HotelProductType,
	|	Recorder.*,
	|	Payments.Recorder.AccountingCustomer.* AS AccountingCustomer,
	|	Payments.Recorder.AccountingContract.* AS AccountingContract,
	|	Payments.ParentDoc.GuestGroup.* AS GuestGroup,
	|	Payments.Recorder.Invoice.* AS Invoice,
	|	Folio.*,
	|	Payments.VATRate.*,
	|	Payments.AccountingDate,
	|	(WEEK(Payments.AccountingDate)) AS AccountingWeek,
	|	(MONTH(Payments.AccountingDate)) AS AccountingMonth,
	|	(QUARTER(Payments.AccountingDate)) AS AccountingQuarter,
	|	(YEAR(Payments.AccountingDate)) AS AccountingYear,
	|	CloseCashRegisterDays.Author.* AS CloseCashRegisterDayAuthor,
	|	CloseCashRegisterDays.Date AS CloseCashRegisterDate,
	|	(CASE
	|			WHEN NOT Payments.Recorder.CardType IS NULL
	|					AND Payments.Recorder.CardType <> &qEmptyCreditCardType
	|				THEN Payments.Recorder.CardType
	|			ELSE Payments.PaymentMethod.CardType
	|		END).* AS CardType,
	|	(CASE
	|			WHEN NOT Payments.Recorder.CardType.CommissionPercent IS NULL
	|				THEN Payments.Recorder.CardType.CommissionPercent
	|			WHEN NOT Payments.PaymentMethod.CardType.CommissionPercent IS NULL
	|				THEN Payments.PaymentMethod.CardType.CommissionPercent
	|			ELSE 0
	|		END) AS CardTypeCommissionPercent,
	|	(BEGINOFPERIOD(CloseCashRegisterDays.Date, DAY)) AS CloseCashRegisterDay}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Payments';RU='Платежи';de='Zahlungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
