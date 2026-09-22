// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
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
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Run in-house guests period of stay extension routine
	If DoCheckOutIfInvoiceAndProformaInvoiceAmountsAreTheSame Then
		pmCheckOutIfInvoiceAndProformaInvoiceAmountsAreTheSame(pIsInteractive);
	Else
		pmCheckOutGuests(pIsInteractive);		
	EndIf;
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmCheckOutGuests(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.AutoCheckOutGuests';ru='Обработка.АвтоматическоеВыселениеГостей';de='DataProcessor.AutoCheckOutGuests'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check interactive mode
	If pIsInteractive = Undefined Then
		pIsInteractive = True;
	EndIf;
	// Fill target check-out time 
	vCheckOutDate = CurrentSessionDate();
	// Build list of accommodations to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE (&qHotelIsEmpty
	|			OR Accommodation.Hotel = &qHotel)
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.CheckOutDate < &qCheckOutDate
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCheckOutDate", vCheckOutDate);
	vDocs = vQry.Execute().Unload();
	vNumberOfDocs = vDocs.Count();
	For Each vDocsRow In vDocs Do
		Try
			i = vDocs.IndexOf(vDocsRow) + 1;
			BeginTransaction(DataLockControlMode.Managed);
			vAccObj = vDocsRow.Ref.GetObject();
			If vAccObj.pmGetNextAccommodationInChain() = Undefined Then
				vAccObj.pmCheckout(vAccObj.CheckOutDate);
				vAccObj.Write(DocumentWriteMode.Posting);
				vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
			CommitTransaction();
			#IF CLIENT THEN
				Status(NStr("en='Processed guests: '; ru='Обработано гостей: '; de='Verarbeitete Gäste: '") + i + NStr("en=' from '; ru=' из '; de=' aus '") + vNumberOfDocs + "...", Round(i/vNumberOfDocs*100, 0), NStr("en='Auto check-out guests';ru='Автоматическое выселение гостей';de='Auto check-out guests'"));
				UserInterruptProcessing();
			#ENDIF
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.AutoCheckOutGuests';ru='Обработка.АвтоматическоеВыселениеГостей';de='DataProcessor.AutoCheckOutGuests'"), EventLogLevel.Warning, vAccObj.Metadata(), vAccObj.Ref, vMessage);
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en='DataProcessor.AutoCheckOutGuests';ru='Обработка.АвтоматическоеВыселениеГостей';de='DataProcessor.AutoCheckOutGuests'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmCheckOutGuests

// -----------------------------------------------------------------------------
Procedure pmCheckOutIfInvoiceAndProformaInvoiceAmountsAreTheSame(pIsInteractive = False, pSpreadsheet = Undefined) Export
	WriteLogEvent(NStr("en='DataProcessor.AutoCheckOutGuests';ru='Обработка.АвтоматическоеВыселениеГостей';de='DataProcessor.AutoCheckOutGuests'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check interactive mode
	If pIsInteractive = Undefined Then
		pIsInteractive = True;
	EndIf;
	vTemplate = Undefined;
	If pSpreadsheet <> Undefined Then
		pSpreadsheet.Clear();
		vTemplate = DataProcessors.AutoCheckOutGuests.GetTemplate("ReportTemplate");
		vHeader = vTemplate.GetArea("Header");
		pSpreadsheet.Put(vHeader);
	EndIf;
	
	// Fill target check-out time 
	vCheckOutDate = CurrentSessionDate();
	// Build list of accommodations to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.GuestGroup AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	(&qHotelIsEmpty
	|			OR Accommodation.Hotel = &qHotel)
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.CheckOutDate < &qCheckOutDate
	|
	|GROUP BY
	|	Accommodation.GuestGroup
	|
	|ORDER BY
	|	GuestGroup";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCheckOutDate", vCheckOutDate);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		Try
			BeginTransaction(DataLockControlMode.Managed);
			vCommitTransaction = False;   
			vGuestGroupObj = vDocsRow.Ref.GetObject(); 
			vAccommodationsList = vGuestGroupObj.pmGetAccommodations();
			vAccommodations = New ValueList();
			For Each vAccommodation In vAccommodationsList Do
				vAccObj = vAccommodation.Accommodation.GetObject();
				If vAccObj.pmGetNextAccommodationInChain() = Undefined Then
					vAccObj.pmCheckout(vAccObj.CheckOutDate);
					vAccObj.Write(DocumentWriteMode.Posting);
					vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					vAccommodations.Add(vAccObj.Ref);
				EndIf;
			EndDo;
			vMessage = CheckAccommodationsBalances(vAccommodations);
			If Not ValueIsFilled(vMessage) Or cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithClientDebts") Then
				vProformaInvoice = vGuestGroupObj.pmGetInvoices(vGuestGroupObj.Customer, vGuestGroupObj.Contract);
				If vProformaInvoice.Count() = 1 Then 
					vNewSettlement = Documents.Settlement.CreateDocument();
					vNewSettlement.Fill(vDocsRow.Ref.ClientDoc);
					vNewSettlement.ParentDoc = Documents.Accommodation.EmptyRef();
					vNewSettlement.Fill(vDocsRow.Ref);
					vNewSettlement.Write(DocumentWriteMode.Posting);
					vProformaInvoiceSum = vProformaInvoice.Get(0).Sum;
					vSettlementSum = vNewSettlement.Sum;
					If vProformaInvoiceSum = vSettlementSum Then
						vCommitTransaction = True;	
					Else
						vMessage = NStr("en = 'The invoice amount does not match the proforma invoice amount'; de = 'Der Rechnungsbetrag entspricht nicht dem von Proforma-rechnungen'; ru = 'Сумма акта не совпадает с суммой счета'");	
					EndIf;	
				ElsIf vProformaInvoice.Count() > 1 Then
					vMessage = NStr("en = 'Several proforma invoice'; de = 'Mehrere Proforma-rechnungen'; ru = 'Несколько счетов на оплату'");
				Else
					vMessage = NStr("en = 'No proforma invoice'; de = 'Nein Proforma-rechnungen'; ru = 'Нет счета на оплату'");
				EndIf;			
			EndIf;
			If vCommitTransaction Then
				If TransactionActive() Then
					CommitTransaction();
				EndIf;
			Else
				If pSpreadsheet <> Undefined And vTemplate <> Undefined Then
					vRow = vTemplate.GetArea("Row");
					vRow.Parameters.mGroup = vDocsRow.Ref;
					vRow.Parameters.mCheckIn = vDocsRow.Ref.CheckInDate;
					vRow.Parameters.mCheckOut = vDocsRow.Ref.CheckOutDate;
					vRow.Parameters.mRoom = vDocsRow.Ref.ClientDoc.Room;
					vRow.Parameters.mNames = vDocsRow.Ref.ClientDoc.GuestFullName;
					vRow.Parameters.mError = vMessage;
					pSpreadsheet.Put(vRow);
				EndIf;
				WriteLogEvent(NStr("en='DataProcessor.AutoCheckOutGuests';ru='Обработка.АвтоматическоеВыселениеГостей';de='DataProcessor.AutoCheckOutGuests'"), EventLogLevel.Warning, vGuestGroupObj.Metadata(), vGuestGroupObj.Ref, vMessage);
				If TransactionActive() Then
					RollbackTransaction();
				EndIf;
			EndIf;
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.AutoCheckOutGuests';ru='Обработка.АвтоматическоеВыселениеГостей';de='DataProcessor.AutoCheckOutGuests'"), EventLogLevel.Warning, vGuestGroupObj.Metadata(), vGuestGroupObj.Ref, vMessage);
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en='DataProcessor.AutoCheckOutGuests';ru='Обработка.АвтоматическоеВыселениеГостей';de='DataProcessor.AutoCheckOutGuests'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmCheckOutGuests

// -----------------------------------------------------------------------------
Function CheckAccommodationsBalances(pAcc)
	vFolios = cmGetDocumentFoliosWithDebts(pAcc);
	If vFolios.Count() > 0 Then
		vDoQuery = False;
		vThereAreDebts = False;
		vThereAreDeposits = False;
		vDebtsMessage = NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF;
		For Each vFoliosRow In vFolios Do
			If vFoliosRow.SumBalance < 0 Then
				vThereAreDeposits = True;
			ElsIf vFoliosRow.SumBalance > 0 Then
				vThereAreDebts = True;
			EndIf;
			If ValueIsFilled(vFoliosRow.Folio) Then
				If ValueIsFilled(vFoliosRow.Folio.PaymentMethod) Then
					If Not vFoliosRow.Folio.PaymentMethod.BookByCashRegister Or
					   (vFoliosRow.Folio.PaymentMethod.IsByBankTransfer And ValueIsFilled(vFoliosRow.Folio.Customer))Then
						Continue;
					EndIf;
				EndIf;
				vDoQuery = True;
				vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFoliosRow.Folio.Number) + " " + 
				                TrimAll(vFoliosRow.Folio.Client) + NStr("ru = ', номер '; en = ', room '; de = ', zimmer '") + 
				                TrimAll(vFoliosRow.Folio.Room) + NStr("ru = ', период '; en = ', period '; de = ', period '") + 
				                Format(vFoliosRow.Folio.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
				                Format(vFoliosRow.Folio.DateTimeTo, "DF='dd.MM.yy HH:mm'") + " = " + 
				                cmFormatSum(vFoliosRow.SumBalance, vFoliosRow.Folio.FolioCurrency, "NZ=");
			Else
				vDoQuery = True;
				vDebtsMessage = vDebtsMessage + Chars.LF + NStr("en='<Empty folio>';ru='<Пустое фолио>';de='<Leeres Blatt>'") + " = " + cmFormatSum(vFoliosRow.SumBalance, "NZ=", , True);
			EndIf;
		EndDo;
		If vDoQuery Then
			If vThereAreDebts And Not vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEBTS!';ru='ЕСТЬ ЗАДОЛЖЕННОСТЬ!';de='ES LIEGT EINE SCHULD VOR!'");
			ElsIf Not vThereAreDebts And vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEPOSITS!';ru='ЕСТЬ ПЕРЕПЛАТА!';de='ES LIEGT EINE ÜBERZAHLUNG VOR!'");
			Else
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEBTS AND DEPOSITS!';ru='ЕСТЬ ЗАДОЛЖЕННОСТЬ И ПЕРЕПЛАТА!';de='ES LIEGT EINE SCHULD oder ÜBERZAHLUNG vor!'");
			EndIf;
			Return vDebtsMessage;
		EndIf;
	EndIf;
	Return "";
EndFunction // CheckAccommodationsBalances