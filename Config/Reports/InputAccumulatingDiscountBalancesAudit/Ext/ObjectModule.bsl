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
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	
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
	|	InputAccumDiscBalances.GuestGroup AS GuestGroup,
	|	SUM(InputAccumDiscBalances.Resource) AS Resource,
	|	SUM(InputAccumDiscBalances.Bonus) AS Bonus,
	|	InputAccumDiscBalances.DiscountDimension AS DiscountDimension,
	|	InputAccumDiscBalances.Ref AS Document,
	|	InputAccumDiscBalances.Ref.DeletionMark AS DeletionMark,
	|	InputAccumDiscBalances.Ref.Date AS Date,
	|	InputAccumDiscBalances.Ref.Posted AS Posted,
	|	InputAccumDiscBalances.Ref.Author AS Author,
	|	InputAccumDiscBalances.Ref.Hotel AS Hotel,
	|	InputAccumDiscBalances.Ref.DiscountType AS DiscountType,
	|	InputAccumDiscBalances.Ref.ExternalCode AS ExternalCode,
	|	InputAccumDiscBalances.Ref.ChangeDate AS ChangeDate,
	|	InputAccumDiscBalances.Ref.IsChanged AS IsChanged,
	|	NestedSelect.Remarks AS Remarks,
	|	Payments.Ref AS BonusPayment,
	|	SUM(Payments.Sum) AS PaidBonusesSum
	|{SELECT
	|	GuestGroup.*,
	|	Resource,
	|	Bonus,
	|	DiscountDimension.*,
	|	Document.*,
	|	DeletionMark,
	|	Date,
	|	Posted,
	|	Author.*,
	|	Hotel.*,
	|	DiscountType.*,
	|	ExternalCode,
	|	ChangeDate,
	|	IsChanged,
	|	NestedSelect.Remarks,
	|	BonusPayment.*,
	|	PaidBonusesSum}
	|FROM
	|	Document.InputAccumulatingDiscountBalances.Balances AS InputAccumDiscBalances
	|		LEFT JOIN (SELECT
	|			CAST(InputAccumulatingDiscountBalances.Remarks AS STRING(100)) AS Remarks,
	|			InputAccumulatingDiscountBalances.Ref AS Ref
	|		FROM
	|			Document.InputAccumulatingDiscountBalances AS InputAccumulatingDiscountBalances
	|		WHERE
	|			InputAccumulatingDiscountBalances.Date >= &qPeriodFrom
	|			AND InputAccumulatingDiscountBalances.Date <= &qPeriodTo
	|			AND (InputAccumulatingDiscountBalances.Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)) AS NestedSelect
	|		ON InputAccumDiscBalances.Ref = NestedSelect.Ref
	|		LEFT JOIN Document.Payment AS Payments
	|		ON InputAccumDiscBalances.GuestGroup = Payments.GuestGroup
	|			AND (Payments.PaymentMethod.IsByBonuses)
	|WHERE
	|	(InputAccumDiscBalances.Ref.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND InputAccumDiscBalances.Ref.Date >= &qPeriodFrom
	|	AND InputAccumDiscBalances.Ref.Date <= &qPeriodTo
	|
	|GROUP BY
	|	InputAccumDiscBalances.Ref,
	|	InputAccumDiscBalances.DiscountDimension,
	|	InputAccumDiscBalances.GuestGroup,
	|	InputAccumDiscBalances.Ref.DeletionMark,
	|	InputAccumDiscBalances.Ref.Date,
	|	InputAccumDiscBalances.Ref.Posted,
	|	InputAccumDiscBalances.Ref.Author,
	|	InputAccumDiscBalances.Ref.Hotel,
	|	InputAccumDiscBalances.Ref.DiscountType,
	|	InputAccumDiscBalances.Ref.ExternalCode,
	|	InputAccumDiscBalances.Ref.ChangeDate,
	|	InputAccumDiscBalances.Ref.IsChanged,
	|	NestedSelect.Remarks,
	|	Payments.Ref
	|TOTALS BY
	|	OVERALL
	|{TOTALS BY
	|	GuestGroup.*,
	|	Resource,
	|	Bonus,
	|	DiscountDimension.*,
	|	Document.*,
	|	DeletionMark,
	|	Date,
	|	Posted,
	|	Author.*,
	|	Hotel.*,
	|	DiscountType.*,
	|	ExternalCode,
	|	ChangeDate,
	|	IsChanged,
	|	PaidBonusesSum,
	|	BonusPayment.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("ru='Аудит ввода нач. остатков по нак. скидкам и бонусам';de='Prüfe den Input von kumulierenden Rabattsalden';en='Audit input accumulating discount balances'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
