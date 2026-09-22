
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelDocRef") Then
		SelDocRef = Parameters.SelDocRef;
		If Parameters.Property("UseNewGroup") Then
			UseNewGroup = Parameters.UseNewGroup;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionExecute(pCommand)
	If ActionExecuteAtServer() Then
		Notify("Document.ResourceReservation.Write");
		ThisForm.Close();
	EndIf;
EndProcedure // ActionExecute

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function ActionExecuteAtServer()
	vResult = False;
	vDates = Items.SelCalendar.SelectedDates;
	vDateTimeFrom = SelDocRef.DateTimeFrom;
	vDateTimeTo = SelDocRef.DateTimeTo;
	vNewGroup = Undefined;
	vNewFolio = Undefined;
	If ValueIsFilled(vDateTimeFrom) And ValueIsFilled(vDateTimeTo) Then 
		If vDates.Count() > 0 Then
			For Each vDate In vDates Do
				vShift = BegOfDay(vDate) - BegOfDay(vDateTimeFrom);
				vNewDoc = SelDocRef.Copy();
				vNewDoc.pmFillAuthorAndDate();
				If vNewDoc.ResourceReservationStatus.ServicesAreDelivered Then
					vNewDoc.ResourceReservationStatus = vNewDoc.Hotel.NewResourceReservationStatus;
					If ValueIsFilled(vNewDoc.ResourceReservationStatus) Then
						vNewDoc.DoCharging = vNewDoc.ResourceReservationStatus.DoCharging;
					EndIf;
				EndIf;
				vNewDoc.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vNewDoc.Hotel, vNewDoc.ReportingCurrency, vNewDoc.Date);
				If UseNewGroup Then
					If vNewGroup = Undefined Then
						vNewDoc.pmCreateGuestGroup();
						vNewGroup = vNewDoc.GuestGroup;
					Else
						vNewDoc.GuestGroup = vNewGroup;
					EndIf;
					If vNewFolio = Undefined Then
						vNewDoc.pmCreateFolio();
						vNewFolio = vNewDoc.ChargingFolio;
					Else
						vNewDoc.ChargingFolio = vNewFolio;
					EndIf;
				EndIf;
				If ValueIsFilled(vNewDoc.DateTimeFrom) Then
					vNewDoc.DateTimeFrom = vNewDoc.DateTimeFrom + vShift;
				EndIf;
				If ValueIsFilled(vNewDoc.DateTimeTo) Then
					vNewDoc.DateTimeTo = vNewDoc.DateTimeTo + vShift;
				EndIf;
				For Each vSrvRow In vNewDoc.Services Do
					If ValueIsFilled(vSrvRow.AccountingDate) Then	
						vSrvRow.AccountingDate = vSrvRow.AccountingDate + vShift;
					EndIf;
					If ValueIsFilled(vSrvRow.DateTimeFrom) Then
						vSrvRow.DateTimeFrom = vSrvRow.DateTimeFrom + vShift;
					EndIf;
					If ValueIsFilled(vSrvRow.DateTimeTo) Then
						vSrvRow.DateTimeTo = vSrvRow.DateTimeTo + vShift;
					EndIf;
				EndDo;
				vNewDoc.Write(DocumentWriteMode.Posting);
			EndDo;
			vResult = True;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // ActionExecuteAtServer

#EndRegion
