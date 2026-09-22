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
	If Not ValueIsFilled(AccountingDate) Then
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
			AccountingDate = BegOfDay(Hotel.AccountingDate) - 24*3600;
		Else
			AccountingDate = BegOfDay(CurrentSessionDate()) - 24*3600;
		EndIf;
	EndIf;
	AccountGroup = Catalogs.AccountGroups.Income;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(AccountingDate) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(AccountingDate, "DF='dd.MM.yyyy'") + 
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
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Company ';ru='Фирма ';de='Kompanie '") + 
			                     TrimAll(Company) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Companies folder ';ru='Папка фирм ';de='Kompaniesgruppe '") + 
			                     TrimAll(Company) + 
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
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qCompanyIsEmpty", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(AccountingDate));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(AccountingDate));
	ReportBuilder.Parameters.Insert("qMonthPeriodFrom", BegOfMonth(AccountingDate));
	ReportBuilder.Parameters.Insert("qYearPeriodFrom", BegOfYear(AccountingDate));
	ReportBuilder.Parameters.Insert("qAccount", Account);
	ReportBuilder.Parameters.Insert("qAccountIsFilled", ValueIsFilled(Account));
	ReportBuilder.Parameters.Insert("qAccountType", AccountType);
	ReportBuilder.Parameters.Insert("qAccountTypeIsFilled", ValueIsFilled(AccountType));
	ReportBuilder.Parameters.Insert("qAccountGroup", AccountGroup);
	ReportBuilder.Parameters.Insert("qAccountGroupIsFilled", ValueIsFilled(AccountGroup));
	ReportBuilder.Parameters.Insert("qDepartmentCode", DepartmentCode);
	ReportBuilder.Parameters.Insert("qDepartmentCodeIsFilled", ValueIsFilled(DepartmentCode));
	
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
	|	PostingsFODayTurnovers.Account AS Account,
	|	PostingsFODayTurnovers.AmountTurnoverCr - PostingsFODayTurnovers.AmountTurnoverDr AS Amount
	|INTO DayTurnovers
	|FROM
	|	AccountingRegister.PostingsFO.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			(NOT &qAccountIsFilled
	|				OR &qAccountIsFilled
	|					AND Account = &qAccount)
	|				AND (NOT &qAccountTypeIsFilled
	|					OR &qAccountTypeIsFilled
	|						AND Account.AccountType IN HIERARCHY (&qAccountType))
	|				AND (NOT &qAccountGroupIsFilled
	|					OR &qAccountGroupIsFilled
	|						AND Account.AccountGroup IN HIERARCHY (&qAccountGroup))
	|				AND (NOT &qDepartmentCodeIsFilled
	|					OR &qDepartmentCodeIsFilled
	|						AND Account.Department = &qDepartmentCode),
	|			,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (&qCompanyIsEmpty
	|					OR NOT &qCompanyIsEmpty
	|						AND Company IN HIERARCHY (&qCompany))) AS PostingsFODayTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PostingsFOMonthTurnovers.Account AS Account,
	|	PostingsFOMonthTurnovers.AmountTurnoverCr - PostingsFOMonthTurnovers.AmountTurnoverDr AS Amount
	|INTO MonthTurnovers
	|FROM
	|	AccountingRegister.PostingsFO.Turnovers(
	|			&qMonthPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			(NOT &qAccountIsFilled
	|				OR &qAccountIsFilled
	|					AND Account = &qAccount)
	|				AND (NOT &qAccountTypeIsFilled
	|					OR &qAccountTypeIsFilled
	|						AND Account.AccountType IN HIERARCHY (&qAccountType))
	|				AND (NOT &qAccountGroupIsFilled
	|					OR &qAccountGroupIsFilled
	|						AND Account.AccountGroup IN HIERARCHY (&qAccountGroup))
	|				AND (NOT &qDepartmentCodeIsFilled
	|					OR &qDepartmentCodeIsFilled
	|						AND Account.Department = &qDepartmentCode),
	|			,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (&qCompanyIsEmpty
	|					OR NOT &qCompanyIsEmpty
	|						AND Company IN HIERARCHY (&qCompany))) AS PostingsFOMonthTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PostingsFOYearTurnovers.Account AS Account,
	|	PostingsFOYearTurnovers.AmountTurnoverCr - PostingsFOYearTurnovers.AmountTurnoverDr AS Amount
	|INTO YearTurnovers
	|FROM
	|	AccountingRegister.PostingsFO.Turnovers(
	|			&qYearPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			(NOT &qAccountIsFilled
	|				OR &qAccountIsFilled
	|					AND Account = &qAccount)
	|				AND (NOT &qAccountTypeIsFilled
	|					OR &qAccountTypeIsFilled
	|						AND Account.AccountType IN HIERARCHY (&qAccountType))
	|				AND (NOT &qAccountGroupIsFilled
	|					OR &qAccountGroupIsFilled
	|						AND Account.AccountGroup IN HIERARCHY (&qAccountGroup))
	|				AND (NOT &qDepartmentCodeIsFilled
	|					OR &qDepartmentCodeIsFilled
	|						AND Account.Department = &qDepartmentCode),
	|			,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (&qCompanyIsEmpty
	|					OR NOT &qCompanyIsEmpty
	|						AND Company IN HIERARCHY (&qCompany))) AS PostingsFOYearTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllTurnovers.Account AS Account,
	|	SUM(AllTurnovers.Amount) AS Amount,
	|	SUM(AllTurnovers.MonthAmount) AS MonthAmount,
	|	SUM(AllTurnovers.YearAmount) AS YearAmount
	|INTO AllTurnovers
	|FROM
	|	(SELECT
	|		DayTurnovers.Account AS Account,
	|		DayTurnovers.Amount AS Amount,
	|		0 AS MonthAmount,
	|		0 AS YearAmount
	|	FROM
	|		DayTurnovers AS DayTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		MonthTurnovers.Account,
	|		0,
	|		MonthTurnovers.Amount,
	|		0
	|	FROM
	|		MonthTurnovers AS MonthTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		YearTurnovers.Account,
	|		0,
	|		0,
	|		YearTurnovers.Amount
	|	FROM
	|		YearTurnovers AS YearTurnovers) AS AllTurnovers
	|
	|GROUP BY
	|	AllTurnovers.Account
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PostingsFOTurnovers.Account.Department AS DepartmentCode,
	|	PostingsFOTurnovers.Account.DepartmentOrder AS DepartmentOrder,
	|	PostingsFOTurnovers.Account AS Account,
	|	PostingsFOTurnovers.Account.Description AS AccountDescription,
	|	PostingsFOTurnovers.Account.AccountType AS AccountType,
	|	PostingsFOTurnovers.Account.AccountGroup AS AccountGroup,
	|	PostingsFOTurnovers.Amount AS Amount,
	|	PostingsFOTurnovers.MonthAmount AS MonthAmount,
	|	PostingsFOTurnovers.YearAmount AS YearAmount
	|{SELECT
	|	DepartmentCode.* AS DepartmentCode,
	|	DepartmentOrder AS DepartmentOrder,
	|	Account.* AS Account,
	|	AccountDescription AS AccountDescription,
	|	AccountType.* AS AccountType,
	|	AccountGroup.* AS AccountGroup,
	|	Amount AS Amount,
	|	MonthAmount AS MonthAmount,
	|	YearAmount AS YearAmount}
	|FROM
	|	AllTurnovers AS PostingsFOTurnovers
	|{WHERE
	|	PostingsFOTurnovers.Account.Department.* AS DepartmentCode,
	|	PostingsFOTurnovers.Account.DepartmentOrder AS DepartmentOrder,
	|	PostingsFOTurnovers.Account.* AS Account,
	|	PostingsFOTurnovers.Account.Description AS AccountDescription,
	|	PostingsFOTurnovers.Account.AccountType.* AS AccountType,
	|	PostingsFOTurnovers.Account.AccountGroup.* AS AccountGroup,
	|	PostingsFOTurnovers.Amount AS Amount,
	|	PostingsFOTurnovers.MonthAmount AS MonthAmount,
	|	PostingsFOTurnovers.YearAmount AS YearAmount}
	|{ORDER BY
	|	DepartmentCode.* AS DepartmentCode,
	|	DepartmentOrder AS DepartmentOrder,
	|	Account.* AS Account,
	|	AccountDescription AS AccountDescription,
	|	AccountType.* AS AccountType,
	|	AccountGroup.* AS AccountGroup,
	|	Amount AS Amount,
	|	MonthAmount AS MonthAmount,
	|	YearAmount AS YearAmount}
	|TOTALS
	|	SUM(Amount),
	|	SUM(MonthAmount),
	|	SUM(YearAmount)
	|BY
	|	OVERALL,
	|	DepartmentCode AS DepartmentCode
	|{TOTALS BY
	|	DepartmentCode.* AS DepartmentCode,
	|	DepartmentOrder AS DepartmentOrder,
	|	Account.* AS Account,
	|	AccountType.* AS AccountType,
	|	AccountGroup.* AS AccountGroup}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Income analysis';ru='Анализ доходов';de='Einkommensanalyse'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
