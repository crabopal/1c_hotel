#Region EventHandlers 

// -----------------------------------------------------------------------------
Function WriteSafetyEvent(pHotelCode, pEventType, pPeriod, pRoomCode, pCardType, pCardCode, pEventDescription, pPeriodFrom = '00010101', pPeriodTo = '00010101', pNumberOfKeys = 0, pExtSystemCode)
	WriteLogEvent(NStr("en='SafetySystem.WriteEvent'; de='SafetySystem.WriteEvent'; ru='СистемаБезопасности.ЗаписатьСобытие'"), EventLogLevel.Information, , , 
	              TrimR(pHotelCode) + ", " + TrimR(pEventType) + ", " + pPeriod + ", " + TrimR(pRoomCode) + ", " + TrimR(pCardType) + ", " + TrimR(pCardCode) + ", " + TrimR(pEventDescription) + ", " + pPeriodFrom + ", " + pPeriodTo + ", " + pNumberOfKeys + ", " + TrimR(pExtSystemCode));
	Try
		// Get hotel by hotel code
		vHotel = cmGetHotelByCode(pHotelCode, pExtSystemCode);
		// Get room by room code
		vRoom = Catalogs.Rooms.EmptyRef();
		If Not IsBlankString(pRoomCode) Then
			vRoom = cmGetRoomByCode(pRoomCode, pHotelCode, pExtSystemCode);
		EndIf;
		// Write record to the information register
		vRecMgr = InformationRegisters.SafetySystemEvents.CreateRecordManager();
		vRecMgr.Period = ?(ValueIsFilled(pPeriod), pPeriod, CurrentSessionDate());
		vRecMgr.Author = SessionParameters.CurrentUser;
		vRecMgr.Hotel = vHotel;
		vRecMgr.Room = vRoom;
		vRecMgr.EventType = pEventType;
		vRecMgr.CardType = pCardType;
		vRecMgr.CardCode = pCardCode;
		vRecMgr.EventDescription = pEventDescription;
		vRecMgr.PeriodFrom = pPeriodFrom;
		vRecMgr.PeriodTo = pPeriodTo;
		vRecMgr.NumberOfKeys = pNumberOfKeys;
		vRecMgr.Write();
		Return "";
	Except
		Return Left(ErrorDescription(), 2048);
	EndTry;
EndFunction // WriteSafetyEvent

#EndRegion