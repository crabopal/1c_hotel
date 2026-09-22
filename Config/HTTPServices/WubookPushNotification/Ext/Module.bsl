#Region EventHandlers 

// -----------------------------------------------------------------------------
Function FetchTemplatePOST(pRequest)
	vRCode = "";
	vLCode = "";
	vError = False;
	vLogTag = NStr("en='Get WuBook push notification';ru='Push-уведомление WuBook';de='Holen WuBook Push-Benachrichtigung'");
	vParamsStr = "";
	If ValueIsFilled(pRequest.GetBodyAsString()) Then
		vParamsArray = StringToArray(pRequest.GetBodyAsString());
		For Each vItem In vParamsArray Do
			vPos = Find(vItem, "=");
			vParam = Left(vItem, vPos-1);
			vValue = Right(vItem, StrLen(vItem) - vPos);
			vParamsStr = vParamsStr + vParam + " = " + vValue + Chars.LF;
			If vParam = "rcode" Then
				vRCode = vValue;
			ElsIf vParam = "lcode" Then
				vLCode = vValue;
			EndIf;
		EndDo;
	EndIf;
	WriteLogEvent(vLogTag, EventLogLevel.Information, , , "Start HTTP-Service" + Chars.LF + "Request Body: " + Chars.LF + vParamsStr);
	If ValueIsFilled(vRCode) And ValueIsFilled(vLCode) Then
		WriteLogEvent(vLogTag, EventLogLevel.Information, , , 
	              NStr("en='External reservation code: ';ru='Код внешней брони: ';de='Reservierungscode im externen System: '") + vRCode + Chars.LF + 
	              NStr("en='Lodging code: ';ru='Код отеля в системе ВуБук: ';de='Unterkünfte Code: '") + vLCode);
		vHotel = SessionParameters.CurrentHotel;
		vFindedExtSystemInteractionRef = Catalogs.ExternalSystemInteractions.FindByCode("Wubook"+TrimAll(vHotel.Code));
		If ValueIsFilled(vFindedExtSystemInteractionRef) Then
			If ValueIsFilled(vFindedExtSystemInteractionRef.Login) And ValueIsFilled(vFindedExtSystemInteractionRef.Password) Then
				vChecked = CheckLodgingCode(vHotel, vFindedExtSystemInteractionRef.InteractionID, vLCode);
				If vChecked Then
					// Get Token
					vResult = GetToken(vFindedExtSystemInteractionRef);
					If ValueIsFilled(vResult) Then
						WriteLogEvent(vLogTag, EventLogLevel.Error, , , vResult);
						vError = True;
					Else
						vParamsArray = New Array();
						vParamsArray.Add(vFindedExtSystemInteractionRef);
						vParamsArray.Add(vLCode);
						vParamsArray.Add(False);
						vParamsArray.Add(Undefined);
						vParamsArray.Add(Undefined);
						vParamsArray.Add(vRCode);
						Try
							AsyncCalls.StartBackgroundJob("WuBook.FetchBookings", vParamsArray, vFindedExtSystemInteractionRef.InteractionID, "WuBook.FetchBookings");
						Except
							vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
							WriteLogEvent(vLogTag, EventLogLevel.Error, , , vErrorDescription);
							vError = True;
						EndTry;
					EndIf;
				Else
					WriteLogEvent(vLogTag, EventLogLevel.Error, , , NStr("en='The lodging code does not match the lodging code stored in the database'; ru='Внешний код отеля не совпадает с сохраненным в базе'; de='Das Quartier Code nicht den Unterkünften Code in der Datenbank gespeichert entsprechen'"));
					vError = True;
				EndIf;
			Else
				WriteLogEvent(vLogTag, EventLogLevel.Error, , , NStr("en='Login or password are not filled'; ru='Логин или пароль не заполнены'; de='Login oder Passwort sind nicht gefüllt'"));
				vError = True;
			EndIf;
		Else
			WriteLogEvent(vLogTag, EventLogLevel.Error, , , NStr("en='Could not find directory entry interaction with external systems'; ru='Не удалось найти элемент справочника Взаимодействия с внешней системой'; de='Verzeichniseintrag Interaktion mit externen Systemen konnte nicht gefunden werden'"));
			vError = True;
		EndIf;
		If vError Then
			WriteLogEvent(vLogTag, EventLogLevel.Error, , , "Error!");
			pResponse = New HTTPServiceResponse(500);
		Else
			pResponse = New HTTPServiceResponse(200);
		EndIf;
	Else
		WriteLogEvent(vLogTag, EventLogLevel.Error, , , NStr("en='Not the transmitted query parameters (LCode and RCode)'; ru='Не переданые параметры запроса (LCode и RCode)'; de='Nicht die übertragenen Abfrageparameter (LCode und RCode)'"));
		pResponse = New HTTPServiceResponse(400);
	EndIf;
	Return pResponse;
EndFunction // FetchTemplatePOST

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function StringToArray(pStr, pDelimiter = "&")
    vParamsArray = New Array();
	vStr = TrimAll(pStr);
    If pDelimiter = " " Then
        While True Do
            vPos = Find(vStr, pDelimiter);
            If vPos = 0 Then
                vParamsArray.Add(vStr);
                Return vParamsArray;
            EndIf;
            vParamsArray.Add(Left(vStr, vPos-1));
            vStr = TrimL(Mid(vStr, vPos));
        EndDo;
    Else
        vDelimiterLen = StrLen(pDelimiter);
        While True Do
            vPos = Find(vStr, pDelimiter);
            If vPos = 0 Then
                vParamsArray.Add(vStr);
                Return vParamsArray;
            EndIf;
            vParamsArray.Add(Left(vStr, vPos-1));
            vStr = Mid(vStr, vPos+vDelimiterLen);
        EndDo;
    EndIf;
EndFunction // StringToArray

// -----------------------------------------------------------------------------
Function GetToken(pExternalInteraction)
	vTokenResult = WuBook.GetToken(pExternalInteraction.WSHost, "xrws", pExternalInteraction.Login, pExternalInteraction.Password);
	If TypeOf(vTokenResult) = Type("String") Then
		WriteLogEvent(NStr("en='Get Token (WuBook)';ru='Get Token (WuBook)';de='Get Token (WuBook)'"), EventLogLevel.Error, , Undefined, vTokenResult);
		Return vTokenResult;
	Else
		If vTokenResult.StatusID <> "0" Then
			WriteLogEvent(NStr("en='Get Token (WuBook)';ru='Get Token (WuBook)';de='Get Token (WuBook)'"), EventLogLevel.Error, , Undefined, vTokenResult.Value);
			Return vTokenResult.Value;
		Else
			vExtObj = pExternalInteraction.GetObject();
			vExtObj.SessionID = vTokenResult.Value;
			vExtObj.SessionTimeout = 60;
			vExtObj.SessionStartTime = CurrentSessionDate();
			vExtObj.SessionLastActivityTime = CurrentSessionDate();
			vExtObj.Write();
		EndIf;
	EndIf;
	Return "";
EndFunction // GetToken

// -----------------------------------------------------------------------------
Function CheckLodgingCode(pHotel, pExtCode, pLCode)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
	|	AND ExternalSystemsObjectCodesMappings.ObjectRef = &qObjectRef";
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qExternalSystemCode", pExtCode);
	vQuery.SetParameter("qObjectTypeName", "Hotels");
	vQuery.SetParameter("qObjectRef", pHotel);
	vQryChoice = vQuery.Execute().Выбрать();
	While vQryChoice.Next() Do
		If TrimAll(vQryChoice.ObjectExternalCode) = TrimAll(pLCode) Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction // CheckLodgingCode

#EndRegion