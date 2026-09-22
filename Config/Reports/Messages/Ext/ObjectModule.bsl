// -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	If ValueIsFilled(MessageReportPeriodCheckType) Then
		SearchByMessageStartDate = False;
	EndIf;
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
	If Not ValueIsFilled(MessageReportPeriodCheckType) Then
		If SearchByMessageStartDate Then
			MessageReportPeriodCheckType = Enums.MessageReportPeriodCheckTypes.ByMessageIsValidFromDate;
		Else
			MessageReportPeriodCheckType = Enums.MessageReportPeriodCheckTypes.ByMessageDate;
		EndIf;
	Else
		SearchByMessageStartDate = False;
	EndIf;
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Nothing yet
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
	If ValueIsFilled(MessageReportPeriodCheckType) Then
		vParamPresentation = TrimAll(vParamPresentation) + " " +
		                     TrimAll(MessageReportPeriodCheckType) + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Type) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Тип '; en = 'Type '; de = 'Typ '") + 
		                     TrimAll(Type) + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(MessageType) Then
		If Not MessageType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Вид '; en = 'Message type '; de = 'Nachrichtentyp '") + 
			                     TrimAll(MessageType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа видов '; en = 'Message types folder '; de = 'Nachrichtentypengruppe '") + 
			                     TrimAll(MessageType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(MessageStatus) Then
		If Not MessageStatus.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Статус '; en = 'Status '; de = 'Status '") + 
			                     TrimAll(MessageStatus.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа статусов '; en = 'Statuses folder '; de = 'Statusengruppe '") + 
			                     TrimAll(MessageStatus.Description) + 
			                     ";" + Chars.LF;
		EndIf;
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
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа отделов '; en = 'Departments folder '; de = 'Abteilungen folder '") + 
			                     TrimAll(Department.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Room) Then
		If Not Room.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room ';ru='Номер ';de='Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Gruppe Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Gruppe Zimmertypen '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Object) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Объект '; en = 'Object '; de = 'Object '") + 
							 TrimAll(Object.Description) + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(ReservationTaskArea) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Область '; en = 'Area '; de = 'Bereich '") + 
							 TrimAll(ReservationTaskArea) + 
							 ";" + Chars.LF;
	EndIf;
	If Not ShowClosedMessages Then
		vParamPresentation = vParamPresentation + NStr("en='Active messages only';ru='Только действующие сообщения';de='Nur aktuelle Aufgaben'") + 
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
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235959'));
	ReportBuilder.Parameters.Insert("qPeriodCheckType", MessageReportPeriodCheckType);
	ReportBuilder.Parameters.Insert("qArea", ReservationTaskArea);
	ReportBuilder.Parameters.Insert("qIsEmptyArea", Not ValueIsFilled(ReservationTaskArea));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qIsEmptyRoom", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qIsEmptyRoomType", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qObject", Object);
	ReportBuilder.Parameters.Insert("qIsEmptyObject", Not ValueIsFilled(Object));
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qIsEmptyEmployee", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qDepartment", Department);
	ReportBuilder.Parameters.Insert("qIsEmptyDepartment", Not ValueIsFilled(Department));
	ReportBuilder.Parameters.Insert("qMessageType", MessageType);
	ReportBuilder.Parameters.Insert("qIsEmptyMessageType", Not ValueIsFilled(MessageType));
	ReportBuilder.Parameters.Insert("qType", Type);
	ReportBuilder.Parameters.Insert("qIsEmptyType", Not ValueIsFilled(Type));
	ReportBuilder.Parameters.Insert("qMessageStatus", MessageStatus);
	ReportBuilder.Parameters.Insert("qIsEmptyMessageStatus", Not ValueIsFilled(MessageStatus));
	ReportBuilder.Parameters.Insert("qShowClosedMessages", ShowClosedMessages);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');

	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	Try
		ReportBuilder.Put(pSpreadsheet);
	Except
		tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
	EndTry;
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
	
	// Remove row height limits
	For i = 5 To pSpreadsheet.TableHeight Do
		vRowI = pSpreadsheet.Area(i, , i, );
		If vRowI.AutoRowHeight Then
			If vRowI.RowHeight = 55 Then
				vRowI.RowHeight = 0;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	Messages.Period AS Period,
	|	Messages.Object AS Object,
	|	Messages.Remarks AS Remarks,
	|	Messages.Author AS Author,
	|	MessagesLastComments.LastComment AS LastComment,
	|	MessagesLastComments.LastCommentPeriod AS LastCommentPeriod,
	|	MessagesLastComments.LastCommentAuthor AS LastCommentAuthor,
	|	DATEDIFF(Messages.Recorder.ActivityStartTime, Messages.Recorder.ActivityEndTime, MINUTE) AS ActivityDuration,
	|	1 AS Count
	|{SELECT
	|	Period,
	|	Object.*,
	|	(BEGINOFPERIOD(Messages.Recorder.Date, DAY)) AS CreateDate,
	|	Messages.Type.* AS Type,
	|	Messages.MessageType.* AS MessageType,
	|	Messages.MessageStatus.* AS MessageStatus,
	|	Messages.ReservationTaskArea AS ReservationTaskArea,
	|	Remarks,
	|	Messages.ForEmployee.*,
	|	Messages.ForDepartment.*,
	|	Messages.ValidFromDate,
	|	(BEGINOFPERIOD(Messages.ValidFromDate, DAY)) AS ValidFromDay,
	|	Messages.ValidToDate,
	|	Messages.CloseToDate,
	|	Author.*,
	|	Messages.Recorder.*,
	|	Messages.Recorder.ActivityStartTime AS ActivityStartTime,
	|	Messages.Recorder.ActivityEndTime AS ActivityEndTime,
	|	ActivityDuration,
	|	Messages.Recorder.ContactPerson.* AS ContactPerson,
	|	Messages.Recorder.Position AS ContactPersonPosition,
	|	Messages.Recorder.Phone AS ContactPersonPhone,
	|	Messages.Recorder.Phone2 AS ContactPersonPhone2,
	|	Messages.Recorder.EMail AS ContactPersonEMail,
	|	Messages.IsClosed,
	|	Count,
	|	LastComment,
	|	LastCommentPeriod,
	|	LastCommentAuthor.*,
	|	Messages.ClosedBy.*,
	|	(BEGINOFPERIOD(Messages.DateWhenClosed, DAY)) AS DayWhenClosed,
	|	Messages.DateWhenClosed}
	|FROM
	|	InformationRegister.Messages AS Messages
	|		LEFT JOIN (SELECT
	|			LastCommentLineNumbers.Ref AS Ref,
	|			LastComments.Comments AS LastComment,
	|			LastComments.Employee AS LastCommentAuthor,
	|			LastComments.Period AS LastCommentPeriod
	|		FROM
	|			(SELECT
	|				MessageComments.Ref AS Ref,
	|				MAX(MessageComments.LineNumber) AS LastCommentLineNumber
	|			FROM
	|				Document.Message.Comments AS MessageComments
	|			WHERE
	|				MessageComments.Ref.Posted
	|				AND (NOT MessageComments.Ref.IsClosed
	|						OR &qShowClosedMessages)
	|				AND (MessageComments.Ref.MessageStatus IN HIERARCHY (&qMessageStatus)
	|							AND NOT &qIsEmptyMessageStatus
	|						OR &qIsEmptyMessageStatus)
	|				AND (MessageComments.Ref.ForEmployee IN HIERARCHY (&qEmployee)
	|							AND NOT &qIsEmptyEmployee
	|						OR &qIsEmptyEmployee)
	|				AND (MessageComments.Ref.ForDepartment IN HIERARCHY (&qDepartment)
	|							AND NOT &qIsEmptyDepartment
	|						OR &qIsEmptyDepartment)
	|				AND (MessageComments.Ref.ByObject = &qObject
	|						OR &qIsEmptyObject)
	|				AND (MessageComments.Ref.ByObject IN HIERARCHY (&qRoom)
	|							AND NOT &qIsEmptyRoom
	|						OR &qIsEmptyRoom)
	|			
	|			GROUP BY
	|				MessageComments.Ref) AS LastCommentLineNumbers
	|				INNER JOIN Document.Message.Comments AS LastComments
	|				ON LastCommentLineNumbers.Ref = LastComments.Ref
	|					AND LastCommentLineNumbers.LastCommentLineNumber = LastComments.LineNumber) AS MessagesLastComments
	|		ON Messages.Recorder = MessagesLastComments.Ref
	|WHERE
	|	(NOT Messages.IsClosed
	|			OR &qShowClosedMessages)
	|	AND (Messages.Type = &qType
	|				AND NOT &qIsEmptyType
	|			OR &qIsEmptyType)
	|	AND (Messages.MessageType IN HIERARCHY (&qMessageType)
	|				AND NOT &qIsEmptyMessageType
	|			OR &qIsEmptyMessageType)
	|	AND (Messages.ReservationTaskArea = &qArea
	|				AND NOT &qIsEmptyArea
	|			OR &qIsEmptyArea)
	|	AND (Messages.MessageStatus IN HIERARCHY (&qMessageStatus)
	|				AND NOT &qIsEmptyMessageStatus
	|			OR &qIsEmptyMessageStatus)
	|	AND (Messages.ForEmployee IN HIERARCHY (&qEmployee)
	|				AND NOT &qIsEmptyEmployee
	|			OR &qIsEmptyEmployee)
	|	AND (Messages.ForDepartment IN HIERARCHY (&qDepartment)
	|				AND NOT &qIsEmptyDepartment
	|			OR &qIsEmptyDepartment)
	|	AND (Messages.Object = &qObject
	|			OR &qIsEmptyObject)
	|	AND (Messages.Object IN HIERARCHY (&qRoom)
	|				AND NOT &qIsEmptyRoom
	|			OR &qIsEmptyRoom)
	|	AND (ISNULL(Messages.Object.RoomType, VALUE(Catalog.RoomTypes.EmptyRef)) IN HIERARCHY (&qRoomType)
	|				AND NOT &qIsEmptyRoomType
	|			OR &qIsEmptyRoomType)
	|	AND CASE
	|			WHEN &qPeriodCheckType = VALUE(Enum.MessageReportPeriodCheckTypes.EmptyRef)
	|					AND Messages.Period >= &qPeriodFrom
	|					AND Messages.Period <= &qPeriodTo
	|				THEN TRUE
	|			WHEN &qPeriodCheckType = VALUE(Enum.MessageReportPeriodCheckTypes.ByMessageDate)
	|					AND Messages.Period >= &qPeriodFrom
	|					AND Messages.Period <= &qPeriodTo
	|				THEN TRUE
	|			WHEN &qPeriodCheckType = VALUE(Enum.MessageReportPeriodCheckTypes.ByMessageIsValidFromDate)
	|					AND Messages.ValidFromDate >= &qPeriodFrom
	|					AND Messages.ValidFromDate <= &qPeriodTo
	|				THEN TRUE
	|			WHEN &qPeriodCheckType = VALUE(Enum.MessageReportPeriodCheckTypes.ByCheckInDate)
	|					AND ISNULL(Messages.Object.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|					AND ISNULL(Messages.Object.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|				THEN TRUE
	|			WHEN &qPeriodCheckType = VALUE(Enum.MessageReportPeriodCheckTypes.ByCheckOutDate)
	|					AND ISNULL(Messages.Object.CheckOutDate, &qEmptyDate) >= &qPeriodFrom
	|					AND ISNULL(Messages.Object.CheckOutDate, &qEmptyDate) <= &qPeriodTo
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|{WHERE
	|	Messages.Period,
	|	(BEGINOFPERIOD(Messages.Recorder.Date, DAY)) AS CreateDate,
	|	Messages.MessageType.* AS MessageType,
	|	Messages.MessageStatus.* AS MessageStatus,
	|	Messages.ReservationTaskArea AS ReservationTaskArea,
	|	Messages.Recorder.*,
	|	Messages.Recorder.ActivityStartTime AS ActivityStartTime,
	|	Messages.Recorder.ActivityEndTime AS ActivityEndTime,
	|	(DATEDIFF(Messages.Recorder.ActivityStartTime, Messages.Recorder.ActivityEndTime, MINUTE)) AS ActivityDuration,
	|	Messages.Recorder.ContactPerson.* AS ContactPerson,
	|	Messages.Recorder.Position AS ContactPersonPosition,
	|	Messages.Recorder.Phone AS ContactPersonPhone,
	|	Messages.Recorder.Phone2 AS ContactPersonPhone2,
	|	Messages.Recorder.EMail AS ContactPersonEMail,
	|	Messages.ForEmployee.*,
	|	Messages.ForDepartment.*,
	|	Messages.Object.*,
	|	Messages.ValidFromDate,
	|	(BEGINOFPERIOD(Messages.ValidFromDate, DAY)) AS ValidFromDay,
	|	Messages.ValidToDate,
	|	Messages.CloseToDate,
	|	Messages.Remarks,
	|	MessagesLastComments.LastComment AS LastComment,
	|	MessagesLastComments.LastCommentPeriod AS LastCommentPeriod,
	|	MessagesLastComments.LastCommentAuthor AS LastCommentAuthor,
	|	Messages.Author.*,
	|	Messages.IsClosed,
	|	Messages.ClosedBy.*,
	|	(BEGINOFPERIOD(Messages.DateWhenClosed, DAY)) AS DayWhenClosed,
	|	Messages.DateWhenClosed}
	|
	|ORDER BY
	|	Period
	|{ORDER BY
	|	Period,
	|	(BEGINOFPERIOD(Messages.Recorder.Date, DAY)) AS CreateDate,
	|	Messages.MessageType.* AS MessageType,
	|	Messages.MessageStatus.* AS MessageStatus,
	|	Messages.ReservationTaskArea AS ReservationTaskArea,
	|	Messages.Recorder.*,
	|	Messages.Recorder.ActivityStartTime AS ActivityStartTime,
	|	Messages.Recorder.ActivityEndTime AS ActivityEndTime,
	|	ActivityDuration,
	|	Messages.Recorder.ContactPerson.* AS ContactPerson,
	|	Messages.Recorder.Position AS ContactPersonPosition,
	|	Messages.Recorder.Phone AS ContactPersonPhone,
	|	Messages.Recorder.Phone2 AS ContactPersonPhone2,
	|	Messages.Recorder.EMail AS ContactPersonEMail,
	|	Messages.ForEmployee.*,
	|	Messages.ForDepartment.*,
	|	Object.*,
	|	Messages.ValidFromDate,
	|	(BEGINOFPERIOD(Messages.ValidFromDate, DAY)) AS ValidFromDay,
	|	Messages.ValidToDate,
	|	Messages.CloseToDate,
	|	LastComment,
	|	LastCommentPeriod,
	|	LastCommentAuthor.*,
	|	Author.*,
	|	Messages.IsClosed,
	|	Messages.ClosedBy.*,
	|	(BEGINOFPERIOD(Messages.DateWhenClosed, DAY)) AS DayWhenClosed,
	|	Messages.DateWhenClosed}
	|TOTALS
	|	SUM(ActivityDuration),
	|	SUM(Count)
	|BY
	|	OVERALL,
	|	Object HIERARCHY
	|{TOTALS BY
	|	Messages.MessageType.* AS MessageType,
	|	Messages.MessageStatus.* AS MessageStatus,
	|	Messages.ReservationTaskArea AS ReservationTaskArea,
	|	Messages.ForEmployee.*,
	|	Messages.ForDepartment.*,
	|	(BEGINOFPERIOD(Messages.Recorder.Date, DAY)) AS CreateDate,
	|	(BEGINOFPERIOD(Messages.ValidFromDate, DAY)) AS ValidFromDay,
	|	Object.*,
	|	LastCommentAuthor.*,
	|	Author.*,
	|	Messages.IsClosed,
	|	Messages.ClosedBy.*,
	|	(BEGINOFPERIOD(Messages.DateWhenClosed, DAY)) AS DayWhenClosed}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Tasks and activities';ru='Действия и задачи';de='Aufgaben und Aktivitäten'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
