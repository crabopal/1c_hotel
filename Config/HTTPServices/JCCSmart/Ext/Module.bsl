#Region EventHandlers

// ----------------------------------------------------------------------------
Function CallbackPOST(pRequest)
	vResponseCode = 200;
	vMessage = ""; 
	
	vAuthorization = pRequest.Headers["Authorization"]; 
	
	vAPPId = "";
	vRequestSignatureBase64String = "";
	vNonce = "";
	vRequestTimeStamp = "";
	
	If GetParametersFromByHeaders(vAuthorization, vAPPId, vRequestSignatureBase64String, vNonce, vRequestTimeStamp) Then 
		vExternalSystemInteraction = cmGetInteractionByID(vAPPId); 
		If ValueIsFilled(vExternalSystemInteraction) Then
			vJSON = pRequest.GetBodyAsString(); 	
			If vAuthorization = GetAuthorization(vExternalSystemInteraction, pRequest.HTTPMethod, pRequest.BaseURL, vJSON, vNonce, vRequestTimeStamp) Then
				If ValueIsFilled(vJSON) Then
					Try           
						vPaymentInfoMap = Catalogs.DataConvertationRules.JSONtoMap(vJSON);
						If vPaymentInfoMap <> Undefined Then
							cmWritePaymentExternalFOSystem(TrimAll(vExternalSystemInteraction.Hotel.Code), "", XMLValue(Type("Date"), vPaymentInfoMap["TransactionTimeStamp"]), vExternalSystemInteraction.InteractionID,
														   "", cmGetDocumentNumberFromPresentation(vPaymentInfoMap["InvoiceId"], vExternalSystemInteraction.Hotel), "", TrimAll(vExternalSystemInteraction.PaymentMethod.Code), 
														   TrimAll(vExternalSystemInteraction.Currency.Code), vPaymentInfoMap["TransactionAmount"], "", vPaymentInfoMap["TransactionAuthorization"],,,, Format(vPaymentInfoMap["TransactionNo"], "NFD=0; NZ=0; NG=0"));
						EndIf;
					Except 
						vMessage = BriefErrorDescription(ErrorInfo());
						vResponseCode = 404;
					EndTry;	
				Else
					vMessage = NStr("en = 'Empty request'; de = 'Leere Anfrage'; ru = 'Пустой запрос'");
					vResponseCode = 400;	
				EndIf;
			Else	      
				vMessage = NStr("en = 'The request was not authenticated'; de = 'Die Anfrage wurde nicht authentifiziert'; ru = 'Запрос не был аутентифицирован'");
				vResponseCode = 400;	
			EndIf;
			If vExternalSystemInteraction.DebugMode Or vResponseCode <> 200 Then 
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExternalSystemInteraction, "Callback", ?(vResponseCode <> 200, Enums.ExternalSystemEventTypes.Error, Enums.ExternalSystemEventTypes.Info), vJSON, "", vMessage); 
			EndIf;
		Else
			vResponseCode = 401;
			vMessage = Nstr("en = 'Failed to find interaction parameters'; de = 'Interaktionsparameter konnten nicht gefunden werden'; ru = 'Не удалось найти параметры взаимодействия'");
			WriteLogEvent("JCCSmart.Callback", EventLogLevel.Error,,, vMessage);
		EndIf;
	Else
		vResponseCode = 401;
		vMessage = Nstr("en = 'Failed to find interaction parameters'; de = 'Interaktionsparameter konnten nicht gefunden werden'; ru = 'Не удалось найти параметры взаимодействия'");
		WriteLogEvent("JCCSmart.Callback", EventLogLevel.Error,,, vMessage);
	EndIf;
	Return New HTTPServiceResponse(vResponseCode);
EndFunction // CallbackPOST

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
Function GetParametersFromByHeaders(pAuthorization, pAPPId, pRequestSignatureBase64String, pNonce, pRequestTimeStamp)
	vResult = False;
	If pAuthorization <> Undefined Then
		vAuthorizationArr = StrSplit(StrReplace(pAuthorization, "hmacauth ", ""), ":", False);
		If vAuthorizationArr.Count() = 4 Then
			pAPPId							= vAuthorizationArr[0];
			pRequestSignatureBase64String	= vAuthorizationArr[1];
			pNonce							= vAuthorizationArr[2];
			pRequestTimeStamp				= vAuthorizationArr[3];
			vResult = True;
		EndIf;
	EndIf; 
	Return vResult;
EndFunction // GetParametersFromByAuthorization

// ----------------------------------------------------------------------------
Function GetAuthorization(pExternalSystemInteraction, pHTTPMethod, pBaseURL, pBody, pNonce, pRequestTimeStamp)
	vContentBase64 = ""; 
	
	If ValueIsFilled(pBody) Then	
		vContentBase64 = Base64String(tcCryptography.Hash(pBody, HashFunction.MD5)); 
	EndIf;	  
	
	vSignature = StrTemplate("%1%2%3%4%5%6", TrimAll(pExternalSystemInteraction.InteractionID), pHTTPMethod, pBaseURL, pRequestTimeStamp, pNonce, vContentBase64); 
	vSignatureBinaryData = tcCryptography.HMAC(TrimAll(pExternalSystemInteraction.OAuth_ClientSecret), vSignature, HashFunction.SHA256);
	If vSignatureBinaryData = Undefined Then
		Return Undefined;	
	Endif; 
	
	Return StrTemplate("hmacauth %1:%2:%3:%4", TrimAll(pExternalSystemInteraction.InteractionID), Base64String(vSignatureBinaryData), pNonce, pRequestTimeStamp);
EndFunction // GetAuthorization

#EndRegion