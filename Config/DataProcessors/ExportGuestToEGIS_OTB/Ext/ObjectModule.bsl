Var MapDocumentTypeCodes; 
// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#IF CLIENT THEN
		OpenForm("DataProcessor.ExportGuestToEGIS_OTB.Form.tcDPForm",New Structure("DataProcessor",ThisObject.DataProcessor));
	#ELSE
		Unload();
	#ENDIF
EndProcedure // pmRun
// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure Unload(pPeriodFrom = Undefined, pPeriodTo = Undefined, pSpreadsheet = Undefined, pErr = False) Export
	Try
		If pPeriodFrom = Undefined or pPeriodTo = Undefined Then 
			vPeriodFrom = LastUnloadDate;
			vPeriodTo	= CurrentSessionDate();
		Else 
			vPeriodFrom = pPeriodFrom;
			vPeriodTo	= pPeriodTo;
		EndIf;
		// Initialize list of errors
		vErrors = InitializeErrors();
		//Get reservations		
		vReservations = GetReservationstions(vPeriodFrom, vPeriodTo, Hotel);
		
		If vReservations.Count() = 0 Then
			vError = Nstr("en = 'In the specified period there are no armor for unloading'; 
						  |de = 'In der angegebenen Zeit gibt es keine Panzerung zum Entladen'; 
						  |ru = 'В указанном периоде нет броней для выгрузки'");
			Raise vError;
		EndIf;	
			
		// Check data and fill data
		If CheckReservationsData(vErrors, vReservations) Then
			//fill file
			vCSV			= CreateCSV(vReservations);
			vFileNameNoPath = TrimAll(OperatorId)+"_"+GetDateForFileName()+ ".CSV";
			vFileName 		= SaveFilePath + "\" + vFileNameNoPath;
			vFile = New File(vFileName);
			FileCopy(vCSV, vFileName);	
			vMsg = Nstr("en = 'Created file ';de = 'Created file '; ru = 'Создан файл '")+Chars.CR+vFileName;
			tcCommonFunctionOnClientServer.TextMessage((vMsg));
			// Zip file with changes if necessary
			If DoZip Then
				vArchive = New ZipFileWriter(vFileName + ".zip", ,"Created in 1C:Hotel" , ZIPCompressionMethod.Deflate, ZIPCompressionLevel.Maximum, ZIPEncryptionMethod.AES256);
				vArchive.Add(vFileName, ZIPStorePathMode.DontStorePath);
				vArchive.Write();
				vMsg = Nstr("en = 'Created file ';de = 'Created file '; ru = 'Создан файл '")+Chars.CR+vFileName+ ".zip";
				tcCommonFunctionOnClientServer.TextMessage((vMsg));
			EndIf;

			//save parameters
			LastUnloadDate = vPeriodTo;
			pmSaveDataProcessorAttributes();
		Else
			//processing errors
			pErr = True;
			PrintErrors(vErrors,pSpreadsheet);
		EndIf;
	Except
		vError = ErrorInfo();
		tcCommonFunctionOnClientServer.TextMessage(vError.Description);
		WriteLogEvent("EgisOTB_Unload", EventLogLevel.Error,,,ErrorDescription());
	EndTry;
EndProcedure

// -----------------------------------------------------------------------------
Function GetReservationstions(pPeriodFrom, pPeriodTo, pHotel)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Reservation.Guest.FirstName AS FirstName,
	|	Reservation.Guest.LastName AS LastName,
	|	Reservation.Guest.SecondName AS SecondName,
	|	Reservation.Guest.DateOfBirth AS DateOfBirth,
	|	Reservation.CheckInDate AS DepartureDate,
	|	Reservation.CheckOutDate AS ArrivalDate,
	|	Reservation.Guest.Sex AS Sex,
	|	Reservation.Guest.Language AS Language,
	|	Reservation.Guest.Citizenship.ISOCode3 AS CitizenshipISOCode3,
	|	Reservation.Guest.IdentityDocumentType.Code AS IdentityDocumentTypeCode,
	|	Reservation.Guest.IdentityDocumentSeries AS IdentityDocumentSeries,
	|	Reservation.Guest.IdentityDocumentNumber AS IdentityDocumentNumber,
	|	Reservation.Ref AS RegistryRecord
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND Reservation.CheckInDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|	AND Reservation.Hotel = &qHotel
	|	AND Reservation.CheckOutDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|	AND Reservation.ReservationStatus.IsActive
	|	AND CASE
	|			WHEN &qAgent = VALUE(Catalog.Customers.EmptyRef)
	|				THEN TRUE
	|			ELSE Reservation.Customer <> &qAgent
	|		END
	|
	|ORDER BY
	|	FirstName,
	|	LastName";
	
	vQuery.SetParameter("qPeriodFrom", 	pPeriodFrom);
	vQuery.SetParameter("qPeriodTo", 	pPeriodTo);
	vQuery.SetParameter("qHotel", 		pHotel);
	vQuery.SetParameter("qAgent", 		Agent);
	
	Return vQuery.Execute().Unload();	
EndFunction

// -----------------------------------------------------------------------------
Function CreateCSV(pReservations)
	vFile 		= GetTempFileName("CSV");
	vTextWriter = New TextWriter(vFile, TextEncoding.UTF8);
	vDelimiter = ";";
	
	vHeader = "surname;name;patronymic;birthday;docType;docNumber;documentAdditionalInfo;departPlace;arrivePlace;routeType;
			  |departDate;citizenship;gender;recType;rank;operationType;operatorId;route;reservedSeatsCount;buyDate;termNumOrSurname;
			  |arriveDate;shipClass;shipNumber;shipName;flagState;registerTimeIS;operatorVersion";
	vTextWriter.WriteLine(vHeader);	
	
	For Each vGuest in pReservations Do
		vDocType = MapDocumentTypeCodes.Get(GetValidStringValue(vGuest.IdentityDocumentTypeCode));
		If vDocType = Undefined Then
			vErr = Nstr("en = 'Не удалось определить соответствие для документа удостоверения личности для гостя: '; 
						|de = 'Не удалось определить соответствие для документа удостоверения личности для гостя: '; 
						|ru = 'Не удалось определить соответствие для документа удостоверения личности для гостя: '")+vGuest.FirstName+" "+ vGuest.LastName +Chars.CR+vGuest.RegistryRecord;
		EndIf;	
		vTextLine = "";
		vTextLine = vTextLine + Left(GetValidStringValue(vGuest.LastName),40)+vDelimiter;                   //surname
		vTextLine = vTextLine + Left(GetValidStringValue(vGuest.FirstName),30)+vDelimiter;					//name
		vTextLine = vTextLine + ?(IsBlankString(GetValidStringValue(vGuest.SecondName)),"NA",Left(GetValidStringValue(vGuest.SecondName),30))+vDelimiter;
		vTextLine = vTextLine + Format(vGuest.DateOfBirth,"DF=yyyy-MM-dd")+vDelimiter;                      //birthday
		vTextLine = vTextLine + vDocType + vDelimiter;                                                      //docType
		vTextLine = vTextLine + GetValidStringValue(vGuest.IdentityDocumentSeries)+GetValidStringValue(vGuest.IdentityDocumentSeries)+vDelimiter;
		vTextLine = vTextLine + vDelimiter;                                                                 //documentAdditionalInfo
		vTextLine = vTextLine + Left(GetValidStringValue(vGuest.DepartureCity),20)+vDelimiter;              //departPlace
		vTextLine = vTextLine + Left(GetValidStringValue(vGuest.CityOfArrival),20)+vDelimiter;              //arrivePlace
		vTextLine = vTextLine + RouteType + vDelimiter;                                                     //routeType
		vTextLine = vTextLine + Format(vGuest.DepartureDate,"DF=yyyy-MM-ddTHH:mmZ") + vDelimiter;           //departDate
		vTextLine = vTextLine + Left(GetValidStringValue(vGuest.CitizenshipISOCode3),30)+vDelimiter;        //citizenship
		vTextLine = vTextLine + ?(vGuest.Sex = Enums.Sex.Female,"F","M")+vDelimiter;                        //gender
		vTextLine = vTextLine + "1"+vDelimiter;  															//recType
		vTextLine = vTextLine + vDelimiter;     															//rank
		vTextLine = vTextLine + "1"+vDelimiter;  															//operationType, 0 - reservation, 1-is bay, 50 - emploee and other...
		vTextLine = vTextLine + GetValidStringValue(OperatorId)+ vDelimiter;       							//operatorId
		vTextLine = vTextLine + GetValidStringValue(vGuest.Route)+ vDelimiter;     							//route
		vTextLine = vTextLine + 1 + vDelimiter;     														//reservedSeatsCount
		vTextLine = vTextLine + Format(vGuest.RegistryRecord.Date,"DF=yyyy-MM-ddTHH:mmZ")+vDelimiter;    	//buyDate
        vTextLine = vTextLine + GetValidStringValue(TerminalNumberOrCashier)+ vDelimiter;     				//termNumOrSurname
		vTextLine = vTextLine + Format(vGuest.ArrivalDate,"DF=yyyy-MM-ddTHH:mmZ") + vDelimiter;             //arriveDate
		vTextLine = vTextLine + GetValidStringValue(ShipClass)+ vDelimiter;       							//shipClass
		vTextLine = vTextLine + GetValidStringValue(ShipNumber)+ vDelimiter;       							//shipNumber
		vTextLine = vTextLine + GetValidStringValue(ShipName)+ vDelimiter;       							//shipName
		vTextLine = vTextLine + GetValidStringValue(Hotel.Citizenship.ISOCode3)+ vDelimiter;       			//flagState
		vTextLine = vTextLine + Format(vGuest.RegistryRecord.Date,"DF=yyyy-MM-ddTHH:mmZ")+vDelimiter;		//registerTimeIS
		vTextLine = vTextLine + 20 + vDelimiter;     														//operatorVersion

		vTextWriter.WriteLine(vTextLine);
	EndDo;
	
	vTextWriter.Close();
	
	Return vFile; 
EndFunction

// -----------------------------------------------------------------------------
Function GetValidStringValue(val pValue)
	pValue = TrimAll(pValue);
	pValue = StrReplace(pValue, ";", "");
	pValue = StrReplace(pValue, """", "");
	Return pValue;
EndFunction

// -----------------------------------------------------------------------------
Procedure AddError(pErrors, pErrorText, pDocument)
	vRow = pErrors.Add();
	vRow.Document = pDocument;
	vRow.ErrorText = pErrorText;
	// Write error to the system log
	WriteLogEvent(NStr("en='DataProcessor.ExportGuestToEgisOTB'; de='DataProcessor.ExportGuestToEgisOTB'; ru='Обработка.ЭкспортДанныхГостейВЕгисОТБ'"), EventLogLevel.Warning, Metadata.DataProcessors.ExportGuestToEGIS_OTB, pDocument, pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
// Initialize table with errors
// -----------------------------------------------------------------------------
Function InitializeErrors()
	vErrors = New ValueTable();
	vErrors.Columns.Add("Document");
	vErrors.Columns.Add("ErrorText", cmGetStringTypeDescription());
	Return vErrors;
EndFunction // InitializeErrors

// -----------------------------------------------------------------------------
Function CheckReservationsData(vErrors, pExportTable)
	pExportTable.Columns.Add("DepartureCity");
	pExportTable.Columns.Add("CityOfArrival");
	pExportTable.Columns.Add("Route");

   	// Check each row in the export table
	For Each vRow In pExportTable Do
		FillCruisesCity(vRow.DepartureCity, vRow.CityOfArrival, vRow.Route);
		If TrimAll(vRow.DepartureCity) = "" Then 
			AddError(vErrors, 
			         NStr("ru = 'Не заполнен город отправления';  
			              |de = 'Departure City is empty'; 
			              |en = 'Departure City is empty'"), 
			         vRow.RegistryRecord);
		EndIf;		
		If TrimAll(vRow.CityOfArrival) = "" Then 
			AddError(vErrors, 
			         NStr("ru = 'Не заполнен город прибытия';  
			              |de = 'Arrival City is empty'; 
			              |en = 'Arrival City is empty'"), 
			         vRow.RegistryRecord);
		EndIf;			 
		If TrimAll(vRow.Route) = "" Then 
			AddError(vErrors, 
			         NStr("ru = 'Не заполнен номер рейса';  
			              |de = 'Route is empty'; 
			              |en = 'Route is empty'"), 
			         vRow.RegistryRecord);
		EndIf;	
		If TrimAll(vRow.LastName) = "" Then 
			AddError(vErrors, 
			         NStr("ru = 'Не заполнена ФАМИЛИЯ';  
			              |de = 'LASTNAME is empty'; 
			              |en = 'LASTNAME is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		If TrimAll(vRow.FirstName) = "" Then 
			AddError(vErrors, 
			         NStr("ru = 'Не заполнено ИМЯ'; 
					      |de = 'FIRSTNAME is empty'; 
			              |en = 'FIRSTNAME is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		If TrimAll(vRow.Sex) = "" Then 
			AddError(vErrors, 
			         NStr("ru = 'Не заполнен ПОЛ'; 
					      |de = 'SEX is empty';
			              |en = 'SEX is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
	   	vDateOfBirth = vRow.DateOfBirth;
		If Not ValueIsFilled(vDateOfBirth) Then 
	   		AddError(vErrors, 
			         NStr("ru = 'Не заполнена ДАТА РОЖДЕНИЯ'; 
					      |de = 'DATE OF BIRTH is empty';
			              |en = 'DATE OF BIRTH is empty'"), 
			         vRow.RegistryRecord);
	   	ElsIf vDateOfBirth >= BegOfDay(CurrentSessionDate()) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ДАТА РОЖДЕНИЯ указана не верно (" + Format(vRow.DateOfBirth, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'DATE OF BIRTH is probably wrong (" + Format(vRow.DateOfBirth, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'DATE OF BIRTH is probably wrong (" + Format(vRow.DateOfBirth, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.RegistryRecord);
	   	EndIf;
	   	If TrimAll(vRow.CitizenshipISOCode3) = "" Then 
	   		AddError(vErrors, 
			         NStr("ru = 'Не указано ГРАЖДАНСТВО'; 
					      |de = 'CITIZENSHIP is empty'; 
			              |en = 'CITIZENSHIP is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
	   	If TrimAll(vRow.IdentityDocumentTypeCode) = "" Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указан ВИД ДУЛ'; 
					      |de = 'IDENTITY DOCUMENT TYPE is empty'; 
			              |en = 'IDENTITY DOCUMENT TYPE is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		If TrimAll(vRow.IdentityDocumentNumber) = "" Then 
	   		AddError(vErrors, 
			         NStr("ru = 'Не указан НОМЕР ДУЛ'; 
					      |de = 'IDENTITY DOCUMENT NUMBER is empty'; 
			              |en = 'IDENTITY DOCUMENT NUMBER is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		vCheckInDate = vRow.DepartureDate;
		If Not ValueIsFilled(vCheckInDate) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указана ДАТА ЗАЕЗДА'; 
					      |de = 'CHECK IN DATE is empty'; 
			              |en = 'CHECK IN DATE is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		vCheckOutDate = vRow.ArrivalDate;
		If ValueIsFilled(vCheckOutDate) Then
			If vCheckOutDate < vCheckInDate Then
		   		AddError(vErrors, 
				         NStr("ru = 'Возможно ДАТА ВЫЕЗДА указана не верно (" + Format(vRow.ArrivalDate, "DF=dd.MM.yyyy") + ")'; 
						      |de = 'CHECK OUT DATE is probably wrong (" + Format(vRow.ArrivalDate, "DF=dd.MM.yyyy") + ")'; 
						      |en = 'CHECK OUT DATE is probably wrong (" + Format(vRow.ArrivalDate, "DF=dd.MM.yyyy") + ")'"), 
				         vRow.RegistryRecord);
			EndIf;
		EndIf;
	EndDo;
	vErrors.Sort("Document, ErrorText");
	If vErrors.Count() = 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckForeignersData

// -----------------------------------------------------------------------------
Procedure PrintErrors(pErrors, pSpreadsheet)
	// Choose template
	vSpreadsheet = pSpreadsheet;
	vSpreadsheet.Clear();
	vTemplate = ThisObject.GetTemplate("ErrorsList");
	
	// Header
	vHeader = vTemplate.GetArea("Header");
	vSpreadsheet.Put(vHeader);

	// Print errors
	vCurDocument = Undefined;
	For Each vErrRow In pErrors Do
		// Fill row parameters
		mDocNumber = cmGetDocumentNumberPresentation(vErrRow.Document.Number);
		mDocDate = Format(vErrRow.Document.Date, "DF='dd.MM.yy'");
		dDocument = vErrRow.Document;
		mGuest = "";
		If ValueIsFilled(vErrRow.Document.Guest) Then
			vGuest = vErrRow.Document.Guest;
			mGuest = TrimAll(TrimAll(vGuest.LastName) + " " + TrimAll(vGuest.FirstName) + " " + TrimAll(vGuest.SecondName));
		EndIf;
		dGuest = vErrRow.Document.Guest;
		mError = TrimAll(vErrRow.ErrorText);
		// Output row
		If vErrRow.Document <> vCurDocument Then
			vCurDocument = vErrRow.Document;
			// Get area
			vDoc = vTemplate.GetArea("Doc");
			// Set row parameters
			vDoc.Parameters.mDocNumber = mDocNumber;
			vDoc.Parameters.mDocDate = mDocDate;
			vDoc.Parameters.dDocument = dDocument;
			vDoc.Parameters.mGuest = mGuest;
			vDoc.Parameters.dGuest = dGuest;
			vDoc.Parameters.mError= mError;
			vSpreadsheet.Put(vDoc);
		Else
			// Get area
			vRow = vTemplate.GetArea("Row");
			// Set row parameters
			vRow.Parameters.dDocument = dDocument;
			vRow.Parameters.dGuest = dGuest;
			vRow.Parameters.mError= mError;
			vSpreadsheet.Put(vRow);
		EndIf;
	EndDo;
	
	// Footer
	vFooter = vTemplate.GetArea("Footer");
	vSpreadsheet.Put(vFooter);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // PrintErrors

// -----------------------------------------------------------------------------
Procedure FillCruisesCity(pDepartureCity = "", pCityOfArrival = "", pRoute = "")
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Cruises.CityOfArrival,
	|	Cruises.DateTo AS DateTo,
	|	Cruises.DepartureCity,
	|	Cruises.DateFrom AS DateFrom,
	|	Cruises.Route
	|FROM
	|	InformationRegister.Cruises AS Cruises
	|WHERE
	|	Cruises.Hotel = &qHotel
	|	AND BEGINOFPERIOD(Cruises.DateFrom, DAY) = &qDateFrom
	|	AND BEGINOFPERIOD(Cruises.DateTo, DAY) = &qDateTo
	|
	|GROUP BY
	|	Cruises.CityOfArrival,
	|	Cruises.DateTo,
	|	Cruises.DepartureCity,
	|	Cruises.DateFrom,
	|	Cruises.Route
	|
	|ORDER BY
	|	DateFrom";
	
	Query.SetParameter("qHotel", Hotel);
	Query.SetParameter("qDateFrom", BegOfDay(PeriodFrom));
	Query.SetParameter("qDateTo", BegOfDay(PeriodTo));
	
	QueryResult = Query.Execute();
	
	vTrans = QueryResult.Unload();
	
	If vTrans.Count() > 0 Then		
		vStr = vTrans[0];
		pDepartureCity = vStr.DepartureCity;
		pCityOfArrival = vStr.CityOfArrival;
		pRoute         = vStr.Route;
	Else
		pDepartureCity = "";
		pCityOfArrival = "";
		pRoute		   = "";	
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
Function GetDateForFileName()
	vMss = CurrentUniversalDateInMilliseconds()%1000;
	vDate = Format(CurrentSessionDate(),"DF=yyyy_MM_dd_HH_mm_ss")+"_"+String(vMss);
	Return vDate;
EndFunction	



MapDocumentTypeCodes = New Map;
MapDocumentTypeCodes.Insert("21", "0"); // Паспорт гражданина Российской Федерации
MapDocumentTypeCodes.Insert("26", "1"); // Удостоверение личности моряка (паспорт моряка)
MapDocumentTypeCodes.Insert("22", "2"); // Общегражданский заграничный паспорт гражданина Российской Федерации
MapDocumentTypeCodes.Insert("ИП", "3"); // Паспорт иностранного гражданина
MapDocumentTypeCodes.Insert("3",  "4"); // Свидетельство о рождении
MapDocumentTypeCodes.Insert("04", "5"); // Удостоверение личности военнослужащего
MapDocumentTypeCodes.Insert("76", "6"); // Удостоверение личности лица без гражданства
MapDocumentTypeCodes.Insert("70", "7"); // Временное удостоверение личности, выдаваемое органами внутренних дел
MapDocumentTypeCodes.Insert("07", "8"); // Военный билет военнослужащего срочной службы
MapDocumentTypeCodes.Insert("19", "9"); // Вид на жительство иностранного гражданина или
MapDocumentTypeCodes.Insert("20", "9"); // Лица без гражданства
//MapDocumentTypeCodes.Insert("", "10");// Справка об освобождении из мест лишения свободы
MapDocumentTypeCodes.Insert("01", "11");// Паспорт гражданина СССР
MapDocumentTypeCodes.Insert("09", "12");// Паспорт дипломатический
//MapDocumentTypeCodes.Insert("", "13");  // Паспорт служебный (кроме паспорта моряка и дипломатического)
//MapDocumentTypeCodes.Insert("", "14");  // Свидетельство о возвращении из стран СНГ
//MapDocumentTypeCodes.Insert("139376", "15");  // Справка об утере паспорта