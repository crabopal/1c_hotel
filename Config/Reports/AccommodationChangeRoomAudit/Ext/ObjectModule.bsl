
#Region Public

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
	If ValueIsFilled(MovedToRoom) Then
		If Not MovedToRoom.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Moved to room ';ru='Переселения в номер ';de='Umzug ins Zimmer '") + 
			                     TrimAll(MovedToRoom.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Moved to rooms folder ';ru='Переселения в группу номеров ';de='Umzug ins Gruppe Zimmer '") + 
			                     TrimAll(MovedToRoom.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(MovedToRoomType) Then
		If Not MovedToRoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Moved to room type ';ru='Переселения в тип номера ';de='Umzug ins Zimmertyp '") + 
			                     TrimAll(MovedToRoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Moved to room types folder ';ru='Переселения в группу типов номеров ';de='Umzug ins Gruppe Zimmertypen '") + 
			                     TrimAll(MovedToRoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(MovedFromRoom) Then
		If Not MovedFromRoom.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Moved from room ';ru='Переселения из номера ';de='Umsiedlung aus dem Zimmer '") + 
			                     TrimAll(MovedFromRoom.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Moved from rooms folder ';ru='Переселения из группы номеров ';de='Umsiedlung aus dem Gruppe Zimmer '") + 
			                     TrimAll(MovedFromRoom.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(MovedFromRoomType) Then
		If Not MovedFromRoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Moved from room type ';ru='Переселения из типа номера ';de='Umsiedlung aus dem Zimmertyp '") + 
			                     TrimAll(MovedFromRoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Moved from room types folder ';ru='Переселения из группы типов номеров ';de='Umsiedlung aus dem Gruppe Zimmertypen '") + 
			                     TrimAll(MovedFromRoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Employee) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Gruppe Mitarbeiter '") + 
			                     TrimAll(Employee) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ShowMainRoomGuestsOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Main room guests only';ru='Только основные гости номера';de='Nur Hauptgäste des Zimmers'") + 
							 ";" + Chars.LF;
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
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qMovedFromRoom", MovedFromRoom);
	ReportBuilder.Parameters.Insert("qMovedFromRoomType", MovedFromRoomType);
	ReportBuilder.Parameters.Insert("qMovedToRoom", MovedToRoom);
	ReportBuilder.Parameters.Insert("qMovedToRoomType", MovedToRoomType);
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", ShowMainRoomGuestsOnly);

	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	AccommodationsBeforeBeginOfPeriod.Accommodation AS Accommodation,
	|	AccommodationsBeforeBeginOfPeriod.Hotel AS Hotel,
	|	AccommodationsBeforeBeginOfPeriod.AccommodationStatus AS AccommodationStatus,
	|	AccommodationsBeforeBeginOfPeriod.Room AS Room,
	|	AccommodationsBeforeBeginOfPeriod.RoomType AS RoomType,
	|	AccommodationsBeforeBeginOfPeriod.CheckInDate AS CheckInDate,
	|	AccommodationsBeforeBeginOfPeriod.Duration AS Duration,
	|	AccommodationsBeforeBeginOfPeriod.CheckOutDate AS CheckOutDate,
	|	AccommodationsBeforeBeginOfPeriod.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationsBeforeBeginOfPeriod.NumberOfAdults AS NumberOfAdults,
	|	AccommodationsBeforeBeginOfPeriod.NumberOfTeenagers AS NumberOfTeenagers,
	|	AccommodationsBeforeBeginOfPeriod.NumberOfChildren AS NumberOfChildren,
	|	AccommodationsBeforeBeginOfPeriod.NumberOfInfants AS NumberOfInfants,
	|	AccommodationsBeforeBeginOfPeriod.AccommodationType AS AccommodationType,
	|	AccommodationsBeforeBeginOfPeriod.NumberOfPersons AS NumberOfPersons,
	|	AccommodationsBeforeBeginOfPeriod.Customer AS Customer,
	|	AccommodationsBeforeBeginOfPeriod.Contract AS Contract,
	|	AccommodationsBeforeBeginOfPeriod.ContactPerson AS ContactPerson,
	|	AccommodationsBeforeBeginOfPeriod.Agent AS Agent,
	|	AccommodationsBeforeBeginOfPeriod.Guest AS Guest,
	|	AccommodationsBeforeBeginOfPeriod.ClientType AS ClientType,
	|	AccommodationsBeforeBeginOfPeriod.RoomRate AS RoomRate,
	|	AccommodationsBeforeBeginOfPeriod.TripPurpose AS TripPurpose,
	|	AccommodationsBeforeBeginOfPeriod.SourceOfBusiness AS SourceOfBusiness,
	|	AccommodationsBeforeBeginOfPeriod.MarketingCode AS MarketingCode,
	|	AccommodationsBeforeBeginOfPeriod.RoomQuota AS RoomQuota,
	|	AccommodationsBeforeBeginOfPeriod.GuestGroup AS GuestGroup,
	|	AccommodationsBeforeBeginOfPeriod.HotelProduct AS HotelProduct,
	|	AccommodationsBeforeBeginOfPeriod.DiscountType AS DiscountType,
	|	AccommodationsBeforeBeginOfPeriod.Discount AS Discount,
	|	AccommodationsBeforeBeginOfPeriod.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	AccommodationsBeforeBeginOfPeriod.Company AS Company,
	|	CAST(AccommodationsBeforeBeginOfPeriod.Remarks AS STRING(1024)) AS Remarks,
	|	CAST(AccommodationsBeforeBeginOfPeriod.Car AS STRING(1024)) AS Car,
	|	AccommodationsBeforeBeginOfPeriod.Period AS Period,
	|	AccommodationChangeHistory.User AS Employee
	|INTO AccommodationsBeforeBeginOfPeriod
	|FROM
	|	InformationRegister.AccommodationChangeHistory.SliceLast(&qPeriodFrom, ) AS AccommodationsBeforeBeginOfPeriod
	|		LEFT JOIN InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|		ON AccommodationsBeforeBeginOfPeriod.Accommodation = AccommodationChangeHistory.Accommodation
	|			AND AccommodationsBeforeBeginOfPeriod.Period = AccommodationChangeHistory.Period
	|WHERE
	|	AccommodationsBeforeBeginOfPeriod.Hotel IN HIERARCHY(&qHotel)
	|	AND AccommodationsBeforeBeginOfPeriod.CheckInDate < &qPeriodTo
	|	AND AccommodationsBeforeBeginOfPeriod.CheckOutDate > &qPeriodFrom
	|	AND AccommodationsBeforeBeginOfPeriod.Accommodation.AccommodationStatus.IsActive
	|	AND AccommodationsBeforeBeginOfPeriod.Accommodation.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccommodationsAfterBeginOfPeriod.Accommodation AS Accommodation,
	|	AccommodationsAfterBeginOfPeriod.Hotel AS Hotel,
	|	AccommodationsAfterBeginOfPeriod.AccommodationStatus AS AccommodationStatus,
	|	AccommodationsAfterBeginOfPeriod.Room AS Room,
	|	AccommodationsAfterBeginOfPeriod.RoomType AS RoomType,
	|	AccommodationsAfterBeginOfPeriod.CheckInDate AS CheckInDate,
	|	AccommodationsAfterBeginOfPeriod.Duration AS Duration,
	|	AccommodationsAfterBeginOfPeriod.CheckOutDate AS CheckOutDate,
	|	AccommodationsAfterBeginOfPeriod.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationsAfterBeginOfPeriod.NumberOfAdults AS NumberOfAdults,
	|	AccommodationsAfterBeginOfPeriod.NumberOfTeenagers AS NumberOfTeenagers,
	|	AccommodationsAfterBeginOfPeriod.NumberOfChildren AS NumberOfChildren,
	|	AccommodationsAfterBeginOfPeriod.NumberOfInfants AS NumberOfInfants,
	|	AccommodationsAfterBeginOfPeriod.AccommodationType AS AccommodationType,
	|	AccommodationsAfterBeginOfPeriod.NumberOfPersons AS NumberOfPersons,
	|	AccommodationsAfterBeginOfPeriod.Customer AS Customer,
	|	AccommodationsAfterBeginOfPeriod.Contract AS Contract,
	|	AccommodationsAfterBeginOfPeriod.ContactPerson AS ContactPerson,
	|	AccommodationsAfterBeginOfPeriod.Agent AS Agent,
	|	AccommodationsAfterBeginOfPeriod.Guest AS Guest,
	|	AccommodationsAfterBeginOfPeriod.ClientType AS ClientType,
	|	AccommodationsAfterBeginOfPeriod.RoomRate AS RoomRate,
	|	AccommodationsAfterBeginOfPeriod.TripPurpose AS TripPurpose,
	|	AccommodationsAfterBeginOfPeriod.SourceOfBusiness AS SourceOfBusiness,
	|	AccommodationsAfterBeginOfPeriod.MarketingCode AS MarketingCode,
	|	AccommodationsAfterBeginOfPeriod.RoomQuota AS RoomQuota,
	|	AccommodationsAfterBeginOfPeriod.GuestGroup AS GuestGroup,
	|	AccommodationsAfterBeginOfPeriod.HotelProduct AS HotelProduct,
	|	AccommodationsAfterBeginOfPeriod.DiscountType AS DiscountType,
	|	AccommodationsAfterBeginOfPeriod.Discount AS Discount,
	|	AccommodationsAfterBeginOfPeriod.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	AccommodationsAfterBeginOfPeriod.Company AS Company,
	|	CAST(AccommodationsAfterBeginOfPeriod.Remarks AS STRING(1024)) AS Remarks,
	|	CAST(AccommodationsAfterBeginOfPeriod.Car AS STRING(1024)) AS Car,
	|	AccommodationsAfterBeginOfPeriod.Period AS Period,
	|	AccommodationChangeHistory.User AS Employee
	|INTO AccommodationsAfterBeginOfPeriod
	|FROM
	|	InformationRegister.AccommodationChangeHistory.SliceFirst(&qPeriodFrom, ) AS AccommodationsAfterBeginOfPeriod
	|		LEFT JOIN InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|		ON AccommodationsAfterBeginOfPeriod.Accommodation = AccommodationChangeHistory.Accommodation
	|			AND AccommodationsAfterBeginOfPeriod.Period = AccommodationChangeHistory.Period
	|WHERE
	|	AccommodationsAfterBeginOfPeriod.Hotel IN HIERARCHY(&qHotel)
	|	AND AccommodationsAfterBeginOfPeriod.CheckInDate < &qPeriodTo
	|	AND AccommodationsAfterBeginOfPeriod.CheckOutDate > &qPeriodFrom
	|	AND AccommodationsAfterBeginOfPeriod.Accommodation.AccommodationStatus.IsActive
	|	AND AccommodationsAfterBeginOfPeriod.Accommodation.Posted
	|	AND NOT AccommodationsAfterBeginOfPeriod.Accommodation IN
	|				(SELECT
	|					AccommodationsBeforeBeginOfPeriod.Accommodation
	|				FROM
	|					AccommodationsBeforeBeginOfPeriod AS AccommodationsBeforeBeginOfPeriod)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccommodationsAtBeginOfPeriod.Accommodation AS Accommodation,
	|	AccommodationsAtBeginOfPeriod.Hotel AS Hotel,
	|	AccommodationsAtBeginOfPeriod.AccommodationStatus AS AccommodationStatus,
	|	AccommodationsAtBeginOfPeriod.Room AS Room,
	|	AccommodationsAtBeginOfPeriod.RoomType AS RoomType,
	|	AccommodationsAtBeginOfPeriod.CheckInDate AS CheckInDate,
	|	AccommodationsAtBeginOfPeriod.Duration AS Duration,
	|	AccommodationsAtBeginOfPeriod.CheckOutDate AS CheckOutDate,
	|	AccommodationsAtBeginOfPeriod.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationsAtBeginOfPeriod.NumberOfAdults AS NumberOfAdults,
	|	AccommodationsAtBeginOfPeriod.NumberOfTeenagers AS NumberOfTeenagers,
	|	AccommodationsAtBeginOfPeriod.NumberOfChildren AS NumberOfChildren,
	|	AccommodationsAtBeginOfPeriod.NumberOfInfants AS NumberOfInfants,
	|	AccommodationsAtBeginOfPeriod.AccommodationType AS AccommodationType,
	|	AccommodationsAtBeginOfPeriod.NumberOfPersons AS NumberOfPersons,
	|	AccommodationsAtBeginOfPeriod.Customer AS Customer,
	|	AccommodationsAtBeginOfPeriod.Contract AS Contract,
	|	AccommodationsAtBeginOfPeriod.ContactPerson AS ContactPerson,
	|	AccommodationsAtBeginOfPeriod.Agent AS Agent,
	|	AccommodationsAtBeginOfPeriod.Guest AS Guest,
	|	AccommodationsAtBeginOfPeriod.ClientType AS ClientType,
	|	AccommodationsAtBeginOfPeriod.RoomRate AS RoomRate,
	|	AccommodationsAtBeginOfPeriod.TripPurpose AS TripPurpose,
	|	AccommodationsAtBeginOfPeriod.SourceOfBusiness AS SourceOfBusiness,
	|	AccommodationsAtBeginOfPeriod.MarketingCode AS MarketingCode,
	|	AccommodationsAtBeginOfPeriod.RoomQuota AS RoomQuota,
	|	AccommodationsAtBeginOfPeriod.GuestGroup AS GuestGroup,
	|	AccommodationsAtBeginOfPeriod.HotelProduct AS HotelProduct,
	|	AccommodationsAtBeginOfPeriod.DiscountType AS DiscountType,
	|	AccommodationsAtBeginOfPeriod.Discount AS Discount,
	|	AccommodationsAtBeginOfPeriod.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	AccommodationsAtBeginOfPeriod.Company AS Company,
	|	AccommodationsAtBeginOfPeriod.Remarks AS Remarks,
	|	AccommodationsAtBeginOfPeriod.Car AS Car,
	|	AccommodationsAtBeginOfPeriod.Period AS Period,
	|	AccommodationsAtBeginOfPeriod.Employee AS Employee
	|INTO AccommodationsAtBeginOfPeriod
	|FROM
	|	(SELECT
	|		AccommodationsBeforeBeginOfPeriod.Accommodation AS Accommodation,
	|		AccommodationsBeforeBeginOfPeriod.Hotel AS Hotel,
	|		AccommodationsBeforeBeginOfPeriod.AccommodationStatus AS AccommodationStatus,
	|		AccommodationsBeforeBeginOfPeriod.Room AS Room,
	|		AccommodationsBeforeBeginOfPeriod.RoomType AS RoomType,
	|		AccommodationsBeforeBeginOfPeriod.CheckInDate AS CheckInDate,
	|		AccommodationsBeforeBeginOfPeriod.Duration AS Duration,
	|		AccommodationsBeforeBeginOfPeriod.CheckOutDate AS CheckOutDate,
	|		AccommodationsBeforeBeginOfPeriod.AccommodationTemplate AS AccommodationTemplate,
	|		AccommodationsBeforeBeginOfPeriod.NumberOfAdults AS NumberOfAdults,
	|		AccommodationsBeforeBeginOfPeriod.NumberOfTeenagers AS NumberOfTeenagers,
	|		AccommodationsBeforeBeginOfPeriod.NumberOfChildren AS NumberOfChildren,
	|		AccommodationsBeforeBeginOfPeriod.NumberOfInfants AS NumberOfInfants,
	|		AccommodationsBeforeBeginOfPeriod.AccommodationType AS AccommodationType,
	|		AccommodationsBeforeBeginOfPeriod.NumberOfPersons AS NumberOfPersons,
	|		AccommodationsBeforeBeginOfPeriod.Customer AS Customer,
	|		AccommodationsBeforeBeginOfPeriod.Contract AS Contract,
	|		AccommodationsBeforeBeginOfPeriod.ContactPerson AS ContactPerson,
	|		AccommodationsBeforeBeginOfPeriod.Agent AS Agent,
	|		AccommodationsBeforeBeginOfPeriod.Guest AS Guest,
	|		AccommodationsBeforeBeginOfPeriod.ClientType AS ClientType,
	|		AccommodationsBeforeBeginOfPeriod.RoomRate AS RoomRate,
	|		AccommodationsBeforeBeginOfPeriod.TripPurpose AS TripPurpose,
	|		AccommodationsBeforeBeginOfPeriod.SourceOfBusiness AS SourceOfBusiness,
	|		AccommodationsBeforeBeginOfPeriod.MarketingCode AS MarketingCode,
	|		AccommodationsBeforeBeginOfPeriod.RoomQuota AS RoomQuota,
	|		AccommodationsBeforeBeginOfPeriod.GuestGroup AS GuestGroup,
	|		AccommodationsBeforeBeginOfPeriod.HotelProduct AS HotelProduct,
	|		AccommodationsBeforeBeginOfPeriod.DiscountType AS DiscountType,
	|		AccommodationsBeforeBeginOfPeriod.Discount AS Discount,
	|		AccommodationsBeforeBeginOfPeriod.PlannedPaymentMethod AS PlannedPaymentMethod,
	|		AccommodationsBeforeBeginOfPeriod.Company AS Company,
	|		AccommodationsBeforeBeginOfPeriod.Remarks AS Remarks,
	|		AccommodationsBeforeBeginOfPeriod.Car AS Car,
	|		AccommodationsBeforeBeginOfPeriod.Period AS Period,
	|		AccommodationsBeforeBeginOfPeriod.Employee AS Employee
	|	FROM
	|		AccommodationsBeforeBeginOfPeriod AS AccommodationsBeforeBeginOfPeriod
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AccommodationsAfterBeginOfPeriod.Accommodation,
	|		AccommodationsAfterBeginOfPeriod.Hotel,
	|		AccommodationsAfterBeginOfPeriod.AccommodationStatus,
	|		AccommodationsAfterBeginOfPeriod.Room,
	|		AccommodationsAfterBeginOfPeriod.RoomType,
	|		AccommodationsAfterBeginOfPeriod.CheckInDate,
	|		AccommodationsAfterBeginOfPeriod.Duration,
	|		AccommodationsAfterBeginOfPeriod.CheckOutDate,
	|		AccommodationsAfterBeginOfPeriod.AccommodationTemplate,
	|		AccommodationsAfterBeginOfPeriod.NumberOfAdults,
	|		AccommodationsAfterBeginOfPeriod.NumberOfTeenagers,
	|		AccommodationsAfterBeginOfPeriod.NumberOfChildren,
	|		AccommodationsAfterBeginOfPeriod.NumberOfInfants,
	|		AccommodationsAfterBeginOfPeriod.AccommodationType,
	|		AccommodationsAfterBeginOfPeriod.NumberOfPersons,
	|		AccommodationsAfterBeginOfPeriod.Customer,
	|		AccommodationsAfterBeginOfPeriod.Contract,
	|		AccommodationsAfterBeginOfPeriod.ContactPerson,
	|		AccommodationsAfterBeginOfPeriod.Agent,
	|		AccommodationsAfterBeginOfPeriod.Guest,
	|		AccommodationsAfterBeginOfPeriod.ClientType,
	|		AccommodationsAfterBeginOfPeriod.RoomRate,
	|		AccommodationsAfterBeginOfPeriod.TripPurpose,
	|		AccommodationsAfterBeginOfPeriod.SourceOfBusiness,
	|		AccommodationsAfterBeginOfPeriod.MarketingCode,
	|		AccommodationsAfterBeginOfPeriod.RoomQuota,
	|		AccommodationsAfterBeginOfPeriod.GuestGroup,
	|		AccommodationsAfterBeginOfPeriod.HotelProduct,
	|		AccommodationsAfterBeginOfPeriod.DiscountType,
	|		AccommodationsAfterBeginOfPeriod.Discount,
	|		AccommodationsAfterBeginOfPeriod.PlannedPaymentMethod,
	|		AccommodationsAfterBeginOfPeriod.Company,
	|		AccommodationsAfterBeginOfPeriod.Remarks,
	|		AccommodationsAfterBeginOfPeriod.Car,
	|		AccommodationsAfterBeginOfPeriod.Period,
	|		AccommodationsAfterBeginOfPeriod.Employee
	|	FROM
	|		AccommodationsAfterBeginOfPeriod AS AccommodationsAfterBeginOfPeriod) AS AccommodationsAtBeginOfPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccommodationsAtEndOfPeriod.Accommodation AS Accommodation,
	|	AccommodationsAtEndOfPeriod.Hotel AS Hotel,
	|	AccommodationsAtEndOfPeriod.AccommodationStatus AS AccommodationStatus,
	|	AccommodationsAtEndOfPeriod.Room AS Room,
	|	AccommodationsAtEndOfPeriod.RoomType AS RoomType,
	|	AccommodationsAtEndOfPeriod.CheckInDate AS CheckInDate,
	|	AccommodationsAtEndOfPeriod.Duration AS Duration,
	|	AccommodationsAtEndOfPeriod.CheckOutDate AS CheckOutDate,
	|	AccommodationsAtEndOfPeriod.AccommodationTemplate AS AccommodationTemplate,
	|	AccommodationsAtEndOfPeriod.NumberOfAdults AS NumberOfAdults,
	|	AccommodationsAtEndOfPeriod.NumberOfTeenagers AS NumberOfTeenagers,
	|	AccommodationsAtEndOfPeriod.NumberOfChildren AS NumberOfChildren,
	|	AccommodationsAtEndOfPeriod.NumberOfInfants AS NumberOfInfants,
	|	AccommodationsAtEndOfPeriod.AccommodationType AS AccommodationType,
	|	AccommodationsAtEndOfPeriod.NumberOfPersons AS NumberOfPersons,
	|	AccommodationsAtEndOfPeriod.Customer AS Customer,
	|	AccommodationsAtEndOfPeriod.Contract AS Contract,
	|	AccommodationsAtEndOfPeriod.ContactPerson AS ContactPerson,
	|	AccommodationsAtEndOfPeriod.Agent AS Agent,
	|	AccommodationsAtEndOfPeriod.Guest AS Guest,
	|	AccommodationsAtEndOfPeriod.ClientType AS ClientType,
	|	AccommodationsAtEndOfPeriod.RoomRate AS RoomRate,
	|	AccommodationsAtEndOfPeriod.TripPurpose AS TripPurpose,
	|	AccommodationsAtEndOfPeriod.SourceOfBusiness AS SourceOfBusiness,
	|	AccommodationsAtEndOfPeriod.MarketingCode AS MarketingCode,
	|	AccommodationsAtEndOfPeriod.RoomQuota AS RoomQuota,
	|	AccommodationsAtEndOfPeriod.GuestGroup AS GuestGroup,
	|	AccommodationsAtEndOfPeriod.HotelProduct AS HotelProduct,
	|	AccommodationsAtEndOfPeriod.DiscountType AS DiscountType,
	|	AccommodationsAtEndOfPeriod.Discount AS Discount,
	|	AccommodationsAtEndOfPeriod.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	AccommodationsAtEndOfPeriod.Company AS Company,
	|	CAST(AccommodationsAtEndOfPeriod.Remarks AS STRING(1024)) AS Remarks,
	|	CAST(AccommodationsAtEndOfPeriod.Car AS STRING(1024)) AS Car,
	|	AccommodationsAtEndOfPeriod.Period AS Period,
	|	AccommodationChangeHistory.User AS Employee
	|INTO AccommodationsAtEndOfPeriod
	|FROM
	|	InformationRegister.AccommodationChangeHistory.SliceLast(&qPeriodTo, ) AS AccommodationsAtEndOfPeriod
	|		LEFT JOIN InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|		ON AccommodationsAtEndOfPeriod.Accommodation = AccommodationChangeHistory.Accommodation
	|			AND AccommodationsAtEndOfPeriod.Period = AccommodationChangeHistory.Period
	|		INNER JOIN AccommodationsAtBeginOfPeriod AS AccommodationsAtBeginOfPeriod
	|		ON AccommodationsAtEndOfPeriod.Accommodation = AccommodationsAtBeginOfPeriod.Accommodation
	|			AND AccommodationsAtEndOfPeriod.Room <> AccommodationsAtBeginOfPeriod.Room
	|WHERE
	|	AccommodationsAtEndOfPeriod.Hotel IN HIERARCHY(&qHotel)
	|	AND AccommodationsAtEndOfPeriod.CheckInDate < &qPeriodTo
	|	AND AccommodationsAtEndOfPeriod.CheckOutDate > &qPeriodFrom
	|	AND AccommodationsAtEndOfPeriod.Accommodation.AccommodationStatus.IsActive
	|	AND AccommodationsAtEndOfPeriod.Accommodation.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccommodationsMovedRoom.Accommodation AS Accommodation,
	|	AccommodationsMovedRoom.Hotel AS Hotel,
	|	AccommodationsMovedRoom.AccommodationStatus AS MovedToAccommodationStatus,
	|	AccommodationsMovedRoom.Room AS MovedToRoom,
	|	AccommodationsMovedRoom.RoomType AS MovedToRoomType,
	|	AccommodationsMovedRoom.CheckInDate AS MovedToCheckInDate,
	|	AccommodationsMovedRoom.Duration AS MovedToDuration,
	|	AccommodationsMovedRoom.CheckOutDate AS MovedToCheckOutDate,
	|	AccommodationsMovedRoom.AccommodationTemplate AS MovedToAccommodationTemplate,
	|	AccommodationsMovedRoom.NumberOfAdults AS MovedToNumberOfAdults,
	|	AccommodationsMovedRoom.NumberOfTeenagers AS MovedToNumberOfTeenagers,
	|	AccommodationsMovedRoom.NumberOfChildren AS MovedToNumberOfChildren,
	|	AccommodationsMovedRoom.NumberOfInfants AS MovedToNumberOfInfants,
	|	AccommodationsMovedRoom.AccommodationType AS MovedToAccommodationType,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(AccommodationsMovedRoom.NumberOfAdults, 0) + ISNULL(AccommodationsMovedRoom.NumberOfTeenagers, 0) + ISNULL(AccommodationsMovedRoom.NumberOfChildren, 0) + ISNULL(AccommodationsMovedRoom.NumberOfInfants, 0)
	|		ELSE AccommodationsMovedRoom.NumberOfPersons
	|	END AS MovedToNumberOfPersons,
	|	AccommodationsMovedRoom.Customer AS MovedToCustomer,
	|	AccommodationsMovedRoom.Contract AS MovedToContract,
	|	AccommodationsMovedRoom.ContactPerson AS MovedToContactPerson,
	|	AccommodationsMovedRoom.Agent AS MovedToAgent,
	|	AccommodationsMovedRoom.Guest AS MovedToGuest,
	|	AccommodationsMovedRoom.ClientType AS MovedToClientType,
	|	AccommodationsMovedRoom.RoomRate AS MovedToRoomRate,
	|	AccommodationsMovedRoom.TripPurpose AS MovedToTripPurpose,
	|	AccommodationsMovedRoom.SourceOfBusiness AS MovedToSourceOfBusiness,
	|	AccommodationsMovedRoom.MarketingCode AS MovedToMarketingCode,
	|	AccommodationsMovedRoom.RoomQuota AS MovedToRoomQuota,
	|	AccommodationsMovedRoom.GuestGroup AS MovedToGuestGroup,
	|	AccommodationsMovedRoom.HotelProduct AS MovedToHotelProduct,
	|	AccommodationsMovedRoom.DiscountType AS MovedToDiscountType,
	|	AccommodationsMovedRoom.Discount AS MovedToDiscount,
	|	AccommodationsMovedRoom.PlannedPaymentMethod AS MovedToPlannedPaymentMethod,
	|	AccommodationsMovedRoom.Company AS MovedToCompany,
	|	AccommodationsMovedRoom.Remarks AS MovedToRemarks,
	|	AccommodationsMovedRoom.Car AS MovedToCar,
	|	AccommodationsMovedRoom.Period AS Period,
	|	AccommodationsMovedRoom.Employee AS Employee,
	|	AccommodationsAtBeginOfPeriod.AccommodationStatus AS MovedFromAccommodationStatus,
	|	AccommodationsAtBeginOfPeriod.Room AS MovedFromRoom,
	|	AccommodationsAtBeginOfPeriod.RoomType AS MovedFromRoomType,
	|	AccommodationsAtBeginOfPeriod.CheckInDate AS MovedFromCheckInDate,
	|	AccommodationsAtBeginOfPeriod.Duration AS MovedFromDuration,
	|	AccommodationsAtBeginOfPeriod.CheckOutDate AS MovedFromCheckOutDate,
	|	AccommodationsAtBeginOfPeriod.AccommodationTemplate AS MovedFromAccommodationTemplate,
	|	AccommodationsAtBeginOfPeriod.NumberOfAdults AS MovedFromNumberOfAdults,
	|	AccommodationsAtBeginOfPeriod.NumberOfTeenagers AS MovedFromNumberOfTeenagers,
	|	AccommodationsAtBeginOfPeriod.NumberOfChildren AS MovedFromNumberOfChildren,
	|	AccommodationsAtBeginOfPeriod.NumberOfInfants AS MovedFromNumberOfInfants,
	|	AccommodationsAtBeginOfPeriod.AccommodationType AS MovedFromAccommodationType,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(AccommodationsAtBeginOfPeriod.NumberOfAdults, 0) + ISNULL(AccommodationsAtBeginOfPeriod.NumberOfTeenagers, 0) + ISNULL(AccommodationsAtBeginOfPeriod.NumberOfChildren, 0) + ISNULL(AccommodationsAtBeginOfPeriod.NumberOfInfants, 0)
	|		ELSE AccommodationsAtBeginOfPeriod.NumberOfPersons
	|	END AS MovedFromNumberOfPersons,
	|	AccommodationsAtBeginOfPeriod.Customer AS MovedFromCustomer,
	|	AccommodationsAtBeginOfPeriod.Contract AS MovedFromContract,
	|	AccommodationsAtBeginOfPeriod.ContactPerson AS MovedFromContactPerson,
	|	AccommodationsAtBeginOfPeriod.Agent AS MovedFromAgent,
	|	AccommodationsAtBeginOfPeriod.Guest AS MovedFromGuest,
	|	AccommodationsAtBeginOfPeriod.ClientType AS MovedFromClientType,
	|	AccommodationsAtBeginOfPeriod.RoomRate AS MovedFromRoomRate,
	|	AccommodationsAtBeginOfPeriod.TripPurpose AS MovedFromTripPurpose,
	|	AccommodationsAtBeginOfPeriod.SourceOfBusiness AS MovedFromSourceOfBusiness,
	|	AccommodationsAtBeginOfPeriod.MarketingCode AS MovedFromMarketingCode,
	|	AccommodationsAtBeginOfPeriod.RoomQuota AS MovedFromRoomQuota,
	|	AccommodationsAtBeginOfPeriod.GuestGroup AS MovedFromGuestGroup,
	|	AccommodationsAtBeginOfPeriod.HotelProduct AS MovedFromHotelProduct,
	|	AccommodationsAtBeginOfPeriod.DiscountType AS MovedFromDiscountType,
	|	AccommodationsAtBeginOfPeriod.Discount AS MovedFromDiscount,
	|	AccommodationsAtBeginOfPeriod.PlannedPaymentMethod AS MovedFromPlannedPaymentMethod,
	|	AccommodationsAtBeginOfPeriod.Company AS MovedFromCompany,
	|	AccommodationsAtBeginOfPeriod.Remarks AS MovedFromRemarks,
	|	AccommodationsAtBeginOfPeriod.Car AS MovedFromCar,
	|	1 AS MovedToCount
	|INTO AccommodationsMovedRoom
	|FROM
	|	AccommodationsAtEndOfPeriod AS AccommodationsMovedRoom
	|		LEFT JOIN AccommodationsAtBeginOfPeriod AS AccommodationsAtBeginOfPeriod
	|		ON AccommodationsMovedRoom.Accommodation = AccommodationsAtBeginOfPeriod.Accommodation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccommodationsMovedRoom.Period AS Period,
	|	AccommodationsMovedRoom.Employee AS Employee,
	|	AccommodationsMovedRoom.Accommodation AS Accommodation,
	|	AccommodationsMovedRoom.MovedFromRoom AS MovedFromRoom,
	|	AccommodationsMovedRoom.MovedFromRoomType AS MovedFromRoomType,
	|	AccommodationsMovedRoom.MovedToRoom AS MovedToRoom,
	|	AccommodationsMovedRoom.MovedToRoomType AS MovedToRoomType,
	|	AccommodationsMovedRoom.MovedToCheckInDate AS MovedToCheckInDate,
	|	AccommodationsMovedRoom.MovedToDuration AS MovedToDuration,
	|	AccommodationsMovedRoom.MovedToCheckOutDate AS MovedToCheckOutDate,
	|	AccommodationsMovedRoom.MovedToGuest AS MovedToGuest,
	|	AccommodationsMovedRoom.MovedToAccommodationTemplate AS MovedToAccommodationTemplate,
	|	AccommodationsMovedRoom.MovedToAccommodationType AS MovedToAccommodationType,
	|	AccommodationsMovedRoom.MovedToCount AS MovedToCount,
	|	AccommodationsMovedRoom.MovedToNumberOfPersons AS MovedToNumberOfPersons,
	|	AccommodationsMovedRoom.MovedToNumberOfAdults AS MovedToNumberOfAdults,
	|	AccommodationsMovedRoom.MovedToNumberOfTeenagers AS MovedToNumberOfTeenagers,
	|	AccommodationsMovedRoom.MovedToNumberOfChildren AS MovedToNumberOfChildren,
	|	AccommodationsMovedRoom.MovedToNumberOfInfants AS MovedToNumberOfInfants
	|{SELECT
	|	Period AS Period,
	|	Employee.* AS Employee,
	|	Accommodation.*,
	|	AccommodationsMovedRoom.Hotel.* AS Hotel,
	|	AccommodationsMovedRoom.MovedToAccommodationStatus.* AS MovedToAccommodationStatus,
	|	MovedToRoom.* AS MovedToRoom,
	|	MovedToRoomType.* AS MovedToRoomType,
	|	MovedToCheckInDate AS MovedToCheckInDate,
	|	MovedToDuration AS MovedToDuration,
	|	MovedToCheckOutDate AS MovedToCheckOutDate,
	|	MovedToAccommodationTemplate.* AS MovedToAccommodationTemplate,
	|	MovedToNumberOfAdults AS MovedToNumberOfAdults,
	|	MovedToNumberOfTeenagers AS MovedToNumberOfTeenagers,
	|	MovedToNumberOfChildren AS MovedToNumberOfChildren,
	|	MovedToNumberOfInfants AS MovedToNumberOfInfants,
	|	MovedToAccommodationType.* AS MovedToAccommodationType,
	|	MovedToNumberOfPersons AS MovedToNumberOfPersons,
	|	AccommodationsMovedRoom.MovedToCustomer.* AS MovedToCustomer,
	|	AccommodationsMovedRoom.MovedToContract.* AS MovedToContract,
	|	AccommodationsMovedRoom.MovedToContactPerson AS MovedToContactPerson,
	|	AccommodationsMovedRoom.MovedToAgent.* AS MovedToAgent,
	|	AccommodationsMovedRoom.MovedToGuest.* AS MovedToGuest,
	|	AccommodationsMovedRoom.MovedToClientType.* AS MovedToClientType,
	|	AccommodationsMovedRoom.MovedToRoomRate.* AS MovedToRoomRate,
	|	AccommodationsMovedRoom.MovedToTripPurpose.* AS MovedToTripPurpose,
	|	AccommodationsMovedRoom.MovedToSourceOfBusiness.* AS MovedToSourceOfBusiness,
	|	AccommodationsMovedRoom.MovedToMarketingCode.* AS MovedToMarketingCode,
	|	AccommodationsMovedRoom.MovedToRoomQuota.* AS MovedToRoomQuota,
	|	AccommodationsMovedRoom.MovedToGuestGroup.* AS MovedToGuestGroup,
	|	AccommodationsMovedRoom.MovedToHotelProduct.* AS MovedToHotelProduct,
	|	AccommodationsMovedRoom.MovedToDiscountType.* AS MovedToDiscountType,
	|	AccommodationsMovedRoom.MovedToDiscount AS MovedToDiscount,
	|	AccommodationsMovedRoom.MovedToPlannedPaymentMethod.* AS MovedToPlannedPaymentMethod,
	|	AccommodationsMovedRoom.MovedToCompany.* AS MovedToCompany,
	|	AccommodationsMovedRoom.MovedToRemarks AS MovedToRemarks,
	|	AccommodationsMovedRoom.MovedToCar AS MovedToCar,
	|	AccommodationsMovedRoom.MovedFromAccommodationStatus.* AS MovedFromAccommodationStatus,
	|	MovedFromRoom.* AS MovedFromRoom,
	|	MovedFromRoomType.* AS MovedFromRoomType,
	|	AccommodationsMovedRoom.MovedFromCheckInDate AS MovedFromCheckInDate,
	|	AccommodationsMovedRoom.MovedFromDuration AS MovedFromDuration,
	|	AccommodationsMovedRoom.MovedFromCheckOutDate AS MovedFromCheckOutDate,
	|	AccommodationsMovedRoom.MovedFromAccommodationTemplate.* AS MovedFromAccommodationTemplate,
	|	AccommodationsMovedRoom.MovedFromNumberOfAdults AS MovedFromNumberOfAdults,
	|	AccommodationsMovedRoom.MovedFromNumberOfTeenagers AS MovedFromNumberOfTeenagers,
	|	AccommodationsMovedRoom.MovedFromNumberOfChildren AS MovedFromNumberOfChildren,
	|	AccommodationsMovedRoom.MovedFromNumberOfInfants AS MovedFromNumberOfInfants,
	|	AccommodationsMovedRoom.MovedFromAccommodationType.* AS MovedFromAccommodationType,
	|	AccommodationsMovedRoom.MovedFromNumberOfPersons AS MovedFromNumberOfPersons,
	|	AccommodationsMovedRoom.MovedFromCustomer.* AS MovedFromCustomer,
	|	AccommodationsMovedRoom.MovedFromContract.* AS MovedFromContract,
	|	AccommodationsMovedRoom.MovedFromContactPerson AS MovedFromContactPerson,
	|	AccommodationsMovedRoom.MovedFromAgent.* AS MovedFromAgent,
	|	AccommodationsMovedRoom.MovedFromGuest.* AS MovedFromGuest,
	|	AccommodationsMovedRoom.MovedFromClientType.* AS MovedFromClientType,
	|	AccommodationsMovedRoom.MovedFromRoomRate.* AS MovedFromRoomRate,
	|	AccommodationsMovedRoom.MovedFromTripPurpose.* AS MovedFromTripPurpose,
	|	AccommodationsMovedRoom.MovedFromSourceOfBusiness.* AS MovedFromSourceOfBusiness,
	|	AccommodationsMovedRoom.MovedFromMarketingCode.* AS MovedFromMarketingCode,
	|	AccommodationsMovedRoom.MovedFromRoomQuota.* AS MovedFromRoomQuota,
	|	AccommodationsMovedRoom.MovedFromGuestGroup.* AS MovedFromGuestGroup,
	|	AccommodationsMovedRoom.MovedFromHotelProduct.* AS MovedFromHotelProduct,
	|	AccommodationsMovedRoom.MovedFromDiscountType.* AS MovedFromDiscountType,
	|	AccommodationsMovedRoom.MovedFromDiscount AS MovedFromDiscount,
	|	AccommodationsMovedRoom.MovedFromPlannedPaymentMethod.* AS MovedFromPlannedPaymentMethod,
	|	AccommodationsMovedRoom.MovedFromCompany.* AS MovedFromCompany,
	|	AccommodationsMovedRoom.MovedFromRemarks AS MovedFromRemarks,
	|	AccommodationsMovedRoom.MovedFromCar AS MovedFromCar,
	|	MovedToCount}
	|FROM
	|	AccommodationsMovedRoom AS AccommodationsMovedRoom
	|WHERE
	|	AccommodationsMovedRoom.Hotel IN HIERARCHY(&qHotel)
	|	AND AccommodationsMovedRoom.MovedFromRoom IN HIERARCHY(&qMovedFromRoom)
	|	AND AccommodationsMovedRoom.MovedFromRoomType IN HIERARCHY(&qMovedFromRoomType)
	|	AND AccommodationsMovedRoom.MovedToRoom IN HIERARCHY(&qMovedToRoom)
	|	AND AccommodationsMovedRoom.MovedToRoomType IN HIERARCHY(&qMovedToRoomType)
	|	AND AccommodationsMovedRoom.Employee IN HIERARCHY(&qEmployee)
	|	AND (NOT &qShowMainRoomGuestsOnly
	|			OR &qShowMainRoomGuestsOnly
	|				AND (AccommodationsMovedRoom.MovedToAccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
	|					OR AccommodationsMovedRoom.MovedToAccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds)))
	|{WHERE
	|	AccommodationsMovedRoom.Period AS Period,
	|	AccommodationsMovedRoom.Employee.* AS Employee,
	|	AccommodationsMovedRoom.Accommodation.*,
	|	AccommodationsMovedRoom.Hotel.* AS Hotel,
	|	AccommodationsMovedRoom.MovedToAccommodationStatus.* AS MovedToAccommodationStatus,
	|	AccommodationsMovedRoom.MovedToRoom.* AS MovedToRoom,
	|	AccommodationsMovedRoom.MovedToRoomType.* AS MovedToRoomType,
	|	AccommodationsMovedRoom.MovedToCheckInDate AS MovedToCheckInDate,
	|	AccommodationsMovedRoom.MovedToDuration AS MovedToDuration,
	|	AccommodationsMovedRoom.MovedToCheckOutDate AS MovedToCheckOutDate,
	|	AccommodationsMovedRoom.MovedToAccommodationTemplate.* AS MovedToAccommodationTemplate,
	|	AccommodationsMovedRoom.MovedToNumberOfAdults AS MovedToNumberOfAdults,
	|	AccommodationsMovedRoom.MovedToNumberOfTeenagers AS MovedToNumberOfTeenagers,
	|	AccommodationsMovedRoom.MovedToNumberOfChildren AS MovedToNumberOfChildren,
	|	AccommodationsMovedRoom.MovedToNumberOfInfants AS MovedToNumberOfInfants,
	|	AccommodationsMovedRoom.MovedToAccommodationType.* AS MovedToAccommodationType,
	|	AccommodationsMovedRoom.MovedToNumberOfPersons AS MovedToNumberOfPersons,
	|	AccommodationsMovedRoom.MovedToCustomer.* AS MovedToCustomer,
	|	AccommodationsMovedRoom.MovedToContract.* AS MovedToContract,
	|	AccommodationsMovedRoom.MovedToContactPerson AS MovedToContactPerson,
	|	AccommodationsMovedRoom.MovedToAgent.* AS MovedToAgent,
	|	AccommodationsMovedRoom.MovedToGuest.* AS MovedToGuest,
	|	AccommodationsMovedRoom.MovedToClientType.* AS MovedToClientType,
	|	AccommodationsMovedRoom.MovedToRoomRate.* AS MovedToRoomRate,
	|	AccommodationsMovedRoom.MovedToTripPurpose.* AS MovedToTripPurpose,
	|	AccommodationsMovedRoom.MovedToSourceOfBusiness.* AS MovedToSourceOfBusiness,
	|	AccommodationsMovedRoom.MovedToMarketingCode.* AS MovedToMarketingCode,
	|	AccommodationsMovedRoom.MovedToRoomQuota.* AS MovedToRoomQuota,
	|	AccommodationsMovedRoom.MovedToGuestGroup.* AS MovedToGuestGroup,
	|	AccommodationsMovedRoom.MovedToHotelProduct.* AS MovedToHotelProduct,
	|	AccommodationsMovedRoom.MovedToDiscountType.* AS MovedToDiscountType,
	|	AccommodationsMovedRoom.MovedToDiscount AS MovedToDiscount,
	|	AccommodationsMovedRoom.MovedToPlannedPaymentMethod.* AS MovedToPlannedPaymentMethod,
	|	AccommodationsMovedRoom.MovedToCompany.* AS MovedToCompany,
	|	AccommodationsMovedRoom.MovedToRemarks AS MovedToRemarks,
	|	AccommodationsMovedRoom.MovedToCar AS MovedToCar,
	|	AccommodationsMovedRoom.MovedFromAccommodationStatus.* AS MovedFromAccommodationStatus,
	|	AccommodationsMovedRoom.MovedFromRoom.* AS MovedFromRoom,
	|	AccommodationsMovedRoom.MovedFromRoomType.* AS MovedFromRoomType,
	|	AccommodationsMovedRoom.MovedFromCheckInDate AS MovedFromCheckInDate,
	|	AccommodationsMovedRoom.MovedFromDuration AS MovedFromDuration,
	|	AccommodationsMovedRoom.MovedFromCheckOutDate AS MovedFromCheckOutDate,
	|	AccommodationsMovedRoom.MovedFromAccommodationTemplate.* AS MovedFromAccommodationTemplate,
	|	AccommodationsMovedRoom.MovedFromNumberOfAdults AS MovedFromNumberOfAdults,
	|	AccommodationsMovedRoom.MovedFromNumberOfTeenagers AS MovedFromNumberOfTeenagers,
	|	AccommodationsMovedRoom.MovedFromNumberOfChildren AS MovedFromNumberOfChildren,
	|	AccommodationsMovedRoom.MovedFromNumberOfInfants AS MovedFromNumberOfInfants,
	|	AccommodationsMovedRoom.MovedFromAccommodationType.* AS MovedFromAccommodationType,
	|	AccommodationsMovedRoom.MovedFromNumberOfPersons AS MovedFromNumberOfPersons,
	|	AccommodationsMovedRoom.MovedFromCustomer.* AS MovedFromCustomer,
	|	AccommodationsMovedRoom.MovedFromContract.* AS MovedFromContract,
	|	AccommodationsMovedRoom.MovedFromContactPerson AS MovedFromContactPerson,
	|	AccommodationsMovedRoom.MovedFromAgent.* AS MovedFromAgent,
	|	AccommodationsMovedRoom.MovedFromGuest.* AS MovedFromGuest,
	|	AccommodationsMovedRoom.MovedFromClientType.* AS MovedFromClientType,
	|	AccommodationsMovedRoom.MovedFromRoomRate.* AS MovedFromRoomRate,
	|	AccommodationsMovedRoom.MovedFromTripPurpose.* AS MovedFromTripPurpose,
	|	AccommodationsMovedRoom.MovedFromSourceOfBusiness.* AS MovedFromSourceOfBusiness,
	|	AccommodationsMovedRoom.MovedFromMarketingCode.* AS MovedFromMarketingCode,
	|	AccommodationsMovedRoom.MovedFromRoomQuota.* AS MovedFromRoomQuota,
	|	AccommodationsMovedRoom.MovedFromGuestGroup.* AS MovedFromGuestGroup,
	|	AccommodationsMovedRoom.MovedFromHotelProduct.* AS MovedFromHotelProduct,
	|	AccommodationsMovedRoom.MovedFromDiscountType.* AS MovedFromDiscountType,
	|	AccommodationsMovedRoom.MovedFromDiscount AS MovedFromDiscount,
	|	AccommodationsMovedRoom.MovedFromPlannedPaymentMethod.* AS MovedFromPlannedPaymentMethod,
	|	AccommodationsMovedRoom.MovedFromCompany.* AS MovedFromCompany,
	|	AccommodationsMovedRoom.MovedFromRemarks AS MovedFromRemarks,
	|	AccommodationsMovedRoom.MovedFromCar AS MovedFromCar}
	|
	|ORDER BY
	|	AccommodationsMovedRoom.Hotel,
	|	AccommodationsMovedRoom.MovedToRoom,
	|	AccommodationsMovedRoom.Period
	|{ORDER BY
	|	Period AS Period,
	|	Employee.* AS Employee,
	|	Accommodation.*,
	|	AccommodationsMovedRoom.Hotel.* AS Hotel,
	|	AccommodationsMovedRoom.MovedToAccommodationStatus.* AS MovedToAccommodationStatus,
	|	MovedToRoom.* AS MovedToRoom,
	|	MovedToRoomType.* AS MovedToRoomType,
	|	MovedToCheckInDate AS MovedToCheckInDate,
	|	MovedToDuration AS MovedToDuration,
	|	MovedToCheckOutDate AS MovedToCheckOutDate,
	|	MovedToAccommodationTemplate.* AS MovedToAccommodationTemplate,
	|	MovedToNumberOfAdults AS MovedToNumberOfAdults,
	|	MovedToNumberOfTeenagers AS MovedToNumberOfTeenagers,
	|	MovedToNumberOfChildren AS MovedToNumberOfChildren,
	|	MovedToNumberOfInfants AS MovedToNumberOfInfants,
	|	MovedToAccommodationType.* AS MovedToAccommodationType,
	|	MovedToNumberOfPersons AS MovedToNumberOfPersons,
	|	AccommodationsMovedRoom.MovedToCustomer.* AS MovedToCustomer,
	|	AccommodationsMovedRoom.MovedToContract.* AS MovedToContract,
	|	AccommodationsMovedRoom.MovedToContactPerson AS MovedToContactPerson,
	|	AccommodationsMovedRoom.MovedToAgent.* AS MovedToAgent,
	|	AccommodationsMovedRoom.MovedToGuest.* AS MovedToGuest,
	|	AccommodationsMovedRoom.MovedToClientType.* AS MovedToClientType,
	|	AccommodationsMovedRoom.MovedToRoomRate.* AS MovedToRoomRate,
	|	AccommodationsMovedRoom.MovedToTripPurpose.* AS MovedToTripPurpose,
	|	AccommodationsMovedRoom.MovedToSourceOfBusiness.* AS MovedToSourceOfBusiness,
	|	AccommodationsMovedRoom.MovedToMarketingCode.* AS MovedToMarketingCode,
	|	AccommodationsMovedRoom.MovedToRoomQuota.* AS MovedToRoomQuota,
	|	AccommodationsMovedRoom.MovedToGuestGroup.* AS MovedToGuestGroup,
	|	AccommodationsMovedRoom.MovedToHotelProduct.* AS MovedToHotelProduct,
	|	AccommodationsMovedRoom.MovedToDiscountType.* AS MovedToDiscountType,
	|	AccommodationsMovedRoom.MovedToDiscount AS MovedToDiscount,
	|	AccommodationsMovedRoom.MovedToPlannedPaymentMethod.* AS MovedToPlannedPaymentMethod,
	|	AccommodationsMovedRoom.MovedToCompany.* AS MovedToCompany,
	|	AccommodationsMovedRoom.MovedToRemarks AS MovedToRemarks,
	|	AccommodationsMovedRoom.MovedToCar AS MovedToCar,
	|	AccommodationsMovedRoom.MovedFromAccommodationStatus.* AS MovedFromAccommodationStatus,
	|	MovedFromRoom.* AS MovedFromRoom,
	|	MovedFromRoomType.* AS MovedFromRoomType,
	|	AccommodationsMovedRoom.MovedFromCheckInDate AS MovedFromCheckInDate,
	|	AccommodationsMovedRoom.MovedFromDuration AS MovedFromDuration,
	|	AccommodationsMovedRoom.MovedFromCheckOutDate AS MovedFromCheckOutDate,
	|	AccommodationsMovedRoom.MovedFromAccommodationTemplate.* AS MovedFromAccommodationTemplate,
	|	AccommodationsMovedRoom.MovedFromNumberOfAdults AS MovedFromNumberOfAdults,
	|	AccommodationsMovedRoom.MovedFromNumberOfTeenagers AS MovedFromNumberOfTeenagers,
	|	AccommodationsMovedRoom.MovedFromNumberOfChildren AS MovedFromNumberOfChildren,
	|	AccommodationsMovedRoom.MovedFromNumberOfInfants AS MovedFromNumberOfInfants,
	|	AccommodationsMovedRoom.MovedFromAccommodationType.* AS MovedFromAccommodationType,
	|	AccommodationsMovedRoom.MovedFromNumberOfPersons AS MovedFromNumberOfPersons,
	|	AccommodationsMovedRoom.MovedFromCustomer.* AS MovedFromCustomer,
	|	AccommodationsMovedRoom.MovedFromContract.* AS MovedFromContract,
	|	AccommodationsMovedRoom.MovedFromContactPerson AS MovedFromContactPerson,
	|	AccommodationsMovedRoom.MovedFromAgent.* AS MovedFromAgent,
	|	AccommodationsMovedRoom.MovedFromGuest.* AS MovedFromGuest,
	|	AccommodationsMovedRoom.MovedFromClientType.* AS MovedFromClientType,
	|	AccommodationsMovedRoom.MovedFromRoomRate.* AS MovedFromRoomRate,
	|	AccommodationsMovedRoom.MovedFromTripPurpose.* AS MovedFromTripPurpose,
	|	AccommodationsMovedRoom.MovedFromSourceOfBusiness.* AS MovedFromSourceOfBusiness,
	|	AccommodationsMovedRoom.MovedFromMarketingCode.* AS MovedFromMarketingCode,
	|	AccommodationsMovedRoom.MovedFromRoomQuota.* AS MovedFromRoomQuota,
	|	AccommodationsMovedRoom.MovedFromGuestGroup.* AS MovedFromGuestGroup,
	|	AccommodationsMovedRoom.MovedFromHotelProduct.* AS MovedFromHotelProduct,
	|	AccommodationsMovedRoom.MovedFromDiscountType.* AS MovedFromDiscountType,
	|	AccommodationsMovedRoom.MovedFromDiscount AS MovedFromDiscount,
	|	AccommodationsMovedRoom.MovedFromPlannedPaymentMethod.* AS MovedFromPlannedPaymentMethod,
	|	AccommodationsMovedRoom.MovedFromCompany.* AS MovedFromCompany,
	|	AccommodationsMovedRoom.MovedFromRemarks AS MovedFromRemarks,
	|	AccommodationsMovedRoom.MovedFromCar AS MovedFromCar}
	|TOTALS
	|	SUM(MovedToCount),
	|	SUM(MovedToNumberOfPersons),
	|	SUM(MovedToNumberOfAdults),
	|	SUM(MovedToNumberOfTeenagers),
	|	SUM(MovedToNumberOfChildren),
	|	SUM(MovedToNumberOfInfants)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Period AS Period,
	|	Employee.* AS Employee,
	|	Accommodation.*,
	|	AccommodationsMovedRoom.Hotel.* AS Hotel,
	|	AccommodationsMovedRoom.MovedToAccommodationStatus.* AS MovedToAccommodationStatus,
	|	MovedToRoom.* AS MovedToRoom,
	|	MovedToRoomType.* AS MovedToRoomType,
	|	MovedToCheckInDate AS MovedToCheckInDate,
	|	MovedToDuration AS MovedToDuration,
	|	MovedToCheckOutDate AS MovedToCheckOutDate,
	|	MovedToAccommodationTemplate.* AS MovedToAccommodationTemplate,
	|	MovedToNumberOfAdults AS MovedToNumberOfAdults,
	|	MovedToNumberOfTeenagers AS MovedToNumberOfTeenagers,
	|	MovedToNumberOfChildren AS MovedToNumberOfChildren,
	|	MovedToNumberOfInfants AS MovedToNumberOfInfants,
	|	MovedToAccommodationType.* AS MovedToAccommodationType,
	|	MovedToNumberOfPersons AS MovedToNumberOfPersons,
	|	AccommodationsMovedRoom.MovedToCustomer.* AS MovedToCustomer,
	|	AccommodationsMovedRoom.MovedToContract.* AS MovedToContract,
	|	AccommodationsMovedRoom.MovedToContactPerson AS MovedToContactPerson,
	|	AccommodationsMovedRoom.MovedToAgent.* AS MovedToAgent,
	|	AccommodationsMovedRoom.MovedToGuest.* AS MovedToGuest,
	|	AccommodationsMovedRoom.MovedToClientType.* AS MovedToClientType,
	|	AccommodationsMovedRoom.MovedToRoomRate.* AS MovedToRoomRate,
	|	AccommodationsMovedRoom.MovedToTripPurpose.* AS MovedToTripPurpose,
	|	AccommodationsMovedRoom.MovedToSourceOfBusiness.* AS MovedToSourceOfBusiness,
	|	AccommodationsMovedRoom.MovedToMarketingCode.* AS MovedToMarketingCode,
	|	AccommodationsMovedRoom.MovedToRoomQuota.* AS MovedToRoomQuota,
	|	AccommodationsMovedRoom.MovedToGuestGroup.* AS MovedToGuestGroup,
	|	AccommodationsMovedRoom.MovedToHotelProduct.* AS MovedToHotelProduct,
	|	AccommodationsMovedRoom.MovedToDiscountType.* AS MovedToDiscountType,
	|	AccommodationsMovedRoom.MovedToDiscount AS MovedToDiscount,
	|	AccommodationsMovedRoom.MovedToPlannedPaymentMethod.* AS MovedToPlannedPaymentMethod,
	|	AccommodationsMovedRoom.MovedToCompany.* AS MovedToCompany,
	|	AccommodationsMovedRoom.MovedFromAccommodationStatus.* AS MovedFromAccommodationStatus,
	|	MovedFromRoom.* AS MovedFromRoom,
	|	MovedFromRoomType.* AS MovedFromRoomType,
	|	AccommodationsMovedRoom.MovedFromCheckInDate AS MovedFromCheckInDate,
	|	AccommodationsMovedRoom.MovedFromDuration AS MovedFromDuration,
	|	AccommodationsMovedRoom.MovedFromCheckOutDate AS MovedFromCheckOutDate,
	|	AccommodationsMovedRoom.MovedFromAccommodationTemplate.* AS MovedFromAccommodationTemplate,
	|	AccommodationsMovedRoom.MovedFromNumberOfAdults AS MovedFromNumberOfAdults,
	|	AccommodationsMovedRoom.MovedFromNumberOfTeenagers AS MovedFromNumberOfTeenagers,
	|	AccommodationsMovedRoom.MovedFromNumberOfChildren AS MovedFromNumberOfChildren,
	|	AccommodationsMovedRoom.MovedFromNumberOfInfants AS MovedFromNumberOfInfants,
	|	AccommodationsMovedRoom.MovedFromAccommodationType.* AS MovedFromAccommodationType,
	|	AccommodationsMovedRoom.MovedFromNumberOfPersons AS MovedFromNumberOfPersons,
	|	AccommodationsMovedRoom.MovedFromCustomer.* AS MovedFromCustomer,
	|	AccommodationsMovedRoom.MovedFromContract.* AS MovedFromContract,
	|	AccommodationsMovedRoom.MovedFromContactPerson AS MovedFromContactPerson,
	|	AccommodationsMovedRoom.MovedFromAgent.* AS MovedFromAgent,
	|	AccommodationsMovedRoom.MovedFromGuest.* AS MovedFromGuest,
	|	AccommodationsMovedRoom.MovedFromClientType.* AS MovedFromClientType,
	|	AccommodationsMovedRoom.MovedFromRoomRate.* AS MovedFromRoomRate,
	|	AccommodationsMovedRoom.MovedFromTripPurpose.* AS MovedFromTripPurpose,
	|	AccommodationsMovedRoom.MovedFromSourceOfBusiness.* AS MovedFromSourceOfBusiness,
	|	AccommodationsMovedRoom.MovedFromMarketingCode.* AS MovedFromMarketingCode,
	|	AccommodationsMovedRoom.MovedFromRoomQuota.* AS MovedFromRoomQuota,
	|	AccommodationsMovedRoom.MovedFromGuestGroup.* AS MovedFromGuestGroup,
	|	AccommodationsMovedRoom.MovedFromHotelProduct.* AS MovedFromHotelProduct,
	|	AccommodationsMovedRoom.MovedFromDiscountType.* AS MovedFromDiscountType,
	|	AccommodationsMovedRoom.MovedFromDiscount AS MovedFromDiscount,
	|	AccommodationsMovedRoom.MovedFromPlannedPaymentMethod.* AS MovedFromPlannedPaymentMethod,
	|	AccommodationsMovedRoom.MovedFromCompany.* AS MovedFromCompany}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Сhange room in accommodations audit';RU='Аудит замен номеров комнат в размещениях';de='Audit des Zimmernummernwechsels in Unterbringungen'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

#EndRegion
