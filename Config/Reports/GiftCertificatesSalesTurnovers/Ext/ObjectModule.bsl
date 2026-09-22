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
		                     Format(PeriodFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy'") + 
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
	If ValueIsFilled(Card) Then
		If Not Card.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Card ';ru='Карты ';de='Karte '") + 
			                     TrimAll(Card) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Cards folder ';ru='Группа карт ';de='Kartegruppe '") + 
			                     TrimAll(Card) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(DiscountType) Then
		If Not DiscountType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Card type ';ru='Тип карты ';de='Kartetyp '") + 
			                     TrimAll(DiscountType) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Card types folder ';ru='Группа типов карт ';de='Kartetypgruppe '") + 
			                     TrimAll(DiscountType) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Payer ';ru='Плательщик ';de='Zahler '") + 
			                     TrimAll(Customer) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Payers folder ';ru='Группа плательщиков ';de='Zahlergruppe '") + 
			                     TrimAll(Customer) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Client) Then
		If Not Client.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Client ';ru='Клиент ';de='Kunde '") + 
			                     TrimAll(Client) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Clients folder ';ru='Группа клиентов ';de='Kundegruppe '") + 
			                     TrimAll(Client) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Author) Then
		If Not Author.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Author ';ru='Автор ';de='Autor '") + 
			                     TrimAll(Author) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Authors folder ';ru='Группа авторов ';de='Autorgruppe '") + 
			                     TrimAll(Author) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Employee) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Employees folder ';ru='Группа сотрудников ';de='Mitarbeitergruppe '") + 
			                     TrimAll(Employee) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Department) Then
		If Not Department.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Department ';ru='Отдел ';de='Abteilung '") + 
			                     TrimAll(Department) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Departments folder ';ru='Группа отделов ';de='Abteilungengruppe '") + 
			                     TrimAll(Department) + 
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
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qCard", Card);
	ReportBuilder.Parameters.Insert("qDiscountType", DiscountType);
	ReportBuilder.Parameters.Insert("qConsumer", Consumer);
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qClient", Client);
	ReportBuilder.Parameters.Insert("qAuthor", Author);
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qDepartment", Department);
	ReportBuilder.Parameters.Insert("qByDocumentTimestamp", PeriodSelectionByDocumentTimestamp);
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	
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
	|	BonusesMovements.Card AS Card,
	|	MIN(BonusesMovements.Period) AS MinPeriod
	|INTO EffectiveCards
	|FROM
	|	AccumulationRegister.Bonuses AS BonusesMovements
	|WHERE
	|	CASE
	|			WHEN &qByDocumentTimestamp
	|					AND BonusesMovements.Period >= &qPeriodFrom
	|					AND BonusesMovements.Period <= &qPeriodTo
	|				THEN TRUE
	|			WHEN NOT &qByDocumentTimestamp
	|					AND ISNULL(BonusesMovements.Recorder.Payment.AccountingDate, BonusesMovements.Period) >= &qPeriodFrom
	|					AND ISNULL(BonusesMovements.Recorder.Payment.AccountingDate, BonusesMovements.Period) <= &qPeriodTo
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|	AND (BonusesMovements.Card.CreateHotel IN HIERARCHY (&qHotel)
	|			OR BonusesMovements.Card.CreateHotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR &qHotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND (BonusesMovements.Card IN HIERARCHY (&qCard)
	|			OR &qCard = VALUE(Catalog.DiscountCards.EmptyRef))
	|	AND (BonusesMovements.Card.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomer = VALUE(Catalog.Customers.EmptyRef))
	|	AND (BonusesMovements.Card.Consumer IN HIERARCHY (&qConsumer)
	|			OR &qConsumer = VALUE(Catalog.Customers.EmptyRef))
	|	AND (BonusesMovements.Card.Client IN HIERARCHY (&qClient)
	|			OR &qClient = VALUE(Catalog.Clients.EmptyRef))
	|	AND (BonusesMovements.Card.Author IN HIERARCHY (&qAuthor)
	|			OR &qAuthor = VALUE(Catalog.Employees.EmptyRef))
	|	AND (BonusesMovements.Card.DiscountType IN HIERARCHY (&qDiscountType)
	|			OR &qDiscountType = VALUE(Catalog.DiscountTypes.EmptyRef))
	|	AND (BonusesMovements.Recorder.Author IN HIERARCHY (&qEmployee)
	|			OR &qEmployee = VALUE(Catalog.Employees.EmptyRef))
	|	AND (BonusesMovements.Recorder.Author.Department IN HIERARCHY (&qDepartment)
	|			OR &qDepartment = VALUE(Catalog.Departments.EmptyRef))
	|	AND BonusesMovements.Quantity <> 0
	|
	|GROUP BY
	|	BonusesMovements.Card
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CardNominalAmounts.Card AS Card,
	|	SUM(CardNominalAmounts.Quantity) AS NominalAmount
	|INTO CardNominalAmounts
	|FROM
	|	AccumulationRegister.Bonuses AS CardNominalAmounts
	|		INNER JOIN EffectiveCards AS EffectiveCards
	|		ON CardNominalAmounts.Card = EffectiveCards.Card
	|WHERE
	|	CardNominalAmounts.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND NOT(CardNominalAmounts.Recorder.Payment REFS Document.Return
	|				AND (CardNominalAmounts.Recorder.Payment.PaymentMethod.IsByBonuses
	|					OR CardNominalAmounts.Recorder.Payment.PaymentMethod.IsByGiftCertificate))
	|
	|GROUP BY
	|	CardNominalAmounts.Card
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusesMovements.Card AS Card,
	|	BonusesMovements.Period AS Period,
	|	BonusesMovements.Recorder AS Recorder,
	|	BonusesMovements.Recorder.Payment AS Payment,
	|	CASE
	|		WHEN &qByDocumentTimestamp
	|			THEN BEGINOFPERIOD(BonusesMovements.Period, DAY)
	|		ELSE BEGINOFPERIOD(ISNULL(BonusesMovements.Recorder.Payment.AccountingDate, BonusesMovements.Period), DAY)
	|	END AS AccountingDate,
	|	CASE
	|		WHEN &qByDocumentTimestamp
	|			THEN BEGINOFPERIOD(BonusesMovements.Period, MONTH)
	|		ELSE BEGINOFPERIOD(ISNULL(BonusesMovements.Recorder.Payment.AccountingDate, BonusesMovements.Period), MONTH)
	|	END AS AccountingMonth,
	|	CASE
	|		WHEN &qByDocumentTimestamp
	|			THEN BEGINOFPERIOD(BonusesMovements.Period, QUARTER)
	|		ELSE BEGINOFPERIOD(ISNULL(BonusesMovements.Recorder.Payment.AccountingDate, BonusesMovements.Period), QUARTER)
	|	END AS AccountingQuarter,
	|	CASE
	|		WHEN &qByDocumentTimestamp
	|			THEN BEGINOFPERIOD(BonusesMovements.Period, YEAR)
	|		ELSE BEGINOFPERIOD(ISNULL(BonusesMovements.Recorder.Payment.AccountingDate, BonusesMovements.Period), YEAR)
	|	END AS AccountingYear,
	|	CASE
	|		WHEN BonusesMovements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN BonusesMovements.Quantity
	|		ELSE 0
	|	END AS AmountReceipt,
	|	CASE
	|		WHEN BonusesMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN BonusesMovements.Quantity
	|		ELSE 0
	|	END AS AmountExpense,
	|	CASE
	|		WHEN BonusesMovements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN BonusesMovements.Quantity
	|		ELSE -BonusesMovements.Quantity
	|	END AS AmountBalance,
	|	CASE
	|		WHEN BonusesMovements.Period = EffectiveCards.MinPeriod
	|			THEN 1
	|		ELSE 0
	|	END AS Counter,
	|	ISNULL(CardsNominal.NominalAmount, 0) AS NominalAmount
	|{SELECT
	|	Card.*,
	|	Period,
	|	Payment.*,
	|	Recorder.*,
	|	AccountingDate,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	AmountReceipt,
	|	AmountExpense,
	|	AmountBalance,
	|	Counter,
	|	NominalAmount}
	|FROM
	|	AccumulationRegister.Bonuses AS BonusesMovements
	|		LEFT JOIN CardNominalAmounts AS CardsNominal
	|		ON BonusesMovements.Card = CardsNominal.Card
	|		LEFT JOIN EffectiveCards AS EffectiveCards
	|		ON BonusesMovements.Card = EffectiveCards.Card
	|WHERE
	|	CASE
	|			WHEN &qByDocumentTimestamp
	|					AND BonusesMovements.Period >= &qPeriodFrom
	|					AND BonusesMovements.Period <= &qPeriodTo
	|				THEN TRUE
	|			WHEN NOT &qByDocumentTimestamp
	|					AND ISNULL(BonusesMovements.Recorder.Payment.AccountingDate, BonusesMovements.Period) >= &qPeriodFrom
	|					AND ISNULL(BonusesMovements.Recorder.Payment.AccountingDate, BonusesMovements.Period) <= &qPeriodTo
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|	AND (BonusesMovements.Card.CreateHotel IN HIERARCHY (&qHotel)
	|			OR BonusesMovements.Card.CreateHotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR &qHotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND (BonusesMovements.Card IN HIERARCHY (&qCard)
	|			OR &qCard = VALUE(Catalog.DiscountCards.EmptyRef))
	|	AND (BonusesMovements.Card.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomer = VALUE(Catalog.Customers.EmptyRef))
	|	AND (BonusesMovements.Card.Consumer IN HIERARCHY (&qConsumer)
	|			OR &qConsumer = VALUE(Catalog.Customers.EmptyRef))
	|	AND (BonusesMovements.Card.Client IN HIERARCHY (&qClient)
	|			OR &qClient = VALUE(Catalog.Clients.EmptyRef))
	|	AND (BonusesMovements.Card.Author IN HIERARCHY (&qAuthor)
	|			OR &qAuthor = VALUE(Catalog.Employees.EmptyRef))
	|	AND (BonusesMovements.Card.DiscountType IN HIERARCHY (&qDiscountType)
	|			OR &qDiscountType = VALUE(Catalog.DiscountTypes.EmptyRef))
	|	AND (BonusesMovements.Recorder.Author IN HIERARCHY (&qEmployee)
	|			OR &qEmployee = VALUE(Catalog.Employees.EmptyRef))
	|	AND (BonusesMovements.Recorder.Author.Department IN HIERARCHY (&qDepartment)
	|			OR &qDepartment = VALUE(Catalog.Departments.EmptyRef))
	|	AND BonusesMovements.Quantity <> 0
	|{WHERE
	|	BonusesMovements.Period AS Period,
	|	BonusesMovements.Recorder.Payment.* AS Payment,
	|	BonusesMovements.Recorder.* AS Recorder,
	|	(CASE
	|			WHEN BonusesMovements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN BonusesMovements.Quantity
	|			ELSE 0
	|		END) AS AmountReceipt,
	|	(CASE
	|			WHEN BonusesMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN BonusesMovements.Quantity
	|			ELSE 0
	|		END) AS AmountExpense,
	|	(CASE
	|			WHEN BonusesMovements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN BonusesMovements.Quantity
	|			ELSE -BonusesMovements.Quantity
	|		END) AS AmountBalance}
	|
	|ORDER BY
	|	Card
	|{ORDER BY
	|	Card.*,
	|	Period,
	|	AccountingDate,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	Payment.*,
	|	Recorder.*,
	|	AmountReceipt,
	|	AmountExpense,
	|	AmountBalance,
	|	NominalAmount}
	|TOTALS
	|	SUM(AmountReceipt),
	|	SUM(AmountExpense),
	|	SUM(AmountBalance),
	|	SUM(Counter)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Card.*,
	|	AccountingDate,
	|	AccountingMonth,
	|	AccountingQuarter,
	|	AccountingYear,
	|	Payment.*,
	|	Recorder.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Gift cards and bonuses sales'; de='Geschenkkarten und Boni verkauf'; ru='Продажи по подарочным картам и бонусам'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
