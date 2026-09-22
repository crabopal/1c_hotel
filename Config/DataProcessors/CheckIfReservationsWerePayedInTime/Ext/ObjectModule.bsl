
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameters 
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(GuaranteedReservationStatus) Then
		If ValueIsFilled(Hotel) Then
			GuaranteedReservationStatus = Hotel.GuaranteedReservationStatus;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PaymentDateExpiredReservationStatus) Then
		If ValueIsFilled(Hotel) Then
			PaymentDateExpiredReservationStatus = Hotel.PaymentDateExpiredReservationStatus;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PaymentTimeExpiredReservationStatus) Then
		If ValueIsFilled(Hotel) Then
			PaymentTimeExpiredReservationStatus = Hotel.PaymentDateExpiredReservationStatus;
		EndIf;
	EndIf;
	If TimeToWaitOnlineReservationPayment = 0 Then
		TimeToWaitOnlineReservationPayment = 120;
	EndIf;
	If Not ValueIsFilled(DepartmentToSendNotificationsTo) Then
		If ValueIsFilled(Hotel) Then
			DepartmentToSendNotificationsTo = Hotel.ReservationDepartment;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Run data processor in silent mode
//
// Parameters:
//  pParameter		 - Structure - Parameters
//  pIsInteractive	 - Boolean	 - IsInteractive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Check reservations
	pmDoCheck(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
//
// Parameters:
//  pIsInteractive	 - Boolean	 - IsInteractive
//
Procedure pmDoCheck(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.CheckIfReservationsWerePayedInTime';ru='Обработка.ПроверитьПоступлениеОплатыПоБрони';de='DataProcessor.CheckIfReservationsWerePayedInTime'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	
	vSetTouristTaxDateMode = ValueIsFilled(Hotel) And Hotel.TouristTaxIsUsed And Hotel.TouristTaxAccountingDateSettingType = Enums.TouristTaxAccountingDateSettingTypes.UseDateOfFullPayment;
	
	If ValueIsFilled(GuaranteedReservationStatus) Or ValueIsFilled(FullyPaidReservationStatus) Or 
	   ValueIsFilled(GuaranteedOnlineReservationStatus) Or ValueIsFilled(FullyPaidOnlineReservationStatus) Or 
	   vSetTouristTaxDateMode Then
		// Get list of reservations with payments received
		vGuestGroups = New ValueList();
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Reservations.GuestGroup AS GuestGroup
		|INTO PayedGuestGroups
		|FROM
		|	Document.Reservation AS Reservations
		|		INNER JOIN (SELECT
		|			Payments.GuestGroup AS GuestGroup,
		|			Payments.SumExpense AS Sum
		|		FROM
		|			AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
		|					&qPeriodFrom,
		|					&qPeriodTo,
		|					Period,
		|					RegisterRecords,
		|					NOT &qHotelIsFilled
		|						OR &qHotelIsFilled
		|							AND Hotel IN HIERARCHY (&qHotel)) AS Payments
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			Preauthorisations.GuestGroup,
		|			Preauthorisations.Sum
		|		FROM
		|			Document.Preauthorisation AS Preauthorisations
		|		WHERE
		|			Preauthorisations.Posted
		|			AND Preauthorisations.Hotel IN HIERARCHY(&qHotel)
		|			AND Preauthorisations.Status = &qAuthorised) AS GuestGroupTurnovers
		|		ON (GuestGroupTurnovers.GuestGroup = Reservations.GuestGroup)
		|WHERE
		|	Reservations.Posted
		|	AND NOT Reservations.ReservationStatus.IsAnnulation
		|	AND NOT Reservations.ReservationStatus.IsCheckIn
		|	AND NOT Reservations.ReservationStatus.IsNoShow
		|	AND NOT Reservations.ReservationStatus.IsFullyPaid
		|	AND NOT Reservations.ReservationStatus.IsInWaitingList
		|	AND Reservations.ReservationStatus <> &qFullyPaidOnlineReservationStatus
		|	AND Reservations.ReservationStatus <> &qFullyPaidReservationStatus
		|	AND (NOT &qHotelIsFilled
		|			OR &qHotelIsFilled
		|				AND Reservations.Hotel IN HIERARCHY (&qHotel))
		|	AND (NOT Reservations.ReservationStatus.IsActive
		|				AND (Reservations.NumberOfBeds = 0
		|					AND Reservations.NumberOfAdditionalBeds = 0
		|					AND Reservations.NumberOfPersons = 0)
		|			OR (Reservations.ReservationStatus.IsActive
		|				OR Reservations.ReservationStatus.IsPreliminary)
		|				AND (Reservations.NumberOfBeds > 0
		|					OR Reservations.NumberOfAdditionalBeds > 0
		|					OR Reservations.NumberOfPersons > 0))
		|	AND TRUE
		|
		|GROUP BY
		|	Reservations.GuestGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Reservations.Ref AS Reservation,
		|	Reservations.ReservationStatus AS ReservationStatus,
		|	Reservations.GuestGroup AS GuestGroup,
		|	Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|		OR Reservations.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|			AND (Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
		|				OR Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds)) AS MainRoomReservation
		|FROM
		|	Document.Reservation AS Reservations
		|		INNER JOIN PayedGuestGroups AS PayedGuestGroups
		|		ON Reservations.GuestGroup = PayedGuestGroups.GuestGroup
		|WHERE
		|	Reservations.Posted
		|	AND NOT Reservations.ReservationStatus.IsAnnulation
		|	AND NOT Reservations.ReservationStatus.IsCheckIn
		|	AND NOT Reservations.ReservationStatus.IsNoShow
		|	AND NOT Reservations.ReservationStatus.IsFullyPaid   
		|	AND NOT Reservations.ReservationStatus.IsInWaitingList
		|	AND Reservations.ReservationStatus <> &qFullyPaidOnlineReservationStatus
		|	AND Reservations.ReservationStatus <> &qFullyPaidReservationStatus
		|	AND (NOT &qHotelIsFilled
		|			OR &qHotelIsFilled
		|				AND Reservations.Hotel IN HIERARCHY (&qHotel))
		|	AND (NOT Reservations.ReservationStatus.IsActive
		|				AND (Reservations.NumberOfBeds = 0
		|					AND Reservations.NumberOfAdditionalBeds = 0
		|					AND Reservations.NumberOfPersons = 0)
		|			OR (Reservations.ReservationStatus.IsActive
		|				OR Reservations.ReservationStatus.IsPreliminary)
		|				AND (Reservations.NumberOfBeds > 0
		|					OR Reservations.NumberOfAdditionalBeds > 0
		|					OR Reservations.NumberOfPersons > 0))
		|	AND CASE
		|			WHEN &qProcessReservationsFromIndividualsOnly
		|				THEN Reservations.Customer = VALUE(Catalog.Customers.EmptyRef)
		|						OR Reservations.Customer.IsIndividual
		|			ELSE TRUE
		|		END
		|	AND TRUE
		|	AND NOT Reservations.RoomRate.IsComplimentary
		|
		|GROUP BY
		|	Reservations.Ref,
		|	Reservations.GuestGroup,
		|	Reservations.ReservationStatus,
		|	Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|		OR Reservations.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|			AND (Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
		|				OR Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds))
		|
		|ORDER BY
		|	Reservations.GuestGroup.Code,
		|	Reservations.Ref.PointInTime";
		If (ValueIsFilled(GuaranteedReservationStatus) And ValueIsFilled(FullyPaidReservationStatus) And GuaranteedReservationStatus = FullyPaidReservationStatus)
			Or ValueIsFilled(GuaranteedReservationStatus) And Not ValueIsFilled(FullyPaidReservationStatus) Then
			vQry.Text = StrReplace(vQry.Text,"&ParamForReplace", " Not Reservations.ReservationStatus = &qGuaranteedReservationStatus");
			vQry.SetParameter("qGuaranteedReservationStatus", GuaranteedReservationStatus);
		Else
		    vQry.Text = StrReplace(vQry.Text,"&ParamForReplace", " True");
		EndIf;
		vQry.SetParameter("qPeriodFrom", '00010101');
		vQry.SetParameter("qPeriodTo", '39991231');
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qHotelIsFilled", ValueIsFilled(Hotel));
		vQry.SetParameter("qAuthorised", Enums.PreauthorisationStatuses.Authorised);
		vQry.SetParameter("qFullyPaidOnlineReservationStatus", FullyPaidOnlineReservationStatus);
		vQry.SetParameter("qFullyPaidReservationStatus", FullyPaidReservationStatus);
		vQry.SetParameter("qProcessReservationsFromIndividualsOnly", ProcessReservationsFromIndividualsOnly);
		vReservations = vQry.Execute();
		// Change reservation status for each reservation and post it
		vCurGuestGroup = Undefined;
		vGroupIsFullyPaid = False;
		vReservationsRow = vReservations.Select();
		While vReservationsRow.Next() Do
			Try
				// Get reservation object
				vReservationRef = vReservationsRow.Reservation;
				If TypeOf(vReservationRef) <> Type("DocumentRef.Reservation") Then
					Continue;
				EndIf;
				vReservationRefReservationStatus = vReservationsRow.ReservationStatus;
				// Check if the status has changed
				If vReservationRefReservationStatus <> vReservationRef.ReservationStatus Then
					 Continue;
				EndIf;	

				// Check if group is fully paid
				If ValueIsFilled(FullyPaidReservationStatus) Or ValueIsFilled(FullyPaidOnlineReservationStatus) Or vSetTouristTaxDateMode Then
					If vCurGuestGroup <> vReservationsRow.GuestGroup Then
						vGroupIsFullyPaid = False;
						vCurGuestGroup = vReservationsRow.GuestGroup;
						vCurGuestGroupObj = vCurGuestGroup.GetObject();
						vGroupSales = vCurGuestGroupObj.pmGetSalesTotals();
						vGroupSales.GroupBy("Currency", "Sales, SalesForecast");
						vGroupPayments = vCurGuestGroupObj.pmGetPaymentsTotals();
						If vGroupSales.Count() > 0 And vGroupSales.Count() = vGroupPayments.Count() Then
							vGroupIsPayed = True;
							i = 0;
							While i < vGroupSales.Count() Do
								vGroupSalesRow = vGroupSales.Get(i);
								vGroupPaymentsRow = vGroupPayments.Get(i);
								If vGroupSalesRow.Currency <> vGroupPaymentsRow.Currency Or 
								   vGroupSalesRow.Currency = vGroupPaymentsRow.Currency And 
								  (vGroupSalesRow.Sales + vGroupSalesRow.SalesForecast) > vGroupPaymentsRow.Sum Then
									vGroupIsPayed = False;
									Break;
								EndIf;
								i = i + 1;
							EndDo;
							If vGroupIsPayed Then
								vGroupIsFullyPaid = True;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				
				// Set reservation status
				vMessageTemplate = Undefined;  
				vNewReservationStatus = Undefined;
				vSetFullyPaidDate = False;
				If ValueIsFilled(FullyPaidOnlineReservationStatus) And vGroupIsFullyPaid And 
				   vReservationRef.ReservationStatus <> FullyPaidOnlineReservationStatus And vReservationRef.ReservationStatus <> FullyPaidReservationStatus And 
				   Not vReservationRef.ReservationStatus.IsFullyPaid And 
				  (vReservationRef.ReservationStatus = GuaranteedOnlineReservationStatus Or vReservationRef.ReservationStatus = NewOnlineReservationStatus) Then
					vNewReservationStatus = FullyPaidOnlineReservationStatus;
					If ValueIsFilled(FullyPaidMessageTemplate) Then
						vMessageTemplate = FullyPaidMessageTemplate;
					Else
						vMessageTemplate = GuaranteedMessageTemplate;
					EndIf;
				ElsIf ValueIsFilled(FullyPaidReservationStatus) And vGroupIsFullyPaid And 
				   vReservationRef.ReservationStatus <> FullyPaidReservationStatus And Not vReservationRef.ReservationStatus.IsFullyPaid And 
				   Not (vReservationRef.ReservationStatus = GuaranteedOnlineReservationStatus Or vReservationRef.ReservationStatus = NewOnlineReservationStatus Or vReservationRef.ReservationStatus = FullyPaidOnlineReservationStatus) Then
					vNewReservationStatus = FullyPaidReservationStatus;
					If ValueIsFilled(FullyPaidMessageTemplate) Then
						vMessageTemplate = FullyPaidMessageTemplate;
					Else
						vMessageTemplate = GuaranteedMessageTemplate;
					EndIf;
				ElsIf ValueIsFilled(GuaranteedOnlineReservationStatus) And vReservationRefReservationStatus = NewOnlineReservationStatus Then
					vNewReservationStatus = GuaranteedOnlineReservationStatus;
					vMessageTemplate = GuaranteedMessageTemplate;
				ElsIf ValueIsFilled(GuaranteedReservationStatus) And vReservationRefReservationStatus <> GuaranteedReservationStatus And Not vReservationRefReservationStatus.IsGuaranteed Then
					vNewReservationStatus = GuaranteedReservationStatus;
					vMessageTemplate = GuaranteedMessageTemplate;
				EndIf;
				If vSetTouristTaxDateMode And vGroupIsFullyPaid And Not ValueIsFilled(vReservationRef.TouristicTaxAccountingDate) Then
					vSetFullyPaidDate = True;
				EndIf;
				If Not ValueIsFilled(vNewReservationStatus) And Not vSetFullyPaidDate Then
					Continue;
				EndIf;
				
				vReservationObj = vReservationRef.GetObject();
				If ValueIsFilled(vNewReservationStatus) Then
					vReservationObj.ReservationStatus = vNewReservationStatus;
					vReservationObj.GuaranteeType = GuaranteeType;
					vReservationObj.pmSetDoCharging();
				EndIf;
				If vSetFullyPaidDate Then
					vReservationObj.TouristicTaxAccountingDate = BegOfDay(CurrentSessionDate());
				EndIf;
				If ValueIsFilled(vNewReservationStatus) And (vNewReservationStatus.DoNoShowCharging Or vNewReservationStatus.DoLateAnnulationCharging) Or
				   vSetFullyPaidDate Then
					vReservationObj.pmCalculateServices();
				EndIf;
				If vReservationObj.Modified() Then
					vReservationObj.Write(DocumentWriteMode.Posting);
					// Save data to the document history
					vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
				
				// Log current state
				vMessage = NStr("ru='Обработан документ: " + String(vReservationRef) + " - группа № " + TrimAll(vReservationObj.GuestGroup) + ", статус установлен в " + TrimAll(vReservationObj.ReservationStatus) + "'; 
				                |de='Document " + String(vReservationRef) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed, status was set to " + TrimAll(vReservationObj.ReservationStatus) + "'; 
								|en='Document " + String(vReservationRef) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed, status was set to " + TrimAll(vReservationObj.ReservationStatus) + "'");
				WriteLogEvent(NStr("en='DataProcessor.CheckIfReservationsWerePayedInTime';ru='Обработка.ПроверитьПоступлениеОплатыПоБрони';de='DataProcessor.CheckIfReservationsWerePayedInTime'"), EventLogLevel.Information, ThisObject.Metadata(), vReservationRef, vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
				EndIf;
				
				// Write attachment
				vSendEMail = False;
				vFax = "";
				vEMail = "";
				
				If ValueIsFilled(vReservationRef.Customer) Then
					vFax = vReservationRef.Customer.Fax;
					vEMail = vReservationRef.Customer.EMail;
					vSendEMail = True;
				EndIf;
				
				If Not ValueIsFilled(vEMail) Then
					vFax = vReservationRef.Fax;
					vEMail = vReservationRef.EMail;
					vSendEMail = True;
				EndIf;
				
				If Not ValueIsFilled(vEMail) And ValueIsFilled(vReservationRef.Guest) Then
					vFax = vReservationRef.Guest.Fax;
					vEMail = vReservationRef.Guest.EMail;
					vSendEMail = True;	
				EndIf;
								
				// Write guest group attachement
				If ValueIsFilled(ReplyMessageType) And ReplyMessageType = Enums.AttachmentTypes.EMail And vReservationsRow.MainRoomReservation And vSendEMail Then
					vGuestGroupRef = vReservationObj.GuestGroup;
					If vGuestGroups.FindByValue(vGuestGroupRef) = Undefined Then
						vGuestGroups.Add(vGuestGroupRef);
						vHotel = vGuestGroupRef.Owner;
						vLanguage = vHotel.Language;
						If ValueIsFilled(vGuestGroupRef.Client) And ValueIsFilled(vGuestGroupRef.Client.Language) Then
							vLanguage = vGuestGroupRef.Client.Language;
						EndIf;
						// Check should we print reservation confirmation or not
						vObjectPrintingForm = Undefined;
						If vLanguage = Catalogs.Languages.RU And ValueIsFilled(ReservationConfirmationPrintFormRu) Then
							vObjectPrintingForm = ReservationConfirmationPrintFormRu;
						ElsIf vLanguage = Catalogs.Languages.EN And ValueIsFilled(ReservationConfirmationPrintFormEn) Then
							vObjectPrintingForm = ReservationConfirmationPrintFormEn;
						ElsIf vLanguage = Catalogs.Languages.DE And ValueIsFilled(ReservationConfirmationPrintFormDe) Then
							vObjectPrintingForm = ReservationConfirmationPrintFormDe;
						EndIf;      
						vReservationStatusPrev = Catalogs.ReservationStatuses.pmGetReservationStatusDescription(vReservationObj.ReservationStatus, vLanguage);
						// Build message text
						vRemarks = StrTemplate(Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage) 
									+ cmNStr("en='. Status of reservation N %1 was changed to %2'; 
								          |de='. Status of reservation N %1 was changed to %2'; 
						                  |ru='. Статус брони № %1 изменен на %2'", 
						                  vLanguage), Format(vGuestGroupRef.Code, "ND=12; NFD=0; NG="), vReservationStatusPrev);
						// Apply template if it is specified
						vDocumentText = "";
						If ValueIsFilled(vMessageTemplate) Then
							vRemarks = cmNStr(TrimAll(vMessageTemplate.Description), vLanguage);
							If ValueIsFilled(vMessageTemplate.HTMLTextRu) Or ValueIsFilled(vMessageTemplate.HTMLTextEn) Or ValueIsFilled(vMessageTemplate.HTMLTextDe) Then
								vDocumentText = SMS.GetHTMLTextByLanguage(vMessageTemplate, vLanguage);
							EndIf;
							If IsBlankString(vDocumentText) Then
								vDocumentText = SMS.GetSMSTextByLanguage(vMessageTemplate, vLanguage);
							EndIf;
							If ValueIsFilled(vMessageTemplate.ObjectPrintingFormRu) Then
								vObjectPrintingForm = vMessageTemplate.ObjectPrintingFormRu;
							EndIf;
							If vLanguage = Catalogs.Languages.EN And ValueIsFilled(vMessageTemplate.ObjectPrintingFormEn) Then
								vObjectPrintingForm = vMessageTemplate.ObjectPrintingFormEn;
							ElsIf vLanguage = Catalogs.Languages.DE And ValueIsFilled(vMessageTemplate.ObjectPrintingFormDe) Then
								vObjectPrintingForm = vMessageTemplate.ObjectPrintingFormDe;
							EndIf;
						EndIf;
						If IsBlankString(vDocumentText) Then
							vDocumentText = cmNStr("en='Reservation status change notification:'; 
							                       |de='Benachrichtigung über Änderung des Reservierungsstatus:'; 
							                       |ru='Уведомление об изменении статусов брони:'", vLanguage) + Chars.LF + Chars.LF +
							                ?(ValueIsFilled(vGuestGroupRef) And ValueIsFilled(vGuestGroupRef.Client), cmNStr("en='Client name: ';ru='Клиент: ';de='Kunde: '", vLanguage) + TrimAll(vGuestGroupRef.Client.FullName) + Chars.LF, "") + 
							                ?(ValueIsFilled(vGuestGroupRef) And ValueIsFilled(vGuestGroupRef.CheckInDate) And ValueIsFilled(vGuestGroupRef.CheckOutDate), cmNStr("en='Period of stay: ';ru='Период проживания: ';de='Unterbringungszeitraum: '", vLanguage) + Format(vGuestGroupRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - "  + Format(vGuestGroupRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + Chars.LF, "") + 
							                Chars.LF + 
							                StrTemplate(cmNStr("en='Status of reservation N %1 was changed to %2'; 
											       |de='Status of reservation N %1 was changed to %2'; 
							                       |ru='Статус брони № %1 изменен на %2'", 
												   vLanguage), Format(vGuestGroupRef.Code, "ND=12; NFD=0; NG="), Catalogs.ReservationStatuses.pmGetReservationStatusDescription(vReservationObj.ReservationStatus, vLanguage)) + Chars.LF + Chars.LF + 
							                cmNStr("en='Best regards,'; 
											       |de='Best regards,'; 
											       |ru='С уважением,'", vLanguage) + Chars.LF + 
							                Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage) + Chars.LF + 
									        cmNStr(SessionParameters.ConfigurationName, vLanguage);
						EndIf;
						vConfirmationFileName = "";
						If ValueIsFilled(vObjectPrintingForm) Then
							vSpreadsheet = New SpreadsheetDocument();
							If ValueIsFilled(vObjectPrintingForm.ExternalProcessing) Then 
								vExtProc = vObjectPrintingForm.ExternalProcessing;
								vExtProcData = vExtProc.ExternalProcessingStorage.Get();
								vExtProcPath = GetTempFileName(".efd");
								vExtProcData.Write(vExtProcPath);
								vExtProcObject = ExternalDataProcessors.Create(vExtProcPath, False);
								vStruct = New Structure("InputParameter, ObjectPrintingForm", vReservationObj, vObjectPrintingForm);
								FillPropertyValues(vExtProcObject, vStruct);
								vExtProcObject.pmPrintConfirmation(vSpreadsheet, vReservationRef, Undefined, 0, Undefined, False, vLanguage, vObjectPrintingForm);  
								DeleteFiles(vExtProcPath);
							Else
								// Check predefined forms
								If vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRu Or
								   vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationEn Or
								   vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationDe Then
									vReservationObj.pmPrintConfirmation(vSpreadsheet, vReservationRef, Undefined, 0, Undefined, False, vLanguage, vObjectPrintingForm);
								ElsIf vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationRu Or
								      vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationEn Or
								      vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationDe Then
									vReservationObj.pmPrintConfirmation(vSpreadsheet, vReservationRef, Undefined, 0, Undefined, True, vLanguage, vObjectPrintingForm);
								ElsIf vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationWithServicesRu Or
									  vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationWithServicesEn Or
									  vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationWithServicesDe Then
									vReservationObj.pmPrintConfirmationWithServices(vSpreadsheet, vReservationRef, Undefined, 0, Undefined, True, vLanguage, vObjectPrintingForm);
								ElsIf vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationWithServicesRu Or
								      vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationWithServicesEn Or
								      vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationWithServicesDe Then
									vReservationObj.pmPrintConfirmationWithServices(vSpreadsheet, vReservationRef, Undefined, 0, Undefined, True, vLanguage, vObjectPrintingForm);
								EndIf;
							EndIf;
							// Save reservation confirmation to the temp PDF file
							vConfirmationFileName = StrReplace(cmNStr("en='Booking confirmation'; ru='Подтверждение брони'; de='Reservierungsbestätigung'", vLanguage) + " " + Format(vReservationObj.GuestGroup.Code, "ND=12; NFD=0; NG="), " ", "_") + ".pdf";
							vConfirmationFileName = cmGetFullFileName(vConfirmationFileName, TempFilesDir());
							vSpreadsheet.Write(vConfirmationFileName, SpreadsheetDocumentFileType.PDF);
						EndIf;
						// Call user exit procedure to give possibility to override message subject ans message text
						vUserExitProc = Catalogs.ExternalDataProcessors.WriteGuestGroupPaymentConfirmation;
						If ValueIsFilled(vUserExitProc) Then
							If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
								If Not IsBlankString(vUserExitProc.Algorithm) Then
									SetSafeMode(True);
									Execute(TrimAll(vUserExitProc.Algorithm));
									SetSafeMode(False);
								EndIf;
							EndIf;
						EndIf;
						InformationRegisters.GuestGroupAttachments.WriteData(, vGuestGroupRef,,,,,, vEMail, vFax, ReplyMessageType, Enums.AttachmentStatuses.Ready, vDocumentText, vMessageTemplate, vReservationRef,,, vConfirmationFileName,, True, vRemarks);
					EndIf;
				EndIf;
			Except
				vMessage = ErrorDescription();
				WriteLogEvent(NStr("en='DataProcessor.CheckIfReservationsWerePayedInTime';ru='Обработка.ПроверитьПоступлениеОплатыПоБрони';de='DataProcessor.CheckIfReservationsWerePayedInTime'"), EventLogLevel.Warning, ThisObject.Metadata(), vReservationRef, vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				EndIf;
			EndTry;
		EndDo;
	EndIf;
	
	// Get list of reservations with expired payment date
	vGuestGroups = New ValueList(); 
	vProcessedGuestGroups = New ValueTable();
	vProcessedGuestGroups.Columns.Add("GuestGroup", cmGetCatalogTypeDescription("GuestGroups"));
	vProcessedGuestGroups.Columns.Add("CheckDate", cmGetDateTimeTypeDescription());
	TimesToWaitOnlineReservationPayment.Sort("CheckInDateFrom, CheckInDateTo, NumberOfDaysBeforeCheckInSinceReservationFrom, NumberOfDaysBeforeCheckInSinceReservationTo");
	
	ChangeReservationStatus(pIsInteractive, vProcessedGuestGroups, vGuestGroups);	

	// Send notifications
	If ValueIsFilled(DepartmentToSendNotificationsTo) Then
		vGuestGroups = New ValueList();
		vProcessedGuestGroups.GroupBy("GuestGroup, CheckDate", );
		For Each vReservationsRow In vProcessedGuestGroups Do
			vGuestGroupRef = vReservationsRow.GuestGroup;
			If vGuestGroups.FindByValue(vGuestGroupRef) = Undefined Then
				vGuestGroups.Add(vGuestGroupRef);
				vMessageStatus = Undefined;
				If ValueIsFilled(vGuestGroupRef) And ValueIsFilled(vGuestGroupRef.Owner.MessageStatus) Then
					vMessageStatus = vGuestGroupRef.Owner.MessageStatus;
				EndIf;
				vMessage = NStr("ru='Просрочена оплата по брони группы № " + TrimAll(vGuestGroupRef) + ", " + TrimAll(vGuestGroupRef.Customer) + ", " + Format(vGuestGroupRef.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vGuestGroupRef.CheckOutDate, "DF=dd.MM.yyyy") + "!'; 
				                |de='Payment expired for the group N " + TrimAll(vGuestGroupRef) + ", " + TrimAll(vGuestGroupRef.Customer) + ", " + Format(vGuestGroupRef.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vGuestGroupRef.CheckOutDate, "DF=dd.MM.yyyy") + "!'; 
								|en='Payment expired for the group N " + TrimAll(vGuestGroupRef) + ", " + TrimAll(vGuestGroupRef.Customer) + ", " + Format(vGuestGroupRef.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vGuestGroupRef.CheckOutDate, "DF=dd.MM.yyyy") + "!'");
				cmSendMessageToDepartment(DepartmentToSendNotificationsTo, vMessage, vMessageStatus, False, vGuestGroupRef);
			EndIf;
		EndDo;
	EndIf;
	WriteLogEvent(NStr("en='DataProcessor.CheckIfReservationsWerePayedInTime';ru='Обработка.ПроверитьПоступлениеОплатыПоБрони';de='DataProcessor.CheckIfReservationsWerePayedInTime'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmDoCheck

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure ChangeReservationStatus(pIsInteractive, rProcessedGuestGroups, rGuestGroups)
	vQry = New Query();
	If TimesToWaitOnlineReservationPayment.Count() > 0 Then
		vQry.Text = 
		"SELECT
		|	TimesToWaitOnlineReservationPayment.CheckInDateFrom AS CheckInDateFrom,
		|	TimesToWaitOnlineReservationPayment.CheckInDateTo AS CheckInDateTo,
		|	TimesToWaitOnlineReservationPayment.NumberOfDaysBeforeCheckInSinceReservationFrom AS NumberOfDaysBeforeCheckInSinceReservationFrom,
		|	TimesToWaitOnlineReservationPayment.NumberOfDaysBeforeCheckInSinceReservationTo AS NumberOfDaysBeforeCheckInSinceReservationTo,
		|	TimesToWaitOnlineReservationPayment.TimeToWaitOnlineReservationPayment AS TimeToWaitOnlineReservationPayment
		|INTO TimesToWaits
		|FROM
		|	&qTimesToWaitOnlineReservationPayment AS TimesToWaitOnlineReservationPayment
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Reservations.GuestGroup AS GuestGroup
		|INTO PayedGuestGroups
		|FROM
		|	Document.Reservation AS Reservations
		|		INNER JOIN (SELECT
		|			Payments.GuestGroup AS GuestGroup,
		|			Payments.SumExpense AS Sum
		|		FROM
		|			AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
		|					&qPeriodFrom,
		|					&qPeriodTo,
		|					Period,
		|					RegisterRecords,
		|					NOT &qHotelIsFilled
		|						OR &qHotelIsFilled
		|							AND Hotel IN HIERARCHY (&qHotel)) AS Payments
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			Preauthorisations.GuestGroup,
		|			Preauthorisations.Sum
		|		FROM
		|			Document.Preauthorisation AS Preauthorisations
		|		WHERE
		|			Preauthorisations.Posted
		|			AND Preauthorisations.Hotel IN HIERARCHY(&qHotel)
		|			AND Preauthorisations.Status = &qAuthorised) AS GuestGroupTurnovers
		|		ON (GuestGroupTurnovers.GuestGroup = Reservations.GuestGroup)
		|WHERE
		|	Reservations.Posted
		|	AND NOT Reservations.ReservationStatus.IsAnnulation
		|	AND NOT Reservations.ReservationStatus.IsCheckIn
		|	AND NOT Reservations.ReservationStatus.IsNoShow
		|	AND NOT Reservations.ReservationStatus.IsFullyPaid
		|	AND (NOT &qHotelIsFilled
		|			OR &qHotelIsFilled
		|				AND Reservations.Hotel IN HIERARCHY (&qHotel))
		|	AND (NOT Reservations.ReservationStatus.IsActive
		|				AND (Reservations.NumberOfBeds = 0
		|					AND Reservations.NumberOfAdditionalBeds = 0
		|					AND Reservations.NumberOfPersons = 0)
		|			OR (Reservations.ReservationStatus.IsActive
		|				OR Reservations.ReservationStatus.IsPreliminary)
		|				AND (Reservations.NumberOfBeds > 0
		|					OR Reservations.NumberOfAdditionalBeds > 0
		|					OR Reservations.NumberOfPersons > 0))
		|
		|GROUP BY
		|	Reservations.GuestGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Reservations.Ref AS Reservation,
		|	Reservations.ReservationStatus AS ReservationStatus,
		|	Reservations.GuestGroup AS GuestGroup,
		|	Reservations.GuestGroup.CheckDate AS CheckDate,
		|	Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|		OR Reservations.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|			AND (Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
		|				OR Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds)) AS MainRoomReservation
		|FROM
		|	Document.Reservation AS Reservations
		|		INNER JOIN TimesToWaits AS TimesToWaits
		|		ON (CASE
		|				WHEN Reservations.ReservationStatus <> &qNewOnlineReservationStatus
		|					THEN TRUE
		|				WHEN Reservations.CheckInDate >= TimesToWaits.CheckInDateFrom
		|					THEN CASE
		|							WHEN TimesToWaits.CheckInDateTo = DATETIME(1, 1, 1, 0, 0, 0)
		|									OR Reservations.CheckInDate <= TimesToWaits.CheckInDateTo
		|								THEN CASE
		|										WHEN DATEDIFF(Reservations.CheckInDate, Reservations.Date, DAY) >= TimesToWaits.NumberOfDaysBeforeCheckInSinceReservationFrom
		|												AND DATEDIFF(Reservations.CheckInDate, Reservations.Date, DAY) < TimesToWaits.NumberOfDaysBeforeCheckInSinceReservationTo
		|												AND DATEDIFF(&qOnlineCheckDate, Reservations.Date, MINUTE) >= TimesToWaits.TimeToWaitOnlineReservationPayment
		|											THEN TRUE
		|										ELSE FALSE
		|									END
		|							ELSE FALSE
		|						END
		|				ELSE FALSE
		|			END)
		|WHERE
		|	Reservations.Posted
		|	AND Reservations.ReservationStatus <> &qPaymentTimeExpiredReservationStatus
		|	AND Reservations.ReservationStatus <> &qGuaranteedReservationStatus
		|	AND Reservations.ReservationStatus <> &qFullyPaidReservationStatus
		|	AND Reservations.ReservationStatus <> &qGuaranteedOnlineReservationStatus
		|	AND Reservations.ReservationStatus <> &qFullyPaidOnlineReservationStatus
		|	AND NOT Reservations.ReservationStatus.IsGuaranteed
		|	AND NOT Reservations.ReservationStatus.IsCheckIn
		|	AND NOT Reservations.ReservationStatus.IsNoShow
		|	AND NOT Reservations.ReservationStatus.IsFullyPaid
		|	AND CASE
		|			WHEN Reservations.ReservationStatus <> &qNewOnlineReservationStatus
		|				THEN Reservations.GuestGroup.CheckDate <= &qCheckDate
		|						AND Reservations.GuestGroup.CheckDate > &qEmptyDate
		|			ELSE TRUE
		|		END
		|	AND (NOT &qHotelIsFilled
		|			OR &qHotelIsFilled
		|				AND Reservations.Hotel IN HIERARCHY (&qHotel))
		|	AND (NOT Reservations.ReservationStatus.IsActive
		|				AND (Reservations.NumberOfBeds = 0
		|					AND Reservations.NumberOfAdditionalBeds = 0
		|					AND Reservations.NumberOfPersons = 0)
		|			OR (Reservations.ReservationStatus.IsActive
		|				OR Reservations.ReservationStatus.IsPreliminary)
		|				AND (Reservations.NumberOfBeds > 0
		|					OR Reservations.NumberOfAdditionalBeds > 0
		|					OR Reservations.NumberOfPersons > 0))
		|	AND NOT Reservations.GuestGroup IN
		|				(SELECT
		|					PayedGuestGroups.GuestGroup
		|				FROM
		|					PayedGuestGroups AS PayedGuestGroups)
		|	AND CASE
		|			WHEN &qProcessReservationsFromIndividualsOnly
		|				THEN Reservations.Customer = VALUE(Catalog.Customers.EmptyRef)
		|						OR Reservations.Customer.IsIndividual
		|			ELSE TRUE
		|		END
		|	AND Reservations.RoomRate.IsComplimentary = FALSE
		|
		|GROUP BY
		|	Reservations.Ref,
		|	Reservations.GuestGroup,
		|	Reservations.GuestGroup.CheckDate,
		|	Reservations.ReservationStatus,
		|	Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|		OR Reservations.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|			AND (Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
		|				OR Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds))
		|
		|ORDER BY
		|	Reservations.Ref.PointInTime"; 
	Else
		vQry.Text = 
		"SELECT
		|	Reservations.GuestGroup AS GuestGroup
		|INTO PayedGuestGroups
		|FROM
		|	Document.Reservation AS Reservations
		|		INNER JOIN (SELECT
		|			Payments.GuestGroup AS GuestGroup,
		|			Payments.SumExpense AS Sum
		|		FROM
		|			AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
		|					&qPeriodFrom,
		|					&qPeriodTo,
		|					Period,
		|					RegisterRecords,
		|					NOT &qHotelIsFilled
		|						OR &qHotelIsFilled
		|							AND Hotel IN HIERARCHY (&qHotel)) AS Payments
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			Preauthorisations.GuestGroup,
		|			Preauthorisations.Sum
		|		FROM
		|			Document.Preauthorisation AS Preauthorisations
		|		WHERE
		|			Preauthorisations.Posted
		|			AND Preauthorisations.Hotel IN HIERARCHY(&qHotel)
		|			AND Preauthorisations.Status = &qAuthorised) AS GuestGroupTurnovers
		|		ON (GuestGroupTurnovers.GuestGroup = Reservations.GuestGroup)
		|WHERE
		|	Reservations.Posted
		|	AND NOT Reservations.ReservationStatus.IsAnnulation
		|	AND NOT Reservations.ReservationStatus.IsCheckIn
		|	AND NOT Reservations.ReservationStatus.IsNoShow
		|	AND NOT Reservations.ReservationStatus.IsFullyPaid
		|	AND (NOT &qHotelIsFilled
		|			OR &qHotelIsFilled
		|				AND Reservations.Hotel IN HIERARCHY (&qHotel))
		|	AND (NOT Reservations.ReservationStatus.IsActive
		|				AND (Reservations.NumberOfBeds = 0
		|					AND Reservations.NumberOfAdditionalBeds = 0
		|					AND Reservations.NumberOfPersons = 0)
		|			OR (Reservations.ReservationStatus.IsActive
		|				OR Reservations.ReservationStatus.IsPreliminary)
		|				AND (Reservations.NumberOfBeds > 0
		|					OR Reservations.NumberOfAdditionalBeds > 0
		|					OR Reservations.NumberOfPersons > 0))
		|
		|GROUP BY
		|	Reservations.GuestGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Reservations.Ref AS Reservation,
		|	Reservations.ReservationStatus AS ReservationStatus,
		|	Reservations.GuestGroup AS GuestGroup,
		|	Reservations.GuestGroup.CheckDate AS CheckDate,
		|	Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|		OR Reservations.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|			AND (Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
		|				OR Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds)) AS MainRoomReservation
		|FROM
		|	Document.Reservation AS Reservations
		|WHERE
		|	Reservations.Posted
		|	AND Reservations.ReservationStatus <> &qPaymentTimeExpiredReservationStatus
		|	AND Reservations.ReservationStatus <> &qGuaranteedReservationStatus
		|	AND Reservations.ReservationStatus <> &qFullyPaidReservationStatus
		|	AND Reservations.ReservationStatus <> &qGuaranteedOnlineReservationStatus
		|	AND Reservations.ReservationStatus <> &qFullyPaidOnlineReservationStatus
		|	AND NOT Reservations.ReservationStatus.IsGuaranteed
		|	AND NOT Reservations.ReservationStatus.IsCheckIn
		|	AND NOT Reservations.ReservationStatus.IsNoShow
		|	AND NOT Reservations.ReservationStatus.IsFullyPaid
		|	AND (Reservations.ReservationStatus <> &qNewOnlineReservationStatus
		|				AND Reservations.GuestGroup.CheckDate <= &qCheckDate
		|				AND Reservations.GuestGroup.CheckDate > &qEmptyDate
		|			OR Reservations.ReservationStatus = &qNewOnlineReservationStatus
		|				AND Reservations.Date <= &qOnlineCheckDate)
		|	AND (NOT &qHotelIsFilled
		|			OR &qHotelIsFilled
		|				AND Reservations.Hotel IN HIERARCHY (&qHotel))
		|	AND (NOT Reservations.ReservationStatus.IsActive
		|				AND (Reservations.NumberOfBeds = 0
		|					AND Reservations.NumberOfAdditionalBeds = 0
		|					AND Reservations.NumberOfPersons = 0)
		|			OR (Reservations.ReservationStatus.IsActive
		|				OR Reservations.ReservationStatus.IsPreliminary)
		|				AND (Reservations.NumberOfBeds > 0
		|					OR Reservations.NumberOfAdditionalBeds > 0
		|					OR Reservations.NumberOfPersons > 0))
		|	AND NOT Reservations.GuestGroup IN
		|				(SELECT
		|					PayedGuestGroups.GuestGroup
		|				FROM
		|					PayedGuestGroups AS PayedGuestGroups)
		|	AND CASE
		|			WHEN &qProcessReservationsFromIndividualsOnly
		|				THEN Reservations.Customer = VALUE(Catalog.Customers.EmptyRef)
		|						OR Reservations.Customer.IsIndividual
		|			ELSE TRUE
		|		END
		|	AND Reservations.RoomRate.IsComplimentary = FALSE
		|
		|GROUP BY
		|	Reservations.Ref,
		|	Reservations.GuestGroup,
		|	Reservations.GuestGroup.CheckDate,
		|	Reservations.ReservationStatus,
		|	Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|		OR Reservations.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|			AND (Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
		|				OR Reservations.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds))
		|
		|ORDER BY
		|	Reservations.Ref.PointInTime";	
	EndIf;
	vQry.SetParameter("qPaymentDateExpiredReservationStatus", PaymentDateExpiredReservationStatus);
	vQry.SetParameter("qPaymentTimeExpiredReservationStatus", PaymentTimeExpiredReservationStatus);
	vQry.SetParameter("qGuaranteedReservationStatus", GuaranteedReservationStatus);
	vQry.SetParameter("qFullyPaidReservationStatus", FullyPaidReservationStatus);
	vQry.SetParameter("qGuaranteedOnlineReservationStatus", GuaranteedOnlineReservationStatus);
	vQry.SetParameter("qFullyPaidOnlineReservationStatus", FullyPaidOnlineReservationStatus);
	vQry.SetParameter("qNewOnlineReservationStatus", NewOnlineReservationStatus);
	vQry.SetParameter("qCheckDate", BegOfDay(CurrentSessionDate())); 
	If TimesToWaitOnlineReservationPayment.Count() > 0 Then
		vQry.SetParameter("qTimesToWaitOnlineReservationPayment", TimesToWaitOnlineReservationPayment);
		vQry.SetParameter("qOnlineCheckDate", CurrentSessionDate());
	Else
		vQry.SetParameter("qOnlineCheckDate", CurrentSessionDate() - TimeToWaitOnlineReservationPayment * 60);	
	EndIf;
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qPeriodFrom", '00010101');
	vQry.SetParameter("qPeriodTo", '39991231');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(Hotel));
	vQry.SetParameter("qAuthorised", Enums.PreauthorisationStatuses.Authorised);
	vQry.SetParameter("qProcessReservationsFromIndividualsOnly", ProcessReservationsFromIndividualsOnly);
	vReservations = vQry.Execute();
	// Change reservation status for each reservation and post it
	vGroupsWithChangedCheckDate = New ValueList();
	If ValueIsFilled(PaymentDateExpiredReservationStatus) Or ValueIsFilled(PaymentTimeExpiredReservationStatus) Then
		vReservationsRow = vReservations.Select(); 
		While vReservationsRow.Next() Do
			Try
				vReservationRef = vReservationsRow.Reservation;
				If TypeOf(vReservationRef) <> Type("DocumentRef.Reservation") Then
					Continue;
				EndIf;
				vReservationRefReservationStatus = vReservationsRow.ReservationStatus;
				// Check if the status has changed
				If vReservationRefReservationStatus <> vReservationRef.ReservationStatus Then
					 Continue;
				EndIf;	

				// Set reservation status
				vMessageTemplate = Undefined;
				vObjectPrintingForm = Undefined;
				vNewReservationStatus = Undefined;
				vDoUpdateCheckDate = False;
				If ValueIsFilled(PaymentTimeExpiredReservationStatus) And vReservationRefReservationStatus = NewOnlineReservationStatus Then
					vNewReservationStatus = PaymentTimeExpiredReservationStatus;
					vMessageTemplate = PaymentTimeExpiredMessageTemplate;
				ElsIf ValueIsFilled(PaymentDateExpiredReservationStatus) Then
					If vReservationRefReservationStatus = PaymentDateExpiredReservationStatus Then
						If Not ValueIsFilled(ReservationAnnulationStatus) Then
							Continue;
						Else
							vNewReservationStatus = ReservationAnnulationStatus;
							vMessageTemplate = ReservationAnnulationMessageTemplate;
						EndIf;
					Else
						vNewReservationStatus = PaymentDateExpiredReservationStatus;
						vMessageTemplate = PaymentDateExpiredMessageTemplate;
						If ValueIsFilled(ReservationAnnulationStatus) Then
							vDoUpdateCheckDate = True;
						EndIf;
					EndIf;
				Else
					Continue;
				EndIf;
				
				// Check if this is individuals reservation
				If ProcessReservationsFromIndividualsOnly Then
					If ValueIsFilled(vReservationRef.Customer) And Not vReservationRef.Customer.IsIndividual Then
						Continue;
					EndIf;
					If ValueIsFilled(vReservationRef.Agent) Then
						Continue;
					EndIf;
				EndIf;
				
				// Process reservation
				vReservationObj = vReservationRef.GetObject();
				vReservationObj.ReservationStatus = vNewReservationStatus;
				vReservationObj.pmSetDoCharging();
				If ValueIsFilled(vNewReservationStatus) And (vNewReservationStatus.DoNoShowCharging Or vNewReservationStatus.DoLateAnnulationCharging) Then
					vReservationObj.pmCalculateServices();
				EndIf;
				vReservationObj.Write(DocumentWriteMode.Posting);
				// Save data to the document history
				vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				
				If vDoUpdateCheckDate Then
					If vGroupsWithChangedCheckDate.FindByValue(vReservationsRow.GuestGroup) = Undefined Then
						vGroupsWithChangedCheckDate.Add(vReservationsRow.GuestGroup);
						
						vGuestGroupObj = vReservationsRow.GuestGroup.GetObject();
						If ValueIsFilled(vGuestGroupObj.CreateDate) And vGuestGroupObj.CheckDate > vGuestGroupObj.CreateDate Then
							vShift = BegOfDay(vGuestGroupObj.CheckDate) - BegOfDay(vGuestGroupObj.CreateDate);
							vGuestGroupObj.CheckDate = vGuestGroupObj.CheckDate + vShift;
							vGuestGroupObj.Write();
						EndIf;
					EndIf;
				EndIf;
				
				vPGRow = rProcessedGuestGroups.Add();
				vPGRow.GuestGroup = vReservationsRow.GuestGroup;
				vPGRow.CheckDate = vReservationsRow.CheckDate;
				
				// Log current state
				vMessage = NStr("ru='Обработан документ: " + String(vReservationRef) + " - группа № " + TrimAll(vReservationObj.GuestGroup) + ", статус установлен в " + TrimAll(vReservationObj.ReservationStatus) + "'; 
				                |de='Document " + String(vReservationRef) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed, status was set to " + TrimAll(vReservationObj.ReservationStatus) + "'; 
								|en='Document " + String(vReservationRef) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed, status was set to " + TrimAll(vReservationObj.ReservationStatus) + "'");
				WriteLogEvent(NStr("en='DataProcessor.CheckIfReservationsWerePayedInTime';ru='Обработка.ПроверитьПоступлениеОплатыПоБрони';de='DataProcessor.CheckIfReservationsWerePayedInTime'"), EventLogLevel.Information, ThisObject.Metadata(), vReservationRef, vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
				Endif;
				
				// Write attachment
				vSendEMail = False;
				vFax = "";
				vEMail = "";
				
				If ValueIsFilled(vReservationRef.Customer) Then
					vFax = vReservationRef.Customer.Fax;
					vEMail = vReservationRef.Customer.EMail;
					vSendEMail = True;
				EndIf;
				
				If Not ValueIsFilled(vEMail) Then
					vFax = vReservationRef.Fax;
					vEMail = vReservationRef.EMail;
					vSendEMail = True;
				EndIf;
				
				If Not ValueIsFilled(vEMail) And ValueIsFilled(vReservationRef.Guest) Then
					vFax = vReservationRef.Guest.Fax;
					vEMail = vReservationRef.Guest.EMail;
					vSendEMail = True;	
				EndIf;
				
				// Write guest group attachement
				If ValueIsFilled(ReplyMessageType) And ReplyMessageType = Enums.AttachmentTypes.EMail And vReservationsRow.MainRoomReservation And vSendEMail Then
					vGuestGroupRef = vReservationObj.GuestGroup;
					If rGuestGroups.FindByValue(vGuestGroupRef) = Undefined Then
						rGuestGroups.Add(vGuestGroupRef);
						vHotel = vGuestGroupRef.Owner;
						vLanguage = vHotel.Language;
						If ValueIsFilled(vGuestGroupRef.Client) And ValueIsFilled(vGuestGroupRef.Client.Language) Then
							vLanguage = vGuestGroupRef.Client.Language;
						EndIf;
						// Build message text
						vRemarks = Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage) + 
						           StrTemplate(cmNStr("en='. Status of reservation N %1 was changed to %2'; 
								          |de='. Status of reservation N %1 was changed to %2'; 
						                  |ru='. Статус брони № %1 изменен на %2'", 
						                  vLanguage), Format(vGuestGroupRef.Code, "ND=12; NFD=0; NG="), Catalogs.ReservationStatuses.pmGetReservationStatusDescription(vReservationObj.ReservationStatus, vLanguage));
						// Apply template if it is specified
						vDocumentText = "";
						If ValueIsFilled(vMessageTemplate) Then
							vRemarks = cmNStr(TrimAll(vMessageTemplate.Description), vLanguage);
							If ValueIsFilled(vMessageTemplate.HTMLTextRu) Or ValueIsFilled(vMessageTemplate.HTMLTextEn) Or ValueIsFilled(vMessageTemplate.HTMLTextDe) Then
								vDocumentText = SMS.GetHTMLTextByLanguage(vMessageTemplate, vLanguage);
							EndIf;
							If IsBlankString(vDocumentText) Then
								vDocumentText = SMS.GetSMSTextByLanguage(vMessageTemplate, vLanguage);
							EndIf;
							If ValueIsFilled(vMessageTemplate.ObjectPrintingFormRu) Then
								vObjectPrintingForm = vMessageTemplate.ObjectPrintingFormRu;
							EndIf;
							If vLanguage = Catalogs.Languages.EN And ValueIsFilled(vMessageTemplate.ObjectPrintingFormEn) Then
								vObjectPrintingForm = vMessageTemplate.ObjectPrintingFormEn;
							ElsIf vLanguage = Catalogs.Languages.DE And ValueIsFilled(vMessageTemplate.ObjectPrintingFormDe) Then
								vObjectPrintingForm = vMessageTemplate.ObjectPrintingFormDe;
							EndIf; 
						EndIf;
						If IsBlankString(vDocumentText) Then
							vDocumentText = cmNStr("en='Reservation status change notification:'; 
							                       |de='Benachrichtigung über Änderung des Reservierungsstatus:'; 
							                       |ru='Уведомление об изменении статусов брони:'", vLanguage) + Chars.LF + Chars.LF +
							                ?(ValueIsFilled(vGuestGroupRef) And ValueIsFilled(vGuestGroupRef.Client), cmNStr("en='Client name: ';ru='Клиент: ';de='Kunde: '", vLanguage) + TrimAll(vGuestGroupRef.Client.FullName) + Chars.LF, "") + 
							                ?(ValueIsFilled(vGuestGroupRef) And ValueIsFilled(vGuestGroupRef.CheckInDate) And ValueIsFilled(vGuestGroupRef.CheckOutDate), cmNStr("en='Period of stay: ';RU='Период проживания: ';de='Unterbringungszeitraum: '", vLanguage) + Format(vGuestGroupRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - "  + Format(vGuestGroupRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + Chars.LF, "") + 
							                Chars.LF + 
							                StrTemplate(cmNStr("en='Status of reservation N %1 was changed to %2'; 
														       |de='Status of reservation N %1 was changed to %2'; 
										                       |ru='Статус брони № %1 изменен на %2'", 
												   vLanguage), Format(vGuestGroupRef.Code, "ND=12; NFD=0; NG="), Catalogs.ReservationStatuses.pmGetReservationStatusDescription(vReservationObj.ReservationStatus, vLanguage))+ Chars.LF + Chars.LF  
							               + cmNStr("en='Best regards,'; 
											       |de='Best regards,'; 
							                       |ru='С уважением,'", vLanguage) + Chars.LF  
							               + Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage) + Chars.LF  
									       + cmNStr(SessionParameters.ConfigurationName, vLanguage);
						EndIf;
						vConfirmationFileName = "";
						If ValueIsFilled(vObjectPrintingForm) Then
							vSpreadsheet = New SpreadsheetDocument();
							If ValueIsFilled(vObjectPrintingForm.ExternalProcessing) Then 
								vExtProc = vObjectPrintingForm.ExternalProcessing;
								vExtProcData = vExtProc.ExternalProcessingStorage.Get();
								vExtProcPath = GetTempFileName(".efd");
								vExtProcData.Write(vExtProcPath);
								vExtProcObject = ExternalDataProcessors.Create(vExtProcPath, False);
								vStruct = New Structure("InputParameter, ObjectPrintingForm", vReservationObj, vObjectPrintingForm);
								FillPropertyValues(vExtProcObject, vStruct);
								vExtProcObject.pmPrintCancellation(vSpreadsheet, vReservationRef, Undefined, False, vLanguage, vObjectPrintingForm); 
								DeleteFiles(vExtProcPath);
							Else
								// Check predefined forms
								If vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintCancellationRu Or
								   vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintCancellationEn Or
								   vObjectPrintingForm = Catalogs.ObjectPrintingForms.ReservationPrintCancellationDe Then
									vReservationObj.pmPrintCancellation(vSpreadsheet, vReservationRef, Undefined, False, vLanguage, vObjectPrintingForm);
								EndIf;
							EndIf;
							// Save reservation confirmation to the temp PDF file
							vConfirmationFileName = StrReplace(cmNStr("en='Booking cancellation'; ru='Отмена брони'; de='Reservierungstornierung'", vLanguage) + " " + Format(vReservationObj.GuestGroup.Code, "ND=12; NFD=0; NG="), " ", "_") + ".pdf";
							vConfirmationFileName = cmGetFullFileName(vConfirmationFileName, TempFilesDir());
							vSpreadsheet.Write(vConfirmationFileName, SpreadsheetDocumentFileType.PDF);
						EndIf;
						// Call user exit procedure to give possibility to override message subject ans message text
						vUserExitProc = Catalogs.ExternalDataProcessors.WriteGuestGroupPaymentWaitTimeIsExpiredNotification;
						If ValueIsFilled(vUserExitProc) Then
							If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
								If Not IsBlankString(vUserExitProc.Algorithm) Then
									SetSafeMode(True);
									Execute(TrimAll(vUserExitProc.Algorithm));
									SetSafeMode(False);
								EndIf;
							EndIf;
						EndIf;
						InformationRegisters.GuestGroupAttachments.WriteData(, vGuestGroupRef,,,,,, vEMail, vFax, ReplyMessageType, Enums.AttachmentStatuses.Ready, vDocumentText, vMessageTemplate, vReservationRef,,, vConfirmationFileName,, True, vRemarks);
					EndIf;
				EndIf;
			Except
				vMessage = ErrorDescription();
				WriteLogEvent(NStr("en='DataProcessor.CheckIfReservationsWerePayedInTime';ru='Обработка.ПроверитьПоступлениеОплатыПоБрони';de='DataProcessor.CheckIfReservationsWerePayedInTime'"), EventLogLevel.Warning, ThisObject.Metadata(), vReservationRef, vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				EndIf;
			EndTry;
		EndDo;
	EndIf;	
EndProcedure//ChangeReservationStatus 

#EndRegion	
