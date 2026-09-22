#Region Public

// -----------------------------------------------------------------------------
//
Procedure pmInstall() Export
	BeginInstallAddIn(,"CommonTemplate.AddInLocksNORWEQMF");
	BeginInstallAddIn(,"CommonTemplate.AddInLocksFHBS");
EndProcedure // EndProcedure

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDevice			 - Structure - Device
//  pParameters		 - Structure - Parameters
//  rErrorMessage	 - String	 - Error message
//  pGuestCardOption - Number	 - Guest card option
// 
// Returns:
//  Number - Result
//
Function pmNewKey(pDevice, pParameters, rErrorMessage, pGuestCardOption = 0) Export
	RC_OK = 0;
	RC_NO_CONNECTION = -199;
	RC_ROOM_WITHOUT_DOOR_LOCK = -9999;
	
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Call API
	vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	
	// Connect
	vLock = pmConnect(pDevice, vParams.LockType);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
		
	// Check in dates
	vCheckInDate = pParameters.CheckInDate;
	If vParams.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - vParams.SubtractMinutes*60;
	EndIf;        
	vLock.CheckInTime = Format(vCheckInDate, "DF='yyyy-MM-dd HH:mm:ss'");

	// Check out dates
	vCheckOutDate = pParameters.CheckOutDate;
	If vParams.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vParams.AddMinutes*60;
	EndIf;
	vLock.CheckOutTime = Format(vCheckOutDate, "DF='yyyy-MM-dd HH:mm:ss'");
	
	vLock.GuestCardOption = pGuestCardOption;
	
	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vParams.UseRoomLockCodes Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;   
	
	If IsBlankString(vRoomCode) And ValueIsFilled(vParams.DefaultRoom) Then
		pParameters.Room = vParams.DefaultRoom;
		vRoomCode = TrimR(pParameters.Room);
		If vParams.UseRoomLockCodes Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	
	If IsBlankString(vRoomCode) Then
		pmDisconnect(vLock);
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf; 	
	vLock.RoomNo = vRoomCode;	
		
	vErrorCode = vLock.MakeGuestCard(); 		
	If vErrorCode = RC_OK Then
		vIdentificationCard = Undefined;
		vCardIDHex = vLock.CardID;
		If vParams.ReturnCardUID And ValueIsFilled(vCardIDHex) Then
			If vParams.ConvertCardIDToDec Then
				vCardID = HexToDec(vCardIDHex, 16);
			Else
				vCardID = vCardIDHex;
			EndIf;
			If pParameters.Property("IdentificationCard") Then
				vIdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardID);
				pParameters.IdentificationCard = vIdentificationCard;
			EndIf;
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"),"Information",,,NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		If pGuestCardOption <> 0 Then
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", TrimAll(vCardID), pParameters.Room, "", pParameters.CheckInDate, pParameters.CheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);	
		Else
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", TrimAll(vCardID), pParameters.Room, "", pParameters.CheckInDate, pParameters.CheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);
		EndIf;
	Else
		rErrorMessage = vLock.LastErrorDescription;                            
		AddError(StrTemplate(NStr("en='Error issuing key card: %1 - %2';ru='Ошибка выдачи карты: %1 - %2';de='Fehler bei der Kartenausstellung: %1 - %2'"), vErrorCode, rErrorMessage));	
	EndIf;
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDeviceArr		 - 		 - 
//  pParameters		 - Structure - Parameters
//  rErrorMessage	 - String	 - Error message
// 
// Returns:
//  Number - Result
//
Function pmAddKey(pDeviceArr, pParameters, rErrorMessage) Export
	Return pmNewKey(pDeviceArr, pParameters, rErrorMessage, 8);	
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - Structure - Card data
//  pDevice		 - Structure - Device
//  pParameters	 - Structure - Parameters
// 
// Returns:
//  Number - Result
//
Function pmVerify(pCardData, pDevice, pParameters) Export
	RC_NO_CONNECTION = -199;
	
	vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	
	// Connect
	vLock = pmConnect(pDevice, vParams.LockType);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;    
			
	vErrorCode = vLock.ReadGuestCard();
	If vErrorCode <> 0 Then
		AddError(StrTemplate(NStr("en='Error reading key card: %1 - %2';ru='Ошибка чтения карты: %1 - %2';de='Fehler beim Lesen der Karte: %1 - %2'"), vErrorCode, vLock.LastErrorDescription));
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vLock);
	EndIf;
	
	// Disconnect
	pmDisconnect(vLock);
	
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDevice	 - Structure - Device
// 
// Returns:
//  Number - Result
//
Function pmDelete(pDevice) Export 
	RC_OK = 0;
	RC_NO_CONNECTION = -199;
	
	// Call API
	vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	
	// Connect
	vLock = pmConnect(pDevice, vParams.LockType);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf; 
	
	// Call API
	vErrorCode = vLock.CardErase();
	If vErrorCode <> RC_OK Then
		AddError(StrTemplate(NStr("en = 'Erase card error: %1 - %2'; de = 'Fehler beim Löschen der Karte: %1 - %2'; ru = 'Ошибка стирания карты: %1 - %2'"), vErrorCode, vLock.LastErrorDescription));
	EndIf;
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction //  pmDelete

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCode		 - Number	 - Code
//  pSystemName	 - String	 - System name
// 
// Returns:
//  String - Error message
//
Function pmGetErrorDescription(pCode, pSystemName) Export
	If pCode = -199 Then
		Return StrTemplate(NStr("en = 'Failed to connect to the door locks system %1!'; de = 'Failed to connect to the door locks system %1!'; ru = 'Не удалось установить соединение с системой %1!'"), pSystemName);
	ElsIf pCode = -99 Then
		Return StrTemplate(NStr("en = 'Failed to load proRFL.DLL %1!'; de = 'Fehler beim laden %1!'; ru = 'Не удалось загрузить proRFL.DLL %1!'"), pSystemName);
	ElsIf pCode = -999 Then
		Return(NStr("en = 'Room has no key card door lock!'; de = 'Im Zimmer ist kein elektronisches Schloss vorhanden!'; ru = 'В номере нет электронного замка!'"));
	Else
		Return StrTemplate(NStr("en = 'Unknown error %1!'; de = 'Unbekannter Fehler %1!'; ru = 'Неизвестная ошибка %1!'"), pSystemName);			
	EndIf;
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"),"Warning",,,pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function HexToDec(Val pValue, pBasis)
	vResult = 0;
	vLength = StrLen(pValue);
	For vChar = 1 To StrLen(pValue) Do
		vMultiplier = 1;
		For vCount = 1 To vLength - vChar Do 
			vMultiplier = vMultiplier * pBasis;
		EndDo;
		vResult = vResult + (Find("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", Mid(pValue, vChar, 1))-1) * vMultiplier;
	EndDo;
	Return Round(vResult);
EndFunction //  HexToDec

// -----------------------------------------------------------------------------
Function pmConnect(pDevice, pLockType = 5)
	If Not ValueIsFilled(pDevice.Ref) Then
		Return Undefined;
	EndIf;
	
	vLock = Undefined;         

	// Fill system name
	vSystemName = String(pDevice.SystemName);
	
	If pDevice.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.FHBS") Then
		Try
			// Build ActiveX object to work with
			IsConnected = AttachAddIn("CommonTemplate.AddInLocksFHBS", "Native", AddInType.Native); // ACC:561
			If Not IsConnected Then
				AddError(StrTemplate(NStr("ru = 'Ошибка подключения системы электронных замков %1: %2'; en = '%1 door lock system connection error: %2'; de = '%1 door lock system connection error: %2'"), vSystemName, ErrorDescription()));
				Return Undefined;
			Endif;
			vLock = New("AddIn.Native.FHBSLock");
		Except
			AddError(StrTemplate(NStr("ru = 'Ошибка подключения системы электронных замков %1: %2'; en = '%1 door lock system connection error: %2'; de = '%1 door lock system connection error: %2'"), vSystemName, ErrorDescription()));
			Return Undefined;
		EndTry;	
	Else
		Try
			// Build ActiveX object to work with
			IsConnected = AttachAddIn("CommonTemplate.AddInLocksNORWEQMF", "Native", AddInType.Native); // ACC:561
			If Not IsConnected Then
				AddError(StrTemplate(NStr("ru = 'Ошибка подключения системы электронных замков %1: %2'; en = '%1 door lock system connection error: %2'; de = '%1 door lock system connection error: %2'"), vSystemName, ErrorDescription()));
				Return Undefined;
			Endif;
			vLock = New("AddIn.Native.eLock");
		Except
			AddError(StrTemplate(NStr("ru = 'Ошибка подключения системы электронных замков %1: %2'; en = '%1 door lock system connection error: %2'; de = '%1 door lock system connection error: %2'"), vSystemName, ErrorDescription()));
			Return Undefined;
		EndTry;
	EndIf;
	
	vLock.LockType = pLockType; 
	
	If vLock.Connect() <> 0 Then 
		vLock = Undefined;	
	EndIf;
	
	Return vLock;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pLock)
	pLock = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function pmParseCardDescription(pLock)
	vRoomCode = TrimAll(pLock.RoomNo);
	vCardCheckInDate = pLock.CheckInTime;
	vCardCheckOutDate = pLock.CheckOutTime;
	
	If ValueIsFilled(vRoomCode) Then 
		vRoomRef = tcDoorLocksAtServer.GetRoomRefByCode(TrimAll(vRoomCode));
	EndIf;
	
	vRoom = vRoomCode;
	vCardFullName = "";
	If ValueIsFilled(vRoomRef) Then
		vRoom = vRoomRef;
		#IF NOT WebClient THEN 
			vCardCheckInDate = ?(ValueIsFilled(vCardCheckInDate), XMLValue(Type("Date"), pLock.CheckInTime), "");
			vCardCheckOutDate = ?(ValueIsFilled(vCardCheckOutDate), XMLValue(Type("Date"), pLock.CheckOutTime), "");
			
			vClientRef = tcDoorLocksAtServer.GetClientRefByCardUID(TrimAll(pLock.CardID), , ?(ValueIsFilled(vCardCheckOutDate), vCardCheckOutDate, Date(1,1,1)), vRoomRef);
			If ValueIsFilled(vClientRef) Then
				vCardFullName = tcOnServer.cmGetAttributeByRef(vClientRef, "FullName");
			EndIf;
		#ENDIF

	EndIf;

	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", vRoom);
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("IsCardValidCode", "");
	vCardData.Insert("IsCardValidDescription", "");
	vCardData.Insert("CardCopyNumber", "");
	vCardData.Insert("AssignedAuthorizations", "");             
	vCardData.Insert("CardCheckInDate", vCardCheckInDate);
	vCardData.Insert("CardCheckOutDate", vCardCheckOutDate);
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", TrimAll(pLock.CardID));
	vCardData.Insert("CardFullName", vCardFullName);
	
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

#EndRegion
