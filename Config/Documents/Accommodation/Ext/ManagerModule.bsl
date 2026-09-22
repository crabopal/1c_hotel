
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure PresentationGetProcessing(pData, pPresentation, pStandardProcessing)
	vRef = pData.Ref;
	If ValueIsFilled(vRef) And vRef.Posted Then
		vGuest = vRef.Guest;
		vRoom = vRef.Room;
		vRoomType = vRef.RoomType;
		vStatus = vRef.AccommodationStatus;
		pPresentation = NStr("en='N'; ru='№'; de='N'") + TrimAll(pData.Number);
		If vStatus.IsActive And Not vStatus.IsInHouse Then
			pPresentation = pPresentation + NStr("en = ' Check-out'; ru = ' Выезд'; de = ' Check-out'");
		Else
			pPresentation = pPresentation + NStr("en = ' Check-in'; ru = ' Размещ.'; de = ' Check-in'");
		EndIf;
		pPresentation = pPresentation + ?(ValueIsFilled(vGuest), " " + Trimall(vGuest.FullName), "") + 
		NStr("en = ' from '; ru = ' c '; de = ' ab '") + Format(vRef.CheckInDate, "DF=dd.MM.yyyy") + 
		?(ValueIsFilled(vRoom), " " + TrimAll(vRoom.Description), "") + 
		?(ValueIsFilled(vRoomType), " " + TrimAll(vRoomType.Code), "");
		pStandardProcessing = False;
	EndIf;
EndProcedure // PresentationGetProcessing

// -----------------------------------------------------------------------------
Function GetResortFeeServiceSum(pDocument)
	vQuantity = 0;
	vPrice = 0;
	vService = Undefined;
	For Each vSrvRow In pDocument.Services Do
		If ValueIsFilled(vSrvRow.Service) And ValueIsFilled(vSrvRow.Service.QuantityCalculationRule) And 
		  (vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
		   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or 
		   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022) Then
			vQuantity = vQuantity+vSrvRow.Quantity;
			vService = vSrvRow.Service;
		EndIf;
	EndDo;
	If ValueIsFilled(vService) Then 
		vServicePrices = vService.GetObject().pmGetServicePrices(pDocument.Hotel);
		If vServicePrices.Count() > 0 Then
			vPrice = vServicePrices.Get(0).Price;
		EndIf;

	EndIf;
	vSum = Round(vQuantity*vPrice);
	Return vSum;
EndFunction // GetResortFeeService

// -----------------------------------------------------------------------------
Procedure FormGetProcessing(pFormType, pParameters, pSelectedForm, pAdditionalInformation, pStandardProcessing)
	SetPrivilegedMode(True);
	vCurSession = GetCurrentInfoBaseSession();
	SetPrivilegedMode(False);
	vSessionNumber = vCurSession.SessionNumber;
	vSessionStartTime = vCurSession.SessionStarted;
	vAppRunMode = CachedCommonFunctions.cmGetAppRunMode(vSessionNumber, vSessionStartTime);
	If vAppRunMode.MobileDeviceMode Then 
		If pFormType = "ObjectForm" Or pSelectedForm = "tcDocumentForm" Then
			pStandardProcessing = False;
			pSelectedForm = "mcDocumentForm";
		EndIf; 
	EndIf;
EndProcedure // FormGetProcessing

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure PrintGuestPersonalDataProcessingConsent(pArrDocument, pSpreadsheet, pTemplate, pObjectPrintForm, rDoPrint = Undefined, pNoSignature = False, pEmployee = Undefined) Export 
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	Else
		vTemplate = pTemplate;
	EndIf;
	
	n = 0;
	For Each vStr In pArrDocument Do
		n = n + 1;
		
		pDocument = vStr.Value;
		
		vHotel = Undefined;
		vCompany = Undefined;
		vGuest = Undefined;
		vLanguage = Undefined;
		
		vParameters = FillPersonalDataConsentParameters(pDocument, vHotel, vCompany, vGuest, vLanguage);
		
		If ValueIsFilled(vLanguage) Then
			vTemplate.LanguageCode = Lower(vLanguage.Code);
		EndIf;	
		// Next page if necessary
		If n > 1 Then
			pSpreadsheet.PutHorizontalPageBreak();
		EndIf;	
		
		vHeader = vTemplate.GetArea("Application");
			
		// Fill printing area parameters
		FillPropertyValues(vHeader.Parameters, vParameters);
		
		// Put consent for a guest
		pSpreadsheet.Put(vHeader);
		
		// Create personal data consent document
		If ValueIsFilled(vHotel.AgreementText) And ValueIsFilled(vGuest) Then
			If BegOfDay(pDocument.CheckOutDate) >= BegOfDay(CurrentSessionDate()) Then
				vConsentDocRef = GetGuestConsentDocForToday(vGuest);
				If ValueIsFilled(vConsentDocRef) Then
					vConsentDocObj = vConsentDocRef.GetObject();
				Else
					vConsentDocObj = Documents.PersonalDataProcessingConsent.CreateDocument();
					vConsentDocObj.Hotel = vHotel;
				EndIf;
				vConsentDocObj.Fill(vGuest);
				vConsentDocObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
	
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current report
			vFilter = New Structure("ObjectPrintingForm, IsActive", pObjectPrintForm, True);
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(pSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings);
						cmDoSpreadsheetOutput(pSpreadsheet, vPrintSettings, vName, , rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Procedure PrintGuestRefusalToPayResortFee(pArrDocument, pSpreadsheet, pTemplate, pObjectPrintForm, rDoPrint = Undefined) Export 
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	Else
		vTemplate = pTemplate;
	EndIf;
	
	n = 0;
	For Each vStr In pArrDocument Do
		
		n = n +1;
		
		pDocument = vStr.Value;
		
		vHotel = Undefined;
		vCompany = Undefined;
		vGuest = Undefined;
		vLanguage = Undefined;
		
		vParameters = FillPersonalDataConsentParameters(pDocument, vHotel, vCompany, vGuest, vLanguage);
		
		If ValueIsFilled(vLanguage) Then
			vTemplate.LanguageCode = Lower(vLanguage.Code);
		EndIf;
		
		vParameters.Insert("mMinResort");

		vParameters.Insert("mSum");
		vParameters.Insert("mSumInWords");

		vObjReport = Reports.ResortFeeOperatorReport.Create();
		vObjReport.Report = Catalogs.Reports.FindByAttribute("Report", "ResortFeeOperatorReport");
		If ValueIsFilled(vObjReport.Report) Then
			vObjReport.pmLoadReportAttributes();
			vParameters.mMinResort = vObjReport.SupplementText;
		Else
			vParameters.mMinResort = "";
		EndIf;
		
		vSum = GetResortFeeServiceSum(pDocument);
		vParameters.mSum = Format(vSum, "ND=17; NFD=0");
		vParameters.mSumInWords = cmSumInWords(vSum, vHotel.BaseCurrency, vLanguage); 
		
		If n>1 Then
			pSpreadsheet.PutHorizontalPageBreak();
		EndIf;	
		
		vRefusal = vTemplate.GetArea("Refusal");
		FillPropertyValues(vRefusal.Parameters, vParameters);
		pSpreadsheet.Put(vRefusal);
		
		pSpreadsheet.PutHorizontalPageBreak();
		
		vApplication = vTemplate.GetArea("Application");
		FillPropertyValues(vApplication.Parameters, vParameters);
		pSpreadsheet.Put(vApplication);
	EndDo;
	
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current report
			vFilter = New Structure("ObjectPrintingForm, IsActive", pObjectPrintForm, True);
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(pSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings);
						cmDoSpreadsheetOutput(pSpreadsheet, vPrintSettings, vName, , rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintGuestRefusalToPayResortFee

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
Function GetGuestConsentDocForToday(pGuest) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PersonalDataProcessingConsent.Ref AS Ref
	|FROM
	|	Document.PersonalDataProcessingConsent AS PersonalDataProcessingConsent
	|WHERE
	|	NOT PersonalDataProcessingConsent.DeletionMark
	|	AND PersonalDataProcessingConsent.Client = &qClient
	|	AND PersonalDataProcessingConsent.Date >= &qPeriodFrom
	|	AND PersonalDataProcessingConsent.Date <= &qPeriodTo
	|
	|ORDER BY
	|	PersonalDataProcessingConsent.PointInTime DESC";
	vQry.SetParameter("qClient", pGuest);
	vQry.SetParameter("qPeriodFrom", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qPeriodTo", EndOfDay(CurrentSessionDate()));
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		Return vDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetGuestConsentDocForToday

// -----------------------------------------------------------------------------
Function FillPersonalDataConsentParameters(pDocument, rHotel, rCompany, rGuest, rLanguage, pUseShort = False) Export
	vParameters = New Structure;
	vParameters.Insert("mHotelName");
	
	vParameters.Insert("mCompanyName");
	vParameters.Insert("mCompanyOGRN");
	vParameters.Insert("mCompanyTIN");
	vParameters.Insert("mCompanyKPP");
	vParameters.Insert("mCompanyVATCode");
	vParameters.Insert("mCompanyAddress");

	vParameters.Insert("mDirectorName");
	vParameters.Insert("mDirectorInDativeName");
	vParameters.Insert("mDirectorPosition");
	vParameters.Insert("mDirectorPositionInDative");
	vParameters.Insert("mDirectorInGenitive");
	
	vParameters.Insert("mGuest");
	vParameters.Insert("mGuestName");
	vParameters.Insert("mGuestDateOfBirth");
	vParameters.Insert("mDocumentType");
	vParameters.Insert("mGuestIDSeries");
	vParameters.Insert("mGuestIDNumber");
	vParameters.Insert("mGuestAddress");
	vParameters.Insert("mGuestPhone");

	vParameters.Insert("mIDIssuedBy");
	vParameters.Insert("mIDIssueDate");
	
	vParameters.Insert("mCheckInDate");
	vParameters.Insert("mCheckOutDate");
	
	vParameters.Insert("mDate");
	
	vParameters.Insert("mEmployeePosition");
	vParameters.Insert("mEmployeeName");
	
	vParameters.Insert("mConsentText");
	
	// Fill parameters
	rHotel = Undefined;
	If ValueIsFilled(pDocument) Then
		If ValueIsFilled(pDocument.Hotel) Then
			rHotel = pDocument.Hotel;
		EndIf;
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		rHotel = SessionParameters.CurrentHotel;
	EndIf;
	
	rCompany = Undefined;
	If ValueIsFilled(pDocument) Then
		If ValueIsFilled(pDocument.Company) Then
			rCompany = pDocument.Company;
		EndIf;
	ElsIf ValueIsFilled(rHotel) Then
		rCompany = rHotel.Company;
	EndIf;
	
	rLanguage = Catalogs.Languages.RU;
	If ValueIsFilled(rHotel) Then
		rLanguage = rHotel.Language;
	EndIf;
	
	rGuest = pDocument.Guest;
	If ValueIsFilled(rGuest) And ValueIsFilled(rGuest.Language) Then
		rLanguage = rGuest.Language;	
	EndIf;	
	If ValueIsFilled(rHotel) Then
		// Hotel name
		vHotelName = TrimAll(rHotel.LegacyName);
		If IsBlankString(vHotelName) Then
			vHotelName = TrimAll(rHotel.Description);
		EndIf;
		vParameters.mHotelName = vHotelName;

		// Date in hotel language			
		vParameters.mDate = Format(CurrentSessionDate(), "L=" + lower(rLanguage.Code) + "; DLF=DD");
	EndIf;
	
	If ValueIsFilled(rCompany) And ValueIsFilled(rHotel) Then
		// Company name
		vCompanyName = TrimAll(rCompany.LegacyName);
		If IsBlankString(vCompanyName) Then
			vCompanyName = TrimAll(rCompany.Description);
		EndIf;
		vParameters.mCompanyName = vCompanyName;
		vParameters.mCompanyTIN = TrimAll(rCompany.TIN);
		vParameters.mCompanyKPP = TrimAll(rCompany.KPP);
		vParameters.mCompanyVATCode = TrimAll(rCompany.VATC);
		vParameters.mCompanyOGRN = TrimAll(rCompany.OGRN);
		
		// Company address
		If Not IsBlankString(rCompany.LegacyAddressTranslations) Then
			vParameters.mCompanyAddress = cmNStr(rCompany.LegacyAddressTranslations, rLanguage);
		Else
			vParameters.mCompanyAddress = TrimAll(rCompany.LegacyAddress);
		EndIf;
		
		// Company parameters
		vParameters.mDirectorName = cmNStr(rCompany.Director, rLanguage);
		vParameters.mDirectorInGenitive = cmNStr(rCompany.DirectorInGenitive, rLanguage);
		If IsBlankString(vParameters.mDirectorInGenitive) Then
			vParameters.mDirectorInGenitive = vParameters.mDirectorName;
		EndIf;
		vParameters.mDirectorInDativeName = cmNStr(rCompany.DirectorInDative, rLanguage);
		If IsBlankString(vParameters.mDirectorInDativeName) Then
			vParameters.mDirectorInDativeName = vParameters.mDirectorName;
		EndIf;
		
		// Director position
		If IsBlankString(rCompany.DirectorPosition) Then
			vParameters.mDirectorPosition = "";
		Else
			vParameters.mDirectorPosition = cmNStr(rCompany.DirectorPosition, rLanguage);
		EndIf;  
		
		// Director position in dative
		If IsBlankString(rCompany.DirectorPositionInDative) Then
			vParameters.mDirectorPositionInDative = "";
		Else
			vParameters.mDirectorPositionInDative = cmNStr(rCompany.DirectorPositionInDative, rLanguage);
		EndIf;
	EndIf;
	
	If ValueIsFilled(rGuest) Then
		// Guest name
		vParameters.mGuest = TrimAll(rGuest.LastName) + " " + Left(TrimAll(rGuest.FirstName), 1) + ". " + Left(TrimAll(rGuest.SecondName), 1) + ". ";
		vParameters.mGuestName = TrimAll(TrimAll(rGuest.LastName) + " " + 
		                                 TrimAll(rGuest.FirstName) + " " + 
		                                 TrimAll(rGuest.SecondName));
										 
		// Guest date of birth
		vParameters.mGuestDateOfBirth = Format(rGuest.DateOfBirth, "DF=dd.MM.yyyy");
		
		// Guest identity document data    
		vParameters.mDocumentType = TrimAll(rGuest.IdentityDocumentType);
		vParameters.mGuestIDSeries = TrimAll(rGuest.IdentityDocumentSeries);
		vParameters.mGuestIDNumber = TrimAll(rGuest.IdentityDocumentNumber);
		vParameters.mIDIssueDate = Format(rGuest.IdentityDocumentIssueDate, "DF=dd.MM.yyyy");
		vParameters.mIDIssuedBy = TrimAll(rGuest.IdentityDocumentIssuedBy);
		
		// Guest phone
		vParameters.mGuestPhone = TrimAll(rGuest.Phone);
		
		// Guest address
		vGuestAddress = cmParseAddress(rGuest.Address);
		vParameters.mGuestAddress = cmGetAddressPresentation(" " + vGuestAddress.PostCode + ", " + vGuestAddress.Region + ", " +
		                                                     vGuestAddress.Area + ", " + vGuestAddress.City + ", " + 
		                                                     vGuestAddress.Street + ", " + vGuestAddress.House + ", " + vGuestAddress.Flat);
	EndIf;

	vParameters.mEmployeeName = SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(rLanguage);
	vParameters.mEmployeePosition = cmNStr("en='Manager'; ru='Администратор'; de='Manager'", rLanguage);
	If Not IsBlankString(SessionParameters.CurrentUser.Position) Then
		vParameters.mEmployeePosition = cmNStr(TrimAll(SessionParameters.CurrentUser.Position), rLanguage);
	EndIf;
	
	// Guest check in and check out dates
	vParameters.mCheckInDate = Format(pDocument.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
	vParameters.mCheckOutDate = Format(pDocument.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
	
	// Consent text
	vParameters.mConsentText = "";
	If pUseShort Then
		If ValueIsFilled(rHotel.AgreementText) And 
		   Not IsBlankString(rHotel.AgreementText.ShortAgreementText) Then
			vParameters.mConsentText = cmNStr(rHotel.AgreementText.ShortAgreementText, rLanguage);
		Else
			vParameters.mConsentText = cmNStr("en = '	I, [mGuestName], ID No. [mGuestIDSeries] [mGuestIDNumber], issue date [mIDIssueDate], confirm my consent to the processing (any action (operation) or set of actions (operations) performed with or without the use of automation tools with personal data, including the collection, recording, systematization, accumulation, storage, clarification (updating, modification), retrieval, use, transfer (distribution, provision, access), depersonalization, blocking, deletion, and destruction of personal data) [mCompanyName] (hereinafter referred to as the Operator) will process my personal data, including my last name, first name, patronymic, date of birth, age, registered address, passport information (passport series and number, date of issue), contact phone number, purpose of visit, and length of stay at the Hotel, in order to comply with the requirements of state and regional regulations.
                                               | This consent is valid for 3 years from the date of signing and may be revoked by the data subject.'; de = '	Ich, [mGuestName], ID Nummer [mGuestIDSeries] [mGuestIDNumber], Ausstellungsdatum [mIDIssueDate], meine Einwilligung zur Verarbeitung (jegliche Handlung oder Reihe von Handlungen, die mit oder ohne Verwendung von automatisierten Verfahren mit personenbezogenen Daten durchgeführt werden, einschließlich Erhebung, Speicherung, Systematisierung, Anhäufung, Aufbewahrung, Aktualisierung, Änderung, Abruf, Verwendung, Übermittlung (Verbreitung, Bereitstellung, Zugriff), Anonymisierung, Sperrung, Löschung und Vernichtung personenbezogener Daten) [mCompanyName] (nachfolgend „Betreiber“ genannt) verarbeitet meine personenbezogenen Daten, einschließlich Nachname, Vorname, Vatersname, Geburtsdatum, Alter, Meldeadresse, Passdaten (Passserie und -nummer, Ausstellungsdatum), Telefonnummer, Reisezweck und Aufenthaltsdauer in der Unterkunft, um den Anforderungen der Staat und regionalen Vorschriften zu entsprechen. Diese Einwilligung gilt drei Jahre ab dem Datum der Unterzeichnung und kann von der betroffenen Person widerrufen werden.'; ru = '	Я, [mGuestName] паспорт серия [mGuestIDSeries] № [mGuestIDNumber], выдан [mIDIssuedBy], дата выдачи [mIDIssueDate], проживающий/ая по адресу [mGuestAddress], в соответствии с требованиями статьи 9 Федерального закона от 27 июля 2006 года № 152-ФЗ «О персональных данных», подтверждаю своё согласие на обработку (любое действие (операция) или совокупность действий (операций), совершаемых с использованием средств автоматизации или без использования таких средств с персональными данными, включая сбор, запись, систематизацию, накопление, хранение, уточнение (обновление, изменение), извлечение, использование, передачу (распространение, предоставление, доступ), обезличивание, блокирование, удаление, уничтожение персональных данных) [mCompanyName] (далее – Оператор), моих персональных данных, включающих фамилию, имя, отчество, дату рождения, возраст, адрес регистрации по месту жительства, паспортные данные (серия и номер паспорта, кем выдан, дата выдачи), контактный телефон, цель визита и период пребывания в объекте размещения с целью исполнения требований нормативных правовых актов Российской Федерации, нормативных правовых актов регионального уровня.
                                               |	Настоящее согласие действует 3 года со дня его подписания, а также может быть отозвано субъектом персональных данных.'", 
			                                  rLanguage);
		EndIf;
	EndIf;
	If IsBlankString(vParameters.mConsentText) Then
		If ValueIsFilled(rHotel.AgreementText) And 
		   Not IsBlankString(rHotel.AgreementText.AgreementText) Then
			vParameters.mConsentText = cmNStr(rHotel.AgreementText.AgreementText, rLanguage);
		Else
			vParameters.mConsentText = cmNStr("en = '	I, [mGuestName], ID No. [mGuestIDSeries] [mGuestIDNumber], issue date [mIDIssueDate], confirm my consent to the processing (any action (operation) or set of actions (operations) performed with or without the use of automation tools with personal data, including the collection, recording, systematization, accumulation, storage, clarification (updating, modification), retrieval, use, transfer (distribution, provision, access), depersonalization, blocking, deletion, and destruction of personal data) [mCompanyName] (hereinafter referred to as the Operator) will process my personal data, including my last name, first name, patronymic, date of birth, age, registered address, passport information (passport series and number, date of issue), contact phone number, purpose of visit, and length of stay at the Hotel, in order to comply with the requirements of state and regional regulations.
                                               | This consent is valid for 3 years from the date of signing and may be revoked by the data subject.'; de = '	Ich, [mGuestName], ID Nummer [mGuestIDSeries] [mGuestIDNumber], Ausstellungsdatum [mIDIssueDate], meine Einwilligung zur Verarbeitung (jegliche Handlung oder Reihe von Handlungen, die mit oder ohne Verwendung von automatisierten Verfahren mit personenbezogenen Daten durchgeführt werden, einschließlich Erhebung, Speicherung, Systematisierung, Anhäufung, Aufbewahrung, Aktualisierung, Änderung, Abruf, Verwendung, Übermittlung (Verbreitung, Bereitstellung, Zugriff), Anonymisierung, Sperrung, Löschung und Vernichtung personenbezogener Daten) [mCompanyName] (nachfolgend „Betreiber“ genannt) verarbeitet meine personenbezogenen Daten, einschließlich Nachname, Vorname, Vatersname, Geburtsdatum, Alter, Meldeadresse, Passdaten (Passserie und -nummer, Ausstellungsdatum), Telefonnummer, Reisezweck und Aufenthaltsdauer in der Unterkunft, um den Anforderungen der Staat und regionalen Vorschriften zu entsprechen. Diese Einwilligung gilt drei Jahre ab dem Datum der Unterzeichnung und kann von der betroffenen Person widerrufen werden.'; ru = '	Я, [mGuestName] паспорт серия [mGuestIDSeries] № [mGuestIDNumber], выдан [mIDIssuedBy], дата выдачи [mIDIssueDate], проживающий/ая по адресу [mGuestAddress], в соответствии с требованиями статьи 9 Федерального закона от 27 июля 2006 года № 152-ФЗ «О персональных данных», подтверждаю своё согласие на обработку (любое действие (операция) или совокупность действий (операций), совершаемых с использованием средств автоматизации или без использования таких средств с персональными данными, включая сбор, запись, систематизацию, накопление, хранение, уточнение (обновление, изменение), извлечение, использование, передачу (распространение, предоставление, доступ), обезличивание, блокирование, удаление, уничтожение персональных данных) [mCompanyName] (далее – Оператор), моих персональных данных, включающих фамилию, имя, отчество, дату рождения, возраст, адрес регистрации по месту жительства, паспортные данные (серия и номер паспорта, кем выдан, дата выдачи), контактный телефон, цель визита и период пребывания в объекте размещения с целью исполнения требований нормативных правовых актов Российской Федерации, нормативных правовых актов регионального уровня.
                                               |	Настоящее согласие действует 3 года со дня его подписания, а также может быть отозвано субъектом персональных данных.'", 
			                                  rLanguage);
		EndIf;
	EndIf;
	
	// Fill text parameters
	For Each vParameter In vParameters Do
		vParameters.mConsentText = StrReplace(vParameters.mConsentText, "[" + vParameter.Key + "]", TrimAll(vParameter.Value));
	EndDo;

	Return vParameters;
EndFunction // FillPersonalDataConsentParameters

#EndRegion
