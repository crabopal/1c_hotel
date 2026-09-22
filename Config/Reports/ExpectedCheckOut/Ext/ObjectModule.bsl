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
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfDay(CurrentSessionDate()); // End of today
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("ru = 'Выезд до '; en = 'Check-out to '; de = 'Check-out bis '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
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
// Runs report and returns if report form should be shown
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qFolioCurrency", FolioCurrency);
	ReportBuilder.Parameters.Insert("qBalancePeriodTo", '39991231235959');
	ReportBuilder.Parameters.Insert("qCustomAttribute1", CustomAttribute1);
	ReportBuilder.Parameters.Insert("qCustomAttribute2", CustomAttribute2);
	ReportBuilder.Parameters.Insert("qCustomAttribute3", CustomAttribute3);
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", ShowMainRoomGuestsOnly);
	ReportBuilder.Parameters.Insert("qFolioDescription", FolioDescription);
	ReportBuilder.Parameters.Insert("qPaymentSection", PaymentSection);
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
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
	|	CAST(RoomInventoryMovements.Recorder AS Document.Accommodation) AS Recorder,
	|	CAST(RoomInventoryMovements.Recorder AS Document.Accommodation).Number AS DocumentNumber,
	|	CAST(RoomInventoryMovements.Recorder AS Document.Accommodation).AccommodationTemplate AS AccommodationTemplate,
	|	RoomInventoryMovements.Hotel AS DocumentHotel,
	|	RoomInventoryMovements.Room AS Room,
	|	RoomInventoryMovements.RoomType AS RoomType,
	|	MIN(RoomInventoryMovements.CheckInAccountingDate) AS CheckInAccountingDate,
	|	MAX(RoomInventoryMovements.CheckOutAccountingDate) AS CheckOutAccountingDate,
	|	SUM(RoomInventoryMovements.ExpectedGuestsCheckedOut) AS GuestsCheckedOut,
	|	SUM(RoomInventoryMovements.ExpectedRoomsCheckedOut) AS RoomsCheckedOut,
	|	SUM(RoomInventoryMovements.ExpectedBedsCheckedOut) AS BedsCheckedOut,
	|	SUM(RoomInventoryMovements.ExpectedAdditionalBedsCheckedOut) AS AdditionalBedsCheckedOut
	|INTO RoomInventoryTurnovers
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventoryMovements
	|WHERE
	|	RoomInventoryMovements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RoomInventoryMovements.Recorder REFS Document.Accommodation
	|	AND RoomInventoryMovements.IsAccommodation
	|	AND RoomInventoryMovements.IsInHouse
	|	AND RoomInventoryMovements.IsCheckOut
	|	AND CASE
	|			WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|				THEN RoomInventoryMovements.Hotel IN HIERARCHY (&qHotel)
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qRoom <> VALUE(Catalog.Rooms.EmptyRef)
	|				THEN RoomInventoryMovements.Room IN HIERARCHY (&qRoom)
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qRoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				THEN RoomInventoryMovements.RoomType IN HIERARCHY (&qRoomType)
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qCustomer <> VALUE(Catalog.Customers.EmptyRef)
	|				THEN RoomInventoryMovements.Customer IN HIERARCHY (&qCustomer)
	|			ELSE TRUE
	|		END
	|	AND RoomInventoryMovements.Period = RoomInventoryMovements.CheckOutDate
	|	AND RoomInventoryMovements.PeriodTo <= &qPeriodTo
	|	AND RoomInventoryMovements.CheckOutDate <= &qPeriodTo
	|
	|GROUP BY
	|	RoomInventoryMovements.Recorder,
	|	RoomInventoryMovements.Hotel,
	|	RoomInventoryMovements.Room,
	|	RoomInventoryMovements.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Folio.Ref AS Ref,
	|	RoomInventoryTurnovers.Recorder AS ParentDoc
	|INTO FolioList
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|		INNER JOIN RoomInventoryTurnovers AS RoomInventoryTurnovers
	|		ON (CAST(Folio.ParentDoc AS Document.Accommodation).Number = RoomInventoryTurnovers.DocumentNumber)
	|			AND (CAST(Folio.ParentDoc AS Document.Accommodation).Hotel = RoomInventoryTurnovers.DocumentHotel)
	|WHERE
	|	&qShowMainRoomGuestsOnly
	|	AND ISNULL(Customers.IsIndividual, TRUE)
	|	AND CASE
	|			WHEN &qFolioCurrency <> VALUE(Catalog.Currencies.EmptyRef)
	|				THEN Folio.FolioCurrency = &qFolioCurrency
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qPaymentSection <> VALUE(Catalog.PaymentSections.EmptyRef)
	|				THEN Folio.PaymentSection = &qPaymentSection
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qFolioDescription <> """"
	|				THEN Folio.Description = &qFolioDescription
	|			ELSE TRUE
	|		END
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref,
	|	RoomInventoryTurnovers.Recorder
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|		INNER JOIN RoomInventoryTurnovers AS RoomInventoryTurnovers
	|		ON (CAST(Folio.ParentDoc AS Document.Reservation).Number = RoomInventoryTurnovers.DocumentNumber)
	|			AND (CAST(Folio.ParentDoc AS Document.Accommodation).Hotel = RoomInventoryTurnovers.DocumentHotel)
	|WHERE
	|	&qShowMainRoomGuestsOnly
	|	AND ISNULL(Customers.IsIndividual, TRUE)
	|	AND CASE
	|			WHEN &qFolioCurrency <> VALUE(Catalog.Currencies.EmptyRef)
	|				THEN Folio.FolioCurrency = &qFolioCurrency
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qPaymentSection <> VALUE(Catalog.PaymentSections.EmptyRef)
	|				THEN Folio.PaymentSection = &qPaymentSection
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qFolioDescription <> """"
	|				THEN Folio.Description = &qFolioDescription
	|			ELSE TRUE
	|		END
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref,
	|	RoomInventoryTurnovers.Recorder
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|		INNER JOIN RoomInventoryTurnovers AS RoomInventoryTurnovers
	|		ON Folio.ParentDoc = RoomInventoryTurnovers.Recorder
	|WHERE
	|	NOT &qShowMainRoomGuestsOnly
	|	AND ISNULL(Customers.IsIndividual, TRUE)
	|	AND CASE
	|			WHEN &qFolioCurrency <> VALUE(Catalog.Currencies.EmptyRef)
	|				THEN Folio.FolioCurrency = &qFolioCurrency
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qPaymentSection <> VALUE(Catalog.PaymentSections.EmptyRef)
	|				THEN Folio.PaymentSection = &qPaymentSection
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qFolioDescription <> """"
	|				THEN Folio.Description = &qFolioDescription
	|			ELSE TRUE
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.FolioCurrency AS FolioCurrency,
	|	FoliosList.ParentDoc AS FolioParentDoc,
	|	SUM(AccountsBalance.SumBalance) AS ClientSumBalance
	|INTO ClientBalances
	|FROM
	|	AccumulationRegister.Accounts.Balance(
	|			&qBalancePeriodTo,
	|			Folio IN
	|				(SELECT
	|					FolioList.Ref AS Ref
	|				FROM
	|					FolioList AS FolioList)) AS AccountsBalance
	|		INNER JOIN FolioList AS FoliosList
	|		ON AccountsBalance.Folio = FoliosList.Ref
	|
	|GROUP BY
	|	AccountsBalance.FolioCurrency,
	|	FoliosList.ParentDoc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.Recorder.Hotel AS Hotel,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.Recorder.Customer AS Customer,
	|	RoomInventory.Recorder.AccommodationStatus AS AccommodationStatus,
	|	RoomInventory.Recorder.Guest AS Guest,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.Duration AS Duration,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.Recorder.AccommodationType AS AccommodationType,
	|	RoomInventory.Recorder.RoomRate AS RoomRate,
	|	RoomInventory.Recorder.Remarks AS Remarks,
	|	RoomInventory.Recorder.GuestGroup AS GuestGroup,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) + ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) + ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) + ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)
	|		ELSE RoomInventory.InHouseGuests
	|	END AS InHouseGuests,
	|	ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) AS NumberOfAdults,
	|	ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) AS NumberOfTeenagers,
	|	ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) AS NumberOfChildren,
	|	ISNULL(RoomInventory.Recorder.NumberOfInfants, 0) AS NumberOfInfants,
	|	RoomInventory.InHouseRooms AS InHouseRooms,
	|	RoomInventory.InHouseBeds AS InHouseBeds,
	|	RoomInventory.InHouseAdditionalBeds AS InHouseAdditionalBeds,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	RoomInventory.FolioCurrency AS FolioCurrency,
	|	RoomInventory.ClientSumBalance AS ClientSumBalance
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
	|	(HOUR(RoomInventory.Recorder.CheckOutDate)) AS CheckOutHour,
	|	(DAY(RoomInventory.Recorder.CheckOutDate)) AS CheckOutDay,
	|	(WEEK(RoomInventory.Recorder.CheckOutDate)) AS CheckOutWeek,
	|	(MONTH(RoomInventory.Recorder.CheckOutDate)) AS CheckOutMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckOutDate)) AS CheckOutQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckOutDate)) AS CheckOutYear,
	|	RoomType.* AS RoomType,
	|	AccommodationType.* AS AccommodationType,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	InHouseGuests,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	InHouseRooms,
	|	InHouseBeds,
	|	InHouseAdditionalBeds,
	|	Remarks AS Remarks,
	|	RoomInventory.Recorder.Car AS Car,
	|	GuestGroup.* AS GuestGroup,
	|	AccommodationStatus.* AS AccommodationStatus,
	|	RoomInventory.Recorder.IsMaster AS IsMaster,
	|	RoomInventory.Recorder.HotelProduct AS HotelProduct,
	|	RoomInventory.Recorder.RoomQuota AS RoomQuota,
	|	RoomInventory.Recorder.MarketingCode AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness AS SourceOfBusiness,
	|	RoomInventory.Recorder.DiscountCard AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType AS DiscountType,
	|	RoomInventory.Recorder.Discount AS Discount,
	|	RoomInventory.Recorder.AgentCommission AS AgentCommission,
	|	RoomInventory.Recorder.AgentCommissionType AS AgentCommissionType,
	|	RoomInventory.Recorder.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	RoomInventory.Recorder.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	RoomInventory.Recorder.ParentDoc AS ParentDoc,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.Recorder.PointInTime AS PointInTime,
	|	RoomInventory.ClientSumBalance AS ClientSumBalance,
	|	RoomInventory.FolioCurrency.* AS FolioCurrency,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}
	|FROM
	|	(SELECT
	|		RoomInventoryTurnovers.Recorder AS Recorder,
	|		RoomInventoryTurnovers.Room AS Room,
	|		RoomInventoryTurnovers.RoomType AS RoomType,
	|		ClientBalances.FolioCurrency AS FolioCurrency,
	|		RoomInventoryTurnovers.CheckInAccountingDate AS CheckInAccountingDate,
	|		RoomInventoryTurnovers.CheckOutAccountingDate AS CheckOutAccountingDate,
	|		RoomInventoryTurnovers.GuestsCheckedOut AS InHouseGuests,
	|		CASE
	|			WHEN RoomInventoryTurnovers.RoomsCheckedOut < 0
	|				THEN 0
	|			ELSE RoomInventoryTurnovers.RoomsCheckedOut
	|		END AS InHouseRooms,
	|		RoomInventoryTurnovers.BedsCheckedOut AS InHouseBeds,
	|		RoomInventoryTurnovers.AdditionalBedsCheckedOut AS InHouseAdditionalBeds,
	|		ISNULL(ClientBalances.ClientSumBalance, 0) AS ClientSumBalance
	|	FROM
	|		RoomInventoryTurnovers AS RoomInventoryTurnovers
	|			LEFT JOIN ClientBalances AS ClientBalances
	|			ON RoomInventoryTurnovers.Recorder = ClientBalances.FolioParentDoc
	|	WHERE
	|		CASE
	|				WHEN &qShowMainRoomGuestsOnly
	|					THEN RoomInventoryTurnovers.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|				ELSE TRUE
	|			END) AS RoomInventory
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
	|{WHERE
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.Recorder.Hotel.* AS Hotel,
	|	RoomInventory.RoomType.* AS RoomType,
	|	RoomInventory.Room.* AS Room,
	|	RoomInventory.Recorder.Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.GuestGroup.* AS GuestGroup,
	|	RoomInventory.Recorder.ParentDoc.* AS ParentDoc,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	RoomInventory.Recorder.AccommodationStatus.* AS AccommodationStatus,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.Duration AS Duration,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(CASE
	|			WHEN &qShowMainRoomGuestsOnly
	|				THEN ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) + ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) + ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) + ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)
	|			ELSE RoomInventory.InHouseGuests
	|		END) AS InHouseGuests,
	|	(ISNULL(RoomInventory.Recorder.NumberOfAdults, 0)) AS NumberOfAdults,
	|	(ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0)) AS NumberOfTeenagers,
	|	(ISNULL(RoomInventory.Recorder.NumberOfChildren, 0)) AS NumberOfChildren,
	|	(ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)) AS NumberOfInfants,
	|	RoomInventory.InHouseRooms AS InHouseRooms,
	|	RoomInventory.InHouseBeds AS InHouseBeds,
	|	RoomInventory.InHouseAdditionalBeds AS InHouseAdditionalBeds,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.Guest.* AS Guest,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.RoomRate.* AS RoomRate,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.DiscountCard AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType AS DiscountType,
	|	RoomInventory.Recorder.Discount AS Discount,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	RoomInventory.Recorder.Car AS Car,
	|	RoomInventory.Recorder.Remarks AS Remarks,
	|	RoomInventory.Recorder.AgentCommission AS AgentCommission,
	|	RoomInventory.Recorder.AgentCommissionType AS AgentCommissionType,
	|	RoomInventory.Recorder.IsMaster AS IsMaster,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomInventory.FolioCurrency.* AS FolioCurrency,
	|	RoomInventory.ClientSumBalance AS ClientSumBalance,
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
	|	Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	Guest.* AS Guest,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
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
	|	InHouseGuests,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	InHouseRooms,
	|	InHouseBeds,
	|	InHouseAdditionalBeds,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckOutDate)) AS CheckOutHour,
	|	(DAY(RoomInventory.Recorder.CheckOutDate)) AS CheckOutDay,
	|	(WEEK(RoomInventory.Recorder.CheckOutDate)) AS CheckOutWeek,
	|	(MONTH(RoomInventory.Recorder.CheckOutDate)) AS CheckOutMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckOutDate)) AS CheckOutQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckOutDate)) AS CheckOutYear,
	|	RoomInventory.Recorder.RoomQuota AS RoomQuota,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	FolioCurrency.* AS FolioCurrency,
	|	ClientSumBalance AS ClientSumBalance,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}
	|TOTALS
	|	SUM(InHouseGuests),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants),
	|	SUM(InHouseRooms),
	|	SUM(InHouseBeds),
	|	SUM(InHouseAdditionalBeds)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Room
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckOutDate)) AS CheckOutHour,
	|	(DAY(RoomInventory.Recorder.CheckOutDate)) AS CheckOutDay,
	|	(WEEK(RoomInventory.Recorder.CheckOutDate)) AS CheckOutWeek,
	|	(MONTH(RoomInventory.Recorder.CheckOutDate)) AS CheckOutMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckOutDate)) AS CheckOutQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckOutDate)) AS CheckOutYear,
	|	RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	GuestGroup.* AS GuestGroup,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	AccommodationStatus.* AS AccommodationStatus,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomInventory.Recorder.DiscountCard AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType AS DiscountType,
	|	RoomInventory.Recorder.* AS Recorder,
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
	ReportBuilder.HeaderText = NStr("EN='Expected check-out';RU='Планируемый выезд';de='Geplante Abreise'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
