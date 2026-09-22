
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure	 - ataprocessor parameter
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // LoadDataProcessorAttributes

// --------------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // SaveDataProcessorAttributes

// --------------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
Procedure pmFillAttributesWithDefaultValues() Export
	
EndProcedure // FillAttributesWithDefaultValues

// --------------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Structure - Parameters
//  pIsInteractive	 - Boolean	 - Is interactive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	vMessage = "";
	vDate = CurrentSessionDate();
	
	If Not ValueIsFilled(ExternalInteraction.LastFullSynchronizationTime) Then
		vObj = ExternalInteraction.GetObject();
		vObj.LastFullSynchronizationTime = BegOfDay(vDate);
		vObj.Write();
	EndIf;
	
	If Not CheckAccessToken(vDate, vMessage) Then
		Return;
	EndIf;
	
	vRoomInterfaceEvents = GetActiveRoomInterfaceEvents(vDate);
	
	vGroupRoomInterfaceEvents = vRoomInterfaceEvents.Copy();
	vGroupRoomInterfaceEvents.GroupBy("ParentDocNumber, ParentDocGuestGroup");
	
	vSuccess = True;
	For Each vGroupRoomInterfaceEvent In vGroupRoomInterfaceEvents Do
		vRoomInterfaceEventsArr = vRoomInterfaceEvents.FindRows(New Structure("ParentDocNumber, ParentDocGuestGroup", vGroupRoomInterfaceEvent.ParentDocNumber, vGroupRoomInterfaceEvent.ParentDocGuestGroup));
		SendRoomInterfaceEvent(vRoomInterfaceEventsArr, vSuccess);
	EndDo;
	
	If vSuccess Then
		vObj = ExternalInteraction.GetObject();
		vObj.LastFullSynchronizationTime = vDate;
		vObj.Write();
	EndIf;
EndProcedure // pmRun

// --------------------------------------------------------------------------------
Procedure SendRoomInterfaceEvent(pRoomInterfaceEvents, rSuccess = False) Export 
	For Each vRoomInterfaceEvent In pRoomInterfaceEvents Do
		vRoomInterfaceEventRef = vRoomInterfaceEvent.Ref;
		vSkip = False;
		vIsError = False;
		vErrorMsg = "";
		
		vType = vRoomInterfaceEvent.TurnOffParameters;
		If Not vRoomInterfaceEvent.IsCanceled Then
			If vRoomInterfaceEvent.PeriodOfStayExtensionIsRequested Then
				vType = vRoomInterfaceEvent.PeriodOfStayExtentionParameters;
			ElsIf vRoomInterfaceEvent.GuestNameChangeIsRequested Then
				vType = vRoomInterfaceEvent.GuestNameChangeParameters;
			ElsIf vRoomInterfaceEvent.RoomChangeIsRequested Then
				vType = vRoomInterfaceEvent.RoomChangeParameters;
			Else
				vType = vRoomInterfaceEvent.TurnOnParameters;
			EndIf;
		EndIf;
		
		vData = "";
		vMethod = "POST";
		If vType = "checkIn" Then
			vData = GetCheckInData(vRoomInterfaceEvent);
			vType = "v1/" + vType;
		Elsif vType = "arrival" Then
			vData = GetArrivalData(vRoomInterfaceEvent);
			vMethod = "PUT";
		Elsif vType = "guest" Then
			vData = GetGuestData(vRoomInterfaceEvent);
			vMethod = "PUT";
		Elsif vType = "move" Then
			vData = GetMoveData(vRoomInterfaceEvent, vSkip, vErrorMsg);
		Elsif vType = "checkout" Then
			vData = GetCheckOutData(vRoomInterfaceEvent, vSkip, vErrorMsg);
		Else
			vIsError = True;
			vErrorMsg = NStr("en = 'Unknown team'; de = 'Unbekanntes Team'; ru = 'Неизвестная команда'");
		EndIf;
		
		If vIsError Or vData = Undefined Then
			vStsObj = vRoomInterfaceEventRef.GetObject();
			vStsObj.IsProcessingError = True;
			vStsObj.ErrorMessage = vErrorMsg;
			vStsObj.Write(DocumentWriteMode.Write);
			rSuccess = False;
			Continue;
		EndIf;
		
		If Not vSkip Then
			vMessage = "";
			vResponse = SendQuery(vData, "/api/pms/" + vType, New Map, vMethod, vMessage);
			If vResponse = Undefined Then
				rSuccess = False;
				Continue;
			EndIf;
		Endif;
		
		vStsObj = vRoomInterfaceEventRef.GetObject();
		vStsObj.IsProcessed = True;
		vStsObj.IsProcessingError = False;
		vStsObj.ErrorMessage = "";
		vStsObj.Write(DocumentWriteMode.Write);
		If vStsObj.IsProcessed And vStsObj.IsCanceled Then
			vStsObj.SetDeletionMark(True);
		EndIf;
	EndDo;
EndProcedure // SendRoomInterfaceEvent

// --------------------------------------------------------------------------------
Function pmReadCart(pExternalEncoderId, rMessage) Export
	vDate = CurrentSessionDate();
	If Not CheckAccessToken(vDate, rMessage) Then
		Return Undefined;
	EndIf;
	
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	If IsBlankString(vEncoderNumber) Then
		rMessage = NStr("en = 'Encoder number not specified'; de = 'Encodernummer nicht angegeben'; ru = 'Не указан номер энкодера'");
		Return Undefined;
	EndIf;
	
	Return SendQuery("", "/api/pms/cardInfo?externalEncoderId=" + vEncoderNumber, New Map, "GET", rMessage);
EndFunction // GetRoomInfo

// --------------------------------------------------------------------------------
Function pmClearKeyCard(rMessage) Export
	vDate = CurrentSessionDate();
	If Not CheckAccessToken(vDate, rMessage) Then
		Return Undefined;
	EndIf;
	
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	If IsBlankString(vEncoderNumber) Then
		rMessage = NStr("en = 'Encoder number not specified'; de = 'Encodernummer nicht angegeben'; ru = 'Не указан номер энкодера'");
		Return Undefined;
	EndIf;
	
	Return SendQuery("", "/api/pms/access?externalEncoderId=" + vEncoderNumber, New Map, "DELETE", rMessage);
EndFunction // GetRoomInfo

// --------------------------------------------------------------------------------
Function pmGetRoomInfo(pRoomCode = "", rMessage) Export
	vDate = CurrentSessionDate();
	If Not CheckAccessToken(vDate, rMessage) Then
		Return Undefined;
	EndIf;
	
	vRoomCode = pRoomCode;
	If ValueIsFilled(Room) And IsBlankString(vRoomCode) Then
		vRoomCode = TrimAll(Room);
		If Not IsBlankString(Room.LockCode) Then
			vRoomCode = Room.LockCode;
		EndIf;
	EndIf;
	
	If IsBlankString(vRoomCode) Then
		rMessage = NStr("en = 'Room is wrong!'; ru = 'Номер комнаты указан неверно!'; de = 'Die Zimmernummer ist falsch!'");
		Return Undefined;
	EndIf;
	
	Return SendQuery("", "/api/pms/roomInfo?roomCode=" + vRoomCode, New Map, "GET", rMessage);
EndFunction // GetRoomInfo

// --------------------------------------------------------------------------------
//
// Parameters:
//  pResponse	 - HttpResponce	 - Http responce
//  pMessage	 - String		 - Return message
// 
// Returns:
//  Boolean - result
//
Function pmGenerateKey(rResponse, pIsKeyCard = False, pAddKey = False, rMessage) Export
	vDate = CurrentSessionDate();
	If Not CheckAccessToken(vDate, rMessage) Then
		Return False;
	EndIf;
	
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	If IsBlankString(vEncoderNumber) Or Not cmIsNumber(vEncoderNumber) Then
		rMessage = NStr("en = 'Encoder number not specified'; de = 'Encodernummer nicht angegeben'; ru = 'Не указан номер энкодера'");
		Return False;
	EndIf;
	
	vData = New Map;
	vData.Insert("externalEncoderId", Number(vEncoderNumber));
	
	vAccess = New Map;
	If pIsKeyCard Then
		vAccess.Insert("typeAccess", 12);
	Else
		vAccess.Insert("typeAccess", 101);
	EndIf;
	
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	
	vAccess.Insert("endDate", Format(vCheckOutDate, "DF='yyyy-MM-dd HH:mm:ss'"));
	
	vRoomCode = "";
	If ValueIsFilled(Room) Then
		vRoomCode = TrimAll(Room);
		If Not IsBlankString(Room.LockCode) Then
			vRoomCode = Room.LockCode;
		EndIf;
	EndIf;
	
	If IsBlankString(vRoomCode) Then
		rMessage = NStr("en = 'Room is wrong!'; ru = 'Номер комнаты указан неверно!'; de = 'Die Zimmernummer ist falsch!'");
		Return False;
	EndIf;
	
	vAccess.Insert("roomCode", vRoomCode);
	
	vAccess.Insert("overwrite", True);
	If pAddKey Then
		vAccess.Insert("overwrite", False);
	EndIf;
	
	vReservation = Undefined;
	If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
		vReservation = ParentDoc.Reservation;
	Else
		vReservation = ParentDoc;
	EndIf;
	
	If ValueIsFilled(vReservation) Then
		vAccess.Insert("guestId", TrimAll(vReservation.UUID()));
	Else
		vAccess.Insert("guestId", TrimAll(ParentDoc.UUID()));
	EndIf;
	
	vZonesArr = StrSplit(DoorLockSystemParameters.AssignedAuthorizations, ",", False);
	
	vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vAssignedAuthorizationsArr = StrSplit(vDoorLockSystemAuthorization.AssignedAuthorizations, ",", False);
		For Each vAssignedAuthorizationRow In vAssignedAuthorizationsArr Do
			If vZonesArr.Find(vAssignedAuthorizationRow) <> Undefined Then
				Continue;
			EndIf;
			
			vZonesArr.Add(vAssignedAuthorizationRow);
		EndDo;
	EndIf;
	
	If ValueIsFilled(DoorLockSystemAuthorization) Then
		vAssignedAuthorizationsArr = StrSplit(DoorLockSystemAuthorization.AssignedAuthorizations, ",", False);
		For Each vAssignedAuthorizationRow In vAssignedAuthorizationsArr Do
			If vZonesArr.Find(vAssignedAuthorizationRow) <> Undefined Then
				Continue;
			EndIf;
			
			vZonesArr.Add(vAssignedAuthorizationRow);
		EndDo;
	EndIf;
	
	vAccess.Insert("zones", vZonesArr);
	
	vData.Insert("access", vAccess);
	
	vResponse = SendQuery(MapToJson(vData), "/api/pms/access", New Map, "POST", rMessage);
	If vResponse = Undefined Then
		Return False;
	EndIf;
	
	vData = vResponse["data"];
	If vResponse["data"] = Undefined Then
		rMessage = NStr("en = 'Error reading lock system response'; de = 'Fehler beim Lesen der Antwort des Sperrsystems'; ru = 'Ошибка чтения ответа замковой системы'");
		Return False;
	EndIf;
	
	rResponse = vData["value"];
	
	If pIsKeyCard Then
		IdentificationCard = cmGetClientIdentificationCard(rResponse, tcDoorLocksAtServer.GetIdentificationCardsRefByCardID(rResponse), ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, True, rResponse);
	EndIf;
	cmWriteKeyCardSecuritySystemEvent(?(pAddKey, "ADD", "NEW") , "", Room, vData, CheckInDate, vCheckOutDate, ParentDoc, Guest);
	
	Return True;
EndFunction // NewKey

// --------------------------------------------------------------------------------
Function pmGetZone(rMessage) Export
	vDate = CurrentSessionDate();
	If Not CheckAccessToken(vDate, rMessage) Then
		Return Undefined;
	EndIf;
	
	Return SendQuery("", "/api/pms/zone", New Map, "GET", rMessage);
EndFunction // pmGetZone

// --------------------------------------------------------------------------------
Function GetActiveRoomInterfaceEvents(pSessionDate, pRoomInterfaceStatus = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInterfaceStatus.Ref AS Ref,
	|	RoomInterfaceStatus.ParentDoc AS ParentDoc,
	|	Accommodations.Reservation AS Reservation,
	|	RoomInterfaceStatus.Room AS Room,
	|	RoomInterfaceStatus.OldRoom AS OldRoom,
	|	RoomInterfaceTypes.TurnOnParameters AS TurnOnParameters,
	|	RoomInterfaceStatus.IsCanceled AS IsCanceled,
	|	RoomInterfaceTypes.TurnOffParameters AS TurnOffParameters,
	|	RoomInterfaceStatus.RoomChangeIsRequested AS RoomChangeIsRequested,
	|	RoomInterfaceTypes.RoomChangeParameters AS RoomChangeParameters,
	|	RoomInterfaceStatus.PeriodOfStayExtensionIsRequested AS PeriodOfStayExtensionIsRequested,
	|	RoomInterfaceTypes.PeriodOfStayExtentionParameters AS PeriodOfStayExtentionParameters,
	|	RoomInterfaceStatus.GuestNameChangeIsRequested AS GuestNameChangeIsRequested,
	|	RoomInterfaceTypes.GuestNameChangeParameters AS GuestNameChangeParameters,
	|	Accommodations.Number AS ParentDocNumber,
	|	Accommodations.GuestGroup AS ParentDocGuestGroup,
	|	Accommodations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef) AS ParentDocIsMain
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|		INNER JOIN Document.Accommodation AS Accommodations
	|		ON ((CAST(RoomInterfaceStatus.ParentDoc AS Document.Accommodation)) = Accommodations.Ref)
	|		INNER JOIN Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
	|		ON RoomInterfaceStatus.RoomInterfaceType = RoomInterfaceTypes.Ref
	|			AND (RoomInterfaceTypes.Ref = &qRoomInterfaceType)
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND RoomInterfaceStatus.Hotel = &qHotel
	|	AND NOT RoomInterfaceStatus.IsProcessed
	|	AND NOT RoomInterfaceStatus.IsProcessingError
	|	AND (Accommodations.CheckInDate <= &qEndOfCurrentDate
	|				AND Accommodations.CheckOutDate >= &qBegOfCurrentDate
	|			OR RoomInterfaceStatus.CancellationDate >= &qLastFullSynchronizationTime)
	|	AND CASE
	|			WHEN &qRoomInterfaceStatusIsEmpty
	|				THEN TRUE
	|			ELSE RoomInterfaceStatus.Ref = &qRoomInterfaceStatus
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	RoomInterfaceStatus.Ref,
	|	RoomInterfaceStatus.ParentDoc,
	|	Reservation.Ref,
	|	RoomInterfaceStatus.Room,
	|	RoomInterfaceStatus.OldRoom,
	|	RoomInterfaceTypes.TurnOnParameters,
	|	RoomInterfaceStatus.IsCanceled,
	|	RoomInterfaceTypes.TurnOffParameters,
	|	RoomInterfaceStatus.RoomChangeIsRequested,
	|	RoomInterfaceTypes.RoomChangeParameters,
	|	RoomInterfaceStatus.PeriodOfStayExtensionIsRequested,
	|	RoomInterfaceTypes.PeriodOfStayExtentionParameters,
	|	RoomInterfaceStatus.GuestNameChangeIsRequested,
	|	RoomInterfaceTypes.GuestNameChangeParameters,
	|	Reservation.Number,
	|	Reservation.GuestGroup,
	|	Reservation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|		INNER JOIN Document.Reservation AS Reservation
	|		ON ((CAST(RoomInterfaceStatus.ParentDoc AS Document.Reservation)) = Reservation.Ref)
	|		INNER JOIN Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
	|		ON RoomInterfaceStatus.RoomInterfaceType = RoomInterfaceTypes.Ref
	|			AND (RoomInterfaceTypes.Ref = &qRoomInterfaceType)
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND RoomInterfaceStatus.Hotel = &qHotel
	|	AND NOT RoomInterfaceStatus.IsProcessed
	|	AND NOT RoomInterfaceStatus.IsProcessingError
	|	AND (Reservation.CheckInDate <= &qEndOfCurrentDate
	|				AND Reservation.CheckOutDate >= &qBegOfCurrentDate
	|			OR RoomInterfaceStatus.CancellationDate >= &qLastFullSynchronizationTime)
	|	AND CASE
	|			WHEN &qRoomInterfaceStatusIsEmpty
	|				THEN TRUE
	|			ELSE RoomInterfaceStatus.Ref = &qRoomInterfaceStatus
	|		END
	|
	|ORDER BY
	|	ParentDocGuestGroup,
	|	ParentDocNumber";
	vQry.SetParameter("qHotel", ExternalInteraction.Hotel);
	vQry.SetParameter("qRoomInterfaceType", RoomInterfaceType);
	vQry.SetParameter("qEndOfCurrentDate", EndOfDay(pSessionDate));
	vQry.SetParameter("qBegOfCurrentDate", BegOfDay(pSessionDate));
	vQry.SetParameter("qLastFullSynchronizationTime", ExternalInteraction.LastFullSynchronizationTime);
	vQry.SetParameter("qRoomInterfaceStatus", pRoomInterfaceStatus);
	vQry.SetParameter("qRoomInterfaceStatusIsEmpty", Not ValueIsFilled(pRoomInterfaceStatus));
	Return vQry.Execute().Unload();
EndFunction // GetActiveRoomInterfaceEvents

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function CheckAccessToken(pDate, rMessage)
	vTokenAlive = 25200;
	
	If Not IsBlankString(ExternalInteraction.OAuth_AccessToken) And ExternalInteraction.SessionStartTime + vTokenAlive > pDate Then
		Return True;
	EndIf;
	
	vHeader = New Map;
	vData = "";
	vType = "";
	vMethod = "POST";
	
	If IsBlankString(ExternalInteraction.OAuth_RefreshToken) Then
		vType = "/Account/Login";
		vDataMap = New Map;
		vDataMap.Insert("username", ExternalInteraction.Login);
		vDataMap.Insert("password", ExternalInteraction.Password);
		vData = MapToJson(vDataMap);
	Else
		vType = "/Account/RefreshToken";
		vHeader.Insert("Authorization", "Bearer " + ExternalInteraction.OAuth_RefreshToken);
		vMethod = "GET";
	EndIf;
	
	vResponse = SendQuery(vData, vType, vHeader, vMethod, rMessage);
	If vResponse = Undefined Then
		If vType = "/Account/RefreshToken" Then
			vIntParObj							= ExternalInteraction.GetObject();
			vIntParObj.SessionStartTime		= '00010101';
			vIntParObj.OAuth_AccessToken	= "";
			vIntParObj.OAuth_RefreshToken	= "";
			vIntParObj.Write();
			
			rMessage = "";
			Return CheckAccessToken(pDate, rMessage);
		EndIf;
		Return False;
	EndIf;
	
	vIntParObj							= ExternalInteraction.GetObject();
	vIntParObj.SessionStartTime		= pDate;
	vIntParObj.OAuth_AccessToken	= vResponse["access_token"];
	vIntParObj.OAuth_RefreshToken	= vResponse["access_token_refresh"];
	vIntParObj.Write();
	Return True;
EndFunction // CheckAccessToken

// --------------------------------------------------------------------------------
Function GetCheckInData(pRoomInterfaceEvent)
	vParentDoc = pRoomInterfaceEvent.ParentDoc;
	
	vRoomCode = "";
	vRoom = pRoomInterfaceEvent.Room;
	If ValueIsFilled(vRoom) Then
		vRoomCode = TrimAll(vRoom);
		If Not IsBlankString(vRoom.LockCode) Then
			vRoomCode = vRoom.LockCode;
		EndIf;
	EndIf;
	
	vData = New Map;
	vData.Insert("roomCode", vRoomCode);
	vData.Insert("startDate", Format(vParentDoc.CheckInDate, "DF='yyyy-MM-dd HH:mm:ss'"));
	vData.Insert("endDate", Format(vParentDoc.CheckOutDate, "DF='yyyy-MM-dd HH:mm:ss'"));
	vData.Insert("comment", Undefined);
	vData.Insert("complexId", Undefined);
	
	vGuestMap = New Map;
	
	vReservation = Undefined;
	If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
		vReservation = vParentDoc.Reservation;
	Else
		vReservation = vParentDoc;
	EndIf;
	
	If ValueIsFilled(vReservation) Then
		vGuestMap.Insert("guestId", TrimAll(vReservation.UUID()));
	Else
		vGuestMap.Insert("guestId", TrimAll(vParentDoc.UUID()));
	EndIf;
	
	vGuest = vParentDoc.Guest;
	If ValueIsFilled(vGuest) Then
		vGuestMap.Insert("firstName", TrimAll(vGuest.FirstName));
		vGuestMap.Insert("lastName", TrimAll(vGuest.LastName));
		vGuestMap.Insert("patronymic", TrimAll(vGuest.SecondName));
		
		If Not IsBlankString(vParentDoc.Phone) Then
			vGuestMap.Insert("phone", SMS.GetValidPhoneNumber(vParentDoc.Phone));
		ElsIf Not IsBlankString(vGuest.Phone) Then
			vGuestMap.Insert("phone", SMS.GetValidPhoneNumber(vGuest.Phone));
		Else
			vGuestMap.Insert("phone", Undefined);
		EndIf;
		vGuestMap.Insert("email", TrimAll(vGuest.SecondName));
		
		If Not IsBlankString(vParentDoc.EMail) Then
			vGuestMap.Insert("email", TrimAll(vParentDoc.EMail));
		ElsIf Not IsBlankString(vGuest.EMail) Then
			vGuestMap.Insert("email", TrimAll(vGuest.EMail));
		Else
			vGuestMap.Insert("email", Undefined);
		EndIf;
	EndIf;
	
	vGuestsArr = New Array;
	vGuestsArr.Add(vGuestMap);
	vData.Insert("guests", vGuestsArr);
	
	Return MapToJson(vData);
EndFunction // GetCheckInData

// --------------------------------------------------------------------------------
Function GetArrivalData(pRoomInterfaceEvent)
	vParentDoc = pRoomInterfaceEvent.ParentDoc;
	
	vRoomCode = "";
	vRoom = pRoomInterfaceEvent.Room;
	If ValueIsFilled(vRoom) Then
		vRoomCode = TrimAll(vRoom);
		If Not IsBlankString(vRoom.LockCode) Then
			vRoomCode = vRoom.LockCode;
		EndIf;
	EndIf;
	
	vData = New Map;
	vData.Insert("roomCode", vRoomCode);
	vData.Insert("complexId", Undefined);
	
	vGuestMap = New Map;
	
	vReservation = Undefined;
	If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
		vReservation = vParentDoc.Reservation;
	Else
		vReservation = vParentDoc;
	EndIf;
	
	If ValueIsFilled(vReservation) Then
		vGuestMap.Insert("guestId", TrimAll(vReservation.UUID()));
	Else
		vGuestMap.Insert("guestId", TrimAll(vParentDoc.UUID()));
	EndIf;
	
	vGuestMap.Insert("startDate", Format(vParentDoc.CheckInDate, "DF='yyyy-MM-dd HH:mm:ss'"));
	vGuestMap.Insert("endDate", Format(vParentDoc.CheckOutDate, "DF='yyyy-MM-dd HH:mm:ss'"));
	
	vGuestsArr = New Array;
	vGuestsArr.Add(vGuestMap);
	vData.Insert("guests", vGuestsArr);
	
	Return MapToJson(vData);
EndFunction // GetArrivalData

// --------------------------------------------------------------------------------
Function GetGuestData(pRoomInterfaceEvent)
	vParentDoc = pRoomInterfaceEvent.ParentDoc;
	
	vRoomCode = "";
	vRoom = pRoomInterfaceEvent.Room;
	If ValueIsFilled(vRoom) Then
		vRoomCode = TrimAll(vRoom);
		If Not IsBlankString(vRoom.LockCode) Then
			vRoomCode = vRoom.LockCode;
		EndIf;
	EndIf;
	
	vGuestMap = New Map;
	
	vReservation = Undefined;
	If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
		vReservation = vParentDoc.Reservation;
	Else
		vReservation = vParentDoc;
	EndIf;
	
	If ValueIsFilled(vReservation) Then
		vGuestMap.Insert("guestId", TrimAll(vReservation.UUID()));
	Else
		vGuestMap.Insert("guestId", TrimAll(vParentDoc.UUID()));
	EndIf;
	
	vGuest = vParentDoc.Guest;
	If ValueIsFilled(vGuest) Then
		vGuestMap.Insert("firstName", TrimAll(vGuest.FirstName));
		vGuestMap.Insert("lastName", TrimAll(vGuest.LastName));
		vGuestMap.Insert("patronymic", TrimAll(vGuest.SecondName));
		
		If Not IsBlankString(vParentDoc.Phone) Then
			vGuestMap.Insert("phone", SMS.GetValidPhoneNumber(vParentDoc.Phone));
		ElsIf Not IsBlankString(vGuest.Phone) Then
			vGuestMap.Insert("phone", SMS.GetValidPhoneNumber(vGuest.Phone));
		Else
			vGuestMap.Insert("phone", Undefined);
		EndIf;
		vGuestMap.Insert("email", TrimAll(vGuest.SecondName));
		
		If Not IsBlankString(vParentDoc.EMail) Then
			vGuestMap.Insert("email", TrimAll(vParentDoc.EMail));
		ElsIf Not IsBlankString(vGuest.EMail) Then
			vGuestMap.Insert("email", TrimAll(vGuest.EMail));
		Else
			vGuestMap.Insert("email", Undefined);
		EndIf;
	EndIf;
	
	vGuestsArr = New Array;
	vGuestMap.Insert("complexId", Undefined);
	
	Return MapToJson(vGuestMap);
EndFunction // GetGuestData

// --------------------------------------------------------------------------------
Function GetMoveData(pRoomInterfaceEvent, rSkip, rMessage)
	vParentDoc = pRoomInterfaceEvent.ParentDoc;
	
	vRoomCode = "";
	vRoom = pRoomInterfaceEvent.Room;
	If ValueIsFilled(vRoom) Then
		vRoomCode = TrimAll(vRoom);
		If Not IsBlankString(vRoom.LockCode) Then
			vRoomCode = vRoom.LockCode;
		EndIf;
	EndIf;
	
	vData = New Map;
	vData.Insert("roomCode", vRoomCode);
	vData.Insert("endDate", Format(vParentDoc.CheckOutDate, "DF='yyyy-MM-dd HH:mm:ss'"));
	vData.Insert("complexId", Undefined);
	
	
	vOldRoomCode = "";
	vRoom = pRoomInterfaceEvent.OldRoom;
	If ValueIsFilled(vRoom) Then
		vOldRoomCode = TrimAll(vRoom);
		If Not IsBlankString(vRoom.LockCode) Then
			vOldRoomCode = vRoom.LockCode;
		EndIf;
	EndIf;
	
	vIDs = GetGuestCheckInID(vOldRoomCode, rMessage);
	If vIDs = Undefined Then
		Return Undefined;
	EndIf;
	
	vGuestMap = New Map;
	
	vReservation = Undefined;
	If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
		vReservation = vParentDoc.Reservation;
	Else
		vReservation = vParentDoc;
	EndIf;
	
	If ValueIsFilled(vReservation) Then
		vGuestMap.Insert("guestId", TrimAll(vReservation.UUID()));
	Else
		vGuestMap.Insert("guestId", TrimAll(vParentDoc.UUID()));
	EndIf;
	
	vID = vIDs[vGuestMap["guestId"]];
	If vID = Undefined Then
		rSkip = True;
	EndIf;
	
	vGuestMap.Insert("id", vID);
	
	vGuestsArr = New Array;
	vGuestsArr.Add(vGuestMap);
	vData.Insert("guests", vGuestsArr);
	
	Return MapToJson(vData);
EndFunction // GetMoveData

// --------------------------------------------------------------------------------
Function GetCheckOutData(pRoomInterfaceEvent, rSkip, rMessage)
	vParentDoc = pRoomInterfaceEvent.ParentDoc;
	
	vRoomCode = "";
	vRoom = pRoomInterfaceEvent.Room;
	If ValueIsFilled(vRoom) Then
		vRoomCode = TrimAll(vRoom);
		If Not IsBlankString(vRoom.LockCode) Then
			vRoomCode = vRoom.LockCode;
		EndIf;
	EndIf;
	
	vData = New Map;
	vData.Insert("complexId", Undefined);
	
	vIDs = GetGuestCheckInID(vRoomCode, rMessage);
	If vIDs = Undefined Then
		Return Undefined;
	EndIf;
	
	vGuestMap = New Map;
	
	vReservation = Undefined;
	If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
		vReservation = vParentDoc.Reservation;
	Else
		vReservation = vParentDoc;
	EndIf;
	
	If ValueIsFilled(vReservation) Then
		vGuestMap.Insert("guestId", TrimAll(vReservation.UUID()));
	Else
		vGuestMap.Insert("guestId", TrimAll(vParentDoc.UUID()));
	EndIf;
	
	vID = vIDs[vGuestMap["guestId"]];
	If vID = Undefined Then
		rSkip = True;
	EndIf;
	
	vGuestMap.Insert("id", vID);
	
	vGuestsArr = New Array;
	vGuestsArr.Add(vGuestMap);
	vData.Insert("guests", vGuestsArr);
	
	Return MapToJson(vData);
EndFunction // GetCheckOutData

// --------------------------------------------------------------------------------
Function SendQuery(pJSON, pType, pHeader, pMethod = "POST", rMessage)
	vHTTPServer = "127.0.0.1";
	If ValueIsFilled(ExternalInteraction.HttpServer) Then
		vHTTPServer = StrReplace(StrReplace(ExternalInteraction.HttpServer, "https://", ""), "http://", "");
		If Right(TrimAll(vHTTPServer), 1) = "/" Then
			vHTTPServer = Left(vHTTPServer, StrLen(vHTTPServer) - 1);
		EndIf;
	EndIf;
	
	Try
		vSSLSecure = Undefined;
		If ExternalInteraction.HttpUseSsl Then
			vSSLSecure = New OpenSSLSecureConnection(Undefined, Undefined);
		EndIf;
		
		vHTTPConnection = New HTTPConnection(vHTTPServer, , , , , , vSSLSecure);
		
		pHeader.Insert("Content-Type", "application/json");
		If pHeader["Authorization"] = Undefined Then
			pHeader.Insert("Authorization", "Bearer " + ExternalInteraction.OAuth_AccessToken);
		EndIf;
		
		vHTTPRequest = New HTTPRequest(TrimAll(pType), pHeader);
		If Not IsBlankString(pJSON) Then
			vHTTPRequest.SetBodyFromString(pJSON, TextEncoding.UTF8);
		EndIf;
		
		vHTTPResponse = vHTTPConnection.CallHTTPMethod(pMethod, vHTTPRequest);
		
		vResponseBody = vHTTPResponse.GetBodyAsString(TextEncoding.UTF8);
		If vHTTPResponse.StatusCode <> 200 Then
			If vHTTPResponse.StatusCode = 401 Then
				vIntParObj							= ExternalInteraction.GetObject();
				vIntParObj.OAuth_AccessToken	= "";
				vIntParObj.Write();
			EndIf;
			
			rMessage = vResponseBody;
			
			vResponseMap = JsonToMap(vResponseBody);
			If vResponseMap <> Undefined Then
				vErrorMessages = vResponseMap["errorMessages"];
				If vErrorMessages <> Undefined Then
					rMessage = "";
					For Each vErrorMessage In vErrorMessages Do
						rMessage = rMessage + Format(vErrorMessage["errorCode"], "NFD=0; NZ=0") + " - " + vErrorMessage["errorMessage"] + Chars.LF;
					EndDo;
				EndIf;
			EndIf;
			
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, pType, Enums.ExternalSystemEventTypes.Error, pJSON, vResponseBody, rMessage, ExternalInteraction.MaxLogLenght);
			Return Undefined;
		EndIf;
		
		If ExternalInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, pType, Enums.ExternalSystemEventTypes.Info, pJSON, vResponseBody, , ExternalInteraction.MaxLogLenght);
		EndIf;
		
		Return JsonToMap(vResponseBody);
	Except
		vError = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, pType, Enums.ExternalSystemEventTypes.Error, pJSON,"","Failed to send post query! " + DetailErrorDescription(vError), ExternalInteraction.MaxLogLenght);
		rMessage = BriefErrorDescription(vError);
		Return Undefined;
	EndTry;
EndFunction // SendQuery

// --------------------------------------------------------------------------------
Function GetGuestCheckInID(pRoomCode, rMessage)
	vIds = New Map;
	
	vRoomInfo = pmGetRoomInfo(pRoomCode, rMessage);
	If vRoomInfo = Undefined Then
		Return Undefined;
	EndIf;
	
	vData = vRoomInfo["data"];
	If vData <> Undefined Then
		vValue = vData["value"];
		If vValue <> Undefined Then
			For Each vGuest In vValue["guests"] Do
				vIds.Insert(vGuest["guestId"], vGuest["id"]);
			EndDo;
		EndIf;
	EndIf;
	
	Return vIds;
EndFunction // GetGuestCheckInID

// --------------------------------------------------------------------------------
Function MapToJson(pMap)
	vJSONWriter = New JSONWriter;
	vJSONWriter.SetString();
	WriteJSON(vJSONWriter, pMap);
	Return vJSONWriter.Close();
EndFunction // MapToJson

// --------------------------------------------------------------------------------
Function JsonToMap(pJson, rMessage = "")
	Try
		vJSONReader = New JSONReader;
		vJSONReader.SetString(pJson);
		Return ReadJSON(vJSONReader, True);
	Except
		rMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	Return Undefined;
EndFunction // MapToJson

#EndRegion
