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
		PeriodFrom = AddMonth(BegOfMonth(CurrentSessionDate()), -1);
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = AddMonth(EndOfMonth(CurrentSessionDate()), -1);
	EndIf;
	If Not ValueIsFilled(Survey) And ValueIsFilled(Hotel) Then
		Survey = Hotel.CheckOutSurvey;
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
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа типов номеров '; en = 'Room types folder '; de = 'Zimmertyp Gruppe '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Survey) Then
		If Not Survey.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Survey ';ru='Опрос ';de='Umfrage '") + 
			                     TrimAll(Survey.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа опросов '; en = 'Surveys folder '; de = 'Umfrage Gruppe '") + 
			                     TrimAll(Survey.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(FeedbackQuestion) Then
		If Not FeedbackQuestion.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Question ';ru='Вопрос ';de='Frage '") + 
			                     TrimAll(FeedbackQuestion.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа вопросов '; en = 'Questions folder '; de = 'Fragen Gruppe '") + 
			                     TrimAll(FeedbackQuestion.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Answer) Then
		vParamPresentation = vParamPresentation + NStr("en='Answer ';ru='Ответ ';de='Antwort '") + 
		                     TrimAll(Answer) + 
		                     ";" + Chars.LF;
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
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qPeriodIsEmpty", Not ValueIsFilled(PeriodTo));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	ReportBuilder.Parameters.Insert("qSurvey", Survey);
	ReportBuilder.Parameters.Insert("qSurveyIsEmpty", Not ValueIsFilled(Survey));
	ReportBuilder.Parameters.Insert("qFeedbackQuestion", FeedbackQuestion);
	ReportBuilder.Parameters.Insert("qFeedbackQuestionIsEmpty", Not ValueIsFilled(FeedbackQuestion));
	ReportBuilder.Parameters.Insert("qAnswer", Answer);
	ReportBuilder.Parameters.Insert("qAnswerIsEmpty", Not ValueIsFilled(Answer));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qEmptyString", "");
	
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
	|	QuestionTotals.Ref.Hotel AS Hotel,
	|	QuestionTotals.Ref.Survey AS Survey,
	|	QuestionTotals.FeedbackQuestion AS FeedbackQuestion,
	|	SUM(1) AS Quantity
	|INTO QuestionTotals
	|FROM
	|	Document.ClientFeedback.Answers AS QuestionTotals
	|WHERE
	|	QuestionTotals.Ref.Date >= &qPeriodFrom
	|	AND QuestionTotals.Ref.Date <= &qPeriodTo
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND QuestionTotals.Ref.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND (QuestionTotals.Ref.Room.RoomType IN HIERARCHY (&qRoomType)
	|					OR QuestionTotals.Ref.ParentDoc.RoomType IN HIERARCHY (&qRoomType)))
	|	AND (&qSurveyIsEmpty
	|			OR NOT &qSurveyIsEmpty
	|				AND QuestionTotals.Ref.Survey IN HIERARCHY (&qSurvey))
	|	AND (&qFeedbackQuestionIsEmpty
	|			OR NOT &qFeedbackQuestionIsEmpty
	|				AND QuestionTotals.FeedbackQuestion IN HIERARCHY (&qFeedbackQuestion))
	|	AND (&qAnswerIsEmpty
	|			OR NOT &qAnswerIsEmpty
	|				AND QuestionTotals.Answer = &qAnswer)
	|
	|GROUP BY
	|	QuestionTotals.Ref.Hotel,
	|	QuestionTotals.Ref.Survey,
	|	QuestionTotals.FeedbackQuestion
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QuestionAnswerTotals.Ref.Hotel AS Hotel,
	|	QuestionAnswerTotals.Ref.Survey AS Survey,
	|	QuestionAnswerTotals.FeedbackQuestion AS FeedbackQuestion,
	|	QuestionAnswerTotals.Answer AS Answer,
	|	SUM(1) AS Quantity
	|INTO QuestionAnswerTotals
	|FROM
	|	Document.ClientFeedback.Answers AS QuestionAnswerTotals
	|WHERE
	|	QuestionAnswerTotals.Ref.Date >= &qPeriodFrom
	|	AND QuestionAnswerTotals.Ref.Date <= &qPeriodTo
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND QuestionAnswerTotals.Ref.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND (QuestionAnswerTotals.Ref.Room.RoomType IN HIERARCHY (&qRoomType)
	|					OR QuestionAnswerTotals.Ref.ParentDoc.RoomType IN HIERARCHY (&qRoomType)))
	|	AND (&qSurveyIsEmpty
	|			OR NOT &qSurveyIsEmpty
	|				AND QuestionAnswerTotals.Ref.Survey IN HIERARCHY (&qSurvey))
	|	AND (&qFeedbackQuestionIsEmpty
	|			OR NOT &qFeedbackQuestionIsEmpty
	|				AND QuestionAnswerTotals.FeedbackQuestion IN HIERARCHY (&qFeedbackQuestion))
	|	AND (&qAnswerIsEmpty
	|			OR NOT &qAnswerIsEmpty
	|				AND QuestionAnswerTotals.Answer = &qAnswer)
	|
	|GROUP BY
	|	QuestionAnswerTotals.Ref.Hotel,
	|	QuestionAnswerTotals.Ref.Survey,
	|	QuestionAnswerTotals.FeedbackQuestion,
	|	QuestionAnswerTotals.Answer
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ClientFeedbackAnswers.Ref.Hotel AS Hotel,
	|	ClientFeedbackAnswers.Ref.Survey AS Survey,
	|	ClientFeedbackAnswers.Ref.Room AS Room,
	|	ClientFeedbackAnswers.Ref.Room.RoomType AS RoomType,
	|	ClientFeedbackAnswers.Ref.ParentDoc AS ParentDoc,
	|	ClientFeedbackAnswers.Ref.Client AS Client,
	|	ClientFeedbackAnswers.Ref.Author AS Author,
	|	ClientFeedbackAnswers.Ref.Remarks AS Remarks,
	|	ClientFeedbackAnswers.FeedbackQuestion AS FeedbackQuestion,
	|	ClientFeedbackAnswers.Answer AS Answer,
	|	CASE
	|		WHEN ISNULL(QuestionTotals.Quantity, 0) <> 0
	|			THEN (CAST(ClientFeedbackAnswers.Answer AS NUMBER(19, 7))) / ISNULL(QuestionTotals.Quantity, 0)
	|		ELSE 0
	|	END AS AverageValue,
	|	0 AS Percentage,
	|	QuestionAnswerTotals.Quantity AS AnswerTotalQuantity,
	|	QuestionTotals.Quantity AS QuestionTotalQuantity,
	|	1 AS Quantity
	|{SELECT
	|	Hotel.* AS Hotel,
	|	Survey.* AS Survey,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	ParentDoc.* AS ParentDoc,
	|	Client.* AS Client,
	|	Author.* AS Author,
	|	Remarks AS Remarks,
	|	FeedbackQuestion.* AS FeedbackQuestion,
	|	ClientFeedbackAnswers.Ref.* AS Recorder,
	|	Answer,
	|	AverageValue,
	|	Percentage,
	|	AnswerTotalQuantity,
	|	QuestionTotalQuantity,
	|	Quantity}
	|FROM
	|	Document.ClientFeedback.Answers AS ClientFeedbackAnswers
	|		LEFT JOIN QuestionTotals AS QuestionTotals
	|		ON ClientFeedbackAnswers.Ref.Hotel = QuestionTotals.Hotel
	|			AND ClientFeedbackAnswers.Ref.Survey = QuestionTotals.Survey
	|			AND ClientFeedbackAnswers.FeedbackQuestion = QuestionTotals.FeedbackQuestion
	|		LEFT JOIN QuestionAnswerTotals AS QuestionAnswerTotals
	|		ON ClientFeedbackAnswers.Ref.Hotel = QuestionAnswerTotals.Hotel
	|			AND ClientFeedbackAnswers.Ref.Survey = QuestionAnswerTotals.Survey
	|			AND ClientFeedbackAnswers.FeedbackQuestion = QuestionAnswerTotals.FeedbackQuestion
	|			AND ClientFeedbackAnswers.Answer = QuestionAnswerTotals.Answer
	|WHERE
	|	ClientFeedbackAnswers.Ref.Date >= &qPeriodFrom
	|	AND ClientFeedbackAnswers.Ref.Date <= &qPeriodTo
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND ClientFeedbackAnswers.Ref.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND (ClientFeedbackAnswers.Ref.Room.RoomType IN HIERARCHY (&qRoomType)
	|					OR ClientFeedbackAnswers.Ref.ParentDoc.RoomType IN HIERARCHY (&qRoomType)))
	|	AND (&qSurveyIsEmpty
	|			OR NOT &qSurveyIsEmpty
	|				AND ClientFeedbackAnswers.Ref.Survey IN HIERARCHY (&qSurvey))
	|	AND (&qFeedbackQuestionIsEmpty
	|			OR NOT &qFeedbackQuestionIsEmpty
	|				AND ClientFeedbackAnswers.FeedbackQuestion IN HIERARCHY (&qFeedbackQuestion))
	|	AND (&qAnswerIsEmpty
	|			OR NOT &qAnswerIsEmpty
	|				AND ClientFeedbackAnswers.Answer = &qAnswer)
	|{WHERE
	|	ClientFeedbackAnswers.Ref.Hotel.* AS Hotel,
	|	ClientFeedbackAnswers.Ref.Survey.* AS Survey,
	|	ClientFeedbackAnswers.Ref.Room.* AS Room,
	|	ClientFeedbackAnswers.Ref.Room.RoomType.* AS RoomType,
	|	ClientFeedbackAnswers.Ref.ParentDoc.* AS ParentDoc,
	|	ClientFeedbackAnswers.Ref.Client.* AS Client,
	|	ClientFeedbackAnswers.Ref.Author.* AS Author,
	|	ClientFeedbackAnswers.Ref.Remarks AS Remarks,
	|	ClientFeedbackAnswers.Ref.* AS Recorder,
	|	ClientFeedbackAnswers.FeedbackQuestion.* AS FeedbackQuestion,
	|	ClientFeedbackAnswers.Answer AS Answer}
	|
	|ORDER BY
	|	Hotel,
	|	Survey,
	|	FeedbackQuestion,
	|	Answer
	|{ORDER BY
	|	Hotel.* AS Hotel,
	|	Survey.* AS Survey,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	ParentDoc.* AS ParentDoc,
	|	Client.* AS Client,
	|	Author.* AS Author,
	|	Remarks AS Remarks,
	|	FeedbackQuestion.* AS FeedbackQuestion,
	|	Answer}
	|TOTALS
	|	CASE 
	|		WHEN FeedbackQuestion IS NULL
	|			THEN 0
	|		WHEN Answer IS NULL
	|			THEN SUM(AverageValue)
	|		ELSE
	|			0
	|	END AS AverageValue,
	|	CASE
	|		WHEN FeedbackQuestion IS NULL
	|			THEN 0
	|		WHEN Answer IS NULL
	|			THEN 100
	|		WHEN MAX(QuestionTotalQuantity) <> 0
	|			THEN MAX(AnswerTotalQuantity) / MAX(QuestionTotalQuantity) * 100
	|		ELSE 0
	|	END AS Percentage,
	|	SUM(Quantity) AS Quantity
	|BY
	|	OVERALL,
	|	Survey,
	|	FeedbackQuestion,
	|	Answer
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	Survey.* AS Survey,
	|	FeedbackQuestion.* AS FeedbackQuestion,
	|	Answer AS Answer,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	ParentDoc.* AS ParentDoc,
	|	Client.* AS Client,
	|	Author.* AS Author,
	|	Remarks AS Remarks,
	|	Answer}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Clients feedback';RU='Опросы клиентов';de='Kundenumfragen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Quantity" 
	   Or pName = "Percentage" 
	   Or pName = "AverageValue" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
