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
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfYear(CurrentSessionDate()); // For beg. of year
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = CurrentSessionDate(); // Current date
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
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Period von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(DiscountType) Then
		If Not DiscountType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Тип скидки '; en = 'Discount type '; de = 'Rabatt-Typ '") + 
			                     TrimAll(DiscountType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа типов скидок '; en = 'Discount types folder '; de = 'Gruppe Rabatt-Typen '") + 
			                     TrimAll(DiscountType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(DiscountDimension) Then
		If Not DiscountDimension.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Измерение '; en = 'Dimension '; de = 'Dimension '") + 
			                     TrimAll(DiscountDimension.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа измерений '; en = 'Dimensions folder '; de = 'Gruppe Dimensionen '") + 
			                     TrimAll(DiscountDimension.Description) + 
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
	ReportBuilder.Parameters.Insert("qDiscountType", DiscountType);
	ReportBuilder.Parameters.Insert("qIsEmptyDiscountType", Not ValueIsFilled(DiscountType));
	ReportBuilder.Parameters.Insert("qDiscountDimension", DiscountDimension);
	ReportBuilder.Parameters.Insert("qIsEmptyDiscountDimension", Not ValueIsFilled(DiscountDimension));
	
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
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.DiscountType AS DiscountType,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.DiscountDimension AS DiscountDimension,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.Period AS Period,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.GuestGroup,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.ResourceOpeningBalance AS ResourceOpeningBalance,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.ResourceTurnover AS ResourceTurnover,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.ResourceClosingBalance AS ResourceClosingBalance,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.BonusOpeningBalance AS BonusOpeningBalance,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.BonusReceipt AS BonusReceipt,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.BonusExpense AS BonusExpense,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.BonusClosingBalance AS BonusClosingBalance
	|{SELECT
	|	DiscountType.*,
	|	DiscountDimension.*,
	|	Period,
	|	GuestGroup.*,
	|	ResourceOpeningBalance,
	|	ResourceTurnover,
	|	ResourceClosingBalance,
	|	BonusOpeningBalance,
	|	BonusReceipt,
	|	BonusExpense,
	|	BonusClosingBalance}
	|FROM
	|	AccumulationRegister.AccumulatingDiscountResources.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			(DiscountDimension IN HIERARCHY (&qDiscountDimension)
	|				OR &qIsEmptyDiscountDimension)
	|				AND (DiscountType IN HIERARCHY (&qDiscountType)
	|					OR &qIsEmptyDiscountType)) AS AccumulatingDiscountResourcesBalanceAndTurnovers
	|{WHERE
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.DiscountType.*,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.DiscountDimension.*,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.GuestGroup.*,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.BonusOpeningBalance,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.BonusReceipt,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.BonusExpense,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.BonusClosingBalance,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.ResourceOpeningBalance,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.ResourceTurnover,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.ResourceClosingBalance}
	|
	|ORDER BY
	|	DiscountType,
	|	DiscountDimension,
	|	Period,
	|	AccumulatingDiscountResourcesBalanceAndTurnovers.GuestGroup
	|{ORDER BY
	|	DiscountType.*,
	|	DiscountDimension.*,
	|	Period,
	|	GuestGroup.*,
	|	ResourceOpeningBalance,
	|	ResourceTurnover,
	|	ResourceClosingBalance,
	|	BonusOpeningBalance,
	|	BonusReceipt,
	|	BonusExpense,
	|	BonusClosingBalance}
	|TOTALS
	|	SUM(ResourceOpeningBalance),
	|	SUM(ResourceTurnover),
	|	SUM(ResourceClosingBalance),
	|	SUM(BonusOpeningBalance),
	|	SUM(BonusReceipt),
	|	SUM(BonusExpense),
	|	SUM(BonusClosingBalance)
	|BY
	|	DiscountType,
	|	DiscountDimension,
	|	Period
	|{TOTALS BY
	|	DiscountType.*,
	|	DiscountDimension.*,
	|	Period,
	|	GuestGroup.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Accumulating discount resources';RU='Ресурсы накопительных скидок';de='Ressourcen summarischer Preisnachlässe'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "ResourceOpeningBalance"  
	   Or pName = "BonusOpeningBalance" 
	   Or pName = "BonusReceipt" 
	   Or pName = "BonusExpense" 
	   Or pName = "BonusTurnover" 
	   Or pName = "BonusClosingBalance" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
