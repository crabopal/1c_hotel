
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
				|	AND CalendarDayTypesAllowed.Period = &qPeriod
				|	AND CalendarDayTypesAllowed.RoomType = &qEmptyRoomType";
				vQry.SetParameter("qCalendar", vCalendar);
				vQry.SetParameter("qPeriod", vAccountingDate);
				vQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
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
EndProcedure // OnWrite

#EndRegion
