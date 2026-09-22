
#Region Public

// -----------------------------------------------------------------------------
// Description: Returns value table with messages for the given object
// Parameters: Object reference, Whether to return closed messages or not
// Return value: Value table with messages
// -----------------------------------------------------------------------------
Function cmGetMessagesForObject(pObject = Undefined, pShowClosed = False, pDate = '00010101', pShowTotals = False, pShowPopUpOnly = False, pShowClosedOnly = False, pType = Undefined, pHotelList = Undefined, pFilterByEmployeeAndDepartment = False) Export
	If pShowTotals = Undefined Then
		pShowTotals = False;
	EndIf;
	// Build and run query
	qGetMsgs = New Query;
	If TypeOf(pObject) = Type("CatalogRef.Employees") Then
		qGetMsgs.Text = 
		"SELECT
		|	MessagesForEmployee.Recorder AS MessageRef
		|INTO MessagesForEmployee
		|FROM
		|	InformationRegister.Messages AS MessagesForEmployee
		|WHERE
		|	(MessagesForEmployee.ForEmployee = &qEmployee
		|			OR MessagesForEmployee.Author = &qEmployee
		|				AND NOT &qShowPopUpOnly
		|			OR MessagesForEmployee.ForEmployee = &qEmptyEmployeeRef
		|				AND MessagesForEmployee.ForDepartment = &qEmptyDepartmentRef
		|				AND MessagesForEmployee.Object = UNDEFINED
		|				AND &qHasRightsToSeeAllMessages)
		|	AND (NOT MessagesForEmployee.IsClosed
		|				AND NOT &qShowClosed
		|			OR &qShowClosed)
		|	AND (MessagesForEmployee.PopUp
		|				AND &qShowPopUpOnly
		|			OR NOT &qShowPopUpOnly)
		|	AND (MessagesForEmployee.ValidFromDate <= &qEndOfPeriod
		|			OR MessagesForEmployee.ValidFromDate = &qEmptyDate
		|			OR &qDateIsEmpty)
		|	AND (MessagesForEmployee.ValidToDate >= &qBeginOfPeriod
		|			OR MessagesForEmployee.ValidToDate = &qEmptyDate
		|			OR &qDateIsEmpty)
		|	AND (&qDateIsEmpty
		|			OR NOT &qDateIsEmpty
		|				AND MessagesForEmployee.AccountingDate = &qDate)
		|	AND (&qHotelListIsEmpty
		|			OR NOT &qHotelListIsEmpty
		|				AND MessagesForEmployee.Hotel IN (&qHotelList))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MessagesForEmployeeDepartment.Recorder AS MessageRef
		|INTO MessagesForEmployeeDepartment
		|FROM
		|	InformationRegister.Messages AS MessagesForEmployeeDepartment
		|WHERE
		|	&qDepartment <> UNDEFINED
		|	AND MessagesForEmployeeDepartment.ForDepartment = &qDepartment
		|	AND (NOT MessagesForEmployeeDepartment.IsClosed
		|				AND NOT &qShowClosed
		|			OR &qShowClosed)
		|	AND (MessagesForEmployeeDepartment.PopUp
		|				AND &qShowPopUpOnly
		|			OR NOT &qShowPopUpOnly)
		|	AND (MessagesForEmployeeDepartment.ValidFromDate <= &qEndOfPeriod
		|			OR MessagesForEmployeeDepartment.ValidFromDate = &qEmptyDate
		|			OR &qDateIsEmpty)
		|	AND (MessagesForEmployeeDepartment.ValidToDate >= &qBeginOfPeriod
		|			OR MessagesForEmployeeDepartment.ValidToDate = &qEmptyDate
		|			OR &qDateIsEmpty)
		|	AND (&qDateIsEmpty
		|			OR NOT &qDateIsEmpty
		|				AND MessagesForEmployeeDepartment.AccountingDate = &qDate)
		|	AND (&qHotelListIsEmpty
		|			OR NOT &qHotelListIsEmpty
		|				AND MessagesForEmployeeDepartment.Hotel IN (&qHotelList))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MessagesToReturn.MessageRef AS MessageRef
		|INTO MessagesToReturn
		|FROM
		|	(SELECT
		|		MessagesForEmployee.MessageRef AS MessageRef
		|	FROM
		|		MessagesForEmployee AS MessagesForEmployee
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MessagesForEmployeeDepartment.MessageRef
		|	FROM
		|		MessagesForEmployeeDepartment AS MessagesForEmployeeDepartment) AS MessagesToReturn
		|
		|GROUP BY
		|	MessagesToReturn.MessageRef
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Messages.AccountingDate AS AccountingDate,
		|	1 AS Counter,
		|	Messages.Period AS Period,
		|	Messages.Recorder AS Recorder,
		|	Messages.LineNumber AS LineNumber,
		|	Messages.Active AS Active,
		|	Messages.Object AS Object,
		|	Messages.Hotel AS Hotel,
		|	Messages.Type AS Type,
		|	Messages.MessageType AS MessageType,
		|	Messages.MessageStatus AS MessageStatus,
		|	Messages.ReservationTaskArea AS ReservationTaskArea,
		|	Messages.ValidFromDate AS ValidFromDate,
		|	Messages.ValidToDate AS ValidToDate,
		|	Messages.CloseToDate AS CloseToDate,
		|	Messages.Remarks AS Remarks,
		|	Messages.ForEmployee AS ForEmployee,
		|	Messages.ForDepartment AS ForDepartment,
		|	Messages.Recorder.ContactPerson AS ContactPerson,
		|	Messages.IsClosed AS IsClosed,
		|	Messages.PopUp AS PopUp,
		|	Messages.Author AS Author,
		|	Messages.Color AS Color,
		|	MessagesLastComments.LastComment AS LastComment,
		|	MessagesLastComments.LastCommentPeriod AS LastCommentPeriod,
		|	MessagesLastComments.LastCommentAuthor AS LastCommentAuthor
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
		|				MessageComments.Ref IN
		|						(SELECT
		|							MessagesToReturn.MessageRef
		|						FROM
		|							MessagesToReturn AS MessagesToReturn)
		|			
		|			GROUP BY
		|				MessageComments.Ref) AS LastCommentLineNumbers
		|				INNER JOIN Document.Message.Comments AS LastComments
		|				ON LastCommentLineNumbers.Ref = LastComments.Ref
		|					AND LastCommentLineNumbers.LastCommentLineNumber = LastComments.LineNumber) AS MessagesLastComments
		|		ON Messages.Recorder = MessagesLastComments.Ref
		|WHERE
		|	Messages.Recorder IN
		|			(SELECT
		|				MessagesToReturn.MessageRef
		|			FROM
		|				MessagesToReturn AS MessagesToReturn)
		|	AND (&qDateIsEmpty
		|			OR NOT &qDateIsEmpty
		|				AND Messages.AccountingDate = &qDate)
		|	AND (Messages.ForEmployee = &qEmployee
		|			OR Messages.Author = &qEmployee
		|				AND NOT &qShowPopUpOnly
		|			OR Messages.ForEmployee = &qEmptyEmployeeRef
		|				AND Messages.ForDepartment = &qEmptyDepartmentRef
		|				AND &qHasRightsToSeeAllMessages
		|			OR Messages.ForDepartment <> &qEmptyDepartmentRef
		|				AND Messages.ForDepartment = &qDepartment
		|				AND &qDepartment <> UNDEFINED)
		|	AND (NOT &qShowClosedOnly
		|			OR &qShowClosedOnly
		|				AND Messages.IsClosed)
		|	AND (Messages.Type = &qType
		|			OR &qType = UNDEFINED)
		|	AND (&qHotelListIsEmpty
		|			OR NOT &qHotelListIsEmpty
		|				AND Messages.Hotel IN (&qHotelList))
		|
		|ORDER BY
		|	AccountingDate,
		|	ValidFromDate,
		|	Messages.PointInTime DESC";
		qGetMsgs.SetParameter("qEmployee", pObject);
		If ValueIsFilled(pObject) And ValueIsFilled(pObject.Department) Then
			qGetMsgs.SetParameter("qDepartment", pObject.Department);
		Else
			qGetMsgs.SetParameter("qDepartment", Undefined);
		EndIf;
		qGetMsgs.SetParameter("qEmptyEmployeeRef", Catalogs.Employees.EmptyRef());
		qGetMsgs.SetParameter("qEmptyDepartmentRef", Catalogs.Departments.EmptyRef());
		qGetMsgs.SetParameter("qHasRightsToSeeAllMessages", cmCheckUserPermissions("HavePermissionToSeeAllMessages"));
		qGetMsgs.SetParameter("qType", pType);
	Else
		qGetMsgs.Text = 
		"SELECT
		|	Messages.AccountingDate AS AccountingDate,
		|	1 AS Counter,
		|	Messages.Period AS Period,
		|	Messages.Recorder AS Recorder,
		|	1 AS LineNumber,
		|	TRUE AS Active,
		|	Messages.Object AS Object,
		|	Messages.Hotel AS Hotel,
		|	Messages.Recorder.Type AS Type,
		|	Messages.Recorder.MessageType AS MessageType,
		|	Messages.Recorder.MessageStatus AS MessageStatus,
		|	Messages.Recorder.ReservationTaskArea AS ReservationTaskArea,
		|	Messages.Recorder.ValidFromDate AS ValidFromDate,
		|	Messages.Recorder.ValidToDate AS ValidToDate,
		|	Messages.Recorder.CloseToDate AS CloseToDate,
		|	Messages.Recorder.Remarks AS Remarks,
		|	Messages.Recorder.ForEmployee AS ForEmployee,
		|	Messages.Recorder.ForDepartment AS ForDepartment,
		|	Messages.Recorder.ContactPerson AS ContactPerson,
		|	Messages.Recorder.IsClosed AS IsClosed,
		|	Messages.Recorder.PopUp AS PopUp,
		|	Messages.Recorder.Author AS Author,
		|	Messages.Recorder.Color AS Color,
		|	CAST(MessagesLastComments.LastComment AS STRING(1024)) AS LastComment,
		|	MessagesLastComments.LastCommentPeriod AS LastCommentPeriod,
		|	MessagesLastComments.LastCommentAuthor AS LastCommentAuthor
		|FROM
		|	(SELECT
		|		MessagesRecords.AccountingDate AS AccountingDate,
		|		MessagesRecords.Period AS Period,
		|		MessagesRecords.Recorder AS Recorder,
		|		MessagesRecords.Object AS Object,
		|		MessagesRecords.Hotel AS Hotel
		|	FROM
		|		InformationRegister.Messages AS MessagesRecords
		|	WHERE
		|		(NOT MessagesRecords.IsClosed
		|					AND NOT &qShowClosed
		|				OR &qShowClosed)
		|		AND (NOT &qShowClosedOnly
		|				OR &qShowClosedOnly
		|					AND MessagesRecords.IsClosed)
		|		AND (MessagesRecords.PopUp
		|					AND &qShowPopUpOnly
		|				OR NOT &qShowPopUpOnly)
		|		AND (MessagesRecords.Object = &qObject
		|				OR MessagesRecords.Object = &qObjectReservation
		|					AND &qObjectReservationIsFilled)
		|		AND (MessagesRecords.ValidFromDate <= &qEndOfPeriod
		|				OR MessagesRecords.ValidFromDate = &qEmptyDate
		|				OR &qDateIsEmpty)
		|		AND (MessagesRecords.ValidToDate >= &qBeginOfPeriod
		|				OR MessagesRecords.ValidToDate = &qEmptyDate
		|				OR &qDateIsEmpty)
		|		AND (&qDateIsEmpty
		|				OR NOT &qDateIsEmpty
		|					AND MessagesRecords.AccountingDate = &qDate)
		|		AND (&qHotelListIsEmpty
		|				OR NOT &qHotelListIsEmpty
		|					AND MessagesRecords.Hotel IN (&qHotelList))
		|		AND (&qHasRightsToSeeAllMessages
		|				OR NOT &qHasRightsToSeeAllMessages
		|					AND NOT &qFilterByEmployeeAndDepartment
		|				OR NOT &qHasRightsToSeeAllMessages
		|					AND &qFilterByEmployeeAndDepartment
		|					AND (MessagesRecords.ForEmployee = &qEmployee
		|							AND MessagesRecords.ForEmployee <> VALUE(Catalog.Employees.EmptyRef)
		|						OR MessagesRecords.Author = &qEmployee
		|							AND MessagesRecords.Author <> VALUE(Catalog.Employees.EmptyRef)
		|						OR MessagesRecords.ForDepartment = &qDepartment
		|							AND MessagesRecords.ForDepartment <> VALUE(Catalog.Departments.EmptyRef)))
		|	
		|	GROUP BY
		|		MessagesRecords.AccountingDate,
		|		MessagesRecords.Period,
		|		MessagesRecords.Recorder,
		|		MessagesRecords.Object,
		|		MessagesRecords.Hotel) AS Messages
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
		|				AND NOT MessageComments.Ref.IsClosed
		|				AND (MessageComments.Ref.ByObject = &qObject
		|						OR MessageComments.Ref.ByObject = &qObjectReservation
		|							AND &qObjectReservationIsFilled)
		|				AND (MessageComments.Ref.ValidFromDate <= &qEndOfPeriod
		|						OR MessageComments.Ref.ValidFromDate = &qEmptyDate
		|						OR &qDateIsEmpty)
		|				AND (MessageComments.Ref.ValidToDate >= &qBeginOfPeriod
		|						OR MessageComments.Ref.ValidToDate = &qEmptyDate
		|						OR &qDateIsEmpty)
		|			
		|			GROUP BY
		|				MessageComments.Ref) AS LastCommentLineNumbers
		|				INNER JOIN Document.Message.Comments AS LastComments
		|				ON LastCommentLineNumbers.Ref = LastComments.Ref
		|					AND LastCommentLineNumbers.LastCommentLineNumber = LastComments.LineNumber) AS MessagesLastComments
		|		ON Messages.Recorder = MessagesLastComments.Ref
		|
		|ORDER BY
		|	AccountingDate,
		|	ValidFromDate,
		|	Messages.Period DESC";
		qGetMsgs.SetParameter("qObject", pObject);
		vObjectReservation = Undefined;
		If ValueIsFilled(pObject) Then
			If TypeOf(pObject) = Type("DocumentRef.Accommodation") Then
				vObjectReservation = pObject.Reservation;
			EndIf;
		EndIf;
		qGetMsgs.SetParameter("qObjectReservation", vObjectReservation);
		qGetMsgs.SetParameter("qObjectReservationIsFilled", ValueIsFilled(vObjectReservation));
		qGetMsgs.SetParameter("qHasRightsToSeeAllMessages", cmCheckUserPermissions("HavePermissionToSeeAllMessages"));
		qGetMsgs.SetParameter("qFilterByEmployeeAndDepartment", pFilterByEmployeeAndDepartment);
		qGetMsgs.Setparameter("qDepartment", ?(ValueIsFilled(Sessionparameters.CurrentUser), Sessionparameters.CurrentUser.Department, Catalogs.Departments.EmptyRef()));
		qGetMsgs.Setparameter("qEmployee", Sessionparameters.CurrentUser);
	EndIf;
	If pShowTotals Then
		qGetMsgs.Text = qGetMsgs.Text + "
		|TOTALS 
		|	SUM(Counter)
		|BY
		|	AccountingDate";
	EndIf;
	qGetMsgs.SetParameter("qDate", BegOfDay(pDate));
	qGetMsgs.SetParameter("qBeginOfPeriod", BegOfDay(pDate));
	qGetMsgs.SetParameter("qEndOfPeriod", EndOfDay(pDate) + 1);
	qGetMsgs.SetParameter("qPeriodIsEmpty", Not ValueIsFilled(pDate));
	qGetMsgs.SetParameter("qEmptyDate", '00010101');
	qGetMsgs.SetParameter("qDateIsEmpty", Not ValueIsFilled(pDate));
	qGetMsgs.SetParameter("qShowClosed", pShowClosed);
	qGetMsgs.SetParameter("qShowPopUpOnly", pShowPopUpOnly);
	qGetMsgs.SetParameter("qShowClosedOnly", pShowClosedOnly); 
	qGetMsgs.SetParameter("qHotelList", pHotelList);
	qGetMsgs.SetParameter("qHotelListIsEmpty", pHotelList = Undefined);
	vMsgs = qGetMsgs.Execute().Unload();
	Return vMsgs;
EndFunction // cmGetMessagesForObject

// -----------------------------------------------------------------------------
// Description: Returns number of active messages for the given object
// Parameters: Object reference
// Return value: Number of active messages
// -----------------------------------------------------------------------------
Function cmGetNumberOfMessagesForObject(pObject = Undefined, pPopUpOnly = False, pType = Undefined) Export
	vCount = 0;
	// Build and run query
	qGetMsgs = New Query;
	If TypeOf(pObject) = Type("CatalogRef.Employees") Then
		qGetMsgs.Text = 
		"SELECT
		|	COUNT(Messages.Recorder) AS Count
		|FROM
		|	InformationRegister.Messages AS Messages
		|WHERE
		|	NOT Messages.IsClosed
		|	AND (NOT &qPopUpOnly
		|			OR &qPopUpOnly
		|				AND Messages.PopUp)
		|	AND (Messages.ForEmployee = &qEmployee
		|			OR (Messages.Author = &qEmployee AND NOT &qPopUpOnly)
		|			OR &qDepartment <> UNDEFINED
		|				AND Messages.ForDepartment = &qDepartment
		|			OR Messages.ForEmployee = &qEmptyEmployeeRef
		|				AND Messages.ForDepartment = &qEmptyDepartmentRef
		|				AND Messages.Object = UNDEFINED
		|				AND &qHasRightsToSeeAllMessages)
		|	AND Messages.ValidFromDate <= &qPeriod
		|	AND (Messages.ValidToDate > &qPeriod
		|			OR Messages.ValidToDate = &qEmptyDate)
		|	AND (Messages.Type = &qType OR &qType = UNDEFINED)";
		qGetMsgs.SetParameter("qEmployee", pObject);
		If ValueIsFilled(pObject) And ValueIsFilled(pObject.Department) Then
			qGetMsgs.SetParameter("qDepartment", pObject.Department);
		Else
			qGetMsgs.SetParameter("qDepartment", Undefined);
		EndIf;
		qGetMsgs.SetParameter("qEmptyEmployeeRef", Catalogs.Employees.EmptyRef());
		qGetMsgs.SetParameter("qEmptyDepartmentRef", Catalogs.Departments.EmptyRef());
		qGetMsgs.SetParameter("qPopUpOnly", pPopUpOnly);
		qGetMsgs.SetParameter("qHasRightsToSeeAllMessages", cmCheckUserPermissions("HavePermissionToSeeAllMessages"));
		qGetMsgs.SetParameter("qType", pType);
	Else
		qGetMsgs.Text = 
		"SELECT
		|	COUNT(MessageDocuments.Recorder) AS Count
		|FROM
		|	(SELECT
		|		Messages.Recorder AS Recorder
		|	FROM
		|		InformationRegister.Messages AS Messages
		|	WHERE
		|		(Messages.Object = &qObject
		|				OR Messages.Object = &qObjectReservation
		|					AND &qObjectReservationIsFilled)
		|		AND (NOT &qPopUp
		|				OR &qPopUp
		|					AND Messages.PopUp)
		|		AND NOT Messages.IsClosed
		|		AND Messages.ValidFromDate <= &qPeriod
		|		AND (Messages.ValidToDate > &qPeriod
		|				OR Messages.ValidToDate = &qEmptyDate)
		|	
		|	GROUP BY
		|		Messages.Recorder) AS MessageDocuments";
		qGetMsgs.SetParameter("qObject", pObject);
		vObjectReservation = Undefined;
		If ValueIsFilled(pObject) Then
			If TypeOf(pObject) = Type("DocumentRef.Accommodation") Then
				vObjectReservation = pObject.Reservation;
			EndIf;
		EndIf;
		qGetMsgs.SetParameter("qObjectReservation", vObjectReservation);
		qGetMsgs.SetParameter("qObjectReservationIsFilled", ValueIsFilled(vObjectReservation));
	EndIf;
	qGetMsgs.SetParameter("qPeriod", CurrentSessionDate());
	qGetMsgs.SetParameter("qEmptyDate", '00010101');
	qGetMsgs.SetParameter("qPopUp", pPopUpOnly);
	vMsgs = qGetMsgs.Execute().Unload();
	For Each vMsgsRow In vMsgs Do
		vCount = vMsgsRow.Count;
		Break;
	EndDo;
	Return vCount;
EndFunction // cmGetNumberOfMessagesForObject

// -----------------------------------------------------------------------------
// Description: Returns number of pop up messages for the given employee
// Parameters: Employee reference
// Return value: Number of active employee pop up messages
// -----------------------------------------------------------------------------
Function cmGetNumberOfPopUpMessagesForEmployee(pEmployee = Undefined) Export
	// Build and run query
	qGetMsgs = New Query;
	qGetMsgs.Text = 
	"SELECT
	|	COUNT(Messages.Recorder) AS Count
	|FROM
	|	InformationRegister.Messages AS Messages
	|WHERE
	|	(Messages.ForEmployee = &qEmployee
	|			OR &qDepartment <> UNDEFINED
	|				AND Messages.ForDepartment = &qDepartment
	|			OR Messages.ForEmployee = &qEmptyEmployeeRef
	|				AND Messages.ForDepartment = &qEmptyDepartmentRef
	|				AND Messages.Object = UNDEFINED
	|				AND &qHasRightsToSeeAllMessages)
	|	AND Messages.PopUp
	|	AND Messages.Type = VALUE(Enum.MessageTypes.Message)
	|	AND NOT Messages.IsClosed
	|	AND Messages.ValidFromDate <= &qPeriod
	|	AND (Messages.ValidToDate > &qPeriod
	|			OR Messages.ValidToDate = &qEmptyDate)";
	qGetMsgs.SetParameter("qEmployee", pEmployee);
	If ValueIsFilled(pEmployee) And ValueIsFilled(pEmployee.Department) Then
		qGetMsgs.SetParameter("qDepartment", pEmployee.Department);
	Else
		qGetMsgs.SetParameter("qDepartment", Undefined);
	EndIf;
	qGetMsgs.SetParameter("qEmptyEmployeeRef", Catalogs.Employees.EmptyRef());
	qGetMsgs.SetParameter("qEmptyDepartmentRef", Catalogs.Departments.EmptyRef());
	qGetMsgs.SetParameter("qPeriod", CurrentSessionDate());
	qGetMsgs.SetParameter("qEmptyDate", '00010101');
	qGetMsgs.SetParameter("qHasRightsToSeeAllMessages", cmCheckUserPermissions("HavePermissionToSeeAllMessages"));
	vMsgs = qGetMsgs.Execute().Unload();
	vCount = vMsgs.Get(0).Count;
	If Not cmIsNumber(vCount) Then
		vCount = 0;
	EndIf;
	Return vCount;
EndFunction // cmGetNumberOfPopUpMessagesForEmployee

// -----------------------------------------------------------------------------
// Description: Applies Messages button appearance
// Parameters: Messages button control, Object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmMessagesButtonAppearance(pButton, pObject) Export
	If ValueIsFilled(pObject) Then
		vCount = cmGetNumberOfMessagesForObject(pObject);
		pButton.Enabled = True;
		If vCount = 0 Then
			pButton.Caption = NStr("en='Tasks (F11)';ru='Задачи (F11)';de='Aufgaben (F11)'");
			pButton.ButtonBackColor = StyleColors.ButtonBackColor;
			pButton.ButtonTextColor = StyleColors.ButtonTextColor;
		Else
			pButton.Caption = NStr("ru = 'Задачи (F11) - " + vCount + "'; en = 'Tasks (F11) - " + vCount + "'; de = 'Aufgaben (F11) - " + vCount + "'");
			pButton.ButtonBackColor = StyleColors.SpecialTextColor;
			pButton.ButtonTextColor = StyleColors.FieldSelectedTextColor;
		EndIf;
	Else
		pButton.Caption = NStr("en='Tasks (F11)';ru='Задачи (F11)';de='Aufgaben (F11)'");
		pButton.ButtonBackColor = StyleColors.ButtonBackColor;
		pButton.ButtonTextColor = StyleColors.ButtonTextColor;
		pButton.Enabled = True;
	EndIf;
EndProcedure // cmMessagesButtonAppearance
	
// -----------------------------------------------------------------------------
// Description: Returns active messages value table for the given objects list
// Parameters: Value list with objects
// Return value: Value table with active messages
// -----------------------------------------------------------------------------
Function cmGetMessagesForObjectsList(pObjects) Export
	// Get the table of messages
	vQryMsg = New Query();
	vQryMsg.Text = 
	"SELECT
	|	Messages.ByObject AS Object,
	|	Messages.Author AS Author,
	|	Messages.Remarks AS Remarks,
	|	Messages.Ref AS Recorder
	|FROM
	|	Document.Message AS Messages
	|WHERE
	|	Messages.Posted
	|	AND (NOT Messages.IsClosed)
	|	AND Messages.ByObject IN (&qObjects)
	|	AND Messages.ValidFromDate <= &qPeriod
	|	AND (Messages.ValidToDate > &qPeriod
	|			OR Messages.ValidToDate = &qEmptyDate)
	|
	|ORDER BY
	|	Messages.PointInTime DESC";
	vQryMsg.SetParameter("qObjects", pObjects);
	vQryMsg.SetParameter("qPeriod", CurrentSessionDate());
	vQryMsg.SetParameter("qEmptyDate", '00010101');
	vMessages = vQryMsg.Execute().Unload();
	Return vMessages;
EndFunction // cmGetMessagesForObjectsList

// -----------------------------------------------------------------------------
// Description: Returns string with messages text
// Parameters: Value table with messages, Object
// Return value: String with joined message texts
// -----------------------------------------------------------------------------
Function cmGetMessagesPresentationForObject(pMessages, pObject) Export
	vMessagesStr = "";
	vMessagesArray = pMessages.FindRows(New Structure("Object", pObject));
	For Each vMessagesRow In vMessagesArray Do
		If vMessagesStr <> "" Then
			vMessagesStr = vMessagesStr + Chars.LF;
		EndIf;
		vMessagesStr = vMessagesStr + TrimAll(vMessagesRow.Remarks);
	EndDo;
	Return vMessagesStr;
EndFunction // cmGetMessagesPresentationForObject

// -----------------------------------------------------------------------------
// Description: Returns value table with all message statuses
// Parameters: None
// Return value: Value table with all message status catalog items
// -----------------------------------------------------------------------------
Function cmGetAllMessageStatuses(pType = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MessageStatuses.Ref AS MessageStatus,
	|	MessageStatuses.Code AS Code,
	|	MessageStatuses.IsClosed AS IsClosed,
	|	MessageStatuses.Description AS Description,
	|	MessageStatuses.SortCode AS SortCode
	|FROM
	|	Catalog.MessageStatuses AS MessageStatuses
	|WHERE
	|	(MessageStatuses.Type = &qType
	|			OR &qType = UNDEFINED)
	|	AND NOT MessageStatuses.DeletionMark
	|	AND NOT MessageStatuses.IsFolder
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qType", pType);
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllMessageStatuses

// -----------------------------------------------------------------------------
// Description: Returns value table with all message types
// Parameters: None
// Return value: Value table with all message type catalog items
// -----------------------------------------------------------------------------
Function cmGetAllMessageTypes() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MessageTypes.Ref AS MessageType,
	|	MessageTypes.Code AS Code,
	|	MessageTypes.Description AS Description,
	|	MessageTypes.SortCode AS SortCode
	|FROM
	|	Catalog.MessageTypes AS MessageTypes
	|WHERE
	|	MessageTypes.DeletionMark = FALSE
	|	AND MessageTypes.IsFolder = FALSE
	|
	|ORDER BY
	|	SortCode";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllMessageTypes

// -----------------------------------------------------------------------------
// Description: Returns all active messages for the given employee
// Parameters: Employee
// Return value: Value list with message documents
// -----------------------------------------------------------------------------
Function cmGetEmployeeMessages(pEmployee) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Messages.Recorder AS Ref
	|FROM
	|	InformationRegister.Messages AS Messages
	|WHERE
	|	(Messages.Author = &qEmployee
	|			OR Messages.ForEmployee = &qEmployee
	|			OR &qDepartment <> UNDEFINED
	|				AND Messages.ForDepartment = &qDepartment
	|			OR Messages.ForEmployee = &qEmptyEmployee
	|				AND Messages.ForDepartment = &qEmptyDepartment
	|				AND Messages.Object = UNDEFINED)
	|
	|ORDER BY
	|	Messages.Recorder.PointInTime";
	vQry.SetParameter("qEmployee", pEmployee);
	vQry.SetParameter("qDepartment", ?(ValueIsFilled(pEmployee), pEmployee.Department, Undefined));
	vQry.SetParameter("qEmptyEmployee", Catalogs.Employees.EmptyRef());
	vQry.SetParameter("qEmptyDepartment", Catalogs.Departments.EmptyRef());
	vDocsArray = vQry.Execute().Unload().UnloadColumn("Ref");
	vDocsList = New ValueList();
	If vDocsArray.Count() > 0 Then
		vDocsList.LoadValues(vDocsArray);
	EndIf;
	Return vDocsList;
EndFunction // cmGetEmployeeMessages

// -----------------------------------------------------------------------------
// Description: Sends message to the given employee
// Parameters: Employee, Message text, Message status, Is pop up message
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSendMessageToEmployee(pEmployee, pMsg, pMessageStatus = Undefined, pPopUp = False, pType = Undefined) Export
	Try
		vMsgObj = Documents.Message.CreateDocument();
		vMsgObj.pmFillAttributesWithDefaultValues();
		If ValueIsFilled(pMessageStatus) Then
			vMsgObj.MessageStatus = pMessageStatus;
			vMsgObj.IsClosed = vMsgObj.MessageStatus.IsClosed;
		EndIf;
		vMsgObj.Type = ?(pType = Undefined, Enums.MessageTypes.Message, pType);
		vMsgObj.ForEmployee = pEmployee;
		vMsgObj.Remarks = pMsg;
		vMsgObj.PopUp = pPopUp;
		vMsgObj.Write(DocumentWriteMode.Posting);
	Except
		// If, for any reson the document can not be written the above processing has to continued
		WriteLogEvent("SendMessageToEmployee",EventLogLevel.Error,,,ErrorDescription());
	EndTry;
EndProcedure // cmSendMessageToEmployee

// -----------------------------------------------------------------------------
// Description: Sends message to all employees in the department
// Parameters: Department, Message text, Message status, Is pop up message
// Return value: None
// -----------------------------------------------------------------------------
Function cmSendMessageToDepartment(pDepartment, pMsg, pMessageStatus = Undefined, pPopUp = False, pObject = Undefined, pSendBySMS = False, pOrder = Undefined, pType = Undefined) Export
	vMsgObj = Documents.Message.CreateDocument();
	vMsgObj.pmFillAttributesWithDefaultValues();
	If ValueIsFilled(pMessageStatus) Then
		vMsgObj.MessageStatus = pMessageStatus;
		vMsgObj.IsClosed = vMsgObj.MessageStatus.IsClosed;
	EndIf;
	vMsgObj.ForDepartment = pDepartment;
	If ValueIsFilled(pObject) Then
		vMsgObj.ByObject = pObject;
	EndIf;
	vMsgObj.Type = ?(pType = Undefined, Enums.MessageTypes.Message, pType);
	vMsgObj.Remarks = pMsg;
	vMsgObj.PopUp = pPopUp;
	vMsgObj.SendBySMS = pSendBySMS;
	vMsgObj.SMSIsSent = False;
	If ValueIsFilled(pOrder) Then
		vMsgObj.ByOrder = pOrder;
	EndIf;
	vMsgObj.Write(DocumentWriteMode.Posting);
	Return vMsgObj.Ref;
EndFunction // cmSendMessageToDepartment

// -----------------------------------------------------------------------------
// Description: Sends message to the object
// Parameters: Object reference, Message text, Message status, Is pop up message
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSendMessageToObject(pObjectRef, pMsg, pMessageStatus = Undefined, pPopUp = False, pType = Undefined) Export
	vMsgObj = Documents.Message.CreateDocument();
	vMsgObj.pmFillAttributesWithDefaultValues();
	If ValueIsFilled(pMessageStatus) Then
		vMsgObj.MessageStatus = pMessageStatus;
		vMsgObj.IsClosed = vMsgObj.MessageStatus.IsClosed;
	EndIf;
	If Not ValueIsFilled(pType) Then
		vMsgObj.Type = Enums.MessageTypes.Task;
	Else
		vMsgObj.Type = pType;
	EndIf;
	vMsgObj.ByObject = pObjectRef;
	vMsgObj.Remarks = pMsg;
	vMsgObj.PopUp = pPopUp;
	vMsgObj.Write(DocumentWriteMode.Posting);
EndProcedure // cmSendMessageToObject

#EndRegion
