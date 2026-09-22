// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Record.Period) Then
		Record.Period = CurrentSessionDate();
		Record.Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	If Not ValueIsFilled(Record.Hotel) Then
		If ValueIsFilled(Record.RoomType) Then
			Record.RoomType = PredefinedValue("Catalog.RoomTypes.EmptyRef");
		EndIf;
	Else
		vHotel = tcOnServer.cmGetAttributeByRef(Record.RoomType, "Owner");
		If vHotel <> Record.Hotel Then
			Record.RoomType = PredefinedValue("Catalog.RoomTypes.EmptyRef");
		EndIf;
	EndIf;
EndProcedure // HotelOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	vMessage = "";
	If Not ValueIsFilled(pCurrentObject.CalendarDayTypeFrom) Or Not ValueIsFilled(pCurrentObject.CalendarDayTypeTo) Then
		vMessage = NStr("en='Both day types in range has to be filled!'; ru='Необходимо заполнить типы дней границ диапазона!'; de='Es ist notwendig, die Tage Typen von Bereichsgrenzen zu füllen!'");
	ElsIf pCurrentObject.CalendarDayTypeFrom.Parent <> pCurrentObject.CalendarDayTypeTo.Parent Then
		vMessage = NStr("en='Day types should be from the same parent folder!'; ru='Типы дней должны быть из одной родительской папки!'; de='Die Tage Typen müssen aus einem Gruppe stammen!'");
	ElsIf pCurrentObject.CalendarDayTypeFrom.Weight > pCurrentObject.CalendarDayTypeTo.Weight Then
		vMessage = NStr("en='Left border day type weight should be less or equal to the right border day type weight!'; ru='Вес типа дня левой границы диапазона должен быть меньше или равен весу типа дня правой границы!'; de='Das Gewicht des tagestyps der linken Bereichsgrenze sollte kleiner oder gleich dem Gewicht des tagestyps der rechten Grenze sein!'");
	EndIf;
	If Not IsBlankString(vMessage) Then
		pCancel = True;
		SetObjectAndFormAttributeConformity(pCurrentObject, "Record");
		vUM = New UserMessage();
		vUM.SetData(pCurrentObject);
		vUM.Field = "CalendarDayTypeFrom";
		vUM.Text = vMessage;
		vUM.Message();
	EndIf;
EndProcedure // BeforeWriteAtServer
