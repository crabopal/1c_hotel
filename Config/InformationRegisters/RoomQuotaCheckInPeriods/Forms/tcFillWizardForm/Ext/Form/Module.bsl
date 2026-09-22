
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Hotel") Then
		SelHotel	    = Parameters.Hotel;
	Else
		SelHotel	    = SessionParameters.CurrentHotel;
	EndIf;
	If Parameters.Property("RoomQuota") Then
		SelRoomQuota	= Parameters.RoomQuota;
	EndIf;
	If Parameters.Property("CheckInDate") Then
		SelCheckInDate	= Parameters.CheckInDate;
	EndIf;
	If Parameters.Property("Duration") Then
		SelDuration	    = Parameters.Duration;
	EndIf;
	If Parameters.Property("CheckOutDate") Then
		SelCheckOutDate	= Parameters.CheckOutDate;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
Function CheckAttributes(pMessage, pAttributeInErr)
	pMessage = "";
	pAttributeInErr = "";
	vHasErrors = False; 
	vMsgTextRu = "";
	vMsgTextEn = "";
	If Not ValueIsFilled(SelHotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "SelHotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(SelCheckInDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата и время заезда> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Check-in date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "SelCheckInDate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(SelCheckOutDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата и время выезда> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Check-out date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "SelCheckOutDate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(SelDateFrom) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата начала периода> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Period start date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "SelDateFrom", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(SelDateTo) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата окончания периода> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Period end date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "SelDateTo", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckAttributes

// --------------------------------------------------------------------------------
&AtClient
Procedure SelCheckInDateOnChange(Item)
	SelCheckInDateOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelDurationOnChange(Item)
	SelDurationOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelCheckOutDateOnChange(Item)
	SelCheckOutDateOnChangeAtServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Start(Command)
	StartAtServer();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure StartAtServer()
	Var vMessage, vAttributeInErr;
	// Check wizard attributes first
	pCancel = CheckAttributes(vMessage, vAttributeInErr);
	If pCancel Then
		WriteLogEvent(NStr("en = 'Wizard.FillAllowedHotelAccommodationPeriodsList'; de = 'Мастер.ЗаполнитьСписокРазрешенныхПериодовПроживания'; ru = 'Мастер.ЗаполнитьСписокРазрешенныхПериодовПроживания'"), EventLogLevel.Warning, , , NStr(vMessage));
		tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage));

		Return;
	EndIf;
	// Create periods starting from the period from date
	Try
		BeginTransaction(DataLockControlMode.Managed);
		
		vCheckInDate = BegOfDay(SelDateFrom) + Hour(SelCheckInDate) * 3600 + Minute(SelCheckInDate) * 60;
		vCheckOutDate = BegOfDay(vCheckInDate + SelDuration * 24 * 3600) + Hour(SelCheckOutDate) * 3600 + Minute(SelCheckOutDate) * 60;
		
		vMgrObj = InformationRegisters.RoomQuotaCheckInPeriods.CreateRecordManager();
		While vCheckOutDate < SelDateTo Do
			vMgrObj.Hotel = SelHotel;
			vMgrObj.RoomQuota = SelRoomQuota;
			vMgrObj.CheckInDate = vCheckInDate;
			vMgrObj.Duration = SelDuration;
			vMgrObj.CheckOutDate = vCheckOutDate;
			vMgrObj.Read();
			If Not vMgrObj.Selected() Then
				vMgrObj.Hotel = SelHotel;
				vMgrObj.RoomQuota = SelRoomQuota;
				vMgrObj.CheckInDate = vCheckInDate;
				vMgrObj.Duration = SelDuration;
				vMgrObj.CheckOutDate = vCheckOutDate;
				vMgrObj.IsManual = False;
				vMgrObj.Write(True);
			EndIf;
			
			// Calculate next check in and check out date
			vCheckInDate = BegOfDay(vCheckOutDate + SelGap * 24 * 3600) + Hour(vCheckInDate) * 3600 + Minute(vCheckInDate) * 60;
			vCheckOutDate = BegOfDay(vCheckInDate + SelDuration * 24 * 3600) + Hour(vCheckOutDate) * 3600 + Minute(vCheckOutDate) * 60;
		EndDo;
		
		CommitTransaction();
		
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Process is finished!'; de = 'Die Bearbeitung wurde ausgeführt!'; ru = 'Обработка выполнена!'"));
	Except
		vErrInfo = ErrorInfo();
		WriteLogEvent(NStr("en = 'Wizard.FillAllowedHotelAccommodationPeriodsList'; de = 'Мастер.ЗаполнитьСписокРазрешенныхПериодовПроживания'; ru = 'Мастер.ЗаполнитьСписокРазрешенныхПериодовПроживания'"), EventLogLevel.Warning, , , cmGetRootErrorDescription(vErrInfo));
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		//ShowErrorInfo(vErrInfo);
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Process is not finished! All changes are canceled.'; de = 'Bearbeitung nicht ausgeführt! Alle Veränderungen werden rückgängig gemacht.'; ru = 'Обработка не выполнена! Все изменения отменены.'"));
	EndTry;

EndProcedure

// -----------------------------------------------------------------------------
// Calculates and returns duration for giving check in and check out dates 
&AtServer
Function CalculateDuration(pRoomRate, pCheckInDate, pCheckOutDate)
	vDuration = 0;
	If ValueIsFilled(pCheckInDate) And
	   ValueIsFilled(pCheckOutDate) Then
		vReferenceHour = 0;
		vDurationCalculationRuleType = Undefined;
		vPeriodInHours = 24;
		If ValueIsFilled(pRoomRate) Then
			vDurationCalculationRuleType = pRoomRate.DurationCalculationRuleType;
			vReferenceHour = pRoomRate.ReferenceHour - BegOfDay(pRoomRate.ReferenceHour);
		EndIf;
		If vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour And 
		   vReferenceHour = 0 Then
			vPerInSec = EndOfDay(pCheckOutDate) - BegOfDay(pCheckInDate);
			vDuration = Round(vPerInSec / vPeriodInHours / 3600, 0);
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			vPerInSec = (BegOfDay(pCheckOutDate) + vReferenceHour) - (BegOfDay(pCheckInDate) + vReferenceHour);
			vDuration = Round(vPerInSec / vPeriodInHours / 3600, 0);
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
			vPerInSec = EndOfDay(pCheckOutDate) - BegOfDay(pCheckInDate);
			vDuration = Round(vPerInSec / vPeriodInHours / 3600, 0);
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByNights Then
			vPerInSec = pCheckOutDate - pCheckInDate;
			vDuration = Round(vPerInSec / vPeriodInHours / 3600, 0);
		Else
			vPerInSec = pCheckOutDate - pCheckInDate;
			vDuration = Round(vPerInSec / vPeriodInHours / 3600, 0);
		EndIf;
	EndIf;
	Return vDuration;
EndFunction // CalculateDuration

// -----------------------------------------------------------------------------
// Calculates and returns check out date based on giving duration and check in date  
&AtServer
Function CalculateCheckOutDate(pRoomRate, pCheckInDate, pDuration, pCheckOutDate)
	vCheckOutDate = pCheckOutDate;
	If ValueIsFilled(pCheckInDate) And pDuration > 0 Then
		vReferenceHour = 0;
		vDurationCalculationRuleType = Undefined;
		vPeriodInHours = 24;
		If ValueIsFilled(pRoomRate) Then
			vDurationCalculationRuleType = pRoomRate.DurationCalculationRuleType;
			vReferenceHour = pRoomRate.ReferenceHour - BegOfDay(pRoomRate.ReferenceHour);
		EndIf;
		If vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			If vReferenceHour = 0 Then
				vCheckOutDate = BegOfDay(pCheckInDate) + vReferenceHour + pDuration * vPeriodInHours * 3600 - 1;
			Else
				vCheckOutDate = BegOfDay(pCheckInDate) + vReferenceHour + pDuration * vPeriodInHours * 3600;
			EndIf;
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
			vCheckOutDate = BegOfDay(pCheckInDate) + pDuration * vPeriodInHours * 3600 - 3 * 3600;
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByNights Then
			vCheckInTime = pCheckInDate - BegOfDay(pCheckInDate);
			If vCheckInTime <= 9 * 3600 Then // Breakfast check-in
				vCheckOutDate = BegOfDay(pCheckInDate) + pDuration * vPeriodInHours * 3600 + 7 * 3600;
			ElsIf vCheckInTime <= 14 * 3600 Then // Lunch check-in
				vCheckOutDate = BegOfDay(pCheckInDate) + pDuration * vPeriodInHours * 3600 + 12 * 3600;
			ElsIf vCheckInTime <= 20 * 3600 Then // Supper check-in
				vCheckOutDate = BegOfDay(pCheckInDate) + pDuration * vPeriodInHours * 3600 + 18 * 3600;
			Else  // Late check-in
				vCheckOutDate = BegOfDay(pCheckInDate) + pDuration * vPeriodInHours * 3600 + 21 * 3600;
			EndIf;
		Else
			vCheckOutDate = cm0SecondShift(pCheckInDate + pDuration * vPeriodInHours * 3600);
		EndIf;
	EndIf;
	Return vCheckOutDate;
EndFunction // CalculateCheckOutDate

// --------------------------------------------------------------------------------
&AtServer
Procedure SelCheckInDateOnChangeAtServer()
	If ValueIsFilled(SelRoomQuota) And ValueIsFilled(SelRoomQuota.RoomRate) Then
		If SelRoomQuota.RoomRate.PeriodInHours = 24 And SelRoomQuota.RoomRate.ReferenceHour > '00010101' Then
			If SelCheckInDate = BegOfDay(SelCheckInDate) Then
				SelCheckInDate = cmAddTime(SelCheckInDate, SelRoomQuota.RoomRate.ReferenceHour, False);
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(SelRoomQuota) Then
		SelDuration = CalculateDuration(SelRoomQuota.RoomRate, SelCheckInDate, SelCheckOutDate);
		SelDateFrom = BegOfDay(SelCheckInDate);
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Fill allotment first!'; ru='Не указана квота!'; de='Füllen Sie die Zuteilung zuerst aus!'"));
	EndIf;
	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelDurationOnChangeAtServer()
	If ValueIsFilled(SelRoomQuota) Then
		SelCheckOutDate = CalculateCheckOutDate(SelRoomQuota.RoomRate, SelCheckInDate, SelDuration, SelCheckOutDate);
		SelDateFrom = BegOfDay(SelCheckInDate);
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Fill allotment first!'; ru='Не указана квота!'; de='Füllen Sie die Zuteilung zuerst aus!'"));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelCheckOutDateOnChangeAtServer()
	If ValueIsFilled(SelRoomQuota) Then
		SelDuration = CalculateDuration(SelRoomQuota.RoomRate, SelCheckInDate, SelCheckOutDate);
		SelDateFrom = BegOfDay(SelCheckInDate);
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Fill allotment first!'; ru='Не указана квота!'; de='Füllen Sie die Zuteilung zuerst aus!'"));
	EndIf;
EndProcedure

#EndRegion
