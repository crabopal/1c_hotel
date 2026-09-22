
#Region Public

// -----------------------------------------------------------------------------
Procedure pmExecute() Export
	// Create guest group if it is not filled
	If Not ValueIsFilled(GuestGroupTo) Then
		vGroupObj = Catalogs.GuestGroups.CreateItem();
		vGroupObj.Owner = Hotel;
		vGuestGroupFolder = vGroupObj.Owner.GetObject().pmGetGuestGroupFolder();
		If ValueIsFilled(vGuestGroupFolder) Then
			vGroupObj.Parent = vGuestGroupFolder;
		EndIf;
		vGroupObj.OneCustomerPerGuestGroup = vGroupObj.Owner.OneCustomerPerGuestGroup;
		vGroupObj.SetNewCode(); 
		
		// Fill group type and room quotas
		vGroupObj.GroupType = GuestGroupFrom.GroupType;
		vGroupObj.Allotment = GuestGroupFrom.Allotment;

		vGroupObj.Write();
		
		GuestGroupTo = vGroupObj.Ref;
	EndIf;
	// Copy room reservations
	If CopyReservations Then
		// Get list of source guest group reservations
		vReservations = GuestGroupFrom.GetObject().pmGetReservations(True, False, False, False);
		If vReservations.Count() > 0 Then
			// Calculate dates shift
			vShift = 0;
			If ValueIsFilled(CheckInDateTo) Then
				If ValueIsFilled(CheckInDateFrom) Then
					vShift = BegOfDay(CheckInDateTo) - BegOfDay(CheckInDateFrom);
				ElsIf ValueIsFilled(GuestGroupFrom.CheckInDate) Then
					vShift = BegOfDay(CheckInDateTo) - BegOfDay(GuestGroupFrom.CheckInDate);
				EndIf;
			EndIf;
			// Process all source documents
			vSrcDocNumber = "";
			vNewDocNumber = "";
			For Each vReservationsRow In vReservations Do
				If ValueIsFilled(CheckInDateFrom) Then
					If BegOfDay(CheckInDateFrom) <> BegOfDay(vReservationsRow.CheckInDate) Then
						Continue;
					EndIf;
				EndIf;
				vNewDocObj = vReservationsRow.Reservation.Copy();
				vNewDocObj.pmFillAuthorAndDate();
				If IsBlankString(vSrcDocNumber) Then
					vSrcDocNumber = vReservationsRow.Reservation.Number;
				Else
					If vReservationsRow.Reservation.Number = vSrcDocNumber Then
						If Not IsBlankString(vNewDocNumber) Then 
							vNewDocObj.Number = vNewDocNumber;
						EndIf;
					Else
						vSrcDocNumber = vReservationsRow.Reservation.Number;
					EndIf;
				EndIf;
				vNewDocObj.AuthorOfAnnulation = Catalogs.Employees.EmptyRef();
				vNewDocObj.DateOfAnnulation = Undefined;
				vNewDocObj.AnnulationReason = Catalogs.UsualActionReasons.EmptyRef();
				If ValueIsFilled(vNewDocObj.Hotel.NewReservationStatus) Then
					vNewDocObj.ReservationStatus = vNewDocObj.Hotel.NewReservationStatus;
					vNewDocObj.pmSetDoCharging();
				EndIf;
				vNewDocObj.GuestGroup = GuestGroupTo;
				vNewDocObj.CheckInDate = vNewDocObj.CheckInDate + vShift;
				vNewDocObj.CheckOutDate = vNewDocObj.pmCalculateCheckOutDate();
				// Process services
				For Each vSrvRow In vNewDocObj.Services Do
					If vSrvRow.IsManual Then
						If ValueIsFilled(vSrvRow.AccountingDate) Then
							vSrvRow.AccountingDate = vSrvRow.AccountingDate + vShift;
						EndIf;
						vSrvRow.IsManualAuthor = SessionParameters.CurrentUser;
						vSrvRow.IsManualDate = CurrentSessionDate();
					EndIf;
				EndDo;
				vNewDocObj.pmCalculateServices();
				vNewDocObj.Write(DocumentWriteMode.Posting);
				// Save current document number
				vNewDocNumber = vNewDocObj.Number;
				// Write to the document change history
				vNewDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				#If CLIENT Then
					UserInterruptProcessing();
				#EndIf
			EndDo;
		EndIf;
	EndIf;
	// Copy room reservations
	If CopyResourceReservations Then
		// Get list of source guest group reservations
		vResReservations = GuestGroupFrom.GetObject().pmGetResourceReservations(True);
		If vResReservations.Count() > 0 Then
			// Calculate dates shift
			vShift = 0;
			If ValueIsFilled(CheckInDateTo) Then
				If ValueIsFilled(CheckInDateFrom) Then
					vShift = BegOfDay(CheckInDateTo) - BegOfDay(CheckInDateFrom);
				ElsIf ValueIsFilled(GuestGroupFrom.CheckInDate) Then
					vShift = BegOfDay(CheckInDateTo) - BegOfDay(GuestGroupFrom.CheckInDate);
				EndIf;
			EndIf;
			// Folio to be used
			vOldCharingFolio = Undefined;
			vNewCharingFolio = Undefined;
			// Process all source documents
			For Each vReservationsRow In vResReservations Do
				If ValueIsFilled(CheckInDateFrom) Then
					If BegOfDay(CheckInDateFrom) <> BegOfDay(vReservationsRow.DateTimeFrom) Then
						Continue;
					EndIf;
				EndIf;
				If vOldCharingFolio = Undefined Then
					vOldCharingFolio = vReservationsRow.ChargingFolio;
				EndIf;
				// Do copy			
				vNewDocObj = vReservationsRow.Reservation.Copy();
				vNewDocObj.pmFillAuthorAndDate();
				vNewDocObj.AuthorOfAnnulation = Catalogs.Employees.EmptyRef();
				vNewDocObj.DateOfAnnulation = Undefined;
				vNewDocObj.AnnulationReason = Catalogs.UsualActionReasons.EmptyRef();
				vNewDocObj.ParentDoc = Undefined;
				vNewDocObj.IsClosedForEdit = False;
				vNewDocObj.ExchangeRateDate = CurrentSessionDate();
				If ValueIsFilled(vNewDocObj.Hotel.NewResourceReservationStatus) Then
					vNewDocObj.ResourceReservationStatus = vNewDocObj.Hotel.NewResourceReservationStatus;
					vNewDocObj.DoCharging = vNewDocObj.ResourceReservationStatus.DoCharging;
				EndIf;
				vNewDocObj.DoChargingToDate = '00010101';
				vNewDocObj.GuestGroup = GuestGroupTo;
				If ValueIsFilled(vNewDocObj.DateTimeFrom) Then
					vNewDocObj.DateTimeFrom = vNewDocObj.DateTimeFrom + vShift;
				EndIf;
				If ValueIsFilled(vNewDocObj.DateTimeTo) Then
					vNewDocObj.DateTimeTo = vNewDocObj.DateTimeTo + vShift;
				EndIf;
				// Services
				For Each vSrvRow In vNewDocObj.Services Do
					If vSrvRow.IsManual Then
						If ValueIsFilled(vSrvRow.AccountingDate) Then
							vSrvRow.AccountingDate = vSrvRow.AccountingDate + vShift;
						EndIf;
						If ValueIsFilled(vSrvRow.DateTimeFrom) Then
							vSrvRow.DateTimeFrom = vSrvRow.DateTimeFrom + vShift;
						EndIf;
						If ValueIsFilled(vSrvRow.DateTimeTo) Then
							vSrvRow.DateTimeTo = vSrvRow.DateTimeTo + vShift;
						EndIf;
						vSrvRow.IsManualAuthor = SessionParameters.CurrentUser;
						vSrvRow.IsManualDate = CurrentSessionDate();
					EndIf;
				EndDo;
				// Folio
				If ValueIsFilled(vReservationsRow.ChargingFolio) And 
				   vReservationsRow.ChargingFolio.ParentDoc = vReservationsRow.Reservation And 
				   GuestGroupTo <> GuestGroupFrom Then
					If vOldCharingFolio = vReservationsRow.ChargingFolio Then
						If ValueIsFilled(vNewCharingFolio) Then
							vNewDocObj.ChargingFolio = vNewCharingFolio;
						Else
							vNewDocObj.pmCreateFolio();
							vNewCharingFolio = vNewDocObj.ChargingFolio;
						EndIf;
					Else
						vOldCharingFolio = vReservationsRow.ChargingFolio;
						vNewDocObj.pmCreateFolio();
						vNewCharingFolio = vNewDocObj.ChargingFolio;
					EndIf;
					If ValueIsFilled(vNewDocObj.ChargingFolio) Then
						vNewDocObj.FolioCurrency = vNewDocObj.ChargingFolio.FolioCurrency;
						vNewDocObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vNewDocObj.Hotel, vNewDocObj.FolioCurrency, vNewDocObj.ExchangeRateDate);
					EndIf;
				EndIf;
				vNewDocObj.pmCalculateServices();
				vNewDocObj.Write(DocumentWriteMode.Posting);
				// Write to the document change history
				vNewDocObj.pmWriteToResourceReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				#If CLIENT Then
					UserInterruptProcessing();
				#EndIf
			EndDo;
		EndIf;
	EndIf;
EndProcedure // pmExecute

#EndRegion
