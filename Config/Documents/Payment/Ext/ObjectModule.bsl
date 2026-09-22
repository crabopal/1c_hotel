
#Region Variables

Var WasPosted;

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// User activity history   
	vEventDescription = StrTemplate(NStr("en = 'Document deletion: %1, %2, %3'; 
										 |de = 'Unmittelbare Löschung: %1, %2, %3'; 
										 |ru = 'Непосредственное удаление: %1, %2, %3'"), TrimAll(Payer), cmFormatSum(Sum, PaymentCurrency), TrimAll(Ref));  
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
	ReferenceNumber = "";
	AuthorizationCode = "";
	TerminalNumber = "";
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
			vBPRef = pmGetBonusesPayment();
			If ValueIsFilled(vBPRef) And Not vBPRef.DeletionMark Then
				vBPRef.GetObject().SetDeletionMark(True);
			EndIf;
		EndIf;
		If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
			vInvRef = pmGetPaymentInvoice();
			If ValueIsFilled(vInvRef) And Not vInvRef.DeletionMark Then
				vInvRef.GetObject().SetDeletionMark(True);
			EndIf;
		EndIf;
	EndIf;   
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Folio") Then
			FillByFolio(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Preauthorisation") Then
			FillByPreauthorisation(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Payment") Then
			FillByPayment(pBase);
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
		If Not (PaymentMethod.IsByBonuses And ValueIsFilled(PaymentMethod.DiscountType) And PaymentMethod.DiscountType.ExternalBonusSystemIsUsed And Not ValueIsFilled(PaymentMethod.ExternalSystem)) Then 
			vOldBonusesSystemScheme = ValueIsFilled(PaymentMethod) And PaymentMethod.IsByBonuses And ValueIsFilled(PaymentMethod.DiscountType) And Not ValueIsFilled(PaymentMethod.ExternalSystem);
			If Not vOldBonusesSystemScheme And ((PaymentMethod.IsByBonuses Or PaymentMethod.IsByGiftCertificate) And Not ValueIsFilled(DiscountCard)) And (IsBlankString(GiftCertificate) And Not DiscountCard.DiscountType.IsAccumulatingDiscount) Then
				pCancel = True;
				vMessageTemplete = Nstr("en = 'To pay with a %1, you must specify a %2!'; de = 'Um mit einem %1 zu bezahlen, müssen Sie eine %2 angeben!'; ru = 'Для оплаты %1 необходимо указать %2!'");
				vDiscType = ?(PaymentMethod.IsByBonuses,Nstr("en = 'bonuses'; de = 'Boni'; ru = 'бонусами'"),Nstr("en = 'certificate'; de = 'Zertifikat'; ru = 'сертификатом'"));
				vAction = ?(PaymentMethod.IsByBonuses,Nstr("en = 'loyalty card'; de = 'Bonikarte'; ru = 'карту лояльности'"),Nstr("en = 'gift card'; de = 'Geschenkkarte'; ru = 'подарочную карту'"));
				vMessage = StrTemplate(vMessageTemplete, vDiscType, vAction);
			EndIf;
			If vOldBonusesSystemScheme Then
				pCancel = Not CheckBonusesBalance(vMessage);
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
		EndIf;
		If ValueIsFilled(Folio) And (ValueIsFilled(Folio.Customer) 
		   And Folio.Customer <> AccountingCustomer Or Not ValueIsFilled(Folio.Customer) And ValueIsFilled(AccountingCustomer) And ValueIsFilled(Hotel) And Hotel.IndividualsCustomer <> AccountingCustomer) Then
		   
		   // User activity history   
		   vEventDescription = StrTemplate(NStr("en = 'Payment customer and folio differ: %1 <> %2, %3'; 
		   										|de = 'Zahlungskunde und Folio unterscheiden sich: %1 <> %2, %3'; 
												|ru = 'Контрагент платежа и фолио отличаются: %1 <> %2, %3'"), TrimAll(AccountingCustomer), TrimAll(Folio.Customer), cmFormatSum(Sum, PaymentCurrency));  
		   vParentDoc = Ref;
		   If ValueIsFilled(ParentDoc) Then
			   vParentDoc = ParentDoc;
		   EndIf;	
           InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel)
		EndIf;
		If ValueIsFilled(Folio) And ValueIsFilled(Folio.Contract) 
			And Folio.Contract <> AccountingContract Then
			// User activity history   
			vEventDescription = StrTemplate(NStr("en = 'Payment contracts and folio differ: %1 <> %2, %3'; 
												 |de = 'Zahlungsverträge und folio unterscheiden sich: %1 <> %2, %3'; 
												 |ru = 'Договор платежа и фолио отличаются: %1 <> %2, %3'"), TrimAll(AccountingContract), TrimAll(Folio.Contract), cmFormatSum(Sum, PaymentCurrency));  
			vParentDoc = Ref;
			If ValueIsFilled(ParentDoc) Then
				vParentDoc = ParentDoc;
			EndIf;	
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel)
		EndIf;
		If ValueIsFilled(Folio) And ValueIsFilled(Folio.GuestGroup) 
		   And Folio.GuestGroup <> GuestGroup Then
			// User activity history   
			vEventDescription = StrTemplate(NStr("en = 'Payment guest group contracts and folio differ: %1 <> %2, %3'; 
												 |de = 'Zahlungsgastgruppenverträge und Folio unterscheiden sich: %1 <> %2, %3'; 
												 |ru = 'Группа платежа и фолио отличаются: %1 <> %2, %3'"), TrimAll(GuestGroup), TrimAll(Folio.GuestGroup), cmFormatSum(Sum, PaymentCurrency));  
			vParentDoc = Ref;
			If ValueIsFilled(ParentDoc) Then
				vParentDoc = ParentDoc;
			EndIf;	
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel)
		EndIf;
		AdditionalProperties.Insert("OldPaymentMethod", Ref.PaymentMethod);
	Else
		If DeletionMark Then
			// User activity history   
			vEventDescription = StrTemplate(NStr("en = 'Set document deletion mark payment: %1, %2, %3'; 
												 |de = 'Legen Sie die Zahlung für die Löschmarkierung des Dokuments fest: %1, %2, %3'; 
												 |ru = 'Установка отметки удаления платежа: %1, %2, %3'"), TrimAll(Payer), cmFormatSum(Sum, PaymentCurrency), TrimAll(Ref));  
			vParentDoc = Ref;
			If ValueIsFilled(ParentDoc) Then
				vParentDoc = ParentDoc;
			EndIf;	
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel);

			AuthorOfAnnulation = SessionParameters.CurrentUser;
			DateOfAnnulation = CurrentSessionDate();
		EndIf;
	EndIf;
	WasPosted = Posted;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not ValueIsFilled(PaymentMethod) Then
		pCancel = True;
		Return;
	EndIf;
	vIsGiftCardTopUp = ValueIsFilled(DiscountCard) And DiscountCard.LoyaltyType = Enums.LoyaltyType.Certificate And 
	                   Not (PaymentMethod.IsByBonuses Or PaymentMethod.IsByGiftCertificate);
	
	vTransferBalanceCard = GetDiscountCardByFolio(Folio);
	If ValueIsFilled(vTransferBalanceCard) And (vTransferBalanceCard.LoyaltyType = Enums.LoyaltyType.Certificate Or vTransferBalanceCard.LoyaltyType = Enums.LoyaltyType.Bonuses) Then
		vIsGiftCardTopUp = True;
	EndIf;
	
	// 1. Post to Folio payments
	PostToFolioPayments();

	// 2. Post to Accounts
	If Not PaymentMethod.IsCloseToTheRoom And Not PaymentMethod.IsCloseToTheFolio Then
		PostToAccounts(vIsGiftCardTopUp);
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
	If PaymentMethod <> Catalogs.PaymentMethods.Settlement And 
	   Not PaymentMethod.IsCloseToTheRoom And 
	   Not PaymentMethod.IsCloseToTheFolio And 
	   Not StatisticsOnly Then
	   
		// 5. Post to Customer accounts
		If Not vIsGiftCardTopUp Then
			PostToCustomerAccounts();
		EndIf;
		
		// 6. Post to Payment services
		If Not vIsGiftCardTopUp Then
			If Hotel.DoPaymentsDistributionToServices Then
				PostToPaymentServices();
			EndIf;
		EndIf;
		
		// 7. Close preauthorisation
		If ValueIsFilled(Preauthorisation) Then
			ClosePreauthorisation();
		EndIf;
		
		If Not vIsGiftCardTopUp Then
			// 8. Repost settlements if any
			pmRepostSettlements();
			
			// 9. Set hotel product payment date
			FillHotelProductPaymentDate();
		EndIf;
		
		// 10. Write off bonuses and process gift certificates (obsolet scheme)
		WriteOffBonusesObsolete();
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.ReportingCurrency) And 
		   ValueIsFilled(PaymentMethod) And Not IsBlankString(GiftCertificate) Then
			PostToGiftCertificatesObsolete();
		EndIf;
		
		// 11. Write off bonuses or certificate (active scheme)
		If Not ValueIsFilled(PaymentMethod.ExternalSystem) And 
		   Not vIsGiftCardTopUp And 
		   (PaymentMethod.IsByBonuses Or PaymentMethod.IsByGiftCertificate) And 
		   ValueIsFilled(DiscountCard) And ValueIsFilled(DiscountCard.DiscountType) And 
		   Not DiscountCard.DiscountType.IsAccumulatingDiscount Then
			vMessage = "";
			pCancel	= PostBonusesPayment(vMessage);
			If pCancel	Then
				Raise vMessage; 
			EndIf;
		EndIf;
		
		// 12. Activate certificate (active scheme)
		If vIsGiftCardTopUp Then
			ActivateGiftCertificate(pCancel);
		EndIf;
		
		// 13. Send payment SMS
		If Not WasPosted Then
			vMessageDeliveryError = "";
			If Not SMS.SendPaymentMessage(Payer, GuestGroup, ParentDoc, cmFormatSum(Sum, PaymentCurrency), PaymentMethod, Ref, vMessageDeliveryError) Then
				WriteLogEvent(NStr("en='Document.MessageDelivery';ru='Документ.РассылкаСообщений';de='Document.MessageDelivery'"), EventLogLevel.Warning, Metadata(), Ref, vMessageDeliveryError);
				tcCommonFunctionOnClientServer.TextMessage(vMessageDeliveryError, MessageStatus.Attention);
			EndIf;
		EndIf;
	Else
		If PaymentMethod = Catalogs.PaymentMethods.Settlement Then
			// 12. Activate certificate
			If vIsGiftCardTopUp Then
				ActivateGiftCertificate(pCancel);
			EndIf;
		EndIf;
		
		// 13. Repost settlements if any
		pmRepostSettlements();
	EndIf;

	// 14. Create invoice if necessary
	If Not PaymentMethod.IsCloseToTheRoom And Not PaymentMethod.IsCloseToTheFolio Then
		If ValueIsFilled(Folio) And ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
			vInvoice = pmGetPaymentInvoice();
			If Not ValueIsFilled(vInvoice) Then
				If Not vIsGiftCardTopUp Then
					// Check if this is advance payment
					vIsPrepayment = pmIsPrepayment();
				Else
					vIsPrepayment = True;
				EndIf;
				If Not vIsPrepayment Then
					// Generate invoice
					vInvObj = Documents.Settlement.CreateDocument();
					vInvObj.Date = Date + 1;
					vInvObj.Fill(Ref);
					If vInvObj.Services.Count() = 0 Then
						vIsPrepayment = True;
					Else
						// If this is city ledger payment then use FIFO to get payment amount equal to the invoice amount
						If PaymentMethod = Catalogs.PaymentMethods.Settlement Then
							i = 0;
							vPayedSum = Round(cmConvertCurrencies(Sum, PaymentCurrency, PaymentCurrencyExchangeRate, vInvObj.AccountingCurrency, , ExchangeRateDate, Hotel), 2);
							For Each vPDRow In vInvObj.PaymentDocuments Do
								vPayedSum = vPayedSum + vPDRow.Sum;
							EndDo;
							vPaymentSum = 0;
							vInvRowsWereDeleted = False;
							While i < vInvObj.Services.Count() Do
								vSrvRow = vInvObj.Services.Get(i);
								vPaymentSum = vPaymentSum + Round(cmConvertCurrencies(vSrvRow.Sum, vInvObj.AccountingCurrency, , PaymentCurrency, , ExchangeRateDate, Hotel), 2);
								If vPaymentSum > vPayedSum Then
									vInvRowsWereDeleted = True;
									vInvObj.Services.Delete(i);
								Else
									i = i + 1;
								EndIf;
							EndDo;
							// Recalculate invoice amounts
							If vInvRowsWereDeleted Then
								vInvObj.Sum = vInvObj.Services.Total("Sum");
								vInvObj.VATSum = vInvObj.Services.Total("VATSum");
								vInvObj.CommissionSum = vInvObj.Services.Total("CommissionSum");
								vInvObj.SumDue = vInvObj.Sum - vInvObj.PaymentDocuments.Total("Sum");
								// Correct payment amount
								If vInvObj.Sum <> vPayedSum Then
									Raise NStr("en='Wrong payment amount! Amount should be total of some charge amounts'; ru='Неверная сумма платежа! Сумма должна быть итогом для некоторых начислений'; de='Falsche Zahlung! Der Betrag sollte die Summe für einige Abrechnungen sein'");
								EndIf;
							EndIf;
						EndIf;
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
			Else
				If TypeOf(vInvoice) = Type("DocumentRef.ProformaInvoice") Then
					vPaymentSum = Round(cmConvertCurrencies(Sum, PaymentCurrency, PaymentCurrencyExchangeRate, vInvoice.AccountingCurrency, vInvoice.AccountingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					If vInvoice.Sum <> vPaymentSum Or 
					   (AdditionalProperties.Property("OldPaymentMethod") 
					    And ValueIsFilled(AdditionalProperties.OldPaymentMethod) 
					    And AdditionalProperties.OldPaymentMethod <> PaymentMethod) Then
						vInvObj = vInvoice.GetObject();
						i = 0;
						While i < vInvObj.Services.Count() Do
							If i = 0 Then
								vSrvRow = vInvObj.Services.Get(i);
								vSrvRow.Price = vPaymentSum;
								vSrvRow.Quantity = 1;
								vSrvRow.Sum = vPaymentSum;
								vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vPaymentSum, Date);
								vSrvRow.DiscountSum = 0;
								vSrvRow.Discount = 0;
								vSrvRow.AgentCommission = 0;
								vSrvRow.CommissionSum = 0;
								vSrvRow.VATCommissionSum = 0;
								vSrvRow.Remarks = vInvObj.pmSetPaymentMethodInServiceRemarks(vSrvRow.Remarks, PaymentMethod);
								i = i + 1;
							Else
								vInvObj.Services.Delete(i);
							EndIf;
						EndDo;
						vInvObj.Sum = vInvObj.Services.Total("Sum");
						vInvObj.VATSum = vInvObj.Services.Total("VATSum");
						vInvObj.Write(DocumentWriteMode.Posting);
					EndIf;
				EndIf;
			EndIf;					
		EndIf;
	EndIf;
	
	// Save data if there were changes
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
	
	// 15. Post to Invoice accounts
	If PaymentMethod <> Catalogs.PaymentMethods.Settlement And Not PaymentMethod.IsCloseToTheRoom And Not PaymentMethod.IsCloseToTheFolio Then
		If Not vIsGiftCardTopUp Then
			PostToInvoiceAccounts();
		EndIf;
	EndIf;
	
	// 16. Post to FO chart of accounts
	PostToFOChartOfAccounts();    
	
	// 17. Post to labeled goods    
	PostToLabeledGoods();	
EndProcedure // Posting

#EndRegion 

#Region Public

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
		vMsgTextRu = vMsgTextRu + "Итог по платежу зачета аванса должен быть равен 0!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "The total for the advance payment settlement must be 0!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Der Gesamtbetrag für den Vorauszahlungsbetrag Begleichung muss 0 sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Sum", pAttributeInErr);
	ElsIf PaymentMethod = Catalogs.PaymentMethods.Settlement And ValueIsFilled(Hotel) And Not cmCheckUserPermissions("HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios") And 
	     (Not ValueIsFilled(AccountingCustomer) Or ValueIsFilled(AccountingCustomer) And AccountingCustomer = Hotel.IndividualsCustomer) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Закрывать долг по лицевому счету можно только, если указан контрагент!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "You can not close folio debt to city ledger for unspecified customer!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Sie können die Folio-Schulden für Einzelpersonen nicht mit dem City-Ledger abschließen!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCustomer", pAttributeInErr);
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
	If ValueIsFilled(PaymentMethod) Then
		If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
			If Not SessionParameters.CurrentWorkstation.HasConnectionToCreditCardsProcessingSystem Or 
			   PaymentMethod.ExternalBankTerminalIsUsed Then
				If PaymentMethod.AuthorizationCodeIsRequired And IsBlankString(AuthorizationCode) Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "При оплате кредитной картой должен быть введен реквизит <Код авторизации>!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "<Authorization code> attribute should be filled for credit card payment!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "<Authorization code> attribute should be filled for credit card payment!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "AuthorizationCode", pAttributeInErr);
				EndIf;
				If PaymentMethod.ReferenceCodeIsRequired And IsBlankString(ReferenceNumber) Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "При оплате кредитной картой должен быть введен реквизит <Референс номер>!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "<Reference number> attribute should be filled for credit card payment!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "<Reference number> attribute should be filled for credit card payment!" + Chars.LF;
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
	If ValueIsFilled(Hotel) And ValueIsFilled(PaymentMethod) And PaymentMethod.BookByCashRegister Then
		If Not cmCheckUserPermissions("HavePermissionToPostPaymentsWithEmptyPaymentSections") Then
			If Not Hotel.SplitFolioBalanceByPaymentSections And Not Hotel.SplitFolioBalanceByServicesAndPrices Then
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
	If IsBlankString(ExternalCode) Then
		If Sum < 0 Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Для оформления возврата необходимо использовать документ ""Возврат""!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Use ""Return"" document to return money!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Use ""Return"" document to return money!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Sum", pAttributeInErr);
		ElsIf PaymentMethod <> Catalogs.PaymentMethods.AdvanceSettlement Then
			For Each vPSRow In PaymentSections Do
				If vPSRow.Sum < 0 Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Для оформления возврата необходимо использовать документ ""Возврат""!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Use ""Return"" document to return money!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Use ""Return"" document to return money!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "PaymentSections", pAttributeInErr);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If ValueIsFilled(AccountingCustomer) And AccountingCustomer.NonResident And Not AccountingCustomer.IsIndividual And 
	   ValueIsFilled(Hotel) And ValueIsFilled(Hotel.Citizenship) And Hotel.Citizenship.Code = 643 Then // Russia only
		If ValueIsFilled(PaymentMethod) And PaymentMethod.PrintCheque And  
		  (PaymentMethod.IsByCash Or PaymentMethod.IsByCreditCard) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Принимать платежи наличными от контрагентов нерезидентов запрещено!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Cash payments are forbidden from non-resident customers!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Cash payments are forbidden from non-resident customers!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "PaymentMethod", pAttributeInErr);
		EndIf;
	EndIf;
	If Not Posted Then
		// Check user rights to do payment
		vEmployee = SessionParameters.CurrentUser;
		If ValueIsFilled(vEmployee) And ValueIsFilled(vEmployee.PermissionGroup) And ValueIsFilled(Folio) Then
			vPermissionGroup = vEmployee.PermissionGroup;
			For Each vPrmRow In vPermissionGroup.FolioOperationsAllowed Do
				If IsBlankString(vPrmRow.FolioType) Or 
				   Not IsBlankString(vPrmRow.FolioType) And TrimR(vPrmRow.FolioType) = Left(TrimR(Folio.Description), StrLen(TrimR(vPrmRow.FolioType))) Then
					If vPrmRow.PaymentsForbidden Then
						vHasErrors = True;
						vMsgTextRu = vMsgTextRu + "Нет прав на оформление платежей по фолио с типом " + TrimAll(Folio.Description) + "!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "You do not have rights to do payment to folio type " + TrimAll(Folio.Description) + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Sie haben keine Rechte zu tun Zahlung zum Folio-typ " + TrimAll(Folio.Description) + "!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Folio", pAttributeInErr);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Check zero amount
		If Sum = 0 And ValueIsFilled(Hotel) And Not Hotel.SplitFolioBalanceByServicesAndPrices And Not Hotel.SplitFolioBalanceByPaymentSections Then
			vHasErrors = True;
			vMsgTextRu = vMsgTextRu + "Сумма платежа не должна быть равна 0!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Payment amount should not be equal to 0!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Der Betrag der Zahlung muss nicht gleich 0 sein!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Sum", pAttributeInErr);
		EndIf;
	EndIf;
	If ValueIsFilled(PaymentMethod) Then
		If PaymentMethod.NoAdvances Then
			For Each vRow In PaymentSections Do
				If ValueIsFilled(vRow.PaymentSection) And vRow.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then 
					vHasErrors = True;
					vMsgTextRu = vMsgTextRu + StrTemplate("Оплачивать аванс методом оплаты %1 запрещено!",PaymentMethod) + Chars.LF;
					vMsgTextEn = vMsgTextEn + StrTemplate("It is forbidden to pay in advance by payment method %1!",PaymentMethod) + Chars.LF;
					vMsgTextDe = vMsgTextDe + StrTemplate("Es ist verboten, im Voraus per Zahlungsmethode %1 zu bezahlen!",PaymentMethod) + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "PaymentSections", pAttributeInErr);
					Break;
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
			SetNewObjectRef(Documents.Payment.GetRef());
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
		If Not ValueIsFilled(PaymentCurrency) Then
			PaymentCurrency = Hotel.BaseCurrency;
			If ValueIsFilled(SessionParameters.CurrentWorkstation) And ValueIsFilled(SessionParameters.CurrentWorkstation.DefaultPaymentCurrency) Then
				PaymentCurrency = SessionParameters.CurrentWorkstation.DefaultPaymentCurrency;
			EndIf;
		EndIf;
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
			vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);

			vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, PaymentCurrency, PaymentCurrencyExchangeRate, 
			                                                      FolioCurrency, FolioCurrencyExchangeRate, 
			                                                      ExchangeRateDate, Hotel), 2);
			vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
		EndDo;
		pmCalculateTotalsByPaymentSections();
	Else
		VATSum = cmCalculateVATSum(VATRate, Sum, Date);
		SumInFolioCurrency = Round(cmConvertCurrencies(Sum, PaymentCurrency, PaymentCurrencyExchangeRate, 
		                                               FolioCurrency, FolioCurrencyExchangeRate, 
		                                               ExchangeRateDate, Hotel), 2);
		VATSumInFolioCurrency = cmCalculateVATSum(VATRate, SumInFolioCurrency, Date);
	EndIf;
EndProcedure // pmRecalculateSums

// -----------------------------------------------------------------------------
// Fill by folio  
//
// Parameters:
//  pFolio	 - DocumentRef.Folio - Base for fill
//
Procedure FillByFolio(pFolio) Export
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
	FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ExchangeRateDate);
	
	// Fill payment method
	vSkipFillPM = False;
	If AdditionalProperties.Property("SkipFillPaymentMethod") Then
		vSkipFillPM = AdditionalProperties.SkipFillPaymentMethod;
	EndIf;
	If Not vSkipFillPM Then
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
			If ValueIsFilled(ParentDoc.DiscountCard) 
				And (ParentDoc.DiscountCard.LoyaltyType = Enums.LoyaltyType.Certificate 
					Or ParentDoc.DiscountCard.LoyaltyType = Enums.LoyaltyType.Bonuses) Then
				DiscountCard = ParentDoc.DiscountCard;
			EndIf;
		EndIf;
		If ValueIsFilled(Folio) Then
			If ValueIsFilled(Folio.PaymentMethod) Then
				PaymentMethod = Folio.PaymentMethod;
			EndIf;
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
	If ValueIsFilled(Folio.Customer) And Folio.Customer.IsIndividual Then
		If ValueIsFilled(Folio.Client) Then
			If lower(TrimAll(Folio.Client.FullName)) <> lower(TrimAll(Folio.Customer.LegacyName)) And 
			   lower(TrimAll(Folio.Client.FullName)) <> lower(TrimAll(Folio.Customer.Description)) Then
				Payer = Folio.Customer;
			Else
				Payer = Folio.Client;
			EndIf;
		Else
			Payer = Folio.Customer;
		EndIf;
	ElsIf ValueIsFilled(Folio.Client) Then
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
	
	// The payment could be done only if the folio balance is positive
	// otherwise use document Return
	vBalanceDate = '39991231235959';
	If AdditionalProperties.Property("UseDateToGetBalance") And AdditionalProperties.UseDateToGetBalance Then
		vBalanceDate = Date;
	EndIf;
	vFolioObj = Folio.GetObject();
	vFolioBalance = vFolioObj.pmGetBalance(vBalanceDate);
	SumInFolioCurrency = 0;
	If vFolioBalance > 0 Then
		SumInFolioCurrency = vFolioBalance;
	EndIf;
	VATSumInFolioCurrency = cmCalculateVATSum(VATRate, SumInFolioCurrency, Date);
	
	Sum = Round(cmConvertCurrencies(SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	VATSum = cmCalculateVATSum(VATRate, Sum, Date);
	
	// Get parameters for advance and advance settlement
	vAdvanceMode = False;
	vPrepaymentMode = False;
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
	If vMultipleAdvanceSectionsAreUsed And ValueIsFilled(Folio) And 
	   ValueIsFilled(Folio.PaymentSection) And Folio.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
		vMultipleAdvanceSectionsAreUsed = False;
		vAdvancePaymentSection = Folio.PaymentSection;
	EndIf;
	
	// Advance amount
	vAdvanceAmount = 0;
	vAdvanceSettlementMode = False;
	If ValueIsFilled(vAdvancePaymentSection) Then
		If AdditionalProperties.Property("AdvanceSettlementMode") And AdditionalProperties.AdvanceSettlementMode And ValueIsFilled(vAdvanceSettlementPaymentMethod) Then
			vAdvanceSettlementMode = True;
		Else
			// Check conditions of if advance mode is possible 
			vAdvanceMode = ?(AdditionalProperties.Property("AdvanceMode"), AdditionalProperties.AdvanceMode, True);
			vPrepaymentMode = ?(AdditionalProperties.Property("PrepaymentMode"), AdditionalProperties.PrepaymentMode, False);
			If Not AdditionalProperties.Property("AdvanceMode") Then
				If ValueIsFilled(Hotel) And ValueIsFilled(Folio) And Hotel.AlwaysUseAdvancesIfFolioDescriptionIsEmpty And IsBlankString(Folio.Description) Then
					If Hotel.UsePrepaymentsIfPossible Then
						vThereAreCharges = False;
						vThereAreFutureCharges = False;
						vMaxChargesDates = cmGetFolioMaxChargingDate(Folio);
						If vMaxChargesDates.Count() > 0 Then
							vHotelAccountingDate = tcOnServer.GetForecastStartDate(Hotel);
							vMaxChargesDatesRow = vMaxChargesDates.Get(0);
							If vMaxChargesDatesRow.ServiceDate > vHotelAccountingDate Then
								vThereAreFutureCharges = True;
							Else
								vThereAreCharges = True;
							EndIf;
						Else
							vThereAreCharges = True;
						EndIf;
						If (vThereAreCharges Or vThereAreFutureCharges) And Hotel.SplitFolioBalanceByServicesAndPrices Then
							vAdvanceMode = False;
							vPrepaymentMode = True;
						Else
							vAdvanceMode = True;
							vPrepaymentMode = False;
						EndIf;
					Else
						vAdvanceMode = True;
						vPrepaymentMode = False;
					EndIf;
				Else
					vFolioBalanceIsZero = ?(Sum = 0, True, False);
					vAdvancePaymentSectionBalanceIsZero = True;
					vAdvancePaymentSectionBalances = vFolioObj.pmGetPaymentSectionBalances(vBalanceDate, Hotel, , True);
					If vAdvancePaymentSectionBalances.Count() > 0 Then
						If vAdvancePaymentSectionBalances.Count() = 1 Then
							vPSBalancesRow = vAdvancePaymentSectionBalances.Get(0);
							If vPSBalancesRow.SumBalance <> 0 Then
								vAdvancePaymentSectionBalanceIsZero = False;
							EndIf;
						Else
							vAdvancePaymentSectionBalanceIsZero = False;
						EndIf;
					EndIf;
					vThereAreCharges = False;
					vThereAreFutureCharges = False;
					vMaxChargesDates = cmGetFolioMaxChargingDate(Folio);
					If vMaxChargesDates.Count() > 0 Then
						vHotelAccountingDate = tcOnServer.GetForecastStartDate(Hotel);
						vMaxChargesDatesRow = vMaxChargesDates.Get(0);
						If vMaxChargesDatesRow.ServiceDate > vHotelAccountingDate Then
							vThereAreFutureCharges = True;
						Else
							vThereAreCharges = True;
						EndIf;
					Else
						vThereAreCharges = True;
					EndIf;
					If vThereAreFutureCharges And ValueIsFilled(Hotel) And Hotel.SplitFolioBalanceByServicesAndPrices And Hotel.UsePrepaymentsIfPossible Then
						vAdvanceMode = False;
						vPrepaymentMode = True;
					ElsIf Not vThereAreFutureCharges And vThereAreCharges And 
						  Not vFolioBalanceIsZero And vAdvancePaymentSectionBalanceIsZero And 
						  ValueIsFilled(Hotel) And Hotel.SplitFolioBalanceByServicesAndPrices Then
						vAdvanceMode = False;
						vPrepaymentMode = False;
					Else
						If vAdvancePaymentSectionBalanceIsZero And Not vFolioBalanceIsZero Then
							If Hotel.UsePrepaymentsIfPossible Then
								vAdvanceMode = False;
								vPrepaymentMode = False;
							EndIf;
						ElsIf Not vAdvancePaymentSectionBalanceIsZero And Not vFolioBalanceIsZero Then
							If Hotel.UsePrepaymentsIfPossible Then
								vAdvanceMode = False;
								vPrepaymentMode = True;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Try to get per payment section balances
	If ValueIsFilled(Hotel) Then
		If Hotel.SplitFolioBalanceByPaymentSections Then
			If ValueIsFilled(vAdvancePaymentSection) Then
				If ValueIsFilled(PaymentSection) Then
					If vAdvanceSettlementMode And ValueIsFilled(vAdvanceSettlementPaymentMethod) Then
						PaymentSection = Undefined;
					ElsIf vPrepaymentMode Then
						PaymentSection = Undefined;
					EndIf;
				EndIf;
				If vAdvanceSettlementMode And ValueIsFilled(vAdvanceSettlementPaymentMethod) Then
					vPaymentSectionBalances = vFolioObj.pmGetPaymentSectionBalances(vBalanceDate);
					For Each vPSBalancesRow In vPaymentSectionBalances Do
						If vPSBalancesRow.SumBalance < 0 Then
							If vPSBalancesRow.PaymentSection = vAdvancePaymentSection Then
								vAdvanceAmount = -vPSBalancesRow.SumBalance;
								vPSRow = PaymentSections.Add();
								vPSRow.PaymentSection = vPSBalancesRow.PaymentSection;
								vPSRow.VATRate = ?(ValueIsFilled(vPSBalancesRow.VATRate), vPSBalancesRow.VATRate, VATRate);
								vPSRow.SumInFolioCurrency = vPSBalancesRow.SumBalance;
								vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
								vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
								vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
							EndIf;
						EndIf;					
					EndDo;
					For Each vPSBalancesRow In vPaymentSectionBalances Do
						If vPSBalancesRow.SumBalance > 0 Then
							If vAdvanceAmount <= 0 Then
								Break;
							EndIf;
							If vPSBalancesRow.SumBalance > vAdvanceAmount Then
								vPSBalancesRow.SumBalance = vAdvanceAmount;
							EndIf;
							vAdvanceAmount = vAdvanceAmount - vPSBalancesRow.SumBalance;
							
							vPSRow = PaymentSections.Add();
							vPSRow.PaymentSection = vPSBalancesRow.PaymentSection;
							vPSRow.VATRate = ?(ValueIsFilled(vPSBalancesRow.VATRate), vPSBalancesRow.VATRate, VATRate);
							vPSRow.SumInFolioCurrency = vPSBalancesRow.SumBalance;
							vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
							vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
							vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
						EndIf;
					EndDo;
				ElsIf vAdvanceMode Then
					// Add folio balance as advance record
					vSumBalance = vFolioObj.pmGetBalance(vBalanceDate);
					If vSumBalance > 0 Then
						vPSRow = PaymentSections.Add();
						vPSRow.PaymentSection = vAdvancePaymentSection;
						vPSRow.SumInFolioCurrency = vSumBalance;
						If Company.IsUsingSimpleTaxSystem Then
							vPSRow.VATRate = VATRate;
						Else
							If ValueIsFilled(vAdvancePaymentSection.VATRate) Then
								vPSRow.VATRate = vAdvancePaymentSection.VATRate;
							Else
								vPSRow.VATRate = VATRate;
							EndIf;
						EndIf;
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
						vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
					EndIf;
					PaymentSection = vAdvancePaymentSection;
					// Fill VAT rate from the section
					If ValueIsFilled(PaymentSection) And ValueIsFilled(Company) And Not Company.IsUsingSimpleTaxSystem Then
						If ValueIsFilled(PaymentSection.VATRate) Then
							VATRate = PaymentSection.VATRate;
						EndIf;
					EndIf;
				Else
					vPaymentSectionBalances = vFolioObj.pmGetPaymentSectionBalances(vBalanceDate);
					For Each vPSBalancesRow In vPaymentSectionBalances Do
						If vPSBalancesRow.SumBalance > 0 And vPSBalancesRow.PaymentSection <> vAdvancePaymentSection Then
							vPSRow = PaymentSections.Add();
							vPSRow.PaymentSection = vPSBalancesRow.PaymentSection;
							vPSRow.VATRate = ?(ValueIsFilled(vPSBalancesRow.VATRate), vPSBalancesRow.VATRate, VATRate);
							vPSRow.SumInFolioCurrency = vPSBalancesRow.SumBalance;
							vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
							vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
							vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
						EndIf;
					EndDo;
				EndIf;
			Else
				vPaymentSectionBalances = vFolioObj.pmGetPaymentSectionBalances(vBalanceDate);
				For Each vPSBalancesRow In vPaymentSectionBalances Do
					If vPSBalancesRow.SumBalance > 0 Then
						vPSRow = PaymentSections.Add();
						vPSRow.PaymentSection = vPSBalancesRow.PaymentSection;
						vPSRow.VATRate = ?(ValueIsFilled(vPSBalancesRow.VATRate), vPSBalancesRow.VATRate, VATRate);
						vPSRow.SumInFolioCurrency = vPSBalancesRow.SumBalance;
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
						vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
					EndIf;
				EndDo;
			EndIf;
		ElsIf Hotel.SplitFolioBalanceByServicesAndPrices Then
			If ValueIsFilled(vAdvancePaymentSection) Then
				If ValueIsFilled(PaymentSection) Then
					If vAdvanceSettlementMode And ValueIsFilled(vAdvanceSettlementPaymentMethod) Then
						PaymentSection = Undefined;
					ElsIf vPrepaymentMode Then
						PaymentSection = Undefined;
					ElsIf Not vAdvanceMode And vThereAreCharges And Not vThereAreFutureCharges Then
						PaymentSection = Undefined;
					EndIf;
				EndIf;
				If vAdvanceSettlementMode And ValueIsFilled(vAdvanceSettlementPaymentMethod) Then
					vServicesBalances = vFolioObj.pmGetChequeServicesBalances(vBalanceDate, Hotel, , Date);
					For Each vSrvBalancesRow In vServicesBalances Do
						vRowPS = vSrvBalancesRow.PaymentSection;
						If vSrvBalancesRow.SumBalance < 0 Then
							If ValueIsFilled(vRowPS) And vRowPS.ChequeItemType = Enums.ChequeItemTypes.Payment Then
								vAdvanceAmount = vAdvanceAmount - vSrvBalancesRow.SumBalance;
								
								vPSRow = PaymentSections.Add();
								vPSRow.PaymentSection = vSrvBalancesRow.PaymentSection;
								vPSRow.ChequeService = vSrvBalancesRow.ChequeService;
								vPSRow.ChequeServicePrice = vSrvBalancesRow.ChequeServicePrice;
								vPSRow.ChequeServiceQuantity = vSrvBalancesRow.ChequeServiceQuantityBalance;
								vPSRow.VATRate = ?(ValueIsFilled(vSrvBalancesRow.VATRate), vSrvBalancesRow.VATRate, VATRate);
								vPSRow.SumInFolioCurrency = vSrvBalancesRow.SumBalance;
								vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
								vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
								vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);   
								vPSRow.MarkingCode = vSrvBalancesRow.MarkingCode;
								vPSRow.Item = vSrvBalancesRow.Item;
								If vPSRow.ChequeServiceQuantity <> 0 Then
									vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
								EndIf;
							EndIf;
						EndIf;
					EndDo;
					For Each vSrvBalancesRow In vServicesBalances Do
						If vSrvBalancesRow.SumBalance > 0 Then
							If vAdvanceAmount <= 0 Then
								Break;
							EndIf;
							If vSrvBalancesRow.SumBalance > vAdvanceAmount Then
								vSrvBalancesRow.SumBalance = vAdvanceAmount;
								If vSrvBalancesRow.ChequeServicePrice <> 0 Then
									vSrvBalancesRow.ChequeServiceQuantityBalance = Round(vSrvBalancesRow.SumBalance/vSrvBalancesRow.ChequeServicePrice, 7);
								EndIf;								
							EndIf;
							vAdvanceAmount = vAdvanceAmount - vSrvBalancesRow.SumBalance;
							
							vPSRow = PaymentSections.Add();
							vPSRow.PaymentSection = vSrvBalancesRow.PaymentSection;
							vPSRow.ChequeService = vSrvBalancesRow.ChequeService;
							vPSRow.ChequeServicePrice = vSrvBalancesRow.ChequeServicePrice;
							vPSRow.ChequeServiceQuantity = vSrvBalancesRow.ChequeServiceQuantityBalance;
							vPSRow.VATRate = ?(ValueIsFilled(vSrvBalancesRow.VATRate), vSrvBalancesRow.VATRate, VATRate);
							vPSRow.SumInFolioCurrency = vSrvBalancesRow.SumBalance;
							vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
							vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
							vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date); 
							vPSRow.MarkingCode = vSrvBalancesRow.MarkingCode;
							If vPSRow.ChequeServiceQuantity <> 0 Then
								vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
							EndIf;
						EndIf;
					EndDo;
					If Remarks = NStr("en='Advance'; ru='Аванс'; de='Advance'") Then
						Remarks = "";
					EndIf;
				ElsIf vAdvanceMode Then
					If Not vMultipleAdvanceSectionsAreUsed Then
						// Add folio balance as advance record
						vSumBalance = vFolioObj.pmGetBalance(vBalanceDate);
						If vSumBalance > 0 Then
							vPSRow = PaymentSections.Add();
							vPSRow.PaymentSection = vAdvancePaymentSection;
							vPSRow.SumInFolioCurrency = vSumBalance;
							vPSRow.ChequeServiceQuantity = 1;
							vPSRow.ChequeServicePrice = vPSRow.SumInFolioCurrency;
							If Company.IsUsingSimpleTaxSystem Then
								vPSRow.VATRate = VATRate;
							Else
								If ValueIsFilled(vAdvancePaymentSection.VATRate) Then
									vPSRow.VATRate = vAdvancePaymentSection.VATRate;
								Else
									vPSRow.VATRate = VATRate;
								EndIf;
							EndIf;
							vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
							vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
							vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
						EndIf;
						PaymentSection = vAdvancePaymentSection;
						// Fill VAT rate from the section
						If ValueIsFilled(PaymentSection) And ValueIsFilled(Company) And Not Company.IsUsingSimpleTaxSystem Then
							If ValueIsFilled(PaymentSection.VATRate) Then
								VATRate = PaymentSection.VATRate;
							EndIf;
						EndIf;
					Else
						PaymentSection = Undefined;
						PaymentSections.Clear();
						vServicesBalances = vFolioObj.pmGetChequeServicesBalances(vBalanceDate, Hotel, , Date);
						For Each vAdvancePaymentSectionsItem In vAdvancePaymentSections Do
							vCurAdvancePaymentSection = vAdvancePaymentSectionsItem.Value;
							vPSRow = PaymentSections.Find(vCurAdvancePaymentSection, "PaymentSection");
							If vPSRow = Undefined Then
								vPSRow = PaymentSections.Add();
								vPSRow.PaymentSection = vCurAdvancePaymentSection;
								vPSRow.ChequeService = Catalogs.Services.EmptyRef();
								vPSRow.ChequeServicePrice = 0;
								vPSRow.ChequeServiceQuantity = 0;
								vPSRow.VATRAte = vCurAdvancePaymentSection.VATRate;
								vPSRow.MarkingCode = "";
							EndIf;
							For Each vSrvBalancesRow In vServicesBalances Do
								If vSrvBalancesRow.SumBalance > 0 And 
								   vSrvBalancesRow.ChequeServiceQuantityBalance >= 0 And 
								   vSrvBalancesRow.ChequeServicePrice >= 0 Then
									vVATRate = ?(ValueIsFilled(vSrvBalancesRow.VATRate), vSrvBalancesRow.VATRate, VATRate);
									If vPSRow.VATRate = vVATRate Then
										vPSRow.VATRate = vVATRate;
										vPSRow.SumInFolioCurrency = vPSRow.SumInFolioCurrency + vSrvBalancesRow.SumBalance;
										vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
										vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
										vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);  
									EndIf;
								EndIf;
							EndDo;
						EndDo;
						If PaymentSections.Count() > 0 And Not vAdvanceSettlementMode Then
							Remarks = NStr("en='Advance'; ru='Аванс'; de='Advance'");
						EndIf;
					EndIf;
				ElsIf vPrepaymentMode Then
					vServicesBalances = vFolioObj.pmGetChequeServicesBalances(vBalanceDate, Hotel, , Date);
					For Each vSrvBalancesRow In vServicesBalances Do
						If vSrvBalancesRow.SumBalance > 0 And 
						   vSrvBalancesRow.ChequeServiceQuantityBalance >= 0 And 
						   vSrvBalancesRow.ChequeServicePrice >= 0 And 
						   vSrvBalancesRow.PaymentSection <> vAdvancePaymentSection Then
							vPSRow = PaymentSections.Add();
							vPSRow.PaymentSection = vAdvancePaymentSection;
							vPSRow.ChequeService = vSrvBalancesRow.ChequeService;
							vPSRow.ChequeServicePrice = vSrvBalancesRow.ChequeServicePrice;
							vPSRow.ChequeServiceQuantity = vSrvBalancesRow.ChequeServiceQuantityBalance;
							vPSRow.VATRate = ?(ValueIsFilled(vSrvBalancesRow.VATRate), vSrvBalancesRow.VATRate, VATRate);
							vPSRow.SumInFolioCurrency = vSrvBalancesRow.SumBalance;
							vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
							vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
							vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);  
							vPSRow.MarkingCode = vSrvBalancesRow.MarkingCode;
							vPSRow.Item = vSrvBalancesRow.Item;
							If vPSRow.ChequeServiceQuantity <> 0 Then
								vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
							EndIf;
							// Check if there is prepayment for this row
							vPrepaymentRows = vServicesBalances.FindRows(New Structure("PaymentSection, ChequeService, ChequeServicePrice", vAdvancePaymentSection, vSrvBalancesRow.ChequeService, vSrvBalancesRow.ChequeServicePrice)); 
							If vPrepaymentRows.Count() > 0 Then
								For Each vPrepaymentRow In vPrepaymentRows Do
									vPSRow.ChequeServiceQuantity = vPSRow.ChequeServiceQuantity + vPrepaymentRow.ChequeServiceQuantityBalance;
									vPSRow.SumInFolioCurrency = vPSRow.SumInFolioCurrency + vPrepaymentRow.SumBalance;
									vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
									vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
									vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
								EndDo;
								// Delete row if amounts are zero
								If vPSRow.ChequeServiceQuantity = 0 And vPSRow.SumInFolioCurrency = 0 Then
									PaymentSections.Delete(PaymentSections.IndexOf(vPSRow));
								EndIf;
							EndIf;
						EndIf;
					EndDo;
					If PaymentSections.Count() > 0 And Not vAdvanceSettlementMode Then
						Remarks = NStr("en='Prepayment'; ru='Предоплата'; de='Vorauszahlung'");
					EndIf;
				Else
					vServicesBalances = vFolioObj.pmGetChequeServicesBalances(vBalanceDate, Hotel, , Date);
					For Each vSrvBalancesRow In vServicesBalances Do
						If vSrvBalancesRow.SumBalance > 0 And 
						   vSrvBalancesRow.ChequeServiceQuantityBalance >= 0 And 
						   vSrvBalancesRow.ChequeServicePrice >= 0 And 
						   vSrvBalancesRow.PaymentSection <> vAdvancePaymentSection Then
							vPSRow = PaymentSections.Add();
							vPSRow.PaymentSection = vSrvBalancesRow.PaymentSection;
							vPSRow.ChequeService = vSrvBalancesRow.ChequeService;
							vPSRow.ChequeServicePrice = vSrvBalancesRow.ChequeServicePrice;
							vPSRow.ChequeServiceQuantity = vSrvBalancesRow.ChequeServiceQuantityBalance;
							vPSRow.VATRate = ?(ValueIsFilled(vSrvBalancesRow.VATRate), vSrvBalancesRow.VATRate, VATRate);
							vPSRow.SumInFolioCurrency = vSrvBalancesRow.SumBalance;
							vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
							vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
							vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);   
							vPSRow.MarkingCode = vSrvBalancesRow.MarkingCode;
							vPSRow.Item = vSrvBalancesRow.Item;
							If vPSRow.ChequeServiceQuantity <> 0 Then
								vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
							EndIf;
							// Check if there is prepayment for this row
							vPrepaymentRows = vServicesBalances.FindRows(New Structure("PaymentSection, ChequeService, ChequeServicePrice", vAdvancePaymentSection, vSrvBalancesRow.ChequeService, vSrvBalancesRow.ChequeServicePrice)); 
							If vPrepaymentRows.Count() > 0 Then
								For Each vPrepaymentRow In vPrepaymentRows Do
									vPSRow.ChequeServiceQuantity = vPSRow.ChequeServiceQuantity + vPrepaymentRow.ChequeServiceQuantityBalance;
									vPSRow.SumInFolioCurrency = vPSRow.SumInFolioCurrency + vPrepaymentRow.SumBalance;
									vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
									vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
									vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
								EndDo;
								// Delete row if amounts are zero
								If vPSRow.ChequeServiceQuantity = 0 And vPSRow.SumInFolioCurrency = 0 Then
									PaymentSections.Delete(PaymentSections.IndexOf(vPSRow));
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			Else
				vServicesBalances = vFolioObj.pmGetChequeServicesBalances(vBalanceDate, Hotel, , Date);
				For Each vSrvBalancesRow In vServicesBalances Do
					If vSrvBalancesRow.SumBalance > 0 And 
					   vSrvBalancesRow.ChequeServicePrice >= 0 And 
					   vSrvBalancesRow.ChequeServiceQuantityBalance >= 0 Then
						vPSRow = PaymentSections.Add();
						vPSRow.PaymentSection = vSrvBalancesRow.PaymentSection;
						vPSRow.ChequeService = vSrvBalancesRow.ChequeService;
						vPSRow.ChequeServicePrice = vSrvBalancesRow.ChequeServicePrice;
						vPSRow.ChequeServiceQuantity = vSrvBalancesRow.ChequeServiceQuantityBalance;
						vPSRow.VATRate = ?(ValueIsFilled(vSrvBalancesRow.VATRate), vSrvBalancesRow.VATRate, VATRate);
						vPSRow.SumInFolioCurrency = vSrvBalancesRow.SumBalance;
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
						vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);  
						vPSRow.MarkingCode = vSrvBalancesRow.MarkingCode;	
						vPSRow.Item = vSrvBalancesRow.Item;	
						If vPSRow.ChequeServiceQuantity <> 0 Then
							vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	If vAdvanceSettlementMode And ValueIsFilled(vAdvanceSettlementPaymentMethod) Then
		If vAdvanceAmount > 0 Then
			For Each vPSRow In PaymentSections Do
				If vPSRow.SumInFolioCurrency < 0 Then
					If -vPSRow.SumInFolioCurrency > vAdvanceAmount Then
						vPSRow.SumInFolioCurrency = vPSRow.SumInFolioCurrency + vAdvanceAmount;
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
						vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
						If vPSRow.ChequeServiceQuantity <> 0 Then
							vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
						EndIf;
						vAdvanceAmount = 0;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		If PaymentSections.Total("SumInFolioCurrency") = 0 And PaymentSections.Count() > 1 Then
			PaymentMethod = vAdvanceSettlementPaymentMethod;
		Else
			i = 0;
			While i < PaymentSections.Count() Do
				vPSRow = PaymentSections.Get(i);
				If vPSRow.SumInFolioCurrency < 0 Then
					PaymentSections.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Totals and defaults
	If ValueIsFilled(Hotel) And (Hotel.SplitFolioBalanceByPaymentSections Or Hotel.SplitFolioBalanceByServicesAndPrices) Then
		If PaymentSections.Count() = 0 Then
			vPSRow = PaymentSections.Add();
			If ValueIsFilled(vAdvancePaymentSection) Then
				vPSRow.PaymentSection = vAdvancePaymentSection;
				vPSRow.SumInFolioCurrency = Sum;
				If Hotel.SplitFolioBalanceByServicesAndPrices Then
					vPSRow.ChequeServiceQuantity = 1;
					vPSRow.ChequeServicePrice = vPSRow.SumInFolioCurrency;
				EndIf;
				If Company.IsUsingSimpleTaxSystem Then
					vPSRow.VATRate = VATRate;
				Else
					If ValueIsFilled(vAdvancePaymentSection.VATRate) Then
						vPSRow.VATRate = vAdvancePaymentSection.VATRate;
					Else
						vPSRow.VATRate = VATRate;
					EndIf;
				EndIf;
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
				vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
			Else
				vPSRow.PaymentSection = Hotel.PaymentSectionForAdvance;
				If Company.IsUsingSimpleTaxSystem Then
					vPSRow.VATRate = VATRate;
				Else
					If ValueIsFilled(vPSRow.PaymentSection) And ValueIsFilled(vPSRow.PaymentSection.VATRate) Then
						vPSRow.VATRate = vPSRow.PaymentSection.VATRate;
					Else
						vPSRow.VATRate = VATRate;
					EndIf;
				EndIf;
			EndIf;
		EndIf;

		// Check if there are advance rows
		If PaymentSections.Count() > 0 And PaymentMethod <> Catalogs.PaymentMethods.AdvanceSettlement Then
			i = 0;
			While i < PaymentSections.Count() Do
				vPSRow = PaymentSections.Get(i);
				If vPSRow.Sum < 0 Then
					PaymentSections.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;

		// Recalculate payment totals
		pmCalculateTotalsByPaymentSections();
	EndIf;
	
	// Check if advance settlement is possible
	If vAdvanceSettlementMode And PaymentSections.Count() < 2 Then
		Raise NStr("en='No services to do advance settlement!'; ru='Для зачета аванса нет услуг!'; de='Es gibt keine Dienstleistungen für die Vorausberechnung!'");
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
		VATSumInFolioCurrency = cmCalculateVATSum(VATRate, SumInFolioCurrency, Date);
		Sum = cmConvertCurrencies(Order.Sum, Order.Currency, , PaymentCurrency, , Date, Hotel);
		VATSum = cmCalculateVATSum(VATRate, Sum, Date);
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
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
				VATSum = vPSRow.VATSum;
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
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
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
				VATSum = vPSRow.VATSum;
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, Date);
				VATSumInFolioCurrency = vPSRow.VATSumInFolioCurrency;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillByOrder

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
// 
// Returns:
//  DocumentRef.BonusesPayment - Document ref
//
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
			SetNewObjectRef(Documents.Payment.GetRef());
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
			Movement.Sum = vPSRow.SumInFolioCurrency;
			
			// Attributes
			Movement.SumInPaymentCurrency = vPSRow.Sum;
		EndDo;
	Else
		Movement = RegisterRecords.FolioPayments.Add();
		
		Movement.Period = Date;
		Movement.Payment = Ref;
		
		FillPropertyValues(Movement, ThisObject);
		Movement.FolioCurrency = FolioCurrency;
		Movement.Folio = Folio;
		
		// Resources
		Movement.Sum = SumInFolioCurrency;
		
		// Attributes
		Movement.SumInPaymentCurrency = Sum;
	EndIf;
	
	RegisterRecords.FolioPayments.Write();
EndProcedure // PostToFolioPayments

// -----------------------------------------------------------------------------
Procedure PostToAccounts(pIsGifCardTopUp = False)
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
			
			// Resources
			Movement.Sum = vPSRow.SumInFolioCurrency;
			Movement.ChequeServiceQuantity = vPSRow.ChequeServiceQuantity;
			
			// If this is advance
			If vIsByServices And Not ValueIsFilled(Movement.ChequeService) Then
				Movement.ChequeServiceQuantity = 0;
				Movement.ChequeServicePrice = 0;
			EndIf;
			
			// Attributes
			Movement.VATSum = vPSRow.VATSumInFolioCurrency;
			
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
		Movement = RegisterRecords.Accounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		FillPropertyValues(Movement, Folio);
		If ValueIsFilled(ParentDoc) Then
			FillPropertyValues(Movement, ParentDoc);
		EndIf;
		FillPropertyValues(Movement, ThisObject);
		
		// Resources
		Movement.Sum = SumInFolioCurrency;
		
		// Attributes
		Movement.VATSum = VATSumInFolioCurrency;
		
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
			Movement.SumReceipt = vPSRow.Sum;
			Movement.VATSumReceipt = vPSRow.VATSum;
			Movement.SumExpense = 0;
			Movement.VATSumExpense = 0;
		EndDo;
	Else
		Movement = RegisterRecords.Payments.Add();
		
		Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
		
		FillPropertyValues(Movement, ThisObject);
		
		// Dimensions
		Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		
		// Resources
		Movement.SumReceipt = Sum;
		Movement.VATSumReceipt = VATSum;
		Movement.SumExpense = 0;
		Movement.VATSumExpense = 0;
	EndIf;
	
	RegisterRecords.Payments.Write();
EndProcedure // PostToPayments

// -----------------------------------------------------------------------------
Procedure PostToCustomerAccounts()
	// Retrieve amounts that could be cleared
	vPrevAdvances = New ValueTable();
	If PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
		vPrevAdvances = cmGetAdvancesForAdvanceClearing(Folio, Date);
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
				Movement.Quantity = vPSRow.ChequeServiceQuantity;
				
				// Dimensions
				Movement.AccountingCurrency = FolioCurrency;
				
				If ValueIsFilled(Folio) And ValueIsFilled(Folio.GuestGroup) Then
					Movement.GuestGroup = Folio.GuestGroup;
				EndIf;
				
				// Resources
				Movement.Sum = vPSRow.SumInFolioCurrency;
				
				// Attributes
				Movement.VATSum = vPSRow.VATSumInFolioCurrency;
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
							If vSum < Movement.Sum Then
								Movement.Sum = vSum;
								Movement.VATSum = cmCalculateVATSum(Movement.VATRate, Movement.Sum, Date);
								If Movement.Price <> 0 Then
									Movement.Quantity = Round(Movement.Sum/Movement.Price, 7);
								EndIf;
							EndIf;
							Movement.PaymentMethod = vPrevAdvancesRow.PaymentMethod;
							
							// Correct row amount
							vCorrSum = cmConvertCurrencies(Movement.Sum, Movement.AccountingCurrency, , vPrevAdvancesRow.Currency, , ExchangeRateDate, Hotel);
							vPrevAdvancesRow.Sum = vPrevAdvancesRow.Sum - vCorrSum;
							
							vCorrSumInPaymentCurrency = cmConvertCurrencies(Movement.Sum, Movement.AccountingCurrency, , PaymentCurrency, , ExchangeRateDate, Hotel);
							vCorrSumInFolioCurrency = cmConvertCurrencies(Movement.Sum, Movement.AccountingCurrency, , FolioCurrency, , ExchangeRateDate, Hotel);
							
							vPSRow.Sum = vPSRow.Sum - vCorrSumInPaymentCurrency;
							vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, Date);
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
		Movement.Sum = SumInFolioCurrency;
		
		// Attributes
		Movement.VATSum = VATSumInFolioCurrency;
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
		Movement.Sum = cmConvertCurrencies(Sum, PaymentCurrency, PaymentCurrencyExchangeRate, Movement.AccountingCurrency, , ExchangeRateDate, Hotel);
		
		// Attributes
		Movement.VATSum = cmCalculateVATSum(VATRate, Movement.Sum, Date);
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
			Movement.Sum = vPSRow.Sum;
			Movement.VATSum = vPSRow.VATSum;
			Movement.PaymentSum = vPSRow.Sum;
			Movement.VATPaymentSum = vPSRow.VATSum;
			Movement.ReturnSum = 0;
			Movement.VATReturnSum = 0;
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
		Movement.Sum = Sum;
		Movement.VATSum = VATSum;
		Movement.PaymentSum = Sum;
		Movement.VATPaymentSum = VATSum;
		Movement.ReturnSum = 0;
		Movement.VATReturnSum = 0;
	EndIf;			
	
	RegisterRecords.CashRegisterDailyReceipts.Write();
EndProcedure // PostToCashRegisterDailyReceipts

// -----------------------------------------------------------------------------
Procedure PostToCashInCashRegisters()
	Movement = RegisterRecords.CashInCashRegisters.Add();
	
	Movement.Period = Date;
	Movement.RecordType = AccumulationRecordType.Receipt;
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
			Movement.Sum = vPSRow.SumInFolioCurrency;
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
		Movement.Sum = SumInFolioCurrency;
	EndIf;
	
	RegisterRecords.PaymentServices.Write();
EndProcedure // PostToPaymentServices

// -----------------------------------------------------------------------------
Procedure PostToLabeledGoods() 
	RegisterRecords.LabeledGoods.Clear();
	For Each vRow In PaymentSections Do
		If Not IsBlankString(vRow.MarkingCode) Then 
			Movement = RegisterRecords.LabeledGoods.Add();
			Movement.RecordType = AccumulationRecordType.Expense;
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
Procedure ClosePreauthorisation()
	If ValueIsFilled(Preauthorisation) And Preauthorisation.Posted And 
	   ValueIsFilled(Preauthorisation.Status) And 
	   (Preauthorisation.Status = Enums.PreauthorisationStatuses.Authorised Or Preauthorisation.Status = Enums.PreauthorisationStatuses.Archived) And 
	   ValueIsFilled(PaymentMethod) And PaymentMethod.IsByCreditCard And 
	   PaymentMethod = Preauthorisation.PaymentMethod Then
		// Initialize amount of preauthorizations being completed
		vAmountCompleted = 0;
		// Build list of preauthorisations to complete
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Preauthorisation.Ref AS Ref,
		|	Preauthorisation.SumInFolioCurrency AS SumInFolioCurrency,
		|	2 AS SortCode,
		|	Preauthorisation.PointInTime AS PointInTime
		|FROM
		|	Document.Preauthorisation AS Preauthorisation
		|WHERE
		|	Preauthorisation.Posted
		|	AND Preauthorisation.Status = &qStatus
		|	AND Preauthorisation.Folio = &qFolio
		|	AND (NOT &qTransactionIDIsFilled
		|				AND NOT &qCardIsFilled
		|				AND Preauthorisation.PointInTime >= &qPeriodFrom
		|				AND Preauthorisation.PaymentMethod = &qPaymentMethod
		|			OR &qTransactionIDIsFilled
		|				AND Preauthorisation.TransactionID = &qTransactionID
		|			OR &qCardIsFilled
		|				AND Preauthorisation.CreditCard = &qCreditCard
		|				AND Preauthorisation.PaymentMethod = &qPaymentMethod)
		|
		|ORDER BY
		|	Preauthorisation.PointInTime";
		vQry.SetParameter("qPeriodFrom", Preauthorisation.PointInTime());
		vQry.SetParameter("qFolio", Folio);
		vQry.SetParameter("qPaymentMethod", PaymentMethod);
		vQry.SetParameter("qStatus", Enums.PreauthorisationStatuses.Authorised);
		vTransactionID = TrimR(Preauthorisation.TransactionID);
		vQry.SetParameter("qTransactionID", vTransactionID);
		vQry.SetParameter("qTransactionIDIsFilled", Not IsBlankString(vTransactionID));
		vCreditCard = Preauthorisation.CreditCard;
		vQry.SetParameter("qCreditCard", vCreditCard);
		vQry.SetParameter("qCardIsFilled", ValueIsFilled(vCreditCard));
		vDocs = vQry.Execute().Unload();   
		// Check if current preauthorization is in the resulting table 
		vRowTab = vDocs.Find(Preauthorisation, "Ref"); 
		If vRowTab = Undefined Then
			vDocsRow = vDocs.Add();
			vDocsRow.Ref = Preauthorisation;
			vDocsRow.SumInFolioCurrency = Preauthorisation.SumInFolioCurrency; 
			vDocsRow.SortCode = 1;     
		Else
			vRowTab.SortCode = 1;	
		EndIf;  
		vDocs.Sort("SortCode, PointInTime"); 
		For Each vDocsRow In vDocs Do
			If IsBlankString(vTransactionID) And vAmountCompleted < SumInFolioCurrency Or Not IsBlankString(vTransactionID) Then
				vDocObj = vDocsRow.Ref.GetObject();
				vDocObj.Status = Enums.PreauthorisationStatuses.Completed;
				vDocObj.Write(DocumentWriteMode.Posting);
				vAmountCompleted = vAmountCompleted + vDocObj.SumInFolioCurrency;
			Else
				Break;
			EndIf;
		EndDo;
	Else
		If ValueIsFilled(Preauthorisation) Then
			Preauthorisation = Undefined;
		EndIf;
	EndIf;
EndProcedure // ClosePreauthorisation

// -----------------------------------------------------------------------------
Procedure FillHotelProductPaymentDate()
	If ValueIsFilled(Folio) Then
		If ValueIsFilled(Folio.HotelProduct) And Not Folio.HotelProduct.IsFolder Then
			If Not ValueIsFilled(Folio.HotelProduct.PaymentDate) Then
				vHPObj = Folio.HotelProduct.GetObject();
				vPaymentMethod = Undefined;
				vHPObj.PaymentDate = vHPObj.pmGetHotelProductPaymentDate(vPaymentMethod);
				If ValueIsFilled(vPaymentMethod) Then
					vHPObj.PaymentMethod = vPaymentMethod;
				EndIf;
				vHPObj.Write();
			EndIf;
		EndIf;
		If ValueIsFilled(Folio.ParentDoc) And 
		   (TypeOf(Folio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(Folio.ParentDoc) = Type("DocumentRef.Reservation")) Then
			If ValueIsFilled(Folio.ParentDoc.HotelProduct) And Not Folio.ParentDoc.HotelProduct.IsFolder Then
				If Not ValueIsFilled(Folio.ParentDoc.HotelProduct.PaymentDate) Then
					vHPObj = Folio.ParentDoc.HotelProduct.GetObject();
					vPaymentMethod = Undefined;
					vHPObj.PaymentDate = vHPObj.pmGetHotelProductPaymentDate(vPaymentMethod);
					If ValueIsFilled(vPaymentMethod) Then
						vHPObj.PaymentMethod = vPaymentMethod;
					EndIf;
					If Not ValueIsFilled(vHPObj.PaymentDate) Then
						vHPObj.PaymentDate = Date;
					EndIf;
					vHPObj.Write();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillHotelProductPaymentDate

// -----------------------------------------------------------------------------
Procedure WriteOffBonusesObsolete()
	If ValueIsFilled(PaymentMethod) And PaymentMethod.IsByBonuses And 
	   ValueIsFilled(PaymentMethod.DiscountType) And PaymentMethod.DiscountType.IsAccumulatingDiscount And
	   PaymentMethod.DiscountType.BonusCalculationFactor <> 0 And 
	   Not PaymentMethod.DiscountType.ExternalBonusSystemIsUsed Then
		vDimension = Undefined;
		If PaymentMethod.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.DiscountCard Then
			If ValueIsFilled(ParentDoc) And ValueIsFilled(ParentDoc.DiscountCard) Then
				vDimension = ParentDoc.DiscountCard;
			EndIf;
		ElsIf PaymentMethod.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Client Then
			If ValueIsFilled(Payer) And TypeOf(Payer) = Type("CatalogRef.Clients") Then
				vDimension = Payer;
			EndIf;
		EndIf;
		If vDimension <> Undefined Then
			// Get payment currency bonus calculation rate
			vBonusRate = 1;
			If PaymentMethod.DiscountType.BonusRateMultiplier <> 0 Then
				vBonusRate = PaymentMethod.DiscountType.BonusRateMultiplier;
			EndIf;
			vRates = InformationRegisters.CurrencyRates.SliceLast(Date, New Structure("Hotel, Currency", Hotel, PaymentCurrency));
			If vRates.Count() > 0 Then
				vRatesRow = vRates.Get(0);
				If vRatesRow.BonusRate <> 0 Then
					vBonusRate = Round(vRatesRow.BonusRate * vBonusRate, 4);
				ElsIf vRatesRow.Rate <> 0 Then
					vBonusRate = Round(vRatesRow.Rate / ?(vRatesRow.Factor = 0, 1, vRatesRow.Factor) * vBonusRate, 4);
				EndIf;
				vBonus2WriteOff = Round(Sum * vBonusRate, 2);
				If vBonus2WriteOff <> 0 Then
					Movement = RegisterRecords.AccumulatingDiscountResources.Add();
					If vBonus2WriteOff > 0 Then
						Movement.RecordType = AccumulationRecordType.Expense;
					Else
						Movement.RecordType = AccumulationRecordType.Receipt;
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
EndProcedure // WriteOffBonusesObsolete

// -----------------------------------------------------------------------------
Procedure PostToGiftCertificatesObsolete()
	vGiftCertificatesArePerHotel = Constants.GiftCertificatesArePerHotel.Get();
	
	// Write gift certificate information record
	If Not cmGiftCertificateExists(Hotel, GiftCertificate) Then
		vGiftCertificatesRM = InformationRegisters.GiftCertificates.CreateRecordManager();
		vGiftCertificatesRM.Period = Date;
		vGiftCertificatesRM.Hotel = ?(vGiftCertificatesArePerHotel, Hotel, Catalogs.Hotels.EmptyRef());
		vGiftCertificatesRM.GiftCertificate = TrimAll(GiftCertificate);
		vNumMonth = Constants.GiftCertificatesMonthsValid.Get();
		If vNumMonth > 0 Then
			vGiftCertificatesRM.BlockAuthor = Author;
			vGiftCertificatesRM.BlockDate = AddMonth(BegOfDay(Date), vNumMonth);
			vGiftCertificatesRM.BlockReason = "en='Is expired on " + Format(vGiftCertificatesRM.BlockDate, "DF=dd.MM.yyyy") + ", was paid on " + Format(vGiftCertificatesRM.Period, "DF=dd.MM.yyyy") + "!'; 
			                                  |ru='Срок действия истек " + Format(vGiftCertificatesRM.BlockDate, "DF=dd.MM.yyyy") + ", был оплачен " + Format(vGiftCertificatesRM.Period, "DF=dd.MM.yyyy") + "!'";
		EndIf;
		vGiftCertificatesRM.Write(True);
	EndIf;
	
	// Write to gift certificate balances
	Movement = RegisterRecords.GiftCertificatesBalance.Add();
	Movement.Period = Date;
	
	// Fill dimensions
	Movement.Hotel = ?(vGiftCertificatesArePerHotel, Hotel, Catalogs.Hotels.EmptyRef());
	Movement.GiftCertificate = TrimAll(GiftCertificate);
	
	// Fill resource
	Movement.Amount = Round(cmConvertCurrencies(Sum, PaymentCurrency, PaymentCurrencyExchangeRate, Hotel.ReportingCurrency, , ExchangeRateDate, Hotel), 2);
	
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
EndProcedure // PostToGiftCertificatesObsolete

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
				PostingMovement = RegisterRecords.PostingsFO.AddDebit();
			Else
				PostingMovement = RegisterRecords.PostingsFO.AddCredit();
			EndIf;
		ElsIf vPostingAccount.Type = AccountType.Active Then
			If vReverseSign Then
				PostingMovement = RegisterRecords.PostingsFO.AddCredit();
			Else
				PostingMovement = RegisterRecords.PostingsFO.AddDebit();
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
		
		PostingMovement.POSTicket = TrimAll(OrderNumber);
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
		
		PostingMovement.POSTicket = TrimAll(OrderNumber);
		PostingMovement.Invoice = Undefined;
		
		PostingMovement.Recorder = Ref;
		PostingMovement.Author = SessionParameters.CurrentUser;
		
		// Commission
		If vCommissionAccount <> Undefined And vCommissionAmount <> 0 Then
			If vPostingAccount.Type = AccountType.Passive Then
				If vReverseSign Then
					PostingMovement = RegisterRecords.PostingsFO.AddDebit();
				Else
					PostingMovement = RegisterRecords.PostingsFO.AddCredit();
				EndIf;
			ElsIf vPostingAccount.Type = AccountType.Active Then
				If vReverseSign Then
					PostingMovement = RegisterRecords.PostingsFO.AddCredit();
				Else
					PostingMovement = RegisterRecords.PostingsFO.AddDebit();
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
			
			PostingMovement.POSTicket = TrimAll(OrderNumber);
			PostingMovement.Invoice = Undefined;
			
			PostingMovement.Recorder = Ref;
			PostingMovement.Author = SessionParameters.CurrentUser;
		EndIf;			
		
		RegisterRecords.PostingsFO.Write();
	EndIf;
EndProcedure // PostToFOChartOfAccounts

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

// -----------------------------------------------------------------------------
Procedure FillByPreauthorisation(pPreauth)
	If Not ValueIsFilled(pPreauth) Then
		Return;
	EndIf;
	
	If ValueIsFilled(pPreauth.Hotel) Then
		If Hotel <> pPreauth.Hotel Then
			Hotel = pPreauth.Hotel;
		EndIf;
	EndIf;
	
	FillPropertyValues(ThisObject, pPreauth, , "Number, Date, AccountingDate, Author, DeletionMark, Posted, Hotel, ReferenceNumber, AuthorizationCode, Remarks, SlipText");
	Preauthorisation = pPreauth;
	
	FillByFolio(pPreauth.Folio);
	
	PaymentMethod = pPreauth.PaymentMethod;
EndProcedure // FillByPreauthorisation

// -----------------------------------------------------------------------------
Procedure FillByPayment(pPayment)
	If Not ValueIsFilled(pPayment) Then
		Return;
	EndIf;
	
	If ValueIsFilled(pPayment.Hotel) Then
		If Hotel <> pPayment.Hotel Then
			Hotel = pPayment.Hotel;
		EndIf;
	EndIf;
	
	FillPropertyValues(ThisObject, pPayment, , "Number, Date, AccountingDate, Author, DeletionMark, Posted, Hotel, ReferenceNumber, AuthorizationCode, Remarks, SlipText");
	Payment = pPayment;
	CorrectionOfIncorrectCheque = True;
	SendPayerContactsToOFD = 2; // Do not send
	
	// Copy payment sections
	For Each vPaymentPSRow In pPayment.PaymentSections Do
		vPSRow = PaymentSections.Add();
		FillPropertyValues(vPSRow, vPaymentPSRow);
	EndDo;
EndProcedure // FillByPayment

// -----------------------------------------------------------------------------
Function PostBonusesPayment(vMessage)
	vResult = False;
	vDoc = pmGetBonusesPayment();
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
Function GetFirstBonusesPayment()
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	BonusesPayment.Ref AS Ref
		|FROM
		|	Document.BonusesPayment AS BonusesPayment
		|WHERE
		|	NOT BonusesPayment.DeletionMark
		|	AND BonusesPayment.Posted
		|	AND BonusesPayment.Card = &qDiscountCard
		|
		|ORDER BY
		|	BonusesPayment.PointInTime";
	vQuery.SetParameter("qDiscountCard", DiscountCard);
	vQueryResult = vQuery.Execute();
	vRes = vQueryResult.Select();
	While vRes.Next() Do
		Return vRes.ref;
	EndDo;
	Return Documents.BonusesPayment.EmptyRef();
EndFunction // GetFirstBonusesPayment

// -----------------------------------------------------------------------------
Procedure ActivateGiftCertificate(pCancel)
	vDoc = pmGetBonusesPayment();
	Try
		If vDoc.IsEmpty() Then
			vBonusesPaymentObj = Documents.BonusesPayment.CreateDocument();
			vFirstDoc = GetFirstBonusesPayment();
			If ValueIsFilled(vFirstDoc) Then
				vBonusesPaymentObj.IsActivateCertificate = False;
			Else
				vBonusesPaymentObj.IsActivateCertificate = True;
			EndIf;
		Else
			vBonusesPaymentObj = vDoc.GetObject();
		EndIf;
		vBonusesPaymentObj.Fill(Ref); 
		vBonusesPaymentObj.Write(DocumentWriteMode.Posting);
	Except
		pCancel = True;
		Raise BriefErrorDescription(ErrorInfo());
	EndTry;
EndProcedure // ActivateGiftCertificate

// -----------------------------------------------------------------------------
Function pmIsPrepayment()
	// Get folio balance after payment
	If PaymentMethod = Catalogs.PaymentMethods.Settlement Then
		Return False;
	Else
		vFolioBalance = Folio.GetObject().pmGetBalance();
		If vFolioBalance = 0 Then
			Return False;
		Else
			Return True;
		EndIf;
	EndIf;
EndFunction // pmIsPrepayment

// -----------------------------------------------------------------------------
Function CheckBonusesBalance(pError = "")
	vOK = True;
	If ValueIsFilled(PaymentMethod) And PaymentMethod.IsByBonuses And 
	   ValueIsFilled(PaymentMethod.DiscountType) And 
	   PaymentMethod.DiscountType.BonusCalculationFactor <> 0 Then
		vDiscountTypeObj = PaymentMethod.DiscountType.GetObject();
		vDimension = Undefined;
		vBonusDate = Date;
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.DateToGetBonusBalance) And ValueIsFilled(GuestGroup) Then
			If Hotel.DateToGetBonusBalance = Enums.DatesToGetBonusBalance.CheckInDate And ValueIsFilled(GuestGroup.CheckInDate) Then
				vBonusDate = BegOfDay(GuestGroup.CheckInDate);
			ElsIf Hotel.DateToGetBonusBalance = Enums.DatesToGetBonusBalance.CheckOutDate And ValueIsFilled(GuestGroup.CheckOutDate) Then
				vBonusDate = EndOfDay(GuestGroup.CheckOutDate);
			EndIf;
		EndIf;
		If PaymentMethod.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.DiscountCard Then
			If ValueIsFilled(ParentDoc) And ValueIsFilled(ParentDoc.DiscountCard) Then
				vDimension = ParentDoc.DiscountCard;
				vBonuses = vDiscountTypeObj.pmGetAccumulatingDiscountResources(vBonusDate, , , , ParentDoc.DiscountCard);
			EndIf;
		ElsIf PaymentMethod.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Client Then
			If ValueIsFilled(Payer) And TypeOf(Payer) = Type("CatalogRef.Clients") Then
				vDimension = Payer;
				vBonuses = vDiscountTypeObj.pmGetAccumulatingDiscountResources(vBonusDate, , , Payer);
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
					vBonusesSum = Round(vBonusesRow.Bonus / vBonusRate, 2);
					If vBonus2WriteOff <> 0 Then
						If vBonus2WriteOff > vBonusesRow.Bonus Then
							vOK = False;
							pError = NStr("en='You are trying to write off " + Format(vBonus2WriteOff, "ND=17; NFD=0; NG=") + " bonuses from the " + Format(vBonusesRow.Bonus, "ND=17; NFD=0; NG=") + " available! Maximum bonuses payment amount is " + cmFormatSum(vBonusesSum, PaymentCurrency) + "';
							                  |de='You are trying to write off " + Format(vBonus2WriteOff, "ND=17; NFD=0; NG=") + " bonuses from the " + Format(vBonusesRow.Bonus, "ND=17; NFD=0; NG=") + " available! Maximum bonuses payment amount is " + cmFormatSum(vBonusesSum, PaymentCurrency) + "';
							                  |ru='Пытаетесь списать " + Format(vBonus2WriteOff, "ND=17; NFD=0; NG=") + " бонусов из имеющихся " + Format(vBonusesRow.Bonus, "ND=17; NFD=0; NG=") + "! Максимальная сумма оплаты бонусами " + cmFormatSum(vBonusesSum, PaymentCurrency) + "'");
						ElsIf vBonusesRow.BonusReceipt < PaymentMethod.MinimumBonuses Then
							vOK = False;
							pError = NStr("en='Minimum amount of bonuses allowed for payment is " + Format(PaymentMethod.MinimumBonuses, "ND=17; NFD=0; NG=") + "! You have " + Format(vBonusesRow.BonusReceipt, "ND=17; NFD=0; NG=") + " bonuses';
							                  |de='Minimum amount of bonuses allowed for payment is " + Format(PaymentMethod.MinimumBonuses, "ND=17; NFD=0; NG=") + "! You have " + Format(vBonusesRow.BonusReceipt, "ND=17; NFD=0; NG=") + " bonuses';
							                  |ru='Списывать бонусы в счет оплаты услуг можно только при накоплении как минимум " + Format(PaymentMethod.MinimumBonuses, "ND=17; NFD=0; NG=") + " бонусов! Уже начислено " + Format(vBonusesRow.BonusReceipt, "ND=17; NFD=0; NG=") + " бонусов'");
						EndIf;
					EndIf;
				Else
					vOK = False;
					pError = NStr("en='Bonus calculation rate is not specified for the " + TrimAll(PaymentCurrency) + " currency!'; 
					              |de='Bonus calculation rate is not specified for the " + TrimAll(PaymentCurrency) + " currency!'; 
					              |ru='Не определен курс пересчета валюты " + TrimAll(PaymentCurrency) + " в бонусы!'");
				EndIf;
			Else
				vOK = False;
				pError = NStr("en='There is no accumulating bonuses for this payment!';ru='Для этого платежа нет накопленных бонусов!';de='Für diese Zahlung gibt es keine gesammelten Boni!'");
			EndIf;
		Else
			vOK = False;
			pError = NStr("en='Accumulation dimension is not defined for the bonus accumulation type!';ru='У способа накопления бонусов не определено измерение накопления!';de='Bei der Methode der Akkumulation von Boni ist die Messung der Akkumulation nicht definiert!'");
		EndIf;
	EndIf;
	Return vOK;
EndFunction // CheckBonusesBalanceAndSections

#EndRegion    

#Region Initialize

// -----------------------------------------------------------------------------
WasPosted = True;

#EndRegion
