// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("FillingValues") And TypeOf(Parameters.FillingValues) = Type("Structure") Then
		If Parameters.FillingValues.Property("SpecialOffer") And ValueIsFilled(Parameters.FillingValues.SpecialOffer) Then
			Record.SpecialOffer = Parameters.FillingValues.SpecialOffer;
		EndIf;
	EndIf;
	If ValueIsFilled(Record.SpecialOffer) Then
		Items.SpecialOffer.ReadOnly = True;
		Items.SpecialOffer.SkipOnInput = True;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	SetObjectAndFormAttributeConformity(pCurrentObject, "Record");
	If pCurrentObject.DateValidFrom > pCurrentObject.DateValidTo And ValueIsFilled(pCurrentObject.DateValidTo) Then
		vUM = New UserMessage();
		vUM.Field = "DateValidTo";
		vUM.SetData(pCurrentObject);
		vUM.Text = NStr("en='Reservation creation date period is wrong!'; ru='Неправильный период создания брони!'; de='Der Zeitraum für das Erstellungsdatum der Reservierung ist falsch!'");
		vUM.Message();
		pCancel = True;
	EndIf;
	If pCurrentObject.CheckInDateFrom > pCurrentObject.CheckInDateTo And ValueIsFilled(pCurrentObject.CheckInDateTo) Then
		vUM = New UserMessage();
		vUM.Field = "CheckInDateTo";
		vUM.SetData(pCurrentObject);
		vUM.Text = NStr("en='Reservation check-in date period is wrong!'; ru='Неправильный период заезда брони!'; de='Der Zeitraum für das Anreisedatum der Reservierung ist falsch!'");
		vUM.Message();
		pCancel = True;
	EndIf;
	If pCurrentObject.PeriodOfStayFrom > pCurrentObject.PeriodOfStayTo And ValueIsFilled(pCurrentObject.PeriodOfStayTo) Then
		vUM = New UserMessage();
		vUM.Field = "PeriodOfStayTo";
		vUM.SetData(pCurrentObject);
		vUM.Text = NStr("en='Reservation period of stay is wrong!'; ru='Неправильный период проживания!'; de='Buchungszeitraum des Aufenthalts ist falsch!!'");
		vUM.Message();
		pCancel = True;
	EndIf;
EndProcedure // BeforeWriteAtServer
