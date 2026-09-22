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
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode bis '") + 
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
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Firmen ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
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
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Gruppe Zimmertypen '") + 
			                     TrimAll(RoomType.Description) + 
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
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qEndOfTime", '39991231');
 	vShowFRR = False;
	vShowCDS = False;
	vShowPayments = False;
	For Each vFld In ReportBuilder.SelectedFields Do
		If Left(vFld.Name, 23) = "ForeignerRegistryRecord" Then
			vShowFRR = True;
		EndIf;
		If Left(vFld.Name, 14) = "ClientDataScan" Then
			vShowCDS = True;
		EndIf;
		If Left(vFld.Name, 7) = "Payment" Then
			vShowPayments = True;
		EndIf;
	EndDo;
	ReportBuilder.Parameters.Insert("qShowFRR", vShowFRR);
	ReportBuilder.Parameters.Insert("qShowCDS", vShowCDS);
	ReportBuilder.Parameters.Insert("qShowPayments", vShowPayments);
	ReportBuilder.Parameters.Insert("qEmptyForeignerRegistryRecord", Documents.ForeignerRegistryRecord.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyClientDataScan", Documents.ClientDataScans.EmptyRef());
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", ShowMainRoomGuestsOnly);
	ReportBuilder.Parameters.Insert("qShowOnlyEmptyDataScans", ShowOnlyEmptyDataScans);
	ReportBuilder.Parameters.Insert("qEmptyTemplate", Catalogs.AccommodationTemplates.EmptyRef());
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qCustomAttribute1", CustomAttribute1);
	ReportBuilder.Parameters.Insert("qCustomAttribute2", CustomAttribute2);
	ReportBuilder.Parameters.Insert("qCustomAttribute3", CustomAttribute3);

	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	Try
		ReportBuilder.Put(pSpreadsheet);
	Except
		tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
	EndTry;
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
	|	RoomInventory.Recorder.Hotel AS Hotel,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.Recorder.Customer AS Customer,
	|	RoomInventory.Recorder.GuestGroup AS GuestGroup,
	|	RoomInventory.Recorder.AccommodationStatus AS AccommodationStatus,
	|	RoomInventory.Recorder.Guest AS Guest,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.Duration AS Duration,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.Recorder.AccommodationType AS AccommodationType,
	|	RoomInventory.Recorder.RoomRate AS RoomRate,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.Reservation.RoomRate AS ParentDocRoomRate,
	|	RoomInventory.Recorder.Reservation.PricePresentation AS ParentDocPricePresentation,
	|	CASE
	|		WHEN RoomInventory.Recorder.Reservation.PricePresentation <> """"
	|				AND RoomInventory.Recorder.Reservation.PricePresentation <> RoomInventory.Recorder.PricePresentation
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsPriceDifference,
	|	RoomInventory.Recorder.Remarks AS Remarks,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) + ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) + ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) + ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)
	|		ELSE RoomInventory.GuestsCheckedIn
	|	END AS GuestsCheckedIn,
	|	ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) AS NumberOfAdults,
	|	ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) AS NumberOfTeenagers,
	|	ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) AS NumberOfChildren,
	|	ISNULL(RoomInventory.Recorder.NumberOfInfants, 0) AS NumberOfInfants,
	|	RoomInventory.RoomsCheckedIn AS RoomsCheckedIn,
	|	RoomInventory.BedsCheckedIn AS BedsCheckedIn,
	|	RoomInventory.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	Payments.Ref AS Payment,
	|	ISNULL(Payments.Sum, 0) AS PaymentSum
	|{SELECT
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	Customer.* AS Customer,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	Guest.* AS Guest,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.Recorder.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.Recorder.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.Recorder.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckInDate)) AS CheckInYear,
	|	RoomType.* AS RoomType,
	|	AccommodationType.* AS AccommodationType,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.Reservation.RoomType.* AS ParentDocRoomType,
	|	RoomInventory.Recorder.Reservation.AccommodationType.* AS ParentDocAccommodationType,
	|	RoomInventory.Recorder.Reservation.RoomRateType.* AS ParentDocRoomRateType,
	|	ParentDocRoomRate.* AS ParentDocRoomRate,
	|	ParentDocPricePresentation AS ParentDocPricePresentation,
	|	ThereIsPriceDifference AS ThereIsPriceDifference,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Remarks AS Remarks,
	|	RoomInventory.Recorder.Car AS Car,
	|	GuestGroup.* AS GuestGroup,
	|	AccommodationStatus.* AS AccommodationStatus,
	|	RoomInventory.Recorder.IsMaster AS IsMaster,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.Discount AS Discount,
	|	RoomInventory.Recorder.AgentCommission AS AgentCommission,
	|	RoomInventory.Recorder.AgentCommissionType.* AS AgentCommissionType,
	|	RoomInventory.Recorder.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	RoomInventory.Recorder.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	RoomInventory.Recorder.Reservation.* AS ParentDoc,
	|	RoomInventory.Recorder.* AS Recorder,
	|	(DATEDIFF(RoomInventory.Recorder.Reservation.Date, RoomInventory.Recorder.Date, MINUTE)) AS CheckInWaitTimeInMinutes,
	|	(DATEDIFF(RoomInventory.Recorder.Reservation.Date, RoomInventory.Recorder.Date, HOUR)) AS CheckInWaitTimeInHours,
	|	(CASE
	|			WHEN NOT RoomInventory.Recorder.Reservation.CheckInDate IS NULL
	|					AND BEGINOFPERIOD(RoomInventory.Recorder.Reservation.CheckInDate, DAY) <> BEGINOFPERIOD(RoomInventory.Recorder.CheckInDate, DAY)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS AccommodationAndReservationCheckInDatesAreNotTheSame,
	|	(CASE
	|			WHEN NOT RoomInventory.Recorder.Reservation.CheckOutDate IS NULL
	|					AND BEGINOFPERIOD(RoomInventory.Recorder.Reservation.CheckOutDate, DAY) <> BEGINOFPERIOD(RoomInventory.Recorder.CheckOutDate, DAY)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS AccommodationAndReservationCheckOutDatesAreNotTheSame,
	|	RoomInventory.Recorder.PointInTime AS PointInTime,
	|	(CASE
	|			WHEN ForeignerRegistryRecords.ForeignerRegistryRecord IS NULL
	|				THEN &qEmptyForeignerRegistryRecord
	|			ELSE ForeignerRegistryRecords.ForeignerRegistryRecord
	|		END).* AS ForeignerRegistryRecord,
	|	(CASE
	|			WHEN ClientDataScans.Ref IS NULL
	|				THEN &qEmptyClientDataScan
	|			ELSE ClientDataScans.Ref
	|		END).* AS ClientDataScan,
	|	GuestsCheckedIn,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	Payment.*,
	|	PaymentSum,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}
	|FROM
	|	(SELECT
	|		RoomInventoryMovements.Recorder AS Recorder,
	|		RoomInventoryMovements.Room AS Room,
	|		RoomInventoryMovements.RoomType AS RoomType,
	|		RoomInventoryMovements.AccommodationStatus.IsInHouse AS IsInHouse,
	|		MIN(RoomInventoryMovements.CheckInAccountingDate) AS CheckInAccountingDate,
	|		MAX(RoomInventoryMovements.CheckOutAccountingDate) AS CheckOutAccountingDate,
	|		SUM(RoomInventoryMovements.GuestsCheckedIn) AS GuestsCheckedIn,
	|		SUM(RoomInventoryMovements.RoomsCheckedIn) AS RoomsCheckedIn,
	|		SUM(RoomInventoryMovements.BedsCheckedIn) AS BedsCheckedIn,
	|		SUM(RoomInventoryMovements.AdditionalBedsCheckedIn) AS AdditionalBedsCheckedIn
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventoryMovements
	|	WHERE
	|		RoomInventoryMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND RoomInventoryMovements.IsAccommodation = TRUE
	|		AND RoomInventoryMovements.Hotel IN HIERARCHY(&qHotel)
	|		AND RoomInventoryMovements.Room IN HIERARCHY(&qRoom)
	|		AND RoomInventoryMovements.RoomType IN HIERARCHY(&qRoomType)
	|		AND (&qCustomerIsEmpty
	|				OR RoomInventoryMovements.Customer IN HIERARCHY (&qCustomer))
	|		AND RoomInventoryMovements.PeriodFrom >= &qPeriodFrom
	|		AND RoomInventoryMovements.PeriodFrom < &qPeriodTo
	|		AND RoomInventoryMovements.CheckInDate = RoomInventoryMovements.Period
	|		AND RoomInventoryMovements.IsCheckIn = TRUE
	|	
	|	GROUP BY
	|		RoomInventoryMovements.Recorder,
	|		RoomInventoryMovements.Room,
	|		RoomInventoryMovements.RoomType,
	|		RoomInventoryMovements.AccommodationStatus.IsInHouse) AS RoomInventory
	|		LEFT JOIN InformationRegister.AccommodationForeignerRegistryRecords.SliceLast(&qEndOfTime, &qShowFRR) AS ForeignerRegistryRecords
	|		ON RoomInventory.Recorder = ForeignerRegistryRecords.Accommodation
	|		LEFT JOIN Document.ClientDataScans AS ClientDataScans
	|		ON RoomInventory.Recorder = ClientDataScans.ParentDoc
	|			AND (ClientDataScans.Posted)
	|			AND (&qShowCDS)
	|		LEFT JOIN Document.Payment AS Payments
	|		ON (RoomInventory.Recorder = Payments.ParentDoc
	|				OR RoomInventory.Recorder = Payments.ParentDoc.ParentDoc)
	|			AND (Payments.Posted)
	|			AND (&qShowPayments)
	|		LEFT JOIN Document.ClientDataScans AS DataScans
	|		ON RoomInventory.Recorder.Guest = DataScans.Guest
	|			AND (DataScans.Posted)
	|			AND RoomInventory.Recorder <> DataScans.ParentDoc
	|			AND (&qShowCDS)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues1
	|		ON (RoomInventory.Recorder.Reservation = ReservationCustomAttributeValues1.Owner
	|				OR RoomInventory.Recorder = ReservationCustomAttributeValues1.Owner
	|					AND RoomInventory.Recorder.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues1.Characteristic = &qCustomAttribute1)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues2
	|		ON (RoomInventory.Recorder.Reservation = ReservationCustomAttributeValues2.Owner
	|				OR RoomInventory.Recorder = ReservationCustomAttributeValues2.Owner
	|					AND RoomInventory.Recorder.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues2.Characteristic = &qCustomAttribute2)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues3
	|		ON (RoomInventory.Recorder.Reservation = ReservationCustomAttributeValues3.Owner
	|				OR RoomInventory.Recorder = ReservationCustomAttributeValues3.Owner
	|					AND RoomInventory.Recorder.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues3.Characteristic = &qCustomAttribute3)
	|WHERE
	|	(NOT &qShowMainRoomGuestsOnly
	|			OR &qShowMainRoomGuestsOnly
	|				AND RoomInventory.Recorder.AccommodationTemplate <> &qEmptyTEmplate)
	|	AND CASE
	|			WHEN &qShowOnlyEmptyDataScans
	|				THEN DataScans.Number IS NULL
	|			ELSE TRUE
	|		END
	|{WHERE
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.Recorder.Hotel.* AS Hotel,
	|	RoomInventory.Room.* AS Room,
	|	RoomInventory.Recorder.Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.GuestGroup.* AS GuestGroup,
	|	RoomInventory.Recorder.Reservation.* AS ParentDoc,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	RoomInventory.Recorder.AccommodationStatus.* AS AccommodationStatus,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.Duration AS Duration,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.Guest.* AS Guest,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.RoomType.* AS RoomType,
	|	RoomInventory.Recorder.AccommodationType.* AS AccommodationType,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.RoomRate.* AS RoomRate,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.Reservation.RoomType.* AS ParentDocRoomType,
	|	RoomInventory.Recorder.Reservation.AccommodationType.* AS ParentDocAccommodationType,
	|	RoomInventory.Recorder.Reservation.RoomRateType.* AS ParentDocRoomRateType,
	|	RoomInventory.Recorder.Reservation.RoomRate.* AS ParentDocRoomRate,
	|	RoomInventory.Recorder.Reservation.PricePresentation AS ParentDocPricePresentation,
	|	(CASE
	|			WHEN RoomInventory.Recorder.Reservation.PricePresentation <> """"
	|					AND RoomInventory.Recorder.Reservation.PricePresentation <> RoomInventory.Recorder.PricePresentation
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS ThereIsPriceDifference,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.Discount AS Discount,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	RoomInventory.Recorder.Car AS Car,
	|	RoomInventory.Recorder.Remarks AS Remarks,
	|	RoomInventory.Recorder.AgentCommission AS AgentCommission,
	|	RoomInventory.Recorder.AgentCommissionType.* AS AgentCommissionType,
	|	RoomInventory.Recorder.IsMaster AS IsMaster,
	|	(DATEDIFF(RoomInventory.Recorder.Reservation.Date, RoomInventory.Recorder.Date, MINUTE)) AS CheckInWaitTimeInMinutes,
	|	(DATEDIFF(RoomInventory.Recorder.Reservation.Date, RoomInventory.Recorder.Date, HOUR)) AS CheckInWaitTimeInHours,
	|	(CASE
	|			WHEN NOT RoomInventory.Recorder.Reservation.CheckInDate IS NULL
	|					AND BEGINOFPERIOD(RoomInventory.Recorder.Reservation.CheckInDate, DAY) <> BEGINOFPERIOD(RoomInventory.Recorder.CheckInDate, DAY)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS AccommodationAndReservationCheckInDatesAreNotTheSame,
	|	(CASE
	|			WHEN NOT RoomInventory.Recorder.Reservation.CheckOutDate IS NULL
	|					AND BEGINOFPERIOD(RoomInventory.Recorder.Reservation.CheckOutDate, DAY) <> BEGINOFPERIOD(RoomInventory.Recorder.CheckOutDate, DAY)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS AccommodationAndReservationCheckOutDatesAreNotTheSame,
	|	(CASE
	|			WHEN ForeignerRegistryRecords.ForeignerRegistryRecord IS NULL
	|				THEN &qEmptyForeignerRegistryRecord
	|			ELSE ForeignerRegistryRecords.ForeignerRegistryRecord
	|		END).* AS ForeignerRegistryRecord,
	|	(CASE
	|			WHEN ClientDataScans.Ref IS NULL
	|				THEN &qEmptyClientDataScan
	|			ELSE ClientDataScans.Ref
	|		END).* AS ClientDataScan,
	|	(CASE
	|			WHEN &qShowMainRoomGuestsOnly
	|				THEN ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) + ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) + ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) + ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)
	|			ELSE RoomInventory.GuestsCheckedIn
	|		END) AS GuestsCheckedIn,
	|	(ISNULL(RoomInventory.Recorder.NumberOfAdults, 0)) AS NumberOfAdults,
	|	(ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0)) AS NumberOfTeenagers,
	|	(ISNULL(RoomInventory.Recorder.NumberOfChildren, 0)) AS NumberOfChildren,
	|	(ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)) AS NumberOfInfants,
	|	RoomInventory.RoomsCheckedIn AS RoomsCheckedIn,
	|	RoomInventory.BedsCheckedIn AS BedsCheckedIn,
	|	RoomInventory.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	Payments.Ref.* AS Payment,
	|	(ISNULL(Payments.Sum, 0)) AS PaymentSum,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}
	|
	|ORDER BY
	|	Hotel,
	|	Room,
	|	CheckInDate,
	|	Guest
	|{ORDER BY
	|	Customer.*,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	Guest.* AS Guest,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Hotel.* AS Hotel,
	|	RoomInventory.Recorder.PointInTime AS PointInTime,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.Recorder.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.Recorder.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.Recorder.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckInDate)) AS CheckInYear,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.Reservation.* AS ParentDoc,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.Recorder.Reservation.RoomType.* AS ParentDocRoomType,
	|	RoomInventory.Recorder.Reservation.AccommodationType.* AS ParentDocAccommodationType,
	|	RoomInventory.Recorder.Reservation.RoomRateType.* AS ParentDocRoomRateType,
	|	(DATEDIFF(RoomInventory.Recorder.Reservation.Date, RoomInventory.Recorder.Date, MINUTE)) AS CheckInWaitTimeInMinutes,
	|	(DATEDIFF(RoomInventory.Recorder.Reservation.Date, RoomInventory.Recorder.Date, HOUR)) AS CheckInWaitTimeInHours,
	|	ParentDocRoomRate.* AS ParentDocRoomRate,
	|	(CASE
	|			WHEN ForeignerRegistryRecords.ForeignerRegistryRecord IS NULL
	|				THEN &qEmptyForeignerRegistryRecord
	|			ELSE ForeignerRegistryRecords.ForeignerRegistryRecord
	|		END).* AS ForeignerRegistryRecord,
	|	(CASE
	|			WHEN ClientDataScans.Ref IS NULL
	|				THEN &qEmptyClientDataScan
	|			ELSE ClientDataScans.Ref
	|		END).* AS ClientDataScan,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	GuestsCheckedIn,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}
	|TOTALS
	|	SUM(GuestsCheckedIn),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants),
	|	SUM(RoomsCheckedIn),
	|	SUM(BedsCheckedIn),
	|	SUM(AdditionalBedsCheckedIn),
	|	SUM(PaymentSum)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Room
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.Recorder.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.Recorder.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.Recorder.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckInDate)) AS CheckInYear,
	|	Guest.* AS Guest,
	|	AccommodationStatus.* AS AccommodationStatus,
	|	AccommodationType.* AS AccommodationType,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomRate.* AS RoomRate,
	|	RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
	|	RoomInventory.Recorder.Reservation.* AS ParentDoc,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	AccommodationStatus.* AS AccommodationStatus,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.Reservation.RoomType.* AS ParentDocRoomType,
	|	RoomInventory.Recorder.Reservation.AccommodationType.* AS ParentDocAccommodationType,
	|	RoomInventory.Recorder.Reservation.RoomRateType.* AS ParentDocRoomRateType,
	|	ParentDocRoomRate.* AS ParentDocRoomRate,
	|	(DATEDIFF(RoomInventory.Recorder.Reservation.Date, RoomInventory.Recorder.Date, MINUTE)) AS CheckInWaitTimeInMinutes,
	|	(DATEDIFF(RoomInventory.Recorder.Reservation.Date, RoomInventory.Recorder.Date, HOUR)) AS CheckInWaitTimeInHours,
	|	(CASE
	|			WHEN ForeignerRegistryRecords.ForeignerRegistryRecord IS NULL
	|				THEN &qEmptyForeignerRegistryRecord
	|			ELSE ForeignerRegistryRecords.ForeignerRegistryRecord
	|		END).* AS ForeignerRegistryRecord,
	|	(CASE
	|			WHEN ClientDataScans.Ref IS NULL
	|				THEN &qEmptyClientDataScan
	|			ELSE ClientDataScans.Ref
	|		END).* AS ClientDataScan,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Guests checked-in';RU='Заезд гостей';de='Gäste Anreise'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
