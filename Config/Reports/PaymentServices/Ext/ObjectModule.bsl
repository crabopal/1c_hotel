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
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelgruppe '") + 
			                     TrimAll(Hotel.Description) + 
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
	ReportBuilder.Parameters.Insert("qPaymentMethod", PaymentMethod);
	ReportBuilder.Parameters.Insert("qPaymentMethodIsEmpty", Not ValueIsFilled(PaymentMethod));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qCompanyIsEmpty", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qPaymentSection", PaymentSection);
	ReportBuilder.Parameters.Insert("qPaymentSectionIsEmpty", Not ValueIsFilled(PaymentSection));
	ReportBuilder.Parameters.Insert("qCashRegister", CashRegister);
	ReportBuilder.Parameters.Insert("qCashRegisterIsEmpty", Not ValueIsFilled(CashRegister));
	
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
	vHotel = Undefined;
	If ValueIsFilled(Hotel) Then
		vHotel = Hotel;
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	// Check hotel settings
	If ValueIsFilled(vHotel) And Not vHotel.IsFolder Then
		vUseChequeServices = vHotel.SplitFolioBalanceByServicesAndPrices;
	Else
		vUseChequeServices = True;
	EndIf;
	// Set report query
	If vUseChequeServices Then
		QueryText = 
		"SELECT
		|	PaymentServicesBalanceAndTurnovers.Service AS Service,
		|	SUM(PaymentServicesBalanceAndTurnovers.SumExpense) AS SumExpense,
		|	SUM(PaymentServicesBalanceAndTurnovers.Quantity) AS Quantity
		|{SELECT
		|	PaymentServicesBalanceAndTurnovers.Folio.* AS Folio,
		|	PaymentServicesBalanceAndTurnovers.Folio.Hotel.* AS FolioHotel,
		|	PaymentServicesBalanceAndTurnovers.Folio.Company.* AS FolioCompany,
		|	PaymentServicesBalanceAndTurnovers.Folio.FolioCurrency.* AS FolioCurrency,
		|	PaymentServicesBalanceAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
		|	PaymentServicesBalanceAndTurnovers.Folio.Agent.* AS FolioAgent,
		|	PaymentServicesBalanceAndTurnovers.Folio.Customer.* AS FolioCustomer,
		|	PaymentServicesBalanceAndTurnovers.Folio.Contract.* AS FolioContract,
		|	PaymentServicesBalanceAndTurnovers.Folio.Client.* AS FolioClient,
		|	PaymentServicesBalanceAndTurnovers.Folio.GuestGroup.* AS FolioGuestGroup,
		|	PaymentServicesBalanceAndTurnovers.Folio.Room.* AS FolioRoom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeFrom AS FolioDateTimeFrom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeTo AS FolioDateTimeTo,
		|	Service.* AS Service,
		|	PaymentServicesBalanceAndTurnovers.Service.ServiceType.* AS ServiceType,
		|	PaymentServicesBalanceAndTurnovers.Payment.* AS Payment,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentSection.* AS PaymentPaymentSection,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentMethod.* AS PaymentPaymentMethod,
		|	PaymentServicesBalanceAndTurnovers.Payment.Payer.* AS PaymentPayer,
		|	PaymentServicesBalanceAndTurnovers.Payment.CashRegister.* AS PaymentCashRegister,
		|	PaymentServicesBalanceAndTurnovers.Payment.Author.* AS PaymentAuthor,
		|	(BEGINOFPERIOD(PaymentServicesBalanceAndTurnovers.Payment.Date, DAY)) AS AccountingDate,
		|	(WEEK(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingWeek,
		|	(MONTH(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingMonth,
		|	(QUARTER(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingQuarter,
		|	(YEAR(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingYear,
		|	(CASE
		|			WHEN ISNULL(ChequeAttributes.IsCorrection, FALSE)
		|				THEN TRUE
		|			WHEN ISNULL(PaymentServicesBalanceAndTurnovers.Payment.CorrectionOfIncorrectCheque, FALSE)
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS IsCorrection,
		|	PaymentServicesBalanceAndTurnovers.Price AS Price,
		|	Quantity,
		|	SumExpense}
		|FROM
		|	(SELECT
		|		Payments.ChequeService AS Service,
		|		Payments.Ref AS Payment,
		|		Payments.Ref.Folio AS Folio,
		|		Payments.SumInFolioCurrency AS SumExpense,
		|		Payments.ChequeServicePrice AS Price,
		|		Payments.ChequeServiceQuantity AS Quantity
		|	FROM
		|		Document.Payment.PaymentSections AS Payments
		|	WHERE
		|		Payments.Ref.Date >= &qPeriodFrom
		|		AND Payments.Ref.Date <= &qPeriodTo
		|		AND Payments.Ref.Posted
		|		AND (Payments.Ref.Hotel IN HIERARCHY (&qHotel)
		|				OR &qHotelIsEmpty)
		|		AND (Payments.Ref.Company IN HIERARCHY (&qCompany)
		|				OR &qCompanyIsEmpty)
		|		AND (Payments.Ref.PaymentMethod = &qPaymentMethod
		|				OR &qPaymentMethodIsEmpty)
		|		AND (Payments.PaymentSection = &qPaymentSection
		|				OR &qPaymentSectionIsEmpty)
		|		AND (Payments.Ref.CashRegister = &qCashRegister
		|				OR &qCashRegisterIsEmpty)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Returns.ChequeService,
		|		Returns.Ref,
		|		Returns.Ref.Folio,
		|		-Returns.SumInFolioCurrency,
		|		Returns.ChequeServicePrice,
		|		-Returns.ChequeServiceQuantity
		|	FROM
		|		Document.Return.PaymentSections AS Returns
		|	WHERE
		|		Returns.Ref.Date >= &qPeriodFrom
		|		AND Returns.Ref.Date <= &qPeriodTo
		|		AND Returns.Ref.Posted
		|		AND (Returns.Ref.Hotel IN HIERARCHY (&qHotel)
		|				OR &qHotelIsEmpty)
		|		AND (Returns.Ref.Company IN HIERARCHY (&qCompany)
		|				OR &qCompanyIsEmpty)
		|		AND (Returns.Ref.PaymentMethod = &qPaymentMethod
		|				OR &qPaymentMethodIsEmpty)
		|		AND (Returns.PaymentSection = &qPaymentSection
		|				OR &qPaymentSectionIsEmpty)
		|		AND (Returns.Ref.CashRegister = &qCashRegister
		|				OR &qCashRegisterIsEmpty)) AS PaymentServicesBalanceAndTurnovers
		|		LEFT JOIN InformationRegister.ChequeAttributes AS ChequeAttributes
		|		ON PaymentServicesBalanceAndTurnovers.Payment = ChequeAttributes.Payment
		|{WHERE
		|	PaymentServicesBalanceAndTurnovers.Folio.* AS Folio,
		|	PaymentServicesBalanceAndTurnovers.Folio.Hotel.* AS FolioHotel,
		|	PaymentServicesBalanceAndTurnovers.Folio.Company.* AS FolioCompany,
		|	PaymentServicesBalanceAndTurnovers.Folio.FolioCurrency.* AS FolioCurrency,
		|	PaymentServicesBalanceAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
		|	PaymentServicesBalanceAndTurnovers.Folio.Agent.* AS FolioAgent,
		|	PaymentServicesBalanceAndTurnovers.Folio.Customer.* AS FolioCustomer,
		|	PaymentServicesBalanceAndTurnovers.Folio.Contract.* AS FolioContract,
		|	PaymentServicesBalanceAndTurnovers.Folio.Client.* AS FolioClient,
		|	PaymentServicesBalanceAndTurnovers.Folio.GuestGroup.* AS FolioGuestGroup,
		|	PaymentServicesBalanceAndTurnovers.Folio.Room.* AS FolioRoom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeFrom AS FolioDateTimeFrom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeTo AS FolioDateTimeTo,
		|	PaymentServicesBalanceAndTurnovers.Service.* AS Service,
		|	PaymentServicesBalanceAndTurnovers.Service.ServiceType.* AS ServiceType,
		|	PaymentServicesBalanceAndTurnovers.Payment.* AS Payment,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentSection.* AS PaymentPaymentSection,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentMethod.* AS PaymentPaymentMethod,
		|	PaymentServicesBalanceAndTurnovers.Payment.Payer.* AS PaymentPayer,
		|	PaymentServicesBalanceAndTurnovers.Payment.CashRegister.* AS PaymentCashRegister,
		|	PaymentServicesBalanceAndTurnovers.Payment.Author.* AS PaymentAuthor,
		|	(CASE
		|			WHEN ISNULL(ChequeAttributes.IsCorrection, FALSE)
		|				THEN TRUE
		|			WHEN ISNULL(PaymentServicesBalanceAndTurnovers.Payment.CorrectionOfIncorrectCheque, FALSE)
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS IsCorrection,
		|	(BEGINOFPERIOD(PaymentServicesBalanceAndTurnovers.Payment.Date, DAY)) AS AccountingDate,
		|	(SUM(PaymentServicesBalanceAndTurnovers.SumExpense)) AS SumExpense,
		|	PaymentServicesBalanceAndTurnovers.Price AS Price,
		|	(SUM(PaymentServicesBalanceAndTurnovers.Quantity)) AS Quantity}
		|
		|GROUP BY
		|	PaymentServicesBalanceAndTurnovers.Service,
		|	PaymentServicesBalanceAndTurnovers.Folio,
		|	PaymentServicesBalanceAndTurnovers.Payment,
		|	PaymentServicesBalanceAndTurnovers.Price
		|
		|ORDER BY
		|	Service
		|{ORDER BY
		|	PaymentServicesBalanceAndTurnovers.Folio.* AS Folio,
		|	PaymentServicesBalanceAndTurnovers.Folio.Hotel.* AS FolioHotel,
		|	PaymentServicesBalanceAndTurnovers.Folio.Company.* AS FolioCompany,
		|	PaymentServicesBalanceAndTurnovers.Folio.FolioCurrency.* AS FolioCurrency,
		|	PaymentServicesBalanceAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
		|	PaymentServicesBalanceAndTurnovers.Folio.Agent.* AS FolioAgent,
		|	PaymentServicesBalanceAndTurnovers.Folio.Customer.* AS FolioCustomer,
		|	PaymentServicesBalanceAndTurnovers.Folio.Contract.* AS FolioContract,
		|	PaymentServicesBalanceAndTurnovers.Folio.Client.* AS FolioClient,
		|	PaymentServicesBalanceAndTurnovers.Folio.GuestGroup.* AS FolioGuestGroup,
		|	PaymentServicesBalanceAndTurnovers.Folio.Room.* AS FolioRoom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeFrom AS FolioDateTimeFrom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeTo AS FolioDateTimeTo,
		|	Service.* AS Service,
		|	PaymentServicesBalanceAndTurnovers.Service.ServiceType.* AS ServiceType,
		|	(BEGINOFPERIOD(PaymentServicesBalanceAndTurnovers.Payment.Date, DAY)) AS AccountingDate,
		|	PaymentServicesBalanceAndTurnovers.Payment.* AS Payment,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentSection.* AS PaymentPaymentSection,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentMethod.* AS PaymentPaymentMethod,
		|	PaymentServicesBalanceAndTurnovers.Payment.Payer.* AS PaymentPayer,
		|	PaymentServicesBalanceAndTurnovers.Payment.CashRegister.* AS PaymentCashRegister,
		|	PaymentServicesBalanceAndTurnovers.Payment.Author.* AS PaymentAuthor,
		|	PaymentServicesBalanceAndTurnovers.Price AS Price,
		|	(CASE
		|			WHEN ISNULL(ChequeAttributes.IsCorrection, FALSE)
		|				THEN TRUE
		|			WHEN ISNULL(PaymentServicesBalanceAndTurnovers.Payment.CorrectionOfIncorrectCheque, FALSE)
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS IsCorrection,
		|	Quantity,
		|	SumExpense}
		|TOTALS
		|	SUM(SumExpense),
		|	SUM(Quantity)
		|BY
		|	OVERALL,
		|	Service HIERARCHY
		|{TOTALS BY
		|	PaymentServicesBalanceAndTurnovers.Folio.* AS Folio,
		|	PaymentServicesBalanceAndTurnovers.Folio.Hotel.* AS FolioHotel,
		|	PaymentServicesBalanceAndTurnovers.Folio.Company.* AS FolioCompany,
		|	PaymentServicesBalanceAndTurnovers.Folio.FolioCurrency.* AS FolioCurrency,
		|	PaymentServicesBalanceAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
		|	PaymentServicesBalanceAndTurnovers.Folio.Agent.* AS FolioAgent,
		|	PaymentServicesBalanceAndTurnovers.Folio.Customer.* AS FolioCustomer,
		|	PaymentServicesBalanceAndTurnovers.Folio.Contract.* AS FolioContract,
		|	PaymentServicesBalanceAndTurnovers.Folio.Client.* AS FolioClient,
		|	PaymentServicesBalanceAndTurnovers.Folio.GuestGroup.* AS FolioGuestGroup,
		|	PaymentServicesBalanceAndTurnovers.Folio.Room.* AS FolioRoom,
		|	Service.* AS Service,
		|	Quantity,
		|	PaymentServicesBalanceAndTurnovers.Price AS Price,
		|	PaymentServicesBalanceAndTurnovers.Service.ServiceType.* AS ServiceType,
		|	(BEGINOFPERIOD(PaymentServicesBalanceAndTurnovers.Payment.Date, DAY)) AS AccountingDate,
		|	(WEEK(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingWeek,
		|	(MONTH(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingMonth,
		|	(QUARTER(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingQuarter,
		|	(YEAR(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingYear,
		|	(CASE
		|			WHEN ISNULL(ChequeAttributes.IsCorrection, FALSE)
		|				THEN TRUE
		|			WHEN ISNULL(PaymentServicesBalanceAndTurnovers.Payment.CorrectionOfIncorrectCheque, FALSE)
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS IsCorrection,
		|	PaymentServicesBalanceAndTurnovers.Payment.* AS Payment,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentSection.* AS PaymentPaymentSection,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentMethod.* AS PaymentPaymentMethod,
		|	PaymentServicesBalanceAndTurnovers.Payment.Payer.* AS PaymentPayer,
		|	PaymentServicesBalanceAndTurnovers.Payment.CashRegister.* AS PaymentCashRegister,
		|	PaymentServicesBalanceAndTurnovers.Payment.Author.* AS PaymentAuthor}";
	Else
		QueryText = 
		"SELECT
		|	PaymentServicesBalanceAndTurnovers.Service AS Service,
		|	PaymentServicesBalanceAndTurnovers.SumExpense AS SumExpense,
		|	0 AS Quantity
		|{SELECT
		|	PaymentServicesBalanceAndTurnovers.Folio.* AS Folio,
		|	PaymentServicesBalanceAndTurnovers.Folio.Hotel.* AS FolioHotel,
		|	PaymentServicesBalanceAndTurnovers.Folio.Company.* AS FolioCompany,
		|	PaymentServicesBalanceAndTurnovers.Folio.FolioCurrency.* AS FolioCurrency,
		|	PaymentServicesBalanceAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
		|	PaymentServicesBalanceAndTurnovers.Folio.Agent.* AS FolioAgent,
		|	PaymentServicesBalanceAndTurnovers.Folio.Customer.* AS FolioCustomer,
		|	PaymentServicesBalanceAndTurnovers.Folio.Contract.* AS FolioContract,
		|	PaymentServicesBalanceAndTurnovers.Folio.Client.* AS FolioClient,
		|	PaymentServicesBalanceAndTurnovers.Folio.GuestGroup.* AS FolioGuestGroup,
		|	PaymentServicesBalanceAndTurnovers.Folio.Room.* AS FolioRoom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeFrom AS FolioDateTimeFrom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeTo AS FolioDateTimeTo,
		|	Service.* AS Service,
		|	PaymentServicesBalanceAndTurnovers.Service.ServiceType.* AS ServiceType,
		|	PaymentServicesBalanceAndTurnovers.Payment.* AS Payment,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentSection.* AS PaymentPaymentSection,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentMethod.* AS PaymentPaymentMethod,
		|	PaymentServicesBalanceAndTurnovers.Payment.Payer.* AS PaymentPayer,
		|	PaymentServicesBalanceAndTurnovers.Payment.CashRegister.* AS PaymentCashRegister,
		|	PaymentServicesBalanceAndTurnovers.Payment.Author.* AS PaymentAuthor,
		|	(BEGINOFPERIOD(PaymentServicesBalanceAndTurnovers.Payment.Date, DAY)) AS AccountingDate,
		|	(WEEK(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingWeek,
		|	(MONTH(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingMonth,
		|	(QUARTER(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingQuarter,
		|	(YEAR(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingYear,
		|	(CASE
		|			WHEN ISNULL(ChequeAttributes.IsCorrection, FALSE)
		|				THEN TRUE
		|			WHEN ISNULL(PaymentServicesBalanceAndTurnovers.Payment.CorrectionOfIncorrectCheque, FALSE)
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS IsCorrection,
		|	SumExpense,
		|	(0) AS Price,
		|	Quantity}
		|FROM
		|	AccumulationRegister.PaymentServices.BalanceAndTurnovers(
		|			&qPeriodFrom,
		|			&qPeriodTo,
		|			Period,
		|			RegisterRecordsAndPeriodBoundaries,
		|			Payment <> UNDEFINED
		|				AND (Folio.Hotel IN HIERARCHY (&qHotel)
		|					OR &qHotelIsEmpty)
		|				AND (Folio.Company IN HIERARCHY (&qCompany)
		|					OR &qCompanyIsEmpty)
		|				AND (Payment.PaymentMethod = &qPaymentMethod
		|					OR &qPaymentMethodIsEmpty)
		|				AND (Payment.PaymentSection = &qPaymentSection
		|					OR &qPaymentSectionIsEmpty)
		|				AND (Payment.CashRegister = &qCashRegister
		|					OR &qCashRegisterIsEmpty)) AS PaymentServicesBalanceAndTurnovers
		|		LEFT JOIN InformationRegister.ChequeAttributes AS ChequeAttributes
		|		ON PaymentServicesBalanceAndTurnovers.Payment = ChequeAttributes.Payment
		|{WHERE
		|	PaymentServicesBalanceAndTurnovers.Folio.* AS Folio,
		|	PaymentServicesBalanceAndTurnovers.Folio.Hotel.* AS FolioHotel,
		|	PaymentServicesBalanceAndTurnovers.Folio.Company.* AS FolioCompany,
		|	PaymentServicesBalanceAndTurnovers.Folio.FolioCurrency.* AS FolioCurrency,
		|	PaymentServicesBalanceAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
		|	PaymentServicesBalanceAndTurnovers.Folio.Agent.* AS FolioAgent,
		|	PaymentServicesBalanceAndTurnovers.Folio.Customer.* AS FolioCustomer,
		|	PaymentServicesBalanceAndTurnovers.Folio.Contract.* AS FolioContract,
		|	PaymentServicesBalanceAndTurnovers.Folio.Client.* AS FolioClient,
		|	PaymentServicesBalanceAndTurnovers.Folio.GuestGroup.* AS FolioGuestGroup,
		|	PaymentServicesBalanceAndTurnovers.Folio.Room.* AS FolioRoom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeFrom AS FolioDateTimeFrom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeTo AS FolioDateTimeTo,
		|	PaymentServicesBalanceAndTurnovers.Service.* AS Service,
		|	PaymentServicesBalanceAndTurnovers.Service.ServiceType.* AS ServiceType,
		|	PaymentServicesBalanceAndTurnovers.Payment.* AS Payment,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentSection.* AS PaymentPaymentSection,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentMethod.* AS PaymentPaymentMethod,
		|	PaymentServicesBalanceAndTurnovers.Payment.Payer.* AS PaymentPayer,
		|	PaymentServicesBalanceAndTurnovers.Payment.CashRegister.* AS PaymentCashRegister,
		|	PaymentServicesBalanceAndTurnovers.Payment.Author.* AS PaymentAuthor,
		|	(BEGINOFPERIOD(PaymentServicesBalanceAndTurnovers.Payment.Date, DAY)) AS AccountingDate,
		|	(CASE
		|			WHEN ISNULL(ChequeAttributes.IsCorrection, FALSE)
		|				THEN TRUE
		|			WHEN ISNULL(PaymentServicesBalanceAndTurnovers.Payment.CorrectionOfIncorrectCheque, FALSE)
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS IsCorrection,
		|	PaymentServicesBalanceAndTurnovers.SumExpense,
		|	(0) AS Price,
		|	(0) AS Quantity}
		|
		|ORDER BY
		|	Service
		|{ORDER BY
		|	PaymentServicesBalanceAndTurnovers.Folio.* AS Folio,
		|	PaymentServicesBalanceAndTurnovers.Folio.Hotel.* AS FolioHotel,
		|	PaymentServicesBalanceAndTurnovers.Folio.Company.* AS FolioCompany,
		|	PaymentServicesBalanceAndTurnovers.Folio.FolioCurrency.* AS FolioCurrency,
		|	PaymentServicesBalanceAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
		|	PaymentServicesBalanceAndTurnovers.Folio.Agent.* AS FolioAgent,
		|	PaymentServicesBalanceAndTurnovers.Folio.Customer.* AS FolioCustomer,
		|	PaymentServicesBalanceAndTurnovers.Folio.Contract.* AS FolioContract,
		|	PaymentServicesBalanceAndTurnovers.Folio.Client.* AS FolioClient,
		|	PaymentServicesBalanceAndTurnovers.Folio.GuestGroup.* AS FolioGuestGroup,
		|	PaymentServicesBalanceAndTurnovers.Folio.Room.* AS FolioRoom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeFrom AS FolioDateTimeFrom,
		|	PaymentServicesBalanceAndTurnovers.Folio.DateTimeTo AS FolioDateTimeTo,
		|	Service.* AS Service,
		|	PaymentServicesBalanceAndTurnovers.Service.ServiceType.* AS ServiceType,
		|	(BEGINOFPERIOD(PaymentServicesBalanceAndTurnovers.Payment.Date, DAY)) AS AccountingDate,
		|	PaymentServicesBalanceAndTurnovers.Payment.* AS Payment,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentSection.* AS PaymentPaymentSection,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentMethod.* AS PaymentPaymentMethod,
		|	PaymentServicesBalanceAndTurnovers.Payment.Payer.* AS PaymentPayer,
		|	PaymentServicesBalanceAndTurnovers.Payment.CashRegister.* AS PaymentCashRegister,
		|	PaymentServicesBalanceAndTurnovers.Payment.Author.* AS PaymentAuthor,
		|	(CASE
		|			WHEN ISNULL(ChequeAttributes.IsCorrection, FALSE)
		|				THEN TRUE
		|			WHEN ISNULL(PaymentServicesBalanceAndTurnovers.Payment.CorrectionOfIncorrectCheque, FALSE)
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS IsCorrection,
		|	SumExpense,
		|	(0) AS Price,
		|	Quantity}
		|TOTALS
		|	SUM(SumExpense),
		|	SUM(Quantity)
		|BY
		|	OVERALL,
		|	Service HIERARCHY
		|{TOTALS BY
		|	PaymentServicesBalanceAndTurnovers.Folio.* AS Folio,
		|	PaymentServicesBalanceAndTurnovers.Folio.Hotel.* AS FolioHotel,
		|	PaymentServicesBalanceAndTurnovers.Folio.Company.* AS FolioCompany,
		|	PaymentServicesBalanceAndTurnovers.Folio.FolioCurrency.* AS FolioCurrency,
		|	PaymentServicesBalanceAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
		|	PaymentServicesBalanceAndTurnovers.Folio.Agent.* AS FolioAgent,
		|	PaymentServicesBalanceAndTurnovers.Folio.Customer.* AS FolioCustomer,
		|	PaymentServicesBalanceAndTurnovers.Folio.Contract.* AS FolioContract,
		|	PaymentServicesBalanceAndTurnovers.Folio.Client.* AS FolioClient,
		|	PaymentServicesBalanceAndTurnovers.Folio.GuestGroup.* AS FolioGuestGroup,
		|	PaymentServicesBalanceAndTurnovers.Folio.Room.* AS FolioRoom,
		|	Service.* AS Service,
		|	PaymentServicesBalanceAndTurnovers.Service.ServiceType.* AS ServiceType,
		|	(BEGINOFPERIOD(PaymentServicesBalanceAndTurnovers.Payment.Date, DAY)) AS AccountingDate,
		|	(WEEK(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingWeek,
		|	(MONTH(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingMonth,
		|	(QUARTER(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingQuarter,
		|	(YEAR(PaymentServicesBalanceAndTurnovers.Payment.Date)) AS AccountingYear,
		|	PaymentServicesBalanceAndTurnovers.Payment.* AS Payment,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentSection.* AS PaymentPaymentSection,
		|	PaymentServicesBalanceAndTurnovers.Payment.PaymentMethod.* AS PaymentPaymentMethod,
		|	PaymentServicesBalanceAndTurnovers.Payment.Payer.* AS PaymentPayer,
		|	PaymentServicesBalanceAndTurnovers.Payment.CashRegister.* AS PaymentCashRegister,
		|	PaymentServicesBalanceAndTurnovers.Payment.Author.* AS PaymentAuthor,
		|	(CASE
		|			WHEN ISNULL(ChequeAttributes.IsCorrection, FALSE)
		|				THEN TRUE
		|			WHEN ISNULL(PaymentServicesBalanceAndTurnovers.Payment.CorrectionOfIncorrectCheque, FALSE)
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS IsCorrection,
		|	(0) AS Price}";
	EndIf;
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Payments distribution to services charged';RU='Распределение платежей по оказанным услугам';de='Aufteilung der Zahlungen nach erbrachten Diensten'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
