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
	If Not IsBlankString(Text) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Текст '; en = 'Text '; de = 'Text '") + 
		TrimAll(Text) + 
		";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
								 TrimAll(Employee.Description) + 
								 ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Mitarbeiterengruppe '") + 
								 TrimAll(Employee.Description) + 
								 ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Department) Then
		If Not Department.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отдел '; en = 'Department '; de = 'Abteilung '") + 
								 TrimAll(Department.Description) + 
								 ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа отделов '; en = 'Departments folder '; de = 'Abteilungengruppe '") + 
								 TrimAll(Department.Description) + 
								 ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Client) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Клиент '; en = 'Client '; de = 'Kunde '") + 
								 TrimAll(Client.Description) + 
								 ";" + Chars.LF;
	EndIf;
	If Not IsBlankString(Status) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Статус '; en = 'Status '; de = 'Status '") + 
							 TrimAll(Status) + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(SMSTemplate) Then
		If Not SMSTemplate.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Шаблон СМС '; en = 'SMS template '; de = 'SMS-Vorlage '") + 
							";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа шаблонов СМС '; en = 'SMS templates folder '; de = 'SMS-Vorlagen-gruppe '") + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235959'));
	ReportBuilder.Parameters.Insert("qText", "%"+TrimAll(Text)+"%");
	ReportBuilder.Parameters.Insert("qTextIsBlank", IsBlankString(Text));
	ReportBuilder.Parameters.Insert("qClient", Client);
	ReportBuilder.Parameters.Insert("qIsClientEmpty", Not ValueIsFilled(Client));
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qIsEmployeeEmpty", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qDepartment", Department);
	ReportBuilder.Parameters.Insert("qIsDepartmentEmpty", Not ValueIsFilled(Department));
	ReportBuilder.Parameters.Insert("qStatus", Status);
	ReportBuilder.Parameters.Insert("qIsStatusEmpty", IsBlankString(Status));
	ReportBuilder.Parameters.Insert("qSMSTemplate", SMSTemplate);
	ReportBuilder.Parameters.Insert("qIsSMSTemplateEmpty", Not ValueIsFilled(SMSTemplate));
	
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
	|	SMSMessages.Period AS Period,
	|	SMSMessages.Phone,
	|	SMSMessages.Client,
	|	SMSMessages.Text,
	|	SMSMessages.Status,
	|	SMSMessages.SMSTemplate,
	|	SMSMessages.Cost AS Cost,
	|	SMSMessages.Quantity AS SegmentsQuantity,
	|	1 AS SMSQuantity
	|{SELECT
	|	Period,
	|	Phone,
	|	Client.*,
	|	SMSMessages.Employee.*,
	|	SMSMessages.Employee.Department.* AS Department,
	|	Text,
	|	Status,
	|	SMSTemplate.*,
	|	SMSMessages.MessageID,
	|	SMSMessages.Result,
	|	SMSMessages.Sender,
	|	SMSMessages.ClientDoc.*,
	|	(BEGINOFPERIOD(SMSMessages.Period, DAY)) AS SMSMessagesDate,
	|	(WEEK(SMSMessages.Period)) AS SMSMessagesWeek,
	|	(MONTH(SMSMessages.Period)) AS SMSMessagesMonth,
	|	(QUARTER(SMSMessages.Period)) AS SMSMessagesQuarter,
	|	(YEAR(SMSMessages.Period)) AS SMSMessagesYear,
	|	SMSMessages.DocumentStatus.* AS DocumentStatus,
	|	Cost,
	|	SegmentsQuantity,
	|	SMSQuantity}
	|FROM
	|	InformationRegister.SMSMessages AS SMSMessages
	|WHERE
	|	SMSMessages.Period >= &qPeriodFrom
	|	AND SMSMessages.Period <= &qPeriodTo
	|	AND (SMSMessages.Text LIKE &qText
	|			OR &qTextIsBlank)
	|	AND (SMSMessages.Client = &qClient
	|			OR &qIsClientEmpty)
	|	AND (SMSMessages.Employee IN HIERARCHY (&qEmployee)
	|			OR &qIsEmployeeEmpty)
	|	AND (SMSMessages.Employee.Department IN HIERARCHY (&qDepartment)
	|			OR &qIsDepartmentEmpty)
	|	AND (SMSMessages.Status = &qStatus
	|			OR &qIsStatusEmpty)
	|	AND (SMSMessages.SMSTemplate IN HIERARCHY (&qSMSTemplate)
	|			OR &qIsSMSTemplateEmpty)
	|{WHERE
	|	SMSMessages.Period,
	|	SMSMessages.Phone,
	|	SMSMessages.Text,
	|	SMSMessages.Cost AS Cost,
	|	SMSMessages.Quantity AS SegmentsQuantity,
	|	(1) AS SMSQuantity,
	|	SMSMessages.Status,
	|	SMSMessages.SMSTemplate.*,
	|	SMSMessages.Client.*,
	|	SMSMessages.Employee.*,
	|	SMSMessages.Employee.Department.* AS Department,
	|	SMSMessages.MessageID,
	|	SMSMessages.Result,
	|	SMSMessages.Sender,
	|	SMSMessages.ClientDoc.*,
	|	SMSMessages.DocumentStatus.*}
	|
	|ORDER BY
	|	Period
	|{ORDER BY
	|	Period,
	|	Phone,
	|	Text,
	|	Cost,
	|	SegmentsQuantity,
	|	SMSQuantity,
	|	Status,
	|	SMSTemplate.*,
	|	Client.*,
	|	SMSMessages.Employee.*,
	|	SMSMessages.Employee.Department.* AS Department,
	|	SMSMessages.MessageID,
	|	SMSMessages.Result,
	|	SMSMessages.Sender,
	|	SMSMessages.ClientDoc.*,
	|	SMSMessages.DocumentStatus.*}
	|TOTALS
	|	SUM(Cost),
	|	SUM(SegmentsQuantity),
	|	SUM(SMSQuantity)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Phone,
	|	Status,
	|	SMSTemplate.*,
	|	Client.*,
	|	SMSMessages.Employee.*,
	|	SMSMessages.Employee.Department.* AS Department,
	|	SMSMessages.Result,
	|	SMSMessages.Sender,
	|	SMSMessages.ClientDoc.*,
	|	SMSMessages.DocumentStatus.*,
	|	(BEGINOFPERIOD(SMSMessages.Period, DAY)) AS SMSMessagesDate,
	|	(WEEK(SMSMessages.Period)) AS SMSMessagesWeek,
	|	(MONTH(SMSMessages.Period)) AS SMSMessagesMonth,
	|	(QUARTER(SMSMessages.Period)) AS SMSMessagesQuarter,
	|	(YEAR(SMSMessages.Period)) AS SMSMessagesYear,
	|	SMSMessages.DocumentStatus.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='SMS being sent';ru='Отправленные СМС';de='Verschickte SMS'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
