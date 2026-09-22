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
	// Nothing to initialize yet
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
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
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
								 TrimAll(Employee.Description) + 
								 ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Mitarbeitergruppe '") + 
								 TrimAll(Employee.Description) + 
								 ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Контрагент '; en = 'Customer '; de = 'Kunde '") + 
								 TrimAll(Customer.Description) + 
								 ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа контрагентов '; en = 'Customers folder '; de = 'Kunden '") + 
								 TrimAll(Customer.Description) + 
								 ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(CustomerType) Then
		If Not CustomerType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Тип контрагента '; en = 'Customer type '; de = 'Kunden typ '") + 
								 TrimAll(Customer.Description) + 
								 ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа типов контрагентов '; en = 'Customer types folder '; de = 'Kunden typen '") + 
								 TrimAll(CustomerType.Description) + 
								 ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(ContractType) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Тип договора '; en = 'Contract type '; de = 'Vertragsart '") + 
								 TrimAll(ContractType.Description) + 
								 ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), EndOfDay(PeriodTo), '39991231235959'));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qCompanyIsEmpty", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qCustomerType", CustomerType);
	ReportBuilder.Parameters.Insert("qCustomerTypeIsEmpty", Not ValueIsFilled(CustomerType));
	ReportBuilder.Parameters.Insert("qContractType", ContractType);
	ReportBuilder.Parameters.Insert("qContractTypeIsEmpty", Not ValueIsFilled(ContractType));
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qEmployeeIsEmpty", Not ValueIsFilled(Employee));
	
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
	|	Contracts.Code AS Code,
	|	Contracts.Date AS Date,
	|	Contracts.Owner AS Customer,
	|	Contracts.Owner.CustomerType AS CustomerType,
	|	Contracts.ContractType,
	|	Contracts.ValidFromDate,
	|	Contracts.ValidToDate,
	|	Contracts.Author,
	|	Contracts.Remarks,
	|	1 AS Counter
	|{SELECT
	|	Code,
	|	Date,
	|	Customer.*,
	|	CustomerType.*,
	|	ContractType.*,
	|	ValidFromDate,
	|	ValidToDate,
	|	Author.*,
	|	Remarks,
	|	Contracts.CreateDate AS CreateDate,
	|	Contracts.Description AS Description,
	|	Contracts.Ref.* AS Contract,
	|	Counter}
	|FROM
	|	Catalog.Contracts AS Contracts
	|WHERE
	|	NOT Contracts.DeletionMark
	|	AND Contracts.Date BETWEEN &qPeriodFrom AND &qPeriodTo
	|	AND (NOT &qCompanyIsEmpty
	|				AND Contracts.Company IN HIERARCHY (&qCompany)
	|			OR &qCompanyIsEmpty)
	|	AND (NOT &qCustomerIsEmpty
	|				AND Contracts.Owner IN HIERARCHY (&qCustomer)
	|			OR &qCustomerIsEmpty)
	|	AND (NOT &qCustomerTypeIsEmpty
	|				AND Contracts.Owner.CustomerType IN HIERARCHY (&qCustomerType)
	|			OR &qCustomerTypeIsEmpty)
	|	AND (NOT &qContractTypeIsEmpty
	|				AND Contracts.ContractType = &qContractType
	|			OR &qContractTypeIsEmpty)
	|	AND (NOT &qEmployeeIsEmpty
	|				AND Contracts.Author IN HIERARCHY (&qEmployee)
	|			OR &qEmployeeIsEmpty)
	|{WHERE
	|	Contracts.Code,
	|	Contracts.Description,
	|	Contracts.Owner.* AS Customer,
	|	Contracts.Owner.CustomerType.* AS CustomerType,
	|	Contracts.Date,
	|	Contracts.ContractType.*,
	|	Contracts.ValidFromDate,
	|	Contracts.ValidToDate,
	|	Contracts.Author.*,
	|	Contracts.CreateDate,
	|	Contracts.Remarks,
	|	Contracts.Ref.* AS Contract}
	|
	|ORDER BY
	|	Code,
	|	Date
	|{ORDER BY
	|	Code,
	|	Date,
	|	Customer.*,
	|	CustomerType.*,
	|	ContractType.*,
	|	ValidFromDate,
	|	ValidToDate,
	|	Author.*,
	|	Remarks,
	|	Contracts.CreateDate,
	|	Contracts.Description,
	|	Contracts.Ref.* AS Contract}
	|TOTALS
	|	SUM(Counter)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Customer.*,
	|	CustomerType.*,
	|	ContractType.*,
	|	Author.*,
	|	Contracts.Ref.* AS Contract}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("ru='Реестр договоров';de='Verträgen Register';en='Contracts register'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
