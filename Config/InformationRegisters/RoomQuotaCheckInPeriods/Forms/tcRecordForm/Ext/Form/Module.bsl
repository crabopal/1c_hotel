
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("CheckInDate")Then
		Record.CheckInDate = Parameters.CheckInDate;
	EndIf;
	If Parameters.Property("CheckOutDate")Then
		Record.CheckOutDate = Parameters.CheckOutDate;
	EndIf;
	If Parameters.Property("Duration")Then
		Record.Duration = Parameters.Duration;
	EndIf;
	If Parameters.Property("RoomQuota")Then
		Record.RoomQuota = Parameters.RoomQuota;
	EndIf;
	If Parameters.Property("Hotel")Then
		Record.Hotel = Parameters.Hotel;
	Else
		Record.Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(Item)
	If ValueIsFilled(Record.CheckInDate) Then
		Record.CheckOutDate = EndOfDay(Record.CheckInDate) + 24*3600*(Record.Duration - 1);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(Item)
	If ValueIsFilled(Record.CheckInDate) and ValueIsFilled(Record.Duration) Then
		Record.CheckOutDate = Record.CheckInDate + 	Record.Duration * 24*60*60;
	EndIf;	
EndProcedure

#EndRegion
