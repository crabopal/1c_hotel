
#Region Public

#Region TypeDescriptions

// -----------------------------------------------------------------------------
Function cmGetObjectTypeDescription(pObj) Export
	vTypes = New Array();
	vTypes.Add(TypeOf(pObj));
	Return New TypeDescription(vTypes);
EndFunction // cmGetObjectTypeDescription

// -----------------------------------------------------------------------------
Function cmGetQuantityTypeDescription() Export
	vNQ = New NumberQualifiers(19, 7);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetQuantityTypeDescription

// -----------------------------------------------------------------------------
Function cmGetSumTypeDescription() Export
	vNQ = New NumberQualifiers(17, 2);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetSumTypeDescription

// -----------------------------------------------------------------------------
Function cmGetNumberTypeDescription(pTotalDigits, pDecDigits, pNonnegative = False) Export
	If pNonnegative Then
		vNQ = New NumberQualifiers(pTotalDigits, pDecDigits, AllowedSign.Nonnegative);
	Else
		vNQ = New NumberQualifiers(pTotalDigits, pDecDigits);
	EndIf;
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetNumberTypeDescription

// -----------------------------------------------------------------------------
Function cmGetNumberAndStringTypeDescription(pTotalDigits, pDecDigits) Export
	vNQ = New NumberQualifiers(pTotalDigits, pDecDigits);
	vTA = New Array;
	vTA.Add(Type("String"));
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetNumberAndStringTypeDescription

// -----------------------------------------------------------------------------
Function cmGetCatalogTypeDescription(pCatalog) Export
	vTA = New Array;
	vTA.Add(Type("CatalogRef." + pCatalog));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetCatalogTypeDescription

// -----------------------------------------------------------------------------
Function cmGetDocumentTypeDescription(pDocument) Export
	vTA = New Array;
	vTA.Add(Type("DocumentRef." + pDocument));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetDocumentTypeDescription

// -----------------------------------------------------------------------------
Function cmGetDateTimeTypeDescription() Export
	vDQ = New DateQualifiers(DateFractions.DateTime);
	vTA = New Array;
	vTA.Add(Type("Date"));
	vTypeDescr = New TypeDescription(vTA, , , vDQ);
	Return vTypeDescr;
EndFunction // cmGetDateTimeTypeDescription

// -----------------------------------------------------------------------------
Function cmGetDateTypeDescription() Export
	vDQ = New DateQualifiers(DateFractions.Date);
	vTA = New Array;
	vTA.Add(Type("Date"));
	vTypeDescr = New TypeDescription(vTA, , , vDQ);
	Return vTypeDescr;
EndFunction // cmGetDateTypeDescription

// -----------------------------------------------------------------------------
Function cmGetTimeTypeDescription() Export
	vDQ = New DateQualifiers(DateFractions.Time);
	vTA = New Array;
	vTA.Add(Type("Date"));
	vTypeDescr = New TypeDescription(vTA, , , vDQ);
	Return vTypeDescr;
EndFunction // cmGetTimeTypeDescription

// -----------------------------------------------------------------------------
Function cmGetBooleanTypeDescription() Export
	vTA = New Array;
	vTA.Add(Type("Boolean"));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetBooleanTypeDescription

// -----------------------------------------------------------------------------
Function cmGetNumberOfPersonsTypeDescription() Export
	vNQ = New NumberQualifiers(6, 0);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetNumberOfPersonsTypeDescription

// -----------------------------------------------------------------------------
Function cmGetLineNumberTypeDescription() Export
	vNQ = New NumberQualifiers(4, 0);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetLineNumberTypeDescription

// -----------------------------------------------------------------------------
Function cmGetExchangeRateTypeDescription() Export
	vNQ = New NumberQualifiers(19, 7);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetExchangeRateTypeDescription

// -----------------------------------------------------------------------------
Function cmGetDiscountTypeDescription() Export
	vNQ = New NumberQualifiers(6, 2);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetDiscountTypeDescription

// -----------------------------------------------------------------------------
Function cmGetStringTypeDescription(pLength = 0, pAllowedLength = Undefined) Export
	If pLength <> 0 Then
		If pAllowedLength <> Undefined Then
			vSQ = New StringQualifiers(pLength, pAllowedLength);
		Else
			vSQ = New StringQualifiers(pLength);
		EndIf;
		vTA = New Array;
		vTA.Add(Type("String"));
		vTypeDescr = New TypeDescription(vTA, , vSQ);
	Else
		vTA = New Array;
		vTA.Add(Type("String"));
		vTypeDescr = New TypeDescription(vTA);
	EndIf;
	Return vTypeDescr;
EndFunction // cmGetStringTypeDescription

// -----------------------------------------------------------------------------
Function cmGetValueStorageTypeDescription() Export
	vTA = New Array;
	vTA.Add(Type("ValueStorage"));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetValueStorageTypeDescription

// -----------------------------------------------------------------------------
Function cmGetConfirmationTextTypeDescription() Export
	vSQ = New StringQualifiers(100);
	vTA = New Array;
	vTA.Add(Type("String"));
	vTypeDescr = New TypeDescription(vTA, , vSQ);
	Return vTypeDescr;
EndFunction // cmGetConfirmationTextTypeDescription

// -----------------------------------------------------------------------------
Function cmGetAgentCommissionTypeDescription() Export
	vNQ = New NumberQualifiers(6, 2);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetAgentCommissionTypeDescription

// -----------------------------------------------------------------------------
Function cmGetEnumTypeDescription(pEnum) Export
	vTA = New Array;
	vTA.Add(Type("EnumRef." + pEnum));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetEnumTypeDescription

// -----------------------------------------------------------------------------
Function cmGetSortCodeTypeDescription() Export
	vNQ = New NumberQualifiers(8, 0);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetSortCodeTypeDescription

// -----------------------------------------------------------------------------
Function cmGetMaxSortCodeValue() Export
	Return 99999999;
EndFunction // cmGetMaxSortCodeValue

// -----------------------------------------------------------------------------
Function cmGetCatalogCodeTypeDescription() Export
	vSQ = New StringQualifiers(5);
	vTA = New Array;
	vTA.Add(Type("String"));
	vTypeDescr = New TypeDescription(vTA, , vSQ);
	Return vTypeDescr;
EndFunction // cmGetCatalogCodeTypeDescription

// -----------------------------------------------------------------------------
Function cmGetObjectsTypeDescription() Export
	vTA = New Array;
	For Each vCat In Metadata.Catalogs Do
		vTA.Add(Type("CatalogRef." + vCat.Name));
	EndDo;
	For Each vDoc In Metadata.Documents Do
		vTA.Add(Type("DocumentRef." + vDoc.Name));
	EndDo;
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetObjectsTypeDescription

// -----------------------------------------------------------------------------
Function cmGetObjectTemplatesTypeDescription() Export
	vTA = New Array;
	vTA.Add(cmGetDocumentTypeDescription("Accommodation"));
	vTA.Add(cmGetDocumentTypeDescription("Reservation"));
	vTA.Add(cmGetDocumentTypeDescription("ResourceReservation"));
	vTA.Add(cmGetDocumentTypeDescription("Folio"));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetObjectTemplatesTypeDescription

// -----------------------------------------------------------------------------
Function cmGetDayOfWeekShortNameTypeDescription() Export
	vSQ = New StringQualifiers(2);
	vTA = New Array;
	vTA.Add(Type("String"));
	vTypeDescr = New TypeDescription(vTA, , vSQ);
	Return vTypeDescr;
EndFunction // cmGetDayOfWeekShortNameTypeDescription

#EndRegion

// -----------------------------------------------------------------------------
// Description: Creates external data processor object
// Parameters: External data processor catalog item
// Return value: Data processor object
// -----------------------------------------------------------------------------
Function cmGetExternalDataProcessorObject(pExternalDataProcessorRef) Export
	// Retrieve binary data
	vDPBinary = pExternalDataProcessorRef.ExternalProcessingStorage.Get();
	If vDPBinary = Undefined Then
		Return vDPBinary;
	EndIf;	
	// Save it to the temp file 
	vNewUUID = New UUID();
	vTmpFileName = TempFilesDir() + String(vNewUUID);
	vDPBinary.Write(vTmpFileName);
	// Create processor object from the file and delete temp file
	If pExternalDataProcessorRef.ExternalProcessingType = Enums.ExternalProcessingTypes.DataProcessor Then
		vDPObj = ExternalDataProcessors.Create(vTmpFileName, False);
		DeleteFiles(vTmpFileName);
		Return vDPObj;
	ElsIf pExternalDataProcessorRef.ExternalProcessingType = Enums.ExternalProcessingTypes.Report Then
		vRepObj = ExternalReports.Create(vTmpFileName, False);
		DeleteFiles(vTmpFileName);
		Return vRepObj;
	EndIf;
	Return Undefined;
EndFunction // cmGetExternalDataProcessorObject

// -----------------------------------------------------------------------------
// Description: Loads external data processor object and opens it's default form
// Parameters: External data processor catalog item, Parameter object, 
//             Object printing form, Data processor's form owner
// Return value: True if data processor's form was successfully opened, false if 
//               any exception was raised
// -----------------------------------------------------------------------------
Function cmLoadExternalDataProcessor(pExtProc, pObj = Undefined, pObjPrintingForm = Undefined, pFormOwner = Undefined) Export
	If ValueIsFilled(pExtProc) Then
		If pExtProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			PARAM = pObj;
			Execute(TrimAll(pExtProc.Algorithm));
		Else
			vExtProcData = pExtProc.ExternalProcessingStorage.Get();
			vExtProcPath = GetTempFileName(".efd");
			vExtProcData.Write(vExtProcPath);
			vExtProcObj = ExternalDataProcessors.Create(vExtProcPath, False);
			vStruct = New Structure("InputParameter, ObjectPrintingForm", pObj, pObjPrintingForm);
			FillPropertyValues(vExtProcObj, vStruct);
			vFrm = vExtProcObj.GetForm();
			vFrmStruct = New Structure("FormOwner", pFormOwner);
			FillPropertyValues(vFrm, vFrmStruct);
			vFrm.CloseOnOwnerClose = False;
			vFrm.Open();
			DeleteFiles(vExtProcPath);
		EndIf;
		Return True;
	EndIf;
	Return False;
EndFunction // cmLoadExternalDataProcessor

// -----------------------------------------------------------------------------
// Description: Loads external spreadsheet template from the object printing form item
// Parameters: Object printing form
// Return value: Spreadsheet template 
// -----------------------------------------------------------------------------
Function cmReadExternalSpreadsheetDocumentTemplate(pObjPrintingForm) Export
	vExtTemplate = Undefined;
	If ValueIsFilled(pObjPrintingForm) Then
		vExtTempData = pObjPrintingForm.ExternalTemplate.Get();
		If vExtTempData <> Undefined Then
			vExtTemplate = New SpreadsheetDocument();
			vExtTempPath = GetTempFileName(".mxl");
			vExtTempData.Write(vExtTempPath);
			vExtTemplate.Read(vExtTempPath);
			vExtTemplate.TemplateLanguageCode = ?(ValueIsFilled(SessionParameters.CurrentLanguage), TrimAll(SessionParameters.CurrentLanguage.Code), "RU");
			DeleteFiles(vExtTempPath);
		EndIf;
	EndIf;
	Return vExtTemplate;
EndFunction // cmReadExternalSpreadsheetDocumentTemplate

// -----------------------------------------------------------------------------
// Description: Returns text according to the current or parameter language.  
//              In comparison to the NStr() function it is simply returns input string if 
//              string format is wrong or language is undefined. NStr() in this case returns empty string
// Parameters: Text string in different languages, Language
// Return value: Text in given language
// -----------------------------------------------------------------------------
Function cmNStr(pStr, pLang = Undefined) Export
	vStr = TrimR(pStr);
	vNStr = "";
	vLangCode = "";
	If pLang = Undefined Then
		vLangCode = "de";
		vNStr = NStr(vStr);
	ElsIf TypeOf(pLang) = Type("CatalogRef.Languages") Then
		vLangCode = lower(TrimAll(pLang.Code));
		vNStr = NStr(vStr, vLangCode);
	Else
		vLangCode = lower(TrimAll(pLang));
		vNStr = NStr(vStr, vLangCode);
	EndIf;

	If IsBlankString(vNStr) Then
		vUseENLang = False;
		vStr = StrReplace(vStr, vLangCode + " = '", vLangCode + "='");
		vStr = StrReplace(vStr, Upper(vLangCode) + " = '", vLangCode + "='");
		vStr = StrReplace(vStr, Upper(vLangCode) + "='", vLangCode + "='");
		vLangPos = StrFind(vStr, vLangCode + "='");
		If vLangPos = 0 Then
			vUseENLang = True;
		EndIf;
		If vUseENLang Then
			vStr = StrReplace(vStr, "en = '", "en='");
			vStr = StrReplace(vStr, "EN = '", "en='");
			vStr = StrReplace(vStr, "EN='", "en='");
			vEnPos = StrFind(vStr, "en='");
			If vEnPos > 0 Then
				vEnText = Mid(vStr, vEnPos + 4);
				vApPos = StrFind(vEnText, "'");
				If vApPos > 0 Then
					vEnText = Left(vEnText, vApPos - 1);
					If Not IsBlankString(vEnText) Then
						vFixedStr = vStr + ";" + vLangCode + "='" + vEnText + "'";
						If pLang = Undefined Then
							vNStr = NStr(vFixedStr);
						Else
							vNStr = NStr(vFixedStr, vLangCode);
						EndIf;
						If Not IsBlankString(vNStr) Then
							Return vNStr;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		Return vStr;
	Else
		Return vNStr;
	EndIf;
EndFunction // cmNStr

// -----------------------------------------------------------------------------
// Description: Returns localization code being currently used. This function will work if 
//              localization code was entered first in the Languages reference.
// Parameters: None
// Return value: String, Localization code for the session current language
// -----------------------------------------------------------------------------
Function cmLocalizationCode() Export
	vLocalizationCode = "";
	If ValueIsFilled(SessionParameters.CurrentLanguage) Then
		If Not IsBlankString(SessionParameters.CurrentLanguage.LocalizationCode) Then
			vLocalizationCode = "L=" + TrimAll(SessionParameters.CurrentLanguage.LocalizationCode);
		EndIf;
	EndIf;
	Return vLocalizationCode;
EndFunction // cmLocalizationCode

// -----------------------------------------------------------------------------
// Description: Returns language reference by language code
// Parameters: Language code
// Return value: Language
// -----------------------------------------------------------------------------
Function cmGetLanguageByCode(pLanguageCode) Export
	vLanguage = Catalogs.Languages.RU;
	If ValueIsFilled(SessionParameters.CurrentLanguage) Then
		vLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	If Not IsBlankString(pLanguageCode) Then
		vLanguageRef = Catalogs.Languages.FindByCode(TrimAll(pLanguageCode));
		If vLanguageRef <> Undefined Then
			vLanguage = vLanguageRef;
		EndIf;
	EndIf;
	Return vLanguage;
EndFunction // cmGetLanguageByCode

// -----------------------------------------------------------------------------
// Description: Checks if string contains russian letters
// Parameters: String to check
// Return value: Boolean. True if string does not contains russian letters 
// -----------------------------------------------------------------------------
Function cmIsInLat(Val pStr) Export
	vHasRussianLetters = False;
	vRussianABC = "ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ";
	pStr = Upper(TrimAll(pStr));
	For i = 1 To StrLen(vRussianABC) Do
		If StrFind(pStr, Mid(vRussianABC, i, 1)) > 0 Then
			vHasRussianLetters = True;
			Break;
		EndIf;
	EndDo;
	Return Not vHasRussianLetters;
EndFunction // cmIsInLat

// -----------------------------------------------------------------------------
// Description: Returns day of week name or short name based on day of week number
// Parameters: Day of week number, Whether to return short or full day of week name
// Return value: String, Day of week name (Monday or Mo, Tuesday or Tu e.t.c.)
// -----------------------------------------------------------------------------
Function cmGetDayOfWeekName(pDayOfWeek, pShort = True, pLanguage = Undefined) Export
	vLanguage = pLanguage;
	If vLanguage = Undefined Then
		vLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	If pDayOfWeek = 1 Then
		If pShort Then
			Return cmNStr("en='mo';ru='пн';de='Mo';lv='Pirm'", vLanguage);
		Else
			Return cmNStr("en='Monday';ru='Понедельник';de='Montag';lv='Pirmdiena'", vLanguage);
		EndIf;
	ElsIf pDayOfWeek = 2 Then
		If pShort Then
			Return cmNStr("en='tu';ru='вт';de='Di';lv='Otr'", vLanguage);
		Else
			Return cmNStr("en='Tuesday';ru='Вторник';de='Dienstag';lv='Otrdiena'", vLanguage);
		EndIf;
	ElsIf pDayOfWeek = 3 Then
		If pShort Then
			Return cmNStr("en='we';ru='ср';de='Mi';lv='Treš'", vLanguage);
		Else
			Return cmNStr("en='Wednesday';ru='Среда';de='Mittwoch';lv='Trešdiena'", vLanguage);
		EndIf;
	ElsIf pDayOfWeek = 4 Then
		If pShort Then
			Return cmNStr("en='th';ru='чт';de='Do';lv='Cet'", vLanguage);
		Else
			Return cmNStr("en='Thursday';ru='Четверг';de='Donnerstag';lv='Ceturtdiena'", vLanguage);
		EndIf;
	ElsIf pDayOfWeek = 5 Then
		If pShort Then
			Return cmNStr("en='fr';ru='пт';de='Fr';lv='Piek'", vLanguage);
		Else
			Return cmNStr("en='Friday';ru='Пятница';de='Freitag';lv='Piektdiena'", vLanguage);
		EndIf;
	ElsIf pDayOfWeek = 6 Then
		If pShort Then
			Return cmNStr("en='sa';ru='сб';de='Sa';lv='Ses'", vLanguage);
		Else
			Return cmNStr("en='Saturday';ru='Суббота';de='Samstag';lv='Sestdiena'", vLanguage);
		EndIf;
	ElsIf pDayOfWeek = 7 Then
		If pShort Then
			Return cmNStr("en='su';ru='вс';de='So';lv='Sv'", vLanguage);
		Else
			Return cmNStr("en='Sunday';ru='Воскресенье';de='Sonntag';lv='Svētdiena'", vLanguage);
		EndIf;
	EndIf;
EndFunction // cmGetDayOfWeekName

// -----------------------------------------------------------------------------
// Description: Returns month name or short month name based on month number
// Parameters: Month number, Whether to return short or full month name
// Return value: String, Month name (December or Dec, February or Feb e.t.c.)
// -----------------------------------------------------------------------------
Function cmGetMonthName(pMonthNumber, pShort = False) Export
	If pMonthNumber = 1 Then
		If pShort Then
			Return NStr("en='Jan';ru='Янв';de='Jan'");
		Else
			Return NStr("en='January';ru='Январь';de='Januar'");
		EndIf;
	ElsIf pMonthNumber = 2 Then
		If pShort Then
			Return NStr("en='Feb';ru='Фев';de='Feb'");
		Else
			Return NStr("en='February';ru='Февраль';de='Februar'");
		EndIf;
	ElsIf pMonthNumber = 3 Then
		If pShort Then
			Return NStr("en='Mar';ru='Мар';de='Mär'");
		Else
			Return NStr("en='March';ru='Март';de='März'");
		EndIf;
	ElsIf pMonthNumber = 4 Then
		If pShort Then
			Return NStr("en='Apr';ru='Апр';de='Apr'");
		Else
			Return NStr("en='April';ru='Апрель';de='April'");
		EndIf;
	ElsIf pMonthNumber = 5 Then
		If pShort Then
			Return NStr("en='May';ru='Май';de='Mai'");
		Else
			Return NStr("en='May';ru='Май';de='Mai'");
		EndIf;
	ElsIf pMonthNumber = 6 Then
		If pShort Then
			Return NStr("en='Jun';ru='Июн';de='Jun'");
		Else
			Return NStr("en='June';ru='Июнь';de='Juni'");
		EndIf;
	ElsIf pMonthNumber = 7 Then
		If pShort Then
			Return NStr("en='Jul';ru='Июл';de='Jul'");
		Else
			Return NStr("en='July';ru='Июль';de='Juli'");
		EndIf;
	ElsIf pMonthNumber = 8 Then
		If pShort Then
			Return NStr("en='Aug';ru='Авг';de='Aug'");
		Else
			Return NStr("en='August';ru='Август';de='August'");
		EndIf;
	ElsIf pMonthNumber = 9 Then
		If pShort Then
			Return NStr("en='Sep';ru='Сен';de='Sep'");
		Else
			Return NStr("en='September';ru='Сентябрь';de='September'");
		EndIf;
	ElsIf pMonthNumber = 10 Then
		If pShort Then
			Return NStr("en='Oct';ru='Окт';de='Okt'");
		Else
			Return NStr("en='October';ru='Октябрь';de='Oktober'");
		EndIf;
	ElsIf pMonthNumber = 11 Then
		If pShort Then
			Return NStr("en='Nov';ru='Ноя';de='Nov'");
		Else
			Return NStr("en='November';ru='Ноябрь';de='November'");
		EndIf;
	ElsIf pMonthNumber = 12 Then
		If pShort Then
			Return NStr("en='Dec';ru='Дек';de='Dez'");
		Else
			Return NStr("en='December';ru='Декабрь';de='Dezember'");
		EndIf;
	EndIf;
EndFunction // cmGetMonthName

// -----------------------------------------------------------------------------
// Description: Returns indent, i.e. one or several Tab chars based on catalog 
//              object group level. If catalog object level is 1 then one Tab char 
//              is returned. If catalog object level is 2 then two joined Tab chars 
//              are returned.
// Parameters: Catalog object, Initial number of Tab chars to use
// Return value: String, Joined Tab chars
// -----------------------------------------------------------------------------
Function cmGetIndent(pObj, pInitialIndent = 0) Export
	vLevel = pInitialIndent;
	If ValueIsFilled(pObj) Then
		vLevel = vLevel + pObj.Level();
	EndIf;
	vIndent = "";
	i = 0;
	While i < vLevel Do
		vIndent = vIndent + "  ";
		i = i + 1;
	EndDo;
	Return vIndent;
EndFunction // cmGetIndent

// -----------------------------------------------------------------------------
// Description: Returns string from current time and document reference presentation
// Parameters: Any document ref
// Return value: String
// -----------------------------------------------------------------------------
Function cmGetMessageHeader(pDoc) Export
	Return Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm:ss'") + 
	       ?(ValueIsFilled(pDoc), " " + String(pDoc), "") + " - ";
EndFunction // cmGetMessageHeader

// -----------------------------------------------------------------------------
// Description: Adds time to the date 
// Parameters: Begin of date, Time, Whether to add additional 1 second or not
// Return value: Date with time
// -----------------------------------------------------------------------------
Function cmAddTime(pDate, pTime, pIsCheckIn) Export
	If pIsCheckIn Then
		Return BegOfDay(pDate) + Hour(pTime)*3600 + Minute(pTime)*60 + 1;
	Else
		Return BegOfDay(pDate) + Hour(pTime)*3600 + Minute(pTime)*60;
	EndIf;
EndFunction // cmAddTime

// -----------------------------------------------------------------------------
// Description: Extracts time from the date with time
// Parameters: Date with time
// Return value: Time part of the date
// -----------------------------------------------------------------------------
Function cmExtractTime(pDateTime) Export
	vTime = Date(1, 1, 1, Hour(pDateTime), Minute(pDateTime), 0);
	Return vTime;
EndFunction // cmExtractTime

// -----------------------------------------------------------------------------
// Description: Adds specified number of working days to the input date
// Parameters: Starting date, number of working days to add
// Return value: Date
// -----------------------------------------------------------------------------
Function cmAddWorkingDays(pDate, pNumDays) Export
	vDate = pDate;
	For i = 1 To pNumDays Do
		vDate = vDate + 24*3600;
		While WeekDay(vDate) > 5 Do
			vDate = vDate + 24*3600;
		EndDo;
	EndDo;
	Return vDate;
EndFunction // cmAddWorkingDays

// -----------------------------------------------------------------------------
// Description: Sets seconds part of time to one second
// Parameters: Date with time
// Return value: Date with time
// -----------------------------------------------------------------------------
Function cm1SecondShift(pDateTime) Export
	Return Date(Year(pDateTime), Month(pDateTime), Day(pDateTime), Hour(pDateTime), Minute(pDateTime), 1);
EndFunction // cm1SecondShift

// -----------------------------------------------------------------------------
// Description: Sets seconds part of time to 0 second
// Parameters: Date with time
// Return value: Date with time
// -----------------------------------------------------------------------------
Function cm0SecondShift(pDateTime) Export
	Return Date(Year(pDateTime), Month(pDateTime), Day(pDateTime), Hour(pDateTime), Minute(pDateTime), 0);
EndFunction // cm0SecondShift

// -----------------------------------------------------------------------------
// Description: Returns date & time from the timestamp string
// Parameters: Timestamp string like YYYY-MM-DDTHH:MM:SS.SSS
// Return value: Date with time
// -----------------------------------------------------------------------------
Function cmGetDateFromTimestampPresentation(pTimestamp) Export
	Try
		vDateTime = Date(Number(Left(pTimestamp, 4)), Number(Mid(pTimestamp, 6, 2)), Number(Mid(pTimestamp, 9, 2)), Number(Mid(pTimestamp, 12, 2)), Number(Mid(pTimestamp, 15, 2)), Number(Mid(pTimestamp, 18, 2)));
	Except
		vDateTime = '00010101';
	EndTry;
	Return vDateTime;
EndFunction // cmGetDateFromTimestampPresentation

// -----------------------------------------------------------------------------
// Description: Returns date from the date string
// Parameters: Date string like YYYY-MM-DD
// Return value: Date
// -----------------------------------------------------------------------------
Function cmGetDateFromDatePresentation(pTimestamp) Export
	Try
		vDate = Date(Number(Left(pTimestamp, 4)), Number(Mid(pTimestamp, 6, 2)), Number(Mid(pTimestamp, 9, 2)), 0, 0, 0);
	Except
		vDate = '00010101';
	EndTry;
	Return vDate;
EndFunction // cmGetDateFromDatePresentation

// -----------------------------------------------------------------------------
// Description: Returns text representation of the amount
// Parameters: Amount, Currency, Zero amount presentation, Target language, Wether to add currency char or not
// Return value: String, f.e. "$10 000,00" or "10 000,00 USD"
// -----------------------------------------------------------------------------
Function cmFormatSum(pSum, pCurrency, pZeroPresentation = "", pLang = Undefined, pNoCurrency = False) Export
	vFmtStr = "";
	If IsBlankString(pZeroPresentation) Then
		vFmtStr = "ND=17; NFD=2; NDS=; NGS=; NN=1";
	Else
		vFmtStr = "ND=17; NFD=2; NDS=; NGS=; " + pZeroPresentation + "; NN=1";
	EndIf;
	vStr = Format(pSum, vFmtStr);
	If Not pNoCurrency And Not IsBlankString(vStr) Then
		If ValueIsFilled(pCurrency) Then
			vCurPres = cmGetCurrencyPresentation(pCurrency, pLang);
			If StrLen(vCurPres) > 1 Then
				vStr = vStr + " " + vCurPres;
			Else
				If pCurrency.PlaceSymbolBeforeSum Then
					vStr = vCurPres + " " + vStr;
				Else
					vStr = vStr + vCurPres;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vStr;
EndFunction // cmFormatSum

// -----------------------------------------------------------------------------
// Description: Returns decimal hours quantity as XX hours YY minutes string
// Parameters: Decimal duration in hours, Whether to return empty string if duration is zero or not
// Return value: String, f.e. "3h30m" for the 3.5 duration
// -----------------------------------------------------------------------------
Function cmFormatDurationInHours(pDuration, pFormatZero = False) Export
	vStr = "";
	If pDuration <> 0 Then
		vH = Int(pDuration);
		vM = Round((pDuration - vH)*60, 0);
		vStr = ?(vH = 0, "", Format(vH, "ND=9; NFD=0; NZ=") + NStr("en='h';ru='ч';de='St.'")) + 
		       ?(vM = 0, "", ?(vH = 0, "", " ") + Format(vM, "ND=9; NFD=0; NZ=") + NStr("en='m';ru='м';de='m'"));
	Else
		If pFormatZero Then
			vStr = "0" + NStr("en='h';ru='ч';de='St.'");
		EndIf;
	EndIf;
	Return vStr;
EndFunction // cmFormatDurationInHours

// -----------------------------------------------------------------------------
// Description: Converts string to the valid 1C programming language variable name
// Parameters: Name to check and convert
// Return value: String
// -----------------------------------------------------------------------------
Function cmGetValidName(Val pStr) Export
	pStr = TrimAll(pStr);
	pStr = StrReplace(pStr, " ", "");
	pStr = StrReplace(pStr, ".", "");
	pStr = StrReplace(pStr, ",", "");
	pStr = StrReplace(pStr, "-", "");
	pStr = StrReplace(pStr, "=", "");
	pStr = StrReplace(pStr, "*", "");
	pStr = StrReplace(pStr, "+", "");
	pStr = StrReplace(pStr, "(", "");
	pStr = StrReplace(pStr, ")", "");
	pStr = StrReplace(pStr, "&", "");
	pStr = StrReplace(pStr, "?", "");
	pStr = StrReplace(pStr, "&", "");
	pStr = StrReplace(pStr, "^", "");
	pStr = StrReplace(pStr, "%", "");
	pStr = StrReplace(pStr, "$", "");
	pStr = StrReplace(pStr, "#", "");
	pStr = StrReplace(pStr, "№", "");
	pStr = StrReplace(pStr, "@", "");
	pStr = StrReplace(pStr, "!", "");
	pStr = StrReplace(pStr, "~", "");
	pStr = StrReplace(pStr, "<", "");
	pStr = StrReplace(pStr, ">", "");
	pStr = StrReplace(pStr, "/", "");
	pStr = StrReplace(pStr, "|", "");
	pStr = StrReplace(pStr, "\", "");
	pStr = StrReplace(pStr, "[", "");
	pStr = StrReplace(pStr, "]", "");
	pStr = StrReplace(pStr, "{", "");
	pStr = StrReplace(pStr, "}", "");
	pStr = StrReplace(pStr, ";", "");
	pStr = StrReplace(pStr, ":", "");
	pStr = StrReplace(pStr, "'", "");
	pStr = StrReplace(pStr, """", "");
	vFirstChar = Left(pStr, 1);
	If StrFind("0123456789", vFirstChar) > 0 Then
		pStr = "N" + pStr; // Do not allow first digit
	EndIf;
	Return pStr;
EndFunction // cmGetValidName

// -----------------------------------------------------------------------------
// Description: Check the validity of E-Mail
// Parameters: E-Mail
// Return value: Boolean
// -----------------------------------------------------------------------------
Function cmCheckEMailIsValid(pEMail) Export
	If Not ValueIsFilled(pEMail) Or StrLen(pEMail) < 6 Then
		Return False;
	EndIf;
	vAPos = StrFind(pEMail, "@");
	If vAPos < 2 Then
		Return False;
	EndIf;
	vDotPos = StrLen(pEMail);
	While Mid(pEMail, vDotPos, 1)  <> "." And vDotPos > 0 Do
		vDotPos = vDotPos - 1;
	EndDo;
	vStrLen = StrLen(pEMail);
	If (vStrLen - 1) <= vDotPos Or vDotPos = 0 Then
		Return False;
	EndIf;
	If (vDotPos - 1) <= vAPos Then
		Return False;
	EndIf;
	Return True;
EndFunction // cmCheckEMailIsValid

// ------------------------------------------------------------------------------
// Description: Converts string to the valid file name
// Parameters: Name to check and convert
// Return value: String
// -----------------------------------------------------------------------------
Function cmGetValidFileName(pFileName) Export
	vValidFileName = TrimAll(pFileName);
	vValidFileName = StrReplace(vValidFileName, "/", "");
	vValidFileName = StrReplace(vValidFileName, "|", "");
	vValidFileName = StrReplace(vValidFileName, "\", "");
	vValidFileName = StrReplace(vValidFileName, "<", "");
	vValidFileName = StrReplace(vValidFileName, ">", "");
	vValidFileName = StrReplace(vValidFileName, ":", "");
	vValidFileName = StrReplace(vValidFileName, "*", "");
	vValidFileName = StrReplace(vValidFileName, "?", "");
	vValidFileName = StrReplace(vValidFileName, "!", "");
	vValidFileName = StrReplace(vValidFileName, "&", "");
	vValidFileName = StrReplace(vValidFileName, """", "");
	vValidFileName = StrReplace(vValidFileName, "'", "");
	vValidFileName = StrReplace(vValidFileName, " ", "_");
	Return vValidFileName;
EndFunction // cmGetValidFileName

// ------------------------------------------------------------------------------
// Description: Replaces string chars by another ones
// Parameters: Source chars sequence, String where to replace, Target chars sequence
// Return value: String
// -----------------------------------------------------------------------------
Function cmCharRepl(pSourceChars, pStr, pTargetChars) Export
	vRes = pStr;
	For i = 1 To StrLen(pSourceChars) Do
		vRes = StrReplace(vRes, Mid(pSourceChars, i, 1), Mid(pTargetChars, i, 1));
	EndDo;
	Return vRes;
EndFunction // cmCharRepl

// -----------------------------------------------------------------------------
// Description: Adds int quantity to the document number presentation
// Parameters: Source document number, Quantity to add
// Return value: New document number
// -----------------------------------------------------------------------------
Function cmAddToNumberWithPrefix(pNumber, pQuantity) Export
	vRetNumber = "";
	vNumber = TrimAll(pNumber);
	Try
		If pQuantity > 0 Then
			If Not IsBlankString(vNumber) Then
				// Check prefix position (left chars or right)
				vNoPrefix = False;
				vLeftPrefix = False;
				vRightPrefix = False;
				vChar = Left(vNumber, 1);
				If vChar >= "0" And vChar <= "9" Then
					vChar = Right(vNumber, 1);
					If vChar >= "0" And vChar <= "9" Then
						vNoPrefix = True;
					Else
						vRightPrefix = True;
					EndIf;
				Else
					vLeftPrefix = True;
				EndIf;
				If vNoPrefix Then
					vNumberOfDigits = StrLen(vNumber);
					vRetNumber = Format(Number(vNumber) + pQuantity - 1, "ND=" + String(vNumberOfDigits) + "; NFD=0; NZ=; NLZ=; NG=");
				ElsIf vLeftPrefix Then
					vPrefix = "";
					For i = 1 To StrLen(vNumber) Do
						vChar = Mid(vNumber, i, 1);
						If vChar >= "0" And vChar <= "9" Then
							Break;
						Else
							vPrefix = vPrefix + vChar;
						EndIf;
					EndDo;
					vNumberOfDigits = StrLen(vNumber);
					vPrefixLen = StrLen(vPrefix);
					If vPrefixLen < vNumberOfDigits Then
						If Not IsBlankString(vPrefix) Then
							vNumberOfDigits = vNumberOfDigits - vPrefixLen;
							vNumber = Mid(vNumber, vPrefixLen + 1);
						EndIf;
						vRetNumber = vPrefix + Format(Number(vNumber) + pQuantity - 1, "ND=" + String(vNumberOfDigits) + "; NFD=0; NZ=; NLZ=; NG=");
					EndIf;
				ElsIf vRightPrefix Then
					vPrefix = "";
					vNumberOfDigits = StrLen(vNumber);
					i = vNumberOfDigits;
					While i > 0 Do
						vChar = Mid(vNumber, i, 1);
						If vChar >= "0" And vChar <= "9" Then
							Break;
						Else
							vPrefix = vChar + vPrefix;
						EndIf;
						i = i - 1;
					EndDo;
					vPrefixLen = StrLen(vPrefix);
					If vPrefixLen < vNumberOfDigits Then
						If Not IsBlankString(vPrefix) Then
							vNumberOfDigits = vNumberOfDigits - vPrefixLen;
							vNumber = Left(vNumber, vNumberOfDigits);
						EndIf;
						vRetNumber = Format(Number(vNumber) + pQuantity - 1, "ND=" + String(vNumberOfDigits) + "; NFD=0; NZ=; NLZ=; NG=") + vPrefix;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	Except
	EndTry;
	Return vRetNumber;
EndFunction // cmAddToNumberWithPrefix 

// -----------------------------------------------------------------------------
// Description: Subtracts int quantity from the document number presentation
// Parameters: Source document number, Quantity to subtract
// Return value: New document number
// -----------------------------------------------------------------------------
Function cmSubtractNumbersWithPrefix(pNumberTo, pNumberFrom) Export
	vQty = 0;
	Try
		vNumberTo = TrimAll(pNumberTo);
		vNumberFrom = TrimAll(pNumberFrom);
		If IsBlankString(vNumberTo) Or IsBlankString(vNumberFrom) Then
			Return vQty;
		EndIf;
		// Check prefix position (left chars or right)
		vNoPrefix = False;
		vLeftPrefix = False;
		vRightPrefix = False;
		vChar = Left(vNumberFrom, 1);
		If vChar >= "0" And vChar <= "9" Then
			vChar = Right(vNumberFrom, 1);
			If vChar >= "0" And vChar <= "9" Then
				vNoPrefix = True;
			Else
				vRightPrefix = True;
			EndIf;
		Else
			vLeftPrefix = True;
		EndIf;
		vQtyFrom = 0;
		vQtyTo = 0;
		If vNoPrefix Then
			vQtyTo = Number(vNumberTo);
			vQtyFrom = Number(vNumberFrom);
		ElsIf vLeftPrefix Then
			vPrefixTo = "";
			For i = 1 To StrLen(vNumberTo) Do
				vChar = Mid(vNumberTo, i, 1);
				If vChar >= "0" And vChar <= "9" Then
					Break;
				Else
					vPrefixTo = vPrefixTo + vChar;
				EndIf;
			EndDo;
			vPrefixToLen = StrLen(vPrefixTo);
			vNumberToLen = StrLen(vNumberTo);
			If vPrefixToLen < vNumberToLen Then
				vQtyTo = Number(Mid(vNumberTo, vPrefixToLen + 1));
			EndIf;
			vPrefixFrom = "";
			For i = 1 To StrLen(vNumberFrom) Do
				vChar = Mid(vNumberFrom, i, 1);
				If vChar >= "0" And vChar <= "9" Then
					Break;
				Else
					vPrefixFrom = vPrefixFrom + vChar;
				EndIf;
			EndDo;
			vPrefixFromLen = StrLen(vPrefixFrom);
			vNumberFromLen = StrLen(vNumberFrom);
			If vPrefixFromLen < vNumberFromLen Then
				vQtyFrom = Number(Mid(vNumberFrom, vPrefixFromLen + 1));
			EndIf;
			If vPrefixFrom <> vPrefixTo Then
				vQtyTo = 0;
				vQtyFrom = 1;
			EndIf;
		ElsIf vRightPrefix Then
			vPrefixTo = "";
			vNumberToLen = StrLen(vNumberTo);
			i = vNumberToLen;
			While i > 0 Do
				vChar = Mid(vNumberTo, i, 1);
				If vChar >= "0" And vChar <= "9" Then
					Break;
				Else
					vPrefixTo = vChar + vPrefixTo;
				EndIf;
				i = i - 1;
			EndDo;
			vPrefixToLen = StrLen(vPrefixTo);
			If vPrefixToLen < vNumberToLen Then
				vQtyTo = Number(Left(vNumberTo, vNumberToLen - vPrefixToLen));
			EndIf;
			vPrefixFrom = "";
			vNumberFromLen = StrLen(vNumberFrom);
			i = vNumberFromLen;
			While i > 0 Do
				vChar = Mid(vNumberFrom, i, 1);
				If vChar >= "0" And vChar <= "9" Then
					Break;
				Else
					vPrefixFrom = vChar + vPrefixFrom;
				EndIf;
				i = i - 1;
			EndDo;
			vPrefixFromLen = StrLen(vPrefixFrom);
			If vPrefixFromLen < vNumberFromLen Then
				vQtyFrom = Number(Left(vNumberFrom, vNumberFromLen - vPrefixFromLen));
			EndIf;
			If vPrefixFrom <> vPrefixTo Then
				vQtyTo = 0;
				vQtyFrom = 1;
			EndIf;
		EndIf;
		vQty = vQtyTo - vQtyFrom + 1;
		If vQty < 0 Then
			vQty = 0;
		EndIf;
	Except
		vQty = 0;
	EndTry;
	Return vQty;
EndFunction // cmSubtractNumbersWithPrefix

// -----------------------------------------------------------------------------
//  Applies default print settings to the report or other print form
//
// Parameters:
//  pSpreadsheet		 - Spreadsheet	 - Spreadsheet with form
//  pPageOrientation	 - FitToPage	 - Page orientation to set
//  pDefaultFitToPage	 - Boolean		 - 
//  pCopies				 - Number		 - 
//  pBlackAndWhite		 - Boolean		 - 
//
Procedure cmSetDefaultPrintFormSettings(pSpreadsheet, pPageOrientation, pDefaultFitToPage = True, pCopies = 0, pBlackAndWhite = Undefined) Export
	cmFixDrawingsPrintForm(pSpreadsheet);
	pSpreadsheet.FitToPage = pDefaultFitToPage;
	pSpreadsheet.ReadOnly = True;
	pSpreadsheet.ShowHeaders = False;
	pSpreadsheet.ShowGrid = False;
	pSpreadsheet.PageOrientation = pPageOrientation;
	If pCopies <> 0 Then
		pSpreadsheet.Copies = pCopies;
	EndIf;
	If pBlackAndWhite <> Undefined Then
		pSpreadsheet.BlackAndWhite = pBlackAndWhite;
	EndIf;
EndProcedure // cmSetDefaultPrintFormSettings

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSpreadsheet - Spreadsheet	 - Spreadsheet with form
//
Procedure cmFixDrawingsPrintForm(pSpreadsheet) Export
	For Each vDrawing In pSpreadsheet.Drawings Do
		vHeight = vDrawing.Height;
		vWidth = vDrawing.Width;
		If vHeight < 0 Then
			vHeight = vHeight * -1;
			vDrawing.Top = vDrawing.Top -vHeight;
			vDrawing.Height = vHeight;
		EndIf;
		If vWidth < 0 Then
			vWidth = vWidth * -1;
			vDrawing.Left = vDrawing.Left - vWidth;
			vDrawing.Width = vWidth;
		EndIf;
	EndDo;
EndProcedure // FixDrawingsPrintForm

// -----------------------------------------------------------------------------
// Description: Applies print settings to the report or other print form
// Parameters: Spreadsheet with form, Structure with print form settings
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetSpreadsheetSettings(pSpreadsheet, pPrintSettings) Export
	pSpreadsheet.PrinterName = pPrintSettings.PrinterName;
	pSpreadsheet.FitToPage = pPrintSettings.FitToPage;
	pSpreadsheet.PrintScale = pPrintSettings.PrintScale;
	pSpreadsheet.Copies = pPrintSettings.Copies;
	If pPrintSettings.CopiesPerPage = Enums.CopiesPerPage.Auto Then
		pSpreadsheet.PerPage = 0;
	ElsIf pPrintSettings.CopiesPerPage = Enums.CopiesPerPage.One Then
		pSpreadsheet.PerPage = 1;
	ElsIf pPrintSettings.CopiesPerPage = Enums.CopiesPerPage.Two Then
		pSpreadsheet.PerPage = 2;
	EndIf;
	pSpreadsheet.Collate = pPrintSettings.Collate;
	If pPrintSettings.PageOrientation = Enums.PageOrientations.Portrait Then
		pSpreadsheet.PageOrientation = PageOrientation.Portrait;
	ElsIf pPrintSettings.PageOrientation = Enums.PageOrientations.Landscape Then
		pSpreadsheet.PageOrientation = PageOrientation.Landscape;
	EndIf;
	If pPrintSettings.DuplexPrintingType = Enums.DuplexPrintingTypes.FlipPagesLeft Then
		pSpreadsheet.DuplexPrinting = DuplexPrintingType.FlipPagesLeft;
	ElsIf pPrintSettings.DuplexPrintingType = Enums.DuplexPrintingTypes.FlipPagesUp Then
		pSpreadsheet.DuplexPrinting = DuplexPrintingType.FlipPagesUp;
	ElsIf pPrintSettings.DuplexPrintingType = Enums.DuplexPrintingTypes.None Then
		pSpreadsheet.DuplexPrinting = DuplexPrintingType.None;
	Else
		pSpreadsheet.DuplexPrinting = DuplexPrintingType.UsePrinterSettings;
	EndIf;
	If Not IsBlankString(pPrintSettings.PageSize) Then
		pSpreadsheet.PageSize = pPrintSettings.PageSize;
	EndIf;
	pSpreadsheet.BlackAndWhite = pPrintSettings.BlackAndWhite;
	pSpreadsheet.TopMargin = pPrintSettings.TopMargin;
	pSpreadsheet.BottomMargin = pPrintSettings.BottomMargin;
	pSpreadsheet.LeftMargin = pPrintSettings.LeftMargin;
	pSpreadsheet.RightMargin = pPrintSettings.RightMargin;
	pSpreadsheet.HeaderSize = pPrintSettings.HeaderSize;
	pSpreadsheet.FooterSize = pPrintSettings.FooterSize;
EndProcedure // cmSetSpreadsheetSettings

// -----------------------------------------------------------------------------
// Description: Builds report form save to file default name based on print form settings
// Parameters: Structure with print form settings, Default file name
// Return value: String, Print form save to file name
// -----------------------------------------------------------------------------
Function cmGetPrintFormFileName(pPrintSettings, pFileName = "") Export
	vFileName = pFileName;
	If pPrintSettings <> Undefined Then
		vFileName = ?(IsBlankString(pPrintSettings.FileName), pFileName, cmNStr(pPrintSettings.FileName));
		If pPrintSettings.AddTimeToTheFileName Then
			vFileName = vFileName + " " + Format(CurrentSessionDate(), "DF='yyyy-MM-dd HHmm'");
		EndIf;
	EndIf;
	Return vFileName;
EndFunction // cmGetPrintFormFileName
	
// -----------------------------------------------------------------------------
// Description: Receives and performs output of form according to the print form settings
//              Output could be done to the screen, printer or to the file in different formats.
//              Send form by E-Mail is also supported
// Parameters: Print form, Structure with print form settings, Default file name, Language
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmDoSpreadsheetOutput(pSpreadsheet, pPrintSettings, pFileName, pLanguage = Undefined, rDoPrint = Undefined, pSendEMail = true, rFilePath = Undefined) Export
	rDoPrint = Undefined;
	vLanguage = pLanguage;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	If pPrintSettings <> Undefined Then
		If pPrintSettings.PrintDirection = Enums.PrintDirections.Printer Then
			#IF ThickClientOrdinaryApplication THEN
				If IsBlankString(pSpreadsheet.PrinterName) Then
					pSpreadsheet.Print(False);
				Else
					pSpreadsheet.Print(True);
				EndIf;
			#ELSE
				rDoPrint = New Structure("Spreadsheet, PrinterName, PrintDialogUseMode", pSpreadsheet, TrimAll(pSpreadsheet.PrinterName), ?(IsBlankString(pSpreadsheet.PrinterName), "Use", "DontUse"));
			#ENDIF
		Else
			// Get file and save catalog names
			vFileName = "";
			If IsBlankString(pFileName) Then
				If ValueIsFilled(pPrintSettings.Report) Then
					vFileName = cmNStr(TrimAll(pPrintSettings.Report));
				ElsIf ValueIsFilled(pPrintSettings.ObjectPrintingForm) Then
					vFileName = cmNStr(TrimAll(pPrintSettings.ObjectPrintingForm));
				Else
					vUUID = New UUID();
					vFileName = String(vUUID);
				EndIf;
			Else
				vFileName = TrimAll(pFileName);
			EndIf;
			vFileSaveCatalog = "";
			If IsBlankString(pPrintSettings.FileSaveCatalog) Then
				vFileSaveCatalog = TempFilesDir();
			Else
				vFileSaveCatalog = TrimAll(pPrintSettings.FileSaveCatalog);
			EndIf;
			If pPrintSettings.CreateDateFolderInside Then
				vDateFolder = Format(CurrentSessionDate(), "DF=yyyy-MM-dd");
				vFileSaveCatalog = vFileSaveCatalog + "\" + vDateFolder;
				vDir = New File(vFileSaveCatalog);
				If Not (tcCommonFunctionOnClientServer.cmExists(vDir) And Not vDir.IsFile()) Then
					CreateDirectory(vFileSaveCatalog);
				EndIf;
			EndIf;

			// Get full file name and save file
			vFullFileName = "";
			If pPrintSettings.PrintDirection = Enums.PrintDirections.MXL Then
				vFileName = vFileName + ".mxl";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.MXL);
			ElsIf pPrintSettings.PrintDirection = Enums.PrintDirections.XLS Then
				vFileName = vFileName + ".xls";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.XLS);
			ElsIf pPrintSettings.PrintDirection = Enums.PrintDirections.XLSX Then
				vFileName = vFileName + ".xlsx";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.XLSX);
			ElsIf pPrintSettings.PrintDirection = Enums.PrintDirections.HTML Then
				vFileName = vFileName + ".html";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.HTML);
			ElsIf pPrintSettings.PrintDirection = Enums.PrintDirections.TXT Then
				vFileName = vFileName + ".txt";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.TXT);
			ElsIf pPrintSettings.PrintDirection = Enums.PrintDirections.PDF Then
				vFileName = vFileName + ".pdf";
				vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
				pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.PDF);
			EndIf;
			// Check if we have to send file by e-mail
			rFilePath = vFullFileName;
			If Not IsBlankString(pPrintSettings.EMails) And pSendEMail = True Then
				vSubject = vFileName;
				vMessage = cmNStr("ru='Рассылка печатных форм: '; de='Versand von Druckformen: '; en = 'Print form delivery: '", vLanguage) + Chars.LF + Chars.LF + 
				           vFileName + Chars.LF + Chars.LF + 
				           cmNStr("ru='C уважением, '; de='Hochachtungsvoll, '; en='Best regards, '", vLanguage) + Chars.LF + 
				           cmNStr(SessionParameters.ConfigurationName, vLanguage);
				cmSendFileByEMailInBackground(vSubject, vMessage, pPrintSettings.EMails, vFileName, vFullFileName, vLanguage);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmDoSpreadsheetOutput

// -----------------------------------------------------------------------------
// Description: Parses passport data to the passport series and number
// Parameters: Passport data string, Return passport series string, return passport number string
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmParsePassportNumber(pPassport, rSeries, rNumber) Export
	vPassport = TrimAll(pPassport);
	rSeries = "";
	rNumber = vPassport;
	i = StrLen(vPassport);
	While i > 1 Do
		vChar = Mid(vPassport, i , 1);
		If vChar = " " Then
			rNumber = TrimAll(Mid(vPassport, i + 1));
			rSeries = StrReplace(TrimAll(Left(vPassport, i - 1)), " ", "");
			Break;
		EndIf;
		i = i - 1;
	EndDo;
EndProcedure // cmParsePassportNumber

// -----------------------------------------------------------------------------
// Description: Parses client full name string to last name, first name, second name and sex
// Parameters: Client full name string as Ivanov Ivan Ivanovich, 
//             Return client last name string, 
//             Return client first name string, 
//             Return client second name string, 
//             Return client sex enumeration reference
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmParseClientFullName(Val pFullName, rLastName, rFirstName, rSecondName, rSex = Undefined) Export
	rLastName = "";
	rFirstName = "";
	rSecondName = "";
	rSex = Undefined;
	pFullName = TrimAll(pFullName);
	// Try to parse guest full name to the 3 parts
	If Not IsBlankString(pFullName) Then
		pFullName = StrReplace(pFullName, ".", " ");
		pFullName = StrReplace(pFullName, "  ", " ");
		pFullName = StrReplace(pFullName, "  ", " ");
		rLastName = pFullName;
		vBlankPos1 = StrFind(pFullName, " ");
		If vBlankPos1 > 1 Then
			vBlankPos2 = StrFind(Mid(pFullName, vBlankPos1 + 1), " ");
			If vBlankPos2 > 1 Then
				rLastName = TrimAll(Left(pFullName, vBlankPos1 - 1));
				rFirstName = TrimAll(Mid(pFullName, vBlankPos1 + 1, vBlankPos2 - 1));
				rSecondName = TrimAll(Right(pFullName, StrLen(pFullName) - vBlankPos1 - vBlankPos2));
				// Try to fill gest sex
				rSex = cmGetSexByNames(rLastName, rFirstName, rSecondName);
			Else
				rLastName = TrimAll(Left(pFullName, vBlankPos1 - 1));
				rFirstName = TrimAll(Mid(pFullName, vBlankPos1 + 1));
				// Try to fill gest sex
				rSex = cmGetSexByNames(rLastName, rFirstName, rSecondName);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmParseClientFullName

// -----------------------------------------------------------------------------
// Description: Converts comma delimeted list of e-mail addresses to the address array
// Parameters: String of addresses
// Return value: Array of addresses
// -----------------------------------------------------------------------------
Function cmParseEMailAddress(pEMails) Export
	vEMailsList = New ValueList();
	vEMails = TrimAll(pEMails);
	vPos = StrFind(vEMails, ",");
	If vPos = 0 Then
		vEMailsList.Add(vEMails);
	Else
		While vPos > 0 Do
			vEMailsList.Add(TrimAll(Left(vEMails, vPos-1)));
			vEMails = TrimAll(Mid(vEMails, vPos+1));
			vPos = StrFind(vEMails, ",");
		EndDo;
		If Not IsBlankString(vEMails) Then
			vEMailsList.Add(TrimAll(vEMails));
		EndIf;
	EndIf;
	Return vEMailsList;
EndFunction // cmParseEMailAddress

// -----------------------------------------------------------------------------
// Description: Sends file by e-mail asynchronously
// Parameters: Mail subject, Mail text, Target addresses, File name to attach, Full file name, language
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSendFileByEMailInBackground(pSubject, pMessage, pEMails, pFileName, pFullFileName, pLanguage = Undefined) Export
	vLanguage = pLanguage;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	vFilesMap = New Map;
	vFilesMap.Insert(pFileName, pFullFileName);
	// Initialize parameters array
	vParams = New Array();
	vParams.Add(pSubject);
	vParams.Add(pMessage);
	vParams.Add(pEMails);
	vParams.Add(vFilesMap);
	vParams.Add(vLanguage);
	vParams.Add(True);
	vParams.Add(Undefined);
	// Execute in the background
	BackgroundJobs.Execute("JobsScheduled.cmSendFilesByEMail", vParams, , pSubject);
EndProcedure // cmSendFileByEMailInBackground

// -----------------------------------------------------------------------------
// Description: Builds full file name
// Parameters: File name, File catalog
// Return value: Full file name
// -----------------------------------------------------------------------------
Function cmGetFullFileName(Val pFileName, Val pFileCatalog) Export
	pFileName = TrimAll(pFileName);
	pFileCatalog = TrimAll(pFileCatalog);
	If Right(pFileCatalog, 1) = "\" Then
		Return pFileCatalog + pFileName;
	ElsIf Right(pFileCatalog, 1) = "/" Then
		Return pFileCatalog + pFileName;
	Else
		Return pFileCatalog + "\" + pFileName; // Windows format by default
	EndIf;
EndFunction // cmGetFullFileName

// -----------------------------------------------------------------------------
// Description: Returns short file name with type
// Parameters: Full file name as string
// Return value: String
// -----------------------------------------------------------------------------
Function cmGetFileName(pFullFileName) Export
	vFile = New File(pFullFileName);
	If Not tcCommonFunctionOnClientServer.cmExists(vFile) Then
		Raise NStr("en='File ';ru='Файл ';de='Datei '") + TrimAll(pFullFileName) + NStr("en=' is not found!';ru=' не найден!';de=' nicht gefunden!'");
	ElsIf Not vFile.IsFile() Then
		Raise NStr("en='Folders could not be choosen! ';ru='Выбирать папки нельзя!';de='Die Ordner dürfen nicht gewählt werden!'");
	EndIf;
	Return vFile.Name;
EndFunction // cmGetFileName

// -----------------------------------------------------------------------------
// Description: Sets protected flag to the given print form
// Parameters: Print form
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetSpreadsheetProtection(pSpreadsheet) Export
	If cmCheckUserPermissions("HavePermissionToEditPrintForms") Then
		pSpreadsheet.Protection = False;
	Else
		pSpreadsheet.Protection = True;
	EndIf;
EndProcedure // cmSetSpreadsheetProtection

// -----------------------------------------------------------------------------
// Description: Returns default object printing form to be used when object's 
//              "Print" button is pressed
// Parameters: Type of object (objects empty reference), Print form language
// Return value: Object printing form
// -----------------------------------------------------------------------------
Function cmGetDefaultObjectPrintingForm(pObjectType, pLanguage = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS ObjectPrintingForm
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	ObjectPrintingForms.ObjectType = &qObjectType AND " + 
		?(ValueIsFilled(pLanguage), "(ObjectPrintingForms.Language = &qLanguage OR ObjectPrintingForms.Language = &qEmptyLanguage) AND ", "") + "
	|	(NOT ObjectPrintingForms.DeletionMark) AND
	|	(NOT ObjectPrintingForms.IsFolder) AND
	|	ObjectPrintingForms.IsActive AND
	|	ObjectPrintingForms.IsDefault
	|ORDER BY
	|	ObjectPrintingForms.Code";
	vQry.SetParameter("qObjectType", pObjectType);
	vQry.SetParameter("qLanguage", pLanguage);
	vQry.SetParameter("qEmptyLanguage", Catalogs.Languages.EmptyRef());
	vForms = vQry.Execute().Unload();
	vForm = Undefined;
	For Each vFormsRow In vForms Do
		vForm = vFormsRow.ObjectPrintingForm;
		Break;
	EndDo;
	Return vForm;
EndFunction // cmGetDefaultObjectPrintingForm

// -----------------------------------------------------------------------------
// Description: Returns default object form action to be used when object's 
//              "Actions" button is pressed
// Parameters: Type of object (objects empty reference), Action form language
// Return value: Object form action
// -----------------------------------------------------------------------------
Function cmGetDefaultObjectFormAction(pObjectType, pLanguage = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ObjectFormActions.Ref AS ObjectFormAction
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	ObjectFormActions.ObjectType = &qObjectType AND " + 
		?(ValueIsFilled(pLanguage), "(ObjectFormActions.Language = &qLanguage OR ObjectFormActions.Language = &qEmptyLanguage) AND ", "") + "
	|	(NOT ObjectFormActions.DeletionMark) AND
	|	(NOT ObjectFormActions.IsFolder) AND
	|	ObjectFormActions.IsActive AND
	|	ObjectFormActions.IsDefault
	|ORDER BY
	|	ObjectFormActions.Code";
	vQry.SetParameter("qObjectType", pObjectType);
	vQry.SetParameter("qLanguage", pLanguage);
	vQry.SetParameter("qEmptyLanguage", Catalogs.Languages.EmptyRef());
	vForms = vQry.Execute().Unload();
	vAction = Undefined;
	For Each vFormsRow In vForms Do
		vAction = vFormsRow.ObjectFormAction;
		Break;
	EndDo;
	Return vAction;
EndFunction // cmGetDefaultObjectFormAction

// -----------------------------------------------------------------------------
// Description: Returns full person name
// Parameters: Client reference
// Return value: String
// -----------------------------------------------------------------------------
Function cmGetFullPersonName(pPerson) Export
	If ValueIsFilled(pPerson) Then
		Return TrimAll(TrimAll(pPerson.LastName) + " " + TrimAll(pPerson.FirstName) + " " + TrimAll(pPerson.SecondName));
	Else
		Return "";
	EndIf;
EndFunction // cmGetFullPersonName

// -----------------------------------------------------------------------------
// Description: Returns guest sex by names
// Parameters: Last name, First name, Second name
// Return value: Enums.Sex.Ref
// -----------------------------------------------------------------------------
Function cmGetSexByNames(pLastName, pFirstName, pSecondName) Export
	If StrLen(TrimAll(pSecondName)) < 2 Тогда
		vLastCharLastName = Upper(Right(TrimAll(pLastName), 1));
		vLastCharFirstName = Upper(Right(TrimAll(pFirstName), 1));
		If (vLastCharLastName = "А") Or (vLastCharLastName = "Я") Or
		   (vLastCharFirstName = "А") Or (vLastCharFirstName = "Я") Then
			Return Enums.Sex.Female;
		Else
			Return Enums.Sex.Male;
		EndIf;
	Else
		vLastCharSecondName = Upper(Right(TrimAll(pSecondName), 1));
		If vLastCharSecondName = "А" Then
			Return Enums.Sex.Female;
		Else
			Return Enums.Sex.Male;
		EndIf;
	EndIf;
EndFunction // cmGetSexByNames

// -----------------------------------------------------------------------------
// Description: Returns client's list with given identity document number and series
// Parameters: Identity document series, Identity document number
// Return value: Value list of clients
// -----------------------------------------------------------------------------
Function cmGetClientsByIdentityDocumentSeriesAndNumber(pIDSeries, pIDNumber, pClientToSkip) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.IdentityDocumentNumber = &qIDNumber
	|	AND Clients.IdentityDocumentSeries = &qIDSeries
	|	AND Clients.Ref <> &qClient
	|	AND NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder
	|
	|ORDER BY
	|	Clients.Description";
	vQry.SetParameter("qIDSeries", TrimAll(pIDSeries));
	vQry.SetParameter("qIDNumber", TrimAll(pIDNumber));
	vQry.SetParameter("qClient", pClientToSkip);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetClientsByIdentityDocumentSeriesAndNumber

// -----------------------------------------------------------------------------
// Description: Gets object printing forms list based on object type and language
// Parameters: Object type as empty object reference, language
// Return value: Value table with list of object printing forms
// -----------------------------------------------------------------------------
Function cmGetObjectPrintingForms(pObjectType, pLanguage = Undefined, pPostponedOnly = False) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS ObjectPrintingForm,
	|	ObjectPrintingForms.Predefined,
	|	ObjectPrintingForms.Code,
	|	ObjectPrintingForms.Description,
	|	ObjectPrintingForms.ObjectType,
	|	ObjectPrintingForms.Language,
	|	ObjectPrintingForms.ExternalProcessing,
	|	ObjectPrintingForms.Report,
	|	ObjectPrintingForms.AutomaticallyPrintOnFirstObjectWrite,
	|	ObjectPrintingForms.Remarks,
	|	ObjectPrintingForms.IsDefault
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	ObjectPrintingForms.ObjectType = &qObjectType
	|	AND NOT ObjectPrintingForms.DeletionMark
	|	AND NOT ObjectPrintingForms.IsFolder
	|	AND (NOT &qPostponedOnly
	|				AND NOT ObjectPrintingForms.Parameter LIKE &qPostponed
	|			OR &qPostponedOnly
	|				AND ObjectPrintingForms.Parameter LIKE &qPostponed)
	|	AND ObjectPrintingForms.IsActive" + 
		?(ValueIsFilled(pLanguage), " AND (ObjectPrintingForms.Language = &qLanguage OR ObjectPrintingForms.Language = &qEmptyLanguage) ", "") + "
	|ORDER BY
	|	Code";
	vQry.SetParameter("qObjectType", pObjectType);
	vQry.SetParameter("qLanguage", pLanguage);
	vQry.SetParameter("qEmptyLanguage", Catalogs.Languages.EmptyRef());
	vQry.SetParameter("qPostponedOnly", pPostponedOnly);
	vQry.SetParameter("qPostponed", "%POSTPONED%");
	vForms = vQry.Execute().Unload();
	Return vForms;
EndFunction // cmGetObjectPrintingForms

// -----------------------------------------------------------------------------
// Description: Gets object actions list based on object type and language
// Parameters: Object type as empty object reference, language
// Return value: Value table with list of object form actions
// -----------------------------------------------------------------------------
Function cmGetObjectActions(pObjectType, pLanguage = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ObjectFormActions.Ref AS ObjectFormAction,
	|	ObjectFormActions.Predefined,
	|	ObjectFormActions.Code,
	|	ObjectFormActions.Description,
	|	ObjectFormActions.ObjectFormActionButton,
	|	ObjectFormActions.ButtonCaption,
	|	ObjectFormActions.ButtonToolTip,
	|	ObjectFormActions.ButtonShortcut,
	|	ObjectFormActions.ObjectType,
	|	ObjectFormActions.Language,
	|	ObjectFormActions.AutomaticallyRunOnFirstObjectWrite,
	|	ObjectFormActions.DataProcessor,
	|	ObjectFormActions.ExternalProcessing,
	|	ObjectFormActions.Remarks,
	|	ObjectFormActions.IsDefault
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	ObjectFormActions.ObjectType = &qObjectType AND 
	|	ObjectFormActions.DeletionMark = FALSE AND 
	|	ObjectFormActions.IsFolder = FALSE AND 
	|	ObjectFormActions.IsActive = TRUE " + 
		?(ValueIsFilled(pLanguage), " AND (ObjectFormActions.Language = &qLanguage OR ObjectFormActions.Language = &qEmptyLanguage) ", "") + "
	|ORDER BY
	|	Code";
	vQry.SetParameter("qObjectType", pObjectType);
	vQry.SetParameter("qLanguage", pLanguage);
	vQry.SetParameter("qEmptyLanguage", Catalogs.Languages.EmptyRef());
	vActions = vQry.Execute().Unload();
	Return vActions;
EndFunction // cmGetObjectActions

// -----------------------------------------------------------------------------
// Description: Gets object templates list based on object type
// Parameters: Hotel, Object type as empty object reference
// Return value: Value table with list of object templates
// -----------------------------------------------------------------------------
Function cmGetObjectTemplates(pHotel, pObjectType) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ObjectTemplates.Ref AS ObjectTemplate,
	|	ObjectTemplates.Code AS Code,
	|	ObjectTemplates.Description AS Description,
	|	ObjectTemplates.IsDefault AS IsDefault
	|FROM
	|	Catalog.ObjectTemplates AS ObjectTemplates
	|WHERE
	|	ObjectTemplates.Hotel = &qHotel 
	|	AND ObjectTemplates.ObjectType = &qObjectType 
	|	AND ObjectTemplates.DeletionMark = FALSE 
	|	AND ObjectTemplates.IsFolder = FALSE 
	|	AND ObjectTemplates.IsActive = TRUE 
	|ORDER BY
	|	Code";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qObjectType", pObjectType);
	vTemplates = vQry.Execute().Unload();
	Return vTemplates;
EndFunction // cmGetObjectTemplates 

// -----------------------------------------------------------------------------
// Description: Gets employee permission group
// Parameters: Employee
// Return value: Permission group reference
// -----------------------------------------------------------------------------
Function cmGetEmployeePermissionGroup(pEmployee) Export
	vPermissionGroup = Catalogs.PermissionGroups.EmptyRef();
	If ValueIsFilled(pEmployee) And Not cmIsBrokenRef("Catalog.Employees", pEmployee) Then
		vEmployeeNonReplicatingAttrs = pEmployee.GetObject().pmGetNonReplicatingAttributes();
		If vEmployeeNonReplicatingAttrs.Count() > 0 Then
			vPermissionGroup = vEmployeeNonReplicatingAttrs.Get(0).PermissionGroup;
		Else
			vPermissionGroup = pEmployee.PermissionGroup;
		EndIf;
	EndIf;
	Return vPermissionGroup;
EndFunction // cmGetEmployeePermissionGroup

// -----------------------------------------------------------------------------
// Description: Checks employee permissions to do some action
// Parameters: Permission name
// Return value: True if employee has rights to perform an action or False if not
// -----------------------------------------------------------------------------
Function cmCheckUserPermissions(pPermissionName) Export
	vUserHasPermissions = False;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vCurUsr = SessionParameters.CurrentUser;
		If ValueIsFilled(vCurUsr) Then
			vCurUsrPermGrp = cmGetEmployeePermissionGroup(vCurUsr);
			If ValueIsFilled(vCurUsrPermGrp) Then
				If vCurUsrPermGrp[pPermissionName] Then
					vUserHasPermissions = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vUserHasPermissions;
EndFunction // cmCheckUserPermissions

// -----------------------------------------------------------------------------
// Description: Returns value list of room rates allowed for the current employee
// Parameters: Period start date, Period end date
// Return value: Value list of room rates allowed
// -----------------------------------------------------------------------------
Function cmGetAllowedRoomRates(pPeriodFrom = Undefined, pPeriodTo = Undefined, pReservationDate = Undefined, pRoomType = Undefined, pHotel = Undefined, pIsRateForCRS = False) Export
	vAllowedRoomRates = New ValueList();    
	vOneDay = 24 * 3600;
	// Get list of all room rates valid for the period
	If ValueIsFilled(pPeriodFrom) Or ValueIsFilled(pPeriodTo) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomRates.Ref AS Ref,
		|	RoomRates.Hotel AS Hotel,
		|	CalendarDays.AccountingDate AS AccountingDate,
		|	CalendarDays.CalendarDayType AS CalendarDayType
		|INTO RoomRateDays
		|FROM
		|	Catalog.RoomRates AS RoomRates
		|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(
		|				,
		|				AccountingDate >= &qPeriodFrom
		|					AND AccountingDate <= &qPeriodTo
		|					AND NOT &qPeriodFromIsEmpty
		|					AND NOT &qPeriodToIsEmpty) AS CalendarDays
		|		ON (CalendarDays.Calendar = RoomRates.Calendar)
		|WHERE
		|	NOT RoomRates.DeletionMark
		|	AND NOT RoomRates.IsFolder
		|	AND (NOT &qIsRateForCRS
		|			OR &qIsRateForCRS
		|				AND RoomRates.IsRateForCRS)
		|	AND (&qPeriodFrom >= RoomRates.DateValidFrom
		|			OR &qPeriodFromIsEmpty)
		|	AND (RoomRates.DateValidTo <> &qEmptyDate
		|				AND &qPeriodTo <= ENDOFPERIOD(RoomRates.DateValidTo, DAY)
		|			OR &qPeriodToIsEmpty
		|			OR RoomRates.DateValidTo = &qEmptyDate)
		|	AND (NOT &qHotelIsFilled
		|			OR &qHotelIsFilled
		|				AND (RoomRates.Hotel = &qHotel
		|					OR RoomRates.Hotel = &qEmptyHotel))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RoomRateDays.Ref AS Ref,
		|	RoomRateDays.AccountingDate AS AccountingDate,
		|	RoomRateDays.CalendarDayType AS CalendarDayType,
		|	ISNULL(Restrictions.StopSale, FALSE) AS StopSale,
		|	FALSE AS CTA,
		|	FALSE AS CTD,
		|	0 AS MLOS,
		|	0 AS MaxLOS,
		|	0 AS MinDaysBeforeCheckIn,
		|	0 AS MaxDaysBeforeCheckIn
		|INTO PeriodRestrictions
		|FROM
		|	RoomRateDays AS RoomRateDays
		|		LEFT JOIN InformationRegister.RoomRateRestrictions AS Restrictions
		|		ON (NOT &qPeriodFromIsEmpty)
		|			AND (NOT &qPeriodToIsEmpty)
		|			AND (RoomRateDays.Ref = Restrictions.RoomRate
		|				OR Restrictions.RoomRate = VALUE(Catalog.RoomRates.EmptyRef))
		|			AND (RoomRateDays.Hotel = Restrictions.Hotel
		|				OR RoomRateDays.Hotel = &qEmptyHotel
		|				OR Restrictions.Hotel = &qEmptyHotel)
		|			AND (RoomRateDays.AccountingDate = Restrictions.AccountingDate
		|					AND Restrictions.AccountingDate >= &qPeriodFrom
		|					AND Restrictions.AccountingDate < &qPeriodToForStopSale
		|				OR Restrictions.DayOfWeek IN (&qDaysOfWeek)
		|					AND Restrictions.AccountingDate = &qEmptyDate
		|					AND Restrictions.CalendarDayType = &qEmptyCalendarDayType
		|				OR Restrictions.DayOfWeek IN (&qDaysOfWeek)
		|					AND Restrictions.AccountingDate = &qEmptyDate
		|					AND Restrictions.CalendarDayType = RoomRateDays.CalendarDayType
		|					AND Restrictions.CalendarDayType <> &qEmptyCalendarDayType
		|				OR Restrictions.CalendarDayType = RoomRateDays.CalendarDayType
		|					AND Restrictions.CalendarDayType <> &qEmptyCalendarDayType
		|					AND Restrictions.AccountingDate = &qEmptyDate
		|					AND Restrictions.DayOfWeek = 0)
		|			AND (Restrictions.RoomType = &qRoomType
		|					AND Restrictions.RoomType <> &qEmptyRoomType
		|				OR Restrictions.RoomType = &qEmptyRoomType)
		|			AND (NOT Restrictions.IsForOnlineOnly)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RoomRateDays.Ref AS Ref,
		|	RoomRateDays.AccountingDate AS AccountingDate,
		|	RoomRateDays.CalendarDayType AS CalendarDayType,
		|	ISNULL(Restrictions.StopSale, FALSE) AS StopSale,
		|	ISNULL(Restrictions.CTA, FALSE) AS CTA,
		|	FALSE AS CTD,
		|	ISNULL(Restrictions.MLOS, 0) AS MLOS,
		|	ISNULL(Restrictions.MaxLOS, 0) AS MaxLOS,
		|	CASE
		|		WHEN &qReservationDateIsEmpty
		|			THEN 0
		|		ELSE ISNULL(Restrictions.MinDaysBeforeCheckIn, 0)
		|	END AS MinDaysBeforeCheckIn,
		|	CASE
		|		WHEN &qReservationDateIsEmpty
		|			THEN 0
		|		ELSE ISNULL(Restrictions.MaxDaysBeforeCheckIn, 0)
		|	END AS MaxDaysBeforeCheckIn
		|INTO ArrivalRestrictions
		|FROM
		|	RoomRateDays AS RoomRateDays
		|		LEFT JOIN InformationRegister.RoomRateRestrictions AS Restrictions
		|		ON (NOT &qPeriodFromIsEmpty)
		|			AND (NOT &qPeriodToIsEmpty)
		|			AND (RoomRateDays.Ref = Restrictions.RoomRate
		|				OR Restrictions.RoomRate = VALUE(Catalog.RoomRates.EmptyRef))
		|			AND (RoomRateDays.Hotel = Restrictions.Hotel
		|				OR RoomRateDays.Hotel = &qEmptyHotel
		|				OR Restrictions.Hotel = &qEmptyHotel)
		|			AND (RoomRateDays.AccountingDate = Restrictions.AccountingDate
		|					AND Restrictions.AccountingDate = &qPeriodFrom
		|				OR Restrictions.DayOfWeek = &qDayOfWeekFrom
		|					AND Restrictions.AccountingDate = &qEmptyDate
		|					AND Restrictions.CalendarDayType = &qEmptyCalendarDayType
		|				OR Restrictions.DayOfWeek = &qDayOfWeekFrom
		|					AND Restrictions.AccountingDate = &qEmptyDate
		|					AND Restrictions.CalendarDayType = RoomRateDays.CalendarDayType
		|					AND Restrictions.CalendarDayType <> &qEmptyCalendarDayType
		|				OR Restrictions.CalendarDayType = RoomRateDays.CalendarDayType
		|					AND Restrictions.CalendarDayType <> &qEmptyCalendarDayType
		|					AND Restrictions.AccountingDate = &qEmptyDate
		|					AND Restrictions.DayOfWeek = 0)
		|			AND (Restrictions.RoomType = &qRoomType
		|					AND Restrictions.RoomType <> &qEmptyRoomType
		|				OR Restrictions.RoomType = &qEmptyRoomType)
		|			AND (NOT Restrictions.IsForOnlineOnly)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RoomRateDays.Ref AS Ref,
		|	RoomRateDays.AccountingDate AS AccountingDate,
		|	RoomRateDays.CalendarDayType AS CalendarDayType,
		|	FALSE AS StopSale,
		|	FALSE AS CTA,
		|	ISNULL(Restrictions.CTD, FALSE) AS CTD,
		|	0 AS MLOS,
		|	0 AS MaxLOS,
		|	0 AS MinDaysBeforeCheckIn,
		|	0 AS MaxDaysBeforeCheckIn
		|INTO DepartureRestrictions
		|FROM
		|	RoomRateDays AS RoomRateDays
		|		LEFT JOIN InformationRegister.RoomRateRestrictions AS Restrictions
		|		ON (NOT &qPeriodFromIsEmpty)
		|			AND (NOT &qPeriodToIsEmpty)
		|			AND (RoomRateDays.Ref = Restrictions.RoomRate
		|				OR Restrictions.RoomRate = VALUE(Catalog.RoomRates.EmptyRef))
		|			AND (RoomRateDays.Hotel = Restrictions.Hotel
		|				OR RoomRateDays.Hotel = &qEmptyHotel
		|				OR Restrictions.Hotel = &qEmptyHotel)
		|			AND (RoomRateDays.AccountingDate = Restrictions.AccountingDate
		|					AND Restrictions.AccountingDate = &qPeriodTo
		|				OR Restrictions.DayOfWeek = &qDayOfWeekTo
		|					AND Restrictions.AccountingDate = &qEmptyDate
		|					AND Restrictions.CalendarDayType = &qEmptyCalendarDayType
		|				OR Restrictions.DayOfWeek = &qDayOfWeekTo
		|					AND Restrictions.AccountingDate = &qEmptyDate
		|					AND Restrictions.CalendarDayType = RoomRateDays.CalendarDayType
		|					AND Restrictions.CalendarDayType <> &qEmptyCalendarDayType
		|				OR Restrictions.CalendarDayType = RoomRateDays.CalendarDayType
		|					AND Restrictions.CalendarDayType <> &qEmptyCalendarDayType
		|					AND Restrictions.AccountingDate = &qEmptyDate
		|					AND Restrictions.DayOfWeek = 0)
		|			AND (Restrictions.RoomType = &qRoomType
		|					AND Restrictions.RoomType <> &qEmptyRoomType
		|				OR Restrictions.RoomType = &qEmptyRoomType)
		|			AND (NOT Restrictions.IsForOnlineOnly)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Restrictions.Ref AS Ref,
		|	MAX(Restrictions.StopSale) AS StopSaleActive,
		|	MAX(Restrictions.CTA) AS CTAActive,
		|	MAX(Restrictions.CTD) AS CTDActive,
		|	MAX(CASE
		|			WHEN Restrictions.MLOS > 0
		|					AND &qDuration < Restrictions.MLOS
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS MinLOSActive,
		|	MAX(CASE
		|			WHEN Restrictions.MaxLOS > 0
		|					AND &qDuration > Restrictions.MaxLOS
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS MaxLOSActive,
		|	MAX(CASE
		|			WHEN Restrictions.MinDaysBeforeCheckIn > 0
		|					AND &qDaysBeforeCheckIn < Restrictions.MinDaysBeforeCheckIn
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS MinDaysBeforeCheckInActive,
		|	MAX(CASE
		|			WHEN Restrictions.MaxDaysBeforeCheckIn > 0
		|					AND &qDaysBeforeCheckIn > Restrictions.MaxDaysBeforeCheckIn
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS MaxDaysBeforeCheckInActive
		|FROM
		|	(SELECT
		|		PeriodRestrictions.Ref AS Ref,
		|		PeriodRestrictions.StopSale AS StopSale,
		|		PeriodRestrictions.CTA AS CTA,
		|		PeriodRestrictions.CTD AS CTD,
		|		PeriodRestrictions.MLOS AS MLOS,
		|		PeriodRestrictions.MaxLOS AS MaxLOS,
		|		PeriodRestrictions.MinDaysBeforeCheckIn AS MinDaysBeforeCheckIn,
		|		PeriodRestrictions.MaxDaysBeforeCheckIn AS MaxDaysBeforeCheckIn
		|	FROM
		|		PeriodRestrictions AS PeriodRestrictions
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ArrivalRestrictions.Ref,
		|		ArrivalRestrictions.StopSale,
		|		ArrivalRestrictions.CTA,
		|		ArrivalRestrictions.CTD,
		|		ArrivalRestrictions.MLOS,
		|		ArrivalRestrictions.MaxLOS,
		|		ArrivalRestrictions.MinDaysBeforeCheckIn,
		|		ArrivalRestrictions.MaxDaysBeforeCheckIn
		|	FROM
		|		ArrivalRestrictions AS ArrivalRestrictions
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DepartureRestrictions.Ref,
		|		DepartureRestrictions.StopSale,
		|		DepartureRestrictions.CTA,
		|		DepartureRestrictions.CTD,
		|		DepartureRestrictions.MLOS,
		|		DepartureRestrictions.MaxLOS,
		|		DepartureRestrictions.MinDaysBeforeCheckIn,
		|		DepartureRestrictions.MaxDaysBeforeCheckIn
		|	FROM
		|		DepartureRestrictions AS DepartureRestrictions) AS Restrictions
		|
		|GROUP BY
		|	Restrictions.Ref
		|
		|HAVING
		|	NOT MAX(ISNULL(Restrictions.StopSale, FALSE)) AND
		|	NOT MAX(ISNULL(Restrictions.CTA, FALSE)) AND
		|	NOT MAX(ISNULL(Restrictions.CTD, FALSE)) AND
		|	NOT MAX(CASE
		|				WHEN Restrictions.MLOS > 0
		|						AND &qDuration < Restrictions.MLOS
		|					THEN TRUE
		|				ELSE FALSE
		|			END) AND
		|	NOT MAX(CASE
		|				WHEN Restrictions.MaxLOS > 0
		|						AND &qDuration > Restrictions.MaxLOS
		|					THEN TRUE
		|				ELSE FALSE
		|			END) AND
		|	NOT MAX(CASE
		|				WHEN Restrictions.MinDaysBeforeCheckIn > 0
		|						AND &qDaysBeforeCheckIn < Restrictions.MinDaysBeforeCheckIn
		|						AND NOT &qReservationDateIsEmpty
		|					THEN TRUE
		|				ELSE FALSE
		|			END) AND
		|	NOT MAX(CASE
		|				WHEN Restrictions.MaxDaysBeforeCheckIn > 0
		|						AND &qDaysBeforeCheckIn > Restrictions.MaxDaysBeforeCheckIn
		|						AND NOT &qReservationDateIsEmpty
		|					THEN TRUE
		|				ELSE FALSE
		|			END)
		|
		|ORDER BY
		|	Restrictions.Ref.SortCode,
		|	Restrictions.Ref.Description";
		vQry.SetParameter("qPeriodFrom", ?(ValueIsFilled(pPeriodFrom), BegOfDay(pPeriodFrom), '00010101'));
		vQry.SetParameter("qDayOfWeekFrom", ?(ValueIsFilled(pPeriodFrom), WeekDay(pPeriodFrom), 0));
		vQry.SetParameter("qPeriodFromIsEmpty", Not ValueIsFilled(pPeriodFrom));
		If ValueIsFilled(pPeriodTo) And ValueIsFilled(pPeriodFrom) And BegOfDay(pPeriodTo) > BegOfDay(pPeriodFrom) Then
			vQry.SetParameter("qPeriodTo", BegOfDay(pPeriodTo));
			vQry.SetParameter("qPeriodToForStopSale", BegOfDay(pPeriodTo));
		Else
			vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(pPeriodTo), BegOfDay(pPeriodTo), '00010101'));
			vQry.SetParameter("qPeriodToForStopSale", ?(ValueIsFilled(pPeriodTo), BegOfDay(pPeriodTo) + vOneDay, '00010101'));
		EndIf;
		vQry.SetParameter("qPeriodToIsEmpty", Not ValueIsFilled(pPeriodTo));
		vQry.SetParameter("qReservationDateIsEmpty", Not ValueIsFilled(pReservationDate));
		vQry.SetParameter("qDayOfWeekTo", ?(ValueIsFilled(pPeriodTo), WeekDay(pPeriodTo), 0));
		If ValueIsFilled(pPeriodFrom) And ValueIsFilled(pPeriodTo) And pPeriodTo > pPeriodFrom Then
			vQry.SetParameter("qDuration", (BegOfDay(pPeriodTo) - BegOfDay(pPeriodFrom)) / vOneDay);
		Else
			vQry.SetParameter("qDuration", 0);
		EndIf;
		If ValueIsFilled(pReservationDate) And ValueIsFilled(pPeriodFrom) And pPeriodFrom > pReservationDate Then
			vQry.SetParameter("qDaysBeforeCheckIn", (BegOfDay(pPeriodFrom) - BegOfDay(pReservationDate)) / vOneDay);
		Else
			vQry.SetParameter("qDaysBeforeCheckIn", 0);
		EndIf;
		vWeekDays = New ValueList();
		If ValueIsFilled(pPeriodFrom) And ValueIsFilled(pPeriodTo) And BegOfDay(pPeriodTo) > BegOfDay(pPeriodFrom) Then
			vCurDay = BegOfDay(pPeriodFrom);
			While vCurDay < pPeriodTo Do
				vWeekDay = WeekDay(vCurDay);
				If vWeekDays.FindByValue(vWeekDay) = Undefined Then
					vWeekDays.Add(vWeekDay);
				EndIf;
				If vWeekDays.Count() = 7 Then
					Break;
				EndIf;
				vCurDay = vCurDay + vOneDay;
			EndDo;
		EndIf;
		vQry.SetParameter("qDaysOfWeek", vWeekDays);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		vQry.SetParameter("qEmptyCalendarDayType", Catalogs.CalendarDayTypes.EmptyRef());
		vQry.SetParameter("qRoomType", pRoomType);
		vQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
		vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pHotel));
		vQry.SetParameter("qHotel", pHotel);
		vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		vQry.SetParameter("qIsRateForCRS", pIsRateForCRS);
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vAllowedRoomRates.LoadValues(vQryRes.UnloadColumn("Ref"));
		EndIf;
	Else
		vAllRoomRates = cmGetAllRoomRates(?(ValueIsFilled(pHotel), pHotel, SessionParameters.CurrentHotel));
		vAllowedRoomRates.LoadValues(vAllRoomRates.UnloadColumn("RoomRate"));
	EndIf;
	// Leave only allowed for this user room rates
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vCurUsr = SessionParameters.CurrentUser;
		If ValueIsFilled(vCurUsr) Then
			vCurUsrPermGrp = cmGetEmployeePermissionGroup(vCurUsr);
			If ValueIsFilled(vCurUsrPermGrp) Then
				If vCurUsrPermGrp.RoomRatesAllowed.Count() > 0 Then
					vInd = 0;
					While vInd < vAllowedRoomRates.Count() Do
						vAllowedRoomRatesItem = vAllowedRoomRates.Get(vInd);
						If vCurUsrPermGrp.RoomRatesAllowed.Find(vAllowedRoomRatesItem.Value, "RoomRate") = Undefined Then
							vAllowedRoomRates.Delete(vInd);
						Else
							vInd = vInd + 1;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vAllowedRoomRates;
EndFunction // cmGetAllowedRoomRates

// -----------------------------------------------------------------------------
// Description: Returns value list of service packages allowed for the current employee
// Parameters: Period start date, Period end date, Resource
// Return value: Value list of service packages allowed
// -----------------------------------------------------------------------------
Function cmGetAllowedServicePackages(pHotel, pPeriodFrom, pPeriodTo, pResource = Undefined, pWithoutMealBoardTerms = False, pWithoutHidden = False) Export
	vAllowedServicePackages = New ValueList();
	// Run query to get service packages valid for the period selected
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServicePackages.Ref AS Ref
	|FROM
	|	Catalog.ServicePackages AS ServicePackages
	|WHERE
	|	NOT ServicePackages.DeletionMark
	|	AND NOT ServicePackages.IsFolder
	|	AND ServicePackages.DateValidFrom <= &qPeriodFrom
	|	AND (ENDOFPERIOD(ServicePackages.DateValidTo, DAY) >= &qPeriodFrom
	|			OR ServicePackages.DateValidTo = &qEmptyDate)
	|	AND (ServicePackages.Hotel = &qHotel
	|			OR ServicePackages.Hotel = &qEmptyHotel)
	|	AND (&qWithoutMealBoardTerms
	|				AND NOT ServicePackages.IsMealBoardTerm
	|			OR NOT &qWithoutMealBoardTerms)
	|	AND (NOT &qWithoutHidden
	|			OR &qWithoutHidden
	|				AND NOT ServicePackages.HideForManualPackageAssignment)
	|
	|ORDER BY
	|	ServicePackages.SortCode";
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", BegOfDay(pPeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qWithoutMealBoardTerms", pWithoutMealBoardTerms);
	vQry.SetParameter("qWithoutHidden", pWithoutHidden);
	vQryRes = vQry.Execute().Unload();
	// Filter service packages by resource
	If ValueIsFilled(pResource) And pResource.ServicePackages.Count() > 0 Then
		i = 0;
		While i < vQryRes.Count() Do
			vQryResRow = vQryRes.Get(i);
			If pResource.ServicePackages.Find(vQryResRow.Ref, "ServicePackage") = Undefined Then
				vQryRes.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	// Fill value list
	vAllowedServicePackages.LoadValues(vQryRes.UnloadColumn("Ref"));
	// Fill presentation and icon
	For Each vSPItem In vAllowedServicePackages Do
		If ValueIsFilled(vSPItem.Value) Then
			vSPItem.Presentation = TrimAll(vSPItem.Value);
			If vSPItem.Value.IsPerPerson Then
				vSPItem.Presentation = vSPItem.Presentation + NStr("ru=' (Персональный)'; en=' (per person)'; de=' (Persönlich)'");
				vSPItem.Picture = PictureLib.Clients;
			Else
				vSPItem.Presentation = vSPItem.Presentation + NStr("ru=' (На основного гостя номера)'; en=' (per main room guest)'; de=' (Für Zimmer Hauptgast)'");
				vSPItem.Picture = PictureLib.Rooms;
			EndIf;
		EndIf;
	EndDo;
	// Return
	Return vAllowedServicePackages;
EndFunction // cmGetAllowedServicePackages

// -----------------------------------------------------------------------------
// Description: Returns whether current employee has to see balances in the 
//              accommodation or reservation lists or not
// Parameters: None
// Return value: True/False
// -----------------------------------------------------------------------------
Function cmShowBalancesInLists() Export
	vShowBalances = True;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vCurUsr = SessionParameters.CurrentUser;
		If ValueIsFilled(vCurUsr) Then
			vCurUsrPermGrp = vCurUsr.PermissionGroup;
			If ValueIsFilled(vCurUsrPermGrp) Then
				vShowBalances = Not vCurUsrPermGrp.DoNotShowBalancesInLists;
			EndIf;
		EndIf;
	EndIf;
	Return vShowBalances;
EndFunction // cmShowBalancesInLists 

// -----------------------------------------------------------------------------
// Description: Parses address string into the structure of address elements like
//              country, region, district, city, street, house, flat and so on
// Parameters: Address string
// Return value: Address structure
// -----------------------------------------------------------------------------
Function cmParseAddress(pAddress) Export
	// Initialize return structure
	vAddrElements = New Structure("Country, PostCode, Region, Area, City, Street, House, Flat", 
	                              Catalogs.Countries.EmptyRef(), "", "", "", "", "", "", "");
	// Initialize working variables
	vAddress = TrimAll(pAddress);
	If IsBlankString(pAddress) Then
		Return vAddrElements;
	EndIf;
	// Country
	vCommaPos = StrFind(vAddress, ",");
	If vCommaPos = 0 Then
		vAddrElements.Country = Catalogs.Countries.FindByDescription(vAddress, True);
		If valueIsFilled(vAddrElements.Country) Then
			Return vAddrElements;
		EndIf;		
	EndIf;	
	vAddrElements.Country = Catalogs.Countries.FindByDescription(Left(vAddress, vCommaPos-1), True);
	vAddress = Mid(vAddress, vCommaPos+1);
	// Post index
	vCommaPos = StrFind(vAddress, ",");
	If vCommaPos = 0 Then
		vAddrElements.PostCode = TrimAll(vAddress);
		Return vAddrElements;
	EndIf;	
	vAddrElements.PostCode = TrimAll(Left(vAddress, vCommaPos-1));
	vAddress = Mid(vAddress, vCommaPos+1);
	// Region
	vCommaPos = StrFind(vAddress, ",");
	If vCommaPos = 0 Then
		vAddrElements.Region = TrimAll(vAddress);
		Return vAddrElements;
	EndIf;	
	vAddrElements.Region = TrimAll(Left(vAddress, vCommaPos-1));
	vAddress = Mid(vAddress, vCommaPos+1);
	// Area
	vCommaPos = StrFind(vAddress, ",");
	If vCommaPos = 0 Then
		vAddrElements.Area = TrimAll(vAddress);
		Return vAddrElements;
	EndIf;	
	vAddrElements.Area = TrimAll(Left(vAddress, vCommaPos-1));
	vAddress = Mid(vAddress, vCommaPos+1);
	// City
	vCommaPos = StrFind(vAddress, ",");
	If vCommaPos = 0 Then
		vAddrElements.City = TrimAll(vAddress);
		Return vAddrElements;
	EndIf;	
	vAddrElements.City = TrimAll(Left(vAddress, vCommaPos-1));
	vAddress = Mid(vAddress, vCommaPos+1);
	// Street
	vCommaPos = StrFind(vAddress, ",");
	If vCommaPos = 0 Then
		vAddrElements.Street = TrimAll(vAddress);
		Return vAddrElements;
	EndIf;	
	vAddrElements.Street = TrimAll(Left(vAddress, vCommaPos-1));
	vAddress = Mid(vAddress, vCommaPos+1);
	// House
	vCommaPos = StrFind(vAddress, ",");
	If vCommaPos = 0 Then
		vAddrElements.House = TrimAll(vAddress);
		Return vAddrElements;
	EndIf;	
	vAddrElements.House = TrimAll(Left(vAddress, vCommaPos-1));
	vAddress = Mid(vAddress, vCommaPos+1);
	// Flat
	vAddrElements.Flat = TrimAll(vAddress);
	// Return address structure
	Return vAddrElements;
EndFunction // cmParseAddress

// -----------------------------------------------------------------------------
// Description: Builds address string from the list of address elements like
//              country, region, district, city, street, house, flat and so on
// Parameters: Address elements
// Return value: Address string
// -----------------------------------------------------------------------------
Function cmBuildAddress(pCountry = "", pPostCode = "", pRegion = "", pArea = "", pCity = "", pStreet = "", pHouse = "", pFlat = "") Export
	// Build address string
	vAddress = TrimAll(pCountry) + ", " + 
	           TrimAll(pPostCode) + ", " +  
	           TrimAll(pRegion) + ", " +  
	           TrimAll(pArea) + ", " +  
	           TrimAll(pCity) + ", " +  
	           TrimAll(pStreet) + ", " +  
	           TrimAll(pHouse) + ", " +  
	           TrimAll(pFlat);
	// Remove trailing commas and blanks
	vAddress = TrimAll(vAddress);
	vLen = StrLen(vAddress);
	i = vLen;
	While i > 0 Do
		vChar = Mid(vAddress, i, 1);
		If vChar <> "," And vChar <> " " Then
			Break;
		Else
			If i > 1 Then
				vAddress = Left(vAddress, i - 1);
			Else
				vAddress = "";
			EndIf;
		EndIf;
		i = i - 1;
	EndDo;
	// Return address
	Return vAddress;
EndFunction // cmBuildAddress

// -----------------------------------------------------------------------------
// Description: Converts address string to the human readable form
// Parameters: Address string
// Return value: Human readable address string
// -----------------------------------------------------------------------------
Function cmGetAddressPresentation(pAddress) Export
	vAddress = TrimAll(pAddress);
	If StrFind(vAddress, Chars.LF) > 0 Then
		Return vAddress;
	EndIf;
	While Left(vAddress, 1) = "," Do
		If Left(vAddress, 2) = ", " Then
			vAddress = Right(vAddress, StrLen(vAddress)-2);
		ElsIf Left(vAddress, 1) = "," Then
			vAddress = Right(vAddress, StrLen(vAddress)-1);
		EndIf;
		vAddress = TrimAll(vAddress);
	EndDo;
	vAddress = StrReplace(vAddress, " , ", "");
	vAddress = StrReplace(vAddress, ", , ", ", ");
	vAddress = StrReplace(vAddress, ", , ", ", ");
	vAddress = StrReplace(vAddress, ", , ", ", ");
	vAddress = StrReplace(vAddress, ", , ", ", ");
	vAddress = StrReplace(vAddress, ", , ", ", ");
	vAddress = StrReplace(vAddress, ",,", ",");
	vAddress = StrReplace(vAddress, ",,", ",");
	vAddress = StrReplace(vAddress, ",,", ",");
	vAddress = StrReplace(vAddress, ",,", ",");
	vAddress = StrReplace(vAddress, ",,", ",");
	vAddress = StrReplace(vAddress, "корп.", "к.");
	vAddress = StrReplace(vAddress, "Корп.", "к.");
	vAddress = StrReplace(vAddress, "кор.", "к.");
	vAddress = StrReplace(vAddress, "Кор.", "к.");
	vAddress = StrReplace(vAddress, "стр.", "с.");
	vAddress = StrReplace(vAddress, "Стр.", "с.");
	Return TrimAll(vAddress);
EndFunction // cmGetAddressPresentation

// -----------------------------------------------------------------------------
// Description: Removes prefix and leading zeros from the document number
// Parameters: Document number
// Return value: Document number presentation
// -----------------------------------------------------------------------------
Function cmGetDocumentNumberPresentation(pNumber) Export
	vNumberPresentation = "";
	vNumber = TrimAll(pNumber);
	Try
		vNumberLength = StrLen(vNumber);
		vPrefixLength = 0;
		For i = 1 To vNumberLength Do
			vChar = Mid(vNumber, i, 1);
			If (vChar < "0" Or vChar > "9") And vChar <> "/" Then
				vPrefixLength = i;
			EndIf;
		EndDo;
		If vPrefixLength < vNumberLength Then
			vNumberPresentation = Mid(vNumber, vPrefixLength + 1);
			vNumberPresentation = Format(Number(vNumberPresentation), "ND=12; NFD=0; NG=");
		EndIf;
		If IsBlankString(vNumberPresentation) Then
			vNumberPresentation = vNumber;
		EndIf;
	Except
		vNumberPresentation = TrimAll(pNumber);
	EndTry;
	Return vNumberPresentation;
EndFunction // cmGetDocumentNumberPresentation	

// -----------------------------------------------------------------------------
// Description: Removes leading zeros from the document number
// Parameters: Document number
// Return value: Document number presentation
// -----------------------------------------------------------------------------
Function cmRemoveLeadingZeroes(pNumber) Export
	vNumberPresentation = "";
	vNumber = TrimAll(pNumber);
	Try
		vNumberLength = StrLen(vNumber);
		For i = 1 To vNumberLength Do
			vChar = Mid(vNumber, i, 1);
			If vChar <> "0" Then
				Break;
			EndIf;
		EndDo;
		If i < vNumberLength Then
			vNumberPresentation = Mid(vNumber, i);
		EndIf;
		If IsBlankString(vNumberPresentation) Then
			vNumberPresentation = vNumber;
		EndIf;
	Except
		vNumberPresentation = TrimAll(pNumber);
	EndTry;
	Return vNumberPresentation;
EndFunction // cmRemoveLeadingZeroes	

// -----------------------------------------------------------------------------
// Description: Formats document date to the dd.MM.yyyy form
// Parameters: Date
// Return value: Date formatted
// -----------------------------------------------------------------------------
Function cmGetDocumentDatePresentation(pDate) Export
	Return Format(pDate, "DF=dd.MM.yyyy");
EndFunction // cmGetDocumentDatePresentation

// -----------------------------------------------------------------------------
// Description: Restores full document number (with prefix and leading zeros) from
//              document number presentation
// Parameters: Document number presentation, Hotel
// Return value: Document number
// -----------------------------------------------------------------------------
Function cmGetDocumentNumberFromPresentation(pNumberPresentation, pHotel, pCompany = Undefined) Export
	vNumber = "";
	vPresentation = TrimAll(pNumberPresentation);
	If StrLen(vPresentation) = 12 Then
		Return vPresentation;
	EndIf;
	If Not IsBlankString(vPresentation) Then
		Try
			vPrefix = "";
			If ValueIsFilled(pCompany) And Not IsBlankString(pCompany.Prefix) Then
				vPrefix = TrimAll(pCompany.Prefix);
			ElsIf ValueIsFilled(pHotel) Then
				vPrefix = Catalogs.Hotels.pmGetPrefix(pHotel);
			ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
				vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
			EndIf;
			If Not IsBlankString(vPrefix) Then
				If Left(vPresentation, Min(StrLen(vPrefix), StrLen(vPresentation))) <> vPrefix Then
					vPresentation = vPrefix + Format(Number(vPresentation), "ND=" + String(12 - StrLen(vPrefix)) + "; NZ=; NLZ=; NG=");
				EndIf;
			Else
				vPresentation = Format(Number(vPresentation), "ND=12; NZ=; NLZ=; NG=");
			EndIf;
		Except
		EndTry;
		vNumber = vPresentation;
	EndIf;
	Return vNumber;
EndFunction // cmGetDocumentNumberFromPresentation

// -----------------------------------------------------------------------------
// Description: Rounds number
// Parameters: Number to round, number of decimal digits
// Return value: Rounded number
// -----------------------------------------------------------------------------
Function cmRound(pNum, pDigits) Export
	Return Round(pNum, pDigits);
EndFunction // cmRound 

// -----------------------------------------------------------------------------
// Description: Rounds date to the int number of hours (fraction = 1) or 
//              minutes (fraction = 2)
// Parameters: Date, Round precision
// Return value: Date
// -----------------------------------------------------------------------------
Function cmRoundDate(pDate, pFraction = 0) Export
	vDate = pDate;
	If pFraction = 0 Then
		vDate = BegOfDay(pDate);
	ElsIf pFraction = 1 Then
		vDate = BegOfDay(pDate) + Hour(pDate) * 3600 + ?(Minute(pDate) >= 30, 3600, 0);
	ElsIf pFraction = 2 Then
		vDate = BegOfDay(pDate) + Hour(pDate) * 3600 + Minute(pDate) + ?(Second(pDate) >= 30, 60, 0);
	EndIf;
	Return vDate;
EndFunction // cmRoundDate

// -----------------------------------------------------------------------------
// Description: Rounds date to necessary number of hours
// Parameters: Date, Number of hours
// Return value: Date
// -----------------------------------------------------------------------------
Function cmRoundHours(pDate, pNumHours = 1) Export
	Return BegOfDay(pDate) + Round(Hour(pDate)/pNumHours, 0) * pNumHours * 3600;
EndFunction // cmRoundHours

// -----------------------------------------------------------------------------
// Description: Tries to find and return country by contry code
// Parameters: Country code
// Return value: Country or empty reference
// -----------------------------------------------------------------------------
Function cmGetCountryByCode(pCountryCode) Export
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	Countries.Ref
		|FROM
		|	Catalog.Countries AS Countries
		|WHERE
		|	(Countries.Code = &qCode
		|			OR Countries.ISOCode3 = &qCode
		|			OR Countries.ISOCode = &qCode
		|			OR Countries.Description = &qCode)
		|	AND NOT Countries.IsFolder
		|	AND NOT Countries.DeletionMark";
	
	vQuery.SetParameter("qCode", TrimAll(pCountryCode));
	
	vQueryResult = vQuery.Execute().Unload();
	
	For each vRow in vQueryResult Do
		vCountry = vRow.Ref;
	EndDo;
		
	Return vCountry;
EndFunction // cmGetCountryByCode

// -----------------------------------------------------------------------------
// Description: Tries to find and return region by region code and country
// Parameters: Region code, Country
// Return value: Region or empty reference
// -----------------------------------------------------------------------------
Function cmGetRegionByCode(pRegionCode, pCountry) Export
	vRegion = Catalogs.Regions.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Regions.Ref AS Region
	|FROM
	|	Catalog.Regions AS Regions
	|WHERE
	|	Regions.Code = &qRegionCode
	|	AND Regions.Country = &qCountry
	|	AND Regions.DeletionMark = FALSE";
	vQry.SetParameter("qRegionCode", pRegionCode);
	vQry.SetParameter("qCountry", pCountry);
	vList = vQry.Execute().Unload();
	For Each vListRow In vList Do
		vRegion = vListRow.Region;
		Break;
	EndDo;
	Return vRegion;
EndFunction // cmGetRegionByCode

// -----------------------------------------------------------------------------
// Description: Tries to find and return abbreviation by code and level as bbreviation type
// Parameters: Code, Abbreviation type
// Return value: Abbreviation or empty reference
// -----------------------------------------------------------------------------
Function cmGetAbbreviationByCode(pAbbreviation, pAbbreviationType) Export
	vRef = Catalogs.Abbreviations.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Abbreviations.Ref AS Ref
	|FROM
	|	Catalog.Abbreviations AS Abbreviations
	|WHERE
	|	Abbreviations.Abbreviation = &qAbbreviation
	|	AND Abbreviations.AbbreviationType = &qAbbreviationType
	|	AND Abbreviations.DeletionMark = FALSE";
	vQry.SetParameter("qAbbreviation", pAbbreviation);
	vQry.SetParameter("qAbbreviationType", pAbbreviationType);
	vRefs = vQry.Execute().Unload();
	For Each vRefsRow In vRefs Do
		vRef = vRefsRow.Ref;
		Break;
	EndDo;
	Return vRef;
EndFunction // cmGetAbbreviationByCode

// -----------------------------------------------------------------------------
// Description: Tries to find and return region by region description and country
// Parameters: Region description, Country
// Return value: Region or empty reference
// -----------------------------------------------------------------------------
Function cmGetRegionByDescription(pRegionDescription, pCountry) Export
	vRegion = Catalogs.Regions.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Regions.Ref AS Region
	|FROM
	|	Catalog.Regions AS Regions
	|WHERE
	|	Regions.Description = &qRegionDescription
	|	AND Regions.Country = &qCountry
	|	AND Regions.DeletionMark = FALSE";
	vQry.SetParameter("qRegionDescription", TrimAll(pRegionDescription));
	vQry.SetParameter("qCountry", pCountry);
	vList = vQry.Execute().Unload();
	For Each vListRow In vList Do
		vRegion = vListRow.Region;
		Break;
	EndDo;
	Return vRegion;
EndFunction // cmGetRegionByDescription

// -----------------------------------------------------------------------------
// Description: Tries to find and return area (district) by area code, region and country
// Parameters: Area code, Country, Region
// Return value: Area or empty reference
// -----------------------------------------------------------------------------
Function cmGetAreaByCode(pAreaCode, pCountry, pRegion) Export
	vArea = Catalogs.Areas.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Areas.Ref AS Area
	|FROM
	|	Catalog.Areas AS Areas
	|WHERE
	|	Areas.Code = &qAreaCode
	|	AND Areas.Country = &qCountry
	|	AND Areas.Region = &qRegion
	|	AND Areas.DeletionMark = FALSE";
	vQry.SetParameter("qAreaCode", pAreaCode);
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qRegion", pRegion);
	vList = vQry.Execute().Unload();
	For Each vListRow In vList Do
		vArea = vListRow.Area;
		Break;
	EndDo;
	Return vArea;
EndFunction // cmGetAreaByCode

// -----------------------------------------------------------------------------
// Description: Tries to find and return area (district) by area description, region and country
// Parameters: Area description, Country, Region
// Return value: Area or empty reference
// -----------------------------------------------------------------------------
Function cmGetAreaByDescription(pAreaDescription, pCountry, pRegion) Export
	vArea = Catalogs.Areas.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Areas.Ref AS Area
	|FROM
	|	Catalog.Areas AS Areas
	|WHERE
	|	Areas.Description = &qAreaDescription
	|	AND Areas.Country = &qCountry
	|	AND Areas.Region = &qRegion
	|	AND Areas.DeletionMark = FALSE";
	vQry.SetParameter("qAreaDescription", TrimAll(pAreaDescription));
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qRegion", pRegion);
	vList = vQry.Execute().Unload();
	For Each vListRow In vList Do
		vArea = vListRow.Area;
		Break;
	EndDo;
	Return vArea;
EndFunction // cmGetAreaByDescription

// -----------------------------------------------------------------------------
// Description: Tries to find and return city by city code, area, region and country
// Parameters: City code, Country, Region, Area
// Return value: City or empty reference
// -----------------------------------------------------------------------------
Function cmGetCityByCode(pCityCode, pCountry, pRegion, pArea) Export
	vCity = Catalogs.Cities.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Cities.Ref AS City
	|FROM
	|	Catalog.Cities AS Cities
	|WHERE
	|	Cities.Code = &qCityCode
	|	AND Cities.Country = &qCountry
	|	AND Cities.Region = &qRegion
	|	AND Cities.Area = &qArea
	|	AND Cities.DeletionMark = FALSE";
	vQry.SetParameter("qCityCode", pCityCode);
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qRegion", pRegion);
	vQry.SetParameter("qArea", pArea);
	vList = vQry.Execute().Unload();
	For Each vListRow In vList Do
		vCity = vListRow.City;
		Break;
	EndDo;
	Return vCity;
EndFunction // cmGetCityByCode

// -----------------------------------------------------------------------------
// Description: Tries to find and return city by city description, area, region and country
// Parameters: City description, Country, Region, Area
// Return value: City or empty reference
// -----------------------------------------------------------------------------
Function cmGetCityByDescription(pCityDescription, pCountry, pRegion, pArea) Export
	vCity = Catalogs.Cities.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Cities.Ref AS City
	|FROM
	|	Catalog.Cities AS Cities
	|WHERE
	|	Cities.Description = &qCityDescription
	|	AND Cities.Country = &qCountry
	|	AND Cities.Region = &qRegion
	|	AND Cities.Area = &qArea
	|	AND Cities.DeletionMark = FALSE";
	vQry.SetParameter("qCityDescription", TrimAll(pCityDescription));
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qRegion", pRegion);
	vQry.SetParameter("qArea", pArea);
	vList = vQry.Execute().Unload();
	For Each vListRow In vList Do
		vCity = vListRow.City;
		Break;
	EndDo;
	Return vCity;
EndFunction // cmGetCityByDescription

// -----------------------------------------------------------------------------
// Description: Tries to find and return street by street code, city, area, region and country
// Parameters: Street code, Country, Region, Area, City
// Return value: Street or empty reference
// -----------------------------------------------------------------------------
Function cmGetStreetByCode(pStreetCode, pCountry, pRegion, pArea, pCity) Export
	vStreet = Catalogs.Streets.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Streets.Ref AS Street
	|FROM
	|	Catalog.Streets AS Streets
	|WHERE
	|	Streets.Code = &qStreetCode
	|	AND Streets.Country = &qCountry
	|	AND Streets.Region = &qRegion
	|	AND Streets.Area = &qArea
	|	AND Streets.City = &qCity
	|	AND Streets.DeletionMark = FALSE";
	vQry.SetParameter("qStreetCode", pStreetCode);
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qRegion", pRegion);
	vQry.SetParameter("qArea", pArea);
	vQry.SetParameter("qCity", pCity);
	vList = vQry.Execute().Unload();
	For Each vListRow In vList Do
		vStreet = vListRow.Street;
		Break;
	EndDo;
	Return vStreet;
EndFunction // cmGetStreetByCode

// -----------------------------------------------------------------------------
// Description: Tries to find and return street by street description, city, area, region and country
// Parameters: Street description, Country, Region, Area, City
// Return value: Street or empty reference
// -----------------------------------------------------------------------------
Function cmGetStreetByDescription(pStreetDescription, pCountry, pRegion, pArea, pCity) Export
	vStreet = Catalogs.Streets.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Streets.Ref AS Street
	|FROM
	|	Catalog.Streets AS Streets
	|WHERE
	|	Streets.Description = &qStreetDescription
	|	AND Streets.Country = &qCountry
	|	AND Streets.Region = &qRegion
	|	AND Streets.Area = &qArea
	|	AND Streets.City = &qCity
	|	AND Streets.DeletionMark = FALSE";
	vQry.SetParameter("qStreetDescription", TrimAll(pStreetDescription));
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qRegion", pRegion);
	vQry.SetParameter("qArea", pArea);
	vQry.SetParameter("qCity", pCity);
	vList = vQry.Execute().Unload();
	For Each vListRow In vList Do
		vStreet = vListRow.Street;
		Break;
	EndDo;
	Return vStreet;
EndFunction // cmGetStreetByDescription

// -----------------------------------------------------------------------------
// Procedure is used to initalize data processor object attributes from the
// parameters saved in the data processor catalog item
// -----------------------------------------------------------------------------
Procedure cmLoadDataProcessorAttributes(pDPObject, pParameter = Undefined) Export
	// Rename input parameters to the name being used to 
	// address attributes in dynamic parameters calculation
	DPO = pDPObject;
	PARM = pParameter;
	// Get reference to the DataProcessor catalog item
	vDP = DPO.DataProcessor;
	If ValueIsFilled(vDP) Then
		// 1. Apply static parameters if are filled
		vStatic = vDP.StaticParameters.Get();
		If vStatic <> Undefined Then
			// Static parameters are simple structure
			FillPropertyValues(DPO, vStatic);
			// Load data processor tabular parts
			For Each vTP In DPO.Metadata().TabularSections Do
				Try
					DPO[vTP.Name].Load(vStatic["TP_" + vTP.Name]);
				Except
				EndTry;
			EndDo;
		EndIf;
		// 2. Apply current hotel
		Try
			If Not Constants.DoNotFillDataProcessorHotelAttributeFromSessionParameters.Get() And 
			   Not vDP.DoNotFillHotelFromSessionParameters Then
				DPO.Hotel = SessionParameters.CurrentHotel;
			EndIf;
		Except
		EndTry;
		// 3. Apply dynamic parameters if are filled
		// "Dynamic parameters" is piece of source code working with DPO variable attributes.
		// F.e. the following sentence will be executed smoothly:
		// "DPO.PeriodFrom = BegOfDay(CurrentSessionDate());"
		// PARM input parameter also could be used in calculations and could be of any type. 
		// F.e. it could be used to set up current Hotel in the following example code:
		// "DPO.Hotel = PARM;"
		vDynamic = TrimAll(vDP.DynamicParameters);
		If Not IsBlankString(vDynamic) Then
			Execute(vDynamic);
		EndIf;
		// 4. Call default attributes initialization procedure if static parameters were not set 
		If vStatic = Undefined Then
			// Fill attributes with default values
			DPO.pmFillAttributesWithDefaultValues();
		EndIf;
	Else
		// Fill attributes with default values
		DPO.pmFillAttributesWithDefaultValues();
	EndIf;
	// Check parameters
	If TypeOf(PARM) = Type("Structure") Then
		FillPropertyValues(DPO, PARM);
	EndIf;
EndProcedure // cmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
// Procedure is used to initalize report object attributes from the
// parameters saved in the report catalog item
// -----------------------------------------------------------------------------
Procedure cmLoadReportAttributes(pRepObject, pParameter = Undefined) Export
	// Rename input parameters to the name being used to 
	// address attributes in dynamic parameters calculation
	REP = pRepObject;
	PARM = pParameter;
	// Initialize report builder
	Try
		REP.pmInitializeReportBuilder();
	Except
	EndTry;
	// Get reference to the Report catalog item
	vRep = REP.Report;
	If ValueIsFilled(vRep) Then
		vStatic = Undefined;
		// Try to find record in the user current unsaved report settings register
		vCurSession = GetCurrentInfoBaseSession();
		vRSMgr = InformationRegisters.CurrentUnsavedReportSettings.CreateRecordManager();
		vRSMgr.Report = vRep;
		vRSMgr.Employee = SessionParameters.CurrentUser;
		vRSMgr.SessionID = vCurSession.SessionNumber;
		vRSMgr.Read();
		If vRSMgr.Selected() Then
			vStatic = vRSMgr.StaticParameters.Get();
		EndIf;
		// Load report settings from the report static parameters
		If vStatic = Undefined Then
			vStatic = vRep.StaticParameters.Get();
		EndIf;
		// 1. Apply static parameters if are filled
		If vStatic <> Undefined Then
			// Static parameters are simple structure
			FillPropertyValues(REP, vStatic);
			// Load report builder settings
			Try
				If vStatic.ReportBuilderSettings <> Undefined Then
					REP.ReportBuilder.SetSettings(vStatic.ReportBuilderSettings, True, True, True, True, True);
				EndIf;
			Except
			EndTry;
			
			// Load report builder settings
			Try
				If vStatic.SettingsComposer <> Undefined Then
					REP.SettingsComposer.LoadSettings(vStatic.SettingsComposer);
				EndIf;
			Except
			EndTry;
		EndIf;
		// 2. Apply current hotel
		Try
			REP.Hotel = SessionParameters.CurrentHotel;
		Except
		EndTry;
		// 3. Apply dynamic parameters if are filled
		// "Dynamic parameters" is piece of source code working with REP variable attributes.
		// F.e. the following sentence will be executed smoothly:
		// "REP.PeriodFrom = BegOfDay(CurrentSessionDate());"
		// PARM input parameter also could be used in calculations and could be of any type. 
		// F.e. it could be used to set up current Hotel in the following example code:
		// "REP.Hotel = PARM;"
		vDynamic = TrimAll(vRep.DynamicParameters);
		If Not IsBlankString(vDynamic) Then
			Execute(vDynamic);
		EndIf;
		// 4. Call default attributes initialization procedure if static parameters were not set 
		If vStatic = Undefined Then
			// Fill attributes with default values
			REP.pmFillAttributesWithDefaultValues();
		EndIf;
		// 5. Fill report builder header text with the report description
		Try
			If IsBlankString(vRep.ReportHeaderText) Then
				REP.ReportBuilder.HeaderText = cmNStr(vRep.Description);
			Else
				REP.ReportBuilder.HeaderText = cmNStr(vRep.ReportHeaderText);
			EndIf;
		Except
		EndTry;
	Else
		// Fill attributes with default values
		REP.pmFillAttributesWithDefaultValues();
	EndIf;
	// Check parameters
	If TypeOf(PARM) = Type("Structure") Then
		FillPropertyValues(REP, PARM);
	EndIf;
EndProcedure // cmLoadReportAttributes

// -----------------------------------------------------------------------------
// Description: Applies report builder settings saved in the report catalog item
//              to the report builder object
// Parameters: Report catalog item object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmApplyReportBuilderSettings(pRepObject) Export
	// Get reference to the Report catalog item
	vRep = pRepObject.Report;
	If ValueIsFilled(vRep) Then
		vStatic = vRep.StaticParameters.Get();
		If vStatic <> Undefined Then
			// Load report builder settings
			Try
				If vStatic.ReportBuilderSettings <> Undefined Then
					pRepObject.ReportBuilder.SetSettings(vStatic.ReportBuilderSettings, True, True, True, True, True);
				EndIf;
			Except
			EndTry;
		EndIf;
	EndIf;
EndProcedure // cmApplyReportBuilderSettings

// -----------------------------------------------------------------------------
// Description: Saves current data processor object attributes to the data
//              processor catalog item
// Parameters: Data processor object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSaveDataProcessorAttributes(pDPObject) Export
	// Get reference to the DataProcessor catalog item
	vDP = pDPObject.DataProcessor;
	If ValueIsFilled(vDP) Then
		vDPObj = vDP.GetObject();
		// Initialize structure of the static parameters
		vStatic = New Structure();
		For Each vAttr In pDPObject.Metadata().Attributes Do
			If vAttr.Name <> "DataProcessor" And vAttr.Name <> "ExternalSystemInteractionsObj" Then
				vStatic.Insert(vAttr.Name);
			EndIf;
		EndDo;
		// Fill structure from the data processor object attributes
		FillPropertyValues(vStatic, pDPObject);
		// Save all tabular parts
		For Each vTP In pDPObject.Metadata().TabularSections Do
			vStatic.Insert("TP_" + vTP.Name, pDPObject[vTP.Name].Unload());
		EndDo;
		// Save structure in the value storage of the data processor catalog item
		vStaticVS = New ValueStorage(vStatic);
		vDPObj.StaticParameters = vStaticVS;
		vDPObj.Write();
		// Dynamic parameters could be changed only from the 
		// Data processor catalog item form
	EndIf;
EndProcedure // cmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Description: Saves current report object attributes to the report catalog item
// Parameters: Report object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSaveReportAttributes(pRepObject, pComposeTemplate = Undefined, pSaveToTempSettings = False) Export
	// Get reference to the Report catalog item
	vRep = pRepObject.Report;
	If ValueIsFilled(vRep) Then
		vRepObj = vRep.GetObject();
		// Initialize structure of the static parameters
		vStatic = New Structure();
		For Each vAttr In pRepObject.Metadata().Attributes Do
			If vAttr.Name <> "Report" And vAttr.Name <> "ReportBuilder" Then
				vStatic.Insert(vAttr.Name);
			EndIf;
		EndDo;
		// Fill structure from the report object attributes
		FillPropertyValues(vStatic, pRepObject);
		// Save report builder settings
		Try
			If pRepObject.ReportBuilder <> Undefined Then
				vStatic.Insert("ReportBuilderSettings", pRepObject.ReportBuilder.GetSettings(True, True, True, True, True));
			EndIf;
		Except
		EndTry;
		// Save Data composition settings
		Try
			If pRepObject.SettingsComposer <> Undefined Then
				vStatic.Insert("SettingsComposer", pRepObject.SettingsComposer.GetSettings());
			EndIf;
		Except
		EndTry;
		vStaticVS = New ValueStorage(vStatic);
		If pSaveToTempSettings Then
			// Create record to the "Current unsaved report settings"
			vCurSession = GetCurrentInfoBaseSession();
			vRSMgr = InformationRegisters.CurrentUnsavedReportSettings.CreateRecordManager();
			vRSMgr.Report = vRep;
			vRSMgr.Employee = SessionParameters.CurrentUser;
			vRSMgr.SessionID = vCurSession.SessionNumber;
			vRSMgr.StaticParameters = vStaticVS;
			vRSMgr.Write(True);
		Else
			// Save structure in the value storage of the report catalog item
			vRepObj.StaticParameters = vStaticVS;
			vRepObj.Write();
		EndIf;
		// Dynamic parameters could be changed only from the report catalog item form
	EndIf;
EndProcedure // cmSaveReportAttributes

// -----------------------------------------------------------------------------
// Try to find record in the user current unsaved report settings register and delete it
// -----------------------------------------------------------------------------
Procedure cmClearCurrentUnsavedReportSettings(pRep) Export
	vCurSession = GetCurrentInfoBaseSession();
	vRSMgr = InformationRegisters.CurrentUnsavedReportSettings.CreateRecordManager();
	vRSMgr.Report = pRep;
	vRSMgr.Employee = SessionParameters.CurrentUser;
	vRSMgr.SessionID = vCurSession.SessionNumber;
	vRSMgr.Read();
	If vRSMgr.Selected() Then
		vRSMgr.Delete();
	EndIf;
EndProcedure // cmClearCurrentUnsavedReportSettings 

// -----------------------------------------------------------------------------
// Description: Returns structure of data processor object attributes converted to the
//              value storage to save it to the data processor catalog item
// Parameters: Data processor object
// Return value: Value storage from the structure of data processor object attributes 
// -----------------------------------------------------------------------------
Function cmGetDataProcessorStaticParametersValue(pObject) Export
	// Initialize structure of the static parameters
	vStatic = New Structure();
	For Each vAttr In pObject.Metadata().Attributes Do
		If vAttr.Name <> "DataProcessor" And vAttr.Name <> "ExternalSystemInteractionsObj" Then
			vStatic.Insert(vAttr.Name);
		EndIf;
	EndDo;
	// Fill structure from the report object attributes
	FillPropertyValues(vStatic, pObject);
	// Create value storage
	Return New ValueStorage(vStatic);
EndFunction // cmGetDataProcessorStaticParametersValue

// -----------------------------------------------------------------------------
// Description: Returns structure of report object attributes converted to the
//              value storage to save it to the report catalog item
// Parameters: Report object
// Return value: Value storage from the structure of report object attributes 
// -----------------------------------------------------------------------------
Function cmGetReportStaticParametersValue(pObject) Export
	// Initialize structure of the static parameters
	vStatic = New Structure();
	For Each vAttr In pObject.Metadata().Attributes Do
		If vAttr.Name <> "Report" And vAttr.Name <> "ReportBuilder" Then
			vStatic.Insert(vAttr.Name);
		EndIf;
	EndDo;
	// Fill structure from the report object attributes
	FillPropertyValues(vStatic, pObject);
	// Save report builder settings
	Try
		If pObject.ReportBuilder <> Undefined Then
			vStatic.Insert("ReportBuilderSettings", pObject.ReportBuilder.GetSettings(True, True, True, True, True));
		EndIf;
	Except
	EndTry;
	// Create value storage
	Return New ValueStorage(vStatic);
EndFunction // cmGetReportStaticParametersValue

// -----------------------------------------------------------------------------
// Description: Returns list of reports based on reports catalog folder or item
// Parameters: Report catalog folder or item
// Return value: Value table with report catalog items 
// -----------------------------------------------------------------------------
Function cmGetListOfReportsToRun(pReport) Export
	vReps = New ValueTable();
	vReps.Columns.Add("Report", cmGetCatalogTypeDescription("Reports")); 
	// Fill list of reports to run	
	If pReport.IsFolder Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Reports.Ref AS Report
		|FROM
		|	Catalog.Reports AS Reports
		|WHERE
		|	Reports.Ref IN HIERARCHY (&qRepFolder)
		|	AND Reports.DeletionMark = FALSE
		|	AND Reports.IsFolder = FALSE
		|ORDER BY
		|	Reports.SortCode";
		vQry.SetParameter("qRepFolder", pReport);
		vReps = vQry.Execute().Unload();
	Else
		If Not pReport.DeletionMark Then
			vRepRow = vReps.Add();
			vRepRow.Report = pReport;
		Else
			Raise NStr("ru = 'Попытка выполнения помеченного на удаление отчета " + pReport + ". Выполнение невозможно!'; 
			           |de = 'Попытка выполнения помеченного на удаление отчета " + pReport + ". Выполнение невозможно!'; 
			           |en = 'Attempt to run report " + pReport + " with deletion mark set. Failed to proceed!'");
		EndIf;
	EndIf;
	Return vReps;
EndFunction // cmGetListOfReportsToRun

// -----------------------------------------------------------------------------
// Description: Returns report object based on report catalog item
// Parameters: Report catalog item reference
// Return value: Report object
// -----------------------------------------------------------------------------
Function cmBuildReportObject(pRep) Export
	vRepObj = Undefined;
	If Not pRep.IsExternal Then
		vRepObj = Reports[TrimAll(pRep.Report)].Create();
	Else
		If pRep.Report.ExternalProcessingType = Enums.ExternalProcessingTypes.Report Then
			vRepObj = cmGetExternalDataProcessorObject(pRep.Report);
		ElsIf pRep.Report.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			vAlgorithm = TrimAll(pRep.Report.Algorithm);
			Execute(vAlgorithm);
		Else
			Raise NStr("ru = 'Попытка выполнения внешнего отчета с типом отличным от ""Отчет"" и ""Алгоритм"". Выполнение невозможно!'; 
			           |de = 'Versuch, den externen Bericht mit einem anderen Typ als ""Bericht"" und ""Algorithmus"" auszuführen. Ausführung ist nicht möglich!'; 
					   |en = 'Attempt to run external report with type different then ""Report"" and ""Algorithm"". Failed to proceed!'");
		EndIf;
	EndIf;
	Return vRepObj;
EndFunction // cmBuildReportObject

// -----------------------------------------------------------------------------
// Description: Generates reports catalog item report
// Parameters: Reports catalog item reference, Report parameter, 
//             Whether to generate report on form open or show empty report
// Return value: True if report was successfully generated, False if exception was raised
// -----------------------------------------------------------------------------
Function cmGenerateReport(pReport, pParameter = Undefined, pGenerateOnOpen = True) Export
	Try
		// Initialize list of reports to run
		vReps = cmGetListOfReportsToRun(pReport);
		// Run each report from the list
		For Each vRepRow In vReps Do
			// Check user rights to open report
			If Not cmCheckUserRightsToOpenReport(vRepRow.Report) Then 
				vMessage = StrTemplate(NStr("en='You do not have rights to run report: %1!';ru='Нет прав на формирование отчета: %1!';de='Sie haben keine Rechte, einen Bericht zu erstellen: %1!'"), cmNStr(vRepRow.Report.Description)); 
				Raise vMessage;
			EndIf;
			vRepObj = cmBuildReportObject(vRepRow.Report);
			If vRepObj <> Undefined Then
				// Initialize report settings
				Try
					// Fill reference to the report catalog item
					vRepObj.Report = vRepRow.Report;
					// Load report catalog item attributes
					vRepObj.pmLoadReportAttributes(pParameter);
					// Open report's default form
					#IF ThickClientOrdinaryApplication THEN
						If TypeOf(vRepObj) = Type("ReportObject.ResortFeeOperatorReport") Then
							vRepFrm = OpenForm("Report.ResortFeeOperatorReport.ObjectForm", New Structure("GenerateOnOpen", pGenerateOnOpen));
						ElsIf TypeOf(vRepObj) = Type("ReportObject.ResortFeeDetailsOperatorReport") Then
							vRepFrm = OpenForm("Report.ResortFeeDetailsOperatorReport.ObjectForm", New Structure("GenerateOnOpen", pGenerateOnOpen));
						Else
							vRepFrm = vRepObj.GetForm();
							vRepFrm.GenerateOnFormOpen = pGenerateOnOpen;
							vRepFrm.Open();
						EndIf;
					#ELSE
						vRepFrm = vRepObj.GetForm();
						vRepFrm.GenerateOnFormOpen = pGenerateOnOpen;
						vRepFrm.Open();
					#ENDIF
				Except
					// Open report's default form
					vRepFrm = vRepObj.GetForm();
					vRepFrm.Open();
				EndTry;
			EndIf;
		EndDo;
		Return True;
	Except
		vErrorDescription = ErrorDescription();
		vMessage = StrTemplate(NStr("ru = 'Ошибка выполнения отчета %1! Описание ошибки: %2'; 
		                |de = 'Fehler beim Ausführen des Berichts %1! Fehlerbeschreibung: %2'; 
		                |en = 'Error executing report %1! Error description: %2'"), cmNStr(pReport.Description, SessionParameters.CurrentLanguage), vErrorDescription);
		WriteLogEvent(NStr("en='Report.Generate';ru='Отчет.Сформировать';de='Bericht.Generieren'"), EventLogLevel.Warning, Metadata.Catalogs.Reports, pReport, vMessage);
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return False;
	EndTry;
EndFunction // cmGenerateReport

// -----------------------------------------------------------------------------
// Description: Builds list of reports catalog items by string key value and generates them all. 
// Parameters: String report key value 
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmGenerateReportsByKey(pKey) Export
	// Get catalog items by key
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reports.Ref AS Report
	|FROM
	|	Catalog.Reports AS Reports
	|WHERE
	|	Reports.Key = &qKey
	|	AND Reports.DeletionMark = FALSE
	|
	|ORDER BY
	|	Reports.SortCode,
	|	Reports.Code";
	vQry.SetParameter("qKey", pKey);
	vRepList = vQry.Execute().Unload();
	// Run all retrieved reports
	For Each vRepRow In vRepList Do
		vRepRef = vRepRow.Report;
		cmGenerateReport(vRepRef);
	EndDo;
EndProcedure // cmGenerateReportsByKey

// -----------------------------------------------------------------------------
// Description: Builds list of data processors catalog items for the data processors
//              catalog folder or item given
// Parameters: Data processors catalog folder or item
// Return value: Value table with list of data processors catalog items
// -----------------------------------------------------------------------------
Function cmGetListOfDataProcessorsToRun(pDataProcessor) Export
	vDPs = New ValueTable();
	vDPs.Columns.Add("DataProcessor", cmGetCatalogTypeDescription("DataProcessors")); 
	// Fill list of data processors to run	
	If pDataProcessor.IsFolder Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	DataProcessors.Ref AS DataProcessor
		|FROM
		|	Catalog.DataProcessors AS DataProcessors
		|WHERE
		|	DataProcessors.Ref IN HIERARCHY(&qDPFolder)
		|	AND DataProcessors.DeletionMark = FALSE
		|	AND DataProcessors.IsFolder = FALSE
		|
		|ORDER BY
		|	DataProcessors.SortCode,
		|	DataProcessors.Code";
		vQry.SetParameter("qDPFolder", pDataProcessor);
		vDPs = vQry.Execute().Unload();
	Else
		If Not pDataProcessor.DeletionMark Then
			vDPRow = vDPs.Add();
			vDPRow.DataProcessor = pDataProcessor;
		Else
			Raise NStr("ru = 'Попытка выполнения помеченной на удаление процедуры " + pDataProcessor + ". Выполнение невозможно!'; 
			           |de = 'Attempt to run data processor " + pDataProcessor + " with deletion mark set. Failed to proceed!'; 
			           |en = 'Attempt to run data processor " + pDataProcessor + " with deletion mark set. Failed to proceed!'");
		EndIf;
	EndIf;
	Return vDPs;
EndFunction // cmGetListOfDataProcessorsToRun 

// -----------------------------------------------------------------------------
// Description: Creates data processor object from the data processor catalog item
// Parameters: Data processors catalog item
// Return value: Data processor object
// -----------------------------------------------------------------------------
Function cmBuildDataProcessorObject(pDP) Export
	vDPObj = Undefined;
	If Not pDP.IsExternal Then
		If ValueIsFilled(TrimAll(pDP.Processing)) Then
			vDPObj = DataProcessors[TrimAll(pDP.Processing)].Create();
		EndIf;
	Else
		If pDP.Processing.ExternalProcessingType = Enums.ExternalProcessingTypes.DataProcessor Then
			vDPObj = cmGetExternalDataProcessorObject(pDP.Processing);
		ElsIf pDP.Processing.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			vAlgorithm = TrimAll(pDP.Processing.Algorithm);
			Execute(vAlgorithm);
		Else
			Raise NStr("ru='Попытка выполнения внешней обработки с типом отличным от ""Обработка"" и ""Алгоритм"". Выполнение невозможно!';
			           |de='Versuch, die externe Bearbeitung mit einem anderen Typ als ""Bearbeitung"" und ""Algorithmus"" auszuführen. Ausführung ist nicht möglich!';
					   |en='Attempt to run external data processor with type different then ""Data processor"" and ""Algorithm"". Failed to proceed!'");
		EndIf;
	EndIf;
	Return vDPObj;
EndFunction // cmBuildDataProcessorObject

// -----------------------------------------------------------------------------
// Description: Builds list of data processors available in the program. 
//              List includes data processors with DataProcessor attribute available only 
// Parameters: None
// Return value: Value list of data processor names
// -----------------------------------------------------------------------------
Function cmFillDataProcessorsList() Export
	vDPList = New ValueList();
	For Each vDPMetadata In Metadata.DataProcessors Do
		// Check that DataProcessor attribute exists
		vFound = False;
		For Each vDPAttr In vDPMetadata.Attributes Do
			If vDPAttr.Name = "DataProcessor" Then
				vFound = True;
				Break;
			EndIf;
		EndDo;
		If vFound Then
			vDPList.Add(vDPMetadata.Name, vDPMetadata.Name + " - " + vDPMetadata.Presentation());
		EndIf;
	EndDo;
	Return vDPList;
EndFunction // cmFillDataProcessorsList

// -----------------------------------------------------------------------------
// Description: Builds list of reports available in the program. 
//              List includes reports with Report attribute available only 
// Parameters: None
// Return value: Value list of report names
// -----------------------------------------------------------------------------
Function cmFillReportsList() Export
	vRepList = New ValueList();
	For Each vRepMetadata In Metadata.Reports Do
		// Check that Report attribute exists
		vFound = False;
		For Each vRepAttr In vRepMetadata.Attributes Do
			If vRepAttr.Name = "Report" Then
				vFound = True;
				Break;
			EndIf;
		EndDo;
		If vFound Then
			vRepList.Add(vRepMetadata.Name, vRepMetadata.Name + " - " + vRepMetadata.Presentation());
		EndIf;
	EndDo;
	Return vRepList;
EndFunction // cmFillReportsList

// -----------------------------------------------------------------------------
// Description: Builds list of catalogs available in the program. 
//              List includes all catalogs
// Parameters: None
// Return value: Value list of catalog names
// -----------------------------------------------------------------------------
Function cmFillCatalogsList() Export
	vCatList = New ValueList();
	For Each vCatMetadata In Metadata.Catalogs Do
		vCatList.Add(vCatMetadata.Name, vCatMetadata.Name + " - " + vCatMetadata.Presentation());
	EndDo;
	Return vCatList;
EndFunction // cmFillCatalogsList

// -----------------------------------------------------------------------------
// Description: Returns SMTP authentication mode based on enum value
// Parameters: SMTP authentication types enum item
// Return value: SMTP authentication mode
// -----------------------------------------------------------------------------
Function cmGetSMTPAuthentication(pSMTPAuthentication) Export
	If ValueIsFilled(pSMTPAuthentication) Then
		If pSMTPAuthentication = Enums.SMTPAuthenticationTypes.CramMD5 Then
			Return SMTPAuthenticationMode.CramMD5;
		ElsIf pSMTPAuthentication = Enums.SMTPAuthenticationTypes.Login Then
			Return SMTPAuthenticationMode.Login;
		ElsIf pSMTPAuthentication = Enums.SMTPAuthenticationTypes.Plain Then
			Return SMTPAuthenticationMode.Plain;
		ElsIf pSMTPAuthentication = Enums.SMTPAuthenticationTypes.None Then
			Return SMTPAuthenticationMode.None;
		ElsIf pSMTPAuthentication = Enums.SMTPAuthenticationTypes.Default Then
			Return SMTPAuthenticationMode.Default;
		Else
			Return SMTPAuthenticationMode.Default;
		EndIf;
	Else
		Return SMTPAuthenticationMode.Default;
	EndIf;
EndFunction // cmGetSMTPAuthentication

// -----------------------------------------------------------------------------
// Description: Returns POP3 authentication mode based on enum value
// Parameters: POP3 authentication types enum item
// Return value: POP3 authentication mode
// -----------------------------------------------------------------------------
Function cmGetPOP3Authentication(pPOP3Authentication) Export
	If ValueIsFilled(pPOP3Authentication) Then
		If pPOP3Authentication = Enums.POP3AuthenticationTypes.CramMD5 Then
			Return POP3AuthenticationMode.CramMD5;
		ElsIf pPOP3Authentication = Enums.POP3AuthenticationTypes.APOP Then
			Return POP3AuthenticationMode.APOP;
		ElsIf pPOP3Authentication = Enums.POP3AuthenticationTypes.General Then
			Return POP3AuthenticationMode.General;
		Else
			Return POP3AuthenticationMode.General;
		EndIf;
	Else
		Return POP3AuthenticationMode.General;
	EndIf;
EndFunction // cmGetSMTPAuthentication

// -----------------------------------------------------------------------------
// Description: Returns left part of the report attribute name before point char
// Parameters: Full report attribute name
// Return value: Report attribute root name
// -----------------------------------------------------------------------------
Function cmGetReportAttributeRootName(pName) Export
	vName = TrimAll(pName);
	vPointPos = StrFind(vName, ".");
	If vPointPos > 0 Then
		If vPointPos > 1 Then
			Return Left(vName, vPointPos-1);
		Else
			Return vName;
		EndIf;
	Else
		Return vName;
	EndIf;
EndFunction // cmGetReportAttributeRootName

// -----------------------------------------------------------------------------
// Description: Fill report builder field presentations from the report template
// Parameters: Report object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillReportAttributesPresentations(pRepObj) Export
	vTemplate = pRepObj.GetTemplate("ReportTemplate");
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pRepObj.Report);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	For Each vAttr In pRepObj.ReportBuilder.AvailableFields Do
		vAttrRange = vTemplate.Areas.Find(vAttr.Name);
		If vAttrRange <> Undefined Then
			vAttr.Presentation = TrimAll(vAttrRange.Text);
		EndIf;
	EndDo;
	For Each vAttr In pRepObj.ReportBuilder.SelectedFields Do
		vAttrRange = vTemplate.Areas.Find(vAttr.Name);
		If vAttrRange <> Undefined Then
			vAttr.Presentation = TrimAll(vAttrRange.Text);
		EndIf;
	EndDo;
	For Each vAttr In pRepObj.ReportBuilder.RowDimensions Do
		vAttrRange = vTemplate.Areas.Find(vAttr.Name);
		If vAttrRange <> Undefined Then
			vAttr.Presentation = TrimAll(vAttrRange.Text);
		EndIf;
	EndDo;
	For Each vAttr In pRepObj.ReportBuilder.ColumnDimensions Do
		vAttrRange = vTemplate.Areas.Find(vAttr.Name);
		If vAttrRange <> Undefined Then
			vAttr.Presentation = TrimAll(vAttrRange.Text);
		EndIf;
	EndDo;
	For Each vAttr In pRepObj.ReportBuilder.Order Do
		vAttrRange = vTemplate.Areas.Find(vAttr.Name);
		If vAttrRange <> Undefined Then
			vAttr.Presentation = TrimAll(vAttrRange.Text);
		EndIf;
	EndDo;
EndProcedure // cmFillReportAttributesPresentations 

// -----------------------------------------------------------------------------
// Description: Replaces report query text with new one. Could be used to override 
//              report main query at the dynamic report parameter settings page
// Parameters: Report object, New query text
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetReportQueryText(pRepObj, pQueryText) Export
	pRepObj.ReportBuilder.Text = pQueryText;
	pRepObj.ReportBuilder.FillSettings();
	cmFillReportAttributesPresentations(pRepObj);
	vStatic = pRepObj.Report.StaticParameters.Get();
	If vStatic <> Undefined Then
		Try
			If vStatic.ReportBuilderSettings <> Undefined Then
				pRepObj.ReportBuilder.SetSettings(vStatic.ReportBuilderSettings, True, True, True, True, True);
			EndIf;
		Except
		EndTry;
	EndIf;
EndProcedure // cmSetReportQueryText

// -----------------------------------------------------------------------------
// Description: Sets new report main query parameter value. Could be used after 
//              report main query was replaced 
// Parameters: Report object, Parameter name, Parameter value
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetReportParameter(prepObj, pParameterName, pParameterValue) Export
	pRepObj.ReportBuilder.Parameters.Insert(pParameterName, pParameterValue);
EndProcedure // cmSetReportParameter

// -----------------------------------------------------------------------------
// Description: Returns report appearance template based on it's type
// Parameters: Report appearance template type
// Return value: Report appearance template
// -----------------------------------------------------------------------------
Function cmGetAppearanceTemplate(pReportAppearanceTemplateType) Export
	vTemplate = Undefined;
	Try
		vTemplate = GetCommonTemplate("ReportAppearanceTemplate" + pReportAppearanceTemplateType.Metadata().EnumValues[Enums.ReportAppearanceTemplateTypes.IndexOf(pReportAppearanceTemplateType)].Name);
	Except
	EndTry;
	Return vTemplate;
EndFunction // cmGetAppearanceTemplate

// -----------------------------------------------------------------------------
//  Fills report page header text with hotel name and program name
//
// Parameters:
//  pSpreadsheet - Spreadsheet	 - Report spreadshee
//
Procedure cmApplyReportHeader(pSpreadsheet) Export    
	vHotelPrintName = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(SessionParameters.CurrentHotel, SessionParameters.CurrentLanguage) + " - ";
	EndIf;
	// Add hotel name to the left report header
	pSpreadsheet.Header.LeftText = vHotelPrintName + TrimAll(SessionParameters.ConfigurationPresentation);
	// Set header text alignement
	pSpreadsheet.Header.VerticalAlign = VerticalAlign.Bottom;
	pSpreadsheet.Header.Enabled = True;   
EndProcedure // cmApplyReportHeader 

// -----------------------------------------------------------------------------
// Description: Fills report page footer text with report page number
// Parameters: Report spreadsheet
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmApplyReportFooter(pSpreadsheet) Export
	// Add number of pages to the report footer
	pSpreadsheet.Footer.CenterText = NStr("en='Page ';ru='Страница ';de='Seite '") + "[&PageNumber]" + NStr("ru = ' из '; en = ' of '; de = ' von '") + "[&PagesTotal]";
	pSpreadsheet.Footer.VerticalAlign = VerticalAlign.Top;
	pSpreadsheet.Footer.Enabled = True;
EndProcedure // cmApplyReportFooter

// -----------------------------------------------------------------------------
// Description: Hides report row groups for levels defined in report settings
// Parameters: Report object, Report spreadsheet control
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmShowRowGroupsLevel(pRepObj, pSpreadsheet) Export
	Try 
		If pRepObj.ReportColumnOverrides.Count() > 0 And pRepObj.ReportColumnOverrides.Columns.Count() > 0 Then
			c = pSpreadsheet.RowGroupLevelCount();
			i = pRepObj.ReportBuilder.RowDimensions.Count();
			While i > 0 Do
				i = i - 1;
				vAttr = pRepObj.ReportBuilder.RowDimensions.Get(i);
				vShowGroupClosed = False;
				vOverrideRow = Undefined;
				If pRepObj.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
					vOverrideRow = pRepObj.ReportColumnOverrides.Find(vAttr.DataPath, "ColumnDataPath");
				EndIf;
				If vOverrideRow = Undefined Then
					If pRepObj.ReportColumnOverrides.Columns.Find("ColumnName") <> Undefined Then
						vOverrideRow = pRepObj.ReportColumnOverrides.Find(vAttr.Name, "ColumnName");
					EndIf;
				EndIf;
				If vOverrideRow <> Undefined Then
					If pRepObj.ReportColumnOverrides.Columns.Find("ShowGroupClosed") <> Undefined Then
						vShowGroupClosed = vOverrideRow.ShowGroupClosed;
					EndIf;
				EndIf;
				If vShowGroupClosed Then
					r = 0;
					For Each vGrpAttr In pRepObj.ReportBuilder.RowDimensions Do
						r = r + 1;
						If vGrpAttr.Name = vAttr.Name Then
							Break;
						EndIf;
						If vGrpAttr.DimensionType = ReportBuilderDimensionType.Hierarchy Then
							r = r + 1;
						EndIf;
					EndDo;
					If r <= c Then
						pSpreadsheet.ShowRowGroupLevel(r - 1);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	Except
	EndTry;
EndProcedure // cmShowRowGroupsLevel

// -----------------------------------------------------------------------------
// Description: Hides report column groups for levels defined in report settings
// Parameters: Report object, Report spreadsheet control
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmShowColumnGroupsLevel(pRepObj, pSpreadsheet) Export
	Try 
		If pRepObj.ReportColumnOverrides.Count() > 0 And pRepObj.ReportColumnOverrides.Columns.Count() > 0 Then
			c = pSpreadsheet.ColumnGroupLevelCount();
			i = pRepObj.ReportBuilder.ColumnDimensions.Count();
			While i > 0 Do
				i = i - 1;
				vAttr = pRepObj.ReportBuilder.ColumnDimensions.Get(i);
				vShowGroupClosed = False;
				vOverrideRow = Undefined;
				If pRepObj.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
					vOverrideRow = pRepObj.ReportColumnOverrides.Find(vAttr.DataPath, "ColumnDataPath");
				EndIf;
				If vOverrideRow = Undefined Then
					If pRepObj.ReportColumnOverrides.Columns.Find("ColumnName") <> Undefined Then
						vOverrideRow = pRepObj.ReportColumnOverrides.Find(vAttr.Name, "ColumnName");
					EndIf;
				EndIf;
				If vOverrideRow <> Undefined Then
					If pRepObj.ReportColumnOverrides.Columns.Find("ShowColumnGroupClosed") <> Undefined Then
						vShowGroupClosed = vOverrideRow.ShowColumnGroupClosed;
					EndIf;
				EndIf;
				If vShowGroupClosed Then
					r = 0;
					For Each vGrpAttr In pRepObj.ReportBuilder.ColumnDimensions Do
						r = r + 1;
						If vGrpAttr.Name = vAttr.Name Then
							Break;
						EndIf;
						If vGrpAttr.DimensionType = ReportBuilderDimensionType.Hierarchy Then
							r = r + 1;
						EndIf;
					EndDo;
					If r <= c Then
						pSpreadsheet.ShowColumnGroupLevel(r - 1);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	Except
	EndTry;
EndProcedure // cmShowColumnGroupsLevel

// -----------------------------------------------------------------------------
// Description: Fills report header and footer, fixes report header
// Parameters: Report object, Report spreadsheet, Report template attributes structure
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmApplyReportAppearance(pRepObj, pSpreadsheet, pTemplateAttributes) Export
	// Reset report appearance template
	pRepObj.ReportBuilder.AppearanceTemplate = Undefined;
	// Fix report header horizontally
	If pTemplateAttributes <> Undefined Then
		If Not pRepObj.ReportDoNotPutReportHeader And Not pRepObj.ReportDoNotPutTableHeader Then
			pSpreadsheet.FixedTop = pTemplateAttributes.TableHeaderBottom;
		EndIf;
	EndIf;
	// Report header
	If Not pRepObj.ReportDoNotPutReportHeader Then
		cmApplyReportHeader(pSpreadsheet);
	EndIf;
	// Report footer
	If Not pRepObj.ReportDoNotPutReportFooter Then
		cmApplyReportFooter(pSpreadsheet);
	EndIf;
	// Report groups
	cmShowRowGroupsLevel(pRepObj, pSpreadsheet);
	cmShowColumnGroupsLevel(pRepObj, pSpreadsheet);
EndProcedure // cmApplyReportAppearance

// -----------------------------------------------------------------------------
// Description: Reformats report spreadsheet to the multicolumn view
// Parameters: Report object, Report spreadsheet
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmApplyReportMultiplePages(pRepObj, pSpreadsheet) Export
	// Apply number of pages to be printed on the one paper sheet
	If pRepObj.PerPage > 1 Then
		vTableWidth = pSpreadsheet.TableWidth;
		vTableHeight = pSpreadsheet.TableHeight;
		vReportArea = pSpreadsheet.Area(1, , vTableHeight);
		vReportArea.Ungroup();
		pSpreadsheet.ShowGroups = False;
		vPages = New ValueList();
		vProbeSpreadsheet = New SpreadsheetDocument();
		vProbeSpreadsheet.PrinterName = pSpreadsheet.PrinterName;
		vPageStart = 0;
		vTempSpreadsheet = Undefined;
		i = 0;
		While i < pSpreadsheet.TableHeight Do
			Try
				vPageHeight = i - vPageStart + 1;
				vTempSpreadsheet = New SpreadsheetDocument();
				vReportArea = vTempSpreadsheet.Put(pSpreadsheet);
				If (i + 2) < vTableHeight Then
					vTempSpreadsheet.DeleteArea(vTempSpreadsheet.Area(i + 2, , vTableHeight), SpreadsheetDocumentShiftType.Vertical);
				EndIf;
				If vPageStart > 0 Then
					vTempSpreadsheet.DeleteArea(vTempSpreadsheet.Area(1, , vPageStart), SpreadsheetDocumentShiftType.Vertical);
				Else
					vTempSpreadsheet.DeleteArea(vTempSpreadsheet.Area(1, , 5), SpreadsheetDocumentShiftType.Vertical);
				EndIf;
				If Not vProbeSpreadsheet.CheckPut(vTempSpreadsheet) Then
					vTempSpreadsheet.DeleteArea(vTempSpreadsheet.Area(vTempSpreadsheet.TableHeight, , vTempSpreadsheet.TableHeight), SpreadsheetDocumentShiftType.Vertical);
					vPages.Add(vTempSpreadsheet);
					vPageStart = i + 1;
				EndIf;
			Except
				Return;
			EndTry;
			i = i + 1;
		EndDo;
		If vTempSpreadsheet <> Undefined Then
			If vPages.Count() > 0 Then
				vPages.Add(vTempSpreadsheet);
			EndIf;
		EndIf;
		If vPages.Count() > 1 Then
			vTargetSpreadsheet = New SpreadsheetDocument();
			pSpreadsheet.DeleteArea(pSpreadsheet.Area(6, , pSpreadsheet.TableHeight), SpreadsheetDocumentShiftType.Vertical);
			vTargetSpreadsheet.Put(pSpreadsheet);
			For Each vPagesItem In vPages Do
				vPageSheet = vPagesItem.Value;
				vPageNumber = vPages.IndexOf(vPagesItem) + 1;
				If vPageNumber = 1 Then
					vTargetSpreadsheet.Join(vPageSheet);
				ElsIf vPageNumber > 1 And (vPageNumber - 1)/pRepObj.PerPage = Int((vPageNumber - 1)/pRepObj.PerPage) Then
					vTargetSpreadsheet.Put(vPageSheet);
				Else
					vTargetSpreadsheet.Join(vPageSheet);
					// Set column width
					For i = 1 To vPageSheet.TableWidth Do
						vSrcCol = vTargetSpreadsheet.Area(5, i, 5, i);
						vTgtCol = vTargetSpreadsheet.Area(5, vTargetSpreadsheet.TableWidth - vPageSheet.TableWidth + i, 5, vTargetSpreadsheet.TableWidth - vPageSheet.TableWidth + i);
						vTgtCol.ColumnWidth = vSrcCol.ColumnWidth;
					EndDo;
				EndIf;
			EndDo;
			pSpreadsheet.Clear();
			pSpreadsheet.Put(vTargetSpreadsheet);
		EndIf;
	EndIf;
EndProcedure // cmApplyReportMultiplePages

// -----------------------------------------------------------------------------
// Description: Apply report print settings and do output other then on screen
// Parameters: Report object, Report spreadsheet, Default page orientation, 
//             Fit to page or not, Show report on screen or not, Default report name
// Return value: True if report has to be shown on screen, False if not
// -----------------------------------------------------------------------------
Function cmApplyReportPrintSettingsAndDoOutput(pRepObj, pSpreadsheet, pDefaultPageOrientation, pDefaultFitToPage = True, pOnScreen = False, pDefaultReportName, rDoPrint = Undefined) Export
	vOutputOnScreen = True;
	// Setup default attributes
	cmSetDefaultPrintFormSettings(pSpreadsheet, pDefaultPageOrientation, pDefaultFitToPage);
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current report
			vFilter = New Structure("Report, IsActive", pRepObj.Report, True);
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(pSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen And Not pOnScreen Then
						vName = cmGetPrintFormFileName(vPrintSettings, pDefaultReportName);
						cmDoSpreadsheetOutput(pSpreadsheet, vPrintSettings, vName, , rDoPrint);
						vOutputOnScreen = False;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	Return vOutputOnScreen;
EndFunction // cmApplyReportPrintSettingsAndDoOutput

// -----------------------------------------------------------------------------
// Description: Fills report filters presentation. It builds text list of filters 
//              applied to the report main query
// Parameters: Report object
// Return value: Text, description of filters applied to the report query
// -----------------------------------------------------------------------------
Function cmGetReportFilterPresentation(pRepObj) Export
	vFilterPresentation = "";
	vParametersPresentation = pRepObj.pmGetReportParametersPresentation();
	vFilterPresentation = vParametersPresentation;
	For Each vFilter In pRepObj.ReportBuilder.Filter Do
		If vFilter.Use Then
			vFilterPresentation = vFilterPresentation + String(vFilter) + ";" + Chars.LF;
		EndIf;
	EndDo;
	Return vFilterPresentation;
EndFunction // cmGetReportFilterPresentation 

// -----------------------------------------------------------------------------
// Description: Returns phones catalog item reference by text phone number
// Parameters: Text phone number, Hotel
// Return value: Phones catalog item reference or Undefined if nothing was found
// -----------------------------------------------------------------------------
Function cmGetPhoneNumber(pPhoneNumber, pHotel) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PhoneNumbers.Ref
	|FROM
	|	Catalog.PhoneNumbers AS PhoneNumbers
	|WHERE
	|	PhoneNumbers.IsFolder = FALSE
	|	AND PhoneNumbers.DeletionMark = FALSE
	|	AND PhoneNumbers.Owner = &qHotel
	|	AND PhoneNumbers.PhoneNumber = &qPhoneNumber";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPhoneNumber", pPhoneNumber);
	vList = vQry.Execute().Unload();
	
	vPhoneNumberRef = Undefined;
	If vList.Count() > 0 Then
		vRow = vList.Get(0);
		vPhoneNumberRef = vRow.Ref;
	EndIf;
	
	Return vPhoneNumberRef;
EndFunction // cmGetPhoneNumber

// -----------------------------------------------------------------------------
// Description: Returns door lock system driver data processor object for the 
//              door lock system switched to the current workstation
// Parameters: None
// Return value: Door lock system driver data processor object
// -----------------------------------------------------------------------------
Function cmGetDoorLockSystemDataProcessor() Export
	// Check parameters
	vWstn = SessionParameters.CurrentWorkstation;
	If Not ValueIsFilled(vWstn) Then
		Return Undefined;
	EndIf;
	If Not vWstn.HasConnectionToDoorLockSystem Then
		Return Undefined;
	EndIf;
	If Not ValueIsFilled(vWstn.DoorLockSystemParameters) Then
		Return Undefined;
	EndIf;
	vDLST = vWstn.DoorLockSystemParameters.DoorLockSystemType;
	If Not ValueIsFilled(vDLST) Then
		Return Undefined;
	EndIf;
	// Create data processor object for the given door lock system name
	Try
		If vDLST = Enums.DoorLockSystems.VingCardVision Then
			vSystemName = "VingCardVisionDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.VingCard2100 Then
			vSystemName = "VingCard21002800DoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.VingCardDavinci Then
			vSystemName = "VingCardVisionDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.VingCard2800 Then
			vSystemName = "VingCard21002800DoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.OnityHT22 Then
			vSystemName = "OnityDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.OnityHT24 Then
			vSystemName = "OnityDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.OnityHT28 Then
			vSystemName = "OnityDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.SaltoHotel Then
			vSystemName = "OnityDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Amadeus Then
			vSystemName = "AmadeusDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.KabaIlco Then
			vSystemName = "KabaIlcoDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.KabaSaflok Then
			vSystemName = "KabaSaflokDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.InhovaMagnetic Then
			vSystemName = "InhovaDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.InhovaProximity Then
			vSystemName = "InhovaDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Cisa Then
			vSystemName = "CisaDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.TimeLox2300 Then
			vSystemName = "TimeLoxDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Adel Then
			vSystemName = "AdelDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Orbita Then
			vSystemName = "OrbitaDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Orbita4X Then
			vSystemName = "Orbita4XDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Orbita5X Then
			vSystemName = "Orbita5XDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Motolong Then
			vSystemName = "MotolongDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Xeeder Then
			vSystemName = "XeederDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.OmniTec Then
			vSystemName = "OmniTecDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.iLocks Then
			vSystemName = "ILocksDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.IronLogic Then
			vSystemName = "IronLogicDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Bonwin Then
			vSystemName = "BonwinDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.BonwinAutonomous Then
			vSystemName = "BonwinAutonomousDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.AssaAbloyHospitality Then
			vSystemName = "AssaAbloyDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Hoist Then
			vSystemName = "HoistDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.OZLocks Then
			vSystemName = "OZLocksDoorLockSystemDriver";
		ElsIf vDLST = Enums.DoorLockSystems.Novilock Then
			vSystemName = "NovilockDoorLockSystemDriver";	
		EndIf;
		vDataProcessorObj = DataProcessors[vSystemName].Create();
		vDataProcessorObj.DoorLockSystemParameters = vWstn.DoorLockSystemParameters;
		Return vDataProcessorObj;
	Except
		Return Undefined;
	EndTry;
EndFunction // cmGetDoorLockSystemDataProcessor

// -----------------------------------------------------------------------------
// Description: Returns identity cards system driver data processor object for the 
//              identity cards system switched to the current workstation
// Parameters: None
// Return value: Client identity cards system driver data processor object
// -----------------------------------------------------------------------------
Function cmGetClientIdentityCardsSystemDataProcessor() Export
	// Check parameters
	vWstn = SessionParameters.CurrentWorkstation;
	If Not ValueIsFilled(vWstn) Then
		Return Undefined;
	EndIf;
	If Not vWstn.HasConnectionToIdentityCardsProcessingSystem Then
		Return Undefined;
	EndIf;
	If Not ValueIsFilled(vWstn.IdentityCardsProcessingSystemParameters) Then
		Return Undefined;
	EndIf;
	// Create data processor object
	Try
		vDataProcessorObj = DataProcessors.IdentityCardsProcessingDriver.Create();
		vDataProcessorObj.IdentityCardSystemParameters = vWstn.IdentityCardsProcessingSystemParameters;
		Return vDataProcessorObj;
	Except
		Return Undefined;
	EndTry;
EndFunction // cmGetClientIdentityCardsSystemDataProcessor

// -----------------------------------------------------------------------------
// Description: Returns barcodes scanner driver data processor object for the 
//              barcodes scanner switched to the current workstation
// Parameters: None
// Return value: Barcodes scanner driver data processor object
// -----------------------------------------------------------------------------
Function cmGetBarcodesScannerDriverDataProcessor() Export
	// Check parameters
	vWstn = SessionParameters.CurrentWorkstation;
	If Not ValueIsFilled(vWstn) Then
		Return Undefined;
	EndIf;
	If Not vWstn.HasConnectionToBarcodesScanner Then
		Return Undefined;
	EndIf;
	If Not ValueIsFilled(vWstn.BarcodesScannerConnectionParameters) Then
		Return Undefined;
	EndIf;
	// Create data processor object
	Try
		vDataProcessorObj = DataProcessors.BarcodesScannerProcessingDriver.Create();
		vDataProcessorObj.BarcodesScannerConnectionParameters = vWstn.BarcodesScannerConnectionParameters;
		Return vDataProcessorObj;
	Except
		Return Undefined;
	EndTry;
EndFunction // cmGetBarcodesScannerDriverDataProcessor
 
// -----------------------------------------------------------------------------
// Description: Returns images scanner driver data processor object for the 
//              images scanner switched to the current workstation
// Parameters: None
// Return value: Images scanner driver data processor object
// -----------------------------------------------------------------------------
Function cmGetImagesScannerDriverDataProcessor() Export
	// Check parameters
	vWstn = SessionParameters.CurrentWorkstation;
	If Not ValueIsFilled(vWstn) Then
		Return Undefined;
	EndIf;
	If Not vWstn.HasConnectionToImagesScanner Then
		Return Undefined;
	EndIf;
	If Not ValueIsFilled(vWstn.ImagesScannerConnectionParameters) Then
		Return Undefined;
	EndIf;
	// Create data processor object
	Try
		If vWstn.ImagesScannerConnectionParameters.ImageScannerDriver = Enums.ImageScannerDrivers.CognitiveScanifyAPI Then
			vDataProcessorObj = DataProcessors.CognitiveImageScannerDriver.Create();
			vDataProcessorObj.ImageScannerConnectionParameters = vWstn.ImagesScannerConnectionParameters;
			Return vDataProcessorObj;
		ElsIf vWstn.ImagesScannerConnectionParameters.ImageScannerDriver = Enums.ImageScannerDrivers.AbbyyPassportReaderSDKEngine Or 
		      vWstn.ImagesScannerConnectionParameters.ImageScannerDriver = Enums.ImageScannerDrivers.ContentAIPassportReaderSDKEngine Then
			vDataProcessorObj = DataProcessors.AbbyyImageScannerDriver.Create();
			vDataProcessorObj.ImageScannerConnectionParameters = vWstn.ImagesScannerConnectionParameters;
			Return vDataProcessorObj;
		ElsIf vWstn.ImagesScannerConnectionParameters.ImageScannerDriver = Enums.ImageScannerDrivers.SmartPassportBoxEngine Then
			vDataProcessorObj = DataProcessors.SmartPassportBoxDriver.Create();
			vDataProcessorObj.ImageScannerConnectionParameters = vWstn.ImagesScannerConnectionParameters;
			Return vDataProcessorObj;
		ElsIf vWstn.ImagesScannerConnectionParameters.ImageScannerDriver = Enums.ImageScannerDrivers.Scan1C Then
			vDataProcessorObj = DataProcessors.Scan1CImageScannerDriver.Create();
			vDataProcessorObj.ImageScannerConnectionParameters = vWstn.ImagesScannerConnectionParameters;
			Return vDataProcessorObj;
		Else
			Return Undefined;
		EndIf;
	Except
		Return Undefined;
	EndTry;
EndFunction // cmGetImagesScannerDriverDataProcessor
 
// -----------------------------------------------------------------------------
// Description: Returns WEB camera images driver data processor object for the 
//              WEB camera switched to the current workstation
// Parameters: None
// Return value: WEB camera driver data processor object
// -----------------------------------------------------------------------------
Function cmGetWEBCamDriverDataProcessor() Export
	// Check parameters
	vWstn = SessionParameters.CurrentWorkstation;
	If Not ValueIsFilled(vWstn) Then
		Return Undefined;
	EndIf;
	If Not vWstn.HasConnectionToWEBCamera Then
		Return Undefined;
	EndIf;
	If Not ValueIsFilled(vWstn.WEBCamConnectionParameters) Then
		Return Undefined;
	EndIf;
	// Create data processor object
	Try
		vDataProcessorObj = DataProcessors.Scan1CWebCamDriver.Create();
		vDataProcessorObj.WEBCamConnectionParameters = vWstn.WEBCamConnectionParameters;
		Return vDataProcessorObj;
	Except
		Return Undefined;
	EndTry;
EndFunction // cmGetWEBCamDriverDataProcessor

// -----------------------------------------------------------------------------
// Description: Returns array of text lines built from the multi line text
// Parameters: Multi line text
// Return value: Array of text lines
// -----------------------------------------------------------------------------
Function cmGetTextLinesArray(pTextStr) Export
	vTxtArr = New Array;
	If Not IsBlankString(pTextStr) Then
		vTxt = New TextDocument();
		vTxt.SetText(pTextStr);
		For i = 1 To vTxt.LineCount() Do
			vStr = vTxt.GetLine(i);
			If TrimAll(vStr) = "[cut]" Then
				Break;
			EndIf;
			vTxtArr.Add(vStr);
		EndDo;
	EndIf;
	Return vTxtArr;
EndFunction // cmGetTextLinesArray

// -----------------------------------------------------------------------------
// Description: Tries to cast given text value to the number
// Parameters: Text number representation
// Return value: Number
// -----------------------------------------------------------------------------
Function cmCastToNumber(pVal) Export
	Try
		If pVal = Undefined Then
			Return 0;
		ElsIf TypeOf(pVal) = Type("Number") Then
			Return pVal;
		Else
			Return Number(pVal);
		EndIf;
	Except
		Try
			Return Number(cmGetDocumentNumberPresentation(pVal));
		Except
			Return 0;
		EndTry;
	EndTry;
EndFunction // cmCastToNumber

// -----------------------------------------------------------------------------
// Description: Checks whether given two documents are bound by parent/child reference
// Parameters: Main document, document to check
// Return value: True if documents are bound to each other, false if not
// -----------------------------------------------------------------------------
Function cmIsInDocumentChain(pDoc, pCheckDoc) Export
	vIsInChain = False;
	If ValueIsFilled(pDoc) And ValueIsFilled(pCheckDoc) Then
		If pDoc <> pCheckDoc Then
			vParentDoc = pDoc.ParentDoc;
			While ValueIsFilled(vParentDoc) Do
				If vParentDoc = pCheckDoc Then
					vIsInChain = True;
					Break;
				EndIf;
				vParentDoc = vParentDoc.ParentDoc;
			EndDo;
		Else
			vIsInChain = True;
		EndIf;
	EndIf;
	Return vIsInChain;
EndFunction // cmIsInDocumentChain

// -----------------------------------------------------------------------------
// Description: Returns value list of reports catalog items allowed to the given 
//              permission group
// Parameters: Permission groups catalog item
// Return value: Value list of reports 
// -----------------------------------------------------------------------------
Function cmGetListOfAllowedReports(pPermissionGroup) Export
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	Reports.Ref
	|FROM
	|	Catalog.Reports AS Reports
	|WHERE
	|	(NOT Reports.DeletionMark)
	|	AND (NOT Reports.IsFolder)
	|	AND (Reports.PermissionGroup = &qPermissionGroup
	|			OR &qPermissionGroup IN
	|				(SELECT
	|					PermissionGroups.PermissionGroup
	|				FROM
	|					Catalog.Reports.PermissionGroups AS PermissionGroups
	|				WHERE
	|					PermissionGroups.Ref = Reports.Ref))
	|ORDER BY
	|	Reports.Code";
	vQry.SetParameter("qPermissionGroup", pPermissionGroup);
	vReports = vQry.Execute().Unload();
	vReportsList = New ValueList();
	If vReports.Count() > 0 Then
		vReportsList.LoadValues(vReports.UnloadColumn("Ref"));
	EndIf;
	Return vReportsList;
EndFunction // cmGetListOfAllowedReports

// -----------------------------------------------------------------------------
// Description: Returns value list of data processors catalog items allowed to 
//              the given permission group
// Parameters: Permission groups catalog item
// Return value: Value list of data processors
// -----------------------------------------------------------------------------
Function cmGetListOfAllowedDataProcessors(pPermissionGroup) Export
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	DataProcessors.Ref
	|FROM
	|	Catalog.DataProcessors AS DataProcessors
	|WHERE
	|	(NOT DataProcessors.DeletionMark)
	|	AND (NOT DataProcessors.IsFolder)
	|	AND (DataProcessors.PermissionGroup = &qPermissionGroup
	|			OR &qPermissionGroup IN
	|				(SELECT
	|					PermissionGroups.PermissionGroup
	|				FROM
	|					Catalog.DataProcessors.PermissionGroups AS PermissionGroups
	|				WHERE
	|					PermissionGroups.Ref = DataProcessors.Ref))
	|ORDER BY
	|	DataProcessors.Code";
	vQry.SetParameter("qPermissionGroup", pPermissionGroup);
	vDPs = vQry.Execute().Unload();
	vDPsList = New ValueList();
	If vDPs.Count() > 0 Then
		vDPsList.LoadValues(vDPs.UnloadColumn("Ref"));
	EndIf;
	Return vDPsList;
EndFunction // cmGetListOfAllowedDataProcessors

// -----------------------------------------------------------------------------
// Description: Returns binary string representing positive decimal number
// Parameters: Decimal number
// Return value: Binary number presentation as string
// -----------------------------------------------------------------------------
Function cmDec2Bin(pDec) Export
	vBin = "";
	vDiv = pDec;
	While vDiv > 0 Do
		vIntDiv = Int(vDiv/2);
		vBinChar = "0";
		If vDiv <> vIntDiv*2 Then
			vBinChar = "1";
		EndIf;
		vBin = vBinChar + vBin;
		vDiv = vIntDiv;
	EndDo;
	Return vBin;
EndFunction // cmDec2Bin

// -----------------------------------------------------------------------------
// Description: Returns positive decimal number representing binary string
// Parameters: Binary number presentation as string
// Return value: Decimal number
// -----------------------------------------------------------------------------
Function cmBin2Dec(pBin) Export
	vDec = 0;
	vLen = StrLen(pBin);
	For i = 1 To vLen Do
		vDec = vDec + Number(Mid(pBin, i, 1)) * Pow(2, (vLen - i));
	EndDo;
	Return vDec;
EndFunction // cmBin2Dec

// -----------------------------------------------------------------------------
// Description: Returns hex string representing binary string
// Parameters: Binary number presentation as string
// Return value: Hex number presentation as string
// -----------------------------------------------------------------------------
Function cmBin2Hex(Val pBin) Export
	vHex = "";
	// Build conversion map
	vHexStruct = New Map();
	vHexStruct.Insert("0000", "0");
	vHexStruct.Insert("0001", "1");
	vHexStruct.Insert("0010", "2");
	vHexStruct.Insert("0011", "3");
	vHexStruct.Insert("0100", "4");
	vHexStruct.Insert("0101", "5");
	vHexStruct.Insert("0110", "6");
	vHexStruct.Insert("0111", "7");
	vHexStruct.Insert("1000", "8");
	vHexStruct.Insert("1001", "9");
	vHexStruct.Insert("1010", "A");
	vHexStruct.Insert("1011", "B");
	vHexStruct.Insert("1100", "C");
	vHexStruct.Insert("1101", "D");
	vHexStruct.Insert("1110", "E");
	vHexStruct.Insert("1111", "F");
	// Convert binary string to the length divided by 4
	vLen = StrLen(pBin);
	vNewLen = Int(vLen/4);
	If vNewLen <> vLen/4 Then
		vNewLen = vNewLen + 1;
	EndIf;
	vNewLen = vNewLen*4;
	pBin = Format(Number(pBin), "ND=" + vNewLen + "; NFD=0; NZ=; NLZ=; NG=");
	For i = 1 To vNewLen/4 Do
		vHex = vHex + vHexStruct.Get(Mid(pBin, 1+4*(i-1), 4));
	EndDo;
	Return vHex;
EndFunction // cmBin2Hex

// -----------------------------------------------------------------------------
// Description: Returns decimal number of the hex char
// Parameters: Hex char as string
// Return value: Decimal number presentation as number
// -----------------------------------------------------------------------------
Function cmHex2Dec(pHexChar) Export
	If pHexChar = "0" Then
		Return 0;
	ElsIf pHexChar = "1" Then
		Return 1;
	ElsIf pHexChar = "2" Then
		Return 2;
	ElsIf pHexChar = "3" Then
		Return 3;
	ElsIf pHexChar = "4" Then
		Return 4;
	ElsIf pHexChar = "5" Then
		Return 5;
	ElsIf pHexChar = "6" Then
		Return 6;
	ElsIf pHexChar = "7" Then
		Return 7;
	ElsIf pHexChar = "8" Then
		Return 8;
	ElsIf pHexChar = "9" Then
		Return 9;
	ElsIf Upper(pHexChar) = "A" Then
		Return 10;
	ElsIf Upper(pHexChar) = "B" Then
		Return 11;
	ElsIf Upper(pHexChar) = "C" Then
		Return 12;
	ElsIf Upper(pHexChar) = "D" Then
		Return 13;
	ElsIf Upper(pHexChar) = "E" Then
		Return 14;
	ElsIf Upper(pHexChar) = "F" Then
		Return 15;
	EndIf;
EndFunction // cmHex2Dec

// -----------------------------------------------------------------------------
// Description: Returns null terminating string of given length
// Parameters: String to be encoded, Target string length
// Return value: Right padded with blanks to the specified length null terminating string
// -----------------------------------------------------------------------------
Function cmGetNullTerminatingString(pStr, pLen) Export
	vStr = "";
	vStrLen = StrLen(pStr);
	If vStrLen >= (pLen - 1) Then
		vStr = Left(pStr, (pLen - 1)) + Char(0);
	Else
		vStr = pStr;
		For i = 1 To (pLen - vStrLen - 1) Do
			vStr = vStr + Char(0);
		EndDo;
		vStr = vStr + Char(0);
	EndIf;		
	Return vStr;
EndFunction // cmGetNullTerminatingString

// -----------------------------------------------------------------------------
// Description: Returns map to get char index value for the appropriate hex byte
// Parameters: None
// Return value: Char/Index Map
// -----------------------------------------------------------------------------
Function cmGetByte2CharIndexMap() Export
	vMap = New Map();
	
	vMap.Insert("00", 0);
	vMap.Insert("01", 1);
	vMap.Insert("02", 2);
	vMap.Insert("03", 3);
	vMap.Insert("04", 4);
	vMap.Insert("05", 5);
	vMap.Insert("06", 6);
	vMap.Insert("07", 7);
	vMap.Insert("08", 8);
	vMap.Insert("09", 9);
	vMap.Insert("0A", 10);
	vMap.Insert("0B", 11);
	vMap.Insert("0C", 12);
	vMap.Insert("0D", 13);
	vMap.Insert("0E", 14);
	vMap.Insert("0F", 15);
	
	vMap.Insert("10", 16);
	vMap.Insert("11", 17);
	vMap.Insert("12", 18);
	vMap.Insert("13", 19);
	vMap.Insert("14", 20);
	vMap.Insert("15", 21);
	vMap.Insert("16", 22);
	vMap.Insert("17", 23);
	vMap.Insert("18", 24);
	vMap.Insert("19", 25);
	vMap.Insert("1A", 26);
	vMap.Insert("1B", 27);
	vMap.Insert("1C", 28);
	vMap.Insert("1D", 29);
	vMap.Insert("1E", 30);
	vMap.Insert("1F", 31);
	
	vMap.Insert("20", 32);
	vMap.Insert("21", 33);
	vMap.Insert("22", 34);
	vMap.Insert("23", 35);
	vMap.Insert("24", 36);
	vMap.Insert("25", 37);
	vMap.Insert("26", 38);
	vMap.Insert("27", 39);
	vMap.Insert("28", 40);
	vMap.Insert("29", 41);
	vMap.Insert("2A", 42);
	vMap.Insert("2B", 43);
	vMap.Insert("2C", 44);
	vMap.Insert("2D", 45);
	vMap.Insert("2E", 46);
	vMap.Insert("2F", 47);
	
	vMap.Insert("30", 48);
	vMap.Insert("31", 49);
	vMap.Insert("32", 50);
	vMap.Insert("33", 51);
	vMap.Insert("34", 52);
	vMap.Insert("35", 53);
	vMap.Insert("36", 54);
	vMap.Insert("37", 55);
	vMap.Insert("38", 56);
	vMap.Insert("39", 57);
	vMap.Insert("3A", 58);
	vMap.Insert("3B", 59);
	vMap.Insert("3C", 60);
	vMap.Insert("3D", 61);
	vMap.Insert("3E", 62);
	vMap.Insert("3F", 63);
	
	vMap.Insert("40", 64);
	vMap.Insert("41", 65);
	vMap.Insert("42", 66);
	vMap.Insert("43", 67);
	vMap.Insert("44", 68);
	vMap.Insert("45", 69);
	vMap.Insert("46", 70);
	vMap.Insert("47", 71);
	vMap.Insert("48", 72);
	vMap.Insert("49", 73);
	vMap.Insert("4A", 74);
	vMap.Insert("4B", 75);
	vMap.Insert("4C", 76);
	vMap.Insert("4D", 77);
	vMap.Insert("4E", 78);
	vMap.Insert("4F", 79);
	
	vMap.Insert("50", 80);
	vMap.Insert("51", 81);
	vMap.Insert("52", 82);
	vMap.Insert("53", 83);
	vMap.Insert("54", 84);
	vMap.Insert("55", 85);
	vMap.Insert("56", 86);
	vMap.Insert("57", 87);
	vMap.Insert("58", 88);
	vMap.Insert("59", 89);
	vMap.Insert("5A", 90);
	vMap.Insert("5B", 91);
	vMap.Insert("5C", 92);
	vMap.Insert("5D", 93);
	vMap.Insert("5E", 94);
	vMap.Insert("5F", 95);
	
	vMap.Insert("60", 96);
	vMap.Insert("61", 97);
	vMap.Insert("62", 98);
	vMap.Insert("63", 99);
	vMap.Insert("64", 100);
	vMap.Insert("65", 101);
	vMap.Insert("66", 102);
	vMap.Insert("67", 103);
	vMap.Insert("68", 104);
	vMap.Insert("69", 105);
	vMap.Insert("6A", 106);
	vMap.Insert("6B", 107);
	vMap.Insert("6C", 108);
	vMap.Insert("6D", 109);
	vMap.Insert("6E", 110);
	vMap.Insert("6F", 111);
	
	vMap.Insert("70", 112);
	vMap.Insert("71", 113);
	vMap.Insert("72", 114);
	vMap.Insert("73", 115);
	vMap.Insert("74", 116);
	vMap.Insert("75", 117);
	vMap.Insert("76", 118);
	vMap.Insert("77", 119);
	vMap.Insert("78", 120);
	vMap.Insert("79", 121);
	vMap.Insert("7A", 122);
	vMap.Insert("7B", 123);
	vMap.Insert("7C", 124);
	vMap.Insert("7D", 125);
	vMap.Insert("7E", 126);
	vMap.Insert("7F", 127);
	
	vMap.Insert("80", 1026);
	vMap.Insert("81", 1027);
	vMap.Insert("82", 8218);
	vMap.Insert("83", 1107);
	vMap.Insert("84", 8222);
	vMap.Insert("85", 8230);
	vMap.Insert("86", 8224);
	vMap.Insert("87", 8225);
	vMap.Insert("88", 8364);
	vMap.Insert("89", 8240);
	vMap.Insert("8A", 1033);
	vMap.Insert("8B", 8249);
	vMap.Insert("8C", 1034);
	vMap.Insert("8D", 1036);
	vMap.Insert("8E", 1035);
	vMap.Insert("8F", 1039);
	
	vMap.Insert("90", 1106);
	vMap.Insert("91", 8216);
	vMap.Insert("92", 8217);
	vMap.Insert("93", 8220);
	vMap.Insert("94", 8221);
	vMap.Insert("95", 8226);
	vMap.Insert("96", 8211);
	vMap.Insert("97", 8212);
	vMap.Insert("98", 152);
	vMap.Insert("99", 8482);
	vMap.Insert("9A", 1113);
	vMap.Insert("9B", 8250);
	vMap.Insert("9C", 1114);
	vMap.Insert("9D", 1116);
	vMap.Insert("9E", 1115);
	vMap.Insert("9F", 1119);
	
	vMap.Insert("A0", 160);
	vMap.Insert("A1", 1038);
	vMap.Insert("A2", 1118);
	vMap.Insert("A3", 1032);
	vMap.Insert("A4", 164);
	vMap.Insert("A5", 1168);
	vMap.Insert("A6", 166);
	vMap.Insert("A7", 167);
	vMap.Insert("A8", 1025);
	vMap.Insert("A9", 169);
	vMap.Insert("AA", 1028);
	vMap.Insert("AB", 171);
	vMap.Insert("AC", 172);
	vMap.Insert("AD", 173);
	vMap.Insert("AE", 174);
	vMap.Insert("AF", 1031);
	
	vMap.Insert("B0", 176);
	vMap.Insert("B1", 177);
	vMap.Insert("B2", 1030);
	vMap.Insert("B3", 1110);
	vMap.Insert("B4", 1169);
	vMap.Insert("B5", 181);
	vMap.Insert("B6", 182);
	vMap.Insert("B7", 183);
	vMap.Insert("B8", 1105);
	vMap.Insert("B9", 8470);
	vMap.Insert("BA", 1108);
	vMap.Insert("BB", 187);
	vMap.Insert("BC", 1112);
	vMap.Insert("BD", 1029);
	vMap.Insert("BE", 1109);
	vMap.Insert("BF", 1111);
	
	vMap.Insert("C0", 1040);
	vMap.Insert("C1", 1041);
	vMap.Insert("C2", 1042);
	vMap.Insert("C3", 1043);
	vMap.Insert("C4", 1044);
	vMap.Insert("C5", 1045);
	vMap.Insert("C6", 1046);
	vMap.Insert("C7", 1047);
	vMap.Insert("C8", 1048);
	vMap.Insert("C9", 1049);
	vMap.Insert("CA", 1050);
	vMap.Insert("CB", 1051);
	vMap.Insert("CC", 1052);
	vMap.Insert("CD", 1053);
	vMap.Insert("CE", 1054);
	vMap.Insert("CF", 1055);
	
	vMap.Insert("D0", 1056);
	vMap.Insert("D1", 1057);
	vMap.Insert("D2", 1058);
	vMap.Insert("D3", 1059);
	vMap.Insert("D4", 1060);
	vMap.Insert("D5", 1061);
	vMap.Insert("D6", 1062);
	vMap.Insert("D7", 1063);
	vMap.Insert("D8", 1064);
	vMap.Insert("D9", 1065);
	vMap.Insert("DA", 1066);
	vMap.Insert("DB", 1067);
	vMap.Insert("DC", 1068);
	vMap.Insert("DD", 1069);
	vMap.Insert("DE", 1070);
	vMap.Insert("DF", 1071);
	
	vMap.Insert("E0", 1072);
	vMap.Insert("E1", 1073);
	vMap.Insert("E2", 1074);
	vMap.Insert("E3", 1075);
	vMap.Insert("E4", 1076);
	vMap.Insert("E5", 1077);
	vMap.Insert("E6", 1078);
	vMap.Insert("E7", 1079);
	vMap.Insert("E8", 1080);
	vMap.Insert("E9", 1081);
	vMap.Insert("EA", 1082);
	vMap.Insert("EB", 1083);
	vMap.Insert("EC", 1084);
	vMap.Insert("ED", 1085);
	vMap.Insert("EE", 1086);
	vMap.Insert("EF", 1087);
	
	vMap.Insert("F0", 1088);
	vMap.Insert("F1", 1089);
	vMap.Insert("F2", 1090);
	vMap.Insert("F3", 1091);
	vMap.Insert("F4", 1092);
	vMap.Insert("F5", 1093);
	vMap.Insert("F6", 1094);
	vMap.Insert("F7", 1095);
	vMap.Insert("F8", 1096);
	vMap.Insert("F9", 1097);
	vMap.Insert("FA", 1098);
	vMap.Insert("FB", 1099);
	vMap.Insert("FC", 1100);
	vMap.Insert("FD", 1101);
	vMap.Insert("FE", 1102);
	vMap.Insert("FF", 1103);
	
	Return vMap;
EndFunction // cmGetByte2CharIndexMap

// -----------------------------------------------------------------------------
// Description: Returns binary string representing binary XOR with two binary numbers
// Parameters: First binary number presentation, Second binary number presentation
// Return value: XOR result binary presentation as string
// -----------------------------------------------------------------------------
Function cmXOR(Val pBin1, Val pBin2) Export
	vXOR = "";
	// Check that parameters length is the same
	vMaxLen = Max(StrLen(pBin1), StrLen(pBin2));
	pBin1 = Format(Number(pBin1), "ND=" + vMaxLen + "; NFD=0; NZ=; NLZ=; NG=");
	pBin2 = Format(Number(pBin2), "ND=" + vMaxLen + "; NFD=0; NZ=; NLZ=; NG=");
	// Do XOR
	For i = 1 To vMaxLen Do
		vChar1 = Mid(pBin1, i, 1);
		vChar2 = Mid(pBin2, i, 1);
		If vChar1 = vChar2 Then
			vXOR = vXOR + "0";
		Else
			vXOR = vXOR + "1";
		EndIf;			
	EndDo;
	Return vXOR;
EndFunction // cmXOR

// -----------------------------------------------------------------------------
// Description: Calculates hex number returned as string representing 
//              longitudinal redundancy check sum for the input character string
// Parameters: Character string to process
// Return value: 2 LRC chars
// -----------------------------------------------------------------------------
Function cmHexLRC(pStr) Export
	vBinaryDataBuffer = GetBinaryDataBufferFromHexString(pStr);
	vSeedBinaryDataBuffer = New BinaryDataBuffer(1);
	For i = 0 To vBinaryDataBuffer.Size - 1 Do
		vSeedBinaryDataBuffer.WriteBitwiseXor(0, vBinaryDataBuffer.Read(i, 1), 1);	
	EndDo;
	Return GetHexStringFromBinaryDataBuffer(vSeedBinaryDataBuffer);
EndFunction // cmHexLRC

// -----------------------------------------------------------------------------
// Description: Checks longitudinal redundancy check sum for the input 
//              character string. Last two chars of string are assumed to be 
//              input check sum to be compared with new calculated one.
// Parameters: Character string to process
// Return value: True if check sum is right, false if not
// -----------------------------------------------------------------------------
Function cmCheckHexLRC(pStr) Export
	vNewHexLRC = cmHexLRC(Left(pStr, StrLen(pStr) - 2));
	vInpHexLRC = Right(pStr, 2);
	If vNewHexLRC = vInpHexLRC Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmCheckHexLRC

// -----------------------------------------------------------------------------
// Description: Always returns char(13) so far...
// Parameters: Character string to process
// Return value: Char(13)
// -----------------------------------------------------------------------------
Function cmCharLRC(pStr, pRet13 = True) Export
	If pRet13 Then
		Return Char(13);
	Else
		vBinaryDataBuffer = GetBinaryDataBufferFromString(pStr);
		vSeedBinaryDataBuffer = New BinaryDataBuffer(1);
		For i = 0 To vBinaryDataBuffer.Size - 1 Do
			vSeedBinaryDataBuffer.WriteBitwiseXor(0, vBinaryDataBuffer.Read(i, 1), 1);	
		EndDo;
		Return Char(vSeedBinaryDataBuffer[0]); 
	EndIf;
EndFunction // cmCharLRC

// -----------------------------------------------------------------------------
// Description: Checks longitudinal redundancy check sum for the input 
//              character string. Last one char of string is assumed to be 
//              input check sum to be compared with new calculated one.
// Parameters: Character string to process
// Return value: True if check sum is right, false if not
// -----------------------------------------------------------------------------
Function cmCheckCharLRC(pStr, pRet13 = True) Export
	vInpCharLRC = Right(pStr, 1);
	vStr = Left(pStr, StrLen(pStr) - 1);
	vNewCharLRC = cmCharLRC(vStr, pRet13);
	If vNewCharLRC = Char(13) Or vNewCharLRC = vInpCharLRC Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmCheckCharLRC

// -----------------------------------------------------------------------------
// Description: Calculates hex number returned as string representing simple 
//              check sum for the input character string
// Parameters: Character string to process
// Return value: True if check sum is right, false if not
// -----------------------------------------------------------------------------
Function cmHexCSUM(pStr) Export
	vDecCSUM = 0;
	For i = 1 To StrLen(pStr) Do
		vDecCSUM = vDecCSUM + CharCode(Mid(pStr, i, 1));
		vDecCSUM = cmBin2Dec(Right(cmDec2Bin(vDecCSUM), 8)); // Take last byte decimal code as next iteration seed
	EndDo;
	vHexCSUM = cmBin2Hex(cmDec2Bin(vDecCSUM));
	If StrLen(vHexCSUM) = 1 Then
		vHexCSUM = "0" + vHexCSUM;
	EndIf;
	Return vHexCSUM;
EndFunction // cmHexCSUM

// -----------------------------------------------------------------------------
// Description: Checks simple check sum for the input character string
// Parameters: Character string to process
// Return value: True if check sum is right, false if not
// -----------------------------------------------------------------------------
Function cmCheckHexCSUM(pStr) Export
	vNewHexCSUM = cmHexCSUM(Mid(pStr, 2, StrLen(pStr) - 4));
	vInpHexCSUM = Left(Right(pStr, 3), 2);
	If vNewHexCSUM = vInpHexCSUM Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmCheckHexCSUM

// -----------------------------------------------------------------------------
// Description: Returns TCP\IP COM component license code ver. 6
// Parameters: None
// Return value: License code
// -----------------------------------------------------------------------------
Function cmGetCSWSOCK6LicenseKey() Export
	Return "HODLMGFPHNNBOMRB";
EndFunction // cmGetCSWSOCK6LicenseKey

// -----------------------------------------------------------------------------
// Description: Returns TCP\IP COM component license code ver. 10
// Parameters: None
// Return value: License code
// -----------------------------------------------------------------------------
Function cmGetCSWSOCK10LicenseKey() Export
	Return "FmCJsEIqOPoERjGNlKWqFUhHKpIIuK";
EndFunction // cmGetCSWSOCK10LicenseKey

// -----------------------------------------------------------------------------
// Description: Appends right blanks to the given string up to the given string length
// Parameters: String, Length of string to return
// Return value: String
// -----------------------------------------------------------------------------
Function cmAppendBlanks(pStr, pLen, pChar = " ") Export
	vStr = String(pStr);
	For i = 1 To pLen Do
		If StrLen(vStr) = pLen Then
			Break;
		Else
			vStr = vStr + pChar;
		EndIf;
	EndDo;
	Return vStr;
EndFunction // cmAppendBlanks

// -----------------------------------------------------------------------------
// Description: Appends left blanks to the given string up to the given string length
// Parameters: String, Length of string to return
// Return value: String
// -----------------------------------------------------------------------------
Function cmAppendLeftBlanks(pStr, pLen) Export
	vStr = TrimL(pStr);
	For i = 1 To pLen Do
		If StrLen(vStr) = pLen Then
			Break;
		Else
			vStr = " " + vStr;
		EndIf;
	EndDo;
	Return vStr;
EndFunction // cmAppendLeftBlanks

// -----------------------------------------------------------------------------
// Description: Returns value table with all report items
// Parameters: Reports catalog folder to filter reports by
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetAllReports(pReportsFolder = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	Reports.Ref AS Report
	|FROM
	|	Catalog.Reports AS Reports
	|WHERE
	|	Reports.IsFolder = FALSE AND " +
		?(ValueIsFilled(pReportsFolder), "Reports.Ref IN HIERARCHY(&qReportsFolder) AND ", "") + "
	|	Reports.DeletionMark = FALSE
	|ORDER BY Reports.SortCode";
	vQry.SetParameter("qReportsFolder", pReportsFolder);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllReports

// -----------------------------------------------------------------------------
// Description: Returns whether to show not enough rooms messages to the 
//              current user or not
// Parameters: None
// Return value: False if messages shouldn't be shown, true if yes
// -----------------------------------------------------------------------------
Function cmShowNotEnoughRoomsMessages() Export
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
			If SessionParameters.CurrentUser.EmployeePreferences.DoNotShowNotEnoughRoomsMessages Then
				Return False;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction // cmShowNotEnoughRoomsMessages

// -----------------------------------------------------------------------------
// Description: Returns value table with phone numbers for the given list of rooms
// Parameters: Value list of rooms
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetPhoneNumbersForRooms(pRooms) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PhoneNumbers.Ref,
	|	PhoneNumbers.Room,
	|	PhoneNumbers.PhoneNumber AS PhoneNumber
	|FROM
	|	Catalog.PhoneNumbers AS PhoneNumbers
	|WHERE
	|	(NOT PhoneNumbers.DeletionMark)
	|	AND PhoneNumbers.Room IN(&qRoomsList)
	|ORDER BY
	|	PhoneNumber";
	vQry.SetParameter("qRoomsList", pRooms);
	vPhoneNumbers = vQry.Execute().Unload();
	Return vPhoneNumbers;
EndFunction // cmGetPhoneNumbersForRooms

// -----------------------------------------------------------------------------
// Description: Return room for the given internal phone number
// Parameters: Phone number
// Return value: Room
// -----------------------------------------------------------------------------
Function cmGetRoomByPhoneNumber(pPhoneNumber) Export
	vRoom = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PhoneNumbers.Ref,
	|	PhoneNumbers.Room,
	|	PhoneNumbers.PhoneNumber AS PhoneNumber
	|FROM
	|	Catalog.PhoneNumbers AS PhoneNumbers
	|WHERE
	|	(NOT PhoneNumbers.DeletionMark)
	|	AND PhoneNumbers.PhoneNumber = &qPhoneNumber
	|ORDER BY
	|	PhoneNumbers.Room.SortCode";
	vQry.SetParameter("qPhoneNumber", TrimR(pPhoneNumber));
	vPhoneNumbers = vQry.Execute().Unload();
	If vPhoneNumbers.Count() > 0 Then
		vRoom = vPhoneNumbers.Get(0).Room;
	EndIf;
	Return vRoom;
EndFunction // cmGetRoomByPhoneNumber

// -----------------------------------------------------------------------------
// Description: Returns count of elemnts from the parameter iterator
// Parameters: ValueList, Array, ValueTable, ...
// Return value: Count of elements as number
// -----------------------------------------------------------------------------
Function cmCount(pIter) Export
	Try
		Return pIter.Count();
	Except
	EndTry;
	Return 0;
EndFunction // cmCount

// -----------------------------------------------------------------------------
// Description: Replaces MS Excel file data with picture of those data. Excel file 
//              becames read only without any chance to edit it
// Parameters: Full path to the file to be converted, Spreadsheet 
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmDoExcelSpreadSheetReadOnly(pFilePath, pSpreadsheet) Export
	// Get number of pages
	Try
		vPagesCount = pSpreadsheet.PageCount();
	Except
		Raise NStr("en='Please set up default windows printer first!';
		           |ru='Пожалуйста настройте в Windows хотя бы один принтер по умолчанию!';
				   |de='Bitte stellen Sie in Windows mindestens einen Drucker als Standard-Drucker ein!'");
	EndTry;
	Try
		vFile = New File(pFilePath);
		If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() Then
			vFileName = vFile.Name;
			// Assuming that MS Office is installed in the system
			vExcel = New COMObject("Excel.Application");
			vExcel.Workbooks.Open(pFilePath);
			vWorkbook = vExcel.Workbooks.Item(vFileName);
			vWorkbook.Parent.ActiveWindow.DisplayGridlines = False;
			vSheet = vWorkbook.ActiveSheet;
			vSheet.PageSetup.Zoom = False;
			vSheet.PageSetup.BlackAndWhite = True;
			vSheet.PageSetup.FitToPagesWide = 1;
			vSheet.PageSetup.FitToPagesTall = vPagesCount;
			vPrintRange = vSheet.UsedRange;
			vPrintRange.CopyPicture(1);
			vPrintRange.Worksheet.Paste(vPrintRange.Item(1));
			vPrintRange.Clear();
			vNewUUID = New UUID(); // Will be used as password
			vSheet.Protect(String(vNewUUID), True, True, True, , True, False, False, False, False, False, False, False, False, False, False);
			vWorkbook.Protect(String(vNewUUID), True, False);
		    vWorkbook.Save();
		    vWorkbook.Close();
			vExcel = Undefined;
		EndIf;
	Except
		tcCommonFunctionOnClientServer.UserMessage(ErrorDescription());
	EndTry;
EndProcedure // cmDoExcelSpreadSheetReadOnly

// -----------------------------------------------------------------------------
// Description: Removes commas from the text
// Parameters: Text
// Return value: Text without commas
// -----------------------------------------------------------------------------
Function cmRemoveComma(pStr) Export
	Return StrReplace(StrReplace(TrimR(pStr), ",", ""), Chars.LF, "");
EndFunction // cmRemoveComma

// -----------------------------------------------------------------------------
// Description: Returns period presentation as string
// Parameters: Start of period date, End of period date
// Return value: String
// -----------------------------------------------------------------------------
Function cmPeriodPresentation(pDateFrom, pDateTo) Export
	vStr = "";
	If BegOfDay(pDateFrom) = BegOfDay(pDateTo) Then
		vStr = Format(pDateFrom, "DF=dd.MM.yy");
	Else
		vStr = Format(pDateFrom, "DF=dd.MM.yy") + " - " + Format(pDateTo, "DF=dd.MM.yy");
	EndIf;
	Return vStr;	
EndFunction // cmPeriodPresentation

// -----------------------------------------------------------------------------
// Description: This function checks whether current user has rights to open 
//              report form or not
// Parameters: Catalog Reports reference
// Return value: Boolean, true if user has rights, false if not
// -----------------------------------------------------------------------------
Function cmCheckUserRightsToOpenReport(pReport) Export
	vUserHasRights = True;
	If Not cmCheckUserPermissions("HavePermissionToRunAllReports") Then
		If ValueIsFilled(pReport) And ValueIsFilled(SessionParameters.CurrentUser) Then
			vPermissionGroup = SessionParameters.CurrentUser.PermissionGroup;
			vNonReplAttrs = CachedSettings.сmGetEmployeeNonReplicatingAttributes(SessionParameters.CurrentUser);
			If vNonReplAttrs.Count() > 0 Then
				If ValueIsFilled(vNonReplAttrs.Get(0).PermissionGroup) Then
					vPermissionGroup = vNonReplAttrs.Get(0).PermissionGroup;
				EndIf;
			EndIf;
			If ValueIsFilled(vPermissionGroup) Then
				If pReport.PermissionGroup <> vPermissionGroup Then
					If pReport.PermissionGroups.Find(vPermissionGroup, "PermissionGroup") = Undefined Then
						vUserHasRights = False;
					EndIf;
				EndIf;
			Else
				vUserHasRights = False;
			EndIf;
		EndIf;
	EndIf;
	Return vUserHasRights;
EndFunction // cmCheckUserRightsToOpenReport

// -----------------------------------------------------------------------------
// Description: This function checks whether current user has rights to execute 
//              data processor or not
// Parameters: Catalog DataProcessors reference
// Return value: Boolean, true if user has rights, false if not
// -----------------------------------------------------------------------------
Function cmCheckUserRightsToExecuteDataProcessor(pDP) Export
	vUserHasRights = True;
	If Not cmCheckUserPermissions("HavePermissionToRunAllDataProcessors") Then
		If ValueIsFilled(pDP) And ValueIsFilled(SessionParameters.CurrentUser) Then
			vPermissionGroup = SessionParameters.CurrentUser.PermissionGroup;
			vNonReplAttrs = CachedSettings.сmGetEmployeeNonReplicatingAttributes(SessionParameters.CurrentUser);
			If vNonReplAttrs.Count() > 0 Then
				If ValueIsFilled(vNonReplAttrs.Get(0).PermissionGroup) Then
					vPermissionGroup = vNonReplAttrs.Get(0).PermissionGroup;
				EndIf;
			EndIf;
			If ValueIsFilled(vPermissionGroup) Then
				If pDP.PermissionGroup <> vPermissionGroup Then
					If pDP.PermissionGroups.Find(vPermissionGroup, "PermissionGroup") = Undefined Then
						vUserHasRights = False;
					EndIf;
				EndIf;
			Else
				vUserHasRights = False;
			EndIf;
		EndIf;
	EndIf;
	Return vUserHasRights;
EndFunction // cmCheckUserRightsToExecuteDataProcessor

// -----------------------------------------------------------------------------
// Description: Load's report static and dynamic settings and parameters from the given XML file
// Parameters: Reports catalog item object, report settings file path
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmReadReportSettingsFromFile(pRepObj, pFileName) Export
	vXMLReader = New XMLReader();
	vXMLReader.OpenFile(pFileName);
	While vXMLReader.Read() Do
		If vXMLReader.NodeType = XMLNodeType.StartElement Then
			If vXMLReader.Name = "htl:ReportSettings" Then
				While vXMLReader.ReadAttribute() Do
					If vXMLReader.Name = "htl:report" Then
						If vXMLReader.Value <> TrimAll(pRepObj.Report) Then
							Raise NStr("en='Report settings you are trying to load from are of different report type!';
							           |ru='Тип отчета, настройки которого пытаетесь загрузить, отличается от типа текущего отчета!';
									   |de='Der Berichtstyp, dessen Einstellungen Sie zu laden versuchen, unterscheidet sich vom Typ des aktuellen Berichts!'");
						EndIf;
					EndIf;
				EndDo;
			ElsIf vXMLReader.Name = "htl:Dynamic" Then
				vXMLReader.Read();
				pRepObj.DynamicParameters = ReadXML(vXMLReader);
			ElsIf vXMLReader.Name = "htl:Static" Then
				vXMLReader.Read();
				pRepObj.StaticParameters = ReadXML(vXMLReader);
			EndIf;
		EndIf;
	EndDo;
	vXMLReader.Close();
EndProcedure // cmReadReportSettingsFromFile

// -----------------------------------------------------------------------------
// Description: Saves report static and dynamic settings and parameters to the given XML file
// Parameters: Reports catalog item reference or object, file path where to save 
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmWriteReportSettingsToFile(pRep, pFileName) Export
	vNameSpaceURI = "http://1chotel.ru";
	vXMLWriter = New XMLWriter();
	vXMLWriter.OpenFile(pFileName, "UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	vXMLWriter.WriteStartElement("Hotel");
	vXMLWriter.WriteNamespaceMapping("htl", vNameSpaceURI);
	vXMLWriter.WriteStartElement("ReportSettings", vNameSpaceURI);
	vXMLWriter.WriteAttribute("report", vNameSpaceURI, TrimAll(pRep.Report));
	vXMLWriter.WriteStartElement("Dynamic", vNameSpaceURI);
	WriteXML(vXMLWriter, pRep.DynamicParameters, XMLTypeAssignment.Explicit);
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteStartElement("Static", vNameSpaceURI);
	WriteXML(vXMLWriter, pRep.StaticParameters, XMLTypeAssignment.Explicit);
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();
	vXMLWriter.Close();
EndProcedure // cmWriteReportSettingsToFile

// -----------------------------------------------------------------------------
// Description: This function reads report default settings from the report template
// Parameters: Report name
// Return value: String, xml with report settings
// -----------------------------------------------------------------------------
Function cmReadReportDefaultSettingFromTemplate(pReportObj) Export
	vReportSettings = Undefined;
	Try
		vFileName = GetTempFileName("xml");
		Reports[pReportObj.Report].GetTemplate("DefaultSettings").Write(vFileName);
		vFileReader = New TextReader(vFileName, TextEncoding.UTF8);
		vReportSettings = vFileReader.Read();
		vFileReader.Close();
		// Activate default report settings
		cmReadReportSettingsFromFile(pReportObj, vFileName);     
		DeleteFiles(vFileName);
	Except
	EndTry;
	Return vReportSettings;
EndFunction // cmReadReportDefaultSettingFromTemplate

// -----------------------------------------------------------------------------
// Description: This function converts string first character to upper case
// Parameters: String to be converted
// Return value: String
// -----------------------------------------------------------------------------
Function cmFirstLetter2Upper(pStr) Export 
	vStr = "";
	vStrLen = StrLen(pStr);
	If vStrLen > 1 Then	
		vStr = Upper(Left(pStr, 1)) + Mid(pStr, 2);
		Return vStr;
	ElsIf vStrLen = 1 Then
		Return Upper(pStr);
	Else
		Return pStr;
	EndIf;
EndFunction // cmFirstLetter2Upper

// -----------------------------------------------------------------------------
// Description: This function converts string first character to lower case
// Parameters: String to be converted
// Return value: String
// -----------------------------------------------------------------------------
Function cmFirstLetter2Lower(pStr) Export 
	vStr = "";
	vStrLen = StrLen(pStr);
	If vStrLen > 1 Then	
		vStr = Lower(Left(pStr, 1)) + Mid(pStr, 2);
		Return vStr;
	ElsIf vStrLen = 1 Then
		Return Lower(pStr);
	Else
		Return pStr;
	EndIf;
EndFunction // cmFirstLetter2Lower

// -----------------------------------------------------------------------------
// Description: This function char code into it's hex representation
// Parameters: Char code
// Return value: String hex code representation
// -----------------------------------------------------------------------------
Function cmHex(Val pValue) Export
	vResult = "0";
    vValue = Number(pValue);
    If vValue > 0 Then
        vValue = Int(vValue);
        vResult = "";
        While vValue > 0 Do
            vResult = Mid("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", vValue%16 + 1, 1) + vResult;
            vValue = Int(vValue/16);
        EndDo;
    EndIf;
    If StrLen(vResult) < 2 Then
        vResult = "0" + vResult;
    EndIf;
    Return "%" + vResult;
EndFunction // cmHex

// -----------------------------------------------------------------------------
// Description: Encodes http GET request string
// Parameters: URL string to be encoded
// Return value: Encoded URL string
// -----------------------------------------------------------------------------
Function cmEncodeURL(pURL, pUseSpecialChars = True) Export
    vResult = "";
    For i = 1 To StrLen(pURL) Do
        ch = Mid(pURL, i, 1);
        vch = CharCode(ch);
        If ("A" <= ch) And (ch <= "Z") Then // "A".."Z"
            vResult = vResult + ch;
        ElsIf ("a" <= ch) And (ch <= "z") Then // "a".."z"
            vResult = vResult + ch;
        ElsIf ("0" <= ch) And (ch <= "9") Then // "0".."9"
            vResult = vResult + ch;
        ElsIf (ch = " ") Or (ch = "+") Then // space
            vResult = vResult + "+";
		ElsIf pUseSpecialChars 
			And ((ch = "-") Or (ch = "_") // unreserved
            Or (ch = ".") Or (ch = "!")
            Or (ch = "~") Or (ch = "*")
            Or (ch = "") Or (ch = "(")
            Or (ch = ")")) Then
            vResult = vResult + ch;
        ElsIf (vch <= 127) Then  // other ASCII
            vResult = vResult + cmHex(vch);
        ElsIf (vch <= 2047) Then // non-ASCII <= 0x7FF
            vResult = vResult + cmHex(192 + Int(vch / 64));
            vResult = vResult + cmHex(128 + (vch % 64));
        Else                     // 0x7FF < ch <= 0xFFFF
            vResult = vResult + cmHex(224 + Int(vch / 4096));
            vResult = vResult + cmHex(128 + (Int(vch / 64) % 64));
            vResult = vResult + cmHex(128 + (vch % 64));
        EndIf;
    EndDo;
    Return vResult;
EndFunction // cmEncodeURL

// -----------------------------------------------------------------------------
// 
// -----------------------------------------------------------------------------
Function cmGetQRCodePicture(pCode) Export
	vParametersBarcode = New Structure; 
	vParametersBarcode.Insert("CodeType", 16);
	vParametersBarcode.Insert("Barcode", pCode);
	vParametersBarcode.Insert("InPixels", True);
	vParametersBarcode.Insert("Width", 800);
	vParametersBarcode.Insert("Height", 800);
	vParametersBarcode.Insert("TextVisible", False);
	Return tcSystemBarcodePrinterDriver.pmGetPictureCode(vParametersBarcode);
EndFunction // cmGetQRCodePicture

// -----------------------------------------------------------------------------
// This function fills docx template file with DocumentProperties field values
// -----------------------------------------------------------------------------
Procedure cmProcessDOCXFile(pFilePath, pFieldsStruct) Export
	vF = New File(pFilePath);
	If tcCommonFunctionOnClientServer.cmExists(vF) And vF.IsFile() Then
		vFileName = vF.Name;
		vDirName = vF.BaseName;
		vFile = New ZipFileReader(TempFilesDir()+vFileName);
		vDocumentEntry = vFile.Items.Find("document.xml");
		If vDocumentEntry <> Undefined Then
			vFile.ExtractAll(TempFilesDir()+vDirName+"\");
			vFile.Close();
			vTextFile = New TextDocument;
			vTextFile.Read(TempFilesDir()+vDirName+"\word\document.xml", TextEncoding.UTF8);
			// Process all document fields
			For Each vItem In pFieldsStruct Do
				vText = vTextFile.GetText();
				vItemKey = TrimAll(vItem.Key);
				vSearchText = vText;
				vStep = 0;
				While True Do
					vBeginPos = StrFind(vSearchText, vItemKey); 
					If vBeginPos <> 0 Then
						vBeginPos = vStep + vBeginPos;
						vStep = vBeginPos + StrLen(vItemKey) - 1;
						vSearchText = Mid(vText, vBeginPos + StrLen(vItemKey));
						vLeftText = Left(vText, vBeginPos-1);
						vTempText = Right(vText, StrLen(vText)-vBeginPos+1);
						vPos = StrFind(vTempText, "<w:fldChar w:fldCharType=""end""/></w:r>");
						If vPos <> 0 Then
							vBegOfWTPos = StrFind(vTempText, "<w:t>");
							If vBegOfWTPos <> 0 Then
								vLastEndOfWTPos = -1;
								vEndOfWTPos = 0;
								vCounter = 0;
								While (vCounter < vPos And vLastEndOfWTPos <> 0) Do
									vLastEndOfWTPos = StrFind(Right(vTempText, StrLen(vTempText) - vCounter), "</w:t>");
									vCounter = vCounter + vLastEndOfWTPos + 6;
									If vCounter < vPos And vLastEndOfWTPos <> 0 Then
										vEndOfWTPos = vCounter;
									EndIf;
								EndDo;
								vRightText = Right(vTempText, StrLen(vTempText)-vEndOfWTPos+7);
								vMidLeftText = Left(vTempText, vBegOfWTPos+4);
								vEndText = vLeftText + vMidLeftText + StrReplace(cmEncodeXML(TrimAll(vItem.Value), True), Chars.LF, "</w:t></w:r></w:p><w:p><w:r><w:t xml:space=""preserve"">") + vRightText;
								vTextFile.SetText(vEndText);
								vText = vEndText;
							EndIf;
						EndIf;
					Else
						Break;
					EndIf;
				EndDo;
			EndDo;
			// Update and build file structure
			vTextFile.Write(TempFilesDir() + vDirName + "\word\document.xml");
			vWrFile = New ZipFileWriter(TempFilesDir() + vFileName);
			vWrFile.Add(TempFilesDir() + vDirName + "\*.*", ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.ProcessRecursively);
			vWrFile.Write();
			// Delete file content
			DeleteFiles(TempFilesDir() + vDirName + "\");
		EndIf;
	EndIf;
EndProcedure // cmProcessDOCXFile

// -----------------------------------------------------------------------------
// This function fills odt template file with DocumentProperties field values
// -----------------------------------------------------------------------------
Procedure cmProcessODTFile(pFilePath, pFieldsStruct) Export
	vF = New File(pFilePath);
	If tcCommonFunctionOnClientServer.cmExists(vF) And vF.IsFile() Then
		vFileName = vF.Name;
		vDirName = vF.BaseName;
		vFile = New ZipFileReader(TempFilesDir()+vFileName);
		vDocumentEntry = vFile.Items.Find("meta.xml");
		vContentDocumentEntry = vFile.Items.Find("content.xml");
		If vDocumentEntry <> Undefined Then
			vFile.ExtractAll(TempFilesDir()+vDirName+"\");
			vFile.Close();
			vTextFile = New TextDocument;
			vTextFile.Read(TempFilesDir()+vDirName+"\content.xml", TextEncoding.UTF8);
			// Process all document fields
			For Each vItem In pFieldsStruct Do
				vText = vTextFile.GetText();
				vItemKey = TrimAll(vItem.Key);
				vSearchText = vText;
				vStep = 0;
				While True Do
					vBeginPos = StrFind(vSearchText, vItemKey); 
					If vBeginPos <> 0 Then
						vBeginPos = vStep + vBeginPos;
						vStep = vBeginPos + StrLen(vItemKey) - 1;
						vSearchText = Mid(vText, vBeginPos + StrLen(vItemKey));
						vLeftText = Left(vText, vBeginPos-1);
						vTempText = Right(vText, StrLen(vText)-vBeginPos+1);
						vPos = StrFind(vTempText, "</text:user-defined>");
						If vPos <> 0 Then
							vBegOfWTPos = StrFind(vTempText, ">");
							If vBegOfWTPos <> 0 Then
								vRightText = Right(vTempText, StrLen(vTempText)-vPos+1);
								vMidLeftText = Left(vTempText, vBegOfWTPos);
								vEndText = vLeftText + vMidLeftText +  cmEncodeXML(TrimAll(vItem.Value), True) + vRightText;
								vTextFile.SetText(vEndText);
								vText = vEndText;
							EndIf;
						EndIf;
					Else
						Break;
					EndIf;
				EndDo;
			EndDo;
			// Change field type from "user-defined" to "text-input"
			vText = vTextFile.GetText();
			vText = StrReplace(vText, "user-defined", "text-input");
			vTextFile.SetText(vText);
			// Update and build file structure
			vTextFile.Write(TempFilesDir()+vDirName+"\content.xml");
			vWrFile = New ZipFileWriter(TempFilesDir()+vFileName);
			vWrFile.Add(TempFilesDir()+vDirName+"\*.*", ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.ProcessRecursively);
			vWrFile.Write();
			// Delete file content
			DeleteFiles(TempFilesDir()+vDirName+"\");
		EndIf;
	EndIf;
EndProcedure // cmProcessODTFile

// -----------------------------------------------------------------------------
// This function replaces XML forbiden chars with substitutes
// -----------------------------------------------------------------------------
Function cmEncodeXML(Val pText, pAmpOnly = False) Export
	vText = pText;
	If pAmpOnly Then
		vText = StrReplace(vText, "&", "&amp;");
	Else
		vText = StrReplace(vText, """", "&quot;");
		vText = StrReplace(vText, "©", "&copy;");
		vText = StrReplace(vText, "®", "&reg;");
		vText = StrReplace(vText, "™", "&trade;");
		vText = StrReplace(vText, "„", "&bdquo;");
		vText = StrReplace(vText, "“", "&ldquo;");
		vText = StrReplace(vText, "«", "&laquo;");
		vText = StrReplace(vText, "»", "&raquo;");
		vText = StrReplace(vText, ">", "&gt;");
		vText = StrReplace(vText, "<", "&lt;");
		vText = StrReplace(vText, "≥", "&ge;");
		vText = StrReplace(vText, "≤", "&le;");
		vText = StrReplace(vText, "≈", "&asymp;");
		vText = StrReplace(vText, "≠", "&ne;");
		vText = StrReplace(vText, "≡", "&equiv;");
		vText = StrReplace(vText, "§", "&sect;");
		vText = StrReplace(vText, "&", "&amp;");
		vText = StrReplace(vText, "∞", "&infin;");
	EndIf;
	Return vText;
EndFunction // cmEncodeXML

// -----------------------------------------------------------------------------
// Description: Replaces client name with code, clears all other idenification 
//              client data and clears all history records connected to that client
// Parameters: Reference to the client item
// Return value: Boolean, true if operation completed successfully
// -----------------------------------------------------------------------------
Procedure cmHideClientNameAndNameHistory(pClient) Export
	vCltObj = pClient.GetObject();
	// Replace client name with client code
	vCltObj.LastName = ?(cmIsNumber(TrimAll(vCltObj.Code)), Format(Number(vCltObj.Code), "ND=12; NFD=0; NG="), TrimAll(vCltObj.Code));
	vCltObj.FirstName = "";
	vCltObj.SecondName = "";
	vCltObj.Description = vCltObj.LastName;
	vCltObj.FullName = vCltObj.LastName;
	// Cliear other client identification data. 
	// We will skip clearing citizenship, date of birth and address 
	// to avoid change in the sales statistics
	vCltObj.Phone = "";
	vCltObj.Fax = "";
	vCltObj.EMail = "";
	vCltObj.PlaceOfBirth = "";
	vCltObj.IdentityDocumentType = Undefined;
	vCltObj.IdentityDocumentSeries = "";
	vCltObj.IdentityDocumentNumber = "";
	vCltObj.IdentityDocumentIssueDate = Undefined;
	vCltObj.IdentityDocumentValidToDate = Undefined;
	vCltObj.IdentityDocumentIssuedBy = "";
	vCltObj.MilitaryRank = "";
	vCltObj.Certificate = "";
	vCltObj.PlaceOfEmployment = "";
	vCltObj.PolicyOfMedicalInsurance = "";
	vCltObj.AmbulatoryCard = "";
	vCltObj.Disablement = "";
	vCltObj.Children = "";
	vCltObj.Parents = "";
	vCltObj.Title = "";
	vCltObj.Salutation = "";
	vCltObj.Photo = Undefined;
	vCltObj.Signature = Undefined; 
	vCltObj.AddressRegistrationDate = Undefined;
	vCltObj.AddressRegistrationDateTo = Undefined;
	vCltObj.PostalAddress = ""; 
	vCltObj.PlaceOfBirth = ""; 
	vCltObj.SocialSecurityNumber = "";
	vCltObj.PersonalNumber = "";
    vCltObj.AddressPresentation = "";
	vCltObj.IdentityDocumentPresentation = "";
	vCltObj.TIN = "";
	vCltObj.EMailAdditional = "";
	vAddressStruct = cmParseAddress(TrimAll(vCltObj.Address));
	vAddressStruct.Street = "";
	vAddressStruct.House = "";
	vAddressStruct.Flat = "";
	vCltObj.Address = cmBuildAddress(vAddressStruct.Country, vAddressStruct.PostCode, vAddressStruct.Region, vAddressStruct.Area, vAddressStruct.City, vAddressStruct.Street, vAddressStruct.House, vAddressStruct.Flat);
	// Save changes
	vCltObj.Write();
	// Write client change history record
	vCltObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	// Clear client change history records
	vSet = InformationRegisters.ClientChangeHistory.CreateRecordSet();
	vSet.Filter.Client.ComparisonType = ComparisonType.Equal;
	vSet.Filter.Client.Value = pClient;
	vSet.Filter.Client.Use = True;
	vSet.Read();
	For Each vSetRow In vSet Do
		FillPropertyValues(vSetRow, vCltObj);
		vSetRow.Changes = "";
	EndDo;
	vSet.Write(True);
	// Find references to the client in the reservation change history and clear them either
	vSet = InformationRegisters.ReservationChangeHistory.CreateRecordSet();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Guest = &qClient
	|
	|ORDER BY
	|	Reservation.PointInTime";
	vQry.SetParameter("qClient", pClient);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		// Update reservation full guest name
		vDocObj = vDocsRow.Ref.GetObject();
		If TrimAll(vDocObj.GuestFullName) <> TrimAll(vCltObj.FullName) Then
			vDocObj.GuestFullName = vCltObj.FullName;
			vDocObj.Phone = "";
			vDocObj.EMail = "";
			vDocObj.EMailAdditional = "";
			vDocObj.Fax = "";
			vDocObj.Write(DocumentWriteMode.Write);
		EndIf;
		// Update document change history
		vSet.Filter.Reservation.ComparisonType = ComparisonType.Equal;
		vSet.Filter.Reservation.Value = vDocsRow.Ref;
		vSet.Filter.Reservation.Use = True;
		vSet.Read();
		For Each vSetRow In vSet Do
			vSetRow.Phone = "";
			vSetRow.EMail = "";  
			vSetRow.EMailAdditional = "";
			vSetRow.Fax = "";
			vSetRow.GuestFullName = vCltObj.FullName;
			vSetRow.Changes = "";
		EndDo;
		vSet.Write(True);
	EndDo;
	// Find references to the client in the resource reservation change history and clear them either
	vSet = InformationRegisters.ResourceReservationChangeHistory.CreateRecordSet();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ResourceReservation.Ref
	|FROM
	|	Document.ResourceReservation AS ResourceReservation
	|WHERE
	|	ResourceReservation.Client = &qClient
	|
	|ORDER BY
	|	ResourceReservation.PointInTime";
	vQry.SetParameter("qClient", pClient);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		// Update resource reservation contact data
		vDocObj = vDocsRow.Ref.GetObject();
		If Not IsBlankString(vDocObj.Phone) Or Not IsBlankString(vDocObj.EMail) Then
			vDocObj.Phone = "";
			vDocObj.EMail = "";
			vDocObj.EMailAdditional = "";
			vDocObj.Fax = "";
			vDocObj.Write(DocumentWriteMode.Write);
		EndIf;
		// Update document change history
		vSet.Filter.ResourceReservation.ComparisonType = ComparisonType.Equal;
		vSet.Filter.ResourceReservation.Value = vDocsRow.Ref;
		vSet.Filter.ResourceReservation.Use = True;
		vSet.Read();
		For Each vSetRow In vSet Do
			vSetRow.Phone = "";
			vSetRow.EMail = ""; 
			vSetRow.EMailAdditional = "";
			vSetRow.Fax = "";
			vSetRow.Changes = "";
		EndDo;
		vSet.Write(True);
	EndDo;
	// Find references to the client in the accommodation change history and clear them either
	vSet = InformationRegisters.AccommodationChangeHistory.CreateRecordSet();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Guest = &qClient
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qClient", pClient);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		// Update accommodation full guest name
		vDocObj = vDocsRow.Ref.GetObject();
		If TrimAll(vDocObj.GuestFullName) <> TrimAll(vCltObj.FullName) Then
			vDocObj.GuestFullName = vCltObj.FullName;
			vDocObj.Phone = "";
			vDocObj.EMail = "";
			vDocObj.EMailAdditional = "";
			vDocObj.Fax = "";
			vDocObj.Write(DocumentWriteMode.Write);
		EndIf;
		// Update document change history
		vSet.Filter.Accommodation.ComparisonType = ComparisonType.Equal;
		vSet.Filter.Accommodation.Value = vDocsRow.Ref;
		vSet.Filter.Accommodation.Use = True;
		vSet.Read();
		For Each vSetRow In vSet Do
			vSetRow.GuestFullName = vCltObj.FullName;
			vSetRow.Phone = "";
			vSetRow.EMail = ""; 
			vSetRow.EMailAdditional = "";
			vSetRow.Fax = "";
			vSetRow.Changes = "";
		EndDo;
		vSet.Write(True);
	EndDo;
	// Find references to the client in the foreigner record change history and clear them either
	vSet = InformationRegisters.ForeignerRegistryRecordChangeHistory.CreateRecordSet();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ForeignerRegistryRecord.Ref
	|FROM
	|	Document.ForeignerRegistryRecord AS ForeignerRegistryRecord
	|WHERE
	|	ForeignerRegistryRecord.Guest = &qClient
	|
	|ORDER BY
	|	ForeignerRegistryRecord.PointInTime";
	vQry.SetParameter("qClient", pClient);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		// Update document
		vDocObj = vDocsRow.Ref.GetObject();
		FillPropertyValues(vDocObj, vCltObj, , "Author, Remarks");
		vDocObj.Write(DocumentWriteMode.Write);
		// Update document change history
		vSet.Filter.ForeignerRegistryRecord.ComparisonType = ComparisonType.Equal;
		vSet.Filter.ForeignerRegistryRecord.Value = vDocsRow.Ref;
		vSet.Filter.ForeignerRegistryRecord.Use = True;
		vSet.Read();
		For Each vSetRow In vSet Do
			FillPropertyValues(vSetRow, vCltObj, , "Author, Remarks");
			vSetRow.Changes = "";
		EndDo;
		vSet.Write(True);
	EndDo;
EndProcedure // cmHideClientNameAndNameHistory

// -----------------------------------------------------------------------------
// Description: Returns boolean true if file is editable i.e. word document, spreadsheet,
//              text or e-mail. Returns false if file is picture or pdf
// Parameters: File name
// Return value: Boolean, true if file is editable
// -----------------------------------------------------------------------------
Function cmIsFileEditable(pExtension) Export
	vFileExtensions = Lower(Constants.EditableFileExtensions.Get());
	If IsBlankString(vFileExtensions) Then
		If Lower(pExtension) = ".xls" 
		   Or Lower(pExtension) = ".xlsx"
		   Or Lower(pExtension) = ".doc"
		   Or Lower(pExtension) = ".docx"
		   Or Lower(pExtension) = ".txt"
		   Or Lower(pExtension) = ".rtf"
		   Or Lower(pExtension) = ".odt"
		   Or Lower(pExtension) = ".odf"
		   Or Lower(pExtension) = ".eml" Then
			Return True;
		EndIf;
	Else
		vExtension = Lower(pExtension);
		If Left(pExtension, 1) = "." Then
			vExtension = Mid(vExtension, 2);
		EndIf;
		If StrFind(vFileExtensions, vExtension) > 0 Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // cmIsFileEditable

// -----------------------------------------------------------------------------
// Description: Returns path to 1C program common directory
// Parameters: None
// Return value: String
// -----------------------------------------------------------------------------
Function cmCommonDir() Export
	vDir = Lower(BinDir());
	vCommonPos = StrFind(vDir, "\1cv8\");
	If vCommonPos > 0 Then
		vDir = Left(vDir, vCommonPos + 4) + "\common\";
	EndIf;
	Return vDir;
EndFunction // cmCommonDir

// -----------------------------------------------------------------------------
// Description: Returns structure of report builder attributes initialized with
//              default values
// Parameters: None
// Return value: Structure
// -----------------------------------------------------------------------------
Function cmGetReportBuilderAttributesStructure() Export
	vStruct = New Structure();
	// Initialize details fill type
	vStruct.Insert("DetailFillType", ReportBuilderDetailsFillType.GroupValues);
	
	// Set report formatting rules
	vStruct.Insert("DimensionsPlacementOnRows", DimensionPlacementType.Together);
	vStruct.Insert("DimensionAttributePlacementInRows", DimensionAttributePlacementType.WithDimensions);
	vStruct.Insert("TotalsPlacementOnRows", TotalPlacementType.Header);
	
	vStruct.Insert("DimensionsPlacementOnColumns", DimensionPlacementType.Together);
	vStruct.Insert("DimensionAttributePlacementInColumns", DimensionAttributePlacementType.WithDimensions);
	vStruct.Insert("TotalsPlacementOnColumns", TotalPlacementType.Header);
	
	// Apply report sections appearance rules
	vStruct.Insert("PutReportHeader", True);
	vStruct.Insert("PutTableHeader", True);
	vStruct.Insert("PutDetailRecords", True);
	vStruct.Insert("PutTableFooter", True);
	vStruct.Insert("PutOveralls", True);
	vStruct.Insert("PutReportFooter", True);
	
	// Show status
	vStruct.Insert("ShowStatus", True);
	
	// User interrupt processing
	vStruct.Insert("ProcessUserInterruption", True);
	
	// Return structure being build
	Return vStruct;
EndFunction // cmGetReportBuilderAttributesStructure

// -----------------------------------------------------------------------------
// Description: Fills report builder attributes from the input structure
// Parameters: Report object, Attributes structure
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSetReportBuilderAttributes(pRepObject, pAttributesStruct) Export
	// Check user rights to open report
	If Not cmCheckUserRightsToOpenReport(pRepObject.Report) Then
		Raise NStr("en='You do not have rights to run report: ';ru='Нет прав на формирование отчета: ';de='Sie haben keine Rechte, einen Bericht zu erstellen: '") + cmNStr(pRepObject.Report.Description) + "!";
	EndIf;
	
	// Initialize query fields presentation addition type 
	pRepObject.ReportBuilder.PresentationAdding = PresentationAdditionType.DontAdd;
	
	// Initialize details fill type
	If pAttributesStruct.Property("DetailFillType") Then
		pRepObject.ReportBuilder.DetailFillType = pAttributesStruct.DetailFillType;
	Else
		pRepObject.ReportBuilder.DetailFillType = ReportBuilderDetailsFillType.GroupValues;
	EndIf;
	
	// Set report formatting rules
	pRepObject.ReportBuilder.DimensionsPlacementOnRows = ?(pRepObject.ReportDimensionsPlacementOnRowsType.IsEmpty(), 
	                                                       pAttributesStruct.DimensionsPlacementOnRows, 
	                                                       DimensionPlacementType[pRepObject.ReportDimensionsPlacementOnRowsType.Metadata().EnumValues[Enums.ReportDimensionsPlacementTypes.IndexOf(pRepObject.ReportDimensionsPlacementOnRowsType)].Name]);
	pRepObject.ReportBuilder.DimensionAttributePlacementInRows = ?(pRepObject.ReportDimensionAttributesPlacementInRowsType.IsEmpty(), 
	                                                               pAttributesStruct.DimensionAttributePlacementInRows, 
	                                                               DimensionAttributePlacementType[pRepObject.ReportDimensionAttributesPlacementInRowsType.Metadata().EnumValues[Enums.ReportDimensionAttributesPlacementTypes.IndexOf(pRepObject.ReportDimensionAttributesPlacementInRowsType)].Name]);
	pRepObject.ReportBuilder.TotalsPlacementOnRows = ?(pRepObject.ReportTotalsPlacementOnRowsType.IsEmpty(), 
	                                                   pAttributesStruct.TotalsPlacementOnRows, 
	                                                   TotalPlacementType[pRepObject.ReportTotalsPlacementOnRowsType.Metadata().EnumValues[Enums.ReportTotalsPlacementTypes.IndexOf(pRepObject.ReportTotalsPlacementOnRowsType)].Name]);
	
	pRepObject.ReportBuilder.DimensionsPlacementOnColumns = ?(pRepObject.ReportDimensionsPlacementOnColumnsType.IsEmpty(), 
	                                                          pAttributesStruct.DimensionsPlacementOnColumns, 
	                                                          DimensionPlacementType[pRepObject.ReportDimensionsPlacementOnColumnsType.Metadata().EnumValues[Enums.ReportDimensionsPlacementTypes.IndexOf(pRepObject.ReportDimensionsPlacementOnColumnsType)].Name]);
	pRepObject.ReportBuilder.DimensionAttributePlacementInColumns = ?(pRepObject.ReportDimensionAttributesPlacementInColumnsType.IsEmpty(), 
	                                                                  pAttributesStruct.DimensionAttributePlacementInColumns, 
	                                                                  DimensionAttributePlacementType[pRepObject.ReportDimensionAttributesPlacementInColumnsType.Metadata().EnumValues[Enums.ReportDimensionAttributesPlacementTypes.IndexOf(pRepObject.ReportDimensionAttributesPlacementInColumnsType)].Name]);
	pRepObject.ReportBuilder.TotalsPlacementOnColumns = ?(pRepObject.ReportTotalsPlacementOnColumnsType.IsEmpty(), 
	                                                      pAttributesStruct.TotalsPlacementOnColumns, 
	                                                      TotalPlacementType[pRepObject.ReportTotalsPlacementOnColumnsType.Metadata().EnumValues[Enums.ReportTotalsPlacementTypes.IndexOf(pRepObject.ReportTotalsPlacementOnColumnsType)].Name]);
	
	// Apply report sections appearance rules
	If ValueIsFilled(pRepObject.ReportAppearanceTemplateType) Then
		pRepObject.ReportBuilder.PutReportHeader = Not pRepObject.ReportDoNotPutReportHeader;
		pRepObject.ReportBuilder.PutTableHeader = Not pRepObject.ReportDoNotPutTableHeader;
		pRepObject.ReportBuilder.PutDetailRecords = Not pRepObject.ReportDoNotPutDetailRecords;
		pRepObject.ReportBuilder.PutTableFooter = Not pRepObject.ReportDoNotPutTableFooter;
		pRepObject.ReportBuilder.PutOveralls = Not pRepObject.ReportDoNotPutOveralls;
		pRepObject.ReportBuilder.PutReportFooter = Not pRepObject.ReportDoNotPutReportFooter;
	Else
		pRepObject.ReportBuilder.PutReportHeader = pAttributesStruct.PutReportHeader;
		pRepObject.ReportBuilder.PutTableHeader = pAttributesStruct.PutTableHeader;
		pRepObject.ReportBuilder.PutDetailRecords = pAttributesStruct.PutDetailRecords;
		pRepObject.ReportBuilder.PutTableFooter = pAttributesStruct.PutTableFooter;
		pRepObject.ReportBuilder.PutOveralls = pAttributesStruct.PutOveralls;
		pRepObject.ReportBuilder.PutReportFooter = pAttributesStruct.PutReportFooter;
		
		pRepObject.ReportDoNotPutReportHeader = Not pAttributesStruct.PutReportHeader;
		pRepObject.ReportDoNotPutTableHeader = Not pAttributesStruct.PutTableHeader;
		pRepObject.ReportDoNotPutDetailRecords = Not pAttributesStruct.PutDetailRecords;
		pRepObject.ReportDoNotPutTableFooter = Not pAttributesStruct.PutTableFooter;
		pRepObject.ReportDoNotPutOveralls = Not pAttributesStruct.PutOveralls;
		pRepObject.ReportDoNotPutReportFooter = Not pAttributesStruct.PutReportFooter;
	EndIf;
	
	// Set auto detail records
	If Not pRepObject.ReportBuilder.PutOveralls Then
		pRepObject.ReportBuilder.AutoDetailRecords = False;
	Else
		pRepObject.ReportBuilder.AutoDetailRecords = True;
	EndIf;
	
	// Initialize report builder header text
	If IsBlankString(pRepObject.Report.ReportHeaderText) Then
		pRepObject.ReportBuilder.HeaderText = cmNStr(pRepObject.Report.Description);
	Else
		pRepObject.ReportBuilder.HeaderText = cmNStr(pRepObject.Report.ReportHeaderText);
	EndIf;
	
	// Show status on put
	pRepObject.ReportBuilder.ShowStatus = pAttributesStruct.ShowStatus;
	
	// Initialize user interrupt processing
	pRepObject.ReportBuilder.ProcessUserInterruption = pAttributesStruct.ProcessUserInterruption;
EndProcedure // cmSetReportBuilderAttributes

// -----------------------------------------------------------------------------
// Description: Applies appearance to the report template generated by report 
//              builder object
// Parameters: Report object
// Return value: Structure
// -----------------------------------------------------------------------------
Function cmApplyReportTemplateAppearance(pRepObj) Export
	CheckReportColumnOverridesStructure(pRepObj.ReportColumnOverrides);
	Return ApplyReportTemplateAppearance(pRepObj);
EndFunction // cmApplyReportTemplateAppearance

// -----------------------------------------------------------------------------
// Description: Checks if input ref is broken
// Parameters: Type of ref as string, f.e. "Catalog.Clients", "Document.SetRoomQuota"
// Return value: String
// -----------------------------------------------------------------------------
Function cmIsBrokenRef(pSomething, pRef) Export
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Something.Ref
	|FROM
	|	"+pSomething+" AS Something
	|WHERE
	|	Something.Ref = &qRef";
	vQry.SetParameter("qRef", pRef);
	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		Return False;
	EndDo;
	Return True;
EndFunction // cmIsBrokenRef

// -----------------------------------------------------------------------------
// Returns unit code by unit description
// -----------------------------------------------------------------------------
Function cmGetUnitCode(pUnit) Export
	If IsBlankString(pUnit) Then
		Return "---";
	Else
		vUnitRef = Catalogs.Units.FindByDescription(TrimR(pUnit), False);
		If ValueIsFilled(vUnitRef) Then
			Return TrimAll(vUnitRef.Code);
		Else
			Return "---";
		EndIf;
	EndIf;
EndFunction // cmGetUnitCode

// -----------------------------------------------------------------------------
// Returns chart object height for the report
// -----------------------------------------------------------------------------
Function cmGetReportChartHeight(pRepObj) Export
	If pRepObj.ReportChartType = ChartType.Pie Or 
	   pRepObj.ReportChartType = ChartType.Pie3D Or 
	   pRepObj.ReportChartType = ChartType.Honeycomb Or 
	   pRepObj.ReportChartType = ChartType.BarGraph Or 
	   pRepObj.ReportChartType = ChartType.CeilGraph Or 
	   pRepObj.ReportChartType = ChartType.StackedArea Or 
	   pRepObj.ReportChartType = ChartType.StackedBar Or 
	   pRepObj.ReportChartType = ChartType.StackedBar3D Or 
	   pRepObj.ReportChartType = ChartType.StackedColumn Or 
	   pRepObj.ReportChartType = ChartType.StackedColumn3D Or 
	   pRepObj.ReportChartType = ChartType.StackedLine Or 
	   pRepObj.ReportChartType = ChartType.ConcaveSurface Or 
	   pRepObj.ReportChartType = ChartType.ConvexSurface Or 
	   pRepObj.ReportChartType = ChartType.NormalizedArea Or 
	   pRepObj.ReportChartType = ChartType.NormalizedBar Or 
	   pRepObj.ReportChartType = ChartType.NormalizedBar3D Or 
	   pRepObj.ReportChartType = ChartType.NormalizedColumn Or 
	   pRepObj.ReportChartType = ChartType.NormalizedColumn3D Or 
	   pRepObj.ReportChartType = ChartType.RadarArea Or 
	   pRepObj.ReportChartType = ChartType.RadarLine Or 
	   pRepObj.ReportChartType = ChartType.RadarNormalizedArea Or 
	   pRepObj.ReportChartType = ChartType.RadarStackedArea Or 
	   pRepObj.ReportChartType = ChartType.RadarStackedLine Or 
	   pRepObj.ReportChartType = ChartType.ShadedSurface Or 
	   pRepObj.ReportChartType = ChartType.Surface Or 
	   pRepObj.ReportChartType = ChartType.Waterfall Or 
	   pRepObj.ReportChartType = ChartType.WireframeSurface Then
		Return 240;
	Else
		Return 110;
	EndIf;
EndFunction // cmGetReportChartHeight

// -----------------------------------------------------------------------------
// Returns chart object width for the report
// -----------------------------------------------------------------------------
Function cmGetReportChartWidth(pRepObj) Export
	If pRepObj.ReportPageOrientation = Enums.PageOrientations.Portrait Then
		Return 11;
	Else
		Return 17;
	EndIf;
EndFunction // cmGetReportChartWidth

// -----------------------------------------------------------------------------
// Description: Fills value table column headers with human readable names taken 
//              from the report template
// Parameters: Value table, Report object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillValueTableColumnTitles(pValTbl, pRepObj) Export
	// Get report template defined for the report
	vReportTemplate = pRepObj.GetTemplate("ReportTemplate");
	// Set column title
	For Each vColumn In pValTbl.Columns Do
		// Try to get column name overrides
		vColumnHeaderDescription = "";
		If pRepObj.ReportColumnOverrides.Count() > 0 Then
			vOverrideRow = Undefined;
			If pRepObj.ReportColumnOverrides.Columns.Count() > 0 Then
				vOverrideRow = pRepObj.ReportColumnOverrides.Find(vColumn.Name, "ColumnName");
			EndIf;
			If vOverrideRow <> Undefined Then
				Try
					If pRepObj.ReportColumnOverrides.Columns.Count() > 2 Then
						vColumnHeaderDescription = cmNStr(vOverrideRow.ColumnHeaderDescription);
					EndIf;
				Except
				EndTry;
			EndIf;
		EndIf;
		// Try to get report template range for the current column
		vReportAttrRange = vReportTemplate.Areas.Find(vColumn.Name);
		If vReportAttrRange <> Undefined Then
			vReportAttrHeaderRange = vReportTemplate.Areas.Find(vColumn.Name+"Header");
			If vReportAttrHeaderRange <> Undefined Then
				// Set colum title text
				If Not IsBlankString(vColumnHeaderDescription) Then
					vColumn.Title = vColumnHeaderDescription;
				Else
					vColumn.Title = vReportAttrHeaderRange.Text;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // cmFillValueTableColumnTitles

// -----------------------------------------------------------------------------
// Description: Adds chart object to the report spreadsheet 
// Parameters: Report spreadsheet, Report object
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmAddReportChart(pSpreadsheet, pRepObj) Export
	// Insert chart area
	vRepHeaderHeight = 3;
	pSpreadsheet.InsertArea(pSpreadsheet.Area(vRepHeaderHeight, , vRepHeaderHeight), pSpreadsheet.Area(vRepHeaderHeight+1, , vRepHeaderHeight+1), SpreadsheetDocumentShiftType.Vertical);
	vRepHeaderHeight = vRepHeaderHeight + 1;
	pSpreadsheet.Area(vRepHeaderHeight, , vRepHeaderHeight).Clear(True, True, True);
	pSpreadsheet.Area(vRepHeaderHeight, , vRepHeaderHeight).RowHeight = 5;
	pSpreadsheet.InsertArea(pSpreadsheet.Area(vRepHeaderHeight, , vRepHeaderHeight), pSpreadsheet.Area(vRepHeaderHeight+1, , vRepHeaderHeight+1), SpreadsheetDocumentShiftType.Vertical);
	vRepHeaderHeight = vRepHeaderHeight + 1;
	pSpreadsheet.Area(vRepHeaderHeight, , vRepHeaderHeight).Clear(True, True, True);
	pSpreadsheet.Area(vRepHeaderHeight, , vRepHeaderHeight).RowHeight = cmGetReportChartHeight(pRepObj);
	pSpreadsheet.InsertArea(pSpreadsheet.Area(vRepHeaderHeight, , vRepHeaderHeight), pSpreadsheet.Area(vRepHeaderHeight+1, , vRepHeaderHeight+1), SpreadsheetDocumentShiftType.Vertical);
	pSpreadsheet.Area(vRepHeaderHeight+1, , vRepHeaderHeight+1).Clear(True, True, True);
	pSpreadsheet.Area(vRepHeaderHeight+1, , vRepHeaderHeight+1).RowHeight = 5;
	
	// Add chart drawing object to the spreadsheet
	vDrawing = pSpreadsheet.Drawings.Add(SpreadsheetDocumentDrawingType.Chart);
	vDrawing.Name = "ReportChart";
	vDrawing.Place(pSpreadsheet.Area(vRepHeaderHeight, 2, vRepHeaderHeight, cmGetReportChartWidth(pRepObj)));
	vDrawing.LineColor = StyleColors.BorderColor;
	vChart = vDrawing.Object;
	
	// Disable chart
	vChart.RefreshEnabled = False;
	// Fill chart parameters
	vChart.SeriesInRows = False;
	vChart.TitleArea.Text = pRepObj.ReportBuilder.HeaderText;
	vChart.ValueLabelFormat = "ND=17; NFD=2; NZ="; 
	vChart.LabelType = ChartLabelType.Value; 
	If pRepObj.ReportChartType <> Undefined Then
		vChart.ChartType = pRepObj.ReportChartType;
	EndIf;
	vChart.PlotArea.ShowScaleValueLines = False;
	// Fill list of chart data source columns		
	vDimensionColumns = "";
	If pRepObj.ReportBuilder.ColumnDimensions.Count() > 0 Then
		vDimensionColumns = pRepObj.ReportBuilder.ColumnDimensions.Get(0).Name;
	ElsIf pRepObj.ReportBuilder.RowDimensions.Count() > 0 Then
		vDimensionColumns = pRepObj.ReportBuilder.RowDimensions.Get(0).Name;
	EndIf;
	If IsBlankString(vDimensionColumns) Then
		vDimensionColumns = pRepObj.ReportBuilder.SelectedFields.Get(0).Name;
	EndIf;
	vDataSourceColumns = vDimensionColumns;
	For Each vFld In pRepObj.ReportBuilder.SelectedFields Do
		If pRepObj.pmIsResource(vFld.Name) Then
			If pRepObj.ReportColumnOverrides.Columns.Count() > 4 Then
				vOverrideRow = Undefined;
				If pRepObj.ReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
					vOverrideRow = pRepObj.ReportColumnOverrides.Find(vFld.DataPath, "ColumnDataPath");
				EndIf;
				If vOverrideRow = Undefined Then
					If pRepObj.ReportColumnOverrides.Columns.Find("ColumnName") <> Undefined Then
						vOverrideRow = pRepObj.ReportColumnOverrides.Find(vFld.Name, "ColumnName");
					EndIf;
				EndIf;
				If vOverrideRow <> Undefined Then
					If vOverrideRow.ShowInChart Then
						vDataSourceColumns = vDataSourceColumns + ", " + vFld.Name;
					EndIf;
				EndIf;
			Else
				vDataSourceColumns = vDataSourceColumns + ", " + vFld.Name;
			EndIf;
		EndIf;
	EndDo;
	// Get chart data source value table from the report builder data source
	vRBDataSource = pRepObj.ReportBuilder.Result.Unload();
	vRBDataSource = vRBDataSource.CopyColumns(vDataSourceColumns);
	If pRepObj.ReportBuilder.RowDimensions.Count() = 0 And pRepObj.ReportBuilder.ColumnDimensions.Count() = 0 Then
		vRBQryRes = pRepObj.ReportBuilder.Result.Select(QueryResultIteration.Linear);
	ElsIf pRepObj.ReportBuilder.RowDimensions.Count() > 0 And pRepObj.ReportBuilder.ColumnDimensions.Count() > 0 Then
		vRBQryRes = pRepObj.ReportBuilder.Result.Select(QueryResultIteration.ByGroups, vDimensionColumns);
	Else
		vRBQryRes = pRepObj.ReportBuilder.Result.Select(QueryResultIteration.ByGroups, vDimensionColumns);
	EndIf;
	While vRBQryRes.Next() Do
		vRBDataSourceRow = vRBDataSource.Add();
		FillPropertyValues(vRBDataSourceRow, vRBQryRes);
	EndDo;
	vChartDataSource = vRBDataSource.Copy(, vDataSourceColumns);
	// Fill chart data source columns titles from the report template column headers
	cmFillValueTableColumnTitles(vChartDataSource, pRepObj);
	// Connect data source to the chart
	If Not IsBlankString(vDimensionColumns) Then
		If pRepObj.ReportBuilder.RowDimensions.Count() = 0 Then
			// Delete report totals row
			If vChartDataSource.Count() > 0 Then
				vChartDataSource.Delete(vChartDataSource.Count() - 1);
			EndIf;
		EndIf;
		vChart.DataSource = vChartDataSource;
	EndIf;
	// Draw chart
	vChart.RefreshEnabled = True;
	
	// Set spreadsheet output parameters
	pSpreadsheet.ReadOnly = False;
	pSpreadsheet.ShowHeaders = False;
	pSpreadsheet.ShowGrid = False;
	pSpreadsheet.FixedTop = vRepHeaderHeight + 2;
EndProcedure // cmAddReportChart

// -----------------------------------------------------------------------------
Function cmGetFMSRecord(pText, pIsCode = False, pType = "FMSListRU", pTop = 2) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP " + Format(pTop, "NFD=0; NG=") + "  
	|	CodesFMS.Code AS Code,
	|	CodesFMS.ID AS ID,
	|	CodesFMS.Description AS Description
	|FROM
	|	InformationRegister.CodesFMS AS CodesFMS
	|WHERE
	|	CodesFMS.Type = &qType
	|	AND CodesFMS.Code LIKE &qCode
	|
	|ORDER BY
	|	Code";
	If Not pIsCode Then
		vQry.Text = StrReplace(vQry.Text,"AND CodesFMS.Code LIKE &qCode","AND CodesFMS.Description LIKE &qDescription");
		vQry.SetParameter("qDescription", "%"+TrimAll(pText) + "%");
	EndIf;
	vQry.SetParameter("qCode", TrimAll(pText) + "%");
	vQry.SetParameter("qType", pType);
	Return vQry.Execute();
EndFunction // cmGetFMSRecord 

// -----------------------------------------------------------------------------
Function cmGetIssuedByRecord(pText, pIsCode = False, pTop = 2) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP " + Format(pTop, "NFD=0; NG=") + "  
	|	Clients.IdentityDocumentUnitCode AS Code,
	|	Clients.IdentityDocumentIssuedBy AS Description
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder
	|	AND (Clients.IdentityDocumentIssuedBy LIKE &qIssuedBy
	|			OR &qIsCode
	|				AND Clients.IdentityDocumentUnitCode = &qUnitCode)
	|GROUP BY
	|	Clients.IdentityDocumentUnitCode,
	|	Clients.IdentityDocumentIssuedBy
	|ORDER BY
	|	Description";
	vQry.SetParameter("qIssuedBy", TrimAll(pText) + "%");
	vQry.SetParameter("qUnitCode", TrimAll(pText));
	vQry.SetParameter("qIsCode", pIsCode);
	Return vQry.Execute();
EndFunction // cmGetIssuedByRecord 

// -----------------------------------------------------------------------------
// Description: Returns if program is in simple mode
// Parameters: None
// Return value: Boolean
// -----------------------------------------------------------------------------
Function cmIsSimpleMode() Export
	vSimpleMode = Constants.SimpleMode.Get();
	If vSimpleMode Then
		Return vSimpleMode;
	Else
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			vPGRef = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
			If ValueIsFilled(vPGRef) Then
				Return vPGRef.SimpleMode;
			Else
				Return False;
			EndIf;
		Else
			Return False;
		EndIf;
	EndIf;
EndFunction // cmIsSimpleMode

// -----------------------------------------------------------------------------
// Get data from dadata service
//
// Parameters:
//  pText - String - Data that has to be processed by service: part of address, company name and e.t.c.
//  pToken - String - Http service access token
//  pQueryType - String - Type of data passed
//
// Returns:
//   Array   
// -----------------------------------------------------------------------------
Function cmGetDadataArray(pText, pToken, pQueryType = "party") Export
	vList = New  Array;
	
	vHTTPRequest = New HTTPRequest();
	vHTTPRequest.ResourceAddress = "/api/v2/suggest/" + pQueryType;
	
	vHTTPRequest.Headers.Insert("Content-Type", "application/xml");
	vHTTPRequest.Headers.Insert("Accept", "application/xml");
	vHTTPRequest.Headers.Insert("Authorization", "Token "+pToken);  
	vHTTPRequest.SetBodyFromString("<req><query>" + pText + "</query></req>"); 
	
	vHTTPConnection = New HTTPConnection("dadata.ru", , , , , , New OpenSSLSecureConnection);
	vHTTPResponse = vHTTPConnection.Post(vHTTPRequest);
	vBody = vHTTPResponse.GetBodyAsString();
	
	If vHTTPResponse.StatusCode = 200 Then
		vXMLReader = New XMLReader;
		vXMLReader.SetString(vBody);
		vXMLReader.MoveToContent();
		
		vXDTODataObject = XDTOFactory.ReadXML(vXMLReader);
		
		vXMLReader.Close();
		If vXDTODataObject.Properties().Get("suggestions") <> Undefined Then
			If TypeOf(vXDTODataObject.suggestions) = Type("XDTOList") Then
				For Each  vKey In vXDTODataObject.suggestions Do
					If pQueryType = "party" Then
						GetCustomersDadataArr(vList, vKey);
					ElsIf   pQueryType = "address" Then
						GetAddresDadataArr(vList, vKey);
					ElsIf   pQueryType = "fio" Then
						GetFIODadataArr(vList, vKey);
					EndIf;	
				EndDo;
			ElsIf TypeOf(vXDTODataObject.suggestions) = Type("XDTODataObject") Then
				If pQueryType = "party" Then
					GetCustomersDadataArr(vList, vXDTODataObject.suggestions);
				ElsIf   pQueryType = "address" Then
					GetAddresDadataArr(vList, vXDTODataObject.suggestions);
				ElsIf   pQueryType = "fio" Then
					GetFIODadataArr(vList, vXDTODataObject.suggestions);
				EndIf;	
			EndIf;
		EndIf; 
	EndIf;
	Return vList;
EndFunction // cmGetDadataArray

// -----------------------------------------------------------------------------
// <Get data from dadata servise>
//
// Parameters:
//  pText  - String - Search text
//  pHotel   - Catalog.Hotels - Ref on hotel
//  pQueryType  - string	 -  Query type: "address", "party", "bank"
//
// Returns:
//   Array - Array - list rows
Function cmGetDadataArrayApiV4(pText, pHotel = Undefined , pQueryType="address") Export
	vList = New  Array;
	If pHotel = Undefined Or pHotel = PredefinedValue("Catalog.Hotels.EmptyRef") Then 
		pHotel = SessionParameters.CurrentHotel;
	EndIf;	
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.DADATA, pHotel);
	If ValueIsFilled(vInteraction) And Not IsBlankString(vInteraction.OAuth_AccessToken) Then
		vDadataToken = vInteraction.OAuth_AccessToken;
		vIntMapping = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction,"Dadata");
		If vIntMapping.Count() > 0 Then 
			vData = vIntMapping[0];
			// Bild post query 
			If pQueryType = "address" And vData.FillAddress = True 
				Or pQueryType = "bank" And vData.FillBank = True 
				Or pQueryType = "party" And vData.FillCustomers = True Then  
				vJSON = "";				
				Try
					vHTTPRequest = New HTTPRequest();
					vHTTPRequest.ResourceAddress = "/suggestions/api/4_1/rs/suggest/" + pQueryType;
					
					vHTTPRequest.Headers.Insert("Content-Type", "application/json");
					vHTTPRequest.Headers.Insert("Accept", "application/json");
					vHTTPRequest.Headers.Insert("Authorization", "Token " + vDadataToken);
					vQuery = New Structure("query", pText);
					
					vJSONSettings	= New JSONWriterSettings(JSONLineBreak.None);
					vJSONWriter 	= New JSONWriter;
					vJSONWriter.SetString(vJSONSettings);
					WriteJSON(vJSONWriter,vQuery);
					vJSON = vJSONWriter.Close();
					
					vHTTPRequest.SetBodyFromString(vJSON);
					
					vHTTPConnection = New HTTPConnection("suggestions.dadata.ru", , , , , , New OpenSSLSecureConnection);
					vHTTPResponse = vHTTPConnection.Post(vHTTPRequest);
					vBody = vHTTPResponse.GetBodyAsString();
					
					If vHTTPResponse.StatusCode = 200 Then
						vRs = Catalogs.DataConvertationRules.JSONtoStructure(vBody); 
						If TypeOf(vRs) = Type("Structure") And vRs.Property("suggestions") 
							And TypeOf(vRs.suggestions) = Type("Array") And vRs.suggestions.Count() > 0 Then
							vList = vRs.suggestions;
						EndIf;
					Else
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, pQueryType, Enums.ExternalSystemEventTypes.Error, vJSON, vBody, "Query error");
					EndIf;
				Except
					vErrInfo = ErrorInfo();
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, pQueryType, Enums.ExternalSystemEventTypes.Error, vJSON, DetailErrorDescription(vErrInfo), BriefErrorDescription(vErrInfo));
				EndTry;	
			EndIf;
		EndIf;
	EndIf;
	Return vList;

EndFunction	

// -----------------------------------------------------------------------------
// Get data from dadata
// Parameters: 
//  pText		 - string	 -  Search text 
//  pQueryType	 - string	 -  Query type: "address", "party", "bank", "email" 
//  pHotel		 - Catalog.Hotels - Ref on hotel
// 
// Returns:
//  ValueList  - ValueList - list rows
Function cmGetDataFromDadata(pText, pQueryType = "address", pHotel = Undefined) Export
	vList = New ValueList;
	// Call post query
	vRs = cmGetDadataArrayApiV4(TrimAll(pText), pHotel, pQueryType);

	// Fill result
	If pQueryType = "address" Then
		For Each vRow In vRs Do
			vData = vRow.data;
			vAddressArr = New Array;
			
			vCountry = "";
			If Not vData.country = Undefined And Not IsBlankString(vData.country) Then
				vCountry = vData.country;
			EndIf;
			vAddressArr.Add(vCountry);
			
			vPostal_code = "";
			If Not vData.postal_code = Undefined And Not IsBlankString(vData.postal_code) Then
				vPostal_code = vData.postal_code;
			EndIf;
			vAddressArr.Add(vPostal_code);

			vRegion = "";
			If vData.region = vData.city And Not vData.city = Undefined And Not IsBlankString(vData.city) Then
				vRegion = StrTemplate("%1 %2", vData.region, vData.region_type);
			ElsIf Not vData.region_with_type = Undefined And Not IsBlankString(vData.region_with_type) Then
				vRegion = vData.region_with_type;
			EndIf;
			vAddressArr.Add(vRegion);

			vArea = "";
			If Not vData.area_with_type = Undefined And Not IsBlankString(vData.area_with_type) Then
				vArea = vData.area_with_type;
			EndIf;
			vAddressArr.Add(vArea);

			vCity = "";
			If Not vData.settlement_with_type = Undefined And Not IsBlankString(vData.settlement_with_type) Then
				vCity = StrTemplate("%1 %2", vData.settlement, vData.settlement_type_full);
			ElsIf Not vData.city = Undefined And Not IsBlankString(vData.city) Then
				vCity = StrTemplate("%1 %2", vData.city, vData.city_type);
			EndIf;
			vAddressArr.Add(vCity);
			
			vStreet = "";
			If Not vData.street = Undefined And Not IsBlankString(vData.street) Then
				vStreet = vData.street + " " + vData.street_type;
			EndIf;
			vAddressArr.Add(vStreet);
			
			vHouse = "";
			If Not vData.house = Undefined And Not IsBlankString(vData.house) Then
				vHouse = vData.house;
			EndIf;
			
			If Not vData.block = Undefined And Not IsBlankString(vData.block) Then
				vHouse = vHouse + " "+ vData.block_type + vData.block;
			EndIf;	
			vAddressArr.Add(TrimAll(vHouse));
			
			vAddressArr.Add(vData.flat);
			
			vAddress = TrimAll(StrConcat(vAddressArr, ", ")); 
			While StrEndsWith(vAddress,",") Or StrEndsWith(vAddress," ") And StrLen(vAddress) > 0 Do
				vAddress = Left(vAddress, StrLen(vAddress)-1);
			EndDo;	             
			vDataRow = vRow.data;
			vDataRow.Insert("Address", vAddress);  
			StreetFiasId = vData.street_fias_id;
			If IsBlankString(StreetFiasId) Then
				StreetFiasId = vData.settlement_fias_id;	
			EndIf;	  
			vDataRow.Insert("StreetFiasId", StreetFiasId);
			vList.Add(vDataRow, vRow.unrestricted_value);
		EndDo;
	ElsIf pQueryType = "party" Then
		For Each vRow In vRs Do
			vList.Add(vRow.data, vRow.unrestricted_value);
		EndDo;
	ElsIf pQueryType = "bank" Then
		For Each vRow In vRs Do
			vList.Add(vRow.data, vRow.unrestricted_value);
		EndDo;
	EndIf;	
	
	Return vList;
EndFunction	

// -----------------------------------------------------------------------------
//  Transliterate string from russian to english or from english to russian
//
// Parameters:
//  pStr - String	 - String for transliterate
// 
// Returns:
//  String - Transliterate string
//
Function cmTransliterate(Val pStr) Export
	vStr = TrimAll(pStr);
	vUpperStr = Upper(vStr);
	// Get string current language
	vIsInRussian = False;
	vRuABC = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЫЬЪЭЮЯ";
	For vInd = 1 To StrLen(vRuABC) Do
		vC = Mid(vRuABC, vInd, 1);
		If StrFind(vUpperStr, vC) > 0 Then
			vIsInRussian = True;
			Break;
		EndIf;
	EndDo;
	If vIsInRussian Then
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
		vStr = StrReplace(vStr, "Ж", "GH");
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
		vStr = StrReplace(vStr, "Ч", "CH");
		vStr = StrReplace(vStr, "ч", "ch");
		vStr = StrReplace(vStr, "Ш", "SH");
		vStr = StrReplace(vStr, "ш", "sh");
		vStr = StrReplace(vStr, "Щ", "SCH");
		vStr = StrReplace(vStr, "щ", "sch");
		vStr = StrReplace(vStr, "Ь", "");
		vStr = StrReplace(vStr, "ь", "");
		vStr = StrReplace(vStr, "Ы", "YI");
		vStr = StrReplace(vStr, "ы", "yi");
		vStr = StrReplace(vStr, "Ъ", "");
		vStr = StrReplace(vStr, "ъ", "");
		vStr = StrReplace(vStr, "Э", "E");
		vStr = StrReplace(vStr, "э", "e");
		vStr = StrReplace(vStr, "Ю", "YU");
		vStr = StrReplace(vStr, "ю", "yu");
		vStr = StrReplace(vStr, "Я", "YA");
		vStr = StrReplace(vStr, "я", "ya");
	Else
		vStr = StrReplace(vStr, "Ya", "Я");
		vStr = StrReplace(vStr, "ya", "я");
		vStr = StrReplace(vStr, "A", "А");
		vStr = StrReplace(vStr, "a", "а");
		vStr = StrReplace(vStr, "B", "Б");
		vStr = StrReplace(vStr, "b", "б");
		vStr = StrReplace(vStr, "Sch", "Щ");
		vStr = StrReplace(vStr, "sch", "щ");
		vStr = StrReplace(vStr, "Sh", "Ш");
		vStr = StrReplace(vStr, "sh", "ш");
		vStr = StrReplace(vStr, "Ch", "Ч");
		vStr = StrReplace(vStr, "ch", "ч");
		vStr = StrReplace(vStr, "Zh", "Ж");
		vStr = StrReplace(vStr, "zh", "ж");
		vStr = StrReplace(vStr, "C", "К");
		vStr = StrReplace(vStr, "c", "к");
		vStr = StrReplace(vStr, "D", "Д");
		vStr = StrReplace(vStr, "d", "д");
		vStr = StrReplace(vStr, "E", "Е");
		vStr = StrReplace(vStr, "e", "е");
		vStr = StrReplace(vStr, "F", "Ф");
		vStr = StrReplace(vStr, "f", "ф");
		vStr = StrReplace(vStr, "G", "Г");
		vStr = StrReplace(vStr, "g", "г");
		vStr = StrReplace(vStr, "H", "Х");
		vStr = StrReplace(vStr, "h", "х");
		vStr = StrReplace(vStr, "I", "И");
		vStr = StrReplace(vStr, "i", "и");
		vStr = StrReplace(vStr, "J", "Ж");
		vStr = StrReplace(vStr, "j", "ж");
		vStr = StrReplace(vStr, "K", "К");
		vStr = StrReplace(vStr, "k", "к");
		vStr = StrReplace(vStr, "L", "Л");
		vStr = StrReplace(vStr, "l", "л");
		vStr = StrReplace(vStr, "M", "М");
		vStr = StrReplace(vStr, "m", "м");
		vStr = StrReplace(vStr, "N", "Н");
		vStr = StrReplace(vStr, "n", "н");
		vStr = StrReplace(vStr, "O", "О");
		vStr = StrReplace(vStr, "o", "о");
		vStr = StrReplace(vStr, "P", "П");
		vStr = StrReplace(vStr, "p", "п");
		vStr = StrReplace(vStr, "Q", "К");
		vStr = StrReplace(vStr, "q", "к");
		vStr = StrReplace(vStr, "R", "Р");
		vStr = StrReplace(vStr, "r", "р");
		vStr = StrReplace(vStr, "S", "С");
		vStr = StrReplace(vStr, "s", "с");
		vStr = StrReplace(vStr, "T", "Т");
		vStr = StrReplace(vStr, "t", "т");
		vStr = StrReplace(vStr, "Yu", "Ю");
		vStr = StrReplace(vStr, "yu", "ю");
		vStr = StrReplace(vStr, "U", "У");
		vStr = StrReplace(vStr, "u", "у");
		vStr = StrReplace(vStr, "V", "В");
		vStr = StrReplace(vStr, "v", "в");
		vStr = StrReplace(vStr, "W", "В");
		vStr = StrReplace(vStr, "w", "в");
		vStr = StrReplace(vStr, "X", "Кс");
		vStr = StrReplace(vStr, "x", "кс");
		vStr = StrReplace(vStr, "Y", "Й");
		vStr = StrReplace(vStr, "y", "й");
		vStr = StrReplace(vStr, "Z", "З");
		vStr = StrReplace(vStr, "z", "з");
	EndIf;
	Return vStr;
EndFunction // cmTransliterate

// -----------------------------------------------------------------------------
// Get last symbol position from string
// -----------------------------------------------------------------------------
Function cmGetLastSymbolPosition(Val pString, Val pSymbol) Export
	vSymbolPos = StrLen(pString);
	While vSymbolPos >= 1 Do
		If Mid(pString, vSymbolPos, 1) = pSymbol Then
			Return vSymbolPos; 
		EndIf;
		vSymbolPos = vSymbolPos - 1;	
	EndDo;
	Return 0;
EndFunction // cmGetLastSymbolPosition

// -----------------------------------------------------------------------------
// Send request to payment system
// -----------------------------------------------------------------------------
Function cmSendRequestToPaymentUrl(pCommand, pTransId, pAmount, pPaymentMethod, rErrorMessage = "") Export
	vPaymentUrlTemplate = pPaymentMethod.PaymentUrlTemplate;
	If ValueIsFilled(vPaymentUrlTemplate) Then
		vUseSSL = False;
		If Left(vPaymentUrlTemplate, 7) = "http://" Then
			vPaymentUrlTemplate = Right(vPaymentUrlTemplate, StrLen(vPaymentUrlTemplate)-7);
		ElsIf Left(vPaymentUrlTemplate, 8) = "https://" Then
			vUseSSL = True;
			vPaymentUrlTemplate = Right(vPaymentUrlTemplate, StrLen(vPaymentUrlTemplate)-8);
		EndIf;
		If Right(vPaymentUrlTemplate, 1) = "/" Then
			vPaymentUrlTemplate = Left(vPaymentUrlTemplate, StrLen(vPaymentUrlTemplate)-1);
		EndIf;
		vSymbPos = cmGetLastSymbolPosition(vPaymentUrlTemplate, "/");
		vBasePaymentUrl = Left(vPaymentUrlTemplate, vSymbPos - 1);
		vResource = Right(vPaymentUrlTemplate, StrLen(vPaymentUrlTemplate) - vSymbPos);
		Try
			vProxy = cmGetInternetProxy(SessionParameters.CurrentWorkstation.InternetConnectionSettings, False, vBasePaymentUrl);
			vHTTP = Undefined;
			If vProxy <> Undefined Then
			    vHTTP = New HTTPConnection(vBasePaymentUrl,,,,vProxy,,?(vUseSSL, New OpenSSLSecureConnection(), Undefined));
			Else
			    vHTTP = New HTTPConnection(vBasePaymentUrl,,,,,,?(vUseSSL, New OpenSSLSecureConnection(), Undefined));
			EndIf;
		Except
			rErrorMessage = NStr("ru='Ошибка при создании HTTP-соединения!'; en='Error creating HTTP connection'; de='Error creating HTTP connection'");
			WriteLogEvent(NStr("en='Send request to payment system';ru='Отправить запрос в платежную систему';de='Anfrage senden an Zahlungssystem'"), EventLogLevel.Error, , , 
				NStr("ru='ID транзакции: '; en='Transaction ID: '; de='Transaction ID: '") + TrimAll(pTransId) + Chars.LF +
				NStr("ru='Команда: '; en='Command: '; de='Command: '") + ?(pCommand = "r", NStr("ru='Отмена преавторизации';en='Cancel preauth.';de='Cancel preauth.'"), ?(pCommand = "t", NStr("ru='Расчет'; en='Computation'; de='Computation'"), ?(pCommand = "k", NStr("ru='Возврат'; en='Return'; de='Return'"), ""))) + Chars.LF +
				NStr("ru='Сумма: '; en='Amount: '; de='Amount: '") + pAmount + Chars.LF +
				NStr("ru='Ошибка: '; en='Error: '; de='Error: '") + TrimAll(rErrorMessage));
			Return False;
		EndTry;
		vTransId = TrimAll(pTransId);
		vAmount = Format(pAmount*100, "NFD=; NGS=; NG=");

		If ValueIsFilled(vTransId) And pAmount > 0 Then
			Try
				vResource = StrReplace(vResource, "#command", pCommand);
				vResource = StrReplace(vResource, "#payment_id", cmEncodeURL(vTransId, False));
				vResource = StrReplace(vResource, "#amount", vAmount);
				vResultFileName = GetTempFileName();
				vResponse = vHTTP.Post(New HTTPRequest(vResource), vResultFileName);
				vResponseTextDocument = New TextDocument();
				vResponseTextDocument.Read(vResultFileName, TextEncoding.UTF8);
				vResponseText = vResponseTextDocument.GetText();
				DeleteFiles(vResultFileName);
				WriteLogEvent(NStr("en='Send request to payment system';ru='Отправить запрос в платежную систему';de='Anfrage senden an Zahlungssystem'"), EventLogLevel.Information, , , 
					NStr("ru='ID транзакции: '; en='Transaction ID: '; de='Transaction ID: '") + TrimAll(pTransId) + Chars.LF +
					NStr("ru='Команда: '; en='Command: '; de='Command: '") + ?(pCommand = "r", NStr("ru='Отмена преавторизации';en='Cancel preauth.';de='Cancel preauth.'"), ?(pCommand = "t", NStr("ru='Расчет'; en='Computation'; de='Computation'"), ?(pCommand = "k", NStr("ru='Возврат'; en='Return'; de='Return'"), ""))) + Chars.LF +
					NStr("ru='Сумма: '; en='Amount: '; de='Amount: '") + pAmount + Chars.LF +
					NStr("ru='Результат: '; en='Result: '; de='Result: '") + vResponseText + Chars.LF +
					NStr("ru='Ошибка: '; en='Error: '; de='Error: '") + "");
			Except
				rErrorMessage = NStr("ru='Ошибка при отправке запроса'; en='Error sending POST request'; de='Error sending POST request'");
				WriteLogEvent(NStr("en='Send request to payment system';ru='Отправить запрос в платежную систему';de='Anfrage senden an Zahlungssystem'"), EventLogLevel.Error, , , 
					NStr("ru='ID транзакции: '; en='Transaction ID: '; de='Transaction ID: '") + TrimAll(pTransId) + Chars.LF +
					NStr("ru='Команда: '; en='Command: '; de='Command: '") + ?(pCommand = "r", NStr("ru='Отмена преавторизации';en='Cancel preauth.';de='Cancel preauth.'"), ?(pCommand = "t", NStr("ru='Расчет'; en='Computation'; de='Computation'"), ?(pCommand = "k", NStr("ru='Возврат'; en='Return'; de='Return'"), ""))) + Chars.LF +
					NStr("ru='Сумма: '; en='Amount: '; de='Amount: '") + pAmount + Chars.LF +
					NStr("ru='Ошибка: '; en='Error: '; de='Error: '") + TrimAll(rErrorMessage));
				Return False;
			EndTry;
		Else
			rErrorMessage = NStr("ru='Не передан ID транзакции, либо нулевая сумма'; en='We did not receive a transaction ID, or received a zero-sum'; de='We did not receive a transaction ID, or received a zero-sum'");
			WriteLogEvent(NStr("en='Send request to payment system';ru='Отправить запрос в платежную систему';de='Anfrage senden an Zahlungssystem'"), EventLogLevel.Error, , , 
				NStr("ru='ID транзакции: '; en='Transaction ID: '; de='Transaction ID: '") + TrimAll(pTransId) + Chars.LF +
				NStr("ru='Команда: '; en='Command: '; de='Command: '") + ?(pCommand = "r", NStr("ru='Отмена преавторизации';en='Cancel preauth.';de='Cancel preauth.'"), ?(pCommand = "t", NStr("ru='Расчет'; en='Computation'; de='Computation'"), ?(pCommand = "k", NStr("ru='Возврат'; en='Return'; de='Return'"), ""))) + Chars.LF +
				NStr("ru='Сумма: '; en='Amount: '; de='Amount: '") + pAmount + Chars.LF +
				NStr("ru='Ошибка: '; en='Error: '; de='Error: '") + TrimAll(rErrorMessage));
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction // cmSendRequestToPaymentUrl

// -----------------------------------------------------------------------------
// Returns value table with list of fields used in report
// -----------------------------------------------------------------------------
Function cmGetReportUsedFields(pReportBuilder) Export
	vSelectedFields = New ValueTable();
	vSelectedFields.Columns.Add("DataPath", cmGetStringTypeDescription());
	// Selected fields
	For Each vFieldItem In pReportBuilder.SelectedFields Do
		If vSelectedFields.Find(vFieldItem.DataPath, "DataPath") = Undefined Then
			vSelectedFieldsRow = vSelectedFields.Add();
			vSelectedFieldsRow.DataPath = vFieldItem.DataPath;
		EndIf;
	EndDo;
	// Filter
	For Each vFilterItem In pReportBuilder.Filter Do
		If vSelectedFields.Find(vFilterItem.DataPath, "DataPath") = Undefined Then
			vSelectedFieldsRow = vSelectedFields.Add();
			vSelectedFieldsRow.DataPath = vFilterItem.DataPath;
		EndIf;
	EndDo;
	// Row dimensions
	For Each vRowDimItem In pReportBuilder.RowDimensions Do
		If vSelectedFields.Find(vRowDimItem.DataPath, "DataPath") = Undefined Then
			vSelectedFieldsRow = vSelectedFields.Add();
			vSelectedFieldsRow.DataPath = vRowDimItem.DataPath;
		EndIf;
	EndDo;
	// Column dimensions
	For Each vColumnDimItem In pReportBuilder.ColumnDimensions Do
		If vSelectedFields.Find(vColumnDimItem.DataPath, "DataPath") = Undefined Then
			vSelectedFieldsRow = vSelectedFields.Add();
			vSelectedFieldsRow.DataPath = vColumnDimItem.DataPath;
		EndIf;
	EndDo;
	// Order
	For Each vOrderItem In pReportBuilder.Order Do
		If vSelectedFields.Find(vOrderItem.DataPath, "DataPath") = Undefined Then
			vSelectedFieldsRow = vSelectedFields.Add();
			vSelectedFieldsRow.DataPath = vOrderItem.DataPath;
		EndIf;
	EndDo;
	// Return
	Return vSelectedFields;
EndFunction // cmGetReportUsedFields

// -----------------------------------------------------------------------------
// Checks if input email is in the black list. Returns True if Yes and False if Not.
// -----------------------------------------------------------------------------
Function cmCheckIfEMailIsInBlackList(pEMail) Export
	vIsInBlackList = False;
	vBlackListStr = Constants.EMailsBlackListForOFD.Get();
	If Not IsBlankString(vBlackListStr) Then
		vArray = StrSplit(vBlackListStr, ",", False);
		For Each vArrayItem In vArray Do
			If StrFind(TrimAll(pEMail), TrimAll(vArrayItem)) > 0 Then
				vIsInBlackList = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	Return vIsInBlackList;
EndFunction // cmCheckIfEMailIsInBlackList

// -----------------------------------------------------------------------------
// Get Absolute Color.
// -----------------------------------------------------------------------------
Function cmGetAbsoluteColor(pColor)	Export
	If pColor.Type = ColorType.Absolute Then
		Return pColor;
	EndIf;
	vSD = New SpreadsheetDocument;
	vSD.Area("R1C1").BackColor = pColor;
	vTF = GetTempFileName("mxl");
	vSD.Write(vTF, SpreadsheetDocumentFileType.MXL7);
	vSD.Read(vTF);	
	vColor = vSD.Area("R1C1").BackColor;
	vSD = Undefined;
	DeleteFiles(vTF);	
	Return vColor;	
EndFunction

// -----------------------------------------------------------------------------
// Check request parameters
//
// Parameters:
//  pParamsType				 - 	 - QueryOptions or JSON
//  pParamsArray			 - 	 - String array of mandatory params to check and get value
//  pNonMandatoryParamsArray - 	 - String array of non mandatory params to get value
//  pRequest				 - 	 - HTTP Request
// 
// Returns:
//  Structure - With error param and all parameters from array. Error will be filled if one of paramters is missing in request.
//
Function cmCheckRequestParameters(pParamsType, pParamsArray, pNonMandatoryParamsArray = Undefined, pRequest, pReadToMap = False) Export
	If pReadToMap Then
		vResult = New Map;	
	Else
		vResult = New Structure;
	EndIf;
	vResult.Insert("Error", "");
	For Each vParam In pParamsArray Do
		vResult.Insert(vParam, Undefined);
	EndDo;
	
	If pNonMandatoryParamsArray <> Undefined Then
		For Each vParam In pNonMandatoryParamsArray Do
			vResult.Insert(vParam, Undefined);
		EndDo;
	EndIf;
	
	If pParamsType = "QueryOptions" Then
		For each vParam in pParamsArray Do
			vParamValue = pRequest.QueryOptions.Get(vParam);
			If NOT ValueIsFilled(vParamValue) Then 
				If pReadToMap Then
					vResult["Error"]	= vResult.Error + "Missing <" + vParam + "> parameter" + Chars.LF;	
				Else
					vResult.Error		= vResult.Error + "Missing <" + vParam + "> parameter" + Chars.LF;
				EndIf;
			Else
				vResult[vParam] = vParamValue; 	
			EndIf;
		EndDo;
		If pNonMandatoryParamsArray <> Undefined Then
			For Each vParam In pNonMandatoryParamsArray Do
				vParamValue = pRequest.QueryOptions.Get(vParam);
				If ValueIsFilled(vParamValue) Then
					vResult[vParam] = vParamValue; 	
				EndIf;
			EndDo;
		EndIf;
	ElsIf pParamsType = "JSON" Then
		vRequeuestBody 			= pRequest.GetBodyAsString();
		If vRequeuestBody <> Undefined And Not IsBlankString(vRequeuestBody) Then	
			vJSON = new JSONReader;
			vJSON.SetString(vRequeuestBody);
			
			vSuccess = True;
			Try
				vRequestParameters = ReadJSON(vJSON, pReadToMap);
			Except
				vSuccess 				= False;
				If pReadToMap Then
					vResult["Error"]	= "Cant read request body as JSON";	
				Else
					vResult.Error  		= "Cant read request body as JSON";
				EndIf;
			EndTry;
			
			If vSuccess Then
				If pReadToMap Then
					For Each vParam In pParamsArray Do
						If vRequestParameters[vParam] <> Undefined Then
							vResult[vParam]		= vRequestParameters[vParam];
						Else 
							vResult["Error"]	= vResult["Error"] + "Missing <" + vParam + "> parameter" + Chars.LF;
						EndIf;				
					EndDo;
					If pNonMandatoryParamsArray <> Undefined Then
						For Each vParam In pNonMandatoryParamsArray Do
							If vRequestParameters[vParam] <> Undefined Then
								vResult[vParam] = vRequestParameters[vParam];
							EndIf;				
						EndDo;
					EndIf; 
				Else
					For Each vParam In pParamsArray Do
						If vRequestParameters.Property(vParam) Then
							vResult[vParam] = vRequestParameters[vParam];
						Else 
							vResult.Error	= vResult.Error + "Missing <" + vParam + "> parameter" + Chars.LF;
						EndIf;				
					EndDo;
					If pNonMandatoryParamsArray <> Undefined Then
						For Each vParam In pNonMandatoryParamsArray Do
							If vRequestParameters.Property(vParam) Then
								vResult[vParam] = vRequestParameters[vParam];
							EndIf;				
						EndDo;
					EndIf;
				EndIf;
			EndIf;
		Else  
			If pReadToMap Then
				vResult["Error"]	= "Missing request body";
			Else
				vResult.Error 	= "Missing request body";
			EndIf;
		EndIf;
	Else        
		If pReadToMap Then
			vResult["Error"]	= "Wrong ParamsType";
		Else
			vResult.Error 		= "Wrong ParamsType";
		EndIf;
	EndIf;
	
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
Procedure cmSetFormItemsStandarts(rItems, pStandartsTemplate) Export
	vLastItem = Undefined;
	For i = 1 to pStandartsTemplate.TableHeight Do
		If vLastItem <> pStandartsTemplate.Area(i,1).Text Then
			vItem = rItems.Find(pStandartsTemplate.Area(i,1).Text);
		EndIf;
		If vItem <> Undefined  Then
			vValue = Undefined;
			Try  
				If pStandartsTemplate.Area(i,3).Text = "ChoiceHistoryOnInput" Then 
					vValue = ChoiceHistoryOnInput[pStandartsTemplate.Area(i,4).Text];
				ElsIf  pStandartsTemplate.Area(i,3).Text = "ChoiceButtonRepresentation" Then
					vValue = ChoiceButtonRepresentation[pStandartsTemplate.Area(i,4).Text];	
				Else		
					vTypeDescription 	= New TypeDescription(pStandartsTemplate.Area(i,3).Text);
					vValue 				= vTypeDescription.AdjustValue(pStandartsTemplate.Area(i,4).Text);
				EndIf;
				vItem[pStandartsTemplate.Area(i,2).Text] = vValue;			
			Except
				vError =  pStandartsTemplate.Area(i,2).Text + Chars.LF + ErrorDescription();
				tcCommonFunctionOnClientServer.UserMessage(vError);
			EndTry;
		EndIf;
		vLastItem = pStandartsTemplate.Area(i,1).Text;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
Function cmGetListOfReservationCustomFields() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationCustomAttributes.Ref AS Ref,
	|	ReservationCustomAttributes.IsFolder AS IsFolder,
	|	ReservationCustomAttributes.Code AS Code,
	|	ReservationCustomAttributes.Description AS Description,
	|	ReservationCustomAttributes.ValueType AS ValueType,
	|	ReservationCustomAttributes.Remarks AS Remarks,
	|	ReservationCustomAttributes.SortCode AS SortCode,
	|	ReservationCustomAttributes.ChoiceListValues AS ChoiceListValues,
	|	ReservationCustomAttributes.FillChoiceListFromHistory AS FillChoiceListFromHistory,
	|	ReservationCustomAttributes.ShowCaptionAboveTheField AS ShowCaptionAboveTheField,
	|	ReservationCustomAttributes.IsMultiline AS IsMultiline
	|FROM
	|	ChartOfCharacteristicTypes.ReservationCustomAttributes AS ReservationCustomAttributes
	|WHERE
	|	NOT ReservationCustomAttributes.DeletionMark
	|
	|ORDER BY
	|	ReservationCustomAttributes.SortCode";
	vCustFields = vQry.Execute().Unload();
	Return vCustFields;
EndFunction // cmGetListOfReservationCustomFields

// -----------------------------------------------------------------------------
Function cmGetReservationCustomFieldsValues(pDoc) Export
	vDoc = pDoc;
	If TypeOf(pDoc) = Type("DocumentRef.Accommodation") And 
	   ValueIsFilled(pDoc.Reservation) Then
		vDoc = pDoc.Reservation;
	EndIf;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationCustomAttributeValues.Characteristic AS Characteristic,
	|	ReservationCustomAttributeValues.Characteristic.Code AS CharacteristicCode,
	|	ReservationCustomAttributeValues.CharacteristicValue AS CharacteristicValue
	|FROM
	|	InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues
	|WHERE
	|	ReservationCustomAttributeValues.Owner = &qDoc
	|	AND NOT ReservationCustomAttributeValues.Characteristic.DeletionMark
	|
	|ORDER BY
	|	ReservationCustomAttributeValues.Characteristic.SortCode,
	|	ReservationCustomAttributeValues.Characteristic.Code";
	vQry.SetParameter("qDoc", vDoc);
	vCustFieldsValues = vQry.Execute().Unload();
	Return vCustFieldsValues;
EndFunction // cmGetListOfReservationCustomFields

// -----------------------------------------------------------------------------
Function cmGetReservationCustomFieldHistoryValuesList(pFieldName) Export
	vValues = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	ReservationCustomAttributeValues.CharacteristicValue
	|FROM
	|	InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues
	|WHERE
	|	ReservationCustomAttributeValues.Characteristic = &qCharacteristic
	|	AND ReservationCustomAttributeValues.CharacteristicValue <> """"
	|
	|ORDER BY
	|	ReservationCustomAttributeValues.CharacteristicValue";
	vQry.SetParameter("qCharacteristic", ChartsOfCharacteristicTypes.ReservationCustomAttributes.FindByCode(pFieldName));
	vFieldValues = vQry.Execute().Select();
	While vFieldValues.Next() Do
		vValues.Add(vFieldValues.CharacteristicValue);
	EndDo;
	Return vValues;
EndFunction // cmGetReservationCustomFieldHistoryValuesList

// -----------------------------------------------------------------------------
Function cmCheckRussianSocialSecurityNumber(pSNILS) Export
	vResult = True;
	Try
		If Not IsBlankString(pSNILS) Then
			vC1 = Number(Mid(pSNILS, 1, 1));
			vC2 = Number(Mid(pSNILS, 2, 1));
			vC3 = Number(Mid(pSNILS, 3, 1));
			vC4 = Number(Mid(pSNILS, 5, 1));
			vC5 = Number(Mid(pSNILS, 6, 1));
			vC6 = Number(Mid(pSNILS, 7, 1));
			vC7 = Number(Mid(pSNILS, 9, 1));
			vC8 = Number(Mid(pSNILS, 10, 1));
			vC9 = Number(Mid(pSNILS, 11, 1));
			vCC = Number(Mid(pSNILS, 13, 2));
			
			// Do check
			vCalcCC = -1;
			vSum = vC1 * 9 + vC2 * 8 + vC3 * 7 + vC4 * 6 + vC5 * 5 + vC6 * 4 + vC7 * 3 + vC8 * 2 + vC9 * 1;
			If vSum < 100 Then
				vCalcCC = vSum;
			ElsIf vSum = 100 Then
				vCalcCC = 0;
			ElsIf vSum = 101 Then
				vCalcCC = 0;
			Else
				vCalcCC = vSum - (Int(vSum/101)*101);
			EndIf;
			
			If vCalcCC <> vCC Then
				vResult = False;
			EndIf;
		EndIf;
	Except
		vResult = False;
	EndTry;
	Return vResult;
EndFunction // cmCheckRussianSocialSecurityNumber

// -----------------------------------------------------------------------------
Function cmConvertPDFtoJPG(pExtFile, pFileName) Export 
	// Converter path 
	Try
		vConverterPath = CommonDir();
		vFilesPath = TempFilesDir();
		If vConverterPath <> Undefined Then
			vPdfFile = New File(vFilesPath + pFileName);
			vPdfFileFullName = vPdfFile.FullName;
			pExtFile.Get().Write(vPdfFileFullName);
			vRetCode = 0;
			RunApp("""" + vConverterPath + "szp.exe"" " + """" + vConverterPath + "pdftopng.exe"" -q " + """" + vPdfFileFullName + """ " + vPdfFile.BaseName, vFilesPath, True, vRetCode);
			If (vRetCode = 0 Or vRetCode = 2) Then
				vPngFile = New File(vFilesPath + vPdfFile.BaseName + "-000001.png");
				If tcCommonFunctionOnClientServer.cmExists(vPngFile) Then
					vUsePNG = False;
					vPngFileFullName = vPngFile.FullName;
					vJpgFileFullName = vPngFile.Path + vPngFile.BaseName + ".jpg";
					vPngFileAddress = "";
					vPngPicture = New Picture(vPngFileFullName);
					Try 
						vPngToJpegPicture = New ProcessingPicture(vPngPicture);
						vPngToJpegPicture.SetFormat(PictureFormat.JPEG);
						vJpegPicture = vPngToJpegPicture.GetPicture();
					Except
						vUsePNG = True;
					EndTry;
					If vUsePNG Then
						vBinaryData = vPngFile.GetBinaryData();
						vPngFileAddress = PutToTempStorage(vBinaryData);
						Return vPngFileAddress;
					Else
						vBinaryData = vJpegPicture.GetBinaryData();
						vJpegFileAddress = PutToTempStorage(vBinaryData);
						Return vJpegFileAddress;
					EndIf;
				EndIf;
			Else
				If vPdfFile.Extension = ".pdf" Then
					Message = New UserMessage();
					Message.Text = cmNStr("en='Could not connect to the file converter to create a preview image! To turn on the converter, run 1C:Enterprise on behalf of the Operating system Administrator. Go to the “Workplaces” catalog, open the item form of any workplace and on the “External components” tab, click “Install a PDF file converter to PNG images.”';ru='Не удалось подключиться к конвертеру файлов для создания картинки предпросмотра! Чтобы включить конвертер, запустите 1С:Предприятие от имени Администратора операционной системы. Перейдите в справочник “Рабочие места”, откройте карточку любого рабочего места и на вкладке “Внешние компоненты” нажмите “Установить конвертер PDF-файлов в картинки формата PNG”.';de='Es konnte keine Verbindung zum Dateikonverter hergestellt werden, um ein Vorschaubild zu erstellen! Um den Konverter zu aktivieren, führen Sie 1C:Enterprise als Administrator des Betriebssystems aus. Öffnen Sie die Arbeitsbereichsübersicht, öffnen Sie die Arbeitsbereichskarte und klicken Sie auf der Registerkarte Externe Komponenten auf “PDF-Konverter in PNG-Bilder installieren”.'", SessionParameters.CurrentLanguage);
					Message.Message();
				EndIf;
			EndIf;
		EndIf;
	Except
		Return Undefined;
	EndTry;
	
	Return Undefined;
EndFunction // cmConvertPDFtoJPG

// -----------------------------------------------------------------------------
Function CommonDir()
	#If Not WebClient  And Not MobileClient Then
		vDir = Lower(BinDir());
		vSI = New SystemInfo();
		vAppVersion = Left(vSI.AppVersion, 3);
		If vAppVersion = "8.2" Then
			vCommonPos = Find(vDir, "\1cv82\");
			If vCommonPos > 0 Then
				vDir = Left(vDir, vCommonPos + 5) + "\common\";
			EndIf;
		Else
			vCommonPos = Find(vDir, "\1cv8\");
			If vCommonPos > 0 Then
				vDir = Left(vDir, vCommonPos + 4) + "\common\";
			EndIf;
		EndIf;
		Return vDir;
	#EndIf	
EndFunction // CommonDir

// --------------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - List objects
//
Function cmGetLastVisitedObjects() Export
	vQry = New Query;
	vQry.Text = "SELECT TOP 50
	            |	UAH.Object AS LastVisitedObject,
	            |	UAH.User AS User,
	            |	MAX(UAH.Period) AS Period
	            |FROM
	            |	InformationRegister.UserActionsHistory AS UAH
	            |WHERE
	            |	UAH.Hotel = &qHotel
	            |	AND UAH.User = &qUser
	            |
	            |GROUP BY
	            |	UAH.Object,
	            |	UAH.User
	            |
	            |ORDER BY
	            |	Period DESC"; 
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);  
	vQry.SetParameter("qUser", SessionParameters.CurrentUser);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetLastVisitedObjects

// -----------------------------------------------------------------------------
Function cmGetListPresentation(pList) Export
	vStr = "";
	For Each vListItem In pList Do
		vStr = vStr + ?(IsBlankString(vStr), "", ", ") + TrimAll(vListItem.Value);
	EndDo;
	Return vStr;
EndFunction // cmGetListPresentation

// --------------------------------------------------------------------------------
//
// Parameters:
//  pBotType - EnumRef.BotTypes	 - Bot type
// 
// Returns:
//  CommonModule - Result
//
Function cmGetChatBotAPI(pBotType) Export
	If pBotType = Enums.BotTypes.MAX Then
		vAPI = MAX;
	Else
		vAPI = Telegram;
	EndIf;
	Return vAPI;
EndFunction // GetChatBotAPI

#Region ReportThinClientForms

// -----------------------------------------------------------------------------
Function cmGetReportUserAtrributes(pRepObj) Export
	vAttributes = "";
	vListOfSystemReportAtributes = CachedCommonFunctions.cmGetListOfSystemReportAttributes();
	vRepMetadata = pRepObj.Metadata();
	For Each vRepAttribute In vRepMetadata.Attributes Do
		If vListOfSystemReportAtributes.FindByValue(vRepAttribute.Name) = Undefined Then
			vAttributes = vAttributes + ?(IsBlankString(vAttributes), "", ", ") + vRepAttribute.Name;
		EndIf;
	EndDo;
	Return vAttributes;
EndFunction // cmGetReportUserAtrributes

// -----------------------------------------------------------------------------
Function cmGetReportSystemAttributes(pRepObj) Export
	vAttributes = "";
	vReportAttributes = pRepObj.Metadata().Attributes;
	vListOfSystemReportAtributes = CachedCommonFunctions.cmGetListOfSystemReportAttributes();
	For Each vItem In vListOfSystemReportAtributes Do
		If vReportAttributes.Find(vItem.Value) <> Undefined Then
			vAttributes = vAttributes + ?(IsBlankString(vAttributes), "", ", ") + vItem.Value;
		EndIf;
	EndDo;
	Return vAttributes;
EndFunction // cmGetReportSystemAttributes

#EndRegion

#Region ReportSettingsForThinClient

// -----------------------------------------------------------------------------
Function cmGetReportParametersStructure(pRepObj, pFormUUID) Export
	vParams = New Structure("CloseOnChoice,
							|CloseOnOwnerClose,
							|ReadOnly,
							|Report, 
	                        |AvailableFieldsAddress, 
	                        |SelectedFieldsAddress, 
							|ReportColumnOverridesAddress,
							|FilterAddress,
							|RowDimensionsAddress,
							|ColumnDimensionsAddress,
							|OrderAddress,
							|ConditionalAppearanceAddress,
							|QueryText, 
							|ReportAppearanceTemplateType, 
							|ReportDimensionsPlacementOnRowsType, 
							|ReportDimensionsPlacementOnColumnsType, 
							|ReportTotalsPlacementOnRowsType, 
							|ReportTotalsPlacementOnColumnsType, 
							|ReportDimensionAttributesPlacementInRowsType, 
							|ReportDimensionAttributesPlacementInColumnsType, 
							|ReportAutoscaleType, 
							|ReportPageOrientation, 
							|ReportDoNotPutReportHeader, 
							|ReportDoNotPutTableHeader, 
							|ReportDoNotPutDetailRecords, 
							|ReportDoNotPutTableFooter, 
							|ReportDoNotPutOveralls, 
							|ReportDoNotPutReportFooter, 
							|ChartIsSupported,
							|ReportChartType, 
							|ReportShowChartOnOpen");
	
	// Initialize structure parameters
	vParams.CloseOnChoice = False;
	vParams.CloseOnOwnerClose = True;
	vParams.ReportShowChartOnOpen = False;
	vParams.ReadOnly = False;
	FillPropertyValues(vParams, pRepObj);
	
	// Check if chart is supported
	vReportAttributes = pRepObj.Metadata().Attributes;
	If vReportAttributes.Find("ReportShowChartOnOpen") = Undefined Then
		vParams.ChartIsSupported = False;
		vParams.ReportChartType = Undefined;
	Else
		vParams.ChartIsSupported = True;
		vParams.ReportChartType = cmGetReportChartTypeEnumRef(pRepObj.ReportChartType);
	EndIf;
	
	// Initialize report builder object
	If pRepObj.ReportBuilder.AvailableFields.Count() = 0 Then
		pRepObj.pmLoadReportAttributes();
	EndIf;
	
	// Fill value tree of report builder available fields
	vAvailableFields = New ValueTree();
	vAvailableFields.Columns.Add("Name");
	vAvailableFields.Columns.Add("DataPath");
	vAvailableFields.Columns.Add("Presentation");
	vAvailableFields.Columns.Add("ValueList");
	vAvailableFields.Columns.Add("ValueType");
	vAvailableFields.Columns.Add("Field", cmGetBooleanTypeDescription());
	vAvailableFields.Columns.Add("Dimension", cmGetBooleanTypeDescription());
	vAvailableFields.Columns.Add("Filter", cmGetBooleanTypeDescription());
	vAvailableFields.Columns.Add("Order", cmGetBooleanTypeDescription());
	For Each vAvailableField In pRepObj.ReportBuilder.AvailableFields Do
		AddFieldToTree(vAvailableFields.Rows, vAvailableField, 0);
	EndDo;
	vParams.AvailableFieldsAddress = PutToTempStorage(vAvailableFields, pFormUUID);
	
	// Fill value table of report selected fields
	vSelectedFields = New ValueTable();
	vSelectedFields.Columns.Add("Name", cmGetStringTypeDescription(1000));
	vSelectedFields.Columns.Add("DataPath", cmGetStringTypeDescription(1000));
	vSelectedFields.Columns.Add("Presentation", cmGetStringTypeDescription(1000));
	For Each vSelectedField In pRepObj.ReportBuilder.SelectedFields Do
		vSelectedFieldsRow = vSelectedFields.Add();
		FillPropertyValues(vSelectedFieldsRow, vSelectedField);
		FixNameAndDataPathReadPlatformBug(vSelectedFieldsRow);
	EndDo;
	vParams.SelectedFieldsAddress = PutToTempStorage(vSelectedFields, pFormUUID);
	
	// Report column overrides
	CheckReportColumnOverridesStructure(pRepObj.ReportColumnOverrides);
	vParams.ReportColumnOverridesAddress = PutToTempStorage(pRepObj.ReportColumnOverrides, pFormUUID);
	
	// Fill value table of report filter fields
	vFilterFields = New ValueTable();
	vFilterFields.Columns.Add("Name", cmGetStringTypeDescription(1000));
	vFilterFields.Columns.Add("DataPath", cmGetStringTypeDescription(1000));
	vFilterFields.Columns.Add("Presentation", cmGetStringTypeDescription(1000));
	vFilterFields.Columns.Add("ValueType");
	vFilterFields.Columns.Add("ComparisonType");
	vFilterFields.Columns.Add("Value");
	vFilterFields.Columns.Add("ValueFrom");
	vFilterFields.Columns.Add("ValueTo");
	vFilterFields.Columns.Add("Use", cmGetBooleanTypeDescription());
	For Each vFilterField In pRepObj.ReportBuilder.Filter Do
		vFilterFieldsRow = vFilterFields.Add();
		FillPropertyValues(vFilterFieldsRow, vFilterField, , "ComparisonType");
		FixNameAndDataPathReadPlatformBug(vFilterFieldsRow);
		vFilterFieldsRow.ComparisonType = cmGetComparisonTypeEnumRef(vFilterField.ComparisonType);
	EndDo;
	vParams.FilterAddress = PutToTempStorage(vFilterFields, pFormUUID);
	
	// Fill value table of report row dimensions fields
	vRowDimFields = New ValueTable();
	vRowDimFields.Columns.Add("Name", cmGetStringTypeDescription(1000));
	vRowDimFields.Columns.Add("DataPath", cmGetStringTypeDescription(1000));
	vRowDimFields.Columns.Add("Presentation", cmGetStringTypeDescription(1000));
	vRowDimFields.Columns.Add("DimensionType");
	vRowDimFields.Columns.Add("GroupBy", cmGetBooleanTypeDescription());
	For Each vRowDimField In pRepObj.ReportBuilder.RowDimensions Do
		vRowDimFieldsRow = vRowDimFields.Add();
		FillPropertyValues(vRowDimFieldsRow, vRowDimField, , "DimensionType");
		FixNameAndDataPathReadPlatformBug(vRowDimFieldsRow);
		vRowDimFieldsRow.DimensionType = cmGetReportDimensionTypeEnumRef(vRowDimField.DimensionType);
	EndDo;
	vParams.RowDimensionsAddress = PutToTempStorage(vRowDimFields, pFormUUID);
	
	// Fill value table of report column dimensions fields
	vColDimFields = New ValueTable();
	vColDimFields.Columns.Add("Name", cmGetStringTypeDescription(1000));
	vColDimFields.Columns.Add("DataPath", cmGetStringTypeDescription(1000));
	vColDimFields.Columns.Add("Presentation", cmGetStringTypeDescription(1000));
	vColDimFields.Columns.Add("DimensionType");
	vColDimFields.Columns.Add("GroupBy", cmGetBooleanTypeDescription());
	For Each vColDimField In pRepObj.ReportBuilder.ColumnDimensions Do
		vColDimFieldsRow = vColDimFields.Add();
		FillPropertyValues(vColDimFieldsRow, vColDimField, , "DimensionType");
		FixNameAndDataPathReadPlatformBug(vColDimFieldsRow);
		vColDimFieldsRow.DimensionType = cmGetReportDimensionTypeEnumRef(vColDimField.DimensionType);
	EndDo;
	vParams.ColumnDimensionsAddress = PutToTempStorage(vColDimFields, pFormUUID);
	
	// Fill value table of report sorting fields
	vOrderFields = New ValueTable();
	vOrderFields.Columns.Add("Name", cmGetStringTypeDescription(1000));
	vOrderFields.Columns.Add("DataPath", cmGetStringTypeDescription(1000));
	vOrderFields.Columns.Add("Presentation", cmGetStringTypeDescription(1000));
	vOrderFields.Columns.Add("Data", cmGetStringTypeDescription(1000));
	vOrderFields.Columns.Add("Direction");
	For Each vOrderField In pRepObj.ReportBuilder.Order Do
		vOrderFieldsRow = vOrderFields.Add();
		FillPropertyValues(vOrderFieldsRow, vOrderField, , "Direction");
		FixNameAndDataPathReadPlatformBug(vOrderFieldsRow);
		vOrderFieldsRow.Direction = cmGetReportSortingDirectionEnumRef(vOrderField.Direction);
	EndDo;
	vParams.OrderAddress = PutToTempStorage(vOrderFields, pFormUUID);
	
	// Fill value table of report conditional appearance fields
	vCondAppFields = New ValueTable();
	vCondAppFields.Columns.Add("Use", cmGetBooleanTypeDescription());
	vCondAppFields.Columns.Add("Name", cmGetStringTypeDescription(1000));
	vCondAppFields.Columns.Add("Title", cmGetStringTypeDescription(1000));
	vCondAppFields.Columns.Add("AreaPresentation", cmGetStringTypeDescription());
	vCondAppFields.Columns.Add("FilterPresentation", cmGetStringTypeDescription());
	vCondAppFields.Columns.Add("AppearancePresentation", cmGetStringTypeDescription());
	vCondAppFields.Columns.Add("Area");
	vCondAppFields.Columns.Add("Filter");
	vCondAppFields.Columns.Add("Appearance");
	For Each vCondAppField In pRepObj.ReportBuilder.ConditionalAppearance Do
		vCondAppFieldsRow = vCondAppFields.Add();
		FillPropertyValues(vCondAppFieldsRow, vCondAppField);
		vCondAppFieldsRow.AreaPresentation = String(vCondAppField.Area);
		vCondAppFieldsRow.FilterPresentation = String(vCondAppField.Filter);
		vCondAppFieldsRow.AppearancePresentation = String(vCondAppField.Appearance);
		
		vCondAppFieldsRow.Area = New ValueTable();
		vCondAppFieldsRow.Area.Columns.Add("Title", cmGetStringTypeDescription(1000));
		vCondAppFieldsRow.Area.Columns.Add("DataPath", cmGetStringTypeDescription(1000));
		vCondAppFieldsRow.Area.Columns.Add("AreaType");
		For Each vAreaItem In vCondAppField.Area Do
			vAreasRow = vCondAppFieldsRow.Area.Add();
			FillPropertyValues(vAreasRow, vAreaItem, , "AreaType");
			vAreasRow.AreaType = cmGetReportAppearanceAreaTypeEnumRef(vAreaItem.AreaType);
		EndDo;
		
		vCondAppFieldsRow.Filter = New ValueTable();
		vCondAppFieldsRow.Filter.Columns.Add("Name", cmGetStringTypeDescription(1000));
		vCondAppFieldsRow.Filter.Columns.Add("DataPath", cmGetStringTypeDescription(1000));
		vCondAppFieldsRow.Filter.Columns.Add("Presentation", cmGetStringTypeDescription(1000));
		vCondAppFieldsRow.Filter.Columns.Add("ValueType");
		vCondAppFieldsRow.Filter.Columns.Add("ComparisonType");
		vCondAppFieldsRow.Filter.Columns.Add("Value");
		vCondAppFieldsRow.Filter.Columns.Add("ValueFrom");
		vCondAppFieldsRow.Filter.Columns.Add("ValueTo");
		vCondAppFieldsRow.Filter.Columns.Add("Use", cmGetBooleanTypeDescription());
		For Each vFilterItem In vCondAppField.Filter Do
			vFilterRow = vCondAppFieldsRow.Filter.Add();
			FillPropertyValues(vFilterRow, vFilterItem, , "ComparisonType");
			vFilterRow.ComparisonType = cmGetComparisonTypeEnumRef(vFilterItem.ComparisonType);
		EndDo;
		
		vCondAppFieldsRow.Appearance = New ValueTable();
		vCondAppFieldsRow.Appearance.Columns.Add("Title", cmGetStringTypeDescription(1000));
		vCondAppFieldsRow.Appearance.Columns.Add("Name", cmGetStringTypeDescription(1000));
		vCondAppFieldsRow.Appearance.Columns.Add("ValueType");
		vCondAppFieldsRow.Appearance.Columns.Add("Value");
		vCondAppFieldsRow.Appearance.Columns.Add("Use", cmGetBooleanTypeDescription());
		For Each vAppearanceItem In vCondAppField.Appearance Do
			vAppearanceRow = vCondAppFieldsRow.Appearance.Add();
			FillPropertyValues(vAppearanceRow, vAppearanceItem);
		EndDo;
	EndDo;
	vParams.ConditionalAppearanceAddress = PutToTempStorage(vCondAppFields, pFormUUID);
	
	// Return structure
	Return vParams;
EndFunction // cmGetReportParametersStructure

// -----------------------------------------------------------------------------
// 1C execution platforms with version later then 8.3.12 (up to 8.3.24 at the moment this code was written)
// occasionally could read Name without first letter from the Report builder settings (first letter will be x0). 
// This procedure will restore this missing letter from the DataPath column
// -----------------------------------------------------------------------------
Procedure FixNameAndDataPathReadPlatformBug(pFieldRow)
	If pFieldRow <> Undefined Then
		If Not IsBlankString(pFieldRow.Name) And Not IsBlankString(pFieldRow.DataPath) Then
			vNameFirstLetter = Left(pFieldRow.Name, 1);
			If CharCode(vNameFirstLetter) = 0 Then
				vNameLength = StrLen(pFieldRow.Name);
				vDataPathLength = StrLen(pFieldRow.DataPath);
				If lower(Mid(pFieldRow.Name, 2)) = lower(Right(pFieldRow.DataPath, vNameLength - 1)) Then
					pFieldRow.Name = Mid(pFieldRow.DataPath, vDataPathLength - vNameLength + 1, 1) + Mid(pFieldRow.Name, 2);
				Else
					pFieldRow.Name = Left(pFieldRow.DataPath, 1) + Mid(pFieldRow.Name, 2);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FixNameAndDataPathReadPlatformBug

// -----------------------------------------------------------------------------
Procedure AddFieldToTree(pTreeRows, pField, Val pLevel)
	pLevel = pLevel + 1;
	If pLevel > 3 Then
		Return;
	EndIf;
	vTreeRow = pTreeRows.Add();
	FillPropertyValues(vTreeRow, pField);
	j = 0;
	For Each vChildField In pField.Fields Do
		If vChildField.Name = "DataVersion" Then
			Continue;
		EndIf;
		j = j + 1;
		AddFieldToTree(vTreeRow.Rows, vChildField, pLevel);
		If pLevel = 2 And j > 0 Then
			Return;
		EndIf;
	EndDo;
EndProcedure // AddFieldToTree

// -----------------------------------------------------------------------------
Function cmGetComparisonTypeEnumRef(pCompType) Export
	If pCompType = ComparisonType.Contains Then
		Return Enums.ComparisonTypes.Contains;
	ElsIf pCompType = ComparisonType.Equal Then
		Return Enums.ComparisonTypes.Equal;
	ElsIf pCompType = ComparisonType.Greater Then
		Return Enums.ComparisonTypes.Greater;
	ElsIf pCompType = ComparisonType.GreaterOrEqual Then
		Return Enums.ComparisonTypes.GreaterOrEqual;
	ElsIf pCompType = ComparisonType.InHierarchy Then
		Return Enums.ComparisonTypes.InHierarchy;
	ElsIf pCompType = ComparisonType.InList Then
		Return Enums.ComparisonTypes.InList;
	ElsIf pCompType = ComparisonType.InListByHierarchy Then
		Return Enums.ComparisonTypes.InListByHierarchy;
	ElsIf pCompType = ComparisonType.Interval Then
		Return Enums.ComparisonTypes.Interval;
	ElsIf pCompType = ComparisonType.IntervalIncludingBounds Then
		Return Enums.ComparisonTypes.IntervalIncludingBounds;
	ElsIf pCompType = ComparisonType.IntervalIncludingLowerBound Then
		Return Enums.ComparisonTypes.IntervalIncludingLowerBound;
	ElsIf pCompType = ComparisonType.IntervalIncludingUpperBound Then
		Return Enums.ComparisonTypes.IntervalIncludingUpperBound;
	ElsIf pCompType = ComparisonType.Less Then
		Return Enums.ComparisonTypes.Less;
	ElsIf pCompType = ComparisonType.LessOrEqual Then
		Return Enums.ComparisonTypes.LessOrEqual;
	ElsIf pCompType = ComparisonType.NotContains Then
		Return Enums.ComparisonTypes.NotContains;
	ElsIf pCompType = ComparisonType.NotEqual Then
		Return Enums.ComparisonTypes.NotEqual;
	ElsIf pCompType = ComparisonType.NotInHierarchy Then
		Return Enums.ComparisonTypes.NotInHierarchy;
	ElsIf pCompType = ComparisonType.NotInList Then
		Return Enums.ComparisonTypes.NotInList;
	ElsIf pCompType = ComparisonType.NotInListByHierarchy Then
		Return Enums.ComparisonTypes.NotInListByHierarchy;
	Else
		Return Enums.ComparisonTypes.EmptyRef();
	EndIf;
EndFunction // cmGetComparisonTypeEnumRef

// -----------------------------------------------------------------------------
Function cmGetComparisonType(pCompType) Export
	If pCompType = Enums.ComparisonTypes.Contains Then
		Return ComparisonType.Contains;
	ElsIf pCompType = Enums.ComparisonTypes.Equal Then
		Return ComparisonType.Equal;
	ElsIf pCompType = Enums.ComparisonTypes.Greater Then
		Return ComparisonType.Greater;
	ElsIf pCompType = Enums.ComparisonTypes.GreaterOrEqual Then
		Return ComparisonType.GreaterOrEqual;
	ElsIf pCompType = Enums.ComparisonTypes.InHierarchy Then
		Return ComparisonType.InHierarchy;
	ElsIf pCompType = Enums.ComparisonTypes.InList Then
		Return ComparisonType.InList;
	ElsIf pCompType = Enums.ComparisonTypes.InListByHierarchy Then
		Return ComparisonType.InListByHierarchy;
	ElsIf pCompType = Enums.ComparisonTypes.Interval Then
		Return ComparisonType.Interval;
	ElsIf pCompType = Enums.ComparisonTypes.IntervalIncludingBounds Then
		Return ComparisonType.IntervalIncludingBounds;
	ElsIf pCompType = Enums.ComparisonTypes.IntervalIncludingLowerBound Then
		Return ComparisonType.IntervalIncludingLowerBound;
	ElsIf pCompType = Enums.ComparisonTypes.IntervalIncludingUpperBound Then
		Return ComparisonType.IntervalIncludingUpperBound;
	ElsIf pCompType = Enums.ComparisonTypes.Less Then
		Return ComparisonType.Less;
	ElsIf pCompType = Enums.ComparisonTypes.LessOrEqual Then
		Return ComparisonType.LessOrEqual;
	ElsIf pCompType = Enums.ComparisonTypes.NotContains Then
		Return ComparisonType.NotContains;
	ElsIf pCompType = Enums.ComparisonTypes.NotEqual Then
		Return ComparisonType.NotEqual;
	ElsIf pCompType = Enums.ComparisonTypes.NotInHierarchy Then
		Return ComparisonType.NotInHierarchy;
	ElsIf pCompType = Enums.ComparisonTypes.NotInList Then
		Return ComparisonType.NotInList;
	ElsIf pCompType = Enums.ComparisonTypes.NotInListByHierarchy Then
		Return ComparisonType.NotInListByHierarchy;
	Else
		Return ComparisonType.Equal;
	EndIf;
EndFunction // cmGetComparisonType

// -----------------------------------------------------------------------------
Function cmGetReportDimensionTypeEnumRef(pRptDimType) Export
	If pRptDimType = ReportBuilderDimensionType.Hierarchy Then
		Return Enums.ReportDimensionTypes.Hierarchy;
	ElsIf pRptDimType = ReportBuilderDimensionType.HierarchyOnly Then
		Return Enums.ReportDimensionTypes.HierarchyOnly;
	ElsIf pRptDimType = ReportBuilderDimensionType.Items Then
		Return Enums.ReportDimensionTypes.Items;
	Else
		Return Enums.ReportDimensionTypes.EmptyRef();
	EndIf;
EndFunction // cmGetReportDimensionTypeEnumRef

// -----------------------------------------------------------------------------
Function cmGetReportDimensionType(pRptDimType) Export
	If pRptDimType = Enums.ReportDimensionTypes.Hierarchy Then
		Return ReportBuilderDimensionType.Hierarchy;
	ElsIf pRptDimType = Enums.ReportDimensionTypes.HierarchyOnly Then
		Return ReportBuilderDimensionType.HierarchyOnly;
	ElsIf pRptDimType = Enums.ReportDimensionTypes.Items Then
		Return ReportBuilderDimensionType.Items;
	Else
		Return ReportBuilderDimensionType.Items;
	EndIf;
EndFunction // cmGetReportDimensionType

// -----------------------------------------------------------------------------
Function cmGetReportSortingDirectionEnumRef(pSortDirection) Export
	If pSortDirection = SortDirection.Asc Then
		Return Enums.SortingDirections.Asc;
	ElsIf pSortDirection = SortDirection.Desc Then
		Return Enums.SortingDirections.Desc;
	Else
		Return Enums.SortingDirections.EmptyRef();
	EndIf;
EndFunction // cmGetReportSortingDirectionEnumRef

// -----------------------------------------------------------------------------
Function cmGetReportSortingDirection(pSortDirection) Export
	If pSortDirection = Enums.SortingDirections.Asc Then
		Return SortDirection.Asc;
	ElsIf pSortDirection = Enums.SortingDirections.Desc Then
		Return SortDirection.Desc;
	Else
		Return SortDirection.Asc;
	EndIf;
EndFunction // cmGetReportSortingDirection

// -----------------------------------------------------------------------------
Function cmGetReportAppearanceAreaTypeEnumRef(pAreaType) Export
	If pAreaType = AppearanceAreaType.Field Then
		Return Enums.AppearanceAreaTypes.Field;
	ElsIf pAreaType = AppearanceAreaType.Group Then
		Return Enums.AppearanceAreaTypes.Group;
	Else
	    Return Enums.AppearanceAreaTypes.EmptyRef();
	EndIf;
EndFunction // cmGetReportAppearanceAreaTypeEnumRef

// -----------------------------------------------------------------------------
Function cmGetReportAppearanceAreaType(pAreaType) Export
	If pAreaType = Enums.AppearanceAreaTypes.Field Then
		Return AppearanceAreaType.Field;
	ElsIf pAreaType = Enums.AppearanceAreaTypes.Group Then
		Return AppearanceAreaType.Group;
	Else
		Return AppearanceAreaType.Field;
	EndIf;
EndFunction // cmGetReportAppearanceAreaType

// -----------------------------------------------------------------------------
Function cmGetReportChartTypeEnumRef(pChartType) Export
	For i = 0 To (Enums.ReportChartTypes.Count() - 1) Do
		vReportChartTypesItem = Enums.ReportChartTypes.Get(i);
		If ChartType[vReportChartTypesItem.Metadata().EnumValues[i].Name] = pChartType Then
			Return vReportChartTypesItem;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction // cmGetReportChartTypeEnumRef

// -----------------------------------------------------------------------------
Function cmGetReportChartType(pChartType) Export
	If ValueIsFilled(pChartType) Then
		Return ChartType[pChartType.Metadata().EnumValues[Enums.ReportChartTypes.IndexOf(pChartType)].Name];
	Else
		Return ChartType.Line;
	EndIf;
EndFunction // cmGetReportChartType

// -----------------------------------------------------------------------------
Procedure cmApplyReportSettingsStructure(pRepObj, pSettingsStruct) Export
	// Save settings to the report object
	FillPropertyValues(pRepObj, pSettingsStruct);
	
	// Get default builder attributes
	vDefaultSettingsStruct = cmGetReportBuilderAttributesStructure();
	
	// Apply main settings to the report builder
	cmSetReportBuilderAttributes(pRepObj, vDefaultSettingsStruct);
	
	// Report builder
	vReportBuilder = pRepObj.ReportBuilder;
	
	// Apply filter settings
	If pSettingsStruct.Property("FilterAddress") Then
		If Not IsBlankString(pSettingsStruct.FilterAddress) Then
			vFilters = GetFromTempStorage(pSettingsStruct.FilterAddress);
			If vFilters <> Undefined And TypeOf(vFilters) = Type("ValueTable") Then
				vRBFilter = vReportBuilder.Filter;
				i = 0;
				While i < vRBFilter.Count() Do
					vRBFilter.Delete(i);
				EndDo;
				For Each vFiltersRow In vFilters Do
					vRBFilterItem = vRBFilter.Add(vFiltersRow.DataPath, vFiltersRow.Name, vFiltersRow.Presentation);
					vRBFilterItem.ComparisonType = cmGetComparisonType(vFiltersRow.ComparisonType);
					FillPropertyValues(vRBFilterItem, vFiltersRow, "Use, Value, ValueFrom, ValueTo");
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	// Apply report columns settings
	If pSettingsStruct.Property("SelectedFieldsAddress") Then
		If Not IsBlankString(pSettingsStruct.SelectedFieldsAddress) Then
			vFields = GetFromTempStorage(pSettingsStruct.SelectedFieldsAddress);
			If vFields <> Undefined And TypeOf(vFields) = Type("ValueTable") Then
				vRBFields = vReportBuilder.SelectedFields;
				i = 0;
				While i < vRBFields.Count() Do
					vRBFields.Delete(vRBFields[i]);
				EndDo;
				For Each vFieldsRow In vFields Do
					vRBFieldsItem = vRBFields.Add(vFieldsRow.DataPath, vFieldsRow.Name);
					vRBFieldsItem.Presentation = vFieldsRow.Presentation;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	// Apply report row dimensions
	If pSettingsStruct.Property("RowDimensionsAddress") Then
		If Not IsBlankString(pSettingsStruct.RowDimensionsAddress) Then
			vRDims = GetFromTempStorage(pSettingsStruct.RowDimensionsAddress);
			If vRDims <> Undefined And TypeOf(vRDims) = Type("ValueTable") Then
				vRBRDims = vReportBuilder.RowDimensions;
				i = 0;
				While i < vRBRDims.Count() Do
					vRBRDims.Delete(vRBRDims[i]);
				EndDo;
				For Each vRDimsRow In vRDims Do
					vRBRDimsItem = vRBRDims.Add(vRDimsRow.DataPath, vRDimsRow.Name, cmGetReportDimensionType(vRDimsRow.DimensionType));
					vRBRDimsItem.Presentation = vRDimsRow.Presentation;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	// Apply report column dimensions
	If pSettingsStruct.Property("ColumnDimensionsAddress") Then
		If Not IsBlankString(pSettingsStruct.ColumnDimensionsAddress) Then
			vCDims = GetFromTempStorage(pSettingsStruct.ColumnDimensionsAddress);
			If vCDims <> Undefined And TypeOf(vCDims) = Type("ValueTable") Then
				vRBCDims = vReportBuilder.ColumnDimensions;
				i = 0;
				While i < vRBCDims.Count() Do
					vRBCDims.Delete(vRBCDims[i]);
				EndDo;
				For Each vCDimsRow In vCDims Do
					vRBCDimsItem = vRBCDims.Add(vCDimsRow.DataPath, vCDimsRow.Name, cmGetReportDimensionType(vCDimsRow.DimensionType));
					vRBCDimsItem.Presentation = vCDimsRow.Presentation;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	// Apply report sorting settings
	If pSettingsStruct.Property("OrderAddress") Then
		If Not IsBlankString(pSettingsStruct.OrderAddress) Then
			vSortings = GetFromTempStorage(pSettingsStruct.OrderAddress);
			If vSortings <> Undefined And TypeOf(vSortings) = Type("ValueTable") Then
				vRBOrders = vReportBuilder.Order;
				i = 0;
				While i < vRBOrders.Count() Do
					vRBOrders.Delete(i);
				EndDo;
				For Each vSortingsRow In vSortings Do
					vRBOrders.Add(vSortingsRow.DataPath, vSortingsRow.Name, vSortingsRow.Presentation, cmGetReportSortingDirection(vSortingsRow.Direction));
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	// Apply report conditional appearance
	If pSettingsStruct.Property("ConditionalAppearanceAddress") Then
		If Not IsBlankString(pSettingsStruct.ConditionalAppearanceAddress) Then
			vCondApps = GetFromTempStorage(pSettingsStruct.ConditionalAppearanceAddress);
			If vCondApps <> Undefined And TypeOf(vCondApps) = Type("ValueTable") Then
				vRBCondApps = vReportBuilder.ConditionalAppearance;
				i = 0;
				While i < vRBCondApps.Count() Do
					vRBCondApps.Delete(vRBCondApps[i]);
				EndDo;
				For Each vCondAppsRow In vCondApps Do
					vRBCondAppItem = vRBCondApps.Add(vCondAppsRow.Name, vCondAppsRow.Title);
					For Each vAreaRow In vCondAppsRow.Area Do
						vRBAreaItem = vRBCondAppItem.Area.Add(vAreaRow.DataPath, vAreaRow.Title, cmGetReportAppearanceAreaType(vAreaRow.AreaType));
					EndDo;
					For Each vFilterRow In vCondAppsRow.Filter Do
						vRBFilterItem = vRBCondAppItem.Filter.Add(vFilterRow.DataPath, vFilterRow.Name, vFilterRow.Presentation);
						vRBFilterItem.ComparisonType = cmGetComparisonType(vFilterRow.ComparisonType);
						FillPropertyValues(vRBFilterItem, vFilterRow, "Use, Value, ValueFrom, ValueTo");
					EndDo;
					For Each vAppearanceRow In vCondAppsRow.Appearance Do
						vRBAppItem = vRBCondAppItem.Appearance[vCondAppsRow.Appearance.IndexOf(vAppearanceRow)];
						vRBAppItem.Use = vAppearanceRow.Use;
						vRBAppItem.Value = vAppearanceRow.Value;
					EndDo;
					vRBCondAppItem.Use = vCondAppsRow.Use;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	// Load report column overrides
	If pSettingsStruct.Property("ReportColumnOverridesAddress") Then
		If Not IsBlankString(pSettingsStruct.ReportColumnOverridesAddress) Then
			vColumnOverrides = GetFromTempStorage(pSettingsStruct.ReportColumnOverridesAddress);
			pRepObj.ReportColumnOverrides.Clear();
			CheckReportColumnOverridesStructure(pRepObj.ReportColumnOverrides);
			For Each vColumnOverridesRow In vColumnOverrides Do
				If Not IsBlankString(vColumnOverridesRow.ColumnName) Then
					vRepColumnOverridesRow = pRepObj.ReportColumnOverrides.Add();
					FillPropertyValues(vRepColumnOverridesRow, vColumnOverridesRow);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // cmApplyReportSettingsStructure

// -----------------------------------------------------------------------------
Function cmGetExternalDataProcessorObjectByCode(pCode, pFolderCode) Export
	vExtDPFolder = Catalogs.ExternalDataProcessors.EmptyRef();
	If Not IsBlankString(pFolderCode) Then
		vExtDPFolder = Catalogs.ExternalDataProcessors.FindByCode(pFolderCode, False, Catalogs.ExternalDataProcessors.EmptyRef());
	EndIf;
	vExtDPRef = Catalogs.ExternalDataProcessors.FindByCode(pCode, False, vExtDPFolder);
	vExtDPURL = GetURL(vExtDPRef, "ExternalProcessingStorage"); 
	vExtDPName = ExternalDataProcessors.Connect(vExtDPURL, , False);
	vExtDPObj = ExternalDataProcessors.Create(vExtDPName);
	Return vExtDPObj;
EndFunction // cmGetExternalDataProcessorObjectByCode

// -----------------------------------------------------------------------------
// Function - Get XMLString from XDTO
//
// Parameters:
//  pXDTO	 - XDTOObject	 - 
// 
// Returns:
//   - String 
//
Function cmGetXMLStringFromXDTO(pXDTO) Export
	vXML = "";
	Try
		vXMLWriter = New XMLWriter; 
		vXMLWriter.SetString();
		XDTOFactory.WriteXML(vXMLWriter, pXDTO);
		vXML = vXMLWriter.Close();
	Except
	EndTry;
	Return vXML;
EndFunction	

#EndRegion

#Region ImportantDates

// -----------------------------------------------------------------------------
Function cmGetClientImportantDates(pClientRef) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ImportantDates.Ref AS ImportantDateType,
	|	ImportantDates.Remarks AS Remarks,
	|	ImportantDates.Code AS Code,
	|	ImportantDates.Description AS Description,
	|	ClientImportantDates.Guest AS Client,
	|	ClientImportantDates.Date AS Date
	|FROM
	|	Catalog.ImportantDateTypes AS ImportantDates
	|		LEFT JOIN InformationRegister.ClientImportantDates AS ClientImportantDates
	|		ON ImportantDates.Ref = ClientImportantDates.ImportantDateType
	|			AND (ClientImportantDates.Guest = &qClient)
	|WHERE
	|	NOT ImportantDates.DeletionMark
	|	AND NOT ImportantDates.IsFolder
	|
	|ORDER BY
	|	ImportantDates.Code";
	vQry.SetParameter("qClient", pClientRef);
	Return vQry.Execute().Unload();
EndFunction // cmGetClientImportantDates

#EndRegion

#Region ClientTags

// -----------------------------------------------------------------------------
Function cmGetClientTagsList(pClient) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientTags.Tag AS Tag,
	|	ClientTags.Tag.Code AS TagCode,
	|	ClientTags.Tag.Description AS TagDescription
	|FROM
	|	InformationRegister.ClientTags AS ClientTags
	|WHERE
	|	ClientTags.Client = &qClient
	|	AND NOT ClientTags.Tag.DeletionMark
	|
	|ORDER BY
	|	TagCode";
	vQry.SetParameter("qClient", pClient);
	vTags = vQry.Execute().Unload();
	vTagsList = New ValueList();
	For Each vTagsRow In vTags Do
		vTagsList.Add(vTagsRow.Tag, vTagsRow.TagDescription);
	EndDo;
	Return vTagsList;
EndFunction //cmGetClientTagsList

// -----------------------------------------------------------------------------
Procedure cmFillClientTagsPresentation(pClient) Export
	If Not ValueIsFilled(pClient) Then
		Return;
	EndIf;
	vClientTags = cmGetClientTagsList(pClient);
	vNewTags = "";
	For Each vClientTagsItem In vClientTags Do
		vNewTags = vNewTags + ?(IsBlankString(vNewTags), "", ", ") + TrimAll(vClientTagsItem.Presentation);
	EndDo;
	vOldTags = TrimAll(pClient.TagsPresentation);
	If vOldTags <> vNewTags Then
		vClientObj = pClient.GetObject();
		vClientObj.TagsPresentation = vNewTags;
		vClientObj.Write();
	EndIf;
EndProcedure //cmFillClientTagsPresentation

#EndRegion

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure GetAddresDadataArr(pList, pKey)
	// Presentation
	pStr = "" 	+ ?(String(pKey.data.country    ) = "XDTODataObject", "", pKey.data.country);
	pStr = pStr + ?(String(pKey.data.postal_code) = "XDTODataObject", "", ", " + pKey.data.postal_code);
	pStr = pStr + ?(String(pKey.data.region     ) = "XDTODataObject", "", ", " + pKey.data.region          + " " + pKey.data.region_type);
	pStr = pStr + ?(String(pKey.data.area       ) = "XDTODataObject", "", ", " + pKey.data.area            + " " + pKey.data.area_type);
	pStr = pStr + ?(String(pKey.data.city       ) = "XDTODataObject", "", ", " + pKey.data.city_type       + " " + pKey.data.city);
	pStr = pStr + ?(String(pKey.data.settlement ) = "XDTODataObject", "", ", " + pKey.data.settlement_type + " " + pKey.data.settlement);
	pStr = pStr + ?(String(pKey.data.street     ) = "XDTODataObject", "", ", " + pKey.data.street_type     + " " + pKey.data.street);
	pStr = pStr + ?(String(pKey.data.house      ) = "XDTODataObject", "", ", " + pKey.data.house_type      + " " + pKey.data.house);
	pList.Add(pStr);	
	
	// Value
	pStr = ""   + ?(String(pKey.data.country    ) = "XDTODataObject", "", pKey.data.country);
	pStr = pStr + ?(String(pKey.data.postal_code) = "XDTODataObject", ",", ", " + pKey.data.postal_code);
	pStr = pStr + ?(String(pKey.data.region     ) = "XDTODataObject", ",", ", " + pKey.data.region + " " + pKey.data.region_type);
	pStr = pStr + ?(String(pKey.data.area       ) = "XDTODataObject", ",", ", " + pKey.data.area   + " " + pKey.data.area_type);
	
	vCity  = 	  ?(String(pKey.data.city       ) = "XDTODataObject", "", pKey.data.city);
	vSettlement = ?(String(pKey.data.settlement ) = "XDTODataObject", "", pKey.data.settlement);
	If  IsBlankString(vCity) And Not IsBlankString(vSettlement) Then
		pStr = pStr + ", " +vSettlement;
	ElsIf Not IsBlankString(vCity) And IsBlankString(vSettlement) Then	
		pStr = pStr + ", " + vCity;
	ElsIf IsBlankString(vCity) And IsBlankString(vSettlement) Then	
		pStr = pStr + ", ";
	ElsIf Not IsBlankString(vCity) And Not IsBlankString(vSettlement) Then	
		pStr = pStr + ", " + vCity;
	EndIf;	
	pStr = pStr + ?(String(pKey.data.street     ) = "XDTODataObject", ",", ", " + pKey.data.street);
	pStr = pStr + ?(String(pKey.data.house      ) = "XDTODataObject", ",", ", " + pKey.data.house);
	pStr = pStr + ",";
	pList.Add(pStr);
EndProcedure // GetAddresDadataArr

// -----------------------------------------------------------------------------
Procedure GetCustomersDadataArr(pList, pKey)  
	vObject = "XDTODataObject"; 
	If pKey.data.type =	"LEGAL" Then
		// Presentation
		pStr = "" 	+ ?(String(pKey.value    			) = vObject, "", pKey.data.name.short_with_opf);  // Description
		pStr = pStr + ?(String(pKey.data.inn			) = vObject, "", ", " + pKey.data.inn);     // INN
		pStr = pStr + ?(pKey.data.address.Properties().Count() = 0, "", ", " + pKey.data.address.value);  // LegacyAddress
		pList.Add(pStr);	
		
		// Value
		pStr = "" 	+ ?(String(pKey.value    			) = vObject, "", pKey.Value);  // Description
		pStr = pStr + ?(String(pKey.data.inn			) = vObject, "; ","; " + pKey.data.inn);     // INN
		pStr = pStr + ?(String(pKey.data.kpp     		) = vObject, "; ","; " + pKey.data.kpp);     // KPP
		pStr = pStr + ?(String(pKey.data.ogrn     		) = vObject, "; ","; " + pKey.data.ogrn);     // OGRN
		pStr = pStr + ?(pKey.data.address.Properties().Count() = 0, "", "; " + pKey.data.address.value);  // LegacyAddress
		pStr = pStr + ?(pKey.data.name.Properties().Count() = 0, "; ", "; """ + pKey.data.name.full_with_opf + """");  // Legacy name
 		pStr = pStr + ?(pKey.data.management.Properties().Count() = 0, "; ", "; " + pKey.data.management.name);  // Director
		pStr = pStr + ?(pKey.data.management.Properties().Count() = 0, "; ", "; " + pKey.data.management.post);  //
		pStr = pStr + ?(pKey.data.state.Properties().Count() = 0, "; ", "; " + pKey.data.state.status);  //  Status: ACTIVE; LIQUIDATING; LIQUIDATED
		
		pList.Add(pStr);	
	Else
		// INDIVIDUAL
		
		// Presentation
		pStr = "" 	+ ?(String(pKey.value    			) = vObject, "", pKey.data.name.short_with_opf);  // Description
		pStr = pStr + ?(String(pKey.data.inn			) = vObject, "; ", ", " + pKey.data.inn);     // INN
		pList.Add(pStr);	
		
		// Value
		pStr = "" 	+ ?(String(pKey.value    			) = vObject, "; ", pKey.value);  // Description
		pStr = pStr + ?(String(pKey.data.inn			) = vObject, "; ", "; " + pKey.data.inn);     // INN
		pStr = pStr + ";";     // KPP
		pStr = pStr + ?(String(pKey.data.ogrn     		) = vObject, "; ", "; " + pKey.data.ogrn);     // OGRN
		pStr = pStr + ";";  // LegacyAddress
		pStr = pStr + ?(pKey.data.name.Properties().Count() = 0, "; ", "; " + pKey.data.name.full_with_opf);  // Legacy name
		pStr = pStr + ";";  // Director
		pStr = pStr + ";";  //
		pStr = pStr + ?(pKey.data.state.Properties().Count() = 0, "; ", "; " + pKey.data.state.status);  //  Status: ACTIVE; LIQUIDATING; LIQUIDATED
		
		pList.Add(pStr);	
	EndIf;
EndProcedure // GetCustomersDadataArr

// -----------------------------------------------------------------------------
Procedure GetFIODadataArr(pList, pKey)   
	vObject = "XDTODataObject";
    pStr = "" 	+ ?(String(pKey.data.country    ) = vObject, "", pKey.data.country);
    pStr = pStr + ?(String(pKey.data.postal_code) = vObject, "",", " + pKey.data.postal_code);
    pStr = pStr + ?(String(pKey.data.region     ) = vObject, "",", " + pKey.data.region          + " " + pKey.data.region_type);
    pStr = pStr + ?(String(pKey.data.area       ) = vObject, "",", " + pKey.data.area            + " " + pKey.data.area_type);
    pStr = pStr + ?(String(pKey.data.city       ) = vObject, "",", " + pKey.data.city_type       + " " + pKey.data.city);
    pStr = pStr + ?(String(pKey.data.settlement ) = vObject, "",", " + pKey.data.settlement_type + " " + pKey.data.settlement);
    pStr = pStr + ?(String(pKey.data.street     ) = vObject, "",", " + pKey.data.street_type     + " " + pKey.data.street);
    pStr = pStr + ?(String(pKey.data.house      ) = vObject, "",", " + pKey.data.house_type      + " " + pKey.data.house);
    pList.Add(pStr);	
    
    pStr = ""   + ?(String(pKey.data.country    ) = vObject, "", pKey.data.country);
    pStr = pStr + ?(String(pKey.data.postal_code) = vObject, ",",", " + pKey.data.postal_code);
    pStr = pStr + ?(String(pKey.data.region     ) = vObject, ",",", " + pKey.data.region + " " + pKey.data.region_type);
    pStr = pStr + ?(String(pKey.data.area       ) = vObject, ",",", " + pKey.data.area   + " " + pKey.data.area_type);
    pStr = pStr + ?(String(pKey.data.city       ) = vObject, ",",", " + pKey.data.city);
    pStr = pStr + ?(String(pKey.data.settlement ) = vObject, ",",", " + pKey.data.settlement);
    pStr = pStr + ?(String(pKey.data.street     ) = vObject, ",",", " + pKey.data.street);
    pStr = pStr + ?(String(pKey.data.house      ) = vObject, ",",", " + pKey.data.house);
    pStr = pStr + ",";
    pStr = pStr + ",";
    pList.Add(pStr);
EndProcedure  //GetFIODadataArr

// -----------------------------------------------------------------------------
Procedure CheckReportColumnOverridesStructure(pRepColOvr)
	If pRepColOvr.Columns.Find("ColumnName") = Undefined Then
		pRepColOvr.Columns.Add("ColumnName", cmGetStringTypeDescription());
	EndIf;
	If pRepColOvr.Columns.Find("ColumnDataPath") = Undefined Then
		pRepColOvr.Columns.Add("ColumnDataPath", cmGetStringTypeDescription());
	EndIf;
	If pRepColOvr.Columns.Find("ColumnWidth") = Undefined Then
		pRepColOvr.Columns.Add("ColumnWidth", cmGetNumberTypeDescription(6, 2));
	EndIf;
	If pRepColOvr.Columns.Find("ColumnHeaderDescription") = Undefined Then
		pRepColOvr.Columns.Add("ColumnHeaderDescription", cmGetStringTypeDescription());
	EndIf;
	If pRepColOvr.Columns.Find("ColumnTextPlacement") = Undefined Then
		pRepColOvr.Columns.Add("ColumnTextPlacement", cmGetEnumTypeDescription("TextPlacements"));
	EndIf;
	If pRepColOvr.Columns.Find("ColumnFormat") = Undefined Then
		pRepColOvr.Columns.Add("ColumnFormat", cmGetStringTypeDescription());
	EndIf;
	If pRepColOvr.Columns.Find("ShowInChart") = Undefined Then
		pRepColOvr.Columns.Add("ShowInChart", cmGetBooleanTypeDescription());
	EndIf;
	If pRepColOvr.Columns.Find("ShowGroupClosed") = Undefined Then
		pRepColOvr.Columns.Add("ShowGroupClosed", cmGetBooleanTypeDescription());
	EndIf;
EndProcedure // CheckReportColumnOverridesStructure

#EndRegion
