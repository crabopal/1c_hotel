
#Region Variables

Var WasPosted;

#EndRegion

#Region EventHandlers

 // -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not ValueIsFilled(PaymentMethod) Then
		pCancel = True;
		Return;
	EndIf;
	
	vIsGifCardReturn = ValueIsFilled(DiscountCard) And DiscountCard.LoyaltyType = Enums.LoyaltyType.Certificate And 
	                   Not (PaymentMethod.IsByBonuses Or PaymentMethod.IsByGiftCertificate);
	
	// 1. Post to Folio payments
	PostToFolioPayments();
	
	// 2. Post to Accounts
	If Not PaymentMethod.IsCloseToTheRoom And Not PaymentMethod.IsCloseToTheFolio Then
		PostToAccounts(vIsGifCardReturn);
	EndIf;
	
	// 3. Post to Payments
	PostToPayments();
	
	// 4. Post to Close of cash register day debits
	If ValueIsFilled(CashRegister) And ValueIsFilled(PaymentMethod) Then
		If PaymentMethod.BookByCashRegister Then
			PostToCashRegisterDailyReceipts();
			// Post to cash in cash registers
			If PaymentMethod.IsByCash Then
				PostToCashInCashRegisters();
			EndIf;
		EndIf;
	EndIf;
	
	// Actions taken if this is not transfer to the city ledger
	If PaymentMethod <> Catalogs.PaymentMethods.Settlement And Not PaymentMethod.IsCloseToTheRoom And Not PaymentMethod.IsCloseToTheFolio AND Not StatisticsOnly Then
		// 5. Post to Customer accounts
		If Not vIsGifCardReturn Then
			PostToCustomerAccounts();
		EndIf;
		
		If Not vIsGifCardReturn Then
			// 6. Post to Payment services
			If Hotel.DoPaymentsDistributionToServices Then
				PostToPaymentServices();
			EndIf;
			
			// 7. Repost settlements if any
			pmRepostSettlements();
		EndIf;
		
		// 8. Write off bonuses and process gift certificates (obsolete code)
		WriteOffBonuses();
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.ReportingCurrency) And 
		   ValueIsFilled(PaymentMethod) And Not IsBlankString(GiftCertificate) Then
			PostToGiftCertificates();
		EndIf;
		
		// 9. Write off bonuses or certificate
		If Not ValueIsFilled(PaymentMethod.ExternalSystem) And Not vIsGifCardReturn And (PaymentMethod.IsByBonuses Or PaymentMethod.IsByGiftCertificate) And ValueIsFilled(DiscountCard) Then
			vMessage = "";
			pCancel	= PostBonusesPayment(vMessage);
			If pCancel	Then
				Raise vMessage; 
			EndIf;
		EndIf;
		
		// 10. Return certificate
		If vIsGifCardReturn Then
			ReturnGiftCertificate(pCancel);
		EndIf;
		
		// 11. Send return SMS
		If Not WasPosted Then
			vMessageDeliveryError = "";
			If Not SMS.SendPaymentMessage(Payer, GuestGroup, ParentDoc, cmFormatSum(Sum, PaymentCurrency), PaymentMethod, Ref, vMessageDeliveryError) Then
				WriteLogEvent(NStr("en='Document.MessageDelivery';ru='Документ.РассылкаСообщений';de='Document.MessageDelivery'"), EventLogLevel.Warning, Metadata(), Ref, vMessageDeliveryError);
				tcCommonFunctionOnClientServer.TextMessage(vMessageDeliveryError, MessageStatus.Attention);
			EndIf;
		EndIf;
	Else
		If PaymentMethod = Catalogs.PaymentMethods.Settlement Then
			// 10. Return certificate
			If vIsGifCardReturn Then
				ReturnGiftCertificate(pCancel);
			EndIf;
		EndIf;
		
		// Repost settlements if any
		pmRepostSettlements();
	EndIf;

	// 12. Create invoice if necessary
	If Not PaymentMethod.IsCloseToTheRoom And Not PaymentMethod.IsCloseToTheFolio Then
		If ValueIsFilled(Folio) And ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
			vInvoice = pmGetReturnInvoice();
			If Not ValueIsFilled(vInvoice) Then
				If Not vIsGifCardReturn Then
					// Check if this is advance payment
					vIsPrepayment = pmIsPrepayment();
				Else
					vIsPrepayment = True;
				EndIf;
				If Not vIsPrepayment Then
					// Generate invoice
					If PaymentMethod = Catalogs.PaymentMethods.Settlement And ValueIsFilled(Payment) Then
						If TypeOf(Payment) <> Type("DocumentRef.DepositTransfer") And Payment.Sum <> Sum Then
							Raise NStr("en='Amount to return should be the same as payment amount!'; ru='Сумма возврата должна быть равна сумме платежа!'; de='Betrag zur Rückgabe sollte die gleiche wie Zahlungsbetrag sein!'");
						Else
							vInvRef = GetInvoiceForPayment();
							If ValueIsFilled(vInvRef) Then
								If vInvRef.Services.Count() = 0 Then
									vIsPrepayment = True;
								Else
									vInvObj = vInvRef.Copy();
									vInvObj.Date = Date + 1;
									vInvObj.pmFillAuthorAndDate();
									For Each vSrvRow In vInvObj.Services Do
										vSrvRow.Quantity = -vSrvRow.Quantity;
										vSrvRow.Sum = -vSrvRow.Sum;
										vSrvRow.VATSum = -vSrvRow.VATSum;
										vSrvRow.VATCommissionSum = -vSrvRow.VATCommissionSum;
									EndDo;
									vInvObj.Sum = -vInvObj.Sum;
									vInvObj.SumDue = -vInvObj.SumDue;
									vInvObj.VATSum = -vInvObj.VATSum;
									For Each vPDRow In vInvObj.PaymentDocuments Do
										If vPDRow.PaymentDoc = Payment Then
											vPDRow.PaymentDoc = Ref;
										EndIf;
									EndDo;
									vInvObj.IsChecked = vInvRef.IsChecked;
									vInvObj.Write(DocumentWriteMode.Posting);
								EndIf;
							Else
								Raise NStr("en='Failed to find invoice to be canceled!'; ru='Не удалось найти акт, который должен быть отменен!'; de='Konnte keine Rechnung finden, die gelöscht werden muss!'");
							EndIf;
						EndIf;
					Else
						vInvObj = Documents.Settlement.CreateDocument();
						vInvObj.Date = Date + 1;
						vInvObj.Fill(Ref);
						If vInvObj.Services.Count() = 0 Then
							vIsPrepayment = True;
						Else
							vInvObj.Write(DocumentWriteMode.Posting);
						EndIf;
					EndIf;
				EndIf;					
				If vIsPrepayment Then
					// Generate proforma invoice
					vInvObj = Documents.ProformaInvoice.CreateDocument();
					vInvObj.Date = Date + 1;
					vInvObj.Fill(Ref);
					vInvObj.Write(DocumentWriteMode.Posting);
					// Save proforma invoice reference to the return
					Invoice = vInvObj.Ref;
				EndIf;					
			EndIf;					
		EndIf;
	EndIf;
	
	// Save data if there were changes
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
	
	// 13. Post to Invoice accounts
	If PaymentMethod <> Catalogs.PaymentMethods.Settlement And Not PaymentMethod.IsCloseToTheRoom And Not PaymentMethod.IsCloseToTheFolio Then
		If Not vIsGifCardReturn Then
			PostToInvoiceAccounts();
		EndIf;
	EndIf;
	
	// 14. Post to FO chart of accounts
	PostToFOChartOfAccounts();     
	
	// 15. Post to labeled goods    
	PostToLabeledGoods();
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Folio") Then
			FillByFolio(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Payment") Then
			FillByPayment(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.DepositTransfer") Then
			FillByDepositTransfer(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Order") Then
			FillByOrder(pBase);
		EndIf;
	EndIf;
	pmFillContactsToOFD();
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsBlankString(Number) Then
		SetNewNumber();
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
		// Expense bonuses
		If (PaymentMethod.IsByBonuses Or PaymentMethod.IsByGiftCertificate) And Not ValueIsFilled(DiscountCard) Then
			pCancel = True;
			vMessageTemplete = Nstr("en = 'To return %1, you must specify a %2!'; de = 'Um %1 zurückzugeben, müssen Sie eine %2 angeben!'; ru = 'Для возврата %1 необходимо указать %2!'");
			vDiscType = ?(PaymentMethod.IsByBonuses,Nstr("en = 'bonuses'; de = 'Boni'; ru = 'бонусов'"),Nstr("en = 'money to certificate'; de = 'Geld auf Ihre Geschenkkarte'; ru = 'денег на сертификат'"));
			vAction = ?(PaymentMethod.IsByBonuses,Nstr("en = 'loyalty card'; de = 'Bonikarte'; ru = 'карту лояльности'"),Nstr("en = 'gift card'; de = 'Geschenkkarte'; ru = 'подарочную карту'"));
			vMessage = StrTemplate(vMessageTemplete, vDiscType, vAction);
		EndIf;
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, vMessage);
			Message = New UserMessage();
			Message.Text = vMessage;
			Message.Field = "DiscountCard";
			Message.DataKey = Ref; 
			Message.Message();
			Return;
		EndIf;
	Else
		If DeletionMark Then
			// User activity history   
			vEventDescription = StrTemplate(NStr("en = 'Set document deletion mark return: %1, %2, %3'; 
												 |de = 'Legen Sie die Rückgabe der Löschmarkierung für das Dokument fest: %1, %2, %3'; 
												 |ru = 'Установка отметки удаления возврата: %1, %2, %3'"), TrimAll(Payer), cmFormatSum(Sum, PaymentCurrency), TrimAll(Ref));  
			vParentDoc = Ref;
			If ValueIsFilled(ParentDoc) Then
				vParentDoc = ParentDoc;
			EndIf;	
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel);
		EndIf;
	EndIf;
	WasPosted = Posted;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// User activity history   
	vEventDescription = StrTemplate(NStr("en = 'Document deletion: %1, %2, %3'; 
										 |de = 'Unmittelbare Löschung: %1, %2, %3'; 
										 |ru = 'Непосредственное удаление возврата: %1, %2, %3'"), TrimAll(Payer), cmFormatSum(Sum, PaymentCurrency), TrimAll(Ref));  
	vParentDoc = Ref;
	If ValueIsFilled(ParentDoc) Then
		vParentDoc = ParentDoc;
	EndIf;	
	InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel);
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Company) And Company.UsePrefixForPayments And Not IsBlankString(Company.Prefix) Then
		vPrefix = TrimAll(Company.Prefix);
	ElsIf ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		If ValueIsFilled(SessionParameters.CurrentHotel.Company) And SessionParameters.CurrentHotel.Company.UsePrefixForPayments And Not IsBlankString(SessionParameters.CurrentHotel.Company.Prefix) Then
			vPrefix = TrimAll(SessionParameters.CurrentHotel.Company.Prefix);
		Else
			vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	AccountingDate = '00010101';
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
		AccountingDate = Hotel.AccountingDate;
	EndIf;
	ExternalCode = "";
	GiftCertificate = "";
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
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
Procedure OnWrite(pCancel)  
	If DataExchange.Load Then
		Return;
	EndIf;
	If DeletionMark Then
		If ValueIsFilled(DiscountCard) Then
			vDocRef = GetBonusesPayment();
			If ValueIsFilled(vDocRef) And Not vDocRef.DeletionMark Then
				vDocRef.GetObject().SetDeletionMark(True);
			EndIf;
		EndIf;
		If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
			vInvRef = pmGetReturnInvoice();
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
	If ValueIsFilled(Folio) And ValueIsFilled(Folio.PaymentMethod) And 
	   Folio.PaymentMethod.IsByBankTransfer Then
		vSettlements = Folio.GetObject().pmGetAllFolioSettlements();
		For Each vSettlementsRow In vSettlements Do
			vSettlementObj = vSettlementsRow.Document.GetObject();
			vSettlementObj.pmPostToAccountsAndPayments();
		EndDo;
	EndIf;
EndProcedure // pmRepostSettlements

// -----------------------------------------------------------------------------
//  Check document attributes
//
// Parameters:
//  pMessage		 - String	 - Error string
//  pAttributeInErr	 - String	 - Attributes with error
// 
// Returns:
//  Boolean - Has errors
//
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
	If Not ValueIsFilled(Company) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Фирма> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Company> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Company> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Company", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Folio) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Лицевой счет> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Folio", pAttributeInErr);
	Else
		If Folio.DeletionMark Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "<Лицевой счет> помечен на удаление!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Folio> is marked for deletion!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Folio> is marked for deletion!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Folio", pAttributeInErr);
		EndIf;
	EndIf;
	If Not ValueIsFilled(PaymentMethod) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Способ оплаты> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Payment method> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Payment method> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
	ElsIf PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement And Sum <> 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Итог по возврату зачета аванса должен быть равен 0!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "The total for the advance return settlement must be 0!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Der Gesamtbetrag für den Vorausreturnsbetrag Begleichung muss 0 sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Sum", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(PaymentCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта платежа> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Payment currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Payment currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "PaymentCurrency", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ExchangeRateDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата курса> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ExchangeRateDate", pAttributeInErr);
	EndIf;
	If ValueIsFilled(Hotel) And ValueIsFilled(PaymentMethod) And PaymentMethod.BookByCashRegister Then
		If Not cmCheckUserPermissions("HavePermissionToPostPaymentsWithEmptyPaymentSections") Then
			If Not Hotel.SplitFolioBalanceByPaymentSections AND Not Hotel.SplitFolioBalanceByServicesAndPrices Then
				If Not ValueIsFilled(PaymentSection) Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Не указана кассовая секция (отдел)!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "<Payment section> attribute should be filled!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "<Payment section> attribute should be filled!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "PaymentSection", pAttributeInErr);
				EndIf;
			Else
				For Each vPSRow In PaymentSections Do
					If vPSRow.Sum > 0 And Not ValueIsFilled(vPSRow.PaymentSection) Then
						vHasErrors = True; 
						vMsgTextRu = vMsgTextRu + "В строке " + Format(vPSRow.LineNumber, "ND=4; NFD=0; NG=") + " не указана кассовая секция (отдел)!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "<Payment section> attribute should be filled in row " + Format(vPSRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "<Payment section> attribute should be filled in row " + Format(vPSRow.LineNumber, "ND=4; NFD=0; NG=") + "!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "PaymentSection", pAttributeInErr);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(PaymentMethod) Then
		If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
			If Not SessionParameters.CurrentWorkstation.HasConnectionToCreditCardsProcessingSystem Or 
			   PaymentMethod.ExternalBankTerminalIsUsed Then
				If PaymentMethod.AuthorizationCodeIsRequired And IsBlankString(AuthorizationCode) Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "При возврате на кредитную карту должен быть введен реквизит <Код авторизации>!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "<Authorization code> attribute should be filled for credit card return!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "<Authorization code> attribute should be filled for credit card return!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "AuthorizationCode", pAttributeInErr);
				EndIf;
				If PaymentMethod.ReferenceCodeIsRequired And IsBlankString(ReferenceNumber) Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "При возврате на кредитную карту должен быть введен реквизит <Референс номер>!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "<Reference number> attribute should be filled for credit card return!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "<Reference number> attribute should be filled for credit card return!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "ReferenceNumber", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		If Not cmCheckUserPermissions("HavePermissionToDoCashAndCreditCardPaymentsWithoutCashRegister") Then
			If PaymentMethod.BookByCashRegister Then
				If Not ValueIsFilled(CashRegister) Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Реквизит <ККМ> должен быть заполнен!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "<Cash register> attribute should be filled!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "<Cash register> attribute should be filled!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "CashRegister", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If Sum < 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Для оформления оплаты необходимо использовать документ ""Платеж""!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "Use ""Payment"" document to get money!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Use ""Payment"" document to get money!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Sum", pAttributeInErr);
	ElsIf PaymentMethod <> Catalogs.PaymentMethods.AdvanceSettlement Then
		For Each vPSRow In PaymentSections Do
			If vPSRow.Sum < 0 Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Для оформления оплаты необходимо использовать документ ""Платеж""!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Use ""Payment"" document to get money!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Use ""Payment"" document to get money!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "PaymentSections", pAttributeInErr);
			EndIf;
		EndDo;
	ElsIf PaymentMethod = Catalogs.PaymentMethods.Settlement And ValueIsFilled(Hotel) And Not cmCheckUserPermissions("HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios") And 
	     (Not ValueIsFilled(AccountingCustomer) Or ValueIsFilled(AccountingCustomer) And AccountingCustomer = Hotel.IndividualsCustomer) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Изменять долг по лицевому счету можно только, если указан контрагент!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "You can not move city ledger amount to folio for unspecified customer!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Sie können den City-Ledger betrag für einzelne Kunden nicht nach Folio verschieben!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCustomer", pAttributeInErr);
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToReturnPayments") Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Нет прав на оформление возвратов!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "You do not have rights to return payments!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "You do not have rights to return payments!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
	EndIf;
	If ValueIsFilled(Payment) And Not CorrectionOfIncorrectCheque Then
		If Not cmCheckUserPermissions("HavePermissionToReturnBasedOnFolio") Then
			If ValueIsFilled(PaymentMethod) And ValueIsFilled(Payment.PaymentMethod) Then
				If Payment.PaymentMethod.IsByCash And Not PaymentMethod.IsByCash Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Возврат можно оформить только наличными!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Return could be done by cash only!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Return could be done by cash only!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
				ElsIf Payment.PaymentMethod.IsByCreditCard And Not PaymentMethod.IsByCreditCard Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Возврат можно оформить только на кредитную карту!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Return could be done by credit card only!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Return could be done by credit card only!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
				ElsIf Payment.PaymentMethod.IsByBankTransfer And Not PaymentMethod.IsByBankTransfer Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Возврат можно оформить только банковским платежом!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Return could be done by bank transfer only!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Return could be done by bank transfer only!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	vGiftCertificateNotFound = False;
	If ValueIsFilled(PaymentMethod) And PaymentMethod.IsByGiftCertificate Then
		If IsBlankString(GiftCertificate) And Not (ValueIsFilled(DiscountCard) And DiscountCard.LoyaltyType = Enums.LoyaltyType.Certificate) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Подарочный сертификат не указан!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Gift certificate is not filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Gift certificate is not filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "GiftCertificate", pAttributeInErr);
		Else
			// Try to find gift certificate
			If Not IsBlankString(GiftCertificate) And Not cmGiftCertificateExists(Hotel, GiftCertificate) Then
				vGiftCertificateNotFound = True;
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Подарочный сертификат не найден!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Gift certificate is not found!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Gift certificate is not found!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "GiftCertificate", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If Not Posted And ValueIsFilled(Hotel) And ValueIsFilled(Hotel.ReportingCurrency) And 
	   ValueIsFilled(PaymentMethod) And Not PaymentMethod.IsByGiftCertificate And 
	   Not IsBlankString(GiftCertificate) And Not vGiftCertificateNotFound Then
		vReturnAmount = Round(cmConvertCurrencies(Sum, PaymentCurrency, PaymentCurrencyExchangeRate, Hotel.ReportingCurrency, , ExchangeRateDate, Hotel), 2);
		vGiftCertificateBalance = cmGetGiftCertificateBalance(Hotel, GiftCertificate, Date);
		If vGiftCertificateBalance <= 0 Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Подарочный сертификат уже использован!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Gift certificate is already being used!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Gift certificate is already being used!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "GiftCertificate", pAttributeInErr);
		ElsIf vReturnAmount > vGiftCertificateBalance Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Сумма возврата превышает остаток по подарочному сертификату (" + cmFormatSum(vGiftCertificateBalance, Hotel.ReportingCurrency) + ")!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Return amount is greater then gift certificate balance (" + cmFormatSum(vGiftCertificateBalance, Hotel.ReportingCurrency) + ")!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Return amount is greater then gift certificate balance (" + cmFormatSum(vGiftCertificateBalance, Hotel.ReportingCurrency) + ")!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Sum", pAttributeInErr);
		EndIf;
	EndIf;
	If Not Posted Then
		// Check user rights to do return
		vEmployee = SessionParameters.CurrentUser;
		If ValueIsFilled(vEmployee) And ValueIsFilled(vEmployee.PermissionGroup) And ValueIsFilled(Folio) Then
			vPermissionGroup = vEmployee.PermissionGroup;
			For Each vPrmRow In vPermissionGroup.FolioOperationsAllowed Do
				If IsBlankString(vPrmRow.FolioType) Or 
				   Not IsBlankString(vPrmRow.FolioType) And TrimR(vPrmRow.FolioType) = Left(TrimR(Folio.Description), StrLen(TrimR(vPrmRow.FolioType))) Then
					If vPrmRow.ReturnsForbidden Then
						vHasErrors = True;
						vMsgTextRu = vMsgTextRu + "Нет прав на оформление возвратов по фолио с типом " + TrimAll(Folio.Description) + "!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "You do not have rights to return money from folio type " + TrimAll(Folio.Description) + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Sie haben keine Rechte für Geld zurückgeben in Folio-typ " + TrimAll(Folio.Description) + "!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Folio", pAttributeInErr);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	Else
		If Not ValueIsFilled(AccountingCustomer) And ValueIsFilled(Hotel) And ValueIsFilled(Hotel.IndividualsCustomer) Then
			AccountingCustomer = Hotel.IndividualsCustomer;
			AccountingContract = Hotel.IndividualsContract;
		EndIf;
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
	// New object ref
	If IsNew() Then
		If Not ValueIsFilled(GetNewObjectRef()) Then
			SetNewObjectRef(Documents.Return.GetRef());
		EndIf;
	EndIf;
	// Fill from session parameters
	ExchangeRateDate = BegOfDay(Date);
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(Hotel.AccountingDate) And Not ValueIsFilled(AccountingDate) Then
			AccountingDate = Hotel.AccountingDate;
		EndIf;
		FolioCurrency = Hotel.FolioCurrency;
		FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ExchangeRateDate);
		PaymentCurrency = Hotel.BaseCurrency;
		PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, PaymentCurrency, ExchangeRateDate);
		Company = Hotel.Company;
		If ValueIsFilled(Company) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmFillCustomerContractAndGuestGroup() Export
	If ValueIsFilled(Payer) Then
		If TypeOf(Payer) = Type("CatalogRef.Customers") Then
			If AccountingCustomer <> Payer Then
				AccountingCustomer = Payer;
				If AccountingCustomer = Folio.Customer Then
					AccountingContract = Folio.Contract;
				Else
					AccountingContract = Payer.Contract;
				EndIf;
			EndIf;
		Else
			If ValueIsFilled(Folio.Customer) Then
				If AccountingCustomer <> Folio.Customer Then
					AccountingCustomer = Folio.Customer;
					AccountingContract = Folio.Contract;
				EndIf;
			Else
				If ValueIsFilled(Hotel) Then
					If AccountingCustomer <> Hotel.IndividualsCustomer Then
						AccountingCustomer = Hotel.IndividualsCustomer;
						AccountingContract = Hotel.IndividualsContract;
					EndIf;
				Else
					AccountingCustomer = Catalogs.Customers.EmptyRef();
					AccountingContract = Catalogs.Contracts.EmptyRef();
				EndIf;
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(Folio.Customer) Then
			If AccountingCustomer <> Folio.Customer Then
				AccountingCustomer = Folio.Customer;
				AccountingContract = Folio.Contract;
			EndIf;
		Else
			If ValueIsFilled(Hotel) Then
				If AccountingCustomer <> Hotel.IndividualsCustomer Then
					AccountingCustomer = Hotel.IndividualsCustomer;
					AccountingContract = Hotel.IndividualsContract;
				EndIf;
			Else
				AccountingCustomer = Catalogs.Customers.EmptyRef();
				AccountingContract = Catalogs.Contracts.EmptyRef();
			EndIf;
		EndIf;
	EndIf;
	If Folio.GuestGroup <> GuestGroup Then
		GuestGroup = Folio.GuestGroup;
	EndIf;
EndProcedure // pmFillCustomerContractAndGuestGroup

// -----------------------------------------------------------------------------
//  Get list of payment methods allowed for return
//  -----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - Payment methods list
//
Function pmGetPaymentMethodsAllowedForReturn() Export
	vPMs = Undefined;
	If ValueIsFilled(Payment) And ValueIsFilled(Payment.PaymentMethod) And 
	   Payment.PaymentMethod <> Catalogs.PaymentMethods.DepositTransfer And 
	   Not CorrectionOfIncorrectCheque Then
		vPaymentMethod = Payment.PaymentMethod;
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	PaymentMethods.Ref AS Ref
		|FROM
		|	Catalog.PaymentMethods AS PaymentMethods
		|WHERE
		|	NOT PaymentMethods.DeletionMark
		|	AND (PaymentMethods.IsForReturnOnly
		|			OR &qIgnoreForReturnOnly
		|			OR &qPaymentMethod = VALUE(Catalog.PaymentMethods.AdvanceSettlement)
		|				AND PaymentMethods.Ref = VALUE(Catalog.PaymentMethods.AdvanceSettlement)
		|			OR &qPaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
		|				AND PaymentMethods.Ref = VALUE(Catalog.PaymentMethods.Settlement))
		|	AND PaymentMethods.IsByCash = &qIsByCash
		|	AND (PaymentMethods.IsByCreditCard = &qIsByCreditCard
		|			OR &qIsByCreditCard
		|				AND PaymentMethods.IsViaInternetAcquiring)
		|	AND PaymentMethods.IsByBankTransfer = &qIsByBankTransfer
		|	AND PaymentMethods.IsByGiftCertificate = &qIsByGiftCertificate
		|	AND PaymentMethods.IsByBonuses = &qIsByBonuses
		|	AND (PaymentMethods.CardType = &qCardType
		|			OR &qIgnoreCardType)
		|
		|ORDER BY
		|	PaymentMethods.SortCode";
		vQry.SetParameter("qPaymentMethod", vPaymentMethod);
		vQry.SetParameter("qIsByCash", vPaymentMethod.IsByCash);
		vQry.SetParameter("qIsByCreditCard", vPaymentMethod.IsByCreditCard);
		vQry.SetParameter("qIsByBankTransfer", vPaymentMethod.IsByBankTransfer);
		vQry.SetParameter("qIsByGiftCertificate", vPaymentMethod.IsByGiftCertificate);
		vQry.SetParameter("qIsByBonuses", vPaymentMethod.IsByBonuses);
		vQry.SetParameter("qIgnoreForReturnOnly", ?(ValueIsFilled(CashRegister), CashRegister.CashReturnDirectlyFromCashBoxIsAllowed, True));
		vQry.SetParameter("qCardType", vPaymentMethod.CardType);
		vQry.SetParameter("qIgnoreCardType", Not ValueIsFilled(vPaymentMethod.CardType));
		vPMs = vQry.Execute().Unload();
	Else
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	PaymentMethods.Ref AS Ref
		|FROM
		|	Catalog.PaymentMethods AS PaymentMethods
		|WHERE
		|	NOT PaymentMethods.DeletionMark
		|	AND (PaymentMethods.IsForReturnOnly
		|			OR &qIgnoreForReturnOnly
		|			OR PaymentMethods.Ref = VALUE(Catalog.PaymentMethods.AdvanceSettlement)
		|			OR PaymentMethods.Ref = VALUE(Catalog.PaymentMethods.Settlement))
		|
		|ORDER BY
		|	PaymentMethods.SortCode";
		vQry.SetParameter("qIgnoreForReturnOnly", ?(ValueIsFilled(CashRegister), CashRegister.CashReturnDirectlyFromCashBoxIsAllowed, True));
		vPMs = vQry.Execute().Unload();
	EndIf;
	If vPMs <> Undefined Then
		Return vPMs.UnloadColumn("Ref");
	Else
		Return New Array();
	EndIf;
EndFunction // pmGetPaymentMethodsAllowedForReturn

// -----------------------------------------------------------------------------
// Set default payment method for return
// -----------------------------------------------------------------------------
Procedure pmSetDefaultPaymentMethodForReturn() Export
	If ValueIsFilled(Payment) And ValueIsFilled(Payment.PaymentMethod) And Payment.PaymentMethod <> Catalogs.PaymentMethods.DepositTransfer Then
		PaymentMethod = Payment.PaymentMethod;
	EndIf;
	vPMs = pmGetPaymentMethodsAllowedForReturn();
	If ValueIsFilled(PaymentMethod) Then
		If vPMs.Find(PaymentMethod) = Undefined Then
			PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
		EndIf;
	EndIf;
	If Not ValueIsFilled(PaymentMethod) Then
		If vPMs.Count() > 0 Then
			PaymentMethod = vPMs.Get(0);
		EndIf;
	EndIf;
EndProcedure // pmSetDefaultPaymentMethodForReturn

// -----------------------------------------------------------------------------
Procedure pmCalculateTotalsByPaymentSections() Export
	SumInFolioCurrency = PaymentSections.Total("SumInFolioCurrency");
	VATSumInFolioCurrency = PaymentSections.Total("VATSumInFolioCurrency");
	Sum = PaymentSections.Total("Sum");
	VATSum = PaymentSections.Total("VATSum");
EndProcedure // pmCalculateTotalsByPaymentSections

// -----------------------------------------------------------------------------
Procedure pmRecalculateSums() Export
	If PaymentSections.Count() > 0 Then
		For Each vPSRow In PaymentSections Do
			vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));

			vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, PaymentCurrency, PaymentCurrencyExchangeRate, 
			                                                      FolioCurrency, FolioCurrencyExchangeRate, 
			                                                      ExchangeRateDate, Hotel), 2);
			vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, ?(ValueIsFilled(Payment), Payment.Date, Date));
		EndDo;
		pmCalculateTotalsByPaymentSections();
	Else
		VATSum = cmCalculateVATSum(VATRate, Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));
		SumInFolioCurrency = Round(cmConvertCurrencies(Sum, PaymentCurrency, PaymentCurrencyExchangeRate, 
		                                               FolioCurrency, FolioCurrencyExchangeRate, 
		                                               ExchangeRateDate, Hotel), 2);
		VATSumInFolioCurrency = cmCalculateVATSum(VATRate, SumInFolioCurrency, ?(ValueIsFilled(Payment), Payment.Date, Date));
	EndIf;
EndProcedure // pmRecalculateSums

// -----------------------------------------------------------------------------
// 
// Returns:
//  DocumentRef.Payment - Document ref
//
Function pmGetThisDocumentRef() Export
	vObjectRef = Ref;
	If IsNew() Then
		vObjectRef = GetNewObjectRef();
		If Not ValueIsFilled(vObjectRef) Then
			SetNewObjectRef(Documents.Return.GetRef());
			vObjectRef = GetNewObjectRef();
		EndIf;
	EndIf;
	Return vObjectRef;
EndFunction // pmGetThisDocumentRef

// -----------------------------------------------------------------------------
// 
// Returns:
//  DocumentRef.ProformaInvoice - Document ref
//
Function pmGetReturnInvoice() Export
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
EndFunction // pmGetReturnInvoice

// --------------------------------------------------------------------------------
Procedure pmFillContactsToOFD() Export
	If ValueIsFilled(CashRegister) And CashRegister.IsControlledByProgram And
		ValueIsFilled(PaymentMethod) And PaymentMethod.BookByCashRegister And PaymentMethod.PrintCheque Then
		SendPayerContactsToOFD = CashRegister.SendPayerContactsToOFD;
	Else
		SendPayerContactsToOFD = 2;
	EndIf;
	If ValueIsFilled(Payer) Then
		EmailToSendToOFD = Payer.EMail;
		PhoneToSendToOFD = Payer.Phone;
	Else
		EmailToSendToOFD = "";
		PhoneToSendToOFD = "";
	EndIf;
EndProcedure // pmFillContactsToOFD

#EndRegion

#Region Internal

// -----------------------------------------------------------------------------
Procedure PostToFolioPayments()
	If PaymentSections.Count() > 0 Then
		vPaymentSections = PaymentSections.Unload();
		vPaymentSections.GroupBy("PaymentSection, VATRate", "SumInFolioCurrency, VATSumInFolioCurrency, Sum, VATSum");
		For Each vPSRow In vPaymentSections Do
			If vPSRow.Sum = 0 Then
				Continue;
			EndIf;
				
			Movement = RegisterRecords.FolioPayments.Add();
			
			Movement.Period = Date;
			Movement.Payment = Ref;
			
			FillPropertyValues(Movement, ThisObject);
			FillPropertyValues(Movement, vPSRow);
			Movement.FolioCurrency = FolioCurrency;
			Movement.Folio = Folio;
			
			// Resources
			Movement.Sum = -vPSRow.SumInFolioCurrency;
			
			// Attributes
			Movement.SumInPaymentCurrency = -vPSRow.Sum;
		EndDo;			
	Else
		Movement = RegisterRecords.FolioPayments.Add();
		
		Movement.Period = Date;
		Movement.Payment = Ref;
		
		FillPropertyValues(Movement, ThisObject);
		Movement.FolioCurrency = FolioCurrency;
		Movement.Folio = Folio;
		
		// Resources
		Movement.Sum = -SumInFolioCurrency;
		
		// Attributes
		Movement.SumInPaymentCurrency = -Sum;
	EndIf;
	
	RegisterRecords.FolioPayments.Write();
EndProcedure // PostToFolioPayments

// -----------------------------------------------------------------------------
Procedure PostToAccounts(pIsGiftCardReturn = False)
	vIsByServices = ?(ValueIsFilled(Hotel), Hotel.SplitFolioBalanceByServicesAndPrices, False);
	If PaymentSections.Count() > 0 Then
		For Each vPSRow In PaymentSections Do
			If vPSRow.Sum = 0 Then
				Continue;
			EndIf;
			
			Movement = RegisterRecords.Accounts.Add();
			
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			
			FillPropertyValues(Movement, Folio);
			If ValueIsFilled(ParentDoc) Then
				FillPropertyValues(Movement, ParentDoc);
			EndIf;
			FillPropertyValues(Movement, ThisObject);
			FillPropertyValues(Movement, vPSRow);
			
			// Dimensions
			Movement.PaymentSection = vPSRow.PaymentSection;
			Movement.ChequeService = vPSRow.ChequeService;
			Movement.ChequeServicePrice = vPSRow.ChequeServicePrice;
			
			// Resources
			Movement.Sum = -vPSRow.SumInFolioCurrency;
			Movement.ChequeServiceQuantity = -vPSRow.ChequeServiceQuantity;
			
			// Attributes
			Movement.VATSum = -vPSRow.VATSumInFolioCurrency;
			
			// If this is advance
			If vIsByServices And Not ValueIsFilled(Movement.ChequeService) Then
				Movement.ChequeServiceQuantity = 0;
				Movement.ChequeServicePrice = 0;
			EndIf;
			
			// Zero resources if this is gift card refill
			If pIsGiftCardReturn Then
				Movement.Sum = 0;
				Movement.Limit = 0;
				Movement.VATSum = 0;
				Movement.ChequeServicePrice = 0;
				Movement.ChequeServiceQuantity = 0;
			EndIf;
		EndDo;
	Else
		Movement = RegisterRecords.Accounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		FillPropertyValues(Movement, Folio);
		If ValueIsFilled(ParentDoc) Then
			FillPropertyValues(Movement, ParentDoc);
		EndIf;
		FillPropertyValues(Movement, ThisObject);
		
		// Resources
		Movement.Sum = -SumInFolioCurrency;
		
		// Attributes
		Movement.VATSum = -VATSumInFolioCurrency;
		
		// Payment section
		If ValueIsFilled(Hotel) And Not Hotel.SplitFolioBalanceByPaymentSections And Not Hotel.SplitFolioBalanceByServicesAndPrices Then
			Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
		EndIf;
		
		// Zero resources if this is gift card refill
		If pIsGiftCardReturn Then
			Movement.Sum = 0;
			Movement.Limit = 0;
			Movement.VATSum = 0;
			Movement.ChequeServicePrice = 0;
			Movement.ChequeServiceQuantity = 0;
		EndIf;
	EndIf;

	RegisterRecords.Accounts.Write();
EndProcedure // PostToAccounts

// -----------------------------------------------------------------------------
Procedure PostToPayments()
	If PaymentSections.Count() > 0 Then
		vPaymentSections = PaymentSections.Unload();
		vPaymentSections.GroupBy("PaymentSection, VATRate", "SumInFolioCurrency, VATSumInFolioCurrency, Sum, VATSum");
		For Each vPSRow In vPaymentSections Do
			If vPSRow.Sum = 0 Then
				Continue;
			EndIf;
			
			Movement = RegisterRecords.Payments.Add();
			
			Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			
			FillPropertyValues(Movement, ThisObject);
			FillPropertyValues(Movement, vPSRow);
			
			// Dimensions
			Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
			
			// Resources
			Movement.Sum = -vPSRow.Sum;
			Movement.VATSum = -vPSRow.VATSum;
			Movement.SumReceipt = 0;
			Movement.VATSumReceipt = 0;
			Movement.SumExpense = vPSRow.Sum;
			Movement.VATSumExpense = vPSRow.VATSum;
		EndDo;
	Else
		Movement = RegisterRecords.Payments.Add();
		
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		FillPropertyValues(Movement, ThisObject);
		
		// Dimensions
		Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		
		// Resources
		Movement.Sum = -Sum;
		Movement.VATSum = -VATSum;
		Movement.SumReceipt = 0;
		Movement.VATSumReceipt = 0;
		Movement.SumExpense = Sum;
		Movement.VATSumExpense = VATSum;
	EndIf;
	
	RegisterRecords.Payments.Write();
EndProcedure // PostToPayments

// -----------------------------------------------------------------------------
Procedure PostToCustomerAccounts()
	// Retrieve amounts that could be cleared
	vPrevAdvances = New ValueTable();
	If PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
		vPrevAdvances = cmGetAdvancesForAdvanceClearing(Folio, ?(ValueIsFilled(Payment), Payment.Date, Date));
	EndIf;
	
	// Do for each row in payment sections table
	If PaymentSections.Count() > 0 Then
		vPaymentSections = PaymentSections.Unload();
		For Each vPSRow In vPaymentSections Do
			If vPSRow.Sum = 0 Then
				Continue;
			EndIf;
			
			While True Do
				Movement = RegisterRecords.CustomerAccounts.Add();
				
				Movement.RecordType = AccumulationRecordType.Expense;
				Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
				
				FillPropertyValues(Movement, Folio);
				If ValueIsFilled(ParentDoc) Then
					FillPropertyValues(Movement, ParentDoc);
				EndIf;
				FillPropertyValues(Movement, ThisObject);
				FillPropertyValues(Movement, vPSRow);
				
				Movement.Service = vPSRow.ChequeService;
				Movement.Price = vPSRow.ChequeServicePrice;
				Movement.Quantity = -vPSRow.ChequeServiceQuantity;
				
				// Dimensions
				Movement.AccountingCurrency = FolioCurrency;
				
				If ValueIsFilled(Folio) And ValueIsFilled(Folio.GuestGroup) Then
					Movement.GuestGroup = Folio.GuestGroup;
				EndIf;
				
				// Resources
				Movement.Sum = -vPSRow.SumInFolioCurrency;
				
				// Attributes
				Movement.VATSum = -vPSRow.VATSumInFolioCurrency;
				Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
				
				// Fill payment method attribute based on payments before
				If PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
					If ValueIsFilled(vPSRow.PaymentSection) And vPSRow.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
						Break;
					EndIf;
					
					vOuterBreak = True;
					If vPrevAdvances.Count() > 0 Then
						vOuterBreak = False;
						vThereAreAmountsForClearing = False;
						
						i = 0;
						While i < vPrevAdvances.Count() Do
							vPrevAdvancesRow = vPrevAdvances.Get(i);
							i = i + 1;
							
							If vPrevAdvancesRow.Sum = 0 Then
								Continue;
							EndIf;
							vThereAreAmountsForClearing = True;
							
							vSum = cmConvertCurrencies(vPrevAdvancesRow.Sum, vPrevAdvancesRow.Currency, , Movement.AccountingCurrency, , ExchangeRateDate, Hotel);
							If vSum < -Movement.Sum Then
								Movement.Sum = -vSum;
								Movement.VATSum = cmCalculateVATSum(Movement.VATRate, Movement.Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));
								If Movement.Price <> 0 Then
									Movement.Quantity = Round(Movement.Sum/Movement.Price, 7);
								EndIf;
							EndIf;
							Movement.PaymentMethod = vPrevAdvancesRow.PaymentMethod;
							
							// Correct row amount
							vCorrSum = cmConvertCurrencies(-Movement.Sum, Movement.AccountingCurrency, , vPrevAdvancesRow.Currency, , ExchangeRateDate, Hotel);
							vPrevAdvancesRow.Sum = vPrevAdvancesRow.Sum - vCorrSum;
							
							vCorrSumInPaymentCurrency = cmConvertCurrencies(-Movement.Sum, Movement.AccountingCurrency, , PaymentCurrency, , ExchangeRateDate, Hotel);
							vCorrSumInFolioCurrency = cmConvertCurrencies(-Movement.Sum, Movement.AccountingCurrency, , FolioCurrency, , ExchangeRateDate, Hotel);
							
							vPSRow.Sum = vPSRow.Sum - vCorrSumInPaymentCurrency;
							vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));
							vPSRow.SumInFolioCurrency = vPSRow.SumInFolioCurrency - vCorrSumInFolioCurrency;
							If vPSRow.ChequeServicePrice <> 0 Then
								vPSRow.ChequeServiceQuantity = Round(vPSRow.Sum/vPSRow.ChequeServicePrice, 7);
							EndIf;
							
							If vPSRow.Sum = 0 Then
								vOuterBreak = True;
								Break;
							EndIf;
							If vPrevAdvancesRow.Sum = 0 Then
								Break;
							EndIf;
						EndDo;
						
						If Not vThereAreAmountsForClearing Then
							vOuterBreak = True;
						EndIf;
					EndIf;
					If vOuterBreak Then
						Break;
					EndIf;
				Else
					Break;
				EndIf;
			EndDo;
		EndDo;
	Else
		Movement = RegisterRecords.CustomerAccounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		FillPropertyValues(Movement, Folio);
		If ValueIsFilled(ParentDoc) Then
			FillPropertyValues(Movement, ParentDoc);
		EndIf;
		FillPropertyValues(Movement, ThisObject);
		
		// Dimensions
		Movement.AccountingCurrency = FolioCurrency;
		
		If ValueIsFilled(Folio) And ValueIsFilled(Folio.GuestGroup) Then
			Movement.GuestGroup = Folio.GuestGroup;
		EndIf;
		
		// Resources
		Movement.Sum = -SumInFolioCurrency;
		
		// Attributes
		Movement.VATSum = -VATSumInFolioCurrency;
		Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
	EndIf;

	RegisterRecords.CustomerAccounts.Write();
EndProcedure // PostToCustomerAccounts

// -----------------------------------------------------------------------------
Procedure PostToInvoiceAccounts()
	If ValueIsFilled(Invoice) Then
		Movement = RegisterRecords.InvoiceAccounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		// Dimensions
		Movement.Hotel = Hotel;
		Movement.Company = Company;
		Movement.Invoice = Invoice;
		Movement.AccountingCustomer = Invoice.AccountingCustomer;
		Movement.AccountingContract = Invoice.AccountingContract;
		Movement.AccountingCurrency = Invoice.AccountingCurrency;
		Movement.GuestGroup = Invoice.GuestGroup;
		
		// Resources
		Movement.Sum = -cmConvertCurrencies(Sum, PaymentCurrency, PaymentCurrencyExchangeRate, Movement.AccountingCurrency, , ExchangeRateDate, Hotel);
		
		// Attributes
		Movement.VATSum = cmCalculateVATSum(VATRate, Movement.Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));
		Movement.VATRate = VATRate;
		Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		
		If ValueIsFilled(Folio) Then
			Movement.Client = Folio.Client;
			Movement.Room = Folio.Room;
		EndIf;
	EndIf;
	
	RegisterRecords.InvoiceAccounts.Write();
EndProcedure // PostToInvoiceAccounts

// -----------------------------------------------------------------------------
Procedure PostToCashRegisterDailyReceipts()
	If PaymentSections.Count() > 0 Then
		vPaymentSections = PaymentSections.Unload();
		vPaymentSections.GroupBy("PaymentSection, VATRate", "SumInFolioCurrency, VATSumInFolioCurrency, Sum, VATSum");
		For Each vPSRow In vPaymentSections Do
			If vPSRow.Sum = 0 Then
				Continue;
			EndIf;
			
			Movement = RegisterRecords.CashRegisterDailyReceipts.AddReceipt();
			
			Movement.Period = Date;
			Movement.Currency = PaymentCurrency;
			
			FillPropertyValues(Movement, Folio);
			If ValueIsFilled(ParentDoc) Then
				FillPropertyValues(Movement, ParentDoc);
			EndIf;
			FillPropertyValues(Movement, ThisObject);
			FillPropertyValues(Movement, vPSRow);
			
			// Dimensions
			Movement.Customer = AccountingCustomer;
			Movement.Contract = AccountingContract;
			Movement.Payment = Ref;
			
			If ValueIsFilled(Folio) And ValueIsFilled(Folio.GuestGroup) Then
				Movement.GuestGroup = Folio.GuestGroup;
			EndIf;
			
			// Resources
			Movement.Sum = -vPSRow.Sum;
			Movement.VATSum = -vPSRow.VATSum;
			Movement.PaymentSum = 0;
			Movement.VATPaymentSum = 0;
			Movement.ReturnSum = vPSRow.Sum;
			Movement.VATReturnSum = vPSRow.VATSum;
		EndDo;
	Else
		Movement = RegisterRecords.CashRegisterDailyReceipts.AddReceipt();
		
		Movement.Period = Date;
		Movement.Currency = PaymentCurrency;
		
		FillPropertyValues(Movement, Folio);
		If ValueIsFilled(ParentDoc) Then
			FillPropertyValues(Movement, ParentDoc);
		EndIf;
		FillPropertyValues(Movement, ThisObject);
		
		// Dimensions
		Movement.Customer = AccountingCustomer;
		Movement.Contract = AccountingContract;
		Movement.Payment = Ref;
		
		If ValueIsFilled(Folio) And ValueIsFilled(Folio.GuestGroup) Then
			Movement.GuestGroup = Folio.GuestGroup;
		EndIf;
		
		// Resources
		Movement.Sum = -Sum;
		Movement.VATSum = -VATSum;
		Movement.PaymentSum = 0;
		Movement.VATPaymentSum = 0;
		Movement.ReturnSum = Sum;
		Movement.VATReturnSum = VATSum;
	EndIf;

	RegisterRecords.CashRegisterDailyReceipts.Write();
EndProcedure // PostToCashRegisterDailyReceipts

// -----------------------------------------------------------------------------
Procedure PostToCashInCashRegisters()
	Movement = RegisterRecords.CashInCashRegisters.Add();
	
	Movement.Period = Date;
	Movement.RecordType = AccumulationRecordType.Expense;
	Movement.Currency = PaymentCurrency;
	
	FillPropertyValues(Movement, ThisObject);

	RegisterRecords.CashInCashRegisters.Write();
EndProcedure // PostToCashInCashRegisters

// -----------------------------------------------------------------------------
Procedure PostToPaymentServices()
	If PaymentSections.Count() > 0 Then
		vPaymentSections = PaymentSections.Unload();
		vPaymentSections.GroupBy("PaymentSection, VATRate", "SumInFolioCurrency, VATSumInFolioCurrency, Sum, VATSum");
		For Each vPSRow In vPaymentSections Do
			If vPSRow.Sum = 0 Then
				Continue;
			EndIf;
			
			Movement = RegisterRecords.PaymentServices.Add();
		
			Movement.RecordType = AccumulationRecordType.Expense;
			Movement.Period = Date;
			
			// Dimensions
			Movement.Folio = Folio;
			Movement.Service = Catalogs.Services.EmptyRef();
			Movement.PaymentSection = vPSRow.PaymentSection;
			Movement.Payment = Ref;
			
			// Resources
			Movement.Sum = -vPSRow.SumInFolioCurrency;
		EndDo;
	Else
		Movement = RegisterRecords.PaymentServices.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = Date;
		
		// Dimensions
		Movement.Folio = Folio;
		Movement.Service = Catalogs.Services.EmptyRef();
		Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
		Movement.Payment = Ref;
		
		// Resources
		Movement.Sum = -SumInFolioCurrency;
	EndIf;
	
	RegisterRecords.PaymentServices.Write();
EndProcedure // PostToPaymentServices

// -----------------------------------------------------------------------------
Procedure WriteOffBonuses()
	If ValueIsFilled(PaymentMethod) And PaymentMethod.IsByBonuses And 
	   ValueIsFilled(PaymentMethod.DiscountType) And 
	   PaymentMethod.DiscountType.BonusCalculationFactor <> 0 And
	   Not PaymentMethod.DiscountType.ExternalBonusSystemIsUsed Then
		vDiscountTypeObj = PaymentMethod.DiscountType.GetObject();
		vDimension = Undefined;
		If PaymentMethod.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.DiscountCard Then
			If ValueIsFilled(ParentDoc) And ValueIsFilled(ParentDoc.DiscountCard) Then
				vDimension = ParentDoc.DiscountCard;
				vBonuses = vDiscountTypeObj.pmGetAccumulatingDiscountResources(Date, , , , ParentDoc.DiscountCard);
			EndIf;
		ElsIf PaymentMethod.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Client Then
			If ValueIsFilled(Payer) And TypeOf(Payer) = Type("CatalogRef.Clients") Then
				vDimension = Payer;
				vBonuses = vDiscountTypeObj.pmGetAccumulatingDiscountResources(Date, , , Payer);
			EndIf;
		EndIf;
		If vDimension <> Undefined Then
			If vBonuses.Count() > 0 Then
				vBonusesRow = vBonuses.Get(0);
				// Get payment currency bonus calculation rate
				vBonusRate = ?(vDiscountTypeObj.BonusRateMultiplier <> 0, vDiscountTypeObj.BonusRateMultiplier, 1);
				vRates = InformationRegisters.CurrencyRates.SliceLast(Date, New Structure("Hotel, Currency", Hotel, PaymentCurrency));
				If vRates.Count() > 0 Then
					vRatesRow = vRates.Get(0);
					If vRatesRow.BonusRate <> 0 Then
						vBonusRate = Round(vRatesRow.BonusRate * vBonusRate, 4);
					ElsIf vRatesRow.Rate <> 0 Then
						vBonusRate = Round(vRatesRow.Rate / ?(vRatesRow.Factor = 0, 1, vRatesRow.Factor) * vBonusRate, 4);
					EndIf;
				EndIf;
				If vBonusRate <> 0 Then
					vBonus2WriteOff = Round(Sum * vBonusRate, 2);
					If vBonus2WriteOff <> 0 Then
						Movement = RegisterRecords.AccumulatingDiscountResources.Add();
						If vBonus2WriteOff > 0 Then
							Movement.RecordType = AccumulationRecordType.Receipt;
						Else
							Movement.RecordType = AccumulationRecordType.Expense;
						EndIf;
						Movement.Period = Date;
						Movement.DiscountType = PaymentMethod.DiscountType;
						Movement.DiscountDimension = vDimension;
						Movement.GuestGroup = Catalogs.GuestGroups.EmptyRef();
						Movement.Resource = 0;
						Movement.Bonus = vBonus2WriteOff;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // WriteOffBonuses

// -----------------------------------------------------------------------------
Procedure PostToGiftCertificates()
	vGiftCertificatesArePerHotel = Constants.GiftCertificatesArePerHotel.Get();
	
	Movement = RegisterRecords.GiftCertificatesBalance.Add();
	Movement.Period = Date;
	
	// Fill dimensions
	Movement.Hotel = ?(vGiftCertificatesArePerHotel, Hotel, Catalogs.Hotels.EmptyRef());
	Movement.GiftCertificate = GiftCertificate;
	
	// Fill resource
	Movement.Amount = -Round(cmConvertCurrencies(Sum, PaymentCurrency, PaymentCurrencyExchangeRate, Hotel.ReportingCurrency, , ExchangeRateDate, Hotel), 2);
	
	// Fill attributes and movement type
	If Not PaymentMethod.IsByGiftCertificate Then
		Movement.RecordType = AccumulationRecordType.Receipt;
		
		Movement.Buyer = Folio.Client;
	Else
		Movement.RecordType = AccumulationRecordType.Expense;
		
		Movement.Payer = Folio.Client;
	EndIf;
	
	// Write movements
	RegisterRecords.GiftCertificatesBalance.Write();
EndProcedure // PostToGiftCertificates

// -----------------------------------------------------------------------------
Procedure PostToFOChartOfAccounts()
	// Get service account
	vAccountStruct = cmGetAccountCodeForPOSAndPaymentMethod(Hotel, Company, CashRegister, PaymentMethod, PaymentSection);
	vPostingAccount = vAccountStruct.Account;
	If Not ValueIsFilled(vPostingAccount) Then
		Return;
	EndIf;
	vCorrespondingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
	If ValueIsFilled(Folio) And ValueIsFilled(Folio.FinancialAccount) Then
		vCorrespondingAccount = Folio.FinancialAccount;
	EndIf;
	
	// Postings currency
	vAccountCurrency = FolioCurrency;
	
	vPostingAmount = SumInFolioCurrency;
	
	vReverseSign = False;
	If vPostingAmount < 0 Then
		vReverseSign = True;
		
		vPostingAmount = -vPostingAmount;
	EndIf;
	
	// Commission percent
	vCommissionAccount = Undefined;
	vCommissionPercent = 0;
	vCommissionAmount = 0;
	If ValueIsFilled(vAccountStruct.CommissionAccount) And vAccountStruct.CommissionPercent <> 0 Then
		vCommissionAccount = vAccountStruct.CommissionAccount;
		vCommissionPercent = vAccountStruct.CommissionPercent;
		vCommissionAmount = Round(vPostingAmount * vCommissionPercent / 100, 2);
	EndIf;
	
	If vPostingAmount <> 0 Then
		// Create movement for this payment
		PostingMovement = Undefined;
		If vPostingAccount.Type = AccountType.Passive Then
			If vReverseSign Then
				PostingMovement = RegisterRecords.PostingsFO.AddCredit();
			Else
				PostingMovement = RegisterRecords.PostingsFO.AddDebit();
			EndIf;
		ElsIf vPostingAccount.Type = AccountType.Active Then
			If vReverseSign Then
				PostingMovement = RegisterRecords.PostingsFO.AddDebit();
			Else
				PostingMovement = RegisterRecords.PostingsFO.AddCredit();
			EndIf;
		Else
			Raise NStr("en='Sign is not defined for account '; ru='Знак не указан в настройках счета '; de='Das buchungszeichen ist in den Konto nicht angegeben '") + vPostingAccount;
		EndIf;
		
		PostingMovement.Active = True;
		
		PostingMovement.Account = vPostingAccount;
		PostingMovement.CorrAccount = vCorrespondingAccount;
		
		PostingMovement.Amount = vPostingAmount - vCommissionAmount;
		PostingMovement.GrosAmount = 0;
		
		PostingMovement.Description = TrimAll(PaymentMethod) + "/" + TrimAll(CashRegister);
		
		PostingMovement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		PostingMovement.FODate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		PostingMovement.ServiceDate = '00010101';
		PostingMovement.Days = 0;
					
		PostingMovement.ParentDoc = ParentDoc;
		
		PostingMovement.Room = Folio.Room;
		PostingMovement.Resource = Undefined;
		
		PostingMovement.Service = Undefined;
		PostingMovement.PaymentMethod = PaymentMethod;
		PostingMovement.AccountingCustomer = AccountingCustomer;
			
		PostingMovement.AccountGroup = vPostingAccount.AccountGroup;
		PostingMovement.AccountType = vPostingAccount.AccountType;
		PostingMovement.Department = vPostingAccount.Department;
		PostingMovement.DiscountType = vPostingAccount.DiscountType;
		PostingMovement.ServiceType = vPostingAccount.ServiceType;
		
		PostingMovement.Hotel = Hotel;
		PostingMovement.Company = Company;
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
			PostingMovement = RegisterRecords.PostingsFO.AddCredit();
		Else
			PostingMovement = RegisterRecords.PostingsFO.AddDebit();
		EndIf;
					
		PostingMovement.Active = True;
		
		PostingMovement.Account = vCorrespondingAccount;
		If vCorrespondingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger Then
			PostingMovement.ExtDimensions.Folio = Folio;
		EndIf;
		PostingMovement.CorrAccount = vPostingAccount;
		
		PostingMovement.Amount = vPostingAmount;
		PostingMovement.GrosAmount = 0;
		
		PostingMovement.Description = TrimAll(PaymentMethod) + "/" + TrimAll(CashRegister);
		
		PostingMovement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		PostingMovement.FODate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		PostingMovement.ServiceDate = '00010101';
		PostingMovement.Days = 0;
					
		PostingMovement.ParentDoc = ParentDoc;
		
		PostingMovement.Room = Folio.Room;
		PostingMovement.Resource = Undefined;
		
		PostingMovement.Service = Undefined;
		PostingMovement.PaymentMethod = PaymentMethod;
		PostingMovement.AccountingCustomer = AccountingCustomer;
			
		PostingMovement.AccountGroup = vCorrespondingAccount.AccountGroup;
		PostingMovement.AccountType = vCorrespondingAccount.AccountType;
		PostingMovement.Department = vCorrespondingAccount.Department;
		PostingMovement.DiscountType = vCorrespondingAccount.DiscountType;
		PostingMovement.ServiceType = vCorrespondingAccount.ServiceType;
		
		PostingMovement.Hotel = Hotel;
		PostingMovement.Company = Company;
		PostingMovement.Currency = vAccountCurrency;
		
		PostingMovement.Discount = 0;
		PostingMovement.DiscountAmount = 0;
		
		PostingMovement.VATAmount = 0;
		PostingMovement.VATRate = Undefined;
		
		PostingMovement.POSTicket = "";
		PostingMovement.Invoice = Undefined;
		
		PostingMovement.Recorder = Ref;
		PostingMovement.Author = SessionParameters.CurrentUser;
		
		// Commission
		If vCommissionAccount <> Undefined And vCommissionAmount <> 0 Then
			If vPostingAccount.Type = AccountType.Passive Then
				If vReverseSign Then
					PostingMovement = RegisterRecords.PostingsFO.AddCredit();
				Else
					PostingMovement = RegisterRecords.PostingsFO.AddDebit();
				EndIf;
			ElsIf vPostingAccount.Type = AccountType.Active Then
				If vReverseSign Then
					PostingMovement = RegisterRecords.PostingsFO.AddDebit();
				Else
					PostingMovement = RegisterRecords.PostingsFO.AddCredit();
				EndIf;
			Else
				Raise NStr("en='Sign is not defined for account '; ru='Знак не указан в настройках счета '; de='Das buchungszeichen ist in den Konto nicht angegeben '") + vPostingAccount;
			EndIf;
			
			PostingMovement.Active = True;
			
			PostingMovement.Account = vCommissionAccount;
			PostingMovement.CorrAccount = vCorrespondingAccount;
			
			PostingMovement.Amount = vCommissionAmount;
			PostingMovement.GrosAmount = 0;
			
			PostingMovement.Description = TrimAll(vCommissionPercent) + "%";
			
			PostingMovement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
			PostingMovement.FODate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
			PostingMovement.ServiceDate = '00010101';
			PostingMovement.Days = 0;
						
			PostingMovement.ParentDoc = ParentDoc;
			
			PostingMovement.Room = Folio.Room;
			PostingMovement.Resource = Undefined;
			
			PostingMovement.Service = Undefined;
			PostingMovement.PaymentMethod = PaymentMethod;
			PostingMovement.AccountingCustomer = AccountingCustomer;
				
			PostingMovement.AccountGroup = vCommissionAccount.AccountGroup;
			PostingMovement.AccountType = vCommissionAccount.AccountType;
			PostingMovement.Department = vCommissionAccount.Department;
			PostingMovement.DiscountType = vCommissionAccount.DiscountType;
			PostingMovement.ServiceType = vCommissionAccount.ServiceType;
			
			PostingMovement.Hotel = Hotel;
			PostingMovement.Company = Company;
			PostingMovement.Currency = vAccountCurrency;
			
			PostingMovement.Discount = 0;
			PostingMovement.DiscountAmount = 0;
			
			PostingMovement.VATAmount = 0;
			PostingMovement.VATRate = Undefined;
			
			PostingMovement.POSTicket = "";
			PostingMovement.Invoice = Undefined;
			
			PostingMovement.Recorder = Ref;
			PostingMovement.Author = SessionParameters.CurrentUser;
		EndIf;			
		
		RegisterRecords.PostingsFO.Write();
	EndIf;
EndProcedure // PostToFOChartOfAccounts

// -----------------------------------------------------------------------------
Procedure PostToLabeledGoods() 
	RegisterRecords.LabeledGoods.Clear();
	For Each vRow In PaymentSections Do
		If Not IsBlankString(vRow.MarkingCode) Then 
			Movement = RegisterRecords.LabeledGoods.Add();
			Movement.RecordType = AccumulationRecordType.Receipt;
			Movement.Period = Date;  
			Movement.Company = Company;
			Movement.Hotel 	 = Hotel;   
			Movement.Folio = Folio;
			Movement.MarkingCode = vRow.MarkingCode;
			Movement.Service = vRow.ChequeService; 
			Movement.Sum = vRow.Sum;
			Movement.Quantity = vRow.ChequeServiceQuantity;
			Movement.VATSum = vRow.VATSum; 
			Movement.VATRate = vRow.VATRate;
			
			RegisterRecords.LabeledGoods.Write = True;
		EndIf;
	EndDo;
EndProcedure // PostToLabeledGoods

// -----------------------------------------------------------------------------
Function GetBonusesPayment()
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BonusesPayment.Ref AS Ref
		|FROM
		|	Document.BonusesPayment AS BonusesPayment
		|WHERE
		|	NOT BonusesPayment.DeletionMark
		|	AND BonusesPayment.Posted
		|	AND BonusesPayment.Payment = &qPayment";
	
	Query.SetParameter("qPayment", Ref);
	
	QueryResult = Query.Execute();
	
	vRes = QueryResult.Select();
	
	While vRes.Next() Do
		Return vRes.ref;
	EndDo;
	
	Return Documents.BonusesPayment.EmptyRef();
EndFunction	

// -----------------------------------------------------------------------------
Function PostBonusesPayment(vMessage)
	vResult = False;
	vDoc = GetBonusesPayment();
	Try
		If vDoc.IsEmpty() Then
			vBonusesPaymentObj = Documents.BonusesPayment.CreateDocument();
		Else
			vBonusesPaymentObj = vDoc.GetObject();
		EndIf;
		vBonusesPaymentObj.Fill(Ref); 
		vBonusesPaymentObj.Write(DocumentWriteMode.Posting);
	Except
		vResult = True;
		vMessage = BriefErrorDescription(ErrorInfo());
	EndTry;
	Return vResult; 
EndFunction // PostBonusesPayment

// -----------------------------------------------------------------------------
Procedure ReturnGiftCertificate(pCancel)
	vDoc = GetBonusesPayment();
	Try
		If vDoc.IsEmpty() Then
			vBonusesPaymentObj = Documents.BonusesPayment.CreateDocument();
			vBonusesPaymentObj.IsActivateCertificate = False;
		Else
			vBonusesPaymentObj = vDoc.GetObject();
		EndIf;
		vBonusesPaymentObj.Fill(Ref); 
		vBonusesPaymentObj.Write(DocumentWriteMode.Posting);
	Except
		pCancel = True;
		Raise BriefErrorDescription(ErrorInfo());
	EndTry;
EndProcedure // ReturnGiftCertificate

// -----------------------------------------------------------------------------
Procedure FillByFolio(pFolio)
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	Folio = pFolio;
	
	If ValueIsFilled(Folio.Hotel) Then
		If Hotel <> Folio.Hotel Then
			Hotel = Folio.Hotel;
		EndIf;
	EndIf;
	
	ParentDoc = Folio.ParentDoc;
	
	FolioCurrency = Folio.FolioCurrency;
	FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, Date);
	
	// Fill payment method
	PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(Hotel.PlannedPaymentMethod) Then
			PaymentMethod = Hotel.PlannedPaymentMethod;
		EndIf;
	EndIf;
	If ValueIsFilled(ParentDoc) Then
		If ValueIsFilled(ParentDoc.PlannedPaymentMethod) Then
			PaymentMethod = ParentDoc.PlannedPaymentMethod;
		EndIf;
	EndIf;
	If ValueIsFilled(Folio) Then
		If ValueIsFilled(Folio.PaymentMethod) Then
			PaymentMethod = Folio.PaymentMethod;
		EndIf;
	EndIf;
	
	// Fill company
	If ValueIsFilled(Folio.Company) Then
		Company = Folio.Company;
		If ValueIsFilled(Company.VATRate) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
	
	// Fill default payer	
	If ValueIsFilled(Folio.Client) Then
		Payer = Folio.Client;
	ElsIf ValueIsFilled(ParentDoc) Then
		If TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or
		   TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
			If ValueIsFilled(ParentDoc.Guest) Then
				Payer = ParentDoc.Guest;
			EndIf;
		ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
			If ValueIsFilled(ParentDoc.Client) Then
				Payer = ParentDoc.Client;
			EndIf;
		EndIf;
	EndIf;
	
	// Fill customer, contract and guest group
	pmFillCustomerContractAndGuestGroup();
	
	// Fill payment section
	PaymentSection = Folio.PaymentSection;
	// Fill VAT rate from the section
	If ValueIsFilled(PaymentSection) And ValueIsFilled(Company) And Not Company.IsUsingSimpleTaxSystem Then
		If ValueIsFilled(PaymentSection.VATRate) Then
			VATRate = PaymentSection.VATRate;
		EndIf;
	EndIf;
	
	// Set default payment method for return
	pmSetDefaultPaymentMethodForReturn();

	// The return could be done only if the folio balance is negative
	// otherwise use document Payment
	vFolioObj = Folio.GetObject();
	vFolioBalance = vFolioObj.pmGetBalance('39991231235959');
	SumInFolioCurrency = 0;
	If vFolioBalance < 0 Then
		SumInFolioCurrency = -vFolioBalance;
	EndIf;
	VATSumInFolioCurrency = cmCalculateVATSum(VATRate, SumInFolioCurrency, ?(ValueIsFilled(Payment), Payment.Date, Date));
	
	Sum = Round(cmConvertCurrencies(SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	VATSum = cmCalculateVATSum(VATRate, Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));
	
	// Get parameters for advance and advance settlement
	vAdvancePaymentSection = Undefined;
	vMultipleAdvanceSectionsAreUsed = False;
	vAdvancePaymentSections = New ValueList();
	vAdvanceSettlementPaymentMethod = Undefined;
	cmFillAdvanceAndAdvanceSettlementParameters(Hotel, Author, vAdvancePaymentSection, vAdvanceSettlementPaymentMethod, vMultipleAdvanceSectionsAreUsed, vAdvancePaymentSections);
	If ValueIsFilled(vAdvancePaymentSection) And ValueIsFilled(Folio) And ValueIsFilled(Folio.PaymentSection) Then
		vFolioPaymentSection = Folio.PaymentSection;
		If vFolioPaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment And 
		  (Not ValueIsFilled(vFolioPaymentSection.Hotel) Or vFolioPaymentSection.Hotel = Hotel) Then
			vAdvancePaymentSection = vFolioPaymentSection;
		EndIf;
	EndIf;
	
	// Try to get per payment section balances
	If ValueIsFilled(Hotel) Then
		If Hotel.SplitFolioBalanceByPaymentSections And Not ValueIsFilled(vAdvancePaymentSection) Then
			vPaymentSectionBalances = vFolioObj.pmGetPaymentSectionBalances('39991231235959');
			For Each vPSBalancesRow In vPaymentSectionBalances Do
				If vPSBalancesRow.SumBalance < 0 Then
					vPSRow = PaymentSections.Add();
					vPSRow.PaymentSection = vPSBalancesRow.PaymentSection;
					vPSRow.VATRate = ?(ValueIsFilled(vPSBalancesRow.VATRate), vPSBalancesRow.VATRate, VATRate);
					vPSRow.SumInFolioCurrency = -vPSBalancesRow.SumBalance;
					vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, ?(ValueIsFilled(Payment), Payment.Date, Date));
					vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));
				EndIf;
			EndDo;
		ElsIf Hotel.SplitFolioBalanceByServicesAndPrices Then
			vServicesBalances = vFolioObj.pmGetChequeServicesBalances('39991231235959', Hotel, , Date);
		   	If vMultipleAdvanceSectionsAreUsed And Not Hotel.UsePrepaymentsIfPossible Then
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
						vPSRow.VATRate = vCurAdvancePaymentSection.VATRate;
						vPSRow.MarkingCode = "";
					EndIf;
					For Each vSrvBalancesRow In vServicesBalances Do
						If vSrvBalancesRow.SumBalance < 0 And Not ValueIsFilled(vSrvBalancesRow.ChequeService) Then
							vVATRate = ?(ValueIsFilled(vSrvBalancesRow.VATRate), vSrvBalancesRow.VATRate, VATRate);
							If vPSRow.VATRate = vVATRate Then
								vPSRow.VATRate = vVATRate;
								vPSRow.SumInFolioCurrency = vPSRow.SumInFolioCurrency - vSrvBalancesRow.SumBalance;
								vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
								vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
								vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);  
							EndIf;
						EndIf;
					EndDo;
				EndDo;
			ElsIf Not ValueIsFilled(vAdvancePaymentSection) Then
				For Each vSrvBalancesRow In vServicesBalances Do
					If vSrvBalancesRow.SumBalance < 0 And vSrvBalancesRow.ChequeServiceQuantityBalance <= 0 Then
						vPSRow = PaymentSections.Add();
						vPSRow.ChequeService = vSrvBalancesRow.ChequeService;
						If ValueIsFilled(vPSRow.ChequeService) Then
							vPSRow.PaymentSection = vPSRow.ChequeService.PaymentSection;
						EndIf;
						vPSRow.ChequeServicePrice = vSrvBalancesRow.ChequeServicePrice;
						vPSRow.ChequeServiceQuantity = -vSrvBalancesRow.ChequeServiceQuantityBalance;
						vPSRow.VATRate = ?(ValueIsFilled(vSrvBalancesRow.VATRate), vSrvBalancesRow.VATRate, VATRate);
						vPSRow.SumInFolioCurrency = -vSrvBalancesRow.SumBalance;
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, ?(ValueIsFilled(Payment), Payment.Date, Date));
						vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));
						If vPSRow.ChequeServiceQuantity <> 0 Then
							vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		If Hotel.SplitFolioBalanceByPaymentSections Or 
		   Hotel.SplitFolioBalanceByServicesAndPrices Then
			If ValueIsFilled(vAdvancePaymentSection) And Not Hotel.UsePrepaymentsIfPossible And Not vMultipleAdvanceSectionsAreUsed Then
				i = 0;
				While i < PaymentSections.Count() Do
					vPSRow = PaymentSections.Get(i);
					If vPSRow.PaymentSection <> vAdvancePaymentSection Then
						PaymentSections.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
				PaymentSection = vAdvancePaymentSection;
				// Fill VAT rate from the section
				If ValueIsFilled(PaymentSection) And ValueIsFilled(Company) And Not Company.IsUsingSimpleTaxSystem Then
					If ValueIsFilled(PaymentSection.VATRate) Then
						VATRate = PaymentSection.VATRate;
					EndIf;
				EndIf;
			EndIf;
			If PaymentSections.Count() = 0 Then
				vPSRow = PaymentSections.Add();
				If ValueIsFilled(vAdvancePaymentSection) Then
					vPSRow.PaymentSection = vAdvancePaymentSection;
					vPSRow.VATRate = VATRate;
					vPSRow.Sum = Sum;
					vPSRow.SumInFolioCurrency = SumInFolioCurrency;
					vPSRow.VATSum = VATSum;
					vPSRow.VATSumInFolioCurrency = VATSumInFolioCurrency;
				EndIf;
			EndIf;
			pmCalculateTotalsByPaymentSections();
		EndIf;
	EndIf;
EndProcedure // FillByFolio

// -----------------------------------------------------------------------------
// Fill by Order  
//
// Parameters:
//  pOrder	 - DocumentRef.Order - Base for fill
//
Procedure FillByOrder(pOrder) Export
	If Not ValueIsFilled(pOrder) Then
		Return;
	EndIf;
	If Not ValueIsFilled(pOrder.Folio) Then
		Return;
	EndIf;
	
	// Fill by folio
	FillByFolio(pOrder.Folio);
	If Not ValueIsFilled(Hotel) Then
		Return;
	EndIf;
	Order = pOrder;
	Remarks = Order.Remarks;
	
	// Statistics only
	If ValueIsFilled(Order.Type) And Order.Type.StatisticsOnly Then
		StatisticsOnly = Order.Type.StatisticsOnly;
	EndIf;
	
	// Fill payment by amount from order
	If ValueIsFilled(Order.Currency) Then
		SumInFolioCurrency = cmConvertCurrencies(Order.Sum, Order.Currency, , FolioCurrency, , Date, Hotel);
		VATSumInFolioCurrency = cmCalculateVATSum(VATRate, SumInFolioCurrency, ?(ValueIsFilled(Payment), Payment.Date, Date));
		Sum = cmConvertCurrencies(Order.Sum, Order.Currency, , PaymentCurrency, , Date, Hotel);
		VATSum = cmCalculateVATSum(VATRate, Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));
		If ValueIsFilled(Order.Service) Then
			If Hotel.SplitFolioBalanceByPaymentSections Then
				PaymentSections.Clear();
				vPSRow = PaymentSections.Add();
				vPSRow.PaymentSection = Order.Service.PaymentSection;
				vPSRow.Sum = Sum;
				vPSRow.SumInFolioCurrency = SumInFolioCurrency;
				vPSRow.VATRate = VATRate;
				If ValueIsFilled(vPSRow.PaymentSection) And ValueIsFilled(vPSRow.PaymentSection.VATRate) Then
					vPSRow.VATRate = vPSRow.PaymentSection.VATRate;
				EndIf;
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));
				VATSum = vPSRow.VATSum;
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, ?(ValueIsFilled(Payment), Payment.Date, Date));
				VATSumInFolioCurrency = vPSRow.VATSumInFolioCurrency;
			ElsIf Hotel.SplitFolioBalanceByServicesAndPrices Then
				PaymentSections.Clear();
				vPSRow = PaymentSections.Add();
				vPSRow.ChequeService = Order.Service;
				vPSRow.ChequeServicePrice = Sum;
				vPSRow.ChequeServiceQuantity = 1;
				vPSRow.PaymentSection = vPSRow.ChequeService.PaymentSection;
				vPSRow.Sum = Sum;
				vPSRow.SumInFolioCurrency = SumInFolioCurrency;
				vPSRow.VATRate = VATRate;
				If ValueIsFilled(vPSRow.PaymentSection) And ValueIsFilled(vPSRow.PaymentSection.VATRate) Then
					vPSRow.VATRate = vPSRow.PaymentSection.VATRate;
				EndIf;
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, ?(ValueIsFilled(Payment), Payment.Date, Date));
				VATSum = vPSRow.VATSum;
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, ?(ValueIsFilled(Payment), Payment.Date, Date));
				VATSumInFolioCurrency = vPSRow.VATSumInFolioCurrency;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillByOrder

// -----------------------------------------------------------------------------
Procedure FillByPayment(pPayment)
	If Not ValueIsFilled(pPayment) Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToReturnPayments") Then
		Raise NStr("en='You do not have rights to return payments!';ru='Нет прав на оформление возвратов!';de='Sie haben keine Rechte, eine Rückvergütung zu realisieren!'");
	EndIf;
	
	If ValueIsFilled(pPayment.Hotel) Then
		If Hotel <> pPayment.Hotel Then
			Hotel = pPayment.Hotel;
		EndIf;
	EndIf;
	
	FillPropertyValues(ThisObject, pPayment, , "Number, Date, AccountingDate, Author, DeletionMark, Posted, Hotel, ReferenceNumber, AuthorizationCode, CardOperationDate, Remarks, SlipText, ExternalCode, BonusesAreProcessed, CorrectionOfIncorrectCheque");
	Payment = pPayment;
	If Hotel.PaymentsGenerateInvoices Then
		Invoice = Undefined;
	EndIf;
	
	If pPayment.PaymentSections.Count() > 0 Then
		For Each vPaymentPSRow In pPayment.PaymentSections Do
			vReturnPSRow = PaymentSections.Add();
			FillPropertyValues(vReturnPSRow, vPaymentPSRow);
		EndDo;
	EndIf;
	
	// Set default payment method for return
	If pPayment.PaymentMethod <> Catalogs.PaymentMethods.AdvanceSettlement Then
		pmSetDefaultPaymentMethodForReturn();
	EndIf;
EndProcedure // FillByPayment

// -----------------------------------------------------------------------------
Procedure FillByDepositTransfer(pDepositTransfer)
	If Not ValueIsFilled(pDepositTransfer) Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToReturnPayments") Then
		Raise NStr("en='You do not have rights to return payments!';ru='Нет прав на оформление возвратов!';de='Sie haben keine Rechte, eine Rückvergütung zu realisieren!'");
	EndIf;
	
	If ValueIsFilled(pDepositTransfer.Hotel) Then
		If Hotel <> pDepositTransfer.Hotel Then
			Hotel = pDepositTransfer.Hotel;
		EndIf;
	EndIf;
	
	FillPropertyValues(ThisObject, pDepositTransfer, , "Number, Date, AccountingDate, Author, DeletionMark, Posted, Hotel, Remarks");
	Payment = pDepositTransfer;
	If Hotel.PaymentsGenerateInvoices Then
		Invoice = Undefined;
	EndIf;
	
	If pDepositTransfer.PaymentSections.Count() > 0 Then
		For Each vPaymentPSRow In pDepositTransfer.PaymentSections Do
			vReturnPSRow = PaymentSections.Add();
			FillPropertyValues(vReturnPSRow, vPaymentPSRow);
		EndDo;
	EndIf;
	
	// Set default payment method for return
	If pDepositTransfer.PaymentMethod <> Catalogs.PaymentMethods.AdvanceSettlement Then
		pmSetDefaultPaymentMethodForReturn();
	EndIf;
EndProcedure // FillByPayment

// -----------------------------------------------------------------------------
Function pmIsPrepayment()
	If PaymentMethod = Catalogs.PaymentMethods.Settlement Then
		If ValueIsFilled(Payment) Then
			Return False;
		Else
			Raise NStr("en='Please select guest ledger payment this return is done for!'; ru='Возврат должен быть на основании платежа на Guest ledger!'; de='Bitte wählen Sie Guest ledger Zahlung diese Rückkehr ist getan für!'");
		EndIf;
	Else
		// Get folio balance after payment
		vFolioBalance = Folio.GetObject().pmGetBalance();
		If vFolioBalance = 0 Then
			Return False;
		Else
			Return True;
		EndIf;
	EndIf;
EndFunction // pmIsPrepayment

// -----------------------------------------------------------------------------
Function GetInvoiceForPayment()
	vInv = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Settlements.Ref AS Ref
	|FROM
	|	Document.Settlement AS Settlements
	|WHERE
	|	Settlements.Posted
	|	AND Settlements.Sum = &qPaymentSum
	|	AND BEGINOFPERIOD(Settlements.Date, DAY) = &qPaymentDate
	|
	|ORDER BY
	|	Settlements.PointInTime DESC";
	vQry.SetParameter("qPaymentSum", Payment.Sum);
	vQry.SetParameter("qPaymentDate", BegOfDay(Payment.Date));
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vInv = vDocsRow.Ref;
		Break;
	EndDo;
	Return vInv;
EndFunction // GetInvoiceForPayment

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
WasPosted = True;

#EndRegion
