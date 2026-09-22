#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion

#Region EventHandlers

// ----------------------------------------------------------------------------
Procedure PresentationGetProcessing(pData, pPresentation, pStandardProcessing)
	vRef = pData.Ref;
	If ValueIsFilled(vRef) And vRef.Posted Then
		vGuest = vRef.Guest;
		vRoom = vRef.Room;
		vRoomType = vRef.RoomType;
		pPresentation = NStr("en='N'; ru='№'; de='N'") + TrimAll(pData.Number) + 
		                NStr("en = ' Reservation'; ru = ' Бронь'; de = ' Reservierung'") + 
		                ?(ValueIsFilled(vGuest), " " + Trimall(vGuest.FullName), "") + 
					    NStr("en = ' from '; ru = ' c '; de = ' ab '") + Format(vRef.CheckInDate, "DF=dd.MM.yyyy") + 
					    ?(ValueIsFilled(vRoom), " " + TrimAll(vRoom.Description), "") + 
					    ?(ValueIsFilled(vRoomType), " " + TrimAll(vRoomType.Code), "");
		pStandardProcessing = False;
	EndIf;
EndProcedure //  PresentationGetProcessing

// ----------------------------------------------------------------------------
Procedure FormGetProcessing(pFormType, pParameters, pSelectedForm, pAdditionalInformation, pStandardProcessing)
	SetPrivilegedMode(True);
	vCurSession = GetCurrentInfoBaseSession();
	SetPrivilegedMode(False);
	vSessionNumber = vCurSession.SessionNumber;
	vSessionStartTime = vCurSession.SessionStarted;
	vAppRunMode = CachedCommonFunctions.cmGetAppRunMode(vSessionNumber, vSessionStartTime);
	If vAppRunMode.MobileDeviceMode Then 
		If pFormType = "ObjectForm" Or pSelectedForm = "tcDocumentForm" Then
			pStandardProcessing = False;
			pSelectedForm = "mcDocumentForm";
		EndIf; 
	EndIf;
EndProcedure //  FormGetProcessing

#EndRegion