
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
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
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
	WriteLogEvent(NStr("en='DataProcessor.SendExpressCheckInInvitations';ru='Обработка.РассылкаПриглашенийНаЭкспрессЗаселение';de='DataProcessor.ExpressCheckInEinladungSenden'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	vGuestGroups = New ValueList();
	// Get list of reservations with payments received
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservedGuestGroups.GuestGroup AS GuestGroup
	|INTO ReservedGuestGroups
	|FROM
	|	AccumulationRegister.RoomInventory AS ReservedGuestGroups
	|WHERE
	|	ReservedGuestGroups.ReservationStatus.IsActive
	|	AND ReservedGuestGroups.ReservationStatus <> &qExpressCheckInReservationStatus
	|	AND NOT ReservedGuestGroups.ReservationStatus.IsCheckIn
	|	AND NOT ReservedGuestGroups.ReservationStatus.IsNoShow
	|	AND NOT ReservedGuestGroups.ReservationStatus.IsPreliminary
	|	AND ReservedGuestGroups.Hotel IN HIERARCHY(&qHotel)
	|	AND (ReservedGuestGroups.BedsReserved > 0
	|			OR ReservedGuestGroups.AdditionalBedsReserved > 0
	|			OR ReservedGuestGroups.GuestsReserved > 0)
	|	AND ReservedGuestGroups.Guest.IdentityDocumentNumber <> &qEmptyString
	|	AND (ReservedGuestGroups.Recorder.EMail <> &qEmptyString
	|			OR ReservedGuestGroups.Guest.EMail <> &qEmptyString)
	|	AND ReservedGuestGroups.RecordType = &qExpense
	|
	|GROUP BY
	|	ReservedGuestGroups.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroupSales.GuestGroup AS GuestGroup,
	|	GuestGroupSales.ReportingCurrency AS Currency,
	|	SUM(GuestGroupSales.SalesTurnover + GuestGroupSales.SalesForecastTurnover) AS SalesAmount
	|INTO GuestGroupSales
	|FROM
	|	(SELECT
	|		CurrentAccountsReceivableTurnovers.GuestGroup AS GuestGroup,
	|		CurrentAccountsReceivableTurnovers.FolioCurrency AS ReportingCurrency,
	|		CurrentAccountsReceivableTurnovers.SumReceipt - CurrentAccountsReceivableTurnovers.CommissionSumReceipt AS SalesTurnover,
	|		0 AS SalesForecastTurnover
	|	FROM
	|		AccumulationRegister.CurrentAccountsReceivable.Turnovers(
	|				,
	|				,
	|				Period,
	|				GuestGroup IN
	|					(SELECT
	|						ReservedGuestGroups.GuestGroup
	|					FROM
	|						ReservedGuestGroups AS ReservedGuestGroups)) AS CurrentAccountsReceivableTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AccountsReceivableForecastTurnovers.GuestGroup,
	|		AccountsReceivableForecastTurnovers.FolioCurrency,
	|		0,
	|		AccountsReceivableForecastTurnovers.SalesTurnover - AccountsReceivableForecastTurnovers.CommissionSumTurnover
	|	FROM
	|		AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				GuestGroup IN
	|					(SELECT
	|						ReservedGuestGroups.GuestGroup
	|					FROM
	|						ReservedGuestGroups AS ReservedGuestGroups)) AS AccountsReceivableForecastTurnovers) AS GuestGroupSales
	|
	|GROUP BY
	|	GuestGroupSales.GuestGroup,
	|	GuestGroupSales.ReportingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroupPayments.GuestGroup AS GuestGroup,
	|	GuestGroupPayments.AccountingCurrency AS Currency,
	|	SUM(GuestGroupPayments.SumExpense) AS PayedAmount
	|INTO GuestGroupPayments
	|FROM
	|	AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
	|			,
	|			,
	|			Period,
	|			RegisterRecordsAndPeriodBoundaries,
	|			GuestGroup IN
	|				(SELECT
	|					ReservedGuestGroups.GuestGroup
	|				FROM
	|					ReservedGuestGroups AS ReservedGuestGroups)) AS GuestGroupPayments
	|
	|GROUP BY
	|	GuestGroupPayments.GuestGroup,
	|	GuestGroupPayments.AccountingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroupBalances.GuestGroup AS GuestGroup,
	|	SUM(GuestGroupBalances.BalanceAmount) AS BalanceAmount
	|INTO GuestGroupBalances
	|FROM
	|	(SELECT
	|		GuestGroupSales.GuestGroup AS GuestGroup,
	|		GuestGroupSales.Currency AS Currency,
	|		GuestGroupSales.SalesAmount AS BalanceAmount
	|	FROM
	|		GuestGroupSales AS GuestGroupSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GuestGroupPayments.GuestGroup,
	|		GuestGroupPayments.Currency,
	|		-GuestGroupPayments.PayedAmount
	|	FROM
	|		GuestGroupPayments AS GuestGroupPayments) AS GuestGroupBalances
	|
	|GROUP BY
	|	GuestGroupBalances.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.Recorder AS Reservation,
	|	RoomInventory.GuestGroup AS GuestGroup
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|		INNER JOIN GuestGroupBalances AS GuestGroupBalances
	|		ON RoomInventory.GuestGroup = GuestGroupBalances.GuestGroup
	|			AND (GuestGroupBalances.BalanceAmount <= 0)
	|WHERE
	|	RoomInventory.ReservationStatus.IsActive
	|	AND RoomInventory.ReservationStatus <> &qExpressCheckInReservationStatus
	|	AND (RoomInventory.AccommodationType.Type = &qRoom
	|			OR RoomInventory.AccommodationType.Type = &qBeds)
	|	AND NOT RoomInventory.ReservationStatus.IsCheckIn
	|	AND NOT RoomInventory.ReservationStatus.IsNoShow
	|	AND NOT RoomInventory.ReservationStatus.IsPreliminary
	|	AND RoomInventory.Hotel IN HIERARCHY(&qHotel)
	|	AND RoomInventory.Guest <> &qEmptyClient
	|	AND RoomInventory.Guest.IdentityDocumentNumber <> &qEmptyString
	|	AND (RoomInventory.Recorder.EMail <> &qEmptyString
	|			OR RoomInventory.Guest.EMail <> &qEmptyString)
	|	AND (RoomInventory.BedsReserved > 0
	|			OR RoomInventory.AdditionalBedsReserved > 0
	|			OR RoomInventory.GuestsReserved > 0)
	|	AND (NOT &qSkipForeigners
	|			OR &qSkipForeigners
	|				AND RoomInventory.Guest.Citizenship = RoomInventory.Hotel.Citizenship)
	|	AND RoomInventory.RecordType = &qExpense
	|
	|GROUP BY
	|	RoomInventory.Recorder,
	|	RoomInventory.GuestGroup
	|
	|ORDER BY
	|	RoomInventory.GuestGroup.Code,
	|	RoomInventory.Recorder.PointInTime";
	vQry.SetParameter("qExpressCheckInReservationStatus", ExpressCheckInReservationStatus);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qRoom", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qBeds", Enums.AccomodationTypes.Beds);
	vQry.SetParameter("qSkipForeigners", SkipForeigners);
	vQry.SetParameter("qForecastPeriodFrom", tcOnServer.GetForecastStartDate(Hotel));
	vQry.SetParameter("qForecastPeriodTo", '39991231235959');
	vReservations = vQry.Execute().Unload();
	
	// Change reservation status for each reservation and post it
	For Each vReservationsRow In vReservations Do
		vReservationRef = vReservationsRow.Reservation;
		If TypeOf(vReservationRef) <> Type("DocumentRef.Reservation") Then
			Continue;
		EndIf;
		vReservationObj = vReservationRef.GetObject();
		vEMail = vReservationObj.EMail;
		If IsBlankString(vEMail) And ValueIsFilled(vReservationObj.Guest) Then
			vEMail = vReservationObj.Guest.EMail;
		EndIf;
		If IsBlankString(vEMail) Then
			Continue;
		EndIf;
		vHotel = vReservationObj.Hotel;
		vLanguage = vHotel.Language;
		If ValueIsFilled(vReservationObj.Guest) And ValueIsFilled(vReservationObj.Guest.Language) Then
			vLanguage = vReservationObj.Guest.Language;
		EndIf;
		
		// Process reservation
		Try
			If ValueIsFilled(ExpressCheckInReservationStatus) Then
				// Set reservation status
				vReservationObj.ReservationStatus = ExpressCheckInReservationStatus;
				vReservationObj.pmSetDoCharging();
				vReservationObj.Write(DocumentWriteMode.Posting);
				// Save data to the document history
				vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
			
			// Send express check-in form with QR-Code
			vSpreadsheet = New SpreadsheetDocument();
			vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationRu;
			If vLanguage = Catalogs.Languages.EN Then
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationEn;
			ElsIf vLanguage = Catalogs.Languages.DE Then
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationDe;
			EndIf;
			If ValueIsFilled(vObjectPrintForm.ExternalProcessing) Then
				vExtDataProcessor = cmGetExternalDataProcessorObject(vObjectPrintForm.ExternalProcessing);
				vExtDataProcessor.pmPrintExpressCheckInInvitation(vSpreadsheet, vReservationRef, Undefined, True, vLanguage, vObjectPrintForm);
			Else
				vReservationObj.pmPrintExpressCheckInInvitation(vSpreadsheet, vReservationRef, Undefined, True, vLanguage, vObjectPrintForm);
			EndIf;
			// Save reservation confirmation to the temp PDF file
			vInvitationFileName = StrReplace(cmNStr("en='Invitation'; ru='Приглашение'; de='Einladung'", vLanguage) + " " + Format(vReservationObj.GuestGroup.Code, "ND=12; NFD=0; NG=") + "-" + cmGetDocumentNumberPresentation(vReservationObj.Number), " ", "_") + ".pdf";
			vInvitationFilePath = cmGetFullFileName(vInvitationFileName, TempFilesDir());
			vSpreadsheet.Write(vInvitationFilePath, SpreadsheetDocumentFileType.PDF);
			// Add record to guest group attachements
			vGrpAttachmentsRecPeriod = CurrentSessionDate();
			vGrpAttachmentsRecMgr = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
			// Try to find period without other attachments
			vGrpAttachmentsRecMgr.Period = vGrpAttachmentsRecPeriod;
			vGrpAttachmentsRecMgr.GuestGroup = vReservationObj.GuestGroup;
			vGrpAttachmentsRecMgr.Read();
			While vGrpAttachmentsRecMgr.Selected() Do
				vGrpAttachmentsRecPeriod = vGrpAttachmentsRecPeriod + 1;
				vGrpAttachmentsRecMgr.Period = vGrpAttachmentsRecPeriod;
				vGrpAttachmentsRecMgr.GuestGroup = vReservationObj.GuestGroup;
				vGrpAttachmentsRecMgr.Read();
			EndDo;
			vHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage);
			// Create new guest group attachment using period found before
			MessageSubject = vHotelPrintName + 
			                 cmNStr("en=' Express check-in invitation for reservation N " + Format(vReservationObj.GuestGroup.Code, "ND=12; NFD=0; NG=") + "/" + cmGetDocumentNumberPresentation(vReservationObj.Number) + "'; 
			                        |de=' Express-Check-in Einladung für Reservierung Nr. " + Format(vReservationObj.GuestGroup.Code, "ND=12; NFD=0; NG=") + "/" + cmGetDocumentNumberPresentation(vReservationObj.Number) + "'; 
			                        |ru=' Приглашение на экспресс-заселение по брони № " + Format(vReservationObj.GuestGroup.Code, "ND=12; NFD=0; NG=") + "/" + cmGetDocumentNumberPresentation(vReservationObj.Number) + "'", 
			                        vLanguage);
			MessageText = cmNStr("en='Express check-in invitation:'; 
			                     |de='Express Check-in-Einladung:'; 
			                     |ru='Приглашение на экспресс-заселение:'",
			                     vLanguage) + Chars.LF + Chars.LF +
			              cmNStr("en='Your reservation number " + Format(vReservationObj.GuestGroup.Code, "ND=12; NFD=0; NG=") + "/" + cmGetDocumentNumberPresentation(vReservationObj.Number) + " is ready for express check-in!'; 
			                     |de='Ihre Reservierung Nummer " + Format(vReservationObj.GuestGroup.Code, "ND=12; NFD=0; NG=") + "/" + cmGetDocumentNumberPresentation(vReservationObj.Number) + " ist bereit für Express-Check-in!'; 
			                     |ru='Ваша бронь номер " + Format(vReservationObj.GuestGroup.Code, "ND=12; NFD=0; NG=") + "/" + cmGetDocumentNumberPresentation(vReservationObj.Number) + " готова к заселению без очереди!'",
			                     vLanguage) + Chars.LF + Chars.LF + 
			              ?(ValueIsFilled(vReservationObj.Guest), cmNStr("en='Client name: ';ru='Клиент: ';de='Kunde: '", vLanguage) + TrimAll(vReservationObj.Guest.FullName) + Chars.LF, "") + 
			              ?(ValueIsFilled(vReservationObj.CheckInDate) And ValueIsFilled(vReservationObj.CheckOutDate), cmNStr("EN='Period of stay: ';RU='Период проживания: ';de='Unterbringungszeitraum: '", vLanguage) + Format(vReservationObj.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - "  + Format(vReservationObj.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + Chars.LF, "") + 
			              cmNStr("en='Room type: ';ru='Тип номера: ';de='Zimmertyp: '", vLanguage) + vReservationObj.RoomType.GetObject().pmGetRoomTypeDescription(vLanguage) + Chars.LF + Chars.LF + 
			              cmNStr("en='Please print QR-Code attached to this letter, show it at hotel reception and get your room key!';
			                     |ru='Распечатайте QR-код прикрепленный к этому письму, покажите его на стойке размещения и получите ключ от номера!';
			                     |de='Bitte drucken Sie QR-Code zu diesem Schreiben beigefügt ist, zeigen Sie an der Hotelrezeption und erhalten Sie Ihren Zimmerschlüssel!'", vLanguage) + Chars.LF + Chars.LF + 
			              TrimAll(Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, vLanguage)) + Chars.LF + Chars.LF + 
			              TrimAll(Catalogs.Hotels.pmGetHotelHowToDriveToTheHotelDescription(vHotel, vLanguage)) + Chars.LF + Chars.LF + 
			              cmNStr("en='Best regards,'; 
			                     |de='Mit freundlichen Grüßen,'; 
			                     |ru='С уважением,'",
			                     vLanguage) + Chars.LF + 
			              Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage) + Chars.LF + 
			              cmNStr(SessionParameters.ConfigurationName, vLanguage);
			// Call user exit procedure to give possibility to override message subject and message text
			vUserExitProc = Catalogs.ExternalDataProcessors.SendExpressCheckInInvitationByEMail;
			If ValueIsFilled(vUserExitProc) Then
				If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
					If Not IsBlankString(vUserExitProc.Algorithm) Then
						SetSafeMode(True);
						Execute(TrimAll(vUserExitProc.Algorithm));
						SetSafeMode(False);
					EndIf;
				EndIf;
			EndIf;
			
			// Create record in guest group attachments
			vGrpAttachmentsRecMgr.Period = vGrpAttachmentsRecPeriod;
			vGrpAttachmentsRecMgr.GuestGroup = vReservationObj.GuestGroup;
			vGrpAttachmentsRecMgr.Fax = vReservationObj.Fax;
			vGrpAttachmentsRecMgr.EMail = vReservationObj.EMail;
			vGrpAttachmentsRecMgr.AttachmentStatus = Enums.AttachmentStatuses.Ready;
			vGrpAttachmentsRecMgr.AttachmentType = Enums.AttachmentTypes.EMail;
			vGrpAttachmentsRecMgr.Remarks = MessageSubject;
			vGrpAttachmentsRecMgr.DocumentText = MessageText;
			vFile = New File(vInvitationFilePath);
			If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() Then
				vGrpAttachmentsRecMgr.FileName = vInvitationFileName;
				vGrpAttachmentsRecMgr.FileLoadTime = CurrentSessionDate();
				vGrpAttachmentsRecMgr.FileLastChangeTime = vFile.GetModificationTime();
				vBinary = New BinaryData(vInvitationFilePath);
				vGrpAttachmentsRecMgr.ExtFile = New ValueStorage(vBinary);
				DeleteFiles(vInvitationFilePath);
			EndIf;
			// Try to send this attachment by e-mail
			Try 
				SendByEMail(vGrpAttachmentsRecMgr);
				vGrpAttachmentsRecMgr.AttachmentStatus = Enums.AttachmentStatuses.Sent;
			Except
			EndTry;
			// Write attachment
			vGrpAttachmentsRecMgr.Write();
			
			// Log current state
			vMessage = NStr("ru='Обработан документ: " + String(vReservationObj.Ref) + " - группа № " + TrimAll(vReservationObj.GuestGroup) + ", статус брони " + TrimAll(vReservationObj.ReservationStatus) + "'; 
			                |de='Dokument " + String(vReservationObj.Ref) + " - Gruppe Nr. " + TrimAll(vReservationObj.GuestGroup) + " verarbeitet wurde, Reservierungsstatus ist " + TrimAll(vReservationObj.ReservationStatus) + "'; 
							|en='Document " + String(vReservationObj.Ref) + " - group N " + TrimAll(vReservationObj.GuestGroup) + " was processed, reservation status is " + TrimAll(vReservationObj.ReservationStatus) + "'");
			WriteLogEvent(NStr("en='DataProcessor.SendExpressCheckInInvitations';ru='Обработка.РассылкаПриглашенийНаЭкспрессЗаселение';de='DataProcessor.ExpressCheckInEinladungSenden'"), EventLogLevel.Information, ThisObject.Metadata(), vReservationObj.Ref, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			EndIf;
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.SendExpressCheckInInvitations';ru='Обработка.РассылкаПриглашенийНаЭкспрессЗаселение';de='DataProcessor.ExpressCheckInEinladungSenden'"), EventLogLevel.Warning, ThisObject.Metadata(), ?(vReservationObj = Undefined, Undefined, vReservationObj.Ref), vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	
	// Send internal hotel invitations
	If ValueIsFilled(DepartmentToSendNotificationsTo) Then
		vGuestGroups = New ValueList();
		vReservations.GroupBy("GuestGroup", );
		For Each vReservationsRow In vReservations Do
			vGuestGroupRef = vReservationsRow.GuestGroup;
			If vGuestGroups.FindByValue(vGuestGroupRef) = Undefined Then
				vGuestGroups.Add(vGuestGroupRef);
				vMessageStatus = Undefined;
				If ValueIsFilled(vGuestGroupRef) And ValueIsFilled(vGuestGroupRef.Owner.MessageStatus) Then
					vMessageStatus = vGuestGroupRef.Owner.MessageStatus;
				EndIf;
				vMessage = NStr("ru='Группа № " + TrimAll(vGuestGroupRef) + ", " + Format(vGuestGroupRef.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vGuestGroupRef.CheckOutDate, "DF=dd.MM.yyyy") + " готова к экспресс-заезду!'; 
				                |de='Gruppe Nr. " + TrimAll(vGuestGroupRef) + ", " + Format(vGuestGroupRef.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vGuestGroupRef.CheckOutDate, "DF=dd.MM.yyyy") + " ist bereit für Express-Check-in!'; 
								|en='Guest group N " + TrimAll(vGuestGroupRef) + ", " + Format(vGuestGroupRef.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vGuestGroupRef.CheckOutDate, "DF=dd.MM.yyyy") + " is ready for express check-in!'");
				cmSendMessageToDepartment(DepartmentToSendNotificationsTo, vMessage, vMessageStatus, False, vGuestGroupRef);
			EndIf;
		EndDo;
	EndIf;
	
	// End of processing
	WriteLogEvent(NStr("en='DataProcessor.SendExpressCheckInInvitations';ru='Обработка.РассылкаПриглашенийНаЭкспрессЗаселение';de='DataProcessor.ExpressCheckInEinladungSenden'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmDoCheck

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
Procedure SendByEMail(pNotificationRow)
	// Get current employee settings
	vCurEmployee = SessionParameters.CurrentUser;
	If Not ValueIsFilled(vCurEmployee) Then
		vError = NStr("ru = 'Невозможно отправить сообщение " + TrimAll(pNotificationRow.Remarks) + " по электронной почте на адрес " + TrimAll(pNotificationRow.EMail) + "! Не определен текущий пользователь!'; 
		              |de = 'Unable to send notification " + TrimAll(pNotificationRow.Remarks) + " by e-mail to " + TrimAll(pNotificationRow.EMail) + "! Current user is not defined!'; 
		              |en = 'Unable to send notification " + TrimAll(pNotificationRow.Remarks) + " by e-mail to " + TrimAll(pNotificationRow.EMail) + "! Current user is not defined!'");
		Raise vError;
	EndIf;
	
	// Addresses and names
	vSenderName = vCurEmployee.GetObject().pmGetEmployeeDescription(SessionParameters.CurrentLanguage);  
	
	// Add ReplyTo address
	vReplyToEMail = New Array;
	If Not IsBlankString(vCurEmployee.ReplyToEMail) Then
		vEMailsList = cmParseEMailAddress(TrimAll(vCurEmployee.ReplyToEMail));
		For Each vEMailItem In vEMailsList Do
			vReplyToEMail.Add(TrimAll(vEMailItem.Value));
		EndDo;
	EndIf;        
	
	// Add to address
	vToEMail = New Array;
	vEMailsList = cmParseEMailAddress(TrimAll(pNotificationRow.EMail));
	For Each vEMailItem In vEMailsList Do
		vToEMail.Add(TrimAll(vEMailItem.Value));
	EndDo; 
	
	// Add Bcc address
	vBccEMail = New Array;
	If Not IsBlankString(vCurEmployee.BccEMail) Then
		vEMailsList = cmParseEMailAddress(vCurEmployee.BccEMail);
		For Each vEMailItem In vEMailsList Do
			vBccEMail.Add(TrimAll(vEMailItem.Value));
		EndDo;
	EndIf;
	
	// Add file as attachement  
	vAttachements = New Map;
	If Not IsBlankString(pNotificationRow.FileName) Then		
		// Save file to the temp directory
		vFileName = cmGetValidFileName(pNotificationRow.FileName);
		vFullFileName = TempFilesDir() + vFileName;
		vBinary = pNotificationRow.ExtFile.Get();
		vBinary.Write(vFullFileName);                 
				              
		vAttachements.Insert(vFileName, vFullFileName);
	EndIf;
		
	EMail.Send(vCurEmployee, vSenderName, TrimAll(vCurEmployee.EMail), TrimAll(pNotificationRow.Remarks), TrimAll(pNotificationRow.DocumentText), , , , , , , vAttachements, vToEMail, vReplyToEMail, , vBccEMail);   
EndProcedure // SendByEMail
	
#EndRegion        
