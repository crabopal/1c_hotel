
#Region Public

#Region CallAPIForSMSGateways 

// --------------------------------------------------------------------------------------------------------------
// API for SMS gateways module
// --------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------
Function SendMessage(pSMSText, pSMSReceiver, pSMSTemplate = Undefined, pSMSSender = "", pClient = Undefined, pClientDoc = Undefined, pEmployee = Undefined, pDocumentStatus = Undefined, rErrorDescription = "", rMessageID = "", rCost = 0, pDeliveryDate = "", pExternalSystem = Undefined) Export
	pSMSReceiver = StrReplace(pSMSReceiver, "+", "");
	
	rErrorDescription = "";
	rMessageID = "";
	rCost = 0;
	
	vLogin = Constants.SMSLogin.Get(); 
	vPassword = Constants.SMSPassword.Get();
	vSMSSender = "";
	If Not IsBlankString(pSMSSender) Then
		vSMSSender = TrimAll(pSMSSender);
	Else
		vSMSSender = TrimAll(Constants.SMSSenderName.Get());
	EndIf;
	If IsBlankString(vLogin) Or IsBlankString(vPassword) Then
		rErrorDescription = NStr("en='Login or password not found!';ru='Не найден логин или пароль!';de='Passwort oder Login nicht gefunden!'");
		Return False;
	ElsIf IsBlankString(vSMSSender) Then
		rErrorDescription = NStr("en='SMS sender name or phone number is empty!';ru='Не указан телефон или имя отправителя СМС!';de='Die Telefonnummer oder der Name des SMS-Absenders ist nicht angegeben!'");
		Return False;
	EndIf;
	
	vSMSGateway = GetModuleByGateway();
	If vSMSGateway <> Undefined Then
		vStruct = vSMSGateway.SendSMS(vLogin, vPassword, pSMSReceiver, pSMSText, vSMSSender, pDeliveryDate);	
	Else
		rErrorDescription = NStr("en='Unsupported SMS gateway!';ru='СМС шлюз не поддерживается!';de='SMS-Gateway wird nicht unterstützt!'");
		Return False;	
	EndIf;
 
	If Not IsBlankString(vStruct.Result) Then
		rErrorDescription = vStruct.Result;
	ElsIf Not IsBlankString(vStruct.ErrorDescription) Then
		rErrorDescription = vStruct.ErrorDescription;
	EndIf;

	If Not vStruct.Success And Not IsBlankString(rErrorDescription) Then
		Return False;
	EndIf;

	rMessageID = StrReplace(StrReplace(String(vStruct.MessageID), " ", ""), Chars.NBSp, "");
	rCost = vStruct.Cost;
	
	If Not IsBlankString(rMessageID) Then
		// Do movement
		vSMSMessagesRecordSet = InformationRegisters.SMSMessages.CreateRecordSet();
		vSMSMessagesRecordSet.Filter.MessageID.Set(rMessageID);
		vSMSMessRec = vSMSMessagesRecordSet.Add();
		vSMSMessRec.Period = CurrentSessionDate();
		vSMSMessRec.MessageID = rMessageID;
		vSMSMessRec.Result = vStruct.Result;
		vSMSMessRec.Text = pSMSText;
		vSMSMessRec.Phone = pSMSReceiver;
		vSMSMessRec.Sender = vSMSSender;
		vSMSMessRec.Quantity = vStruct.NumberOfSegments;
		vSMSMessRec.Cost = vStruct.Cost;
		vSMSMessRec.SMSTemplate = pSMSTemplate;
		vSMSMessRec.Status = "";
		If TypeOf(pClient) = Type("CatalogRef.Clients") Then
			vSMSMessRec.Client = pClient;
		ElsIf TypeOf(pClient) = Type("CatalogRef.Customers") Then
			vSMSMessRec.Customer = pClient;
		EndIf;
		vSMSMessRec.ClientDoc = pClientDoc;
		vSMSMessRec.SourceDoc = pClientDoc;
		vSMSMessRec.Employee = pEmployee;
		vSMSMessRec.DocumentStatus = pDocumentStatus;
		// Write movements
		vSMSMessagesRecordSet.Write();
		// Return
	EndIf;
	Return True;
EndFunction // SendMessage

// --------------------------------------------------------------------------------------------------------------
Function GetBalance(rErrorDescription = "") Export
	vResultStructure = New Structure("Status, Balance", "", Undefined);
	
	vLogin = Constants.SMSLogin.Get(); 
	vPassword = Constants.SMSPassword.Get();
	If IsBlankString(vLogin) Or IsBlankString(vPassword) Then
		rErrorDescription = NStr("en = 'Login or password not found!'; de = 'Passwort oder Login nicht gefunden!'; ru = 'Не найден логин или пароль!'");
		Return vResultStructure;
	EndIf;
	
	vSMSGateway = GetModuleByGateway();
	If vSMSGateway <> Undefined Then
		vResultStructure.Balance = vSMSGateway.GetBalance(vLogin, vPassword, vResultStructure.Status, rErrorDescription);
	Else
		vResultStructure.Status = "Exception";
		rErrorDescription = NStr("en = 'Unsupported SMS gateway!'; de = 'SMS-Gateway wird nicht unterstützt!'; ru = 'СМС шлюз не поддерживается!'");
		Return vResultStructure;	
	EndIf;
	
	Return vResultStructure;
EndFunction // GetBalance

// --------------------------------------------------------------------------------------------------------------
Function GetMessageStatus(pMessageID, pPhone) Export
	vResultStructure = New Structure("Status, Result, ErrorDescription", "", "", "");
	vLogin = Constants.SMSLogin.Get(); 
	vPassword = Constants.SMSPassword.Get();
	
	If IsBlankString(vLogin) Or IsBlankString(vPassword) Then
		vResultStructure.ErrorDescription = NStr("en = 'Login or password not found!'; de = 'Passwort oder Login nicht gefunden!'; ru = 'Не найден логин или пароль!'");
		Return vResultStructure;
	EndIf; 
	
	vSMSGateway = GetModuleByGateway();
	If vSMSGateway <> Undefined Then
		vStruct = vSMSGateway.GetStatus(vLogin, vPassword, pMessageID, pPhone);	
	Else
		vResultStructure.ErrorDescription = NStr("en = 'Unsupported SMS gateway!'; de = 'SMS-Gateway wird nicht unterstützt!'; ru = 'СМС шлюз не поддерживается!'");
		Return vResultStructure;	
	EndIf;
	
	If vStruct.Success Then
		vResultStructure.Status = vStruct.Status;
		If Not IsBlankString(vStruct.Result) Then
			vResultStructure.Result = vStruct.Result;
		EndIf;
	Else
		vResultStructure.Status = vStruct.Status;
		If Not IsBlankString(vStruct.Result) Then
			vResultStructure.Result = vStruct.Result;
		EndIf;
		vResultStructure.ErrorDescription = vStruct.ErrorDescription;
		If IsBlankString(vResultStructure.ErrorDescription) Then
			vResultStructure.ErrorDescription = "?";
		EndIf;
	EndIf;
    Return vResultStructure;
EndFunction // GetMessageStatus

#EndRegion 

#Region CommonAPIForSMSGateways

// --------------------------------------------------------------------------------------------------------------
// Common API for all SMS gateways
// --------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------
Function ServerResponseDescription(pResult) Export
	vServerResponses = New Map;
	// False
	vServerResponses.Insert("InvalidCredentials", 		New Structure("Text, Action", NStr("en='Error: Incorrect login or password';ru='Ошибка: Неправильный логин или пароль';de='Fehler: falsches Login oder Passwort'")));
	vServerResponses.Insert("UserDisabled", 			New Structure("Text, Action", NStr("en='Error: User is blocked';ru='Ошибка: Пользователь заблокирован';de='Fehler: der Nutzer ist blockiert'")));
	vServerResponses.Insert("Forbidden",  				New Structure("Text, Action", NStr("en='Error: this function is not allowed for the selected user';ru='Ошибка: для выбранного пользователя выполнение данной функции запрещено';de='Fehler: diese Funktion ist für den ausgewählten Benutzer nicht zulässig'")));
	vServerResponses.Insert("UserBlocked",  			New Structure("Text, Action", NStr("en='Error: IP address is blocked';ru='Ошибка: IP адрес заблокирован';de='Fehler: IP-Adresse wurde blockiert'")));
	vServerResponses.Insert("InvalidBalance", 			New Structure("Text, Action", NStr("en='Error: SMS account balance is zero';ru='Ошибка: Нулевой баланс на счете отправки СМС сообщений';de='Fehler: Nullbilanz auf dem SN`MS-Versandkonto'")));
	vServerResponses.Insert("DatabaseOffline", 			New Structure("Text, Action", NStr("en='Error: Database offline';ru='Ошибка: Проблема базы данных на стороне сервиса';de='Fehler: Datenbankproblem an der Service-Seite'")));
    vServerResponses.Insert("InvalidFlashMessage",		New Structure("Text, Action", NStr("en='Error: Incorrect flash-message';ru='Ошибка: Некорректное флэш-сообщение';de='Fehler: falsche Flash-Mitteilung'")));
	vServerResponses.Insert("InvalidSenderAddress",		New Structure("Text, Action", NStr("en='Error: Incorrect sender address';ru='Ошибка: Некорректный адрес отправителя сообщения';de='Fehler: falsche Absenderadresse'")));
	vServerResponses.Insert("InvalidReceiverAddress",   New Structure("Text, Action", NStr("en='Error: Incorrect phone number';ru='Ошибка: Некорректный номер получателя сообщения';de='Fehler: falsche Empfängeradresse'")));
	vServerResponses.Insert("InvalidDate",   			New Structure("Text, Action", NStr("en='Error: Incorrect date format';ru='Ошибка: Некорректный формат даты';de='Fehler: falsches Datumformat'")));
	vServerResponses.Insert("EmptyMessage", 			New Structure("Text, Action", NStr("en='Error: The message is blank';ru='Ошибка: Пустое сообщение';de='Fehler: leere Nachricht'")));
	vServerResponses.Insert("TooLongMessage", 			New Structure("Text, Action", NStr("en='Error: The message is too long';ru='Ошибка: Слишком длинное сообщение';de='Fehler: die Nachricht ist zu lang'")));
	vServerResponses.Insert("MessageBlocked", 			New Structure("Text, Action", NStr("en='Error: The message is blocked by anti-spam filter';ru='Ошибка: Сообщение заблокировано анти спам-фильтром';de='Fehler: die Nachricht wurde durch Antispam-Filter blockiert'")));
	vServerResponses.Insert("MessageNotFound", 			New Structure("Text, Action", NStr("en='Error: Message is not found';ru='Ошибка: Сообщение не найдено';de='Fehler: die Nachricht wurde nicht gefunden'")));
	vServerResponses.Insert("InvalidParameters", 		New Structure("Text, Action", NStr("en='Error: Wrong message parameters';ru='Ошибка: Параметры запроса неверны';de='Fehler: falsche Anfrageparameter'")));
	vServerResponses.Insert("LimitOfAttemptsReached", 	New Structure("Text, Action", NStr("en='Error: Number of attempts to send the same message limit is reached';ru='Ошибка: Превышен лимит попыток отправки одного и того же запроса';de='Fehler: die Anzahl der Versuche ein und derselben Anfrage ist überschritten'")));
	vServerResponses.Insert("Error", 					New Structure("Text, Action", NStr("en='Error: The message status check is failed or unknown error';ru='Ошибка: Проверить статус не удалось или неизвестная ошибка';de='Fehler: der Status konnte nicht geprüft werden oder unbekannter Fehler'"), -1));	
	vServerResponses.Insert("Exception", 				New Structure("Text, Action", NStr("en='Error: Program request has failed!';ru='Ошибка: Ошибка при выполнении запроса!';de='Fehler: Fehler bei der Ausführung der Anfrage!'"), -1));	

	// True
	vServerResponses.Insert("IsSent",					New Structure("Text, Action", NStr("en='The message is sent';ru='Сообщение отправлено';de='Die Mitteilung wurde versendet'"), 1));
	vServerResponses.Insert("Delivered",				New Structure("Text, Action", NStr("en='The message is delivered to subscriber';ru='Сообщение доставлено до абонента';de='Die Mitteilung wurde dem Abonnenten zugestellt'"), 1));
	vServerResponses.Insert("EnRoute", 					New Structure("Text, Action", NStr("en='The message is in progress';ru='Сообщение находится в режиме отправки';de='Die Mitteilung befindet sich im Sendemodus'"), 0));
	vServerResponses.Insert("EnQueue", 					New Structure("Text, Action", NStr("en='The message is queued';ru='Сообщение находится в очереди на отправку';de='Die Mitteilung befindet sich in der Warteschlange'"), 0));
	vServerResponses.Insert("Deleted", 					New Structure("Text, Action", NStr("en='The message is deleted';ru='Сообщение удалено';de='Die Mitteilung wurde gelöscht'"), -1));
	vServerResponses.Insert("Expired", 					New Structure("Text, Action", NStr("en='The message is not delivered';ru='Сообщение не доставлено';de='Die Mitteilung wurde nicht zugestellt'"), -1));
	vServerResponses.Insert("Rejected", 				New Structure("Text, Action", NStr("en='The message is not delivered';ru='Сообщение не доставлено';de='Die Mitteilung wurde nicht zugestellt'"), -1));
	vServerResponses.Insert("UnDeliverable", 			New Structure("Text, Action", NStr("en='The message is not delivered';ru='Сообщение не доставлено';de='Die Mitteilung wurde nicht zugestellt'"), -1));
	vServerResponses.Insert("Unknown", 					New Structure("Text, Action", NStr("en='The message is not delivered';ru='Сообщение не доставлено';de='Die Mitteilung wurde nicht zugestellt'"), -1));
	
	vServerResponses.Insert("OK", 						New Structure("Text, Action", NStr("en='Operation is completed';ru='Операция выполнена';de='Die Operation wurde ausgeführt'"), 0));	
	If vServerResponses.Get(pResult) <> Undefined Then
		vResponse = vServerResponses.Get(pResult);
	ElsIf ValueIsFilled(pResult) Then
		vResponse = New Structure("Text, Action", NStr("en = 'Error: '; de = 'Fehler: '; ru = 'Ошибка: '") + pResult);
	Else
		vResponse = New Structure("Text, Action", "");		
	EndIf;
	Return vResponse;
EndFunction // ServerResponseDescription

// --------------------------------------------------------------------------------------------------------------
Function URLEncode(pStr) Export
	Return EncodeString(pStr, StringEncodingMethod.URLInURLEncoding);
EndFunction // URLEncode

// --------------------------------------------------------------------------------------------------------------
// Convert string like x,y to the value list {x,y}
// --------------------------------------------------------------------------------------------------------------
Function Str2List(pStr) Export       
    Var vList;
	vStr = TrimAll(pStr);       
    vList = New ValueList;
    For vInd = 1 To 4 Do
        vPos = StrFind(vStr, ",");
        If vPos = 0 Then
            vList.Add(vStr);
            Break;                 
        Else
            vList.Add(Left(vStr, vPos - 1));
        EndIf;     
        vStr = Mid(vStr, vPos + 1);
    EndDo;
    Return vList;
EndFunction //  Str2List

// --------------------------------------------------------------------------------------------------------------
// Convert time in Unix DateTimeStamp to the string
// --------------------------------------------------------------------------------------------------------------
Function Unix2Date (pDateTimeStamp) Export 
    Return Date("19700101000000") + pDateTimeStamp;
EndFunction // Unix2Date

// --------------------------------------------------------------------------------------------------------------
Function GetModuleByGateway(pSMSGateway = Undefined) Export
	vSMSGateway = Constants.SMSGateway.Get();	
	If pSMSGateway <> Undefined Then
		vSMSGateway = pSMSGateway;	
	EndIf;   
	
	If Not ValueIsFilled(vSMSGateway) Then
		vSMSGateway = Enums.SupportedSMSGateways.SMS1CHOTEL;
	EndIf;  
	
	If vSMSGateway = Enums.SupportedSMSGateways.SMS1CHOTEL Then
		Return SMS1CHOTEL; 
	ElsIf vSMSGateway = Enums.SupportedSMSGateways.SMSC Then
		Return SMSC;
	ElsIf vSMSGateway = Enums.SupportedSMSGateways.SMSD Then
		Return SMSD; 
	ElsIf vSMSGateway = Enums.SupportedSMSGateways.SMSESTERIALV Then
		Return SMSESTERIALV;
	ElsIf vSMSGateway = Enums.SupportedSMSGateways.Aramba Then
		Return SMSAramba; 
	ElsIf vSMSGateway = Enums.SupportedSMSGateways.Microsms Then
		Return SMSMicrosms; 
	ElsIf vSMSGateway = Enums.SupportedSMSGateways.SMSLogisoft Then
		Return SMSLogisoft; 
	ElsIf vSMSGateway = Enums.SupportedSMSGateways.OTHER Then
		Return SMSOther;   
	Else
		Return Undefined;
	EndIf;		
EndFunction // GetModuleByGateway

#EndRegion  

#Region Hotel365

// --------------------------------------------------------------------------------------------------------------
// API for Hotel365 module
// --------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------
Function Hotel365_SendSMS(pHotelRef, pDocRef, pPhone, pGuest) Export
	
	vResult = New Structure("Success, GuestID, Errors", False, Undefined, New Array);
	vResult.Success = True;
	vExtSys = Undefined;
	Try
		// Get ext.sys parameters
		vExtSys = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(pHotelRef);
		
		// Check params
		If Not ValueIsFilled(pHotelRef) Then
			vResult.Success = False;
			vResult.Errors.Add(NStr("en = 'Hotel not filled!'; de = 'Hotel nicht gefüllt!'; ru = 'Не указан отель'"));
		EndIf;
		If Not ValueIsFilled(pPhone) Then
			vResult.Success = False;
			vResult.Errors.Add(NStr("en = 'Phone not filled!'; de = 'Telefon nicht gefüllt!'; ru = 'Не указан телефон.'"));
		EndIf;
		If Not ValueIsFilled(vExtSys) Then
			vResult.Success = False;
			vResult.Errors.Add(NStr("en = 'Integration with the hotel365 service is not configured'; de = 'Die Integration mit hotel365 ist nicht konfiguriert'; ru = 'Не настроена интеграция с сервисом hotel365'"));
		EndIf;
		
		If Not vResult.Success Then
			Return vResult;
		EndIf;
		
		vLanguage = pHotelRef.Language;
		If ValueIsFilled(pGuest) And ValueIsFilled(pGuest.Language) Then
			vLanguage = pGuest.Language;
		EndIf;
		vErrorMessage = "";
		
		vSMSTemplate = vExtSys.SMSTemplate;
		
		If ValueIsFilled(vSMSTemplate) And (Not IsBlankString(vSMSTemplate.SMSTextRu) Or Not IsBlankString(vSMSTemplate.SMSTextEn) Or Not IsBlankString(vSMSTemplate.SMSTextDe)) Then
			vSMSText = GetSMSTextByLanguage(vSMSTemplate, vLanguage);
		Else
			vSMSText = StrTemplate(cmNStr("en = 'Welcome to %1  &GuestHotel365Link'; 
										  |de = 'Willkommen bei %1  &GuestHotel365Link'; 
										  |ru = 'Добро пожаловать в %1  &GuestHotel365Link'", vLanguage), Catalogs.Hotels.pmGetHotelPrintName(pHotelRef, vLanguage));
		EndIf;
		
		If IsBlankString(vSMSText) Then
			vErrText = Nstr("en = 'Message text for language %1 of message template <<%2>> is not specified!'; 
							|de = 'Nachrichtentext für Sprache %1 der Nachrichtenvorlage <<%2>> ist nicht angegeben!'; 
							|ru = 'Для языка %1 шаблона сообщения <<%2>> не задан текст сообщения!'");
			vError = StrTemplate(vErrText, vLanguage, vSMSTemplate); 
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtSys, "Hotel365_SendSMS", Enums.ExternalSystemEventTypes.Error, , , vError); 
			vResult.Success = False;
			vResult.Errors.Add(vError);
		Else	
			vSMSText = ReplaceSMSParameters(vSMSText, pDocRef, pGuest);
			
			If Not SMS.SendMessage(vSMSText, pPhone, , , pGuest, pDocRef, SessionParameters.CurrentUser, , vErrorMessage) Then
				vResult.Success = False;
				vResult.Errors.Add(vErrorMessage);
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtSys, "Hotel365_SendSMS", Enums.ExternalSystemEventTypes.Error, , , vErrorMessage); 
			Else
				vResult.Success = True;
			EndIf;		
		EndIf;
	Except
		vError = cmGetRootErrorDescription(ErrorInfo());
		WriteLogEvent("Hotel365_SendSMS", EventLogLevel.Warning, , CurrentSessionDate(), "Failed to send sms! " + vError);
		vResult.Success = False;
		vResult.Errors.Add(vError);
		If ValueIsFilled(vExtSys) Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtSys, "Hotel365_SendSMS", Enums.ExternalSystemEventTypes.Error, , , vErrorMessage); 
		EndIf;
	EndTry;

	Return vResult;
EndFunction // Hotel365_SendSMS

// --------------------------------------------------------------------------------------------------------------
// API for Hotel365
// --------------------------------------------------------------------------------------------------------------
Function GetHotel365GuestID(pDocRef) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MyFolioSystemIdentificators.Identifier AS Identifier
	|FROM
	|	InformationRegister.MyFolioSystemIdentificators AS MyFolioSystemIdentificators
	|WHERE
	|	MyFolioSystemIdentificators.ClientDocument = &qDoc";
	vQry.SetParameter("qDoc", pDocRef);
	vRcds = vQry.Execute().Unload();
	If vRcds.Count() > 0 Then
		Return TrimAll(vRcds.Get(0).Identifier);
	Else
		// Use UUID as seed
		vUUID = StrReplace(String(pDocRef.UUID()), "-", "");
		For vInd = 0 To 26 Do
			vSpecimen = "" + Mid(vUUID, 27 - vInd, 6);
			If GetClientDocumentByMyFolioId(vSpecimen) = Undefined Then
				vRcdMgr = InformationRegisters.MyFolioSystemIdentificators.CreateRecordManager();
				vRcdMgr.ClientDocument = pDocRef;
				vRcdMgr.Identifier = vSpecimen;
				vRcdMgr.Write(False);
				Return vSpecimen;
			EndIf;
		EndDo;
	EndIf;
	Raise NStr("en='Failed to generate guest unique <My folio> system id!'; 
	           |ru='Не удалось получить уникальный id гостя в системе <Мой счет>!'; 
			   |de='Fehler beim generieren Gast einzigartig <My Folio> System ID!'");
EndFunction // GetMyFolioGuestId

#EndRegion  

#Region OnlineReservation

// --------------------------------------------------------------------------------------------------------------
// API for Online reservation module
// --------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------
Function OnlineReservation_SendSMS(pOnlineModuleLink, pHotelRef, pDocRef, pPhone, pGuestRef) Export
	vResult = New Structure("Success, GuestID, Errors", False, Undefined, New Array);
	Try
		If Not ValueIsFilled(pHotelRef) Or Not ValueIsFilled(pPhone) Then
			vResult.Success = False;
			vResult.Errors.Add("Not all parameters are filled!");
			Return vResult;
		EndIf;
		If Not ValueIsFilled(pOnlineModuleLink) Then
			vResult.Success = False;
			vResult.Errors.Add("Missing online module link in the program constants!");
			Return vResult;
		EndIf;
		
		vLanguage = pHotelRef.Language;
		If ValueIsFilled(pGuestRef) And ValueIsFilled(pGuestRef.Language) Then
			vLanguage = pGuestRef.Language;
		EndIf;
		vErrorMessage = "";
		
		If TypeOf(pDocRef) = Type("DocumentRef.ProformaInvoice") Then
			vSMSTemplate = Catalogs.SMSTemplates.SendProformaInvoicePaymentLinkMessage;
		Else
			vSMSTemplate = Catalogs.SMSTemplates.SendPaymentLinkMessage;
		EndIf;
		If ValueIsFilled(vSMSTemplate) And (Not IsBlankString(vSMSTemplate.SMSTextRu) Or Not IsBlankString(vSMSTemplate.SMSTextEn) Or Not IsBlankString(vSMSTemplate.SMSTextDe)) Then
			vSMSText = GetSMSTextByLanguage(vSMSTemplate, vLanguage);
		Else      
			vHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(pHotelRef, vLanguage);
			If TypeOf(pDocRef) = Type("DocumentRef.ProformaInvoice") Then
				vSMSText = StrTemplate(cmNStr("en = '%1: You may pay the proforma invoice by following the link &ProformaInvoiceLink'; 
											  |de = '%1: Sie können die Proforma-Rechnung bezahlen, indem Sie dem Link folgen &ProformaInvoiceLink'; 
											  |ru = '%1: Оплатить счет можно по ссылке &ProformaInvoiceLink'", vLanguage), vHotelPrintName);
			Else
				vSMSText = StrTemplate(cmNStr("en = '%1: Your reservation &GuestGroup &GuestReservationLink'; 
											  |de = '%1: Um Ihre Reservierung &GuestGroup &GuestReservationLink'; 
											  |ru = '%1: Ваше бронирование &GuestGroup &GuestReservationLink'", vLanguage), vHotelPrintName);
			EndIf;
		EndIf;
		vSMSText = ReplaceSMSParameters(vSMSText, pDocRef, pGuestRef);

		If Not SMS.SendMessage(vSMSText, pPhone, , , pGuestRef, pDocRef, SessionParameters.CurrentUser, , vErrorMessage) Then
			Raise vErrorMessage;
		EndIf;		
		
		vResult.Success = True;
	Except
		vError = cmGetRootErrorDescription(ErrorInfo());
		WriteLogEvent("OnlineReservationModule_SendSMS", EventLogLevel.Warning, , CurrentSessionDate(), NStr("en = 'Failed to send sms! '; de = 'SMS senden fehlgeschlagen!'; ru = 'Не удалось отправить смс!'") + vError);
		vResult.Success = False;
		vResult.Errors.Add(vError);
	EndTry;
	Return vResult;
EndFunction // OnlineReservation_SendSMS

#EndRegion

#Region OtherAPI 

// --------------------------------------------------------------------------------------------------------------
//
// Parameters:
//  pLink		 - String	 - Link to convert
//  pProvider	 - String	 - Provider
// 
// Returns:
//  String - Link shortened by clck.ru
//
Function GetShortLink(pLink, pProvider = "clck.ru") Export
	// If it's already shortened than do nothing
	If StrFind(pLink, pProvider) > 0 Then
		Return pLink;
	EndIf;
	Try
		If pProvider = "clck.ru" Or IsBlankString(pProvider) Then
			SetSafeModeDisabled(True);
			ssl						= New OpenSSLSecureConnection;
			StartConnection			= New HTTPConnection("clck.ru", , , , , , ssl);
			Headers					= New Map;
			HttpRequest				= New HttpRequest("/--?url=" + EncodeString(pLink, StringEncodingMethod.URLEncoding, TextEncoding.UTF8), Headers);
			
			HTTPResponse				=	StartConnection.Get(HttpRequest);
			Return HTTPResponse.GetBodyAsString();
		ElsIf pProvider="is.gd" Then
			SetSafeModeDisabled(True);
			ssl						= New OpenSSLSecureConnection;
			StartConnection			= New HTTPConnection("is.gd", , , , , , ssl);
			Headers					= New Map;
			HttpRequest				= New HttpRequest("/create.php?format=simple&url=" + EncodeString(pLink, StringEncodingMethod.URLEncoding, TextEncoding.UTF8), Headers);
			
			HTTPResponse				= StartConnection.Get(HttpRequest);
			Return HTTPResponse.GetBodyAsString();
		ElsIf pProvider = "gstlnk.ru" Then
			SetSafeModeDisabled(True);
			ssl						= New OpenSSLSecureConnection;
			StartConnection			= New HTTPConnection("gstlnk.ru", , , , , , ssl);
			Headers					= New Map;
			HttpRequest				= New HttpRequest("/api/v2/action/shorten?key=5a9982864c565afd81b8885f8ac9f9&url=" + EncodeString(pLink, StringEncodingMethod.URLEncoding, TextEncoding.UTF8), Headers);
			
			HTTPResponse			= StartConnection.Get(HttpRequest);
			Return HTTPResponse.GetBodyAsString();
		Else
			Return pLink;
		EndIf;
	Except
	EndTry;
	
	// No internet connection - just return original link
	Return pLink;
EndFunction

// --------------------------------------------------------------------------------------------------------------
Function GetNumberOfSegments(pSMSText) Export
	vIsTextCyr = False;
	vSMSTextLen = StrLen(pSMSText);
	Quantity = 0;
	For Ch = 1 to vSMSTextLen Do
		If CharCode(pSMSText, Ch) > 255 Then
			vIsTextCyr = True;
			Break;
		EndIf;
	EndDo;
	If Not vIsTextCyr Then
		If vSMSTextLen > 160 Then
			Quantity = ?(Int(vSMSTextLen / 153) <> (vSMSTextLen / 153), Int(vSMSTextLen / 153) + 1, Int(vSMSTextLen / 153));
		Else
			Quantity = 1;
		EndIf;
	Else
		If vSMSTextLen > 70 Then
			Quantity = ?(Int(vSMSTextLen / 67) <> (vSMSTextLen / 67), Int(vSMSTextLen / 67) + 1, Int(vSMSTextLen / 67));
		Else
			Quantity = 1;
		EndIf;
	EndIf;
    Return Quantity;
EndFunction // GetNumberOfSegments

// --------------------------------------------------------------------------------------------------------------
Procedure CheckSMSStatuses(rError = "") Export
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	SMSMessages.MessageID AS MessageID,
		|	SMSMessages.Phone AS Phone,
		|	SMSMessages.Status AS Status
		|FROM
		|	InformationRegister.SMSMessages AS SMSMessages
		|WHERE
		|	(SMSMessages.Status = &qEnRoute
		|			OR SMSMessages.Status = &qEnQueue
		|			OR SMSMessages.Status = """")
		|	AND SMSMessages.MessageID <> &qIsBlankMessageID
		|	AND SMSMessages.Period >= &qPeriodFrom";
	vQuery.SetParameter("qEnRoute", "EnRoute");
	vQuery.SetParameter("qEnQueue", "EnQueue");
	vQuery.SetParameter("qIsBlankMessageID", "");
	vQuery.SetParameter("qPeriodFrom", CurrentSessionDate() - tcCommonFunctionOnClientServer.cmOneDay());
	vResult = vQuery.Execute().Select();
	vSMSMessagesRecordSet = InformationRegisters.SMSMessages.CreateRecordSet();
	While vResult.Next() Do
		vMessStatusResult = GetMessageStatus(vResult.MessageID, vResult.Phone);
		If IsBlankString(vMessStatusResult.ErrorDescription) Then
			// Do movement
			vSMSMessagesRecordSet.Filter.MessageID.Set(vResult.MessageID);
			vSMSMessagesRecordSet.Read(); 
			vSMSMessagesRecordSet[0].Status = vMessStatusResult.Status;
			// Write movements
			vSMSMessagesRecordSet.Write();	
		EndIf;
	EndDo;
EndProcedure // CheckSMSStatuses

// --------------------------------------------------------------------------------------------------------------
Function GetValidPhoneNumber(pPhone) Export
	vPhone = "";
	vCommaPosition = Find(pPhone, ",");
	If vCommaPosition = 0 Then
		vPhone = TrimAll(pPhone);
	Else
		vPhone = TrimAll(Left(pPhone, vCommaPosition - 1));
	EndIf;
	vPhone = StrReplace(vPhone, " ", "");	
	vPhone = StrReplace(vPhone, ")", "");	
	vPhone = StrReplace(vPhone, "(", "");	
	vPhone = StrReplace(vPhone, "-", "");
	vPhone = StrReplace(vPhone, "+", "");
	vCurrHotelCountryISOCode = SessionParameters.CurrentHotel.Citizenship.ISOCode;
	If vCurrHotelCountryISOCode = "RU" Or vCurrHotelCountryISOCode = "KZ" Then
		If StrLen(vPhone) = 10 Then
			vPhone = "7" + vPhone;
		EndIf;
		If Left(vPhone, 1) = "8" And StrLen(vPhone) = 11 Then
			vPhone = "7" + Right(vPhone, StrLen(vPhone)-1);
		EndIf;
	ElsIf vCurrHotelCountryISOCode = "UA" Then
		If (Left(vPhone, 1) = "0" Or Left(vPhone, 1) = "8") And StrLen(vPhone) = 11 Then
			vPhone = "38" + Right(vPhone, StrLen(vPhone)-1);
		EndIf;
	EndIf;
	Return vPhone;
EndFunction // GetValidPhoneNumber

// --------------------------------------------------------------------------------
Function GetPhoneNumberWithCountryCode(pPhone) Export
	vPhone = TrimAll(pPhone);
	If StrLen(vPhone) = 10 Then
		vPhone = "+7" + vPhone;
	ElsIf Left(vPhone, 1) = "8" And StrLen(vPhone) = 11 Then
		vPhone = "+7" + Right(vPhone, StrLen(vPhone)-1);
	ElsIf Left(vPhone, 1) = "7" And StrLen(vPhone) = 11 Then
		vPhone = "+" + vPhone;
	EndIf;
	Return vPhone;
EndFunction // GetPhoneNumberWithCountryCode

// --------------------------------------------------------------------------------------------------------------
Function IsSMSDeliveryActive() Export
	vLogin = Constants.SMSLogin.Get();
	vPassword = Constants.SMSPassword.Get();
	vSenderName = Constants.SMSSenderName.Get();
	vCompany = Constants.SMSCompany.Get();
	If ValueIsFilled(vLogin) and ValueIsFilled(vPassword) and 
		ValueIsFilled(vSenderName) and ValueIsFilled(vCompany) Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // IsSMSDeliveryActive

// --------------------------------------------------------------------------------------------------------------
Function GetClientDocumentByMyFolioId(pId) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MyFolioSystemIdentificators.ClientDocument AS ClientDocument
	|FROM
	|	InformationRegister.MyFolioSystemIdentificators AS MyFolioSystemIdentificators
	|WHERE
	|	MyFolioSystemIdentificators.Identifier = &qIdentifier";
	vQry.SetParameter("qIdentifier", pId);
	vRcds = vQry.Execute().Unload();
	If vRcds.Count() = 1 Then
		vDoc = vRcds.Get(0).ClientDocument;
		If ValueIsFilled(vDoc) And TypeOf(vDoc) = Type("DocumentRef.Reservation") Then
			// Try to find accommodation for the given reservation
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Accommodation.Ref AS Ref
			|FROM
			|	Document.Accommodation AS Accommodation
			|WHERE
			|	Accommodation.Posted
			|	AND Accommodation.AccommodationStatus.IsActive
			|	AND Accommodation.Reservation = &qReservation
			|
			|ORDER BY
			|	Accommodation.CheckInDate DESC";
			vQry.SetParameter("qReservation", vDoc);
			vAccs = vQry.Execute().Unload();
			If vAccs.Count() > 0 Then
				vDoc = vAccs.Get(0).Ref;
			EndIf;
		EndIf;
		If ValueIsFilled(vDoc) And TypeOf(vDoc) = Type("DocumentRef.Accommodation") Then
			If vDoc.Posted And ValueIsFilled(vDoc.AccommodationStatus) And vDoc.AccommodationStatus.IsActive And 
			  (Not vDoc.AccommodationStatus.IsInHouse Or BegOfDay(vDoc.CheckOutDate) < BegOfDay(CurrentSessionDate())) Then
				// Try to get active accommodation for the guest
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	Accommodation.Ref AS Ref
				|FROM
				|	Document.Accommodation AS Accommodation
				|WHERE
				|	Accommodation.GuestGroup = &qGuestGroup
				|	AND Accommodation.Guest = &qGuest
				|	AND Accommodation.Posted
				|	AND ISNULL(Accommodation.AccommodationStatus.IsActive, FALSE)
				|	AND ISNULL(Accommodation.AccommodationStatus.IsInHouse, FALSE)
				|
				|ORDER BY
				|	Accommodation.PointInTime DESC";
				vQry.SetParameter("qGuestGroup", vDoc.GuestGroup);
				vQry.SetParameter("qGuest", vDoc.Guest);
				vAccs = vQry.Execute().Unload();
				If vAccs.Count() > 0 Then
					vDoc = vAccs.Get(0).Ref;
				EndIf;
			EndIf;
		EndIf;
		Return vDoc;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetClientDocumentByMyFolioId

// --------------------------------------------------------------------------------------------------------------
Function GetMyFolioGuestId(pDocRef) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MyFolioSystemIdentificators.Identifier AS Identifier
	|FROM
	|	InformationRegister.MyFolioSystemIdentificators AS MyFolioSystemIdentificators
	|WHERE
	|	MyFolioSystemIdentificators.ClientDocument = &qDoc";
	vQry.SetParameter("qDoc", pDocRef);
	vRcds = vQry.Execute().Unload();
	If vRcds.Count() > 0 Then
		Return TrimAll(vRcds.Get(0).Identifier);
	Else
		Return "";
	EndIf;
EndFunction // GetMyFolioGuestId

// --------------------------------------------------------------------------------------------------------------
Function GetMyFolioGuestIdByClient(pClient) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MyFolioSystemIdentificators.Identifier AS Identifier
	|FROM
	|	InformationRegister.MyFolioSystemIdentificators AS MyFolioSystemIdentificators
	|WHERE
	|	CASE
	|			WHEN MyFolioSystemIdentificators.ClientDocument REFS Document.Accommodation
	|					OR MyFolioSystemIdentificators.ClientDocument REFS Document.Reservation
	|				THEN MyFolioSystemIdentificators.ClientDocument.Guest = &qGuest
	|			WHEN MyFolioSystemIdentificators.ClientDocument REFS Document.Folio
	|					OR MyFolioSystemIdentificators.ClientDocument REFS Document.ResourceReservation
	|				THEN MyFolioSystemIdentificators.ClientDocument.Client = &qGuest
	|			ELSE FALSE
	|		END
	|
	|ORDER BY
	|	MyFolioSystemIdentificators.ClientDocument.PointInTime DESC";
	vQry.SetParameter("qGuest", pClient);
	vRcds = vQry.Execute().Unload();
	If vRcds.Count() > 0 Then
		Return TrimAll(vRcds.Get(0).Identifier);
	Else
		Return "";
	EndIf;
EndFunction // GetMyFolioGuestId

// --------------------------------------------------------------------------------------------------------------
Procedure SaveGuestMyFolioID(pDocRef, pGuestID) Export
	vRcdMgr = InformationRegisters.MyFolioSystemIdentificators.CreateRecordManager();
	vRcdMgr.ClientDocument = pDocRef;
	vRcdMgr.Identifier = pGuestID;
	vRcdMgr.Write(True);
EndProcedure // SaveGuestMyFolioID

// --------------------------------------------------------------------------------------------------------------
Function ReplaceSMSParameters(pSMSText, pDocRef, pClientRef = Undefined, pAmountStr = "", pDiscountCard = Undefined, pLanguage = Undefined, pGuestGroup = Undefined) Export
	vSMSText = TrimAll(pSMSText);
	vSMSText = StrReplace(vSMSText, "&amp;", "&");
	vLanguage = pLanguage;
	If Not ValueIsFilled(vLanguage) Then
		If ValueIsFilled(pClientRef) Then
			vLanguage = pClientRef.Language;
		EndIf;
	EndIf;
	vGuestGroup = pGuestGroup;
	If ValueIsFilled(pDocRef) Then
		If Not ValueIsFilled(vLanguage) Then
            If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation") Or TypeOf(pDocRef) = Type("DocumentRef.BonusesOperation") Then
				vDocRefGuest = pDocRef.Guest;
				If ValueIsFilled(vDocRefGuest) And ValueIsFilled(vDocRefGuest.Language) Then
					vLanguage = vDocRefGuest.Language;
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vLanguage) Then
			vLanguage = pDocRef.Hotel.Language;
		EndIf;
		If Not ValueIsFilled(vGuestGroup) Then
            If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation") Or TypeOf(pDocRef) = Type("DocumentRef.ResourceReservation") Or TypeOf(pDocRef) = Type("DocumentRef.Folio") Or TypeOf(pDocRef) = Type("DocumentRef.BonusesOperation") Then
				vGuestGroup = pDocRef.GuestGroup;
			ElsIf TypeOf(pDocRef) = Type("DocumentRef.Charge") Then
				vGuestGroup = pDocRef.Folio.GuestGroup;
			EndIf;
		EndIf;
		vDearIsFindPos = StrFind(vSMSText, "&Dear");
		If vDearIsFindPos > 0 Then
			vDearIsFirst = False;
			If Upper(Left(vSMSText, 2)) = "RU" Or Upper(Left(vSMSText, 2)) = "EN" Or Upper(Left(vSMSText, 2)) = "DE" Then
				If vDearIsFindPos <= 7 Then
					vDearIsFirst = True;
				EndIf;
			Else
				If vDearIsFindPos = 1 Then
					vDearIsFirst = True;
				EndIf;
			EndIf;
			vDearIsUpper = False;
			vDearPosInd = StrFind(vSMSText, ". &Dear");
			If vDearPosInd > 0 Then
				vDearIsUpper = True;
			EndIf;
			vDearPosInd = StrFind(vSMSText, ">&Dear");
			If vDearPosInd > 0 Then
				vDearIsUpper = True;
			EndIf;
			If ValueIsFilled(pClientRef) And ValueIsFilled(pClientRef.Sex) Then
				If pClientRef.Sex = Enums.Sex.Male Then
					vDear = cmNStr("en='dear';ru='уважаемый';de='Sehr geehrter'", vLanguage);
				Else
					vDear = cmNStr("en='dear';ru='уважаемая';de='Sehr geehrte'", vLanguage);
				EndIf;
			ElsIf (TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation")) And 
				  ValueIsFilled(pDocRef.Guest.Sex) Then
				If pDocRef.Guest.Sex = Enums.Sex.Male Then
					vDear = cmNStr("en='dear';ru='уважаемый';de='Sehr geehrter'", vLanguage);
				Else
					vDear = cmNStr("en='dear';ru='уважаемая';de='Sehr geehrte'", vLanguage);
				EndIf;
			Else
				vDear = cmNStr("en='dear';ru='уважаемый(ая)';de='Sehr geehrte(r)'", vLanguage);
			EndIf;
			If vDearIsFirst Or vDearIsUpper Then
				vDear = Upper(Left(vDear, 1)) + Mid(vDear, 2);
			EndIf;
			vSMSText = StrReplace(vSMSText, "&Dear", vDear);
            // Discount card
            If pDocRef.Metadata().Attributes.Find("DiscountCard") <> Undefined Then
				If StrFind(vSMSText, "&CardID") > 0 Then
					If ValueIsFilled(pDocRef.DiscountCard) Then
	                	vSMSText = StrReplace(vSMSText, "&CardID", pDocRef.DiscountCard.Identifier);
					Else
	                	vSMSText = StrReplace(vSMSText, "&CardID", "");
					EndIf;
				EndIf;
				If StrFind(vSMSText, "&DiscountCardBalance") > 0 Then
					If ValueIsFilled(pDocRef.DiscountCard) Then
		                vCardData = AccumulationRegisters.Bonuses.mmGetBalanceByCard(pDocRef.DiscountCard);
		            	vTotalByCard = Format(vCardData.BalanceAmount, "NFD=2; NZ=0.00");
		                vSMSText = StrReplace(vSMSText, "&DiscountCardBalance", vTotalByCard);
					Else
		                vSMSText = StrReplace(vSMSText, "&DiscountCardBalance", "");
					EndIf;
	            EndIf;
            EndIf;
			If TypeOf(pDocRef) = Type("DocumentRef.BonusesOperation") Then
				// Amount
				If StrFind(vSMSText, "&BonusesOperationAmount") > 0 Then
					vBonusesOperationAmount = Format(pDocRef.Amount, "NFD=2; NZ=0.00"); 
					If pDocRef.OperationType = Enums.BonusesOperationTypes.Expense Then
					   vBonusesOperationAmount =  - vBonusesOperationAmount;
					EndIf; 
					vSMSText = StrReplace(vSMSText, "&BonusesOperationAmount", vBonusesOperationAmount); 
				EndIf;
				// Room
				If StrFind(vSMSText, "&Room") > 0 Then
					vSMSText = StrReplace(vSMSText, "&Room", TrimAll(pDocRef.Room));
				EndIf;
				// Guest ID
				If StrFind(vSMSText, "&GuestUUID") > 0 Then
					If ValueIsFilled(pDocRef.Guest) Then
						vGuestUUID = SMS.GetMyFolioGuestIdByClient(pDocRef.Guest);
						vSMSText = StrReplace(vSMSText, "&GuestUUID", vGuestUUID);
					Else
						vSMSText = StrReplace(vSMSText, "&GuestUUID", "");
					EndIf;
				EndIf;
				If StrFind(vSMSText, "&CardID") > 0 Then
					If ValueIsFilled(pDocRef.Card) Then
						vSMSText = StrReplace(vSMSText, "&CardID", pDocRef.Card.Identifier);
					Else
						vSMSText = StrReplace(vSMSText, "&CardID", "");
					EndIf;
				EndIf;
				If StrFind(vSMSText, "&DiscountCardBalance") > 0 Then
					If ValueIsFilled(pDocRef.Card) Then
						vCardData = AccumulationRegisters.Bonuses.mmGetBalanceByCard(pDocRef.Card);
						vTotalByCard = Format(vCardData.BalanceAmount, "NFD=2; NZ=0.00");
						vSMSText = StrReplace(vSMSText, "&DiscountCardBalance", vTotalByCard);
					Else
						vSMSText = StrReplace(vSMSText, "&DiscountCardBalance", "");
					EndIf;
				EndIf;
			EndIf;    
		EndIf;
		If ValueIsFilled(pClientRef) Then
			vSMSText = StrReplace(vSMSText, "&LastName &FirstName &SecondName", TrimAll(TrimAll(pClientRef.LastName) + " " + TrimAll(pClientRef.FirstName) + " " + TrimAll(pClientRef.SecondName)));
			vSMSText = StrReplace(vSMSText, "&FirstName &SecondName &LastName", TrimAll(TrimAll(pClientRef.FirstName) + " " + TrimAll(pClientRef.SecondName) + " " + TrimAll(pClientRef.LastName)));
			vSMSText = StrReplace(vSMSText, "&FirstName &SecondName", TrimAll(TrimAll(pClientRef.FirstName) + " " + TrimAll(pClientRef.SecondName)));
			vSMSText = StrReplace(vSMSText, "&FirstName", TrimAll(pClientRef.FirstName));
			vSMSText = StrReplace(vSMSText, "&LastName", TrimAll(pClientRef.LastName));
			vSMSText = StrReplace(vSMSText, "&SecondName", TrimAll(pClientRef.SecondName));
		ElsIf (TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation")) And 
			  ValueIsFilled(pDocRef.Guest) Then
			vGuestRef = pDocRef.Guest;
			vSMSText = StrReplace(vSMSText, "&LastName &FirstName &SecondName", TrimAll(TrimAll(vGuestRef.LastName) + " " + TrimAll(vGuestRef.FirstName) + " " + TrimAll(vGuestRef.SecondName)));
			vSMSText = StrReplace(vSMSText, "&FirstName &SecondName &LastName", TrimAll(TrimAll(vGuestRef.FirstName) + " " + TrimAll(vGuestRef.SecondName) + " " + TrimAll(vGuestRef.LastName)));
			vSMSText = StrReplace(vSMSText, "&FirstName &SecondName", TrimAll(TrimAll(vGuestRef.FirstName) + " " + TrimAll(vGuestRef.SecondName)));
			vSMSText = StrReplace(vSMSText, "&FirstName", TrimAll(vGuestRef.FirstName));
			vSMSText = StrReplace(vSMSText, "&LastName", TrimAll(vGuestRef.LastName));
			vSMSText = StrReplace(vSMSText, "&SecondName", TrimAll(vGuestRef.SecondName));
		ElsIf (TypeOf(pDocRef) = Type("DocumentRef.Settlement") Or TypeOf(pDocRef) = Type("DocumentRef.ProformaInvoice")) And 
		       ValueIsFilled(pDocRef.GuestGroup) And ValueIsFilled(pDocRef.GuestGroup.Client) Then
			vGuestRef = pDocRef.GuestGroup.Client;
			vSMSText = StrReplace(vSMSText, "&LastName &FirstName &SecondName", TrimAll(TrimAll(vGuestRef.LastName) + " " + TrimAll(vGuestRef.FirstName) + " " + TrimAll(vGuestRef.SecondName)));
			vSMSText = StrReplace(vSMSText, "&FirstName &SecondName &LastName", TrimAll(TrimAll(vGuestRef.FirstName) + " " + TrimAll(vGuestRef.SecondName) + " " + TrimAll(vGuestRef.LastName)));
			vSMSText = StrReplace(vSMSText, "&FirstName &SecondName", TrimAll(TrimAll(vGuestRef.FirstName) + " " + TrimAll(vGuestRef.SecondName)));
			vSMSText = StrReplace(vSMSText, "&FirstName", TrimAll(vGuestRef.FirstName));
			vSMSText = StrReplace(vSMSText, "&LastName", TrimAll(vGuestRef.LastName));
			vSMSText = StrReplace(vSMSText, "&SecondName", TrimAll(vGuestRef.SecondName));
		EndIf;
		If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
			vSMSText = StrReplace(vSMSText, "&CheckInDate", Format(pDocRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'"));
			vSMSText = StrReplace(vSMSText, "&CheckOutDate", Format(pDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
			vSMSText = StrReplace(vSMSText, "&Duration", Format(pDocRef.Duration, "ND=10; NFD=0; NZ=; NG="));
			vSMSText = StrReplace(vSMSText, "&RoomType", TrimAll(pDocRef.RoomType));
			vSMSText = StrReplace(vSMSText, "&RoomClass", TrimAll(pDocRef.RoomType.RoomClass));
			vSMSText = StrReplace(vSMSText, "&Room", TrimAll(pDocRef.Room));
			vSMSText = StrReplace(vSMSText, "&WindowView", TrimAll(pDocRef.RoomType.WindowView));
		ElsIf TypeOf(pDocRef) = Type("DocumentRef.ResourceReservation") Then
			vSMSText = StrReplace(vSMSText, "&DateTimeFrom", Format(pDocRef.DateTimeFrom, "DF='dd.MM.yyyy HH:mm'"));
			vSMSText = StrReplace(vSMSText, "&DateTimeTo", Format(pDocRef.DateTimeTo, "DF='dd.MM.yyyy HH:mm'"));
			vSMSText = StrReplace(vSMSText, "&Duration", Format(pDocRef.Duration, "ND=10; NFD=0; NZ=; NG="));
			vSMSText = StrReplace(vSMSText, "&Resource", TrimAll(pDocRef.Resource));
			vSMSText = StrReplace(vSMSText, "&ResourceType", TrimAll(pDocRef.ResourceType));
		EndIf;
		If TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
			If StrFind(vSMSText, "&ReservationUUID") > 0 Then
				vSMSText = StrReplace(vSMSText, "&ReservationUUID", pDocRef.UUID());
			EndIf;
			// Guest reservation link
			If StrFind(vSMSText, "&GuestReservationLink") > 0 Then
				vOnlineLink = Catalogs.ExternalSystemInteractions.GetReservationGuestURL(pDocRef);
				vSMSText = StrReplace(vSMSText, "&GuestReservationLink", vOnlineLink);
			EndIf;
			// Registration link
			If StrFind(vSMSText, "&GuestRegistrationLink") > 0 Then
				vRegLink = Catalogs.ExternalSystemInteractions.GetRegistrationGuestURL(pDocRef);
				vSMSText = StrReplace(vSMSText, "&GuestRegistrationLink", vRegLink);
			EndIf;
		ElsIf TypeOf(pDocRef) = Type("DocumentRef.ProformaInvoice") Then
			If StrFind(vSMSText, "&ProformaInvoiceLink") > 0 Then
				vOnlineLink = Catalogs.ExternalSystemInteractions.GetProformaInvoiceURL(pDocRef);
				vSMSText = StrReplace(vSMSText, "&ProformaInvoiceLink", vOnlineLink);
			EndIf;
		EndIf;
		If TypeOf(pDocRef) = Type("DocumentRef.Charge") Then
			If StrFind(vSMSText, "&Service") > 0 Then
				vService = pDocRef.Service;
				vServiceDescription = ?(IsBlankString(vService.DescriptionTranslations), vService.Description,Nstr(vService.DescriptionTranslations));
				vSMSText = StrReplace(vSMSText, "&Service", TrimAll(vServiceDescription));
			EndIf;
			If StrFind(vSMSText, "&GuestGroup") > 0 And ValueIsFilled(vGuestGroup) Then
				vSMSText = StrReplace(vSMSText, "&GuestGroup", Format(vGuestGroup.Code, "ND=12; NFD=0; NZ=; NG="));
			EndIf; 
			If StrFind(vSMSText, "&ReservationNumber") > 0 And ValueIsFilled(pDocRef.ParentDoc) And 
			  (TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.ResourceReservation")) Then
				vSMSText = StrReplace(vSMSText, "&ReservationNumber", cmGetDocumentNumberPresentation(pDocRef.ParentDoc.Number));
			EndIf;
			If StrFind(vSMSText, "&GuestUUID") > 0 Then
				vGuestUUID = "";
				If ValueIsFilled(pClientRef) Then
					vGuestUUID = SMS.GetMyFolioGuestIdByClient(pClientRef);
				Else	
					vGuestUUID = GetMyFolioGuestIdByClient(pDocRef.Folio.Client);
				EndIf;
				vSMSText = StrReplace(vSMSText, "&GuestUUID", vGuestUUID);
			EndIf;
		Else
			vSMSText = StrReplace(vSMSText, "&Service", "");
			If StrFind(vSMSText, "&GuestGroup") > 0 And ValueIsFilled(vGuestGroup) Then
				vSMSText = StrReplace(vSMSText, "&GuestGroup", Format(vGuestGroup.Code, "ND=12; NFD=0; NZ=; NG="));
			EndIf;
			If StrFind(vSMSText, "&ReservationNumber") > 0 And ValueIsFilled(pDocRef) Then
				If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation") Or TypeOf(pDocRef) = Type("DocumentRef.ResourceReservation") Then
					vSMSText = StrReplace(vSMSText, "&ReservationNumber", cmGetDocumentNumberPresentation(pDocRef.Number));
				ElsIf TypeOf(pDocRef) = Type("DocumentRef.Folio") And ValueIsFilled(pDocRef.ParentDoc) Then
					If TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.ResourceReservation") Then
						vSMSText = StrReplace(vSMSText, "&ReservationNumber", cmGetDocumentNumberPresentation(pDocRef.ParentDoc.Number));
					EndIf;
				EndIf;
			EndIf; 
			If StrFind(vSMSText, "&GuestUUID") > 0 Then
				vGuestUUID = GetMyFolioGuestId(pDocRef);
				vSMSText = StrReplace(vSMSText, "&GuestUUID", vGuestUUID);
			EndIf;
		EndIf;
		
		// Get hotel365 link
		If StrFind(vSMSText, "&GuestHotel365Link") > 0 Then
			vH365Link = Catalogs.ExternalSystemInteractions.GetHotel365URL(pDocRef);
			vSMSText = StrReplace(vSMSText, "&GuestHotel365Link", vH365Link);
		EndIf;
		
		If StrFind(vSMSText, "&HotelDesc") > 0 Or StrFind(vSMSText, "&HotelName") > 0 Then
			vHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(pDocRef.Hotel, vLanguage);
			
			vSMSText = StrReplace(vSMSText, "&HotelDesc", vHotelPrintName);
			vSMSText = StrReplace(vSMSText, "&HotelName", vHotelPrintName);
		EndIf;

		vSMSText = StrReplace(vSMSText, "&PaymentAmount", TrimAll(pAmountStr));
		If StrFind(vSMSText, "&FolioBalance") > 0 Then
			vGuestBalanceIsReceived = False;
			vDocuments = New ValueList();
			vDocuments.Add(pDocRef);
			vBalances = cmGetDocumentListBalances(vDocuments, pDocRef.Hotel);
			vGuestBalance = cmFormatSum(0, pDocRef.Hotel.FolioCurrency, "NZ=");
			For Each vBalancesRow In vBalances Do
				vGuestBalanceNum = vBalancesRow.ClientSumBalance;
				vGuestBalancePrefix = "";
				If vGuestBalanceNum < 0 Then
					vGuestBalancePrefix = cmNStr("en='deposit ';ru='депозит ';de='Guthaben '", vLanguage);
					vGuestBalanceNum = -vGuestBalanceNum;
				ElsIf vGuestBalanceNum > 0 Then
					vGuestBalancePrefix = cmNStr("en='debt ';ru='задолженность ';de='Verschuldung '", vLanguage);
				EndIf;
				If Not vGuestBalanceIsReceived Then
					vGuestBalanceIsReceived = True;
					vGuestBalance = vGuestBalancePrefix + cmFormatSum(vGuestBalanceNum, vBalancesRow.FolioCurrency);
				Else
					vGuestBalance = ", " + vGuestBalancePrefix + cmFormatSum(vGuestBalanceNum, vBalancesRow.FolioCurrency);
				EndIf;
			EndDo;
			vSMSText = StrReplace(vSMSText, "&FolioBalance", vGuestBalance);
		EndIf;
		If StrFind(vSMSText, "&GroupTotalAmount") > 0 And ValueIsFilled(vGuestGroup) Then
			vGroupTotalSales = vGuestGroup.GetObject().pmGetSalesTotals();
			vGroupTotalSales.GroupBy("Currency", "Sales, SalesForecast, ExpectedSales");
			vGroupTotalAmount = "";
			For Each vGroupTotalSalesRow In vGroupTotalSales Do
				vGroupTotalAmount = vGroupTotalAmount + ?(IsBlankString(vGroupTotalAmount), "", ", ") + cmFormatSum(vGroupTotalSalesRow.Sales + vGroupTotalSalesRow.SalesForecast, vGroupTotalSalesRow.Currency);
			EndDo;
			vSMSText = StrReplace(vSMSText, "&GroupTotalAmount", vGroupTotalAmount);
		EndIf;
		vSMSText = cmNStr(vSMSText, vLanguage);
	ElsIf ValueIsFilled(pClientRef) Then
		If TypeOf(pClientRef) = Type("CatalogRef.Clients") Then
			vDearIsFindPos = StrFind(vSMSText, "&Dear");
			If vDearIsFindPos > 0 Then
				vDearIsFirst = False;
				If Upper(Left(vSMSText, 2)) = "RU" Or Upper(Left(vSMSText, 2)) = "EN" Or Upper(Left(vSMSText, 2)) = "DE" Then
					If vDearIsFindPos <= 7 Then
						vDearIsFirst = True;
					EndIf;
				Else
					If vDearIsFindPos = 1 Then
						vDearIsFirst = True;
					EndIf;
				EndIf;
				vDearIsUpper = False;
				vDearPosInd = StrFind(vSMSText, ". &Dear");
				If vDearPosInd > 0 Then
					vDearIsUpper = True;
				EndIf;
				vDearPosInd = StrFind(vSMSText, ">&Dear");
				If vDearPosInd > 0 Then
					vDearIsUpper = True;
				EndIf;
				If ValueIsFilled(pClientRef.Sex) Then
					If pClientRef.Sex = Enums.Sex.Male Then
						vDear = cmNStr("en='dear';ru='уважаемый';de='Sehr geehrter'", vLanguage);
					Else
						vDear = cmNStr("en='dear';ru='уважаемая';de='Sehr geehrte'", vLanguage);
					EndIf;
				Else
					vDear = cmNStr("en='dear';ru='уважаемый(ая)';de='Sehr geehrte(r)'", vLanguage);
				EndIf;
				If vDearIsFirst Or vDearIsUpper Then
					vDear = Upper(Left(vDear, 1)) + Mid(vDear, 2);
				EndIf;
				vSMSText = StrReplace(vSMSText, "&Dear", vDear);
			EndIf;
			vSMSText = StrReplace(vSMSText, "&LastName &FirstName &SecondName", TrimAll(TrimAll(pClientRef.LastName) + " " + TrimAll(pClientRef.FirstName) + " " + TrimAll(pClientRef.SecondName)));
			vSMSText = StrReplace(vSMSText, "&FirstName &SecondName &LastName", TrimAll(TrimAll(pClientRef.FirstName) + " " + TrimAll(pClientRef.SecondName) + " " + TrimAll(pClientRef.LastName)));
			vSMSText = StrReplace(vSMSText, "&FirstName &SecondName", TrimAll(TrimAll(pClientRef.FirstName) + " " + TrimAll(pClientRef.SecondName)));
			vSMSText = StrReplace(vSMSText, "&FirstName", TrimAll(pClientRef.FirstName));
			vSMSText = StrReplace(vSMSText, "&LastName", TrimAll(pClientRef.LastName));
			vSMSText = StrReplace(vSMSText, "&SecondName", TrimAll(pClientRef.SecondName));
            If ValueIsFilled(pDiscountCard) Then
				If StrFind(vSMSText, "&CardID") > 0 Then
                	vSMSText = StrReplace(vSMSText, "&CardID", pDiscountCard.Identifier);
				EndIf;
				If StrFind(vSMSText, "&DiscountCardBalance") > 0 Then
	                vCardData = AccumulationRegisters.Bonuses.mmGetBalanceByCard(pDiscountCard);
	                vTotalByCard = Format(vCardData.BalanceAmount, "NFD=2; NZ=0.00");
	                vSMSText = StrReplace(vSMSText, "&DiscountCardBalance", vTotalByCard);
				EndIf;
            EndIf; 
		EndIf;
		vSMSText = cmNStr(vSMSText, vLanguage);
	EndIf;      
	If StrFind(vSMSText, "&Employee") Then
		vEmployee = SessionParameters.CurrentUser;
		vSMSText = StrReplace(vSMSText, "&EmployeeFirstName", TrimAll(vEmployee.FirstName));
		vSMSText = StrReplace(vSMSText, "&EmployeeSecondName", TrimAll(vEmployee.SecondName));
		vSMSText = StrReplace(vSMSText, "&EmployeeLastName", TrimAll(vEmployee.LastName));
		vSMSText = StrReplace(vSMSText, "&EmployeeFullName", TrimAll(Catalogs.Employees.pmGetEmployeeDescription(vEmployee, vLanguage)));
		vSMSText = StrReplace(vSMSText, "&EmployeeDepartment", TrimAll(vEmployee.Department.Description));
		vSMSText = StrReplace(vSMSText, "&EmployeePosition", cmNStr(vEmployee.Position, vLanguage));
	EndIf;	
	
	Return vSMSText;
EndFunction // ReplaceSMSParameters

// --------------------------------------------------------------------------------------------------------------
Function SendChangeDocumentSatusMessage(pDocRef, rError = "") Export
	rError = "";
	Try
		If SessionParameters.SMSDeliveryIsStopped Then
			Return True;
		EndIf;
		vDocumentStatus = Undefined;
		If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Then
			vDocumentStatus = pDocRef.AccommodationStatus;
		ElsIf TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
			vDocumentStatus = pDocRef.ReservationStatus;
		Else
			rError = NStr("en = 'Unsupported document type!'; de = 'Dokumententyp wird nicht unterstützt!'; ru = 'Тип документа не поддерживается!'");
			Return True;
		EndIf;
		If pDocRef.AccommodationTemplate = Catalogs.AccommodationTemplates.EmptyRef() And 
		   pDocRef.AccommodationType.Type <> Enums.AccomodationTypes.Room And 
		   pDocRef.AccommodationType.Type <> Enums.AccomodationTypes.Beds Then
			rError = NStr("en = 'Message could be sent to the main room guest only!'; de = 'Das Senden einer Nachricht ist nur an den Hauptgast des Hotelzimmers möglich!'; ru = 'Отправка сообщения возможна только основному гостю номера!'");
			Return True;
		EndIf;
		If Not ValueIsFilled(vDocumentStatus) Then
			rError = NStr("en = 'Document status is not specified!'; de = 'Der Dokumentstatus ist nicht festgelegt!'; ru = 'Не определен статус документа!'");
			Return True;
		EndIf;
		If BegOfDay(pDocRef.CheckOutDate) < BegOfDay(CurrentSessionDate()) Then
			rError = NStr("en = 'Current time is after guest check-out!'; de = 'Aktuelle Zeit ist später als die Abreisezeit des Gastes!'; ru = 'Текущее время позже времени выезда гостя!'");
			Return True;
		EndIf;
		If Not ValueIsFilled(vDocumentStatus.SMSTemplate) Then
			rError = NStr("en = 'SMS message template is not specified!'; de = 'Das Muster für den SMS-Verteiler ist nicht festgelegt!'; ru = 'Не определен шаблон для рассылки СМС!'");
			Return True;
		EndIf;
		vDoNotSendSMS = False;
		If vDocumentStatus.DeliveryType = Enums.DeliveryTypes.SMS Or vDocumentStatus.DeliveryType = Enums.DeliveryTypes.Both Then
			If Not IsSMSDeliveryActive() Then
				If vDocumentStatus.DeliveryType = Enums.DeliveryTypes.Both Then
					vDoNotSendSMS = True;
				Else
					rError = NStr("en = 'SMS delivery is not initialized!'; de = 'Der Versand von SMS Mitteilungen ist nicht eingerichtet!'; ru = 'Рассылка СМС сообщений не настроена!'");
					Return True;
				EndIf;
			EndIf;
		ElsIf vDocumentStatus.DeliveryType = Enums.DeliveryTypes.DoNotSend Then
			rError = NStr("en = 'Messages delivery is switched off for template '; de = 'Der Versand von Mitteilungen ist ausschalten für Verteiler '; ru = 'Рассылка сообщений отключена для шаблона '") + vDocumentStatus.SMSTemplate;
			Return True;
		EndIf;
		If Not ValueIsFilled(pDocRef.Guest) Then
			rError = NStr("en = 'Guest is not specified!'; de = 'Im Dokument ist kein Gast angegeben!'; ru = 'В документе не указан гость!'");
			Return True;
		EndIf;
		vLanguage = pDocRef.Hotel.Language;
		If ValueIsFilled(pDocRef.Guest.Language) Then
			vLanguage = pDocRef.Guest.Language;
		EndIf;
		If vDocumentStatus.DeliveryType = Enums.DeliveryTypes.SMS Or vDocumentStatus.DeliveryType = Enums.DeliveryTypes.Both And Not vDoNotSendSMS Then
			vPhone = GetValidPhoneNumber(pDocRef.Phone);
			If IsBlankString(vPhone) Then
				vPhone = GetValidPhoneNumber(pDocRef.Guest.Phone);
				If ValueIsFilled(pDocRef.Guest) Then
					vPhone = TrimAll(pDocRef.Guest.Phone);
				EndIf;
				If IsBlankString(vPhone) Then
					If ValueIsFilled(pDocRef.Customer) And pDocRef.Customer.IsIndividual Then
						vPhone = TrimAll(pDocRef.Customer.Phone);
					EndIf;
				EndIf;
			EndIf;
			If IsBlankString(vPhone) Then
				rError = NStr("en = 'Guest phone number is not specified!'; de = 'Bei dem Gast ist keine Telefonnummer angegeben!'; ru = 'У гостя не указан номер телефона!'");
			Else
				// Check if this message was already sent
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	COUNT(*) AS SMSCount
				|FROM
				|	InformationRegister.SMSMessages AS SMSMessages
				|WHERE
				|	SMSMessages.Phone = &qPhone
				|	AND SMSMessages.DocumentStatus = &qDocumentStatus
				|	AND SMSMessages.Period >= &qPeriodFrom
				|	AND SMSMessages.Period <= &qPeriodTo";
				vQry.SetParameter("qPeriodFrom", pDocRef.Date);
				vQry.SetParameter("qPeriodTo", pDocRef.CheckOutDate);
				vQry.SetParameter("qPhone", vPhone);
				vQry.SetParameter("qDocumentStatus", vDocumentStatus);
				If vQry.Execute().Unload().Get(0).SMSCount > 0 Then
					rError = NStr("en = 'SMS message was already sent!'; de = 'SMS wurde schon versandt!'; ru = 'СМС уже был отправлен!'");
				Else
					// Get message text
					vSMSTemplate = vDocumentStatus.SMSTemplate;
					vSMSText = ReplaceSMSParameters(GetSMSTextByLanguage(vSMSTemplate, vLanguage), pDocRef);
					// Send message
					vResult = SendMessage(vSMSText, vPhone, vSMSTemplate, TrimR(vSMSTemplate.Sender), pDocRef.Guest, pDocRef,, vDocumentStatus, rError, , , "10-22");
					If Not vResult Then
						If vDocumentStatus.DeliveryType = Enums.DeliveryTypes.SMS Then
							Return vResult;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If vDocumentStatus.DeliveryType = Enums.DeliveryTypes.EMail Or vDocumentStatus.DeliveryType = Enums.DeliveryTypes.Both Then
			If ValueIsFilled(pDocRef.Customer) Then
				vEMail = pDocRef.Customer.EMail;
				vSendEMail = True;
			EndIf;			
			If Not ValueIsFilled(vEMail) Then
				vEMail = pDocRef.EMail;
				vSendEMail = True;
			EndIf;
			If Not ValueIsFilled(vEMail) And ValueIsFilled(pDocRef.Guest) Then
				vEMail = pDocRef.Guest.EMail;
				vSendEMail = True;	
			EndIf;			
			If IsBlankString(vEMail) Then
				rError = NStr("en = 'Guest e-mail is not specified!'; de = 'Bei dem Gast ist keine E-Mail angegeben!'; ru = 'У гостя не указан e-mail!'");
			Else
				// Get message text
				vMessageTemplate = vDocumentStatus.SMSTemplate;
				vMessageSubject = "";
				vMessageText = "";
				If ValueIsFilled(vMessageTemplate) Then
					vMessageSubject = cmNStr(TrimAll(vMessageTemplate.Description), vLanguage);
					If Not IsBlankString(vMessageTemplate.HTMLTextRu) Or Not IsBlankString(vMessageTemplate.HTMLTextEn) Or Not IsBlankString(vMessageTemplate.HTMLTextDe) Then
						vMessageText = GetHTMLTextByLanguage(vMessageTemplate, vLanguage);
					EndIf;
					If IsBlankString(vMessageText) Then
						vMessageText = GetSMSTextByLanguage(vMessageTemplate, vLanguage);
					EndIf;
				EndIf;
				// Check if this message was already sent
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	COUNT(*) AS EMailCount
				|FROM
				|	InformationRegister.GuestGroupAttachments AS EMailMessages
				|WHERE
				|	EMailMessages.EMail = &qEMail
				|	AND EMailMessages.GuestGroup = &qGuestGroup
				|	AND (CAST(EMailMessages.Remarks AS STRING(100))) = &qEMailSubject";
				vQry.SetParameter("qEMail", vEMail);
				vQry.SetParameter("qEMailSubject", vMessageSubject);
				vQry.SetParameter("qGuestGroup", pDocRef.GuestGroup);
				If vQry.Execute().Unload().Get(0).EMailCount > 0 Then
					rError = NStr("en = 'E-Mail message was already sent!'; de = 'Die E-Mail wurde bereits verschickt!'; ru = 'E-Mail уже был отправлен!'");
				Else
					// Get document print form
					vPrintFormFileName = "";
					vPrintFormFilePath = "";
					vObjectPrintForm = Undefined;
					If ValueIsFilled(vDocumentStatus) Then
						If ValueIsFilled(vDocumentStatus.PrintFormRu) Then
							vObjectPrintForm = vDocumentStatus.PrintFormRu;
						EndIf;
						If vLanguage = Catalogs.Languages.EN And ValueIsFilled(vDocumentStatus.PrintFormEn) Then
							vObjectPrintForm = vDocumentStatus.PrintFormEn;
						ElsIf vLanguage = Catalogs.Languages.DE And ValueIsFilled(vDocumentStatus.PrintFormDe) Then
							vObjectPrintForm = vDocumentStatus.PrintFormDe;
						EndIf;
					EndIf;
					If Not ValueIsFilled(vObjectPrintForm) Then
						If ValueIsFilled(vMessageTemplate) And vMessageTemplate.AttachDocumentPrintFormToEMail Then
							If ValueIsFilled(vMessageTemplate.ObjectPrintingFormRu) Then
								vObjectPrintForm = vMessageTemplate.ObjectPrintingFormRu;
							EndIf;
							If vLanguage = Catalogs.Languages.EN And ValueIsFilled(vMessageTemplate.ObjectPrintingFormEn) Then
								vObjectPrintForm = vMessageTemplate.ObjectPrintingFormEn;
							ElsIf vLanguage = Catalogs.Languages.DE And ValueIsFilled(vMessageTemplate.ObjectPrintingFormDe) Then
								vObjectPrintForm = vMessageTemplate.ObjectPrintingFormDe;
							EndIf;
							If Not ValueIsFilled(vObjectPrintForm) Then
								vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRu;
								If vLanguage = Catalogs.Languages.EN Then
									vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationEn;
								ElsIf vLanguage = Catalogs.Languages.DE Then
									vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationDe;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If ValueIsFilled(vObjectPrintForm) And ValueIsFilled(pDocRef) And TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
						vDocObj = pDocRef.GetObject();
						vPrintFormSpreadsheet = New SpreadsheetDocument();
						If ValueIsFilled(vObjectPrintForm.ExternalProcessing) Then
							vExtDataProcessor = cmGetExternalDataProcessorObject(vObjectPrintForm.ExternalProcessing);
							vExtDataProcessor.pmPrintConfirmation(vPrintFormSpreadsheet, pDocRef, Undefined, 0, Catalogs.ServiceGroups.EmptyRef(), False, vLanguage, vObjectPrintForm);
						ElsIf ValueIsFilled(vObjectPrintForm.Report) Then
							vRepObj = cmBuildReportObject(vObjectPrintForm.Report);
							If vRepObj <> Undefined Then
								// Fill reference to the report catalog item
								vRepObj.Report = vObjectPrintForm.Report;
								// Load report catalog item attributes
								vRepObj.pmLoadReportAttributes(pDocRef);
								// Generate print form
								vRepObj.pmGenerate(vPrintFormSpreadsheet);
							EndIf;
						Else
							If vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationWithServicesRu Or
							   vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationWithServicesEn Or
							   vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationWithServicesDe Or
							   vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationWithServicesRu Or
							   vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationWithServicesEn Or
							   vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationWithServicesDe Then
								vDocObj.pmPrintConfirmationWithServices(vPrintFormSpreadsheet, pDocRef, Undefined, 0, Catalogs.ServiceGroups.EmptyRef(), False, vLanguage, vObjectPrintForm);
							ElsIf vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCancellationRu Or
							      vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCancellationEn Or
							      vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCancellationDe Then
								vDocObj.pmPrintCancellation(vPrintFormSpreadsheet, pDocRef, Undefined, False, vLanguage, vObjectPrintForm);
							ElsIf vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationRu Or
							      vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationEn Or
							      vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationDe Then
								vDocObj.pmPrintExpressCheckInInvitation(vPrintFormSpreadsheet, pDocRef, Undefined, False, vLanguage, vObjectPrintForm);
							ElsIf vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintPaymentOrder Then
								vDocObj.pmPrintPaymentOrder(vPrintFormSpreadsheet, pDocRef, pDocRef.GetObject(), Undefined, Undefined, vLanguage, vObjectPrintForm);
							Else
								vDocObj.pmPrintConfirmation(vPrintFormSpreadsheet, pDocRef, Undefined, 0, Catalogs.ServiceGroups.EmptyRef(), False, vLanguage, vObjectPrintForm);
							EndIf;
						EndIf;
						vResFileNumber = "";
						If Find(vObjectPrintForm.Parameter, "USE_INDIVIDUAL_RESERVATION_NUMBER_FOR_FILE") > 0 Then
							vResFileNumber = vDocObj.Number;
						Else
							vResFileNumber = Format(vDocObj.GuestGroup.Code, "ND=12; NFD=0; NG=");
						Endif;
						// Save reservation confirmation to the temp PDF file
						vPrintFormFileName = StrReplace(pDocRef.Metadata().Presentation() + " " + vResFileNumber, " ", "_") + ".pdf";
						vPrintFormFilePath = cmGetFullFileName(vPrintFormFileName, TempFilesDir());
						vPrintFormSpreadsheet.Write(vPrintFormFilePath, SpreadsheetDocumentFileType.PDF);
					EndIf;
					// Send E-Mail message
					InformationRegisters.GuestGroupAttachments.WriteData(, pDocRef.GuestGroup,,,,,, vEMail,, Enums.AttachmentTypes.EMail, Enums.AttachmentStatuses.Ready, vMessageText, vMessageTemplate, pDocRef,,, vPrintFormFilePath, vPrintFormFileName, True, vMessageSubject);            
				EndIf;
			EndIf;
		EndIf;
	Except
		rError = cmGetRootErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	Return True;
EndFunction // SendChangeDocumentSatusMessage

// --------------------------------------------------------------------------------------------------------------
Function SendPaymentMessage(pPayer, pGuestGroup, pDocRef, pAmountStr, pPaymentMethod, pPaymentRef, rError = "") Export
	rError = "";
	Try
		If Not IsSMSDeliveryActive() Then
			rError = NStr("en = 'SMS delivery is not initialized!'; de = 'Der Versand von SMS Mitteilungen ist nicht eingerichtet!'; ru = 'Рассылка СМС сообщений не настроена!'");
			Return True;
		EndIf;
		If Not ValueIsFilled(pPaymentMethod) Then
			rError = NStr("en = 'Payment method is not specified!'; de = 'Die Zahlungsmethode ist nicht festgelegt!'; ru = 'Не определен способ оплаты!'");
			Return True;
		EndIf;
		If Not ValueIsFilled(pPaymentMethod.SMSTemplate) Then
			rError = NStr("en = 'SMS message template is not specified!'; de = 'Das Muster für den SMS-Verteiler ist nicht festgelegt!'; ru = 'Не определен шаблон для рассылки СМС!'");
			Return True;
		EndIf;
		If ValueIsFilled(pGuestGroup) And pGuestGroup.CheckOutDate < CurrentSessionDate() Then
			rError = NStr("en = 'Current time is after guest check-out!'; de = 'Aktuelle Zeit ist später als die Abreisezeit des Gastes!'; ru = 'Текущее время позже времени выезда гостя!'");
			Return True;
		EndIf;
		If Not ValueIsFilled(pPayer) Then
			rError = NStr("en = 'Payer is not specified!'; de = 'Im Dokument ist kein Zahler angegeben!'; ru = 'В документе не указан плательщик!'");
			Return True;
		EndIf;
		If Not ValueIsFilled(pDocRef) Or ValueIsFilled(pDocRef) And TypeOf(pDocRef) <> Type("DocumentRef.Accommodation") And TypeOf(pDocRef) <> Type("DocumentRef.Reservation") Then
			rError = NStr("en='Document is not specified!';ru='Документ не указан!';de='Das Dokument wurde nicht angegeben!'");
			Return True;
		EndIf;
		vLanguage = pDocRef.Hotel.Language;
		If ValueIsFilled(pPayer.Language) Then
			vLanguage = pPayer.Language;
		EndIf;
		If pPaymentMethod.DeliveryType = Enums.DeliveryTypes.SMS Or pPaymentMethod.DeliveryType = Enums.DeliveryTypes.Both Then
			vPhone = "";
			If ValueIsFilled(pPaymentRef) And ValueIsFilled(pPaymentRef.Hotel) And ValueIsFilled(pPaymentRef.AccountingCustomer) And 
			   Not pPaymentRef.AccountingCustomer.IsIndividual Then
				If ValueIsFilled(pPaymentRef.AccountingCustomer) Then
					vPhone = GetValidPhoneNumber(pPaymentRef.AccountingCustomer.Phone);
				EndIf;
			Else
				If IsBlankString(vPhone) And ValueIsFilled(pDocRef) Then
					vPhone = GetValidPhoneNumber(pDocRef.Phone);
				EndIf;
				If IsBlankString(vPhone) And ValueIsFilled(pPayer) Then
					vPhone = GetValidPhoneNumber(pPayer.Phone);
				EndIf;
				If IsBlankString(vPhone) And ValueIsFilled(pDocRef.Guest) Then
					vPhone = GetValidPhoneNumber(pDocRef.Guest.Phone);
				EndIf;
			EndIf;
			If IsBlankString(vPhone) Then
				rError = NStr("en='Payer phone number is not specified!';ru='У плательщика не указан номер телефона!';de='Bei dem Zahlungspflichtigen ist keine Telefonnummer angegeben!'");
			Else
				// Get message text
				vGuest = pDocRef.Guest;
				If ValueIsFilled(pPayer) And TypeOf(pPayer) = Type("CatalogRef.Clients") Then
					vGuest = pPayer;
				EndIf;
				vSMSTemplate = pPaymentMethod.SMSTemplate;
				vSMSText = ReplaceSMSParameters(GetSMSTextByLanguage(vSMSTemplate, vLanguage), pDocRef, vGuest, pAmountStr);
				// Send message
				vResult = SendMessage(vSMSText, vPhone, vSMSTemplate, TrimR(vSMSTemplate.Sender), vGuest, pDocRef, , , rError);
				If Not vResult Then
					Return vResult;
				EndIf;
			EndIf;
		EndIf;
		If pPaymentMethod.DeliveryType = Enums.DeliveryTypes.EMail Or pPaymentMethod.DeliveryType = Enums.DeliveryTypes.Both Then
			vEMail = "";
			If ValueIsFilled(pPaymentRef) And ValueIsFilled(pPaymentRef.Hotel) And ValueIsFilled(pPaymentRef.AccountingCustomer) And 
			   Not pPaymentRef.AccountingCustomer.IsIndividual Then
				If ValueIsFilled(pPaymentRef.AccountingCustomer) Then
					vEMail = TrimAll(pPaymentRef.AccountingCustomer.EMail);
				EndIf;
			Else
				If IsBlankString(vEMail) And ValueIsFilled(pDocRef) Then
					vEMail = TrimAll(pDocRef.EMail);
				EndIf;
				If IsBlankString(vEMail) And ValueIsFilled(pPayer) Then
					vEMail = TrimAll(pPayer.EMail);
				EndIf;
				If IsBlankString(vEMail) And ValueIsFilled(pDocRef.Guest) Then
					vEMail = TrimAll(pDocRef.Guest.EMail);
				EndIf;
			EndIf;
			If IsBlankString(vEMail) Then
				rError = NStr("en='Payer e-mail is not specified!';ru='У плательщика не указан e-mail!';de='Bei dem Zahlungspflichtigen ist keine E-Mail angegeben!'");
			Else
				// Get message text
				vMessageSubject = String(pPaymentRef);
				vMessageText = "";
				vMessageTemplate = pPaymentMethod.SMSTemplate;
				If ValueIsFilled(vMessageTemplate) Then
					vMessageSubject = cmNStr(TrimAll(vMessageTemplate.Description), vLanguage);
					vMessageSubject = vMessageSubject + " (" + String(pPaymentRef) + ")";
					If Not IsBlankString(vMessageTemplate.HTMLTextRu) Or Not IsBlankString(vMessageTemplate.HTMLTextEn) Or Not IsBlankString(vMessageTemplate.HTMLTextDe) Then
						vMessageText = GetHTMLTextByLanguage(vMessageTemplate, vLanguage);
					EndIf;
					If IsBlankString(vMessageText) Then
						vMessageText = GetSMSTextByLanguage(vMessageTemplate, vLanguage);
					EndIf;
				EndIf;
				// Check if this message was already sent
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	COUNT(*) AS EMailCount
				|FROM
				|	InformationRegister.GuestGroupAttachments AS EMailMessages
				|WHERE
				|	EMailMessages.EMail = &qEMail
				|	AND EMailMessages.GuestGroup = &qGuestGroup
				|	AND (CAST(EMailMessages.Remarks AS STRING(100))) = &qEMailSubject";
				vQry.SetParameter("qEMail", vEMail);
				vQry.SetParameter("qEMailSubject", vMessageSubject);
				vQry.SetParameter("qGuestGroup", pGuestGroup);
				If vQry.Execute().Unload().Get(0).EMailCount > 0 Then
					rError = NStr("en='E-Mail message was already sent!';ru='E-Mail уже был отправлен!';de='Die E-Mail wurde bereits verschickt!'");
				Else
					// Send E-Mail message					
					InformationRegisters.GuestGroupAttachments.WriteData(, pGuestGroup,, pDocRef.Guest,,,, vEMail,, Enums.AttachmentTypes.EMail, Enums.AttachmentStatuses.Ready, vMessageText, vMessageTemplate, pDocRef,, pAmountStr,,,, vMessageSubject);          	
				EndIf;
			EndIf;
		EndIf;		
	Except
		rError = cmGetRootErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	Return True;
EndFunction // SendPaymentMessage

// --------------------------------------------------------------------------------------------------------------
Function SendChargeMessage(pDocRef, pSmsTemplate, pPayer, rError = "", pPhone) Export
	rError = "";
	Try
		If Not IsSMSDeliveryActive() Then
			rError = NStr("en='SMS delivery is not initialized!';ru='Рассылка СМС сообщений не настроена!';de='Der Versand von SMS Mitteilungen ist nicht eingerichtet!'");
			Return False;
		EndIf;
		If Not ValueIsFilled(pSmsTemplate) Then
			rError = NStr("en='SMS message template is not specified!';ru='Не определен шаблон для рассылки СМС!';de='Das Muster für den SMS-Verteiler ist nicht festgelegt!'");
			Return False;
		EndIf;
		If Not ValueIsFilled(pDocRef) Or (ValueIsFilled(pDocRef) And TypeOf(pDocRef) <> Type("DocumentRef.Charge")) Then
			rError = NStr("en='Document is not specified!';ru='Документ не указан!';de='Das Dokument wurde nicht angegeben!'");
			Return False;
		EndIf;
		If Not ValueIsFilled(pPayer) Then
			rError = NStr("en='Payer is not specified!';ru='В документе не указан плательщик!';de='Im Dokument ist kein Zahler angegeben!'");
			Return False;
		EndIf;
		If pPayer.NoSMSDelivery Then
			rError = NStr("en = 'Guest refused to receive SMS!'; de = 'Gast weigerte sich, SMS zu empfangen!'; ru = 'Гость отказался от смс рассылки!'");
			Return False;
		EndIf;
		vLanguage = pDocRef.Hotel.Language;
		If ValueIsFilled(pPayer.Language) Then
			vLanguage = pPayer.Language;
		EndIf;
		vPhone = "";
		vCustomer = pDocRef.Folio.Customer;
		If ValueIsFilled(pDocRef) And ValueIsFilled(pDocRef.Hotel) And ValueIsFilled(vCustomer) And Not vCustomer.IsIndividual Then
			If ValueIsFilled(vCustomer) Then
				vPhone = GetValidPhoneNumber(vCustomer.Phone);
			EndIf;
		Else
			If IsBlankString(vPhone) And ValueIsFilled(pPayer) Then
				vPhone = GetValidPhoneNumber(pPayer.Phone);
			EndIf;
		EndIf;
		pPhone = vPhone;
		If IsBlankString(vPhone) Then
			rError = NStr("en='Payer phone number is not specified!';ru='У плательщика не указан номер телефона!';de='Bei dem Zahlungspflichtigen ist keine Telefonnummer angegeben!'");
		Else
			// Fill charge sum
			vChargeSum = cmFormatSum(pDocRef.Sum - pDocRef.DiscountSum, pDocRef.FolioCurrency,"NZ=");
			// Get message text
			vSMSText = ReplaceSMSParameters(GetSMSTextByLanguage(pSmsTemplate, vLanguage), pDocRef, pPayer, vChargeSum);
			// Send message
			vResult = SendMessage(vSMSText, vPhone, pSMSTemplate, TrimR(pSmsTemplate.Sender), pPayer, pDocRef, , , rError);
			If Not vResult Then
				Return vResult;
			EndIf;
		EndIf;
	Except
		rError = cmGetRootErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	Return True;
EndFunction	

// --------------------------------------------------------------------------------------------------------------
Procedure SendDefferedSMS() Export
	vQry = New Query;
	vQry.Text = 
	"SELECT DISTINCT
	|	AllMessages.Ref AS Ref,
	|	AllMessages.Remarks AS Remarks,
	|	AllMessages.Phones AS Phones,
	|	AllMessages.Employee AS Employee
	|FROM
	|	(SELECT
	|		Messages.Recorder AS Ref,
	|		CAST(Messages.Remarks AS STRING(1024)) AS Remarks,
	|		Employees.Phones AS Phones,
	|		Employees.Ref AS Employee
	|	FROM
	|		InformationRegister.Messages AS Messages
	|			INNER JOIN Catalog.Employees AS Employees
	|			ON Messages.ForDepartment = Employees.Department
	|				AND (Messages.ForDepartment <> &qEmptyDepartment)
	|	WHERE
	|		NOT Messages.IsClosed
	|		AND Messages.Recorder.SendBySMS
	|		AND NOT Messages.Recorder.SMSIsSent
	|		AND Messages.ValidFromDate <> &qEmptyDate
	|		AND Messages.ValidFromDate <= &qCurrentDate
	|		AND Messages.ForDepartment <> &qEmptyDepartment
	|		AND Employees.Phones <> &qBlankString
	|		AND Employees.DeletionMark = FALSE
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Messages.Recorder,
	|		CAST(Messages.Remarks AS STRING(1024)),
	|		Messages.ForEmployee.Phones,
	|		Messages.ForEmployee
	|	FROM
	|		InformationRegister.Messages AS Messages
	|	WHERE
	|		NOT Messages.IsClosed
	|		AND Messages.Recorder.SendBySMS
	|		AND NOT Messages.Recorder.SMSIsSent
	|		AND Messages.ValidFromDate <> &qEmptyDate
	|		AND Messages.ValidFromDate <= &qCurrentDate
	|		AND Messages.ForEmployee <> &qEmptyEmployee
	|		AND Messages.ForEmployee.Phones <> &qBlankString) AS AllMessages
	|
	|ORDER BY
	|	AllMessages.Ref.Date";
	vQry.SetParameter("qEmptyDate", "00010101");
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vQry.SetParameter("qBlankString", "");
	vQry.SetParameter("qEmptyEmployee", Catalogs.Employees.EmptyRef());
	vQry.SetParameter("qEmptyDepartment", Catalogs.Departments.EmptyRef());
	vPhoneNumberChoice = vQry.Execute().Select();
	While vPhoneNumberChoice.Next() Do
		vError = "";
		vCommaPosition = Find(vPhoneNumberChoice.Phones, ",");
		If SMS.SendMessage(vPhoneNumberChoice.Remarks, ?(vCommaPosition = 0, SMS.GetValidPhoneNumber(vPhoneNumberChoice.Phones), SMS.GetValidPhoneNumber(Left(vPhoneNumberChoice.Phones, vCommaPosition - 1))), , , , , vPhoneNumberChoice.Employee, , vError) Then
			If ValueIsFilled(vPhoneNumberChoice.Ref) Then
				vMessagesObj = vPhoneNumberChoice.Ref.GetObject();
				vMessagesObj.SMSIsSent = True;
				vMessagesObj.Write(DocumentWriteMode.Write);
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(vError);
		EndIf;
	EndDo;
EndProcedure // SendDefferedSMS

// --------------------------------------------------------------------------------------------------------------
Function GetSentMessageData(pMessageId, pPhone) Export
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	SMSMessages.Period AS Period,
	|	SMSMessages.MessageID AS MessageID,
	|	SMSMessages.Phone AS Phone,
	|	SMSMessages.Text AS Text,
	|	SMSMessages.Quantity AS Quantity,
	|	SMSMessages.Cost AS Cost,
	|	SMSMessages.Result AS Result,
	|	SMSMessages.Status AS Status,
	|	SMSMessages.Sender AS Sender,
	|	SMSMessages.SMSTemplate AS SMSTemplate,
	|	SMSMessages.Client AS Client,
	|	SMSMessages.ClientDoc AS ClientDoc,
	|	SMSMessages.Customer AS Customer,
	|	SMSMessages.Employee AS Employee,
	|	SMSMessages.DocumentStatus AS DocumentStatus
	|FROM
	|	InformationRegister.SMSMessages AS SMSMessages
	|WHERE
	|	SMSMessages.MessageID = &qMessageID
	|	AND SMSMessages.Phone = &qPhone
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qMessageID", TrimAll(pMessageID));
	vQry.SetParameter("qPhone", TrimAll(pPhone));
	vMessages = vQry.Execute().Unload();
	Return vMessages;
EndFunction // GetSentMessageData

// --------------------------------------------------------------------------------------------------------------
Procedure AutoDelivery(pHotel, pSender, pDeliveryTemplate, pMessageTemplate, pDeliveryType, pDeliveryFilter = "", pNumberOfDays = 0, pImportantDateType = Undefined) Export
	vDPObj = DataProcessors.AutoSMSDelivery.Create();
	vDPObj.Hotel = pHotel;
	vDPObj.Sender = pSender;
	vDPObj.AccountingDate = BegOfDay(CurrentSessionDate());
	vDPObj.DeliveryTemplate = pDeliveryTemplate;
	vDPObj.DeliveryType = pDeliveryType;
	vDPObj.DeliveryFilter = pDeliveryFilter;
	vDPObj.MessageTemplate = pMessageTemplate;
	vDPObj.NumberOfDays = pNumberOfDays; 
	vDPObj.ImportantDateType = pImportantDateType;
	vDPObj.pmRun(Undefined, False);
EndProcedure // AutoDelivery

// --------------------------------------------------------------------------------------------------------------
Function GetSMSTextByLanguage(pTemplate, Val pLanguage = Undefined) Export
	If Not ValueIsFilled(pLanguage) Then
		pLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	If pLanguage = Catalogs.Languages.RU Then
		Return TrimAll(pTemplate.SMSTextRu);
	ElsIf pLanguage = Catalogs.Languages.EN Then
		Return TrimAll(pTemplate.SMSTextEn);
	ElsIf pLanguage = Catalogs.Languages.DE Then
		Return TrimAll(pTemplate.SMSTextDe);
	Else
		Return TrimAll(pTemplate.SMSTextRu);
	EndIf;
EndFunction // GetSMSTextByLanguage

// --------------------------------------------------------------------------------------------------------------
Function GetHTMLTextByLanguage(pTemplate, Val pLanguage = Undefined) Export
	If Not ValueIsFilled(pLanguage) Then
		pLanguage = SessionParameters.CurrentLanguage;
	EndIf; 
	vEmptyHTMLBody1 = 
	"<body>
	|</body>";
	vEmptyHTMLBody2 = 
	"<body>
	|<p><br></p>
	|</body>";
	vMessageText = "";
	If pLanguage = Catalogs.Languages.RU Then
		vMessageText = TrimAll(pTemplate.HTMLTextRu);
	ElsIf pLanguage = Catalogs.Languages.EN Then
		vMessageText = TrimAll(pTemplate.HTMLTextEn);
	ElsIf pLanguage = Catalogs.Languages.DE Then
		vMessageText = TrimAll(pTemplate.HTMLTextDe);
	Else
		vMessageText = TrimAll(pTemplate.HTMLTextRu);
	EndIf;
	If Not IsBlankString(vMessageText) And 
	  (StrFind(vMessageText, vEmptyHTMLBody1) > 0 Or StrFind(vMessageText, vEmptyHTMLBody2) > 0) Then
		vMessageText = "";
	EndIf;
	Return vMessageText;
EndFunction // GetHTMLTextByLanguage

// --------------------------------------------------------------------------------------------------------------
// gets the latest MessageId and adds +1 
// the function is used for consecutative numbering for services which don't return message id
Function GetNextMessageID() Export
	vQ = New Query("SELECT TOP 1
	               |	SMSMessages.MessageID AS MessageID
	               |FROM
	               |	InformationRegister.SMSMessages AS SMSMessages
	               |
	               |ORDER BY
	               |	MessageID DESC");
	qRes = vQ.Execute().Select();
	vMessageID = 0;
	If qRes.Next() Then
		Try
			vMessageID = Number(qRes.MessageID);
		Except
			vMessageID = 0;
		EndTry;
	EndIf;
	vMessageID = vMessageID + 1;
	Return Format(vMessageID, "ND=20; NFD=0; NLZ=; NG=");
EndFunction

#EndRegion          

#EndRegion
