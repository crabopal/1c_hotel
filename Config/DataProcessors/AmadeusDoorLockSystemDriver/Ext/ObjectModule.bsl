
#Region Variables

Var SEP;
Var ENQ;
Var ACK;
Var NAK;
Var STX;
Var ETX;
Var DLE;

// -----------------------------------------------------------------------------
Var RC_SYNTAX_ERROR Export; // Syntax error
Var RC_NO_COMMUNICATION Export; // No communication
Var RC_OVERFLOW Export; // Overflow
Var RC_MAGNETIC_TRACK_ERROR Export; // Error
Var RC_MAGNETIC_FORMAT_ERROR Export; // Error
Var RC_MAGNETIC_LEVEL_ERROR Export; // Error
Var RC_NO_CONNECTION Export; // No connection
Var RC_OK Export; // Ok
Var RC_UNKNOWN Export; // Unknown
Var RC_DEVICE_TIME_OUT Export; // Device time out
Var RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Export; // No guest previously checked in
Var RC_WRONG_ROOM Export; // Wrong room
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_NO_REPLY Export; // No reply
Var RC_WRONG_REPLY Export; // Wrong reply
Var RC_CARD_MEMORY_OVERFLOW Export; // Card memory overflow

// -----------------------------------------------------------------------------
Var SystemName;

// -----------------------------------------------------------------------------
Var CSWSOCK6_LICENSE_KEY;
Var CSWSOCK10_LICENSE_KEY;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmNewKey() Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);

	// Build command data string
	vRoomCode = TrimR(Room);
	If ValueIsFilled(Room) Then
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(DoorLockSystemParameters.DefaultRoom) Then
		Room = DoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(Room);
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	// 3. Room 1
	vDta = SEP + vRoomCode; 
	
	// 4. Room 2 
	vDta = vDta + SEP; // Room 2
	
	// 5. Room 3
	vDta = vDta + SEP; // Room 3
	
	// 6. Room 4
	vDta = vDta + SEP; // Room 4
	
	// 7. Assigned authorizations
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If ValueIsFilled(DoorLockSystemParameters) And 
		   Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) And 
		   vDoorLockSystemAuthorization.MergeWithDefault Then
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
		Else
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		vDta = vDta + SEP + TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	
	// 8. Denied authorizations
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.DeniedAuthorizations) Then
		If ValueIsFilled(DoorLockSystemParameters) And 
		   Not IsBlankString(DoorLockSystemParameters.DeniedAuthorizations) And 
		   vDoorLockSystemAuthorization.MergeWithDefault Then
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.DeniedAuthorizations) + TrimAll(DoorLockSystemParameters.DeniedAuthorizations);
		Else
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.DeniedAuthorizations);
		EndIf;
	Else
		vDta = vDta + SEP + TrimAll(DoorLockSystemParameters.DeniedAuthorizations);
	EndIf;
	
	// 9  Initial date - Useless
	vDta = vDta + SEP;
	
	// 10. Expire date
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + Format(vCheckOutDate,"DF=HHddMMyy");
	
	// 11. Operators data - Useless.
	vDta = vDta + SEP + SEP;
	
	// 12,13 Add tack 1 and track 2 data  - Useless
	vDta = vDta + SEP +SEP;		
	
	// Call API
	vErrorCode = MakeNewKey(vDLSys, vEncoderNumber, vDta);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
	Else
		// Get ID Card
		vCardDesc = "";
		vErrorCode = Verify(vDLSys, vEncoderNumber, vCardDesc);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
		EndIf;
		// Update data
		IdentificationCard = cmGetClientIdentificationCard(vCardDesc, Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, True,vCardDesc);
		// Write log
		WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
		cmWriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, vDta, CurrentSessionDate(), vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
	EndIf;
	
	pmDisconnect(vDLSys);
	Return vErrorCode;
EndFunction //  pmNewKey

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code
//
Function pmAddKey() Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);

	// Build command data string
	vRoomCode = TrimR(Room);
	If ValueIsFilled(Room) Then
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(DoorLockSystemParameters.DefaultRoom) Then
		Room = DoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(Room);
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	// 3. Room 1
	vDta = SEP + vRoomCode; 
	
	// 4. Room 2
	vDta = vDta + SEP; // Room 2
	
	// 5. Room 3
	vDta = vDta + SEP; // Room 3
	
	// 6. Room 4
	vDta = vDta + SEP; // Room 4
	
	// 7. Assigned authorizations
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If ValueIsFilled(DoorLockSystemParameters) And 
		   Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) And 
		   vDoorLockSystemAuthorization.MergeWithDefault Then
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
		Else
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		vDta = vDta + SEP + TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	
	// 8. Denied authorizations
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.DeniedAuthorizations) Then
		If ValueIsFilled(DoorLockSystemParameters) And 
		   Not IsBlankString(DoorLockSystemParameters.DeniedAuthorizations) And 
		   vDoorLockSystemAuthorization.MergeWithDefault Then
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.DeniedAuthorizations) + TrimAll(DoorLockSystemParameters.DeniedAuthorizations);
		Else
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.DeniedAuthorizations);
		EndIf;
	Else
		vDta = vDta + SEP + TrimAll(DoorLockSystemParameters.DeniedAuthorizations);
	EndIf;
	
	// 9.  Initial date - Useless
	vDta = vDta + SEP;
	
	// 10. Expire date
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + Format(vCheckOutDate,"DF=HHddMMyy");
	
	// 11. Operators data - Useless.
	vDta = vDta + SEP + SEP;
	
	// 12,13 Add tack 1 and track 2 data  - Useless
	vDta = vDta + SEP +SEP;		
	
	// Call API
	vErrorCode = AddKey(vDLSys, vEncoderNumber, vDta);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
	Else
		// Get ID Card
		vCardDesc = "";
		vErrorCode = Verify(vDLSys, vEncoderNumber, vCardDesc);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
		EndIf;
		// Update data
		IdentificationCard = cmGetClientIdentificationCard(vCardDesc, Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, True,vCardDesc);
		// Write log
		WriteLogEvent(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
		cmWriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, vDta, CurrentSessionDate(), vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
	EndIf;
	
	pmDisconnect(vDLSys);
	Return vErrorCode;
EndFunction //  pmAddKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel					 - CatalogRef.Hotel	 - Ref 
//  pAssignedAuthorizations	 - String	 - Assigned authorization
// 
// Returns:
//  CatalogRef.DoorLockSystemAuthorizations - Catalog ref or undefined 
//
Function pmFindAuthorizations(pHotel, pAssignedAuthorizations) Export
	vAuthRef = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DoorLockSystemAuthorizations.Ref
	|FROM
	|	Catalog.DoorLockSystemAuthorizations AS DoorLockSystemAuthorizations
	|WHERE
	|	DoorLockSystemAuthorizations.AssignedAuthorizations = &qAssignedAuthorizations
	|	AND (DoorLockSystemAuthorizations.Hotel = &qHotel
	|			OR &qIsEmptyHotel)
	|	AND (NOT DoorLockSystemAuthorizations.DeletionMark)
	|	AND (NOT DoorLockSystemAuthorizations.IsFolder)
	|ORDER BY
	|	DoorLockSystemAuthorizations.Code";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qAssignedAuthorizations", pAssignedAuthorizations);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() = 1 Then
		vAuthRef = vQryRes.Get(0).Ref;
	EndIf;
	Return vAuthRef;
EndFunction //  pmFindAuthorizations

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - Structure - Card data
// 
// Returns:
//  String - Error code 
//
Function pmVerify(pCardData) Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	
	// Get ID Card
	vCardDesc = "";
	vErrorCode = Verify(vDLSys, vEncoderNumber, vCardDesc);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc);
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys);
	
	Return vErrorCode;
EndFunction //  pmVerify

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmCancel() Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	vRoomCode = TrimR(Room);
	If ValueIsFilled(Room) Then
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	vDta = SEP + vRoomCode;
	
	// Get encoder number
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	
	// Call API
	vErrorCode = CancelKeys(vDLSys, vEncoderNumber, vDta);
	If vErrorCode <> RC_OK Then
		AddError(NStr("ru = 'Ошибка отмены ранее выданных карт: '; en = 'Error cancelling keys: '; de = 'Error cancelling keys: '") + vErrorCode);
	Else
		// Get ID Card
		vCardDesc = "";
		vErrorCode = Verify(vDLSys, vEncoderNumber, vCardDesc);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
		Else
			// Parse returned data
			pCardData = pmParseCardDescription(vCardDesc);
		EndIf;
		
		If ValueIsFilled(IdentificationCard) Then
			vObjCard = IdentificationCard.GetObject();
			vObjCard.IsCheckedOut = True;
			vObjCard.IsBlocked	  = True;
			vObjCard.Write();
		EndIf;	
		
		WriteLogEvent(NStr("en='DoorLockSystem.CancelKeyCards'; de='DoorLockSystem.CancelKeyCards'; ru='СистемаЭлектронныхЗамков.ОтменаРанееВыданныхКлючей'"), EventLogLevel.Information, , , NStr("ru = 'Отменены ключи номера: '; en = 'Key cards canceled: '; de = 'Key cards canceled: '") + TrimAll(Room));
		cmWriteKeyCardSecuritySystemEvent("CANCEL", "", Room, vDta, '00010101', '00010101', ParentDoc, Guest, 0);
	EndIf;
	
	pmDisconnect(vDLSys);
	Return vErrorCode;
EndFunction //  pmCancel

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRC	 - String	 - Return code
// 
// Returns:
//  String - Error description
//
Function pmGetErrorDescription(pRC) Export
	If pRC = RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + SystemName + "!'; 
		            |de = 'Failed to connect to the door locks system " + SystemName + "!'; 
		            |en = 'Failed to connect to the door locks system " + SystemName + "!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en = 'Unknown error! See error log for details.'; ru = 'Неизвестная ошибка! Дополнительная информация сохранена в системном логе.'; de = 'Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en = 'The reader/writer has been waiting too long for a card!'; ru = 'Закончилось время ожидания карты энкодером!'; de = 'Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Then
		Return(NStr("en = 'No checked in guests in the room! Make new key card instead.'; ru = 'В номере нет размещенных гостей! Выдайте гостю новую карту.'; de = 'In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en = 'Room is wrong!'; ru = 'Номер комнаты указан неверно!'; de = 'Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + SystemName + " не отвечает!'; 
		            |de = 'System " + SystemName + "  antwortet nicht!'; 
		            |en = '" + SystemName + " system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + SystemName + " получен ответ в неизвестном формате!'; 
		            |de = '" + SystemName + " system replied with unknown format!'; 
		            |en = '" + SystemName + " system replied with unknown format!'"));
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
	EndIf;		
EndFunction //  pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure //  AddError

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString()
	vStr = ""; // "9600,N,8,1,P" by default
	// Baudrate
	If DoorLockSystemParameters.BaudRate > 0 Then
		vStr = vStr + Format(DoorLockSystemParameters.BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "9600";
	EndIf;
	// Parity
	If ValueIsFilled(DoorLockSystemParameters.Parity) Then
		If DoorLockSystemParameters.Parity = Enums.ParityTypes.Even Then
			vStr = vStr + ",E";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.Odd Then
			vStr = vStr + ",O";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.None Then
			vStr = vStr + ",N";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.Mark Then
			vStr = vStr + ",M";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.Space Then
			vStr = vStr + ",S";
		EndIf;
	Else
		vStr = vStr + ",N";
	EndIf;
	// Data length
	If ValueIsFilled(DoorLockSystemParameters.DataBits) Then
		If DoorLockSystemParameters.DataBits = Enums.DataBits.Bits8 Then
			vStr = vStr + ",8";
		ElsIf DoorLockSystemParameters.DataBits = Enums.DataBits.Bits7 Then
			vStr = vStr + ",7";
		EndIf;
	Else
		vStr = vStr + ",8";
	EndIf;
	// Stop bits
	If ValueIsFilled(DoorLockSystemParameters.StopBits) Then
		If DoorLockSystemParameters.StopBits = Enums.StopBits.Bits1 Then
			vStr = vStr + ",1";
		ElsIf DoorLockSystemParameters.StopBits = Enums.StopBits.Bits2 Then
			vStr = vStr + ",2";
		EndIf;
	Else
		vStr = vStr + ",1";
	EndIf;
	// Hardware flow control always
	vStr = vStr + ",P";
	Return vStr;		
EndFunction //  GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function RS232Acknowledgement(pDLSys)
	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.WriteStr(ENQ);
	If vBytesSent = 1 Then
		pDLSys.TimeoutReadTotalConstant = 3000;
		vReply = pDLSys.ReadStr();
		If vReply = ACK Then
			Return True;
		ElsIf vReply = NAK Then
			AddError(NStr("en = 'NAK received on acknowledgement!'; ru = 'При подтверждении связи получен NAK!'; de = 'Bei der Bestätigung der Verbindung NAK erhalten!'"));
		Else
			AddError(NStr("en = 'Wrong reply received on acknowledgement: '; ru = 'При подтверждении связи получен символ: '; de = 'Bei der Bestätigung der Verbindung Symbol erhalten: '") + vReply);
		EndIf;
	Else
		AddError(NStr("en = 'Wrong number of bytes sent on acknowledgement: '; ru = 'При подтверждении связи отправлено байт: '; de = 'Bei der Bestätigung der Verbindung Byte versendet: '") + vBytesSent);
	EndIf;
	Return False;
EndFunction //  RS232Acknowledgement

// -----------------------------------------------------------------------------
Function TCPAcknowledgement(pDLSys)
	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.Write(ENQ, 1);
	If vBytesSent <> -1 Then
		pDLSys.Timeout = 3;
		vReply = "";
		If pDLSys.Read(vReply, 1) <> -1 Then
			If vReply = ACK Then
				Return True;
			ElsIf vReply = NAK Then
				AddError(NStr("en = 'NAK received on acknowledgement!'; ru = 'При подтверждении связи получен NAK!'; de = 'Bei der Bestätigung der Verbindung NAK erhalten!'"));
			Else
				AddError(NStr("en = 'Wrong reply received on acknowledgement: '; ru = 'При подтверждении связи получен символ: '; de = 'Bei der Bestätigung der Verbindung Symbol erhalten: '") + vReply);
			EndIf;
		Else
			AddError(NStr("en = 'Acknowledgement error: '; ru = 'Ошибка подтверждения связи: '; de = 'Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		EndIf;
	Else
		AddError(NStr("en = 'Acknowledgement error: '; ru = 'Ошибка подтверждения связи: '; de = 'Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
	EndIf;
	Return False;
EndFunction //  TCPAcknowledgement

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "Amadeus ST40";
		
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vDLSys = Undefined;
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
			vDLSys = New COMObject("SPort.SPortAx.1");
			// Set connection parameters
			vDLSys.InitString(GetCOMPortConnectionString());
			// Open COM port
			vIsOpen = vDLSys.Open(TrimAll(DoorLockSystemParameters.Port));
			If Not vIsOpen Then
				AddError(NStr("en = 'Failed to open port: '; ru = 'Не удалось открыть порт: '; de = 'Der Port konnte nicht geöffnet werden: '") + TrimAll(DoorLockSystemParameters.Port));
				Return Undefined;
			EndIf;
			// Set block mode
			vDLSys.BlockMode = True;
			// Setup timeouts
			vDLSys.TimeoutReadInterval = 1000;
			vDLSys.TimeoutReadTotalConstant = 3000;
			vDLSys.TimeoutReadTotalMultiplier = 100;
			vDLSys.TimeoutWriteTotalConstant = 3000;
			vDLSys.TimeoutWriteTotalMultiplier = 100;
			// Send/receive acknowledgement
			If Not RS232Acknowledgement(vDLSys) Then
				AddError(NStr("ru = 'Не удалось получить подтверждение установки связи с системой " + SystemName + "!'; 
				              |de = 'Acknowledgement with system " + SystemName + " failed!'; 
				              |en = 'Acknowledgement with system " + SystemName + " failed!'"));
				vDLSys.Close();
				Return Undefined;
			EndIf;
		Else
			Try
			    vDLSys = New COMObject("SocketTools.SocketWrench.10");
				// Load license
				vErrorCode = vDLSys.Initialize(CSWSOCK10_LICENSE_KEY);
			Except
				vDLSys = New COMObject("SocketTools.SocketWrench.6");
				// Load license
				vErrorCode = vDLSys.Initialize(CSWSOCK6_LICENSE_KEY);
			EndTry;
			If vErrorCode <> 0 Then
				AddError(NStr("en = 'SocketTools.SocketWrench component initialization error: '; ru = 'Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: '; de = 'Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '") + vErrorCode);
				Return Undefined;
			EndIf;     
			vDLSys.Blocking = True;
			vDLSys.Timeout = 60; // 60 seconds blocking read timeout by default
			vErrorCode = vDLSys.Connect(TrimAll(DoorLockSystemParameters.ServerName), Number(TrimAll(DoorLockSystemParameters.Port)));
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Не найден сервер системы электронных замков " + SystemName + ": '; 
				              |de = '" + SystemName + " system server was not found: '; 
				              |en = '" + SystemName + " system server was not found: '") + vErrorCode);
				Return Undefined;
			EndIf;     
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; 
		              |de = '" + SystemName + " door lock system connection error: '; 
		              |en = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vDLSys;
EndFunction //  pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys)
	Try
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
			pDLSys.Close();
		Else
			vErrorCode = pDLSys.Disconnect();
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + SystemName + ": '; 
				              |de = '" + SystemName + " server disconnect error: '; 
				              |en = '" + SystemName + " server disconnect error: '") + vErrorCode);
				Return;
			EndIf;  
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + SystemName + ": '; 
		              |de = '" + SystemName + " system disconnect error: '; 
		              |en = '" + SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
Function GetErrorCode(pRC)
	vErrorCode = RC_UNKNOWN;
	If pRC = "ES" Then
		vErrorCode = RC_SYNTAX_ERROR;
	ElsIf pRC = "NC" Then
		vErrorCode = RC_NO_COMMUNICATION;
	ElsIf pRC = "NF" Then
		vErrorCode = RC_CARD_MEMORY_OVERFLOW;
	ElsIf pRC = "OV" Then
		vErrorCode = RC_OVERFLOW;
	ElsIf pRC = "EP" Then
		vErrorCode = RC_MAGNETIC_TRACK_ERROR;
	ElsIf pRC = "EF" Then
		vErrorCode = RC_MAGNETIC_FORMAT_ERROR;
	ElsIf pRC = "EN" Then
		vErrorCode = RC_MAGNETIC_LEVEL_ERROR;
	ElsIf pRC = "TD" Then
		vErrorCode = RC_WRONG_ROOM;
	ElsIf pRC = "ED" Then
		vErrorCode = RC_DEVICE_TIME_OUT;
	ElsIf pRC = "EA" Then
		vErrorCode = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN;
	ElsIf pRC = "OS" Then
		vErrorCode = RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	Return vErrorCode;
EndFunction //  GetErrorCode

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pReadTimeout = 60000, pEncoderNumber, pCommandCode, pDta, pWithRetention = "", pReply)
	vErrorCode = RC_OK;
	pReply = "";
	// Format encoder number and source address
	vEncoderNumber = TrimAll(pEncoderNumber);
	If pCommandCode = "CO" Then
		vEncoderNumber = 0; //Command CO (check-out) does not involve encoders
	EndIf;	
	// 0. Build command string for the TCP interface
	vCmd = SEP + pCommandCode; // Command code
	// 1. Number of the encoder
	vCmd = vCmd + SEP + vEncoderNumber; // Destination address
	// 2. Ejection or retention of card - Useless
	vCmd = vCmd + SEP;	
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + SEP + ETX;
	vCmd = STX + vCmd + cmCharLRC(vCmd);

	// Send acknowledgement
	If Not RS232Acknowledgement(pDLSys) Then
		Return RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	pDLSys.TimeoutReadTotalConstant = 3000;
	For i = 1 To 3 Do
		vBytesSent = pDLSys.WriteStr(vCmd);
		If vBytesSent > 0 Then
			vReply = pDLSys.ReadStr();
			If vReply = ACK Then
				Break;
			Else
				If vReply <> NAK Then
					Return RC_NO_REPLY;
				EndIf;
				pDLSys.PurgeQueue();
			EndIf;
		Else
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	pDLSys.PurgeQueue();
	If vReply = NAK Then
		Return RC_SYNTAX_ERROR;
	EndIf;
	// Read command reply message
	vReadOK = False;
	pDLSys.TimeoutReadTotalConstant = pReadTimeout;
	For i = 1 To 3 Do
		pReply = pDLSys.ReadStr();
		If Not IsBlankString(pReply) Then
			// Check LRC
			pReply = StrReplace(pReply, STX, "");
			If cmCheckCharLRC(pReply) Then
				vBytesSent = pDLSys.WriteStr(ACK);
				vReadOK = True;
				Break;
			Else
				vBytesSent = pDLSys.WriteStr(NAK);
				pDLSys.TimeoutReadTotalConstant = 3000;
			EndIf;
		Else
			Return RC_NO_REPLY;
		EndIf;
	EndDo;
	If Not vReadOK Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		// Retreive return code
		vRC = Mid(pReply, 2, 2);
		If vRC <> Left(pCommandCode, 2) Then
			AddError(NStr("ru = 'Ошибка системы эл. замков " + SystemName + ": '; 
			              |de = '" + SystemName + " system error: '; 
			              |en = '" + SystemName + " system error: '") + pReply + " <- " + vCmd);
			vErrorCode = GetErrorCode(vRC);
		Else
			// Retreive reply data
			vPrefixLen = StrLen(SEP + pCommandCode + SEP + vEncoderNumber);
			If StrLen(pReply) > vPrefixLen Then
				pReply = Mid(pReply, vPrefixLen+1, StrLen(pReply) - vPrefixLen);
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  CallRS232Command

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pEncoderNumber, pCommandCode, pDta, pWithRetention = "", pReply)
	vErrorCode = RC_OK;
	pReply = "";
	// Format encoder number and source address
	vEncoderNumber = TrimAll(pEncoderNumber);
	If pCommandCode = "CO" Then
		vEncoderNumber = 0; //Command CO (check-out) does not involve encoders
	EndIf;	
	// 0. Build command string for the TCP interface
	vCmd = SEP + pCommandCode; // Command code
	// 1. Number of the encoder
	vCmd = vCmd + SEP + vEncoderNumber; // Destination address
	// 2. Ejection or retention of card - Useless
	If pCommandCode <> "CO" Then	
		vCmd = vCmd + SEP;	
	EndIf;
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + SEP + ETX;
	vCmd = STX + vCmd + cmCharLRC(vCmd);
	// Send acknowledgement
	If Not TCPAcknowledgement(pDLSys) Then
		Return RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	pDLSys.Timeout = 3;
	For i = 1 To 3 Do
		If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
			vReply = "";
			If pDLSys.Read(vReply, 1) <> -1 Then
				If vReply = ACK Then
					Break;
				Else
					If vReply <> NAK Then
						Return RC_NO_REPLY;
					EndIf;
				EndIf;
			Else
				AddError(NStr("en='Read command confirmation error: ';ru='Ошибка получения подтверждения команды: ';de='Fehler bei der Einholung der Befehlbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
				Return RC_NO_CONNECTION;
			EndIf;
		Else
			AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	// Read command reply message
	vReadOK = False;
	pDLSys.Timeout = pReadTimeout;
	For i = 1 To 3 Do
		pReply = "";
		If pDLSys.Read(pReply, 1024) <> -1 Then
			If Not IsBlankString(pReply) Then
				// Check LRC
				pReply = StrReplace(pReply, STX, "");
				If cmCheckCharLRC(pReply) Then
					If pDLSys.Write(ACK, 1) <> -1 Then
						vReadOK = True;
						Break;
					Else
						AddError(NStr("en='Write command reply confirmation error: ';ru='Ошибка отправки подтверждения чтения ответа: ';de='Fehler beim Versenden der Lesebestätigung der Antwort: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
						Return RC_NO_CONNECTION;
					EndIf;
				Else
					pDLSys.Write(NAK, 1);
					pDLSys.Timeout = 3;
				EndIf;
			Else
				Return RC_NO_REPLY;
			EndIf;
		Else
			AddError(NStr("en='Read command reply error: ';ru='Ошибка чтения ответа на команду: ';de='Fehler beim Lesen der Antwort auf den Befehl: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	If Not vReadOK Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		// Retreive return code
		vRC = Mid(pReply, 2, 2);
		If vRC <> Left(pCommandCode, 2) Then
			AddError(NStr("ru = 'Ошибка системы эл. замков " + SystemName + ": '; 
			              |de = '" + SystemName + " system error: '; 
			              |en = '" + SystemName + " system error: '") + pReply + " <- " + vCmd);
			vErrorCode = GetErrorCode(vRC);
		Else
			// Retreive reply data
			vPrefixLen = StrLen(SEP + pCommandCode + SEP + vEncoderNumber);
			If StrLen(pReply) > vPrefixLen Then
				pReply = Mid(pReply, vPrefixLen+1, StrLen(pReply) - vPrefixLen);
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pEncoderNumber, pDta)
	// Define command code
	vCommandCode = "CN";
	If NumberOfKeys > 1 Then
		vCommandCode = vCommandCode + Format(NumberOfKeys, "ND=1; NFD=0; NG=");
	EndIf;	
	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, vCommandCode, pDta, "", vReply);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, vCommandCode, pDta, "", vReply);
	EndIf;
	Return vErrorCode;
EndFunction //  MakeNewKey

// -----------------------------------------------------------------------------
Function AddKey(pDLSys, pEncoderNumber, pDta)
	// Define command code
	vCommandCode = "CC";
	If NumberOfKeys > 1 Then
		vCommandCode = vCommandCode + Format(NumberOfKeys, "ND=1; NFD=0; NG=");
	EndIf;	
	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, vCommandCode, pDta, "", vReply);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, vCommandCode, pDta, "", vReply);
	EndIf;
	Return vErrorCode;
EndFunction //  AddKey

// -----------------------------------------------------------------------------
Function GetNextWord(pStr, pDelimeter="")
	If pDelimeter = "" Then
		pDelimeter = SEP;
	EndIf;
	vWord = "";
	vPos = Find(pStr, pDelimeter);
	If vPos > 0 Then
		vWord = Left(pStr, vPos-1);
		pStr = TrimL(Right(pStr, StrLen(pStr) - vPos));
	Else
		vWord = TrimL(pStr);
		pStr = "";
	EndIf;
	Return vWord;
EndFunction //  GetNextWord

// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc)
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", "");
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("IsCardValidCode", "");
	vCardData.Insert("IsCardValidDescription", "");
	vCardData.Insert("CardCopyNumber", "");
	vCardData.Insert("AssignedAuthorizations", "");
	vCardData.Insert("CardCheckInDate", '00010101');
	vCardData.Insert("CardCheckOutDate", '00010101');
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", "");
	vCardData.Insert("CardFullName", "");
	
	If pCardDesc = "" Then
		Return vCardData;
	EndIf;
	vCardData.CardID = pCardDesc;
	IdentificationCard = Catalogs.IdentificationCards.FindByAttribute("Identifier", pCardDesc);
	If ValueIsFilled(IdentificationCard) Then
		If  ValueIsFilled(IdentificationCard.Client) Then
			vCardData.CardFullName = IdentificationCard.Client.FullName;
		EndIf;
		vCardData.CardRoom 			= IdentificationCard.Room;
		vCardData.CardCheckInDate 	= IdentificationCard.DateTimeFrom;
		vCardData.CardCheckOutDate 	= IdentificationCard.DateTimeTo;
		vCardData.CardOperator 		= IdentificationCard.Author;
		If IdentificationCard.IsBlocked Or vCardData.IsCheckedOut Then
			vCardData.IsCardValidDescription = NStr("en='Card has been canceled by check out or other card!';ru='Гость выехал или карта отменена другой картой!';de='Der Gast ist abgereist oder die Karte wurde durch eine andere ersetzt!'");
		Else
			vCardData.IsCardValidDescription = NStr("en='Card is valid!';ru='Действующая карта!';de='Gültige Karte!'");
		EndIf;
	EndIf;
	
	Return vCardData;
EndFunction //  pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pEncoderNumber, pID)
	vErrorCode = RC_OK;
	pCardDesc = "";
	vReply = "";
	// Retention or ejection of the card
	vRetention = "";
	// Define command
	vCommandCode = "LTE";
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Send command using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, vCommandCode, "", vRetention, vReply);
	Else
		// Send command using TCP interface
		vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, vCommandCode, "", vRetention, vReply);
	EndIf;
	// Retrieve card data
	If vErrorCode = RC_OK Then
		// Read card data
		vCardDesc = Right(vReply, StrLen(vReply) - 1);
		// Card ID
		vCardDesc = GetNextWord(vCardDesc);
		pID = vCardDesc;
	EndIf;
	Return vErrorCode;
EndFunction //  Verify

// -----------------------------------------------------------------------------
Function CancelKeys(pDLSys, pEncoderNumber, pDta)
	// Define command code
	vCommandCode = "CO";
	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, vCommandCode, pDta, "", vReply);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, vCommandCode, pDta, "", vReply);
	EndIf;
	Return vErrorCode;
EndFunction //  CancelKeys

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
SEP = Char(1110); // It will be converted from Char(1110) in UTF-8 to Char(179) in CP-437 (Win-1251, etc...)
ENQ = Char(5);
ACK = Char(6);
NAK = Char(15);
STX = Char(2);
ETX = Char(3);
DLE = Char(16);

// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();

#EndRegion
