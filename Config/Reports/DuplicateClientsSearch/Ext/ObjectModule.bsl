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
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If SearchType = 0 Then
		vParamPresentation = vParamPresentation + NStr("en='Full name'; ru='Полное имя'; de='Vollständiger Name'") + 
		                     ";" + Chars.LF;
	ElsIf SearchType = 1 Then
		vParamPresentation = vParamPresentation + NStr("en='Phone'; ru='Телефон'; de='Telefon'") + 
		                     ";" + Chars.LF;
	ElsIf SearchType = 2 Then
		vParamPresentation = vParamPresentation + NStr("en='E-Mail'; ru='E-Mail'; de='E-Mail'") + 
		                     ";" + Chars.LF;
	ElsIf SearchType = 3 Then
		vParamPresentation = vParamPresentation + NStr("en='Identity document type + series + number'; ru='Тип документа удостоверяющего личность + серия + номер'; de='Art des Ausweisdokuments + Serie + Nummer'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Unknown search type!';ru='Неизвестный тип поиска!';de='Unbekannter Suchtyp!'") + 
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
	ReportBuilder.Parameters.Insert("qSearchType", SearchType);

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
	|	CASE
	|		WHEN &qSearchType = 0
	|			THEN AllClients.FullName
	|		WHEN &qSearchType = 1
	|			THEN AllClients.Phone
	|		WHEN &qSearchType = 2
	|			THEN AllClients.EMail
	|		WHEN &qSearchType = 3
	|			THEN ISNULL(AllClients.IdentityDocumentType.Description, """") + "" "" + AllClients.IdentityDocumentSeries + "" "" + AllClients.IdentityDocumentNumber
	|		ELSE AllClients.Code
	|	END AS SearchString,
	|	COUNT(AllClients.Ref) AS ClientsCount
	|INTO DuplicatedSearchStrings
	|FROM
	|	Catalog.Clients AS AllClients
	|WHERE
	|	NOT AllClients.DeletionMark
	|	AND NOT AllClients.IsFolder
	|	AND CASE
	|			WHEN &qSearchType = 0
	|				THEN AllClients.FullName
	|			WHEN &qSearchType = 1
	|				THEN AllClients.Phone
	|			WHEN &qSearchType = 2
	|				THEN AllClients.EMail
	|			WHEN &qSearchType = 3
	|				THEN ISNULL(AllClients.IdentityDocumentType.Description, """") + "" "" + AllClients.IdentityDocumentSeries + "" "" + AllClients.IdentityDocumentNumber
	|			ELSE AllClients.Code
	|		END <> """"
	|	AND (&qSearchType <> 3 OR &qSearchType = 3 AND AllClients.IdentityDocumentNumber <> """")
	|
	|GROUP BY
	|	CASE
	|		WHEN &qSearchType = 0
	|			THEN AllClients.FullName
	|		WHEN &qSearchType = 1
	|			THEN AllClients.Phone
	|		WHEN &qSearchType = 2
	|			THEN AllClients.EMail
	|		WHEN &qSearchType = 3
	|			THEN ISNULL(AllClients.IdentityDocumentType.Description, """") + "" "" + AllClients.IdentityDocumentSeries + "" "" + AllClients.IdentityDocumentNumber
	|		ELSE AllClients.Code
	|	END
	|
	|HAVING
	|	COUNT(AllClients.Ref) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Clients.SearchString AS SearchString,
	|	Clients.Client.Code AS Code,
	|	Clients.Client AS Client,
	|	Clients.Client.Title AS Title,
	|	Clients.Client.Salutation AS Salutation,
	|	Clients.Client.FullName AS FullName,
	|	Clients.Client.DateOfBirth AS DateOfBirth,
	|	Clients.Client.Sex AS Sex,
	|	Clients.Client.CreateDate AS CreateDate,
	|	Clients.Client.Author AS Author,
	|	Clients.Client.Phone AS Phone,
	|	Clients.Client.Fax AS Phone2,
	|	Clients.Client.EMail AS EMail,
	|	Clients.Client.EMailAdditional AS EMail2,
	|	Clients.Client.IdentityDocumentType AS IdentityDocumentType,
	|	Clients.Client.IdentityDocumentSeries AS IdentityDocumentSeries,
	|	Clients.Client.IdentityDocumentNumber AS IdentityDocumentNumber,
	|	Clients.Client.IdentityDocumentIssuedBy AS IdentityDocumentIssuedBy,
	|	Clients.Client.Citizenship AS Citizenship,
	|	Clients.Client.Remarks AS Remarks,
	|	Clients.Counter AS Counter
	|{SELECT
	|	SearchString,
	|	Code,
	|	Client.*,
	|	Title,
	|	Salutation,
	|	FullName,
	|	DateOfBirth,
	|	Sex,
	|	CreateDate,
	|	Author,
	|	Phone,
	|	Phone2,
	|	EMail,
	|	EMail2,
	|	IdentityDocumentType.*,
	|	IdentityDocumentSeries,
	|	IdentityDocumentNumber,
	|	IdentityDocumentIssuedBy,
	|	Citizenship.*,
	|	Remarks,
	|	Counter}
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN &qSearchType = 0
	|				THEN AllClients.FullName
	|			WHEN &qSearchType = 1
	|				THEN AllClients.Phone
	|			WHEN &qSearchType = 2
	|				THEN AllClients.EMail
	|			WHEN &qSearchType = 3
	|				THEN ISNULL(AllClients.IdentityDocumentType.Description, """") + "" "" + AllClients.IdentityDocumentSeries + "" "" + AllClients.IdentityDocumentNumber
	|			ELSE AllClients.Code
	|		END AS SearchString,
	|		AllClients.Ref AS Client,
	|		1 AS Counter
	|	FROM
	|		Catalog.Clients AS AllClients
	|			INNER JOIN DuplicatedSearchStrings AS DuplicatedSearchStrings
	|			ON (CASE
	|					WHEN &qSearchType = 0
	|						THEN AllClients.FullName
	|					WHEN &qSearchType = 1
	|						THEN AllClients.Phone
	|					WHEN &qSearchType = 2
	|						THEN AllClients.EMail
	|					WHEN &qSearchType = 3
	|						THEN ISNULL(AllClients.IdentityDocumentType.Description, """") + "" "" + AllClients.IdentityDocumentSeries + "" "" + AllClients.IdentityDocumentNumber
	|					ELSE AllClients.Code
	|				END = DuplicatedSearchStrings.SearchString)) AS Clients
	|{WHERE
	|	Clients.SearchString AS SearchString,
	|	Clients.Client.Code AS Code,
	|	Clients.Client.* AS Client,
	|	Clients.Client.Title AS Title,
	|	Clients.Client.Salutation AS Salutation,
	|	Clients.Client.FullName AS FullName,
	|	Clients.Client.DateOfBirth AS DateOfBirth,
	|	Clients.Client.Sex AS Sex,
	|	Clients.Client.CreateDate AS CreateDate,
	|	Clients.Client.Author AS Author,
	|	Clients.Client.Phone AS Phone,
	|	Clients.Client.Fax AS Phone2,
	|	Clients.Client.EMail AS EMail,
	|	Clients.Client.EMailAdditional AS EMail2,
	|	Clients.Client.IdentityDocumentType.* AS IdentityDocumentType,
	|	Clients.Client.IdentityDocumentSeries AS IdentityDocumentSeries,
	|	Clients.Client.IdentityDocumentNumber AS IdentityDocumentNumber,
	|	Clients.Client.IdentityDocumentIssuedBy AS IdentityDocumentIssuedBy,
	|	Clients.Client.Citizenship.* AS Citizenship,
	|	Clients.Client.Remarks AS Remarks}
	|
	|ORDER BY
	|	SearchString,
	|	FullName
	|{ORDER BY
	|	SearchString AS SearchString,
	|	Code,
	|	Client.* AS Client,
	|	Title,
	|	Salutation,
	|	FullName,
	|	DateOfBirth,
	|	Sex,
	|	CreateDate,
	|	Author,
	|	Phone,
	|	Phone2,
	|	EMail,
	|	EMail2,
	|	IdentityDocumentType.*,
	|	IdentityDocumentSeries,
	|	IdentityDocumentNumber,
	|	IdentityDocumentIssuedBy,
	|	Citizenship.*}
	|TOTALS
	|	SUM(Counter)
	|BY
	|	SearchString
	|{TOTALS BY
	|	SearchString,
	|	Code,
	|	Client.* AS Client,
	|	Title,
	|	Salutation,
	|	FullName,
	|	DateOfBirth,
	|	Sex,
	|	Author,
	|	Phone,
	|	Phone2,
	|	EMail,
	|	EMail2,
	|	IdentityDocumentType.*,
	|	IdentityDocumentSeries,
	|	IdentityDocumentNumber,
	|	IdentityDocumentIssuedBy,
	|	Citizenship.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("ru='Поиск дублированных клиентов';de='Suche nach doppelten Clients';en='Search for duplicate clients'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
