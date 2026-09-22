
#Region Variables

Var vNSURICore;
Var vNSURICorrection;
Var vNSURIFCCore;
Var vNSURIMigration;
Var vNSURIHotel;
Var vNSURICaseEdit;
Var vNSURIForm5;
Var vNSURIUnreg;
Var vNSURIStaying;
Var vNSURIInvitationApp;
Var vNSURIPayment;
Var vNSURIHotelResponse;

#EndRegion

#Region Public

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
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Company) Then
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.CompanyRegisteredInUFMS) Then
				Company = Hotel.CompanyRegisteredInUFMS;
			Else
				Company = Hotel.Company;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(Employee) Then
		FillEmployee();
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate()) - 24 * 3600 ; // For yesterday
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
	ExportForeigners = True;
	ExportRussians = True;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Function pmRun(pParameter = Undefined, pIsInteractive = False, pThinClient = False, pAddressStorageForeigners = "", pAddressStorageRussian = "", pIgnoreErrors = False) Export
	// Initialize list of errors
	vErrors = InitializeErrors();
	// Process foreigners
	If ExportForeigners And Not IsBlankString(ExportDirForeigners) Then
		// Check and create directory structure
		CheckDirStructure(?(pThinClient = False, ExportDirForeigners, TempFilesDir()));
		// Get foreigner registry records
		vRegistryRecords = GetForeignersRegistryRecords();
		// Build export table
		vExportTable = GetForeignersExportValueTable(vRegistryRecords);
		// Check data
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Vega Then
			If CheckForeignersData(vErrors, vExportTable) Or pIgnoreErrors Then
				// Write foreigners to file
				WriteToForeignersFiles(vExportTable, vErrors, pThinClient, pAddressStorageForeigners);
			EndIf;
		Else
			If CheckForeignersVegaData(vErrors, vExportTable) Or pIgnoreErrors Then
				// Write foreigners to file
				WriteToForeignersVegaFiles(vExportTable, vErrors, pThinClient, pAddressStorageForeigners);
			EndIf;	
		EndIf;
	EndIf;
	// Process russian
	If ExportRussians And Not IsBlankString(ExportDirRussian) Then
		// Check and create directory structure
		CheckDirStructure(?(pThinClient = False, ExportDirRussian, TempFilesDir()));
		// Get foreigner registry records
		vForm5Records = GetForm5RegistryRecords();
		// Build export table
		vExportTable = GetForm5ExportValueTable(vForm5Records);
		// Check data
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Vega Then
			If CheckForm5Data(vErrors, vExportTable) Or pIgnoreErrors Then
				// Write russians to file
				WriteToForm5Files(vExportTable, vErrors, pThinClient, pAddressStorageRussian); 
			EndIf;
		Else
			If CheckVegaData(vErrors, vExportTable) Or pIgnoreErrors Then
				// Write foreigners to file
				WriteVegaFiles(vExportTable, vErrors, pThinClient, pAddressStorageRussian);
			EndIf;	
		EndIf;
	EndIf;
	// Return errors if were found
	Return vErrors
EndFunction // pmRun

// -----------------------------------------------------------------------------
Function pmGetForeignersZIPFileName(pData = "") Export
	vFileNamePrefix = "mvd_fr";
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vFileNamePrefix = "IG";
	ElsIf Receiver = Enums.GuestDataExportHeaderTypesRu.Vega Then
		vFileNamePrefix = "Foreigners_FrOrg" 	
	Else
		vFileNamePrefix = "migcase";
	EndIf;
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		Return Format(CurrentDate(), "DF=yyyyMMdd_HHmmss000_") + vFileNamePrefix + ".zip";
	ElsIf Receiver = Enums.GuestDataExportHeaderTypesRu.Vega Then
		Return vFileNamePrefix + pData + ".zip";  
	Else
		Return vFileNamePrefix + "_" + Format(PeriodFrom, "DF=yyyy-MM-dd_HHmm") + "-" + Format(PeriodTo, "DF=yyyy-MM-dd_HHmm") + ".zip";
	EndIf;
EndFunction // pmGetForeignersZIPFileName

// -----------------------------------------------------------------------------
Function pmGetForeignersFileName(pUID = "") Export
	vFileNamePrefix = "mvd_fr";
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vFileNamePrefix = "IG";
	ElsIf Receiver = Enums.GuestDataExportHeaderTypesRu.Vega Then
		vFileNamePrefix = "FrOrg";
	Else
		vFileNamePrefix = "migcase";
	EndIf;
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		Return "OUT\" + pUID + "_" + Format(CurrentDate(), "DF=yyyyMMdd_HHmmss") + ".xml";
	ElsIf Receiver = Enums.GuestDataExportHeaderTypesRu.Vega Then
		Return "OUT\" + vFileNamePrefix + pUID + ".xml";
	Else
		Return "OUT\" + vFileNamePrefix + "_" + pUID + ".xml";
	EndIf;
EndFunction // pmGetForeignersFileName

// -----------------------------------------------------------------------------
Function pmGetForm5ZIPFileName(pData = "") Export 
	vFileNamePrefix = "mvd_rf";
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vFileNamePrefix = "RG";
	ElsIf Receiver = Enums.GuestDataExportHeaderTypesRu.Vega Then
		vFileNamePrefix = "FrOrg";
	Else
		vFileNamePrefix = "form5case";
	EndIf;
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		Return Format(CurrentDate(), "DF=yyyyMMdd_HHmmss000_") + vFileNamePrefix + ".zip";
	ElsIf Receiver = Enums.GuestDataExportHeaderTypesRu.Vega Then
		Return vFileNamePrefix + pData + ".zip";
	Else
		Return vFileNamePrefix + "_" + Format(PeriodFrom, "DF=yyyy-MM-dd_HHmm") + "-" + Format(PeriodTo, "DF=yyyy-MM-dd_HHmm") + ".zip";
	EndIf;
EndFunction // pmGetForm5ZIPFileName

// -----------------------------------------------------------------------------
Function pmGetForm5FileName(pUID = "") Export 
	vFileNamePrefix = "mvd_rf";
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vFileNamePrefix = "RG";
	ElsIf Receiver = Enums.GuestDataExportHeaderTypesRu.Vega Then
		vFileNamePrefix = "FrOrg";
	Else
		vFileNamePrefix = "form5case";
	EndIf;
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		Return "OUT\" + pUID + "_" + Format(CurrentDate(), "DF=yyyyMMdd_HHmmss") + ".xml";
	ElsIf Receiver = Enums.GuestDataExportHeaderTypesRu.Vega Then
		Return "OUT\" + vFileNamePrefix + pUID + ".xml";
	Else
		Return "OUT\" + vFileNamePrefix + "_" + pUID + ".xml";
	EndIf;
EndFunction // pmGetForm5FileName

// -----------------------------------------------------------------------------
Function pmGetHouse(pHouseStr) Export
	vHouse = "";
	For vInd = 1 To StrLen(pHouseStr) Do
		vChar1 = lower(Mid(pHouseStr, vInd, 1));
		vChar2 = lower(Mid(pHouseStr, vInd, 2));
		vChar3 = lower(Mid(pHouseStr, vInd, 3));
		vChar4 = lower(Mid(pHouseStr, vInd, 4));
		If vChar2 = "к." Or vChar4 = "стр." Or vChar1 = "к" Or vChar3 = "стр" Then
			Break;
		Else
			vHouse = vHouse + vChar1;
		EndIf;
	EndDo;
	Return TrimAll(vHouse);
EndFunction // pmGetHouse

// -----------------------------------------------------------------------------
Function pmGetBuilding1(pHouseStr) Export
	vBuilding = "";
	vHouse = pmGetHouse(pHouseStr);
	If TrimAll(vHouse) <> TrimAll(pHouseStr) Then
		vBuilding = TrimAll(Mid(pHouseStr, StrLen(vHouse) + 1));
		If StrLen(vBuilding) > 0 Then
			If lower(Left(vBuilding, 2)) = "к." Then
				vBuilding = TrimAll(Mid(vBuilding, 3));
			ElsIf lower(Left(vBuilding, 1)) = "к" Then
				vBuilding = TrimAll(Mid(vBuilding, 2));
			EndIf;
		EndIf;
		vBuilding1 = "";
		For vInd = 1 To StrLen(vBuilding) Do
			vChar1 = lower(Mid(vBuilding, vInd, 1));
			vChar3 = lower(Mid(vBuilding, vInd, 3));
			vChar4 = lower(Mid(vBuilding, vInd, 4));
			If vChar4 = "стр." Then
				Break;
			ElsIf vChar3 = "стр" Then
				Break;
			Else
				vBuilding1 = vBuilding1 + vChar1;
			EndIf;
		EndDo;
		Return vBuilding1;
	Else
		Return vBuilding;
	EndIf;
EndFunction // pmGetBuilding1

// -----------------------------------------------------------------------------
Function pmGetBuilding2(pHouseStr) Export
	vBuilding2 = "";
	vHouse = pmGetHouse(pHouseStr);
	If TrimAll(vHouse) <> TrimAll(pHouseStr) Then
		vBuilding = TrimAll(Mid(pHouseStr, StrLen(vHouse) + 1));
		If StrLen(vBuilding) > 1 Then
			vStrFound = False;
			For vInd = 1 To StrLen(vBuilding) Do
				vChar1 = lower(Mid(vBuilding, vInd, 1));
				vChar3 = lower(Mid(vBuilding, vInd, 3));
				vChar4 = lower(Mid(vBuilding, vInd, 4));
				If vChar4 = "стр." Then
					vStrFound = True;
					vInd = vInd + 3;
					Continue;
				ElsIf vChar3 = "стр" Then
					vStrFound = True;
					vInd = vInd + 2;
					Continue;
				Else
					If vStrFound Then
						vBuilding2 = vBuilding2 + vChar1;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vBuilding2;
EndFunction // pmGetBuilding2

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function HexString(pBinaryData)
	Return GetHexStringFromBinaryData(pBinaryData);
EndFunction // HexString

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
Procedure CheckDirStructure(pDir)
	vDirPathIN = "";
	vDirPathOUT = "";
	If Right(TrimAll(pDir), 1) = "\" Or Right(TrimAll(pDir), 1) = "/" Then
		vDirPathOUT = TrimAll(pDir) + "OUT";
		vDirPathIN = TrimAll(pDir) + "IN";
	Else
		vDirPathOUT = TrimAll(pDir) + "\OUT";
		vDirPathIN = TrimAll(pDir) + "\IN";
	EndIf;
	vProbeDir = New File(vDirPathIN);
	If Not tcCommonFunctionOnClientServer.cmExists(vProbeDir) Or tcCommonFunctionOnClientServer.cmExists(vProbeDir) And Not vProbeDir.IsDirectory() Then
		CreateDirectory(vDirPathIN);
	EndIf;
	vProbeDir = New File(vDirPathOUT);
	If Not tcCommonFunctionOnClientServer.cmExists(vProbeDir) Or tcCommonFunctionOnClientServer.cmExists(vProbeDir) And Not vProbeDir.IsDirectory() Then
		CreateDirectory(vDirPathOUT);
	EndIf;
EndProcedure // CheckDirStructure

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
// Fill employee with default value
// -----------------------------------------------------------------------------
Procedure FillEmployee()
	// Get list of employees with permission to sign foreigner registration notification form
	vEmps = cmGetEmployeesWithPermissionToSignNotificationForm();
	// If the current employee is in the permitted list then use it
	vCurEmpRow = vEmps.Find(SessionParameters.CurrentUser, "Employee");
	If Not vCurEmpRow = Undefined Then
		Employee = SessionParameters.CurrentUser;
	Else
		// Choose first employee from the list
		If vEmps.Count() > 0 Then
			Employee = vEmps.Get(0).Employee;
		EndIf;
	EndIf;
EndProcedure // FillEmployee

// -----------------------------------------------------------------------------
Procedure AddError(pErrors, pErrorText, pDocument)
	vRow = pErrors.Add();
	vRow.Document = pDocument;
	vRow.ErrorText = pErrorText;
	// Write error to the system log
	WriteLogEvent(NStr("en='DataProcessor.ExportGuestsToUFMSTerritoryApp'; de='DataProcessor.ExportGuestsToUFMSTerritoryApp'; ru='Обработка.ЭкспортДанныхГостейВУФМС'"), EventLogLevel.Warning, Metadata.DataProcessors.ExportGuestsToUFMSTerritoryApp, pDocument, pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function GetForeignersRegistryRecords()
	vAccommodationNumbersList = New ValueList();
	For Each vAccRow In Accommodations Do
		If ValueIsFilled(vAccRow.Accommodation) Then
			If vAccommodationNumbersList.FindByValue(TrimR(vAccRow.Accommodation.Number)) = Undefined Then
				vAccommodationNumbersList.Add(TrimR(vAccRow.Accommodation.Number));
			EndIf;
		EndIf;
	EndDo;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ForeignerRegistryRecords.Date AS Period,
	|	ForeignerRegistryRecords.Ref AS RegistryRecord,
	|	ForeignerRegistryRecords.Number AS Number,
	|	ForeignerRegistryRecords.Date AS Date,
	|	ForeignerRegistryRecords.Room AS Room,
	|	ForeignerRegistryRecords.Guest AS Guest,
	|	ISNULL(Guests.FullName, """") AS FullName,
	|	ForeignerRegistryRecords.CheckInDate AS CheckInDate,
	|	ForeignerRegistryRecords.CheckOutDate AS CheckOutDate,
	|	ForeignerRegistryRecords.IsCheckedOut AS IsCheckedOut,
	|	ForeignerRegistryRecords.LastName AS LastName,
	|	ForeignerRegistryRecords.FirstName AS FirstName,
	|	ForeignerRegistryRecords.SecondName AS SecondName,
	|	ISNULL(Guests.LastName, """") AS LastNameLat,
	|	ISNULL(Guests.FirstName, """") AS FirstNameLat,
	|	ISNULL(Guests.SecondName, """") AS SecondNameLat,
	|	ForeignerRegistryRecords.Sex AS Sex,
	|	ForeignerRegistryRecords.Citizenship AS Citizenship,
	|	ForeignerRegistryRecords.Citizenship.Description AS CitizenshipDescription,
	|	ForeignerRegistryRecords.Citizenship.ISOCode3 AS CitizenshipISOCode3,
	|	ForeignerRegistryRecords.Citizenship.Code AS CitizenshipCode,
	|	ForeignerRegistryRecords.DateOfBirth AS DateOfBirth,
	|	ForeignerRegistryRecords.PlaceOfBirth AS PlaceOfBirth,
	|	ForeignerRegistryRecords.IdentityDocumentType AS IdentityDocumentType,
	|	ForeignerRegistryRecords.IdentityDocumentType.Code AS IdentityDocumentTypeCode,
	|	ForeignerRegistryRecords.IdentityDocumentType.ExternalCode AS IdentityDocumentTypeExternalCode,
	|	ForeignerRegistryRecords.IdentityDocumentSeries AS IdentityDocumentSeries,
	|	ForeignerRegistryRecords.IdentityDocumentNumber AS IdentityDocumentNumber,
	|	ForeignerRegistryRecords.IdentityDocumentIssueDate AS IdentityDocumentIssueDate,
	|	ForeignerRegistryRecords.IdentityDocumentValidToDate AS IdentityDocumentValidToDate,
	|	ForeignerRegistryRecords.IdentityDocumentUnitCode AS IdentityDocumentUnitCode,
	|	ForeignerRegistryRecords.IdentityDocumentIssuedBy AS IdentityDocumentIssuedBy,
	|	ForeignerRegistryRecords.TripPurpose AS TripPurpose,
	|	ForeignerRegistryRecords.TripPurpose.Code AS TripPurposeCode,
	|	ForeignerRegistryRecords.TripPurpose.ExternalCode AS TripPurposeID,
	|	ForeignerRegistryRecords.Profession AS Profession,
	|	ForeignerRegistryRecords.ArrivedFrom AS ArrivedFrom,
	|	ForeignerRegistryRecords.MigrationCardNumber AS MigrationCardNumber,
	|	ForeignerRegistryRecords.MigrationCardDateFrom AS MigrationCardDateFrom,
	|	ForeignerRegistryRecords.MigrationCardDateTo AS MigrationCardDateTo,
	|	ForeignerRegistryRecords.ResidencePermitDocument AS ResidencePermitDocument,
	|	ForeignerRegistryRecords.VisaNumber AS VisaNumber,
	|	ForeignerRegistryRecords.VisaType AS VisaType,
	|	ForeignerRegistryRecords.VisaType.Code AS VisaTypeCode,
	|	ForeignerRegistryRecords.VisaMultiplicity AS VisaMultiplicity,
	|	ForeignerRegistryRecords.VisaIdentifier AS VisaIdentifier,
	|	ForeignerRegistryRecords.VisaEntryGoal AS VisaEntryGoal,
	|	ForeignerRegistryRecords.VisaEntryGoal.Code AS VisaEntryGoalCode,
	|	ForeignerRegistryRecords.VisaIssuedDate AS VisaIssuedDate,
	|	ForeignerRegistryRecords.VisaIssuedBy AS VisaIssuedBy,
	|	ForeignerRegistryRecords.VisaFromDate AS VisaFromDate,
	|	ForeignerRegistryRecords.VisaToDate AS VisaToDate,
	|	ForeignerRegistryRecords.VisaDays AS VisaDays,
	|	ForeignerRegistryRecords.BorderCrossingDate AS BorderCrossingDate,
	|	ForeignerRegistryRecords.CheckPointNumber AS CheckPointNumber,
	|	ForeignerRegistryRecords.Route AS Route,
	|	ForeignerRegistryRecords.LegalRepresentatives AS LegalRepresentatives,
	|	ForeignerRegistryRecords.ReceivingParty AS ReceivingParty,
	|	ForeignerRegistryRecords.IsFromAbroad AS IsFromAbroad,
	|	ForeignerRegistryRecords.IsFirstArrival AS IsFirstArrival,
	|	ForeignerRegistryRecords.Standing AS Standing,
	|	ForeignerRegistryRecords.ExternalCode AS ExternalCode
	|FROM
	|	Document.ForeignerRegistryRecord AS ForeignerRegistryRecords
	|		LEFT JOIN Catalog.Clients AS Guests
	|		ON ForeignerRegistryRecords.Guest = Guests.Ref
	|WHERE
	|	ForeignerRegistryRecords.Posted
	|	AND ForeignerRegistryRecords.Date >= &qPeriodFrom
	|	AND ForeignerRegistryRecords.Date <= &qPeriodTo
	|	AND ForeignerRegistryRecords.CheckOutDate >= &qBegOfDayPeriodFrom
	|	AND (&qAccommodationNumbersListIsEmpty
	|			OR NOT &qAccommodationNumbersListIsEmpty
	|				AND ForeignerRegistryRecords.ParentDoc.Number IN (&qAccommodationNumbersList))
	|	AND ForeignerRegistryRecords.Hotel = &qHotel
	|	AND (&qCompanyIsFilled
	|				AND ForeignerRegistryRecords.ParentDoc.Company IN HIERARCHY (&qCompany)
	|			OR NOT &qCompanyIsFilled)
	|	AND NOT ForeignerRegistryRecords.GuestHasNotificationAlready
	|	AND CASE
	|			WHEN &qIgnoreEmptyGuests
	|				THEN NOT(ISNULL(Guests.LastName, """") = """"
	|							AND ISNULL(Guests.FirstName, """") = """")
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	ForeignerRegistryRecords.PointInTime";
	vQry.SetParameter("qBegOfDayPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodFrom", PeriodFrom);
	vQry.SetParameter("qPeriodTo", PeriodTo);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsFilled", ValueIsFilled(Company));
	vQry.SetParameter("qAccommodationNumbersList", vAccommodationNumbersList);
	vQry.SetParameter("qAccommodationNumbersListIsEmpty", ?(vAccommodationNumbersList.Count() = 0, True, False));
	vQry.SetParameter("qIgnoreEmptyGuests", IgnoreEmptyGuests);
	Return vQry.Execute().Unload();
EndFunction // GetForeignersRegistryRecords

// -----------------------------------------------------------------------------
Function GetForeignersExportValueTable(pRegistryRecords)
	// Initialize export value table
	vExportTable = New ValueTable();
    vExportTable.Columns.Add("RegistryRecord", cmGetDocumentTypeDescription("ForeignerRegistryRecord"));
    vExportTable.Columns.Add("Accommodation", cmGetDocumentTypeDescription("Accommodation"));
    vExportTable.Columns.Add("Guest", cmGetCatalogTypeDescription("Clients"));
	// Identification data																	// Field number in file
	vExportTable.Columns.Add("Period", cmGetDateTimeTypeDescription());						// 1 
	vExportTable.Columns.Add("RecordNumber", cmGetStringTypeDescription());					// 1 
	vExportTable.Columns.Add("RecordDate", cmGetDateTimeTypeDescription());					// 1 
	vExportTable.Columns.Add("GuestCode", cmGetStringTypeDescription());					// 2
	vExportTable.Columns.Add("FullName", cmGetStringTypeDescription());						// * 2
	vExportTable.Columns.Add("LastName", cmGetStringTypeDescription());						// * 3
	vExportTable.Columns.Add("FirstName", cmGetStringTypeDescription());					// * 4
	vExportTable.Columns.Add("SecondName", cmGetStringTypeDescription());					// 5
	vExportTable.Columns.Add("LastNameLat", cmGetStringTypeDescription());					// 6
	vExportTable.Columns.Add("FirstNameLat", cmGetStringTypeDescription());					// 7
	vExportTable.Columns.Add("SecondNameLat", cmGetStringTypeDescription());				// 8  
	vExportTable.Columns.Add("Sex");														// * 9
	vExportTable.Columns.Add("DateOfBirth", cmGetDateTypeDescription());					// * 10 дд.мм.гггг
	vExportTable.Columns.Add("Citizenship", cmGetStringTypeDescription());					// * 11
	vExportTable.Columns.Add("CitizenshipISOCode3", cmGetStringTypeDescription());			// * 11
	vExportTable.Columns.Add("CitizenshipCode", cmGetStringTypeDescription());				// * 11
	vExportTable.Columns.Add("PlaceOfBirthCountry", cmGetStringTypeDescription());			// 32 место рождения: государство
	vExportTable.Columns.Add("PlaceOfBirthCountryISOCode3", cmGetStringTypeDescription());	// 32 место рождения: государство
	vExportTable.Columns.Add("PlaceOfBirthCity", cmGetStringTypeDescription());				// 33 место рождения: город
	vExportTable.Columns.Add("PlaceOfBirthRegion", cmGetStringTypeDescription());			// 33 место рождения: регион
	vExportTable.Columns.Add("PlaceOfBirthArea", cmGetStringTypeDescription());             // 34 место рождения: Район  
	// Identity document data
	vExportTable.Columns.Add("IdentityDocumentType", cmGetCatalogTypeDescription("IdentityDocumentTypes")); // * 12 ИП - иностранный паспорт, УБ - удостоверение беженца
	vExportTable.Columns.Add("IdentityDocumentTypeCode", cmGetStringTypeDescription());						// * 12
	vExportTable.Columns.Add("IdentityDocumentTypeExternalCode", cmGetStringTypeDescription());				// * 12
	vExportTable.Columns.Add("IdentityDocumentSeries", cmGetStringTypeDescription());		// 13 серия документа, удостоверяющего личность
	vExportTable.Columns.Add("IdentityDocumentUnitCode", cmGetStringTypeDescription());		// код подразделения
	vExportTable.Columns.Add("IdentityDocumentIssuedBy", cmGetStringTypeDescription());		// кем выдано
	vExportTable.Columns.Add("IdentityDocumentNumber", cmGetStringTypeDescription());		// * 14 номер документа, удостоверяющего личность
	vExportTable.Columns.Add("IdentityDocumentIssueDate", cmGetDateTypeDescription());		// 29 дата выдачи документа удостоверяющего личность
	vExportTable.Columns.Add("IdentityDocumentValidToDate", cmGetDateTypeDescription());	// 30 срок действия документа удостоверяющего личность
	// Residence permit document
	vExportTable.Columns.Add("ResidencePermitDocument", cmGetEnumTypeDescription("ConfirmingDocuments"));
	// Visa data
	vExportTable.Columns.Add("VisaType", cmGetCatalogTypeDescription("VisaTypes"));			// 15 "В" - Виза, "ВЖ" - вид на жительство, "РВП" - разрешение на временное проживание
	vExportTable.Columns.Add("VisaTypeCode", cmGetStringTypeDescription());					// 15
	vExportTable.Columns.Add("VisaMultiplicity");											// 15a кратность визы
	vExportTable.Columns.Add("VisaNumber", cmGetStringTypeDescription());					// 26 номер документа, подтверждающего право на пребывание
	vExportTable.Columns.Add("VisaSeries", cmGetStringTypeDescription());					// 16 серия документа, подтверждающего право на пребывание
	vExportTable.Columns.Add("VisaIdentifier", cmGetStringTypeDescription());				// идентификатор визы
	vExportTable.Columns.Add("VisaIssuedDate", cmGetDateTypeDescription());					// 17 дата выдачи документа - визы
	vExportTable.Columns.Add("VisaIssuedBy", cmGetStringTypeDescription());					//    кем выдана виза
	vExportTable.Columns.Add("VisaFromDate", cmGetDateTypeDescription());					// 18 дата начала периода действия визы
	vExportTable.Columns.Add("VisaToDate", cmGetDateTypeDescription());						// 18 дата окончания периода действия визы
	vExportTable.Columns.Add("VisaEntryGoal", cmGetCatalogTypeDescription("EntryGoals"));	// Цель въезда по типу визы
	vExportTable.Columns.Add("VisaEntryGoalCode", cmGetStringTypeDescription());			// 
	vExportTable.Columns.Add("VisaDays", cmGetNumberTypeDescription(4, 0));					// 
	// Trip purpose	
	vExportTable.Columns.Add("TripPurpose", cmGetCatalogTypeDescription("TripPurposes"));	// 19 С - служебная, Т - туризм, К - коммерческая, У - учеба, Р - работа, Ч - частная, ТР - транзит, ДР - другая
	vExportTable.Columns.Add("TripPurposeCode", cmGetStringTypeDescription());				// 19
	vExportTable.Columns.Add("TripPurposeID", cmGetStringTypeDescription());				// 19
	// Migration card data
	vExportTable.Columns.Add("MigrationCardNumber", cmGetStringTypeDescription());			// 20 номер миграционной карты
	vExportTable.Columns.Add("MigrationCardSeries", cmGetStringTypeDescription());			// 28 серия миграционной карты
	vExportTable.Columns.Add("BorderCrossingDate", cmGetDateTypeDescription());				// * 24 дата въезда в РФ
	vExportTable.Columns.Add("MigrationCardDateFrom", cmGetDateTypeDescription());			// * 31 срок пребывания c
	vExportTable.Columns.Add("MigrationCardDateTo", cmGetDateTypeDescription());			// * 31 срок пребывания до
	vExportTable.Columns.Add("LegalRepresentatives", cmGetStringTypeDescription());			// 25 сведения о законных представителях
	vExportTable.Columns.Add("CouponLossCheck", cmGetStringTypeDescription());				// 27 отметка об утере отрывного талона (we do not have it yet)
	vExportTable.Columns.Add("CheckPointNumber", cmGetCatalogTypeDescription("CheckPoints"));	// 34 КПП въезда в РФ
	// Accommodation data	
	vExportTable.Columns.Add("Room", cmGetStringTypeDescription());							// 21 комната
    vExportTable.Columns.Add("CheckInDate", cmGetDateTypeDescription());					// * 22 дата заезда в гостиницу
    vExportTable.Columns.Add("ExpectedCheckOutDate", cmGetDateTypeDescription());			// 23 дата планируемого выезда из гостиницы
    vExportTable.Columns.Add("CheckOutDate", cmGetDateTypeDescription());					// 23 дата выезда из гостиницы
    vExportTable.Columns.Add("IsCheckedOut", cmGetBooleanTypeDescription());				// 
    vExportTable.Columns.Add("IsFirstArrival", cmGetBooleanTypeDescription());				// 
	vExportTable.Columns.Add("ExternalCode", cmGetStringTypeDescription());					// 8  
	
	// Fill table with data from foreigner registry records
	For Each vRegistryRecord In pRegistryRecords Do
		vDoc = vRegistryRecord.RegistryRecord;
		vAccDoc = vDoc.ParentDoc;
		vGuest = vRegistryRecord.Guest;

		vExpRow = vExportTable.Add();
		vExpRow.Period = vRegistryRecord.Period;
		
		vExpRow.RegistryRecord = vDoc;
		vExpRow.Accommodation = vAccDoc;
		vExpRow.Guest = vGuest;
		
		vExpRow.ExternalCode = vRegistryRecord.ExternalCode;
		
		vExpRow.RecordNumber = TrimAll(vDoc.Number);
		vExpRow.RecordDate = vRegistryRecord.Date;
		vExpRow.GuestCode = TrimAll(cmGetDocumentNumberPresentation(vDoc.Number));
		vExpRow.FullName = Upper(TrimAll(vRegistryRecord.FullName));
		
		// We expect that guest names are in russian language in the registry record
		If TrimAll(vRegistryRecord.LastName) <> "" Then
			vExpRow.LastName = Upper(TrimAll(vRegistryRecord.LastName));			
			vExpRow.FirstName = Upper(TrimAll(vRegistryRecord.FirstName));
			vExpRow.SecondName = Upper(TrimAll(vRegistryRecord.SecondName));
		Else
			vExpRow.LastName = Upper(TrimAll(vRegistryRecord.LastNameLat));			
			vExpRow.FirstName = Upper(TrimAll(vRegistryRecord.FirstNameLat));
			vExpRow.SecondName = Upper(TrimAll(vRegistryRecord.SecondNameLat));
		EndIf;
		vExpRow.LastNameLat = Upper(TrimAll(vRegistryRecord.LastNameLat));			
		vExpRow.FirstNameLat = Upper(TrimAll(vRegistryRecord.FirstNameLat));
		vExpRow.SecondNameLat = Upper(TrimAll(vRegistryRecord.SecondNameLat));
		
		If ValueIsFilled(vRegistryRecord.Sex) Then
			vExpRow.Sex = vRegistryRecord.Sex;
		Else
			vExpRow.Sex = vGuest.Sex;
		EndIf;
			
		If ValueIsFilled(vRegistryRecord.DateOfBirth) Then
			vExpRow.DateOfBirth = vRegistryRecord.DateOfBirth;
		Else
			vExpRow.DateOfBirth = vGuest.DateOfBirth;
		EndIf;

		If ValueIsFilled(vRegistryRecord.Citizenship) Then
			vExpRow.Citizenship = ?(ValueIsFilled(vRegistryRecord.Citizenship), vRegistryRecord.CitizenshipDescription, "");
			vExpRow.CitizenshipISOCode3 = ?(ValueIsFilled(vRegistryRecord.Citizenship), vRegistryRecord.CitizenshipISOCode3, "");
			vExpRow.CitizenshipCode = ?(ValueIsFilled(vRegistryRecord.Citizenship), vRegistryRecord.CitizenshipCode, "");
		Else
			vExpRow.Citizenship = ?(ValueIsFilled(vGuest.Citizenship), TrimAll(vGuest.Citizenship.Description), "");
			vExpRow.CitizenshipISOCode3 = ?(ValueIsFilled(vGuest.Citizenship), vGuest.Citizenship.ISOCode3, "");
			vExpRow.CitizenshipCode = ?(ValueIsFilled(vGuest.Citizenship), vGuest.Citizenship.Code, "");
		EndIf;
		
		If ValueIsFilled(vRegistryRecord.IdentityDocumentType) Then
			vExpRow.IdentityDocumentType = vRegistryRecord.IdentityDocumentType;
			vExpRow.IdentityDocumentTypeCode = TrimAll(vRegistryRecord.IdentityDocumentTypeCode);
			vExpRow.IdentityDocumentTypeExternalCode = TrimAll(vRegistryRecord.IdentityDocumentTypeExternalCode);
		ElsIf ValueIsFilled(vGuest.IdentityDocumentType) Then
			vExpRow.IdentityDocumentType = vGuest.IdentityDocumentType;
			vExpRow.IdentityDocumentTypeCode = TrimAll(vGuest.IdentityDocumentType.Code);
			vExpRow.IdentityDocumentTypeExternalCode = TrimAll(vGuest.IdentityDocumentType.ExternalCode);
		EndIf;

		If Not IsBlankString(vRegistryRecord.IdentityDocumentSeries) Then
			vExpRow.IdentityDocumentSeries = Upper(TrimAll(vRegistryRecord.IdentityDocumentSeries));
		Else
			vExpRow.IdentityDocumentSeries = Upper(TrimAll(vGuest.IdentityDocumentSeries));
		EndIf;
		
		If Not IsBlankString(vRegistryRecord.IdentityDocumentNumber) Then
			vExpRow.IdentityDocumentNumber = Upper(StrReplace(TrimAll(vRegistryRecord.IdentityDocumentNumber), " ", ""));
		Else
			vExpRow.IdentityDocumentNumber = Upper(StrReplace(TrimAll(vGuest.IdentityDocumentNumber), " ", ""));
		EndIf;

		If ValueIsFilled(vRegistryRecord.IdentityDocumentIssueDate) Then
			vExpRow.IdentityDocumentIssueDate = vRegistryRecord.IdentityDocumentIssueDate;
		Else
			vExpRow.IdentityDocumentIssueDate = vGuest.IdentityDocumentIssueDate;
		EndIf;
		
		If ValueIsFilled(vRegistryRecord.IdentityDocumentValidToDate) Then
			vExpRow.IdentityDocumentValidToDate = vRegistryRecord.IdentityDocumentValidToDate;
		Else
			vExpRow.IdentityDocumentValidToDate = vGuest.IdentityDocumentValidToDate;
		EndIf;
		
		If Not IsBlankString(vRegistryRecord.IdentityDocumentUnitCode) Then
			vExpRow.IdentityDocumentUnitCode = Upper(StrReplace(TrimAll(vRegistryRecord.IdentityDocumentUnitCode), " ", ""));
		Else
			vExpRow.IdentityDocumentUnitCode = Upper(StrReplace(TrimAll(vGuest.IdentityDocumentUnitCode), " ", ""));
		EndIf;
		
		If Not IsBlankString(vRegistryRecord.IdentityDocumentIssuedBy) Then
			vExpRow.IdentityDocumentIssuedBy = Upper(TrimAll(vRegistryRecord.IdentityDocumentIssuedBy));
		Else
			vExpRow.IdentityDocumentIssuedBy = Upper(TrimAll(vGuest.IdentityDocumentIssuedBy));
		EndIf;
		
		// Residence permit document
		vExpRow.ResidencePermitDocument = vRegistryRecord.ResidencePermitDocument;
		
		// Visa
		vExpRow.VisaType = vRegistryRecord.VisaType;
		vExpRow.VisaTypeCode = TrimAll(vRegistryRecord.VisaTypeCode);
		vExpRow.VisaMultiplicity = vRegistryRecord.VisaMultiplicity;
		vVisaNumber = TrimAll(vRegistryRecord.VisaNumber);
		vEndOfSeries = Find(vVisaNumber, " ");
		While vEndOfSeries > 0 Do
			vVisaNumber = TrimAll(Mid(vVisaNumber, vEndOfSeries));
			vEndOfSeries = Find(vVisaNumber, " ");
		EndDo;
		vExpRow.VisaSeries = "";
		vExpRow.VisaNumber = vVisaNumber;
		If TrimAll(vRegistryRecord.VisaNumber) <> vVisaNumber Then
			vExpRow.VisaSeries = TrimAll(Left(TrimAll(vRegistryRecord.VisaNumber), StrLen(TrimAll(vRegistryRecord.VisaNumber)) - StrLen(vVisaNumber)));
		EndIf;
		vExpRow.VisaIssuedDate = vRegistryRecord.VisaIssuedDate;
		vExpRow.VisaIssuedBy = TrimR(vRegistryRecord.VisaIssuedBy);
		vExpRow.VisaFromDate = vRegistryRecord.VisaFromDate;
		vExpRow.VisaToDate = vRegistryRecord.VisaToDate; 
		vExpRow.VisaEntryGoal = vRegistryRecord.VisaEntryGoal; 
		vExpRow.VisaEntryGoalCode = TrimAll(vRegistryRecord.VisaEntryGoalCode); 
		vExpRow.VisaIdentifier = TrimAll(vRegistryRecord.VisaIdentifier);
		vExpRow.VisaDays = vRegistryRecord.VisaDays;
		
		// Trip purpose
		vExpRow.TripPurpose = vRegistryRecord.TripPurpose;
		vExpRow.TripPurposeCode = TrimAll(vRegistryRecord.TripPurposeCode);
		vExpRow.TripPurposeID = TrimAll(vRegistryRecord.TripPurposeID);

		// Migration card
		vMigrationCardNumber = Upper(TrimAll(vRegistryRecord.MigrationCardNumber));
		vEndOfSeries = Find(vMigrationCardNumber, " ");
		While vEndOfSeries > 0 Do
			vMigrationCardNumber = TrimAll(Mid(vMigrationCardNumber, vEndOfSeries));
			vEndOfSeries = Find(vMigrationCardNumber, " ");
		EndDo;
		vExpRow.MigrationCardSeries = "";
		vExpRow.MigrationCardNumber = vMigrationCardNumber;
		If Upper(TrimAll(vRegistryRecord.MigrationCardNumber)) <> vMigrationCardNumber Then
			vExpRow.MigrationCardSeries = TrimAll(Left(TrimAll(vRegistryRecord.MigrationCardNumber), StrLen(TrimAll(vRegistryRecord.MigrationCardNumber)) - StrLen(vMigrationCardNumber)));
		EndIf;
		vExpRow.BorderCrossingDate = vRegistryRecord.BorderCrossingDate;
		vExpRow.MigrationCardDateFrom = vRegistryRecord.MigrationCardDateFrom; 
		vExpRow.MigrationCardDateTo = vRegistryRecord.MigrationCardDateTo; 
		vExpRow.CheckPointNumber = vRegistryRecord.CheckPointNumber;
		
		vExpRow.LegalRepresentatives = TrimAll(StrReplace(vRegistryRecord.LegalRepresentatives, Chars.LF, " "));
		
		vExpRow.PlaceOfBirthCountry = "";
		vExpRow.PlaceOfBirthCountryISOCode3 = "";
		vExpRow.PlaceOfBirthCity = "";
		vExpRow.PlaceOfBirthRegion = "";
		vExpRow.PlaceOfBirthArea = "";
		vPlaceOfBirth = "";
		If TrimAll(vRegistryRecord.PlaceOfBirth) <> "" Then
			vPlaceOfBirth = TrimAll(vRegistryRecord.PlaceOfBirth);
		ElsIf TrimAll(vGuest.PlaceOfBirth) <> "" Then
			vPlaceOfBirth = TrimAll(vGuest.PlaceOfBirth);
		EndIf;
		If Not IsBlankString(vPlaceOfBirth) Then
			vAddressItems = cmParseAddress(vPlaceOfBirth);
			If ValueIsFilled(vAddressItems.Country) Then
				vExpRow.PlaceOfBirthCountry = TrimAll(vAddressItems.Country.Description);
				vExpRow.PlaceOfBirthCountryISOCode3 = TrimAll(vAddressItems.Country.ISOCode3);
			EndIf;
			If Not IsBlankString(vAddressItems.Region) Then
				vExpRow.PlaceOfBirthRegion = TrimAll(vAddressItems.Region);
			EndIf;
			If Not IsBlankString(vAddressItems.Area) Then
				vExpRow.PlaceOfBirthArea = TrimAll(vAddressItems.Area);
			EndIf;
			If Not IsBlankString(vAddressItems.City) Then
				vExpRow.PlaceOfBirthCity = TrimAll(vAddressItems.City);
			EndIf;
		EndIf;
		
		vExpRow.CouponLossCheck = "";
		
		// Accommodation data
		vExpRow.Room = Upper(TrimAll(vRegistryRecord.Room));  
		vExpRow.CheckInDate = vRegistryRecord.CheckInDate;
		vExpRow.ExpectedCheckOutDate = vRegistryRecord.CheckOutDate;
		vExpRow.IsCheckedOut = vRegistryRecord.IsCheckedOut;
		vExpRow.CheckOutDate = Undefined;
		If ValueIsFilled(vRegistryRecord.CheckOutDate) Then
			If BegOfDay(vRegistryRecord.CheckOutDate) <= BegOfDay(CurrentSessionDate()) And vRegistryRecord.IsCheckedOut Then
				vExpRow.CheckOutDate = vRegistryRecord.CheckOutDate;
			EndIf;
		EndIf;
		
		// Is first arrival
		vExpRow.IsFirstArrival = vRegistryRecord.IsFirstArrival;
	EndDo;
	
	Return vExportTable;
EndFunction // GetForeignersExportValueTable

// -----------------------------------------------------------------------------
Function CheckForeignersData(vErrors, pExportTable)
   	// Check each row in the export table
	For Each vRow In pExportTable Do
		If IsBlankString(vRow.Guest) Then
			AddError(vErrors, 
			         NStr("en = 'The guest registration document does not contains a guest!';
					 	  |de = 'Das Gästebuch enthält keinen Gast!';
						  |ru = 'В документе регистрации иностранного гражданина не указан гость!'"), 
			         vRow.RegistryRecord);
		EndIf;
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost And 
	   	   Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
			If IsBlankString(HotelAddress) Then
				AddError(vErrors, 
			         	 NStr("en='Your hotel address should be received from UMMS and stored in the data processor settings!'; 
				           	  |ru='Адрес вашей гостиницы нужно получить в УФМС и сохранить в настройках обработки!'; 
						      |de='Ihre Hoteladresse sollte gespeichert werden!'"), 
			         	 vRow.RegistryRecord);
			EndIf;
		EndIf;
		If TrimAll(vRow.LastName) = "" Then // * 3
			AddError(vErrors, 
			         NStr("ru = 'Не заполнена ФАМИЛИЯ';  
			              |de = 'LASTNAME is empty'; 
			              |en = 'LASTNAME is empty'"), 
			         vRow.RegistryRecord);
		Else
			vFirstChar = Upper(Left(TrimAll(vRow.LastName), 1));
			If Find("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ", vFirstChar) = 0 Then
				AddError(vErrors,
						 NStr("en='Names should be in russian language in notification'; 
				           	  |ru='ФИО в уведомлении должно указываться по-русски'; 
						      |de='Namen sollten in der russischen Sprache in der Mitteilung'"), 
			         	 vRow.RegistryRecord);
			EndIf; 
		EndIf;
		If TrimAll(vRow.FirstName) = "" Then // * 4
			AddError(vErrors, 
			         NStr("ru = 'Не заполнено ИМЯ'; 
					      |de = 'FIRSTNAME is empty'; 
			              |en = 'FIRSTNAME is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		If TrimAll(vRow.Sex) = "" Then // * 9
			AddError(vErrors, 
			         NStr("ru = 'Не заполнен ПОЛ'; 
					      |de = 'SEX is empty';
			              |en = 'SEX is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
	   	vDateOfBirth = vRow.DateOfBirth;
		If Not ValueIsFilled(vDateOfBirth) Then // * 10
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
	   	If TrimAll(vRow.CitizenshipISOCode3) = "" Then // * 11
	   		AddError(vErrors, 
			         NStr("ru = 'Не указано ГРАЖДАНСТВО'; 
					      |de = 'CITIZENSHIP is empty'; 
			              |en = 'CITIZENSHIP is empty'"), 
			         vRow.RegistryRecord);
		ElsIf ValueIsFilled(Hotel.Citizenship) And 
		      TrimAll(vRow.CitizenshipISOCode3) = TrimAll(Hotel.Citizenship.ISOCode3) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ГРАЖДАНСТВО указано не верно (" + TrimAll(vRow.CitizenshipISOCode3) + ")'; 
					      |de = 'CITIZENSHIP is probably wrong (" + TrimAll(vRow.CitizenshipISOCode3) + ")'; 
					      |en = 'CITIZENSHIP is probably wrong (" + TrimAll(vRow.CitizenshipISOCode3) + ")'"), 
			         vRow.RegistryRecord);
		EndIf;          
		vIdentityDocumentType = vRow.IdentityDocumentType;	
		vCheckVisa = True;
		vCheckMigrationCard = True;
		If ValueIsFilled(vIdentityDocumentType) Then
			vCheckVisa = Not vIdentityDocumentType.DoNotCheckVisa;
			vCheckMigrationCard = Not vIdentityDocumentType.DoNotCheckMigrationCard;	
		EndIf;	
	   	If TrimAll(vIdentityDocumentType) = "" Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указан ВИД ДУЛ'; 
					      |de = 'IDENTITY DOCUMENT TYPE is empty'; 
			              |en = 'IDENTITY DOCUMENT TYPE is empty'"), 
			         vRow.RegistryRecord);
		Else
			If IsBlankString(vRow.IdentityDocumentTypeExternalCode) Then
				AddError(vErrors, 
				         NStr("en='You have to refresh identity document types catalog! Please open identity document types list and press <Load> button.'; 
				              |ru='Необходимо обновить справочник видов документов удостоверяющих личность! Откройте справочник и нажмите кнопку <Загрузить> в панели инструментов списка.'; 
						      |de='Sie müssen aktualisieren Identität Dokumenttypen Katalog! Bitte offenen Identität Dokumenttypen Liste und drücken Sie <Laden> Taste.'"), 
				         vRow.RegistryRecord);	
			EndIf;			 
		EndIf;
		If TrimAll(vRow.IdentityDocumentNumber) = "" Then // * 14
	   		AddError(vErrors, 
			         NStr("ru = 'Не указан НОМЕР ДУЛ'; 
					      |de = 'IDENTITY DOCUMENT NUMBER is empty'; 
			              |en = 'IDENTITY DOCUMENT NUMBER is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		If vCheckMigrationCard And TrimAll(vRow.TripPurpose) = "" Then // 19 С - служебная, Т - туризм, К - коммерческая, У - учеба, Р - работа, Ч - частная, ТР - транзит, Д - деловая, ДР - другая
	   		AddError(vErrors, 
			         NStr("ru = 'Не указана ЦЕЛЬ ПОЕЗДКИ'; 
					      |de = 'TRIP PURPOSE is empty'; 
			              |en = 'TRIP PURPOSE is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vRegRecord = vRow.RegistryRecord;
			vLegalRep = vRegRecord.LegalRepresentative;
			If ValueIsFilled(vLegalRep) Then
				vLegalRepLastName = TrimAll(vRegRecord.LegalRepresentativeLastName);
				If IsBlankString(vLegalRepLastName) Then
					vLegalRepLastName = TrimAll(vLegalRep.LastName);
				EndIf;
				vFirstChar = Upper(Left(TrimAll(vLegalRepLastName), 1));
				If Find("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ", vFirstChar) = 0 Then
					AddError(vErrors, 
			         		 StrTemplate(NStr("en='Names should be in russian language in notification for person %1'; 
								           	  |ru='ФИО в уведомлении должно указываться по-русски у представителя %1'; 
										   	  |de='Namen sollten in der russischen Sprache in der Mitteilung für die Gäste sein %1'"), TrimAll(vLegalRep.FullName)), 
			         		 vRow.RegistryRecord);
				EndIf;
				If Not ValueIsFilled(vLegalRep.Sex) Then
					AddError(vErrors, 
			         		 StrTemplate(NStr("en='Sex is missing for person %1'; 
							           		  |ru='Пол не указан у представителя %1'; 
									   		  |de='Sex wird für die Gäste fehlen %1'"), TrimAll(vLegalRep.FullName)),
			         		 vRow.RegistryRecord);	
				EndIf;
				If ValueIsFilled(vLegalRep.IdentityDocumentType) Then
					vLegalRepIdentityDocumentType = vLegalRep.IdentityDocumentType;
					If IsBlankString(vLegalRepIdentityDocumentType.ExternalCode) Then
						AddError(vErrors, 
			         		 	 NStr("en='You have to refresh identity document types catalog! Please open identity document types list and press <Load> button.'; 
						           	  |ru='Необходимо обновить справочник видов документов удостоверяющих личность! Откройте справочник и нажмите кнопку <Загрузить> в панели инструментов списка.'; 
								   	  |de='Sie müssen aktualisieren Identität Dokumenttypen Katalog! Bitte offenen Identität Dokumenttypen Liste und drücken Sie <Laden> Taste.'"), 
			         		 	 vRow.RegistryRecord);
					EndIf;
				Else
					AddError(vErrors, 
			         		 StrTemplate(NStr("en='Identity document type is missing for person %1'; 
								           	  |ru='Тип документа удостоверяющего личность не указан у представителя %1'; 
										   	  |de='Identität Dokumenttyp wird für die Gäste fehlen %1'"), TrimAll(vLegalRep.FullName)),
			         		 vRow.RegistryRecord);
				EndIf;
			EndIf;		
		EndIf;
		If vCheckVisa And (vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.Visa Or vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.ElectronicVisa) Then
			If ValueIsFilled(vRow.VisaType) Then
				If IsBlankString(vRow.VisaType.Code) Then
					AddError(vErrors, 
			         		 NStr("en='You have to refresh visa types catalog! Please open visa types list and press <Load> button.'; 
					           	  |ru='Необходимо обновить справочник типов виз! Откройте справочник и нажмите кнопку <Загрузить> в панели инструментов списка.'; 
							   	  |de='Sie müssen aktualisieren Visumtypen Katalog! Bitte offenen Liste und drücken Sie <Laden> Taste.'"), 
			         		 vRow.RegistryRecord);
				EndIf;
			Else
				AddError(vErrors, 
			         	StrTemplate(NStr("en='Visa type is missing for guest %1'; 
							           	  |ru='Тип визы не указан у гостя  %1'; 
									   	  |de='Visumtyp wird für die Gäste fehlen %1'"), TrimAll(vRow.FullName)), 
			         	 vRow.RegistryRecord);
			EndIf;
			If IsBlankString(vRow.VisaMultiplicity) Then
				AddError(vErrors, 
			         	 StrTemplate(NStr("en='Visa multiplicity is missing for guest %1'; 
						           		  |ru='Кратность визы не указана у гостя %1'; 
								   		  |de='Visum Vielzahl wird für die Gäste fehlen %1'"), TrimAll(vRow.FullName)), 
			         	 vRow.RegistryRecord);	
			EndIf;
			If IsBlankString(vRow.VisaEntryGoal) Then
				AddError(vErrors, 
			         	 StrTemplate(NStr("en='Entry goal is missing for guest %1'; 
						           	 	  |ru='Цель въезда не указана у гостя %1'; 
								   		  |de='Eintrag Ziel wird für die Gäste fehlen %1'"), TrimAll(vRow.FullName)), 
			         	 vRow.RegistryRecord);
			EndIf;  
			If IsBlankString(vRow.VisaNumber) Then
				AddError(vErrors, 
			         	 StrTemplate(NStr("en = 'Visa number is missing for guest %1'; 
						 				  |de = 'Für den Gast fehlt die Visumnummer %1'; 
										  |ru = 'Номер визы не указан у гостя %1'"), TrimAll(vRow.FullName)), 
			         	 vRow.RegistryRecord);
			EndIf;
		EndIf;
		If vCheckMigrationCard And ValueIsFilled(vRow.MigrationCardNumber) Then
			If IsBlankString(vRow.MigrationCardDateFrom) Then
				AddError(vErrors, 
			         	 StrTemplate(NStr("en='Migration card date from should be filled for guest %1'; 
				           	  |ru='Дата начала срока пребывания по миграционной карте не указана у гостя %1'; 
						   	  |de='Aufenthaltszeitraum nach Migrationskarte von Datum ist nicht angegeben für der Gast %1'"), TrimAll(vRow.FullName)), 
			         	 vRow.RegistryRecord);
			EndIf;
			If IsBlankString(vRow.BorderCrossingDate) Then
				AddError(vErrors, 
			         	 StrTemplate(NStr("en='Border crossing date should be filled for guest %1'; 
				           	  |ru='Дата пересечения границы не указана у гостя %1'; 
						   	  |de='Datum des Grenzübergangs ist nicht angegeben für der Gast %1'"), TrimAll(vRow.FullName)), 
			         	 vRow.RegistryRecord);
			EndIf;
			If IsBlankString(vRow.CheckPointNumber) Then
				AddError(vErrors, 
			         	 StrTemplate(NStr("en='Check point should be filled for guest %1'; 
			           		  |ru='Контрольно-пропускной пункт не указан у гостя %1'; 
					   		  |de='Nummer des Kontrolle- und Durchgangspunkts ist nicht angegeben für der Gast %1'"), TrimAll(vRow.FullName)), 
			         	 vRow.RegistryRecord);	
			EndIf;
		EndIf;
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost And 
	   	   Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
		   If IsBlankString(HotelCode) Then
				AddError(vErrors, 
			         	 NStr("en='Hotel code should be filled!'; 
					       	  |ru='Код гостиницы должен быть указан!'; 
				           	  |de='Hotelcode gefüllt werden sollen!'"), 
			         	 vRow.RegistryRecord);
			EndIf;
			If IsBlankString(OfficialOrganCode) Then
				AddError(vErrors, 
			         	 NStr("en='UMMS official organ code should be filled!'; 
					       	  |ru='Код отделения УФМС должен быть указан!'; 
				           	  |de='UMMS code gefüllt werden sollen!'"), 
			         	 vRow.RegistryRecord);
			EndIf;
			If IsBlankString(NoticeFromID) Then
				AddError(vErrors, 
			         	 NStr("en='Notice from ID should be filled!'; 
					       	  |ru='ID типа организации должен быть указан!'; 
				           	  |de='Mitteilung ID gefüllt werden sollen!'"), 
			         	 vRow.RegistryRecord);
			EndIf;
			If IsBlankString(Company) Then
				AddError(vErrors, 
			         	 NStr("en='Company should be filled!'; 
				           	  |ru='Фирма должна быть указана!'; 
						   	  |de='Kompanie sollten gefüllt werden!'"), 
			         	 vRow.RegistryRecord);
			Else
				If IsBlankString(Company.TIN) Then
					AddError(vErrors, 
			         	 	 NStr("en='Company TIN should be filled!'; 
					           	  |ru='ИНН фирмы должен быть указан!'; 
							   	  |de='Kompanie TIN sollten gefüllt werden!'"), 
			         	 vRow.RegistryRecord);
				EndIf;
			EndIf;
			If IsBlankString(CompanyAddress) Then
				AddError(vErrors, 
			         	 NStr("en='Company address should be filled!'; 
				           	  |ru='Адрес фирмы должен быть указан!'; 
						   	  |de='Kompanieadresse sollten gefüllt werden!'"), 
			         	 vRow.RegistryRecord);
			EndIf;
			If IsBlankString(Employee) Then
				AddError(vErrors, 
			         	 NStr("en='Employee should be filled!'; 
				           	  |ru='Сотрудник должен быть указан!'; 
						   	  |de='Mitarbeiter sollten gefüllt werden!'"), 
			         	 vRow.RegistryRecord);
			Else
				If IsBlankString(Employee.LastName) Then
					AddError(vErrors, 
			         	 	 NStr("en='Employee last name should be filled!'; 
					           	  |ru='Фамилия сотрудника должна быть указана!'; 
							   	  |de='Mitarbeiter Nachnamen sollte gefüllt werden!'"), 
			         	 	 vRow.RegistryRecord);
				EndIf;
				If IsBlankString(Employee.FirstName) Then
					AddError(vErrors, 
			         	 	 NStr("en='Employee first name should be filled!'; 
					           	  |ru='Имя сотрудника должно быть указано!'; 
							   	  |de='Mitarbeiter Vorname sollte gefüllt werden!'"), 
			         		 vRow.RegistryRecord);
				EndIf;
				If IsBlankString(Employee.Sex) Then
					AddError(vErrors, 
			         	 	 NStr("en='Employee gender should be filled!'; 
					           	  |ru='Пол сотрудника должен быть указан!'; 
							   	  |de='Mitarbeiter Sex sollte gefüllt werden!'"), 
			         	 	 vRow.RegistryRecord);
				EndIf;
				If IsBlankString(Employee.DateOfBirth) Then
					AddError(vErrors, 
			         	 	 NStr("en='Employee date of birth should be filled!'; 
					           	  |ru='Дата рождения сотрудника должен быть указан!'; 
							   	  |de='Mitarbeiter Geburtsdatum sollte gefüllt werden!'"), 
			         	 	 vRow.RegistryRecord);
				EndIf;
				If IsBlankString(Employee.IdentityDocumentType) Then
					AddError(vErrors, 
			         	 	 NStr("en='Employee identity document type should be filled!'; 
					           	  |ru='Тип документа удостоверяющего личность сотрудника должен быть указан!'; 
							   	  |de='Mitarbeiter Ausweisestyp muss angegeben werden!'"), 
			         	 	 vRow.RegistryRecord);
				EndIf;
				If IsBlankString(Employee.IdentityDocumentNumber) Then
					AddError(vErrors, 
			         	 	 NStr("en='Employee identity document number should be filled!'; 
					           	  |ru='Номер документа удостоверяющего личность сотрудника должен быть указан!'; 
							   	  |de='Mitarbeiter Ausweisesnummer muss angegeben werden!'"), 
			         	 	 vRow.RegistryRecord);
				EndIf;
				If IsBlankString(Employee.IdentityDocumentUnitCode) Then
					AddError(vErrors, 
			         	 	 NStr("en='Employee identity document unit code should be filled!'; 
					           	  |ru='Код подразделения выдавшего документ удостоверяющий личность сотрудника должен быть указан!'; 
							   	  |de='Mitarbeiter Ausweisdokument Vorort-Code muss angegeben werden!'"), 
			         	 	 vRow.RegistryRecord);
				EndIf;
				If IsBlankString(Employee.IdentityDocumentIssueDate) Then
					AddError(vErrors, 
			         	 	 NStr("en='Employee identity document issue date should be filled!'; 
					           	  |ru='Дата выдачи документа удостоверяющего личность сотрудника должна быть указана!'; 
							   	  |de='Mitarbeiter Ausweisdokument Ausgabedatum muss angegeben werden!'"), 
			         	 	 vRow.RegistryRecord);
				EndIf; 		 
				vOfficialOrganID = GetOfficialOrganID(TrimAll(Employee.IdentityDocumentUnitCode), TrimAll(Employee.IdentityDocumentIssuedBy));
				If IsBlankString(vOfficialOrganID) Then
					AddError(vErrors, 
			         	 	 NStr("en='Employee identity document unit code is wrong!'; 
					           	  |ru='Код подразделения выдавшего документ удостоверяющий личность сотрудника указан не верно!'; 
							   	  |de='Mitarbeiter Ausweisdokument Vorort-Code nicht wahr ist!'"), 
			         	 	 vRow.RegistryRecord);
				EndIf;		 
			EndIf;			
		EndIf;   
		If vCheckMigrationCard Then
			If ValueIsFilled(vRow.TripPurpose) Then
				If IsBlankString(vRow.TripPurposeID) Then
					AddError(vErrors, 
					NStr("en='Trip purpose UMMS ID is empty! Please reload trip purposes list.'; 
					|ru='Не заполнен ID цели приезда! Пожалуйста перезаполните справочник <Цели приезда> по кнопке <Заполнить> в панели инструментов списка целей.'; 
					|de='Reiseziel UMMS ID ist leer! Bitte laden Reiseziel Liste.'"), 
					vRow.RegistryRecord);
				EndIf;
			Else
				AddError(vErrors, 
				NStr("en='Trip purpose should be filled for guest " + TrimAll(vRow.FullName) + "'; 
				|ru='Цель приезда не указана у гостя " + TrimAll(vRow.FullName) + "'; 
				|de='Reiseziel ist nicht angegeben für der Gast " + TrimAll(vRow.FullName) + "'"), 
				vRow.RegistryRecord);
			EndIf;  
		EndIf;
		vCheckInDate = vRow.CheckInDate;
		If Not ValueIsFilled(vCheckInDate) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указана ДАТА ЗАЕЗДА'; 
					      |de = 'CHECK IN DATE is empty'; 
			              |en = 'CHECK IN DATE is empty'"), 
			         vRow.RegistryRecord);
		ElsIf vCheckInDate > CurrentSessionDate() Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ДАТА ЗАЕЗДА указана не верно (" + Format(vRow.CheckInDate, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'CHECK IN DATE is probably wrong (" + Format(vRow.CheckInDate, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'CHECK IN DATE is probably wrong (" + Format(vRow.CheckInDate, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.RegistryRecord);
		EndIf;
		vCheckOutDate = vRow.ExpectedCheckOutDate;
		If ValueIsFilled(vCheckOutDate) Then
			If vCheckOutDate < vCheckInDate Then
		   		AddError(vErrors, 
				         NStr("ru = 'Возможно ДАТА ВЫЕЗДА указана не верно (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'; 
						      |de = 'CHECK OUT DATE is probably wrong (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'; 
						      |en = 'CHECK OUT DATE is probably wrong (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'"), 
				         vRow.RegistryRecord);
			EndIf;
		EndIf;
		vBorderCrossingDate = vRow.BorderCrossingDate;
		If Not ValueIsFilled(vBorderCrossingDate) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указана ДАТА ВЪЕЗДА В РФ'; 
					      |de = 'BORDER CROSSING DATE is empty'; 
			              |en = 'BORDER CROSSING DATE is empty'"), 
			         vRow.RegistryRecord);
		ElsIf vBorderCrossingDate > CurrentSessionDate() Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ДАТА ВЪЕЗДА В РФ указана не верно (" + Format(vRow.BorderCrossingDate, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'BORDER CROSSING DATE is probably wrong (" + Format(vRow.BorderCrossingDate, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'BORDER CROSSING DATE is probably wrong (" + Format(vRow.BorderCrossingDate, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.RegistryRecord);
		EndIf;
		If ValueIsFilled(vBorderCrossingDate) And ValueIsFilled(vCheckInDate) And vBorderCrossingDate > vCheckInDate Then
			AddError(vErrors, 
			         NStr("ru = 'ДАТА ВЪЕЗДА В РФ превышает дату прибытия'; 
					      |de = 'BORDER CROSSING DATE is later then check-in date'; 
			              |en = 'BORDER CROSSING DATE is later then check-in date'"), 
			         vRow.RegistryRecord);
		EndIf;    
		If vCheckMigrationCard Then		 
			vMigrationCardDateTo = vRow.MigrationCardDateTo;
			If ValueIsFilled(vMigrationCardDateTo) And (vMigrationCardDateTo < vCheckInDate Or vMigrationCardDateTo < vCheckOutDate) Then
				AddError(vErrors, 
				NStr("ru = 'Возможно СРОК ПРЕБЫВАНИЯ ДО указан не верно (" + Format(vRow.MigrationCardDateTo, "DF=dd.MM.yyyy") + ")'; 
					 |de = 'MIGRATION CARD DATE TO is probably wrong (" + Format(vRow.MigrationCardDateTo, "DF=dd.MM.yyyy") + ")'; 
					 |en = 'MIGRATION CARD DATE TO is probably wrong (" + Format(vRow.MigrationCardDateTo, "DF=dd.MM.yyyy") + ")'"), 
				vRow.RegistryRecord);
			EndIf;    
			vIdentityDocumentValidToDate = vRow.IdentityDocumentValidToDate;
			If vRow.RegistryRecord.Citizenship.IsVisaNecessaryForEntrance And Not ValueIsFilled(vIdentityDocumentValidToDate) Then
				AddError(vErrors, 
				NStr("ru = 'Не указан срок действия документа удостоверяющего личность'; 
					 |de = 'Identity document valid till date should be filled'; 
					 |en = 'Identity document valid till date should be filled'"), 
				vRow.RegistryRecord);
			EndIf;
			If vRow.RegistryRecord.Citizenship.IsVisaNecessaryForEntrance And ValueIsFilled(vIdentityDocumentValidToDate) And vMigrationCardDateTo > vIdentityDocumentValidToDate Then
				AddError(vErrors, 
				NStr("ru = 'СРОК ПРЕБЫВАНИЯ ДО не должен превышать срок действия документа удостоверяющего личность (" + Format(vRow.IdentityDocumentValidToDate, "DF=dd.MM.yyyy") + ")'; 
							|de = 'MIGRATION CARD DATE TO could not be later then identity document valid till date (" + Format(vRow.IdentityDocumentValidToDate, "DF=dd.MM.yyyy") + ")'; 
							|en = 'MIGRATION CARD DATE TO could not be later then identity document valid till date (" + Format(vRow.IdentityDocumentValidToDate, "DF=dd.MM.yyyy") + ")'"), 
				vRow.RegistryRecord);
			EndIf;  
		EndIf;		 
		vIdentityDocumentIssueDate = vRow.IdentityDocumentIssueDate;
		If ValueIsFilled(vIdentityDocumentIssueDate) And ValueIsFilled(vIdentityDocumentValidToDate) And vIdentityDocumentIssueDate >= vIdentityDocumentValidToDate Then
	   		AddError(vErrors, 
			         NStr("ru = 'Дата выдачи документа удостоверяющего личность превышает срок действия (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'Identity document issue date could not be later then identity document valid till date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'Identity document issue date could not be later then identity document valid till date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.RegistryRecord);
		EndIf;
		If ValueIsFilled(vIdentityDocumentIssueDate) And ValueIsFilled(vDateOfBirth) And vIdentityDocumentIssueDate < vDateOfBirth Then
	   		AddError(vErrors, 
			         NStr("ru = 'Дата выдачи документа удостоверяющего личность раньше даты рождения (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'Identity document issue date could not be earlier then guest birth date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'Identity document issue date could not be earlier then guest birth date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.RegistryRecord);
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
Function CheckForeignersVegaData(vErrors, pExportTable)
	// Check each row in the export table
	For Each vRow In pExportTable Do
		If IsBlankString(vRow.Guest) Then
			AddError(vErrors, 
			         NStr("en = 'The guest registration document does not contains a guest!';
					 	  |de = 'Das Gästebuch enthält keinen Gast!';
						  |ru = 'В документе регистрации иностранного гражданина не указан гость!'"), 
			         vRow.RegistryRecord);
		EndIf;
		If TrimAll(vRow.LastName) = "" Then // *3
			AddError(vErrors, 
			         NStr("ru = 'Не заполнена ФАМИЛИЯ';  
			              |de = 'LASTNAME is empty'; 
			              |en = 'LASTNAME is empty'"), 
			         vRow.RegistryRecord);
		Else
			vFirstChar = Upper(Left(TrimAll(vRow.LastName), 1));
			If Find("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ", vFirstChar) = 0 Then
				AddError(vErrors,
						 NStr("en='Names should be in russian language in notification'; 
				           	  |ru='ФИО в уведомлении должно указываться по-русски'; 
						      |de='Namen sollten in der russischen Sprache in der Mitteilung'"), 
			         	 vRow.RegistryRecord);
			EndIf; 
		EndIf;
		If TrimAll(vRow.FirstName) = "" Then // * 4
			AddError(vErrors, 
			         NStr("ru = 'Не заполнено ИМЯ'; 
					      |de = 'FIRSTNAME is empty'; 
			              |en = 'FIRSTNAME is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		If TrimAll(vRow.Sex) = "" Then // * 9
			AddError(vErrors, 
			         NStr("ru = 'Не заполнен ПОЛ'; 
					      |de = 'SEX is empty';
			              |en = 'SEX is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
	   	vDateOfBirth = vRow.DateOfBirth;
		If Not ValueIsFilled(vDateOfBirth) Then // * 10
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
	   	If TrimAll(vRow.Citizenship) = "" Then // * 11
	   		AddError(vErrors, 
			         NStr("ru = 'Не указано ГРАЖДАНСТВО'; 
					      |de = 'CITIZENSHIP is empty'; 
			              |en = 'CITIZENSHIP is empty'"), 
			         vRow.RegistryRecord);
		ElsIf ValueIsFilled(Hotel.Citizenship) And 
		      TrimAll(vRow.CitizenshipISOCode3) = TrimAll(Hotel.Citizenship.ISOCode3) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ГРАЖДАНСТВО указано не верно (" + TrimAll(vRow.CitizenshipISOCode3) + ")'; 
					      |de = 'CITIZENSHIP is probably wrong (" + TrimAll(vRow.CitizenshipISOCode3) + ")'; 
					      |en = 'CITIZENSHIP is probably wrong (" + TrimAll(vRow.CitizenshipISOCode3) + ")'"), 
			         vRow.RegistryRecord);
		EndIf;
	   	If TrimAll(vRow.IdentityDocumentType) = "" Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указан ВИД ДУЛ'; 
					      |de = 'IDENTITY DOCUMENT TYPE is empty'; 
			              |en = 'IDENTITY DOCUMENT TYPE is empty'"), 
			         vRow.RegistryRecord);			 
		EndIf;     
		vIdentityDocumentType = vRow.IdentityDocumentType;	
		vCheckVisa = True;
		vCheckMigrationCard = True;
		If ValueIsFilled(vIdentityDocumentType) Then
			vCheckVisa = Not vIdentityDocumentType.DoNotCheckVisa;
			vCheckMigrationCard = Not vIdentityDocumentType.DoNotCheckMigrationCard;	
		EndIf;	
		If TrimAll(vRow.IdentityDocumentNumber) = "" Then // * 14
	   		AddError(vErrors, 
			         NStr("ru = 'Не указан НОМЕР ДУЛ'; 
					      |de = 'IDENTITY DOCUMENT NUMBER is empty'; 
			              |en = 'IDENTITY DOCUMENT NUMBER is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		If vCheckMigrationCard And TrimAll(vRow.TripPurpose) = "" Then // 19 С - служебная, Т - туризм, К - коммерческая, У - учеба, Р - работа, Ч - частная, ТР - транзит, Д - деловая, ДР - другая
	   		AddError(vErrors, 
			         NStr("ru = 'Не указана ЦЕЛЬ ПОЕЗДКИ'; 
					      |de = 'TRIP PURPOSE is empty'; 
			              |en = 'TRIP PURPOSE is empty'"), 
			         vRow.RegistryRecord);
		EndIf;
		If vCheckVisa And Not IsBlankString(vRow.VisaNumber) And (vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.Visa Or vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.ElectronicVisa) Then
			If IsBlankString(vRow.VisaType) Then
				AddError(vErrors, 
			         	 NStr("en='Visa type is missing for guest " + TrimAll(vRow.FullName) + "'; 
				           	  |ru='Тип визы не указан у гостя " + TrimAll(vRow.FullName) + "'; 
						   	  |de='Visumtyp wird für die Gäste fehlen " + TrimAll(vRow.FullName) + "'"), 
			         	 vRow.RegistryRecord);
			EndIf;
			If IsBlankString(vRow.VisaMultiplicity) Then
				AddError(vErrors, 
			         	 NStr("en='Visa multiplicity is missing for guest " + TrimAll(vRow.FullName) + "'; 
			           		  |ru='Кратность визы не указана у гостя " + TrimAll(vRow.FullName) + "'; 
					   		  |de='Visum Vielzahl wird für die Gäste fehlen " + TrimAll(vRow.FullName) + "'"), 
			         	 vRow.RegistryRecord);	
			EndIf;
			If IsBlankString(vRow.VisaEntryGoal) Then
				AddError(vErrors, 
			         	 NStr("en='Entry goal is missing for guest " + TrimAll(vRow.FullName) + "'; 
			           	 	  |ru='Цель въезда не указана у гостя " + TrimAll(vRow.FullName) + "'; 
					   		  |de='Eintrag Ziel wird für die Gäste fehlen " + TrimAll(vRow.FullName) + "'"), 
			         	 vRow.RegistryRecord);
			EndIf;
		EndIf;
		If vCheckMigrationCard And ValueIsFilled(vRow.MigrationCardNumber) Then
			If IsBlankString(vRow.MigrationCardDateFrom) Then
				AddError(vErrors, 
			         	 NStr("en='Migration card date from should be filled for guest " + TrimAll(vRow.FullName) + "'; 
				           	  |ru='Дата начала срока пребывания по миграционной карте не указана у гостя " + TrimAll(vRow.FullName) + "'; 
						   	  |de='Aufenthaltszeitraum nach Migrationskarte von Datum ist nicht angegeben für der Gast " + TrimAll(vRow.FullName) + "'"), 
			         	 vRow.RegistryRecord);
			EndIf;
			If IsBlankString(vRow.BorderCrossingDate) Then
				AddError(vErrors, 
			         	 NStr("en='Border crossing date should be filled for guest " + TrimAll(vRow.FullName) + "'; 
				           	  |ru='Дата пересечения границы не указана у гостя " + TrimAll(vRow.FullName) + "'; 
						   	  |de='Datum des Grenzübergangs ist nicht angegeben für der Gast " + TrimAll(vRow.FullName) + "'"), 
			         	 vRow.RegistryRecord);
			EndIf;
			If IsBlankString(vRow.CheckPointNumber) Then
				AddError(vErrors, 
			         	 NStr("en='Check point should be filled for guest " + TrimAll(vRow.FullName) + "'; 
			           		  |ru='Контрольно-пропускной пункт не указан у гостя " + TrimAll(vRow.FullName) + "'; 
					   		  |de='Nummer des Kontrolle- und Durchgangspunkts ist nicht angegeben für der Gast " + TrimAll(vRow.FullName) + "'"), 
			         	 vRow.RegistryRecord);	
			EndIf;
	   EndIf;
	   If IsBlankString(HotelCode) Then
			AddError(vErrors, 
		         	 NStr("en='Hotel code should be filled!'; 
				       	  |ru='Код гостиницы должен быть указан!'; 
			           	  |de='Hotelcode gefüllt werden sollen!'"), 
		         	 vRow.RegistryRecord);
		EndIf;
		If vCheckMigrationCard And IsBlankString(vRow.TripPurpose) Then
			AddError(vErrors, 
			         NStr("en='Trip purpose should be filled for guest " + TrimAll(vRow.FullName) + "'; 
						  |ru='Цель приезда не указана у гостя " + TrimAll(vRow.FullName) + "'; 
						  |de='Reiseziel ist nicht angegeben für der Gast " + TrimAll(vRow.FullName) + "'"), 
			         vRow.RegistryRecord);
		EndIf;
		vCheckInDate = vRow.CheckInDate;
		If Not ValueIsFilled(vCheckInDate) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указана ДАТА ЗАЕЗДА'; 
					      |de = 'CHECK IN DATE is empty'; 
			              |en = 'CHECK IN DATE is empty'"), 
			         vRow.RegistryRecord);
		ElsIf vCheckInDate > CurrentSessionDate() Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ДАТА ЗАЕЗДА указана не верно (" + Format(vRow.CheckInDate, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'CHECK IN DATE is probably wrong (" + Format(vRow.CheckInDate, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'CHECK IN DATE is probably wrong (" + Format(vRow.CheckInDate, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.RegistryRecord);
		EndIf;
		vCheckOutDate = vRow.ExpectedCheckOutDate;
		If ValueIsFilled(vCheckOutDate) Then
			If vCheckOutDate < vCheckInDate Then
		   		AddError(vErrors, 
				         NStr("ru = 'Возможно ДАТА ВЫЕЗДА указана не верно (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'; 
						      |de = 'CHECK OUT DATE is probably wrong (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'; 
						      |en = 'CHECK OUT DATE is probably wrong (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'"), 
				         vRow.RegistryRecord);
			EndIf;
		EndIf;
		vBorderCrossingDate = vRow.BorderCrossingDate;
		If Not ValueIsFilled(vBorderCrossingDate) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указана ДАТА ВЪЕЗДА В РФ'; 
					      |de = 'BORDER CROSSING DATE is empty'; 
			              |en = 'BORDER CROSSING DATE is empty'"), 
			         vRow.RegistryRecord);
		ElsIf vBorderCrossingDate > CurrentSessionDate() Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ДАТА ВЪЕЗДА В РФ указана не верно (" + Format(vRow.BorderCrossingDate, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'BORDER CROSSING DATE is probably wrong (" + Format(vRow.BorderCrossingDate, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'BORDER CROSSING DATE is probably wrong (" + Format(vRow.BorderCrossingDate, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.RegistryRecord);
		EndIf;
		If ValueIsFilled(vBorderCrossingDate) And ValueIsFilled(vCheckInDate) And vBorderCrossingDate > vCheckInDate Then
			AddError(vErrors, 
			         NStr("ru = 'ДАТА ВЪЕЗДА В РФ превышает дату прибытия'; 
					      |de = 'BORDER CROSSING DATE is later then check-in date'; 
			              |en = 'BORDER CROSSING DATE is later then check-in date'"), 
			         vRow.RegistryRecord);
		EndIf;   
		If vCheckMigrationCard Then		 
			vMigrationCardDateTo = vRow.MigrationCardDateTo;
			If ValueIsFilled(vMigrationCardDateTo) And (vMigrationCardDateTo < vCheckInDate Or vMigrationCardDateTo < vCheckOutDate) Then
				AddError(vErrors, 
				NStr("ru = 'Возможно СРОК ПРЕБЫВАНИЯ ДО указан не верно (" + Format(vRow.MigrationCardDateTo, "DF=dd.MM.yyyy") + ")'; 
					 |de = 'MIGRATION CARD DATE TO is probably wrong (" + Format(vRow.MigrationCardDateTo, "DF=dd.MM.yyyy") + ")'; 
					 |en = 'MIGRATION CARD DATE TO is probably wrong (" + Format(vRow.MigrationCardDateTo, "DF=dd.MM.yyyy") + ")'"), 
				vRow.RegistryRecord);
			EndIf;
			vIdentityDocumentValidToDate = vRow.IdentityDocumentValidToDate;
			If vRow.RegistryRecord.Citizenship.IsVisaNecessaryForEntrance And Not ValueIsFilled(vIdentityDocumentValidToDate) Then
				AddError(vErrors, 
				NStr("ru = 'Не указан срок действия документа удостоверяющего личность'; 
					 |de = 'Identity document valid till date should be filled'; 
					 |en = 'Identity document valid till date should be filled'"), 
				vRow.RegistryRecord);
			EndIf;    
			
			If vRow.RegistryRecord.Citizenship.IsVisaNecessaryForEntrance And ValueIsFilled(vIdentityDocumentValidToDate) And vMigrationCardDateTo > vIdentityDocumentValidToDate Then
				AddError(vErrors, 
				NStr("ru = 'СРОК ПРЕБЫВАНИЯ ДО не должен превышать срок действия документа удостоверяющего личность (" + Format(vRow.IdentityDocumentValidToDate, "DF=dd.MM.yyyy") + ")'; 
					 |de = 'MIGRATION CARD DATE TO could not be later then identity document valid till date (" + Format(vRow.IdentityDocumentValidToDate, "DF=dd.MM.yyyy") + ")'; 
					 |en = 'MIGRATION CARD DATE TO could not be later then identity document valid till date (" + Format(vRow.IdentityDocumentValidToDate, "DF=dd.MM.yyyy") + ")'"), 
				vRow.RegistryRecord);
			EndIf;  
		EndIf;		 
		vIdentityDocumentIssueDate = vRow.IdentityDocumentIssueDate;
		If ValueIsFilled(vIdentityDocumentIssueDate) And ValueIsFilled(vIdentityDocumentValidToDate) And vIdentityDocumentIssueDate >= vIdentityDocumentValidToDate Then
	   		AddError(vErrors, 
			         NStr("ru = 'Дата выдачи документа удостоверяющего личность превышает срок действия (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'Identity document issue date could not be later then identity document valid till date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'Identity document issue date could not be later then identity document valid till date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.RegistryRecord);
		EndIf;
		If ValueIsFilled(vIdentityDocumentIssueDate) And ValueIsFilled(vDateOfBirth) And vIdentityDocumentIssueDate < vDateOfBirth Then
	   		AddError(vErrors, 
			         NStr("ru = 'Дата выдачи документа удостоверяющего личность раньше даты рождения (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'Identity document issue date could not be earlier then guest birth date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'Identity document issue date could not be earlier then guest birth date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.RegistryRecord);
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
Function GetForm5RegistryRecords()
	vAccommodationNumbersList = New ValueList();
	For Each vAccRow In Accommodations Do
		If ValueIsFilled(vAccRow.Accommodation) Then
			If vAccommodationNumbersList.FindByValue(TrimR(vAccRow.Accommodation.Number)) = Undefined Then
				vAccommodationNumbersList.Add(TrimR(vAccRow.Accommodation.Number));
			EndIf;
		EndIf;
	EndDo;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationChangeHistoryRecords.Period AS Period,
	|	AccommodationChangeHistoryRecords.Accommodation AS Accommodation,
	|	AccommodationChangeHistoryRecords.Accommodation.Number AS Number,
	|	AccommodationChangeHistoryRecords.Accommodation.Date AS Date,
	|	AccommodationStateAtPeriodTo.Room AS Room,
	|	CASE
	|		WHEN NOT AccommodationStateAtPeriodFrom.CheckOutDate IS NULL
	|				AND BEGINOFPERIOD(AccommodationStateAtPeriodFrom.CheckOutDate, DAY) < BEGINOFPERIOD(AccommodationStateAtPeriodTo.CheckOutDate, DAY)
	|			THEN AccommodationStateAtPeriodFrom.CheckOutDate
	|		ELSE AccommodationStateAtPeriodTo.CheckInDate
	|	END AS CheckInDate,
	|	AccommodationStateAtPeriodTo.CheckOutDate AS CheckOutDate,
	|	AccommodationStateAtPeriodTo.AccommodationStatus.IsInHouse AS IsInHouse,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest AS Guest,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.FullName AS FullName,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.LastName AS LastName,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.FirstName AS FirstName,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.SecondName AS SecondName,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.Sex AS Sex,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.Citizenship AS Citizenship,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.Citizenship.Description AS CitizenshipDescription,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.Citizenship.ISOCode3 AS CitizenshipISOCode3,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.Citizenship.Code AS CitizenshipCode,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.DateOfBirth AS DateOfBirth,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.PlaceOfBirth AS PlaceOfBirth,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.Address AS Address,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.IdentityDocumentType AS IdentityDocumentType,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.IdentityDocumentType.Code AS IdentityDocumentTypeCode,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.IdentityDocumentType.ExternalCode AS IdentityDocumentTypeExternalCode,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.IdentityDocumentSeries AS IdentityDocumentSeries,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.IdentityDocumentNumber AS IdentityDocumentNumber,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.IdentityDocumentIssueDate AS IdentityDocumentIssueDate,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.IdentityDocumentValidToDate AS IdentityDocumentValidToDate,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.IdentityDocumentUnitCode AS IdentityDocumentUnitCode,
	|	AccommodationStateAtPeriodTo.Accommodation.Guest.IdentityDocumentIssuedBy AS IdentityDocumentIssuedBy,
	|	AccommodationStateAtPeriodTo.TripPurpose AS TripPurpose,
	|	AccommodationStateAtPeriodTo.TripPurpose.Code AS TripPurposeCode,
	|	AccommodationStateAtPeriodTo.TripPurpose.ExternalCode AS TripPurposeID,
	|	NOT AccommodationStateAtPeriodTo.AccommodationStatus.IsInHouse AS IsCheckedOut,
	|	AccommodationStateAtPeriodFrom.CheckInDate AS PrevCheckInDate,
	|	AccommodationStateAtPeriodFrom.CheckOutDate AS PrevCheckOutDate,
	|	AccommodationChangeHistoryRecords.Accommodation.LegalRepresentative AS LegalRepresentative,
	|	AccommodationChangeHistoryRecords.Accommodation.RelationType AS RelationType
	|FROM
	|	(SELECT
	|		AccommodationChangeHistory.Accommodation AS Accommodation,
	|		MAX(AccommodationChangeHistory.Period) AS Period
	|	FROM
	|		InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|	WHERE
	|		AccommodationChangeHistory.Period >= &qPeriodFrom
	|		AND AccommodationChangeHistory.Period <= &qPeriodTo
	|		AND AccommodationChangeHistory.Accommodation.Hotel = &qHotel
	|		AND AccommodationChangeHistory.Accommodation.Posted
	|		AND AccommodationChangeHistory.Accommodation.AccommodationStatus.IsActive
	|		AND (&qCompanyIsFilled
	|					AND AccommodationChangeHistory.Company IN HIERARCHY (&qCompany)
	|				OR NOT &qCompanyIsFilled)
	|		AND (NOT &qExportVirtualGuests
	|					AND NOT AccommodationChangeHistory.Accommodation.Room.IsVirtual
	|				OR &qExportVirtualGuests)
	|		AND AccommodationChangeHistory.Accommodation.Hotel.Citizenship = AccommodationChangeHistory.Accommodation.Guest.Citizenship
	|	
	|	GROUP BY
	|		AccommodationChangeHistory.Accommodation) AS AccommodationChangeHistoryRecords
	|		LEFT JOIN (SELECT
	|			AccommodationChangeHistorySliceLast.Period AS Period,
	|			AccommodationChangeHistorySliceLast.Accommodation AS Accommodation,
	|			AccommodationChangeHistorySliceLast.CheckInDate AS CheckInDate,
	|			AccommodationChangeHistorySliceLast.CheckOutDate AS CheckOutDate
	|		FROM
	|			InformationRegister.AccommodationChangeHistory.SliceLast(&qPeriodFrom, ) AS AccommodationChangeHistorySliceLast) AS AccommodationStateAtPeriodFrom
	|		ON AccommodationChangeHistoryRecords.Accommodation = AccommodationStateAtPeriodFrom.Accommodation
	|		LEFT JOIN InformationRegister.AccommodationChangeHistory AS AccommodationStateAtPeriodTo
	|		ON AccommodationChangeHistoryRecords.Accommodation = AccommodationStateAtPeriodTo.Accommodation
	|			AND AccommodationChangeHistoryRecords.Period = AccommodationStateAtPeriodTo.Period
	|		LEFT JOIN Catalog.Clients AS Guests
	|		ON AccommodationChangeHistoryRecords.Accommodation.Guest = Guests.Ref
	|WHERE
	|	(AccommodationStateAtPeriodFrom.CheckOutDate IS NULL
	|			OR BEGINOFPERIOD(AccommodationStateAtPeriodFrom.CheckOutDate, DAY) < BEGINOFPERIOD(AccommodationStateAtPeriodTo.CheckOutDate, DAY))
	|	AND (&qLocalRegion <> &qPercentChar
	|				AND NOT AccommodationStateAtPeriodTo.Guest.Region LIKE &qLocalRegion
	|			OR &qLocalRegion = &qPercentChar)
	|	AND AccommodationStateAtPeriodTo.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|	AND AccommodationChangeHistoryRecords.Accommodation.CheckOutDate >= &qBegOfPeriodFrom
	|	AND (&qAccommodationNumbersListIsEmpty
	|			OR NOT &qAccommodationNumbersListIsEmpty
	|				AND AccommodationChangeHistoryRecords.Accommodation.Number IN (&qAccommodationNumbersList))
	|	AND CASE
	|			WHEN &qIgnoreEmptyGuests
	|				THEN NOT(ISNULL(Guests.LastName, """") = """"
	|							AND ISNULL(Guests.FirstName, """") = """")
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	AccommodationChangeHistoryRecords.Accommodation.PointInTime";
	vQry.SetParameter("qPeriodFrom", PeriodFrom);
	vQry.SetParameter("qBegOfPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", PeriodTo);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qLocalRegion", TrimAll(Hotel.Region) + "%");
	vQry.SetParameter("qPercentChar", "%");
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsFilled", ValueIsFilled(Company));
	vQry.SetParameter("qExportVirtualGuests", ExportVirtualGuests);
	vQry.SetParameter("qAccommodationNumbersList", vAccommodationNumbersList);
	vQry.SetParameter("qAccommodationNumbersListIsEmpty", ?(vAccommodationNumbersList.Count() = 0, True, False));
	vQry.SetParameter("qIgnoreEmptyGuests", IgnoreEmptyGuests);
	Return vQry.Execute().Unload();
EndFunction // GetForm5RegistryRecords

// -----------------------------------------------------------------------------
Function GetForm5ExportValueTable(pForm5Records)
	// Initialize export value table
	vExportTable = New ValueTable();
    vExportTable.Columns.Add("Accommodation", cmGetDocumentTypeDescription("Accommodation"));
    vExportTable.Columns.Add("Guest", cmGetCatalogTypeDescription("Clients"));
	// Identification data																	// Field number in file
	vExportTable.Columns.Add("Period", cmGetDateTimeTypeDescription());						// 1 
	vExportTable.Columns.Add("DocNumber", cmGetStringTypeDescription());					// 1 
	vExportTable.Columns.Add("DocDate", cmGetDateTimeTypeDescription());					// 1 
	vExportTable.Columns.Add("GuestCode", cmGetStringTypeDescription());					// 2
	vExportTable.Columns.Add("FullName", cmGetStringTypeDescription());						// * 2
	vExportTable.Columns.Add("LastName", cmGetStringTypeDescription());						// * 3
	vExportTable.Columns.Add("FirstName", cmGetStringTypeDescription());					// * 4
	vExportTable.Columns.Add("SecondName", cmGetStringTypeDescription());					// 5
	vExportTable.Columns.Add("Sex");														// * 9
	vExportTable.Columns.Add("DateOfBirth", cmGetDateTypeDescription());					// * 10 дд.мм.гггг
	vExportTable.Columns.Add("Citizenship", cmGetStringTypeDescription());					// * 11
	vExportTable.Columns.Add("CitizenshipISOCode3", cmGetStringTypeDescription());			// * 11
	vExportTable.Columns.Add("CitizenshipCode", cmGetStringTypeDescription());				// * 11
	vExportTable.Columns.Add("PlaceOfBirthCountry", cmGetStringTypeDescription());			// 32 место рождения: государство
	vExportTable.Columns.Add("PlaceOfBirthCountryISOCode3", cmGetStringTypeDescription());	// 32 место рождения: государство
	vExportTable.Columns.Add("PlaceOfBirthCountryCode", cmGetStringTypeDescription());		// 32 место рождения: государство
	vExportTable.Columns.Add("PlaceOfBirthCity", cmGetStringTypeDescription());				// 33 место рождения: город
	vExportTable.Columns.Add("PlaceOfBirthRegion", cmGetStringTypeDescription());			// 33 место рождения: город
	vExportTable.Columns.Add("Address", cmGetStringTypeDescription());						// 34 адрес проживания
	vExportTable.Columns.Add("PlaceOfBirthArea", cmGetStringTypeDescription());             // 35 место рождения: Район
	// Identity document data
	vExportTable.Columns.Add("IdentityDocumentType", cmGetCatalogTypeDescription("IdentityDocumentTypes")); // * 12 ИП - иностранный паспорт, УБ - удостоверение беженца
	vExportTable.Columns.Add("IdentityDocumentTypeCode", cmGetStringTypeDescription());						// * 12
	vExportTable.Columns.Add("IdentityDocumentTypeExternalCode", cmGetStringTypeDescription());				// * 12
	vExportTable.Columns.Add("IdentityDocumentSeries", cmGetStringTypeDescription());		// 13 серия документа, удостоверяющего личность
	vExportTable.Columns.Add("IdentityDocumentUnitCode", cmGetStringTypeDescription());		// код подразделения
	vExportTable.Columns.Add("IdentityDocumentIssuedBy", cmGetStringTypeDescription());		// кем выдано
	vExportTable.Columns.Add("IdentityDocumentNumber", cmGetStringTypeDescription());		// * 14 номер документа, удостоверяющего личность
	vExportTable.Columns.Add("IdentityDocumentIssueDate", cmGetDateTypeDescription());		// 29 дата выдачи документа удостоверяющего личность
	vExportTable.Columns.Add("IdentityDocumentValidToDate", cmGetDateTypeDescription());	// 30 срок действия документа удостоверяющего личность
	// Trip purpose	
	vExportTable.Columns.Add("TripPurpose", cmGetCatalogTypeDescription("TripPurposes"));	// 19 С - служебная, Т - туризм, К - коммерческая, У - учеба, Р - работа, Ч - частная, ТР - транзит, ДР - другая
	vExportTable.Columns.Add("TripPurposeCode", cmGetStringTypeDescription());				// 19
	vExportTable.Columns.Add("TripPurposeID", cmGetStringTypeDescription());				// 19
	// Accommodation data	
	vExportTable.Columns.Add("Room", cmGetStringTypeDescription());							// 21 комната
    vExportTable.Columns.Add("CheckInDate", cmGetDateTypeDescription());					// * 22 дата заезда в гостиницу
    vExportTable.Columns.Add("ExpectedCheckOutDate", cmGetDateTypeDescription());			// 23 дата планируемого выезда из гостиницы
    vExportTable.Columns.Add("CheckOutDate", cmGetDateTypeDescription());					// 23 дата выезда из гостиницы
    vExportTable.Columns.Add("IsInHouse", cmGetBooleanTypeDescription());					// 
	vExportTable.Columns.Add("LegalRepresentative", );										//
	vExportTable.Columns.Add("RelationType", );												//

	// Fill table with data from records
	For Each vRecord In pForm5Records Do
		vDoc = vRecord.Accommodation;
		vGuest = vRecord.Guest;

		vExpRow = vExportTable.Add();
		vExpRow.Period = vRecord.Period;
		
		vExpRow.Accommodation = vDoc;
		vExpRow.Guest = vGuest;
		
		vExpRow.DocNumber = TrimAll(vDoc.Number);
		vExpRow.DocDate = vRecord.Date;
		vExpRow.GuestCode = TrimAll(cmGetDocumentNumberPresentation(vDoc.Number));
		vExpRow.FullName = Upper(TrimAll(vRecord.FullName));
		
		// We expect that guest names are in russian language in the registry record
		vExpRow.LastName = Upper(TrimAll(vRecord.LastName));			
		vExpRow.FirstName = Upper(TrimAll(vRecord.FirstName));
		vExpRow.SecondName = Upper(TrimAll(vRecord.SecondName));
	
		vExpRow.Sex = vRecord.Sex;
			
		vExpRow.DateOfBirth = vRecord.DateOfBirth;

		vExpRow.Citizenship = ?(ValueIsFilled(vRecord.Citizenship), vRecord.CitizenshipDescription, "");
		vExpRow.CitizenshipISOCode3 = ?(ValueIsFilled(vRecord.Citizenship), vRecord.CitizenshipISOCode3, "");
		vExpRow.CitizenshipCode = ?(ValueIsFilled(vRecord.Citizenship), vRecord.CitizenshipCode, "");
		
		vExpRow.IdentityDocumentType = vRecord.IdentityDocumentType;
		vExpRow.IdentityDocumentTypeCode = TrimAll(vRecord.IdentityDocumentTypeCode);
		vExpRow.IdentityDocumentTypeExternalCode = TrimAll(vRecord.IdentityDocumentTypeExternalCode);
		vExpRow.IdentityDocumentSeries = Upper(TrimAll(vRecord.IdentityDocumentSeries));
		vExpRow.IdentityDocumentNumber = Upper(StrReplace(TrimAll(vRecord.IdentityDocumentNumber), " ", ""));
		vExpRow.IdentityDocumentIssueDate = vRecord.IdentityDocumentIssueDate;
		vExpRow.IdentityDocumentValidToDate = vRecord.IdentityDocumentValidToDate;
		vExpRow.IdentityDocumentUnitCode = Upper(StrReplace(TrimAll(vRecord.IdentityDocumentUnitCode), " ", ""));
		vExpRow.IdentityDocumentIssuedBy = Upper(TrimAll(vRecord.IdentityDocumentIssuedBy));
		
		// Trip purpose
		vExpRow.TripPurpose = vRecord.TripPurpose;
		vExpRow.TripPurposeCode = TrimAll(vRecord.TripPurposeCode);
		vExpRow.TripPurposeID = TrimAll(vRecord.TripPurposeID);
		
		vExpRow.PlaceOfBirthCountry = "";
		vExpRow.PlaceOfBirthCountryISOCode3 = "";
		vExpRow.PlaceOfBirthCity = "";
		vExpRow.PlaceOfBirthRegion = "";
		vExpRow.PlaceOfBirthArea = "";
		vPlaceOfBirth = "";
		If TrimAll(vRecord.PlaceOfBirth) <> "" Then
			vPlaceOfBirth = TrimAll(vRecord.PlaceOfBirth);
		ElsIf TrimAll(vGuest.PlaceOfBirth) <> "" Then
			vPlaceOfBirth = TrimAll(vGuest.PlaceOfBirth);
		EndIf;
		If Not IsBlankString(vPlaceOfBirth) Then
			vAddressItems = cmParseAddress(vPlaceOfBirth);
			If ValueIsFilled(vAddressItems.Country) Then
				vExpRow.PlaceOfBirthCountry = TrimAll(vAddressItems.Country.Description);
				vExpRow.PlaceOfBirthCountryISOCode3 = TrimAll(vAddressItems.Country.ISOCode3);
			EndIf;
			If Not IsBlankString(vAddressItems.City) Then
				vExpRow.PlaceOfBirthCity = TrimAll(vAddressItems.City);
			EndIf;
			If Not IsBlankString(vAddressItems.Area) Then
				vExpRow.PlaceOfBirthArea = TrimAll(vAddressItems.Area);
			EndIf;
			If Not IsBlankString(vAddressItems.Region) Then
				vExpRow.PlaceOfBirthRegion = TrimAll(vAddressItems.Region);
			EndIf;
		EndIf;
		vExpRow.Address = TrimAll(vRecord.Address);
		
		// Accommodation data
		vExpRow.Room = Upper(TrimAll(vRecord.Room));  
		vExpRow.CheckInDate = vRecord.CheckInDate;
		vExpRow.ExpectedCheckOutDate = vRecord.CheckOutDate;
		vExpRow.IsInHouse = vRecord.IsInHouse;
		vExpRow.CheckOutDate = Undefined;
		If ValueIsFilled(vRecord.CheckOutDate) Then
			If BegOfDay(vRecord.CheckOutDate) <= BegOfDay(CurrentSessionDate()) And Not vExpRow.IsInHouse Then
				vExpRow.CheckOutDate = vRecord.CheckOutDate;
			EndIf;
		EndIf;
		vExpRow.LegalRepresentative = vRecord.LegalRepresentative;
		vExpRow.RelationType = vRecord.RelationType;

	EndDo;
	
	Return vExportTable;
EndFunction // GetForm5ExportValueTable

// -----------------------------------------------------------------------------
Function CheckForm5Data(vErrors, pExportTable)
   	// Check each row in the export table
	For Each vRow In pExportTable Do
		If Not ValueIsFilled(vRow.Guest) Then
			AddError(vErrors, 
			         NStr("en = 'The accommodation does not contains a guest!';
					 	  |de = 'Die Unterkunft enthält keinen Gast!';
						  |ru = 'В документе размещения не указан гость!'"), 
			         vRow.Accommodation);
		EndIf;
		If TrimAll(vRow.LastName) = "" Then // * 3
			AddError(vErrors, 
			         NStr("ru = 'Не заполнена ФАМИЛИЯ';  
			              |de = 'LASTNAME is empty'; 
			              |en = 'LASTNAME is empty'"), 
			         vRow.Accommodation);
		EndIf;
		vFirstChar = Upper(Left(TrimAll(vRow.LastName), 1));
		If Find("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ", vFirstChar) = 0 Then
			AddError(vErrors, 
			         NStr("en='Names should be in russian language in notification for guest " + TrimAll(vRow.FullName) + "'; 
			           	  |ru='ФИО в уведомлении должно указываться по-русски у гостя " + TrimAll(vRow.FullName) + "'; 
					   	  |de='Namen sollten in der russischen Sprache in der Mitteilung für die Gäste sein " + TrimAll(vRow.FullName) + "'"), 
			         vRow.Accommodation);
		EndIf;		 
		If TrimAll(vRow.FirstName) = "" Then // * 4
			AddError(vErrors, 
			         NStr("ru = 'Не заполнено ИМЯ'; 
					      |de = 'FIRSTNAME is empty'; 
			              |en = 'FIRSTNAME is empty'"), 
			         vRow.Accommodation);
		EndIf;
		If TrimAll(vRow.Sex) = "" Then // * 9
			AddError(vErrors, 
			         NStr("ru = 'Не заполнен ПОЛ'; 
					      |de = 'SEX is empty';
			              |en = 'SEX is empty'"), 
			         vRow.Accommodation);
		EndIf;
	   	vDateOfBirth = vRow.DateOfBirth;
		If Not ValueIsFilled(vDateOfBirth) Then // * 10
	   		AddError(vErrors, 
			         NStr("ru = 'Не заполнена ДАТА РОЖДЕНИЯ'; 
					      |de = 'DATE OF BIRTH is empty';
			              |en = 'DATE OF BIRTH is empty'"), 
			         vRow.Accommodation);
	   	ElsIf vDateOfBirth >= BegOfDay(CurrentSessionDate()) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ДАТА РОЖДЕНИЯ указана не верно (" + Format(vRow.DateOfBirth, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'DATE OF BIRTH is probably wrong (" + Format(vRow.DateOfBirth, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'DATE OF BIRTH is probably wrong (" + Format(vRow.DateOfBirth, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.Accommodation);
	   	EndIf;
	   	If TrimAll(vRow.CitizenshipISOCode3) = "" Then // * 11
	   		AddError(vErrors, 
			         NStr("ru = 'Не указано ГРАЖДАНСТВО'; 
					      |de = 'CITIZENSHIP is empty'; 
			              |en = 'CITIZENSHIP is empty'"), 
			         vRow.Accommodation);
		ElsIf ValueIsFilled(Hotel.Citizenship) And 
		      TrimAll(Hotel.Citizenship.ISOCode3) <> TrimAll(vRow.CitizenshipISOCode3) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ГРАЖДАНСТВО указано не верно (" + TrimAll(vRow.CitizenshipISOCode3) + ")'; 
					      |de = 'CITIZENSHIP is probably wrong (" + TrimAll(vRow.CitizenshipISOCode3) + ")'; 
					      |en = 'CITIZENSHIP is probably wrong (" + TrimAll(vRow.CitizenshipISOCode3) + ")'"), 
			         vRow.Accommodation);
		EndIf;
	   	If TrimAll(vRow.IdentityDocumentType) = "" Then
	   		AddError(vErrors, 
			         NStr("ru = 'Не указан ВИД ДУЛ'; 
					      |de = 'IDENTITY DOCUMENT TYPE is empty'; 
			              |en = 'IDENTITY DOCUMENT TYPE is empty'"), 
			         vRow.Accommodation);
		Else
			If IsBlankString(vRow.IdentityDocumentTypeExternalCode) Then			 
				AddError(vErrors, 
			         	 NStr("en='You have to refresh identity document types catalog! Please open identity document types list and press <Load> button.'; 
						   	  |ru='Необходимо обновить справочник видов документов удостоверяющих личность! Откройте справочник и нажмите кнопку <Загрузить> в панели инструментов списка.'; 
						   	  |de='Sie müssen aktualisieren Identität Dokumenttypen Katalog! Bitte offenen Identität Dokumenttypen Liste und drücken Sie <Laden> Taste.'"), 
			         	 vRow.Accommodation);
			EndIf;
		EndIf;
		If TrimAll(vRow.IdentityDocumentNumber) = "" Then // * 14
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
		EndIf;
		If Hotel.LegalRepresentativeForChildren And Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			If (Year(CurrentDate()) - Year(vRow.DateOfBirth)) < 18 Then
				vLegalRep = vRow.LegalRepresentative;
				If ValueIsFilled(vLegalRep) Then
					If Not ValueIsFilled(vLegalRep.Sex) Then
						AddError(vErrors, 
				         		 NStr("en='Sex is missing for person " + TrimAll(vLegalRep.FullName) + "'; 
								   	  |ru='Пол не указан у представителя " + TrimAll(vLegalRep.FullName) + "'; 
								   	  |de='Sex wird für die Gäste fehlen " + TrimAll(vLegalRep.FullName) + "'"), 
			         			 vRow.Accommodation);	
					EndIf;
					If ValueIsFilled(vLegalRep.IdentityDocumentType) Then
						vLegalRepIdentityDocumentType = vLegalRep.IdentityDocumentType;
						If IsBlankString(vLegalRepIdentityDocumentType.ExternalCode) Then
							AddError(vErrors, 
				         		 	 NStr("en='You have to refresh identity document types catalog! Please open identity document types list and press <Load> button.'; 
									   	  |ru='Необходимо обновить справочник видов документов удостоверяющих личность! Откройте справочник и нажмите кнопку <Загрузить> в панели инструментов списка.'; 
									   	  |de='Sie müssen aktualisieren Identität Dokumenttypen Katalog! Bitte offenen Identität Dokumenttypen Liste und drücken Sie <Laden> Taste.'"), 
			         				 vRow.Accommodation);
						EndIf;
					Else
						AddError(vErrors,
								 NStr("en='Identity document type is missing for person " + TrimAll(vLegalRep.FullName) + "'; 
								   	  |ru='Тип документа удостоверяющего личность не указан у представителя " + TrimAll(vLegalRep.FullName) + "'; 
								   	  |de='Identität Dokumenttyp wird für die Gäste fehlen " + TrimAll(vLegalRep.FullName) + "'"), 
			         			 vRow.Accommodation);
					EndIf;
					If IsBlankString(vRow.RelationType) Then
						AddError(vErrors,
								 StrTemplate(NStr("en = 'The legal representative has not specified the degree of relationship for the guest %1'; 
										   		  |de = 'Der gesetzliche Vertreter hat den Grad der Beziehung für den Gast %1 nicht angegeben'; 
										   		  |ru = 'У законного представителя не указана степень родства для гостя %1'"),
								 			 TrimAll(vRow.FullName)), 
			         			 vRow.Accommodation);	
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost And 
	   	   Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then 
			If Not ValueIsFilled(Company) Then
				AddError(vErrors,
						 NStr("en='Company should be filled!'; 
				           	  |ru='Фирма должна быть указана!'; 
						   	  |de='Kompanie sollten gefüllt werden!'"), 
			         	 vRow.Accommodation);
			Else
				If IsBlankString(Company.TIN) Then
					AddError(vErrors,
						 	 NStr("en='Company TIN should be filled!'; 
					           	  |ru='ИНН фирмы должен быть указан!'; 
							   	  |de='Kompanie TIN sollten gefüllt werden!'"), 
			         	 	 vRow.Accommodation);
				EndIf;
			EndIf;
			If IsBlankString(CompanyAddress) Then
				AddError(vErrors,
						 NStr("en='Company address should be filled!'; 
				           |ru='Адрес фирмы должен быть указан!'; 
						   |de='Kompanieadresse sollten gefüllt werden!'"), 
			         	 vRow.Accommodation);
			EndIf;
		EndIf;
		vCheckOutDate = vRow.ExpectedCheckOutDate;
		If ValueIsFilled(vCheckOutDate) Then
			If vCheckOutDate < vCheckInDate Then
		   		AddError(vErrors, 
				         NStr("ru = 'Возможно ДАТА ВЫЕЗДА указана не верно (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'; 
						      |de = 'CHECK OUT DATE is probably wrong (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'; 
						      |en = 'CHECK OUT DATE is probably wrong (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'"), 
				         vRow.Accommodation);
			EndIf;
		EndIf;
		vIdentityDocumentIssueDate = vRow.IdentityDocumentIssueDate;
		If ValueIsFilled(vIdentityDocumentIssueDate) And ValueIsFilled(vDateOfBirth) And vIdentityDocumentIssueDate < vDateOfBirth Then
	   		AddError(vErrors, 
			         NStr("ru = 'Дата выдачи документа удостоверяющего личность раньше даты рождения (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'Identity document issue date could not be earlier then guest birth date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'Identity document issue date could not be earlier then guest birth date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.Accommodation);
		EndIf;
		// Passport unit code
		If IsBlankString(vRow.IdentityDocumentUnitCode) And vRow.IdentityDocumentType.ExternalCode = "103008" Then
			AddError(vErrors, 
					NStr("ru = 'Не указан КОД подразделения кем выдан паспорт'; 
						|de = 'Identity document issued by code is missing'; 
						|en = 'Identity document issued by code is missing'"), 
					vRow.Accommodation);
		EndIf;	 
		// Legal representative
		If Hotel.LegalRepresentativeForChildren And Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			If ValueIsFilled(vRow.Guest) And (Year(CurrentDate()) - Year(vDateOfBirth)) < 18  Then
				If Not ValueIsFilled(vRow.LegalRepresentative) Then
					AddError(vErrors, 
						NStr("en = 'Legal representative not specified'; de = 'Gesetzlicher Vertreter nicht angegeben'; ru = 'Не указан законный представитель'"), 
						vRow.Accommodation);
				EndIf;	
				If Not ValueIsFilled(vRow.RelationType) Then
					AddError(vErrors, 
						NStr("en = 'The legal representative does not indicate the degree of relationship'; 
							 |de = 'Der gesetzliche Vertreter gibt den Grad der Beziehung nicht ann'; 
							 |ru = 'У законного представителя не указана степень родства'"), 
						vRow.Accommodation);
				EndIf;	
			EndIf;
		EndIf;
		// Place of birth
		If IsBlankString(vRow.PlaceOfBirthCountryISOCode3) Or (IsBlankString(vRow.PlaceOfBirthRegion) And IsBlankString(vRow.PlaceOfBirthCity)) Then
			AddError(vErrors, 
				NStr("en = 'Place of birth is not specified!'; de = 'Geburtsort ist nicht angegeben!'; ru = 'Не указано место рождения!'"), 
				vRow.Accommodation);
		EndIf;
	EndDo;
	vErrors.Sort("Document, ErrorText");
	If vErrors.Count() = 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckForm5Data

// -----------------------------------------------------------------------------
Function CheckVegaData(vErrors, pExportTable)
	// Check each row in the export table
	For Each vRow In pExportTable Do
		If Not ValueIsFilled(vRow.Guest) Then
			AddError(vErrors, 
			         NStr("en = 'The accommodation does not contains a guest!';
					 	  |de = 'Die Unterkunft enthält keinen Gast!';
						  |ru = 'В документе размещения не указан гость!'"), 
			         vRow.Accommodation);
		EndIf;
		If TrimAll(vRow.LastName) = "" Then // *3
			AddError(vErrors, 
			         NStr("ru = 'Не заполнена ФАМИЛИЯ';  
			              |de = 'LASTNAME is empty'; 
			              |en = 'LASTNAME is empty'"), 
			         vRow.Accommodation);
		EndIf;
		vFirstChar = Upper(Left(TrimAll(vRow.LastName), 1));
		If Find("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ", vFirstChar) = 0 Then
			AddError(vErrors, 
			         NStr("en='Names should be in russian language in notification for guest " + TrimAll(vRow.FullName) + "'; 
			           	  |ru='ФИО в уведомлении должно указываться по-русски у гостя " + TrimAll(vRow.FullName) + "'; 
					   	  |de='Namen sollten in der russischen Sprache in der Mitteilung für die Gäste sein " + TrimAll(vRow.FullName) + "'"), 
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
		If IsBlankString(HotelCode) Then
			AddError(vErrors, 
		         	 NStr("en='Hotel code should be filled!'; 
				       	  |ru='Код гостиницы должен быть указан!'; 
			           	  |de='Hotelcode gefüllt werden sollen!'"), 
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
			         NStr("ru = 'Возможно ДАТА РОЖДЕНИЯ указана не верно (" + Format(vRow.DateOfBirth, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'DATE OF BIRTH is probably wrong (" + Format(vRow.DateOfBirth, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'DATE OF BIRTH is probably wrong (" + Format(vRow.DateOfBirth, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.Accommodation);
	   	EndIf;
	   	If TrimAll(vRow.Citizenship) = "" Then //*11
	   		AddError(vErrors, 
			         NStr("ru = 'Не указано ГРАЖДАНСТВО'; 
					      |de = 'CITIZENSHIP is empty'; 
			              |en = 'CITIZENSHIP is empty'"), 
			         vRow.Accommodation);
		ElsIf ValueIsFilled(Hotel.Citizenship) And 
		      TrimAll(Hotel.Citizenship.ISOCode3) <> TrimAll(vRow.CitizenshipISOCode3) Then
	   		AddError(vErrors, 
			         NStr("ru = 'Возможно ГРАЖДАНСТВО указано не верно (" + TrimAll(vRow.CitizenshipISOCode3) + ")'; 
					      |de = 'CITIZENSHIP is probably wrong (" + TrimAll(vRow.CitizenshipISOCode3) + ")'; 
					      |en = 'CITIZENSHIP is probably wrong (" + TrimAll(vRow.CitizenshipISOCode3) + ")'"), 
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
		EndIf;
		vCheckOutDate = vRow.ExpectedCheckOutDate;
		If ValueIsFilled(vCheckOutDate) Then
			If vCheckOutDate < vCheckInDate Then
		   		AddError(vErrors, 
				         NStr("ru = 'Возможно ДАТА ВЫЕЗДА указана не верно (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'; 
						      |de = 'CHECK OUT DATE is probably wrong (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'; 
						      |en = 'CHECK OUT DATE is probably wrong (" + Format(vRow.ExpectedCheckOutDate, "DF=dd.MM.yyyy") + ")'"), 
				         vRow.Accommodation);
			EndIf;
		EndIf;
		vIdentityDocumentIssueDate = vRow.IdentityDocumentIssueDate;
		If ValueIsFilled(vIdentityDocumentIssueDate) And ValueIsFilled(vDateOfBirth) And vIdentityDocumentIssueDate < vDateOfBirth Then
	   		AddError(vErrors, 
			         NStr("ru = 'Дата выдачи документа удостоверяющего личность раньше даты рождения (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |de = 'Identity document issue date could not be earlier then guest birth date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'; 
					      |en = 'Identity document issue date could not be earlier then guest birth date (" + Format(vRow.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + ")'"), 
			         vRow.Accommodation);
		EndIf;
		// Passport unit code
		If IsBlankString(vRow.IdentityDocumentUnitCode) And vRow.IdentityDocumentType.ExternalCode = "103008" Then
			AddError(vErrors, 
					NStr("ru = 'Не указан КОД подразделения кем выдан паспорт'; 
						|de = 'Identity document issued by code is missing'; 
						|en = 'Identity document issued by code is missing'"), 
					vRow.Accommodation);
		EndIf;	 
		// Place of birth
		If IsBlankString(vRow.PlaceOfBirthCountryISOCode3) Or (IsBlankString(vRow.PlaceOfBirthRegion) And IsBlankString(vRow.PlaceOfBirthCity)) Then
			AddError(vErrors, 
				NStr("en = 'Place of birth is not specified!'; de = 'Geburtsort ist nicht angegeben!'; ru = 'Не указано место рождения!'"), 
				vRow.Accommodation);
		EndIf;
	EndDo;
	vErrors.Sort("Document, ErrorText");
	If vErrors.Count() = 0 Then
		Return True;
	Else
		Return False;
	EndIf;	
EndFunction // CheckForm5Data

// -----------------------------------------------------------------------------
Function GetOfficialOrganID(pUnitCode, pIssuedBy)
	vID = "";
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CodesFMS.Code AS Code,
	|	CodesFMS.ID AS ID,
	|	CodesFMS.Description AS Description,
	|	CASE
	|		WHEN CodesFMS.Description = &qDescription
	|			THEN 0
	|		ELSE 1
	|	END AS IsFilled
	|FROM
	|	InformationRegister.CodesFMS AS CodesFMS
	|WHERE
	|	CodesFMS.Type = &qType
	|	AND CodesFMS.Code = &qCode
	|
	|ORDER BY
	|	IsFilled,
	|	Code";
	vQry.SetParameter("qType", "FMSListRU");
	vQry.SetParameter("qCode", pUnitCode);
	vQry.SetParameter("qDescription", pIssuedBy);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vID = TrimAll(vQryRes.Get(0).ID);
	EndIf;
	Return vID;	
EndFunction // GetOfficialOrganID

// -----------------------------------------------------------------------------
// Returns address in Region$Area$City$Place$CityRegion$Street format
// -----------------------------------------------------------------------------
Function FormatAddressString(pAddrStr)
	vAddrStr = "";
	vAddrStruct = cmParseAddress(TrimAll(pAddrStr));
	If Not IsBlankString(vAddrStruct.City) Then
		If Receiver = Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
			If Left(Lower(TrimAll(vAddrStruct.City)), 6) = "москва" Then
				If StrFind(Lower(TrimAll(vAddrStruct.Region)), "москва") > 0 Then
					vAddrStruct.City = "";
				EndIf;
			EndIf;
			If Left(Lower(TrimAll(vAddrStruct.City)), 15) = "санкт-петербург" Then
				If StrFind(Lower(TrimAll(vAddrStruct.Region)), "санкт-петербург") > 0 Then
					vAddrStruct.City = "";
				EndIf;
			EndIf;
		EndIf;
		If (Lower(Right(vAddrStruct.City, 2)) = " г" Or Lower(Left(vAddrStruct.City, 2)) = "г ") Or
		   (Lower(Right(vAddrStruct.City, 3)) = " г." Or Lower(Left(vAddrStruct.City, 3)) = "г. ") Then
			vAddrStr = vAddrStruct.Region + "$" + vAddrStruct.Area + "$" + vAddrStruct.City + "$" + "$" + "$" + vAddrStruct.Street;
		Else
			If TrimAll(StrReplace(vAddrStruct.Region, "г ", "")) = TrimAll(vAddrStruct.City) Then 
				vAddrStr = vAddrStruct.Region + "$" + vAddrStruct.Area + "$" + "$" + "$" + "$" + vAddrStruct.Street;	
			Else
				vAddrStr = vAddrStruct.Region + "$" + vAddrStruct.Area + "$" + "$" + vAddrStruct.City + "$" + "$" + vAddrStruct.Street;	
			EndIf;
		EndIf;
	Else
		If Not IsBlankString(vAddrStruct.Street) Then
			vAddrStr = vAddrStruct.Region + "$" + vAddrStruct.Area + "$" + vAddrStruct.Region + "$" + "$" + "$" + vAddrStruct.Street;
		Else
			vAddrStr = vAddrStruct.Region + "$" + vAddrStruct.Area + "$" + "$" + "$" + "$";
		EndIf;
	EndIf;
	If Receiver = Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
		Return StrReplace(vAddrStr, ".", "");
	Else
		Return vAddrStr;
	EndIf;
EndFunction // FormatAddressString

// -----------------------------------------------------------------------------
Procedure WriteCase(vRow, pXMLWriter = Undefined, Val pNSURI = "", rFullFileName, pTempDir = Undefined)
	pNSURI = "http://umms.fms.gov.ru/replication/migration/staying";
	vNSURICase = "";
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		pNSURI = "http://portal.federalhotelservice.ru/elpost/integration/hms/common/imp/core";
		vNSURICase = "http://portal.federalhotelservice.ru/elpost/integration/hms/common/imp/migration";
		vNSURIMigration = vNSURICase;
	EndIf;
	
	vGuest = vRow.Guest;
	vRegRecord = vRow.RegistryRecord;
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vGuestCode = Right(TrimAll(vGuest.Code), 2);
		vDocNumber = Right(TrimAll(vRegRecord.Number), 7);
		vUID = vDocNumber + vGuestCode;
	Else
		vUID = String(vRegRecord.UUID());
	EndIf;
	vAccDoc = vRow.Accommodation;
	vAccUID = String(vAccDoc.UUID());
	vPersonUID = String(vGuest.UUID());
	vPersonName = GetPersonName(vGuest);
	vEmployeeUID = String(Employee.UUID());
	vIdentityDocUUID = String(vRow.IdentityDocumentType.UUID());

	vGuestCode = "";
	vDocNumber = "";
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vGuestCode = Right(TrimAll(vGuest.Code), 2);
		vDocNumber = Right(TrimAll(vRegRecord.Number), 7);
		rFullFileName = cmGetFullFileName(pmGetForeignersFileName(vDocNumber + vGuestCode), ?(pTempDir = Undefined, ExportDirForeigners, pTempDir));
	Else
		vGuestCode = cmGetValidFileName(StrReplace(TrimAll(vGuest.Code), " ", "_"));
		vDocNumber = cmGetValidFileName(StrReplace(TrimAll(vRegRecord.Number), " ", "_"));
		rFullFileName = cmGetFullFileName(pmGetForeignersFileName(vPersonName + "_" + vGuestCode + "_" + vDocNumber), ?(pTempDir = Undefined, ExportDirForeigners, pTempDir));
	EndIf;
	
	vLimits = GetLimitsAndConditions(vGuest);
	vFanID = "";
	vFanNumber	= "";
	For Each vLimitRow In vLimits Do
		If vLimitRow.Characteristic.XMLElementName = "fan_id_number" Then
			vFanNumber = vLimitRow.CharacteristicValue;
		EndIf;
		If vLimitRow.Characteristic.XMLElementName = "fan_id" Then
			vFanID = vLimitRow.CharacteristicValue;
		EndIf;
	EndDo;
	
	// Build XML
	If pXMLWriter = Undefined Then
		vXMLWriter = New XMLWriter();
		vXMLWriter.OpenFile(rFullFileName, "UTF-8");
		vXMLWriter.WriteXMLDeclaration();
	Else
		vXMLWriter = pXMLWriter;
	EndIf;
	
	// Case
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("case", vNSURICase);
	Else
		vXMLWriter.WriteStartElement("case", pNSURI);
	EndIf;
	
	// Name space uri
	If pXMLWriter = Undefined Then
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteNamespaceMapping("", pNSURI);
			vXMLWriter.WriteNamespaceMapping("migration", vNSURICase);
		Else
			vXMLWriter.WriteNamespaceMapping("", vNSURICore);
			vXMLWriter.WriteNamespaceMapping("ds", "http://www.w3.org/2000/09/xmldsig#");
			vXMLWriter.WriteNamespaceMapping("", vNSURICore);
			vXMLWriter.WriteNamespaceMapping("ns2", vNSURIMigration);
			vXMLWriter.WriteNamespaceMapping("ns3", vNSURIFCCore);
			vXMLWriter.WriteNamespaceMapping("ns4", vNSURIStaying);
		EndIf;
		
		// SchemaVersion
		vXMLWriter.WriteStartAttribute("schemaVersion");
		vXMLWriter.WriteText("1.0");
		vXMLWriter.WriteEndAttribute();
	EndIf;
		
	// Uid
	vXMLWriter.WriteStartElement("uid");
	vXMLWriter.WriteText(vUID);
	vXMLWriter.WriteEndElement();
	
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost And
	   Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
		// SupplierInfo
		vXMLWriter.WriteStartElement("supplierInfo");
		vXMLWriter.WriteText(TrimAll(SupplierInfo));
		vXMLWriter.WriteEndElement();
		
		// Subdivision
		vXMLWriter.WriteStartElement("subdivision");
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteText("officialOrgan");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText(TrimAll(OfficialOrganID));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement();
		
		// Employee
		vXMLWriter.WriteStartElement("employee");
		If Not IsBlankString(UmmsLoginId) Then
			vXMLWriter.WriteStartElement("ummsId");
			vXMLWriter.WriteText(TrimAll(UmmsLoginId));
			vXMLWriter.WriteEndElement();
		Else
			vXMLWriter.WriteStartElement("name");
			vXMLWriter.WriteText(TrimAll(Employee));
			vXMLWriter.WriteEndElement();
		EndIf;
		vXMLWriter.WriteEndElement();
		
		// Date
		vXMLWriter.WriteStartElement("date");
		vXMLWriter.WriteText(Format(vRow.RecordDate, "DF=yyyy-MM-ddTHH:mm:ss"));
		vXMLWriter.WriteEndElement();
		
		// Number 
		vXMLWriter.WriteStartElement("number");
		vXMLWriter.WriteText(vRow.RecordNumber);
		vXMLWriter.WriteEndElement();
	EndIf;

	// Fan_id
	If ValueIsFilled(vFanID) And ValueIsFilled(vFanNumber) Then
		vXMLWriter.WriteStartElement("fan_id");
			vXMLWriter.WriteStartElement("id");
			vXMLWriter.WriteText(String(vFanID));
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("number");
			vXMLWriter.WriteText(String(vFanNumber));
			vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement();
	EndIf;

	// NotificationReceived
	If Receiver = Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
		vXMLWriter.WriteStartElement("receptionDate", vNSURIMigration);
		vXMLWriter.WriteText(Format(vRow.RecordDate, "DF=yyyy-MM-dd"));
		vXMLWriter.WriteEndElement();
	ElsIf Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("notificationReceived", vNSURIMigration);
		vXMLWriter.WriteText(Format(vRow.RecordDate, "DF=yyyy-MM-dd"));
		vXMLWriter.WriteEndElement();
	EndIf;
	
	// PersonDataDocument
	vXMLWriter.WriteStartElement("personDataDocument", vNSURIMigration);
	vXMLWriter.WriteStartElement("person");
	
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("uid");
		vXMLWriter.WriteText(vPersonUID);
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("personUid");
		vXMLWriter.WriteText(vPersonUID);
		vXMLWriter.WriteEndElement();
	EndIf;
	
	// Names
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("lastNameRus");
		vXMLWriter.WriteText(TrimAll(vRow.LastName));
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("lastNameLat");
		vXMLWriter.WriteText(TrimAll(vRow.LastNameLat));
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("firstNameRus");
		vXMLWriter.WriteText(TrimAll(vRow.FirstName));
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("firstNameLat");
		vXMLWriter.WriteText(TrimAll(vRow.FirstNameLat));
		vXMLWriter.WriteEndElement();
		
		If Not IsBlankString(TrimAll(vRow.SecondName)) Then
			vXMLWriter.WriteStartElement("middleNameRus");
			vXMLWriter.WriteText(TrimAll(vRow.SecondName));
			vXMLWriter.WriteEndElement();
		EndIf;
		
		If Not IsBlankString(TrimAll(vRow.SecondNameLat)) Then
			vXMLWriter.WriteStartElement("middleNameLat");
			vXMLWriter.WriteText(TrimAll(vRow.SecondNameLat));
			vXMLWriter.WriteEndElement();
		EndIf;
	Else
		vXMLWriter.WriteStartElement("lastName");
		vXMLWriter.WriteText(TrimAll(vRow.LastName));
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("lastNameLat");
		vXMLWriter.WriteText(TrimAll(vRow.LastNameLat));
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("firstName");
		vXMLWriter.WriteText(TrimAll(vRow.FirstName));
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("firstNameLat");
		vXMLWriter.WriteText(TrimAll(vRow.FirstNameLat));
		vXMLWriter.WriteEndElement();
		
		If Not IsBlankString(TrimAll(vRow.SecondName)) Then
			vXMLWriter.WriteStartElement("middleName");
			vXMLWriter.WriteText(TrimAll(vRow.SecondName));
			vXMLWriter.WriteEndElement();
		EndIf;
		
		If Not IsBlankString(TrimAll(vRow.SecondNameLat)) Then
			vXMLWriter.WriteStartElement("middleNameLat");
			vXMLWriter.WriteText(TrimAll(vRow.SecondNameLat));
			vXMLWriter.WriteEndElement();
		EndIf;
	EndIf;
	
	// Gender
	vXMLWriter.WriteStartElement("gender");
	vXMLWriter.WriteStartElement("type");
	vXMLWriter.WriteText("Gender");
	vXMLWriter.WriteEndElement();
	If ValueIsFilled(vRow.Sex) Then
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			If vRow.Sex = Enums.Sex.Male Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("M");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("M");
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("F");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("F");
				vXMLWriter.WriteEndElement();
			EndIf;
		Else
			If vRow.Sex = Enums.Sex.Male Then
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText("M");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("Мужской");
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText("F");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("Женский");
				vXMLWriter.WriteEndElement();
			EndIf;
		EndIf;
	EndIf;
	vXMLWriter.WriteEndElement(); // Gender
	
	// Birth date
	vXMLWriter.WriteStartElement("birthDate");
	vXMLWriter.WriteText(Format(vRow.DateOfBirth, "DF=dd.MM.yyyy"));
	vXMLWriter.WriteEndElement();
	
	// Citizenship
	vXMLWriter.WriteStartElement("citizenship");
	vXMLWriter.WriteStartElement("type");
	vXMLWriter.WriteText("Citizenship");
	vXMLWriter.WriteEndElement();
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("id");
		vXMLWriter.WriteText(Upper(vRow.CitizenshipISOCode3));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(vRow.Citizenship);
		vXMLWriter.WriteEndElement();
	Else
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText(Upper(vRow.CitizenshipISOCode3));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(vRow.Citizenship);
		vXMLWriter.WriteEndElement();
	EndIf;
	vXMLWriter.WriteEndElement(); // Citizenship
	
	// Birth place
	vXMLWriter.WriteStartElement("birthPlace");
	vXMLWriter.WriteStartElement("country");
	vXMLWriter.WriteStartElement("type");
	vXMLWriter.WriteText("Country");
	vXMLWriter.WriteEndElement();
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("id");
		vXMLWriter.WriteText(Upper(vRow.PlaceOfBirthCountryISOCode3));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(vRow.PlaceOfBirthCountry);
		vXMLWriter.WriteEndElement();
	Else
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText(Upper(vRow.PlaceOfBirthCountryISOCode3));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(vRow.PlaceOfBirthCountry);
		vXMLWriter.WriteEndElement();
	EndIf;
	vXMLWriter.WriteEndElement(); // Country
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("place");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("place2");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("place3");
		vXMLWriter.WriteText(?(IsBlankString(vRow.PlaceOfBirthCity), vRow.PlaceOfBirthRegion, vRow.PlaceOfBirthCity));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("place4");
		vXMLWriter.WriteEndElement();
	EndIf;
	vXMLWriter.WriteEndElement(); // BirthPlace
	
	vXMLWriter.WriteEndElement(); // Person
	
	// Identity document
	vXMLWriter.WriteStartElement("document");
	If ValueIsFilled(vRow.IdentityDocumentType) Then
		If Not IsBlankString(vRow.IdentityDocumentTypeExternalCode) Then
			// Uid
			If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("uid");
				vXMLWriter.WriteText(vIdentityDocUUID);
				vXMLWriter.WriteEndElement();
			EndIf;
			// Type
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("DocumentType");
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentTypeExternalCode));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentTypeExternalCode));
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentTypeExternalCode));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentType));
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement(); // Type
			// Series
			If Not IsBlankString(vRow.IdentityDocumentSeries) Then
				vXMLWriter.WriteStartElement("series");
				vXMLWriter.WriteText(vRow.IdentityDocumentSeries);
				vXMLWriter.WriteEndElement();
			EndIf;
			// Nnumber
			vXMLWriter.WriteStartElement("number");
			vXMLWriter.WriteText(vRow.IdentityDocumentNumber);
			vXMLWriter.WriteEndElement();
			// Issued
			If ValueIsFilled(vRow.IdentityDocumentIssueDate) Then
				vXMLWriter.WriteStartElement("issued");
				vXMLWriter.WriteText(Format(vRow.IdentityDocumentIssueDate, "DF=yyyy-MM-dd"));
				vXMLWriter.WriteEndElement();
			EndIf;
			// ValidFrom
			If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
				If ValueIsFilled(vRow.IdentityDocumentIssueDate) Then
					vXMLWriter.WriteStartElement("validFrom");
					vXMLWriter.WriteText(Format(vRow.IdentityDocumentIssueDate, "DF=yyyy-MM-dd"));
					vXMLWriter.WriteEndElement();
				EndIf;
			EndIf;
			// ValidTo
			If ValueIsFilled(vRow.IdentityDocumentValidToDate) Then
				vXMLWriter.WriteStartElement("validTo");
				vXMLWriter.WriteText(Format(vRow.IdentityDocumentValidToDate, "DF=yyyy-MM-dd"));
				vXMLWriter.WriteEndElement();
			EndIf;
			// Authority
			If Not IsBlankString(vRow.IdentityDocumentIssuedBy) Then
				vXMLWriter.WriteStartElement("authority");
				vXMLWriter.WriteText(vRow.IdentityDocumentIssuedBy);
				vXMLWriter.WriteEndElement();
			EndIf;
			// Status
			If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("status");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("DocumentStatus");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText("102877");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteEndElement();
			EndIf;
		EndIf;
	EndIf;
	vXMLWriter.WriteEndElement(); // Document
	
	vLegalRep = vRegRecord.LegalRepresentative;
	
	// Entered
	vXMLWriter.WriteStartElement("entered");
	If Receiver = Enums.GuestDataExportHeaderTypesRu.KonturFMS And ValueIsFilled(vLegalRep) Then
		vXMLWriter.WriteText("true");
	Else
		vXMLWriter.WriteText("false");
	EndIf;
	vXMLWriter.WriteEndElement();
	
	vXMLWriter.WriteEndElement(); // PersonDataDocument
		
	// StayPlace
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost And 
	   Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
			
		vXMLWriter.WriteStartElement("stayPlace", vNSURIMigration);
		vXMLWriter.WriteStartElement("address");
		vXMLWriter.WriteStartElement("russianAddress");
		vXMLWriter.WriteStartElement("addressObjectString");
		vXMLWriter.WriteText(FormatAddressString(TrimAll(HotelAddress)));
		vXMLWriter.WriteEndElement(); // AddressObjectString
		// Housing
		If Not IsBlankString(HotelAddressHouse) Then
			vXMLWriter.WriteStartElement("housing");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("addressObjectType");
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("1202");
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText("1202");
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement(); // Type
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText(TrimAll(HotelAddressHouse));
			vXMLWriter.WriteEndElement(); 
			vXMLWriter.WriteEndElement(); // Housing
		EndIf;
		If Not IsBlankString(HotelAddressBuilding) Then
			vXMLWriter.WriteStartElement("housing");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("addressObjectType");
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("1203");
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText("1203");
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement(); // Type
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText(TrimAll(HotelAddressBuilding));
			vXMLWriter.WriteEndElement(); 
			vXMLWriter.WriteEndElement(); // Housing
		EndIf;
		vXMLWriter.WriteEndElement(); // RussianAddress
		
		vXMLWriter.WriteEndElement(); // Address
		vXMLWriter.WriteEndElement(); // StayPlace
	EndIf;
	
	// Legal representative
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
		If ValueIsFilled(vLegalRep) Then
			vLegalRepUID = String(vLegalRep.UUID());
			vLegalRepLastName = TrimAll(vRegRecord.LegalRepresentativeLastName);
			If IsBlankString(vLegalRepLastName) Then
				vLegalRepLastName = TrimAll(vLegalRep.LastName);
			EndIf;
			vLegalRepFirstName = TrimAll(vRegRecord.LegalRepresentativeFirstName);
			If IsBlankString(vLegalRepFirstName) Then
				vLegalRepFirstName = TrimAll(vLegalRep.FirstName);
			EndIf;
			vLegalRepSecondName = TrimAll(vRegRecord.LegalRepresentativeSecondName);
			If IsBlankString(vLegalRepSecondName) Then
				vLegalRepSecondName = TrimAll(vLegalRep.SecondName);
			EndIf;
			
			vXMLWriter.WriteStartElement("representative", vNSURIMigration);
			
			// PersonDataDocument
			vXMLWriter.WriteStartElement("personDataDocument", vNSURIMigration);
			vXMLWriter.WriteStartElement("person");
			
			If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("uid");
				vXMLWriter.WriteText(vLegalRepUID);
				vXMLWriter.WriteEndElement();
				
				vXMLWriter.WriteStartElement("personUid");
				vXMLWriter.WriteText(vLegalRepUID);
				vXMLWriter.WriteEndElement();
			EndIf;
			
			// Names
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("lastNameRus");
				vXMLWriter.WriteText(TrimAll(vLegalRepLastName));
				vXMLWriter.WriteEndElement();
				
				vXMLWriter.WriteStartElement("lastNameLat");
				vXMLWriter.WriteText(TrimAll(vLegalRep.LastName));
				vXMLWriter.WriteEndElement();
				
				vXMLWriter.WriteStartElement("firstNameRus");
				vXMLWriter.WriteText(TrimAll(vLegalRepFirstName));
				vXMLWriter.WriteEndElement();
				
				vXMLWriter.WriteStartElement("firstNameLat");
				vXMLWriter.WriteText(TrimAll(vLegalRep.FirstName));
				vXMLWriter.WriteEndElement();
				
				If Not IsBlankString(TrimAll(vLegalRepSecondName)) Then
					vXMLWriter.WriteStartElement("middleNameRus");
					vXMLWriter.WriteText(TrimAll(vLegalRepSecondName));
					vXMLWriter.WriteEndElement();
				EndIf;
				
				If Not IsBlankString(TrimAll(vLegalRep.SecondName)) Then
					vXMLWriter.WriteStartElement("middleNameLat");
					vXMLWriter.WriteText(TrimAll(vLegalRep.SecondName));
					vXMLWriter.WriteEndElement();
				EndIf;
			Else
				vXMLWriter.WriteStartElement("lastName");
				vXMLWriter.WriteText(TrimAll(vLegalRepLastName));
				vXMLWriter.WriteEndElement();
				
				If lower(TrimAll(vLegalRep.LastName)) <> lower(TrimAll(vLegalRepLastName)) Then
					vXMLWriter.WriteStartElement("lastNameLat");
					vXMLWriter.WriteText(TrimAll(vLegalRep.LastName));
					vXMLWriter.WriteEndElement();
				EndIf;
				
				vXMLWriter.WriteStartElement("firstName");
				vXMLWriter.WriteText(TrimAll(vLegalRepFirstName));
				vXMLWriter.WriteEndElement();
				
				If lower(TrimAll(vLegalRep.FirstName)) <> lower(TrimAll(vLegalRepFirstName)) Then
					vXMLWriter.WriteStartElement("firstNameLat");
					vXMLWriter.WriteText(TrimAll(vLegalRep.FirstName));
					vXMLWriter.WriteEndElement();
				EndIf;
				
				If Not IsBlankString(TrimAll(vLegalRepSecondName)) Then
					vXMLWriter.WriteStartElement("middleName");
					vXMLWriter.WriteText(TrimAll(vLegalRepSecondName));
					vXMLWriter.WriteEndElement();
				EndIf;
				
				If Not IsBlankString(TrimAll(vLegalRep.SecondName)) Then
					If lower(TrimAll(vLegalRep.SecondName)) <> lower(TrimAll(vLegalRepSecondName)) Then
						vXMLWriter.WriteStartElement("middleNameLat");
						vXMLWriter.WriteText(TrimAll(vLegalRep.SecondName));
						vXMLWriter.WriteEndElement();
					EndIf;
				EndIf;
			EndIf;
			
			// Gender
			vXMLWriter.WriteStartElement("gender");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("Gender");
			vXMLWriter.WriteEndElement();
			If ValueIsFilled(vLegalRep.Sex) Then
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					If vLegalRep.Sex = Enums.Sex.Male Then
						vXMLWriter.WriteStartElement("id");
						vXMLWriter.WriteText("M");
						vXMLWriter.WriteEndElement();
						vXMLWriter.WriteStartElement("value");
						vXMLWriter.WriteText("M");
						vXMLWriter.WriteEndElement();
					Else
						vXMLWriter.WriteStartElement("id");
						vXMLWriter.WriteText("F");
						vXMLWriter.WriteEndElement();
						vXMLWriter.WriteStartElement("value");
						vXMLWriter.WriteText("F");
						vXMLWriter.WriteEndElement();
					EndIf;
				Else
					If vLegalRep.Sex = Enums.Sex.Male Then
						vXMLWriter.WriteStartElement("element");
						vXMLWriter.WriteText("M");
						vXMLWriter.WriteEndElement();
						vXMLWriter.WriteStartElement("value");
						vXMLWriter.WriteText("Мужской");
						vXMLWriter.WriteEndElement();
					Else
						vXMLWriter.WriteStartElement("element");
						vXMLWriter.WriteText("F");
						vXMLWriter.WriteEndElement();
						vXMLWriter.WriteStartElement("value");
						vXMLWriter.WriteText("Женский");
						vXMLWriter.WriteEndElement();
					EndIf;
				EndIf;
			EndIf;
			vXMLWriter.WriteEndElement(); // Gender
			
			// Birth date
			vXMLWriter.WriteStartElement("birthDate");
			vXMLWriter.WriteText(Format(vLegalRep.DateOfBirth, "DF=dd.MM.yyyy"));
			vXMLWriter.WriteEndElement();
			
			// Citizenship
			vXMLWriter.WriteStartElement("citizenship");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("Citizenship");
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText(Upper(vLegalRep.Citizenship.ISOCode3));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vLegalRep.Citizenship));
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText(Upper(vLegalRep.Citizenship.ISOCode3));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vLegalRep.Citizenship));
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement(); // Citizenship
			
			// Birth place
			vLegalRepPlaceOfBirthCountry = "";
			vLegalRepPlaceOfBirthCountryISOCode3 = "";
			vLegalRepPlaceOfBirthCity = "";
			vLegalRepPlaceOfBirthRegion = "";
			vLegalRepPlaceOfBirth = "";
			If TrimAll(vLegalRep.PlaceOfBirth) <> "" Then
				vLegalRepPlaceOfBirth = TrimAll(vLegalRep.PlaceOfBirth);
			EndIf;
			If Not IsBlankString(vLegalRepPlaceOfBirth) Then
				vLegalRepAddressItems = cmParseAddress(vLegalRepPlaceOfBirth);
				If ValueIsFilled(vLegalRepAddressItems.Country) Then
					vLegalRepPlaceOfBirthCountry = TrimAll(vLegalRepAddressItems.Country.Description);
					vLegalRepPlaceOfBirthCountryISOCode3 = TrimAll(vLegalRepAddressItems.Country.ISOCode3);
				EndIf;
				If Not IsBlankString(vLegalRepAddressItems.Region) Then
					vLegalRepPlaceOfBirthRegion = TrimAll(vLegalRepAddressItems.Region);
				EndIf;
				If Not IsBlankString(vLegalRepAddressItems.City) Then
					vLegalRepPlaceOfBirthCity = TrimAll(vLegalRepAddressItems.City);
				EndIf;
			EndIf;
			
			vXMLWriter.WriteStartElement("birthPlace");
			vXMLWriter.WriteStartElement("country");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("Country");
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText(Upper(vLegalRepPlaceOfBirthCountryISOCode3));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(vLegalRepPlaceOfBirthCountry);
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText(Upper(vLegalRepPlaceOfBirthCountryISOCode3));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(vLegalRepPlaceOfBirthCountry);
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement(); // Country
			vXMLWriter.WriteStartElement("place");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("place2");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("place3");
			vXMLWriter.WriteText(?(IsBlankString(vLegalRepPlaceOfBirthCity), vLegalRepPlaceOfBirthRegion, vLegalRepPlaceOfBirthCity));
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("place4");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteEndElement(); // BirthPlace
			
			vXMLWriter.WriteEndElement(); // Person
			
			// Identity document
			vXMLWriter.WriteStartElement("document");
			If ValueIsFilled(vLegalRep.IdentityDocumentType) Then
				vLegalRepIdentityDocumentType = vLegalRep.IdentityDocumentType;
				If Not IsBlankString(vLegalRepIdentityDocumentType.ExternalCode) Then
					// Uid
					If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
						vXMLWriter.WriteStartElement("uid");
						vXMLWriter.WriteText(String(vLegalRepIdentityDocumentType.UUID()));
						vXMLWriter.WriteEndElement();
					EndIf;
					// Type
					vXMLWriter.WriteStartElement("type");
					vXMLWriter.WriteStartElement("type");
					vXMLWriter.WriteText("DocumentType");
					vXMLWriter.WriteEndElement();
					If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
						vXMLWriter.WriteStartElement("id");
						vXMLWriter.WriteText(TrimAll(vLegalRepIdentityDocumentType.ExternalCode));
						vXMLWriter.WriteEndElement();
						vXMLWriter.WriteStartElement("value");
						vXMLWriter.WriteText(TrimAll(vLegalRepIdentityDocumentType.ExternalCode));
						vXMLWriter.WriteEndElement();
					Else
						vXMLWriter.WriteStartElement("element");
						vXMLWriter.WriteText(TrimAll(vLegalRepIdentityDocumentType.ExternalCode));
						vXMLWriter.WriteEndElement();
						vXMLWriter.WriteStartElement("value");
						vXMLWriter.WriteText(TrimAll(vLegalRepIdentityDocumentType));
						vXMLWriter.WriteEndElement();
					EndIf;
					vXMLWriter.WriteEndElement(); // Type
					// Series
					If Not IsBlankString(vLegalRep.IdentityDocumentSeries) Then
						vXMLWriter.WriteStartElement("series");
						vXMLWriter.WriteText(vLegalRep.IdentityDocumentSeries);
						vXMLWriter.WriteEndElement();
					EndIf;
					// Number
					vXMLWriter.WriteStartElement("number");
					vXMLWriter.WriteText(vLegalRep.IdentityDocumentNumber);
					vXMLWriter.WriteEndElement();
					// Issued
					If ValueIsFilled(vLegalRep.IdentityDocumentIssueDate) Then
						vXMLWriter.WriteStartElement("issued");
						vXMLWriter.WriteText(Format(vLegalRep.IdentityDocumentIssueDate, "DF=yyyy-MM-dd"));
						vXMLWriter.WriteEndElement();
					EndIf;
					// ValidFrom
					If ValueIsFilled(vLegalRep.IdentityDocumentIssueDate) Then
						vXMLWriter.WriteStartElement("validFrom");
						vXMLWriter.WriteText(Format(vLegalRep.IdentityDocumentIssueDate, "DF=yyyy-MM-dd"));
						vXMLWriter.WriteEndElement();
					EndIf;
					// ValidTo
					If ValueIsFilled(vLegalRep.IdentityDocumentValidToDate) Then
						vXMLWriter.WriteStartElement("validTo");
						vXMLWriter.WriteText(Format(vLegalRep.IdentityDocumentValidToDate, "DF=yyyy-MM-dd"));
						vXMLWriter.WriteEndElement();
					EndIf;
					// Authority
					If Not IsBlankString(vLegalRep.IdentityDocumentIssuedBy) Then
						vXMLWriter.WriteStartElement("authority");
						vXMLWriter.WriteText(vLegalRep.IdentityDocumentIssuedBy);
						vXMLWriter.WriteEndElement();
					EndIf;
					// Status
					If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
						vXMLWriter.WriteStartElement("status");
						vXMLWriter.WriteStartElement("type");
						vXMLWriter.WriteText("DocumentStatus");
						vXMLWriter.WriteEndElement();
						vXMLWriter.WriteStartElement("element");
						vXMLWriter.WriteText("102877");
						vXMLWriter.WriteEndElement();
						vXMLWriter.WriteEndElement();
					EndIf;
				EndIf;
			EndIf;
			vXMLWriter.WriteEndElement(); // Document
			
			// Entered
			vXMLWriter.WriteStartElement("entered");
			vXMLWriter.WriteText("false");
			vXMLWriter.WriteEndElement();
			
			vXMLWriter.WriteEndElement(); // PersonDataDocument
			vXMLWriter.WriteEndElement(); // Representative
		EndIf;
		
		// Previous place of stay address
		If Not IsBlankString(vRegRecord.PreviousPlaceOfStay) Then
			vPrevPlaceOfStayAddress = TrimAll(vRegRecord.PreviousPlaceOfStay);
			vPrevPlaceOfStayAddressStruct = cmParseAddress(vPrevPlaceOfStayAddress);
			vPrevPlaceOfStayAddressFullHouse = TrimAll(vPrevPlaceOfStayAddressStruct.House);
			vPrevPlaceOfStayAddressHouse = pmGetHouse(vPrevPlaceOfStayAddressFullHouse);
			vPrevPlaceOfStayAddressBuilding1 = pmGetBuilding1(vPrevPlaceOfStayAddressFullHouse);
			vPrevPlaceOfStayAddressBuilding2 = pmGetBuilding2(vPrevPlaceOfStayAddressFullHouse);
			vPrevPlaceOfStayAddressFlat = TrimAll(vPrevPlaceOfStayAddressStruct.Flat);
			
			vXMLWriter.WriteStartElement("arrivalFromPlaceAddress");
			vXMLWriter.WriteStartElement("addressObjectString");
			vXMLWriter.WriteText(FormatAddressString(vPrevPlaceOfStayAddress));
			vXMLWriter.WriteEndElement(); // AddressObjectString
			// Housing
			If Not IsBlankString(vPrevPlaceOfStayAddressHouse) Then
				vXMLWriter.WriteStartElement("housing");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("addressObjectType");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText("1202");
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText("1202");
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteEndElement(); // Type
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(vPrevPlaceOfStayAddressHouse);
				vXMLWriter.WriteEndElement(); 
				vXMLWriter.WriteEndElement(); // Housing
			EndIf;
			If Not IsBlankString(vPrevPlaceOfStayAddressBuilding1) Then
				vXMLWriter.WriteStartElement("housing");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("addressObjectType");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText("1203");
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText("1203");
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteEndElement(); // Type
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(vPrevPlaceOfStayAddressBuilding1);
				vXMLWriter.WriteEndElement(); 
				vXMLWriter.WriteEndElement(); // Housing
			EndIf;
			If Not IsBlankString(vPrevPlaceOfStayAddressBuilding2) Then
				vXMLWriter.WriteStartElement("housing");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("addressObjectType");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText("1204");
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText("1204");
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteEndElement(); // Type
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(vPrevPlaceOfStayAddressBuilding2);
				vXMLWriter.WriteEndElement(); 
				vXMLWriter.WriteEndElement(); // Housing
			EndIf;
			If Not IsBlankString(vPrevPlaceOfStayAddressFlat) Then
				vXMLWriter.WriteStartElement("housing");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("addressObjectType");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText("1303");
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText("1303");
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteEndElement(); // Type
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(vPrevPlaceOfStayAddressFlat);
				vXMLWriter.WriteEndElement(); 
				vXMLWriter.WriteEndElement(); // Housing
			EndIf;
			vXMLWriter.WriteEndElement(); // ArrivalFromPlaceAddress
		EndIf;
	EndIf;
	
	// Document scans
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
		// documentPhoto Identity document scans
		vScans = GetIdentityDocScan(vAccDoc);
		For Each vScan In vScans Do
			vError = "";
			vBinaryData = Undefined;
			vBase64String = Undefined;
			Try
				vScanData = vScan.ScanPicture.Get();
				If TypeOf(vScanData) = Type("String") Then
					vBinaryData = New BinaryData(GetImageCatalogName(vScan.Ref) + TrimAll(vScanData));
				ElsIf TypeOf(vScanData) = Type("Picture") Then
					vBinaryData = vScanData.GetBinaryData();
				EndIf;
				If vBinaryData <> Undefined Then
					vBase64String = Base64String(vBinaryData);
				EndIf;
			Except
				vError = ErrorDescription();
				WriteLogEvent(NStr("en='DataProcessor.ExportGuestsToUFMSTerritoryApp'; de='DataProcessor.ExportGuestsToUFMSTerritoryApp'; ru='Обработка.ЭкспортДанныхГостейВУФМС'"), EventLogLevel.Warning, Metadata.DataProcessors.ExportGuestsToUFMSTerritoryApp, vAccDoc, "Failed to get identity document scan from value storage!");
			EndTry;
			If Not ValueIsFilled(vError) And vBase64String <> Undefined Then
				If ValueIsFilled(vScan.ScanConfiguration) Then
					vScanConfiguration = vScan.ScanConfiguration;
					vScanId = TrimAll(vScanConfiguration.IdentityDocumentType.ExternalCode);
					If vScanId <> "103012" And vScanId <> "135709" And vScanId <> "135710" And 
					   Not vScanConfiguration.IsVisa And Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsFanId Then
						Continue;
					EndIf;
					
					vXMLWriter.WriteStartElement("documentPhoto");
						vXMLWriter.WriteStartElement("documentUID");
						vXMLWriter.WriteText(String(vScan.Ref.UUID()) + "-" + String(vScanConfiguration.UUID()));
						vXMLWriter.WriteEndElement(); // DocumentUID
						
						vXMLWriter.WriteStartElement("type");
							vXMLWriter.WriteStartElement("type");
							vXMLWriter.WriteText("DocumentType");
							vXMLWriter.WriteEndElement(); // Type
							vXMLWriter.WriteStartElement("element");
							If vScanConfiguration.IsVisa Then
								vXMLWriter.WriteText("139356");
							ElsIf vScanConfiguration.IsMigrationCard Then
								vXMLWriter.WriteText("103022");
							ElsIf vScanConfiguration.IsFanId Then
								vXMLWriter.WriteText("fan_id");
							ElsIf ValueIsFilled(vScanConfiguration.IdentityDocumentType) Then
								vXMLWriter.WriteText(TrimAll(vScanConfiguration.IdentityDocumentType.ExternalCode));
							EndIf;
							vXMLWriter.WriteEndElement(); // Element
						vXMLWriter.WriteEndElement(); // Type
						
						If Receiver = Enums.GuestDataExportHeaderTypesRu.Skala Then
							vXMLWriter.WriteStartElement("documentPhotoContent");
							vXMLWriter.WriteText(vBase64String);
							vXMLWriter.WriteEndElement(); // Content
						Else
							vXMLWriter.WriteStartElement("content");
							vXMLWriter.WriteText(vBase64String);
							vXMLWriter.WriteEndElement(); // Content
						EndIf;
						
						If Receiver = Enums.GuestDataExportHeaderTypesRu.Skala Then
							vXMLWriter.WriteStartElement("documentPhotoType");
						Else
							vXMLWriter.WriteStartElement("mimeType");
						EndIf;
						vXMLWriter.WriteText("image/jpeg");
						vXMLWriter.WriteEndElement(); // MimeType

					vXMLWriter.WriteEndElement(); // IdentityDocumentScan
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Residence permit document
	If Not IsBlankString(vRow.VisaNumber) And (vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.Visa Or vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.ElectronicVisa) Then
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("residencePermitDocument", vNSURIMigration);
		Else
			vXMLWriter.WriteStartElement("docResidence", vNSURIMigration);
		EndIf;
		If vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.ElectronicVisa And Not Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("electronicVisa", vNSURIMigration);	
		Else	
			vXMLWriter.WriteStartElement("visa", vNSURIMigration);
		EndIf;
		// Uid
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("uid");
			vXMLWriter.WriteText(vUID);
			vXMLWriter.WriteEndElement();
		EndIf;
		// Type
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteStartElement("type");
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			If vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.Visa Then
				vXMLWriter.WriteText("mig.residencePermitDocumentType"); 
			Else
				vXMLWriter.WriteText("mig.dwellingEvidenceType");	
			EndIf;
		Else
			vXMLWriter.WriteText("DocumentType");
		EndIf;
		vXMLWriter.WriteEndElement();
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("id");
			vXMLWriter.WriteText("139356");
			vXMLWriter.WriteEndElement();
		Else
			vXMLWriter.WriteStartElement("element");
			If vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.Visa Then
				vXMLWriter.WriteText("139356");
			Else
				vXMLWriter.WriteText("139404");	
			EndIf;
			vXMLWriter.WriteEndElement();
		EndIf;
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText("139356");
			vXMLWriter.WriteEndElement();
		EndIf;
		vXMLWriter.WriteEndElement(); // Type
		// Series
		If Not IsBlankString(vRow.VisaSeries) Then
			vXMLWriter.WriteStartElement("series");
			vXMLWriter.WriteText(vRow.VisaSeries);
			vXMLWriter.WriteEndElement();
		EndIf;
		// Number
		vXMLWriter.WriteStartElement("number");
		vXMLWriter.WriteText(vRow.VisaNumber);
		vXMLWriter.WriteEndElement();
		// Issued
		If ValueIsFilled(vRow.VisaIssuedDate) Then
			vXMLWriter.WriteStartElement("issued");
			vXMLWriter.WriteText(Format(vRow.VisaIssuedDate, "DF=yyyy-MM-dd"));
			vXMLWriter.WriteEndElement();
		EndIf;
		// ValidFrom
		If ValueIsFilled(vRow.VisaFromDate) Then
			vXMLWriter.WriteStartElement("validFrom");
			vXMLWriter.WriteText(Format(vRow.VisaFromDate, "DF=yyyy-MM-dd"));
			vXMLWriter.WriteEndElement();
		EndIf;
		// ValidTo
		If ValueIsFilled(vRow.VisaToDate) Then
			vXMLWriter.WriteStartElement("validTo");
			vXMLWriter.WriteText(Format(vRow.VisaToDate, "DF=yyyy-MM-dd"));
			vXMLWriter.WriteEndElement();
		EndIf;
		// Categorie
		If ValueIsFilled(vRow.VisaType) Then
			If Not IsBlankString(vRow.VisaType.Code) Then
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("category", vNSURIMigration);
				Else
					vXMLWriter.WriteStartElement("category", vNSURIFCCore);
				EndIf;
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("VisaCategory");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText(TrimAll(vRow.VisaType.Code));
					vXMLWriter.WriteEndElement();
					vXMLWriter.WriteStartElement("value");
					vXMLWriter.WriteText(TrimAll(vRow.VisaType.Code));
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText(TrimAll(vRow.VisaType.Code));
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteEndElement(); // Category
			EndIf;
		EndIf;
		// Multiplicity
		If ValueIsFilled(vRow.VisaMultiplicity) Then
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("multiplicity", vNSURIMigration);
			Else
				vXMLWriter.WriteStartElement("multiplicity", vNSURIFCCore);
			EndIf;
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("VisaMultiplicity");
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				If vRow.VisaMultiplicity = Enums.VisaMultiplicityTypes.Single Then
					vXMLWriter.WriteText("135495");
				ElsIf vRow.VisaMultiplicity = Enums.VisaMultiplicityTypes.TwoTime Then
					vXMLWriter.WriteText("135496");
				ElsIf vRow.VisaMultiplicity = Enums.VisaMultiplicityTypes.Multiple Then
					vXMLWriter.WriteText("135497");
				EndIf;
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				If vRow.VisaMultiplicity = Enums.VisaMultiplicityTypes.Single Then
					vXMLWriter.WriteText("135495");
				ElsIf vRow.VisaMultiplicity = Enums.VisaMultiplicityTypes.TwoTime Then
					vXMLWriter.WriteText("135496");
				ElsIf vRow.VisaMultiplicity = Enums.VisaMultiplicityTypes.Multiple Then
					vXMLWriter.WriteText("135497");
				EndIf;
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element", vNSURIFCCore);
				If vRow.VisaMultiplicity = Enums.VisaMultiplicityTypes.Single Then
					vXMLWriter.WriteText("135495");
				ElsIf vRow.VisaMultiplicity = Enums.VisaMultiplicityTypes.TwoTime Then
					vXMLWriter.WriteText("135496");
				ElsIf vRow.VisaMultiplicity = Enums.VisaMultiplicityTypes.Multiple Then
					vXMLWriter.WriteText("135497");
				EndIf;
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement(); // Multiplicity
		EndIf;
		// Entry goal
		If ValueIsFilled(vRow.VisaEntryGoal) Then
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("visitPurpose", vNSURIMigration);
			Else
				vXMLWriter.WriteStartElement("visitPurpose", vNSURIFCCore);
			EndIf;
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("EntryGoal");
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText(TrimAll(vRow.VisaEntryGoal.Code));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.VisaEntryGoal.Code));
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText(TrimAll(vRow.VisaEntryGoal.Code));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.VisaEntryGoal));
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement(); // Entry goal
		EndIf;
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			// Identifier
			If Not IsBlankString(vRow.VisaIdentifier) Then
				vXMLWriter.WriteStartElement("identifier", vNSURIMigration);
				vXMLWriter.WriteText(TrimAll(vRow.VisaIdentifier));
				vXMLWriter.WriteEndElement();
			EndIf;
		Else
			// Stay duration
			If vRow.VisaDays > 0 Then
				vXMLWriter.WriteStartElement("stayDuration", vNSURIFCCore);
				vXMLWriter.WriteText(Format(vRow.VisaDays, "ND=4; NFD=0; NG="));
				vXMLWriter.WriteEndElement();
			EndIf;
			// Identifier
			If Not IsBlankString(vRow.VisaIdentifier) Then
				vXMLWriter.WriteStartElement("identifier", vNSURIFCCore);
				vXMLWriter.WriteText(TrimAll(vRow.VisaIdentifier));
				vXMLWriter.WriteEndElement();
			EndIf;
			// Status
			vXMLWriter.WriteStartElement("status");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("DocumentStatus");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("102877");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteEndElement(); // Status
		EndIf;
		vXMLWriter.WriteEndElement(); // Visa
		
		// Entered
		vXMLWriter.WriteStartElement("entered", vNSURIMigration);
		vXMLWriter.WriteText("false");
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteEndElement(); // DocResidence
	ElsIf Not IsBlankString(vRow.VisaIdentifier) And vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit Then
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("residencePermitDocument", vNSURIMigration);
		Else
			vXMLWriter.WriteStartElement("docResidence", vNSURIMigration);
		EndIf;
		
		vXMLWriter.WriteStartElement("tempResidencePermit", vNSURIMigration);
		// Uid
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("uid");
			vXMLWriter.WriteText(vUID);
			vXMLWriter.WriteEndElement();
		EndIf;
		// Type
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteStartElement("type");
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteText("mig.residencePermitDocumentType");
		Else
			vXMLWriter.WriteText("DocumentType");
		EndIf;
		vXMLWriter.WriteEndElement();
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("id");
			vXMLWriter.WriteText("139373");
			vXMLWriter.WriteEndElement();
		Else
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("139373");
			vXMLWriter.WriteEndElement();
		EndIf;
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText("139373");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement(); //type
		// Number
		vXMLWriter.WriteStartElement("number");
		vXMLWriter.WriteText(vRow.VisaIdentifier);
		vXMLWriter.WriteEndElement();
		// Issued
		If ValueIsFilled(vRow.VisaIssuedDate) Then
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("issued");
				vXMLWriter.WriteText(Format(vRow.VisaIssuedDate, "DF=yyyy-MM-dd"));
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("decisionDate");
				vXMLWriter.WriteText(Format(vRow.VisaIssuedDate, "DF=yyyy-MM-dd"));
				vXMLWriter.WriteEndElement();
			EndIf;
		EndIf;
		// Status
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("status");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("DocumentStatus");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("102877");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteEndElement(); // Status
			// Authority
			If Not IsBlankString(vRow.VisaIssuedBy) Then
				vXMLWriter.WriteStartElement("authority");
				vXMLWriter.WriteText(vRow.VisaIssuedBy);
				vXMLWriter.WriteEndElement();
			EndIf;
			// Decision number
			If Not IsBlankString(vRow.VisaIdentifier) Then
				vXMLWriter.WriteStartElement("decisionNumber", vNSURIFCCore);
				vXMLWriter.WriteText(TrimAll(vRow.VisaIdentifier));
				vXMLWriter.WriteEndElement();
			EndIf;
		EndIf;
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then 
			// Entry goal
			If ValueIsFilled(vRow.VisaEntryGoal) Then
				vXMLWriter.WriteStartElement("visitPurpose", vNSURIMigration);
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("EntryGoal");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText(TrimAll(vRow.VisaEntryGoal.Code));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.VisaEntryGoal.Code));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteEndElement(); // Entry goal
			Else
				vXMLWriter.WriteStartElement("visitPurpose", vNSURIMigration);
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("EntryGoal");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("103101");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("103101");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteEndElement(); // Entry goal
			EndIf;
		EndIf;
		vXMLWriter.WriteEndElement(); // TempResidencePermit
		
		// Entered
		vXMLWriter.WriteStartElement("entered", vNSURIMigration);
		vXMLWriter.WriteText("false");
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteEndElement(); // DocResidence
	ElsIf Not IsBlankString(vRow.VisaNumber) And vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit Then
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("residencePermitDocument", vNSURIMigration);
		Else
			vXMLWriter.WriteStartElement("docResidence", vNSURIMigration);
		EndIf;
		
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("visa", vNSURIMigration);
		Else
			vXMLWriter.WriteStartElement("permResidencePermit", vNSURIMigration);
		EndIf;
		// Uid
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("uid");
			vXMLWriter.WriteText(vUID);
			vXMLWriter.WriteEndElement();
		EndIf;
		// Type
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteStartElement("type");
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteText("mig.residencePermitDocumentType");
		Else
			vXMLWriter.WriteText("DocumentType");
		EndIf;
		vXMLWriter.WriteEndElement();
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("id");
			vXMLWriter.WriteText("135709");
			vXMLWriter.WriteEndElement();
		Else
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("135709");
			vXMLWriter.WriteEndElement();
		EndIf;
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText("135709");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement(); // Type
		// Series
		If Not IsBlankString(vRow.VisaSeries) Then
			vXMLWriter.WriteStartElement("series");
			vXMLWriter.WriteText(vRow.VisaSeries);
			vXMLWriter.WriteEndElement();
		EndIf;
		// Number
		vXMLWriter.WriteStartElement("number");
		vXMLWriter.WriteText(vRow.VisaNumber);
		vXMLWriter.WriteEndElement();
		// Issued
		If ValueIsFilled(vRow.VisaIssuedDate) Then
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("issued");
			Else
				vXMLWriter.WriteStartElement("decisionDate");
			EndIf;
			vXMLWriter.WriteText(Format(vRow.VisaIssuedDate, "DF=yyyy-MM-dd"));
			vXMLWriter.WriteEndElement();
		EndIf;
		// ValidFrom
		If ValueIsFilled(vRow.VisaFromDate) Then
			vXMLWriter.WriteStartElement("validFrom");
			vXMLWriter.WriteText(Format(vRow.VisaFromDate, "DF=yyyy-MM-dd"));
			vXMLWriter.WriteEndElement();
		EndIf;
		// ValidTo
		If ValueIsFilled(vRow.VisaToDate) Then
			vXMLWriter.WriteStartElement("validTo");
			vXMLWriter.WriteText(Format(vRow.VisaToDate, "DF=yyyy-MM-dd"));
			vXMLWriter.WriteEndElement();
		EndIf;
		// Status
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("status");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("DocumentStatus");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("102877");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteEndElement(); // Status
			// Authority
			If Not IsBlankString(vRow.VisaIssuedBy) Then
				vXMLWriter.WriteStartElement("authority");
				vXMLWriter.WriteText(vRow.VisaIssuedBy);
				vXMLWriter.WriteEndElement();
			EndIf;
			// Decision number
			If Not IsBlankString(vRow.VisaIdentifier) Then
				vXMLWriter.WriteStartElement("decisionNumber", vNSURIFCCore);
				vXMLWriter.WriteText(TrimAll(vRow.VisaIdentifier));
				vXMLWriter.WriteEndElement();
			EndIf;
		EndIf;
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then 
			// Entry goal
			If ValueIsFilled(vRow.VisaEntryGoal) Then
				vXMLWriter.WriteStartElement("visitPurpose", vNSURIMigration);
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("EntryGoal");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText(TrimAll(vRow.VisaEntryGoal.Code));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.VisaEntryGoal.Code));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteEndElement(); // Entry goal
			Else
				vXMLWriter.WriteStartElement("visitPurpose", vNSURIMigration);
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("EntryGoal");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("103101");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("103101");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteEndElement(); // Entry goal
			EndIf;
		EndIf;
		vXMLWriter.WriteEndElement(); // PermResidencePermit
		
		// Entered
		vXMLWriter.WriteStartElement("entered", vNSURIMigration);
		vXMLWriter.WriteText("false");
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteEndElement(); // DocResidence
	Else // No VISA, TRP, PRP
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("residencePermitDocument", vNSURIMigration);
			
			vXMLWriter.WriteStartElement("visa", vNSURIMigration);
			// Entry goal
			If ValueIsFilled(vRow.VisaEntryGoal) Then
				vXMLWriter.WriteStartElement("visitPurpose", vNSURIMigration);
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("EntryGoal");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText(TrimAll(vRow.VisaEntryGoal.Code));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.VisaEntryGoal.Code));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteEndElement(); // Entry goal
			Else
				vXMLWriter.WriteStartElement("visitPurpose", vNSURIMigration);
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("EntryGoal");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("103101");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("103101");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteEndElement(); // Entry goal
			EndIf;
			vXMLWriter.WriteEndElement();
			
			// Entered
			vXMLWriter.WriteStartElement("entered", vNSURIMigration);
			vXMLWriter.WriteText("false");
			vXMLWriter.WriteEndElement();
			
			vXMLWriter.WriteEndElement();
		EndIf;
	EndIf; // Residence permit document
	
	// Migration card
	If Not IsBlankString(vRow.MigrationCardNumber) Then
		vXMLWriter.WriteStartElement("migrationCard", vNSURIMigration);
		vWrkURI = vNSURIMigration;
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("uid");
			vXMLWriter.WriteText(vUID);
			vXMLWriter.WriteEndElement(); // Uid
			vWrkURI = vNSURIFCCore;
		EndIf;
		If Not IsBlankString(vRow.MigrationCardSeries) Then
			vXMLWriter.WriteStartElement("series", vWrkURI);
			vXMLWriter.WriteText(TrimAll(vRow.MigrationCardSeries));
			vXMLWriter.WriteEndElement(); // Series
		EndIf;
		vXMLWriter.WriteStartElement("number", vWrkURI);
		vXMLWriter.WriteText(TrimAll(vRow.MigrationCardNumber));
		vXMLWriter.WriteEndElement(); // Number
		vXMLWriter.WriteStartElement("stayPeriod", vWrkURI);
		vXMLWriter.WriteStartElement("dateFrom");
		vXMLWriter.WriteText(Format(vRow.MigrationCardDateFrom, "DF=yyyy-MM-dd"));
		vXMLWriter.WriteEndElement(); // DateFrom
		If ValueIsFilled(vRow.MigrationCardDateTo) Then
			vXMLWriter.WriteStartElement("dateTo");
			vXMLWriter.WriteText(Format(vRow.MigrationCardDateTo, "DF=yyyy-MM-dd"));
			vXMLWriter.WriteEndElement(); // DateTo
		EndIf;
		vXMLWriter.WriteEndElement(); // StayPeriod
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("entranceDate", vWrkURI);
			vXMLWriter.WriteText(Format(vRow.BorderCrossingDate, "DF=yyyy-MM-dd"));
			vXMLWriter.WriteEndElement(); // EntranceDate
		EndIf;
		// Entrance checkpoint
		If ValueIsFilled(vRow.CheckPointNumber) Then
			vXMLWriter.WriteStartElement("entranceCheckpoint", vWrkURI);
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("officialOrgan");
			vXMLWriter.WriteEndElement(); // Type
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText(TrimAll(vRow.CheckPointNumber.Code));
				vXMLWriter.WriteEndElement(); // Id
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.CheckPointNumber.Code));
				vXMLWriter.WriteEndElement(); // Element
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText(TrimAll(vRow.CheckPointNumber.Code));
				vXMLWriter.WriteEndElement(); // Element
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.CheckPointNumber));
				vXMLWriter.WriteEndElement(); // Element
			EndIf;
			vXMLWriter.WriteEndElement(); // EntranceCheckpoint
		EndIf;
		vXMLWriter.WriteEndElement(); // MigrationCard
	EndIf;
	
	// Hotel, Company and Employee
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost  
	   And Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
		// Sono
		vXMLWriter.WriteStartElement("sono", vNSURIFCCore);
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteText("officialOrgan");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText(TrimAll(OfficialOrganID));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement(); // Sono
		
		// Notification number
		vNotificationNumber = TrimAll(HotelCode) + "/" + TrimAll(OfficialOrganCode) + "/" + Format(vRow.RecordDate, "DF=yy") + "/" + Right(TrimAll(vRow.RecordNumber), 6); 
		vXMLWriter.WriteStartElement("notificationNumber", vNSURIStaying);
		vXMLWriter.WriteText(vNotificationNumber);
		vXMLWriter.WriteEndElement(); // NotificationNumber
		
		// Notice from
		vXMLWriter.WriteStartElement("noticeFrom", vNSURIMigration);
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteText("NoticeFrom");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText(TrimAll(NoticeFromID));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement(); // NoticeFrom
		
		// ProlongationReason
		vXMLWriter.WriteStartElement("prolongationReason", vNSURIMigration);
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteText("prolongationReason");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText("10406");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement(); // ProlongationReason
		
		// State program member
		vXMLWriter.WriteStartElement("stateProgramMember", vNSURIMigration);
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteText("mig.specialStatus");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText("1019");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement(); // StateProgramMember

		// First arrival
		
		// Host
		vXMLWriter.WriteStartElement("host", vNSURIMigration);
		vXMLWriter.WriteStartElement("organization", vNSURIMigration);
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("uid");
			vXMLWriter.WriteText(vUID);
			vXMLWriter.WriteEndElement();
		EndIf;
		vXMLWriter.WriteStartElement("inn");
		vXMLWriter.WriteText(TrimAll(Company.TIN));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("name");
		vXMLWriter.WriteText(TrimAll(Company.Description));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("address");
		vXMLWriter.WriteStartElement("address");
		vXMLWriter.WriteStartElement("russianAddress");
		vXMLWriter.WriteStartElement("addressObjectString");
		vXMLWriter.WriteText(FormatAddressString(TrimAll(CompanyAddress)));
		vXMLWriter.WriteEndElement(); // AddressObjectString
		// Housing
		If Not IsBlankString(CompanyAddressHouse) Then
			vXMLWriter.WriteStartElement("housing");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("addressObjectType");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("1202");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteEndElement(); // Type
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText(TrimAll(CompanyAddressHouse));
			vXMLWriter.WriteEndElement(); 
			vXMLWriter.WriteEndElement(); // Housing
		EndIf;
		If Not IsBlankString(CompanyAddressBuilding) Then
			vXMLWriter.WriteStartElement("housing");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("addressObjectType");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("1203");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteEndElement(); // Type
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText(TrimAll(CompanyAddressBuilding));
			vXMLWriter.WriteEndElement(); 
			vXMLWriter.WriteEndElement(); // Housing
		EndIf;
		vXMLWriter.WriteEndElement(); // RussianAddress
		vXMLWriter.WriteEndElement(); // Address
		vXMLWriter.WriteEndElement(); // Address
		vXMLWriter.WriteEndElement(); // Organization
		
		// Person data document
		vXMLWriter.WriteStartElement("personDataDocument", vNSURIMigration);
		// Person
		vXMLWriter.WriteStartElement("person");
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("uid");
			vXMLWriter.WriteText(vEmployeeUID);
			vXMLWriter.WriteEndElement(); // Uid
			vXMLWriter.WriteStartElement("personUid");
			vXMLWriter.WriteText(vEmployeeUID);
			vXMLWriter.WriteEndElement(); // PersonId
		EndIf;
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("lastName");
			vXMLWriter.WriteText(Employee.LastName);
			vXMLWriter.WriteEndElement(); // LastName
			vXMLWriter.WriteStartElement("firstName");
			vXMLWriter.WriteText(Employee.FirstName);
			vXMLWriter.WriteEndElement(); // FirstName
			vXMLWriter.WriteStartElement("middleName");
			vXMLWriter.WriteText(Employee.SecondName);
			vXMLWriter.WriteEndElement(); // MiddleName
		EndIf;
		vXMLWriter.WriteStartElement("gender");
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteText("Gender");
		vXMLWriter.WriteEndElement();
		If Employee.Sex = Enums.Sex.Male Then
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("M");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText("Мужской");
			vXMLWriter.WriteEndElement();
		Else
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("F");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText("Женский");
			vXMLWriter.WriteEndElement();
		EndIf;
		vXMLWriter.WriteEndElement(); // Gender
		vXMLWriter.WriteStartElement("birthDate");
		vXMLWriter.WriteText(Format(Employee.DateOfBirth, "DF=dd.MM.yyyy"));
		vXMLWriter.WriteEndElement(); // BirthDate
		vXMLWriter.WriteEndElement(); // Person
		// Document
		vXMLWriter.WriteStartElement("document");
		vXMLWriter.WriteStartElement("uid");
		vXMLWriter.WriteText(String(Employee.IdentityDocumentType.UUID()));
		vXMLWriter.WriteEndElement(); // Uid
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteText("DocumentType");
		vXMLWriter.WriteEndElement(); // Type
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText(TrimAll(Employee.IdentityDocumentType.ExternalCode));
		vXMLWriter.WriteEndElement(); // Element
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(TrimAll(Employee.IdentityDocumentType));
		vXMLWriter.WriteEndElement(); // Value
		vXMLWriter.WriteEndElement(); // Type
		If Not IsBlankString(Employee.IdentityDocumentSeries) Then
			vXMLWriter.WriteStartElement("series");
			vXMLWriter.WriteText(TrimAll(Employee.IdentityDocumentSeries));
			vXMLWriter.WriteEndElement(); // Series
		EndIf;
		vXMLWriter.WriteStartElement("number");
		vXMLWriter.WriteText(TrimAll(Employee.IdentityDocumentNumber));
		vXMLWriter.WriteEndElement(); // Number
		vOfficialOrgan = TrimAll(Employee.IdentityDocumentIssuedBy);
		vOfficialOrganID = GetOfficialOrganID(TrimAll(Employee.IdentityDocumentUnitCode), TrimAll(Employee.IdentityDocumentIssuedBy));
		vXMLWriter.WriteStartElement("authorityOrgan");
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteText("officialOrgan");
		vXMLWriter.WriteEndElement(); // Type
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText(vOfficialOrganID);
		vXMLWriter.WriteEndElement(); // Element
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(vOfficialOrgan);
		vXMLWriter.WriteEndElement(); // Value
		vXMLWriter.WriteEndElement(); // AuthorityOrgan
		vXMLWriter.WriteStartElement("issued");
		vXMLWriter.WriteText(Format(Employee.IdentityDocumentIssueDate, "DF=yyyy-MM-dd"));
		vXMLWriter.WriteEndElement(); // Issued
		// Status
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("status");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("DocumentStatus");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("102877");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteEndElement(); // Status
		EndIf;
		vXMLWriter.WriteEndElement(); // Document
			
		// Entered
		vXMLWriter.WriteStartElement("entered");
		vXMLWriter.WriteText("false");
		vXMLWriter.WriteEndElement(); // Entered
		vXMLWriter.WriteEndElement(); // PersonDataDocument
		// Contact info
		vXMLWriter.WriteStartElement("contactInfo", vNSURIMigration);
		vXMLWriter.WriteStartElement("address");
		vXMLWriter.WriteStartElement("russianAddress");
		vXMLWriter.WriteStartElement("addressObjectString");
		vXMLWriter.WriteText(FormatAddressString(TrimAll(EmployeeAddress)));
		vXMLWriter.WriteEndElement(); // AddressObjectString
		// Housing
		If Not IsBlankString(EmployeeAddressHouse) Then
			vXMLWriter.WriteStartElement("housing");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("addressObjectType");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("1202");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteEndElement(); // Type
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText(TrimAll(EmployeeAddressHouse));
			vXMLWriter.WriteEndElement(); 
			vXMLWriter.WriteEndElement(); // Housing
		EndIf;
		If Not IsBlankString(EmployeeAddressBuilding) Then
			vXMLWriter.WriteStartElement("housing");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("addressObjectType");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("element");
			vXMLWriter.WriteText("1203");
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteEndElement(); // Type
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText(TrimAll(EmployeeAddressBuilding));
			vXMLWriter.WriteEndElement(); 
			vXMLWriter.WriteEndElement(); // Housing
		EndIf;
		vXMLWriter.WriteEndElement(); // RussianAddress
		vXMLWriter.WriteEndElement(); // Address
		vXMLWriter.WriteEndElement(); // ContactInfo
		vXMLWriter.WriteEndElement(); // Host
	EndIf; // Not Elpost and Not KonturFMS
	
	// EntrancePurpose
	If ValueIsFilled(vRow.TripPurpose) Then
		If Not IsBlankString(vRow.TripPurposeID) Then			
			vXMLWriter.WriteStartElement("entrancePurpose", vNSURIMigration);
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("VisitPurpose");
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText(TrimAll(vRow.TripPurposeId));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.TripPurposeId));
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText(TrimAll(vRow.TripPurposeId));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.TripPurpose));
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement();
		EndIf;
	EndIf;
	// EntrancePurpose
	
	// HotelStayPeriod
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("hotelStayPeriod", vNSURIMigration);
	Else
		vXMLWriter.WriteStartElement("stayPeriod", vNSURIMigration);
	EndIf;
	vXMLWriter.WriteStartElement("dateFrom");
	vXMLWriter.WriteText(Format(vRow.CheckInDate, "DF=yyyy-MM-dd"));
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteStartElement("dateTo");
	vXMLWriter.WriteText(Format(vRow.ExpectedCheckOutDate, "DF=yyyy-MM-dd"));
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();

	// RoomNumber
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS And 
	   Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("roomNumber", vNSURIMigration);
		vXMLWriter.WriteText(vAccDoc.Room.Description);
		vXMLWriter.WriteEndElement();
	EndIf;
	
	// Document scans
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("documentScans", vNSURIMigration);
		vXMLWriter.WriteStartElement("identityDocumentNumber", vNSURIMigration);
		vXMLWriter.WriteText(vUID);
		vXMLWriter.WriteEndElement(); // IdentityDocumentNumber
	  
		// DocumentPhoto Identity document scans
		vScans = GetIdentityDocScan(vAccDoc);
		For Each vScan In vScans Do
			vError = "";
			vBinaryData = Undefined;
			vBase64String = Undefined;
			Try
				vScanData = vScan.ScanPicture.Get();
				If TypeOf(vScanData) = Type("String") Then
					vBinaryData = New BinaryData(GetImageCatalogName(vScan.Ref) + TrimAll(vScanData));
				ElsIf TypeOf(vScanData) = Type("Picture") Then
					vBinaryData = vScanData.GetBinaryData();
				EndIf;
				If vBinaryData <> Undefined Then
					If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
						vBase64String = HexString(vBinaryData);
					Else
						vBase64String = Base64String(vBinaryData);
					EndIf;
				EndIf;
			Except
				vError = ErrorDescription();
				WriteLogEvent(NStr("en='DataProcessor.ExportGuestsToUFMSTerritoryApp'; de='DataProcessor.ExportGuestsToUFMSTerritoryApp'; ru='Обработка.ЭкспортДанныхГостейВУФМС'"), EventLogLevel.Warning, Metadata.DataProcessors.ExportGuestsToUFMSTerritoryApp, vAccDoc, "Failed to get identity document scan from value storage!");
			EndTry;
			If Not ValueIsFilled(vError) And vBase64String <> Undefined Then
				If ValueIsFilled(vScan.ScanConfiguration) Then
					vScanConfiguration = vScan.ScanConfiguration;
					vScanId = TrimAll(vScanConfiguration.IdentityDocumentType.ExternalCode);
					If vScanId <> "103012" And vScanId <> "135709" And vScanId <> "135710" And 
					   Not vScanConfiguration.IsVisa And Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsFanId Then
						Continue;
					EndIf;
					
					If vScanConfiguration.IsVisa Or vScanConfiguration.IsFanId Then
						vXMLWriter.WriteStartElement("residencePermitDocumentScan", vNSURIMigration);
					ElsIf vScanConfiguration.IsMigrationCard Then
						vXMLWriter.WriteStartElement("migrationCardDocumentScan", vNSURIMigration);
					ElsIf ValueIsFilled(vScanConfiguration.IdentityDocumentType) Then
						vXMLWriter.WriteStartElement("identityDocumentScan", vNSURIMigration);
					EndIf;
						
						vXMLWriter.WriteStartElement("type");
							vXMLWriter.WriteStartElement("type");
							If vScanConfiguration.IsVisa Or vScanConfiguration.IsFanId Then
								vXMLWriter.WriteText("mig.residencePermitDocumentType");
							ElsIf vScanConfiguration.IsMigrationCard Then
								vXMLWriter.WriteText("DocumentType");
							ElsIf ValueIsFilled(vScanConfiguration.IdentityDocumentType) Then
								vXMLWriter.WriteText("mig.identityDocumentType");
							EndIf;
							vXMLWriter.WriteEndElement(); // Type
							vXMLWriter.WriteStartElement("id");
							If vScanConfiguration.IsVisa Then
								vXMLWriter.WriteText("139356");
							ElsIf vScanConfiguration.IsMigrationCard Then
								vXMLWriter.WriteText("103022");
							ElsIf vScanConfiguration.IsFanId Then
								vXMLWriter.WriteText("fan_id");
							ElsIf ValueIsFilled(vScanConfiguration.IdentityDocumentType) Then
								vXMLWriter.WriteText(TrimAll(vScanConfiguration.IdentityDocumentType.ExternalCode));
							EndIf;
							vXMLWriter.WriteEndElement(); // Id
							vXMLWriter.WriteStartElement("value");
							If vScanConfiguration.IsVisa Then
								vXMLWriter.WriteText("Виза");
							ElsIf vScanConfiguration.IsMigrationCard Then
								vXMLWriter.WriteText("Миграционная карта");
							ElsIf vScanConfiguration.IsFanId Then
								vXMLWriter.WriteText("FAN ID");
							ElsIf ValueIsFilled(vScanConfiguration.IdentityDocumentType) Then
								vXMLWriter.WriteText(TrimAll(vScanConfiguration.IdentityDocumentType));
							EndIf;
							vXMLWriter.WriteEndElement(); // Value
						vXMLWriter.WriteEndElement(); // Type
						
						vXMLWriter.WriteStartElement("content");
						vXMLWriter.WriteText(vBase64String);
						vXMLWriter.WriteEndElement(); // Content
						
						vXMLWriter.WriteStartElement("mimeType");
						vXMLWriter.WriteText("image/jpeg");
						vXMLWriter.WriteEndElement(); // MimeType

					vXMLWriter.WriteEndElement(); // IdentityDocumentScan
				EndIf;
			EndIf;
		EndDo;
		
		vXMLWriter.WriteEndElement(); // DocumentScans
	EndIf;
	  
	vXMLWriter.WriteEndElement(); // Case
	
	// Close document
	If pXMLWriter = Undefined Then
		vXMLWriter.Close();
	EndIf;
	
	// Write record to the exported guests
	vHotel = ?(ValueIsFilled(Hotel), Hotel, SessionParameters.CurrentHotel);
	If ValueIsFilled(vHotel) Then
		vEGRM = InformationRegisters.GuestsExportedToUMMS.CreateRecordManager();
		vEGRM.Hotel = vHotel;
		vEGRM.Guest = vGuest;
		vEGRM.CheckOutDate = BegOfDay(vRow.ExpectedCheckOutDate);
		vEGRM.CheckInDate = BegOfDay(vRow.CheckInDate);
		vEGRM.CaseUUID = vUID;
		vEGRM.CaseIsRemovedFromRegister = False;
		vEGRM.Write(True);
	EndIf;
EndProcedure // WriteCase

// -----------------------------------------------------------------------------
Procedure WriteXMLAttribute(pXMLWriter, pNameAttribute, pTextAttribute)
	If ValueIsFilled(pTextAttribute) Then
		pXMLWriter.WriteStartAttribute(pNameAttribute);
		pXMLWriter.WriteText(pTextAttribute);
		pXMLWriter.WriteEndAttribute();
	EndIf;
EndProcedure // WriteXMLAttribute

// -----------------------------------------------------------------------------
Procedure WriteForeignersVegaCase(vRow, rFullFilePath, rScanArr, pTempDir = Undefined, pFullFileName)
	rFullFilePath = cmGetFullFileName(pFullFileName, ?(pTempDir = Undefined, ExportDirForeigners, pTempDir)) + ".xml";;
	vGuest = vRow.Guest;
	vRegRecord = vRow.RegistryRecord;
	vUID = String(vRegRecord.UUID());
	vAccDoc = vRow.Accommodation;
	
	vXMLWriter = New XMLWriter();
	vXMLWriter.OpenFile(rFullFilePath, "UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	
	#Region registration 
	vXMLWriter.WriteStartElement("registration");
	
	WriteXMLAttribute(vXMLWriter, "dateIn", Format(vRow.CheckInDate, "DF=yyyy-MM-dd"));
	WriteXMLAttribute(vXMLWriter, "dateOut", Format(vRow.ExpectedCheckOutDate, "DF=yyyy-MM-dd"));
	WriteXMLAttribute(vXMLWriter, "room", vAccDoc.Room.Description);
	vXMLWriter.WriteNamespaceMapping("", "http://www.sonarplus.ru/replication/vegaimport");
	
	#Region person
	vXMLWriter.WriteStartElement("person");
	
	WriteXMLAttribute(vXMLWriter, "lastNameLat", TrimAll(vRow.LastNameLat));
	WriteXMLAttribute(vXMLWriter, "firstNameLat", TrimAll(vRow.FirstNameLat));
	If ValueIsFilled(TrimAll(vRow.SecondNameLat)) Then
		WriteXMLAttribute(vXMLWriter, "middleNameLat", TrimAll(vRow.SecondNameLat));
	EndIf;
	WriteXMLAttribute(vXMLWriter, "lastName", TrimAll(vRow.LastName));
	WriteXMLAttribute(vXMLWriter, "firstName", TrimAll(vRow.FirstName));
	If ValueIsFilled(TrimAll(vRow.SecondName)) Then
		WriteXMLAttribute(vXMLWriter, "middleName", TrimAll(vRow.SecondName));
	EndIf;
	
	// Birth date
	WriteXMLAttribute(vXMLWriter, "birthDate", Format(vRow.DateOfBirth, "DF=yyyy-MM-dd"));
	
	vXMLWriter.WriteStartElement("gender");
	WriteXMLAttribute(vXMLWriter, "type", "S_SEX");
	WriteXMLAttribute(vXMLWriter, "dictvalue", ?(vRow.Sex = Enums.Sex.Male, "МУЖ.", "ЖЕН."));
	vXMLWriter.WriteEndElement(); // Gender
	
	vXMLWriter.WriteStartElement("citizenship");
	WriteXMLAttribute(vXMLWriter, "type", "S_STATE");
	WriteXMLAttribute(vXMLWriter, "dictvalue", ?(ValueIsFilled(vRow.Citizenship), vRow.Citizenship, "ЛИЦО БЕЗ ГРАЖДАНСТВА"));
	vXMLWriter.WriteEndElement(); // Citizenship
	
	#Region birthPlace
	vXMLWriter.WriteStartElement("birthPlace");
	If ValueIsFilled(vRow.PlaceOfBirthRegion) Then
		WriteXMLAttribute(vXMLWriter, "main_region", vRow.PlaceOfBirthRegion);
	EndIf;
	If ValueIsFilled(vRow.PlaceOfBirthRegion) Then
		WriteXMLAttribute(vXMLWriter, "district", vRow.PlaceOfBirthArea);
	EndIf;
	If ValueIsFilled(vRow.PlaceOfBirthRegion) Then
		WriteXMLAttribute(vXMLWriter, "city", vRow.PlaceOfBirthCity);
	EndIf;
	
	#Region birthPlace
	vXMLWriter.WriteStartElement("country");
	WriteXMLAttribute(vXMLWriter, "type", "S_STATE");
	WriteXMLAttribute(vXMLWriter, "dictvalue", vRow.PlaceOfBirthCountry);
	vXMLWriter.WriteEndElement(); // Country
	#EndRegion
	
	vXMLWriter.WriteEndElement(); // BirthPlace
	#EndRegion
	
	vXMLWriter.WriteEndElement(); // Person
	#EndRegion
	
	#Region documentRelation
	vXMLWriter.WriteStartElement("documentRelation");
	
	#Region document
	vXMLWriter.WriteStartElement("document");
	
	If ValueIsFilled(vRow.IdentityDocumentSeries) Then
		WriteXMLAttribute(vXMLWriter, "series", vRow.IdentityDocumentSeries);
	EndIf;
	WriteXMLAttribute(vXMLWriter, "number", vRow.IdentityDocumentNumber);
	If ValueIsFilled(vRow.IdentityDocumentIssueDate) Then
		WriteXMLAttribute(vXMLWriter, "issued", Format(vRow.IdentityDocumentIssueDate, "DF=yyyy-MM-dd"));
	EndIf;
	If ValueIsFilled(vRow.IdentityDocumentValidToDate) Then
		WriteXMLAttribute(vXMLWriter, "expired", Format(vRow.IdentityDocumentValidToDate, "DF=yyyy-MM-dd"));
	EndIf;
	
	vXMLWriter.WriteStartElement("type");
	
	WriteXMLAttribute(vXMLWriter, "type", "S_DOCUM");
	WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vRow.IdentityDocumentType));
	
	vXMLWriter.WriteEndElement(); // Type
	
	vXMLWriter.WriteStartElement("authorityOrgan");
	
	WriteXMLAttribute(vXMLWriter, "type", "S_FMS");
	WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vRow.IdentityDocumentUnitCode));
	
	vXMLWriter.WriteEndElement(); // AuthorityOrgan
	
	vXMLWriter.WriteEndElement(); // Document
	#EndRegion
	
	vXMLWriter.WriteStartElement("relation");
	
	WriteXMLAttribute(vXMLWriter, "type", "TYPE_SV");
	WriteXMLAttribute(vXMLWriter, "dictvalue", "ВЛАДЕЛЕЦ");
	
	vXMLWriter.WriteEndElement(); // Relation
	
	vXMLWriter.WriteEndElement(); // DocumentRelation
	#EndRegion
	
	#Region documentResidence
	If Not IsBlankString(vRow.VisaNumber) And (vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.Visa Or vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.ElectronicVisa) Then
		vXMLWriter.WriteStartElement("documentResidence");
		
		If ValueIsFilled(vRow.VisaSeries) Then
			WriteXMLAttribute(vXMLWriter, "series", vRow.VisaSeries);
		EndIf;	
		WriteXMLAttribute(vXMLWriter, "number", vRow.VisaNumber);
		If ValueIsFilled(vRow.VisaIssuedDate) Then
			WriteXMLAttribute(vXMLWriter, "issued", Format(vRow.VisaIssuedDate, "DF=yyyy-MM-dd"));
		EndIf;
		If ValueIsFilled(vRow.VisaToDate) Then
			WriteXMLAttribute(vXMLWriter, "expired", Format(vRow.VisaToDate, "DF=yyyy-MM-dd"));
		EndIf;
		If vRow.VisaDays > 0 Then
			WriteXMLAttribute(vXMLWriter, "stayDuration", Format(vRow.VisaDays, "ND=4; NFD=0; NG="));
		EndIf;
		If ValueIsFilled(vRow.VisaIdentifier) Then
			WriteXMLAttribute(vXMLWriter, "identitifier", TrimAll(vRow.VisaIdentifier));
		EndIf;
		If ValueIsFilled(vRow.VisaFromDate) Then
			WriteXMLAttribute(vXMLWriter, "validFrom", Format(vRow.VisaFromDate, "DF=yyyy-MM-dd"));
		EndIf;
		
		vXMLWriter.WriteStartElement("type");
		
		WriteXMLAttribute(vXMLWriter, "type", "S_DOCUM");
		WriteXMLAttribute(vXMLWriter, "dictvalue", "ВИЗА");
	
		vXMLWriter.WriteEndElement(); // Type
		
		If ValueIsFilled(vRow.VisaIssuedBy) Then
			vXMLWriter.WriteStartElement("authority");
			
			vXMLWriter.WriteText(vRow.VisaIssuedBy);
			
			vXMLWriter.WriteEndElement(); // Authority
		EndIf;
		
		vXMLWriter.WriteStartElement("visaCategory");
	
		WriteXMLAttribute(vXMLWriter, "type", "VIS_CATG");
		WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vRow.VisaType));
		
		vXMLWriter.WriteEndElement(); // VisaCategory
		
		If ValueIsFilled(vRow.VisaMultiplicity) Then
			
			vXMLWriter.WriteStartElement("visaMultiplicity");
			
			WriteXMLAttribute(vXMLWriter, "type", "VIS_MULT");
			WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vRow.VisaMultiplicity));
		
			vXMLWriter.WriteEndElement(); // VisaMultiplicity
			
		EndIf;
		
		If ValueIsFilled(vRow.VisaEntryGoal) Then
			
			vXMLWriter.WriteStartElement("visaPurpose");
			
			WriteXMLAttribute(vXMLWriter, "type", "VIS_PURP");
			WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vRow.VisaEntryGoal));
		
			vXMLWriter.WriteEndElement(); // VisaPurpose	
			
		EndIf;
		
	    vXMLWriter.WriteEndElement(); // DocumentResidence
	ElsIf Not IsBlankString(vRow.VisaIdentifier) And vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit Then		
		vXMLWriter.WriteStartElement("documentResidence");
		
		WriteXMLAttribute(vXMLWriter, "number", vRow.VisaIdentifier);
		If ValueIsFilled(vRow.VisaToDate) Then
			WriteXMLAttribute(vXMLWriter, "expired", Format(vRow.VisaToDate, "DF=yyyy-MM-dd"));
		EndIf;
		If ValueIsFilled(vRow.VisaIssuedDate) Then
			WriteXMLAttribute(vXMLWriter, "decisionDate", Format(vRow.VisaIssuedDate, "DF=yyyy-MM-dd"));
		EndIf;
		If ValueIsFilled(vRow.VisaIdentifier) Then
			WriteXMLAttribute(vXMLWriter, "decisionNumber", TrimAll(vRow.VisaIdentifier));
		EndIf;
		
		vXMLWriter.WriteStartElement("type");
		
		WriteXMLAttribute(vXMLWriter, "type", "S_DOCUM");
		WriteXMLAttribute(vXMLWriter, "dictvalue", ?(ValueIsFilled(vRow.Citizenship) And vRow.Citizenship.Code <> 0 And Upper(TrimAll(vRow.Citizenship.Description)) <> "БЕЗ ГРАЖДАНСТВА", "РАЗРЕШЕНИЕ НА ВРЕМЕННОЕ ПРОЖИВАНИЕ ИГ", "РАЗРЕШЕНИЕ НА ВРЕМЕННОЕ ПРОЖИВАНИЕ ЛБГ"));
	
		vXMLWriter.WriteEndElement(); // Type
		
		If ValueIsFilled(vRow.VisaIssuedBy) Then
			vXMLWriter.WriteStartElement("authority");
			
			vXMLWriter.WriteText(vRow.VisaIssuedBy);
			
			vXMLWriter.WriteEndElement(); // Authority
		EndIf;
		
		If ValueIsFilled(vRow.VisaEntryGoal) Then
			
			vXMLWriter.WriteStartElement("visaPurpose");
			
			WriteXMLAttribute(vXMLWriter, "type", "VIS_PURP");
			WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vRow.VisaEntryGoal));
		
			vXMLWriter.WriteEndElement(); //visaPurpose	
			
		EndIf;
		
		vXMLWriter.WriteEndElement(); // DocumentResidence
	ElsIf Not IsBlankString(vRow.VisaNumber) And vRow.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit Then
		vXMLWriter.WriteStartElement("documentResidence");
		
		If ValueIsFilled(vRow.VisaSeries) Then
			WriteXMLAttribute(vXMLWriter, "series", vRow.VisaSeries);
		EndIf;
		WriteXMLAttribute(vXMLWriter, "number", vRow.VisaIdentifier);
		If ValueIsFilled(vRow.VisaIssuedDate) Then
			WriteXMLAttribute(vXMLWriter, "decisionDate", Format(vRow.VisaIssuedDate, "DF=yyyy-MM-dd"));
		EndIf;
		If ValueIsFilled(vRow.VisaToDate) Then
			WriteXMLAttribute(vXMLWriter, "expired", Format(vRow.VisaToDate, "DF=yyyy-MM-dd"));
		EndIf;
		If ValueIsFilled(vRow.VisaIdentifier) Then
			WriteXMLAttribute(vXMLWriter, "identitifier", TrimAll(vRow.VisaIdentifier));
		EndIf;
		If ValueIsFilled(vRow.VisaFromDate) Then
			WriteXMLAttribute(vXMLWriter, "validFrom", Format(vRow.VisaFromDate, "DF=yyyy-MM-dd"));
		EndIf;
		
		vXMLWriter.WriteStartElement("type");
		
		WriteXMLAttribute(vXMLWriter, "type", "S_DOCUM");
		WriteXMLAttribute(vXMLWriter, "dictvalue", ?(ValueIsFilled(vRow.Citizenship) And vRow.Citizenship.Code <> 0 And Upper(TrimAll(vRow.Citizenship.Description)), "ВИД НА ЖИТЕЛЬСТВО ИГ", "ВИД НА ЖИТЕЛЬСТВО ЛБГ"));
	
		vXMLWriter.WriteEndElement(); // Type

		If ValueIsFilled(vRow.VisaIssuedBy) Then
			vXMLWriter.WriteStartElement("authority");
			
			vXMLWriter.WriteText(vRow.VisaIssuedBy);
			
			vXMLWriter.WriteEndElement(); // Authority
		EndIf;
		
		If ValueIsFilled(vRow.VisaEntryGoal) Then
			
			vXMLWriter.WriteStartElement("visaPurpose");
			
			WriteXMLAttribute(vXMLWriter, "type", "VIS_PURP");
			WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vRow.VisaEntryGoal));
		
			vXMLWriter.WriteEndElement(); // VisaPurpose	
			
		EndIf;
		
		vXMLWriter.WriteEndElement(); // DocumentResidence
	EndIf;	
	#EndRegion	
	
	#Region migrationCard
	If Not IsBlankString(vRow.MigrationCardNumber) Then
		vXMLWriter.WriteStartElement("migrationCard");
		
		If ValueIsFilled(vRow.MigrationCardSeries) Then
			WriteXMLAttribute(vXMLWriter, "series", vRow.MigrationCardSeries);
		EndIf;
		WriteXMLAttribute(vXMLWriter, "number", vRow.MigrationCardNumber);
		WriteXMLAttribute(vXMLWriter, "dateFrom", Format(vRow.MigrationCardDateFrom, "DF=yyyy-MM-dd"));
		If ValueIsFilled(vRow.MigrationCardDateTo) Then 
			WriteXMLAttribute(vXMLWriter, "dateTo", Format(vRow.MigrationCardDateTo, "DF=yyyy-MM-dd"));
		EndIf;
		
		If ValueIsFilled(vRow.TripPurpose) Then
			vXMLWriter.WriteStartElement("purpose");
			
			WriteXMLAttribute(vXMLWriter, "type", "S_PURPOS");
			WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vRow.TripPurpose));
		
			vXMLWriter.WriteEndElement(); // Purpose
		EndIf;
		
		If ValueIsFilled(vRow.CheckPointNumber) Then
			vXMLWriter.WriteStartElement("checkpoint");
			
			WriteXMLAttribute(vXMLWriter, "type", "S_KPP");
			WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vRow.CheckPointNumber));
		
			vXMLWriter.WriteEndElement(); // Checkpoint
		EndIf;
		
		vXMLWriter.WriteEndElement(); // MigrationCard
	EndIf;
	#EndRegion
	
	#Region regAddress
	If ValueIsFilled(HotelCode) Then
		vXMLWriter.WriteStartElement("regAddress");
		
		WriteXMLAttribute(vXMLWriter, "type", "ADDR_REG");
		WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(HotelCode));
	
		vXMLWriter.WriteEndElement(); // RegAddress
	EndIf;	
	#EndRegion

	#Region embeddings	
	vXMLWriter.WriteStartElement("embeddings");
	
	vScans = GetIdentityDocScan(vAccDoc);
	For Each vScan In vScans Do
		vError = "";
		vBinaryData = Undefined;
		vBase64String = Undefined;
		Try
			vScanData = vScan.ScanPicture.Get();
			If TypeOf(vScanData) = Type("String") Then
				vBinaryData = New BinaryData(GetImageCatalogName(vScan.Ref) + TrimAll(vScanData));
			ElsIf TypeOf(vScanData) = Type("Picture") Then
				vBinaryData = vScanData.GetBinaryData();
			EndIf;
		Except
			vError = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.ExportGuestsToUFMSTerritoryApp'; de='DataProcessor.ExportGuestsToUFMSTerritoryApp'; ru='Обработка.ЭкспортДанныхГостейВУФМС'"), EventLogLevel.Warning, Metadata.DataProcessors.ExportGuestsToUFMSTerritoryApp, vAccDoc, "Failed to get identity document scan from value storage!");
		EndTry;
		If Not ValueIsFilled(vError) And vBinaryData <> Undefined Then
			If ValueIsFilled(vScan.ScanConfiguration) Then
				vScanConfiguration = vScan.ScanConfiguration;
				vScanId = TrimAll(vScanConfiguration.IdentityDocumentType.ExternalCode);
				If vScanId <> "103012" And vScanId <> "135709" And vScanId <> "135710" And 
				   Not vScanConfiguration.IsVisa And Not vScanConfiguration.IsMigrationCard And Not vScanConfiguration.IsFanId Then
					Continue;
				EndIf;
				
				vScanName = TrimAll(New UUID()) + ".png"; 
				vFullScanPath = cmGetFullFileName("OUT\images\", ?(pTempDir = Undefined, ExportDirForeigners, pTempDir)); 
				vBinaryData.Write(vFullScanPath + vScanName);
				rScanArr.Add(vFullScanPath);
				
				vXMLWriter.WriteStartElement("scanneddocument");
				
				WriteXMLAttribute(vXMLWriter, "filename", vScanName);
				
				vXMLWriter.WriteStartElement("doctype");
			
				WriteXMLAttribute(vXMLWriter, "type", "S_DOCUM");
				WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vScanConfiguration.IdentityDocumentType));
			
				vXMLWriter.WriteEndElement(); // Doctype
				
				vXMLWriter.WriteEndElement(); // Scanneddocument
			EndIf;
		EndIf;
	EndDo;
	
	vXMLWriter.WriteEndElement(); // Embeddings
	#EndRegion
	
	vXMLWriter.WriteEndElement(); // Registration
	#EndRegion
	
	vXMLWriter.Close();
	
	// Write record to the exported guests
	vHotel = ?(ValueIsFilled(Hotel), Hotel, SessionParameters.CurrentHotel);
	If ValueIsFilled(vHotel) Then
		vEGRM = InformationRegisters.GuestsExportedToUMMS.CreateRecordManager();
		vEGRM.Hotel = vHotel;
		vEGRM.Guest = vGuest;
		vEGRM.CheckOutDate = BegOfDay(vRow.ExpectedCheckOutDate);
		vEGRM.CheckInDate = BegOfDay(vRow.CheckInDate);
		vEGRM.CaseUUID = vUID;
		vEGRM.CaseIsRemovedFromRegister = False;
		vEGRM.Write(True);
	EndIf;
EndProcedure // WriteVegaCase

// -----------------------------------------------------------------------------
Procedure WriteToForeignersFiles(pExportTable, pErrors, pThinClient = False, pAddressStorageForeigners) 
	If pExportTable <> Undefined And pExportTable.Count() > 0 Then
		If pThinClient Then
			vFilesList = New ValueList();
			// Temp dir at server to create files and archive
			vExportDirForeigners = TempFilesDir();
			vPath = cmGetFullFileName("OUT", vExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
			// Zip all output files
			vZPFileName = vPath + "\" + pmGetForeignersZIPFileName();
			vZP = New ZipFileWriter(vZPFileName);
			// Do for each record in the list 
			For Each vRow In pExportTable Do
				vErrorRow = pErrors.Find(vRow.RegistryRecord, "Document");
				If vErrorRow = Undefined Then
					vFullFileName = "";
					
					WriteCase(vRow, , , vFullFileName, vExportDirForeigners);
					
					If Not IsBlankString(vFullFileName) Then
						If vFilesList.FindByValue(vFullFileName) = Undefined Then
							vFilesList.Add(vFullFileName);
							
							vZP.Add(vFullFileName, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.DontProcess);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vZP.Write();
			// Clear OUT directory from xml files
			DeleteFiles(vPath, "*.xml");
			// Clear IN directory
			vPath = cmGetFullFileName("IN", vExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
			pAddressStorageForeigners = PutToTempStorage(New BinaryData(vZPFileName), New UUID());
		Else	
			vFilesList = New ValueList();
			// Clear OUT directory
			vPath = cmGetFullFileName("OUT", ExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
			// Zip all output files
			vZP = New ZipFileWriter(vPath + "\" + pmGetForeignersZIPFileName());
			// Do for each record in the list 
			For Each vRow In pExportTable Do
				vErrorRow = pErrors.Find(vRow.RegistryRecord, "Document");
				If vErrorRow = Undefined Then
					vFullFileName = "";
					
					WriteCase(vRow, , , vFullFileName);
					
					If Not IsBlankString(vFullFileName) Then
						If vFilesList.FindByValue(vFullFileName) = Undefined Then
							vFilesList.Add(vFullFileName);
							
							vZP.Add(vFullFileName, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.DontProcess);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vZP.Write();
			// Clear OUT directory from xml files
			DeleteFiles(vPath, "*.xml");
			// Clear IN directory
			vPath = cmGetFullFileName("IN", ExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
		EndIf;
	Else
		pAddressStorageForeigners = "<empty>";
	EndIf;
EndProcedure // WriteToForeignersFiles

// -----------------------------------------------------------------------------
Procedure WriteToForeignersVegaFiles(pExportTable, pErrors, pThinClient = False, pAddressStorageForeigners) 
	If pExportTable <> Undefined And pExportTable.Count() > 0 Then
		If pThinClient Then
			vFilesList = New ValueList();
			// Temp dir at server to create files and archive
			vExportDirForeigners = TempFilesDir();
			vPath = cmGetFullFileName("OUT", vExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
			DeleteFiles(vPath + "\images", "*.png");
			vData = CurrentSessionDate(); 
			// Zip all output files
			vZPFileName = vPath + "\" + pmGetForeignersZIPFileName(Format(vData, "DF=yyyyMMddHHmmss"));
			vZP = New ZipFileWriter(vZPFileName);
			vNumber = 0;
			// Do for each record in the list 
			For Each vRow In pExportTable Do
				vErrorRow = pErrors.Find(vRow.RegistryRecord, "Document");
				If vErrorRow = Undefined Then
					vFullFilePath = "";
					vScanArr = New Array();
					WriteForeignersVegaCase(vRow, vFullFilePath, vScanArr, vExportDirForeigners, "OUT\FrOrg" + Format(vData, "DF=yyyyMMddHHmmss") + ?(vNumber = 0 , "", "_" + Format(vNumber, "NG=0")));
					
					If Not IsBlankString(vFullFilePath) Then
						If vFilesList.FindByValue(vFullFilePath) = Undefined Then
							vFilesList.Add(vFullFilePath);
							
							vZP.Add(vFullFilePath, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.DontProcess);
							vNumber = vNumber + 1;
							For Each vScan In vScanArr Do
								vZP.Add(vScan, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.ProcessRecursively);	
							EndDo;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vZP.Write();
			// Clear OUT directory from xml files
			DeleteFiles(vPath, "*.xml");
			// Clear IN directory
			vPath = cmGetFullFileName("IN", vExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
			pAddressStorageForeigners = PutToTempStorage(New BinaryData(vZPFileName), New UUID());
		Else	
			vFilesList = New ValueList();
			// Clear OUT directory
			vPath = cmGetFullFileName("OUT", ExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
			vData = CurrentSessionDate();
			// Zip all output files
			vZP = New ZipFileWriter(vPath + "\" + pmGetForeignersZIPFileName(Format(vData, "DF=yyyyMMddHHmmss")));
			vNumber = 0;
			// Do for each record in the list 
			For Each vRow In pExportTable Do
				vErrorRow = pErrors.Find(vRow.RegistryRecord, "Document");
				If vErrorRow = Undefined Then
					vFullFilePath = "";
					vScanArr = New Array();
					WriteForeignersVegaCase(vRow, vFullFilePath, vScanArr, , "OUT\FrOrg" + Format(vData, "DF=yyyyMMddHHmmss") + ?(vNumber = 0 , "", "_" + Format(vNumber, "NG=0")));
					
					If Not IsBlankString(vFullFilePath) Then
						If vFilesList.FindByValue(vFullFilePath) = Undefined Then
							vFilesList.Add(vFullFilePath);
							
							vZP.Add(vFullFilePath, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.DontProcess);
							vNumber = vNumber + 1;
							For Each vScan In vScanArr Do
								vZP.Add(vScan, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.DontProcess);	
							EndDo;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vZP.Write();
			// Clear OUT directory from xml files
			DeleteFiles(vPath, "*.xml");
			// Clear IN directory
			vPath = cmGetFullFileName("IN", ExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
		EndIf;
	Else
		pAddressStorageForeigners = "<empty>";
	EndIf;	
EndProcedure // WriteToForeignersFiles

// -----------------------------------------------------------------------------
Function GetPersonName(pGuest)
	vPersonName = TrimAll(pGuest.Description);
	vPersonName = StrReplace(vPersonName, ". ", "_");
	vPersonName = StrReplace(vPersonName, " ", "_");
	vPersonName = StrReplace(vPersonName, ".", "_");
	Return cmTransliterate(vPersonName);
EndFunction // GetPersonName

// -----------------------------------------------------------------------------
Procedure WriteForm5Case(vRow, pXMLWriter = Undefined, Val pNSURI = "", rFullFileName, pTempDir = Undefined)
	pNSURI = "http://umms.fms.gov.ru/replication/hotel/form5";
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		pNSURI = "http://portal.federalhotelservice.ru/elpost/integration/hms/common/imp/core";
		vNSURIForm5 = "http://portal.federalhotelservice.ru/elpost/integration/hms/common/imp/registration";
	EndIf;
	
	vAccDoc = vRow.Accommodation;
	vGuest = vRow.Guest;
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vGuestCode = Right(TrimAll(vGuest.Code), 2);
		vDocNumber = Right(TrimAll(vAccDoc.Number), 7);
		vUID = vDocNumber + vGuestCode;
	Else
		vUID = String(vAccDoc.UUID());
	EndIf;
	vPersonUID = String(vGuest.UUID());
	vPersonName = GetPersonName(vGuest);

	vLimits = GetLimitsAndConditions(vGuest);
	vFanID		= "";
	vFanNumber	= "";
	For Each vLimitRow In vLimits Do
		If vLimitRow.Characteristic.XMLElementName = "fan_id_number" Then
			vFanNumber = vLimitRow.CharacteristicValue;
		EndIf;
		If vLimitRow.Characteristic.XMLElementName = "fan_id" Then
			vFanID = vLimitRow.CharacteristicValue;
		EndIf;
	EndDo;

	vGuestCode = "";
	vDocNumber = "";
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vGuestCode = Right(TrimAll(vGuest.Code), 2);
		vDocNumber = Right(TrimAll(vAccDoc.Number), 7);
		rFullFileName = cmGetFullFileName(pmGetForm5FileName(vDocNumber + vGuestCode), ?(pTempDir = Undefined, ExportDirRussian, pTempDir));
	Else
		vGuestCode = cmGetValidFileName(StrReplace(TrimAll(vGuest.Code), " ", "_"));
		vDocNumber = cmGetValidFileName(StrReplace(TrimAll(vAccDoc.Number), " ", "_"));
		rFullFileName = cmGetFullFileName(pmGetForm5FileName(vPersonName + "_" + vGuestCode + "_" + vDocNumber), ?(pTempDir = Undefined, ExportDirRussian, pTempDir));
	EndIf;
	
	// Build XML
	If pXMLWriter = Undefined Then
		vXMLWriter = New XMLWriter();
		vXMLWriter.OpenFile(rFullFileName, "UTF-8");
		vXMLWriter.WriteXMLDeclaration();
	Else
		vXMLWriter = pXMLWriter;
	EndIf;
	
	// Case
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("case", vNSURIForm5);
	Else
		vXMLWriter.WriteStartElement("form5", pNSURI);
	EndIf;
	
	// Name space uri
	If pXMLWriter = Undefined Then
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteNamespaceMapping("", pNSURI);
			vXMLWriter.WriteNamespaceMapping("registration", vNSURIForm5);
		Else
			vXMLWriter.WriteNamespaceMapping("", vNSURICore);
			vXMLWriter.WriteNamespaceMapping("ns1", vNSURIForm5);
		EndIf;
		
		// SchemaVersion
		vXMLWriter.WriteStartAttribute("schemaVersion");
		vXMLWriter.WriteText("1.0");
		vXMLWriter.WriteEndAttribute();	
		
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteNamespaceMapping("ds", "http://www.w3.org/2000/09/xmldsig#");
			vXMLWriter.WriteNamespaceMapping("ns3", vNSURIMigration);
			vXMLWriter.WriteNamespaceMapping("ns4", vNSURIPayment);
			vXMLWriter.WriteNamespaceMapping("ns5", vNSURIHotel);
			vXMLWriter.WriteNamespaceMapping("ns6", vNSURIUnreg);
			vXMLWriter.WriteNamespaceMapping("ns7", vNSURIStaying);
			vXMLWriter.WriteNamespaceMapping("ns8", vNSURIInvitationApp);
			vXMLWriter.WriteNamespaceMapping("ns2", vNSURIFCCore);
		EndIf;
	EndIf;
		
	// Uid
	vXMLWriter.WriteStartElement("uid");
	vXMLWriter.WriteText(vUID);
	vXMLWriter.WriteEndElement();
	
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
		// Supplier info
		vXMLWriter.WriteStartElement("supplierInfo");
		vXMLWriter.WriteText(TrimAll(SupplierInfo));
		vXMLWriter.WriteEndElement();
		
		// Subdivision
		vXMLWriter.WriteStartElement("subdivision");
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteText("officialOrgan");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText(TrimAll(OfficialOrganID));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement();
		
		// Employee
		vXMLWriter.WriteStartElement("employee");
		If Not IsBlankString(UmmsLoginId) Then
			vXMLWriter.WriteStartElement("ummsId");
			vXMLWriter.WriteText(TrimAll(UmmsLoginId));
			vXMLWriter.WriteEndElement();
		Else
			vXMLWriter.WriteStartElement("name");
			vXMLWriter.WriteText(TrimAll(Employee));
			vXMLWriter.WriteEndElement();
		EndIf;
		vXMLWriter.WriteEndElement();
		
		// Date
		vXMLWriter.WriteStartElement("date");
		vXMLWriter.WriteText(Format(vRow.DocDate, "DF=yyyy-MM-ddTHH:mm:ss"));
		vXMLWriter.WriteEndElement();
		
		// Number
		If Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
			vXMLWriter.WriteStartElement("number");
			vXMLWriter.WriteText(TrimAll(vRow.DocNumber));
			vXMLWriter.WriteEndElement();
		EndIf;
		
		If Not DoNotUploadScansOfRussianPassports Then
			// DocumentPhoto Identity document scans
			vScans = GetIdentityDocScan(vAccDoc);
			For Each vScan In vScans Do
				vError = "";
				vBinaryData = Undefined;
				vBase64String = Undefined;
				Try
					vScanData = vScan.ScanPicture.Get();
					If TypeOf(vScanData) = Type("String") Then
						vBinaryData = New BinaryData(GetImageCatalogName(vScan.Ref) + TrimAll(vScanData));
					ElsIf TypeOf(vScanData) = Type("Picture") Then
						vBinaryData = vScanData.GetBinaryData();
					EndIf;
					If vBinaryData <> Undefined Then
						If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
							vBase64String = HexString(vBinaryData);
						Else
							vBase64String = Base64String(vBinaryData);
						EndIf;
					EndIf;
				Except
					vError = ErrorDescription();
					WriteLogEvent(NStr("en='DataProcessor.ExportGuestsToUFMSTerritoryApp'; de='DataProcessor.ExportGuestsToUFMSTerritoryApp'; ru='Обработка.ЭкспортДанныхГостейВУФМС'"), EventLogLevel.Warning, Metadata.DataProcessors.ExportGuestsToUFMSTerritoryApp, vAccDoc, "Failed to get identity document scan from value storage!");
				EndTry;
				If Not ValueIsFilled(vError) And vBase64String <> Undefined Then
					If ValueIsFilled(vScan.ScanConfiguration) Then
						vScanConfiguration = vScan.ScanConfiguration;
						
						vXMLWriter.WriteStartElement("documentPhoto");
						
							vXMLWriter.WriteStartElement("documentUid");
							vXMLWriter.WriteText(String(vScanConfiguration.UUID()));
							vXMLWriter.WriteEndElement(); // DocumentUid
							
							vXMLWriter.WriteStartElement("type");
								vXMLWriter.WriteStartElement("type");
								vXMLWriter.WriteText("DocumentType");
								vXMLWriter.WriteEndElement(); // Type
								vXMLWriter.WriteStartElement("element");
								If vScanConfiguration.IsVisa Then
									vXMLWriter.WriteText("139356");
								ElsIf vScanConfiguration.IsMigrationCard Then
									vXMLWriter.WriteText("103022");
								ElsIf vScanConfiguration.IsFanId Then
									vXMLWriter.WriteText("fan_id");
								ElsIf ValueIsFilled(vScanConfiguration.IdentityDocumentType) Then
									vXMLWriter.WriteText(TrimAll(vScanConfiguration.IdentityDocumentType.ExternalCode));
								EndIf;
								vXMLWriter.WriteEndElement(); // Element
							vXMLWriter.WriteEndElement(); // Type
							
							vXMLWriter.WriteStartElement("content");
							vXMLWriter.WriteText(vBase64String);
							vXMLWriter.WriteEndElement(); // Content
							
							vXMLWriter.WriteStartElement("mimeType");
							vXMLWriter.WriteText("image/jpeg");  
							vXMLWriter.WriteEndElement(); // MimeType

						vXMLWriter.WriteEndElement(); // DocumentPhoto
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;

	// PersonDataDocument
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("personDataDocument", vNSURIForm5);
	ElsIf Receiver = Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
		vXMLWriter.WriteStartElement("declarant", pNSURI);	
	Else
		vXMLWriter.WriteStartElement("personDataDocument", pNSURI);
	EndIf;
	vXMLWriter.WriteStartElement("person");
	
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("uid");
		vXMLWriter.WriteText(vPersonUID);
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("personId");
		vXMLWriter.WriteText(vPersonUID);
		vXMLWriter.WriteEndElement();
	EndIf;
	
	// Names	
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("lastNameRus");
		vXMLWriter.WriteText(TrimAll(vRow.LastName));
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("firstNameRus");
		vXMLWriter.WriteText(TrimAll(vRow.FirstName));
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("middleNameRus");
		vXMLWriter.WriteText(TrimAll(vRow.SecondName));
		vXMLWriter.WriteEndElement();
	Else
		vXMLWriter.WriteStartElement("lastName");
		vXMLWriter.WriteText(TrimAll(vRow.LastName));
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("firstName");
		vXMLWriter.WriteText(TrimAll(vRow.FirstName));
		vXMLWriter.WriteEndElement();
		
		vXMLWriter.WriteStartElement("middleName");
		vXMLWriter.WriteText(TrimAll(vRow.SecondName));
		vXMLWriter.WriteEndElement();
	EndIf;
	
	// Gender
	vXMLWriter.WriteStartElement("gender");
	vXMLWriter.WriteStartElement("type");
	vXMLWriter.WriteText("Gender");
	vXMLWriter.WriteEndElement();
	If ValueIsFilled(vRow.Sex) Then
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			If vRow.Sex = Enums.Sex.Male Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("M");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("M");
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("F");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("F");
				vXMLWriter.WriteEndElement();
			EndIf;
		Else
			If vRow.Sex = Enums.Sex.Male Then
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText("M");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("Мужской");
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText("F");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText("Женский");
				vXMLWriter.WriteEndElement();
			EndIf;
		EndIf;
	EndIf;
	vXMLWriter.WriteEndElement(); // Gender
	
	// Birth date
	vXMLWriter.WriteStartElement("birthDate");
	vXMLWriter.WriteText(Format(vRow.DateOfBirth, "DF=dd.MM.yyyy"));
	vXMLWriter.WriteEndElement();
	
	// Citizenship
	vXMLWriter.WriteStartElement("citizenship");
	vXMLWriter.WriteStartElement("type");
	vXMLWriter.WriteText("Citizenship");
	vXMLWriter.WriteEndElement();
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("id");
		vXMLWriter.WriteText(Upper(vRow.CitizenshipISOCode3));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(vRow.Citizenship);
		vXMLWriter.WriteEndElement();
	Else
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText(Upper(vRow.CitizenshipISOCode3));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(vRow.Citizenship);
		vXMLWriter.WriteEndElement();
	EndIf;
	vXMLWriter.WriteEndElement(); // Citizenship
	
	// Birth place
	vXMLWriter.WriteStartElement("birthPlace");
	vXMLWriter.WriteStartElement("country");
	vXMLWriter.WriteStartElement("type");
	vXMLWriter.WriteText("Country");
	vXMLWriter.WriteEndElement();
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("id");
		vXMLWriter.WriteText(Upper(vRow.PlaceOfBirthCountryISOCode3));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(vRow.PlaceOfBirthCountry);
		vXMLWriter.WriteEndElement();
	Else
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText(Upper(vRow.PlaceOfBirthCountryISOCode3));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(vRow.PlaceOfBirthCountry);
		vXMLWriter.WriteEndElement();
	EndIf;
	vXMLWriter.WriteEndElement(); // Country
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("place");
		vXMLWriter.WriteText(?(IsBlankString(vRow.PlaceOfBirthCity), vRow.PlaceOfBirthRegion, vRow.PlaceOfBirthCity));
		vXMLWriter.WriteEndElement();
	Else
		vXMLWriter.WriteStartElement("place");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("place2");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("place3");
		vXMLWriter.WriteText(?(IsBlankString(vRow.PlaceOfBirthCity), vRow.PlaceOfBirthRegion, vRow.PlaceOfBirthCity));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("place4");
		vXMLWriter.WriteEndElement();
	EndIf;
	vXMLWriter.WriteEndElement(); // BirthPlace
	
	vXMLWriter.WriteEndElement(); // Person
	
	// Identity document
	vXMLWriter.WriteStartElement("document");
	If ValueIsFilled(vRow.IdentityDocumentType) Then
		If Not IsBlankString(vRow.IdentityDocumentTypeExternalCode) Then
			// Uid
			If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost And 
			   Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
				vXMLWriter.WriteStartElement("uid");
				vXMLWriter.WriteText(String(vRow.IdentityDocumentType.UUID()));
				vXMLWriter.WriteEndElement();
			EndIf;
			// Type
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteStartElement("type");
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteText("reg.personIdentDocTypes");
			Else
				vXMLWriter.WriteText("DocumentType");
			EndIf;
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentTypeExternalCode));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentTypeExternalCode));
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentTypeExternalCode));
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentType));
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement(); // Type
			// Series
			If Not IsBlankString(vRow.IdentityDocumentSeries) Then
				vXMLWriter.WriteStartElement("series");
				vXMLWriter.WriteText(vRow.IdentityDocumentSeries);
				vXMLWriter.WriteEndElement();
			EndIf;
			// Number
			vXMLWriter.WriteStartElement("number");
			vXMLWriter.WriteText(vRow.IdentityDocumentNumber);
			vXMLWriter.WriteEndElement();
			// issued
			If ValueIsFilled(vRow.IdentityDocumentIssueDate) Then
				vXMLWriter.WriteStartElement("issued");
				vXMLWriter.WriteText(Format(vRow.IdentityDocumentIssueDate, "DF=yyyy-MM-dd"));
				vXMLWriter.WriteEndElement();
			EndIf;
			// ValidTo
			If ValueIsFilled(vRow.IdentityDocumentValidToDate) Then
				vXMLWriter.WriteStartElement("validTo");
				vXMLWriter.WriteText(Format(vRow.IdentityDocumentValidToDate, "DF=yyyy-MM-dd"));
				vXMLWriter.WriteEndElement();
			EndIf;
			// Authority
			If Not IsBlankString(vRow.IdentityDocumentIssuedBy) Then
				If TrimAll(vRow.IdentityDocumentType.Code) = "21" Then
					vGuestOfficialOrgan = TrimAll(vRow.IdentityDocumentIssuedBy);
					vGuestOfficialOrganID = GetOfficialOrganID(TrimAll(vRow.IdentityDocumentUnitCode), TrimAll(vRow.IdentityDocumentIssuedBy));
					If Not IsBlankString(vGuestOfficialOrganID) Then
						vXMLWriter.WriteStartElement("authorityOrgan");
						vXMLWriter.WriteStartElement("type");
						If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
							vXMLWriter.WriteText("officialOrgan.fms");
						Else
							vXMLWriter.WriteText("officialOrgan");
						EndIf;
						vXMLWriter.WriteEndElement(); // Type
						If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
							vXMLWriter.WriteStartElement("id");
							vXMLWriter.WriteText(vGuestOfficialOrganID);
							vXMLWriter.WriteEndElement(); // Element
							vXMLWriter.WriteStartElement("value");
							vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentUnitCode));
							vXMLWriter.WriteEndElement(); // Value
						Else
							vXMLWriter.WriteStartElement("element");
							vXMLWriter.WriteText(vGuestOfficialOrganID);
							vXMLWriter.WriteEndElement(); // Element
							vXMLWriter.WriteStartElement("value");
							vXMLWriter.WriteText(vGuestOfficialOrgan);
							vXMLWriter.WriteEndElement(); // Value
						EndIf;
						vXMLWriter.WriteEndElement(); // AuthorityOrgan
					Else
						vXMLWriter.WriteStartElement("authority");
						vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentIssuedBy));
						vXMLWriter.WriteEndElement(); // Authority
					EndIf;
				Else
					vXMLWriter.WriteStartElement("authority");
					vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentIssuedBy));
					vXMLWriter.WriteEndElement(); // Authority
				EndIf;
			EndIf;
			// Status
			If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("status");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("DocumentStatus");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText("102877");
				vXMLWriter.WriteEndElement();
				vXMLWriter.WriteEndElement();
			EndIf;
		EndIf;
	EndIf;
	vXMLWriter.WriteEndElement(); // Document
	
	// Entered
	vXMLWriter.WriteStartElement("entered");
	vXMLWriter.WriteText("false");
	vXMLWriter.WriteEndElement();
	
	vXMLWriter.WriteEndElement(); // PersonDataDocument
	
	// Legal representative
	If Hotel.LegalRepresentativeForChildren And Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
		If (Year(CurrentDate()) - Year(vRow.DateOfBirth)) < 18 Then
			vLegalRep = vRow.LegalRepresentative;
			If ValueIsFilled(vLegalRep) Then
				If IsBlankString(vLegalRep.LastName) Then
					vLegalRepLastName = "[отсутствует]";
				Else
					vLegalRepLastName = vLegalRep.LastName;
				EndIf;
				If IsBlankString(vLegalRep.FirstName) Then
					vLegalRepFirstName = "[отсутствует]";
				Else
					vLegalRepFirstName = TrimAll(vLegalRep.FirstName);
				EndIf;
				If IsBlankString(vLegalRep.SecondName) Then
					vLegalRepSecondName = "[отсутствует]";
				Else
					vLegalRepSecondName = TrimAll(vLegalRep.SecondName);
				EndIf;
				
				vXMLWriter.WriteStartElement("representative", pNSURI);
				
				// PersonDataDocument
				If Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
					vXMLWriter.WriteStartElement("personDataDocument");
				EndIf;
				vXMLWriter.WriteStartElement("person");
				
				If Receiver = Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
					vRepUID = String(vLegalRep.UUID());
					
					vXMLWriter.WriteStartElement("uid");
					vXMLWriter.WriteText(vRepUID);
					vXMLWriter.WriteEndElement();
					
					vXMLWriter.WriteStartElement("personId");
					vXMLWriter.WriteText(vRepUID);
					vXMLWriter.WriteEndElement();
				EndIf;
				
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("lastNameRus");
					vXMLWriter.WriteText(vLegalRepLastName);
					vXMLWriter.WriteEndElement();
					
					vXMLWriter.WriteStartElement("firstNameRus");
					vXMLWriter.WriteText(vLegalRepFirstName);
					vXMLWriter.WriteEndElement();
					
					vXMLWriter.WriteStartElement("middleNameRus");
					vXMLWriter.WriteText(vLegalRepSecondName);
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("lastName");
					vXMLWriter.WriteText(vLegalRepLastName);
					vXMLWriter.WriteEndElement();
					
					vXMLWriter.WriteStartElement("firstName");
					vXMLWriter.WriteText(vLegalRepFirstName);
					vXMLWriter.WriteEndElement();
					
					vXMLWriter.WriteStartElement("middleName");
					vXMLWriter.WriteText(vLegalRepSecondName);
					vXMLWriter.WriteEndElement();
				EndIf;
				
				// Gender
				vXMLWriter.WriteStartElement("gender");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("Gender");
				vXMLWriter.WriteEndElement();
				If ValueIsFilled(vLegalRep.Sex) Then
					If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
						If vLegalRep.Sex = Enums.Sex.Male Then
							vXMLWriter.WriteStartElement("id");
							vXMLWriter.WriteText("M");
							vXMLWriter.WriteEndElement();
						Else
							vXMLWriter.WriteStartElement("id");
							vXMLWriter.WriteText("F");
							vXMLWriter.WriteEndElement();
						EndIf;
					Else
						If vLegalRep.Sex = Enums.Sex.Male Then
							vXMLWriter.WriteStartElement("element");
							vXMLWriter.WriteText("M");
							vXMLWriter.WriteEndElement();
						Else
							vXMLWriter.WriteStartElement("element");
							vXMLWriter.WriteText("F");
							vXMLWriter.WriteEndElement();
						EndIf;
					EndIf;
				EndIf;
				vXMLWriter.WriteEndElement(); // Gender
				
				// Birth date
				vXMLWriter.WriteStartElement("birthDate");
				vXMLWriter.WriteText(Format(vLegalRep.DateOfBirth, "DF=dd.MM.yyyy"));
				vXMLWriter.WriteEndElement();
				
				// Citizenship
				vXMLWriter.WriteStartElement("citizenship");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("Citizenship");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText(Upper(vLegalRep.Citizenship.ISOCode3));
					vXMLWriter.WriteEndElement();
					vXMLWriter.WriteStartElement("value");
					vXMLWriter.WriteText(TrimAll(vLegalRep.Citizenship));
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText(Upper(vLegalRep.Citizenship.ISOCode3));
					vXMLWriter.WriteEndElement();
					vXMLWriter.WriteStartElement("value");
					vXMLWriter.WriteText(TrimAll(vLegalRep.Citizenship));
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteEndElement(); // Citizenship
				
				// Birth place
				vLegalRepPlaceOfBirthCountry = "";
				vLegalRepPlaceOfBirthCountryISOCode3 = "";
				vLegalRepPlaceOfBirth = "";
				If TrimAll(vLegalRep.PlaceOfBirth) <> "" Then
					vLegalRepPlaceOfBirth = TrimAll(vLegalRep.PlaceOfBirth);
				EndIf;
				If Not IsBlankString(vLegalRepPlaceOfBirth) Then
					vLegalRepAddressItems = cmParseAddress(vLegalRepPlaceOfBirth);
					If ValueIsFilled(vLegalRepAddressItems.Country) Then
						vLegalRepPlaceOfBirthCountry = TrimAll(vLegalRepAddressItems.Country.Description);
						vLegalRepPlaceOfBirthCountryISOCode3 = TrimAll(vLegalRepAddressItems.Country.ISOCode3);
					EndIf;
				EndIf;
				
				vXMLWriter.WriteStartElement("birthPlace");
				vXMLWriter.WriteStartElement("country");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("Country");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText(Upper(vLegalRepPlaceOfBirthCountryISOCode3));
					vXMLWriter.WriteEndElement();
					vXMLWriter.WriteStartElement("value");
					vXMLWriter.WriteText(vLegalRepPlaceOfBirthCountry);
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText(Upper(vLegalRepPlaceOfBirthCountryISOCode3));
					vXMLWriter.WriteEndElement();
					vXMLWriter.WriteStartElement("value");
					vXMLWriter.WriteText(vLegalRepPlaceOfBirthCountry);
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteEndElement(); // Country
				vXMLWriter.WriteEndElement(); // BirthPlace
				
				vXMLWriter.WriteEndElement(); // Person
				
				// Identity document
				vXMLWriter.WriteStartElement("document");
				If ValueIsFilled(vLegalRep.IdentityDocumentType) Then
					vLegalRepIdentityDocumentType = vLegalRep.IdentityDocumentType;
					If Not IsBlankString(vLegalRepIdentityDocumentType.ExternalCode) Then
						// Type
						vXMLWriter.WriteStartElement("type");
						vXMLWriter.WriteStartElement("type");
						If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
							vXMLWriter.WriteText("reg.personIdentDocTypes");
						Else
							vXMLWriter.WriteText("DocumentType");
						EndIf;
						vXMLWriter.WriteEndElement();
						If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
							vXMLWriter.WriteStartElement("id");
							vXMLWriter.WriteText(TrimAll(vLegalRepIdentityDocumentType.ExternalCode));
							vXMLWriter.WriteEndElement();
						Else
							vXMLWriter.WriteStartElement("element");
							vXMLWriter.WriteText(TrimAll(vLegalRepIdentityDocumentType.ExternalCode));
							vXMLWriter.WriteEndElement();
						EndIf;
						vXMLWriter.WriteEndElement(); // Type
						// Series
						If Not IsBlankString(vLegalRep.IdentityDocumentSeries) Then
							vXMLWriter.WriteStartElement("series");
							vXMLWriter.WriteText(vLegalRep.IdentityDocumentSeries);
							vXMLWriter.WriteEndElement();
						EndIf;
						// Number
						vXMLWriter.WriteStartElement("number");
						vXMLWriter.WriteText(vLegalRep.IdentityDocumentNumber);
						vXMLWriter.WriteEndElement();
						vGuestOfficialOrgan = TrimAll(vLegalRep.IdentityDocumentIssuedBy);
						vGuestOfficialOrganID = GetOfficialOrganID(TrimAll(vLegalRep.IdentityDocumentUnitCode), TrimAll(vLegalRep.IdentityDocumentIssuedBy));
						If Not IsBlankString(vGuestOfficialOrganID) Then
							vXMLWriter.WriteStartElement("authorityOrgan");
							vXMLWriter.WriteStartElement("type");
							If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
								vXMLWriter.WriteText("officialOrgan.fms");
							Else
								vXMLWriter.WriteText("officialOrgan");
							EndIf;
							vXMLWriter.WriteEndElement(); // Type
							If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
								vXMLWriter.WriteStartElement("id");
								vXMLWriter.WriteText(vGuestOfficialOrganID);
								vXMLWriter.WriteEndElement(); // Id
								vXMLWriter.WriteStartElement("value");
								vXMLWriter.WriteText(TrimAll(vLegalRep.IdentityDocumentUnitCode));
								vXMLWriter.WriteEndElement(); // Value
							Else
								vXMLWriter.WriteStartElement("element");
								vXMLWriter.WriteText(vGuestOfficialOrganID);
								vXMLWriter.WriteEndElement(); // Element
							EndIf;
							vXMLWriter.WriteEndElement(); // AuthorityOrgan
						EndIf;
						// Authority
						If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
							If Not IsBlankString(vLegalRep.IdentityDocumentIssuedBy) Then
								vXMLWriter.WriteStartElement("authority");
								vXMLWriter.WriteText(vLegalRep.IdentityDocumentIssuedBy);
								vXMLWriter.WriteEndElement();
							EndIf;
						EndIf;
						// Issued
						If ValueIsFilled(vLegalRep.IdentityDocumentIssueDate) Then
							vXMLWriter.WriteStartElement("issued");
							vXMLWriter.WriteText(Format(vLegalRep.IdentityDocumentIssueDate, "DF=yyyy-MM-dd"));
							vXMLWriter.WriteEndElement();
						EndIf;
						// Issued
						If ValueIsFilled(vLegalRep.IdentityDocumentIssueDate) Then
							vXMLWriter.WriteStartElement("validFrom");
							vXMLWriter.WriteText(Format(vLegalRep.IdentityDocumentIssueDate, "DF=yyyy-MM-dd"));
							vXMLWriter.WriteEndElement();
						EndIf;
						// ValidTo
						If ValueIsFilled(vLegalRep.IdentityDocumentValidToDate) Then
							vXMLWriter.WriteStartElement("validTo");
							vXMLWriter.WriteText(Format(vLegalRep.IdentityDocumentValidToDate, "DF=yyyy-MM-dd"));
							vXMLWriter.WriteEndElement();
						EndIf;
					EndIf;
				EndIf;
				vXMLWriter.WriteEndElement(); // Document
				If Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
					vXMLWriter.WriteEndElement(); // PersonDataDocument
				EndIf;
				
				// Relation type
				If ValueIsFilled(vRow.RelationType) Then
					vXMLWriter.WriteStartElement("type", pNSURI);
					vXMLWriter.WriteStartElement("type");
					vXMLWriter.WriteText(TrimAll(vRow.RelationType));
					vXMLWriter.WriteEndElement();
					If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
						vXMLWriter.WriteStartElement("id");
						vXMLWriter.WriteText(TrimAll(vRow.RelationType.ID));
						vXMLWriter.WriteEndElement();
					Else
						vXMLWriter.WriteStartElement("element");
						vXMLWriter.WriteText(TrimAll(vRow.RelationType.ID));
						vXMLWriter.WriteEndElement();
					EndIf;
					vXMLWriter.WriteEndElement(); // Type
				EndIf;
				vXMLWriter.WriteEndElement(); // Representative
			EndIf;
		EndIf;
	EndIf;
	
	// LivingAddress
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost Then
		If Not IsBlankString(vRow.Address) And Not vGuest.IsHomeless Then
			vLivingAddress = TrimAll(vRow.Address);
			vLivingAddressStruct = cmParseAddress(vLivingAddress);
			vLivingAddressFullHouse = TrimAll(vLivingAddressStruct.House);
			vLivingAddressHouse = pmGetHouse(vLivingAddressFullHouse);
			vLivingAddressBuilding1 = pmGetBuilding1(vLivingAddressFullHouse);
			vLivingAddressBuilding2 = pmGetBuilding2(vLivingAddressFullHouse);
			vLivingAddressFlat = TrimAll(vLivingAddressStruct.Flat);
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("livingAddress", vNSURIForm5);
			Else
				vXMLWriter.WriteStartElement("livingAddress", pNSURI);
			EndIf;
			vXMLWriter.WriteStartElement("dateFrom");
			vXMLWriter.WriteText(Format(vGuest.AddressRegistrationDate, "DF=yyyy-MM-dd"));
			vXMLWriter.WriteEndElement();   
			If Receiver = Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
				If ValueIsFilled(vGuest.AddressRegistrationDateTo) Then
					vXMLWriter.WriteStartElement("dateTo");
					vXMLWriter.WriteText(Format(vGuest.AddressRegistrationDateTo, "DF=yyyy-MM-dd"));
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteStartElement("address");	
			EndIf;
			vXMLWriter.WriteStartElement("russianAddress");
			vXMLWriter.WriteStartElement("addressObjectString");
			vXMLWriter.WriteText(FormatAddressString(vLivingAddress));
			vXMLWriter.WriteEndElement(); // AddressObjectString
			// Housing
			If Not IsBlankString(vLivingAddressHouse) Then
				vXMLWriter.WriteStartElement("housing");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("addressObjectType");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText("1202");
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText("1202");
					vXMLWriter.WriteEndElement();
				Endif;
				vXMLWriter.WriteEndElement(); // Type
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(vLivingAddressHouse);
				vXMLWriter.WriteEndElement(); 
				vXMLWriter.WriteEndElement(); // Housing
			EndIf;
			If Not IsBlankString(vLivingAddressBuilding1) Then
				vXMLWriter.WriteStartElement("housing");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("addressObjectType");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText("1203");
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText("1203");
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteEndElement(); // Type
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(vLivingAddressBuilding1);
				vXMLWriter.WriteEndElement(); 
				vXMLWriter.WriteEndElement(); // Housing
			EndIf;
			If Not IsBlankString(vLivingAddressBuilding2) Then
				vXMLWriter.WriteStartElement("housing");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("addressObjectType");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText("1204");
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText("1204");
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteEndElement(); // Type
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(vLivingAddressBuilding2);
				vXMLWriter.WriteEndElement(); 
				vXMLWriter.WriteEndElement(); // Housing
			EndIf;
			If Not IsBlankString(vLivingAddressFlat) Then
				vXMLWriter.WriteStartElement("housing");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteStartElement("type");
				vXMLWriter.WriteText("addressObjectType");
				vXMLWriter.WriteEndElement();
				If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
					vXMLWriter.WriteStartElement("id");
					vXMLWriter.WriteText("1303");
					vXMLWriter.WriteEndElement();
				Else
					vXMLWriter.WriteStartElement("element");
					vXMLWriter.WriteText("1303");
					vXMLWriter.WriteEndElement();
				EndIf;
				vXMLWriter.WriteEndElement(); // Type
				vXMLWriter.WriteStartElement("value");
				vXMLWriter.WriteText(vLivingAddressFlat);
				vXMLWriter.WriteEndElement(); 
				vXMLWriter.WriteEndElement(); // Housing
			EndIf;
			vXMLWriter.WriteEndElement(); // RussianAddress
			If Receiver = Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
				vXMLWriter.WriteEndElement(); // Address	
			EndIf;
			vXMLWriter.WriteEndElement(); // LivingAddress 
		ElsIf vGuest.IsHomeless Then
			vXMLWriter.WriteStartElement("homeless", pNSURI);
			vXMLWriter.WriteEndElement();
		EndIf;
	EndIf;
	
	// StayPeriod
	If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vXMLWriter.WriteStartElement("hotelStayPeriod", vNSURIForm5);
	ElsIf Receiver = Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
		vXMLWriter.WriteStartElement("stayingPeriod", pNSURI);	
	Else
		vXMLWriter.WriteStartElement("stayPeriod", pNSURI);
	EndIf;
	vXMLWriter.WriteStartElement("dateFrom");
	vXMLWriter.WriteText(Format(vRow.CheckInDate, "DF=yyyy-MM-dd"));
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteStartElement("dateTo");
	vXMLWriter.WriteText(Format(vRow.ExpectedCheckOutDate, "DF=yyyy-MM-dd"));
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();
	
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
		// RoomNumber
		If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
			vXMLWriter.WriteStartElement("roomNumber", vNSURIForm5);
		Else
			vXMLWriter.WriteStartElement("roomNumber", pNSURI);
		EndIf;
		vXMLWriter.WriteText(vAccDoc.Room.Description);
		vXMLWriter.WriteEndElement();
	Else
		vXMLWriter.WriteStartElement("stayingAddress", pNSURI);
		vXMLWriter.WriteStartElement("housing");
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteStartElement("type");
		vXMLWriter.WriteText("addressObjectType");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("element");
		vXMLWriter.WriteText("1304");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("value");
		vXMLWriter.WriteText(vAccDoc.Room.Description);
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement();
	EndIf;
	
	// Fan_id
	If ValueIsFilled(vFanID) And ValueIsFilled(vFanNumber) Then
		vXMLWriter.WriteStartElement("fan_id");
			vXMLWriter.WriteStartElement("id");
			vXMLWriter.WriteText(String(vFanID));
			vXMLWriter.WriteEndElement();
			vXMLWriter.WriteStartElement("number");
			vXMLWriter.WriteText(String(vFanNumber));
			vXMLWriter.WriteEndElement();
		vXMLWriter.WriteEndElement();
	EndIf;
	
	If Receiver <> Enums.GuestDataExportHeaderTypesRu.Elpost And 
	   Receiver <> Enums.GuestDataExportHeaderTypesRu.KonturFMS Then
		// RegistrationDate
		vXMLWriter.WriteStartElement("registrationDate", pNSURI);
		vXMLWriter.WriteText(Format(vRow.DocDate, "DF=yyyy-MM-dd"));
		vXMLWriter.WriteEndElement(); // RegistrationDate
		
		// HotelInfo
		vXMLWriter.WriteStartElement("hotelInfo", pNSURI);
		vXMLWriter.WriteStartElement("organization", pNSURI);
		vXMLWriter.WriteStartElement("uid");
		vXMLWriter.WriteText("org_1");
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("inn");
		vXMLWriter.WriteText(TrimAll(Company.TIN));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("name");
		vXMLWriter.WriteText(TrimAll(Company.Description));
		vXMLWriter.WriteEndElement();
		vXMLWriter.WriteStartElement("address");
		vXMLWriter.WriteStartElement("address");
		vXMLWriter.WriteStartElement("russianAddress");
		vXMLWriter.WriteStartElement("addressObjectString");
		vXMLWriter.WriteText(FormatAddressString(TrimAll(CompanyAddress)));
		vXMLWriter.WriteEndElement(); // AddressObjectString
		// Housing
		If Not IsBlankString(CompanyAddressHouse) Then
			vXMLWriter.WriteStartElement("housing");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("addressObjectType");
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("1202");
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText("1202");
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement(); // Type
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText(TrimAll(CompanyAddressHouse));
			vXMLWriter.WriteEndElement(); 
			vXMLWriter.WriteEndElement(); // Housing
		EndIf;
		If Not IsBlankString(CompanyAddressBuilding) Then
			vXMLWriter.WriteStartElement("housing");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteStartElement("type");
			vXMLWriter.WriteText("addressObjectType");
			vXMLWriter.WriteEndElement();
			If Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
				vXMLWriter.WriteStartElement("id");
				vXMLWriter.WriteText("1203");
				vXMLWriter.WriteEndElement();
			Else
				vXMLWriter.WriteStartElement("element");
				vXMLWriter.WriteText("1203");
				vXMLWriter.WriteEndElement();
			EndIf;
			vXMLWriter.WriteEndElement(); // Type
			vXMLWriter.WriteStartElement("value");
			vXMLWriter.WriteText(TrimAll(CompanyAddressBuilding));
			vXMLWriter.WriteEndElement(); 
			vXMLWriter.WriteEndElement(); // Housing
		EndIf;
		vXMLWriter.WriteEndElement(); // RussianAddress
		vXMLWriter.WriteEndElement(); // Address
		vXMLWriter.WriteEndElement(); // Address
		vXMLWriter.WriteEndElement(); // Organization
		vXMLWriter.WriteEndElement(); // HotelInfo
	EndIf;
	
	vXMLWriter.WriteEndElement(); // Case
	
	// Close document
	If pXMLWriter = Undefined Then
		vXMLWriter.Close();
	EndIf;
	
	// Write record to the exported guests
	vHotel = ?(ValueIsFilled(Hotel), Hotel, SessionParameters.CurrentHotel);
	If ValueIsFilled(vHotel) Then
		vEGRM = InformationRegisters.GuestsExportedToUMMS.CreateRecordManager();
		vEGRM.Hotel = vHotel;
		vEGRM.Guest = vGuest;
		vEGRM.CheckOutDate = BegOfDay(vRow.ExpectedCheckOutDate);
		vEGRM.CheckInDate = BegOfDay(vRow.CheckInDate);
		vEGRM.CaseUUID = vUID;
		vEGRM.CaseIsRemovedFromRegister = False;
		vEGRM.Write(True);
	EndIf;
EndProcedure // WriteForm5Case

// -----------------------------------------------------------------------------
Procedure WriteVegaCase(vRow, rFullFilePath, pTempDir = Undefined, pFullFileName)
	rFullFilePath = cmGetFullFileName(pFullFileName, ?(pTempDir = Undefined, ExportDirForeigners, pTempDir)) + ".xml";;
	vGuest = vRow.Guest;
	vAccDoc = vRow.Accommodation;
	vUID = String(vAccDoc.UUID());
	
	vXMLWriter = New XMLWriter();
	vXMLWriter.OpenFile(rFullFilePath, "UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	
	#Region registration 
	vXMLWriter.WriteStartElement("registration");
	
	WriteXMLAttribute(vXMLWriter, "dateIn", Format(vRow.CheckInDate, "DF=yyyy-MM-dd"));
	WriteXMLAttribute(vXMLWriter, "dateOut", Format(vRow.ExpectedCheckOutDate, "DF=yyyy-MM-dd"));
	WriteXMLAttribute(vXMLWriter, "room", vAccDoc.Room.Description);
	vXMLWriter.WriteNamespaceMapping("", "http://www.sonarplus.ru/replication/vegaimport");
	
	#Region person
	vXMLWriter.WriteStartElement("person");
	
	WriteXMLAttribute(vXMLWriter, "lastName", TrimAll(vRow.LastName));
	WriteXMLAttribute(vXMLWriter, "firstName", TrimAll(vRow.FirstName));
	If ValueIsFilled(TrimAll(vRow.SecondName)) Then
		WriteXMLAttribute(vXMLWriter, "middleName", TrimAll(vRow.SecondName));
	EndIf;
	
	// birth date
	WriteXMLAttribute(vXMLWriter, "birthDate", Format(vRow.DateOfBirth, "DF=yyyy-MM-dd"));
	
	vXMLWriter.WriteStartElement("gender");
	WriteXMLAttribute(vXMLWriter, "type", "S_SEX");
	WriteXMLAttribute(vXMLWriter, "dictvalue", ?(vRow.Sex = Enums.Sex.Male, "МУЖ.", "ЖЕН."));
	vXMLWriter.WriteEndElement(); // Gender
	
	vXMLWriter.WriteStartElement("citizenship");
	WriteXMLAttribute(vXMLWriter, "type", "S_STATE");
	WriteXMLAttribute(vXMLWriter, "dictvalue", ?(ValueIsFilled(vRow.Citizenship), vRow.Citizenship, "ЛИЦО БЕЗ ГРАЖДАНСТВА"));
	vXMLWriter.WriteEndElement(); // Citizenship
	
	#Region birthPlace
	vXMLWriter.WriteStartElement("birthPlace");
	If ValueIsFilled(vRow.PlaceOfBirthRegion) Then
		WriteXMLAttribute(vXMLWriter, "main_region", vRow.PlaceOfBirthRegion);
	EndIf;
	If ValueIsFilled(vRow.PlaceOfBirthRegion) Then
		WriteXMLAttribute(vXMLWriter, "district", vRow.PlaceOfBirthArea);
	EndIf;
	If ValueIsFilled(vRow.PlaceOfBirthRegion) Then
		WriteXMLAttribute(vXMLWriter, "city", vRow.PlaceOfBirthCity);
	EndIf;
	
	#Region birthPlace
	vXMLWriter.WriteStartElement("country");
	WriteXMLAttribute(vXMLWriter, "type", "S_STATE");
	WriteXMLAttribute(vXMLWriter, "dictvalue", vRow.PlaceOfBirthCountry);
	vXMLWriter.WriteEndElement(); // Country
	#EndRegion
	
	vXMLWriter.WriteEndElement(); // BirthPlace
	#EndRegion
	
	vXMLWriter.WriteEndElement(); // Person
	#EndRegion
	
	#Region documentRelation
	vXMLWriter.WriteStartElement("documentRelation");
	
	#Region document
	vXMLWriter.WriteStartElement("document");
	
	If ValueIsFilled(vRow.IdentityDocumentSeries) Then
		WriteXMLAttribute(vXMLWriter, "series", vRow.IdentityDocumentSeries);
	EndIf;
	WriteXMLAttribute(vXMLWriter, "number", vRow.IdentityDocumentNumber);
	If ValueIsFilled(vRow.IdentityDocumentIssueDate) Then
		WriteXMLAttribute(vXMLWriter, "issued", Format(vRow.IdentityDocumentIssueDate, "DF=yyyy-MM-dd"));
	EndIf;
	If ValueIsFilled(vRow.IdentityDocumentValidToDate) Then
		WriteXMLAttribute(vXMLWriter, "expired", Format(vRow.IdentityDocumentValidToDate, "DF=yyyy-MM-dd"));
	EndIf;
	
	vXMLWriter.WriteStartElement("type");
	
	WriteXMLAttribute(vXMLWriter, "type", "S_DOCUM");
	WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vRow.IdentityDocumentType));
	
	vXMLWriter.WriteEndElement(); // Type
	
	vXMLWriter.WriteStartElement("authority");
	
	vXMLWriter.WriteText(TrimAll(vRow.IdentityDocumentIssuedBy));
	
	vXMLWriter.WriteEndElement(); // AuthorityOrgan
	
	vXMLWriter.WriteEndElement(); // Document
	#EndRegion
	
	vXMLWriter.WriteStartElement("relation");
	
	WriteXMLAttribute(vXMLWriter, "type", "TYPE_SV");
	WriteXMLAttribute(vXMLWriter, "dictvalue", "ВЛАДЕЛЕЦ");
	
	vXMLWriter.WriteEndElement(); // Relation
	
	vXMLWriter.WriteEndElement(); // DocumentRelation
	#EndRegion	
		
	#Region regAddress
	If ValueIsFilled(HotelCode) Then
		vXMLWriter.WriteStartElement("regAddress");
		
		WriteXMLAttribute(vXMLWriter, "type", "ADDR_REG");
		WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(HotelCode));
	
		vXMLWriter.WriteEndElement(); // RegAddress
	EndIf;	
	#EndRegion
	
	#Region liveAddress
	If ValueIsFilled(vRow.Address) Then
		vXMLWriter.WriteStartElement("liveAddress");
		
		vLivingAddress = TrimAll(vRow.Address);
		vLivingAddressStruct = cmParseAddress(vLivingAddress);
		vUUIDStreet = GetUUIDAddressFromDadata(vLivingAddress);
		If ValueIsFilled(vUUIDStreet) Then
			vXMLWriter.WriteStartElement("addressObjectGlobal");
			
			WriteXMLAttribute(vXMLWriter, "type", "ADDROBJ");
			WriteXMLAttribute(vXMLWriter, "dictvalue", TrimAll(vUUIDStreet));
			
			vXMLWriter.WriteEndElement(); // AddressObjectGlobal
		Else
			vXMLWriter.WriteStartElement("addressObjectDecomposed");
			
			If ValueIsFilled(vLivingAddressStruct.Region) Then
				WriteXMLAttribute(vXMLWriter, "region", vLivingAddressStruct.Region);
			EndIf;
			If ValueIsFilled(vLivingAddressStruct.Area) Then
				WriteXMLAttribute(vXMLWriter, "district", vLivingAddressStruct.Area);
			EndIf;
			If ValueIsFilled(vLivingAddressStruct.City) Then
				WriteXMLAttribute(vXMLWriter, "city", vLivingAddressStruct.City);
			EndIf;
			If ValueIsFilled(vLivingAddressStruct.Street) Then
				WriteXMLAttribute(vXMLWriter, "street", vLivingAddressStruct.Street);
			EndIf;
			
			vXMLWriter.WriteEndElement(); // AddressObjectDecomposed	
		EndIf;
		
		If ValueIsFilled(vLivingAddressStruct.House) Then
			vXMLWriter.WriteStartElement("housing");
			
			WriteXMLAttribute(vXMLWriter, "value", vLivingAddressStruct.House);
			WriteXMLAttribute(vXMLWriter, "type", "S_HOUSEPART");
			WriteXMLAttribute(vXMLWriter, "dictvalue", "ДОМ");
			
			vXMLWriter.WriteEndElement(); // Housing	
		EndIf;
		
		If ValueIsFilled(vLivingAddressStruct.Flat) Then
			vXMLWriter.WriteStartElement("housing");
			
			WriteXMLAttribute(vXMLWriter, "value", vLivingAddressStruct.Flat);
			WriteXMLAttribute(vXMLWriter, "type", "S_HOUSEPART");
			WriteXMLAttribute(vXMLWriter, "dictvalue", "КВАРТИРА");
			
			vXMLWriter.WriteEndElement(); // Housing	
		EndIf;
		
		vXMLWriter.WriteEndElement(); // LiveAddress
	EndIf;
	#EndRegion
	
	
	vXMLWriter.WriteEndElement(); // Registration
	#EndRegion
	
	vXMLWriter.Close();
	
	// Write record to the exported guests
	vHotel = ?(ValueIsFilled(Hotel), Hotel, SessionParameters.CurrentHotel);
	If ValueIsFilled(vHotel) Then
		vEGRM = InformationRegisters.GuestsExportedToUMMS.CreateRecordManager();
		vEGRM.Hotel = vHotel;
		vEGRM.Guest = vGuest;
		vEGRM.CheckOutDate = BegOfDay(vRow.ExpectedCheckOutDate);
		vEGRM.CheckInDate = BegOfDay(vRow.CheckInDate);
		vEGRM.CaseUUID = vUID;
		vEGRM.CaseIsRemovedFromRegister = False;
		vEGRM.Write(True);
	EndIf;
EndProcedure // WriteVegaCase

// -----------------------------------------------------------------------------
Function GetUUIDAddressFromDadata(pAddress)
	vUUIDAddress = "";
	vListArr = cmGetDadataArrayApiV4(TrimAll(pAddress));
	For Each vItem In vListArr Do
		If vItem.data.fias_level = 7 Then
			vUUIDAddress = vItem.data.fias_id;
			Break;
		ElsIf vItem.data.street_fias_id <> Null Then
			vUUIDAddress = vItem.data.street_fias_id;
			Break;	
		EndIf;
	EndDo;
	Return vUUIDAddress 
EndFunction // GetAddressFromDadata

// -----------------------------------------------------------------------------
Procedure WriteToForm5Files(pExportTable, pErrors, pThinClient = False, pAddressStorageRussian) 
	If pExportTable <> Undefined And pExportTable.Count() > 0 Then
		If pThinClient Then
			vFilesList = New ValueList();
			// Temp dir at server to create files and archive
			vExportDirRussian = TempFilesDir();
			// Clear OUT directory
			vPath = cmGetFullFileName("OUT", vExportDirRussian);
			DeleteFiles(vPath, "*.xml");
			// Zip all output files
			vZPFileName = vPath + "\" + pmGetForm5ZIPFileName();
			vZP = New ZipFileWriter(vZPFileName);
			// Do for each record in the list 
			For Each vRow In pExportTable Do
				vErrorRow = pErrors.Find(vRow.Accommodation, "Document");
				If vErrorRow = Undefined Then
					vFullFileName = "";
					WriteForm5Case(vRow, , , vFullFileName, vExportDirRussian);
					
					If vFilesList.FindByValue(vFullFileName) = Undefined Then
						vFilesList.Add(vFullFileName);
						
						vZP.Add(vFullFileName, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.DontProcess);
					EndIf;
				EndIf;
			EndDo; 
			vZP.Write();
			// Clear OUT directory from xml files
			DeleteFiles(vPath, "*.xml");
			// Clear IN directory
			vPath = cmGetFullFileName("IN", vExportDirRussian);
			DeleteFiles(vPath, "*.xml");
			pAddressStorageRussian = PutToTempStorage(New BinaryData(vZPFileName), New UUID());
		Else	
			vFilesList = New ValueList();
			// Clear OUT directory
			vPath = cmGetFullFileName("OUT", ExportDirRussian);
			DeleteFiles(vPath, "*.xml");
			// Zip all output files
			vZP = New ZipFileWriter(vPath + "\" + pmGetForm5ZIPFileName());
			// Do for each record in the list 
			For Each vRow In pExportTable Do
				vErrorRow = pErrors.Find(vRow.Accommodation, "Document");
				If vErrorRow = Undefined Then
					vFullFileName = "";
					WriteForm5Case(vRow, , , vFullFileName);
					
					If vFilesList.FindByValue(vFullFileName) = Undefined Then
						vFilesList.Add(vFullFileName);
						
						vZP.Add(vFullFileName, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.DontProcess);
					EndIf;
				EndIf;
			EndDo;
			vZP.Write();
			// Clear OUT directory from xml files
			DeleteFiles(vPath, "*.xml");
			// Clear IN directory
			vPath = cmGetFullFileName("IN", ExportDirRussian);
			DeleteFiles(vPath, "*.xml");
		EndIf;
	Else
		pAddressStorageForeigners = "<empty>";
	EndIf;
EndProcedure // WriteToForm5Files

// -----------------------------------------------------------------------------
Procedure WriteVegaFiles(pExportTable, pErrors, pThinClient = False, pAddressStorageRussian) 
	If pExportTable <> Undefined And pExportTable.Count() > 0 Then
		If pThinClient Then
			vFilesList = New ValueList();
			// Temp dir at server to create files and archive
			vExportDirForeigners = TempFilesDir();
			vPath = cmGetFullFileName("OUT", vExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
			vData = CurrentSessionDate(); 
			// Zip all output files
			vZPFileName = vPath + "\" + pmGetForm5ZIPFileName(Format(vData, "DF=yyyyMMddHHmmss"));
			vZP = New ZipFileWriter(vZPFileName);
			vNumber = 0;
			// Do for each record in the list 
			For Each vRow In pExportTable Do
				vErrorRow = pErrors.Find(vRow.Accommodation, "Document");
				If vErrorRow = Undefined Then
					vFullFilePath = "";
					WriteVegaCase(vRow, vFullFilePath, vExportDirForeigners, "OUT\FrOrg" + Format(vData, "DF=yyyyMMddHHmmss") + ?(vNumber = 0 , "", "_" + Format(vNumber, "NG=0")));
					
					If Not IsBlankString(vFullFilePath) Then
						If vFilesList.FindByValue(vFullFilePath) = Undefined Then
							vFilesList.Add(vFullFilePath);
							
							vZP.Add(vFullFilePath, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.DontProcess);
							vNumber = vNumber + 1;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vZP.Write();
			// Clear OUT directory from xml files
			DeleteFiles(vPath, "*.xml");
			// Clear IN directory
			vPath = cmGetFullFileName("IN", vExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
			pAddressStorageRussian = PutToTempStorage(New BinaryData(vZPFileName), New UUID());
		Else	
			vFilesList = New ValueList();
			// Clear OUT directory
			vPath = cmGetFullFileName("OUT", ExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
			vData = CurrentSessionDate();
			// Zip all output files
			vZP = New ZipFileWriter(vPath + "\" + pmGetForeignersZIPFileName(Format(vData, "DF=yyyyMMddHHmmss")));
			vNumber = 0;
			// Do for each record in the list 
			For Each vRow In pExportTable Do
				vErrorRow = pErrors.Find(vRow.Accommodation, "Document");
				If vErrorRow = Undefined Then
					vFullFilePath = "";
					
					WriteVegaCase(vRow, vFullFilePath, , "OUT\FrOrg" + Format(vData, "DF=yyyyMMddHHmmss") + ?(vNumber = 0 , "", "_" + Format(vNumber, "NG=0")));
					
					If Not IsBlankString(vFullFilePath) Then
						If vFilesList.FindByValue(vFullFilePath) = Undefined Then
							vFilesList.Add(vFullFilePath);
							
							vZP.Add(vFullFilePath, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.DontProcess);
							vNumber = vNumber + 1;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vZP.Write();
			// Clear OUT directory from xml files
			DeleteFiles(vPath, "*.xml");
			// Clear IN directory
			vPath = cmGetFullFileName("IN", ExportDirForeigners);
			DeleteFiles(vPath, "*.xml");
		EndIf;
	Else
		pAddressStorageForeigners = "<empty>";
	EndIf;		
EndProcedure // WriteToForm5Files

// -----------------------------------------------------------------------------
Function GetIdentityDocScan(pAccommodation)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ClientDataScansScanPictures.ScanPicture AS ScanPicture,
		|	ClientDataScansScanPictures.Ref AS Ref,
		|	ClientDataScansScanPictures.ScanConfiguration AS ScanConfiguration,
		|	CASE
		|		WHEN NOT ClientDataScansScanPictures.ScanConfiguration.IdentityDocumentType.Code IS NULL
		|			THEN 1
		|		WHEN ISNULL(ClientDataScansScanPictures.ScanConfiguration.IsVisa, FALSE)
		|			THEN 2
		|		WHEN ISNULL(ClientDataScansScanPictures.ScanConfiguration.IsMigrationCard, FALSE)
		|			THEN 3
		|	END AS SortingOrder
		|FROM
		|	Document.ClientDataScans.ScanPictures AS ClientDataScansScanPictures
		|WHERE
		|	NOT ClientDataScansScanPictures.Ref.DeletionMark
		|	AND (ClientDataScansScanPictures.Ref.ParentDoc = &qAccommodation
		|			OR ClientDataScansScanPictures.Ref.ParentDoc = &qFirstAccommodationInChain
		|			OR ClientDataScansScanPictures.Ref.ParentDoc.Guest = &qGuest
		|				AND ClientDataScansScanPictures.Ref.ParentDoc.Guest <> &qEmptyGuest
		|				AND ClientDataScansScanPictures.Ref.ParentDoc.GuestGroup = &qGuestGroup)
		|
		|ORDER BY
		|	SortingOrder";
	vQuery.SetParameter("qAccommodation", pAccommodation);
	vQuery.SetParameter("qFirstAccommodationInChain", pAccommodation.GetObject().pmGetFirstAccommodationInChain());
	vQuery.SetParameter("qGuest", pAccommodation.Guest);
	vQuery.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQuery.SetParameter("qGuestGroup", pAccommodation.GuestGroup);
	vQueryResult = vQuery.Execute().Unload();
	Return vQueryResult;	
EndFunction // GetIdentityDocScan

// -----------------------------------------------------------------------------
Function GetImageCatalogName(pClientDataScans)
	If Not ValueIsFilled(pClientDataScans.Hotel) Then
		Return Undefined;
	EndIf;
	vBLOBRootFolder = TrimAll(pClientDataScans.Hotel.BLOBRootFolder);
	vNonReplicatingAttributes = CachedSettings.cmGetNonReplicatingHotelAttributes(pClientDataScans.Hotel);
	If vNonReplicatingAttributes.Count() > 0 Then
		vBLOBRootFolder = TrimAll(vNonReplicatingAttributes.Get(0).BLOBRootFolder);
	EndIf;
	vDelimeter = "\";
	If Find(vBLOBRootFolder, "/") > 0 Then
		vDelimeter = "/";
	EndIf;
	If Right(vBLOBRootFolder, 1) <> vDelimeter Then
		vBLOBRootFolder = vBLOBRootFolder + vDelimeter;
	EndIf;
	rCatalogName = vBLOBRootFolder + "ClientDataScans" + vDelimeter + TrimAll(pClientDataScans.Number) + "_" + Format(pClientDataScans.Date, "DF=yyyy-MM-dd") + vDelimeter;
	Return rCatalogName;
EndFunction // pmGetImageCatalogName

// -----------------------------------------------------------------------------
Function GetLimitsAndConditions(pClientRef)
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	NestedSelect.Owner AS Owner,
	|	NestedSelect.Hotel AS Hotel,
	|	LimitsAndSpecialConditionTypes.Ref AS Characteristic,
	|	NestedSelect.CharacteristicValue AS CharacteristicValue
	|FROM
	|	ChartOfCharacteristicTypes.LimitsAndSpecialConditionTypes AS LimitsAndSpecialConditionTypes
	|		LEFT JOIN (SELECT
	|			LimitsAndSpecialConditions.Owner AS Owner,
	|			LimitsAndSpecialConditions.Hotel AS Hotel,
	|			LimitsAndSpecialConditions.Characteristic AS Characteristic,
	|			LimitsAndSpecialConditions.CharacteristicValue AS CharacteristicValue
	|		FROM
	|			InformationRegister.LimitsAndSpecialConditions AS LimitsAndSpecialConditions
	|		WHERE
	|			LimitsAndSpecialConditions.Owner = &qClient
	|			AND NOT LimitsAndSpecialConditions.Characteristic.DeletionMark) AS NestedSelect
	|		ON LimitsAndSpecialConditionTypes.Ref = NestedSelect.Characteristic
	|WHERE
	|	NOT LimitsAndSpecialConditionTypes.DeletionMark";
	vQry.SetParameter("qClient", pClientRef);
	vChars = vQry.Execute().Unload();
	Return vChars;
EndFunction // pmGetLimitsAndConditions

#EndRegion 

#Region Initialize

// -----------------------------------------------------------------------------
// Name spaces
// -----------------------------------------------------------------------------
vNSURICore 			= "http://umms.fms.gov.ru/replication/core";
vNSURICorrection 	= "http://umms.fms.gov.ru/replication/core/correction";
vNSURIFCCore 		= "http://umms.fms.gov.ru/replication/foreign-citizen-core";
vNSURIMigration 	= "http://umms.fms.gov.ru/replication/migration";
vNSURIHotel 		= "http://umms.fms.gov.ru/replication/hotel";
vNSURICaseEdit	 	= "http://umms.fms.gov.ru/replication/migration/staying/case-edit";
vNSURIForm5 		= "http://umms.fms.gov.ru/replication/hotel/form5";
vNSURIUnreg 		= "http://umms.fms.gov.ru/replication/migration/staying/unreg";
vNSURIStaying 		= "http://umms.fms.gov.ru/replication/migration/staying";
vNSURIInvitationApp = "http://umms.fms.gov.ru/replication/invitation-application";
vNSURIPayment 		= "http://umms.fms.gov.ru/replication/payment";
vNSURIHotelResponse = "http://umms.fms.gov.ru/hotel/hotel-response";

#EndRegion
