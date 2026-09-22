#Region Public

// -----------------------------------------------------------------------------
//  Connect YandexVision (not necessary)
//
// Parameters:
//  rMessage - String	 - Return result message
// 
// Returns:
//  Returns - Undefined
//
Function pmConnect(rMessage="") Export
	rMessage = "";
	
	Return Undefined;	
EndFunction // pmConnect

// -----------------------------------------------------------------------------
//  Disconnect YandexVision (not necessary)
//
// Parameters:
//  pScObj	 - ComObject - ComObject images scanner
//
Procedure pmDisconnect(pScObj) Export
	#If WebClient Then
		Return;
	#EndIf
	Try
		pScObj = Undefined;
	Except
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
//  Recognize document and get recognized data
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - External system interaction
//  pImg					 - String								 - Base64 image of document to be recognized
//  pRecognitionQuality		 - Structure							 - Reliability of field recognition
//  rMessage				 - String								 - Return result message
// 
// Returns:
//  Structure - recognized fields of document
//
Function RecognizeDocument(pInteractionParameters, pImg, pRecognitionQuality, rMessage="") Export
	vRecognizedFields = New Structure();
	If Not ValueIsFilled(pInteractionParameters) Then
		rMessage = NStr("en='The image scanner does not have the interaction parameters filled in!';ru='У сканера изображений не заполнены параметры взаимодействия!';de='Der Bildscanner hat die Interaktionsparameter nicht ausgefüllt!'");
		Return vRecognizedFields;
	EndIf;
	
	vHTTPRes = Undefined;
	rErr = "";
		
	vResStruct = Undefined;
	vTextArr = Undefined;
	vTextDetection = Undefined;
	pType = "TEXT_DETECTION";
	
	vFolderId = pInteractionParameters.SecretKey;
	vIAMToken = pInteractionParameters.OAuth_RefreshToken;
	
	// Build JSON for request body
	vJsonBody = BuildJSON(vFolderId, pImg, pType);
	// Get result of HTTPQuery
	vRes = VisionHTTPQuery(pInteractionParameters, vJsonBody, rErr);
	vResString = vRes.Body;
	vStatuscode = vRes.StatusCode;
	
	If IsBlankString(vResString) Or Not IsBlankString(rErr) Then
		rMessage = rErr;
		Return vRecognizedFields;
	EndIf;
		
	// Processing the request results
	If vStatusCode = 200 Then
		Try
			vResStruct = Catalogs.DataConvertationRules.JSONtoStructure(vResString);
			// Try to find required fields in result structure
			vTextDetection = vResStruct["results"][0]["results"][0]["textDetection"]["pages"][0];
			vTextArr = vTextDetection["entities"];
		Except
			rMessage = NStr("en='Failed to recognize the document!';ru='Не удалось распознать документ!';de='Überprüfen Sie den Internetanschluss!'");
			Return vRecognizedFields;
		EndTry;
	Else
		rMessage = NStr("en='Failed to recognize the document!';ru='Не удалось распознать документ!';de='Überprüfen Sie den Internetanschluss!'") + " " + GetErrorMessage(vStatusCode);		
		Return vRecognizedFields;
	EndIf;
		
	// Fill recognized fields in correct format
	For Each vFieldStruct In vTextArr Do
		vFieldStruct.Text = Title(vFieldStruct.Text);
		If vFieldStruct.Name = "citizenship" Then
			vRecognizedFields.Insert("Citizenship", Upper(vFieldStruct.Text));
		ElsIf vFieldStruct.Name = "expiration_date" Then
			vRecognizedFields.Insert("IdentityDocumentValidToDate", vFieldStruct.Text);
		ElsIf vFieldStruct.Name = "gender" Then
			vRecognizedFields.Insert("Sex", vFieldStruct.Text);
		ElsIf vFieldStruct.Name = "subdivision" Then
			vRecognizedFields.Insert("IdentityDocumentUnitCode", vFieldStruct.Text);
		ElsIf vFieldStruct.Name = "issue_date" Then
			vRecognizedFields.Insert("IdentityDocumentIssueDate", vFieldStruct.Text);
		ElsIf vFieldStruct.Name = "issued_by" Then
			vRecognizedFields.Insert("IdentityDocumentIssuedBy", Upper(vFieldStruct.Text));
		ElsIf vFieldStruct.Name = "surname" Then
			vRecognizedFields.Insert("LastName", vFieldStruct.Text);
		ElsIf vFieldStruct.Name = "name" Then
			vRecognizedFields.Insert("FirstName", vFieldStruct.Text);
		ElsIf vFieldStruct.Name = "middle_name" Then
			vRecognizedFields.Insert("SecondName", vFieldStruct.Text);
		ElsIf vFieldStruct.Name = "birth_date" Then
			vRecognizedFields.Insert("DateOfBirth", vFieldStruct.Text);
		ElsIf vFieldStruct.Name = "birth_place" Then
			vRecognizedFields.Insert("PlaceOfBirth", vFieldStruct.Text);
		ElsIf vFieldStruct.Name = "number" Then
			vRecognizedFields.Insert("IdentityDocumentSeries", Left(vFieldStruct.Text, 4));
			vRecognizedFields.Insert("IdentityDocumentNumber", Right(vFieldStruct.Text, 6));
		EndIf;		
	EndDo;
		
	// Fill recognition quality data
	If vTextDetection <> Undefined Then
		Try	
			vQualityFields = vTextDetection["blocks"];
			
			FillQualityState(pRecognitionQuality, vRecognizedFields, vQualityFields);
			vRecognizedFields.Insert("RecognitionQuality", pRecognitionQuality);
			vRecognizedFields.Insert("FillAllItems", True);
		Except
		EndTry;
	EndIf;
	
	If vRecognizedFields.Property("Sex") Then
		vRecognizedFields.Sex = GetClientSex(vRecognizedFields.Sex);
	EndIf;
	If vRecognizedFields.Property("IdentityDocumentIssueDate") Then
		vRecognizedFields.IdentityDocumentIssueDate = FormatDate(vRecognizedFields.IdentityDocumentIssueDate);
	EndIf;
	If vRecognizedFields.Property("DateOfBirth") Then
		vRecognizedFields.DateOfBirth = FormatDate(vRecognizedFields.DateOfBirth);
	EndIf;
	
	Return vRecognizedFields;
EndFunction // RecognizeDocument

// -----------------------------------------------------------------------------
//  Recognize document photo and get it
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - External system interaction
//  pImg					 - String								 - Base64 image of document to be recognized
// 
// Returns:
//  Array - top left coordinate (x and y), width and height of photo
//
Function FindFaces(pInteractionParameters, pImg) Export
	vMessage = "";
	vCoordArray = New Array();
	If Not ValueIsFilled(pInteractionParameters) Then
		rMessage = NStr("en='The image scanner does not have the interaction parameters filled in!';ru='У сканера изображений не заполнены параметры взаимодействия!';de='Der Bildscanner hat die Interaktionsparameter nicht ausgefüllt!'");
		Return vCoordArray;
	EndIf;
	
	vFolderId = pInteractionParameters.SecretKey;
	vIAMToken = pInteractionParameters.OAuth_RefreshToken;
	
	vHTTPRes = Undefined;
	rErr = "";
		
	vResStruct = Undefined;
	vTextArr = Undefined;
	vTextDetection = Undefined;
	pType = "FACE_DETECTION";
	
	// Build JSON for request body
	vJsonBody = BuildJSON(vFolderId, pImg, pType);
	// Get result of HTTP request
	vRes = VisionHTTPQuery(pInteractionParameters, vJsonBody, rErr);
	vResString = vRes.Body;
	vStatuscode = vRes.StatusCode;
	If IsBlankString(vResString) Or Not IsBlankString(rErr) Then
		Message = rErr;
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return vCoordArray;
	EndIf;
		
	// Processing the request results
	If vStatusCode = 200 Then
		Try
			vResStruct = Catalogs.DataConvertationRules.JSONtoStructure(vResString);
			// Try to find required fields in result structure
			vFaceСoordinates = vResStruct["results"][0]["results"][0]["faceDetection"]["faces"][0]["boundingBox"]["vertices"];
		Except
			Return Undefined;
		EndTry;
	Else
		vMessage = NStr("en='Failed to recognize the document!';ru='Не удалось распознать документ!';de='Überprüfen Sie den Internetanschluss!'") + " " + GetErrorMessage(vStatusCode);
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return vCoordArray;
	EndIf;
	
	If vStatusCode = 401 Then
		ExchangeToken(pInteractionParameters);
	EndIf;
	
	// Get top left and botoom right rectangle photo cordinates
	If ValueIsFilled(vFaceСoordinates[0]) And ValueIsFilled(vFaceСoordinates[2]) Then
		vFaceTopLeftCoord = vFaceСoordinates[0];
		vTopLeftX = Round(Number(vFaceTopLeftCoord["X"]), 0);
		vTopLeftY = Round(Number(vFaceTopLeftCoord["Y"]), 0);
		
		vFaceBotRightCoord = vFaceСoordinates[2];
		vBotRightX = Round(Number(vFaceBotRightCoord["X"]), 0);
		vBotRightY = Round(Number(vFaceBotRightCoord["Y"]), 0);
		
		
		vHeight = vBotRightX - vTopLeftX;
		vWidth = vBotRightY - vTopLeftY;
		
		// Increase photo to 3 by 4 format
		vIncHeight = Round(vHeight * 4/2.6, 0);
		vIncWidth = Round(vWidth * 3/2.8, 0);
		
		vIncTopLeftX = Round(vTopLeftX - (vIncWidth - vWidth), 0);
		vIncTopLeftY = Round(vTopLeftY - (vIncHeight - vHeight), 0);
		
		vCoordArray.Add(vIncTopLeftX);
		vCoordArray.Add(vIncTopLeftY);
		vCoordArray.Add(vIncWidth);
		vCoordArray.Add(vIncHeight);
	Else
		vMessage = NStr("en='Failed to recognize photo from passport!';ru='Не удалось распознать фото из паспорта!';de='Passfoto konnte nicht erkannt werden!'");
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndIf;
	
	Return vCoordArray;
EndFunction // FindFaces

// -----------------------------------------------------------------------------
//  Get list of TWAIN devices (not supported by this driver)
//
// Parameters:
//  rMessage - String	 - Return result message
// 
// Returns:
//  ValueList - empty list
//
Function pmGetListOfTWAINDevices(rMessage="") Export
	vList = New ValueList();
	rMessage = NStr("en='TWAIN devices are not supported by this driver!';ru='TWAIN устройства не поддерживаются этим драйвером!';de='TWAIN-Geräte werden von diesem Treiber nicht unterstützt!'");
	Return vList
EndFunction // pmGetListOfTWAINDevices

// -----------------------------------------------------------------------------
//  Get list of allowed scan configurations (not supported by this driver)
//
// Parameters:
//  rMessage - String	 - Return result message
// 
// Returns:
//  ValueList - empty list
//
Function pmGetListOfAllowedConfigurations(rMessage="") Export
	vList = New ValueList();
	rMessage = NStr("en='Recognition configurations are not used by this driver!';ru='Конфигурации распознавания изображений не поддерживаются выбранным драйвером!';de='Die Konfigurationen für die Erkennungen von Abbildungen werden von diesem Treiber nicht unterstützt'");
	Return vList;
EndFunction // pmGetListOfAllowedConfigurations

// -----------------------------------------------------------------------------
//  Refresh IAM-token and its expiration time by sending HTTP request with OAuth-token
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - External system interaction
//  rMessage				 - String								 - Return result message
//
Procedure ExchangeToken(pInteractionParameters, rMessage="") Export
	vFolderId = pInteractionParameters.SecretKey;
	vOAuthToken = pInteractionParameters.OAuth_AccessToken;
	
	vResStruct = New Structure();
	If ValueIsFilled(pInteractionParameters.SecretKey) Then
		vResStruct = GetIAMToken(vOAuthToken, rMessage);
	Else
		rMessage = ("en = 'The OAuth-token is not filled in the image scanners connection parameters!'; de = 'Der OAuth-Token ist in den Verbindungsparametern des Bildscanners nicht ausgefüllt!'; ru = 'В параметрах сканеров изображений не заполнен OAuth-токен!'");
	EndIf;
	If ValueIsFilled(vResStruct) Then
		vInterParamsObject = pInteractionParameters.GetObject();
		If ValueIsFilled(vResStruct["iamToken"]) Then
			vInterParamsObject.OAuth_RefreshToken = vResStruct["iamToken"];
		Else
			rMessage = NStr("en='Failed to authorize!';ru='Не удалось выполнить авторизацию!';de='Autorisierung fehlgeschlagen!'");
		EndIf;
		If ValueIsFilled(vResStruct["expiresAt"]) Then
			vInterParamsObject.LastFullSynchronizationTime = ReadJSONDate(vResStruct["expiresAt"], JSONDateFormat.ISO);
		Else
			rMessage = NStr("en='Failed to authorize!';ru='Не удалось выполнить авторизацию!';de='Autorisierung fehlgeschlagen!'");
		EndIf;
		vInterParamsObject.Write();
	EndIf;
EndProcedure // ExchangeToken

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetErrorMessage(pStatusCode)
	If pStatusCode = 400 Then
		rMessage = NStr("en='Bad request!';ru='Неверный запрос!';de='Ungültige Anfrage!'");
	ElsIf pStatusCode = 401 Then
		rMessage = NStr("en='Invalid Yandex Vision token!';ru='Неверный токен Yandex Vision!';de='Ungültiger Yandex Vision token!'");
	ElsIf pStatusCode = 403 Then
		rMessage = NStr("en='No access to the specified Yandex Vision folder!';ru='Нет доступа к указанной папке Yandex Vision!';de='Kein Zugriff auf den angegebenen Yandex Vision-Ordner!'");
	ElsIf pStatusCode = 404 Then
		rMessage = NStr("en='The specified Yandex Vision folder was not found!';ru='Указанная папка Yandex Vision не найдена!';de='Der angegebene Yandex Vision-Ordner wurde nicht gefunden!'");
	ElsIf pStatusCode = 409 Then
		rMessage = NStr("en='Operation aborted!';ru='Операция прервана!';de='Vorgang abgebrochen!'");
	ElsIf pStatusCode = 429 Then
		rMessage = NStr("en='Too many requests!';ru='Cлишком много запросов!';de='Zu viele Anfragen!'");
	ElsIf pStatusCode = 499 Then
		rMessage = NStr("en='The user canceled the operation!';ru='Пользователь отменил операцию!';de='Der Benutzer hat den Vorgang abgebrochen!'");
	ElsIf pStatusCode = 500 Then
		rMessage = NStr("en='Unknown error!';ru='Неизвестная ошибка!';de='Unbekannter Fehler!'");
	ElsIf pStatusCode = 501 Then
		rMessage = NStr("en='Operation not supported!';ru='Операция не поддерживается!';de='Betrieb wird nicht unterstützt!'");
	ElsIf pStatusCode = 503 Then
		rMessage = NStr("en='Service is unavailable!';ru='Сервис недоступен!';de='Service ist nicht verfügbar!'");
	ElsIf pStatusCode = 504 Then
		rMessage = NStr("en='Timeout expired!';ru='Время ожидания истекло!';de='Timeout abgelaufen!'");;
	EndIf;
	
	Return rMessage;
EndFunction // BuildJSON

// -----------------------------------------------------------------------------
Function BuildJSON(pFolderId, pImg, pType)
	// Create request structure
	vStruct = New Structure();
	vStruct.Insert("folderId", pFolderId);
	
	vAnalyzeSpecsArr = New Array();
	
	vAnalyzeSpecsFirstStruct = New Structure();
	vAnalyzeSpecsFirstStruct.Insert("content", pImg);
	
	vFeaturesArray = New Array();
	
	vFeaturesStruct = New Structure();
	vFeaturesStruct.Insert("type", pType);
		
	If pType = "TEXT_DETECTION" Then
		vTDCStruct = New Structure();
	
		vLngCodesArray = New Array();
		vLngCodesArray.Add("ru");
		vLngCodesArray.Add("en");
		
		vTDCStruct.Insert("language_codes", vLngCodesArray);
		vTDCStruct.Insert("model", "passport");

		vFeaturesStruct.Insert("text_detection_config", vTDCStruct);
	EndIf;
	
	vFeaturesArray.Add(vFeaturesStruct);
	
	vAnalyzeSpecsFirstStruct.Insert("features", vFeaturesArray);
	
	vAnalyzeSpecsArr.Add(vAnalyzeSpecsFirstStruct);
	
	vStruct.Insert("analyze_specs", vAnalyzeSpecsArr);
	
	vJson = Catalogs.DataConvertationRules.MapToJSON(vStruct);
	
	Return vJson;
EndFunction // BuildJSON

// -----------------------------------------------------------------------------
Procedure FillQualityState(pRecognitionQuality, pRecognizedFields, pQualityFields)
	For Each vField In pRecognizedFields Do
		For Each vBlock In pQualityFields Do
			If Not IsBlankString(vField.Value) Then
				If vBlock["lines"][0]["words"][0]["text"] = Lower(vField.Value) Then
					pRecognitionQuality.Insert(vField.Key, Round(vBlock["lines"][0]["confidence"] * 100, 0));
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	pRecognitionQuality.Insert("IdentityDocumentSeries", pRecognitionQuality.IdentityDocumentUnitCode);
	pRecognitionQuality.Insert("IdentityDocumentNumber", pRecognitionQuality.IdentityDocumentUnitCode);
EndProcedure // FillQualityState

// -----------------------------------------------------------------------------
Function FormatDate(pDateString)
	vResult = Undefined;
	If ValueIsFilled(pDateString) Then
		Try
			vResult = Date(Right(pDateString, 4) + Mid(pDateString, 4, 2) + Left(pDateString, 2));
		Except
			vResult = Undefined;
		EndTry;
	EndIf;
	Return vResult;
EndFunction // FormatDate

// -----------------------------------------------------------------------------
Function GetClientSex(pSexStr)
	vSex = Undefined;
	If Not IsBlankString(pSexStr) Then
		vL = Upper(Left(TrimAll(pSexStr), 1));
		If vL = "Ж" Or vL = "F" Then
			vSex = PredefinedValue("Enum.Sex.Female");
		Else
			vSex = PredefinedValue("Enum.Sex.Male");
		EndIf;
	EndIf;
	Return vSex;
EndFunction // GetClientSex

// -----------------------------------------------------------------------------
Function VisionHTTPQuery(pInteractionParameters, pBody, rErr)
    vRes = ""; 
	Try
		vIAMToken = pInteractionParameters.OAuth_RefreshToken;  
		vHeaders = New Map();
		vHeaders.Insert("Authorization", "Bearer " + vIAMToken);

		vRes = Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vHeaders, , "POST", , pBody, "JSON", , , , , , , , False);
    Except
        rErr = ErrorDescription();
        Return "";
    EndTry;
    Return vRes;
EndFunction // VisionHTTPQuery

// -----------------------------------------------------------------------------
Function TokenHTTPQuery(pOAuthToken, pHTTPRes, rErr)
	vRes = ""; 
    Try
		// HTTP connection
		vHTTPCon = New HTTPConnection("iam.api.cloud.yandex.net",,,,,, New OpenSSLSecureConnection(Undefined, Undefined));

		vHTTPRequest = New HTTPRequest("/iam/v1/tokens");
		
		vStruct = New Structure();
		vStruct.Insert("yandexPassportOauthToken", pOAuthToken);
		
		vJson = New JSONWriter;
		vJson.SetString();
		WriteJSON(vJson, vStruct);
		vJson =  vJson.Close();
						
		vHTTPRequest.SetBodyFromString(vJson);
		pHTTPRes = vHTTPCon.Post(vHTTPRequest);
		
		vRes = pHTTPRes.GetBodyAsString();	
    Except
        rErr = ErrorDescription();
        Return "";
    EndTry;
    Return vRes;
EndFunction// TokenHTTPQuery

// -----------------------------------------------------------------------------
Function GetIAMToken(pOAuthToken, rMessage="") Export
	vHTTPRes = Undefined;
	rErr = "";
		
	vResStruct = Undefined;
	vToken = "";

	// Get result of HTTPQuery
	vResString = TokenHTTPQuery(pOAuthToken ,vHTTPRes, rErr);

	If IsBlankString(vResString) Or Not IsBlankString(rErr) Then
		rMessage = rErr;
		Return vResStruct;
	EndIf;
		
	// Processing the request results
	If vHTTPRes.StatusCode = 200 Then
		Try
			vResStruct = Catalogs.DataConvertationRules.JSONtoStructure(vResString);
		Except
			rMessage = NStr("en='Failed to authorize!';ru='Не удалось выполнить авторизацию!';de='Autorisierung fehlgeschlagen!'");
			Return vResStruct;
		EndTry;
	Else
		rMessage = GetErrorMessage(vHTTPRes.StatusCode);		
		Return vResStruct;
	EndIf;
	
	Return vResStruct;
EndFunction // RecognizeDocument

#EndRegion