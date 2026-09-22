#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel		 - CatalogRef.Hotels - Ref
//  pRecipient	 - String			 - Recipient
//
Procedure SendNotification(pHotel = Undefined, pRecipient = Undefined) Export
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	NotificationQueue.Document AS Document,
	|	NotificationQueue.Recipient AS Recipient,
	|	NotificationQueue.MessageType AS MessageType,
	|	NotificationQueue.Document.Room AS Room,
	|	NotificationQueue.Message AS Message,
	|	NotificationQueue.Document.Room.RoomSection AS Section,
	|	NotificationQueue.Date AS Date,
	|	NotificationQueue.Hotel AS Hotel
	|FROM
	|	InformationRegister.NotificationQueue AS NotificationQueue
	|WHERE
	|	CASE
	|			WHEN &qUseRecipientFilter
	|				THEN NotificationQueue.Recipient = &qRecipient
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qHotelIsEmpty
	|				THEN TRUE
	|			ELSE NotificationQueue.Hotel = &qHotel
	|		END
	|
	|ORDER BY
	|	Hotel,
	|	Recipient,
	|	MessageType,
	|	Section
	|TOTALS BY
	|	Hotel,
	|	Recipient,
	|	MessageType,
	|	Section";
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	If ValueIsFilled(pRecipient) Then
		vQuery.SetParameter("qUseRecipientFilter", True);
		vQuery.SetParameter("qRecipient", pRecipient);
	Else
		vQuery.SetParameter("qUseRecipientFilter", False);
		vQuery.SetParameter("qRecipient", pRecipient);
	EndIf;
	vRes = vQuery.Execute();
	vByHotels = vRes.Select(QueryResultIteration.ByGroups);
	While vByHotels.Next() Do  
		vHotel = vByHotels.Hotel;
		vSelRecipient = vByHotels.Select(QueryResultIteration.ByGroups);
		While vSelRecipient.Next() Do
			vSelMessageType = vSelRecipient.Select(QueryResultIteration.ByGroups);
			While vSelMessageType.Next() Do
				vSelRoomSectionlRecords = vSelMessageType.Select(QueryResultIteration.ByGroups);
				While vSelRoomSectionlRecords.Next() Do
					vSelDetail = vSelRoomSectionlRecords.Select();
					
					vMessage = "";
					vDocs = New Array;
					
					While vSelDetail.Next() Do
						If CurrentSessionDate() - vSelDetail.Date > 60 * 60 * 3 Then
							vRm = InformationRegisters.NotificationQueue.CreateRecordManager();
							vRm.Hotel = vHotel;
							vRm.Document = vSelDetail.Document;
							vRm.Read();
							vRm.Delete();
						Else
							If TypeOf(vSelDetail.Document) = Type("DocumentRef.Message") Then
								vMessage = vMessage + GetRoomText(vSelDetail.Document.ByObject, False, False, False, True, False) + Chars.LF;
							Else
								vMessage = vMessage + GetRoomText(vSelDetail.Room, False, False, False, False, False, vSelDetail.Document) + Chars.LF;
							EndIf;
						EndIf;
						
						vDocs.Add(vSelDetail.Document);
					EndDo;
					If vMessage <> "" Then
						If BotNotify(vHotel, vSelRecipient.Recipient, "<b>" + vSelMessageType.MessageType + "</b>" + Chars.LF + vMessage, vSelRoomSectionlRecords.Section) Then
							For Each vRow In vDocs Do
								vRm = InformationRegisters.NotificationQueue.CreateRecordManager();
								vRm.Hotel = vHotel;
								vRm.Document = vRow;
								vRm.Read();
								vRm.Delete();
							EndDo;
						EndIf;
					EndIf;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
EndProcedure // SendNotification

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel		 - CatalogRef.Hotels - Ref
//  pRecipient	 - String			 - Recipient
//  pText		 - String			 - Text
//  pSection	 - String			 - Section
// 
// Returns:
//  Boolen - Result sent
//
Function BotNotify(pHotel, pRecipient, pText, pSection = Undefined) Export
	Try
		If TypeOf(pRecipient) = Type("CatalogRef.Employees") Then
			vChats = GetAutorizaitingEmployee(pHotel, , pRecipient);
		ElsIf TypeOf(pRecipient) = Type("EnumRef.ChatRoles") Then
			vChats = GetAutorizaitingEmployee(pHotel, pRecipient);
		ElsIf TypeOf(pRecipient) = Type("CatalogRef.Departments") Then
			vChats = GetAutorizaitingEmployee(pHotel, , , pRecipient);
		EndIf;
		
		If vChats.Count() = 0 Then
			Return True;
		EndIf;
		
		For Each vRow In vChats Do
			If Not ValueIsFilled(vRow.room) Or TypeOf(pRecipient) = Type("EnumRef.ChatRoles") Or TypeOf(pRecipient) = Type("CatalogRef.Departments") Then
				vChat = vRow.Chat;
				If Not vChat.Bot.IsActive Then
					Continue;
				EndIf;
				
				If pRecipient = Enums.ChatRoles.Supervisor 
					And UseSections(pHotel) And vRow.section = pSection 
					Or Not UseSections(pHotel) 
					Or TypeOf(pRecipient) = Type("CatalogRef.Employees") 
					Or TypeOf(pRecipient) = Type("CatalogRef.Departments")Then
					
					vAPI = cmGetChatBotAPI(vChat.Bot.BotType);
					
					vMessage = New Structure;
					vMessage.Insert("Chat", vChat);
					vMessage.Insert("Bot", vChat.Bot);
					
					vMessageID = vAPI.sendMessage(vMessage, pText, , False);
					
					If Not ValueIsFilled(vMessageID) Then
						Return False;
					EndIf;
				EndIf;
			Else
				Return True;
			EndIf;
		EndDo;
		
		Return True;
	Except
		Return False;
	EndTry;
EndFunction // Notifi

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel		 - CatalogRef.Hotels - Ref
//  pRecipient	 - String			 - Recipient
//  pText		 - String			 - Text
// 
// Returns:
//  Boolen - Result sent
//
Function SendEmployeeMessage(pHotel, pRecipient, pText) Export
	vWasSent = False;
	Try
		vChats = GetAutorizaitingEmployee(pHotel, , pRecipient);
		If vChats.Count() > 0 Then
			For Each vRow In vChats Do
				vChat = vRow.Chat;
				If Not vChat.Bot.IsActive Then
					Continue;
				EndIf;
				
				vAPI = cmGetChatBotAPI(vChat.Bot.BotType);
				
				vMessage = New Structure;
				vMessage.Insert("Chat", vChat);
				vMessage.Insert("Bot", vChat.Bot);
				
				vMessageID = vAPI.sendMessage(vMessage, pText, , False);
				
				If ValueIsFilled(vMessageID) Then
					vWasSent = True;
				EndIf;
			EndDo;
		EndIf;
		Return vWasSent;
	Except
		Return vWasSent;
	EndTry;
EndFunction // SendEmployeeMessage

// -----------------------------------------------------------------------------
//
// Parameters:
//  pEmployee	 - CatalogRef.Employees	 - Ref 
//  pText		 - String				 - Text 
//  pKeyboard	 - String				 - Keyboard 
//  pRoom		 - CatalogRef.Rooms	 - Ref
// 
// Returns:
//  String - Response
//
Function Response(pEmployee, pText, pRoom) Export
	Try
		vHotel = pRoom.Owner;
		vChats = GetAutorizaitingAllEmployee(vHotel);
		For Each vChatRow In vChats Do
			If vChatRow.Employee = pEmployee And Not vChatRow.room = pRoom And vChatRow.Chat.Bot.IsActive Then
				vChat = vChatRow.Chat;
				
				vAPI = cmGetChatBotAPI(vChat.Bot.BotType);
				
				vMessage = New Structure;
				vMessage.Insert("Chat", vChat);
				vMessage.Insert("Bot", vChat.Bot);
				
				Return vAPI.sendMessage(vMessage, pText + Chars.LF + vAPI.GetRoomText(pRoom), vAPI.getKeyboard(pEmployee), False);
			EndIf;
		EndDo;
	Except
	EndTry;
EndFunction // Response

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDocument	 - DocumentRef	 - Ref
//  pHotel		 - CatalogRef.Hotels - Ref
//  pRecipient	 - String			 - Recipient
//  pMessageType - String			 - Message type
//  pMessage	 - String			 - Message
//
Procedure AddNotification(pDocument, pHotel, pRecipient, pMessageType, pMessage) Export
	If ValueIsFilled(pDocument) And ValueIsFilled(pRecipient) Then
		vRm = InformationRegisters.NotificationQueue.CreateRecordManager();
		vRm.Hotel 		= pHotel;
		vRm.Document    = pDocument;
		vRm.Recipient   = pRecipient;
		vRm.MessageType = pMessageType;
		vRm.Message     = pMessage;
		vRm.Date        = CurrentSessionDate();
		vRm.Write();
	EndIf;
EndProcedure // AddNotification

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRoom				 - CatalogRef.Rooms	 - Ref
//  pOperation			 - String			 - Operation
//  pGuest				 - CatalogRef.Clients	 - Ref
//  pMalfunction		 - Boolean				 - Malfunction
//  pArrival			 - Boolean				 - Is Arrival
//  pCurrentOperation	 - String				 - CurrentOperation
// 
// Returns:
//  String - Reply text
//
Function GetRoomText(pRoom, pShowGuestsLastName = False, pOperation = True, pGuest = True, pMalfunction = True, pArrival = True, pCurrentOperation = Undefined, pAttachPhoto = False) Export
	vStatusTime = GetCurrentStatusTime(pRoom);
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Reservations.NumberOfAdults AS NumberOfAdults,
		|	Reservations.NumberOfTeenagers AS NumberOfTeenagers,
		|	Reservations.NumberOfChildren AS NumberOfChildren,
		|	Reservations.NumberOfInfants AS NumberOfInfants,
		|	Reservations.NumberOfPersons AS NumberOfPersons,
		|	Reservations.ReservationStatus.IsInWaitingList AS IsInWaitingList,
		|	Reservations.HousekeepingRemarks AS HousekeepingRemarks
		|FROM
		|	Document.Reservation AS Reservations
		|WHERE
		|	Reservations.Posted
		|	AND Reservations.ReservationStatus.IsActive
		|	AND Reservations.CheckInDate >= &qBegOfToday
		|	AND Reservations.CheckInDate <= &qEndOfToday
		|	AND Reservations.Room = &qRoom
		|TOTALS
		|	SUM(NumberOfAdults),
		|	SUM(NumberOfTeenagers),
		|	SUM(NumberOfChildren),
		|	SUM(NumberOfInfants),
		|	SUM(NumberOfPersons)
		|BY
		|	IsInWaitingList";
	
	vQuery.SetParameter("qBegOfToday", BegOfDay(CurrentSessionDate()));
	vQuery.SetParameter("qEndOfToday", EndOfDay(CurrentSessionDate()));
	vQuery.SetParameter("qRoom", pRoom);
	
	vResult = vQuery.Execute();
	
	vRes = vResult.Select(QueryResultIteration.ByGroups);
	
	vCheckIn = ""; 
	vOnTerritory = ""; 
	vDelimiter = "%0D%0A";
	vFormatTime = "DF=HH:mm";
 	If vRes.Next() Then
		vNumberOfAdults = ?(vRes.NumberOfAdults = Null, 0, vRes.NumberOfAdults);
		vNumberOfChildren = ?(vRes.NumberOfTeenagers = Null, 0, vRes.NumberOfTeenagers) + ?(vRes.NumberOfChildren = Null, 0, vRes.NumberOfChildren);
		vNumberOfPersons = ?(vRes.NumberOfPersons = Null, 0, vRes.NumberOfPersons);  
		vOnTerritory = ?(vRes.IsInWaitingList, " " + GetEmoji("HOTEL"), "");   
		vTempMsg = NStr("en = '%1 %2'; de = '%1 %2'; ru = '%1 %2'");
		
		vResDetRec = vRes.Select();
		vRemarks = "";
		vInd = 0;
		While vResDetRec.Next() Do
			vRowHRemarks = vResDetRec.HousekeepingRemarks;
			If Not IsBlankString(vRowHRemarks) Then
				vRemarks = vRemarks + ?(vInd <> 0, vDelimiter, "") + vRowHRemarks;
				vInd = vInd + 1;	
			EndIf;
		EndDo;
		
		If vNumberOfPersons <> 0 Then    
			// First param %1
			vEmj = GetEmoji("AIRPLANE ARRIVING") + vOnTerritory;  
			// Second param %2
			If vRes.IsInWaitingList Then
				vMsgPers = NStr("en = 'Waiting for arrival (%1 prs., %2 chl.)'; de = 'Warten auf Ankunft (%1 prs., %2 kin.)'; ru = 'Ожид. заезд (%1 чел., %2 дет.)'");	
			Else	
				vMsgPers = NStr("en = 'Exp. arrival (%1 prs., %2 chl.)'; de = 'Gepl. anreise (%1 prs., %2 kin.)'; ru = 'План. заезд (%1 чел., %2 дет.)'");
			EndIf;
			vMsgGuests = ?(vNumberOfPersons = 0, "", StrTemplate(vMsgPers, vNumberOfAdults, vNumberOfChildren));
			vCheckIn = TrimAll(StrTemplate(vTempMsg, vEmj, vMsgGuests)); 
		EndIf;
	EndIf;	
	vReplyText = "" + GetEmoji("DOOR") + " /" + TrimAll(pRoom) + " - " + TrimAll(pRoom.RoomStatus) + ?(IsBlankString(vStatusTime), "", NStr("ru=' c ';en=' from ';de=' from '") + vStatusTime + vCheckIn );
	If Not IsBlankString(vRemarks) Then
		vMemo = GetEmoji("MEMO");
		vReplyText = vReplyText + vDelimiter + vMemo + vRemarks;
	EndIf;
	vROperations = GetRoomOperations(pRoom);
	If vROperations.Count() > 0 Then
		vInt = 0;
		While vInt < vROperations.Count() Do
			If ValueIsFilled(vROperations[vInt].DoNotDisturbTime) Then
				vReplyText = vReplyText + vDelimiter + GetEmoji("NO ENTRY SIGN") + NStr("en=' Do not disturb: ';ru=' Не беспокоить: ';de=' Nicht stören: '") + Format('00010101' + 5 + (CurrentSessionDate() - vROperations[vInt].DoNotDisturbTime), vFormatTime);	
			EndIf;
			vInt = vInt + 1;
		EndDo;
	EndIf;
	
	vRoomList = New ValueList;
	vRoomList.Add(pRoom);
	If pCurrentOperation <> Undefined Then
		vReplyText = vReplyText + vDelimiter + pCurrentOperation.Operation + ": " + pCurrentOperation.Employee;
		If ValueIsFilled(pCurrentOperation.OperationEndTime) Then
			vReplyText = vReplyText + GetEmoji("chequered flag") + Format(pCurrentOperation.OperationEndTime, vFormatTime);
		Else
			If ValueIsFilled(pCurrentOperation.OperationStartTime) Then
				vReplyText = vReplyText + NStr("en = ' from '; de = ' von '; ru = ' c '") + Format(pCurrentOperation.OperationStartTime, vFormatTime);
			Else
				vReplyText = vReplyText + GetEmoji("watch");
			EndIf;
		EndIf;	
	EndIf;
	
	If pOperation Then
		vTOperation = GetCurrentOperations(pRoom);
		If vTOperation.Count() > 0 Then
			vInt = 0;
			While vInt < vTOperation.Count() Do
				vReplyText = vReplyText + vDelimiter + vTOperation[vInt].Operation + ": " + vTOperation[vInt].Employee;
				If ValueIsFilled(vTOperation[vInt].OperationEndTime) Then
					vReplyText = vReplyText + GetEmoji("chequered flag") + Format(vTOperation[vInt].OperationEndTime, vFormatTime);
				Else
					If ValueIsFilled(vTOperation[vInt].OperationStartTime) Then
						vReplyText = vReplyText + NStr("en=' from ';ru=' c ';de=' von '") + Format(vTOperation[vInt].OperationStartTime, vFormatTime);
					Else
						vReplyText = vReplyText + GetEmoji("watch");
					EndIf;
				EndIf;
				vInt = vInt + 1;
			EndDo;
		EndIf;	
	EndIf;
	If pGuest Then
		vInHouse = cmGetRoomGuests(pRoom.Owner, Undefined, pRoom, CurrentSessionDate(), CurrentSessionDate());
		If vInHouse.Count() > 0 Then
			vReplyText = vReplyText + vDelimiter + GetEmoji("key") + NStr("en = 'In-house: '; ru = 'Проживает: '; de = 'In-house: '") +vInHouse.Count() + " " + NStr("en = 'pers.'; ru = 'чел.'; de = 'pers.'");
			For Each vClientsRow In vInHouse Do
				If vClientsRow.Guest.Sex = Enums.Sex.Female Then 
					If vClientsRow.Guest.Age <= 60 And vClientsRow.Guest.Age >= 18 Then 
						vSex = GetEmoji("WOMAN");
					ElsIf vClientsRow.Guest.Age > 60 Then
						vSex = GetEmoji("OLDER WOMAN");
					ElsIf vClientsRow.Guest.Age < 18 And vClientsRow.Guest.Age > 0 Then
						vSex = GetEmoji("GIRL");
					Else
						vSex = GetEmoji("WOMAN");
					EndIf;
				ElsIf vClientsRow.Guest.Sex = Enums.Sex.Male Then
					If vClientsRow.Guest.Age <= 60 And vClientsRow.Guest.Age >= 18 Then 
						vSex = GetEmoji("MAN");
					ElsIf vClientsRow.Guest.Age > 60 Then
						vSex = GetEmoji("OLDER MAN");
					ElsIf vClientsRow.Guest.Age < 18 And vClientsRow.Guest.Age > 0 Then
						vSex = GetEmoji("BOY");
					Else
						vSex = GetEmoji("MAN");
					EndIf;
				Else
					vSex = GetEmoji("bust in silhouette");	
				EndIf;    
				vBD = "";  
				vDateOfBirth = vClientsRow.Guest.DateOfBirth;
				If ValueIsFilled(vDateOfBirth) Then
					If Day(vDateOfBirth) = Day(CurrentSessionDate()) And Month(vDateOfBirth) = Month(CurrentSessionDate()) Then
						vBD = GetEmoji("BIRTHDAY CAKE");		
					EndIf;	
				EndIf;	
				If pShowGuestsLastName Then
					vGuestName = vClientsRow.Guest.FullName;
				Else
					vGuestName = vClientsRow.Guest.FirstName + " " + vClientsRow.Guest.SecondName;
				EndIf;
				vReplyText = vReplyText + vDelimiter + vSex + vBD + " " + vGuestName + " ";	
				If BegOfDay(vClientsRow.Accommodation.CheckOutDate) = BegOfDay(CurrentSessionDate()) Then
					vReplyText = vReplyText + NStr("en = 'check out: '; ru = 'выезд: '; de = 'abreise: '") + Format(vClientsRow.Accommodation.CheckOutDate, vFormatTime);
				EndIf;
			EndDo;
			If Not IsBlankString(vInHouse[0].Accommodation.HousekeepingRemarks) Then
				vReplyText = vReplyText + vDelimiter + GetEmoji("TRIANGULAR FLAG ON POST") + vInHouse[0].Accommodation.HousekeepingRemarks;
			EndIf;
		EndIf;	
	EndIf;	
	If pMalfunction Then
		vMalfunctionsList = GetMalfunctions(pRoom);
		If vMalfunctionsList.Count() > 0 Then
			vInt=0;
			While vInt < vMalfunctionsList.Count() Do
				vReplyText = vReplyText + vDelimiter + GetEmoji("wrench") + vMalfunctionsList.Get(vInt) + ";";
				vInt=vInt+1;
			EndDo;
		EndIf;
	EndIf;
	
	If pAttachPhoto Then
		vReplyText = vReplyText + vDelimiter + NStr("en = 'Attach a photo if any'; de = 'Fügen Sie gegebenenfalls ein Foto bei'; ru = 'Прикрепите фото, если имеется'");
	EndIf;
	Return vReplyText;
EndFunction // GetRoomText

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel		 - CatalogRef.Hotels	 - Ref
//  pChatRole	 - String				 - ChatRole
//  pEmployee	 - CatalogRef.Employees	 - Ref
//  pDepartment	 - CatalogRef.Departments	 - Ref
// 
// Returns:
//  String - CommandName
//
Function GetAutorizaitingEmployee(pHotel, pChatRole = Undefined, pEmployee = Undefined, pDepartment = Undefined) Export
	Query = New Query;
	Query.Text = 
	"SELECT
	|	current_sessions.chat AS chat,
	|	current_sessions.employee AS employee,
	|	current_sessions.session_start AS session_start,
	|	ChatAuthorisation.sessions_stop AS sessions_stop,
	|	current_sessions.employee.PermissionGroup.ChatRole AS employeePermissionGroupChatRole,
	|	ChatAuthorisation.hotel AS hotel,
	|	ChatAuthorisation.room AS room,
	|	ChatAuthorisation.section AS section
	|FROM
	|	(SELECT
	|		ChatAuthorisation.chat AS chat,
	|		ChatAuthorisation.employee AS employee,
	|		MAX(ChatAuthorisation.session_start) AS session_start
	|	FROM
	|		InformationRegister.ChatAuthorisation AS ChatAuthorisation
	|	
	|	GROUP BY
	|		ChatAuthorisation.chat,
	|		ChatAuthorisation.employee) AS current_sessions
	|		LEFT JOIN InformationRegister.ChatAuthorisation AS ChatAuthorisation
	|		ON (ChatAuthorisation.chat = current_sessions.chat)
	|			AND (ChatAuthorisation.employee = current_sessions.employee)
	|			AND (ChatAuthorisation.session_start = current_sessions.session_start)
	|WHERE
	|	ChatAuthorisation.sessions_stop < current_sessions.session_start
	|	AND NOT ChatAuthorisation.hotel = VALUE(catalog.hotels.emptyRef)
	|	AND ChatAuthorisation.hotel = &hotel
	|	AND CASE
	|			WHEN &qUseEmployee
	|				THEN current_sessions.employee = &qEmployee
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qUseDepartment
	|				THEN current_sessions.employee.Department = &qDepartment
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qUseChatRole
	|				THEN current_sessions.employee.PermissionGroup.ChatRole = &qChatRole
	|			ELSE TRUE
	|		END";
	Query.SetParameter("hotel", pHotel);
	Query.SetParameter("ChatRole", pChatRole);
	
	If ValueIsFilled(pEmployee) Then
		Query.SetParameter("qUseEmployee", True);
		Query.SetParameter("qEmployee", pEmployee);
	Else
		Query.SetParameter("qUseEmployee", False);
		Query.SetParameter("qEmployee", pEmployee);	
	EndIf;
	
	If ValueIsFilled(pDepartment) Then
		Query.SetParameter("qUseDepartment", True);
		Query.SetParameter("qDepartment", pDepartment);
	Else
		Query.SetParameter("qUseDepartment", False);
		Query.SetParameter("qDepartment", pDepartment);	
	EndIf;
	If ValueIsFilled(pChatRole) Then
		Query.SetParameter("qUseChatRole", True);
		Query.SetParameter("qChatRole", pChatRole);
	Else
		Query.SetParameter("qUseChatRole", False);
		Query.SetParameter("qChatRole", pChatRole);	
	EndIf;
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Unload() ;
	Return SelectionDetailRecords;
EndFunction // GetAutorizaitingEmployee

// -----------------------------------------------------------------------------
//  Returns emoji symbol as url ecoded string
//  supposed than emoji table is ready for use in Information Register "emoji"
//
// Parameters:
//  pName		 - String	 - Emoji name
//  pEMString	 - 	Boolean		 - emString
// 
// Returns:
//  String - urlString
//
Function GetEmoji(pName) Export
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	emoji.emString AS emString,
	|	emoji.urlString AS urlString
	|FROM
	|	InformationRegister.emoji AS emoji
	|WHERE
	|	emoji.Name = &Name";
	vQ.SetParameter("Name", pName);
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		Return qRes.urlString;
	EndIf;
	Return "";
EndFunction // GetEmoji

// -----------------------------------------------------------------------------
Function GetCurrentStatusTime(pRoom) Export
	If Not ValueIsFilled(pRoom) Then
		Return "";
	EndIf;
	
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	RoomStatusChangeHistorySliceLast.Period AS Period
	|FROM
	|	InformationRegister.RoomStatusChangeHistory.SliceLast(, Room = &qRoom) AS RoomStatusChangeHistorySliceLast";
	vQ.SetParameter("qRoom", pRoom);
	
	vRes = vQ.Execute().Select();
	If vRes.Next() Then
		If (CurrentSessionDate() - vRes.Period) >= 24 * 3600 Then
			Return Format(vRes.Period, "DF='dd.MMM HH:mm'");
		EndIf;
		
		Return Format(vRes.Period, "DF=HH:mm");
	EndIf;
	
	Return "";
EndFunction // GetCurrentStatusTime

// -----------------------------------------------------------------------------
Function UseSections(pHotel) Export
	vHotels = New Array;
	vHotels.Add(pHotel);
	vHotels.Add(Catalogs.Hotels.EmptyRef());
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	RoomSections.Ref AS Ref
	|FROM
	|	Catalog.RoomSections AS RoomSections
	|WHERE
	|	NOT RoomSections.IsFolder
	|	AND NOT RoomSections.DeletionMark
	|	AND RoomSections.Hotel IN(&qHotels)";
	Query.SetParameter("qHotels", vHotels);
	QueryResult = Query.Execute();
	
	Return QueryResult.Select().Count() > 0;
EndFunction // UseSections

// -----------------------------------------------------------------------------
Function GetRoomOperations(pRoom) Export
	vText = "SELECT
	|	EmployeeOperation.Ref AS Ref,
	|	EmployeeOperation.Room AS Room,
	|	EmployeeOperation.Employee AS Employee,
	|	EmployeeOperation.Operation AS Operation,
	|	EmployeeOperation.OperationIntentTime AS OperationIntentTime,
	|	EmployeeOperation.EmployeeAssignmentTime AS EmployeeAssignmentTime,
	|	EmployeeOperation.OperationStartTime AS OperationStartTime,
	|	EmployeeOperation.OperationEndTime AS OperationEndTime,
	|	EmployeeOperation.OperationEndConfirmedTime AS OperationEndConfirmedTime,
	|	EmployeeOperation.DoNotDisturbTime AS DoNotDisturbTime
	|FROM
	|	Document.EmployeeOperation AS EmployeeOperation
	|WHERE
	|	EmployeeOperation.Posted
	|	AND NOT EmployeeOperation.DeletionMark
	|	AND EmployeeOperation.OperationEndTime = &qEmptyDate
	|	AND EmployeeOperation.Room = &qRoom
	|
	|ORDER BY
	|	EmployeeOperation.Room.SortCode,
	|	EmployeeOperation.OperationStartTime";
	vQ = New Query();
	vQ.Text = vText;
	vQ.SetParameter("qRoom", pRoom);
	vQ.SetParameter("qEmptyDate", '00010101');
	vQRes = vQ.Execute().Unload();
	Return vQRes;
EndFunction // GetRoomOperations

// -----------------------------------------------------------------------------
Function GetCurrentOperations(pRoom = Undefined, pEmployee = Undefined) Export
	vText = "SELECT
	|	EmployeeOperation.Ref AS Ref,
	|	EmployeeOperation.Room AS Room,
	|	EmployeeOperation.Employee AS Employee,
	|	EmployeeOperation.Operation AS Operation,
	|	EmployeeOperation.OperationIntentTime AS OperationIntentTime,
	|	EmployeeOperation.EmployeeAssignmentTime AS EmployeeAssignmentTime,
	|	EmployeeOperation.OperationStartTime AS OperationStartTime,
	|	EmployeeOperation.OperationEndTime AS OperationEndTime,
	|	EmployeeOperation.OperationEndConfirmedTime AS OperationEndConfirmedTime,
	|	EmployeeOperation.DoNotDisturbTime AS DoNotDisturbTime
	|FROM
	|	Document.EmployeeOperation AS EmployeeOperation
	|WHERE
	|	EmployeeOperation.Posted
	|	AND NOT EmployeeOperation.DeletionMark
	|	AND EmployeeOperation.OperationStartTime >= &qStartDate
	|	AND EmployeeOperation.OperationEndTime = &qEmptyDate";
	If ValueIsFilled(pRoom) Then
		vText = vText + " AND EmployeeOperation.Room = &qRoom
		|	";
	EndIf;
	If ValueIsFilled(pEmployee) Then
		vText = vText + " AND EmployeeOperation.Employee = &qEmployee
		|	";
	EndIf;
	vText = vText + "
	|ORDER BY
	|	EmployeeOperation.Room.SortCode,
	|	EmployeeOperation.OperationStartTime";
	vQ = New Query();
	vQ.Text = vText;
	If ValueIsFilled(pRoom) Then
		vQ.SetParameter("qRoom", pRoom);
	EndIf;
	If ValueIsFilled(pEmployee) Then
		vQ.SetParameter("qEmployee", pEmployee);
	EndIf;
	vQ.SetParameter("qEmptyDate", '00010101');
	vQ.SetParameter("qStartDate", BegOfDay(CurrentSessionDate()) - 24 * 3600 * 3);
	qTRes = vQ.Execute().Unload();
	Return qTRes;
EndFunction // GetCurrentOperations

// -----------------------------------------------------------------------------
Function GetMalfunctions(pRoom) Export
	vMalfunctionsList = New Array;
	
	If Not ValueIsFilled(pRoom) Then
		Return vMalfunctionsList;
	EndIf;
	
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	Messages.Remarks AS Remarks
	|FROM
	|	Document.Message AS Messages
	|WHERE
	|	Messages.ByObject = &qRoom
	|	AND NOT Messages.IsClosed
	|	AND Messages.Posted
	|
	|ORDER BY
	|	Messages.Date DESC";
	vQ.SetParameter("qRoom", pRoom);
	
	vRes = vQ.Execute().Select();
	While vRes.Next() Do
		vMalfunctionsList.Add(vRes.Remarks);
	EndDo;
	
	Return vMalfunctionsList;
EndFunction // GetMalfunctions

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  String - Result
//
Function GetAutorizaitingAllEmployee(pHotel) Export
	Query = New Query;
	Query.Text = 
	"SELECT
	|	current_sessions.chat AS chat,
	|	current_sessions.employee AS employee,
	|	current_sessions.session_start AS session_start,
	|	ChatAuthorisation.sessions_stop AS sessions_stop,
	|	current_sessions.employee.PermissionGroup.ChatRole AS employeePermissionGroupChatRole,
	|	ChatAuthorisation.hotel AS hotel,
	|	ChatAuthorisation.room AS room
	|FROM
	|	(SELECT
	|		ChatAuthorisation.chat AS chat,
	|		ChatAuthorisation.employee AS employee,
	|		MAX(ChatAuthorisation.session_start) AS session_start
	|	FROM
	|		InformationRegister.ChatAuthorisation AS ChatAuthorisation
	|	
	|	GROUP BY
	|		ChatAuthorisation.chat,
	|		ChatAuthorisation.employee) AS current_sessions
	|		LEFT JOIN InformationRegister.ChatAuthorisation AS ChatAuthorisation
	|		ON (ChatAuthorisation.chat = current_sessions.chat)
	|			AND (ChatAuthorisation.employee = current_sessions.employee)
	|			AND (ChatAuthorisation.session_start = current_sessions.session_start)
	|WHERE
	|	ChatAuthorisation.sessions_stop < current_sessions.session_start
	|	AND NOT ChatAuthorisation.hotel = VALUE(catalog.hotels.emptyRef)
	|	AND ChatAuthorisation.hotel = &hotel";
	Query.SetParameter("hotel", pHotel);
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Unload() ;
	Return SelectionDetailRecords;
EndFunction // GetAutorizaitingAllEmployee

#EndRegion
