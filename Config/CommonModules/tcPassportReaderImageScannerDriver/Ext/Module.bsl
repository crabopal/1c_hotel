
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMessage - String - Error message 
// 
// Returns:
//  ComObject - ComObject images scanner
//
Function pmConnect(rMessage = "") Export 
	#IF NOT WebClient AND NOT MobileClient THEN
		// Reset return status
		rMessage = "";
		// Try to load external component
		Try
			// Use Abbyy ActiveX object
			If amImageScannerInstance = Undefined Then
				vScanComponentInstallationPath = TrimAll(tcDevicesConnection.cmGetImagesScannerParameters("ScanComponentInstallationPath"));
				vProjectId = TrimAll(CachedCommonFunctions.cmGetContentAIProjectId());
				If Not IsBlankString(vScanComponentInstallationPath) Then
					If Right(vScanComponentInstallationPath, 1) <> "\" Then
						vScanComponentInstallationPath = vScanComponentInstallationPath + "\";
					EndIf;
				EndIf;
				vImageScannerDriver = tcDevicesConnection.cmGetImagesScannerParameters("ImageScannerDriver");
				If vImageScannerDriver = PredefinedValue("Enum.ImageScannerDrivers.AbbyyPassportReaderSDKEngine") Then
					DriverType = "ABBYY";
				ElsIf vImageScannerDriver = PredefinedValue("Enum.ImageScannerDrivers.ContentAIPassportReaderSDKEngine") Then
					DriverType = "ContentAI";
					If IsBlankString(vProjectId) Then
						vErr = NStr("en='The developer Id is not specified in the information database settings!';
									|ru='В настройках информационной базы не указан Id разработчика!';
									|de='Die Entwickler-ID ist in den Einstellungen der Informationsdatenbank nicht angegeben!'");
						Raise vErr; 	
					EndIf;
				EndIf;
				If DriverType = "ContentAI" Then      
					// Content AI PassportReader SDK
					vScObj = New COMObject("PassportReader.SDK.RecognitionEngine");
				Else
					// ABBYY PassportReader SDK
					vScObj = New COMObject("ABBYY.PassportReaderSdk.RecognitionEngine");
				EndIf;
				Try
					If DriverType = "ContentAI" Then
						vInitParams = New COMObject("PassportReader.SDK.InitParams");
						vInitParams.AppDataPath = ?(ValueIsFilled(vScanComponentInstallationPath), vScanComponentInstallationPath, NULL);
						vInitParams.CustomerProjectId = vProjectId;
						vInitParams.LicensePassword = NULL;
						vInitParams.LicensePath = NULL;
						vInitParams.FCEnginePath = NULL;
						vInitParams.TemplatesPath = NULL;
						vScObj.Init(vInitParams);
					Else
						vScObj.Init();
					EndIf;
					// Set some options
					vScObj.ImageQuality = 0;
					vScObj.ImageResolution = 300;
					// Set current scanner
					vTwainDeviceName = tcDevicesConnection.cmGetImagesScannerParameters("TwainDeviceName");
					If Not IsBlankString(vTwainDeviceName) Then
						vCount = vScObj.ScannersCount;
						For i = 0 To (vCount - 1) Do
							vName = vScObj.ScannerName(i);
							If vName = vTwainDeviceName Then
								vScObj.CurrentScanSource = i;
								Break;
							EndIf;
						EndDo;
					EndIf;
					// Change scanner settings
					vSettings = vScObj.GetScanSettings();
					vSettings.Set("interface-type", "None");
					vSettings.Set("resolution", "300");
					If DriverType = "ContentAI" Then
						vSettings.Set("compression", "NoCompression");
					Else
						vSettings.Set("compression", "False");
					EndIf;
					vSettings.Set("paper-size", "A4");
					vPSCode = GetPaperSize(Undefined);
					If Not IsBlankString(vPSCode) Then
						vSettings.Set("paper-size", vPSCode);
					EndIf;
					vScObj.SetScanSettings(vSettings);
				Except
					rMessage = BriefErrorDescription(ErrorInfo());
				EndTry;
			Else
				vScObj = amImageScannerInstance;
			EndIf;
			// OK
			Return vScObj;
		Except       
			vMsg = NStr("en = 'Image scanner connection error: %1'; 
						|de = 'Verbindungsfehler beim Bildscanner: %1'; 
						|ru = 'Ошибка подключения сканера изображений: %1'");
			rMessage = StrTemplate(vMsg, BriefErrorDescription(ErrorInfo()));
			Return Undefined;
		EndTry;
	#ELSE
		ShowMessageBox(,NStr("en = 'Image scanning not supported in Web or Mobile client'; 
							 |de = 'Das Scannen von Bildern wird im Web oder Mobile-Client nicht unterstützt'; 
							 |ru = 'Сканирование изображений не поддерживается в Web и Mobile клиентах'"));
		Return Undefined;
	#ENDIF
EndFunction

// -----------------------------------------------------------------------------
//  Disconnect images scanner
//
// Parameters:
//  pScObj	 - ComObject - ComObject images scanner
//
Procedure pmDisconnect(pScObj) Export
	#If WebClient Then
		Return;
	#EndIf
	Try
		pScObj.Close();
		pScObj = Undefined;
	Except
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
//  Scan document
//
// Parameters:
//  pInputParameters - Structure - Input parameters
//  pOuputParameters - Structure - Output parameters
//  rMessage		 - String	 - The string to which the error message is written.
//
Procedure ScanDocument(pInputParameters, pOuputParameters, rMessage = "") Export
	#IF NOT WebClient AND NOT MobileClient THEN
		vScObj = amImageScannerInstance;
		If vScObj = Undefined Then
			vScObj = pmConnect(rMessage);
			If Not IsBlankString(rMessage) Or vScObj = Undefined Then
				Return;
			EndIf; 
		EndIf; 
		vUUID = pInputParameters.FormUUID;
		If Not ValueIsFilled(vUUID) Then
			vUUID = New UUID;
		EndIf; 
		vScanConfiguration = pInputParameters.ScanConfiguration;
		// Scanner was connected
		Try
			// Get scanner settings
			vSettings = vScObj.GetScanSettings();
			// Set document paper size
			vPSCode = GetPaperSize(vScanConfiguration);
			If Not IsBlankString(vPSCode) Then
				vSettings.Set("paper-size", vPSCode);
			EndIf;
			// Set document rotation
			vRotation = GetRotation(vScanConfiguration);
			If Not IsBlankString(vRotation) Then
				vSettings.Set("rotation-angle", vRotation);
			EndIf;
			// Set document color depth
			vColorDepthCode = GetColorDepth(vScanConfiguration);
			If Not IsBlankString(vColorDepthCode) Then
				vSettings.Set("picture-mode", vColorDepthCode);
			EndIf;
			// Set scanner settings
			vScObj.SetScanSettings(vSettings);
			// Acquire image
			vPictFileName = vScObj.Scan();
			
			vImageScannerDriver = tcDevicesConnection.cmGetImagesScannerParameters("ImageScannerDriver");

			ConvertImage(vPictFileName + ".jpg", vPictFileName);
			vPic = New Picture(vPictFileName + ".jpg");
			
			// Save document picture
			pOuputParameters.IdentityDocumentPicture = PutToTempStorage(vPic,vUUID);
			
			vAutoRecognition = tcDevicesConnection.cmGetImagesScannerParameters("AutoRecognition");
			vScanConfigName = "Passport";
			vScanConfigName = vScanConfigName + "_RU";
			If Not IsBlankString(vScanConfiguration.ScanConfigurationName) Then
				vScanConfigName = vScanConfiguration.ScanConfigurationName;
			ElsIf vScanConfiguration.RecognitionIsAvailable Then
				vMsg = NStr("en = 'No recognition configuration specified for scan configuration.'; 
							|de = 'Keine Erkennungskonfiguration für die Scan-Konfiguration angegeben.'; 
							|ru = 'Для конфигурации сканирования не указана конфигурация распознавания.'");
				tcCommonFunctionOnClientServer.TextMessage(vMsg);
			EndIf; 
			If vAutoRecognition = True And vScanConfiguration.RecognitionIsAvailable Then
				vFields = vScObj.Recognize(vPictFileName, vScanConfigName);
				// Check if any fields were filled
				If vFields = Undefined Or vFields.Count = 0 Then  
					vErr = NStr("en='Recognition is not supported for the client identification document type choosen!';
								|ru='Распознавание для данного вида документа удостоверяющего личность не поддерживается!';
								|de='Die Erkennung dieser Art des Identitätsnachweises wird nicht unterstützt!'");
					Raise vErr; 
				EndIf;
				FillGuestData(vFields, pOuputParameters, vUUID, vScanConfiguration);
			EndIf; 
			// Delete working images
			Try
				BeginDeletingFiles(New NotifyDescription, vPictFileName);
				BeginDeletingFiles(New NotifyDescription, vPictFileName + ".jpg");
			Except
			EndTry;
		Except
			rMessage = BriefErrorDescription(ErrorInfo());
			tcOnServer.cmWriteLogEventAtServer(NStr("en='ImageScannerDriver.ScanDocument';ru='СканерИзображений.СканироватьДокумент';de='ImageScannerDriver.ScanDocument'"),,,,ErrorDescription());
		EndTry;
	#EndIf
EndProcedure //  ScanDocument()

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMessage - String - Error message 
// 
// Returns:
//  ValueList - List of TWAIN devices
//
Function pmGetListOfTWAINDevices(rMessage = "") Export
	vList = New ValueList();
	// Reset return status
	rMessage = "";
	// Try to load external component
	vScObj = pmConnect(rMessage);
	If vScObj <> Undefined Then 
		Try
			vImageScannerDriver = tcDevicesConnection.cmGetImagesScannerParameters("ImageScannerDriver");

			// Get list of TWAIN devices
			vCount = vScObj.ScannersCount;
			For i = 0 To (vCount - 1) Do
				Try
					vName = vScObj.ScannerName(i);
					If Not IsBlankString(vName) Then
						vList.Add(vName);
					Else
						Break;
					EndIf;
				Except
					Break;
				EndTry;
			EndDo;
		Except
			rMessage = ErrorDescription();
		EndTry;
	EndIf;
	Return vList;
EndFunction // pmGetListOfTWAINDevices

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMessage - String - Error message 
// 
// Returns:
//  ValueList - List of allowed configurations
//
Function pmGetListOfAllowedConfigurations(rMessage = "") Export
	vList = New ValueList();
	// Reset return status
	rMessage = "";
	// Try to load external component
	vScObj = pmConnect(rMessage);
	If vScObj <> Undefined Then 
		Try
			// Get list of allowed documents
			vForms = vScObj.AllowedDocuments();
			For i = 0 To (vForms.Count - 1) Do
				vList.Add(vForms.Name(i));
			EndDo;
		Except
			rMessage = ErrorDescription();
		EndTry;
	EndIf;
	Return vList;
EndFunction // pmGetListOfAllowedConfigurations

// -----------------------------------------------------------------------------
//  Recognize document
//
// Parameters:
//  pFormClientDataScans - ManagedForm	 - Form document
//  rMessage			 - String		 - Will be put eroor
// 
// Returns:
//  Boolean - True Or False,  Result recognize document
//
Function RecognizeDocument(pFormClientDataScans, rMessage) Export
	vUUID = pFormClientDataScans.UUID;
	#IF NOT WebClient AND NOT MobileClient THEN
		vScObj = amImageScannerInstance;
		If vScObj = Undefined Then
			vScObj = pmConnect(rMessage);
			If Not IsBlankString(rMessage) Or vScObj = Undefined Then
				Return False;
			EndIf; 
		EndIf; 
		If Not vScObj = Undefined Then
			vGuestData = pFormClientDataScans.Object;
			vRecognitionQuality = pFormClientDataScans.Object.RecognitionQuality;
			vRecognitionQuality.Clear();
			Try
				vImageScannerDriver = tcDevicesConnection.cmGetImagesScannerParameters("ImageScannerDriver");
				
				For Each vCurRow In vGuestData.ScanPictures Do
					If Not vCurRow.RecognitionIsAvailable Then
						// Skip recognition
						Continue;
					EndIf;
					If IsBlankString(vCurRow.TempStorage) Then
						Continue;
					EndIf; 
					vPictFileName = GetTempFileName("jpg");
					vPicture = GetFromTempStorage(vCurRow.TempStorage);
					If vPicture = Undefined Then
						Continue;
					EndIf;
					vPicture.Write(vPictFileName);
					
					vScanConfiguration = tcOnServer.cmGetAtributeAsArray(vCurRow.ScanConfiguration);
					
					vFields = vScObj.Recognize(vPictFileName, vScanConfiguration.ScanConfigurationName);
					// Check if any fields were filled
					If vFields = Undefined Or vFields.Count = 0 Then
						rMessage =  NStr("en='Recognition is not supported for the client identification document type choosen!';ru='Распознавание для данного вида документа удостоверяющего личность не поддерживается!';de='Die Erkennung dieser Art des Identitätsnachweises wird nicht unterstützt!'");
						Return False;
					EndIf;
					
					// Check identification document type
					vIdentityDocumentTypeCode = TrimAll(tcOnServer.cmGetAttributeByRef(vScanConfiguration.IdentityDocumentType, "Code"));
					vIdentityDocumentTypeUFMSCode = TrimAll(tcOnServer.cmGetAttributeByRef(vScanConfiguration.IdentityDocumentType, "ExternalCode"));
					
					If ValueIsFilled(vScanConfiguration.IdentityDocumentType) And (vIdentityDocumentTypeCode = "21" Or vIdentityDocumentTypeUFMSCode = "103008") And
						Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsVisa Then // Russian passport
						// Last name   
						InsertIfNotEmpty(vGuestData.LastName, Title(GetFieldValue(vFields, "LastName")));
						FillQualityState(vRecognitionQuality, vFields.Field("LastName"), "LastName");
						// First name   
						InsertIfNotEmpty(vGuestData.FirstName, Title(GetFieldValue(vFields, "FirstName")));
						FillQualityState(vRecognitionQuality, vFields.Field("FirstName"), "FirstName");
						// Second name
						InsertIfNotEmpty(vGuestData.SecondName, Title(GetFieldValue(vFields, "MiddleName")));
						FillQualityState(vRecognitionQuality, vFields.Field("MiddleName"), "SecondName");
						// Sex   
						vSex = GetClientSex(GetFieldValue(vFields, "Sex"));
						If ValueIsFilled(vSex) Then
							InsertIfNotEmpty(vGuestData.Sex, vSex);
						EndIf;
						FillQualityState(vRecognitionQuality, vFields.Field("Sex"), "Sex");
						// Date of birth   
						vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
						InsertIfNotEmpty(vGuestData.DateOfBirth, GetDateFromString(vDateOfBirth));
						FillQualityState(vRecognitionQuality, vFields.Field("DateOfBirth"), "DateOfBirth");
						// Place of birth
						InsertIfNotEmpty(vGuestData.PlaceOfBirth, "РОССИЯ, , , , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), Chars.LF, " "));
						FillQualityState(vRecognitionQuality, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
						// ID type
						InsertIfNotEmpty(vGuestData.IdentityDocumentType, vScanConfiguration.IdentityDocumentType);
						// ID series
						InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, StrReplace(GetFieldValue(vFields, "Series2"), " ", ""));
						FillQualityState(vRecognitionQuality, vFields.Field("Series2"), "IdentityDocumentSeries");
						// ID number   
						InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, GetFieldValue(vFields, "Number2"));
						FillQualityState(vRecognitionQuality, vFields.Field("Number2"), "IdentityDocumentNumber");
						// Issued date   
						vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
						InsertIfNotEmpty(vGuestData.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate));
						FillQualityState(vRecognitionQuality, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
						// Issued by   
						If vFields.Field("DepartmentCode") <> Undefined Then
							vQlt = vFields.Field("DepartmentCode");
							InsertIfNotEmpty(vGuestData.IdentityDocumentUnitCode, GetFieldValue(vFields, "DepartmentCode"));
							FillQualityState(vRecognitionQuality, vQlt, "IdentityDocumentUnitCode");
							If ValueIsFilled(vGuestData.IdentityDocumentUnitCode) And vQlt.Quality > 80 Then
								InsertIfNotEmpty(vGuestData.IdentityDocumentIssuedBy, tcOnServer.qmGetIssuedBy(TrimAll(vGuestData.IdentityDocumentUnitCode)));
							Else	
								InsertIfNotEmpty(vGuestData.IdentityDocumentIssuedBy, StrReplace(GetFieldValue(vFields, "IssuedBy"), Chars.LF, " "));
								FillQualityState(vRecognitionQuality, vFields.Field("IssuedBy"), "IdentityDocumentIssuedBy");
							EndIf;
						EndIf;
						// Photo
						vRecPhoto = vFields.Field("Photo");
						If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
							pFormClientDataScans.Photo = PutToTempStorage(New Picture(vRecPhoto.SaveTemp(0)),vUUID);
							FillQualityState(vRecognitionQuality, vRecPhoto, "Photo");
						EndIf;
						// Signature
						vRecSignature = vFields.Field("Signature");
						If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
							pFormClientDataScans.Signature = PutToTempStorage(New Picture(vRecSignature.SaveTemp(0)),vUUID);
							FillQualityState(vScanConfiguration, vRecSignature, "Signature");
						EndIf;
						
					ElsIf ValueIsFilled(vScanConfiguration.IdentityDocumentType) And vIdentityDocumentTypeCode = "30" And
						Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsVisa Then // Drivers license
						
						// Last name   
						InsertIfNotEmpty(vGuestData.LastName, Title(GetFieldValue(vFields, "LastName")));
						FillQualityState(vRecognitionQuality, vFields.Field("LastName"), "LastName");
						// First name   
						InsertIfNotEmpty(vGuestData.FirstName, Title(GetFieldValue(vFields, "FirstName")));
						FillQualityState(vRecognitionQuality, vFields.Field("FirstName"), "FirstName");
						// Second name
						InsertIfNotEmpty(vGuestData.SecondName, Title(GetFieldValue(vFields, "MiddleName")));
						FillQualityState(vRecognitionQuality, vFields.Field("MiddleName"), "SecondName");
						// Sex   
						vSex = GetSexByNames(vGuestData.LastName, vGuestData.FirstName, vGuestData.SecondName);
						If ValueIsFilled(vSex) Then
							InsertIfNotEmpty(vGuestData.Sex, vSex);
						EndIf;
						// Date of birth   
						vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
						InsertIfNotEmpty(vGuestData.DateOfBirth, GetDateFromString(vDateOfBirth));
						FillQualityState(vRecognitionQuality, vFields.Field("DateOfBirth"), "DateOfBirth");
						// Place of birth
						InsertIfNotEmpty(vGuestData.PlaceOfBirth, "РОССИЯ, , , , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), Chars.LF, " "));
						FillQualityState(vRecognitionQuality, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
						// ID type
						InsertIfNotEmpty(vGuestData.IdentityDocumentType, vScanConfiguration.IdentityDocumentType);
						// ID series
						InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, StrReplace(GetFieldValue(vFields, "Series"), " ", ""));
						FillQualityState(vRecognitionQuality, vFields.Field("Series"), "IdentityDocumentSeries");
						// ID number   
						InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
						FillQualityState(vRecognitionQuality, vFields.Field("Number"), "IdentityDocumentNumber");
						// Issued date   
						vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
						InsertIfNotEmpty(vGuestData.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate));
						FillQualityState(vRecognitionQuality, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
						// Expire date   
						vIdentityDocumentValidToDate = GetFieldValue(vFields, "DateOfExpiry");
						InsertIfNotEmpty(vGuestData.IdentityDocumentValidToDate, GetDateFromString(vIdentityDocumentValidToDate, 90));
						FillQualityState(vRecognitionQuality, vFields.Field("DateOfExpiry"), "IdentityDocumentIssueDate");
						// Photo
						vRecPhoto = vFields.Field("Photo");
						If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
							pFormClientDataScans.Photo = PutToTempStorage(New Picture(vRecPhoto.SaveTemp(0)),vUUID);
							FillQualityState(vRecognitionQuality, vRecPhoto, "Photo");
						EndIf;
						// Signature
						vRecSignature = vFields.Field("Signature");
						If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
							pFormClientDataScans.Signature = PutToTempStorage(New Picture(vRecSignature.SaveTemp(0)),vUUID);
							FillQualityState(vScanConfiguration, vRecSignature, "Signature");
						EndIf;
						
					ElsIf ValueIsFilled(vScanConfiguration.IdentityDocumentType) And (vIdentityDocumentTypeCode = "03" Or vIdentityDocumentTypeUFMSCode = "102974") And
					      Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsVisa Then // Birth certificate
						
						// Last name   
						InsertIfNotEmpty(vGuestData.LastName, Title(GetFieldValue(vFields, "LastName")));
						FillQualityState(vRecognitionQuality, vFields.Field("LastName"), "LastName");
						// First name   
						InsertIfNotEmpty(vGuestData.FirstName, Title(GetFieldValue(vFields, "FirstName")));
						FillQualityState(vRecognitionQuality, vFields.Field("FirstName"), "FirstName");
						// Second name
						InsertIfNotEmpty(vGuestData.SecondName, Title(GetFieldValue(vFields, "MiddleName")));
						FillQualityState(vRecognitionQuality, vFields.Field("MiddleName"), "SecondName");
						// Sex   
						vSex = GetSexByNames(vGuestData.LastName, vGuestData.FirstName, vGuestData.SecondName);
						If ValueIsFilled(vSex) Then
							InsertIfNotEmpty(vGuestData.Sex, vSex);
						EndIf;
						// Date of birth   
						vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
						InsertIfNotEmpty(vGuestData.DateOfBirth, GetDateFromString(vDateOfBirth));
						FillQualityState(vRecognitionQuality, vFields.Field("DateOfBirth"), "DateOfBirth");
						// Place of birth
						InsertIfNotEmpty(vGuestData.PlaceOfBirth, "РОССИЯ, , , , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), Chars.LF, " "));
						FillQualityState(vRecognitionQuality, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
						// ID type
						InsertIfNotEmpty(vGuestData.IdentityDocumentType, vScanConfiguration.IdentityDocumentType);
						// ID series
						InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, StrReplace(GetFieldValue(vFields, "Series"), " ", ""));
						FillQualityState(vRecognitionQuality, vFields.Field("Series"), "IdentityDocumentSeries");
						// ID number   
						InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
						FillQualityState(vRecognitionQuality, vFields.Field("Number"), "IdentityDocumentNumber");
						// Issued date   
						vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
						InsertIfNotEmpty(vGuestData.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate));
						FillQualityState(vRecognitionQuality, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
						
						InsertIfNotEmpty(vGuestData.IdentityDocumentIssuedBy, StrReplace(GetFieldValue(vFields, "IssuedBy"), Chars.LF, " "));
						FillQualityState(vRecognitionQuality, vFields.Field("IssuedBy"), "IdentityDocumentIssuedBy");
						
					ElsIf ValueIsFilled(vScanConfiguration.IdentityDocumentType) And (vIdentityDocumentTypeCode  = "ИП" Or vIdentityDocumentTypeUFMSCode = "103012") And
						Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsVisa Then // Foreign passport
						
						// Last name   
						InsertIfNotEmpty(vGuestData.LastName, Title(GetFieldValue(vFields, "LastName")));
						FillQualityState(vScanConfiguration, vFields.Field("LastName"), "LastName");
						// First name   
						InsertIfNotEmpty(vGuestData.FirstName, Title(GetFieldValue(vFields, "FirstName")));
						FillQualityState(vScanConfiguration, vFields.Field("FirstName"), "FirstName");
						// Second name
						InsertIfNotEmpty(vGuestData.SecondName, "");
						// Sex   
						vSex = GetClientSex(GetFieldValue(vFields, "Sex"));
						If ValueIsFilled(vSex) Then
							InsertIfNotEmpty(vGuestData.Sex, vSex);
						EndIf;
						FillQualityState(vScanConfiguration, vFields.Field("Sex"), "Sex");
						// Date of birth   
						vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
						InsertIfNotEmpty(vGuestData.DateOfBirth, GetDateFromString(vDateOfBirth));
						FillQualityState(vScanConfiguration, vFields.Field("DateOfBirth"), "DateOfBirth");
						// Place of birth
						InsertIfNotEmpty(vGuestData.PlaceOfBirth, TrimAll(vGuestData.Citizenship) + ", , , , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), chars.LF, " "));
						FillQualityState(vScanConfiguration, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
						// ID type
						InsertIfNotEmpty(vGuestData.IdentityDocumentType, vScanConfiguration.IdentityDocumentType);
						// ID Series
						InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, "");
						// ID number   
						InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
						FillQualityState(vScanConfiguration, vFields.Field("Number"), "IdentityDocumentNumber");
						// Issue date   
						vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
						InsertIfNotEmpty(vGuestData.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate, 90));
						FillQualityState(vScanConfiguration, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
						// Expire date   
						vIdentityDocumentValidToDate = GetFieldValue(vFields, "DateOfExpiry");
						InsertIfNotEmpty(vGuestData.IdentityDocumentValidToDate, GetDateFromString(vIdentityDocumentValidToDate, 90));
						FillQualityState(vScanConfiguration, vFields.Field("DateOfExpiry"), "IdentityDocumentIssueDate");
						// Issued by   
						InsertIfNotEmpty(vGuestData.IdentityDocumentIssuedBy, StrReplace(GetFieldValue(vFields, "IssuedBy"), Chars.LF, " "));
						FillQualityState(vScanConfiguration, vFields.Field("IssuedBy"), "IdentityDocumentIssuedBy");
						// Photo
						vRecPhoto = vFields.Field("Photo");
						If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
							pFormClientDataScans.Photo = PutToTempStorage(New Picture(vRecPhoto.SaveTemp(0)),vUUID);
							FillQualityState(vRecognitionQuality, vRecPhoto, "Photo");
						EndIf;
						// Signature
						vRecSignature = vFields.Field("Signature");
						If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
							pFormClientDataScans.Signature = PutToTempStorage(New Picture(vRecSignature.SaveTemp(0)),vUUID);
							FillQualityState(vScanConfiguration, vRecSignature, "Signature");
						EndIf;
						
					ElsIf ValueIsFilled(vScanConfiguration.IdentityDocumentType) And (vIdentityDocumentTypeCode = "22" Or vIdentityDocumentTypeUFMSCode = "103007") And
						Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsVisa Then // Russian foreign passport
						
						// Last name   
						InsertIfNotEmpty(vGuestData.LastName, Title(GetFieldValue(vFields, "LastName")));
						FillQualityState(vScanConfiguration, vFields.Field("LastName"), "LastName");
						// First name   
						InsertIfNotEmpty(vGuestData.FirstName, Title(GetFieldValue(vFields, "FirstName")));
						FillQualityState(vScanConfiguration, vFields.Field("FirstName"), "FirstName");
						// Second name
						InsertIfNotEmpty(vGuestData.SecondName, "");
						// Sex   
						vSex = GetClientSex(GetFieldValue(vFields, "Sex"));
						If ValueIsFilled(vSex) Then
							InsertIfNotEmpty(vGuestData.Sex, vSex);
						EndIf;
						FillQualityState(vScanConfiguration, vFields.Field("Sex"), "Sex");
						// Date of birth   
						vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
						InsertIfNotEmpty(vGuestData.DateOfBirth, GetDateFromString(vDateOfBirth));
						FillQualityState(vScanConfiguration, vFields.Field("DateOfBirth"), "DateOfBirth");
						// Place of birth
						InsertIfNotEmpty(vGuestData.PlaceOfBirth, "РОССИЯ, , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), Chars.LF, " "));
						FillQualityState(vScanConfiguration, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
						// ID type
						InsertIfNotEmpty(vGuestData.IdentityDocumentType, vScanConfiguration.IdentityDocumentType);
						// ID Series
						InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, "");
						// ID number   
						InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
						FillQualityState(vScanConfiguration, vFields.Field("Number"), "IdentityDocumentNumber");
						If Not IsBlankString(vGuestData.IdentityDocumentNumber) Then
							If StrLen(TrimAll(vGuestData.IdentityDocumentNumber)) > 8 Then
								InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, Left(TrimAll(vGuestData.IdentityDocumentNumber), 2));
								InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, Mid(TrimAll(vGuestData.IdentityDocumentNumber), 3));
							EndIf;
						EndIf;
						// Issue date   
						vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
						InsertIfNotEmpty(vGuestData.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate, 90));
						FillQualityState(vScanConfiguration, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
						// Expire date   
						vIdentityDocumentValidToDate = GetFieldValue(vFields, "DateOfExpiry");
						InsertIfNotEmpty(vGuestData.IdentityDocumentValidToDate, GetDateFromString(vIdentityDocumentValidToDate, 90));
						FillQualityState(vScanConfiguration, vFields.Field("DateOfExpiry"), "IdentityDocumentValidToDate");
						// Issued by   
						InsertIfNotEmpty(vGuestData.IdentityDocumentIssuedBy, StrReplace(GetFieldValue(vFields, "IssuedBy"), Chars.LF, " "));
						FillQualityState(vScanConfiguration, vFields.Field("IssuedBy"), "IdentityDocumentIssuedBy");
						// Photo
						vRecPhoto = vFields.Field("Photo");
						If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
							pFormClientDataScans.Photo = PutToTempStorage(New Picture(vRecPhoto.SaveTemp(0)),vUUID);
							FillQualityState(vRecognitionQuality, vRecPhoto, "Photo");
						EndIf;
						// Signature
						vRecSignature = vFields.Field("Signature");
						If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
							pFormClientDataScans.Signature = PutToTempStorage(New Picture(vRecSignature.SaveTemp(0)),vUUID);
							FillQualityState(vScanConfiguration, vRecSignature, "Signature");
						EndIf;
						
						// Delete working images
						Try
							BeginDeletingFiles(New NotifyDescription, vPictFileName);
						Except
						EndTry;
					EndIf;
				EndDo;
				// Return success
				Return True;
			Except
				rMessage = ErrorDescription();
				tcOnServer.cmWriteLogEventAtServer(NStr("en='ImageScannerDriver.RecognizeDocument';ru='СканерИзображений.РаспознатьДокумент';de='ImageScannerDriver.RecognizeDocument'"),,,,rMessage);
			EndTry;
		EndIf;
	#ENDIF
	Return False;
EndFunction // RecognizeDocument

#EndRegion

#Region Internal

// -----------------------------------------------------------------------------
Procedure FillGuestData(vFields, pOuputParameters, pUUID, pScanConfiguration)
	vGuestData 			= pOuputParameters;
	vRecognitionQuality = pOuputParameters.RecognitionQuality;	
	vGuestData.FillAllItems = True;
	vImageScannerDriver = tcDevicesConnection.cmGetImagesScannerParameters("ImageScannerDriver");
	
	// Check identification document type
	vIdentityDocumentTypeCode = TrimAll(tcOnServer.cmGetAttributeByRef(pScanConfiguration.IdentityDocumentType,"Code"));
	vIdentityDocumentTypeUFMSCode = TrimAll(tcOnServer.cmGetAttributeByRef(pScanConfiguration.IdentityDocumentType, "ExternalCode"));
	
	If ValueIsFilled(pScanConfiguration.IdentityDocumentType) And vIdentityDocumentTypeCode = "21" And
		Not pScanConfiguration.IsMigrationCard And Not pScanConfiguration.IsVisa  Then
		// Last name   
		InsertIfNotEmpty(vGuestData.LastName, Title(GetFieldValue(vFields, "LastName")));
		FillQualityState(vRecognitionQuality, vFields.Field("LastName"), "LastName");
		// First name   
		InsertIfNotEmpty(vGuestData.FirstName, Title(GetFieldValue(vFields, "FirstName")));
		FillQualityState(vRecognitionQuality, vFields.Field("FirstName"), "FirstName");
		// Second name
		InsertIfNotEmpty(vGuestData.SecondName, Title(GetFieldValue(vFields, "MiddleName")));
		FillQualityState(vRecognitionQuality, vFields.Field("MiddleName"), "SecondName");
		// Sex   
		vSex = GetClientSex(GetFieldValue(vFields, "Sex"));
		If ValueIsFilled(vSex) Then
			InsertIfNotEmpty(vGuestData.Sex, vSex);
		EndIf;
		FillQualityState(vRecognitionQuality, vFields.Field("Sex"), "Sex");
		// Date of birth   
		vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
		InsertIfNotEmpty(vGuestData.DateOfBirth, GetDateFromString(vDateOfBirth));
		FillQualityState(vRecognitionQuality, vFields.Field("DateOfBirth"), "DateOfBirth");
		// Place of birth
		InsertIfNotEmpty(vGuestData.PlaceOfBirth, "РОССИЯ, , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), Chars.LF, " "));
		FillQualityState(vRecognitionQuality, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
		// ID type
		InsertIfNotEmpty(vGuestData.IdentityDocumentType, pScanConfiguration.IdentityDocumentType);
		// Citizenship

		// ID series
		InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, StrReplace(GetFieldValue(vFields, "Series2"), " ", ""));
		FillQualityState(vRecognitionQuality, vFields.Field("Series2"), "IdentityDocumentSeries");
		// ID number   
		InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, GetFieldValue(vFields, "Number2"));
		FillQualityState(vRecognitionQuality, vFields.Field("Number2"), "IdentityDocumentNumber");
		// Issued date   
		vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
		InsertIfNotEmpty(vGuestData.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate));
		FillQualityState(vRecognitionQuality, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
		// Issued by
		If vFields.Field("DepartmentCode") <> Undefined Then
			vQlt = vFields.Field("DepartmentCode");
			InsertIfNotEmpty(vGuestData.IdentityDocumentUnitCode, GetFieldValue(vFields, "DepartmentCode"));
			FillQualityState(vRecognitionQuality, vQlt, "IdentityDocumentUnitCode");
			If ValueIsFilled(vGuestData.IdentityDocumentUnitCode) And vQlt.Quality > 80 Then
				InsertIfNotEmpty(vGuestData.IdentityDocumentIssuedBy, tcOnServer.qmGetIssuedBy(TrimAll(vGuestData.IdentityDocumentUnitCode)));
			Else	
				InsertIfNotEmpty(vGuestData.IdentityDocumentIssuedBy, StrReplace(GetFieldValue(vFields, "IssuedBy"), Chars.LF, " "));
				FillQualityState(vRecognitionQuality, vFields.Field("IssuedBy"), "IdentityDocumentIssuedBy");
			EndIf;
		EndIf;
		// Photo
		vRecPhoto = vFields.Field("Photo");
		If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
			vGuestData.Photo = PutToTempStorage(New Picture(vRecPhoto.SaveTemp("0")),pUUID);
			FillQualityState(vRecognitionQuality, vRecPhoto, "Photo");
		EndIf;
		// Signature
		vRecSignature = vFields.Field("Signature");
		If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
			vGuestData.Signature = PutToTempStorage(New Picture(vRecSignature.SaveTemp(0)),pUUID);
			FillQualityState(pScanConfiguration, vRecSignature, "Signature");
		EndIf;
		
	ElsIf ValueIsFilled(pScanConfiguration.IdentityDocumentType) And vIdentityDocumentTypeCode = "30" And
		Not pScanConfiguration.IsMigrationCard And Not pScanConfiguration.IsVisa Then
		
		// Last name   
		InsertIfNotEmpty(vGuestData.LastName, Title(GetFieldValue(vFields, "LastName")));
		FillQualityState(vRecognitionQuality, vFields.Field("LastName"), "LastName");
		// First name   
		InsertIfNotEmpty(vGuestData.FirstName, Title(GetFieldValue(vFields, "FirstName")));
		FillQualityState(vRecognitionQuality, vFields.Field("FirstName"), "FirstName");
		// Second name
		InsertIfNotEmpty(vGuestData.SecondName, Title(GetFieldValue(vFields, "MiddleName")));
		FillQualityState(vRecognitionQuality, vFields.Field("MiddleName"), "SecondName");
		//// Sex
		vSex = GetSexByNames(vGuestData.LastName, vGuestData.FirstName, vGuestData.SecondName);
		If ValueIsFilled(vSex) Then
			InsertIfNotEmpty(vGuestData.Sex, vSex);
		EndIf;
		// Date of birth   
		vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
		InsertIfNotEmpty(vGuestData.DateOfBirth, GetDateFromString(vDateOfBirth));
		FillQualityState(vRecognitionQuality, vFields.Field("DateOfBirth"), "DateOfBirth");
		// Place of birth
		InsertIfNotEmpty(vGuestData.PlaceOfBirth, "РОССИЯ, , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), Chars.LF, " "));
		FillQualityState(vRecognitionQuality, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
		// ID type
		InsertIfNotEmpty(vGuestData.IdentityDocumentType, pScanConfiguration.IdentityDocumentType);
		// Citizenship
		// ID series
		InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, StrReplace(GetFieldValue(vFields, "Series"), " ", ""));
		FillQualityState(vRecognitionQuality, vFields.Field("Series"), "IdentityDocumentSeries");
		// ID number   
		InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
		FillQualityState(vRecognitionQuality, vFields.Field("Number"), "IdentityDocumentNumber");
		// Issued date   
		vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
		InsertIfNotEmpty(vGuestData.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate));
		FillQualityState(vRecognitionQuality, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
		// Expire date   
		vIdentityDocumentValidToDate = GetFieldValue(vFields, "DateOfExpiry");
		vGuestData = GetFieldValue(vFields, "DateOfExpiry");
		InsertIfNotEmpty(vGuestData.IdentityDocumentValidToDate, GetDateFromString(vIdentityDocumentValidToDate, 90));
		FillQualityState(vRecognitionQuality, vFields.Field("DateOfExpiry"), "IdentityDocumentIssueDate");
		// Photo
		vRecPhoto = vFields.Field("Photo");
		If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
			vGuestData.Photo = PutToTempStorage(New Picture(vRecPhoto.SaveTemp("0")),pUUID);
			FillQualityState(vRecognitionQuality, vRecPhoto, "Photo");
		EndIf;
		// Signature
		vRecSignature = vFields.Field("Signature");
		If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
			vGuestData.Signature = PutToTempStorage(New Picture(vRecSignature.SaveTemp(0)),pUUID);
			FillQualityState(pScanConfiguration, vRecSignature, "Signature");
		EndIf;
		
	ElsIf ValueIsFilled(pScanConfiguration.IdentityDocumentType) And vIdentityDocumentTypeCode  = "ИП" And
		Not pScanConfiguration.IsMigrationCard And Not pScanConfiguration.IsVisa Then
		
		// Last name   
		InsertIfNotEmpty(vGuestData.LastName, Title(GetFieldValue(vFields, "LastName")));
		FillQualityState(pScanConfiguration, vFields.Field("LastName"), "LastName");
		// First name   
		InsertIfNotEmpty(vGuestData.FirstName, Title(GetFieldValue(vFields, "FirstName")));
		FillQualityState(pScanConfiguration, vFields.Field("FirstName"), "FirstName");
		// Second name
		InsertIfNotEmpty(vGuestData.SecondName, "");
		// Sex   
		vSex = GetClientSex(GetFieldValue(vFields, "Sex"));
		If ValueIsFilled(vSex) Then
			InsertIfNotEmpty(vGuestData.Sex, vSex);
		EndIf;
		FillQualityState(pScanConfiguration, vFields.Field("Sex"), "Sex");
		// Date of birth   
		vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
		InsertIfNotEmpty(vGuestData.DateOfBirth, GetDateFromString(vDateOfBirth));
		FillQualityState(pScanConfiguration, vFields.Field("DateOfBirth"), "DateOfBirth");
		// Place of birth
		InsertIfNotEmpty(vGuestData.PlaceOfBirth, StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), Chars.LF, " "));
		FillQualityState(pScanConfiguration, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
		// ID type
		InsertIfNotEmpty(vGuestData.IdentityDocumentType, pScanConfiguration.IdentityDocumentType);
		// Citizenship
		FillQualityState(pScanConfiguration, vFields.Field("CodeOfIssuingState"), "Citizenship");
		// ID Series
		InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, "");
		// ID number   
		InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
		FillQualityState(pScanConfiguration, vFields.Field("Number"), "IdentityDocumentNumber");
		// Issue date   
		vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
		InsertIfNotEmpty(vGuestData.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate, 90));
		FillQualityState(pScanConfiguration, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
		// Expire date   
		vIdentityDocumentValidToDate = GetFieldValue(vFields, "DateOfExpiry");
		InsertIfNotEmpty(vGuestData.IdentityDocumentValidToDate, GetDateFromString(vIdentityDocumentValidToDate, 90));
		FillQualityState(pScanConfiguration, vFields.Field("DateOfExpiry"), "IdentityDocumentIssueDate");
		// Issued by   
		InsertIfNotEmpty(vGuestData.IdentityDocumentIssuedBy, StrReplace(GetFieldValue(vFields, "IssuedBy"), Chars.LF, " "));
		FillQualityState(pScanConfiguration, vFields.Field("IssuedBy"), "IdentityDocumentIssuedBy");
		// Photo
		vRecPhoto = vFields.Field("Photo");
		If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
			vGuestData.Photo = PutToTempStorage(New Picture(vRecPhoto.SaveTemp("0")),pUUID);
			FillQualityState(vRecognitionQuality, vRecPhoto, "Photo");
		EndIf;
		// Signature
		vRecSignature = vFields.Field("Signature");
		If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
			vGuestData.Signature = PutToTempStorage(New Picture(vRecSignature.SaveTemp(0)),pUUID);
			FillQualityState(pScanConfiguration, vRecSignature, "Signature");
		EndIf;
		
	ElsIf ValueIsFilled(pScanConfiguration.IdentityDocumentType) And vIdentityDocumentTypeCode = "22" And
		Not pScanConfiguration.IsMigrationCard And Not pScanConfiguration.IsVisa Then
		
		// Last name   
		InsertIfNotEmpty(vGuestData.LastName, Title(GetFieldValue(vFields, "LastName")));
		FillQualityState(pScanConfiguration, vFields.Field("LastName"), "LastName");
		// First name   
		InsertIfNotEmpty(vGuestData.FirstName, Title(GetFieldValue(vFields, "FirstName")));
		FillQualityState(pScanConfiguration, vFields.Field("FirstName"), "FirstName");
		// Second name
		InsertIfNotEmpty(vGuestData.SecondName, "");
		// Sex   
		vSex = GetClientSex(GetFieldValue(vFields, "Sex"));
		If ValueIsFilled(vSex) Then
			InsertIfNotEmpty(vGuestData.Sex, vSex);
		EndIf;
		FillQualityState(pScanConfiguration, vFields.Field("Sex"), "Sex");
		// Date of birth   
		vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
		InsertIfNotEmpty(vGuestData.DateOfBirth, GetDateFromString(vDateOfBirth));
		FillQualityState(pScanConfiguration, vFields.Field("DateOfBirth"), "DateOfBirth");
		// Place of birth
		InsertIfNotEmpty(vGuestData.PlaceOfBirth, "РОССИЯ, , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), Chars.LF, " "));
		FillQualityState(pScanConfiguration, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
		// ID type
		InsertIfNotEmpty(vGuestData.IdentityDocumentType, pScanConfiguration.IdentityDocumentType);
		// Citizenship
		// ID Series
		InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, "");
		// ID number   
		InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
		FillQualityState(pScanConfiguration, vFields.Field("Number"), "IdentityDocumentNumber");
		If Not IsBlankString(vGuestData.IdentityDocumentNumber) Then
			If StrLen(TrimAll(vGuestData.IdentityDocumentNumber)) > 8 Then
				InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, Left(TrimAll(vGuestData.IdentityDocumentNumber), 2));
				InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, Mid(TrimAll(vGuestData.IdentityDocumentNumber), 3));
			EndIf;
		EndIf;
		// Issue date   
		vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
		InsertIfNotEmpty(vGuestData.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate, 90));
		FillQualityState(pScanConfiguration, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
		// Expire date   
		vIdentityDocumentValidToDate = GetFieldValue(vFields, "DateOfExpiry");
		InsertIfNotEmpty(vGuestData.IdentityDocumentValidToDate, GetDateFromString(vIdentityDocumentValidToDate, 90));
		FillQualityState(pScanConfiguration, vFields.Field("DateOfExpiry"), "IdentityDocumentValidToDate");
		// Issued by   
		InsertIfNotEmpty(vGuestData.IdentityDocumentIssuedBy, StrReplace(GetFieldValue(vFields, "IssuedBy"), Chars.LF, " "));
		FillQualityState(pScanConfiguration, vFields.Field("IssuedBy"), "IdentityDocumentIssuedBy");
		// Photo
		vRecPhoto = vFields.Field("Photo");
		If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
			vGuestData.Photo = PutToTempStorage(New Picture(vRecPhoto.SaveTemp("0")),pUUID);
			FillQualityState(vRecognitionQuality, vRecPhoto, "Photo");
		EndIf;
		// Signature
		vRecSignature = vFields.Field("Signature");
		If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
			vGuestData.Signature = PutToTempStorage(New Picture(vRecSignature.SaveTemp(0)),pUUID);
			FillQualityState(pScanConfiguration, vRecSignature, "Signature");
		EndIf;
	ElsIf ValueIsFilled(pScanConfiguration.IdentityDocumentType) And (vIdentityDocumentTypeCode = "03" Or vIdentityDocumentTypeUFMSCode = "102974") And
		Not pScanConfiguration.IsMigrationCard And Not pScanConfiguration.IsVisa Then // Birth certificate
		
		// Last name   
		InsertIfNotEmpty(vGuestData.LastName, Title(GetFieldValue(vFields, "LastName")));
		FillQualityState(vRecognitionQuality, vFields.Field("LastName"), "LastName");
		// First name   
		InsertIfNotEmpty(vGuestData.FirstName, Title(GetFieldValue(vFields, "FirstName")));
		FillQualityState(vRecognitionQuality, vFields.Field("FirstName"), "FirstName");
		// Second name
		InsertIfNotEmpty(vGuestData.SecondName, Title(GetFieldValue(vFields, "MiddleName")));
		FillQualityState(vRecognitionQuality, vFields.Field("MiddleName"), "SecondName");
		// Sex   
		vSex = GetSexByNames(vGuestData.LastName, vGuestData.FirstName, vGuestData.SecondName);
		If ValueIsFilled(vSex) Then
			InsertIfNotEmpty(vGuestData.Sex, vSex);
		EndIf;
		// Date of birth   
		vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
		InsertIfNotEmpty(vGuestData.DateOfBirth, GetDateFromString(vDateOfBirth));
		FillQualityState(vRecognitionQuality, vFields.Field("DateOfBirth"), "DateOfBirth");
		// Place of birth
		InsertIfNotEmpty(vGuestData.PlaceOfBirth, "РОССИЯ, , , , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), Chars.LF, " "));
		FillQualityState(vRecognitionQuality, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
		// ID type
		InsertIfNotEmpty(vGuestData.IdentityDocumentType, pScanConfiguration.IdentityDocumentType);
		// ID series
		InsertIfNotEmpty(vGuestData.IdentityDocumentSeries, StrReplace(GetFieldValue(vFields, "Series"), " ", ""));
		FillQualityState(vRecognitionQuality, vFields.Field("Series"), "IdentityDocumentSeries");
		// ID number   
		InsertIfNotEmpty(vGuestData.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
		FillQualityState(vRecognitionQuality, vFields.Field("Number"), "IdentityDocumentNumber");
		// Issued date   
		vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
		InsertIfNotEmpty(vGuestData.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate));
		FillQualityState(vRecognitionQuality, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
	Else  
		vErr = NStr("en = 'Recognition is not supported for the client identification document type choosen!'; 
					|de = 'Die Erkennung dieser Art des Identitätsnachweises wird nicht unterstützt!'; 
					|ru = 'Распознавание для данного вида документа удостоверяющего личность не поддерживается!'");
		Raise vErr;
	EndIf;
EndProcedure // FillGuestData

// -----------------------------------------------------------------------------
Procedure InsertIfNotEmpty(pDocumentAttribute, pRecognizedField)
	If ValueIsFilled(pRecognizedField) Then
		pDocumentAttribute = pRecognizedField;
	EndIf;
EndProcedure // InsertIfNotEmpty

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
Function GetSexByNames(pLastName, pFirstName, pSecondName)
	If StrLen(TrimAll(pSecondName)) < 2 Тогда
		vLastCharLastName = Upper(Right(TrimAll(pLastName), 1));
		vLastCharFirstName = Upper(Right(TrimAll(pFirstName), 1));
		If (vLastCharLastName = "А") Or (vLastCharLastName = "Я") Or
		   (vLastCharFirstName = "А") Or (vLastCharFirstName = "Я") Then
			Return PredefinedValue("Enum.Sex.Female");
		Else
			Return PredefinedValue("Enum.Sex.Male");
		EndIf;
	Else
		vLastCharSecondName = Upper(Right(TrimAll(pSecondName), 1));
		If vLastCharSecondName = "А" Then
			Return PredefinedValue("Enum.Sex.Female");
		Else
			Return PredefinedValue("Enum.Sex.Male");
		EndIf;
	EndIf;
EndFunction // GetSexByNames

// -----------------------------------------------------------------------------
Function GetPaperSize(pScanConfiguration)
	vPSCode = "";
	vPS = Undefined;
	vPS_SI = tcDevicesConnection.cmGetImagesScannerParameters("PaperSize");
	If ValueIsFilled(pScanConfiguration) And ValueIsFilled(pScanConfiguration.PaperSize) Then
		vPS = pScanConfiguration.PaperSize;
	ElsIf ValueIsFilled(vPS_SI) Then
		vPS = vPS_SI;
	EndIf;
	If ValueIsFilled(vPS) Then
		If vPS = PredefinedValue("Enum.PaperSizes.A0") Then
			vPSCode = "A0";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A1") Then
			vPSCode = "A1";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A2") Then
			vPSCode = "A2";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A3") Then
			vPSCode = "A3";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A4") Then
			vPSCode = "A4";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A5") Then
			vPSCode = "A5";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A6") Then
			Raise NStr("en='Unsupported paper size A6!';ru='Неподдерживаемый размер бумаги A6!';de='Nicht unterstütztes Papier-Format A6!'");
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A7") Then
			Raise NStr("en='Unsupported paper size A7!';ru='Неподдерживаемый размер бумаги A7!';de='Nicht unterstütztes Papier-Format A7!'");
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A8") Then
			Raise NStr("en='Unsupported paper size A8!';ru='Неподдерживаемый размер бумаги A8!';de='Nicht unterstütztes Papierformat A8!'");
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A9") Then
			Raise NStr("en='Unsupported paper size A9!';ru='Неподдерживаемый размер бумаги A9!';de='Nicht unterstütztes Papierformat A9!'");
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A10") Then
			Raise NStr("en='Unsupported paper size A10!';ru='Неподдерживаемый размер бумаги A10!';de='Nicht unterstütztes Papier-Format A10!'");
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.B3") Then
			vPSCode = "B3_ISO";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.B4") Then
			vPSCode = "B4_ISO";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.B5") Then
			vPSCode = "B5_ISO";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.B6") Then
			vPSCode = "B6_ISO";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.C4") Then
			vPSCode = "C4";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.C5") Then
			vPSCode = "C5";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.C6") Then
			vPSCode = "C6";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A40") Then
			vPSCode = "RA4";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.A20") Then
			vPSCode = "RA2";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.USLET") Then
			vPSCode = "Letter";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.USLEG") Then
			vPSCode = "Legal";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.USLEDGER") Then
			vPSCode = "Statement";
		ElsIf vPS = PredefinedValue("Enum.PaperSizes.USEXECUTIVE") Then
			vPSCode = "Executive";
		EndIf;
	EndIf;
	Return vPSCode;
EndFunction // GetPaperSize

// -----------------------------------------------------------------------------
Function GetRotation(pScanConfiguration)
	vRotationCode = "";
	vRotation = 0;
	vRotationSConf = pScanConfiguration.Rotation;
	If ValueIsFilled(pScanConfiguration) And pScanConfiguration.Rotation <> 0 Then
		vRotation = pScanConfiguration.Rotation;
	ElsIf vRotationSConf <> 0 Then
		vRotation = vRotationSConf;
	EndIf;
	If vRotation <> 0 Then
		If vRotation = 90 Then
			vRotationCode = "Rotation90";
		ElsIf vRotation = 180 Then
			vRotationCode = "Rotation180";
		ElsIf vRotation = 270 Then
			vRotationCode = "Rotation270";
		Else     
			vErr = NStr("en='Unsupported rotation angle (90, 180, 270 are allowed)!';
						|ru='Неподдерживаемый угол поворота (разрешены 90, 180, 270)!';
						|de='Nicht unterstützter Drehwinkel (zulässig sind 90, 180, 270)!'");
			Raise vErr;
		EndIf;
	EndIf;
	Return vRotationCode;
EndFunction // GetRotation

// -----------------------------------------------------------------------------
Function GetColorDepth(pScanConfiguration)
	vColorDepthCode = "Color";
	vColorDepth = Undefined;
	vColorDepthSI = tcDevicesConnection.cmGetImagesScannerParameters("ColorDepth");
	If ValueIsFilled(pScanConfiguration) And ValueIsFilled(pScanConfiguration.ColorDepth) Then
		vColorDepth = pScanConfiguration.ColorDepth;
	ElsIf ValueIsFilled(vColorDepthSI) Then
		vColorDepth = vColorDepthSI;
	EndIf;
	If ValueIsFilled(vColorDepth) Then
		If vColorDepth = PredefinedValue("Enum.ColorDepths.RGB") Then
			vColorDepthCode = "Color";
		ElsIf vColorDepth = PredefinedValue("Enum.ColorDepths.Palette") Then 
			vErr = NStr("en='Unsupported color depth (24 bits color, Grayscale, Black&white image are allowed only)!';
					    |ru='Неподдерживаемая глубина цвета (разрешены 24 битный цвет, Оттенки серого, Черно-белая картинка)!';
						|de='Eine nicht unterstützte Farbtiefe (erlaubt sind 24-Bit-Farben, Grauschattierungen, schwarz-weißes Bild)'");
			Raise vErr; 
		ElsIf vColorDepth = PredefinedValue("Enum.ColorDepths.Gray") Then
			vColorDepthCode = "Grayscale";
		ElsIf vColorDepth = PredefinedValue("Enum.ColorDepths.BW") Then
			vColorDepthCode = "BlackAndWhite";
		EndIf;
	EndIf;
	Return vColorDepthCode;
EndFunction // GetColorDepth

// -----------------------------------------------------------------------------
Procedure ConvertImage(pTargetFileName, pSourceFileName)
	#IF NOT WebClient AND NOT MobileClient THEN
		// Build active X object to rotate picture
		Try
			vGFLAx = New COMObject("GFLAx.GFLAx");
		Except
			vMessage = NStr("en='GFLAx (ActiveX/ASP component) should be installed first! Go to the current workstation item settings and press <Install GFLAx (ActiveX/ASP component)> button.';
							|ru='ActiveX/ASP библиотека GFLAx не установлена! Для установки откройте карточку настроек рабочего места и нажмите на кнопку <Установить GFLAx (ActiveX/ASP библиотеку)>.';
							|de='Die ActiveX/ASP-Bibliothek GFLAx wurde nicht installiert! Zur Installation öffnen Sie die Arbeitsplatzeinstellungen und wählen Sie <GFLAx (ActiveX/AP-Bibliothek) installieren)>.'");
			ShowMessageBox(,vMessage);
			Return;
		EndTry;
		Try
			vGFLAx.LoadBitmap(pSourceFileName);
			vGFLAx.SaveformatName = "jpeg";
			vGFLAx.SaveJPEGQuality = 30;
			vGFLAx.SaveBitmap(pTargetFileName);
			vGFLAx = Undefined;
		Except
			vMessage = NStr("en='Unsupported picture format!';ru='Формат картинки не поддерживается!';de='Format des Bilds wird nicht unterstützt!'") + Chars.LF + ErrorDescription();
			ShowMessageBox(,vMessage);
		EndTry;
	#ENDIF
EndProcedure // ConvertImage

// -----------------------------------------------------------------------------
Function GetFieldValue(pFields, pID)
	vFieldItem = pFields.Field(pID);
	If vFieldItem <> Undefined Then
		Return vFieldItem.Value;
	Else
		Return "";
	EndIf;
EndFunction // GetFieldValue

// -----------------------------------------------------------------------------
Procedure FillQualityState(pRecognitionQuality, pRecognizedField, pField)
	If pRecognizedField <> Undefined Then
		If pRecognizedField.Quality < 100 Then
			If Type(pRecognitionQuality) = Type("Structure") Then
				If Not pRecognitionQuality.Property(pField) Then
					pRecognitionQuality.Insert(pField, pRecognizedField.Quality);
				Else
					pRecognitionQuality[pField] = pRecognizedField.Quality;
				EndIf;
			Else
				vRows = pRecognitionQuality.FindRows(New Structure("Field",pField));
				If vRows.Count() = 0 Then
					vRow = pRecognitionQuality.Add();
					vRow.Field = pField;
				Else
					vRow = vRows[0]; 	
				EndIf;
				vRow.Quality = pRecognizedField.Quality;
			EndIf;
		Else 
			If Type(pRecognitionQuality) = Type("Structure") Then
				If pRecognitionQuality.Property(pField) Then
					pRecognitionQuality.Delete(pField);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillQualityState

#EndRegion
