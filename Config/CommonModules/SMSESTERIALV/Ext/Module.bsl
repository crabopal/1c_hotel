// --------------------------------------------------------------------------------------------------------------
// API for SMS_ESTERIA_LV
// --------------------------------------------------------------------------------------------------------------

#Region Public

// --------------------------------------------------------------------------------------------------------------
//
// Parameters:
//  pLogin			 - String	 - Login
//  pPassword		 - String	 - Password
//  pPhones			 - String	 - Phones
//  pMessage		 - String	 - Message
//  pSender			 - String	 - Sender
//  pDeliveryDate	 - String	 - Delivery date
// 
// Returns:
//  Structure - Result
//
Function SendSMS(pLogin, pPassword, pPhones, pMessage, pSender, pDeliveryDate = "") Export
	vMessage = "";
	vStruct = New Structure("Success, MessageID, NumberOfSegments, Cost, Balance, Result, ErrorDescription", False, "", 0, 0, 0, "", "");
	
	pSender = TrimAll(Constants.SMSSenderName.Get());
	
	vRequest = StrTemplate("send?api-key=%1&sender=%2&number=%3&text=%4", SMS.URLEncode(pPassword), SMS.URLEncode(pSender), SMS.URLEncode(pPhones), SMS.URLEncode(pMessage));
	rSMSID = Format(CurrentSessionDate(),"DF=yyyyMMddHHmmss")+"-"+Right(pPhones, 5);
	
	
	vResult = SendCommand(vRequest, vMessage, rSMSID);
	If Not vResult Then
		vStruct.Success = False;
		vStruct.ErrorDescription = vMessage;
		Return vStruct;
	EndIf;
	
	vStruct.Success = True;
	vStruct.MessageID = rSMSID;
	vStruct.NumberOfSegments = SMS.GetNumberOfSegments(pMessage);
	vStruct.Cost = 0;
	vStruct.Balance = 0;
	vStruct.Result = "OK";
	
	Return vStruct;
EndFunction // SendSMS

// --------------------------------------------------------------------------------------------------------------
//
// Parameters:
//  pLogin		 - String	 - Login
//  pPassword	 - String	 - Password
//  pMessageID	 - String	 - Message ID
//  pPhone		 - String	 - Phones
// 
// Returns:
//  Structure - Result
//
Function GetStatus(pLogin, pPassword, pMessageID, pPhone) Export
	Return New Structure("Success, Status, Result, ErrorDescription", False, "", "", "");
EndFunction // GetStatus

// --------------------------------------------------------------------------------------------------------------
//
// Parameters:
//  pLogin				 - String	 - Login
//  pPassword			 - String	 - Password
//  rErrorCode			 - Number	 - Error code
//  rErrorDescription	 - String	 - Error description
// 
// Returns:
//  Structure - Result
//
Function GetBalance(pLogin, pPassword, rErrorCode, rErrorDescription) Export
	rErrorCode = "";
	rErrorDescription = "";
	Return 0;
EndFunction // GetBalance

#EndRegion

#Region Private

// --------------------------------------------------------------------------------------------------------------
Function HTTPSend(pRequest)
	vResult = New Structure("StatusCode, Body, Error", 200, "", "");
	
	Try
		vHTTPConnection = New HTTPConnection("api.esteria.eu", , , , , , New OpenSSLSecureConnection(Undefined, Undefined));
		vHTTPRequest = New HTTPRequest(pRequest);
		vResponse = vHTTPConnection.CallHTTPMethod("GET", vHTTPRequest);
		
		vResult.Body = vResponse.GetBodyAsString();
		vResult.StatusCode = vResponse.StatusCode;
	Except
		vResult.StatusCode = 500;
		vResult.Error = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	Return vResult;
EndFunction // HTTPGet

// --------------------------------------------------------------------------------------------------------------
// Call SMS1CHOTEL API. Build URL and try 3 times to read data from server
// --------------------------------------------------------------------------------------------------------------
Function SendCommand(pRequest, rMessage, rSMSID = "")
	rMessage = "";
	
	vResult = HTTPSend(pRequest);
	If vResult.StatusCode <> 200 Then
		rMessage = vResult.Error;
		WriteLogEvent(NStr("en='sms.ErrorSendingRequest'; de='sms.ErrorSendingRequest'; ru='sms.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , pRequest,"status="+vResult.StatusCode+", body="+vResult.Body+"; "+ rMessage);
		Return False;
	EndIf;
	
	vSMSID = 0;
	If Not IsBlankString(vResult.Body) And cmIsNumber(vResult.Body) Then
		vSMSID = Number(vResult.Body);
	EndIf;
	
	If vSMSID <= 100 Then
		rMessage = GetErrorMessage(Number(vResult.Body));
		WriteLogEvent(NStr("en='sms.ErrorSendingRequest'; de='sms.ErrorSendingRequest'; ru='sms.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , pRequest,"status="+vResult.StatusCode+", body="+vResult.Body+"; "+ rMessage);
		Return False;
	EndIf;
	
	rSMSID = Format(vSMSID, "NFD=0; NZ=0; NG=");
	
	Return True;
EndFunction // SendCommand

// --------------------------------------------------------------------------------
Function GetErrorMessage(pCode)
	vMessage = "";
	If pCode = 1 Then
		vMessage = NStr("en = 'Internal system error (INTERNAL ERROR)'; de = 'Interner Systemfehler (INTERNER FEHLER)'; ru = 'Внутренняя ошибка системы (INTERNAL ERROR)'");
	ElsIf pCode = 2 Then
		vMessage = NStr("en = 'One of the required parameters (api-key, sender, number, text) is not specified.'; de = 'Einer der erforderlichen Parameter ist nicht angegeben (api-key, sender, number, text)'; ru = 'Не указан один из обязательных параметров (api-key, sender, number, text)'");
	ElsIf pCode = 3 Then
		vMessage = NStr("en = 'Authorization is not possible: an incorrect api-key has been specified or access is denied'; de = 'Eine Autorisierung ist nicht möglich: Es wird ein falscher API-Schlüssel angegeben oder der Zugriff verweigert'; ru = 'Авторизация невозможна: указан некорректный api-key или доступ закрыт'");
	ElsIf pCode = 4 Then
		vMessage = NStr("en = 'Sending SMS from this IP address is prohibited'; de = 'Das Versenden von SMS von dieser IP-Adresse ist verboten'; ru = 'Запрещена отправка SMS с данного IP адреса'");
	ElsIf pCode = 5 Then
		vMessage = NStr("en = 'The sender number is incorrectly specified. The number length must be from 2 to 11 characters (Latin letters, numbers)'; de = 'Die Absendernummer ist falsch angegeben. Die Länge der Zahl muss zwischen 2 und 11 Zeichen betragen (lateinische Buchstaben, Zahlen).'; ru = 'Некорректно указан номер отправителя (sender). Длина номера должна быть от 2 до 11 символов (латинские буквы, цифры)'");
	ElsIf pCode = 6 Then
		vMessage = NStr("en = 'The specified sender number is prohibited.'; de = 'Die angegebene Absendernummer ist verboten.'; ru = 'Указанный номер отправителя (sender) запрещён.'");
	ElsIf pCode = 7 Then
		vMessage = NStr("en = 'The recipient''s number is incorrect. It must be specified with the country code, without the ""+"" sign. The number must be longer than 8 characters.'; de = 'Die Empfängernummer ist falsch angegeben. Muss mit dem Ländercode ohne das „+“-Zeichen angegeben werden. Die Länge der Nummer muss mehr als 8 Zeichen betragen'; ru = 'Некорректно указан номер получателя (number). Необходимо указывать с кодом страны, без знака «+». Длина номера должна быть больше 8 знаков'");
	ElsIf pCode = 9 Then
		vMessage = NStr("en = 'Text conversion is not possible. The text is not in UTF-8 encoding.'; de = 'Eine Textkonvertierung ist nicht möglich. Der Text liegt nicht in UTF-8-Kodierung vor'; ru = 'Конвертация текста невозможна. Текст указан не в UTF-8 кодировке'");
	ElsIf pCode =11 Then
		vMessage = NStr("en = 'No SMS text specified. SMS with empty text cannot be sent to the recipient.'; de = 'SMS-Text (Text) ist nicht angegeben. Eine SMS mit leerem Text kann nicht an den Empfänger gesendet werden'; ru = 'Не указан текст SMS (text). Получателю не может быть отправлено SMS с пустым текстом'");
	Else
		vMessage = NStr("en = 'Unknown error'; de = 'Unbekannter Fehler'; ru = 'Неизвестная ошибка'");
	EndIf;
	Return vMessage;
EndFunction // GetErrorMessage

#EndRegion
