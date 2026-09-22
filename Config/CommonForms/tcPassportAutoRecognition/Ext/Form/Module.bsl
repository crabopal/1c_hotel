
#Region Variables

&AtClient
Var PBObj;
&AtClient
Var AutoCaptureSettings;
&AtClient
Var CaptureSettings;
&AtClient
Var GuestData;
&AtClient
Var EventMode;
&AtClient
Var SavGuestStatus;
&AtClient
Var SavGuestStatusColor;
&AtClient
Var PassportWasRecognized;
&AtClient
Var WaitForRecognitionTimeout;
&AtClient
Var DocumentDescription;

#EndRegion

#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
		Return;
	EndIf;
	If Parameters.Property("Document") And ValueIsFilled(Parameters.Document) Then
		DocumentType = "P1";
		Reservation = Parameters.Document;
		GuestFullName = "";
		GuestFirstName = "";
		GuestLastName = "";
		GuestSecondName = "";
		GuestLastNameScanned = "";
		GuestFirstNameScanned = "";
		GuestSecondNameScanned = "";
		GuestGroup = Reservation.GuestGroup;
		PeriodOfStay = Format(Reservation.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(Reservation.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + 
		               TrimAll(Reservation.RoomType) + 
					   ?(ValueIsFilled(Reservation.Room), ", " + TrimAll(Reservation.Room), "");
		DocumentDescription = "";
		// Fill one room guests
		FillOneRoomGuests();
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	PassportWasRecognized = False;
	WaitForRecognitionTimeout = 12;
	
	#IF NOT MobileClient THEN
		If amImageScanner = Undefined Then
			vMsg = "";
			vModuleName = tcDevicesConnection.cmGetImagesScannerDriverModule(vMsg);
			
			If Not IsBlankString(vMsg) Then
				tcCommonFunctionOnClientServer.UserMessage(vMsg);
				Return;
			EndIf;
			
			If vModuleName = "tcSmartPassportBoxEngine" Then
				Try
					// Create passport box object
					PBObj = New COMObject("passport_box_com.PBCOM");
					CaptureSettings = New COMObject("passport_box_com.PBCOM_CaptureSettings");
					AutoCaptureSettings = New COMObject("passport_box_com.PBCOM_AutoCaptureSettings");
					AddHandler PBObj.RecognitionEvent, AutoOCREvent;
					amImageScanner = tcSmartPassportBoxEngine;
					
					// Connect to Passport box
					ConnectionParameters = GetConnectionParameters();
					vJSONPath = TrimAll(tcOnServer.cmGetAttributeByRef(ConnectionParameters, "ScanComponentInstallationPath"));
					If Right(vJSONPath, 1) <> "\" Then
						vJSONPath = vJSONPath + "\";
					EndIf;
					vJSONPath = vJSONPath + "passport_box_api.json";
					If PBObj.Configure(vJSONPath) < 0 Then
						Raise PBObj.GetLastError().ErrMessage;
					EndIf;
					If PBObj.OpenCaptureDevice() < 0 Then
						Raise PBObj.GetLastError().ErrMessage;
					EndIf;
					If tcOnServer.cmGetAttributeByRef(ConnectionParameters, "AutoRecognition") Then
						If PBObj.StartAutoCapturePassport(AutoCaptureSettings, CaptureSettings) < 0 Then
							GuestStatus = NStr("en='Failed to start auto capture! '; 
							|ru='Не удалось запустить автоматическое распознавание! '; 
							|de='Fehler beim Auto-Capture zu starten! '") + 
							PBObj.GetLastError().ErrMessage;
							Items.GuestStatus.TextColor = WebColors.Red;
						Else
							GuestStatus = NStr("en='Place passport first page over Passport box!'; 
							|ru='Положите паспорт открытый на первой странице на Passport Box!'; 
							|de='Platz Pass erste Seite über Passport-Box!'");
							Items.GuestStatus.TextColor = WebColors.Blue;
						EndIf;
					Else
						GuestStatus = NStr("en='Place passport first page over Passport box!'; 
						|ru='Положите паспорт открытый на первой странице на Passport Box!'; 
						|de='Platz Pass erste Seite über Passport-Box!'");
						Items.GuestStatus.TextColor = WebColors.Blue;
					EndIf;
				Except
					GuestStatus = NStr("en='Failed to connect to Passport box device! '; 
					|ru='Ошибка подключения к Passport box! '; 
					|de='Fehler bei Passport-Box verbinden! '");
					tcOnServer.cmWriteLogEventAtServer("AutoRecognition",,,,ErrorDescription());
					Items.GuestStatus.TextColor = WebColors.Red;
					PBObj = Undefined;
				EndTry;
			Else
				Try
					// Create Regula object
					PBObj = New COMObject("READERDEMO.regulaReader");
					
					// Connect to Regula
					If Not PBObj.Connected Then
						PBObj.Connect();   
					EndIf; 
					
					PBObj.MultiPageProcessing = False;
					
					If Not PBObj.Connected Then
						GuestStatus = NStr("en='Failed to connect to Regula device! '; 
						|ru='Ошибка подключения к Regula! '; 
						|de='Fehler bei Regula verbinden! '");
						Items.GuestStatus.TextColor = WebColors.Red;
					Else
						AddHandler PBObj.OnProcessingFinished, Reader_OnProcessingFinished;
						amImageScanner = tcRegula;
						
						GuestStatus = NStr("en='Place passport first page over Regula!'; 
						|ru='Положите паспорт открытый на первой странице на Regula!'; 
						|de='Platz Pass erste Seite über Regula!'");
						Items.GuestStatus.TextColor = WebColors.Blue;	
					EndIf;				
				Except;
					GuestStatus = NStr("en='Failed to connect to Regula device! '; 
					|ru='Ошибка подключения к Regula! '; 
					|de='Fehler bei Regula verbinden! '") + Chars.LF + BriefErrorDescription(ErrorInfo());
					tcOnServer.cmWriteLogEventAtServer("AutoRecognition",,,,ErrorDescription());
					Items.GuestStatus.TextColor = WebColors.Red;
					PBObj = Undefined;
				EndTry;
			EndIf;
		Else
			If vModuleName = "tcSmartPassportBoxEngine" Then 
				GuestStatus = NStr("en='Passport box is used in another form! Please close all forms and try again to connect...'; 
				|ru='Passport box используется в другой форме! Для подключения пожалуйста закройте все формы и попробуйте еще раз...'; 
				|de='Passport-Box ist in einer anderen Form verwendet! Bitte schließen Sie alle Formen und versuchen Sie es erneut...'");
				Items.GuestStatus.TextColor = WebColors.Red;
			Else
				GuestStatus = NStr("en='Regula is used in another form! Please close all forms and try again to connect...'; 
				|ru='Regula используется в другой форме! Для подключения пожалуйста закройте все формы и попробуйте еще раз...'; 
				|de='Regula ist in einer anderen Form verwendet! Bitte schließen Sie alle Formen und versuchen Sie es erneut...'");
				Items.GuestStatus.TextColor = WebColors.Red;
			EndIf;
			PBObj = Undefined;
		EndIf;
	#ELSE
		PBObj = Undefined;
	#ENDIF
	
	// Hide group picture
	Items.GroupPicture.Visible = False;
	
	// Initialize document type
	DocumentType = "";
	EventMode = False;
	
	// Initialize guest data structure
	InitializeGuestData();
EndProcedure // OnOpen

// ----------------------------------------------------------------------------
&AtClient
Procedure Reader_OnProcessingFinished() Export	
	GetScannedData();	
EndProcedure // Reader_OnProcessingFinished

// ----------------------------------------------------------------------------
&AtClient
Procedure GetScannedData()	
	
	#If WebClient Then
		Return;
	#EndIf
		
	If DocumentType = "" Or DocumentType = "P1" Or DocumentType = "P2" Or DocumentType = "P3" Then 
		For i = 0 To PBObj.PagesCount - 1 Do
			GuestStatus = NStr("en='Passport detected...'; 
				                   |ru='Паспорт распознается...'; 
								   |de='Der Pass wird anerkannt...'");
			Items.GuestStatus.TextColor = WebColors.Blue;
			
			vDocumentTypesCandidateJSON = PBObj.CheckReaderResultJSON(9, i, 0);
			
			If ValueIsFilled(vDocumentTypesCandidateJSON) Then
				vDocumentTypesCandidateMap = JSONtoMap(vDocumentTypesCandidateJSON);
						
				vID = "";
				vType = "";
				vDescription = "";
				If vDocumentTypesCandidateMap["OneCandidate"] <> Undefined And TypeOf(vDocumentTypesCandidateMap["OneCandidate"]) = Type("Map") Then
					vOneCandidate = vDocumentTypesCandidateMap["OneCandidate"];
					If vOneCandidate["ID"] <> Undefined Then
						vID = Format(vOneCandidate["ID"], "NG="); 	
					EndIf; 
					If vOneCandidate["DocumentName"] <> Undefined Then
						vDescription = TrimAll(vOneCandidate["DocumentName"]);
						DocumentDescription = vDescription;
					EndIf;
					If vOneCandidate["FDSIDList"] <> Undefined And TypeOf(vOneCandidate["FDSIDList"]) = Type("Map") Then 
						vFDSIDList = vOneCandidate["FDSIDList"]; 
						If vFDSIDList["dType"] <> Undefined Then
							vType = Format(vFDSIDList["dType"], "NG=");
						EndIf;	
					EndIf;
					If vType = "222" Then
						DocumentType = "P1";
					ElsIf vType = "240" Then
						DocumentType  = "P2";
					ElsIf vType = "227" Or StrFind(vDescription, "Registration Stamp") > 0 Then
						DocumentType  = "P3";
					EndIf;
				EndIf;
				
				vDocumentTextJSON = PBObj.CheckReaderResultJSON(36, i, 0);		
				If ValueIsFilled(vDocumentTextJSON) Then
					vDocumentTextMap = JSONtoMap(vDocumentTextJSON);
					If vDocumentTextMap["Text"] <> Undefined And TypeOf(vDocumentTextMap["Text"]) = Type("Map") Then
						vTextMap = vDocumentTextMap["Text"];
						FillByTextField(vTextMap["fieldList"], vType, Number(1049));
					EndIf;	
				EndIf;
				
				vGraphicsJSON = PBObj.CheckReaderResultJSON(6, i, 0);
				If ValueIsFilled(vGraphicsJSON) Then
					vGraphicsMAP = JSONtoMAP(vGraphicsJSON);
					If vGraphicsMAP["DocGraphicsInfo"] <> Undefined And TypeOf(vGraphicsMAP["DocGraphicsInfo"]) = Type("Map") Then
						vDocGraphicsInfo = vGraphicsMAP["DocGraphicsInfo"];
						FillByImgFieldType(vDocGraphicsInfo["pArrayFields"], UUID);
					EndIf;	
				EndIf;
			Else
				GuestStatus = NStr("en='Regula is used in another form! Please close all forms and try again to connect...'; 
					|ru='Не удалось распознать документ! Попробуйте еще раз...'; 
					|de='Regula ist in einer anderen Form verwendet! Bitte schließen Sie alle Formen und versuchen Sie es erneut...'");
				Items.GuestStatus.TextColor = WebColors.Red	
			EndIf;
			
			vFileImageJSON = PBObj.CheckReaderResultJSON(2, i, 0);
			If ValueIsFilled(vFileImageJSON) Then
				vFileImageMAP = JSONtoMAP(vFileImageJSON);
				vPictureStorage = "";
				If vFileImageMAP["FileImageData"] <> Undefined And ValueIsFilled(vFileImageMAP["FileImageData"]) Then
					GuestData.IdentityDocumentPicture = vFileImageMAP["FileImageData"];
				EndIf;
			EndIf;
		EndDo;
		
		If Not IsBlankString(GuestData.LastName) And DocumentType = "P1" Then
			vGuestFullName = TrimAll(GuestData.LastName + " " + GuestData.FirstName + " " + GuestData.SecondName);
			If GuestFullName <> vGuestFullName Then
				GuestFullName = vGuestFullName;
			EndIf;
			
			GuestLastName = Title(GuestData.LastName);
			GuestFirstName = Title(GuestData.FirstName);
			GuestSecondName = Title(GuestData.SecondName);
			
			GuestLastNameScanned = GuestLastName;
			GuestFirstNameScanned = GuestFirstName;
			GuestSecondNameScanned = GuestSecondName;
			
			SavGuestStatus = GuestStatus;
			SavGuestStatusColor = Items.GuestStatus.TextColor;
		EndIf;
		
		GuestFullNameOnChangeAtClient()
	Else
		FillDocPictureRegula();
		// Save document picture to the data scan object
		SaveDocumentPictureAtClient();
		// Update status
		GuestStatus = NStr("en='Document picture was saved to database!'; 
							|ru='Картинка документа сохранена!'; 
							|de='Bild eines Dokuments wird gespeichert!'");
		Items.GuestStatus.TextColor = WebColors.Green;
		OpenPicture();
	EndIf;

	DocumentType = "";
EndProcedure // GetScannedData

&AtClient
// -----------------------------------------------------------------------------
Procedure FillDocPictureRegula() 
	GuestData.IdentityDocumentPicture = "";
	// Try to get document picture
	vFileImageJSON = PBObj.CheckReaderResultJSON(2, 0, 0);
	If ValueIsFilled(vFileImageJSON) Then
		vFileImageMAP = JSONtoMAP(vFileImageJSON);
		vPictureStorage = "";
		If vFileImageMAP["FileImageData"] <> Undefined And ValueIsFilled(vFileImageMAP["FileImageData"]) Then
			GuestData.IdentityDocumentPicture = vFileImageMAP["FileImageData"];
		EndIf;
	EndIf;
EndProcedure // FillDocPictureRegula

&AtClient
// -----------------------------------------------------------------------------
// Converts JSON to map
// 
// Parameters:
//  pJSONString	 - JSON formatted string  
// 
// Returns:
//   - Map - Based on JSON
// -----------------------------------------------------------------------------
Function JSONtoMap(pJSONString)
	vResult = Undefined;
	
	#If WebClient Then
		Return vResult;
	#Else	
		If NOT IsBlankString(pJSONString) Then
			vJSONReader = New JSONReader;
			vJSONReader.SetString(pJSONString);
			vResult = ReadJSON(vJSONReader, True);
		EndIf;
		
		Return vResult;
	#EndIf
EndFunction

&AtClient
// -----------------------------------------------------------------------------
Procedure FillByTextField(Val pFieldList, pType, pLanguageID)
	For Each vField In pFieldList Do 
		If vField["lcid"] <> 9999 Then 
			If vField["fieldType"] <> Undefined Then
				If (pType <> "12" And vField["fieldType"] = 2) Or (pType = "12" And vField["fieldType"] = 142) Then 
					If vField["lcid"] = pLanguageID Or vField["lcid"] = 0 Then 
						GuestData.IdentityDocumentNumber = vField["value"];
					EndIf;
				ElsIf vField["fieldType"] = 3 Then
					If vField["lcid"] = pLanguageID Or vField["lcid"] = 0 Then
						GuestData.IdentityDocumentValidToDate = FormatDate(vField["value"]); 
					EndIf;
				ElsIf vField["fieldType"] = 4 Then
					If vField["lcid"] = pLanguageID Or vField["lcid"] = 0 Then
						GuestData.IdentityDocumentIssueDate = FormatDate(vField["value"]);
					EndIf;
				ElsIf vField["fieldType"] = 5 Then
					If vField["lcid"] = pLanguageID Or vField["lcid"] = 0 Then
						GuestData.DateOfBirth = FormatDate(vField["value"]);
					EndIf;
				ElsIf vField["fieldType"] = 6 Then
					If vField["lcid"] = pLanguageID Then
						GuestData.PlaceOfBirth = FormatString(vField["value"]); 
					EndIf;
				ElsIf vField["fieldType"] = 8 Then
					If vField["lcid"] = pLanguageID Then
						GuestData.LastName = FormatString(Title(TrimAll(vField["value"])));   
					EndIf;
				ElsIf vField["fieldType"] = 9 Then
					If vField["lcid"] = pLanguageID Then
						GuestData.FirstName = FormatString(Title(TrimAll(vField["value"])));
					EndIf;
				ElsIf vField["fieldType"] = 12 Then
					If vField["lcid"] = pLanguageID Then
						GuestData.Sex = GetClientSex(vField["value"]);
					EndIf;
				ElsIf vField["fieldType"] = 17 Then
					If vField["lcid"] = pLanguageID Then
						GuestData.Address = FormatString(vField["value"]); 
					EndIf;
				ElsIf vField["fieldType"] = 24 And DocumentType = "P2" Then
					If vField["lcid"] = pLanguageID Then
						GuestData.IdentityDocumentIssuedBy = FormatString(vField["value"]); 
					EndIf;
				ElsIf vField["fieldType"] = 26 Then
					If vField["lcid"] = pLanguageID Then
						GuestData.Citizenship = vField["value"];
					EndIf;
				ElsIf vField["fieldType"] = 56 Then
					If vField["lcid"] = pLanguageID Or vField["lcid"] = 0 Then
						GuestData.IdentityDocumentSeries = vField["value"];
					EndIf;
				ElsIf vField["fieldType"] = 70 Then
					If vField["lcid"] = pLanguageID Or vField["lcid"] = 0 Then
						GuestData.AddressRegistrationDate = FormatAddressRegistrationData(vField["value"]); 
					EndIf;
				ElsIf vField["fieldType"] = 73 Then
					If vField["lcid"] = pLanguageID Or vField["lcid"] = 0 Then
						GuestData.IdentityDocumentUnitCode = vField["value"];
					EndIf;
				ElsIf vField["fieldType"] = 129 Then
					If vField["lcid"] = pLanguageID Then
						GuestData.SecondName = FormatString(Title(TrimAll(vField["value"])));        
					EndIf;
				EndIf;
			EndIf; 
		EndIf;
	EndDo;
	
	If GuestData.Property("PlaceOfBirth") And GuestData.PlaceOfBirth <> "" Then 
		vBaseCitizenship = GetCitizenship(False);
		If ValueIsFilled(vBaseCitizenship) Then
			If GuestData.Property("DateOfBirth") And GuestData.DateOfBirth < '19920101' Then
				vCitizenship = GetCitizenship(True);
				If ValueIsFilled(vCitizenship) Then
					GuestData.PlaceOfBirth = GetPlaceOfBirth(vCitizenship, , , , TrimAll(GuestData.PlaceOfBirth));	
				Else
					GuestData.PlaceOfBirth = GetPlaceOfBirth(vBaseCitizenship, , , , TrimAll(GuestData.PlaceOfBirth));
				EndIf;
			Else
				GuestData.PlaceOfBirth = GetPlaceOfBirth(vBaseCitizenship, , , , TrimAll(GuestData.PlaceOfBirth));
			EndIf;
		EndIf;
	EndIf;
	
	GuestData.IdentityDocumentType = GetRussianPassportType();
	
	If GuestData.Property("IdentityDocumentNumber") And GuestData.Property("IdentityDocumentSeries") Then
		If ValueIsFilled(GuestData.IdentityDocumentSeries) And GuestData.IdentityDocumentSeries = Left(GuestData.IdentityDocumentNumber, 4) Then
			GuestData.IdentityDocumentNumber = Right(GuestData.IdentityDocumentNumber, StrLen(GuestData.IdentityDocumentNumber) - 4);	
		EndIf;
	EndIf;  
	If GuestData.Property("IdentityDocumentUnitCode") And ValueIsFilled(GuestData.IdentityDocumentUnitCode) And 
	   StrLen(GuestData.IdentityDocumentUnitCode) = 6 And StrFind(GuestData.IdentityDocumentUnitCode, "-") = 0 Then
		GuestData.IdentityDocumentUnitCode = Left(GuestData.IdentityDocumentUnitCode, 3) + "-" + Right(GuestData.IdentityDocumentUnitCode, 3);		
	EndIf;
EndProcedure // FillByTextField

// -----------------------------------------------------------------------------
Function FormatAddressRegistrationData(pDateString)
  vResult = Undefined;
  
  If ValueIsFilled(pDateString) Then
    Try
      vYear = Right(pDateString, 4);
      vDay = Left(pDateString, 2);
      
      vTextMonthProc = StrReplace(pDateString, vYear, "");
      vTextMonth = TrimAll(StrReplace(vTextMonthProc, vDay, ""));
      
      vMonthNumber = "";
      
      If vTextMonth = "ЯНВАРЯ" Then
        vMonthNumber = "01";
      ElsIf vTextMonth = "ФЕВРАЛЯ" Then
        vMonthNumber = "02";
      ElsIf vTextMonth = "МАРТА" Then
        vMonthNumber = "03";
      ElsIf vTextMonth = "АПРЕЛЯ" Then
        vMonthNumber = "04";
      ElsIf vTextMonth = "МАЯ" Then
        vMonthNumber = "05";
      ElsIf vTextMonth = "ИЮНЯ" Then
        vMonthNumber = "06";
      ElsIf vTextMonth = "ИЮЛЯ" Then
        vMonthNumber = "07";
      ElsIf vTextMonth = "АВГУСТА" Then
        vMonthNumber = "08";
      ElsIf vTextMonth = "СЕНТЯБРЯ" Then
        vMonthNumber = "09";
      ElsIf vTextMonth = "ОКТЯБРЯ" Then
        vMonthNumber = "10";
      ElsIf vTextMonth = "НОЯБРЯ" Then
        vMonthNumber = "11";
      ElsIf vTextMonth = "ДЕКАБРЯ" Then
        vMonthNumber = "12";
      EndIf;
      
      vResult = Date(TrimAll(vYear + vMonthNumber + vDay));
    Except
      vResult = Undefined;
    EndTry;
  EndIf;
  
  Return vResult;        
EndFunction // FormatAddressRegistrationData

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetCitizenship(pIsUSSR)
	If pIsUSSR Then
		Return Catalogs.Countries.FindByCode(810, False);
	Else
		Return Catalogs.Countries.FindByCode(643, False);
	EndIf;
EndFunction // GetUSSR

// ----------------------------------------------------------------------------
&AtClient
Function GetPlaceOfBirth(pCountry = Undefined, pPostCode = Undefined, pRegion = Undefined, pArea = Undefined, pCity = Undefined)
	vPlaceOfBirth = "";
	If ValueIsFilled(pCountry) Then
		vPlaceOfBirth = vPlaceOfBirth + TrimAll(pCountry);	
	EndIf;
	vPlaceOfBirth = vPlaceOfBirth + ", ";
	If ValueIsFilled(pPostCode) Then
		vPlaceOfBirth = vPlaceOfBirth + TrimAll(pPostCode);	
	EndIf;
	vPlaceOfBirth = vPlaceOfBirth + ", ";
	If ValueIsFilled(pRegion) Then
		vPlaceOfBirth = vPlaceOfBirth + TrimAll(pRegion);	
	EndIf;
	vPlaceOfBirth = vPlaceOfBirth + ", ";
	If ValueIsFilled(pArea) Then
		vPlaceOfBirth = vPlaceOfBirth + TrimAll(pArea);	
	EndIf;
	vPlaceOfBirth = vPlaceOfBirth + ", ";
	If ValueIsFilled(pCity) Then
		vPlaceOfBirth = vPlaceOfBirth + TrimAll(pCity);	
	EndIf;
	vPlaceOfBirth = vPlaceOfBirth + ", ";
	Return vPlaceOfBirth;
EndFunction // GetPlaceOfBirth

&AtClient
// -----------------------------------------------------------------------------
Procedure FillByImgFieldType(Val pFieldList, Val pStorageUUID)
	For Each vField In pFieldList Do 
		If vField["FieldType"] <> Undefined And vField["image"] <> Undefined Then
			vImageM = vField["image"];
			If vImageM["image"] <> Undefined And ValueIsFilled(vImageM["image"]) Then
				If vField["FieldType"] = 201 Then
					GuestData.Photo = vImageM["image"];
				ElsIf vField["FieldType"] = 204 Then
					GuestData.Signature = vImageM["image"];
				EndIf; 
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillByImgFieldType

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
Function FormatString(pStr) 
	vStr = StrReplace(pStr, "^", " ");
	vStr = StrReplace(vStr, Chars.LF, " ");
	vStr = StrReplace(vStr, Chars.CR, " ");
	vStr = StrReplace(vStr, "  ", " ");
	vStr = StrReplace(vStr, "  ", " ");
	Return vStr; 
EndFunction // StringFormat

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose()
	If PBObj <> Undefined Then
		If amImageScanner = tcSmartPassportBoxEngine Then
			If PBObj.StopAutoCapturePassport() < 0 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to stop auto capture! '; 
																|ru='Не удалось остановить автоматическое распознавание! '; 
																|de='Fehlgeschlagen Auto-Capture zu stoppen! '") + 
				PBObj.GetLastError().ErrMessage, MessageStatus.Information);
			EndIf;
			If PBObj.CloseCaptureDevice() < 0 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to disconnect from passport box! '; 
																|ru='Не удалось отключиться от Passport box! '; 
																|de='Fehler beim Passport-Box zu trennen! '") + 
				PBObj.GetLastError().ErrMessage, MessageStatus.Information);
			EndIf;
		EndIf;
		Try
			PBObj = Undefined;
		Except
		EndTry;
	EndIf;
	amImageScanner = Undefined;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	EventMode = True;
	
	// Actions in the document
	// Try to find client identification card with such Id
	vCard = GetClientIdentificationCardById(vEventData.DeviceData);
	If ValueIsFilled(vCard) Then
		vClient = GetClient(vCard);
		If ValueIsFilled(vClient) Then
			vFName = GetFName(vCard);
			GuestFullName = vFName;
		Else
			ShowMessageBox(,NStr("en='Card do not have client specified!';ru='У карты не указан клиент!';de='Bei der Karte sind weder Kunde angegeben!'"), 3);
		EndIf;
	Else
		// Try to find discount card with such Id
		vDiscountCard = GetDiscountCardById(vEventData.DeviceData);
		If ValueIsFilled(vDiscountCard) Then
			vClient = GetClient(vCard);
			If ValueIsFilled(vClient) Then
				vFName = GetFName(vCard);
				
				GuestFullName = vFName;
			EndIf;
		EndIf;
	EndIf;
	
	ParseGuestFullName();
	If PBObj <> Undefined Then
		// Try to get document picture
		PBObj.TakeSnapshot();
		GuestData.IdentityDocumentPicture = PBObj.GetSnapshotBase64();
	EndIf;
	GuestFullNameOnChangeAtClient();
	SavGuestStatus = GuestStatus;
	SavGuestStatusColor = Items.GuestStatus.TextColor;
	
	EventMode = False;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestFullNameOnChange(pItem)
	EventMode = True;
	ParseGuestFullName();
	If PBObj <> Undefined Then
		If amImageScanner = tcSmartPassportBoxEngine Then
			// Try to get document picture
			PBObj.TakeSnapshot();
			GuestData.IdentityDocumentPicture = PBObj.GetSnapshotBase64();
		EndIf;
	EndIf;
	GuestFullNameOnChangeAtClient();
	SavGuestStatus = GuestStatus;
	SavGuestStatusColor = Items.GuestStatus.TextColor;
	EventMode = False;
EndProcedure // GuestFullNameOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodOfStayClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(Reservation) Then
		If TypeOf(Reservation) = Type("DocumentRef.Reservation") Then
			// Open reservation form
			OpenForm("Document.Reservation.ObjectForm", New Structure("Key", Reservation), , Reservation);
		Else
			// Open reservation form
			OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", Reservation), , Reservation);
		EndIf;
	Else
		GuestStatus = NStr("en='Guest reservation was NOT found!.'; 
		                   |ru='Бронь гостя НЕ найдена!'; 
						   |de='Gast Reservierung NICHT gefunden!'");
		Items.GuestStatus.TextColor = WebColors.Red;
		Items.CheckInGuest.Enabled = False;
	EndIf;
EndProcedure // PeriodOfStayClick

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomGuestsOnActivateRow(pItem)
	If pItem.CurrentRow <> Undefined Then
		GuestRowID = pItem.CurrentRow;
		If Not EventMode Then
			GuestFullName = TrimAll(pItem.CurrentData.GuestFullName);
		EndIf;
	InitializeGuestData();
	EndIf;
EndProcedure // RoomGuestsOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomGuestsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If EventMode Then
		Return;
	EndIf;
	PassportWasRecognized = False;
	LastEventTime = '00010101';
	DetachIdleHandler("CheckRecognitionTimeout");
	vScanCmd = NStr("en='scan'; ru='сканировать'; de='scan'");
	vPictureCmd = NStr("en='picture'; ru='картинка'; de='bild'");
	
	If pSelectedRow >= 0 Then
		If GuestRowID <> pSelectedRow Then
			GuestRowID = pSelectedRow;
		EndIf;
		vRow = RoomGuests.FindByID(pSelectedRow);
		If vRow <> Undefined Then
			If pField.Name = "RoomGuestsGuestFullName" Then
				If ValueIsFilled(vRow.Guest) Then
					OpenForm("Catalog.Clients.ObjectForm", New Structure("Key", vRow.Guest), , vRow.Guest);
				EndIf;
			ElsIf pField.Name = "RoomGuestsPassport1Photo" Then 
				DocumentType = "P1";
				If vRow.Passport1Photo = vScanCmd Then
					If amImageScanner = tcSmartPassportBoxEngine Then
						ScanDocument();
					EndIf;
				Else
					OpenPicture();
				EndIf;
			ElsIf pField.Name = "RoomGuestsPassport2Photo" Then 
				DocumentType = "P2";
				If vRow.Passport2Photo = vScanCmd Then
					If amImageScanner = tcSmartPassportBoxEngine Then
						ScanDocument();
					EndIf;
				Else
					OpenPicture();
				EndIf;
			ElsIf pField.Name = "RoomGuestsPassport3Photo" Then 
				DocumentType = "P3";
				If vRow.Passport3Photo = vScanCmd Then
					If amImageScanner = tcSmartPassportBoxEngine Then
						ScanDocument();
					EndIf;
				Else
					OpenPicture();
				EndIf;
			ElsIf pField.Name = "RoomGuestsBirthCertificate" Then 
				DocumentType = "BC";
				If vRow.BirthCertificate = vScanCmd Then
					If amImageScanner = tcSmartPassportBoxEngine Then
						ScanDocument();
					EndIf;
				Else
					OpenPicture();
				EndIf;
			ElsIf pField.Name = "RoomGuestsMigrationCard" Then 
				DocumentType = "MC";
				If vRow.MigrationCard = vScanCmd Then
					If amImageScanner = tcSmartPassportBoxEngine Then
						ScanDocument();
					EndIf;
				Else
					OpenPicture();
				EndIf;
			ElsIf pField.Name = "RoomGuestsVisum" Then 
				DocumentType = "VS";
				If vRow.Visum = vScanCmd Then
					If amImageScanner = tcSmartPassportBoxEngine Then
						ScanDocument();
					EndIf;
				Else
					OpenPicture();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // RoomGuestsSelection

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SearchByGuestFullName(pCommand)
	EventMode = True;
	ParseGuestFullName();
	If PBObj <> Undefined Then
		If amImageScanner = tcSmartPassportBoxEngine Then
			// Try to get document picture
			PBObj.TakeSnapshot();
			GuestData.IdentityDocumentPicture = PBObj.GetSnapshotBase64();
		EndIf;
	EndIf;
	
	GuestFullNameOnChangeAtClient();
	SavGuestStatus = GuestStatus;
	SavGuestStatusColor = Items.GuestStatus.TextColor;
	EventMode = False;
EndProcedure // SearchByGuestFullName

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInGuest(Command)
	If ValueIsFilled(Reservation) Then
		If TypeOf(Reservation) = Type("DocumentRef.Reservation") Then
			vHotel = tcOnServer.cmGetAttributeByRef(Reservation, "Hotel");
			vHotelAccountingDate = '00010101';
			If ValueIsFilled(vHotel) Then
				vHotelAccountingDate =  tcOnServer.cmGetAttributeByRef(vHotel, "AccountingDate");
			EndIf;
			If Not ValueIsFilled(vHotelAccountingDate) Then
				vHotelAccountingDate = BegOfDay(CurrentDate());
			EndIf;
			// Start check-in
			vResult = CheckInAtServer(Reservation, False);
			If ValueIsFilled(vResult) Then
				If vResult = "DoQueryBox" Then
					ShowMessageBox(, NStr("en='You are checking-in by inactive reservation!';ru='Селите по не активной брони!';de='Sie bringen nicht nach einer aktiven Reservierung unter!'"));
					Return;
				ElsIf TypeOf(vResult) = Type("ValueList") Then
					vQuestionWasAsked = False;
					vSelResList = New ValueList;
					vErrList    = New ValueList;
					vSkip = False;
					For Each vItem In vResult Do
						vCheckInDate = tcOnServer.cmGetAttributeByRef(vItem.Value, "CheckInDate");
						If vHotelAccountingDate <> BegOfDay(vCheckInDate) Then
							vErrList.Add(vItem.Value);
							Continue;
						EndIf;
						vSelResList.Add(vItem.Value);
					EndDo; 
					If vErrList.Count()>0 Then
						vQueryText = NStr("en='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "! Skip such reservations?';
						                  |de='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "! Skip such reservations?';
						                  |ru='В выбранном списке брони есть документы с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "! Отменить поселение по такой брони?'");
						
						ShowQueryBox(New NotifyDescription("AfterAnswer", ThisForm,New Structure("vSelResList,vErrList",vSelResList,vErrList)), vQueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
					Else 
						CheckInEndPart(vSelResList,vErrList);
					EndIf;
				ElsIf TypeOf(vResult)=Type("Structure") Then
					#IF ThickClientOrdinaryApplication THEN
						If cmIsSimpleMode() Then
							// APDEX
							vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
							APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

							// Open new accommodation and fill group table from the given list
							OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()));
						Else
							// Open new accommodation and fill group table from the given list
							vDocObj = Documents.Accommodation.CreateDocument();
							vDocObj.Fill(Reservation);
							// Check should we turn "Fix reservation conditions" flag on 
							cmCheckFixReservationConditionsAtCheckIn(vDocObj, Reservation);
							// Get document form
							vFrm = vDocObj.GetForm();
							vFrm.SelDocsList = vResult.ValueList;
							If Not vFrm.IsOpen() Then
								vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
							EndIf;
							vFrm.Open();
							// Check current reservation messages
							If cmGetNumberOfMessagesForObject(Reservation) > 0 Then
								// Show reservation messages
								vMsgsFrm = DataProcessors.Messages.GetForm();
								vMsgsFrm.ByObject = Reservation;
								vMsgsFrm.Open();
							EndIf;
						EndIf;
					#ELSE
						// APDEX
						vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
						APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

						// Open new accommodation and fill group table from the given list
						OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()));
					#ENDIF
				Else
					ShowMessageBox(,vResult);
				EndIf;
			EndIf;
		Else
			// APDEX
			vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
			APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

			// Open accommodation form
			OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", Reservation), , Reservation);
		EndIf;
	Else
		GuestStatus = NStr("en='Guest reservation was NOT found!.'; 
		                   |ru='Бронь гостя НЕ найдена!'; 
						   |de='Gast Reservierung NICHT gefunden!'");
		Items.GuestStatus.TextColor = WebColors.Red;
		Items.CheckInGuest.Enabled = False;
	EndIf;
EndProcedure // CheckInGuest

// -----------------------------------------------------------------------------
&AtClient
Procedure NextReservation(Command)
	DocPicture = "";
	Items.GroupPicture.Visible = False;
	PassportWasRecognized = False;
	Items.CheckInGuest.Enabled = False;
	RoomGuests.Clear();
	GuestRowID = -1;
	GuestGroup = Undefined;
	Reservation = Undefined;
	PeriodOfStay = "";
	GuestFullName = "";
	GuestFirstName = "";
	GuestLastName = "";
	GuestSecondName = "";
	GuestLastNameScanned = "";
	GuestFirstNameScanned = "";
	GuestSecondNameScanned = "";
	GuestData = Undefined;
	DocumentType = "P1";
	If amImageScanner = tcSmartPassportBoxEngine Then
		If PBObj <> Undefined Then
			GuestStatus = NStr("en='Place passport first page over Passport box!'; 
			                   |ru='Положите паспорт открытый на первой странице на Passport Box!'; 
							   |de='Platz Pass erste Seite über Passport-Box!'");
			Items.GuestStatus.TextColor = WebColors.Blue;
		Else
			GuestStatus = NStr("en='Failed to connect to Passport box device!'; 
			                   |ru='Ошибка подключения к Passport box!'; 
							   |de='Fehler bei Passport-Box verbinden!'");
			Items.GuestStatus.TextColor = WebColors.Red;
		EndIf;
	Else
		If PBObj <> Undefined Then
			GuestStatus = NStr("en='Place passport first page over Regula!'; 
			                   |ru='Положите паспорт открытый на первой странице на Regula!'; 
							   |de='Platz Pass erste Seite über Regula!'");
			Items.GuestStatus.TextColor = WebColors.Blue;
		Else
			GuestStatus = NStr("en='Failed to connect to Regula device!'; 
			                   |ru='Ошибка подключения к Regula!'; 
							   |de='Fehler bei Regula verbinden!'");
			Items.GuestStatus.TextColor = WebColors.Red;
		EndIf;
	EndIf;
	SavGuestStatus = GuestStatus;
	SavGuestStatusColor = Items.GuestStatus.TextColor;
EndProcedure // NextReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearPicture(pCommand)
	vScanCmd = NStr("en='scan'; ru='сканировать'; de='scan'");
	If GuestRowID >= 0 And Not IsBlankString(DocumentType) Then
		vRowData = RoomGuests.FindByID(GuestRowID);
		If DocumentType = "P1" Then
			vRowData.Passport1Photo = vScanCmd;
		ElsIf DocumentType = "P2" Then
			vRowData.Passport2Photo = vScanCmd;
		ElsIf DocumentType = "P3" Then
			vRowData.Passport3Photo = vScanCmd;
		ElsIf DocumentType = "BC" Then
			vRowData.BirthCertificate = vScanCmd;
		ElsIf DocumentType = "MC" Then
			vRowData.MigrationCard = vScanCmd;
		ElsIf DocumentType = "VS" Then
			vRowData.Visum = vScanCmd;
		EndIf;
		If ValueIsFilled(vRowData.GuestDataScans) Then
			ClearPictureAtServer(vRowData.GuestDataScans);
		EndIf;
	EndIf;
	HidePicture(pCommand);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HidePicture(pCommand)
	DocPicture = "";
	Items.GroupPicture.Visible = False;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetConnectionParameters()
	vConnParams = Undefined;
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWstn = SessionParameters.CurrentWorkstation;
		If vWstn.HasConnectionToImagesScanner And ValueIsFilled(vWstn.ImagesScannerConnectionParameters) Then
			vWstnConnParams = vWstn.ImagesScannerConnectionParameters;
			If vWstnConnParams.ImageScannerDriver = Enums.ImageScannerDrivers.SmartPassportBoxEngine Then
				vConnParams = vWstnConnParams;
			EndIf;
		EndIf;
	EndIf;
	Return vConnParams;
EndFunction // GetConnectionParameters

// -----------------------------------------------------------------------------
&AtClient
Procedure InitializeGuestData()
	GuestData = New Structure("LastName, FirstName, SecondName, Sex, Address, DateOfBirth, PlaceOfBirth, IdentityDocumentType, IdentityDocumentSeries, AddressRegistrationDate, IdentityDocumentNumber, IdentityDocumentUnitCode, IdentityDocumentIssuedBy, IdentityDocumentIssueDate, IdentityDocumentValidToDate, Citizenship, Photo, Signature, IdentityDocumentPicture", 
	                          "", "", "", Undefined, "", '00010101', "", Undefined, "", '00010101', "", "", "", '00010101', '00010101', Undefined, "", "", "", "", "");
EndProcedure // InitializeGuestData

// -----------------------------------------------------------------------------
&AtServerNoContext
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
&AtClient
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
EndFunction // GetDateFromString

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetIssuedBy(pUnitCode)
	vQryRes = cmGetFMSRecord(pUnitCode, True).Choose();
	While vQryRes.Next() Do
		Return TrimAll(vQryRes.Description);
	EndDo;
	Return "";
EndFunction // GetIssuedBy

// -----------------------------------------------------------------------------
&AtClient
Procedure FillGuestData(pData, pIdentityDocumentType, pIsFromMRZ = False)
	InitializeGuestData();
	// Fill from scan results
	If Not pIsFromMRZ Then
		If pData.Property("IsSurnameAccepted") And pData.IsSurnameAccepted Then
			GuestData.LastName = Title(pData.Surname);
		EndIf;
		If pData.Property("IsNameAccepted") And pData.IsNameAccepted Then
			GuestData.FirstName = Title(pData.Name);
		EndIf;
		If pData.Property("IsPatronymicAccepted") And pData.IsPatronymicAccepted Then
			GuestData.SecondName = Title(pData.Patronymic);
		EndIf;
		If pData.Property("IsBirthdateAccepted") And pData.IsBirthdateAccepted Then
			GuestData.DateOfBirth = GetDateFromString(pData.BirthDate);
		EndIf;
		If pData.Property("IsGenderAccepted") And pData.IsGenderAccepted Then
			GuestData.Sex = GetClientSex(pData.Gender);
		EndIf;
		If pData.Property("IsAuthority_codeAccepted") And pData.IsAuthority_codeAccepted Then
			GuestData.IdentityDocumentType = pIdentityDocumentType;
		EndIf;
		If pData.Property("IsSeriesAccepted") And pData.IsSeriesAccepted Then
			GuestData.IdentityDocumentSeries = StrReplace(pData.Series, " ", "");
		EndIf;
		If pData.Property("IsNumberAccepted") And pData.IsNumberAccepted Then
			GuestData.IdentityDocumentNumber = StrReplace(pData.Number, " ", "");
		EndIf;
		vSkipAuthority = False;
		If pData.Property("IsAuthority_codeAccepted") And pData.IsAuthority_codeAccepted Then
			GuestData.IdentityDocumentUnitCode = TrimAll(pData.authority_code);
			If Not IsBlankString(GuestData.IdentityDocumentUnitCode) Then
				GuestData.IdentityDocumentIssuedBy = GetIssuedBy(TrimAll(GuestData.IdentityDocumentUnitCode));
				If Not IsBlankString(GuestData.IdentityDocumentIssuedBy) Then
					vSkipAuthority = True;
				EndIf;
			EndIf;
		EndIf;
		If Not vSkipAuthority Then
			If pData.Property("IsAuthorityAccepted") And pData.IsAuthorityAccepted Then
				GuestData.IdentityDocumentIssuedBy = TrimAll(pData.Authority);
			EndIf;
		EndIf;
		If pData.Property("IsIssue_DateAccepted") And pData.IsIssue_DateAccepted Then
			GuestData.IdentityDocumentIssueDate = GetDateFromString(pData.issue_date);
		EndIf;
		If pData.Property("IsBirthPlaceAccepted") And pData.IsBirthPlaceAccepted Then
			GuestData.PlaceOfBirth = TrimAll(pData.BirthPlace);
		EndIf;
		// Try to get passport photo
		If pData.Property("Photo") Then
			GuestData.Photo = pData.Photo;
		EndIf;
		// Try to get passport signature
		If pData.Property("Signature") Then
			GuestData.Signature = pData.Signature;
		EndIf;
		// Try to get passport picture
		GuestData.IdentityDocumentPicture = pData.Full_Document;
	Else
		If pData.Property("IsLast_name_mrzAccepted") And pData.IsLast_name_mrzAccepted Then
			GuestData.LastName = Title(pData.Last_name_mrz);
		EndIf;
		If pData.Property("IsFirst_Name_mrzAccepted") And pData.IsFirst_Name_mrzAccepted Then
			GuestData.FirstName = Title(pData.First_Name_mrz);
		EndIf;
		GuestData.SecondName = "";
		If pData.Property("IsBirth_date_mrzAccepted") And pData.IsBirth_date_mrzAccepted Then
			GuestData.DateOfBirth = GetDateFromString(pData.birth_date_mrz);
		EndIf;
		If pData.Property("IsGender_mrzAccepted") And pData.IsGender_mrzAccepted Then
			GuestData.Sex = GetClientSex(pData.gender_mrz);
		EndIf;
		If pData.Property("IsSeries_mrzAccepted") And pData.IsSeries_mrzAccepted Then
			GuestData.IdentityDocumentSeries = StrReplace(pData.series_mrz, " ", "");
		EndIf;
		If pData.Property("IsNumber_mrzAccepted") And pData.IsNumber_mrzAccepted Then
			GuestData.IdentityDocumentNumber = StrReplace(pData.number_mrz, " ", "");
		EndIf;
		If pData.Property("IsIssuer_mrzAccepted") And pData.IsIssuer_mrzAccepted Then
			GuestData.IdentityDocumentIssuedBy = TrimAll(GuestData.issuer_mrz);
		EndIf;
		If pData.Property("IsIssue_date_mrzAccepted") And pData.IsIssue_date_mrzAccepted Then
			GuestData.IdentityDocumentIssueDate = GetDateFromString(pData.issue_date_mrz);
		EndIf;
		If pData.Property("IsExpiry_date_mrzAccepted") And pData.IsExpiry_date_mrzAccepted Then
			GuestData.IdentityDocumentValidToDate = GetDateFromString(pData.expiry_date_mrz);
		EndIf;
		If pData.Property("IsNationality_mrzAccepted") And pData.IsNationality_mrzAccepted And GuestData.Property("Citizenship") Then
			GuestData.Citizenship = tcOnServer.GetCountryByCode(TrimAll(pData.nationality_mrz));
		EndIf;
		// Try to get passport picture
		GuestData.IdentityDocumentPicture = pData.Full_Document;
	EndIf;
EndProcedure // FillGuestData

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CreateNewGuest(pGuestData)
	// Check if this guest already exists
	vClientRef = Undefined;
	If Not IsBlankString(pGuestData.LastName) And Not IsBlankString(pGuestData.FirstName) And Not IsBlankString(pGuestData.SecondName) And ValueIsFilled(pGuestData.DateOfBirth) Then
		vClientRef = cmGetClientByFullnameAndBirthDate(pGuestData.LastName, pGuestData.FirstName, pGuestData.SecondName, pGuestData.DateOfBirth);
	EndIf;
	If ValueIsFilled(vClientRef) Then
		Return UpdateGuest(vClientRef, pGuestData, True);
	Else
		vGuestObj = Catalogs.Clients.CreateItem();
		vGuestObj.pmFillAttributesWithDefaultValues();
		FillPropertyValues(vGuestObj, pGuestData, , "Photo, Signature");
		// Photo
		If Not IsBlankString(pGuestData.Photo) Then
			vPhoto = New Picture(Base64Value(pGuestData.Photo));
			vGuestObj.Photo = New ValueStorage(vPhoto);
		EndIf;
		// Signature
		If Not IsBlankString(pGuestData.Signature) Then
			vSignature = New Picture(Base64Value(pGuestData.Signature));
			vGuestObj.Signature = New ValueStorage(vSignature);
		EndIf;
		// Write
		vGuestObj.Write();
		vGuestObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		Return vGuestObj.Ref;
	EndIf;
EndFunction // CreateNewGuest

// -----------------------------------------------------------------------------
&AtServerNoContext
Function UpdateGuest(Val pGuest, pGuestData, pSkipSearch = False)
	If Not pSkipSearch Then
		vClientRef = Undefined;
		If Not IsBlankString(pGuestData.LastName) And Not IsBlankString(pGuestData.FirstName) And Not IsBlankString(pGuestData.SecondName) And ValueIsFilled(pGuestData.DateOfBirth) Then
			vClientRef = cmGetClientByFullnameAndBirthDate(pGuestData.LastName, pGuestData.FirstName, pGuestData.SecondName, pGuestData.DateOfBirth);
		EndIf;
		If ValueIsFilled(vClientRef) And pGuest <> vClientRef Then
			pGuest = vClientRef;
		EndIf;
	EndIf;
	vGuestObj = pGuest.GetObject();
	If Not IsBlankString(pGuestData.LastName) Then
		vGuestObj.LastName = Title(pGuestData.LastName);
	EndIf;
	If Not IsBlankString(pGuestData.FirstName) Then
		vGuestObj.FirstName = Title(pGuestData.FirstName);
	EndIf;
	If Not IsBlankString(pGuestData.SecondName) Then
		vGuestObj.SecondName = Title(pGuestData.SecondName);
	EndIf;
	If ValueIsFilled(pGuestData.DateOfBirth) Then
		vGuestObj.DateOfBirth = pGuestData.DateOfBirth;
	EndIf;
	If ValueIsFilled(pGuestData.Sex) Then
		vGuestObj.Sex = pGuestData.Sex;
	EndIf;
	If Not IsBlankString(pGuestData.Address) Then
		vGuestObj.Address = TrimAll(pGuestData.Address);
	EndIf;
	If ValueIsFilled(pGuestData.IdentityDocumentType) Then
		vGuestObj.IdentityDocumentType = pGuestData.IdentityDocumentType;
	EndIf;
	If Not IsBlankString(pGuestData.IdentityDocumentSeries) Then
		vGuestObj.IdentityDocumentSeries = TrimAll(pGuestData.IdentityDocumentSeries);
	EndIf;
	If Not IsBlankString(pGuestData.AddressRegistrationDate) Then
		vGuestObj.AddressRegistrationDate = pGuestData.AddressRegistrationDate;
	EndIf;
	If Not IsBlankString(pGuestData.IdentityDocumentNumber) Then
		vGuestObj.IdentityDocumentNumber = TrimAll(pGuestData.IdentityDocumentNumber);
	EndIf;
	If Not IsBlankString(pGuestData.IdentityDocumentUnitCode) Then
		vGuestObj.IdentityDocumentUnitCode = TrimAll(pGuestData.IdentityDocumentUnitCode);
	EndIf;
	If Not IsBlankString(pGuestData.IdentityDocumentIssuedBy) Then
		vGuestObj.IdentityDocumentIssuedBy = TrimAll(pGuestData.IdentityDocumentIssuedBy);
	EndIf;
	If ValueIsFilled(pGuestData.IdentityDocumentIssueDate) Then
		vGuestObj.IdentityDocumentIssueDate = pGuestData.IdentityDocumentIssueDate;
	EndIf;
	If Not IsBlankString(pGuestData.PlaceOfBirth) Then
		vGuestObj.PlaceOfBirth = TrimAll(pGuestData.PlaceOfBirth);
	EndIf;
	// Photo
	If Not IsBlankString(pGuestData.Photo) Then
		vPhoto = New Picture(Base64Value(pGuestData.Photo));
		vGuestObj.Photo = New ValueStorage(vPhoto);
	EndIf;
	// Signature
	If Not IsBlankString(pGuestData.Signature) Then
		vSignature = New Picture(Base64Value(pGuestData.Signature));
		vGuestObj.Signature = New ValueStorage(vSignature);
	EndIf;
	// Write
	vGuestObj.Write();
	vGuestObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	Return vGuestObj.Ref;
EndFunction // UpdateGuest

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure UpdateDataScansDocument(pDocObj, pGuestData) 
	If Not IsBlankString(pGuestData.LastName) Then
		pDocObj.LastName = Title(pGuestData.LastName);
	EndIf;
	If Not IsBlankString(pGuestData.FirstName) Then
		pDocObj.FirstName = Title(pGuestData.FirstName);
	EndIf;
	If Not IsBlankString(pGuestData.SecondName) Then
		pDocObj.SecondName = Title(pGuestData.SecondName);
	EndIf;
	If ValueIsFilled(pGuestData.DateOfBirth) Then
		pDocObj.DateOfBirth = pGuestData.DateOfBirth;
	EndIf;
	If ValueIsFilled(pGuestData.Sex) Then
		pDocObj.Sex = pGuestData.Sex;
	EndIf;
	If ValueIsFilled(pGuestData.Address) Then
		pDocObj.Address = TrimAll(pGuestData.Address);
	EndIf;
	If ValueIsFilled(pGuestData.IdentityDocumentType) Then
		pDocObj.IdentityDocumentType = pGuestData.IdentityDocumentType;
	EndIf;
	If Not IsBlankString(pGuestData.IdentityDocumentSeries) Then
		pDocObj.IdentityDocumentSeries = TrimAll(pGuestData.IdentityDocumentSeries);
	EndIf;
	If Not IsBlankString(pGuestData.AddressRegistrationDate) Then
		pDocObj.AddressRegistrationDate = pGuestData.AddressRegistrationDate;
	EndIf;
	If Not IsBlankString(pGuestData.IdentityDocumentNumber) Then
		pDocObj.IdentityDocumentNumber = TrimAll(pGuestData.IdentityDocumentNumber);
	EndIf;
	If Not IsBlankString(pGuestData.IdentityDocumentUnitCode) Then
		pDocObj.IdentityDocumentUnitCode = TrimAll(pGuestData.IdentityDocumentUnitCode);
	EndIf;
	If Not IsBlankString(pGuestData.IdentityDocumentIssuedBy) Then
		pDocObj.IdentityDocumentIssuedBy = TrimAll(pGuestData.IdentityDocumentIssuedBy);
	EndIf;
	If ValueIsFilled(pGuestData.IdentityDocumentIssueDate) Then
		pDocObj.IdentityDocumentIssueDate = pGuestData.IdentityDocumentIssueDate;
	EndIf;
	If Not IsBlankString(pGuestData.PlaceOfBirth) Then
		pDocObj.PlaceOfBirth = TrimAll(pGuestData.PlaceOfBirth);
	EndIf;
	// Photo
	If Not IsBlankString(pGuestData.Photo) Then
		vPhoto = New Picture(Base64Value(pGuestData.Photo));
		pDocObj.Photo = New ValueStorage(vPhoto);
	EndIf;
	// Signature
	If Not IsBlankString(pGuestData.Signature) Then
		vSignature = New Picture(Base64Value(pGuestData.Signature));
		pDocObj.Signature = New ValueStorage(vSignature);
	EndIf;
EndProcedure // UpdateDataScansDocument

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure SavePicture(pDocObj, pPictureType, pPictureString, pDocDescription = Undefined)
	vTypeRow = Undefined;
	If pPictureType = "P1" Or pPictureType = "P2" Then
		vIdentityDocumentType = GetRussianPassportType();
		If ValueIsFilled(vIdentityDocumentType) Then
			vScanConfigsForPassport = GetScanConfigurationsForIdentityDocumentType(vIdentityDocumentType);
			If vScanConfigsForPassport.Count() > 0 Then
				If pPictureType = "P1" Then
					pScanConfiguration = vScanConfigsForPassport.Get(0).ScanConfiguration;
				ElsIf pPictureType = "P2" Then
					If vScanConfigsForPassport.Count() > 1 Then
						pScanConfiguration = vScanConfigsForPassport.Get(1).ScanConfiguration;
					Else
						pScanConfiguration = vScanConfigsForPassport.Get(0).ScanConfiguration;
					EndIf;
				Else
					pScanConfiguration = vScanConfigsForPassport.Get(vIdentityDocumentType.Count() - 1).ScanConfiguration;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
		
	For Each vRow In pDocObj.ScanPictures Do
		If TrimAll(vRow.Remarks) = pPictureType Then
			vTypeRow = vRow;
			Break;
		ElsIf ValueIsFilled(vRow.ScanConfiguration) And vRow.ScanConfiguration = pScanConfiguration Then
			vTypeRow = vRow;
			Break;
		EndIf;
	EndDo;
	If vTypeRow = Undefined Then
		vTypeRow = pDocObj.ScanPictures.Add();
		vTypeRow.Remarks = pPictureType;
		If ValueIsFilled(pDocDescription) Then
			vTypeRow.Description = pDocDescription;
		EndIf;
		vTypeRow.ScanConfiguration = pScanConfiguration;
	EndIf;					
	vTypeRow.ScanPicture = New ValueStorage(New Picture(Base64Value(pPictureString)));
EndProcedure // SavePicture

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDataScansDocument(pGuestGroup, pGuest)
	vDocRef = Documents.ClientDataScans.EmptyRef();
	If ValueIsFilled(pGuest) And ValueIsFilled(pGuestGroup) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ClientDataScans.Ref
		|FROM
		|	Document.ClientDataScans AS ClientDataScans
		|WHERE
		|	ClientDataScans.Posted
		|	AND ClientDataScans.GuestGroup = &qGuestGroup
		|	AND ClientDataScans.Guest = &qGuest
		|
		|ORDER BY
		|	ClientDataScans.PointInTime DESC";
		vQry.SetParameter("qGuestGroup", pGuestGroup);
		vQry.SetParameter("qGuest", pGuest);
		vDocs = vQry.Execute().Unload();
		For Each vDocsRow In vDocs Do
			vDocRef = vDocsRow.Ref;
			Break;
		EndDo;
		vDocObj = Undefined;
		If Not ValueIsFilled(vDocRef) Then
			vDocObj = Documents.ClientDataScans.CreateDocument();
			vDocObj.pmFillAttributesWithDefaultValues();
			vDocObj.Guest = pGuest;
			vDocObj.GuestGroup = pGuestGroup;
			vDocObj.Write(DocumentWriteMode.Posting);
			vDocRef = vDocObj.Ref;
		EndIf;
	EndIf;
	Return vDocRef;
EndFunction // GetDataScansDocument

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDocumentType(pRoomGuestsRow)
	vPictureCmd = NStr("en='<picture>'; ru='<картинка>'; de='<bild>'");
	If DocumentType = "P1" Then
		pRoomGuestsRow.Passport1Photo = vPictureCmd;
	ElsIf DocumentType = "P2" Then
		pRoomGuestsRow.Passport2Photo = vPictureCmd;
	ElsIf DocumentType = "P3" Then
		pRoomGuestsRow.Passport3Photo = vPictureCmd;
	ElsIf DocumentType = "BC" Then
		pRoomGuestsRow.BirthCertificate = vPictureCmd;
	ElsIf DocumentType = "MC" Then
		pRoomGuestsRow.MigrationCard = vPictureCmd;
	ElsIf DocumentType = "VS" Then
		pRoomGuestsRow.Visum = vPictureCmd;
	EndIf;
EndProcedure // FillDocumentType

// -----------------------------------------------------------------------------
&AtServer
Procedure FillOneRoomGuests()
	vScanCmd = NStr("en='scan'; ru='сканировать'; de='scan'");
	vPictureCmd = NStr("en='<picture>'; ru='<картинка>'; de='<bild>'");
	If TypeOf(Reservation) = Type("DocumentRef.Reservation") Then
		vOneRoomGuests = cmGetOneRoomReservations(Reservation.Number, Reservation.GuestGroup, Reservation.CheckInDate, Reservation.CheckOutDate, False);
	Else
		vOneRoomGuests = cmGetOneRoomAccommodations(Reservation.Room, Reservation.GuestGroup, Reservation.CheckInDate, Reservation.CheckOutDate);
	EndIf;
	For Each vOneRoomGuestsRow In vOneRoomGuests Do
		vResRef = vOneRoomGuestsRow.Ref;
		If vOneRoomGuests.IndexOf(vOneRoomGuestsRow) = 0 Then
			Reservation = vResRef;
		EndIf;
		
		vResGuest = vResRef.Guest;
		vRoomGuestsRow = RoomGuests.Add();
		vRoomGuestsRow.GuestFullName = vResRef.GuestFullName;
		vRoomGuestsRow.Guest = vResGuest;
		vRoomGuestsRow.GuestReservation = vResRef;
		vRoomGuestsRow.AccommodationType = vResRef.AccommodationType;
		
		vRoomGuestsRow.Passport1Photo = vScanCmd;
		vRoomGuestsRow.Passport2Photo = vScanCmd;
		vRoomGuestsRow.Passport3Photo = vScanCmd;
		vRoomGuestsRow.Visum = vScanCmd;
		vRoomGuestsRow.MigrationCard = vScanCmd;
		vRoomGuestsRow.BirthCertificate = vScanCmd;
		
		If ValueIsFilled(vResGuest) Then
			vGuestDataScans = GetDataScansDocument(GuestGroup, vResGuest);
			vRoomGuestsRow.GuestDataScans = vGuestDataScans;
			If ValueIsFilled(vGuestDataScans) Then
				vScanPictures = vGuestDataScans.ScanPictures;
				If vScanPictures.Find("P1", "Remarks") <> Undefined Then
					vRoomGuestsRow.Passport1Photo = vPictureCmd;
				EndIf;
				If vScanPictures.Find("P2", "Remarks") <> Undefined Then
					vRoomGuestsRow.Passport2Photo = vPictureCmd;
				EndIf;
				If vScanPictures.Find("P3", "Remarks") <> Undefined Then
					vRoomGuestsRow.Passport3Photo = vPictureCmd;
				EndIf;
				If vScanPictures.Find("BC", "Remarks") <> Undefined Then
					vRoomGuestsRow.BirthCertificate = vPictureCmd;
				EndIf;
				If vScanPictures.Find("MC", "Remarks") <> Undefined Then
					vRoomGuestsRow.MigrationCard = vPictureCmd;
				EndIf;
				If vScanPictures.Find("VS", "Remarks") <> Undefined Then
					vRoomGuestsRow.Visum = vPictureCmd;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillOneRoomGuests

// -----------------------------------------------------------------------------
&AtServer
Function FindGuestReservation(pGuestData, pDocumentDescription, pGuestRowID = Undefined)
	vReservationRowID = -1;
	vReservation = Undefined;
	If pGuestRowID <> Undefined Then
		vReservation = RoomGuests.FindByID(pGuestRowID).GuestReservation;
	Else
		If Not ValueIsFilled(Reservation) Then
			vReservation = Undefined;
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Reservation.Ref
			|FROM
			|	Document.Reservation AS Reservation
			|WHERE
			|	Reservation.Posted
			|	AND Reservation.ReservationStatus.IsActive
			|	AND (Reservation.GuestFullName = &qGuestFullName
			|			OR Reservation.GuestFullName = &qGuestFullNameEn
			|			OR Reservation.GuestFullName <> &qGuestFullName
			|				AND Reservation.GuestFullName <> &qGuestFullNameEn
			|				AND Reservation.Guest.LastName = &qGuestLastName
			|				AND Reservation.Guest.FirstName = &qGuestFirstName
			|				AND Reservation.Guest.SecondName = &qEmptyString
			|			OR Reservation.GuestFullName <> &qGuestFullName
			|				AND Reservation.GuestFullName <> &qGuestFullNameEn
			|				AND Reservation.Guest.LastName = &qGuestLastNameEn
			|				AND Reservation.Guest.FirstName = &qGuestFirstNameEn
			|				AND Reservation.Guest.SecondName = &qEmptyString)
			|	AND Reservation.CheckInDate <= &qPeriodTo
			|
			|ORDER BY
			|	Reservation.CheckInDate";
			vQry.SetParameter("qGuestFullName", TrimAll(GuestFullName));
			vQry.SetParameter("qGuestLastName", TrimAll(GuestLastName));
			vQry.SetParameter("qGuestFirstName", TrimAll(GuestFirstName));
			vQry.SetParameter("qGuestFullNameEn", Transliterate(TrimAll(GuestFullName)));
			vQry.SetParameter("qGuestLastNameEn", Transliterate(TrimAll(GuestLastName)));
			vQry.SetParameter("qGuestFirstNameEn", Transliterate(TrimAll(GuestFirstName)));
			vQry.SetParameter("qEmptyString", "");
			vQry.SetParameter("qPeriodTo", EndOfDay(CurrentSessionDate()) + 24*3600);
			vQryRes = vQry.Execute().Unload();
			If vQryRes.Count() > 0 Then
				vReservation = vQryRes.Get(0).Ref;
			EndIf;
		Else
			vReservation = Reservation;
		EndIf;
	EndIf;
	// Fill current guest
	If ValueIsFilled(vReservation) Or RoomGuests.Count() > 0 Then
		If RoomGuests.Count() = 0 And ValueIsFilled(vReservation) Then
			Reservation = vReservation;
			GuestGroup = Reservation.GuestGroup;
			PeriodOfStay = Format(Reservation.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(Reservation.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + 
			               TrimAll(Reservation.RoomType) + 
						   ?(ValueIsFilled(Reservation.Room), ", " + TrimAll(Reservation.Room), "");
			// Fill one room guests
			FillOneRoomGuests();
		EndIf;
		If pGuestRowID <> Undefined Then
			vRoomGuestsRow = RoomGuests.FindByID(pGuestRowID);
			vResGuest = vRoomGuestsRow.Guest;
			vReservation = vRoomGuestsRow.GuestReservation;
			vRoomGuestsRow.GuestFullName = Title(TrimAll(GuestFullName));
			vGuest = UpdateGuest(vResGuest, pGuestData);
			If vRoomGuestsRow.Guest <> vGuest And ValueIsFilled(vGuest) Then
				vResGuest = vGuest;
				vRoomGuestsRow.Guest = vGuest;
				vRoomGuestsRow.GuestFullName = TrimAll(vGuest.FullName);
				If ValueIsFilled(vRoomGuestsRow.GuestReservation) Then
					vResObj = vRoomGuestsRow.GuestReservation.GetObject();
					vResObj.GuestFullName = vRoomGuestsRow.GuestFullName;
					vResObj.Guest = vRoomGuestsRow.Guest;
					vResObj.Write(DocumentWriteMode.Posting);
					If TypeOf(vRoomGuestsRow.GuestReservation) = Type("DocumentRef.Accommodation") Then
						vResObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					Else
						vResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					EndIf;
				EndIf;
				If ValueIsFilled(vRoomGuestsRow.GuestDataScans) Then
					vDocObj = vRoomGuestsRow.GuestDataScans.GetObject();
					vDocObj.Guest = vRoomGuestsRow.Guest;
					If ValueIsFilled(vRoomGuestsRow.GuestReservation) Then
						vDocObj.ParentDoc = vRoomGuestsRow.GuestReservation;
					EndIf;
					vDocObj.Write(DocumentWriteMode.Posting);
					vRoomGuestsRow.GuestDataScans = vDocObj.Ref;
				EndIf;
			EndIf;
			If Not ValueIsFilled(vRoomGuestsRow.GuestDataScans) Then
				vRoomGuestsRow.GuestDataScans = GetDataScansDocument(GuestGroup, vResGuest);
			EndIf;
			If pGuestData <> Undefined And ValueIsFilled(vRoomGuestsRow.GuestDataScans) Then
				vDocObj = vRoomGuestsRow.GuestDataScans.GetObject();
				If DocumentType = "P1" Or DocumentType = "P2" Or DocumentType = "P3" Then
					UpdateDataScansDocument(vDocObj, pGuestData);
					// Photo
					If Not IsBlankString(pGuestData.Photo) Then
						vPhoto = New Picture(Base64Value(pGuestData.Photo));
						vDocObj.Photo = New ValueStorage(vPhoto);
					EndIf;
					// Signature
					If Not IsBlankString(pGuestData.Signature) Then
						vSignature = New Picture(Base64Value(pGuestData.Signature));
						vDocObj.Signature = New ValueStorage(vSignature);
					EndIf;
				EndIf;
				If Not IsBlankString(pGuestData.IdentityDocumentPicture) Then
					SavePicture(vDocObj, DocumentType, pGuestData.IdentityDocumentPicture, pDocumentDescription);
					FillDocumentType(vRoomGuestsRow);
				EndIf;
				// Parent document
				If ValueIsFilled(vRoomGuestsRow.GuestReservation) Then
					vDocObj.ParentDoc = vRoomGuestsRow.GuestReservation;
				EndIf;
				vDocObj.Write(DocumentWriteMode.Posting);
				vRoomGuestsRow.GuestDataScans = vDocObj.Ref;
			EndIf;
			vReservationRowID = pGuestRowID;
		Else
			// Try to find this guest row
			For Each vRoomGuestsRow In RoomGuests Do
				vResGuest = vRoomGuestsRow.Guest;
				If ValueIsFilled(vResGuest) And 
				  (Lower(TrimAll(GuestFullName)) = Lower(TrimAll(vRoomGuestsRow.GuestFullName)) Or Lower(Transliterate(TrimAll(GuestFullName))) = Lower(TrimAll(vRoomGuestsRow.GuestFullName)) Or
				   Lower(TrimAll(GuestFullName)) <> Lower(TrimAll(vRoomGuestsRow.GuestFullName)) And Lower(Transliterate(TrimAll(GuestFullName))) <> Lower(TrimAll(vRoomGuestsRow.GuestFullName)) And
				   (Lower(TrimAll(GuestLastName)) = Lower(TrimAll(vResGuest.LastName)) And Lower(TrimAll(GuestFirstName)) = Lower(TrimAll(vResGuest.FirstName)) And IsBlankString(vResGuest.SecondName) Or
				    Lower(Transliterate(TrimAll(GuestLastName))) = Lower(TrimAll(vResGuest.LastName)) And Lower(Transliterate(TrimAll(GuestFirstName))) = Lower(TrimAll(vResGuest.FirstName)) And IsBlankString(vResGuest.SecondName))) Then
					If cmIsInLat(GuestFullName) And Not cmIsInLat(GuestLastNameScanned) And Not IsBlankString(GuestLastNameScanned) Then
						GuestFullName = Title(TrimAll(TrimAll(GuestLastNameScanned) + " " + TrimAll(GuestFirstNameScanned) + " " + TrimAll(GuestSecondNameScanned)));
						
						GuestLastName = TrimAll(GuestLastNameScanned);
						GuestFirstName = TrimAll(GuestFirstNameScanned);
						GuestSecondName = TrimAll(GuestSecondNameScanned);
						
						pGuestData.LastName = GuestLastName;
						pGuestData.FirstName = GuestFirstName;
						pGuestData.SecondName = GuestSecondName;
					EndIf;
					vReservation = vRoomGuestsRow.GuestReservation;
					vRoomGuestsRow.GuestFullName = Title(TrimAll(GuestFullName));
					vGuest = UpdateGuest(vResGuest, pGuestData);
					If vRoomGuestsRow.Guest <> vGuest And ValueIsFilled(vGuest) Then
						vResGuest = vGuest;
						vRoomGuestsRow.Guest = vGuest;
						vRoomGuestsRow.GuestFullName = TrimAll(vGuest.FullName);
						If ValueIsFilled(vRoomGuestsRow.GuestReservation) Then
							vResObj = vRoomGuestsRow.GuestReservation.GetObject();
							vResObj.GuestFullName = vRoomGuestsRow.GuestFullName;
							vResObj.Guest = vRoomGuestsRow.Guest;
							vResObj.Write(DocumentWriteMode.Posting);
							If TypeOf(vRoomGuestsRow.GuestReservation) = Type("DocumentRef.Accommodation") Then
								vResObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							Else
								vResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							EndIf;
						EndIf;
						If ValueIsFilled(vRoomGuestsRow.GuestDataScans) Then
							vDocObj = vRoomGuestsRow.GuestDataScans.GetObject();
							vDocObj.Guest = vRoomGuestsRow.Guest;
							If ValueIsFilled(vRoomGuestsRow.GuestReservation) Then
								vDocObj.ParentDoc = vRoomGuestsRow.GuestReservation;
							EndIf;
							vDocObj.Write(DocumentWriteMode.Posting);
							vRoomGuestsRow.GuestDataScans = vDocObj.Ref;
						EndIf;
					EndIf;
					If Not ValueIsFilled(vRoomGuestsRow.GuestDataScans) Then
						vRoomGuestsRow.GuestDataScans = GetDataScansDocument(GuestGroup, vResGuest);
					EndIf;
					If pGuestData <> Undefined And ValueIsFilled(vRoomGuestsRow.GuestDataScans) Then
						vDocObj = vRoomGuestsRow.GuestDataScans.GetObject();
						If DocumentType = "P1" Or DocumentType = "P2" Or DocumentType = "P3" Then
							UpdateDataScansDocument(vDocObj, pGuestData);
						EndIf;
						If Not IsBlankString(pGuestData.IdentityDocumentPicture) Then
							SavePicture(vDocObj, DocumentType, pGuestData.IdentityDocumentPicture, pDocumentDescription);
							FillDocumentType(vRoomGuestsRow);
						EndIf;
						If ValueIsFilled(vRoomGuestsRow.GuestReservation) Then
							vDocObj.ParentDoc = vRoomGuestsRow.GuestReservation;
						EndIf;
						vDocObj.Write(DocumentWriteMode.Posting);
						vRoomGuestsRow.GuestDataScans = vDocObj.Ref;
					EndIf;
					vReservationRowID = vRoomGuestsRow.GetID();
					Break;
				EndIf;
			EndDo;
			// Try to find empty guest row
			If vReservationRowID = -1 Then
				For Each vRoomGuestsRow In RoomGuests Do
					If IsBlankString(vRoomGuestsRow.GuestFullName) Then
						vReservation = vRoomGuestsRow.GuestReservation;
						vRoomGuestsRow.GuestFullName = Title(TrimAll(GuestFullName));
						vRoomGuestsRow.Guest = CreateNewGuest(pGuestData);
						vRoomGuestsRow.GuestDataScans = GetDataScansDocument(GuestGroup, vRoomGuestsRow.Guest);
						If pGuestData <> Undefined And ValueIsFilled(vRoomGuestsRow.GuestDataScans) Then
							vDocObj = vRoomGuestsRow.GuestDataScans.GetObject();
							If DocumentType = "P1" Or DocumentType = "P2" Or DocumentType = "P3" Then
								UpdateDataScansDocument(vDocObj, pGuestData);
								// Photo
								If Not IsBlankString(pGuestData.Photo) Then
									vPhoto = New Picture(Base64Value(pGuestData.Photo));
									vDocObj.Photo = New ValueStorage(vPhoto);
								EndIf;
								// Signature
								If Not IsBlankString(pGuestData.Signature) Then
									vSignature = New Picture(Base64Value(pGuestData.Signature));
									vDocObj.Signature = New ValueStorage(vSignature);
								EndIf;
							EndIf;
							If Not IsBlankString(pGuestData.IdentityDocumentPicture) Then
								SavePicture(vDocObj, DocumentType, pGuestData.IdentityDocumentPicture, pDocumentDescription);
								FillDocumentType(vRoomGuestsRow);
							EndIf;
							// Parent document
							If ValueIsFilled(vRoomGuestsRow.GuestReservation) Then
								vDocObj.ParentDoc = vRoomGuestsRow.GuestReservation;
							EndIf;
							vDocObj.Write(DocumentWriteMode.Posting);
							vRoomGuestsRow.GuestDataScans = vDocObj.Ref;
						EndIf;
						If ValueIsFilled(vRoomGuestsRow.GuestReservation) Then
							vResObj = vRoomGuestsRow.GuestReservation.GetObject();
							vResObj.GuestFullName = Title(vRoomGuestsRow.GuestFullName);
							vResObj.Guest = vRoomGuestsRow.Guest;
							vResObj.Write(DocumentWriteMode.Posting);
							If TypeOf(vRoomGuestsRow.GuestReservation) = Type("DocumentRef.Accommodation") Then
								vResObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							Else
								vResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							EndIf;
						EndIf;
						vReservationRowID = vRoomGuestsRow.GetID();
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	Return vReservationRowID;
EndFunction // FindGuestReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestFullNameOnChangeAtClient(pGuestRowID = Undefined)
	If Not IsBlankString(GuestFullName) Then
		vPrevGuestGroup = GuestGroup;
		GuestRowID = FindGuestReservation(GuestData, DocumentDescription, pGuestRowID);
		If GuestRowID = -1 Then
			GuestStatus = NStr("en='Guest reservation was NOT found!.'; 
			                   |ru='Бронь гостя НЕ найдена!'; 
							   |de='Gast Reservierung NICHT gefunden!'");
			Items.GuestStatus.TextColor = WebColors.Red;
			Items.CheckInGuest.Enabled = False;
		Else
			If vPrevGuestGroup <> GuestGroup Then
				If DocumentType = "P1" Then
					GuestStatus = NStr("en='Guest reservation was found! Passport picture was saved and recognized.'; 
					                   |ru='Бронь гостя найдена. Картинка паспорта сохранена и распознана.'; 
									   |de='Gast Reservierung gefunden. Das Pass Bild wird gespeichert und erkannt.'");
				Else
					GuestStatus = NStr("en='Guest reservation was found! Document picture was saved.'; 
					                   |ru='Бронь гостя найдена. Картинка документа сохранена.'; 
									   |de='Gast Reservierung gefunden. Das Document Bild wird gespeichert.'");
				EndIf;
			Else
				If DocumentType = "P1" Then
					GuestStatus = NStr("en='Passport picture was saved and recognized.'; 
					                   |ru='Картинка паспорта сохранена и распознана.'; 
									   |de='Das Pass Bild wird gespeichert und erkannt.'");
				Else
					GuestStatus = NStr("en='Document picture was saved.'; 
					                   |ru='Картинка документа сохранена.'; 
									   |de='Das Document Bild wird gespeichert.'");
				EndIf;
			EndIf;
			Items.GuestStatus.TextColor = WebColors.Green;
			Items.CheckInGuest.Enabled = True;
			// Select row of current guest
			If GuestRowID >= 0 Then
				Items.RoomGuests.CurrentRow = GuestRowID;
				Items.RoomGuests.SelectedRows.Clear();
				Items.RoomGuests.SelectedRows.Add(GuestRowID);
			EndIf;
			// Open picture
			OpenPicture();
		EndIf;
	Else
		GuestStatus = NStr("en='Guest name is not filled!'; 
		                   |ru='ФИО гостя не указано!'; 
						   |de='Name des Gastes ist nicht gefüllt!'");
		Items.GuestStatus.TextColor = WebColors.Blue;
		Items.CheckInGuest.Enabled = False;
	EndIf;
EndProcedure // GuestFullNameOnChangeOnClient

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRussianPassportType()
	Return Catalogs.IdentityDocumentTypes.FindByCode("21");
EndFunction // GetRussianPassportType

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetScanConfigurationsForIdentityDocumentType(pIdentityDocumentType)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ScanConfigurations.Ref AS ScanConfiguration
	|FROM
	|	Catalog.ScanConfigurations AS ScanConfigurations
	|WHERE
	|	ScanConfigurations.IdentityDocumentType = &qIdentityDocumentType
	|	AND NOT ScanConfigurations.DeletionMark
	|
	|ORDER BY
	|	ScanConfigurations.SortCode,
	|	ScanConfigurations.Code";
	vQry.SetParameter("qIdentityDocumentType", pIdentityDocumentType);
	Return vQry.Execute().Unload();
EndFunction // GetScanConfigurationsForIdentityDocumentType

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckRecognitionTimeout() 
	LastEventTime = '00010101';
	DetachIdleHandler("CheckRecognitionTimeout");
	GuestStatus = NStr("en='Failed to recognize document within " + WaitForRecognitionTimeout + " seconds!'; 
	                   |ru='Не удалось распознать документ в течение " + WaitForRecognitionTimeout + " секунд!'; 
					   |de='Konnte das Dokument nicht innerhalb von " + WaitForRecognitionTimeout + " Sekunden erkennen!'");
	Items.GuestStatus.TextColor = WebColors.Blue;
EndProcedure // CheckRecognitionTimeout

// -----------------------------------------------------------------------------
&AtClient
Function FillStructureWithCapturedData(pPBObj, pCapturedData)
	vData = New Structure();
	For i = 0 To (pCapturedData.FieldCount - 1) Do
		vFieldInfo = pPBObj.GetFieldInfo(i);
		vData.Insert(vFieldInfo.FieldName, vFieldInfo.FieldValue);
		vData.Insert("Is" + Title(vFieldInfo.FieldName) + "Accepted", vFieldInfo.IsAccepted);
	EndDo;
	For i = 0 To (pCapturedData.ImageCount - 1) Do
		vImageName = pPBObj.GetImageName(i);
		vData.Insert(pPBObj.GetImageName(i), pPBObj.GetImageBase64(i));
	EndDo;
	If Not vData.Property("Full_Document") Then
		pPBObj.TakeSnapshot();
		vData.Insert("Full_Document", pPBObj.GetSnapshotBase64());
	EndIf;
	Return vData;	
EndFunction // FillStructureWithCapturedData

// -----------------------------------------------------------------------------
&AtClient
Procedure AutoOCREvent(pEventType = Undefined) Export
	If pEventType = 1 Then
		If PassportWasRecognized Then
			Return;
		EndIf;
		If Not ValueIsFilled(LastEventTime) Or (CurrentDate() - LastEventTime) <= WaitForRecognitionTimeout Then
			If Not ValueIsFilled(LastEventTime) Then
				LastEventTime = CurrentDate();
				AttachIdleHandler("CheckRecognitionTimeout", WaitForRecognitionTimeout, True);
			EndIf;
			GuestStatus = NStr("en='Passport detected...'; 
			                   |ru='Паспорт распознается...'; 
							   |de='Der Pass wird anerkannt...'");
			Items.GuestStatus.TextColor = WebColors.Blue;
		Else
			PassportWasRecognized = False;
			LastEventTime = '00010101';
			DetachIdleHandler("CheckRecognitionTimeout");
			GuestStatus = NStr("en='Failed to recognize document within " + WaitForRecognitionTimeout + " seconds!'; 
			                   |ru='Не удалось распознать документ в течение " + WaitForRecognitionTimeout + " секунд!'; 
							   |de='Konnte das Dokument nicht innerhalb von " + WaitForRecognitionTimeout + " Sekunden erkennen!'");
			Items.GuestStatus.TextColor = WebColors.Blue;
		EndIf;
	ElsIf pEventType = 2 Then
		If PassportWasRecognized Then
			Return;
		EndIf;
		EventMode = True;
		vCapturedData = PBObj.GetDocumentInfo();
		If lower(vCapturedData.DocType) = "rus.passport.national" Then
			DocumentType = "P1";
			
			// Fill structure with captured data
			vData = FillStructureWithCapturedData(PBObj, vCapturedData);
			If Not IsBlankString(vData.Surname) And vData.IsSurnameAccepted Then
				PassportWasRecognized = True;
				LastEventTime = '00010101';
				DetachIdleHandler("CheckRecognitionTimeout");
				
				vGuestFullName = TrimAll(?(vData.IsSurnameAccepted, Title(vData.Surname), "") + " " + ?(vData.IsNameAccepted, Title(vData.Name), "") + " " + ?(vData.IsPatronymicAccepted, Title(vData.Patronymic), ""));
				If vGuestFullName <> TrimAll(GuestFullName) Then
					GuestFullName = vGuestFullName;
					
					GuestLastName = Title(vData.Surname);
					GuestFirstName = Title(vData.Name);
					GuestSecondName = Title(vData.Patronymic);
					
					GuestLastNameScanned = GuestLastName;
					GuestFirstNameScanned = GuestFirstName;
					GuestSecondNameScanned = GuestSecondName;
					
					FillGuestData(vData, GetRussianPassportType());
					
					GuestFullNameOnChangeAtClient();
					
					SavGuestStatus = GuestStatus;
					SavGuestStatusColor = Items.GuestStatus.TextColor;
				Else
					GuestStatus = SavGuestStatus;
					Items.GuestStatus.TextColor = SavGuestStatusColor;
				EndIf;
			EndIf;
		ElsIf StrFind(lower(vCapturedData.DocType), "mrz.") > 0 Then
			DocumentType = "P1";
			
			// Fill structure with captured data
			vData = FillStructureWithCapturedData(PBObj, vCapturedData);
			If vData.Property("last_name_mrz") And Not IsBlankString(vData.last_name_mrz) And vData.IsLast_name_mrzAccepted Then
				PassportWasRecognized = True;
				LastEventTime = '00010101';
				DetachIdleHandler("CheckRecognitionTimeout");
				
				vGuestFullName = TrimAll(vData.last_name_mrz);
				If vData.Property("first_name_mrz") And Not IsBlankString(vData.first_name_mrz) And vData.IsFirst_name_mrzAccepted Then
					vGuestFullName = vGuestFullName + " " + TrimAll(vData.first_name_mrz);
				EndIf;
				If vGuestFullName <> TrimAll(GuestFullName) Then
					GuestFullName = vGuestFullName;
					
					GuestLastName = Title(vData.last_name_mrz);
					GuestFirstName = Title(vData.first_name_mrz);
					GuestSecondName = "";
					
					GuestLastNameScanned = GuestLastName;
					GuestFirstNameScanned = GuestFirstName;
					GuestSecondNameScanned = GuestSecondName;
					
					vCitizenshipCode = "";
					If vData.Property("nationality_mrz") And Not IsBlankString(vData.nationality_mrz) And vData.IsNationality_mrzAccepted Then
						vCitizenshipCode = TrimAll(vData.nationality_mrz);
					EndIf;
					FillGuestData(vData, tcOnServer.GetDocumentTypeByMRZCountryCode(vCitizenshipCode));
					
					GuestFullNameOnChangeAtClient();
					
					SavGuestStatus = GuestStatus;
					SavGuestStatusColor = Items.GuestStatus.TextColor;
				Else
					GuestStatus = SavGuestStatus;
					Items.GuestStatus.TextColor = SavGuestStatusColor;
				EndIf;
			EndIf;
		EndIf;
		EventMode = False;
	ElsIf pEventType = 3 Then
		PassportWasRecognized = False;
		LastEventTime = '00010101';
		DetachIdleHandler("CheckRecognitionTimeout");
		GuestStatus = NStr("en='Place passport first page over Passport box!'; 
		                   |ru='Положите паспорт открытый на первой странице на Passport Box!'; 
						   |de='Platz Pass erste Seite über Passport-Box!'");
		Items.GuestStatus.TextColor = WebColors.Blue;
		EventMode = False;
	EndIf;
EndProcedure // AutoOCREvent

// -----------------------------------------------------------------------------
&AtServer
Procedure ParseGuestFullNameAtServer()
	vSex = Undefined;
	cmParseClientFullName(GuestFullName, GuestLastName, GuestFirstName, GuestSecondName, vSex);
EndProcedure // ParseGuestFullNameAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ParseGuestFullName()
	If IsBlankString(GuestFullName) Then
		GuestLastName = "";
		GuestFirstName = "";
		GuestSecondName = "";
		
		GuestLastNameScanned = "";
		GuestFirstNameScanned = "";
		GuestSecondNameScanned = "";
	Else
		ParseGuestFullNameAtServer();
		
		GuestLastNameScanned = GuestData.LastName;
		GuestFirstNameScanned = GuestData.FirstName;
		GuestSecondNameScanned = GuestData.SecondName;
		
		GuestData.LastName = GuestLastName;
		GuestData.FirstName = GuestFirstName;
		GuestData.SecondName = GuestSecondName;
	EndIf;
EndProcedure // ParseGuestFullName

// -----------------------------------------------------------------------------
&AtServer
Function CheckInAtServer(pRef, pQueryBoxInactive = false, pSelResList = Undefined)
	// Build list of selected reservations. We will process reservations from the one room only (or empty one)
	vSelRes = pRef;
	vStopCheckIn = False;
	If Not vSelRes.Posted Then
		vStopCheckIn = True;
	ElsIf Not ValueIsFilled(vSelRes.ReservationStatus) Then
		vStopCheckIn = True;
	ElsIf Not vSelRes.ReservationStatus.IsActive And vSelRes.ReservationStatus <> vSelRes.Hotel.NoShowReservationStatus Then
		vStopCheckIn = True;
		If Not cmCheckUserPermissions("HavePermissionToCheckInBasedOnInactiveReservations") And ValueIsFilled(vSelRes.Hotel) Then
			Return NStr("en='You do not have rights to check-in guests based on inactive reservation!';ru='Нет прав на размещение гостей по не активной брони!';de='Sie haben keine Rechte, Gäste nach nicht aktiven Reservierungen zu platzieren! '");
		EndIf;
	EndIf;
	If vStopCheckIn Then
		If Not pQueryBoxInactive Then
			Return "DoQueryBox"
		EndIf;
	EndIf;
	If vSelRes.Posted Then
		vSelResList = New ValueList();
		vSelRows = GetOneRoomGuests(vSelRes);
		vQuestionWasAsked = False;
		vSkip = False;
		If pSelResList = Undefined Then
			For Each vRow In vSelRows Do
				vSelResList.Add(vRow.Ref, cmBuildAccommodationSortingPresentation(vRow.Ref));
			EndDo;
		Else
			vSelResList = pSelResList;
		EndIf;
		If pSelResList = Undefined Then
			Return vSelResList;
		EndIf;
		If vSelResList.Count() = 0 Then
			Return "";
		Else
			vSelResList.SortByPresentation();
			vSelRes = vSelResList.Get(0).Value;
		EndIf;
		Return New Structure("ValueList", vSelResList);
	Else
		Return NStr("en='Check-in is allowed for posted reservation only!';ru='Поселять можно только по проведенной брони!';de='Ein Check-In ist nur nach einer bearbeiteten Reservierung möglich!'");
	EndIf;
EndFunction // CheckInAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterAnswer(QuestionResult, AdditionalParameters) Export
	vSelResList  = AdditionalParameters.vSelResList;
	vErrList     = AdditionalParameters.vErrList;
	If QuestionResult = DialogReturnCode.No Then	
		For Each int In vErrList Do
			vSelResList.Add(int.value)	
		EndDo;
	EndIf;	
	vQuestionWasAsked = True;
	CheckInEndPart(vSelResList);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInEndPart(vSelResList, vErrList = Undefined)
	If Not vErrList = Undefined Then
		For Each int In vErrList Do
			vSelResList.Add(int.value)	
		EndDo;
	EndIf;
	
	// Check current reservation list deposits
	CheckReservationsDeposits(vSelResList);
	vResult = CheckInAtServer(Reservation, true, vSelResList);
	If ValueIsFilled(vResult) Then
		If TypeOf(vResult)=Type("Structure") Then
			#IF ThickClientOrdinaryApplication THEN
				If cmIsSimpleMode() Then
					// APDEX
					vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
					APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

					// Open new accommodation and fill group table from the given list
					OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()));
					ThisForm.Close();
				Else
					// Open new accommodation and fill group table from the given list
					vDocObj = Documents.Accommodation.CreateDocument();
					vDocObj.Fill(Reservation);
					// Check should we turn "Fix reservation conditions" flag on 
					cmCheckFixReservationConditionsAtCheckIn(vDocObj, Reservation);
					// Get document form
					vFrm = vDocObj.GetForm();
					vFrm.SelDocsList = vResult.ValueList;
					If Not vFrm.IsOpen() Then
						vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
					EndIf;
					vFrm.Open();
					// Check current reservation messages
					If cmGetNumberOfMessagesForObject(Reservation) > 0 Then
						// Show reservation messages
						vMsgsFrm = DataProcessors.Messages.GetForm();
						vMsgsFrm.ByObject = Reservation;
						vMsgsFrm.Open();
					EndIf;
				EndIf;
			#ELSE
				// APDEX
				vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.OpenForm";
				APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

				// Open new accommodation and fill group table from the given list
				OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()));
				ThisForm.Close();
			#ENDIF
		Else
			ShowMessageBox(,vResult);
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
// Description: Function checks balances (deposits that are negative balances) 
//              for the given reservations value list
// Parameters: Value list of reservations
// Return value: Always true so far
// -----------------------------------------------------------------------------
&AtServer
Function CheckReservationsDeposits(pResRef)
	vFolios = cmGetDocumentFoliosWithDebts(pResRef, True); // Deposits only
	If vFolios.Count() > 0 Then
		vDebtsMessage = NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF;
		For Each vFoliosRow In vFolios Do
			If ValueIsFilled(vFoliosRow.Folio) Then
				vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFoliosRow.Folio.Number) + " " + 
				TrimAll(vFoliosRow.Folio.Client) + NStr("ru=', номер ';en=', room ';de=', Zimmer '") + 
				TrimAll(vFoliosRow.Folio.Room) + NStr("ru=', период ';en=', period ';de=', Period '") + 
				Format(vFoliosRow.Folio.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
				Format(vFoliosRow.Folio.DateTimeTo, "DF='dd.MM.yy HH:mm'") + " = " + 
				cmFormatSum(vFoliosRow.SumBalance, vFoliosRow.Folio.FolioCurrency, "NZ=");
			Else
				vDebtsMessage = vDebtsMessage + Chars.LF + NStr("en='<Empty folio>';ru='<Пустое фолио>';de='<Leeres Konto>'") + " = " + cmFormatSum(vFoliosRow.SumBalance, "NZ=", , True);
			EndIf;
		EndDo;
		vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEPOSITS!';ru='ЕСТЬ ПРЕДОПЛАТА!';de='ES LIEGT EINE ANZAHLUNG VOR!'");
		tcCommonFunctionOnClientServer.TextMessage(vDebtsMessage);
		WriteLogEvent(NStr("en='Reservation.CheckDeposits';ru='Резервирование.ПроверкаДепозита';de='Reservation.CheckDeposits'"), EventLogLevel.Information, Metadata.Documents.Folio, , vDebtsMessage);
	EndIf;
	Return True;
EndFunction // CheckReservationsDeposits

// -----------------------------------------------------------------------------
&AtServer
Function GetOneRoomGuests(pRef)
	// Fill one room guests
	vQry = New Query;
	vQry.Text = "SELECT
	            |	Reservations.Ref AS Ref,
	            |	Reservations.CheckInDate AS CheckInDate,
	            |	Reservations.CheckOutDate AS CheckOutDate,
	            |	Reservations.Guest AS GuestRef,
	            |	Reservations.Guest.FullName AS Guest,
	            |	Reservations.AccommodationType AS AccommodationType,
	            |	0 AS AnnulReserv,
	            |	FALSE AS IsStatusChanged,
	            |	FALSE AS IsAnnulation,
	            |	TRUE AS IsGuest,
	            |	&qEmptyReservationStatusRef AS ReservationStatus
	            |FROM
	            |	Document.Reservation AS Reservations
	            |WHERE
	            |	Reservations.GuestGroup = &qGroup
	            |	AND (Reservations.Room = &qRoom
	            |				AND &qRoomIsFilled
	            |			OR Reservations.Number = &qNumber
	            |				AND NOT &qRoomIsFilled)
	            |	AND Reservations.Posted
	            |	AND NOT Reservations.DeletionMark
	            |	AND (Reservations.ReservationStatus.IsActive
	            |			OR Reservations.ReservationStatus.IsCheckIn
	            |			OR Reservations.ReservationStatus.IsPreliminary
	            |			OR Reservations.ReservationStatus.IsInWaitingList
	            |			OR Reservations.ReservationStatus = &qReservStatus)
	            |
	            |ORDER BY
	            |	Reservations.CheckInDate,
	            |	Reservations.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pRef.GuestGroup);
	vQry.SetParameter("qRoom", pRef.Room);
	vQry.SetParameter("qReservStatus", pRef.ReservationStatus);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRef.Room));
	vQry.SetParameter("qNumber", pRef.Number);
	vQry.SetParameter("qEmptyReservationStatusRef", Catalogs.ReservationStatuses.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction // GetOneRoomGuests

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveDocumentPictureAtServer(pGuestData, pDocumentDescription)
	vRoomGuestsRow = RoomGuests.FindByID(GuestRowID);
	If ValueIsFilled(vRoomGuestsRow.Guest) Then
		If Not ValueIsFilled(vRoomGuestsRow.GuestDataScans) Then
			vRoomGuestsRow.GuestDataScans = GetDataScansDocument(GuestGroup, vRoomGuestsRow.Guest);
		EndIf;
		If ValueIsFilled(vRoomGuestsRow.GuestDataScans) Then
			vDocObj = vRoomGuestsRow.GuestDataScans.GetObject();
			If Not IsBlankString(pGuestData.IdentityDocumentPicture) Then
				SavePicture(vDocObj, DocumentType, pGuestData.IdentityDocumentPicture, pDocumentDescription);
			EndIf;
			If ValueIsFilled(vRoomGuestsRow.GuestReservation) Then
				vDocObj.ParentDoc = vRoomGuestsRow.GuestReservation;
			EndIf;
			vDocObj.Write(DocumentWriteMode.Posting);
			vRoomGuestsRow.GuestDataScans = vDocObj.Ref;
		EndIf;
		FillDocumentType(vRoomGuestsRow);
	Else
		GuestStatus = NStr("en='Guest names should be filled!'; 
		                   |ru='Не заполнены ФИО гостя!'; 
						   |de='Die Namen der Gäste sollten gefüllt werden!'");
		Items.GuestStatus.TextColor = WebColors.Blue;
	EndIf;
EndProcedure // SaveDocumentPictureAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveDocumentPictureAtClient()
	If GuestRowID >= 0 Then
		SaveDocumentPictureAtServer(GuestData, DocumentDescription);
	Else
		GuestStatus = NStr("en='Choose guest from the list of room guests!'; 
		                   |ru='В списке гостей выделите гостя, чей документ сканируете!'; 
						   |de='Wählen Sie Gast aus der Liste der Zimmer Gäste!'");
		Items.GuestStatus.TextColor = WebColors.Blue;
	EndIf;
EndProcedure // SaveDocumentPictureAtClient

// -----------------------------------------------------------------------------
&AtClient
Procedure ScanDocument()
	// Clear picture if any
	DocPicture = "";
	// Event mode is On
	EventMode = True;
	// Initialize document type
	If GuestRowID = -1 And DocumentType <> "P1" Then
		DocumentType = "P1";
	EndIf;
	If PBObj <> Undefined And amImageScanner = tcSmartPassportBoxEngine Then
		// Stop auto capture
		If PBObj.StopAutoCapturePassport() < 0 Then
			GuestStatus = NStr("en='Failed to stop auto capture! '; 
			                   |ru='Не удалось остановить распознавание! '; 
							   |de='Fehler beim Auto-Capture zu stoppen! '") + 
			              PBObj.GetLastError().ErrMessage;
			Items.GuestStatus.TextColor = WebColors.Red;
			EventMode = False;
			Return;
		EndIf;
		// Check document type
		If DocumentType = "P1" Then
			// Try to recognize passport
			If PBObj.CapturePassport(CaptureSettings) < 0 Then
				// Try to get document picture
				PBObj.TakeSnapshot();
				GuestData.IdentityDocumentPicture = PBObj.GetSnapshotBase64();
				// Save document picture to the data scan object
				SaveDocumentPictureAtClient();
				// Update status
				GuestStatus = NStr("en='Passport was not recognized! Document picture was saved to database.'; 
				                   |ru='Паспорт не распознан! Картинка документа сохранена.'; 
								   |de='Passport wurde nicht erkannt! Bild eines Dokuments wird gespeichert'");
				Items.GuestStatus.TextColor = WebColors.Blue;
				// Show passport picture
				OpenPicture();
			Else
				vCapturedData = PBObj.GetDocumentInfo();
				If lower(vCapturedData.DocType) = "rus.passport.national" Then
					// Fill structure with captured data
					vData = FillStructureWithCapturedData(PBObj, vCapturedData);
					If vData.Property("Surname") And Not IsBlankString(vData.Surname) And vData.IsSurnameAccepted Then
						PassportWasRecognized = True;
						
						GuestFullName = TrimAll(?(vData.IsSurnameAccepted, Title(vData.Surname), "") + " " + ?(vData.IsNameAccepted, Title(vData.Name), "") + " " + ?(vData.IsPatronymicAccepted, Title(vData.Patronymic), ""));
						
						GuestLastName = Title(vData.Surname);
						GuestFirstName = Title(vData.Name);
						GuestSecondName = Title(vData.Patronymic);
						
						GuestLastNameScanned = GuestLastName;
						GuestFirstNameScanned = GuestFirstName;
						GuestSecondNameScanned = GuestSecondName;
						
						FillGuestData(vData, GetRussianPassportType());
						
						// Process guest name change
						GuestFullNameOnChangeAtClient(GuestRowID);
					Else
						// Try to get document picture
						PBObj.TakeSnapshot();
						GuestData.IdentityDocumentPicture = PBObj.GetSnapshotBase64();
						// Save document picture to the data scan object
						SaveDocumentPictureAtClient();
						// Update status
						GuestStatus = NStr("en='Passport was not recognized! Document picture was saved to database.'; 
						                   |ru='Паспорт не распознан! Картинка документа сохранена.'; 
										   |de='Passport wurde nicht erkannt! Bild eines Dokuments wird gespeichert'");
						Items.GuestStatus.TextColor = WebColors.Blue;
						// Show passport picture
						OpenPicture();
					EndIf;
				ElsIf StrFind(lower(vCapturedData.DocType), "mrz.") > 0 Then
					// Fill structure with captured data
					vData = FillStructureWithCapturedData(PBObj, vCapturedData);
					If vData.Property("last_name_mrz") And Not IsBlankString(vData.last_name_mrz) And vData.IsLast_name_mrzAccepted Then
						PassportWasRecognized = True;
						
						GuestLastName = Title(TrimAll(vData.last_name_mrz));
						GuestFirstName = "";
						GuestSecondName = "";
						
						GuestFullName = GuestLastName;
						If vData.Property("first_name_mrz") And Not IsBlankString(vData.first_name_mrz) And vData.IsFirst_name_mrzAccepted Then
							GuestFirstName = Title(TrimAll(vData.first_name_mrz));
							GuestFullName = GuestFullName + GuestFirstName;
						EndIf;
						
						GuestLastNameScanned = GuestLastName;
						GuestFirstNameScanned = GuestFirstName;
						GuestSecondNameScanned = GuestSecondName;
						
						vCitizenshipCode = "";
						If vData.Property("nationality_mrz") And Not IsBlankString(vData.nationality_mrz) And vData.IsNationality_mrzAccepted Then
							vCitizenshipCode = TrimAll(vData.nationality_mrz);
						EndIf;
						FillGuestData(vData, tcOnServer.GetDocumentTypeByMRZCountryCode(vCitizenshipCode));
						
						// Process guest name change
						GuestFullNameOnChangeAtClient(GuestRowID);
					Else
						// Try to get document picture
						PBObj.TakeSnapshot();
						GuestData.IdentityDocumentPicture = PBObj.GetSnapshotBase64();
						// Save document picture to the data scan object
						SaveDocumentPictureAtClient();
						// Update status
						GuestStatus = NStr("en='Passport was not recognized! Document picture was saved to database.'; 
						                   |ru='Паспорт не распознан! Картинка документа сохранена.'; 
										   |de='Passport wurde nicht erkannt! Bild eines Dokuments wird gespeichert'");
						Items.GuestStatus.TextColor = WebColors.Blue;
						// Show passport picture
						OpenPicture();
					EndIf;
				Else
					// Try to get document picture
					PBObj.TakeSnapshot();
					GuestData.IdentityDocumentPicture = PBObj.GetSnapshotBase64();
					// Save document picture to the data scan object
					SaveDocumentPictureAtClient();
					// Update status
					GuestStatus = NStr("en='Passport was not recognized! Document picture was saved to database.'; 
					                   |ru='Паспорт не распознан! Картинка документа сохранена.'; 
									   |de='Passport wurde nicht erkannt! Bild eines Dokuments wird gespeichert'");
					Items.GuestStatus.TextColor = WebColors.Blue;
					// Show passport picture
					OpenPicture();
				EndIf;
			EndIf;
		Else
			// Try to get document picture
			PBObj.TakeSnapshot();
			GuestData.IdentityDocumentPicture = PBObj.GetSnapshotBase64();
			// Save document picture to the data scan object
			SaveDocumentPictureAtClient();
			// Update status
			GuestStatus = NStr("en='Document picture was saved to database!'; 
			                   |ru='Картинка документа сохранена!'; 
							   |de='Bild eines Dokuments wird gespeichert!'");
			Items.GuestStatus.TextColor = WebColors.Green;
			// Show passport picture
			OpenPicture();
		EndIf;
		If ValueIsFilled(ConnectionParameters) And tcOnServer.cmGetAttributeByRef(ConnectionParameters, "AutoRecognition") Then
			If PBObj.StartAutoCapturePassport(AutoCaptureSettings, CaptureSettings) < 0 Then
			    GuestStatus = NStr("en='Failed to start auto capture! '; 
				                   |ru='Не удалось запустить автоматическое распознавание! '; 
								   |de='Fehler beim Auto-Capture zu starten! '") + 
				              PBObj.GetLastError().ErrMessage;
				Items.GuestStatus.TextColor = WebColors.Red;
			EndIf;
		EndIf;
	Else		
		GuestStatus = NStr("en='Failed to connect to Passport box device!'; 
		                   |ru='Ошибка подключения к Passport box!'; 
						   |de='Fehler bei Passport-Box verbinden!'");
		Items.GuestStatus.TextColor = WebColors.Red;
	EndIf;
	SavGuestStatus = GuestStatus;
	SavGuestStatusColor = Items.GuestStatus.TextColor;
	EventMode = False;
EndProcedure // ScanDocument

// -----------------------------------------------------------------------------
&AtServer
Procedure OpenPictureAtServer(pScanDocument)
	DocPicture = "";
	// Get document row by document type
	vScanDocumentObj = pScanDocument.GetObject();
	vScanPicturesRow = Undefined;
	For Each vRow In pScanDocument.ScanPictures Do
		If TrimAll(vRow.Remarks) = DocumentType Then
			vScanPicturesRow = vRow;
			Break;
		EndIf;
	EndDo;
	If vScanPicturesRow <> Undefined Then
		vScanPicture = vScanPicturesRow.ScanPicture.Get();
		If TypeOf(vScanPicture) = Type("String") Then
			vPicture = New Picture(vScanDocumentObj.pmGetImageCatalogName(vScanPicturesRow) + TrimAll(vScanPicture));
		Else
			vPicture = vScanPicture;
		EndIf;
		DocPicture = PutToTempStorage(vPicture);
	EndIf;
EndProcedure // OpenPictureAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenPicture()
	If GuestRowID >= 0 And Not IsBlankString(DocumentType) Then
		vRowData = RoomGuests.FindByID(GuestRowID);
		If ValueIsFilled(vRowData.GuestDataScans) Then
			OpenPictureAtServer(vRowData.GuestDataScans);
		EndIf;
	EndIf;
	Items.GroupPicture.Visible = True;
EndProcedure // OpenPicture

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearPictureAtServer(pScansDoc)
	vScansDocObj = pScansDoc.GetObject();
	vRow = vScansDocObj.ScanPictures.Find(DocumentType, "Remarks");
	If vRow <> Undefined Then
		vScansDocObj.ScanPictures.Delete(vRow);
		vScansDocObj.Write(DocumentWriteMode.Posting);
	EndIf;
EndProcedure // ClearPictureAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetClientIdentificationCardById(pIdentifier, pUseDeleted = False) 
    Return cmGetClientIdentificationCardById(pIdentifier);
EndFunction // cmGetClientIdentificationCardById

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False) 
	Return cmGetDiscountCardById(pIdentifier);
EndFunction // cmGetDiscountCardById

// -----------------------------------------------------------------------------
&AtServer
Function GetFName(pCard) 
	Return pCard.Client.FullName;
EndFunction // cmGetDiscountCardById

// -----------------------------------------------------------------------------
&AtServer
Function GetClient(pCard) 
	Return pCard.Client;
EndFunction // cmGetDiscountCardById

// ----------------------------------------------------------------------------- 
&AtServer
Function Transliterate(Val pStr)
	vStr = TrimAll(pStr);
	// Get string current language
	vIsInRussian = True;
	vEnABC = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	For i = 1 To StrLen(vEnABC) Do
		vC = Mid(vEnABC, i, 1);
		If Find(vEnABC, vC) > 0 Then
			vIsInRussian = False;
			Break;
		EndIf;
	EndDo;
	vStr = StrReplace(vStr, "А", "A");
	vStr = StrReplace(vStr, "а", "a");
	vStr = StrReplace(vStr, "Б", "B");
	vStr = StrReplace(vStr, "б", "b");
	vStr = StrReplace(vStr, "В", "V");
	vStr = StrReplace(vStr, "в", "v");
	vStr = StrReplace(vStr, "Г", "G");
	vStr = StrReplace(vStr, "г", "g");
	vStr = StrReplace(vStr, "Д", "D");
	vStr = StrReplace(vStr, "д", "d");
	vStr = StrReplace(vStr, "Е", "E");
	vStr = StrReplace(vStr, "е", "e");
	vStr = StrReplace(vStr, "Ё", "E");
	vStr = StrReplace(vStr, "ё", "e");
	vStr = StrReplace(vStr, "Ж", "Gh");
	vStr = StrReplace(vStr, "ж", "gh");
	vStr = StrReplace(vStr, "З", "Z");
	vStr = StrReplace(vStr, "з", "z");
	vStr = StrReplace(vStr, "И", "I");
	vStr = StrReplace(vStr, "и", "i");
	vStr = StrReplace(vStr, "Й", "Y");
	vStr = StrReplace(vStr, "й", "y");
	vStr = StrReplace(vStr, "К", "K");
	vStr = StrReplace(vStr, "к", "k");
	vStr = StrReplace(vStr, "Л", "L");
	vStr = StrReplace(vStr, "л", "l");
	vStr = StrReplace(vStr, "М", "M");
	vStr = StrReplace(vStr, "м", "m");
	vStr = StrReplace(vStr, "Н", "N");
	vStr = StrReplace(vStr, "н", "n");
	vStr = StrReplace(vStr, "О", "O");
	vStr = StrReplace(vStr, "о", "o");
	vStr = StrReplace(vStr, "П", "P");
	vStr = StrReplace(vStr, "п", "p");
	vStr = StrReplace(vStr, "Р", "R");
	vStr = StrReplace(vStr, "р", "r");
	vStr = StrReplace(vStr, "С", "S");
	vStr = StrReplace(vStr, "с", "s");
	vStr = StrReplace(vStr, "Т", "T");
	vStr = StrReplace(vStr, "т", "t");
	vStr = StrReplace(vStr, "У", "U");
	vStr = StrReplace(vStr, "у", "u");
	vStr = StrReplace(vStr, "Ф", "F");
	vStr = StrReplace(vStr, "ф", "f");
	vStr = StrReplace(vStr, "Х", "H");
	vStr = StrReplace(vStr, "х", "h");
	vStr = StrReplace(vStr, "Ц", "C");
	vStr = StrReplace(vStr, "ц", "c");
	vStr = StrReplace(vStr, "Ч", "Ch");
	vStr = StrReplace(vStr, "ч", "ch");
	vStr = StrReplace(vStr, "Ш", "Sh");
	vStr = StrReplace(vStr, "ш", "sh");
	vStr = StrReplace(vStr, "Щ", "Sch");
	vStr = StrReplace(vStr, "щ", "sch");
	vStr = StrReplace(vStr, "Ь", "");
	vStr = StrReplace(vStr, "ь", "");
	vStr = StrReplace(vStr, "Ы", "Yi");
	vStr = StrReplace(vStr, "ы", "yi");
	vStr = StrReplace(vStr, "Ъ", "");
	vStr = StrReplace(vStr, "ъ", "");
	vStr = StrReplace(vStr, "Э", "E");
	vStr = StrReplace(vStr, "э", "e");
	vStr = StrReplace(vStr, "Ю", "Yu");
	vStr = StrReplace(vStr, "ю", "yu");
	vStr = StrReplace(vStr, "Я", "Ya");
	vStr = StrReplace(vStr, "я", "ya");
	Return vStr;
EndFunction // Transliterate

#EndRegion