#Region Public

// -----------------------------------------------------------------------------
//  Function - Send query
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pCommand				 - String								 - Command
// 
// Returns:
//  Boolean - Status
//
Function SendQuery(pInteractionParameters, pCommand) Export  	
	vHttp = StrReplace(StrReplace(pInteractionParameters.HttpServer, "https://", ""), "http://", "");
	vHTTPServer = Left(vHttp, StrFind(vHttp, "/") - 1);
	vType = Right(vHttp, StrLen(vHttp) - StrFind(vHttp, "/") + 1);  
	Try
	
		// HTTP connection
		vHTTPConnection = New HTTPConnection(vHTTPServer,,,,, 15);
		
		vHeaders = New Map;
		vHeaders.Insert("Token", pInteractionParameters.InteractionID); 
		
		// Send query
		vHTTPRequest = New HTTPRequest(TrimAll(vType), vHeaders);

		vHTTPRequest.SetBodyFromString(pCommand, TextEncoding.UTF8);

		vRS = vHTTPConnection.CallHTTPMethod("POST", vHTTPRequest); 
	   
		Return vRS.StatusCode = 200;
	Except
		vError = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "Send", Enums.ExternalSystemEventTypes.Error, cmReplaceControlCharacters(pCommand), "", NStr("en = 'Failed to send query! '; de = 'Запрос не может быть отправлен! '; ru = 'Не удалось отправить запрос! '") + DetailErrorDescription(vError), pInteractionParameters.MaxLogLenght); 
		Return False;
	EndTry;	
EndFunction // SendQuery 

// -----------------------------------------------------------------------------
Function ParsResponse(Val pStrResponse) Export
	vMapResponse = New Map();
	vMapResponse.Insert("Command", "");
	vStrResponse = "";
	vStrResponse = StrReplace(StrReplace(pStrResponse, Char(2), ""), Char(3), "");	  
	If ValueIsFilled(vStrResponse) Then
		vArrResponse = StrSplit(vStrResponse, Char(124), False);
		vArrResponseCount = vArrResponse.Count(); 
		If vArrResponseCount > 0 Then
			vMapResponse["Command"] = vArrResponse[0];
			If vArrResponseCount > 1 Then
				For i = 1 To vArrResponseCount - 1 Do
					If StrLen(vArrResponse[i]) >= 2 Then
						vParamName = Left(vArrResponse[i], 2);
						vParamValue = "";
						If StrLen(vArrResponse[i]) > 2 Then 
							vParamValue = Right(vArrResponse[i], StrLen(vArrResponse[i]) - 2);
						EndIf;
						vMapResponse.Insert(vParamName, vParamValue); 
					EndIf;
				EndDo;
			EndIf;
		EndIf;	
	EndIf;
	Return vMapResponse;
EndFunction // ParsResponse

// -----------------------------------------------------------------------------
Function GetLinkStart(pCurDate) Export 
	Return "LS" + Char(124) + "DA" + Format(pCurDate, "DF=yyMMdd") + Char(124) + "TI" + Format(pCurDate, "DF=HHmmss") + Char(124);
EndFunction // GetLinkStart

// -----------------------------------------------------------------------------
Function GetLinkAlive(pCurDate) Export 
	Return "LA" + Char(124) + "DA" + Format(pCurDate, "DF=yyMMdd") + Char(124) + "TI" + Format(pCurDate, "DF=HHmmss") + Char(124);
EndFunction // GetLinkAlive

// -----------------------------------------------------------------------------
Function GetLinkEnd(pCurDate) Export 
	Return "LE" + Char(124) + "DA" + Format(pCurDate, "DF=yyMMdd") + Char(124) + "TI" + Format(pCurDate, "DF=HHmmss") + Char(124);
EndFunction // GetLinkEnd

// -----------------------------------------------------------------------------
Function GetResyncStart(pCurDate) Export 
	Return "DS" + Char(124) + "DA" + Format(pCurDate, "DF=yyMMdd") + Char(124) + "TI" + Format(pCurDate, "DF=HHmmss") + Char(124);
EndFunction // GetResyncStart

// -----------------------------------------------------------------------------
Function GetResyncEnd(pCurDate) Export 
	Return "DE" + Char(124) + "DA" + Format(pCurDate, "DF=yyMMdd") + Char(124) + "TI" + Format(pCurDate, "DF=HHmmss") + Char(124);
EndFunction // GetResyncEnd

// -----------------------------------------------------------------------------
Function GetGuestCheckIn(pInteractionParameters, pLinkRecords, pDoDataTransliteration, pDocument, pGuestIndexInRoom, pRoom, pDateTime, pMiniberRights, pNoPostStatus, pTVRights, pVideoRights, pIsSync) Export 				  					 					 					 
	vCommandArr = New Array();
	vRoomsArr = GetObjectExternalSystemCodeByRef(pInteractionParameters, "Rooms", pRoom);
	For Each vRowRoom In vRoomsArr Do 
		vCommandArr.Add(GetGuestCheckInByRoomCode(pLinkRecords, pDoDataTransliteration, pDocument, pGuestIndexInRoom, vRowRoom, pDateTime, pMiniberRights, pNoPostStatus, pTVRights, pVideoRights, pIsSync));
	EndDo;
	Return vCommandArr;
EndFunction // GetGuestCheckIn

// -----------------------------------------------------------------------------
Function GetGuestCheckInByRoomCode(pLinkRecords, pDoDataTransliteration, pDocument, pGuestIndexInRoom, pRoom, pDateTime, pMiniberRights, pNoPostStatus, pTVRights, pVideoRights, pIsSync) Export 				  					 					 					 
	vCommand = "GI" + Char(124);
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "G#", Right(cmGetDocumentNumberPresentation(pDocument.Number), 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "RN", Left(TrimAll(pRoom), 8));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "GS", "N");
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "DA", Format(pDateTime, "DF=yyMMdd"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "TI", Format(pDateTime, "DF=HHmmss"));	
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "GA", ?(ValueIsFilled(pDocument.CheckInDate), Format(pDocument.CheckInDate, "DF=yyMMdd"), ""));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "GD", ?(ValueIsFilled(pDocument.CheckOutDate), Format(pDocument.CheckOutDate, "DF=yyMMdd"), ""));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "GG", Right(Format(pDocument.GuestGroup.Code, "NFD=0; NZ=0; NG="), 10));
	vGuest = pDocument.Guest; 
	If ValueIsFilled(vGuest) Then
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "GF", Left(Transliterate(vGuest.FirstName, pDoDataTransliteration), 40));
		vSalutation = vGuest.Salutation;
		If ValueIsFilled(vSalutation) Then
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "GT", Left(Transliterate(vSalutation.Title, pDoDataTransliteration), 20));
		EndIf;
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "GL", Left(GetLanguageCode(vGuest.Language), 2));
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "G+", Right(cmGetDocumentNumberPresentation(vGuest.Code), 10));
		vClientType = vGuest.ClientType; 
		If ValueIsFilled(vClientType) Then
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "GV", Right(cmGetDocumentNumberPresentation(vClientType.Code), 20));
		EndIf;
	EndIf; 
	vGuestFullName = "";
	If ValueIsFilled(vGuest) Then
		If pLinkRecords.FindRows(New Structure("LinkRecordCommand, LinkRecordParameter", "GI", "GF")).Count() > 0 Then 
			vGuestFullName = Left(vGuest.LastName, 200);	
		ElsIf ValueIsFilled(vGuest.FullName) Then  
			vGuestFullName = Left(vGuest.FullName, 200);	
		EndIf;
	EndIf;
	If Not ValueIsFilled(vGuestFullName) Then
		If ValueIsFilled(pDocument.GuestFullName) Then 
			vGuestFullName = Left(pDocument.GuestFullName, 200);
		Else
			vGuestFullName = Right(cmGetDocumentNumberPresentation(pDocument.Number), 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG=");	
		EndIf; 
	EndIf;
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "GN", Left(Transliterate(vGuestFullName, pDoDataTransliteration), 200));	
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "MR", Left(pMiniberRights, 2));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "NP", Left(pNoPostStatus, 1));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "TV", Left(pTVRights, 2));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GI", "VR", Left(pVideoRights, 2));
	If pIsSync Then
		vCommand = vCommand + "SF" + Char(124);	
	EndIf;
	Return vCommand;
EndFunction // GetGuestCheckInByRoomCode

// -----------------------------------------------------------------------------
Function GetGuestCheckOut(pInteractionParameters, pLinkRecords, pDocument, pGuestIndexInRoom, pRoom, pDateTime, pIsSync) Export 
	vCommandArr = New Array();
	vRoomsArr = GetObjectExternalSystemCodeByRef(pInteractionParameters, "Rooms", pRoom);
	For Each vRowRoom In vRoomsArr Do
		vCommandArr.Add(GetGuestCheckOutByRoomCode(pLinkRecords, pDocument, pGuestIndexInRoom, vRowRoom, pDateTime, pIsSync));
	EndDo;
	Return vCommandArr;
EndFunction // GetGuestCheckOut

// -----------------------------------------------------------------------------
Function GetGuestCheckOutByRoomCode(pLinkRecords, pDocument, pGuestIndexInRoom, pRoom, pDateTime, pIsSync) Export 
	vCommand = "GO" + Char(124);
	If Not pIsSync Then
		If ValueIsFilled(pDocument) Then
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GO", "G#", Right(cmGetDocumentNumberPresentation(pDocument.Number), 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="));
		EndIf;    
	EndIf;
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GO", "RN", Left(TrimAll(pRoom), 8));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GO", "GS", "N");
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GO", "DA", Format(pDateTime, "DF=yyMMdd"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GO", "TI", Format(pDateTime, "DF=HHmmss"));
	If pIsSync Then
		vCommand = vCommand + "SF" + Char(124);	
	EndIf;
	Return vCommand;
EndFunction // GetGuestCheckOutByRoomCode

// -----------------------------------------------------------------------------
Function GetGuestCheckChange(pInteractionParameters, pLinkRecords, pDoDataTransliteration, pDocument, pGuestIndexInRoom, pRoom, pDateTime, pMiniberRights, pNoPostStatus, pTVRights, pVideoRights, pOldRoom) Export 					 					 
	vCommandArr = New Array();
	vRoomsArr = GetObjectExternalSystemCodeByRef(pInteractionParameters, "Rooms", pRoom);
	vOldRoomArr = GetObjectExternalSystemCodeByRef(pInteractionParameters, "Rooms", pOldRoom);
	
	If vRoomsArr.Count() > 0 And vOldRoomArr.Count() > 0 And vRoomsArr.Count() > vOldRoomArr.Count() Then
		vAmountOfDifference = vRoomsArr.Count() - vOldRoomArr.Count();
		For vNumber = 0 To vAmountOfDifference - 1 Do
			vCommandArr.Add(GetGuestCheckInByRoomCode(pLinkRecords, pDoDataTransliteration, pDocument, pGuestIndexInRoom, vRoomsArr[0], pDateTime, pMiniberRights, pNoPostStatus, pTVRights, pVideoRights, False));		
			vRoomsArr.Delete(0);
		EndDo;
	EndIf;
	For Each vRowRoom In vRoomsArr Do
		vCommandArr.Add(GetGuestCheckChangeByRoomCode(pLinkRecords, pDoDataTransliteration, pDocument, pGuestIndexInRoom, vRowRoom, pDateTime, pMiniberRights, pNoPostStatus, pTVRights, pVideoRights, vOldRoomArr));
	EndDo;
	For Each vRowRoom In vOldRoomArr Do 
		vCommandArr.Add(GetGuestCheckOutByRoomCode(pLinkRecords, pDocument, pGuestIndexInRoom, vRowRoom, pDateTime, False)); 	
	EndDo;
	Return vCommandArr;
EndFunction // GetGuestCheckChange

// -----------------------------------------------------------------------------
Function GetGuestCheckChangeByRoomCode(pLinkRecords, pDoDataTransliteration, pDocument, pGuestIndexInRoom, pRoom, pDateTime, pMiniberRights, pNoPostStatus, pTVRights, pVideoRights, rOldRoomArr)
	vCommand = "GC" + Char(124);					 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "G#", Right(cmGetDocumentNumberPresentation(pDocument.Number), 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "RN", Left(TrimAll(pRoom), 8));
	If rOldRoomArr.Count() > 0 And Not IsBlankString(rOldRoomArr[0]) Then
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "RO", Left(TrimAll(rOldRoomArr[0]), 8));	
		rOldRoomArr.Delete(0);
	EndIf;
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "GS", "N");
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "DA", Format(pDateTime, "DF=yyMMdd"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "TI", Format(pDateTime, "DF=HHmmss"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "GA", ?(ValueIsFilled(pDocument.CheckInDate), Format(pDocument.CheckInDate, "DF=yyMMdd"), ""));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "GD", ?(ValueIsFilled(pDocument.CheckOutDate), Format(pDocument.CheckOutDate, "DF=yyMMdd"), ""));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "GG", Right(Format(pDocument.GuestGroup.Code, "NFD=0; NZ=0; NG="), 10));
	vGuest = pDocument.Guest; 
	If ValueIsFilled(vGuest) Then
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "GF", Left(Transliterate(vGuest.FirstName, pDoDataTransliteration), 40));
		vSalutation = vGuest.Salutation;
		If ValueIsFilled(vSalutation) Then
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "GT", Left(Transliterate(vSalutation.Title, pDoDataTransliteration), 20));
		EndIf;
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "GL", Left(GetLanguageCode(vGuest.Language), 2));
		vClientType = vGuest.ClientType; 
		If ValueIsFilled(vClientType) Then
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "GV", Right(cmGetDocumentNumberPresentation(vClientType.Code), 20));
		EndIf;
	EndIf;        
	vGuestFullName = "";
	If ValueIsFilled(vGuest) Then
		If pLinkRecords.FindRows(New Structure("LinkRecordCommand, LinkRecordParameter", "GI", "GF")).Count() > 0 Then 
			vGuestFullName = Left(vGuest.LastName, 200);	
		ElsIf ValueIsFilled(vGuest.FullName) Then  
			vGuestFullName = Left(vGuest.FullName, 200);	
		EndIf;
	EndIf;
	If Not ValueIsFilled(vGuestFullName) Then
		If ValueIsFilled(pDocument.GuestFullName) Then 
			vGuestFullName = Left(pDocument.GuestFullName, 200);
		Else
			vGuestFullName = Right(cmGetDocumentNumberPresentation(pDocument.Number), 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG=");	
		EndIf; 
	EndIf;
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "GN", Left(Transliterate(vGuestFullName, pDoDataTransliteration), 200));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "MR", Left(pMiniberRights, 2));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "NP", Left(pNoPostStatus, 1));		
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "TV", Left(pTVRights, 2));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "GC", "VR", Left(pVideoRights, 2));
	Return vCommand;
EndFunction // GetGuestCheckChangeByRoomCode

// -----------------------------------------------------------------------------
Function GetRoomEquipmentStatus(pInteractionParameters, pLinkRecords, pRoom, pDocument, pGuestIndexInRoom, pClassOfService, pDND, pMessageLightStatus, pMinibarRights, pTVRights) Export 
	vCommandArr = New Array();
	vRoomsArr = GetObjectExternalSystemCodeByRef(pInteractionParameters, "Rooms", pRoom);
	For Each vRowRoom In vRoomsArr Do
		vCommandArr.Add(GetRoomEquipmentStatusByRoomCode(pLinkRecords, vRowRoom, pDocument, pGuestIndexInRoom, pClassOfService, pDND, pMessageLightStatus, pMinibarRights, pTVRights));
	EndDo;
	Return vCommandArr;
EndFunction // GetRoomEquipmentStatus

// -----------------------------------------------------------------------------
Function GetRoomEquipmentStatusByRoomCode(pLinkRecords, pRoom, pDocument, pGuestIndexInRoom, pClassOfService, pDND, pMessageLightStatus, pMinibarRights, pTVRights)
	vCommand = "RE" + Char(124);					 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "RE", "RN", Left(TrimAll(pRoom), 8));
	If ValueIsFilled(pMessageLightStatus) Then
		If ValueIsFilled(pDocument) And ValueIsFilled(pDocument.Number) Then 
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "RE", "G#", Left(pDocument.Number, 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="));
		EndIf;
	EndIf;
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "RE", "CS", Left(pClassOfService, 1));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "RE", "DN", Left(pDND, 1));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "RE", "ML", Left(pMessageLightStatus, 1));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "RE", "MR", Left(pMinibarRights, 2));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "RE", "TV", Left(pTVRights, 2));
	Return vCommand;
EndFunction // GetRoomEquipmentStatusByRoomCode

// -----------------------------------------------------------------------------
Function GetWakeupRequest(pInteractionParameters, pLinkRecords, pRoom, pMessageDateTime) Export 
	vCommandArr = New Array();
	vRoomsArr = GetObjectExternalSystemCodeByRef(pInteractionParameters, "Rooms", pRoom);
	For Each vRowRoom In vRoomsArr Do 
		vCommandArr.Add(GetWakeupRequestByRoomCode(pLinkRecords, vRowRoom, pMessageDateTime));
	EndDo;
	Return vCommandArr;
EndFunction // GetWakeupRequest

// -----------------------------------------------------------------------------
Function GetWakeupRequestByRoomCode(pLinkRecords, pRoom, pMessageDateTime)
	vCommand = "WR" + Char(124);					 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "WR", "DA", Format(pMessageDateTime, "DF=yyMMdd")); 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "WR", "RN", Left(TrimAll(pRoom), 8));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "WR", "TI", Format(pMessageDateTime, "DF=HHmmss"));
	Return vCommand;
EndFunction // GetWakeupRequestByRoomCode

// -----------------------------------------------------------------------------
Function GetWakeupClear(pInteractionParameters, pLinkRecords, pRoom, pMessageDateTime) Export 
	vCommandArr = New Array();
	vRoomsArr = GetObjectExternalSystemCodeByRef(pInteractionParameters, "Rooms", pRoom);
	For Each vRowRoom In vRoomsArr Do
		vCommand = "WC" + Char(124);					 
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "WC", "DA", Format(pMessageDateTime, "DF=yyMMdd"));
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "WC", "RN", Left(TrimAll(vRowRoom), 8));
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "WC", "TI", Format(pMessageDateTime, "DF=HHmmss"));
		vCommandArr.Add(TrimAll(vCommand));
	EndDo;
	Return vCommandArr;
EndFunction // GetWakeupClear

// -----------------------------------------------------------------------------
Function GetKeyRequest(pInteractionParameters, pLinkRecords, pDoDataTransliteration, pDoorLockSystemConnectionParameters, pDoorLockSystemAuthorization, pExtraParms, pDocument, pGuestIndexInRoom, pRoom, pCheckInDate, pCheckOutDate, pDateTime, pWorkstations) Export 
	vCommand = "KR" + Char(124);
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "KT", Left(pExtraParms, 1));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "G#", Right(cmGetDocumentNumberPresentation(pDocument.Number), 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG=")); 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "GG", Right(Format(pDocument.GuestGroup.Code, "NFD=0; NZ=0; NG="), 10));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "KC", Left(pDoorLockSystemConnectionParameters.KeyCoder, 10)); 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "RN", Left(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pRoom, False), 8));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "WS", pWorkstations);
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "DA", Format(pDateTime, "DF=yyMMdd"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "DT", Format(pCheckOutDate, "DF=HH:mm")); 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "GA", Format(pCheckInDate, "DF=yyMMdd"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "GD", Format(pCheckOutDate, "DF=yyMMdd"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "K#", "1");
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "KO", Left(?(ValueIsFilled(pDoorLockSystemAuthorization), pDoorLockSystemAuthorization.AssignedAuthorizations, pDoorLockSystemConnectionParameters.AssignedAuthorizations), 20));
	
	vGuestFullName = "";
	vGuest = pDocument.Guest; 
	If ValueIsFilled(vGuest) Then
		vSalutation = vGuest.Salutation;
		If ValueIsFilled(vSalutation) Then
			vGuestFullName = vGuestFullName + TrimAll(vSalutation.Title) + " ";
		EndIf;
		If ValueIsFilled(vGuest.LastName) Then
			vGuestFullName = vGuestFullName + TrimAll(vGuest.LastName) + " "; 
		EndIf;
		If ValueIsFilled(vGuest.FirstName) Then
			vGuestFullName = vGuestFullName + TrimAll(vGuest.FirstName); 
		EndIf;
	EndIf;
	If ValueIsFilled(vGuestFullName) Then	
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "GN", Left(Transliterate(TrimAll(vGuestFullName), pDoDataTransliteration), 200));	
	Else 
		If ValueIsFilled(pDocument.GuestFullName) Then 
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "GN", Left(Transliterate(pDocument.GuestFullName, pDoDataTransliteration), 200));
		Else
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "GN", Right(cmGetDocumentNumberPresentation(pDocument.Number), 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="));	
		EndIf;
	EndIf; 
	vCurrentUser = SessionParameters.CurrentUser;
	If ValueIsFilled(vCurrentUser) Then 
		vEmployeePreferences = vCurrentUser.EmployeePreferences; 
		If ValueIsFilled(vEmployeePreferences) Then
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "ID", Left(vEmployeePreferences.DoorLockSystemLogin, 16));
		EndIf;
	Endif;
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "SI", Left(pDoorLockSystemConnectionParameters.ExtensionRooms, 30));	 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KR", "TI", Format(pDateTime, "DF=HHmmss"));
	Return vCommand;
EndFunction // GetKeyRequest

// -----------------------------------------------------------------------------
Function GetKeyDataRead(pLinkRecords, pDoorLockSystemConnectionParameters, pDateTime, pWorkstations) Export 
	vCommand = "KZ" + Char(124);  
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KZ", "KC", Left(pDoorLockSystemConnectionParameters.KeyCoder, 10));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KZ", "WS", pWorkstations);
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KZ", "DA", Format(pDateTime, "DF=yyMMdd"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KZ", "TI", Format(pDateTime, "DF=HHmmss"));
	Return vCommand;	
EndFunction // GetKeyDataRead

// -----------------------------------------------------------------------------
Function GetKeyDataChange(pInteractionParameters, pLinkRecords, pDoDataTransliteration, pDocument, pGuestIndexInRoom, pRoom, pDateTime, pOldRoom, pWorkstations) Export	
	vCommand = "KM" + Char(124); 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "G#", Right(cmGetDocumentNumberPresentation(pDocument.Number), 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "GG", Right(Format(pDocument.GuestGroup.Code, "NFD=0; NZ=0; NG="), 10));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "KC", pWorkstations); 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "RN", Left(TrimAll(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pRoom, False)), 8));
	If ValueIsFilled(pOldRoom) Then
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "RO", Left(TrimAll(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pOldRoom, False)), 8));	
	EndIf;
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "WS", pWorkstations);
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "DA", Format(pDateTime, "DF=yyMMdd"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "DT", Format(pDocument.CheckOutDate, "DF=HH:mm"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "GA", Format(pDocument.CheckInDate, "DF=yyMMdd"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "GD", Format(pDocument.CheckOutDate, "DF=yyMMdd"));		
	
	vGuestFullName = "";
	vGuest = pDocument.Guest; 
	If ValueIsFilled(vGuest) Then
		vSalutation = vGuest.Salutation;
		If ValueIsFilled(vSalutation) Then
			vGuestFullName = vGuestFullName + TrimAll(vSalutation.Title) + " ";
		EndIf;
		If ValueIsFilled(vGuest.LastName) Then
			vGuestFullName = vGuestFullName + TrimAll(vGuest.LastName) + " "; 
		EndIf;
		If ValueIsFilled(vGuest.FirstName) Then
			vGuestFullName = vGuestFullName + TrimAll(vGuest.FirstName); 
		EndIf;
	EndIf;
	
	If ValueIsFilled(vGuestFullName) Then	
		vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "GN", Left(Transliterate(TrimAll(vGuestFullName), pDoDataTransliteration), 200));	
	Else 
		If ValueIsFilled(pDocument.GuestFullName) Then 
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "GN", Left(Transliterate(pDocument.GuestFullName, pDoDataTransliteration), 200));
		Else
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "GN", Right(cmGetDocumentNumberPresentation(pDocument.Number), 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="));	
		EndIf;
	EndIf;
	vCurrentUser = SessionParameters.CurrentUser;
	If ValueIsFilled(vCurrentUser) Then 
		vEmployeePreferences = vCurrentUser.EmployeePreferences; 
		If ValueIsFilled(vEmployeePreferences) Then
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "ID", Left(vEmployeePreferences.DoorLockSystemLogin, 16));
		EndIf;
	Endif;
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KM", "TI", Format(pDateTime, "DF=HHmmss"));
	Return vCommand;
EndFunction // GetKeyDataChange

// -----------------------------------------------------------------------------
Function GetKeyDelete(pInteractionParameters, pLinkRecords, pDocument, pGuestIndexInRoom, pRoom, pDateTime, pWorkstations) Export
	vCommand = "KD" + Char(124);
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KD", "KC", pWorkstations); 
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KD", "RN", Left(TrimAll(cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pRoom, False)), 8));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KD", "WS", pWorkstations);
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KD", "DA", Format(pDateTime, "DF=yyMMdd"));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KD", "G#", Right(cmGetDocumentNumberPresentation(pDocument.Number), 8) + Format(pGuestIndexInRoom, "ND=2; NFD=0; NZ=0; NLZ=; NG="));
	vCurrentUser = SessionParameters.CurrentUser;
	If ValueIsFilled(vCurrentUser) Then 
		vEmployeePreferences = vCurrentUser.EmployeePreferences; 
		If ValueIsFilled(vEmployeePreferences) Then
			vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KD", "ID", Left(vEmployeePreferences.DoorLockSystemLogin, 16));
		EndIf;
	Endif;
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "KD", "TI", Format(pDateTime, "DF=HHmmss"));
	Return vCommand;	
EndFunction // GetKeyDelete

// -----------------------------------------------------------------------------
Function GetPostingAnswer(pInteractionParameters, pLinkRecords, pRoom, pDate, pTime, pAnswerStatus, pPostingSequenceNumber, pWorkstationID, pClearText, pCheckNumber, pReservationNumber, pGuestName, pUserID, pSalesOutlet) Export
	vRoom = pRoom;
	If TypeOf(pRoom) = Type("CatalogRef.Rooms") Then
		vRoom = cmGetObjectExternalSystemCodeByRef(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Rooms", pRoom, False);	
	EndIf;	
	vCommand = "PA" + Char(124);
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "AS", Left(pAnswerStatus, 2));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "CT", Left(pClearText, 50));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "DA", pDate);
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "P#", Left(pPostingSequenceNumber, 8));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "RN", Left(vRoom, 8));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "TI", pTime);
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "WS", Left(pWorkstationID, 16));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "C#", Left(pCheckNumber, 8));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "G#", Left(pReservationNumber, 10));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "GN", Left(pGuestName, 40));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "ID", Left(pUserID, 16));
	vCommand = vCommand + CheckAndFillParameters(pLinkRecords, "PA", "SO", Left(pSalesOutlet, 5));
	Return TrimAll(vCommand);	
EndFunction // GetPostingAnswer

// -----------------------------------------------------------------------------
Function GetPriorityRequest(pLinkRecords, pCommand, pParameters) Export
	vCommand = "";
	If ValueIsFilled(TrimAll(pCommand)) And TypeOf(pParameters) = Type("Map") Then
		vCommand = TrimAll(pCommand) + Char(124);
		For Each vRow In pParameters Do
			If vRow.Key <> "Command" Then
				vCommand = vCommand + CheckAndFillParameters(pLinkRecords, TrimAll(pCommand), vRow.Key, vRow.Value);
			EndIf;
		EndDo;
	EndIf;
	Return TrimAll(vCommand);
EndFunction // GetKeyRequest

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetObjectExternalSystemCodeByRef(pInteractionParameters, pObjectTypeName, pObjectRef)
	vObjectExternalCodeArr = New Array();
	// Try to find reference to the object in the program by external code
	If ValueIsFilled(pObjectRef) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	(ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|			OR ExternalSystemsObjectCodesMappings.Hotel = VALUE(Catalog.Hotels.EmptyRef))
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
		|	AND ExternalSystemsObjectCodesMappings.ObjectRef = &qObject
		|
		|ORDER BY
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode";
		vQry.SetParameter("qHotel", pInteractionParameters.Hotel);
		vQry.SetParameter("qExternalSystemCode", TrimAll(pInteractionParameters.InteractionID));
		vQry.SetParameter("qObjectTypeName", TrimAll(pObjectTypeName));
		vQry.SetParameter("qObject", pObjectRef);
		vObjects = vQry.Execute().Unload();
		For Each vRow In vObjects Do 
			vObjectExternalCodeArr.Add(vRow.ObjectExternalCode);
		EndDo;
		If vObjectExternalCodeArr.Count() = 0 Then
			// Try to return object description instead
			Try
				vObjectExternalCodeArr.Add(TrimAll(pObjectRef.Description));
			Except
				vObjectExternalCodeArr = New Array();
			EndTry;
		EndIf;
	EndIf;
	Return vObjectExternalCodeArr;
EndFunction // GetObjectRefByExternalSystemCode

// -----------------------------------------------------------------------------
Function GetLanguageCode(Val pLanguage)
	If pLanguage = Catalogs.Languages.RU Then
		Return "RU";	
	ElsIf pLanguage = Catalogs.Languages.EN Then
		Return "EA";	
	ElsIf pLanguage = Catalogs.Languages.DE Then 
		Return "GE";
	Else
		Return "EA";	
	EndIf;
EndFunction // GetLanguageCode

// -----------------------------------------------------------------------------
Function CheckAndFillParameters(Val pLinkRecords, Val pFunctionName, Val pParameterName, Val pValue)
	vParameter = "";
	If ValueIsFilled(TrimAll(pValue)) Then
		If pLinkRecords.Count() > 0 Then
			vLinkRecordsArr = pLinkRecords.FindRows(New Structure("LinkRecordCommand, LinkRecordParameter", pFunctionName, pParameterName));
			If vLinkRecordsArr.Count() > 0 Then
				vParameter = TrimAll(pParameterName) + TrimAll(pValue) + Char(124);	
			EndIf; 		
		Else
			vParameter = TrimAll(pParameterName) + TrimAll(pValue) + Char(124);   	
		EndIf;
	EndIf;
	Return vParameter;
EndFunction // CheckAndFillParameters

// -----------------------------------------------------------------------------
Function Transliterate(pStr, pDoDataTransliteration)
	vStr = pStr;
	If pDoDataTransliteration Then
		vStr = StrReplace(vStr, "А", "A");
		vStr = StrReplace(vStr, "Б", "B");
		vStr = StrReplace(vStr, "В", "V");
		vStr = StrReplace(vStr, "Г", "G");
		vStr = StrReplace(vStr, "Д", "D");
		vStr = StrReplace(vStr, "Е", "E");
		vStr = StrReplace(vStr, "Ё", "E");
		vStr = StrReplace(vStr, "Ж", "Zh");
		vStr = StrReplace(vStr, "З", "Z");
		vStr = StrReplace(vStr, "И", "I");
		vStr = StrReplace(vStr, "Й", "Y");
		vStr = StrReplace(vStr, "К", "K");
		vStr = StrReplace(vStr, "Л", "L");
		vStr = StrReplace(vStr, "М", "M");
		vStr = StrReplace(vStr, "Н", "N");
		vStr = StrReplace(vStr, "О", "O");
		vStr = StrReplace(vStr, "П", "P");
		vStr = StrReplace(vStr, "Р", "R");
		vStr = StrReplace(vStr, "С", "S");
		vStr = StrReplace(vStr, "Т", "T");
		vStr = StrReplace(vStr, "У", "U");
		vStr = StrReplace(vStr, "Ф", "F");
		vStr = StrReplace(vStr, "Х", "H");
		vStr = StrReplace(vStr, "Ц", "C");
		vStr = StrReplace(vStr, "Ч", "Ch");
		vStr = StrReplace(vStr, "Ш", "Sh");
		vStr = StrReplace(vStr, "Щ", "Sch");
		vStr = StrReplace(vStr, "Ь", "'");
		vStr = StrReplace(vStr, "Ы", "Yi");
		vStr = StrReplace(vStr, "Ъ", "");
		vStr = StrReplace(vStr, "Э", "E");
		vStr = StrReplace(vStr, "Ю", "Yu");
		vStr = StrReplace(vStr, "Я", "Ya");
		vStr = StrReplace(vStr, "а", "a");
		vStr = StrReplace(vStr, "б", "b");
		vStr = StrReplace(vStr, "в", "v");
		vStr = StrReplace(vStr, "г", "g");
		vStr = StrReplace(vStr, "д", "d");
		vStr = StrReplace(vStr, "е", "e");
		vStr = StrReplace(vStr, "ё", "e");
		vStr = StrReplace(vStr, "ж", "zh");
		vStr = StrReplace(vStr, "з", "z");
		vStr = StrReplace(vStr, "и", "i");
		vStr = StrReplace(vStr, "й", "y");
		vStr = StrReplace(vStr, "к", "k");
		vStr = StrReplace(vStr, "л", "l");
		vStr = StrReplace(vStr, "м", "m");
		vStr = StrReplace(vStr, "н", "n");
		vStr = StrReplace(vStr, "о", "o");
		vStr = StrReplace(vStr, "п", "p");
		vStr = StrReplace(vStr, "р", "r");
		vStr = StrReplace(vStr, "с", "s");
		vStr = StrReplace(vStr, "т", "t");
		vStr = StrReplace(vStr, "у", "u");
		vStr = StrReplace(vStr, "ф", "f");
		vStr = StrReplace(vStr, "х", "h");
		vStr = StrReplace(vStr, "ц", "c");
		vStr = StrReplace(vStr, "ч", "ch");
		vStr = StrReplace(vStr, "ш", "sh");
		vStr = StrReplace(vStr, "щ", "sch");
		vStr = StrReplace(vStr, "ь", "'");
		vStr = StrReplace(vStr, "ы", "yi");
		vStr = StrReplace(vStr, "ъ", "");
		vStr = StrReplace(vStr, "э", "e");
		vStr = StrReplace(vStr, "ю", "yu");
		vStr = StrReplace(vStr, "я", "ya");
	EndIf;
	Return vStr;
EndFunction // Transliterate

#EndRegion