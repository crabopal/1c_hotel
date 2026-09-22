
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// 1. Post to Folio payments
	PostToFolioPayments();
		
	If Status = Enums.PreauthorisationStatuses.Authorised Then
		// 2. Post to Accounts
		PostToAccounts();
		
		// 5. Post to Invoice accounts
		PostToInvoiceAccounts();
	EndIf;
EndProcedure // Posting

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
		EndIf;
	EndIf;
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
		If ValueIsFilled(Folio) And ValueIsFilled(Folio.GuestGroup) And
		   Folio.GuestGroup <> GuestGroup Then
			// User activity history   
			vEventDescription = StrTemplate(NStr("en = 'Preauthorisation guest group contracts and folio differ: %1 <> %2, %3'; 
												 |de = 'Zahlungsgastgruppenverträge und Folio unterscheiden sich: %1 <> %2, %3'; 
												 |ru = 'Группа преавторизации и фолио отличаются: %1 <> %2, %3'"), TrimAll(GuestGroup), TrimAll(Folio.GuestGroup), cmFormatSum(Sum, PaymentCurrency));  
			vParentDoc = Ref;
			If ValueIsFilled(ParentDoc) Then
				vParentDoc = ParentDoc; 
			ElsIf Not ValueIsFilled(ParentDoc) And IsNew() Then 
				vParentDoc = Documents.Preauthorisation.GetRef(New UUID);
				SetNewObjectRef(vParentDoc);	
			EndIf;	
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel)
		EndIf;
	Else
		If DeletionMark Then
			// User activity history   
			vEventDescription = StrTemplate(NStr("en = 'Set document deletion mark preauthorisation: %1, %2, %3'; 
												 |de = 'Legen Sie die Zahlung für die Löschmarkierung des Dokuments fest: %1, %2, %3'; 
												 |ru = 'Установка отметки удаления преавторизации: %1, %2, %3'"), TrimAll(Payer), cmFormatSum(Sum, PaymentCurrency), TrimAll(Ref));  
			vParentDoc = Ref;
			If ValueIsFilled(ParentDoc) Then
				vParentDoc = ParentDoc;
			EndIf;	
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel);

			AuthorOfCancellation = SessionParameters.CurrentUser;
			DateOfCancellation = CurrentSessionDate();
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;       
	// User activity history   
	vEventDescription = StrTemplate(NStr("en = 'Document deletion: %1, %2, %3'; 
										 |de = 'Unmittelbare Löschung: %1, %2, %3'; 
										 |ru = 'Непосредственное удаление преавторизации: %1, %2, %3'"), TrimAll(Payer), cmFormatSum(Sum, PaymentCurrency), TrimAll(Ref));  
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
	Status = Enums.PreauthorisationStatuses.Authorised;
	ExternalCode = "";
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)   
	If DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

#EndRegion

#Region Public

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
	EndIf;
	If Sum < 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Для оформления возврата необходимо использовать документ ""Возврат""!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "Use ""Return"" document to return money!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Use ""Return"" document to return money!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Sum", pAttributeInErr);
	EndIf;
	If Not Posted Then
		// Check user rights to do payment
		vEmployee = SessionParameters.CurrentUser;
		If ValueIsFilled(vEmployee) And ValueIsFilled(vEmployee.PermissionGroup) And ValueIsFilled(Folio) Then
			vPermissionGroup = vEmployee.PermissionGroup;
			For Each vPrmRow In vPermissionGroup.FolioOperationsAllowed Do
				If IsBlankString(vPrmRow.FolioType) Or 
				   Not IsBlankString(vPrmRow.FolioType) And TrimR(vPrmRow.FolioType) = Left(TrimR(Folio.Description), StrLen(TrimR(vPrmRow.FolioType))) Then
					If vPrmRow.PreauthorisationsForbidden Then
						vHasErrors = True;
						vMsgTextRu = vMsgTextRu + "Нет прав на оформление преавторизаций по фолио с типом " + TrimAll(Folio.Description) + "!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "You do not have rights to do preauthorisations to folio type " + TrimAll(Folio.Description) + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Sie haben keine Rechte zur Vorautorisierung zum Folio-typ " + TrimAll(Folio.Description) + "!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Folio", pAttributeInErr);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
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
Procedure pmFillGuestGroup() Export
	If Folio.GuestGroup <> GuestGroup Then
		GuestGroup = Folio.GuestGroup;
	EndIf;
EndProcedure // pmFillGuestGroup

// -----------------------------------------------------------------------------
Procedure pmRecalculateSums() Export
	SumInFolioCurrency = Round(cmConvertCurrencies(Sum, PaymentCurrency, PaymentCurrencyExchangeRate, 
												   FolioCurrency, FolioCurrencyExchangeRate, 
												   ExchangeRateDate, Hotel), 2);
EndProcedure // pmRecalculateSums

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure PostToFolioPayments()
	Movement = RegisterRecords.FolioPayments.Add();
	
	Movement.Period = Date;
	
	FillPropertyValues(Movement, ThisObject);
	Movement.FolioCurrency = FolioCurrency;
	Movement.Folio = Folio;
	
	// Resources
	Movement.Sum = 0;
	Movement.Limit = SumInFolioCurrency;
	
	// Attributes
	Movement.SumInPaymentCurrency = Sum;
	Movement.IsPreauthorisation = True;
	
	RegisterRecords.FolioPayments.Write();
EndProcedure // PostToFolioPayments

// -----------------------------------------------------------------------------
Procedure PostToAccounts()
	Movement = RegisterRecords.Accounts.Add();
	
	Movement.RecordType = AccumulationRecordType.Expense;
	Movement.Period = ?(ValueIsFilled(AccountingDate), AccountingDate, Date);
	
	FillPropertyValues(Movement, Folio);
	If ValueIsFilled(ParentDoc) Then
		FillPropertyValues(Movement, ParentDoc);
	EndIf;
	FillPropertyValues(Movement, ThisObject);
	
	// Resources
	Movement.Sum = 0;
	Movement.Limit = SumInFolioCurrency;
	
	// Attributes
	Movement.IsPreauthorisation = True;

	RegisterRecords.Accounts.Write();
EndProcedure // PostToAccounts

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
		Movement.AccountingDate = ?(ValueIsFilled(AccountingDate), AccountingDate, BegOfDay(Date));
		If ValueIsFilled(Folio) Then
			Movement.Client = Folio.Client;
			Movement.Room = Folio.Room;
		EndIf;
		Movement.IsPreauthorisation = True;

		RegisterRecords.InvoiceAccounts.Write();
	EndIf;
EndProcedure // PostToInvoiceAccounts

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
	FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ExchangeRateDate);
	
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
	pmFillGuestGroup();
	
	// Get folio balance
	vFolioObj = Folio.GetObject();
	vFolioBalance = vFolioObj.pmGetBalance('39991231235959');
	SumInFolioCurrency = 0;
	If vFolioBalance > 0 Then
		SumInFolioCurrency = vFolioBalance;
	EndIf;
	
	// Recalculate sum
	Sum = Round(cmConvertCurrencies(SumInFolioCurrency, FolioCurrency, FolioCurrencyExchangeRate, PaymentCurrency, PaymentCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
EndProcedure // FillByFolio

// -----------------------------------------------------------------------------
Procedure FillByPreauthorisation(pPreauthorisation)
	If Not ValueIsFilled(pPreauthorisation) Then
		Return;
	EndIf;
	If Not ValueIsFilled(pPreauthorisation.Folio) Then
		Return;
	EndIf;
	
	FillByFolio(pPreauthorisation.Folio);
	
	// Fill attributes from previous preauthorisation
	Payer = pPreauthorisation.Payer;
	CreditCard = pPreauthorisation.CreditCard;
	CardType = pPreauthorisation.CardType;
	PaymentMethod = pPreauthorisation.PaymentMethod;
	TransactionID = pPreauthorisation.TransactionID;
EndProcedure // FillByPreauthorisation

#EndRegion
