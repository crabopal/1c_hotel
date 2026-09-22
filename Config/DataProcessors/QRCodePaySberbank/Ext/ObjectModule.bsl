
#Region Public

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
	If Not ValueIsFilled(ScopeCreate) Then
		ScopeCreate = "https://api.sberbank.ru/qr/order.create";
	EndIf;
	If Not ValueIsFilled(ScopeStatus) Then
		ScopeStatus = "https://api.sberbank.ru/qr/order.status";
	EndIf;
	If Not ValueIsFilled(ScopeRevoke) Then
		ScopeRevoke = "https://api.sberbank.ru/qr/order.revoke";
	EndIf;
	If Not ValueIsFilled(ScopeCancel) Then
		ScopeCancel = "https://api.sberbank.ru/qr/order.cancel";
	EndIf;
	If Not ValueIsFilled(GrantType) Then
		GrantType = "client_credentials";
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function GetAccessToken(pScope, rAccessToken, rMessage) Export
	rMessage = "";

	vHeader = New Map;
	vHeader.Insert("Authorization", GetBase64Auth(ExternalInteraction.OAuth_ClientID, ExternalInteraction.OAuth_ClientSecret));
	vHeader.Insert("accept", "application/json"); 
	vHeader.Insert("x-ibm-client-id", TrimAll(ExternalInteraction.OAuth_ClientID));
	vHeader.Insert("RqUID", StrReplace(New UUID(), "-", ""));
	vHeader.Insert("content-type", "application/x-www-form-urlencoded");
	
	vDataArr = New Array;
	vDataArr.Add("grant_type=" + ?(ValueIsFilled(GrantType), TrimAll(GrantType), "client_credentials"));
	vDataArr.Add("scope=" + TrimAll(pScope));
	vData = StrConcat(vDataArr, "&");
	
	vResponse = Undefined;
	If Not SendQuery(vData, "oauth", vHeader, True, vResponse) Then
		rMessage = vResponse; 
		Return False;
	EndIf;
	
	rAccessToken = vResponse["access_token"];
	Return True;
EndFunction // GetAccessToken

// -----------------------------------------------------------------------------
Function StartExternalPayment(pDocument, rMessage) Export
	If pDocument.Sum = 0 Then
		rMessage = NStr("ru = 'Не указана сумма операции!'; en = 'Zero amount operation is not possible!'; de = 'Null-Summen-Operation nicht möglich ist!'");
		Return False;
	EndIf;
	
	vMemberID = SessionParameters.CurrentWorkstation.MemberID; 
	If Not ValueIsFilled(vMemberID) Then
		rMessage = NStr("en = 'Member ID is blank'; de = 'Mitglieds-ID ist leer'; ru = 'Идентификатор клиента не заполнен'");
		Return False;
	EndIf;
	
	vDisplayCode = "";
	vCurWorkstation = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vCurWorkstation) Then 
		If vCurWorkstation.HasConnectionToCustomerDisplayParameters Then 
			vCustomerDisplayParameters = vCurWorkstation.CustomerDisplayParameters;
			If ValueIsFilled(vCustomerDisplayParameters) Then
				vDisplayCode = TrimAll(vCustomerDisplayParameters.ID_QR);
			EndIf;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(vDisplayCode) Then
		rMessage = NStr("en = 'Customer display code not specified'; de = 'Kundenanzeigecode nicht angegeben'; ru = 'Код дисплея покупателя не указан'");
		Return False;
	EndIf;
	
	vUUID = Left(TrimAll(StrReplace(New UUID(), "-", "")), 32);
	vDate = CurrentSessionDate();
	
	vAccessToken = "";
	If Not GetAccessToken(?(ValueIsFilled(ScopeCreate), ScopeCreate, "https://api.sberbank.ru/qr/order.create"), vAccessToken, rMessage) Then
		Return False;
	EndIf;
	
	rMessage = "";
	vHeader = New Map;
	
	vHeader.Insert("Authorization", "Bearer " + vAccessToken); 
	vHeader.Insert("Accept", "*/*");
	vHeader.Insert("Content-Type", "application/json");
	vHeader.Insert("RqUID", vUUID);
	
	vParam = New Map;
	
	vParam.Insert("rq_uid", vUUID);
	vParam.Insert("rq_tm", Format(vDate, "DF=yyyy-MM-ddTHH:mm:ssZ"));
	vParam.Insert("member_id", vMemberID);
	vParam.Insert("order_number", cmGetDocumentNumberPresentation(pDocument.Number));
	vParam.Insert("order_create_date", Format(?(ValueIsFilled(pDocument.Date), pDocument.Date, vDate), "DF=yyyy-MM-ddTHH:mm:ssZ"));
	
	vItemArr = New Array();
	For Each vRow In pDocument.PaymentSections Do
		vItem = New Map;
		vItem.Insert("position_name", TrimAll(?(ValueIsFilled(vRow.ChequeService), vRow.ChequeService, vRow.PaymentSection)));
		If Int(vRow.ChequeServiceQuantity) = vRow.ChequeServiceQuantity Then
			vItem.Insert("position_count", vRow.ChequeServiceQuantity);
		EndIf;
		vItem.Insert("position_sum", Int(vRow.ChequeServicePrice * 100));
		vItem.Insert("position_description", TrimAll(?(ValueIsFilled(vRow.ChequeService), vRow.ChequeService, vRow.PaymentSection)));
		vItemArr.Add(vItem);
	EndDo;
	
	vParam.Insert("order_params_type", vItemArr); 
	vParam.Insert("id_qr", vDisplayCode);
	vParam.Insert("order_sum", Int(pDocument.Sum * 100));
	vParam.Insert("currency", TrimAll(pDocument.FolioCurrency.Code));
	vParam.Insert("description", pDocument.Remarks);
	vParam.Insert("sbp_member_id", "100000000111");
	
	vJson = MapToJSON(vParam);
	
	vResponse = Undefined;
	If Not SendQuery(vJson, "creation", vHeader, False, vResponse) Then
		rMessage = vResponse;
		Return False;
	EndIf;
	
	pDocument.OrderURL = vResponse["order_form_url"];
	pDocument.OrderID = vResponse["order_id"];
	Return True;
EndFunction // StartExternalPayment

// -----------------------------------------------------------------------------
Function ReturnExternalPayment(pDocument, rMessage, pIsRefund = False) Export
	If pDocument.Sum = 0 Then
		rMessage = NStr("ru = 'Не указана сумма операции!'; en = 'Zero amount operation is not possible!'; de = 'Null-Summen-Operation nicht möglich ist!'");
		Return False;
	EndIf;
	
	vDisplayCode = "";
	vCurWorkstation = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vCurWorkstation) Then 
		If vCurWorkstation.HasConnectionToCustomerDisplayParameters Then 
			vCustomerDisplayParameters = vCurWorkstation.CustomerDisplayParameters;
			If ValueIsFilled(vCustomerDisplayParameters) Then
				vDisplayCode = TrimAll(vCustomerDisplayParameters.ID_QR);
			EndIf;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(vDisplayCode) Then
		rMessage = NStr("en = 'Customer display code not specified'; de = 'Kundenanzeigecode nicht angegeben'; ru = 'Код дисплея покупателя не указан'");
		Return False;
	EndIf;
	
	vUUID = Left(TrimAll(StrReplace(New UUID(), "-", "")), 32);
	vDate = CurrentSessionDate();
	
	vAccessToken = "";
	If Not GetAccessToken(?(ValueIsFilled(ScopeCancel), ScopeCancel, "https://api.sberbank.ru/qr/order.cancel"), vAccessToken, rMessage) Then
		Return False;
	EndIf;
	
	rMessage = "";
	vHeader = New Map;
	
	vHeader.Insert("Authorization", "Bearer " + vAccessToken);
	vHeader.Insert("Accept", "*/*");
	vHeader.Insert("Content-Type", "application/json");
	vHeader.Insert("RqUID", vUUID);
	
	vParam = New Map;
	
	vParam.Insert("rq_uid", vUUID);
	vParam.Insert("rq_tm", Format(vDate, "DF=yyyy-MM-ddTHH:mm:ssZ"));
	
	vPayment = pDocument.Payment;
	vParam.Insert("order_id", vPayment.OrderID);
	vParam.Insert("operation_id", vPayment.ExternalCode);
	If Not pIsRefund Then
		vParam.Insert("operation_type", "REVERSE");
	Else
		vParam.Insert("operation_type", "REFUND");
	EndIf;
	vParam.Insert("auth_code", vPayment.AuthorizationCode);
	
	vParam.Insert("id_qr", vDisplayCode);
	vParam.Insert("tid", vDisplayCode);
	vParam.Insert("cancel_operation_sum", Int(pDocument.Sum * 100));
	vParam.Insert("operation_currency", TrimAll(pDocument.FolioCurrency.Code));
	vParam.Insert("operation_description", TrimAll(pDocument.Remarks));
	
	vJson = MapToJSON(vParam);
	
	vResponse = Undefined;
	If Not SendQuery(vJson, "cancel", vHeader, False, vResponse, True) Then
		If pIsRefund Then
			rMessage = vResponse;
			Return False;
		EndIf;
		
		Return ReturnExternalPayment(pDocument, rMessage, True);
	EndIf;
	
	pDocument.ExternalCode = vResponse["operation_id"];
	If Number(vResponse["error_code"]) = 0 Then
		pDocument.ReferenceNumber = vResponse["rrn"];
		pDocument.AuthorizationCode = vResponse["auth_code"];
		pDocument.CardOperationDate = XMLValue(Type("Date"), vResponse["operation_date_time"]);
	EndIf;
	
	Return True;
EndFunction // ReturnExternalPayment

// -----------------------------------------------------------------------------
Function RevokeExternalPayment(pDocument, rMessage) Export
	vAccessToken = "";
	If Not GetAccessToken(?(ValueIsFilled(ScopeRevoke), ScopeRevoke, "https://api.sberbank.ru/qr/order.revoke"), vAccessToken, rMessage) Then
		Return False;
	EndIf;
	
	vUUID = Left(TrimAll(StrReplace(New UUID(), "-", "")), 32);
	vDate = CurrentSessionDate();
	
	rMessage = "";
	vHeader = New Map;
	
	vHeader.Insert("Authorization", "Bearer " + vAccessToken);
	vHeader.Insert("Accept", "*/*");
	vHeader.Insert("Content-Type", "application/json");
	vHeader.Insert("RqUID", vUUID);
	
	vParam = New Map;
	
	vParam.Insert("rq_uid", vUUID);
	vParam.Insert("rq_tm", Format(vDate, "DF=yyyy-MM-ddTHH:mm:ssZ"));
	vParam.Insert("order_id", pDocument.OrderID);
	
	vJson = MapToJSON(vParam);
	
	vResponse = Undefined;
	If Not SendQuery(vJson, "revocation", vHeader, False, vResponse) Then
		rMessage = vResponse;
		Return False;
	EndIf;
	
	pDocument.OrderURL = "";
	pDocument.OrderID = "";
	Return True;
EndFunction // RevokeExternalPayment

// -----------------------------------------------------------------------------
Function GetStatusExternalPayment(pDocument, rIsCompleted, pIsPayment, rStatus, rMessage) Export
	vDisplayCode = "";
	vCurWorkstation = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vCurWorkstation) Then
		If vCurWorkstation.HasConnectionToCustomerDisplayParameters Then
			vCustomerDisplayParameters = vCurWorkstation.CustomerDisplayParameters;
			If ValueIsFilled(vCustomerDisplayParameters) Then
				vDisplayCode = TrimAll(vCustomerDisplayParameters.ID_QR);
			EndIf;
		EndIf;
	EndIf;
	
	vAccessToken = "";
	If Not GetAccessToken(?(ValueIsFilled(ScopeStatus), ScopeStatus, "https://api.sberbank.ru/qr/order.status"), vAccessToken, rMessage) Then
		Return False;
	EndIf;
	
	vUUID = Left(TrimAll(StrReplace(New UUID(), "-", "")), 32);
	vDate = CurrentSessionDate();
	
	rMessage = "";
	vHeader = New Map;
	
	vHeader.Insert("Authorization", "Bearer " + vAccessToken);
	vHeader.Insert("Accept", "*/*");
	vHeader.Insert("Content-Type", "application/json");
	vHeader.Insert("RqUID", vUUID);
	
	vParam = New Map;
	
	vParam.Insert("rq_uid", vUUID);
	vParam.Insert("rq_tm", Format(vDate, "DF=yyyy-MM-ddTHH:mm:ssZ"));
	vParam.Insert("order_id", pDocument.OrderID); 
	vParam.Insert("tid", vDisplayCode);
	vParam.Insert("partner_order_number", cmGetDocumentNumberPresentation(pDocument.Number));
	
	vJson = MapToJSON(vParam);
	
	vResponse = Undefined;
	If Not SendQuery(vJson, "status", vHeader, False, vResponse) Then
		rMessage = vResponse;
		Return False;
	EndIf;
	
	rStatus = GetStatusDescription(vResponse["order_state"]);
	If Not CheckStatusOrder(vResponse["order_state"], rIsCompleted, pIsPayment, rMessage) Then
		Return False;
	EndIf;
	
	If Not rIsCompleted And pIsPayment Then
		Return True;
	EndIf;

	For Each vItem In vResponse["order_operation_params"] Do
		If (vItem["operation_type"] = "PAY" Or (Not pIsPayment And vItem["operation_id"] = pDocument.ExternalCode)) And Number(vItem["response_code"]) = 0 Then
			vObj = pDocument.GetObject();
			vObj.MerchantID = vResponse["mid"];
			vObj.ReferenceNumber = vItem["rrn"];
			vObj.AuthorizationCode = vItem["auth_code"];
			vObj.ExternalCode = vItem["operation_id"];
			vObj.CardOperationDate = XMLValue(Type("Date"), vItem["operation_date_time"]);
			vObj.Write(DocumentWriteMode.Write);
			rIsCompleted = True;
			Break;
		EndIf;
	EndDo;
		
	Return True;
EndFunction // GetStatusExternalPayment

// -----------------------------------------------------------------------------
Function SendQuery(pData, pType, pHeader, pOAuth, rResponse, pIsReturn = False)
	vHTTPServer = "api.sberbank.ru";
	vPort = 8443;
	vHttpAddress = "";
	
	If Not pOAuth Then
		vHttpAddress = "prod/qr/order/v3/";
		If Not IsBlankString(ExternalInteraction.HttpServer) Then
			vHttp = StrReplace(StrReplace(ExternalInteraction.HttpServer, "https://", ""), "http://", "");
			vHTTPServer = Left(vHttp, StrFind(vHttp, "/") - 1);
			vPortIndex = StrFind(vHTTPServer, ":", SearchDirection.FromEnd);
			If vPortIndex > 0 Then
				vPortStr = Right(vHTTPServer, StrLen(vHTTPServer) - vPortIndex);
				If Not IsBlankString(vPortStr) And cmIsNumber(vPortStr) Then
					vPort = Number(vPortStr);
				EndIf;
				vHTTPServer = Left(vHTTPServer, vPortIndex - 1);
			EndIf;
			vHttpAddress = Right(vHttp, StrLen(vHttp) - StrFind(vHttp, "/") + 1);
		EndIf;
	Else
		vHttpAddress = "/prod/tokens/v2/";
		If Not IsBlankString(ExternalInteraction.WSHost) Then
			vHttp = StrReplace(StrReplace(ExternalInteraction.WSHost, "https://", ""), "http://", "");
			vHTTPServer = Left(vHttp, StrFind(vHttp, "/") - 1);
			vPortIndex = StrFind(vHTTPServer, ":", SearchDirection.FromEnd);
			If vPortIndex > 0 Then
				vPortStr = Right(vHTTPServer, StrLen(vHTTPServer) - vPortIndex);
				If Not IsBlankString(vPortStr) And cmIsNumber(vPortStr) Then
					vPort = Number(vPortStr);
				EndIf;
				vHTTPServer = Left(vHTTPServer, vPortIndex - 1);
			EndIf;
			vHttpAddress = Right(vHttp, StrLen(vHttp) - StrFind(vHttp, "/") + 1);
		EndIf;
	EndIf;
	
	If Right(vHttpAddress, 1) <> "/" Then
		vHttpAddress = vHttpAddress + "/";
	EndIf;
	
	vHttpAddress = vHttpAddress + TrimAll(pType);
	
	Try
		vSSLSecure = New OpenSSLSecureConnection(New FileClientCertificate(ExternalInteraction.HttpCertificateFile, ExternalInteraction.HttpCertificatePassword), Undefined);
		
		vHTTPConnection = New HTTPConnection(vHTTPServer, vPort,,,, 15, vSSLSecure);
		
		vHTTPRequest = New HTTPRequest(vHttpAddress, pHeader);
		If ValueIsFilled(pData) Then
			vHTTPRequest.SetBodyFromString(pData, TextEncoding.UTF8);
		EndIf;
		
		vRS = vHTTPConnection.CallHTTPMethod("POST", vHTTPRequest);
			
		vRSString = vRS.GetBodyAsString(TextEncoding.UTF8);
		
		If ExternalInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, pType, Enums.ExternalSystemEventTypes.Info, pData, vRSString,, ExternalInteraction.MaxLogLenght);
		EndIf;
		
		If vRS.StatusCode <> 200 Then
			rResponse = vRSString;
			Return False;
		EndIf;
		
		rResponse = JSONToMap(vRSString);
		
		If pOAuth Then
			Return True;
		EndIf;
		
		If Number(rResponse["error_code"]) = 0 Or (pIsReturn And (Number(rResponse["error_code"]) = 130000 Or Number(rResponse["error_code"]) = 990000)) Then
			Return True;
		EndIf;
		
		rResponse = rResponse["error_description"];
		Return False;
	Except
		vError = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, pType+".SendQuery", Enums.ExternalSystemEventTypes.Error, pData, "", "Failed to send post query! " + DetailErrorDescription(vError), ExternalInteraction.MaxLogLenght); 
		rResponse = BriefErrorDescription(vError);
		Return False;
	EndTry;
EndFunction // SendQuery

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetBase64Auth(Val pClientID, Val pClientSecret)
	Return StrTemplate("Basic %1", StrReplace(StrReplace(Base64String(GetBinaryDataFromString(pClientID + ":" + pClientSecret)), Chars.LF, ""), Chars.CR, ""));
EndFunction // GetBase64Auth

// -----------------------------------------------------------------------------
Function MapToJSON(pMap)
	vJSONWriter = New JSONWriter;
	vJSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(vJSONWriter, pMap);
	Return vJSONWriter.Close();
EndFunction // MapToJSON

// -----------------------------------------------------------------------------
Function JSONToMap(pJson)
	vJSONReader = New JSONReader;
	vJSONReader.SetString(pJson);
	Return ReadJSON(vJSONReader, True);
EndFunction // MapToJSON

// -----------------------------------------------------------------------------
Function CheckStatusOrder(Val pStatus, rIsCompleted, pIsPayment, rMessage)
	vResult = False;
	rMessage = "";
	If pStatus = "PAID" Then
		rIsCompleted = pIsPayment;
		vResult = True;
	ElsIf pStatus = "CREATED" Then
		vResult = True
	ElsIf pStatus = "REVERSED" And Not pIsPayment Then
		rIsCompleted = Not pIsPayment;
		vResult = True;
	ElsIf pStatus = "REFUNDED" And Not pIsPayment Then
		rIsCompleted = Not pIsPayment;
		vResult = True;
	ElsIf pStatus = "ON_PAYMENT" Then
		rMessage = NStr("en = 'Waiting for payment confirmation from SBP'; de = 'Warten auf Zahlungsbestätigung von SBP'; ru = 'Ожидание подтверждения платежа от СБП'");
		rIsCompleted = False;
		vResult = True;
	ElsIf pStatus = "REVOKED" Then
		rMessage = NStr("en = 'Canceled before financial transaction'; de = 'Vor der Finanztransaktion storniert'; ru = 'Отменен до проведения фин.операции'");
	ElsIf pStatus = "DECLINED" Then
		rMessage = NStr("en = 'Order declined - payment via SberPay failed'; de = 'Bestellung abgelehnt - Zahlung über SberPay fehlgeschlagen'; ru = 'Заказ отклонен - не прошла оплата по SberPay'");
	ElsIf pStatus = "EXPIRED" Then
		rMessage = NStr("en = 'Order expired'; de = 'Bestellung abgelaufen'; ru = 'Истек срок жизни заказа'");
	Else
		rMessage = NStr("en = 'Unknown order status'; de = 'Unbekannter Bestellstatus'; ru = 'Неизвестный статус заказа'");
	EndIf;
	Return vResult;
EndFunction // CheckStatusOrder

// -----------------------------------------------------------------------------
Function GetStatusDescription(Val pStatus)
	If pStatus = "PAID" Then
		Return NStr("en = 'Paid'; de = 'Bezahlt'; ru = 'Оплачен'");
	ElsIf pStatus = "CREATED" Then
		Return NStr("en = 'Created'; de = 'Erstellt'; ru = 'Создан'");
	ElsIf pStatus = "REVERSED" Then
		Return NStr("en = 'Canceled'; de = 'Abgesagt'; ru = 'Отменен'");
	ElsIf pStatus = "REFUNDED" Then
		Return NStr("en = 'Returned'; de = 'Ist zurückgekommen'; ru = 'Возвращен'");
	ElsIf pStatus = "REVOKED" Then
		Return NStr("en = 'Revoked'; de = 'Widerrufen'; ru = 'Аннулировано'");
	ElsIf pStatus = "DECLINED" Then
		Return NStr("en = 'Rejected'; de = 'Abgelehnt'; ru = 'Отклонен'");
	ElsIf pStatus = "EXPIRED" Then
		Return NStr("en = 'Order expired'; de = 'Bestellung abgelaufen'; ru = 'Истек срок жизни заказа'");
	Else
		Return NStr("en = 'Unknown order status'; de = 'Unbekannter Bestellstatus'; ru = 'Неизвестный статус заказа'");
	EndIf;
EndFunction // GetStatusDescription

#EndRegion


