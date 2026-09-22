
#Region EventHandlers

 // -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	vIsTransferToDiscountCard = Not GetDiscountCardByFolio(FolioTo).IsEmpty();
    
    // 1. Post to Accounts
	PostToAccounts(vIsTransferToDiscountCard);
	
	// 2. Post to Payments
	PostToPayments();
	
	// 3. Post to Folio payments
	PostToFolioPayments();
	
	// 4. Post to Customer accounts
    If Not vIsTransferToDiscountCard Then
        PostToCustomerAccounts();
    EndIf;
    
	// 5. Post to Payment services
    If Not vIsTransferToDiscountCard Then
        If Hotel.DoPaymentsDistributionToServices Then
            PostToPaymentServices();
        EndIf;
    EndIf;

	// 6. Repost invoices if any
    If Not vIsTransferToDiscountCard Then
        pmRepostSettlements();
    EndIf;
	
	// 7. Set hotel product payment date
    If Not vIsTransferToDiscountCard Then
        FillHotelProductPaymentDate();
    EndIf;
    
	// 8. Create invoice if neccessary
	If ValueIsFilled(FolioTo) And ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices And Not vIsTransferToDiscountCard Then
		vInvoice = pmGetPaymentInvoice();
		If Not ValueIsFilled(vInvoice) Then
			// Check if this is advance payment
			vIsPrepayment = pmIsPrepayment();
			If Not vIsPrepayment Then
				// Generate invoice
				vInvObj = Documents.Settlement.CreateDocument();
				vInvObj.Date = Date + 1;
				vInvObj.Fill(Ref);
				If vInvObj.Services.Count() = 0 Then
					vIsPrepayment = True;
				Else
					vInvObj.Write(DocumentWriteMode.Posting);
				EndIf;
			EndIf;
			If vIsPrepayment Then
				// Generate proforma invoice
				vInvObj = Documents.ProformaInvoice.CreateDocument();
				vInvObj.Date = Date + 1;
				vInvObj.Fill(Ref);
				vInvObj.Write(DocumentWriteMode.Posting);
				// Save proforma invoice reference
				Invoice = vInvObj.Ref;
			EndIf;					
		EndIf;
	Else
		// Update (proforma) invoice balance
		If ValueIsFilled(Invoice) Then
			PostToInvoiceAccounts();
		EndIf;
	EndIf;
    
    // 9. Create payment for discount card
    If vIsTransferToDiscountCard Then
        TransferGiftCertificateBalance(pCancel);
    EndIf; 
    
	// Save data if there were changes
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
	
	// 10. Post to FO chart of accounts
	PostToFOChartOfAccounts();
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Folio") Then
			FillByFolio(pBase);
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, ThisObject.Metadata(), ThisObject.Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
		If ValueIsFilled(FolioFrom) And ValueIsFilled(FolioTo) And
		   FolioFrom.GuestGroup <> FolioTo.GuestGroup Then
			
			// User activity history   
			vEventDescription = StrTemplate(NStr("en = 'Deposit transfer between groups: %1 -> %2, %3'; 
												 |de = 'Anzahlungstransfer zwischen Gruppen: %1 -> %2, %3'; 
												 |ru = 'Перемещение депозита между разными группами: %1 -> %2, %3'"), TrimAll(FolioFrom.GuestGroup), TrimAll(FolioTo.GuestGroup), cmFormatSum(SumInFolioFromCurrency, FolioFromCurrency));  
			vParentDoc = Ref;
			If ValueIsFilled(ParentDoc) Then
				vParentDoc = ParentDoc; 
			ElsIf Not ValueIsFilled(ParentDoc) And IsNew() Then 
				vParentDoc = Documents.DepositTransfer.GetRef(New UUID);
				SetNewObjectRef(vParentDoc);	
			EndIf;	
	
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	// Accounts
	vAccSet = AccumulationRegisters.Accounts.CreateRecordSet();
	vAccSet.Filter.Recorder.Set(Ref);
	vAccSet.Read();
	vAccSet.Clear();
	vAccSet.Write(True);
	// Repost settlements
	pmRepostSettlements();
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
	AccountingDate = '00010101';
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
		AccountingDate = Hotel.AccountingDate;
	EndIf;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	
	If DeletionMark Then
		If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
			vInvRef = pmGetPaymentInvoice();
			If ValueIsFilled(vInvRef) And Not vInvRef.DeletionMark Then
				vInvRef.GetObject().SetDeletionMark(True);
			EndIf;
		EndIf;
	EndIf;          
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmRepostSettlements() Export
	If ValueIsFilled(Hotel) And Hotel.SwitchOffRepostingOfSettlements Then
		Return;
	EndIf;
	If ValueIsFilled(FolioFrom) And ValueIsFilled(FolioFrom.PaymentMethod) And 
	   FolioFrom.PaymentMethod.IsByBankTransfer Then
		vSettlements = FolioFrom.GetObject().pmGetAllFolioSettlements();
		For Each vSettlementsRow In vSettlements Do
			vSettlementObj = vSettlementsRow.Document.GetObject();
			vSettlementObj.pmPostToAccountsAndPayments();
		EndDo;
	EndIf;
	If ValueIsFilled(FolioTo) And ValueIsFilled(FolioTo.PaymentMethod) And 
	   FolioTo.PaymentMethod.IsByBankTransfer Then
		vSettlements = FolioTo.GetObject().pmGetAllFolioSettlements();
		For Each vSettlementsRow In vSettlements Do
			vSettlementObj = vSettlementsRow.Document.GetObject();
			vSettlementObj.pmPostToAccountsAndPayments();
		EndDo;
	EndIf;
EndProcedure // pmRepostSettlements

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(FolioFrom) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Лицевой счет источник> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio from> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio from> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "FolioFrom", pAttributeInErr);
	Else
		If FolioFrom.DeletionMark Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "<Лицевой счет источник> помечен на удаление!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Folio from> is marked for deletion!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Folio from> is marked for deletion!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "FolioFrom", pAttributeInErr);
		EndIf;
	EndIf;
	If Not ValueIsFilled(FolioTo) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Лицевой счет получатель> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio to> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio to> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "FolioTo", pAttributeInErr);
	Else
		If FolioTo.DeletionMark Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "<Лицевой счет получатель> помечен на удаление!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Folio to> is marked for deletion!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Folio to> is marked for deletion!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "FolioTo", pAttributeInErr);
		EndIf;
	EndIf;
	If ValueIsFilled(FolioFrom) And ValueIsFilled(FolioTo) Then
		If FolioFrom = FolioTo And
		   (PaymentSections.Count() = 0 Or PaymentSections.Count() <> 0 And Not ValueIsFilled(PaymentSection)) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Лицевые счета должны быть разными!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Folios should not be the same!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Folios should not be the same!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "FolioTo", pAttributeInErr);
		EndIf;
	EndIf;
	If Not ValueIsFilled(FolioFromCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта лицевого счета источника> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio from currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio from currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "FolioFromCurrency", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(FolioToCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта лицевого счета получателя> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio to currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio to currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "FolioToCurrency", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ExchangeRateDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата курса> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ExchangeRateDate", pAttributeInErr);
	EndIf;
	If SumInFolioFromCurrency < 0 And FolioFrom <> Hotel.ReservationAdvancesFolio Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Для оформления возврата необходимо использовать документ ""Возврат""!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "Use ""Return"" document to return money!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Use ""Return"" document to return money!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "SumInFolioFromCurrency", pAttributeInErr);
	EndIf;
	If Not Posted Then
		// Check user rights to do transfer
		vEmployee = SessionParameters.CurrentUser;
		If ValueIsFilled(vEmployee) And ValueIsFilled(vEmployee.PermissionGroup) And ValueIsFilled(FolioFrom) And ValueIsFilled(FolioTo) Then
			vPermissionGroup = vEmployee.PermissionGroup;
			For Each vPrmRow In vPermissionGroup.FolioOperationsAllowed Do
				If IsBlankString(vPrmRow.FolioType) Or 
				   Not IsBlankString(vPrmRow.FolioType) And TrimR(vPrmRow.FolioType) = Left(TrimR(FolioFrom.Description), StrLen(TrimR(vPrmRow.FolioType))) Then
					If vPrmRow.DepositTransfersFromFolioForbidden Then
						vHasErrors = True;
						vMsgTextRu = vMsgTextRu + "Нет прав на перемещение денег из фолио с типом " + TrimAll(FolioFrom.Description) + "!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "You do not have rights to transfer deposit from folio type " + TrimAll(FolioFrom.Description) + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Sie haben keine Rechte für Transfer von Folio-typ " + TrimAll(FolioFrom.Description) + " nutzen!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "FolioFrom", pAttributeInErr);
					EndIf;
				EndIf;
				If IsBlankString(vPrmRow.FolioType) Or 
				   Not IsBlankString(vPrmRow.FolioType) And TrimR(vPrmRow.FolioType) = Left(TrimR(FolioTo.Description), StrLen(TrimR(vPrmRow.FolioType))) Then
					If vPrmRow.DepositTransfersToFolioForbidden Then
						vHasErrors = True;
						vMsgTextRu = vMsgTextRu + "Нет прав на перемещение денег на фолио с типом " + TrimAll(FolioTo.Description) + "!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "You do not have rights to transfer deposit to folio type " + TrimAll(FolioTo.Description) + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Sie haben keine Rechte für Transfer zum Folio-typ " + TrimAll(FolioTo.Description) + " nutzen!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "FolioTo", pAttributeInErr);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';"+ "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	If Not ValueIsFilled(Author) Then
		Author = SessionParameters.CurrentUser;
	EndIf;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	ExchangeRateDate = BegOfDay(CurrentSessionDate());
	PaymentMethod = Catalogs.PaymentMethods.DepositTransfer;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(Hotel.AccountingDate) Then
			AccountingDate = Hotel.AccountingDate;
		EndIf;
		FolioFromCurrency = Hotel.FolioCurrency;
		FolioToCurrency = Hotel.FolioCurrency;
		FolioFromCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioFromCurrency, ExchangeRateDate);
		FolioToCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioToCurrency, ExchangeRateDate);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmCalculateSums() Export
	If PaymentSections.Count() > 0 Then
		For Each vPSRow In PaymentSections Do
			vPSRow.SumInFolioToCurrency = Round(cmConvertCurrencies(vPSRow.SumInFolioFromCurrency, FolioFromCurrency, FolioFromCurrencyExchangeRate, 
			                                                        FolioToCurrency, FolioToCurrencyExchangeRate, 
			                                                        ExchangeRateDate, Hotel), 2);
		EndDo;
		SumInFolioFromCurrency = PaymentSections.Total("SumInFolioFromCurrency");
		SumInFolioToCurrency = PaymentSections.Total("SumInFolioToCurrency");
	Else
		SumInFolioToCurrency = Round(cmConvertCurrencies(SumInFolioFromCurrency, FolioFromCurrency, FolioFromCurrencyExchangeRate, 
		                                                 FolioToCurrency, FolioToCurrencyExchangeRate, 
		                                                 ExchangeRateDate, Hotel), 2);
	EndIf;
EndProcedure // pmCalculateSums

// -----------------------------------------------------------------------------
Procedure pmFolioToOnChange() Export
	If ValueIsFilled(FolioTo) Then
		FolioToCurrency = FolioTo.FolioCurrency;
		FolioToCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioToCurrency, ExchangeRateDate);
		pmCalculateSums();
	EndIf;
EndProcedure // pmFolioToOnChange

// -----------------------------------------------------------------------------
Function pmGetPaymentInvoice() Export
	If ValueIsFilled(Invoice) Then
		Return Invoice;
	Else
		vQry = New Query();
		vQry.Text = 
		"SELECT DISTINCT
		|	SettlementPaymentDocuments.Ref AS Invoice
		|FROM
		|	Document.Settlement.PaymentDocuments AS SettlementPaymentDocuments
		|WHERE
		|	SettlementPaymentDocuments.Ref.Posted
		|	AND SettlementPaymentDocuments.PaymentDoc = &qRef";
		vQry.SetParameter("qRef", Ref);
		vInvoices = vQry.Execute().Unload();
		For Each vInvoicesRow In vInvoices Do
			Return vInvoicesRow.Invoice;
		EndDo;
	EndIf;
	Return Undefined;
EndFunction // GetPaymentInvoice

// -----------------------------------------------------------------------------
Function pmGetBonusesPayment() Export
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	BonusesPayment.Ref AS Ref
		|FROM
		|	Document.BonusesPayment AS BonusesPayment
		|WHERE
		|	NOT BonusesPayment.DeletionMark
		|	AND BonusesPayment.Posted
		|	AND BonusesPayment.Payment = &qPayment";
	vQuery.SetParameter("qPayment", Ref);
	vQueryResult = vQuery.Execute();
	vRes = vQueryResult.Select();
	While vRes.Next() Do
		Return vRes.ref;
	EndDo;
	Return Documents.BonusesPayment.EmptyRef();
EndFunction // pmGetBonusesPayment

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure PostToAccounts(pIsGifCardTopUp)
	vIsByServices = ?(ValueIsFilled(Hotel), Hotel.SplitFolioBalanceByServicesAndPrices, False);
	If PaymentSections.Count() > 0 Then
		For Each vPSRow In PaymentSections Do
			If vPSRow.SumInFolioFromCurrency = 0 Then
				Continue;
			EndIf;
					
			// Storno movement for folio from
			Movement = RegisterRecords.Accounts.Add();
			
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			
			FillPropertyValues(Movement, FolioFrom);
			If ValueIsFilled(Payment) And ValueIsFilled(Payment.ParentDoc) Then
				FillPropertyValues(Movement, Payment.ParentDoc, , "Hotel");
			ElsIf ValueIsFilled(ParentDoc) Then
				FillPropertyValues(Movement, ParentDoc, , "Hotel");
			EndIf;
			FillPropertyValues(Movement, ThisObject, , "Hotel");
			If Not ValueIsFilled(Movement.Hotel) Then
				Movement.Hotel = Hotel;
			EndIf;
			
			// Attributes
			If ValueIsFilled(Payment) And ValueIsFilled(Payment.ParentDoc) Then
				Movement.ParentDoc = Payment.ParentDoc;
			EndIf;
			
			// Dimensions
			Movement.Folio = FolioFrom;
			Movement.FolioCurrency = FolioFromCurrency;
			Movement.PaymentSection = vPSRow.PaymentSection;
			Movement.ChequeService = vPSRow.ChequeService;
			Movement.ChequeServicePrice = vPSRow.ChequeServicePrice;
			
			// Resources
			Movement.Sum = -vPSRow.SumInFolioFromCurrency;
			If ValueIsFilled(Movement.PaymentSection) And ValueIsFilled(Movement.PaymentSection.VATRate) Then
				Movement.VATRate = Movement.PaymentSection.VATRate;
			ElsIf ValueIsFilled(FolioFrom.Company) And ValueIsFilled(FolioFrom.Company.VATRate) Then
				Movement.VATRate = FolioFrom.Company.VATRate;
			EndIf;
			Movement.VATSum = 0;
			If ValueIsFilled(Movement.VATRate) Then
				Movement.VATSum = cmCalculateVATSum(Movement.VATRate, Movement.Sum, Date);
			EndIf;
			Movement.ChequeServiceQuantity = -vPSRow.ChequeServiceQuantity;
			
			// If this is advance
			If vIsByServices And Not ValueIsFilled(Movement.ChequeService) Then
				Movement.ChequeServiceQuantity = 0;
				Movement.ChequeServicePrice = 0;
			EndIf;
				
			// Expense movement for folio to
			Movement = RegisterRecords.Accounts.Add();
			
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = Date;
			
			FillPropertyValues(Movement, FolioTo);
			FillPropertyValues(Movement, ThisObject, , "Hotel");
			If Not ValueIsFilled(Movement.Hotel) Then
				Movement.Hotel = Hotel;
			EndIf;
			
			// Dimensions
			Movement.Folio = FolioTo;
			Movement.FolioCurrency = FolioToCurrency;
			Movement.PaymentSection = ?(ValueIsFilled(PaymentSection), PaymentSection, vPSRow.PaymentSection);
			Movement.ChequeService = vPSRow.ChequeService;
			Movement.ChequeServicePrice = vPSRow.ChequeServicePrice;
			
			// Resources
			Movement.Sum = vPSRow.SumInFolioToCurrency;
			If ValueIsFilled(Movement.PaymentSection) And ValueIsFilled(Movement.PaymentSection.VATRate) Then
				Movement.VATRate = Movement.PaymentSection.VATRate;
			ElsIf ValueIsFilled(FolioTo.Company) And ValueIsFilled(FolioTo.Company.VATRate) Then
				Movement.VATRate = FolioTo.Company.VATRate;
			EndIf;
			Movement.VATSum = 0;
			If ValueIsFilled(Movement.VATRate) Then
				Movement.VATSum = cmCalculateVATSum(Movement.VATRate, Movement.Sum, Date);
			EndIf;
			Movement.ChequeServiceQuantity = vPSRow.ChequeServiceQuantity;
			
			// If this is advance
			If vIsByServices And Not ValueIsFilled(Movement.ChequeService) Then
				Movement.ChequeServiceQuantity = 0;
				Movement.ChequeServicePrice = 0;
            EndIf;
            
            // Zero resources if this is gift card refill
			If pIsGifCardTopUp Then
				Movement.Sum = 0;
				Movement.Limit = 0;
				Movement.VATSum = 0;
				Movement.ChequeServicePrice = 0;
				Movement.ChequeServiceQuantity = 0;
			EndIf;
		EndDo;
	Else
		// Storno movement for folio from
		Movement = RegisterRecords.Accounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		FillPropertyValues(Movement, FolioFrom);
		If ValueIsFilled(Payment) And ValueIsFilled(Payment.ParentDoc) Then
			FillPropertyValues(Movement, Payment.ParentDoc, , "Hotel");
		ElsIf ValueIsFilled(ParentDoc) Then
			FillPropertyValues(Movement, ParentDoc, , "Hotel");
		EndIf;
		FillPropertyValues(Movement, ThisObject, , "Hotel");
		If Not ValueIsFilled(Movement.Hotel) Then
			Movement.Hotel = Hotel;
		EndIf;
		
		// Attributes
		If ValueIsFilled(Payment) And ValueIsFilled(Payment.ParentDoc) Then
			Movement.ParentDoc = Payment.ParentDoc;
		EndIf;
		
		// Dimensions
		Movement.Folio = FolioFrom;
		Movement.FolioCurrency = FolioFromCurrency;
		
		// Resources
		Movement.Sum = -SumInFolioFromCurrency;
		If ValueIsFilled(Movement.PaymentSection) And ValueIsFilled(Movement.PaymentSection.VATRate) Then
			Movement.VATRate = Movement.PaymentSection.VATRate;
		ElsIf ValueIsFilled(FolioFrom.Company) And ValueIsFilled(FolioFrom.Company.VATRate) Then
			Movement.VATRate = FolioFrom.Company.VATRate;
		EndIf;
		Movement.VATSum = 0;
		If ValueIsFilled(Movement.VATRate) Then
			Movement.VATSum = cmCalculateVATSum(Movement.VATRate, Movement.Sum, Date);
		EndIf;
		
		// Payment section
		If ValueIsFilled(Hotel) And Not Hotel.SplitFolioBalanceByPaymentSections And Not Hotel.SplitFolioBalanceByServicesAndPrices Then
			Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
			Movement.ChequeService = Catalogs.Services.EmptyRef();
			Movement.ChequeServicePrice = 0;
			Movement.ChequeServiceQuantity = 0;
		EndIf;
		
		// Expense movement for folio to
		Movement = RegisterRecords.Accounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = Date;
		
		FillPropertyValues(Movement, FolioTo);
		FillPropertyValues(Movement, ThisObject, , "Hotel");
		If Not ValueIsFilled(Movement.Hotel) Then
			Movement.Hotel = Hotel;
		EndIf;
		
		// Dimensions
		Movement.Folio = FolioTo;
		Movement.FolioCurrency = FolioToCurrency;
		
		// Resources
		Movement.Sum = SumInFolioToCurrency;
		If ValueIsFilled(Movement.PaymentSection) And ValueIsFilled(Movement.PaymentSection.VATRate) Then
			Movement.VATRate = Movement.PaymentSection.VATRate;
		ElsIf ValueIsFilled(FolioTo.Company) And ValueIsFilled(FolioTo.Company.VATRate) Then
			Movement.VATRate = FolioTo.Company.VATRate;
		EndIf;
		Movement.VATSum = 0;
		If ValueIsFilled(Movement.VATRate) Then
			Movement.VATSum = cmCalculateVATSum(Movement.VATRate, Movement.Sum, Date);
		EndIf;
		
		// Payment section
		If ValueIsFilled(Hotel) And Not Hotel.SplitFolioBalanceByPaymentSections And Not Hotel.SplitFolioBalanceByServicesAndPrices Then
			Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
			Movement.ChequeService = Catalogs.Services.EmptyRef();
			Movement.ChequeServicePrice = 0;
			Movement.ChequeServiceQuantity = 0;
        EndIf;
        
        // Zero resources if this is gift card refill
		If pIsGifCardTopUp Then
			Movement.Sum = 0;
			Movement.Limit = 0;
			Movement.VATSum = 0;
			Movement.ChequeServicePrice = 0;
			Movement.ChequeServiceQuantity = 0;
		EndIf;
	EndIf;
	
	// Write movements
	RegisterRecords.Accounts.Write();
EndProcedure // PostToAccounts

// -----------------------------------------------------------------------------
Procedure PostToFolioPayments()
	If PaymentSections.Count() > 0 Then
		vPaymentSections = PaymentSections.Unload();
		vPaymentSections.GroupBy("PaymentSection", "SumInFolioFromCurrency, SumInFolioToCurrency");
		For Each vPSRow In vPaymentSections Do
			If vPSRow.SumInFolioFromCurrency = 0 Then
				Continue;
			EndIf;
			
			// Storno movement for folio from
			Movement = RegisterRecords.FolioPayments.Add();
			
			Movement.Period = Date;
			
			FillPropertyValues(Movement, FolioFrom);
			If ValueIsFilled(ParentDoc) Then
				FillPropertyValues(Movement, ParentDoc, , "Hotel");
			EndIf;
			FillPropertyValues(Movement, ThisObject, , "Hotel");
			If Not ValueIsFilled(Movement.Hotel) Then
				Movement.Hotel = Hotel;
			EndIf;
			
			// Dimensions
			Movement.Folio = FolioFrom;
			Movement.FolioCurrency = FolioFromCurrency;
			Movement.Payment = ThisObject.Ref;
			
			// Resources
			Movement.Sum = -vPSRow.SumInFolioFromCurrency;
			
			// Attributes
			Movement.PaymentCurrency = FolioFromCurrency;
			Movement.SumInPaymentCurrency = -vPSRow.SumInFolioFromCurrency;
			Movement.PaymentSection = vPSRow.PaymentSection;
			
			// Expense movement for folio to
			Movement = RegisterRecords.FolioPayments.Add();
			
			Movement.Period = Date;
			
			FillPropertyValues(Movement, FolioTo);
			FillPropertyValues(Movement, ThisObject, , "Hotel");
			If Not ValueIsFilled(Movement.Hotel) Then
				Movement.Hotel = Hotel;
			EndIf;
			
			// Dimensions
			Movement.Folio = FolioTo;
			Movement.FolioCurrency = FolioToCurrency;
			Movement.Payment = ThisObject.Ref;
			
			// Resources
			Movement.Sum = vPSRow.SumInFolioToCurrency;
			
			// Attributes
			Movement.PaymentCurrency = FolioToCurrency;
			Movement.SumInPaymentCurrency = vPSRow.SumInFolioToCurrency;
			Movement.PaymentSection = ?(ValueIsFilled(PaymentSection), PaymentSection, vPSRow.PaymentSection);
		EndDo;
	Else					
		// Storno movement for folio from
		Movement = RegisterRecords.FolioPayments.Add();
		
		Movement.Period = Date;
		
		FillPropertyValues(Movement, FolioFrom);
		If ValueIsFilled(ParentDoc) Then
			FillPropertyValues(Movement, ParentDoc, , "Hotel");
		EndIf;
		FillPropertyValues(Movement, ThisObject, , "Hotel");
		If Not ValueIsFilled(Movement.Hotel) Then
			Movement.Hotel = Hotel;
		EndIf;
		
		// Dimensions
		Movement.Folio = FolioFrom;
		Movement.FolioCurrency = FolioFromCurrency;
		Movement.Payment = ThisObject.Ref;
		
		// Resources
		Movement.Sum = -SumInFolioFromCurrency;
		
		// Attributes
		Movement.PaymentCurrency = FolioFromCurrency;
		Movement.SumInPaymentCurrency = -SumInFolioFromCurrency;
		
		// Expense movement for folio to
		Movement = RegisterRecords.FolioPayments.Add();
		
		Movement.Period = Date;
		
		FillPropertyValues(Movement, FolioTo);
		FillPropertyValues(Movement, ThisObject, , "Hotel");
		If Not ValueIsFilled(Movement.Hotel) Then
			Movement.Hotel = Hotel;
		EndIf;
		
		// Dimensions
		Movement.Folio = FolioTo;
		Movement.FolioCurrency = FolioToCurrency;
		Movement.Payment = ThisObject.Ref;
		
		// Resources
		Movement.Sum = SumInFolioToCurrency;
		
		// Attributes
		Movement.PaymentCurrency = FolioToCurrency;
		Movement.SumInPaymentCurrency = SumInFolioToCurrency;
	EndIf;
	
	// Write movements
	RegisterRecords.FolioPayments.Write();
EndProcedure // PostToFolioPayments

// -----------------------------------------------------------------------------
Procedure PostToInvoiceAccounts()
	Movement = RegisterRecords.InvoiceAccounts.Add();
	
	Movement.RecordType = AccumulationRecordType.Expense;
	Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
	
	// Dimensions
	Movement.Hotel = Invoice.Hotel;
	If Not ValueIsFilled(Movement.Hotel) Then
		Movement.Hotel = Hotel;
	EndIf;
	Movement.Company = Invoice.Company;
	Movement.Invoice = Invoice;
	Movement.AccountingCustomer = Invoice.AccountingCustomer;
	Movement.AccountingContract = Invoice.AccountingContract;
	Movement.AccountingCurrency = Invoice.AccountingCurrency;
	Movement.GuestGroup = Invoice.GuestGroup;
	
	// Resources
	Movement.Sum = cmConvertCurrencies(SumInFolioToCurrency, FolioToCurrency, FolioToCurrencyExchangeRate, Movement.AccountingCurrency, , ExchangeRateDate, Hotel);
	
	// Attributes
	vVATRate = Invoice.Company.VATRate;
	If ValueIsFilled(Payment) And ValueIsFilled(Payment.VATRate) Then
		vVATRate = Payment.VATRate;
	EndIf;
	Movement.VATSum = cmCalculateVATSum(vVATRate, Movement.Sum, Date);
	Movement.VATRate = vVATRate;
	Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
	
	If ValueIsFilled(FolioTo) Then
		Movement.Client = FolioTo.Client;
		Movement.Room = FolioTo.Room;
	EndIf;
EndProcedure // PostToInvoiceAccounts

// -----------------------------------------------------------------------------
Procedure PostToPaymentServices()
	If PaymentSections.Count() > 0 Then
		vPaymentSections = PaymentSections.Unload();
		vPaymentSections.GroupBy("PaymentSection", "SumInFolioFromCurrency, SumInFolioToCurrency");
		For Each vPSRow In vPaymentSections Do
			If vPSRow.SumInFolioFromCurrency = 0 Then
				Continue;
			EndIf;
			
			// Storno movement for folio from
			Movement = RegisterRecords.PaymentServices.Add();
			
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = Date;
			
			// Dimensions
			Movement.Folio = FolioFrom;
			Movement.Service = Catalogs.Services.EmptyRef();
			Movement.Payment = Ref;
			
			// Resources
			Movement.Sum = -vPSRow.SumInFolioFromCurrency;
			
			// Expense movement for folio to
			Movement = RegisterRecords.PaymentServices.Add();
			
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = Date;
			
			// Dimensions
			Movement.Folio = FolioTo;
			Movement.PaymentSection = vPSRow.PaymentSection;
			Movement.Service = Catalogs.Services.EmptyRef();
			Movement.Payment = Ref;
			
			// Resources
			Movement.Sum = vPSRow.SumInFolioToCurrency;
		EndDo;			
	Else
		// Storno movement for folio from
		Movement = RegisterRecords.PaymentServices.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = Date;
		
		// Dimensions
		Movement.Folio = FolioFrom;
		Movement.Service = Catalogs.Services.EmptyRef();
		Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
		Movement.Payment = Ref;
		
		// Resources
		Movement.Sum = -SumInFolioFromCurrency;
		
		// Expense movement for folio to
		Movement = RegisterRecords.PaymentServices.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = Date;
		
		// Dimensions
		Movement.Folio = FolioTo;
		Movement.Service = Catalogs.Services.EmptyRef();
		Movement.Payment = Ref;
		
		// Resources
		Movement.Sum = SumInFolioToCurrency;
	EndIf;
	
	// Write movements
	RegisterRecords.PaymentServices.Write();
EndProcedure // PostToPaymentServices

// -----------------------------------------------------------------------------
Function CheckPaymentSections()
	If ValueIsFilled(PaymentSection) And PaymentSections.Count() > 0 Then
		For Each vPSRow In PaymentSections Do
			If vPSRow.SumInFolioFromCurrency = 0 Then
				Continue;
			EndIf;
			If vPSRow.PaymentSection <> PaymentSection Then
				Return True;
			EndIf;
		EndDo;
		Return False;
	Else
		Return False;
	EndIf;
EndFunction // CheckPaymentSections 

// -----------------------------------------------------------------------------
Procedure PostToCustomerAccounts()
	// Post movents if customer accounts accummulation register 
	// dimensions are not the same for source and target folios
	If ValueIsFilled(Hotel) And FolioFrom <> Hotel.ReservationAdvancesFolio And 
	  (FolioFrom.Company <> FolioTo.Company Or
	   FolioFrom.Customer <> FolioTo.Customer Or
	   FolioFrom.Contract <> FolioTo.Contract Or
	   FolioFrom.FolioCurrency <> FolioTo.FolioCurrency Or
	   FolioFrom.GuestGroup <> FolioTo.GuestGroup Or
	   FolioFrom.Hotel <> FolioTo.Hotel Or 
	   FolioFrom.Description <> FolioTo.Description Or 
	   CheckPaymentSections()) Then
	   
		If PaymentSections.Count() > 0 Then
			vPaymentSections = PaymentSections.Unload();
			For Each vPSRow In vPaymentSections Do
				If vPSRow.SumInFolioFromCurrency = 0 Then
					Continue;
				EndIf;
				
				// Do correction movement for the source folio   
				Movement = RegisterRecords.CustomerAccounts.Add();
				
				Movement.RecordType = AccumulationRecordType.Expense;
				Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
				
				// Dimensions
				Movement.AccountingCurrency = FolioFromCurrency;
				Movement.Hotel = FolioFrom.Hotel;
				If Not ValueIsFilled(Movement.Hotel) Then
					Movement.Hotel = Hotel;
				EndIf;
				Movement.Company = FolioFrom.Company;
				If ValueIsFilled(FolioFrom.Customer) Then
					Movement.AccountingCustomer = FolioFrom.Customer;
					Movement.AccountingContract = FolioFrom.Contract;
				Else
					Movement.AccountingCustomer = FolioFrom.Hotel.IndividualsCustomer;
					Movement.AccountingContract = FolioFrom.Hotel.IndividualsContract;
				EndIf;
				Movement.GuestGroup = FolioFrom.GuestGroup;
				If Not ValueIsFilled(FolioFrom.GuestGroup) Then
					If ValueIsFilled(Payment) And ValueIsFilled(Payment.ParentDoc) Then
						Movement.ParentDoc = Payment.ParentDoc;
						Movement.GuestGroup = Payment.ParentDoc.GuestGroup;
					EndIf;
				EndIf;
				
				// Resources
				Movement.Sum = -vPSRow.SumInFolioFromCurrency;
				
				// Attributes
				Movement.Folio = FolioFrom;
				Movement.Client = FolioFrom.Client;
				Movement.Room = FolioFrom.Room;
				Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
				Movement.PaymentMethod = PaymentMethod;
				Movement.PaymentSection = vPSRow.PaymentSection;
				If ValueIsFilled(Movement.PaymentSection) And ValueIsFilled(Movement.PaymentSection.VATRate) Then
					Movement.VATRate = Movement.PaymentSection.VATRate;
				ElsIf ValueIsFilled(FolioFrom.Company) And ValueIsFilled(FolioFrom.Company.VATRate) Then
					Movement.VATRate = FolioFrom.Company.VATRate;
				EndIf;
				Movement.VATSum = 0;
				If ValueIsFilled(Movement.VATRate) Then
					Movement.VATSum = cmCalculateVATSum(Movement.VATRate, Movement.Sum, Date);
				EndIf;
				
				Movement.Service = vPSRow.ChequeService;
				Movement.Price = vPSRow.ChequeServicePrice;
				Movement.Quantity = vPSRow.ChequeServiceQuantity;
				
				// Do payment movement for the target folio   
				Movement = RegisterRecords.CustomerAccounts.Add();
				
				Movement.RecordType = AccumulationRecordType.Expense;
				Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
				
				// Dimensions
				Movement.AccountingCurrency = FolioToCurrency;
				Movement.Hotel = FolioTo.Hotel;
				If Not ValueIsFilled(Movement.Hotel) Then
					Movement.Hotel = Hotel;
				EndIf;
				Movement.Company = FolioTo.Company;
				If ValueIsFilled(FolioTo.Customer) Then
					Movement.AccountingCustomer = FolioTo.Customer;
					Movement.AccountingContract = FolioTo.Contract;
				Else
					Movement.AccountingCustomer = FolioTo.Hotel.IndividualsCustomer;
					Movement.AccountingContract = FolioTo.Hotel.IndividualsContract;
				EndIf;
				Movement.GuestGroup = FolioTo.GuestGroup;
				Movement.ParentDoc = FolioTo.ParentDoc;
				
				// Resources
				Movement.Sum = vPSRow.SumInFolioToCurrency;
				
				// Attributes
				Movement.Folio = FolioTo;
				Movement.Client = FolioTo.Client;
				Movement.Room = FolioTo.Room;
				Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
				Movement.PaymentMethod = PaymentMethod;
				Movement.PaymentSection = vPSRow.PaymentSection;
				If ValueIsFilled(PaymentSection) Then
					Movement.PaymentSection = PaymentSection;
				EndIf;
				If ValueIsFilled(Movement.PaymentSection) And ValueIsFilled(Movement.PaymentSection.VATRate) Then
					Movement.VATRate = Movement.PaymentSection.VATRate;
				ElsIf ValueIsFilled(FolioTo.Company) And ValueIsFilled(FolioTo.Company.VATRate) Then
					Movement.VATRate = FolioTo.Company.VATRate;
				EndIf;
				Movement.VATSum = 0;
				If ValueIsFilled(Movement.VATRate) Then
					Movement.VATSum = cmCalculateVATSum(Movement.VATRate, Movement.Sum, Date);
				EndIf;
				
				Movement.Service = vPSRow.ChequeService;
				Movement.Price = vPSRow.ChequeServicePrice;
				Movement.Quantity = vPSRow.ChequeServiceQuantity;
			EndDo;
		Else
			// Do correction movement for the source folio   
			Movement = RegisterRecords.CustomerAccounts.Add();
			
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			
			// Dimensions
			Movement.AccountingCurrency = FolioFromCurrency;
			Movement.Hotel = FolioFrom.Hotel;
			If Not ValueIsFilled(Movement.Hotel) Then
				Movement.Hotel = Hotel;
			EndIf;
			Movement.Company = FolioFrom.Company;
			If ValueIsFilled(FolioFrom.Customer) Then
				Movement.AccountingCustomer = FolioFrom.Customer;
				Movement.AccountingContract = FolioFrom.Contract;
			Else
				Movement.AccountingCustomer = FolioFrom.Hotel.IndividualsCustomer;
				Movement.AccountingContract = FolioFrom.Hotel.IndividualsContract;
			EndIf;
			Movement.GuestGroup = FolioFrom.GuestGroup;
			If Not ValueIsFilled(FolioFrom.GuestGroup) Then
				If ValueIsFilled(Payment) And ValueIsFilled(Payment.ParentDoc) Then
					Movement.ParentDoc = Payment.ParentDoc;
					Movement.GuestGroup = Payment.ParentDoc.GuestGroup;
				EndIf;
			EndIf;
			
			// Resources
			Movement.Sum = -SumInFolioFromCurrency;
			
			// Attributes
			Movement.Folio = FolioFrom;
			Movement.Client = FolioFrom.Client;
			Movement.Room = FolioFrom.Room;
			Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
			Movement.PaymentMethod = PaymentMethod;
			Movement.PaymentSection = PaymentSection;
			If ValueIsFilled(Movement.PaymentSection) And ValueIsFilled(Movement.PaymentSection.VATRate) Then
				Movement.VATRate = Movement.PaymentSection.VATRate;
			ElsIf ValueIsFilled(FolioFrom.Company) And ValueIsFilled(FolioFrom.Company.VATRate) Then
				Movement.VATRate = FolioFrom.Company.VATRate;
			EndIf;
			Movement.VATSum = 0;
			If ValueIsFilled(Movement.VATRate) Then
				Movement.VATSum = cmCalculateVATSum(Movement.VATRate, Movement.Sum, Date);
			EndIf;
			
			// Do payment movement for the target folio   
			Movement = RegisterRecords.CustomerAccounts.Add();
			
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			
			// Dimensions
			Movement.AccountingCurrency = FolioToCurrency;
			Movement.Hotel = FolioTo.Hotel;
			If Not ValueIsFilled(Movement.Hotel) Then
				Movement.Hotel = Hotel;
			EndIf;
			Movement.Company = FolioTo.Company;
			If ValueIsFilled(FolioTo.Customer) Then
				Movement.AccountingCustomer = FolioTo.Customer;
				Movement.AccountingContract = FolioTo.Contract;
			Else
				Movement.AccountingCustomer = FolioTo.Hotel.IndividualsCustomer;
				Movement.AccountingContract = FolioTo.Hotel.IndividualsContract;
			EndIf;
			Movement.GuestGroup = FolioTo.GuestGroup;
			Movement.ParentDoc = FolioTo.ParentDoc;
			
			// Resources
			Movement.Sum = SumInFolioToCurrency;
			
			// Attributes
			Movement.Folio = FolioTo;
			Movement.Client = FolioTo.Client;
			Movement.Room = FolioTo.Room;
			Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
			Movement.PaymentMethod = PaymentMethod;
			Movement.PaymentSection = PaymentSection;
			If ValueIsFilled(Movement.PaymentSection) And ValueIsFilled(Movement.PaymentSection.VATRate) Then
				Movement.VATRate = Movement.PaymentSection.VATRate;
			ElsIf ValueIsFilled(FolioTo.Company) And ValueIsFilled(FolioTo.Company.VATRate) Then
				Movement.VATRate = FolioTo.Company.VATRate;
			EndIf;
			Movement.VATSum = 0;
			If ValueIsFilled(Movement.VATRate) Then
				Movement.VATSum = cmCalculateVATSum(Movement.VATRate, Movement.Sum, Date);
			EndIf;
		EndIf;
	EndIf;
	
	// Write movements
	RegisterRecords.CustomerAccounts.Write();
EndProcedure // PostToCustomerAccounts

// -----------------------------------------------------------------------------
Procedure PostToPayments()
	If PaymentSections.Count() > 0 Then
		vPaymentSections = PaymentSections.Unload();
		vPaymentSections.GroupBy("PaymentSection", "SumInFolioFromCurrency, SumInFolioToCurrency");
		For Each vPSRow In vPaymentSections Do
			If vPSRow.SumInFolioFromCurrency = 0 Then
				Continue;
			EndIf;
			
			// Add movement for folio from
			Movement = RegisterRecords.Payments.Add();
			
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			
			FillPropertyValues(Movement, ThisObject);
			If ValueIsFilled(Payment) And ValueIsFilled(Payment.ParentDoc) Then
				Movement.ParentDoc = Payment.ParentDoc;
			EndIf;
			
			If ValueIsFilled(FolioFrom.Hotel) Then
				Movement.Hotel = FolioFrom.Hotel;
			EndIf;
			
			vVATRate = Undefined;
			If ValueIsFilled(FolioFrom.Company) Then
				vVATRate = FolioFrom.Company.VATRate;
			EndIf;
			If ValueIsFilled(vPSRow.PaymentSection) And ValueIsFilled(vPSRow.PaymentSection.VATRate) Then
				vVATRate = vPSRow.PaymentSection.VATRate;
			EndIf;
			Movement.VATRate = vVATRate;
			
			Movement.PaymentSection = vPSRow.PaymentSection;
			
			// Dimensions
			Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
			Movement.Company = FolioFrom.Company;
			Movement.PaymentCurrency = FolioFromCurrency;
			
			// Resources
			Movement.Sum = -vPSRow.SumInFolioFromCurrency;
			Movement.VATSum = cmCalculateVATSum(vVATRate, Movement.Sum, Movement.AccountingDate);
			Movement.SumReceipt = 0;
			Movement.VATSumReceipt = 0;
			Movement.SumExpense = -Movement.Sum;
			Movement.VATSumExpense = -Movement.VATSum;
			
			// Add movement for folio to
			Movement = RegisterRecords.Payments.Add();
			
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			
			FillPropertyValues(Movement, ThisObject);
			Movement.ParentDoc = FolioTo.ParentDoc;
			
			If ValueIsFilled(FolioTo.Hotel) Then
				Movement.Hotel = FolioTo.Hotel;
			EndIf;
			
			vVATRate = Undefined;
			If ValueIsFilled(FolioTo.Company) Then
				vVATRate = FolioTo.Company.VATRate;
			EndIf;
			If ValueIsFilled(vPSRow.PaymentSection) And ValueIsFilled(vPSRow.PaymentSection.VATRate) Then
				vVATRate = vPSRow.PaymentSection.VATRate;
			EndIf;
			Movement.VATRate = vVATRate;
			
			Movement.PaymentSection = vPSRow.PaymentSection;
			
			// Dimensions
			Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
			Movement.Company = FolioTo.Company;
			Movement.PaymentCurrency = FolioToCurrency;
			
			// Resources
			Movement.Sum = vPSRow.SumInFolioToCurrency;
			Movement.VATSum = cmCalculateVATSum(vVATRate, Movement.Sum, Movement.AccountingDate);
			Movement.SumReceipt = Movement.Sum;
			Movement.VATSumReceipt = Movement.VATSum;
			Movement.SumExpense = 0;
			Movement.VATSumExpense = 0;
		EndDo;
	ElsIf SumInFolioFromCurrency <> 0 Then
		// Add movement for folio from
		Movement = RegisterRecords.Payments.Add();
		
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		FillPropertyValues(Movement, ThisObject);
		If ValueIsFilled(Payment) And ValueIsFilled(Payment.ParentDoc) Then
			Movement.ParentDoc = Payment.ParentDoc;
		EndIf;
		
		If ValueIsFilled(FolioFrom.Hotel) Then
			Movement.Hotel = FolioFrom.Hotel;
		EndIf;
		
		vVATRate = Undefined;
		If ValueIsFilled(FolioFrom.Company) Then
			vVATRate = FolioFrom.Company.VATRate;
		EndIf;
		If ValueIsFilled(PaymentSection) And ValueIsFilled(PaymentSection.VATRate) Then
			vVATRate = PaymentSection.VATRate;
		EndIf;
		Movement.VATRate = vVATRate;
		
		// Dimensions
		Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		Movement.Company = FolioFrom.Company;
		Movement.PaymentCurrency = FolioFromCurrency;
		
		// Resources
		Movement.Sum = -SumInFolioFromCurrency;
		Movement.VATSum = cmCalculateVATSum(vVATRate, Movement.Sum, Movement.AccountingDate);
		Movement.SumReceipt = 0;
		Movement.VATSumReceipt = 0;
		Movement.SumExpense = -Movement.Sum;
		Movement.VATSumExpense = -Movement.VATSum;
		
		// Add movement for folio to
		Movement = RegisterRecords.Payments.Add();
		
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		FillPropertyValues(Movement, ThisObject);
		Movement.ParentDoc = FolioTo.ParentDoc;
		
		If ValueIsFilled(FolioTo.Hotel) Then
			Movement.Hotel = FolioTo.Hotel;
		EndIf;
		
		vVATRate = Undefined;
		If ValueIsFilled(FolioTo.Company) Then
			vVATRate = FolioTo.Company.VATRate;
		EndIf;
		If ValueIsFilled(PaymentSection) And ValueIsFilled(PaymentSection.VATRate) Then
			vVATRate = PaymentSection.VATRate;
		EndIf;
		Movement.VATRate = vVATRate;
		
		// Dimensions
		Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		Movement.Company = FolioTo.Company;
		Movement.PaymentCurrency = FolioToCurrency;
		
		// Resources
		Movement.Sum = SumInFolioToCurrency;
		Movement.VATSum = cmCalculateVATSum(vVATRate, Movement.Sum, Movement.AccountingDate);
		Movement.SumReceipt = Movement.Sum;
		Movement.VATSumReceipt = Movement.VATSum;
		Movement.SumExpense = 0;
		Movement.VATSumExpense = 0;
	EndIf;
	
	RegisterRecords.Payments.Write();
EndProcedure // PostToPayments

// -----------------------------------------------------------------------------
Procedure FillHotelProductPaymentDate()
	If ValueIsFilled(FolioTo) Then
		If ValueIsFilled(FolioTo.HotelProduct) And Not FolioTo.HotelProduct.IsFolder Then
			If Not ValueIsFilled(FolioTo.HotelProduct.PaymentDate) Then
				vHPObj = FolioTo.HotelProduct.GetObject();
				vPaymentMethod = Undefined;
				vHPObj.PaymentDate = vHPObj.pmGetHotelProductPaymentDate(vPaymentMethod);
				If ValueIsFilled(vPaymentMethod) Then
					vHPObj.PaymentMethod = vPaymentMethod;
				EndIf;
				vHPObj.Write();
			EndIf;
		EndIf;
		If ValueIsFilled(FolioTo.ParentDoc) And 
		   (TypeOf(FolioTo.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(FolioTo.ParentDoc) = Type("DocumentRef.Reservation")) Then
			If ValueIsFilled(FolioTo.ParentDoc.HotelProduct) And Not FolioTo.ParentDoc.HotelProduct.IsFolder Then
				If Not ValueIsFilled(FolioTo.ParentDoc.HotelProduct.PaymentDate) Then
					vHPObj = FolioTo.ParentDoc.HotelProduct.GetObject();
					vPaymentMethod = Undefined;
					vHPObj.PaymentDate = vHPObj.pmGetHotelProductPaymentDate(vPaymentMethod);
					If ValueIsFilled(vPaymentMethod) Then
						vHPObj.PaymentMethod = vPaymentMethod;
					EndIf;
					If ValueIsFilled(vHPObj.PaymentDate) Then
						vHPObj.Write();
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillHotelProductPaymentDate

// -----------------------------------------------------------------------------
Procedure PostToFOChartOfAccounts()
	vGL = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
	If Not ValueIsFilled(vGL.Type) Or Not ValueIsFilled(vGL.AccountType) Then
		Return;
	EndIf;
	
	// Get service account
	vPostingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
	If ValueIsFilled(FolioFrom) And ValueIsFilled(FolioFrom.FinancialAccount) Then
		vPostingAccount = FolioFrom.FinancialAccount;
	EndIf;
	vCorrespondingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
	If ValueIsFilled(FolioTo) And ValueIsFilled(FolioTo.FinancialAccount) Then
		vCorrespondingAccount = FolioTo.FinancialAccount;
	EndIf;
	
	// Postings currency
	vAccountCurrency = FolioFromCurrency;
	vPostingAmount = SumInFolioFromCurrency;
	
	vReverseSign = False;
	If vPostingAmount < 0 Then
		vReverseSign = True;
		
		vPostingAmount = -vPostingAmount;
	EndIf;
	
	If vPostingAmount <> 0 Then
		// Create movement for this payment
		PostingMovement = Undefined;
		If vReverseSign Then
			PostingMovement = RegisterRecords.PostingsFO.AddCredit();
		Else
			PostingMovement = RegisterRecords.PostingsFO.AddDebit();
		EndIf;
		
		PostingMovement.Active = True;
		
		PostingMovement.Account = vPostingAccount;
		If vPostingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger Then
			PostingMovement.ExtDimensions.Folio = FolioFrom;
		EndIf;
		PostingMovement.CorrAccount = vCorrespondingAccount;
		
		PostingMovement.Amount = vPostingAmount;
		PostingMovement.GrosAmount = 0;
		
		PostingMovement.Description = TrimAll(ParentDoc);
		
		PostingMovement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		PostingMovement.FODate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		PostingMovement.ServiceDate = '00010101';
		PostingMovement.Days = 0;
					
		PostingMovement.ParentDoc = ParentDoc;
		
		PostingMovement.Room = FolioTo.Room;
		PostingMovement.Resource = Undefined;
		
		PostingMovement.Service = Undefined;
		PostingMovement.PaymentMethod = PaymentMethod;
		PostingMovement.AccountingCustomer = Undefined;
			
		PostingMovement.AccountGroup = vPostingAccount.AccountGroup;
		PostingMovement.AccountType = vPostingAccount.AccountType;
		PostingMovement.Department = vPostingAccount.Department;
		PostingMovement.DiscountType = vPostingAccount.DiscountType;
		PostingMovement.ServiceType = vPostingAccount.ServiceType;
		
		PostingMovement.Hotel = Hotel;
		If ValueIsFilled(FolioFrom.Hotel) Then
			PostingMovement.Hotel = FolioFrom.Hotel;
		EndIf;
		PostingMovement.Company = FolioFrom.Company;
		PostingMovement.Currency = vAccountCurrency;
		
		PostingMovement.Discount = 0;
		PostingMovement.DiscountAmount = 0;
		
		PostingMovement.VATAmount = 0;
		PostingMovement.VATRate = Undefined;
		
		PostingMovement.POSTicket = "";
		PostingMovement.Invoice = Undefined;
		
		PostingMovement.Recorder = Ref;
		PostingMovement.Author = SessionParameters.CurrentUser;
		
		// Create guest ledger debit movement
		If vReverseSign Then
			PostingMovement = RegisterRecords.PostingsFO.AddDebit();
		Else
			PostingMovement = RegisterRecords.PostingsFO.AddCredit();
		EndIf;
					
		PostingMovement.Active = True;
		
		PostingMovement.Account = vCorrespondingAccount;
		If vCorrespondingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger Then
			PostingMovement.ExtDimensions.Folio = FolioTo;
		EndIf;
		PostingMovement.CorrAccount = vPostingAccount;
		
		PostingMovement.Amount = vPostingAmount;
		PostingMovement.GrosAmount = 0;
		
		PostingMovement.Description = "Advance clearance: " + TrimAll(ParentDoc);
		
		PostingMovement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		PostingMovement.FODate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		PostingMovement.ServiceDate = '00010101';
		PostingMovement.Days = 0;
					
		PostingMovement.ParentDoc = ParentDoc;
		
		PostingMovement.Room = FolioTo.Room;
		PostingMovement.Resource = Undefined;
		
		PostingMovement.Service = Undefined;
		PostingMovement.PaymentMethod = PaymentMethod;
		PostingMovement.AccountingCustomer = FolioTo.Customer;
			
		PostingMovement.AccountGroup = vCorrespondingAccount.AccountGroup;
		PostingMovement.AccountType = vCorrespondingAccount.AccountType;
		PostingMovement.Department = vCorrespondingAccount.Department;
		PostingMovement.DiscountType = vCorrespondingAccount.DiscountType;
		PostingMovement.ServiceType = vCorrespondingAccount.ServiceType;
		
		PostingMovement.Hotel = Hotel;
		If ValueIsFilled(FolioTo.Hotel) Then
			PostingMovement.Hotel = FolioTo.Hotel;
		EndIf;
		PostingMovement.Company = FolioTo.Company;
		PostingMovement.Currency = vAccountCurrency;
		
		PostingMovement.Discount = 0;
		PostingMovement.DiscountAmount = 0;
		
		PostingMovement.VATAmount = 0;
		PostingMovement.VATRate = Undefined;
		
		PostingMovement.POSTicket = "";
		PostingMovement.Invoice = Undefined;
		
		PostingMovement.Recorder = Ref;
		PostingMovement.Author = SessionParameters.CurrentUser;
		
		RegisterRecords.PostingsFO.Write();
	EndIf;
EndProcedure // PostToFOChartOfAccounts

// -----------------------------------------------------------------------------
Procedure FillByFolio(pFolio)
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	
	FolioFrom = pFolio;
	
	If ValueIsFilled(FolioFrom.Hotel) Then
		If Hotel <> FolioFrom.Hotel Then
			Hotel = FolioFrom.Hotel;
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	
	ParentDoc = FolioFrom.ParentDoc;
	If ValueIsFilled(Hotel) And (Hotel.SplitFolioBalanceByPaymentSections Or Hotel.SplitFolioBalanceByServicesAndPrices) Then
		PaymentSection = Catalogs.PaymentSections.EmptyRef();
	Else
		PaymentSection = FolioFrom.PaymentSection;
	EndIf;
	
	FolioFromCurrency = FolioFrom.FolioCurrency;
	FolioFromCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioFromCurrency, ExchangeRateDate);
	
	// Get parameters for advance and advance settlement
	vAdvancePaymentSection = Undefined;
	vMultipleAdvanceSectionsAreUsed = False;
	vAdvancePaymentSections = New ValueList();
	vAdvanceSettlementPaymentMethod = Undefined;
	cmFillAdvanceAndAdvanceSettlementParameters(Hotel, Author, vAdvancePaymentSection, vAdvanceSettlementPaymentMethod, vMultipleAdvanceSectionsAreUsed, vAdvancePaymentSections);
	
	vFolioBalance = 0;
	PaymentSections.Clear();
	If ValueIsFilled(Hotel) Then
		If Hotel.SplitFolioBalanceByPaymentSections Then
			vPaymentSectionBalances = FolioFrom.GetObject().pmGetPaymentSectionBalances('39991231235959');
			For Each vPSBalancesRow In vPaymentSectionBalances Do
				If vPSBalancesRow.SumBalance < 0 Then
					vPSRow = PaymentSections.Add();
					vPSRow.PaymentSection = vPSBalancesRow.PaymentSection;
					vPSRow.SumInFolioFromCurrency = -vPSBalancesRow.SumBalance;
					vPSRow.SumInFolioToCurrency = Round(cmConvertCurrencies(vPSRow.SumInFolioFromCurrency, FolioFromCurrency, FolioFromCurrencyExchangeRate, FolioToCurrency, FolioToCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				EndIf;
			EndDo;
		ElsIf Hotel.SplitFolioBalanceByServicesAndPrices Then
			vServicesBalances = FolioFrom.GetObject().pmGetChequeServicesBalances('39991231235959', FolioFrom.Hotel, , Date);
			If vMultipleAdvanceSectionsAreUsed Then
				PaymentSection = Undefined;
				PaymentSections.Clear();
				For Each vAdvancePaymentSectionsItem In vAdvancePaymentSections Do
					vCurAdvancePaymentSection = vAdvancePaymentSectionsItem.Value;
					vPSRow = PaymentSections.Find(vCurAdvancePaymentSection, "PaymentSection");
					If vPSRow = Undefined Then
						vPSRow = PaymentSections.Add();
						vPSRow.PaymentSection = vCurAdvancePaymentSection;
						vPSRow.ChequeService = Catalogs.Services.EmptyRef();
						vPSRow.ChequeServicePrice = 0;
						vPSRow.ChequeServiceQuantity = 0;
					EndIf;
					For Each vSrvBalancesRow In vServicesBalances Do
						If vSrvBalancesRow.SumBalance < 0 And Not ValueIsFilled(vSrvBalancesRow.ChequeService) Then
							If vPSRow.PaymentSection = vSrvBalancesRow.PaymentSection Then
								vPSRow.SumInFolioFromCurrency = vPSRow.SumInFolioFromCurrency - vSrvBalancesRow.SumBalance;
								vPSRow.SumInFolioToCurrency = Round(cmConvertCurrencies(vPSRow.SumInFolioFromCurrency, FolioFromCurrency, FolioFromCurrencyExchangeRate, FolioToCurrency, FolioToCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
							EndIf;
						EndIf;
					EndDo;
				EndDo;
			Else
				For Each vSrvBalancesRow In vServicesBalances Do
					If vSrvBalancesRow.SumBalance < 0 Then
						vPSRow = PaymentSections.Add();
						If ValueIsFilled(vSrvBalancesRow.ChequeService) And ValueIsFilled(vSrvBalancesRow.ChequeService) Then
							vPSRow.PaymentSection = vSrvBalancesRow.ChequeService.PaymentSection;
						Else
							vPSRow.PaymentSection = vSrvBalancesRow.PaymentSection;
						EndIf;
						vPSRow.ChequeService = vSrvBalancesRow.ChequeService;
						vPSRow.ChequeServicePrice = vSrvBalancesRow.ChequeServicePrice;
						vPSRow.ChequeServiceQuantity = -vSrvBalancesRow.ChequeServiceQuantityBalance;
						vPSRow.SumInFolioFromCurrency = -vSrvBalancesRow.SumBalance;
						vPSRow.SumInFolioToCurrency = Round(cmConvertCurrencies(vPSRow.SumInFolioFromCurrency, FolioFromCurrency, FolioFromCurrencyExchangeRate, FolioToCurrency, FolioToCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					EndIf;
				EndDo;
			EndIf;
		Else
			vFolioBalance = FolioFrom.GetObject().pmGetBalance('39991231235959');
			SumInFolioFromCurrency = 0;
			If vFolioBalance < 0 Then
				SumInFolioFromCurrency = -vFolioBalance;
				SumInFolioToCurrency = Round(cmConvertCurrencies(SumInFolioFromCurrency, FolioFromCurrency, FolioFromCurrencyExchangeRate, FolioToCurrency, FolioToCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
			EndIf;
		EndIf;
		If Hotel.SplitFolioBalanceByPaymentSections Or 
		   Hotel.SplitFolioBalanceByServicesAndPrices Then
			If ValueIsFilled(vAdvancePaymentSection) And Not vMultipleAdvanceSectionsAreUsed Then
				i = 0;
				While i < PaymentSections.Count() Do
					vPSRow = PaymentSections.Get(i);
					If Not ValueIsFilled(vPSRow.PaymentSection) Or ValueIsFilled(vPSRow.PaymentSection) And vPSRow.PaymentSection.ChequeItemType <> Enums.ChequeItemTypes.Payment Then
						PaymentSections.Delete(i);
					Else
						vAdvancePaymentSection = vPSRow.PaymentSection;
						i = i + 1;
					EndIf;
				EndDo;
				PaymentSection = vAdvancePaymentSection;
				i = 0;
				While i < PaymentSections.Count() Do
					vPSRow = PaymentSections.Get(i);
					If vPSRow.PaymentSection <> PaymentSection Then
						PaymentSections.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
			EndIf;
			SumInFolioFromCurrency = PaymentSections.Total("SumInFolioFromCurrency");
			SumInFolioToCurrency = PaymentSections.Total("SumInFolioToCurrency");
		EndIf;
	EndIf;
EndProcedure // FillByFolio

// -----------------------------------------------------------------------------
Function pmIsPrepayment()
	// Get folio balance after payment
	vFolioBalance = FolioTo.GetObject().pmGetBalance();
	If vFolioBalance = 0 Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // pmIsPrepayment

// -----------------------------------------------------------------------------
Procedure TransferGiftCertificateBalance(pCancel)
	vDoc = pmGetBonusesPayment();
	Try
		If vDoc.IsEmpty() Then
			vBonusesPaymentObj = Documents.BonusesPayment.CreateDocument();
		Else
			vBonusesPaymentObj = vDoc.GetObject();
		EndIf;
		vBonusesPaymentObj.Fill(ThisObject.Ref); 
		vBonusesPaymentObj.Write(DocumentWriteMode.Posting);
	Except
		pCancel = True;
		Raise BriefErrorDescription(ErrorInfo());
	EndTry;
EndProcedure // ActivateGiftCertificate

// -----------------------------------------------------------------------------
Function GetDiscountCardByFolio(pFolio)
	vDiscountCards = Catalogs.DiscountCards.EmptyRef();
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	DiscountCards.Ref AS Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	NOT DiscountCards.DeletionMark
	|	AND DiscountCards.Folio = &qFolio";
	vQuery.SetParameter("qFolio",pFolio);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		vDiscountCards = vResult.Get(0).Ref;		
	EndIf;
	Return vDiscountCards;
EndFunction // GetDiscountCardByFolio

#EndRegion
