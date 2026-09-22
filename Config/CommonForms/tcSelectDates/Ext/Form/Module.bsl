
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelDefaultDate = BegOfDay(CurrentSessionDate());
	If Parameters.Property("DefaultDate") And ValueIsFilled(Parameters.DefaultDate) Then
		SelDefaultDate = Parameters.DefaultDate;
	EndIf;
	Items.SelCalendar.BeginOfRepresentationPeriod = SelDefaultDate;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionExecute(pCommand)
	NotifyChoice(Items.SelCalendar.SelectedDates);
EndProcedure // ActionExecute

#EndRegion
