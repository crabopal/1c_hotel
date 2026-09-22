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
Function pmConnect(rMessage, pDummy = Undefined) Export
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		// Use ActiveX object
		vScObj = Undefined;
		#IF CLIENT THEN
			vScObj = New COMObject("passport_box_com.PBCOM");
			Try
				vJSONPath = TrimAll(ImageScannerConnectionParameters.ScanComponentInstallationPath);
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
				vAutoCaptureSettings = New COMObject("passport_box_com.PBCOM_AutoCaptureSettings");
				vCaptureSettings = New COMObject("passport_box_com.PBCOM_CaptureSettings");
				If ImageScannerConnectionParameters.AutoRecognition Then
					If vScObj.StartAutoCapturePassport(vAutoCaptureSettings, vCaptureSettings) < 0 Then
					    Raise NStr("en='Failed to start auto capture! '; ru='Не удалось запустить автоматическое распознавание! '; de='Fehler beim Auto-Capture zu starten! '") + vScObj.GetLastError().ErrMessage;
					EndIf;
				EndIf;
			Except
				tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);
				vScObj = Undefined;
			EndTry;
			If amImageScannerDriver = Undefined Then
				amImageScannerDriver = ThisObject;
			EndIf;
		#ENDIF
		// OK
		Return vScObj;
	Except
		//amImageScanner = Undefined;
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pScObj, pDummy = Undefined) Export
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
Procedure ProcessException(pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, ImageScannerConnectionParameters.Metadata(), ImageScannerConnectionParameters, "Error description: " + rMessage);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function pmScanDocument(pScanConfiguration, pPictureStorage, rMessage) Export
	rMessage = NStr("en='Not supported!'; ru='Не поддерживается!'; de='Not supported!'");
	Return False;
EndFunction // pmScanDocument

// -----------------------------------------------------------------------------
Function pmRecognizeDocument(pClientDataScansObj, rMessage, pScObj = Undefined, pDummy = Undefined) Export
	rMessage = NStr("en='Not supported! Use <Scan> button instead.'; ru='Не поддерживается! Используйте кнопку <Сканировать>.'; de='Not supported! Verwenden <Scan> Knopf dafür.'");
	Return False;
EndFunction // pmRecognizeDocument

// -----------------------------------------------------------------------------
Function pmGetImageData(pClientDataScansObj, pClientDataScansRow, rMessage, pScObj = Undefined) Export
	Try
		// Try to get passport picture
		If pClientDataScansRow <> Undefined Then
			pScObj.TakeSnapshot();
			pClientDataScansRow.ScanPicture = New ValueStorage(New Picture(Base64Value(pScObj.GetSnapshotBase64())));
			Return True;
		EndIf;
	Except
		rMessage = ErrorDescription();
		ProcessException(NStr("en='ImageScannerDriver.DetectDocument';ru='СканерИзображений.СохранитьДокумент';de='ImageScannerDriver.DetectDocument'"), rMessage);
	EndTry;
	Return False;
EndFunction // pmGetImageData

// -----------------------------------------------------------------------------
Function pmGetRecognizedData(pClientDataScansObj, pScanConfiguration, rMessage, pScObj = Undefined) Export
	Try
		If ValueIsFilled(pScanConfiguration) And ValueIsFilled(pScanConfiguration.IdentityDocumentType) And TrimAll(pScanConfiguration.IdentityDocumentType.Code) = "21" Then
			vCapturedData = pScObj.GetDocumentInfo();
			If lower(vCapturedData.DocType) = "rus.passport.national" Then
				// Fill structure with captured data
				vData = New Structure();
				For i = 0 To (vCapturedData.FieldCount - 1) Do
					vFieldInfo = pScObj.GetFieldInfo(i);
					vData.Insert(vFieldInfo.FieldName, vFieldInfo.FieldValue);
					vData.Insert("Is" + Title(vFieldInfo.FieldName) + "Accepted", vFieldInfo.IsAccepted);
				EndDo;
				For i = 0 To (vCapturedData.ImageCount - 1) Do
					vImageName = StrReplace(StrReplace(pScObj.GetImageName(i), ".", "_"), ":", "_");
					vData.Insert(vImageName, pScObj.GetImageBase64(i));
				EndDo;
				// Fill data
				If vData.Property("IsSurnameAccepted") And vData.IsSurnameAccepted Then
					pClientDataScansObj.LastName = Title(vData.Surname);
				EndIf;
				If vData.Property("IsNameAccepted") And vData.IsNameAccepted Then
					pClientDataScansObj.FirstName = Title(vData.Name);
				EndIf;
				If vData.Property("IsPatronymicAccepted") And vData.IsPatronymicAccepted Then
					pClientDataScansObj.SecondName = Title(vData.Patronymic);
				EndIf;
				If vData.Property("IsBirthdateAccepted") And vData.IsBirthdateAccepted Then
					pClientDataScansObj.DateOfBirth = GetDateFromString(vData.BirthDate);
				EndIf;
				If vData.Property("IsGenderAccepted") And vData.IsGenderAccepted Then
					pClientDataScansObj.Sex = GetClientSex(vData.Gender);
				EndIf;
				pClientDataScansObj.IdentityDocumentType = pScanConfiguration.IdentityDocumentType;
				If vData.Property("IsSeriesAccepted") And vData.IsSeriesAccepted Then
					pClientDataScansObj.IdentityDocumentSeries = StrReplace(vData.Series, " ", "");
				EndIf;
				If vData.Property("IsNumberAccepted") And vData.IsNumberAccepted Then
					pClientDataScansObj.IdentityDocumentNumber = StrReplace(vData.Number, " ", "");
				EndIf;
				vSkipAuthority = False;
				If vData.Property("IsAuthority_CodeAccepted") And vData.IsAuthority_CodeAccepted Then
					pClientDataScansObj.IdentityDocumentUnitCode = TrimAll(vData.Authority_Code);
					If Not IsBlankString(pClientDataScansObj.IdentityDocumentUnitCode) Then
						vQryRes = cmGetFMSRecord(TrimAll(pClientDataScansObj.IdentityDocumentUnitCode), True).Choose();
						While vQryRes.Next() Do
							pClientDataScansObj.IdentityDocumentIssuedBy = TrimAll(vQryRes.Description);
							vSkipAuthority = True;
							Break;
						EndDo;
					EndIf;
				EndIf;
				If Not vSkipAuthority Then
					If vData.Property("IsAuthorityAccepted") And vData.IsAuthorityAccepted Then
						pClientDataScansObj.IdentityDocumentIssuedBy = TrimAll(vData.Authority);
					EndIf;
				EndIf;
				If vData.Property("IsIssue_DateAccepted") And vData.IsIssue_DateAccepted Then
					pClientDataScansObj.IdentityDocumentIssueDate = GetDateFromString(vData.Issue_Date);
				EndIf;
				If vData.Property("IsBirthPlaceAccepted") And vData.IsBirthPlaceAccepted Then
					pClientDataScansObj.PlaceOfBirth = TrimAll(vData.BirthPlace);
				EndIf;
				// Try to get photo picture
				If vData.Property("Photo") Then
					If Not IsBlankString(vData.Photo) Then
						pClientDataScansObj.Photo = New ValueStorage(New Picture(Base64Value(vData.Photo)));
					EndIf;
				EndIf;
				// Try to get signature picture
				If vData.Property("Signature") Then
					If Not IsBlankString(vData.Signature) Then
						pClientDataScansObj.Signature = New ValueStorage(New Picture(Base64Value(vData.Signature)));
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		Return True;
	Except
		rMessage = ErrorDescription();
		ProcessException(NStr("en='ImageScannerDriver.RecognizeDocument';ru='СканерИзображений.РаспознатьДокумент';de='ImageScannerDriver.RecognizeDocument'"), rMessage);
	EndTry;
	Return False;
EndFunction // pmGetRecognizedData
