// -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

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
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For today
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Room) Then
		If Not Room.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room ';ru='Номер ';de='Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Gruppe Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Country) Then
		If Not Country.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Страна '; en = 'Country '; de = 'Land '") + 
			                     TrimAll(Country.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа стран '; en = 'Countries folder '; de = 'Ländergruppe '") + 
			                     TrimAll(Country.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qCountry", Country);
	ReportBuilder.Parameters.Insert("qCountryList", CountryList);
	If CountryList.Count() > 0 Then
		ReportBuilder.Parameters.Insert("qCountryListIsEmpty", False);
	Else
		ReportBuilder.Parameters.Insert("qCountryListIsEmpty", True);
	EndIf;
	ReportBuilder.Parameters.Insert("qCheckInOnly", CheckInOnly);
	ReportBuilder.Parameters.Insert("qCheckOutOnly", CheckOutOnly);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	
	// If output should be done using standart form then run query manually and
	// convert resulting table to the standart one
	vNumberOfPersons = 0;
	If OutputUsingStandartForm Then
		vQry = New Query();
		vQry.Text = QueryText;
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qPeriodFrom", PeriodFrom);
		vQry.SetParameter("qPeriodTo", PeriodTo);
		vQry.SetParameter("qRoom", Room);
		vQry.SetParameter("qCountry", Country);
		vQry.SetParameter("qCountryList", CountryList);
		If CountryList.Count() > 0 Then
			vQry.SetParameter("qCountryListIsEmpty", False);
		Else
			vQry.SetParameter("qCountryListIsEmpty", True);
		EndIf;
		vQry.SetParameter("qCheckInOnly", CheckInOnly);
		vQry.SetParameter("qCheckOutOnly", CheckOutOnly);
		vQry.SetParameter("qEmptyDate", '00010101');
		vSrcTab = vQry.Execute().Unload();
		
		vNumberOfPersons = vSrcTab.Count();
		
		vStdTab = ConvertToStandartForm(vSrcTab);
		
		ReportBuilder.DataSource = New DataSourceDescription(vStdTab);
		
		// Fill report builder fields presentations from the report template
		cmFillReportAttributesPresentations(ThisObject);
		
		// Remove "Guest has notification already" from the selected fields
		ReportBuilder.SelectedFields.Delete(ReportBuilder.SelectedFields.Find("GuestHasNotificationAlready"));
	EndIf;
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose
	
	// Footer
	If (CheckInOnly Or CheckOutOnly) And vNumberOfPersons <> 0 Then
		vTemplate = ThisObject.GetTemplate("ReportTemplate");
		vFooter = vTemplate.GetArea("Footer");
		vFooter.Parameters.mNumberOfPersons = vNumberOfPersons;
		pSpreadsheet.Put(vFooter);
	EndIf;

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	ForeignerRegistryRecord.Number AS RegistrationNumber,
	|	ForeignerRegistryRecord.Date AS RegistrationDate,
	|	DATEDIFF(ForeignerRegistryRecord.Date, ForeignerRegistryRecord.CheckOutDate, DAY) AS RegistrationPeriod,
	|	ForeignerRegistryRecord.LastName + "" "" + ForeignerRegistryRecord.FirstName + "" "" + ForeignerRegistryRecord.SecondName AS GuestFullName,
	|	ForeignerRegistryRecord.DateOfBirth,
	|	ForeignerRegistryRecord.Citizenship,
	|	ForeignerRegistryRecord.IdentityDocumentSeries + "" N"" + ForeignerRegistryRecord.IdentityDocumentNumber AS IdentityDocument,
	|	ForeignerRegistryRecord.IdentityDocumentValidToDate,
	|	ForeignerRegistryRecord.ArrivedFrom,
	|	ForeignerRegistryRecord.BorderCrossingDate,
	|	ForeignerRegistryRecord.CheckPointNumber,
	|	ForeignerRegistryRecord.VisaType,
	|	ForeignerRegistryRecord.VisaIssuedBy,
	|	ForeignerRegistryRecord.VisaNumber,
	|	ForeignerRegistryRecord.VisaFromDate,
	|	ForeignerRegistryRecord.VisaToDate,
	|	ForeignerRegistryRecord.VisaIdentifier,
	|	ForeignerRegistryRecord.VisaIssuedDate,
	|	ForeignerRegistryRecord.ResidencePermitDocument,
	|	ForeignerRegistryRecord.Route,
	|	ForeignerRegistryRecord.MigrationCardNumber,
	|	ForeignerRegistryRecord.MigrationCardDateTo,
	|	ForeignerRegistryRecord.Room,
	|	ForeignerRegistryRecord.TripPurpose,
	|	ForeignerRegistryRecord.ReceivingParty,
	|	CASE
	|		WHEN &qCheckInOnly
	|			THEN &qEmptyDate
	|		ELSE ForeignerRegistryRecord.CheckOutDate
	|	END AS CheckOutDate,
	|	ForeignerRegistryRecord.GuestHasNotificationAlready AS GuestHasNotificationAlready,
	|	ForeignerRegistryRecord.Remarks,
	|	1 AS Guests
	|{SELECT
	|	RegistrationNumber,
	|	RegistrationDate,
	|	RegistrationPeriod,
	|	GuestFullName,
	|	DateOfBirth,
	|	Citizenship.*,
	|	IdentityDocument,
	|	IdentityDocumentValidToDate,
	|	ArrivedFrom,
	|	BorderCrossingDate,
	|	CheckPointNumber,
	|	VisaType.*,
	|	VisaIssuedBy,
	|	VisaNumber,
	|	VisaFromDate,
	|	VisaToDate,
	|	VisaIdentifier,
	|	VisaIssuedDate,
	|	ResidencePermitDocument,
	|	Route,
	|	MigrationCardNumber,
	|	MigrationCardDateTo,
	|	Room.*,
	|	TripPurpose.*,
	|	ReceivingParty,
	|	CheckOutDate,
	|	Remarks,
	|	ForeignerRegistryRecord.Ref.* AS ForeignerRegistryRecord,
	|	GuestHasNotificationAlready AS GuestHasNotificationAlready,
	|	ForeignerRegistryRecord.Guest.*,
	|	ForeignerRegistryRecord.CheckInDate,
	|	ForeignerRegistryRecord.LastName,
	|	ForeignerRegistryRecord.FirstName,
	|	ForeignerRegistryRecord.SecondName,
	|	ForeignerRegistryRecord.VisaFromDate,
	|	ForeignerRegistryRecord.MigrationCardDateFrom,
	|	Guests}
	|FROM
	|	Document.ForeignerRegistryRecord AS ForeignerRegistryRecord
	|WHERE
	|	(NOT &qCheckInOnly
	|				AND NOT &qCheckOutOnly
	|				AND ForeignerRegistryRecord.Date >= &qPeriodFrom
	|				AND ForeignerRegistryRecord.Date <= &qPeriodTo
	|			OR &qCheckInOnly
	|				AND ForeignerRegistryRecord.CheckInDate >= &qPeriodFrom
	|				AND ForeignerRegistryRecord.CheckInDate <= &qPeriodTo
	|			OR &qCheckOutOnly
	|				AND ForeignerRegistryRecord.IsCheckedOut
	|				AND ForeignerRegistryRecord.CheckOutDate >= &qPeriodFrom
	|				AND ForeignerRegistryRecord.CheckOutDate <= &qPeriodTo)
	|	AND ForeignerRegistryRecord.Posted = TRUE
	|	AND ForeignerRegistryRecord.Hotel IN HIERARCHY(&qHotel)
	|	AND ForeignerRegistryRecord.Room IN HIERARCHY(&qRoom)
	|	AND ForeignerRegistryRecord.Citizenship IN HIERARCHY(&qCountry)
	|	AND (ForeignerRegistryRecord.Citizenship IN (&qCountryList)
	|			OR &qCountryListIsEmpty)
	|{WHERE
	|	ForeignerRegistryRecord.Number AS RegistrationNumber,
	|	ForeignerRegistryRecord.Date AS RegistrationDate,
	|	(DATEDIFF(ForeignerRegistryRecord.Date, ForeignerRegistryRecord.CheckOutDate, DAY)) AS RegistrationPeriod,
	|	(ForeignerRegistryRecord.LastName + "" "" + ForeignerRegistryRecord.FirstName + "" "" + ForeignerRegistryRecord.SecondName) AS GuestFullName,
	|	ForeignerRegistryRecord.DateOfBirth,
	|	ForeignerRegistryRecord.Citizenship.*,
	|	(ForeignerRegistryRecord.IdentityDocumentSeries + "" N"" + ForeignerRegistryRecord.IdentityDocumentNumber) AS Field5,
	|	ForeignerRegistryRecord.IdentityDocumentValidToDate,
	|	ForeignerRegistryRecord.ArrivedFrom,
	|	ForeignerRegistryRecord.BorderCrossingDate,
	|	ForeignerRegistryRecord.CheckPointNumber,
	|	ForeignerRegistryRecord.VisaType.*,
	|	ForeignerRegistryRecord.VisaIssuedBy,
	|	ForeignerRegistryRecord.VisaNumber,
	|	ForeignerRegistryRecord.VisaFromDate,
	|	ForeignerRegistryRecord.VisaToDate,
	|	ForeignerRegistryRecord.VisaIdentifier,
	|	ForeignerRegistryRecord.VisaIssuedDate,
	|	ForeignerRegistryRecord.ResidencePermitDocument,
	|	ForeignerRegistryRecord.Route,
	|	ForeignerRegistryRecord.MigrationCardNumber,
	|	ForeignerRegistryRecord.MigrationCardDateTo,
	|	ForeignerRegistryRecord.Room.*,
	|	ForeignerRegistryRecord.TripPurpose.*,
	|	ForeignerRegistryRecord.ReceivingParty,
	|	(CASE
	|			WHEN &qCheckInOnly
	|				THEN &qEmptyDate
	|			ELSE ForeignerRegistryRecord.CheckOutDate
	|		END) AS CheckOutDate,
	|	ForeignerRegistryRecord.GuestHasNotificationAlready AS GuestHasNotificationAlready,
	|	ForeignerRegistryRecord.Remarks,
	|	ForeignerRegistryRecord.Ref.*,
	|	ForeignerRegistryRecord.Guest.*,
	|	ForeignerRegistryRecord.CheckInDate,
	|	ForeignerRegistryRecord.LastName,
	|	ForeignerRegistryRecord.FirstName,
	|	ForeignerRegistryRecord.SecondName,
	|	ForeignerRegistryRecord.VisaFromDate,
	|	ForeignerRegistryRecord.MigrationCardDateFrom}
	|
	|ORDER BY
	|	RegistrationNumber
	|{ORDER BY
	|	RegistrationNumber,
	|	RegistrationDate,
	|	RegistrationPeriod,
	|	GuestFullName,
	|	DateOfBirth,
	|	Citizenship.*,
	|	IdentityDocument,
	|	IdentityDocumentValidToDate,
	|	ArrivedFrom,
	|	BorderCrossingDate,
	|	CheckPointNumber,
	|	VisaType.*,
	|	VisaIssuedBy,
	|	VisaNumber,
	|	VisaFromDate,
	|	VisaToDate,
	|	VisaIdentifier,
	|	VisaIssuedDate,
	|	ResidencePermitDocument,
	|	Route,
	|	MigrationCardNumber,
	|	MigrationCardDateTo,
	|	TripPurpose.*,
	|	ReceivingParty,
	|	CheckOutDate,
	|	Remarks,
	|	ForeignerRegistryRecord.Ref.* AS ForeignerRegistryRecord,
	|	GuestHasNotificationAlready AS GuestHasNotificationAlready,
	|	Room.*,
	|	ForeignerRegistryRecord.Guest.*,
	|	ForeignerRegistryRecord.CheckInDate,
	|	ForeignerRegistryRecord.LastName,
	|	ForeignerRegistryRecord.FirstName,
	|	ForeignerRegistryRecord.SecondName,
	|	ForeignerRegistryRecord.VisaFromDate,
	|	ForeignerRegistryRecord.MigrationCardDateFrom}
	|TOTALS
	|	SUM(Guests)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Room.*,
	|	ForeignerRegistryRecord.Guest.*,
	|	DateOfBirth,
	|	Citizenship.*,
	|	ArrivedFrom,
	|	BorderCrossingDate,
	|	CheckPointNumber,
	|	Route,
	|	TripPurpose.*,
	|	ReceivingParty}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Foreigner citizen registry journal';RU='Журнал регистрации иностранных граждан';de='Registrierungsheft ausländischer Bürger'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Function ConvertToStandartForm(pSrcTab)
	vTab = New ValueTable();
	vTab.Columns.Add("FCRRNumber", cmGetStringTypeDescription()); 
	vTab.Columns.Add("FCRRDate", cmGetStringTypeDescription()); 
	vTab.Columns.Add("FCRRGuestFullName", cmGetStringTypeDescription()); 
	vTab.Columns.Add("FCRRIDData", cmGetStringTypeDescription()); 
	vTab.Columns.Add("FCRRCountryFrom", cmGetStringTypeDescription()); 
	vTab.Columns.Add("FCRRVisaData", cmGetStringTypeDescription()); 
	vTab.Columns.Add("FCRRMigrCardData", cmGetStringTypeDescription()); 
	vTab.Columns.Add("Room", cmGetCatalogTypeDescription("Rooms"));
	vTab.Columns.Add("FCRRTripPurpose", cmGetStringTypeDescription());
	vTab.Columns.Add("CheckOutDate", cmGetDateTypeDescription());
	vTab.Columns.Add("Remarks", cmGetStringTypeDescription());
	vTab.Columns.Add("GuestHasNotificationAlready", cmGetBooleanTypeDescription());
	
	For Each vSrcRow In pSrcTab Do
		vRow = vTab.Add();
		
		vRow.FCRRNumber = TrimAll(vSrcRow.RegistrationNumber); 
		vRow.FCRRDate = Format(vSrcRow.RegistrationDate, "DF=dd.MM.yy") + ", " + vSrcRow.RegistrationPeriod + NStr("EN=' days';RU=' дней';de='Tage'"); 
		vRow.FCRRGuestFullName = TrimAll(vSrcRow.GuestFullName); 
		vRow.FCRRIDData = NStr("EN='Birth. '; RU='Род. '; DE='Geburt '") + Format(vSrcRow.DateOfBirth, "DF=dd.MM.yy") + ", " + 
		                  TrimAll(vSrcRow.Citizenship) + NStr("EN=' document '; RU=' документ '; DE=' Dokument '") + TrimAll(vSrcRow.IdentityDocument) + 
		                  NStr("EN=' valid to '; RU=' действ. до '; DE=' gültig bis '") + Format(vSrcRow.IdentityDocumentValidToDate, "DF=dd.MM.yy");
		vRow.FCRRCountryFrom = TrimAll(vSrcRow.ArrivedFrom) + ", " + Format(vSrcRow.BorderCrossingDate, "DF=dd.MM.yy") + 
		                       NStr("EN=', CP '; RU=', КПП '; DE=', PPC '") + TrimAll(vSrcRow.CheckPointNumber);
		If vSrcRow.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit Then
			vRow.FCRRVisaData = ?(IsBlankString(vSrcRow.VisaIdentifier), "", NStr("EN='Temp. Res. Permit '; RU='Разр. на врем. преб. '; DE='Temp. Res. Permit '") + NStr("EN='N'; RU='№'; DE='Nr.'") + TrimAll(vSrcRow.VisaIdentifier) + 
			                    ?(IsBlankString(vSrcRow.VisaIssuedBy), "", " " + TrimAll(vSrcRow.VisaIssuedBy)) + NStr("EN=', valid from '; RU=', действ. с '; DE=', gültig ab '") + Format(vSrcRow.VisaIssuedDate, "DF=dd.MM.yy") + 
			                    NStr("EN=' to '; RU=' по ';de=' bis '") + Format(vSrcRow.VisaToDate, "DF=dd.MM.yy"));
		ElsIf vSrcRow.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit Then
			vRow.FCRRVisaData = ?(IsBlankString(vSrcRow.VisaIdentifier), "", NStr("EN='Perm. Res. Permit '; RU='Разр. на пост. преб. '; DE='Perm. Res. Permit '") + NStr("EN='N'; RU='№'; DE='Nr.'") + TrimAll(vSrcRow.VisaIdentifier) + 
			                    ?(IsBlankString(vSrcRow.VisaIssuedBy), "", " " + TrimAll(vSrcRow.VisaIssuedBy)) + NStr("EN=', valid from '; RU=', действ. с '; DE=', gültig ab '") + Format(vSrcRow.VisaIssuedDate, "DF=dd.MM.yy") + 
			                    NStr("EN=' to '; RU=' по ';de=' bis '") + Format(vSrcRow.VisaToDate, "DF=dd.MM.yy"));
		Else
			vRow.FCRRVisaData = ?(IsBlankString(vSrcRow.VisaNumber), "", NStr("EN='Visa '; RU='Виза '; DE='Visum '") + TrimAll(vSrcRow.VisaType) + NStr("EN=' N'; RU=' №'; DE=' Nr.'") + TrimAll(vSrcRow.VisaNumber) + 
			                    ?(IsBlankString(vSrcRow.VisaIssuedBy), "", " " + TrimAll(vSrcRow.VisaIssuedBy)) + NStr("EN=', valid from '; RU=', действ. с '; DE=', gültig ab '") + Format(vSrcRow.VisaFromDate, "DF=dd.MM.yy") + 
			                    NStr("EN=' to ';RU=' по ';de=' bis '") + Format(vSrcRow.VisaToDate, "DF=dd.MM.yy") + 
								NStr("EN=', route '; RU=', маршрут '; DE=', Route '") + TrimAll(vSrcRow.Route));
		EndIf;
		vRow.FCRRMigrCardData = ?(IsBlankString(vSrcRow.MigrationCardNumber), "", NStr("EN='MC '; RU='МК '") + TrimAll(vSrcRow.MigrationCardNumber) + 
		                          NStr("EN=', valid to '; RU=', действ. по '; DE=' gültig bis '") + Format(vSrcRow.MigrationCardDateTo, "DF=dd.MM.yy") +
							      ?(IsBlankString(vSrcRow.VisaNumber), NStr("EN=', route '; RU=', маршрут '; DE=', Route '") + TrimAll(vSrcRow.Route), ""));
		vRow.Room = vSrcRow.Room; 
		vRow.FCRRTripPurpose = TrimAll(vSrcRow.TripPurpose) + 
							   ?(IsBlankString(vSrcRow.ReceivingParty), "", NStr("EN=', receiving party '; RU=', приним. сторона '; DE=', Empfängerseite '") + TrimAll(vSrcRow.ReceivingParty)); 
		vRow.CheckOutDate = vSrcRow.CheckOutDate; 
		vRow.Remarks = TrimAll(vSrcRow.Remarks); 
		vRow.GuestHasNotificationAlready = vSrcRow.GuestHasNotificationAlready; 
	EndDo;
	
	Return vTab;
EndFunction // ConvertToStandartForm