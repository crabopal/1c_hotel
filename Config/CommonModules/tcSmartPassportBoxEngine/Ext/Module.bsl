
// -----------------------------------------------------------------------------
Function pmConnect(rMessage="") Export 
	#If WebClient Then
		ShowMessageBox(,NStr("en = 'Image scanning not supported in Web client'; de = 'Das Scannen von Bildern wird im Web-Client nicht unterstützt'; ru = 'Сканирование изображений не поддерживается в Web клиенте'"));
		Return Undefined;
	#EndIf
	rMessage = "";

	vScObj = Undefined;
	#IF NOT MobileClient THEN
		Try
			If amImageScannerInstance = Undefined Then
				// Create passport box object
				vScObj = New COMObject("passport_box_com.PBCOM");
				// Connect to Passport box
				vJSONPath = TrimAll(tcDevicesConnection.cmGetImagesScannerParameters("ScanComponentInstallationPath"));
				If Right(vJSONPath, 1) <> "\" Then
					vJSONPath = vJSONPath + "\";
				EndIf;
				vJSONPath = vJSONPath + "passport_box_api.json";
				If vScObj.Configure(vJSONPath) < 0 Then
					Raise vScObj.GetLastError().ErrMessage;
				EndIf;
				If vScObj.OpenCaptureDevice() < 0 Then
					Raise vScObj.GetLastError().ErrMessage;
				EndIf;
				amImageScannerInstance = vScObj;
			Else
				vScObj = amImageScannerInstance;
			Endif;
		Except
			rMessage = NStr("en='Failed to connect to Passport box device! '; 
			|ru='Ошибка подключения к Passport box! '; 
			|de='Fehler bei Passport-Box verbinden! '")+Chars.LF+BriefErrorDescription(ErrorInfo());
			tcOnServer.cmWriteLogEventAtServer("AutoRecognition",,,,ErrorDescription());
			
			vScObj = Undefined;
		EndTry;
	#ENDIF
	
	Return vScObj;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
// Disconnect images scanner
//
// Parameters:
//  pScObj	 - ComObject - ComObject images scanner
//
Procedure pmDisconnect(pScObj) Export
	#If WebClient Or MobileClient Then
		Return;
	#EndIf
	Try
		If pScObj.StopAutoCapturePassport() < 0 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to stop auto capture! '; ru='Не удалось остановить распознавание! '; de='Fehler beim Auto-Capture zu stoppen! '") + pScObj.GetLastError().ErrMessage, MessageStatus.Information);
		EndIf;
		If pScObj.CloseCaptureDevice() < 0 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to disconnect from passport box! '; ru='Не удалось отключиться от Passport box! '; de='Fehler beim Passport-Box zu trennen! '") + pScObj.GetLastError().ErrMessage, MessageStatus.Information);
		EndIf;
		pScObj = Undefined;
	Except
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function BuildCapturedFieldsStructure(pPBObj, pCapturedData)
	// Fill structure with captured data
	vData = New Structure();
	For i = 0 To (pCapturedData.FieldCount - 1) Do
		vFieldInfo = pPBObj.GetFieldInfo(i);
		vData.Insert(vFieldInfo.FieldName, vFieldInfo.FieldValue);
		vData.Insert("Is" + Title(vFieldInfo.FieldName) + "Accepted", vFieldInfo.IsAccepted);
	EndDo;
	For i = 0 To (pCapturedData.ImageCount - 1) Do
		vImageName = StrReplace(StrReplace(pPBObj.GetImageName(i), ".", "_"), ":", "_");
		vData.Insert(vImageName, pPBObj.GetImageBase64(i));
	EndDo;
	Return vData;
EndFunction // BuildCapturedFieldsStructure

// -----------------------------------------------------------------------------
// Scan document
//
// Parameters:
//  pInputParameters  - Structure - Input parameters
//
//  pOuputParameters  - Structure - Output parameters
//
//	rMessage  - String - The string to which the error message is written.
//
Procedure ScanDocument(pInputParameters, pOuputParameters, rMessage = "") Export
	PBObj = amImageScannerInstance;
	#IF NOT MobileClient THEN
		If PBObj = Undefined Then
			PBObj = pmConnect(rMessage);
			If Not IsBlankString(rMessage) Or PBObj = Undefined Then
				Return;
			EndIf; 
		EndIf; 
		vUUID = pInputParameters.FormUUID;
		If Not ValueIsFilled(vUUID) Then
		  vUUID = New UUID;
		EndIf; 
		CaptureSettings = New COMObject("passport_box_com.PBCOM_CaptureSettings");
		
		If pInputParameters.ScanConfiguration.RecognitionIsAvailable Then
			// Try to recognize passport
			If PBObj.CapturePassport(CaptureSettings) < 0 Then
				// Try to get document picture
				PBObj.TakeSnapshot();
				vSnapshot = PutToTempStorage(New Picture(Base64Value(PBObj.GetSnapshotBase64())),vUUID);
				// Save document picture
				pOuputParameters.IdentityDocumentPicture = vSnapshot;
			Else
				vCapturedData = PBObj.GetDocumentInfo();
				If lower(vCapturedData.DocType) = "rus.passport.national" Then
					// Fill structure with captured data
					vData = BuildCapturedFieldsStructure(PBObj, vCapturedData);
					// Fill client data
					FillGuestDataFromPassportRU(vData, pOuputParameters, vUUID, pInputParameters.ScanConfiguration.IdentityDocumentType);
				ElsIf StrFind(lower(vCapturedData.DocType), "mrz.") > 0 Then
					// Fill structure with captured data
					vData = BuildCapturedFieldsStructure(PBObj, vCapturedData);
					// Fill client data
					FillGuestDataFromMRZ(vData, pOuputParameters, vUUID, pInputParameters.ScanConfiguration.IdentityDocumentType);
					// Try to get document picture
					PBObj.TakeSnapshot();
					vSnapshot = PutToTempStorage(New Picture(Base64Value(PBObj.GetSnapshotBase64())),vUUID);
					// Save document picture
					pOuputParameters.IdentityDocumentPicture = vSnapshot;
				Else
					// Try to get document picture
					PBObj.TakeSnapshot();
					vSnapshot = PutToTempStorage(New Picture(Base64Value(PBObj.GetSnapshotBase64())), vUUID);
					// Save document picture
					pOuputParameters.IdentityDocumentPicture = vSnapshot;
				EndIf;
			EndIf;
		Else
			// Try to get document picture
			PBObj.TakeSnapshot();
			vSnapshot = PutToTempStorage(New Picture(Base64Value(PBObj.GetSnapshotBase64())),vUUID);
			// Save document picture
			pOuputParameters.IdentityDocumentPicture = vSnapshot;
		EndIf;
	#ENDIF
EndProcedure // ScanDocument

// -----------------------------------------------------------------------------
Procedure FillGuestDataFromPassportRU(pData, pOuputParameters, pUUID, pIdentityDocumentType)
	vGuestData 			= pOuputParameters;
	vRecognitionQuality = pOuputParameters.RecognitionQuality;	
	vGuestData.FillAllItems = True;
	// Fill from scan results
	If pData.Property("surname") Then
		vGuestData.LastName = Title(pData.Surname);
		If pData.Property("IsSurnameAccepted") Then
			If pData.IsSurnameAccepted = False Then
			  vRecognitionQuality.Insert("LastName", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("LastName", 70);
		EndIf;	
	EndIf;
	If pData.Property("Name") Then
		vGuestData.FirstName = Title(pData.Name);
		If pData.Property("IsNameAccepted") Then
			If pData.IsNameAccepted = False Then
			  vRecognitionQuality.Insert("FirstName", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("FirstName", 70);
		EndIf;	
	EndIf;
	If pData.Property("Patronymic") Then
		vGuestData.SecondName = Title(pData.Patronymic);
		If pData.Property("IsPatronymicAccepted") Then
			If pData.IsPatronymicAccepted = False Then
			  vRecognitionQuality.Insert("SecondName", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("SecondName", 70);
		EndIf;	
	EndIf;
	If pData.Property("BirthDate") Then
		vGuestData.DateOfBirth = GetDateFromString(pData.BirthDate);
		If pData.Property("IsBirthdateAccepted") Then
			If pData.IsBirthdateAccepted = False Then
			  vRecognitionQuality.Insert("DateOfBirth", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("DateOfBirth", 70);
		EndIf;	
	EndIf;
	If pData.Property("Gender") Then
		vGuestData.Sex = GetClientSex(pData.Gender);
		If pData.Property("IsGenderAccepted") Then
			If pData.IsGenderAccepted = False Then
			  vRecognitionQuality.Insert("Sex", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("Sex", 70);
		EndIf;	
	EndIf;
	vGuestData.IdentityDocumentType = pIdentityDocumentType;
	If pData.Property("Series") Then
		vGuestData.IdentityDocumentSeries = StrReplace(pData.Series, " ", "");
		If pData.Property("IsSeriesAccepted") Then
			If pData.IsSeriesAccepted = False Then
			  vRecognitionQuality.Insert("IdentityDocumentSeries", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentSeries", 70);
		EndIf;	
	EndIf;
	If pData.Property("Number") Then
		vGuestData.IdentityDocumentNumber = StrReplace(pData.Number, " ", "");
		If pData.Property("IsNumberAccepted") Then
			If pData.IsNumberAccepted = False Then
			  vRecognitionQuality.Insert("IdentityDocumentNumber", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentNumber", 70);
		EndIf;	
	EndIf;
	vSkipAuthority = False;
	If pData.Property("authority_code") Then
		vGuestData.IdentityDocumentUnitCode = TrimAll(pData.authority_code);
		If pData.Property("IsAuthority_codeAccepted") Then
			If pData.IsAuthority_codeAccepted = False Then
				vRecognitionQuality.Insert("IdentityDocumentIssuedBy", 70);
			Else
				If Not IsBlankString(vGuestData.IdentityDocumentUnitCode) Then
					vGuestData.IdentityDocumentIssuedBy = tcOnServer.qmGetIssuedBy(TrimAll(vGuestData.IdentityDocumentUnitCode));
					If Not IsBlankString(vGuestData.IdentityDocumentIssuedBy) Then
						vSkipAuthority = True;
					EndIf;
				EndIf;	
			EndIf;	
			
		Else
			vRecognitionQuality.Insert("IdentityDocumentIssuedBy", 70);
		EndIf;	
	EndIf;
	If Not vSkipAuthority Then
		If pData.Property("Authority") Then
			vGuestData.IdentityDocumentIssuedBy = TrimAll(pData.Authority);
			If pData.Property("IsAuthorityAccepted") Then
				If pData.IsAuthorityAccepted = False Then
					vRecognitionQuality.Insert("IdentityDocumentIssuedBy", 70);
				EndIf; 
			Else
				vRecognitionQuality.Insert("IdentityDocumentIssuedBy", 70);
			EndIf;	
		EndIf;
	EndIf;
	If pData.Property("issue_date") Then
		vGuestData.IdentityDocumentIssueDate = GetDateFromString(pData.issue_date);
		If pData.Property("IsIssue_DateAccepted") Then
			If pData.IsIssue_DateAccepted = False Then
			  vRecognitionQuality.Insert("IdentityDocumentIssueDate", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentIssueDate", 70);
		EndIf;	
	EndIf;
	If pData.Property("BirthPlace") Then
		vGuestData.PlaceOfBirth = TrimAll(pData.BirthPlace);
		If pData.Property("IsBirthPlaceAccepted") Then
			If pData.IsBirthPlaceAccepted = False Then
			  vRecognitionQuality.Insert("PlaceOfBirth", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("PlaceOfBirth", 70);
		EndIf;	
	EndIf;
	// Try to get passport photo
	If pData.Property("Photo") Then
		vGuestData.Photo = PutToTempStorage(New Picture(Base64Value(pData.Photo)), pUUID);
	EndIf;
	// Try to get passport signature
	If pData.Property("Signature") Then
		vGuestData.Signature = PutToTempStorage(New Picture(Base64Value(pData.Signature)), pUUID);
	EndIf;
	// Try to get passport picture
	If pData.Property("Full_Document") Then
		vGuestData.IdentityDocumentPicture = PutToTempStorage(New Picture(Base64Value(pData.Full_Document)), pUUID);
	Else
		amImageScannerInstance.TakeSnapshot();
		vSnapshot = PutToTempStorage(New Picture(Base64Value(amImageScannerInstance.GetSnapshotBase64())),pUUID);
		vGuestData.IdentityDocumentPicture = vSnapshot;
	EndIf;
EndProcedure // FillGuestDataFromPassportRU

// -----------------------------------------------------------------------------
Procedure FillGuestDataFromMRZ(pData, pOuputParameters, pUUID, pIdentityDocumentType)
	vGuestData 			= pOuputParameters;
	vRecognitionQuality = pOuputParameters.RecognitionQuality;	
	vGuestData.FillAllItems = True;
	// Fill from scan results
	If pData.Property("last_name_mrz") Then
		vGuestData.LastName = Title(pData.last_name_mrz);
		If pData.Property("IsLast_name_mrzAccepted") Then
			If pData.IsLast_name_mrzAccepted = False Then
			  vRecognitionQuality.Insert("LastName", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("LastName", 70);
		EndIf;	
	EndIf;
	If pData.Property("first_name_mrz") Then
		vGuestData.FirstName = Title(pData.first_name_mrz);
		If pData.Property("IsFirst_name_mrzAccepted") Then
			If pData.IsFirst_name_mrzAccepted = False Then
			  vRecognitionQuality.Insert("FirstName", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("FirstName", 70);
		EndIf;	
	EndIf;
	If pData.Property("birth_date_mrz") Then
		vGuestData.DateOfBirth = GetDateFromString(pData.birth_date_mrz);
		If pData.Property("IsBirth_date_mrzAccepted") Then
			If pData.IsBirth_date_mrzAccepted = False Then
			  vRecognitionQuality.Insert("DateOfBirth", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("DateOfBirth", 70);
		EndIf;	
	EndIf;
	If pData.Property("gender_mrz") Then
		vGuestData.Sex = GetClientSex(pData.gender_mrz);
		If pData.Property("IsGender_mrzAccepted") Then
			If pData.IsGender_mrzAccepted = False Then
			  vRecognitionQuality.Insert("Sex", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("Sex", 70);
		EndIf;	
	EndIf;
	vGuestData.IdentityDocumentType = pIdentityDocumentType;
	If pData.Property("series_mrz") Then
		vGuestData.IdentityDocumentSeries = StrReplace(pData.series_mrz, " ", "");
		If pData.Property("IsSeries_mrzAccepted") Then
			If pData.IsSeries_mrzAccepted = False Then
			  vRecognitionQuality.Insert("IdentityDocumentSeries", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentSeries", 70);
		EndIf;	
	EndIf;
	If pData.Property("number_mrz") Then
		vGuestData.IdentityDocumentNumber = StrReplace(pData.Number_mrz, " ", "");
		If pData.Property("IsNumber_mrzAccepted") Then
			If pData.IsNumber_mrzAccepted = False Then
			  vRecognitionQuality.Insert("IdentityDocumentNumber", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentNumber", 70);
		EndIf;	
	EndIf;
	If pData.Property("issuer_mrz") Then
		vGuestData.IdentityDocumentIssuedBy = TrimAll(pData.issuer_mrz);
		If pData.Property("IsIssuer_mrzAccepted") Then
			If pData.IsIssuer_mrzAccepted = False Then
				vRecognitionQuality.Insert("IdentityDocumentIssuedBy", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentIssuedBy", 70);
		EndIf;	
	EndIf;
	If pData.Property("issue_date_mrz") And vGuestData.Property("IdentityDocumentIssueDate") Then
		vGuestData.IdentityDocumentIssueDate = GetDateFromString(pData.issue_date_mrz);
		If pData.Property("IsIssue_date_mrzAccepted") Then
			If pData.IsIssue_date_mrzAccepted = False Then
			  vRecognitionQuality.Insert("IdentityDocumentIssueDate", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentIssueDate", 70);
		EndIf;	
	EndIf;
	If pData.Property("expiry_date_mrz") And vGuestData.Property("IdentityDocumentValidToDate") Then
		vGuestData.IdentityDocumentValidToDate = GetDateFromString(pData.expiry_date_mrz);
		If pData.Property("IsExpiry_date_mrzAccepted") Then
			If pData.IsExpiry_date_mrzAccepted = False Then
			  vRecognitionQuality.Insert("IdentityDocumentValidToDate", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("IdentityDocumentValidToDate", 70);
		EndIf;	
	EndIf;
	If pData.Property("nationality_mrz") And vGuestData.Property("Citizenship") Then
		vGuestData.Citizenship = tcOnServer.GetCountryByCode(TrimAll(pData.nationality_mrz));
		If pData.Property("IsNationality_mrzAccepted") Then
			If pData.IsNationality_mrzAccepted = False Then
			  vRecognitionQuality.Insert("Citizenship", 70);
			EndIf; 
		Else
			vRecognitionQuality.Insert("Citizenship", 70);
		EndIf;	
	EndIf;
EndProcedure // FillGuestDataFromMRZ

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

