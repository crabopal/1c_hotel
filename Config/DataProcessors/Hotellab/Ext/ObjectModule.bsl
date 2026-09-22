#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameter
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

//  -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Structure - Parameter
//  pIsInteractive	 - Boolean	 - IsInteractive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	If UseToExportPrices Then
		UnloadPrices(pParameter, pIsInteractive);
		If ValueIsFilled(InteractionParameters.WebhookURL) Then
			UnloadInventoryDailyAvailability(pParameter, pIsInteractive);	
		EndIf;
	Else
		UnloadReservations(pParameter, pIsInteractive);	
	EndIf;
EndProcedure // pmRun

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure UnloadPrices(pParameter, pIsInteractive)
	vPeriodFrom = BegOfDay(CurrentSessionDate()); 
	If ValueIsFilled(RoomRate.DateValidTo) And vPeriodFrom <= BegOfDay(RoomRate.DateValidTo) Then
		vPeriodTo = Min(BegOfDay(vPeriodFrom + (NumberOfDaysToExportPrices * 24 * 3600)), BegOfDay(RoomRate.DateValidTo));
	Else
		vPeriodTo = BegOfDay(vPeriodFrom + (NumberOfDaysToExportPrices * 24 * 3600));	
	EndIf;
	
	If pIsInteractive And pParameter <> Undefined Then
		vPeriodFrom = pParameter.PeriodFrom; 
		vPeriodTo = pParameter.PeriodTo;
	EndIf; 
	
	If RoomRate.UsePricesFromCalendar Then
		vCalendarDays = GetCalendarDaysPricesFromCalendar(vPeriodFrom, vPeriodTo);
		vByPrice = True;
	Else
		vCalendarDays = GetCalendarDays(vPeriodFrom, vPeriodTo);
		vByPrice = False;
	EndIf;
	
	vCountCalendarDays = vCalendarDays.Count(); 
	If vCountCalendarDays > 0 Then
		vResult = New Array;
		
		For Each vRow In vCalendarDays Do	
			If vRow.CalendarDayType <> Null Then 
				vResult.Add(New Structure("date, category, ratecode, guests, price", 
				BegOfDay(vRow.AccountingDate), 
				TrimAll(vRow.RoomType.Code), 
				TrimAll(RoomRate.Code), 
				vRow.RoomType.NumberOfBedsPerRoom, 
				?(vByPrice, Format(vRow.CalendarDayPrice, "ND=17; NFD=2; NDS=; NGS=; NZ=0,00; NG="), TrimAll(vRow.CalendarDayType.Description))));
			EndIf;
		EndDo;
		
		vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vResult, "DF='yyyy-MM-dd'");
		
		vResultRequest = SendHTTPRequest(vResponseBody, vCountCalendarDays);
	EndIf;

EndProcedure // UnloadReservations

// -----------------------------------------------------------------------------
Function GetCalendarDays(pPeriodFrom, pPeriodTo)
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	RoomTypes.Ref AS RoomType,
	|	CalendarDays.AccountingDate AS AccountingDate,
	|	CASE
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|			THEN CalendarDays.CalendarDayType
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|			THEN CalendarDays.CalendarDayType
	|		ELSE CalendarDaysByRoomTypes.CalendarDayType
	|	END AS CalendarDayType
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(
	|				,
	|				AccountingDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|					AND Calendar = &qCalendar) AS CalendarDays
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
	|				,
	|				AccountingDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|					AND Calendar = &qCalendar) AS CalendarDaysByRoomTypes
	|		ON RoomTypes.Ref = CalendarDaysByRoomTypes.RoomType
	|			AND (CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate)
	|WHERE
	|	NOT RoomTypes.IsFolder
	|	AND NOT RoomTypes.DeletionMark
	|	AND RoomTypes.Owner = &qHotel
	|	AND CASE
	|			WHEN CalendarDaysByRoomTypes.CalendarDayType.Code IS NULL
	|				THEN NOT CalendarDays.CalendarDayType.IsFolder
	|			ELSE NOT CalendarDaysByRoomTypes.CalendarDayType.IsFolder
	|		END
	|
	|ORDER BY
	|	RoomTypes.SortCode,
	|	CalendarDays.AccountingDate";
	vQ.SetParameter("qCalendar", RoomRate.Calendar);
	vQ.SetParameter("qHotel", InteractionParameters.Hotel);
	vQ.SetParameter("qPeriodFrom", pPeriodFrom);
	vQ.SetParameter("qPeriodTo", pPeriodTo);
	Return vQ.Execute().Unload();
EndFunction // GetCalendarDays

// -----------------------------------------------------------------------------
Function GetCalendarDaysPricesFromCalendar(pPeriodFrom, pPeriodTo)
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	RoomTypes.Ref AS RoomType,
	|	CalendarDays.AccountingDate AS AccountingDate,
	|	CASE
	|		WHEN CalendarDaysByRoomTypes.RoomPrice IS NULL
	|			THEN CalendarDays.RoomPrice
	|		WHEN CalendarDaysByRoomTypes.RoomPrice = 0
	|			THEN CalendarDays.RoomPrice
	|		ELSE CalendarDaysByRoomTypes.RoomPrice
	|	END AS CalendarDayPrice,
	|	1 AS CalendarDayType
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(
	|				,
	|				AccountingDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|					AND Calendar = &qCalendar) AS CalendarDays
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
	|				,
	|				AccountingDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|					AND Calendar = &qCalendar) AS CalendarDaysByRoomTypes
	|		ON RoomTypes.Ref = CalendarDaysByRoomTypes.RoomType
	|			AND (CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate)
	|WHERE
	|	NOT RoomTypes.IsFolder
	|	AND NOT RoomTypes.DeletionMark
	|	AND RoomTypes.Owner = &qHotel
	|
	|ORDER BY
	|	RoomTypes.SortCode,
	|	CalendarDays.AccountingDate";
	vQ.SetParameter("qCalendar", RoomRate.Calendar);
	vQ.SetParameter("qHotel", InteractionParameters.Hotel);
	vQ.SetParameter("qPeriodFrom", pPeriodFrom);
	vQ.SetParameter("qPeriodTo", pPeriodTo);
	Return vQ.Execute().Unload();
EndFunction // GetCalendarDaysPricesFromCalendar

// -----------------------------------------------------------------------------
Procedure UnloadReservations(pParameter, pIsInteractive)
	vResult = New Map;
	vCurrentSessionDate = CurrentSessionDate();
	vResult.Insert("Success", True);
	vResult.Insert("Error", "");
	vResultRequest = Undefined;

	vDailyRatesTable = New ValueTable();
	vDailyRatesTable.Columns.Add("AccountingDate", New TypeDescription("Date",,,,, New DateQualifiers(DateFractions.DateTime)));
	vDailyRatesTable.Columns.Add("DailyRates", New TypeDescription("Number",,, New NumberQualifiers(17, 2)));

	vDailyExtrasTable = New ValueTable();
	vDailyExtrasTable.Columns.Add("AccountingDate", New TypeDescription("Date",,,,, New DateQualifiers(DateFractions.DateTime)));
	vDailyExtrasTable.Columns.Add("DailyExtras", New TypeDescription("Number",,, New NumberQualifiers(17, 2)));
	
	vRoomHistoryTable = New ValueTable();
	vRoomHistoryTable.Columns.Add("AccountingDate", New TypeDescription("Date",,,,, New DateQualifiers(DateFractions.DateTime)));
	vRoomHistoryTable.Columns.Add("RoomHistory", New TypeDescription("String",,,, New StringQualifiers(0)));
	                                                                  
	vPeriodFrom = InteractionParameters.LastFullSynchronizationTime; 
	vPeriodTo = '00010101';
	vUnLoadFromCheckInDate = False; 
	
	If pIsInteractive And pParameter <> Undefined Then
		vPeriodFrom = pParameter.PeriodFrom; 
		vPeriodTo = pParameter.PeriodTo;
		vUnLoadFromCheckInDate = pParameter.UnLoadFromCheckInDate;
	EndIf;
	
	vMainRoomReservations = Undefined;
	vDataReservations = GetChangedReservations(vPeriodFrom, vPeriodTo, vUnLoadFromCheckInDate, InteractionParameters.Hotel, vMainRoomReservations);
	If vDataReservations.Count() > 0 Then  
		If vMainRoomReservations = Undefined Then
			vMainRoomReservations = vDataReservations.Copy();
			vMainRoomReservations.GroupBy("DocNumber, GuestGroup");
		EndIf;
		vReservations = New Map();
		vReservations.Insert("reservations", New Array()); 
		For Each vRow In vMainRoomReservations Do
			vDataFilled = False;
			vCheckMainReservation = vDataReservations.FindRows(New Structure("DocNumber, GuestGroup, MainRoomReservation", vRow.DocNumber, vRow.GuestGroup, 0)).Count() > 0;  
			vDataReservationsArr = vDataReservations.FindRows(New Structure("DocNumber, GuestGroup", vRow.DocNumber, vRow.GuestGroup));
			vDataRequestResult = GetStructureRequest();
			vDailyRatesTable.Clear();
			vDailyExtrasTable.Clear();
			vRoomHistoryTable.Clear();
			For Each vDataReservationsRow In vDataReservationsArr Do
				If Not vDataFilled And (vDataReservationsRow.MainRoomReservation = 0 And vCheckMainReservation Or Not vCheckMainReservation) Then
					FillPropertyValues(vDataRequestResult, vDataReservationsRow,, "ArrivalDate, DepartureDate, Adults");
					vDataRequestResult.ConfNumber = String(vDataReservationsRow.DocRef.UUID());
					If ValueIsFilled(vDataReservationsRow.Room) Then
						vDataRequestResult.Room = TrimAll(vDataReservationsRow.Room);
					Else
						vDataRequestResult.Room = TrimAll(vDataReservationsRow.DocNumber);
					EndIf;
					If Not ValueIsFilled(vDataRequestResult.PriceRoomType) Then
						vDataRequestResult.PriceRoomType = vDataRequestResult.RoomType;
					EndIf;
					vDataFilled = True;
				EndIf;  
				vDataRequestResult.Adults = vDataRequestResult.Adults + vDataReservationsRow.Adults; 
				If ValueIsFilled(vDataRequestResult.ArrivalDate) Then 
					vDataRequestResult.ArrivalDate = Min(vDataRequestResult.ArrivalDate, vDataReservationsRow.ArrivalDate);
				Else
					vDataRequestResult.ArrivalDate = vDataReservationsRow.ArrivalDate;	
				EndIf;
				If ValueIsFilled(vDataRequestResult.DepartureDate) Then
					vDataRequestResult.DepartureDate = Max(vDataRequestResult.DepartureDate, vDataReservationsRow.DepartureDate);
				Else
					vDataRequestResult.DepartureDate = vDataReservationsRow.DepartureDate;	
				EndIf;
				If vDataReservationsRow.Services <> Undefined Then
					FillRates(vDataReservationsRow.Services, vDataReservationsRow.ArrivalDate, vDataReservationsRow.DepartureDate,?(vDataReservationsRow.NoOfRooms > 0, vDataReservationsRow.NoOfRooms, 1), vDataRequestResult.Packages, vDataRequestResult.RateAmount, vDailyRatesTable, vDailyExtrasTable);
				EndIf;
				If vDataReservationsRow.RoomRates <> Undefined Then
					FillRoomHistory(vDataReservationsRow.Room, vDataReservationsRow.ArrivalDate, vDataReservationsRow.DepartureDate, vDataReservationsRow.RoomRates, vRoomHistoryTable);	
				EndIf;
			EndDo;
			vDailyRatesTable.Sort("AccountingDate");
			vDailyExtrasTable.Sort("AccountingDate");
			vDataRequestResult.DailyRates = vDailyRatesTable.UnloadColumn("DailyRates");
			vDataRequestResult.DailyExtras = vDailyExtrasTable.UnloadColumn("DailyExtras");
			If ExportRoomChanges Then 
				vRoomHistoryTable.Sort("AccountingDate");
				vDataRequestResult.Insert("RoomHistory", vRoomHistoryTable.UnloadColumn("RoomHistory"));	
			EndIf;
			vReservations["reservations"].Add(vDataRequestResult);
			If ExportSharedGuests Then
				For Each vDataReservationsRow In vDataReservationsArr Do   
					vConfNumber = String(vDataReservationsRow.DocRef.UUID()); 
					If vDataRequestResult.ConfNumber <> vConfNumber Then
						vSharedDataRequestResult = GetStructureRequest();
						If ExportRoomChanges Then
							vSharedDataRequestResult.Insert("RoomHistory", New Array);	
						EndIf;
						FillPropertyValues(vSharedDataRequestResult, vDataRequestResult,, "DailyRates, DailyExtras");
						vSharedDataRequestResult.Room = TrimAll(vDataReservationsRow.DocNumber);
						vSharedDataRequestResult.ConfNumber = vConfNumber;
						For Each vDailyRatesRow In vDataRequestResult.DailyRates Do
							vSharedDataRequestResult.DailyRates.Add(0);	
						EndDo;
						For Each vDailyExtrasRow In vDataRequestResult.DailyExtras Do
							vSharedDataRequestResult.DailyExtras.Add(0);	
						EndDo;
						vSharedDataRequestResult.RateAmount = 0;
						vSharedDataRequestResult.Packages = 0;
						vReservations["reservations"].Add(vSharedDataRequestResult);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		vResult.Insert("DataRequestResult", vReservations);	
		
		vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vResult, "DF='yyyy-MM-ddTHH:mm:ss'");
		
		vResultRequest = SendHTTPRequest(vResponseBody);
	EndIf;
	If Not pIsInteractive And vDataReservations.Count() > 0 Then
		vRequestMap = New Map();
		If ValueIsFilled(vResultRequest.Body) Then
			Try
				vRequestMap = Catalogs.DataConvertationRules.JSONtoMap(vResultRequest.Body);	
			Except
				vRequestMap = New Map();
			EndTry;
			If vRequestMap["success"] <> Undefined And vRequestMap["success"] Then 
				vObj 								= InteractionParameters.GetObject();
				vObj.LastFullSynchronizationTime 	= vCurrentSessionDate; 
				vObj.Write();
			EndIf;
		EndIf;
	EndIf;	
EndProcedure // UnloadReservations

// -----------------------------------------------------------------------------
Function GetChangedReservations(pPeriodFrom, pPeriodTo, pUnLoadFromCheckInDate, pHotel, rMainRoomReservations)
	vDocQuery = New Query();
	If pUnLoadFromCheckInDate Then
		vDocQuery.Text = 
		"SELECT
		|	Docs.Number AS DocNumber,
		|	Docs.GuestGroup AS GuestGroup
		|FROM
		|	(SELECT
		|		Accommodation.Number AS Number,
		|		Accommodation.GuestGroup AS GuestGroup
		|	FROM
		|		Document.Accommodation AS Accommodation
		|	WHERE
		|		Accommodation.Hotel = &qHotel
		|		AND NOT Accommodation.DeletionMark
		|		AND Accommodation.Posted
		|		AND Accommodation.CheckOutDate > &qPeriodFrom
		|		AND CASE
		|				WHEN &qPeriodTo <> DATETIME(1, 1, 1, 0, 0, 0)
		|					THEN Accommodation.CheckInDate < &qPeriodTo
		|				ELSE TRUE
		|			END
		|		AND Accommodation.AccommodationStatus.IsActive
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Reservation.Number,
		|		Reservation.GuestGroup
		|	FROM
		|		Document.Reservation AS Reservation
		|	WHERE
		|		Reservation.Hotel = &qHotel
		|		AND NOT Reservation.DeletionMark
		|		AND Reservation.Posted
		|		AND Reservation.CheckOutDate > &qPeriodFrom
		|		AND CASE
		|				WHEN &qPeriodTo <> DATETIME(1, 1, 1, 0, 0, 0)
		|					THEN Reservation.CheckInDate < &qPeriodTo
		|				ELSE TRUE
		|			END
		|		AND NOT Reservation.ReservationStatus.IsCheckIn) AS Docs
		|
		|GROUP BY
		|	Docs.Number,
		|	Docs.GuestGroup"; 
	Else
		vDocQuery.Text = 
		"SELECT
		|	Docs.Number AS DocNumber,
		|	Docs.GuestGroup AS GuestGroup
		|FROM
		|	(SELECT
		|		AccommodationChangeHistorySliceLast.Number AS Number,
		|		AccommodationChangeHistorySliceLast.GuestGroup AS GuestGroup
		|	FROM
		|		InformationRegister.AccommodationChangeHistory.SliceLast(
		|				&qPeriodTo,
		|				Period >= &qPeriodFrom
		|					AND Hotel = &qHotel
		|					AND NOT Accommodation.DeletionMark
		|					AND Accommodation.Posted
		|					AND AccommodationStatus.IsActive) AS AccommodationChangeHistorySliceLast
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationChangeHistorySliceLast.Number,
		|		ReservationChangeHistorySliceLast.GuestGroup
		|	FROM
		|		InformationRegister.ReservationChangeHistory.SliceLast(
		|				&qPeriodTo,
		|				Period >= &qPeriodFrom
		|					AND Hotel = &qHotel
		|					AND Reservation.Posted
		|					AND NOT Reservation.DeletionMark
		|					AND NOT ReservationStatus.IsCheckIn) AS ReservationChangeHistorySliceLast) AS Docs
		|
		|GROUP BY
		|	Docs.Number,
		|	Docs.GuestGroup"; 
	EndIf;
	vDocQuery.SetParameter("qPeriodFrom", pPeriodFrom);
	vDocQuery.SetParameter("qPeriodTo", pPeriodTo);
	vDocQuery.SetParameter("qHotel", pHotel);
	rMainRoomReservations = vDocQuery.Execute().Unload();	
	
	vQuery = New Query();
	vQuery.Text = 
		"SELECT
		|	DocsList.DocNumber AS DocNumber,
		|	DocsList.GuestGroup AS GuestGroup
		|INTO DocsList
		|FROM
		|	&qDocsList AS DocsList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Docs.DocRef AS DocRef,
		|	Docs.DocNumber AS DocNumber,
		|	Docs.Room AS Room,
		|	Docs.AccommodationType AS AccommodationType,
		|	Docs.CreationDate AS CreationDate,
		|	Docs.GuestGroup AS GuestGroup,
		|	Docs.ArrivalDate AS ArrivalDate,
		|	Docs.DepartureDate AS DepartureDate,
		|	Docs.ReservationStatus AS ReservationStatus,
		|	Docs.RoomType AS RoomType,
		|	Docs.PriceRoomType AS PriceRoomType,
		|	Docs.RoomRate AS RoomRate,
		|	Docs.Adults AS Adults,
		|	Docs.Children AS Children,
		|	Docs.GroupNameID AS GroupNameID,
		|	Docs.SourceCode AS SourceCode,
		|	Docs.CancellationDate AS CancellationDate,
		|	Docs.NoOfRooms AS NoOfRooms,
		|	Docs.CompanyName AS CompanyName,
		|	Docs.Market AS Market,
		|	Docs.MainRoomReservation AS MainRoomReservation,
		|	Docs.Services.(
		|		Service AS Service,
		|		AccountingDate AS AccountingDate,
		|		FolioCurrency AS FolioCurrency,
		|		Sum AS Sum,
		|		DiscountSum AS DiscountSum,
		|		IsInPrice AS IsInPrice,
		|		IsRoomRevenue AS IsRoomRevenue
		|	) AS Services,
		|	Docs.RoomRates.(
		|		AccountingDate AS AccountingDate,
		|		Room AS Room
		|	) AS RoomRates
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN NOT Accommodation.Reservation.Number IS NULL
		|				THEN Accommodation.Reservation
		|			ELSE Accommodation.Ref
		|		END AS DocRef,
		|		Accommodation.Number AS DocNumber,
		|		Accommodation.Room AS Room,
		|		Accommodation.AccommodationType.Type AS AccommodationType,
		|		CASE
		|			WHEN NOT Accommodation.Reservation.Number IS NULL
		|				THEN Accommodation.Reservation.Date
		|			ELSE Accommodation.Date
		|		END AS CreationDate,
		|		Accommodation.GuestGroup AS GuestGroup,
		|		Accommodation.CheckInDate AS ArrivalDate,
		|		Accommodation.CheckOutDate AS DepartureDate,
		|		Accommodation.AccommodationStatus AS ReservationStatus,
		|		Accommodation.RoomType AS RoomType,
		|		Accommodation.RoomTypeUpgrade AS PriceRoomType,
		|		Accommodation.RoomRate AS RoomRate,
		|		Accommodation.NumberOfPersons AS Adults,
		|		Accommodation.NumberOfTeenagers + Accommodation.NumberOfChildren + Accommodation.NumberOfInfants AS Children,
		|		CASE
		|			WHEN Accommodation.GuestGroup.GroupType <> VALUE(Catalog.GroupTypes.EmptyRef)
		|				THEN Accommodation.GuestGroup
		|			ELSE """"
		|		END AS GroupNameID,
		|		Accommodation.SourceOfBusiness AS SourceCode,
		|		NULL AS CancellationDate,
		|		1 AS NoOfRooms,
		|		CASE
		|			WHEN NOT Accommodation.Number IS NULL
		|					AND NOT ISNULL(Accommodation.Customer.IsIndividual, TRUE)
		|				THEN Accommodation.Customer.Description
		|			ELSE """"
		|		END AS CompanyName,
		|		Accommodation.MarketingCode AS Market,
		|		CASE
		|			WHEN Accommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|					OR Accommodation.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|						AND (Accommodation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
		|							OR Accommodation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds))
		|				THEN 0
		|			ELSE 1
		|		END AS MainRoomReservation,
		|		Accommodation.Services.(
		|			Service AS Service,
		|			AccountingDate AS AccountingDate,
		|			FolioCurrency AS FolioCurrency,
		|			Sum AS Sum,
		|			DiscountSum AS DiscountSum,
		|			IsInPrice AS IsInPrice,
		|			IsRoomRevenue AS IsRoomRevenue
		|		) AS Services,
		|		Accommodation.RoomRates.(
		|			AccountingDate AS AccountingDate,
		|			Room AS Room
		|		) AS RoomRates
		|	FROM
		|		DocsList AS DocsList
		|			INNER JOIN Document.Accommodation AS Accommodation
		|			ON DocsList.DocNumber = Accommodation.Number
		|				AND DocsList.GuestGroup = Accommodation.GuestGroup
		|	WHERE
		|		Accommodation.Posted
		|		AND NOT Accommodation.DeletionMark
		|		AND Accommodation.AccommodationStatus.IsActive
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Reservation.Ref,
		|		Reservation.Number,
		|		Reservation.Room,
		|		Reservation.AccommodationType.Type,
		|		Reservation.Date,
		|		Reservation.GuestGroup,
		|		Reservation.CheckInDate,
		|		Reservation.CheckOutDate,
		|		Reservation.ReservationStatus,
		|		Reservation.RoomType,
		|		Reservation.RoomTypeUpgrade,
		|		Reservation.RoomRate,
		|		Reservation.NumberOfPersons,
		|		Reservation.NumberOfTeenagers + Reservation.NumberOfChildren + Reservation.NumberOfInfants,
		|		CASE
		|			WHEN Reservation.GuestGroup.GroupType <> VALUE(Catalog.GroupTypes.EmptyRef)
		|				THEN Reservation.GuestGroup
		|			ELSE """"
		|		END,
		|		Reservation.SourceOfBusiness,
		|		CASE
		|			WHEN Reservation.ReservationStatus.IsAnnulation
		|				THEN Reservation.DateOfAnnulation
		|			ELSE NULL
		|		END,
		|		Reservation.RoomQuantity,
		|		CASE
		|			WHEN NOT ISNULL(Reservation.Customer.IsIndividual, TRUE)
		|				THEN Reservation.Customer.Description
		|			ELSE """"
		|		END,
		|		Reservation.MarketingCode,
		|		CASE
		|			WHEN Reservation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|					OR Reservation.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|						AND (Reservation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
		|							OR Reservation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds))
		|				THEN 0
		|			ELSE 1
		|		END,
		|		Reservation.Services.(
		|			Service,
		|			AccountingDate,
		|			FolioCurrency,
		|			Sum,
		|			DiscountSum,
		|			IsInPrice,
		|			IsRoomRevenue
		|		),
		|		Reservation.RoomRates.(
		|			AccountingDate,
		|			Room
		|		)
		|	FROM
		|		DocsList AS DocsList
		|			INNER JOIN Document.Reservation AS Reservation
		|			ON DocsList.DocNumber = Reservation.Number
		|				AND DocsList.GuestGroup = Reservation.GuestGroup
		|	WHERE
		|		Reservation.Posted
		|		AND NOT Reservation.DeletionMark
		|		AND NOT Reservation.ReservationStatus.IsCheckIn) AS Docs
		|
		|ORDER BY
		|	CreationDate";
	vQuery.SetParameter("qDocsList", rMainRoomReservations);
	Return vQuery.Execute().Unload();
EndFunction // GetChangedReservations

// -----------------------------------------------------------------------------
Function GetStructureRequest()
	vDataRequestResult = New Structure();	
	vDataRequestResult.Insert("ConfNumber",);
	vDataRequestResult.Insert("CreationDate",);
	vDataRequestResult.Insert("ArrivalDate",);
	vDataRequestResult.Insert("DepartureDate",);
	vDataRequestResult.Insert("RateAmount", 0);
	vDataRequestResult.Insert("ReservationStatus",);
	vDataRequestResult.Insert("Room",);
	vDataRequestResult.Insert("RoomType",);
	vDataRequestResult.Insert("PriceRoomType",);
	vDataRequestResult.Insert("RoomRate",);
	vDataRequestResult.Insert("Adults", 0);
	vDataRequestResult.Insert("Children", 0);
	vDataRequestResult.Insert("SourceCode",);
	vDataRequestResult.Insert("GroupNameID",);
	vDataRequestResult.Insert("CancellationDate",);
	vDataRequestResult.Insert("NoOfRooms", 0);
	vDataRequestResult.Insert("Packages", 0);
	vDataRequestResult.Insert("DailyRates", New Array());
	vDataRequestResult.Insert("DailyExtras", New Array());
	vDataRequestResult.Insert("CompanyName",);
	vDataRequestResult.Insert("Market",);
	Return vDataRequestResult;
EndFunction // GetStructureRequest

// -----------------------------------------------------------------------------
Procedure FillRates(pServices, pArrivalDate, pDepartureDate, pNoOfRooms, rPackages, rRateAmount, rDailyRates, rDailyExtras)
	If rPackages = Undefined Then
		rPackages = 0;	
	EndIf;
	If rRateAmount = Undefined Then
		rRateAmount = 0;	
	EndIf;
	If BegOfDay(pArrivalDate) < BegOfDay(pDepartureDate) Then
		For Each vSrvRow In pServices Do
			vService = vSrvRow.Service;
			If ValueIsFilled(vService) And ValueIsFilled(vService.QuantityCalculationRule) And vService.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Breakfast Then
				vSrvRow.AccountingDate = vSrvRow.AccountingDate - 24*3600;
			EndIf;
		EndDo;
	EndIf;
	pServices.GroupBy("AccountingDate, FolioCurrency, IsInPrice, IsRoomRevenue", "Sum, DiscountSum");
	vSrvRows = pServices.FindRows(New Structure("AccountingDate, IsInPrice, IsRoomRevenue", BegOfDay(pArrivalDate), True, False));
	For Each vSrvRow In vSrvRows Do
		rPackages = rPackages + Round((vSrvRow.Sum - vSrvRow.DiscountSum)/pNoOfRooms, 2);
	EndDo;
	pServices.GroupBy("AccountingDate, FolioCurrency, IsInPrice", "Sum, DiscountSum");
	vSrvRows = pServices.FindRows(New Structure("AccountingDate, IsInPrice", BegOfDay(pArrivalDate), True));
	For Each vRow In vSrvRows Do
		rRateAmount = rRateAmount + Round((vRow.Sum - vRow.DiscountSum)/pNoOfRooms, 2);
	EndDo;
	For Each vRow In pServices Do
		vDailyRatesArr = rDailyRates.FindRows(New Structure("AccountingDate", vRow.AccountingDate)); 
		If vDailyRatesArr.Count() > 0 Then
			If vRow.IsInPrice Then
				vDailyRatesArr[0].DailyRates = rDailyRates[0].DailyRates + Round((vRow.Sum - vRow.DiscountSum)/pNoOfRooms, 2);	
			EndIf;
		Else
			vNewRow = rDailyRates.Add();
			vNewRow.AccountingDate = vRow.AccountingDate;
			If vRow.IsInPrice Then
				vNewRow.DailyRates = Round((vRow.Sum - vRow.DiscountSum)/pNoOfRooms, 2);
			Else
				vNewRow.DailyRates = 0;
			EndIf;
		EndIf;
		vDailyExtrasArr = rDailyExtras.FindRows(New Structure("AccountingDate", vRow.AccountingDate)); 
		If vDailyExtrasArr.Count() > 0 Then
			If Not vRow.IsInPrice Then
				vDailyExtrasArr[0].DailyExtras = rDailyExtras[0].DailyExtras + Round((vRow.Sum - vRow.DiscountSum)/pNoOfRooms, 2);	
			EndIf;
		Else
			vNewRow = rDailyExtras.Add();
			vNewRow.AccountingDate = vRow.AccountingDate;
			If Not vRow.IsInPrice Then
				vNewRow.DailyExtras = Round((vRow.Sum - vRow.DiscountSum)/pNoOfRooms, 2);
			Else
				vNewRow.DailyExtras = 0;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillRates

// -----------------------------------------------------------------------------
Procedure FillRoomHistory(Val pRoom, Val pCheckInDate, Val pCheckOutDate, pRoomRates, rRoomHistory)
	vCurRoom = pRoom;
	vCurDate = BegOfDay(pCheckInDate);
	vCheckOutDate = BegOfDay(pCheckOutDate);
	While vCurDate <= vCheckOutDate Do
		vRoomHistoryArr = rRoomHistory.FindRows(New Structure("AccountingDate", vCurDate));
		If vRoomHistoryArr.Count() = 0 Then
			vRoomRatesArr = pRoomRates.FindRows(New Structure("AccountingDate", vCurDate));
			If vRoomRatesArr.Count() > 0 Then
				For Each vRow In vRoomRatesArr Do
					If ValueIsFilled(vRow.Room) Then
						vCurRoom = vRow.Room;
						Break;
					EndIf;
				EndDo;
			EndIf; 
			vNewRow = rRoomHistory.Add();
			vNewRow.AccountingDate = vCurDate;
			vNewRow.RoomHistory = vCurRoom;
		EndIf;
		vCurDate = BegOfDay(vCurDate + 24 * 3600); 
	EndDo;
EndProcedure // FillRoomHistory

// -----------------------------------------------------------------------------
Procedure UnloadInventoryDailyAvailability(pParameter, pIsInteractive)
	vPeriodFrom = BegOfDay(CurrentSessionDate()); 
	If ValueIsFilled(RoomRate.DateValidTo) And vPeriodFrom <= BegOfDay(RoomRate.DateValidTo) Then
		vPeriodTo = Min(BegOfDay(vPeriodFrom + (NumberOfDaysToExportPrices * 24 * 3600)), BegOfDay(RoomRate.DateValidTo));
	Else
		vPeriodTo = BegOfDay(vPeriodFrom + (NumberOfDaysToExportPrices * 24 * 3600));	
	EndIf;
	
	If pIsInteractive And pParameter <> Undefined Then
		vPeriodFrom = pParameter.PeriodFrom; 
		vPeriodTo = pParameter.PeriodTo;
	EndIf; 
	
	vInventoryDailyAvailability = GetInventoryDailyAvailability(vPeriodFrom, vPeriodTo, InteractionParameters.Hotel);
	
	vCountInventoryDailyAvailability = vInventoryDailyAvailability.Count(); 
	If vCountInventoryDailyAvailability > 0 Then 
		vResult = New Array;
		
		For Each vRow In vInventoryDailyAvailability Do
			vResult.Add(New Structure("Date, Category, RoomsOut, AvailableRooms, Blocks, RoomsSoldIndividual, GrossRoomRevenueDeductedIndividual", 
										   BegOfDay(vRow.Period), 
										   TrimAll(vRow.RoomType.Description), 
										   vRow.RoomsOut, 
										   vRow.AvailableRooms, 
										   vRow.Blocks,
										   vRow.RoomsSoldIndividual,
										   vRow.GrossRoomRevenueDeductedIndividual));	
		EndDo; 
		
		vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vResult, "DF='yyyy-MM-dd'");
		vResultRequest = SendHTTPRequest(vResponseBody, vCountInventoryDailyAvailability, True);
	EndIf;
EndProcedure // UnloadInventoryDailyAvailability

// -----------------------------------------------------------------------------
Function GetInventoryDailyAvailability(pPeriodFrom, pPeriodTo, pHotel)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesByDates.Period AS Period,
	|	SUM(SalesByDates.RoomRevenueTurnover) AS RoomRevenue,
	|	SUM(SalesByDates.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SalesByDates.RoomType AS RoomType
	|INTO RoomSalesTurnovers
	|FROM
	|	(SELECT
	|		ChargedSales.Hotel AS Hotel,
	|		ChargedSales.Period AS Period,
	|		ChargedSales.RoomRevenueTurnover AS RoomRevenueTurnover,
	|		ChargedSales.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		ChargedSales.RoomType AS RoomType
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				Hotel = &qHotel
	|					AND NOT RoomType.DeletionMark) AS ChargedSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecast.Hotel,
	|		SalesForecast.Period,
	|		SalesForecast.RoomRevenueTurnover,
	|		SalesForecast.RoomsRentedTurnover,
	|		SalesForecast.RoomType
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Day,
	|				Hotel = &qHotel
	|					AND NOT RoomType.DeletionMark) AS SalesForecast) AS SalesByDates
	|
	|GROUP BY
	|	SalesByDates.Period,
	|	SalesByDates.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalanceAndTurnovers.Period AS Period,
	|	RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
	|	RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance AS AvailableRooms,
	|	-RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance AS RoomsOut,
	|	-RoomInventoryBalanceAndTurnovers.RoomsInQuotaClosingBalance AS Blocks,
	|	RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance AS RoomsVacant,
	|	RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|	ISNULL(RoomSalesTurnovers.RoomRevenue, 0) AS GrossRoomRevenueDeductedIndividual,
	|	ISNULL(RoomSalesTurnovers.RoomsRentedTurnover, 0) AS RoomsSoldIndividual
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel = &qHotel
	|				AND NOT RoomType.DeletionMark) AS RoomInventoryBalanceAndTurnovers
	|		LEFT JOIN RoomSalesTurnovers AS RoomSalesTurnovers
	|		ON RoomInventoryBalanceAndTurnovers.Period = RoomSalesTurnovers.Period
	|			AND RoomInventoryBalanceAndTurnovers.RoomType = RoomSalesTurnovers.RoomType
	|
	|ORDER BY
	|	Period,
	|	RoomInventoryBalanceAndTurnovers.RoomType.SortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo)); 
	vForecastStartDate = tcOnServer.GetForecastStartDate(pHotel);
	vQry.SetParameter("qForecastPeriodFrom", Max(BegOfDay(pPeriodFrom), BegOfDay(vForecastStartDate)));
	vQry.SetParameter("qForecastPeriodTo", Max(EndOfDay(pPeriodTo), EndOfDay(vForecastStartDate-24*3600)));
	Return vQry.Execute().Unload();
EndFunction // GetInventoryDailyAvailability

// -----------------------------------------------------------------------------
Function SendHTTPRequest(pRequestBody, pRequestCount = 0, pIsInventoryDailyAvailability = False)
	
	vResult = New Structure("StatusCode, Body, Error, Raw");

	Try           
		vHTTPServer = TrimAll(InteractionParameters.HTTPServer); 
		vRequestURL = TrimAll(InteractionParameters.HttpAddress);
		
		If UseToExportPrices And Not pIsInventoryDailyAvailability Then
			vHttp = StrReplace(StrReplace(InteractionParameters.WSHost, "https://", ""), "http://", "");
			vHTTPServer = Left(vHttp, StrFind(vHttp, "/") - 1); 
			vRequestURL = Right(vHttp, StrLen(vHttp) - StrFind(vHttp, "/") + 1); 
		ElsIf UseToExportPrices And pIsInventoryDailyAvailability Then
			vHttp = StrReplace(StrReplace(InteractionParameters.WebhookURL, "https://", ""), "http://", "");
			vHTTPServer = Left(vHttp, StrFind(vHttp, "/") - 1); 
			vRequestURL = Right(vHttp, StrLen(vHttp) - StrFind(vHttp, "/") + 1);
		Endif;
			
		vPort = InteractionParameters.HttpPort;
		If vPort <> 80 And vPort <> 0 Then
			vHTTPServer = vHTTPServer + ":" + Format(vPort, "NFD=0; NG=");
		EndIf;
			
		vUseSSL 	= InteractionParameters.HTTPUseSSL;
			
		// HTTP header
		vHTTPHeader = New Map();
		vHTTPHeader.Insert("X-HL-Token", TrimAll(InteractionParameters.OAuth_AccessToken));
		vHTTPHeader.Insert("Content-Type", "application/json");

		// HTTP connection
		vSSL = Undefined;
		If vUseSSL Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);       	
		EndIf;
		
		vHTTPConnection = New HTTPConnection(vHTTPServer, , ,, , , vSSL);
		vHTTPRequest = New HTTPRequest(vRequestURL, vHTTPHeader);
		 
		vHTTPRequest.SetBodyFromString(pRequestBody);
		vRequestBody = pRequestBody;
		
		vRs = vHTTPConnection.Post(vHTTPRequest);
				
		vResult.StatusCode	= vRs.StatusCode;
		vResult.Body 		= vRs.GetBodyAsString();  
		
		If UseToExportPrices Then
			Try
	        	vMapResult = Catalogs.DataConvertationRules.JSONtoMap(vResult.Body); 
				If vMapResult["errors"] <> Undefined Then
					vCountError = vMapResult["errors"].Count();
					If vCountError > 0 Then 
						vError = "";
						If Not pIsInventoryDailyAvailability Then
							vError = NStr("en = 'Not all price levels unloaded: '; de = 'Nicht alle Preisstufen unbelastet: '; ru = 'Выгружены не все уровни цен: '") + (pRequestCount - vCountError) + "/" + pRequestCount;
						Else
							vError = NStr("en = 'Not all room availability unloaded: '; de = 'Nicht alle Zimmerverfügbarkeit entladen: '; ru = 'Выгружены не все доступные номера: '") + (pRequestCount - vCountError) + "/" + pRequestCount;	
						EndIf;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "SendHTTPRequest", Enums.ExternalSystemEventTypes.Warning,,, vError);
					EndIf;
				EndIf;
			Except
			EndTry;
		EndIf;		
	Except
		vError = String(InteractionParameters) + NStr("en = 'Failed to send request!'; de = 'Anfrage konnte nicht gesendet werden!'; ru = 'Не удалось отправить запрос!'") + ErrorDescription();
		WriteLogEvent("SendHTTPRequest", EventLogLevel.Warning, ,CurrentSessionDate(), "" + vError);
		vResult.Error = vError;
		vLogEventType = Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "SendHTTPRequest", vLogEventType, , , vError, );	
	EndTry;
	
	If InteractionParameters.DebugMode Then
		
		vLogStructure = New Structure;
		vLogStructure.Insert("Action", 						"SendHTTPRequest");
		vLogStructure.Insert("ExternalSystemInteractions", 	String(InteractionParameters));
		vLogStructure.Insert("RequestURL", 					vRequestURL);
		If StrLen(vRequestURL) > 100 Then
			vMap = New Map;
			vMap.Insert("RequestURL", 	vRequestURL);
			vMap.Insert("RequestBody", 	vRequestBody);
			vRequestBody = Catalogs.DataConvertationRules.MapToJSON(vMap);
		EndIf;
		vLogStructure.Insert("RequestBody", 				vRequestBody);
		vLogStructure.Insert("ResponseStatus", 				vResult.StatusCode);
		vLogStructure.Insert("ResponseBody", 				vResult.Body);
		vLogStructure.Insert("Error", 						vResult.Error);
		
		Catalogs.ExternalSystemInteractions.WriteLog(InteractionParameters, vLogStructure);	
	EndIf;
	
	Return vResult;	
	
EndFunction // SendQuery

#EndRegion