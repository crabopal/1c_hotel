
#Region Private

// -----------------------------------------------------------------------------
// Description: Returns value table with room statuses
// Parameters: External system code, Language code, ..., Return type
// Return value: Value table with rooms and room statuses
// -----------------------------------------------------------------------------
Function cmGetRoomsWithStatuses(pExtSystemCode, pLanguageCode = "RU", pHotelCode, pRoomSectionCode, pRoomStatusCode, pRoomTypeCode, pOutputType = "CSV", pGetGuests = False) Export
	vFunc = NStr("en = 'Get rooms with statuses'; de = 'Zimmerliste mit Status erhalten'; ru = 'Получить список номеров с статусами'"); 
	vInputParameters = NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExtSystemCode + Chars.LF 
					   + NStr("en='Language code: ';ru='Код языка: ';de='Sprachencode: '") + pLanguageCode + Chars.LF 
					   + NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code des Hotels: '") + pHotelCode + Chars.LF 
					   + NStr("en='Section code: ';ru='Код секции номеров: ';de='Code der Zimmersektion: '") + pRoomSectionCode + Chars.LF 
					   + NStr("en='Room status code: ';ru='Код статуса номера: ';de='Zimmerstatuscode: '") + pRoomStatusCode + Chars.LF 
					   + NStr("en='Room type code: ';ru='Код типа номера: ';de='Zimmertypcode: '") + pRoomTypeCode + Chars.LF 
					   + NStr("en='Get guests: ';ru='Получать гостей: ';de='Zimmertypcode: '") + pGetGuests;
	// Retrieve language
	vLanguage = cmGetLanguageByCode(pLanguageCode);
	// Retreive hotel reference 
	vHotel = Catalogs.Hotels.EmptyRef();
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExtSystemCode);
	EndIf; 
	vWriteDebug = False;				   
	vInteraction = Undefined;					
	If Not IsBlankString(pExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then  
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	If vWriteDebug Then
		vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vInputParameters);
	EndIf;
	// Retrieve parameter references based on codes
	vRoomType = Catalogs.RoomTypes.EmptyRef();
	If Not IsBlankString(pRoomTypeCode) Then
		vRoomType = cmGetObjectRefByExternalSystemCode(vHotel, pExtSystemCode, "RoomTypes", pRoomTypeCode);
	EndIf;
	vRoomSection = Catalogs.RoomSections.EmptyRef();
	If Not IsBlankString(pRoomSectionCode) Then
		vRoomSection = cmGetObjectRefByExternalSystemCode(vHotel, pExtSystemCode, "RoomSections", pRoomSectionCode);
	EndIf;
	vRoomStatus = Catalogs.RoomStatuses.EmptyRef();
	If Not IsBlankString(pRoomStatusCode) Then
		vRoomStatus = cmGetObjectRefByExternalSystemCode(vHotel, pExtSystemCode, "RoomStatuses", pRoomStatusCode);
	EndIf;
	// Run query to get active room tasks
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Message.Ref AS Ref,
	|	Message.ByObject AS Room,
	|	Message.Number AS TaskNumber,
	|	Message.Date AS TaskDate,
	|	Message.MessageType AS TaskType,
	|	Message.Remarks AS MessageText,
	|	Message.Author AS Author,
	|	Message.CloseToDate AS CloseToDate
	|FROM
	|	Document.Message AS Message
	|WHERE
	|	Message.Posted
	|	AND Message.ByObject REFS Catalog.Rooms
	|	AND Message.ByObject <> &qEmptyRoom
	|	AND NOT Message.IsClosed
	|	AND NOT Message.ByObject.DeletionMark
	|	AND Message.ByObject.OperationStartDate <= &qPeriod
	|	AND (Message.ByObject.OperationEndDate > &qPeriod
	|			OR Message.ByObject.OperationEndDate = &qEmptyDate)
	|	AND (Message.ByObject.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qRoomSectionIsEmpty)
	|	AND (Message.ByObject.RoomStatus IN HIERARCHY (&qRoomStatus)
	|			OR &qRoomStatusIsEmpty)
	|	AND (Message.ByObject.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qRoomTypeIsEmpty)
	|	AND (Message.ByObject.Owner = &qHotel
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	Message.ByObject.SortCode,
	|	Message.MessageType.SortCode,
	|	Message.MessageType.Code,
	|	Message.PointInTime";
	vQry.SetParameter("qPeriod", CurrentSessionDate());
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qHotel", vHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(vHotel));
	vQry.SetParameter("qRoomType", vRoomType);
	vQry.SetParameter("qRoomTypeIsEmpty", Not ValueIsFilled(vRoomType));
	vQry.SetParameter("qRoomSection", vRoomSection);
	vQry.SetParameter("qRoomSectionIsEmpty", Not ValueIsFilled(vRoomSection));
	vQry.SetParameter("qRoomStatus", vRoomStatus);
	vQry.SetParameter("qRoomStatusIsEmpty", Not ValueIsFilled(vRoomStatus));
	vTasks = vQry.Execute().Unload();
	// Run query to get list of rooms
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 999999
	|	Rooms.Ref AS Room,
	|	Rooms.Description AS Description,
	|	Rooms.RoomType AS RoomType,
	|	Rooms.RoomType.Code AS RoomTypeCode,
	|	Rooms.RoomSection AS RoomSection,
	|	Rooms.RoomSection.Code AS RoomSectionCode,
	|	Rooms.RoomSection.Description AS RoomSectionDescription,
	|	Rooms.RoomStatus AS RoomStatus,
	|	Rooms.RoomStatus.Code AS RoomStatusCode,
	|	Rooms.RoomStatus.Description AS RoomStatusDescription,
	|	Rooms.Parent AS Parent,
	|	Rooms.Parent.Description AS ParentDescription,
	|	RoomStatusChangeHistorySliceLast.Period AS StatusLastChangeTime,
	|	CASE
	|		WHEN RoomStatusChangeHistorySliceLast.User.Code IS NULL
	|			THEN NULL
	|		ELSE RoomStatusChangeHistorySliceLast.User
	|	END AS StatusLastChangeEmployee,
	|	Rooms.RoomStatus.RoomStatusIcon AS RoomStatusIcon,
	|	TodayReservations.CheckInDate AS CheckInDate
	|FROM
	|	Catalog.Rooms AS Rooms
	|		LEFT JOIN InformationRegister.RoomStatusChangeHistory.SliceLast(
	|				&qPeriod,
	|				Room.Owner = &qHotel
	|					OR &qEmptyHotel) AS RoomStatusChangeHistorySliceLast
	|		ON Rooms.Ref = RoomStatusChangeHistorySliceLast.Room
	|		LEFT JOIN (SELECT
	|			Reservations.Room AS Room,
	|			MIN(Reservations.CheckInDate) AS CheckInDate
	|		FROM
	|			AccumulationRegister.RoomInventory AS Reservations
	|		WHERE
	|			Reservations.IsReservation
	|			AND Reservations.RecordType = &qExpense
	|			AND Reservations.CheckInDate >= &qPeriodFrom
	|			AND Reservations.CheckInDate <= &qPeriodTo
	|			AND (Reservations.Hotel = &qHotel
	|					OR &qEmptyHotel)
	|			AND Reservations.Room <> &qEmptyRoom
	|		
	|		GROUP BY
	|			Reservations.Room) AS TodayReservations
	|		ON Rooms.Ref = TodayReservations.Room
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND Rooms.OperationStartDate <= &qPeriod
	|	AND (Rooms.OperationEndDate > &qPeriod
	|			OR Rooms.OperationEndDate = &qEmptyDate)
	|	AND (Rooms.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qRoomSectionIsEmpty)
	|	AND (Rooms.RoomStatus IN HIERARCHY (&qRoomStatus)
	|			OR &qRoomStatusIsEmpty)
	|	AND (Rooms.RoomType IN HIERARCHY (&qRoomType)
	|			OR &qRoomTypeIsEmpty)
	|	AND (Rooms.Owner = &qHotel
	|			OR &qEmptyHotel)
	|
	|ORDER BY
	|	Rooms.SortCode";
	vQry.SetParameter("qPeriod", CurrentSessionDate());
	vQry.SetParameter("qPeriodFrom", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qPeriodTo", EndOfDay(CurrentSessionDate()));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qHotel", vHotel);
	vQry.SetParameter("qEmptyHotel", Not ValueIsFilled(vHotel));
	vQry.SetParameter("qRoomType", vRoomType);
	vQry.SetParameter("qRoomTypeIsEmpty", Not ValueIsFilled(vRoomType));
	vQry.SetParameter("qRoomSection", vRoomSection);
	vQry.SetParameter("qRoomSectionIsEmpty", Not ValueIsFilled(vRoomSection));
	vQry.SetParameter("qRoomStatus", vRoomStatus);
	vQry.SetParameter("qRoomStatusIsEmpty", Not ValueIsFilled(vRoomStatus));
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vRooms = vQry.Execute().Unload();
	
	vGuests = Undefined;
	If pGetGuests Then
		vRoomRefArray = vRooms.UnloadColumn("Room");
		
		vQuery = New Query;
		vQuery.Text = 
		"SELECT DISTINCT
		|	RoomInventory.Room AS Room,
		|	RoomInventory.Guest AS Guest,
		|	ISNULL(RoomInventory.Guest.LastName, """") AS LastName,
		|	ISNULL(RoomInventory.Guest.FirstName, """") AS FirstName,
		|	ISNULL(RoomInventory.Guest.SecondName, """") AS SecondName,
		|	RoomInventory.Guest.Sex AS Sex,
		|	RoomInventory.Guest.ClientType AS ClientType,
		|	RoomInventory.Guest.AgeRange AS AgeRange,
		|	RoomInventory.Guest.DateOfBirth AS DateOfBirth,
		|	RoomInventory.CheckInDate AS CheckInDate,
		|	RoomInventory.CheckOutDate AS CheckOutDate,
		|	RoomInventory.IsReservation AS IsExpected,
		|	CAST(RoomInventory.Recorder.HousekeepingRemarks AS STRING(150)) AS HousekeepingRemarks
		|FROM
		|	AccumulationRegister.RoomInventory AS RoomInventory
		|WHERE
		|	RoomInventory.Room IN(&qRooms)
		|	AND RoomInventory.Recorder.AccommodationStatus.IsInHouse
		|	AND NOT RoomInventory.IsReservation
		|	AND NOT RoomInventory.Guest IS NULL
		|	AND RoomInventory.PeriodFrom <= &qPeriod
		|	AND (RoomInventory.PeriodTo > &qPeriod
		|			OR RoomInventory.PeriodTo = RoomInventory.CheckOutDate)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	RoomInventory.Room,
		|	RoomInventory.Guest,
		|	ISNULL(RoomInventory.Guest.LastName, """"),
		|	ISNULL(RoomInventory.Guest.FirstName, """"),
		|	ISNULL(RoomInventory.Guest.SecondName, """"),
		|	RoomInventory.Guest.Sex,
		|	RoomInventory.Guest.ClientType,
		|	RoomInventory.Guest.AgeRange,
		|	RoomInventory.Guest.DateOfBirth,
		|	RoomInventory.CheckInDate,
		|	RoomInventory.CheckOutDate,
		|	RoomInventory.IsReservation,
		|	CAST(RoomInventory.Recorder.HousekeepingRemarks AS STRING(150))
		|FROM
		|	AccumulationRegister.RoomInventory AS RoomInventory
		|WHERE
		|	RoomInventory.Room IN(&qRooms)
		|	AND RoomInventory.Period >= &qPeriodFrom
		|	AND RoomInventory.Period <= &qPeriodTo
		|	AND RoomInventory.IsReservation
		|	AND NOT RoomInventory.Guest IS NULL";
		vQuery.SetParameter("qPeriod", 	CurrentSessionDate());
		vQuery.SetParameter("qPeriodFrom", 	BegOfDay(CurrentSessionDate()));
		vQuery.SetParameter("qPeriodTo", 	EndOfDay(CurrentSessionDate()));
		vQuery.SetParameter("qRooms", 		vRoomRefArray);
		
		vGuests = vQuery.Execute().Unload();
	EndIf;
	
	// Initialize return values
	vRetStr = "";
	For Each vRoomsRow In vRooms Do
		vChangeTimePresentation = "";
		If ValueIsFilled(vRoomsRow.StatusLastChangeTime) Then
			If BegOfDay(vRoomsRow.StatusLastChangeTime) = BegOfDay(CurrentSessionDate()) Then
				vChangeTimePresentation = Format(vRoomsRow.StatusLastChangeTime, "DF=HH:mm");
			Else
				vChangeTimePresentation = Format(vRoomsRow.StatusLastChangeTime, "DF='dd.MM HH:mm'");
			EndIf;
		EndIf;
		vCheckInTimePresentation = "";
		If ValueIsFilled(vRoomsRow.CheckInDate) Then
			vCheckInTimePresentation = Format(vRoomsRow.CheckInDate, "DF=HH:mm");
		EndIf;  
		vEmployeeDescr = ?(ValueIsFilled(vRoomsRow.StatusLastChangeEmployee), Catalogs.Employees.pmGetEmployeeDescription(vRoomsRow.StatusLastChangeEmployee, vLanguage), "");
		vRetStr = vRetStr + """" + TrimAll(vRoomsRow.Description) + """" 
						  + ", """ + TrimAll(vRoomsRow.RoomTypeCode) + """" 
						  + ", """ + cmRemoveComma(Catalogs.RoomTypes.pmGetRoomTypeDescription(vRoomsRow.RoomType, vLanguage)) + """" 
						  + ", """ + TrimAll(vRoomsRow.RoomSectionCode) + """" 
						  + ", """ + cmRemoveComma(TrimAll(vRoomsRow.RoomSectionDescription)) + """" 
						  + ", """ + TrimAll(vRoomsRow.RoomStatusCode) + """" 
						  + ", """ + cmRemoveComma(TrimAll(vRoomsRow.RoomStatusDescription)) + """" 
						  + ", """ + TrimAll(vRoomsRow.ParentDescription) + """" 
						  + ", """ + vEmployeeDescr + """" 
						  + ", """ + Format(?(ValueIsFilled(vRoomsRow.StatusLastChangeTime), vRoomsRow.StatusLastChangeTime, '00010101'), "DF='yyyy.MM.dd HH:mm:ss'") + """" 
						  + ", """ + TrimAll(vRoomsRow.RoomStatusIcon) + """" 
						  + ", """ + TrimAll(vChangeTimePresentation) + """" 
						  + ", """ + TrimAll(vCheckInTimePresentation) + """" + Chars.LF;
	EndDo;
	vResponse = Undefined;
	If pOutputType = "CSV" Then  
		vResponse = vRetStr;
		vLogStr = vRetStr;
	Else
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "GetRoomsWithStatuses"));
		vRetRowType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "GetRoomsWithStatusesRow");
		For Each vRoomsRow In vRooms Do      
			vEmployeeDescr = ?(ValueIsFilled(vRoomsRow.StatusLastChangeEmployee), Catalogs.Employees.pmGetEmployeeDescription(vRoomsRow.StatusLastChangeEmployee, vLanguage), "");
			vRetRow = XDTOFactory.Create(vRetRowType);
			vRetRow.Room = TrimAll(vRoomsRow.Description);
			vRetRow.RoomTypeCode = TrimAll(vRoomsRow.RoomTypeCode);
			vRetRow.RoomTypeDescription = Left(Catalogs.RoomTypes.pmGetRoomTypeDescription(vRoomsRow.RoomType, vLanguage), 170);
			vRetRow.RoomStatusCode = TrimAll(vRoomsRow.RoomStatusCode);
			vRetRow.RoomStatusDescription = Left(TrimAll(vRoomsRow.RoomStatusDescription), 170);
			vRetRow.RoomSectionCode = TrimAll(vRoomsRow.RoomSectionCode);
			vRetRow.RoomSectionDescription = Left(TrimAll(vRoomsRow.RoomSectionDescription), 170);
			vRetRow.RoomParent = TrimAll(vRoomsRow.ParentDescription);
			vRetRow.StatusLastChangeEmployee = vEmployeeDescr;
			vRetRow.StatusLastChangeTime = '00010101';
			If ValueIsFilled(vRoomsRow.StatusLastChangeTime) Then
				vRetRow.StatusLastChangeTime = vRoomsRow.StatusLastChangeTime;
			EndIf;
			vRetRow.RoomStatusIcon = TrimAll(vRoomsRow.RoomStatusIcon);
			If ValueIsFilled(vRoomsRow.StatusLastChangeTime) Then
				If BegOfDay(vRoomsRow.StatusLastChangeTime) = BegOfDay(CurrentSessionDate()) Then
					vRetRow.StatusLastChangeTimePresentation = Format(vRoomsRow.StatusLastChangeTime, "DF=HH:mm");
				Else
					vRetRow.StatusLastChangeTimePresentation = Format(vRoomsRow.StatusLastChangeTime, "DF='dd.MM HH:mm'");
				EndIf;
			EndIf;
			vCheckInTimePresentation = "";
			If ValueIsFilled(vRoomsRow.CheckInDate) Then
				vCheckInTimePresentation = Format(vRoomsRow.CheckInDate, "DF=HH:mm");
			EndIf;
			vRetRow.CheckInTime = vCheckInTimePresentation;
			
			// Add active room tasks
			vRoomTasksArray = vTasks.FindRows(New Structure("Room", vRoomsRow.Room));
			vActiveTasks = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "ActiveTasks"));
			vTaskType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "Task");
			For Each vRoomTaskRow In vRoomTasksArray Do
				vTaskRow = XDTOFactory.Create(vTaskType);
				
				vTaskRow.TaskNumber = cmGetDocumentNumberPresentation(vRoomTaskRow.TaskNumber);
				vTaskRow.TaskDate = vRoomTaskRow.TaskDate;
				vTaskRow.TaskType = ?(ValueIsFilled(vRoomTaskRow.TaskType), TrimAll(vRoomTaskRow.TaskType.Code), "");
				vTaskRow.TaskTypeDescription = ?(ValueIsFilled(vRoomTaskRow.TaskType), cmGetObjectExternalSystemCodeByRef(vRoomsRow.Room.Owner, "HOUSEKEEPING", "MessageTypes", vRoomTaskRow.TaskType, False), "");
				vTaskRow.MessageText = TrimAll(vRoomTaskRow.MessageText);
				
				vActiveTasks.Task.Add(vTaskRow);
			EndDo;
			vRetRow.ActiveTasks = vActiveTasks;
			
			//Guests
			vGuestListXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "GuestList"));
			If pGetGuests And vGuests <> Undefined Then
				vNumberOfGuests 		= 0;
				vExpectedNumberOfGuests = 0;
				For each vGuestRow in vGuests Do
					If vRoomsRow.Room = vGuestRow.Room AND ValueIsFilled(vGuestRow.Guest) Then 
						vGuestListRowXDTO 						= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "GuestListRow"));
						vGuestListRowXDTO.LastName				= vGuestRow.LastName;
						vGuestListRowXDTO.FirstName				= vGuestRow.FirstName;
						vGuestListRowXDTO.SecondName			= vGuestRow.SecondName;
						
						If ValueIsFilled(vGuestRow.ClientType) Then
							vGuestListRowXDTO.ClientTypeDescription	= vGuestRow.ClientType.Description;
						EndIf;
						
						If ValueIsFilled(vGuestRow.Sex) Then
							vGuestListRowXDTO.Sex					= String(vGuestRow.Sex);
						EndIf;
						
						If ValueIsFilled(vGuestRow.AgeRange) Then
							vGuestListRowXDTO.AgeRange				= vGuestRow.AgeRange.Description;
						EndIf;
						
						vGuestListRowXDTO.DateOfBirth			= vGuestRow.DateOfBirth;
						vGuestListRowXDTO.CheckInDate			= vGuestRow.CheckInDate;
						vGuestListRowXDTO.CheckOutDate			= vGuestRow.CheckOutDate;
						vGuestListRowXDTO.IsExpected			= vGuestRow.IsExpected; 
						vGuestListRowXDTO.HousekeepingRemarks   = TrimAll(vGuestRow.HousekeepingRemarks);
						vGuestListXDTO.GuestListRow.Add(vGuestListRowXDTO);
						
						If vGuestRow.IsExpected Then
							vExpectedNumberOfGuests = vExpectedNumberOfGuests + 1;
						Else
							vNumberOfGuests = vNumberOfGuests + 1;
						EndIf;
					EndIf;
				EndDo;
				vRetRow.NumberOfGuests 			= vNumberOfGuests;
				vRetRow.ExpectedNumberOfGuests 	= vExpectedNumberOfGuests
			EndIf;			
			vRetRow.GuestList = vGuestListXDTO;
			
			vRetXDTO.GetRoomsWithStatusesRow.Add(vRetRow);
		EndDo;
		vLogStr = cmGetXMLStringFromXDTO(vRetXDTO);
		vResponse = vRetXDTO;
	EndIf; 
	
	If vWriteDebug Then
		vMsg = NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, , vLogStr, vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vLogStr);
	EndIf;
	Return vResponse;
EndFunction // cmGetRoomsWithStatuses 

// -----------------------------------------------------------------------------
// Description: Returns value table with room statuses allowed for current user
// Parameters: External system code, Language code, Return type
// Return value: Value table with room statuses list
// -----------------------------------------------------------------------------
Function cmGetRoomStatuses(pExtSystemCode, pLanguageCode = "RU", pEmployeeCode = 0, pOutputType = "CSV", pHotelCode = "") Export   
	vFunc = NStr("en = 'Get allowed room statuses list'; de = 'Liste zulässiger Zimmerstatus erhalten'; ru = 'Получить список разрешенных статусов номеров'");
	
	vInputParameters = NStr("en = 'External system code: '; de = 'Code des externen Systems: '; ru = 'Код внешней системы: '") + pExtSystemCode + Chars.LF 
						+ NStr("en = 'Language code: '; de = 'Sprachencode: '; ru = 'Код языка: '") + pLanguageCode + Chars.LF
						+ "OutputType: " + pOutputType + Chars.LF
						+ NStr("en = 'Employee code: '; de = 'Code des Mitarbeiters: '; ru = 'Код сотрудника: '") + pEmployeeCode;
	// Retreive hotel reference 
	vHotel = Catalogs.Hotels.EmptyRef();
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExtSystemCode);
	EndIf; 					
	vWriteDebug = False;				   
	vInteraction = Undefined;					
	If Not IsBlankString(pExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then  
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	If vWriteDebug Then
		vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vInputParameters);
	EndIf;					
	// Retrieve language
	vLanguage = cmGetLanguageByCode(pLanguageCode);
	// Retrieve employee by code
	vEmployee = cmGetEmployeeByPBXCode(pEmployeeCode);   
	vEmployeeDescr = ?(ValueIsFilled(vEmployee), Catalogs.Employees.pmGetEmployeeDescription(vEmployee, vLanguage), "");
	// Run query to get list of room statuses
	vRoomStatuses = cmGetAllowedRoomStatuses(vEmployee);
	// Initialize return values
	vRetStr = vEmployeeDescr + Chars.LF;
	For Each vRoomStatusesRow In vRoomStatuses Do
		vRoomStatus = vRoomStatusesRow.RoomStatus;
		vRetStr = vRetStr + """" + TrimAll(vRoomStatus.Code) + """" 
				 + ", """ + TrimAll(vRoomStatus.Description) + """" 
				 + ", """ + TrimAll(vRoomStatus.RoomStatusIcon) + """" 
				 + ", " + Format(vRoomStatus.SortCode, "ND=6; NFD=0; NZ=; NG=") + Chars.LF;
	EndDo;
	vRetStr = TrimAll(vRetStr); 
	vResponse = Undefined;
	If pOutputType = "CSV" Then  
		vResponse = vRetStr;
		vLogStr = vRetStr;
	Else
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "GetRoomStatuses"));
		vRetXDTO.EmployeeName = vEmployeeDescr;
		vRetRowType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "GetRoomStatusesRow");
		For Each vRoomStatusesRow In vRoomStatuses Do
			vRoomStatus = vRoomStatusesRow.RoomStatus;
			vRetRow = XDTOFactory.Create(vRetRowType);
			vRetRow.RoomStatusCode = TrimAll(vRoomStatus.Code);
			vRetRow.RoomStatusDescription = Left(TrimAll(vRoomStatus.Description), 170);
			vRetRow.RoomStatusIcon = TrimAll(vRoomStatus.RoomStatusIcon);
			vRetRow.RoomStatusSortCode = vRoomStatus.SortCode;
			vRetXDTO.GetRoomStatusesRow.Add(vRetRow);
		EndDo;  
		vLogStr = cmGetXMLStringFromXDTO(vRetXDTO);
		vResponse = vRetXDTO;
	EndIf;  
	If vWriteDebug Then
		vMsg = NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, , vLogStr, vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vLogStr);
	EndIf;
	Return vResponse;
EndFunction // cmGetRoomStatuses 

// -----------------------------------------------------------------------------
// Description: Changes room status to the next from the current status or to 
//              the specified as input parameter
// Parameters: External system code, Language code, Hotel code, Room code, 
//             Current room status code, New room status code (if empty string is 
//             passed then next allowed for the employee room status will be used), 
//             Employee code, Output type
// Return value: Structure with new room status data
// -----------------------------------------------------------------------------
Function cmChangeRoomStatus(pExtSystemCode, pLanguageCode = "RU", pHotelCode, pRoomCode, pCurrentRoomStatusCode, pNewRoomStatusCode = "", pEmployeeCode = 0, pOutputType = "CSV") Export
	vFunc = NStr("en='Change room status';ru='Изменить статус номера';de='Zimmerstatus ändern'"); 
	
	vInputParameters = NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExtSystemCode + Chars.LF 
					   + NStr("en='Language code: ';ru='Код языка: ';de='Sprachencode: '") + pLanguageCode + Chars.LF 
					   + NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code des Hotels: '") + pHotelCode + Chars.LF 
					   + NStr("en='Room code: ';ru='Код номера: ';de='Zimmercode: '") + pRoomCode + Chars.LF 
					   + NStr("en='Current room status code: ';ru='Текущий код статуса номера: ';de='Aktueller Statuscode des Zimmers: '") + pCurrentRoomStatusCode + Chars.LF 
					   + NStr("en='New room status code: ';ru='Новый код статуса номера: ';de='Neuer Code des Zimmerstatus: '") + pNewRoomStatusCode + Chars.LF 
					   + NStr("en='Employee code: ';ru='Код сотрудника: ';de='Code des Mitarbeiters: '") + pEmployeeCode;     
					   
	// Retreive hotel reference 
	vHotel = Catalogs.Hotels.EmptyRef();
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExtSystemCode);
	EndIf;				   
	vWriteDebug = False;				   
	vInteraction = Undefined;
	If Not IsBlankString(pExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then  
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	If vWriteDebug Then
		vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vInputParameters);
	EndIf;
				   
	// Retrieve language
	vLanguage = cmGetLanguageByCode(pLanguageCode);
	
	// Retrieve parameter references based on codes
	vRoom = Catalogs.Rooms.EmptyRef();
	If Not IsBlankString(pRoomCode) Then
		If IsBlankString(pHotelCode) Then
			vRoom = Catalogs.Rooms.FindByDescription(pRoomCode, True, , );
		Else
			vRoom = Catalogs.Rooms.FindByDescription(pRoomCode, True, , vHotel);
		EndIf;
	EndIf;
	If Not ValueIsFilled(vRoom) Then  
		vErr = NStr("en = 'Failed to get room by code!'; de = 'Fehler bei der Zimmersuche nach Code!'; ru = 'Ошибка поиска номера по коду!'");
		If ValueIsFilled(vInteraction) Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Error, , , vErr);
		Else	
			WriteLogEvent(vFunc, EventLogLevel.Error, , , vErr);	
		EndIf;
		Raise vErr;
	EndIf;
	// Retrieve employee by code
	vEmployee = cmGetEmployeeByPBXCode(pEmployeeCode);
	// Get current room status
	vCurrentRoomStatus = Catalogs.RoomStatuses.EmptyRef();
	If Not IsBlankString(pCurrentRoomStatusCode) Then
		vCurrentRoomStatus = cmGetObjectRefByExternalSystemCode(vHotel, pExtSystemCode, "RoomStatuses", pCurrentRoomStatusCode);
	EndIf;
	If IsBlankString(pNewRoomStatusCode) And Not ValueIsFilled(vCurrentRoomStatus) Then
		vErr = NStr("en = 'Failed to get current room status by code!'; de = 'Fehler bei der Suche nach dem aktuellen Zimmerstatus nach Code!'; ru = 'Ошибка поиска текущего статуса номера по коду!'"); 
		If ValueIsFilled(vInteraction) Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Error, , , vErr);
		Else	
			WriteLogEvent(vFunc, EventLogLevel.Error, , , vErr);	
		EndIf;
		Raise vErr;
	EndIf;
	// Get new room status
	vNewRoomStatus = Catalogs.RoomStatuses.EmptyRef();
	If Not IsBlankString(pNewRoomStatusCode) Then
		vNewRoomStatus = cmGetObjectRefByExternalSystemCode(vHotel, pExtSystemCode, "RoomStatuses", pNewRoomStatusCode);
	Else
		// Run query to get list of room statuses
		vAllRoomStatuses = cmGetAllRoomStatuses();
		vAllowedRoomStatuses = cmGetAllowedRoomStatuses(vEmployee, vCurrentRoomStatus);
		vCurrentRoomStatusRow = vAllRoomStatuses.Find(vCurrentRoomStatus, "RoomStatus");
		If vCurrentRoomStatusRow <> Undefined And vAllowedRoomStatuses.Count() > 0 Then
			i = vAllRoomStatuses.IndexOf(vCurrentRoomStatusRow) + 1;
			While True Do
				If i < vAllRoomStatuses.Count() Then
					vNewRoomStatus = vAllRoomStatuses.Get(i).RoomStatus;
				Else
					i = 0;
					vNewRoomStatus = vAllRoomStatuses.Get(i).RoomStatus;
				EndIf;
				If ValueIsFilled(vNewRoomStatus) Then
					If vAllowedRoomStatuses.Find(vNewRoomStatus, "RoomStatus") <> Undefined Then
						Break;
					EndIf;
				EndIf;
				i = i + 1;
			EndDo;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vNewRoomStatus) Then
		vErr = NStr("en = 'Failed to get new room status by code!'; de = 'Fehler bei der Suche des neuen Zimmerstatus nach Code!'; ru = 'Ошибка поиска нового статуса номера по коду!'"); 
		If ValueIsFilled(vInteraction) Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Error, vInputParameters, , vErr);
		Else	
			WriteLogEvent(vFunc, EventLogLevel.Error, , , vErr);	
		EndIf;
		Raise vErr;
	EndIf;
	// Do room status update
	vRoomObj = vRoom.GetObject();
	vRoomObj.RoomStatus = vNewRoomStatus;
	vRoomObj.Write();
	// Add record to the room status change history
	vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), ?(ValueIsFilled(vEmployee), vEmployee, SessionParameters.CurrentUser), NStr("en = 'External interface call'; de = 'Externes Interface'; ru = 'Внешний интерфейс'"));
	// Initialize return values
	vRetStr = """" + TrimAll(vRoom.Description) + """" + 
	          ", """ + TrimAll(vRoom.RoomType.Code) + """" + 
	          ", """ + vRoom.RoomType.GetObject().pmGetRoomTypeDescription(vLanguage) + """" + 
	          ", """ + TrimAll(vNewRoomStatus.Code) + """" + 
	          ", """ + TrimAll(vNewRoomStatus.Description) + """" + 
	          ", """ + TrimAll(vNewRoomStatus.RoomStatusIcon) + """" + 
	          ", """ + ?(ValueIsFilled(vEmployee), Catalogs.Employees.pmGetEmployeeDescription(vEmployee, vLanguage), Catalogs.Employees.pmGetEmployeeDescription(SessionParameters.CurrentUser, vLanguage)) + """" +
	          ", """ + Format(CurrentSessionDate(), "DF='yyyy.MM.dd HH:mm:ss'") + """" + 
	          ", " + Format(vNewRoomStatus.SortCode, "ND=6; NFD=0; NZ=; NG=") + 
	          ", """ + Format(CurrentSessionDate(), "DF=HH:mm") + """" + Chars.LF;
	vResponse = Undefined;
	If pOutputType = "CSV" Then  
		vResponse = vRetStr;
		vLogStr = vRetStr;
	Else
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "ChangeRoomStatus"));
		vRetXDTO.RoomStatusCode = TrimAll(vNewRoomStatus.Code);
		vRetXDTO.RoomStatusDescription = Left(TrimAll(vNewRoomStatus.Description), 170);
		vRetXDTO.RoomStatusIcon = TrimAll(vNewRoomStatus.RoomStatusIcon);
		vRetXDTO.StatusLastChangeEmployee = ?(ValueIsFilled(vEmployee), vEmployee.GetObject().pmGetEmployeeDescription(vLanguage), SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(vLanguage));
		vRetXDTO.StatusLastChangeTime = CurrentSessionDate();
		vRetXDTO.RoomStatusSortCode = vNewRoomStatus.SortCode;
		vRetXDTO.StatusLastChangeTimePresentation = Format(vRetXDTO.StatusLastChangeTime, "DF=HH:mm");
		vRetXDTO.Room = TrimAll(vRoom.Description);
		vRetXDTO.RoomTypeCode = TrimAll(vRoom.RoomType.Code);
		vRetXDTO.RoomTypeDescription = Left(vRoom.RoomType.GetObject().pmGetRoomTypeDescription(vLanguage), 170);   
		
		vLogStr = cmGetXMLStringFromXDTO(vRetXDTO);
		
		vResponse = vRetXDTO;
	EndIf; 
	If vWriteDebug Then
		vMsg = NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, , vLogStr, vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vLogStr);
	EndIf;
	Return vResponse;
EndFunction // cmChangeRoomStatus

// -----------------------------------------------------------------------------
Function cmActionProcessing(pMainCode, pActionCode, pTimestamp, pLanguage = "RU", pExtSystemCode = "") Export
	vFunc = NStr("en='Action processing';ru='Обработка действия';de='Aktionsverarbeitung'"); 
	vInputParameters = NStr("en='Main code: ';ru='Основной код: ';de='Hauptcode: '") + pMainCode + Chars.LF 
					   + NStr("en='Action code: ';ru='Код действия: ';de='Aktionscode: '") + pActionCode + Chars.LF 
					   + NStr("en='Timestamp: ';ru='Момент времени: ';de='Timestamp: '") + pTimestamp + Chars.LF 
					   + NStr("en='Language code: ';ru='Код языка: ';de='Sprachencode: '") + pLanguage;
	
	// Parameters
	vErrorDescription 	= "";
	vEmployee 			= Catalogs.Employees.EmptyRef();
	vRoom 				= Catalogs.Rooms.EmptyRef();
	vHotel 				= SessionParameters.CurrentHotel;
	// We're not use Date value from phone. Use current server date
	vCurDate 			= CurrentSessionDate();
	// Retrieve language
	vLanguage 			= cmGetLanguageByCode(pLanguage);
	vWriteDebug = False;				   
	vInteraction = Undefined;					
	If Not IsBlankString(pExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode);
		If ValueIsFilled(vInteraction) Then  
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	If vWriteDebug Then
		vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vInputParameters);
	EndIf;
	// Type of return data
	vNeedToReturnOperationsList 	= False;
	vNeedToReturnOperationDetails	= False;
	// If this is first launch an app
	If Not ValueIsFilled(pMainCode) Then
		// Get employee
		vEmployeeStruc = cmGetDataByActionCode(pActionCode, "Employees");
		If vEmployeeStruc = Undefined Then
			vErrorDescription = vErrorDescription + cmNStr("en = 'Authorization is needed. Attach your card. (The employee is not found in the system!)'; de = 'Autorisierung erforderlich. Bringen Sie Ihre Karte. (Der Mitarbeiter ist nicht im System gefunden!)'; ru = 'Необходимо авторизоваться. Приложите Вашу карту. (Сотрудник не найден в системе!)'", vLanguage) + Chars.LF;
		Else
			vEmployee = vEmployeeStruc.Data;
			// Get hotel
			If ValueIsFilled(vEmployeeStruc.Hotel) And vEmployeeStruc.Hotel <> vHotel Then
				vHotel = vEmployeeStruc.Hotel;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vErrorDescription) Then
			If Not ValueIsFilled(vEmployee) Then
				vErrorDescription = vErrorDescription + cmNStr("ru='Сотрудник не распознан!'; en='Employee is not recognized!'; de='Mitarbeiter wird nicht erkannt!'", vLanguage) + Chars.LF;
			EndIf;
			If Not ValueIsFilled(vHotel) Then
				vErrorDescription = vErrorDescription + cmNStr("en = 'Configure the system: the hotel is not found!'; de = 'Konfigurieren Sie das System: das Hotel nicht gefunden!'; ru = 'Настройте систему: гостиница не найдена!'", vLanguage) + Chars.LF;
			EndIf;
			If Not ValueIsFilled(vErrorDescription) Then
				vNeedToReturnOperationsList = True;
			EndIf;
		EndIf;
	// If this is new employee authorization or start of any action
	Else
		// Recognizing the action
		vDataStructure = cmGetDataByActionCode(pActionCode);
		If vDataStructure <> Undefined Then
			// If this is new employee authorization
			If vDataStructure.Type = "Employees" Then
				vEmployee = vDataStructure.Data;
				// Get hotel
				If ValueIsFilled(vDataStructure.Hotel) And vDataStructure.Hotel <> vHotel Then
					vHotel = vDataStructure.Hotel;
				EndIf;
				If Not ValueIsFilled(vEmployee) Then
					vErrorDescription = vErrorDescription + cmNStr("en = 'Employee is not recognized!'; de = 'Mitarbeiter wird nicht erkannt!'; ru = 'Сотрудник не распознан!'", vLanguage) + Chars.LF;
				EndIf;
				If Not ValueIsFilled(vHotel) Then
					vErrorDescription = vErrorDescription + cmNStr("en = 'Configure the system: the hotel is not found!'; de = 'Konfigurieren Sie das System: das Hotel nicht gefunden!'; ru = 'Настройте систему: гостиница не найдена!'", vLanguage) + Chars.LF;
				EndIf;
				If Not ValueIsFilled(vErrorDescription) Then
					vNeedToReturnOperationsList = True;
				EndIf;
			// If this is start or end an operation
			ElsIf vDataStructure.Type = "Rooms" Then
				// Get room
				vRoom = vDataStructure.Data;
				// Get hotel
				If ValueIsFilled(vDataStructure.Hotel) Then
					vHotel = vDataStructure.Hotel;
				EndIf;
				// Get employee
				vEmployeeStruc = cmGetDataByActionCode(pMainCode, "Employees");
				If vEmployeeStruc = Undefined Then
					vErrorDescription = vErrorDescription + cmNStr("ru='Сотрудник не найден в системе!'; en='The employee is not found in the system!'; de='Der Mitarbeiter ist nicht im System gefunden!'", vLanguage) + Chars.LF;
				Else
					vEmployee = vEmployeeStruc.Data;
					// Get hotel
					If ValueIsFilled(vEmployeeStruc.Hotel) And vEmployeeStruc.Hotel <> vHotel Then
						vHotel = vEmployeeStruc.Hotel;
					EndIf;
				EndIf;
				If Not ValueIsFilled(vErrorDescription) Then
					// Get current room status 
					vCurrentRoomStatus = vRoom.RoomStatus;
					// Skip updating status if it is equal to the new one
					If ValueIsFilled(vCurrentRoomStatus.NextRoomStatus) Then
						// Update room status
						vRoomObj = vRoom.GetObject();
						vRoomObj.RoomStatus = vCurrentRoomStatus.NextRoomStatus;
						vRoomObj.Write();
						// Add record to the room status change history
						vRoomObj.pmWriteToRoomStatusChangeHistory(vCurDate, ?(ValueIsFilled(vEmployee), vEmployee, SessionParameters.CurrentUser), "HOUSEKEEPING");
					EndIf;
					// Process start operation and end operation
					If ValueIsFilled(vEmployee) And ValueIsFilled(vCurrentRoomStatus) And ValueIsFilled(vCurrentRoomStatus.Operation) Then
						vOperation = vCurrentRoomStatus.Operation;
						// Try to find pending employee operation
						vEmpOpRef = cmGetPendingEmployeeOperation(vEmployee, vOperation, vCurDate, vRoom);
						If Not ValueIsFilled(vEmpOpRef) Then
							// Add operation start record
							vStOfOpResult = cmWriteStartOfOperation(vEmployee, vOperation, vRoom, vCurDate, vLanguage);
							If ValueIsFilled(vStOfOpResult) Then
								vErrorDescription = vErrorDescription + vStOfOpResult + Chars.LF;
							EndIf;
						Else
							vOldRoom = vEmpOpRef.Room;
							If ValueIsFilled(vOldRoom) And vOldRoom <> vRoom And ValueIsFilled(vOldRoom.RoomStatus) And ValueIsFilled(vOldRoom.RoomStatus.NextRoomStatus) Then
								// Update previous room status
								vRoomObj = vOldRoom.GetObject();
								vRoomObj.RoomStatus = vOldRoom.RoomStatus.NextRoomStatus;
								vRoomObj.Write();
								// Add record to the room status change history
								vRoomObj.pmWriteToRoomStatusChangeHistory(vCurDate, ?(ValueIsFilled(vEmployee), vEmployee, SessionParameters.CurrentUser), "HOUSEKEEPING");
							EndIf;
							// End operation
							vEndOfOpResult = cmWriteEndOfOperation(vEmpOpRef, vCurDate, vLanguage);
							If ValueIsFilled(vEndOfOpResult) Then
								vErrorDescription = vErrorDescription + vEndOfOpResult + Chars.LF;
							EndIf;
							// Maid moved to another room and forgot to finish operation in previous room.
							If ValueIsFilled(vOldRoom) And vOldRoom <> vRoom Or vEmpOpRef.Operation <> vOperation Or (vCurDate - vEmpOpRef.OperationStartTime)/(12*3600) > 12 Then
								vStOfOpResult = cmWriteStartOfOperation(vEmployee, vOperation, vRoom, vCurDate, vLanguage);
								If ValueIsFilled(vStOfOpResult) Then
									vErrorDescription = vErrorDescription + vStOfOpResult + Chars.LF;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If Not ValueIsFilled(vErrorDescription) Then
						If Not ValueIsFilled(vEmployee) Then
							vErrorDescription = vErrorDescription + cmNStr("en = 'Employee is not recognized!'; de = 'Mitarbeiter wird nicht erkannt!'; ru = 'Сотрудник не распознан!'", vLanguage) + Chars.LF;
						EndIf;
						If Not ValueIsFilled(vHotel) Then
							vErrorDescription = vErrorDescription + cmNStr("en = 'Configure the system: the hotel is not found!'; de = 'Konfigurieren Sie das System: das Hotel nicht gefunden!'; ru = 'Настройте систему: гостиница не найдена!'", vLanguage) + Chars.LF;
						EndIf;
						If Not ValueIsFilled(vRoom) Then
							vErrorDescription = vErrorDescription + cmNStr("en = 'The room is not recognized!'; de = 'Der Raum wird nicht erkannt!'; ru = 'Номер не распознан!'", vLanguage) + Chars.LF;
						EndIf;
						If Not ValueIsFilled(vErrorDescription) Then
							vNeedToReturnOperationDetails = True;
						EndIf;
					EndIf;
				EndIf;
			// If check a mini bar
			ElsIf vDataStructure.Type = "MiniBar" Then
				
				// TODO: write the handler action with mini bar
				
			Else
				vErrorDescription = vErrorDescription + cmNStr("en = 'Action is not recognized!'; de = 'Aktion wird nicht erkannt!'; ru = 'Действие не распознано!'", vLanguage) + Chars.LF;
			EndIf;
		Else
			vErrorDescription = vErrorDescription + cmNStr("en = 'Information about this card is not found in the system!'; de = 'Informationen zu dieser Karte ist nicht im System gefunden!'; ru = 'Данные об этой карте не найдены в системе!'", vLanguage) + Chars.LF;
		EndIf;
	EndIf;
	
	// RETURN DATA
	
	If ValueIsFilled(vErrorDescription) Then
		// Return error description
		vRetXDTO = cmGetOperationInfo(vLanguage, vHotel, vEmployee, vCurDate, , vErrorDescription);
	ElsIf vNeedToReturnOperationDetails Then
		// Return an operation details
		vRetXDTO = cmGetOperationInfo(vLanguage, vHotel, vEmployee, vCurDate, vRoom);
	ElsIf vNeedToReturnOperationsList Then
		// Return an operations list
		vRetXDTO = cmGetOperationInfo(vLanguage, vHotel, vEmployee, vCurDate);
	Else
		// Undefined error
		vRetXDTO = cmGetOperationInfo(vLanguage, vHotel, vEmployee, vCurDate, , cmNStr("ru='Неизвестная ошибка!'; en='Undefined error!'; de='undefined Fehler!'", vLanguage));
	EndIf;
	
	vLogStr = cmGetXMLStringFromXDTO(vRetXDTO);
	If vWriteDebug Then
		vMsg = NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, , vLogStr, vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vLogStr);
	EndIf;
	Return vRetXDTO;
EndFunction // ActionProcessing

// ----------------------------------------------------------------------------
Function cmGetDataByActionCode(pActionCode, pType = "") Export
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectRef AS DataRef,
	|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS DataType,
	|	ExternalSystemsObjectCodesMappings.Hotel AS Hotel
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	" + ?(ValueIsFilled(pType), "AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName ", " ") + "
	|	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode = &qObjectExternalCode";
	vQuery.SetParameter("qExternalSystemCode", "HOUSEKEEPING");
	vQuery.SetParameter("qObjectExternalCode", TrimAll(pActionCode));
	If ValueIsFilled(pType) Then
		vQuery.SetParameter("qObjectTypeName", TrimAll(pType));
	EndIf;
	vQryResult = vQuery.Execute().Unload();
	
	If vQryResult.Count() > 0 Then
		vReturnStructure = New Structure("Type, Data, Hotel", vQryResult[0].DataType, vQryResult[0].DataRef, vQryResult[0].Hotel);
		Return vReturnStructure;
	Else
		// Try to find room by code
		vRoom = Catalogs.Rooms.FindByDescription(TrimAll(pActionCode));
		If ValueIsFilled(vRoom) Then
			vReturnStructure = New Structure("Type, Data, Hotel", "Rooms", vRoom, vRoom.Owner);
			Return vReturnStructure;
		EndIf;
	EndIf;
	Return Undefined;
EndFunction // GetDataByActionCode

// -----------------------------------------------------------------------------
Function cmWriteEndOfOperation(pEmpOpRef, pCurrentDate, pLanguage) Export
	Try
		// Update employee operation document
		vEmpOpObj = pEmpOpRef.GetObject();
		// Fill operation end time and duration
		vEmpOpObj.OperationEndTime = pCurrentDate;
		vEmpOpObj.Duration = vEmpOpObj.pmGetOperationDuration();
		// Post document
		vEmpOpObj.Write(DocumentWriteMode.Posting);
	Except
		Return cmNStr("en='Failed to write end of employee operation! Error description: ';ru='Не удалось записать конец работы сотрудника! Описание ошибки: ';de='Das Ender der Arbeitszeit des Mitarbeiters konnte nicht geschrieben werden! Fehlerbeschreibung: '", pLanguage) + ErrorDescription();
	EndTry;
	Return "";
EndFunction // cmWriteEndOfOperation

// -----------------------------------------------------------------------------
Function cmWriteStartOfOperation(pEmployee, pOperation, pRoom, pCurrentDate, pLanguage) Export
	Try
		// Check if there is such operation already. Skip loading if found
		vEmpOperations = cmGetEmployeeOperation(pEmployee, pOperation, pCurrentDate);
		If vEmpOperations.Count() = 0 Then
			// Create new employee operation document
			vEmpOpObj = Documents.EmployeeOperation.CreateDocument();
			vEmpOpObj.SetTime(AutoTimeMode.CurrentOrLast);
			vEmpOpObj.Hotel = pRoom.Owner;
			vEmpOpObj.pmFillAttributesWithDefaultValues();
			// Fill employee and operation
			vEmpOpObj.Employee = pEmployee;
			vEmpOpObj.Operation = pOperation;
			vEmpOpObj.Room = pRoom;
			vEmpOpObj.OperationStartTime = pCurrentDate;
			// Retrieve room resources
			vRoomAttrs = vEmpOpObj.Room.GetObject().pmGetRoomAttributes(vEmpOpObj.OperationStartTime);
			For Each vRoomAttrsRow In vRoomAttrs Do
				vEmpOpObj.RoomType = vRoomAttrsRow.RoomType;
				Break;
			EndDo;
			// Get number of persons in the room for the operation start date
			vEmpOpObj.NumberOfPersons = vEmpOpObj.pmGetNumberOfPersons();
			// Fill operation start and end PBX codes
			vEmpOpObj.pmFillPBXCodes();
			// Get operation room space
			vStds = Catalogs.Operations.GetOperationStandards(vEmpOpObj.Operation, vEmpOpObj.Hotel, vEmpOpObj.RoomType, vEmpOpObj.Room, vEmpOpObj.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vEmpOpObj.RoomSpace = vStdsRow.RoomSpace;
				vEmpOpObj.Price = vStdsRow.Price;
			EndIf;
			// Fill operation articles consumption standards table
			vEmpOpObj.Articles.Clear();
			vEmpOpObj.pmFillArticles();
			// Fill remarks with call data
			vEmpOpObj.Remarks = "HOUSEKEEPING";
			// Post document
			vEmpOpObj.Write(DocumentWriteMode.Posting);
		EndIf;
	Except
		Return cmNStr("en='Failed to write start of employee operation! Error description: ';ru='Не удалось записать начало работы сотрудника! Описание ошибки: ';de='Der Arbeitsbeginn des Mitarbeiters konnte nicht geschrieben werden! Fehlerbeschreibung: '", pLanguage) + ErrorDescription();
	EndTry;
	Return "";
EndFunction // cmWriteStartOfOperation

// -----------------------------------------------------------------------------
// Description: Returns value table with room statuses
// Parameters: External system code, Language code, ..., Return type
// Return value: Value table with rooms and room statuses
// -----------------------------------------------------------------------------
Function cmGetOperationInfo(pLanguage, pHotel, pEmployee, pCurrentDate, pRoom = Undefined, pErrorDescription = "") Export
	WriteLogEvent(NStr("en='Get operation info';ru='Получить информацию о работе';de='Holen Betrieb Infos'"), EventLogLevel.Information, , , 
				NStr("en='Language: ';ru='Язык: ';de='Sprachen: '") + pLanguage + Chars.LF + 
				NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code des Hotels: '") + TrimAll(pHotel.Code) + Chars.LF + 
				NStr("en='Employee code: ';ru='Код сотрудника: ';de='Code des Mitarbeiters: '") + pEmployee.Code + Chars.LF +
				NStr("en='Current date: ';ru='Текущая дата: ';de='aktuelle Datum: '") + Format(pCurrentDate, "DF='dd.MM.yyyy HH:mm:ss'") + Chars.LF + 
				NStr("en='Room code: ';ru='Код номера: ';de='Zimmercode: '") + TrimAll(pRoom) + Chars.LF + 
				NStr("en='Error description: ';ru='Текст ошибки: ';de='Fehlerbeschreibung: '") + TrimAll(pErrorDescription)); 
	
	If pRoom = Undefined Then
		pRoom = Catalogs.Rooms.EmptyRef();
	EndIf;
	If Not ValueIsFilled(pErrorDescription) Then
		// Run query to get active room tasks
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Message.Ref,
		|	Message.ByObject AS Room,
		|	Message.Number AS TaskNumber,
		|	Message.Date AS TaskDate,
		|	Message.MessageType AS TaskType,
		|	Message.Remarks AS MessageText,
		|	Message.Author,
		|	Message.CloseToDate
		|FROM
		|	Document.Message AS Message
		|WHERE
		|	Message.Posted
		|	AND Message.ByObject REFS Catalog.Rooms
		|	AND Message.ByObject <> &qEmptyRoom
		|	AND NOT Message.IsClosed
		|	AND NOT Message.ByObject.DeletionMark
		|	AND Message.ByObject.OperationStartDate <= &qPeriod
		|	AND (Message.ByObject.OperationEndDate > &qPeriod
		|			OR Message.ByObject.OperationEndDate = &qEmptyDate)
		|	AND Message.ByObject.Owner = &qHotel
		|
		|ORDER BY
		|	Message.ByObject.SortCode,
		|	Message.MessageType.SortCode,
		|	Message.MessageType.Code,
		|	Message.PointInTime";
		vQry.SetParameter("qPeriod", pCurrentDate);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
		vQry.SetParameter("qHotel", pHotel);
		vTasks = vQry.Execute().Unload();
		// Run query to get scheduled emplioyee operations
		vQry = New Query;
		vQry.Text =	
		"SELECT
		|	OperationScheduleOperations.Room.Owner.Code AS HotelCode,
		|	OperationScheduleOperations.Room AS Room,
		|	OperationScheduleOperations.Room.RoomType AS RoomType,
		|	OperationScheduleOperations.Room.RoomType.Code AS RoomTypeCode,
		|	OperationScheduleOperations.Room.RoomType.Description AS RoomTypeDescription,
		|	OperationScheduleOperations.Room.RoomStatus AS RoomStatus,
		|	OperationScheduleOperations.Room.RoomStatus.Code AS RoomStatusCode,
		|	OperationScheduleOperations.Room.RoomStatus.Description AS RoomStatusDescription,
		|	OperationScheduleOperations.Room.RoomStatus.RoomStatusIcon AS RoomStatusIcon,
		|	OperationScheduleOperations.Operation.Code AS OperationCode,
		|	OperationScheduleOperations.Operation.Description AS OperationDescription,
		|	ISNULL(EmployeeOperationsHistorySliceLast.OperationStartTime, &qEmptyDate) AS OperationStartTime,
		|	ISNULL(EmployeeOperationsHistorySliceLast.OperationEndTime, &qEmptyDate) AS OperationEndTime
		|FROM
		|	Document.OperationSchedule.Operations AS OperationScheduleOperations
		|		LEFT JOIN InformationRegister.EmployeeOperationsHistory.SliceLast(
		|				&qCurrentDate,
		|				Employee = &qEmployee " +
		?(ValueIsFilled(pRoom), "	AND Room = &qRoom ", "AND OperationEndTime = &qEmptyDate") +
		"					) AS EmployeeOperationsHistorySliceLast
		|		ON OperationScheduleOperations.Room = EmployeeOperationsHistorySliceLast.Room " +
		?(Not ValueIsFilled(pRoom), "	AND OperationScheduleOperations.Operation = EmployeeOperationsHistorySliceLast.Operation ", "") +
		" WHERE
		|	NOT OperationScheduleOperations.Ref.DeletionMark
		|	AND (OperationScheduleOperations.Room = &qRoom
		|			OR &qRoomIsEmpty)
		|	AND OperationScheduleOperations.Ref.Date <= &qCurrentDate
		|	AND OperationScheduleOperations.Ref.Date >= &qBegOfCurrentDate
		|	AND OperationScheduleOperations.Ref.Posted
		|	AND OperationScheduleOperations.Ref.Hotel = &qHotel
		|	AND OperationScheduleOperations.Employee = &qEmployee
		|	AND ISNULL(EmployeeOperationsHistorySliceLast.OperationStartTime, &qEmptyDate) <= &qCurrentDate " +
		?(Not ValueIsFilled(pRoom),"	AND (ISNULL(EmployeeOperationsHistorySliceLast.OperationEndTime, &qEmptyDate) > &qCurrentDate
		|			OR ISNULL(EmployeeOperationsHistorySliceLast.OperationEndTime, &qEmptyDate) = &qEmptyDate) ", "") +
		"	AND NOT OperationScheduleOperations.Room.DeletionMark
		|	AND OperationScheduleOperations.Room.Owner = &qHotel " +
		?(Not ValueIsFilled(pRoom), " AND OperationScheduleOperations.Operation <> &qEmptyOperation ", "") +
		
		" ORDER BY
		|	OperationScheduleOperations.Room.SortCode";
		vQry.SetParameter("qCurrentDate", pCurrentDate);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qBegOfCurrentDate", BegOfDay(pCurrentDate));
		vQry.SetParameter("qRoom", pRoom);
		If Not ValueIsFilled(pRoom) Then
			vQry.SetParameter("qEmptyOperation", Catalogs.Operations.EmptyRef());
		EndIf;
		vQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(pRoom));
		vQry.SetParameter("qEmployee", pEmployee);
		vQry.SetParameter("qHotel", pHotel);
		vRooms = vQry.Execute().Unload();
		
		If vRooms.Count() = 0 Then
			vQry = New Query;
			vQry.Text =	
			"SELECT TOP 999999
			|	Rooms.Owner.Code AS HotelCode,
			|	Rooms.Ref AS Room,
			|	Rooms.RoomType AS RoomType,
			|	Rooms.RoomType.Code AS RoomTypeCode,
			|	Rooms.RoomType.Description AS RoomTypeDescription,
			|	Rooms.RoomStatus AS RoomStatus,
			|	Rooms.RoomStatus.Code AS RoomStatusCode,
			|	Rooms.RoomStatus.Description AS RoomStatusDescription,
			|	Rooms.RoomStatus.RoomStatusIcon AS RoomStatusIcon,
			|	Rooms.RoomStatus.Operation.Code AS OperationCode,
			|	Rooms.RoomStatus.Operation.Description AS OperationDescription,
			|	ISNULL(EmployeeOperationsHistorySliceLast.OperationStartTime, &qEmptyDate) AS OperationStartTime,
			|	ISNULL(EmployeeOperationsHistorySliceLast.OperationEndTime, &qEmptyDate) AS OperationEndTime
			|FROM
			|	Catalog.Rooms AS Rooms
			|		LEFT JOIN InformationRegister.EmployeeOperationsHistory.SliceLast(
			|				&qCurrentDate,
			|				Employee = &qEmployee " +
			?(ValueIsFilled(pRoom), "	AND Room = &qRoom ", "AND OperationEndTime = &qEmptyDate") +
			"					) AS EmployeeOperationsHistorySliceLast
			|		ON Rooms.Ref = EmployeeOperationsHistorySliceLast.Room " +
			?(Not ValueIsFilled(pRoom), "	AND Rooms.RoomStatus.Operation = EmployeeOperationsHistorySliceLast.Operation ", "") +
			" WHERE
			|	NOT Rooms.DeletionMark
			|	AND ISNULL(EmployeeOperationsHistorySliceLast.OperationStartTime, &qEmptyDate) <= &qCurrentDate  " +
			?(Not ValueIsFilled(pRoom), "	AND (ISNULL(EmployeeOperationsHistorySliceLast.OperationEndTime, &qEmptyDate) > &qCurrentDate
			|			OR ISNULL(EmployeeOperationsHistorySliceLast.OperationEndTime, &qEmptyDate) = &qEmptyDate) ", "") +
			"	AND Rooms.Owner = &qHotel
			|	AND (Rooms.Ref = &qRoom
			|			OR &qRoomIsEmpty) " +
			?(Not ValueIsFilled(pRoom), "	AND Rooms.RoomStatus.Operation <> &qEmptyOperation ", "") +
			
			" ORDER BY
			|	Rooms.SortCode";
			vQry.SetParameter("qCurrentDate", pCurrentDate);
			vQry.SetParameter("qEmptyDate", '00010101');
			vQry.SetParameter("qRoom", pRoom);
			If Not ValueIsFilled(pRoom) Then
				vQry.SetParameter("qEmptyOperation", Catalogs.Operations.EmptyRef());
			EndIf;
			vQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(pRoom));
			vQry.SetParameter("qEmployee", pEmployee);
			vQry.SetParameter("qHotel", pHotel);
			vRooms = vQry.Execute().Unload();
		EndIf;
		
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "ActionProcessing"));
		If ValueIsFilled(pRoom) Then
			vRetXDTO.ResponseType = "Detail";
			vRetXDTO.ResponseData = TrimAll(pRoom.Description);
			vRetXDTO.ResponseAddData = TrimAll(pRoom.RoomType.Description);
		Else
			vRetXDTO.ResponseType = "List";
			vRetXDTO.ResponseData = TrimAll(pEmployee.PBXAccountCode);
			vRetXDTO.ResponseAddData = TrimAll(pEmployee.Description);
		EndIf;
		vRetXDTO.ErrorDescription = TrimAll(pErrorDescription);
		
		vRetRowType				= XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "ActionProcessingRow");
		vRetGuestListRowType	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "GuestListRow");
		For Each vRoomsRow In vRooms Do
			vRetRow = XDTOFactory.Create(vRetRowType);
			
			vNumberOfGuests	= 0;
			
			vRetRow.Hotel 					= TrimAll(vRoomsRow.HotelCode);
			vRetRow.Room 					= TrimAll(vRoomsRow.Room);
			vRetRow.RoomTypeCode 			= TrimAll(vRoomsRow.RoomTypeCode);
			vRetRow.RoomTypeDescription 	= Left(vRoomsRow.RoomType.GetObject().pmGetRoomTypeDescription(pLanguage), 170);
			vRetRow.RoomStatusCode 			= TrimAll(vRoomsRow.RoomStatusCode);
			vRetRow.RoomStatusDescription 	= Left(TrimAll(vRoomsRow.RoomStatusDescription), 170);
			vRetRow.RoomStatusType = "None";
			If vRoomsRow.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
				vRetRow.RoomStatusType = "CheckOut";
			ElsIf vRoomsRow.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
				vRetRow.RoomStatusType = "Occupied";
			ElsIf vRoomsRow.RoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
				vRetRow.RoomStatusType = "Reserved";
			ElsIf vRoomsRow.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
				vRetRow.RoomStatusType = "TidyingUp";
			ElsIf vRoomsRow.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
				vRetRow.RoomStatusType = "Vacant";
			ElsIf vRoomsRow.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
				vRetRow.RoomStatusType = "Waiting";
			EndIf;
			vRetRow.OperationCode = TrimAll(vRoomsRow.OperationCode);
			vRetRow.OperationDescription = TrimAll(vRoomsRow.OperationDescription);
			vRetRow.OperationStartTime = vRoomsRow.OperationStartTime;
			vRetRow.OperationEndTime = vRoomsRow.OperationEndTime;
			
			// Get room object
			vRoomObj = vRoomsRow.Room.GetObject();
			
			// Get guests in house
			vGuestsTable = vRoomObj.pmGetInHouseGuests();
			
			vIsCheckInWaiting = False;
			If vGuestsTable.Count() = 0 Then
				vGuestsTable = cmGetCheckInWaitingGuests(pHotel, vRoomsRow.Room, pCurrentDate);
				If vGuestsTable.Count() > 0 Then
					vIsCheckInWaiting = True;
				EndIf;
			Else
				vRowsToDeleteArray = New Array();
				For Each vGuestRow In vGuestsTable Do
					vAccommodation = vGuestRow.Accommodation;
					If vAccommodation.CheckOutDate <= pCurrentDate Then
						vRowsToDeleteArray.Add(vGuestRow);
					EndIf;
				EndDo;
				For Each vRowsToDeleteItem in vRowsToDeleteArray Do
					vGuestsTable.Delete(vRowsToDeleteItem);
				EndDo;
			EndIf;
			vRetRow.IsCheckInWaiting = vIsCheckInWaiting;
			
			vRoomBlockTypeCode 			= "";
			vRoomBlockTypeDescription 	= "";
			If vRoomsRow.Room.HasRoomBlocks Then
				// Get room blocks
				vRoomBlocks = vRoomObj.pmGetRoomBlocks();
				
				For Each vRBlock In vRoomBlocks Do
					vRoomBlockTypeCode 			= TrimAll(vRBlock.RoomBlockType.Code);
					vRoomBlockTypeDescription 	= TrimAll(vRBlock.RoomBlockType.Description);
					Break;
				EndDo;
			EndIf;
			vRetRow.RoomBlockTypeCode 			= vRoomBlockTypeCode;
			vRetRow.RoomBlockTypeDescription 	= vRoomBlockTypeDescription;
			
			// Create XDTO Guest list
			vRetGuestListXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "GuestList"));
			
			vMiniBarIsOpen = False;
			If vGuestsTable.Count() > 0 Then
				For Each vGuestRow In vGuestsTable Do
					// Create XDTO Guest list row
					vRetGuestListRow = XDTOFactory.Create(vRetGuestListRowType);
					
					If vIsCheckInWaiting Then
						vNumberOfGuests = vNumberOfGuests + vGuestRow.Reservation.NumberOfPersons;
						If ValueIsFilled(vGuestRow.Reservation.Guest) Then
							vRetGuestListRow.LastName = TrimAll(vGuestRow.Reservation.Guest.LastName);
							vRetGuestListRow.FirstName = TrimAll(vGuestRow.Reservation.Guest.FirstName);
							vRetGuestListRow.SecondName = TrimAll(vGuestRow.Reservation.Guest.SecondName);
							vRetGuestListRow.Sex = TrimAll(vGuestRow.Reservation.Guest.Sex);
							vRetGuestListRow.ClientTypeDescription = TrimAll(vGuestRow.Reservation.Guest.ClientType.Description);
						Else
							vRetGuestListRow.LastName = "";
							vRetGuestListRow.FirstName = "";
							vRetGuestListRow.SecondName = "";
							vRetGuestListRow.Sex = "";
							vRetGuestListRow.ClientTypeDescription = "";
						EndIf;
					Else
						vNumberOfGuests = vNumberOfGuests + vGuestRow.Accommodation.NumberOfPersons;
						vRetGuestListRow.LastName = TrimAll(vGuestRow.Accommodation.Guest.LastName);
						vRetGuestListRow.FirstName = TrimAll(vGuestRow.Accommodation.Guest.FirstName);
						vRetGuestListRow.SecondName = TrimAll(vGuestRow.Accommodation.Guest.SecondName);
						vRetGuestListRow.Sex = TrimAll(vGuestRow.Accommodation.Guest.Sex);
						vRetGuestListRow.ClientTypeDescription = TrimAll(vGuestRow.Accommodation.Guest.ClientType.Description);
						if vGuestRow.Accommodation.MinibarIsOpen Then
							vMiniBarIsOpen = True;
						EndIf;
					EndIf;
					
					vRetGuestListXDTO.GuestListRow.Add(vRetGuestListRow);
				EndDo;
			EndIf;
			
			vRetRow.MiniBarIsOpen 	= vMiniBarIsOpen;
			vRetRow.NumberOfGuests 	= String(vNumberOfGuests);
			vRetRow.GuestList 		= vRetGuestListXDTO;
			
			// Add active room tasks
			vRoomTasksArray = vTasks.FindRows(New Structure("Room", vRoomsRow.Room));
			vActiveTasks = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "ActiveTasks"));
			vTaskType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "Task");
			For Each vRoomTaskRow In vRoomTasksArray Do
				vTaskRow = XDTOFactory.Create(vTaskType);
				
				vTaskRow.TaskNumber = cmGetDocumentNumberPresentation(vRoomTaskRow.TaskNumber);
				vTaskRow.TaskDate = vRoomTaskRow.TaskDate;
				vTaskRow.TaskType = ?(ValueIsFilled(vRoomTaskRow.TaskType), TrimAll(vRoomTaskRow.TaskType.Code), "");
				vTaskRow.TaskTypeDescription = ?(ValueIsFilled(vRoomTaskRow.TaskType), cmGetObjectExternalSystemCodeByRef(vRoomsRow.Room.Owner, "HOUSEKEEPING", "MessageTypes", vRoomTaskRow.TaskType, False), "");
				vTaskRow.MessageText = TrimAll(vRoomTaskRow.MessageText);
				
				vActiveTasks.Task.Add(vTaskRow);
			EndDo;
			vRetRow.ActiveTasks = vActiveTasks;
			
			vRetXDTO.ActionProcessingRow.Add(vRetRow);
		EndDo;
	Else
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "ActionProcessing"));
		vRetXDTO.ResponseType = "Error";
		vRetXDTO.ResponseData = "";
		vRetXDTO.ResponseAddData = "";
		vRetXDTO.ErrorDescription = TrimAll(pErrorDescription);
	EndIf;
	Return vRetXDTO;	
EndFunction // cmGetOperationInfo

// -----------------------------------------------------------------------------
Function cmGetCheckInWaitingGuests(pHotel, pRoom = Undefined, pPeriod = '00010101') Export
	If Not ValueIsFilled(pPeriod) Then
		pPeriod = CurrentSessionDate();
	EndIf;
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventory.Guest AS Guest,
	|	RoomInventory.Recorder AS Reservation,
	|	RoomInventory.CheckInDate AS CheckInDate
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Hotel = &qHotel
	|	AND RoomInventory.Room = &qRoom
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.IsReservation
	|	AND RoomInventory.CheckInDate > &qPeriod 
	|	AND RoomInventory.CheckInDate < &qEndOfDay 
	|
	|GROUP BY
	|	RoomInventory.Guest,
	|	RoomInventory.Recorder,
	|	RoomInventory.CheckInDate
	|
	|ORDER BY
	|	RoomInventory.CheckInDate";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qEndOfDay", EndOfDay(pPeriod));
	vQry.SetParameter("qEmptyRoom", Not ValueIsFilled(pRoom));
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQryTab = vQry.Execute().Unload();
	Return vQryTab;
EndFunction // cmGetCheckInWaitingGuests

// -----------------------------------------------------------------------------
Function cmChangeMiniBarStatus(pRoomCode, pHotelCode, pLanguage, pExtSystemCode = "") Export
	vFunc = NStr("en = 'Change mini-bar status'; de = 'Ändern Minibar Status'; ru = 'Сменить статус мини-бара'"); 
	vInputParameters = NStr("en='Language: ';ru='Язык: ';de='Sprachen: '") + TrimAll(pLanguage) + Chars.LF 
					   + NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code des Hotels: '") + TrimAll(pHotelCode) + Chars.LF 
					   + NStr("en='Room code: ';ru='Код номера: ';de='Zimmercode: '") + TrimAll(pRoomCode); 
				
				
	vErrorDescription = "";			
	vHotel = cmGetHotelByCode(pHotelCode);   
	vWriteDebug = False;				   
	vInteraction = Undefined;					
	If Not IsBlankString(pExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then  
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	If vWriteDebug Then
		vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vInputParameters);
	EndIf;
	// Retrieve language
	vLanguage = cmGetLanguageByCode(pLanguage);
	// Retrieve parameter references based on codes
	vRoom = Catalogs.Rooms.EmptyRef();
	If Not IsBlankString(pRoomCode) Then
		vRoom = Catalogs.Rooms.FindByDescription(pRoomCode, True, , vHotel);
	EndIf;
	If Not ValueIsFilled(vRoom) Then
		vErrorDescription = cmNStr("en = 'Failed to get room by code!'; de = 'Fehler bei der Zimmersuche nach Code!'; ru = 'Ошибка поиска номера по коду!'", vLanguage);
	EndIf;
	vMiniBarIsOpen = False;
	If Not ValueIsFilled(vErrorDescription) Then
		vQry = New Query;
		vQry.Text = 
			"SELECT
			|	Accommodation.Ref AS Ref
			|FROM
			|	Document.Accommodation AS Accommodation
			|WHERE
			|	Accommodation.Posted
			|	AND NOT Accommodation.DeletionMark
			|	AND Accommodation.Hotel = &qHotel
			|	AND Accommodation.AccommodationStatus.IsInHouse
			|	AND Accommodation.AccommodationStatus.IsActive
			|	AND Accommodation.Room = &qRoom
			|	AND Accommodation.CheckInDate <= &qCurrentDate
			|	AND Accommodation.CheckOutDate >= &qCurrentDate";

		vQry.SetParameter("qHotel", vHotel);
		vQry.SetParameter("qRoom", vRoom);
		vQry.SetParameter("qCurrentDate", CurrentSessionDate());

		vResult = vQry.Execute();

		vSelectionDetailRecords = vResult.Select();
		
        vAccommodation = Documents.Accommodation.EmptyRef();
		While vSelectionDetailRecords.Next() Do
			vAccommodation = vSelectionDetailRecords.Ref;
			Break;
		EndDo; 
		If ValueIsFilled(vAccommodation) Then
			vAccObject = vAccommodation.GetObject();
			vAccObject.MinibarIsOpen = Not vAccObject.MinibarIsOpen;
			vMiniBarIsOpen = vAccObject.MinibarIsOpen;
			vAccObject.Write();
		Else
			vErrorDescription = cmNStr("en='Accommodation document is not found!';ru='Документ размещения не найден!';de='Unterkunft Dokument nicht gefunden!'", vLanguage);
		EndIf;
	EndIf;
	
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "ChangeMiniBarStatus"));
	vRetXDTO.ErrorDescription = TrimAll(vErrorDescription); 
	
	vLogStr = cmGetXMLStringFromXDTO(vRetXDTO);
	If vWriteDebug Then
		vMsg = NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, , vLogStr, vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vLogStr);
	EndIf;
	
	Return vRetXDTO;
EndFunction // cmChangeMiniBarStatus

// -----------------------------------------------------------------------------
Function cmRegisterRoomTag(pActionCode, pRoomCode, pHotelCode, pLanguage) Export
	vFunc = NStr("en='Register room tag';ru='Зарегистрировать метку номера';de='Registrieren Raumbeschriftung'"); 
	vInputParameters = NStr("en='Action code: ';ru='Код действия: ';de='Aktionscode: '") + pActionCode + Chars.LF 
					   + NStr("en='Room code: ';ru='Код номера: ';de='Zimmercode: '") + TrimAll(pRoomCode) + Chars.LF 
					   + NStr("en='Language: ';ru='Язык: ';de='Sprachen: '") + TrimAll(pLanguage) + Chars.LF 
					   + NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code des Hotels: '") + TrimAll(pHotelCode);
				
	vHotel = cmGetHotelByCode(pHotelCode);   
	
	WriteLogEvent(vFunc, EventLogLevel.Information, , , vInputParameters);

	// Retrieve language
	vLanguage = cmGetLanguageByCode(pLanguage);
	// Retrieve parameter references based on codes
	vRoom = Catalogs.Rooms.EmptyRef();
	If Not IsBlankString(pRoomCode) Then
		vRoom = Catalogs.Rooms.FindByDescription(pRoomCode, True, , vHotel);
	EndIf;		
	vErrorDescription = "";
	If Not ValueIsFilled(vHotel) Or Not ValueIsFilled(vLanguage) Or Not ValueIsFilled(vRoom) Then
		vMessage = cmNStr("en = 'Unable to find a hotel or room in the system.'; de = 'Nicht in der Lage, ein Hotel oder ein Zimmer in der Anlage zu finden.'; ru = 'Не удалось найти отель или номер в системе.'", vLanguage);
		WriteLogEvent(NStr("en='Register room tag';ru='Зарегистрировать метку номера';de='Registrieren Raumbeschriftung'"), EventLogLevel.Error, , , vMessage + Chars.LF +
		"Debug info: Hotel is found: " + String(ValueIsFilled(vHotel)) + Chars.LF +
		"Language is found: " + String(ValueIsFilled(vLanguage)) + Chars.LF +
		"Room is found: " + String(ValueIsFilled(vRoom)));
		vErrorDescription = vMessage;
	EndIf;
	If Not ValueIsFilled(vErrorDescription) Then
		Try
			cmDeleteExternalSystemsObjectCodesMappingRowsByObjectRef(vHotel, "HOUSEKEEPING", "Rooms", vRoom);
			cmDeleteExternalSystemsObjectCodesMappingRowsByObjectExternalCode(vHotel, "HOUSEKEEPING", , pActionCode);
			
			// Try to update existing mapping or create new one
			vMgrObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vMgrObj.Hotel = vHotel;
			vMgrObj.ExternalSystemCode = "HOUSEKEEPING";
			vMgrObj.ObjectTypeName = "Rooms";
			vMgrObj.ObjectExternalCode = TrimAll(pActionCode);
			vMgrObj.ObjectRef = vRoom;
			vMgrObj.Write(True);
		Except
			WriteLogEvent(NStr("en = 'Register room tag'; de = 'Registrieren Raumbeschriftung'; ru = 'Зарегистрировать метку номера'"), EventLogLevel.Error, , , ErrorDescription());
			vErrorDescription = ErrorDescription();
		EndTry;
	EndIf;
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "RoomInfoShell"));
	vRetXDTO.ErrorDescription = TrimAll(vErrorDescription);
	vRoomInfo = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "RoomInfo"));
	If ValueIsFilled(vRoom) Then
		vRoomInfo.Room = TrimAll(vRoom.Description);
		vRoomInfo.RoomTypeCode = TrimAll(vRoom.RoomType.Code);
		vRoomInfo.RoomTypeDescription = TrimAll(vRoom.RoomType.Description);
		vRoomInfo.RoomStatusCode = TrimAll(vRoom.RoomStatus.Code);
		vRoomInfo.RoomStatusDescription = TrimAll(vRoom.RoomStatus.Description);
		vRoomInfo.Floor = TrimAll(vRoom.Floor);
		vRoomInfo.RoomSectionCode = TrimAll(vRoom.RoomSection.Code);
		vRoomInfo.RoomSectionDescription = TrimAll(vRoom.RoomSection.Description);
		vRoomInfo.HasRoomBlock = vRoom.HasRoomBlocks;
		vRoomInfo.StopSale = vRoom.StopSale;
		vRoomInfo.Remarks = Left(TrimAll(vRoom.Remarks), 4096);
	Else
		vRoomInfo.Room = "";
		vRoomInfo.RoomTypeCode = "";
		vRoomInfo.RoomTypeDescription = "";
		vRoomInfo.RoomStatusCode = "";
		vRoomInfo.RoomStatusDescription = "";
		vRoomInfo.Floor = "";
		vRoomInfo.RoomSectionCode = "";
		vRoomInfo.RoomSectionDescription = "";
		vRoomInfo.HasRoomBlock = False;
		vRoomInfo.StopSale = False;
		vRoomInfo.Remarks = "";
	EndIf;
	vRetXDTO.RoomInfo = vRoomInfo;  
	
	vLogStr = cmGetXMLStringFromXDTO(vRetXDTO);
	
	WriteLogEvent(vFunc, EventLogLevel.Information, , , vLogStr);
	
	Return vRetXDTO;
EndFunction // cmRegisterRoomTag

// -----------------------------------------------------------------------------
Function cmRegisterEmployeeTag(pActionCode, pEmployeeCode, pHotelCode, pLanguage) Export
	WriteLogEvent(NStr("en='Register employee tag';ru='Зарегистрировать метку сотрудника';de='Registrieren Mitarbeiter-Tag'"), EventLogLevel.Information, , , 
				NStr("en='Action code: ';ru='Код действия: ';de='Aktionscode: '") + pActionCode + Chars.LF + 
				NStr("en='Employee code: ';ru='Код сотрудника: ';de='Code des Mitarbeiters: '") + TrimAll(pEmployeeCode) + Chars.LF + 
				NStr("en='Language: ';ru='Язык: ';de='Sprachen: '") + TrimAll(pLanguage) + Chars.LF + 
				NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code des Hotels: '") + TrimAll(pHotelCode));
				
	vHotel = cmGetHotelByCode(pHotelCode);
	// Retrieve language
	vLanguage = cmGetLanguageByCode(pLanguage);
	// Retrieve parameter references based on codes
	vEmployee = Catalogs.Employees.EmptyRef();
	If Not IsBlankString(pEmployeeCode) Then
		vEmployee = cmGetEmployeeByPBXAccountCode(Number(pEmployeeCode));
	EndIf;	
	vErrorDescription = "";
	If Not ValueIsFilled(vHotel) Or Not ValueIsFilled(vLanguage) Or Not ValueIsFilled(vEmployee) Then
		vMessage = cmNStr("ru='Не удалось найти отель или сотрудника в системе.'; en='Unable to find a hotel or employee in the system.'; de='Nicht in der Lage, ein Hotel oder ein Mitarbeiter im System zu finden.'", vLanguage);
		WriteLogEvent(NStr("en='Register employee tag';ru='Зарегистрировать метку сотрудника';de='Registrieren Mitarbeiter-Tag'"), EventLogLevel.Error, , ,  vMessage + Chars.LF +
		"Debug info: Hotel is found: " + String(ValueIsFilled(vHotel)) + Chars.LF +
		"Language is found: " + String(ValueIsFilled(vLanguage)) + Chars.LF +
		"Employee is found: " + String(ValueIsFilled(vEmployee)));
		vErrorDescription = vMessage;
	EndIf;
	If Not ValueIsFilled(vErrorDescription) Then
		Try
			cmDeleteExternalSystemsObjectCodesMappingRowsByObjectRef(vHotel, "HOUSEKEEPING", "Employees", vEmployee);
			cmDeleteExternalSystemsObjectCodesMappingRowsByObjectExternalCode(vHotel, "HOUSEKEEPING", , pActionCode);
			
			// Try to update existing mapping or create new one
			vMgrObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vMgrObj.Hotel = vHotel;
			vMgrObj.ExternalSystemCode = "HOUSEKEEPING";
			vMgrObj.ObjectTypeName = "Employees";
			vMgrObj.ObjectExternalCode = TrimAll(pActionCode);
			vMgrObj.ObjectRef = vEmployee;
			vMgrObj.Write(True);
		Except
			WriteLogEvent(NStr("en='Register employee tag';ru='Зарегистрировать метку сотрудника';de='Registrieren Mitarbeiter-Tag'"), EventLogLevel.Error, , , ErrorDescription());
			vErrorDescription = ErrorDescription();
		EndTry;
	EndIf;
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "EmployeeInfoShell"));
	vRetXDTO.ErrorDescription = TrimAll(vErrorDescription);
	vEmployeeInfo = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "EmployeeInfo"));
	If ValueIsFilled(vEmployee) Then
		vEmployeeInfo.EmployeeCode = TrimAll(vEmployee.Code);
		vEmployeeInfo.EmployeeDescription = TrimAll(vEmployee.Description);
		vEmployeeInfo.Room = TrimAll(vEmployee.Room.Description);
		vEmployeeInfo.PBXAccountCode = vEmployee.PBXAccountCode;
	Else
		vEmployeeInfo.EmployeeCode = "";
		vEmployeeInfo.EmployeeDescription = "";
		vEmployeeInfo.Room = "";
		vEmployeeInfo.PBXAccountCode = 0;
	EndIf;
	vRetXDTO.EmployeeInfo = vEmployeeInfo;
	Return vRetXDTO;
EndFunction // cmRegisterEmployeeTag

// -----------------------------------------------------------------------------
Function cmRegisterMinibarTag(pActionCode, pRoomCode, pHotelCode, pLanguage) Export
	WriteLogEvent(NStr("en='Register mini-bar tag';ru='Зарегистрировать метку мини-бара';de='Registrieren Mini-bar Tag'"), EventLogLevel.Information, , , 
				NStr("en='Action code: ';ru='Код действия: ';de='Aktionscode: '") + pActionCode + Chars.LF + 
				NStr("en='Room code: ';ru='Код номера: ';de='Zimmercode: '") + TrimAll(pRoomCode) + Chars.LF + 
				NStr("en='Language: ';ru='Язык: ';de='Sprachen: '") + TrimAll(pLanguage) + Chars.LF + 
				NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code des Hotels: '") + TrimAll(pHotelCode));
				
	vHotel = cmGetHotelByCode(pHotelCode);
	// Retrieve language
	vLanguage = cmGetLanguageByCode(pLanguage);
	// Retrieve parameter references based on codes
	vRoom = Catalogs.Rooms.EmptyRef();
	If Not IsBlankString(pRoomCode) Then
		vRoom = Catalogs.Rooms.FindByDescription(pRoomCode, True, , vHotel);
	EndIf;	
	vErrorDescription = "";
	If Not ValueIsFilled(vHotel) Or Not ValueIsFilled(vLanguage) Or Not ValueIsFilled(vRoom) Then
		vMessage = cmNStr("ru='Не удалось найти отель или номер в системе.'; en='Unable to find a hotel or room in the system.'; de='Nicht in der Lage, ein Hotel oder ein Zimmer in der Anlage zu finden.'", vLanguage);
		WriteLogEvent(NStr("en='Register mini-bar tag';ru='Зарегистрировать метку мини-бара';de='Registrieren Mini-bar Tag'"), EventLogLevel.Error, , , vMessage + Chars.LF +
		"Debug info: Hotel is found: " + String(ValueIsFilled(vHotel)) + Chars.LF +
		"Language is found: " + String(ValueIsFilled(vLanguage)) + Chars.LF +
		"Room is found: " + String(ValueIsFilled(vRoom)));
		vErrorDescription = vMessage;
	EndIf;
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "RoomInfoShell"));
	vRetXDTO.ErrorDescription = TrimAll(vErrorDescription);
	vRoomInfo = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "RoomInfo"));
	If ValueIsFilled(vRoom) Then
		vRoomInfo.Room = TrimAll(vRoom.Description);
		vRoomInfo.RoomTypeCode = TrimAll(vRoom.RoomType.Code);
		vRoomInfo.RoomTypeDescription = TrimAll(vRoom.RoomType.Description);
		vRoomInfo.RoomStatusCode = TrimAll(vRoom.RoomStatus.Code);
		vRoomInfo.RoomStatusDescription = TrimAll(vRoom.RoomStatus.Description);
		vRoomInfo.Floor = TrimAll(vRoom.Floor);
		vRoomInfo.RoomSectionCode = TrimAll(vRoom.RoomSection.Code);
		vRoomInfo.RoomSectionDescription = TrimAll(vRoom.RoomSection.Description);
		vRoomInfo.HasRoomBlock = vRoom.HasRoomBlocks;
		vRoomInfo.StopSale = vRoom.StopSale;
		vRoomInfo.Remarks = Left(TrimAll(vRoom.Remarks), 4096);
	Else
		vRoomInfo.Room = "";
		vRoomInfo.RoomTypeCode = "";
		vRoomInfo.RoomTypeDescription = "";
		vRoomInfo.RoomStatusCode = "";
		vRoomInfo.RoomStatusDescription = "";
		vRoomInfo.Floor = "";
		vRoomInfo.RoomSectionCode = "";
		vRoomInfo.RoomSectionDescription = "";
		vRoomInfo.HasRoomBlock = False;
		vRoomInfo.StopSale = False;
		vRoomInfo.Remarks = "";
	EndIf;
	vRetXDTO.RoomInfo = vRoomInfo;
	Return vRetXDTO;
EndFunction // cmRegisterMinibarTag

// -----------------------------------------------------------------------------
Procedure cmDeleteExternalSystemsObjectCodesMappingRowsByObjectRef(pHotel, pExternalSystemCode, pObjectTypeName, pObjectRef) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
	|	AND ExternalSystemsObjectCodesMappings.ObjectRef = &qObjectRef";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qExternalSystemCode", pExternalSystemCode);
	vQry.SetParameter("qObjectTypeName", pObjectTypeName); 
	vQry.SetParameter("qObjectRef", pObjectRef); 
	vObjects = vQry.Execute().Unload();
	For Each vObjRow In vObjects Do
		Try
			vRcdSetObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordSet();
			
			vHotelFlt = vRcdSetObj.Filter.Hotel;
			vHotelFlt.ComparisonType = ComparisonType.Equal;
			vHotelFlt.Value = pHotel;
			vHotelFlt.Use = True;
			
			vExtSystemCodeFlt = vRcdSetObj.Filter.ExternalSystemCode;
			vExtSystemCodeFlt.ComparisonType = ComparisonType.Equal;
			vExtSystemCodeFlt.Value = pExternalSystemCode;
			vExtSystemCodeFlt.Use = True;
			
			vObjectTypeFlt = vRcdSetObj.Filter.ObjectTypeName;
			vObjectTypeFlt.ComparisonType = ComparisonType.Equal;
			vObjectTypeFlt.Value = pObjectTypeName;
			vObjectTypeFlt.Use = True;
			
			vObjectExternalCodeFlt = vRcdSetObj.Filter.ObjectExternalCode;
			vObjectExternalCodeFlt.ComparisonType = ComparisonType.Equal;
			vObjectExternalCodeFlt.Value = TrimAll(vObjRow.ObjectExternalCode);
			vObjectExternalCodeFlt.Use = True;
			
			vRcdSetObj.Clear();
			vRcdSetObj.Write(True);
		Except
		EndTry;
	EndDo;
EndProcedure // cmDeleteExternalSystemsObjectCodesMappingRowsByObjectRef

// -----------------------------------------------------------------------------
Procedure cmDeleteExternalSystemsObjectCodesMappingRowsByObjectExternalCode(pHotel, pExternalSystemCode, pObjectTypeName = "", pObjectExternalCode) Export
	Try
		vRcdSetObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordSet();
		
		vHotelFlt = vRcdSetObj.Filter.Hotel;
		vHotelFlt.ComparisonType = ComparisonType.Equal;
		vHotelFlt.Value = pHotel;
		vHotelFlt.Use = True;
		
		vExtSystemCodeFlt = vRcdSetObj.Filter.ExternalSystemCode;
		vExtSystemCodeFlt.ComparisonType = ComparisonType.Equal;
		vExtSystemCodeFlt.Value = pExternalSystemCode;
		vExtSystemCodeFlt.Use = True;
		
		if ValueIsFilled(pObjectTypeName) Then
			vObjectTypeFlt = vRcdSetObj.Filter.ObjectTypeName;
			vObjectTypeFlt.ComparisonType = ComparisonType.Equal;
			vObjectTypeFlt.Value = pObjectTypeName;
			vObjectTypeFlt.Use = True;
		EndIf;
		
		vObjectExternalCodeFlt = vRcdSetObj.Filter.ObjectExternalCode;
		vObjectExternalCodeFlt.ComparisonType = ComparisonType.Equal;
		vObjectExternalCodeFlt.Value = TrimAll(pObjectExternalCode);
		vObjectExternalCodeFlt.Use = True;
		
		vRcdSetObj.Clear();
		vRcdSetObj.Write(True);
	Except
	EndTry;
EndProcedure // cmDeleteExternalSystemsObjectCodesMappingRowsByObjectExternalCode

// -----------------------------------------------------------------------------
Function cmAddNewTask(pActionCode, pHotelCode, pLanguageCode, pRemarks, pRoomCode, pTaskType, pPhoto, pExtSystemCode = "") Export
	vFunc = NStr("en = 'Add new task'; de = 'Add new task'; ru = 'Добавить новую задачу'"); 
	vInputParameters = NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExtSystemCode + Chars.LF
					   + NStr("en='Language: ';ru='Язык: ';de='Sprachen: '") + TrimAll(pLanguageCode) + Chars.LF 
					   + NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code des Hotels: '") + TrimAll(pHotelCode) + Chars.LF 
					   + NStr("en='Room code: ';ru='Код номера: ';de='Zimmercode: '") + TrimAll(pRoomCode) + Chars.LF
					   + NStr("en = 'Action code: '; de = 'Action code: '; ru = 'Код операции: '") + TrimAll(pActionCode) + Chars.LF
					   + NStr("en = 'Remarks: '; de = 'Remarks: '; ru = 'Описание: '") + TrimAll(pRemarks) + Chars.LF
					   + NStr("en = 'Task type: '; de = 'Task type: '; ru = 'Тип задачи: '") + TrimAll(pTaskType); 
				
	vErrorDescription = "";			
	vHotel = cmGetHotelByCode(pHotelCode);   
	vWriteDebug = False;				   
	vInteraction = Undefined;					
	If Not IsBlankString(pExtSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then  
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	If vWriteDebug Then
		vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vInputParameters);
	EndIf;
	// Check parameters
	vErrorDescription = "";
	Try
		// Retrieve language
		vLanguage = cmGetLanguageByCode(pLanguageCode);
		// Get employee
		vEmployee = Undefined;
		vEmployeeStruct = cmGetDataByActionCode(pActionCode, "Employees");
		If vEmployeeStruct = Undefined Then
			vErr = cmNStr("ru='Необходимо авторизоваться. Приложите Вашу карту. (Сотрудник не найден в системе!)'; en='Authorization is needed. Attach your card. (The employee is not found in the system!)'; de='Autorisierung erforderlich. Bringen Sie Ihre Karte. (Der Mitarbeiter ist nicht im System gefunden!)'", vLanguage);
			If ValueIsFilled(vInteraction) Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Error, , , vErr);
			Else	
				WriteLogEvent(vFunc, EventLogLevel.Error, , , vErr);	
			EndIf;
			
			Raise vErr;
		Else
			vEmployee = vEmployeeStruct.Data;
		EndIf;
		// Hotel
		vHotel = cmGetHotelByCode(pHotelCode);
		If Not ValueIsFilled(vHotel) Then
			If vEmployeeStruct <> Undefined And ValueIsFilled(vEmployeeStruct.Hotel) And 
			   vEmployeeStruct.Hotel <> vHotel Then
				vHotel = vEmployeeStruct.Hotel;
			EndIf;
		EndIf;
		// Retrieve parameter references based on codes
		vRoom = Catalogs.Rooms.EmptyRef();
		If Not IsBlankString(pRoomCode) Then
			vRoom = Catalogs.Rooms.FindByDescription(pRoomCode, True, , vHotel);
		EndIf;
		// Message type
		vMessageType = Catalogs.MessageTypes.EmptyRef();
		If Not IsBlankString(pTaskType) Then
			vMessageType = cmGetObjectRefByExternalSystemCode(vHotel, "HOUSEKEEPING", "MessageTypes", pTaskType);
		EndIf;
		// Create message document
		vMsgObj = Documents.Message.CreateDocument();
		vMsgObj.pmFillAttributesWithDefaultValues();
		vMsgObj.Type = Enums.MessageTypes.Message;
		If ValueIsFilled(vMsgObj.MessageStatus) Then
			vMsgObj.IsClosed = vMsgObj.MessageStatus.IsClosed;
		EndIf;
		If ValueIsFilled(vEmployee) Then
			vMsgObj.Author = vEmployee;
		EndIf;
		vMsgObj.ByObject = vRoom;
		vMsgObj.MessageType = vMessageType;
		If ValueIsFilled(vMessageType) And ValueIsFilled(vMessageType.Department) Then
			vMsgObj.ForDepartment = vMessageType.Department;
		Else
			vMsgObj.ForDepartment = vHotel.QualityManagementDepartment;
		EndIf;
		vMsgObj.Remarks = TrimAll(pRemarks);
		vMsgObj.PopUp = True;
		vMsgObj.Write(DocumentWriteMode.Posting);
		// Attach photo to this message
		If ValueIsFilled(pPhoto) Then
			vPhotoBinary = Base64Value(pPhoto);
			// Add record to the message attachments register
			vRcdMgr = InformationRegisters.MessageAttachments.CreateRecordManager();
			vRcdMgr.Period = CurrentSessionDate();
			vRcdMgr.Message = vMsgObj.Ref;
			vRcdMgr.Read();
			If Not vRcdMgr.Selected() Then
				vRcdMgr.Author = vMsgObj.Author;
				vRcdMgr.ExtFile = New ValueStorage(vPhotoBinary);
				vRcdMgr.FileName = TrimAll(pTaskType) + "_" + TrimAll(pRoomCode) + "_" + Format(vRcdMgr.Period, "DF=yyyy-MM-dd_HHmm") + ".jpg";
				vRcdMgr.FileLoadTime = vRcdMgr.Period;
				vRcdMgr.FileLastChangeTime = vRcdMgr.Period;
				vRcdMgr.Write();
			EndIf;
		EndIf;
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "AddNewTask"));
	vRetXDTO.ErrorDescription = "";
	If Not IsBlankString(vErrorDescription) Then
		vRetXDTO.ErrorDescription = vErrorDescription;
	Else
		vRetXDTO.TaskNumber = TrimAll(vMsgObj.Number);
		vRetXDTO.TaskType = pTaskType;
		vRetXDTO.MessageText = TrimAll(vMsgObj.Remarks);
		vRetXDTO.Room = pRoomCode;
	EndIf;  

	vLogStr = cmGetXMLStringFromXDTO(vRetXDTO);
		
	If vWriteDebug Then
		vMsg = NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFunc, Enums.ExternalSystemEventTypes.Info, , vLogStr, vMsg);
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vLogStr);
	EndIf;             
	
	Return vRetXDTO;
EndFunction // cmAddNewTask

#EndRegion
