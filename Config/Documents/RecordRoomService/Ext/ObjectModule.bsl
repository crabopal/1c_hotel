
#Region Public

// -----------------------------------------------------------------------------
Function pmGetRoomServiceCharges() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charge.Ref AS Charge
	|FROM
	|	Document.Charge AS Charge
	|WHERE
	|	Charge.ParentRoomService = &qParentRoomService
	|	AND Charge.Posted = TRUE";
	vQry.SetParameter("qParentRoomService", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetRoomServiceCharges

// -----------------------------------------------------------------------------
Function pmGetFoliosToChargeTo() Export
	vFolios = cmGetFoliosToChargeRoomService(Room, ServiceDate, Client);
	Return vFolios;
EndFunction // pmGetFoliosToChargeTo

// -----------------------------------------------------------------------------
Function pmGetFolioToChargeTo() Export
	vFolioTo = Documents.Folio.EmptyRef();
	// Create table with accommodation folios
	vAccFolios = New ValueTable();
	vAccFolios.Columns.Add("Accommodation", cmGetDocumentTypeDescription("Accommodation"));
	vAccFolios.Columns.Add("IsInHouse", cmGetNumberTypeDescription(1, 0));
	vAccFolios.Columns.Add("AccommodationDate", cmGetDateTimeTypeDescription());
	vAccFolios.Columns.Add("IsPayingForTheRoom", cmGetNumberTypeDescription(1, 0));
	vAccFolios.Columns.Add("Folio", cmGetDocumentTypeDescription("Folio"));
	vAccFolios.Columns.Add("FolioDate", cmGetDateTimeTypeDescription());
	vAccFolios.Columns.Add("FolioPriority", cmGetNumberTypeDescription(9, 0));
	vAccFolios.Columns.Add("ThereIsDeposit", cmGetNumberTypeDescription(1, 0));
	// Get service we will check
	vService = RoomService;
	If Not ValueIsFilled(vService) Then
		vService = FixedService;
	EndIf;
	// Get list of all active suitable folios
	vFolios = pmGetFoliosToChargeTo();
	If ValueIsFilled(vService) Then
		// Check client and charging rules for the service
		For Each vFolioRow In vFolios Do
			vFolio = vFolioRow.Folio;
			vParentDoc = vFolio.ParentDoc;
			If ValueIsFilled(vParentDoc) Then
				If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
					vCRs = vParentDoc.ChargingRules.Unload();
					If Not vParentDoc.IgnoreGroupChargingRules Then
						cmAddGuestGroupChargingRules(vCRs, vParentDoc.GuestGroup);
					EndIf;
					vCRRow = vCRs.Find(vFolio, "ChargingFolio");
					If vCRRow <> Undefined Then
						If cmIsServiceFitToTheChargingRule(vCRRow, vService, BegOfDay(Date), False, False) Then
							vAccFoliosRowsArray = vAccFolios.FindRows(New Structure("Accommodation, Folio", vParentDoc, vFolio));
							If vAccFoliosRowsArray.Count() = 0 Then
								vAccFoliosRow = vAccFolios.Add();
								vAccFoliosRow.Accommodation = vParentDoc;
								vAccFoliosRow.AccommodationDate = vFolio.DateTimeFrom;
								If ValueIsFilled(vParentDoc.AccommodationStatus) Then
									vAccFoliosRow.IsInHouse = ?(vParentDoc.AccommodationStatus.IsInHouse, 1, 0);
								EndIf;
								vAccFoliosRow.IsPayingForTheRoom = 0;
								If ValueIsFilled(vAccFoliosRow.Accommodation.AccommodationType) Then
									If vAccFoliosRow.Accommodation.AccommodationType.Type = Enums.AccomodationTypes.Room Then
										vAccFoliosRow.IsPayingForTheRoom = 1;
									EndIf;
								EndIf;
								vAccFoliosRow.Folio = vFolio;
								vAccFoliosRow.FolioDate = vFolio.Date;
								vAccFoliosRow.FolioPriority = vCRRow.LineNumber;
								vAccFoliosRow.ThereIsDeposit = 0;
								vFolioBalance = vFolio.GetObject().pmGetBalance('39991231235959');
								If vFolioBalance < 0 Then
									vAccFoliosRow.ThereIsDeposit = 1;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// We will use folio of the client paing for the room and with deposit first. If not then we will use the oldest accommodations folio with lowest folio priority
	If vAccFolios.Count() > 0 Then
		vAccFolios.Sort("IsInHouse Desc, IsPayingForTheRoom Desc, ThereIsDeposit Desc, AccommodationDate Desc, Accommodation, FolioPriority, FolioDate, Folio");
		vFolioTo = vAccFolios.Get(0).Folio;
	EndIf;
	// If there was no suitable folio found then take the earliest one without customer
	If Not ValueIsFilled(vFolioTo) Then
		// Return first active client folio
		For Each vFoliosRow In vFolios Do
			vWrkFolio = vFoliosRow.Folio;
			If Not ValueIsFilled(vWrkFolio.Customer) Or 
			   ValueIsFilled(vWrkFolio.Hotel) And ValueIsFilled(vWrkFolio.Customer) And vWrkFolio.Customer.IsIndividual Then
				vFolioTo = vWrkFolio;
				Break;
			EndIf;
		EndDo;
	EndIf;
	// Return
	Return vFolioTo;
EndFunction // pmGetFolioToChargeTo

// -----------------------------------------------------------------------------
// Recalculate all sums based on room service charge Sum in document currency
// -----------------------------------------------------------------------------
Procedure pmRecalculateSums() Export
	// Room service charge sum
	If RoomServicePriceIsWithVAT Then
		Sum = Round(Price * Quantity, 2);
	Else
		// Get price with VAT
		vPrice = Price;
		If ValueIsFilled(VATRate) Then
			vPrice = Round(Price * (100 + cmGetVATTaxRate(VATRate, Date))/100, 2);
		EndIf;
		Sum = Round(vPrice * Quantity, 2);
	EndIf;
	// All other bound sums
	SumInFolioCurrency = 0;
	VATSumInFolioCurrency = 0;
	DiscountSumInFolioCurrency = 0;
	VATDiscountSumInFolioCurrency = 0;
	CommissionSumInFolioCurrency = 0;
	VATCommissionSumInFolioCurrency = 0;
	If ValueIsFilled(RoomService) Then
		// In document currency
		VATSum = cmCalculateVATSum(VATRate, Sum, Date);
		// In folio currency
		If ValueIsFilled(FolioCurrency) Then
			SumInFolioCurrency = Round(cmConvertCurrencies(Sum, Currency, CurrencyExchangeRate, FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
			VATSumInFolioCurrency = cmCalculateVATSum(VATRate, SumInFolioCurrency, Date);
			// Discount
			If cmIsServiceInServiceGroup(RoomService, DiscountServiceGroup) Then
				DiscountSumInFolioCurrency = Round(SumInFolioCurrency * Discount / 100, 2);
				VATDiscountSumInFolioCurrency = cmCalculateVATSum(VATRate, DiscountSumInFolioCurrency, Date);
			EndIf;
			// Commission
			If cmIsServiceInServiceGroup(RoomService, AgentCommissionServiceGroup) Then
				If AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
					CommissionSumInFolioCurrency = Round((SumInFolioCurrency - DiscountSumInFolioCurrency) * AgentCommission/100, 2);
					VATCommissionSumInFolioCurrency = cmCalculateVATSum(VATRate, CommissionSumInFolioCurrency, Date);
				ElsIf AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
					If ValueIsFilled(Folio) And ValueIsFilled(Folio.ParentDoc) Then
						If (TypeOf(Folio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(Folio.ParentDoc) = Type("DocumentRef.Accommodation")) And 
						   BegOfDay(Folio.ParentDoc.CheckInDate) = BegOfDay(Date) Then
							CommissionSumInFolioCurrency = Round((SumInFolioCurrency - DiscountSumInFolioCurrency) * AgentCommission/100, 2);
							VATCommissionSumInFolioCurrency = cmCalculateVATSum(VATRate, CommissionSumInFolioCurrency, Date);
						ElsIf TypeOf(Folio.ParentDoc) = Type("DocumentRef.ResourceReservation") And BegOfDay(Folio.ParentDoc.DateTimeFrom) = BegOfDay(Date) Then
							CommissionSumInFolioCurrency = Round((SumInFolioCurrency - DiscountSumInFolioCurrency) * AgentCommission/100, 2);
							VATCommissionSumInFolioCurrency = cmCalculateVATSum(VATRate, CommissionSumInFolioCurrency, Date);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	Else
		Sum = 0;
		VATSum = 0;
	EndIf;
	// Fixed service sum
	FixedServiceSumInFolioCurrency = 0;
	FixedServiceVATSumInFolioCurrency = 0;
	FixedServiceDiscountSumInFolioCurrency = 0;
	FixedServiceVATDiscountSumInFolioCurrency = 0;
	FixedServiceCommissionSumInFolioCurrency = 0;
	FixedServiceVATCommissionSumInFolioCurrency = 0;
	If ValueIsFilled(FixedService) Then
		// In document currency
		FixedServiceVATSum = cmCalculateVATSum(FixedServiceVATRate, FixedServiceSum, Date);
		// In folio currency
		If ValueIsFilled(FolioCurrency) Then
			FixedServiceSumInFolioCurrency = Round(cmConvertCurrencies(FixedServiceSum, Currency, CurrencyExchangeRate, FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
			FixedServiceVATSumInFolioCurrency = cmCalculateVATSum(FixedServiceVATRate, FixedServiceSumInFolioCurrency, Date);
			// Discount
			If cmIsServiceInServiceGroup(FixedService, DiscountServiceGroup) Then
				FixedServiceDiscountSumInFolioCurrency = Round(FixedServiceSumInFolioCurrency * Discount / 100, 2);
				FixedServiceVATDiscountSumInFolioCurrency = cmCalculateVATSum(FixedServiceVATRate, FixedServiceDiscountSumInFolioCurrency, Date);
			EndIf;
			// Commission
			If cmIsServiceInServiceGroup(FixedService, AgentCommissionServiceGroup) Then
				If AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
					FixedServiceCommissionSumInFolioCurrency = Round((FixedServiceSumInFolioCurrency - FixedServiceDiscountSumInFolioCurrency) * AgentCommission/100, 2);
					FixedServiceVATCommissionSumInFolioCurrency = cmCalculateVATSum(FixedServiceVATRate, FixedServiceCommissionSumInFolioCurrency, Date);
				ElsIf AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
					If ValueIsFilled(Folio) And ValueIsFilled(Folio.ParentDoc) Then
						If (TypeOf(Folio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(Folio.ParentDoc) = Type("DocumentRef.Accommodation")) And 
						   BegOfDay(Folio.ParentDoc.CheckInDate) = BegOfDay(Date) Then
							FixedServiceCommissionSumInFolioCurrency = Round((FixedServiceSumInFolioCurrency - FixedServiceDiscountSumInFolioCurrency) * AgentCommission/100, 2);
							FixedServiceVATCommissionSumInFolioCurrency = cmCalculateVATSum(FixedServiceVATRate, FixedServiceCommissionSumInFolioCurrency, Date);
						ElsIf TypeOf(Folio.ParentDoc) = Type("DocumentRef.ResourceReservation") And BegOfDay(Folio.ParentDoc.DateTimeFrom) = BegOfDay(Date) Then
							FixedServiceCommissionSumInFolioCurrency = Round((FixedServiceSumInFolioCurrency - FixedServiceDiscountSumInFolioCurrency) * AgentCommission/100, 2);
							FixedServiceVATCommissionSumInFolioCurrency = cmCalculateVATSum(FixedServiceVATRate, FixedServiceCommissionSumInFolioCurrency, Date);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	Else
		FixedServiceSum = 0;
		FixedServiceVATSum = 0;
	EndIf;
EndProcedure // pmRecalculateSums

// -----------------------------------------------------------------------------
Procedure pmFillByFolio() Export
	If Not ValueIsFilled(Folio) Then
		Return;
	EndIf;
	// Folio currency
	FolioCurrency = Folio.FolioCurrency;
	If ValueIsFilled(Folio.Hotel) Then
		If Hotel <> Folio.Hotel Then
			Hotel = Folio.Hotel;
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	If ValueIsFilled(Folio.Company) Then
		Company = Folio.Company;
		If Company.IsUsingSimpleTaxSystem Then
			VATRate = Company.VATRate;
			FixedServiceVATRate = Company.VATRate;
		EndIf;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(FolioCurrency) Then
			FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ExchangeRateDate);
		Else
			FolioCurrencyExchangeRate = 0;
		EndIf;
	Else
		FolioCurrencyExchangeRate = 0;
	EndIf;
	// Parent document
	If ValueIsFilled(Folio.ParentDoc) Then
		// Client type
		ClientType = Folio.ParentDoc.ClientType;
		ClientTypeConfirmationText = Folio.ParentDoc.ClientTypeConfirmationText;
		// Discount
		If ValueIsFilled(Folio.ParentDoc.DiscountType) And Not Folio.ParentDoc.DiscountType.DoNotApplyToExternalInterfaces Then
			DiscountCard = Folio.ParentDoc.DiscountCard;
			DiscountType = Folio.ParentDoc.DiscountType;
			DiscountConfirmationText = Folio.ParentDoc.DiscountConfirmationText;
			Discount = Folio.ParentDoc.Discount;
			DiscountServiceGroup = Folio.ParentDoc.DiscountServiceGroup;
		EndIf;
	EndIf;
	// Commission
	If ValueIsFilled(Folio.Agent) Then
		AgentCommission = Folio.Agent.AgentCommission;
		AgentCommissionType = Folio.Agent.AgentCommissionType;
		AgentCommissionServiceGroup = Folio.Agent.AgentCommissionServiceGroup;
	EndIf;
EndProcedure // pmFillByFolio

// -----------------------------------------------------------------------------
Procedure pmFillRoomServiceChargeType() Export
	RoomServiceChargeType = TrimAll(RoomService.Code);
EndProcedure // pmFillRoomServiceChargeType

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
	If Not ValueIsFilled(Currency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Currency", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Room) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Номер> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Room> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ServiceDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата и время услуги> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Service charge date and time> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Service charge date and time> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ServiceDate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ExchangeRateDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата курса> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ExchangeRateDate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(RoomService) And Not ValueIsFilled(FixedService) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Как минимум одна из услуг должна быть указана!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "At least one service should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "At least one service should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomService", pAttributeInErr);
	EndIf;
	If Sum <> 0 Then
		If Not ValueIsFilled(Folio) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Реквизит <Фолио> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Folio> attribute should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Folio> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Folio", pAttributeInErr);
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Author = SessionParameters.CurrentUser;
	Date = CurrentSessionDate();
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		Company = Hotel.Company;
		RoomServicePriceIsWithVAT = True;
		If ValueIsFilled(Company) Then
			VATRate = Company.VATRate;
			FixedServiceVATRate = Company.VATRate;
		EndIf;
		ExchangeRateDate = BegOfDay(Date); 
		ServiceDate = Date;
		Currency = Hotel.BaseCurrency;
		CurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, Currency, ExchangeRateDate);
		ReportingCurrency = Hotel.ReportingCurrency;
		ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, ReportingCurrency, ExchangeRateDate);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
// Document will create charge for the room service charge specified
// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	If AdditionalProperties.Property("NoPostprocessing") Then
		If AdditionalProperties.NoPostprocessing Then
			Return;
		EndIf;
	EndIf;
	// First check if there is posted charges for the current document
	vCharges = pmGetRoomServiceCharges();
	// Initialize charge objects
	vChargeObj = Undefined;
	vFixedServiceChargeObj = Undefined;
	For Each vChargesRow In vCharges Do
		If vChargesRow.Charge.IsFixedCharge Then
			vFixedServiceChargeObj = vChargesRow.Charge.GetObject();
		Else
			vChargeObj = vChargesRow.Charge.GetObject();
		EndIf;
	EndDo;
	If ValueIsFilled(RoomService) Then
		If vChargeObj = Undefined Then
			// Create charge document
			vChargeObj = Documents.Charge.CreateDocument();
			vChargeObj.pmFillAttributesWithDefaultValues();
			SetChargeHotelAndNumber(vChargeObj);
		EndIf;
	Else
		If vChargeObj <> Undefined Then
			// Mark this document deleted
			If Not cmIfChargeIsInClosedDay(vChargeObj) Then
				vChargeObj.SetDeletionMark(True);
			EndIf;
			vChargeObj = Undefined;
		EndIf;
	EndIf;
	If ValueIsFilled(FixedService) Then
		If vFixedServiceChargeObj = Undefined Then
			// Create charge document
			vFixedServiceChargeObj = Documents.Charge.CreateDocument();
			vFixedServiceChargeObj.pmFillAttributesWithDefaultValues();
			SetChargeHotelAndNumber(vFixedServiceChargeObj);
		EndIf;
	Else
		If vFixedServiceChargeObj <> Undefined Then
			// Mark this document deleted
			If Not cmIfChargeIsInClosedDay(vFixedServiceChargeObj) Then
				vFixedServiceChargeObj.SetDeletionMark(True);
			EndIf;
			vFixedServiceChargeObj = Undefined;
		EndIf;
	EndIf;
	// Fill charges
	If ValueIsFilled(Folio) Then
		If vChargeObj <> Undefined Then
			// Post this document
			FillChargeDocumentAttributesForRoomService(vChargeObj);
			If vChargeObj.Modified() Then
				If Not cmIfChargeIsInClosedDay(vChargeObj) Then
					vChargeObj.Write(DocumentWriteMode.Posting);
				EndIf;
			Endif;
		EndIf;
		If vFixedServiceChargeObj <> Undefined Then
			// Post this document
			FillChargeDocumentAttributesForFixedServiceCharge(vFixedServiceChargeObj);
			If vFixedServiceChargeObj.Modified() Then
				If Not cmIfChargeIsInClosedDay(vFixedServiceChargeObj) Then
					vFixedServiceChargeObj.Write(DocumentWriteMode.Posting);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Post to RoomServices register
	PostToRoomServices(vChargeObj, vFixedServiceChargeObj);
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If AdditionalProperties.Property("NoPostprocessing") Then
		If AdditionalProperties.NoPostprocessing Then
			Return;
		EndIf;
	EndIf;
	//check if it is exernal  charge and is already posed
	If NOT IsBlankString(ExternalCode) Then
		vQ = New Query("SELECT
		               |	RecordRoomService.ExternalCode,
		               |	RecordRoomService.Ref
		               |FROM
		               |	Document.RecordRoomService AS RecordRoomService
		               |WHERE
		               |	RecordRoomService.ExternalCode = &qExternalCode
		               |	AND RecordRoomService.Posted
		               |	AND RecordRoomService.Ref <> &qRef");
		vQ.SetParameter("qExternalCode",ExternalCode);
		vQ.SetParameter("qRef",Ref);
		qRes = vQ.Execute();
		If Not qRes.IsEmpty() Then
			pCancel = true;
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr("en = 'Charge with the same external code already exists'; ru = 'Уже есть начисление с таким же внешним кодом. Дублирующее начисление сохранять не нужно.'; de = 'In Rechnung mit den gleichen bereits externen Code existiert'"));
			Return;
		EndIf;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
	Else
		// Check if this document is closed by settlement
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And 
		  (pWriteMode = DocumentWriteMode.UndoPosting Or DeletionMark) And 
		  (Sum <> 0 Or Quantity <> 0) And ValueIsFilled(Folio) And Folio.IsClosed And 
		   cmGetRoomServiceDocumentCharges(Ref).Count() > 0 Then
			vDocBalanceIsZero = False;
			vDocBalancesRow = cmGetRoomServiceDocumentCurrentAccountsReceivableBalance(Ref);
			If vDocBalancesRow <> Undefined Then
				If vDocBalancesRow.SumBalance = 0 And vDocBalancesRow.QuantityBalance = 0 Then
					vDocBalanceIsZero = True;
				EndIf;
			Else
				vDocBalanceIsZero = True;
			EndIf;
			If vDocBalanceIsZero Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This document is closed by settlement! You can not change this document.';ru='Документ уже закрыт актом об оказании услуг! Редактирование такого докумена запрещено.';de='Das Dokument wurde bereits über ein Dienstleistungserbringungsprotokoll geschlossen! Die Bearbeitung eines solchen Dokuments ist verboten.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If AdditionalProperties.Property("NoPostprocessing") Then
		If AdditionalProperties.NoPostprocessing Then
			Return;
		EndIf;
	EndIf;
	// First check if there is posted charges for the current document
	vCharges = pmGetRoomServiceCharges();
	// Undo posting for them
	For Each vChargesRow In vCharges Do
		vChargeObj = vChargesRow.Charge.GetObject();
		vChargeObj.Write(DocumentWriteMode.UndoPosting);
	EndDo;
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If AdditionalProperties.Property("NoPostprocessing") Then
		If AdditionalProperties.NoPostprocessing Then
			Return;
		EndIf;
	EndIf;
	If Posted Then
		// Check if this document is closed by settlement
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And 
		  (Sum <> 0 Or Quantity <> 0) And ValueIsFilled(Folio) And Folio.IsClosed And 
		   cmGetRoomServiceDocumentCharges(Ref).Count() > 0 Then
			vDocBalanceIsZero = False;
			vDocBalancesRow = cmGetRoomServiceDocumentCurrentAccountsReceivableBalance(Ref);
			If vDocBalancesRow <> Undefined Then
				If vDocBalancesRow.SumBalance = 0 And vDocBalancesRow.QuantityBalance = 0 Then
					vDocBalanceIsZero = True;
				EndIf;
			Else
				vDocBalanceIsZero = True;
			EndIf;
			If vDocBalanceIsZero Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This document is closed by settlement! You can not change this document.';ru='Документ уже закрыт актом об оказании услуг! Редактирование такого докумена запрещено.';de='Das Dokument wurde bereits über ein Dienstleistungserbringungsprotokoll geschlossen! Die Bearbeitung eines solchen Dokuments ist verboten.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
		UndoPosting(pCancel);
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)     
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillChargeDocumentAttributesForRoomService(pChargeObj)
	If pChargeObj.ParentDoc <> Folio.ParentDoc Then
		pChargeObj.ParentDoc = Folio.ParentDoc;
	EndIf;
	If pChargeObj.ParentRoomService <> Ref Then
		pChargeObj.ParentRoomService = Ref;
	EndIf;
	If pChargeObj.IsFixedCharge Then
		pChargeObj.IsFixedCharge = False;
	EndIf;
	If pChargeObj.Hotel <> Hotel Then
		pChargeObj.Hotel = Hotel;
	EndIf;
	If pChargeObj.ExchangeRateDate <> ExchangeRateDate Then
		pChargeObj.ExchangeRateDate = ExchangeRateDate;
	EndIf;
	If pChargeObj.Folio <> Folio Then
		pChargeObj.Folio = Folio;
	EndIf;
	If pChargeObj.ClientType <> ClientType Then
		pChargeObj.ClientType = ClientType;
	EndIf;
	If TrimAll(pChargeObj.ClientTypeConfirmationText) <> TrimAll(ClientTypeConfirmationText) Then
		pChargeObj.ClientTypeConfirmationText = ClientTypeConfirmationText;
	EndIf;
	If ValueIsFilled(Folio.ParentDoc) Then
		vParentDoc = Folio.ParentDoc;
		If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
			If pChargeObj.MarketingCode <> vParentDoc.MarketingCode Then
				pChargeObj.MarketingCode = vParentDoc.MarketingCode;
				pChargeObj.MarketingCodeConfirmationText = vParentDoc.MarketingCodeConfirmationText;
			EndIf;
			If pChargeObj.SourceOfBusiness <> vParentDoc.SourceOfBusiness Then
				pChargeObj.SourceOfBusiness = vParentDoc.SourceOfBusiness;
			EndIf;
		EndIf;
	EndIf;
	If pChargeObj.Service <> RoomService Then
		pChargeObj.Service = RoomService;
		If ValueIsFilled(pChargeObj.Service) And pChargeObj.PaymentSection <> pChargeObj.Service.PaymentSection Then
			pChargeObj.PaymentSection = pChargeObj.Service.PaymentSection;
		EndIf;
	EndIf;
	If pChargeObj.Price <> cmRecalculatePrice(SumInFolioCurrency, Quantity) Then
		pChargeObj.Price = cmRecalculatePrice(SumInFolioCurrency, Quantity);
	EndIf;
	If TrimAll(pChargeObj.Unit) <> TrimAll(Unit) Then
		pChargeObj.Unit = Unit;
	EndIf;
	If pChargeObj.Quantity <> Quantity Then
		pChargeObj.Quantity = Quantity;
	EndIf;
	If pChargeObj.Sum <> SumInFolioCurrency Then
		pChargeObj.Sum = SumInFolioCurrency;
	EndIf;
	If pChargeObj.VATRate <> VATRate Then
		pChargeObj.VATRate = VATRate;
	EndIf;
	If pChargeObj.VATSum <> VATSumInFolioCurrency Then
		pChargeObj.VATSum = VATSumInFolioCurrency;
	EndIf;
	If TrimAll(pChargeObj.Remarks) <> TrimAll(Remarks) Then
		pChargeObj.Remarks = Remarks;
	EndIf;
	If pChargeObj.IsRoomRevenue Then
		pChargeObj.IsRoomRevenue = False;
	EndIf;
	If pChargeObj.IsInPrice Then
		pChargeObj.IsInPrice = False;
	EndIf;
	If pChargeObj.FolioCurrency <> FolioCurrency Then
		pChargeObj.FolioCurrency = FolioCurrency;
	EndIf;
	If pChargeObj.FolioCurrencyExchangeRate <> FolioCurrencyExchangeRate Then
		pChargeObj.FolioCurrencyExchangeRate = FolioCurrencyExchangeRate;
	EndIf;
	If pChargeObj.ReportingCurrency <> ReportingCurrency Then
		pChargeObj.ReportingCurrency = ReportingCurrency;
	EndIf;
	If pChargeObj.ReportingCurrencyExchangeRate <> ReportingCurrencyExchangeRate Then
		pChargeObj.ReportingCurrencyExchangeRate = ReportingCurrencyExchangeRate;
	EndIf;
	If pChargeObj.Company <> Company Then
		pChargeObj.Company = Company;
	EndIf;
	If pChargeObj.DiscountCard <> DiscountCard Then
		pChargeObj.DiscountCard = DiscountCard;
	EndIf;
	If pChargeObj.DiscountType <> DiscountType Then
		pChargeObj.DiscountType = DiscountType;
	EndIf;
	If TrimAll(pChargeObj.DiscountConfirmationText) <> TrimAll(DiscountConfirmationText) Then
		pChargeObj.DiscountConfirmationText = DiscountConfirmationText;
	EndIf;
	If pChargeObj.Discount <> Discount Then
		pChargeObj.Discount = Discount;
	EndIf;
	If pChargeObj.DiscountServiceGroup <> DiscountServiceGroup Then
		pChargeObj.DiscountServiceGroup = DiscountServiceGroup;
	EndIf;
	If pChargeObj.DiscountSum <> DiscountSumInFolioCurrency Then
		pChargeObj.DiscountSum = DiscountSumInFolioCurrency;
	EndIf;
	If pChargeObj.VATDiscountSum <> VATDiscountSumInFolioCurrency Then
		pChargeObj.VATDiscountSum = VATDiscountSumInFolioCurrency;
	EndIf;
	If pChargeObj.AgentCommission <> AgentCommission Then
		pChargeObj.AgentCommission = AgentCommission;
	EndIf;
	If pChargeObj.AgentCommissionType <> AgentCommissionType Then
		pChargeObj.AgentCommissionType = AgentCommissionType;
	EndIf;
	If pChargeObj.AgentCommissionServiceGroup <> AgentCommissionServiceGroup Then
		pChargeObj.AgentCommissionServiceGroup = AgentCommissionServiceGroup;
	EndIf;
	If pChargeObj.CommissionSum <> CommissionSumInFolioCurrency Then
		pChargeObj.CommissionSum = CommissionSumInFolioCurrency;
	EndIf;
	If pChargeObj.VATCommissionSum <> VATCommissionSumInFolioCurrency Then
		pChargeObj.VATCommissionSum = VATCommissionSumInFolioCurrency;
	EndIf;
	If TrimAll(pChargeObj.Details) <> TrimAll(Details) Then
		pChargeObj.Details = Details;
	EndIf;
	If Not pChargeObj.IsAdditional Then
		pChargeObj.IsAdditional = True;
	EndIf;
	If ValueIsFilled(pChargeObj.ParentDoc) Then
		vChargeParentDoc = pChargeObj.ParentDoc;
		If TypeOf(vChargeParentDoc) = Type("DocumentRef.Accommodation") Or
		   TypeOf(vChargeParentDoc) = Type("DocumentRef.Reservation") Or
		   TypeOf(vChargeParentDoc) = Type("DocumentRef.ResourceReservation") Then
			If ValueIsFilled(vChargeParentDoc.MarketingCode) And vChargeParentDoc.MarketingCode <> pChargeObj.MarketingCode Then
				pChargeObj.MarketingCode = vChargeParentDoc.MarketingCode;
				pChargeObj.MarketingCodeConfirmationText = vChargeParentDoc.MarketingCodeConfirmationText;
			EndIf;
			If ValueIsFilled(vChargeParentDoc.SourceOfBusiness) And vChargeParentDoc.SourceOfBusiness <> pChargeObj.SourceOfBusiness Then
				pChargeObj.SourceOfBusiness = vChargeParentDoc.SourceOfBusiness;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(pChargeObj.Service) And ValueIsFilled(pChargeObj.Service.Resource) Then
		pChargeObj.Resource = pChargeObj.Service.Resource;
	EndIf;
EndProcedure // FillChargeDocumentAttributesForRoomService

// -----------------------------------------------------------------------------
Procedure FillChargeDocumentAttributesForFixedServiceCharge(pChargeObj)
	If pChargeObj.ParentDoc <> Folio.ParentDoc Then
		pChargeObj.ParentDoc = Folio.ParentDoc;
	EndIf;
	If pChargeObj.ParentRoomService <> Ref Then
		pChargeObj.ParentRoomService = Ref;
	EndIf;
	If Not pChargeObj.IsFixedCharge Then
		pChargeObj.IsFixedCharge = True;
	EndIf;
	If pChargeObj.Hotel <> Hotel Then
		pChargeObj.Hotel = Hotel;
	EndIf;
	If pChargeObj.ExchangeRateDate <> ExchangeRateDate Then
		pChargeObj.ExchangeRateDate = ExchangeRateDate;
	EndIf;
	If pChargeObj.Folio <> Folio Then
		pChargeObj.Folio = Folio;
	EndIf;
	If pChargeObj.ClientType <> ClientType Then
		pChargeObj.ClientType = ClientType;
	EndIf;
	If TrimAll(pChargeObj.ClientTypeConfirmationText) <> TrimAll(ClientTypeConfirmationText) Then
		pChargeObj.ClientTypeConfirmationText = ClientTypeConfirmationText;
	EndIf;
	If ValueIsFilled(Folio.ParentDoc) Then
		vParentDoc = Folio.ParentDoc;
		If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
			If pChargeObj.MarketingCode <> vParentDoc.MarketingCode Then
				pChargeObj.MarketingCode = vParentDoc.MarketingCode;
				pChargeObj.MarketingCodeConfirmationText = vParentDoc.MarketingCodeConfirmationText;
			EndIf;
			If pChargeObj.SourceOfBusiness <> vParentDoc.SourceOfBusiness Then
				pChargeObj.SourceOfBusiness = vParentDoc.SourceOfBusiness;
			EndIf;
		EndIf;
	EndIf;
	If pChargeObj.Service <> FixedService Then
		pChargeObj.Service = FixedService;
		If ValueIsFilled(pChargeObj.Service) And pChargeObj.PaymentSection <> pChargeObj.Service.PaymentSection Then
			pChargeObj.PaymentSection = pChargeObj.Service.PaymentSection;
		EndIf;
	EndIf;
	If pChargeObj.Price <> cmRecalculatePrice(FixedServiceSumInFolioCurrency, 1) Then
		pChargeObj.Price = cmRecalculatePrice(FixedServiceSumInFolioCurrency, 1);
	EndIf;
	If TrimAll(pChargeObj.Unit) <> TrimAll(FixedService.Unit) Then
		pChargeObj.Unit = FixedService.Unit;
	EndIf;
	If pChargeObj.Quantity <> 1 Then
		pChargeObj.Quantity = 1;
	EndIf;
	If pChargeObj.Sum <> FixedServiceSumInFolioCurrency Then
		pChargeObj.Sum = FixedServiceSumInFolioCurrency;
	EndIf;
	If pChargeObj.VATRate <> FixedServiceVATRate Then
		pChargeObj.VATRate = FixedServiceVATRate;
	EndIf;
	If pChargeObj.VATSum <> FixedServiceVATSumInFolioCurrency Then
		pChargeObj.VATSum = FixedServiceVATSumInFolioCurrency;
	EndIf;
	If TrimAll(pChargeObj.Remarks) <> TrimAll(Remarks) Then
		pChargeObj.Remarks = Remarks;
	EndIf;
	If pChargeObj.IsRoomRevenue Then
		pChargeObj.IsRoomRevenue = False;
	EndIf;
	If pChargeObj.IsInPrice Then
		pChargeObj.IsInPrice = False;
	EndIf;
	If pChargeObj.FolioCurrency <> FolioCurrency Then
		pChargeObj.FolioCurrency = FolioCurrency;
	EndIf;
	If pChargeObj.FolioCurrencyExchangeRate <> FolioCurrencyExchangeRate Then
		pChargeObj.FolioCurrencyExchangeRate = FolioCurrencyExchangeRate;
	EndIf;
	If pChargeObj.ReportingCurrency <> ReportingCurrency Then
		pChargeObj.ReportingCurrency = ReportingCurrency;
	EndIf;
	If pChargeObj.ReportingCurrencyExchangeRate <> ReportingCurrencyExchangeRate Then
		pChargeObj.ReportingCurrencyExchangeRate = ReportingCurrencyExchangeRate;
	EndIf;
	If pChargeObj.Company <> Company Then
		pChargeObj.Company = Company;
	EndIf;
	If pChargeObj.DiscountCard <> DiscountCard Then
		pChargeObj.DiscountCard = DiscountCard;
	EndIf;
	If pChargeObj.DiscountType <> DiscountType Then
		pChargeObj.DiscountType = DiscountType;
	EndIf;
	If TrimAll(pChargeObj.DiscountConfirmationText) <> TrimAll(DiscountConfirmationText) Then
		pChargeObj.DiscountConfirmationText = DiscountConfirmationText;
	EndIf;
	If pChargeObj.Discount <> Discount Then
		pChargeObj.Discount = Discount;
	EndIf;
	If pChargeObj.DiscountServiceGroup <> DiscountServiceGroup Then
		pChargeObj.DiscountServiceGroup = DiscountServiceGroup;
	EndIf;
	If pChargeObj.DiscountSum <> FixedServiceDiscountSumInFolioCurrency Then
		pChargeObj.DiscountSum = FixedServiceDiscountSumInFolioCurrency;
	EndIf;
	If pChargeObj.VATDiscountSum <> FixedServiceVATDiscountSumInFolioCurrency Then
		pChargeObj.VATDiscountSum = FixedServiceVATDiscountSumInFolioCurrency;
	EndIf;
	If pChargeObj.AgentCommission <> AgentCommission Then
		pChargeObj.AgentCommission = AgentCommission;
	EndIf;
	If pChargeObj.AgentCommissionType <> AgentCommissionType Then
		pChargeObj.AgentCommissionType = AgentCommissionType;
	EndIf;
	If pChargeObj.AgentCommissionServiceGroup <> AgentCommissionServiceGroup Then
		pChargeObj.AgentCommissionServiceGroup = AgentCommissionServiceGroup;
	EndIf;
	If pChargeObj.CommissionSum <> FixedServiceCommissionSumInFolioCurrency Then
		pChargeObj.CommissionSum = FixedServiceCommissionSumInFolioCurrency;
	EndIf;
	If pChargeObj.VATCommissionSum <> FixedServiceVATCommissionSumInFolioCurrency Then
		pChargeObj.VATCommissionSum = FixedServiceVATCommissionSumInFolioCurrency;
	EndIf;
	If Not pChargeObj.IsAdditional Then
		pChargeObj.IsAdditional = True;
	EndIf;
	If ValueIsFilled(pChargeObj.ParentDoc) Then
		vChargeParentDoc = pChargeObj.ParentDoc;
		If TypeOf(vChargeParentDoc) = Type("DocumentRef.Accommodation") Or
		   TypeOf(vChargeParentDoc) = Type("DocumentRef.Reservation") Or
		   TypeOf(vChargeParentDoc) = Type("DocumentRef.ResourceReservation") Then
			If ValueIsFilled(vChargeParentDoc.MarketingCode) And vChargeParentDoc.MarketingCode <> pChargeObj.MarketingCode Then
				pChargeObj.MarketingCode = vChargeParentDoc.MarketingCode;
				pChargeObj.MarketingCodeConfirmationText = vChargeParentDoc.MarketingCodeConfirmationText;
			EndIf;
			If ValueIsFilled(vChargeParentDoc.SourceOfBusiness) And vChargeParentDoc.SourceOfBusiness <> pChargeObj.SourceOfBusiness Then
				pChargeObj.SourceOfBusiness = vChargeParentDoc.SourceOfBusiness;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(pChargeObj.Service) And ValueIsFilled(pChargeObj.Service.Resource) Then
		pChargeObj.Resource = pChargeObj.Service.Resource;
	EndIf;
EndProcedure // FillChargeDocumentAttributesForFixedServiceCharge

// -----------------------------------------------------------------------------
Procedure SetChargeHotelAndNumber(pChargeObj)
	If ValueIsFilled(Folio) Then
		If ValueIsFilled(Folio.Hotel) Then
			If pChargeObj.Hotel <> Folio.Hotel Then
				pChargeObj.Hotel = Folio.Hotel;
				pChargeObj.SetNewNumber(Catalogs.Hotels.pmGetPrefix(pChargeObj.Hotel));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SetChargeHotelAndNumber	

// -----------------------------------------------------------------------------
Procedure PostToRoomServices(pCharge, pFixedServiceCharge)
	Movement = RegisterRecords.RoomServices.Add();
	
	Movement.Period = Date;
	
	FillPropertyValues(Movement, ThisObject);
	
	// Resources
	Movement.Sum = Sum;
	
	// Attributes
	If pCharge <> Undefined Then
		Movement.Charge = pCharge.Ref;
	EndIf;
	If pFixedServiceCharge <> Undefined Then
		Movement.FixedServiceCharge = pFixedServiceCharge.Ref;
	EndIf;
	
	If ValueIsFilled(Movement.Charge) Or ValueIsFilled(Movement.FixedServiceCharge) Then
		RegisterRecords.RoomServices.Write();
	EndIf;
EndProcedure // PostToRoomServices

#EndRegion
