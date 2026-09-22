
#Region Public

// -----------------------------------------------------------------------------
//  Get list of calendar days with day types within given period
//
// Parameters:
//  pRef			 - CatalogRef.Calendars	 - Ref
//  pDateFrom		 - Date					 - DateFrom is mandatory
//  pDateTo			 - Date					 - DateTo is mandatory
//  pCheckInDate	 - Date					 - CheckInDate
//  pCheckOutDate	 - Date					 - CheckOutDate
//  pRoomType		 - CatalogRef.RoomTypes	 - Ref
// 
// Returns:
//  ValueTable - List calendar days
//
Function pmGetDays(pRef, pDateFrom, pDateTo, pCheckInDate = Undefined, pCheckOutDate = Undefined, pRoomType = Undefined, pPriceCalculationDate = '00010101') Export
	// Common checks	
	If Not ValueIsFilled(pDateFrom) Then
		Raise(NStr("en='ERR: Error calling Calendar.pmGetDays function.
		               |CAUSE: Empty pDateFrom parameter value was passed to the function.
					   |DESC: Mandatory parameter pDateFrom should be filled.';
				   |ru='ERR: Ошибка вызова функции Calendar.pmGetDays.
					   |CAUSE: В функцию передано пустое значение параметра pDateFrom.
					   |DESC: Обязательный параметр pDateFrom должен быть явно указан.';
				   |de='ERR: Fehler bei Aufruf der Funktion Calendar.pmGetDays
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pDateFrom übertragen.
					   |DESC: Das Pflichtparameter pDateFrom muss eindeutig angegeben sein.'"));
	EndIf;
	If Not ValueIsFilled(pDateTo) Then
		Raise(NStr("en='ERR: Error calling Calendar.pmGetDays function.
		               |CAUSE: Empty pDateTo parameter value was passed to the function.
					   |DESC: Mandatory parameter pDateTo should be filled.';
				   |ru='ERR: Ошибка вызова функции Calendar.pmGetDays.
				       |CAUSE: В функцию передано пустое значение параметра pDateTo.
					   |DESC: Обязательный параметр pDateTo должен быть явно указан.';
				   |de='ERR: Fehler bei Aufruf der Funktion Calendar.pmGetDays
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
	If pRef.IsPerPeriod Then
		qGetDays.Text = 
		"SELECT
		|	CalendarDays.AccountingDate AS Period,
		|	CalendarDays.Calendar AS Calendar,
		|	CalendarDays.CalendarDayType AS CalendarDayType,
		|	CalendarDays.CalendarDayType.SortCode AS CalendarDayTypeSortCode,
		|	CalendarDays.Timetable AS Timetable,
		|	CalendarDays.PriceTag AS PriceTag,
		|	DATEDIFF(&qCheckInDate, &qCheckOutDate, DAY) AS LengthOfStay,
		|	CalendarDayTypesByLengthOfStay.CalendarDayType AS CalendarDayTypeByLengthOfStay,
		|	CalendarDayTypesByLengthOfStay.CalendarDayType.SortCode AS CalendarDayTypeByLengthOfStaySortCode,
		|	CalendarDayTypesByLengthOfStay.LengthOfStay AS LengthOfStayByLengthOfStay,
		|	CalendarDaysByRoomTypes.CalendarDayType AS CalendarDayTypeByRoomType,
		|	CalendarDaysByRoomTypes.PriceTag AS PriceTagByRoomType,
		|	CalendarDaysByRoomTypes.RoomType AS RoomType
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			AccountingDate BETWEEN &qDateFrom AND &qDateTo
		|				AND Calendar = &qCalendar) AS CalendarDays
		|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|				&qPriceCalculationDate,
		|				AccountingDate BETWEEN &qDateFrom AND &qDateTo
		|					AND Calendar = &qCalendar
		|					AND (&qRoomTypeIsUndefined
		|						OR NOT &qRoomTypeIsUndefined
		|							AND RoomType = &qRoomType)) AS CalendarDaysByRoomTypes
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
		|	CalendarDays.CalendarDayType AS CalendarDayType,
		|	CalendarDays.CalendarDayType.SortCode AS CalendarDayTypeSortCode,
		|	CalendarDays.Timetable AS Timetable,
		|	CalendarDays.PriceTag AS PriceTag,
		|	DATEDIFF(&qCheckInDate, CalendarDays.AccountingDate, DAY) + 1 AS LengthOfStay,
		|	CalendarDayTypesByLengthOfStay.CalendarDayType AS CalendarDayTypeByLengthOfStay,
		|	CalendarDayTypesByLengthOfStay.CalendarDayType.SortCode AS CalendarDayTypeByLengthOfStaySortCode,
		|	CalendarDayTypesByLengthOfStay.LengthOfStay AS LengthOfStayByLengthOfStay,
		|	CalendarDaysByRoomTypes.CalendarDayType AS CalendarDayTypeByRoomType,
		|	CalendarDaysByRoomTypes.PriceTag AS PriceTagByRoomType,
		|	CalendarDaysByRoomTypes.RoomType AS RoomType
		|FROM
		|	InformationRegister.CalendarDays.SliceLast(
		|			&qPriceCalculationDate,
		|			AccountingDate BETWEEN &qDateFrom AND &qDateTo
		|				AND Calendar = &qCalendar) AS CalendarDays
		|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
		|				&qPriceCalculationDate,
		|				AccountingDate BETWEEN &qDateFrom AND &qDateTo
		|					AND Calendar = &qCalendar
		|					AND CASE
		|						WHEN &qRoomTypeIsUndefined
		|							THEN TRUE
		|						WHEN NOT &qRoomTypeIsUndefined
		|								AND RoomType = &qRoomType
		|							THEN TRUE
		|						ELSE FALSE
		|					END) AS CalendarDaysByRoomTypes
		|		ON CalendarDays.Calendar = CalendarDaysByRoomTypes.Calendar
		|			AND CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
		|		LEFT JOIN InformationRegister.CalendarDayTypesByLengthOfStay AS CalendarDayTypesByLengthOfStay
		|		ON CalendarDays.Calendar = CalendarDayTypesByLengthOfStay.Calendar
		|			AND (DATEDIFF(&qCheckInDate, CalendarDays.AccountingDate, DAY) + 1 >= CalendarDayTypesByLengthOfStay.LengthOfStay)
		|			AND (CalendarDayTypesByLengthOfStay.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef))
		|
		|ORDER BY
		|	CalendarDays.AccountingDate,
		|	LengthOfStayByLengthOfStay DESC";
	EndIf;
	qGetDays.SetParameter("qCalendar", pRef);
	qGetDays.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(pPriceCalculationDate), pPriceCalculationDate, CurrentSessionDate()));
	qGetDays.SetParameter("qRoomType", pRoomType);
	qGetDays.SetParameter("qRoomTypeIsUndefined", pRoomType = Undefined);
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
					If vCurRow.CalendarDayTypeByLengthOfStay.Weight > vCurRow.CalendarDayType.Weight Then
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
				If vCurRow.CalendarDayTypeByLengthOfStay.Weight > vCurRow.CalendarDayType.Weight Then
					vCurRow.CalendarDayType = vCurRow.CalendarDayTypeByLengthOfStay;
					vCurRow.CalendarDayTypeSortCode = vCurRow.CalendarDayTypeByLengthOfStaySortCode;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Return
	Return vDays;
EndFunction // pmGetDays

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
