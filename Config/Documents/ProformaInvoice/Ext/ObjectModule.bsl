
#Region Variables

Var RootChecked;

#EndRegion

#Region EventHandlers 

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Folio") Then
			Hotel = pBase.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillByFolio(pBase);
		ElsIf TypeOf(pBase) = Type("Structure") And pBase.Property("Type") And 
		      ValueIsFilled(pBase.Type) And ValueIsFilled(pBase.Type.Hotel) Then 
			Hotel = pBase.Type.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillByFolioWithTree(pBase.Type, pBase.Tree, pBase.AllRows);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Order") Then
			Hotel = pBase.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillByOrder(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Payment") Then
			Hotel = pBase.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillByPayment(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.DepositTransfer") Then
			Hotel = pBase.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillByDepositTransfer(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.CustomerPayment") Then
			Hotel = pBase.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillByCustomerPayment(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Return") Then
			Hotel = pBase.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillByReturn(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Reservation") Then
			Hotel = pBase.Hotel;
			vAccRef = cmGetAccommodationByReservation(pBase);
			pmFillAttributesWithDefaultValues();
			pmFillByReservation(?(ValueIsFilled(vAccRef), vAccRef, pBase));
		ElsIf TypeOf(pBase) = Type("DocumentRef.ResourceReservation") Then 
			Hotel = pBase.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillByResourceReservation(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Accommodation") Then
			Hotel = pBase.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillByReservation(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Settlement") Then 
			Hotel = pBase.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillBySettlement(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.IssueHotelProducts") Then 
			Hotel = pBase.Hotel;
			pmFillAttributesWithDefaultValues();
			pmFillByIssueHotelProducts(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.GuestGroups") Then
			Hotel = pBase.Owner;
			pmFillAttributesWithDefaultValues();
			pmFillByGuestGroup(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.Customers") Then
			pmFillAttributesWithDefaultValues();
			pmFillByCustomer(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.Contracts") Then
			pmFillAttributesWithDefaultValues();
			pmFillByContract(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.Events") Then
			pmFillAttributesWithDefaultValues();
			pmFillByEvent(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.RoomQuotas") Then
			pmFillAttributesWithDefaultValues();
			pmFillByAllotment(pBase);
		Else
			pmFillAttributesWithDefaultValues();
		EndIf;
		// Fill invoice contact information
		If ValueIsFilled(AccountingCustomer) Then
			If AccountingCustomer.IsIndividual And ValueIsFilled(Hotel) And 
			   ValueIsFilled(Hotel.IndividualsCustomer) And AccountingCustomer <> Hotel.IndividualsCustomer Then
				If Not ValueIsFilled(ContactPerson) Then
					ContactPerson = Title(TrimAll(AccountingCustomer.Description));
				EndIf;
			EndIf;
			If Not ValueIsFilled(Phone) Then
				Phone = TrimAll(AccountingCustomer.Phone);
			EndIf;
			If Not ValueIsFilled(Fax) Then
				Fax = TrimAll(AccountingCustomer.Fax);
			EndIf;
			If Not ValueIsFilled(EMail) Then
				EMail = TrimAll(AccountingCustomer.EMail);
			EndIf;
		EndIf;
	Else
		pmFillAttributesWithDefaultValues();
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	
	// Recalculate settlement totals
	vSum = 0;
	vVATSum = 0;
	If ValueIsFilled(AccountingCustomer) And AccountingCustomer.DoNotPostCommission Then
		vSum = Services.Total("Sum");
		vVATSum = Services.Total("VATSum");
	Else
		vSum = Services.Total("Sum") - Services.Total("CommissionSum");
		vVATSum = Services.Total("VATSum") - Services.Total("VATCommissionSum");
	EndIf;
	If vSum <> Sum Then
		Sum = vSum;
	EndIf;
	If vVATSum <> VATSum Then
		VATSum = vVATSum;
	EndIf;
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
	
	// 1. Invoice accounts
	PostToInvoiceAccounts();
EndProcedure // Posting

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
		If Not Ref.Posted Or 
		   Ref.Hotel <> Hotel Or 
		   Ref.Company <> Company Or 
		   Ref.AccountingCustomer <> AccountingCustomer Or 
		   Ref.AccountingContract <> AccountingContract Or 
		   Ref.GuestGroup <> GuestGroup Or 
		   Ref.AccountingCurrency <> AccountingCurrency Or 
		   ServicesHasChanged() Then
			ChangeAuthor = SessionParameters.CurrentUser;
			ChangeDate = CurrentSessionDate();
		EndIf;
	Else
		If Ref.Posted And (pWriteMode = DocumentWriteMode.UndoPosting Or DeletionMark) Then
			ChangeAuthor = SessionParameters.CurrentUser;
			ChangeDate = CurrentSessionDate();
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vCU = SessionParameters.CurrentUser;
		If ValueIsFilled(vCU.Parent) Then
			vCUParent = vCU.Parent;
			If Not IsBlankString(vCUParent.Prefix) Then
				vPrefix = TrimAll(vCUParent.Prefix);
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vPrefix) Then
		If ValueIsFilled(Company) And (Company.UsePrefixForProformaInvoices Or Company.UseGroupCodeAsInvoiceNumberPrefix) Then
			vPrefixLen = 0;
			If Company.UsePrefixForProformaInvoices And Not IsBlankString(Company.Prefix) Then
				vPrefix = TrimAll(Company.Prefix);
				If Not IsBlankString(vPrefix) Then
					vPrefixLen = StrLen(vPrefix) + 1;
				EndIf;
			EndIf;
			If Company.UseGroupCodeAsInvoiceNumberPrefix And ValueIsFilled(GuestGroup) Then
				vGroupCode = Format(GuestGroup.Code, "ND=12; NFD=0; NG=");
				If StrLen(vGroupCode) < 10 Then
					vGroupCode = Format(GuestGroup.Code, "ND=" + Format((12 - 3 - vPrefixLen), "ND=1; NFD=0; NZ=") + "; NFD=0; NLZ=; NG=");
				EndIf;
				If Not IsBlankString(vPrefix) Then
					vPrefix = vPrefix + "/" + vGroupCode + "/";
				Else
					vPrefix = vGroupCode + "/";
				EndIf;
			EndIf;
		ElsIf ValueIsFilled(Hotel) Then
			vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
		ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
			If ValueIsFilled(SessionParameters.CurrentHotel.Company) And SessionParameters.CurrentHotel.Company.UsePrefixForProformaInvoices And Not IsBlankString(SessionParameters.CurrentHotel.Company.Prefix) Then
				vPrefix = TrimAll(SessionParameters.CurrentHotel.Company.Prefix);
			Else
				vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
			EndIf;
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
	ExternalCode = "";
	ChangeAuthor = Undefined;
	ChangeDate = '00010101';
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
	If Not ValueIsFilled(AccountingCustomer) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Контрагент> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Customer> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextEn + "<Customer> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCustomer", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(AccountingCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта счета> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Accounting currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextEn + "<Accounting currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCurrency", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	ExchangeRateDate = Date;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(AccountingCurrency) Then
			AccountingCurrency = Hotel.FolioCurrency;
			AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
		EndIf;
		If Not ValueIsFilled(Company) Then
			Company = Hotel.Company;
		EndIf;
		If ValueIsFilled(Company) Then
			If Not ValueIsFilled(BankAccount) Then
				FillBankAccount();
			EndIf;
		EndIf;
	EndIf;
	vStamp = New Picture;
	If ValueIsFilled(Company) Then
		If Company.Stamp <> Undefined Then
			vStamp = Company.Stamp.Get();
			If vStamp <> Undefined And TypeOf(vStamp) = Type("Picture") Then
				PrintWithCompanyStamp = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmFillServices(pCharges, pLanguage = Undefined) Export
	For Each vFolioChargesRow In pCharges Do
		If ValueIsFilled(vFolioChargesRow.Charge) And vFolioChargesRow.Company = Company Then
			vServicesRow = Services.Add();
			If ValueIsFilled(vFolioChargesRow.Folio) Then
				FillPropertyValues(vServicesRow, vFolioChargesRow.Folio);
			EndIf;
			vParentDoc = vFolioChargesRow.Charge.ParentDoc;
			If ValueIsFilled(vParentDoc) Then
				FillPropertyValues(vServicesRow, vParentDoc);
				If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
					vServicesRow.Client = vParentDoc.Guest;
				EndIf;
			EndIf;
			FillPropertyValues(vServicesRow, vFolioChargesRow.Charge);
			vServicesRow.AccountingDate = BegOfDay(vFolioChargesRow.Charge.Date);
			vServicesRow.Sum = vFolioChargesRow.SumBalance;
			vServicesRow.VATSum = vFolioChargesRow.VATSumBalance;
			vServicesRow.Quantity = vFolioChargesRow.QuantityBalance;
			vServicesRow.Price = cmRecalculatePrice(vServicesRow.Sum, vServicesRow.Quantity);
			vServicesRow.DiscountSum = vFolioChargesRow.DiscountSum;
			vServicesRow.Discount = vFolioChargesRow.Discount;
			// Commission
			vServicesRow.CommissionSum = 0;
			vServicesRow.VATCommissionSum = 0;
			vServicesRow.Agent = Undefined;
			If ValueIsFilled(vFolioChargesRow.Folio) Then
				vServicesRow.Agent = vFolioChargesRow.Folio.Agent;
			EndIf;
			If vFolioChargesRow.CommissionSumBalance <> 0 Then
				vServicesRow.AgentCommissionType = vFolioChargesRow.Charge.AgentCommissionType;
				vServicesRow.AgentCommission = vFolioChargesRow.Charge.AgentCommission;
				If Not ValueIsFilled(vServicesRow.Agent) Or 
				   ValueIsFilled(vServicesRow.Agent) And vServicesRow.Agent <> AccountingCustomer Then
					vServicesRow.Agent = Undefined;
					vServicesRow.AgentCommissionType = Undefined;
					vServicesRow.AgentCommission = 0;
				EndIf;
				pmCalculateServiceCommissions(vParentDoc, vServicesRow);
			EndIf;
			// Check base room type
			If ValueIsFilled(vParentDoc) And (TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation")) Then
				If ValueIsFilled(vServicesRow.RoomType) And ValueIsFilled(vParentDoc.RoomTypeUpgrade) And vParentDoc.RoomTypeUpgrade.BaseRoomType = vServicesRow.RoomType Then
					vServicesRow.RoomType = vParentDoc.RoomTypeUpgrade;
				EndIf;
			EndIf;
			// Recalculate service according to the accounting currency
			pmRecalculateService(vServicesRow, vFolioChargesRow.Charge.FolioCurrency, vFolioChargesRow.Charge.FolioCurrencyExchangeRate);
			// Fill remarks by service description by default
			vServiceDescription = TrimAll(vServicesRow.Service);
			If ValueIsFilled(vServicesRow.Service) Then
				vServiceObj = vServicesRow.Service.GetObject();
				vServiceDescription = vServiceObj.pmGetServiceDescription(pLanguage);
			EndIf;
			vServicesRow.Remarks = vServiceDescription + 
			                       ?(IsBlankString(vServicesRow.Remarks), "", " - " + cmNStr(TrimAll(vServicesRow.Remarks), pLanguage));
		EndIf;
	EndDo;
EndProcedure // pmFillServices	

// -----------------------------------------------------------------------------
// Fill invoice check date
// -----------------------------------------------------------------------------
Procedure pmFillCheckDate() Export
	vCheckDate = '00010101';
	vUpdateCheckDate = False;
	If Not ValueIsFilled(CheckDate) And ValueIsFilled(GuestGroup) Then
		If ValueIsFilled(AccountingContract) And (AccountingContract.DaysBeforeCheckIn <> 0 Or AccountingContract.DaysAfterReservation <> 0) Then
			vUpdateCheckDate = True;
			If AccountingContract.DaysBeforeCheckIn <> 0 And ValueIsFilled(GuestGroup.CheckInDate) Then
				vCheckDate = BegOfDay(GuestGroup.CheckInDate) - 24*3600*AccountingContract.DaysBeforeCheckIn;
			ElsIf AccountingContract.DaysAfterReservation <> 0 And ValueIsFilled(Date) Then
				vCheckDate = cmAddWorkingDays(BegOfDay(Date), (AccountingContract.DaysAfterReservation + 1));
			EndIf;
		ElsIf ValueIsFilled(AccountingCustomer) And (AccountingCustomer.DaysBeforeCheckIn <> 0 Or AccountingCustomer.DaysAfterReservation <> 0) Then
			vUpdateCheckDate = True;
			If AccountingCustomer.DaysBeforeCheckIn <> 0 And ValueIsFilled(GuestGroup.CheckInDate) Then
				vCheckDate = BegOfDay(GuestGroup.CheckInDate) - 24*3600*AccountingCustomer.DaysBeforeCheckIn;
			ElsIf AccountingCustomer.DaysAfterReservation <> 0 And ValueIsFilled(Date) Then
				vCheckDate = cmAddWorkingDays(BegOfDay(Date), (AccountingCustomer.DaysAfterReservation + 1));
			EndIf;
		ElsIf ValueIsFilled(Hotel) And (Hotel.DaysBeforeCheckIn <> 0 Or Hotel.DaysAfterReservation <> 0) Then
			vUpdateCheckDate = True;
			If Hotel.DaysBeforeCheckIn <> 0 And ValueIsFilled(GuestGroup.CheckInDate) Then
				vCheckDate = BegOfDay(GuestGroup.CheckInDate) - 24*3600*Hotel.DaysBeforeCheckIn;
			ElsIf Hotel.DaysAfterReservation <> 0 And ValueIsFilled(Date) Then
				vCheckDate = cmAddWorkingDays(BegOfDay(Date), (Hotel.DaysAfterReservation + 1));
			EndIf;
		EndIf;
	EndIf;
	If vUpdateCheckDate And ValueIsFilled(vCheckDate) And CheckDate <> vCheckDate Then
		CheckDate = vCheckDate;
	EndIf;
EndProcedure // pmFillCheckDate

// -----------------------------------------------------------------------------
Procedure pmFillByFolioWithTree(pFolio, Tree, AllRows, pDetailed = False) Export
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	
	If ValueIsFilled(pFolio.Hotel) Then
		If Hotel <> pFolio.Hotel Then
			Hotel = pFolio.Hotel;
			If Not IsNew() Then
				SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
			EndIf;
		EndIf;
	EndIf;
	
	ParentDoc = pFolio;
	Folio = pFolio;
	
	// Fill phone number
	Phone = pFolio.Client.Phone;
	
	// Fill email adress
	EMail = pFolio.Client.EMail;
	
	// Fill currency
	AccountingCurrency = pFolio.FolioCurrency;
	AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	
	// Fill company
	If ValueIsFilled(pFolio.Company) Then
		Company = pFolio.Company;
	Else
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.Company) Then
				Company = Hotel.Company;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Company) Then
		FillBankAccount();
	EndIf;
	
	// Fill accounting customer, contract and guest group
	AccountingCustomer = pFolio.Customer;
	AccountingContract = pFolio.Contract;
	GuestGroup = pFolio.GuestGroup;
	
	// Fill default customer
	If Not ValueIsFilled(AccountingCustomer) Then
		If ValueIsFilled(Hotel) Then
			AccountingCustomer = Hotel.IndividualsCustomer;
			AccountingContract = Hotel.IndividualsContract;
		EndIf;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// Fill Services 
	RootChecked = False;
	Services.Clear();
	
	TraverseTreeRecursivelyTreeRows(Tree, pFolio.Client, pFolio.Hotel);
	
	ConvertToPrepaimentModeIfNecessary(pDetailed);
	
	// Fill totals
	Sum = Services.Total("Sum");
	VATSum = Services.Total("VATSum");
	
	// Fill check date
	pmFillCheckDate();
EndProcedure // pmFillByFolioWithTree

// -----------------------------------------------------------------------------
Procedure pmFillByFolio(pFolio, pDetailed = False) Export
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	
	If ValueIsFilled(pFolio.Hotel) Then
		If Hotel <> pFolio.Hotel Then
			Hotel = pFolio.Hotel;
			If Not IsNew() Then
				SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
			EndIf;
		EndIf;
	EndIf;
	
	ParentDoc = pFolio;
	
	// Fill currency
	AccountingCurrency = pFolio.FolioCurrency;
	AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	
	// Fill company
	If ValueIsFilled(pFolio.Company) Then
		Company = pFolio.Company;
	Else
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.Company) Then
				Company = Hotel.Company;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Company) Then
		FillBankAccount();
	EndIf;
	
	// Fill accounting customer, contract and guest group
	AccountingCustomer = pFolio.Customer;
	AccountingContract = pFolio.Contract;
	GuestGroup = pFolio.GuestGroup;
	
	// Fill default customer
	If Not ValueIsFilled(AccountingCustomer) Then
		If ValueIsFilled(Hotel) Then
			AccountingCustomer = Hotel.IndividualsCustomer;
			AccountingContract = Hotel.IndividualsContract;
		EndIf;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get all folio current accounts receivable services with balances per end of date
	vFolioCharges = pFolio.GetObject().pmGetCurrentAccountsReceivableChargesWithBalances('39991231235959');
	
	// Fill services tabular part
	pmFillServices(vFolioCharges, vLanguage);
	
	// Fill with prepaiment service in some modes
	ConvertToPrepaimentModeIfNecessary(pDetailed);
	
	// Fill totals
	Sum = Services.Total("Sum");
	VATSum = Services.Total("VATSum");
	
	// Fill check date
	pmFillCheckDate();
EndProcedure // pmFillByFolio

// -----------------------------------------------------------------------------
Procedure pmFillByOrder(pOrder, pDetailed = False) Export
	If Not ValueIsFilled(pOrder) Then
		Return;
	EndIf;
	If ValueIsFilled(pOrder.Hotel) Then
		If Hotel <> pOrder.Hotel Then
			Hotel = pOrder.Hotel;
			If Not IsNew() Then
				SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
			EndIf;
		EndIf;
	EndIf;
	ParentDoc = pOrder;
	
	// Fill Folio
	Folio = pOrder.Folio;
	
	// Fill phone number
	Phone = pOrder.Phone;
	
	// Fill email adress
	EMail = pOrder.Client.EMail;
	
	// Fill currency
	AccountingCurrency = pOrder.Currency;
	AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	
	// Fill company
	If ValueIsFilled(Folio.Company) Then
		Company = Folio.Company;
	Else
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.Company) Then
				Company = Hotel.Company;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Company) Then
		FillBankAccount();
	EndIf;
	
	Services.Clear();
	
	// Fill Services
	vSrvRow = Services.Add();
	vSrvRow.Service = pOrder.Service;
	vSrvRow.Price = pOrder.Price;
	vSrvRow.Sum = pOrder.Sum; 
	vSrvRow.Client = pOrder.Client;  
	If ValueIsFilled(pOrder.Type) And pOrder.Type.Type = Enums.TypesOfOrder.Transfer Then
		vSrvRow.Remarks = String(pOrder.TransferType) + " " + NStr("en = 'Pick up from '; de = 'Aufheben von '; ru = 'Забрать из '") + String(pOrder.PickupFrom) + " " + NStr("en = 'bring in '; de = 'hereinbringen '; ru = 'привезти в '") + String(pOrder.Destination) + " " + String(pOrder.OrderTime);
	Else
		vSrvRow.Remarks = pOrder.Remarks;
	EndIf;
	vPrices = cmGetServicePrice(pOrder.Service, pOrder.Hotel);
	If vPrices.Count() > 0 Then
		vSrvRow.VATRate =  vPrices[0].VATRate;
	Else
		vSrvRow.VATRate = Company.VATRate
	EndIf;
		
	// Fill accounting customer, contract and guest group
	AccountingCustomer = Folio.Customer;
	AccountingContract = Folio.Contract;
	GuestGroup = Folio.GuestGroup;
	
	// Fill default customer
	If Not ValueIsFilled(AccountingCustomer) Then
		If ValueIsFilled(Hotel) Then
			AccountingCustomer = Hotel.IndividualsCustomer;
			AccountingContract = Hotel.IndividualsContract;
		EndIf;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
	
	CheckDate = CurrentSessionDate();
EndProcedure // pmFillByOrder

// -----------------------------------------------------------------------------
Procedure pmRecalculateService(pSrvRow, pCurrencyFrom, Val pCurrencyFromExchangeRate = 0) Export
	If pCurrencyFromExchangeRate = 0 Then
		pCurrencyFromExchangeRate = cmGetCurrencyExchangeRate(Hotel, pCurrencyFrom, ExchangeRateDate);
	EndIf;
	If pCurrencyFrom <> AccountingCurrency Then
		pSrvRow.Price = Round(pSrvRow.Price * pCurrencyFromExchangeRate / AccountingCurrencyExchangeRate, 2);
		cmPriceOnChange(pSrvRow.Price, pSrvRow.Quantity, pSrvRow.Sum, pSrvRow.VATRate, pSrvRow.VATSum, pSrvRow.AccountingDate);
		pSrvRow.DiscountSum = Round(pSrvRow.DiscountSum * pCurrencyFromExchangeRate / AccountingCurrencyExchangeRate, 2);
		If pSrvRow.AgentCommission <> 0 Then
			pSrvRow.CommissionSum = Round(pSrvRow.Sum * pSrvRow.AgentCommission / 100, 2);
			pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
		Else
			pSrvRow.CommissionSum = 0;
			pSrvRow.VATCommissionSum = 0;
		EndIf;
	EndIf;
EndProcedure // pmRecalculateService

// -----------------------------------------------------------------------------
Procedure pmFillByReservation(pDoc, pDoNotClearServices = False, pDetailed = False) Export
	If Not ValueIsFilled(pDoc) Then
		Return;
	EndIf;
	
	vSetNewNumber = False;
	If ValueIsFilled(pDoc.Hotel) Then
		If Hotel <> pDoc.Hotel Then
			Hotel = pDoc.Hotel;
			vSetNewNumber = True;
		EndIf;
	EndIf;

	If Not ValueIsFilled(FillProformaInvoiceMode) Then
		FillProformaInvoiceMode = Hotel.FillProformaInvoiceMode;
	EndIf;
	
	ParentDoc = pDoc;

	// Fill remarks
	If ValueIsFilled(ParentDoc) And (TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation")) Then
		Remarks = TrimAll(ParentDoc.DiscountConfirmationText);
	EndIf;
	
	// Fill accounting customer, contract and guest group
	AccountingCustomer = pDoc.Customer;
	AccountingContract = pDoc.Contract;
	GuestGroup = pDoc.GuestGroup;
	
	vPayer = pDoc.GetObject().pmSetPlannedPaymentMethod();
	If vPayer = Enums.WhoPays.Agent And pDoc.Customer <> pDoc.Agent Then
		AccountingCustomer = pDoc.Agent;
		AccountingContract = Catalogs.Contracts.EmptyRef();
	EndIf;
	
	// Fill default customer
	If Not ValueIsFilled(AccountingCustomer) Then
		If ValueIsFilled(Hotel) Then
			AccountingCustomer = Hotel.IndividualsCustomer;
			AccountingContract = Hotel.IndividualsContract;
		EndIf;
	EndIf;
	
	// Fill currency
	If ValueIsFilled(AccountingContract) Then
		AccountingCurrency = AccountingContract.AccountingCurrency;
		AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	Else
		If ValueIsFilled(AccountingCustomer) Then
			AccountingCurrency = AccountingCustomer.AccountingCurrency;
			AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
		EndIf;
	EndIf;
	
	// Fill company
	If ValueIsFilled(pDoc.Company) Then
		If Company <> pDoc.Company Then
			Company = pDoc.Company;
			vSetNewNumber = True;
		EndIf;
	Else
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.Company) Then
				If Company <> Hotel.Company Then
					Company = Hotel.Company;
					vSetNewNumber = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Company) Then
		FillBankAccount();
	EndIf;
	
	// Set new number
	If vSetNewNumber Then
		If Not IsNew() Then
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Fill contact information
	ContactPerson = pDoc.ContactPerson;
	Phone = pDoc.Phone;
	Fax = pDoc.Fax;
	EMail = pDoc.EMail;
	If ValueIsFilled(GuestGroup) And ValueIsFilled(GuestGroup.Client) Then
		If IsBlankString(EMail) Then
			If Not IsBlankString(GuestGroup.Client.EMail) Then
				EMail = GuestGroup.Client.EMail;
			EndIf;
		EndIf;
		If IsBlankString(Phone) Then
			If Not IsBlankString(GuestGroup.Client.Phone) Then
				Phone = GuestGroup.Client.Phone;
			EndIf;
		EndIf;
		If IsBlankString(Fax) Then
			If Not IsBlankString(GuestGroup.Client.Fax) Then
				Fax = GuestGroup.Client.Fax;
			EndIf;
		EndIf;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// Clear tabular part Services
	If Not pDoNotClearServices Then
		Services.Clear();
	EndIf;
	
	// Get all services
	vIsClosed = False;
	If TypeOf(pDoc) = Type("DocumentRef.Reservation") And ValueIsFilled(pDoc.ReservationStatus) Then
		vIsClosed = Not pDoc.ReservationStatus.IsActive;
		If pDoc.ReservationStatus.IsPreliminary Then
			vIsClosed = False;
		EndIf;
	Else
		vIsClosed = Not pDoc.AccommodationStatus.IsActive;
	EndIf;
	If Not vIsClosed Then
		For Each vDocRow In pDoc.Services Do
			If vDocRow.Company <> Company Then
				Continue;
			EndIf;
 			vSrvRow = Services.Add();
			
			FillPropertyValues(vSrvRow, pDoc);
			FillPropertyValues(vSrvRow, vDocRow);
			
			vSrvRow.ParentDoc = pDoc;
			
			vSrvRow.Client = pDoc.Guest;
			vSrvRow.DateTimeFrom = pDoc.CheckInDate;
			vSrvRow.DateTimeTo = pDoc.CheckOutDate;
			If Not ValueIsFilled(pDoc.Room) Then
				vSrvRow.Room = pDoc.Number;
			EndIf;
			
			vSrvRow.Sum = vDocRow.Sum - vDocRow.DiscountSum;
			vSrvRow.VATSum = vDocRow.VATSum - vDocRow.VATDiscountSum;
			vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
			
			// Discounts
			vSrvRow.Discount = vDocRow.Discount;
			vSrvRow.DiscountSum = vDocRow.DiscountSum;
			
			// Commission
			vSrvRow.CommissionSum = 0;
			vSrvRow.VATCommissionSum = 0;
			vSrvRow.Agent = Undefined;
			If ValueIsFilled(vDocRow.Folio) Then
				vSrvRow.Agent = vDocRow.Folio.Agent;
			EndIf;
			vSrvRow.AgentCommissionType = vDocRow.AgentCommissionType;
			vSrvRow.AgentCommission = vDocRow.AgentCommission;
			If Not ValueIsFilled(vSrvRow.Agent) Or 
			   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
				vSrvRow.Agent = Undefined;
				vSrvRow.AgentCommissionType = Undefined;
				vSrvRow.AgentCommission = 0;
			EndIf;
			If vSrvRow.AgentCommission <> 0 Then
				// Check that current service fit to the commission service group
				If cmIsServiceInServiceGroup(vSrvRow.Service, pDoc.AgentCommissionServiceGroup) Then
					pmCalculateServiceCommissions(pDoc, vSrvRow);
				Else
					vSrvRow.Agent = Undefined;
					vSrvRow.AgentCommissionType = Undefined;
					vSrvRow.AgentCommission = 0;
				EndIf;
			EndIf;
			
			// Check base room type
			If ValueIsFilled(vSrvRow.RoomType) And ValueIsFilled(pDoc.RoomTypeUpgrade) And pDoc.RoomTypeUpgrade.BaseRoomType = vSrvRow.RoomType Then
				vSrvRow.RoomType = pDoc.RoomTypeUpgrade;
			EndIf;
			
			// Recalculate service according to the accounting currency
			pmRecalculateService(vSrvRow, vDocRow.FolioCurrency, vDocRow.FolioCurrencyExchangeRate);
			
			// Fill remarks by service description by default
			vServiceDescription = TrimAll(vSrvRow.Service);
			If ValueIsFilled(vSrvRow.Service) Then
				vServiceObj = vSrvRow.Service.GetObject();
				vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
			EndIf;
			vSrvRow.Remarks = vServiceDescription + 
							  ?(IsBlankString(vSrvRow.Remarks), "", " - " + cmNStr(TrimAll(vSrvRow.Remarks), vLanguage));
		EndDo;
	EndIf;
	
	// Get reservation charges for the folios
	vCharges = cmGetDocumentCharges(pDoc, AccountingCustomer, AccountingContract, Hotel, Undefined, True);
	For Each vDocRow In vCharges Do
		If Not vDocRow.IsAdditional Then
			Continue;
		EndIf;
		If vDocRow.Company <> Company Then
			Continue;
		EndIf;
		vSrvRow = Services.Add();
		
		vParentDoc = Undefined;
		If ValueIsFilled(vDocRow.Recorder.ParentDoc) And TypeOf(vDocRow.Recorder.ParentDoc) = Type("DocumentRef.Reservation") Then
			vParentDoc = vDocRow.Recorder.ParentDoc;
		EndIf;
		
		FillPropertyValues(vSrvRow, pDoc);
		FillPropertyValues(vSrvRow, vDocRow);
	
		vSrvRow.ParentDoc = vParentDoc;
		
		If ValueIsFilled(vParentDoc) Then
			vSrvRow.Client = vParentDoc.Guest;
			vSrvRow.DateTimeFrom = vParentDoc.CheckInDate;
			vSrvRow.DateTimeTo = vParentDoc.CheckOutDate;
			If Not ValueIsFilled(vParentDoc.Room) Then
				vSrvRow.Room = vParentDoc.Number;
			Else
				vSrvRow.Room = vParentDoc.Room;
			EndIf;
		Else
			vSrvRow.Client = pDoc.Guest;
			vSrvRow.DateTimeFrom = pDoc.CheckInDate;
			vSrvRow.DateTimeTo = pDoc.CheckOutDate;
			If Not ValueIsFilled(pDoc.Room) Then
				vSrvRow.Room = pDoc.Number;
			Else
				vSrvRow.Room = pDoc.Room;
			EndIf;
		EndIf;
		
		// Discounts
		vSrvRow.Discount = vDocRow.Discount;
		vSrvRow.DiscountSum = vDocRow.DiscountSum;
		
		// Commission
		vSrvRow.CommissionSum = 0;
		vSrvRow.VATCommissionSum = 0;
		vSrvRow.Agent = Undefined;
		If ValueIsFilled(vDocRow.Folio) Then
			vSrvRow.Agent = vDocRow.Folio.Agent;
		EndIf;
		vSrvRow.AgentCommissionType = vDocRow.AgentCommissionType;
		vSrvRow.AgentCommission = vDocRow.AgentCommission;
		If Not ValueIsFilled(vSrvRow.Agent) Or 
		   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
			vSrvRow.Agent = Undefined;
			vSrvRow.AgentCommissionType = Undefined;
			vSrvRow.AgentCommission = 0;
		EndIf;
		If vSrvRow.AgentCommission <> 0 Then
			vSrvRow.CommissionSum = vDocRow.CommissionSum;
			vSrvRow.VATCommissionSum = vDocRow.VATCommissionSum;
		EndIf;
		
		// Check base room type
		If ValueIsFilled(vSrvRow.RoomType) And ValueIsFilled(pDoc.RoomTypeUpgrade) And pDoc.RoomTypeUpgrade.BaseRoomType = vSrvRow.RoomType Then
			vSrvRow.RoomType = pDoc.RoomTypeUpgrade;
		EndIf;
		
		// Recalculate service according to the accounting currency
		pmRecalculateService(vSrvRow, vDocRow.FolioCurrency, vDocRow.FolioCurrencyExchangeRate);
		
		// Fill remarks by service description by default
		vServiceDescription = TrimAll(vSrvRow.Service);
		If ValueIsFilled(vSrvRow.Service) Then
			vServiceObj = vSrvRow.Service.GetObject();
			vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
		EndIf;
		vSrvRow.Remarks = vServiceDescription + 
						  ?(IsBlankString(vSrvRow.Remarks), "", " - " + cmNStr(TrimAll(vSrvRow.Remarks), vLanguage));
	EndDo;
	
	// Fill with prepaiment service in some modes
	ConvertToPrepaimentModeIfNecessary(pDetailed);
	
	// Fill totals
	If ValueIsFilled(AccountingCustomer) And AccountingCustomer.DoNotPostCommission Then
		Sum = Services.Total("Sum");
		VATSum = Services.Total("VATSum");
	Else
		Sum = Services.Total("Sum") - Services.Total("CommissionSum");
		VATSum = Services.Total("VATSum") - Services.Total("VATCommissionSum");
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
EndProcedure // pmFillByReservation

// -----------------------------------------------------------------------------
Procedure pmFillByResourceReservation(pDoc, pDetailed = False) Export
	If Not ValueIsFilled(pDoc) Then
		Return;
	EndIf;
	
	vSetNewNumber = False;
	If ValueIsFilled(pDoc.Hotel) Then
		If Hotel <> pDoc.Hotel Then
			Hotel = pDoc.Hotel;
			vSetNewNumber = True;
		EndIf;
	EndIf;
	
	GuestGroup = pDoc.GuestGroup;
	ParentDoc = pDoc;
	Folio = pDoc.ChargingFolio;
	
	// Fill accounting customer, contract and guest group
	If ValueIsFilled(pDoc.Owner) Then
		If TypeOf(pDoc.Owner) = Type("CatalogRef.Contracts") Then
			AccountingCustomer = pDoc.Owner.Owner;
			AccountingContract = pDoc.Owner;
		Else
			AccountingCustomer = pDoc.Owner;
			AccountingContract = Undefined;
		EndIf;
	Else
		AccountingCustomer = pDoc.Customer;
		AccountingContract = pDoc.Contract;
	EndIf;
	
	// Fill default customer
	If Not ValueIsFilled(AccountingCustomer) Then
		If ValueIsFilled(Hotel) Then
			AccountingCustomer = Hotel.IndividualsCustomer;
			AccountingContract = Hotel.IndividualsContract;
		EndIf;
	EndIf;
	
	// Fill currency
	If ValueIsFilled(AccountingContract) Then
		AccountingCurrency = AccountingContract.AccountingCurrency;
		AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	Else
		If ValueIsFilled(AccountingCustomer) Then
			AccountingCurrency = AccountingCustomer.AccountingCurrency;
			AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
		EndIf;
	EndIf;
	
	// Fill company
	If ValueIsFilled(pDoc.Company) Then
		If Company <> pDoc.Company Then
			Company = pDoc.Company;
			vSetNewNumber = True;
		EndIf;
	Else
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.Company) Then
				If Company <> Hotel.Company Then
					Company = Hotel.Company;
					vSetNewNumber = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Company) Then
		FillBankAccount();
	EndIf;
	
	// Set new number
	If vSetNewNumber Then
		If Not IsNew() Then
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Fill contact information
	ContactPerson = pDoc.ContactPerson;
	Phone = pDoc.Phone;
	Fax = pDoc.Fax;
	EMail = pDoc.EMail;
	If ValueIsFilled(GuestGroup) And ValueIsFilled(GuestGroup.Client) Then
		If IsBlankString(EMail) Then
			If Not IsBlankString(GuestGroup.Client.EMail) Then
				EMail = GuestGroup.Client.EMail;
			EndIf;
		EndIf;
		If IsBlankString(Phone) Then
			If Not IsBlankString(GuestGroup.Client.Phone) Then
				Phone = GuestGroup.Client.Phone;
			EndIf;
		EndIf;
		If IsBlankString(Fax) Then
			If Not IsBlankString(GuestGroup.Client.Fax) Then
				Fax = GuestGroup.Client.Fax;
			EndIf;
		EndIf;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get all services
	vIsClosed = False;
	If ValueIsFilled(pDoc.ResourceReservationStatus) Then
		vIsClosed = Not pDoc.ResourceReservationStatus.IsActive;
	EndIf;
	If Not vIsClosed Then
		For Each vDocRow In pDoc.Services Do
			If vDocRow.Company <> Company Then
				Continue;
			EndIf;
			If pDoc.DoCharging Then
				If ValueIsFilled(vDocRow.Service) And ValueIsFilled(vDocRow.Service.ServiceType) And vDocRow.Service.ServiceType.ActualAmountIsChargedExternally Then
					Continue;
				EndIf;
			EndIf;
			
			vSrvRow = Services.Add();
			
			FillPropertyValues(vSrvRow, pDoc);
			FillPropertyValues(vSrvRow, vDocRow);
		
			vSrvRow.ParentDoc = pDoc;
			
			vSrvRow.Sum = vDocRow.Sum - vDocRow.DiscountSum;
			vSrvRow.VATSum = vDocRow.VATSum - vDocRow.VATDiscountSum;
			vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
			
			// Discounts
			vSrvRow.Discount = vDocRow.Discount;
			vSrvRow.DiscountSum = vDocRow.DiscountSum;
			
			// Commission
			vSrvRow.CommissionSum = 0;
			vSrvRow.VATCommissionSum = 0;
			vSrvRow.Agent = Undefined;
			If ValueIsFilled(pDoc.ChargingFolio) Then
				vSrvRow.Agent = pDoc.ChargingFolio.Agent;
			EndIf;
			vSrvRow.AgentCommissionType = vDocRow.AgentCommissionType;
			vSrvRow.AgentCommission = vDocRow.AgentCommission;
			If Not ValueIsFilled(vSrvRow.Agent) Or 
			   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
				vSrvRow.Agent = Undefined;
				vSrvRow.AgentCommissionType = Undefined;
				vSrvRow.AgentCommission = 0;
			EndIf;
			If vSrvRow.AgentCommission <> 0 Then
				// Check that current service fit to the commission service group
				If cmIsServiceInServiceGroup(vSrvRow.Service, pDoc.AgentCommissionServiceGroup) Then
					pmCalculateServiceCommissions(pDoc, vSrvRow);
				Else
					vSrvRow.Agent = Undefined;
					vSrvRow.AgentCommissionType = Undefined;
					vSrvRow.AgentCommission = 0;
				EndIf;
			EndIf;
			
			// Recalculate service according to the accounting currency
			pmRecalculateService(vSrvRow, pDoc.FolioCurrency, pDoc.FolioCurrencyExchangeRate);
			
			// Fill remarks by service description by default
			vServiceDescription = TrimAll(vSrvRow.Service);
			If ValueIsFilled(vSrvRow.Service) Then
				vServiceObj = vSrvRow.Service.GetObject();
				vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
			EndIf;
			vSrvRow.Remarks = vServiceDescription + 
							  ?(IsBlankString(vSrvRow.Remarks), "", " - " + cmNStr(TrimAll(vSrvRow.Remarks), vLanguage));
		EndDo;
	EndIf;
	
	// Get reservation charges for the folios
	vCharges = cmGetDocumentCharges(pDoc, AccountingCustomer, AccountingContract, Hotel, Undefined, True);
	For Each vDocRow In vCharges Do
		If Not vDocRow.IsAdditional Then
			Continue;
		EndIf;
		If vDocRow.Company <> Company Then
			Continue;
		EndIf;
		vSrvRow = Services.Add();
		
		FillPropertyValues(vSrvRow, pDoc);
		FillPropertyValues(vSrvRow, vDocRow);
	
		vSrvRow.ParentDoc = pDoc;
		
		// Discounts
		vSrvRow.Discount = vDocRow.Discount;
		vSrvRow.DiscountSum = vDocRow.DiscountSum;
		
		// Commission
		vSrvRow.CommissionSum = 0;
		vSrvRow.VATCommissionSum = 0;
		vSrvRow.Agent = Undefined;
		If ValueIsFilled(vDocRow.Folio) Then
			vSrvRow.Agent = vDocRow.Folio.Agent;
		EndIf;
		vSrvRow.AgentCommissionType = vDocRow.AgentCommissionType;
		vSrvRow.AgentCommission = vDocRow.AgentCommission;
		If Not ValueIsFilled(vSrvRow.Agent) Or 
		   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
			vSrvRow.Agent = Undefined;
			vSrvRow.AgentCommissionType = Undefined;
			vSrvRow.AgentCommission = 0;
		EndIf;
		If vSrvRow.AgentCommission <> 0 Then
			vSrvRow.CommissionSum = vDocRow.CommissionSum;
			vSrvRow.VATCommissionSum = vDocRow.VATCommissionSum;
		EndIf;
		
		// Recalculate service according to the accounting currency
		pmRecalculateService(vSrvRow, pDoc.FolioCurrency, pDoc.FolioCurrencyExchangeRate);
		
		// Fill remarks by service description by default
		vServiceDescription = TrimAll(vSrvRow.Service);
		If ValueIsFilled(vSrvRow.Service) Then
			vServiceObj = vSrvRow.Service.GetObject();
			vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
		EndIf;
		vSrvRow.Remarks = vServiceDescription + 
						  ?(IsBlankString(vSrvRow.Remarks), "", " - " + cmNStr(TrimAll(vSrvRow.Remarks), vLanguage));
	EndDo;
	
	// Fill with prepaiment service in some modes
	ConvertToPrepaimentModeIfNecessary(pDetailed);
	
	// Fill totals
	If ValueIsFilled(AccountingCustomer) And AccountingCustomer.DoNotPostCommission Then
		Sum = Services.Total("Sum");
		VATSum = Services.Total("VATSum");
	Else
		Sum = Services.Total("Sum") - Services.Total("CommissionSum");
		VATSum = Services.Total("VATSum") - Services.Total("VATCommissionSum");
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
EndProcedure // pmFillByResourceReservation

// -----------------------------------------------------------------------------
Procedure pmFillBySettlement(pDoc, pDoNotClearServices = False) Export
	If Not ValueIsFilled(pDoc) Then
		Return;
	EndIf;
	
	vSetNewNumber = False;
	If ValueIsFilled(pDoc.Hotel) Then
		If Hotel <> pDoc.Hotel Then
			Hotel = pDoc.Hotel;
			vSetNewNumber = True;
		EndIf;
	EndIf;
	
	FillPropertyValues(ThisObject, pDoc, , "Number, Date, Author, DeletionMark, Posted, ParentDoc, ExternalCode");
	
	ParentDoc = pDoc;
	
	// Fill company
	If Not ValueIsFilled(pDoc.Company) Then
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.Company) Then
				Company = Hotel.Company;
				vSetNewNumber = True;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Company) Then
		FillBankAccount();
	EndIf;
	
	// Set new number
	If vSetNewNumber Then
		If Not IsNew() Then
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// Clear tabular part Services
	If Not pDoNotClearServices Then
		Services.Clear();
	EndIf;
	
	// Try get services posted by settlement to accounts
	vServices = pDoc.GetObject().pmGetServicesPostedToAccounts();
	If vServices.Count() = 0 Then
		vServices = pDoc.Services;
	EndIf;
	
	// Fill invoice services
	For Each vDocRow In vServices Do
		vSrvRow = Services.Add();
		If ValueIsFilled(vDocRow.ParentDoc) Then
			FillPropertyValues(vSrvRow, vDocRow.ParentDoc);
		EndIf;
		If ValueIsFilled(vDocRow.Folio) Then
			FillPropertyValues(vSrvRow, vDocRow.Folio);
		EndIf;
		If ValueIsFilled(vDocRow.Charge) Then
			FillPropertyValues(vSrvRow, vDocRow.Charge);
		EndIf;
		FillPropertyValues(vSrvRow, vDocRow);
		
		// Commission
		If Not ValueIsFilled(vSrvRow.Agent) Or 
		   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
			vSrvRow.Agent = Undefined;
			vSrvRow.AgentCommissionType = Undefined;
			vSrvRow.AgentCommission = 0;
			vSrvRow.CommissionSum = 0;
			vSrvRow.VATCommissionSum = 0;
		EndIf;
	EndDo;
	
	// Fill totals
	If ValueIsFilled(AccountingCustomer) And AccountingCustomer.DoNotPostCommission Then
		Sum = Services.Total("Sum");
		VATSum = Services.Total("VATSum");
	Else
		Sum = Services.Total("Sum") - Services.Total("CommissionSum");
		VATSum = Services.Total("VATSum") - Services.Total("VATCommissionSum");
	EndIf;
	
	// Fill check date
	If ValueIsFilled(GuestGroup) And Not ValueIsFilled(CheckDate) Then
		vCheckDate = Undefined;
		If ValueIsFilled(AccountingContract) And AccountingContract.DaysAfterSettlement <> 0 And ValueIsFilled(Date) Then
			vCheckDate = cmAddWorkingDays(BegOfDay(Date), (AccountingContract.DaysAfterSettlement + 1));
		ElsIf ValueIsFilled(AccountingCustomer) And AccountingCustomer.DaysAfterSettlement <> 0 And ValueIsFilled(Date) Then
			vCheckDate = cmAddWorkingDays(BegOfDay(Date), (AccountingCustomer.DaysAfterSettlement + 1));
		EndIf;
		If ValueIsFilled(vCheckDate) Then
			CheckDate = vCheckDate;
		EndIf;
	EndIf;
EndProcedure // pmFillBySettlement

// -----------------------------------------------------------------------------
Procedure pmFillByIssueHotelProducts(pDoc) Export
	If Not ValueIsFilled(pDoc) Then
		Return;
	EndIf;
	
	If ValueIsFilled(pDoc.Hotel) Then
		If Hotel <> pDoc.Hotel Then
			Hotel = pDoc.Hotel;
			If Not IsNew() Then
				SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
			EndIf;
		EndIf;
	EndIf;
	
	FillPropertyValues(ThisObject, pDoc, , "Number, Date, Author, DeletionMark, Posted");
	
	// Fill accounting customer and contract
	AccountingCustomer = pDoc.Customer;
	AccountingContract = pDoc.Contract;
	
	ParentDoc = pDoc;
	
	// Currency
	AccountingCurrency = pDoc.Currency;
	AccountingCurrencyExchangeRate = pDoc.CurrencyExchangeRate;
	
	// Fill bank account
	If ValueIsFilled(Company) Then
		FillBankAccount();
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get all services
	For Each vDocRow In pDoc.HotelProducts Do
		If Not ValueIsFilled(vDocRow.Service) Then
			Continue;
		EndIf;
		vServicesRow = Services.Add();
		vServicesRow.AccountingDate = BegOfDay(pDoc.Date);
		vServicesRow.Service = vDocRow.Service;
		vServicesRow.Price = vDocRow.Price;
		vServicesRow.Quantity = vDocRow.Quantity;
		vServicesRow.Unit = NStr("en='pcs.';ru='шт.';de='Stück'");
		vServicesRow.Sum = vDocRow.Sum;
		vServicesRow.VATRate = pDoc.VATRate;
		vServicesRow.VATSum = vDocRow.VATSum;
		vServicesRow.RoomType = vDocRow.RoomType;
		vServicesRow.DateTimeFrom = vDocRow.CheckInDate;
		vServicesRow.DateTimeTo = vDocRow.CheckOutDate;
		vServiceRemarks = vDocRow.Service.Description;
		If Not IsBlankString(vDocRow.ProductStartCode) Then
			If TrimAll(vDocRow.ProductStartCode) = TrimAll(vDocRow.ProductEndCode) Then
				vServiceRemarks = TrimAll(vDocRow.ProductStartCode);
			Else
				vServiceRemarks = TrimAll(vDocRow.ProductStartCode) + " - " + TrimAll(vDocRow.ProductEndCode);
			EndIf;
		EndIf;
		vServicesRow.Remarks = vServiceRemarks;
	EndDo;
	
	// Fill totals
	If ValueIsFilled(AccountingCustomer) And AccountingCustomer.DoNotPostCommission Then
		Sum = Services.Total("Sum");
		VATSum = Services.Total("VATSum");
	Else
		Sum = Services.Total("Sum") - Services.Total("CommissionSum");
		VATSum = Services.Total("VATSum") - Services.Total("VATCommissionSum");
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
EndProcedure // pmFillByIssueHotelProducts

// -----------------------------------------------------------------------------
Procedure pmFillByGuestGroup(pGuestGroup, pDoNotClearServices = False, pDetailed = False) Export
	If Not ValueIsFilled(pGuestGroup) Then
		Return;
	EndIf;
	
	// Reset folio if filled
	Folio = Undefined;
	
	// Accounting customer, contract, hotel, company, currency should be filled before calling Fill() method
	GuestGroup = pGuestGroup;
	If ValueIsFilled(GuestGroup) Then
		If ValueIsFilled(GuestGroup.Agent) And GuestGroup.Payer = Enums.WhoPays.Agent And GuestGroup.Agent <> GuestGroup.Customer Then
			AccountingCustomer = GuestGroup.Agent;
			AccountingContract = Catalogs.Contracts.EmptyRef();
		ElsIf ValueIsFilled(GuestGroup.Customer) And Not ValueIsFilled(AccountingCustomer) Then
			AccountingCustomer = GuestGroup.Customer;
			If ValueIsFilled(GuestGroup.Contract) And Not ValueIsFilled(AccountingContract) Then
				AccountingContract = GuestGroup.Contract;
			EndIf;
		EndIf;
		If ValueIsFilled(GuestGroup.Client) Then
			If IsBlankString(EMail) Then
				If Not IsBlankString(GuestGroup.Client.EMail) Then
					EMail = GuestGroup.Client.EMail;
				EndIf;
			EndIf;
			If IsBlankString(Phone) Then
				If Not IsBlankString(GuestGroup.Client.Phone) Then
					Phone = GuestGroup.Client.Phone;
				EndIf;
			EndIf;
			If IsBlankString(Fax) Then
				If Not IsBlankString(GuestGroup.Client.Fax) Then
					Fax = GuestGroup.Client.Fax;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(AccountingCustomer) Then
		AccountingCustomer = Hotel.IndividualsCustomer;
		AccountingContract = Hotel.IndividualsContract;
	Endif;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;

	If Not ValueIsFilled(FillProformaInvoiceMode) Then
		FillProformaInvoiceMode = Hotel.FillProformaInvoiceMode;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// List of main charges
	vChargesToSkip = New ValueList();
	
	// Clear tabular part Services
	If Not pDoNotClearServices Then
		Services.Clear();
	EndIf;
	
	// Get list of reservations (or accommodations) in the group
	vGroupObj = GuestGroup.GetObject();
	vReservations = New ValueTable();
	vAccommodations = New ValueTable();
	If ParentDoc = Undefined Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
		vReservations = vGroupObj.pmGetReservations(True, False);
		vAccommodations = vGroupObj.pmGetAccommodations(True);
	EndIf;
	vResourceReservations = New ValueTable();
	If ParentDoc = Undefined Or TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
		vResourceReservations = vGroupObj.pmGetResourceReservations();
	EndIf;
	
	// Initialize working table with services
	vServices = Services.Unload();
	vServices.Clear();
	vServices.Columns.Add("Document");
	
	// Fill services for each reservation in the list
	For Each vRow In vReservations Do
		vDoc = vRow.Reservation;
		
		// Add services to the working table from the current document tabular part
		vIsActive = False;
		If ValueIsFilled(vRow.Status) Then
			vIsActive = (vRow.Status.IsActive Or vRow.Status.IsPreliminary) And Not vRow.Status.IsCheckIn;
		EndIf;
		If vIsActive Then
			For Each vDocRow In vDoc.Services Do
				If vDocRow.Company <> Company Then
					Continue;
				EndIf;
				If ValueIsFilled(vDocRow.Folio) And
				   (vDocRow.Folio.Customer = AccountingCustomer Or (vDocRow.Folio.Customer = Catalogs.Customers.EmptyRef() And AccountingCustomer = Hotel.IndividualsCustomer)) And 
				   (vDocRow.Folio.Contract = AccountingContract Or (vDocRow.Folio.Contract = Catalogs.Contracts.EmptyRef() And AccountingContract = Hotel.IndividualsContract)) Then
					vSrvRow = vServices.Add();
					vSrvRow.Document = vDoc;
					
					FillPropertyValues(vSrvRow, vDoc);
					FillPropertyValues(vSrvRow, vDocRow);
					
					vSrvRow.ParentDoc = vDoc;
					vSrvRow.Client = vDoc.Guest;
					vSrvRow.DateTimeFrom = vDoc.CheckInDate;
					vSrvRow.DateTimeTo = vDoc.CheckOutDate;
					If Not ValueIsFilled(vDoc.Room) Then
						vSrvRow.Room = vDoc.Number;
					EndIf;
					
					vSrvRow.Sum = vDocRow.Sum - vDocRow.DiscountSum;
					vSrvRow.VATSum = vDocRow.VATSum - vDocRow.VATDiscountSum;
					vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
					
					// Discounts
					vSrvRow.Discount = vDocRow.Discount;
					vSrvRow.DiscountSum = vDocRow.DiscountSum;
					
					// Commission
					vSrvRow.CommissionSum = 0;
					vSrvRow.VATCommissionSum = 0;
					vSrvRow.Agent = Undefined;
					If ValueIsFilled(vDocRow.Folio) Then
						vSrvRow.Agent = vDocRow.Folio.Agent;
					EndIf;
					vSrvRow.AgentCommissionType = vDocRow.AgentCommissionType;
					vSrvRow.AgentCommission = vDocRow.AgentCommission;
					If Not ValueIsFilled(vSrvRow.Agent) Or 
					   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
						vSrvRow.Agent = Undefined;
						vSrvRow.AgentCommissionType = Undefined;
						vSrvRow.AgentCommission = 0;
					EndIf;
					If vSrvRow.AgentCommission <> 0 Then
						// Check that current service fit to the commission service group
						If cmIsServiceInServiceGroup(vSrvRow.Service, vDoc.AgentCommissionServiceGroup) Then
							pmCalculateServiceCommissions(vDoc, vSrvRow);
						Else
							vSrvRow.Agent = Undefined;
							vSrvRow.AgentCommissionType = Undefined;
							vSrvRow.AgentCommission = 0;
						EndIf;
					EndIf;
					
					// Check base room type
					If ValueIsFilled(vSrvRow.RoomType) And ValueIsFilled(vDoc.RoomTypeUpgrade) And vDoc.RoomTypeUpgrade.BaseRoomType = vSrvRow.RoomType Then
						vSrvRow.RoomType = vDoc.RoomTypeUpgrade;
					EndIf;
					
					// Recalculate service according to the accounting currency
					pmRecalculateService(vSrvRow, vDocRow.FolioCurrency, vDocRow.FolioCurrencyExchangeRate);
					
					// Fill remarks by service description by default
					vServiceDescription = TrimAll(vSrvRow.Service);
					If ValueIsFilled(vSrvRow.Service) Then
						vServiceObj = vSrvRow.Service.GetObject();
						vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
					EndIf;
					vSrvRow.Remarks = vServiceDescription;
					
					// Clear accounting date if this is room rate service
					If vDocRow.IsManual Then
						vSrvRow.Remarks = cmNStr(TrimR(vSrvRow.Remarks), vLanguage) + ?(IsBlankString(vDocRow.Remarks), "", " - " + cmNStr(TrimAll(vDocRow.Remarks), vLanguage));
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		// Get charges from current reservation folios
		vCharges = cmGetDocumentCharges(vDoc, AccountingCustomer, AccountingContract, Hotel, Undefined);
		For Each vDocRow In vCharges Do
			vChargesToSkip.Add(vDocRow.Recorder);
			If Not vDocRow.IsAdditional Then
				Continue;
			EndIf;
			
			vParentDoc = Undefined;
			If ValueIsFilled(vDocRow.Recorder.ParentDoc) And TypeOf(vDocRow.Recorder.ParentDoc) = Type("DocumentRef.Reservation") Then
				vParentDoc = vDocRow.Recorder.ParentDoc;
			EndIf;
			
			If vDocRow.Company <> Company Then
				Continue;
			EndIf;
			
			vSrvRow = vServices.Add();
			
			FillPropertyValues(vSrvRow, vDoc);
			FillPropertyValues(vSrvRow, vDocRow);
			
			vSrvRow.ParentDoc = vParentDoc;
			
			If ValueIsFilled(vParentDoc) Then
				vSrvRow.Client = vParentDoc.Guest;
				vSrvRow.DateTimeFrom = vParentDoc.CheckInDate;
				vSrvRow.DateTimeTo = vParentDoc.CheckOutDate;
				If Not ValueIsFilled(vParentDoc.Room) Then
					vSrvRow.Room = vParentDoc.Number;
				Else
					vSrvRow.Room = vParentDoc.Room;
				EndIf;
			Else
				vSrvRow.Client = vDoc.Guest;
				vSrvRow.DateTimeFrom = vDoc.CheckInDate;
				vSrvRow.DateTimeTo = vDoc.CheckOutDate;
				If Not ValueIsFilled(vDoc.Room) Then
					vSrvRow.Room = vDoc.Number;
				Else
					vSrvRow.Room = vDoc.Room;
				EndIf;
			EndIf;
			
			// Discounts
			vSrvRow.Discount = vDocRow.Discount;
			vSrvRow.DiscountSum = vDocRow.DiscountSum;
			
			// Commission
			vSrvRow.CommissionSum = 0;
			vSrvRow.VATCommissionSum = 0;
			vSrvRow.Agent = Undefined;
			If ValueIsFilled(vDocRow.Folio) Then
				vSrvRow.Agent = vDocRow.Folio.Agent;
			EndIf;
			vSrvRow.AgentCommissionType = vDocRow.AgentCommissionType;
			vSrvRow.AgentCommission = vDocRow.AgentCommission;
			If Not ValueIsFilled(vSrvRow.Agent) Or 
			   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
				vSrvRow.Agent = Undefined;
				vSrvRow.AgentCommissionType = Undefined;
				vSrvRow.AgentCommission = 0;
			EndIf;
			If vSrvRow.AgentCommission <> 0 Then
				vSrvRow.CommissionSum = vDocRow.CommissionSum;
				vSrvRow.VATCommissionSum = vDocRow.VATCommissionSum;
			EndIf;
			
			// Check base room type
			If ValueIsFilled(vSrvRow.RoomType) And ValueIsFilled(vDoc.RoomTypeUpgrade) And vDoc.RoomTypeUpgrade.BaseRoomType = vSrvRow.RoomType Then
				vSrvRow.RoomType = vDoc.RoomTypeUpgrade;
			EndIf;
			
			// Recalculate service according to the accounting currency
			pmRecalculateService(vSrvRow, vDocRow.FolioCurrency, vDocRow.FolioCurrencyExchangeRate);
			
			// Fill remarks by service description by default
			vServiceDescription = TrimAll(vSrvRow.Service);
			If ValueIsFilled(vSrvRow.Service) Then
				vServiceObj = vSrvRow.Service.GetObject();
				vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
			EndIf;
			vSrvRow.Remarks = vServiceDescription + 
							  ?(IsBlankString(vSrvRow.Remarks), "", " - " + cmNStr(TrimAll(vSrvRow.Remarks), vLanguage));
		EndDo;
	EndDo;
	
	// Fill services for each accommodation in the list
	For Each vRow In vAccommodations Do
		vDoc = vRow.Accommodation;
		
		// Add services to the working table from the current document tabular part
		vIsActive = False;
		If ValueIsFilled(vRow.Status) Then
			vIsActive = vRow.Status.IsActive;
		EndIf;
		If vIsActive Then
			For Each vDocRow In vDoc.Services Do
				If vDocRow.Company <> Company Then
					Continue;
				EndIf;
				If ValueIsFilled(vDocRow.Folio) And
				   (vDocRow.Folio.Customer = AccountingCustomer Or (vDocRow.Folio.Customer = Catalogs.Customers.EmptyRef() And AccountingCustomer = Hotel.IndividualsCustomer)) And 
				   (vDocRow.Folio.Contract = AccountingContract Or (vDocRow.Folio.Contract = Catalogs.Contracts.EmptyRef() And AccountingContract = Hotel.IndividualsContract)) Then
					vSrvRow = vServices.Add();
					vSrvRow.Document = vDoc;
					
					FillPropertyValues(vSrvRow, vDoc);
					FillPropertyValues(vSrvRow, vDocRow);
					
					vSrvRow.ParentDoc = vDoc;
					vSrvRow.Client = vDoc.Guest;
					vSrvRow.DateTimeFrom = vDoc.CheckInDate;
					vSrvRow.DateTimeTo = vDoc.CheckOutDate;
					If Not ValueIsFilled(vDoc.Room) Then
						vSrvRow.Room = vDoc.Number;
					EndIf;
					
					vSrvRow.Sum = vDocRow.Sum - vDocRow.DiscountSum;
					vSrvRow.VATSum = vDocRow.VATSum - vDocRow.VATDiscountSum;
					vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
					
					// Discounts
					vSrvRow.Discount = vDocRow.Discount;
					vSrvRow.DiscountSum = vDocRow.DiscountSum;
					
					// Commission
					vSrvRow.CommissionSum = 0;
					vSrvRow.VATCommissionSum = 0;
					vSrvRow.Agent = Undefined;
					If ValueIsFilled(vDocRow.Folio) Then
						vSrvRow.Agent = vDocRow.Folio.Agent;
					EndIf;
					vSrvRow.AgentCommissionType = vDocRow.AgentCommissionType;
					vSrvRow.AgentCommission = vDocRow.AgentCommission;
					If Not ValueIsFilled(vSrvRow.Agent) Or 
					   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
						vSrvRow.Agent = Undefined;
						vSrvRow.AgentCommissionType = Undefined;
						vSrvRow.AgentCommission = 0;
					EndIf;
					If vSrvRow.AgentCommission <> 0 Then
						// Check that current service fit to the commission service group
						If cmIsServiceInServiceGroup(vSrvRow.Service, vDoc.AgentCommissionServiceGroup) Then
							pmCalculateServiceCommissions(vDoc, vSrvRow);
						Else
							vSrvRow.Agent = Undefined;
							vSrvRow.AgentCommissionType = Undefined;
							vSrvRow.AgentCommission = 0;
						EndIf;
					EndIf;
					
					// Check base room type
					If ValueIsFilled(vSrvRow.RoomType) And ValueIsFilled(vDoc.RoomTypeUpgrade) And vDoc.RoomTypeUpgrade.BaseRoomType = vSrvRow.RoomType Then
						vSrvRow.RoomType = vDoc.RoomTypeUpgrade;
					EndIf;
					
					// Recalculate service according to the accounting currency
					pmRecalculateService(vSrvRow, vDocRow.FolioCurrency, vDocRow.FolioCurrencyExchangeRate);
					
					// Fill remarks by service description by default
					vServiceDescription = TrimAll(vSrvRow.Service);
					If ValueIsFilled(vSrvRow.Service) Then
						vServiceObj = vSrvRow.Service.GetObject();
						vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
					EndIf;
					vSrvRow.Remarks = vServiceDescription;
					
					// Clear accounting date if this is room rate service
					If vDocRow.IsManual Then
						vSrvRow.Remarks = cmNStr(TrimR(vSrvRow.Remarks), vLanguage) + ?(IsBlankString(vDocRow.Remarks), "", " - " + cmNStr(TrimAll(vDocRow.Remarks), vLanguage));
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		// Get charges from current accommodation folios
		vCharges = cmGetDocumentCharges(vDoc, AccountingCustomer, AccountingContract, Hotel, Undefined);
		For Each vDocRow In vCharges Do
			vChargesToSkip.Add(vDocRow.Recorder);
			If Not vDocRow.IsAdditional Then
				Continue;
			EndIf;
			
			vParentDoc = Undefined;
			If ValueIsFilled(vDocRow.Recorder.ParentDoc) And TypeOf(vDocRow.Recorder.ParentDoc) = Type("DocumentRef.Accommodation") Then
				vParentDoc = vDocRow.Recorder.ParentDoc;
			EndIf;
			
			If vDocRow.Company <> Company Then
				Continue;
			EndIf;
			
			vSrvRow = vServices.Add();
			
			FillPropertyValues(vSrvRow, vDoc);
			FillPropertyValues(vSrvRow, vDocRow);
			
			vSrvRow.ParentDoc = vParentDoc;
			
			If ValueIsFilled(vParentDoc) Then
				vSrvRow.Client = vParentDoc.Guest;
				vSrvRow.DateTimeFrom = vParentDoc.CheckInDate;
				vSrvRow.DateTimeTo = vParentDoc.CheckOutDate;
				vSrvRow.Room = vParentDoc.Room;
			Else
				vSrvRow.Client = vDoc.Guest;
				vSrvRow.DateTimeFrom = vDoc.CheckInDate;
				vSrvRow.DateTimeTo = vDoc.CheckOutDate;
				vSrvRow.Room = vDoc.Room;
			EndIf;
			
			// Discounts
			vSrvRow.Discount = vDocRow.Discount;
			vSrvRow.DiscountSum = vDocRow.DiscountSum;
			
			// Commission
			vSrvRow.CommissionSum = 0;
			vSrvRow.VATCommissionSum = 0;
			vSrvRow.Agent = Undefined;
			If ValueIsFilled(vDocRow.Folio) Then
				vSrvRow.Agent = vDocRow.Folio.Agent;
			EndIf;
			vSrvRow.AgentCommissionType = vDocRow.AgentCommissionType;
			vSrvRow.AgentCommission = vDocRow.AgentCommission;
			If Not ValueIsFilled(vSrvRow.Agent) Or 
			   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
				vSrvRow.Agent = Undefined;
				vSrvRow.AgentCommissionType = Undefined;
				vSrvRow.AgentCommission = 0;
			EndIf;
			If vSrvRow.AgentCommission <> 0 Then
				vSrvRow.CommissionSum = vDocRow.CommissionSum;
				vSrvRow.VATCommissionSum = vDocRow.VATCommissionSum;
			EndIf;
					
			// Check base room type
			If ValueIsFilled(vSrvRow.RoomType) And ValueIsFilled(vDoc.RoomTypeUpgrade) And vDoc.RoomTypeUpgrade.BaseRoomType = vSrvRow.RoomType Then
				vSrvRow.RoomType = vDoc.RoomTypeUpgrade;
			EndIf;
			
			// Recalculate service according to the accounting currency
			pmRecalculateService(vSrvRow, vDocRow.FolioCurrency, vDocRow.FolioCurrencyExchangeRate);
			
			// Fill remarks by service description by default
			vServiceDescription = TrimAll(vSrvRow.Service);
			If ValueIsFilled(vSrvRow.Service) Then
				vServiceObj = vSrvRow.Service.GetObject();
				vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
			EndIf;
			vSrvRow.Remarks = vServiceDescription + 
							  ?(IsBlankString(vSrvRow.Remarks), "", " - " + cmNStr(TrimAll(vSrvRow.Remarks), vLanguage));
		EndDo;
	EndDo;
	
	// Fill services for each resource reservation in the list
	For Each vRow In vResourceReservations Do
		vDoc = vRow.Reservation;
		
		// Add services to the working table from the current document tabular part
		If vDoc.Posted And ValueIsFilled(vRow.Status) And vRow.Status.IsActive Then
			For Each vDocRow In vDoc.Services Do
				If vDocRow.Company <> Company Then
					Continue;
				EndIf;
				If vDoc.DoCharging Then
					If ValueIsFilled(vDocRow.Service) And ValueIsFilled(vDocRow.Service.ServiceType) And vDocRow.Service.ServiceType.ActualAmountIsChargedExternally Then
						Continue;
					EndIf;
				EndIf;
				If ValueIsFilled(vDoc.ChargingFolio) And
				   (vDoc.ChargingFolio.Customer = AccountingCustomer Or (vDoc.ChargingFolio.Customer = Catalogs.Customers.EmptyRef() And AccountingCustomer = Hotel.IndividualsCustomer)) And 
				   (vDoc.ChargingFolio.Contract = AccountingContract Or (vDoc.ChargingFolio.Contract = Catalogs.Contracts.EmptyRef() And AccountingContract = Hotel.IndividualsContract)) Then
					vSrvRow = vServices.Add();
					vSrvRow.Document = vDoc;
					
					FillPropertyValues(vSrvRow, vDoc);
					FillPropertyValues(vSrvRow, vDocRow);

					vSrvRow.ParentDoc = vDoc;
					
					vSrvRow.Sum = vDocRow.Sum - vDocRow.DiscountSum;
					vSrvRow.VATSum = vDocRow.VATSum - vDocRow.VATDiscountSum;
					vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
					
					// Discounts
					vSrvRow.Discount = vDocRow.Discount;
					vSrvRow.DiscountSum = vDocRow.DiscountSum;
					
					// Commission
					vSrvRow.CommissionSum = 0;
					vSrvRow.VATCommissionSum = 0;
					vSrvRow.Agent = Undefined;
					If ValueIsFilled(vDoc.ChargingFolio) Then
						vSrvRow.Agent = vDoc.ChargingFolio.Agent;
					EndIf;
					vSrvRow.AgentCommissionType = vDocRow.AgentCommissionType;
					vSrvRow.AgentCommission = vDocRow.AgentCommission;
					If Not ValueIsFilled(vSrvRow.Agent) Or 
					   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
						vSrvRow.Agent = Undefined;
						vSrvRow.AgentCommissionType = Undefined;
						vSrvRow.AgentCommission = 0;
					EndIf;
					If vSrvRow.AgentCommission <> 0 Then
						// Check that current service fit to the commission service group
						If cmIsServiceInServiceGroup(vSrvRow.Service, vDoc.AgentCommissionServiceGroup) Then
							pmCalculateServiceCommissions(vDoc, vSrvRow);
						Else
							vSrvRow.Agent = Undefined;
							vSrvRow.AgentCommissionType = Undefined;
							vSrvRow.AgentCommission = 0;
						EndIf;
					EndIf;
					
					// Recalculate service according to the accounting currency
					pmRecalculateService(vSrvRow, vDoc.FolioCurrency, vDoc.FolioCurrencyExchangeRate);
					
					// Fill remarks by service description by default
					vServiceDescription = TrimAll(vSrvRow.Service);
					If ValueIsFilled(vSrvRow.Service) Then
						vServiceObj = vSrvRow.Service.GetObject();
						vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
					EndIf;
					vSrvRow.Remarks = vServiceDescription;
					
					// Clear accounting date if this is room rate service
					If vDocRow.IsManual Then
						vSrvRow.Remarks = cmNStr(TrimR(vSrvRow.Remarks), vLanguage) + ?(IsBlankString(vDocRow.Remarks), "", " - " + cmNStr(TrimAll(vDocRow.Remarks), vLanguage));
					EndIf;
				EndIf;
			EndDo;
			
			// Get charges from current resource reservation folios
			vCharges = cmGetDocumentCharges(vDoc, AccountingCustomer, AccountingContract, Hotel, Undefined);
			For Each vDocRow In vCharges Do
				vChargesToSkip.Add(vDocRow.Recorder);
				If Not vDocRow.IsAdditional Then
					Continue;
				EndIf;
				
				If vDocRow.Company <> Company Then
					Continue;
				EndIf;
				
				vSrvRow = vServices.Add();
				
				FillPropertyValues(vSrvRow, vDoc);
				FillPropertyValues(vSrvRow, vDocRow);
			
				vSrvRow.ParentDoc = vDoc;
				
				// Discounts
				vSrvRow.Discount = vDocRow.Discount;
				vSrvRow.DiscountSum = vDocRow.DiscountSum;
				
				// Commission
				vSrvRow.CommissionSum = 0;
				vSrvRow.VATCommissionSum = 0;
				vSrvRow.Agent = Undefined;
				If ValueIsFilled(vDocRow.Folio) Then
					vSrvRow.Agent = vDocRow.Folio.Agent;
				EndIf;
				vSrvRow.AgentCommissionType = vDocRow.AgentCommissionType;
				vSrvRow.AgentCommission = vDocRow.AgentCommission;
				If Not ValueIsFilled(vSrvRow.Agent) Or 
				   ValueIsFilled(vSrvRow.Agent) And vSrvRow.Agent <> AccountingCustomer Then
					vSrvRow.Agent = Undefined;
					vSrvRow.AgentCommissionType = Undefined;
					vSrvRow.AgentCommission = 0;
				EndIf;
				If vSrvRow.AgentCommission <> 0 Then
					vSrvRow.CommissionSum = vDocRow.CommissionSum;
					vSrvRow.VATCommissionSum = vDocRow.VATCommissionSum;
				EndIf;
				
				// Recalculate service according to the accounting currency
				pmRecalculateService(vSrvRow, vDoc.FolioCurrency, vDoc.FolioCurrencyExchangeRate);
				
				// Fill remarks by service description by default
				vServiceDescription = TrimAll(vSrvRow.Service);
				If ValueIsFilled(vSrvRow.Service) Then
					vServiceObj = vSrvRow.Service.GetObject();
					vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
				EndIf;
				vSrvRow.Remarks = vServiceDescription + 
								  ?(IsBlankString(vSrvRow.Remarks), "", " - " + cmNStr(TrimAll(vSrvRow.Remarks), vLanguage));
			EndDo;
		EndIf;
	EndDo;
	
	// Load resulting value table to the invoice services
	If pDoNotClearServices Then
		For Each vServicesRow In vServices Do
			vSrvRow = Services.Add();
			FillPropertyValues(vSrvRow, vServicesRow);
		EndDo;
	Else
		Services.Load(vServices);
	EndIf;
	
	// Get all customer current accounts receivable services with balances per end of time
	vOtherCharges = cmGetCurrentAccountsReceivableChargesWithBalances('39991231235959', AccountingCustomer, AccountingContract, Undefined, GuestGroup, AccountingCurrency, Hotel, vChargesToSkip, , True);
	
	// Fill services tabular part
	pmFillServices(vOtherCharges, vLanguage);
	
	// Fill with prepaiment service in some modes
	ConvertToPrepaimentModeIfNecessary(pDetailed);
	
	// Fill totals
	If ValueIsFilled(AccountingCustomer) And AccountingCustomer.DoNotPostCommission Then
		Sum = Services.Total("Sum");
		VATSum = Services.Total("VATSum");
	Else
		Sum = Services.Total("Sum") - Services.Total("CommissionSum");
		VATSum = Services.Total("VATSum") - Services.Total("VATCommissionSum");
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
EndProcedure // pmFillByGuestGroup

// -----------------------------------------------------------------------------
Procedure pmCalculateServiceCommissions(pDoc, pSrvRow) Export
	If pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
		pSrvRow.CommissionSum = Round(pSrvRow.Sum * pSrvRow.AgentCommission / 100, 2);
		pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
	ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
		If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
			If BegOfDay(pDoc.CheckInDate) = BegOfDay(pSrvRow.AccountingDate) Then
				pSrvRow.CommissionSum = Round(pSrvRow.Sum * pSrvRow.AgentCommission / 100, 2);
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			EndIf;
		ElsIf TypeOf(pDoc) = Type("DocumentRef.ResourceReservation") Then
			If BegOfDay(pDoc.DateTimeFrom) = BegOfDay(pSrvRow.AccountingDate) Then
				pSrvRow.CommissionSum = Round(pSrvRow.Sum * pSrvRow.AgentCommission / 100, 2);
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			EndIf;
		EndIf;
	ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom Then
		If ValueIsFilled(pDoc) And (pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice Or pSrvRow.IsResourceRevenue) Then
			vAgentCurrency = AccountingCurrency;
			If ValueIsFilled(pDoc.Contract) And ValueIsFilled(pDoc.Contract.AgentCommissionType) Then
				vAgentCurrency = pDoc.Contract.AccountingCurrency;
			ElsIf ValueIsFilled(pDoc.Agent) Then
				vAgentCurrency = pDoc.Agent.AccountingCurrency;
			EndIf;
			If (TypeOf(pDoc) = Type("DocumentRef.Reservation") Or TypeOf(pDoc) = Type("DocumentRef.Accommodation")) And 
			   BegOfDay(pDoc.CheckInDate) = BegOfDay(pSrvRow.AccountingDate) And 
			   ValueIsFilled(pDoc.AccommodationType) And (pDoc.AccommodationType.Type = Enums.AccomodationTypes.Room Or pDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
				pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , AccountingCurrency, AccountingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			ElsIf TypeOf(pDoc) = Type("DocumentRef.ResourceReservation") And BegOfDay(pDoc.DateTimeFrom) = BegOfDay(pSrvRow.AccountingDate) Then
				pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , AccountingCurrency, AccountingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			EndIf;
		EndIf;
	ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom Then
		If pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice Or pSrvRow.IsResourceRevenue Then
			vAgentCurrency = AccountingCurrency;
			If ValueIsFilled(pDoc.Contract) And ValueIsFilled(pDoc.Contract.AgentCommissionType) Then
				vAgentCurrency = pDoc.Contract.AccountingCurrency;
			ElsIf ValueIsFilled(pDoc.Agent) Then
				vAgentCurrency = pDoc.Agent.AccountingCurrency;
			EndIf;
			If (TypeOf(pDoc) = Type("DocumentRef.Reservation") Or TypeOf(pDoc) = Type("DocumentRef.Accommodation")) And 
			   ValueIsFilled(pDoc.AccommodationType) And (pDoc.AccommodationType.Type = Enums.AccomodationTypes.Room Or pDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
				pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , AccountingCurrency, AccountingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2) * pSrvRow.Quantity;
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			Else
				pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , AccountingCurrency, AccountingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2) * pSrvRow.Quantity;
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			EndIf;
		EndIf;
	ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient Then
		If ValueIsFilled(pDoc) And (pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice Or pSrvRow.IsResourceRevenue) Then
			vAgentCurrency = AccountingCurrency;
			If ValueIsFilled(pDoc.Contract) And ValueIsFilled(pDoc.Contract.AgentCommissionType) Then
				vAgentCurrency = pDoc.Contract.AccountingCurrency;
			ElsIf ValueIsFilled(pDoc.Agent) Then
				vAgentCurrency = pDoc.Agent.AccountingCurrency;
			EndIf;
			If (TypeOf(pDoc) = Type("DocumentRef.Reservation") Or TypeOf(pDoc) = Type("DocumentRef.Accommodation")) And 
			   BegOfDay(pDoc.CheckInDate) = BegOfDay(pSrvRow.AccountingDate) Then 
				pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , AccountingCurrency, AccountingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			ElsIf TypeOf(pDoc) = Type("DocumentRef.ResourceReservation") And BegOfDay(pDoc.DateTimeFrom) = BegOfDay(pSrvRow.AccountingDate) Then
				pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , AccountingCurrency, AccountingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			EndIf;
		EndIf;
	ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient Then
		If pSrvRow.IsRoomRevenue And pSrvRow.IsInPrice Or pSrvRow.IsResourceRevenue Then
			vAgentCurrency = AccountingCurrency;
			If ValueIsFilled(pDoc.Contract) And ValueIsFilled(pDoc.Contract.AgentCommissionType) Then
				vAgentCurrency = pDoc.Contract.AccountingCurrency;
			ElsIf ValueIsFilled(pDoc.Agent) Then
				vAgentCurrency = pDoc.Agent.AccountingCurrency;
			EndIf;
			pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , AccountingCurrency, AccountingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2) * pSrvRow.Quantity;
			pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
		EndIf;
	EndIf;
EndProcedure // CalculateServiceCommissions

// -----------------------------------------------------------------------------
Procedure pmFillByEvent(pEvent) Export
	If Not ValueIsFilled(pEvent) Then
		Return;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get list of event guest groups
	vGuestGroups = pEvent.GetObject().pmGetEventGuestGroups(Hotel);
	For Each vGuestGroupsRow In vGuestGroups Do
		pmFillByGuestGroup(vGuestGroupsRow.Ref, True);
	EndDo;
	
	// Clear guest group
	GuestGroup = Undefined;
	
	// Fill remarks
	Remarks = cmNStr("en='Event: '; ru='Мероприятие: '; de='Veranstaltung: '", vLanguage) + TrimAll(pEvent);
EndProcedure // pmFillByEvent

// -----------------------------------------------------------------------------
Procedure pmFillByAllotment(pAllotment) Export
	If Not ValueIsFilled(pAllotment) Then
		Return;
	EndIf;
	
	RoomQuota = pAllotment;
	
	If ValueIsFilled(pAllotment.Customer) Then
		AccountingCustomer = pAllotment.Customer;
		AccountingContract = pAllotment.Contract;
	ElsIf ValueIsFilled(Hotel) Then
		AccountingCustomer = Hotel.IndividualsCustomer;
		AccountingContract = Hotel.IndividualsContract;
	EndIf;
	If ValueIsFilled(pAllotment.Company) Then
		Company = pAllotment.Company;
	EndIf;
	
	// Clear guest group
	GuestGroup = Undefined;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;

	If Not ValueIsFilled(FillProformaInvoiceMode) Then
		FillProformaInvoiceMode = Hotel.FillProformaInvoiceMode;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// Clear tabular part Services
	Services.Clear();

	// Get room rate
	vService = Undefined;
	vRH = 0;
	vVATRate = Undefined;
	vRoomRate = ?(ValueIsFilled(RoomQuota.RoomRate), RoomQuota.RoomRate, Hotel.RoomRate);
	If ValueIsFilled(vRoomRate) Then
		vRH = vRoomRate.ReferenceHour - BegOfDay(vRoomRate.ReferenceHour);
		vService = cmGetRoomRateService(Hotel, vRoomRate, RoomQuota.ClientType, Undefined, RoomQuota.PeriodFrom, vVATRate);
	EndIf;
	If Not ValueIsFilled(vVATRate) Then
		vVATRate = Company.VATRate;
	EndIf;
	vMICEService = GetMICEService();

	If RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
		// Fill invoice according to the business block budget
		If RoomQuota.BudgetReservationAmount > 0 Then
			vSrvRow = Services.Add();
			If ValueIsFilled(vService) Then
				vSrvRow.Service = vService;
				vSrvObj = vService.GetObject();
				vSrvRow.Remarks = vSrvObj.pmGetServiceDescription(vLanguage, True);
				vSrvRow.Unit = vSrvObj.pmGetServiceUnitDescription(vLanguage);
			Else
				vSrvRow.Remarks = cmNStr("en='Accommodation'; ru='Проживание'; de='Aufenthalt'", vLanguage);
				vSrvRow.Unit = cmNStr("en='room night'; ru='номеродней'; de='Zimmertage'", vLanguage);
			EndIf;
			vSrvRow.VATRate = vVATRate;
			vSrvRow.DateTimeFrom = RoomQuota.PeriodFrom + vRH;
			vSrvRow.DateTimeTo = ?(vRH = 0, EndOfDay(RoomQuota.PeriodTo), RoomQuota.PeriodTo + vRH);
			vSrvRow.IsRoomRevenue = True;
			vSrvRow.IsInPrice = True;
			vSrvRow.NumberOfPersons = 0;
			vSrvRow.Sum = Round(cmConvertCurrencies(RoomQuota.BudgetReservationAmount, RoomQuota.BudgetCurrency, , AccountingCurrency, , ExchangeRateDate, Hotel), 2);
			vSrvRow.Quantity = ?(RoomQuota.RoomNights = 0, 1, RoomQuota.RoomNights);
			vSrvRow.Price = Round(vSrvRow.Sum / vSrvRow.Quantity, 2);
			vSrvRow.RoomQuantity = RoomQuota.RoomNights;
			vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, Date);
		EndIf;
		If RoomQuota.BudgetMICEAmount > 0 Then
			vSrvRow = Services.Add();
			If ValueIsFilled(vMICEService) Then
				vSrvRow.Service = vMICEService;
				vSrvObj = vMICEService.GetObject();
				vSrvRow.Remarks = vSrvObj.pmGetServiceDescription(vLanguage, True);
				vSrvRow.Unit = vSrvObj.pmGetServiceUnitDescription(vLanguage);
				vSrvPrices = vSrvObj.pmGetServicePrices(Hotel, Date, RoomQuota.ClientType);
				If vSrvPrices.Count() > 0 Then
					vSrvRow.VATRate = vSrvPrices.Get(0).VATRate;
				Else
					vSrvRow.VATRate = vVATRate;
				EndIf;
			Else
				vSrvRow.Remarks = cmNStr("en='MICE services'; ru='Услуги MICE'; de='MICE'", vLanguage);
				vSrvRow.VATRate = vVATRate;
			EndIf;
			vSrvRow.DateTimeFrom = RoomQuota.PeriodFrom;
			vSrvRow.DateTimeTo = EndOfDay(RoomQuota.PeriodTo);
			vSrvRow.Sum = Round(cmConvertCurrencies(RoomQuota.BudgetMICEAmount, RoomQuota.BudgetCurrency, , AccountingCurrency, , ExchangeRateDate, Hotel), 2);
			vSrvRow.Quantity = 1;
			vSrvRow.Price = vSrvRow.Sum;
			vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, Date);
		EndIf;
		
		// Fill remarks
		Remarks = cmNStr("en='Business block: '; ru='Бизнес-блок: '; de='Geschäftsblock: '", vLanguage) + TrimAll(RoomQuota);
	Else 
		// For allotments use initial availability and prices
		For Each vRTRow In RoomQuota.RoomTypes Do
			If Not vRTRow.IsPriceSetting And vRTRow.RoomQuantity <> 0 Then
				For Each vPriceRow In RoomQuota.RoomTypes Do
					If ValueIsFilled(vPriceRow.Currency) And vPriceRow.Price <> 0 Then
						If vRTRow.RoomType = vPriceRow.RoomType And vRTRow.PeriodFrom < vPriceRow.PeriodTo And vRTRow.PeriodTo > vPriceRow.PeriodFrom Then
							vSrvRow = Services.Add();
							vSrvRow.Service = vService;
							If ValueIsFilled(vService) Then
								vSrvObj = vSrvRow.Service.GetObject();
								vSrvRow.Remarks = vSrvObj.pmGetServiceDescription(vLanguage, True);
								vSrvRow.Unit = vSrvObj.pmGetServiceUnitDescription(vLanguage);
							Else
								vSrvRow.Remarks = cmNStr("en='Accommodation'; ru='Проживание'; de='Aufenthalt'", vLanguage);
								vSrvRow.Unit = cmNStr("en='room night'; ru='номеродней'; de='Zimmertage'", vLanguage);
							EndIf;
							vSrvRow.VATRate = vVATRate;
							vSrvRow.DateTimeFrom = vRTRow.PeriodFrom;
							vSrvRow.DateTimeTo = vRTRow.PeriodTo;
							vSrvRow.IsRoomRevenue = True;
							vSrvRow.IsInPrice = True;
							vSrvRow.NumberOfPersons = vRTRow.NumberOfPersons;
							vSrvRow.Price = cmConvertCurrencies(vPriceRow.Price, vPriceRow.Currency, , AccountingCurrency, , ExchangeRateDate, Hotel);
							vSrvRow.Quantity = (BegOfDay(vSrvRow.DateTimeTo) - BegOfDay(vSrvRow.DateTimeFrom))/(24*3600) * vRTRow.RoomQuantity;
							vSrvRow.Sum = Round(vSrvRow.Price * vSrvRow.Quantity, 2);
							vSrvRow.RoomQuantity = vRTRow.RoomQuantity;
							vSrvRow.RoomType = vRTRow.RoomType;
							vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, Date);
							Break;
						Endif;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		// Fill remarks
		Remarks = cmNStr("en='Allotment: '; ru='Квота: '; de='Allotment: '", vLanguage) + TrimAll(RoomQuota);
	EndIf;
	
	Sum = Services.Total("Sum");
	VATSum = Services.Total("VATSum");
EndProcedure // pmFillByAllotment

// -----------------------------------------------------------------------------
Function GetMICEService()
	vMICEService = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Services.Ref AS Ref
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	NOT Services.DeletionMark
	|	AND NOT Services.IsFolder
	|	AND (Services.IsResourceRevenue
	|			OR Services.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Conference))
	|	AND (Services.Hotel = &qHotel
	|			OR Services.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|
	|ORDER BY
	|	Services.SortCode,
	|	Services.Code";
	vQry.SetParameter("qHotel", Hotel);
	vServices = vQry.Execute().Unload();
	For Each vServicesRow In vServices Do
		vMICEService = vServicesRow.Ref;
		Break;
	EndDo;
	Return vMICEService;
EndFunction // GetMICEService

// -----------------------------------------------------------------------------
Procedure pmFillByCustomer(pCustomer) Export
	If Not ValueIsFilled(pCustomer) Then
		Return;
	EndIf;
	
	// Accounting customer
	AccountingCustomer = pCustomer;
	If ValueIsFilled(AccountingCustomer.Contract) Then
		AccountingContract = AccountingCustomer.Contract;
	EndIf;
	
	// Fill currency
	If ValueIsFilled(AccountingContract) Then
		AccountingCurrency = AccountingContract.AccountingCurrency;
		AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	Else
		If ValueIsFilled(AccountingCustomer) Then
			AccountingCurrency = AccountingCustomer.AccountingCurrency;
			AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
		EndIf;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get all customer current accounts receivable services with balances per end of time
	vCharges = cmGetCurrentAccountsReceivableChargesWithBalances('39991231235959', AccountingCustomer, , ParentDoc, GuestGroup, AccountingCurrency, Hotel);
	
	// Fill services tabular part
	pmFillServices(vCharges, vLanguage);
	
	// Fill totals
	If ValueIsFilled(AccountingCustomer) And AccountingCustomer.DoNotPostCommission Then
		Sum = Services.Total("Sum");
		VATSum = Services.Total("VATSum");
	Else
		Sum = Services.Total("Sum") - Services.Total("CommissionSum");
		VATSum = Services.Total("VATSum") - Services.Total("VATCommissionSum");
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
EndProcedure // pmFillByCustomer

// -----------------------------------------------------------------------------
Procedure pmFillByContract(pContract) Export
	If Not ValueIsFilled(pContract) Then
		Return;
	EndIf;
	
	// Accounting customer and contract
	AccountingContract = pContract;
	AccountingCustomer = pContract.Owner;
	
	// Fill currency
	If ValueIsFilled(AccountingContract) Then
		AccountingCurrency = AccountingContract.AccountingCurrency;
		AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
	Else
		If ValueIsFilled(AccountingCustomer) Then
			AccountingCurrency = AccountingCustomer.AccountingCurrency;
			AccountingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, AccountingCurrency, ExchangeRateDate);
		EndIf;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get all contract current accounts receivable services with balances per end of time
	vCharges = cmGetCurrentAccountsReceivableChargesWithBalances('39991231235959', AccountingCustomer, AccountingContract, ParentDoc, GuestGroup, AccountingCurrency, Hotel);
	
	// Fill services tabular part
	pmFillServices(vCharges, vLanguage);
	
	// Fill totals
	If ValueIsFilled(AccountingCustomer) And AccountingCustomer.DoNotPostCommission Then
		Sum = Services.Total("Sum");
		VATSum = Services.Total("VATSum");
	Else
		Sum = Services.Total("Sum") - Services.Total("CommissionSum");
		VATSum = Services.Total("VATSum") - Services.Total("VATCommissionSum");
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
EndProcedure // pmFillByContract

// -----------------------------------------------------------------------------
Function pmGetInvoiceBalance(Val pDate = Undefined) Export
	vBalance = 0;
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	InvoiceAccountsBalance.Company,
	|	InvoiceAccountsBalance.Invoice,
	|	InvoiceAccountsBalance.Hotel,
	|	InvoiceAccountsBalance.SumBalance AS Balance
	|FROM
	|	AccumulationRegister.InvoiceAccounts.Balance(
	|		&qPeriod,
	|		Invoice = &qInvoice) AS InvoiceAccountsBalance";
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qInvoice", Ref);
	vRes = vQry.Execute().Unload();
	For Each vRow In vRes Do
		vBalance = vBalance + vRow.Balance;
	EndDo;
	Return vBalance;
EndFunction // pmGetInvoiceBalance

// -----------------------------------------------------------------------------
Function pmGetDepositBalance(Val pDate = Undefined) Export
	vBalance = 0;
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerDepositsBalance.ProformaInvoice AS Invoice,
	|	CustomerDepositsBalance.AccountingCurrency,
	|	CustomerDepositsBalance.SumBalance AS Balance
	|FROM
	|	AccumulationRegister.CustomerDeposits.Balance(
	|		&qPeriod,
	|		ProformaInvoice = &qProformaInvoice) AS CustomerDepositsBalance";
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qProformaInvoice", Ref);
	vRes = vQry.Execute().Unload();
	For Each vRow In vRes Do
		vBalance = vBalance + vRow.Balance;
	EndDo;
	Return vBalance;
EndFunction // pmGetDepositBalance

// -----------------------------------------------------------------------------
Procedure pmPrintInvoice(vSpreadsheet, SelLanguage, SelGroupBy, SelObjectPrintForm, mInvoiceNumber, pClear = True) Export
	SelInvoice = ThisObject;
	If IsBlankString(SelGroupBy) And ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		SelGroupBy = TrimAll(SelObjectPrintForm.Parameter);
	EndIf;
	// Basic checks
	vHotel = SelInvoice.Hotel;
	If Not ValueIsFilled(vHotel) Then
		Raise NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'");
	EndIf;
	vCompany = SelInvoice.Company;
	If Not ValueIsFilled(vCompany) Then
		Raise NStr("ru='Не задана фирма!';de='Die Firma ist nicht angegeben!';en='Company should be filled!'");
	EndIf;
	vAccount = SelInvoice.BankAccount;
	If Not ValueIsFilled(vAccount) Then
		vAccount = vCompany.BankAccount;
	EndIf;
	If Not ValueIsFilled(vAccount) Then
		Raise NStr("ru='Не задан расчетный счет фирмы!';de='Das Verrechnungskonto der Firma ist nicht angegeben!';en='Company account should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) AND ValueIsFilled(SelInvoice.AccountingCustomer) Then
		SelLanguage = SelInvoice.AccountingCustomer.Language;
	EndIf;	
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	If pClear Then
		vSpreadsheet.Clear();
	EndIf;
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = SelInvoice.GetTemplate("InvoiceDetailedEn");
			If Not IsBlankString(SelGroupBy) Then
				If SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Or SelGroupBy = "PerClient" Or SelGroupBy = "ByService" Then
					vTemplate = SelInvoice.GetTemplate("InvoiceShortEn");
				EndIf;
			EndIf;
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplate = SelInvoice.GetTemplate("InvoiceDetailedDe");
			If Not IsBlankString(SelGroupBy) Then
				If SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Or SelGroupBy = "PerClient" Or SelGroupBy = "ByService" Then
					vTemplate = SelInvoice.GetTemplate("InvoiceShortDe");
				EndIf;
			EndIf;
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = SelInvoice.GetTemplate("InvoiceDetailedRu");
			If Not IsBlankString(SelGroupBy) Then
				If SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Or SelGroupBy = "PerClient" Or SelGroupBy = "ByService" Then
					vTemplate = SelInvoice.GetTemplate("InvoiceShortRu");
				EndIf;
			EndIf;
		Else
			Raise NStr("ru='Не найден шаблон печатной формы счета для языка " + SelLanguage.Code + "!'; 
			           |de='No invoice print form template found for the " + SelLanguage.Code + " language!'; 
			           |en='No invoice print form template found for the " + SelLanguage.Code + " language!'");
		EndIf;
	Else
		vTemplate = SelInvoice.GetTemplate("InvoiceDetailedRu");
		If Not IsBlankString(SelGroupBy) Then
			If SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Or SelGroupBy = "PerClient" Or SelGroupBy = "ByService" Then
				vTemplate = SelInvoice.GetTemplate("InvoiceShortRu");
			EndIf;
		EndIf;
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Print form parameter
	vParameter = Upper(TrimAll(SelObjectPrintForm.Parameter));
	vShowDiscounts = (Find(vParameter, "SHOW_DISCOUNT") > 0);
	vDoNotUseSectionVAT = (Find(vParameter, "DO_NOT_USE_SECTION_VAT") > 0);
	vPrintQRCode = (Find(vParameter, "SHOW_QRCODE") > 0);
	vIgnoreVATRate = (Find(vParameter, "IGNORE_VATRATE_ON_GROUPING") > 0);
	vDoNotShowPayDueDate = (Find(vParameter, "DO_NOT_SHOW_PAY_DUE_DATE") > 0);
	
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(SelInvoice.Hotel) Then
		If SelInvoice.Hotel.Logo <> Undefined Then
			vLogo = SelInvoice.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vStampIsSet = False;
	vStamp = New Picture;
	If ValueIsFilled(SelInvoice.Company) Then
		If SelInvoice.Company.Stamp <> Undefined Then
			vStamp = SelInvoice.Company.Stamp.Get();
			If vStamp = Undefined Then
				vStamp = New Picture;
			Else
				vStampIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vSignatureIsSet = False;
	vSignature = New Picture;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If SessionParameters.CurrentUser.Signature <> Undefined Then
			vSignature = SessionParameters.CurrentUser.Signature.Get();
			If vSignature = Undefined Then
				vSignature = New Picture;
			Else
				vSignatureIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vDirectorSignatureIsSet = False;
	vDirectorSignature = New Picture;
	If SelInvoice.Company.DirectorSignature <> Undefined Then
		vDirectorSignature = SelInvoice.Company.DirectorSignature.Get();
		If vDirectorSignature = Undefined Then
			vDirectorSignature = New Picture;
		Else
			vDirectorSignatureIsSet = True;
		EndIf;
	EndIf;
	vAccountantGeneralSignatureIsSet = False;
	vAccountantGeneralSignature = New Picture;
	If SelInvoice.Company.AccountantGeneralSignature <> Undefined Then
		vAccountantGeneralSignature = SelInvoice.Company.AccountantGeneralSignature.Get();
		If vAccountantGeneralSignature = Undefined Then
			vAccountantGeneralSignature = New Picture;
		Else
			vAccountantGeneralSignatureIsSet = True;
		EndIf;
	EndIf;
	
	// Header
	vRubHeader = False;
	If SelInvoice.AccountingCurrency.Code = 643 And vHotel.Citizenship.Code = 643 Then
		vRubHeader = True;
	EndIf;
	
	// Hotel
	mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, SelLanguage);
	mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, SelLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vHotelFax);
	mHotelEMail = TrimAll(vHotel.EMail);
	
	// Company
	vCompanyObj = vCompany.GetObject();
	vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
	vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
	vCompanyPostAddress = vCompanyObj.pmGetCompanyPostAddressPresentation(SelLanguage);
	If vCompanyPostAddress = vCompanyLegacyAddress Then
		vCompanyPostAddress = "";
	EndIf;
	mCompanyTIN = TrimAll(vCompany.TIN);
	mCompanyVATCode = TrimAll(vCompany.VATC);
	mCompanyKPP = TrimAll(vCompany.KPP);
	mCompanyCBC = TrimAll(vCompany.KBK);
	mCompanyOKTMO = TrimAll(vCompany.OKTMO);
	vCompanyTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН ';lv=', Reg. N '", SelLanguage) + ?(IsBlankString(mCompanyKPP), " ", "/" + cmNStr("en='KPP ';de='KPP ';ru='КПП '", SelLanguage)) + mCompanyTIN + ?(IsBlankString(mCompanyKPP), "", "/" + mCompanyKPP) + 
	              ?(IsBlankString(mCompanyVATCode), "", cmNStr("en=', VAT code ';de=', Mw.St. code ';ru=', код НДС ';lv=', PVN '", SelLanguage) + mCompanyVATCode);
	vCompanyPhones = TrimAll(vCompany.Phones) + ?(IsBlankString(vCompany.Fax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + TrimAll(vCompany.Fax));
	mCompany = TrimAll(vCompanyLegacyName + vCompanyTIN + Chars.LF + vCompanyLegacyAddress + Chars.LF + ?(IsBlankString(vCompanyPostAddress), "", vCompanyPostAddress + Chars.LF) + vCompanyPhones);
	
	// Invoice date and number
	If vCompany.UseGroupCodeAsInvoiceNumberPrefix Then
		If vCompany.PrintInvoiceAndSettlementNumbersWithPrefixes Then
			vCompanyPrefix = TrimAll(vCompany.Prefix);
			If Not IsBlankString(vCompanyPrefix) Then
				mInvoiceNumber = vCompanyPrefix + cmRemoveLeadingZeroes(SelInvoice.Number);
			Else
				mInvoiceNumber = cmRemoveLeadingZeroes(SelInvoice.Number);
			EndIf;
		Else
			vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelInvoice.Hotel);
			If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
				mInvoiceNumber = vHotelPrefix + cmRemoveLeadingZeroes(SelInvoice.Number);
			Else
				mInvoiceNumber = cmRemoveLeadingZeroes(SelInvoice.Number);
			EndIf;
		EndIf;
	Else
		mInvoiceNumber = ?(vCompany.PrintInvoiceAndSettlementNumbersWithPrefixes, TrimAll(SelInvoice.Number), cmGetDocumentNumberPresentation(SelInvoice.Number));
	EndIf;
	mInvoiceDate = cmGetDocumentDatePresentation(SelInvoice.Date);
	
	vTableHeader = vTemplate.GetArea("TableHeader");
	
	// Print different invoice headers for invoices in RUR and Russia base country and other currencies/countries
	If vRubHeader Then
		vHeader = vTemplate.GetArea("Header");
		
		mCompanyPaymentAttributes = vCompanyLegacyName;
		mCompanyBank = "";
		mCompanyBankAcount = "";
		mCompanyBankBIC = "";
		mCompanyBankCorrAccount = "";
		If vAccount.IsDirectPayments Then
			mCompanyBank = TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity);
			
			mCompanyBankAccount = TrimAll(vAccount.AccountNumber);
			mCompanyBankBIC = TrimAll(vAccount.BankBIC);
			mCompanyBankCorrAccount = TrimAll(vAccount.BankCorrAccountNumber);
		Else
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + cmNStr("en=' acc ';ru=' р/с ';de=' verrechnungskonto '", SelLanguage) + TrimAll(vAccount.AccountNumber);
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + cmNStr("en=' in ';ru=' в ';de=' in '", SelLanguage) + TrimAll(vAccount.BankName);
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + " " + TrimAll(vAccount.BankCity);
		
			mCompanyBank = TrimAll(vAccount.CorrBankName);
			mCompanyBank = mCompanyBank + TrimAll(vAccount.CorrBankCity);
			
			mCompanyBankAccount = TrimAll(vAccount.BankCorrAccountNumber);
			mCompanyBankBIC = TrimAll(vAccount.CorrBankBIC);
			mCompanyBankCorrAccount = TrimAll(vAccount.CorrBankCorrAccountNumber);
		EndIf;
		If Not IsBlankString(vAccount.Beneficiary) Then
			mCompanyPaymentAttributes = TrimAll(vAccount.Beneficiary);
		EndIf;
		
		vStructOKTMO_KBK = New Structure("mOKTMO, mKBK", "", "");
		If Not IsBlankString(vCompany.OKTMO) Or Not IsBlankString(vCompany.KBK) Then
			If Not IsBlankString(vCompany.OKTMO) Then
				vStructOKTMO_KBK.mOKTMO = TrimAll(vCompany.OKTMO);
			EndIf;
			If Not IsBlankString(vCompany.KBK) Then
				vStructOKTMO_KBK.mKBK = TrimAll(vCompany.KBK);
			EndIf; 
		EndIf; 
		
		// Customer
		vCustomerCode = "";
		If SelInvoice.AccountingCustomer = vHotel.IndividualsCustomer Then
			// Use contact person as customer
			If Not IsBlankString(SelInvoice.ContactPerson) Then
				mCustomer = TrimAll(SelInvoice.ContactPerson);
			Else
				vClientRef = Catalogs.Clients.EmptyRef();
				// Use guest group client as customer
				If ValueIsFilled(SelInvoice.GuestGroup) And ValueIsFilled(SelInvoice.GuestGroup.Client) Then
					vClientRef = SelInvoice.GuestGroup.Client;
				// Use first client as customer
				Else
					For Each vRow In SelInvoice.Services Do
						If ValueIsFilled(vRow.Client) Then
							vClientRef = vRow.Client;
							Break;
						EndIf;
					EndDo;
				EndIf;
				vCustomer = vClientRef;
				vCustomerLegacyName = "";
				vCustomerLegacyAddress = "";
				vCustomerTIN = "";
				vCustomerPhones = "";
				If ValueIsFilled(vClientRef) Then
					vCustomerLegacyName = TrimAll(vClientRef.FullName);
					vCustomerLegacyAddress = cmGetAddressPresentation(vClientRef.Address);
					vCustomerTIN = "";
					vCustomerKPP = "";
					// Fax and E-Mail
					vCustomerPhones = TrimAll(vClientRef.Phone);
					vCustomerFax = TrimAll(vClientRef.Fax);
					vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
				EndIf;
				mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + vCustomerPhones);
			EndIf;
			// Contract
			mContract = "";
		Else
			vCustomer = SelInvoice.AccountingCustomer;
			vCustomerLegacyName = "";
			vCustomerLegacyAddress = "";
			vCustomerPostAddress = "";
			vCustomerTIN = "";
			vCustomerVATCode = "";
			vCustomerPhones = "";
			If ValueIsFilled(vCustomer) Then
				vCustomerLegacyName = TrimAll(vCustomer.LegacyName);
				If IsBlankString(vCustomerLegacyName) Then
					vCustomerLegacyName = TrimAll(vCustomer.Description);
				EndIf;
				If Not vCustomer.IsIndividual Then
					vCustomerCode = TrimAll(vCustomer.Code);
				EndIf;
				
				// Addresses
				vCustomerLegacyAddress = cmGetAddressPresentation(vCustomer.LegacyAddress);
				vCustomerPostAddress = cmGetAddressPresentation(vCustomer.PostAddress);
				If vCustomerPostAddress = vCustomerLegacyAddress Then
					vCustomerPostAddress = "";
				EndIf;
				
				// Codes
				vCustomerTIN = TrimAll(vCustomer.TIN);
				vCustomerVATCode = TrimAll(vCustomer.VATC);
				vCustomerKPP = TrimAll(vCustomer.KPP);
				vCustomerTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН '", SelLanguage) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP) + 
				               ?(IsBlankString(vCustomerVATCode), "", cmNStr("en=', VAT code ';de=', Mw.St. code ';ru=', код НДС ';lv=', PVN '", SelLanguage) + vCustomerVATCode);
							   
				// Fax and E-Mail
				vCustomerPhones = TrimAll(vCustomer.Phone);
				vCustomerFax = TrimAll(vCustomer.Fax);
				vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
			EndIf;
			mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + vCustomerPhones);
			// Contract
			mContract = "";
			If ValueIsFilled(SelInvoice.AccountingContract) Then
				mContract = TrimAll(SelInvoice.AccountingContract.Description);
			EndIf;
		EndIf;
		// Guest group code
		mGuestGroup = "";
		vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelInvoice.Hotel);
		If ValueIsFilled(SelInvoice.GuestGroup) Then
			mGuestGroup = Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=");
			If Not IsBlankString(SelInvoice.GuestGroup.ID) Then
				mGuestGroup = mGuestGroup + " - Ref. # " + TrimAll(SelInvoice.GuestGroup.ID);
			ElsIf Not IsBlankString(SelInvoice.GuestGroup.Description) Then
				mGuestGroup = mGuestGroup + " - " + TrimAll(SelInvoice.GuestGroup.Description);
			EndIf;
			If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
				mGuestGroup = vHotelPrefix + mGuestGroup;
			EndIf;
		Else
			vGroups = SelInvoice.Services.Unload(, "GuestGroup");
			vGroups.GroupBy("GuestGroup", );
			For Each vGroupsRow In vGroups Do
				If ValueIsFilled(vGroupsRow.GuestGroup) Then
					vGuestGroupCode = Format(vGroupsRow.GuestGroup.Code, "ND=12; NFD=0; NG=");
					If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
						vGuestGroupCode = vHotelPrefix + vGuestGroupCode;
					EndIf;
					If IsBlankString(mGuestGroup) Then
						mGuestGroup = vGuestGroupCode;
					Else
						mGuestGroup = mGuestGroup + ", " + vGuestGroupCode;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Currency
		mAccountingCurrency = "";
		If ValueIsFilled(SelInvoice.AccountingCurrency) Then
			vCurrencyObj = SelInvoice.AccountingCurrency.GetObject();
			mAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
		EndIf;
		// Parent document
		mParentDoc = ?(ValueIsFilled(SelInvoice.ParentDoc), TrimAll(SelInvoice.ParentDoc.Number), "");
		mFullInvoiceNumber = Trimall(SelInvoice.Number) + ?(IsBlankString(vCustomerCode), "", " " + vCustomerCode);
		// Set parameters and put report section
		vHeader.Parameters.mHotelPrintName = mHotelPrintName;
		vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
		vHeader.Parameters.mHotelPhones = mHotelPhones;
		vHeader.Parameters.mHotelEMail = mHotelEMail;
		vHeader.Parameters.mInvoiceNumber = mInvoiceNumber;
		vHeader.Parameters.mFullInvoiceNumber = mFullInvoiceNumber;
		vHeader.Parameters.mInvoiceDate = mInvoiceDate;
		If SelInvoice.AccountingCurrency = vHotel.BaseCurrency Then
			vHeader.Parameters.mCompany = mCompany;
			vHeader.Parameters.mCompanyTIN = mCompanyTIN;
			vHeader.Parameters.mCompanyKPP = mCompanyKPP;
			vHeader.Parameters.mCompanyBankBIC = mCompanyBankBIC;
			vHeader.Parameters.mCompanyBankCorrAccount = mCompanyBankCorrAccount;
		EndIf;
		vHeader.Parameters.mCompanyPaymentAttributes = mCompanyPaymentAttributes;
		vHeader.Parameters.mCompanyBank = mCompanyBank;
		vHeader.Parameters.mCompanyBankAccount = mCompanyBankAccount;
		vHeader.Parameters.mCustomer = mCustomer;
		vHeader.Parameters.mInvoiceEMail = TrimAll(SelInvoice.EMail);
		vHeader.Parameters.mContract = mContract;
		vHeader.Parameters.mGuestGroup = mGuestGroup;
		vHeader.Parameters.mAccountingCurrency = mAccountingCurrency;
		vHeader.Parameters.mParentDoc = mParentDoc;
		// Logo
		If vLogoIsSet Then
			vHeader.Drawings.Logo.Print = True;
			vHeader.Drawings.Logo.Picture = vLogo;
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.Logo);
		EndIf;
		
		// Genarate QR-Code
		If vPrintQRCode Then
			vServices = SelInvoice.Services.Unload();
			vTotalSum = 0;
			vTotalVATSum = vServices.Total("VATSum");
			vTotalCommissionSum = 0;
			If vServices <> Undefined Then
				vTotalSum = vServices.Total("Sum");
				vTotalCommissionSum = vServices.Total("CommissionSum");
				If vTotalCommissionSum <> 0 And 
					ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
					vTotalSum = vTotalSum - vTotalCommissionSum;
				EndIf;
			EndIf;

			// Payment text
			mPaymentText = NStr("en='Payment for invoice N';ru='Оплата счета №';de='Bezahlung der Rechnung Nr.'", SelLanguage) + cmGetDocumentNumberPresentation(SelInvoice.Number) + 
			               NStr("en=', reservation confirmation N';de=', reservation confirmation N';ru=', подтверждение брони №'", SelLanguage) + mGuestGroup + ".";

			vStructOutputData = New Structure;
			vStructOutputData.Insert("Name", 		mCompany);
			vStructOutputData.Insert("PersonalAcc", mCompanyBankAccount);
			vStructOutputData.Insert("CorrespAcc", 	mCompanyBankCorrAccount);
			vStructOutputData.Insert("BankName", 	mCompanyBank);
			vStructOutputData.Insert("BIC", 		mCompanyBankBIC);
			vStructOutputData.Insert("PayeeINN", 	mCompanyTIN);
			vStructOutputData.Insert("CBC", 		mCompanyCBC);
			vStructOutputData.Insert("OKTMO", 		mCompanyOKTMO);
			vStructOutputData.Insert("KPP", 		mCompanyKPP);
			vStructOutputData.Insert("Sum", 		vTotalSum);
			vStructOutputData.Insert("Purpose", 	mPaymentText);
			
			vQRCodeString =  tcCommonFunctions.cmGenerateBankFormattedString(vStructOutputData);
			If Not IsBlankString(vQRCodeString) Then
				Try
					vQRCodePic =  cmGetQRCodePicture(vQRCodeString);
					vQRCodeControl = vHeader.Drawings.QRCodeControl;
					vQRCodeControl.Picture = vQRCodePic;
				Except
					tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Failed to generate a QR code, possibly no internet connection'; de = 'Fehler beim Erzeugen eines QR-Codes, möglicherweise keine Internetverbindung'; ru = 'Не удалось сформировать QR-code, возможно отсутствует соединение с интернетом'"));
				EndTry;	
			EndIf;
		EndIf;

		// Put header
		FillPropertyValues(vHeader.Parameters, vStructOKTMO_KBK);  
		vSpreadsheet.Put(vHeader);
		vSpreadsheet.Put(vTableHeader);
	Else
		vHeader1 = vTemplate.GetArea("HeaderCurrency1");
		
		If Not IsBlankString(vAccount.Beneficiary) Then
			mCompany = TrimAll(vAccount.Beneficiary);
		EndIf;
		
		mCompanyBank = TrimAll(TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity));
		mCompanyBankAccount = TrimAll(vAccount.AccountNumber);
		If Not IsBlankString(vAccount.BankBIC) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='BIC ';ru='БИК ';de='BIC '", SelLanguage) + TrimAll(vAccount.BankBIC);
		EndIf;
		If Not IsBlankString(vAccount.BankCorrAccountNumber) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='Corr. acc. № ';ru='Корр. сч. № ';de='Korrespondenzkonto Nr. '", SelLanguage) + TrimAll(vAccount.BankCorrAccountNumber);
		EndIf;
		If Not IsBlankString(vAccount.BankTINCode) Then
			mCompanyBank = mCompanyBank + Chars.LF + TrimAll(vAccount.BankTINCode);
		EndIf;
		If Not IsBlankString(vAccount.BankIBAN) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='IBAN CODE ';de='IBAN CODE ';ru='IBAN CODE '", SelLanguage) + TrimAll(vAccount.BankIBAN);
		EndIf;
		If Not IsBlankString(vAccount.BankSWIFTCode) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='SWIFT CODE ';de='SWIFT CODE ';ru='SWIFT CODE '", SelLanguage) + TrimAll(vAccount.BankSWIFTCode);
		EndIf;
		
		// Set parameters and put report section
		vHeader1.Parameters.mHotelPrintName = mHotelPrintName;
		vHeader1.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
		vHeader1.Parameters.mHotelPhones = mHotelPhones;
		vHeader1.Parameters.mHotelEMail = mHotelEMail;
		vHeader1.Parameters.mInvoiceNumber = mInvoiceNumber;
		vHeader1.Parameters.mInvoiceDate = mInvoiceDate;
		vHeader1.Parameters.mCompany = mCompany;
		vHeader1.Parameters.mCompanyBankAccount = mCompanyBankAccount;
		vHeader1.Parameters.mCompanyBank = mCompanyBank;
		// Logo
		If vLogoIsSet Then
			vHeader1.Drawings.LogoCurrency.Print = True;
			vHeader1.Drawings.LogoCurrency.Picture = vLogo;
		Else
			vHeader1.Drawings.Delete(vHeader1.Drawings.LogoCurrency);
		EndIf;
		// Put header1		
		vSpreadsheet.Put(vHeader1);
		
		// Put correspondent bank header
		If Not vAccount.IsDirectPayments Then
			vCorrBankHeader = vTemplate.GetArea("CorrBank");
			
			mCompanyCorrBank = TrimAll(TrimAll(vAccount.CorrBankName) + " " + TrimAll(vAccount.CorrBankCity));
			If Not IsBlankString(vAccount.CorrBankBIC) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='BIC ';ru='БИК ';de='BIC '", SelLanguage) + TrimAll(vAccount.CorrBankBIC);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankCorrAccountNumber) Then
				mCompanyCorrBank = mCompanyCorrBank + cmNStr("en='Corr. acc. № ';ru='Корр. сч. № ';de='Korrespondenzkonto Nr. '", SelLanguage) + TrimAll(vAccount.CorrBankCorrAccountNumber);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankTINCode) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + TrimAll(vAccount.CorrBankTINCode);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankIBAN) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='IBAN CODE ';de='IBAN CODE ';RU='IBAN CODE '", SelLanguage) + TrimAll(vAccount.CorrBankIBAN);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankSWIFTCode) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='SWIFT CODE ';de='SWIFT CODE ';RU='SWIFT CODE '", SelLanguage) + TrimAll(vAccount.CorrBankSWIFTCode);
			EndIf;
			
			// Set parameters and put report section
			vCorrBankHeader.Parameters.mCompanyCorrBank = mCompanyCorrBank;
			
			// Put corr. bank header
			vSpreadsheet.Put(vCorrBankHeader);
		EndIf;
		
		// Table header
		vHeader2 = vTemplate.GetArea("HeaderCurrency2");
		
		// Customer
		vCustomerCode = "";
		If SelInvoice.AccountingCustomer = vHotel.IndividualsCustomer Then
			// Use contact person as customer
			If Not IsBlankString(SelInvoice.ContactPerson) Then
				mCustomer = TrimAll(SelInvoice.ContactPerson);
			Else				
				vClientRef = Catalogs.Clients.EmptyRef();
				// Use guest group client as customer
				If ValueIsFilled(SelInvoice.GuestGroup) And ValueIsFilled(SelInvoice.GuestGroup.Client) Then
					vClientRef = SelInvoice.GuestGroup.Client;
				// Use first client as customer
				Else
					For Each vRow In SelInvoice.Services Do
						If ValueIsFilled(vRow.Client) Then
							vClientRef = vRow.Client;
							Break;
						EndIf;
					EndDo;
				EndIf;
				vCustomer = vClientRef;
				vCustomerLegacyName = "";
				vCustomerLegacyAddress = "";
				vCustomerTIN = "";
				vCustomerPhones = "";
				If ValueIsFilled(vClientRef) Then
					vCustomerLegacyName = TrimAll(vClientRef.FullName);
					vCustomerLegacyAddress = cmGetAddressPresentation(vClientRef.Address);
					vCustomerTIN = "";
					vCustomerKPP = "";
					// Fax and E-Mail
					vCustomerPhones = TrimAll(vClientRef.Phone);
					vCustomerFax = TrimAll(vClientRef.Fax);
					vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
				EndIf;
				mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + vCustomerPhones);
			EndIf;
			// Contract
			mContract = "";
		Else
			vCustomer = SelInvoice.AccountingCustomer;
			vCustomerLegacyName = "";
			vCustomerLegacyAddress = "";
			vCustomerPostAddress = "";
			vCustomerTIN = "";
			vCustomerVATCode = "";
			vCustomerPhones = "";
			If ValueIsFilled(vCustomer) Then
				vCustomerLegacyName = TrimAll(vCustomer.LegacyName);
				If IsBlankString(vCustomerLegacyName) Then
					vCustomerLegacyName = TrimAll(vCustomer.Description);
				EndIf;
				If Not vCustomer.IsIndividual Then
					vCustomerCode = TrimAll(vCustomer.Code);
				EndIf;
				
				// Addresses
				vCustomerPostAddress = "";
				vAddressStruct = cmParseAddress(vCustomer.LegacyAddress);
				vCustomerLegacyAddress = TrimAll(vAddressStruct.Region + " " + vAddressStruct.Area) + Chars.LF +
				                         TrimAll(vAddressStruct.Street + " " + vAddressStruct.House + " " + vAddressStruct.Flat) + Chars.LF +
										 TrimAll(vAddressStruct.PostCode + " " + vAddressStruct.City) + Chars.LF + 
										 TrimAll(vAddressStruct.Country);

				If Not IsBlankString(vCustomer.PostAddress) And TrimAll(vCustomer.PostAddress) <> TrimAll(vCustomer.LegacyAddress) Then
					vAddressStruct = cmParseAddress(vCustomer.PostAddress);
					vCustomerPostAddress = TrimAll(vAddressStruct.Region + " " + vAddressStruct.Area) + Chars.LF +
					                       TrimAll(vAddressStruct.Street + " " + vAddressStruct.House + " " + vAddressStruct.Flat) + Chars.LF +
										   TrimAll(vAddressStruct.PostCode + " " + vAddressStruct.City) + Chars.LF + 
										   TrimAll(vAddressStruct.Country);
				EndIf;
				
				// Codes
				vCustomerTIN = TrimAll(vCustomer.TIN);
				vCustomerKPP = TrimAll(vCustomer.KPP);
				vCustomerVATCode = TrimAll(vCustomer.VATC);
				vCustomerTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН '", SelLanguage) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP) + 
				               ?(IsBlankString(vCustomerVATCode), "", cmNStr("en=', VAT code ';de=', Mw.St. code ';ru=', код НДС ';lv=', PVN '", SelLanguage) + vCustomerVATCode);
							   
				// Fax and E-Mail
				vCustomerPhones = TrimAll(vCustomer.Phone);
				vCustomerFax = TrimAll(vCustomer.Fax);
				vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
			EndIf;
			mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + vCustomerPhones);
			// Contract
			mContract = "";
			If ValueIsFilled(SelInvoice.AccountingContract) Then
				mContract = TrimAll(SelInvoice.AccountingContract.Description);
			EndIf;
		EndIf;
		// Guest group code
		mGuestGroup = "";
		If ValueIsFilled(SelInvoice.GuestGroup) Then
			mGuestGroup = Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=");
			If Not IsBlankString(SelInvoice.GuestGroup.ID) Then
				mGuestGroup = mGuestGroup + " - Ref. # " + TrimAll(SelInvoice.GuestGroup.ID);
			ElsIf Not IsBlankString(SelInvoice.GuestGroup.Description) Then
				mGuestGroup = mGuestGroup + " - " + TrimAll(SelInvoice.GuestGroup.Description);
			EndIf;
		Else
			vGroups = SelInvoice.Services.Unload(, "GuestGroup");
			vGroups.GroupBy("GuestGroup", );
			For Each vGroupsRow In vGroups Do
				If ValueIsFilled(vGroupsRow.GuestGroup) Then
					vGuestGroupCode = Format(vGroupsRow.GuestGroup.Code, "ND=12; NFD=0; NG=");
					If IsBlankString(mGuestGroup) Then
						mGuestGroup = vGuestGroupCode;
					Else
						mGuestGroup = mGuestGroup + ", " + vGuestGroupCode;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Currency
		mAccountingCurrency = "";
		If ValueIsFilled(SelInvoice.AccountingCurrency) Then
			vCurrencyObj = SelInvoice.AccountingCurrency.GetObject();
			mAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
		EndIf;
		// Parent document
		mParentDoc = ?(ValueIsFilled(SelInvoice.ParentDoc), TrimAll(SelInvoice.ParentDoc.Number), "");
		mFullInvoiceNumber = Trimall(SelInvoice.Number) + ?(IsBlankString(vCustomerCode), "", " " + vCustomerCode);
		// Set parameters and put report section
		vHeader2.Parameters.mFullInvoiceNumber = mFullInvoiceNumber;
		vHeader2.Parameters.mCustomer = mCustomer;
		vHeader2.Parameters.mInvoiceEMail = TrimAll(SelInvoice.EMail);
		vHeader2.Parameters.mContract = mContract;
		vHeader2.Parameters.mGuestGroup = mGuestGroup;
		vHeader2.Parameters.mAccountingCurrency = mAccountingCurrency;
		vHeader2.Parameters.mParentDoc = mParentDoc;
		// Put header		
		vSpreadsheet.Put(vHeader2);
		vSpreadsheet.Put(vTableHeader);
	EndIf;
	
	// Get template areas
	vClient = vTemplate.GetArea("Client");
	vRow = vTemplate.GetArea("Row");
	
	// Get all services
	vServices = SelInvoice.Services.Unload();
	
	vAgentCommission = 0;
	vDiscountPercent = 0;
	For Each vSrvRow In vServices Do
		If vAgentCommission = 0 Then
			vAgentCommission = vSrvRow.AgentCommission;
		EndIf;
		If vDiscountPercent = 0 Then
			vDiscountPercent = vSrvRow.Discount;
		EndIf;
	EndDo;
	
	// Change accounting dates for breakfast
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		If vServices.Find(True, "IsRoomRevenue") <> Undefined Then
			For Each vSrvRow In vServices Do
				If vSrvRow.IsInPrice And ValueIsFilled(vSrvRow.Service.QuantityCalculationRule) And
				   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Breakfast Then
					If BegOfDay(vSrvRow.AccountingDate) > BegOfDay(vSrvRow.DateTimeFrom) Then
						vSrvRow.AccountingDate = vSrvRow.AccountingDate - 24*3600;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Join services according to service parameters
	vJoinByServiceParameter = False;
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		// Try to replace accommodation service to the one that should be used for printing
		For Each vSrvRow In vServices Do
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
				EndIf;
			EndIf;
		EndDo;
		// Try to merge other services to the accommodation service
		vFirstReplacedService = Undefined;
		i = 0;
		While i < vServices.Count() Do
			vSrvRow = vServices.Get(i);
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					// Try to find service to hide current one to
					vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Client, RoomType, Room, Resource", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate, vSrvRow.Client, vSrvRow.RoomType, vSrvRow.Room, vSrvRow.Resource));
					If vHideToServices.Count() = 0 Then
						vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Client, RoomType, Room, Resource", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate - 24*3600, vSrvRow.Client, vSrvRow.RoomType, vSrvRow.Room, vSrvRow.Resource));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vSrvRow.Sum;
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vSrvRow.VATSum;
						vSrv2Hide2.DiscountSum = vSrv2Hide2.DiscountSum + vSrvRow.DiscountSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
						// Delete current service
						vServices.Delete(i);
						Continue;
					Else
						If Not ValueIsFilled(vFirstReplacedService) Then
							vFirstReplacedService = vSrvRowService;
						Else
							If vSrvRowService <> vFirstReplacedService Then
								vSrvRow.Quantity = 0;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
	
	// Get accommodation service name
	vAccommodationService = Undefined;	
	vAccommodationRemarks = "";	
	vBaseAccommodationRemarks = "";	
	vAccommodationServiceVATRate = Undefined;
	i = 0;
	While i < vServices.Count() Do
		vSrvRow = vServices.Get(i);
		If SelGroupBy = "InPricePerClientPerDay" Or SelGroupBy = "InPricePerDay" Or
		   SelGroupBy = "AllPerClientPerDay" Or SelGroupBy = "AllPerDay" Or
		   SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or
		   SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Then
			If vSrvRow.Sum = 0 Then
				vServices.Delete(i);
				Continue;
			EndIf;
		EndIf;
		If vAccommodationService = Undefined And vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly Then
			vAccommodationService = vSrvRow.Service;
			vAccommodationServiceVATRate = vSrvRow.VATRate;
			vBaseAccommodationRemarks = TrimAll(vSrvRow.Remarks);	
			vAccommodationRemarks = TrimAll(vSrvRow.Remarks);
			If SelGroupBy = "InPricePerClientPerDay" Or SelGroupBy = "InPricePerDay" Or
			   SelGroupBy = "AllPerClientPerDay" Or SelGroupBy = "AllPerDay" Or
			   SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or
			   SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Then
				If ValueIsFilled(vAccommodationService) Then
					vSrvDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, False);
					vSrvGrpDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, True);
					vAccommodationRemarks = StrReplace(vAccommodationRemarks, vSrvDescr, vSrvGrpDescr);
				EndIf;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	
	// Group by services according to the invoice print type
	If Not IsBlankString(SelGroupBy) Then
		If SelGroupBy = "InPricePerClientPerDay" Or SelGroupBy = "InPricePerDay" Then
			For Each vSrvRow In vServices Do
				// Update accommodation service parameters
				If vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly And Not IsBlankString(vBaseAccommodationRemarks) And vBaseAccommodationRemarks <> TrimAll(vSrvRow.Remarks) Then
					vAccommodationService = vSrvRow.Service;
					vAccommodationServiceVATRate = vSrvRow.VATRate;
					vAccommodationRemarks = TrimAll(vSrvRow.Remarks);
					vBaseAccommodationRemarks = TrimAll(vSrvRow.Remarks);
					If SelGroupBy = "InPricePerClientPerDay" Or SelGroupBy = "InPricePerDay" Or
					   SelGroupBy = "AllPerClientPerDay" Or SelGroupBy = "AllPerDay" Or
					   SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or
					   SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Then
						If ValueIsFilled(vAccommodationService) Then
							vSrvDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, False);
							vSrvGrpDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, True);
							vAccommodationRemarks = StrReplace(vAccommodationRemarks, vSrvDescr, vSrvGrpDescr);
						EndIf;
					EndIf;
				EndIf;
				vSrvRow.AccountingDate = BegOfDay(vSrvRow.AccountingDate);
				If SelGroupBy = "InPricePerDay" Then
					vSrvRow.Client = Catalogs.Clients.EmptyRef();
					vSrvRow.NumberOfPersons = 0;
					vSrvRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
					vSrvRow.RoomType = Catalogs.RoomTypes.EmptyRef();
					vSrvRow.Room = Catalogs.Rooms.EmptyRef();
					vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
					vSrvRow.DateTimeFrom = Undefined;
					vSrvRow.DateTimeTo = Undefined;
				EndIf;
				If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vSrvRow.VATRate) Then
					If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						vSrvRow.Remarks = ?(IsBlankString(vAccommodationRemarks), TrimAll(vSrvRow.Remarks), vAccommodationRemarks);
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
						vSrvRow.RoomQuantity = 0;
						vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
					ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						If vSrvRow.Service.RoomRevenueAmountsOnly Then
							vSrvRow.Quantity = 0;
							vSrvRow.RoomQuantity = 0;
						EndIf;
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						vSrvRow.Remarks = ?(IsBlankString(vAccommodationRemarks), TrimAll(vSrvRow.Remarks), vAccommodationRemarks);
						vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "AllPerClientPerDay" Or SelGroupBy = "AllPerDay" Then
			For Each vSrvRow In vServices Do
				// Update accommodation service parameters
				If vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly And Not IsBlankString(vBaseAccommodationRemarks) And vBaseAccommodationRemarks <> TrimAll(vSrvRow.Remarks) Then
					vAccommodationService = vSrvRow.Service;
					vAccommodationServiceVATRate = vSrvRow.VATRate;
					vAccommodationRemarks = TrimAll(vSrvRow.Remarks);
					vBaseAccommodationRemarks = TrimAll(vSrvRow.Remarks);
					If SelGroupBy = "InPricePerClientPerDay" Or SelGroupBy = "InPricePerDay" Or
					   SelGroupBy = "AllPerClientPerDay" Or SelGroupBy = "AllPerDay" Or
					   SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or
					   SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Then
						If ValueIsFilled(vAccommodationService) Then
							vSrvDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, False);
							vSrvGrpDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, True);
							vAccommodationRemarks = StrReplace(vAccommodationRemarks, vSrvDescr, vSrvGrpDescr);
						EndIf;
					EndIf;
				EndIf;
				vSrvRow.AccountingDate = BegOfDay(vSrvRow.AccountingDate);
				If SelGroupBy = "AllPerDay" Then
					vSrvRow.Client = Catalogs.Clients.EmptyRef();
					vSrvRow.NumberOfPersons = 0;
					vSrvRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
					vSrvRow.RoomType = Catalogs.RoomTypes.EmptyRef();
					vSrvRow.Room = Catalogs.Rooms.EmptyRef();
					vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
					vSrvRow.DateTimeFrom = Undefined;
					vSrvRow.DateTimeTo = Undefined;
				EndIf;
				If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vSrvRow.VATRate) Then
					If Not vSrvRow.IsRoomRevenue Then
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						vSrvRow.Remarks = ?(IsBlankString(vAccommodationRemarks), TrimAll(vSrvRow.Remarks), vAccommodationRemarks);
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
						vSrvRow.RoomQuantity = 0;
						vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
					Else
						If vSrvRow.Service.RoomRevenueAmountsOnly Then
							vSrvRow.Quantity = 0;
							vSrvRow.RoomQuantity = 0;
						EndIf;
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						vSrvRow.Remarks = ?(IsBlankString(vAccommodationRemarks), TrimAll(vSrvRow.Remarks), vAccommodationRemarks);
						vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "PerClient" Then
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(SelInvoice.Date);
				If Not vSrvRow.IsRoomRevenue Then
					vSrvRow.RoomQuantity = 0;
					vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
				Else
					If vSrvRow.Service.RoomRevenueAmountsOnly Then
						vSrvRow.RoomQuantity = 0;
					EndIf;
					vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "ByService" Then
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(SelInvoice.Date);
				vSrvRow.Client = Catalogs.Clients.EmptyRef();
				vSrvRow.NumberOfPersons = 0;
				vSrvRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
				vSrvRow.RoomType = Catalogs.RoomTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				vSrvRow.Resource = Catalogs.Resources.EmptyRef();
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.DateTimeFrom = Undefined;
				vSrvRow.DateTimeTo = Undefined;
				If Not vSrvRow.IsRoomRevenue Then
					vSrvRow.RoomQuantity = 0;
				Else
					If vSrvRow.Service.RoomRevenueAmountsOnly Then
						vSrvRow.RoomQuantity = 0;
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Then
			For Each vSrvRow In vServices Do
				// Update accommodation service parameters
				If vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly And Not IsBlankString(vBaseAccommodationRemarks) And vBaseAccommodationRemarks <> TrimAll(vSrvRow.Remarks) Then
					vAccommodationService = vSrvRow.Service;
					vAccommodationServiceVATRate = vSrvRow.VATRate;
					vAccommodationRemarks = TrimAll(vSrvRow.Remarks);
					vBaseAccommodationRemarks = TrimAll(vSrvRow.Remarks);
					If SelGroupBy = "InPricePerClientPerDay" Or SelGroupBy = "InPricePerDay" Or
					   SelGroupBy = "AllPerClientPerDay" Or SelGroupBy = "AllPerDay" Or
					   SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or
					   SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Then
						If ValueIsFilled(vAccommodationService) Then
							vSrvDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, False);
							vSrvGrpDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, True);
							vAccommodationRemarks = StrReplace(vAccommodationRemarks, vSrvDescr, vSrvGrpDescr);
						EndIf;
					EndIf;
				EndIf;
				vSrvRow.AccountingDate = BegOfDay(SelInvoice.Date);
				If SelGroupBy = "InPrice" Then
					vSrvRow.Client = Catalogs.Clients.EmptyRef();
					vSrvRow.NumberOfPersons = 0;
					vSrvRow.Room = Catalogs.Rooms.EmptyRef();
					vSrvRow.DateTimeFrom = Undefined;
					vSrvRow.DateTimeTo = Undefined;
				EndIf;
				If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vSrvRow.VATRate) Then
					If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						vSrvRow.Remarks = ?(IsBlankString(vAccommodationRemarks), TrimAll(vSrvRow.Remarks), vAccommodationRemarks);
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
						vSrvRow.RoomQuantity = 0;
						vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
					ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						If vSrvRow.Service.RoomRevenueAmountsOnly Then
							vSrvRow.RoomQuantity = 0;
							vSrvRow.Quantity = 0;
						EndIf;
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						vSrvRow.Remarks = ?(IsBlankString(vAccommodationRemarks), TrimAll(vSrvRow.Remarks), vAccommodationRemarks);
						vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Then
			For Each vSrvRow In vServices Do
				// Update accommodation service parameters
				If vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly And Not IsBlankString(vBaseAccommodationRemarks) And vBaseAccommodationRemarks <> TrimAll(vSrvRow.Remarks) Then
					vAccommodationService = vSrvRow.Service;
					vAccommodationServiceVATRate = vSrvRow.VATRate;
					vAccommodationRemarks = TrimAll(vSrvRow.Remarks);
					vBaseAccommodationRemarks = TrimAll(vSrvRow.Remarks);
					If SelGroupBy = "InPricePerClientPerDay" Or SelGroupBy = "InPricePerDay" Or
					   SelGroupBy = "AllPerClientPerDay" Or SelGroupBy = "AllPerDay" Or
					   SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or
					   SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Then
						If ValueIsFilled(vAccommodationService) Then
							vSrvDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, False);
							vSrvGrpDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, True);
							vAccommodationRemarks = StrReplace(vAccommodationRemarks, vSrvDescr, vSrvGrpDescr);
						EndIf;
					EndIf;
				EndIf;
				vSrvRow.AccountingDate = BegOfDay(SelInvoice.Date);
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
				vSrvRow.RoomType = Catalogs.RoomTypes.EmptyRef();
				If SelGroupBy = "All" Then
					vSrvRow.Client = Catalogs.Clients.EmptyRef();
					vSrvRow.NumberOfPersons = 0;
					vSrvRow.Room = Catalogs.Rooms.EmptyRef();
					vSrvRow.DateTimeFrom = Undefined;
					vSrvRow.DateTimeTo = Undefined;
				EndIf;
				If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vSrvRow.VATRate) Then
					If Not vSrvRow.IsRoomRevenue Then
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						vSrvRow.Remarks = ?(IsBlankString(vAccommodationRemarks), TrimAll(vSrvRow.Remarks), vAccommodationRemarks);
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
						vSrvRow.RoomQuantity = 0;
						vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
					Else
						If vSrvRow.Service.RoomRevenueAmountsOnly Then
							vSrvRow.RoomQuantity = 0;
							vSrvRow.Quantity = 0;
						EndIf;
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						vSrvRow.Remarks = ?(IsBlankString(vAccommodationRemarks), TrimAll(vSrvRow.Remarks), vAccommodationRemarks);
						vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Group by transactions
		If FillProformaInvoiceMode = Enums.FillProformaInvoiceModes.InDetailsWithDates Then
			vServices.GroupBy("Client, AccommodationType, RoomType, Room, Resource, DateTimeFrom, DateTimeTo, CalendarDayType, AccountingDate, Service, Remarks, VATRate, AgentCommission, AgentCommissionType, RoomQuantity, NumberOfPersons", "Sum, VATSum, Price, Quantity, CommissionSum, VATCommissionSum, DiscountSum");
		Else
			vServices.GroupBy("Client, AccommodationType, RoomType, Room, Resource, DateTimeFrom, DateTimeTo, CalendarDayType, AccountingDate, Service, Remarks, VATRate, AgentCommission, AgentCommissionType", "Sum, VATSum, Price, Quantity, RoomQuantity, NumberOfPersons, CommissionSum, VATCommissionSum, DiscountSum");
		EndIf;
		// Recalculate price for all services and delete zero sum rows
		i = 0;
		While i < vServices.Count() Do
			vSrvRow = vServices.Get(i);
			If vSrvRow.Sum = 0 And SelGroupBy <> "ByService" Then
				vServices.Delete(i);
			Else
				If vShowDiscounts Then
					vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum + vSrvRow.DiscountSum, vSrvRow.Quantity);
				Else
					vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
				EndIf;
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	vServices.Sort("Room, RoomType, Resource, Client, DateTimeFrom, AccountingDate, Remarks");
	
	// Calculate totals
	vTotalSum = 0;
	vTotalSumNoCommission = 0;
	vTotalCommissionSum = 0;
	vTotalDiscountSum = 0;
	vTotalSumToBePaid = 0;
	vTotalVATSum = 0;
	
	vVATRateTransactions = New ValueTable();
	vVATRateTransactions.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
	vVATRateTransactions.Columns.Add("VATRateCode", cmGetNumberTypeDescription(4, 0));
	vVATRateTransactions.Columns.Add("Sum", cmGetSumTypeDescription());
	vVATRateTransactions.Columns.Add("VATSum", cmGetSumTypeDescription());
	
	vUseSectionVAT = False;
	For Each vSrvRow In vServices Do
		vTotalSum = vTotalSum + vSrvRow.Sum;
		If vShowDiscounts Then
			vTotalSum = vTotalSum + vSrvRow.DiscountSum;
		EndIf;
		vTotalSumToBePaid = vTotalSumToBePaid + vSrvRow.Sum;
		vTotalSumNoCommission = vTotalSumNoCommission + vSrvRow.Sum - vSrvRow.CommissionSum;
		vTotalCommissionSum = vTotalCommissionSum + vSrvRow.CommissionSum;
		vTotalDiscountSum = vTotalDiscountSum + vSrvRow.DiscountSum;
		
		// Get effective VAT rate
		vVATRate = vSrvRow.VATRate;
		If Not vDoNotUseSectionVAT And Not vIgnoreVATRate Then
			If ValueIsFilled(vSrvRow.Service) And ValueIsFilled(vSrvRow.Service.PaymentSection) And ValueIsFilled(vSrvRow.Service.PaymentSection.VATRate) And 
			   vSrvRow.VATRate <> vSrvRow.Service.PaymentSection.VATRate Then
				vVATRate = vSrvRow.Service.PaymentSection.VATRate;
				vUseSectionVAT = True;
			EndIf;
		EndIf;
		vSrvRow.VATRate = vVATRate;
		
		vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
		vTotalVATSum = vTotalVatSum + vSrvRow.VATSum;
		
		vVATRateTransactionsRow = vVATRateTransactions.Add();
		vVATRateTransactionsRow.VATRate = vVATRate;
		vVATRateTransactionsRow.VATRateCode = ?(ValueIsFilled(vVATRate), vVATRate.Code, 0);
		vVATRateTransactionsRow.VATSum = vSrvRow.VATSum;
		vVATRateTransactionsRow.Sum = vSrvRow.Sum;
	EndDo;
	If ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
		vTotalSumToBePaid = vTotalSumNoCommission;
	EndIf;
	vVATRateTransactions.GroupBy("VATRate, VATRateCode", "Sum, VATSum");
	vVATRateTransactions.Sort("VATRateCode");
	
	// Build footer
	vFooterAreas = new Array();
	vFooter1 = vTemplate.GetArea("Footer1");
	vCommission = vTemplate.GetArea("Commission");
	vDiscount = vTemplate.GetArea("Discount");
	vFooter2 = vTemplate.GetArea("Footer2");
	
	// Fill parameters
	mTotalSum = Format(vTotalSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
	mTotalVATSum = "";
	If Not (ValueIsFilled(vCompany) And vCompany.DoNotPrintVAT) Then
		If vTotalVATSum <> 0 Then
			mTotalVATSum = cmNStr("EN='Including VAT ';RU='В том числе НДС ';de='Darunter MwSt. '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
		Else
			If ValueIsFilled(SelInvoice.Company) And SelInvoice.Company.IsUsingSimpleTaxSystem Then
				mTotalVATSum = cmNStr("en='No VAT';ru='НДС не облагается в связи с применением упрощенной системы налогообложения (п. 2 ст. 346.11 НК РФ)';de='Im Zusammenhang mit der Anwendung des vereinfachten Besteuerungssystems wird die MwSt. nicht berechnet (Punkt 2 Artikel 346.11 des Steuergesetzes der Russischen Föderation)'", SelLanguage);
			Else
				If vVATRateTransactions.Count() > 0 Then
					vRowVatRate = vVATRateTransactions[0].VATRate;
					If ValueIsFilled(vRowVatRate) And Not vRowVatRate.NoVAT And vRowVatRate.TaxRate = 0 Then
						mTotalVATSum = cmNStr("EN='Including VAT ';RU='НДС ';de='Darunter MwSt. '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2; NZ=0.00") + " " + mAccountingCurrency;
					EndIf;	
				Else
					mTotalVATSum = cmNStr("en='No VAT';ru='НДС не облагается';de='MwSt. wird nicht berechnet'", SelLanguage); 
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If SelLanguage = Catalogs.Languages.DE Then
		mTotalVATSum = "";
	EndIf;

	// Set parameters
	vFooter1.Parameters.mTotalSum = mTotalSum;
	vFooter2.Parameters.mTotalVATSum = mTotalVATSum;
	vFooter2.Parameters.mTotalSumInWords = cmSumInWords(vTotalSumToBePaid, SelInvoice.AccountingCurrency, SelLanguage);
	
	// Put footer
	vFooterAreas.Add(vFooter1);
	If vShowDiscounts And vDiscountPercent <> 0 Then
		vDiscount.Parameters.mDiscount = vDiscountPercent;
		vDiscount.Parameters.mTotalDiscountSum = Format(vTotalDiscountSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
		vDiscount.Parameters.mSumToBePaid = Format(vTotalSumToBePaid, "ND=17; NFD=2") + " " + mAccountingCurrency;
		vFooterAreas.Add(vDiscount);
	Else
		If vTotalCommissionSum <> 0 And 
		   ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
			mAgentCommission = "";   
			If ValueIsFilled(SelInvoice.GuestGroup) Then
				mAgentCommission = mAgentCommission + GetAgentCommissionDescription(vAgentCommission, SelInvoice.GuestGroup.ClientDoc, SelLanguage);
			Else
				mAgentCommission = mAgentCommission + vAgentCommission + "%";
			EndIf;
			vCommission.Parameters.mTotalCommissionSum = Format(vTotalCommissionSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
			vCommission.Parameters.mAgentCommission = mAgentCommission;
			vCommission.Parameters.mSumToBePaid = Format(vTotalSumToBePaid, "ND=17; NFD=2") + " " + mAccountingCurrency;
			vFooterAreas.Add(vCommission);
		EndIf;
	EndIf;
	vFooterAreas.Add(vFooter2);
	
	// VAT rates table
	If ValueIsFilled(vCompany) And Not vCompany.IsUsingSimpleTaxSystem Then
		vVATHeaderArea = vTemplate.GetArea("VATHeader");
		vFooterAreas.Add(vVATHeaderArea);
		For Each vVATRateRow In vVATRateTransactions Do
			vVATRateRowArea = vTemplate.GetArea("VATRateRow");
			vVATRateRowArea.Parameters.mVATRate = TrimAll(vVATRateRow.VATRate);
			vVATRateRowArea.Parameters.mSumWithoutVAT = Format(vVATRateRow.Sum - vVATRateRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mVATSum = Format(vVATRateRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mSumWithVAT = Format(vVATRateRow.Sum, "ND=17; NFD=2; NZ=");
			vFooterAreas.Add(vVATRateRowArea);
		EndDo;
	EndIf;
	
	// Signatures
	vSignedByManager = False;
	If ValueIsFilled(SelInvoice.Company) And SelInvoice.Company.InvoiceIsSignedByManager Then
		vSignedByManager = True;
	EndIf;
	If Not vSignedByManager Then
		If SelInvoice.PrintWithCompanyStamp Then
			vSignatures = vTemplate.GetArea("SignaturesWithStamp");
		Else
			vSignatures = vTemplate.GetArea("Signatures");
		EndIf;
		mCompanyDirector = TrimAll(cmNStr(vCompany.Director, SelLanguage));
		If Not IsBlankString(vCompany.DirectorPosition) Then
			mCompanyDirectorPosition = TrimAll(cmNStr(vCompany.DirectorPosition, SelLanguage));
		Else
			mCompanyDirectorPosition = cmNStr("en='Director';ru='Руководитель';de='Leiter'", SelLanguage);
		EndIf;
		mCompanyAccountantGeneral = TrimAll(cmNStr(vCompany.AccountantGeneral, SelLanguage));
		If Not IsBlankString(vCompany.AccountantGeneralPosition) Then
			mCompanyAccountantGeneralPosition = TrimAll(cmNStr(vCompany.AccountantGeneralPosition, SelLanguage));
		Else
			mCompanyAccountantGeneralPosition = cmNStr("en='Accountant';ru='Бухгалтер';de='Buchhalter'", SelLanguage);
		EndIf;
		vSignatures.Parameters.mRemarks = TrimAll(SelInvoice.RemarksForPrinting);
		If ValueIsFilled(SelInvoice.CheckDate) And (ValueIsFilled(SelInvoice.GuestGroup) And 
		   ValueIsFilled(SelInvoice.GuestGroup.CheckInDate) And BegOfDay(SelInvoice.GuestGroup.CheckInDate) >= BegOfDay(SelInvoice.CheckDate) Or Not ValueIsFilled(SelInvoice.GuestGroup)) Then
			vSignatures.Parameters.mRemarks = vSignatures.Parameters.mRemarks + ?(IsBlankString(vSignatures.Parameters.mRemarks), "", Chars.LF) + 
			                                  ?(vDoNotShowPayDueDate, "", cmNStr("en='Payment before '; ru='Оплата до '; de='Zahlung vor '; lv='Apmaksāt līdz '", SelLanguage) + Format(SelInvoice.CheckDate, "DF=dd.MM.yyyy"));
		EndIf;
		vSignatures.Parameters.mCompanyDirector = mCompanyDirector;
		vSignatures.Parameters.mCompanyDirectorPosition = mCompanyDirectorPosition;
		vSignatures.Parameters.mCompanyAccountantGeneral = mCompanyAccountantGeneral;
		vSignatures.Parameters.mCompanyAccountantGeneralPosition = mCompanyAccountantGeneralPosition;
		// Company stamp
		If SelInvoice.PrintWithCompanyStamp Then
			If vStampIsSet Then
				vSignatures.Drawings.Stamp.Print = True;
				vSignatures.Drawings.Stamp.Picture = vStamp;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.Stamp);
			EndIf;
			If vDirectorSignatureIsSet Then
				vSignatures.Drawings.DirectorSignature.Print = True;
				vSignatures.Drawings.DirectorSignature.Picture = vDirectorSignature;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.DirectorSignature);
			EndIf;
			If vAccountantGeneralSignatureIsSet Then
				vSignatures.Drawings.AccountantGeneralSignature.Print = True;
				vSignatures.Drawings.AccountantGeneralSignature.Picture = vAccountantGeneralSignature;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.AccountantGeneralSignature);
			EndIf;
		EndIf;
		// Form text
		vSignatures.Parameters.mFormText = TrimR(SelObjectPrintForm.FormText);
		// Put signatures	
		vFooterAreas.Add(vSignatures);
	Else
		If SelInvoice.PrintWithCompanyStamp Then
			vSignatures = vTemplate.GetArea("ManagerSignatureWithStamp");
		Else
			vSignatures = vTemplate.GetArea("ManagerSignature");
		EndIf;
		mPosition = cmNStr("en='Manager';ru='Менеджер';de='Manager'", SelLanguage);
		mEmployee = "";
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			If Not IsBlankString(SessionParameters.CurrentUser.Position) Then
				mPosition = cmNStr(SessionParameters.CurrentUser.Position, SelLanguage);
			EndIf;
			If Not IsBlankString(SessionParameters.CurrentUser.DescriptionTranslations) Then
				mEmployee = cmNStr(SessionParameters.CurrentUser.DescriptionTranslations, SelLanguage);
			Else
				mEmployee = TrimAll(SessionParameters.CurrentUser.Description);
			EndIf;
		EndIf;
		vSignatures.Parameters.mRemarks = TrimAll(SelInvoice.RemarksForPrinting);
		If ValueIsFilled(SelInvoice.CheckDate) And (ValueIsFilled(SelInvoice.GuestGroup) And 
		   ValueIsFilled(SelInvoice.GuestGroup.CheckInDate) And BegOfDay(SelInvoice.GuestGroup.CheckInDate) >= BegOfDay(SelInvoice.CheckDate) Or Not ValueIsFilled(SelInvoice.GuestGroup)) Then
			vSignatures.Parameters.mRemarks = vSignatures.Parameters.mRemarks + ?(IsBlankString(vSignatures.Parameters.mRemarks), "", Chars.LF) + 
			                                  ?(vDoNotShowPayDueDate, "", cmNStr("en='Payment before '; ru='Оплата до '; de='Zahlung vor '; lv='Apmaksāt līdz '", SelLanguage) + Format(SelInvoice.CheckDate, "DF=dd.MM.yyyy"));
		EndIf;
		vSignatures.Parameters.mPosition = mPosition;
		vSignatures.Parameters.mEmployee = mEmployee;
		// Company stamp and manager's signature
		If SelInvoice.PrintWithCompanyStamp Then
			If vSignatureIsSet Then
				vSignatures.Drawings.Signature.Print = True; 
				If TypeOf(vSignature) = Type("BinaryData") Then
					vSignatures.Drawings.Signature.Picture = New Picture(vSignature);	
				Else
					vSignatures.Drawings.Signature.Picture = vSignature;
				EndIf;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.Signature);
			EndIf;
			If vStampIsSet Then
				vSignatures.Drawings.ManagerStamp.Print = True;
				vSignatures.Drawings.ManagerStamp.Picture = vStamp;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.ManagerStamp);
			EndIf;
		EndIf;
		// Form text
		vSignatures.Parameters.mFormText = TrimR(SelObjectPrintForm.FormText);
		// Put signatures	
		vFooterAreas.Add(vSignatures);
	EndIf;
	
	// Print services
	vCurMClient = "";
	vCurClient = Undefined;
	vCurNumberOfPersons = 0;
	vCurAccommodationType = Undefined;
	vCurRoomType = Undefined;
	vCurRoom = Undefined;
	vCurResource = Undefined;
	For Each vSrvRow In vServices Do
		vCurClient = vSrvRow.Client;
		vCurNumberOfPersons = vSrvRow.NumberOfPersons;
		vCurAccommodationType = vSrvRow.AccommodationType;
		vCurRoomType = vSrvRow.RoomType;
		vCurRoom = vSrvRow.Room;
		vCurResource = vSrvRow.Resource;
		vCurPeriodPresentation = "";
		vCurDateTimeFrom = vSrvRow.DateTimeFrom;
		vCurDateTimeTo = vSrvRow.DateTimeTo;
		If ValueIsFilled(vCurDateTimeFrom) And Find(vParameter, "SHOW_ACCOMMODATION_PERIOD") > 0 Then
			j = vServices.IndexOf(vSrvRow);
			While j < vServices.Count() Do
				vClientSrvRow = vServices.Get(j);
				If (vClientSrvRow.Client <> vCurClient Or vClientSrvRow.NumberOfPersons <> vCurNumberOfPersons Or 
				    vClientSrvRow.AccommodationType <> vCurAccommodationType Or vClientSrvRow.RoomType <> vCurRoomType Or
				    vClientSrvRow.Room <> vCurRoom Or vClientSrvRow.Resource <> vCurResource) Then
					Break;
				EndIf;
				If ValueIsFilled(vClientSrvRow.DateTimeFrom) Then
					vCurDateTimeFrom = Min(vCurDateTimeFrom, vClientSrvRow.DateTimeFrom);
				EndIf;
				If ValueIsFilled(vClientSrvRow.DateTimeTo) Then
					vCurDateTimeTo = Max(vCurDateTimeTo, vClientSrvRow.DateTimeTo);
				EndIf;
				j = j + 1;
			EndDo;
			j = vServices.IndexOf(vSrvRow);
			While j >= 0 Do
				vClientSrvRow = vServices.Get(j);
				If (vClientSrvRow.Client <> vCurClient Or vClientSrvRow.NumberOfPersons <> vCurNumberOfPersons Or 
				    vClientSrvRow.AccommodationType <> vCurAccommodationType Or vClientSrvRow.RoomType <> vCurRoomType Or
				    vClientSrvRow.Room <> vCurRoom Or vClientSrvRow.Resource <> vCurResource) Then
					Break;
				EndIf;
				If ValueIsFilled(vClientSrvRow.DateTimeFrom) Then
					vCurDateTimeFrom = Min(vCurDateTimeFrom, vClientSrvRow.DateTimeFrom);
				EndIf;
				If ValueIsFilled(vClientSrvRow.DateTimeTo) Then
					vCurDateTimeTo = Max(vCurDateTimeTo, vClientSrvRow.DateTimeTo);
				EndIf;
				j = j - 1;
			EndDo;
			If ValueIsFilled(vCurDateTimeFrom) And ValueIsFilled(vCurDateTimeTo) Then
				If BegOfDay(vCurDateTimeFrom) < BegOfDay(vCurDateTimeTo) Then
					vCurPeriodPresentation = Format(BegOfDay(vCurDateTimeFrom), "DF=dd.MM.yyyy") + " - " + Format(BegOfDay(vCurDateTimeTo), "DF=dd.MM.yyyy");
				Else
					vCurPeriodPresentation = Format(BegOfDay(vCurDateTimeFrom), "DF=dd.MM.yyyy");
				EndIf;
			EndIf;
		EndIf;
		// Build client description string
		mClient = "";
		If ValueIsFilled(vCurClient) Then
			mClient = TrimAll(TrimAll(vCurClient.LastName) + " " + TrimAll(vCurClient.FirstName) + " " + TrimAll(vCurClient.SecondName));
		EndIf;
		vRStr = "";
		If ValueIsFilled(vSrvRow.Room) And ValueIsFilled(vSrvRow.RoomType) And TypeOf(vSrvRow.Room) = Type("CatalogRef.Rooms") Then
			If Find(vParameter, "NO_ROOM") = 0 Then
				vRStr = vRStr + TrimAll(vSrvRow.Room.Description) + " ";
			EndIf;
			If Find(vParameter, "NO_RTYPE") = 0 Then
				vRStr = vRStr + vSrvRow.RoomType.GetObject().pmGetRoomTypeDescription(SelLanguage);
			EndIf;
		ElsIf ValueIsFilled(vSrvRow.RoomType) Then
			If Find(vParameter, "NO_RTYPE") = 0 Then
				vRStr = vSrvRow.RoomType.GetObject().pmGetRoomTypeDescription(SelLanguage);
			EndIf;
		ElsIf ValueIsFilled(vSrvRow.Resource) Then
			If Find(vParameter, "NO_RESOURCE") = 0 Then
				vRStr = vSrvRow.Resource.GetObject().pmGetResourceDescription(SelLanguage);
			EndIf;
		EndIf;
		If ValueIsFilled(vCurAccommodationType) Then
			If Find(vParameter, "SHOW_ACCOMMODATION_TYPE") > 0 Then
				vRStr = vRStr + ", " + TrimAll(vCurAccommodationType.GetObject().pmGetAccommodationTypeDescription(SelLanguage));
			EndIf;
		EndIf;
		If Not IsBlankString(vCurPeriodPresentation) Then
			If Find(vParameter, "SHOW_ACCOMMODATION_PERIOD") > 0 Then
				vRStr = vRStr + ", " + TrimAll(vCurPeriodPresentation);
			EndIf;
		EndIf;
		vAccTmplStr = "";
		If Find(vParameter, "SHOW_PAX") <> 0 Then
			If ValueIsFilled(SelInvoice.ParentDoc) Then
				vParentDoc = SelInvoice.ParentDoc;
				If TypeOf(vParentDoc) = Type("DocumentRef.Folio") And ValueIsFilled(vParentDoc.ParentDoc) Then
					vParentDoc = vParentDoc.ParentDoc;
				EndIf;
				If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") And ValueIsFilled(vParentDoc.AccommodationTemplate) Then
					vAccTmplStr = TrimAll(vParentDoc.AccommodationTemplate);
				ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Reservation") And ValueIsFilled(vParentDoc.AccommodationTemplate) Then
					vAccTmplStr = TrimAll(vParentDoc.AccommodationTemplate);
				ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") And vParentDoc.NumberOfPersons <> 0 Then
					vAccTmplStr = TrimAll(vParentDoc.NumberOfPersons) + NStr("en=' pax'; ru=' чел.'; de=' pers.'");
				EndIf;
			EndIf;
		EndIf;
		mClient = mClient + 
		          ?(IsBlankString(vRStr), "" , ", " + TrimAll(vRStr)) +  
		          ?(IsBlankString(vAccTmplStr), "" , ", " + TrimAll(vAccTmplStr));
		If Left(mClient, 1) = "," Then
			mClient = Mid(mClient, 3);
		EndIf;
		// Print client header if necessary
		If mClient <> vCurMClient And (Find(SelGroupBy, "PerClient") > 0 Or IsBlankString(SelGroupBy)) Then
			vCurMClient = mClient;
			// Set client area parameters
			vClient.Parameters.mClient = mClient;
			// Put client area
			vSpreadsheet.Put(vClient);
		EndIf;
		// Fill row parameters
		mAccountingDate = Format(vSrvRow.AccountingDate, "DF=dd.MM.yy");
		mPrice = vSrvRow.Price;
		mDescription = TrimAll(vSrvRow.Remarks);
		If vShowDiscounts Then
			mSum = vSrvRow.Sum + vSrvRow.DiscountSum;
		Else
			mSum = vSrvRow.Sum;
		EndIf;
		If vSrvRow.RoomQuantity <> 0 And 
		   ValueIsFilled(vAccommodationService) And vSrvRow.Service = vAccommodationService And 
		   vSrvRow.RoomQuantity > 1 Then
			mQuantity = Format(vSrvRow.RoomQuantity, "ND=10; NFD=0; NG=") + "*" + vSrvRow.Service.GetObject().pmGetServiceQuantityPresentation(vSrvRow.Quantity/vSrvRow.RoomQuantity, SelLanguage);
		Else
			If Round(vSrvRow.Quantity, 3) <> vSrvRow.Quantity Then
				mQuantity = ?(vSrvRow.Quantity = 0, "", Format(vSrvRow.Quantity, "ND=17; NFD=3"));
			Else
				mQuantity = ?(vSrvRow.Quantity = 0, "", String(vSrvRow.Quantity));
			EndIf;
			If ValueIsFilled(vSrvRow.Service) Then
				If vSrvRow.Quantity <> 0 Then
					vServiceObj = vSrvRow.Service.GetObject();
					mQuantity = vServiceObj.pmGetServiceQuantityPresentation(vSrvRow.Quantity, SelLanguage);
				EndIf;
			EndIf;
		EndIf;
		If ExtraInvoice Then
			If Services.Count() = 1 Then
				If vSrvRow.Quantity = 1 Then
					mQuantity = Format(vSrvRow.Quantity, "ND=17; NFD=0");
				EndIf;
			EndIf;
		EndIf;
		
		// Set parameters
		If SelGroupBy <> "InPrice" And SelGroupBy <> "InPricePerClient" And SelGroupBy <> "All" And SelGroupBy <> "AllPerClient" And SelGroupBy <> "PerClient" And SelGroupBy <> "ByService" Then
			vRow.Parameters.mAccountingDate = mAccountingDate;
		EndIf;
		vRow.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
		vRow.Parameters.mQuantity = mQuantity;
		If SelGroupBy = "InPricePerClient" Or SelGroupBy = "AllPerClient" Or SelGroupBy = "PerClient" Then
			vRow.Parameters.mDescription = Chars.Tab + StrReplace(mDescription, Chars.LF, Chars.LF + Chars.Tab + Chars.Tab);
		Else
			vRow.Parameters.mDescription = mDescription;
		EndIf;
		vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
		// Put row
		If Not IsBlankString(vRow.Parameters.mSum) Then
			// Check if we can print footer completely
			If (vServices.IndexOf(vSrvRow) + 1) = vServices.Count() Then
				vFooterAreas.Insert(0, vRow);
				If Not vSpreadsheet.CheckPut(vFooterAreas) Then
					vSpreadsheet.PutHorizontalPageBreak();
					vSpreadsheet.Put(vTableHeader);
				EndIf;
				vFooterAreas.Delete(0);
			Else
				If Not vSpreadsheet.CheckPut(vRow) Then
					vSpreadsheet.PutHorizontalPageBreak();
					vSpreadsheet.Put(vTableHeader);
				EndIf;
			EndIf;
			vSpreadsheet.Put(vRow);
		EndIf;
	EndDo;
	
	// Put footer areas
	For Each vFooterArea In vFooterAreas Do
		vSpreadsheet.Put(vFooterArea);
	EndDo;

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // pmPrintInvoice

// -----------------------------------------------------------------------------
Procedure pmPrintInvoiceSimple(vSpreadsheet, SelLanguage, SelGroupBy, SelObjectPrintForm, mInvoiceNumber, pClear = True) Export
	SelInvoice = ThisObject;
	If IsBlankString(SelGroupBy) And ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		SelGroupBy = TrimAll(SelObjectPrintForm.Parameter);
	EndIf;
	// Basic checks
	vHotel = SelInvoice.Hotel;
	If Not ValueIsFilled(vHotel) Then
		Raise NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'");
	EndIf;
	vCompany = SelInvoice.Company;
	If Not ValueIsFilled(vCompany) Then
		Raise NStr("ru='Не задана фирма!';de='Die Firma ist nicht angegeben!';en='Company should be filled!'");
	EndIf;
	vAccount = SelInvoice.BankAccount;
	If Not ValueIsFilled(vAccount) Then
		vAccount = vCompany.BankAccount;
	EndIf;
	If Not ValueIsFilled(vAccount) Then
		Raise NStr("ru='Не задан расчетный счет фирмы!';de='Das Verrechnungskonto der Firma ist nicht angegeben!';en='Company account should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) AND ValueIsFilled(SelInvoice.AccountingCustomer) Then
		SelLanguage = SelInvoice.AccountingCustomer.Language;
	EndIf;	
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	If pClear Then
		vSpreadsheet.Clear();
	EndIf;
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = SelInvoice.GetTemplate("InvoiceSimpleEn");
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplate = SelInvoice.GetTemplate("InvoiceSimpleDe");
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = SelInvoice.GetTemplate("InvoiceSimpleRu");
		Else
			Raise NStr("ru='Не найден шаблон печатной формы счета для языка " + SelLanguage.Code + "!'; 
			           |de='No invoice print form template found for the " + SelLanguage.Code + " language!'; 
			           |en='No invoice print form template found for the " + SelLanguage.Code + " language!'");
		EndIf;
	Else
		vTemplate = SelInvoice.GetTemplate("InvoiceSimpleRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Print form parameter
	vParameter = Upper(TrimAll(SelObjectPrintForm.Parameter));
	vShowDiscounts = (Find(vParameter, "SHOW_DISCOUNT") > 0);
	vDoNotUseSectionVAT = (Find(vParameter, "DO_NOT_USE_SECTION_VAT") > 0);
	vPrintQRCode = (Find(vParameter, "SHOW_QRCODE") > 0);
	vIgnoreVATRate = (Find(vParameter, "IGNORE_VATRATE_ON_GROUPING") > 0);
	vDoNotShowPayDueDate = (Find(vParameter, "DO_NOT_SHOW_PAY_DUE_DATE") > 0);
	
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(SelInvoice.Hotel) Then
		If SelInvoice.Hotel.Logo <> Undefined Then
			vLogo = SelInvoice.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vStampIsSet = False;
	vStamp = New Picture;
	If ValueIsFilled(SelInvoice.Company) Then
		If SelInvoice.Company.Stamp <> Undefined Then
			vStamp = SelInvoice.Company.Stamp.Get();
			If vStamp = Undefined Then
				vStamp = New Picture;
			Else
				vStampIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vSignatureIsSet = False;
	vSignature = New Picture;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If SessionParameters.CurrentUser.Signature <> Undefined Then
			vSignature = SessionParameters.CurrentUser.Signature.Get();
			If vSignature = Undefined Then
				vSignature = New Picture;
			Else
				vSignatureIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vDirectorSignatureIsSet = False;
	vDirectorSignature = New Picture;
	If SelInvoice.Company.DirectorSignature <> Undefined Then
		vDirectorSignature = SelInvoice.Company.DirectorSignature.Get();
		If vDirectorSignature = Undefined Then
			vDirectorSignature = New Picture;
		Else
			vDirectorSignatureIsSet = True;
		EndIf;
	EndIf;
	vAccountantGeneralSignatureIsSet = False;
	vAccountantGeneralSignature = New Picture;
	If SelInvoice.Company.AccountantGeneralSignature <> Undefined Then
		vAccountantGeneralSignature = SelInvoice.Company.AccountantGeneralSignature.Get();
		If vAccountantGeneralSignature = Undefined Then
			vAccountantGeneralSignature = New Picture;
		Else
			vAccountantGeneralSignatureIsSet = True;
		EndIf;
	EndIf;
	
	// Header
	vRubHeader = False;
	If SelInvoice.AccountingCurrency.Code = 643 And vHotel.Citizenship.Code = 643 Then
		vRubHeader = True;
	EndIf;
	
	// Hotel
	mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, SelLanguage);
	mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, SelLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vHotelFax);
	mHotelEMail = TrimAll(vHotel.EMail);
	
	// Company
	vCompanyObj = vCompany.GetObject();
	vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
	vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
	vCompanyPostAddress = vCompanyObj.pmGetCompanyPostAddressPresentation(SelLanguage);
	If vCompanyPostAddress = vCompanyLegacyAddress Then
		vCompanyPostAddress = "";
	EndIf;
	mCompanyTIN = TrimAll(vCompany.TIN);
	mCompanyVATCode = TrimAll(vCompany.VATC);
	mCompanyKPP = TrimAll(vCompany.KPP);
	mCompanyCBC = TrimAll(vCompany.KBK);
	mCompanyOKTMO = TrimAll(vCompany.OKTMO);
	vCompanyTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН ';lv=', Reg. N '", SelLanguage) + ?(IsBlankString(mCompanyKPP), " ", "/" + cmNStr("en='KPP ';de='KPP ';ru='КПП '", SelLanguage)) + mCompanyTIN + ?(IsBlankString(mCompanyKPP), "", "/" + mCompanyKPP) + 
	              ?(IsBlankString(mCompanyVATCode), "", cmNStr("en=', VAT code ';de=', Mw.St. code ';ru=', код НДС ';lv=', PVN '", SelLanguage) + mCompanyVATCode);
	vCompanyPhones = TrimAll(vCompany.Phones) + ?(IsBlankString(vCompany.Fax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + TrimAll(vCompany.Fax));
	mCompany = TrimAll(vCompanyLegacyName + vCompanyTIN + Chars.LF + vCompanyLegacyAddress + Chars.LF + ?(IsBlankString(vCompanyPostAddress), "", vCompanyPostAddress + Chars.LF) + vCompanyPhones);
	
	// Invoice date and number
	If vCompany.UseGroupCodeAsInvoiceNumberPrefix Then
		If vCompany.PrintInvoiceAndSettlementNumbersWithPrefixes Then
			vCompanyPrefix = TrimAll(vCompany.Prefix);
			If Not IsBlankString(vCompanyPrefix) Then
				mInvoiceNumber = vCompanyPrefix + cmRemoveLeadingZeroes(SelInvoice.Number);
			Else
				mInvoiceNumber = cmRemoveLeadingZeroes(SelInvoice.Number);
			EndIf;
		Else
			vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelInvoice.Hotel);
			If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
				mInvoiceNumber = vHotelPrefix + cmRemoveLeadingZeroes(SelInvoice.Number);
			Else
				mInvoiceNumber = cmRemoveLeadingZeroes(SelInvoice.Number);
			EndIf;
		EndIf;
	Else
		mInvoiceNumber = ?(vCompany.PrintInvoiceAndSettlementNumbersWithPrefixes, TrimAll(SelInvoice.Number), cmGetDocumentNumberPresentation(SelInvoice.Number));
	EndIf;
	mInvoiceDate = cmGetDocumentDatePresentation(SelInvoice.Date);
	
	vTableHeader = vTemplate.GetArea("TableHeader");
	
	// Print different invoice headers for invoices in RUR and Russia base country and other currencies/countries
	If vRubHeader Then
		vHeader = vTemplate.GetArea("Header");
		
		mCompanyPaymentAttributes = vCompanyLegacyName;
		mCompanyBank = "";
		mCompanyBankAcount = "";
		mCompanyBankBIC = "";
		mCompanyBankCorrAccount = "";
		If vAccount.IsDirectPayments Then
			mCompanyBank = TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity);
			
			mCompanyBankAccount = TrimAll(vAccount.AccountNumber);
			mCompanyBankBIC = TrimAll(vAccount.BankBIC);
			mCompanyBankCorrAccount = TrimAll(vAccount.BankCorrAccountNumber);
		Else
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + cmNStr("en=' acc ';ru=' р/с ';de=' verrechnungskonto '", SelLanguage) + TrimAll(vAccount.AccountNumber);
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + cmNStr("en=' in ';ru=' в ';de=' in '", SelLanguage) + TrimAll(vAccount.BankName);
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + " " + TrimAll(vAccount.BankCity);
		
			mCompanyBank = TrimAll(vAccount.CorrBankName);
			mCompanyBank = mCompanyBank + TrimAll(vAccount.CorrBankCity);
			
			mCompanyBankAccount = TrimAll(vAccount.BankCorrAccountNumber);
			mCompanyBankBIC = TrimAll(vAccount.CorrBankBIC);
			mCompanyBankCorrAccount = TrimAll(vAccount.CorrBankCorrAccountNumber);
		EndIf;
		If Not IsBlankString(vAccount.Beneficiary) Then
			mCompanyPaymentAttributes = TrimAll(vAccount.Beneficiary);
		EndIf;
		
		vStructOKTMO_KBK = New Structure("mOKTMO, mKBK", "", "");
		If Not IsBlankString(vCompany.OKTMO) Or Not IsBlankString(vCompany.KBK) Then
			If Not IsBlankString(vCompany.OKTMO) Then
				vStructOKTMO_KBK.mOKTMO = TrimAll(vCompany.OKTMO);
			EndIf;
			If Not IsBlankString(vCompany.KBK) Then
				vStructOKTMO_KBK.mKBK = TrimAll(vCompany.KBK);
			EndIf; 
		EndIf; 
		
		// Customer
		vCustomerCode = "";
		If SelInvoice.AccountingCustomer = vHotel.IndividualsCustomer Then
			// Use contact person as customer
			If Not IsBlankString(SelInvoice.ContactPerson) Then
				mCustomer = TrimAll(SelInvoice.ContactPerson);
			Else
				vClientRef = Catalogs.Clients.EmptyRef();
				// Use guest group client as customer
				If ValueIsFilled(SelInvoice.GuestGroup) And ValueIsFilled(SelInvoice.GuestGroup.Client) Then
					vClientRef = SelInvoice.GuestGroup.Client;
				// Use first client as customer
				Else
					For Each vRow In SelInvoice.Services Do
						If ValueIsFilled(vRow.Client) Then
							vClientRef = vRow.Client;
							Break;
						EndIf;
					EndDo;
				EndIf;
				vCustomer = vClientRef;
				vCustomerLegacyName = "";
				vCustomerLegacyAddress = "";
				vCustomerTIN = "";
				vCustomerPhones = "";
				If ValueIsFilled(vClientRef) Then
					vCustomerLegacyName = TrimAll(vClientRef.FullName);
					vCustomerLegacyAddress = cmGetAddressPresentation(vClientRef.Address);
					vCustomerTIN = "";
					vCustomerKPP = "";
					// Fax and E-Mail
					vCustomerPhones = TrimAll(vClientRef.Phone);
					vCustomerFax = TrimAll(vClientRef.Fax);
					vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
				EndIf;
				mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + vCustomerPhones);
			EndIf;
			// Contract
			mContract = "";
		Else
			vCustomer = SelInvoice.AccountingCustomer;
			vCustomerLegacyName = "";
			vCustomerLegacyAddress = "";
			vCustomerPostAddress = "";
			vCustomerTIN = "";
			vCustomerVATCode = "";
			vCustomerPhones = "";
			If ValueIsFilled(vCustomer) Then
				vCustomerLegacyName = TrimAll(vCustomer.LegacyName);
				If IsBlankString(vCustomerLegacyName) Then
					vCustomerLegacyName = TrimAll(vCustomer.Description);
				EndIf;
				If Not vCustomer.IsIndividual Then
					vCustomerCode = TrimAll(vCustomer.Code);
				EndIf;
				
				// Addresses
				vCustomerLegacyAddress = cmGetAddressPresentation(vCustomer.LegacyAddress);
				vCustomerPostAddress = cmGetAddressPresentation(vCustomer.PostAddress);
				If vCustomerPostAddress = vCustomerLegacyAddress Then
					vCustomerPostAddress = "";
				EndIf;
				
				// Codes
				vCustomerTIN = TrimAll(vCustomer.TIN);
				vCustomerVATCode = TrimAll(vCustomer.VATC);
				vCustomerKPP = TrimAll(vCustomer.KPP);
				vCustomerTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН '", SelLanguage) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP) + 
				               ?(IsBlankString(vCustomerVATCode), "", cmNStr("en=', VAT code ';de=', Mw.St. code ';ru=', код НДС ';lv=', PVN '", SelLanguage) + vCustomerVATCode);
							   
				// Fax and E-Mail
				vCustomerPhones = TrimAll(vCustomer.Phone);
				vCustomerFax = TrimAll(vCustomer.Fax);
				vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
			EndIf;
			mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + vCustomerPhones);
			// Contract
			mContract = "";
			If ValueIsFilled(SelInvoice.AccountingContract) Then
				mContract = TrimAll(SelInvoice.AccountingContract.Description);
			EndIf;
		EndIf;
		// Guest group code
		mGuestGroup = "";
		vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelInvoice.Hotel);
		If ValueIsFilled(SelInvoice.GuestGroup) Then
			mGuestGroup = Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=");
			If Not IsBlankString(SelInvoice.GuestGroup.ID) Then
				mGuestGroup = mGuestGroup + " - Ref. # " + TrimAll(SelInvoice.GuestGroup.ID);
			ElsIf Not IsBlankString(SelInvoice.GuestGroup.Description) Then
				mGuestGroup = mGuestGroup + " - " + TrimAll(SelInvoice.GuestGroup.Description);
			EndIf;
			If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
				mGuestGroup = vHotelPrefix + mGuestGroup;
			EndIf;
		Else
			vGroups = SelInvoice.Services.Unload(, "GuestGroup");
			vGroups.GroupBy("GuestGroup", );
			For Each vGroupsRow In vGroups Do
				If ValueIsFilled(vGroupsRow.GuestGroup) Then
					vGuestGroupCode = Format(vGroupsRow.GuestGroup.Code, "ND=12; NFD=0; NG=");
					If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
						vGuestGroupCode = vHotelPrefix + vGuestGroupCode;
					EndIf;
					If IsBlankString(mGuestGroup) Then
						mGuestGroup = vGuestGroupCode;
					Else
						mGuestGroup = mGuestGroup + ", " + vGuestGroupCode;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Currency
		mAccountingCurrency = "";
		If ValueIsFilled(SelInvoice.AccountingCurrency) Then
			vCurrencyObj = SelInvoice.AccountingCurrency.GetObject();
			mAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
		EndIf;
		// Parent document
		mParentDoc = ?(ValueIsFilled(SelInvoice.ParentDoc), TrimAll(SelInvoice.ParentDoc.Number), "");
		// Set parameters and put report section
		vHeader.Parameters.mHotelPrintName = mHotelPrintName;
		vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
		vHeader.Parameters.mHotelPhones = mHotelPhones;
		vHeader.Parameters.mHotelEMail = mHotelEMail;
		vHeader.Parameters.mInvoiceNumber = mInvoiceNumber;
		vHeader.Parameters.mInvoiceDate = mInvoiceDate;
		If SelInvoice.AccountingCurrency = vHotel.BaseCurrency Then
			vHeader.Parameters.mCompany = mCompany;
			vHeader.Parameters.mCompanyTIN = mCompanyTIN;
			vHeader.Parameters.mCompanyKPP = mCompanyKPP;
			vHeader.Parameters.mCompanyBankBIC = mCompanyBankBIC;
			vHeader.Parameters.mCompanyBankCorrAccount = mCompanyBankCorrAccount;
		EndIf;
		vHeader.Parameters.mCompanyPaymentAttributes = mCompanyPaymentAttributes;
		vHeader.Parameters.mCompanyBank = mCompanyBank;
		vHeader.Parameters.mCompanyBankAccount = mCompanyBankAccount;
		vHeader.Parameters.mCustomer = mCustomer;
		vHeader.Parameters.mInvoiceEMail = TrimAll(SelInvoice.EMail);
		vHeader.Parameters.mContract = mContract;
		vHeader.Parameters.mGuestGroup = mGuestGroup;
		vHeader.Parameters.mAccountingCurrency = mAccountingCurrency;
		vHeader.Parameters.mParentDoc = mParentDoc;
		// Logo
		If vLogoIsSet Then
			vHeader.Drawings.Logo.Print = True;
			vHeader.Drawings.Logo.Picture = vLogo;
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.Logo);
		EndIf;
		
		// Genarate QR-Code
		If vPrintQRCode Then
			vServices = SelInvoice.Services.Unload();
			vTotalSum = 0;
			vTotalVATSum = vServices.Total("VATSum");
			vTotalCommissionSum = 0;
			If vServices <> Undefined Then
				vTotalSum = vServices.Total("Sum");
				vTotalCommissionSum = vServices.Total("CommissionSum");
				If vTotalCommissionSum <> 0 And 
					ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
					vTotalSum = vTotalSum - vTotalCommissionSum;
				EndIf;
			EndIf;

			// Payment text
			mPaymentText = NStr("en='Payment for invoice N';ru='Оплата счета №';de='Bezahlung der Rechnung Nr.'", SelLanguage) + cmGetDocumentNumberPresentation(SelInvoice.Number) + 
			               NStr("en=', reservation confirmation N';de=', reservation confirmation N';ru=', подтверждение брони №'", SelLanguage) + mGuestGroup + ".";

			vStructOutputData = New Structure;
			vStructOutputData.Insert("Name", 		mCompany);
			vStructOutputData.Insert("PersonalAcc", mCompanyBankAccount);
			vStructOutputData.Insert("CorrespAcc", 	mCompanyBankCorrAccount);
			vStructOutputData.Insert("BankName", 	mCompanyBank);
			vStructOutputData.Insert("BIC", 		mCompanyBankBIC);
			vStructOutputData.Insert("PayeeINN", 	mCompanyTIN);
			vStructOutputData.Insert("CBC", 		mCompanyCBC);
			vStructOutputData.Insert("OKTMO", 		mCompanyOKTMO);
			vStructOutputData.Insert("KPP", 		mCompanyKPP);
			vStructOutputData.Insert("Sum", 		vTotalSum);
			vStructOutputData.Insert("Purpose", 	mPaymentText);
			
			vQRCodeString =  tcCommonFunctions.cmGenerateBankFormattedString(vStructOutputData);
			If Not IsBlankString(vQRCodeString) Then
				Try
					vQRCodePic =  cmGetQRCodePicture(vQRCodeString);
					vQRCodeControl = vHeader.Drawings.QRCodeControl;
					vQRCodeControl.Picture = vQRCodePic;
				Except
					tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Failed to generate a QR code, possibly no internet connection'; de = 'Fehler beim Erzeugen eines QR-Codes, möglicherweise keine Internetverbindung'; ru = 'Не удалось сформировать QR-code, возможно отсутствует соединение с интернетом'"));
				EndTry;	
			EndIf;
		EndIf;

		// Put header
		FillPropertyValues(vHeader.Parameters, vStructOKTMO_KBK);  
		vSpreadsheet.Put(vHeader);
		vSpreadsheet.Put(vTableHeader);
	Else
		vHeader1 = vTemplate.GetArea("HeaderCurrency1");
		
		If Not IsBlankString(vAccount.Beneficiary) Then
			mCompany = TrimAll(vAccount.Beneficiary);
		EndIf;
		
		mCompanyBank = TrimAll(TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity));
		mCompanyBankAccount = TrimAll(vAccount.AccountNumber);
		If Not IsBlankString(vAccount.BankBIC) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='BIC ';ru='БИК ';de='BIC '", SelLanguage) + TrimAll(vAccount.BankBIC);
		EndIf;
		If Not IsBlankString(vAccount.BankCorrAccountNumber) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='Corr. acc. № ';ru='Корр. сч. № ';de='Korrespondenzkonto Nr. '", SelLanguage) + TrimAll(vAccount.BankCorrAccountNumber);
		EndIf;
		If Not IsBlankString(vAccount.BankTINCode) Then
			mCompanyBank = mCompanyBank + Chars.LF + TrimAll(vAccount.BankTINCode);
		EndIf;
		If Not IsBlankString(vAccount.BankIBAN) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='IBAN CODE ';de='IBAN CODE ';ru='IBAN CODE '", SelLanguage) + TrimAll(vAccount.BankIBAN);
		EndIf;
		If Not IsBlankString(vAccount.BankSWIFTCode) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='SWIFT CODE ';de='SWIFT CODE ';ru='SWIFT CODE '", SelLanguage) + TrimAll(vAccount.BankSWIFTCode);
		EndIf;
		
		// Set parameters and put report section
		vHeader1.Parameters.mHotelPrintName = mHotelPrintName;
		vHeader1.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
		vHeader1.Parameters.mHotelPhones = mHotelPhones;
		vHeader1.Parameters.mHotelEMail = mHotelEMail;
		vHeader1.Parameters.mInvoiceNumber = mInvoiceNumber;
		vHeader1.Parameters.mInvoiceDate = mInvoiceDate;
		vHeader1.Parameters.mCompany = mCompany;
		vHeader1.Parameters.mCompanyBankAccount = mCompanyBankAccount;
		vHeader1.Parameters.mCompanyBank = mCompanyBank;
		// Logo
		If vLogoIsSet Then
			vHeader1.Drawings.LogoCurrency.Print = True;
			vHeader1.Drawings.LogoCurrency.Picture = vLogo;
		Else
			vHeader1.Drawings.Delete(vHeader1.Drawings.LogoCurrency);
		EndIf;
		// Put header1		
		vSpreadsheet.Put(vHeader1);
		
		// Put correspondent bank header
		If Not vAccount.IsDirectPayments Then
			vCorrBankHeader = vTemplate.GetArea("CorrBank");
			
			mCompanyCorrBank = TrimAll(TrimAll(vAccount.CorrBankName) + " " + TrimAll(vAccount.CorrBankCity));
			If Not IsBlankString(vAccount.CorrBankBIC) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='BIC ';ru='БИК ';de='BIC '", SelLanguage) + TrimAll(vAccount.CorrBankBIC);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankCorrAccountNumber) Then
				mCompanyCorrBank = mCompanyCorrBank + cmNStr("en='Corr. acc. № ';ru='Корр. сч. № ';de='Korrespondenzkonto Nr. '", SelLanguage) + TrimAll(vAccount.CorrBankCorrAccountNumber);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankTINCode) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + TrimAll(vAccount.CorrBankTINCode);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankIBAN) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='IBAN CODE ';de='IBAN CODE ';RU='IBAN CODE '", SelLanguage) + TrimAll(vAccount.CorrBankIBAN);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankSWIFTCode) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='SWIFT CODE ';de='SWIFT CODE ';RU='SWIFT CODE '", SelLanguage) + TrimAll(vAccount.CorrBankSWIFTCode);
			EndIf;
			
			// Set parameters and put report section
			vCorrBankHeader.Parameters.mCompanyCorrBank = mCompanyCorrBank;
			
			// Put corr. bank header
			vSpreadsheet.Put(vCorrBankHeader);
		EndIf;
		
		// Table header
		vHeader2 = vTemplate.GetArea("HeaderCurrency2");
		
		// Customer
		vCustomerCode = "";
		If SelInvoice.AccountingCustomer = vHotel.IndividualsCustomer Then
			// Use contact person as customer
			If Not IsBlankString(SelInvoice.ContactPerson) Then
				mCustomer = TrimAll(SelInvoice.ContactPerson);
			Else				
				vClientRef = Catalogs.Clients.EmptyRef();
				// Use guest group client as customer
				If ValueIsFilled(SelInvoice.GuestGroup) And ValueIsFilled(SelInvoice.GuestGroup.Client) Then
					vClientRef = SelInvoice.GuestGroup.Client;
				// Use first client as customer
				Else
					For Each vRow In SelInvoice.Services Do
						If ValueIsFilled(vRow.Client) Then
							vClientRef = vRow.Client;
							Break;
						EndIf;
					EndDo;
				EndIf;
				vCustomer = vClientRef;
				vCustomerLegacyName = "";
				vCustomerLegacyAddress = "";
				vCustomerTIN = "";
				vCustomerPhones = "";
				If ValueIsFilled(vClientRef) Then
					vCustomerLegacyName = TrimAll(vClientRef.FullName);
					vCustomerLegacyAddress = cmGetAddressPresentation(vClientRef.Address);
					vCustomerTIN = "";
					vCustomerKPP = "";
					// Fax and E-Mail
					vCustomerPhones = TrimAll(vClientRef.Phone);
					vCustomerFax = TrimAll(vClientRef.Fax);
					vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
				EndIf;
				mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + vCustomerPhones);
			EndIf;
			// Contract
			mContract = "";
		Else
			vCustomer = SelInvoice.AccountingCustomer;
			vCustomerLegacyName = "";
			vCustomerLegacyAddress = "";
			vCustomerPostAddress = "";
			vCustomerTIN = "";
			vCustomerVATCode = "";
			vCustomerPhones = "";
			If ValueIsFilled(vCustomer) Then
				vCustomerLegacyName = TrimAll(vCustomer.LegacyName);
				If IsBlankString(vCustomerLegacyName) Then
					vCustomerLegacyName = TrimAll(vCustomer.Description);
				EndIf;
				If Not vCustomer.IsIndividual Then
					vCustomerCode = TrimAll(vCustomer.Code);
				EndIf;
				
				// Addresses
				vCustomerPostAddress = "";
				vAddressStruct = cmParseAddress(vCustomer.LegacyAddress);
				vCustomerLegacyAddress = TrimAll(vAddressStruct.Region + " " + vAddressStruct.Area) + Chars.LF +
				                         TrimAll(vAddressStruct.Street + " " + vAddressStruct.House + " " + vAddressStruct.Flat) + Chars.LF +
										 TrimAll(vAddressStruct.PostCode + " " + vAddressStruct.City) + Chars.LF + 
										 TrimAll(vAddressStruct.Country);

				If Not IsBlankString(vCustomer.PostAddress) And TrimAll(vCustomer.PostAddress) <> TrimAll(vCustomer.LegacyAddress) Then
					vAddressStruct = cmParseAddress(vCustomer.PostAddress);
					vCustomerPostAddress = TrimAll(vAddressStruct.Region + " " + vAddressStruct.Area) + Chars.LF +
					                       TrimAll(vAddressStruct.Street + " " + vAddressStruct.House + " " + vAddressStruct.Flat) + Chars.LF +
										   TrimAll(vAddressStruct.PostCode + " " + vAddressStruct.City) + Chars.LF + 
										   TrimAll(vAddressStruct.Country);
				EndIf;
				
				// Codes
				vCustomerTIN = TrimAll(vCustomer.TIN);
				vCustomerKPP = TrimAll(vCustomer.KPP);
				vCustomerVATCode = TrimAll(vCustomer.VATC);
				vCustomerTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН '", SelLanguage) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP) + 
				               ?(IsBlankString(vCustomerVATCode), "", cmNStr("en=', VAT code ';de=', Mw.St. code ';ru=', код НДС ';lv=', PVN '", SelLanguage) + vCustomerVATCode);
							   
				// Fax and E-Mail
				vCustomerPhones = TrimAll(vCustomer.Phone);
				vCustomerFax = TrimAll(vCustomer.Fax);
				vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
			EndIf;
			mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + vCustomerPhones);
			// Contract
			mContract = "";
			If ValueIsFilled(SelInvoice.AccountingContract) Then
				mContract = TrimAll(SelInvoice.AccountingContract.Description);
			EndIf;
		EndIf;
		// Guest group code
		mGuestGroup = "";
		If ValueIsFilled(SelInvoice.GuestGroup) Then
			mGuestGroup = Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=");
			If Not IsBlankString(SelInvoice.GuestGroup.ID) Then
				mGuestGroup = mGuestGroup + " - Ref. # " + TrimAll(SelInvoice.GuestGroup.ID);
			ElsIf Not IsBlankString(SelInvoice.GuestGroup.Description) Then
				mGuestGroup = mGuestGroup + " - " + TrimAll(SelInvoice.GuestGroup.Description);
			EndIf;
		Else
			vGroups = SelInvoice.Services.Unload(, "GuestGroup");
			vGroups.GroupBy("GuestGroup", );
			For Each vGroupsRow In vGroups Do
				If ValueIsFilled(vGroupsRow.GuestGroup) Then
					vGuestGroupCode = Format(vGroupsRow.GuestGroup.Code, "ND=12; NFD=0; NG=");
					If IsBlankString(mGuestGroup) Then
						mGuestGroup = vGuestGroupCode;
					Else
						mGuestGroup = mGuestGroup + ", " + vGuestGroupCode;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Currency
		mAccountingCurrency = "";
		If ValueIsFilled(SelInvoice.AccountingCurrency) Then
			vCurrencyObj = SelInvoice.AccountingCurrency.GetObject();
			mAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
		EndIf;
		// Parent document
		mParentDoc = ?(ValueIsFilled(SelInvoice.ParentDoc), TrimAll(SelInvoice.ParentDoc.Number), "");
		mFullInvoiceNumber = Trimall(SelInvoice.Number) + ?(IsBlankString(vCustomerCode), "", " " + vCustomerCode);
		// Set parameters and put report section
		vHeader2.Parameters.mFullInvoiceNumber = mFullInvoiceNumber;
		vHeader2.Parameters.mCustomer = mCustomer;
		vHeader2.Parameters.mInvoiceEMail = TrimAll(SelInvoice.EMail);
		vHeader2.Parameters.mContract = mContract;
		vHeader2.Parameters.mGuestGroup = mGuestGroup;
		vHeader2.Parameters.mAccountingCurrency = mAccountingCurrency;
		vHeader2.Parameters.mParentDoc = mParentDoc;
		// Put header		
		vSpreadsheet.Put(vHeader2);
		vSpreadsheet.Put(vTableHeader);
	EndIf;
	
	// Get all services
	vServices = SelInvoice.Services.Unload();

	vServicesCopy = vServices.Copy();
	
	// Calculate totals
	vAgentCommission = 0;
	vDiscountPercent = 0;
	vTotalSum = 0;
	vTotalSumNoCommission = 0;
	vTotalCommissionSum = 0;
	vTotalDiscountSum = 0;
	vTotalSumToBePaid = 0;
	vTotalVATSumNoCommission = 0;
	vTotalVATSum = 0;
	
	vVATRateTransactions = New ValueTable();
	vVATRateTransactions.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
	vVATRateTransactions.Columns.Add("VATRateCode", cmGetNumberTypeDescription(4, 0));
	vVATRateTransactions.Columns.Add("Sum", cmGetSumTypeDescription());
	vVATRateTransactions.Columns.Add("VATSum", cmGetSumTypeDescription());
	
	vUseSectionVAT = False;
	For Each vSrvRow In vServices Do
		If vAgentCommission = 0 Then
			vAgentCommission = vSrvRow.AgentCommission;
		EndIf;
		If vDiscountPercent = 0 Then
			vDiscountPercent = vSrvRow.Discount;
		EndIf;

		vTotalSum = vTotalSum + vSrvRow.Sum;
		If vShowDiscounts Then
			vTotalSum = vTotalSum + vSrvRow.DiscountSum;
		EndIf;
		vTotalSumToBePaid = vTotalSumToBePaid + vSrvRow.Sum;
		vTotalSumNoCommission = vTotalSumNoCommission + vSrvRow.Sum - vSrvRow.CommissionSum;
		vTotalCommissionSum = vTotalCommissionSum + vSrvRow.CommissionSum;
		vTotalDiscountSum = vTotalDiscountSum + vSrvRow.DiscountSum;
		
		// Get effective VAT rate
		vVATRate = vSrvRow.VATRate;
		If Not vDoNotUseSectionVAT And Not vIgnoreVATRate Then
			If ValueIsFilled(vSrvRow.Service) And ValueIsFilled(vSrvRow.Service.PaymentSection) And ValueIsFilled(vSrvRow.Service.PaymentSection.VATRate) And 
			   vSrvRow.VATRate <> vSrvRow.Service.PaymentSection.VATRate Then
				vVATRate = vSrvRow.Service.PaymentSection.VATRate;
				vUseSectionVAT = True;
			EndIf;
		EndIf;
		vSrvRow.VATRate = vVATRate;
		
		vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
		vTotalVATSum = vTotalVatSum + vSrvRow.VATSum;
		
		vVATRateTransactionsRow = vVATRateTransactions.Add();
		vVATRateTransactionsRow.VATRate = vVATRate;
		vVATRateTransactionsRow.VATRateCode = ?(ValueIsFilled(vVATRate), vVATRate.Code, 0);
		vVATRateTransactionsRow.VATSum = vSrvRow.VATSum;
		vVATRateTransactionsRow.Sum = vSrvRow.Sum;
	EndDo;

	vServices.Sort("Room, RoomType, Resource, Client, DateTimeFrom, AccountingDate, Remarks");
	
   	// Calculate VAT totals
	If Not vUseSectionVAT And Not vIgnoreVATRate Then
		vTotalVATSumNoCommission = 0;
		vTotalVATSum = 0;
		vVATRateTransactions.Clear();
		For Each vSrvRow In vServices Do
			vTotalVATSumNoCommission = vTotalVATSumNoCommission + cmCalculateVATSum(vSrvRow.VATRate, (vSrvRow.Sum - vSrvRow.CommissionSum), vSrvRow.AccountingDate);
			vTotalVATSum = vTotalVatSum + cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
			
			vVATRateTransactionsRow = vVATRateTransactions.Add();
			vVATRateTransactionsRow.VATRate = vSrvRow.VATRate;
			vVATRateTransactionsRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
			vVATRateTransactionsRow.Sum = vSrvRow.Sum;
		EndDo;
	EndIf;

	If ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
		vTotalSumToBePaid = vTotalSumNoCommission;
	EndIf;
	vVATRateTransactions.GroupBy("VATRate, VATRateCode", "Sum, VATSum");
	vVATRateTransactions.Sort("VATRateCode");
	
	// Build footer
	vFooterAreas = new Array();
	vFooter1 = vTemplate.GetArea("Footer1");
	vCommission = vTemplate.GetArea("Commission");
	vDiscount = vTemplate.GetArea("Discount");
	vFooter2 = vTemplate.GetArea("Footer2");
	
	// Fill parameters
	mTotalSum = Format(vTotalSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
	mTotalVATSum = "";
	If Not (ValueIsFilled(vCompany) And vCompany.DoNotPrintVAT) Then
		If vTotalVATSum <> 0 Then
			mTotalVATSum = cmNStr("EN='Including VAT ';RU='В том числе НДС ';de='Darunter MwSt. '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
		Else
			If ValueIsFilled(SelInvoice.Company) And SelInvoice.Company.IsUsingSimpleTaxSystem Then
				mTotalVATSum = cmNStr("en='No VAT';ru='НДС не облагается в связи с применением упрощенной системы налогообложения (п. 2 ст. 346.11 НК РФ)';de='Im Zusammenhang mit der Anwendung des vereinfachten Besteuerungssystems wird die MwSt. nicht berechnet (Punkt 2 Artikel 346.11 des Steuergesetzes der Russischen Föderation)'", SelLanguage);
			Else
				If vVATRateTransactions.Count() > 0 Then
					vRowVatRate = vVATRateTransactions[0].VATRate;
					If ValueIsFilled(vRowVatRate) And Not vRowVatRate.NoVAT And vRowVatRate.TaxRate = 0 Then
						mTotalVATSum = cmNStr("EN='Including VAT ';RU='НДС ';de='Darunter MwSt. '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2; NZ=0.00") + " " + mAccountingCurrency;
					EndIf;	
				Else
					mTotalVATSum = cmNStr("en='No VAT';ru='НДС не облагается';de='MwSt. wird nicht berechnet'", SelLanguage); 
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If SelLanguage = Catalogs.Languages.DE Then
		mTotalVATSum = "";
	EndIf;

	// Set parameters
	vFooter1.Parameters.mTotalSum = mTotalSum;
	vFooter2.Parameters.mTotalVATSum = mTotalVATSum;
	vFooter2.Parameters.mTotalSumInWords = cmSumInWords(vTotalSumToBePaid, SelInvoice.AccountingCurrency, SelLanguage);
	
	// Put footer
	vFooterAreas.Add(vFooter1);
	If vShowDiscounts And vDiscountPercent <> 0 Then
		vDiscount.Parameters.mDiscount = vDiscountPercent;
		vDiscount.Parameters.mTotalDiscountSum = Format(vTotalDiscountSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
		vDiscount.Parameters.mSumToBePaid = Format(vTotalSumToBePaid, "ND=17; NFD=2") + " " + mAccountingCurrency;
		vFooterAreas.Add(vDiscount);
	Else
		If vTotalCommissionSum <> 0 And 
		   ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
			mAgentCommission = "";   
			If ValueIsFilled(SelInvoice.GuestGroup) Then
				mAgentCommission = mAgentCommission + GetAgentCommissionDescription(vAgentCommission, SelInvoice.GuestGroup.ClientDoc, SelLanguage);
			Else
				mAgentCommission = mAgentCommission + vAgentCommission + "%";
			EndIf;
			vCommission.Parameters.mTotalCommissionSum = Format(vTotalCommissionSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
			vCommission.Parameters.mAgentCommission = mAgentCommission;
			vCommission.Parameters.mSumToBePaid = Format(vTotalSumToBePaid, "ND=17; NFD=2") + " " + mAccountingCurrency;
			vFooterAreas.Add(vCommission);
		EndIf;
	EndIf;
	vFooterAreas.Add(vFooter2);
	
	// VAT rates table
	If ValueIsFilled(vCompany) And Not vCompany.IsUsingSimpleTaxSystem Then
		vVATHeaderArea = vTemplate.GetArea("VATHeader");
		vFooterAreas.Add(vVATHeaderArea);
		For Each vVATRateRow In vVATRateTransactions Do
			vVATRateRowArea = vTemplate.GetArea("VATRateRow");
			vVATRateRowArea.Parameters.mVATRate = TrimAll(vVATRateRow.VATRate);
			vVATRateRowArea.Parameters.mSumWithoutVAT = Format(vVATRateRow.Sum - vVATRateRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mVATSum = Format(vVATRateRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mSumWithVAT = Format(vVATRateRow.Sum, "ND=17; NFD=2; NZ=");
			vFooterAreas.Add(vVATRateRowArea);
		EndDo;
	EndIf;
	
	// Signatures
	vSignedByManager = False;
	If ValueIsFilled(SelInvoice.Company) And SelInvoice.Company.InvoiceIsSignedByManager Then
		vSignedByManager = True;
	EndIf;
	If Not vSignedByManager Then
		If SelInvoice.PrintWithCompanyStamp Then
			vSignatures = vTemplate.GetArea("SignaturesWithStamp");
		Else
			vSignatures = vTemplate.GetArea("Signatures");
		EndIf;
		mCompanyDirector = TrimAll(cmNStr(vCompany.Director, SelLanguage));
		If Not IsBlankString(vCompany.DirectorPosition) Then
			mCompanyDirectorPosition = TrimAll(cmNStr(vCompany.DirectorPosition, SelLanguage));
		Else
			mCompanyDirectorPosition = cmNStr("en='Director';ru='Руководитель';de='Leiter'", SelLanguage);
		EndIf;
		mCompanyAccountantGeneral = TrimAll(cmNStr(vCompany.AccountantGeneral, SelLanguage));
		If Not IsBlankString(vCompany.AccountantGeneralPosition) Then
			mCompanyAccountantGeneralPosition = TrimAll(cmNStr(vCompany.AccountantGeneralPosition, SelLanguage));
		Else
			mCompanyAccountantGeneralPosition = cmNStr("en='Accountant';ru='Бухгалтер';de='Buchhalter'", SelLanguage);
		EndIf;
		vSignatures.Parameters.mRemarks = TrimAll(SelInvoice.RemarksForPrinting);
		If ValueIsFilled(SelInvoice.CheckDate) And (ValueIsFilled(SelInvoice.GuestGroup) And 
		   ValueIsFilled(SelInvoice.GuestGroup.CheckInDate) And BegOfDay(SelInvoice.GuestGroup.CheckInDate) >= BegOfDay(SelInvoice.CheckDate) Or Not ValueIsFilled(SelInvoice.GuestGroup)) Then
			vSignatures.Parameters.mRemarks = vSignatures.Parameters.mRemarks + ?(IsBlankString(vSignatures.Parameters.mRemarks), "", Chars.LF) + 
			                                  ?(vDoNotShowPayDueDate, "", cmNStr("en='Payment before '; ru='Оплата до '; de='Zahlung vor '; lv='Apmaksāt līdz '", SelLanguage) + Format(SelInvoice.CheckDate, "DF=dd.MM.yyyy"));
		EndIf;
		vSignatures.Parameters.mCompanyDirector = mCompanyDirector;
		vSignatures.Parameters.mCompanyDirectorPosition = mCompanyDirectorPosition;
		vSignatures.Parameters.mCompanyAccountantGeneral = mCompanyAccountantGeneral;
		vSignatures.Parameters.mCompanyAccountantGeneralPosition = mCompanyAccountantGeneralPosition;
		// Company stamp
		If SelInvoice.PrintWithCompanyStamp Then
			If vStampIsSet Then
				vSignatures.Drawings.Stamp.Print = True;
				vSignatures.Drawings.Stamp.Picture = vStamp;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.Stamp);
			EndIf;
			If vDirectorSignatureIsSet Then
				vSignatures.Drawings.DirectorSignature.Print = True;
				vSignatures.Drawings.DirectorSignature.Picture = vDirectorSignature;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.DirectorSignature);
			EndIf;
			If vAccountantGeneralSignatureIsSet Then
				vSignatures.Drawings.AccountantGeneralSignature.Print = True;
				vSignatures.Drawings.AccountantGeneralSignature.Picture = vAccountantGeneralSignature;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.AccountantGeneralSignature);
			EndIf;
		EndIf;
		// Form text
		vSignatures.Parameters.mFormText = TrimR(SelObjectPrintForm.FormText);
		// Put signatures	
		vFooterAreas.Add(vSignatures);
	Else
		If SelInvoice.PrintWithCompanyStamp Then
			vSignatures = vTemplate.GetArea("ManagerSignatureWithStamp");
		Else
			vSignatures = vTemplate.GetArea("ManagerSignature");
		EndIf;
		mPosition = cmNStr("en='Manager';ru='Менеджер';de='Manager'", SelLanguage);
		mEmployee = "";
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			If Not IsBlankString(SessionParameters.CurrentUser.Position) Then
				mPosition = cmNStr(SessionParameters.CurrentUser.Position, SelLanguage);
			EndIf;
			If Not IsBlankString(SessionParameters.CurrentUser.DescriptionTranslations) Then
				mEmployee = cmNStr(SessionParameters.CurrentUser.DescriptionTranslations, SelLanguage);
			Else
				mEmployee = TrimAll(SessionParameters.CurrentUser.Description);
			EndIf;
		EndIf;
		vSignatures.Parameters.mRemarks = TrimAll(SelInvoice.RemarksForPrinting);
		If ValueIsFilled(SelInvoice.CheckDate) And (ValueIsFilled(SelInvoice.GuestGroup) And 
		   ValueIsFilled(SelInvoice.GuestGroup.CheckInDate) And BegOfDay(SelInvoice.GuestGroup.CheckInDate) >= BegOfDay(SelInvoice.CheckDate) Or Not ValueIsFilled(SelInvoice.GuestGroup)) Then
			vSignatures.Parameters.mRemarks = vSignatures.Parameters.mRemarks + ?(IsBlankString(vSignatures.Parameters.mRemarks), "", Chars.LF) + 
			                                  ?(vDoNotShowPayDueDate, "", cmNStr("en='Payment before '; ru='Оплата до '; de='Zahlung vor '; lv='Apmaksāt līdz '", SelLanguage) + Format(SelInvoice.CheckDate, "DF=dd.MM.yyyy"));
		EndIf;
		vSignatures.Parameters.mPosition = mPosition;
		vSignatures.Parameters.mEmployee = mEmployee;
		// Company stamp and manager's signature
		If SelInvoice.PrintWithCompanyStamp Then
			If vSignatureIsSet Then
				vSignatures.Drawings.Signature.Print = True; 
				If TypeOf(vSignature) = Type("BinaryData") Then
					vSignatures.Drawings.Signature.Picture = New Picture(vSignature);	
				Else
					vSignatures.Drawings.Signature.Picture = vSignature;
				EndIf;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.Signature);
			EndIf;
			If vStampIsSet Then
				vSignatures.Drawings.ManagerStamp.Print = True;
				vSignatures.Drawings.ManagerStamp.Picture = vStamp;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.ManagerStamp);
			EndIf;
		EndIf;
		// Form text
		vSignatures.Parameters.mFormText = TrimR(SelObjectPrintForm.FormText);
		// Put signatures	
		vFooterAreas.Add(vSignatures);
	EndIf;

	vServicesSplitCopy = vServicesCopy.Copy();
	vServicesSplitCopy.Clear();
	
	vServicesNoSplitCopy = vServicesSplitCopy.Copy();
	
	// Group all in price services to the accommodation
	If  ValueIsFilled(GuestGroup) And (Not ValueIsFilled(ParentDoc) Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation")) Then
		For Each vRowCopy In vServicesCopy Do 
			If ValueIsFilled(vRowCopy.ParentDoc) Then  
				If Not vRowCopy.ParentDoc.IsForFolioSplit Then
					vSrvRow = vServicesNoSplitCopy.Add();
					FillPropertyValues(vSrvRow, vRowCopy);		
				Else   
					vSrvRow = vServicesSplitCopy.Add();
					FillPropertyValues(vSrvRow, vRowCopy);		
				EndIf;
			Else  
				vSrvRow = vServicesNoSplitCopy.Add();
				FillPropertyValues(vSrvRow, vRowCopy);				
			EndIf;
		EndDo;
		
		vServices.Clear();
		For Each vServicesRow In vServicesNoSplitCopy Do
			If vServicesRow.Sum = 0 Then
				Continue;
			EndIf;
			If ValueIsFilled(vServicesRow.Room)  Then
				vSrvRows = vServices.FindRows(New Structure("Room", vServicesRow.Room));
				If vSrvRows.Count() = 0 Then
					vSrvRow = vServices.Add();
					FillPropertyValues(vSrvRow, vServicesRow, , "AccountingDate");
					If vServicesRow.IsRoomRevenue And ValueIsFilled(vServicesRow.Service) And Not vServicesRow.Service.RoomRevenueAmountsOnly Then
						If Not SelInvoice.ExtraInvoice And ValueIsFilled(vSrvRow.ParentDoc) And 
						  (TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Reservation")) Then
							vSrvRow.Quantity = vSrvRow.ParentDoc.Duration;
						Else
							vSrvRow.Quantity = 1;
						EndIf;
						vSrvRow.Unit = "";
						vSrvRow.Remarks = GetRoomServicePresentationForInvoiceSimple(vSrvRow, SelLanguage);
					EndIf;
				Else
					vSrvRow = vSrvRows.Get(0);
					If vServicesRow.IsRoomRevenue And ValueIsFilled(vServicesRow.Service) And Not vServicesRow.Service.RoomRevenueAmountsOnly And Not ValueIsFilled(vSrvRow.Service) Then
						vSum = vSrvRow.Sum;
						vDiscountSum = vSrvRow.DiscountSum;
						vCommissionSum = vSrvRow.CommissionSum;
						vVATCommissionSum = vSrvRow.VATCommissionSum;

						FillPropertyValues(vSrvRow, vServicesRow);
						If Not SelInvoice.ExtraInvoice And ValueIsFilled(vSrvRow.ParentDoc) And 
						  (TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Reservation")) Then
							vSrvRow.Quantity = vSrvRow.ParentDoc.Duration;
						Else
							vSrvRow.Quantity = 1;
						EndIf;
						vSrvRow.Unit = "";
						vSrvRow.Remarks = GetRoomServicePresentationForInvoiceSimple(vSrvRow, SelLanguage);

						vSrvRow.Sum = vSrvRow.Sum + vSum;
						vSrvRow.DiscountSum = vSrvRow.DiscountSum + vDiscountSum;
						vSrvRow.CommissionSum = vSrvRow.CommissionSum + vCommissionSum;
						vSrvRow.VATCommissionSum = vSrvRow.VATCommissionSum + vVATCommissionSum;
					Else
						vSrvRow.Sum = vSrvRow.Sum + vServicesRow.Sum;
						vSrvRow.DiscountSum = vSrvRow.DiscountSum + vServicesRow.DiscountSum;
						vSrvRow.CommissionSum = vSrvRow.CommissionSum + vServicesRow.CommissionSum;
						vSrvRow.VATCommissionSum = vSrvRow.VATCommissionSum + vServicesRow.VATCommissionSum;
					EndIf;
				EndIf;
			Else
				vSrvRow = vServices.Add();
				FillPropertyValues(vSrvRow, vServicesRow);
			EndIf;
		EndDo;  
		
		For Each vServicesRow In vServicesSplitCopy Do
			If vServicesRow.Sum = 0 Then
				Continue;
			EndIf;
			If ValueIsFilled(vServicesRow.Room)  Then
				vSrvRows = vServices.FindRows(New Structure("Room, ParentDoc", vServicesRow.Room,  vServicesRow.ParentDoc));
				If vSrvRows.Count() = 0 Then
					vSrvRow = vServices.Add();
					FillPropertyValues(vSrvRow, vServicesRow, , "AccountingDate");
					If vServicesRow.IsRoomRevenue And ValueIsFilled(vServicesRow.Service) And Not vServicesRow.Service.RoomRevenueAmountsOnly Then
						If Not SelInvoice.ExtraInvoice And ValueIsFilled(vSrvRow.ParentDoc) And 
						  (TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Reservation")) Then
							vSrvRow.Quantity = vSrvRow.ParentDoc.Duration;
						Else
							vSrvRow.Quantity = 1;
						EndIf;
						vSrvRow.Unit = "";
						vSrvRow.Remarks = GetRoomServicePresentationForInvoiceSimple(vSrvRow, SelLanguage);
					EndIf;
				Else
					vSrvRow = vSrvRows.Get(0);
					If vServicesRow.IsRoomRevenue And ValueIsFilled(vServicesRow.Service) And Not vServicesRow.Service.RoomRevenueAmountsOnly And Not ValueIsFilled(vSrvRow.Service) Then
						vSum = vSrvRow.Sum;
						vDiscountSum = vSrvRow.DiscountSum;
						vCommissionSum = vSrvRow.CommissionSum;
						vVATCommissionSum = vSrvRow.VATCommissionSum;

						FillPropertyValues(vSrvRow, vServicesRow);
						If Not SelInvoice.ExtraInvoice And ValueIsFilled(vSrvRow.ParentDoc) And 
						  (TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Reservation")) Then
							vSrvRow.Quantity = vSrvRow.ParentDoc.Duration;
						Else
							vSrvRow.Quantity = 1;
						EndIf;
						vSrvRow.Unit = "";
						vSrvRow.Remarks = GetRoomServicePresentationForInvoiceSimple(vSrvRow, SelLanguage);

						vSrvRow.Sum = vSrvRow.Sum + vSum;
						vSrvRow.DiscountSum = vSrvRow.DiscountSum + vDiscountSum;
						vSrvRow.CommissionSum = vSrvRow.CommissionSum + vCommissionSum;
						vSrvRow.VATCommissionSum = vSrvRow.VATCommissionSum + vVATCommissionSum;
					Else
						vSrvRow.Sum = vSrvRow.Sum + vServicesRow.Sum;
						vSrvRow.DiscountSum = vSrvRow.DiscountSum + vServicesRow.DiscountSum;
						vSrvRow.CommissionSum = vSrvRow.CommissionSum + vServicesRow.CommissionSum;
						vSrvRow.VATCommissionSum = vSrvRow.VATCommissionSum + vServicesRow.VATCommissionSum;
					EndIf;
				EndIf;
			Else
				vSrvRow = vServices.Add();
				FillPropertyValues(vSrvRow, vServicesRow);
			EndIf;
		EndDo;  

		For Each vSrvRow In vServices Do
			// Recalculate price
			If vSrvRow.Quantity = 0 Then
				If vSrvRow.Sum < 0 Then
					vSrvRow.Quantity = -1;
				Else
					vSrvRow.Quantity = 1;
				EndIf;
			EndIf;
			vSrvRow.Price = Round(vSrvRow.Sum / vSrvRow.Quantity, 2);
		EndDo; 
		
		i = 0;
		For Each vSrvRow In vServices Do    
			vRow = vTemplate.GetArea("Row"); 
			i = i + 1; 
			vRow.Parameters.mNum = i;
			vRow.Parameters.mQuantity = vSrvRow.Quantity; 
			vRow.Parameters.mPrice = Format(vSrvRow.Price, "ND=17; NFD=2");  
			vRow.Parameters.mSum  =  Format(vSrvRow.Sum, "ND=17; NFD=2"); 
			vRow.Parameters.mDescription = vSrvRow.Remarks; 
			vSpreadsheet.Put(vRow);
		EndDo;
	EndIf;
	
	// Put footer areas
	For Each vFooterArea In vFooterAreas Do
		vSpreadsheet.Put(vFooterArea);
	EndDo;

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // pmPrintInvoiceSimple

// -----------------------------------------------------------------------------
Procedure pmPrintInvoiceShort(vSpreadsheet, SelLanguage, SelGroupBy, SelObjectPrintForm, mInvoiceNumber, pClear = True) Export
	SelInvoice = ThisObject;
	
	// Basic checks
	vHotel = SelInvoice.Hotel;
	If Not ValueIsFilled(vHotel) Then
		Raise NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'");
	EndIf;
	vCompany = SelInvoice.Company;
	If Not ValueIsFilled(vCompany) Then
		Raise NStr("ru='Не задана фирма!';de='Die Firma ist nicht angegeben!';en='Company should be filled!'");
	EndIf;
	vAccount = SelInvoice.BankAccount;
	If Not ValueIsFilled(vAccount) Then
		vAccount = vCompany.BankAccount;
	EndIf;
	If Not ValueIsFilled(vAccount) Then
		Raise NStr("ru='Не задан расчетный счет фирмы!';de='Das Verrechnungskonto der Firma ist nicht angegeben!';en='Company account should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	If pClear Then
		vSpreadsheet.Clear();
	EndIf;
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = SelInvoice.GetTemplate("InvoiceShortEn");
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplate = SelInvoice.GetTemplate("InvoiceShortDe");
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = SelInvoice.GetTemplate("InvoiceShortRu");
		Else
			Raise NStr("ru='Не найден шаблон печатной формы счета для языка " + SelLanguage.Code + "!'; 
			           |de='No invoice print form template found for the " + SelLanguage.Code + " language!'; 
			           |en='No invoice print form template found for the " + SelLanguage.Code + " language!'");
		EndIf;
	Else
		vTemplate = SelInvoice.GetTemplate("InvoiceShortRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Print form parameter
	vParameter = Upper(TrimAll(SelObjectPrintForm.Parameter));
	vShowDiscounts = (Find(vParameter, "SHOW_DISCOUNT") > 0);
	vDoNotUseSectionVAT = (Find(vParameter, "DO_NOT_USE_SECTION_VAT") > 0);
	vPrintQRCode = (Find(vParameter, "SHOW_QRCODE") > 0);
	vIgnoreVATRate = (Find(vParameter, "IGNORE_VATRATE_ON_GROUPING") > 0);
	vDoNotShowPayDueDate = (Find(vParameter, "DO_NOT_SHOW_PAY_DUE_DATE") > 0);

	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(SelInvoice.Hotel) Then
		If SelInvoice.Hotel.Logo <> Undefined Then
			vLogo = SelInvoice.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vStampIsSet = False;
	vStamp = New Picture;
	If ValueIsFilled(SelInvoice.Company) Then
		If SelInvoice.Company.Stamp <> Undefined Then
			vStamp = SelInvoice.Company.Stamp.Get();
			If vStamp = Undefined Then
				vStamp = New Picture;
			Else
				vStampIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vSignatureIsSet = False;
	vSignature = New Picture;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If SessionParameters.CurrentUser.Signature <> Undefined Then
			vSignature = SessionParameters.CurrentUser.Signature.Get();
			If vSignature = Undefined Then
				vSignature = New Picture;
			Else
				vSignatureIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vDirectorSignatureIsSet = False;
	vDirectorSignature = New Picture;
	If SelInvoice.Company.DirectorSignature <> Undefined Then
		vDirectorSignature = SelInvoice.Company.DirectorSignature.Get();
		If vDirectorSignature = Undefined Then
			vDirectorSignature = New Picture;
		Else
			vDirectorSignatureIsSet = True;
		EndIf;
	EndIf;
	vAccountantGeneralSignatureIsSet = False;
	vAccountantGeneralSignature = New Picture;
	If SelInvoice.Company.AccountantGeneralSignature <> Undefined Then
		vAccountantGeneralSignature = SelInvoice.Company.AccountantGeneralSignature.Get();
		If vAccountantGeneralSignature = Undefined Then
			vAccountantGeneralSignature = New Picture;
		Else
			vAccountantGeneralSignatureIsSet = True;
		EndIf;
	EndIf;
	
	// Header
	vRubHeader = False;
	If SelInvoice.AccountingCurrency.Code = 643 And vHotel.Citizenship.Code = 643 Then
		vRubHeader = True;
	EndIf;
	
	// Hotel
	mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, SelLanguage);
	mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, SelLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vHotelFax);
	mHotelEMail = TrimAll(vHotel.EMail);
	
	// Company
	vCompanyObj = vCompany.GetObject();
	vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
	vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
	vCompanyPostAddress = vCompanyObj.pmGetCompanyPostAddressPresentation(SelLanguage);
	If vCompanyPostAddress = vCompanyLegacyAddress Then
		vCompanyPostAddress = "";
	EndIf;
	mCompanyTIN = TrimAll(vCompany.TIN);
	mCompanyKPP = TrimAll(vCompany.KPP);
	mCompanyCBC = TrimAll(vCompany.KBK);
	mCompanyOKTMO = TrimAll(vCompany.OKTMO);
	mCompanyVATCode = TrimAll(vCompany.VATC);
	vCompanyTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН'", SelLanguage) + ?(IsBlankString(mCompanyKPP), " ", "/" + cmNStr("en='KPP ';de='KPP ';ru='КПП '", SelLanguage)) + mCompanyTIN + ?(IsBlankString(mCompanyKPP), "", "/" + mCompanyKPP) + 
	              ?(IsBlankString(mCompanyVATCode), "", cmNStr("en=', VAT code ';de=', Mw.St. code ';ru=', код НДС ';lv=', PVN '", SelLanguage) + mCompanyVATCode);
	vCompanyPhones = TrimAll(vCompany.Phones) + ?(IsBlankString(vCompany.Fax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + TrimAll(vCompany.Fax));
	mCompany = TrimAll(vCompanyLegacyName + vCompanyTIN + Chars.LF + vCompanyLegacyAddress + Chars.LF + ?(IsBlankString(vCompanyPostAddress), "", vCompanyPostAddress + Chars.LF) + vCompanyPhones);
	
	// Invoice date and number
	If vCompany.UseGroupCodeAsInvoiceNumberPrefix Then
		If vCompany.PrintInvoiceAndSettlementNumbersWithPrefixes Then
			vCompanyPrefix = TrimAll(vCompany.Prefix);
			If Not IsBlankString(vCompanyPrefix) Then
				mInvoiceNumber = vCompanyPrefix + cmRemoveLeadingZeroes(SelInvoice.Number);
			Else
				mInvoiceNumber = cmRemoveLeadingZeroes(SelInvoice.Number);
			EndIf;
		Else
			vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelInvoice.Hotel);
			If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
				mInvoiceNumber = vHotelPrefix + cmRemoveLeadingZeroes(SelInvoice.Number);
			Else
				mInvoiceNumber = cmRemoveLeadingZeroes(SelInvoice.Number);
			EndIf;
		EndIf;
	Else
		mInvoiceNumber = ?(vCompany.PrintInvoiceAndSettlementNumbersWithPrefixes, TrimAll(SelInvoice.Number), cmGetDocumentNumberPresentation(SelInvoice.Number));
	EndIf;
	mInvoiceDate = cmGetDocumentDatePresentation(SelInvoice.Date);
	
	vTableHeader = vTemplate.GetArea("TableHeader");
	
	// Print different invoice headers for invoices in RUR and Russia base country and other currencies/countries
	If vRubHeader Then
		vHeader = vTemplate.GetArea("Header");
		
		mCompanyPaymentAttributes = vCompanyLegacyName;
		mCompanyBank = "";
		mCompanyBankAcount = "";
		mCompanyBankBIC = "";
		mCompanyBankCorrAccount = "";
		If vAccount.IsDirectPayments Then
			mCompanyBank = TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity);
			
			mCompanyBankAccount = TrimAll(vAccount.AccountNumber);
			mCompanyBankBIC = TrimAll(vAccount.BankBIC);
			mCompanyBankCorrAccount = TrimAll(vAccount.BankCorrAccountNumber);
		Else
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + cmNStr("en=' acc ';ru=' р/с ';de=' verrechnungskonto '", SelLanguage) + TrimAll(vAccount.AccountNumber);
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + cmNStr("en=' in ';ru=' в ';de=' in '", SelLanguage) + TrimAll(vAccount.BankName);
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + " " + TrimAll(vAccount.BankCity);
		
			mCompanyBank = TrimAll(vAccount.CorrBankName);
			mCompanyBank = mCompanyBank + TrimAll(vAccount.CorrBankCity);
			
			mCompanyBankAccount = TrimAll(vAccount.BankCorrAccountNumber);
			mCompanyBankBIC = TrimAll(vAccount.CorrBankBIC);
			mCompanyBankCorrAccount = TrimAll(vAccount.CorrBankCorrAccountNumber);
		EndIf;
		If Not IsBlankString(vAccount.Beneficiary) Then
			mCompanyPaymentAttributes = TrimAll(vAccount.Beneficiary);
		EndIf;
		If Not IsBlankString(vCompany.OKTMO) Or Not IsBlankString(vCompany.KBK) Then
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + Chars.LF;
			If Not IsBlankString(vCompany.OKTMO) Then
				mCompanyPaymentAttributes = mCompanyPaymentAttributes + "ОКТМО " + TrimAll(vCompany.OKTMO);
			EndIf;
			If Not IsBlankString(vCompany.KBK) Then
				If Not IsBlankString(vCompany.OKTMO) Then
					mCompanyPaymentAttributes = mCompanyPaymentAttributes + ", ";
				EndIf;
				mCompanyPaymentAttributes = mCompanyPaymentAttributes + "КБК " + TrimAll(vCompany.KBK);
			EndIf;
		EndIf;
		
		// Customer
		vCustomerCode = "";
		If SelInvoice.AccountingCustomer = vHotel.IndividualsCustomer Then
			// Use contact person as customer
			If Not IsBlankString(SelInvoice.ContactPerson) Then
				mCustomer = TrimAll(SelInvoice.ContactPerson);
			Else
				vClientRef = Catalogs.Clients.EmptyRef();
				// Use guest group client as customer
				If ValueIsFilled(SelInvoice.GuestGroup) And ValueIsFilled(SelInvoice.GuestGroup.Client) Then
					vClientRef = SelInvoice.GuestGroup.Client;
				// Use first client as customer
				Else
					For Each vRow In SelInvoice.Services Do
						If ValueIsFilled(vRow.Client) Then
							vClientRef = vRow.Client;
							Break;
						EndIf;
					EndDo;
				EndIf;
				vCustomer = vClientRef;
				vCustomerLegacyName = "";
				vCustomerLegacyAddress = "";
				vCustomerTIN = "";
				vCustomerPhones = "";
				If ValueIsFilled(vClientRef) Then
					vCustomerLegacyName = TrimAll(vClientRef.FullName);
					vCustomerLegacyAddress = cmGetAddressPresentation(vClientRef.Address);
					vCustomerTIN = "";
					vCustomerKPP = "";
					// Fax and E-Mail
					vCustomerPhones = TrimAll(vClientRef.Phone);
					vCustomerFax = TrimAll(vClientRef.Fax);
					vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
				EndIf;
				mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + vCustomerPhones);
			EndIf;
			// Contract
			mContract = "";
		Else
			vCustomer = SelInvoice.AccountingCustomer;
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
				If Not vCustomer.IsIndividual Then
					vCustomerCode = TrimAll(vCustomer.Code);
				EndIf;
				
				// Addresses
				vCustomerLegacyAddress = cmGetAddressPresentation(vCustomer.LegacyAddress);
				vCustomerPostAddress = cmGetAddressPresentation(vCustomer.PostAddress);
				If vCustomerPostAddress = vCustomerLegacyAddress Then
					vCustomerPostAddress = "";
				EndIf;
				
				// Codes
				vCustomerTIN = TrimAll(vCustomer.TIN);
				vCustomerKPP = TrimAll(vCustomer.KPP);
				vCustomerVATCode = TrimAll(vCustomer.VATC);
				vCustomerTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН '", SelLanguage) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP) + 
				               ?(IsBlankString(vCustomerVATCode), "", cmNStr("en=', VAT code ';de=', Mw.St. code ';ru=', код НДС ';lv=', PVN '", SelLanguage) + vCustomerVATCode);
							   
				// Fax and E-Mail
				vCustomerPhones = TrimAll(vCustomer.Phone);
				vCustomerFax = TrimAll(vCustomer.Fax);
				vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
			EndIf;
			mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + vCustomerPhones);
			// Contract
			mContract = "";
			If ValueIsFilled(SelInvoice.AccountingContract) Then
				mContract = TrimAll(SelInvoice.AccountingContract.Description);
			EndIf;
		EndIf;
		// Guest group code
		mGuestGroup = "";
		vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelInvoice.Hotel);
		If ValueIsFilled(SelInvoice.GuestGroup) Then
			mGuestGroup = Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=");
			If Not IsBlankString(SelInvoice.GuestGroup.ID) Then
				mGuestGroup = mGuestGroup + " - Ref. # " + TrimAll(SelInvoice.GuestGroup.ID);
			ElsIf Not IsBlankString(SelInvoice.GuestGroup.Description) Then
				mGuestGroup = mGuestGroup + " - " + TrimAll(SelInvoice.GuestGroup.Description);
			EndIf;
			If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
				mGuestGroup = vHotelPrefix + mGuestGroup;
			EndIf;
		Else
			vGroups = SelInvoice.Services.Unload(, "GuestGroup");
			vGroups.GroupBy("GuestGroup", );
			For Each vGroupsRow In vGroups Do
				If ValueIsFilled(vGroupsRow.GuestGroup) Then
					vGuestGroupCode = Format(vGroupsRow.GuestGroup.Code, "ND=12; NFD=0; NG=");
					If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
						vGuestGroupCode = vHotelPrefix + vGuestGroupCode;
					EndIf;
					If IsBlankString(mGuestGroup) Then
						mGuestGroup = vGuestGroupCode;
					Else
						mGuestGroup = mGuestGroup + ", " + vGuestGroupCode;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Currency
		mAccountingCurrency = "";
		If ValueIsFilled(SelInvoice.AccountingCurrency) Then
			vCurrencyObj = SelInvoice.AccountingCurrency.GetObject();
			mAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
		EndIf;
		// Parent document
		mParentDoc = ?(ValueIsFilled(SelInvoice.ParentDoc), TrimAll(SelInvoice.ParentDoc.Number), "");
		mFullInvoiceNumber = Trimall(SelInvoice.Number) + ?(IsBlankString(vCustomerCode), "", " " + vCustomerCode);
		// Set parameters and put report section
		vHeader.Parameters.mHotelPrintName = mHotelPrintName;
		vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
		vHeader.Parameters.mHotelPhones = mHotelPhones;
		vHeader.Parameters.mHotelEMail = mHotelEMail;
		vHeader.Parameters.mInvoiceNumber = mInvoiceNumber;
		vHeader.Parameters.mFullInvoiceNumber = mFullInvoiceNumber;
		vHeader.Parameters.mInvoiceDate = mInvoiceDate;
		If SelInvoice.AccountingCurrency = vHotel.BaseCurrency Then
			vHeader.Parameters.mCompany = mCompany;
			vHeader.Parameters.mCompanyTIN = mCompanyTIN;
			vHeader.Parameters.mCompanyKPP = mCompanyKPP;
			vHeader.Parameters.mCompanyBankBIC = mCompanyBankBIC;
			vHeader.Parameters.mCompanyBankCorrAccount = mCompanyBankCorrAccount;
		EndIf;
		vHeader.Parameters.mCompanyPaymentAttributes = mCompanyPaymentAttributes;
		vHeader.Parameters.mCompanyBank = mCompanyBank;
		vHeader.Parameters.mCompanyBankAccount = mCompanyBankAccount;
		vHeader.Parameters.mCustomer = mCustomer;
		vHeader.Parameters.mInvoiceEMail = TrimAll(SelInvoice.EMail);
		vHeader.Parameters.mContract = mContract;
		vHeader.Parameters.mGuestGroup = mGuestGroup;
		vHeader.Parameters.mAccountingCurrency = mAccountingCurrency;
		vHeader.Parameters.mParentDoc = mParentDoc;
		// Logo
		If vLogoIsSet Then
			vHeader.Drawings.Logo.Print = True;
			vHeader.Drawings.Logo.Picture = vLogo;
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.Logo);
		EndIf;
		
		// Genarate QR-Code
		If vPrintQRCode Then
			vServices = SelInvoice.Services.Unload();
			vTotalSum = 0;
			vTotalCommissionSum = 0;
			vTotalVATSum = vServices.Total("VATSum");
			If vServices <> Undefined Then
				vTotalSum = vServices.Total("Sum");
				vTotalCommissionSum = vServices.Total("CommissionSum");
				If vTotalCommissionSum <> 0 And 
					ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
					vTotalSum = vTotalSum - vTotalCommissionSum;
				EndIf;
			EndIf;
			
			// Payment text
			mPaymentText = NStr("en='Payment for invoice N';ru='Оплата счета №';de='Bezahlung der Rechnung Nr.'", SelLanguage) + cmGetDocumentNumberPresentation(SelInvoice.Number) + 
	                       NStr("en=', reservation confirmation N';de=', reservation confirmation N';ru=', подтверждение брони №'", SelLanguage) + mGuestGroup + ".";

			vStructOutputData = New Structure;
			vStructOutputData.Insert("Name", 		mCompany);
			vStructOutputData.Insert("PersonalAcc", mCompanyBankAccount);
			vStructOutputData.Insert("CorrespAcc", 	mCompanyBankCorrAccount);
			vStructOutputData.Insert("BankName", 	mCompanyBank);
			vStructOutputData.Insert("BIC", 		mCompanyBankBIC);
			vStructOutputData.Insert("PayeeINN", 	mCompanyTIN);
			vStructOutputData.Insert("KPP", 		mCompanyKPP);
			vStructOutputData.Insert("CBC", 		mCompanyCBC);
			vStructOutputData.Insert("OKTMO", 		mCompanyOKTMO);
			vStructOutputData.Insert("Sum", 		vTotalSum);
			vStructOutputData.Insert("Purpose", 	mPaymentText);
			
			vQRCodeString =  tcCommonFunctions.cmGenerateBankFormattedString(vStructOutputData);
			If Not IsBlankString(vQRCodeString) Then
				Try
					vQRCodePic =  cmGetQRCodePicture(vQRCodeString);
					vQRCodeControl = vHeader.Drawings.QRCodeControl;
					vQRCodeControl.Picture = vQRCodePic;
				Except
					tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Failed to generate a QR code, possibly no internet connection'; de = 'Fehler beim Erzeugen eines QR-Codes, möglicherweise keine Internetverbindung'; ru = 'Не удалось сформировать QR-code, возможно отсутствует соединение с интернетом'"));
				EndTry;	
			EndIf;
		EndIf;

		// Put header		
		vSpreadsheet.Put(vHeader);
		vSpreadsheet.Put(vTableHeader);
	Else
		vHeader1 = vTemplate.GetArea("HeaderCurrency1");
		
		If Not IsBlankString(vAccount.Beneficiary) Then
			mCompany = TrimAll(vAccount.Beneficiary);
		EndIf;
		
		mCompanyBank = TrimAll(TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity));
		mCompanyBankAccount = TrimAll(vAccount.AccountNumber);
		If Not IsBlankString(vAccount.BankBIC) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='BIC ';ru='БИК ';de='BIC '", SelLanguage) + TrimAll(vAccount.BankBIC);
		EndIf;
		If Not IsBlankString(vAccount.BankCorrAccountNumber) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='Corr. acc. № ';ru='Корр. сч. № ';de='Korrespondenzkonto Nr.'", SelLanguage) + TrimAll(vAccount.BankCorrAccountNumber);
		EndIf;
		If Not IsBlankString(vAccount.BankTINCode) Then
			mCompanyBank = mCompanyBank + Chars.LF + TrimAll(vAccount.BankTINCode);
		EndIf;
		If Not IsBlankString(vAccount.BankIBAN) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='IBAN CODE ';de='IBAN CODE ';ru='IBAN CODE '", SelLanguage) + TrimAll(vAccount.BankIBAN);
		EndIf;
		If Not IsBlankString(vAccount.BankSWIFTCode) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='SWIFT CODE ';de='SWIFT CODE ';ru='SWIFT CODE '", SelLanguage) + TrimAll(vAccount.BankSWIFTCode);
		EndIf;
		
		// Set parameters and put report section
		vHeader1.Parameters.mHotelPrintName = mHotelPrintName;
		vHeader1.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
		vHeader1.Parameters.mHotelPhones = mHotelPhones;
		vHeader1.Parameters.mHotelEMail = mHotelEMail;
		vHeader1.Parameters.mInvoiceNumber = mInvoiceNumber;
		vHeader1.Parameters.mInvoiceDate = mInvoiceDate;
		vHeader1.Parameters.mCompany = mCompany;
		vHeader1.Parameters.mCompanyBankAccount = mCompanyBankAccount;
		vHeader1.Parameters.mCompanyBank = mCompanyBank;
		// Logo
		If vLogoIsSet Then
			vHeader1.Drawings.LogoCurrency.Print = True;
			vHeader1.Drawings.LogoCurrency.Picture = vLogo;
		Else
			vHeader1.Drawings.Delete(vHeader1.Drawings.LogoCurrency);
		EndIf;
		// Put header1		
		vSpreadsheet.Put(vHeader1);
		
		// Put correspondent bank header
		If Not vAccount.IsDirectPayments Then
			vCorrBankHeader = vTemplate.GetArea("CorrBank");
			
			mCompanyCorrBank = TrimAll(TrimAll(vAccount.CorrBankName) + " " + TrimAll(vAccount.CorrBankCity));
			If Not IsBlankString(vAccount.CorrBankBIC) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='BIC ';ru='БИК ';de='BIC '", SelLanguage) + TrimAll(vAccount.CorrBankBIC);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankCorrAccountNumber) Then
				mCompanyCorrBank = mCompanyCorrBank + cmNStr("en='Corr. acc. № ';ru='Корр. сч. № ';de='Korrespondenzkonto Nr. '", SelLanguage) + TrimAll(vAccount.CorrBankCorrAccountNumber);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankTINCode) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + TrimAll(vAccount.CorrBankTINCode);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankIBAN) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='IBAN CODE ';de='IBAN CODE ';RU='IBAN CODE '", SelLanguage) + TrimAll(vAccount.CorrBankIBAN);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankSWIFTCode) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='SWIFT CODE ';de='SWIFT CODE ';RU='SWIFT CODE '", SelLanguage) + TrimAll(vAccount.CorrBankSWIFTCode);
			EndIf;
			
			// Set parameters and put report section
			vCorrBankHeader.Parameters.mCompanyCorrBank = mCompanyCorrBank;
			
			// Put corr. bank header
			vSpreadsheet.Put(vCorrBankHeader);
		EndIf;
		
		// Table header
		vHeader2 = vTemplate.GetArea("HeaderCurrency2");
		
		// Customer
		vCustomerCode = "";
		If SelInvoice.AccountingCustomer = vHotel.IndividualsCustomer Then
			// Use contact person as customer
			If Not IsBlankString(SelInvoice.ContactPerson) Then
				mCustomer = TrimAll(SelInvoice.ContactPerson);
			Else				
				vClientRef = Catalogs.Clients.EmptyRef();
				// Use guest group client as customer
				If ValueIsFilled(SelInvoice.GuestGroup) And ValueIsFilled(SelInvoice.GuestGroup.Client) Then
					vClientRef = SelInvoice.GuestGroup.Client;
				// Use first client as customer
				Else
					For Each vRow In SelInvoice.Services Do
						If ValueIsFilled(vRow.Client) Then
							vClientRef = vRow.Client;
							Break;
						EndIf;
					EndDo;
				EndIf;
				vCustomer = vClientRef;
				vCustomerLegacyName = "";
				vCustomerLegacyAddress = "";
				vCustomerTIN = "";
				vCustomerPhones = "";
				If ValueIsFilled(vClientRef) Then
					vCustomerLegacyName = TrimAll(vClientRef.FullName);
					vCustomerLegacyAddress = cmGetAddressPresentation(vClientRef.Address);
					vCustomerTIN = "";
					vCustomerKPP = "";
					// Fax and E-Mail
					vCustomerPhones = TrimAll(vClientRef.Phone);
					vCustomerFax = TrimAll(vClientRef.Fax);
					vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
				EndIf;
				mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + vCustomerPhones);
			EndIf;
			// Contract
			mContract = "";
		Else
			vCustomer = SelInvoice.AccountingCustomer;
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
				If Not vCustomer.IsIndividual Then
					vCustomerCode = TrimAll(vCustomer.Code);
				EndIf;
				
				// Addresses
				vCustomerPostAddress = "";
				vAddressStruct = cmParseAddress(vCustomer.LegacyAddress);
				vCustomerLegacyAddress = TrimAll(vAddressStruct.Region + " " + vAddressStruct.Area) + Chars.LF +
				                         TrimAll(vAddressStruct.Street + " " + vAddressStruct.House + " " + vAddressStruct.Flat) + Chars.LF +
										 TrimAll(vAddressStruct.PostCode + " " + vAddressStruct.City) + Chars.LF + 
										 TrimAll(vAddressStruct.Country);

				If Not IsBlankString(vCustomer.PostAddress) And TrimAll(vCustomer.PostAddress) <> TrimAll(vCustomer.LegacyAddress) Then
					vAddressStruct = cmParseAddress(vCustomer.PostAddress);
					vCustomerPostAddress = TrimAll(vAddressStruct.Region + " " + vAddressStruct.Area) + Chars.LF +
					                       TrimAll(vAddressStruct.Street + " " + vAddressStruct.House + " " + vAddressStruct.Flat) + Chars.LF +
										   TrimAll(vAddressStruct.PostCode + " " + vAddressStruct.City) + Chars.LF + 
										   TrimAll(vAddressStruct.Country);
				EndIf;
				
				// Codes
				vCustomerTIN = TrimAll(vCustomer.TIN);
				vCustomerKPP = TrimAll(vCustomer.KPP);
				vCustomerVATCode = TrimAll(vCustomer.VATC);
				vCustomerTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН '", SelLanguage) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP) +
				               ?(IsBlankString(vCustomerVATCode), "", cmNStr("en=', VAT code ';de=', Mw.St. code ';ru=', ИНН ';lv=', PVN '", SelLanguage) + vCustomerVATCode);
							   
				// Fax and E-Mail
				vCustomerPhones = TrimAll(vCustomer.Phone);
				vCustomerFax = TrimAll(vCustomer.Fax);
				vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
			EndIf;
			mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + vCustomerPhones);
			// Contract
			mContract = "";
			If ValueIsFilled(SelInvoice.AccountingContract) Then
				mContract = TrimAll(SelInvoice.AccountingContract.Description);
			EndIf;
		EndIf;
		// Guest group code
		mGuestGroup = "";
		If ValueIsFilled(SelInvoice.GuestGroup) Then
			mGuestGroup = Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=");
			If Not IsBlankString(SelInvoice.GuestGroup.ID) Then
				mGuestGroup = mGuestGroup + " - Ref. # " + TrimAll(SelInvoice.GuestGroup.ID);
			ElsIf Not IsBlankString(SelInvoice.GuestGroup.Description) Then
				mGuestGroup = mGuestGroup + " - " + TrimAll(SelInvoice.GuestGroup.Description);
			EndIf;
		Else
			vGroups = SelInvoice.Services.Unload(, "GuestGroup");
			vGroups.GroupBy("GuestGroup", );
			For Each vGroupsRow In vGroups Do
				If ValueIsFilled(vGroupsRow.GuestGroup) Then
					vGuestGroupCode = Format(vGroupsRow.GuestGroup.Code, "ND=12; NFD=0; NG=");
					If IsBlankString(mGuestGroup) Then
						mGuestGroup = vGuestGroupCode;
					Else
						mGuestGroup = mGuestGroup + ", " + vGuestGroupCode;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Currency
		mAccountingCurrency = "";
		If ValueIsFilled(SelInvoice.AccountingCurrency) Then
			vCurrencyObj = SelInvoice.AccountingCurrency.GetObject();
			mAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
		EndIf;
		// Parent document
		mParentDoc = ?(ValueIsFilled(SelInvoice.ParentDoc), TrimAll(SelInvoice.ParentDoc.Number), "");
		mFullInvoiceNumber = Trimall(SelInvoice.Number) + ?(IsBlankString(vCustomerCode), "", " " + vCustomerCode);
		// Set parameters and put report section
		vHeader2.Parameters.mFullInvoiceNumber = mFullInvoiceNumber;
		vHeader2.Parameters.mCustomer = mCustomer;
		vHeader2.Parameters.mInvoiceEMail = TrimAll(SelInvoice.EMail);
		vHeader2.Parameters.mContract = mContract;
		vHeader2.Parameters.mGuestGroup = mGuestGroup;
		vHeader2.Parameters.mAccountingCurrency = mAccountingCurrency;
		vHeader2.Parameters.mParentDoc = mParentDoc;
		// Put header		
		vSpreadsheet.Put(vHeader2);
		vSpreadsheet.Put(vTableHeader);
	EndIf;
	
	// Get template areas
	vClient = vTemplate.GetArea("Client");
	vRow = vTemplate.GetArea("Row");
	
	// Get all services
	vServices = SelInvoice.Services.Unload();
	
	vAgentCommission = 0;
	vDiscountPercent = 0;
	For Each vSrvRow In vServices Do
		If vAgentCommission = 0 Then
			vAgentCommission = vSrvRow.AgentCommission;
		EndIf;
		If vDiscountPercent = 0 Then
			vDiscountPercent = vSrvRow.Discount;
		EndIf;
	EndDo;
	
	// Change accounting dates for breakfast
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		If vServices.Find(True, "IsRoomRevenue") <> Undefined Then
			For Each vSrvRow In vServices Do
				If vSrvRow.IsInPrice And ValueIsFilled(vSrvRow.Service.QuantityCalculationRule) And
				   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Breakfast Then
					If BegOfDay(vSrvRow.AccountingDate) > BegOfDay(vSrvRow.DateTimeFrom) Then
						vSrvRow.AccountingDate = vSrvRow.AccountingDate - 24*3600;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Join services according to service parameters
	vRemarks = "";
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		// Try to replace accommodation service to the one that should be used for printing
		For Each vSrvRow In vServices Do
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
				EndIf;
			EndIf;
		EndDo;
		// Try to merge other services to the accommodation service
		i = 0;
		While i < vServices.Count() Do
			vSrvRow = vServices.Get(i);
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					// Try to find service to hide current one to
					vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Client, RoomType, Room, Resource", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate, vSrvRow.Client, vSrvRow.RoomType, vSrvRow.Room, vSrvRow.Resource));
					If vHideToServices.Count() = 0 Then
						vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Client, RoomType, Room, Resource", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate - 24*3600, vSrvRow.Client, vSrvRow.RoomType, vSrvRow.Room, vSrvRow.Resource));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vSrvRow.Sum;
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vSrvRow.VATSum;
						vSrv2Hide2.DiscountSum = vSrv2Hide2.DiscountSum + vSrvRow.DiscountSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
						// Delete current service
						vServices.Delete(i);
						Continue;
					EndIf;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
	
	// Get accommodation service name
	vAccommodationService = Undefined;	
	vAccommodationRemarks = "";	
	vAccommodationServiceVATRate = Undefined;
	i = 0;
	While i < vServices.Count() Do
		vSrvRow = vServices.Get(i);
		If SelGroupBy = "InPricePerClientPerDay" Or SelGroupBy = "InPricePerDay" Or
		   SelGroupBy = "AllPerClientPerDay" Or SelGroupBy = "AllPerDay" Or
		   SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or
		   SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Then
			If vSrvRow.Sum = 0 Then
				vServices.Delete(i);
				Continue;
			EndIf;
		EndIf;
		If vAccommodationService = Undefined And vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly Then
			vAccommodationService = vSrvRow.Service;
			vAccommodationServiceVATRate = vSrvRow.VATRate;
			vAccommodationRemarks = TrimAll(vSrvRow.Remarks);
			If SelGroupBy = "InPrice" Or SelGroupBy = "All" Then
				If ValueIsFilled(vAccommodationService) Then
					vSrvGrpDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, True);
					vAccommodationRemarks = vSrvGrpDescr;
				EndIf;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	
	// Group by services by the accommodation conditions
	vConditions = vServices.Copy();
	vConditions.GroupBy("AccommodationType, RoomType, Resource, Client, RoomQuantity", );
	vConditions.GroupBy("AccommodationType, RoomType, Resource", "RoomQuantity");
	For Each vConditionsRow In vConditions Do
		// Select services for the each condition
		vRowsArray = vServices.FindRows(New Structure("AccommodationType, RoomType, Resource", 
		                                vConditionsRow.AccommodationType, vConditionsRow.RoomType, 
		                                vConditionsRow.Resource));
		vCndServices = vServices.CopyColumns();
		For Each vRowElement In vRowsArray Do
			vCndServicesRow = vCndServices.Add();
			FillPropertyValues(vCndServicesRow, vRowElement);
		EndDo;
	
		For Each vSrvRow In vCndServices Do
			vSrvRow.AccountingDate = BegOfDay(SelInvoice.Date);
			vSrvRow.Client = Catalogs.Clients.EmptyRef();
			vSrvRow.NumberOfPersons = 0;
			vSrvRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
			vSrvRow.RoomType = Catalogs.RoomTypes.EmptyRef();
			vSrvRow.Room = Catalogs.Rooms.EmptyRef();
			vSrvRow.Resource = Catalogs.Resources.EmptyRef();
			vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
			If SelGroupBy = "InPrice" Or SelGroupBy = "All" Then
				If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vSrvRow.VATRate) Then
					If SelGroupBy = "InPrice" Then
						// Reset "is in price" flag if necessary
						If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.DoNotGroupIntoRoomRateOnPrint Then
							vSrvRow.IsInPrice = False;
						EndIf;
						If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
							vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
						ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
							If vSrvRow.Service.RoomRevenueAmountsOnly Then
								vSrvRow.Quantity = 0;
							EndIf;
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Price = 0;
							vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
						EndIf;
					ElsIf SelGroupBy = "All" Then
						If Not vSrvRow.IsRoomRevenue Then
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
							vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
						Else
							If vSrvRow.Service.RoomRevenueAmountsOnly Then
								vSrvRow.Quantity = 0;
							EndIf;
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Price = 0;
							vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		vCndServices.GroupBy("Service, Remarks, VATRate, AgentCommission", "Sum, VATSum, Price, Quantity, CommissionSum, DiscountSum");
		// Recalculate price for all services and delete zero sum rows
		i = 0;
		While i < vCndServices.Count() Do
			vSrvRow = vCndServices.Get(i);
			If vSrvRow.Sum = 0 And (SelGroupBy = "InPrice" Or SelGroupBy = "All") Then
				vCndServices.Delete(i);
			Else
				If vShowDiscounts Then
					vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum + vSrvRow.DiscountSum, vSrvRow.Quantity);
				Else
					vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
				EndIf;
				i = i + 1;
			EndIf;
		EndDo;
	EndDo;
	
	// Calculate totals
	vVATRateTransactions = New ValueTable();
	vVATRateTransactions.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
	vVATRateTransactions.Columns.Add("VATRateCode", cmGetNumberTypeDescription(4, 0));
	vVATRateTransactions.Columns.Add("Sum", cmGetSumTypeDescription());
	vVATRateTransactions.Columns.Add("VATSum", cmGetSumTypeDescription());
	
	vTotalSum = 0;
	vTotalSumNoCommission = 0;
	vTotalCommissionSum = 0;
	vTotalDiscountSum = 0;
	vTotalSumToBePaid = 0;
	vTotalVATSum = 0;

	vUseSectionVAT = False;
	For Each vSrvRow In vServices Do
		vTotalSum = vTotalSum + vSrvRow.Sum;
		If vShowDiscounts Then
			vTotalSum = vTotalSum + vSrvRow.DiscountSum;
		EndIf;
		vTotalSumToBePaid = vTotalSumToBePaid + vSrvRow.Sum;
		vTotalSumNoCommission = vTotalSumNoCommission + vSrvRow.Sum - vSrvRow.CommissionSum;
		vTotalCommissionSum = vTotalCommissionSum + vSrvRow.CommissionSum;
		vTotalDiscountSum = vTotalDiscountSum + vSrvRow.DiscountSum;
		
		// Get effective VAT rate
		vVATRate = vSrvRow.VATRate;
		If Not vDoNotUseSectionVAT And Not vIgnoreVATRate Then
			If ValueIsFilled(vSrvRow.Service) And ValueIsFilled(vSrvRow.Service.PaymentSection) And ValueIsFilled(vSrvRow.Service.PaymentSection.VATRate) And 
			   vSrvRow.VATRate <> vSrvRow.Service.PaymentSection.VATRate Then
				vVATRate = vSrvRow.Service.PaymentSection.VATRate;
				vUseSectionVAT = True;
			EndIf;
		EndIf;
		vSrvRow.VATRate = vVATRate;
		
		vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
		vTotalVATSum = vTotalVatSum + cmCalculateVATSum(vVATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
		
		vVATRateTransactionsRow = vVATRateTransactions.Add();
		vVATRateTransactionsRow.VATRate = vVATRate;
		vVATRateTransactionsRow.VATRateCode = ?(ValueIsFilled(vVATRate), vVATRate.Code, 0);
		vVATRateTransactionsRow.VATSum = vSrvRow.VATSum;
		vVATRateTransactionsRow.Sum = vSrvRow.Sum;
	EndDo;
	If ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
		vTotalSumToBePaid = vTotalSumNoCommission;
	Endif;
	vVATRateTransactions.GroupBy("VATRate, VATRateCode", "Sum, VATSum");
	vVATRateTransactions.Sort("VATRateCode");
	
	// Build footer
	vFooterAreas = new Array();
	vFooter1 = vTemplate.GetArea("Footer1");
	vCommission = vTemplate.GetArea("Commission");
	vDiscount = vTemplate.GetArea("Discount");
	vFooter2 = vTemplate.GetArea("Footer2");
	// Fill parameters
	mTotalSum = Format(vTotalSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
	mTotalVATSum = "";
	If Not (ValueIsFilled(vCompany) And vCompany.DoNotPrintVAT) Then
		If vTotalVATSum <> 0 Then
			mTotalVATSum = cmNStr("EN='Including VAT ';RU='В том числе НДС ';de='Darunter MwSt. '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
		Else
			If ValueIsFilled(SelInvoice.Company) And SelInvoice.Company.IsUsingSimpleTaxSystem Then
				mTotalVATSum = cmNStr("en='No VAT';ru='НДС не облагается в связи с применением упрощенной системы налогообложения (п. 2 ст. 346.11 НК РФ)';de='Im Zusammenhang mit der Anwendung des vereinfachten Besteuerungssystems wird die MwSt. nicht berechnet (Punkt 2 Artikel 346.11 des Steuergesetzes der Russischen Föderation)'", SelLanguage);
			Else
				If vVATRateTransactions.Count() > 0 Then
					vRowVatRate = vVATRateTransactions[0].VATRate;
					If ValueIsFilled(vRowVatRate) And Not vRowVatRate.NoVAT And vRowVatRate.TaxRate = 0 Then
						mTotalVATSum = cmNStr("EN='Including VAT ';RU='НДС ';de='Darunter MwSt. '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2; NZ=0.00") + " " + mAccountingCurrency;
					EndIf;	
				Else
					mTotalVATSum = cmNStr("en='No VAT';ru='НДС не облагается';de='MwSt. wird nicht berechnet'", SelLanguage); 
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If SelLanguage = Catalogs.Languages.DE Then
		mTotalVATSum = "";
	EndIf;
	// Set parameters
	vFooter1.Parameters.mTotalSum = mTotalSum;
	vFooter2.Parameters.mTotalVATSum = mTotalVATSum;
	vFooter2.Parameters.mTotalSumInWords = cmSumInWords(vTotalSumToBePaid, SelInvoice.AccountingCurrency, SelLanguage);;
	// Put footer
	vFooterAreas.Add(vFooter1);
	If vShowDiscounts And vDiscountPercent <> 0 Then
		vDiscount.Parameters.mDiscount = vDiscountPercent;
		vDiscount.Parameters.mTotalDiscountSum = Format(vTotalDiscountSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
		vDiscount.Parameters.mSumToBePaid = Format(vTotalSumToBePaid, "ND=17; NFD=2") + " " + mAccountingCurrency;
		vFooterAreas.Add(vDiscount);
	Else
		If vTotalCommissionSum <> 0 And 
		   ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
			mAgentCommission = "";   
			If ValueIsFilled(SelInvoice.GuestGroup) Then
				mAgentCommission = "" + GetAgentCommissionDescription(vAgentCommission, SelInvoice.GuestGroup.ClientDoc, SelLanguage);
			Else
				mAgentCommission = "" + vAgentCommission + "%";
			EndIf;
			vCommission.Parameters.mTotalCommissionSum = Format(vTotalCommissionSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
			vCommission.Parameters.mAgentCommission = mAgentCommission;
			vCommission.Parameters.mSumToBePaid = Format(vTotalSumToBePaid, "ND=17; NFD=2") + " " + mAccountingCurrency;
			vFooterAreas.Add(vCommission);
		EndIf;
	EndIf;
	vFooterAreas.Add(vFooter2);
	
	// VAT rates table
	If ValueIsFilled(vCompany) And Not vCompany.IsUsingSimpleTaxSystem Then
		vVATHeaderArea = vTemplate.GetArea("VATHeader");
		vFooterAreas.Add(vVATHeaderArea);
		For Each vVATRateRow In vVATRateTransactions Do
			vVATRateRowArea = vTemplate.GetArea("VATRateRow");
			vVATRateRowArea.Parameters.mVATRate = TrimAll(vVATRateRow.VATRate);
			vVATRateRowArea.Parameters.mSumWithoutVAT = Format(vVATRateRow.Sum - vVATRateRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mVATSum = Format(vVATRateRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mSumWithVAT = Format(vVATRateRow.Sum, "ND=17; NFD=2; NZ=");
			vFooterAreas.Add(vVATRateRowArea);
		EndDo;
	EndIf;
	
	// Signatures
	vSignedByManager = False;
	If ValueIsFilled(SelInvoice.Company) And SelInvoice.Company.InvoiceIsSignedByManager Then
		vSignedByManager = True;
	EndIf;
	If Not vSignedByManager Then
		If SelInvoice.PrintWithCompanyStamp Then
			vSignatures = vTemplate.GetArea("SignaturesWithStamp");
		Else
			vSignatures = vTemplate.GetArea("Signatures");
		EndIf;
		mCompanyDirector = TrimAll(cmNStr(vCompany.Director, SelLanguage));
		If Not IsBlankString(vCompany.DirectorPosition) Then
			mCompanyDirectorPosition = TrimAll(cmNStr(vCompany.DirectorPosition, SelLanguage));
		Else
			mCompanyDirectorPosition = cmNStr("en='Director';ru='Руководитель';de='Leiter'", SelLanguage);
		EndIf;
		mCompanyAccountantGeneral = TrimAll(cmNStr(vCompany.AccountantGeneral, SelLanguage));
		If Not IsBlankString(vCompany.AccountantGeneralPosition) Then
			mCompanyAccountantGeneralPosition = TrimAll(cmNStr(vCompany.AccountantGeneralPosition, SelLanguage));
		Else
			mCompanyAccountantGeneralPosition = cmNStr("en='Accountant';ru='Бухгалтер';de='Buchhalter'", SelLanguage);
		EndIf;
		vSignatures.Parameters.mRemarks = TrimAll(SelInvoice.RemarksForPrinting);
		If ValueIsFilled(SelInvoice.CheckDate) And (ValueIsFilled(SelInvoice.GuestGroup) And 
		   ValueIsFilled(SelInvoice.GuestGroup.CheckInDate) And BegOfDay(SelInvoice.GuestGroup.CheckInDate) >= BegOfDay(SelInvoice.CheckDate) Or Not ValueIsFilled(SelInvoice.GuestGroup)) Then
			vSignatures.Parameters.mRemarks = vSignatures.Parameters.mRemarks + ?(IsBlankString(vSignatures.Parameters.mRemarks), "", Chars.LF) + 
			                                  ?(vDoNotShowPayDueDate, "", cmNStr("en='Payment before '; ru='Оплата до '; de='Zahlung vor '; lv='Apmaksāt līdz '", SelLanguage) + Format(SelInvoice.CheckDate, "DF=dd.MM.yyyy"));
		EndIf;
		vSignatures.Parameters.mCompanyDirector = mCompanyDirector;
		vSignatures.Parameters.mCompanyDirectorPosition = mCompanyDirectorPosition;
		vSignatures.Parameters.mCompanyAccountantGeneral = mCompanyAccountantGeneral;
		vSignatures.Parameters.mCompanyAccountantGeneralPosition = mCompanyAccountantGeneralPosition;
		// Company stamp
		If SelInvoice.PrintWithCompanyStamp Then
			If vStampIsSet Then
				vSignatures.Drawings.Stamp.Print = True;
				vSignatures.Drawings.Stamp.Picture = vStamp;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.Stamp);
			EndIf;
			If vDirectorSignatureIsSet Then
				vSignatures.Drawings.DirectorSignature.Print = True;
				vSignatures.Drawings.DirectorSignature.Picture = vDirectorSignature;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.DirectorSignature);
			EndIf;
			If vAccountantGeneralSignatureIsSet Then
				vSignatures.Drawings.AccountantGeneralSignature.Print = True;
				vSignatures.Drawings.AccountantGeneralSignature.Picture = vAccountantGeneralSignature;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.AccountantGeneralSignature);
			EndIf;
		EndIf;
		// Form text
		vSignatures.Parameters.mFormText = TrimR(SelObjectPrintForm.FormText);
		// Put signatures	
		vFooterAreas.Add(vSignatures);
	Else
		If SelInvoice.PrintWithCompanyStamp Then
			vSignatures = vTemplate.GetArea("ManagerSignatureWithStamp");
		Else
			vSignatures = vTemplate.GetArea("ManagerSignature");
		EndIf;
		mPosition = cmNStr("en='Manager';ru='Менеджер';de='Manager'", SelLanguage);
		mEmployee = "";
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			If Not IsBlankString(SessionParameters.CurrentUser.Position) Then
				mPosition = cmNStr(SessionParameters.CurrentUser.Position, SelLanguage);
			EndIf;
			If Not IsBlankString(SessionParameters.CurrentUser.DescriptionTranslations) Then
				mEmployee = cmNStr(SessionParameters.CurrentUser.DescriptionTranslations, SelLanguage);
			Else
				mEmployee = TrimAll(SessionParameters.CurrentUser.Description);
			EndIf;
		EndIf;
		vSignatures.Parameters.mRemarks = TrimAll(SelInvoice.RemarksForPrinting);
		If ValueIsFilled(SelInvoice.CheckDate) And (ValueIsFilled(SelInvoice.GuestGroup) And 
		   ValueIsFilled(SelInvoice.GuestGroup.CheckInDate) And BegOfDay(SelInvoice.GuestGroup.CheckInDate) >= BegOfDay(SelInvoice.CheckDate) Or Not ValueIsFilled(SelInvoice.GuestGroup)) Then
			vSignatures.Parameters.mRemarks = vSignatures.Parameters.mRemarks + ?(IsBlankString(vSignatures.Parameters.mRemarks), "", Chars.LF) + 
			                                  ?(vDoNotShowPayDueDate, "", cmNStr("en='Payment before '; ru='Оплата до '; de='Zahlung vor '; lv='Apmaksāt līdz '", SelLanguage) + Format(SelInvoice.CheckDate, "DF=dd.MM.yyyy"));
		EndIf;
		vSignatures.Parameters.mPosition = mPosition;
		vSignatures.Parameters.mEmployee = mEmployee;
		// Company stamp and manager's signature
		If SelInvoice.PrintWithCompanyStamp Then
			If vSignatureIsSet Then
				vSignatures.Drawings.Signature.Print = True;
				If TypeOf(vSignature) = Type("BinaryData") Then
					vSignatures.Drawings.Signature.Picture = New Picture(vSignature);	
				Else
					vSignatures.Drawings.Signature.Picture = vSignature;
				EndIf;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.Signature);
			EndIf;
			If vStampIsSet Then
				vSignatures.Drawings.ManagerStamp.Print = True;
				vSignatures.Drawings.ManagerStamp.Picture = vStamp;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.ManagerStamp);
			EndIf;
		EndIf;
		// Form text
		vSignatures.Parameters.mFormText = TrimR(SelObjectPrintForm.FormText);
		// Put signatures	
		vFooterAreas.Add(vSignatures);
	EndIf;
	
	// Group by services by the accommodation conditions
	vConditions = vServices.Copy();
	vConditions.GroupBy("AccommodationType, RoomType, Resource, Client, RoomQuantity", );
	vConditions.GroupBy("AccommodationType, RoomType, Resource", "RoomQuantity");
	For Each vConditionsRow In vConditions Do
		// Select services for the each condition
		vRowsArray = vServices.FindRows(New Structure("AccommodationType, RoomType, Resource", 
		                                vConditionsRow.AccommodationType, vConditionsRow.RoomType, 
		                                vConditionsRow.Resource));
		vCndServices = vServices.CopyColumns();
		For Each vRowElement In vRowsArray Do
			vCndServicesRow = vCndServices.Add();
			FillPropertyValues(vCndServicesRow, vRowElement);
		EndDo;
		
		vGuests = vCndServices.Copy();
		vGuests.GroupBy("Client", );
		vGuests.Sort("Client");
		vGuestNames = "";
		For Each vGuestsRow In vGuests Do
			If ValueIsFilled(vGuestsRow.Client) Then
				If IsBlankString(vGuestNames) Then
					vGuestNames = TrimAll(vGuestsRow.Client);
				Else
					vGuestNames = vGuestNames + ", " + TrimAll(vGuestsRow.Client);
				EndIf;
			EndIf;
		EndDo;
	
		vCurPeriodPresentation = "";
		vCurDateTimeFrom = '39991231';
		vCurDateTimeTo = '00010101';
		For Each vSrvRow In vCndServices Do
			vSrvRow.AccountingDate = BegOfDay(SelInvoice.Date);
			vSrvRow.Client = Catalogs.Clients.EmptyRef();
			vSrvRow.NumberOfPersons = 0;
			vSrvRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
			vSrvRow.RoomType = Catalogs.RoomTypes.EmptyRef();
			vSrvRow.Room = Catalogs.Rooms.EmptyRef();
			vSrvRow.Resource = Catalogs.Resources.EmptyRef();
			vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
			If SelGroupBy = "InPrice" Or SelGroupBy = "All" Then
				If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vSrvRow.VATRate) Then
					If SelGroupBy = "InPrice" Then
						// Reset "is in price" flag if necessary
						If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.DoNotGroupIntoRoomRateOnPrint Then
							vSrvRow.IsInPrice = False;
						EndIf;
						If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
							vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
						ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
							If vSrvRow.Service.RoomRevenueAmountsOnly Then
								vSrvRow.Quantity = 0;
							EndIf;
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Price = 0;
							vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
						EndIf;
					ElsIf SelGroupBy = "All" Then
						If Not vSrvRow.IsRoomRevenue Then
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
							vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
						Else
							If vSrvRow.Service.RoomRevenueAmountsOnly Then
								vSrvRow.Quantity = 0;
							EndIf;
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Price = 0;
							vSrvRow.VATRate = ?(vIgnoreVATRate And ValueIsFilled(vAccommodationServiceVATRate), vAccommodationServiceVATRate, vSrvRow.VATRate);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If Find(vParameter, "SHOW_ACCOMMODATION_PERIOD") > 0 Then
				If ValueIsFilled(vSrvRow.DateTimeFrom) Then
					vCurDateTimeFrom = Min(vCurDateTimeFrom, vSrvRow.DateTimeFrom);
				EndIf;
				If ValueIsFilled(vSrvRow.DateTimeTo) Then
					vCurDateTimeTo = Max(vCurDateTimeTo, vSrvRow.DateTimeTo);
				EndIf;
			EndIf;
		EndDo;
		vCndServices.GroupBy("Service, Remarks, VATRate", "Sum, VATSum, Price, Quantity, CommissionSum, DiscountSum");
		If ValueIsFilled(vCurDateTimeFrom) And ValueIsFilled(vCurDateTimeTo) Then
			If BegOfDay(vCurDateTimeFrom) < BegOfDay(vCurDateTimeTo) Then
				vCurPeriodPresentation = Format(BegOfDay(vCurDateTimeFrom), "DF=dd.MM.yyyy") + " - " + Format(BegOfDay(vCurDateTimeTo), "DF=dd.MM.yyyy");
			Else
				vCurPeriodPresentation = Format(BegOfDay(vCurDateTimeFrom), "DF=dd.MM.yyyy");
			EndIf;
		EndIf;
		// Recalculate price for all services and delete zero sum rows
		i = 0;
		While i < vCndServices.Count() Do
			vSrvRow = vCndServices.Get(i);
			If vSrvRow.Sum = 0 And (SelGroupBy = "InPrice" Or SelGroupBy = "All") Then
				vCndServices.Delete(i);
			Else
				If Not vIgnoreVATRate Then
					vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, Date);
				EndIf;
				If vShowDiscounts Then
					vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum + vSrvRow.DiscountSum, vSrvRow.Quantity);
				Else
					vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
				EndIf;
				i = i + 1;
			EndIf;
		EndDo;
	
		// Print condition header
		vRStr = "";
		If ValueIsFilled(vConditionsRow.RoomType) Then
			If Find(vParameter, "NO_RTYPE") = 0 Then
				vRStr = vRStr + vConditionsRow.RoomType.GetObject().pmGetRoomTypeDescription(SelLanguage);
			EndIf;
		ElsIf ValueIsFilled(vConditionsRow.Resource) Then
			If Find(vParameter, "NO_RESOURCE") = 0 Then
				vRStr = vRStr + vConditionsRow.Resource.GetObject().pmGetResourceDescription(SelLanguage);
			EndIf;
		EndIf;
		mCondition = ?(IsBlankString(vRStr), "" , vRStr) + 
		             ?(IsBlankString(vGuestNames), "", ", " + vGuestNames) + 
					 ?(IsBlankString(vCurPeriodPresentation), "", ", " + vCurPeriodPresentation);
		If Left(mCondition, 1) = "," Then
			mCondition = Mid(mCondition, 3);
		EndIf;
					 
		// Set client area parameters
		vClient.Parameters.mClient = mCondition;
		// Put client area
		vSpreadsheet.Put(vClient);
		For Each vSrvRow In vCndServices Do
			// Fill row parameters
			mPrice = vSrvRow.Price;
			If vShowDiscounts Then
				mSum = vSrvRow.Sum + vSrvRow.DiscountSum;
			Else
				mSum = vSrvRow.Sum;
			EndIf;
			If Round(vSrvRow.Quantity, 3) <> vSrvRow.Quantity Then
				mQuantity = ?(vSrvRow.Quantity = 0, "", Format(vSrvRow.Quantity, "ND=17; NFD=3"));
			Else
				mQuantity = ?(vSrvRow.Quantity = 0, "", String(vSrvRow.Quantity));
			EndIf;
			If ValueIsFilled(vSrvRow.Service) Then
				If vSrvRow.Quantity <> 0 Then
					vServiceObj = vSrvRow.Service.GetObject();
					If vConditionsRow.RoomQuantity <> 0 And 
					   ValueIsFilled(vAccommodationService) And vSrvRow.Service = vAccommodationService And 
					   vConditionsRow.RoomQuantity > 1 Then
						mQuantity = Format(vConditionsRow.RoomQuantity, "ND=10; NFD=0; NG=") + "*" + vServiceObj.pmGetServiceQuantityPresentation(vSrvRow.Quantity/vConditionsRow.RoomQuantity, SelLanguage);
					Else
						mQuantity = vServiceObj.pmGetServiceQuantityPresentation(vSrvRow.Quantity, SelLanguage);
					EndIf;
				EndIf;
			EndIf;
			If ExtraInvoice Then
				If Services.Count() = 1 Then
					If vSrvRow.Quantity = 1 Then
						mQuantity = Format(vSrvRow.Quantity, "ND=17; NFD=0");
					EndIf;
				EndIf;
			EndIf;
			mDescription = Chars.Tab + StrReplace(TrimAll(vSrvRow.Remarks), Chars.LF, Chars.LF + Chars.Tab + Chars.Tab);
			
			vRow.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
			vRow.Parameters.mQuantity = mQuantity;
			vRow.Parameters.mDescription = mDescription;
			vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
			// Put row
			If Not IsBlankString(vRow.Parameters.mSum) Then
				// Check if we can print footer completely
				If (vConditions.IndexOf(vConditionsRow) + 1) = vConditions.Count() And 
				   (vCndServices.IndexOf(vSrvRow) + 1) = vCndServices.Count() Then
					vFooterAreas.Insert(0, vRow);
					If Not vSpreadsheet.CheckPut(vFooterAreas) Then
						vSpreadsheet.PutHorizontalPageBreak();
						vSpreadsheet.Put(vTableHeader);
					EndIf;
					vFooterAreas.Delete(0);
				Else
					If Not vSpreadsheet.CheckPut(vRow) Then
						vSpreadsheet.PutHorizontalPageBreak();
						vSpreadsheet.Put(vTableHeader);
					EndIf;
				EndIf;
				vSpreadsheet.Put(vRow);
			EndIf;
		EndDo;
	EndDo;
	
	// Put footer areas
	For Each vFooterArea In vFooterAreas Do
		vSpreadsheet.Put(vFooterArea);
	EndDo;

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // pmPrintInvoiceShort

// -----------------------------------------------------------------------------
Procedure pmPrintInvoiceHotelProduct(vSpreadsheet, SelLanguage, SelGroupBy, SelObjectPrintForm, mInvoiceNumber, pClear = True) Export
	SelInvoice = ThisObject;
	
	// Basic checks
	vHotel = SelInvoice.Hotel;
	If Not ValueIsFilled(vHotel) Then
		Raise NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'");
	EndIf;
	vCompany = SelInvoice.Company;
	If Not ValueIsFilled(vCompany) Then
		Raise NStr("ru='Не задана фирма!';de='Die Firma ist nicht angegeben!';en='Company should be filled!'");
	EndIf;
	vAccount = SelInvoice.BankAccount;
	If Not ValueIsFilled(vAccount) Then
		vAccount = vCompany.BankAccount;
	EndIf;
	If Not ValueIsFilled(vAccount) Then
		Raise NStr("ru='Не задан расчетный счет фирмы!';de='Das Verrechnungskonto der Firma ist nicht angegeben!';en='Company account should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Print form parameter
	vParameter = Upper(TrimAll(SelObjectPrintForm.Parameter));
	vShowDiscounts = (Find(vParameter, "SHOW_DISCOUNT") > 0);
	vDoNotShowPayDueDate = (Find(vParameter, "DO_NOT_SHOW_PAY_DUE_DATE") > 0);
	
	// Choose template
	If pClear Then
		vSpreadsheet.Clear();
	EndIf;
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = SelInvoice.GetTemplate("InvoiceHotelProductsEn");
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplate = SelInvoice.GetTemplate("InvoiceHotelProductsDe");
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = SelInvoice.GetTemplate("InvoiceHotelProductsRu");
		Else
			Raise NStr("ru='Не найден шаблон печатной формы акта для языка " + SelLanguage.Code + "!'; 
			           |de='No invoice print form template found for the " + SelLanguage.Code + " language!'; 
			           |en='No invoice print form template found for the " + SelLanguage.Code + " language!'");
		EndIf;
	Else
		vTemplate = SelInvoice.GetTemplate("InvoiceHotelProductsRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(SelInvoice.Hotel) Then
		If SelInvoice.Hotel.Logo <> Undefined Then
			vLogo = SelInvoice.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vStampIsSet = False;
	vStamp = New Picture;
	If ValueIsFilled(SelInvoice.Company) Then
		If SelInvoice.Company.Stamp <> Undefined Then
			vStamp = SelInvoice.Company.Stamp.Get();
			If vStamp = Undefined Then
				vStamp = New Picture;
			Else
				vStampIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vSignatureIsSet = False;
	vSignature = New Picture;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If SessionParameters.CurrentUser.Signature <> Undefined Then
			vSignature = SessionParameters.CurrentUser.Signature.Get();
			If vSignature = Undefined Then
				vSignature = New Picture;
			Else
				vSignatureIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vDirectorSignatureIsSet = False;
	vDirectorSignature = New Picture;
	If SelInvoice.Company.DirectorSignature <> Undefined Then
		vDirectorSignature = SelInvoice.Company.DirectorSignature.Get();
		If vDirectorSignature = Undefined Then
			vDirectorSignature = New Picture;
		Else
			vDirectorSignatureIsSet = True;
		EndIf;
	EndIf;
	vAccountantGeneralSignatureIsSet = False;
	vAccountantGeneralSignature = New Picture;
	If SelInvoice.Company.AccountantGeneralSignature <> Undefined Then
		vAccountantGeneralSignature = SelInvoice.Company.AccountantGeneralSignature.Get();
		If vAccountantGeneralSignature = Undefined Then
			vAccountantGeneralSignature = New Picture;
		Else
			vAccountantGeneralSignatureIsSet = True;
		EndIf;
	EndIf;
	
	// Header
	vRubHeader = False;
	If SelInvoice.AccountingCurrency.Code = 643 And vHotel.Citizenship.Code = 643 Then
		vRubHeader = True;
	EndIf;
	
	// Hotel
	mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, SelLanguage);
	mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, SelLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vHotelFax);
	mHotelEMail = TrimAll(vHotel.EMail);
	
	// Company
	vCompanyObj = vCompany.GetObject();
	vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
	vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
	vCompanyPostAddress = vCompanyObj.pmGetCompanyPostAddressPresentation(SelLanguage);
	If vCompanyPostAddress = vCompanyLegacyAddress Then
		vCompanyPostAddress = "";
	EndIf;
	mCompanyTIN = TrimAll(vCompany.TIN);
	mCompanyKPP = TrimAll(vCompany.KPP);
	vCompanyTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН'", SelLanguage) + ?(IsBlankString(mCompanyKPP), " ", "/" + cmNStr("en='KPP ';de='KPP ';ru='КПП '", SelLanguage)) + mCompanyTIN + ?(IsBlankString(mCompanyKPP), "", "/" + mCompanyKPP);
	vCompanyPhones = TrimAll(vCompany.Phones) + ?(IsBlankString(vCompany.Fax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + TrimAll(vCompany.Fax));
	mCompany = TrimAll(vCompanyLegacyName + vCompanyTIN + Chars.LF + vCompanyLegacyAddress + Chars.LF + ?(IsBlankString(vCompanyPostAddress), "", vCompanyPostAddress + Chars.LF) + vCompanyPhones);
	
	// Invoice date and number
	If vCompany.UseGroupCodeAsInvoiceNumberPrefix Then
		If vCompany.PrintInvoiceAndSettlementNumbersWithPrefixes Then
			vCompanyPrefix = TrimAll(vCompany.Prefix);
			If Not IsBlankString(vCompanyPrefix) Then
				mInvoiceNumber = vCompanyPrefix + cmRemoveLeadingZeroes(SelInvoice.Number);
			Else
				mInvoiceNumber = cmRemoveLeadingZeroes(SelInvoice.Number);
			EndIf;
		Else
			vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelInvoice.Hotel);
			If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
				mInvoiceNumber = vHotelPrefix + cmRemoveLeadingZeroes(SelInvoice.Number);
			Else
				mInvoiceNumber = cmRemoveLeadingZeroes(SelInvoice.Number);
			EndIf;
		EndIf;
	Else
		mInvoiceNumber = ?(vCompany.PrintInvoiceAndSettlementNumbersWithPrefixes, TrimAll(SelInvoice.Number), cmGetDocumentNumberPresentation(SelInvoice.Number));
	EndIf;
	mInvoiceDate = cmGetDocumentDatePresentation(SelInvoice.Date);
	
	vTableHeader = vTemplate.GetArea("TableHeader");
	
	// Print different invoice headers for invoices in RUR and Russia base country and other currencies/countries
	If vRubHeader Then
		vHeader = vTemplate.GetArea("Header");
		
		mCompanyPaymentAttributes = vCompanyLegacyName;
		mCompanyBank = "";
		mCompanyBankAcount = "";
		mCompanyBankBIC = "";
		mCompanyBankCorrAccount = "";
		If vAccount.IsDirectPayments Then
			mCompanyBank = TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity);
			
			mCompanyBankAccount = TrimAll(vAccount.AccountNumber);
			mCompanyBankBIC = TrimAll(vAccount.BankBIC);
			mCompanyBankCorrAccount = TrimAll(vAccount.BankCorrAccountNumber);
		Else
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + cmNStr("en=' acc ';ru=' р/с ';de=' Verrechnungskonto '", SelLanguage) + TrimAll(vAccount.AccountNumber);
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + cmNStr("en=' in ';ru=' в ';de=' in '", SelLanguage) + TrimAll(vAccount.BankName);
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + " " + TrimAll(vAccount.BankCity);
		
			mCompanyBank = TrimAll(vAccount.CorrBankName);
			mCompanyBank = mCompanyBank + TrimAll(vAccount.CorrBankCity);
			
			mCompanyBankAccount = TrimAll(vAccount.BankCorrAccountNumber);
			mCompanyBankBIC = TrimAll(vAccount.CorrBankBIC);
			mCompanyBankCorrAccount = TrimAll(vAccount.CorrBankCorrAccountNumber);
		EndIf;
		If Not IsBlankString(vAccount.Beneficiary) Then
			mCompanyPaymentAttributes = TrimAll(vAccount.Beneficiary);
		EndIf;
		If Not IsBlankString(vCompany.OKTMO) Or Not IsBlankString(vCompany.KBK) Then
			mCompanyPaymentAttributes = mCompanyPaymentAttributes + Chars.LF;
			If Not IsBlankString(vCompany.OKTMO) Then
				mCompanyPaymentAttributes = mCompanyPaymentAttributes + "ОКТМО " + TrimAll(vCompany.OKTMO);
			EndIf;
			If Not IsBlankString(vCompany.KBK) Then
				If Not IsBlankString(vCompany.OKTMO) Then
					mCompanyPaymentAttributes = mCompanyPaymentAttributes + ", ";
				EndIf;
				mCompanyPaymentAttributes = mCompanyPaymentAttributes + "КБК " + TrimAll(vCompany.KBK);
			EndIf;
		EndIf;
		
		// Customer
		vCustomerCode = "";
		If SelInvoice.AccountingCustomer = vHotel.IndividualsCustomer Then
			// Use contact person as customer
			If Not IsBlankString(SelInvoice.ContactPerson) Then
				mCustomer = TrimAll(SelInvoice.ContactPerson);
			Else				
				vClientRef = Catalogs.Clients.EmptyRef();
				// Use guest group client as customer
				If ValueIsFilled(SelInvoice.GuestGroup) And ValueIsFilled(SelInvoice.GuestGroup.Client) Then
					vClientRef = SelInvoice.GuestGroup.Client;
				// Use first client as customer
				Else
					For Each vRow In SelInvoice.Services Do
						If ValueIsFilled(vRow.Client) Then
							vClientRef = vRow.Client;
							Break;
						EndIf;
					EndDo;
				EndIf;
				vCustomer = vClientRef;
				vCustomerLegacyName = "";
				vCustomerLegacyAddress = "";
				vCustomerTIN = "";
				vCustomerPhones = "";
				If ValueIsFilled(vClientRef) Then
					vCustomerLegacyName = TrimAll(vClientRef.FullName);
					vCustomerLegacyAddress = cmGetAddressPresentation(vClientRef.Address);
					vCustomerTIN = "";
					vCustomerKPP = "";
					// Fax and E-Mail
					vCustomerPhones = TrimAll(vClientRef.Phone);
					vCustomerFax = TrimAll(vClientRef.Fax);
					vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
				EndIf;
				mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + vCustomerPhones);
			EndIf;
			// Contract
			mContract = "";
		Else
			vCustomer = SelInvoice.AccountingCustomer;
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
				If Not vCustomer.IsIndividual Then
					vCustomerCode = TrimAll(vCustomer.Code);
				EndIf;
				
				// Addresses
				vCustomerLegacyAddress = cmGetAddressPresentation(vCustomer.LegacyAddress);
				vCustomerPostAddress = cmGetAddressPresentation(vCustomer.PostAddress);
				If vCustomerPostAddress = vCustomerLegacyAddress Then
					vCustomerPostAddress = "";
				EndIf;
				
				// Codes
				vCustomerTIN = TrimAll(vCustomer.TIN);
				vCustomerKPP = TrimAll(vCustomer.KPP);
				vCustomerTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН '", SelLanguage) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP);
				// Fax and E-Mail
				vCustomerPhones = TrimAll(vCustomer.Phone);
				vCustomerFax = TrimAll(vCustomer.Fax);
				vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
			EndIf;
			mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + vCustomerPhones);
			// Contract
			mContract = "";
			If ValueIsFilled(SelInvoice.AccountingContract) Then
				mContract = TrimAll(SelInvoice.AccountingContract.Description);
			EndIf;
		EndIf;
		// Guest group code
		mGuestGroup = "";
		vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelInvoice.Hotel);
		If ValueIsFilled(SelInvoice.GuestGroup) Then
			mGuestGroup = Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=");
			If Not IsBlankString(SelInvoice.GuestGroup.ID) Then
				mGuestGroup = mGuestGroup + " - Ref. # " + TrimAll(SelInvoice.GuestGroup.ID);
			ElsIf Not IsBlankString(SelInvoice.GuestGroup.Description) Then
				mGuestGroup = mGuestGroup + " - " + TrimAll(SelInvoice.GuestGroup.Description);
			EndIf;
			If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
				mGuestGroup = vHotelPrefix + mGuestGroup;
			EndIf;
		Else
			vGroups = SelInvoice.Services.Unload(, "GuestGroup");
			vGroups.GroupBy("GuestGroup", );
			For Each vGroupsRow In vGroups Do
				If ValueIsFilled(vGroupsRow.GuestGroup) Then
					vGuestGroupCode = Format(vGroupsRow.GuestGroup.Code, "ND=12; NFD=0; NG=");
					If Not IsBlankString(vHotelPrefix) And SelInvoice.Hotel.ShowHotelPrefixBeforeGroupCode Then
						vGuestGroupCode = vHotelPrefix + vGuestGroupCode;
					EndIf;
					If IsBlankString(mGuestGroup) Then
						mGuestGroup = vGuestGroupCode;
					Else
						mGuestGroup = mGuestGroup + ", " + vGuestGroupCode;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Currency
		mAccountingCurrency = "";
		If ValueIsFilled(SelInvoice.AccountingCurrency) Then
			vCurrencyObj = SelInvoice.AccountingCurrency.GetObject();
			mAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
		EndIf;
		// Parent document
		mParentDoc = ?(ValueIsFilled(SelInvoice.ParentDoc), TrimAll(SelInvoice.ParentDoc.Number), "");
		mFullInvoiceNumber = Trimall(SelInvoice.Number) + ?(IsBlankString(vCustomerCode), "", " " + vCustomerCode);
		// Set parameters and put report section
		vHeader.Parameters.mHotelPrintName = mHotelPrintName;
		vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
		vHeader.Parameters.mHotelPhones = mHotelPhones;
		vHeader.Parameters.mHotelEMail = mHotelEMail;
		vHeader.Parameters.mInvoiceNumber = mInvoiceNumber;
		vHeader.Parameters.mFullInvoiceNumber = mFullInvoiceNumber;
		vHeader.Parameters.mInvoiceDate = mInvoiceDate;
		If SelInvoice.AccountingCurrency = vHotel.BaseCurrency Then
			vHeader.Parameters.mCompany = mCompany;
			vHeader.Parameters.mCompanyTIN = mCompanyTIN;
			vHeader.Parameters.mCompanyKPP = mCompanyKPP;
			vHeader.Parameters.mCompanyBankBIC = mCompanyBankBIC;
			vHeader.Parameters.mCompanyBankCorrAccount = mCompanyBankCorrAccount;
		EndIf;
		vHeader.Parameters.mCompanyPaymentAttributes = mCompanyPaymentAttributes;
		vHeader.Parameters.mCompanyBank = mCompanyBank;
		vHeader.Parameters.mCompanyBankAccount = mCompanyBankAccount;
		vHeader.Parameters.mCustomer = mCustomer;
		vHeader.Parameters.mInvoiceEMail = TrimAll(SelInvoice.EMail);
		vHeader.Parameters.mContract = mContract;
		vHeader.Parameters.mGuestGroup = mGuestGroup;
		vHeader.Parameters.mAccountingCurrency = mAccountingCurrency;
		vHeader.Parameters.mParentDoc = mParentDoc;
		// Logo
		If vLogoIsSet Then
			vHeader.Drawings.Logo.Print = True;
			vHeader.Drawings.Logo.Picture = vLogo;
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.Logo);
		EndIf;
		// Put header		
		vSpreadsheet.Put(vHeader);
		vSpreadsheet.Put(vTableHeader);
	Else
		vHeader1 = vTemplate.GetArea("HeaderCurrency1");
		
		If Not IsBlankString(vAccount.Beneficiary) Then
			mCompany = TrimAll(vAccount.Beneficiary);
		EndIf;
		
		mCompanyBank = TrimAll(TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity));
		mCompanyBankAccount = TrimAll(vAccount.AccountNumber);
		If Not IsBlankString(vAccount.BankBIC) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='BIC ';ru='БИК ';de='BIC '", SelLanguage) + TrimAll(vAccount.BankBIC);
		EndIf;
		If Not IsBlankString(vAccount.BankCorrAccountNumber) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='Corr. acc. № ';ru='Корр. сч. № ';de='Korrespondenzkonto Nr. '", SelLanguage) + TrimAll(vAccount.BankCorrAccountNumber);
		EndIf;
		If Not IsBlankString(vAccount.BankTINCode) Then
			mCompanyBank = mCompanyBank + Chars.LF + TrimAll(vAccount.BankTINCode);
		EndIf;
		If Not IsBlankString(vAccount.BankIBAN) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='IBAN CODE ';de='IBAN CODE ';ru='IBAN CODE '", SelLanguage) + TrimAll(vAccount.BankIBAN);
		EndIf;
		If Not IsBlankString(vAccount.BankSWIFTCode) Then
			mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='SWIFT CODE ';de='SWIFT CODE ';ru='SWIFT CODE '", SelLanguage) + TrimAll(vAccount.BankSWIFTCode);
		EndIf;
		
		// Set parameters and put report section
		vHeader1.Parameters.mHotelPrintName = mHotelPrintName;
		vHeader1.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
		vHeader1.Parameters.mHotelPhones = mHotelPhones;
		vHeader1.Parameters.mHotelEMail = mHotelEMail;
		vHeader1.Parameters.mInvoiceNumber = mInvoiceNumber;
		vHeader1.Parameters.mInvoiceDate = mInvoiceDate;
		vHeader1.Parameters.mCompany = mCompany;
		vHeader1.Parameters.mCompanyBankAccount = mCompanyBankAccount;
		vHeader1.Parameters.mCompanyBank = mCompanyBank;
		// Logo
		If vLogoIsSet Then
			vHeader1.Drawings.LogoCurrency.Print = True;
			vHeader1.Drawings.LogoCurrency.Picture = vLogo;
		Else
			vHeader1.Drawings.Delete(vHeader1.Drawings.LogoCurrency);
		EndIf;
		// Put header1		
		vSpreadsheet.Put(vHeader1);
		
		// Put correspondent bank header
		If Not vAccount.IsDirectPayments Then
			vCorrBankHeader = vTemplate.GetArea("CorrBank");
			
			mCompanyCorrBank = TrimAll(TrimAll(vAccount.CorrBankName) + " " + TrimAll(vAccount.CorrBankCity));
			If Not IsBlankString(vAccount.CorrBankBIC) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='BIC ';ru='БИК ';de='BIC '", SelLanguage) + TrimAll(vAccount.CorrBankBIC);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankCorrAccountNumber) Then
				mCompanyCorrBank = mCompanyCorrBank + cmNStr("en='Corr. acc. № ';ru='Корр. сч. № ';de='Korrespondenzkonto Nr. '", SelLanguage) + TrimAll(vAccount.CorrBankCorrAccountNumber);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankTINCode) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + TrimAll(vAccount.CorrBankTINCode);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankIBAN) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='IBAN CODE ';de='IBAN CODE ';RU='IBAN CODE '", SelLanguage) + TrimAll(vAccount.CorrBankIBAN);
			EndIf;
			If Not IsBlankString(vAccount.CorrBankSWIFTCode) Then
				mCompanyCorrBank = mCompanyCorrBank + Chars.LF + cmNStr("en='SWIFT CODE ';de='SWIFT CODE ';RU='SWIFT CODE '", SelLanguage) + TrimAll(vAccount.CorrBankSWIFTCode);
			EndIf;
			
			// Set parameters and put report section
			vCorrBankHeader.Parameters.mCompanyCorrBank = mCompanyCorrBank;
			
			// Put corr. bank header
			vSpreadsheet.Put(vCorrBankHeader);
		EndIf;
		
		// Table header
		vHeader2 = vTemplate.GetArea("HeaderCurrency2");
		
		// Customer
		vCustomerCode = "";
		If SelInvoice.AccountingCustomer = vHotel.IndividualsCustomer Then
			// Use contact person as customer
			If Not IsBlankString(SelInvoice.ContactPerson) Then
				mCustomer = TrimAll(SelInvoice.ContactPerson);
			Else				
				vClientRef = Catalogs.Clients.EmptyRef();
				// Use guest group client as customer
				If ValueIsFilled(SelInvoice.GuestGroup) And ValueIsFilled(SelInvoice.GuestGroup.Client) Then
					vClientRef = SelInvoice.GuestGroup.Client;
				// Use first client as customer
				Else
					For Each vRow In SelInvoice.Services Do
						If ValueIsFilled(vRow.Client) Then
							vClientRef = vRow.Client;
							Break;
						EndIf;
					EndDo;
				EndIf;
				vCustomer = vClientRef;
				vCustomerLegacyName = "";
				vCustomerLegacyAddress = "";
				vCustomerTIN = "";
				vCustomerPhones = "";
				If ValueIsFilled(vClientRef) Then
					vCustomerLegacyName = TrimAll(vClientRef.FullName);
					vCustomerLegacyAddress = cmGetAddressPresentation(vClientRef.Address);
					vCustomerTIN = "";
					vCustomerKPP = "";
					// Fax and E-Mail
					vCustomerPhones = TrimAll(vClientRef.Phone);
					vCustomerFax = TrimAll(vClientRef.Fax);
					vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
				EndIf;
				mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + vCustomerPhones);
			EndIf;
			// Contract
			mContract = "";
		Else
			vCustomer = SelInvoice.AccountingCustomer;
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
				If Not vCustomer.IsIndividual Then
					vCustomerCode = TrimAll(vCustomer.Code);
				EndIf;
				
				// Addresses
				vCustomerLegacyAddress = cmGetAddressPresentation(vCustomer.LegacyAddress);
				vCustomerPostAddress = cmGetAddressPresentation(vCustomer.PostAddress);
				If vCustomerPostAddress = vCustomerLegacyAddress Then
					vCustomerPostAddress = "";
				EndIf;
				
				// Codes
				vCustomerTIN = TrimAll(vCustomer.TIN);
				vCustomerKPP = TrimAll(vCustomer.KPP);
				vCustomerTIN = cmNStr("en=', Reg. N ';de=', Reg. N ';ru=', ИНН '", SelLanguage) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP);
				// Fax and E-Mail
				vCustomerPhones = TrimAll(vCustomer.Phone);
				vCustomerFax = TrimAll(vCustomer.Fax);
				vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SelLanguage) + vCustomerFax);
			EndIf;
			mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + Chars.LF + ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + vCustomerPhones);
			// Contract
			mContract = "";
			If ValueIsFilled(SelInvoice.AccountingContract) Then
				mContract = TrimAll(SelInvoice.AccountingContract.Description);
			EndIf;
		EndIf;
		// Guest group code
		mGuestGroup = "";
		If ValueIsFilled(SelInvoice.GuestGroup) Then
			mGuestGroup = Format(SelInvoice.GuestGroup.Code, "ND=12; NFD=0; NG=");
			If Not IsBlankString(SelInvoice.GuestGroup.ID) Then
				mGuestGroup = mGuestGroup + " - Ref. # " + TrimAll(SelInvoice.GuestGroup.ID);
			ElsIf Not IsBlankString(SelInvoice.GuestGroup.Description) Then
				mGuestGroup = mGuestGroup + " - " + TrimAll(SelInvoice.GuestGroup.Description);
			EndIf;
		Else
			vGroups = SelInvoice.Services.Unload(, "GuestGroup");
			vGroups.GroupBy("GuestGroup", );
			For Each vGroupsRow In vGroups Do
				If ValueIsFilled(vGroupsRow.GuestGroup) Then
					vGuestGroupCode = Format(vGroupsRow.GuestGroup.Code, "ND=12; NFD=0; NG=");
					If IsBlankString(mGuestGroup) Then
						mGuestGroup = vGuestGroupCode;
					Else
						mGuestGroup = mGuestGroup + ", " + vGuestGroupCode;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Currency
		mAccountingCurrency = "";
		If ValueIsFilled(SelInvoice.AccountingCurrency) Then
			vCurrencyObj = SelInvoice.AccountingCurrency.GetObject();
			mAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
		EndIf;
		// Parent document
		mParentDoc = ?(ValueIsFilled(SelInvoice.ParentDoc), TrimAll(SelInvoice.ParentDoc.Number), "");
		mFullInvoiceNumber = Trimall(SelInvoice.Number) + ?(IsBlankString(vCustomerCode), "", " " + vCustomerCode);
		// Set parameters and put report section
		vHeader2.Parameters.mFullInvoiceNumber = mFullInvoiceNumber;
		vHeader2.Parameters.mCustomer = mCustomer;
		vHeader2.Parameters.mInvoiceEMail = TrimAll(SelInvoice.EMail);
		vHeader2.Parameters.mContract = mContract;
		vHeader2.Parameters.mGuestGroup = mGuestGroup;
		vHeader2.Parameters.mAccountingCurrency = mAccountingCurrency;
		vHeader2.Parameters.mParentDoc = mParentDoc;
		// Put header		
		vSpreadsheet.Put(vHeader2);
		vSpreadsheet.Put(vTableHeader);
	EndIf;
	
	// Get template areas
	vClient = vTemplate.GetArea("Client");
	vRow = vTemplate.GetArea("Row");
	
	// Get all services
	vServices = SelInvoice.Services.Unload();
	
	vAgentCommission = 0;
	vDiscountPercent = 0;
	For Each vSrvRow In vServices Do
		If vAgentCommission = 0 Then
			vAgentCommission = vSrvRow.AgentCommission;
		EndIf;
		If vDiscountPercent = 0 Then
			vDiscountPercent = vSrvRow.Discount;
		EndIf;
	EndDo;
	
	// Change accounting dates for breakfast
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		If vServices.Find(True, "IsRoomRevenue") <> Undefined Then
			For Each vSrvRow In vServices Do
				If vSrvRow.IsInPrice And ValueIsFilled(vSrvRow.Service.QuantityCalculationRule) And
				   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Breakfast Then
					If BegOfDay(vSrvRow.AccountingDate) > BegOfDay(vSrvRow.DateTimeFrom) Then
						vSrvRow.AccountingDate = vSrvRow.AccountingDate - 24*3600;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Join services according to service parameters
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		// Try to replace accommodation service to the one that should be used for printing
		For Each vSrvRow In vServices Do
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
				EndIf;
			EndIf;
		EndDo;
		// Try to merge other services to the accommodation service
		i = 0;
		While i < vServices.Count() Do
			vSrvRow = vServices.Get(i);
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					// Try to find service to hide current one to
					vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Client, RoomType, Room, Resource", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate, vSrvRow.Client, vSrvRow.RoomType, vSrvRow.Room, vSrvRow.Resource));
					If vHideToServices.Count() = 0 Then
						vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Client, RoomType, Room, Resource", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate - 24*3600, vSrvRow.Client, vSrvRow.RoomType, vSrvRow.Room, vSrvRow.Resource));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vSrvRow.Sum;
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vSrvRow.VATSum;
						vSrv2Hide2.DiscountSum = vSrv2Hide2.DiscountSum + vSrvRow.DiscountSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
						// Delete current service
						vServices.Delete(i);
						Continue;
					EndIf;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
	
	// Get accommodation service name
	vAccommodationService = Undefined;	
	vAccommodationRemarks = "";
	vBaseAccommodationRemarks = "";
	vAccommodationServiceVATRate = Undefined;
	i = 0;
	While i < vServices.Count() Do
		vSrvRow = vServices.Get(i);
		If SelGroupBy = "InPricePerClientPerDay" Or SelGroupBy = "InPricePerDay" Or
		   SelGroupBy = "AllPerClientPerDay" Or SelGroupBy = "AllPerDay" Or
		   SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or
		   SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Then
			If vSrvRow.Sum = 0 Then
				vServices.Delete(i);
				Continue;
			EndIf;
		EndIf;
		If vAccommodationService = Undefined And vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly Then
			vAccommodationService = vSrvRow.Service;
			vAccommodationServiceVATRate = vSrvRow.VATRate;
			vAccommodationRemarks = TrimAll(vSrvRow.Remarks);
			vBaseAccommodationRemarks = TrimAll(vSrvRow.Remarks);
			If SelGroupBy = "InPrice" Or SelGroupBy = "All" Then
				If ValueIsFilled(vAccommodationService) Then
					vSrvDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, False);
					vSrvGrpDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, True);
					vAccommodationRemarks = StrReplace(vAccommodationRemarks, vSrvDescr, vSrvGrpDescr);
				EndIf;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	
	// Calculate totals
	vTotalSum = 0;
	vTotalSumNoCommission = 0;
	vTotalCommissionSum = 0;
	vTotalDiscountSum = 0;
	vTotalSumToBePaid = 0;
	vTotalVATSum = 0;

	vVATRateTransactions = New ValueTable();
	vVATRateTransactions.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
	vVATRateTransactions.Columns.Add("VATRateCode", cmGetNumberTypeDescription(4, 0));
	vVATRateTransactions.Columns.Add("Sum", cmGetSumTypeDescription());
	vVATRateTransactions.Columns.Add("VATSum", cmGetSumTypeDescription());
	
	For Each vSrvRow In vServices Do
		vTotalSum = vTotalSum + vSrvRow.Sum;
		If vShowDiscounts Then
			vTotalSum = vTotalSum + vSrvRow.DiscountSum;
		EndIf;
		vTotalSumToBePaid = vTotalSumToBePaid + vSrvRow.Sum;
		vTotalSumNoCommission = vTotalSumNoCommission + vSrvRow.Sum - vSrvRow.CommissionSum;
		vTotalCommissionSum = vTotalCommissionSum + vSrvRow.CommissionSum;
		vTotalDiscountSum = vTotalDiscountSum + vSrvRow.DiscountSum;

		vVATRate = vSrvRow.VATRate;
		vTotalVATSum = vTotalVatSum + cmCalculateVATSum(vVATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
		
		vVATRateTransactionsRow = vVATRateTransactions.Add();
		vVATRateTransactionsRow.VATRate = vVATRate;
		vVATRateTransactionsRow.VATRateCode = ?(ValueIsFilled(vVATRate), vVATRate.Code, 0);
		vVATRateTransactionsRow.VATSum = vSrvRow.VATSum;
		vVATRateTransactionsRow.Sum = vSrvRow.Sum;
	EndDo;
	If ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
		vTotalSumToBePaid = vTotalSumNoCommission;
	EndIf;
	vVATRateTransactions.GroupBy("VATRate, VATRateCode", "Sum, VATSum");
	vVATRateTransactions.Sort("VATRateCode");
	
	// Build footer
	vFooterAreas = new Array();
	vFooter1 = vTemplate.GetArea("Footer1");
	vCommission = vTemplate.GetArea("Commission");
	vDiscount = vTemplate.GetArea("Discount");
	vFooter2 = vTemplate.GetArea("Footer2");
	
	// Fill parameters
	mTotalSum = Format(vTotalSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
	mTotalVATSum = "";
	If Not (ValueIsFilled(vCompany) And vCompany.DoNotPrintVAT) Then
		If vTotalVATSum <> 0 Then
			mTotalVATSum = cmNStr("EN='Including VAT ';RU='В том числе НДС ';de='Darunter MwSt. '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
		Else
			If ValueIsFilled(SelInvoice.Company) And SelInvoice.Company.IsUsingSimpleTaxSystem Then
				mTotalVATSum = cmNStr("en='No VAT';ru='НДС не облагается в связи с применением упрощенной системы налогообложения (п. 2 ст. 346.11 НК РФ)';de='Im Zusammenhang mit der Anwendung des vereinfachten Besteuerungssystems wird die MwSt. nicht berechnet (Punkt 2 Artikel 346.11 des Steuergesetzes der Russischen Föderation)'", SelLanguage);
			Else
				If vVATRateTransactions.Count() > 0 Then
					vRowVatRate = vVATRateTransactions[0].VATRate;
					If ValueIsFilled(vRowVatRate) And Not vRowVatRate.NoVAT And vRowVatRate.TaxRate = 0 Then
						mTotalVATSum = cmNStr("EN='Including VAT ';RU='НДС ';de='Darunter MwSt. '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2; NZ=0.00") + " " + mAccountingCurrency;
					EndIf;	
				Else
					mTotalVATSum = cmNStr("en='No VAT';ru='НДС не облагается';de='MwSt. wird nicht berechnet'", SelLanguage); 
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If SelLanguage = Catalogs.Languages.DE Then
		mTotalVATSum = "";
	EndIf;

	// Set parameters
	vFooter1.Parameters.mTotalSum = mTotalSum;
	vFooter2.Parameters.mTotalVATSum = mTotalVATSum;
	vFooter2.Parameters.mTotalSumInWords = cmSumInWords(vTotalSumToBePaid, SelInvoice.AccountingCurrency, SelLanguage);
	
	// Put footer
	vFooterAreas.Add(vFooter1);
	If vShowDiscounts And vDiscountPercent <> 0 Then
		vDiscount.Parameters.mDiscount = vDiscountPercent;
		vDiscount.Parameters.mTotalDiscountSum = Format(vTotalDiscountSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
		vDiscount.Parameters.mSumToBePaid = Format(vTotalSumToBePaid, "ND=17; NFD=2") + " " + mAccountingCurrency;
		vFooterAreas.Add(vDiscount);
	Else
		If vTotalCommissionSum <> 0 And 
		   ValueIsFilled(SelInvoice.AccountingCustomer) And Not SelInvoice.AccountingCustomer.DoNotPostCommission Then
			mAgentCommission = "";   
			If ValueIsFilled(SelInvoice.GuestGroup) Then
				mAgentCommission = mAgentCommission + GetAgentCommissionDescription(vAgentCommission, SelInvoice.GuestGroup.ClientDoc, SelLanguage);
			Else
				mAgentCommission = mAgentCommission + vAgentCommission + "%";
			EndIf;
			vCommission.Parameters.mTotalCommissionSum = Format(vTotalCommissionSum, "ND=17; NFD=2") + " " + mAccountingCurrency;
			vCommission.Parameters.mAgentCommission = mAgentCommission;
			vCommission.Parameters.mSumToBePaid = Format(vTotalSumToBePaid, "ND=17; NFD=2") + " " + mAccountingCurrency;
			vFooterAreas.Add(vCommission);
		EndIf;
	EndIf;
	vFooterAreas.Add(vFooter2);
	
	// VAT rates table
	If ValueIsFilled(vCompany) And Not vCompany.IsUsingSimpleTaxSystem Then
		vVATHeaderArea = vTemplate.GetArea("VATHeader");
		vFooterAreas.Add(vVATHeaderArea);
		For Each vVATRateRow In vVATRateTransactions Do
			vVATRateRowArea = vTemplate.GetArea("VATRateRow");
			vVATRateRowArea.Parameters.mVATRate = TrimAll(vVATRateRow.VATRate);
			vVATRateRowArea.Parameters.mSumWithoutVAT = Format(vVATRateRow.Sum - vVATRateRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mVATSum = Format(vVATRateRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mSumWithVAT = Format(vVATRateRow.Sum, "ND=17; NFD=2; NZ=");
			vFooterAreas.Add(vVATRateRowArea);
		EndDo;
	EndIf;
	
	// Signatures
	vSignedByManager = False;
	If ValueIsFilled(SelInvoice.Company) And SelInvoice.Company.InvoiceIsSignedByManager Then
		vSignedByManager = True;
	EndIf;
	If Not vSignedByManager Then
		If SelInvoice.PrintWithCompanyStamp Then
			vSignatures = vTemplate.GetArea("SignaturesWithStamp");
		Else
			vSignatures = vTemplate.GetArea("Signatures");
		EndIf;
		mCompanyDirector = TrimAll(cmNStr(vCompany.Director, SelLanguage));
		If Not IsBlankString(vCompany.DirectorPosition) Then
			mCompanyDirectorPosition = TrimAll(cmNStr(vCompany.DirectorPosition, SelLanguage));
		Else
			mCompanyDirectorPosition = cmNStr("en='Director';ru='Руководитель';de='Leiter'", SelLanguage);
		EndIf;
		mCompanyAccountantGeneral = TrimAll(cmNStr(vCompany.AccountantGeneral, SelLanguage));
		If Not IsBlankString(vCompany.AccountantGeneralPosition) Then
			mCompanyAccountantGeneralPosition = TrimAll(cmNStr(vCompany.AccountantGeneralPosition, SelLanguage));
		Else
			mCompanyAccountantGeneralPosition = cmNStr("en='Accountant';ru='Бухгалтер';de='Buchhalter'", SelLanguage);
		EndIf;
		vSignatures.Parameters.mRemarks = TrimAll(SelInvoice.RemarksForPrinting);
		If ValueIsFilled(SelInvoice.CheckDate) And (ValueIsFilled(SelInvoice.GuestGroup) And 
		   ValueIsFilled(SelInvoice.GuestGroup.CheckInDate) And BegOfDay(SelInvoice.GuestGroup.CheckInDate) >= BegOfDay(SelInvoice.CheckDate) Or Not ValueIsFilled(SelInvoice.GuestGroup)) Then
			vSignatures.Parameters.mRemarks = vSignatures.Parameters.mRemarks + ?(IsBlankString(vSignatures.Parameters.mRemarks), "", Chars.LF) + 
			                                  ?(vDoNotShowPayDueDate, "", cmNStr("en='Payment before '; ru='Оплата до '; de='Zahlung vor '; lv='Apmaksāt līdz '", SelLanguage) + Format(SelInvoice.CheckDate, "DF=dd.MM.yyyy"));
		EndIf;
		vSignatures.Parameters.mCompanyDirector = mCompanyDirector;
		vSignatures.Parameters.mCompanyDirectorPosition = mCompanyDirectorPosition;
		vSignatures.Parameters.mCompanyAccountantGeneral = mCompanyAccountantGeneral;
		vSignatures.Parameters.mCompanyAccountantGeneralPosition = mCompanyAccountantGeneralPosition;
		// Company stamp
		If SelInvoice.PrintWithCompanyStamp Then
			If vStampIsSet Then
				vSignatures.Drawings.Stamp.Print = True;
				vSignatures.Drawings.Stamp.Picture = vStamp;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.Stamp);
			EndIf;
			If vDirectorSignatureIsSet Then
				vSignatures.Drawings.DirectorSignature.Print = True;
				vSignatures.Drawings.DirectorSignature.Picture = vDirectorSignature;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.DirectorSignature);
			EndIf;
			If vAccountantGeneralSignatureIsSet Then
				vSignatures.Drawings.AccountantGeneralSignature.Print = True;
				vSignatures.Drawings.AccountantGeneralSignature.Picture = vAccountantGeneralSignature;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.AccountantGeneralSignature);
			EndIf;
		EndIf;
		// Form text
		vSignatures.Parameters.mFormText = TrimR(SelObjectPrintForm.FormText);
		// Put signatures	
		vFooterAreas.Add(vSignatures);
	Else
		If SelInvoice.PrintWithCompanyStamp Then
			vSignatures = vTemplate.GetArea("ManagerSignatureWithStamp");
		Else
			vSignatures = vTemplate.GetArea("ManagerSignature");
		EndIf;
		mPosition = cmNStr("en='Manager';ru='Менеджер';de='Manager'", SelLanguage);
		mEmployee = "";
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			If Not IsBlankString(SessionParameters.CurrentUser.Position) Then
				mPosition = cmNStr(SessionParameters.CurrentUser.Position, SelLanguage);
			EndIf;
			If Not IsBlankString(SessionParameters.CurrentUser.DescriptionTranslations) Then
				mEmployee = cmNStr(SessionParameters.CurrentUser.DescriptionTranslations, SelLanguage);
			Else
				mEmployee = TrimAll(SessionParameters.CurrentUser.Description);
			EndIf;
		EndIf;
		vSignatures.Parameters.mRemarks = TrimAll(SelInvoice.RemarksForPrinting);
		If ValueIsFilled(SelInvoice.CheckDate) And (ValueIsFilled(SelInvoice.GuestGroup) And 
		   ValueIsFilled(SelInvoice.GuestGroup.CheckInDate) And BegOfDay(SelInvoice.GuestGroup.CheckInDate) >= BegOfDay(SelInvoice.CheckDate) Or Not ValueIsFilled(SelInvoice.GuestGroup)) Then
			vSignatures.Parameters.mRemarks = vSignatures.Parameters.mRemarks + ?(IsBlankString(vSignatures.Parameters.mRemarks), "", Chars.LF) + 
			                                  ?(vDoNotShowPayDueDate, "", cmNStr("en='Payment before '; ru='Оплата до '; de='Zahlung vor '; lv='Apmaksāt līdz '", SelLanguage) + Format(SelInvoice.CheckDate, "DF=dd.MM.yyyy"));
		EndIf;
		vSignatures.Parameters.mPosition = mPosition;
		vSignatures.Parameters.mEmployee = mEmployee;
		// Company stamp and manager's signature
		If SelInvoice.PrintWithCompanyStamp Then
			If vSignatureIsSet Then
				vSignatures.Drawings.Signature.Print = True;
				If TypeOf(vSignature) = Type("BinaryData") Then
					vSignatures.Drawings.Signature.Picture = New Picture(vSignature);	
				Else
					vSignatures.Drawings.Signature.Picture = vSignature;
				EndIf;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.Signature);
			EndIf;
			If vStampIsSet Then
				vSignatures.Drawings.ManagerStamp.Print = True;
				vSignatures.Drawings.ManagerStamp.Picture = vStamp;
			Else
				vSignatures.Drawings.Delete(vSignatures.Drawings.ManagerStamp);
			EndIf;
		EndIf;
		// Form text
		vSignatures.Parameters.mFormText = TrimR(SelObjectPrintForm.FormText);
		// Put signatures	
		vFooterAreas.Add(vSignatures);
	EndIf;
	
	// Check if products are specified in services
	vProductsAreSpecified = False;
	For Each vServicesRow In vServices Do
		If ValueIsFilled(vServicesRow.HotelProduct) And Not vServicesRow.HotelProduct.IsFolder Then
			vProductsAreSpecified = True;
			Break;
		EndIf;
	EndDo;	
	
	// Group by services by the accommodation conditions
	vConditions = vServices.Copy();
	vConditions.GroupBy("AccommodationType, RoomType, Resource, DateTimeFrom, DateTimeTo" + ?(vProductsAreSpecified, "", ", HotelProduct"), );
	For Each vConditionsRow In vConditions Do
		// Select services for the each condition
		vRowsArray = New Array();
		If vProductsAreSpecified Then
			vRowsArray = vServices.FindRows(New Structure("AccommodationType, RoomType, Resource, DateTimeFrom, DateTimeTo", 
			                                vConditionsRow.AccommodationType, vConditionsRow.RoomType, 
			                                vConditionsRow.Resource, 
			                                vConditionsRow.DateTimeFrom, vConditionsRow.DateTimeTo));
		Else
			vRowsArray = vServices.FindRows(New Structure("AccommodationType, RoomType, Resource, DateTimeFrom, DateTimeTo, HotelProduct", 
			                                vConditionsRow.AccommodationType, vConditionsRow.RoomType, 
			                                vConditionsRow.Resource, 
			                                vConditionsRow.DateTimeFrom, vConditionsRow.DateTimeTo,
			                                vConditionsRow.HotelProduct));
		EndIf;
		vCndServices = vServices.CopyColumns();
		For Each vRowElement In vRowsArray Do
			vCndServicesRow = vCndServices.Add();
			FillPropertyValues(vCndServicesRow, vRowElement);
		EndDo;
		
		vThereAreHotelProducts = False;
		vHotelProducts = vCndServices.Copy();
		vHotelProducts.GroupBy("HotelProduct", );
		vHotelProducts.Sort("HotelProduct");
		vHotelProductsList = "";
		vHotelProductsCount = 0;
		For Each vHotelProductsRow In vHotelProducts Do
			If ValueIsFilled(vHotelProductsRow.HotelProduct) Then
				If IsBlankString(vHotelProductsList) Then
					vHotelProductsList = TrimAll(vHotelProductsRow.HotelProduct.Description);
				Else
					vHotelProductsList = vHotelProductsList + ", " + TrimAll(vHotelProductsRow.HotelProduct.Description);
				EndIf;
				If Not vHotelProductsRow.HotelProduct.IsFolder Then
					vThereAreHotelProducts = True;
					vHotelProductsCount = vHotelProductsCount + 1;
				EndIf;
			EndIf;
		EndDo;
	
		For Each vSrvRow In vCndServices Do
			// Update accommodation service parameters
			If vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly And Not IsBlankString(vBaseAccommodationRemarks) And vBaseAccommodationRemarks <> TrimAll(vSrvRow.Remarks) Then
				vAccommodationService = vSrvRow.Service;
				vAccommodationServiceVATRate = vSrvRow.VATRate;
				vAccommodationRemarks = TrimAll(vSrvRow.Remarks);
				vBaseAccommodationRemarks = TrimAll(vSrvRow.Remarks);
				If SelGroupBy = "InPricePerClientPerDay" Or SelGroupBy = "InPricePerDay" Or
				   SelGroupBy = "AllPerClientPerDay" Or SelGroupBy = "AllPerDay" Or
				   SelGroupBy = "InPricePerClient" Or SelGroupBy = "InPrice" Or
				   SelGroupBy = "AllPerClient" Or SelGroupBy = "All" Then
					If ValueIsFilled(vAccommodationService) Then
						vSrvDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, False);
						vSrvGrpDescr = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, True);
						vAccommodationRemarks = StrReplace(vAccommodationRemarks, vSrvDescr, vSrvGrpDescr);
					EndIf;
				EndIf;
			EndIf;
			If vSrvRow.IsRoomRevenue And Not vThereAreHotelProducts And 
			   ValueIsFilled(vAccommodationService) And vAccommodationService = vSrvRow.Service Then
				vHotelProductsCount = vHotelProductsCount + ?(vSrvRow.RoomQuantity > 0, vSrvRow.RoomQuantity, 1);
			EndIf;
			If SelGroupBy = "InPrice" Or SelGroupBy = "All" Then
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If SelGroupBy = "InPrice" Then
						// Reset "is in price" flag if necessary
						If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.DoNotGroupIntoRoomRateOnPrint Then
							vSrvRow.IsInPrice = False;
						EndIf;
						If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
							vSrvRow.IsRoomRevenue = True;
						ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
							If vSrvRow.Service.RoomRevenueAmountsOnly Then
								vSrvRow.Quantity = 0;
							EndIf;
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Price = 0;
						EndIf;
					ElsIf SelGroupBy = "All" Then
						If Not vSrvRow.IsRoomRevenue Then
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
							vSrvRow.IsRoomRevenue = True;
						Else
							If vSrvRow.Service.RoomRevenueAmountsOnly Then
								vSrvRow.Quantity = 0;
							EndIf;
							vSrvRow.Service = vAccommodationService;
							vSrvRow.Remarks = vAccommodationRemarks;
							vSrvRow.Price = 0;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		vCndServices.GroupBy("Service, Remarks, VATRate, IsRoomRevenue, AgentCommissionType, AgentCommission", "Sum, VATSum, Price, Quantity, CommissionSum, VATCommissionSum, DiscountSum");
		vCndServices.Columns.Add("Duration", cmGetNumberTypeDescription(10, 0));
		// Recalculate price for all services
		For Each vSrvRow In vCndServices Do
			// Set quantity to the number of hotel products
			If vHotelProductsCount > 0 And vSrvRow.IsRoomRevenue Then
				vSrvRow.Duration = Round(vSrvRow.Quantity/vHotelProductsCount);
				vSrvRow.Quantity = vHotelProductsCount;
			Else
				vSrvRow.Duration = 0;
			EndIf;
			If vShowDiscounts Then
				vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum + vSrvRow.DiscountSum, vSrvRow.Quantity);
			Else
				vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
			EndIf;
		EndDo;
	
		// Print condition header
		vPeriodStr = Format(vConditionsRow.DateTimeFrom, "DF='dd.MM.yyyy'") + " - " + Format(vConditionsRow.DateTimeTo, "DF='dd.MM.yyyy'");
		If BegOfDay(vConditionsRow.DateTimeFrom) = BegOfday(vConditionsRow.DateTimeTo) Then
			vPeriodStr = Format(vConditionsRow.DateTimeFrom, "DF='dd.MM.yyyy'");
		EndIf;
		vRStr = "";
		vAStr = "";
		If ValueIsFilled(vConditionsRow.RoomType) Then
			vRStr = vConditionsRow.RoomType.GetObject().pmGetRoomTypeDescription(SelLanguage);
			If ValueIsFilled(vConditionsRow.AccommodationType) Then
				vAStr = vConditionsRow.AccommodationType.GetObject().pmGetAccommodationTypeDescription(SelLanguage);
			EndIf;
		ElsIf ValueIsFilled(vConditionsRow.Resource) Then
			vRStr = vConditionsRow.Resource.GetObject().pmGetResourceDescription(SelLanguage);
		EndIf;
		mCondition = ?(ValueIsFilled(vConditionsRow.DateTimeFrom), vPeriodStr, "") + 
				     ?(IsBlankString(vRStr), "" , ?(ValueIsFilled(vConditionsRow.DateTimeFrom), ", " + vRStr, vRStr)) + 
				     ?(IsBlankString(vAStr), "" , ", " + vAStr);
		If Left(mCondition, 1) = "," Then
			mCondition = Mid(mCondition, 3);
		EndIf;
					 
		// Set client area parameters
		vClient.Parameters.mClient = mCondition;
		// Put client area
		vSpreadsheet.Put(vClient);
		For Each vSrvRow In vCndServices Do
			// Fill row parameters
			mPrice = Format(vSrvRow.Price, "ND=17; NFD=2");
			If vSrvRow.IsRoomRevenue And vSrvRow.Sum > 0 And vSrvRow.Duration > 0 And vSrvRow.Quantity > 0 Then
				If vShowDiscounts Then
					mPrice = cmFormatSum(Round((vSrvRow.Sum + vSrvRow.DiscountSum)/(vSrvRow.Duration*vSrvRow.Quantity), 2), SelInvoice.AccountingCurrency, "", SelLanguage) + " * " + 
					         Format(vSrvRow.Duration, "ND=10; NFD=0; NG=") + cmNStr("en='d';ru='дн';de='Tage'", SelLanguage) + " * " + 
					         Format(vSrvRow.Quantity, "ND=10; NFD=0; NG=") + cmNStr("en='pcs';ru='шт';de='Stück'", SelLanguage) + " = " + 
					         cmFormatSum(vSrvRow.Sum + vSrvRow.DiscountSum, SelInvoice.AccountingCurrency, "", SelLanguage);
				Else
					mPrice = cmFormatSum(Round(vSrvRow.Sum/(vSrvRow.Duration*vSrvRow.Quantity), 2), SelInvoice.AccountingCurrency, "", SelLanguage) + " * " + 
					         Format(vSrvRow.Duration, "ND=10; NFD=0; NG=") + cmNStr("en='d';ru='дн';de='Tage'", SelLanguage) + " * " + 
					         Format(vSrvRow.Quantity, "ND=10; NFD=0; NG=") + cmNStr("en='pcs';ru='шт';de='Stück'", SelLanguage) + " = " + 
					         cmFormatSum(vSrvRow.Sum, SelInvoice.AccountingCurrency, "", SelLanguage);
				EndIf;
			EndIf;
			If vShowDiscounts Then
				mSum = vSrvRow.Sum + vSrvRow.DiscountSum;
			Else
				mSum = vSrvRow.Sum;
			EndIf;
			If vSrvRow.IsRoomRevenue And vSrvRow.Duration > 0 Then
				mQuantity = ?(vSrvRow.Quantity=0, "", Format(vSrvRow.Quantity, "ND=10; NFD=0; NG=") + cmNStr("en=' pcs.';ru=' шт.';de=' St.'"));
				mDescription = Chars.Tab + StrReplace(TrimAll(vSrvRow.Remarks), Chars.LF, Chars.LF + Chars.Tab) + 
				               ?(vSrvRow.Duration > 0, " (" + ?(IsBlankString(vHotelProductsList), "", vHotelProductsList + ", ") + 
				                 Format(vSrvRow.Duration, "ND=10; NFD=0; NG=") + cmNStr("en=' days)';ru=' дней)';de=' Tage)'", SelLanguage), "");
			Else
				If Round(vSrvRow.Quantity, 3) <> vSrvRow.Quantity Then
					mQuantity = ?(vSrvRow.Quantity = 0, "", Format(vSrvRow.Quantity, "ND=17; NFD=3"));
				Else
					mQuantity = ?(vSrvRow.Quantity = 0, "", String(vSrvRow.Quantity));
				EndIf;
				If ValueIsFilled(vSrvRow.Service) Then
					If vSrvRow.Quantity <> 0 Then
						vServiceObj = vSrvRow.Service.GetObject();
						mQuantity = vServiceObj.pmGetServiceQuantityPresentation(vSrvRow.Quantity, SelLanguage);
					EndIf;
				EndIf;
				mDescription = Chars.Tab + StrReplace(TrimAll(vSrvRow.Remarks), Chars.LF, Chars.LF + Chars.Tab);
			EndIf;
			If ExtraInvoice Then
				If Services.Count() = 1 Then
					If vSrvRow.Quantity = 1 Then
						mQuantity = Format(vSrvRow.Quantity, "ND=17; NFD=0");
					EndIf;
				EndIf;
			EndIf;
			
			vRow.Parameters.mPrice = mPrice;
			vRow.Parameters.mQuantity = mQuantity;
			vRow.Parameters.mDescription = mDescription;
			vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
			
			// Put row
			If Not IsBlankString(vRow.Parameters.mSum) Then
				// Check if we can print footer completely
				If (vConditions.IndexOf(vConditionsRow) + 1) = vConditions.Count() And 
				   (vCndServices.IndexOf(vSrvRow) + 1) = vCndServices.Count() Then
					vFooterAreas.Insert(0, vRow);
					If Not vSpreadsheet.CheckPut(vFooterAreas) Then
						vSpreadsheet.PutHorizontalPageBreak();
						vSpreadsheet.Put(vTableHeader);
					EndIf;
					vFooterAreas.Delete(0);
				Else
					If Not vSpreadsheet.CheckPut(vRow) Then
						vSpreadsheet.PutHorizontalPageBreak();
						vSpreadsheet.Put(vTableHeader);
					EndIf;
				EndIf;
				vSpreadsheet.Put(vRow);
			EndIf;
		EndDo;
	EndDo;
	
	// Put footer areas
	For Each vFooterArea In vFooterAreas Do
		vSpreadsheet.Put(vFooterArea);
	EndDo;
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // pmPrintInvoiceHotelProduct

// -----------------------------------------------------------------------------
Function pmSendInvoiceByEMail(vSpreadsheet, pEMails, pInvoiceNumber, SelLanguage, pMessageText = "", pSMSTemplates = Undefined, pParentDoc = Undefined, pClient = Undefined, pAmountStr = Undefined, pDiscountCard = Undefined) Export
	// Save current spreadsheet as HTML
	vFileName = StrReplace(Metadata().Presentation() + " " + StrReplace(TrimAll(Number), "/", "-"), " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	vSpreadsheet.Write(vFilePath, vFileType);
	// Employee signature
	vEmployeeSignature = TrimAll(cmNStr(SessionParameters.CurrentUser.Position, SelLanguage) + " " + SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(SelLanguage));
	// Sender name
	vSenderName = ?(ValueIsFilled(Hotel), Catalogs.Hotels.pmGetHotelPrintName(Hotel, SelLanguage), "");
	// Initialize message texts
	vMessageSubject = ?(ValueIsFilled(Hotel), Catalogs.Hotels.pmGetHotelPrintName(Hotel, SelLanguage), "") 
						+ cmNStr("en=' Invoice N" + TrimAll(pInvoiceNumber) + "'; 
					         	 |de=' Invoice N" + TrimAll(pInvoiceNumber) + "'; 
	                         	 |ru=' Счет №" + TrimAll(pInvoiceNumber) + "'", 
	                         SelLanguage);
	vMessageText = ?(IsBlankString(pMessageText), "", cmNStr(TrimAll(pMessageText), SelLanguage) + Chars.LF + Chars.LF) 
					 + cmNStr("en='Invoice number is " + TrimAll(pInvoiceNumber) + "'; 
				         	  |de='Invoice number is " + TrimAll(pInvoiceNumber) + "'; 
				              |ru='Номер счета " + TrimAll(pInvoiceNumber) + "'",
	                     SelLanguage) + Chars.LF +
	              ?(ValueIsFilled(GuestGroup), 
	              cmNStr("en='Confirmation number " + Format(GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
				         |de='Confirmation number " + Format(GuestGroup.Code, "ND=12; NFD=0; NG=") + "'; 
	                     |ru='Номер подтверждения " + Format(GuestGroup.Code, "ND=12; NFD=0; NG=") + "'",
	                     SelLanguage) + Chars.LF + Chars.LF, 
	              Chars.LF) + 
	              cmNStr("en='Best regards,'; 
				         |de='Best regards,'; 
	                     |ru='С уважением,'",
	                     SelLanguage) + Chars.LF 
						 + vEmployeeSignature + Chars.LF 
						 + ?(ValueIsFilled(Hotel), Catalogs.Hotels.pmGetHotelPrintName(Hotel, SelLanguage), "") + Chars.LF 
						 + cmNStr(SessionParameters.ConfigurationName, SelLanguage);
	// Call user exit procedure to give possibility to override message subject ans message text
	vUserExitProc = Catalogs.ExternalDataProcessors.SendInvoiceByEMail;
	If ValueIsFilled(vUserExitProc) Then
		If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			If Not IsBlankString(vUserExitProc.Algorithm) Then
				SetSafeMode(True);
				Execute(TrimAll(vUserExitProc.Algorithm));
				SetSafeMode(False);
			EndIf;
		EndIf;
	EndIf;
	// Send file in modal mode
		vFilesMap = New Map;
		vFilesMap.Insert(vFileName, vFilePath);
	vResult = JobsScheduled.cmSendFilesByEMail(vMessageSubject, vMessageText, pEMails, vFilesMap, SelLanguage, , GuestGroup, vSenderName, pSMSTemplates, pParentDoc, pClient, pAmountStr, pDiscountCard);
	// Delete temp file
	DeleteFiles(vFilePath);
	// Return result
	Return vResult;
EndFunction // pmSendInvoiceByEMail

// -----------------------------------------------------------------------------
Function pmSetPaymentMethodInServiceRemarks(Val pRemarks, pPaymentMethod, pLanguage = Undefined) Export
	vRemarks = TrimAll(pRemarks);
	vLanguage = pLanguage;
	If Not ValueIsFilled(vLanguage) Then
		If ValueIsFilled(AccountingCustomer) Then
			vLanguage = AccountingCustomer.Language;
		EndIf;
	EndIf;
	vDashPos = StrFind(vRemarks, " - ");
	If vDashPos > 0 Then
		vRemarks = Left(vRemarks, vDashPos - 1);
	EndIf;
	If ValueIsFilled(pPaymentMethod) Then
		If ValueIsFilled(vLanguage) Then
			vPMObj = pPaymentMethod.GetObject();
			vRemarks = vRemarks + " - " + vPMObj.pmGetPaymentMethodDescription(vLanguage);
		Else
			vRemarks = vRemarks + " - " + TrimAll(pPaymentMethod);
		EndIf;
	EndIf;
	Return vRemarks;
EndFunction // pmSetPaymentMethodInServiceRemarks

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure PostToInvoiceAccounts()
	For Each vServicesRow In Services Do
		Movement = RegisterRecords.InvoiceAccounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Receipt;
		Movement.Period = Date;
		Movement.Invoice = Ref;
		
		FillPropertyValues(Movement, Ref);
		FillPropertyValues(Movement, vServicesRow);
		If ValueIsFilled(GuestGroup) Then
			Movement.GuestGroup = GuestGroup;
		EndIf;
		
		If ValueIsFilled(AccountingCustomer) And AccountingCustomer.DoNotPostCommission Then
			Movement.Sum = vServicesRow.Sum;
			Movement.VATSum = vServicesRow.VATSum;
		Else
			Movement.Sum = vServicesRow.Sum - vServicesRow.CommissionSum;
			Movement.VATSum = vServicesRow.VATSum - vServicesRow.VATCommissionSum;
		EndIf;
	EndDo;

	RegisterRecords.InvoiceAccounts.Write();
EndProcedure // PostToInvoiceAccounts

// -----------------------------------------------------------------------------
Procedure pmFillByPayment(pDoc)
	vVATRate = Company.VATRate;
	vPrepaimentService = cmGetProformaInvoiceService(pDoc, vVATRate);
	If Not ValueIsFilled(vPrepaimentService) Then
		Raise NStr("en='Proforma-invoice could not be created because prepayment service was not setup!'; 
		           |ru='Невозможно создать счет на оплату, т.к. не указа услуга авансов!'; 
				   |de='Es ist nicht möglich, eine Rechnung für die Zahlung zu erstellen, da kein Vorauszahlung-Service!'");
	EndIf;
	If ValueIsFilled(pDoc.Folio) Then
		vFolio = pDoc.Folio;
		
		pmFillByFolio(vFolio);
		
		// Change proforma invoice time
		Date = pDoc.Date - 1;
		
		// Get customer language
		vLanguage = Undefined;
		If ValueIsFilled(AccountingCustomer) Then
			vLanguage = AccountingCustomer.Language;
		EndIf;
		
		// Clear services
		Services.Clear();
		
		// Add 1 row with prepayment amount
		vSrvRow = Services.Add();
		vSrvRow.Service = vPrepaimentService;
		vSrvRow.Remarks = vPrepaimentService.GetObject().pmGetServiceDescription(vLanguage);
		If ValueIsFilled(pDoc.DiscountCard) Then
			vCard = pDoc.DiscountCard;
			vCardRemarks = ?(ValueIsFilled(vCard.DiscountType), TrimAll(vCard.DiscountType) + " ", " ") + TrimAll(vCard.Identifier) + ?(TrimAll(vCard.Identifier) = TrimAll(vCard.Description), "", " (" + TrimAll(vCard.Description) + ")");
			Remarks = TrimAll(vCardRemarks);
			vSrvRow.Remarks = vSrvRow.Remarks + " - " + vCardRemarks;
		EndIf;
		vSrvRow.AccountingDate = pDoc.Date;
		vSrvRow.Price = Round(cmConvertCurrencies(pDoc.Sum, pDoc.PaymentCurrency, , AccountingCurrency, , Date, Hotel), 2);
		vSrvRow.Quantity = 1;
		vSrvRow.Unit = vPrepaimentService.Unit;
		vSrvRow.Sum = vSrvRow.Price;
		vSrvRow.VATRate = vVATRate;
		vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, Date);
		
		// Fill data about client
		If ValueIsFilled(pDoc.Payer) And TypeOf(pDoc.Payer) = Type("CatalogRef.Clients") Then
			vSrvRow.Client = pDoc.Payer;
			vSrvRow.DateTimeFrom = vFolio.DateTimeFrom;
			vSrvRow.DateTimeTo = vFolio.DateTimeTo;
			vSrvRow.Room = vFolio.Room;
		EndIf;
		
		// Add payment method to service remarks
		vSrvRow.Remarks = pmSetPaymentMethodInServiceRemarks(vSrvRow.Remarks, pDoc.PaymentMethod, vLanguage);
		
		// Fill totals
		Sum = Services.Total("Sum");
		VATSum = Services.Total("VATSum");
	EndIf;
EndProcedure // pmFillByPayment

// -----------------------------------------------------------------------------
Procedure pmFillByReturn(pDoc)
	vVATRate = Company.VATRate;
	vPrepaimentService = cmGetProformaInvoiceService(pDoc, vVATRate);
	If Not ValueIsFilled(vPrepaimentService) Then
		Raise NStr("en='Proforma-invoice could not be created because prepayment service was not setup!'; 
		           |ru='Невозможно создать счет на оплату, т.к. не указа услуга авансов!'; 
				   |de='Es ist nicht möglich, eine Rechnung für die Zahlung zu erstellen, da kein Vorauszahlung-Service!'");
	EndIf;
	If ValueIsFilled(pDoc.Folio) Then
		vFolio = pDoc.Folio;
		
		pmFillByFolio(vFolio);
		
		// Change proforma invoice time
		Date = pDoc.Date - 1;
		
		// Get customer language
		vLanguage = Undefined;
		If ValueIsFilled(AccountingCustomer) Then
			vLanguage = AccountingCustomer.Language;
		EndIf;
		
		// Clear services
		Services.Clear();
		
		// Add 1 row with prepayment amount
		vSrvRow = Services.Add();
		vSrvRow.Service = vPrepaimentService;
		vSrvRow.Remarks = vPrepaimentService.GetObject().pmGetServiceDescription(vLanguage);
		If ValueIsFilled(pDoc.DiscountCard) Then
			vCard = pDoc.DiscountCard;
			vCardRemarks = ?(ValueIsFilled(vCard.DiscountType), TrimAll(vCard.DiscountType) + " ", " ") + TrimAll(vCard.Identifier) + ?(TrimAll(vCard.Identifier) = TrimAll(vCard.Description), "", " (" + TrimAll(vCard.Description) + ")");
			Remarks = TrimAll(vCardRemarks);
			vSrvRow.Remarks = vSrvRow.Remarks + " - " + vCardRemarks;
		EndIf;
		vSrvRow.AccountingDate = pDoc.Date;
		vSrvRow.Price = Round(cmConvertCurrencies(pDoc.Sum, pDoc.PaymentCurrency, , AccountingCurrency, , Date, Hotel), 2);
		vSrvRow.Quantity = -1;
		vSrvRow.Unit = vPrepaimentService.Unit;
		vSrvRow.Sum = -vSrvRow.Price;
		vSrvRow.VATRate = vVATRate;
		vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, Date);
		
		// Fill data about client
		If ValueIsFilled(pDoc.Payer) And TypeOf(pDoc.Payer) = Type("CatalogRef.Clients") Then
			vSrvRow.Client = pDoc.Payer;
			vSrvRow.DateTimeFrom = vFolio.DateTimeFrom;
			vSrvRow.DateTimeTo = vFolio.DateTimeTo;
			vSrvRow.Room = vFolio.Room;
		EndIf;
		
		// Add payment method to service remarks
		vSrvRow.Remarks = pmSetPaymentMethodInServiceRemarks(vSrvRow.Remarks, pDoc.PaymentMethod, vLanguage);
		
		// Fill totals
		Sum = Services.Total("Sum");
		VATSum = Services.Total("VATSum");
	EndIf;
EndProcedure // pmFillByReturn

// -----------------------------------------------------------------------------
Procedure pmFillByDepositTransfer(pDoc)
	vVATRate = Company.VATRate;
	vPrepaimentService = cmGetProformaInvoiceService(pDoc, vVATRate);
	If Not ValueIsFilled(vPrepaimentService) Then
		Raise NStr("en='Proforma-invoice could not be created because prepayment service was not setup!'; 
		           |ru='Невозможно создать счет на оплату, т.к. не указа услуга авансов!'; 
				   |de='Es ist nicht möglich, eine Rechnung für die Zahlung zu erstellen, da kein Vorauszahlung-Service!'");
	EndIf;
	If ValueIsFilled(pDoc.FolioTo) Then
		vFolio = pDoc.FolioTo;
		
		pmFillByFolio(vFolio);
		
		// Change proforma invoice time
		Date = pDoc.Date - 1;
		
		// Get customer language
		vLanguage = Undefined;
		If ValueIsFilled(AccountingCustomer) Then
			vLanguage = AccountingCustomer.Language;
		EndIf;
		
		// Clear services
		Services.Clear();
		
		// Add 1 row with prepayment amount
		vSrvRow = Services.Add();
		vSrvRow.Service = vPrepaimentService;
		vSrvRow.Remarks = vPrepaimentService.GetObject().pmGetServiceDescription(vLanguage);
		vSrvRow.AccountingDate = pDoc.Date;
		vSrvRow.Price = Round(cmConvertCurrencies(pDoc.SumInFolioToCurrency, pDoc.FolioToCurrency, , AccountingCurrency, , Date, Hotel), 2);
		vSrvRow.Quantity = 1;
		vSrvRow.Unit = vPrepaimentService.Unit;
		vSrvRow.Sum = vSrvRow.Price;
		vSrvRow.VATRate = vVATRate;
		vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, Date);
		
		// Fill data about client
		If ValueIsFilled(vFolio.Client) Then
			vSrvRow.Client = vFolio.Client;
			vSrvRow.DateTimeFrom = vFolio.DateTimeFrom;
			vSrvRow.DateTimeTo = vFolio.DateTimeTo;
			vSrvRow.Room = vFolio.Room;
		EndIf;
		
		// Add payment method to service remarks
		vSrvRow.Remarks = pmSetPaymentMethodInServiceRemarks(vSrvRow.Remarks, pDoc.PaymentMethod, vLanguage);
		
		// Fill totals
		Sum = Services.Total("Sum");
		VATSum = Services.Total("VATSum");
	EndIf;
EndProcedure // pmFillByDepositTransfer

// -----------------------------------------------------------------------------
Procedure pmFillByCustomerPayment(pDoc)
	vVATRate = Company.VATRate;
	vPrepaimentService = cmGetProformaInvoiceService(pDoc, vVATRate);
	If Not ValueIsFilled(vPrepaimentService) Then
		Raise NStr("en='Proforma-invoice could not be created because prepayment service was not setup!'; 
		           |ru='Невозможно создать счет на оплату, т.к. не указа услуга авансов!'; 
				   |de='Es ist nicht möglich, eine Rechnung für die Zahlung zu erstellen, da kein Vorauszahlung-Service!'");
	EndIf;
	
	// Change proforma invoice time
	Date = pDoc.Date - 1;
	
	// Fill attributes
	ParentDoc = pDoc.ParentDoc;
	Hotel = pDoc.Hotel;
	Company = pDoc.Company;
	AccountingCustomer = pDoc.AccountingCustomer;
	AccountingContract = pDoc.AccountingContract;
	GuestGroup = pDoc.GuestGroup;
	ExchangeRateDate = pDoc.ExchangeRateDate;
	AccountingCurrency = pDoc.AccountingCurrency;
	AccountingCurrencyExchangeRate = pDoc.AccountingCurrencyExchangeRate;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Clear services
	Services.Clear();
	
	// Add 1 row with prepayment amount
	vSrvRow = Services.Add();
	vSrvRow.Service = vPrepaimentService;
	vSrvRow.Remarks = vPrepaimentService.GetObject().pmGetServiceDescription(vLanguage);
	vSrvRow.AccountingDate = pDoc.Date;
	vSrvRow.Price = pDoc.SumInAccountingCurrency;
	vSrvRow.Quantity = 1;
	vSrvRow.Unit = vPrepaimentService.Unit;
	vSrvRow.Sum = pDoc.SumInAccountingCurrency;
	vSrvRow.VATRate = vVATRate;
	vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, Date);
	
	// Fill data about client
	If ValueIsFilled(pDoc.GuestGroup) Then
		vSrvRow.DateTimeFrom = pDoc.GuestGroup.CheckInDate;
		vSrvRow.DateTimeTo = pDoc.GuestGroup.CheckOutDate;
	EndIf;
	
	// Add payment method to service remarks
	vSrvRow.Remarks = pmSetPaymentMethodInServiceRemarks(vSrvRow.Remarks, pDoc.PaymentMethod, vLanguage);
	
	// Fill totals
	Sum = Services.Total("Sum");
	VATSum = Services.Total("VATSum");
EndProcedure // pmFillByCustomerPayment

// -----------------------------------------------------------------------------
Procedure ConvertToPrepaimentModeIfNecessary(pDetailed = False, pPaymentMethod = Undefined)
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	If Not ValueIsFilled(vLanguage) And ValueIsFilled(Hotel) Then
		vLanguage = Hotel.Language;
	EndIf;
	// In details mode
	vInDetails = Hotel.ProformaInvoicesFillServicesInDetail;
	If ValueIsFilled(FillProformaInvoiceMode) And 
	  (FillProformaInvoiceMode = Enums.FillProformaInvoiceModes.InDetails Or FillProformaInvoiceMode = Enums.FillProformaInvoiceModes.InDetailsWithDates) Then
		vInDetails = True;
	EndIf;
	// Check invoice mode
	If ValueIsFilled(Hotel) And ValueIsFilled(Company) And ValueIsFilled(AccountingCustomer) And 
	   Hotel.PaymentsGenerateInvoices And Not pDetailed Then
		vVATRate = Company.VATRate;
		vPrepaimentService = Undefined;
		If ValueIsFilled(Hotel.ProformaInvoiceService) Then
			vPrepaimentService = Hotel.ProformaInvoiceService;
			vPrepaimentServiceObj = vPrepaimentService.GetObject();
			vSrvAttrs = vPrepaimentServiceObj.pmGetServicePrices(Hotel, Date, Catalogs.ClientTypes.EmptyRef());
			If vSrvAttrs.Count() > 0 Then
				wrkVATRate = vSrvAttrs.Get(0).VATRate;
				If ValueIsFilled(wrkVATRate) Then
					vVATRate = wrkVATRate;
				EndIf;
			EndIf;
			
			vSum = Services.Total("Sum");
			Services.Clear();
			
			vSrvRow = Services.Add();
			vSrvRow.Service = vPrepaimentService;
			vSrvRow.Remarks = vPrepaimentServiceObj.pmGetServiceDescription(vLanguage);
			vSrvRow.AccountingDate = Date;
			vSrvRow.Price = vSum;
			vSrvRow.Quantity = 1;
			vSrvRow.Unit = vPrepaimentService.Unit;
			vSrvRow.Sum = vSum;
			vSrvRow.VATRate = vVATRate;
			vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, Date);
			
			// Fill data about client
			If ValueIsFilled(GuestGroup) Then
				vSrvRow.GuestGroup = GuestGroup;
				vSrvRow.Client = GuestGroup.Client;
				vSrvRow.DateTimeFrom = GuestGroup.CheckInDate;
				vSrvRow.DateTimeTo = GuestGroup.CheckOutDate;
			EndIf;
			
			// Add payment method to service remarks
			If ValueIsFilled(pPaymentMethod) Then
				vSrvRow.Remarks = pmSetPaymentMethodInServiceRemarks(vSrvRow.Remarks, pPaymentMethod, vLanguage);
			EndIf;
		EndIf;
	Else
		vServices = Services.Unload();
		Services.Clear();
		// Group all in price services to the accommodation
		If FillProformaInvoiceMode = Enums.FillProformaInvoiceModes.OneLinePerRoom And 
		   ValueIsFilled(GuestGroup) And (Not ValueIsFilled(ParentDoc) Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation")) Then
			vAccommodationServiceVATRate = Undefined;
			For Each vServicesRow In vServices Do
				If vServicesRow.Sum = 0 Then
					Continue;
				EndIf;
				If ValueIsFilled(vServicesRow.Room) And vServicesRow.IsInPrice Then
					If vServicesRow.IsRoomRevenue And ValueIsFilled(vServicesRow.Service) And Not vServicesRow.Service.RoomRevenueAmountsOnly Then
						If vAccommodationServiceVATRate = Undefined Then
							vAccommodationServiceVATRate = vServicesRow.VATRate;
						EndIf;
					EndIf;
					If ValueIsFilled(vAccommodationServiceVATRate) And vServicesRow.VATRate = vAccommodationServiceVATRate Then
						vSrvRows = Services.FindRows(New Structure("Room, VATRate", vServicesRow.Room, vServicesRow.VATRate));
					Else
						vSrvRows = Services.FindRows(New Structure("Service, Room, VATRate", vServicesRow.Service, vServicesRow.Room, vServicesRow.VATRate));
					EndIf;
					If vSrvRows.Count() = 0 Then
						vSrvRow = Services.Add();
						FillPropertyValues(vSrvRow, vServicesRow, , "AccountingDate");
						If vServicesRow.IsRoomRevenue And ValueIsFilled(vServicesRow.Service) And Not vServicesRow.Service.RoomRevenueAmountsOnly Then
							If Not ExtraInvoice And ValueIsFilled(vSrvRow.ParentDoc) And 
							  (TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Reservation")) Then
								vSrvRow.Quantity = vSrvRow.ParentDoc.Duration;
							Else
								vSrvRow.Quantity = 1;
							EndIf;
							vSrvRow.Unit = "";
							vSrvRow.Remarks = GetRoomServicePresentation(vSrvRow, vLanguage);
						EndIf;
					Else
						vSrvRow = vSrvRows.Get(0);
						If vServicesRow.IsRoomRevenue And ValueIsFilled(vServicesRow.Service) And Not vServicesRow.Service.RoomRevenueAmountsOnly And Not ValueIsFilled(vSrvRow.Service) Then
							vSum = vSrvRow.Sum;
							vVATSum = vSrvRow.VATSum;
							vDiscountSum = vSrvRow.DiscountSum;
							vCommissionSum = vSrvRow.CommissionSum;
							vVATCommissionSum = vSrvRow.VATCommissionSum;

							FillPropertyValues(vSrvRow, vServicesRow);
							If Not ExtraInvoice And ValueIsFilled(vSrvRow.ParentDoc) And 
							  (TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vSrvRow.ParentDoc) = Type("DocumentRef.Reservation")) Then
								vSrvRow.Quantity = vSrvRow.ParentDoc.Duration;
							Else
								vSrvRow.Quantity = 1;
							EndIf;
							vSrvRow.Unit = "";
							vSrvRow.Remarks = GetRoomServicePresentation(vSrvRow, vLanguage);

							vSrvRow.Sum = vSrvRow.Sum + vSum;
							vSrvRow.VATSum = vSrvRow.VATSum + vVATSum;
							vSrvRow.DiscountSum = vSrvRow.DiscountSum + vDiscountSum;
							vSrvRow.CommissionSum = vSrvRow.CommissionSum + vCommissionSum;
							vSrvRow.VATCommissionSum = vSrvRow.VATCommissionSum + vVATCommissionSum;
						ElsIf ValueIsFilled(vAccommodationServiceVATRate) And vServicesRow.VATRate = vAccommodationServiceVATRate Then 
							vSrvRow.Sum = vSrvRow.Sum + vServicesRow.Sum;
							vSrvRow.VATSum = vSrvRow.VATSum + vServicesRow.VATSum;
							vSrvRow.DiscountSum = vSrvRow.DiscountSum + vServicesRow.DiscountSum;
							vSrvRow.CommissionSum = vSrvRow.CommissionSum + vServicesRow.CommissionSum;
							vSrvRow.VATCommissionSum = vSrvRow.VATCommissionSum + vServicesRow.VATCommissionSum;
						Else
							vSrvRow.Quantity = vSrvRow.Quantity + vServicesRow.Quantity;
							vSrvRow.Sum = vSrvRow.Sum + vServicesRow.Sum;
							vSrvRow.VATSum = vSrvRow.VATSum + vServicesRow.VATSum;
							vSrvRow.DiscountSum = vSrvRow.DiscountSum + vServicesRow.DiscountSum;
							vSrvRow.CommissionSum = vSrvRow.CommissionSum + vServicesRow.CommissionSum;
							vSrvRow.VATCommissionSum = vSrvRow.VATCommissionSum + vServicesRow.VATCommissionSum;
						EndIf;
					EndIf;
				Else
					vSrvRow = Services.Add();
					FillPropertyValues(vSrvRow, vServicesRow);
				EndIf;
			EndDo;
			For Each vSrvRow In Services Do
				// Recalculate price
				If vSrvRow.Quantity = 0 Then
					If vSrvRow.Sum < 0 Then
						vSrvRow.Quantity = -1;
					Else
						vSrvRow.Quantity = 1;
					EndIf;
				EndIf;
				vSrvRow.Price = Round(vSrvRow.Sum / vSrvRow.Quantity, 2);
			EndDo;
		Else
			// Fill periods with equal room price
			If ValueIsFilled(Hotel) And vInDetails Then
				vCurIdx = -1;
				vCurPrice = 0;
				vCurDayType = Undefined;
				vCurClient = Undefined;
				vCurDateFrom = '00010101';
				vCurDateTo = '00010101';
				vWrkAccountingDate = '00010101';
				vWrkRoom = Undefined;
				vWrkClient = Undefined;
				vFirstRoomRevenuePerDay = False;
				For Each vSrvRow In vServices Do
					If vSrvRow.IsRoomRevenue Then
						If (vSrvRow.IsInPrice And vCurPrice <> vSrvRow.Price) Or vCurDayType <> vSrvRow.CalendarDayType Or vCurClient <> vSrvRow.Client Or vSrvRow.AccountingDate < vCurDateFrom Then
							If vCurDayType <> Undefined And vCurIdx >= 0 Then
								j = vServices.IndexOf(vSrvRow) - 1;
								While j >= vCurIdx Do
									vSrvRowJ = vServices.Get(j);
									vSrvRowJ.DateTimeFrom = vCurDateFrom;
									vSrvRowJ.DateTimeTo = vCurDateTo + 24*3600;
									j = j - 1;
								EndDo;
							EndIf;
							
							vCurIdx = vServices.IndexOf(vSrvRow);
							vCurClient = vSrvRow.Client;
							vCurDayType = vSrvRow.CalendarDayType;
							vCurDateFrom = BegOfDay(vSrvRow.AccountingDate);
							vCurDateTo = BegOfDay(vSrvRow.AccountingDate);
							vCurPrice = vSrvRow.Price;
						Else
							vCurDateTo = Max(vCurDateTo, BegOfDay(vSrvRow.AccountingDate));
						EndIf;
						If vSrvRow.IsInPrice Then
							If vWrkAccountingDate <> vSrvRow.AccountingDate Or
							   vWrkRoom <> vSrvRow.Room Or 
							   vWrkClient <> vSrvRow.Client Then
								vWrkAccountingDate = vSrvRow.AccountingDate;
								vWrkClient = vSrvRow.Client;
								vWrkRoom = vSrvRow.Room;
								vFirstRoomRevenuePerDay = False;
							EndIf;
							If Not vFirstRoomRevenuePerDay Then
								vFirstRoomRevenuePerDay = True;
							Else
								vSrvRow.Quantity = 0;
								vFirstRoomRevenuePerDay = False;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				If ValueIsFilled(vCurDateFrom) And ValueIsFilled(vCurDateTo) Then
					If vCurDayType <> Undefined And vCurIdx >= 0 Then
						j = vServices.Count() - 1;
						While j >= vCurIdx Do
							vSrvRowJ = vServices.Get(j);
							vSrvRowJ.DateTimeFrom = vCurDateFrom;
							vSrvRowJ.DateTimeTo = vCurDateTo + 24*3600;
							j = j - 1;
						EndDo;
					EndIf;
				EndIf;
				If FillProformaInvoiceMode = Enums.FillProformaInvoiceModes.InDetailsWithDates Then
					vServices.GroupBy("AccountingDate, Service, Remarks, VATRate, ParentDoc, AccommodationTemplate, AccommodationType, NumberOfPersons, RoomQuantity, Client, RoomType, Room, HotelProduct, IsInPrice, IsRoomRevenue, Resource, IsResourceRevenue, DateTimeFrom, DateTimeTo, CalendarDayType, Agent, Discount, AgentCommissionType, AgentCommission, Price", "Quantity, Sum, VATSum, DiscountSum, CommissionSum, VATCommissionSum");
				Else
					vServices.GroupBy("Service, Remarks, VATRate, ParentDoc, AccommodationTemplate, AccommodationType, NumberOfPersons, RoomQuantity, Client, RoomType, Room, HotelProduct, IsInPrice, IsRoomRevenue, Resource, IsResourceRevenue, DateTimeFrom, DateTimeTo, CalendarDayType, Agent, Discount, AgentCommissionType, AgentCommission, Price", "Quantity, Sum, VATSum, DiscountSum, CommissionSum, VATCommissionSum");
				EndIf;
			Else
				// Merge services to room revenue according to hotel and service settings
				vWrkAccountingDate = '00010101';
				vWrkRoom = Undefined;
				vWrkClient = Undefined;
				vFirstRoomRevenuePerDay = False;
				For Each vSrvRow In vServices Do
					If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						If vWrkAccountingDate <> vSrvRow.AccountingDate Or 
						   vWrkRoom <> vSrvRow.Room Or 
						   vWrkClient <> vSrvRow.Client Then
							vWrkAccountingDate = vSrvRow.AccountingDate;
							vWrkRoom = vSrvRow.Room;
							vWrkClient = vSrvRow.Client;
							vFirstRoomRevenuePerDay = False;
						EndIf;
						If Not vFirstRoomRevenuePerDay Then
							vFirstRoomRevenuePerDay = True;
						Else
							vSrvRow.Quantity = 0;
							vFirstRoomRevenuePerDay = False;
						EndIf;
					EndIf;
					vService = vSrvRow.Service;
					If ValueIsFilled(vService) Then
						vSrvRow.CalendarDayType = Undefined;
						If vSrvRow.IsInPrice Then
							If ValueIsFilled(vService.HideIntoServiceOnPrint) Then
								vSrvRow.Service = vService.HideIntoServiceOnPrint;
								vSrvRow.IsRoomRevenue = True;
								If Not vService.DoNotGroupIntoRoomRateOnPrint Then
									vSrvRow.Quantity = 0;
								EndIf;
							EndIf;
						EndIf;
						// Fill remarks by service description by default
						vServiceObj = vSrvRow.Service.GetObject();
						vServiceDescription = vServiceObj.pmGetServiceDescription(vLanguage);
						vSrvRow.Remarks = vServiceDescription;
					EndIf;
				EndDo;
				vServices.GroupBy("Service, Remarks, VATRate, ParentDoc, AccommodationTemplate, AccommodationType, NumberOfPersons, RoomQuantity, Client, RoomType, Room, HotelProduct, IsInPrice, IsRoomRevenue, Resource, IsResourceRevenue, DateTimeFrom, DateTimeTo, Agent, Discount, AgentCommissionType, AgentCommission", "Quantity, Sum, VATSum, DiscountSum, CommissionSum, VATCommissionSum");
				// Check if there are services with zero price and quantity
				vCurRoom = Undefined;
				vCurClient = Undefined;
				vCurAccommodationType = Undefined;
				vCurAccommodationTemplate = Undefined;
				For Each vSrvRow In vServices Do
					If vCurRoom <> vSrvRow.Room Then
						vCurRoom = vSrvRow.Room;
						vCurClient = vSrvRow.Client;
						vCurAccommodationType = vSrvRow.AccommodationType;
						vCurAccommodationTemplate = vSrvRow.AccommodationTemplate;
					Else
						If vSrvRow.Quantity = 0 Then
							vSrvRow.Client = vCurClient;
							vSrvRow.AccommodationType = vCurAccommodationType;
							vSrvRow.AccommodationTemplate = vCurAccommodationTemplate;
						EndIf;
					EndIf;
				EndDo;
				vServices.GroupBy("Service, Remarks, VATRate, ParentDoc, AccommodationTemplate, AccommodationType, NumberOfPersons, RoomQuantity, Client, RoomType, Room, HotelProduct, IsInPrice, IsRoomRevenue, Resource, IsResourceRevenue, DateTimeFrom, DateTimeTo, Agent, Discount, AgentCommissionType, AgentCommission", "Quantity, Sum, VATSum, DiscountSum, CommissionSum, VATCommissionSum");
				For Each vSrvRow In vServices Do
					If ValueIsFilled(vSrvRow.AccommodationTemplate) Then
						vAccTemplate = vSrvRow.AccommodationTemplate;
						vSrvRow.NumberOfPersons = vSrvRow.RoomQuantity * (vAccTemplate.NumberOfAdults + vAccTemplate.NumberOfTeenagers + vAccTemplate.NumberOfChildren + vAccTemplate.NumberOfInfants);
					Else
						vSrvRow.NumberOfPersons = 0;
					EndIf;
				EndDo;
				// Add all neccessary columns
				vServices.Columns.Add("Price", cmGetSumTypeDescription());
				vServices.Columns.Add("CalendarDayType", cmGetCatalogTypeDescription("CalendarDayTypes"));
			EndIf;
			If FillProformaInvoiceMode <> Enums.FillProformaInvoiceModes.InDetailsWithDates Then
				vServices.Columns.Add("AccountingDate", cmGetDateTypeDescription());
			EndIf;
			vServices.Columns.Add("Unit", cmGetStringTypeDescription(10));
			For Each vSrvRow In vServices Do
				// Recalculate price
				If vSrvRow.Quantity <> 0 Then
					vSrvRow.Price = Round(vSrvRow.Sum / vSrvRow.Quantity, 2);
				EndIf;
				// Add period to the room revenue service remarks
				If vSrvRow.IsRoomRevenue And vInDetails Then
					If ValueIsFilled(vSrvRow.DateTimeFrom) And ValueIsFilled(vSrvRow.DateTimeTo) And vSrvRow.DateTimeTo >= vSrvRow.DateTimeFrom Then
						vSrvRow.Remarks = vSrvRow.Remarks + " (" + Format(vSrvRow.DateTimeFrom, "DF=dd.MM.yyyy") + " - " + Format(vSrvRow.DateTimeTo, "DF=dd.MM.yyyy") + ")";
					EndIf;
				EndIf;
			EndDo;
			Services.Load(vServices);
		EndIf;
	EndIf;
	// Fill unit if possible
	For Each vSrvRow In Services Do
		If IsBlankString(vSrvRow.Unit) And ValueIsFilled(vSrvRow.Service) Then
			vService = vSrvRow.Service;
			If Not IsBlankString(vService.UnitTranslations) Then
				vSrvRow.Unit = cmNStr(vService.UnitTranslations, vLanguage);
				If vSrvRow.Unit = vService.UnitTranslations And StrFind(vSrvRow.Unit, "'") > 0 Then
					vSrvRow.Unit = "";
				EndIf;
			EndIf;
			If IsBlankString(vSrvRow.Unit) Then
				vSrvRow.Unit = TrimAll(vService.Unit);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ConvertToPrepaimentModeIfNecessary

// -----------------------------------------------------------------------------
Procedure TraverseTreeRecursivelyTreeRows(ValueTree, Client, Hotel)
	For Each TreeRow In ValueTree.Rows Do 
		If TypeOf(TreeRow.Ref) <> Type("DocumentRef.Payment") Then
			If TreeRow.IsChecked Or RootChecked Then
				If TreeRow.Rows.Count() > 0 Then
					RootChecked = True;
					TraverseTreeRecursivelyTreeRows(TreeRow, Client, Hotel);
				Else
					vSrvRow = Services.Add();
					vSrvRow.AccountingDate = TreeRow.Date;
					vSrvRow.Price = TreeRow.Sum;
					vSrvRow.Sum = TreeRow.Sum; 
					vSrvRow.Remarks = TreeRow.Service;
					If TreeRow.Ref <> Undefined Then
						vSrvRow.Service = TreeRow.Ref.Service;
						vSrvRow.VATRate =  TreeRow.Ref.VATRate;
						vSrvRow.VATSum = TreeRow.Ref.VATSum;
						vSrvRow.Quantity = TreeRow.Ref.Quantity;
					Else 
						vSrvRow.VATRate = Company.VATRate;
					EndIf;
					vSrvRow.Client = Client;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	RootChecked = False;
EndProcedure // TraverseTreeRecursivelyTreeRows

// -----------------------------------------------------------------------------
Function ServicesHasChanged()
	vOldServices = Ref.Services;
	If Services.Count() <> vOldServices.Count() Then
		Return True;
	ElsIf Services.Total("Sum") <> vOldServices.Total("Sum") Or 
		  Services.Total("VATSum") <> vOldServices.Total("VATSum") Or 
		  Services.Total("CommissionSum") <> vOldServices.Total("CommissionSum") Or 
		  Services.Total("DiscountSum") <> vOldServices.Total("DiscountSum") Or 
		  Services.Total("Quantity") <> vOldServices.Total("Quantity") Then
		Return True;
	Else
		vNewServices = Services.Unload();
		vOldServices = vOldServices.Unload();
		vNewServices.GroupBy("Service", "Sum, VATSum, CommissionSum, DiscountSum, Quantity");
		vOldServices.GroupBy("Service", "Sum, VATSum, CommissionSum, DiscountSum, Quantity");
		For Each vNewServicesRow In vNewServices Do
			vOldServicesRow = vOldServices.Find(vNewServicesRow.Service, "Service");
			If vOldServicesRow = Undefined Then
				Return True;
			ElsIf vOldServicesRow.Sum <> vNewServicesRow.Sum Or 
				  vOldServicesRow.VATSum <> vNewServicesRow.VATSum Or 
				  vOldServicesRow.CommissionSum <> vNewServicesRow.CommissionSum Or 
				  vOldServicesRow.DiscountSum <> vNewServicesRow.DiscountSum Or 
				  vOldServicesRow.Quantity <> vNewServicesRow.Quantity Then
				Return True;
			EndIf;
		EndDo;
		For Each vOldServicesRow In vOldServices Do
			vNewServicesRow = vNewServices.Find(vOldServicesRow.Service, "Service");
			If vNewServicesRow = Undefined Then
				Return True;
			ElsIf vOldServicesRow.Sum <> vNewServicesRow.Sum Or 
				  vOldServicesRow.VATSum <> vNewServicesRow.VATSum Or 
				  vOldServicesRow.CommissionSum <> vNewServicesRow.CommissionSum Or 
				  vOldServicesRow.DiscountSum <> vNewServicesRow.DiscountSum Or 
				  vOldServicesRow.Quantity <> vNewServicesRow.Quantity Then
				Return True;
			EndIf;
		EndDo;
	EndIf;
	Return False;
EndFunction // ServicesHasChanged

// -----------------------------------------------------------------------------
Function GetAgentCommissionDescription(pAgentCommission, pDoc, pLanguage)
	vStr = "%";
	If ValueIsFilled(pDoc) And (TypeOf(pDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDoc) = Type("DocumentRef.Reservation")) Then
		If pDoc.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
			vStr = TrimAll(pAgentCommission) + cmNStr("en='%';ru='%';de='%'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
			vStr = TrimAll(pAgentCommission) + cmNStr("en='% for the 1-st day';ru='% за 1-ый день';de='% für den ersten Tag'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per guest per check-in';ru=' за гостя за заезд';de=' pro Gast pro Check-in'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per room per check-in';ru=' за номер за заезд';de=' pro Zimmer pro Check-in'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per guest per night';ru=' за гостя за ночь';de=' pro Gast pro Nacht'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per room per night';ru=' за номер за ночь';de=' pro Zimmer pro Nacht'", pLanguage);
		EndIf;
	EndIf;
	Return vStr;
EndFunction // GetAgentCommissionDescription

// -----------------------------------------------------------------------------
Function GetRoomServicePresentation(pSrvRow, pLanguage)
	vRemarks = ?(ExtraInvoice, NStr("en='Additional payment for the reservation'; ru='Доплата по брони'; de='Zuschlag auf Reservierung'"), "");
	If ValueIsFilled(pSrvRow.DateTimeFrom) And ValueIsFilled(pSrvRow.DateTimeTo) Then
		vRemarks = vRemarks + ?(IsBlankString(vRemarks), "", ", ") + 
		           Format(pSrvRow.DateTimeFrom, "DF='dd.MM.yyyy ddd'") + " - " + Format(pSrvRow.DateTimeTo, "DF='dd.MM.yyyy ddd'") + 
				   ?(ValueIsFilled(pSrvRow.ParentDoc), 
				     ", " + TrimAll(pSrvRow.ParentDoc.Duration) + 
				            ?(ValueIsFilled(pSrvRow.ParentDoc.RoomRate), 
							  ?(pSrvRow.ParentDoc.RoomRate.PeriodInHours = 1, NStr("en=' hours'; ru=' часов'; de=' Stunden'"), NStr("en=' nights'; ru=' сут.'; de=' Nachts'")), 
							  ""),  
		             "");
	EndIf;
	If ValueIsFilled(pSrvRow.RoomType) Then
		vRemarks = vRemarks + ?(IsBlankString(vRemarks), "", ", ") + pSrvRow.RoomType.GetObject().pmGetRoomTypeDescription(pLanguage);
	EndIf;
	If ValueIsFilled(pSrvRow.ParentDoc) Then
		vRemarks = vRemarks + ?(IsBlankString(vRemarks), "", ", ") + GetGuestNamesByDocument(pSrvRow.ParentDoc);
	EndIf; 
	Return vRemarks;
EndFunction // GetRoomServicePresentation   

// -----------------------------------------------------------------------------
Function GetRoomServicePresentationForInvoiceSimple(pSrvRow, pLanguage)
	vRemarks = ?(ExtraInvoice, NStr("en='Additional payment for the reservation'; ru='Доплата по брони'; de='Zuschlag auf Reservierung'"), "");
	If ValueIsFilled(pSrvRow.Client) Then
		vRemarks = vRemarks + ?(vRemarks = "", "",  ", ") + pSrvRow.Client.FullName; 
	EndIf;
	If pSrvRow.DateTimeFrom <> Date(1,1,1) And pSrvRow.DateTimeTo <> Date(1,1,1)  Then
		vRemarks = vRemarks + ?(vRemarks = "", "",  ", ")  + Format(BegOfDay(pSrvRow.DateTimeFrom), "DF=dd.MM.yyyy") + " - " + Format(BegOfDay(pSrvRow.DateTimeTo), "DF=dd.MM.yyyy");
	EndIf;
	If ValueIsFilled(pSrvRow.RoomType) Then
		vRemarks = vRemarks + ?(vRemarks = "", "",  ", ")  + Catalogs.RoomTypes.pmGetRoomTypeDescription(pSrvRow.RoomType, pLanguage);
	EndIf;
	Return vRemarks; 
EndFunction // GetRoomServicePresentationForInvoiceSimple

// -----------------------------------------------------------------------------
Function GetGuestNamesByDocument(pParentDoc)
	vNames = "";
	If ValueIsFilled(pParentDoc) Then
		If TypeOf(pParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pParentDoc) = Type("DocumentRef.Reservation") Then
			vDocNumber = TrimAll(pParentDoc.Number);
			vDocGroup = pParentDoc.GuestGroup;
			// Get one room documents
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Reservations.Guest AS Guest
			|INTO Reservations
			|FROM
			|	Document.Reservation AS Reservations
			|WHERE
			|	Reservations.GuestGroup = &qGuestGroup
			|	AND Reservations.Number = &qNumber
			|	AND Reservations.Posted
			|	AND (Reservations.ReservationStatus.IsActive
			|			OR Reservations.ReservationStatus.IsPreliminary)
			|	AND Reservations.Guest <> VALUE(Catalog.Clients.EmptyRef)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Accommodations.Guest AS Guest
			|INTO Accommodations
			|FROM
			|	Document.Accommodation AS Accommodations
			|WHERE
			|	Accommodations.GuestGroup = &qGuestGroup
			|	AND Accommodations.Number = &qNumber
			|	AND Accommodations.Posted
			|	AND Accommodations.AccommodationStatus.IsActive
			|	AND Accommodations.Guest <> VALUE(Catalog.Clients.EmptyRef)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	Guests.Guest AS Guest
			|FROM
			|	(SELECT
			|		Reservations.Guest AS Guest
			|	FROM
			|		Reservations AS Reservations
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		Accommodations.Guest
			|	FROM
			|		Accommodations AS Accommodations) AS Guests
			|
			|ORDER BY
			|	Guests.Guest.FullName";
			vQry.SetParameter("qNumber", vDocNumber);
			vQry.SetParameter("qGuestGroup", vDocGroup);
			vGuests = vQry.Execute().Unload();
			For Each vGuestsRow In vGuests Do
				If ValueIsFilled(vGuestsRow.Guest) Then
					vNames = vNames + ?(IsBlankString(vNames), "", ", ") + TrimAll(vGuestsRow.Guest.FullName);
				EndIf;
			EndDo;
		ElsIf TypeOf(pParentDoc) = Type("DocumentRef.ResourceReservation") Then
			If ValueIsFilled(pParentDoc.Client) Then
				vNames = vNames + ?(IsBlankString(vNames), "", ", ") + TrimAll(pParentDoc.Client.FullName);
			EndIf;
		EndIf;
	EndIf;
	Return vNames;
EndFunction // GetGuestNamesByDocument

// -----------------------------------------------------------------------------
Procedure FillBankAccount()
	If ValueIsFilled(Company.BankAccount) 
		And (Company.BankAccount.Hotel = Hotel Or Company.BankAccount.Hotel = Catalogs.Hotels.EmptyRef()) 
		And AccountingCurrency = Company.BankAccount.AccountCurrency Then 
		
		BankAccount = Company.BankAccount;
	Else 
		vBankAccounts = Catalogs.Companies.pmGetCompanyBankAccounts(Company, AccountingCurrency, Hotel);
		If vBankAccounts.Count() > 0 Then
			vBankAccountsRow = vBankAccounts.Get(0);
			BankAccount = vBankAccountsRow.BankAccount;
		EndIf;
	EndIf;
EndProcedure // FillBankAccount()

#EndRegion
