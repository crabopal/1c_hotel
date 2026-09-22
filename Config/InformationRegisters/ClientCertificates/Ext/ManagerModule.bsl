
#Region Public

// -----------------------------------------------------------------------------
Function UpdateCertificateData(pRec, rMessage, pIsRefreshingAtForm = False, rQRCode = Undefined) Export 
	If Not ValueIsFilled(pRec.LinkToCertificate) Then
		rMessage = NStr("en = 'Certificate link not filled'; de = 'Zertifikatslink nicht ausgefüllt'; ru = 'Не заполнена ссылка на сертификат'");
		Return False;
	EndIf;
	vNumber = "";
	vStartIndex = StrFind(pRec.LinkToCertificate, "/", SearchDirection.FromEnd);
	If vStartIndex <> 0 And vStartIndex + 1 < StrLen(pRec.LinkToCertificate) Then
		vNumber = StrReplace(TrimAll(Right(pRec.LinkToCertificate, StrLen(pRec.LinkToCertificate) - (vStartIndex))), "qr?id=", "");	
	EndIf;
	If ValueIsFilled(pRec.Guest) And Not ValueIsFilled(vNumber) Then
		pRec.CertificateNumber = TrimAll(pRec.Guest.UUID());
	ElsIf ValueIsFilled(vNumber) Then
		pRec.CertificateNumber = vNumber;
	Else
		pRec.CertificateNumber = TrimAll(New UUID());		
	EndIf;
	If ValueIsFilled(vNumber) Then
		vHost = "";
		vResourceAddress = "";
		vBody = "";
		vResponseBody = "";
		vMethod = "GET";
		vHeader = New Map();
		If StrFind(pRec.LinkToCertificate, "immune.mos.ru") <> 0 Then
			vHost = "immune.mos.ru";
			vResourceAddress = "/api/search_by_number_form"; 
			vHeader.Insert("content-type", "application/json");
			vBody = Catalogs.DataConvertationRules.MapToJSON(New Structure("number", vNumber)); 
			vMethod = "POST";
		ElsIf StrFind(pRec.LinkToCertificate, "gosuslugi.ru") <> 0 Then
			vHost = "www.gosuslugi.ru";
			If StrFind(pRec.LinkToCertificate, "vaccine/cert/verify/unrz/") <> 0 Then
				vResourceAddress = "/api/vaccine/v1/cert/verify//unrz/";	
			ElsIf StrFind(pRec.LinkToCertificate, "/vaccine/cert/verify/") <> 0 Then
				vResourceAddress = "/api/vaccine/v1/cert/verify/";					
			Else
				If StrFind(pRec.LinkToCertificate, "ck=") <> 0 Then
					vResourceAddress = "/api/covid-cert/v3/cert/check/";	
				Else
					vResourceAddress = "api/covid-cert/v3/cert/status/";	
				EndIf;
			EndIf;
			vResourceAddress = vResourceAddress + vNumber;
			vHeader.Insert("content-type", "application/json;charset=UTF-8");
		EndIf;
		If ValueIsFilled(vHost) And ValueIsFilled(vResourceAddress) Then
			vHTTPConnection = New HTTPConnection(vHost,,,,, 10, New OpenSSLSecureConnection(Undefined, Undefined));
			vHTTPRequest = New HTTPRequest(vResourceAddress, vHeader);
			If ValueIsFilled(vBody) Then
				vHTTPRequest.SetBodyFromString(vBody, TextEncoding.UTF8);	
			EndIf;
			vHTTPResponse = vHTTPConnection.CallHTTPMethod(vMethod, vHTTPRequest);
			If vHTTPResponse.StatusCode = 200 Then
				Try	
					vMapResponse = New Map();
					vStResponse = vHTTPResponse.GetBodyAsString(TextEncoding.UTF8);
					Try
						vMapResponse = Catalogs.DataConvertationRules.JSONtoMap(vStResponse);			
					Except
					  	rMessage = NStr("en = 'Failed to get certificate data.'; de = 'Zertifikatsdaten konnten nicht abgerufen werden.'; ru = 'Не удалось получить данные сертификата.'");
						WriteLogEvent(NStr("en = 'ClientCertificates.Error'; de = 'ClientCertificates.Error'; ru = 'СертификатыВакцинации.Ошибка'"), EventLogLevel.Warning, , vStResponse, rMessage);
						Return False;
					EndTry;	
					vData = GetDateByLinkCertificate(pRec.LinkToCertificate, vMapResponse);
					If vData <> Undefined Then
						UpdateData(pRec, vData["unrz"], vData["qr"], vData["fio"],  vData["expiredAt"], vData["birthDate"], vData["title"], pIsRefreshingAtForm, rQRCode);
					EndIf;
				Except
					rMessage = ErrorDescription();
					Return False;
				EndTry;
			Else
				rMessage = vHTTPResponse.GetBodyAsString(TextEncoding.UTF8);
				Return False;	
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction // UpdateCertificateData

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Object - Data 
//  pReceiverNode	 - IntegrationServices.DataExchangeInterfaces - Data exchange interfaces
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, , pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetDateByLinkCertificate(Val pLinkToCertificate, pResponse)
	vData = Undefined;
	If StrFind(pLinkToCertificate, "immune.mos.ru") <> 0 Then
		vData = GetDataMOS(pResponse);		
	ElsIf StrFind(pLinkToCertificate, "gosuslugi.ru") <> 0 Then
		If StrFind(pLinkToCertificate, "/vaccine/cert/verify/") <> 0 Then
			vData = GetDataV1(pResponse);	
		Else 
			vData = GetDataV3(pResponse);	
		EndIf;
	EndIf;
	Return vData;
EndFunction // GetDateByLinkCertificate

// -----------------------------------------------------------------------------
Function GetDataV1(pResponse)
	vMapResponse = New Map();
	vMapResponse.Insert("unrz", pResponse["unrz"]);
	vMapResponse.Insert("qr", pResponse["qr"]);
	vMapResponse.Insert("fio", pResponse["fio"]);
	vValidToDate = Undefined;
	vDateOfBirth = Undefined;
	If ValueIsFilled(pResponse["expiredAt"]) Then
		Try
			vValidToDate = Date(pResponse["expiredAt"] + " 00:00:00"); 	
		Except
			vValidToDate = Undefined;
		EndTry;	
	EndIf;
	If ValueIsFilled(pResponse["birthdate"]) Then
		Try
			vDateOfBirth = Date(pResponse["birthdate"] + " 00:00:00"); 	
		Except
			vDateOfBirth = Undefined;
		EndTry;	
	EndIf;
	If vValidToDate <> Undefined Then
		vMapResponse.Insert("expiredAt", vValidToDate); 	
	EndIf;
	If vDateOfBirth <> Undefined Then
		vMapResponse.Insert("birthDate", vDateOfBirth);	
	EndIf;
	Return vMapResponse;
EndFunction // GetDataV1

// -----------------------------------------------------------------------------
Function GetDataV3(pResponse)
	vMapResponse = New Map();
	If pResponse["items"] <> Undefined And TypeOf(pResponse["items"]) = Type("Array") And pResponse["items"].Count() > 0 Then 
		vItem = pResponse["items"][0];
		vMapResponse.Insert("unrz", vItem["unrzFull"]);
		vMapResponse.Insert("qr", vItem["qr"]);
		vMapResponse.Insert("title", vItem["title"]);	 
		vValidToDate = Undefined;
		If ValueIsFilled(vItem["expiredAt"]) Then
			Try
				vValidToDate = Date(vItem["expiredAt"] + " 00:00:00"); 	
			Except
				vValidToDate = Undefined;
			EndTry;	
		EndIf;
		If vValidToDate <> Undefined Then
			vMapResponse.Insert("expiredAt", vValidToDate); 	
		EndIf;
		vDateOfBirth = Undefined;
		vFullName = Undefined;
		If vItem["attrs"] <> Undefined And TypeOf(vItem["attrs"]) = Type("Array") And vItem["attrs"].Count() > 0 Then
			For Each vRow In vItem["attrs"] Do 
				If vRow["type"] = "fio" Then
					vFullName = vRow["value"]; 			
				ElsIf vRow["type"] = "birthDate" Then	
					If ValueIsFilled(vRow["value"]) Then
						Try
							vDateOfBirth = Date(vRow["value"] + " 00:00:00"); 	
						Except
							vDateOfBirth = Undefined;
						EndTry;	
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		If vDateOfBirth <> Undefined Then
			vMapResponse.Insert("birthDate", vDateOfBirth);	
		EndIf;
		If vFullName <> Undefined Then
			vMapResponse.Insert("fio", vFullName);	
		EndIf;
	EndIf;	
	Return vMapResponse;
EndFunction // GetDataV1

// -----------------------------------------------------------------------------
Function GetDataMOS(pResponse)
	vMapResponse = New Map();
	vItem = pResponse["result"];
	If vItem <> Undefined And TypeOf(vItem) = Type("Map") Then 
		vCertificate = vItem["certificate"]; 
		If vCertificate <> Undefined Then
			vValidToDate = Undefined;
			vDateOfBirth = Undefined;
			vMapResponse.Insert("unrz", vItem["number"]); 
			vMapResponse.Insert("qr", vItem["qrCode"]);
			vMapResponse.Insert("fio", vCertificate["initials"]);
			Try
				vValidToDate = XMLValue(Type("Date"), vCertificate["end"]);
			Except
				vValidToDate = Undefined;
			EndTry;
			Try
				vDateOfBirth = XMLValue(Type("Date"), vCertificate["birthDay"]);
			Except
				vDateOfBirth = Undefined;
			EndTry;
			If vValidToDate <> Undefined Then
				vMapResponse.Insert("expiredAt", vValidToDate);	
			EndIf;
			If vDateOfBirth <> Undefined Then
				vMapResponse.Insert("birthDate", vDateOfBirth);	
			EndIf;
		EndIf;
	EndIf;
	Return vMapResponse;
EndFunction // GetDataV1

// -----------------------------------------------------------------------------
Procedure UpdateData(pRec, pNumber, pQRCode, pFullName, pValidToDate, pDateOfBirth, pRemarks, pIsRefreshingAtForm, rQRCode)
	If ValueIsFilled(pFullName) Then
		pRec.FullName = TrimAll(pFullName);
	Else
		pRec.FullName = "";	
	EndIf;
	If Not pIsRefreshingAtForm Then
		If ValueIsFilled(pQRCode) Then
			pRec.QRCode = New ValueStorage(GetBinaryDataFromBase64String(pQRCode));
		Else
			pRec.QRCode = Undefined;	
		EndIf;
	Else
		If ValueIsFilled(pQRCode) Then
			rQRCode = pQRCode;
		Else
			rQRCode = Undefined;	
		EndIf;	
	EndIf;
	If ValueIsFilled(pNumber) Then 
		pRec.CertificateNumber = TrimAll(pNumber);
	EndIf;
	If ValueIsFilled(pValidToDate) Then 
		pRec.ValidToDate = pValidToDate;
	Else
		pRec.ValidToDate = Date('00010101');	
	EndIf;
	If ValueIsFilled(pDateOfBirth) Then 
		pRec.DateOfBirth = pDateOfBirth;
	Else
		pRec.DateOfBirth = Date('00010101');	
	EndIf;
	If ValueIsFilled(pRemarks) Then 
		pRec.Remarks = pRemarks;
	Else
		pRec.Remarks = "";
	EndIf;
	pRec.RegistrationDay = CurrentSessionDate();
EndProcedure // UpdateData

#EndRegion
