
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Basic checks
	If pWriteMode = DocumentWriteMode.Write Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
	EndIf;
	
	// Fill author and date when folio was closed
	If IsClosed Then
		If Not ValueIsFilled(IsClosedDate) Then
			IsClosedDate = CurrentSessionDate();
			IsClosedAuthor = SessionParameters.CurrentUser;
		EndIf;
	Else
		If ValueIsFilled(IsClosedDate) Then
			IsClosedDate = '00010101';
			IsClosedAuthor = Catalogs.Employees.EmptyRef();
		EndIf;
		If IsArchived Then
			IsArchived = False;
		EndIf;
	EndIf;
	
	// Individuals customer
	If Not ValueIsFilled(Customer) And ValueIsFilled(Client) And ValueIsFilled(Company) And Company.CreateIndividualsCustomerForEachClient Then
		If IsBlankString(Hotel.AdditionalServicesFolioCondition) Or Not IsBlankString(Hotel.AdditionalServicesFolioCondition) And StrFind(lower(Description), lower(TrimAll(Hotel.AdditionalServicesFolioCondition))) = 0 Then
			Customer = CreateIndividualsCustomer();
		EndIf;
	EndIf;
	
	// Folio number
	If ValueIsFilled(Hotel) And Hotel.UseCustomerCodeForFolioPrefix Then
		vPrefix = "";
		If Not ValueIsFilled(Customer) And Not IsBlankString(Hotel.ExtraChargesFolioPrefix) And 
		   Not IsBlankString(Hotel.AdditionalServicesFolioCondition) And StrFind(Upper(TrimAll(Description)), Upper(TrimAll(Hotel.AdditionalServicesFolioCondition))) > 0 Then
			vPrefix = TrimAll(Hotel.ExtraChargesFolioPrefix);
		Else
			If ValueIsFilled(Customer) And StrLen(TrimAll(Customer.Code)) <= 6 Then
				vPrefix = TrimAll(Customer.Code);
			ElsIf ValueIsFilled(Hotel.IndividualsCustomer) And StrLen(TrimAll(Hotel.IndividualsCustomer.Code)) <= 6 Then
				vPrefix = TrimAll(Hotel.IndividualsCustomer.Code);
			EndIf;
		EndIf;
		If Not IsBlankString(vPrefix) Then
			If Upper(vPrefix) <> Upper(Left(TrimAll(Number), StrLen(vPrefix))) Then
				SetNewNumber(vPrefix);
			EndIf;
		EndIf;
	EndIf;
	
	// Master folios
	If IsMaster Then
		If Not ValueIsFilled(Hotel) Then
			Hotel = SessionParameters.CurrentHotel;
		EndIf;
		If ValueIsFilled(ParentDoc) Or cmIsBrokenRef("Document.Folio", ParentDoc) Then
			ParentDoc = Undefined;
		EndIf;
	EndIf;
			
	If Not IsNew() Then
		// Save old analytical parameters to document properties
		AdditionalProperties.Insert("OldHotel", Ref.Hotel);
		AdditionalProperties.Insert("OldFolioCurrency", Ref.FolioCurrency);
		AdditionalProperties.Insert("OldCompany", Ref.Company);
		AdditionalProperties.Insert("OldCustomer", Ref.Customer);
		AdditionalProperties.Insert("OldContract", Ref.Contract);
		AdditionalProperties.Insert("OldAgent", Ref.Agent);
		AdditionalProperties.Insert("OldGuestGroup", Ref.GuestGroup);
		AdditionalProperties.Insert("OldParentDoc", Ref.ParentDoc);
		AdditionalProperties.Insert("OldHotelProduct", Ref.HotelProduct);
		
		// Check if folio credit limit was changed
		If Ref.CreditLimit <> CreditLimit Then
			vChanges = TrimAll(Ref) + Chars.LF + NStr("en='Credit limit has changed: '; ru='Изменение кредитного лимита: '; de='Ändern des Kreditlimits: '") + cmFormatSum(Ref.CreditLimit, FolioCurrency, "NZ=") + " -> " + cmFormatSum(CreditLimit, FolioCurrency, "NZ=");
			If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
				// Do movement on current date
				vAccChgRec = InformationRegisters.AccommodationChangeHistory.CreateRecordManager();
				
				FillAccChgAttributes(vAccChgRec, CurrentSessionDate(), SessionParameters.CurrentUser, ParentDoc);
				vAccChgRec.Changes = vChanges;
				
				// Write record
				vAccChgRec.Write(True);
			ElsIf ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
				// Do movement on current date
				vResChgRec = InformationRegisters.ReservationChangeHistory.CreateRecordManager();
				
				FillResChgAttributes(vResChgRec, CurrentSessionDate(), SessionParameters.CurrentUser, ParentDoc);
				vResChgRec.Changes = vChanges;
				
				// Write record
				vResChgRec.Write(True);
			ElsIf ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
				// Do movement on current date
				vRResChgRec = InformationRegisters.ResourceReservationChangeHistory.CreateRecordManager();
				
				FillRResChgAttributes(vRResChgRec, CurrentSessionDate(), SessionParameters.CurrentUser, ParentDoc);
				vRResChgRec.Changes = vChanges;
				
				// Write record
				vRResChgRec.Write(True);
			ElsIf ValueIsFilled(Customer) Then
				// Do movement on current date
				vCustChgRec = InformationRegisters.CustomerChangeHistory.CreateRecordManager();
				
				FillCustChgAttributes(vCustChgRec, CurrentSessionDate(), SessionParameters.CurrentUser, Customer);
				vCustChgRec.Changes = vChanges;
				
				// Write record
				vCustChgRec.Write(True);
			ElsIf ValueIsFilled(Client) Then
				// Do movement on current date
				vCltChgRec = InformationRegisters.ClientChangeHistory.CreateRecordManager();
				
				FillCltChgAttributes(vCltChgRec, CurrentSessionDate(), SessionParameters.CurrentUser, Client);
				vCltChgRec.Changes = vChanges;
				
				// Write record
				vCltChgRec.Write(True);
			EndIf;
		EndIf;
	Else
		AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
	EndIf;
	
	If DoNotFillAgent Then
		Agent = Catalogs.Customers.EmptyRef();
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	LineNumber = 0;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	If IsBlankString(pPrefix) Then
		If IsBlankString(Number) Then
			vHotel = Hotel;
			If Not ValueIsFilled(vHotel) Then
				vHotel = SessionParameters.CurrentHotel;
			EndIf;
			If ValueIsFilled(vHotel) Then
				vPrefix = Catalogs.Hotels.pmGetPrefix(vHotel);
				If vPrefix <> "" Then
					pPrefix = vPrefix;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;      
	
	// Update attributes of the client identification cards
	UpdateClientIdentificationCards();
	
	// Block used gift certificates
	BlockUsedGiftCertificates();

	If AdditionalProperties.Property("SkipCheckOfAnaliticalParametersChange") And 
	   AdditionalProperties.SkipCheckOfAnaliticalParametersChange Then
		Return;
	EndIf;
	
	// New customer and contract
	vNewCustomer = Customer;
	vNewContract = Contract;
	If Not ValueIsFilled(vNewCustomer) Then
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.IndividualsCustomer) Then
				vNewCustomer = Hotel.IndividualsCustomer;
			EndIf;
			If Not ValueIsFilled(Contract) Then 
				If ValueIsFilled(Hotel.IndividualsContract) Then
					vNewContract = Hotel.IndividualsContract;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Compare old and new analytical parameters and decide if we need to repost folio transactions
	vOldHotel = Catalogs.Hotels.EmptyRef();
	If AdditionalProperties.Property("OldHotel") Then
		vOldHotel = AdditionalProperties.OldHotel;
	EndIf;
	vOldFolioCurrency = Catalogs.Currencies.EmptyRef();
	If AdditionalProperties.Property("OldFolioCurrency") Then
		vOldFolioCurrency = AdditionalProperties.OldFolioCurrency;
	EndIf;
	vOldCompany = Catalogs.Companies.EmptyRef();
	If AdditionalProperties.Property("OldCompany") Then
		vOldCompany = AdditionalProperties.OldCompany;
	EndIf;
	vOldCustomer = Catalogs.Customers.EmptyRef();
	If AdditionalProperties.Property("OldCustomer") Then
		vOldCustomer = AdditionalProperties.OldCustomer;
	EndIf;
	vOldContract = Catalogs.Contracts.EmptyRef();
	If AdditionalProperties.Property("OldContract") Then
		vOldContract = AdditionalProperties.OldContract;
	EndIf;
	vOldAgent = Catalogs.Customers.EmptyRef();
	If AdditionalProperties.Property("OldAgent") Then
		vOldAgent = AdditionalProperties.OldAgent;
	EndIf;
	vOldGuestGroup = Catalogs.GuestGroups.EmptyRef();
	If AdditionalProperties.Property("OldGuestGroup") Then
		vOldGuestGroup = AdditionalProperties.OldGuestGroup;
	EndIf;
	vOldParentDoc = Undefined;
	If AdditionalProperties.Property("OldParentDoc") Then
		vOldParentDoc = AdditionalProperties.OldParentDoc;
	EndIf;
	vOldHotelProduct = Catalogs.HotelProducts.EmptyRef();
	If AdditionalProperties.Property("OldHotelProduct") Then
		vOldHotelProduct = AdditionalProperties.OldHotelProduct;
	EndIf;
	
	// Check if there are invoices with currency different from current folio currency
	vQry = New Query();
	vQry.Text = "SELECT
	            |	SettlementServices.Folio,
	            |	SettlementServices.FolioCurrency
	            |FROM
	            |	Document.Settlement.Services AS SettlementServices
	            |WHERE
	            |	SettlementServices.Ref.Posted
	            |	AND SettlementServices.Folio = &qFolio
	            |	AND SettlementServices.FolioCurrency <> &qFolioCurrency
	            |
	            |ORDER BY
	            |	SettlementServices.Ref.PointInTime";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qFolioCurrency", FolioCurrency);
	vQryRes = vQry.Execute().Unload();
	For Each vQryRow In vQryRes Do
		vErrText = NStr("en='There are invoices for the folio N " + TrimAll(Number) + 
		                    " in " + TrimAll(vQryRow.FolioCurrency) + " currency that differs from the new " + TrimAll(FolioCurrency) + " folio currency! " + 
							"Please mark those settlements for deletion and create new ones after completion of folio currency change.';
						|de='Es gibt Rechnungen für das Folio Nr. " + TrimAll(Number) + 
		                    " in der " + TrimAll(vQryRow.FolioCurrency) + " Währung, die sich von der neuen Foliowährung " + TrimAll(FolioCurrency) + " unterscheidet! " + 
							"Bitte markieren Sie diese Rechnungen zum Löschen und erstellen Sie nach Abschluss der Foliowährungsänderung neue.';
		                |ru='По фолио № " + TrimAll(Number) + " существуют акты в валюте " + TrimAll(vQryRow.FolioCurrency) + 
						    ", которая отличается от новой валюты лицевого счета " + TrimAll(FolioCurrency) + 
							". Пожалуйста удалите эти акты и, после изменения валюты лицевого счета, создайте новые акты.'");
		Raise vErrText;
	EndDo;
	
	// What to repost
	vRepostCharges = False;
	vRepostPayments = False;
	
	// Check if there are payments or preauthorisations with currency different from current folio currency
	vQry = New Query();
	vQry.Text = "SELECT
	            |	Payments.Recorder,
	            |	Payments.FolioCurrency
	            |FROM
	            |	AccumulationRegister.Accounts AS Payments
	            |WHERE
	            |	Payments.Folio = &qFolio
	            |	AND Payments.FolioCurrency <> &qFolioCurrency
	            |	AND (NOT Payments.Recorder REFS Document.CloseOfPeriod)
	            |	AND Payments.RecordType = VALUE(AccumulationRecordType.Expense)
	            |	AND Payments.PaymentMethod <> &qSettlement
	            |
	            |ORDER BY
	            |	Payments.PointInTime";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qFolioCurrency", FolioCurrency);
	vQry.SetParameter("qSettlement", Catalogs.PaymentMethods.Settlement);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vRepostPayments = True;
	EndIf;

	// If there are payments with company different from this folio company then we have to cancel operation
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accounts.Recorder.Company AS Company,
	|	SUM(Accounts.Sum) AS SumExpense,
	|	SUM(Accounts.Limit) AS LimitExpense
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.Folio = &qFolio 
	|	AND NOT (Accounts.Recorder REFS Document.CloseOfPeriod)
	|	AND Accounts.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Accounts.PaymentMethod <> &qSettlement
	|
	|GROUP BY
	|	Accounts.Recorder.Company";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qSettlement", Catalogs.PaymentMethods.Settlement);
	vQryRes = vQry.Execute().Unload();
	For Each vQryRow In vQryRes Do
		If vQryRow.Company <> Null And vQryRow.Company <> Company Then
			If vQryRow.SumExpense <> 0 Or vQryRow.LimitExpense <> 0 Then
				vErrText = NStr("en='Folio N " + TrimAll(Number) + " has payments posted for company: " + Chars.LF + 
				                TrimAll(vQryRow.Company) + "!  
							    |You should annulate payments or do return before changing folio company to the new value: " + Chars.LF +  
							    TrimAll(Company) + "';
								|de='Folio N " + TrimAll(Number) + " has payments posted for company: " + Chars.LF + 
				                TrimAll(vQryRow.Company) + "!  
							    |You should annulate payments or do return before changing folio company to the new value: " + Chars.LF +  
							    TrimAll(Company) + "';
				                |ru='По фолио № " + TrimAll(Number) + " проведены платежи по фирме: " + Chars.LF +
				                TrimAll(vQryRow.Company) + ", 
						        |которая отличается от нового значения фирмы: " + Chars.LF + 
							    TrimAll(Company) + " 
							    |Перед изменением фирмы необходимо аннулировать существующие платежи или оформить по ним возвраты!'");
				Raise vErrText;
			EndIf;
		EndIf;
	EndDo;

	// Otherwise we have to repost payments and fix customer/contract parameters there
	If vOldCustomer <> Customer Or vOldContract <> Contract Then
		vRepostPayments = True;
	EndIf;

	// Repost payments
	If vRepostPayments Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Accounts.Recorder AS Recorder
		|FROM
		|	AccumulationRegister.Accounts AS Accounts
		|WHERE
		|	Accounts.Folio = &qFolio
		|	AND (NOT Accounts.Recorder REFS Document.CloseOfPeriod)
		|	AND Accounts.RecordType = VALUE(AccumulationRecordType.Expense)
		|
		|ORDER BY
		|	Accounts.PointInTime";
		vQry.SetParameter("qFolio", Ref);
		vQryRes = vQry.Execute().Unload();
		#IF CLIENT THEN
			// Show progress bar
			ProgressForm = GetCommonForm("Progress");
			ProgressForm.Open();
			ProgressForm.MaxValue = vQryRes.Count();
			ProgressForm.Value = 0;
			ProgressForm.ActionRemarks = NStr("en='Change folio data';ru='Изменение лицевого счета';de='Änderung des Personenkontos'");
			ProgressForm.Value = 0;
			ProgressForm.ValueRemarks = NStr("en='Repost payments...';ru='Перепроведение платежей...';de='Neue Durchführung von Zahlungen...'");
		#ENDIF
		i = 1;
		For Each vQryRow In vQryRes Do
			If TypeOf(vQryRow.Recorder) = Type("DocumentRef.Payment") Or TypeOf(vQryRow.Recorder) = Type("DocumentRef.Return") Then
				vDocObj = vQryRow.Recorder.GetObject();
				If vDocObj <> Undefined Then
					vDocObj.AccountingCustomer = vNewCustomer;
					vDocObj.AccountingContract = vNewContract;
					vDocObj.GuestGroup = GuestGroup;
					If vDocObj.FolioCurrency <> FolioCurrency Then
						vDocObj.FolioCurrency = FolioCurrency;
						vDocObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vDocObj.Hotel, vDocObj.FolioCurrency, vDocObj.ExchangeRateDate);
	                	vDocObj.pmRecalculateSums();
					EndIf;
					vSkipThisDoc = False;
					If ValueIsFilled(Hotel) And Not Hotel.AutomaticallyChangePaymentAccountingCustomerToTheFolioOne And 
					   Hotel.DoNotEditClosedDateDocs And ValueIsFilled(Hotel.AccountingDate) And 
					   vDocObj.Date < Hotel.AccountingDate Then
						vSkipThisDoc = True;
					EndIf;
					If Not vSkipThisDoc Then
						vDocObj.Write(DocumentWriteMode.Posting);
					EndIf;
				EndIf;
			ElsIf TypeOf(vQryRow.Recorder) = Type("DocumentRef.Preauthorisation") Then
				vDocObj = vQryRow.Recorder.GetObject();
				If vDocObj <> Undefined Then
					vDocObj.GuestGroup = GuestGroup;
					If vDocObj.FolioCurrency <> FolioCurrency Then
						vDocObj.FolioCurrency = FolioCurrency;
						vDocObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vDocObj.Hotel, vDocObj.FolioCurrency, vDocObj.ExchangeRateDate);
	                	vDocObj.pmRecalculateSums();
					EndIf;
					vSkipThisDoc = False;
					If ValueIsFilled(Hotel) And Not Hotel.AutomaticallyChangePaymentAccountingCustomerToTheFolioOne And 
					   Hotel.DoNotEditClosedDateDocs And ValueIsFilled(Hotel.AccountingDate) And 
					   vDocObj.Date < Hotel.AccountingDate Then
						vSkipThisDoc = True;
					EndIf;
					If Not vSkipThisDoc Then
						vDocObj.Write(DocumentWriteMode.Posting);
					EndIf;
				EndIf;
			EndIf;
			// Show progress status
			#IF CLIENT THEN
				ProgressForm.Value = i;
			#ENDIF
			i = i + 1;
		EndDo;
		// Close progress bar
		#IF CLIENT THEN
			ProgressForm.Value = 0;
			If ProgressForm.IsOpen() Then
				ProgressForm.Close();
			EndIf;
			ProgressForm = Undefined;
		#ENDIF
		
		// Repost deposit transfers
		vQry = New Query();
		vQry.Text = 
		"SELECT DISTINCT
		|	Accounts.Recorder AS Recorder,
		|	Accounts.PointInTime AS PointInTime
		|FROM
		|	AccumulationRegister.Accounts AS Accounts
		|WHERE
		|	Accounts.Folio = &qFolio
		|	AND Accounts.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND Accounts.Recorder REFS Document.DepositTransfer
		|
		|ORDER BY
		|	PointInTime";
		vQry.SetParameter("qFolio", Ref);
		vQryRes = vQry.Execute().Unload();
		i = 1;
		For Each vQryRow In vQryRes Do
			If TypeOf(vQryRow.Recorder) = Type("DocumentRef.DepositTransfer") Then
				vDocObj = vQryRow.Recorder.GetObject();
				If vDocObj <> Undefined Then
					vSkipThisDoc = False;
					If ValueIsFilled(Hotel) And Not Hotel.AutomaticallyChangePaymentAccountingCustomerToTheFolioOne And 
					   Hotel.DoNotEditClosedDateDocs And ValueIsFilled(Hotel.AccountingDate) And 
					   vDocObj.Date < Hotel.AccountingDate Then
						vSkipThisDoc = True;
					EndIf;
					If Not vSkipThisDoc Then
						vDocObj.Write(DocumentWriteMode.Posting);
					EndIf;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;

	// Check if currency has changed for some charges
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accounts.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.Folio = &qFolio
	|	AND Accounts.FolioCurrency <> &qFolioCurrency
	|	AND Accounts.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|ORDER BY
	|	Accounts.PointInTime";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qFolioCurrency", FolioCurrency);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vRepostCharges = True;
	EndIf;
	
	// Check should we repost charges
	If Not vRepostCharges And Not IsMaster Then
		If vOldCompany <> Company Or vOldCustomer <> Customer Or vOldContract <> Contract Then
			vRepostCharges = True;
		EndIf;
	EndIf;
	
	// Check if hotel product has changed for all charges
	If ValueIsFilled(HotelProduct) Then
		If vOldHotelProduct <> HotelProduct Then
			vRepostCharges = True;
		EndIf;
		// Fill hotel product payment date
		If Not ValueIsFilled(HotelProduct.PaymentDate) Then
			vHPObj = HotelProduct.GetObject();
			If vHPObj <> Undefined Then
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
	
	// Do charges reposting
	If vRepostCharges Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Accounts.Recorder AS Recorder
		|FROM
		|	AccumulationRegister.CurrentAccountsReceivable AS Accounts
		|WHERE
		|	Accounts.Charge.Folio = &qFolio
		|	AND Accounts.RecordType = VALUE(AccumulationRecordType.Receipt)
		|
		|ORDER BY
		|	Accounts.PointInTime";
		vQry.SetParameter("qFolio", Ref);
		vQryRes = vQry.Execute().Unload();
		#IF CLIENT THEN
			// Show progress bar
			ProgressForm = GetCommonForm("Progress");
			ProgressForm.Open();
			ProgressForm.MaxValue = vQryRes.Count();
			ProgressForm.Value = 0;
			ProgressForm.ActionRemarks = NStr("en='Change folio data';ru='Изменение лицевого счета';de='Änderung des Personenkontos'");
			ProgressForm.Value = 0;
			ProgressForm.ValueRemarks = NStr("en='Repost charges...';ru='Перепроведение начислений...';de='Neue Durchführung von Anrechnungen...'");
		#ENDIF
		i = 1;
		For Each vQryRow In vQryRes Do
			vDocObj = vQryRow.Recorder.GetObject();
			If vDocObj <> Undefined Then
				If TypeOf(vQryRow.Recorder) = Type("DocumentRef.Charge") Then
					vDocObj.Company = Company;
					If vDocObj.FolioCurrency <> FolioCurrency Then
						If ValueIsFilled(FolioCurrency) And vDocObj.Quantity <> 0 Then
							vOldCurrency = vDocObj.FolioCurrency;
							vOldCurrencyExchangeRate = vDocObj.FolioCurrencyExchangeRate;
							vDocObj.FolioCurrency = FolioCurrency;
							vDocObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vDocObj.Hotel, vDocObj.FolioCurrency, vDocObj.ExchangeRateDate);
							// Sum & Price
							vDocObj.Sum = cmConvertCurrencies(vDocObj.Sum, vOldCurrency, vOldCurrencyExchangeRate, vDocObj.FolioCurrency, vDocObj.FolioCurrencyExchangeRate, vDocObj.ExchangeRateDate, vDocObj.Hotel);
							vDocObj.Price = Round(vDocObj.Sum/vDocObj.Quantity, 2);
							// VAT Sum
							vDocObj.VATSum = cmCalculateVATSum(vDocObj.VATRate, vDocObj.Sum, vDocObj.Date);
							// Discount
							vDocObj.DiscountSum = 0;
							vDocObj.VATDiscountSum = 0;
							If ValueIsFilled(vDocObj.Service) Then
								If cmIsServiceInServiceGroup(vDocObj.Service, vDocObj.DiscountServiceGroup) Then
									vDocObj.DiscountSum = Round(vDocObj.Sum * vDocObj.Discount / 100, 2);
									vDocObj.VATDiscountSum = cmCalculateVATSum(vDocObj.VATRate, vDocObj.DiscountSum, vDocObj.Date);
								EndIf;
							EndIf;
							// Commission
							vDocObj.CommissionSum = 0;
							vDocObj.VATCommissionSum = 0;
							If ValueIsFilled(vDocObj.Service) Then
								If cmIsServiceInServiceGroup(vDocObj.Service, vDocObj.AgentCommissionServiceGroup) Then
									vDocObj.pmCommissionCalculationProcedure();
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If ValueIsFilled(HotelProduct) And HotelProduct <> vDocObj.HotelProduct Then
						If ValueIsFilled(vDocObj.VATRate) And vDocObj.VATRate.NoVAT Then
							vDocObj.HotelProduct = HotelProduct;
						EndIf;
					EndIf;
				EndIf;
				vDocObj.Write(DocumentWriteMode.Posting);
			EndIf;
			// Show progress status
			#IF CLIENT THEN
				ProgressForm.Value = i;
			#ENDIF
			i = i + 1;
		EndDo;
		// Close progress bar
		#IF CLIENT THEN
			ProgressForm.Value = 0;
			If ProgressForm.IsOpen() Then
				ProgressForm.Close();
			EndIf;
			ProgressForm = Undefined;
		#ENDIF
	EndIf;
	
	// Check should we repost invoices or not 
	vDoRepostInvoices = False;
	If ValueIsFilled(PaymentMethod) Then
		If ValueIsFilled(Hotel) And Not Hotel.SwitchOffRepostingOfSettlements Then
			If ValueIsFilled(Company) And Not Company.SettlementsDoNotChangeFolioBalances Then
				vDoRepostInvoices = True;
			EndIf;
		EndIf;
	ENdIf;
	If vDoRepostInvoices Then
		// Get folio balance
		vFolioBalance = pmGetBalance();
		If vFolioBalance <> 0 Then
			vFolioDebetAmount = pmGetServicesTurnover();
			If PaymentMethod.IsByBankTransfer Then
				// Get invoices for this folio
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	Settlements.Settlement AS Settlement,
				|	Settlements.Settlement.PointInTime AS PointInTime
				|FROM
				|	(SELECT
				|		SettlementServices.Ref AS Settlement
				|	FROM
				|		Document.Settlement.Services AS SettlementServices
				|	WHERE
				|		SettlementServices.Folio = &qFolio
				|		AND SettlementServices.Ref.Posted
				|		AND SettlementServices.Sum <> 0) AS Settlements
				|
				|GROUP BY
				|	Settlements.Settlement,
				|	Settlements.Settlement.PointInTime
				|
				|ORDER BY
				|	PointInTime";
				vQry.SetParameter("qFolio", Ref);
				vSettlements = vQry.Execute().Unload();
				For Each vSettlementsRow In vSettlements Do
					vSettlementObj = vSettlementsRow.Settlement.GetObject();
					If vSettlementObj <> Undefined Then
						vSettlementObj.pmPostToAccountsAndPayments();
					EndIf;
				EndDo;
			Else
				// If there are any account movements made by settlements
				// then we have to repost those settlements
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	Accounts.Recorder AS Settlement,
				|	Accounts.Recorder.PointInTime AS PointInTime
				|FROM
				|	AccumulationRegister.Accounts AS Accounts
				|WHERE
				|	Accounts.Folio = &qFolio
				|	AND Accounts.PaymentMethod = &qSettlement
				|	AND Accounts.RecordType = &qExpense
				|	AND Accounts.Recorder REFS Document.Settlement
				|
				|GROUP BY
				|	Accounts.Recorder,
				|	Accounts.Recorder.PointInTime
				|
				|ORDER BY
				|	PointInTime";
				vQry.SetParameter("qFolio", Ref);
				vQry.SetParameter("qSettlement", Catalogs.PaymentMethods.Settlement);
				vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
				vSettlements = vQry.Execute().Unload();
				For Each vSettlementsRow In vSettlements Do
					vSettlementObj = vSettlementsRow.Settlement.GetObject();
					If vSettlementObj <> Undefined Then
						vSettlementObj.pmPostToAccountsAndPayments();
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("CatalogRef.ObjectTemplates") Then
			// Fill attributes with default values
			pmFillAttributesWithDefaultValues();
			// Fill attributes based on object template
			If ValueIsFilled(pBase.DiscountType) Then
				FolioDiscountType = pBase.DiscountType;
			EndIf;
			If ValueIsFilled(pBase.Company) Then
				Company = pBase.Company;
			EndIf;
			DoNotUpdateCompany = pBase.DoNotUpdateCompany;
			DoNotFillAgent = pBase.DoNotFillAgent;
			If ValueIsFilled(pBase.FolioCurrency) Then
				FolioCurrency = pBase.FolioCurrency;
			EndIf;
			If ValueIsFilled(pBase.Customer) Then
				Customer = pBase.Customer;
			EndIf;
			If ValueIsFilled(pBase.Contract) Then
				Contract = pBase.Contract;
			EndIf;
			If ValueIsFilled(pBase.Agent) Then
				Agent = pBase.Agent;
			EndIf;
			If ValueIsFilled(pBase.GuestGroup) Then
				GuestGroup = pBase.GuestGroup;
			EndIf;
			If ValueIsFilled(pBase.Client) Then
				Client = pBase.Client;
			EndIf;
			If ValueIsFilled(pBase.PaymentSection) Then
				PaymentSection = pBase.PaymentSection;
			EndIf;
			If ValueIsFilled(pBase.Room) Then
				Room = pBase.Room;
			EndIf;
			If ValueIsFilled(pBase.DateTimeFrom) Then
				DateTimeFrom = pBase.DateTimeFrom;
			EndIf;
			If ValueIsFilled(pBase.DateTimeTo) Then
				DateTimeTo = pBase.DateTimeTo;
			EndIf;
			If pBase.UseCurrentDateForTheFolioPeriod Then
				DateTimeFrom = BegOfDay(CurrentSessionDate());
				DateTimeTo = EndOfDay(CurrentSessionDate());
			EndIf;
			If ValueIsFilled(pBase.PaymentMethod) Then
				PaymentMethod = pBase.PaymentMethod;
			EndIf;
			If pBase.CreditLimit <> 0 Then
				CreditLimit = pBase.CreditLimit;
			EndIf;
			IsClosed = pBase.IsClosed;
			IsMaster = pBase.IsMaster;
			DoNotUpdateCompany = pBase.DoNotUpdateCompany;
			// Fill folio description
			Description = pBase.FolioDescription;
		EndIf;
	EndIf;
EndProcedure // Filling

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	IsClosed = False;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(FolioCurrency) Then
			FolioCurrency = Hotel.FolioCurrency;
		EndIf;
		If Not ValueIsFilled(PaymentMethod) Then
			PaymentMethod = Hotel.PlannedPaymentMethod;
		EndIf;
		If Not ValueIsFilled(Company) Then
			Company = Hotel.Company;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If Not ValueIsFilled(FolioCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта лицевого счета> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "FolioCurrency", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
//  Get folio balance
//
// Parameters:
//  pDate			 - Date	- If is not specified, then function calculates current balance
//  pHotel			 - CatalogRef.Hotels - If is not specified, then function calculates balance for the folio hotel
//  pPaymentSection	 - CatalogRef.PaymentSections - Then function calculates balance for the given payment section only
//  pLimit			 - Boolean - Limit
// 
// Returns:
//  Number - Folio balance
//
Function pmGetBalance(Val pDate = Undefined, Val pHotel = Undefined, Val pPaymentSection = Undefined, pLimit = 0) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
		vHotel = pHotel;
		If Not ValueIsFilled(vHotel) Then
			vHotel = Hotel;
		EndIf;
		If ValueIsFilled(vHotel) Then
			If vHotel.ShowDebtsOnCurrentDate Then
				pDate = CurrentSessionDate();
			EndIf;
		EndIf;
	EndIf;

	// Build query to get accounts balance
	rVATBalance = 0;
	vAccBalance = 0;
	vLimit = 0;
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	SUM(ISNULL(AccountsBalance.SumBalance, 0)) AS SumBalance, 
	|	-SUM(ISNULL(AccountsBalance.LimitBalance, 0)) AS LimitBalance, " +
		?(ValueIsFilled(pHotel), "AccountsBalance.Hotel AS Hotel, ", "") + 
	"	AccountsBalance.FolioCurrency AS FolioCurrency,
	|	AccountsBalance.Folio AS Folio
	|FROM
	|	AccumulationRegister.Accounts.Balance(&qDate, " +
		?(ValueIsFilled(pHotel), "Hotel = &qHotel AND ", "") +
		?(pPaymentSection <> Undefined, "PaymentSection = &qPaymentSection AND ", "") +
		"FolioCurrency = &qFolioCurrency AND Folio = &qFolio) AS AccountsBalance
	|GROUP BY " +
		?(ValueIsFilled(pHotel), "AccountsBalance.Hotel, ", "") +
	"	AccountsBalance.FolioCurrency,
	|	AccountsBalance.Folio";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qFolioCurrency", FolioCurrency);
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qPaymentSection", pPaymentSection);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vAccBalance = vAccBalance + vQryResRow.SumBalance;
		vLimit = vLimit + vQryResRow.LimitBalance;
	EndDo;	
	pLimit = vLimit;
	
	Return vAccBalance;
EndFunction // pmGetBalance

// -----------------------------------------------------------------------------
// Get folio payment section balances
// - pDate is optional. If is not specified, then function calculates current balance
// - pHotel is optional. If is not specified, then function calculates balance for the 
//   folio hotel. If it is not specified, then function calculates balance per all hotels.
// - pPaymentSection is optional. If it is specified, then function calculates balance for the given payment section only
// Returns balances for each folio payment section in a value table
// -----------------------------------------------------------------------------
Function pmGetPaymentSectionBalances(Val pDate = Undefined, Val pHotel = Undefined, Val pPaymentSection = Undefined, pAdvancesOnly = False) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
		vHotel = pHotel;
		If Not ValueIsFilled(vHotel) Then
			vHotel = Hotel;
		EndIf;
		If ValueIsFilled(vHotel) Then
			If vHotel.ShowDebtsOnCurrentDate Then
				pDate = CurrentSessionDate();
			EndIf;
		EndIf;
	EndIf;

	// Build query to get accounts balance
	rVATBalance = 0;
	vAccBalance = 0;
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	SUM(ISNULL(AccountsBalance.SumBalance, 0)) AS SumBalance, " +
		?(ValueIsFilled(pHotel), "AccountsBalance.Hotel AS Hotel, ", "") + 
	"	AccountsBalance.FolioCurrency AS FolioCurrency,
	|	AccountsBalance.PaymentSection AS PaymentSection,
	|	AccountsBalance.PaymentSection.VATRate AS VATRate,
	|	AccountsBalance.Folio AS Folio
	|FROM
	|	AccumulationRegister.Accounts.Balance(&qDate, " +
		?(ValueIsFilled(pHotel), "Hotel = &qHotel AND ", "") +
		?(pPaymentSection <> Undefined, "PaymentSection = &qPaymentSection AND ", "") +
		?(pAdvancesOnly, "PaymentSection.ChequeItemType = VALUE(Enum.ChequeItemTypes.Payment) AND ", "") +
		"FolioCurrency = &qFolioCurrency AND Folio = &qFolio) AS AccountsBalance
	|GROUP BY " +
		?(ValueIsFilled(pHotel), "AccountsBalance.Hotel, ", "") +
	"	AccountsBalance.FolioCurrency,
	|	AccountsBalance.PaymentSection, 
	|	AccountsBalance.Folio
	|ORDER BY
	|	AccountsBalance.PaymentSection.Code,
	|	AccountsBalance.PaymentSection.Description";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qFolioCurrency", FolioCurrency);
	vQry.SetParameter("qFolio", Ref);
	If pPaymentSection <> Undefined Then
		vQry.SetParameter("qPaymentSection", pPaymentSection);
	EndIf;	
	vQryRes = vQry.Execute().Unload();
	If ValueIsFilled(Company) And Company.IsUsingSimpleTaxSystem Then
		For Each vRow In vQryRes Do
			vRow.VATRate = Company.VATRate;
		EndDo;
	EndIf;
	Return vQryRes;
EndFunction // pmGetPaymentSectionBalances

// -----------------------------------------------------------------------------
// Get folio cheque services balances
// - pDate is optional. If is not specified, then function calculates current balance
// - pHotel is optional. If is not specified, then function calculates balance for the 
//   folio hotel. If it is not specified, then function calculates balance per all hotels.
// - pService is optional. If it is specified, then function calculates balance for the given service only
// Returns balances for each folio payment section in a value table
// -----------------------------------------------------------------------------
Function pmGetChequeServicesBalances(Val pBalanceDate = Undefined, Val pHotel = Undefined, Val pService = Undefined, Val pDate = Undefined) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pBalanceDate) Then
		pBalanceDate = '39991231235959';
		vHotel = pHotel;
		If Not ValueIsFilled(vHotel) Then
			vHotel = Hotel;
		EndIf;
		If ValueIsFilled(vHotel) Then
			If vHotel.ShowDebtsOnCurrentDate Then
				pBalanceDate = CurrentSessionDate();
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(pDate) Then
		pDate = pBalanceDate;
	EndIf;

	// Build query to get accounts balance
	rVATBalance = 0;
	vAccBalance = 0;
	vQry = New Query;
	vQry.Text =	"SELECT
	           	|	AccountsBalance.Hotel AS Hotel,
	           	|	AccountsBalance.Folio AS Folio,
	           	|	AccountsBalance.FolioCurrency AS FolioCurrency,
	           	|	AccountsBalance.PaymentSection AS PaymentSection,
	           	|	AccountsBalance.ChequeService AS ChequeService,
	           	|	AccountsBalance.ChequeServicePrice AS ChequeServicePrice,
	           	|	CASE
	           	|		WHEN ISNULL(ActiveServicePrices.VATRate, VALUE(Catalog.VATRates.EmptyRef)) <> VALUE(Catalog.VATRates.EmptyRef)
	           	|			THEN ActiveServicePrices.VATRate
	           	|		WHEN ISNULL(AccountsBalance.PaymentSection.VATRate, VALUE(Catalog.VATRates.EmptyRef)) <> VALUE(Catalog.VATRates.EmptyRef)
	           	|			THEN AccountsBalance.PaymentSection.VATRate
	           	|		ELSE NULL
	           	|	END AS VATRate,
	           	|	AccountsBalance.Item AS Item,
	           	|	AccountsBalance.MarkingCode AS MarkingCode,
	           	|	AccountsBalance.SumBalance AS SumBalance,
	           	|	AccountsBalance.ChequeServiceQuantityBalance AS ChequeServiceQuantityBalance
	           	|FROM
	           	|	AccumulationRegister.Accounts.Balance(
	           	|			&qBalanceDate,
	           	|			(&qHotelIsEmpty
	           	|				OR NOT &qHotelIsEmpty
	           	|					AND Hotel = &qHotel)
	           	|				AND (&qChequeServiceIsUndefined
	           	|					OR NOT &qChequeServiceIsUndefined
	           	|						AND ChequeService = &qChequeService)
	           	|				AND FolioCurrency = &qFolioCurrency
	           	|				AND Folio = &qFolio) AS AccountsBalance
	           	|		LEFT JOIN InformationRegister.ServicePrices.SliceLast(
	           	|				&qDate,
	           	|				(&qHotelIsEmpty
	           	|						AND Hotel = VALUE(Catalog.Hotels.EmptyRef)
	           	|					OR NOT &qHotelIsEmpty
	           	|						AND Hotel = &qHotel
	           	|					OR NOT &qHotelIsEmpty
	           	|						AND Hotel = VALUE(Catalog.Hotels.EmptyRef))
	           	|					AND (&qChequeServiceIsUndefined
	           	|						OR NOT &qChequeServiceIsUndefined
	           	|							AND Service = &qChequeService)) AS ActiveServicePrices
	           	|		ON (AccountsBalance.Hotel = ActiveServicePrices.Hotel
	           	|				OR ActiveServicePrices.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	           	|			AND AccountsBalance.ChequeService = ActiveServicePrices.Service
	           	|			AND (ActiveServicePrices.ClientType = VALUE(Catalog.ClientTypes.EmptyRef))";
	vQry.SetParameter("qBalanceDate", pBalanceDate);
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qFolioCurrency", FolioCurrency);
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qChequeService", pService);
	vQry.SetParameter("qChequeServiceIsUndefined", pService = Undefined);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		If Not ValueIsFilled(vQryResRow.ChequeService) Then
			vRowIndex = vQryRes.IndexOf(vQryResRow);
			If vRowIndex > 0 Then
				vQryRes.Move(vQryResRow, -vRowIndex);
				Break;
			EndIf;
		EndIf;
	EndDo;
	// Merge corrections
	i = 0;
	While i < vQryRes.Count() Do
		vQryResRowI = vQryRes.Get(i);
		If vQryResRowI.SumBalance <> 0 And vQryResRowI.ChequeServiceQuantityBalance = 0 Then // This is correction
			vModSumBalanceI = ?(vQryResRowI.SumBalance < 0, -vQryResRowI.SumBalance, vQryResRowI.SumBalance);
			vChequeServiceQuantityI = 1;
			If vQryResRowI.ChequeServicePrice <> 0 Then
				vChequeServiceQuantityI = Round(vQryResRowI.SumBalance/vQryResRowI.ChequeServicePrice, 7);
				If vChequeServiceQuantityI = 0 Then
					vChequeServiceQuantityI = 1;
				EndIf;
			EndIf;
			vProcessed = False;
			j = 0;
			While j < vQryRes.Count() Do
				vQryResRowJ = vQryRes.Get(j);
				If vQryResRowI.ChequeService = vQryResRowJ.ChequeService And vQryResRowI.PaymentSection = vQryResRowJ.PaymentSection And vQryResRowJ.ChequeServiceQuantityBalance > 0 And vModSumBalanceI <= vQryResRowJ.ChequeServicePrice Then
					k = 0;
					While k < vChequeServiceQuantityI Do
						If vQryResRowJ.ChequeServiceQuantityBalance > 1 Then
							vQryResRowJ.ChequeServiceQuantityBalance = vQryResRowJ.ChequeServiceQuantityBalance - 1;
							vQryResRowJ.SumBalance = Round(vQryResRowJ.ChequeServiceQuantityBalance*vQryResRowJ.ChequeServicePrice, 2);
							
							// Create new row
							If i > j Then
								i = i + 1;
							EndIf;
							j = j + 1;
							vQryResRowJ1 = vQryRes.Insert(j);
							FillPropertyValues(vQryResRowJ1, vQryResRowJ);
							vQryResRowJ1.ChequeServiceQuantityBalance = 1;
							vQryResRowJ1.ChequeServicePrice = vQryResRowJ1.ChequeServicePrice + Round(vQryResRowI.SumBalance/vChequeServiceQuantityI, 2);
							vQryResRowJ1.SumBalance = vQryResRowJ1.ChequeServicePrice;
						Else
							vQryResRowJ.SumBalance = vQryResRowJ.SumBalance + Round(vQryResRowI.SumBalance/vChequeServiceQuantityI, 2);
							vQryResRowJ.ChequeServicePrice = Round(vQryResRowJ.SumBalance/vQryResRowJ.ChequeServiceQuantityBalance, 2);
							If Round(vQryResRowJ.ChequeServicePrice*vQryResRowJ.ChequeServiceQuantityBalance, 2) <> vQryResRowJ.SumBalance Then
								vQryResRowJ.ChequeServiceQuantityBalance = Round(vQryResRowJ.SumBalance/vQryResRowJ.ChequeServicePrice, 7);
							EndIf;
						EndIf;
						k = k + 1;
					EndDo;
					vProcessed = True;
					Break;
				EndIf;
				j = j + 1;
			EndDo;
			If vProcessed Then
				vQryRes.Delete(i);
				Continue;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	vQryRes.GroupBy("Hotel, FolioCurrency, PaymentSection, ChequeService, ChequeServicePrice, VATRate, Folio, Item, MarkingCode", "SumBalance, ChequeServiceQuantityBalance");
	// Fill price and quantity
	For Each vQryResRow In vQryRes Do
		If vQryResRow.SumBalance <> 0 And vQryResRow.ChequeServiceQuantityBalance = 0 Then
			vQryResRow.ChequeServicePrice = ?(vQryResRow.SumBalance < 0, -vQryResRow.SumBalance, vQryResRow.SumBalance);
			vQryResRow.ChequeServiceQuantityBalance = ?(vQryResRow.SumBalance < 0, -1, 1);
		EndIf;
	EndDo;
	// Check VAT rate
	If ValueIsFilled(Company) And Company.IsUsingSimpleTaxSystem Then
		For Each vQryResRow In vQryRes Do
			vQryResRow.VATRate = Company.VATRate;
		EndDo;
	EndIf;
	Return vQryRes;
EndFunction // pmGetChequeServicesBalances

// -----------------------------------------------------------------------------
Function pmGetAllFolioTransactions(pRecordersList = Undefined, pHideCorrections = False, pParentDoc = Undefined, pShowInvoices = False, pShowOrderItems = False) Export
	vQry = New Query();
	vQry.Text = cmGetTransactionsQueryText(pShowOrderItems);
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qRecordersList", pRecordersList);
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qEmptyEmployee", Catalogs.Employees.EmptyRef());
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQry.SetParameter("qSettlement", Catalogs.PaymentMethods.Settlement);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qHideCorrections", pHideCorrections);
	vQry.SetParameter("qEmptyCharge", Documents.Charge.EmptyRef());
	vQry.SetParameter("qShowInvoices", pShowInvoices);
	vQry.SetParameter("qParentDocIsUndefined", pParentDoc = Undefined);
	vQry.SetParameter("qRecordersListIsUndefined", pRecordersList = Undefined);
	vQry.SetParameter("qShowOrderItems", ValueIsFilled(Hotel) And Hotel.SplitFolioBalanceByServicesAndPrices And pShowOrderItems); 
	Return vQry.Execute().Unload();
EndFunction // pmGetAllFolioTransactions

// -----------------------------------------------------------------------------
Function pmGetFolioFromChargeTransfers() Export
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	ChargeTransfers.Ref AS Document,
	|	ChargeTransfers.ParentCharge AS Charge,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	ChargeTransfers.FolioFrom AS Folio,
	|	ChargeTransfers.ParentDoc AS FolioParentDoc,
	|	ChargeTransfers.ParentCharge.ParentDoc AS ChargeParentDoc,
	|	ChargeTransfers.FolioTo.Client AS FolioClient,
	|	ChargeTransfers.ParentCharge.Service AS Service,
	|	ChargeTransfers.ParentCharge.Service.SortCode AS ServiceSortCode,
	|	ChargeTransfers.ParentCharge.Service.Description AS ServiceDescription,
	|	ChargeTransfers.Date AS Period,
	|	BEGINOFPERIOD(ChargeTransfers.Date, DAY) AS AccountingDate,
	|	BEGINOFPERIOD(ChargeTransfers.Date, MONTH) AS AccountingMonth,
	|	ChargeTransfers.ParentCharge.ServiceDate AS ServiceDate,
	|	ChargeTransfers.Remarks AS Remarks,
	|	ChargeTransfers.ParentCharge.Number AS RecorderNumber,
	|	ChargeTransfers.ParentCharge.IsRoomRevenue AS IsRoomRevenue,
	|	ChargeTransfers.ParentCharge.IsInPrice AS IsInPrice,
	|	ChargeTransfers.ParentCharge.CalendarDayType AS CalendarDayType,
	|	ChargeTransfers.FolioTo.Room AS Room,
	|	ChargeTransfers.ParentCharge.Resource AS Resource,
	|	ChargeTransfers.ParentCharge.VATRate AS VATRate,
	|	ChargeTransfers.ParentCharge.Performer AS Performer,
	|	ISNULL(ChargeTransfers.FolioTo.Room.SortCode, 99999999) AS RoomSortCode,
	|	ISNULL(ChargeTransfers.ParentCharge.Resource.SortCode, 0) AS ResourceSortCode,
	|	ChargeTransfers.ParentCharge.AccommodationType AS AccommodationType,
	|	ISNULL(ChargeTransfers.ParentCharge.AccommodationType.SortCode, 99999999) AS AccommodationTypeSortCode,
	|	ISNULL(ChargeTransfers.ParentCharge.AccommodationType.Description, """") AS AccommodationTypeDescription,
	|	ChargeTransfers.FolioTo.Client AS Client,
	|	ChargeTransfers.FolioTo.Client.FullName AS ClientFullName,
	|	ChargeTransfers.ParentCharge.RoomRate AS RoomRate,
	|	ChargeTransfers.ParentCharge.RoomRate.Code AS RoomRateCode,
	|	ChargeTransfers.ParentCharge.RoomRate.Description AS RoomRateDescription,
	|	FALSE AS IsCorrection,
	|	ChargeTransfers.ParentCharge.Price AS Price,
	|	ChargeTransfers.ParentCharge.DiscountSum AS Discount,
	|	ChargeTransfers.ParentCharge.Sum - ChargeTransfers.ParentCharge.DiscountSum AS Sum,
	|	ChargeTransfers.ParentCharge.VATSum - ChargeTransfers.ParentCharge.VATDiscountSum AS VATSum,
	|	ChargeTransfers.ParentCharge.Quantity AS Quantity
	|FROM
	|	Document.ChargeTransfer AS ChargeTransfers
	|WHERE
	|	ChargeTransfers.FolioFrom = &qFolio
	|	AND ChargeTransfers.Posted
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qFolio", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetFolioFromChargeTransfers

// -----------------------------------------------------------------------------
Function pmGetRoomRateServicesTurnover(pPeriodFrom = '00010101', pPeriodTo = '39991231235959', pPaymentSection = Undefined) Export
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	Accounts.FolioCurrency AS FolioCurrency,
	|	SUM(Accounts.Sum) AS Sum
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.Folio = &qFolio AND NOT (Accounts.Recorder REFS Document.CloseOfPeriod)
	|	AND Accounts.Period >= &qPeriodFrom
	|	AND Accounts.Period < &qPeriodTo
	|	AND (Accounts.PaymentSection = &qPaymentSection
	|			OR (NOT &qPaymentSectionIsSet))
	|	AND Accounts.RecordType = &qReceipt
	|	AND (NOT Accounts.Recorder.IsAdditional)
	|GROUP BY
	|	Accounts.FolioCurrency";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qPaymentSection", pPaymentSection);
	vQry.SetParameter("qPaymentSectionIsSet", ?(pPaymentSection = Undefined, False, True));
	vQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		Return vQryRes.Get(0).Sum;
	Else
		Return 0;
	EndIf;
EndFunction // pmGetRoomRateServicesTurnover

// -----------------------------------------------------------------------------
Function pmGetServicesTurnover(pPeriodFrom = '00010101', pPeriodTo = '39991231235959', pPaymentSection = Undefined) Export
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	Accounts.FolioCurrency AS FolioCurrency,
	|	SUM(Accounts.Sum) AS Sum
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.Folio = &qFolio AND NOT (Accounts.Recorder REFS Document.CloseOfPeriod)
	|	AND Accounts.Period >= &qPeriodFrom
	|	AND Accounts.Period < &qPeriodTo
	|	AND (Accounts.PaymentSection = &qPaymentSection
	|			OR (NOT &qPaymentSectionIsSet))
	|	AND Accounts.RecordType = &qReceipt
	|GROUP BY
	|	Accounts.FolioCurrency";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qPaymentSection", pPaymentSection);
	vQry.SetParameter("qPaymentSectionIsSet", ?(pPaymentSection = Undefined, False, True));
	vQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		Return vQryRes.Get(0).Sum;
	Else
		Return 0;
	EndIf;
EndFunction // pmGetServicesTurnover

// -----------------------------------------------------------------------------
Function pmGetAllFolioTransactionsCount() Export
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	COUNT(Accounts.Recorder) AS Count
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.Folio = &qFolio
	|	AND NOT Accounts.Recorder REFS Document.CloseOfPeriod";
	vQry.SetParameter("qFolio", Ref);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vRow = vQryRes.Get(0);
		Return vRow.Count;
	Else
		Return 0;
	EndIf;
EndFunction // pmGetAllFolioTransactionsCount

// -----------------------------------------------------------------------------
Function pmGetAllFolioCharges() Export
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	Accounts.Recorder AS Document,
	|	Accounts.Charge AS Charge,
	|	Accounts.Folio,
	|	Accounts.PaymentSection,
	|	Accounts.Service,
	|	Accounts.Sum,
	|	Accounts.VATSum,
	|	Accounts.Quantity,
	|	Accounts.Price,
	|	Accounts.Period,
	|	Accounts.Remarks,
	|	Accounts.PaymentMethod,
	|	Accounts.Recorder.Number AS RecorderNumber,
	|	Accounts.Recorder.Payer AS Payer,
	|	Accounts.IsRoomRevenue,
	|	Accounts.IsInPrice,
	|	Accounts.CalendarDayType
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.Folio = &qFolio
	|	AND Accounts.RecordType = &qReceipt
	|ORDER BY
	|	Accounts.Period";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	Return vQry.Execute().Unload();
EndFunction // pmGetAllFolioCharges

// -----------------------------------------------------------------------------
Function pmGetAllFolioPayments(pPostedOnly = True, pSortDescending = False) Export
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	FolioPayments.Period AS Period,
	|	FolioPayments.Recorder AS Document,
	|	FolioPayments.Recorder.Number AS Number,
	|	FolioPayments.Payer AS Payer,
	|	FolioPayments.Recorder.PaymentSection AS PaymentSection,
	|	FolioPayments.PaymentMethod AS PaymentMethod,
	|	FolioPayments.Author AS Author,
	|	FolioPayments.CashRegister AS CashRegister,
	|	FolioPayments.Recorder.Status AS Status,
	|	FolioPayments.FolioCurrency AS FolioCurrency,
	|	FALSE AS IsAnnulated,
	|	SUM(FolioPayments.Sum) AS Sum,
	|	SUM(FolioPayments.Limit) AS Limit
	|FROM
	|	AccumulationRegister.FolioPayments AS FolioPayments
	|WHERE
	|	FolioPayments.Folio = &qFolio
	|
	|GROUP BY
	|	FolioPayments.Period,
	|	FolioPayments.Recorder,
	|	FolioPayments.Recorder.Number,
	|	FolioPayments.Payer,
	|	FolioPayments.Recorder.PaymentSection,
	|	FolioPayments.PaymentMethod,
	|	FolioPayments.Author,
	|	FolioPayments.CashRegister,
	|	FolioPayments.Recorder.Status,
	|	FolioPayments.FolioCurrency
	|
	|UNION ALL
	|
	|SELECT
	|	AnnulatedPayments.Date,
	|	AnnulatedPayments.Ref,
	|	AnnulatedPayments.SumInFolioCurrency,
	|	0,
	|	AnnulatedPayments.Number,
	|	AnnulatedPayments.Payer,
	|	AnnulatedPayments.PaymentSection,
	|	AnnulatedPayments.PaymentMethod,
	|	AnnulatedPayments.Author,
	|	AnnulatedPayments.CashRegister,
	|	&qAnnulationStatus,
	|	AnnulatedPayments.FolioCurrency,
	|	TRUE
	|FROM
	|	Document.Payment AS AnnulatedPayments
	|WHERE
	|	NOT &qPostedOnly
	|	AND AnnulatedPayments.Folio = &qFolio
	|	AND AnnulatedPayments.DeletionMark
	|	AND AnnulatedPayments.DateOfAnnulation > &qEmptyDate
	|
	|ORDER BY
	|	Period" + ?(pSortDescending, " DESC", "");
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qPostedOnly", pPostedOnly);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qAnnulationStatus", NStr("en='Is annulated';ru='Аннулирован';de='Storniert'"));
	Return vQry.Execute().Unload();
EndFunction // pmGetAllFolioPayments

// -----------------------------------------------------------------------------
Function pmGetAllFolioPaymentsCount() Export
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	COUNT(FolioPayments.Recorder) AS Count
	|FROM
	|	AccumulationRegister.FolioPayments AS FolioPayments
	|WHERE
	|	FolioPayments.Folio = &qFolio";
	vQry.SetParameter("qFolio", Ref);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vRow = vQryRes.Get(0);
		Return vRow.Count;
	Else
		Return 0;
	EndIf;
EndFunction // pmGetAllFolioPaymentsCount

// -----------------------------------------------------------------------------
Function pmGetAllFolioSettlements() Export
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	AccountsReceivable.Folio AS Folio,
	|	AccountsReceivable.Period AS Period,
	|	AccountsReceivable.Recorder AS Document,
	|	AccountsReceivable.Recorder.Number AS Number,
	|	AccountsReceivable.AccountingCustomer AS Customer,
	|	AccountsReceivable.AccountingContract AS Contract,
	|	AccountsReceivable.AccountingCurrency AS Currency,
	|	AccountsReceivable.GuestGroup AS GuestGroup,
	|	AccountsReceivable.Company AS Company,
	|	AccountsReceivable.Recorder.Author AS Author,
	|	SUM(AccountsReceivable.Sum) AS Sum
	|FROM
	|	AccumulationRegister.AccountsReceivable AS AccountsReceivable
	|WHERE
	|	AccountsReceivable.Folio = &qFolio
	|GROUP BY
	|	AccountsReceivable.Folio,
	|	AccountsReceivable.Period,
	|	AccountsReceivable.Recorder,
	|	AccountsReceivable.AccountingCustomer,
	|	AccountsReceivable.AccountingContract,
	|	AccountsReceivable.AccountingCurrency,
	|	AccountsReceivable.GuestGroup,
	|	AccountsReceivable.Company,
	|	AccountsReceivable.Recorder.Number,
	|	AccountsReceivable.Recorder.Author
	|ORDER BY
	|	Period";
	vQry.SetParameter("qFolio", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetAllFolioSettlements

// -----------------------------------------------------------------------------
Function pmGetAllFolioProformaInvoices() Export
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	Invoices.ParentDoc AS Folio,
	|	Invoices.Date AS Period,
	|	Invoices.Ref AS Document,
	|	Invoices.Number AS Number,
	|	Invoices.AccountingCustomer AS Customer,
	|	Invoices.AccountingContract AS Contract,
	|	Invoices.AccountingCurrency AS Currency,
	|	Invoices.GuestGroup AS GuestGroup,
	|	Invoices.Company AS Company,
	|	Invoices.Author AS Author,
	|	Invoices.Sum AS Sum
	|FROM
	|	Document.ProformaInvoice AS Invoices
	|WHERE
	|	Invoices.ParentDoc = &qFolio
	|	AND Invoices.Posted
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qFolio", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetAllFolioProformaInvoices

// -----------------------------------------------------------------------------
Function pmGetUnpostedFolioSettlements() Export
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	Settlements.Ref AS Invoice
	|FROM
	|	Document.Settlement AS Settlements
	|WHERE
	|	Settlements.ParentDoc = &qFolio
	|	AND NOT Settlements.DeletionMark
	|	AND NOT Settlements.Posted
	|
	|ORDER BY
	|	Settlements.PointInTime";
	vQry.SetParameter("qFolio", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetUnpostedFolioSettlements

// -----------------------------------------------------------------------------
Function pmGetAllFolioSettlementsRowsCount() Export
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable AS CurrentAccountsReceivable
	|WHERE
	|	CurrentAccountsReceivable.Folio = &qFolio";
	vQry.SetParameter("qFolio", Ref);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vRow = vQryRes.Get(0);
		Return vRow.Count;
	Else
		Return 0;
	EndIf;
EndFunction // pmGetAllFolioSettlementsRowsCount

// -----------------------------------------------------------------------------
Function pmGetAllChargeTransfersFrom() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ChargeTransfer.Ref AS Document,
	|	ChargeTransfer.ParentCharge.Date AS Period,
	|	ChargeTransfer.ParentCharge.Service AS Service,
	|	ChargeTransfer.ParentCharge.Sum AS Sum,
	|	ChargeTransfer.ParentCharge.VATRate AS VATRate,
	|	ChargeTransfer.FolioFrom,
	|	ChargeTransfer.FolioTo,
	|	ChargeTransfer.Remarks,
	|	ChargeTransfer.Author
	|FROM
	|	Document.ChargeTransfer AS ChargeTransfer
	|WHERE
	|	ChargeTransfer.Posted
	|	AND ChargeTransfer.FolioFrom = &qFolioFrom
	|ORDER BY
	|	ChargeTransfer.PointInTime";
	vQry.SetParameter("qFolioFrom", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetAllChargeTransfersFrom

// -----------------------------------------------------------------------------
Function pmGetCurrentAccountsReceivableChargesWithBalances(pDate = Undefined) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;

	// Build query to get services
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	CurrentAccountsReceivableBalance.Hotel AS Hotel,
	|	CurrentAccountsReceivableBalance.Company AS Company,
	|	CurrentAccountsReceivableBalance.Customer AS Customer,
	|	CurrentAccountsReceivableBalance.Contract AS Contract,
	|	CurrentAccountsReceivableBalance.GuestGroup AS GuestGroup,
	|	CurrentAccountsReceivableBalance.FolioCurrency AS FolioCurrency,
	|	CurrentAccountsReceivableBalance.Charge.Folio AS Folio,
	|	CurrentAccountsReceivableBalance.Charge.ParentDoc AS ParentDoc,
	|	CurrentAccountsReceivableBalance.Charge.HotelProduct AS HotelProduct,
	|	CurrentAccountsReceivableBalance.Charge AS Charge,
	|	CurrentAccountsReceivableBalance.Charge.Discount AS Discount,
	|	CurrentAccountsReceivableBalance.Charge.DiscountSum AS DiscountSum,
	|	CurrentAccountsReceivableBalance.Charge.AgentCommissionType AS AgentCommissionType,
	|	CurrentAccountsReceivableBalance.Charge.AgentCommission AS AgentCommission,
	|	CurrentAccountsReceivableBalance.Charge.Folio.Description AS FolioDescription,
	|	CurrentAccountsReceivableBalance.CommissionSumBalance AS CommissionSumBalance,
	|	CurrentAccountsReceivableBalance.SumBalance AS SumBalance,
	|	CurrentAccountsReceivableBalance.VATSumBalance AS VATSumBalance,
	|	CurrentAccountsReceivableBalance.QuantityBalance AS QuantityBalance
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Balance(
	|			&qPeriod,
	|			Charge.Folio = &qFolio
	|				AND FolioCurrency = &qCurrency) AS CurrentAccountsReceivableBalance
	|
	|ORDER BY
	|	CurrentAccountsReceivableBalance.Charge.PointInTime";
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qCurrency", FolioCurrency);
	vQryRes = vQry.Execute().Unload();
	
	Return vQryRes;
EndFunction // pmGetCurrentAccountsReceivableChargesWithBalances

// -----------------------------------------------------------------------------
Function pmGetHotelProducts() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charge.HotelProduct
	|FROM
	|	Document.Charge AS Charge
	|WHERE
	|	Charge.Posted
	|	AND Charge.HotelProduct <> &qEmptyHotelProduct
	|	AND Charge.Folio = &qFolio
	|GROUP BY
	|	Charge.HotelProduct
	|ORDER BY
	|	Charge.HotelProduct.Code";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	Return vQry.Execute().Unload();
EndFunction // pmGetHotelProducts

// -----------------------------------------------------------------------------
Procedure pmChargeServicePackage(pServicePackage, pClientType, pClientTypeConfirmationText = "", pServicesPerformers = Undefined, pMarketingCode = Undefined, pMarketingCodeConfirmationText = "", pSourceOfBusiness = Undefined, pDate = Undefined) Export
	If Not ValueIsFilled(pServicePackage) Then
		Raise NStr("en='Service package is not specified!';ru='Для начисления на лицевой счет не выбран пакет услуг!';de='Für die Anrechnung auf das Personenkonto wurde kein Dienstleistungspaket gewählt!'");
	EndIf;    
	vServicePackagesServices = Catalogs.ServicePackages.GetServices(pServicePackage, ?(ValueIsFilled(pDate), pDate, CurrentSessionDate()), CurrentSessionDate());
	vPackageServices = vServicePackagesServices.FindRows(New Structure("ClientType", pClientType));
	If ValueIsFilled(pClientType) And vPackageServices.Count() = 0 Then
		vPackageServices = vServicePackagesServices.FindRows(New Structure("ClientType", Catalogs.ClientTypes.EmptyRef()));
	EndIf;
	// Do some initialization
	vIsCheckIn = True;
	vIsCheckOut = True;
	vIsRoomChange = False;
	vIsBeforeRoomChange = False;
	If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
		If ValueIsFilled(ParentDoc.AccommodationStatus) Then
			vIsCheckIn = ParentDoc.AccommodationStatus.IsCheckIn;
			vIsCheckOut = ParentDoc.AccommodationStatus.IsCheckOut;
			vIsRoomChange = ParentDoc.AccommodationStatus.IsRoomChange;
			If ParentDoc.AccommodationStatus.IsActive And Not ParentDoc.AccommodationStatus.IsCheckOut Then
				vIsBeforeRoomChange = True;
			EndIf;
		EndIf;
	EndIf;
	vParentDocObj = Undefined;
	If ValueIsFilled(ParentDoc) Then
		vParentDocObj = ParentDoc.GetObject();
	EndIf;
	vIsBasedOnReservation = False;
	If ValueIsFilled(ParentDoc) Then
		If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") And ParentDoc.IsByReservation Then
			If vIsCheckIn Then
				vIsBasedOnReservation = True;
			EndIf;
		ElsIf TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
			vIsBasedOnReservation = True;
		EndIf;
	EndIf;
	// Choose rows of the client type choosen
	i = -1;
	For Each vServicePackageRow In vPackageServices Do
		i = i + 1;
		// Check accommodation type
		If ValueIsFilled(ParentDoc) Then
			If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
				If ValueIsFilled(vServicePackageRow.AccommodationType) And 
				   vServicePackageRow.AccommodationType <> ParentDoc.AccommodationType Then
					Continue;
				EndIf;
			EndIf;
		EndIf;
		
		// Services period
		vDateTimeFrom = DateTimeFrom;
		If Not ValueIsFilled(vDateTimeFrom) Then
			vDateTimeFrom = BegOfDay(CurrentSessionDate());
		EndIf;
		vDateTimeTo = DateTimeTo;
		If Not ValueIsFilled(vDateTimeTo) Then
			vDateTimeTo = EndOfDay(CurrentSessionDate());
		EndIf;
		
		// Get accounting date from the package service settings
		vAccountingDatesList = New ValueList();
		If ValueIsFilled(pDate) Then
			vAccountingDatesList.Add(pDate);
		ElsIf ValueIsFilled(vServicePackageRow.AccountingDate) Then
			vAccountingDatesList.Add(BegOfDay(vServicePackageRow.AccountingDate));
		ElsIf vServicePackageRow.AccountingDayNumber = 9999 Then
			vAccountingDatesList.Add(BegOfDay(vDateTimeTo));
		ElsIf vServicePackageRow.AccountingDayNumber <> 0 Then
			vAccountingDatesList.Add(BegOfDay(vDateTimeFrom) + (vServicePackageRow.AccountingDayNumber - 1)*24*3600);
		ElsIf ValueIsFilled(vServicePackageRow.QuantityCalculationRule) Then
			vCurDate = BegOfDay(vDateTimeFrom);
			While vCurDate <= BegOfDay(vDateTimeTo) Do
				// Check calendar day type
				If ValueIsFilled(vServicePackageRow.CalendarDayType) Then
					If ValueIsFilled(ParentDoc) Then
						If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
							vRoomRate = ParentDoc.RoomRate;
							vPriceCalculationDate = ParentDoc.PriceCalculationDate;
							If ParentDoc.RoomRates.Count() > 0 Then
								vRoomRatesRow = ParentDoc.RoomRates.Find(vCurDate, "AccountingDate");
								If vRoomRatesRow <> Undefined Then
									If ValueIsFilled(vRoomRatesRow.RoomRate) Then
										vRoomRate = vRoomRatesRow.RoomRate;
										If ValueIsFilled(vRoomRatesRow.PriceCalculationDate) Then
											vPriceCalculationDate = vRoomRatesRow.PriceCalculationDate;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
							vCalendarDayType = cmGetCalendarDayType(vRoomRate, vCurDate, ParentDoc.CheckInDate, ParentDoc.CheckOutDate, , ?(ValueIsFilled(ParentDoc.RoomTypeUpgrade), ParentDoc.RoomTypeUpgrade, ParentDoc.RoomType), vPriceCalculationDate);
							If vCalendarDayType <> vServicePackageRow.CalendarDayType Then
								// Go to the next date
								vCurDate = vCurDate + 24*3600;
								Continue;
							EndIf;
						ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
							vCalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
							vCalendar = Catalogs.Calendars.EmptyRef();
							If ValueIsFilled(ParentDoc.Resource) And ValueIsFilled(ParentDoc.Resource.Calendar) Then
								vCalendar = ParentDoc.Resource.Calendar;
							EndIf;
							If ValueIsFilled(vCalendar) Then
								vCalendarDays = vCalendar.GetObject().pmGetDays(vCurDate, vCurDate, vDateTimeFrom, vDateTimeTo, Catalogs.RoomTypes.EmptyRef());
								If vCalendarDays.Count() > 0 Then
									vCalendarDayType = vCalendarDays.Get(0).CalendarDayType;
								EndIf;
							EndIf;
							If vCalendarDayType <> vServicePackageRow.CalendarDayType Then
								// Go to the next date
								vCurDate = vCurDate + 24*3600;
								Continue;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				// Fill parameters
				vCurPrice = vServicePackageRow.Price;
				vCurCurrency = vServicePackageRow.Currency;
				vCurRemarks = "";
				vIsDayUse = False;
				vWrkDate = vCurDate;
				// Calculate quantity
				vCurQuantity = cmCalculateServiceQuantity(vServicePackageRow.Service, vServicePackageRow.QuantityCalculationRule, 
														  vWrkDate, vDateTimeFrom, vDateTimeTo, 
														  vParentDocObj, vParentDocObj, vIsCheckIn, vIsBasedOnReservation, 
														  vIsBeforeRoomChange, vIsRoomChange, vIsCheckOut, False, 
														  vCurPrice, vCurCurrency, vCurRemarks, vIsDayUse);
				// Add current accounting date if quantity being calculated is not equal zero
				If vCurQuantity <> 0 Then
					vAccountingDatesList.Add(vWrkDate);
				EndIf;
				// Go to the next date
				vCurDate = vCurDate + 24*3600;
			EndDo;
		ElsIf Not ValueIsFilled(vServicePackageRow.QuantityCalculationRule) And Not ValueIsFilled(vServicePackageRow.AccountingDate) And vServicePackageRow.AccountingDayNumber = 0 Then
			// Add all days
			vCurDate = BegOfDay(vDateTimeFrom);
			While vCurDate <= BegOfDay(vDateTimeTo) Do
				// Check calendar day type
				If ValueIsFilled(vServicePackageRow.CalendarDayType) Then
					If ValueIsFilled(ParentDoc) Then
						If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
							vRoomRate = ParentDoc.RoomRate;
							vPriceCalculationDate = ParentDoc.PriceCalculationDate;
							If ParentDoc.RoomRates.Count() > 0 Then
								vRoomRatesRow = ParentDoc.RoomRates.Find(vCurDate, "AccountingDate");
								If vRoomRatesRow <> Undefined Then
									If ValueIsFilled(vRoomRatesRow.RoomRate) Then
										vRoomRate = vRoomRatesRow.RoomRate;
										If ValueIsFilled(vRoomRatesRow.PriceCalculationDate) Then
											vPriceCalculationDate = vRoomRatesRow.PriceCalculationDate;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
							vCalendarDayType = cmGetCalendarDayType(vRoomRate, vCurDate, ParentDoc.CheckInDate, ParentDoc.CheckOutDate, , ?(ValueIsFilled(ParentDoc.RoomTypeUpgrade), ParentDoc.RoomTypeUpgrade, ParentDoc.RoomType), vPriceCalculationDate);
							If vCalendarDayType <> vServicePackageRow.CalendarDayType Then
								// Go to the next date
								vCurDate = vCurDate + 24*3600;
								Continue;
							EndIf;
						ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
							vCalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
							vCalendar = Catalogs.Calendars.EmptyRef();
							If ValueIsFilled(ParentDoc.Resource) And ValueIsFilled(ParentDoc.Resource.Calendar) Then
								vCalendar = ParentDoc.Resource.Calendar;
							EndIf;
							If ValueIsFilled(vCalendar) Then
								vCalendarDays = vCalendar.GetObject().pmGetDays(vCurDate, vCurDate, vDateTimeFrom, vDateTimeTo, Catalogs.RoomTypes.EmptyRef());
								If vCalendarDays.Count() > 0 Then
									vCalendarDayType = vCalendarDays.Get(0).CalendarDayType;
								EndIf;
							EndIf;
							If vCalendarDayType <> vServicePackageRow.CalendarDayType Then
								// Go to the next date
								vCurDate = vCurDate + 24*3600;
								Continue;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				// Add current accounting date
				vAccountingDatesList.Add(vCurDate);
				// Go to the next date
				vCurDate = vCurDate + 24*3600;
			EndDo;
		EndIf;
		
		For Each vAccountingDatesItem In vAccountingDatesList Do
			vAccountingDate = vAccountingDatesItem.Value;
			
			// Add charge
			vChargeObj = Documents.Charge.CreateDocument();
			vChargeObj.Fill(Ref);
			vChargeObj.SetTime(AutoTimeMode.CurrentOrLast);
			vChargeObj.Service = vServicePackageRow.Service;
			vChargeObj.PaymentSection = vChargeObj.Service.PaymentSection;
			vChargeObj.IsRoomRevenue = vChargeObj.Service.IsRoomRevenue;
			vChargeObj.RoomRevenueAmountsOnly = vChargeObj.Service.RoomRevenueAmountsOnly;
			vChargeObj.IsResourceRevenue = vChargeObj.Service.IsResourceRevenue;
			vChargeObj.IsInPrice = vServicePackageRow.IsInPrice;
			vChargeObj.IsManual = True;
			vChargeObj.IsAdditional = True;
			vChargeObj.Remarks = vServicePackageRow.Remarks;
			vChargeObj.Company = Company;
			If ValueIsFilled(pClientType) Then 
				vChargeObj.ClientType = pClientType;
				If Not IsBlankString(pClientTypeConfirmationText) Then
					vChargeObj.ClientTypeConfirmationText = pClientTypeConfirmationText;
				EndIf;
			EndIf;
			
			// Fill accounting date
			vChargeObj.ServiceDate = ?(ValueIsFilled(vAccountingDate), vAccountingDate, CurrentSessionDate());
			// Fill calendar day type
			If (vChargeObj.IsManual Or vChargeObj.IsAdditional) And 
			   ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) <> Type("DocumentRef.ResourceReservation") And 
			   ValueIsFilled(ParentDoc.RoomRate) Then
				vChargeObj.CalendarDayType = cmGetCalendarDayType(ParentDoc.RoomRate, vChargeObj.Date, ParentDoc.CheckInDate, ParentDoc.CheckOutDate, , ?(ValueIsFilled(ParentDoc.RoomTypeUpgrade), ParentDoc.RoomTypeUpgrade, vChargeObj.RoomType), ParentDoc.PriceCalculationDate);
			EndIf;
				
			// Recalculate price
			vChargeObj.Price = Round(cmConvertCurrencies(vServicePackageRow.Price, vServicePackageRow.Currency, , 
														 vChargeObj.FolioCurrency, 
														 vChargeObj.FolioCurrencyExchangeRate, 
														 vChargeObj.ExchangeRateDate, vChargeObj.Hotel), 2);
			vChargeObj.Unit = vServicePackageRow.Unit;
			If Not Company.IsUsingSimpleTaxSystem Then
				vChargeObj.VATRate = vServicePackageRow.VATRate;
			Else
				vChargeObj.VATRate = Company.VATRate;
			EndIf;
			If ValueIsFilled(ParentDoc) Then
				vChargeObj.Quantity = vServicePackageRow.Quantity * ?(vServicePackageRow.IsServicePerPerson, ?(ParentDoc.NumberOfPersons = 0, 1, ParentDoc.NumberOfPersons), 1);
			Else
				vChargeObj.Quantity = vServicePackageRow.Quantity;
			EndIf;
			// Sum and VAT sum
			cmPriceOnChange(vChargeObj.Price, vChargeObj.Quantity, vChargeObj.Sum, vChargeObj.VATRate, vChargeObj.VATSum, vChargeObj.Date);
			// Set charge discounts
			vChargeObj.pmSetDiscounts();
			// Room sales resources
			If vChargeObj.IsRoomRevenue And Not vChargeObj.IsSplit Then
				If ValueIsFilled(ParentDoc) And 
				  (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation")) Then
					vCurPeriodInHours = 24;
					If ValueIsFilled(vChargeObj.Service.QuantityCalculationRule) Then
						If vChargeObj.Service.QuantityCalculationRule.PeriodInHours <> 0 Then
							vCurPeriodInHours = vChargeObj.Service.QuantityCalculationRule.PeriodInHours;
						EndIf;
					ElsIf ValueIsFilled(vChargeObj.RoomRate) And vChargeObj.RoomRate.PeriodInHours <> 0 Then
						vCurPeriodInHours = vChargeObj.RoomRate.PeriodInHours;
					EndIf;
					If vCurPeriodInHours <> 0 Then
						vChargeObj.RoomsRented = ?(ParentDoc.NumberOfBedsPerRoom = 0, 0, Round(ParentDoc.NumberOfBeds/ParentDoc.NumberOfBedsPerRoom*vChargeObj.Quantity*vCurPeriodInHours/24, 7));
						vChargeObj.BedsRented = Round(ParentDoc.NumberOfBeds*vChargeObj.Quantity*vCurPeriodInHours/24, 7);
						vChargeObj.AdditionalBedsRented = Round(ParentDoc.NumberOfAdditionalBeds*vChargeObj.Quantity*vCurPeriodInHours/24, 7);
						vChargeObj.GuestDays = Round(ParentDoc.NumberOfPersons*vChargeObj.Quantity*vCurPeriodInHours/24, 7);
						If BegOfDay(ParentDoc.CheckInDate) = BegOfDay(vAccountingDate) Then
							vChargeObj.GuestsCheckedIn = ParentDoc.NumberOfPersons;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			// Discount
			vChargeObj.DiscountSum = 0;
			vChargeObj.VATDiscountSum = 0;
			If vChargeObj.Discount <> 0 And cmIsServiceInServiceGroup(vChargeObj.Service, vChargeObj.DiscountServiceGroup) Then
				vChargeObj.DiscountSum = Round(vChargeObj.Sum * vChargeObj.Discount / 100, 2);
				vChargeObj.VATDiscountSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.DiscountSum, vChargeObj.Date);
			EndIf;
			// Commission
			vChargeObj.CommissionSum = 0;
			vChargeObj.VATCommissionSum = 0;
			If ValueIsFilled(vChargeObj.Service) Then
				If cmIsServiceInServiceGroup(vChargeObj.Service, vChargeObj.AgentCommissionServiceGroup) Then
					vChargeObj.pmCommissionCalculationProcedure();
				EndIf;
			EndIf;
			// Service performer
			If pServicesPerformers <> Undefined Then
				vSPRow = pServicesPerformers.Get(i);
				If vSPRow <> Undefined Then
					vChargeObj.Performer = vSPRow.Employee;
				EndIf;
			EndIf;
			// Marketing code and source of business
			If pMarketingCode <> Undefined Then
				vChargeObj.MarketingCode = pMarketingCode;
				vChargeObj.MarketingCodeConfirmationText = pMarketingCodeConfirmationText;
			EndIf;
			If pSourceOfBusiness <> Undefined Then
				vChargeObj.SourceOfBusiness = pSourceOfBusiness;
			EndIf;
			// Write current charge
			WriteLogEvent(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"), EventLogLevel.Information, vChargeObj.Metadata(), Documents.Charge.EmptyRef(), NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
			// Post charge object
			vChargeObj.Write(DocumentWriteMode.Posting);
		EndDo;
	EndDo;
EndProcedure // pmChargeServicePackage

// -----------------------------------------------------------------------------
Function pmGetFolioCertificates() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Payments.Date AS Period,
	|	Payments.GiftCertificate AS GiftCertificate
	|FROM
	|	Document.Payment AS Payments
	|WHERE
	|	Payments.Posted
	|	AND Payments.Folio = &qFolio
	|	AND Payments.PaymentMethod.IsByGiftCertificate
	|	AND Payments.GiftCertificate <> &qEmptyString
	|
	|GROUP BY
	|	Payments.Date,
	|	Payments.GiftCertificate
	|
	|ORDER BY
	|	Period,
	|	GiftCertificate";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qEmptyString", "");
	Return vQry.Execute().Unload();
EndFunction // pmGetFolioCertificates

// -----------------------------------------------------------------------------
Function pmGetFolioCertificateCharges() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charge.GiftCertificate AS GiftCertificate
	|FROM
	|	Document.Charge AS Charge
	|WHERE
	|	Charge.Posted
	|	AND Charge.Folio = &qFolio
	|	AND Charge.Service.IsGiftCertificate
	|	AND Charge.GiftCertificate <> &qEmptyString
	|
	|GROUP BY
	|	Charge.GiftCertificate
	|
	|ORDER BY
	|	GiftCertificate";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qEmptyString", "");
	Return vQry.Execute().Unload();
EndFunction // pmGetFolioCertificateCharges

// -----------------------------------------------------------------------------
Procedure pmRepostAdditionalCharges(pSkipDocRef = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accounts.Recorder AS Recorder,
	|	Accounts.Recorder.Date AS Date
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.Folio = &qFolio
	|	AND Accounts.Period > ENDOFPERIOD(Accounts.Folio.Hotel.EditProhibitedDate, DAY)
	|	AND Accounts.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND ISNULL(Accounts.Charge.IsAdditional, FALSE)
	|	AND Accounts.Recorder <> &qSkipDocRef
	|
	|ORDER BY
	|	Accounts.PointInTime";
	vQry.SetParameter("qFolio", Ref);
	vQry.SetParameter("qSkipDocRef", pSkipDocRef);
	vQryRes = vQry.Execute().Unload();
	#IF CLIENT THEN
		// Show progress bar
		ProgressForm = GetCommonForm("Progress");
		ProgressForm.Open();
		ProgressForm.MaxValue = vQryRes.Count();
		ProgressForm.Value = 0;
		ProgressForm.ActionRemarks = NStr("en='Change folio data';ru='Изменение лицевого счета';de='Änderung des Personenkontos'");
		ProgressForm.Value = 0;
		ProgressForm.ValueRemarks = NStr("en='Repost charges...';ru='Перепроведение начислений...';de='Neue Durchführung von Anrechnungen...'");
	#ENDIF
	i = 1;
	For Each vQryRow In vQryRes Do
		vSkipThisDoc = False;
		If Not IsClosed And ValueIsFilled(Hotel) And Hotel.DoNotEditClosedDateDocs And 
		   ValueIsFilled(Hotel.AccountingDate) And vQryRow.Date < Hotel.AccountingDate Then
			vSkipThisDoc = True;
		EndIf;
		If Not vSkipThisDoc Then
			vDocObj = vQryRow.Recorder.GetObject();
			vDocObj.Write(DocumentWriteMode.Posting);
		EndIf;
		// Show progress status
		#IF CLIENT THEN
			ProgressForm.Value = i;
		#ENDIF
		i = i + 1;
	EndDo;
	// Close progress bar
	#IF CLIENT THEN
		ProgressForm.Value = 0;
		If ProgressForm.IsOpen() Then
			ProgressForm.Close();
		EndIf;
		ProgressForm = Undefined;
	#ENDIF
EndProcedure // pmRepostAdditionalCharges

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function CreateIndividualsCustomer()
	// Try to find customer with guest full name
	vCustomer = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Customers.Ref AS Ref,
	|	Customers.LegacyName AS LegacyName,
	|	Customers.Description AS Description
	|FROM
	|	Catalog.Customers AS Customers
	|WHERE
	|	(NOT Customers.DeletionMark
	|				AND NOT Customers.IsFolder
	|				AND Customers.Client = &qClient
	|			OR Customers.Client = &qEmptyClient
	|				AND (Customers.Description = &qDescription
	|					AND (Customers.DateOfBirth = &qEmptyDate
	|						OR Customers.DateOfBirth = &qDateOfBirth)))
	|
	|ORDER BY
	|	Customers.Code DESC";
	vQry.SetParameter("qClient", Client);
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qDescription", Upper(TrimAll(Client.FullName)));
	vQry.SetParameter("qDateOfBirth", Client.DateOfBirth);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vCustomer = vQryRes.Get(0).Ref;
	EndIf;
	If Not ValueIsFilled(vCustomer) Then
		vCustObj = Catalogs.Customers.CreateItem();
		vIndividualsFolder = Constants.IndividualsFolder.Get();
		If Not ValueIsFilled(vIndividualsFolder) Then
			vIndividualsFolder = Catalogs.Customers.IndividualsFolder;
		EndIf;
		vCustObj.Parent = vIndividualsFolder;
		vCustObj.pmFillAttributesWithDefaultValues();
	Else
		vCustObj = vCustomer.GetObject();
	EndIf;
	vCustObj.Description = Upper(TrimAll(Client.FullName));
	vCustObj.LegacyName = Client.FullName + 
	                      ?(ValueIsFilled(Client.DateOfBirth), ", " + Format(Client.DateOfBirth, "DF=dd.MM.yyyy"), "") + 
						  ?(IsBlankString(Client.IdentityDocumentNumber), "", ", " + TrimAll(Client.IdentityDocumentType) + " " + TrimAll(Client.IdentityDocumentSeries) + " " + TrimAll(Client.IdentityDocumentNumber));
	vCustObj.LegacyAddress = Client.Address;
	vCustObj.Phone = Client.Phone;
	vCustObj.Fax = Client.Fax;
	vCustObj.EMail = Client.EMail;
	vCustObj.Language = Client.Language;
	vCustObj.IdentityDocumentIssueDate = Client.IdentityDocumentIssueDate;
	vCustObj.IdentityDocumentIssuedBy = Client.IdentityDocumentIssuedBy;
	vCustObj.IdentityDocumentNumber = Client.IdentityDocumentNumber;
	vCustObj.IdentityDocumentSeries = Client.IdentityDocumentSeries;
	vCustObj.IdentityDocumentType = Client.IdentityDocumentType;
	vCustObj.IdentityDocumentValidToDate = Client.IdentityDocumentValidToDate;
	vCustObj.DateOfBirth = Client.DateOfBirth;
	vCustObj.Client = Client;
	vCustObj.pmFillPlannedPaymentMethodFromChargingRules();
	vCustObj.IsIndividual = True;
	vCustObj.Write();
	vCustObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	vCustomer = vCustObj.Ref;
	Return vCustomer;
EndFunction // CreateIndividualsCustomer

// -----------------------------------------------------------------------------
Procedure FillAccChgAttributes(pRChgRec, pPeriod, pUser, pDoc)
	FillPropertyValues(pRChgRec, pDoc);
	
	pRChgRec.Period = pPeriod;
	pRChgRec.Accommodation = pDoc;
	pRChgRec.User = pUser;
	
	// Store tabular parts
	vPrices = New ValueStorage(pDoc.Prices.Unload());
	pRChgRec.Prices = vPrices;
	vRoomRates = New ValueStorage(pDoc.RoomRates.Unload());
	pRChgRec.RoomRates = vRoomRates;
	vServicePackages = New ValueStorage(pDoc.ServicePackages.Unload());
	pRChgRec.ServicePackages = vServicePackages;
	vServices = New ValueStorage(pDoc.Services.Unload());
	pRChgRec.Services = vServices;
	vChargingRules = New ValueStorage(pDoc.ChargingRules.Unload());
	pRChgRec.ChargingRules = vChargingRules;
	vOccupationPercents = New ValueStorage(pDoc.OccupationPercents.Unload());
	pRChgRec.OccupationPercents = vOccupationPercents;
	vRoomProperties = New ValueStorage(pDoc.RoomProperties.Unload());
	pRChgRec.RoomProperties = vRoomProperties;
EndProcedure // FillAccChgAttributes

// -----------------------------------------------------------------------------
Procedure FillResChgAttributes(pRChgRec, pPeriod, pUser, pDoc)
	FillPropertyValues(pRChgRec, pDoc);
	
	pRChgRec.Period = pPeriod;
	pRChgRec.Reservation = pDoc;
	pRChgRec.User = pUser;
	
	// Store tabular parts
	vPrices = New ValueStorage(pDoc.Prices.Unload());
	pRChgRec.Prices = vPrices;
	vRoomRates = New ValueStorage(pDoc.RoomRates.Unload());
	pRChgRec.RoomRates = vRoomRates;
	vServicePackages = New ValueStorage(pDoc.ServicePackages.Unload());
	pRChgRec.ServicePackages = vServicePackages;
	vServices = New ValueStorage(pDoc.Services.Unload());
	pRChgRec.Services = vServices;
	vChargingRules = New ValueStorage(pDoc.ChargingRules.Unload());
	pRChgRec.ChargingRules = vChargingRules;
	vRooms = New ValueStorage(pDoc.Rooms.Unload());
	pRChgRec.Rooms = vRooms;
	vOccupationPercents = New ValueStorage(pDoc.OccupationPercents.Unload());
	pRChgRec.OccupationPercents = vOccupationPercents;
	vRoomProperties = New ValueStorage(pDoc.RoomProperties.Unload());
	pRChgRec.RoomProperties = vRoomProperties;
EndProcedure // FillResChgAttributes

// -----------------------------------------------------------------------------
Procedure FillRResChgAttributes(pRChgRec, pPeriod, pUser, pDoc)
	FillPropertyValues(pRChgRec, pDoc);
	
	pRChgRec.Period = pPeriod;
	pRChgRec.ResourceReservation = pDoc;
	pRChgRec.User = pUser;
	
	// Store tabular parts
	vServicePackages = New ValueStorage(pDoc.ServicePackages.Unload());
	pRChgRec.ServicePackages = vServicePackages;
	vServices = New ValueStorage(pDoc.Services.Unload());
	pRChgRec.Services = vServices;
EndProcedure // FillRResChgAttributes

// -----------------------------------------------------------------------------
Procedure FillCustChgAttributes(pRChgRec, pPeriod, pUser, pRef)
	FillPropertyValues(pRChgRec, pRef);
	
	pRChgRec.Period = pPeriod;
	pRChgRec.Customer = pRef;
	pRChgRec.User = pUser;
	
	// Store tabular parts
	vChargingRules = New ValueStorage(pRef.ChargingRules.Unload());
	pRChgRec.ChargingRules = vChargingRules;
	vContactPersons = New ValueStorage(pRef.ContactPersons.Unload());
	pRChgRec.ContactPersons = vContactPersons;
	vRoomRates = New ValueStorage(pRef.RoomRates.Unload());
	pRChgRec.RoomRates = vRoomRates;
EndProcedure // FillCustChgAttributes

// -----------------------------------------------------------------------------
Procedure FillCltChgAttributes(pRChgRec, pPeriod, pUser, pRef)
	FillPropertyValues(pRChgRec, pRef);
	
	pRChgRec.Period = pPeriod;
	pRChgRec.Client = pRef;
	pRChgRec.User = pUser;
	
	// Store tabular parts
	vChargingRules = New ValueStorage(pRef.ChargingRules.Unload());
	pRChgRec.ChargingRules = vChargingRules;
EndProcedure // FillCltChgAttributes

// -----------------------------------------------------------------------------
Procedure BlockUsedGiftCertificates()
	
	If IsClosed And ValueIsFilled(IsClosedDate) And ValueIsFilled(IsClosedAuthor) And ValueIsFilled(Hotel) Then
		vGiftCertificatesArePerHotel = Constants.GiftCertificatesArePerHotel.Get();
		vBlockUsedGiftCertificates = Constants.GiftCertificatesCancellationAfterCheckOut.Get();
		If vBlockUsedGiftCertificates Then
			vFolioCertificates = pmGetFolioCertificates();
			For Each vFolioCertificatesRow In vFolioCertificates Do
				If Not IsBlankString(vFolioCertificatesRow.GiftCertificate) Then
					vBlockedCertificatesRM = InformationRegisters.GiftCertificates.CreateRecordManager();
					vBlockedCertificatesRM.Period = vFolioCertificatesRow.Period;
					vBlockedCertificatesRM.Hotel = ?(vGiftCertificatesArePerHotel, Hotel, Catalogs.Hotels.EmptyRef());
					vBlockedCertificatesRM.GiftCertificate = TrimAll(vFolioCertificatesRow.GiftCertificate);
					vBlockedCertificatesRM.Read();
					If vBlockedCertificatesRM.Selected() Then
						vBlockedCertificatesRM.BlockDate = BegOfDay(IsClosedDate);
						vBlockedCertificatesRM.BlockAuthor = IsClosedAuthor;
						vBlockedCertificatesRM.BlockReason = "en='Folio was closed on " + Format(vBlockedCertificatesRM.BlockDate, "DF=dd.MM.yyyy") + "!'; 
						|ru='Лицевой счет закрыт " + Format(vBlockedCertificatesRM.BlockDate, "DF=dd.MM.yyyy") + "!';
						|de='Folio wurde am " + Format(vBlockedCertificatesRM.BlockDate, "DF=dd.MM.yyyy") + " geschlossen!'";
						vBlockedCertificatesRM.Write(True);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
Procedure UpdateClientIdentificationCards()
	
	vClearCardsData = False;
	If ValueIsFilled(Hotel) Then
		vClearCardsData = Hotel.ClearClientIdentificationCardDataOnGuestsCheckOut;
	EndIf;
	vCards = cmGetClientIdentificationCardsByFolio(Ref);
	For Each vCardsRow In vCards Do
		vCardRef = vCardsRow.Ref;
		vCardObj = vCardRef.GetObject();
		If vCardObj <> Undefined Then
			If (IsClosed And Not vCardRef.IsCheckedOut) Or
				(Not IsClosed And vCardRef.IsCheckedOut) Then
				vCardObj.IsCheckedOut = IsClosed;
			ElsIf DeletionMark And Not vCardRef.IsCheckedOut Then
				vCardObj.IsCheckedOut = True;
			EndIf;
			If Not vClearCardsData Or Not IsClosed Then
				vCardObj.GuestGroup = GuestGroup;
				If ValueIsFilled(vCardObj.ParentDoc) Then
					If TypeOf(vCardObj.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardObj.ParentDoc) = Type("DocumentRef.Reservation") Then
						vCardObj.Client = vCardObj.ParentDoc.Guest;
					ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
						vCardObj.Client = vCardObj.ParentDoc.Client;
					ElsIf TypeOf(ParentDoc) = Type("DocumentRef.Folio") Then
						vCardObj.Client = vCardObj.ParentDoc.Client;
					EndIf;
				Else
					vCardObj.Client = Client;
				EndIf;
				If ValueIsFilled(vCardObj.Client) Then
					vCardObj.Description = TrimAll(vCardObj.Client.FullName);
				Else
					vCardObj.Description = "";
				EndIf;
				vCardObj.Hotel = Hotel;
				vCardObj.Room = Room;
				vCardObj.DateTimeFrom = DateTimeFrom;
				vCardObj.DateTimeTo = DateTimeTo;
				vCardObj.Write();
			Else
				vCardObj.GuestGroup = Catalogs.GuestGroups.EmptyRef();
				vCardObj.Folio = Documents.Folio.EmptyRef();
				vCardObj.ParentDoc = Undefined;
				vCardObj.Client = Catalogs.Clients.EmptyRef();
				vCardObj.Description = "";
				vCardObj.Hotel = Hotel;
				vCardObj.Room = Catalogs.Rooms.EmptyRef();
				vCardObj.DateTimeFrom = '00010101';
				vCardObj.DateTimeTo = '00010101';
				vCardObj.IsBlocked = False;
				vCardObj.BlockReason = "";
				vCardObj.Write();
			EndIf;
		EndIf;
	EndDo;

EndProcedure // OnWrite

#EndRegion

