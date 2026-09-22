
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
	|	AccommodationChanges.CheckInTime AS CheckInTime,
	|	AccommodationChanges.CheckInRoom AS CheckInRoom,
	|	AccommodationChanges.Author AS Author,
	|	AccommodationChanges.Accommodation AS Accommodation,
	|	AccommodationChanges.CheckInDate AS CheckInDate,
	|	AccommodationChanges.Duration AS Duration,
	|	AccommodationChanges.CheckOutDate AS CheckOutDate,
	|	AccommodationChanges.Room AS Room,
	|	AccommodationChanges.RoomType AS RoomType,
	|	AccommodationChanges.Guest AS Guest,
	|	AccommodationChanges.AccommodationType AS AccommodationType,
	|	AccommodationChanges.MovedToRoom AS MovedToRoom,
	|	AccommodationChanges.MovedToRoomType AS MovedToRoomType,
	|	AccommodationChanges.MovedToTime AS MovedToTime,
	|	AccommodationChanges.MovedToAuthor AS MovedToAuthor,
	|	1 AS MovedToCount
	|{SELECT
	|	CheckInTime,
	|	Author.*,
	|	CheckInRoom.*,
	|	Accommodation.*,
	|	AccommodationChanges.Hotel.* AS Hotel,
	|	AccommodationChanges.GuestGroup.* AS GuestGroup,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	Guest.*,
	|	Room.*,
	|	RoomType.*,
	|	AccommodationType.*,
	|	AccommodationChanges.RoomRate.* AS RoomRate,
	|	MovedToTime,
	|	MovedToAuthor.*,
	|	MovedToRoom.*,
	|	AccommodationChanges.MovedToHotel.* AS MovedToHotel,
	|	AccommodationChanges.MovedToAccommodationStatus.* AS MovedToAccommodationStatus,
	|	AccommodationChanges.MovedToCheckInDate AS MovedToCheckInDate,
	|	AccommodationChanges.MovedToDuration AS MovedToDuration,
	|	AccommodationChanges.MovedToCheckOutDate AS MovedToCheckOutDate,
	|	MovedToRoomType.* AS MovedToRoomType,
	|	AccommodationChanges.MovedToAccommodationType.* AS MovedToAccommodationType,
	|	AccommodationChanges.MovedToNumberOfPersons AS MovedToNumberOfPersons,
	|	AccommodationChanges.MovedToCustomer.* AS MovedToCustomer,
	|	AccommodationChanges.MovedToContract.* AS MovedToContract,
	|	AccommodationChanges.MovedToContactPerson AS MovedToContactPerson,
	|	AccommodationChanges.MovedToAgent.* AS MovedToAgent,
	|	AccommodationChanges.MovedToGuest.* AS MovedToGuest,
	|	AccommodationChanges.MovedToClientType.* AS MovedToClientType,
	|	AccommodationChanges.MovedToRoomRate.* AS MovedToRoomRate,
	|	AccommodationChanges.MovedToTripPurpose.* AS MovedToTripPurpose,
	|	AccommodationChanges.MovedToSourceOfBusiness.* AS MovedToSourceOfBusiness,
	|	AccommodationChanges.MovedToMarketingCode.* AS MovedToMarketingCode,
	|	AccommodationChanges.MovedToRoomQuota.* AS MovedToRoomQuota,
	|	AccommodationChanges.MovedToGuestGroup.* AS MovedToGuestGroup,
	|	AccommodationChanges.MovedToHotelProduct.* AS MovedToHotelProduct,
	|	AccommodationChanges.MovedToDiscountType.* AS MovedToDiscountType,
	|	AccommodationChanges.MovedToDiscount AS MovedToDiscount,
	|	AccommodationChanges.MovedToPlannedPaymentMethod.* AS MovedToPlannedPaymentMethod,
	|	AccommodationChanges.MovedToCompany.* AS MovedToCompany,
	|	AccommodationChanges.MovedToRemarks AS MovedToRemarks,
	|	AccommodationChanges.MovedToCar AS MovedToCar,
	|	MovedToCount}
	|FROM
	|	(SELECT
	|		AccommodationChangeHistorySliceFirst.Period AS CheckInTime,
	|		AccommodationChangeHistorySliceFirst.Room AS CheckInRoom,
	|		AccommodationChangeHistorySliceLast.Author AS Author,
	|		AccommodationChangeHistorySliceLast.Accommodation AS Accommodation,
	|		AccommodationChangeHistorySliceLast.CheckInDate AS CheckInDate,
	|		AccommodationChangeHistorySliceLast.Duration AS Duration,
	|		AccommodationChangeHistorySliceLast.CheckOutDate AS CheckOutDate,
	|		AccommodationChangeHistorySliceLast.Room AS Room,
	|		AccommodationChangeHistorySliceLast.RoomType AS RoomType,
	|		AccommodationChangeHistorySliceLast.Guest AS Guest,
	|		AccommodationChangeHistorySliceLast.AccommodationType AS AccommodationType,
	|		AccommodationChangeHistory.Room AS MovedToRoom,
	|		AccommodationChangeHistory.RoomType AS MovedToRoomType,
	|		AccommodationChangeHistory.User AS MovedToAuthor,
	|		AccommodationChangeHistorySliceLast.Hotel AS Hotel,
	|		AccommodationChangeHistorySliceLast.GuestGroup AS GuestGroup,
	|		AccommodationChangeHistorySliceLast.RoomRate AS RoomRate,
	|		AccommodationChangeHistory.Hotel AS MovedToHotel,
	|		AccommodationChangeHistory.AccommodationStatus AS MovedToAccommodationStatus,
	|		AccommodationChangeHistory.CheckInDate AS MovedToCheckInDate,
	|		AccommodationChangeHistory.Duration AS MovedToDuration,
	|		AccommodationChangeHistory.CheckOutDate AS MovedToCheckOutDate,
	|		AccommodationChangeHistory.AccommodationType AS MovedToAccommodationType,
	|		AccommodationChangeHistory.NumberOfPersons AS MovedToNumberOfPersons,
	|		AccommodationChangeHistory.Customer AS MovedToCustomer,
	|		AccommodationChangeHistory.Contract AS MovedToContract,
	|		AccommodationChangeHistory.ContactPerson AS MovedToContactPerson,
	|		AccommodationChangeHistory.Agent AS MovedToAgent,
	|		AccommodationChangeHistory.Guest AS MovedToGuest,
	|		AccommodationChangeHistory.ClientType AS MovedToClientType,
	|		AccommodationChangeHistory.RoomRate AS MovedToRoomRate,
	|		AccommodationChangeHistory.TripPurpose AS MovedToTripPurpose,
	|		AccommodationChangeHistory.SourceOfBusiness AS MovedToSourceOfBusiness,
	|		AccommodationChangeHistory.MarketingCode AS MovedToMarketingCode,
	|		AccommodationChangeHistory.RoomQuota AS MovedToRoomQuota,
	|		AccommodationChangeHistory.GuestGroup AS MovedToGuestGroup,
	|		AccommodationChangeHistory.HotelProduct AS MovedToHotelProduct,
	|		AccommodationChangeHistory.DiscountType AS MovedToDiscountType,
	|		AccommodationChangeHistory.Discount AS MovedToDiscount,
	|		AccommodationChangeHistory.PlannedPaymentMethod AS MovedToPlannedPaymentMethod,
	|		AccommodationChangeHistory.Company AS MovedToCompany,
	|		CAST(AccommodationChangeHistory.Remarks AS STRING(1024)) AS MovedToRemarks,
	|		CAST(AccommodationChangeHistory.Car AS STRING(1024)) AS MovedToCar,
	|		MIN(AccommodationChangeHistory.Period) AS MovedToTime
	|	FROM
	|		InformationRegister.AccommodationChangeHistory.SliceLast(&qPeriodTo, ) AS AccommodationChangeHistorySliceLast
	|			INNER JOIN InformationRegister.AccommodationChangeHistory.SliceFirst(&qEmptyDate, ) AS AccommodationChangeHistorySliceFirst
	|			ON (AccommodationChangeHistorySliceFirst.Accommodation = AccommodationChangeHistorySliceLast.Accommodation)
	|				AND (AccommodationChangeHistorySliceFirst.Room <> AccommodationChangeHistorySliceLast.Room)
	|			INNER JOIN InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|			ON AccommodationChangeHistorySliceLast.Accommodation = AccommodationChangeHistory.Accommodation
	|				AND (AccommodationChangeHistorySliceFirst.Room <> AccommodationChangeHistory.Room)
	|	WHERE
	|		AccommodationChangeHistorySliceLast.Hotel IN HIERARCHY(&qHotel)
	|		AND AccommodationChangeHistorySliceLast.Room IN HIERARCHY(&qRoom)
	|		AND AccommodationChangeHistorySliceLast.RoomType IN HIERARCHY(&qRoomType)
	|		AND AccommodationChangeHistory.User IN HIERARCHY(&qEmployee)
	|		AND AccommodationChangeHistorySliceLast.Period >= &qPeriodFrom
	|		AND AccommodationChangeHistorySliceLast.Period < &qPeriodTo
	|	
	|	GROUP BY
	|		AccommodationChangeHistorySliceFirst.Period,
	|		AccommodationChangeHistorySliceFirst.Room,
	|		AccommodationChangeHistorySliceLast.Author,
	|		AccommodationChangeHistorySliceLast.Accommodation,
	|		AccommodationChangeHistorySliceLast.CheckInDate,
	|		AccommodationChangeHistorySliceLast.Duration,
	|		AccommodationChangeHistorySliceLast.CheckOutDate,
	|		AccommodationChangeHistorySliceLast.Room,
	|		AccommodationChangeHistorySliceLast.RoomType,
	|		AccommodationChangeHistorySliceLast.Guest,
	|		AccommodationChangeHistorySliceLast.AccommodationType,
	|		AccommodationChangeHistory.Room,
	|		AccommodationChangeHistory.RoomType,
	|		AccommodationChangeHistory.User,
	|		AccommodationChangeHistorySliceLast.Hotel,
	|		AccommodationChangeHistorySliceLast.GuestGroup,
	|		AccommodationChangeHistorySliceLast.RoomRate,
	|		AccommodationChangeHistory.Hotel,
	|		AccommodationChangeHistory.AccommodationStatus,
	|		AccommodationChangeHistory.CheckInDate,
	|		AccommodationChangeHistory.Duration,
	|		AccommodationChangeHistory.CheckOutDate,
	|		AccommodationChangeHistory.AccommodationType,
	|		AccommodationChangeHistory.NumberOfPersons,
	|		AccommodationChangeHistory.Customer,
	|		AccommodationChangeHistory.Contract,
	|		AccommodationChangeHistory.ContactPerson,
	|		AccommodationChangeHistory.Agent,
	|		AccommodationChangeHistory.Guest,
	|		AccommodationChangeHistory.ClientType,
	|		AccommodationChangeHistory.RoomRate,
	|		AccommodationChangeHistory.TripPurpose,
	|		AccommodationChangeHistory.SourceOfBusiness,
	|		AccommodationChangeHistory.MarketingCode,
	|		AccommodationChangeHistory.RoomQuota,
	|		AccommodationChangeHistory.GuestGroup,
	|		AccommodationChangeHistory.HotelProduct,
	|		AccommodationChangeHistory.DiscountType,
	|		AccommodationChangeHistory.Discount,
	|		AccommodationChangeHistory.PlannedPaymentMethod,
	|		AccommodationChangeHistory.Company,
	|		CAST(AccommodationChangeHistory.Remarks AS STRING(1024)),
	|		CAST(AccommodationChangeHistory.Car AS STRING(1024))) AS AccommodationChanges
	|{WHERE
	|	AccommodationChanges.CheckInTime AS CheckInTime,
	|	AccommodationChanges.CheckInRoom.* AS CheckInRoom,
	|	AccommodationChanges.Author.*,
	|	AccommodationChanges.Accommodation.*,
	|	AccommodationChanges.Hotel.* AS Hotel,
	|	AccommodationChanges.GuestGroup.* AS GuestGroup,
	|	AccommodationChanges.CheckInDate,
	|	AccommodationChanges.Duration,
	|	AccommodationChanges.CheckOutDate,
	|	AccommodationChanges.Room.*,
	|	AccommodationChanges.Guest.*,
	|	AccommodationChanges.AccommodationType.*,
	|	AccommodationChanges.RoomType.*,
	|	AccommodationChanges.RoomRate.* AS RoomRate,
	|	AccommodationChanges.MovedToRoom.* AS MovedToRoom,
	|	AccommodationChanges.MovedToTime AS MovedToTime,
	|	AccommodationChanges.MovedToAuthor.* AS MovedToAuthor,
	|	AccommodationChanges.MovedToHotel.* AS MovedToHotel,
	|	AccommodationChanges.MovedToAccommodationStatus.* AS MovedToAccommodationStatus,
	|	AccommodationChanges.MovedToCheckInDate AS MovedToCheckInDate,
	|	AccommodationChanges.MovedToDuration AS MovedToDuration,
	|	AccommodationChanges.MovedToCheckOutDate AS MovedToCheckOutDate,
	|	AccommodationChanges.MovedToRoomType.* AS MovedToRoomType,
	|	AccommodationChanges.MovedToAccommodationType.* AS MovedToAccommodationType,
	|	AccommodationChanges.MovedToNumberOfPersons AS MovedToNumberOfPersons,
	|	AccommodationChanges.MovedToCustomer.* AS MovedToCustomer,
	|	AccommodationChanges.MovedToContract.* AS MovedToContract,
	|	AccommodationChanges.MovedToContactPerson AS MovedToContactPerson,
	|	AccommodationChanges.MovedToAgent.* AS MovedToAgent,
	|	AccommodationChanges.MovedToGuest.* AS MovedToGuest,
	|	AccommodationChanges.MovedToClientType.* AS MovedToClientType,
	|	AccommodationChanges.MovedToRoomRate.* AS MovedToRoomRate,
	|	AccommodationChanges.MovedToTripPurpose.* AS MovedToTripPurpose,
	|	AccommodationChanges.MovedToSourceOfBusiness.* AS MovedToSourceOfBusiness,
	|	AccommodationChanges.MovedToMarketingCode.* AS MovedToMarketingCode,
	|	AccommodationChanges.MovedToRoomQuota.* AS MovedToRoomQuota,
	|	AccommodationChanges.MovedToGuestGroup.* AS MovedToGuestGroup,
	|	AccommodationChanges.MovedToHotelProduct.* AS MovedToHotelProduct,
	|	AccommodationChanges.MovedToDiscountType.* AS MovedToDiscountType,
	|	AccommodationChanges.MovedToDiscount AS MovedToDiscount,
	|	AccommodationChanges.MovedToPlannedPaymentMethod.* AS MovedToPlannedPaymentMethod,
	|	AccommodationChanges.MovedToCompany.* AS MovedToCompany,
	|	AccommodationChanges.MovedToRemarks AS MovedToRemarks,
	|	AccommodationChanges.MovedToCar AS MovedToCar}
	|
	|ORDER BY
	|	CheckInTime,
	|	Room,
	|	MovedToTime
	|{ORDER BY
	|	CheckInTime,
	|	CheckInRoom.*,
	|	Author.*,
	|	Accommodation.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	Room.*,
	|	Guest.*,
	|	AccommodationType.*,
	|	RoomType.*,
	|	MovedToRoom.*,
	|	MovedToTime,
	|	MovedToAuthor.*}
	|TOTALS
	|	SUM(MovedToCount)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	CheckInRoom.*,
	|	Author.*,
	|	Accommodation.*,
	|	Room.*,
	|	Guest.*,
	|	AccommodationType.*,
	|	RoomType.*,
	|	MovedToRoom.*,
	|	MovedToAuthor.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en = 'Сhanges in accommodations audit'; de = 'Audit von Änderungen in Unterbringungen'; ru = 'Аудит изменений в размещениях'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

#EndRegion
