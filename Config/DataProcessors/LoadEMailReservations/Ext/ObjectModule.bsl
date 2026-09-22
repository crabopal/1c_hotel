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
	If Not ValueIsFilled(ReservationStatus) And ValueIsFilled(Hotel) Then
		ReservationStatus = Hotel.NewReservationStatus;
	EndIf;
	If InternetMailPOP3Port = 0 Then
		InternetMailPOP3Port = 110;
	EndIf;
	If InternetMailTimeout = 0 Then
		InternetMailTimeout = 60;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Do data exchange
	pmLoadEMails(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure ParseAndLoadReservation(pMessage)
	// Try to find message text part with XML data
	vXMLResDataText = "";
	For Each vMessageText In pMessage.Texts Do
		vStartPos = Find(vMessageText.Text, "<WriteExternalReservation>");
		vEndPos = Find(vMessageText.Text, "</WriteExternalReservation>");
		If vStartPos > 0 And vEndPos > 0 And vEndPos > vStartPos Then
			// First try to find XML header with text encoding like <?xml version="1.0" encoding="windows-1251"?>
			vXMLHeaderStartPos = Find(Left(vMessageText.Text, vStartPos), "<?xml version=");
			If vXMLHeaderStartPos > 0 Then
				vStartPos = vXMLHeaderStartPos;
			EndIf;
			// Retrieve message text block
			vXMLResDataText = Mid(vMessageText.Text, vStartPos, vEndPos + 26);
			Break;
		EndIf;
	EndDo;
	If Not IsBlankString(vXMLResDataText) Then
		// Initialize write external reservation API parameters
		vReservationCode = "";
		vGroupCode = 0;
		vGroupDescription = "";
		vGroupCustomer = "";
		vReservationStatus = "";
		vPeriodFrom = '00010101';
		vPeriodTo = '00010101';
		vHotel = "";
		vRoomType = "";
		vAccommodationType = "";
		vClientType = "";
		vRoomQuota = "";
		vRoomRate = "";
		vCustomer = "";
		vContract = "";
		vAgent = "";
		vContactPerson = "";
		vNumberOfRooms = 0;
		vNumberOfPersons = 0;
		vClientCode = "";
		vClientLastName = "";
		vClientFirstName = "";
		vClientSecondName = "";
		vClientSex = "";
		vClientCitizenship = "";
		vClientBirthDate = "";
		vClientPhone = "";
		vClientFax = "";
		vClientEMail = "";
		vClientRemarks = "";
		vReservationRemarks = "";
		vCar = "";
		vPlannedPaymentMethod = "";
		vExternalSystemCode = TrimAll(ExternalSystemCode);
		// Try to parse reservation data XML
		vXMLReader = New XMLReader();
		vXMLReadParams = New XMLReaderSettings(, , XMLSpace.Preserve, , False, , , , , True);
		vXMLReader.SetString(vXMLResDataText, vXMLReadParams);
		vInElement = False;
		vElementName = "";
		While vXMLReader.Read() Do
			If Not IsBlankString(vXMLReader.Name) And vXMLReader.NodeType = XMLNodeType.StartElement Then
				vElementName = TrimAll(vXMLReader.Name);
				vInElement = True;
				Continue;
			ElsIf Not IsBlankString(vXMLReader.Name) And vXMLReader.NodeType = XMLNodeType.EndElement Then
				vInElement = False;
				Continue;
			ElsIf Not vInElement Or vXMLReader.NodeType <> XMLNodeType.Text Then
				Continue;
			EndIf;
			If vElementName = "ReservationCode" Then
				vReservationCode = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "GroupCode" Then
				vGroupCode = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "GroupDescription" Then
				vGroupDescription = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "GroupCustomer" Then
				vGroupCustomer = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ReservationStatus" Then
				vReservationStatus = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "PeriodFrom" Then
				If Not IsBlankString(vXMLReader.Value) Then
					vDtStr = TrimAll(vXMLReader.Value);
					vPeriodFrom = Date(Number(Left(vDtStr, 4)), Number(Mid(vDtStr, 6, 2)), Number(Mid(vDtStr, 9, 2)), Number(Mid(vDtStr, 12, 2)), Number(Mid(vDtStr, 15, 2)), 1);
				EndIf;
			ElsIf vElementName = "PeriodTo" Then
				If Not IsBlankString(vXMLReader.Value) Then
					vDtStr = TrimAll(vXMLReader.Value);
					vPeriodTo = Date(Number(Left(vDtStr, 4)), Number(Mid(vDtStr, 6, 2)), Number(Mid(vDtStr, 9, 2)), Number(Mid(vDtStr, 12, 2)), Number(Mid(vDtStr, 15, 2)), 0);
				EndIf;
			ElsIf vElementName = "Hotel" Then
				vHotel = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "RoomType" Then
				vRoomType = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "AccommodationType" Then
				vAccommodationType = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ClientType" Then
				vClientType = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "RoomQuota" Then
				vRoomQuota = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "RoomRate" Then
				vRoomRate = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "Customer" Then
				vCustomer = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "Contract" Then
				vContract = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "Agent" Then
				vAgent = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ContactPerson" Then
				vContactPerson = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "NumberOfRooms" Then
				If Not IsBlankString(vXMLReader.Value) Then
					vNumberOfRooms = Number(TrimAll(vXMLReader.Value));
				EndIf;
			ElsIf vElementName = "NumberOfPersons" Then
				If Not IsBlankString(vXMLReader.Value) Then
					vNumberOfPersons = Number(TrimAll(vXMLReader.Value));
				EndIf;
			ElsIf vElementName = "ClientCode" Then
				vClientCode = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ClientLastName" Then
				vClientLastName = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ClientFirstName" Then
				vClientFirstName = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ClientSecondName" Then
				vClientSecondName = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ClientSex" Then
				vClientSex = Upper(Left(TrimAll(vXMLReader.Value), 1));
			ElsIf vElementName = "ClientCitizenship" Then
				vClientCitizenship = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ClientBirthDate" Then
				If Not IsBlankString(vXMLReader.Value) Then
					vDtStr = TrimAll(vXMLReader.Value);
					vClientBirthDate = Date(Number(Left(vDtStr, 4)), Number(Mid(vDtStr, 6, 2)), Number(Mid(vDtStr, 9, 2)));
				EndIf;
			ElsIf vElementName = "ClientPhone" Then
				vClientPhone = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ClientFax" Then
				vClientFax = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ClientEMail" Then
				vClientEMail = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ClientRemarks" Then
				vClientRemarks = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ReservationRemarks" Then
				vReservationRemarks = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "Car" Then
				vCar = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "PlannedPaymentMethod" Then
				vPlannedPaymentMethod = TrimAll(vXMLReader.Value);
			ElsIf vElementName = "ExternalSystemCode" Then
				If Not IsBlankString(vXMLReader.Value) Then
					vExternalSystemCode = TrimAll(vXMLReader.Value);
				EndIf;
			EndIf;
		EndDo;
		vXMLReader.Close();
		// Call API to create new reservation
		cmWriteExternalReservation(vReservationCode, vGroupCode, vGroupDescription, 
	                               vGroupCustomer, vReservationStatus, vPeriodFrom, vPeriodTo, 
	                               vHotel, vRoomType, vAccommodationType, vClientType, vRoomQuota, 
	                               vRoomRate, vCustomer, vContract, vAgent, vContactPerson, 
	                               vNumberOfRooms, vNumberOfPersons, vClientCode, 
	                               vClientLastName, vClientFirstName, vClientSecondName, 
	                               vClientSex, vClientCitizenship, vClientBirthDate, 
	                               vClientPhone, vClientFax, vClientEMail, 
	                               vClientRemarks, , vReservationRemarks, vCar, 
	                               vPlannedPaymentMethod, vExternalSystemCode, False, , "XDTO");
	Else
		WriteLogEvent(NStr("en='DataProcessor.LoadEMailReservations';ru='Обработка.ЗагрузкаEMailСообщенийСДаннымиБрони';de='DataProcessor.LoadEMailReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Message text part with new reservation data was not found!';ru='Не найдена часть письма содержащая XML данные новой брони!';de='Der Teil des Schreibens mit XML-Daten der neuen Reservierung wurde nicht gefunden!'"));
	EndIf;
EndProcedure // ParseAndLoadReservation

// -----------------------------------------------------------------------------
Procedure pmLoadEMails(pIsInteractive = False) Export
	// Log processing start
	WriteLogEvent(NStr("en='DataProcessor.LoadEMailReservations';ru='Обработка.ЗагрузкаEMailСообщенийСДаннымиБрони';de='DataProcessor.LoadEMailReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	
	// Check parameters
	If Not ValueIsFilled(Hotel) Then
		vMessage = NStr("ru='Не указана гостиница!';de='Das Hotel ist nicht angegeben!';en = 'Hotel is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadEMailReservations';ru='Обработка.ЗагрузкаEMailСообщенийСДаннымиБрони';de='DataProcessor.LoadEMailReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If IsBlankString(EMail) Then
		vMessage = NStr("ru='Не указан адрес электронной почты с которого получать сообщения с данными брони!';de='Die E-Mail-Adresse ist nicht angegeben, von der die Mitteilungen mit Reservierungsdaten empfangen werden sollen!';en='E-mail address to receive reservations from is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadEMailReservations';ru='Обработка.ЗагрузкаEMailСообщенийСДаннымиБрони';de='DataProcessor.LoadEMailReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If IsBlankString(InternetMailPOP3ServerAddress) Then
		vMessage = NStr("ru='Не указан адрес сервера электронной почты с которого получать сообщения с данными брони!';de='Die Adresse des E-Mail-Servers ist nicht angegeben, von dem die Mitteilungen mit Reservierungsdaten empfangen werden sollen!';en='POP3 server address to receive reservations from is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadEMailReservations';ru='Обработка.ЗагрузкаEMailСообщенийСДаннымиБрони';de='DataProcessor.LoadEMailReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If IsBlankString(InternetMailPOP3Authentication) Then
		vMessage = NStr("ru='Не указан тип аутентификации на сервере электронной почты!';de='Der Authentifizierungsweg auf dem E-Mai-Server ist nicht angegeben!';en='POP3 server authentication type is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadEMailReservations';ru='Обработка.ЗагрузкаEMailСообщенийСДаннымиБрони';de='DataProcessor.LoadEMailReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If IsBlankString(InternetMailUser) Then
		vMessage = NStr("ru='Не указан логин на сервер электронной почты!';de='Login zum E-Mail-Server ist nicht angegeben!';en='POP3 server login is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadEMailReservations';ru='Обработка.ЗагрузкаEMailСообщенийСДаннымиБрони';de='DataProcessor.LoadEMailReservations'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	
	// Try to connect to the POP3 server
	vProfile = New InternetMailProfile();
	vProfile.POP3BeforeSMTP = False;
	vProfile.POP3ServerAddress = TrimAll(InternetMailPOP3ServerAddress);
	vProfile.POP3Port = ?(InternetMailPOP3Port = 0, 110, InternetMailPOP3Port);
	vProfile.POP3UseSSL = InternetMailPOP3UseSSL;
	vProfile.POP3SecureAuthenticationOnly = InternetMailPOP3SecureAuthenticationOnly;
	vProfile.POP3Authentication = cmGetPOP3Authentication(InternetMailPOP3Authentication);
	vProfile.User = TrimAll(InternetMailUser);
	vProfile.Password = TrimR(InternetMailPassword);
	vProfile.Timeout = ?(InternetMailTimeout = 0, 30, InternetMailTimeout);
	vInternetMail = New InternetMail;
	vInternetMail.Logon(vProfile);
	
	// Receive new E-mails
	vNewMessages = vInternetMail.Get(True);
	If vNewMessages.Count() > 0 Then
		For Each vNewMessage In vNewMessages Do
			ParseAndLoadReservation(vNewMessage);
		EndDo;
	Else
		WriteLogEvent(NStr("en='DataProcessor.LoadEMailReservations';ru='Обработка.ЗагрузкаEMailСообщенийСДаннымиБрони';de='DataProcessor.LoadEMailReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='No new e-mails!';ru='Нет новых сообщений!';de='Es gibt keine neuen Mitteilungen!'"));
	EndIf;
	
	// Logoff from the mail server 
	vInternetMail.Logoff();
	
	// Log end of processing
	WriteLogEvent(NStr("en='DataProcessor.LoadEMailReservations';ru='Обработка.ЗагрузкаEMailСообщенийСДаннымиБрони';de='DataProcessor.LoadEMailReservations'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmLoadEMails
