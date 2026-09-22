
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Check payment method
	If Not ValueIsFilled(PaymentMethod) Then
		PaymentMethod = Catalogs.PaymentMethods.Settlement;
	EndIf;
	
	// Check payment section and VAT
	If ValueIsFilled(Company) And Company.SplitSettllementsByPaymentSections Then
		If Not ValueIsFilled(PaymentSection) Then
			If Services.Count() > 0 Then
				vSrvRow = Services.Get(0);
				If ValueIsFilled(vSrvRow.Service) Then
					PaymentSection = vSrvRow.Service.PaymentSection;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Company) And Company.SplitSettllementsByVATRate Then
		If Not ValueIsFilled(VATRate) Then
			If Services.Count() > 0 Then
				vSrvRow = Services.Get(0);
				VATRate = vSrvRow.VATRate;
			EndIf;
		EndIf;
	EndIf;
	
	// Get table of document services
	vAllFoliosList = New ValueList();
	vNotSortedServices = New ValueTable();
	vInvoiceServices = GetCorrectionServices(vAllFoliosList, vNotSortedServices);
	
	// Update services folio and parent doc
	For Each vServicesRow In Services Do
		vNotSortedServicesRow = vNotSortedServices.Get(Services.IndexOf(vServicesRow));
		If ValueIsFilled(vServicesRow.Charge) And vServicesRow.Charge = vNotSortedServicesRow.Charge Then
			If vServicesRow.Folio <> vNotSortedServicesRow.ChargeFolio Then
				vServicesRow.Folio = vNotSortedServicesRow.ChargeFolio;
			EndIf;
			If vServicesRow.FolioCurrency <> vNotSortedServicesRow.ChargeFolioCurrency Then
				vServicesRow.FolioCurrency = vNotSortedServicesRow.ChargeFolioCurrency;
			EndIf;
			If vServicesRow.ParentDoc <> vNotSortedServicesRow.ChargeParentDoc Then
				vServicesRow.ParentDoc = vNotSortedServicesRow.ChargeParentDoc;
			EndIf;
		EndIf;
	EndDo;
	
	// Save changes if any
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
	
	// 1. Repost invoices from this document
	For Each vInvRow In Invoices Do
		If ValueIsFilled(vInvRow.Invoice) Then
			vBalancedFoliosList = New ValueList();
			vInvObj = vInvRow.Invoice.GetObject();
			vInvObj.pmPostToAccountsAndPayments(vBalancedFoliosList);
		EndIf;
	EndDo;
	
	// 2. Post to Accounts and Payments
	vBalancedFoliosList = New ValueList();
	pmPostToAccountsAndPayments(vBalancedFoliosList);
	
	// 3. Post to CurrentAccountsReceivable
	PostToCurrentAccountsReceivable(vInvoiceServices);
	
	// 4. Post to AccountsReceivable
	PostToAccountsReceivable(vInvoiceServices);
	
	// 5. Post to Customer accounts
	PostToCustomerAccounts();
	
	// 6. Post to Invoice accounts
	PostToInvoiceAccounts();
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("CatalogRef.Customers") Then
			pmFillByCustomer(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.Contracts") Then
			pmFillByContract(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.GuestGroups") Then
			pmFillByGuestGroup(pBase);
		EndIf;
		SetNewNumber();
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Or pWriteMode = DocumentWriteMode.Write Then
		If Invoices.Count() = 1 Then
			Invoice = Invoices.Get(0).Invoice;
		Else
			Invoice = Undefined;
		EndIf;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, ThisObject.Metadata(), ThisObject.Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
		If Not Ref.Posted Or 
		   Ref.Hotel <> Hotel Or 
		   Ref.Company <> Company Or 
		   Ref.AccountingCustomer <> AccountingCustomer Or 
		   Ref.AccountingContract <> AccountingContract Or 
		   Ref.GuestGroup <> GuestGroup Or 
		   Ref.AccountingCurrency <> AccountingCurrency Or 
		   Ref.IsChecked <> IsChecked Or 
		   Ref.CorrectionSum <> CorrectionSum Then
			If Not ValueIsFilled(ChangeDate) And ValueIsFilled(Date) Then
				ChangeDate = Date;
			Else
				ChangeDate = CurrentSessionDate();
			EndIf;
			ChangeAuthor = SessionParameters.CurrentUser;
		EndIf;
	Else
		If Ref.Posted And pWriteMode = DocumentWriteMode.UndoPosting Or Not Ref.DeletionMark And Ref.Posted And DeletionMark Then
			If ValueIsFilled(Hotel) Then
				If ValueIsFilled(Hotel.EditProhibitedDate) And 
					BegOfDay(Hotel.EditProhibitedDate) >= BegOfDay(Date) Then
					pCancel = True;
				EndIf;
			EndIf;
			If ValueIsFilled(Company) Then
				If ValueIsFilled(Company.EditProhibitedDate) And 
					BegOfDay(Company.EditProhibitedDate) >= BegOfDay(Date) Then
					pCancel = True;
				EndIf;
			EndIf;
			vHasRightsToEditInvoice = cmHasRightsToEditInvoice(Company, Date, ExternalCode);
			If Not vHasRightsToEditInvoice Then
				pCancel = True;
			EndIf;  
			If Not pCancel Then
				ChangeAuthor = SessionParameters.CurrentUser;
				ChangeDate = CurrentSessionDate();
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights to edit debit note!'; de = 'Sie haben kein Recht, die Lastschrift zu ändern!'; ru = 'Нет прав изменять дебетовую корректировку!'"), MessageStatus.Attention);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Company) And Not IsBlankString(Company.Prefix) Then
		vPrefix = TrimAll(Company.Prefix);
	ElsIf ValueIsFilled(Hotel) Then
		vPrefix = TrimAll(Catalogs.Hotels.pmGetPrefix(Hotel));
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		If ValueIsFilled(SessionParameters.CurrentHotel.Company) And Not IsBlankString(SessionParameters.CurrentHotel.Company.Prefix) Then
			vPrefix = TrimAll(SessionParameters.CurrentHotel.Company.Prefix);
		Else
			vPrefix = TrimAll(Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel));
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	pmFillAuthorAndDate();
	ChangeAuthor = Undefined;
	ChangeDate = '00010101';
	ExternalCode = "";
	IsChecked = False;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function GetCorrectionServices(rFoliosList, rNotSortedServices)
	// All services
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*,
	|	Services.Charge.ParentDoc AS ChargeParentDoc,
	|	Services.Charge.Folio AS ChargeFolio,
	|	Services.Charge.Folio.GuestGroup AS ChargeFolioGuestGroup,
	|	Services.Service.PaymentSection AS ServicePaymentSection,
	|	Services.Agent.DoNotPostCommission AS AgentDoNotPostCommission,
	|	Services.Agent.AgentCommissionContract AS AgentAgentCommissionContract
	|FROM
	|	Document.DebitNote.Services AS Services
	|WHERE
	|	Services.Ref = &qInvoice
	|
	|ORDER BY
	|	Services.Charge.Folio,
	|	Services.AccountingDate,
	|	Services.Charge";
	vQry.SetParameter("qInvoice", Ref);
	vServices = vQry.Execute().Unload();
    vServicesFolios = Services.Unload(, "Folio");
	vServicesFolios.GroupBy("Folio", );
	rFoliosList = New ValueList();
	rFoliosList.LoadValues(vServicesFolios.UnloadColumn("Folio"));
	// Not sorted services
	vNSQry = New Query();
	vNSQry.Text = 
	"SELECT
	|	Services.Charge AS Charge,
	|	Services.Charge.ParentDoc AS ChargeParentDoc,
	|	Services.Charge.Folio AS ChargeFolio,
	|	Services.Charge.Folio.FolioCurrency AS ChargeFolioCurrency
	|FROM
	|	Document.DebitNote.Services AS Services
	|WHERE
	|	Services.Ref = &qInvoice
	|
	|ORDER BY
	|	Services.LineNumber";
	vNSQry.SetParameter("qInvoice", Ref);
	rNotSortedServices = vNSQry.Execute().Unload();
	// Return
	Return vServices;
EndFunction // GetCorrectionServices

// -----------------------------------------------------------------------------
Procedure pmPostToAccountsAndPayments(rFolioList = Undefined) Export
	If rFolioList = Undefined Then
		rFolioList = New ValueList();
	EndIf;
	
	// Clear movements
	RegisterRecords.Accounts.Clear();
	RegisterRecords.Accounts.Write();
	RegisterRecords.Payments.Clear();
	RegisterRecords.Payments.Write();
	RegisterRecords.PaymentServices.Clear();
	RegisterRecords.PaymentServices.Write();
	RegisterRecords.PostingsFO.Clear();
	RegisterRecords.PostingsFO.Write();
	
	// Check should we group services by payment sections
	vUsePaymentSections = False;
	vUseChequeServices = False;
	If ValueIsFilled(Hotel) Then
		If Hotel.SplitFolioBalanceByPaymentSections Then
			vUsePaymentSections = True;
		EndIf;
		If Hotel.SplitFolioBalanceByServicesAndPrices Then
			vUseChequeServices = True;
		EndIf;
	EndIf;	
	
	// Check should we write to payment services
	vUsePaymentServices = Hotel.DoPaymentsDistributionToServices;
	
	// Group services by folio
	vDoWrite2Accounts = False;
	If ValueIsFilled(Company) And Not Company.SettlementsDoNotChangeFolioBalances Then
		
		vServices = New ValueTable();
		If Not vUsePaymentSections And Not vUseChequeServices Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	CorrectionServices.Folio AS Folio,
			|	CorrectionServices.Folio.PaymentMethod AS FolioPaymentMethod,
			|	CorrectionServices.Folio.PaymentMethod.IsByBankTransfer AS FolioPaymentMethodIsByBankTransfer,
			|	CorrectionServices.Folio.Customer AS FolioCustomer,
			|	CorrectionServices.Folio.Customer.IsIndividual AS FolioCustomerIsIndividual,
			|	CorrectionServices.Folio.FinancialAccount AS FolioFinancialAccount,
			|	CorrectionServices.Folio.ParentDoc AS FolioParentDoc,
			|	CorrectionServices.VATRate AS VATRate,
			|	&qEmptyPaymentSection AS PaymentSection,
			|	SUM(CorrectionServices.VATSum) AS VATSum,
			|	SUM(CorrectionServices.Sum) AS Sum
			|FROM
			|	(SELECT
			|		CorrectionServices1.Charge.Folio AS Folio,
			|		CorrectionServices1.VATRate AS VATRate,
			|		ISNULL(Accounts1.VATSum, 0) AS VATSum,
			|		ISNULL(Accounts1.Sum, 0) AS Sum
			|	FROM
			|		Document.DebitNote.Services AS CorrectionServices1
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts1
			|			ON CorrectionServices1.Charge = Accounts1.Recorder
			|	WHERE
			|		CorrectionServices1.Ref = &qRef
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CorrectionServices2.Charge.Folio,
			|		CorrectionServices2.VATRate,
			|		ISNULL(Accounts2.VATSum, 0),
			|		ISNULL(Accounts2.Sum, 0)
			|	FROM
			|		Document.DebitNote.Services AS CorrectionServices2
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts2
			|			ON CorrectionServices2.Charge = Accounts2.Recorder.ParentCharge
			|	WHERE
			|		CorrectionServices2.Ref = &qRef) AS CorrectionServices
			|
			|GROUP BY
			|	CorrectionServices.Folio,
			|	CorrectionServices.VATRate,
			|	CorrectionServices.Folio.PaymentMethod,
			|	CorrectionServices.Folio.PaymentMethod.IsByBankTransfer,
			|	CorrectionServices.Folio.Customer,
			|	CorrectionServices.Folio.Customer.IsIndividual,
			|	CorrectionServices.Folio.FinancialAccount,
			|	CorrectionServices.Folio.ParentDoc
			|
			|HAVING
			|	SUM(CorrectionServices.Sum) <> 0";
			vQry.SetParameter("qRef", Ref);
			vQry.SetParameter("qEmptyPaymentSection", Catalogs.PaymentSections.EmptyRef());
			vServices = vQry.Execute().Unload();
		ElsIf vUsePaymentSections And Not vUseChequeServices Then 
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	CorrectionServices.Folio AS Folio,
			|	CorrectionServices.Folio.PaymentMethod AS FolioPaymentMethod,
			|	CorrectionServices.Folio.PaymentMethod.IsByBankTransfer AS FolioPaymentMethodIsByBankTransfer,
			|	CorrectionServices.Folio.Customer AS FolioCustomer,
			|	CorrectionServices.Folio.Customer.IsIndividual AS FolioCustomerIsIndividual,
			|	CorrectionServices.Folio.FinancialAccount AS FolioFinancialAccount,
			|	CorrectionServices.Folio.ParentDoc AS FolioParentDoc,
			|	CorrectionServices.PaymentSection AS PaymentSection,
			|	CorrectionServices.VATRate AS VATRate,
			|	SUM(CorrectionServices.VATSum) AS VATSum,
			|	SUM(CorrectionServices.Sum) AS Sum
			|FROM
			|	(SELECT
			|		CorrectionServices1.Charge.Folio AS Folio,
			|		CorrectionServices1.Charge.PaymentSection AS PaymentSection,
			|		CorrectionServices1.VATRate AS VATRate,
			|		ISNULL(Accounts1.VATSum, 0) AS VATSum,
			|		ISNULL(Accounts1.Sum, 0) AS Sum
			|	FROM
			|		Document.DebitNote.Services AS CorrectionServices1
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts1
			|			ON CorrectionServices1.Charge = Accounts1.Recorder
			|	WHERE
			|		CorrectionServices1.Ref = &qRef
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CorrectionServices2.Charge.Folio,
			|		CorrectionServices2.Charge.PaymentSection,
			|		CorrectionServices2.VATRate,
			|		ISNULL(Accounts2.VATSum, 0),
			|		ISNULL(Accounts2.Sum, 0)
			|	FROM
			|		Document.DebitNote.Services AS CorrectionServices2
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts2
			|			ON CorrectionServices2.Charge = Accounts2.Recorder.ParentCharge
			|	WHERE
			|		CorrectionServices2.Ref = &qRef) AS CorrectionServices
			|
			|GROUP BY
			|	CorrectionServices.Folio,
			|	CorrectionServices.PaymentSection,
			|	CorrectionServices.VATRate,
			|	CorrectionServices.Folio.PaymentMethod,
			|	CorrectionServices.Folio.PaymentMethod.IsByBankTransfer,
			|	CorrectionServices.Folio.Customer,
			|	CorrectionServices.Folio.Customer.IsIndividual,
			|	CorrectionServices.Folio.FinancialAccount,
			|	CorrectionServices.Folio.ParentDoc
			|
			|HAVING
			|	SUM(CorrectionServices.Sum) <> 0";
			vQry.SetParameter("qRef", Ref);
			vServices = vQry.Execute().Unload();
		ElsIf vUseChequeServices Then 
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	CorrectionServices.Folio AS Folio,
			|	CorrectionServices.Folio.PaymentMethod AS FolioPaymentMethod,
			|	CorrectionServices.Folio.PaymentMethod.IsByBankTransfer AS FolioPaymentMethodIsByBankTransfer,
			|	CorrectionServices.Folio.Customer AS FolioCustomer,
			|	CorrectionServices.Folio.Customer.IsIndividual AS FolioCustomerIsIndividual,
			|	CorrectionServices.Folio.FinancialAccount AS FolioFinancialAccount,
			|	CorrectionServices.Folio.ParentDoc AS FolioParentDoc,
			|	CorrectionServices.PaymentSection AS PaymentSection,
			|	CorrectionServices.ChequeService AS ChequeService,
			|	CorrectionServices.ChequeServicePrice AS ChequeServicePrice,
			|	CorrectionServices.ChequeService.PaymentSection AS ChequeServicePaymentSection,
			|	CorrectionServices.VATRate AS VATRate,
			|	SUM(CorrectionServices.ChequeServiceQuantity) AS ChequeServiceQuantity,
			|	SUM(CorrectionServices.VATSum) AS VATSum,
			|	SUM(CorrectionServices.Sum) AS Sum
			|FROM
			|	(SELECT
			|		CorrectionServices1.Charge.Folio AS Folio,
			|		CorrectionServices1.Charge.PaymentSection AS PaymentSection,
			|		CorrectionServices1.Service AS ChequeService,
			|		ISNULL(Accounts1.Price, 0) AS ChequeServicePrice,
			|		CorrectionServices1.VATRate AS VATRate,
			|		ISNULL(Accounts1.Quantity, 0) AS ChequeServiceQuantity,
			|		ISNULL(Accounts1.VATSum, 0) AS VATSum,
			|		ISNULL(Accounts1.Sum, 0) AS Sum
			|	FROM
			|		Document.DebitNote.Services AS CorrectionServices1
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts1
			|			ON CorrectionServices1.Charge = Accounts1.Recorder
			|	WHERE
			|		CorrectionServices1.Ref = &qRef
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CorrectionServices2.Charge.Folio,
			|		CorrectionServices2.Charge.PaymentSection,
			|		CorrectionServices2.Service,
			|		ISNULL(Accounts2.Price, 0),
			|		CorrectionServices2.VATRate,
			|		ISNULL(Accounts2.Quantity, 0),
			|		ISNULL(Accounts2.VATSum, 0),
			|		ISNULL(Accounts2.Sum, 0)
			|	FROM
			|		Document.DebitNote.Services AS CorrectionServices2
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts2
			|			ON CorrectionServices2.Charge = Accounts2.Recorder.ParentCharge
			|	WHERE
			|		CorrectionServices2.Ref = &qRef) AS CorrectionServices
			|
			|GROUP BY
			|	CorrectionServices.Folio,
			|	CorrectionServices.PaymentSection,
			|	CorrectionServices.ChequeService,
			|	CorrectionServices.ChequeServicePrice,
			|	CorrectionServices.ChequeService.PaymentSection,
			|	CorrectionServices.VATRate,
			|	CorrectionServices.Folio.PaymentMethod,
			|	CorrectionServices.Folio.PaymentMethod.IsByBankTransfer,
			|	CorrectionServices.Folio.Customer,
			|	CorrectionServices.Folio.Customer.IsIndividual,
			|	CorrectionServices.Folio.FinancialAccount,
			|	CorrectionServices.Folio.ParentDoc
			|
			|HAVING
			|	SUM(CorrectionServices.Sum) <> 0";
			vQry.SetParameter("qRef", Ref);
			vServices = vQry.Execute().Unload();
		EndIf;
		
		// Build value table with folio balances
		vFolios = vServices.Copy(, "Folio");
		vFolios.GroupBy("Folio", );
		vFoliosArray = vFolios.UnloadColumn("Folio");
		vFoliosList = New ValueList();
		vFoliosList.LoadValues(vFoliosArray);
		If Not vUsePaymentSections And Not vUseChequeServices Then
			vBalances = cmGetFoliosBalance('39991231235959', Hotel, Undefined, vFoliosList);
		ElsIf vUsePaymentSections Then
			vBalances = cmGetFoliosBalanceByPaymentSections('39991231235959', Hotel, Undefined, vFoliosList);
		ElsIf vUseChequeServices Then
			vBalances = cmGetFoliosBalanceByServicesAndPrices('39991231235959', Hotel, Undefined, vFoliosList);
		EndIf;
		// Get folio balance
		vFolioBalances = cmGetFoliosBalance('39991231235959', Hotel, Undefined, vFoliosList);
		
		// Do for each folio with balance
		For Each vServicesRow In vServices Do
			// Check folio payment method 
			If ValueIsFilled(vServicesRow.FolioPaymentMethod) And vServicesRow.FolioPaymentMethodIsByBankTransfer And 
			   ValueIsFilled(vServicesRow.FolioCustomer) And Not vServicesRow.FolioCustomerIsIndividual Then
				vChequeServicePrice = 0;
				vServicesRow.VATSum = cmCalculateVATSum(vServicesRow.VATRate, vServicesRow.Sum, Date);
			   
				// Find folio balances row
				vBalancesRow = Undefined;
				vFolioBalancesRow = Undefined;
				If Not vUsePaymentSections And Not vUseChequeServices Then
					vBalancesRows = vBalances.FindRows(New Structure("Folio", vServicesRow.Folio));
					If vBalancesRows.Count() > 0 Then
						vBalancesRow = vBalancesRows.Get(0);
					EndIf;
				ElsIf vUsePaymentSections And Not vUseChequeServices Then
					vBalancesRows = vBalances.FindRows(New Structure("Folio, PaymentSection", vServicesRow.Folio, vServicesRow.PaymentSection));
					If vBalancesRows.Count() > 0 Then
						vBalancesRow = vBalancesRows.Get(0);
					EndIf;
				ElsIf vUseChequeServices Then
					vChequeServicePrice = vServicesRow.ChequeServicePrice;
					If vServicesRow.ChequeServiceQuantity <> 0 Then
						vChequeServicePrice = Round(vServicesRow.Sum / vServicesRow.ChequeServiceQuantity, 2);
					EndIf;
					vBalancesRows = vBalances.FindRows(New Structure("Folio, ChequeService, ChequeServicePrice", vServicesRow.Folio, vServicesRow.ChequeService, vChequeServicePrice));
					If vBalancesRows.Count() > 0 Then
						vBalancesRow = vBalancesRows.Get(0);
					EndIf;
				EndIf;
				vFolioBalancesRows = vFolioBalances.FindRows(New Structure("Folio", vServicesRow.Folio));
				If vFolioBalancesRows.Count() > 0 Then
					vFolioBalancesRow = vFolioBalancesRows.Get(0);
				EndIf;
				If vBalancesRow <> Undefined And vFolioBalancesRow <> Undefined And vFolioBalancesRow.SumBalance <= 0 Then
					vBalancesRow.SumBalance = 0;
				EndIf;
				
				// Stop processing if folio balance is zero
				If vBalancesRow <> Undefined And vBalancesRow.SumBalance <> 0 And
				   vFolioBalancesRow <> Undefined And vFolioBalancesRow.SumBalance <> 0 Then
					If vBalancesRow.SumBalance >= 0 Then
						If vServicesRow.Sum >= 0 Then
							If vServicesRow.Sum > vBalancesRow.SumBalance Then
								vServicesRow.Sum = vBalancesRow.SumBalance;
							EndIf;
						EndIf;
					Else
						If vServicesRow.Sum < 0 Then
							If vServicesRow.Sum < vBalancesRow.SumBalance Then
								vServicesRow.Sum = vBalancesRow.SumBalance;
							EndIf;
						EndIf;
					EndIf;
					If vFolioBalancesRow <> Undefined Then
						If vFolioBalancesRow.SumBalance >=0 Then
							If vServicesRow.Sum >= 0 Then
								If vServicesRow.Sum > vFolioBalancesRow.SumBalance Then
									vServicesRow.Sum = vFolioBalancesRow.SumBalance;
								EndIf;
							EndIf;
						Else
							If vServicesRow.Sum < 0 Then
								If vServicesRow.Sum < vFolioBalancesRow.SumBalance Then
									vServicesRow.Sum = vFolioBalancesRow.SumBalance;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					vBalancesRow.SumBalance = vBalancesRow.SumBalance - vServicesRow.Sum;
					
					vFolioBalanceSignBefore = ?(vFolioBalancesRow.SumBalance >= 0, 1, -1);
					vFolioBalancesRow.SumBalance = vFolioBalancesRow.SumBalance - vServicesRow.Sum;
					vFolioBalanceSignAfter = ?(vFolioBalancesRow.SumBalance >= 0, 1, -1);
					
					If vFolioBalanceSignBefore <> vFolioBalanceSignAfter Then
						Break;
					EndIf;
				Else
					Continue;
				EndIf;			

				// Do movement
				Movement = RegisterRecords.Accounts.Add();
				
				Movement.RecordType = AccumulationRecordType.Expense;
				Movement.Period = Date;
				
				FillPropertyValues(Movement, ThisObject);
				FillPropertyValues(Movement, vServicesRow.Folio);
				FillPropertyValues(Movement, vServicesRow);
				
				// Attributes
				Movement.PaymentMethod = PaymentMethod;
				Movement.ParentDoc = vServicesRow.FolioParentDoc;
				
				// Save list of folios closed with settlement
				If rFolioList.FindByValue(Movement.Folio) = Undefined Then
					rFolioList.Add(Movement.Folio);
				EndIf;
				
				// Payment section
				If Not vUsePaymentSections And Not vUseChequeServices Then
					Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
					Movement.ChequeService = Catalogs.Services.EmptyRef();
					Movement.ChequeServicePrice = 0;
					Movement.ChequeServiceQuantity = 0;
				ElsIf vUsePaymentSections Then
					Movement.PaymentSection = vServicesRow.PaymentSection;
					Movement.ChequeService = Catalogs.Services.EmptyRef();
					Movement.ChequeServicePrice = 0;
					Movement.ChequeServiceQuantity = 0;
				ElsIf vUseChequeServices Then
					Movement.ChequeService = vServicesRow.ChequeService;
					Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
					If ValueIsFilled(Movement.ChequeService) Then
						Movement.PaymentSection = Movement.ChequeService.PaymentSection;
					Endif;
					Movement.ChequeServicePrice = vChequeServicePrice;
					Movement.ChequeServiceQuantity = vServicesRow.ChequeServiceQuantity;
				EndIf;
				
				vDoWrite2Accounts = True;
			EndIf;
		EndDo;
				
		// Group services by payment sections
		vServices.GroupBy("Folio, FolioPaymentMethod, FolioPaymentMethodIsByBankTransfer, FolioCustomer, FolioCustomerIsIndividual, FolioFinancialAccount, FolioParentDoc, PaymentSection, VATRate", "VATSum, Sum");
		
		// Create value table for FO postings
		vFOPostings = vServices.Copy(, "Folio, FolioFinancialAccount, FolioParentDoc, Sum");
		vFOPostings.Clear();
		
		For Each vServicesRow In vServices Do
			// Check folio payment method 
			If ValueIsFilled(vServicesRow.FolioPaymentMethod) And vServicesRow.FolioPaymentMethodIsByBankTransfer And 
			   ValueIsFilled(vServicesRow.FolioCustomer) And Not vServicesRow.FolioCustomerIsIndividual Then
				// Write to payments
				Movement = RegisterRecords.Payments.Add();
				
				Movement.Period = Date;
				
				FillPropertyValues(Movement, ThisObject);
				FillPropertyValues(Movement, vServicesRow);
				
				// Dimensions
				Movement.PaymentCurrency = AccountingCurrency;
				Movement.Payer = AccountingCustomer;
				Movement.AccountingDate = BegOfDay(Date);
				
				// Resources
				If vServicesRow.Sum >= 0 Then
					Movement.SumReceipt = vServicesRow.Sum;
					Movement.VATSumReceipt = vServicesRow.VATSum;
					Movement.SumExpense = 0;
					Movement.VATSumExpense = 0;
				Else
					Movement.SumReceipt = 0;
					Movement.VATSumReceipt = 0;
					Movement.SumExpense = -vServicesRow.Sum;
					Movement.VATSumExpense = -vServicesRow.VATSum;
				EndIf;
				
				// Post to FO chart of accounts
				vFOPostingsRow = vFOPostings.Add();
				vFOPostingsRow.Sum = vServicesRow.Sum;
				vFOPostingsRow.Folio = vServicesRow.Folio;
				
				// Write to payment services
				If vUsePaymentServices Then
					Movement = RegisterRecords.PaymentServices.Add();
					
					Movement.RecordType = AccumulationRecordType.Expense;
					Movement.Period = Date;
					
					Movement.Folio = vServicesRow.Folio;
					Movement.Service = Catalogs.Services.EmptyRef();
					Movement.Payment = Ref;
					
					// Fill resources
					Movement.Sum = vServicesRow.Sum;
				EndIf;
			EndIf;
		EndDo;
		
		// Post guest ledger postings to FO chart of accounts
		vFOPostings.GroupBy("Folio, FolioFinancialAccount, FolioParentDoc", "Sum");
		For Each vFOPostingsRow In vFOPostings Do
			WriteGuestLedgerFOPostings(vFOPostingsRow.Sum, vFOPostingsRow.Folio, vFOPostingsRow.FolioFinancialAccount, vFOPostingsRow.FolioParentDoc);
		EndDo;
	EndIf;
	
	// Write
	For Each vInvoicesRow In Invoices Do
		WriteCityLedgerFOPostings(vInvoicesRow, vInvoicesRow.CorrectionSum);
	EndDo;
		
	// Write records
	If vDoWrite2Accounts Then
		RegisterRecords.Accounts.Write();
		RegisterRecords.Payments.Write();
		If vUsePaymentServices Then
			RegisterRecords.PaymentServices.Write();
		EndIf;
	EndIf;
	RegisterRecords.PostingsFO.Write();
	
	// Reset auto write mode
	RegisterRecords.Accounts.Write = False;
	RegisterRecords.Payments.Write = False;
	RegisterRecords.PaymentServices.Write = False;
	RegisterRecords.PostingsFO.Write = False;
EndProcedure // pmPostToAccountsAndPayments

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
	If Not ValueIsFilled(Company) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Фирма> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Company> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das Attribut <Kompanie> sollte ausgefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Company", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(AccountingCustomer) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Контрагент> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Customer> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das Attribut <Firma> sollte ausgefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCustomer", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(AccountingCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта взаиморасчетов> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Accounting currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das Attribut <Buchhaltungswährung> sollte gefüllt sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCurrency", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(VATRate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Ставка НДС> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<VAT rate> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das Attribut <Mehrwertsteuersatz> sollte gefüllt sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCurrency", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

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
	PaymentMethod = Catalogs.PaymentMethods.Settlement;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	vHotel = Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotels = cmGetAllHotels();
		vHotel = vHotels.Get(0).Hotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		If Not ValueIsFilled(AccountingCurrency) Then
			AccountingCurrency = vHotel.BaseCurrency;
		EndIf;
		If Not ValueIsFilled(Company) Then
			Company = vHotel.Company;
		EndIf;
	EndIf;
	If ValueIsFilled(Author) And ValueIsFilled(Author.Company) Then
		Company = Author.Company;
	EndIf;
	If ValueIsFilled(Company) Then
		VATRate = Company.VATRate;
		If Not ValueIsFilled(BankAccount) Then
			If ValueIsFilled(Company.BankAccount) And (Company.BankAccount.Hotel = Hotel Or Company.BankAccount.Hotel = Catalogs.Hotels.EmptyRef()) Then
				BankAccount = Company.BankAccount;
			Else
				vQry = New Query();
				
				vQry.Text = 
				"SELECT TOP 1
				|	BankAccounts.Ref AS Ref
				|FROM
				|	Catalog.BankAccounts AS BankAccounts
				|WHERE
				|	NOT BankAccounts.DeletionMark
				|	AND BankAccounts.Owner = &qOwner
				|	AND (BankAccounts.Hotel = &qHotel
				|			OR BankAccounts.Hotel = VALUE(Catalog.Hotels.EmptyRef))
				|
				|ORDER BY
				|	BankAccounts.Hotel DESC";
				vQry.SetParameter("qHotel", Hotel);
				vQry.SetParameter("qOwner", Company);  
				vRes = vQry.Execute();
				vSel = vRes.Select();
				If vSel.Next() Then
					BankAccount = vSel.Ref;
				EndIf;	
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmFillByGuestGroup(pGuestGroup) Export
	If Not ValueIsFilled(pGuestGroup) Then
		Return;
	EndIf;
	
	// Fill customer and currency
	AccountingCustomer = pGuestGroup.Customer;
	AccountingContract = pGuestGroup.Contract;
	If ValueIsFilled(AccountingCustomer) Then
		AccountingCurrency = AccountingCustomer.AccountingCurrency;
	EndIf;
	GuestGroup = pGuestGroup;
	
	Invoices.Clear();
	
	CorrectionSum = 0;
EndProcedure // pmFillByGuestGroup

// -----------------------------------------------------------------------------
Procedure pmFillByCustomer(pCustomer) Export
	If Not ValueIsFilled(pCustomer) Then
		Return;
	EndIf;
	
	// Fill customer and currency
	AccountingCustomer = pCustomer;
	AccountingContract = Catalogs.Contracts.EmptyRef();
	AccountingCurrency = AccountingCustomer.AccountingCurrency;
	
	Invoices.Clear();
	
	CorrectionSum = 0;
EndProcedure // pmFillByCustomer

// -----------------------------------------------------------------------------
Procedure pmFillByContract(pContract) Export
	If Not ValueIsFilled(pContract) Then
		Return;
	EndIf;
	
	// Fill customer contract and currency
	AccountingCustomer = pContract.Owner;
	AccountingContract = pContract;
	AccountingCurrency = AccountingContract.AccountingCurrency;
	
	Invoices.Clear();
	
	CorrectionSum = 0;
EndProcedure // pmFillByContract

// -----------------------------------------------------------------------------
Procedure pmFillServices(pCharges, pLanguage = Undefined) Export
	For Each vFolioChargesRow In pCharges Do
		If ValueIsFilled(vFolioChargesRow.Charge) Then
			If vFolioChargesRow.Company <> Company Then
				Continue;
			EndIf;
			// Add service
			vServicesRow = Services.Add();
			If ValueIsFilled(vFolioChargesRow.Folio) Then
				vServicesRow.Client = vFolioChargesRow.Folio.Client;
				vServicesRow.Room = vFolioChargesRow.Folio.Room;
			EndIf;
			vParentDoc = vFolioChargesRow.ParentDoc;
			If ValueIsFilled(vParentDoc) Then
				If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or 
				   TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
					vServicesRow.Client = vParentDoc.Guest;
					vServicesRow.Room = vParentDoc.Room;
					vServicesRow.AccommodationType = vParentDoc.AccommodationType;
					vServicesRow.NumberOfPersons = vParentDoc.NumberOfPersons;
				ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
					vServicesRow.Client = vParentDoc.Client;
					vServicesRow.Resource = vParentDoc.Resource;
					vServicesRow.NumberOfPersons = vParentDoc.NumberOfPersons;
				EndIf;
			EndIf;
			FillPropertyValues(vServicesRow, vFolioChargesRow.Charge);
			FillPropertyValues(vServicesRow, vFolioChargesRow);
			vServicesRow.AccountingDate = BegOfDay(vFolioChargesRow.Charge.Date);
			vServicesRow.Sum = vFolioChargesRow.SumBalance;
			vServicesRow.VATSum = vFolioChargesRow.VATSumBalance;
			vServicesRow.Quantity = vFolioChargesRow.QuantityBalance;
			vServicesRow.Price = cmRecalculatePrice(vServicesRow.Sum, vServicesRow.Quantity);
			// Commission
			If ValueIsFilled(vFolioChargesRow.Folio) Then
				vServicesRow.Agent = vFolioChargesRow.Folio.Agent;
			EndIf;
			If ValueIsFilled(vFolioChargesRow.Charge) Then
				vServicesRow.AgentCommissionType = vFolioChargesRow.Charge.AgentCommissionType;
				vServicesRow.AgentCommission = vFolioChargesRow.Charge.AgentCommission;
			EndIf;
			vServicesRow.CommissionSum = vFolioChargesRow.CommissionSumBalance;
			vServicesRow.VATCommissionSum = cmCalculateVATSum(vServicesRow.VATRate, vServicesRow.CommissionSum, vServicesRow.AccountingDate);
			If vServicesRow.CommissionSum = 0 And vServicesRow.VATCommissionSum = 0 And 
			   ValueIsFilled(vServicesRow.AgentCommissionType) Then
				vServicesRow.AgentCommissionType = Undefined;
				vServicesRow.AgentCommission = 0;
			EndIf;				
			// Fill remarks by service description by default
			vServiceDescription = TrimAll(vServicesRow.Service);
			If ValueIsFilled(vServicesRow.Service) Then
				vServiceObj = vServicesRow.Service.GetObject();
				vServiceDescription = vServiceObj.pmGetServiceDescription(pLanguage);
			EndIf;
			vServicesRow.Remarks = vServiceDescription + 
			                       ?(IsBlankString(vServicesRow.Remarks), "", " - " + cmNStr(vServicesRow.Remarks, pLanguage));
		EndIf;
	EndDo;
EndProcedure // pmFillServices	

// -----------------------------------------------------------------------------
Procedure pmFillCorrectionTotals(rInvoiceSum, rCorrectionSum, rCorrectionVATSum) Export
	rInvoiceSum = 0;
	If ValueIsFilled(Invoice) Then
		rInvoiceSum = Round(cmConvertCurrencies(Invoice.Sum, Invoice.AccountingCurrency, , AccountingCurrency, , Date, Hotel), 2);
	EndIf;
	rCorrectionSum = 0;
	rCorrectionVATSum = 0;
	For Each vSrvRow In Services Do
		rCorrectionSum = rCorrectionSum + cmConvertCurrencies(vSrvRow.Sum, vSrvRow.FolioCurrency, , AccountingCurrency, , Date, Hotel);
		rCorrectionVATSum = rCorrectionSum + cmConvertCurrencies(vSrvRow.VATSum, vSrvRow.FolioCurrency, , AccountingCurrency, , Date, Hotel);
	EndDo;
	rCorrectionSum = Round(rCorrectionSum, 2);
	rCorrectionVATSum = Round(rCorrectionVATSum, 2);
	CorrectionSum = rCorrectionSum;
EndProcedure // pmFillCorrectionTotals

// ------------------------------------------------------------------------------
Function pmPrintDocument(pDocs) Export
	USE_SHORT_FORM = True;
	
	vSpreadsheet = New SpreadsheetDocument;
	vSpreadsheetTemplate = Documents.DebitNote.GetTemplate(?(USE_SHORT_FORM, "PrintFormTemplateShort", "PrintFormTemplate"));
	
	// Do for each document in the documents array
	i = 0;
	For Each vDoc In pDocs Do
		If ValueIsFilled(vDoc) Then
			If i > 0 Then
				vSpreadsheet.PutHorizontalPageBreak();
			EndIf;
			
			vHeaderArea = vSpreadsheetTemplate.GetArea("Header");
			
			vHeaderArea.Parameters.mDocumentNumber = cmGetDocumentNumberPresentation(vDoc.Number);
			vHeaderArea.Parameters.mDocumentDate = Format(vDoc.Date, "DF=dd.MM.yyyy");
			
			vLang = SessionParameters.CurrentLanguage;
			
			// Hotel
			vHotel = vDoc.Hotel;
			mHotelName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLang);
			mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, vLang);
			vHotelPhones = TrimAll(vHotel.Phones);
			vHotelFax = TrimAll(vHotel.Fax);
			vHotelEMail = TrimAll(vHotel.EMail);
			mHotelPhones = vHotelPhones + 
			               ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", vLang) + vHotelFax) + 
						   ?(IsBlankString(vHotelEMail), "", cmNStr("en=', e-mail ';de=', e-mail ';ru=', e-mail '", vLang) + vHotelEMail);
			vHeaderArea.Parameters.mHotelName = mHotelName;
			vHeaderArea.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
			vHeaderArea.Parameters.mHotelPhones = mHotelPhones;
			
			// Company
			vCompanyObj = vDoc.Company.GetObject(); 
			vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(vLang);
			vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(vLang);
			vCompanyPostAddress = vCompanyObj.pmGetCompanyPostAddressPresentation(vLang);
			If vCompanyPostAddress = vCompanyLegacyAddress Then
				vCompanyPostAddress = "";
			EndIf;
			vCompanyCodes = "";
			vCompanyTIN = TrimAll(vCompanyObj.TIN);
			vCompanyKPP = TrimAll(vCompanyObj.KPP);
			vCompanyVATCode = TrimAll(vCompanyObj.VATC);
			If Not IsBlankString(vCompanyTIN) Then
				vCompanyCodes = cmNStr("en=', TIC ';de=', SIC ';ru=', ИНН '", vLang) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP) + 
				                ?(IsBlankString(vCompanyVATCode), "", cmNStr("en=', VAT code ';de=', Mw.St. code ';ru=', код НДС '", vLang) + vCompanyVATCode);
			EndIf;
			mCompany = TrimAll(vCompanyLegacyName + vCompanyCodes + Chars.LF + vCompanyLegacyAddress + ?(IsBlankString(vCompanyPostAddress), "", Chars.LF + vCompanyPostAddress));
			vHeaderArea.Parameters.mCompany = mCompany;
					
			// Customer
			vCustomer = vDoc.AccountingCustomer;
			vCustomerLegacyName = "";
			vCustomerLegacyAddress = "";
			vCustomerPostAddress = "";
			vCustomerTIN = "";
			vCustomerPhones = "";
			If ValueIsFilled(vCustomer) Then
				vCustomerLegacyName = TrimAll(vCustomer.LegacyName);
				If IsBlankString(vCustomerLegacyName) Then
					vCustomerLegacyName = TrimAll(vCustomer.Description);
				EndIf;
				vCustomerLegacyAddress = cmGetAddressPresentation(vCustomer.LegacyAddress);
				vCustomerPostAddress = cmGetAddressPresentation(vCustomer.PostAddress);
				If vCustomerPostAddress = vCustomerLegacyAddress Then
					vCustomerPostAddress = "";
				EndIf;
				vCustomerCodes = "";
				vCustomerTIN = TrimAll(vCustomer.TIN);
				vCustomerKPP = TrimAll(vCustomer.KPP);
				vCustomerVATCode = TrimAll(vCustomer.VATC);
				If Not IsBlankString(vCustomerTIN) Then
					vCustomerCodes = cmNStr("en=', TIC ';de=', SIC ';ru=', ИНН '", vLang) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP) + 
					                 cmNStr("en=', VAT code ';de=', Mw.St. Code ';ru=', код НДС '", vLang) + vCustomerVATCode;
				EndIf;
				// Fax and E-Mail
				vCustomerPhones = TrimAll(vCustomer.Phone);
				vCustomerFax = TrimAll(vCustomer.Fax);
				vCustomerEMail = TrimAll(vCustomer.EMail);
				vCustomerPhones = vCustomerPhones + 
				                  ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", vLang) + vCustomerFax) + 
				                  ?(IsBlankString(vCustomerEMail), "", cmNStr("en=', e-mail ';de=', e-mail ';ru=', e-mail '", vLang) + vCustomerEMail);
			EndIf;
			mCustomer = TrimAll(vCustomerLegacyName + vCustomerCodes + Chars.LF + vCustomerLegacyAddress + ?(IsBlankString(vCustomerPostAddress), "", Chars.LF + vCustomerPostAddress) + Chars.LF + vCustomerPhones);
			vHeaderArea.Parameters.mCustomer = mCustomer;
			
			// Put header
			vSpreadsheet.Put(vHeaderArea);
			
			For Each vRow In vDoc.Invoices Do
				vInvoice = vRow.Invoice;
				
				vRowArea = vSpreadsheetTemplate.GetArea("Row");
				
				vRowArea.Parameters.mLineNumber = Format(vRow.LineNumber, "NFD=; NG=");
				
				If ValueIsFilled(vInvoice) Then
					vGuestGroup = vInvoice.GuestGroup;
					
					vRowArea.Parameters.mCheckOutDate = ?(ValueIsFilled(vGuestGroup.CheckOutDate), Format(vGuestGroup.CheckOutDate, "DF=dd.MM.yyyy"), "");
					vRowArea.Parameters.mClientName = ?(ValueIsFilled(vGuestGroup.Client), TrimAll(vGuestGroup.Client.FullName), "");
					vRowArea.Parameters.mReferenceNumber = ?(IsBlankString(vGuestGroup.ID), ?(IsBlankString(vGuestGroup.Description), Format(vGuestGroup.Code, "NFD=0; NG="), TrimAll(vGuestGroup.Description)), TrimAll(vGuestGroup.ID));
				Else
					vRowArea.Parameters.mCheckOutDate = "";
					vRowArea.Parameters.mClientName = "";
					vRowArea.Parameters.mReferenceNumber = "";
				EndIf;
				
				If Not USE_SHORT_FORM Then
					vRowArea.Parameters.mInvoiceSum = cmFormatSum(vRow.InvoiceSum, vDoc.AccountingCurrency);
					vRowArea.Parameters.mSum = cmFormatSum(vRow.Sum, vDoc.AccountingCurrency);
				EndIf;
				vRowArea.Parameters.mCorrectionSum = cmFormatSum(vRow.CorrectionSum, vDoc.AccountingCurrency);
				
				vSpreadsheet.Put(vRowArea);
			EndDo;
					
			vFooterArea = vSpreadsheetTemplate.GetArea("Footer");
			
			vCorrectionSum = vDoc.Invoices.Total("CorrectionSum");
			vVATAmount = cmCalculateVATSum(vDoc.VATRate, vCorrectionSum, vDoc.Date);
			
			If Not USE_SHORT_FORM Then
				vFooterArea.Parameters.mTotalInvoiceSum = cmFormatSum(vDoc.Invoices.Total("InvoiceSum"), vDoc.AccountingCurrency);
				vFooterArea.Parameters.mTotalSum = cmFormatSum(vDoc.Invoices.Total("Sum"), vDoc.AccountingCurrency);
			EndIf;
			vFooterArea.Parameters.mTotalCorrectionSum = cmFormatSum(vCorrectionSum, vDoc.AccountingCurrency);
			
			vFooterArea.Parameters.mVATRate = ?(ValueIsFilled(vDoc.VATRate), TrimAll(vDoc.VATRate) + NStr("en=' ('; ru=' ('; de=' ('") + cmGetVATTaxRate(vDoc.VATRate, vDoc.Date) + "%)", NStr("en='No VAT'; ru='Без НДС'; de='Ohne Mehrwertsteuer'"));
			vFooterArea.Parameters.mTotalCorrectionSumWithoutVAT = cmFormatSum(vCorrectionSum - vVATAmount, vDoc.AccountingCurrency);
			vFooterArea.Parameters.mTotalCorrectionVATSum = cmFormatSum(vVATAmount, vDoc.AccountingCurrency);
			
			vFooterArea.Parameters.mRemarks = TrimAll(vDoc.RemarksForPrinting); 
				
			vSpreadsheet.Put(vFooterArea);
		
			i = i + 1;
		EndIf;
	EndDo;

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	
	// Report header
	cmApplyReportHeader(vSpreadsheet);
	cmApplyReportFooter(vSpreadsheet);
	
	Return vSpreadsheet;
EndFunction // pmPrintDocument

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure WriteGuestLedgerFOPostings(pPostingAmount, pFolio, pFolioFinancialAccount, pFolioParentDoc)
	// Do nothing if paid amount is zero
	If pPostingAmount = 0 Then
		Return;
	EndIf;
	
	// Get service account
	vAccountStruct = cmGetAccountCodeForPOSAndPaymentMethod(Hotel, Company, Catalogs.CashRegisters.EmptyRef(), ?(ValueIsFilled(PaymentMethod), PaymentMethod, Catalogs.PaymentMethods.Settlement), PaymentSection);
	vPostingAccount = vAccountStruct.Account;
	If Not ValueIsFilled(vPostingAccount) Then
		Return;
	EndIf;
	vCorrespondingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
	If ValueIsFilled(pFolio) And ValueIsFilled(pFolioFinancialAccount) Then
		vCorrespondingAccount = pFolioFinancialAccount;
	EndIf;
	
	// Postings currency
	vAccountCurrency = AccountingCurrency;
	
	vPostingAmount = pPostingAmount;
	
	vReverseSign = False;
	If vPostingAmount < 0 Then
		vReverseSign = True;
		
		vPostingAmount = -vPostingAmount;
	EndIf;
	
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
	
	PostingMovement.Amount = vPostingAmount;
	PostingMovement.GrosAmount = 0;
	
	PostingMovement.Description = TrimAll(PaymentMethod);
	
	PostingMovement.Period = BegOfDay(Date);
	PostingMovement.FODate = BegOfDay(Date);
	PostingMovement.ServiceDate = '00010101';
	PostingMovement.Days = 0;
				
	PostingMovement.ParentDoc = pFolioParentDoc;
	
	PostingMovement.Room = Undefined;
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
	PostingMovement.Invoice = Ref;
	
	PostingMovement.Recorder = Ref;
	PostingMovement.Author = ?(ValueIsFilled(ChangeAuthor), ChangeAuthor, Author);
	
	// Create guest ledger debit movement
	If vReverseSign Then
		PostingMovement = RegisterRecords.PostingsFO.AddCredit();
	Else
		PostingMovement = RegisterRecords.PostingsFO.AddDebit();
	EndIf;
				
	PostingMovement.Active = True;
	
	PostingMovement.Account = vCorrespondingAccount;
	If vCorrespondingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger Then
		PostingMovement.ExtDimensions.Folio = pFolio;
	EndIf;
	PostingMovement.CorrAccount = vPostingAccount;
	
	PostingMovement.Amount = vPostingAmount;
	PostingMovement.GrosAmount = 0;
	
	PostingMovement.Description = TrimAll(PaymentMethod);
	
	PostingMovement.Period = BegOfDay(Date);
	PostingMovement.FODate = BegOfDay(Date);
	PostingMovement.ServiceDate = '00010101';
	PostingMovement.Days = 0;
				
	PostingMovement.ParentDoc = pFolioParentDoc;
	
	PostingMovement.Room = Undefined;
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
	PostingMovement.Invoice = Ref;
	
	PostingMovement.Recorder = Ref;
	PostingMovement.Author = ?(ValueIsFilled(ChangeAuthor), ChangeAuthor, Author);
EndProcedure // WriteGuestLedgerFOPostings

// -----------------------------------------------------------------------------
Procedure WriteCityLedgerFOPostings(pInvoicesRow, pPostingAmount)
	// Do nothing if paid amount is zero
	If pPostingAmount = 0 Then
		Return;
	EndIf;
	
	// Get service account
	vAccountStruct = cmGetAccountCodeForPOSAndPaymentMethod(Hotel, Company, Catalogs.CashRegisters.EmptyRef(), ?(ValueIsFilled(PaymentMethod), PaymentMethod, Catalogs.PaymentMethods.Settlement), PaymentSection);
	vPostingAccount = vAccountStruct.Account;
	If Not ValueIsFilled(vPostingAccount) Then
		Return;
	EndIf;
	vCorrespondingAccountStruct = cmGetAccountCodeForCustomer(Hotel, Company, AccountingCustomer, AccountingContract);
	vCorrespondingAccount = vCorrespondingAccountStruct.Account;
	If Not ValueIsFilled(vCorrespondingAccount) Then
		Return;
	EndIf;
	
	// Postings currency
	vAccountCurrency = AccountingCurrency;
	
	vPostingAmount = pPostingAmount;
	
	vReverseSign = False;
	If vPostingAmount < 0 Then
		vReverseSign = True;
		
		vPostingAmount = -vPostingAmount;
	EndIf;
	
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
	
	PostingMovement.Amount = vPostingAmount;
	PostingMovement.GrosAmount = 0;
	
	PostingMovement.Description = TrimAll(Ref);
	
	PostingMovement.Period = BegOfDay(Date);
	PostingMovement.FODate = BegOfDay(Date);
	PostingMovement.ServiceDate = '00010101';
	PostingMovement.Days = 0;
				
	PostingMovement.ParentDoc = Undefined;
	
	PostingMovement.Room = Undefined;
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
	PostingMovement.Invoice = pInvoicesRow.Invoice;
	
	PostingMovement.Recorder = Ref;
	PostingMovement.Author = ?(ValueIsFilled(ChangeAuthor), ChangeAuthor, Author);
	
	// Create guest ledger debit movement
	If vReverseSign Then
		PostingMovement = RegisterRecords.PostingsFO.AddCredit();
	Else
		PostingMovement = RegisterRecords.PostingsFO.AddDebit();
	EndIf;
				
	PostingMovement.Active = True;
	
	PostingMovement.Account = vCorrespondingAccount;
	PostingMovement.CorrAccount = vPostingAccount;
	
	PostingMovement.Amount = vPostingAmount;
	PostingMovement.GrosAmount = 0;
	
	PostingMovement.Description = TrimAll(Ref);
	
	PostingMovement.Period = BegOfDay(Date);
	PostingMovement.FODate = BegOfDay(Date);
	PostingMovement.ServiceDate = '00010101';
	PostingMovement.Days = 0;
				
	PostingMovement.ParentDoc = Undefined;
	
	PostingMovement.Room = Undefined;
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
	PostingMovement.Invoice = pInvoicesRow.Invoice;
	
	PostingMovement.Recorder = Ref;
	PostingMovement.Author = ?(ValueIsFilled(ChangeAuthor), ChangeAuthor, Author);
EndProcedure // WriteCityLedgerFOPostings

// -----------------------------------------------------------------------------
Procedure PostToCurrentAccountsReceivable(pServices)
	RegisterRecords.CurrentAccountsReceivable.Clear();

	// Write movement for each charge in the services tabular part
	For Each vServicesRow In pServices Do
		Movement = RegisterRecords.CurrentAccountsReceivable.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = Date;
		
		FillPropertyValues(Movement, vServicesRow);
		
		// Fill individuals customer and customer contract if specified
		If Not ValueIsFilled(Movement.Customer) And ValueIsFilled(Hotel.IndividualsCustomer) And ValueIsFilled(Hotel.IndividualsContract) Then
			Movement.Customer = Hotel.IndividualsCustomer;
			Movement.Contract = Hotel.IndividualsContract;
		EndIf;
		
		Movement.Hotel = Hotel;
		Movement.Company = Company;
	EndDo;

	RegisterRecords.CurrentAccountsReceivable.Write();
	RegisterRecords.CurrentAccountsReceivable.Write = False;
EndProcedure // PostToCurrentAccountsReceivable

// -----------------------------------------------------------------------------
Procedure PostToAccountsReceivable(pServices)
	RegisterRecords.AccountsReceivable.Clear();
	
	// Write movement for each charge in the services tabular part
	For Each vServicesRow In pServices Do
		Movement = RegisterRecords.AccountsReceivable.Add();
		
		Movement.Period = Date;
		
		FillPropertyValues(Movement, ThisObject);
		FillPropertyValues(Movement, vServicesRow);
		Movement.GuestGroup = vServicesRow.ChargeFolioGuestGroup;
		
		Movement.Settlement = Ref;
	EndDo;

	RegisterRecords.AccountsReceivable.Write();
	RegisterRecords.AccountsReceivable.Write = False;
EndProcedure // PostToAccountsReceivable

// -----------------------------------------------------------------------------
Procedure PostToCustomerAccounts() 
	RegisterRecords.CustomerAccounts.Clear();
	
	For Each vRow In Invoices Do
		If Not ValueIsFilled(vRow.Invoice) Then
			Continue;
		ElsIf vRow.CorrectionSum = 0 Then
			Continue;
		EndIf;
		
		// Add correction movement
		Movement = RegisterRecords.CustomerAccounts.Add();
		Movement.RecordType = AccumulationRecordType.Receipt;
		Movement.Period = Date;
		
		// Dimensions
		FillPropertyValues(Movement, ThisObject);
		FillPropertyValues(Movement, vRow.Invoice, , "VATRate");
		
		// Resources
		Movement.Sum = vRow.CorrectionSum;
		Movement.VATSum = vRow.CorrectionVATSum;
		
		// Attributes
		Movement.AccountingDate = BegOfDay(Date);
	EndDo;

	RegisterRecords.CustomerAccounts.Write();
	RegisterRecords.CustomerAccounts.Write = False;
EndProcedure // PostToCustomerAccounts

// -----------------------------------------------------------------------------
Procedure PostToInvoiceAccounts()
	RegisterRecords.InvoiceAccounts.Clear();
	
	For Each vRow In Invoices Do
		If Not ValueIsFilled(vRow.Invoice) Then
			Continue;
		ElsIf vRow.CorrectionSum = 0 Then
			Continue;
		EndIf;
		
		Movement = RegisterRecords.InvoiceAccounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Receipt;
		Movement.Period = Date;
		
		FillPropertyValues(Movement, ThisObject);
		FillPropertyValues(Movement, vRow.Invoice, , "VATRate");
		Movement.Invoice = Ref;
		
		Movement.Sum = vRow.CorrectionSum;
		Movement.VATSum = vRow.CorrectionVATSum;
		
		// Attributes
		Movement.AccountingDate = BegOfDay(Date);
	EndDo;

	RegisterRecords.InvoiceAccounts.Write();
	RegisterRecords.InvoiceAccounts.Write = False;
EndProcedure // PostToInvoiceAccounts

#EndRegion

