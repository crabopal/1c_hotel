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
		PeriodFrom = AddMonth(BegOfMonth(CurrentSessionDate()), -1);
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = AddMonth(EndOfMonth(CurrentSessionDate()), -1);
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
	ReportBuilder.Parameters.Insert("qPeriodIsEmpty", Not ValueIsFilled(PeriodTo));
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qServiceIsEmpty", Not ValueIsFilled(Service));
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qEmptyString", "");
	
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
	|	GiftCertificatesBalance.GiftCertificate AS GiftCertificate,
	|	GiftCertificatesBalance.Hotel AS Hotel,
	|	GiftCertificatesBalance.AmountOpeningBalance AS AmountOpeningBalance,
	|	GiftCertificatesBalance.AmountReceipt AS PayedAmount,
	|	GiftCertificatesBalance.AmountExpense AS WriteOffAmount,
	|	GiftCertificatesBalance.AmountClosingBalance AS AmountClosingBalance,
	|	1 AS Quantity
	|INTO ActiveGiftCertificates
	|FROM
	|	AccumulationRegister.GiftCertificatesBalance.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			PERIOD,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qHotelIsEmpty
	|				OR NOT &qHotelIsEmpty
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR Hotel = &qEmptyHotel)) AS GiftCertificatesBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BlockedGiftCertificatesSliceLast.GiftCertificate AS GiftCertificate,
	|	BlockedGiftCertificatesSliceLast.BlockReason AS BlockReason,
	|	BlockedGiftCertificatesSliceLast.BlockDate AS BlockDate,
	|	BlockedGiftCertificatesSliceLast.BlockAuthor AS BlockAuthor,
	|	BlockedGiftCertificatesSliceLast.Period AS Period
	|INTO BlockedGiftCertificates
	|FROM
	|	InformationRegister.GiftCertificates.SliceLast(
	|			&qPeriodTo,
	|			&qHotelIsEmpty
	|				OR NOT &qHotelIsEmpty
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR Hotel = &qEmptyHotel)) AS BlockedGiftCertificatesSliceLast
	|WHERE
	|	BlockedGiftCertificatesSliceLast.BlockDate <> &qEmptyDate
	|	AND (&qPeriodIsEmpty
	|			OR NOT &qPeriodIsEmpty
	|				AND BlockedGiftCertificatesSliceLast.BlockDate < BEGINOFPERIOD(&qPeriodTo, DAY))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ActiveGiftCertificates.GiftCertificate AS GiftCertificate,
	|	ActiveGiftCertificates.Hotel AS Hotel,
	|	GiftCertificateCharges.Service AS Service,
	|	GiftCertificateCharges.NominalAmount AS NominalAmount,
	|	GiftCertificatePayments.Client AS Client,
	|	GiftCertificatePayments.Customer AS Customer,
	|	GiftCertificatePayments.Contract AS Contract,
	|	GiftCertificatePayments.GuestGroup AS GuestGroup,
	|	GiftCertificatePayments.PeriodFrom AS PeriodFrom,
	|	GiftCertificatePayments.PeriodTo AS PeriodTo,
	|	GiftCertificatePayments.Room AS Room,
	|	GiftCertificatePayments.RoomType AS RoomType,
	|	GiftCertificatePayments.Company AS Company,
	|	GiftCertificatePayments.ParentDoc AS ParentDoc,
	|	GiftCertificatePayments.Author AS Author,
	|	GiftCertificatePayments.RegistrationDate AS RegistrationDate,
	|	ActiveGiftCertificates.AmountOpeningBalance AS AmountOpeningBalance,
	|	ActiveGiftCertificates.PayedAmount AS PayedAmount,
	|	ActiveGiftCertificates.WriteOffAmount AS WriteOffAmount,
	|	ActiveGiftCertificates.AmountClosingBalance AS AmountClosingBalance,
	|	ActiveGiftCertificates.Quantity AS Quantity
	|{SELECT
	|	GiftCertificate,
	|	Hotel.*,
	|	Service.*,
	|	Client.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	PeriodFrom,
	|	PeriodTo,
	|	Room.*,
	|	RoomType.*,
	|	Company.*,
	|	Author.*,
	|	RegistrationDate,
	|	ParentDoc.*,
	|	(CASE
	|			WHEN BlockedGiftCertificates.BlockDate IS NULL
	|				THEN FALSE
	|			ELSE TRUE
	|		END) AS IsBlocked,
	|	BlockedGiftCertificates.BlockReason AS BlockReason,
	|	BlockedGiftCertificates.BlockDate AS BlockDate,
	|	BlockedGiftCertificates.BlockAuthor.* AS BlockAuthor,
	|	NominalAmount,
	|	AmountOpeningBalance,
	|	PayedAmount,
	|	WriteOffAmount,
	|	AmountClosingBalance,
	|	Quantity}
	|FROM
	|	ActiveGiftCertificates AS ActiveGiftCertificates
	|		LEFT JOIN (SELECT
	|			Charge.GiftCertificate AS GiftCertificate,
	|			Charge.Service AS Service,
	|			Charge.Sum - Charge.DiscountSum AS NominalAmount
	|		FROM
	|			Document.Charge AS Charge
	|		WHERE
	|			Charge.Posted
	|			AND Charge.GiftCertificate <> &qEmptyString
	|			AND (&qHotelIsEmpty
	|					OR NOT &qHotelIsEmpty
	|						AND Charge.Hotel IN HIERARCHY (&qHotel))
	|			AND Charge.Service.IsGiftCertificate) AS GiftCertificateCharges
	|		ON ActiveGiftCertificates.GiftCertificate = GiftCertificateCharges.GiftCertificate
	|		LEFT JOIN (SELECT
	|			Payments.GiftCertificate AS GiftCertificate,
	|			Payments.Author AS Author,
	|			MIN(Payments.Date) AS RegistrationDate,
	|			Payments.Client AS Client,
	|			Payments.Customer AS Customer,
	|			Payments.Contract AS Contract,
	|			Payments.GuestGroup AS GuestGroup,
	|			Payments.PeriodFrom AS PeriodFrom,
	|			Payments.PeriodTo AS PeriodTo,
	|			Payments.Hotel AS Hotel,
	|			Payments.Room AS Room,
	|			Payments.RoomType AS RoomType,
	|			Payments.Company AS Company,
	|			Payments.ParentDoc AS ParentDoc
	|		FROM
	|			(SELECT
	|				Payments.GiftCertificate AS GiftCertificate,
	|				Payments.Author AS Author,
	|				Payments.Date AS Date,
	|				Payments.Folio.Client AS Client,
	|				Payments.Folio.Customer AS Customer,
	|				Payments.Folio.Contract AS Contract,
	|				Payments.Folio.GuestGroup AS GuestGroup,
	|				Payments.Folio.DateTimeFrom AS PeriodFrom,
	|				Payments.Folio.DateTimeTo AS PeriodTo,
	|				Payments.Folio.Hotel AS Hotel,
	|				Payments.Folio.Room AS Room,
	|				Payments.Folio.Room.RoomType AS RoomType,
	|				Payments.Folio.Company AS Company,
	|				Payments.Folio.ParentDoc AS ParentDoc
	|			FROM
	|				Document.Payment AS Payments
	|			WHERE
	|				Payments.Posted
	|				AND Payments.GiftCertificate <> &qEmptyString
	|				AND (&qHotelIsEmpty
	|						OR NOT &qHotelIsEmpty
	|							AND Payments.Hotel IN HIERARCHY (&qHotel))
	|				AND NOT Payments.PaymentMethod.IsByGiftCertificate
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				Returns.GiftCertificate,
	|				Returns.Author,
	|				Returns.Date,
	|				Returns.Folio.Client,
	|				Returns.Folio.Customer,
	|				Returns.Folio.Contract,
	|				Returns.Folio.GuestGroup,
	|				Returns.Folio.DateTimeFrom,
	|				Returns.Folio.DateTimeTo,
	|				Returns.Folio.Hotel,
	|				Returns.Folio.Room,
	|				Returns.Folio.Room.RoomType,
	|				Returns.Folio.Company,
	|				Returns.Folio.ParentDoc
	|			FROM
	|				Document.Return AS Returns
	|			WHERE
	|				Returns.Posted
	|				AND Returns.GiftCertificate <> &qEmptyString
	|				AND (&qHotelIsEmpty
	|						OR NOT &qHotelIsEmpty
	|							AND Returns.Hotel IN HIERARCHY (&qHotel))
	|				AND NOT Returns.PaymentMethod.IsByGiftCertificate) AS Payments
	|		
	|		GROUP BY
	|			Payments.GiftCertificate,
	|			Payments.Author,
	|			Payments.Client,
	|			Payments.Customer,
	|			Payments.Contract,
	|			Payments.GuestGroup,
	|			Payments.PeriodFrom,
	|			Payments.PeriodTo,
	|			Payments.Hotel,
	|			Payments.Room,
	|			Payments.RoomType,
	|			Payments.Company,
	|			Payments.ParentDoc) AS GiftCertificatePayments
	|		ON ActiveGiftCertificates.GiftCertificate = GiftCertificatePayments.GiftCertificate
	|		LEFT JOIN BlockedGiftCertificates AS BlockedGiftCertificates
	|		ON ActiveGiftCertificates.GiftCertificate = BlockedGiftCertificates.GiftCertificate
	|WHERE
	|	(&qServiceIsEmpty
	|			OR NOT &qServiceIsEmpty
	|				AND GiftCertificateCharges.Service IN HIERARCHY (&qService))
	|{WHERE
	|	ActiveGiftCertificates.GiftCertificate AS GiftCertificate,
	|	ActiveGiftCertificates.Hotel.* AS Hotel,
	|	GiftCertificateCharges.Service.* AS Service,
	|	GiftCertificateCharges.NominalAmount AS NominalAmount,
	|	GiftCertificatePayments.Client.* AS Client,
	|	GiftCertificatePayments.Customer.* AS Customer,
	|	GiftCertificatePayments.Contract.* AS Contract,
	|	GiftCertificatePayments.GuestGroup.* AS GuestGroup,
	|	GiftCertificatePayments.PeriodFrom AS PeriodFrom,
	|	GiftCertificatePayments.PeriodTo AS PeriodTo,
	|	GiftCertificatePayments.Room.* AS Room,
	|	GiftCertificatePayments.RoomType.* AS RoomType,
	|	GiftCertificatePayments.Company.* AS Company,
	|	GiftCertificatePayments.ParentDoc.* AS ParentDoc,
	|	GiftCertificatePayments.Author.* AS Author,
	|	GiftCertificatePayments.RegistrationDate AS RegistrationDate,
	|	(CASE
	|			WHEN BlockedGiftCertificates.BlockDate IS NULL
	|				THEN FALSE
	|			ELSE TRUE
	|		END) AS IsBlocked,
	|	BlockedGiftCertificates.BlockReason AS BlockReason,
	|	BlockedGiftCertificates.BlockDate AS BlockDate,
	|	BlockedGiftCertificates.BlockAuthor.* AS BlockAuthor,
	|	ActiveGiftCertificates.AmountOpeningBalance AS AmountOpeningBalance,
	|	ActiveGiftCertificates.PayedAmount AS PayedAmount,
	|	ActiveGiftCertificates.WriteOffAmount AS WriteOffAmount,
	|	ActiveGiftCertificates.AmountClosingBalance AS AmountClosingBalance}
	|
	|ORDER BY
	|	GiftCertificate
	|{ORDER BY
	|	GiftCertificate,
	|	Hotel.*,
	|	Service.*,
	|	Client.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	PeriodFrom,
	|	PeriodTo,
	|	Room.*,
	|	RoomType.*,
	|	Company.*,
	|	ParentDoc.*,
	|	Author.*,
	|	RegistrationDate,
	|	(CASE
	|			WHEN BlockedGiftCertificates.BlockDate IS NULL
	|				THEN FALSE
	|			ELSE TRUE
	|		END) AS IsBlocked,
	|	BlockedGiftCertificates.BlockReason AS BlockReason,
	|	BlockedGiftCertificates.BlockDate AS BlockDate,
	|	BlockedGiftCertificates.BlockAuthor.* AS BlockAuthor,
	|	NominalAmount,
	|	AmountOpeningBalance,
	|	PayedAmount,
	|	WriteOffAmount,
	|	AmountClosingBalance}
	|TOTALS
	|	SUM(NominalAmount),
	|	SUM(AmountOpeningBalance),
	|	SUM(PayedAmount),
	|	SUM(WriteOffAmount),
	|	SUM(AmountClosingBalance),
	|	SUM(Quantity)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Hotel.*,
	|	Service.*,
	|	Client.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Room.*,
	|	RoomType.*,
	|	Company.*,
	|	ParentDoc.*,
	|	Author.*,
	|	(CASE
	|			WHEN BlockedGiftCertificates.BlockDate IS NULL
	|				THEN FALSE
	|			ELSE TRUE
	|		END) AS IsBlocked,
	|	BlockedGiftCertificates.BlockReason AS BlockReason,
	|	BlockedGiftCertificates.BlockAuthor.* AS BlockAuthor}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Gift certificates';RU='Подарочные сертификаты';de='Geschenkgutscheine'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Quantity" 
	   Or pName = "NominalAmount" 
	   Or pName = "AmountOpeningBalance" 
	   Or pName = "PayedAmount" 
	   Or pName = "WriteOffAmount" 
	   Or pName = "AmountClosingBalance" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
