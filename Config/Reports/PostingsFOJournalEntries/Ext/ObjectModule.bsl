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
	If ValueIsFilled(AccountGroup) Then
		If Not AccountGroup.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Account group ';ru='Группа счетов ';de='Kontogruppe '") + 
			                     TrimAll(AccountGroup) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Account groups folder ';ru='Папка групп счетов ';de='Kontogruppen Ordner '") + 
			                     TrimAll(AccountGroup) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(AccountType) Then
		If Not AccountType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Account type ';ru='Тип счета ';de='Kontotyp '") + 
			                     TrimAll(AccountType) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Account types folder ';ru='Папка типов счетов ';de='Kontotypen Ordner '") + 
			                     TrimAll(AccountType) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(DepartmentCode) Then
		vParamPresentation = vParamPresentation + NStr("en='Department code ';ru='Номенклатурная группа ';de='Abteilung-code '") + 
		                     TrimAll(DepartmentCode) + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Account) Then
		vParamPresentation = vParamPresentation + NStr("en='Account ';ru='Счет ';de='Konto '") + 
		                     TrimAll(Account) + 
		                     ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qAccount", Account);
	ReportBuilder.Parameters.Insert("qAccountIsFilled", ValueIsFilled(Account));
	ReportBuilder.Parameters.Insert("qAccountType", AccountType);
	ReportBuilder.Parameters.Insert("qAccountTypeIsFilled", ValueIsFilled(AccountType));
	ReportBuilder.Parameters.Insert("qAccountGroup", AccountGroup);
	ReportBuilder.Parameters.Insert("qAccountGroupIsFilled", ValueIsFilled(AccountGroup));
	ReportBuilder.Parameters.Insert("qDepartmentCode", DepartmentCode);
	ReportBuilder.Parameters.Insert("qDepartmentCodeIsFilled", ValueIsFilled(DepartmentCode));
	ReportBuilder.Parameters.Insert("qGuestLedger", ChartsOfAccounts.ChartOfAccountsFO.GuestLedger);
	ReportBuilder.Parameters.Insert("qCompactView", CompactView);
	ReportBuilder.Parameters.Insert("qShowIncomeAccountsAmountWithVAT", ShowIncomeAccountsAmountWithVAT);
	
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
	|	BEGINOFPERIOD(PostingsFORecordsWithExtDimensions.Period, DAY) AS Period,
	|	PostingsFORecordsWithExtDimensions.RecordType AS RecordType,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN 0
	|		ELSE PostingsFORecordsWithExtDimensions.LineNumber
	|	END AS LineNumber,
	|	PostingsFORecordsWithExtDimensions.Account AS Account,
	|	PostingsFORecordsWithExtDimensions.Account.Description AS AccountName,
	|	PostingsFORecordsWithExtDimensions.CorrAccount AS CorrAccount,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.ExtDimension1
	|	END AS Folio,
	|	PostingsFORecordsWithExtDimensions.Description AS PostingDescription,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.POSTicket
	|	END AS POSTicket,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.Recorder
	|	END AS Recorder,
	|	PostingsFORecordsWithExtDimensions.AccountType AS AccountType,
	|	PostingsFORecordsWithExtDimensions.AccountGroup AS AccountGroup,
	|	PostingsFORecordsWithExtDimensions.ServiceType AS ServiceType,
	|	PostingsFORecordsWithExtDimensions.Service AS Service,
	|	PostingsFORecordsWithExtDimensions.DiscountType AS DiscountType,
	|	PostingsFORecordsWithExtDimensions.Department AS DepartmentCode,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.Room
	|	END AS Room,
	|	PostingsFORecordsWithExtDimensions.FODate AS FODate,
	|	PostingsFORecordsWithExtDimensions.Days AS Days,
	|	PostingsFORecordsWithExtDimensions.ServiceDate AS ServiceDate,
	|	PostingsFORecordsWithExtDimensions.Invoice AS Invoice,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.Resource
	|	END AS Resource,
	|	PostingsFORecordsWithExtDimensions.Discount AS Discount,
	|	PostingsFORecordsWithExtDimensions.DiscountAmount AS DiscountAmount,
	|	PostingsFORecordsWithExtDimensions.PaymentMethod AS PaymentMethod,
	|	PostingsFORecordsWithExtDimensions.AccountingCustomer AS AccountingCustomer,
	|	PostingsFORecordsWithExtDimensions.Company AS Company,
	|	PostingsFORecordsWithExtDimensions.Hotel AS Hotel,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.Author
	|	END AS Author,
	|	PostingsFORecordsWithExtDimensions.VATRate AS VATRate,
	|	SUM(PostingsFORecordsWithExtDimensions.VATAmount) AS VATAmount,
	|	SUM(PostingsFORecordsWithExtDimensions.Amount) AS Amount,
	|	SUM(CASE
	|			WHEN PostingsFORecordsWithExtDimensions.RecordType = VALUE(AccountingRecordType.Credit)
	|					AND PostingsFORecordsWithExtDimensions.Account.AccountGroup = VALUE(Catalog.AccountGroups.Income)
	|					AND &qShowIncomeAccountsAmountWithVAT
	|				THEN PostingsFORecordsWithExtDimensions.Amount + PostingsFORecordsWithExtDimensions.VATAmount
	|			WHEN PostingsFORecordsWithExtDimensions.RecordType = VALUE(AccountingRecordType.Credit)
	|					AND PostingsFORecordsWithExtDimensions.Account.AccountGroup = VALUE(Catalog.AccountGroups.Income)
	|					AND NOT &qShowIncomeAccountsAmountWithVAT
	|				THEN PostingsFORecordsWithExtDimensions.Amount
	|			WHEN PostingsFORecordsWithExtDimensions.RecordType = VALUE(AccountingRecordType.Credit)
	|					AND PostingsFORecordsWithExtDimensions.Account.AccountGroup <> VALUE(Catalog.AccountGroups.Income)
	|				THEN PostingsFORecordsWithExtDimensions.Amount
	|			ELSE 0
	|		END) AS AmountCr,
	|	SUM(CASE
	|			WHEN PostingsFORecordsWithExtDimensions.RecordType = VALUE(AccountingRecordType.Debit)
	|				THEN PostingsFORecordsWithExtDimensions.Amount
	|			ELSE 0
	|		END) AS AmountDt,
	|	SUM(PostingsFORecordsWithExtDimensions.GrosAmount) AS GrosAmount
	|INTO PostingsFORecordsWithExtDimensions
	|FROM
	|	AccountingRegister.PostingsFO.RecordsWithExtDimensions(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (NOT &qAccountIsFilled
	|					OR &qAccountIsFilled
	|						AND Account = &qAccount)
	|				AND (NOT &qAccountTypeIsFilled
	|					OR &qAccountTypeIsFilled
	|						AND AccountType IN HIERARCHY (&qAccountType))
	|				AND (NOT &qAccountGroupIsFilled
	|					OR &qAccountGroupIsFilled
	|						AND AccountGroup IN HIERARCHY (&qAccountGroup))
	|				AND (NOT &qDepartmentCodeIsFilled
	|					OR &qDepartmentCodeIsFilled
	|						AND Department = &qDepartmentCode)
	|				AND Active,
	|			(Recorder.PointInTime, LineNumber),
	|			) AS PostingsFORecordsWithExtDimensions
	|		LEFT JOIN Document.Order AS Orders
	|		ON (PostingsFORecordsWithExtDimensions.Recorder = Orders.Charge
	|				OR (CAST(ISNULL(PostingsFORecordsWithExtDimensions.Recorder.OrderNumber, """") AS STRING(36))) <> """"
	|					AND ((CAST(ISNULL(PostingsFORecordsWithExtDimensions.Recorder.OrderNumber, """") AS STRING(36))) = (CAST(Orders.Remarks AS STRING(36)))
	|						OR (CAST(ISNULL(PostingsFORecordsWithExtDimensions.Recorder.OrderNumber, """") AS STRING(36))) = (CAST(Orders.ExternalCode AS STRING(36))))
	|					AND Orders.Posted)
	|
	|GROUP BY
	|	BEGINOFPERIOD(PostingsFORecordsWithExtDimensions.Period, DAY),
	|	PostingsFORecordsWithExtDimensions.RecordType,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN 0
	|		ELSE PostingsFORecordsWithExtDimensions.LineNumber
	|	END,
	|	PostingsFORecordsWithExtDimensions.Account,
	|	PostingsFORecordsWithExtDimensions.Account.Description,
	|	PostingsFORecordsWithExtDimensions.CorrAccount,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.ExtDimension1
	|	END,
	|	PostingsFORecordsWithExtDimensions.Description,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.POSTicket
	|	END,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.Recorder
	|	END,
	|	PostingsFORecordsWithExtDimensions.AccountType,
	|	PostingsFORecordsWithExtDimensions.AccountGroup,
	|	PostingsFORecordsWithExtDimensions.ServiceType,
	|	PostingsFORecordsWithExtDimensions.Service,
	|	PostingsFORecordsWithExtDimensions.DiscountType,
	|	PostingsFORecordsWithExtDimensions.Department,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.Room
	|	END,
	|	PostingsFORecordsWithExtDimensions.FODate,
	|	PostingsFORecordsWithExtDimensions.Days,
	|	PostingsFORecordsWithExtDimensions.ServiceDate,
	|	PostingsFORecordsWithExtDimensions.Invoice,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.Resource
	|	END,
	|	PostingsFORecordsWithExtDimensions.Discount,
	|	PostingsFORecordsWithExtDimensions.DiscountAmount,
	|	PostingsFORecordsWithExtDimensions.PaymentMethod,
	|	PostingsFORecordsWithExtDimensions.AccountingCustomer,
	|	PostingsFORecordsWithExtDimensions.Company,
	|	PostingsFORecordsWithExtDimensions.Hotel,
	|	CASE
	|		WHEN &qCompactView
	|				AND Orders.OrderPaymentType = VALUE(Enum.OrderPaymentType.Cash)
	|			THEN NULL
	|		ELSE PostingsFORecordsWithExtDimensions.Author
	|	END,
	|	PostingsFORecordsWithExtDimensions.VATRate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PostingsFORecordsWithExtDimensions.Period AS Period,
	|	PostingsFORecordsWithExtDimensions.RecordType AS RecordType,
	|	PostingsFORecordsWithExtDimensions.LineNumber AS LineNumber,
	|	PostingsFORecordsWithExtDimensions.Account AS Account,
	|	PostingsFORecordsWithExtDimensions.AccountName AS AccountName,
	|	PostingsFORecordsWithExtDimensions.CorrAccount AS CorrAccount,
	|	PostingsFORecordsWithExtDimensions.Folio AS Folio,
	|	PostingsFORecordsWithExtDimensions.PostingDescription AS PostingDescription,
	|	PostingsFORecordsWithExtDimensions.POSTicket AS POSTicket,
	|	PostingsFORecordsWithExtDimensions.Recorder AS Recorder,
	|	PostingsFORecordsWithExtDimensions.AccountType AS AccountType,
	|	PostingsFORecordsWithExtDimensions.AccountGroup AS AccountGroup,
	|	PostingsFORecordsWithExtDimensions.ServiceType AS ServiceType,
	|	PostingsFORecordsWithExtDimensions.Service AS Service,
	|	PostingsFORecordsWithExtDimensions.DiscountType AS DiscountType,
	|	PostingsFORecordsWithExtDimensions.DepartmentCode AS DepartmentCode,
	|	PostingsFORecordsWithExtDimensions.Room AS Room,
	|	PostingsFORecordsWithExtDimensions.FODate AS FODate,
	|	PostingsFORecordsWithExtDimensions.Days AS Days,
	|	PostingsFORecordsWithExtDimensions.ServiceDate AS ServiceDate,
	|	PostingsFORecordsWithExtDimensions.Invoice AS Invoice,
	|	PostingsFORecordsWithExtDimensions.Resource AS Resource,
	|	PostingsFORecordsWithExtDimensions.Discount AS Discount,
	|	PostingsFORecordsWithExtDimensions.DiscountAmount AS DiscountAmount,
	|	PostingsFORecordsWithExtDimensions.PaymentMethod AS PaymentMethod,
	|	PostingsFORecordsWithExtDimensions.AccountingCustomer AS AccountingCustomer,
	|	PostingsFORecordsWithExtDimensions.Company AS Company,
	|	PostingsFORecordsWithExtDimensions.Hotel AS Hotel,
	|	PostingsFORecordsWithExtDimensions.Author AS Author,
	|	PostingsFORecordsWithExtDimensions.VATRate AS VATRate,
	|	PostingsFORecordsWithExtDimensions.VATAmount AS VATAmount,
	|	PostingsFORecordsWithExtDimensions.Amount AS Amount,
	|	PostingsFORecordsWithExtDimensions.AmountCr AS AmountCr,
	|	PostingsFORecordsWithExtDimensions.AmountDt AS AmountDt,
	|	PostingsFORecordsWithExtDimensions.GrosAmount AS GrosAmount
	|{SELECT
	|	Period AS Period,
	|	RecordType AS RecordType,
	|	LineNumber AS LineNumber,
	|	Account.* AS Account,
	|	AccountName AS AccountName,
	|	CorrAccount.* AS CorrAccount,
	|	Folio.* AS Folio,
	|	PostingDescription AS PostingDescription,
	|	POSTicket AS POSTicket,
	|	Recorder.* AS Recorder,
	|	Service.* AS Service,
	|	Room.* AS Room,
	|	AccountType.* AS AccountType,
	|	AccountGroup.* AS AccountGroup,
	|	ServiceType.* AS ServiceType,
	|	DiscountType.* AS DiscountType,
	|	DepartmentCode.* AS DepartmentCode,
	|	FODate AS FODate,
	|	Days AS Days,
	|	ServiceDate AS ServiceDate,
	|	Invoice.* AS Invoice,
	|	VATRate.* AS VATRate,
	|	VATAmount AS VATAmount,
	|	Amount AS Amount,
	|	AmountCr AS AmountCr,
	|	AmountDt AS AmountDt,
	|	GrosAmount AS GrosAmount,
	|	Resource.* AS Resource,
	|	Discount AS Discount,
	|	DiscountAmount AS DiscountAmount,
	|	PaymentMethod.* AS PaymentMethod,
	|	AccountingCustomer.* AS AccountingCustomer,
	|	Company.* AS Company,
	|	Hotel.* AS Hotel,
	|	Author.* AS Author}
	|FROM
	|	PostingsFORecordsWithExtDimensions AS PostingsFORecordsWithExtDimensions
	|{WHERE
	|	PostingsFORecordsWithExtDimensions.Period,
	|	PostingsFORecordsWithExtDimensions.Recorder.*,
	|	PostingsFORecordsWithExtDimensions.LineNumber,
	|	PostingsFORecordsWithExtDimensions.Account.*,
	|	PostingsFORecordsWithExtDimensions.AccountName AS AccountName,
	|	PostingsFORecordsWithExtDimensions.Folio.* AS Folio,
	|	PostingsFORecordsWithExtDimensions.Hotel.*,
	|	PostingsFORecordsWithExtDimensions.Company.*,
	|	PostingsFORecordsWithExtDimensions.CorrAccount.*,
	|	PostingsFORecordsWithExtDimensions.Amount,
	|	PostingsFORecordsWithExtDimensions.GrosAmount,
	|	PostingsFORecordsWithExtDimensions.POSTicket,
	|	PostingsFORecordsWithExtDimensions.AccountGroup.*,
	|	PostingsFORecordsWithExtDimensions.ServiceType.*,
	|	PostingsFORecordsWithExtDimensions.DiscountType.*,
	|	PostingsFORecordsWithExtDimensions.AccountType.*,
	|	PostingsFORecordsWithExtDimensions.DepartmentCode.* AS DepartmentCode,
	|	PostingsFORecordsWithExtDimensions.Room.*,
	|	PostingsFORecordsWithExtDimensions.Resource.*,
	|	PostingsFORecordsWithExtDimensions.FODate,
	|	PostingsFORecordsWithExtDimensions.Days,
	|	PostingsFORecordsWithExtDimensions.ServiceDate,
	|	PostingsFORecordsWithExtDimensions.PostingDescription AS PostingDescription,
	|	PostingsFORecordsWithExtDimensions.Discount,
	|	PostingsFORecordsWithExtDimensions.DiscountAmount,
	|	PostingsFORecordsWithExtDimensions.Invoice.*,
	|	PostingsFORecordsWithExtDimensions.Service.*,
	|	PostingsFORecordsWithExtDimensions.PaymentMethod.*,
	|	PostingsFORecordsWithExtDimensions.AccountingCustomer.*,
	|	PostingsFORecordsWithExtDimensions.VATRate.*,
	|	PostingsFORecordsWithExtDimensions.VATAmount,
	|	PostingsFORecordsWithExtDimensions.Author.*,
	|	PostingsFORecordsWithExtDimensions.RecordType}
	|{ORDER BY
	|	Period AS Period,
	|	RecordType AS RecordType,
	|	LineNumber AS LineNumber,
	|	Account.* AS Account,
	|	AccountName AS AccountName,
	|	CorrAccount.* AS CorrAccount,
	|	Folio.* AS Folio,
	|	Amount AS Amount,
	|	GrosAmount AS GrosAmount,
	|	PostingDescription AS PostingDescription,
	|	POSTicket AS POSTicket,
	|	Recorder.* AS Recorder,
	|	AccountType.* AS AccountType,
	|	AccountGroup.* AS AccountGroup,
	|	ServiceType.* AS ServiceType,
	|	Service.* AS Service,
	|	DiscountType.* AS DiscountType,
	|	DepartmentCode.* AS DepartmentCode,
	|	Room.* AS Room,
	|	FODate AS FODate,
	|	Days AS Days,
	|	ServiceDate AS ServiceDate,
	|	Invoice.* AS Invoice,
	|	VATRate.* AS VATRate,
	|	VATAmount AS VATAmount,
	|	Resource.*,
	|	PaymentMethod.*,
	|	AccountingCustomer.*,
	|	Discount,
	|	DiscountAmount,
	|	Company.*,
	|	Hotel.*,
	|	Author.*}
	|TOTALS
	|	SUM(Amount),
	|	SUM(AmountCr),
	|	SUM(AmountDt)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Period AS Period,
	|	RecordType AS RecordType,
	|	Account.* AS Account,
	|	AccountName AS AccountName,
	|	CorrAccount.* AS CorrAccount,
	|	Folio.* AS Folio,
	|	POSTicket AS POSTicket,
	|	Recorder.* AS Recorder,
	|	AccountType.* AS AccountType,
	|	AccountGroup.* AS AccountGroup,
	|	ServiceType.* AS ServiceType,
	|	Service.* AS Service,
	|	DiscountType.* AS DiscountType,
	|	DepartmentCode.* AS DepartmentCode,
	|	Room.* AS Room,
	|	FODate AS FODate,
	|	Days AS Days,
	|	ServiceDate AS ServiceDate,
	|	Invoice.* AS Invoice,
	|	VATRate.* AS VATRate,
	|	Resource.*,
	|	PaymentMethod.*,
	|	AccountingCustomer.*,
	|	Discount,
	|	Company.*,
	|	Hotel.*,
	|	Author.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Journal entries';ru='Реестр проводок';de='Journaleinträge'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
