
#Region Variables

Var vParentDoc;
Var vClient;
Var vSumInReportingCurrency;
Var vRateSumInReportingCurrency;
Var vVATRateSumInReportingCurrency;
Var vRateDiscountSumInReportingCurrency;
Var vVATSumInReportingCurrency;
Var vDiscountSumInReportingCurrency;
Var vVATDiscountSumInReportingCurrency;
Var vCommissionSumInReportingCurrency;
Var vVATCommissionSumInReportingCurrency;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillCalendarDayTypeByFolio() Export
	If ValueIsFilled(ParentDoc) Then
		If TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or
		   TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
			If ValueIsFilled(ParentDoc.RoomRate) And ValueIsFilled(ParentDoc.RoomRate.Calendar) Then
				vCalendarDays = ParentDoc.RoomRate.Calendar.GetObject().pmGetDays(?(ValueIsFilled(ServiceDate), ServiceDate, Date), ?(ValueIsFilled(ServiceDate), ServiceDate, Date), ParentDoc.CheckInDate, ParentDoc.CheckOutDate, ?(ValueIsFilled(ParentDoc.RoomTypeUpgrade), ParentDoc.RoomTypeUpgrade, ParentDoc.RoomType));
				If vCalendarDays.Count() > 0 Then
					CalendarDayType = vCalendarDays.Get(0).CalendarDayType;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillCalendarDayTypeByFolio

// -----------------------------------------------------------------------------
Procedure pmFillByFolio(pFolio) Export
	If pFolio = Documents.Folio.EmptyRef() Then
		Return;
	EndIf;
	// Folio and folio currency
	Folio = pFolio;
	If ValueIsFilled(Folio.Hotel) Then
		If Hotel <> Folio.Hotel Then
			Hotel = Folio.Hotel;
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	If ValueIsFilled(Folio.Company) Then
		Company = Folio.Company;
		VATRate = Company.VATRate;
	EndIf;
	FolioCurrency = Folio.FolioCurrency;
	FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ExchangeRateDate);
	// Client
	If ValueIsFilled(Folio.Client) And ValueIsFilled(Folio.Client.ClientType) And (Not ValueIsFilled(Folio.Client.ClientType.Hotel) Or Folio.Client.ClientType.Hotel = Hotel) Then
		// Client type
		ClientType = Folio.Client.ClientType;
		ClientTypeConfirmationText = Folio.Client.ClientTypeConfirmationText;
	EndIf;
	// Room and room type
	If ValueIsFilled(Folio.Room) Then
		Room = Folio.Room;
		If ValueIsFilled(Room) Then
			RoomType = Room.RoomType;
		EndIf;
	EndIf;
	// Parent document
	ParentDoc = Folio.ParentDoc;
	If ValueIsFilled(ParentDoc) Then
		// Client type
		ClientType = ParentDoc.ClientType;
		ClientTypeConfirmationText = ParentDoc.ClientTypeConfirmationText;
		// Discount
		DiscountCard = ParentDoc.DiscountCard;
		DiscountType = ParentDoc.DiscountType;
		DiscountConfirmationText = ParentDoc.DiscountConfirmationText;
		Discount = ParentDoc.Discount;
		DiscountServiceGroup = ParentDoc.DiscountServiceGroup;
		// Marketing code
		MarketingCode = ParentDoc.MarketingCode;
		MarketingCodeConfirmationText = ParentDoc.MarketingCodeConfirmationText;
		// Source of business
		SourceOfBusiness = ParentDoc.SourceOfBusiness;
	Else
		If ValueIsFilled(Folio.GuestGroup) Then
			vGuestGroup = Folio.GuestGroup;
			// Marketing code
			MarketingCode = vGuestGroup.MarketingCode;
			// Source of business
			SourceOfBusiness = vGuestGroup.SourceOfBusiness;
		EndIf;
		// Discount
		DiscountCard = Folio.FolioDiscountCard;
		DiscountType = Folio.FolioDiscountType;
		DiscountConfirmationText = "";
		If ValueIsFilled(DiscountType) Then
			DiscountConfirmationText = DiscountType.ConfirmationPattern;
			DiscountServiceGroup = DiscountType.DiscountServiceGroup;
			If DiscountType.IsAccumulatingDiscount Then
				pmCalculateAccumulationDiscount();
			Else	
				vDiscountTypeObj = DiscountType.GetObject();
				Discount = vDiscountTypeObj.pmGetDiscount(?(ValueIsFilled(ServiceDate), ServiceDate, Date), Service, Hotel);
			EndIf;
		EndIf;
	EndIf;
	// Calendar day type
	pmFillCalendarDayTypeByFolio();
	// Get complex commission
	vComplexCommission = pmGetComplexCommission(Folio);
	// Commission
	If vComplexCommission.Count() > 0 And ValueIsFilled(Service) Then
		For Each vComplexCommissionRow In vComplexCommission Do
			If BegOfDay(vComplexCommissionRow.Period) <= BegOfDay(Date) Then
				If cmIsServiceInServiceGroup(Service, vComplexCommissionRow.ServiceGroup) Then
					If Not ValueIsFilled(vComplexCommissionRow.RoomClass) And Not ValueIsFilled(vComplexCommissionRow.RoomType) Or
					   ValueIsFilled(vComplexCommissionRow.RoomClass) And Not ValueIsFilled(vComplexCommissionRow.RoomType) And ValueIsFilled(RoomType) And RoomType.RoomClass = vComplexCommissionRow.RoomClass Or
					   ValueIsFilled(vComplexCommissionRow.RoomType) And vComplexCommissionRow.RoomType = RoomType Then
						AgentCommissionType = vComplexCommissionRow.CommissionType;
						AgentCommission = vComplexCommissionRow.Commission;
						AgentCommissionServiceGroup = vComplexCommissionRow.ServiceGroup;
						Break;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Else	
		If ValueIsFilled(Folio.Agent) Then
			If ValueIsFilled(Folio.ParentDoc) Then
				AgentCommission = Folio.ParentDoc.AgentCommission;
				AgentCommissionType = Folio.ParentDoc.AgentCommissionType;
				AgentCommissionServiceGroup = Folio.ParentDoc.AgentCommissionServiceGroup;
			Else
				AgentCommission = Folio.Agent.AgentCommission;
				AgentCommissionType = Folio.Agent.AgentCommissionType;
				AgentCommissionServiceGroup = Folio.Agent.AgentCommissionServiceGroup;
			EndIf;
		EndIf;
	EndIf;
	// Hotel product
	If ValueIsFilled(Folio.HotelProduct) Then
		HotelProduct = Folio.HotelProduct;
	EndIf;
EndProcedure // pmFillByFolio

// -----------------------------------------------------------------------------
Function pmGetComplexCommission(pFolio) Export
	If ValueIsFilled(Folio.ParentDoc) Then
		vAgent = Folio.ParentDoc.Agent;
		vContract = Folio.ParentDoc.Contract;
	Else
		vAgent = Folio.Agent;
		vContract = Folio.Contract;
	EndIf;	
	
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	CommissionSliceLast.Period AS SliceLastPeriod,
	|	CommissionSliceLast.Agent AS SliceLastAgent,
	|	CommissionSliceLast.Contract AS SliceLastContract,
	|	CommissionSliceLast.ServiceGroup AS SliceLastServiceGroup,
	|	CommissionSliceLast.RoomClass AS SliceLastRoomClass,
	|	CommissionSliceLast.RoomType AS SliceLastRoomType,
	|	CommissionSliceLast.Hotel AS SliceLastHotel,
	|	CommissionSliceLast.Commission AS SliceLastCommission,
	|	CommissionSliceLast.CommissionType AS SliceLastCommissionType
	|INTO CommissionSliceLast
	|FROM
	|	InformationRegister.Commission.SliceLast(
	|			&qPeriodFrom,
	|			Agent = &qAgent
	|				AND Contract = &qContract
	|				AND (Hotel = &qHotel
	|					OR Hotel = &qEmptyHotel)) AS CommissionSliceLast
	|
	|ORDER BY
	|	SliceLastPeriod DESC,
	|	CommissionSliceLast.ServiceGroup.Code
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Commissions.Period AS Period,
	|	Commissions.Agent AS Agent,
	|	Commissions.Contract AS Contract,
	|	Commissions.ServiceGroup AS ServiceGroup,
	|	Commissions.RoomClass AS RoomClass,
	|	Commissions.RoomType AS RoomType,
	|	Commissions.Hotel AS Hotel,
	|	Commissions.Commission AS Commission,
	|	Commissions.CommissionType AS CommissionType
	|FROM
	|	(SELECT
	|		ComplexCommission.Period AS Period,
	|		ComplexCommission.Agent AS Agent,
	|		ComplexCommission.Contract AS Contract,
	|		ComplexCommission.ServiceGroup AS ServiceGroup,
	|		ComplexCommission.RoomClass AS RoomClass,
	|		ComplexCommission.RoomType AS RoomType,
	|		ComplexCommission.Hotel AS Hotel,
	|		ComplexCommission.Commission AS Commission,
	|		ComplexCommission.CommissionType AS CommissionType
	|	FROM
	|		InformationRegister.Commission AS ComplexCommission
	|			INNER JOIN CommissionSliceLast AS CommissionSliceLast
	|			ON ComplexCommission.Period = CommissionSliceLast.SliceLastPeriod
	|				AND ComplexCommission.Agent = CommissionSliceLast.SliceLastAgent
	|				AND ComplexCommission.Contract = CommissionSliceLast.SliceLastContract
	|				AND ComplexCommission.Hotel = CommissionSliceLast.SliceLastHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ComplexCommissionChanges.Period,
	|		ComplexCommissionChanges.Agent,
	|		ComplexCommissionChanges.Contract,
	|		ComplexCommissionChanges.ServiceGroup,
	|		ComplexCommissionChanges.RoomClass,
	|		ComplexCommissionChanges.RoomType,
	|		ComplexCommissionChanges.Hotel,
	|		ComplexCommissionChanges.Commission,
	|		ComplexCommissionChanges.CommissionType
	|	FROM
	|		InformationRegister.Commission AS ComplexCommissionChanges
	|	WHERE
	|		ComplexCommissionChanges.Period > &qPeriodFrom
	|		AND ComplexCommissionChanges.Period < &qPeriodTo
	|		AND ComplexCommissionChanges.Agent = &qAgent
	|		AND ComplexCommissionChanges.Contract = &qContract
	|		AND (ComplexCommissionChanges.Hotel = &qHotel
	|				OR ComplexCommissionChanges.Hotel = &qEmptyHotel)) AS Commissions
	|
	|ORDER BY
	|	Commissions.Period DESC,
	|	ISNULL(Commissions.RoomClass.SortCode, 0) DESC,
	|	ISNULL(Commissions.RoomType.SortCode, 0) DESC,
	|	Commissions.ServiceGroup.Code";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qAgent", vAgent);
	vQry.SetParameter("qContract", vContract);
	vQry.SetParameter("qPeriodFrom", Date);
	vQry.SetParameter("qPeriodTo", Date);
	vComplexCommission = vQry.Execute().Unload();
	Return vComplexCommission;
EndFunction // pmGetComplexCommission

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
	If Not ValueIsFilled(Service) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Услуга> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Service> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Service> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Service", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ReportingCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Отчетная валюта> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Reporting currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Reporting currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ReportingCurrency", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ExchangeRateDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата курса> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ExchangeRateDate", pAttributeInErr);
	EndIf;
	If Not IsCorrection And Price = 0 And Sum <> 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Цена> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Price> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Price> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ExchangeRateDate", pAttributeInErr);
	EndIf;
	If ValueIsFilled(Service) And Service.IsGiftCertificate Then
		If Not IsBlankString(GiftCertificate) Then
			vOtherGiftCertCharges = cmGetGiftCertificateCharges(GiftCertificate, Ref);
			If vOtherGiftCertCharges.Count() > 0 Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Подарочный сертификат (" + TrimAll(GiftCertificate) + ") уже был продан!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Gift certificate (" + TrimAll(GiftCertificate) + ") was already sold!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Gift certificate (" + TrimAll(GiftCertificate) + ") was already sold!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "GiftCertificate", pAttributeInErr);
			EndIf;
			If Quantity <> 1 Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Реквизит <Количество> должен быть равен 1!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "<Quantity> attribute should be 1!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "<Quantity> attribute should be 1!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Quantity", pAttributeInErr);
			Endif;
		EndIf;
	EndIf;
	If Not Posted Then
		If Not ValueIsFilled(ClientType) And Not ValueIsFilled(ParentRoomService) Then
			If Not cmCheckUserPermissions("HavePermissionToSkipInputOfClientType") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Реквизит <Тип клиента> должен быть заполнен!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "<Client type> attribute should be filled!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "<Client type> attribute should be filled!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "ClientType", pAttributeInErr);
			EndIf;
		EndIf;
		// Check folio payment section
		If ValueIsFilled(Folio) And ValueIsFilled(Folio.PaymentSection) And ValueIsFilled(PaymentSection) Then
			If Folio.PaymentSection <> PaymentSection Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Секция оплаты начисления отличается от секции оплаты лицевого счета!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Charge payment section is different from folio payment section!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Charge Zahlung Abschnitt unterscheidet sich von Folio Zahlung Abschnitt!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "PaymentSection", pAttributeInErr);
			EndIf;
		EndIf;
		// Check user rights to do storno
		If Sum < 0 Then
			If Not ValueIsFilled(ChargeCorrectionType) And Not cmCheckUserPermissions("HavePermissionToStornoFolioCharges") Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Нет прав на сторнирование начислений!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "You do not have rights to storno charges!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "You do not have rights to storno charges!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Sum", pAttributeInErr);
			EndIf;
		EndIf;
		// Check user rights to use current service
		If Not IsManual Then
			vEmployee = SessionParameters.CurrentUser;
			If ValueIsFilled(vEmployee) And ValueIsFilled(vEmployee.PermissionGroup) And ValueIsFilled(Folio) Then
				vPermissionGroup = vEmployee.PermissionGroup;
				For Each vPrmRow In vPermissionGroup.FolioOperationsAllowed Do
					If IsBlankString(vPrmRow.FolioType) Or 
					   Not IsBlankString(vPrmRow.FolioType) And TrimR(vPrmRow.FolioType) = Left(TrimR(Folio.Description), StrLen(TrimR(vPrmRow.FolioType))) Then
						If ValueIsFilled(Service) And ValueIsFilled(vPrmRow.ServiceGroup) And Not cmIsServiceInServiceGroup(Service, vPrmRow.ServiceGroup) Then
							vHasErrors = True;
							vMsgTextRu = vMsgTextRu + "Нет прав на использование услуги " + TrimAll(Service) + " в фолио с типом " + TrimAll(Folio.Description) + "!" + Chars.LF;
							vMsgTextEn = vMsgTextEn + "You do not have rights to use service " + TrimAll(Service) + " in folio type " + TrimAll(Folio.Description) + "!" + Chars.LF;
							vMsgTextDe = vMsgTextDe + "Sie haben keine Rechte Service " + TrimAll(Service) + " in Folio-typ " + TrimAll(Folio.Description) + " nutzen!" + Chars.LF;
							pAttributeInErr = ?(pAttributeInErr = "", "Service", pAttributeInErr);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate(pCurrentAccountingDate = '00010101') Export
	If ValueIsFilled(pCurrentAccountingDate) Then
		Date = pCurrentAccountingDate;
	Else
		Date = CurrentSessionDate();
	EndIf;
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Suppose it is additional service
	IsAdditional = True;
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	ExchangeRateDate = BegOfDay(CurrentSessionDate());
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(Hotel.AccountingDate) Then
			If BegOfDay(Date) > Hotel.AccountingDate Then
				Date = EndOfDay(Hotel.AccountingDate);
			EndIf;
		EndIf;
		FolioCurrency  = Hotel.FolioCurrency;
		FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ExchangeRateDate);
		ReportingCurrency = Hotel.ReportingCurrency;
		ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, ReportingCurrency, ExchangeRateDate);
		Company = Hotel.Company;
		If ValueIsFilled(Company) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function GetEffectiveGuestGroup()
	vGuestGroup = Catalogs.GuestGroups.EmptyRef();
	If ValueIsFilled(Folio.GuestGroup) Then
		vGuestGroup = Folio.GuestGroup;
	Else
		If ValueIsFilled(ParentDoc) And 
		  (TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or 
		   TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or 
		   TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation")) And
		   ValueIsFilled(ParentDoc.GuestGroup) Then
			vGuestGroup = ParentDoc.GuestGroup;
		EndIf;
	EndIf;
	Return vGuestGroup;
EndFunction // GetEffectiveGuestGroup

// -----------------------------------------------------------------------------
Function pmGetAccumulatingDiscountResources() Export
	// Initialize map with resources
	vRes = New ValueTable();
	vRes.Columns.Add("DiscountType", cmGetCatalogTypeDescription("DiscountTypes"), "Discount type", 20);
	vRes.Columns.Add("DiscountDimension", cmGetDiscountDimensionTypeDescription(), "Discount dimension", 20);
	vRes.Columns.Add("Resource", cmGetAccumulatingDiscountResourceTypeDescription(), "Discount resource", 20);
	vRes.Columns.Add("Bonus", cmGetAccumulatingDiscountResourceTypeDescription(), "Bonus", 20);
	// Check folio
	If Not ValueIsFilled(Folio) Then
		Return vRes;
	EndIf;
	// Get list of accumulating discount types defined in the catalog
	vDiscountType = Undefined;
	If ValueIsFilled(DiscountType) And DiscountType.IsAccumulatingDiscount Then
		vDiscountType = DiscountType;
	EndIf;
	vAccDisTypes = cmGetAccumulatingDiscountTypes(vDiscountType, Hotel);
	// Get effective guest group
	vGuestGroup = GetEffectiveGuestGroup();
	// Get resources
	For Each vAccDisType In vAccDisTypes Do
		vDiscountType = vAccDisType.DiscountType;
		vDiscountTypeObj = vDiscountType.GetObject();
		vAccDisRes = vDiscountTypeObj.pmGetAccumulatingDiscountResources(Date,
		                                                                 Folio.Customer,
		                                                                 Folio.Contract,
		                                                                 Folio.Client,
		                                                                 DiscountCard,
		                                                                 ?(vDiscountType.IsPerVisit, vGuestGroup, Undefined));
		If vAccDisRes.Count() = 0 Then
			vResRow = vRes.Add();
			vResRow.DiscountType = vDiscountType;
			vResRow.DiscountDimension = vDiscountTypeObj.pmGetDefaultAccumulatingDiscountDimension();
			vResRow.Resource = 0;
			vResRow.Bonus = 0;
		Else
			For Each vAccDis In vAccDisRes Do
				vResRow = vRes.Add();
				vResRow.DiscountType = vAccDis.DiscountType;
				vResRow.DiscountDimension = vAccDis.DiscountDimension;
				vResRow.Resource = vAccDis.Resource;
				vResRow.Bonus = vAccDis.Bonus;
			EndDo;
		EndIf;
	EndDo;
	// Return
	Return vRes;
EndFunction // pmGetAccumulatingDiscountResources

// -----------------------------------------------------------------------------
Procedure pmCalculateAccumulationDiscount() Export
	vAccDiscounts = ParentDoc.GetObject().pmGetAccumulatingDiscountResources();
	If vAccDiscounts.Count() > 0 Then
		vAccDiscountsRow = vAccDiscounts.Get(0);
		vDiscountType = vAccDiscountsRow.DiscountType;
		If Not ValueIsFilled(vDiscountType) Then
			Return;
		EndIf;
		vAccountingDate = BegOfDay(Date);
		If BegOfDay(vAccountingDate) < vDiscountType.DateValidFrom Or
		   (vAccountingDate > vDiscountType.DateValidTo And ValueIsFilled(vDiscountType.DateValidTo)) Then
			Return;
		EndIf;
		vDiscountDimension = vAccDiscountsRow.DiscountDimension;
		If cmIsServiceInServiceGroup(Service, DiscountServiceGroup) And 
		  (Not vDiscountType.IsForRackRatesOnly Or 
		   vDiscountType.IsForRackRatesOnly And ValueIsFilled(RoomRate) And RoomRate.IsRackRate Or
		   IsAdditional Or
		   IsManual) Then
			vDiscountTypeObj = vDiscountType.GetObject();
			vResource = vAccDiscountsRow.Resource;
			vDiscountConfirmationText = "";
			vDiscount = vDiscountTypeObj.pmGetAccumulatingDiscount(Service, vAccountingDate, 
																   vResource, 
																   vDiscountConfirmationText);
			If vDiscount <> 0 Then
				DiscountType = vDiscountType;
				Discount = vDiscount;
				DiscountConfirmationText = vDiscountConfirmationText;
			EndIf;

			vWeekDays = vDiscountType.WeekDays;
			If Not IsBlankString(vWeekDays) Then
				If StrFind(vWeekDays, String(WeekDay(vAccountingDate))) = 0 Then
					Discount = 0;
				EndIf;
			EndIf;
		EndIf;
	EndIf;						
EndProcedure // pmCalculateAccumulationDiscount

// -----------------------------------------------------------------------------
Procedure pmSetDiscounts() Export
	// Check if manual discount is choosen
	If ValueIsFilled(DiscountType) And DiscountType.IsManualDiscount Then
		vDiscount = DiscountType.GetObject().pmGetDiscount(?(ValueIsFilled(ServiceDate), ServiceDate, Date), Service, Hotel);
		If vDiscount > Discount Then 
			Discount = vDiscount;
		EndIf;
		If DiscountType.IsForIndividualsOnly Then
			If ValueIsFilled(Folio) And ValueIsFilled(Folio.Customer) And Not Folio.Customer.IsIndividual Or ValueIsFilled(Folio.Agent) Then
				DiscountType = Catalogs.DiscountTypes.EmptyRef();
				DiscountConfirmationText = "";
				DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
				Discount = 0;
			EndIf;
		EndIf;
		Return;
	ElsIf Not ValueIsFilled(DiscountType) And Discount <> 0 Then
		Return;
	EndIf;
	// Get number of persons
	vNumberOfPersons = 1;
	If ValueIsFilled(ParentDoc) And 
	   (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or 
		TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or 
		TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation")) Then
		vNumberOfPersons = ParentDoc.NumberOfPersons;
	EndIf;
	// Initialize discounts
	DiscountType = Catalogs.DiscountTypes.EmptyRef();
	DiscountConfirmationText = "";
	DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
	Discount = 0;
	If ValueIsFilled(DiscountCard) Then
		If ValueIsFilled(DiscountCard.DiscountType) Then
			vDiscountType = DiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(?(ValueIsFilled(ServiceDate), ServiceDate, Date), Service, Hotel);
			If vDiscount > Discount Or (vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned) Then 
				DiscountType = vDiscountType;
				DiscountConfirmationText = DiscountCard.Metadata().Synonym + " " + TrimAll(DiscountCard.Description);
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				Discount = vDiscount;
				If ValueIsFilled(DiscountCard.ClientType) Then
					ClientType = DiscountCard.ClientType;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(ClientType) Then
		If ValueIsFilled(ClientType.DiscountType) Then
			vDiscountType = ClientType.DiscountType;
			vDiscount = ClientType.DiscountType.GetObject().pmGetDiscount(?(ValueIsFilled(ServiceDate), ServiceDate, Date), Service, Hotel);
			If vDiscount > Discount Or (vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned) Then 
				DiscountType = ClientType.DiscountType;
				If IsBlankString(ClientTypeConfirmationText) Then
					DiscountConfirmationText = NStr("en='Client type discount';ru='По типу клиента';de='Nach Kundentyp'");
				Else
					DiscountConfirmationText = ClientTypeConfirmationText;
				EndIf;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				vDiscountTypeObj = DiscountType.GetObject();
				Discount = vDiscount;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(ParentDoc) Then
		If ValueIsFilled(ParentDoc.DiscountType) Then
			vDiscountType = ParentDoc.DiscountType;
			If vDiscountType.IsAccumulatingDiscount Then
				DiscountType = vDiscountType;
				DiscountConfirmationText = TrimAll(ParentDoc.DiscountConfirmationText);
				DiscountServiceGroup = ParentDoc.DiscountServiceGroup;
				pmCalculateAccumulationDiscount();
			Else
				vDiscount = vDiscountType.GetObject().pmGetDiscount(?(ValueIsFilled(ServiceDate), ServiceDate, Date), Service, Hotel);
				If vDiscount > Discount Or (vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned) Then 
					DiscountType = vDiscountType;
					DiscountConfirmationText = TrimAll(ParentDoc.DiscountConfirmationText);
					DiscountServiceGroup = ParentDoc.DiscountServiceGroup;
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	ElsIf ValueIsFilled(Folio) And ValueIsFilled(Folio.Client) Then
		If ValueIsFilled(Folio.Client.DiscountType) Then
			vDiscountType = Folio.Client.DiscountType;
			If vDiscountType.IsAccumulatingDiscount Then
				DiscountType = vDiscountType;
				DiscountConfirmationText = "";
				DiscountServiceGroup = vDiscountType.DiscountServiceGroup;
				pmCalculateAccumulationDiscount();
			Else
				vDiscount = vDiscountType.GetObject().pmGetDiscount(?(ValueIsFilled(ServiceDate), ServiceDate, Date), Service, Hotel);
				If vDiscount > Discount Or (vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned) Then 
					DiscountType = vDiscountType;
					DiscountConfirmationText = "";
					DiscountServiceGroup = vDiscountType.DiscountServiceGroup;
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Accummulating discounts
	If ValueIsFilled(Service) Then
		vSkipAccumulatingDiscounts = False;
		If ValueIsFilled(DiscountType) And DiscountType.TurnOffAutomaticDiscounts Or 
		   ValueIsFilled(DiscountCard) And DiscountCard.TurnOffAutomaticDiscounts Or 
		   ValueIsFilled(ClientType) And ClientType.TurnOffAutomaticDiscounts Or 
		   ValueIsFilled(MarketingCode) And MarketingCode.TurnOffAutomaticDiscounts Then
			vSkipAccumulatingDiscounts = True;
		EndIf;
		If Not vSkipAccumulatingDiscounts Then
			vCurDiscount = 0;
			vCurDiscountType = Catalogs.DiscountTypes.EmptyRef();
			vCurDiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
			vCurDiscountConfirmationText = "";
			// Check accumulating discounts
			vCheckAccDiscounts = True;
			If ValueIsFilled(ParentDoc) And 
			   (TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or 
			    TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or
			    TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
			   ParentDoc.TurnOffAutomaticDiscounts Then
				vCheckAccDiscounts = False;
			EndIf;
			If ValueIsFilled(ClientType) Then
				If ClientType.TurnOffAutomaticDiscounts Then
					vCheckAccDiscounts = False;
				EndIf;
			EndIf;
			If ValueIsFilled(DiscountType) Then
				If DiscountType.TurnOffAutomaticDiscounts Then
					vCheckAccDiscounts = False;
				EndIf;
			EndIf;
			If vCheckAccDiscounts Then
				// Read all configured accumulating discount types
				vAccDiscounts = pmGetAccumulatingDiscountResources();
				// Check all accumulation discounts
				For Each vAccDiscount In vAccDiscounts Do
					vDiscountType = vAccDiscount.DiscountType;
					vDiscountDimension = vAccDiscount.DiscountDimension;
					vDiscountServiceGroup = vDiscountType.DiscountServiceGroup;
					If cmIsServiceInServiceGroup(Service, vDiscountServiceGroup) And 
					  (Not vDiscountType.IsForRackRatesOnly Or 
					   vDiscountType.IsForRackRatesOnly And ValueIsFilled(RoomRate) And RoomRate.IsRackRate Or 
					   IsAdditional Or
					   IsManual) Then
						vDiscountTypeObj = vDiscountType.GetObject();
						
						// Check that this discount type fits to the service folio
						vSrvDiscountDimension = Undefined;
						vSrvResource = vDiscountTypeObj.pmCalculateResource(ThisObject, vNumberOfPersons, Folio, DiscountCard, vSrvDiscountDimension);
						If TypeOf(vSrvDiscountDimension) = TypeOf(vDiscountDimension) Then
							// Retrieve discount percent valid for current discount resource										
							vResource = vAccDiscount.Resource;
							vDiscountConfirmationText = "";
							vDiscount = vDiscountTypeObj.pmGetAccumulatingDiscount(Service, Date, 
																				   vResource, 
																				   vDiscountConfirmationText);
							If vDiscount <> 0 Then
								If cmFirstDiscountIsGreater(vDiscount, vCurDiscount) Then
									vCurDiscount = vDiscount;
									vCurDiscountType = vDiscountType;
									vCurDiscountServiceGroup = vDiscountServiceGroup;
									vCurDiscountConfirmationText = vDiscountConfirmationText;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				// Apply accumulating discount
				If vCurDiscount <> 0 Then 
					If cmIsServiceInServiceGroup(Service, vCurDiscountServiceGroup) Then
						If vCurDiscount > Discount Then
							Discount = vCurDiscount;
							DiscountType = vCurDiscountType;
							DiscountServiceGroup = vCurDiscountServiceGroup;
							DiscountConfirmationText = vCurDiscountConfirmationText;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(DiscountType) Then
		If DiscountType.IsForIndividualsOnly Then
			If ValueIsFilled(Folio) And ValueIsFilled(Folio.Customer) And Not Folio.Customer.IsIndividual Or ValueIsFilled(Folio.Agent) Then
				DiscountType = Catalogs.DiscountTypes.EmptyRef();
				DiscountConfirmationText = "";
				DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
				Discount = 0;
			EndIf;
		EndIf;
		vWeekDays = DiscountType.WeekDays;
		If Not IsBlankString(vWeekDays) Then
			If StrFind(vWeekDays, String(WeekDay(?(ValueIsFilled(ServiceDate), ServiceDate, Date)))) = 0 Then
				Discount = 0;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmSetDiscounts

// -----------------------------------------------------------------------------
Procedure pmRecalculateAmounts() Export
	If ValueIsFilled(Service) Then
		If Service.RecalculatePriceWhenSumChanged And Not IsSplit Then
			If Quantity = 0 And Sum > 0 Then
				Quantity = 1;
			EndIf;
			Price = ?(Quantity = 0, 0, Round(Sum / Quantity, 2));
		Else
			Quantity = ?(Price = 0, 1, Round(Sum / Price, 7));
		EndIf;
	Else
		Quantity = ?(Price = 0, 1, Round(Sum / Price, 7));
	EndIf;
	VATSum = cmCalculateVATSum(VATRate, Sum, Date);
	// Discount
	DiscountSum = 0;
	VATDiscountSum = 0;
	If ValueIsFilled(Service) Then
		If cmIsServiceInServiceGroup(Service, DiscountServiceGroup) Then
			If Not ValueIsFilled(DiscountType) Then
				DiscountSum = Round(Sum * Discount / 100, 2);
				VATDiscountSum = cmCalculateVATSum(VATRate, DiscountSum, Date);
			Else 
				If Not DiscountType.IsForRackRatesOnly Or 
				   DiscountType.IsForRackRatesOnly And ValueIsFilled(RoomRate) And RoomRate.IsRackRate Or
				   IsAdditional Or
				   IsManual Then
					If Not DiscountType.IsAmountDiscount Then
						DiscountSum = Round(Sum * Discount / 100, 2);
						VATDiscountSum = cmCalculateVATSum(VATRate, DiscountSum, Date);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Commission
	CommissionSum = 0;
	VATCommissionSum = 0;
	If ValueIsFilled(Service) Then
		If cmIsServiceInServiceGroup(Service, AgentCommissionServiceGroup) Then
			pmCommissionCalculationProcedure();
		EndIf;
	EndIf;
EndProcedure // pmRecalculateAmounts

// -----------------------------------------------------------------------------
Procedure pmFillRoomInventoryStatistics() Export
	// Room sales resources
	RoomsRented = 0;
	BedsRented = 0;
	AdditionalBedsRented = 0;
	GuestDays = 0;
	GuestsCheckedIn = 0;
	If IsRoomRevenue And Not IsSplit And ValueIsFilled(Service) And Not RoomRevenueAmountsOnly Then
		vCurPeriodInHours = 24;
		If ValueIsFilled(Service.QuantityCalculationRule) Then
			If Service.QuantityCalculationRule.PeriodInHours <> 0 Then
				vCurPeriodInHours = Service.QuantityCalculationRule.PeriodInHours;
			EndIf;
		ElsIf ValueIsFilled(RoomRate) And RoomRate.PeriodInHours <> 0 Then
			vCurPeriodInHours = RoomRate.PeriodInHours;
		EndIf;
		If vCurPeriodInHours <> 0 Then
			vRoomQuantity = 1;
			If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
				vRoomQuantity = ParentDoc.RoomQuantity;
			EndIf;
			vAccommodationTemplate = AccommodationTemplate;
			If ValueIsFilled(vAccommodationTemplate) And NumberOfAdults = 0 And NumberOfTeenagers = 0 And NumberOfChildren = 0 And NumberOfInfants = 0 Then
				NumberOfAdults = vAccommodationTemplate.NumberOfAdults;
				NumberOfTeenagers = vAccommodationTemplate.NumberOfTeenagers;
				NumberOfChildren = vAccommodationTemplate.NumberOfChildren;
				NumberOfInfants = vAccommodationTemplate.NumberOfInfants; 
			EndIf;
			vNumberOfAdults = NumberOfAdults;
			vNumberOfTeenagers = NumberOfTeenagers;
			vNumberOfChildren = NumberOfChildren;
			vNumberOfInfants = NumberOfInfants;
			vNumberOfBedsPerRoom = 0;
			If ValueIsFilled(RoomType) Then
				vNumberOfBedsPerRoom = RoomType.NumberOfBedsPerRoom;
			EndIf;
			vCheckInDate = '00010101';
			If Not ValueIsFilled(vAccommodationTemplate) And ValueIsFilled(ParentDoc) And 
			  (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation")) Then
				vAccommodationTemplate = ParentDoc.AccommodationTemplate;
				vNumberOfAdults = ParentDoc.NumberOfAdults;
				vNumberOfTeenagers = ParentDoc.NumberOfTeenagers;
				vNumberOfChildren = ParentDoc.NumberOfChildren;
				vNumberOfInfants = ParentDoc.NumberOfInfants;
				vCheckInDate = ParentDoc.CheckInDate;
				vNumberOfBedsPerRoom = ParentDoc.NumberOfBedsPerRoom;
			EndIf;
			If ValueIsFilled(vAccommodationTemplate) And (vNumberOfAdults <> 0 Or vNumberOfTeenagers <> 0 Or vNumberOfChildren <> 0 Or vNumberOfInfants <> 0) Then
				For Each vRow In vAccommodationTemplate.AccommodationTypes Do
					If ValueIsFilled(vRow.AccommodationType) Then
						If vRow.AccommodationType.Type = Enums.AccomodationTypes.Room Then
							RoomsRented = RoomsRented + Round(vRow.AccommodationType.NumberOfRooms*Quantity*vCurPeriodInHours/24, 7);
							BedsRented = BedsRented + Round(vRow.AccommodationType.NumberOfRooms*vNumberOfBedsPerRoom*Quantity*vCurPeriodInHours/24, 7);
						ElsIf vRow.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
							RoomsRented = RoomsRented + ?(vNumberOfBedsPerRoom = 0, 0, Round(vRow.AccommodationType.NumberOfBeds/vNumberOfBedsPerRoom*Quantity*vCurPeriodInHours/24, 7));
							BedsRented = BedsRented + Round(vRow.AccommodationType.NumberOfBeds*Quantity*vCurPeriodInHours/24, 7);
						ElsIf vRow.AccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Then
							AdditionalBedsRented = AdditionalBedsRented + Round(vRow.AccommodationType.NumberOfAdditionalBeds*Quantity*vCurPeriodInHours/24, 7);
						EndIf;
					EndIf;
				EndDo;
				GuestDays = Round((vNumberOfAdults + vNumberOfTeenagers + vNumberOfChildren + vNumberOfInfants)*Quantity*vCurPeriodInHours/24/vRoomQuantity, 7);
				If ValueIsFilled(vCheckInDate) And BegOfDay(vCheckInDate) = BegOfDay(?(ValueIsFilled(ServiceDate), ServiceDate, Date)) Then
					GuestsCheckedIn = Round((vNumberOfAdults + vNumberOfTeenagers + vNumberOfChildren + vNumberOfInfants)*Quantity/vRoomQuantity, 0);
				EndIf;
			ElsIf ValueIsFilled(ParentDoc) And 
			     (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation")) Then
				RoomsRented = ?(vNumberOfBedsPerRoom = 0, 0, Round(ParentDoc.NumberOfBeds/vNumberOfBedsPerRoom*Quantity*vCurPeriodInHours/24/vRoomQuantity, 7));
				BedsRented = Round(ParentDoc.NumberOfBeds*Quantity*vCurPeriodInHours/24/vRoomQuantity, 7);
				AdditionalBedsRented = Round(ParentDoc.NumberOfAdditionalBeds*Quantity*vCurPeriodInHours/24/vRoomQuantity, 7);
				GuestDays = Round(ParentDoc.NumberOfPersons*Quantity*vCurPeriodInHours/24/vRoomQuantity, 7);
				If BegOfDay(ParentDoc.CheckInDate) = BegOfDay(?(ValueIsFilled(ServiceDate), ServiceDate, Date)) Then
					GuestsCheckedIn = Round(ParentDoc.NumberOfPersons*Quantity/vRoomQuantity, 0);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillRoomInventoryStatistics

// -----------------------------------------------------------------------------
Procedure pmPostResourceReservation(pDateFrom, pDateTill) Export
	If Not IsAdditional Or IsManual Then
		Return;
	EndIf;
	// Create/update resource reservation document
	vDocObj = Undefined;
	If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
		vDocObj = ParentDoc.GetObject();
	Else
		vDocObj = Documents.ResourceReservation.CreateDocument();
		vDocObj.pmFillAuthorAndDate();
	EndIf;
	vDocObj.ChargingFolio = Folio;
	vDocObj.FolioCurrency = FolioCurrency;
	vDocObj.FolioCurrencyExchangeRate = FolioCurrencyExchangeRate;
	vDocObj.ReportingCurrency = ReportingCurrency;
	vDocObj.ReportingCurrencyExchangeRate = ReportingCurrencyExchangeRate;
	vDocObj.Hotel = Hotel;
	If ValueIsFilled(Resource) Then
		vDocObj.ResourceType = Resource.Owner;
		vDocObj.Resource = Resource;
	Else
		vDocObj.ResourceType = Catalogs.ResourceTypes.EmptyRef();
		vDocObj.Resource = Catalogs.Resources.EmptyRef();
	EndIf;
	vDocObj.Company = Folio.Company;
	If Not ValueIsFilled(vDocObj.Company) Then
		vDocObj.Company = Company;
	EndIf;
	vDocObj.ExchangeRateDate = CurrentSessionDate();
	vDocObj.GuestGroup = GetEffectiveGuestGroup();
	If NOT ValueIsFilled(vDocObj.GuestGroup) Then
		vDocObj.pmCreateGuestGroup();
	EndIf;
	vDocObj.ClientType = ClientType;
	vDocObj.ClientTypeConfirmationText = ClientTypeConfirmationText;
	vDocObj.PlannedPaymentMethod = Folio.PaymentMethod;
	vDocObj.ResourceReservationStatus = Hotel.NewResourceReservationStatus;
	If ValueIsFilled(vDocObj.ResourceReservationStatus) Then
		vDocObj.DoCharging = vDocObj.ResourceReservationStatus.DoCharging;
	EndIf;
	vDocObj.DateTimeFrom = pDateFrom;
	vDocObj.DateTimeTo = pDateTill;
	vDocObj.Duration = vDocObj.pmCalculateDuration();
	If ValueIsFilled(Folio.Contract) Then
		vDocObj.Owner = Folio.Contract;
	ElsIf ValueIsFilled(Folio.Customer) Then
		vDocObj.Owner = Folio.Customer;
	ElsIf ValueIsFilled(vDocObj.Hotel) Then
		If ValueIsFilled(vDocObj.Hotel.IndividualsContract) Then
			vDocObj.Owner = vDocObj.Hotel.IndividualsContract;
		Else
			vDocObj.Owner = vDocObj.Hotel.IndividualsCustomer;
		EndIf;
	Else
		vDocObj.Owner = Undefined;
	EndIf;
	If ValueIsFilled(Folio.ParentDoc) Then
		vDocObj.Customer = Folio.ParentDoc.Customer;
		If ValueIsFilled(vDocObj.Customer) Then
			vDocObj.CustomerType = vDocObj.Customer.CustomerType;
		EndIf;
		vDocObj.Contract = Folio.ParentDoc.Contract;
	Else
		If ValueIsFilled(vDocObj.Owner) Then
			If ValueIsFilled(vDocObj.Hotel) And (vDocObj.Owner = vDocObj.Hotel.IndividualsCustomer Or vDocObj.Owner = vDocObj.Hotel.IndividualsContract) Then
				vDocObj.Customer = Catalogs.Customers.EmptyRef();
				vDocObj.Contract = Catalogs.Contracts.EmptyRef();
			Else
				If TypeOf(vDocObj.Owner) = Type("CatalogRef.Contracts") Then
					vDocObj.Customer = vDocObj.Owner.Owner;
					vDocObj.Contract = vDocObj.Owner;
				ElsIf TypeOf(vDocObj.Owner) = Type("CatalogRef.Customers") Then
					vDocObj.Customer = vDocObj.Owner;
					vDocObj.Contract = Catalogs.Contracts.EmptyRef();
				EndIf;
			EndIf;
		Else
			vDocObj.Customer = Catalogs.Customers.EmptyRef();
			vDocObj.Contract = Catalogs.Contracts.EmptyRef();
		EndIf;
	EndIf;
	vDocObj.Agent = Folio.Agent;
	If ValueIsFilled(vDocObj.Agent) Then
		vDocObj.AgentCommission = AgentCommission;
		vDocObj.AgentCommissionType = AgentCommissionType;
		vDocObj.AgentCommissionServiceGroup = AgentCommissionServiceGroup;
	Else
		vDocObj.AgentCommission = 0;
		vDocObj.AgentCommissionType = Undefined;
		vDocObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
	EndIf;
	vDocObj.Client = Folio.Client;
	If ValueIsFilled(Folio.Client) Then
		vDocObj.Phone = Folio.Client.Phone;
		vDocObj.Fax = Folio.Client.Fax;
		vDocObj.EMail = Folio.Client.EMail;
	EndIf;
	vDocObj.MarketingCode = MarketingCode;
	vDocObj.MarketingCodeConfirmationText = MarketingCodeConfirmationText;
	vDocObj.SourceOfBusiness = SourceOfBusiness;
	If ValueIsFilled(Folio.ParentDoc) Then
		vDocObj.NumberOfPersons = Folio.ParentDoc.NumberOfPersons;
		vDocObj.ContactPerson = TrimR(Folio.ParentDoc.ContactPerson);
		vDocObj.CreditCard = Folio.ParentDoc.CreditCard;
		vDocObj.Phone = Folio.ParentDoc.Phone;
		vDocObj.Fax = Folio.ParentDoc.Fax;
		vDocObj.EMail = Folio.ParentDoc.EMail;
	EndIf;
	If ValueIsFilled(vDocObj.Client) Then
		// Check if client has master charging rules
		vClientMasterFolio = Undefined;
		For Each vCRRow In vDocObj.Client.ChargingRules Do
			If ValueIsFilled(vCRRow.ChargingFolio) And vCRRow.ChargingFolio.IsMaster Then
				If vCRRow.ChargingFolio.Client = vDocObj.Client Then
					vClientMasterFolio = vCRRow.ChargingFolio;
					Break;
				EndIf;
			EndIf;
		EndDo;
		If ValueIsFilled(vClientMasterFolio) And vClientMasterFolio <> vDocObj.ChargingFolio Then
			vDocObj.ChargingFolio = vClientMasterFolio;
			vDocObj.FolioCurrency = vDocObj.ChargingFolio.FolioCurrency;
			vDocObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vDocObj.Hotel, vDocObj.ReportingCurrency, vDocObj.ExchangeRateDate);
		EndIf;
	EndIf;
	vDocObj.Remarks = TrimAll(Remarks);
	vDocObj.DoNotCalculateServices = True;
	vDocObj.DeletionMark = False;
	vDocObj.pmCalculateServices();
	vDocObj.Write(DocumentWriteMode.Posting);
	vDocObj.pmWriteToResourceReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	If ParentDoc <> vDocObj.Ref Then
		Read();
		ParentDoc = vDocObj.Ref;
		Write(DocumentWriteMode.Write);
	EndIf;
EndProcedure // pmPostResourceReservation

// -----------------------------------------------------------------------------
Procedure pmCommissionCalculationProcedure() Export
	If AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
		CommissionSum = Round((Sum - DiscountSum) * AgentCommission/100, 2);
		VATCommissionSum = cmCalculateVATSum(VATRate, CommissionSum, Date);
	ElsIf AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
		If ValueIsFilled(ParentDoc) Then
			If (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation")) And 
			   BegOfDay(ParentDoc.CheckInDate) = BegOfDay(?(ValueIsFilled(ServiceDate), ServiceDate, Date)) Then
				CommissionSum = Round((Sum - DiscountSum) * AgentCommission/100, 2);
				VATCommissionSum = cmCalculateVATSum(VATRate, CommissionSum, Date);
			ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") And BegOfDay(ParentDoc.DateTimeFrom) = BegOfDay(?(ValueIsFilled(ServiceDate), ServiceDate, Date)) Then
				CommissionSum = Round((Sum - DiscountSum) * AgentCommission/100, 2);
				VATCommissionSum = cmCalculateVATSum(VATRate, CommissionSum, Date);
			EndIf;
		EndIf;
	ElsIf AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom Then
		If (IsRoomRevenue And IsInPrice Or IsResourceRevenue) And Not IsSplit Then
			vAgentCurrency = ReportingCurrency;
			If ValueIsFilled(ParentDoc.Contract) And ValueIsFilled(ParentDoc.Contract.AgentCommissionType) Then
				vAgentCurrency = ParentDoc.Contract.AccountingCurrency;
			ElsIf ValueIsFilled(ParentDoc.Agent) Then
				vAgentCurrency = ParentDoc.Agent.AccountingCurrency;
			EndIf;
			If (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation")) And 
			   ValueIsFilled(ParentDoc.AccommodationType) And (ParentDoc.AccommodationType.Type = Enums.AccomodationTypes.Room Or ParentDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
				CommissionSum = Round(cmConvertCurrencies(AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				VATCommissionSum = cmCalculateVATSum(VATRate, CommissionSum, Date);
			Else
				CommissionSum = Round(cmConvertCurrencies(AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				VATCommissionSum = cmCalculateVATSum(VATRate, CommissionSum, Date);
			EndIf;
		EndIf;
	ElsIf AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom Then
		If ValueIsFilled(ParentDoc) And (IsRoomRevenue And IsInPrice Or IsResourceRevenue) And Not IsSplit Then
			vAgentCurrency = ReportingCurrency;
			If ValueIsFilled(ParentDoc.Contract) And ValueIsFilled(ParentDoc.Contract.AgentCommissionType) Then
				vAgentCurrency = ParentDoc.Contract.AccountingCurrency;
			ElsIf ValueIsFilled(ParentDoc.Agent) Then
				vAgentCurrency = ParentDoc.Agent.AccountingCurrency;
			EndIf;
			If (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation")) And 
			   BegOfDay(ParentDoc.CheckInDate) = BegOfDay(?(ValueIsFilled(ServiceDate), ServiceDate, Date)) And 
			   ValueIsFilled(ParentDoc.AccommodationType) And (ParentDoc.AccommodationType.Type = Enums.AccomodationTypes.Room Or ParentDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
				CommissionSum = Round(cmConvertCurrencies(AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				VATCommissionSum = cmCalculateVATSum(VATRate, CommissionSum, Date);
			ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") And BegOfDay(ParentDoc.DateTimeFrom) = BegOfDay(Date) Then
				CommissionSum = Round(cmConvertCurrencies(AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				VATCommissionSum = cmCalculateVATSum(VATRate, CommissionSum, Date);
			EndIf;
		EndIf;
	ElsIf AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient Then
		If (IsRoomRevenue And IsInPrice Or IsResourceRevenue) And Not IsSplit Then
			vAgentCurrency = ReportingCurrency;
			If ValueIsFilled(ParentDoc.Contract) And ValueIsFilled(ParentDoc.Contract.AgentCommissionType) Then
				vAgentCurrency = ParentDoc.Contract.AccountingCurrency;
			ElsIf ValueIsFilled(ParentDoc.Agent) Then
				vAgentCurrency = ParentDoc.Agent.AccountingCurrency;
			EndIf;
			CommissionSum = Round(cmConvertCurrencies(AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
			VATCommissionSum = cmCalculateVATSum(VATRate, CommissionSum, Date);
		EndIf;
	ElsIf AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient Then
		If ValueIsFilled(ParentDoc) And (IsRoomRevenue And IsInPrice Or IsResourceRevenue) And Not IsSplit Then
			vAgentCurrency = ReportingCurrency;
			If ValueIsFilled(ParentDoc.Contract) And ValueIsFilled(ParentDoc.Contract.AgentCommissionType) Then
				vAgentCurrency = ParentDoc.Contract.AccountingCurrency;
			ElsIf ValueIsFilled(ParentDoc.Agent) Then
				vAgentCurrency = ParentDoc.Agent.AccountingCurrency;
			EndIf;
			If (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation")) And 
			   BegOfDay(ParentDoc.CheckInDate) = BegOfDay(?(ValueIsFilled(ServiceDate), ServiceDate, Date)) Then
				CommissionSum = Round(cmConvertCurrencies(AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				VATCommissionSum = cmCalculateVATSum(VATRate, CommissionSum, Date);
			ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") And BegOfDay(ParentDoc.DateTimeFrom) = BegOfDay(Date) Then
				CommissionSum = Round(cmConvertCurrencies(AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				VATCommissionSum = cmCalculateVATSum(VATRate, CommissionSum, Date);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CommissionCalculationProcedure

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// 1. Check should we clear hotel product from the charge
	If ValueIsFilled(HotelProduct) Then
		If ValueIsFilled(Service) And Not Service.IsHotelProductService Then
			HotelProduct = Catalogs.HotelProducts.EmptyRef();
			Write(DocumentWriteMode.Write);
		EndIf;
	EndIf;
	
	If ValueIsFilled(CorrectedCharge) And CorrectedCharge.StatisticsOnly Then
		StatisticsOnly = CorrectedCharge.StatisticsOnly;
	EndIf;
	
	If Not StatisticsOnly And Not Service.IsNotInvoiced Then
		// 2. Post to Accumulating discounts
		PostToAccumulatingDiscountResources();
		
		// 3. Post to Current accounts receivable
		PostToCurrentAccountsReceivable();
	EndIf;
	
	// Clear main registers
	RegisterRecords.Accounts.Clear();
	RegisterRecords.Sales.Clear();
	RegisterRecords.PostingsFO.Clear();
	RegisterRecords.HotelProductSales.Clear();
	
	// Check if this charge is by order
	vHasOrder = False;
	vOrderItems = Undefined;
	vOrderCurrency = Undefined;
	vPOSTicket = "";
	vOrderAmount = 0;
	vOrderItemsAmount = 0;
	vOrderIsComplimentary = False;
	vOrderIsDiscounted = False;
	If Not IsInPrice And Not IsCorrection Then
		AdditionalProperties.Property("OrderItems", vOrderItems);
		AdditionalProperties.Property("OrderCurrency", vOrderCurrency);
		If AdditionalProperties.Property("OrderRemarks") Then
			vPOSTicket = TrimAll(AdditionalProperties.OrderRemarks);
		EndIf;
		If AdditionalProperties.Property("OrderAmount") Then
			vOrderAmount = AdditionalProperties.OrderAmount;
		EndIf;
		If AdditionalProperties.Property("OrderItemsAmount") Then
			vOrderItemsAmount = AdditionalProperties.OrderItemsAmount;
		EndIf;
		If vOrderItems = Undefined Then
			vOrder = Orders.GetChargeOrder(Ref);
			If ValueIsFilled(vOrder) Then
				vHasOrder = True;
				vPOSTicket = TrimAll(vOrder.Remarks);
				vOrderCurrency = vOrder.Currency;
				vOrderItems = vOrder.Items.Unload();
				vOrderAmount = vOrder.Sum;
				vOrderItemsAmount = vOrderItems.Total("Sum");
			EndIf;
		Else
			vHasOrder = True;
		EndIf;
		If vHasOrder Then
			If vOrderAmount = 0 And vOrderItemsAmount <> 0 Then
				vOrderIsComplimentary = True;
			ElsIf vOrderAmount <> 0 And vOrderItemsAmount <> 0 And vOrderAmount <> vOrderItemsAmount Then
				vOrderIsDiscounted = True;
			ElsIf DiscountSum <> 0 Then
				vOrderIsDiscounted = True;
			EndIf;
			vOrderItems.FillValues(0, "Price, Quantity");
			vOrderItems.GroupBy("Service, Quantity, Price, MarkingCode, Item", "Sum");
			For Each vOrderItemsRow In vOrderItems Do
				If Not ValueIsFilled(vOrderItemsRow.Service) Then
					vOrderItemsRow.Service = Service;
				EndIf;
				vOrderItemsRow.Quantity = 1;
				vOrderItemsRow.Price = vOrderItemsRow.Sum;
			EndDo;
			// Fill order item VAT rates
			If vOrderItems.Columns.Find("VATRate") = Undefined Then
				vOrderItems.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
			EndIf;
			For Each vOrderItemsRow In vOrderItems Do
				vOrderItemsRow.VATRate = VATRate;
				If ValueIsFilled(vOrderItemsRow.Service) And vOrderItemsRow.Service <> Service Then
					If ValueIsFilled(Company) And ValueIsFilled(Company.VATRate) Then
						vOrderItemsRow.VATRate = Company.VATRate;
					EndIf;
					vOrderItemServiceAttrs = vOrderItemsRow.Service.GetObject().pmGetServicePrices(Hotel, Date, ClientType);
					If vOrderItemServiceAttrs <> Undefined And vOrderItemServiceAttrs.Count() > 0 Then
						vOrderItemServiceAttrsRow = vOrderItemServiceAttrs.Get(0);
						If ValueIsFilled(vOrderItemServiceAttrsRow.VATRate) Then
							vOrderItemsRow.VATRate = vOrderItemServiceAttrsRow.VATRate;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If vHasOrder Then
		// Post order items to sales and accounts
		PostOrderItemsToSalesAndAccounts(vOrderItems, vOrderCurrency);
		
		// Post order items to FO chart of accounts
		PostOrderItemsToFOChartOfAccounts(vOrderItems, vOrderCurrency, vPOSTicket, vOrderIsComplimentary, vOrderIsDiscounted);
		
		// Post to labeled goods
		PostToLabeledGoods(vOrderItems);
	Else
		// 4. Post to Accounts
		If IsInPrice And IsRoomRevenue And Not RoomRevenueAmountsOnly And Not IsSplit Then
			If RateSum <> 0 And IsMergedToRoomRevenue Then
				PostToAccounts(Service, Quantity, RateSum, RateDiscountSum, cmCalculateVATSum(VATRate, RateDiscountSum, Date), RateCommissionSum, cmCalculateVATSum(VATRate, RateCommissionSum, Date), cmCalculateVATSum(VATRate, RateSum, Date));
			Else
				PostToAccounts(Service, Quantity, Sum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, VATSum);
			EndIf;
		ElsIf Not (IsMergedToRoomRevenue And ValueIsFilled(RoomRevenueCharge)) Then
			PostToAccounts(Service, Quantity, Sum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, VATSum, , ?(Hotel.SplitFolioBalanceByServicesAndPrices, TrimR(MarkingCode), ""));
		EndIf;
		
		// 5. Fill analitics
		PostToAnaliticalRegisters(Service, Quantity, Sum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, VATSum, RateSum, RateDiscountSum);
		
		// 6. Post to FO chart of accounts
		If (ChargeCorrectionType = Enums.ChargeCorrectionTypes.Complimentary Or ChargeCorrectionType = Enums.ChargeCorrectionTypes.Discount) And Not Folio.IsComplimentary Then
			PostToFOChartOfAccounts(Service, Quantity, Sum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, VATSum);
		EndIf;
		PostToFOChartOfAccounts(Service, Quantity, Sum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, VATSum, , ValueIsFilled(ChargeCorrectionType), ?(ChargeCorrectionType = Enums.ChargeCorrectionTypes.Complimentary, True, Folio.IsComplimentary), ?(ChargeCorrectionType = Enums.ChargeCorrectionTypes.Discount, True, False));
		
		// Post to labeled goods
		PostToLabeledGoods();
	EndIf;
	
	// 7. If bound service is defined for the current one then we have to do
	// couple of movements where second one is correction for the bound service
	vBoundService = cmGetBoundService(Service);
	If vBoundService = Service Then
		vBoundService = Undefined;
	EndIf;
	If ValueIsFilled(vBoundService) And Not IsFixedCharge Then
		vBoundChargeObj = Undefined;
		If ValueIsFilled(BoundCharge) Then
			vBoundChargeObj = BoundCharge.GetObject();
			If BoundCharge.Posted Then
				vBoundChargeObj.Write(DocumentWriteMode.UndoPosting);
			EndIf;
		EndIf;
		// Check if bound service was charged at all
		vBoundServiceQuantity = 0;
		vBoundServiceTurnover = GetBoundServiceTurnover(vBoundService, vBoundServiceQuantity);
		If vBoundServiceTurnover > 0 And (Sum - DiscountSum) > 0 And Price <> 0 Then
			If Not ValueIsFilled(BoundCharge) Then
				vBoundChargeObj = Documents.Charge.CreateDocument();
			ElsIf BoundCharge.DeletionMark Then
				vBoundChargeObj.SetDeletionMark(False);
			EndIf;
			FillPropertyValues(vBoundChargeObj, ThisObject, , "Number, BoundCharge");
			vBoundChargeObj.Service = vBoundService;
			vBoundChargeObj.BoundCharge = Ref;
			vBoundChargeObj.IsFixedCharge = True;
			vCoeff = 1;
			vBoundChargeSum = Sum - DiscountSum;
			If (Sum - DiscountSum) > vBoundServiceTurnover Then
				vCoeff = -vBoundServiceTurnover/(Sum - DiscountSum);
				vBoundChargeSum = vBoundServiceTurnover;
			EndIf;
			If Quantity > vBoundServiceQuantity Then
				vBoundChargeObj.Quantity = -vBoundServiceQuantity;
			Else
				vBoundChargeObj.Quantity = -vBoundChargeObj.Quantity;
			EndIf;
			vBoundChargeObj.Sum = -vBoundChargeSum;
			If vBoundChargeObj.Quantity <> 0 Then
				vBoundChargeObj.Price = Round(vBoundChargeObj.Sum/vBoundChargeObj.Quantity, 2);
			Else
				vBoundChargeObj.Price = vBoundChargeSum;
			EndIf;
			vBoundChargeObj.VATSum = vCoeff * (vBoundChargeObj.VATSum - vBoundChargeObj.VATDiscountSum);
			vBoundChargeObj.Discount = 0;
			vBoundChargeObj.DiscountConfirmationText = "";
			vBoundChargeObj.DiscountType = Catalogs.DiscountTypes.EmptyRef();
			vBoundChargeObj.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
			vBoundChargeObj.DiscountCard = Catalogs.DiscountCards.EmptyRef();
			vBoundChargeObj.DiscountSum = 0;
			vBoundChargeObj.VATDiscountSum = 0;
			vBoundChargeObj.CommissionSum = vCoeff * vBoundChargeObj.CommissionSum;
			vBoundChargeObj.VATCommissionSum = vCoeff * vBoundChargeObj.VATCommissionSum;
			vBoundChargeObj.RoomsRented = 0;
			vBoundChargeObj.BedsRented = 0;
			vBoundChargeObj.AdditionalBedsRented = 0;
			vBoundChargeObj.GuestDays = 0;
			vBoundChargeObj.GuestsCheckedIn = 0;
			vBoundChargeObj.StatisticsOnly = StatisticsOnly;
			vBoundChargeObj.Write(DocumentWriteMode.Posting);
			// Fill reference
			BoundCharge = vBoundChargeObj.Ref;
			IsFixedCharge = False;
			Write(DocumentWriteMode.Write);
		Else
			If ValueIsFilled(BoundCharge) And Not BoundCharge.DeletionMark Then
				vBoundChargeObj.SetDeletionMark(True);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Folio") Then
			pmFillByFolio(pBase);
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en = 'Document.DataValidation'; de = 'Document.DataValidation'; ru = 'Документ.КонтрольДанных'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
		If Not ValueIsFilled(ServiceDate) Then
			ServiceDate = BegOfDay(Date);
		EndIf;
		If Sum < 0 Then
			If Not IsCorrection Then
				IsCorrection = True;
			EndIf;
			If Not ValueIsFilled(BoundCharge) Then
				// User activity history   
				vEventDescription = StrTemplate(NStr("en = 'Charge with a negative amount: %1 from %2, %3'; 
													 |de = 'Abrechnung mit negativem Betrag: %1 from %2, %3'; 
													 |ru = 'Начисление с отрицательной суммой: %1 от %2, %3'"), TrimAll(Service), ServiceDate, cmFormatSum(Sum, FolioCurrency));    
				AddUserLog(vEventDescription);
			EndIf;   
		Else
			If IsNew() And IsAdditional Then    
				vEventDescription = StrTemplate(NStr("en = 'Manual charge: %1 from %2, %3'; 
													 |de = 'Manuelle Abgrenzung: %1 from %2, %3'; 
													 |ru = 'Ручное начисление: %1 от %2, %3'"), TrimAll(Service), ServiceDate, cmFormatSum(Sum, FolioCurrency)); 
				AddUserLog(vEventDescription);
			EndIf;	
		EndIf;
		If IsCorrection And Not ValueIsFilled(CorrectionDate) Then
			CorrectionDate = BegOfDay(Date);
		EndIf;
	Else
		// Check if this charge is closed by settlement
		If Posted And ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And 
		   pWriteMode = DocumentWriteMode.UndoPosting And 
		  (Sum <> 0 Or Quantity <> 0) And IsAdditional And 
		   ValueIsFilled(Folio) And Folio.IsClosed Then
			vChargeBalanceIsZero = False;
			vChargeBalancesRow = cmGetChargeCurrentAccountsReceivableBalance(Ref);
			If vChargeBalancesRow <> Undefined Then
				If vChargeBalancesRow.SumBalance = 0 And vChargeBalancesRow.QuantityBalance = 0 Then
					vChargeBalanceIsZero = True;
				EndIf;
			Else
				vChargeBalanceIsZero = True;
			EndIf;
			If vChargeBalanceIsZero Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This charge is closed by settlement! Charge is read only.';
				             |ru='Начисление уже закрыто актом об оказании услуг! Редактирование такого начисления запрещено.';
							 |de='Die Anrechnung wurde bereits über ein Übergabeprotokoll über die Erbringung von Dienstleistungen geschlossen! Die Bearbeitung einer solchen Anrechnung ist verboten.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
	EndIf;
	// Check if this charge is in closed day
	vSkipCheck = False;
	// StatisticsOnly - if it's a loading of past transactions from other DB we have to load it without opening the closed dates
	If AdditionalProperties.Property("ChargeSplitMode") And AdditionalProperties.ChargeSplitMode Or StatisticsOnly Then
		vSkipCheck = True;
	EndIf;
	If Not vSkipCheck And ValueIsFilled(Hotel) And Hotel.DoNotEditClosedDateDocs And 
	  (pWriteMode = DocumentWriteMode.Posting Or pWriteMode = DocumentWriteMode.UndoPosting) Then
		If Not ValueIsFilled(Ref) Or Ref.Sum <> Sum Or Ref.VATSum <> VATSum Or 
		   Ref.DiscountSum <> DiscountSum Or Ref.VATDiscountSum <> VATDiscountSum Or 
		   Ref.CommissionSum <> CommissionSum Or Ref.VATCommissionSum <> VATCommissionSum Then
			vChargeIsInClosedDay = cmIfChargeIsInClosedDay(ThisObject);
			If Not vChargeIsInClosedDay And ValueIsFilled(RoomRevenueCharge) Then
				vChargeIsInClosedDay = cmIfChargeIsInClosedDay(RoomRevenueCharge);
			EndIf;
			// Allow vaucher, some analitical attributes and commission update if it was changed after day was closed
			vNewGuestGroup = Undefined;
			If AdditionalProperties.Property("NewGuestGroup") Then
				vNewGuestGroup = AdditionalProperties.NewGuestGroup;
			EndIf;
			vOldGuestGroup = Undefined;
			If AdditionalProperties.Property("OldGuestGroup") Then
				vOldGuestGroup = AdditionalProperties.OldGuestGroup;
			EndIf;
			vNewClient = Undefined;
			If AdditionalProperties.Property("NewClient") Then
				vNewClient = AdditionalProperties.NewClient;
			EndIf;
			vOldClient = Undefined;
			If AdditionalProperties.Property("OldClient") Then
				vOldClient = AdditionalProperties.OldClient;
			EndIf;
			vNewClientAge = 0;
			If AdditionalProperties.Property("NewClientAge") Then
				vNewClientAge = AdditionalProperties.NewClientAge;
			EndIf;
			vOldClientAge = 0;
			If AdditionalProperties.Property("OldClientAge") Then
				vOldClientAge = AdditionalProperties.OldClientAge;
			EndIf;
			vNewTouristicTaxExemptionReason = Undefined;
			If AdditionalProperties.Property("NewTouristicTaxExemptionReason") Then
				vNewTouristicTaxExemptionReason = AdditionalProperties.NewTouristicTaxExemptionReason;
			EndIf;
			vOldTouristicTaxExemptionReason = Undefined;
			If AdditionalProperties.Property("OldTouristicTaxExemptionReason") Then
				vOldTouristicTaxExemptionReason = AdditionalProperties.OldTouristicTaxExemptionReason;
			EndIf;
			vNewTouristicTaxExemptionReasonFillDate = Undefined;
			If AdditionalProperties.Property("NewTouristicTaxExemptionReasonFillDate") Then
				vNewTouristicTaxExemptionReasonFillDate = AdditionalProperties.NewTouristicTaxExemptionReasonFillDate;
			EndIf;
			vOldTouristicTaxExemptionReasonFillDate = Undefined;
			If AdditionalProperties.Property("OldTouristicTaxExemptionReasonFillDate") Then
				vOldTouristicTaxExemptionReasonFillDate = AdditionalProperties.OldTouristicTaxExemptionReasonFillDate;
			EndIf;
			If vChargeIsInClosedDay And ValueIsFilled(Ref) And 
			  (HotelProduct <> Ref.HotelProduct Or 
			   SourceOfBusiness <> Ref.SourceOfBusiness Or
			   MarketingCode <> Ref.MarketingCode Or
			   ClientType <> Ref.ClientType Or
			   BoardPlace <> Ref.BoardPlace Or
			   AgentCommissionType <> Ref.AgentCommissionType Or
			   AgentCommission <> Ref.AgentCommission Or
			   CommissionSum <> Ref.CommissionSum Or
			   vOldGuestGroup <> vNewGuestGroup Or 
			   vOldClient <> vNewClient Or
			   vOldClientAge <> vNewClientAge Or
			   vOldTouristicTaxExemptionReason <> vNewTouristicTaxExemptionReason Or
			   vOldTouristicTaxExemptionReasonFillDate <> vNewTouristicTaxExemptionReasonFillDate) Then
				// Restore all attributes except allowed to be changed ones
				If Ref.Sum = Sum And Ref.VATSum = VATSum And Ref.DiscountSum = DiscountSum Then
					FillPropertyValues(ThisObject, Ref, , "HotelProduct, SourceOfBusiness, MarketingCode, ClientType, ClientTypeConfirmationText, BoardPlace, AgentCommissionType, AgentCommission, CommissionSum");
				Else
					FillPropertyValues(ThisObject, Ref, , "HotelProduct, SourceOfBusiness, MarketingCode, ClientType, ClientTypeConfirmationText, BoardPlace");
				EndIf;
				// Reset cancel operation flag
				vChargeIsInClosedDay = False;
			EndIf;
			If vChargeIsInClosedDay Then
				pCancel = True;
				If IsNew() Then
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Charge date is closed! You can not post charge on this day.';
					             |ru='День закрыт! Нельзя провести начисление этой датой.';
								 |de='Der Tag ist geschlossen! Eine Anrechnung zu diesem Datum ist nicht möglich.'"), MessageStatus.Attention);
				Else
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='This charge is in closed day! Charge is read only.';
					             |ru='Начисление в закрытом дне! Редактирование такого начисления запрещено.';
								 |de='Anrechnung am geschlossenen Tag! Die Bearbeitung einer solchen Abrechnung ist verboten.'"), MessageStatus.Attention);
				EndIf;
				Return;
			EndIf;
		EndIf;
	EndIf;
	// Delete bound room service document if this charge is marked for deletion
	If DeletionMark And ValueIsFilled(ParentRoomService) And Not ParentRoomService.DeletionMark And Not IsFixedCharge Then
		vParentRoomServiceObj = ParentRoomService.GetObject();
		vParentRoomServiceObj.AdditionalProperties.Insert("NoPostprocessing", True);
		If ParentRoomService.Posted Then
			vParentRoomServiceObj.Write(DocumentWriteMode.UndoPosting);
		EndIf;
		vParentRoomServiceObj.SetDeletionMark(True);
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If DeletionMark Then
		Try
			// Delete bound charge
			If ValueIsFilled(BoundCharge) And Not IsFixedCharge Then
				vRepostCharges = False;
				vBoundChargeObj = BoundCharge.GetObject();
				If BoundCharge.Posted Then
					vBoundChargeObj.Write(DocumentWriteMode.UndoPosting);
					vRepostCharges = True;
				EndIf;
				If Not vBoundChargeObj.DeletionMark Then
					vBoundChargeObj.SetDeletionMark(True);
					vRepostCharges = True;
				EndIf;
				// Repost all other charges
				If vRepostCharges Then
					vFolioObj = Folio.GetObject();
					vFolioObj.pmRepostAdditionalCharges(Ref);
				EndIf;
			EndIf;
			// Delete bound storno
			If IsAdditional Then
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	Storno.Ref
				|FROM
				|	Document.Storno AS Storno
				|WHERE
				|	Storno.Posted
				|	AND Storno.ParentCharge = &qCharge";
				vQry.SetParameter("qCharge", Ref);
				vStornos = vQry.Execute().Unload();
				For Each vStornosRow In vStornos Do
					vStornoObj = vStornosRow.Ref.GetObject();
					vStornoObj.SetDeletionMark(True);
				EndDo;
			EndIf;
			// Delete bound resource reservation document
			If IsAdditional And ValueIsFilled(Service) And ValueIsFilled(Service.Resource) And 
			   ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") And 
			   Not ParentDoc.DoCharging And ParentDoc.Posted Then
				ParentDoc.GetObject().SetDeletionMark(True);
			EndIf;
			// Delete connected room rate price documents
			If IsInPrice And IsRoomRevenue And Not IsSplit And Not RoomRevenueAmountsOnly And IsMergedToRoomRevenue Then
				vConnectedDocs = cmGetRoomRateTransactions(Ref);
				For Each vConnectedDocsRow In vConnectedDocs Do
					If vConnectedDocsRow.Ref <> Ref Then
						If Not vConnectedDocsRow.Ref.DeletionMark Then
							vConnectedDocsRow.Ref.GetObject().SetDeletionMark(True);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		Except
		EndTry;
	Else
		// Unpost bound charge
		If ValueIsFilled(BoundCharge) And Not IsFixedCharge Then
			vRepostCharges = False;
			vBoundChargeObj = BoundCharge.GetObject();
			If Not Posted Then 
				If BoundCharge.Posted Then
					vBoundChargeObj.Write(DocumentWriteMode.UndoPosting);
					vRepostCharges = True;
				EndIf;
			EndIf;
			// Repost all other charges
			If vRepostCharges Then
				vFolioObj = Folio.GetObject();
				vFolioObj.pmRepostAdditionalCharges(Ref);
			EndIf;
		EndIf;
	EndIf;    
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Write log event
	If Posted Then
		// Check if this charge is closed by settlement
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And 
		  (Sum <> 0 Or Quantity <> 0) And 
		   ValueIsFilled(Folio) And Folio.IsClosed Then
			vChargeBalanceIsZero = False;
			vChargeBalancesRow = cmGetChargeCurrentAccountsReceivableBalance(Ref);
			If vChargeBalancesRow <> Undefined Then
				If vChargeBalancesRow.SumBalance = 0 And vChargeBalancesRow.QuantityBalance = 0 Then
					vChargeBalanceIsZero = True;
				EndIf;
			Else
				vChargeBalanceIsZero = True;
			EndIf;
			If vChargeBalanceIsZero Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This charge is closed by settlement! Charge is read only.';
				             |ru='Начисление уже закрыто актом об оказании услуг! Редактирование такого начисления запрещено.';
							 |de='Die Anrechnung wurde bereits über ein Übergabeprotokoll über die Erbringung von Dienstleistungen geschlossen! Die Bearbeitung einer solchen Anrechnung ist verboten.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
		// Check if this charge is in closed day
		If ValueIsFilled(Hotel) And Hotel.DoNotEditClosedDateDocs Then
			vChargeIsInClosedDay = cmIfChargeIsInClosedDay(Ref);
			If Not vChargeIsInClosedDay And ValueIsFilled(RoomRevenueCharge) Then
				vChargeIsInClosedDay = cmIfChargeIsInClosedDay(RoomRevenueCharge);
			EndIf;
			If vChargeIsInClosedDay Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This charge is in closed day! Charge is read only.';
				             |ru='Начисление в закрытом дне! Редактирование такого начисления запрещено.';
							 |de='Anrechnung am geschlossenen Tag! Die Bearbeitung einer solchen Abrechnung ist verboten.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
		// User activity history   
		vEventDescription = StrTemplate(NStr("en = 'Document deletion: %1 from %2, %3'; 
											 |de = 'Unmittelbare Löschung: %1 from %2, %3'; 
											 |ru = 'Непосредственное удаление: %1 от %2, %3'"), TrimAll(Service), ServiceDate, cmFormatSum(Sum, FolioCurrency));    
		AddUserLog(vEventDescription);
	EndIf;
	// Delete bound charge
	If ValueIsFilled(BoundCharge) And Not IsFixedCharge Then
		vBoundChargeObj = BoundCharge.GetObject();
		If BoundCharge.Posted Then
			vBoundChargeObj.Write(DocumentWriteMode.UndoPosting);
		EndIf;
		vBoundChargeObj.Delete();
		// Repost all other charges
		vFolioObj = Folio.GetObject();
		vFolioObj.pmRepostAdditionalCharges(Ref);
	EndIf;
	// Delete bound resource reservation document
	If IsAdditional And ValueIsFilled(Service) And ValueIsFilled(Service.Resource) And 
	   ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") And 
	   Not ParentDoc.DoCharging And ParentDoc.Posted Then
		ParentDoc.GetObject().SetDeletionMark(True);
	EndIf;
	// Delete bound room service document
	If ValueIsFilled(ParentRoomService) And Not IsFixedCharge Then
		vParentRoomServiceObj = ParentRoomService.GetObject();
		vParentRoomServiceObj.AdditionalProperties.Insert("NoPostprocessing", True);
		If ParentRoomService.Posted Then
			vParentRoomServiceObj.Write(DocumentWriteMode.UndoPosting);
		EndIf;
		vParentRoomServiceObj.SetDeletionMark(True);
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
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
	If ValueIsFilled(BoundCharge) And Not IsFixedCharge Then
		If BoundCharge.Posted Then
			vBoundChargeObj = BoundCharge.GetObject();
			vBoundChargeObj.Write(DocumentWriteMode.UndoPosting);
		EndIf;
	EndIf;
EndProcedure // UndoPosting

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure PostToAccounts(pService, pQuantity, pSum, pDiscountSum, pVATDiscountSum, pCommissionSum, pVATCommissionSum, pVATSum, pVATRate = Undefined, pMarkingCode = "", pItem = Undefined)
	vSrvVATRate = ?(ValueIsFilled(pVATRate), pVATRate, VATRate);
	
	Movement = RegisterRecords.Accounts.Add();
	
	Movement.RecordType = AccumulationRecordType.Receipt;
	Movement.Period = BegOfDay(Date);
	
	FillPropertyValues(Movement, Folio);
	FillPropertyValues(Movement, ThisObject);
	
	Movement.Service = pService;
	Movement.VATRate = vSrvVATRate;
	
	// Fill resource, room and room type
	If ValueIsFilled(ParentDoc) Then
		If TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
			If Not ValueIsFilled(Resource) Then
				Movement.Resource = ParentDoc.Resource;
			EndIf;
		ElsIf TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or 
		      TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
			If Not ValueIsFilled(Room) Then
				Movement.Room = ParentDoc.Room;
			EndIf;
		EndIf;
	EndIf;
	
	// Resources
	Movement.Sum = pSum - pDiscountSum;
	Movement.VATSum = pVATSum - pVATDiscountSum;
	// Take commission into account
	If ValueIsFilled(Folio.Agent) And pCommissionSum <> 0 Then
		If ValueIsFilled(Folio.Customer) And Not Folio.Customer.DoNotPostCommission And Folio.Agent = Folio.Customer Then
			Movement.Sum = Movement.Sum - pCommissionSum;
			Movement.VATSum = Movement.VATSum - pVATCommissionSum;
		EndIf;
	EndIf;
	
	// Attributes
	Movement.Quantity = pQuantity;
	Movement.Charge = Ref;
	Movement.Price = cmRecalculatePrice(Movement.Sum, Movement.Quantity);
	
	// Payment section
	If ValueIsFilled(Hotel) Then
		If Not Hotel.SplitFolioBalanceByPaymentSections And Not Hotel.SplitFolioBalanceByServicesAndPrices Then
			Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
			Movement.ChequeService = Catalogs.Services.EmptyRef();
			Movement.ChequeServicePrice = 0;
			Movement.ChequeServiceQuantity = 0;
			Movement.MarkingCode = "";
			Movement.Item = Undefined;
		ElsIf Hotel.SplitFolioBalanceByPaymentSections And Not Hotel.SplitFolioBalanceByServicesAndPrices Then
			Movement.ChequeService = Catalogs.Services.EmptyRef();
			Movement.ChequeServicePrice = 0;
			Movement.ChequeServiceQuantity = 0;
			Movement.MarkingCode = "";
			Movement.Item = Undefined;
		ElsIf Not Hotel.SplitFolioBalanceByPaymentSections And Hotel.SplitFolioBalanceByServicesAndPrices Then
			Movement.ChequeService = Movement.Service;
			Movement.ChequeServicePrice = Movement.Price;
			Movement.ChequeServiceQuantity = Movement.Quantity;
			Movement.MarkingCode = pMarkingCode;
			Movement.Item = pItem;
		EndIf;
	EndIf;
	
	If StatisticsOnly Then
		Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
		Movement.ChequeService = Catalogs.Services.EmptyRef();
		Movement.ChequeServicePrice = 0;
		Movement.ChequeServiceQuantity = 0;
		Movement.MarkingCode = "";
		Movement.Item = Undefined;
	EndIf;
	
	RegisterRecords.Accounts.Write = True;
EndProcedure // PostToAccounts

// -----------------------------------------------------------------------------
Procedure PostToAccumulatingDiscountResources()
	RegisterRecords.AccumulatingDiscountResources.Clear();
	
	vDate = Date;
	If IsCorrection Then
		vDate = CorrectionDate;
	EndIf;
	
	vDiscountType = Undefined;
	If ValueIsFilled(DiscountType) And DiscountType.IsAccumulatingDiscount Then
		vDiscountType = DiscountType;
	EndIf;
	vAccDiscounts = cmGetAccumulatingDiscountTypes(vDiscountType, Hotel);
	For Each vAccDiscount In vAccDiscounts Do
		// Check discount type is valid period
		If vDate < vAccDiscount.DateValidFrom Or ValueIsFilled(vAccDiscount.DateValidTo) And vDate > vAccDiscount.DateValidTo Then
			Continue;
		EndIf;
		// Process discount type
		vDiscountType = vAccDiscount.DiscountType;
		If ValueIsFilled(vDiscountType) And vDiscountType.ExternalBonusSystemIsUsed Then
			Continue;
		EndIf;
		If ValueIsFilled(ParentDoc) And 
		   (TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or 
		    TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or
		    TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
		   ParentDoc.TurnOffAutomaticDiscounts Then
			If DiscountType <> vDiscountType Then
				Continue;
			EndIf;
		EndIf;
		If vDiscountType.MLOS > 0 Then
			If ValueIsFilled(ParentDoc) Then
				If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
					If vDiscountType.MLOS > ParentDoc.Duration Then
						Continue;
					EndIf;
				Else
					Continue;
				EndIf;
			Else
				Continue;
			EndIf;
		EndIf;
		If Not vDiscountType.IsForRackRatesOnly Or 
		   vDiscountType.IsForRackRatesOnly And ValueIsFilled(RoomRate) And RoomRate.IsRackRate Or
		   IsAdditional Or 
		   IsManual Then 
			vDiscountServiceGroup = vDiscountType.DiscountServiceGroup;
			If cmIsServiceInServiceGroup(Service, vDiscountServiceGroup) And Not Service.IsGiftCertificate Then
				vDiscountTypeObj = vDiscountType.GetObject();
				vDiscountDimension = Undefined;
				vNumberOfPersons = 1;
				If ValueIsFilled(ParentDoc) And 
				   (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or 
				    TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or 
					TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation")) Then
					vNumberOfPersons = ParentDoc.NumberOfPersons;
				EndIf;
				vResource = vDiscountTypeObj.pmCalculateResource(Ref, vNumberOfPersons, Folio, DiscountCard, vDiscountDimension);
				If vResource <> 0 Then
					If ValueIsFilled(vDiscountDimension) Then
						Movement = RegisterRecords.AccumulatingDiscountResources.Add();
						If vResource > 0 Then
							Movement.RecordType = AccumulationRecordType.Receipt;
						Else
							Movement.RecordType = AccumulationRecordType.Expense;
						EndIf;
						Movement.Period = vDate;
						Movement.DiscountType = vDiscountType;
						Movement.DiscountDimension = vDiscountDimension;
						If vDiscountType.IsPerVisit Or vDiscountType.BonusCalculationFactor <> 0 Then
							Movement.GuestGroup = GetEffectiveGuestGroup();
						EndIf;
						Movement.Resource = vResource;
						If vDiscountTypeObj.BonusCalculationFactor <> 0 Then
							Movement.Bonus = vResource * vDiscountTypeObj.BonusCalculationFactor;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	RegisterRecords.AccumulatingDiscountResources.Write = True;
EndProcedure // PostToAccumulatingDiscountResources

// -----------------------------------------------------------------------------
Procedure PostToCurrentAccountsReceivable()
	RegisterRecords.CurrentAccountsReceivable.Clear();
	
	Movement = RegisterRecords.CurrentAccountsReceivable.Add();
	
	Movement.RecordType = AccumulationRecordType.Receipt;
	Movement.Period = BegOfDay(Date);
	Movement.Charge = Ref;
	
	If ValueIsFilled(Folio) Then
		FillPropertyValues(Movement, Folio);
	EndIf;
	FillPropertyValues(Movement, ThisObject);
	Movement.GuestGroup = GetEffectiveGuestGroup();
	
	// Fill individuals customer and customer contract if specified
	If Not ValueIsFilled(Movement.Customer) And ValueIsFilled(Hotel.IndividualsCustomer) And ValueIsFilled(Hotel.IndividualsContract) Then
		Movement.Customer = Hotel.IndividualsCustomer;
		Movement.Contract = Hotel.IndividualsContract;
	EndIf;
	
	// Resources
	Movement.Quantity = Quantity;
	Movement.Sum = Sum - DiscountSum;
	Movement.VATSum = VATSum - VATDiscountSum;
	Movement.CommissionSum = CommissionSum;
	
	// Commission
	If Not ValueIsFilled(Folio.Agent) Then
		Movement.CommissionSum = 0;
	ElsIf CommissionSum <> 0 And ValueIsFilled(Folio) And ValueIsFilled(Folio.Agent) Then
		vDoNotPostCommission = False;
		If Folio.Agent.DoNotPostCommission Then
			vDoNotPostCommission = True;
		EndIf;
		If Folio.Agent <> Folio.Customer Then
			Movement.CommissionSum = 0;
			
			// Add new register record for the agent
			If Not vDoNotPostCommission Then
				Movement = RegisterRecords.CurrentAccountsReceivable.Add();
				
				Movement.RecordType = AccumulationRecordType.Receipt;
				Movement.Period = BegOfDay(Date);
				Movement.Charge = Ref;
				
				If ValueIsFilled(Folio) Then
					FillPropertyValues(Movement, Folio);
				EndIf;
				FillPropertyValues(Movement, ThisObject);
				
				// Dimensions
				Movement.Customer = Folio.Agent;
				Movement.Contract = Folio.Agent.AgentCommissionContract;
				Movement.GuestGroup = Catalogs.GuestGroups.EmptyRef();
				
				// Resources
				Movement.Quantity = 0;
				Movement.Sum = 0;
				Movement.VATSum = 0;
				Movement.CommissionSum = CommissionSum;
			EndIf;
		EndIf;
	EndIf;
	
	RegisterRecords.CurrentAccountsReceivable.Write = True;
EndProcedure // PostToCurrentAccountsReceivable

// -----------------------------------------------------------------------------
Procedure PostToPaymentServices(pService, pSum, pDiscountSum)
	RegisterRecords.PaymentServices.Clear();
	
	vDate = Date;
	If IsCorrection Then
		vDate = CorrectionDate;
	EndIf;
	
	Movement = RegisterRecords.PaymentServices.Add();
	
	Movement.RecordType = AccumulationRecordType.Receipt;
	Movement.Period = vDate;
	Movement.Folio = Folio;
	Movement.Service = pService;
	
	// Resources
	Movement.Sum = Round(cmConvertCurrencies(pSum - pDiscountSum, ReportingCurrency, ReportingCurrencyExchangeRate, FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	
	RegisterRecords.PaymentServices.Write = True;
EndProcedure // PostToPaymentServices

// -----------------------------------------------------------------------------
Procedure PostToLabeledGoods(pOrderItems = Undefined)
	RegisterRecords.LabeledGoods.Clear();

	vDate = Date;
	If IsCorrection Then
		vDate = CorrectionDate;
	EndIf;

	If Not IsBlankString(MarkingCode) Then 
		Movement = RegisterRecords.LabeledGoods.Add();
		FillPropertyValues(Movement, ThisObject);
		Movement.RecordType = AccumulationRecordType.Receipt;
		Movement.Period = vDate;
		
		RegisterRecords.LabeledGoods.Write = True;
	EndIf;
	If pOrderItems <> Undefined Then
		For Each vRow In pOrderItems Do
			If Not IsBlankString(vRow.MarkingCode) Then 
				Movement = RegisterRecords.LabeledGoods.Add();
				FillPropertyValues(Movement, ThisObject);
				FillPropertyValues(Movement, vRow);
				Movement.RecordType = AccumulationRecordType.Receipt;
				Movement.Period = vDate;  

				Movement.VATSum = cmCalculateVATSum(vRow.VATRate, vRow.Sum, vDate); 
				
				RegisterRecords.LabeledGoods.Write = True;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // PostToPaymentServices

// -----------------------------------------------------------------------------
Procedure PostToSales(pService, pVATRate = Undefined)
	vAccommodationTemplate = AccommodationTemplate;
	If Not ValueIsFilled(AccommodationTemplate) And ValueIsFilled(vParentDoc) And (TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation")) Then
		vAccommodationTemplate = vParentDoc.AccommodationTemplate;
	EndIf;

	vNoVATRate = cmGetNoVATVATRate();
	
	vGuestGroup = GetEffectiveGuestGroup();
	
	vNumberOfPersonsInRoom = vAccommodationTemplate.NumberOfAdults + vAccommodationTemplate.NumberOfTeenagers + vAccommodationTemplate.NumberOfChildren + vAccommodationTemplate.NumberOfInfants;
	// Get table of one room documents
	vOneRoomDocs = Undefined;
	If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
		vOneRoomDocs = cmGetOneRoomAccommodations(Room, vGuestGroup, ParentDoc.CheckInDate, ParentDoc.CheckOutDate, ParentDoc.Number);
	ElsIf TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
		vOneRoomDocs = cmGetOneRoomReservations(ParentDoc.Number, vGuestGroup, ParentDoc.CheckInDate, ParentDoc.CheckOutDate);
	EndIf;
	If vOneRoomDocs <> Undefined And vOneRoomDocs.Count() > 1 Then
		vNumberOfPersonsInRoom = vOneRoomDocs.Count();
	EndIf;
	
	vSrvSumInReportingCurrency = vSumInReportingCurrency;
	vSrvVATSumInReportingCurrency = vVATSumInReportingCurrency;
	vSrvDiscountSumInReportingCurrency = vDiscountSumInReportingCurrency;
	vSrvVATDiscountSumInReportingCurrency = vVATDiscountSumInReportingCurrency;
	vSrvCommissionSumInReportingCurrency = vCommissionSumInReportingCurrency;
	vSrvVATCommissionSumInReportingCurrency = vVATCommissionSumInReportingCurrency;
	
	vSrvQuantity = Quantity;
	vSrvVATRate = ?(ValueIsFilled(pVATRate), pVATRate, VATRate);
	
	If Not IsCorrection And Not IsSplit And Sum >= 0 Then
		vBDLSettingsDate = GetServiceBreakdownListActiveDate(Service, Date, Hotel);
		If ValueIsFilled(vBDLSettingsDate) Then
			vAccommodationTypesList = New ValueList();
			If IsInPrice And ValueIsFilled(RoomRate) And RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest And 
			   ValueIsFilled(ParentDoc) And (TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation")) And 
			   Not ParentDoc.IsForFolioSplit And ValueIsFilled(vAccommodationTemplate) And vAccommodationTemplate.AccommodationTypes.Count() > 0 Then
				For Each vAccommodationTemplateRow In vAccommodationTemplate.AccommodationTypes Do
					vAccommodationTypesList.Add(vAccommodationTemplateRow.AccommodationType);
				EndDo;
			Else
				vAccommodationTypesList.Add(AccommodationType);
			EndIf;
			For Each vAccommodationTypesListItem In vAccommodationTypesList Do
				vAccommodationTypesListItemIndex = vAccommodationTypesList.IndexOf(vAccommodationTypesListItem);
				
				vAccommodationType = vAccommodationTypesListItem.Value;
				
				vCurClient = vClient;
				vPersonParentDoc = vParentDoc;
				If vAccommodationTypesListItemIndex > 0 Then
					If AdditionalProperties.Property("GuestsInRoom") And AdditionalProperties.GuestsInRoom.Count() = (vAccommodationTypesList.Count() - 1) Then
						vOneRoomDocsRow = AdditionalProperties.GuestsInRoom.Get(vAccommodationTypesListItemIndex - 1);
						If vOneRoomDocsRow.AccommodationType = vAccommodationType Then
							vCurClient = vOneRoomDocsRow.GuestRef;
						EndIf;
					ElsIf vOneRoomDocs <> Undefined And vOneRoomDocs.Count() = vAccommodationTypesList.Count() Then
						vOneRoomDocsRow = vOneRoomDocs.Get(vAccommodationTypesListItemIndex);
						vPersonParentDoc = vOneRoomDocsRow.Ref;
						If ValueIsFilled(vPersonParentDoc) And vPersonParentDoc.AccommodationType = vAccommodationType Then
							vCurClient = vPersonParentDoc.Guest;
						EndIf;
					EndIf;
				EndIf;
				
				vBDLSettings = cmGetServiceBreakdownList(Service, vBDLSettingsDate, Hotel, RoomRate, RoomType, vAccommodationType);
				For Each vBDLSettingsRow In vBDLSettings Do
					If ValueIsFilled(vBDLSettingsRow.Item) And vSrvSumInReportingCurrency >= 0 Then
						vItemService = vBDLSettingsRow.Item;
						
						// Item VAT rate
						vItemVATRate = vSrvVATRate;
						If ValueIsFilled(vBDLSettingsRow.VATRate) And Not vBDLSettingsRow.IsTax Then
							vItemVATRate = vBDLSettingsRow.VATRate;
						EndIf;
						
						// Item price
						vItemPrice = 0;
						vPriceFormula = "";
						If vBDLSettingsRow.Price <> 0 And ValueIsFilled(vBDLSettingsRow.Currency) Then
							vItemPrice = cmConvertCurrencies(vBDLSettingsRow.Price, vBDLSettingsRow.Currency, , ReportingCurrency, , ExchangeRateDate, Hotel);
						ElsIf Not IsBlankString(vBDLSettingsRow.PriceCalculationFormula) Then
							vPriceFormula = TrimAll(vBDLSettingsRow.PriceCalculationFormula);
							vPriceFormula = cmGetFormulaExecutionText(vPriceFormula, ThisObject);
							SetSafeMode(True);
							Execute(vPriceFormula);
							SetSafeMode(False);
						EndIf;
						
						// Item quantity
						vItemQuantity = Quantity;
						vQuantityFormula = "";
						If vBDLSettingsRow.Quantity <> 0 Then
							vItemQuantity = vBDLSettingsRow.Quantity;
						ElsIf Not IsBlankString(vBDLSettingsRow.QuantityCalculationFormula) Then
							vQuantityFormula = TrimAll(vBDLSettingsRow.QuantityCalculationFormula);
							vQuantityFormula = cmGetFormulaExecutionText(vQuantityFormula, ThisObject);
							SetSafeMode(True);
							Execute(vQuantityFormula);
							SetSafeMode(False);
						EndIf;
						
						// Check rest of amount
						If Round(vItemPrice*vItemQuantity, 2) > vSrvSumInReportingCurrency Then
							If vItemQuantity <> 0 Then
								vItemPrice = Round(vSrvSumInReportingCurrency/vItemQuantity, 2);
							Else
								Continue;
							EndIf;
						EndIf;
						
						// Calculate amount to be posted by this item service
						vItemSumInReportingCurrency = Round(vItemPrice*vItemQuantity, 2);
						If vItemSumInReportingCurrency > vSrvSumInReportingCurrency Then
							vItemSumInReportingCurrency = vSrvSumInReportingCurrency;
						EndIf;
						If Not vBDLSettingsRow.IsTax Then
							vItemVATSumInReportingCurrency = cmCalculateVATSum(vItemVATRate, vItemSumInReportingCurrency, Date);
						Else
							If ValueIsFilled(vNoVATRate) Then
								vItemVATRate = vNoVATRate;
							EndIf;
							vItemVATSumInReportingCurrency = 0;
						EndIf;
						
						vItemDiscountSumInReportingCurrency = 0;
						vItemVATDiscountSumInReportingCurrency = 0;
						vItemCommissionSumInReportingCurrency = 0;
						vItemVATCommissionSumInReportingCurrency = 0;
						
						vServiceDate = BegOfDay(Date);
						If ValueIsFilled(vParentDoc) Then
							If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
								If vBDLSettingsRow.ServiceDateNumber > 0 Then
									If BegOfDay(vParentDoc.CheckInDate) <= BegOfDay(vServiceDate) Then
										vN = (BegOfDay(vServiceDate) - BegOfDay(vParentDoc.CheckInDate))/(24*3600) + 1;
										If vN <> vBDLSettingsRow.ServiceDateNumber Then
											vItemQuantity = 0;
										EndIf;
									EndIf;
								ElsIf vBDLSettingsRow.ServiceDateNumber < 0 Then
									If BegOfDay(vParentDoc.CheckOutDate) >= BegOfDay(vServiceDate) Then
										vN = -(BegOfDay(vParentDoc.CheckOutDate) - BegOfDay(vServiceDate))/(24*3600) - 1;
										If vN <> vBDLSettingsRow.ServiceDateNumber Then
											vItemQuantity = 0;
										EndIf;
									EndIf;
								EndIf;
							ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
								If vBDLSettingsRow.ServiceDateNumber > 0 Then
									If BegOfDay(vParentDoc.DateTimeFrom) <= BegOfDay(vServiceDate) Then
										vN = (BegOfDay(vServiceDate) - BegOfDay(vParentDoc.DateTimeFrom))/(24*3600) + 1;
										If vN <> vBDLSettingsRow.ServiceDateNumber Then
											vItemQuantity = 0;
										EndIf;
									EndIf;
								ElsIf vBDLSettingsRow.ServiceDateNumber < 0 Then
									If BegOfDay(vParentDoc.DateTimeTo) >= BegOfDay(vServiceDate) Then
										vN = -(BegOfDay(vParentDoc.DateTimeTo) - BegOfDay(vServiceDate))/(24*3600) - 1;
										If vN <> vBDLSettingsRow.ServiceDateNumber Then
											vItemQuantity = 0;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
						If StrFind(lower(vBDLSettingsRow.PriceCalculationFormula), lower("[TouristTaxAmountRU]")) > 0 And vItemPrice = 0 Then
							vItemQuantity = 0;
						EndIf;
						If vItemQuantity = 0 Then
							Continue;
						EndIf;

						// Create movement for this item service
						ItemMovement = RegisterRecords.Sales.Add();
						
						ItemMovement.Period = Date;
						ItemMovement.AccountingDate = vServiceDate;    
						
						vBDLServiceDate = ?(ValueIsFilled(ServiceDate), ServiceDate, vServiceDate);
						 
						If vBDLSettingsRow.ServiceDateShift <> 0 And ValueIsFilled(vParentDoc) Then
							If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
								If vParentDoc.FixReservationConditions Then
									vReservationDoc = vParentDoc.Reservation;
									If ValueIsFilled(vReservationDoc) Then
										If BegOfDay(vReservationDoc.CheckInDate) < BegOfDay(vReservationDoc.CheckOutDate) Then
											vBDLServiceDate = vBDLServiceDate + vBDLSettingsRow.ServiceDateShift * 24 * 3600;
										EndIf;
									Else
										If BegOfDay(vParentDoc.CheckInDate) < BegOfDay(vParentDoc.CheckOutDate) Then
											vBDLServiceDate = vBDLServiceDate + vBDLSettingsRow.ServiceDateShift * 24 * 3600;
										EndIf;
									EndIf;
								Else
									If BegOfDay(vParentDoc.CheckInDate) < BegOfDay(vParentDoc.CheckOutDate) Then
										vBDLServiceDate = vBDLServiceDate + vBDLSettingsRow.ServiceDateShift * 24 * 3600;
									EndIf;
								EndIf;
							ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
								If BegOfDay(vParentDoc.CheckInDate) < BegOfDay(vParentDoc.CheckOutDate) Then
									vBDLServiceDate = vBDLServiceDate + vBDLSettingsRow.ServiceDateShift * 24 * 3600;
								EndIf;
							ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
								If BegOfDay(vParentDoc.DateTimeFrom) < BegOfDay(vParentDoc.DateTimeTo) Then
									vBDLServiceDate = vBDLServiceDate + vBDLSettingsRow.ServiceDateShift * 24 * 3600;
								EndIf;
							EndIf;
						EndIf;
						
						ItemMovement.ServiceDate = vBDLServiceDate;	
						ItemMovement.IsCorrection = False;
						
						ItemMovement.ParentDoc = vParentDoc;
						
						FillPropertyValues(ItemMovement, vParentDoc, , "ParentDoc");
						FillPropertyValues(ItemMovement, ThisObject, , "ParentDoc, ServiceDate");
						ItemMovement.Service = vItemService;
						ItemMovement.VATRate = vItemVATRate;
						ItemMovement.AccommodationType = vAccommodationType;
						If vAccommodationTypesListItemIndex > 0 Then
							ItemMovement.AccommodationTemplate = Undefined;
						EndIf;
						
						// Fill customer, contract, guest group, agent from the folio
						ItemMovement.Customer = Folio.Customer;
						ItemMovement.Contract = Folio.Contract;
						ItemMovement.Agent = Folio.Agent;
						ItemMovement.PaymentMethod = Folio.PaymentMethod;
						ItemMovement.GuestGroup = vGuestGroup;
						
						// Fill individuals customer and customer contract if specified
						If Not ValueIsFilled(ItemMovement.Customer) And ValueIsFilled(Hotel.IndividualsCustomer) And ValueIsFilled(Hotel.IndividualsContract) Then
							ItemMovement.Customer = Hotel.IndividualsCustomer;
							ItemMovement.Contract = Hotel.IndividualsContract;
						EndIf;
						
						// Fill room rate, accommodation type, room and room type
						If ValueIsFilled(vParentDoc) Then
							If TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
								If Not ValueIsFilled(Room) Then
									ItemMovement.Room = vParentDoc.Room;
								EndIf;
								If Not ValueIsFilled(RoomType) Then
									ItemMovement.RoomType = vParentDoc.RoomType;
								EndIf;
								If Not ValueIsFilled(vAccommodationType) Then
									ItemMovement.AccommodationType = vParentDoc.AccommodationType;
								EndIf;
								If Not ValueIsFilled(RoomRate) Then
									ItemMovement.RoomRate = vParentDoc.RoomRate;
								EndIf;
							ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Folio") Then
								If Not ValueIsFilled(Room) Then
									ItemMovement.Room = vParentDoc.Room;
								EndIf;
							EndIf;
						EndIf;
						If ValueIsFilled(ItemMovement.RoomRate) Then
							ItemMovement.RoomRateType = ItemMovement.RoomRate.RoomRateType;
						EndIf;
						If ValueIsFilled(Resource) Then
							ItemMovement.ResourceType = Resource.Owner;
						EndIf;
								
						ItemMovement.Quantity = vItemQuantity;
						
						ItemMovement.Sales = vItemSumInReportingCurrency;
						ItemMovement.SalesWithoutVAT = vItemSumInReportingCurrency - vItemVATSumInReportingCurrency;
						ItemMovement.VATSum = vItemVATSumInReportingCurrency;
						
						If vBDLSettingsRow.IsInRoomRevenue Then
							If IsRoomRevenue Then
								ItemMovement.RoomRevenue = vItemSumInReportingCurrency;
								ItemMovement.RoomRevenueWithoutVAT = vItemSumInReportingCurrency - vItemVATSumInReportingCurrency;
							Else
								ItemMovement.RoomRevenue = 0;
								ItemMovement.RoomRevenueWithoutVAT = 0;
							EndIf;
							If AdditionalBedsRented <> 0 Then
								ItemMovement.ExtraBedRevenue = vItemSumInReportingCurrency;
								ItemMovement.ExtraBedRevenueWithoutVAT = vItemSumInReportingCurrency - vItemVATSumInReportingCurrency;
							Else
								ItemMovement.ExtraBedRevenue = 0;
								ItemMovement.ExtraBedRevenueWithoutVAT = 0;
							EndIf;
							If IsResourceRevenue Then
								ItemMovement.ResourceRevenue = vItemSumInReportingCurrency;
								ItemMovement.ResourceRevenueWithoutVAT = vItemSumInReportingCurrency - vItemVATSumInReportingCurrency;
							Else
								ItemMovement.ResourceRevenue = 0;
								ItemMovement.ResourceRevenueWithoutVAT = 0;
							EndIf;
						Else
							ItemMovement.RoomRevenue = 0;
							ItemMovement.RoomRevenueWithoutVAT = 0;
							ItemMovement.ExtraBedRevenue = 0;
							ItemMovement.ExtraBedRevenueWithoutVAT = 0;
							ItemMovement.ResourceRevenue = 0;
							ItemMovement.ResourceRevenueWithoutVAT = 0;
						EndIf;
						
						ItemMovement.DiscountSum = vItemDiscountSumInReportingCurrency;
						ItemMovement.DiscountSumWithoutVAT = vItemDiscountSumInReportingCurrency - vItemVATDiscountSumInReportingCurrency;
						If vItemDiscountSumInReportingCurrency = 0 Then
							ItemMovement.Discount = 0;
							ItemMovement.DiscountType = Catalogs.DiscountTypes.EmptyRef();
						EndIf;
						
						ItemMovement.CommissionSum = vItemCommissionSumInReportingCurrency;
						ItemMovement.CommissionSumWithoutVAT = vItemCommissionSumInReportingCurrency - vItemVATCommissionSumInReportingCurrency;
						
						ItemMovement.BookingWindow = 0;
						ItemMovement.RoomsRented = 0;
						ItemMovement.BedsRented = 0;
						ItemMovement.AdditionalBedsRented = 0;
						ItemMovement.GuestDays = 0;
						ItemMovement.GuestsCheckedIn = 0;
						ItemMovement.RoomsCheckedIn = 0;
						ItemMovement.BedsCheckedIn = 0;
						ItemMovement.AdditionalBedsCheckedIn = 0;
						ItemMovement.HoursRented = 0;
						
						ItemMovement.Client = vCurClient;
						If ValueIsFilled(vCurClient) Then
							ItemMovement.Age = vCurClient.Age;
							ItemMovement.AgeRange = vCurClient.AgeRange;
						Else
							ItemMovement.Age = 0;
							ItemMovement.AgeRange = Undefined;
						EndIf;
						
						ItemMovement.RateSum = 0;
						
						ItemMovement.Price = cmRecalculatePrice(vItemSumInReportingCurrency, vItemQuantity);
						ItemMovement.IsStorno = False;
						
						// Do correction of the amounts to be posted by main charge service
						vSrvSumInReportingCurrency = vSrvSumInReportingCurrency - vItemSumInReportingCurrency;
						vSrvDiscountSumInReportingCurrency = vSrvDiscountSumInReportingCurrency - vItemDiscountSumInReportingCurrency;
						vSrvCommissionSumInReportingCurrency = vSrvCommissionSumInReportingCurrency - vItemCommissionSumInReportingCurrency;
						vSrvVATSumInReportingCurrency = vSrvVATSumInReportingCurrency - vItemVATSumInReportingCurrency;
						vSrvVATDiscountSumInReportingCurrency = vSrvVATDiscountSumInReportingCurrency - vItemVATDiscountSumInReportingCurrency;
						vSrvVATCommissionSumInReportingCurrency = vSrvVATCommissionSumInReportingCurrency - vItemVATCommissionSumInReportingCurrency;
						
						// Post to service registration
						If ValueIsFilled(vItemService) And vItemService.ServiceRegistrationIsTurnedOn Then
							PostToServiceRegistration(ItemMovement.Service, ItemMovement.Sales, ItemMovement.DiscountSum, ItemMovement.Quantity, ItemMovement.ParentDoc, ItemMovement.Client, ItemMovement.ServiceDate);
						EndIf;
						
						// Post to Payment services
						If Hotel.DoPaymentsDistributionToServices Then
							PostToPaymentServices(ItemMovement.Service, ItemMovement.Sales, ItemMovement.DiscountSum);
						EndIf;
					EndIf;	
				EndDo; // By breakdown list settings items
			EndDo; // By accommodation types
		EndIf;
	EndIf;
	
	vNumberOfPersonsInTemplate = 0;
	vRecalculateQuantity = False;
	If Not IsCorrection Then
		If (pService.ChargeToEachGuestSeparately Or IsRoomRevenue And Not IsAdditional And Not RoomRevenueAmountsOnly And Not IsSplit) And 
		   ValueIsFilled(vAccommodationTemplate) And Not vAccommodationTemplate.IsForFolioSplit And ValueIsFilled(RoomRate) And 
		   RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest And ValueIsFilled(vParentDoc) And 
		   (TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation")) And 
		   Not vParentDoc.IsForFolioSplit Then
			If IsRoomRevenue And Not IsAdditional And Not RoomRevenueAmountsOnly And Not IsSplit Then
				vNumberOfPersonsInTemplate = vNumberOfPersonsInRoom;
			ElsIf vSrvQuantity <> 0 Then
				vNumberOfPersonsInTemplate = vNumberOfPersonsInRoom;
				vRecalculateQuantity = True;
			EndIf;
		EndIf;
	EndIf;
	If vNumberOfPersonsInTemplate = 1 Then
		vNumberOfPersonsInTemplate = 0;
	EndIf;
	
	vPersonIndex = 0;
	vPersonIndexShift = 0;
	
	vRecGuestDays = GuestDays;
	vRecGuestsCheckedIn = GuestsCheckedIn;
	vRecQuantity = Quantity;
	
	vProportion = 0;
	
	vEffGuestDaysPerPerson = 0;
	vEffGuestsCheckedInPerPerson = 0;
	vEffQuantityPerPerson = 0;
	If vNumberOfPersonsInTemplate > 0 Then
		vEffGuestDaysPerPerson = Round(GuestDays / vNumberOfPersonsInTemplate, 0);
		If vEffGuestDaysPerPerson = 0 And GuestDays <> 0 Then
			vEffGuestDaysPerPerson = ?(GuestDays < 0, -1, 1);
		EndIf;
		vEffGuestsCheckedInPerPerson = Round(GuestsCheckedIn / vNumberOfPersonsInTemplate, 0);
		If vEffGuestsCheckedInPerPerson = 0 And GuestsCheckedIn <> 0 Then
			vEffGuestsCheckedInPerPerson = 1;
		EndIf;
		vEffQuantityPerPerson = Round(Quantity / vNumberOfPersonsInTemplate, 0);
		If vEffQuantityPerPerson = 0 And Quantity <> 0 Then
			vEffQuantityPerPerson = 1;
		EndIf;
	EndIf;

	While True Do
		vDoBreak = False;
		If (vPersonIndex + vPersonIndexShift) >= (vNumberOfPersonsInTemplate - 1) Then
			vDoBreak = True;
		EndIf;
		
		// Create movement for the main charge service
		Movement = RegisterRecords.Sales.Add();
		Movement.Period = Date;
		Movement.IsCorrection = False;
		
		Movement.ParentDoc = vParentDoc;
		
		FillPropertyValues(Movement, vParentDoc, , "ParentDoc");
		FillPropertyValues(Movement, ThisObject, , "ParentDoc");
		Movement.Service = pService;
		Movement.VATRate = vSrvVATRate;
		
		// Fill customer, contract, guest group, agent from the folio
		Movement.Customer = Folio.Customer;
		Movement.Contract = Folio.Contract;
		Movement.Agent = Folio.Agent;
		Movement.PaymentMethod = Folio.PaymentMethod;
		Movement.GuestGroup = vGuestGroup;
		
		// Fill individuals customer and customer contract if specified
		If Not ValueIsFilled(Movement.Customer) And ValueIsFilled(Hotel.IndividualsCustomer) And ValueIsFilled(Hotel.IndividualsContract) Then
			Movement.Customer = Hotel.IndividualsCustomer;
			Movement.Contract = Hotel.IndividualsContract;
		EndIf;
		
		// Fill room rate, accommodation type, room and room type
		If ValueIsFilled(vParentDoc) Then
			If TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
				If Not ValueIsFilled(Room) Then
					Movement.Room = vParentDoc.Room;
				EndIf;
				If Not ValueIsFilled(RoomType) Then
					Movement.RoomType = vParentDoc.RoomType;
				EndIf;
				If Not ValueIsFilled(AccommodationType) Then
					Movement.AccommodationType = vParentDoc.AccommodationType;
				EndIf;
				If Not ValueIsFilled(RoomRate) Then
					Movement.RoomRate = vParentDoc.RoomRate;
				EndIf;
			ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Folio") Then
				If Not ValueIsFilled(Room) Then
					Movement.Room = vParentDoc.Room;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(Movement.RoomRate) Then
			Movement.RoomRateType = Movement.RoomRate.RoomRateType;
		EndIf;
		If ValueIsFilled(Resource) Then
			Movement.ResourceType = Resource.Owner;
		EndIf;
				
		Movement.Sales = vSrvSumInReportingCurrency;
		Movement.SalesWithoutVAT = vSrvSumInReportingCurrency - vSrvVATSumInReportingCurrency;
		Movement.VATSum = vSrvVATSumInReportingCurrency;
		If IsRoomRevenue Then
			Movement.RoomRevenue = vSrvSumInReportingCurrency;
			Movement.RoomRevenueWithoutVAT = vSrvSumInReportingCurrency - vSrvVATSumInReportingCurrency;
		Else
			Movement.RoomRevenue = 0;
			Movement.RoomRevenueWithoutVAT = 0;
		EndIf;
		If Movement.AdditionalBedsRented <> 0 Then
			Movement.ExtraBedRevenue = vSrvSumInReportingCurrency;
			Movement.ExtraBedRevenueWithoutVAT = vSrvSumInReportingCurrency - vSrvVATSumInReportingCurrency;
		Else
			Movement.ExtraBedRevenue = 0;
			Movement.ExtraBedRevenueWithoutVAT = 0;
		EndIf;
		If IsResourceRevenue Then
			If Not RoomRevenueAmountsOnly Then
				Movement.HoursRented = Movement.Quantity;
				If Movement.Service.IsPricePerMinute Then
					Movement.HoursRented = Movement.Quantity/60;
				EndIf;
			EndIf;
			Movement.ResourceRevenue = Movement.Sales;
			Movement.ResourceRevenueWithoutVAT = Movement.SalesWithoutVAT;
		EndIf;
		
		Movement.DiscountSum = vSrvDiscountSumInReportingCurrency;
		Movement.DiscountSumWithoutVAT = vSrvDiscountSumInReportingCurrency - vSrvVATDiscountSumInReportingCurrency;
		If vSrvDiscountSumInReportingCurrency = 0 Then
			Movement.Discount = 0;
			Movement.DiscountType = Catalogs.DiscountTypes.EmptyRef();
		EndIf;
		
		Movement.CommissionSum = vSrvCommissionSumInReportingCurrency;
		Movement.CommissionSumWithoutVAT = vSrvCommissionSumInReportingCurrency - vSrvVATCommissionSumInReportingCurrency;
		
		Movement.BookingWindow = 0;
		Movement.RoomsCheckedIn = 0;
		Movement.BedsCheckedIn = 0;
		Movement.AdditionalBedsCheckedIn = 0;
		If Movement.GuestsCheckedIn <> 0 And Movement.Quantity <> 0 Then
			Movement.RoomsCheckedIn = Movement.RoomsRented;
			Movement.BedsCheckedIn = Movement.BedsRented;
			Movement.AdditionalBedsCheckedIn = Movement.AdditionalBedsRented;
			If Movement.RoomsCheckedIn <> 0 Then
				If ValueIsFilled(ParentDoc) Then
					If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") And ValueIsFilled(ParentDoc.Reservation) Then
						Movement.BookingWindow = Round((BegOfDay(ParentDoc.CheckInDate) - BegOfDay(ParentDoc.Reservation.Date))/(24*3600), 0);
					ElsIf TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
						Movement.BookingWindow = Round((BegOfDay(ParentDoc.CheckInDate) - BegOfDay(ParentDoc.Date))/(24*3600)*?(Movement.RoomsCheckedIn > 1, Movement.RoomsCheckedIn, 1), 0);
					ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
						Movement.BookingWindow = Round((BegOfDay(ParentDoc.DateTimeFrom) - BegOfDay(ParentDoc.Date))/(24*3600), 0);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		Movement.Client = vClient;
		If ValueIsFilled(vClient) Then
			Movement.Age = vClient.Age;
			Movement.AgeRange = vClient.AgeRange;
		Else
			Movement.Age = 0;
			Movement.AgeRange = Undefined;
		EndIf;
		
		// Fill room rate deviation
		If Not IsAdditional And RateSum <> 0 Then
			Movement.RateSum = vRateSumInReportingCurrency;
		EndIf;
		
		Movement.AccountingDate = BegOfDay(Date);
		Movement.Price = cmRecalculatePrice(vSrvSumInReportingCurrency, Quantity);
		Movement.IsStorno = False;
		
		Movement.IsCorrection = False;
		
		// Correction for the template guests
		If vNumberOfPersonsInTemplate > 0 Then
			If vRecGuestDays = 0 Then
				vEffGuestDaysPerPerson = 0;
			EndIf;
			If vRecGuestsCheckedIn = 0 Then
				vEffGuestsCheckedInPerPerson = 0;
			EndIf;
			If vRecQuantity = 0 Then
				vEffQuantityPerPerson = 0;
			EndIf;
			
			// Guest stats
			If (vPersonIndex + vPersonIndexShift) = (vNumberOfPersonsInTemplate - 1) Then
				Movement.GuestDays = vRecGuestDays;
				Movement.GuestsCheckedIn = vRecGuestsCheckedIn;
			Else
				If vRecGuestDays > 0 Then
					Movement.GuestDays = ?(vRecGuestDays > vEffGuestDaysPerPerson, vEffGuestDaysPerPerson, vRecGuestDays);
					Movement.GuestsCheckedIn = ?(vRecGuestsCheckedIn > vEffGuestsCheckedInPerPerson, vEffGuestsCheckedInPerPerson, vRecGuestsCheckedIn);
				Else
					Movement.GuestDays = ?(vRecGuestDays < vEffGuestDaysPerPerson, vEffGuestDaysPerPerson, vRecGuestDays);
					Movement.GuestsCheckedIn = ?(vRecGuestsCheckedIn < vEffGuestsCheckedInPerPerson, vEffGuestsCheckedInPerPerson, vRecGuestsCheckedIn);
				EndIf;
			EndIf;
			vRecGuestDays = vRecGuestDays - Movement.GuestDays;
			vRecGuestsCheckedIn = vRecGuestsCheckedIn - Movement.GuestsCheckedIn;
			
			// Service quantity correction
			If vRecalculateQuantity Then
				Movement.Quantity = Round(Movement.Quantity / vNumberOfPersonsInTemplate, 7);
				If (vPersonIndex + vPersonIndexShift) = (vNumberOfPersonsInTemplate - 1) Then
					Movement.Quantity = vRecQuantity;
				Else
					If vRecQuantity > 0 Then
						Movement.Quantity = ?(vRecQuantity > vEffQuantityPerPerson, vEffQuantityPerPerson, vRecQuantity);
					Else
						Movement.Quantity = ?(vRecQuantity < vEffQuantityPerPerson, vEffQuantityPerPerson, vRecQuantity);
					EndIf;
				EndIf;
				vRecQuantity = vRecQuantity - Movement.Quantity;
			Else
				If vPersonIndex > 0 Then
					Movement.Quantity = 0;
				EndIf;
				vRecQuantity = 0;
			EndIf;

			If vNumberOfPersonsInTemplate = 0 Then
				vDoBreak = True;
			EndIf;
			If vRecGuestDays = 0 And vRecGuestsCheckedIn = 0 And 
			  (Not vRecalculateQuantity Or vRecalculateQuantity And vRecQuantity = 0) Then
				vDoBreak = True;
			EndIf;
			
			// Calculate initial shift for template
			If vPersonIndex = 0 Then
				If AdditionalProperties.Property("GuestsInRoom") And AdditionalProperties.GuestsInRoom.Count() = (vNumberOfPersonsInTemplate - 1) Then
					For j = 0 To (AdditionalProperties.GuestsInRoom.Count() - 1) Do
						vOneRoomDocsRow = AdditionalProperties.GuestsInRoom.Get(j);
						If vOneRoomDocsRow.AccommodationType = AccommodationType Then
							vPersonIndexShift = j + 1;
							If ValueIsFilled(vOneRoomDocsRow.Ref) Then
								Movement.ParentDoc = vOneRoomDocsRow.Ref;
							EndIf;
							Movement.Client = vOneRoomDocsRow.GuestRef;
							Break;
						EndIf;
					EndDo;
				ElsIf vOneRoomDocs <> Undefined And vOneRoomDocs.Count() = vNumberOfPersonsInTemplate Then
					For j = 0 To (vOneRoomDocs.Count() - 1) Do
						vOneRoomDocsRow = vOneRoomDocs.Get(j);
						vPersonParentDoc = vOneRoomDocsRow.Ref;
						If ValueIsFilled(vPersonParentDoc) And vPersonParentDoc.AccommodationType = AccommodationType Then
							vPersonIndexShift = j;
							Movement.ParentDoc = vPersonParentDoc;
							Movement.Client = vPersonParentDoc.Guest;
							Break;
						EndIf;
					EndDo;
				ElsIf ValueIsFilled(vAccommodationTemplate) Then
					For j = 0 To (vAccommodationTemplate.AccommodationTypes.Count() - 1) Do
						vOneRoomDocsRow = vAccommodationTemplate.AccommodationTypes.Get(j);
						If vOneRoomDocsRow.AccommodationType = AccommodationType Then
							vPersonIndexShift = j;
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			
			If vPersonIndex > 0 Then
				vPersonParentDoc = vParentDoc;
				vPerson = ParentDoc.Guest;
				vPersonAccommodationType = AccommodationType;
				If AdditionalProperties.Property("GuestsInRoom") And 
				   AdditionalProperties.GuestsInRoom.Count() = (vNumberOfPersonsInTemplate - 1) And 
				   AdditionalProperties.GuestsInRoom.Count() > (vPersonIndex + vPersonIndexShift - 1) Then
					vOneRoomDocsRow = AdditionalProperties.GuestsInRoom.Get(vPersonIndex + vPersonIndexShift - 1);
					If ValueIsFilled(vOneRoomDocsRow.Ref) Then
						vPersonParentDoc = vOneRoomDocsRow.Ref;
					EndIf;
					vPerson = vOneRoomDocsRow.GuestRef;
					vPersonAccommodationType = vOneRoomDocsRow.AccommodationType;
				ElsIf vOneRoomDocs <> Undefined And vOneRoomDocs.Count() = vNumberOfPersonsInTemplate And 
				      vOneRoomDocs.Count() > (vPersonIndex + vPersonIndexShift) Then
					vOneRoomDocsRow = vOneRoomDocs.Get(vPersonIndex + vPersonIndexShift);
					vPersonParentDoc = vOneRoomDocsRow.Ref;
					vPerson = vPersonParentDoc.Guest;
					vPersonAccommodationType = vPersonParentDoc.AccommodationType;
				Else
					If ValueIsFilled(vAccommodationTemplate) And 
					   vAccommodationTemplate.AccommodationTypes.Count() > (vPersonIndex + vPersonIndexShift) Then
						vWrkAccType = vAccommodationTemplate.AccommodationTypes.Get(vPersonIndex + vPersonIndexShift).AccommodationType;
						If ValueIsFilled(vWrkAccType) Then
							vPerson = Undefined;
							vPersonAccommodationType = vWrkAccType;
						EndIf;
					EndIf;
				EndIf;					
				// Update dimensions
				Movement.Client = vPerson;
				Movement.ParentDoc = vPersonParentDoc;
				Movement.AccommodationType = vPersonAccommodationType;
				If (vPersonIndex + vPersonIndexShift) > 0 Then
					Movement.AccommodationTemplate = Undefined;
				EndIf;
				If ValueIsFilled(vPerson) Then
					Movement.Age = vPerson.Age;
					Movement.AgeRange = vPerson.AgeRange;
				Else
					Movement.Age = 0;
					Movement.AgeRange = Undefined;
				EndIf;
				// Update attributes
				Movement.RateSum = 0;
				Movement.NumberOfAdditionalBeds = 0;
				Movement.NumberOfBeds = 0;
				Movement.NumberOfRooms = 0;
				// Reset resources
				If vRecalculateQuantity And Movement.Quantity <> 0 Then
					If vDoBreak Then
						Movement.Sales = Movement.Sales - Round(Movement.Sales * vProportion, 2) * vPersonIndex;
						Movement.SalesWithoutVAT = Movement.SalesWithoutVAT - Round(Movement.SalesWithoutVAT * vProportion, 2) * vPersonIndex;
						Movement.RoomRevenue = Movement.RoomRevenue - Round(Movement.RoomRevenue * vProportion, 2) * vPersonIndex;
						Movement.RoomRevenueWithoutVAT = Movement.RoomRevenueWithoutVAT - Round(Movement.RoomRevenueWithoutVAT * vProportion, 2) * vPersonIndex;
						Movement.ExtraBedRevenue = Movement.ExtraBedRevenue - Round(Movement.ExtraBedRevenue * vProportion, 2);
						Movement.ExtraBedRevenueWithoutVAT = Movement.ExtraBedRevenueWithoutVAT - Round(Movement.ExtraBedRevenueWithoutVAT * vProportion, 2) * vPersonIndex;
						Movement.CommissionSum = Movement.CommissionSum - Round(Movement.CommissionSum * vProportion, 2) * vPersonIndex;
						Movement.CommissionSumWithoutVAT = Movement.CommissionSumWithoutVAT - Round(Movement.CommissionSumWithoutVAT * vProportion, 2) * vPersonIndex;
						Movement.DiscountSum = Movement.DiscountSum - Round(Movement.DiscountSum * vProportion, 2) * vPersonIndex;
						Movement.DiscountSumWithoutVAT = Movement.DiscountSumWithoutVAT - Round(Movement.DiscountSumWithoutVAT * vProportion, 2) * vPersonIndex;
						Movement.ResourceRevenue = Movement.ResourceRevenue - Round(Movement.ResourceRevenue * vProportion, 2) * vPersonIndex;
						Movement.ResourceRevenueWithoutVAT = Movement.ResourceRevenueWithoutVAT - Round(Movement.ResourceRevenueWithoutVAT * vProportion, 2) * vPersonIndex;
						Movement.VATSum = Movement.Sales - Movement.SalesWithoutVAT;
					Else
						If Quantity <> 0 Then
							vProportion = Movement.Quantity / Quantity;
						EndIf;
						Movement.Sales = Round(Movement.Sales * vProportion, 2);
						Movement.SalesWithoutVAT = Round(Movement.SalesWithoutVAT * vProportion, 2);
						Movement.RoomRevenue = Round(Movement.RoomRevenue * vProportion, 2);
						Movement.RoomRevenueWithoutVAT = Round(Movement.RoomRevenueWithoutVAT * vProportion, 2);
						Movement.ExtraBedRevenue = Round(Movement.ExtraBedRevenue * vProportion, 2);
						Movement.ExtraBedRevenueWithoutVAT = Round(Movement.ExtraBedRevenueWithoutVAT * vProportion, 2);
						Movement.CommissionSum = Round(Movement.CommissionSum * vProportion, 2);
						Movement.CommissionSumWithoutVAT = Round(Movement.CommissionSumWithoutVAT * vProportion, 2);
						Movement.DiscountSum = Round(Movement.DiscountSum * vProportion, 2);
						Movement.DiscountSumWithoutVAT = Round(Movement.DiscountSumWithoutVAT * vProportion, 2);
						Movement.ResourceRevenue = Round(Movement.ResourceRevenue * vProportion, 2);
						Movement.ResourceRevenueWithoutVAT = Round(Movement.ResourceRevenueWithoutVAT * vProportion, 2);
						Movement.VATSum = Movement.Sales - Movement.SalesWithoutVAT;
					EndIf;
				Else
					Movement.Price = 0;
					Movement.Sales = 0;
					Movement.SalesWithoutVAT = 0;
					Movement.RoomRevenue = 0;
					Movement.RoomRevenueWithoutVAT = 0;
					Movement.ExtraBedRevenue = 0;
					Movement.ExtraBedRevenueWithoutVAT = 0;
					Movement.CommissionSum = 0;
					Movement.CommissionSumWithoutVAT = 0;
					Movement.DiscountSum = 0;
					Movement.DiscountSumWithoutVAT = 0;
					Movement.VATSum = 0;
					Movement.ResourceRevenue = 0;
					Movement.ResourceRevenueWithoutVAT = 0;
				EndIf;
				Movement.RoomsRented = 0;
				Movement.BedsRented = 0;
				Movement.AdditionalBedsRented = 0;
				Movement.RoomsCheckedIn = 0;
				Movement.BedsCheckedIn = 0;
				Movement.AdditionalBedsCheckedIn = 0;
				Movement.BookingWindow = 0;
				Movement.HoursRented = 0;
			ElsIf vRecalculateQuantity And Quantity <> 0 Then
				If Quantity <> 0 Then
					vProportion = Movement.Quantity / Quantity;
				EndIf;
				Movement.Sales = Round(Movement.Sales * vProportion, 2);
				Movement.SalesWithoutVAT = Round(Movement.SalesWithoutVAT * vProportion, 2);
				Movement.RoomRevenue = Round(Movement.RoomRevenue * vProportion, 2);
				Movement.RoomRevenueWithoutVAT = Round(Movement.RoomRevenueWithoutVAT * vProportion, 2);
				Movement.ExtraBedRevenue = Round(Movement.ExtraBedRevenue * vProportion, 2);
				Movement.ExtraBedRevenueWithoutVAT = Round(Movement.ExtraBedRevenueWithoutVAT * vProportion, 2);
				Movement.CommissionSum = Round(Movement.CommissionSum * vProportion, 2);
				Movement.CommissionSumWithoutVAT = Round(Movement.CommissionSumWithoutVAT * vProportion, 2);
				Movement.DiscountSum = Round(Movement.DiscountSum * vProportion, 2);
				Movement.DiscountSumWithoutVAT = Round(Movement.DiscountSumWithoutVAT * vProportion, 2);
				Movement.ResourceRevenue = Round(Movement.ResourceRevenue * vProportion, 2);
				Movement.ResourceRevenueWithoutVAT = Round(Movement.ResourceRevenueWithoutVAT * vProportion, 2);
				Movement.VATSum = Movement.Sales - Movement.SalesWithoutVAT;
			EndIf;
		EndIf;
		
		If IsCorrection And BegOfDay(CorrectionDate) <> BegOfDay(Date) Then
			vMovement1 = RegisterRecords.Sales.Add();
			FillPropertyValues(vMovement1, Movement);
			vMovement1.IsCorrection = True;
			vMovement1.Sales = -vMovement1.Sales;
			vMovement1.SalesWithoutVAT = -vMovement1.SalesWithoutVAT;
			vMovement1.RoomRevenue = -vMovement1.RoomRevenue;
			vMovement1.RoomRevenueWithoutVAT = -vMovement1.RoomRevenueWithoutVAT;
			vMovement1.ExtraBedRevenue = -vMovement1.ExtraBedRevenue;
			vMovement1.ExtraBedRevenueWithoutVAT = -vMovement1.ExtraBedRevenueWithoutVAT;
			vMovement1.CommissionSum = -vMovement1.CommissionSum;
			vMovement1.CommissionSumWithoutVAT = -vMovement1.CommissionSumWithoutVAT;
			vMovement1.DiscountSum = -vMovement1.DiscountSum;
			vMovement1.DiscountSumWithoutVAT = -vMovement1.DiscountSumWithoutVAT;
			vMovement1.RoomsRented = -vMovement1.RoomsRented;
			vMovement1.BedsRented = -vMovement1.BedsRented;
			vMovement1.AdditionalBedsRented = -vMovement1.AdditionalBedsRented;
			vMovement1.GuestDays = -vMovement1.GuestDays;
			vMovement1.GuestsCheckedIn = -vMovement1.GuestsCheckedIn;
			vMovement1.RoomsCheckedIn = -vMovement1.RoomsCheckedIn;
			vMovement1.BedsCheckedIn = -vMovement1.BedsCheckedIn;
			vMovement1.AdditionalBedsCheckedIn = -vMovement1.AdditionalBedsCheckedIn;
			vMovement1.BookingWindow = -vMovement1.BookingWindow;
			vMovement1.ResourceRevenue = -vMovement1.ResourceRevenue;
			vMovement1.ResourceRevenueWithoutVAT = -vMovement1.ResourceRevenueWithoutVAT;
			vMovement1.HoursRented = -vMovement1.HoursRented;
			vMovement1.Quantity = -vMovement1.Quantity;
			vMovement1.VATSum = -vMovement1.VATSum;
			
			vMovement2 = RegisterRecords.Sales.Add();
			FillPropertyValues(vMovement2, Movement);
			vMovement2.IsCorrection = True;
			vMovement2.Period = CorrectionDate;
			vMovement2.AccountingDate = BegOfDay(CorrectionDate);
		EndIf;
		
		// Post to service registration
		If Movement.Service.ServiceRegistrationIsTurnedOn Then
			PostToServiceRegistration(Movement.Service, Movement.Sales, Movement.DiscountSum, Movement.Quantity, Movement.ParentDoc, Movement.Client, Movement.ServiceDate);
		EndIf;
		
		// Post to Payment services
		If Hotel.DoPaymentsDistributionToServices Then
			PostToPaymentServices(Movement.Service, Movement.Sales, Movement.DiscountSum);
		EndIf;    
		
		If vDoBreak Then
			Break;
		EndIf;
		
		vPersonIndex = vPersonIndex + 1;
	EndDo;
	
	// Process connected rooms 
	vIsConnectService = False;
	If ValueIsFilled(RoomType) And IsRoomRevenue And IsInPrice And Not IsSplit And Not RoomRevenueAmountsOnly And (RoomsRented <> 0 Or BedsRented <> 0) Then
		If RoomType.DoesNotAffectRoomRevenueStatistics And RoomType.ConnectedRoomTypes.Count() > 0 Then
			vIsConnectService = True;
		EndIf;
	EndIf;
	If vIsConnectService Then
		For Each vConnectedRoomTypesRow In RoomType.ConnectedRoomTypes Do
			If ValueIsFilled(vConnectedRoomTypesRow.RoomType) Then
				vMovementCR = RegisterRecords.Sales.Add();
				FillPropertyValues(vMovementCR, Movement, , "Price, Sales, SalesWithoutVAT, RoomRevenue, RoomRevenueWithoutVAT, ExtraBedRevenue, ExtraBedRevenueWithoutVAT, CommissionSum, CommissionSumWithoutVAT, DiscountSum, DiscountSumWithoutVAT, VATSum, AdditionalBedsRented, GuestDays, RoomsCheckedIn, BedsCheckedIn, AdditionalBedsCheckedIn, GuestsCheckedIn, BookingWindow, ResourceRevenue, ResourceRevenueWithoutVAT, HoursRented, Quantity, Room, RoomType, RateSum, NumberOfBedsPerRoom, NumberOfPersonsPerRoom, NumberOfAdditionalBeds, NumberOfBeds, NumberOfPersons");
				If ValueIsFilled(Room) Then
					If Room.ConnectedRooms.Count() = RoomType.ConnectedRoomTypes.Count() Then
						vConnectedRoomsRow = Room.ConnectedRooms.Get(RoomType.ConnectedRoomTypes.IndexOf(vConnectedRoomTypesRow));
						vMovementCR.Room = vConnectedRoomsRow.Room;
						vMovementCR.RoomType = vConnectedRoomsRow.RoomType;
					EndIf;
				Else
					vMovementCR.RoomType = vConnectedRoomTypesRow.RoomType;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	RegisterRecords.Sales.Write = True;
EndProcedure // PostToSales

// -----------------------------------------------------------------------------
Procedure PostToFOChartOfAccounts(pService, pQuantity, pSum, pDiscountSum, pVATDiscountSum, pCommissionSum, pVATCommissionSum, Val pVATSum, pPOSTicket = "", pDoNotProcessPostingSettings = False, pIsComplimentary = False, pIsDiscounted = False, pVATRate = Undefined)
	vSrvVATRate = ?(ValueIsFilled(pVATRate), pVATRAte, VATRate);

	// Get service account
	vAccountStruct = cmGetAccountCodeForService(Hotel, Company, pService, vSrvVATRate, BegOfDay(Date));
	vAccount = vAccountStruct.Account;
	If Not ValueIsFilled(vAccount) Then
		Return;
	EndIf;
	// Get account postings settings
	If vAccount.PostingsListSettings.Count() = 0 Then
		Return;
	EndIf;
	
	// Postings currency
	vAccountCurrency = FolioCurrency;
	
	vGrosSumInPostingCurrency = cmConvertCurrencies(pSum, FolioCurrency, FolioCurrencyExchangeRate, vAccountCurrency, , ExchangeRateDate, Hotel);
	vSrvSumInPostingCurrency = vGrosSumInPostingCurrency;
	vSrvVATSumInPostingCurrency = cmConvertCurrencies(pVATSum, FolioCurrency, FolioCurrencyExchangeRate, vAccountCurrency, , ExchangeRateDate, Hotel);
	vSrvDiscountSumInPostingCurrency = cmConvertCurrencies(pDiscountSum, FolioCurrency, FolioCurrencyExchangeRate, vAccountCurrency, , ExchangeRateDate, Hotel);
	vSrvVATDiscountSumInPostingCurrency = cmConvertCurrencies(pVATDiscountSum, FolioCurrency, FolioCurrencyExchangeRate, vAccountCurrency, , ExchangeRateDate, Hotel);
	vSrvCommissionSumInPostingCurrency = cmConvertCurrencies(pCommissionSum, FolioCurrency, FolioCurrencyExchangeRate, vAccountCurrency, , ExchangeRateDate, Hotel);
	vSrvVATCommissionSumInPostingCurrency = cmConvertCurrencies(pVATCommissionSum, FolioCurrency, FolioCurrencyExchangeRate, vAccountCurrency, , ExchangeRateDate, Hotel);
	vRateSumInPostingCurrency = 0;
	vRateDiscountSumInPostingCurrency = 0;
	If IsRoomRevenue And IsInPrice Or IsResourceRevenue Then
		vRateSumInPostingCurrency = cmConvertCurrencies(RateSum, FolioCurrency, FolioCurrencyExchangeRate, vAccountCurrency, , ExchangeRateDate, Hotel);
		vRateDiscountSumInPostingCurrency = cmConvertCurrencies(RateDiscountSum, FolioCurrency, FolioCurrencyExchangeRate, vAccountCurrency, , ExchangeRateDate, Hotel);
		vRateSumInPostingCurrency = vRateSumInPostingCurrency - vRateDiscountSumInPostingCurrency;
		
		If vSrvSumInPostingCurrency < 0 And vRateSumInPostingCurrency > 0 Then
			vRateSumInPostingCurrency = -vRateSumInPostingCurrency;
			vRateDiscountSumInPostingCurrency = -vRateDiscountSumInPostingCurrency;
		EndIf;
	EndIf;
	
	vSrvQuantity = pQuantity;
	
	// Do amounts correction for discounts
	vSrvVATSumInPostingCurrency = cmCalculateVATSum(vSrvVATRate, vSrvSumInPostingCurrency - vSrvDiscountSumInPostingCurrency, Date);
	If Not pIsDiscounted Then
		vSrvSumInPostingCurrency = vSrvSumInPostingCurrency - vSrvDiscountSumInPostingCurrency;
		vGrosSumInPostingCurrency = vSrvSumInPostingCurrency;
	EndIf;
	
	// Total VAT amount calculated for all break down list items
	vPostingsVATSumInPostingCurrency = vSrvVATSumInPostingCurrency;
	
	// Recalculate amounts according to the account complimentary settings
	If pIsComplimentary Then
		If ValueIsFilled(vAccount.ComplimentaryIncomeAccount) And ValueIsFilled(vAccount.ComplimentaryExpensesAccount) Then
			vExpensesAccount = vAccount.ComplimentaryExpensesAccount;
			vExpensesAccountType = vExpensesAccount.AccountType;
			If ValueIsFilled(vExpensesAccountType) Then
				vExpensesPercent = vExpensesAccountType.ExpensesPercent;
				vExpensesExcludeVAT = vExpensesAccountType.ExpensesExcludeVAT;
				If vExpensesPercent > 0 Or vExpensesExcludeVAT Then
					If vExpensesExcludeVAT Then
						vSrvSumInPostingCurrency = vSrvSumInPostingCurrency - vSrvVATSumInPostingCurrency;
						vSrvSumInPostingCurrency = Round(vSrvSumInPostingCurrency*vExpensesAccountType.ExpensesPercent/100, 2);
						vSrvVATSumInPostingCurrency = 0;
					Else
						vSrvSumInPostingCurrency = Round(vSrvSumInPostingCurrency*vExpensesAccountType.ExpensesPercent/100, 2);
						vSrvVATSumInPostingCurrency = cmCalculateVATSum(vSrvVATRate, vSrvSumInPostingCurrency, Date);
					EndIf;
				Else
					Return;
				EndIf;
			Else
				Return;
			EndIf;
		Else
			Return;
		EndIf;
	EndIf;
	
	vReverseSign = False;
	If vGrosSumInPostingCurrency < 0 Then
		vReverseSign = True;
		
		vGrosSumInPostingCurrency = -vGrosSumInPostingCurrency;
		vSrvSumInPostingCurrency = -vSrvSumInPostingCurrency;
		vSrvVATSumInPostingCurrency = -vSrvVATSumInPostingCurrency;
		vSrvDiscountSumInPostingCurrency = -vSrvDiscountSumInPostingCurrency;
		vSrvVATDiscountSumInPostingCurrency = -vSrvVATDiscountSumInPostingCurrency;
		vSrvCommissionSumInPostingCurrency = -vSrvCommissionSumInPostingCurrency;
		vSrvVATCommissionSumInPostingCurrency = -vSrvVATCommissionSumInPostingCurrency;
		
		vSrvQuantity = -vSrvQuantity;
	EndIf;
	vCorrespondingAccountPostingAmount = vSrvSumInPostingCurrency;
	If pIsDiscounted And Not IsCorrection Then
		vCorrespondingAccountPostingAmount = vSrvSumInPostingCurrency - vSrvDiscountSumInPostingCurrency;
	EndIf;
	
	// Wich debit account to use: Guest ledger or Financial account
	vCorrespondingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
	If ValueIsFilled(Folio) And ValueIsFilled(Folio.FinancialAccount) Then
		vCorrespondingAccount = Folio.FinancialAccount;
	EndIf;
	
	vClosingAccount = vAccount;
	
	If vSrvSumInPostingCurrency <> 0 Then
		// Do for each rule in the postings list
		vRestOfPostingAmount = vSrvSumInPostingCurrency;
		vAmountFormula = "";
		vVariableNames = New ValueList();
		For Each vPostingsRow In vAccount.PostingsListSettings Do
			If ValueIsFilled(vPostingsRow.Account) And Not IsBlankString(vPostingsRow.Symbol) And Not IsBlankString(vPostingsRow.Formula) Then
				vPostingAccount = vPostingsRow.Account;
				
				// Generate formula to be executed
				vRowFormula = cmGetPostingFormulaExecutionText(TrimAll(vPostingsRow.Formula), vPostingsRow.Variable, ThisObject);
				// Replace previous rows result variabels with technical names
				For Each vVariableNamesItem In vVariableNames Do
					vRowFormula = StrReplace(vRowFormula, vVariableNamesItem.Presentation, vVariableNamesItem.Value);
				EndDo;
				vFormulaResultVar = cmGetValidName(TrimAll(vPostingsRow.Symbol));
				vVariableNames.Add(vFormulaResultVar, TrimAll(vPostingsRow.Symbol));
				vAmountFormula = vAmountFormula + vFormulaResultVar + " = Round(" + vRowFormula + ", 2);" + Chars.LF;
				
				// Skip all except VAT in some cases
				If pDoNotProcessPostingSettings Then
					If vRowFormula <> "vSrvVATSumInPostingCurrency" Then
						If vAccount <> vPostingAccount And (vAccount.PostingsListSettings.IndexOf(vPostingsRow) + 1) < vAccount.PostingsListSettings.Count() Then
							If vRestOfPostingAmount = 0 Then
								Break;
							Else
								Continue;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				
				// Execute row formula
				vPostingAmount = 0;
				vThisIsMainAccountPosting = False;
				If vAccount = vPostingAccount And 
				   (vAccount.PostingsListSettings.IndexOf(vPostingsRow) + 1) = vAccount.PostingsListSettings.Count() Then
					vPostingAmount = vRestOfPostingAmount;
					vThisIsMainAccountPosting = True;
				Else
					If Not IsSplit Or vPostingAccount.IsVATAccount Then
						SetSafeMode(True);
						Execute(vAmountFormula + Chars.LF + "vPostingAmount = Round(" + vFormulaResultVar + ", 2);");
						SetSafeMode(False);
					EndIf;
				EndIf;
				If pIsComplimentary Then
					If vPostingAccount.IsVATAccount Then
						vPostingAmount = 0;
					EndIf;
				EndIf;
				If vPostingAmount = 0 Then
					Continue;
				EndIf;
				If vRestOfPostingAmount >= 0 Then
					If vPostingAmount > vRestOfPostingAmount Then
						vPostingAmount = vRestOfPostingAmount;
					EndIf;
				Else
					If vPostingAmount < vRestOfPostingAmount Then
						vPostingAmount = vRestOfPostingAmount;
					EndIf;
				EndIf;
				vRestOfPostingAmount = vRestOfPostingAmount - vPostingAmount;
				
				// Check if it is complimentary or discount and replace account if possible
				If vThisIsMainAccountPosting Then
					If pIsComplimentary Then
						If ValueIsFilled(vAccount.ComplimentaryIncomeAccount) And ValueIsFilled(vAccount.ComplimentaryExpensesAccount) Then
							vPostingAccount = vAccount.ComplimentaryIncomeAccount;
							vClosingAccount = vPostingAccount;
							vCorrespondingAccount = vAccount.ComplimentaryExpensesAccount;
						EndIf;
					ElsIf pIsDiscounted Then
						If IsCorrection Then
							If ValueIsFilled(vAccount.DiscountIncomeAccount) And ValueIsFilled(vAccount.DiscountExpensesAccount) Then
								vPostingAccount = vAccount.DiscountIncomeAccount;
								vClosingAccount = vPostingAccount;
								vCorrespondingAccount = vAccount.DiscountExpensesAccount;
							EndIf;
						EndIf;
					EndIf;
				Else
					If pIsComplimentary Then
						If ValueIsFilled(vAccount.ComplimentaryIncomeAccount) And ValueIsFilled(vAccount.ComplimentaryExpensesAccount) Then
							vCorrespondingAccount = vAccount.ComplimentaryExpensesAccount;
						EndIf;
					ElsIf pIsDiscounted Then
						If IsCorrection Then
							If ValueIsFilled(vAccount.DiscountIncomeAccount) And ValueIsFilled(vAccount.DiscountExpensesAccount) Then
								vCorrespondingAccount = vAccount.DiscountExpensesAccount;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				
				// Create movement for this item service
				PostingMovement = Undefined;
				If vPostingsRow.Sign = Enums.AccountSigns.Cr Then
					If vReverseSign Then
						PostingMovement = RegisterRecords.PostingsFO.AddDebit();
					Else
						PostingMovement = RegisterRecords.PostingsFO.AddCredit();
					EndIf;
				ElsIf vPostingsRow.Sign = Enums.AccountSigns.Dt Then
					If vReverseSign Then
						PostingMovement = RegisterRecords.PostingsFO.AddCredit();
					Else
						PostingMovement = RegisterRecords.PostingsFO.AddDebit();
					EndIf;
				Else
					Raise NStr("en='Sign is not defined in posting settings line '; ru='Знак проводки не указан в настройках проводок в строке '; de='Das buchungszeichen ist in den buchungseinstellungen in der Zeile nicht angegeben '") + vPostingsRow.LineNumber + ", " + vPostingAccount;
				EndIf;
				
				PostingMovement.Active = True;
				
				PostingMovement.Account = vPostingAccount;
				PostingMovement.CorrAccount = vCorrespondingAccount;
				
				PostingMovement.Amount = vPostingAmount;
				If vThisIsMainAccountPosting Then
					PostingMovement.GrosAmount = vGrosSumInPostingCurrency;
				Else
					PostingMovement.GrosAmount = 0;
				EndIf;
				
				If IsBlankString(vPostingsRow.PostingDescriptionTemplate) Then
					PostingMovement.Description = TrimAll(pService);
				Else
					SetSafeMode(True);
					Execute("PostingMovement.Description = " + cmGetPostingDescriptionByTemplate(vPostingsRow.PostingDescriptionTemplate) + ";");
					SetSafeMode(False);
				EndIf;
				
				PostingMovement.Period = BegOfDay(Date);
				PostingMovement.FODate = BegOfDay(Date);
				PostingMovement.ServiceDate = ServiceDate;
				PostingMovement.Days = 0;
				
				PostingMovement.ParentDoc = ParentDoc;
				
				PostingMovement.Room = Room;
				PostingMovement.Resource = Resource;
				
				PostingMovement.Service = pService;
				PostingMovement.PaymentMethod = Undefined;
				PostingMovement.AccountingCustomer = Undefined;
					
				PostingMovement.AccountGroup = vPostingAccount.AccountGroup;
				PostingMovement.AccountType = vPostingAccount.AccountType;
				PostingMovement.Department = vPostingAccount.Department;
				PostingMovement.DiscountType = vPostingAccount.DiscountType;
				PostingMovement.ServiceType = vPostingAccount.ServiceType;
				
				PostingMovement.Hotel = Hotel;
				PostingMovement.Company = Company;
				PostingMovement.Currency = vAccountCurrency;
				
				If vThisIsMainAccountPosting Then
					PostingMovement.Discount = Discount;
					PostingMovement.DiscountAmount = vSrvDiscountSumInPostingCurrency - vSrvVATDiscountSumInPostingCurrency;
				Else
					PostingMovement.Discount = 0;
					PostingMovement.DiscountAmount = 0;
				EndIf;
				
				If Not vPostingAccount.IsVATAccount Then
					If ValueIsFilled(vPostingsRow.VATRate) Then
						PostingMovement.VATRate = vPostingsRow.VATRate;
					Else
						PostingMovement.VATRate = vSrvVATRate;
					EndIf;
					If vThisIsMainAccountPosting Then
						PostingMovement.VATAmount = vPostingsVATSumInPostingCurrency;
					Else
						PostingMovement.VATAmount = cmCalculateVATSum(PostingMovement.VATRate, PostingMovement.Amount, PostingMovement.FODate, True);
					EndIf;
					vPostingsVATSumInPostingCurrency = vPostingsVATSumInPostingCurrency - PostingMovement.VATAmount;
				Else
					PostingMovement.VATRate = vSrvVATRate;
					PostingMovement.VATAmount = PostingMovement.Amount;
				EndIf;
				
				PostingMovement.POSTicket = pPOSTicket;
				PostingMovement.Invoice = Undefined;
				
				PostingMovement.Recorder = Ref;
				PostingMovement.Author = Author;
				
				If vRestOfPostingAmount = 0 Then
					Break;
				EndIf;
			EndIf;	
		EndDo;
		
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
		PostingMovement.CorrAccount = vClosingAccount;
		
		PostingMovement.Amount = vCorrespondingAccountPostingAmount;
		PostingMovement.GrosAmount = 0;
		
		PostingMovement.Description = TrimAll(pService);
		
		PostingMovement.Period = BegOfDay(Date);
		PostingMovement.FODate = BegOfDay(Date);
		PostingMovement.ServiceDate = ServiceDate;
		PostingMovement.Days = 0;
					
		PostingMovement.ParentDoc = ParentDoc;
		
		PostingMovement.Room = Room;
		PostingMovement.Resource = Resource;
		
		PostingMovement.Service = pService;
		PostingMovement.PaymentMethod = Undefined;
		PostingMovement.AccountingCustomer = Undefined;
			
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
		PostingMovement.VATRate = vSrvVATRate;
		
		PostingMovement.POSTicket = pPOSTicket;
		PostingMovement.Invoice = Undefined;
		
		PostingMovement.Recorder = Ref;
		PostingMovement.Author = Author;
		
		// Create movement to discounts income account
		If pIsDiscounted And ValueIsFilled(vAccount.DiscountIncomeAccount) Then
			vPostingAccount = vAccount.DiscountIncomeAccount;
			
			vGrosSumInPostingCurrency = vSrvDiscountSumInPostingCurrency;
			vPostingAmount = vSrvDiscountSumInPostingCurrency;
			
			// Create movement for this item service
			If vPostingAmount <> 0 Then
				PostingMovement = Undefined;
				If vReverseSign Then
					PostingMovement = RegisterRecords.PostingsFO.AddCredit();
				Else
					PostingMovement = RegisterRecords.PostingsFO.AddDebit();
				EndIf;
				
				PostingMovement.Active = True;
				
				PostingMovement.Account = vPostingAccount;
				PostingMovement.CorrAccount = vClosingAccount;
				
				PostingMovement.Amount = vPostingAmount;
				PostingMovement.GrosAmount = vGrosSumInPostingCurrency;
				
				PostingMovement.VATRate = vSrvVATRate;
				PostingMovement.VATAmount = 0;
				
				PostingMovement.Description = NStr("en='Discount '; ru='Скидка '; de='Rabatt '") + String(Discount) + "%";
				
				PostingMovement.Period = BegOfDay(Date);
				PostingMovement.FODate = BegOfDay(Date);
				PostingMovement.ServiceDate = ServiceDate;
				PostingMovement.Days = 0;
				
				PostingMovement.ParentDoc = ParentDoc;
				
				PostingMovement.Room = Room;
				PostingMovement.Resource = Resource;
				
				PostingMovement.Service = pService;
				PostingMovement.PaymentMethod = Undefined;
				PostingMovement.AccountingCustomer = Undefined;
					
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
				
				PostingMovement.POSTicket = pPOSTicket;
				PostingMovement.Invoice = Undefined;
				
				PostingMovement.Recorder = Ref;
				PostingMovement.Author = Author;
			EndIf;		
		EndIf;		
	EndIf;
	
	RegisterRecords.PostingsFO.Write = True;
EndProcedure // PostToFOChartOfAccounts

// -----------------------------------------------------------------------------
Procedure PostToHotelProductSales(pService, pVATRate = Undefined)
	vSrvVATRate = ?(ValueIsFilled(pVATRate), pVATRAte, VATRate);

	vDate = Date;
	If IsCorrection Then
		vDate = CorrectionDate;
	EndIf;
	
	vGuestGroup = GetEffectiveGuestGroup();
	
	Movement = RegisterRecords.HotelProductSales.Add();
	
	If ValueIsFilled(HotelProduct) And ValueIsFilled(HotelProduct.CheckInDate) And HotelProduct.FixProductPeriod Then
		Movement.Period = BegOfDay(HotelProduct.CheckInDate);
	ElsIf ValueIsFilled(vParentDoc) Then
		If (TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or 
			TypeOf(vParentDoc) = Type("DocumentRef.Reservation")) And 
		   ValueIsFilled(vParentDoc.CheckInDate) Then
			Movement.Period = BegOfDay(vParentDoc.CheckInDate);
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Folio") And 
			  ValueIsFilled(vParentDoc.DateTimeFrom) Then
			Movement.Period = BegOfDay(vParentDoc.DateTimeFrom);
		Else
			Movement.Period = vDate;
		EndIf;
	Else
		Movement.Period = vDate;
	EndIf;
	
	Movement.ParentDoc = vParentDoc;
	
	FillPropertyValues(Movement, vParentDoc, , "ParentDoc");
	FillPropertyValues(Movement, ThisObject, , "ParentDoc");
	Movement.Service = pService;
	Movement.VATRate = vSrvVATRate;
	
	// Fill room rate, accommodation type, room and room type
	If ValueIsFilled(vParentDoc) Then
		If TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
			If Not ValueIsFilled(Room) Then
				Movement.Room = vParentDoc.Room;
			EndIf;
			If Not ValueIsFilled(RoomType) Then
				Movement.RoomType = vParentDoc.RoomType;
			EndIf;
			If Not ValueIsFilled(AccommodationType) Then
				Movement.AccommodationType = vParentDoc.AccommodationType;
			EndIf;
			If Not ValueIsFilled(RoomRate) Then
				Movement.RoomRate = vParentDoc.RoomRate;
			EndIf;
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Folio") Then
			If Not ValueIsFilled(Room) Then
				Movement.Room = vParentDoc.Room;
			EndIf;
		EndIf;
	EndIf;
	
	Movement.Sales = vSumInReportingCurrency;
	Movement.SalesWithoutVAT = vSumInReportingCurrency - vVATSumInReportingCurrency;
	If IsRoomRevenue Then
		Movement.RoomRevenue = vSumInReportingCurrency;
		Movement.RoomRevenueWithoutVAT = vSumInReportingCurrency - vVATSumInReportingCurrency;
	Else
		Movement.RoomRevenue = 0;
		Movement.RoomRevenueWithoutVAT = 0;
	EndIf;
	If Movement.AdditionalBedsRented <> 0 Then
		Movement.ExtraBedRevenue = vSumInReportingCurrency;
		Movement.ExtraBedRevenueWithoutVAT = vSumInReportingCurrency - vVATSumInReportingCurrency;
	Else
		Movement.ExtraBedRevenue = 0;
		Movement.ExtraBedRevenueWithoutVAT = 0;
	EndIf;
	Movement.DiscountSum = vDiscountSumInReportingCurrency;
	Movement.DiscountSumWithoutVAT = vDiscountSumInReportingCurrency - vVATDiscountSumInReportingCurrency;
	Movement.CommissionSum = vCommissionSumInReportingCurrency;
	Movement.CommissionSumWithoutVAT = vCommissionSumInReportingCurrency - vVATCommissionSumInReportingCurrency;
	
	Movement.BookingWindow = 0;
	Movement.RoomsCheckedIn = 0;
	Movement.BedsCheckedIn = 0;
	Movement.AdditionalBedsCheckedIn = 0;
	If Movement.GuestsCheckedIn <> 0 And Movement.Quantity <> 0 Then
		If ValueIsFilled(ParentDoc) Then
			If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
				Movement.RoomsCheckedIn = Movement.RoomsRented;
				Movement.BedsCheckedIn = Movement.BedsRented;
				Movement.AdditionalBedsCheckedIn = Movement.AdditionalBedsRented;
			EndIf;
			If Movement.RoomsCheckedIn <> 0 Then
				If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") And ValueIsFilled(ParentDoc.Reservation) Then
					Movement.BookingWindow = Round((BegOfDay(ParentDoc.CheckInDate) - BegOfDay(ParentDoc.Reservation.Date))/(24*3600), 0);
				ElsIf TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
					Movement.BookingWindow = Round((BegOfDay(ParentDoc.CheckInDate) - BegOfDay(ParentDoc.Date))/(24*3600)*?(Movement.RoomsCheckedIn > 1, Movement.RoomsCheckedIn, 1), 0);
				ElsIf TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
					Movement.BookingWindow = Round((BegOfDay(ParentDoc.DateTimeFrom) - BegOfDay(ParentDoc.Date))/(24*3600), 0);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Movement.Client = vClient;
	
	Movement.AccountingDate = BegOfDay(vDate);
	Movement.Price = cmRecalculatePrice(vSumInReportingCurrency, Quantity);
	Movement.IsStorno = False;
	
	// Fill customer, contract, guest group, agent from the folio
	Movement.Customer = Folio.Customer;
	Movement.Contract = Folio.Contract;
	Movement.Agent = Folio.Agent;
	Movement.PaymentMethod = Folio.PaymentMethod;
	Movement.GuestGroup = vGuestGroup;
	
	// Fill individuals customer and customer contract if specified
	If Not ValueIsFilled(Movement.Customer) And ValueIsFilled(Hotel.IndividualsCustomer) And ValueIsFilled(Hotel.IndividualsContract) Then
		Movement.Customer = Hotel.IndividualsCustomer;
		Movement.Contract = Hotel.IndividualsContract;
	EndIf;
	
	RegisterRecords.HotelProductSales.Write = True;
	
	// Write to the hotel product log
	RegisterRecords.HotelProductLog.Clear();
	
	LogMovement = RegisterRecords.HotelProductLog.AddReceipt();
	
	FillPropertyValues(LogMovement, ThisObject);
	LogMovement.Period = ?(ValueIsFilled(HotelProduct.CreateDate), HotelProduct.CreateDate, vDate);
	LogMovement.Sum = Sum - DiscountSum;
	
	RegisterRecords.HotelProductLog.Write = True;
EndProcedure // PostToHotelProductSales

// -----------------------------------------------------------------------------
Procedure PostToAnaliticalRegisters(pService, pQuantity, pSum, pDiscountSum, pVATDiscountSum, pCommissionSum, pVATCommissionSum, pVATSum, pRateSum, pRateDiscountSum, pVATRate = Undefined)
	vSrvVATRate = ?(ValueIsFilled(pVATRate), pVATRate, VATRate);
	
	// Fill parent doc	
	vParentDoc = ParentDoc;
	If Not ValueIsFilled(vParentDoc) Or TypeOf(vParentDoc) = Type("DocumentRef.CloseOfPeriod") Then
		vParentDoc = Folio;
	EndIf;
	
	vClient = Catalogs.Clients.EmptyRef();
	vStruct = New Structure("Client", Undefined);
	FillPropertyValues(vStruct, vParentDoc);
	If ValueIsFilled(vStruct.Client) Then
		vClient = vStruct.Client;
	Else
		If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
			vClient = vParentDoc.Guest;
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then 
			vClient = vParentDoc.Guest;
		ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then 
			vClient = vParentDoc.Client;
		EndIf;
	EndIf;
	
	// Fill resources in reporting currency
	vSumInReportingCurrency = Round(cmConvertCurrencies(pSum - pDiscountSum, FolioCurrency, FolioCurrencyExchangeRate, ReportingCurrency, ReportingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	vVATSumInReportingCurrency = cmCalculateVATSum(vSrvVATRate, vSumInReportingCurrency, Date);
	vDiscountSumInReportingCurrency = Round(cmConvertCurrencies(pDiscountSum, FolioCurrency, FolioCurrencyExchangeRate, ReportingCurrency, ReportingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	vVATDiscountSumInReportingCurrency = cmCalculateVATSum(vSrvVATRate, vDiscountSumInReportingCurrency, Date);
	vCommissionSumInReportingCurrency = Round(cmConvertCurrencies(pCommissionSum, FolioCurrency, FolioCurrencyExchangeRate, ReportingCurrency, ReportingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	vVATCommissionSumInReportingCurrency = cmCalculateVATSum(vSrvVATRate, vCommissionSumInReportingCurrency, Date);
	vRateSumInReportingCurrency = Round(cmConvertCurrencies((pRateSum - pRateDiscountSum), FolioCurrency, FolioCurrencyExchangeRate, ReportingCurrency, ReportingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	vRateDiscountSumInReportingCurrency = Round(cmConvertCurrencies(pRateDiscountSum, FolioCurrency, FolioCurrencyExchangeRate, ReportingCurrency, ReportingCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	vVATRateSumInReportingCurrency = cmCalculateVATSum(vSrvVATRate, vRateSumInReportingCurrency, Date);
	
	// Post to the sales
	PostToSales(pService, vSrvVATRate);
	
	// Post to the hotel product sales
	If ValueIsFilled(HotelProduct) And ValueIsFilled(Service) And Service.IsHotelProductService And Not Service.IsNotInvoiced Then
		PostToHotelProductSales(pService, vSrvVATRate);
	EndIf;
EndProcedure // PostToAnaliticalRegisters

// -----------------------------------------------------------------------------
Procedure PostToServiceRegistration(pService, pSum, pDiscountSum, pQuantity, pParentDoc = Undefined, pClient = Undefined, pServiceDate = Undefined)
	vDate = Date;
	If IsCorrection Then
		vDate = CorrectionDate;
	EndIf;
	
	If ValueIsFilled(pServiceDate) Then
		vServiceDate = pServiceDate;  
	ElsIf ValueIsFilled(ServiceDate) Then
		vServiceDate = ServiceDate;
	Else
		vServiceDate = vDate;	
	EndIf;	
	Movement = RegisterRecords.ServiceRegistration.Add();
	
	Movement.RecordType = AccumulationRecordType.Receipt;
	Movement.Period = vServiceDate;
	
	FillPropertyValues(Movement, Folio);
	If ValueisFilled(?(ValueIsFilled(pParentDoc), pParentDoc, ParentDoc)) Then
		FillPropertyValues(Movement, ?(ValueIsFilled(pParentDoc), pParentDoc, ParentDoc));
	EndIf;
	FillPropertyValues(Movement, ThisObject);
	Movement.Service = ?(pService = Undefined, Service, pService);
	Movement.GuestGroup = GetEffectiveGuestGroup();
	
	// Fill accounting date
	Movement.AccountingDate = BegOfDay(Movement.Period);
	
	// Fill resource
	If ValueIsFilled(ParentDoc) Then
		If TypeOf(ParentDoc) = Type("DocumentRef.ResourceReservation") Then
			If Not ValueIsFilled(Resource) Then
				Movement.Resource = ParentDoc.Resource;
			EndIf;
		EndIf;
	EndIf;
	
	// Fill room and client
	If ValueIsFilled(pParentDoc) Then
		If TypeOf(pParentDoc) = Type("DocumentRef.Reservation") Or 
		   TypeOf(pParentDoc) = Type("DocumentRef.Accommodation") Then
			Movement.Client = pParentDoc.Guest;
			If Not ValueIsFilled(Room) Then
				Movement.Room = pParentDoc.Room;
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(ParentDoc) Then
			If TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or 
			   TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
				If Not ValueIsFilled(Room) Then
					Movement.Room = ParentDoc.Room;
				EndIf;
			EndIf;
		Else
			If Not ValueIsFilled(Room) Then
				Movement.Room = Folio.Room;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(pClient) Then
		Movement.Client = pClient;
	EndIf;
	
	// Resources
	Movement.Sum = Round(cmConvertCurrencies(pSum - pDiscountSum, ReportingCurrency, ReportingCurrencyExchangeRate, FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
	Movement.Quantity = pQuantity;
	
	// Attributes
	Movement.Price = cmRecalculatePrice(Movement.Sum, Movement.Quantity);
	
	RegisterRecords.ServiceRegistration.Write = True;
EndProcedure // PostToServiceRegistration

// -----------------------------------------------------------------------------
Function GetBoundServiceTurnover(pService, rQuantity)
	vTurnover = 0;
	rQuantity = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesTurnovers.Service,
	|	SalesTurnovers.SalesTurnover AS SumTurnover,
	|	SalesTurnovers.QuantityTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			Folio = &qFolio
	|				AND Service = &qService) AS SalesTurnovers";
	vQry.SetParameter("qPeriodFrom", '00010101');
	vQry.SetParameter("qPeriodTo", '00010101');
	vQry.SetParameter("qService", pService);
	vQry.SetParameter("qFolio", Folio);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vTurnover = vTurnover + vQryResRow.SumTurnover;
		rQuantity = rQuantity + vQryResRow.QuantityTurnover;
	EndDo;
	Return vTurnover;
EndFunction // GetBoundServiceTurnover

// -----------------------------------------------------------------------------
Procedure PostOrderItemsToSalesAndAccounts(pOrderItems, pOrderCurrency)
	If Sum = 0 Or (Not Hotel.SplitFolioBalanceByPaymentSections And Not Hotel.SplitFolioBalanceByServicesAndPrices) Then
		// 4. Post to Accounts
		PostToAccounts(Service, Quantity, Sum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, VATSum);
	EndIf;
	If Sum = 0 Then
		// 5. Fill analitics
		PostToAnaliticalRegisters(Service, Quantity, Sum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, VATSum, RateSum, RateDiscountSum);
	EndIf;
		
	vOrderServices = pOrderItems.Copy();

	vOrderItemsTotalSum = 0;
	vOrderItemsTotalDiscountSum = 0;
	vOrderItemsTotalVATDiscountSum = 0;
	vOrderItemsTotalCommissionSum = 0;
	vOrderItemsTotalVATCommissionSum = 0;
	vOrderItemsTotalVATSum = 0;

	vDiscountSum = DiscountSum;
	vVATDiscountSum = VATDiscountSum;
	vCommissionSum = CommissionSum;
	vVATCommissionSum = VATCommissionSum;
	vVATSum = VATSum;
	For Each vOrderServicesRow In vOrderServices Do
		vOrderItemService = ?(ValueIsFilled(vOrderServicesRow.Service), vOrderServicesRow.Service, Service);
		vOrderItemVATRate = ?(ValueIsFilled(vOrderServicesRow.VATRate), vOrderServicesRow.VATRate, VATRate);
		vOrderItemQuantity = vOrderServicesRow.Quantity;
		vOrderItemSum = Round(cmConvertCurrencies(vOrderServicesRow.Sum, pOrderCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
		vOrderItemVATSum = cmCalculateVATSum(vOrderItemVATRate, vOrderItemSum, Date);
		
		vK = 1;
		If Sum <> 0 Then
			vK = vOrderItemSum/Sum;
		EndIf;
		
		If vOrderServices.IndexOf(vOrderServicesRow) < (vOrderServices.Count() - 1) Then
			vOrderItemDiscountSum = Round(DiscountSum*vK, 2);
			vOrderItemVATDiscountSum = cmCalculateVATSum(vOrderItemVATRate, vOrderItemDiscountSum, Date);
			vOrderItemCommissionSum = Round(CommissionSum*vK, 2);
			vOrderItemVATCommissionSum = cmCalculateVATSum(vOrderItemVATRate, vOrderItemCommissionSum, Date);
			
			vDiscountSum = vDiscountSum - vOrderItemDiscountSum;
			vVATDiscountSum = vVATDiscountSum - vOrderItemVATDiscountSum;
			vCommissionSum = vCommissionSum - vOrderItemCommissionSum;
			vVATCommissionSum = vVATCommissionSum - vOrderItemVATCommissionSum;
			vVATSum = vVATSum - vOrderItemVATSum;
		Else
			vOrderItemDiscountSum = vDiscountSum;
			vOrderItemVATDiscountSum = cmCalculateVATSum(vOrderItemVATRate, vOrderItemDiscountSum, Date);
			vOrderItemCommissionSum = vCommissionSum;
			vOrderItemVATCommissionSum = cmCalculateVATSum(vOrderItemVATRate, vOrderItemCommissionSum, Date);
		EndIf;
		
		vOrderItemsTotalSum = vOrderItemsTotalSum + vOrderItemSum;
		vOrderItemsTotalDiscountSum = vOrderItemsTotalDiscountSum + vOrderItemDiscountSum;
		vOrderItemsTotalVATDiscountSum = vOrderItemsTotalVATDiscountSum + vOrderItemVATDiscountSum;
		vOrderItemsTotalCommissionSum = vOrderItemsTotalCommissionSum + vOrderItemCommissionSum;
		vOrderItemsTotalVATCommissionSum = vOrderItemsTotalVATCommissionSum + vOrderItemVATCommissionSum; 
		vOrderItemsTotalVATSum = vOrderItemsTotalVATSum + vOrderItemVATSum;
		
		// 4. Post to Accounts
		If Sum <> 0 And Hotel.SplitFolioBalanceByPaymentSections Then
			PostToAccounts(vOrderItemService, vOrderItemQuantity, vOrderItemSum, vOrderItemDiscountSum, vOrderItemVATDiscountSum, vOrderItemCommissionSum, vOrderItemVATCommissionSum, vOrderItemVATSum);
		ElsIf (Sum <> 0 Or Not IsBlankString(MarkingCode)) And Hotel.SplitFolioBalanceByServicesAndPrices Then
			PostToAccounts(vOrderItemService, vOrderItemQuantity, vOrderItemSum, vOrderItemDiscountSum, vOrderItemVATDiscountSum, vOrderItemCommissionSum, vOrderItemVATCommissionSum, vOrderItemVATSum, vOrderItemVATRate, vOrderServicesRow.MarkingCode, vOrderServicesRow.Item);
		EndIf;
		
		// 5. Fill analitics
		If Sum <> 0 Then
			PostToAnaliticalRegisters(vOrderItemService, vOrderItemQuantity, vOrderItemSum, vOrderItemDiscountSum, vOrderItemVATDiscountSum, vOrderItemCommissionSum, vOrderItemVATCommissionSum, vOrderItemVATSum, 0, 0, vOrderItemVATRate);
		EndIf;
	EndDo;

	// Do correction movements 
	If Sum <> vOrderItemsTotalSum Then
		vCorrectionSum = Sum - vOrderItemsTotalSum;
		vCorrectionVATSum = cmCalculateVATSum(VATRate, vCorrectionSum, Date);
		vCorrectionDiscountSum = DiscountSum - vOrderItemsTotalDiscountSum;
		vCorrectionVATDiscountSum = cmCalculateVATSum(VATRate, vCorrectionDiscountSum, Date);
		vCorrectionCommissionSum = CommissionSum - vOrderItemsTotalCommissionSum;
		vCorrectionVATCommissionSum = cmCalculateVATSum(VATRate, vCorrectionCommissionSum, Date);
		
		vSign = 1;
		If Quantity > 0 And vCorrectionSum < 0 Then
			vSign = -1;
		ElsIf Quantity < 0 And vCorrectionSum > 0 Then
			vSign = -1;
		EndIf;
		
		// 4. Post to Accounts
		If Sum <> 0 And (Hotel.SplitFolioBalanceByPaymentSections Or Hotel.SplitFolioBalanceByServicesAndPrices) Then
			PostToAccounts(Service, vSign * Quantity, vCorrectionSum, vCorrectionDiscountSum, vCorrectionVATDiscountSum, vCorrectionCommissionSum, vCorrectionVATCommissionSum, vCorrectionVATSum);
		EndIf;
		
		// 5. Fill analitics
		If Sum <> 0 Then
			PostToAnaliticalRegisters(Service, vSign * Quantity, vCorrectionSum, vCorrectionDiscountSum, vCorrectionVATDiscountSum, vCorrectionCommissionSum, vCorrectionVATCommissionSum, vCorrectionVATSum, RateSum, RateDiscountSum);
		EndIf;
	EndIf;
EndProcedure // PostOrderItemsToSalesAndAccounts

// -----------------------------------------------------------------------------
Procedure PostOrderItemsToFOChartOfAccounts(pOrderItems, pOrderCurrency, pPOSTicket = "", pOrderIsComplimentary = False, pOrderIsDiscounted = False)
	vOrderItemsTotalSum = 0;
	vOrderItemsTotalDiscountSum = 0;
	vOrderItemsTotalVATDiscountSum = 0;
	vOrderItemsTotalCommissionSum = 0;
	vOrderItemsTotalVATCommissionSum = 0;
	vOrderItemsTotalVATSum = 0;

	vSum = Sum;
	vDiscountSum = DiscountSum;
	vVATDiscountSum = VATDiscountSum;
	vCommissionSum = CommissionSum;
	vVATCommissionSum = VATCommissionSum;
	vVATSum = VATSum;
	vChargeVATSum = VATSum;
	
	// If order is complimentary then recalculate order total amount and VAT amount based on items amount
	If pOrderIsComplimentary Then
		vSum = Round(cmConvertCurrencies(pOrderItems.Total("Sum"), pOrderCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
		vVATSum = 0;
		For Each vOrderItemsRow In pOrderItems Do
			vOrderItemVATRate = ?(ValueIsFilled(vOrderItemsRow.VATRate), vOrderItemsRow.VATRate, VATRate);
			vVATSum = vVATSum + Round(cmConvertCurrencies(cmCalculateVATSum(vOrderItemVATRate, vOrderItemsRow.Sum, Date), pOrderCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
		EndDo;
		vChargeVATSum = vVATSum;
	EndIf;
	
	For Each vOrderItemsRow In pOrderItems Do
		vOrderItemService = ?(ValueIsFilled(vOrderItemsRow.Service), vOrderItemsRow.Service, Service);
		vOrderItemVATRate = ?(ValueIsFilled(vOrderItemsRow.VATRate), vOrderItemsRow.VATRate, VATRate);
		vOrderItemQuantity = vOrderItemsRow.Quantity;
		vOrderItemSum = Round(cmConvertCurrencies(vOrderItemsRow.Sum, pOrderCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
		vOrderItemVATSum = cmCalculateVATSum(vOrderItemVATRate, vOrderItemSum, Date);
		
		vK = 1;
		If vSum <> 0 Then
			vK = vOrderItemSum/vSum;
		EndIf;

		If pOrderItems.IndexOf(vOrderItemsRow) < (pOrderItems.Count() - 1) Then
			vOrderItemDiscountSum = Round(DiscountSum*vK, 2);
			vOrderItemVATDiscountSum = cmCalculateVATSum(vOrderItemVATRate, vOrderItemDiscountSum, Date);
			vOrderItemCommissionSum = Round(CommissionSum*vK, 2);
			vOrderItemVATCommissionSum = cmCalculateVATSum(vOrderItemVATRate, vOrderItemCommissionSum, Date);
			
			vDiscountSum = vDiscountSum - vOrderItemDiscountSum;
			vVATDiscountSum = vVATDiscountSum - vOrderItemVATDiscountSum;
			vCommissionSum = vCommissionSum - vOrderItemCommissionSum;
			vVATCommissionSum = vVATCommissionSum - vOrderItemVATCommissionSum;
			vVATSum = vVATSum - vOrderItemVATSum;
		Else
			vOrderItemDiscountSum = vDiscountSum;
			vOrderItemVATDiscountSum = cmCalculateVATSum(vOrderItemVATRate, vOrderItemDiscountSum, Date);
			vOrderItemCommissionSum = vCommissionSum;
			vOrderItemVATCommissionSum = cmCalculateVATSum(vOrderItemVATRate, vOrderItemCommissionSum, Date);
		EndIf;
		
		vOrderItemsTotalSum = vOrderItemsTotalSum + vOrderItemSum;
		vOrderItemsTotalDiscountSum = vOrderItemsTotalDiscountSum + vOrderItemDiscountSum;
		vOrderItemsTotalVATDiscountSum = vOrderItemsTotalVATDiscountSum + vOrderItemVATDiscountSum;
		vOrderItemsTotalCommissionSum = vOrderItemsTotalCommissionSum + vOrderItemCommissionSum;
		vOrderItemsTotalVATCommissionSum = vOrderItemsTotalVATCommissionSum + vOrderItemVATCommissionSum; 
		vOrderItemsTotalVATSum = vOrderItemsTotalVATSum + vOrderItemVATSum;
		
		// Do postings to the chart of accounts
		PostToFOChartOfAccounts(vOrderItemService, vOrderItemQuantity, vOrderItemSum, vOrderItemDiscountSum, vOrderItemVATDiscountSum, vOrderItemCommissionSum, vOrderItemVATCommissionSum, vOrderItemVATSum, pPOSTicket, False, pOrderIsComplimentary, pOrderIsDiscounted, vOrderItemVATRate);
	EndDo;

	// Do correction movements 
	If vSum <> vOrderItemsTotalSum Then
		vCorrectionSum = vSum - vOrderItemsTotalSum;
		vCorrectionVATSum = cmCalculateVATSum(VATRate, vCorrectionSum, Date);
		vCorrectionDiscountSum = DiscountSum - vOrderItemsTotalDiscountSum;
		vCorrectionVATDiscountSum = cmCalculateVATSum(VATRate, vCorrectionDiscountSum, Date);
		vCorrectionCommissionSum = CommissionSum - vOrderItemsTotalCommissionSum;
		vCorrectionVATCommissionSum = cmCalculateVATSum(VATRate, vCorrectionCommissionSum, Date);
		
		vSign = 1;
		If Quantity > 0 And vCorrectionSum < 0 Then
			vSign = -1;
		ElsIf Quantity < 0 And vCorrectionSum > 0 Then
			vSign = -1;
		EndIf;
		
		// Do postings to the chart of accounts
		PostToFOChartOfAccounts(Service, vSign * Quantity, vCorrectionSum, vCorrectionDiscountSum, vCorrectionVATDiscountSum, vCorrectionCommissionSum, vCorrectionVATCommissionSum, vCorrectionVATSum, pPOSTicket, True, pOrderIsComplimentary, pOrderIsDiscounted);
	EndIf;
EndProcedure // PostOrderItemsToFOChartOfAccounts

// -----------------------------------------------------------------------------
Procedure AddUserLog(pEventDescription)  
	vParentDoc = Ref;   
	If ValueIsFilled(ParentDoc) Then
		vParentDoc = ParentDoc; 
	ElsIf Not ValueIsFilled(ParentDoc) And IsNew() Then 
		vParentDoc = Documents.Charge.GetRef(New UUID);
		SetNewObjectRef(vParentDoc);	
	EndIf;	
	InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, pEventDescription, Hotel);
EndProcedure // AddUserLog

#EndRegion
