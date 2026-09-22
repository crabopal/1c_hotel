// -----------------------------------------------------------------------------
Function GetClientSex(pSexStr)
	vSex = Undefined;
	If Not IsBlankString(pSexStr) Then
		vL = Upper(Left(TrimAll(pSexStr), 1));
		If vL = "Ж" Or vL = "F" Then
			vSex = Enums.Sex.Female;
		Else
			vSex = Enums.Sex.Male;
		EndIf;
	EndIf;
	Return vSex;
EndFunction // GetClientSex

// -----------------------------------------------------------------------------
Function GetPaperSize(pScanConfiguration)
	vPSCode = "";
	vPS = Undefined;
	If ValueIsFilled(pScanConfiguration) And ValueIsFilled(pScanConfiguration.PaperSize) Then
		vPS = pScanConfiguration.PaperSize;
	ElsIf ValueIsFilled(ImageScannerConnectionParameters.PaperSize) Then
		vPS = ImageScannerConnectionParameters.PaperSize;
	EndIf;
	If ValueIsFilled(vPS) Then
		If vPS = Enums.PaperSizes.A0 Then
			vPSCode = "A0";
		ElsIf vPS = Enums.PaperSizes.A1 Then
			vPSCode = "A1";
		ElsIf vPS = Enums.PaperSizes.A2 Then
			vPSCode = "A2";
		ElsIf vPS = Enums.PaperSizes.A3 Then
			vPSCode = "A3";
		ElsIf vPS = Enums.PaperSizes.A4 Then
			vPSCode = "A4";
		ElsIf vPS = Enums.PaperSizes.A5 Then
			vPSCode = "A5";
		ElsIf vPS = Enums.PaperSizes.A6 Then
			Raise NStr("en='Unsupported paper size A6!';ru='Неподдерживаемый размер бумаги A6!';de='Nicht unterstütztes Papier-Format A6!'");
		ElsIf vPS = Enums.PaperSizes.A7 Then
			Raise NStr("en='Unsupported paper size A7!';ru='Неподдерживаемый размер бумаги A7!';de='Nicht unterstütztes Papier-Format A7!'");
		ElsIf vPS = Enums.PaperSizes.A8 Then
			Raise NStr("en='Unsupported paper size A8!';ru='Неподдерживаемый размер бумаги A8!';de='Nicht unterstütztes Papierformat A8!'");
		ElsIf vPS = Enums.PaperSizes.A9 Then
			Raise NStr("en='Unsupported paper size A9!';ru='Неподдерживаемый размер бумаги A9!';de='Nicht unterstütztes Papierformat A9!'");
		ElsIf vPS = Enums.PaperSizes.A10 Then
			Raise NStr("en='Unsupported paper size A10!';ru='Неподдерживаемый размер бумаги A10!';de='Nicht unterstütztes Papier-Format A10!'");
		ElsIf vPS = Enums.PaperSizes.B3 Then
			vPSCode = "B3_ISO";
		ElsIf vPS = Enums.PaperSizes.B4 Then
			vPSCode = "B4_ISO";
		ElsIf vPS = Enums.PaperSizes.B5 Then
			vPSCode = "B5_ISO";
		ElsIf vPS = Enums.PaperSizes.B6 Then
			vPSCode = "B6_ISO";
		ElsIf vPS = Enums.PaperSizes.C4 Then
			vPSCode = "C4";
		ElsIf vPS = Enums.PaperSizes.C5 Then
			vPSCode = "C5";
		ElsIf vPS = Enums.PaperSizes.C6 Then
			vPSCode = "C6";
		ElsIf vPS = Enums.PaperSizes.A40 Then
			vPSCode = "RA4";
		ElsIf vPS = Enums.PaperSizes.A20 Then
			vPSCode = "RA2";
		ElsIf vPS = Enums.PaperSizes.USLET Then
			vPSCode = "Letter";
		ElsIf vPS = Enums.PaperSizes.USLEG Then
			vPSCode = "Legal";
		ElsIf vPS = Enums.PaperSizes.USLEDGER Then
			vPSCode = "Statement";
		ElsIf vPS = Enums.PaperSizes.USEXECUTIVE Then
			vPSCode = "Executive";
		EndIf;
	EndIf;
	Return vPSCode;
EndFunction // GetPaperSize

// -----------------------------------------------------------------------------
Function GetRotation(pScanConfiguration)
	vRotationCode = "";
	vRotation = 0;
	If ValueIsFilled(pScanConfiguration) And pScanConfiguration.Rotation <> 0 Then
		vRotation = pScanConfiguration.Rotation;
	ElsIf ImageScannerConnectionParameters.Rotation <> 0 Then
		vRotation = ImageScannerConnectionParameters.Rotation;
	EndIf;
	If vRotation <> 0 Then
		If vRotation = 90 Then
			vRotationCode = "Rotation90";
		ElsIf vRotation = 180 Then
			vRotationCode = "Rotation180";
		ElsIf vRotation = 270 Then
			vRotationCode = "Rotation270";
		Else
			Raise NStr("en='Unsupported rotation angle (90, 180, 270 are allowed)!';ru='Неподдерживаемый угол поворота (разрешены 90, 180, 270)!';de='Nicht unterstützter Drehwinkel (zulässig sind 90, 180, 270)!'");
		EndIf;
	EndIf;
	Return vRotationCode;
EndFunction // GetRotation

// -----------------------------------------------------------------------------
Function GetColorDepth(pScanConfiguration)
	vColorDepthCode = "Color";
	vColorDepth = Undefined;
	If ValueIsFilled(pScanConfiguration) And ValueIsFilled(pScanConfiguration.ColorDepth) Then
		vColorDepth = pScanConfiguration.ColorDepth;
	ElsIf ValueIsFilled(ImageScannerConnectionParameters.ColorDepth) Then
		vColorDepth = ImageScannerConnectionParameters.ColorDepth;
	EndIf;
	If ValueIsFilled(vColorDepth) Then
		If vColorDepth = Enums.ColorDepths.RGB Then
			vColorDepthCode = "Color";
		ElsIf vColorDepth = Enums.ColorDepths.Palette Then
			Raise NStr("en='Unsupported color depth (24 bits color, Grayscale, Black&white image are allowed only)!';ru='Неподдерживаемая глубина цвета (разрешены 24 битный цвет, Оттенки серого, Черно-белая картинка)!';de='Eine nicht unterstützte Farbtiefe (erlaubt sind 24-Bit-Farben, Grauschattierungen, schwarz-weißes Bild)'");
		ElsIf vColorDepth = Enums.ColorDepths.Gray Then
			vColorDepthCode = "Grayscale";
		ElsIf vColorDepth = Enums.ColorDepths.BW Then
			vColorDepthCode = "BlackAndWhite";
		EndIf;
	EndIf;
	Return vColorDepthCode;
EndFunction // GetColorDepth

// -----------------------------------------------------------------------------
Function GetDateFromString(pDateStr, pCutOffYear = 0)
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
					If vYear > (Year(CurrentSessionDate()) - 2000) Then
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
EndFunction // GetDateFromString

// -----------------------------------------------------------------------------
Function pmGetListOfTWAINDevices(pScanComponentInstallationPath, rMessage) Export
	vList = New ValueList();
	// Reset return status
	rMessage = "";
	// Try to load external component
	vScObj = pmConnect(rMessage);
	If vScObj <> Undefined Then 
		Try
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
Function pmGetListOfAllowedConfigurations(rMessage) Export
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
Procedure Connect(pScObj)
	// Set some options
	pScObj.ImageQuality = 90;
	pScObj.ImageResolution = 0;
	// Set current scanner
	vTwainDeviceName = "";
	If Not IsBlankString(ImageScannerConnectionParameters.TwainDeviceName) Then
		vTwainDeviceName = TrimAll(ImageScannerConnectionParameters.TwainDeviceName);
		vCount = pScObj.ScannersCount;
		For i = 0 To (vCount - 1) Do
			vName = pScObj.ScannerName(i);
			If vName = vTwainDeviceName Then
				pScObj.CurrentScanSource = i;
				Break;
			EndIf;
		EndDo;
	EndIf;
	// Change scanner settings
	vSettings = pScObj.GetScanSettings();
	vSettings.Set("interface-type", "None");
	vSettings.Set("resolution", "300");
	If ImageScannerConnectionParameters.ImageScannerDriver = Enums.ImageScannerDrivers.ContentAIPassportReaderSDKEngine Then
		vSettings.Set("compression", "NoCompression");
	Else
		vSettings.Set("compression", "False");
	EndIf;
	pScObj.SetScanSettings(vSettings);
EndProcedure // Connect

// -----------------------------------------------------------------------------
Function pmConnect(rMessage, pDummy = Undefined) Export
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		vScanComponentInstallationPath = "";
		If Not IsBlankString(ImageScannerConnectionParameters.ScanComponentInstallationPath) Then
			vScanComponentInstallationPath = TrimAll(ImageScannerConnectionParameters.ScanComponentInstallationPath);
			If Right(vScanComponentInstallationPath, 1) <> "\" Then
				vScanComponentInstallationPath = vScanComponentInstallationPath + "\";
			EndIf;
		EndIf;
		// Use Abbyy ActiveX object
		#IF CLIENT AND NOT MobileClient THEN
			If amImageScanner = Undefined Then
				If ImageScannerConnectionParameters.ImageScannerDriver = Enums.ImageScannerDrivers.ContentAIPassportReaderSDKEngine Then
					vProjectId = TrimAll(CachedCommonFunctions.cmGetContentAIProjectId());
					If IsBlankString(vProjectId) Then
						vErr = NStr("en='The developer Id is not specified in the information database settings!';
									|ru='В настройках информационной базы не указан Id разработчика!';
									|de='Die Entwickler-ID ist in den Einstellungen der Informationsdatenbank nicht angegeben!'");
						Raise vErr; 	
					EndIf;
					// Content AI PassportReader SDK
					vScObj = New COMObject("PassportReader.SDK.RecognitionEngine");
					// Initialisation parameters
					vInitParams = New COMObject("PassportReader.SDK.InitParams");
					vInitParams.AppDataPath = ?(ValueIsFilled(vScanComponentInstallationPath), vScanComponentInstallationPath, NULL);
					vInitParams.CustomerProjectId = vProjectId;
					vInitParams.LicensePassword = NULL;
					vInitParams.LicensePath = NULL;
					vInitParams.FCEnginePath = NULL;
					vInitParams.TemplatesPath = NULL;
					Try
						vScObj.Init(vInitParams);
						Connect(vScObj);
					Except
						tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);
					EndTry;
				Else
					vScObj = New COMObject("ABBYY.PassportReaderSdk.RecognitionEngine");
					Try
						vScObj.Init();
						Connect(vScObj);
					Except
						tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);
					EndTry;
				EndIf;
				amImageScanner = vScObj;
			Else
				vScObj = amImageScanner;
			Endif;
		#ELSE
			#IF NOT MobileClient THEN
				vScObj = New COMObject("ABBYY.PassportReaderSdk.RecognitionEngine");
				vScObj.Init();
				Connect(vScObj);
			#ENDIF
		#ENDIF
		#IF CLIENT THEN
			If amImageScannerDriver = Undefined Then
				amImageScannerDriver = ThisObject;
			EndIf;
		#ENDIF
		// OK
		Return vScObj;
	Except
		amImageScanner = Undefined;
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pScObj, pDummy = Undefined) Export
	Try
		pScObj.Close();
		pScObj = Undefined;
		#IF CLIENT THEN
			amImageScanner = Undefined;
		#ENDIF			
	Except
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Procedure ProcessException(pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, ImageScannerConnectionParameters.Metadata(), ImageScannerConnectionParameters, "Error description: " + rMessage);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Procedure ConvertImage(pTargetFileName, pSourceFileName)
	// Build active X object to rotate picture
	#IF NOT WebClient AND NOT MobileClient THEN
		Try
			vGFLAx = New COMObject("GFLAx.GFLAx");
		Except	
			vMessage = NStr("en='GFLAx (ActiveX/ASP component) should be installed first! Go to the current workstation item settings and press <Install GFLAx (ActiveX/ASP component)> button.';ru='ActiveX/ASP библиотека GFLAx не установлена! Для установки откройте карточку настроек рабочего места и нажмите на кнопку <Установить GFLAx (ActiveX/ASP библиотеку)>.';de='Die ActiveX/ASP-Bibliothek GFLAx wurde nicht installiert! Zur Installation öffnen Sie die Arbeitsplatzeinstellungen und wählen Sie <GFLAx (ActiveX/AP-Bibliothek) installieren)>.'");
			#IF CLIENT THEN
				ShowMessageBox(, vMessage);
			#ELSE
				ProcessException("ConvertImage", vMessage);
			#ENDIF
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
			#IF CLIENT THEN
				ShowMessageBox(, vMessage);
			#ELSE
				ProcessException("ConvertImage", vMessage);
			#ENDIF
		EndTry;
	#ENDIF
EndProcedure // ConvertImage

// -----------------------------------------------------------------------------
Function pmScanDocument(pScanConfiguration, pPictureStorage, rMessage) Export
	// Try to connect
	vScObj = pmConnect(rMessage);
	If vScObj = Undefined Then
		Return False;
	Else
		// Scanner was connected
		Try
			// Get scanner settings
			vSettings = vScObj.GetScanSettings();
			// Set document paper size
			vPSCode = GetPaperSize(pScanConfiguration);
			If Not IsBlankString(vPSCode) Then
				vSettings.Set("paper-size", vPSCode);
			EndIf;
			// Set document rotation
			vRotation = GetRotation(pScanConfiguration);
			If Not IsBlankString(vRotation) Then
				vSettings.Set("rotation-angle", vRotation);
			EndIf;
			// Set document color depth
			vColorDepthCode = GetColorDepth(pScanConfiguration);
			If Not IsBlankString(vColorDepthCode) Then
				vSettings.Set("picture-mode", vColorDepthCode);
			EndIf;
			// Set scanner settings
			vScObj.SetScanSettings(vSettings);
			// Acquire image
			vPictFileName = vScObj.Scan();
			ConvertImage(vPictFileName + ".jpg", vPictFileName);
			vPict = New Picture(vPictFileName + ".jpg");
			pPictureStorage = New ValueStorage(vPict);
			// Delete working images
			Try
				DeleteFiles(vPictFileName);
				DeleteFiles(vPictFileName + ".jpg");
			Except
			EndTry;
			// Return success
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='ImageScannerDriver.ScanDocument';ru='СканерИзображений.СканироватьДокумент';de='ImageScannerDriver.ScanDocument'"), rMessage);
		EndTry;
	EndIf;
	Return False;
EndFunction // pmScanDocument

// -----------------------------------------------------------------------------
Procedure FillQualityState(pClientDataScansObj, pRecognizedField, pField)
	If pRecognizedField <> Undefined Then
		vRow = pClientDataScansObj.RecognitionQuality.Find(pField, "Field");
		If pRecognizedField.Quality < 100 Then
			If vRow = Undefined Then
				vRow = pClientDataScansObj.RecognitionQuality.Add();
				vRow.Field = pField;
				vRow.Quality = pRecognizedField.Quality;
			Else
				vRow.Quality = pRecognizedField.Quality;
			EndIf;
		Else
			If vRow <> Undefined Then
				pClientDataScansObj.RecognitionQuality.Delete(vRow);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillQualityState

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
Function pmRecognizeDocument(pClientDataScansObj, rMessage, pScObj = Undefined, pDummy = Undefined, pScanConfig = Undefined) Export
	// Try to connect
	If pScObj = Undefined Then
		vScObj = pmConnect(rMessage);
	Else
		vScObj = pScObj;
	EndIf;
	If vScObj = Undefined Then
		Return False;
	Else
		// Scanner was connected
		Try
			For Each vCurRow In pClientDataScansObj.ScanPictures Do
				vScanConfiguration = vCurRow.ScanConfiguration;
				If pScanConfig = Undefined Or pScanConfig = vScanConfiguration Then
					// Get scan configuration name
					vScanConfigName = "Passport";
					vScanConfigName = vScanConfigName + "_RU";
					If ValueIsFilled(vScanConfiguration) Then
						If Not vScanConfiguration.RecognitionIsAvailable Then
							// Skip recognition
							Continue;
						EndIf;
						If Not IsBlankString(vScanConfiguration.ScanConfigurationName) Then
							vScanConfigName = TrimAll(vScanConfiguration.ScanConfigurationName);
						EndIf;
					EndIf;
					// Save current picture to disk
					vPictFileName = GetTempFileName("jpg");
					vPicture = vCurRow.ScanPicture.Get();
					If vPicture <> Undefined Then
						If TypeOf(vPicture) = Type("String") Then
							vPicture = New Picture(pClientDataScansObj.pmGetImageCatalogName(vCurRow) + TrimAll(vPicture));
						EndIf;
						vPicture.Write(vPictFileName);
						vFields = vScObj.Recognize(vPictFileName, vScanConfigName);
						// Check if any fields were filled
							If vFields = Undefined Or vFields.Count = 0 Then
							Raise NStr("en='Recognition is not supported for the client identification document type choosen!';ru='Распознавание для данного вида документа удостоверяющего личность не поддерживается!';de='Die Erkennung dieser Art des Identitätsnachweises wird nicht unterstützt!'");
						EndIf;
						// Identity document type
						vIdentityDocumentType = Undefined;
						vIdentityDocumentTypeCode = "";
						vIdentityDocumentTypeUFMSCode = "";
						If ValueIsFilled(vScanConfiguration) Then
							vIdentityDocumentType = vScanConfiguration.IdentityDocumentType;
							If ValueIsFilled(vIdentityDocumentType) Then
								vIdentityDocumentTypeCode = TrimAll(vIdentityDocumentType.Code);
								vIdentityDocumentTypeUFMSCode = TrimAll(vIdentityDocumentType.ExternalCode);
							EndIf;
						EndIf;
						// Check identification document type
						If Not ValueIsFilled(vScanConfiguration) Or
						   ValueIsFilled(vScanConfiguration) And Not ValueIsFilled(vIdentityDocumentType) Or 
						   ValueIsFilled(vScanConfiguration) And ValueIsFilled(vIdentityDocumentType) And 
						   (vIdentityDocumentTypeCode = "21" Or vIdentityDocumentTypeUFMSCode = "103008") And
						   Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsVisa Then // Russian passport
							// Last name   
							InsertIfNotEmpty(pClientDataScansObj.LastName, Title(GetFieldValue(vFields, "LastName")));
							FillQualityState(pClientDataScansObj, vFields.Field("LastName"), "LastName");
							// First name   
							InsertIfNotEmpty(pClientDataScansObj.FirstName, Title(GetFieldValue(vFields, "FirstName")));
							FillQualityState(pClientDataScansObj, vFields.Field("FirstName"), "FirstName");
							// Second name
							InsertIfNotEmpty(pClientDataScansObj.SecondName, Title(GetFieldValue(vFields, "MiddleName")));
							FillQualityState(pClientDataScansObj, vFields.Field("MiddleName"), "SecondName");
							// Sex   
							vSex = GetClientSex(GetFieldValue(vFields, "Sex"));
							If ValueIsFilled(vSex) Then
								InsertIfNotEmpty(pClientDataScansObj.Sex, vSex);
							EndIf;
							FillQualityState(pClientDataScansObj, vFields.Field("Sex"), "Sex");
							// Date of birth   
							vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
							InsertIfNotEmpty(pClientDataScansObj.DateOfBirth, GetDateFromString(vDateOfBirth));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfBirth"), "DateOfBirth");
							// Place of birth
							InsertIfNotEmpty(pClientDataScansObj.PlaceOfBirth, "РОССИЯ, , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), chars.LF, " "));
							FillQualityState(pClientDataScansObj, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
							// ID type
							vPassport = Catalogs.IdentityDocumentTypes.FindByCode("21");
							If ValueIsFilled(vPassport) Then
								InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentType, vPassport);
							EndIf;
							// Citizenship
							InsertIfNotEmpty(pClientDataScansObj.Citizenship, Catalogs.Countries.FindByCode(643));
							// ID series
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentSeries, StrReplace(GetFieldValue(vFields, "Series2"), " ", ""));
							FillQualityState(pClientDataScansObj, vFields.Field("Series2"), "IdentityDocumentSeries");
							// ID number   
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentNumber, GetFieldValue(vFields, "Number2"));
							FillQualityState(pClientDataScansObj, vFields.Field("Number2"), "IdentityDocumentNumber");
							// Issued date   
							vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
							// Issued by   
							If vFields.Field("DepartmentCode") <> Undefined Then
								vQlt = vFields.Field("DepartmentCode");
								InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentUnitCode, GetFieldValue(vFields, "DepartmentCode"));
								FillQualityState(pClientDataScansObj, vQlt, "IdentityDocumentUnitCode");
								vQryRes = cmGetFMSRecord(TrimAll(pClientDataScansObj.IdentityDocumentUnitCode),True).Unload();	
								If ValueIsFilled(pClientDataScansObj.IdentityDocumentUnitCode) And vQlt.Quality > 80 And vQryRes.Count()>0 Then
									InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentIssuedBy, vQryRes[0].Description);
								Else	
									InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentIssuedBy, StrReplace(GetFieldValue(vFields, "IssuedBy"), chars.LF, " "));
									FillQualityState(pClientDataScansObj, vFields.Field("IssuedBy"), "IdentityDocumentIssuedBy");
								EndIf;
							EndIf;
							// Photo
							vRecPhoto = vFields.Field("Photo");
							If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
								pClientDataScansObj.Photo = New ValueStorage(New Picture(vFields.Field("Photo").SaveTemp(0)));
								FillQualityState(pClientDataScansObj, vFields.Field("Photo"), "Photo");
							EndIf;
							// Signature
							vRecSignature = vFields.Field("Signature");
							If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
								pClientDataScansObj.Signature = New ValueStorage(New Picture(vFields.Field("Signature").SaveTemp(0)));
								FillQualityState(pClientDataScansObj, vFields.Field("Signature"), "Signature");
							EndIf;
						ElsIf ValueIsFilled(vScanConfiguration) And ValueIsFilled(vIdentityDocumentType) And 
						      vIdentityDocumentTypeCode = "30" And
						      Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsVisa Then // Drivers license
							// Last name   
							InsertIfNotEmpty(pClientDataScansObj.LastName, Title(GetFieldValue(vFields, "LastName")));
							FillQualityState(pClientDataScansObj, vFields.Field("LastName"), "LastName");
							// First name   
							InsertIfNotEmpty(pClientDataScansObj.FirstName, Title(GetFieldValue(vFields, "FirstName")));
							FillQualityState(pClientDataScansObj, vFields.Field("FirstName"), "FirstName");
							// Second name
							InsertIfNotEmpty(pClientDataScansObj.SecondName, Title(GetFieldValue(vFields, "MiddleName")));
							FillQualityState(pClientDataScansObj, vFields.Field("MiddleName"), "SecondName");
							// Sex   
							InsertIfNotEmpty(pClientDataScansObj.Sex, cmGetSexByNames(pClientDataScansObj.LastName, pClientDataScansObj.FirstName, pClientDataScansObj.SecondName));
							// Date of birth   
							vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
							InsertIfNotEmpty(pClientDataScansObj.DateOfBirth, GetDateFromString(vDateOfBirth));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfBirth"), "DateOfBirth");
							// Place of birth
							InsertIfNotEmpty(pClientDataScansObj.PlaceOfBirth, "РОССИЯ, , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), chars.LF, " "));
							FillQualityState(pClientDataScansObj, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
							// ID type
							vDriverLicense = Catalogs.IdentityDocumentTypes.FindByCode("30");
							If ValueIsFilled(vDriverLicense) Then
								InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentType, vDriverLicense);
							EndIf;
							// Citizenship
							InsertIfNotEmpty(pClientDataScansObj.Citizenship, Catalogs.Countries.FindByCode(643));
							// ID series
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentSeries, StrReplace(GetFieldValue(vFields, "Series"), " ", ""));
							FillQualityState(pClientDataScansObj, vFields.Field("Series"), "IdentityDocumentSeries");
							// ID number   
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
							FillQualityState(pClientDataScansObj, vFields.Field("Number"), "IdentityDocumentNumber");
							// Issued date   
							vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
							// Expire date   
							vIdentityDocumentValidToDate = GetFieldValue(vFields, "DateOfExpiry");
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentValidToDate, GetDateFromString(vIdentityDocumentValidToDate, 90));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfExpiry"), "IdentityDocumentIssueDate");
							// Photo
							vRecPhoto = vFields.Field("Photo");
							If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
								pClientDataScansObj.Photo = New ValueStorage(New Picture(vFields.Field("Photo").SaveTemp(0)));
								FillQualityState(pClientDataScansObj, vFields.Field("Photo"), "Photo");
							EndIf;
							// Signature
							vRecSignature = vFields.Field("Signature");
							If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
								pClientDataScansObj.Signature = New ValueStorage(New Picture(vFields.Field("Signature").SaveTemp(0)));
								FillQualityState(pClientDataScansObj, vFields.Field("Signature"), "Signature");
							EndIf;
						ElsIf ValueIsFilled(vIdentityDocumentType) And (vIdentityDocumentTypeCode = "03" Or vIdentityDocumentTypeUFMSCode = "102974") And
						      Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsVisa Then // Birth certificate
							// Last name   
							InsertIfNotEmpty(pClientDataScansObj.LastName, Title(GetFieldValue(vFields, "LastName")));
							FillQualityState(pClientDataScansObj, vFields.Field("LastName"), "LastName");
							// First name   
							InsertIfNotEmpty(pClientDataScansObj.FirstName, Title(GetFieldValue(vFields, "FirstName")));
							FillQualityState(pClientDataScansObj, vFields.Field("FirstName"), "FirstName");
							// Second name
							InsertIfNotEmpty(pClientDataScansObj.SecondName, Title(GetFieldValue(vFields, "MiddleName")));
							FillQualityState(pClientDataScansObj, vFields.Field("MiddleName"), "SecondName");
							// Sex   
							vSex = cmGetSexByNames(pClientDataScansObj.LastName, pClientDataScansObj.FirstName, pClientDataScansObj.SecondName);
							If ValueIsFilled(vSex) Then
								InsertIfNotEmpty(pClientDataScansObj.Sex, vSex);
							EndIf;
							// Date of birth   
							vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
							InsertIfNotEmpty(pClientDataScansObj.DateOfBirth, GetDateFromString(vDateOfBirth));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfBirth"), "DateOfBirth");
							// Place of birth
							InsertIfNotEmpty(pClientDataScansObj.PlaceOfBirth, "РОССИЯ, , , , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), chars.LF, " "));
							FillQualityState(pClientDataScansObj, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
							// Citizenship
							InsertIfNotEmpty(pClientDataScansObj.Citizenship, Catalogs.Countries.FindByCode(643));
							// ID type
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentType, vIdentityDocumentType);
							// ID series
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentSeries, StrReplace(GetFieldValue(vFields, "Series"), " ", ""));
							FillQualityState(pClientDataScansObj, vFields.Field("Series"), "IdentityDocumentSeries");
							// ID number   
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
							FillQualityState(pClientDataScansObj, vFields.Field("Number"), "IdentityDocumentNumber");
							// Issued date   
							vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
						ElsIf ValueIsFilled(vScanConfiguration) And ValueIsFilled(vIdentityDocumentType) And 
						      (vIdentityDocumentTypeCode = "ИП" Or vIdentityDocumentTypeUFMSCode = "103012") And
						      Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsVisa Then // Foreign passport
							// Last name   
							InsertIfNotEmpty(pClientDataScansObj.LastName, Title(GetFieldValue(vFields, "LastName")));
							FillQualityState(pClientDataScansObj, vFields.Field("LastName"), "LastName");
							// First name   
							InsertIfNotEmpty(pClientDataScansObj.FirstName, Title(GetFieldValue(vFields, "FirstName")));
							FillQualityState(pClientDataScansObj, vFields.Field("FirstName"), "FirstName");
							// Second name
							InsertIfNotEmpty(pClientDataScansObj.SecondName, "");
							// Sex   
							vSex = GetClientSex(GetFieldValue(vFields, "Sex"));
							If ValueIsFilled(vSex) Then
								InsertIfNotEmpty(pClientDataScansObj.Sex, vSex);
							EndIf;
							FillQualityState(pClientDataScansObj, vFields.Field("Sex"), "Sex");
							// Date of birth   
							vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
							InsertIfNotEmpty(pClientDataScansObj.DateOfBirth, GetDateFromString(vDateOfBirth));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfBirth"), "DateOfBirth");
							// Place of birth
							InsertIfNotEmpty(pClientDataScansObj.PlaceOfBirth, StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), chars.LF, " "));
							FillQualityState(pClientDataScansObj, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
							// ID type
							vPassport = Catalogs.IdentityDocumentTypes.FindByCode("ИП");
							If ValueIsFilled(vPassport) Then
								InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentType, vPassport);
							EndIf;
							// Citizenship
							vCountryISO3Code = GetFieldValue(vFields, ?(DriverType = "CodeOfIssuingState", "IssuedBy", "country"));
							InsertIfNotEmpty(pClientDataScansObj.Citizenship, Catalogs.Countries.FindByAttribute("ISOCode3", vCountryISO3Code));
							FillQualityState(pClientDataScansObj, vFields.Field("CodeOfIssuingState"), "Citizenship");
							// ID Series
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentSeries, "");
							// ID number   
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
							FillQualityState(pClientDataScansObj, vFields.Field("Number"), "IdentityDocumentNumber");
							// Issue date   
							vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate, 90));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
							// Expire date   
							vIdentityDocumentValidToDate = GetFieldValue(vFields, "DateOfExpiry");
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentValidToDate, GetDateFromString(vIdentityDocumentValidToDate, 90));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfExpiry"), "IdentityDocumentIssueDate");
							// Issued by   
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentIssuedBy, StrReplace(GetFieldValue(vFields, "IssuedBy"), chars.LF, " "));
							FillQualityState(pClientDataScansObj, vFields.Field("IssuedBy"), "IdentityDocumentIssuedBy");
							// Photo
							vRecPhoto = vFields.Field("Photo");
							If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
								pClientDataScansObj.Photo = New ValueStorage(New Picture(vFields.Field("Photo").SaveTemp(0)));
								FillQualityState(pClientDataScansObj, vFields.Field("Photo"), "Photo");
							EndIf;
							// Signature
							vRecSignature = vFields.Field("Signature");
							If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
								pClientDataScansObj.Signature = New ValueStorage(New Picture(vFields.Field("Signature").SaveTemp(0)));
								FillQualityState(pClientDataScansObj, vFields.Field("Signature"), "Signature");
							EndIf;
						ElsIf ValueIsFilled(vScanConfiguration) And ValueIsFilled(vIdentityDocumentType) And 
						      (vIdentityDocumentTypeCode = "22" Or vIdentityDocumentTypeUFMSCode = "103007") And
						      Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsVisa Then // Russian foreign passport
							// Last name   
							InsertIfNotEmpty(pClientDataScansObj.LastName, Title(GetFieldValue(vFields, "LastName")));
							FillQualityState(pClientDataScansObj, vFields.Field("LastName"), "LastName");
							// First name   
							InsertIfNotEmpty(pClientDataScansObj.FirstName, Title(GetFieldValue(vFields, "FirstName")));
							FillQualityState(pClientDataScansObj, vFields.Field("FirstName"), "FirstName");
							// Second name
							InsertIfNotEmpty(pClientDataScansObj.SecondName, "");
							// Sex   
							vSex = GetClientSex(GetFieldValue(vFields, "Sex"));
							If ValueIsFilled(vSex) Then
								InsertIfNotEmpty(pClientDataScansObj.Sex, vSex);
							EndIf;
							FillQualityState(pClientDataScansObj, vFields.Field("Sex"), "Sex");
							// Date of birth   
							vDateOfBirth = GetFieldValue(vFields, "DateOfBirth");
							InsertIfNotEmpty(pClientDataScansObj.DateOfBirth, GetDateFromString(vDateOfBirth));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfBirth"), "DateOfBirth");
							// Place of birth
							InsertIfNotEmpty(pClientDataScansObj.PlaceOfBirth, "РОССИЯ, , " + StrReplace(GetFieldValue(vFields, "PlaceOfBirth"), chars.LF, " "));
							FillQualityState(pClientDataScansObj, vFields.Field("PlaceOfBirth"), "PlaceOfBirth");
							// ID type
							vPassport = Catalogs.IdentityDocumentTypes.FindByCode("22");
							If ValueIsFilled(vPassport) Then
								InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentType, vPassport);
							EndIf;
							// Citizenship
							InsertIfNotEmpty(pClientDataScansObj.Citizenship, Catalogs.Countries.FindByCode(643));
							// ID Series
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentSeries, "");
							// ID number   
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentNumber, GetFieldValue(vFields, "Number"));
							FillQualityState(pClientDataScansObj, vFields.Field("Number"), "IdentityDocumentNumber");
							If Not IsBlankString(pClientDataScansObj.IdentityDocumentNumber) Then
								If StrLen(TrimAll(pClientDataScansObj.IdentityDocumentNumber)) > 8 Then
									InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentSeries, Left(TrimAll(pClientDataScansObj.IdentityDocumentNumber), 2));
									InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentNumber, Mid(TrimAll(pClientDataScansObj.IdentityDocumentNumber), 3));
								EndIf;
							EndIf;
							// Issue date   
							vIdentityDocumentIssueDate = GetFieldValue(vFields, "DateOfIssue");
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentIssueDate, GetDateFromString(vIdentityDocumentIssueDate, 90));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfIssue"), "IdentityDocumentIssueDate");
							// Expire date   
							vIdentityDocumentValidToDate = GetFieldValue(vFields, "DateOfExpiry");
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentValidToDate, GetDateFromString(vIdentityDocumentValidToDate, 90));
							FillQualityState(pClientDataScansObj, vFields.Field("DateOfExpiry"), "IdentityDocumentValidToDate");
							// Issued by   
							InsertIfNotEmpty(pClientDataScansObj.IdentityDocumentIssuedBy, StrReplace(GetFieldValue(vFields, "IssuedBy"), chars.LF, " "));
							FillQualityState(pClientDataScansObj, vFields.Field("IssuedBy"), "IdentityDocumentIssuedBy");
							// Photo
							vRecPhoto = vFields.Field("Photo");
							If vRecPhoto <> Undefined And vRecPhoto.IsImage And vRecPhoto.IsFound Then
								pClientDataScansObj.Photo = New ValueStorage(New Picture(vFields.Field("Photo").SaveTemp(0)));
								FillQualityState(pClientDataScansObj, vFields.Field("Photo"), "Photo");
							EndIf;
							// Signature
							vRecSignature = vFields.Field("Signature");
							If vRecSignature <> Undefined And vRecSignature.IsImage And vRecSignature.IsFound Then
								pClientDataScansObj.Signature = New ValueStorage(New Picture(vFields.Field("Signature").SaveTemp(0)));
								FillQualityState(pClientDataScansObj, vFields.Field("Signature"), "Signature");
							EndIf;
						Else
							Raise NStr("en='Recognition is not supported for the client identification document type choosen!';ru='Распознавание для данного вида документа удостоверяющего личность не поддерживается!';de='Die Erkennung dieser Art des Identitätsnachweises wird nicht unterstützt!'");
						EndIf;
						// Delete working images
						Try
							DeleteFiles(vPictFileName);
						Except
						EndTry;
					EndIf;
				EndIf;
			EndDo;
			// Return success
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='ImageScannerDriver.RecognizeDocument';ru='СканерИзображений.РаспознатьДокумент';de='ImageScannerDriver.RecognizeDocument'"), rMessage);
		EndTry;
	EndIf;
	Return False;
EndFunction // pmRecognizeDocument

// -----------------------------------------------------------------------------
Procedure InsertIfNotEmpty(pDocumentAttribute, pRecognizedField)
	If ValueIsFilled(pRecognizedField) Then
		pDocumentAttribute = pRecognizedField;
	EndIf;
EndProcedure // InsertIfNotEmpty
