
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	If Not IsFolder Then
		Author = SessionParameters.CurrentUser;
		CreateDate = CurrentSessionDate();
		AuthorOfAnnulation = Undefined;
		DateOfAnnulation = '00010101';
		AnnulationReason = Undefined;
		If AllotmentType = Enums.AllotmentTypes.Cancelled Then
			If AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
				AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed;
			Else
				AllotmentType = Enums.AllotmentTypes.Definite;
			EndIf;
		EndIf;
		// Clear set room quota documents
		For Each vRow In RoomTypes Do
			vRow.SetRoomQuota = Documents.SetRoomQuota.EmptyRef();
		EndDo;
		// Clear budget fields
		BudgetAmount = 0;
		BudgetReservationAmount = 0;
		BudgetMICEAmount = 0;
		BudgetADR = 0;
		RoomNights = 0;
	EndIf;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(Ref) And DeletionMark <> Ref.DeletionMark Then
		If AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToManageAllotments") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage allotments!';
			                                                |ru='Нет прав на управление квотами!';
															|de='Sie haben keine Rechte, Allotmenten zu verwalten!'"));
		ElsIf AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock And Not cmCheckUserPermissions("HavePermissionToSetDeletionMarkForBusinessBlocks") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to delete business blocks! Use <Cancel business block> function instead';
			                                                |ru='Нет прав на удаление бизнес-блоков! Используйте функцию отмены бизнес блока';
															|de='Sie haben keine Rechte, Geschäftsblock zu löschen! Verwenden Sie stattdessen die Funktion <Geschäftsblock stornieren>'"));
		ElsIf Not IsFolder Then
			If Not DeletionMark And AllotmentType <> Enums.AllotmentTypes.Cancelled Then
				If ValueIsFilled(AuthorOfAnnulation) Then
					AuthorOfAnnulation = Undefined;
				EndIf;
				If ValueIsFilled(DateOfAnnulation) Then
					DateOfAnnulation = Undefined;
				EndIf;
				If ValueIsFilled(AnnulationReason) Then
					AnnulationReason = Undefined;
				EndIf;
			Else
				If Not ValueIsFilled(AuthorOfAnnulation) Then
					AuthorOfAnnulation = SessionParameters.CurrentUser;
				EndIf;
				If Not ValueIsFilled(DateOfAnnulation) Then
					DateOfAnnulation = CurrentSessionDate();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If DeletionMark Or AllotmentType = Enums.AllotmentTypes.Cancelled Then
		vAllAllomentDocs = pmGetAllotmentDocuments();
		For Each vDocsRow In vAllAllomentDocs Do
			If TypeOf(vDocsRow.Ref) = Type("DocumentRef.SetRoomQuota") Then
				vDocObj = vDocsRow.Ref.GetObject();
				If Not vDocObj.DeletionMark Then
					vDocObj.AdditionalProperties.Insert("SkipAllotmentUpdate", True);
					vDocObj.SetDeletionMark(True);
				EndIf;
			ElsIf TypeOf(vDocsRow.Ref) = Type("DocumentRef.Reservation") Then
				vDocObj = vDocsRow.Ref.GetObject();
				vDocObj.RoomQuota = Undefined;
				vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
				vDocObj.Write(DocumentWriteMode.Posting);
				vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			ElsIf TypeOf(vDocsRow.Ref) = Type("DocumentRef.Accommodation") Then
				vDocObj = vDocsRow.Ref.GetObject();
				vDocObj.RoomQuota = Undefined;
				vDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
				vDocObj.Write(DocumentWriteMode.Posting);
				vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
		EndDo;
	Else
		For Each vRTRow In RoomTypes Do
			If ValueIsFilled(vRTRow.SetRoomQuota) Then
				vDocRef = vRTRow.SetRoomQuota;
				If vDocRef.DeletionMark Then
					vDocObj = vDocRef.GetObject();
					vDocObj.DeletionMark = False;
					vDocObj.AdditionalProperties.Insert("SkipAllotmentUpdate", True);
					vDocObj.Write(DocumentWriteMode.Posting);
				EndIf;
			EndIf;
		EndDo;
	EndIf;        
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	Hotel = SessionParameters.CurrentHotel;
	Author = SessionParameters.CurrentUser;
	CreateDate = CurrentSessionDate();
	If Not ValueIsFilled(AllotmentType) Then
		If AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
			AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed;
		Else
			AllotmentType = Enums.AllotmentTypes.Definite;
		EndIf;
		DoWriteOff = True;
		TreatAsTentativeBooking = False;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetIntersectingCheckInPeriods(pPeriodFrom, pPeriodTo, pHotel = Undefined) Export
	// Try to find intersecting periods 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AllotmentCheckInPeriods.Hotel AS Hotel,
	|	AllotmentCheckInPeriods.RoomQuota.RoomRate AS RoomRate,
	|	AllotmentCheckInPeriods.RoomQuota AS RoomQuota,
	|	AllotmentCheckInPeriods.CheckInDate AS CheckInDate,
	|	AllotmentCheckInPeriods.Duration AS Duration,
	|	AllotmentCheckInPeriods.CheckOutDate AS CheckOutDate
	|FROM
	|	InformationRegister.RoomQuotaCheckInPeriods AS AllotmentCheckInPeriods
	|WHERE
	|	AllotmentCheckInPeriods.Hotel = &qHotel
	|	AND AllotmentCheckInPeriods.RoomQuota = &qAllotment
	|	AND AllotmentCheckInPeriods.CheckInDate < &qCheckOutDate
	|	AND AllotmentCheckInPeriods.CheckOutDate > &qCheckInDate
	|	AND NOT AllotmentCheckInPeriods.IsNotActive
	|
	|ORDER BY
	|	AllotmentCheckInPeriods.CheckInDate,
	|	AllotmentCheckInPeriods.Duration";
	vQry.SetParameter("qHotel", ?(ValueIsFilled(pHotel), pHotel, Hotel));
	vQry.SetParameter("qAllotment", Ref);
	vQry.SetParameter("qCheckInDate", cm0SecondShift(pPeriodFrom));
	vQry.SetParameter("qCheckOutDate", cm0SecondShift(pPeriodTo));
	vPeriods = vQry.Execute().Unload();
	Return vPeriods;
EndFunction // pmGetIntersectingCheckInPeriods

// -----------------------------------------------------------------------------
Function pmGetAllotmentDocuments() Export
	// Try to find intersecting periods 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SetRoomQuota.Ref AS Ref,
	|	SetRoomQuota.PointInTime AS PointInTime
	|FROM
	|	Document.SetRoomQuota AS SetRoomQuota
	|WHERE
	|	SetRoomQuota.Posted
	|	AND SetRoomQuota.RoomQuota = &qAllotment
	|
	|UNION ALL
	|
	|SELECT
	|	Reservations.Ref,
	|	Reservations.PointInTime
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Posted
	|	AND Reservations.RoomQuota = &qAllotment
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|
	|UNION ALL
	|
	|SELECT
	|	Accommodations.Ref,
	|	Accommodations.PointInTime
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.RoomQuota = &qAllotment
	|	AND Accommodations.AccommodationStatus.IsActive
	|
	|ORDER BY
	|	SetRoomQuota.PointInTime";
	vQry.SetParameter("qAllotment", Ref);
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // pmGetAllotmentDocuments

// -----------------------------------------------------------------------------
Function pmCalculateBuisinessBlockTotalsByRoomTypes(pRoomType = Undefined, pDateFrom = Undefined, pDateTo = Undefined) Export
	vDateFrom = pDateFrom;
	If Not ValueIsFilled(vDateFrom) Then
		vDateFrom = PeriodFrom;
	EndIf;
	vDateTo = pDateTo;
	If Not ValueIsFilled(vDateTo) Then
		vDateTo = PeriodTo;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExpectedGuestGroupsTurnovers.Period AS PeriodDate,
	|	ExpectedGuestGroupsTurnovers.Hotel AS Hotel,
	|	ExpectedGuestGroupsTurnovers.RoomQuota AS RoomQuota,
	|	ExpectedGuestGroupsTurnovers.RoomType AS RoomType,
	|	ExpectedGuestGroupsTurnovers.RoomsReservedTurnover AS RoomsForecast,
	|	ExpectedGuestGroupsTurnovers.BedsReservedTurnover AS BedsForecast
	|INTO ForecastData
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			&qShowTentative
	|				AND RoomQuota = &qRoomQuota
	|				AND (RoomType = &qRoomType
	|					OR &qRoomTypeIsEmpty)
	|				AND (Hotel = &qHotel
	|					OR &qHotelIsEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark) AS ExpectedGuestGroupsTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentRawBalances.Period AS PeriodDate,
	|	AllotmentRawBalances.Hotel AS Hotel,
	|	AllotmentRawBalances.RoomQuota AS RoomQuota,
	|	AllotmentRawBalances.RoomType AS RoomType,
	|	AllotmentRawBalances.RoomsInQuotaClosingBalance AS RoomsInQuota,
	|	AllotmentRawBalances.BedsInQuotaClosingBalance AS BedsInQuota,
	|	AllotmentRawBalances.CounterClosingBalance AS CounterClosingBalance
	|INTO AllotmentRawBalances
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			RoomQuota = &qRoomQuota
	|				AND (RoomType = &qRoomType
	|					OR &qRoomTypeIsEmpty)
	|				AND (Hotel = &qHotel
	|					OR &qHotelIsEmpty)
	|				AND NOT RoomType.IsVirtual
	|				AND NOT RoomType.DeletionMark) AS AllotmentRawBalances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllotmentBalances.PeriodDate AS PeriodDate,
	|	AllotmentBalances.Hotel AS Hotel,
	|	AllotmentBalances.RoomQuota AS RoomQuota,
	|	AllotmentBalances.RoomType AS RoomType,
	|	SUM(AllotmentBalances.RoomsInQuota) AS RoomsInQuota,
	|	SUM(AllotmentBalances.BedsInQuota) AS BedsInQuota
	|FROM
	|	(SELECT
	|		ForecastData.PeriodDate AS PeriodDate,
	|		ForecastData.Hotel AS Hotel,
	|		ForecastData.RoomQuota AS RoomQuota,
	|		ForecastData.RoomType AS RoomType,
	|		ForecastData.RoomsForecast AS RoomsInQuota,
	|		ForecastData.BedsForecast AS BedsInQuota
	|	FROM
	|		ForecastData AS ForecastData
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AllotmentRawBalances.PeriodDate,
	|		AllotmentRawBalances.Hotel,
	|		AllotmentRawBalances.RoomQuota,
	|		AllotmentRawBalances.RoomType,
	|		AllotmentRawBalances.RoomsInQuota,
	|		AllotmentRawBalances.BedsInQuota
	|	FROM
	|		AllotmentRawBalances AS AllotmentRawBalances) AS AllotmentBalances
	|
	|GROUP BY
	|	AllotmentBalances.PeriodDate,
	|	AllotmentBalances.Hotel,
	|	AllotmentBalances.RoomQuota,
	|	AllotmentBalances.RoomType
	|
	|ORDER BY
	|	AllotmentBalances.Hotel.SortCode,
	|	AllotmentBalances.Hotel.Description,
	|	AllotmentBalances.RoomQuota.SortCode,
	|	AllotmentBalances.RoomQuota.Description,
	|	AllotmentBalances.RoomType.SortCode,
	|	AllotmentBalances.RoomType.Description,
	|	PeriodDate";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qRoomQuota", Ref);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsEmpty", Not ValueIsFilled(pRoomType));
	vQry.SetParameter("qPeriodFrom", BegOfDay(vDateFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(vDateTo) + 24*3600);
	vQry.SetParameter("qShowTentative", ?(AllotmentType = Enums.AllotmentTypes.Tentative, True, False));
	Return vQry.Execute().Unload();
EndFunction // pmCalculateBuisinessBlockTotalsByRoomTypes

// -----------------------------------------------------------------------------
Function pmCalculateBusinessBlockForecastSales(pHotel, pRoomType, pDateFrom, pDateTo, pRoomQuantity, pBedsQuantity, pNumberOfBedsPerRoom, rMessage = "") Export
	rMessage = "";
	vDateFrom = pDateFrom;
	If Not ValueIsFilled(vDateFrom) Then
		vDateFrom = PeriodFrom;
	EndIf;
	vDateTo = pDateTo;
	If Not ValueIsFilled(vDateTo) Then
		vDateTo = PeriodTo;
	EndIf;
	
	vForecastSales = New ValueTable();
	vForecastSales.Columns.Add("Folio", cmGetDocumentTypeDescription("Folio"));
	vForecastSales.Columns.Add("Customer", cmGetCatalogTypeDescription("Customers"));
	vForecastSales.Columns.Add("Contract", cmGetCatalogTypeDescription("Contracts"));
	vForecastSales.Columns.Add("Agent", cmGetCatalogTypeDescription("Customers"));
	vForecastSales.Columns.Add("Company", cmGetCatalogTypeDescription("Companies"));
	vForecastSales.Columns.Add("SourceOfBusiness", cmGetCatalogTypeDescription("SourcesOfBusiness"));
	vForecastSales.Columns.Add("MarketingCode", cmGetCatalogTypeDescription("MarketingCodes"));
	vForecastSales.Columns.Add("ClientType", cmGetCatalogTypeDescription("ClientTypes"));
	vForecastSales.Columns.Add("TripPurpose", cmGetCatalogTypeDescription("TripPurposes"));
	vForecastSales.Columns.Add("RoomQuota", cmGetCatalogTypeDescription("RoomQuotas"));
	vForecastSales.Columns.Add("Period", cmGetDateTimeTypeDescription());
	vForecastSales.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vForecastSales.Columns.Add("ServiceDate", cmGetDateTypeDescription());
	vForecastSales.Columns.Add("Price", cmGetSumTypeDescription());
	vForecastSales.Columns.Add("Quantity", cmGetQuantityTypeDescription());
	vForecastSales.Columns.Add("Sales", cmGetSumTypeDescription());
	vForecastSales.Columns.Add("SalesWithoutVAT", cmGetSumTypeDescription());
	vForecastSales.Columns.Add("RoomRevenue", cmGetSumTypeDescription());
	vForecastSales.Columns.Add("RoomRevenueWithoutVAT", cmGetSumTypeDescription());
	vForecastSales.Columns.Add("Service", cmGetCatalogTypeDescription("Services"));
	vForecastSales.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
	vForecastSales.Columns.Add("VATSum", cmGetSumTypeDescription());
	vForecastSales.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vForecastSales.Columns.Add("FolioCurrency", cmGetCatalogTypeDescription("Currencies"));
	vForecastSales.Columns.Add("ReportingCurrency", cmGetCatalogTypeDescription("Currencies"));
	vForecastSales.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vForecastSales.Columns.Add("RoomsRented", cmGetQuantityTypeDescription());
	vForecastSales.Columns.Add("BedsRented", cmGetQuantityTypeDescription());
	vForecastSales.Columns.Add("Author", cmGetCatalogTypeDescription("Employees"));

	// Skip virtual blocks
	If AllotmentType = Enums.AllotmentTypes.DoNotChangeAvailability Then
		Return vForecastSales;
	EndIf;
	
	vHotel = pHotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = Hotel;
	EndIf;
	If ValueIsFilled(pRoomType) Then
		vHotel = pRoomType.Owner;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		rMessage = NStr("en='Business block hotel is empty!'; ru='В бизнес-блоке не указана гостиница!'; de='Im Geschäftsblock ist kein Hotel angegeben!'");
		Return vForecastSales;
	EndIf;
	
	// Get room rate
	vRoomRate = ?(ValueIsFilled(RoomRate), RoomRate, vHotel.RoomRate);
	If Not ValueIsFilled(vRoomRate) Then
		rMessage = NStr("en='Business block room rate is empty!'; ru='В бизнес-блоке не указан тариф!'; de='Im Geschäftsblock ist kein Tarif angegeben!'");
		Return vForecastSales;
	EndIf;
	
	vCompany = Company;
	If Not ValueIsFilled(vCompany) Then
		If ValueIsFilled(pRoomType.Company) Then
			vCompany = pRoomType.Company;
		ElsIf ValueIsFilled(vRoomRate.Company) Then
			vCompany = vRoomRate.Company;
		Else
			vCompany = vHotel.Company;
		EndIf;
	EndIf;
	
	// Get accommodation templates by guest ages
	vAdults = BudgetNumberOfAdults;
	vTeens = BudgetNumberOfTeenagers;
	vChildren = BudgetNumberOfChildren;
	vInfants = BudgetNumberOfInfants;
	If vHotel.TeenagersMaxAge = 0 Then
		vChildren = vChildren + vTeens;
		vTeens = 0;
	EndIf;
	If vHotel.ChildrenMaxAge = 0 Then
		vInfants = vInfants + vChildren;
		vChildren = 0;
	EndIf;
	If vHotel.InfantsMaxAge = 0 Then
		vAdults = vAdults + vInfants;
		vInfants = 0;
	EndIf;

	vVATRate = Undefined;
	vService = cmGetRoomRateService(vHotel, vRoomRate, ClientType, pRoomType, vDateFrom, vVATRate);
	If Not ValueIsFilled(vVATRate) Then
		vVATRate = vHotel.Company.VATRate;
	EndIf;
	If Not ValueIsFilled(vService) Then
		rMessage = NStr("en='Failed to get the room revenue service!'; ru='Не удалось определить услугу доходов от продажи номеров!'; de='Der Erlös-Service aus dem Verkauf von Zimmern konnte nicht ermittelt werden!'");
		Return vForecastSales;
	EndIf;
	
	// Check budget currency
	If Not ValueIsFilled(BudgetCurrency) Then
		rMessage = NStr("en='Business block budget currency is empty!'; ru='В бизнес-блоке не указана валюта бюджета!'; de='Die Budgetwährung ist im Geschäftsblock nicht angegeben!'");
		Return vForecastSales;
	EndIf;
	
	vAccTemplatesList = New ValueList();
	vCachedPricesTab = New ValueTable();
	
	Try
		// Calculate total allotment budget
		vDate = BegOfDay(vDateFrom);
		While vDate < BegOfDay(vDateTo) Do
			vDayPrice = 0;
			vGetTemplates = False;
			
			// Try to find this date in price overrides
			vRMPRows = RoomTypes.FindRows(New Structure("RoomType", pRoomType));
			p = vRMPRows.Count() - 1;
			While p >= 0 Do
				vRMPRow = vRMPRows.Get(p);
				If BegOfDay(vRMPRow.PeriodFrom) <= vDate And BegOfDay(vRMPRow.PeriodTo) > vDate Then
					vDayPrice = Round(cmConvertCurrencies(vRMPRow.Price, vRMPRow.Currency, , vHotel.ReportingCurrency, , vDate, vHotel), 2);
					
					// Price number of persons
					vManualPriceAdults = vRMPRow.NumberOfAdults;
					vManualPriceTeens = vRMPRow.NumberOfTeenagers;
					vManualPriceChildren = vRMPRow.NumberOfChildren;
					vManualPriceInfants = vRMPRow.NumberOfInfants;
					If vHotel.TeenagersMaxAge = 0 Then
						vManualPriceChildren = vManualPriceChildren + vManualPriceTeens;
						vManualPriceTeens = 0;
					EndIf;
					If vHotel.ChildrenMaxAge = 0 Then
						vManualPriceInfants = vManualPriceInfants + vChildren;
						vManualPriceChildren = 0;
					EndIf;
					If vHotel.InfantsMaxAge = 0 Then
						vManualPriceAdults = vManualPriceAdults + vManualPriceInfants;
						vManualPriceInfants = 0;
					EndIf;
					
					If vManualPriceAdults <> vAdults Or vManualPriceTeens <> vTeens Or vManualPriceChildren <> vChildren Or vManualPriceInfants <> vInfants Then
						vAdults = vManualPriceAdults;
						vTeens = vManualPriceTeens;
						vChildren = vManualPriceChildren;
						vInfants = vManualPriceInfants;
						
						vGetTemplates = True;
					EndIf;
						
					Break;
				EndIf;
				p = p - 1;
			EndDo;
				
			// Try to get price from prices cache if there is no manual price
			If vDayPrice = 0 And ValueIsFilled(BudgetCurrency) Then
				If vAdults <> 0 Or vTeens <> 0 Or vChildren <> 0 Or vInfants <> 0 Then
					// Get list of templates valid for the given number of persons
					If vAccTemplatesList.Count() = 0 Or vCachedPricesTab.Count() = 0 Or vGetTemplates Then
						vAccTemplates = cmGetAccommodationTemplatesByGuestsQuantity(vAdults, vTeens, vChildren, vInfants, vHotel, True);
						vAccTemplatesList.LoadValues(vAccTemplates.UnloadColumn("AccommodationTemplate"));

						If ValueIsFilled(vRoomRate) And 
						  (Not ValueIsFilled(vRoomRate.PriceTagType) Or vRoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByDays Or vRoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByPeriod) Then
							vCachedPricesTab = cmGetCachedPricesByDays(vHotel, ClientType, BegOfDay(vDateFrom), BegOfDay(vDateTo) + 24*3600, Catalogs.PriceTags.EmptyRef(), vRoomRate, vAccTemplatesList, False, True, Undefined, , , pRoomType);
						Else
							vCachedPricesTab = cmGetCachedPricesForPriceTagsByDays(vHotel, ClientType, BegOfDay(vDateFrom), BegOfDay(vDateTo) + 24*3600, vRoomRate, vAccTemplatesList, False, True, Undefined, , , pRoomType);
						EndIf;
						vCachedPricesTab.GroupBy("Period, RoomType, Currency", "Amount");
					EndIf;

					vCPRows = vCachedPricesTab.FindRows(New Structure("Period, RoomType", vDate, pRoomType));
					For Each vCPRow In vCPRows Do
						vDayPrice = vDayPrice + Round(cmConvertCurrencies(vCPRow.Amount, vCPRow.Currency, , vHotel.ReportingCurrency, , vDate, vHotel), 2);
					EndDo;
				EndIf;
			EndIf;
			
            vForecastSalesRow = vForecastSales.Add();

			vForecastSalesRow.RoomQuota = Ref;
			vForecastSalesRow.Company = vCompany;
			vForecastSalesRow.Customer = Customer;
			vForecastSalesRow.Contract = Contract;
			vForecastSalesRow.Agent = Agent;
			vForecastSalesRow.Author = SessionParameters.CurrentUser;
			vForecastSalesRow.SourceOfBusiness = SourceOfBusiness;
			vForecastSalesRow.MarketingCode = MarketingCode;
			vForecastSalesRow.ClientType = ClientType;
			vForecastSalesRow.TripPurpose = TripPurpose;
			vForecastSalesRow.Period = vDate;
			vForecastSalesRow.AccountingDate = vDate;
			vForecastSalesRow.ServiceDate = vDate;
			vForecastSalesRow.RoomType = pRoomType;
			vForecastSalesRow.RoomRate = vRoomRate;
			vForecastSalesRow.Folio = ChargingFolio;

			vForecastSalesRow.Service = vService;
			vForecastSalesRow.VATRate = vVATRate;
			
			vForecastSalesRow.Price = vDayPrice;
			vForecastSalesRow.Quantity = ?(pRoomQuantity = 0 And pNumberOfBedsPerRoom > 0, pBedsQuantity/pNumberOfBedsPerRoom, pRoomQuantity);
			vForecastSalesRow.RoomRevenue = vForecastSalesRow.Price * vForecastSalesRow.Quantity;
			vForecastSalesRow.VATSum = cmCalculateVATSum(vForecastSalesRow.VATRate, vForecastSalesRow.Price, vDate) * vForecastSalesRow.Quantity ;
			vForecastSalesRow.RoomRevenueWithoutVAT = vForecastSalesRow.RoomRevenue - vForecastSalesRow.VATSum;
			vForecastSalesRow.Sales = vForecastSalesRow.RoomRevenue;
			vForecastSalesRow.SalesWithoutVAT = vForecastSalesRow.RoomRevenueWithoutVAT;
			vForecastSalesRow.FolioCurrency = ?(ValueIsFilled(ChargingFolio), ChargingFolio.FolioCurrency, BudgetCurrency);
			vForecastSalesRow.ReportingCurrency = vHotel.ReportingCurrency;
			
			vForecastSalesRow.RoomsRented = ?(pRoomQuantity = 0 And pNumberOfBedsPerRoom > 0, pBedsQuantity/pNumberOfBedsPerRoom, pRoomQuantity);
			vForecastSalesRow.BedsRented = pBedsQuantity;
			
			vDate = vDate + 24*3600;
		EndDo;
	Except
		rMessage = cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	
	Return vForecastSales;
EndFunction // pmCalculateBusinessBlockForecastSales

// -----------------------------------------------------------------------------
Function pmCalculateBusinessBlockPricePerRoomTypeAndDate(pRoomType, pDate, pAdults = Undefined, pTeenagers = Undefined, pChildren = Undefined, pInfants = Undefined, rIsManualPrice = False) Export
	vMessage = "";
	vDayPrice = 0;
	rIsManualPrice = False;
	If AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock Then
		Return vDayPrice;
	EndIf;
		
	// Preprocessing
	vHotel = Hotel;
	If ValueIsFilled(pRoomType) Then
		vHotel = pRoomType.Owner;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vMessage = NStr("en='Business block hotel is empty!'; ru='В бизнес-блоке не указана гостиница!'; de='Im Geschäftsblock ist kein Hotel angegeben!'");
		Raise vMessage;
	EndIf;
	
	// Get room rate
	vRoomRate = ?(ValueIsFilled(RoomRate), RoomRate, vHotel.RoomRate);
	If Not ValueIsFilled(vRoomRate) Then
		vMessage = NStr("en='Business block room rate is empty!'; ru='В бизнес-блоке не указан тариф!'; de='Im Geschäftsblock ist kein Tarif angegeben!'");
		Raise vMessage;
	EndIf;
	
	// Check budget currency
	If Not ValueIsFilled(BudgetCurrency) Then
		vMessage = NStr("en='Business block budget currency is empty!'; ru='В бизнес-блоке не указана валюта бюджета!'; de='Die Budgetwährung ist im Geschäftsblock nicht angegeben!'");
		Raise vMessage;
	EndIf;
	
	// Get accommodation templates by guest ages
	vAdults = ?(pAdults = Undefined, BudgetNumberOfAdults, pAdults);
	vTeens = ?(pTeenagers = Undefined, BudgetNumberOfTeenagers, pTeenagers);
	vChildren = ?(pChildren = Undefined, BudgetNumberOfChildren, pChildren);
	vInfants = ?(pInfants = Undefined, BudgetNumberOfInfants, pInfants);
	If vHotel.TeenagersMaxAge = 0 Then
		vChildren = vChildren + vTeens;
		vTeens = 0;
	EndIf;
	If vHotel.ChildrenMaxAge = 0 Then
		vInfants = vInfants + vChildren;
		vChildren = 0;
	EndIf;
	If vHotel.InfantsMaxAge = 0 Then
		vAdults = vAdults + vInfants;
		vInfants = 0;
	EndIf;
	
	// Try to find this date in price overrides
	vRMPRows = RoomTypes.FindRows(New Structure("RoomType", pRoomType));
	p = vRMPRows.Count() - 1;
	While p >= 0 Do
		vRMPRow = vRMPRows.Get(p);
		If BegOfDay(vRMPRow.PeriodFrom) <= pDate And BegOfDay(vRMPRow.PeriodTo) > pDate Then
			vDayPrice = vRMPRow.Price;
			
			// Price number of persons
			vManualPriceAdults = vRMPRow.NumberOfAdults;
			vManualPriceTeens = vRMPRow.NumberOfTeenagers;
			vManualPriceChildren = vRMPRow.NumberOfChildren;
			vManualPriceInfants = vRMPRow.NumberOfInfants;
			If vHotel.TeenagersMaxAge = 0 Then
				vManualPriceChildren = vManualPriceChildren + vManualPriceTeens;
				vManualPriceTeens = 0;
			EndIf;
			If vHotel.ChildrenMaxAge = 0 Then
				vManualPriceInfants = vManualPriceInfants + vChildren;
				vManualPriceChildren = 0;
			EndIf;
			If vHotel.InfantsMaxAge = 0 Then
				vManualPriceAdults = vManualPriceAdults + vManualPriceInfants;
				vManualPriceInfants = 0;
			EndIf;
			
			If vManualPriceAdults <> vAdults Or vManualPriceTeens <> vTeens Or vManualPriceChildren <> vChildren Or vManualPriceInfants <> vInfants Then
				vAdults = vManualPriceAdults;
				vTeens = vManualPriceTeens;
				vChildren = vManualPriceChildren;
				vInfants = vManualPriceInfants;
			EndIf;
			
			Break;
		EndIf;
		p = p - 1;
	EndDo;
	
	// Get block prices from the price cache
	If vDayPrice = 0 And (vAdults <> 0 Or vTeens <> 0 Or vChildren <> 0 Or vInfants <> 0) And ValueIsFilled(BudgetCurrency) Then
		vAccTemplatesList = New ValueList;
		vAccTemplates = cmGetAccommodationTemplatesByGuestsQuantity(vAdults, vTeens, vChildren, vInfants, vHotel, True);
		vAccTemplatesList.LoadValues(vAccTemplates.UnloadColumn("AccommodationTemplate"));

		vCachedPricesTab = New ValueTable();
		If ValueIsFilled(vRoomRate) And 
		  (Not ValueIsFilled(vRoomRate.PriceTagType) Or vRoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByDays Or vRoomRate.PriceTagType = Enums.PriceTagTypes.ByDurationOfStayByPeriod) Then
			vCachedPricesTab = cmGetCachedPricesByDays(vHotel, ClientType, BegOfDay(pDate), BegOfDay(pDate) + 24*3600, Catalogs.PriceTags.EmptyRef(), vRoomRate, vAccTemplatesList, False, True, Undefined, , , pRoomType);
		Else
			vCachedPricesTab = cmGetCachedPricesForPriceTagsByDays(vHotel, ClientType, BegOfDay(PeriodFrom), BegOfDay(PeriodTo) + 24*3600, vRoomRate, vAccTemplatesList, False, True, Undefined, , , pRoomType);
		EndIf;
		vCachedPricesTab.GroupBy("Period, RoomType, Currency", "Amount");
		
		vCPRows = vCachedPricesTab.FindRows(New Structure("Period, RoomType", pDate, pRoomType));
		For Each vCPRow In vCPRows Do
			vDayPrice = vDayPrice + cmConvertCurrencies(vCPRow.Amount, vCPRow.Currency, , BudgetCurrency, , pDate, vHotel);
		EndDo;
	EndIf;
	
	Return vDayPrice;
EndFunction // pmCalculateBusinessBlockPricePerRoomTypeAndDate

#EndRegion
