
#Region Public

// -----------------------------------------------------------------------------
//  Function returns hotel non replicating attribute values from the information register
//  -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  ValueTable - Attribute list
//
Function cmGetNonReplicatingHotelAttributes(pHotel) Export
	// Read from database
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	HotelNonReplicatingAttributes.Hotel,
	|	HotelNonReplicatingAttributes.Prefix,
	|	HotelNonReplicatingAttributes.GuestGroupFolder,
	|	HotelNonReplicatingAttributes.BLOBRootFolder
	|FROM
	|	InformationRegister.HotelNonReplicatingAttributes AS HotelNonReplicatingAttributes
	|WHERE
	|	HotelNonReplicatingAttributes.Hotel = &qHotel";
	vQry.SetParameter("qHotel", pHotel);
	vNonReplicatingHotelAttributes = vQry.Execute().Unload();
	// Return
	Return vNonReplicatingHotelAttributes;
EndFunction // cmGetNonReplicatingHotelAttributes

// -----------------------------------------------------------------------------
//  Function returns employee non replicating attribute values from the information register
//
// Parameters:
//  pEmployee	 - CatalogRef.Employees	 - Ref
// 
// Returns:
//  ValueTable - Attribute list
//
Function сmGetEmployeeNonReplicatingAttributes(pEmployee) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EmployeeNonReplicatingAttributes.Employee,
	|	EmployeeNonReplicatingAttributes.Workstation,
	|	EmployeeNonReplicatingAttributes.PermissionGroup
	|FROM
	|	InformationRegister.EmployeeNonReplicatingAttributes AS EmployeeNonReplicatingAttributes
	|WHERE
	|	EmployeeNonReplicatingAttributes.Employee = &qEmployee";
	vQry.SetParameter("qEmployee", pEmployee);
	Return vQry.Execute().Unload();
EndFunction // сmGetEmployeeNonReplicatingAttributes

// -----------------------------------------------------------------------------
//  Get list of calendar days with day types within given period
//
// Parameters:
//  pCalendar				 - CatalogRef.Calendars	 - is mandatory and is calendar item reference
//  pDateFrom				 - Date					 - Is mandatory
//  pDateTo					 - Date					 - Is mandatory
//  pCheckInDate			 - Date					 - Are used to calculate guest period of stay length in days
//  pCheckOutDate			 - Date					 - Are used to calculate guest period of stay length in days
//  pRoomType				 - CatalogRef.RoomTypes	 - Ref
//  pPriceCalculationDate	 - Date					 - Is mandatory
// 
// Returns:
//  ValueTable - List of calendar days
//
Function cmGetCalendarDays(pCalendar, pDateFrom, pDateTo, pCheckInDate, pCheckOutDate, pRoomType = Undefined, pPriceCalculationDate = '00010101') Export
	// Common checks	
	If Not ValueIsFilled(pDateFrom) Then
		Raise(NStr("en='ERR: Error calling cmGetCalendarDays function.
		               |CAUSE: Empty pDateFrom parameter value was passed to the function.
					   |DESC: Mandatory parameter pDateFrom should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetCalendarDays.
					   |CAUSE: В функцию передано пустое значение параметра pDateFrom.
					   |DESC: Обязательный параметр pDateFrom должен быть явно указан.';
				   |de='ERR: Fehler bei Aufruf der Funktion cmGetCalendarDays
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pDateFrom übertragen.
					   |DESC: Das Pflichtparameter pDateFrom muss eindeutig angegeben sein.'"));
	EndIf;
	If Not ValueIsFilled(pDateTo) Then
		Raise(NStr("en='ERR: Error calling cmGetCalendarDays function.
		               |CAUSE: Empty pDateTo parameter value was passed to the function.
					   |DESC: Mandatory parameter pDateTo should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetCalendarDays.
				       |CAUSE: В функцию передано пустое значение параметра pDateTo.
					   |DESC: Обязательный параметр pDateTo должен быть явно указан.';
				   |de='ERR: Fehler bei Aufruf der Funktion cmGetCalendarDays
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pDateTo übertragen.
					   |DESC: Das Pflichtparameter pDateTo muss eindeutig angegeben sein.'"));
	EndIf;
	vCheckInDate = pCheckInDate;
	If Not ValueIsFilled(vCheckInDate) Then
		vCheckInDate = pDateFrom;
	EndIf;
	vCheckOutDate = pCheckOutDate;
	If Not ValueIsFilled(vCheckOutDate) Then
		vCheckOutDate = pDateTo;
	EndIf;
	
	// Build and run query to get calendar days
	qGetDays = New Query();
	If pCalendar.IsPerPeriod Then
		qGetDays.Text = 
		"SELECT
		|	CalendarDays.AccountingDate AS Period,
		|	CalendarDays.Calendar AS Calendar,
		|	CASE
		|		WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
		|			THEN CalendarDays.CalendarDayType
		|		WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|			THEN CalendarDays.CalendarDayType
		|		ELSE CalendarDaysByRoomTypes.CalendarDayType
		|	END AS CalendarDayType,
		|	CASE
		|		WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
		|			THEN CalendarDays.CalendarDayType.SortCode
		|		WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|			THEN CalendarDays.CalendarDayType.SortCode
		|		ELSE CalendarDaysByRoomTypes.CalendarDayType.SortCode
		|	END AS CalendarDayTypeSortCode,
		|	CalendarDays.Timetable AS Timetable,
		|	CASE
		|		WHEN CalendarDaysByRoomTypes.PriceTag IS NULL
		|			THEN CalendarDays.PriceTag
		|		WHEN CalendarDaysByRoomTypes.PriceTag = VALUE(Catalog.PriceTags.EmptyRef)
		|			THEN CalendarDays.PriceTag
		|		ELSE CalendarDaysByRoomTypes.PriceTag
		|	END AS PriceTag,
		|	DATEDIFF(&qCheckInDate, &qCheckOutDate, DAY) AS LengthOfStay,
		|	CalendarDayTypesByLengthOfStay.CalendarDayType AS CalendarDayTypeByLengthOfStay,
		|	CalendarDayTypesByLengthOfStay.CalendarDayType.SortCode AS CalendarDayTypeByLengthOfStaySortCode,
		|	CalendarDayTypesByLengthOfStay.LengthOfStay AS LengthOfStayByLengthOfStay
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			AccountingDate BETWEEN &qDateFrom AND &qDateTo
		|				AND Calendar = &qCalendar) AS CalendarDays
		|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|				&qPriceCalculationDate,
		|				AccountingDate BETWEEN &qDateFrom AND &qDateTo
		|					AND Calendar = &qCalendar
		|					AND RoomType = &qRoomType) AS CalendarDaysByRoomTypes
		|		ON CalendarDays.Calendar = CalendarDaysByRoomTypes.Calendar
		|			AND CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
		|		LEFT JOIN InformationRegister.CalendarDayTypesByLengthOfStay AS CalendarDayTypesByLengthOfStay
		|		ON CalendarDays.Calendar = CalendarDayTypesByLengthOfStay.Calendar
		|			AND (DATEDIFF(&qCheckInDate, &qCheckOutDate, DAY) >= CalendarDayTypesByLengthOfStay.LengthOfStay)
		|			AND (CalendarDayTypesByLengthOfStay.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef))
		|
		|ORDER BY
		|	CalendarDays.AccountingDate,
		|	LengthOfStayByLengthOfStay DESC";
	Else
		qGetDays.Text = 
		"SELECT
		|	CalendarDays.AccountingDate AS Period,
		|	CalendarDays.Calendar AS Calendar,
		|	CASE
		|		WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
		|			THEN CalendarDays.CalendarDayType
		|		WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|			THEN CalendarDays.CalendarDayType
		|		ELSE CalendarDaysByRoomTypes.CalendarDayType
		|	END AS CalendarDayType,
		|	CASE
		|		WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
		|			THEN CalendarDays.CalendarDayType.SortCode
		|		WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
		|			THEN CalendarDays.CalendarDayType.SortCode
		|		ELSE CalendarDaysByRoomTypes.CalendarDayType.SortCode
		|	END AS CalendarDayTypeSortCode,
		|	CalendarDays.Timetable AS Timetable,
		|	CASE
		|		WHEN CalendarDaysByRoomTypes.PriceTag IS NULL
		|			THEN CalendarDays.PriceTag
		|		WHEN CalendarDaysByRoomTypes.PriceTag = VALUE(Catalog.PriceTags.EmptyRef)
		|			THEN CalendarDays.PriceTag
		|		ELSE CalendarDaysByRoomTypes.PriceTag
		|	END AS PriceTag,
		|	DATEDIFF(&qCheckInDate, CalendarDays.AccountingDate, DAY) + 1 AS LengthOfStay,
		|	CalendarDayTypesByLengthOfStay.CalendarDayType AS CalendarDayTypeByLengthOfStay,
		|	CalendarDayTypesByLengthOfStay.CalendarDayType.SortCode AS CalendarDayTypeByLengthOfStaySortCode,
		|	CalendarDayTypesByLengthOfStay.LengthOfStay AS LengthOfStayByLengthOfStay
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			AccountingDate BETWEEN &qDateFrom AND &qDateTo
		|				AND Calendar = &qCalendar) AS CalendarDays
		|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|				&qPriceCalculationDate,
		|				AccountingDate BETWEEN &qDateFrom AND &qDateTo
		|					AND Calendar = &qCalendar
		|					AND RoomType = &qRoomType) AS CalendarDaysByRoomTypes
		|		ON CalendarDays.Calendar = CalendarDaysByRoomTypes.Calendar
		|			AND CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
		|		LEFT JOIN InformationRegister.CalendarDayTypesByLengthOfStay AS CalendarDayTypesByLengthOfStay
		|		ON CalendarDays.Calendar = CalendarDayTypesByLengthOfStay.Calendar
		|			AND (DATEDIFF(&qCheckInDate, CalendarDays.Period, DAY) + 1 >= CalendarDayTypesByLengthOfStay.LengthOfStay)
		|			AND (CalendarDayTypesByLengthOfStay.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef))
		|
		|ORDER BY
		|	CalendarDays.AccountingDate,
		|	LengthOfStayByLengthOfStay DESC";
	EndIf;
	qGetDays.SetParameter("qCalendar", pCalendar);
	qGetDays.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(pPriceCalculationDate), pPriceCalculationDate, CurrentSessionDate()));
	qGetDays.SetParameter("qRoomType", pRoomType);
	qGetDays.SetParameter("qDateFrom", BegOfDay(pDateFrom));
	qGetDays.SetParameter("qDateTo", pDateTo);
	qGetDays.SetParameter("qCheckInDate", BegOfDay(vCheckInDate));
	qGetDays.SetParameter("qCheckOutDate", BegOfDay(vCheckOutDate));
	vDays = qGetDays.Execute().Unload();
	
	// Remove join extended rows and set resulting calendar day type by comparing weights of both
	If vDays.Count() > 0 Then
		If vDays.Count() > 1 Then
			i = 0;
			While i < (vDays.Count() - 1) Do
				vCurRow = vDays.Get(i);
				If ValueIsFilled(vCurRow.CalendarDayType) And ValueIsFilled(vCurRow.CalendarDayTypeByLengthOfStay) Then
					If vCurRow.CalendarDayTypeByLengthOfStay.Weight >= vCurRow.CalendarDayType.Weight Then
						vCurRow.CalendarDayType = vCurRow.CalendarDayTypeByLengthOfStay;
						vCurRow.CalendarDayTypeSortCode = vCurRow.CalendarDayTypeByLengthOfStaySortCode;
					EndIf;
				EndIf;
				vNextRow = vDays.Get(i + 1);
				If vCurRow.Period = vNextRow.Period And vCurRow.LengthOfStay = vNextRow.LengthOfStay Then
					vDays.Delete(i + 1);
				Else
					i = i + 1;
				EndIf;
			EndDo;
		Else
			vCurRow = vDays.Get(0);
			If ValueIsFilled(vCurRow.CalendarDayType) And ValueIsFilled(vCurRow.CalendarDayTypeByLengthOfStay) Then
				If vCurRow.CalendarDayTypeByLengthOfStay.Weight >= vCurRow.CalendarDayType.Weight Then
					vCurRow.CalendarDayType = vCurRow.CalendarDayTypeByLengthOfStay;
					vCurRow.CalendarDayTypeSortCode = vCurRow.CalendarDayTypeByLengthOfStaySortCode;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Return
	Return vDays;
EndFunction // cmGetCalendarDays

// -----------------------------------------------------------------------------
//  Get list of accumulation discount types
//
// Parameters:
//  pDiscountType	 - CatalogRef	 - ref
// 
// Returns:
//  ValueTable - Value table with accumulating discount types
//
Function cmGetAccumulatingDiscountTypesTable(pDiscountType = Undefined, pHotel = Undefined) Export
	// Build and run query
	qAccDisTypes = New Query;
	qAccDisTypes.Text = 
	"SELECT
	|	DiscountTypes.Ref AS DiscountType,
	|	DiscountTypes.DateValidFrom AS DateValidFrom,
	|	DiscountTypes.DateValidTo AS DateValidTo,
	|	DiscountTypes.SortCode AS SortCode
	|FROM
	|	Catalog.DiscountTypes AS DiscountTypes
	|WHERE
	|	NOT DiscountTypes.DeletionMark
	|	AND DiscountTypes.IsAccumulatingDiscount
	|	AND DiscountTypes.LoyaltyType <> VALUE(Enum.LoyaltyType.Bonuses)
	|	AND (NOT DiscountTypes.HasToBeDirectlyAssigned
	|				AND &qDiscountTypeIsEmpty
	|			OR DiscountTypes.HasToBeDirectlyAssigned
	|				AND DiscountTypes.Ref = &qDiscountType)
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND (DiscountTypes.Hotel = &qHotel
	|					OR DiscountTypes.Hotel = VALUE(Catalog.Hotels.EmptyRef)))
	|
	|ORDER BY
	|	SortCode";
	vDiscountType = Catalogs.DiscountTypes.EmptyRef();
	If ValueIsFilled(pDiscountType) Then
		If Not pDiscountType.IsFolder And Not pDiscountType.DeletionMark And 
		   pDiscountType.IsAccumulatingDiscount And pDiscountType.HasToBeDirectlyAssigned Then
			vDiscountType = pDiscountType;
		EndIf;
	EndIf;
	qAccDisTypes.SetParameter("qDiscountType", vDiscountType);
	qAccDisTypes.SetParameter("qDiscountTypeIsEmpty", Not ValueIsFilled(vDiscountType));
	qAccDisTypes.SetParameter("qHotel", pHotel);
	qAccDisTypes.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vAccDisTypes = qAccDisTypes.Execute().Unload();
	Return vAccDisTypes;
EndFunction // cmGetAccumulatingDiscountTypes

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotelRef			 - CatalogRef.Hotels - Ref
//  pExternalSystemCode	 - String			 - ExternalSystemCode
//  pObjectTypeName		 - String			 - ObjectTypeName
//  pObjectRef			 - CatalogRef		 - Ref
//  pEmptyIfNotFound	 - Boolean			 - EmptyIfNotFound
//  pGetCode			 - Boolean			 - Need get code
// 
// Returns:
//  String - External system code
//
Function cmGetObjectExternalSystemCodeByRefReUse(pHotelRef, pExternalSystemCode, pObjectTypeName, pObjectRef, pEmptyIfNotFound = False, pGetCode = False) Export
	vObjectExternalCode = "";
	// Try to find reference to the object in the program by external code
	If ValueIsFilled(pObjectRef) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	(ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|			OR ExternalSystemsObjectCodesMappings.Hotel = &qEmptyHotel)
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
		|	AND ExternalSystemsObjectCodesMappings.ObjectRef = &qObject
		|
		|ORDER BY
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode";
		vQry.SetParameter("qHotel", pHotelRef);
		vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		vQry.SetParameter("qExternalSystemCode", TrimAll(pExternalSystemCode));
		vQry.SetParameter("qObjectTypeName", TrimAll(pObjectTypeName));
		vQry.SetParameter("qObject", pObjectRef);
		vObjects = vQry.Execute().Unload();
		If vObjects.Count() > 0 Then
			vObjectExternalCode = vObjects.Get(0).ObjectExternalCode;
		EndIf;
		If IsBlankString(vObjectExternalCode) And Not pEmptyIfNotFound Then
			// Try to return object description instead
			Try         
				If pGetCode Then
					If Metadata.Catalogs.Contains(pObjectRef.Metadata()) Then
						vObjectExternalCode = TrimAll(pObjectRef.Code);
					Else
						vObjectExternalCode = TrimAll(pObjectRef.Number);	
					EndIf;
				Else
					vObjectExternalCode = TrimAll(pObjectRef.Description);
				EndIf;
			Except
				vObjectExternalCode = "";
			EndTry;
		EndIf;
	EndIf;
	Return vObjectExternalCode;
EndFunction // cmGetObjectExternalSystemCodeByRef_ReUse 

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel		 - CatalogRef.Hotels - Ref 
//  pPeriodFrom	 - Date	 - PeriodFrom
//  pPeriodTo	 - Date	 - PeriodTo
// 
// Returns:
//  ValueTable - rows of accounting date and occupancy percent
//
Function cmFillOccupationPercentsReUse(pHotel, pPeriodFrom, pPeriodTo) Export 

	Return cmFillOccupationPercents(pHotel, pPeriodFrom, pPeriodTo, False);

EndFunction // cmFillOccupationPercentsReUse

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel					 - CatalogRef.Hotels - Ref 
//  pPriceTagType			 - CatalogRef.PriceTag - price tag type enum reference 
//  pPriceCalculationDate	 - Date	 - accounting date 
// 
// Returns:
//  ValueTable - rows from the PriceTagRanges information register
//
Function cmGetPriceTagRangesReUse(pHotel, pPriceTagType, pPriceCalculationDate = Undefined) Export

	Return cmGetPriceTagRanges(pHotel, pPriceTagType, pPriceCalculationDate, False);

EndFunction // cmGetPriceTagRangesReUse

#EndRegion
