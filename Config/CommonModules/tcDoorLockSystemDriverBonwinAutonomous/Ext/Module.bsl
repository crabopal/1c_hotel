
#Region Public

// -----------------------------------------------------------------------------
Procedure pmInstall() Export
	BeginInstallAddIn(,"CommonTemplate.AddInLocksBonwinAutonomous");
EndProcedure

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, rErrorMessage = "", pTypeKey = "A") Export
	RC_OK = 0;
	RC_NO_CONNECTION = -1;
	RC_ROOM_WITHOUT_DOOR_LOCK = 114;
	
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vLock = pmConnect(pDevice);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Call API
	vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	
	If vParams.Property("ConnectionType") Then
		If vParams.ConnectionType Then 
			vErrorCode = pmNewKeyHotelLock(pTypeKey, vLock, vParams, pParameters, rErrorMessage);
		Else
			vErrorCode = pmNewKeyHotelNetLock(pTypeKey, vLock, vParams, pParameters, rErrorMessage); 
		EndIf;
	Else
		Return RC_NO_CONNECTION;
	EndIf;
	
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage = "", pTypeKey = "B") Export
	vErrorCode = pmNewKey(pDevice, pParameters, rErrorMessage, pTypeKey);
	Return vErrorCode; 
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	RC_NO_CONNECTION = -1;
	
	// Connect
	vLock = pmConnect(pDevice);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	// Call API
	vCardDesc = "";
	vParamsText = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
	vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vLock.LockType = Number(vParams.LockType);
	vLock.Location = vParams.NameOfTheFolder;
	vLock.FileName = vParams.FileName;
	vLock.CardType = GetCartType(vParams.LockType);
	If vParams.LockType = "8032" Or vParams.LockType = "8038" Then
		vParamsText = vParams.HotelPassword + vParamsText;
		vErrorCode = vLock.ReadGuestCard803(vParams.SectorNumber, vParamsText);
	ElsIf vParams.LockType = "823" Then
		vParamsText = vParams.HotelPassword + vParamsText;
		vErrorCode = vLock.ReadGuestCard823(vParamsText);
	ElsIf vParams.LockType = "893" Or vParams.LockType = "8938" Then
		vErrorCode = vLock.ReadGuestCard893(vParams.SectorNumber, vParamsText + "000000");
	Else
		vParamsText = vParams.HotelPassword + vParamsText;
		vErrorCode = vLock.ReadGuestCard(vParamsText);
	EndIf;
	
	If vErrorCode <> 0 Then
		vErrorMessage = vLock.ErrorDescription;
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode + " - " + vErrorMessage);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vLock,vParams, pParameters);
	EndIf;
	
	// Disconnect
	pmDisconnect(vLock);
	
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_UNKNOWN = 100;
	RC_NO_FOLIO = 101;
	RC_NO_ID_CARD = 102;
	RC_NO_REPLY = 103;
	RC_WRONG_REPLY = 104;
	RC_SYNTAX_ERROR = 105;
	RC_NO_COMMUNICATION = 106;
	RC_OVERFLOW = 107;
	RC_MAGNETIC_TRACK_ERROR = 108;
	RC_MAGNETIC_FORMAT_ERROR = 109;
	RC_MAGNETIC_LEVEL_ERROR = 110;
	RC_DEVICE_TIME_OUT = 111;
	RC_NO_GUEST_PREVIOUSLY_CHECKED_IN = 112;
	RC_WRONG_ROOM = 113;
	RC_ROOM_WITHOUT_DOOR_LOCK = 114;
	RC_CARD_MEMORY_OVERFLOW = 115;
	RC_CARD_NOTADD_TYPE = 999;
	
	vSystemName = pSystemName;

	If pRC = RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + vSystemName + "!'; 
		            |de = 'Failed to connect to the door locks system " + vSystemName + "!'; 
		            |en = 'Failed to connect to the door locks system " + vSystemName + "!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en = 'Unknown error! See error log for details.'; ru = 'Неизвестная ошибка! Дополнительная информация сохранена в системном логе.'; de = 'Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en = 'The reader/writer has been waiting too long for a card!'; ru = 'Закончилось время ожидания карты энкодером!'; de = 'Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Then
		Return(NStr("en = 'No checked in guests in the room! Make new key card instead.'; ru = 'В номере нет размещенных гостей! Выдайте гостю новую карту.'; de = 'In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en = 'Room is wrong!'; ru = 'Номер комнаты указан неверно!'; de = 'Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + vSystemName + " не отвечает!'; 
		            |de = 'System " + vSystemName + "  antwortet nicht!'; 
		            |en = '" + vSystemName + " system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + vSystemName + " получен ответ в неизвестном формате!'; 
		            |de = '" + vSystemName + " system replied with unknown format!'; 
		            |en = '" + vSystemName + " system replied with unknown format!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_SYNTAX_ERROR Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = RC_NO_COMMUNICATION Then
		Return(NStr("ru = 'Энкодер не отвечает (возможно выключен или не подключен)!'; 
		            |de = 'The encoder does not answer (failure in the communications or switched off)!'; 
		            |en = 'The encoder does not answer (failure in the communications or switched off)!'"));
	ElsIf pRC = RC_OVERFLOW Then
		Return(NStr("en='The encoder has not already accomplished the previous task!';ru='Энкодер не закончил выполнение предыдущего задания!';de='Encoder hat die vorhergehende Aufgabe nicht beendet!'"));
	ElsIf pRC = RC_MAGNETIC_TRACK_ERROR Then
		Return(NStr("en='Card inserted wrongly or without magnetic stripe!';ru='Не правильно вставлена карта или карта без магнитной полосы!';de='Die Karte wurde falsch eingesetzt oder hat kein Magnetstreifen!'"));
	ElsIf pRC = RC_MAGNETIC_FORMAT_ERROR Then
		Return(NStr("en='You have removed card from the encoder before operation has finished or card/magnetic strip is damaged!';ru='Возможно сняли карту с энкодера не дожидаясь окончания операции или карта/магнитная полоса повреждена!';de='Möglicherweise haben Sie die Karte von Encoder vor dem Ende der Operation genommen oder die Karte/der Magnetstreifen ist beschädigt!'"));
	ElsIf pRC = RC_MAGNETIC_LEVEL_ERROR Then
		Return(NStr("en='The card has been encoded with a too low magnetic level due to dust in the reader magnetic head or low quality card!';ru='Низкий уровень намагничивания (возможно грязный энкодер или карта плохого качества)!';de='Niedriges Magnetisierungsniveau (möglicherweise ist der Encoder verschmutzt oder die Qualität der Karte ist schlecht)!'"));
	ElsIf pRC = RC_CARD_MEMORY_OVERFLOW Then
		Return(NStr("en='Card memory overflow!';ru='Переполнение памяти карты!';de='Der Kartenspeicher ist voll!'"));
	ElsIf pRC = RC_CARD_NOTADD_TYPE Then
		Return(NStr("en='An extension card is not supported for this model!';ru='Добавочная карта не поддерживается для этой модели!';de='Inkrementelle Karte wird für dieses Modell nicht unterstützt!'"));
	EndIf;
	Return "";
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"),"Warning",,,pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmConnect(pDevice)
	If Not ValueIsFilled(pDevice.Ref) Then
		Return Undefined;
	EndIf;
	
	vLock = Undefined;         

	// Fill system name
	vSystemName = String(pDevice.SystemName);
	Try    
		// ACC:561-off
		// Build ActiveX object to work with
		IsConnected = AttachAddIn("CommonTemplate.AddInLocksBonwinAutonomous", "Native", AddInType.Native);
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " door lock system connection error: '; de = '" + vSystemName + " door lock system connection error: '") + Chars.LF + ErrorDescription());
			Return Undefined;
		Endif;
		vLock = New("AddIn.Native.bwlocks");
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " door lock system connection error: '; de = '" + vSystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined; 
		// ACC:561-on
	EndTry;
	
	Return vLock;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pLock)
	pLock = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function SummBin(pArray2, pArray1)
	vNewCommArray = New Array();
    For Each vArray1 In pArray1 Do
        If vArray1 <> "000000" Then
            vNewCommArray.Add(vArray1);
        EndIf;
	EndDo;
	For Each vArray2 In pArray2 Do
        If vArray2 <> "000000" And vNewCommArray.Find(vArray2) = Undefined Then
            vNewCommArray.Add(vArray2);
        EndIf;
	EndDo;
	Return vNewCommArray;
EndFunction

// -----------------------------------------------------------------------------
Function GetCommDoors(pDoorLockFormKeyCard, pDoorLockFormRoom, pAssignedSettingsEquipment)
	vCommDoorsArray = New Array();
	vAssignedAuthorizationsKeyCard = "";
	vAssignedAuthorizationsRoom = "";
	If ValueIsFilled(pDoorLockFormKeyCard) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(pDoorLockFormKeyCard,"AssignedAuthorizations")) Then
		vAssignedAuthorizationsKeyCard = tcOnServer.cmGetAttributeByRef(pDoorLockFormKeyCard,"AssignedAuthorizations");
		vAuthorizationsKeyCardArray = StrSplit(vAssignedAuthorizationsKeyCard,";");
		If tcOnServer.cmGetAttributeByRef(pDoorLockFormKeyCard,"MergeWithDefault") Then
			If ValueIsFilled(pDoorLockFormRoom) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(pDoorLockFormRoom,"AssignedAuthorizations")) Then
				vAssignedAuthorizationsRoom = tcOnServer.cmGetAttributeByRef(pDoorLockFormRoom,"AssignedAuthorizations");
				vAuthorizationsRoomArray = StrSplit(vAssignedAuthorizationsRoom,";");
				vSumKeyCardAndRoom = SummBin(vAuthorizationsKeyCardArray,vAuthorizationsRoomArray); 
				If tcOnServer.cmGetAttributeByRef(pDoorLockFormRoom,"MergeWithDefault") Then
					If ValueIsFilled(pAssignedSettingsEquipment) Then
						vSettingsEquipmentArray = StrSplit(pAssignedSettingsEquipment,";");
						vCommDoorsArray = SummBin(vSettingsEquipmentArray,vSumKeyCardAndRoom);
					Else
						vCommDoorsArray = vSumKeyCardAndRoom;	
					EndIf;
				Else
					vCommDoorsArray = vSumKeyCardAndRoom;  	
				EndIf;
			Else
				If ValueIsFilled(pAssignedSettingsEquipment) Then
					vSettingsEquipmentArray = StrSplit(pAssignedSettingsEquipment,";");
					vCommDoorsArray = SummBin(vSettingsEquipmentArray,vAuthorizationsKeyCardArray);
				Else
					vCommDoorsArray = vAuthorizationsKeyCardArray;	
				EndIf;	
			EndIf;			
		Else
			vCommDoorsArray = vAuthorizationsKeyCardArray; 	
		EndIf;
	Else
		If ValueIsFilled(pDoorLockFormRoom) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(pDoorLockFormRoom,"AssignedAuthorizations")) Then
			vAssignedAuthorizationsRoom = tcOnServer.cmGetAttributeByRef(pDoorLockFormRoom,"AssignedAuthorizations");
			vAuthorizationsRoomArray = StrSplit(vAssignedAuthorizationsRoom,";");	
			If tcOnServer.cmGetAttributeByRef(pDoorLockFormRoom,"MergeWithDefault") Then
				If ValueIsFilled(pAssignedSettingsEquipment) Then
					vSettingsEquipmentArray = StrSplit(pAssignedSettingsEquipment,";");
					vCommDoorsArray = SummBin(vSettingsEquipmentArray,vAuthorizationsRoomArray);
				Else
					vCommDoorsArray = vAuthorizationsRoomArray;	
				EndIf;
			Else
				vCommDoorsArray = vAuthorizationsRoomArray;  	
			EndIf;
		Else
			vSettingsEquipmentArray = StrSplit(pAssignedSettingsEquipment,";");
			vCommDoorsArray = vSettingsEquipmentArray;	
		EndIf;
	EndIf;
	vRumsNum = 0;
	vCommDoors = "";
	For Each vCommDoorArray In vCommDoorsArray Do
		If vCommDoorArray <> "00000000" Then
			vRumsNum = vRumsNum + 1;
			vCommDoors = vCommDoors + vCommDoorArray;
			If vRumsNum = 7 Then
				Break;	
			EndIf;
		EndIf;
	EndDo;
	vCommDoorsS = new Structure("RumsNum, CommDoors",vRumsNum,vCommDoors);
	Return vCommDoorsS; 
EndFunction

// -----------------------------------------------------------------------------
Function Dec2Hex(pDec)
	vBase = "123456789ABCDEF";
	vHexLE = "";
	vDiv = pDec;
	While vDiv > 0 Do
		vIntDiv = Int(vDiv/16);
		vHexChar = "0";
		If vDiv <> vIntDiv*16 Then
			vHexChar = Mid(vBase, (vDiv - vIntDiv*16), 1);
		EndIf;
		vHexLE = vHexChar + vHexLE;
		vDiv = vIntDiv;
	EndDo;
	While StrLen(vHexLE) < 4 Do
		vHexLE = "0" + vHexLE;
	EndDo;
	Return vHexLE;
EndFunction // cmBin2Hex

// -----------------------------------------------------------------------------
Function GetCartType(pLockType)
	cType = 30;
	If (pLockType = "801") Then
	    cType = 7;
	ElsIf (pLockType = "802") Then 
	    cType = 20;
	ElsIf (pLockType = "8031") Then
	    cType = 30;
	ElsIf (pLockType = "804") Then
	    cType = 10;
	ElsIf (pLockType = "8090") Then
	    cType = 14;
	ElsIf (pLockType = "809") Then
	    cType = 15;
	ElsIf (pLockType = "8032") Then
	    cType = 30;
	ElsIf (pLockType = "8038") Then
	    cType = 30;
	ElsIf (pLockType = "823") Then
	    cType = 30;
	ElsIf (pLockType = "893") Then
	    cType = 30;
	ElsIf (pLockType = "8938") Then
	    cType = 30;
	EndIf;
	Return cType;
EndFunction

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
Function pmNewKeyHotelLock(pTypeKey, pLock, pConnectionParameters, pParameters, rErrorMessage)
	RC_OK = 0;
	RC_NO_CONNECTION = -1;
	RC_ROOM_WITHOUT_DOOR_LOCK = 114;
	
	pLock.LockType = Number(pConnectionParameters.LockType);
	pLock.Location = pConnectionParameters.NameOfTheFolder;
	pLock.FileName = pConnectionParameters.FileName;
	pLock.CardType = GetCartType(pConnectionParameters.LockType);
	
	DateNow = Format(tcOnServer.cmGetServerCurrentSessionDate(),"DF=yyMMddHHmm");
	RNG = New RandomNumberGenerator(Number(DateNow));
	vNuberCart = TrimAll(Format(RNG.RandomNumber(1048576,16777215),"NFD=0; NG="));
	vNuberCartHex = Dec2Hex(Number(vNuberCart)); 
	
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pConnectionParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - pConnectionParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If pConnectionParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pConnectionParameters.AddMinutes*60;
	EndIf;
	
	vSDate = Format(vCheckInDate,"DF=yyMMddHHmm");
	vEDate = Format(vCheckOutDate,"DF=yyMMddHHmm");
	
	vParams = pTypeKey;
	vRooms = "";
	// Build command data string
	If ValueIsFilled(tcOnServer.cmGetAttributeByRef(pParameters.Room,"LockCode")) Then
		vRoomCode = TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Room,"LockCode"));
		If IsBlankString(vRoomCode) Then
			Return RC_ROOM_WITHOUT_DOOR_LOCK; 
		EndIf;
		// Get building number
		vRoomsArray = StrSplit(vRoomCode,".");
		For Each vRoom In vRoomsArray Do
			vRooms = vRooms + TrimAll(vRoom); 
		EndDo;
		vRoomsReg = vRooms;
	EndIf;
	If pConnectionParameters.LockType = "8032" Or pConnectionParameters.LockType = "8038" Then
		vRoomsNum = 1;
		If pConnectionParameters.AllowDynamicAuthorizations Then
			vDoorLockSystemDef = "";
			For i = 1 To 7 Do
				If i <> 7 Then
					vDoorLockSystemDef = vDoorLockSystemDef + pConnectionParameters["OtherLock" + i] + ";";
				Else
					vDoorLockSystemDef = vDoorLockSystemDef + pConnectionParameters["OtherLock" + i];
				EndIf;
			EndDo;
			vDoorLockSystemAuthorization = GetCommDoors(pParameters.DoorLockSystemAuthorization, tcOnServer.cmGetAttributeByRef(pParameters.Room,"DoorLockSystemAuthorization"), vDoorLockSystemDef);				
			vRooms = TrimAll(Number(vDoorLockSystemAuthorization.RumsNum) + vRoomsNum) + vRooms + vDoorLockSystemAuthorization.CommDoors + "00000000000000000000000000000000000000000000000000";    
		Else
			vRooms = TrimAll(vRoomsNum) + TrimAll(vRooms) + "00000000000000000000000000000000000000000000000000";
		EndIf;
		vParams = TrimAll(vParams) + TrimAll(pConnectionParameters.HotelPassword) + TrimAll(vEDate) + TrimAll(vSDate) + vNuberCartHex + "0000000000000000000000000000000000000000000";    
		vErrorCode = pLock.MakeGuestCard803(pConnectionParameters.SectorNumber, vParams, vRooms);
	Else
	 vParams = TrimAll(vParams) + TrimAll(pConnectionParameters.HotelPassword) + TrimAll(vRooms) + TrimAll(vEDate) + TrimAll(vSDate) + vNuberCartHex + "0000000000000000000000000000000000000000000";	
	 vErrorCode = pLock.MakeGuestCard(vParams);
	EndIf;
	If vErrorCode = RC_OK Then
		vIdentificationCard = Undefined;
		vCardID ="";
		If StrLen(pLock.CardID) <> 8 Then 
			vCardIDHex = Mid(pLock.CardID,StrLen(pLock.CardID) - 7);
			If pConnectionParameters.ConvertCardIDToDec Then
				vCardID = HexToDec(vCardIDHex,16);
			Else
				vCardID = vCardIDHex;
			EndIf;
		Else
			vCardIDHex = pLock.CardID;
			If pConnectionParameters.ConvertCardIDToDec Then
				vCardID = HexToDec(vCardIDHex,16);
			Else
				vCardID = vCardIDHex;
			EndIf;
		EndIf;
		If pConnectionParameters.ReturnCardUID Then
			If pParameters.Property("IdentificationCard") Then
				vIdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardID);
				pParameters.IdentificationCard = vIdentificationCard;
			EndIf;
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"),"Information",,,NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(vRoomsReg) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW",TrimAll(vNuberCart), pParameters.Room, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);
	Else
		rErrorMessage = pLock.ErrorDescription;
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + rErrorMessage);
	EndIf;
	Return vErrorCode; 	
EndFunction // pmNewKeyHotelLock

// -----------------------------------------------------------------------------
Function pmNewKeyHotelNetLock(pTypeKey, pLock, pConnectionParameters, pParameters, rErrorMessage)
	RC_OK = 0;
	RC_NO_CONNECTION = -1;
	RC_ROOM_WITHOUT_DOOR_LOCK = 114;
	RC_CARD_NOTADD_TYPE = 999;
	
	pLock.LockType = Number(pConnectionParameters.LockType);
	pLock.Location = pConnectionParameters.NameOfTheFolder;
	pLock.FileName = pConnectionParameters.FileName;
	
	pLock.CardType = GetCartType(pConnectionParameters.LockType);	
	DateNow = Format(tcOnServer.cmGetServerCurrentSessionDate(),"DF=yyMMddHHmm");
	RNG = New RandomNumberGenerator(Number(DateNow));
	vNuberCart = TrimAll(Format(RNG.RandomNumber(1048576,16777215),"NFD=0; NG="));
	
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pConnectionParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - pConnectionParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If pConnectionParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pConnectionParameters.AddMinutes*60;
	EndIf;
	
	vSDate = Format(vCheckInDate,"DF=yyMMddHHmm");
	vEDate = Format(vCheckOutDate,"DF=yyMMddHHmm");
	
	vRooms = "";
	// Build command data string
	If ValueIsFilled(tcOnServer.cmGetAttributeByRef(pParameters.Room,"LockCode")) Then
		vRoomCode = TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Room,"LockCode"));
		If IsBlankString(vRoomCode) Then
			Return RC_ROOM_WITHOUT_DOOR_LOCK; 
		EndIf;
		// Get building number
		vRoomsArray = StrSplit(vRoomCode,".");
		For Each vRoom In vRoomsArray Do
			vRooms = vRooms + TrimAll(vRoom); 
		EndDo;
		vRoomsReg = vRooms;
	EndIf;
	If pConnectionParameters.LockType = "893" Or pConnectionParameters.LockType = "8938" Then
		If pTypeKey = "A" Then
			vParams = "C4";	
		Else
			vParams = "C5";	
		EndIf;
		vRoomsNum = 1;
		If pConnectionParameters.AllowDynamicAuthorizations Then
			vDoorLockSystemDef = "";
			For i = 1 To 7 Do
				If i <> 7 Then
					vDoorLockSystemDef = vDoorLockSystemDef + pConnectionParameters["OtherLock" + i] + ";";
				Else
					vDoorLockSystemDef = vDoorLockSystemDef + pConnectionParameters["OtherLock" + i];
				EndIf;
			EndDo;
			vDoorLockSystemAuthorization = GetCommDoors(pParameters.DoorLockSystemAuthorization, tcOnServer.cmGetAttributeByRef(pParameters.Room,"DoorLockSystemAuthorization"), vDoorLockSystemDef);				
			vRooms = TrimAll(Number(vDoorLockSystemAuthorization.RumsNum) + vRoomsNum) + vRooms + vDoorLockSystemAuthorization.CommDoors + "00000000000000000000000000000000000000000000000000";    
		Else
			vRooms = TrimAll(vRoomsNum) + TrimAll(vRooms) + "00000000000000000000000000000000000000000000000000";
		EndIf;
		vParams = TrimAll(vParams) + TrimAll(vEDate)+ "00002359" + Format(tcOnServer.cmGetServerCurrentSessionDate(), "DF=yyMMddHHmm");    
		vErrorCode = pLock.MakeGuestCard893(pConnectionParameters.SectorNumber, vParams, vRooms);
	Else	
		vParams = "24" + TrimAll(pConnectionParameters.HotelPassword) + TrimAll(vRooms)+ "00" + TrimAll(vEDate)+ "00002359" + TrimAll(vSDate);	
		vErrorCode = pLock.MakeGuestCard823(vParams);
	EndIf;
	If vErrorCode = RC_OK Then
		vIdentificationCard = Undefined;
		vCardID ="";
		If pConnectionParameters.LockType = "893" Or pConnectionParameters.LockType = "8938" Then
       		vCardID = Left(pLock.CardID, 8); 
		Else
			If StrLen(pLock.CardID) <> 8 Then 
				vCardIDHex = Mid(pLock.CardID,StrLen(pLock.CardID) - 7);
				If pConnectionParameters.ConvertCardIDToDec Then
					vCardID = HexToDec(vCardIDHex,16);
				Else
					vCardID = vCardIDHex;
				EndIf;
			Else
				vCardIDHex = pLock.CardID;
				If pConnectionParameters.ConvertCardIDToDec Then
					vCardID = HexToDec(vCardIDHex,16);
				Else
					vCardID = vCardIDHex;
				EndIf;
			EndIf;	
		EndIf;
		If pConnectionParameters.ReturnCardUID And Not IsBlankString(vCardID) Then
			If pParameters.Property("IdentificationCard") Then
				vIdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardID);
				pParameters.IdentificationCard = vIdentificationCard;
			EndIf;
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"),"Information",,,NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(vRoomsReg) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW",TrimAll(vNuberCart), pParameters.Room, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);
	Else
		rErrorMessage = pLock.ErrorDescription;
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + rErrorMessage);
	EndIf;
	Return vErrorCode;	
EndFunction // pmNewKeyHotelNetLock

// -----------------------------------------------------------------------------
Function pmParseCardDescription(pLock, pConnectionParameters, pParameters)
	vCardInfo = pLock.CardInfo; 
	vCardID = "";
	If pConnectionParameters.LockType = "893" Or pConnectionParameters.LockType = "8938" Then
		vCardInfo = Left(vCardInfo, 38);
		vCardID = Right(vCardInfo, 8);		
	Else
		If StrLen(pLock.CardID) <> 8 Then 
			vCardID = Mid(pLock.CardID,StrLen(pLock.CardID)-7) 	
		Else
			vCardID = pLock.CardID;	
		EndIf;
	EndIf; 
	
	vCardFullName = "";
	vIDCardRef = tcDoorLocksAtServer.GetIdentificationCardsRefByCardID(vCardID);
	If ValueIsFilled(vIDCardRef) Then
		vClient = tcOnServer.cmGetAttributeByRef(vIDCardRef, "Client");
		If ValueIsFilled(vClient) Then
			vCardFullName = tcOnServer.cmGetAttributeByRef(vClient, "FullName");
		EndIf;
	EndIf;	
	
	If pConnectionParameters.LockType = "8032" Or pConnectionParameters.LockType = "8038" Then
		vRoomCode = Mid(pLock.Room, 2, 6);
		vCheckinTime = Mid(vCardInfo, 20, 10); 
		vCheckoutTime = Mid(vCardInfo, 10, 10);
	ElsIf pConnectionParameters.LockType = "823" Then
		vRoomCode = Mid(vCardInfo, 11, 6);
		vCheckinTime = Mid(vCardInfo, 37, 10); 
		vCheckoutTime = Mid(vCardInfo, 19, 10);
	ElsIf pConnectionParameters.LockType = "893" Or pConnectionParameters.LockType = "8938" Then
		vRoomCode = Mid(pLock.Room, 2, 6);
		vCheckinTime = Mid(vCardInfo, 21, 10); 
		vCheckoutTime = Mid(vCardInfo, 3, 10);
	Else
		vRoomCode = Mid(vCardInfo, 10, 6);
		vCheckinTime = Mid(vCardInfo, 26, 10); 
		vCheckoutTime = Mid(vCardInfo, 16, 10);	
	EndIf;
	
	vRoomRef = tcDoorLocksAtServer.GetRoomRefByCode(TrimAll(vRoomCode));
	                              
	If ValueIsFilled(vRoomRef) Then
		vRoom = vRoomRef;
	Else
		vRoom = vRoomCode;
	EndIf;
	
	vYears = TrimAll(Format(tcOnServer.cmGetServerCurrentSessionDate(),"DF=yyyy"));
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
	vCardData.Insert("CardCheckInDate", StrNuwFormat(vCheckinTime));
	vCardData.Insert("CardCheckOutDate", StrNuwFormat(vCheckoutTime));
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", vCardID);
	vCardData.Insert("CardFullName", vCardFullName);
	
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

// -----------------------------------------------------------------------------
Function StrNuwFormat(pStr)
	vNewStr = "";
	If ValueIsFilled(pStr) And StrLen(pStr) = 10 Then
		vYear = Mid(PStr,1,2);
		vMonth = Mid(PStr,3,2);
		vDay = Mid(PStr,5,2);
		vHour = Mid(PStr,7,2);
		vMinute = Mid(PStr,9,2);
		vNewStr = vDay + "." + vMonth + "." + vYear + " " + vHour + ":" + vMinute;
	EndIf;
	Return vNewStr;
EndFunction // StrNuwFormat

#EndRegion
