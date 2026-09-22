
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
		vParamPresentation = vParamPresentation + NStr("en = 'Report period is not set'; 
													   |de = 'Berichtszeitraum nicht festgelegt'; 
													   |ru = 'Период отчета не установлен'") 
							 + ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '")  
		                     + Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'")  
		                     + ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '")  
		                     + Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") 
		                     + ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '")  
		                     + Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") 
							 + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode())  
		                     + ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en = 'Period is wrong!'; 
													   |de = 'Der Zeitraum wurde falsch eingetragen!'; 
													   |ru = 'Неправильно задан период!'")  
		                     + ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Room) Then
		If Not Room.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en = 'Room '; de = 'Zimmer '; ru = 'Номер '")  
			                     + TrimAll(Room.Description) + ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en = 'Rooms folder '; de = 'Gruppe Zimmer '; ru = 'Группа номеров '")  
			                     + TrimAll(Room.Description) + ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en = 'Room type '; de = 'Zimmertyp '; ru = 'Тип номера '")  
			                     + TrimAll(RoomType.Description) + ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en = 'Room types folder '; de = 'Gruppe Zimmertypen '; ru = 'Группа типов номеров '")  
			                     + TrimAll(RoomType.Description) + ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en = 'Employee '; de = 'Mitarbeiter '; ru = 'Сотрудник '")  
			                     + TrimAll(Employee) + ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Gruppe Mitarbeiter '")  
			                     + TrimAll(Employee) + ";" + Chars.LF;
		EndIf;
	EndIf;
	If ShowMainRoomGuestsOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Main room guests only';ru='Только основные гости номера';de='Nur Hauptgäste des Zimmers'") + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Hotel) Then   
		vHotelPresentation = Catalogs.Hotels.pmGetHotelPrintName(Hotel, SessionParameters.CurrentLanguage); 
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + vHotelPresentation + ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en = 'Hotels folder '; de = 'Gruppe Hotels '; ru = 'Группа гостиниц '") + vHotelPresentation + ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", ShowMainRoomGuestsOnly);

	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	AccommodationChangeHistorySliceLast.Accommodation AS Accommodation,
	|	AccommodationChangeHistorySliceLast.RoomType AS RoomType,
	|	AccommodationChangeHistorySliceFirst.RoomType AS RoomTypeBefore,
	|	AccommodationChangeHistorySliceLast.RoomTypeUpgrade AS RoomTypeForPrices,
	|	AccommodationChangeHistorySliceFirst.RoomTypeUpgrade AS RoomTypeForPricesBefore,
	|	MIN(AccommodationChangeHistory.Period) AS UpgradeTime
	|INTO AccommodationUpgrades
	|FROM
	|	InformationRegister.AccommodationChangeHistory.SliceLast(&qPeriodTo, ) AS AccommodationChangeHistorySliceLast
	|		INNER JOIN InformationRegister.AccommodationChangeHistory.SliceFirst(&qPeriodFrom, ) AS AccommodationChangeHistorySliceFirst
	|		ON (AccommodationChangeHistorySliceFirst.Accommodation = AccommodationChangeHistorySliceLast.Accommodation)
	|			AND (AccommodationChangeHistorySliceFirst.RoomTypeUpgrade <> AccommodationChangeHistorySliceLast.RoomTypeUpgrade)
	|			AND (AccommodationChangeHistorySliceLast.RoomTypeUpgrade <> VALUE(Catalog.RoomTypes.EmptyRef))
	|		INNER JOIN InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|		ON AccommodationChangeHistorySliceLast.Accommodation = AccommodationChangeHistory.Accommodation
	|			AND AccommodationChangeHistorySliceLast.RoomTypeUpgrade = AccommodationChangeHistory.RoomTypeUpgrade
	|			AND (AccommodationChangeHistory.Period >= &qPeriodFrom)
	|			AND (AccommodationChangeHistory.Period < &qPeriodTo)
	|WHERE
	|	AccommodationChangeHistorySliceLast.Hotel IN HIERARCHY(&qHotel)
	|	AND AccommodationChangeHistorySliceLast.Room IN HIERARCHY(&qRoom)
	|	AND AccommodationChangeHistorySliceLast.RoomType IN HIERARCHY(&qRoomType)
	|
	|GROUP BY
	|	AccommodationChangeHistorySliceLast.Accommodation,
	|	AccommodationChangeHistorySliceLast.RoomType,
	|	AccommodationChangeHistorySliceFirst.RoomType,
	|	AccommodationChangeHistorySliceLast.RoomTypeUpgrade,
	|	AccommodationChangeHistorySliceFirst.RoomTypeUpgrade
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReservationChangeHistorySliceLast.Reservation AS Reservation,
	|	ReservationChangeHistorySliceLast.RoomType AS RoomType,
	|	ReservationChangeHistorySliceFirst.RoomType AS RoomTypeBefore,
	|	ReservationChangeHistorySliceLast.RoomTypeUpgrade AS RoomTypeForPrices,
	|	ReservationChangeHistorySliceFirst.RoomTypeUpgrade AS RoomTypeForPricesBefore,
	|	MIN(ReservationChangeHistory.Period) AS UpgradeTime
	|INTO ReservationUpgrades
	|FROM
	|	InformationRegister.ReservationChangeHistory.SliceLast(&qPeriodTo, ) AS ReservationChangeHistorySliceLast
	|		INNER JOIN InformationRegister.ReservationChangeHistory.SliceFirst(&qPeriodFrom, ) AS ReservationChangeHistorySliceFirst
	|		ON (ReservationChangeHistorySliceFirst.Reservation = ReservationChangeHistorySliceLast.Reservation)
	|			AND (ReservationChangeHistorySliceFirst.RoomTypeUpgrade <> ReservationChangeHistorySliceLast.RoomTypeUpgrade)
	|			AND (ReservationChangeHistorySliceLast.RoomTypeUpgrade <> VALUE(Catalog.RoomTypes.EmptyRef))
	|		INNER JOIN InformationRegister.ReservationChangeHistory AS ReservationChangeHistory
	|		ON ReservationChangeHistorySliceLast.Reservation = ReservationChangeHistory.Reservation
	|			AND ReservationChangeHistorySliceLast.RoomTypeUpgrade = ReservationChangeHistory.RoomTypeUpgrade
	|			AND (ReservationChangeHistory.Period >= &qPeriodFrom)
	|			AND (ReservationChangeHistory.Period < &qPeriodTo)
	|WHERE
	|	ReservationChangeHistorySliceLast.Hotel IN HIERARCHY(&qHotel)
	|	AND (ReservationChangeHistorySliceLast.Room IN HIERARCHY (&qRoom)
	|			OR &qRoom = VALUE(Catalog.Rooms.EmptyRef))
	|	AND ReservationChangeHistorySliceLast.RoomType IN HIERARCHY(&qRoomType)
	|
	|GROUP BY
	|	ReservationChangeHistorySliceLast.Reservation,
	|	ReservationChangeHistorySliceLast.RoomType,
	|	ReservationChangeHistorySliceFirst.RoomType,
	|	ReservationChangeHistorySliceLast.RoomTypeUpgrade,
	|	ReservationChangeHistorySliceFirst.RoomTypeUpgrade
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpgradedDocuments.UpgradeAuthor AS UpgradeAuthor,
	|	UpgradedDocuments.UpgradeTime AS UpgradeTime,
	|	UpgradedDocuments.Status AS Status,
	|	UpgradedDocuments.Reservation AS Reservation,
	|	UpgradedDocuments.GuestGroup AS GuestGroup,
	|	UpgradedDocuments.Customer AS Customer,
	|	UpgradedDocuments.Guest AS Guest,
	|	UpgradedDocuments.CheckInDate AS CheckInDate,
	|	UpgradedDocuments.Duration AS Duration,
	|	UpgradedDocuments.CheckOutDate AS CheckOutDate,
	|	UpgradedDocuments.AccommodationTemplate AS AccommodationTemplate,
	|	UpgradedDocuments.NumberOfAdults AS NumberOfAdults,
	|	UpgradedDocuments.NumberOfTeenagers AS NumberOfTeenagers,
	|	UpgradedDocuments.NumberOfChildren AS NumberOfChildren,
	|	UpgradedDocuments.NumberOfInfants AS NumberOfInfants,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN UpgradedDocuments.NumberOfAdults + UpgradedDocuments.NumberOfTeenagers + UpgradedDocuments.NumberOfChildren + UpgradedDocuments.NumberOfInfants
	|		ELSE UpgradedDocuments.NumberOfPersons
	|	END AS NumberOfPersons,
	|	UpgradedDocuments.AccommodationType AS AccommodationType,
	|	UpgradedDocuments.Room AS Room,
	|	UpgradedDocuments.RoomType AS RoomType,
	|	UpgradedDocuments.RoomTypeForPrices AS RoomTypeForPrices,
	|	UpgradedDocuments.RoomRate AS RoomRate,
	|	CASE
	|		WHEN UpgradedDocuments.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
	|				OR UpgradedDocuments.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds)
	|			THEN UpgradedDocuments.PriceChangeReason
	|		ELSE """"
	|	END AS PriceChangeReason,
	|	CASE
	|		WHEN UpgradedDocuments.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
	|				OR UpgradedDocuments.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds)
	|			THEN 1
	|		ELSE 0
	|	END AS UpgradesCount
	|{SELECT
	|	UpgradeAuthor.* AS UpgradeAuthor,
	|	(BEGINOFPERIOD(UpgradedDocuments.UpgradeTime, DAY)) AS UpgradeDate,
	|	UpgradeTime AS UpgradeTime,
	|	Status.*,
	|	Reservation.*,
	|	GuestGroup.*,
	|	Customer.*,
	|	Guest.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	AccommodationTemplate.*,
	|	NumberOfAdults AS NumberOfAdults,
	|	NumberOfTeenagers AS NumberOfTeenagers,
	|	NumberOfChildren AS NumberOfChildren,
	|	NumberOfInfants AS NumberOfInfants,
	|	AccommodationType.*,
	|	Room.*,
	|	RoomType.* AS RoomType,
	|	RoomTypeForPrices.* AS RoomTypeForPrices,
	|	RoomRate.*,
	|	UpgradesCount,
	|	UpgradedDocuments.RoomTypeBefore.* AS RoomTypeBefore,
	|	UpgradedDocuments.RoomTypeForPricesBefore.* AS RoomTypeForPricesBefore,
	|	NumberOfPersons AS NumberOfPersons,
	|	UpgradedDocuments.Contract.* AS Contract,
	|	UpgradedDocuments.ContactPerson AS ContactPerson,
	|	UpgradedDocuments.Agent.* AS Agent,
	|	UpgradedDocuments.ClientType.* AS ClientType,
	|	UpgradedDocuments.TripPurpose.* AS TripPurpose,
	|	UpgradedDocuments.SourceOfBusiness.* AS SourceOfBusiness,
	|	UpgradedDocuments.MarketingCode.* AS MarketingCode,
	|	UpgradedDocuments.RoomQuota.* AS RoomQuota,
	|	UpgradedDocuments.HotelProduct.* AS HotelProduct,
	|	UpgradedDocuments.DiscountType.* AS DiscountType,
	|	UpgradedDocuments.Discount AS Discount,
	|	UpgradedDocuments.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	UpgradedDocuments.Company.* AS Company,
	|	UpgradedDocuments.Hotel.* AS Hotel,
	|	PriceChangeReason AS PriceChangeReason,
	|	UpgradedDocuments.Remarks AS Remarks,
	|	UpgradedDocuments.Car AS Car}
	|FROM
	|	(SELECT
	|		AllUpgrades.RoomType AS RoomType,
	|		AllUpgrades.RoomTypeBefore AS RoomTypeBefore,
	|		AllUpgrades.RoomTypeForPrices AS RoomTypeForPrices,
	|		AllUpgrades.RoomTypeForPricesBefore AS RoomTypeForPricesBefore,
	|		AllUpgrades.UpgradeAuthor AS UpgradeAuthor,
	|		AllUpgrades.UpgradeTime AS UpgradeTime,
	|		AllUpgrades.Status AS Status,
	|		AllUpgrades.Doc AS Reservation,
	|		AllUpgrades.Doc.CheckInDate AS CheckInDate,
	|		AllUpgrades.Doc.Duration AS Duration,
	|		AllUpgrades.Doc.CheckOutDate AS CheckOutDate,
	|		AllUpgrades.Doc.Room AS Room,
	|		AllUpgrades.Doc.Guest AS Guest,
	|		AllUpgrades.Doc.GuestGroup AS GuestGroup,
	|		AllUpgrades.Doc.RoomRate AS RoomRate,
	|		AllUpgrades.Doc.AccommodationTemplate AS AccommodationTemplate,
	|		AllUpgrades.Doc.AccommodationType AS AccommodationType,
	|		AllUpgrades.Doc.NumberOfPersons AS NumberOfPersons,
	|		AllUpgrades.Doc.NumberOfAdults AS NumberOfAdults,
	|		AllUpgrades.Doc.NumberOfTeenagers AS NumberOfTeenagers,
	|		AllUpgrades.Doc.NumberOfChildren AS NumberOfChildren,
	|		AllUpgrades.Doc.NumberOfInfants AS NumberOfInfants,
	|		AllUpgrades.Doc.Customer AS Customer,
	|		AllUpgrades.Doc.Contract AS Contract,
	|		AllUpgrades.Doc.ContactPerson AS ContactPerson,
	|		AllUpgrades.Doc.Agent AS Agent,
	|		AllUpgrades.Doc.ClientType AS ClientType,
	|		AllUpgrades.Doc.TripPurpose AS TripPurpose,
	|		AllUpgrades.Doc.SourceOfBusiness AS SourceOfBusiness,
	|		AllUpgrades.Doc.MarketingCode AS MarketingCode,
	|		AllUpgrades.Doc.RoomQuota AS RoomQuota,
	|		AllUpgrades.Doc.HotelProduct AS HotelProduct,
	|		AllUpgrades.Doc.DiscountType AS DiscountType,
	|		AllUpgrades.Doc.Discount AS Discount,
	|		AllUpgrades.Doc.PlannedPaymentMethod AS PlannedPaymentMethod,
	|		AllUpgrades.Doc.Company AS Company,
	|		AllUpgrades.Doc.Hotel AS Hotel,
	|		AllUpgrades.Doc.PriceChangeReason AS PriceChangeReason,
	|		CAST(AllUpgrades.Doc.Remarks AS STRING(1024)) AS Remarks,
	|		CAST(AllUpgrades.Doc.Car AS STRING(1024)) AS Car
	|	FROM
	|		(SELECT
	|			AccommodationUpgrades.Accommodation AS Doc,
	|			AccommodationUpgrades.Accommodation.AccommodationStatus AS Status,
	|			AccommodationUpgrades.RoomType AS RoomType,
	|			AccommodationUpgrades.RoomTypeBefore AS RoomTypeBefore,
	|			AccommodationUpgrades.RoomTypeForPrices AS RoomTypeForPrices,
	|			AccommodationUpgrades.RoomTypeForPricesBefore AS RoomTypeForPricesBefore,
	|			AccommodationUpgrades.UpgradeTime AS UpgradeTime,
	|			AccommodationChangeHistory.User AS UpgradeAuthor
	|		FROM
	|			AccommodationUpgrades AS AccommodationUpgrades
	|				INNER JOIN InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|				ON AccommodationUpgrades.Accommodation = AccommodationChangeHistory.Accommodation
	|					AND AccommodationUpgrades.UpgradeTime = AccommodationChangeHistory.Period
	|		WHERE
	|			AccommodationUpgrades.Accommodation.AccommodationStatus.IsActive
	|			AND AccommodationUpgrades.Accommodation.Posted
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			ReservationUpgrades.Reservation,
	|			ReservationUpgrades.Reservation.ReservationStatus,
	|			ReservationUpgrades.RoomType,
	|			ReservationUpgrades.RoomTypeBefore,
	|			ReservationUpgrades.RoomTypeForPrices,
	|			ReservationUpgrades.RoomTypeForPricesBefore,
	|			ReservationUpgrades.UpgradeTime,
	|			ReservationChangeHistory.User
	|		FROM
	|			ReservationUpgrades AS ReservationUpgrades
	|				INNER JOIN InformationRegister.ReservationChangeHistory AS ReservationChangeHistory
	|				ON ReservationUpgrades.Reservation = ReservationChangeHistory.Reservation
	|					AND ReservationUpgrades.UpgradeTime = ReservationChangeHistory.Period
	|		WHERE
	|			(ReservationUpgrades.Reservation.ReservationStatus.IsActive
	|					OR ReservationUpgrades.Reservation.ReservationStatus.IsPreliminary
	|					OR ReservationUpgrades.Reservation.ReservationStatus.IsCheckIn)
	|			AND ReservationUpgrades.Reservation.Posted) AS AllUpgrades
	|	WHERE
	|		AllUpgrades.UpgradeAuthor IN HIERARCHY(&qEmployee)) AS UpgradedDocuments
	|WHERE
	|	(NOT &qShowMainRoomGuestsOnly
	|			OR &qShowMainRoomGuestsOnly
	|				AND (UpgradedDocuments.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
	|					OR UpgradedDocuments.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds)))
	|{WHERE
	|	UpgradedDocuments.UpgradeAuthor.* AS UpgradeAuthor,
	|	(BEGINOFPERIOD(UpgradedDocuments.UpgradeTime, DAY)) AS UpgradeDate,
	|	UpgradedDocuments.UpgradeTime AS UpgradeTime,
	|	UpgradedDocuments.Status.*,
	|	UpgradedDocuments.Reservation.*,
	|	UpgradedDocuments.GuestGroup.*,
	|	UpgradedDocuments.Customer.*,
	|	UpgradedDocuments.Guest.*,
	|	UpgradedDocuments.CheckInDate,
	|	UpgradedDocuments.Duration,
	|	UpgradedDocuments.CheckOutDate,
	|	UpgradedDocuments.AccommodationTemplate.*,
	|	UpgradedDocuments.AccommodationType.*,
	|	UpgradedDocuments.Room.*,
	|	UpgradedDocuments.RoomType.* AS RoomType,
	|	UpgradedDocuments.RoomTypeForPrices.* AS RoomTypeForPrices,
	|	UpgradedDocuments.RoomRate.*,
	|	UpgradedDocuments.RoomTypeBefore.* AS RoomTypeBefore,
	|	UpgradedDocuments.RoomTypeForPricesBefore.* AS RoomTypeForPricesBefore,
	|	UpgradedDocuments.Contract.* AS Contract,
	|	UpgradedDocuments.ContactPerson AS ContactPerson,
	|	UpgradedDocuments.Agent.* AS Agent,
	|	UpgradedDocuments.ClientType.* AS ClientType,
	|	UpgradedDocuments.TripPurpose.* AS TripPurpose,
	|	UpgradedDocuments.SourceOfBusiness.* AS SourceOfBusiness,
	|	UpgradedDocuments.MarketingCode.* AS MarketingCode,
	|	UpgradedDocuments.RoomQuota.* AS RoomQuota,
	|	UpgradedDocuments.HotelProduct.* AS HotelProduct,
	|	UpgradedDocuments.DiscountType.* AS DiscountType,
	|	UpgradedDocuments.Discount AS Discount,
	|	UpgradedDocuments.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	UpgradedDocuments.Company.* AS Company,
	|	UpgradedDocuments.Hotel.* AS Hotel,
	|	UpgradedDocuments.PriceChangeReason AS PriceChangeReason,
	|	UpgradedDocuments.Remarks AS Remarks,
	|	UpgradedDocuments.Car AS Car}
	|
	|ORDER BY
	|	UpgradeTime
	|{ORDER BY
	|	UpgradeAuthor.* AS UpgradeAuthor,
	|	(BEGINOFPERIOD(UpgradedDocuments.UpgradeTime, DAY)) AS UpgradeDate,
	|	UpgradeTime AS UpgradeTime,
	|	Status.*,
	|	Reservation.*,
	|	GuestGroup.*,
	|	Customer.*,
	|	Guest.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	AccommodationTemplate.*,
	|	NumberOfPersons AS NumberOfPersons,
	|	NumberOfAdults AS NumberOfAdults,
	|	NumberOfTeenagers AS NumberOfTeenagers,
	|	NumberOfChildren AS NumberOfChildren,
	|	NumberOfInfants AS NumberOfInfants,
	|	AccommodationType.*,
	|	Room.*,
	|	RoomType.* AS RoomType,
	|	RoomTypeForPrices.* AS RoomTypeForPrices,
	|	RoomRate.*,
	|	UpgradedDocuments.RoomTypeBefore.* AS RoomTypeBefore,
	|	UpgradedDocuments.RoomTypeForPricesBefore.* AS RoomTypeForPricesBefore,
	|	UpgradedDocuments.Contract.* AS Contract,
	|	UpgradedDocuments.ContactPerson AS ContactPerson,
	|	UpgradedDocuments.Agent.* AS Agent,
	|	UpgradedDocuments.ClientType.* AS ClientType,
	|	UpgradedDocuments.TripPurpose.* AS TripPurpose,
	|	UpgradedDocuments.SourceOfBusiness.* AS SourceOfBusiness,
	|	UpgradedDocuments.MarketingCode.* AS MarketingCode,
	|	UpgradedDocuments.RoomQuota.* AS RoomQuota,
	|	UpgradedDocuments.HotelProduct.* AS HotelProduct,
	|	UpgradedDocuments.DiscountType.* AS DiscountType,
	|	UpgradedDocuments.Discount AS Discount,
	|	UpgradedDocuments.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	PriceChangeReason AS PriceChangeReason,
	|	UpgradedDocuments.Company.* AS Company,
	|	UpgradedDocuments.Hotel.* AS Hotel}
	|TOTALS
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants),
	|	SUM(NumberOfPersons),
	|	SUM(UpgradesCount)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	UpgradeAuthor.* AS UpgradeAuthor,
	|	(BEGINOFPERIOD(UpgradedDocuments.UpgradeTime, DAY)) AS UpgradeDate,
	|	Status.*,
	|	Reservation.*,
	|	GuestGroup.*,
	|	Customer.*,
	|	Guest.*,
	|	AccommodationTemplate.*,
	|	AccommodationType.*,
	|	Room.*,
	|	RoomType.* AS RoomType,
	|	RoomTypeForPrices.* AS RoomTypeForPrices,
	|	RoomRate.*,
	|	UpgradedDocuments.Contract.* AS Contract,
	|	UpgradedDocuments.ContactPerson AS ContactPerson,
	|	UpgradedDocuments.Agent.* AS Agent,
	|	UpgradedDocuments.ClientType.* AS ClientType,
	|	UpgradedDocuments.TripPurpose.* AS TripPurpose,
	|	UpgradedDocuments.SourceOfBusiness.* AS SourceOfBusiness,
	|	UpgradedDocuments.MarketingCode.* AS MarketingCode,
	|	UpgradedDocuments.RoomQuota.* AS RoomQuota,
	|	UpgradedDocuments.HotelProduct.* AS HotelProduct,
	|	UpgradedDocuments.DiscountType.* AS DiscountType,
	|	UpgradedDocuments.Discount AS Discount,
	|	UpgradedDocuments.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	PriceChangeReason AS PriceChangeReason,
	|	UpgradedDocuments.Company.* AS Company,
	|	UpgradedDocuments.Hotel.* AS Hotel}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en = 'Room upgrades audit'; de = 'Audit der Zimmer-Upgrades'; ru = 'Аудит повышений категории номеров'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

#EndRegion
