// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ServerPort = 0 Then
		ServerPort = 80;
	EndIf;
	If IsBlankString(ServerAddress) Then
		ServerAddress = "127.0.0.1";
	EndIf;
	If IsBlankString(ServerResource) Then
		ServerResource = "/xml/command.php";
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	If IsBlankString(ServerAddress) Then
		Raise NStr("en='Interface server address should be filled!';ru='Не указан сетевой адрес, на котором должен работать интерфейсный сервер!';de='Server address sollten ausgefüllt werden!'");
	EndIf;	
	If ServerPort = 0 Then
		Raise NStr("en='Interface server port should be filled!';ru='Не указан сетевой порт, на котором должен работать интерфейсный сервер!';de='Port sollten ausgefüllt werden!'");
	EndIf;
	// Get all active room interface events that need to be processed
	vActiveEvents = GetActiveRoomInterfaceEvents();
	// Process events
	If vActiveEvents.Count() > 0 Then
		ProcessEvents(vActiveEvents, pIsInteractive);
	EndIf;
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
 
// -----------------------------------------------------------------------------
Function GetAddUserMessage(pEventRow)
	vCommand = "";
	
	vAccDoc = pEventRow.ParentDoc;
	vGuest = vAccDoc.Guest;
	
	If Not ValueIsFilled(vGuest) Then
		Return vCommand;
	EndIf;
	
	vCommand = 
	"<hsmx>
	|	<command>add_user</command>
	|	<username>&USER_NAME</username>
	|	<password>&PASSWORD</password>
	|	<plan>&RATEPLAN</plan>
	|	<fields>
	|		<expiration>&EXPIRED</expiration>
	|		<firstname>&FIRST_NAME</firstname>
	|		<lastname>&LAST_NAME</lastname>
	|		<company>&ROOM</company>
	|		<room>&ROOM</room>
	|		<phone>&PHONE</phone>
	|	</fields>
	|</hsmx>";
	
	If WhatIsGuestLogin = 0 Then
		vUserName = cmGetDocumentNumberPresentation(vAccDoc.Number);
		vPassword = TrimAll(vAccDoc.Room);
	Else
		vPassword = cmGetDocumentNumberPresentation(vAccDoc.Number);
		vUserName = TrimAll(vAccDoc.Room);
	EndIf;
	vRoom = TrimAll(vAccDoc.Room);
	vExpired = Format(vAccDoc.CheckOutDate + 3600, "DF='yyyy-MM-dd HH:mm:ss'");
	vFirstName = TrimAll(vGuest.FirstName);
	vLastName = TrimAll(vGuest.LastName);
	vPhone = TrimAll(vAccDoc.Phone);
	
	vCommand = StrReplace(vCommand, "&USER_NAME", vUserName);
	vCommand = StrReplace(vCommand, "&PASSWORD", vPassword);
	vCommand = StrReplace(vCommand, "&EXPIRED", vExpired);
	vCommand = StrReplace(vCommand, "&FIRST_NAME", vFirstName);
	vCommand = StrReplace(vCommand, "&LAST_NAME", vLastName);
	vCommand = StrReplace(vCommand, "&ROOM", vRoom);
	vCommand = StrReplace(vCommand, "&PHONE", vPhone);
	vCommand = StrReplace(vCommand, "&RATEPLAN", ?(IsBlankString(RateCode), "7", TrimAll(RateCode)));
	
	Return vCommand;
EndFunction // GetAddUserMessage
 
// -----------------------------------------------------------------------------
Function GetUpdateUsersMessage(pEventRow)
	vCommand = "";
	
	vAccDoc = pEventRow.ParentDoc;
	vGuest = vAccDoc.Guest;
	
	If Not ValueIsFilled(vGuest) Then
		Return vCommand;
	EndIf;
	
	vCommand = 
	"<hsmx>
	|	<command>update_users</command>
	|	<fields>
	|		<expiration>&EXPIRED</expiration>
	|		<firstname>&FIRST_NAME</firstname>
	|		<lastname>&LAST_NAME</lastname>
	|	</fields>
	|	<where>
	|		<field>user</field>
	|		<operator>=</operator>
	|		<value>&USER_NAME</value>
	|	</where>
	|</hsmx>";
	
	If WhatIsGuestLogin = 0 Then
		vUserName = cmGetDocumentNumberPresentation(vAccDoc.Number);
	Else
		vUserName = TrimAll(vAccDoc.Room);
	EndIf;
	vExpired = Format(vAccDoc.CheckOutDate + 3600, "DF='yyyy-MM-dd HH:mm:ss'");
	vFirstName = TrimAll(vGuest.FirstName);
	vLastName = TrimAll(vGuest.LastName);
	
	vCommand = StrReplace(vCommand, "&USER_NAME", vUserName);
	vCommand = StrReplace(vCommand, "&EXPIRED", vExpired);
	vCommand = StrReplace(vCommand, "&FIRST_NAME", vFirstName);
	vCommand = StrReplace(vCommand, "&LAST_NAME", vLastName);
	
	Return vCommand;
EndFunction // GetUpdateUsersMessage

// -----------------------------------------------------------------------------
Function GetActiveRoomInterfaceEvents() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInterfaceStatus.Ref AS Ref,
	|	RoomInterfaceStatus.Hotel AS Hotel,
	|	RoomInterfaceStatus.Room AS Room,
	|	RoomInterfaceStatus.RoomInterfaceType AS RoomInterfaceType,
	|	RoomInterfaceStatus.Remarks AS Remarks,
	|	RoomInterfaceStatus.IsProcessed AS IsProcessed,
	|	RoomInterfaceStatus.IsCanceled AS IsCanceled,
	|	RoomInterfaceStatus.MessageDateTime AS MessageDateTime,
	|	RoomInterfaceStatus.MessageIsDelivered AS MessageIsDelivered,
	|	RoomInterfaceStatus.MessageDeliveryDateTime AS MessageDeliveryDateTime,
	|	RoomInterfaceStatus.Number AS Number,
	|	RoomInterfaceStatus.Date AS Date,
	|	RoomInterfaceStatus.ParentDoc AS ParentDoc,
	|	RoomInterfaceStatus.Author AS Author,
	|	RoomInterfaceStatus.CancellationAuthor AS CancellationAuthor,
	|	RoomInterfaceStatus.CancellationDate AS CancellationDate,
	|	RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters AS TurnOnParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters AS TurnOffParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.InterfaceType AS InterfaceType,
	|	RoomInterfaceStatus.PeriodOfStayExtensionIsRequested AS PeriodOfStayExtensionIsRequested,
	|	RoomInterfaceStatus.RoomInterfaceType.PeriodOfStayExtentionParameters AS PeriodOfStayExtentionParameters
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND NOT RoomInterfaceStatus.IsProcessed
	|	AND RoomInterfaceStatus.RoomInterfaceType.InterfaceType = &qInternet
	|	AND NOT RoomInterfaceStatus.ParentDoc.CheckInDate IS NULL
	|	AND RoomInterfaceStatus.ParentDoc.CheckOutDate >= &qBegOfCurrentDate
	|
	|ORDER BY
	|	RoomInterfaceStatus.PointInTime";
	vQry.SetParameter("qInternet", Enums.InterfaceTypes.Internet);
	vQry.SetParameter("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	Return vQry.Execute().Unload();
EndFunction // GetActiveRoomInterfaceEvents

// -----------------------------------------------------------------------------
Function SendCommand(pData, pHTTPConnection, pHTTPHeader, pIsInteractive)
	vSuccess = False;
	// Send command
	vHTTPRequest = New HTTPRequest(TrimAll(ServerResource), pHTTPHeader);
	vHTTPRequest.SetBodyFromString(pData);
	vResponse = pHTTPConnection.Post(vHTTPRequest);
	If vResponse.StatusCode = 200 Then
		vResponseXML = vResponse.GetBodyAsString();
		vResult = "";
		vResultPos = StrFind(vResponseXML, "<result>");
		If vResultPos > 0 Then
			vResult = Mid(vResponseXML, vResultPos + 8, 1);
		EndIf;
		If vResult = "1" Then
			vSuccess = True;
		Else
			vErrorDescription = vResponseXML;
			vDescrPos = StrFind(vResponseXML, "<description>");
			vDescrEndPos = StrFind(vResponseXML, "</description>");
			If vDescrPos > 0 And vDescrEndPos > vDescrPos Then
				vErrorDescription = Mid(vResponseXML, vResultPos + 13, vDescrEndPos - vResultPos - 13);
			EndIf;
			DoMessage("Connectum -> PMS. Error sending add_user: " + vErrorDescription, MessageStatus.Attention, pIsInteractive);
		EndIf;
	Else
		DoMessage("Connectum -> PMS. Error sending add_user. HTTP response code: " + vResponse.StatusCode, MessageStatus.Attention, pIsInteractive);
	EndIf;
	Return vSuccess;
EndFunction // SendCommand

// -----------------------------------------------------------------------------
Procedure ProcessEvents(pActiveEvents, pIsInteractive)
	// HTTP header
	vHTTPHeader = New Map;
	vHTTPHeader.Insert("Content-Type", "text/xml;charset=utf-8");

	// HTTP connection
	vHTTPConnection = New HTTPConnection(StrReplace(TrimAll(ServerAddress), " ", ""), ServerPort, TrimAll(Login), TrimAll(Password));
	
	For Each vEventRow In pActiveEvents Do
		vSuccess = False;
		vResetPeriodOfStayExtention = False;
		
		If TrimAll(vEventRow.TurnOnParameters) = "add_user" And Not vEventRow.PeriodOfStayExtensionIsRequested And Not vEventRow.IsCanceled Then
			// Build message for Connectum
			vData = GetAddUserMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> Connectum. add_user message. Data going to be written: " + vData, pIsInteractive);
			EndIf;
			
			// Send command
			vSuccess = SendCommand(vData, vHTTPConnection, vHTTPHeader, pIsInteractive);
		EndIf;
		If TrimAll(vEventRow.PeriodOfStayExtentionParameters) = "update_users" And vEventRow.PeriodOfStayExtensionIsRequested And Not vEventRow.IsCanceled Then
			vResetPeriodOfStayExtention = True;
			
			// Build message for Connectum
			vData = GetUpdateUsersMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> Connectum. update_users message. Data going to be written: " + vData, pIsInteractive);
			EndIf;
			
			// Send command
			vSuccess = SendCommand(vData, vHTTPConnection, vHTTPHeader, pIsInteractive);
		EndIf;
		If TrimAll(vEventRow.TurnOffParameters) = "update_users" And vEventRow.IsCanceled Then
			// Build message for Connectum
			vData = GetUpdateUsersMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> Connectum. update_users message after check-out. Data going to be written: " + vData, pIsInteractive);
			EndIf;
			
			// Send command
			vSuccess = SendCommand(vData, vHTTPConnection, vHTTPHeader, pIsInteractive);
		EndIf;
		// Set processed status to the interface record
		If vSuccess Then
			vStsObj = vEventRow.Ref.GetObject();
			vStsObj.IsProcessed = True;
			If vResetPeriodOfStayExtention Then
				vStsObj.PeriodOfStayExtensionIsRequested = False;
			EndIf;
			vStsObj.Write(DocumentWriteMode.Write);
		EndIf;
	EndDo;
EndProcedure // ProcessEvents

// -----------------------------------------------------------------------------
Procedure DoMessage(pMsg, pMsgStatus = Undefined, pIsInteractive = False)
	vMsgStatus = MessageStatus.Information;
	If pMsgStatus <> Undefined Then
		vMsgStatus = pMsgStatus;
	EndIf;
	If pIsInteractive Then
		tcCommonFunctionOnClientServer.TextMessage(TrimAll(CurrentSessionDate()) + " " + pMsg, vMsgStatus);
	EndIf;
	WriteLogEvent("Connectum.WiFi", ?(vMsgStatus = MessageStatus.Attention, EventLogLevel.Error, EventLogLevel.Information), , , pMsg);
EndProcedure // DoMessage
