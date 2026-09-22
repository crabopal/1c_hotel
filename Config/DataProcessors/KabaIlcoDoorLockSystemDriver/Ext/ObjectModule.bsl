
#Region Variables

Var SEP;
Var ENQ;
Var ACK;
Var NAK;
Var STX;
Var ETX;
Var DLE;
Var DC1;
Var SOF;

// -----------------------------------------------------------------------------
Var RC_NO_CONNECTION Export; // No connection
Var RC_OK Export; // OK
Var RC_UNKNOWN Export; // Unknown
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_NO_REPLY Export; // No reply
Var RC_WRONG_REPLY Export; // Wrong reply
Var RC_SYNTAX_ERROR Export; // Syntax error
Var RC_WRONG_ENCODER_NUMBER Export; // Wrong encoder number
Var RC_WRONG_SOURCE_ADDRESS Export; // Wrong source address
Var RC_DEVICE_IS_BUSY Export; // Device is busy
Var RC_VALUE_INVALID Export; // Value invalid
Var RC_ROOM_IS_MISSING Export; // Room is missing
Var RC_ENCODER_ERROR Export; // Encoder error
Var RC_TOO_MUCH_DATA Export; // To much data
Var RC_WRONG_ROOM Export;   // Wrong room
Var RC_INVALID_AUTH Export; // Invalid auth
Var RC_DEVICE_TIME_OUT Export; // Device time out
Var RC_DATE_OUT_OF_RANGE Export; // Date out of range
Var RC_INVALID_EXPIRY_DATE Export; // Invalid expiry date
Var RC_NO_INNER_DOORS Export; // No inner doors
Var RC_CARD_SWYPE_ERROR Export; // Card swype error
Var RC_NO_FOLIO_NUMBER Export;  // No foilo number
Var RC_OPERATION_ABORTED Export; // Operation aborted
Var RC_FUNCTION_NOT_ENABLED Export; // Function not enabled
Var RC_DEVICE_NOT_RESPONDING Export; // Device not responding
Var RC_COMMUNICATION_FAILURE Export; // Communication failure

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
	// Room
	vDta = """" + vRoomCode + SEP;
	// Number of key cards
	If NumberOfKeys > 1 Then
		vDta = vDta + "&" + Format(NumberOfKeys, "ND=3; NFD=0; NG=") + SEP;
	Else
		vDta = vDta + "&1" + SEP;
	EndIf;	
	// Key card type - new key card
	vDta = vDta + "%0" + SEP;
	// Check in and check out dates
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + "$" + Format(vCheckOutDate, "DF='yyyy/MM/dd HH:mm'") + SEP;
	vCheckInDate = CheckInDate;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	If (vCheckInDate - CurrentSessionDate()) > 3600 Then
		vDta = vDta + "(" + Format(vCheckInDate, "DF='yyyy/MM/dd HH:mm'") + SEP;
	EndIf;
	// Guest name
	vGuestName = "";
	If ValueIsFilled(Guest) Then
		vGuestName = Left(Transliterate(TrimAll(Guest), True), 20);
	EndIf;
	If Not IsBlankString(vGuestName) Then
		vDta = vDta + " 2, " + vGuestName + SEP;
	EndIf;
	// Operators data
	vOperatorLogin = "";
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) And 
		   Not IsBlankString(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin) Then
			vOperatorLogin = Left(Transliterate(TrimAll(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin), True), 3);
		EndIf;
	EndIf;
	If Not IsBlankString(vOperatorLogin) Then
		vDta = vDta + "+" + vOperatorLogin + SEP;
	EndIf;
	// Common area
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
			vDta = vDta + ")" + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + SEP + ")" + TrimAll(DoorLockSystemParameters.AssignedAuthorizations) + SEP;
		Else
			vDta = vDta + ")" + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + SEP;
		EndIf;
	Else
		If ValueIsFilled(DoorLockSystemParameters) And Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) Then
			vDta = vDta + ")" + TrimAll(DoorLockSystemParameters.AssignedAuthorizations) + SEP;
		EndIf;
	EndIf;
	// Add track 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		// Get encoder number
		vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
		// Get source address
		vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
		
		// Call API
		vErrorCode = MakeNewKey(vDLSys, vEncoderNumber, vSourceAddress, vDta);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode));
		Else
			WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
			cmWriteKeyCardSecuritySystemEvent("NEW", "", Room, vDta, vCheckInDate, vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
		EndIf;
		
		pmDisconnect(vDLSys);
		Return vErrorCode;
	EndIf;
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
	// Room
	vDta = """" + vRoomCode + SEP;
	// Number of key cards
	If NumberOfKeys > 1 Then
		vDta = vDta + "&" + Format(NumberOfKeys, "ND=3; NFD=0; NG=") + SEP;
	Else
		vDta = vDta + "&1" + SEP;
	EndIf;	
	// Key card type - additional
	vDta = vDta + "%1" + SEP;
	// Check in and check out dates
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + "$" + Format(vCheckOutDate, "DF='yyyy/MM/dd HH:mm'") + SEP;
	vCheckInDate = CheckInDate;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	If (vCheckInDate - CurrentSessionDate()) > 3600 Then
		vDta = vDta + "(" + Format(vCheckInDate, "DF='yyyy/MM/dd HH:mm'") + SEP;
	EndIf;
	// Guest name
	vGuestName = "";
	If ValueIsFilled(Guest) Then
		vGuestName = Left(Transliterate(TrimAll(Guest), True), 20);
	EndIf;
	If Not IsBlankString(vGuestName) Then
		vDta = vDta + " 2, " + vGuestName + SEP;
	EndIf;
	// Operators data
	vOperatorLogin = "";
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) And 
		   Not IsBlankString(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin) Then
			vOperatorLogin = Left(Transliterate(TrimAll(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin), True), 3);
		EndIf;
	EndIf;
	If Not IsBlankString(vOperatorLogin) Then
		vDta = vDta + "+" + vOperatorLogin + SEP;
	EndIf;
	// Common area
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
			vDta = vDta + ")" + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + SEP + ")" + TrimAll(DoorLockSystemParameters.AssignedAuthorizations) + SEP;
		Else
			vDta = vDta + ")" + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + SEP;
		EndIf;
	Else
		If ValueIsFilled(DoorLockSystemParameters) And 
		   Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) Then
			vDta = vDta + ")" + TrimAll(DoorLockSystemParameters.AssignedAuthorizations) + SEP;
		EndIf;
	EndIf;
	// Add track 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		// Get encoder number
		vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
		// Get source address
		vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
		
		// Call API
		vErrorCode = AddKey(vDLSys, vEncoderNumber, vSourceAddress, vDta);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode));
		Else
			WriteLogEvent(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
			cmWriteKeyCardSecuritySystemEvent("ADD", "", Room, vDta, vCheckInDate, vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
		EndIf;
		
		pmDisconnect(vDLSys);
		Return vErrorCode;
	EndIf;
EndFunction //  pmAddKey

// ----------------------------------------------------------------------------- 
//
// Parameters:
//  pHotel					 - CatalogRef.Hotels	 - Ref
//  pAssignedAuthorizations	 - CatalogRef.AssignedAuthorizations	 - Assigned authorizations
// 
// Returns:
//  CatalogRef.DoorLockSystemAuthorizations - Item ref 
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
	pCardData = InitializeCardDataStructure();
	
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
	
	// Call API
	vCardDesc = "";
	vErrorCode = Verify(vDLSys, vEncoderNumber, vSourceAddress, vCardDesc);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode));
	Else
		// Parse returned data
		pmParseCardDescription(vCardDesc, pCardData);
		
		// Guest client name from the client identification card
		If ValueIsFilled(DoorLockSystemParameters) And DoorLockSystemParameters.WriteTrack2 Then
			vIDCardRef = Catalogs.IdentificationCards.FindByAttribute("Identifier", pCardData.CardID);
			If ValueIsFilled(vIDCardRef) And ValueIsFilled(vIDCardRef.Client) Then
				pCardData.CardFullName = vIDCardRef.Client.FullName;
			EndIf;
		EndIf;
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys);
	
	Return vErrorCode;
EndFunction //  pmVerify

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
		Return(NStr("en='Unknown error! See error log for details.';ru='Неизвестная ошибка! Дополнительная информация сохранена в системном логе.';de='Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en='The reader/writer has been waiting too long for a card!';ru='Закончилось время ожидания карты энкодером!';de='Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + SystemName + " не отвечает!'; 
		            |de = '" + SystemName + " system is not responding!'; 
		            |en = '" + SystemName + " system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + SystemName + " получен ответ в неизвестном формате!'; 
		            |de = '" + SystemName + " system replied with unknown format!'; 
		            |en = '" + SystemName + " system replied with unknown format!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_FOLIO_NUMBER Then
		Return(NStr("en='No folio # found on keycard. Read keycard reply';ru='№ лицевого счета на карте не записан!';de='Die Personenkontonummer ist nicht auf der Karte gespeichert!'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_SYNTAX_ERROR Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = RC_DEVICE_IS_BUSY Then
		Return(NStr("en='The encoder has not already accomplished the previous task!';ru='Энкодер не закончил выполнение предыдущего задания!';de='Encoder hat die vorhergehende Aufgabe nicht beendet!'"));
	ElsIf pRC = RC_WRONG_ENCODER_NUMBER Then
		Return(NStr("en='Encoder address should be empty or in range from 01 to 24!';ru='Номер (адрес) энкодера должен быть пустой или в диапазоне от 01 до 24!';de='Nummer (Adresse) des Encoders muss leer sein oder im Bereich von 01 bis 24 liegen!'"));
	ElsIf pRC = RC_WRONG_SOURCE_ADDRESS Then
		Return(NStr("en='Workstation address should be empty or in range from 00 to 64!';ru='Номер (адрес) рабочей станции должен быть пустой или в диапазоне от 00 до 64!';de='Nummer (Adresse) der Arbeitsstation muss leer sein oder sich im Bereich von 00 bis 64 liegen!'"));
	ElsIf pRC = RC_VALUE_INVALID Then
		Return(NStr("en='Illegal Field Type! Value invalid, out of range';ru='Неверный тип поля! Значение указано неверно или находится вне разрешенного диапазона';de='Falscher Feldtyp! Der Wert ist falsch angegeben oder befindet sich außerhalb des zugelassenen Bereichs'"));
	ElsIf pRC = RC_ROOM_IS_MISSING Then
		Return(NStr("en='Room number was not specified in the command!';ru='Неверный тип поля! Значение указано неверно или находится вне разрешенного диапазона';de='Falscher Feldtyp! Der Wert ist falsch angegeben oder befindet sich außerhalb des zugelassenen Bereichs'"));
	ElsIf pRC = RC_TOO_MUCH_DATA Then
		Return(NStr("ru = 'Display line data > 20 characters!'; 
		            |de = 'Display line data > 20 characters!'; 
		            |en = 'Display line data > 20 characters!'"));
	ElsIf pRC = RC_ENCODER_ERROR Then
		Return(NStr("en='Encoder error!';ru='Ошибка энкодера!';de='Encoderfehler!'"));
	ElsIf pRC = RC_INVALID_AUTH Then
		Return(NStr("en='Authorization # not between 1-120 or 161-200!';ru='Авторизационный код не в диапазонах 1-120 или 161-200!';de='Der Autorisierungscode liegt nicht in den Bereichen 1-120 oder 161-200!'"));
	ElsIf pRC = RC_DATE_OUT_OF_RANGE Then
		Return(NStr("en='Pre-reg. Date Out of Range or Date > Expiry Date or Date < Creation Date!';ru='Pre-reg. Неверная дата или Дата > Дата окончания ключа или Дата < Дата создания!';de='Pre-reg. Falsches Datum oder Datum > Enddatum des Schlüssels oder Datum < Erstellungsdatum!'"));
	ElsIf pRC = RC_INVALID_EXPIRY_DATE Then
		Return(NStr("en='Expiry date is invalid or less than creation date!';ru='Дата окончания действия ключа меньше чем дата выдачи или указана неверно!';de='Das Datum des Schlüsselgültigkeitsendes liegt vor dem Datum der Schlüsselausgabe oder wurde falsch angegeben!'"));
	ElsIf pRC = RC_NO_INNER_DOORS Then
		Return(NStr("en='No inner door(s) specified for a common door!';ru='Для общей двери не указано ни одной внутренней двери!';de='Für die allgemeine Tür ist keine innere Tür angegeben!'"));
	ElsIf pRC = RC_CARD_SWYPE_ERROR Then
		Return(NStr("en='Card swipe error or invalid guest keycard!';ru='Ошибка чтения карты или вставлена не гостевая карта!';de='Fehler beim Lesen der Karte oder die eingesetzte Karte ist keine Gästekarte!'"));
	ElsIf pRC = RC_OPERATION_ABORTED Then
		Return(NStr("en='Card encoding or read was cancelled by user!';ru='Операция c картой прервана пользователем!';de='Die Operation mit der Karte wurde vom Nutzer unterbrochen!'"));
	ElsIf pRC = RC_FUNCTION_NOT_ENABLED Then
		Return(NStr("en='Keycard read back feature is not enabled!';ru='Запрошенное с карты свойство не поддерживается!';de='Die von der Karte abgefragte Eigenschaft wird nicht unterstützt!'"));
	ElsIf pRC = RC_DEVICE_NOT_RESPONDING Then
		Return(NStr("en='Encoder is not responding to command!';ru='Энкодер не отвечает на команды!';de='Encoder antwortet nicht auf Befehle!'"));
	ElsIf pRC = RC_COMMUNICATION_FAILURE Then
		Return(NStr("en='Gateway interface to FDU failure!';ru='Нет связи между энкодером (FDU) и концентратором (gateway)!';de='Es gibt keine Verbindung zwischen dem Encoder (FDU) und dem Hub (Gateway)!'"));
	EndIf;		
EndFunction //  pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function Transliterate(Val pStr, pAlways = False)
	If pAlways = Undefined Then
		pAlways = False;
	EndIf;
	vStr = Upper(pStr);
	If DoorLockSystemParameters.DoGuestNamesTransliteration Or pAlways Then
		vStr = StrReplace(vStr, "А", "A");
		vStr = StrReplace(vStr, "Б", "B");
		vStr = StrReplace(vStr, "В", "V");
		vStr = StrReplace(vStr, "Г", "G");
		vStr = StrReplace(vStr, "Д", "D");
		vStr = StrReplace(vStr, "Е", "E");
		vStr = StrReplace(vStr, "Ё", "E");
		vStr = StrReplace(vStr, "Ж", "GH");
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
		vStr = StrReplace(vStr, "Ч", "CH");
		vStr = StrReplace(vStr, "Ш", "SH");
		vStr = StrReplace(vStr, "Щ", "SCH");
		vStr = StrReplace(vStr, "Ь", "");
		vStr = StrReplace(vStr, "Ы", "YI");
		vStr = StrReplace(vStr, "Ъ", "");
		vStr = StrReplace(vStr, "Э", "E");
		vStr = StrReplace(vStr, "Ю", "YU");
		vStr = StrReplace(vStr, "Я", "YA");
	EndIf;
	Return vStr;
EndFunction //  Transliterate

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure //  AddError

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString()
	vStr = ""; // "19200,N,8,1" by default
	// Baudrate
	If DoorLockSystemParameters.BaudRate > 0 Then
		vStr = vStr + Format(DoorLockSystemParameters.BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "19200";
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
	// No flow control
	// Return
	Return vStr;		
EndFunction //  GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function RS232Acknowledgement(pDLSys)
	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.WriteStr(ENQ);
	If vBytesSent = 1 Then
		pDLSys.TimeoutReadTotalConstant = 2000;
		vReply = pDLSys.ReadStr();
		If vReply = ACK Then
			Return True;
		ElsIf vReply = NAK Then
			AddError(NStr("en='NAK received on acknowledgement!';ru='При подтверждении связи получен NAK!';de='Bei der Bestätigung der Verbindung NAK erhalten!'"));
		Else
			AddError(NStr("en='Wrong reply received on acknowledgement: ';ru='При подтверждении связи получен символ: ';de='Bei der Bestätigung der Verbindung Symbol erhalten: '") + vReply);
		EndIf;
	Else
		AddError(NStr("en='Wrong number of bytes sent on acknowledgement: ';ru='При подтверждении связи отправлено байт: ';de='Bei der Bestätigung der Verbindung Byte versendet: '") + vBytesSent);
	EndIf;
	Return False;
EndFunction //  RS232Acknowledgement

// -----------------------------------------------------------------------------
Function TCPAcknowledgement(pDLSys)
	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.Write(ENQ, 1);
	If vBytesSent <> -1 Then
		pDLSys.Timeout = 2;
		vReply = "";
		If pDLSys.Read(vReply, 1) <> -1 Then
			If vReply = ACK Then
				Return True;
			ElsIf vReply = NAK Then
				AddError(NStr("en='NAK received on acknowledgement!';ru='При подтверждении связи получен NAK!';de='Bei der Bestätigung der Verbindung NAK erhalten!'"));
			Else
				AddError(NStr("en='Wrong reply received on acknowledgement: ';ru='При подтверждении связи получен символ: ';de='Bei der Bestätigung der Verbindung Symbol erhalten: '") + vReply);
			EndIf;
		Else
			AddError(NStr("en='Acknowledgement error: ';ru='Ошибка подтверждения связи: ';de='Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		EndIf;
	Else
		AddError(NStr("en='Acknowledgement error: ';ru='Ошибка подтверждения связи: ';de='Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
	EndIf;
	Return False;
EndFunction //  TCPAcknowledgement

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "Kaba Ilco";
	
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
				AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden: '") + TrimAll(DoorLockSystemParameters.Port));
				Return Undefined;
			EndIf;
			// Set block mode
			vDLSys.BlockMode = True;
			// Setup timeouts
			vDLSys.TimeoutReadInterval = 1000;
			vDLSys.TimeoutReadTotalConstant = 2000;
			vDLSys.TimeoutReadTotalMultiplier = 100;
			vDLSys.TimeoutWriteTotalConstant = 2000;
			vDLSys.TimeoutWriteTotalMultiplier = 100;
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
				AddError(NStr("en='SocketTools.SocketWrench component initialization error: ';ru='Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: ';de='Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '") + vErrorCode);
				Return Undefined;
			EndIf;     
			vDLSys.Blocking = True;
			vDLSys.Timeout = 60; // 60 seconds blocking read timeout by default
			vErrorCode = vDLSys.Connect(TrimAll(DoorLockSystemParameters.ServerName), Number(?(IsBlankString(DoorLockSystemParameters.Port), "10001", TrimAll(DoorLockSystemParameters.Port))));
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Не найден сервер системы электронных замков " + SystemName + ": '; en = '" + SystemName + " system server was not found: '; de = '" + SystemName + " system server was not found: '") + vErrorCode);
				Return Undefined;
			EndIf;     
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
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
				AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + SystemName + ": '; en = '" + SystemName + " server disconnect error: '; de = '" + SystemName + " server disconnect error: '") + vErrorCode);
				Return;
			EndIf;  
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system disconnect error: '; de = '" + SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
Function AddTrack2(pDLSys, pDta)
	If DoorLockSystemParameters.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(Folio) Then
			vIDCardRef = cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, False);
			If ValueIsFilled(vIDCardRef) Then
				// Update card identifier
				If Left(vIDCardRef.Identifier, 1) = "0" Then
					vIDCardObj = vIDCardRef.GetObject();
					vIDCardObj.Identifier = "1" + Mid(vIDCardObj.Identifier, 2);
					vIDCardObj.Write();
					vIDCardRef = vIDCardObj.Ref;
				EndIf;
				// Save identification card number
				IdentificationCard = vIDCardRef;
				// Track 2 data: CardIdentifier
				vTrack2 = TrimAll(vIDCardRef.Identifier);
				pDta = pDta + "F202" + Left(vTrack2, 14) + SEP;
			Else
				vErrorCode = RC_NO_ID_CARD;
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode));
				pmDisconnect(pDLSys);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = RC_NO_FOLIO;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode));
			pmDisconnect(pDLSys);
			Return vErrorCode;
		EndIf;
	EndIf;
	Return RC_OK;
EndFunction //  AddTrack2	

// -----------------------------------------------------------------------------
Function GetErrorCode(pRC)
	vErrorCode = RC_UNKNOWN;
	If pRC = "Q" Then
		vErrorCode = RC_SYNTAX_ERROR;
	ElsIf pRC = "R" Then
		vErrorCode = RC_VALUE_INVALID;
	ElsIf pRC = "S" Then
		vErrorCode = RC_ENCODER_ERROR;
	ElsIf pRC = "U" Then
		vErrorCode = RC_ROOM_IS_MISSING;
	ElsIf pRC = "V" Then
		vErrorCode = RC_TOO_MUCH_DATA;
	ElsIf pRC = "W" Then
		vErrorCode = RC_WRONG_ROOM;
	ElsIf pRC = "X" Then
		vErrorCode = RC_INVALID_AUTH;
	ElsIf pRC = "Y" Then
		vErrorCode = RC_DEVICE_TIME_OUT;
	ElsIf pRC = "Z" Then
		vErrorCode = RC_DATE_OUT_OF_RANGE;
	ElsIf pRC = "[" Then
		vErrorCode = RC_DATE_OUT_OF_RANGE;
	ElsIf pRC = "\" Then
		vErrorCode = RC_DATE_OUT_OF_RANGE;
	ElsIf pRC = "]" Then
		vErrorCode = RC_NO_INNER_DOORS;
	ElsIf pRC = "^" Then
		vErrorCode = RC_INVALID_EXPIRY_DATE;
	ElsIf pRC = "_" Then
		vErrorCode = RC_CARD_SWYPE_ERROR;
	ElsIf pRC = "'" Then
		vErrorCode = RC_NO_FOLIO_NUMBER;
	ElsIf pRC = "a" Then
		vErrorCode = RC_OPERATION_ABORTED;
	ElsIf pRC = "d" Then
		vErrorCode = RC_WRONG_ROOM;
	ElsIf pRC = "h" Then
		vErrorCode = RC_FUNCTION_NOT_ENABLED;
	ElsIf pRC = "p" Then
		vErrorCode = RC_WRONG_ENCODER_NUMBER;
	ElsIf pRC = "q" Then
		vErrorCode = RC_DEVICE_IS_BUSY;
	ElsIf pRC = "t" Then
		vErrorCode = RC_DEVICE_NOT_RESPONDING;
	ElsIf pRC = "u" Then
		vErrorCode = RC_COMMUNICATION_FAILURE;
	EndIf;
	Return vErrorCode;
EndFunction //  GetErrorCode

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pReadTimeout = 60000, pEncoderNumber, pSourceAddress, pCommandCode, pDta, pReply)
	vErrorCode = RC_OK;
	pReply = "";
	// Format encoder number and source address
	vEncoderNumber = TrimAll(pEncoderNumber);
	If Not IsBlankString(vEncoderNumber) Then
		If vEncoderNumber < "01" Or vEncoderNumber > "24" Or StrLen(vEncoderNumber) <> 2 Then
			Return RC_WRONG_ENCODER_NUMBER;
		EndIf;
	EndIf;
	vSourceAddress = TrimAll(pSourceAddress);
	If Not IsBlankString(vSourceAddress) Then
		If vSourceAddress < "00" Or vSourceAddress > "64" Or StrLen(vSourceAddress) <> 2 Then
			Return RC_WRONG_SOURCE_ADDRESS;
		EndIf;
	EndIf;
	// Build command string for the RS232 interface
	vCmd = "";
	vMsgLength = 1;
	vShift = 2;
	// Encoder number
	If Not IsBlankString(vEncoderNumber) Then
		vCmd = vCmd + vEncoderNumber;
		vMsgLength = vMsgLength + 2;
		vShift = vShift + 2;
	EndIf;
	// Source address
	If Not IsBlankString(vSourceAddress) Then
		vCmd = vCmd + vSourceAddress;
		vMsgLength = vMsgLength + 2;
		vShift = vShift + 2;
	EndIf;
	// Command code
	vCmd = vCmd + pCommandCode;
	vMsgLength = vMsgLength + 1;
	// Message length
	vMsgLength = vMsgLength + 4 + StrLen(pDta) + 1 + 1;
	vCmd = vCmd + Format(vMsgLength, "ND=4; NFD=0; NZ=; NLZ=; NG=");
	// Command data tags
	vCmd = vCmd + pDta;
	// Command start and end chars
	vCmd = STX + vCmd + ETX;
	// Build command
	vCmd = vCmd + cmCharLRC(vCmd, False);
	// Send acknowledgement
	If Not RS232Acknowledgement(pDLSys) Then
		Return RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	pDLSys.TimeoutReadTotalConstant = 2000;
	For i = 1 To 3 Do
		vBytesSent = pDLSys.WriteStr(vCmd);
		If vBytesSent > 0 Then
			vReply = pDLSys.ReadStr();
			If vReply = ACK Then
				Break;
			Else
				If vReply = DC1 Then
					Return RC_DEVICE_IS_BUSY;
				ElsIf vReply <> NAK Then
					AddError(NStr("en='DFU Reply is: ';ru='Ответ DFU: ';de='Antwort DFU: '") + vReply);
					Return RC_WRONG_REPLY;
				EndIf;
				pDLSys.PurgeQueue();
			EndIf;
		Else
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	// Write end of transaction char
	vBytesSent = pDLSys.WriteStr(SOF);
	// Purge RS232
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
			// Skip ENQ
			If pReply = ENQ Then
				// Send ACK and wait for reply
				vBytesSent = pDLSys.WriteStr(ACK);
				pReply = pDLSys.ReadStr();
				If IsBlankString(pReply) Then
					Return RC_NO_REPLY;
				EndIf;
			EndIf;
			// Check LRC
			If cmCheckCharLRC(pReply, False) Then
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
	// Check returned data
	If Not vReadOK Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		// Retreive return code
		vCmdCode = Mid(pReply, vShift, 1);
		If vCmdCode = "4" Then
			vRC = Mid(pReply, vShift + 5, 1);
			If vRC <> "P" Then
				AddError(NStr("ru = 'Ошибка системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system error: '; de = '" + SystemName + " system error: '") + pReply + " <- " + vCmd);
				vErrorCode = GetErrorCode(vRC);
			Else
				pReply = Mid(pReply, vShift + 5);
			EndIf;
		ElsIf vCmdCode = "3" Then
			pReply = Mid(pReply, vShift + 5);
		Else
			vErrorCode = RC_WRONG_REPLY;
			// Retreive reply data
			vPrefixLen = 1;
			If StrLen(pReply) > (vPrefixLen + 1) Then
				pReply = Mid(pReply, vPrefixLen + 1, StrLen(pReply) - vPrefixLen - 1);
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  CallRS232Command

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pEncoderNumber, pSourceAddress, pCommandCode, pDta, pReply)
	vErrorCode = RC_OK;
	pReply = "";
	// Format encoder number and source address
	vEncoderNumber = TrimAll(pEncoderNumber);
	If Not IsBlankString(vEncoderNumber) Then
		If vEncoderNumber < "01" Or vEncoderNumber > "24" Or StrLen(vEncoderNumber) <> 2 Then
			Return RC_WRONG_ENCODER_NUMBER;
		EndIf;
	EndIf;
	vSourceAddress = TrimAll(pSourceAddress);
	If Not IsBlankString(vSourceAddress) Then
		If vSourceAddress < "00" Or vSourceAddress > "64" Or StrLen(vSourceAddress) <> 2 Then
			Return RC_WRONG_SOURCE_ADDRESS;
		EndIf;
	EndIf;
	// Build command string for the RS232 interface
	vCmd = "";
	vMsgLength = 1;
	vShift = 2;
	// Encoder number
	If Not IsBlankString(vEncoderNumber) Then
		vCmd = vCmd + vEncoderNumber;
		vMsgLength = vMsgLength + 2;
		vShift = vShift + 2;
	EndIf;
	// Source address
	If Not IsBlankString(vSourceAddress) Then
		vCmd = vCmd + vSourceAddress;
		vMsgLength = vMsgLength + 2;
		vShift = vShift + 2;
	EndIf;
	// Command code
	vCmd = vCmd + pCommandCode;
	vMsgLength = vMsgLength + 1;
	// Message length
	vMsgLength = vMsgLength + 4 + StrLen(pDta) + 1 + 1;
	vCmd = vCmd + Format(vMsgLength, "ND=4; NFD=0; NZ=; NLZ=; NG=");
	// Command data tags
	vCmd = vCmd + pDta;
	// Command start and end chars
	vCmd = STX + vCmd + ETX;
	// Build command
	vCmd = vCmd + cmCharLRC(vCmd, False);
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
					If vReply = DC1 Then
						Return RC_DEVICE_IS_BUSY;
					ElsIf vReply <> NAK Then
						AddError(NStr("en='Reply is: ';ru='Ответ: ';de='Antwort: '") + vReply);
						Return RC_WRONG_REPLY;
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
	// Write end of transaction char
	pDLSys.Write(SOF, 1);
	// Read command reply message
	vReadOK = False;
	pDLSys.Timeout = pReadTimeout;
	For i = 1 To 3 Do
		pReply = "";
		If pDLSys.Read(pReply, 1024) <> -1 Then
			If Not IsBlankString(pReply) Then
				// Skip ENQ
				If pReply = ENQ Then
					// Send ACK and wait for reply
					pDLSys.Write(ACK, 1);
					If pDLSys.Read(pReply, 1024) <> -1 Then
						If IsBlankString(pReply) Then
							Return RC_NO_REPLY;
						EndIf;
					Else
						AddError(NStr("en='Read command reply error: ';ru='Ошибка чтения ответа на команду: ';de='Fehler beim Lesen der Antwort auf den Befehl: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
						Return RC_NO_CONNECTION;
					EndIf;
				EndIf;
				// Check LRC
				If cmCheckCharLRC(pReply, False) Then
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
	// Check returned data
	If Not vReadOK Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		// Read command code
		vCmdCode = Mid(pReply, vShift, 1);
		If vCmdCode = "4" Then
			// Retreive return code
			vRC = Mid(pReply, vShift + 5, 1);
			If vRC <> "P" Then
				AddError(NStr("ru = 'Ошибка системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system error: '; de = '" + SystemName + " system error: '") + pReply + " <- " + vCmd);
				vErrorCode = GetErrorCode(vRC);
			Else
				pReply = Mid(pReply, vShift + 5);
			EndIf;
		ElsIf vCmdCode = "3" Then
			pReply = Mid(pReply, vShift + 5);
		Else
			vErrorCode = RC_WRONG_REPLY;
			// Retreive reply data
			vPrefixLen = 1;
			If StrLen(pReply) > (vPrefixLen + 1) Then
				pReply = Mid(pReply, vPrefixLen + 1, StrLen(pReply) - vPrefixLen - 1);
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pEncoderNumber, pSourceAddress, pDta)
	// Define command code
	vCommandCode = "1";
	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, pSourceAddress, vCommandCode, pDta, vReply);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, pSourceAddress, vCommandCode, pDta, vReply);
	EndIf;
	Return vErrorCode;
EndFunction //  MakeNewKey

// -----------------------------------------------------------------------------
Function AddKey(pDLSys, pEncoderNumber, pSourceAddress, pDta)
	// Define command code
	vCommandCode = "1";
	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, pSourceAddress, vCommandCode, pDta, vReply);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, pSourceAddress, vCommandCode, pDta, vReply);
	EndIf;
	Return vErrorCode;
EndFunction //  AddKey

// -----------------------------------------------------------------------------
Function GetWord(pStr, pTag)
	vWord = "";
	If Not IsBlankString(pStr) Then
		vTagPos = Find(pStr, pTag);
		If vTagPos > 0 And vTagPos < Strlen(pStr) Then
			vStr = TrimAll(Mid(pStr, vTagPos + 1));
			vSEPPos = Find(vStr, SEP);
			If vSEPPos > 1 Then
				vWord = TrimAll(Left(vStr, vSEPPos - 1));
			ElsIf vSEPPos = 0 Then
				vWord = TrimAll(vStr);
			EndIf;
		EndIf;
	EndIf;
	Return vWord;
EndFunction //  GetWord

// -----------------------------------------------------------------------------
Function GetDate(pDateStr)
	Try
		If Not IsBlankString(pDateStr) Then
			If StrLen(pDateStr) = 16 Then
				vYear = Left(pDateStr, 4);
				vMonth = Mid(pDateStr, 6, 2);
				vDay = Mid(pDateStr, 9, 2);
				vHour = Mid(pDateStr, 12, 2);
				vMinute = Right(pDateStr, 2);
				Return Date(Number(vYear), Number(vMonth), Number(vDay), Number(vHour), Number(vMinute), 0);
			Else
				Return '00010101';
			EndIf;
		Else
			Return '00010101';
		EndIf;
	Except
		Return '00010101';
	EndTry;
EndFunction //  GetDate

// -----------------------------------------------------------------------------
Function InitializeCardDataStructure()
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("CardRoom", "");
	vCardData.Insert("IsCardValidCode", "ER");
	vCardData.Insert("IsCardValidDescription", NStr("en='Wrong card or card read error!';ru='Ошибка чтения карты или вставлена не гостевая карта!';de='Fehler beim Lesen der Karte oder die eingesetzte Karte ist keine Gästekarte!'"));
	vCardData.Insert("AssignedAuthorizations", "");
	vCardData.Insert("CardCheckOutDate", '00010101');
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", "");
	vCardData.Insert("CardFullName", "");
	Return vCardData;
EndFunction //  InitializeCardDataStructure

// -----------------------------------------------------------------------------
Procedure pmParseCardDescription(Val pCardDesc, pCardData)
	// Set status
	pCardData.IsCardValidCode = "OK";
	pCardData.IsCardValidDescription = NStr("en='Guest card is valid!';ru='Действующая гостевая карта!';de='Gültige Gastkarte!'");
	
	// Card parameters
	pCardData.CardRoom = GetWord(pCardDesc, """");
	pCardData.AssignedAuthorizations = GetWord(pCardDesc, ")");
	vAuthRef = pmFindAuthorizations(DoorLockSystemParameters.Hotel, pCardData.AssignedAuthorizations);
	If ValueIsFilled(vAuthRef) Then
		pCardData.CardAuthorizations = TrimAll(vAuthRef.Code) + " - " + TrimAll(vAuthRef.Description);
	EndIf;
	pCardData.CardCheckOutDate = GetDate(GetWord(pCardDesc, "$"));
	pCardData.CardID = GetWord(pCardDesc, ",");
EndProcedure //  pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pEncoderNumber, pSourceAddress, pCardDesc)
	vErrorCode = RC_OK;
	pCardDesc = "";
	vReply = "";
	// Define command
	vCommandCode = "2";
	// Build command data
	vDta = "@" + """" + "$" + ")" + "," + SEP;
	// Send command
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Send command using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, pSourceAddress, vCommandCode, vDta, vReply);
	Else
		// Send command using TCP interface
		vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, pSourceAddress, vCommandCode, vDta, vReply);
	EndIf;
	// Retrieve card data
	If vErrorCode = RC_OK Then
		pCardDesc = vReply;
	EndIf;
	Return vErrorCode;
EndFunction //  Verify

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
SEP = Char(28);
ENQ = Char(5);
ACK = Char(6);
NAK = Char(21);
STX = Char(2);
ETX = Char(3);
DLE = Char(16);
DC1 = Char(11);
SOF = Char(127);

// -----------------------------------------------------------------------------
RC_NO_CONNECTION = -1;
RC_OK = 0;
RC_UNKNOWN = 100;
RC_NO_FOLIO = 101;
RC_NO_ID_CARD = 102;
RC_NO_REPLY = 103;
RC_DEVICE_TIME_OUT = 111;
RC_ROOM_WITHOUT_DOOR_LOCK = 114;
RC_WRONG_REPLY = 104;
RC_WRONG_ENCODER_NUMBER = 121;
RC_WRONG_SOURCE_ADDRESS = 122;
RC_DEVICE_IS_BUSY = 123;
RC_SYNTAX_ERROR = 105;
RC_VALUE_INVALID = 124;
RC_ROOM_IS_MISSING = 125;
RC_ENCODER_ERROR = 126;
RC_TOO_MUCH_DATA = 127;
RC_WRONG_ROOM = 113;
RC_INVALID_AUTH = 128;
RC_DATE_OUT_OF_RANGE = 130;
RC_INVALID_EXPIRY_DATE = 131;
RC_NO_INNER_DOORS = 132;
RC_CARD_SWYPE_ERROR = 133;
RC_NO_FOLIO_NUMBER = 134;
RC_OPERATION_ABORTED = 135;
RC_FUNCTION_NOT_ENABLED = 136;
RC_DEVICE_NOT_RESPONDING = 138;
RC_COMMUNICATION_FAILURE = 139;

// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();

#EndRegion
