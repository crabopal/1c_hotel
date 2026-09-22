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
		PeriodFrom = '20000101';
		PeriodTo = EndOfDay(CurrentSessionDate());
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
	If ValueIsFilled(DiscountType) Then
		If Not DiscountType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Тип скидки '; en = 'Discount type '; de = 'Rabatttyp '") + 
			                     TrimAll(DiscountType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа типов скидок '; en = 'Discount types folder '; de = 'Rabatttypgruppe '") + 
			                     TrimAll(DiscountType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(ClientType) Then
		If Not ClientType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Client type ';ru='Тип клиента ';de='Kundentyp '") + 
			                     TrimAll(ClientType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа типов клиентов '; en = 'Client types folder '; de = 'Kundentypgruppe '") + 
			                     TrimAll(ClientType.Description) + 
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
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qDiscountType", DiscountType);
	ReportBuilder.Parameters.Insert("qIsEmptyDiscountType", Not ValueIsFilled(DiscountType));
	ReportBuilder.Parameters.Insert("qClientType", ClientType);
	ReportBuilder.Parameters.Insert("qIsEmptyClientType", Not ValueIsFilled(ClientType));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');

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
	|	DiscountCards.Ref AS DiscountCard,
	|	DiscountCards.Identifier AS Identifier,
	|	DiscountCards.Client AS Client,
	|	DiscountCards.DiscountType AS DiscountType,
	|	DiscountCards.ClientType AS ClientType,
	|	DiscountCards.ValidFrom AS ValidFrom,
	|	DiscountCards.ValidTo AS ValidTo,
	|	DiscountCards.TurnOffAutomaticDiscounts AS TurnOffAutomaticDiscounts,
	|	DiscountCards.IsBlocked AS IsBlocked,
	|	DiscountCards.Remarks AS Remarks,
	|	1 AS CardsCount
	|{SELECT
	|	DiscountCard.* AS DiscountCard,
	|	Identifier AS Identifier,
	|	Client.* AS Client,
	|	DiscountCards.Client.FullName AS ClientFullName,
	|	DiscountCards.Client.DateOfBirth AS ClientDateOfBirth,
	|	DiscountCards.Client.Phone AS ClientPhone,
	|	DiscountCards.Client.Fax AS ClientFax,
	|	DiscountCards.Client.EMail AS ClientEMail,
	|	DiscountType.* AS DiscountType,
	|	ClientType.* AS ClientType,
	|	ValidFrom AS ValidFrom,
	|	ValidTo AS ValidTo,
	|	TurnOffAutomaticDiscounts AS TurnOffAutomaticDiscounts,
	|	IsBlocked AS IsBlocked,
	|	Remarks AS Remarks,
	|	CardsCount}
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	(NOT DiscountCards.DeletionMark
	|				AND (NOT &qIsEmptyDiscountType
	|						AND DiscountCards.DiscountType IN HIERARCHY (&qDiscountType)
	|					OR &qIsEmptyDiscountType)
	|				AND (NOT &qIsEmptyClientType
	|						AND DiscountCards.ClientType IN HIERARCHY (&qClientType)
	|					OR &qIsEmptyClientType)
	|				AND DiscountCards.ValidFrom <> &qEmptyDate
	|				AND DiscountCards.ValidFrom < &qPeriodTo
	|			OR DiscountCards.ValidFrom = &qEmptyDate
	|				AND DiscountCards.ValidTo <> &qEmptyDate
	|				AND DiscountCards.ValidTo > &qPeriodFrom
	|			OR DiscountCards.ValidTo = &qEmptyDate)
	|{WHERE
	|	DiscountCards.Ref.* AS DiscountCard,
	|	DiscountCards.Identifier AS Identifier,
	|	DiscountCards.Client.* AS Client,
	|	DiscountCards.Client.FullName AS ClientFullName,
	|	DiscountCards.Client.DateOfBirth AS ClientDateOfBirth,
	|	DiscountCards.Client.Phone AS ClientPhone,
	|	DiscountCards.Client.Fax AS ClientFax,
	|	DiscountCards.Client.EMail AS ClientEMail,
	|	DiscountCards.DiscountType.* AS DiscountType,
	|	DiscountCards.ClientType.* AS ClientType,
	|	DiscountCards.ValidFrom AS ValidFrom,
	|	DiscountCards.ValidTo AS ValidTo,
	|	DiscountCards.TurnOffAutomaticDiscounts AS TurnOffAutomaticDiscounts,
	|	DiscountCards.IsBlocked AS IsBlocked,
	|	DiscountCards.Remarks AS Remarks}
	|
	|ORDER BY
	|	DiscountType,
	|	Client
	|{ORDER BY
	|	DiscountCard.* AS DiscountCard,
	|	Identifier AS Identifier,
	|	Client.* AS Client,
	|	DiscountCards.Client.FullName AS ClientFullName,
	|	DiscountCards.Client.DateOfBirth AS ClientDateOfBirth,
	|	DiscountCards.Client.Phone AS ClientPhone,
	|	DiscountCards.Client.Fax AS ClientFax,
	|	DiscountCards.Client.EMail AS ClientEMail,
	|	DiscountType.* AS DiscountType,
	|	ClientType.* AS ClientType,
	|	ValidFrom AS ValidFrom,
	|	ValidTo AS ValidTo,
	|	TurnOffAutomaticDiscounts AS TurnOffAutomaticDiscounts,
	|	IsBlocked AS IsBlocked,
	|	Remarks AS Remarks}
	|TOTALS
	|	SUM(CardsCount)
	|BY
	|	OVERALL,
	|	DiscountType
	|{TOTALS BY
	|	DiscountCard.* AS DiscountCard,
	|	Identifier AS Identifier,
	|	Client.* AS Client,
	|	DiscountCards.Client.FullName AS ClientFullName,
	|	DiscountCards.Client.DateOfBirth AS ClientDateOfBirth,
	|	DiscountCards.Client.Phone AS ClientPhone,
	|	DiscountCards.Client.Fax AS ClientFax,
	|	DiscountCards.Client.EMail AS ClientEMail,
	|	DiscountType.* AS DiscountType,
	|	ClientType.* AS ClientType,
	|	ValidFrom AS ValidFrom,
	|	ValidTo AS ValidTo,
	|	TurnOffAutomaticDiscounts AS TurnOffAutomaticDiscounts,
	|	IsBlocked AS IsBlocked}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Guests with discount cards';RU='Гости с дисконтными картами';de='Gäste mit Diskontkarten'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
