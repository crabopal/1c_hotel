
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pReplacing)  
	If DataExchange.Load Or SessionParameters.UpdateInProgress Then
		Return;
	EndIf;  
	// Check delete or change record  
	If ThisObject.Count() = 0 Then      
		vAccountingDate = ThisObject.Filter.AccountingDate.Value;
		If vAccountingDate <> '00010101' Then
			vCalendar = ThisObject.Filter.Calendar.Value;
			vPeriod = ThisObject.Filter.Period.Value;
			If RatesManagement.IsRoomRateInUse(vPeriod, , , , vCalendar) Then
				pCancel = True;  
				If ThisObject.Modified() Then
					// It`s delete row
					vErrMsg = StrTemplate(NStr("en = 'You cannot delete the line for %1 to %2. because We have reservations!'; 
											   |de = 'Sie können die Zeile %1 nicht in %2 ändern. Weil Wir haben Reservierungen!'; 
											   |ru = 'Нельзя удалить строку для %1 от %2. т.к. есть бронирования!'"), vCalendar, vPeriod);   
					tcCommonFunctionOnClientServer.UserMessage(vErrMsg);    
				EndIf;
				Return;
			EndIf;	
		EndIf;	
	EndIf;

	For Each vRcd In ThisObject Do
		// Try to find restrictions data for this date
		vPeriod = BegOfDay(vRcd.Period);
		If vPeriod <> '20000101' Then
			vAccountingDate = vRcd.AccountingDate;
			vCalendar = vRcd.Calendar;
			vCalendarDayType = vRcd.CalendarDayType;
			vRoomType = vRcd.RoomType;
			vHotel = vRcd.Hotel;
			If ValueIsFilled(vCalendarDayType) Then
				vWeight = vCalendarDayType.Weight;
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	CalendarDayTypesAllowed.Period AS Period,
				|	CalendarDayTypesAllowed.Calendar AS Calendar,
				|	CalendarDayTypesAllowed.RoomType AS RoomType,
				|	CalendarDayTypesAllowed.Hotel AS Hotel,
				|	CalendarDayTypesAllowed.CalendarDayTypeFrom.Parent AS DayTypeParent,
				|	CalendarDayTypesAllowed.CalendarDayTypeFrom.Weight AS WeightFrom,
				|	CalendarDayTypesAllowed.CalendarDayTypeTo.Weight AS WeightTo
				|FROM
				|	InformationRegister.CalendarDayTypesAllowed AS CalendarDayTypesAllowed
				|WHERE
				|	CalendarDayTypesAllowed.Calendar = &qCalendar
				|	AND CalendarDayTypesAllowed.RoomType = &qRoomType
				|	AND CalendarDayTypesAllowed.Hotel = &qHotel
				|	AND CalendarDayTypesAllowed.Period = &qPeriod";
				vQry.SetParameter("qCalendar", vCalendar);
				vQry.SetParameter("qRoomType", vRoomType);
				vQry.SetParameter("qHotel", vHotel);
				vQry.SetParameter("qPeriod", vAccountingDate);
				vRestrictions = vQry.Execute().Unload();
				For Each vRestrictionsRow In vRestrictions Do
					If vRestrictionsRow.WeightFrom > vWeight Or vRestrictionsRow.WeightTo < vWeight Or vRestrictionsRow.DayTypeParent <> vCalendarDayType.Parent Then
						pCancel = True;  
						vErrMsg = NStr("en = 'Day type is not in the list of allowed day types!'; 
						               |de = 'Tag-Typ ist nicht in der Liste der zulässigen Tag-Typen!'; 
						               |ru = 'Тип дня не входит в список разрешенных типов дней!'");
						tcCommonFunctionOnClientServer.UserMessage(vErrMsg);
						Return;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel, pReplacing)   
	If DataExchange.Load Then
		Return;
	EndIf;
	// Check if for the all dates in record set there are dates in main calendar days register
	For Each vRcd In ThisObject Do
		If ValueIsFilled(vRcd.Calendar) And ValueIsFilled(vRcd.AccountingDate) Then
			If Not MainCalendarRecordExists(vRcd.Calendar, vRcd.AccountingDate, vRcd.Period) Then
				vMainRcd = InformationRegisters.CalendarDays.CreateRecordManager();
				FillPropertyValues(vMainRcd, vRcd);
				vMainRcd.Write(True);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // OnWrite

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function MainCalendarRecordExists(pCalendar, pAccountingDate, pPeriod)
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	CalendarDays.Calendar AS Calendar,
	|	CalendarDays.AccountingDate AS AccountingDate,
	|	CalendarDays.Period AS Period,
	|	CalendarDays.CalendarDayType AS CalendarDayType,
	|	CalendarDays.RoomPrice AS RoomPrice,
	|	CalendarDays.RoomPriceCurrency AS RoomPriceCurrency
	|FROM
	|	InformationRegister.CalendarDays AS CalendarDays
	|WHERE
	|	CalendarDays.Calendar = &qCalendar
	|	AND CalendarDays.AccountingDate = &qAccountingDate
	|	AND CalendarDays.Period <= &qPeriod
	|
	|ORDER BY
	|	AccountingDate,
	|	Period DESC";
	vQry.SetParameter("qCalendar", pCalendar);
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qPeriod", pPeriod);
	vRows = vQry.Execute().Unload();
	If vRows.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // MainCalendarRecordExists

#EndRegion
