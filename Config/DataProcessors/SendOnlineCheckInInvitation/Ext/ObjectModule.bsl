
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	If TypeOf(pParameter) = Type("CatalogRef.GuestGroups") Then
		GuestGroup = pParameter.Ref;
	EndIf;
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Template) Then
		If ValueIsFilled(Hotel) Then
			Template = Hotel.TemplateSendOnlineCheckinInvitation;
		EndIf;
	EndIf;
	If Not ValueIsFilled(CheckInDate) Then
		CheckInDate = CurrentSessionDate() + 2*86400;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	pmSendInvitationByEmail(pIsInteractive);
EndProcedure // pmRun

#EndRegion

#Region Internal

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes()

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmSendInvitationByEmail(pIsInteractive = False) Export
	vTabDocs = GetReservationsToSend();
	For Each vResRow In vTabDocs Do 
		Send(vResRow.Ref, pIsInteractive);
	EndDo;
EndProcedure // pmSendInvitationByEmail()

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetReservationsToSend()
	
	vQry = New Query;
	vQry.Text = "SELECT
	            |	Reservation.Ref AS Ref
	            |FROM
	            |	Document.Reservation AS Reservation
	            |WHERE
	            |	Reservation.Posted = TRUE
	            |	AND CASE
	            |			WHEN &qHotelIsEpty
	            |				THEN TRUE
	            |			ELSE Reservation.Hotel = &qHotel
	            |		END
	            |	AND CASE
	            |			WHEN &qCheckInDateIsEmpty
	            |				THEN TRUE
	            |			ELSE BEGINOFPERIOD(Reservation.CheckInDate, DAY) = &qCheckInDate
	            |		END
	            |	AND CASE
	            |			WHEN &qReservationStatusIsEmpty
	            |				THEN Reservation.ReservationStatus.IsActive
	            |			ELSE Reservation.ReservationStatus = &qReservationStatus
	            |		END
	            |	AND CASE
	            |			WHEN &qGuestGroupIsEmpty
	            |				THEN TRUE
	            |			ELSE Reservation.GuestGroup = &qGuestGroup
	            |		END";
	
	vQry.SetParameter("qCheckInDateIsEmpty", Not ValueIsFilled(CheckInDate));
	vQry.SetParameter("qCheckInDate", BegOfDay(CheckInDate)); 
	
	vQry.SetParameter("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	vQry.SetParameter("qGuestGroup", GuestGroup);
	
	vQry.SetParameter("qReservationStatusIsEmpty", Not ValueIsFilled(ReservationStatus));
	vQry.SetParameter("qReservationStatus", ReservationStatus); 
	
	vQry.SetParameter("qHotelIsEpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qHotel", Hotel);
	
	Return vQry.Execute().Unload();
	
EndFunction // FindReservationsToSend()

// -----------------------------------------------------------------------------
Procedure Send(pDoc, pIsInteractive = False)
	vLanguage = pDoc.Guest.Language;
	
	vText = "";
	If ValueIsFilled(Template.HTMLTextRu) Or ValueIsFilled(Template.HTMLTextEn) Or ValueIsFilled(Template.HTMLTextDe) Then
		vText = SMS.GetHTMLTextByLanguage(Template, vLanguage);
	EndIf;
	If IsBlankString(vText) Then
		vText = SMS.GetSMSTextByLanguage(Template, vLanguage);
	EndIf;
	If Not IsBlankString(vText) Then
		vText = SMS.ReplaceSMSParameters(vText, pDoc);
	EndIf;
	
	vEmailAddress = ?(ValueIsFilled(pDoc.Email), pDoc.Email, ?(ValueIsFilled(pDoc.Guest), pDoc.Guest.Email, ""));
	
	vObjectPrintForm = Template.ObjectPrintingFormRu;
	If vLanguage = Catalogs.Languages.EN Then
		vObjectPrintForm = Template.ObjectPrintingFormEn;
	ElsIf  vLanguage = Catalogs.Languages.DE Then 
		vObjectPrintForm = Template.ObjectPrintingFormDe;
	EndIf;
	
	If ValueIsFilled(vObjectPrintForm) And ValueIsFilled(pDoc) And TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
		vDocObj = pDoc.GetObject();
		vPrintFormSpreadsheet = New SpreadsheetDocument();
		If ValueIsFilled(vObjectPrintForm.ExternalProcessing) Then
			vExtDataProcessor = cmGetExternalDataProcessorObject(vObjectPrintForm.ExternalProcessing);
			vExtDataProcessor.pmPrintConfirmation(vPrintFormSpreadsheet, pDoc, Undefined, 0, Catalogs.ServiceGroups.EmptyRef(), False, vLanguage, vObjectPrintForm);
		ElsIf ValueIsFilled(vObjectPrintForm.Report) Then
			vRepObj = cmBuildReportObject(vObjectPrintForm.Report);
			If vRepObj <> Undefined Then
				// Fill reference to the report catalog item
				vRepObj.Report = vObjectPrintForm.Report;
				// Load report catalog item attributes
				vRepObj.pmLoadReportAttributes(pDoc);
				// Generate print form
				vRepObj.pmGenerate(vPrintFormSpreadsheet);
			EndIf;
		Else
			If vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationWithServicesRu Or
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationWithServicesEn Or
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationWithServicesDe Or
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationWithServicesRu Or
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationWithServicesEn Or
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCurrentDocConfirmationWithServicesDe Then
				vDocObj.pmPrintConfirmationWithServices(vPrintFormSpreadsheet, pDoc, Undefined, 0, Catalogs.ServiceGroups.EmptyRef(), False, vLanguage, vObjectPrintForm);
			ElsIf vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCancellationRu Or
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCancellationEn Or
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintCancellationDe Then
				vDocObj.pmPrintCancellation(vPrintFormSpreadsheet, pDoc, Undefined, False, vLanguage, vObjectPrintForm);
			ElsIf vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationRu Or
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationEn Or
				vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationDe Then
				vDocObj.pmPrintExpressCheckInInvitation(vPrintFormSpreadsheet, pDoc, Undefined, False, vLanguage, vObjectPrintForm);
			ElsIf vObjectPrintForm = Catalogs.ObjectPrintingForms.ReservationPrintPaymentOrder Then
				vDocObj.pmPrintPaymentOrder(vPrintFormSpreadsheet, pDoc, pDoc.GetObject(), Undefined, Undefined, vLanguage, vObjectPrintForm);
			Else
				vDocObj.pmPrintConfirmation(vPrintFormSpreadsheet, pDoc, Undefined, 0, Catalogs.ServiceGroups.EmptyRef(), False, vLanguage, vObjectPrintForm);
			EndIf;
		EndIf;
		vResFileNumber = "";
		If Find(vObjectPrintForm.Parameter, "USE_INDIVIDUAL_RESERVATION_NUMBER_FOR_FILE") > 0 Then
			vResFileNumber = vDocObj.Number;
		Else
			vResFileNumber = Format(vDocObj.GuestGroup.Code, "ND=12; NFD=0; NG=");
		Endif;
		// Save reservation confirmation to the temp PDF file
		vPrintFormFileName = StrReplace(pDoc.Metadata().Presentation() + " " + vResFileNumber, " ", "_") + ".pdf";
		vPrintFormFilePath = cmGetFullFileName(vPrintFormFileName, TempFilesDir());
		vPrintFormSpreadsheet.Write(vPrintFormFilePath, SpreadsheetDocumentFileType.PDF);
	EndIf;
	
	vCheckResult = "";
	If Not JobsScheduled.cmSendTextByEMail(cmNStr(Template.Description, vLanguage), TrimAll(vText), TrimAll(vEmailAddress), False,,,, vPrintFormFilePath, Template, pDoc) Then
		vCheckResult = cmNStr("ru='Сообщение не отправлено!'; en='The message was not sent'; de='The message was not sent'");
	Else
		vCheckResult = cmNStr("ru='Сообщение отправлено!'; en='The message was sent'; de='Die Nachricht wurde gesendet'", vLanguage);
	EndIf;
	If pIsInteractive Then
		tcCommonFunctionOnClientServer.TextMessage(vCheckResult, MessageStatus.Information);
	EndIf;
EndProcedure // Send()

#EndRegion
