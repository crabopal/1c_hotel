
#Region Public

// -----------------------------------------------------------------------------
// Creates or finds credit card by data being read from the card
//
// Parameters:
//  pText			 - String - Credit card data
//  pCardOwner		 - CatalogRef.Clients - Credit card owner
//  pCreateNew		 - Boolean - Do create new card if card was not found
//  pPaymentMethod	 - CatalogRef.PaymentMethods - Used to fill card type if it is not directly specified
// 
// Returns:
//  CatalogRef.CreditCards
//
Function cmGetCreditCardByText(pText, pCardOwner, pCreateNew = False, pPaymentMethod = Undefined) Export
	// Check card owner
	If Not ValueIsFilled(pCardOwner) Then
		Return Catalogs.CreditCards.EmptyRef();
	EndIf;
	Try
		// Parse credit card data to fields
		vCardData = cmParseCreditCardData(pText);
		If pPaymentMethod <> Undefined Then
			If ValueIsFilled(pPaymentMethod.CardType) Then
				vCardData.CardType = pPaymentMethod.CardType;
			EndIf;
			If ValueIsFilled(pPaymentMethod.CardOwner) Then
				vCardData.CardOwner = pPaymentMethod.CardOwner;
			EndIf;
		EndIf;
		// Get card number
		vCardNumber = vCardData.CardNumber;
		// Search cards with given owner and number
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CreditCards.Ref AS CreditCard
		|FROM
		|	Catalog.CreditCards AS CreditCards
		|WHERE
		|	CreditCards.CardOwner = &qCardOwner
		|	AND CreditCards.CardNumber = &qCardNumber
		|	AND CreditCards.DeletionMark = FALSE";
		vQry.SetParameter("qCardOwner", pCardOwner);
		vQry.SetParameter("qCardNumber", vCardNumber);
		vCards = vQry.Execute().Unload();
		If vCards.Count() > 0 Then
			// Return first found
			Return vCards.Get(0).CreditCard;
		Else
			// Create new card if necessary
			If pCreateNew Then
				If Not ValueIsFilled(vCardData.CardHolder) Or Not ValueIsFilled(vCardData.CardType) Then
					vCardObj = Catalogs.CreditCards.CreateItem();
					vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
					FillPropertyValues(vCardObj, vCardData);
					If Not ValueIsFilled(vCardObj.CardOwner) Then
						vCardObj.CardOwner = pCardOwner;
					EndIf;
					vCardObj.Author = SessionParameters.CurrentUser;
					vCardObj.CreateDate = CurrentSessionDate();
					// Open card item form
					vFrm = vCardObj.GetForm();
					vFrm.DoModal();
					// Check that card was saved
					vCardIsSaved = False;
					Try
						vCardObj.Read();
						If Not vCardObj.IsNew() Then
							vCardIsSaved = True;
						EndIf;
					Except
					EndTry;
					If Not vCardIsSaved Then
						Return Catalogs.CreditCards.EmptyRef();
					Else
						Return vCardObj.Ref;
					EndIf;
				Else
					vCardObj = Catalogs.CreditCards.CreateItem();
					vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
					FillPropertyValues(vCardObj, vCardData);
					If Not ValueIsFilled(vCardObj.CardOwner) Then
						vCardObj.CardOwner = pCardOwner;
					EndIf;
					vCardObj.Author = SessionParameters.CurrentUser;
					vCardObj.CreateDate = CurrentSessionDate();
					vCardObj.Write();
					Return vCardObj.Ref;
				EndIf;
			Else
				Return Catalogs.CreditCards.EmptyRef();
			EndIf;
		EndIf;
	Except
		vErrInfo = ErrorInfo();
		WriteLogEvent(NStr("en='CreditCards.GetCreditCardByText';ru='КредитныеКарты.GetCreditCardByText';de='Kreditkarten.GetCreditCardByText'"), EventLogLevel.Warning, Metadata.Catalogs.CreditCards, , cmGetRootErrorDescription(vErrInfo));
		ShowErrorInfo(vErrInfo);
		Return Catalogs.CreditCards.EmptyRef();
	EndTry;
EndFunction // cmGetCreditCardByText

// -----------------------------------------------------------------------------
//  Function calls customer accounts detailed or short balances report
//
// Parameters:
//  pCustomer			 - 	 - 
//  pContract			 - 	 - 
//  pGuestGroup			 - 	 - 
//  pCurrency			 - 	 - 
//  pCompany			 - 	 - 
//  pHotel				 - 	 - 
//  pPeriodFrom			 - 	 - 
//  pPeriodTo			 - 	 - 
//  pForm				 - 	 - 
//  pIsInAutomaticMode	 - 	 - 
//
Procedure cmPrintCustomerAccountingBalances(pCustomer, pContract, pGuestGroup = Undefined, 
                                            pCurrency = Undefined, pCompany = Undefined, pHotel = Undefined, 
                                            pPeriodFrom = Undefined, pPeriodTo = Undefined, 
                                            pForm = Undefined, pIsInAutomaticMode = False) Export
	vRepItem = pForm.Report;
	If Not ValueIsFilled(vRepItem) Then
		If pForm = Catalogs.ObjectPrintingForms.CustomerPrintBalances Then
			vRepItem = Catalogs.Reports.CustomerAccounts;
		Else
			vRepItem = Catalogs.Reports.CustomerAccountsDetails;
		EndIf;
	EndIf;
	If Not cmCheckUserRightsToOpenReport(vRepItem) Then  
		vErr = StrTemplate(NStr("en='You do not have rights to run report: %1!';ru='Нет прав на формирование отчета: %1!';de='Sie haben keine Rechte, einen Bericht zu erstellen: %1!'"), cmNStr(vRepItem.Description));
		Raise  vErr;
	EndIf;
	vRepObj = cmBuildReportObject(vRepItem);
	If vRepObj <> Undefined Then
		// Load report catalog item attributes
		vRepObj.Report = pForm.Report;
		If Not ValueIsFilled(vRepObj.Report) Then
			vRepObj.Report = vRepItem;
		EndIf;
		// Open report's default form
		vRepFrm = vRepObj.GetForm();
		vRepFrm.GenerateOnFormOpen = False;
		vRepFrm.Open();
		// Set report attributes from parameters
		vRepObj.Company = pCompany;
		vRepObj.Customer = pCustomer;
		vRepObj.Contract = pContract;
		vRepObj.GuestGroup = pGuestGroup;
		vRepObj.Currency = pCurrency;
		vRepObj.Hotel = pHotel;
		vRepObj.PeriodFrom = pPeriodFrom;
		vRepObj.PeriodTo = pPeriodTo;
		If ValueIsFilled(vRepObj.Hotel) Then
			vRepObj.ShowCurrentAccountsReceivable = vRepObj.Hotel.ShowCurrentAccountsReceivable;
		EndIf;
		// Generate report
		vRepFrm.fmGenerateReport();
	EndIf;
EndProcedure // cmPrintCustomerAccountingBalances

// -----------------------------------------------------------------------------
//  Function calls proforma invoice balances report
//
// Parameters:
//  pCustomer				 - 	 - 
//  pContract				 - 	 - 
//  pGuestGroup				 - 	 - 
//  pCurrency				 - 	 - 
//  pCompany				 - 	 - 
//  pHotel					 - 	 - 
//  pPeriodFrom				 - 	 - 
//  pPeriodTo				 - 	 - 
//  pShowExpiredInvoicesOnly - 	 - 
//  pForm					 - 	 - 
//  pIsInAutomaticMode		 - 	 - 
//
Procedure cmPrintProformaInvoicesBalances(pCustomer, pContract, pGuestGroup = Undefined, 
                                          pCurrency = Undefined, pCompany = Undefined, pHotel = Undefined, 
                                          pPeriodFrom = Undefined, pPeriodTo = Undefined, pShowExpiredInvoicesOnly = False, 
                                          pForm = Undefined, pIsInAutomaticMode = False) Export
	vRepItem = Catalogs.Reports.InvoiceAccounts;
	If ValueIsFilled(pForm) And ValueIsFilled(pForm.Report) Then
		vRepItem = pForm.Report;
	EndIf;
	If Not cmCheckUserRightsToOpenReport(vRepItem) Then  
		vErr = StrTemplate(NStr("en='You do not have rights to run report: %1!';ru='Нет прав на формирование отчета: %1!';de='Sie haben keine Rechte, einen Bericht zu erstellen: %1!'"), cmNStr(vRepItem.Description));
		Raise  vErr;
	EndIf;
	vRepObj = cmBuildReportObject(vRepItem);
	If vRepObj <> Undefined Then
		// Load report catalog item attributes
		vRepObj.Report = vRepItem;
		// Open report's default form
		vRepFrm = vRepObj.GetForm();
		vRepFrm.GenerateOnFormOpen = False;
		vRepFrm.Open();
		// Set report attributes from parameters
		vRepObj.Company = pCompany;
		vRepObj.Customer = pCustomer;
		vRepObj.Contract = pContract;
		vRepObj.GuestGroup = pGuestGroup;
		vRepObj.Currency = pCurrency;
		vRepObj.Hotel = pHotel;
		vRepObj.PeriodFrom = pPeriodFrom;
		vRepObj.PeriodTo = pPeriodTo;
		vRepObj.ShowExpiredInvoicesOnly = pShowExpiredInvoicesOnly;
		vRepObj.TypeOfInvoicesToShow = 0;
		// Generate report
		vRepFrm.fmGenerateReport();
	EndIf;
EndProcedure // cmPrintProformaInvoicesBalances

// -----------------------------------------------------------------------------
//  Function calls invoice balances report
//
// Parameters:
//  pCustomer				 - 	 - 
//  pContract				 - 	 - 
//  pGuestGroup				 - 	 - 
//  pCurrency				 - 	 - 
//  pCompany				 - 	 - 
//  pHotel					 - 	 - 
//  pPeriodFrom				 - 	 - 
//  pPeriodTo				 - 	 - 
//  pShowExpiredInvoicesOnly - 	 - 
//  pForm					 - 	 - 
//  pIsInAutomaticMode		 - 	 - 
//
Procedure cmPrintInvoicesBalances(pCustomer, pContract, pGuestGroup = Undefined, 
                                          pCurrency = Undefined, pCompany = Undefined, pHotel = Undefined, 
                                          pPeriodFrom = Undefined, pPeriodTo = Undefined, pShowExpiredInvoicesOnly = False, 
                                          pForm = Undefined, pIsInAutomaticMode = False) Export
	vRepItem = Catalogs.Reports.InvoiceAccounts;
	If ValueIsFilled(pForm) And ValueIsFilled(pForm.Report) Then
		vRepItem = pForm.Report;
	EndIf;
	If Not cmCheckUserRightsToOpenReport(vRepItem) Then
		vErr = StrTemplate(NStr("en='You do not have rights to run report: %1!';ru='Нет прав на формирование отчета: %1!';de='Sie haben keine Rechte, einen Bericht zu erstellen: %1!'"), cmNStr(vRepItem.Description));
		Raise  vErr;
	EndIf;
	vRepObj = cmBuildReportObject(vRepItem);
	If vRepObj <> Undefined Then
		// Load report catalog item attributes
		vRepObj.Report = vRepItem;
		// Open report's default form
		vRepFrm = vRepObj.GetForm();
		vRepFrm.GenerateOnFormOpen = False;
		vRepFrm.Open();
		// Set report attributes from parameters
		vRepObj.Company = pCompany;
		vRepObj.Customer = pCustomer;
		vRepObj.Contract = pContract;
		vRepObj.GuestGroup = pGuestGroup;
		vRepObj.Currency = pCurrency;
		vRepObj.Hotel = pHotel;
		vRepObj.PeriodFrom = pPeriodFrom;
		vRepObj.PeriodTo = pPeriodTo;
		vRepObj.ShowExpiredInvoicesOnly = pShowExpiredInvoicesOnly;
		vRepObj.TypeOfInvoicesToShow = 1;
		// Generate report
		vRepFrm.fmGenerateReport();
	EndIf;
EndProcedure // cmPrintInvoicesBalances

// -----------------------------------------------------------------------------
//  Function checks whether currency rates are actual or should be updated
//
Procedure cmCheckCurrencyRatesActuality() Export
	If cmCheckUserPermissions("HavePermissionToCheckCurrencyRatesActuality") Then
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			vCurDayOfWeek = WeekDay(CurrentSessionDate());
			If vCurDayOfWeek <> 7 And vCurDayOfWeek <> 1 Then
				vRates = InformationRegisters.CurrencyRates.SliceLast(, New Structure("Hotel", SessionParameters.CurrentHotel));
				If vRates.Count() > 0 Then
					vTodayIsFound = False;
					vDate = Date('00010101');
					For Each vRatesRow In vRates Do
						vDate = Max(vDate, BegOfDay(vRatesRow.Period));
						If BegOfDay(vRatesRow.Period) >= BegOfDay(CurrentSessionDate()) Then
							vTodayIsFound = True;
							Break;
						EndIf;
					EndDo;
					If Not vTodayIsFound Then 
						vMsg = Nstr("en = 'There is no currency rates for today! Currency rates are actual for %1 - %2.'; 
									|de = 'Für heute gibt es keine Wechselkurse! Die Wechselkurse sind für %1 - %2 aktuell.'; 
									|ru = 'На сегодня не установлены курсы валют! Курсы актуальны на %1 - %2.'"); 
						tcCommonFunctionOnClientServer.UserMessage(StrTemplate(vMsg, Format(vDate, "DF='dd MMMM yyyy'"), cmGetDayOfWeekName(WeekDay(vDate), False)));
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmCheckCurrencyRatesActuality

// -----------------------------------------------------------------------------
//  Function checks balances for the given accommodations value list
//
// Parameters:
//  pAccList - ValueList - Value list of accommodations
// 
// Returns:
//  Boolean - True if balances are zero or False if not
//
Function cmCheckAccommodationsBalances(pAccList) Export
	vFolios = cmGetDocumentFoliosWithDebts(pAccList);
	If vFolios.Count() > 0 Then
		vDoQuery = False;
		vThereAreDebts = False;
		vThereAreDeposits = False;
		vDebtsMessage = NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF;
		For Each vFoliosRow In vFolios Do
			If Not ValueIsFilled(vFoliosRow.Folio.ParentDoc) Then
				Continue;
			EndIf;
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
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en = 'There are DEBTS!'; de = 'ES LIEGT EINE SCHULD VOR!'; ru = 'ЕСТЬ ЗАДОЛЖЕННОСТЬ!'");
			ElsIf Not vThereAreDebts And vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en = 'There are DEPOSITS!'; de = 'ES LIEGT EINE ÜBERZAHLUNG VOR!'; ru = 'ЕСТЬ ПЕРЕПЛАТА!'");
			Else
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en = 'There are DEBTS AND DEPOSITS!'; de = 'ES LIEGT EINE SCHULD oder ÜBERZAHLUNG vor!'; ru = 'ЕСТЬ ЗАДОЛЖЕННОСТЬ И ПЕРЕПЛАТА!'");
			EndIf;
			vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("de='Check-out Die Gäste?';en='Do check-out?';ru='Выселить гостей?'");
			If DoQueryBox(vDebtsMessage, QuestionDialogMode.YesNo, , DialogReturnCode.No) = DialogReturnCode.No Then
				WriteLogEvent(NStr("en='Accommodation.CheckBalances';ru='Размещение.ПроверкаБаланса';de='Accommodation.CheckBalances'"), EventLogLevel.Information, Metadata.Documents.Folio, , vDebtsMessage + NStr("en=' - No';ru=' - Нет';de=' - Nein'"));
				Return False;
			Else
				WriteLogEvent(NStr("en='Accommodation.CheckBalances';ru='Размещение.ПроверкаБаланса';de='Accommodation.CheckBalances'"), EventLogLevel.Information, Metadata.Documents.Folio, , vDebtsMessage + NStr("en=' - Yes';ru=' - Да';de=' - Ja'"));
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction // cmCheckAccommodationsBalances

// -----------------------------------------------------------------------------
//  Function checks balances (deposits that are negative balances) for the given reservations value list
//
// Parameters:
//  pResRef	 - ValueList - Value list of reservations
// 
// Returns:
//  Boolean - Always true so far
//
Function cmCheckReservationsDeposits(pResRef) Export
	vFolios = cmGetDocumentFoliosWithDebts(pResRef, True); // Deposits only
	If vFolios.Count() > 0 Then
		vDebtsMessage = NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF;
		For Each vFoliosRow In vFolios Do
			If ValueIsFilled(vFoliosRow.Folio) Then
				vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFoliosRow.Folio.Number) + " " + 
				                TrimAll(vFoliosRow.Folio.Client) + NStr("ru = ', номер '; en = ', room '; de = ', zimmer '") + 
				                TrimAll(vFoliosRow.Folio.Room) + NStr("ru = ', период '; en = ', period '; de = ', period '") + 
				                Format(vFoliosRow.Folio.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
				                Format(vFoliosRow.Folio.DateTimeTo, "DF='dd.MM.yy HH:mm'") + " = " + 
				                cmFormatSum(vFoliosRow.SumBalance, vFoliosRow.Folio.FolioCurrency, "NZ=");
			Else
				vDebtsMessage = vDebtsMessage + Chars.LF + NStr("en='<Empty folio>';ru='<Пустое фолио>';de='<Leeres Blatt>'") + " = " + cmFormatSum(vFoliosRow.SumBalance, "NZ=", , True);
			EndIf;
		EndDo;
		vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en = 'There are DEPOSITS!'; de = 'ES LIEGT EINE ANZAHLUNG VOR!'; ru = 'ЕСТЬ ПРЕДОПЛАТА!'");
		DoMessageBox(vDebtsMessage);
		WriteLogEvent(NStr("en='Reservation.CheckDeposits';ru='Резервирование.ПроверкаДепозита';de='Reservation.CheckDeposits'"), EventLogLevel.Information, Metadata.Documents.Folio, , vDebtsMessage);
	EndIf;
	Return True;
EndFunction // cmCheckReservationsDeposits

// -----------------------------------------------------------------------------
//  Function returns accommodation service item reference searching
//  value table with services by IsRoomRevenue column value equal true
//
// Parameters:
//  pServices	 - ValueTable	 - Value table with services
// 
// Returns:
//  CatalogRef.Services - Services catalog item reference
//
Function cmGetAccommodationService(pServices) Export
	vAccommodationService = Undefined;
	For Each pServicesRow In pServices Do
		If pServicesRow.IsRoomRevenue And pServicesRow.IsInPrice Then
			vAccommodationService = pServicesRow.Service;
			Break;
		EndIf;
	EndDo;
	Return vAccommodationService;
EndFunction // cmGetAccommodationService

// -----------------------------------------------------------------------------
//  Checks guest group changes and asks user whether to create invoice for changes only
//
// Parameters:
//  pGuestGroup		 - 	 - 
//  pInvObj			 - 	 - 
//  pForm			 - 	 - 
//  pButton			 - 	 - 
//  pExtraInvoice	 - 	 - 
// 
// Returns:
//  Boolean - False if user skipped selection, true if choice was done
//
Function cmCheckOtherInvoices(pGuestGroup, pInvObj, pForm, pButton, pExtraInvoice = False) Export
	// Check if there are other guest group invoices
	vGuestGroupObj = pGuestGroup.GetObject();
	vExistingInvoices = vGuestGroupObj.pmGetInvoices();
	If vExistingInvoices.Count() > 0 Then
		vNewInvServices = pInvObj.Services.Unload();
		For Each vExistingInvoicesRow In vExistingInvoices Do
			If vExistingInvoicesRow.InvoiceDate <= pInvObj.Date And vExistingInvoicesRow.Invoice <> pInvObj.Ref Then
				For Each vExistingInvoicesServicesRow In vExistingInvoicesRow.Invoice.Services Do
					vNewInvServicesRow = vNewInvServices.Add();
					FillPropertyValues(vNewInvServicesRow, vExistingInvoicesServicesRow, , "LineNumber");
					vNewInvServicesRow.Quantity = -vNewInvServicesRow.Quantity;
					vNewInvServicesRow.Sum = -vNewInvServicesRow.Sum;
					vNewInvServicesRow.VATSum = -vNewInvServicesRow.VATSum;
					vNewInvServicesRow.DiscountSum = -vNewInvServicesRow.DiscountSum;
					vNewInvServicesRow.CommissionSum = -vNewInvServicesRow.CommissionSum;
					vNewInvServicesRow.VATCommissionSum = -vNewInvServicesRow.VATCommissionSum;
					vNewInvServicesRow.NumberOfPersons = -vNewInvServicesRow.NumberOfPersons;
					vNewInvServicesRow.RoomQuantity = -vNewInvServicesRow.RoomQuantity;
				EndDo;
			EndIf;
		EndDo;
		vNewInvServices.GroupBy("AccountingDate, Service, Price, Unit, VATRate, Remarks, Client, AccommodationType, RoomType, Room, Resource, IsInPrice, IsRoomRevenue, IsResourceRevenue, DateTimeFrom, DateTimeTo, CalendarDayType, Discount, HotelProduct, Agent, AgentCommissionType, AgentCommission, GuestGroup", "Quantity, Sum, VATSum, NumberOfPersons, RoomQuantity, DiscountSum, CommissionSum, VATCommissionSum");
		vMinusIsFound = False;
		i = 0;
		While i < vNewInvServices.Count() Do
			vNewInvServicesRow = vNewInvServices.Get(i);
			If vNewInvServicesRow.Quantity < 0 Then
				vMinusIsFound = True;
			ElsIf vNewInvServicesRow.Quantity = 0 And vNewInvServicesRow.Sum = 0 Then
				vNewInvServices.Delete(i);
				Continue;
			EndIf;
			i = i + 1;
		EndDo;
		vNewFullAmount = pInvObj.Services.Total("Sum");
		vNewExtraAmount = vNewInvServices.Total("Sum");
		If pExtraInvoice Then
			If vMinusIsFound Then
				FillExtraInvoiceServices(pInvObj, vNewInvServices);
			Else
				pInvObj.Services.Load(vNewInvServices);
			EndIf;
		ElsIf vNewExtraAmount <> 0 And vNewFullAmount <> 0 And vNewFullAmount <> vNewExtraAmount Then
			vUCMenu = New ValueList();
			vUCMenu.Add(1, NStr("en='Invoice for total amount ';ru='Счет на полную сумму ';de='Rechnung für die volle Summe '") + cmFormatSum(vNewFullAmount, pInvObj.AccountingCurrency));
			vUCMenu.Add(2, NStr("en='Invoice for extra amount ';ru='Счет на доплату ';de='Nachzahlungsrechnung '") + cmFormatSum(vNewExtraAmount, pInvObj.AccountingCurrency));
			vUC = pForm.ChooseFromMenu(vUCMenu, pButton);
			If vUC = Undefined Then
				Return False;
			ElsIf vUC.Value = 2 Then
				If vMinusIsFound Then
					FillExtraInvoiceServices(pInvObj, vNewInvServices);
				Else
					pInvObj.Services.Load(vNewInvServices);
				EndIf;
				pInvObj.ExtraInvoice = True;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction // cmCheckOtherInvoices

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillExtraInvoiceServices(pInvObj, pExtraServices)
	vAccommodationService = cmGetAccommodationService(pExtraServices);
	pExtraServices.FillValues(vAccommodationService, "Service");
	pExtraServices.FillValues(0, "Price");
	pExtraServices.FillValues(0, "Quantity");
	pExtraServices.GroupBy("Service, VATRate", "Quantity, Price, Sum, VATSum, DiscountSum, CommissionSum, VATCommissionSum");
	pInvObj.Services.Load(pExtraServices);
	For Each vServicesRow In pInvObj.Services Do
		If ValueIsFilled(pInvObj.GuestGroup) Then
			vServicesRow.Remarks = cmNStr("en='Extra charge by guest group N';ru='Доплата по группе N';de='Zuzahlung nach Gruppe N'", ?(ValueIsFilled(pInvObj.AccountingCustomer), pInvObj.AccountingCustomer.Language, Catalogs.Languages.RU)) + Format(pInvObj.GuestGroup.Code, "ND=12; NFD=0; NG=");
		ElsIf ValueIsFilled(pInvObj.AccountingContract) Then
			vServicesRow.Remarks = cmNStr("en='Extra charge by contract ';ru='Доплата по договору ';de='Zuzahlung nach Vertrag '", ?(ValueIsFilled(pInvObj.AccountingCustomer), pInvObj.AccountingCustomer.Language, Catalogs.Languages.RU)) + TrimAll(pInvObj.AccountingContract);
		Else
			vServicesRow.Remarks = cmNStr("en='Extra charge';ru='Доплата';de='Zuzahlung'", ?(ValueIsFilled(pInvObj.AccountingCustomer), pInvObj.AccountingCustomer.Language, Catalogs.Languages.RU));
		EndIf;
		vServicesRow.Price = vServicesRow.Sum;
		vServicesRow.Quantity = 1;
	EndDo;
EndProcedure // FillExtraInvoiceServices

#EndRegion
