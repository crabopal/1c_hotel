
#Region Public

// -----------------------------------------------------------------------------
//  Gets discount percent
//
// Parameters:
//  pDate	 - Date					 - Date
//  pService - CatalogRef.Services	 - Ref
//  pHotel	 - CatalogRef.Hotels	 - Ref
// 
// Returns:
//  Number - discount percent
//
Function pmGetDiscount(Val pDate = Undefined, pService = Undefined, pHotel = Undefined) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	vHotel = Catalogs.Hotels.EmptyRef();
	If Not ValueIsFilled(pHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	Else
		vHotel = pHotel;
	EndIf;
	
	// Initialize return parameters
	vDiscount = 0;
	
	// Build query
	q = New Query;
	If ValueIsFilled(pService) Then
		q.Text =
		"SELECT
		|	Discounts.Discount AS Discount
		|FROM
		|	InformationRegister.Discounts.SliceLast(
		|			&qDate,
		|			DiscountType = &qDiscountType
		|				AND (Hotel = &qHotel
		|					OR Hotel = &qEmptyHotel)
		|				AND ServiceGroup IN (&qServiceGroupsList)) AS Discounts";
		// Set parameters
		q.SetParameter("qDate", pDate);
		q.SetParameter("qDiscountType", Ref);
		q.SetParameter("qHotel", vHotel);
		q.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		q.SetParameter("qServiceGroupsList", cmGetListOfServiceServiceGroups(pService));
		// Run query
		vResTable = q.Execute().Unload();
		For Each vResTableRow In vResTable Do
			vDiscount = vResTableRow.Discount;
			Break;
		EndDo;
	EndIf;
	If Not ValueIsFilled(pService) Or (ValueIsFilled(pService) And vDiscount = 0) Then
		q.Text =
		"SELECT
		|	Discounts.Discount AS Discount
		|FROM
		|	InformationRegister.Discounts.SliceLast(
		|			&qDate,
		|			DiscountType = &qDiscountType
		|				AND (Hotel = &qHotel
		|					OR Hotel = &qEmptyHotel)
		|				AND ServiceGroup = &qEmptyServiceGroup) AS Discounts";
		// Set parameters
		q.SetParameter("qDate", pDate);
		q.SetParameter("qDiscountType", Ref);
		q.SetParameter("qHotel", vHotel);
		q.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		q.SetParameter("qEmptyServiceGroup", Catalogs.ServiceGroups.EmptyRef());
		// Run query
		vResTable = q.Execute().Unload();
		For Each vResTableRow In vResTable Do
			vDiscount = vResTableRow.Discount;
			Break;
		EndDo;
	EndIf;
	If Not ValueIsFilled(pService) And vDiscount = 0 And Not DifferentDiscountPercentsForServiceGroupsAllowed Then
		q.Text =
		"SELECT
		|	Discounts.Discount AS Discount
		|FROM
		|	InformationRegister.Discounts.SliceLast(
		|			&qDate,
		|			DiscountType = &qDiscountType
		|				AND (Hotel = &qHotel
		|					OR Hotel = &qEmptyHotel)) AS Discounts";
		// Set parameters
		q.SetParameter("qDate", pDate);
		q.SetParameter("qHotel", vHotel);
		q.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		q.SetParameter("qDiscountType", Ref);
		// Run query
		vResTable = q.Execute().Unload();
		For Each vResTableRow In vResTable Do
			vDiscount = vResTableRow.Discount;
			Break;
		EndDo;
	EndIf;
	
	// Return
	Return vDiscount;
EndFunction // pmGetDiscount

// -----------------------------------------------------------------------------
//  Gets bonus calculation factor
//
// Parameters:
//  pDate	 - Date					 - Date
//  pService - CatalogRef.Services	 - Ref
//  pHotel	 - CatalogRef.Hotels	 - Ref
// 
// Returns:
//  Number - bonus calculation factoron
//
Function pmGetBonusCalculationFactor(Val pDate = Undefined, pService = Undefined, pHotel = Undefined) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	vHotel = Catalogs.Hotels.EmptyRef();
	If Not ValueIsFilled(pHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	Else
		vHotel = pHotel;
	EndIf;
	
	// Initialize return parameters
	vBonusCalculationFactor = 0;
	
	// Build query
	q = New Query;
	If ValueIsFilled(pService) Then
		q.Text =
		"SELECT
		|	Discounts.BonusCalculationFactor AS BonusCalculationFactor
		|FROM
		|	InformationRegister.Discounts.SliceLast(
		|			&qDate,
		|			DiscountType = &qDiscountType
		|				AND (Hotel = &qHotel
		|					OR Hotel = &qEmptyHotel)
		|				AND ServiceGroup IN (&qServiceGroupsList)) AS Discounts";
		// Set parameters
		q.SetParameter("qDate", pDate);
		q.SetParameter("qDiscountType", Ref);
		q.SetParameter("qHotel", vHotel);
		q.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		q.SetParameter("qServiceGroupsList", cmGetListOfServiceServiceGroups(pService));
		// Run query
		vResTable = q.Execute().Unload();
		For Each vResTableRow In vResTable Do
			vBonusCalculationFactor = vResTableRow.BonusCalculationFactor;
			Break;
		EndDo;
	EndIf;
	If Not ValueIsFilled(pService) Or (ValueIsFilled(pService) And vBonusCalculationFactor = 0) Then
		q.Text =
		"SELECT
		|	Discounts.BonusCalculationFactor AS BonusCalculationFactor
		|FROM
		|	InformationRegister.Discounts.SliceLast(
		|			&qDate,
		|			DiscountType = &qDiscountType
		|				AND (Hotel = &qHotel
		|					OR Hotel = &qEmptyHotel)
		|				AND ServiceGroup = &qEmptyServiceGroup) AS Discounts";
		// Set parameters
		q.SetParameter("qDate", pDate);
		q.SetParameter("qDiscountType", Ref);
		q.SetParameter("qHotel", vHotel);
		q.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		q.SetParameter("qEmptyServiceGroup", Catalogs.ServiceGroups.EmptyRef());
		// Run query
		vResTable = q.Execute().Unload();
		For Each vResTableRow In vResTable Do
			vBonusCalculationFactor = vResTableRow.BonusCalculationFactor;
			Break;
		EndDo;
	EndIf;
	
	// Return
	Return vBonusCalculationFactor;
EndFunction // pmGetBonusCalculationFactor

// -----------------------------------------------------------------------------
//  Gets accumulating discount percent
//
// Parameters:
//  pService					 - CatalogRef.Services	 - Ref
//  pDate						 - Date					 - Date
//  pResource					 - Number				 - Resource
//  rDiscountConfirmationText	 - String				 - DiscountConfirmationText
// 
// Returns:
//  Number - discount percent
//
Function pmGetAccumulatingDiscount(pService, Val pDate = Undefined, pResource, 
                                   rDiscountConfirmationText) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	
	// Initialize return parameters
	vDiscount = 0;
	
	// Build query
	q = New Query;
	q.Text =
	"SELECT
	|	Discounts.Period AS Period,
	|	Discounts.ResourceLimit AS ResourceLimit,
	|	Discounts.ServiceGroup AS ServiceGroup,
	|	Discounts.Discount AS Discount,
	|	Discounts.Name AS Name
	|INTO AccumulatingDiscounts
	|FROM
	|	InformationRegister.AccumulatingDiscounts.SliceLast(&qDate, DiscountType = &qDiscountType) AS Discounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(AccumulatingDiscounts.Period) AS MaxPeriod
	|INTO MaxPeriods
	|FROM
	|	AccumulatingDiscounts AS AccumulatingDiscounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Discounts.ResourceLimit AS ResourceLimit,
	|	Discounts.ServiceGroup AS ServiceGroup,
	|	Discounts.Discount AS Discount,
	|	Discounts.Name AS Name
	|FROM
	|	AccumulatingDiscounts AS Discounts
	|		INNER JOIN MaxPeriods AS MaxPeriods
	|		ON Discounts.Period = MaxPeriods.MaxPeriod
	|
	|ORDER BY
	|	ResourceLimit,
	|	Discounts.ServiceGroup.SortCode,
	|	Discounts.ServiceGroup.Description";
	// Set parameters
	q.SetParameter("qDate", pDate);
	q.SetParameter("qDiscountType", Ref);
	// Run query
	vAccDiscounts = q.Execute().Unload();
	For Each vAccDiscount In vAccDiscounts Do
		If ValueIsFilled(vAccDiscount.ServiceGroup) Then
			If Not cmIsServiceInServiceGroup(pService, vAccDiscount.ServiceGroup) Then
				Continue;
			EndIf;
		EndIf;
		If vAccDiscount.ResourceLimit <= pResource Then
			vDiscount = vAccDiscount.Discount;
			rDiscountConfirmationText = TrimAll(Description) + ?(IsBlankString(vAccDiscount.Name), "", " - " + Trimall(vAccDiscount.Name)) + 
			                            " (" + GetAccumulatingTypeUnitDescription() + pResource + ")";
		Else
			Break;
		EndIf;
	EndDo;
	
	// Return
	Return vDiscount;
EndFunction // pmGetAccumulatingDiscount

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDate			 - Date					 - Date
//  pCustomer		 - CatalogRef.Customers	 - Ref
//  pContract		 - CatalogRef.Contracts	 - Ref
//  pClient			 - CatalogRef.Clients	 - Ref
//  pDiscountCard	 - CatalogRef.DiscountCards	 - Ref
//  pGuestGroup		 - CatalogRef.GuestGroup	 - Ref
// 
// Returns:
//  ValueTable - Accumulating discount resources
//
Function pmGetAccumulatingDiscountResources(Val pDate = Undefined, 
											pCustomer = Undefined, 
                                            pContract = Undefined, 
                                            pClient = Undefined, 
                                            pDiscountCard = Undefined,
											pGuestGroup = Undefined) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	// Initialize map with resources
	vRes = New Map();
	// Build and run query
	vDateTo = pDate;
	qAccDisRes = New Query;
	If LoyaltyType = Enums.LoyaltyType.Bonuses Then
		If ValueIsFilled(pDiscountCard) Then
			If pDiscountCard.DiscountType = Ref Then
				qAccDisRes.Text = 
				"SELECT
				|	&qDiscountType AS DiscountType,
				|	BonusesBalance.Card AS DiscountDimension,
				|	0 AS Resource,
				|	BonusesBalance.QuantityClosingBalance AS Bonus,
				|	BonusesBalance.QuantityReceipt AS BonusReceipt
				|FROM
				|	AccumulationRegister.Bonuses.BalanceAndTurnovers(, &qDateTo, Period, RegisterRecordsAndPeriodBoundaries, Card = &qDiscountCard) AS BonusesBalance";
				qAccDisRes.SetParameter("qDateTo", New Boundary(vDateTo, BoundaryType.Excluding));
				qAccDisRes.SetParameter("qDiscountCard", pDiscountCard);
				qAccDisRes.SetParameter("qDiscountType", Ref);
			Else
				qAccDisRes.Text = 
				"SELECT
				|	&qDiscountType AS DiscountType,
				|	VALUE(Catalog.DiscountCards.EmptyRef) AS DiscountDimension,
				|	0 AS Resource,
				|	0 AS Bonus,
				|	0 AS BonusReceipt
				|FROM
				|	AccumulationRegister.Bonuses AS Bonuses
				|WHERE
				|	FALSE";
				qAccDisRes.SetParameter("qDiscountType", Ref);
			EndIf;
		Else
			If ValueIsFilled(pClient) Then
				qCards = New Query;
				qCards.Text = 
				"SELECT
				|	ClientCards.Ref AS Ref
				|FROM
				|	Catalog.DiscountCards AS ClientCards
				|WHERE
				|	ClientCards.Client = &qClient
				|	AND ClientCards.DiscountType = &qDiscountType
				|	AND NOT ClientCards.DeletionMark";
				qCards.SetParameter("qClient", pClient);
				qCards.SetParameter("qDiscountType", Ref);
				vClientCards = qCards.Execute().Unload();
				vClientCardsArray = vClientCards.UnloadColumn("Ref");
				If vClientCardsArray.Count() > 0 Then
					qAccDisRes.Text = 
					"SELECT
					|	&qDiscountType AS DiscountType,
					|	BonusesBalance.Card AS DiscountDimension,
					|	0 AS Resource,
					|	BonusesBalance.QuantityClosingBalance AS Bonus,
					|	BonusesBalance.QuantityReceipt AS BonusReceipt
					|FROM
					|	AccumulationRegister.Bonuses.BalanceAndTurnovers(, &qDateTo, Period, RegisterRecordsAndPeriodBoundaries, Card IN (&qCardsArray)) AS BonusesBalance";
					qAccDisRes.SetParameter("qDateTo", New Boundary(vDateTo, BoundaryType.Excluding));
					qAccDisRes.SetParameter("qCardsArray", vClientCardsArray);
					qAccDisRes.SetParameter("qDiscountType", Ref);
				Else
					qAccDisRes.Text = 
					"SELECT
					|	&qDiscountType AS DiscountType,
					|	VALUE(Catalog.DiscountCards.EmptyRef) AS DiscountDimension,
					|	0 AS Resource,
					|	0 AS Bonus,
					|	0 AS BonusReceipt
					|FROM
					|	AccumulationRegister.Bonuses AS Bonuses
					|WHERE
					|	FALSE";
					qAccDisRes.SetParameter("qDiscountType", Ref);
				EndIf;
			Else
				qAccDisRes.Text = 
				"SELECT
				|	&qDiscountType AS DiscountType,
				|	VALUE(Catalog.DiscountCards.EmptyRef) AS DiscountDimension,
				|	0 AS Resource,
				|	0 AS Bonus,
				|	0 AS BonusReceipt
				|FROM
				|	AccumulationRegister.Bonuses AS Bonuses
				|WHERE
				|	FALSE";
				qAccDisRes.SetParameter("qDiscountType", Ref);
			EndIf;
		EndIf;
	Else
		If AccumulatingDiscountPeriod = 0 And Not ValueIsFilled(AccumulatingDiscountFromDate) Then
			qAccDisRes.Text = 
			"SELECT
			|	AccumulatingDiscountResourcesBalances.DiscountType,
			|	AccumulatingDiscountResourcesBalances.DiscountDimension,
			|	AccumulatingDiscountResourcesBalances.ResourceClosingBalance AS Resource,
			|	AccumulatingDiscountResourcesBalances.BonusClosingBalance AS Bonus,
			|	AccumulatingDiscountResourcesBalances.BonusReceipt AS BonusReceipt
			|FROM
			|	AccumulationRegister.AccumulatingDiscountResources.BalanceAndTurnovers(
			|			,
			|			&qDateTo,
			|			Period,
			|			RegisterRecordsAndPeriodBoundaries,
			|			DiscountType = &qDiscountType
			|				AND (DiscountDimension = &qCustomer
			|						AND &qCustomerIsFilled
			|					OR DiscountDimension = &qContract
			|						AND &qContractIsFilled
			|					OR DiscountDimension = &qClient
			|						AND &qClientIsFilled
			|					OR DiscountDimension = &qDiscountCard
			|						AND &qDiscountCardIsFilled)
			|				AND (GuestGroup = &qGuestGroup
			|					OR &qGuestGroupIsEmpty)) AS AccumulatingDiscountResourcesBalances";
		Else
			qAccDisRes.Text = 
			"SELECT
			|	AccumulatingDiscountResourcesTurnovers.DiscountType,
			|	AccumulatingDiscountResourcesTurnovers.DiscountDimension,
			|	AccumulatingDiscountResourcesTurnovers.ResourceTurnover AS Resource,
			|	AccumulatingDiscountResourcesTurnovers.BonusTurnover AS Bonus,
			|	AccumulatingDiscountResourcesTurnovers.BonusReceipt AS BonusReceipt
			|FROM
			|	AccumulationRegister.AccumulatingDiscountResources.Turnovers(
			|			&qDateFrom,
			|			&qDateTo,
			|			Period,
			|			DiscountType = &qDiscountType
			|				AND (DiscountDimension = &qCustomer
			|						AND &qCustomerIsFilled
			|					OR DiscountDimension = &qContract
			|						AND &qContractIsFilled
			|					OR DiscountDimension = &qClient
			|						AND &qClientIsFilled
			|					OR DiscountDimension = &qDiscountCard
			|						AND &qDiscountCardIsFilled)
			|				AND (GuestGroup = &qGuestGroup
			|					OR &qGuestGroupIsEmpty)) AS AccumulatingDiscountResourcesTurnovers";
			If ValueIsFilled(AccumulatingDiscountFromDate) Then
				vDateFrom = BegOfDay(AccumulatingDiscountFromDate);
			Else
				vDateFrom = BegOfDay(vDateTo - AccumulatingDiscountPeriod*24*3600);
			Endif;
			qAccDisRes.SetParameter("qDateFrom", vDateFrom);
		EndIf;
		qAccDisRes.SetParameter("qDateTo", New Boundary(vDateTo, BoundaryType.Excluding));
		qAccDisRes.SetParameter("qDiscountType", Ref);
		qAccDisRes.SetParameter("qCustomer", pCustomer);
		qAccDisRes.SetParameter("qCustomerIsFilled", ValueIsFilled(pCustomer));
		qAccDisRes.SetParameter("qContract", pContract);
		qAccDisRes.SetParameter("qContractIsFilled", ValueIsFilled(pContract));
		qAccDisRes.SetParameter("qClient", pClient);
		qAccDisRes.SetParameter("qClientIsFilled", ValueIsFilled(pClient));
		qAccDisRes.SetParameter("qDiscountCard", pDiscountCard);
		qAccDisRes.SetParameter("qDiscountCardIsFilled", ValueIsFilled(pDiscountCard));
		qAccDisRes.SetParameter("qGuestGroup", pGuestGroup);
		qAccDisRes.SetParameter("qGuestGroupIsEmpty", Not ValueIsFilled(pGuestGroup));
	EndIf;
	vAccDisRes = qAccDisRes.Execute().Unload();
	// Return
	Return vAccDisRes;
EndFunction // pmGetAccumulatingDiscountResources

// -----------------------------------------------------------------------------
//  Calculates default accumulating discount dimension based
// 
// Returns:
//  CatalogRef.Clients - discount dimension
//
Function pmGetDefaultAccumulatingDiscountDimension() Export
	vDiscountDimension = Undefined;
	If ValueIsFilled(AccumulatingDiscountDimension) Then
		If AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Client Then
			vDiscountDimension = Catalogs.Clients.EmptyRef();
		ElsIf AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Customer Then
			vDiscountDimension = Catalogs.Customers.EmptyRef();
		ElsIf AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Contract Then
			vDiscountDimension = Catalogs.Contracts.EmptyRef();
		ElsIf AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Agent Then
			vDiscountDimension = Catalogs.Customers.EmptyRef();
		ElsIf AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.DiscountCard Then
			vDiscountDimension = Catalogs.DiscountCards.EmptyRef();
		EndIf;
	EndIf;
	Return vDiscountDimension;
EndFunction // pmGetDefaultAccumulatingDiscountDimension

// -----------------------------------------------------------------------------
//  Calculates accumulating discount resource value based on given service and document
//
// Parameters:
//  pSrvRec					 - CatalogRef.Services	 - Ref
//  pNumberOfPersons		 - Number				 - NumberOfPersons
//  pFolio					 - DocumentRef.Folio	 - Ref
//  pDiscountCard			 - CatalogRef.DiscountCards	 - Ref
//  rDiscountDimension		 - CatalogRef				 - REf
//  pIsResourceReservation	 - Boolean					 - IsResourceReservation
// 
// Returns:
//  Number - resource value for given service.
//
Function pmCalculateResource(pSrvRec, pNumberOfPersons, pFolio, pDiscountCard = Undefined, rDiscountDimension = Undefined, pIsResourceReservation = False) Export
	vRes = 0;
	rDiscountDimension = Undefined;
	vFolio = pFolio;
	vNumberOfPersons = ?(pNumberOfPersons > 0, pNumberOfPersons, 1);
	If ValueIsFilled(AccumulatingDiscountDimension) Then
		If AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Client Then
			If ValueIsFilled(vFolio.Client) Then
				rDiscountDimension = vFolio.Client;
			Else
				rDiscountDimension = Catalogs.Clients.EmptyRef();
			EndIf;
		ElsIf AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Customer Then
			If Not ValueIsFilled(vFolio.Customer) Then
				Return 0;
			Else
				rDiscountDimension = vFolio.Customer;
			EndIf;
		ElsIf AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Contract Then
			If Not ValueIsFilled(vFolio.Contract) Then
				Return 0;
			Else
				rDiscountDimension = vFolio.Contract;
			EndIf;
		ElsIf AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Agent Then
			If Not ValueIsFilled(vFolio.Agent) Then
				Return 0;
			Else
				rDiscountDimension = vFolio.Agent;
			EndIf;
		ElsIf AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.DiscountCard Then
			If Not ValueIsFilled(pDiscountCard) Then
				Return 0;
			Else
				rDiscountDimension = pDiscountCard;
			EndIf;
		EndIf;
	Else
		Return 0;
	EndIf;
	If AccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByAccommodationDuration Then
		If Not pIsResourceReservation Then
			If pSrvRec.IsRoomRevenue Then
				If pSrvRec.RoomsRented <> 0 Or pSrvRec.BedsRented <> 0 Then
					vRes = pSrvRec.GuestDays/vNumberOfPersons;
				EndIf;
			EndIf;
		EndIf;
	ElsIf AccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByNumberOfGuestVisits Then
		If Not pIsResourceReservation Then
			If pSrvRec.IsRoomRevenue Then
				If pSrvRec.RoomsRented <> 0 Or pSrvRec.BedsRented <> 0 Then
					vRes = pSrvRec.GuestsCheckedIn/vNumberOfPersons;
				EndIf;
			EndIf;
		EndIf;
	ElsIf AccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByServicesTotalSum Then
		vRes = pSrvRec.Sum - pSrvRec.DiscountSum;
	ElsIf AccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByServiceQuantity Then
		vRes = pSrvRec.Quantity;
	ElsIf AccumulatingDiscountType = Enums.AccumulatingDiscountTypes.External Then
		Execute(TrimR(ExternalAlgorithm.Algorithm));
	EndIf;
	Return vRes;
EndFunction // pmCalculateResource

// -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	DateValidFrom = '00010101';
EndProcedure // pmFillAttributesWithDefaultValues

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)   
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetAccumulatingTypeUnitDescription()
	vUnit = "";
	If AccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByAccommodationDuration Then
		vUnit = NStr("en='Days: '; ru='Дней: '; de='Tage: '");
	ElsIf AccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByNumberOfGuestVisits Then
		vUnit = NStr("en='Visits: '; ru='Заездов: '; de='Besuche: '");
	ElsIf AccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByServiceQuantity Then
		vUnit = NStr("en='Q-ty: '; ru='Кол-во: '; de='Anzahl: '");
	ElsIf AccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByServicesTotalSum Then
		vUnit = NStr("en='Amount: '; ru='Сумма: '; de='Summe: '");
	EndIf;
	Return vUnit;
EndFunction // GetAccumulatingTypeUnitDescription 

#EndRegion
