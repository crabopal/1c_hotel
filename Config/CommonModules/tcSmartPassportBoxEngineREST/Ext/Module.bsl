#Region Public

// -----------------------------------------------------------------------------
//  Connect PassportBox (not necessary)
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
//  Disconnect PassportBox (not necessary)
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
	rMessage = NStr("en='TWAIN devices are not supported by this driver!';
					|ru='TWAIN устройства не поддерживаются этим драйвером!';
					|de='TWAIN-Geräte werden von diesem Treiber nicht unterstützt!'");
	
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
	rMessage = NStr("en='Recognition configurations are not used by this driver!';
					|ru='Конфигурации распознавания изображений не поддерживаются выбранным драйвером!';
					|de='Die Konfigurationen für die Erkennungen von Abbildungen werden von diesem Treiber nicht unterstützt'");
	
	Return vList;
EndFunction // pmGetListOfAllowedConfigurations

// -----------------------------------------------------------------------------
//  Scan document
//
// Parameters:
//  pInputParameters - Structure - Input parameters
//  pOuputParameters - Structure - Output parameters
//  rMessage		 - String	 - The string to which the error message is written.
//
Procedure ScanDocument(pInputParameters, pOuputParameters, rMessage = "") Export
	vRecognizedFields = New Structure();
	
	vInteractionParameters = tcDevicesConnection.cmGetImagesScannerParameters("InteractionParameters");
	
	If Not ValueIsFilled(vInteractionParameters) Then
		rMessage = NStr("en='The image scanner does not have the interaction parameters filled in!';
						|ru='У сканера изображений не заполнены параметры взаимодействия!';
						|de='Der Bildscanner hat die Interaktionsparameter nicht ausgefüllt!'");
		Return;	
	EndIf;
	
	vEmptyRes = True;
	If pInputParameters.ScanConfiguration.RecognitionIsAvailable Then
		vResString = "";
		vUUID = pInputParameters.FormUUID;
		If Not ValueIsFilled(vUUID) Then
		  vUUID = New UUID;
		EndIf; 
		
		// Get result of HTTPQuery
		vCurrentMethod = "/CaptureDocument";
		vRes = HTTPQuery(vInteractionParameters, vCurrentMethod, rMessage);
		If vRes.Count() > 0 Then
			vResStruct = GetResultStructure(vRes, vCurrentMethod, rMessage);
			
			If vResStruct.Count() > 0 Then
				vEmptyRes = False;
				// Fill recognized data
				FillRecognizedData(pOuputParameters, vInteractionParameters, vResStruct, vUUID, pInputParameters.ScanConfiguration.IdentityDocumentType, rMessage);
			EndIf;
		EndIf;
	EndIf;
	// If recognition is not available or the request was unsuccessful then try to save full document picture
	SaveSnapshot(vInteractionParameters, pOuputParameters, vUUID, rMessage);
	If Not IsBlankString(rMessage) Then
		If pInputParameters.ScanConfiguration.RecognitionIsAvailable Then
			rMessage = NStr("en='Failed to recognize photo from passport!';
							|ru='Не удалось распознать фото из паспорта!';
							|de='Passfoto konnte nicht erkannt werden!'") + " " + rMessage;
		EndIf;
		vLogEventType = Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "ScanDocument", vLogEventType, , ?(vEmptyRes, vRes.Body, ""), rMessage);
		tcCommonFunctionOnClientServer.UserMessage(rMessage);
		rMessage = "";
	EndIf;
EndProcedure // ScanDocument

#EndRegion

#Region Internal

// -----------------------------------------------------------------------------
//  Get structure from HTTP request body
//
// Parameters:
//  pResult			 - Structure - HTTP request result
//  pCurrentMethod	 - String	 - HTTP request method
//  rMessage		 - String	 - Error message
// 
// Returns:
//  Structure - HTTP request body structure
//
Function GetResultStructure(pResult, pCurrentMethod, rMessage = "")
	vResString = pResult.Body;
	vStatusCode = pResult.StatusCode;
	vResStruct = New Structure;
	
	If vStatusCode = 200 Then
		If Not IsBlankString(vResString) Then
			// Processing the request results
			If pCurrentMethod = "/CaptureDocument" Then
				Try
					vResStruct = Catalogs.DataConvertationRules.JSONtoStructure(vResString);
					Return vResStruct;
				Except
					rMessage =  ErrorDescription();
				EndTry;
			Else
				vResStruct.Insert("Image", vResString);
			EndIf;
		EndIf;
	Else
		rMessage = GetErrorMessage(pResult, pCurrentMethod);
	EndIf;
	Return vResStruct;
EndFunction // GetResultStructure

// -----------------------------------------------------------------------------
//  Get HHTP request result
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Parameters of external system
//  pMethod					 - String								 - HTTP request method
//  rMessage				 - String								 - Error message
// 
// Returns:
//  Structure - Request result
//
Function HTTPQuery(pInteractionParameters, pMethod, rMessage)
	vRes = New Structure;
	Try
		If pMethod <> "/CaptureDocument" Then
			vHeaders = New Map();
			vHeaders.Insert("Content-Encoding", "base64");
		EndIf;
		vRes = Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vHeaders, pMethod, "GET", , , , , , , , , , , False);
    Except
        rMessage = ErrorDescription();
	EndTry;
	
    Return vRes;
EndFunction // HTTPQuery

// -----------------------------------------------------------------------------
Procedure SaveSnapshot(pInteractionParameters, pOuputParameters, pUUID, rMessage)
	Try
		vCurrentMethod = "/TakeSnapshot";
		vRes = HTTPQuery(pInteractionParameters, vCurrentMethod, rMessage);
		If vRes.Count() > 0 Then
			vResStruct = GetResultStructure(vRes, vCurrentMethod, rMessage);
			
			If vResStruct.Count() > 0 Then
				vImageByte64 = vResStruct.Image;
				If Not IsBlankString(vImageByte64) Then
					vSnapshot = PutToTempStorage(New Picture(Base64Value(vImageByte64)), pUUID);
					// Save document picture
					pOuputParameters.IdentityDocumentPicture = vSnapshot;
				EndIf;
			EndIf;
		EndIf;
	Except
		rMessage = ErrorDescription();
	EndTry;
EndProcedure // SaveSnapshot

// -----------------------------------------------------------------------------
Procedure FillRecognizedData(pOuputParameters, pInteractionParameters, pResStruct, pUUID, pIdentityDocumentType, rMessage = "")
	vRecognizedFields = New Structure;
	vImages = New Array;
	vDocType = "";
	
	If pResStruct.Property("fields") And TypeOf(pResStruct.fields) = Type("Structure") Then
		vRecognizedFields = pResStruct.fields;
	EndIf;
	If pResStruct.Property("images") And TypeOf(pResStruct.images) = Type("Array") Then
		vImages = pResStruct.images;
	EndIf;
	If pResStruct.Property("doc_type") Then
		vDocType = pResStruct.doc_type;
	EndIf;
	
	vGuestData = pOuputParameters;
	vRecognitionQuality = pOuputParameters.RecognitionQuality;
	vGuestData.FillAllItems = True;
	
	Try
		// ---RECOGNIZE RUSSIAN PASSPORT---
		If vDocType = "rus.passport.national" Then
			// Fill text fields
			If vRecognizedFields.Count() > 0 Then
				// Create mapping between PassportBox document fields and 1CHotel document fields
				vDocDataMapping = New Structure;
				vDocDataMapping.Insert("authority", "IdentityDocumentIssuedBy");
				vDocDataMapping.Insert("authority_code", "IdentityDocumentUnitCode");
				vDocDataMapping.Insert("birthdate", "DateOfBirth");
				vDocDataMapping.Insert("birthplace", "PlaceOfBirth");
				vDocDataMapping.Insert("gender", "Sex");
				vDocDataMapping.Insert("issue_date", "IdentityDocumentIssueDate");
				vDocDataMapping.Insert("name", "FirstName");
				vDocDataMapping.Insert("number", "IdentityDocumentNumber");
				vDocDataMapping.Insert("patronymic", "SecondName");
				vDocDataMapping.Insert("series", "IdentityDocumentSeries");
				vDocDataMapping.Insert("surname", "LastName");
				
				vGuestData.IdentityDocumentType = vGuestData.RussianPassportType;
				For Each vDocField In vDocDataMapping Do
					// Get filled values
					
					If vRecognizedFields.Property(vDocField.Key) Then
						vFieldStruct = vRecognizedFields[vDocField.Key];
						FillStructuresFields(vGuestData, vFieldStruct, vDocField, vRecognitionQuality);
					Else
						vRecognitionQuality.Insert(vDocField.Value, 0);
					EndIf;
					// If field is not accepted or not found then try to fill from mrz
					If vRecognitionQuality[vDocField.Value] < 80 Then
						If vRecognizedFields.Property(vDocField.Key + "_mrz") Then
							vMRZFieldStruct = vRecognizedFields[vDocField.Key + "_mrz"];
							FillStructuresFields(vGuestData, vMRZFieldStruct, vDocField, vRecognitionQuality);
						Else
							// If field not accepted or not found in mrz and field is "number" or "series"
							// then try to find in pages
							If vDocField.Value = "number" or vDocField.Value = "series" Then
								vPageFieldStruct = Undefined;
								If vRecognizedFields.Property(vDocField.Value + "_page2") Then
									vPageFieldStruct = vRecognizedFields[vDocField.Key + "_mrz"];
								ElsIf vRecognizedFields.Property(vDocField.Value + "_page3") Then
									vPageFieldStruct = vRecognizedFields[vDocField.Key + "_mrz"];
								EndIf;
								If vPageFieldStruct <> Undefined Then
									FillStructuresFields(vGuestData, vPageFieldStruct, vDocField, vRecognitionQuality);
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				// Format dates
				If Not IsBlankString(vGuestData.DateOfBirth) Then
					vGuestData.DateOfBirth = Date(vGuestData.DateOfBirth + " 00:00:00");
				EndIf;
				If Not IsBlankString(vGuestData.IdentityDocumentIssueDate) Then
					vGuestData.IdentityDocumentIssueDate = Date(vGuestData.IdentityDocumentIssueDate + " 00:00:00");
				EndIf;
				If Not IsBlankString(vGuestData.Sex) Then
					If StrFind(vGuestData.Sex, "МУЖ") > 0 Then
						vGuestData.Sex = Enums.Sex.Male;
					Else
						vGuestData.Sex = Enums.Sex.Female;
					EndIf;
				EndIf;
			EndIf;
			// Fill photos
			If vImages.Count() > 0 Then
				// Create mapping between PassportBox document images and 1CHotel document images
				vImageMapping = New Map;
				vImageMapping.Insert("photo", "Photo");
				vImageMapping.Insert("signature", "Signature");
				
				For Each vImage In vImageMapping Do
					vCurrentMethod = "/Image?name=";
					If vImages.Find(vImage.Key) <> Undefined Then
						vCurrentMethod = vCurrentMethod + vImage.Key;
						vRes = HTTPQuery(pInteractionParameters, vCurrentMethod, rMessage);
						If vRes.Count() > 0 Then
							vResStruct = GetResultStructure(vRes, vCurrentMethod, rMessage);
							If vResStruct.Count() > 0 Then
								vImageByte64 = vResStruct.Image;
								If Not IsBlankString(vImageByte64) Then
									// Fill captured images
									vGuestData[vImage.Value] = PutToTempStorage(New Picture(Base64Value(vImageByte64)), pUUID);
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;  
			
		ElsIf StrFind(lower(vDocType), "mrz.") > 0 Then
			FillGuestDataFromMRZ(vRecognizedFields, pOuputParameters, pUUID, pIdentityDocumentType);
		Else
			rMessage = NStr("en = 'Only the passport of a citizen of the Russian Federation can be recognized!';
							|de = 'Nur der Pass eines Bürgers der Russischen Föderation kann anerkannt werden!';
							|ru = 'Может быть распознан только паспорт гражданина РФ!'");
		EndIf;
	Except
		rMessage = ErrorDescription();
	EndTry;
EndProcedure // FillRecognizedData

// -----------------------------------------------------------------------------
Procedure FillGuestDataFromMRZ(pData, pOuputParameters, pUUID, pIdentityDocumentType)
	vGuestData 			= pOuputParameters;
	vRecognitionQuality = pOuputParameters.RecognitionQuality;	
	vGuestData.FillAllItems = True;
	// Fill from scan results
	If pData.Property("mrz_last_name") Then
		vLastNameStr = pData.mrz_last_name;
		vGuestData.LastName = Title(vLastNameStr.value); 
		If vLastNameStr.Property("is_Accepted") Then
			If vLastNameStr.is_Accepted = "false" Then
			  vRecognitionQuality.Insert("LastName", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("LastName", 70);
		EndIf;	
	EndIf;
	If pData.Property("mrz_name") Then
		vFirstNameStr = pData.mrz_name; 
		vGuestData.FirstName = Title(vFirstNameStr.value);
		If vFirstNameStr.Property("is_Accepted") Then
			If vFirstNameStr.is_Accepted = "false" Then
			  vRecognitionQuality.Insert("FirstName", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("FirstName", 70);
		EndIf;	
	EndIf;
	If pData.Property("mrz_birth_date") Then  
		vDateOfBirthStr = pData.mrz_birth_date;
		vGuestData.DateOfBirth = GetDateFromString(vDateOfBirthStr.value);
		If vDateOfBirthStr.Property("is_Accepted") Then
			If vDateOfBirthStr.is_Accepted = "false" Then
			  vRecognitionQuality.Insert("DateOfBirth", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("DateOfBirth", 70);
		EndIf;	
	EndIf;
	If pData.Property("mrz_gender") Then 
		vSexStr = pData.mrz_gender;
		vGuestData.Sex = GetClientSex(vSexStr.value);
		If vSexStr.Property("is_Accepted") Then
			If vSexStr.is_Accepted = "false" Then
			  vRecognitionQuality.Insert("Sex", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("Sex", 70);
		EndIf;	
	EndIf;
	vGuestData.IdentityDocumentType = pIdentityDocumentType;
	If pData.Property("mrz_series") Then
		vIdentityDocumentSeriesStr = pData.mrz_series;
		vGuestData.IdentityDocumentSeries = StrReplace(vIdentityDocumentSeriesStr.value, " ", "");
		If vIdentityDocumentSeriesStr.Property("is_Accepted") Then
			If vIdentityDocumentSeriesStr.is_Accepted = "false" Then
			  vRecognitionQuality.Insert("IdentityDocumentSeries", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentSeries", 70);
		EndIf;	
	EndIf;
	If pData.Property("mrz_number") Then
		vIdentityDocumentNumberStr = pData.mrz_number; 
		vGuestData.IdentityDocumentNumber = StrReplace(vIdentityDocumentNumberStr.value, " ", "");
		If vIdentityDocumentNumberStr.Property("is_Accepted") Then
			If vIdentityDocumentNumberStr.is_Accepted = "false" Then
			  vRecognitionQuality.Insert("IdentityDocumentNumber", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentNumber", 70);
		EndIf;	
	EndIf;
	If pData.Property("mrz_issuer") Then
		vIdentityDocumentIssuedByStr = pData.mrz_issuer;
		vGuestData.IdentityDocumentIssuedBy = TrimAll(vIdentityDocumentIssuedByStr.value);
		If vIdentityDocumentIssuedByStr.Property("is_Accepted") Then
			If vIdentityDocumentIssuedByStr.is_Accepted = "false" Then
				vRecognitionQuality.Insert("IdentityDocumentIssuedBy", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentIssuedBy", 70);
		EndIf;	
	EndIf;
	If pData.Property("mrz_issue_date") And vGuestData.Property("IdentityDocumentIssueDate") Then
		vIdentityDocumentIssueDateStr = pData.mrz_issue_date;
		vGuestData.IdentityDocumentIssueDate = GetDateFromString(vIdentityDocumentIssueDateStr.value);
		If vIdentityDocumentIssueDateStr.Property("is_Accepted") Then
			If vIdentityDocumentIssueDateStr.is_Accepted = "false" Then
			  vRecognitionQuality.Insert("IdentityDocumentIssueDate", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentIssueDate", 70);
		EndIf;	
	EndIf;
	If pData.Property("mrz_expiry_date") And vGuestData.Property("IdentityDocumentValidToDate") Then
		vIdentityDocumentValidToDateStr = pData.mrz_expiry_date;
		vGuestData.IdentityDocumentValidToDate = GetDateFromString(vIdentityDocumentValidToDateStr.value);
		If vIdentityDocumentValidToDateStr.Property("is_Accepted") Then
			If vIdentityDocumentValidToDateStr.is_Accepted = "false" Then
			  vRecognitionQuality.Insert("IdentityDocumentValidToDate", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentValidToDate", 70);
		EndIf;	
	EndIf;
	If pData.Property("mrz_nationality") And vGuestData.Property("Citizenship") Then
		vCitizenshipStr = pData.mrz_nationality;
		vGuestData.Citizenship = tcOnServer.GetCountryByCode(TrimAll(vCitizenshipStr.value));
		If vCitizenshipStr.Property("is_Accepted") Then
			If vCitizenshipStr.is_Accepted = "false" Then
			  vRecognitionQuality.Insert("Citizenship", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("Citizenship", 70);
		EndIf;	
	EndIf;
EndProcedure // FillGuestDataFromMRZ

// -----------------------------------------------------------------------------
Procedure FillStructuresFields(pGuestData, pFieldStruct, pDocField, pRecognitionQuality)
	// Fill value
	pGuestData[pDocField.Value] = pFieldStruct.value;
	// Fill recognition quality
	If FormatBoolean(pFieldStruct.is_accepted) Then
		pRecognitionQuality.Insert(pDocField.Value, 80);
	Else
		pRecognitionQuality.Insert(pDocField.Value, 70);
	EndIf;
EndProcedure // FillStructuresFields

// -----------------------------------------------------------------------------
//  Format string to boolean
//
// Parameters:
//  pString	 - String	 - String boolean literal
// 
// Returns:
//  Boolean - 1C boolean literal
//
Function FormatBoolean(pString)
	Return Format(pString, "BF=false; BT=true");
EndFunction// FormatBoolean

// -----------------------------------------------------------------------------
Function GetDateFromString(pDateStr,pCutOffYear = 0)
	vDate = '00010101';
	Try
		If Not IsBlankString(pDateStr) Then 
			If StrLen(pDateStr) = 10 Then
				vDay = Number(Left(pDateStr, 2));
				vMonth = Number(Mid(pDateStr, 4, 2));
				vYear = Number(Right(pDateStr, 4));
				vDate = Date(vYear, vMonth, vDay);
			ElsIf StrLen(pDateStr) = 8 Then
				vDay = Number(Right(pDateStr, 2));
				vMonth = Number(Mid(pDateStr, 4, 2));
				vYear = Number(Left(pDateStr, 2));
				If pCutOffYear = 0 Then
					If vYear > (Year(CurrentDate()) - 2000) Then
						vYear = 1900 + vYear;
					Else
						vYear = 2000 + vYear;
					EndIf;
				ElsIf vYear > pCutOffYear Then
					vYear = 1900 + vYear;
				Else
					vYear = 2000 + vYear;
				EndIf;
				vDate = Date(vYear, vMonth, vDay);
			EndIf;
		EndIf;
	Except
		vDate = '00010101';
	EndTry;
	Return vDate;
EndFunction

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
//  Get error message by code
//
// Parameters:
//  pResult			 - Structure - Result of HTTP request
//  pCurrentMethod	 - String	 - HTTP request method
// 
// Returns:
//  String - Error message
//
Function GetErrorMessage(pResult, pCurrentMethod)
	vStatusCode = pResult.StatusCode;
	If pCurrentMethod = "CaptureDocument" Then
		If vStatusCode = 400 Then
			rMessage = NStr("en='The document is not recognized or is not placed on the SmartPassportBox!';
							|ru='Документ не распознан или не размещен на SmartPassportBox!';
							|de='Das Dokument wird nicht erkannt oder befindet sich nicht in der SmartPassportBox!'");
		EndIf;
	Else
		If vStatusCode = 400 Then
			rMessage = NStr("en='The document area does not exist or is not recognized!';
							|ru='Область документа не существует или не распознана!';
							|de='Der Dokumentenbereich existiert nicht oder wird nicht erkannt!'");
		ElsIf vStatusCode = 424 Then
			rMessage = NStr("en='Areas are missing or not recognized!';
							|ru='Области отсутствуют или не распознаны!';
							|de='Bereiche fehlen oder werden nicht erkannt!'");
		EndIf;
	EndIf;
	If vStatusCode = Undefined Then
		rMessage = pResult.Error;
	EndIf;
	// Not specified in documentation
	If vStatusCode = 500 Then
		Try
			vResStruct = GetResultStructure(pResult, pCurrentMethod);
			If vResStruct.Count() > 0 Then
				If vResStruct.Property("innerError") Then
					rMessage = vResStruct.innerError.message;
				EndIf;
			EndIf;
		Except
		EndTry;
	EndIf;
	
	Return rMessage;
EndFunction // GetErrorMessage

#EndRegion
