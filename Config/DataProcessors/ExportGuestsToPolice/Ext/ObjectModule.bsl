
#Region Variables

Var SEP;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - param
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Save dataprocessor attributes
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) Then
		Company = SessionParameters.CurrentUser.Company;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate()) - 24*3600 ; // For yesterday
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Run data processor in silent mode
//
// Parameters:
//  pParameter		 - 	 - 
//  pIsInteractive	 - 	 - 
//  pThinClient		 - 	 - 
//  pAddressStorage	 - 	 - 
// 
// Returns:
//  String - Errors 
//
Function pmRun(pParameter = Undefined, pIsInteractive = False, pThinClient = False, pAddressStorage = "") Export
	// Initialize list of errors
	vErrors = InitializeErrors();
	
	// 1. Get data
	vTGuests = GetGuestsList();
	
	CheckGuestData(vErrors,vTGuests);
	
	// 2. Save it to file
	vResultText = SaveToFile(vTGuests,pThinClient,pAddressStorage);
	
	vRow = vErrors.Add();
	vRow.Document = Undefined;
	vRow.ErrorText = "";
	vRow.SuccessText = vResultText;
	// Return errors
	Return vErrors;
EndFunction // pmRun


#EndRegion

#Region Private

// -----------------------------------------------------------------------------
//  Get file name
// 
// Returns:
//  String - File name
//
Function pmGetFileName() 
	vFileName = "";
	If PoliceExportFormat = Enums.PoliceExportFormat.gencat Then
		If FileSeqNumber>=999 Then
			FileSeqNumber = 1;
		EndIf;
		vFileName = TrimAll(PoliceHotelID)+"."+Format(FileSeqNumber,"ND=3; NLZ=; NG=");
	Else
		vFileName = TrimAll(PoliceHotelID)+"_"+Format(CurrentSessionDate(),"DF=yyyyMMdd")+"_"+Format(FileSeqNumber,"NG=")+".csv";
	EndIf;

	Return vFileName;
EndFunction // pmGetFileName

// -----------------------------------------------------------------------------
// Initialize table with errors
Function InitializeErrors()
	vTA = New Array;
	vTA.Add(Type("DocumentRef." + "Accommodation"));
	vTA.Add(Type("DocumentRef." + "ForeignerRegistryRecord"));
	vTypeDescr = New TypeDescription(vTA);

	vErrors = New ValueTable();
	vErrors.Columns.Add("Document", vTypeDescr);
	vErrors.Columns.Add("ErrorText", cmGetStringTypeDescription());
	vErrors.Columns.Add("SuccessText", cmGetStringTypeDescription());
	Return vErrors;
EndFunction // InitializeErrors

// -----------------------------------------------------------------------------
Procedure AddError(pErrors, pErrorText, pDocument)
	vRow = pErrors.Add();
	vRow.Document = pDocument;
	vRow.ErrorText = pErrorText;
	// Write error to the system log
	WriteLogEvent(NStr("en='DataProcessor.ExportGuestsToPolice'; de='DataProcessor.ExportGuestsToPolice'; ru='Обработка.ЭкспортДанныхГостейВПолицию'"), EventLogLevel.Warning, Metadata.DataProcessors.ExportGuestsToPolice, pDocument, pErrorText);
EndProcedure // AddError

// ----------------------------------------------------------------------------
// Returnst value table fo guests to export depending on export format
Function GetGuestsList()
	If PoliceExportFormat = Enums.PoliceExportFormat.gencat Then
		Return GetCheckedInGuests();
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
// Returns the list of guests 
// checked in during export period
// 
Function GetCheckedInGuests()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.Ref AS Accommodation,
	|	Accommodations.Number AS Number,
	|	Accommodations.Date AS Date,
	|	Accommodations.Room AS Room,
	|	Accommodations.CheckInDate AS CheckInDate,
	|	Accommodations.Duration AS Duration,
	|	Accommodations.CheckOutDate AS CheckOutDate,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.Guest.FullName AS FullName,
	|	Accommodations.Guest.LastName AS LastName,
	|	Accommodations.Guest.FirstName AS FirstName,
	|	Accommodations.Guest.SecondName AS SecondName,
	|	Accommodations.Guest.Sex AS Sex,
	|	Accommodations.Guest.Citizenship AS Citizenship,
	|	Accommodations.Guest.Citizenship.ISOCode3 AS CitizenshipISOCode3,
	|	Accommodations.Guest.DateOfBirth AS DateOfBirth,
	|	Accommodations.Guest.PlaceOfBirth AS PlaceOfBirth,
	|	Accommodations.Guest.Address AS Address,
	|	Accommodations.Guest.IdentityDocumentType AS IdentityDocumentType,
	|	Accommodations.Guest.IdentityDocumentType.Code AS IdentityDocumentTypeCode,
	|	Accommodations.Guest.IdentityDocumentType.ExternalCode AS IdentityDocumentTypeExternalCode,
	|	Accommodations.Guest.IdentityDocumentSeries AS IdentityDocumentSeries,
	|	Accommodations.Guest.IdentityDocumentNumber AS IdentityDocumentNumber,
	|	Accommodations.Guest.IdentityDocumentIssueDate AS IdentityDocumentIssueDate,
	|	Accommodations.Guest.IdentityDocumentValidToDate AS IdentityDocumentValidToDate
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.CheckInDate >= &qPeriodFrom
	|	AND Accommodations.CheckInDate <= &qPeriodTo
	|	AND Accommodations.Hotel = &qHotel
	|	AND Accommodations.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|	AND Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND (NOT &qExportVirtualGuests
	|				AND NOT Accommodations.Room.IsVirtual
	|			OR &qExportVirtualGuests)
	|
	|ORDER BY
	|	Accommodations.SortCode";
	vQry.SetParameter("qPeriodFrom", PeriodFrom);
	vQry.SetParameter("qPeriodTo", PeriodTo);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qExportVirtualGuests", ExportVirtualGuests);
	Return vQry.Execute().Unload();
EndFunction // GetCheckedInGuests

// -----------------------------------------------------------------------------
Procedure CheckGuestData(vErrors, pExportTable)
	If Not ValueIsFilled(pExportTable) Then
		Return;
	EndIF;
   	// Check each row in the export table
   	For Each vRow In pExportTable Do
		If TrimAll(vRow.LastName) = "" Then // *3
			AddError(vErrors, 
			         NStr("ru = 'Не заполнена ФАМИЛИЯ';  
			              |de = 'LASTNAME is empty'; 
			              |en = 'LASTNAME is empty'"), 
			         vRow.Accommodation);
		EndIf;
		If TrimAll(vRow.FirstName) = "" Then // *4
			AddError(vErrors, 
			         NStr("ru = 'Не заполнено ИМЯ'; 
					      |de = 'FIRSTNAME is empty'; 
			              |en = 'FIRSTNAME is empty'"), 
			         vRow.Accommodation);
		EndIf;
		If TrimAll(vRow.Sex) = "" Then // *9
			AddError(vErrors, 
			         NStr("ru = 'Не заполнен ПОЛ'; 
					      |de = 'SEX is empty';
			              |en = 'SEX is empty'"), 
			         vRow.Accommodation);
		EndIf;
	   	vDateOfBirth = vRow.DateOfBirth;
		If Not ValueIsFilled(vDateOfBirth) Then //*10
	   		AddError(vErrors, 
			         NStr("ru = 'Не заполнена ДАТА РОЖДЕНИЯ'; 
					      |de = 'DATE OF BIRTH is empty';
			              |en = 'DATE OF BIRTH is empty'"), 
			         vRow.Accommodation);
	   	ElsIf vDateOfBirth >= BegOfDay(CurrentSessionDate()) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ДАТА РОЖДЕНИЯ указана не верно (" + vRow.DateOfBirth + ")'; 
					      |de = 'DATE OF BIRTH is probably wrong (" + vRow.DateOfBirth + ")'; 
					      |en = 'DATE OF BIRTH is probably wrong (" + vRow.DateOfBirth + ")'"), 
			         vRow.Accommodation);
	   	EndIf;
	   	If TrimAll(vRow.CitizenshipISOCode3) = "" Then //*11
	   		AddError(vErrors, 
			         NStr("ru = 'Не указано ГРАЖДАНСТВО'; 
					      |de = 'CITIZENSHIP is empty'; 
			              |en = 'CITIZENSHIP is empty'"), 
			         vRow.Accommodation);
		EndIf;
	   	If TrimAll(vRow.IdentityDocumentType) = "" Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указан ВИД ДУЛ'; 
					      |de = 'IDENTITY DOCUMENT TYPE is empty'; 
			              |en = 'IDENTITY DOCUMENT TYPE is empty'"), 
			         vRow.Accommodation);
		EndIf;
		If TrimAll(vRow.IdentityDocumentNumber) = "" Then // *14
	   		AddError(vErrors, 
			         NStr("ru = 'Не указан НОМЕР ДУЛ'; 
					      |de = 'IDENTITY DOCUMENT NUMBER is empty'; 
			              |en = 'IDENTITY DOCUMENT NUMBER is empty'"), 
			         vRow.Accommodation);
		EndIf;
		vCheckInDate = vRow.CheckInDate;
		If Not ValueIsFilled(vCheckInDate) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указана ДАТА ЗАЕЗДА'; 
					      |de = 'CHECK IN DATE is empty'; 
			              |en = 'CHECK IN DATE is empty'"), 
			         vRow.Accommodation);
		ElsIf vCheckInDate > CurrentSessionDate() Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ДАТА ЗАЕЗДА указана не верно (" + vRow.CheckInDate + ")'; 
					      |de = 'CHECK IN DATE is probably wrong (" + vRow.CheckInDate + ")'; 
					      |en = 'CHECK IN DATE is probably wrong (" + vRow.CheckInDate + ")'"), 
			         vRow.Accommodation);
		EndIf;
		vIdentityDocumentIssueDate = vRow.IdentityDocumentIssueDate;
		If ValueIsFilled(vIdentityDocumentIssueDate) And ValueIsFilled(vDateOfBirth) And vIdentityDocumentIssueDate < vDateOfBirth Then
			AddError(vErrors, 
			NStr("ru = 'Дата выдачи документа удостоверяющего личность раньше даты рождения (" + vRow.IdentityDocumentIssueDate + ")'; 
			|de = 'Identity document issue date could not be earlier then guest birth date (" + vRow.IdentityDocumentIssueDate + ")'; 
			|en = 'Identity document issue date could not be earlier then guest birth date (" + vRow.IdentityDocumentIssueDate + ")'"), 
			vRow.Accommodation);
		EndIf;
	EndDo;
	vErrors.Sort("Document, ErrorText");
EndProcedure // CheckForm5Data

// -----------------------------------------------------------------------------
// Save guest data table to the file export format depends on police export format
//
// Parameters:
//  pExportTable	 - ValueTable	 - Export table
//  pThinClient		 - Boolean		 - ThinClient
//  pAddressStorage	 - String		 - Address temp storage
// 
// Returns:
//  String - Result
//
Function SaveToFile(pExportTable, pThinClient=False, pAddressStorage)
	vSuccessText = "";
Try
	If PoliceExportFormat = Enums.PoliceExportFormat.gencat Then
		// It's for spain catalunia police department
		SEP = "|";
		
		// One guest - one row, group it by guest
		pExportTable.GroupBy("Citizenship, IdentityDocumentSeries, IdentityDocumentNumber, IdentityDocumentTypeExternalCode, IdentityDocumentIssueDate, LastName, SecondName, FirstName, Sex, DateOfBirth, CheckInDate",);
		// 1. create output file
		vExportDir = ?(pThinClient = False, ExportDir, TempFilesDir());
		// Get export file
		vFullFileName = cmGetFullFileName(pmGetFileName(), TrimAll(vExportDir));
		DeleteFiles(vFullFileName);

		vFileName = cmGetFullFileName(pmGetFileName(),ExportDir);
		
		vOutputText = New TextWriter(vFullFileName, TextEncoding.ANSI);
		
		// 2. Write header line
		vHotelName = "";
		If IsBlankString(HotelName) Then
			vHotelName = TrimAll(Hotel.LegacyName);
		Else
			vHotelName = TrimAll(HotelName);
		EndIf;
		vFirstStr = "1"+SEP+TrimAll(Upper(PoliceHotelID)) + SEP + Upper(vHotelName) + SEP+Format(CurrentSessionDate(),"DF=yyyyMMdd")+SEP+Format(CurrentSessionDate(),"DF=HHmm")+SEP+Format(pExportTable.Count(),"NG=");

		vOutputText.WriteLine(vFirstStr);
		
		i = 0;

		// 3. Write guest lines
		For Each vRow In pExportTable Do
			
			vStr = "2"; //1 = Tipus de registre = 2
			If ValueIsFilled(vRow.Citizenship) AND vRow.Citizenship <> Hotel.Citizenship Then
				//it's a foriegner
				vStr=vStr+SEP+""; //11 = * Número de document d’identitat d’espanyols
				vStr=vStr+SEP+Left(TrimAll(vRow.IdentityDocumentSeries)+TrimAll(vRow.IdentityDocumentNumber),14); //14  =* Número de passaport o altre document d’identitat d’estrangers
			Else
				vStr=vStr+SEP+Left(TrimAll(vRow.IdentityDocumentSeries)+TrimAll(vRow.IdentityDocumentNumber),11); //11 = * Número de document d’identitat d’espanyols
				vStr=vStr+SEP+""; //14  =* Número de passaport o altre document d’identitat d’estrangers
			Endif;
			vStr=vStr+SEP+Left(vRow.IdentityDocumentTypeExternalCode,1); //1 = * Tipus de document d’identitat D: DNI, P: passaport, C: carnet conduir (exclusiu per ciutadans espanyols), I: carta o document d’identitat, N: permís de residència espanyol, X: permís de residència d’un altre Estat Membre de la Unió Europea.
			vStr=vStr+SEP+?(ValueIsFilled(vRow.IdentityDocumentIssueDate),Format(vRow.IdentityDocumentIssueDate,"DF=yyyyMMdd"),""); //8 = Data d’expedició del DNI (Date of issue of ID card)
			vStr=vStr+SEP+Upper(Left(vRow.LastName,30)); //30 = Primer cognom (Last name)
			vStr=vStr+SEP+Upper(Left(vRow.SecondName,30)); //30 = Segon cognom (Second name)
			vStr=vStr+SEP+Upper(Left(vRow.FirstName,30)); // 30 = Nom (First name)
			If vRow.Sex = Enums.Sex.Female Then
				vStr=vStr+SEP+"F"; // 1 = Sexe F: femení, M: masculí
			Else
				vStr=vStr+SEP+"M"; // 1 = Sexe F: femení, M: masculí
			EndIf;
			vStr=vStr+SEP+?(ValueIsFilled(vRow.DateOfBirth),Format(vRow.DateOfBirth,"DF=yyyyMMdd"),""); // 8 = Data de naixement  Date of birth
			vStr=vStr+SEP+Upper(Left(vRow.Citizenship,21)); // 21 = País de nacionalitat
			vStr=vStr+SEP+?(ValueIsFilled(vRow.CheckInDate),Format(vRow.CheckInDate,"DF=yyyyMMdd"),""); // 8 = * Data d’entrada
			vOutputText.WriteLine(vStr);
			i=i+1;
		EndDo;
		vOutputText.Close();
		pAddressStorage =  PutToTempStorage(New BinaryData(vFullFileName), New UUID());
		
		vSuccessText = StrTemplate(NStr("en = '%1 guests in file %2'; de = '%1 gäste in Datei %2'; ru = 'Выгружено %1 гостей в файл %2'"),i,vFileName);
	Endif;
	// If no errors - save seq.number
	FileSeqNumber = FileSeqNumber + 1;
	pmSaveDataProcessorAttributes();
Except
	vErrText = ErrorDescription();
	WriteLogEvent("ExportToPolice.SaveToFile",EventLogLevel.Error,,,vErrText);
	tcCommonFunctionOnClientServer.UserMessage(vErrText);
	Return "";
EndTry;
	Return vSuccessText;
EndFunction

#EndRegion
