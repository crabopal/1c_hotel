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
	// [NONE SO FAR]
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Внесены в систему c '; en = 'Registered from '; de = 'Registriert von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Внесены в систему по '; en = 'Registered to '; de = 'Registriert bis '") + 
		                     Format(cm0SecondShift(PeriodTo) + 59, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		If PeriodFrom <= PeriodTo Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Внесены в систему с '; en = 'Registered from '; de = 'Registriert von '") + 
			                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
								 NStr("ru = ' по '; en = ' to '; de = ' bis '") + 
			                     Format(cm0SecondShift(PeriodTo) + 59, "DF='dd.MM.yyyy HH:mm:ss'") + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru='Неправильно задан период!'; en='Period is wrong!'; de='Der Zeitraum wurde falsch eingetragen!'") + 
			                     ";" + Chars.LF;
		EndIf;
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
	If Tags.Count() > 0 Then
		vParamPresentation = vParamPresentation + NStr("de='Tags ';en='Tags ';ru='Теги '");
		For Each vTagsItem In Tags Do
			If Tags.IndexOf(vTagsItem) > 0 Then
				If TagsCheckMode Then
					vParamPresentation = vParamPresentation + NStr("en=' AND '; ru=' И '; de=' UND '");
				Else
					vParamPresentation = vParamPresentation + NStr("en=' OR '; ru=' ИЛИ '; de=' ODER '");
				EndIf;
			EndIf;
			vParamPresentation = vParamPresentation + TrimAll(vTagsItem.Value);
		EndDo;
		vParamPresentation = vParamPresentation + ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qTagsList", Tags);
	ReportBuilder.Parameters.Insert("qTagsCount", Tags.Count());
	ReportBuilder.Parameters.Insert("qTagsConditionAND", TagsCheckMode);
	ReportBuilder.Parameters.Insert("qPeriodFrom", cm0SecondShift(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), cm0SecondShift(PeriodTo) + 59, '39991231235959'));

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
	|	CustomerTags.Client AS Customer,
	|	COUNT(CustomerTags.Tag) AS TagsCount
	|INTO CustomersWithTags
	|FROM
	|	InformationRegister.ClientTags AS CustomerTags
	|WHERE
	|	CustomerTags.Tag IN(&qTagsList)
	|	AND CustomerTags.Client.CreateDate >= &qPeriodFrom
	|	AND CustomerTags.Client.CreateDate <= &qPeriodTo
	|	AND NOT CustomerTags.Client.DeletionMark
	|	AND CustomerTags.Client REFS Catalog.Customers
	|
	|GROUP BY
	|	CustomerTags.Client
	|
	|HAVING
	|	(NOT &qTagsConditionAND
	|			AND COUNT(CustomerTags.Tag) > 0
	|		OR &qTagsConditionAND
	|			AND COUNT(CustomerTags.Tag) = &qTagsCount)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReportCustomers.Customer AS Customer
	|INTO ReportCustomers
	|FROM
	|	(SELECT
	|		CustomersByTags.Ref AS Customer
	|	FROM
	|		Catalog.Customers AS CustomersByTags
	|			INNER JOIN CustomersWithTags AS CustomersWithTags
	|			ON CustomersByTags.Ref = CustomersWithTags.Customer
	|	WHERE
	|		&qTagsCount > 0
	|		AND CustomersByTags.CreateDate >= &qPeriodFrom
	|		AND CustomersByTags.CreateDate <= &qPeriodTo
	|		AND CustomersByTags.Ref IN HIERARCHY(&qCustomer)
	|		AND NOT CustomersByTags.DeletionMark
	|		AND NOT CustomersByTags.IsFolder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Customers.Ref
	|	FROM
	|		Catalog.Customers AS Customers
	|	WHERE
	|		&qTagsCount = 0
	|		AND Customers.CreateDate >= &qPeriodFrom
	|		AND Customers.CreateDate <= &qPeriodTo
	|		AND Customers.Ref IN HIERARCHY(&qCustomer)
	|		AND NOT Customers.DeletionMark
	|		AND NOT Customers.IsFolder) AS ReportCustomers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContactPersons.Customer AS Customer,
	|	ContactPersons.ContactPerson AS ContactPerson,
	|	ContactPersons.Client AS Client,
	|	ContactPersons.Phone1 AS Phone1,
	|	ContactPersons.Phone2 AS Phone2,
	|	ContactPersons.EMail AS EMail,
	|	ContactPersons.Position AS Position,
	|	ContactPersons.Customer.TagsPresentation AS CustomerTagsPresentation
	|{SELECT
	|	Customer.*,
	|	ContactPerson,
	|	Client.*,
	|	Phone1,
	|	Phone2,
	|	EMail,
	|	Position,
	|	CustomerTagsPresentation}
	|FROM
	|	(SELECT
	|		ReportCustomers.Customer AS Customer,
	|		ReportCustomers.Customer.ContactPerson AS ContactPerson,
	|		ReportCustomers.Customer.Client AS Client,
	|		ReportCustomers.Customer.Fax AS Phone1,
	|		ReportCustomers.Customer.Phone AS Phone2,
	|		ReportCustomers.Customer.EMail AS EMail,
	|		"""" AS Position
	|	FROM
	|		ReportCustomers AS ReportCustomers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerContacts.Ref,
	|		CustomerContacts.ContactPerson,
	|		CustomerContacts.Client,
	|		CustomerContacts.Phone,
	|		CustomerContacts.Phone2,
	|		CustomerContacts.EMail,
	|		CustomerContacts.Position
	|	FROM
	|		Catalog.Customers.ContactPersons AS CustomerContacts
	|			INNER JOIN ReportCustomers AS ReportCustomers
	|			ON (ReportCustomers.Customer = CustomerContacts.Ref)
	|				AND (NOT CustomerContacts.NotActive)) AS ContactPersons
	|{WHERE
	|	ContactPersons.Customer.*,
	|	ContactPersons.ContactPerson,
	|	ContactPersons.Client.*,
	|	ContactPersons.Phone1,
	|	ContactPersons.Phone2,
	|	ContactPersons.EMail,
	|	ContactPersons.Position,
	|	ContactPersons.Customer.TagsPresentation AS CustomerTagsPresentation}
	|
	|ORDER BY
	|	ContactPersons.Customer,
	|	ContactPersons.ContactPerson
	|{ORDER BY
	|	Customer.*,
	|	ContactPerson,
	|	Client.*,
	|	Phone1,
	|	Phone2,
	|	EMail,
	|	Position,
	|	CustomerTagsPresentation}
	|{TOTALS BY
	|	Customer.*,
	|	Client.*,
	|	ContactPerson,
	|	Phone1,
	|	Phone2,
	|	EMail,
	|	Position,
	|	CustomerTagsPresentation}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Customer contacts';de='Firma kontakten';ru='Контакты контрагентов'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
