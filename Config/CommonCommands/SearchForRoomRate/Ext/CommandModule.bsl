#Region EventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vHotel = Undefined;
	vRoomRate = Undefined;
	vCheckInDate = Undefined;
	vCheckOutDate = Undefined;
	FillDefaultParametersAtServer(vHotel, vRoomRate, vCheckInDate, vCheckOutDate);
	vParams = New Structure("Hotel, RoomType, CheckInDate, CheckOutDate, Duration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, AgeArray, SelectRoomRateMode", 
	                         vHotel, PredefinedValue("Catalog.RoomTypes.EmptyRef"), vCheckInDate, vCheckOutDate, 1, , , , 1, 0, New Array, True);
	vFrm = OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", vParams);
EndProcedure // CommandProcessing

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtServer
Procedure FillDefaultParametersAtServer(rHotel, rRoomRate, rCheckInDate, rCheckOutDate)
	rHotel = SessionParameters.CurrentHotel;
	rRoomRate = rHotel.RoomRate;
	vRH = cmGetReferenceHour(rRoomRate);
	vCiT = cmGetDefaultCheckInTime(rRoomRate);
	vCoT = cmGetDefaultCheckOutTime(rRoomRate);
	rCheckInDate = CurrentSessionDate();
	If (vCiT - BegOfDay(vCiT)) > (rCheckInDate - BegOfDay(rCheckInDate)) Then
		rCheckInDate = cm1SecondShift(BegOfDay(rCheckInDate) + (vCiT - BegOfDay(vCiT)));
	EndIf;
	rCheckOutDate = rCheckInDate + 24*3600;
	rCheckOutDate = cm0SecondShift(BegOfDay(rCheckOutDate) + (vCoT - BegOfDay(vCoT)));
EndProcedure // FillDefaultParametersAtServer

#EndRegion
