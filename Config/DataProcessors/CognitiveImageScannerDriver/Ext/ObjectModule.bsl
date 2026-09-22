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
	// Try to connect
	vScI = Undefined;
	vScObj = pmConnect(rMessage, vScI);
	If vScObj <> Undefined Then
		Try
			// Get list of TWAIN devices
			// vCount = vScI.ScannerGetTWAINSourceCount(); // Is not working, error in API
			vCount = 99;
			For i = 0 To (vCount - 1) Do
				Try
					vName = vScI.ScannerGetTWAINSourceName(i);
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
	// Try to read context file
	Try
		// Initialization
		vScanComponentInstallationPath = "C:\Program Files\Cognitive\ScanifyAPI\Scanify\Bin32";
		If Not IsBlankString(ImageScannerConnectionParameters.ScanComponentInstallationPath) Then
			vScanComponentInstallationPath = TrimAll(ImageScannerConnectionParameters.ScanComponentInstallationPath);
		EndIf;
		If Right(vScanComponentInstallationPath, 1) <> "\" Then
			vScanComponentInstallationPath = vScanComponentInstallationPath + "\";
		EndIf;
		vScanContextFile = "scapi.ini";
		If Not IsBlankString(ImageScannerConnectionParameters.ScanContextFile) Then
			vScanContextFile = TrimAll(ImageScannerConnectionParameters.ScanContextFile);
		EndIf;
		// Read file
		vScapi = New TextReader(vScanComponentInstallationPath + vScanContextFile, , , , False);
		vScapiStr = TrimL(vScapi.ReadLine());
		While vScapiStr <> Undefined Do
			vStr = TrimL(vScapiStr);
			If Left(vStr, 5) = "[Scan" Then
				vRBPos = Find(vStr, "]");
				If vRBPos > 2 Then
					vName = Mid(vStr, 2, vRBPos - 2);
					If Not IsBlankString(vName) Then
						vList.Add(vName);
					Endif;
				EndIf;
			EndIf;
			vScapiStr = vScapi.ReadLine();
		EndDo;
	Except
		rMessage = ErrorDescription();
	EndTry;
	Return vList;
EndFunction // pmGetListOfAllowedConfigurations

// -----------------------------------------------------------------------------
Function pmConnect(rMessage, rScI) Export
	#IF CLIENT THEN
		If amImageScannerDriver = Undefined Then
			amImageScannerDriver = ThisObject;
		EndIf;
	#ENDIF
	// Reset return status
	rMessage = "";
	rScI = Undefined;
	// Try to load external component
	Try
		// Initialization
		vScanComponentInstallationPath = "C:\Program Files\Cognitive\ScanifyAPI\Scanify\Bin32";
		If Not IsBlankString(ImageScannerConnectionParameters.ScanComponentInstallationPath) Then
			vScanComponentInstallationPath = TrimAll(ImageScannerConnectionParameters.ScanComponentInstallationPath);
		EndIf;
		vScanContextFile = "scapi.ini";
		If Not IsBlankString(ImageScannerConnectionParameters.ScanContextFile) Then
			vScanContextFile = TrimAll(ImageScannerConnectionParameters.ScanContextFile);
		EndIf;
		// Use Cognitive ActiveX object
		#IF CLIENT THEN
			If amImageScanner = Undefined Then
				vScObj = New COMObject("Scanify.ScanifyObject");
				rScI = vScObj.Initialize(vScanComponentInstallationPath);
				rScI.ContextFile = vScanContextFile;
				amImageScanner = vScObj;
				amImageScannerInstance = rScI;
			Else
				vScObj = amImageScanner;
				rScI = amImageScannerInstance;
			EndIf;
		#ELSE
			vScObj = New COMObject("Scanify.ScanifyObject");
			rScI = vScObj.Initialize(vScanComponentInstallationPath);
			rScI.ContextFile = vScanContextFile;
		#ENDIF
		// OK
		Return vScObj;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pScObj, pScI) Export
	Try
		pScObj.Terminate(pScI);
		pScObj = Undefined;
		#IF CLIENT THEN
			amImageScannerInstance = Undefined;
			amImageScanner = Undefined;
		#ENDIF			
	Except
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Procedure ProcessException(pScObj, pScI, pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, ImageScannerConnectionParameters.Metadata(), ImageScannerConnectionParameters, "Error description: " + rMessage);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function pmScanDocument(pScanConfiguration, pPictureStorage, rMessage) Export
	// Try to connect
	vScI = Undefined;
	vScObj = pmConnect(rMessage, vScI);
	If vScObj = Undefined Then
		Return False;
	Else
		// Initialization
		vTwainDeviceName = "";
		If Not IsBlankString(ImageScannerConnectionParameters.TwainDeviceName) Then
			vTwainDeviceName = TrimAll(ImageScannerConnectionParameters.TwainDeviceName);
		EndIf;
		vScanConfigName = "ScanPassportAndDriveLic";
		If ValueIsFilled(pScanConfiguration) Then
			If Not IsBlankString(pScanConfiguration.ScanConfigurationName) Then
				vScanConfigName = TrimAll(pScanConfiguration.ScanConfigurationName);
			EndIf;
		EndIf;
		// Scanner was connected
		vScD = Undefined;
		vScP = Undefined;
		Try
			vScP = vScI.PackageCreate("");
			vScD = vScI.OpenTwainDevice(vTwainDeviceName);
			vScD.ConfigName = vScanConfigName;
			vScImg = vScP.Scan(vScD, 0);
			vPictFileName = GetTempFileName("jpg");
			vScImg.SaveAsJpeg(vPictFileName, 0);
			pPictureStorage = New ValueStorage(New Picture(vPictFileName));
			// Delete working images
			DeleteFiles(vPictFileName);
			Try
				vScD.Close();
			Except
			EndTry;
			Try
				vScP.Destroy();
			Except
			EndTry;
			// Return success
			Return True;
		Except
			rMessage = ErrorDescription();
			Try
				vScD.Close();
			Except
			EndTry;
			Try
				vScP.Destroy();
			Except
			EndTry;
			ProcessException(vScObj, vScI, NStr("en='ImageScannerDriver.ScanDocument';ru='СканерИзображений.СканироватьДокумент';de='ImageScannerDriver.ScanDocument'"), rMessage);
		EndTry;
	EndIf;
	Return False;
EndFunction // pmScanDocument

// -----------------------------------------------------------------------------
Function FillQualityState(pClientDataScansObj, pRecognizedField, pField)
	vQuality = 100;
	If pRecognizedField.RecogStatus <> 0 And pRecognizedField.RecogStatus <> 1 And pRecognizedField.RecogStatus <> 10 Then
		vRow = pClientDataScansObj.RecognitionQuality.Find(pField, "Field");
		If vRow = Undefined Then
			vRow = pClientDataScansObj.RecognitionQuality.Add();
			vRow.Field = pField;
		EndIf;
		If pRecognizedField.RecogStatus = 4 Then
			vRow.Quality = 90;
			vQuality = 90;
		ElsIf pRecognizedField.RecogStatus = 8 Then
			vRow.Quality = 10;
			vQuality = 10;
		ElsIf pRecognizedField.RecogStatus = 20 Then
			vRow.Quality = 10;
			vQuality = 10;
		Else
			vRow.Quality = 0;
			vQuality = 0;
		EndIf;
	EndIf;
	Return vQuality;
EndFunction // FillQualityState

// -----------------------------------------------------------------------------
Function GetFieldValue(pFields, pID)
	vFieldItem = pFields.ItemID(pID);
	If vFieldItem <> Undefined Then
		Return vFieldItem.Value;
	Else
		Return "";
	EndIf;
EndFunction // GetFieldValue

// -----------------------------------------------------------------------------
Function pmRecognizeDocument(pClientDataScansObj, rMessage, pScObj = Undefined, pScI = Undefined) Export
	// Try to connect
	vScObj = Undefined;
	vScI = Undefined;
	If pScObj <> Undefined Then
		vScObj = pScObj;
		vScI = pScI;
	Else
		vScObj = pmConnect(rMessage, vScI);
	EndIf;
	If vScObj = Undefined Then
		Return False;
	Else
		// Scanner was connected
		vScD = Undefined;
		vScP = Undefined;
		Try
			For Each vCurRow In pClientDataScansObj.ScanPictures Do
				// Get scan configuration name
				vScanConfigName = "ScanPassportAndDriveLic";
				If ValueIsFilled(vCurRow.ScanConfiguration) Then
					If Not vCurRow.ScanConfiguration.RecognitionIsAvailable Then
						// Skip recognition
						Continue;
					EndIf;
					If Not IsBlankString(vCurRow.ScanConfiguration.ScanConfigurationName) Then
						vScanConfigName = TrimAll(vCurRow.ScanConfiguration.ScanConfigurationName);
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
					vScP = vScI.PackageCreate("");
					vScD = vScI.OpenFileReader(vPictFileName);
					vScD.ConfigName = vScanConfigName;
					// Load picture
					vScImg = vScP.Scan(vScD, 0);
					// Recognize
					vScP.Recog();
					If vScP.Documents.Count = 0 Then
						Raise NStr("en='Recognition is not supported for the client identification document type choosen!';ru='Распознавание для данного вида документа удостоверяющего личность не поддерживается!';de='Die Erkennung dieser Art des Identitätsnachweises wird nicht unterstützt!'");
					EndIf;
					vFields = vScP.Documents.Item(0).FieldValues;
					// Check identification document type
					If Not ValueIsFilled(vCurRow.ScanConfiguration) Or
					   ValueIsFilled(vCurRow.ScanConfiguration) And Not ValueIsFilled(vCurRow.ScanConfiguration.IdentityDocumentType) Or 
					   ValueIsFilled(vCurRow.ScanConfiguration) And ValueIsFilled(vCurRow.ScanConfiguration.IdentityDocumentType) And 
					   TrimAll(vCurRow.ScanConfiguration.IdentityDocumentType.Code) = "21" And 
					   Not vCurRow.ScanConfiguration.IsMigrationCard And Not vCurRow.ScanConfiguration.IsVisa Then
						// Clear recognition quality
						pClientDataScansObj.RecognitionQuality.Clear();
						// Last name   
						pClientDataScansObj.LastName = Title(GetFieldValue(vFields, "PP_SurName"));
						FillQualityState(pClientDataScansObj, vFields.ItemId("PP_SurName"), "LastName");
						// First name   
						pClientDataScansObj.FirstName = Title(GetFieldValue(vFields, "PP_Name"));
						FillQualityState(pClientDataScansObj, vFields.ItemId("PP_Name"), "FirstName");
						// Second name   
						pClientDataScansObj.SecondName = Title(GetFieldValue(vFields, "PP_SecName"));
						FillQualityState(pClientDataScansObj, vFields.ItemId("PP_SecName"), "SecondName");
						// Sex
						vSex = GetClientSex(GetFieldValue(vFields, "PP_Sex"));
						If ValueIsFilled(vSex) Then
							pClientDataScansObj.Sex = vSex;
						EndIf;
						FillQualityState(pClientDataScansObj, vFields.ItemId("PP_Sex"), "Sex");
						// Date of birth
						vDateOfBirth = GetFieldValue(vFields, "PP_BirthDate");
						pClientDataScansObj.DateOfBirth = GetDateFromString(vDateOfBirth);
						FillQualityState(pClientDataScansObj, vFields.ItemId("PP_BirthDate"), "DateOfBirth");
						// Place of birth
						pClientDataScansObj.PlaceOfBirth = "РОССИЯ, , " + GetFieldValue(vFields, "PP_BirthPlace");
						FillQualityState(pClientDataScansObj, vFields.ItemId("PP_BirthPlace"), "PlaceOfBirth");
						// ID type
						vPassport = Catalogs.IdentityDocumentTypes.FindByCode("21");
						If ValueIsFilled(vPassport) Then
							pClientDataScansObj.IdentityDocumentType = vPassport;
						EndIf;
						// Citizenship
						pClientDataScansObj.Citizenship = Catalogs.Countries.FindByCode(643);
						// ID Series
						pClientDataScansObj.IdentityDocumentSeries = StrReplace(GetFieldValue(vFields, "PP_Ser2"), " ", "");
						FillQualityState(pClientDataScansObj, vFields.ItemId("PP_Ser2"), "IdentityDocumentSeries");
						// ID Number
						pClientDataScansObj.IdentityDocumentNumber = GetFieldValue(vFields, "PP_Num2");
						FillQualityState(pClientDataScansObj, vFields.ItemId("PP_Num2"), "IdentityDocumentNumber");
						// ID issue date
						vIdentityDocumentIssueDate = GetFieldValue(vFields, "PP_Date");
						pClientDataScansObj.IdentityDocumentIssueDate = GetDateFromString(vIdentityDocumentIssueDate);
						FillQualityState(pClientDataScansObj, vFields.ItemId("PP_Date"), "IdentityDocumentIssueDate");
						// ID issued by
						pClientDataScansObj.IdentityDocumentUnitCode = GetFieldValue(vFields, "PP_Podr");
						vQlt = vFields.ItemId("PP_Podr");
						vUnitCodeRecogQuality = FillQualityState(pClientDataScansObj, vQlt, "IdentityDocumentUnitCode");
						vQryRes = cmGetFMSRecord(TrimAll(pClientDataScansObj.IdentityDocumentUnitCode),True).Unload();	
						If vUnitCodeRecogQuality > 80 And vQryRes.Count()>0 Then
							pClientDataScansObj.IdentityDocumentIssuedBy = vQryRes[0].Description;
						Else	
							pClientDataScansObj.IdentityDocumentIssuedBy = GetFieldValue(vFields, "PP_Kem");
							FillQualityState(pClientDataScansObj, vFields.ItemId("PP_Kem"), "IdentityDocumentIssuedBy");
						EndIf;
						// Photo
						If vFields.ItemId("photo") <> Undefined Then
							pClientDataScansObj.Photo = New ValueStorage(New Picture(vScP.DirectoryPath + "\" + vFields.ItemId("photo").Value));
							FillQualityState(pClientDataScansObj, vFields.ItemId("photo"), "Photo");
						Else
							pClientDataScansObj.Photo = Undefined;
						EndIf;
						// Signature
						If vFields.ItemId("signature") <> Undefined Then
							pClientDataScansObj.Signature = New ValueStorage(New Picture(vScP.DirectoryPath + "\" + vFields.ItemId("signature").Value));
							FillQualityState(pClientDataScansObj, vFields.ItemId("signature"), "Signature");
						Else
							pClientDataScansObj.Signature = Undefined;
						EndIf;
					ElsIf ValueIsFilled(vCurRow.ScanConfiguration) And ValueIsFilled(vCurRow.ScanConfiguration.IdentityDocumentType) And 
					      TrimAll(vCurRow.ScanConfiguration.IdentityDocumentType.Code) = "30" And 
					      Not vCurRow.ScanConfiguration.IsMigrationCard And Not vCurRow.ScanConfiguration.IsVisa Then
						// Clear recognition quality
						pClientDataScansObj.RecognitionQuality.Clear();
						// Last name   
						pClientDataScansObj.LastName = Title(GetFieldValue(vFields, "DR_SurName"));
						FillQualityState(pClientDataScansObj, vFields.ItemId("DR_SurName"), "LastName");
						// First name   
						pClientDataScansObj.FirstName = Title(GetFieldValue(vFields, "DR_Name"));
						FillQualityState(pClientDataScansObj, vFields.ItemId("DR_Name"), "FirstName");
						// Second name   
						pClientDataScansObj.SecondName = Title(GetFieldValue(vFields, "DR_SecName"));
						FillQualityState(pClientDataScansObj, vFields.ItemId("DR_SecName"), "SecondName");
						// Sex
						pClientDataScansObj.Sex = cmGetSexByNames(pClientDataScansObj.LastName, pClientDataScansObj.FirstName, pClientDataScansObj.SecondName);
						// Date of birth
						vDateOfBirth = GetFieldValue(vFields, "DR_BirthDate");
						pClientDataScansObj.DateOfBirth = GetDateFromString(vDateOfBirth);
						FillQualityState(pClientDataScansObj, vFields.ItemId("DR_BirthDate"), "DateOfBirth");
						// ID type
						vDriverLicense = Catalogs.IdentityDocumentTypes.FindByCode("30");
						If ValueIsFilled(vDriverLicense) Then
							pClientDataScansObj.IdentityDocumentType = vDriverLicense;
						EndIf;
						// Citizenship
						pClientDataScansObj.Citizenship = Catalogs.Countries.FindByCode(643);
						// ID Series
						pClientDataScansObj.IdentityDocumentSeries = GetFieldValue(vFields, "DR_Ser");
						FillQualityState(pClientDataScansObj, vFields.ItemId("DR_Ser"), "IdentityDocumentSeries");
						// ID Number
						pClientDataScansObj.IdentityDocumentNumber = GetFieldValue(vFields, "DR_Num");
						FillQualityState(pClientDataScansObj, vFields.ItemId("DR_Num"), "IdentityDocumentNumber");
						// ID issue date
						vIdentityDocumentIssueDate = GetFieldValue(vFields, "DR_Date");
						pClientDataScansObj.IdentityDocumentIssueDate = GetDateFromString(vIdentityDocumentIssueDate);
						FillQualityState(pClientDataScansObj, vFields.ItemId("DR_Date"), "IdentityDocumentIssueDate");
						// Photo
						If vFields.ItemId("photo") <> Undefined Then
							pClientDataScansObj.Photo = New ValueStorage(New Picture(vScP.DirectoryPath + "\" + vFields.ItemId("photo").Value));
							FillQualityState(pClientDataScansObj, vFields.ItemId("photo"), "Photo");
						Else
							pClientDataScansObj.Photo = Undefined;
						EndIf;
						// Signature
						If vFields.ItemId("signature") <> Undefined Then
							pClientDataScansObj.Signature = New ValueStorage(New Picture(vScP.DirectoryPath + "\" + vFields.ItemId("signature").Value));
							FillQualityState(pClientDataScansObj, vFields.ItemId("signature"), "Signature");
						Else
							pClientDataScansObj.Signature = Undefined;
						EndIf;
					ElsIf ValueIsFilled(vCurRow.ScanConfiguration) And ValueIsFilled(vCurRow.ScanConfiguration.IdentityDocumentType) And 
					      TrimAll(vCurRow.ScanConfiguration.IdentityDocumentType.Code) = "ИП" And 
					      Not vCurRow.ScanConfiguration.IsMigrationCard And Not vCurRow.ScanConfiguration.IsVisa Then
						// Clear recognition quality
						pClientDataScansObj.RecognitionQuality.Clear();
						// Last name   
						pClientDataScansObj.LastName = Title(GetFieldValue(vFields, "IN_SurName"));
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_SurName"), "LastName");
						// First name   
						pClientDataScansObj.FirstName = Title(GetFieldValue(vFields, "IN_Name"));
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_Name"), "FirstName");
						// Sex
						vSex = GetClientSex(GetFieldValue(vFields, "IN_Sex"));
						If ValueIsFilled(vSex) Then
							pClientDataScansObj.Sex = vSex;
						EndIf;
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_Sex"), "Sex");
						// Date of birth
						vDateOfBirth = GetFieldValue(vFields, "IN_BirthDate");
						pClientDataScansObj.DateOfBirth = GetDateFromString(vDateOfBirth);
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_BirthDate"), "DateOfBirth");
						// ID type
						vPassport = Catalogs.IdentityDocumentTypes.FindByCode("ИП");
						If ValueIsFilled(vPassport) Then
							pClientDataScansObj.IdentityDocumentType = vPassport;
						EndIf;
						// Citizenship
						vCountryISO3Code = GetFieldValue(vFields, "IN_CNT");
						pClientDataScansObj.Citizenship = Catalogs.Countries.FindByAttribute("ISOCode3", vCountryISO3Code);
						FillQualityState(pClientDataScansObj, vFields.Field("IN_CNT"), "Citizenship");
						// ID Series
						pClientDataScansObj.IdentityDocumentSeries = "";
						// ID Number
						pClientDataScansObj.IdentityDocumentNumber = GetFieldValue(vFields, "IN_SerNum");
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_SerNum"), "IdentityDocumentNumber");
						// Expire date   
						vIdentityDocumentValidToDate = GetFieldValue(vFields, "IN_Expiry");
						pClientDataScansObj.IdentityDocumentValidToDate = GetDateFromString(vIdentityDocumentValidToDate, 90);
						FillQualityState(pClientDataScansObj, vFields.Field("IN_Expiry"), "IdentityDocumentValidToDate");
						// Photo
						If vFields.ItemId("IN_FOTO") <> Undefined Then
							pClientDataScansObj.Photo = New ValueStorage(New Picture(vScP.DirectoryPath + "\" + vFields.ItemId("IN_FOTO").Value));
							FillQualityState(pClientDataScansObj, vFields.ItemId("IN_FOTO"), "Photo");
						Else
							pClientDataScansObj.Photo = Undefined;
						EndIf;
					ElsIf ValueIsFilled(vCurRow.ScanConfiguration) And ValueIsFilled(vCurRow.ScanConfiguration.IdentityDocumentType) And 
					      TrimAll(vCurRow.ScanConfiguration.IdentityDocumentType.Code) = "22" And 
					      Not vCurRow.ScanConfiguration.IsMigrationCard And Not vCurRow.ScanConfiguration.IsVisa Then
						// Clear recognition quality
						pClientDataScansObj.RecognitionQuality.Clear();
						// Last name   
						pClientDataScansObj.LastName = Title(GetFieldValue(vFields, "IN_SurName"));
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_SurName"), "LastName");
						// First name   
						pClientDataScansObj.FirstName = Title(GetFieldValue(vFields, "IN_Name"));
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_Name"), "FirstName");
						// Sex
						vSex = GetClientSex(GetFieldValue(vFields, "IN_Sex"));
						If ValueIsFilled(vSex) Then
							pClientDataScansObj.Sex = vSex;
						EndIf;
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_Sex"), "Sex");
						// Date of birth
						vDateOfBirth = GetFieldValue(vFields, "IN_BirthDate");
						pClientDataScansObj.DateOfBirth = GetDateFromString(vDateOfBirth);
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_BirthDate"), "DateOfBirth");
						// ID type
						vPassport = Catalogs.IdentityDocumentTypes.FindByCode("22");
						If ValueIsFilled(vPassport) Then
							pClientDataScansObj.IdentityDocumentType = vPassport;
						EndIf;
						// Citizenship
						pClientDataScansObj.Citizenship = Catalogs.Countries.FindByCode(643);
						// ID Series
						pClientDataScansObj.IdentityDocumentSeries = "";
						// ID Number
						pClientDataScansObj.IdentityDocumentNumber = GetFieldValue(vFields, "IN_SerNum2");
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_SerNum2"), "IdentityDocumentNumber");
						If Not IsBlankString(pClientDataScansObj.IdentityDocumentNumber) Then
							If StrLen(TrimAll(pClientDataScansObj.IdentityDocumentNumber)) > 8 Then
								pClientDataScansObj.IdentityDocumentSeries = Left(TrimAll(pClientDataScansObj.IdentityDocumentNumber), 2);
								pClientDataScansObj.IdentityDocumentNumber = Mid(TrimAll(pClientDataScansObj.IdentityDocumentNumber), 3);
							EndIf;
						EndIf;
						// ID issue date
						vIdentityDocumentIssueDate = GetFieldValue(vFields, "IN_Date");
						pClientDataScansObj.IdentityDocumentIssueDate = GetDateFromString(vIdentityDocumentIssueDate);
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_Date"), "IdentityDocumentIssueDate");
						// ID issued by
						pClientDataScansObj.IdentityDocumentIssuedBy = GetFieldValue(vFields, "IN_Kem");
						FillQualityState(pClientDataScansObj, vFields.ItemId("IN_Kem"), "IdentityDocumentIssuedBy");
						// Expiry date   
						vIdentityDocumentValidToDate = GetFieldValue(vFields, "IN_ExpiryDate");
						pClientDataScansObj.IdentityDocumentValidToDate = GetDateFromString(vIdentityDocumentValidToDate, 90);
						FillQualityState(pClientDataScansObj, vFields.Field("IN_ExpiryDate"), "IdentityDocumentValidToDate");
						// Photo
						If vFields.ItemId("IN_PHOTO2") <> Undefined Then
							pClientDataScansObj.Photo = New ValueStorage(New Picture(vScP.DirectoryPath + "\" + vFields.ItemId("IN_PHOTO2").Value));
							FillQualityState(pClientDataScansObj, vFields.ItemId("IN_PHOTO2"), "Photo");
						Else
							pClientDataScansObj.Photo = Undefined;
						EndIf;
						// Signature
						If vFields.ItemId("IN_SIGN2") <> Undefined Then
							pClientDataScansObj.Signature = New ValueStorage(New Picture(vScP.DirectoryPath + "\" + vFields.ItemId("IN_SIGN2").Value));
							FillQualityState(pClientDataScansObj, vFields.ItemId("IN_SIGN2"), "Signature");
						Else
							pClientDataScansObj.Signature = Undefined;
						EndIf;
					Else
						Raise NStr("en='Recognition is not supported for the client identification document type choosen!';ru='Распознавание для данного вида документа удостоверяющего личность не поддерживается!';de='Die Erkennung dieser Art des Identitätsnachweises wird nicht unterstützt!'");
					EndIf;
					Try
						vScD.Close();
					Except
					EndTry;
					Try
						vScP.Destroy();
					Except
					EndTry;
					// Delete working images
					DeleteFiles(vPictFileName);
				EndIf;
			EndDo;
			// Return success
			Return True;
		Except
			rMessage = ErrorDescription();
			Try
				vScD.Close();
			Except
			EndTry;
			Try
				vScP.Destroy();
			Except
			EndTry;
			ProcessException(vScObj, vScI, NStr("en='ImageScannerDriver.RecognizeDocument';ru='СканерИзображений.РаспознатьДокумент';de='ImageScannerDriver.RecognizeDocument'"), rMessage);
		EndTry;
	EndIf;
	Return False;
EndFunction // pmRecognizeDocument
