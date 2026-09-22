
#Region Public

// -----------------------------------------------------------------------------
//  Copies one calendar to new calendar with all days and day types
//  Retruns the ref to the new Calendar
//
// Parameters:
//  pFromCalendar	 - CatalogRef.Calendars	 - Calendar to copy
//  pDescription	 - String				 - Calendar description
//  pCode			 - String				 - New code calendar
// 
// Returns:
//  CatalogRef.Calendars - Ref
//
Function CopyCalendar(pFromCalendar, pDescription = "", pCode = "") Export
	If IsBlankString(pDescription) Then
		pDescription = pFromCalendar.Description + " - " + NStr("en = 'copy '; de = 'Kopie '; ru = 'копия '");
	EndIf;
	If IsBlankString(pCode) Then
		pCode = TrimAll(Left(pFromCalendar.Code, 4)) + "1";
	EndIf;
	vNewCalendarCode = TrimAll(pCode);
	vNumberOfAttempts = 0;
	
	// There are other room rates referencing the same calendar. We need to create new calendar as a copy of current one
	While True Do
		Try
			vTmpCalendar = Catalogs.Calendars.FindByCode(vNewCalendarCode, False);
			If ValueIsFilled(vTmpCalendar) Then
				vNumberOfAttempts = vNumberOfAttempts + 1;
				vNewCalendarCode = TrimAll(Left(vNewCalendarCode, 4)) + String(vNumberOfAttempts);
				If vNumberOfAttempts > 9 Then
					// Failed to generate new code for the new calendar
					Raise NStr("en='Failed to create new calendar for the choosen room rate. Please change room rate code!'; 
					           |ru='Не удалось создать новый календарь для выбранного тарифа. Пожалуйста укажите у тарифа любой новый код!'; 
							   |de='Es konnte keine neue Kalender für den gewählten Tarif zu schaffen. Bitte geben Sie den neuen Tarif Code ein!'");
				EndIf;
			Else
				vNewCalendarObj = pFromCalendar.Copy();
				vNewCalendarObj.Code = vNewCalendarCode;
				If vNumberOfAttempts = 0 Then
					vNewCalendarObj.Description = TrimAll(pDescription);
				Else
					vNewCalendarObj.Description = TrimAll(pDescription) + " - " + NStr("en = 'copy '; de = 'Kopie '; ru = 'копия '") + String(vNumberOfAttempts);
				EndIf;
				vNewCalendarObj.Write();
				Break;
			EndIf;
		Except
			// Failed to write new calendar
			Raise NStr("en='Failed to create new calendar for the choosen room rate. Please change room rate code!'; 
			           |ru='Не удалось создать новый календарь для выбранного тарифа. Пожалуйста укажите у тарифа любой новый код!'; 
					   |de='Es konnte keine neue Kalender für den gewählten Tarif zu schaffen. Bitte geben Sie den neuen Tarif Code ein!'");
		EndTry;
	EndDo;
	// New calendar reference
	vNewCalendar = vNewCalendarObj.Ref;

	// Get target calendar days
	vTgtDays = InformationRegisters.CalendarDays.CreateRecordSet();
	vTgtDays.Filter.Calendar.ComparisonType = ComparisonType.Equal;
	vTgtDays.Filter.Calendar.Value = vNewCalendar;
	vTgtDays.Filter.Calendar.Use = True;
	vTgtDays.Read();
	vTgtDays.Clear();
	
	// Write calendar days
	vDaysRow = InformationRegisters.CalendarDays.Select(, , New Structure("Calendar", pFromCalendar));
	// Copy calendar days
	While vDaysRow.Next() Do
		vTgtDaysRow = vTgtDays.Add();
		vTgtDaysRow.Calendar = vNewCalendar;
		vTgtDaysRow.Period = vDaysRow.Period;
		vTgtDaysRow.AccountingDate = vDaysRow.AccountingDate;
		vTgtDaysRow.CalendarDayType = vDaysRow.CalendarDayType;
		vTgtDaysRow.Timetable = vDaysRow.Timetable;
		vTgtDaysRow.PriceTag = vDaysRow.PriceTag;
		vTgtDaysRow.RoomPrice = vDaysRow.RoomPrice;
		vTgtDaysRow.RoomPriceCurrency = vDaysRow.RoomPriceCurrency;
		vTgtDaysRow.Author = SessionParameters.CurrentUser;
		vTgtDaysRow.Remarks = StrTemplate(NStr("en='Copy calendar %1 -> %2'; ru='Копирование календаря %1 -> %2'; de='Kalender kopieren %1 -> %2'"), TrimAll(pFromCalendar), TrimAll(vNewCalendar));
	EndDo;

	// Write record set to the database
	vTgtDays.Write(True);

	// Get target calendar days
	vTgtDaysRT = InformationRegisters.CalendarDaysByRoomTypes.CreateRecordSet();
	vTgtDaysRT.Filter.Calendar.ComparisonType = ComparisonType.Equal;
	vTgtDaysRT.Filter.Calendar.Value = vNewCalendar;
	vTgtDaysRT.Filter.Calendar.Use = True;
	vTgtDaysRT.Read();
	vTgtDaysRT.Clear();
	
	// Write calendar days by room types
	vDaysRTRow = InformationRegisters.CalendarDaysByRoomTypes.Select(, , New Structure("Calendar", pFromCalendar));
	// Copy calendar days
	While vDaysRTRow.Next() Do
		vTgtDaysRTRow = vTgtDaysRT.Add();
		vTgtDaysRTRow.Calendar = vNewCalendar;
		vTgtDaysRTRow.Period = vDaysRTRow.Period;
		vTgtDaysRTRow.AccountingDate = vDaysRTRow.AccountingDate;
		vTgtDaysRTRow.RoomType = vDaysRTRow.RoomType;
		vTgtDaysRTRow.Hotel = vDaysRTRow.Hotel;
		vTgtDaysRTRow.CalendarDayType = vDaysRTRow.CalendarDayType;
		vTgtDaysRTRow.PriceTag = vDaysRTRow.PriceTag;
		vTgtDaysRTRow.RoomPrice = vDaysRTRow.RoomPrice;
		vTgtDaysRTRow.RoomPriceCurrency = vDaysRTRow.RoomPriceCurrency;
		vTgtDaysRTRow.Author = SessionParameters.CurrentUser;
		vTgtDaysRTRow.Remarks = StrTemplate(NStr("en='Copy calendar %1 -> %2'; ru='Копирование календаря %1 -> %2'; de='Kalender kopieren %1 -> %2'"), TrimAll(pFromCalendar), TrimAll(vNewCalendar));
	EndDo;

	// Write record set to the database
	vTgtDaysRT.Write(True);

	Return vNewCalendar;
EndFunction // CopyCalendar()

// -----------------------------------------------------------------------------
//  Copies one rate prices to another
//  It is supposed that calandar is the same. the function does not check for calendar
//
// Parameters:
//  pFromRate	 - CatalogRef.RoomRates	 - Source Rate
//  pToRate		 - CatalogRef.RoomRates	 - Destination Rate
// 
// Returns:
//  String - Return error message if any. Empty string means OK
//
Function CopyRoomRatePrices(pFromRate, pToRate) Export
	If Not ValueIsFilled(pFromRate) Then
		Return NStr("en = 'Source Rate is not filled'; de = 'Datenquelle Tarif nicht angegeben'; ru = 'Не указан тариф - источник данных'");
	EndIf;
	If Not ValueIsFilled(pToRate) Then
		Return NStr("en = 'Destination Rate is not filled'; de = 'Keine Tarif für den Datenempfänger'; ru = 'Не указан тариф - получатель данных'");
	EndIf;
	// 1. Get the list of Set room rate prices
	vQ = New Query;
	vQ.Text = "SELECT
	          |	SetRoomRatePrices.Ref AS Ref,
	          |	SetRoomRatePrices.Date AS Date
	          |FROM
	          |	Document.SetRoomRatePrices AS SetRoomRatePrices
	          |WHERE
	          |	SetRoomRatePrices.RoomRate = &qRoomRate
	          |	AND SetRoomRatePrices.Posted
	          |
	          |ORDER BY
	          |	SetRoomRatePrices.Date DESC";
	vQ.SetParameter("qRoomRate", pFromRate);
	qRes = vQ.Execute().Select();
	// 2.Copy them 
	While qRes.Next() Do
		newDoc = qRes.Ref.Copy();
		newDoc.RoomRate = pToRate;
		newDoc.Date = qRes.Date;
		Try
			newDoc.Write(DocumentWriteMode.Posting);
		Except
			Return ErrorDescription();
		EndTry;
	EndDo;
	Return "";
EndFunction // CopyRoomRatePrices()

// -----------------------------------------------------------------------------
// Returns True in case there is any reservation or accommodation
//  for given room rate, day type and price tag
//  that use prices for this room rate, day type and price tag combination
//  no one can change document with date earlier than Price Calculation Date in reservation
//
// Parameters:
//  pDate			 - Date	 - Check date
//  pRoomRate		 - CatalogRef.RoomRates	 - Ref room rate
//  pCalendarDayType - CatalogRef.CalendarDayTypes - Ref day type
//  pPriceTag		 - CatalogRef.PriceTags - Ref price tag combination
// 
// Returns:
//  Boolean - True or False 
//
Function IsRoomRateInUse(pDate, pRoomRate = Undefined, pCalendarDayType = Undefined, pPriceTag = Undefined, pCalendar = Undefined) Export
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(pRoomRate) And ValueIsFilled(pRoomRate.Hotel) Then
		vHotel = pRoomRate.Hotel;
	ElsIf ValueIsFilled(pCalendar) And ValueIsFilled(pCalendar.Hotel) Then
		vHotel = pCalendar.Hotel;
	ElsIf ValueIsFilled(pCalendarDayType) And ValueIsFilled(pCalendarDayType.Hotel) Then
		vHotel = pCalendarDayType.Hotel;
	ElsIf ValueIsFilled(pPriceTag) And ValueIsFilled(pPriceTag.Hotel) Then
		vHotel = pPriceTag.Hotel;
	EndIf;
	If ValueIsFilled(vHotel) And vHotel.AllowEditOfRatesUsedInReservationsAlready Then
		Return False;
	EndIf;
		
	If pRoomRate <> Undefined And pCalendarDayType = Undefined And pPriceTag = Undefined And pCalendar = Undefined Then
		// For price formulas. There is not day type or price tag in the document
		vText = "SELECT TOP 1
		|	ReservationServices.Ref AS Ref
		|FROM
		|	Document.Reservation.Services AS ReservationServices
		|WHERE
		|	ReservationServices.Ref.Posted
		|	AND ReservationServices.Ref.PriceCalculationDate >= &qDocDate
		|	AND ReservationServices.RoomRate = &qRoomRate
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	AccServices.Ref
		|FROM
		|	Document.Accommodation.Services AS AccServices
		|WHERE
		|	AccServices.Ref.Posted
		|	AND AccServices.Ref.PriceCalculationDate >= &qDocDate
		|	AND AccServices.RoomRate = &qRoomRate";    
	ElsIf Not pCalendar = Undefined	And pRoomRate = Undefined Then
		// For registers. There is not room rate    
		vText = 
		"SELECT DISTINCT
		|	RoomRates.Ref AS Ref
		|INTO vRomeRates
		|FROM
		|	Catalog.RoomRates AS RoomRates
		|WHERE
		|	RoomRates.Calendar = &qCalendar
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	ReservationServices.Ref AS Ref
		|FROM
		|	vRomeRates AS vRomeRates
		|		INNER JOIN Document.Reservation.Services AS ReservationServices
		|		ON vRomeRates.Ref = ReservationServices.RoomRate
		|WHERE
		|	ReservationServices.Ref.Posted
		|	AND ReservationServices.Ref.PriceCalculationDate >= &qDocDate
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	AccServices.Ref
		|FROM
		|	vRomeRates AS vRomeRates
		|		INNER JOIN Document.Accommodation.Services AS AccServices
		|		ON vRomeRates.Ref = AccServices.RoomRate
		|WHERE
		|	AccServices.Ref.Posted
		|	AND AccServices.Ref.PriceCalculationDate >= &qDocDate";   
	Else
		vText = "SELECT TOP 1
		|	ReservationServices.Ref AS Ref
		|FROM
		|	Document.Reservation.Services AS ReservationServices
		|WHERE
		|	ReservationServices.Ref.Posted
		|	AND ReservationServices.Ref.PriceCalculationDate >= &qDocDate
		|	AND ReservationServices.RoomRate = &qRoomRate
		|	AND ReservationServices.CalendarDayType %1 
		|	AND ReservationServices.PriceTag %2 
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	AccServices.Ref
		|FROM
		|	Document.Accommodation.Services AS AccServices
		|WHERE
		|	AccServices.Ref.Posted
		|	AND AccServices.Ref.PriceCalculationDate >= &qDocDate
		|	AND AccServices.RoomRate = &qRoomRate
		|	AND AccServices.CalendarDayType %1
		|	AND AccServices.PriceTag %2";
		If ValueIsFilled(pCalendarDayType) And pCalendarDayType.IsFolder Then
			qDayTypeText = "IN HIERARCHY(&qCalendarDayType)";
		Else
			qDayTypeText = " = &qCalendarDayType";
		EndIf;
		
		If ValueIsFilled(pPriceTag) And pPriceTag.IsFolder Then
			qPriceTagText = "IN HIERARCHY(&qPriceTag)";
		Else
			qPriceTagText = " = &qPriceTag";
		EndIf;
		vText = StrTemplate(vText, qDayTypeText, qPriceTagText);
	EndIf;
	
	vQ = New Query(vText);
	vPriceTag = Catalogs.PriceTags.EmptyRef();
	If ValueIsFilled(pPriceTag) Then
		vPriceTag = pPriceTag;
	EndIf;	
	vQ.SetParameter("qDocDate", pDate);		
	vQ.SetParameter("qRoomRate", pRoomRate);
	vQ.SetParameter("qCalendarDayType", pCalendarDayType);
	vQ.SetParameter("qPriceTag", vPriceTag);
	vQ.SetParameter("qCalendar", pCalendar);
	
	If Not vQ.Execute().IsEmpty() Then
		Return True;
	EndIf;
	Return False;
EndFunction // IsRoomRateInUse()

#EndRegion
