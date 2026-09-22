
#Region Public

// -----------------------------------------------------------------------------
//  Calculates VAT amount
//
// Parameters:
//  pVATRate		 - CatalogRef.VATRates	 - Ref
//  pSum			 - Number				 - Sum
//  pDate			 - Date					 - Date
//  pSumIsWithoutVAT - Number				 - SumIsWithoutVAT
// 
// Returns:
//  Number - VAT amount
//
Function cmCalculateVATSum(pVATRate, pSum, Val pDate = '00010101', pSumIsWithoutVAT = False) Export
	If pDate = '00010101' Then
		pDate = CurrentSessionDate();
	EndIf;
	vVATSum = 0;
	If ValueIsFilled(pVATRate) And pSum <> 0 Then
		vTaxRate = cmGetVATTaxRate(pVATRate, pDate);
		If pSumIsWithoutVAT Then
			vVATSum = Round(pSum * vTaxRate / 100, 2);
		Else
			vVATSum = Round(pSum * vTaxRate /(100 + vTaxRate), 2);
		EndIf;
	EndIf;
	Return vVATSum;
EndFunction // cmCalculateVATSum

// -----------------------------------------------------------------------------
//
// Parameters:
//  pVATRate - CatalogRef.VATRates	 - Ref 
//  pDate	 - Date					 - Date 
// 
// Returns:
//  Number - TaxRate
//
Function cmGetVATTaxRate(pVATRate, pDate) Export
	Return CachedAccounts.GetVATTaxRate(pVATRate, pDate);
EndFunction // cmGetVATTaxRate

// -----------------------------------------------------------------------------
Function cmGetVATRateParams(pVATRate, pDate) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	VATRatesHistorySliceLast.TaxRate AS TaxRate,
	|	VATRatesHistorySliceLast.TaxGroup AS TaxGroup,
	|	VATRatesHistorySliceLast.NoVAT AS NoVAT,
	|	VATRatesHistorySliceLast.Description AS Description
	|FROM
	|	InformationRegister.VATRatesHistory.SliceLast(&qDate, VATRate = &qVATRate) AS VATRatesHistorySliceLast";
	vQry.SetParameter("qVATRate", pVATRate);
	vQry.SetParameter("qDate", New Boundary(pDate, BoundaryType.Including));
	vRes = vQry.Execute().Unload();
	If vRes.Count() > 0 Then
		vResRow = vRes.Get(0);
		If vResRow.TaxRate = Null Then
			Return pVATRate;
		Else
			Return vResRow;
		EndIf;
	Else
		Return pVATRate;
	EndIf;
EndFunction // cmGetVATRateParams

// -----------------------------------------------------------------------------
Function cmGetNoVATVATRate() Export
	vNoVATVATRate = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	VATRates.Ref AS Ref
	|FROM
	|	Catalog.VATRates AS VATRates
	|WHERE
	|	VATRates.NoVAT
	|	AND NOT VATRates.DeletionMark
	|
	|ORDER BY
	|	VATRates.Code";
	vVATRates = vQry.Execute().Unload();
	For Each vVATRatesRow In vVATRates Do
		vNoVATVATRate = vVATRatesRow.Ref;
		Break;
	EndDo;
	Return vNoVATVATRate;
EndFunction // cmGetNoVATVATRate

// -----------------------------------------------------------------------------
//  Description: Recalculates amount and VAT amount based on price and quantity values
//
// Parameters:
//  pPrice		 - Number			 - Price
//  pQuantity	 - Number			 - Quantity
//  pSum		 - Number			 - Sum
//  pVATRate	 - CatalogRef.VATRates	 - Ref
//  pVATSum		 - Number				 - VATSum
//  pDate		 - Date					 - Date
//
Procedure cmPriceOnChange(pPrice, pQuantity, pSum, pVATRate, pVATSum, pDate = '00010101') Export
	pSum = Round(pPrice * pQuantity, 2);
	pVATSum = cmCalculateVATSum(pVATRate, pSum, pDate);
EndProcedure // cmQuantityOnChange

// -----------------------------------------------------------------------------
//  Description: Recalculates amount and VAT amount based on new quantity
//
// Parameters:
//  pPrice		 - Number			 - Price
//  pQuantity	 - Number			 - Quantity
//  pSum		 - Number			 - Sum
//  pVATRate	 - CatalogRef.VATRates	 - Ref
//  pVATSum		 - Number				 - VATSum
//  pDate		 - Date					 - Date
//
Procedure cmQuantityOnChange(pPrice, pQuantity, pSum, pVATRate, pVATSum, pDate = '00010101') Export
	pSum = Round(pPrice * pQuantity, 2);
	pVATSum = cmCalculateVATSum(pVATRate, pSum, pDate);
EndProcedure // cmQuantityOnChange

// -----------------------------------------------------------------------------
//  Recalculates price, quantity and VAT amount based on new amount
//
// Parameters:
//  pService			 - CatalogRef.Services	 - Ref
//  pPrice				 - Number				 - Price
//  pQuantity			 - Number				 - Quantity
//  pSum				 - Number				 - Sum
//  pVATRate			 - CatalogRef.VATRates	 - Ref
//  pVATSum				 - Number				 - VATSum
//  pRecalculatePrice	 - Boolean				 - RecalculatePrice
//  pDate				 - Date					 - Date
//
Procedure cmSumOnChange(pService, pPrice, pQuantity, pSum, pVATRate, pVATSum, pRecalculatePrice = False, pDate = '00010101') Export
	If pRecalculatePrice = Undefined Then
		pRecalculatePrice = False;
	EndIf;
	If Not ValueIsFilled(pService) Then
		If pPrice = 0 Then
			pPrice = PSum;
		EndIf;
		If pPrice <> 0 Then
			pQuantity = Round(pSum / pPrice, 7);
		EndIf;
	Else
		If pQuantity = 0 Then
			pQuantity = 1;
		EndIf;
		If pRecalculatePrice Or pService.RecalculatePriceWhenSumChanged Then
			pPrice = Round(pSum / pQuantity, 2);
		Else
			If pPrice = 0 Then
				pPrice = Round(pSum / pQuantity, 2);
			Else
				pQuantity = Round(pSum / pPrice, 7);
			EndIf;
		EndIf;
	EndIf;
	pVATSum = cmCalculateVATSum(pVATRate, pSum, pDate);
EndProcedure // cmSumOnChange

// -----------------------------------------------------------------------------
//  Description: Recalculate service room sales parameters like number of rooms and beds rented and so on
//
// Parameters:
//  pSrvRow	 - ServiceRow	 - Service row
//  pDocObj	 - DocumentObject	 - Accommodation or reservation object
//
Procedure cmRecalculateServiceRoomSalesParameters(pSrvRow, pDocObj) Export
	If pSrvRow.IsRoomRevenue And Not pSrvRow.IsSplit And Not pSrvRow.RoomRevenueAmountsOnly And Not pSrvRow.IsManual Then
		If ValueIsFilled(pSrvRow.RoomRate) And pSrvRow.RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
			Return;
		EndIf;
		vCurPeriodInHours = 24;
		If ValueIsFilled(pSrvRow.Service) And ValueIsFilled(pSrvRow.Service.QuantityCalculationRule) Then
			If pSrvRow.Service.QuantityCalculationRule.PeriodInHours <> 0 Then
				vCurPeriodInHours = pSrvRow.Service.QuantityCalculationRule.PeriodInHours;
			EndIf;
		ElsIf ValueIsFilled(pSrvRow.RoomRate) And pSrvRow.RoomRate.PeriodInHours <> 0 Then
			vCurPeriodInHours = pSrvRow.RoomRate.PeriodInHours;
		EndIf;
		If vCurPeriodInHours <> 0 Then
			vRoomType = pSrvRow.RoomType;
			vRoom = pSrvRow.Room;
			vAccommodationType = pDocObj.AccommodationType;
			vNumberOfPersonsPerRoom = pDocObj.NumberOfPersonsPerRoom;
			vNumberOfBedsPerRoom = pDocObj.NumberOfBedsPerRoom;
			vNumberOfRooms = pDocObj.NumberOfRooms;
			vNumberOfBeds = pDocObj.NumberOfBeds;
			vNumberOfAdditionalBeds = pDocObj.NumberOfAdditionalBeds;
			vNumberOfPersons = pDocObj.NumberOfPersons;
			vIsVirtual = False;
			If vRoomType <> pDocObj.RoomType Then
				If ValueIsFilled(vRoom) Then
					vRoomAttrs = vRoom.GetObject().pmGetRoomAttributes(cm1SecondShift(pSrvRow.AccountingDate));
					For Each vRoomAttrsRow In vRoomAttrs Do
						vNumberOfBedsPerRoom = vRoomAttrsRow.NumberOfBedsPerRoom;
						vNumberOfPersonsPerRoom = vRoomAttrsRow.NumberOfPersonsPerRoom;
						vIsVirtual = vRoomAttrsRow.IsVirtual;
						Break;
					EndDo;
				ElsIf ValueIsFilled(vRoomType) Then
					vNumberOfBedsPerRoom = vRoomType.NumberOfBedsPerRoom;
					vNumberOfPersonsPerRoom = vRoomType.NumberOfPersonsPerRoom;
					vIsVirtual = vRoomType.IsVirtual;
				EndIf;
			EndIf;
			If pSrvRow.AccommodationType <> vAccommodationType Then
				// Fill accommodation type resources
				If ValueIsFilled(vAccommodationType) And Not vIsVirtual Then
					If vAccommodationType.Type = Enums.AccomodationTypes.Room Then
						vNumberOfRooms = vAccommodationType.NumberOfRooms;
						vNumberOfBeds = ?(vAccommodationType.NumberOfRooms = 0, 0, vNumberOfBedsPerRoom);
						vNumberOfAdditionalBeds = vAccommodationType.NumberOfAdditionalBeds;
					ElsIf vAccommodationType.Type = Enums.AccomodationTypes.Beds Then
						vNumberOfRooms = 0;
						vNumberOfBeds = vAccommodationType.NumberOfBeds;
						vNumberOfAdditionalBeds = vAccommodationType.NumberOfAdditionalBeds;
					ElsIf vAccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Then
						vNumberOfRooms = 0;
						vNumberOfBeds = 0;
						vNumberOfAdditionalBeds = vAccommodationType.NumberOfAdditionalBeds;
					ElsIf vAccommodationType.Type = Enums.AccomodationTypes.Together Then
						vNumberOfRooms = 0;
						vNumberOfBeds = 0;
						vNumberOfAdditionalBeds = vAccommodationType.NumberOfAdditionalBeds;
					EndIf;
				Else
					vNumberOfRooms = 0;
					vNumberOfBeds = 0;
					vNumberOfAdditionalBeds = 0;
				EndIf;
			EndIf;
			pSrvRow.RoomsRented = ?(vNumberOfBedsPerRoom = 0, 0, Round(vNumberOfBeds/vNumberOfBedsPerRoom * pSrvRow.Quantity*vCurPeriodInHours / 24, 7));
			pSrvRow.BedsRented = Round(vNumberOfBeds * pSrvRow.Quantity * vCurPeriodInHours / 24, 7);
			pSrvRow.AdditionalBedsRented = Round(vNumberOfAdditionalBeds * pSrvRow.Quantity * vCurPeriodInHours / 24, 7);
			pSrvRow.GuestDays = Round(vNumberOfPersons * pSrvRow.Quantity * vCurPeriodInHours / 24, 7);
			If TypeOf(pDocObj) = Type("DocumentObject.Reservation") Then
				If pDocObj.RoomQuantity > 1 Then
					pSrvRow.RoomsRented = Round(pSrvRow.RoomsRented / pDocObj.RoomQuantity, 7);
					pSrvRow.BedsRented = Round(pSrvRow.BedsRented / pDocObj.RoomQuantity, 7);
					pSrvRow.AdditionalBedsRented = Round(pSrvRow.AdditionalBedsRented / pDocObj.RoomQuantity, 7);
					pSrvRow.GuestDays = Round(pSrvRow.GuestDays / pDocObj.RoomQuantity, 7);
				EndIf;
			EndIf;
			If pSrvRow.GuestsCheckedIn <> 0 Then
				pSrvRow.GuestsCheckedIn = pDocObj.NumberOfPersons;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmRecalculateServiceRoomSalesParameters

// -----------------------------------------------------------------------------
// Description: Returns currency exchange rate
// Parameters: Hotel, Currency, Date to get rate on
// Return value: Currency exchange rate
// -----------------------------------------------------------------------------
Function cmGetCurrencyExchangeRate(pHotel, pCurrency, pDate, pUseTCHQRate = False) Export
	vRate = 0;
	
	// Common checks	
	If Not ValueIsFilled(pHotel) Then
		Raise(NStr("en='ERR: Error calling cmGetCurrencyExchangeRate function.
		               |CAUSE: Empty pHotel parameter value was passed to the function.
					   |DESC: Mandatory parameter pHotel should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetCurrencyExchangeRate.
					   |CAUSE: В функцию передано пустое значение параметра pHotel.
					   |DESC: Обязательный параметр pHotel должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetCurrencyExchangeRate.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pHotel übertragen.
					   |DESC: Das Pflichtparameter pHotel muss eindeutig angegeben sein.'"));
	EndIf;
	If Not ValueIsFilled(pCurrency) Then
		Raise(NStr("en='ERR: Error calling cmGetCurrencyExchangeRate function.
		               |CAUSE: Empty pCurrency parameter value was passed to the function.
					   |DESC: Mandatory parameter pCurrency should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetCurrencyExchangeRate.
				       |CAUSE: В функцию передано пустое значение параметра pCurrency.
					   |DESC: Обязательный параметр pCurrency должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetCurrencyExchangeRate.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pCurrency übertragen.
					   |DESC: Das Pflichtparameter pCurrency muss eindeutig angegeben sein.'"));
	EndIf;
	
	// Check if currency is base currency
	If pHotel.BaseCurrency = pCurrency Then
		Return 1;
	EndIf;
	
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	* 
	|FROM
	|	InformationRegister.CurrencyRates.SliceLast(
	|	&qDate, 
	|	Hotel = &qHotel AND Currency = &qCurrency) AS CurrencyRates";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCurrency", pCurrency);
	vExRt = vQry.Execute().Unload();
	
	// Get exchange rate
	For Each vExRtRow In VExRt Do
		If pUseTCHQRate Then
			vRate = ?(vExRtRow.TravellerChequeRate = 0, vExRtRow.Rate, vExRtRow.TravellerChequeRate) / ?(vExRtRow.Factor = 0, 1, vExRtRow.Factor);
		Else
			vRate = vExRtRow.Rate/?(vExRtRow.Factor = 0, 1, vExRtRow.Factor);
		EndIf;
		Break;
	EndDo;
	
	Return vRate;
EndFunction // cmGetCurrencyExchangeRate

// -----------------------------------------------------------------------------
// Description: Returns currency exchange rates value table
// Parameters: Hotel, Currency, Date to get rate on
// Return value: Currency exchange rates value table
// -----------------------------------------------------------------------------
Function cmGetCurrencyExchangeRates(pHotel, pCurrency, pDate) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	// Build and run query
	vQry = New Query();
	vQry.Text = 
			"SELECT 
			|	* 
			|FROM
			|	InformationRegister.CurrencyRates.SliceLast(
			|	&qDate, TRUE" + 
				?(ValueISFilled(pHotel), " AND Hotel IN HIERARCHY (&qHotel)", "") + 
				?(ValueIsFilled(pCurrency), " AND Currency = &qCurrency", "") + "
			|	) AS CurrencyRates";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCurrency", pCurrency);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetCurrencyExchangeRates

// -----------------------------------------------------------------------------
//  Recalculates amount from one currency to another
//
// Parameters:
//  pSum						 - 	 - 
//  pFromCurrency				 - 	 - 
//  pFromCurrencyExchangeRate	 - 	 - 
//  pToCurrency					 - 	 - 
//  pToCurrencyExchangeRate		 - 	 - 
//  pExchangeRateDate			 - 	 - 
//  pHotel						 - 	 - 
// 
// Returns:
//  Number - Amount in to currency
//
Function cmConvertCurrencies(pSum, pFromCurrency, pFromCurrencyExchangeRate = 0, pToCurrency, pToCurrencyExchangeRate = 0, pExchangeRateDate = Undefined, pHotel = Undefined) Export
	If pFromCurrency = pToCurrency And pFromCurrencyExchangeRate = pToCurrencyExchangeRate Then
		Return pSum;
	EndIf;
	// Get exchange rates if not specified
	If pFromCurrencyExchangeRate = 0 Then
		pFromCurrencyExchangeRate = cmGetCurrencyExchangeRate(pHotel, pFromCurrency, pExchangeRateDate);
	EndIf;
	If pToCurrencyExchangeRate = 0 Then
		pToCurrencyExchangeRate = cmGetCurrencyExchangeRate(pHotel, pToCurrency, pExchangeRateDate);
	EndIf;
	If pToCurrencyExchangeRate = 0 Then
		Return 0;
	EndIf;
	If pFromCurrencyExchangeRate = pToCurrencyExchangeRate Then
		Return pSum;
	EndIf;
	// Convert input sum
	Return pSum * pFromCurrencyExchangeRate/pToCurrencyExchangeRate;
EndFunction // cmConvertCurrencies

// -----------------------------------------------------------------------------
// Description: Tries to find service in the value table of manual prices. 
//              If found change input price and currency to manual ones.
// Parameters: Manual prices value table, Service, Price to return, 
//             Service unit of measure to return, Calendar day type
// Return value: None
// -----------------------------------------------------------------------------
Function cmGetManualPrice(pMPTab, pService, rPrice, rCurrency, rUnit, pCalendarDayType, rRemarks = "") Export
	vMPRow = Undefined;
	vManualPriceFound = False;
	// 1. Check services of the same calendar day type as input parameter is
	vMPRows = pMPTab.FindRows(New Structure("Service, CalendarDayType", pService, pCalendarDayType));
	If vMPRows.Count() > 0 Then
		vMPRow = vMPRows.Get(0);
	Else
		// 2. Check services only
		vMPRows = pMPTab.FindRows(New Structure("Service, CalendarDayType", pService, Catalogs.CalendarDayTypes.EmptyRef()));
		If vMPRows.Count() > 0 Then
			vMPRow = vMPRows.Get(0);
		EndIf;
	EndIf;
	If Not vMPRow = Undefined Then
		vManualPriceFound = True;
		rPrice = vMPRow.Price;
		rCurrency = vMPRow.Currency;
		rUnit = vMPRow.Unit;
		If IsBlankString(rRemarks) And Not IsBlankString(vMPRow.Remarks) Then
			rRemarks = TrimAll(vMPRow.Remarks);
		EndIf;
	EndIf;
	Return vManualPriceFound;
EndFunction // cmGetManualPrice

// -----------------------------------------------------------------------------
// Description: Checks whether given service is in the service group specified or not
// Parameters: Service to check, Service group where to check 
// Return value: Boolean, true if service was found in the service group, false if not
// -----------------------------------------------------------------------------
Function cmIsServiceInServiceGroup(pService, pServiceGroup) Export
	Return CachedAccounts.IsServiceInServiceGroup(pService, pServiceGroup);
EndFunction // cmIsServiceInServiceGroup

// -----------------------------------------------------------------------------
// Returns first preauthorisation document for the given transaction id
// -----------------------------------------------------------------------------
Function cmGetFirstPreauthorisationByTransactionID(pTransactionID, pFolioRef) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Preauthorisation.Ref
	|FROM
	|	Document.Preauthorisation AS Preauthorisation
	|WHERE
	|	Preauthorisation.Posted
	|	AND Preauthorisation.TransactionID = &qTransactionID
	|	AND Preauthorisation.Status = &qStatus
	|	AND Preauthorisation.Folio = &qFolio
	|
	|ORDER BY
	|	Preauthorisation.PointInTime";
	vQry.SetParameter("qTransactionID", pTransactionID);
	vQry.SetParameter("qStatus", Enums.PreauthorisationStatuses.Authorised);
	vQry.SetParameter("qFolio", pFolioRef);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		Return vDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetFirstPreauthorisationByTransactionID

// -----------------------------------------------------------------------------
// Description: Checks wether given service fits to the given charging rule row  
// Parameters: Charging rule row, Service to check, Service date, Whether given service is in the rate or not, 
//             Whether service is room revenue or not, Company
// Return value: Boolean, true if service fits to the charging rule, false if not
// -----------------------------------------------------------------------------
Function cmIsServiceFitToTheChargingRule(pChargingRuleRow, pService, pDate, pIsInRate = False, pIsRoomRevenue = False, pCompany = Undefined, pIsFromResourceReservation = False) Export
	vDate = pDate;
	// First check charging rule priod
	If (vDate < pChargingRuleRow.ValidFromDate) Or
	   (vDate > pChargingRuleRow.ValidToDate) And ValueIsFilled(pChargingRuleRow.ValidToDate) Then
		Return False;
	EndIf;
	// Check company
	If ValueIsFilled(pCompany) Then
		If ValueIsFilled(pChargingRuleRow.ChargingFolio) Then
			If ValueIsFilled(pChargingRuleRow.ChargingFolio.Company) Then
				If pChargingRuleRow.ChargingFolio.Company <> pCompany Then
					Return False;
				EndIf;
			EndIf;
		EndIf;
	EndIf;             
	vResCancel = False;
	// Then check rule types	   
	If pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.Any Then
		vResCancel = True;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.InRate Then
		If pIsInRate And ValueIsFilled(pService) And Not (pService.IsResortFee And Not pService.IsInPrice) Then
			vResCancel = True;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.NotInRate Then
		If Not pIsInRate Or ValueIsFilled(pService) And (pService.IsResortFee And Not pService.IsInPrice) Then
			vResCancel = True;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.AllButOne Then
		If pChargingRuleRow.ChargingRuleValue <> pService Then
			vResCancel = True;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.One Then
		If pChargingRuleRow.ChargingRuleValue = pService Then
			vResCancel = True;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.InServiceGroup Then
		If cmIsServiceInServiceGroup(pService, pChargingRuleRow.ChargingRuleValue) Then
			vResCancel = True;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.NotInServiceGroup Then
		If Not cmIsServiceInServiceGroup(pService, pChargingRuleRow.ChargingRuleValue) Then
			vResCancel = True;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePrice Then
		If pIsRoomRevenue And ValueIsFilled(pService) And Not (pService.IsResortFee And Not pService.IsInPrice) Then
			vResCancel = True;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePricePercent Then
		If pIsRoomRevenue And ValueIsFilled(pService) And Not (pService.IsResortFee And Not pService.IsInPrice) Then
			vResCancel = True;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenueAmount Then
		If pIsInRate And ValueIsFilled(pService) And Not (pService.IsResortFee And Not pService.IsInPrice) Then
			vResCancel = True;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePriceByRoomType Then
		If pIsRoomRevenue And ValueIsFilled(pService) And Not (pService.IsResortFee And Not pService.IsInPrice) Then
			vResCancel = True;
		EndIf;
	ElsIf pChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.RestOfRoomRevenuePrice Then
		If pIsRoomRevenue And ValueIsFilled(pService) And Not (pService.IsResortFee And Not pService.IsInPrice) Then
			vResCancel = True;
		EndIf;
	EndIf;
	Return vResCancel;
EndFunction // cmIsServiceFitToTheChargingRule

// -----------------------------------------------------------------------------
//  Returns value table of charges for the accommodation or reservation specified
//
// Parameters:
//  pDoc			 - DocumentRef	 - Reference to the accommodation or reservation document
//  pIsForFolioSplit - Boolean		 - IsForFolioSplit
// 
// Returns:
//  ValueTable - Value table with charges
//
Function cmGetTableOfAlreadyChargedServices(pDoc, pIsForFolioSplit = False, pOldGuestGroup = Undefined, pOldClient = Undefined, pOldClientCitizenship = Undefined, pOldClientRegion = Undefined, pOldClientCity = Undefined, pOldClientAge = Undefined, pOldTouristicTaxExemptionReason = Undefined, pOldTouristicTaxExemptionReasonFillDate = Undefined) Export
	// Common checks	
	If Not ValueIsFilled(pDoc) Then
		Raise(NStr("en='ERR: Error calling cmGetTableOfAlreadyChargedServices function.
		               |CAUSE: Empty pDoc parameter value was passed to the function.
					   |DESC: Mandatory parameter pDoc should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetTableOfAlreadyChargedServices.
				       |CAUSE: В функцию передано пустое значение параметра pDoc.
					   |DESC: Обязательный параметр pDoc должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetTabbleOfAlreadyChargedServices.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pDoc übertragen.
					   |DESC: Das Pflichtparameter pDoc muss eindeutig angegeben sein.'"));
	EndIf;
	
	// Build and run query
	qCharges = New Query;
	qCharges.Text = 
	"SELECT
	|	CASE
	|		WHEN ChargeDocuments.CorrectedCharge <> &qEmptyCharge
	|			THEN ChargeDocuments.CorrectedCharge
	|		ELSE ChargeDocuments.Ref
	|	END AS DocRef,
	|	SUM(ChargeDocuments.Sum) AS Sum,
	|	SUM(ChargeDocuments.Quantity) AS Quantity,
	|	SUM(ChargeDocuments.VATSum) AS VATSum,
	|	SUM(ChargeDocuments.DiscountSum) AS DiscountSum,
	|	SUM(ChargeDocuments.VATDiscountSum) AS VATDiscountSum,
	|	SUM(ChargeDocuments.CommissionSum) AS CommissionSum,
	|	SUM(ChargeDocuments.VATCommissionSum) AS VATCommissionSum
	|INTO ChargeDocuments
	|FROM
	|	Document.Charge AS ChargeDocuments
	|WHERE
	|	(ChargeDocuments.ParentDoc = &qDoc
	|			OR &qIsAccommodation
	|				AND ChargeDocuments.ParentDoc = &qRes)
	|	AND NOT ChargeDocuments.IsAdditional
	|	AND ChargeDocuments.Posted
	|
	|GROUP BY
	|	CASE
	|		WHEN ChargeDocuments.CorrectedCharge <> &qEmptyCharge
	|			THEN ChargeDocuments.CorrectedCharge
	|		ELSE ChargeDocuments.Ref
	|	END
	|
	|HAVING
	|	(SUM(ChargeDocuments.Sum) <> 0
	|		OR SUM(ChargeDocuments.Quantity) <> 0
	|		OR SUM(ChargeDocuments.VATSum) <> 0
	|		OR SUM(ChargeDocuments.DiscountSum) <> 0
	|		OR SUM(ChargeDocuments.VATDiscountSum) <> 0
	|		OR SUM(ChargeDocuments.CommissionSum) <> 0
	|		OR SUM(ChargeDocuments.VATCommissionSum) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN Charges.CorrectionDate <> &qEmptyDate
	|			THEN BEGINOFPERIOD(Charges.CorrectionDate, DAY)
	|		ELSE BEGINOFPERIOD(Charges.Date, DAY)
	|	END AS AccountingDate,
	|	Charges.Folio AS Folio,
	|	Charges.Folio.Agent AS Agent,
	|	Charges.Folio.Customer AS Customer,
	|	Charges.Folio.Contract AS Contract,
	|	CASE
	|		WHEN &qOldGuestGroup <> UNDEFINED
	|			THEN &qOldGuestGroup
	|		ELSE Charges.Folio.GuestGroup
	|	END AS GuestGroup,
	|	Charges.Folio.PaymentMethod AS PaymentMethod,
	|	CASE
	|		WHEN &qOldClient <> UNDEFINED
	|			THEN &qOldClient
	|		WHEN Charges.ParentDoc.Guest IS NULL
	|			THEN Charges.ParentDoc.Client
	|		ELSE Charges.ParentDoc.Guest
	|	END AS Client,
	|	CASE
	|		WHEN &qOldClientCitizenship <> UNDEFINED
	|			THEN &qOldClientCitizenship
	|		WHEN Charges.ParentDoc.Guest IS NULL
	|			THEN Charges.ParentDoc.Client.Citizenship
	|		ELSE Charges.ParentDoc.Guest.Citizenship
	|	END AS ClientCitizenship,
	|	CASE
	|		WHEN &qOldClientRegion <> UNDEFINED
	|			THEN &qOldClientRegion
	|		WHEN Charges.ParentDoc.Guest IS NULL
	|			THEN Charges.ParentDoc.Client.Region
	|		ELSE Charges.ParentDoc.Guest.Region
	|	END AS ClientRegion,
	|	CASE
	|		WHEN &qOldClientCity <> UNDEFINED
	|			THEN &qOldClientCity
	|		WHEN Charges.ParentDoc.Guest IS NULL
	|			THEN Charges.ParentDoc.Client.City
	|		ELSE Charges.ParentDoc.Guest.City
	|	END AS ClientCity,
	|	ISNULL(CASE
	|			WHEN &qOldClientAge <> UNDEFINED
	|				THEN &qOldClientAge
	|			WHEN Charges.ParentDoc.Guest IS NULL
	|				THEN Charges.ParentDoc.Client.Age
	|			ELSE Charges.ParentDoc.Guest.Age
	|		END, 0) AS ClientAge,
	|	Charges.MarketingCode AS MarketingCode,
	|	Charges.SourceOfBusiness AS SourceOfBusiness,
	|	Charges.ParentDoc.TripPurpose AS TripPurpose,
	|	Charges.Room AS Room,
	|	Charges.RoomType AS RoomType,
	|	Charges.RoomRate AS RoomRate,
	|	ISNULL(Charges.AccommodationType, VALUE(Catalog.AccommodationTypes.EmptyRef)) AS AccommodationType,
	|	ISNULL(Charges.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) AS AccommodationTemplate,
	|	Charges.Resource AS Resource,
	|	Charges.Resource AS ServiceResource,
	|	Charges.Resource.Owner AS ResourceType,
	|	Charges.EventActivity AS EventActivity,
	|	Charges.TimeFrom AS TimeFrom,
	|	Charges.TimeTo AS TimeTo,
	|	Charges.Ref AS Ref,
	|	Charges.DeletionMark AS DeletionMark,
	|	Charges.Number AS Number,
	|	CASE
	|		WHEN Charges.CorrectionDate <> &qEmptyDate
	|			THEN Charges.CorrectionDate
	|		ELSE Charges.Date
	|	END AS Date,
	|	Charges.Posted AS Posted,
	|	Charges.ParentDoc AS ParentDoc,
	|	Charges.Hotel AS Hotel,
	|	Charges.ExchangeRateDate AS ExchangeRateDate,
	|	Charges.ClientType AS ClientType,
	|	Charges.ClientTypeConfirmationText AS ClientTypeConfirmationText,
	|	Charges.Service AS Service,
	|	Charges.Price AS Price,
	|	Charges.Ref.Unit AS Unit,
	|	ChargeDocuments.Quantity AS Quantity,
	|	ChargeDocuments.Sum AS Sum,
	|	Charges.VATRate AS VATRate,
	|	ChargeDocuments.VATSum AS VATSum,
	|	Charges.Remarks AS Remarks,
	|	Charges.IsRoomRevenue AS IsRoomRevenue,
	|	Charges.IsInPrice AS IsInPrice,
	|	Charges.IsResourceRevenue AS IsResourceRevenue,
	|	CASE
	|		WHEN Charges.IsResourceRevenue
	|			THEN ChargeDocuments.Sum - ChargeDocuments.DiscountSum
	|		ELSE 0
	|	END AS ResourceRevenue,
	|	CASE
	|		WHEN Charges.IsResourceRevenue
	|			THEN ChargeDocuments.Sum - ChargeDocuments.DiscountSum - ChargeDocuments.VATSum
	|		ELSE 0
	|	END AS ResourceRevenueWithoutVAT,
	|	CASE
	|		WHEN Charges.IsResourceRevenue
	|				AND NOT Charges.RoomRevenueAmountsOnly
	|				AND ISNULL(Charges.Service.IsPricePerMinute, FALSE)
	|			THEN ChargeDocuments.Quantity / 60
	|		WHEN Charges.IsResourceRevenue
	|				AND NOT Charges.RoomRevenueAmountsOnly
	|				AND NOT ISNULL(Charges.Service.IsPricePerMinute, FALSE)
	|			THEN ChargeDocuments.Quantity
	|		ELSE 0
	|	END AS HoursRented,
	|	Charges.CalendarDayType AS CalendarDayType,
	|	Charges.Timetable AS Timetable,
	|	Charges.PriceTag AS PriceTag,
	|	Charges.FolioCurrency AS FolioCurrency,
	|	Charges.FolioCurrencyExchangeRate AS FolioCurrencyExchangeRate,
	|	Charges.ReportingCurrency AS ReportingCurrency,
	|	Charges.ReportingCurrencyExchangeRate AS ReportingCurrencyExchangeRate,
	|	Charges.Folio.Company AS Company,
	|	Charges.RoomsRented AS RoomsRented,
	|	Charges.BedsRented AS BedsRented,
	|	Charges.AdditionalBedsRented AS AdditionalBedsRented,
	|	Charges.GuestDays AS GuestDays,
	|	Charges.GuestsCheckedIn AS GuestsCheckedIn,
	|	Charges.DiscountCard AS DiscountCard,
	|	Charges.DiscountType AS DiscountType,
	|	Charges.DiscountConfirmationText AS DiscountConfirmationText,
	|	Charges.Discount AS Discount,
	|	Charges.DiscountServiceGroup AS DiscountServiceGroup,
	|	ChargeDocuments.DiscountSum AS DiscountSum,
	|	ChargeDocuments.VATDiscountSum AS VATDiscountSum,
	|	Charges.AgentCommission AS AgentCommission,
	|	Charges.AgentCommissionType AS AgentCommissionType,
	|	Charges.AgentCommissionServiceGroup AS AgentCommissionServiceGroup,
	|	ChargeDocuments.CommissionSum AS CommissionSum,
	|	ChargeDocuments.VATCommissionSum AS VATCommissionSum,
	|	Charges.HotelProduct AS HotelProduct,
	|	Charges.ServicePackage AS ServicePackage,
	|	Charges.BoardPlace AS BoardPlace,
	|	Charges.ParentRoomService AS ParentRoomService,
	|	Charges.IsFixedCharge AS IsFixedCharge,
	|	Charges.IsAdditional AS IsAdditional,
	|	Charges.IsManual AS IsManual,
	|	Charges.IsSplit AS IsSplit,
	|	Charges.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
	|	Charges.RateSum AS RateSum,
	|	Charges.ChargeTransfer AS ChargeTransfer,
	|	Charges.Author AS Author,
	|	Charges.Presentation AS Presentation,
	|	Charges.PointInTime AS PointInTime,
	|	Charges.LineNumber AS LineNumber,
	|	&qIsForFolioSplit AS IsForFolioSplit,
	|	Charges.Service.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	Charges.IsMergedToRoomRevenue AS IsMergedToRoomRevenue,
	|	Charges.RoomRevenueCharge AS RoomRevenueCharge,
	|	&qOldTouristicTaxExemptionReason AS TouristicTaxExemptionReason,
	|	&qOldTouristicTaxExemptionReasonFillDate AS TouristicTaxExemptionReasonFillDate,
	|	Stornos.ParentCharge.RoomRevenueCharge AS StornoRoomRevenueCharge,
	|	ISNULL(Stornos.ParentCharge.Sum, 0) AS StornoSum,
	|	ISNULL(Stornos.ParentCharge.DiscountSum, 0) AS StornoDiscountSum,
	|	ISNULL(Stornos.ParentCharge.CommissionSum, 0) AS StornoCommissionSum
	|FROM
	|	Document.Charge AS Charges
	|		INNER JOIN ChargeDocuments AS ChargeDocuments
	|		ON Charges.Ref = ChargeDocuments.DocRef
	|		LEFT JOIN Document.Storno AS Stornos
	|		ON (Stornos.ParentCharge = Charges.Ref)
	|			AND (Stornos.Posted)
	|			AND (Charges.IsMergedToRoomRevenue)
	|			AND (Charges.RoomRevenueCharge <> VALUE(Document.Charge.EmptyRef))";
	qCharges.SetParameter("qDoc", pDoc);
	If TypeOf(pDoc) = Type("DocumentRef.Accommodation") And ValueIsFilled(pDoc.Reservation) Then
		qCharges.SetParameter("qRes", pDoc.Reservation);
		qCharges.SetParameter("qIsAccommodation", True);
	Else
		qCharges.SetParameter("qRes", Undefined);
		qCharges.SetParameter("qIsAccommodation", False);
	EndIf;
	qCharges.SetParameter("qEmptyCharge", Documents.Charge.EmptyRef());
	qCharges.SetParameter("qEmptyDate", '00010101');
	qCharges.SetParameter("qIsForFolioSplit", pIsForFolioSplit);
	qCharges.SetParameter("qOldGuestGroup", pOldGuestGroup);
	qCharges.SetParameter("qOldClient", pOldClient);
	qCharges.SetParameter("qOldClientCitizenship", pOldClientCitizenship);
	qCharges.SetParameter("qOldClientRegion", pOldClientRegion);
	qCharges.SetParameter("qOldClientCity", pOldClientCity);
	qCharges.SetParameter("qOldClientAge", pOldClientAge);
	qCharges.SetParameter("qOldTouristicTaxExemptionReason", pOldTouristicTaxExemptionReason);
	qCharges.SetParameter("qOldTouristicTaxExemptionReasonFillDate", pOldTouristicTaxExemptionReasonFillDate);
	vCharges = qCharges.Execute().Unload();
	If vCharges.Total("StornoSum") <> 0 Then
		For Each vChargesRow In vCharges Do
			If ValueIsFilled(vChargesRow.StornoRoomRevenueCharge) And vChargesRow.StornoSum <> 0 Then
				vRoomRevenueChargeRow = vCharges.Find(vChargesRow.StornoRoomRevenueCharge, "Ref");
				If vRoomRevenueChargeRow <> Undefined And vRoomRevenueChargeRow.IsMergedToRoomRevenue Then
					vRoomRevenueChargeRow.RateSum = vRoomRevenueChargeRow.RateSum + vChargesRow.StornoSum;
					vRoomRevenueChargeRow.StornoSum = vRoomRevenueChargeRow.StornoSum + vChargesRow.StornoSum;
					vRoomRevenueChargeRow.StornoDiscountSum = vRoomRevenueChargeRow.StornoDiscountSum + vChargesRow.StornoDiscountSum;
					vRoomRevenueChargeRow.StornoCommissionSum = vRoomRevenueChargeRow.StornoCommissionSum + vChargesRow.StornoCommissionSum;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vCharges;
EndFunction // cmGetTableOfAlreadyChargedServices

// -----------------------------------------------------------------------------
//  Returns value table of charges for the resource reservation specified
//
// Parameters:
//  pDoc			 - DocumentRef	 - Reference to the resource reservation document
// 
// Returns:
//  ValueTable - Value table with charges
//
Function cmGetTableOfResourceReservationAlreadyChargedServices(pDoc) Export
	// Common checks	
	If Not ValueIsFilled(pDoc) Then
		Raise(NStr("en='ERR: Error calling cmGetTableOfResourceReservationAlreadyChargedServices function.
		               |CAUSE: Empty pDoc parameter value was passed to the function.
					   |DESC: Mandatory parameter pDoc should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetTableOfResourceReservationAlreadyChargedServices.
				       |CAUSE: В функцию передано пустое значение параметра pDoc.
					   |DESC: Обязательный параметр pDoc должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetTableOfResourceReservationAlreadyChargedServices.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pDoc übertragen.
					   |DESC: Das Pflichtparameter pDoc muss eindeutig angegeben sein.'"));
	EndIf;
	
	// Build and run query
	qCharges = New Query;
	qCharges.Text = 
	"SELECT
	|	CASE
	|		WHEN ChargeDocuments.CorrectedCharge <> &qEmptyCharge
	|			THEN ChargeDocuments.CorrectedCharge
	|		ELSE ChargeDocuments.Ref
	|	END AS DocRef,
	|	SUM(ChargeDocuments.Sum) AS Sum,
	|	SUM(ChargeDocuments.Quantity) AS Quantity,
	|	SUM(ChargeDocuments.VATSum) AS VATSum,
	|	SUM(ChargeDocuments.DiscountSum) AS DiscountSum,
	|	SUM(ChargeDocuments.VATDiscountSum) AS VATDiscountSum,
	|	SUM(ChargeDocuments.CommissionSum) AS CommissionSum,
	|	SUM(ChargeDocuments.VATCommissionSum) AS VATCommissionSum
	|INTO ChargeDocuments
	|FROM
	|	Document.Charge AS ChargeDocuments
	|WHERE
	|	ChargeDocuments.ParentDoc = &qDoc
	|	AND NOT ChargeDocuments.IsAdditional
	|	AND ChargeDocuments.Posted
	|
	|GROUP BY
	|	CASE
	|		WHEN ChargeDocuments.CorrectedCharge <> &qEmptyCharge
	|			THEN ChargeDocuments.CorrectedCharge
	|		ELSE ChargeDocuments.Ref
	|	END
	|
	|HAVING
	|	(SUM(ChargeDocuments.Sum) <> 0
	|		OR SUM(ChargeDocuments.Quantity) <> 0
	|		OR SUM(ChargeDocuments.VATSum) <> 0
	|		OR SUM(ChargeDocuments.DiscountSum) <> 0
	|		OR SUM(ChargeDocuments.VATDiscountSum) <> 0
	|		OR SUM(ChargeDocuments.CommissionSum) <> 0
	|		OR SUM(ChargeDocuments.VATCommissionSum) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN Charges.CorrectionDate <> &qEmptyDate
	|			THEN BEGINOFPERIOD(Charges.CorrectionDate, DAY)
	|		WHEN Charges.ServiceDate <> &qEmptyDate
	|			THEN Charges.ServiceDate
	|		ELSE BEGINOFPERIOD(Charges.Date, DAY)
	|	END AS AccountingDate,
	|	Charges.Folio AS Folio,
	|	Charges.Folio.Agent AS Agent,
	|	Charges.Folio.Customer AS Customer,
	|	Charges.Folio.Contract AS Contract,
	|	Charges.Folio.GuestGroup AS GuestGroup,
	|	Charges.Folio.PaymentMethod AS PaymentMethod,
	|	Charges.ParentDoc.Client AS Client,
	|	Charges.ParentDoc.Client.Citizenship AS ClientCitizenship,
	|	Charges.ParentDoc.Client.Region AS ClientRegion,
	|	Charges.ParentDoc.Client.City AS ClientCity,
	|	ISNULL(Charges.ParentDoc.Client.Age, 0) AS ClientAge,
	|	Charges.MarketingCode AS MarketingCode,
	|	Charges.SourceOfBusiness AS SourceOfBusiness,
	|	Charges.ParentDoc.TripPurpose AS TripPurpose,
	|	Charges.Room AS Room,
	|	Charges.RoomType AS RoomType,
	|	Charges.RoomRate AS RoomRate,
	|	ISNULL(Charges.AccommodationType, VALUE(Catalog.AccommodationTypes.EmptyRef)) AS AccommodationType,
	|	ISNULL(Charges.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) AS AccommodationTemplate,
	|	Charges.Resource AS Resource,
	|	Charges.Resource AS ServiceResource,
	|	Charges.Resource.Owner AS ResourceType,
	|	Charges.EventActivity AS EventActivity,
	|	Charges.TimeFrom AS TimeFrom,
	|	Charges.TimeTo AS TimeTo,
	|	Charges.Ref AS Ref,
	|	Charges.DeletionMark AS DeletionMark,
	|	Charges.Number AS Number,
	|	CASE
	|		WHEN Charges.CorrectionDate <> &qEmptyDate
	|			THEN Charges.CorrectionDate
	|		ELSE Charges.Date
	|	END AS Date,
	|	Charges.Posted AS Posted,
	|	Charges.ParentDoc AS ParentDoc,
	|	Charges.Hotel AS Hotel,
	|	Charges.ExchangeRateDate AS ExchangeRateDate,
	|	Charges.ClientType AS ClientType,
	|	Charges.ClientTypeConfirmationText AS ClientTypeConfirmationText,
	|	Charges.Service AS Service,
	|	Charges.Price AS Price,
	|	Charges.Ref.Unit AS Unit,
	|	ChargeDocuments.Quantity AS Quantity,
	|	ChargeDocuments.Sum AS Sum,
	|	Charges.VATRate AS VATRate,
	|	ChargeDocuments.VATSum AS VATSum,
	|	Charges.Remarks AS Remarks,
	|	Charges.IsRoomRevenue AS IsRoomRevenue,
	|	Charges.IsInPrice AS IsInPrice,
	|	Charges.IsResourceRevenue AS IsResourceRevenue,
	|	CASE
	|		WHEN Charges.IsResourceRevenue
	|			THEN ChargeDocuments.Sum - ChargeDocuments.DiscountSum
	|		ELSE 0
	|	END AS ResourceRevenue,
	|	CASE
	|		WHEN Charges.IsResourceRevenue
	|			THEN ChargeDocuments.Sum - ChargeDocuments.DiscountSum - ChargeDocuments.VATSum
	|		ELSE 0
	|	END AS ResourceRevenueWithoutVAT,
	|	CASE
	|		WHEN Charges.IsResourceRevenue
	|				AND NOT Charges.RoomRevenueAmountsOnly
	|				AND ISNULL(Charges.Service.IsPricePerMinute, FALSE)
	|			THEN ChargeDocuments.Quantity / 60
	|		WHEN Charges.IsResourceRevenue
	|				AND NOT Charges.RoomRevenueAmountsOnly
	|				AND NOT ISNULL(Charges.Service.IsPricePerMinute, FALSE)
	|			THEN ChargeDocuments.Quantity
	|		ELSE 0
	|	END AS HoursRented,
	|	Charges.CalendarDayType AS CalendarDayType,
	|	Charges.Timetable AS Timetable,
	|	Charges.PriceTag AS PriceTag,
	|	Charges.FolioCurrency AS FolioCurrency,
	|	Charges.FolioCurrencyExchangeRate AS FolioCurrencyExchangeRate,
	|	Charges.ReportingCurrency AS ReportingCurrency,
	|	Charges.ReportingCurrencyExchangeRate AS ReportingCurrencyExchangeRate,
	|	Charges.Folio.Company AS Company,
	|	Charges.RoomsRented AS RoomsRented,
	|	Charges.BedsRented AS BedsRented,
	|	Charges.AdditionalBedsRented AS AdditionalBedsRented,
	|	Charges.GuestDays AS GuestDays,
	|	Charges.GuestsCheckedIn AS GuestsCheckedIn,
	|	Charges.DiscountCard AS DiscountCard,
	|	Charges.DiscountType AS DiscountType,
	|	Charges.DiscountConfirmationText AS DiscountConfirmationText,
	|	Charges.Discount AS Discount,
	|	Charges.DiscountServiceGroup AS DiscountServiceGroup,
	|	ChargeDocuments.DiscountSum AS DiscountSum,
	|	ChargeDocuments.VATDiscountSum AS VATDiscountSum,
	|	Charges.AgentCommission AS AgentCommission,
	|	Charges.AgentCommissionType AS AgentCommissionType,
	|	Charges.AgentCommissionServiceGroup AS AgentCommissionServiceGroup,
	|	ChargeDocuments.CommissionSum AS CommissionSum,
	|	ChargeDocuments.VATCommissionSum AS VATCommissionSum,
	|	Charges.HotelProduct AS HotelProduct,
	|	Charges.ServicePackage AS ServicePackage,
	|	Charges.BoardPlace AS BoardPlace,
	|	Charges.ParentRoomService AS ParentRoomService,
	|	Charges.IsFixedCharge AS IsFixedCharge,
	|	Charges.IsAdditional AS IsAdditional,
	|	Charges.IsManual AS IsManual,
	|	Charges.IsSplit AS IsSplit,
	|	Charges.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
	|	Charges.RateSum AS RateSum,
	|	Charges.ChargeTransfer AS ChargeTransfer,
	|	Charges.Author AS Author,
	|	Charges.Presentation AS Presentation,
	|	Charges.PointInTime AS PointInTime,
	|	Charges.LineNumber AS LineNumber,
	|	Charges.Service.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	ISNULL(Stornos.ParentCharge.Sum, 0) AS StornoSum,
	|	ISNULL(Stornos.ParentCharge.DiscountSum, 0) AS StornoDiscountSum,
	|	ISNULL(Stornos.ParentCharge.CommissionSum, 0) AS StornoCommissionSum
	|FROM
	|	Document.Charge AS Charges
	|		INNER JOIN ChargeDocuments AS ChargeDocuments
	|		ON Charges.Ref = ChargeDocuments.DocRef
	|		LEFT JOIN Document.Storno AS Stornos
	|		ON (Stornos.ParentCharge = Charges.Ref)
	|			AND (Stornos.Posted)
	|			AND (Charges.IsMergedToRoomRevenue)
	|			AND (Charges.RoomRevenueCharge <> VALUE(Document.Charge.EmptyRef))";
	qCharges.SetParameter("qDoc", pDoc);
	qCharges.SetParameter("qEmptyCharge", Documents.Charge.EmptyRef());
	qCharges.SetParameter("qEmptyDate", '00010101');
	vCharges = qCharges.Execute().Unload();
	Return vCharges;
EndFunction // cmGetTableOfResourceReservationAlreadyChargedServices

// -----------------------------------------------------------------------------
//  Returns value table of charges for the accommodation or reservation specified
//
// Parameters:
//  pDoc				 - 	 - 
//  pCustomer			 - 	 - 
//  pContract			 - 	 - 
//  pHotel				 - 	 - 
//  pIsClosed			 - 	 - 
//  pDoNotCheckCustomer	 - 	 - 
// 
// Returns:
//  ValueTable - Value table with charges
//
Function cmGetDocumentCharges(pDoc, pCustomer, pContract, pHotel, pIsClosed = Undefined, pDoNotCheckCustomer = False) Export
	// Common checks	
	If Not ValueIsFilled(pDoc) Then
		Raise(NStr("en='ERR: Error calling cmGetDocumentCharges function.
		               |CAUSE: Empty pDoc parameter value was passed to the function.
					   |DESC: Mandatory parameter pDoc should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetDocumentCharges.
				       |CAUSE: В функцию передано пустое значение параметра pDoc.
					   |DESC: Обязательный параметр pDoc должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetDocumentCharges.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pDoc übertragen.
					   |DESC: Das Pflichtparameter pDoc muss eindeutig angegeben sein.'"));
	EndIf;
	
	// Build and run query
	qCharges = New Query;
	qCharges.Text = 
	"SELECT
	|	Accounts.Folio AS Folio,
	|	BEGINOFPERIOD(Accounts.Period, DAY) AS AccountingDate,
	|	Accounts.Service AS Service,
	|	Accounts.Price AS Price,
	|	Accounts.Quantity AS Quantity,
	|	Accounts.Charge.Unit AS Unit,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN CASE
	|					WHEN Accounts.Charge.IsMergedToRoomRevenue
	|						THEN -(Accounts.Charge.RateSum - Accounts.Charge.RateDiscountSum)
	|					ELSE -(Accounts.Charge.Sum - Accounts.Charge.DiscountSum)
	|				END
	|		ELSE CASE
	|				WHEN Accounts.Charge.IsMergedToRoomRevenue
	|					THEN Accounts.Charge.RateSum - Accounts.Charge.RateDiscountSum
	|				ELSE Accounts.Charge.Sum - Accounts.Charge.DiscountSum
	|			END
	|	END AS Sum,
	|	Accounts.VATRate AS VATRate,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN -(Accounts.Charge.VATSum - Accounts.Charge.VATDiscountSum)
	|		ELSE Accounts.Charge.VATSum - Accounts.Charge.VATDiscountSum
	|	END AS VATSum,
	|	Accounts.IsRoomRevenue AS IsRoomRevenue,
	|	Accounts.IsInPrice AS IsInPrice,
	|	Accounts.CalendarDayType AS CalendarDayType,
	|	Accounts.Charge.Timetable AS Timetable,
	|	Accounts.Charge.PriceTag AS PriceTag,
	|	Accounts.FolioCurrency AS FolioCurrency,
	|	Accounts.Charge.FolioCurrencyExchangeRate AS FolioCurrencyExchangeRate,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN -Accounts.Charge.RoomsRented
	|		ELSE Accounts.Charge.RoomsRented
	|	END AS RoomsRented,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN -Accounts.Charge.BedsRented
	|		ELSE Accounts.Charge.BedsRented
	|	END AS BedsRented,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN -Accounts.Charge.AdditionalBedsRented
	|		ELSE Accounts.Charge.AdditionalBedsRented
	|	END AS AdditionalBedsRented,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN -Accounts.Charge.GuestDays
	|		ELSE Accounts.Charge.GuestDays
	|	END AS GuestDays,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN -Accounts.Charge.GuestsCheckedIn
	|		ELSE Accounts.Charge.GuestsCheckedIn
	|	END AS GuestsCheckedIn,
	|	Accounts.Charge.DiscountType AS DiscountType,
	|	Accounts.Charge.Discount AS Discount,
	|	Accounts.Charge.DiscountServiceGroup AS DiscountServiceGroup,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN -Accounts.Charge.DiscountSum
	|		ELSE Accounts.Charge.DiscountSum
	|	END AS DiscountSum,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN -Accounts.Charge.VATDiscountSum
	|		ELSE Accounts.Charge.VATDiscountSum
	|	END AS VATDiscountSum,
	|	Accounts.Charge.DiscountConfirmationText AS DiscountConfirmationText,
	|	Accounts.Charge.AgentCommissionType AS AgentCommissionType,
	|	Accounts.Charge.AgentCommission AS AgentCommission,
	|	Accounts.Charge.AgentCommissionServiceGroup AS AgentCommissionServiceGroup,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN -Accounts.Charge.CommissionSum
	|		ELSE Accounts.Charge.CommissionSum
	|	END AS CommissionSum,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Storno
	|			THEN -Accounts.Charge.VATCommissionSum
	|		ELSE Accounts.Charge.VATCommissionSum
	|	END AS VATCommissionSum,
	|	Accounts.Remarks AS Remarks,
	|	Accounts.Charge.Company AS Company,
	|	Accounts.Charge.RoomRate AS RoomRate,
	|	Accounts.Charge.AccommodationType AS AccommodationType,
	|	Accounts.Charge.RoomType AS RoomType,
	|	Accounts.Charge.Room AS Room,
	|	Accounts.Charge.Resource AS Resource,
	|	Accounts.Charge.IsAdditional AS IsAdditional,
	|	Accounts.Charge.IsManual AS IsManual,
	|	Accounts.Charge.IsManual AS IsManualPrice,
	|	Accounts.Charge.IsSplit AS IsSplit,
	|	Accounts.Charge.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
	|	Accounts.Charge.RateSum AS RateSum,
	|	Accounts.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.RecordType = &qReceipt
	|	AND Accounts.ParentDoc = &qDoc
	|	AND Accounts.Folio IN
	|			(SELECT
	|				Folios.Ref
	|			FROM
	|				Document.Folio AS Folios
	|			WHERE
	|				Folios.GuestGroup = &qGuestGroup
	|				AND (Folios.Customer = &qCustomer
	|					OR Folios.Customer = &qEmptyCustomer
	|						AND &qCustomer = &qIndividualsCustomer
	|					OR Folios.Customer <> &qEmptyCustomer
	|						AND Folios.Customer.IsIndividual
	|						AND &qCustomer = &qIndividualsCustomer
	|					OR &qDoNotCheckCustomer)
	|				AND (Folios.Contract = &qContract
	|					OR Folios.Contract = &qEmptyContract
	|						AND &qContract = &qIndividualsContract
	|					OR &qDoNotCheckCustomer)
	|				AND NOT Folios.DeletionMark
	|				AND (Folios.IsClosed = &qIsClosed
	|					OR &qIsClosedNotSet))";
	qCharges.SetParameter("qDoc", pDoc);
	qCharges.SetParameter("qGuestGroup", pDoc.GuestGroup);
	qCharges.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	qCharges.SetParameter("qCustomer", pCustomer);
	qCharges.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	qCharges.SetParameter("qIndividualsCustomer", pHotel.IndividualsCustomer);
	qCharges.SetParameter("qContract", pContract);
	qCharges.SetParameter("qEmptyContract", Catalogs.Contracts.EmptyRef());
	qCharges.SetParameter("qIndividualsContract", pHotel.IndividualsContract);
	If pIsClosed = Undefined Then
		qCharges.SetParameter("qIsClosed", False);
		qCharges.SetParameter("qIsClosedNotSet", True);
	Else
		qCharges.SetParameter("qIsClosed", pIsClosed);
		qCharges.SetParameter("qIsClosedNotSet", False);
	EndIf;
	qCharges.SetParameter("qDoNotCheckCustomer", pDoNotCheckCustomer);
	vCharges = qCharges.Execute().Unload();
	For Each vChargesRow In vCharges Do
		vChargesRow.Price = cmRecalculatePrice(vChargesRow.Sum, vChargesRow.Quantity);
		vChargesRow.VATSum = cmCalculateVATSum(vChargesRow.VATRate, vChargesRow.Sum, vChargesRow.AccountingDate);
	EndDo;
	Return vCharges;
EndFunction // cmGetDocumentCharges

// -----------------------------------------------------------------------------
// Description: Returns value table of charges for the record phone call or record room service document
// Parameters: Reference to the record phone call or record room service document
// Return value: Value table with charges
// -----------------------------------------------------------------------------
Function cmGetRoomServiceDocumentCharges(pDoc) Export
	// Common checks	
	If Not ValueIsFilled(pDoc) Then
		Raise(NStr("en='ERR: Error calling cmGetRoomServiceDocumentCharges function.
		               |CAUSE: Empty pDoc parameter value was passed to the function.
					   |DESC: Mandatory parameter pDoc should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetRoomServiceDocumentCharges.
				       |CAUSE: В функцию передано пустое значение параметра pDoc.
					   |DESC: Обязательный параметр pDoc должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetOfRoomServiceDocumentCharges.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pDoc übertragen.
					   |DESC: Das Pflichtparameter pDoc muss eindeutig angegeben sein.'"));
	EndIf;
	
	// Build and run query
	qCharges = New Query;
	qCharges.Text = 
	"SELECT
	|	Accounts.Recorder AS Charge
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.RecordType = &qReceipt
	|	AND Accounts.Recorder.ParentRoomService = &qDoc";
	qCharges.SetParameter("qDoc", pDoc);
	qCharges.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vCharges = qCharges.Execute().Unload();
	Return vCharges;
EndFunction // cmGetRoomServiceDocumentCharges

// -----------------------------------------------------------------------------
// Description: Adds new dimension columns to the accommodation or reservation services value table. 
//              Dimension columns are those used in dimensions of analitical register Sales
// Parameters: Value table with document services
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmAddServicesDimensionsColumns(pServicesTab) Export
	pServicesTab.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"), "Hotel", 20);
	pServicesTab.Columns.Add("Agent", cmGetCatalogTypeDescription("Customers"), "Agent", 20);
	pServicesTab.Columns.Add("AgentCommissionServiceGroup", cmGetCatalogTypeDescription("ServiceGroups"), "Agent commission service group", 20);
	pServicesTab.Columns.Add("Customer", cmGetCatalogTypeDescription("Customers"), "Customer", 20);
	pServicesTab.Columns.Add("Contract", cmGetCatalogTypeDescription("Contracts"), "Contract", 20);
	pServicesTab.Columns.Add("GuestGroup", cmGetCatalogTypeDescription("GuestGroups"), "GuestGroup", 20);
	pServicesTab.Columns.Add("Client", cmGetCatalogTypeDescription("Clients"), "Client", 20);
	pServicesTab.Columns.Add("ClientAge", cmGetNumberTypeDescription(3, 0), "Age", 3);
	pServicesTab.Columns.Add("TripPurpose", cmGetCatalogTypeDescription("TripPurposes"), "Trip purpose", 20);
	pServicesTab.Columns.Add("PaymentMethod", cmGetCatalogTypeDescription("PaymentMethods"), "Payment method", 20);
	pServicesTab.Columns.Add("ExchangeRateDate", cmGetDateTypeDescription(), "Exchange rate date", 20);
	pServicesTab.Columns.Add("NumberOfPersons", cmGetNumberOfPersonsTypeDescription(), "Number of persons", 10);
	pServicesTab.Columns.Add("ReportingCurrency", cmGetCatalogTypeDescription("Currencies"), "Reporting currency", 10);
	pServicesTab.Columns.Add("ReportingCurrencyExchangeRate", cmGetExchangeRateTypeDescription(), "Reporting currency exchange rate", 20);
	pServicesTab.Columns.Add("DiscountCard", cmGetCatalogTypeDescription("DiscountCards"), "Discount card", 20);
	pServicesTab.Columns.Add("HotelProduct", cmGetCatalogTypeDescription("HotelProducts"), "Hotel product", 20);
	pServicesTab.Columns.Add("IsForFolioSplit", cmGetBooleanTypeDescription(), "Is folio split mode", 20);
	pServicesTab.Columns.Add("ChargeToEachGuestSeparately", cmGetBooleanTypeDescription(), "Charge to each guest separately", 20);
	pServicesTab.Columns.Add("AccommodationTemplate", cmGetCatalogTypeDescription("AccommodationTemplates"), "Persons", 20);
	pServicesTab.Columns.Add("TouristicTaxExemptionReason", cmGetCatalogTypeDescription("ResortFeeExemptionReasons"), "Exemption reason", 20);
	pServicesTab.Columns.Add("TouristicTaxExemptionReasonFillDate", cmGetDateTypeDescription(), "Exemption date", 10);
EndProcedure // cmAddServicesDimensionsColumns

// -----------------------------------------------------------------------------
// Description: Fill service dimension avlues from the accommodation/reservation attributes
// Parameters: Service row, Document object, Client's citizenship, region, city and age
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillServicesDimensionsColumns(pSrv, pObj) Export
	vFolio = pSrv.Folio;
	vService = pSrv.Service;
	
	pSrv.Hotel = pObj.Hotel;
	pSrv.Agent = vFolio.Agent;
	pSrv.AgentCommissionServiceGroup = pObj.AgentCommissionServiceGroup;
	pSrv.Customer = vFolio.Customer;
	pSrv.Contract = vFolio.Contract;
	pSrv.GuestGroup = vFolio.GuestGroup;
	If Not ValueIsFilled(pSrv.RoomRate) Then
		pSrv.RoomRate = pObj.RoomRate;
	EndIf;
	If Not ValueIsFilled(pSrv.AccommodationType) Then
		pSrv.AccommodationType = pObj.AccommodationType;
	EndIf;
	If Not ValueIsFilled(pSrv.Room) Then
		pSrv.Room = pObj.Room;
	EndIf;
	If Not ValueIsFilled(pSrv.RoomType) Then
		pSrv.RoomType = pObj.RoomType;
	EndIf;
	pSrv.Client = pObj.Guest;
	If ValueIsFilled(pObj.Guest) Then
		vGuest = pObj.Guest;
		pSrv.ClientAge = vGuest.Age;
	Else
		pSrv.ClientAge = 0;
	EndIf;
	If Not ValueIsFilled(pSrv.ClientType) And ValueIsFilled(pObj.ClientType) Then
		pSrv.ClientType = pObj.ClientType;
	EndIf;
	If Not ValueIsFilled(pSrv.MarketingCode) And ValueIsFilled(pObj.MarketingCode) Then
		pSrv.MarketingCode = pObj.MarketingCode;
	EndIf;
	If Not ValueIsFilled(pSrv.SourceOfBusiness) And ValueIsFilled(pObj.SourceOfBusiness) Then
		pSrv.SourceOfBusiness = pObj.SourceOfBusiness;
	EndIf;
	If Not ValueIsFilled(pSrv.BoardPlace) And ValueIsFilled(pObj.BoardPlace) Then
		pSrv.BoardPlace = pObj.BoardPlace;
	EndIf;
	pSrv.TripPurpose = pObj.TripPurpose;
	pSrv.PaymentMethod = vFolio.PaymentMethod;
	pSrv.ExchangeRateDate = pSrv.AccountingDate;
	pSrv.NumberOfPersons = pObj.NumberOfPersons;
	pSrv.ReportingCurrency = pObj.ReportingCurrency;
	pSrv.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(pSrv.Hotel, pSrv.FolioCurrency, pSrv.ExchangeRateDate);
	pSrv.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(pSrv.Hotel, pSrv.ReportingCurrency, pSrv.ExchangeRateDate);
	pSrv.DiscountCard = pObj.DiscountCard;
	If ValueIsFilled(vService) And TypeOf(vService) = Type("CatalogRef.Services") Then 
		pSrv.ChargeToEachGuestSeparately = vService.ChargeToEachGuestSeparately; 
		If vService.IsHotelProductService Then
			If ValueIsFilled(vFolio.HotelProduct) Then
				pSrv.HotelProduct = vFolio.HotelProduct;
			Else
				pSrv.HotelProduct = pObj.HotelProduct;
			EndIf;
		EndIf;
	Else
		pSrv.ChargeToEachGuestSeparately = False;
	EndIf;
	pSrv.TouristicTaxExemptionReason = pObj.TouristicTaxExemptionReason;
	pSrv.TouristicTaxExemptionReasonFillDate = pObj.TouristicTaxExemptionReasonFillDate;
	pSrv.IsForFolioSplit = pObj.IsForFolioSplit;
	pSrv.AccommodationTemplate = pObj.AccommodationTemplate;
	// Process change history
	For Each vRRRow In pObj.RoomRates Do
		If BegOfDay(vRRRow.AccountingDate) <= pSrv.AccountingDate Then
			If ValueIsFilled(vRRRow.AccommodationTemplate) Then
				If vRRRow.AccommodationTemplate = Catalogs.AccommodationTemplates.NoTemplate Then
					pSrv.AccommodationTemplate = Catalogs.AccommodationTemplates.EmptyRef();
				Else
					pSrv.AccommodationTemplate = vRRRow.AccommodationTemplate;
				EndIf;
			EndIf;
		Else
			Break;
		EndIf;
	EndDo;
EndProcedure // cmFillServicesDimensionsColumns

// -----------------------------------------------------------------------------
// Description: Compares value tables with old and new services with each other. 
// Parameters: New services value table, Old services value table
// Return value: Returns value table with rows that are not the same in both input value tables
// -----------------------------------------------------------------------------
Function cmGetServicesDifference(pTabS, pTabC) Export
	// Create resulting value table
	vDiffTabS = pTabS.Copy();
	
	// Add services from second table with negative resources
	For Each vTabCRow In pTabC Do
		vTabSRow = vDiffTabS.Add();
		FillPropertyValues(vTabSRow, vTabCRow, , "Quantity, Sum, VATSum, RoomsRented, BedsRented, AdditionalBedsRented, GuestDays, GuestsCheckedIn, CommissionSum, VATCommissionSum, DiscountSum, VATDiscountSum, RateSum");
		vTabSRow.Quantity = vTabSRow.Quantity - vTabCRow.Quantity;
		vTabSRow.Sum = vTabSRow.Sum - vTabCRow.Sum;
		vTabSRow.VATSum = vTabSRow.VATSum - vTabCRow.VATSum;
		vTabSRow.RoomsRented = vTabSRow.RoomsRented - vTabCRow.RoomsRented;
		vTabSRow.BedsRented = vTabSRow.BedsRented - vTabCRow.BedsRented;
		vTabSRow.AdditionalBedsRented = vTabSRow.AdditionalBedsRented - vTabCRow.AdditionalBedsRented;
		vTabSRow.GuestDays = vTabSRow.GuestDays - vTabCRow.GuestDays;
		vTabSRow.GuestsCheckedIn = vTabSRow.GuestsCheckedIn - vTabCRow.GuestsCheckedIn;
		vTabSRow.CommissionSum = vTabSRow.CommissionSum - vTabCRow.CommissionSum;
		vTabSRow.VATCommissionSum = vTabSRow.VATCommissionSum - vTabCRow.VATCommissionSum;
		vTabSRow.DiscountSum = vTabSRow.DiscountSum - vTabCRow.DiscountSum;
		vTabSRow.VATDiscountSum = vTabSRow.VATDiscountSum - vTabCRow.VATDiscountSum;
		vTabSRow.RateSum = vTabSRow.RateSum - vTabCRow.RateSum;
	EndDo;
	
	// Reset folio to empty value
	vDiffTabS.FillValues(Documents.Folio.EmptyRef(), "Folio");
	
	// Group by services
	vGroupByColumns = "Hotel, Company, Agent, Customer, Contract, GuestGroup, RoomRate, Client, ClientAge, ClientType, " + 
	                  "MarketingCode, SourceOfBusiness, TripPurpose, RoomType, Room, AccommodationType, AccommodationTemplate, PaymentMethod, ServiceResource, TimeFrom, TimeTo, " + 
	                  "AccountingDate, ExchangeRateDate, Service, CalendarDayType, Timetable, PriceTag, HotelProduct, ServicePackage, BoardPlace, " +
	                  "Price, Unit, VATRate, Remarks, FolioCurrency, FolioCurrencyExchangeRate, Folio, " +
	                  "DiscountCard, DiscountType, DiscountConfirmationText, Discount, AgentCommission, AgentCommissionType, AgentCommissionServiceGroup, " +
	                  "ReportingCurrency, ReportingCurrencyExchangeRate, IsRoomRevenue, IsInPrice, IsManual, IsSplit, RoomRevenueAmountsOnly, LineNumber, IsForFolioSplit, ChargeToEachGuestSeparately, " + 
	                  "TouristicTaxExemptionReason, TouristicTaxExemptionReasonFillDate";
	vSumColumns = "Quantity, Sum, VATSum, RoomsRented, BedsRented, AdditionalBedsRented, GuestDays, GuestsCheckedIn, CommissionSum, VATCommissionSum, DiscountSum, VATDiscountSum, RateSum"; 
	vDiffTabS.GroupBy(vGroupByColumns, vSumColumns);
	
	// Return result
	Return vDiffTabS;
EndFunction // cmGetServicesDifference

// -----------------------------------------------------------------------------
//  Checks if all service row resources like amount, quantity, VAT quantity, discount sum and so on are equal zero
//
// Parameters:
//  pSrvRow	 - ValueTableRow - Service row to check
// 
// Returns:
//  Boolean - True if all resources are zero, False if at least one of them is not
//
Function cmServiceResourcesAreZero(pSrvRow) Export
	If pSrvRow.Quantity = 0 And
	   pSrvRow.Sum = 0 And
	   pSrvRow.VATSum = 0 And
	   pSrvRow.CommissionSum = 0 And
	   pSrvRow.VATCommissionSum = 0 And
	   pSrvRow.DiscountSum = 0 And
	   pSrvRow.VATDiscountSum = 0 And
	   pSrvRow.RoomsRented = 0 And
	   pSrvRow.BedsRented = 0 And
	   pSrvRow.AdditionalBedsRented = 0 And
	   pSrvRow.GuestDays = 0 And
	   pSrvRow.GuestsCheckedIn = 0 And 
	   pSrvRow.RateSum = 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmServiceResourcesAreZero

// -----------------------------------------------------------------------------
// Description: Tries to find row in the input services value table with the same 
//              accounting parameters as other input service row has
// Parameters: Services value table where to search, Services row with accounting parameter values to search
// Return value: Row from the input value table if found or undefined if not
// -----------------------------------------------------------------------------
Function cmGetChargeRow(pTabC, pSrvRow) Export
	vRows = pTabC.FindRows(New Structure("AccountingDate, LineNumber, Service", pSrvRow.AccountingDate, pSrvRow.LineNumber, pSrvRow.Service));
	If vRows.Count()>0 Then
		Return vRows[0];
	EndIf;	
	Return Undefined;
EndFunction // cmGetChargeRow

// -----------------------------------------------------------------------------
//  Initializes new folio object with parameters from the template folio
//
// Parameters:
//  pFolioObj	 - 	 - 
//  pTemplateRef - 	 - 
//  pHotel		 - 	 - 
//  pDate		 - 	 - 
//
Procedure cmFillFolioFromTemplate(pFolioObj, pTemplateRef = Undefined, Val pHotel = Undefined, Val pDate = Undefined) Export
	If pHotel = Undefined Then
		pHotel = SessionParameters.CurrentHotel;
	EndIf;
	pFolioObj.pmFillAttributesWithDefaultValues();
	If ValueIsFilled(pDate) Then
		pFolioObj.Date = pDate;
	Else
		pFolioObj.SetTime(AutoTimeMode.CurrentOrLast);
	EndIf;
	If ValueIsFilled(pHotel) Then
		If pHotel <> pFolioObj.Hotel Then
			pFolioObj.Hotel = pHotel;
			pFolioObj.IsClosed = False;
			pFolioObj.FolioCurrency = pHotel.FolioCurrency;
			pFolioObj.PaymentMethod = pHotel.PlannedPaymentMethod;   
			pFolioObj.SetNewNumber(Catalogs.Hotels.pmGetPrefix(pHotel));
		EndIf;
	EndIf;
	If ValueIsFilled(pTemplateRef) Then
		If Not pTemplateRef.IsMaster Then
			pFolioObj.Description = pTemplateRef.Description;
			If pTemplateRef.DoNotUpdateCompany Then
				pFolioObj.Company = pTemplateRef.Company;
			Else
				pFolioObj.Company = pHotel.Company;
			EndIf;
			pFolioObj.FolioCurrency = pTemplateRef.FolioCurrency;
			pFolioObj.ParentDoc = pTemplateRef.ParentDoc;
			pFolioObj.Agent = pTemplateRef.Agent;
			pFolioObj.Customer = pTemplateRef.Customer;
			pFolioObj.Contract = pTemplateRef.Contract;
			pFolioObj.Client = pTemplateRef.Client;
			pFolioObj.GuestGroup = pTemplateRef.GuestGroup;
			pFolioObj.Room = pTemplateRef.Room;
			pFolioObj.DateTimeFrom = pTemplateRef.DateTimeFrom;
			pFolioObj.DateTimeTo = pTemplateRef.DateTimeTo;
			pFolioObj.PaymentSection = pTemplateRef.PaymentSection;
			pFolioObj.PaymentMethod = pTemplateRef.PaymentMethod;
			pFolioObj.CreditLimit = pTemplateRef.CreditLimit;
			pFolioObj.DoNotUpdateCompany = pTemplateRef.DoNotUpdateCompany;
			pFolioObj.DoNotUpdateCustomer = pTemplateRef.DoNotUpdateCustomer;
			pFolioObj.DoNotFillAgent = pTemplateRef.DoNotFillAgent;
			pFolioObj.HotelProduct = pTemplateRef.HotelProduct;
		EndIf;
	EndIf;
EndProcedure // cmFillFolioFromTemplate

// -----------------------------------------------------------------------------
// Description: Returns value table with list of active folios for the given room and currency. 
//              Folios created by accommodations or reservations for the given room are skipped. 
// Parameters: Hotel, Room, Folio currency
// Return value: Value table with room folios list
// -----------------------------------------------------------------------------
Function cmGetActiveRoomFolios(pHotel, pRoom, pFolioCurrency) Export
	// Common checks	
	If Not ValueIsFilled(pHotel) Then
		Raise(NStr("en='ERR: Error calling cmGetActiveRoomFolios function.
		               |CAUSE: Empty pHotel parameter value was passed to the function.
					   |DESC: Mandatory parameter pHotel should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetActiveRoomFolios.
				       |CAUSE: В функцию передано пустое значение параметра pHotel.
					   |DESC: Обязательный параметр pHotel должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetActiveRoomFolios.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pHotel übertragen. 
					   |DESC: Das Pflichtparameter pHotel muss eindeutig angegeben sein.'"));
	EndIf;
	If Not ValueIsFilled(pHotel) Then
		Raise(NStr("en='ERR: Error calling cmGetActiveRoomFolios function.
		               |CAUSE: Empty pRoom parameter value was passed to the function.
					   |DESC: Mandatory parameter pRoom should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetActiveRoomFolios.
				       |CAUSE: В функцию передано пустое значение параметра pRoom.
					   |DESC: Обязательный параметр pRoom должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetActiveRoomFolios.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pRoom übertragen.
					   |DESC: Das Pflichtparameter pRoom muss eindeutig angegeben sein.'"));
	EndIf;
	If Not ValueIsFilled(pFolioCurrency) Then
		Raise(NStr("en='ERR: Error calling cmGetActiveRoomFolios function.
		               |CAUSE: Empty pFolioCurrency parameter value was passed to the function.
					   |DESC: Mandatory parameter pFolioCurrency should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetActiveRoomFolios.
				       |CAUSE: В функцию передано пустое значение параметра pFolioCurrency.
					   |DESC: Обязательный параметр pFolioCurrency должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetActiveExchangeRate.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pCurrency übertragen.
					   |DESC: Das Pflichtparameter pCurrency muss eindeutig angegeben sein.'"));
	EndIf;
	
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Folio,
	|	Folio.IsClosed,
	|	Folio.FolioCurrency,
	|	Folio.Hotel,
	|	Folio.Room,
	|	Folio.PointInTime AS PointInTime
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.IsClosed = FALSE
	|	AND Folio.FolioCurrency = &qFolioCurrency
	|	AND Folio.Hotel = &qHotel
	|	AND Folio.Room = &qRoom
	|	AND Folio.Customer = &qEmptyCustomer
	|	AND Folio.Contract = &qEmptyContract
	|	AND Folio.Client = &qEmptyClient
	|	AND Folio.GuestGroup = &qEmptyGuestGroup
	|	AND Folio.DeletionMark = FALSE
	|ORDER BY
	|	PointInTime";
	vQry.SetParameter("qFolioCurrency", pFolioCurrency);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qEmptyContract", Catalogs.Contracts.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyGuestGroup", Catalogs.GuestGroups.EmptyRef());
	vQryRes = vQry.Execute().Unload();
	
	Return vQryRes;
EndFunction // cmGetActiveRoomFolios

// -----------------------------------------------------------------------------
// Description: Returns value table with list of active folios for the given document. 
// Parameters: Accommodation or Reservation reference
// Return value: Value table with folios list
// -----------------------------------------------------------------------------
Function cmGetActiveDocumentFolios(pDoc) Export
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Folio
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.ParentDoc = &qDoc
	|	AND Folio.IsClosed = FALSE
	|	AND Folio.DeletionMark = FALSE
	|
	|ORDER BY
	|	Folio.PointInTime";
	vQry.SetParameter("qDoc", pDoc);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetActiveDocumentFolios

// -----------------------------------------------------------------------------
// Description: Returns value table with list of active documents bound to the folio given 
// Parameters: Folio document reference
// Return value: Value table with active documents
// -----------------------------------------------------------------------------
Function cmGetActiveFolioDocuments(pFolio, pDoc) Export
	// Check that there is no other active documents referencing this folio
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ResourceReservation.Ref AS Ref
	|FROM
	|	Document.ResourceReservation AS ResourceReservation
	|WHERE
	|	ResourceReservation.Posted
	|	AND ResourceReservation.ChargingFolio = &qFolio
	|	AND ResourceReservation.Ref <> &qDoc
	|	AND ISNULL(ResourceReservation.ResourceReservationStatus.IsActive, FALSE)
	|	AND NOT ISNULL(ResourceReservation.ResourceReservationStatus.ServicesAreDelivered, FALSE)
	|
	|UNION ALL
	|
	|SELECT
	|	ReservationChargingRules.Ref
	|FROM
	|	Document.Reservation.ChargingRules AS ReservationChargingRules
	|WHERE
	|	ReservationChargingRules.Ref.Posted
	|	AND ReservationChargingRules.ChargingFolio = &qFolio
	|	AND ReservationChargingRules.Ref <> &qDoc
	|	AND NOT ReservationChargingRules.IsTransfer
	|	AND (ISNULL(ReservationChargingRules.Ref.ReservationStatus.IsActive, FALSE)
	|				AND NOT ISNULL(ReservationChargingRules.Ref.ReservationStatus.IsCheckIn, FALSE)
	|			OR ISNULL(ReservationChargingRules.Ref.ReservationStatus.IsPreliminary, FALSE))
	|
	|UNION ALL
	|
	|SELECT
	|	AccommodationChargingRules.Ref
	|FROM
	|	Document.Accommodation.ChargingRules AS AccommodationChargingRules
	|WHERE
	|	AccommodationChargingRules.Ref.Posted
	|	AND AccommodationChargingRules.ChargingFolio = &qFolio
	|	AND AccommodationChargingRules.Ref <> &qDoc
	|	AND NOT AccommodationChargingRules.IsTransfer
	|	AND ISNULL(AccommodationChargingRules.Ref.AccommodationStatus.IsActive, FALSE)
	|	AND ISNULL(AccommodationChargingRules.Ref.AccommodationStatus.IsInHouse, FALSE)";
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qDoc", pDoc);
	vFolioDocs = vQry.Execute().Unload();
	Return vFolioDocs;
EndFunction // cmGetActiveFolioDocuments

// -----------------------------------------------------------------------------
// Description: Returns value table with list of closed folios for the given document. 
// Parameters: Accommodation or Reservation reference
// Return value: Value table with folios list
// -----------------------------------------------------------------------------
Function cmGetInactiveDocumentFolios(pDoc) Export
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Folio
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.ParentDoc = &qDoc
	|	AND Folio.IsClosed = TRUE
	|	AND Folio.DeletionMark = FALSE
	|ORDER BY
	|	Folio.PointInTime";
	vQry.SetParameter("qDoc", pDoc);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetInactiveDocumentFolios

// -----------------------------------------------------------------------------
//  Description: Returns value table with balances for accommodations or reservations.
//  Balances are normally returned for the guest check-out dates but if hotel has
//  "Show debts on current date" parameter turned on, then balances are calculated for the current date
//
// Parameters:
//  pDocList - ValueList		 - Value list with documents to return balances for
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  ValueTable - Row contains Client debt value, Client credit card preauthorisation balance, Customer debt value
//
Function cmGetDocumentListBalances(pDocList, pHotel) Export
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccountsBalance.FolioCurrency AS FolioCurrency,
	|	AccountsBalance.FolioParentDoc AS FolioParentDoc,
	|	AccountsBalance.FolioParentDoc.Number AS FolioParentDocNumber,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance,
	|	SUM(AccountsBalance.ClientCreditLimit) AS ClientCreditLimit
	|FROM
	|	(SELECT
	|		ClientAccountsBalance.FolioCurrency AS FolioCurrency,
	|		ClientAccountsBalance.Folio.ParentDoc AS FolioParentDoc,
	|		SUM(ClientAccountsBalance.SumBalance) AS ClientSumBalance,
	|		-SUM(ClientAccountsBalance.LimitBalance) AS ClientLimitBalance,
	|		0 AS CustomerSumBalance,
	|		SUM(ClientAccountsBalance.Folio.CreditLimit) AS ClientCreditLimit
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				&qBalancesPeriod,
	|				(Folio.Customer = &qEmptyCustomer
	|					OR Folio.Customer <> &qEmptyCustomer
	|						AND Folio.Customer.IsIndividual)
	|					AND Folio.ParentDoc IN (&qDocList)) AS ClientAccountsBalance
	|	
	|	GROUP BY
	|		ClientAccountsBalance.FolioCurrency,
	|		ClientAccountsBalance.Folio.ParentDoc
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerAccountsBalance.FolioCurrency,
	|		CustomerAccountsBalance.Folio.ParentDoc,
	|		0,
	|		-SUM(CustomerAccountsBalance.LimitBalance),
	|		SUM(CustomerAccountsBalance.SumBalance),
	|		0
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				&qBalancesPeriod,
	|				Folio.Customer <> &qEmptyCustomer
	|					AND NOT ISNULL(Folio.Customer.IsIndividual, FALSE)
	|					AND Folio.ParentDoc IN (&qDocList)) AS CustomerAccountsBalance
	|	
	|	GROUP BY
	|		CustomerAccountsBalance.FolioCurrency,
	|		CustomerAccountsBalance.Folio.ParentDoc) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.FolioCurrency,
	|	AccountsBalance.FolioParentDoc,
	|	AccountsBalance.FolioParentDoc.Number";
	vQry.SetParameter("qBalancesPeriod", ?(ValueIsFilled(pHotel), ?(pHotel.ShowDebtsOnCurrentDate, CurrentSessionDate(), '39991231235959'), '39991231235959'));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qDocList", pDocList);
	Return vQry.Execute().Unload();
EndFunction // cmGetDocumentListBalances

// -----------------------------------------------------------------------------
// Description: Returns value table with balances for clients. 
//              Balances are normally returned for end of time but if hotel has 
//              "Show debts on current date" parameter turned on, then balances are calculated for the current date
// Parameters: Value list with clients to return balances for, Hotel
// Return value: Return value table row contains Client debt value, Client credit card preauthorisation balance
// -----------------------------------------------------------------------------
Function cmGetClientListBalances(pClientList, pHotel) Export
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccountsBalance.FolioCurrency AS FolioCurrency,
	|	AccountsBalance.FolioClient AS FolioClient,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance
	|FROM
	|	(SELECT
	|		ClientAccountsBalance.FolioCurrency AS FolioCurrency,
	|		ClientAccountsBalance.Folio.Client AS FolioClient,
	|		SUM(ClientAccountsBalance.SumBalance) AS ClientSumBalance,
	|		-SUM(ClientAccountsBalance.LimitBalance) AS ClientLimitBalance,
	|		0 AS CustomerSumBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				&qBalancesPeriod,
	|				(Folio.Customer = &qEmptyCustomer
	|					OR Folio.Customer <> &qEmptyCustomer
	|						AND ISNULL(Folio.Customer.IsIndividual, FALSE))
	|					AND Folio.Client IN (&qClientList)) AS ClientAccountsBalance
	|	
	|	GROUP BY
	|		ClientAccountsBalance.FolioCurrency,
	|		ClientAccountsBalance.Folio.Client
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerAccountsBalance.FolioCurrency,
	|		CustomerAccountsBalance.Folio.Client,
	|		0,
	|		-SUM(CustomerAccountsBalance.LimitBalance),
	|		SUM(CustomerAccountsBalance.SumBalance)
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				&qBalancesPeriod,
	|				Folio.Customer <> &qEmptyCustomer
	|					AND NOT ISNULL(Folio.Customer.IsIndividual, FALSE)
	|					AND Folio.Client IN (&qClientList)) AS CustomerAccountsBalance
	|	
	|	GROUP BY
	|		CustomerAccountsBalance.FolioCurrency,
	|		CustomerAccountsBalance.Folio.Client) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.FolioCurrency,
	|	AccountsBalance.FolioClient";
	vQry.SetParameter("qBalancesPeriod", ?(ValueIsFilled(pHotel), ?(pHotel.ShowDebtsOnCurrentDate, CurrentSessionDate(), '39991231235959'), '39991231235959'));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qClientList", pClientList);
	Return vQry.Execute().Unload();
EndFunction // cmGetClientListBalances

// -----------------------------------------------------------------------------
// Description: Returns value table with balances in different currencies for the given client and room 
// Parameters: Date to calculate balances, Room, Client
// Return value: Return value table row contains Client debt value, Client credit card preauthorisation balance
// -----------------------------------------------------------------------------
Function cmGetClientRoomBalances(pPeriod, pRoom, pClient) Export
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientAccountsBalance.FolioCurrency AS FolioCurrency,
	|	SUM(ClientAccountsBalance.SumBalance) AS ClientSumBalance,
	|	SUM(ClientAccountsBalance.LimitBalance) AS ClientLimitBalance
	|FROM
	|	AccumulationRegister.Accounts.Balance(
	|			&qPeriod,
	|			(Folio.Customer = &qEmptyCustomer
	|				OR Folio.Customer <> &qEmptyCustomer
	|					AND Folio.Customer.IsIndividual)
	|				AND Folio.Client = &qClient
	|				AND Folio.Room = &qRoom) AS ClientAccountsBalance
	|
	|GROUP BY
	|	ClientAccountsBalance.FolioCurrency";
	vQry.SetParameter("qPeriod", ?(ValueIsFilled(pPeriod), pPeriod, '39991231235959'));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qClient", pClient);
	vQry.SetParameter("qRoom", pRoom);
	Return vQry.Execute().Unload();
EndFunction // cmGetClientRoomBalances

// -----------------------------------------------------------------------------
// Get balance for all folios in the value list. Balance is returned by payment sections
// - pDate is optional. If is not specified, then function calculates current balance
// - pHotel is optional. If is not specified, then function calculates balance for the 
//   folio hotel. If it is not specified, then function calculates balance per all hotels.
// - pPaymentSection is optional. If it is specified, then function calculates balance for the given payment section only
// Returns value table with balances for each folio from the input value list
// -----------------------------------------------------------------------------
Function cmGetFoliosBalanceByPaymentSections(Val pDate = Undefined, Val pHotel = Undefined, Val pPaymentSection = Undefined, pFoliosList) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			If Not SessionParameters.CurrentHotel.ShowDebtsOnCurrentDate Then
				pDate = '39991231235959';
			EndIf;
		EndIf;
	EndIf;

	// Build query to get accounts balance
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	SUM(ISNULL(AccountsBalance.SumBalance, 0)) AS SumBalance, 
	|	-SUM(ISNULL(AccountsBalance.LimitBalance, 0)) AS LimitBalance, " +
		?(ValueIsFilled(pHotel), "AccountsBalance.Hotel AS Hotel, ", "") + 
	"	AccountsBalance.FolioCurrency AS FolioCurrency,
	|	AccountsBalance.Folio AS Folio,
	|	AccountsBalance.PaymentSection.VATRate AS VATRate,
	|	AccountsBalance.PaymentSection AS PaymentSection
	|FROM
	|	AccumulationRegister.Accounts.Balance(&qDate, " +
		?(ValueIsFilled(pHotel), "Hotel = &qHotel AND ", "") +
		?(pPaymentSection <> Undefined, "PaymentSection = &qPaymentSection AND ", "") +
		"Folio IN (&qFoliosList)) AS AccountsBalance
	|GROUP BY " +
		?(ValueIsFilled(pHotel), "AccountsBalance.Hotel, ", "") +
	"	AccountsBalance.FolioCurrency,
	|	AccountsBalance.Folio,
	|	AccountsBalance.PaymentSection.VATRate,
	|	AccountsBalance.PaymentSection";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qFoliosList", pFoliosList);
	If pPaymentSection <> Undefined Then
		vQry.SetParameter("qPaymentSection", pPaymentSection);
	EndIf;
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetFoliosBalanceByPaymentSections

// -----------------------------------------------------------------------------
// Get balance for all folios in the value list. Balance is returned by cheque services and prices
// - pDate is optional. If is not specified, then function calculates current balance
// - pHotel is optional. If is not specified, then function calculates balance for the 
//   folio hotel. If it is not specified, then function calculates balance per all hotels.
// - pService is optional. If it is specified, then function calculates balance for the given service only
// Returns value table with balances for each folio from the input value list
// -----------------------------------------------------------------------------
Function cmGetFoliosBalanceByServicesAndPrices(Val pDate = Undefined, Val pHotel = Undefined, Val pService = Undefined, pFoliosList) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			If Not SessionParameters.CurrentHotel.ShowDebtsOnCurrentDate Then
				pDate = '39991231235959';
			EndIf;
		EndIf;
	EndIf;

	// Build query to get accounts balance
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	SUM(ISNULL(AccountsBalance.SumBalance, 0)) AS SumBalance, 
	|	SUM(ISNULL(AccountsBalance.ChequeServiceQuantityBalance, 0)) AS ChequeServiceQuantityBalance, 
	|	-SUM(ISNULL(AccountsBalance.LimitBalance, 0)) AS LimitBalance, " +
		?(ValueIsFilled(pHotel), "AccountsBalance.Hotel AS Hotel, ", "") + 
	"	AccountsBalance.FolioCurrency AS FolioCurrency,
	|	AccountsBalance.Folio AS Folio,
	|	AccountsBalance.ChequeService.PaymentSection.VATRate AS VATRate,
	|	AccountsBalance.ChequeService AS ChequeService,
	|	AccountsBalance.ChequeServicePrice AS ChequeServicePrice
	|FROM
	|	AccumulationRegister.Accounts.Balance(&qDate, " +
		?(ValueIsFilled(pHotel), "Hotel = &qHotel AND ", "") +
		?(pService <> Undefined, "ChequeService = &qChequeService AND ", "") +
		"Folio IN (&qFoliosList)) AS AccountsBalance
	|GROUP BY " +
		?(ValueIsFilled(pHotel), "AccountsBalance.Hotel, ", "") +
	"	AccountsBalance.FolioCurrency,
	|	AccountsBalance.Folio,
	|	AccountsBalance.ChequeService.PaymentSection.VATRate,
	|	AccountsBalance.ChequeService,
	|	AccountsBalance.ChequeServicePrice";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qFoliosList", pFoliosList);
	If pService <> Undefined Then
		vQry.SetParameter("qChequeService", pService);
	EndIf;
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetFoliosBalanceByServicesAndPrices

// -----------------------------------------------------------------------------
// Get balance for all folios in the value list
// - pDate is optional. If is not specified, then function calculates current balance
// - pHotel is optional. If is not specified, then function calculates balance for the 
//   folio hotel. If it is not specified, then function calculates balance per all hotels.
// - pPaymentSection is optional. If it is specified, then function calculates balance for the given payment section only
// Returns value table with balances for each folio from the input value list
// -----------------------------------------------------------------------------
Function cmGetFoliosBalance(Val pDate = Undefined, Val pHotel = Undefined, Val pPaymentSection = Undefined, pFoliosList) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			If Not SessionParameters.CurrentHotel.ShowDebtsOnCurrentDate Then
				pDate = '39991231235959';
			EndIf;
		EndIf;
	EndIf;
	// Build query to get accounts balance
	vQry = New Query;
	If ValueIsFilled(pHotel) Then
		vQry.Text =
		"SELECT
		|	AccountsBalance.Hotel AS Hotel,
		|	AccountsBalance.FolioCurrency AS FolioCurrency,
		|	AccountsBalance.Folio AS Folio,
		|	ISNULL(AccountsBalance.SumClosingBalance, 0) AS SumBalance,
		|	ISNULL(AccountsBalance.SumReceipt, 0) AS AmountCharged,
		|	ISNULL(AccountsBalance.SumExpense, 0) AS AmountPaid,
		|	-ISNULL(AccountsBalance.LimitClosingBalance, 0) AS LimitBalance
		|FROM
		|	AccumulationRegister.Accounts.BalanceAndTurnovers(
		|			,
		|			&qDate,
		|			PERIOD,
		|			RegisterRecordsAndPeriodBoundaries,
		|			Hotel = &qHotel
		|				AND (NOT &qPaymentSectionIsFilled
		|					OR &qPaymentSectionIsFilled
		|						AND PaymentSection = &qPaymentSection)
		|				AND Folio IN (&qFoliosList)) AS AccountsBalance";
		vQry.SetParameter("qHotel", pHotel);
	Else
		vQry.Text =
		"SELECT
		|	AccountsBalance.FolioCurrency AS FolioCurrency,
		|	AccountsBalance.Folio AS Folio,
		|	ISNULL(AccountsBalance.SumClosingBalance, 0) AS SumBalance,
		|	ISNULL(AccountsBalance.SumReceipt, 0) AS AmountCharged,
		|	ISNULL(AccountsBalance.SumExpense, 0) AS AmountPaid,
		|	-ISNULL(AccountsBalance.LimitClosingBalance, 0) AS LimitBalance
		|FROM
		|	AccumulationRegister.Accounts.BalanceAndTurnovers(
		|			,
		|			&qDate,
		|			PERIOD,
		|			RegisterRecordsAndPeriodBoundaries,
		|			(NOT &qPaymentSectionIsFilled
		|				OR &qPaymentSectionIsFilled
		|					AND PaymentSection = &qPaymentSection)
		|				AND Folio IN (&qFoliosList)) AS AccountsBalance";
	EndIf;
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qFoliosList", pFoliosList);
	vQry.SetParameter("qPaymentSection", pPaymentSection);
	vQry.SetParameter("qPaymentSectionIsFilled", ValueIsFilled(pPaymentSection));
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetFoliosBalance

// -----------------------------------------------------------------------------
// Get customer balance for all folios in the value list
// - pDate is optional. If is not specified, then function calculates current balance
// Returns value table with balances for each folio from the input value list
// -----------------------------------------------------------------------------
Function cmGetGuestGroupsBalance(Val pDate = Undefined, pFoliosList) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			If Not SessionParameters.CurrentHotel.ShowDebtsOnCurrentDate Then
				pDate = '39991231235959';
			EndIf;
		EndIf;
	EndIf;

	// Build query to get accounts balance
	vQry = New Query;
	vQry.Text =
	"SELECT DISTINCT
	|	Folio.GuestGroup AS GuestGroup
	|INTO AllGuestGroups
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.Ref IN(&qFoliosList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Folio.Ref AS Ref,
	|	Folio.FolioCurrency AS Currency,
	|	Folio.Customer AS Customer,
	|	Folio.Contract AS Contract,
	|	Folio.GuestGroup AS GuestGroup
	|INTO AllFolios
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.Ref IN(&qFoliosList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllFolios.Ref AS Folio,
	|	AllFolios.Currency AS Currency,
	|	ISNULL(GuestGroupBalances.SumBalance, 0) AS SumBalance
	|FROM
	|	AllFolios AS AllFolios
	|		LEFT JOIN (SELECT
	|			CustomerAccounts.Customer AS Customer,
	|			CustomerAccounts.Contract AS Contract,
	|			CustomerAccounts.GuestGroup AS GuestGroup,
	|			CustomerAccounts.Currency AS Currency,
	|			SUM(CustomerAccounts.SumBalance) AS SumBalance
	|		FROM
	|			(SELECT
	|				CustomerAccountsBalance.AccountingCustomer AS Customer,
	|				CustomerAccountsBalance.AccountingContract AS Contract,
	|				CustomerAccountsBalance.GuestGroup AS GuestGroup,
	|				CustomerAccountsBalance.AccountingCurrency AS Currency,
	|				CustomerAccountsBalance.SumBalance AS SumBalance
	|			FROM
	|				AccumulationRegister.CustomerAccounts.Balance(
	|						&qDate,
	|						GuestGroup IN
	|							(SELECT
	|								AllGuestGroups.GuestGroup
	|							FROM
	|								AllGuestGroups AS AllGuestGroups)) AS CustomerAccountsBalance
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				CurrentAccountsReceivableBalance.Customer,
	|				CurrentAccountsReceivableBalance.Contract,
	|				CurrentAccountsReceivableBalance.GuestGroup,
	|				CurrentAccountsReceivableBalance.FolioCurrency,
	|				CurrentAccountsReceivableBalance.SumBalance - CurrentAccountsReceivableBalance.CommissionSumBalance
	|			FROM
	|				AccumulationRegister.CurrentAccountsReceivable.Balance(
	|						&qDate,
	|						GuestGroup IN
	|							(SELECT
	|								AllGuestGroups.GuestGroup
	|							FROM
	|								AllGuestGroups AS AllGuestGroups)) AS CurrentAccountsReceivableBalance) AS CustomerAccounts
	|		
	|		GROUP BY
	|			CustomerAccounts.Customer,
	|			CustomerAccounts.Contract,
	|			CustomerAccounts.GuestGroup,
	|			CustomerAccounts.Currency) AS GuestGroupBalances
	|		ON AllFolios.Currency = GuestGroupBalances.Currency
	|			AND AllFolios.Customer = GuestGroupBalances.Customer
	|			AND AllFolios.Contract = GuestGroupBalances.Contract
	|			AND AllFolios.GuestGroup = GuestGroupBalances.GuestGroup";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qFoliosList", pFoliosList);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetGuestGroupsBalance

// -----------------------------------------------------------------------------
// Get value table with services found in the folios from the input value list
// -----------------------------------------------------------------------------
Function cmGetFoliosServices(pFoliosList) Export
	// Build query to get folio services
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	FolioSales.ReportingCurrency AS ReportingCurrency,
	|	FolioSales.Folio AS Folio,
	|	FolioSales.Service AS Service,
	|	FolioSales.Service.Code AS ServiceCode,
	|	FolioSales.Service.Description AS ServiceDescription,
	|	FolioSales.Service.SortCode AS ServiceSortCode,
	|	FolioSales.SalesTurnover AS Sales,
	|	FolioSales.QuantityTurnover AS Quantity
	|FROM
	|	AccumulationRegister.Sales.Turnovers(, , Period, Folio IN (&qFoliosList)) AS FolioSales
	|
	|ORDER BY
	|	ServiceSortCode,
	|	ServiceDescription";
	vQry.SetParameter("qFoliosList", pFoliosList);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetFoliosServices

// -----------------------------------------------------------------------------
// Get maximum service date of folio charges
// -----------------------------------------------------------------------------
Function cmGetFolioMaxChargingDate(pFolio) Export
	// Build query to get folio services
	vQry = New Query;
	If ValueIsFilled(pFolio.Hotel) And pFolio.Hotel.SplitFolioBalanceByServicesAndPrices Then
		vQry.Text =
		"SELECT
		|	AccountsBalances.ChequeService AS Service,
		|	AccountsBalances.ChequeServiceQuantityBalance AS Quantity
		|INTO ServicesWithBalances
		|FROM
		|	AccumulationRegister.Accounts.Balance(, Folio = &qFolio) AS AccountsBalances
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FolioSales.Service AS Service,
		|	MAX(CASE
		|			WHEN FolioSales.ServiceDate = &qEmptyDate
		|				THEN FolioSales.AccountingDate
		|			ELSE FolioSales.ServiceDate
		|		END) AS ServiceDate,
		|	SUM(FolioSales.Quantity) AS Quantity,
		|	SUM(FolioSales.Sales) AS Sum
		|FROM
		|	AccumulationRegister.Sales AS FolioSales
		|		INNER JOIN ServicesWithBalances AS ServicesWithBalances
		|		ON (ServicesWithBalances.Service = FolioSales.Service)
		|WHERE
		|	FolioSales.Folio = &qFolio
		|	AND NOT FolioSales.Service.NoPrepaymentIsAllowed
		|	AND (NOT FolioSales.Service.IsHotelProductService
		|			OR FolioSales.Service.IsHotelProductService
		|				AND (FolioSales.HotelProduct = VALUE(Catalog.HotelProducts.EmptyRef)
		|					OR ISNULL(FolioSales.HotelProduct.IsFolder, FALSE))
		|			OR FolioSales.Service.IsHotelProductService
		|				AND FolioSales.Company.DoVouchersFullPaymentOnDeparture
		|				AND FolioSales.HotelProduct <> VALUE(Catalog.HotelProducts.EmptyRef)
		|				AND NOT ISNULL(FolioSales.HotelProduct.IsFolder, FALSE))
		|
		|GROUP BY
		|	FolioSales.Service
		|
		|HAVING
		|	SUM(FolioSales.Quantity) <> 0 AND
		|	SUM(FolioSales.Sales) <> 0
		|
		|ORDER BY
		|	ServiceDate DESC";
	Else
		vQry.Text =
		"SELECT
		|	FolioSales.Service AS Service,
		|	MAX(CASE
		|			WHEN FolioSales.ServiceDate = &qEmptyDate
		|				THEN FolioSales.AccountingDate
		|			ELSE FolioSales.ServiceDate
		|		END) AS ServiceDate,
		|	SUM(FolioSales.Quantity) AS Quantity,
		|	SUM(FolioSales.Sales) AS Sum
		|FROM
		|	AccumulationRegister.Sales AS FolioSales
		|WHERE
		|	FolioSales.Folio = &qFolio
		|	AND NOT FolioSales.Service.NoPrepaymentIsAllowed
		|	AND (NOT FolioSales.Service.IsHotelProductService
		|			OR FolioSales.Service.IsHotelProductService
		|				AND (FolioSales.HotelProduct = VALUE(Catalog.HotelProducts.EmptyRef)
		|					OR ISNULL(FolioSales.HotelProduct.IsFolder, FALSE))
		|			OR FolioSales.Service.IsHotelProductService
		|				AND FolioSales.Company.DoVouchersFullPaymentOnDeparture
		|				AND FolioSales.HotelProduct <> VALUE(Catalog.HotelProducts.EmptyRef)
		|				AND NOT ISNULL(FolioSales.HotelProduct.IsFolder, FALSE))
		|
		|GROUP BY
		|	FolioSales.Service
		|
		|HAVING
		|	SUM(FolioSales.Quantity) <> 0 AND
		|	SUM(FolioSales.Sales) <> 0
		|
		|ORDER BY
		|	ServiceDate DESC";
	EndIf;
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetFolioMaxChargingDate

// -----------------------------------------------------------------------------
// Description: Procedure is marked all unused accommodation/reservation folios as deleted
// Parameters: Document
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmDeleteUnusedDocumentFolios(pDoc, pBoundDocs = Undefined) Export
	// Build and run query to get all document folios
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Folio
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.ParentDoc = &qDoc
	|ORDER BY
	|	Folio.PointInTime";
	vQry.SetParameter("qDoc", pDoc);
	vAllFolios = vQry.Execute().Unload();
	// Leave folios not in the document charging rules
	If TypeOf(pDoc) = Type("DocumentRef.ResourceReservation") Then
		// Resource reservation
		vRow = vAllFolios.Find(pDoc.ChargingFolio, "Folio");
		If vRow <> Undefined Then
			vFolioRef = vRow.Folio;
			If vFolioRef.DeletionMark Then
				vFolioObj = vFolioRef.GetObject();
				vFolioObj.SetDeletionMark(False);
			EndIf;
			vAllFolios.Delete(vRow);
		EndIf;
	Else
		// Accommodation and reservation
		vRules = pDoc.ChargingRules.Unload(, "ChargingFolio");
		For Each vRule In vRules Do
			vRow = vAllFolios.Find(vRule.ChargingFolio, "Folio");
			If vRow <> Undefined Then
				vFolioRef = vRow.Folio;
				If vFolioRef.DeletionMark Then
					vFolioObj = vFolioRef.GetObject();
					vFolioObj.SetDeletionMark(False);
				EndIf;
				vAllFolios.Delete(vRow);
			EndIf;
		EndDo;
	EndIf;
	// If folio left in the list do not have any transactions based on it then delete it
	For Each vRow In vAllFolios Do
		vFolioRef = vRow.Folio;
		If Not vFolioRef.IsMaster And Not vFolioRef.DeletionMark Then
			// Check if this folio present in other document charging rules
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	AccommodationChargingRules.Ref AS Ref,
			|	AccommodationChargingRules.ChargingFolio AS ChargingFolio
			|FROM
			|	Document.Accommodation.ChargingRules AS AccommodationChargingRules
			|WHERE
			|	AccommodationChargingRules.ChargingFolio = &qFolio
			|	AND AccommodationChargingRules.Ref <> &qDoc
			|	AND AccommodationChargingRules.Ref.Posted
			|
			|UNION ALL
			|
			|SELECT
			|	ReservationChargingRules.Ref,
			|	ReservationChargingRules.ChargingFolio
			|FROM
			|	Document.Reservation.ChargingRules AS ReservationChargingRules
			|WHERE
			|	ReservationChargingRules.ChargingFolio = &qFolio
			|	AND ReservationChargingRules.Ref <> &qDoc
			|	AND ReservationChargingRules.Ref.Posted";
			vQry.SetParameter("qFolio", vFolioRef);
			vQry.SetParameter("qDoc", pDoc);
			vDocs = vQry.Execute().Unload();
			// Check folio transactions
			If vDocs.Count() = 0 Then
				vFolioObj = vFolioRef.GetObject();
				vTransCount = vFolioObj.pmGetAllFolioTransactionsCount();
				If vTransCount = 0 Then
					// Check if this folio has active identification cards
					vActiveFolioCards = cmGetClientIdentificationCardsByFolio(vFolioRef);
					If vActiveFolioCards.Count() = 0 Then
						// Set deletion mark
						vFolioObj.SetDeletionMark(True);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	If pBoundDocs = Undefined Then
		pBoundDocs = New ValueList();
	EndIf;
	If pBoundDocs.FindByValue(pDoc) = Undefined Then
		pBoundDocs.Add(pDoc);
	EndIf;
	// Check unused folios for other charging rules documents
	If TypeOf(pDoc) = Type("DocumentRef.Reservation") Or TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
		For Each vCRRow In pDoc.ChargingRules Do
			If ValueIsFilled(vCRRow.ChargingFolio) Then
				vDoc = vCRRow.ChargingFolio.ParentDoc;
				If ValueIsFilled(vDoc) And vDoc <> pDoc Then
					If pBoundDocs.FindByValue(vDoc) = Undefined Then
						pBoundDocs.Add(vDoc);
						cmDeleteUnusedDocumentFolios(vDoc, pBoundDocs);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Check unused folios for other one room documents
	vOneRoomDocs = New ValueTable();
	If TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
		vOneRoomDocs = cmGetOneRoomReservations(pDoc.Number, pDoc.GuestGroup, pDoc.CheckInDate, pDoc.CheckOutDate);
	ElsIf TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
		vOneRoomDocs = cmGetOneRoomAccommodations(pDoc.Room, pDoc.GuestGroup, pDoc.CheckInDate, pDoc.CheckOutDate);
	EndIf;
	If vOneRoomDocs.Count() > 0 Then
		For Each vDocRow In vOneRoomDocs Do
			vDoc = vDocRow.Ref;
			If ValueIsFilled(vDoc) And vDoc <> pDoc Then
				If pBoundDocs.FindByValue(vDoc) = Undefined Then
					pBoundDocs.Add(vDoc);
					cmDeleteUnusedDocumentFolios(vDoc, pBoundDocs);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // cmDeleteUnusedDocumentFolios

// -----------------------------------------------------------------------------
// Description: Rounds number down, i.e. 
//              pRoundDigits = -1: 24 -> 20; 29 -> 20; -33 -> -40; -37 -> -40
//              pRoundDigits =  1: 2.43 -> 2.40; 2.49 -> 2.40; -3.33 -> -3.40; -3.37 -> -3.40
// -----------------------------------------------------------------------------
Function cmRoundDown(pNumber, pRoundDigits) Export
	vNumber = Round(pNumber, pRoundDigits);
	If (vNumber - pNumber) > 0 Then
		vNumber = vNumber - Pow(10, -pRoundDigits);
	EndIf;
	Return vNumber;
EndFunction // cmRoundDown

// -----------------------------------------------------------------------------
// Description: Rounds number up, i.e. 
//              pRoundDigits = -1: 24 -> 30; 29 -> 30; -33 -> -30; -37 -> -30
//              pRoundDigits =  1: 2.43 -> 2.50; 2.49 -> 2.50; -3.33 -> -3.30; -3.37 -> -3.30
// -----------------------------------------------------------------------------
Function cmRoundUp(pNumber, pRoundDigits) Export
	vNumber = Round(pNumber, pRoundDigits);
	If (vNumber - pNumber) < 0 Then
		vNumber = vNumber + Pow(10, - pRoundDigits);
	EndIf;
	Return vNumber;
EndFunction // cmRoundUp

// -----------------------------------------------------------------------------
// Description: Returns value table with active set room rate prices orders for the given list of room rates
// Parameters: Value list with room rates, Date to get active set room rate prices orders
// Return value: Value table with set room rate prices orders
// -----------------------------------------------------------------------------
Function cmGetActiveSetRoomRatePrices(pRoomRates, Val pPeriod = Undefined, pCheckInDate = Undefined, pCheckOutDate = Undefined, pCalendarDayTypesList = Undefined, pHotel = Undefined, pRoomType = Undefined) Export
	// Check period
	If Not ValueIsFilled(pPeriod) Then
		pPeriod = CurrentSessionDate();
	EndIf;
	// Room rates
	vRoomRatesStruct = pRoomRates;
	If TypeOf(pRoomRates) = Type("ValueList") Then
		i = 1;
		vRoomRatesStruct = New Structure();
		For Each vRoomRatesItem In pRoomRates Do
			vRoomRatesStruct.Insert("RoomRate" + Format(i, "ND=10; NFD=; NG="), vRoomRatesItem.Value);
			i = i + 1;
		EndDo;
	EndIf;
	// Calendar day types
	i = 1;
	vDayTypesStruct = New Structure();
	If pCalendarDayTypesList <> Undefined Then
		For Each vCalendarDayTypesListItem In pCalendarDayTypesList Do
			vDayTypesStruct.Insert("CalendarDayType" + Format(i, "ND=10; NFD=; NG="), vCalendarDayTypesListItem.Value);
			i = i + 1;
		EndDo;
	EndIf;
	// Call cached API
	vReturnStruct = CachedAccounts.GetActiveSetRoomRatePrices(vRoomRatesStruct, pPeriod, pCheckInDate, pCheckOutDate, vDayTypesStruct, pHotel, pRoomType);
	
	vReturnTable = New ValueTable();
	vReturnTable.Columns.Add("SetRoomRatePrices", cmGetDocumentTypeDescription("SetRoomRatePrices"));
	vReturnTable.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vReturnTable.Columns.Add("RoomRateSortCode", cmGetSortCodeTypeDescription());
	vReturnTable.Columns.Add("CalendarDayType", cmGetCatalogTypeDescription("CalendarDayTypes"));
	vReturnTable.Columns.Add("CalendarDayTypeSortCode", cmGetSortCodeTypeDescription());
	vReturnTable.Columns.Add("PriceTag", cmGetCatalogTypeDescription("PriceTags"));
	vReturnTable.Columns.Add("PriceTagSortCode", cmGetSortCodeTypeDescription());
	
	For Each vReturnStructKeyAndValue In vReturnStruct Do
		vReturnTableRow = vReturnTable.Add();
		FillPropertyValues(vReturnTableRow, vReturnStructKeyAndValue.Value);
	EndDo;     
	Return vReturnTable;
EndFunction // cmGetActiveSetRoomRatePrices

// -----------------------------------------------------------------------------
//  Description: For thick client compatibility. Returns value table with service prices for the given list of services
//
// Parameters:
//  pServices	 - ValueList			 - Value list with services
//  pHotel		 - CatalogRef.Hotels	 - Ref
//  pPeriod		 - Date					 - Date to get active prices
//  pClientType	 - CatalogRef.ClientTypes- Ref
// 
// Returns:
//  ValueTable - Value table with service prices
//
Function cmGetServicePrices(pServices, pHotel, Val pPeriod = Undefined, Val pClientType = Undefined) Export
	// Common checks	
	If Not ValueIsFilled(pHotel) Then
		Raise(NStr("en='ERR: Error calling cmGetServicePrices function.
		               |CAUSE: Empty pHotel parameter value was passed to the function.
					   |DESC: Mandatory parameter pHotel should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetServicePrices.
				       |CAUSE: В функцию передано пустое значение параметра pHotel.
					   |DESC: Обязательный параметр pHotel должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetServicePrices.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pHotel übertragen.
					   |DESC: Das Pflichtparameter pHotel muss eindeutig angegeben sein.'"));
	EndIf;
	
	// Fill parameters default values 
	If Not ValueIsFilled(pPeriod) Then
		pPeriod = CurrentSessionDate();
	EndIf;
	If Not ValueIsFilled(pClientType) Then
		pClientType = Catalogs.ClientTypes.EmptyRef();
	EndIf;
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServicePricesSliceLast.Period AS Period,
	|	ServicePricesSliceLast.Hotel AS Hotel,
	|	ServicePricesSliceLast.Service AS Service,
	|	ServicePricesSliceLast.Service.Unit AS ServiceUnit,
	|	ServicePricesSliceLast.ClientType AS ClientType,
	|	ServicePricesSliceLast.Price AS Price,
	|	ServicePricesSliceLast.Currency AS Currency,
	|	ServicePricesSliceLast.VATRate AS VATRate
	|FROM
	|	InformationRegister.ServicePrices.SliceLast(
	|			&qPeriod,
	|			(Hotel = &qHotel
	|				OR Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|				AND Service IN (&qServices)
	|				AND (ClientType = &qClientType
	|					OR ClientType = &qClientTypeParent
	|						AND &qClientTypeParent <> VALUE(Catalog.ClientTypes.EmptyRef)
	|					OR ClientType = VALUE(Catalog.ClientTypes.EmptyRef))) AS ServicePricesSliceLast
	|
	|ORDER BY
	|	Hotel DESC,
	|	ClientType DESC,
	|	Period DESC";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qServices", pServices);
	vQry.SetParameter("qClientType", pClientType);
	vQry.SetParameter("qClientTypeParent", ?(ValueIsFilled(pClientType), pClientType.Parent, Catalogs.ClientTypes.EmptyRef()));
	vPrices = vQry.Execute().Unload();

	Return vPrices;
EndFunction // cmGetServicePrices

// -----------------------------------------------------------------------------
//  Description: Returns value table with service prices for the given list of services
//
// Parameters:
//  pService	 - CatalogRef.Services	 - Ref service
//  pHotel		 - CatalogRef.Hotels	 - Ref
//  pPeriod		 - Date					 - Date to get active prices
//  pClientType	 - CatalogRef.ClientTypes- Ref
// 
// Returns:
//  ValueTable - Value table with service prices
//
Function cmGetServicePrice(pService, pHotel, Val pPeriod = Undefined, Val pClientType = Undefined) Export
	// Common checks	
	If Not ValueIsFilled(pHotel) Then
		Raise(NStr("en='ERR: Error calling cmGetServicePrice function.
		               |CAUSE: Empty pHotel parameter value was passed to the function.
					   |DESC: Mandatory parameter pHotel should be filled.';
				   |ru='ERR: Ошибка вызова функции cmGetServicePrice.
				       |CAUSE: В функцию передано пустое значение параметра pHotel.
					   |DESC: Обязательный параметр pHotel должен быть явно указан.';
				   |de='ERR: Fehler beim Aufruf der Funktion cmGetServicePrice.
				       |CAUSE: In die Funktion wurde ein leerer Wert des Parameters pHotel übertragen.
					   |DESC: Das Pflichtparameter pHotel muss eindeutig angegeben sein.'"));
	EndIf;
	
	// Fill parameters default values 
	If Not ValueIsFilled(pPeriod) Then
		pPeriod = CurrentSessionDate();
	EndIf;
	If Not ValueIsFilled(pClientType) Then
		pClientType = Catalogs.ClientTypes.EmptyRef();
	EndIf;
	
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	ServicePricesSliceLast.Period AS Period,
	|	ServicePricesSliceLast.Hotel AS Hotel,
	|	ServicePricesSliceLast.Service AS Service,
	|	ServicePricesSliceLast.Service.Unit AS ServiceUnit,
	|	ServicePricesSliceLast.ClientType AS ClientType,
	|	ServicePricesSliceLast.Price AS Price,
	|	ServicePricesSliceLast.Currency AS Currency,
	|	ServicePricesSliceLast.VATRate AS VATRate
	|FROM
	|	InformationRegister.ServicePrices.SliceLast(
	|			&qPeriod,
	|			(Hotel = &qHotel
	|				OR Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|				AND Service = &qService
	|				AND (ClientType = &qClientType
	|					OR ClientType = &qClientTypeParent
	|						AND &qClientTypeParent <> VALUE(Catalog.ClientTypes.EmptyRef)
	|					OR ClientType = VALUE(Catalog.ClientTypes.EmptyRef))) AS ServicePricesSliceLast
	|
	|ORDER BY
	|	Hotel DESC,
	|	ClientType DESC,
	|	Period DESC";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qService", pService);
	vQry.SetParameter("qClientType", pClientType);
	vQry.SetParameter("qClientTypeParent", ?(ValueIsFilled(pClientType), pClientType.Parent, Catalogs.ClientTypes.EmptyRef()));
	vPrices = vQry.Execute().Unload();
	
	Return vPrices;
EndFunction // cmGetServicePrice

// -----------------------------------------------------------------------------
// Description: Returns cash register driver data processor object based on cash register type
// Parameters: Cash register
// Return value: Cash register driver data processor object
// -----------------------------------------------------------------------------
Function cmGetCashRegisterDataProcessor(pCashRegister) Export
	// Check parameters
	If Not ValueIsFilled(pCashRegister) Then
		Return Undefined;
	EndIf;
	If Not ValueIsFilled(pCashRegister.CashRegisterDriver) Then
		Return Undefined;
	EndIf;
	// Create data processor object for the given driver name
	Try
		vDriverName = pCashRegister.CashRegisterDriver.Metadata().EnumValues[Enums.CashRegisterDrivers.IndexOf(pCashRegister.CashRegisterDriver)].Name;
		If vDriverName = "AtolCommonCashRegisterDriver8" Then
			vDriverName = "AtolCommonCashRegisterDriver";
		EndIf;
		vDataProcessorObj = DataProcessors[vDriverName].Create();
		vDataProcessorObj.CashRegister = pCashRegister;
		Return vDataProcessorObj;
	Except
		Return Undefined;
	EndTry;
EndFunction // cmGetCashRegisterDataProcessor

// -----------------------------------------------------------------------------
// Description: Returns ribbon printer data processor object based on ribbon printer settings
// Parameters: Ribbon printer settings catalog item
// Return value: Ribbon printer driver data processor object
// -----------------------------------------------------------------------------
Function cmGetRibbonPrinterDataProcessor(pSettings) Export
	// Check parameters
	If Not ValueIsFilled(pSettings) Then
		Return Undefined;
	EndIf;
	If IsBlankString(pSettings.Model) And pSettings.DriverType <> Enums.RibbonPrinterDrivers.SystemPrinter Then
		Return Undefined;
	EndIf;
	// Create data processor object
	Try
		If ValueIsFilled(pSettings.DriverType) And pSettings.DriverType = Enums.RibbonPrinterDrivers.Atol Then
			vDriverName = "AtolRibbonPrinterDriver";
		ElsIf ValueIsFilled(pSettings.DriverType) And pSettings.DriverType = Enums.RibbonPrinterDrivers.Intermec Then
			vDriverName = "IntermecRibbonPrinterDriver";
		ElsIf ValueIsFilled(pSettings.DriverType) And pSettings.DriverType = Enums.RibbonPrinterDrivers.SystemPrinter Then
			vDriverName = "PrintCouponSystemPrinter"; 
		Else
			Return Undefined;
		EndIf;
		vDataProcessorObj = DataProcessors[vDriverName].Create();
		vDataProcessorObj.RibbonPrinterConnectionParameters = pSettings;
		Return vDataProcessorObj;
	Except
		Return Undefined;
	EndTry;
EndFunction // cmGetRibbonPrinterDataProcessor

// -----------------------------------------------------------------------------
// Description: Returns pay card system driver data processor object based on pay card system parameters
// Parameters: Pay card system parameters reference
// Return value: Pay card system driver data processor object
// -----------------------------------------------------------------------------
Function cmGetPayCardDataProcessor(pPCSystemParameters) Export
	// Check parameters
	If Not ValueIsFilled(pPCSystemParameters) Then
		Return Undefined;
	EndIf;
	If Not ValueIsFilled(pPCSystemParameters.CreditCardsProcessingSystemType) Then
		Return Undefined;
	EndIf;
	// Create data processor object for the given driver name
	Try
		If pPCSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.AtolPayCardSystemsDriver Then
			vDriverName = "AtolPayCardSystemsDriver";
		ElsIf pPCSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.TrPosPOSTerminalsDriver Then
			vDriverName = "TrPosPOSTerminalsDriver";
		ElsIf pPCSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.INPASPulsarSystemDriver Then
			vDriverName = "INPASPulsarSystemDriver";
		ElsIf pPCSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.INPASDualConnectorDriver82 Then
			vDriverName = "INPASDualConnectorDriver82";
		ElsIf pPCSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.INPASDualConnectorDriver83 Then
			vDriverName = "INPASDualConnectorDriver83";
		ElsIf pPCSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.UCSSystemDriver Then
			vDriverName = "UCSSystemDriver";
		ElsIf pPCSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.SberbankSBRFCOMSystemDriver Then
			vDriverName = "SberbankSBRFCOMSystemDriver";
		ElsIf pPCSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.EMVGateCOM1C Then
			vDriverName = "GazprombankSystemDriver";
		ElsIf pPCSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.SberbankSBRFSystemDriver Then
			vDriverName = "SberbankSBRFSystemDriver"; 
		ElsIf pPCSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.Arcus2SystemsDriver Then
			vDriverName = "Arcus2SystemsDriver";
		Else
			Return Undefined;
		EndIf;
		vDataProcessorObj = DataProcessors[vDriverName].Create();
		vDataProcessorObj.CreditCardsProcessingSystemParameters = pPCSystemParameters;
		Return vDataProcessorObj;
	Except
		Return Undefined;
	EndTry;
EndFunction // cmGetPayCardDataProcessor

// -----------------------------------------------------------------------------
// Description: Returns list of payment methods allowed for the program user
// Parameters: Employee, Whether it is necessary to get list of money back payment methods, 
//             Cash register, Whether to return credit card payment methods only
// Return value: Value list of payment methods
// -----------------------------------------------------------------------------
Function cmGetListOfPaymentMethodsAllowed(pEmployee, pIsReturn = False, pCashRegister = Undefined, pCreditCardsOnly = False) Export
	vList = New ValueList();
	If Not ValueIsFilled(pEmployee) Then
		Return vList;
	EndIf;
	vPermissionGroup = cmGetEmployeePermissionGroup(pEmployee);
	If Not ValueIsFilled(vPermissionGroup) Then
		Return vList;
	EndIf;
	// Initialize user permissions
	UserHavePermissionToReturnCashDirectlyFromCashBox = cmCheckUserPermissions("HavePermissionToReturnCashDirectlyFromCashBox");
	UserShowReturnPaymentMethodsInReturnDocumentsOnly = cmCheckUserPermissions("ShowReturnPaymentMethodsInReturnDocumentsOnly");
	// Get employee permission group list of payment methods
	vList.LoadValues(vPermissionGroup.PaymentMethodsAllowed.UnloadColumn("PaymentMethod"));
	// Remove payment methods marked for deletion
	i = 0;
	While i < vList.Count() Do
		vListItem = vList.Get(i);
		vPaymentMethod = vListItem.Value;
		If vPaymentMethod.DeletionMark Then
			vList.Delete(vListItem);
			Continue;
		EndIf;
		i = i + 1;
	EndDo;
	// Remove not applicable payment methods
	If pIsReturn Then
		// Leave payment methods allowed for return according to the user permissions
		i = 0;
		While i < vList.Count() Do
			vListItem = vList.Get(i);
			vPaymentMethod = vListItem.Value;
			If vPaymentMethod.IsByCash Then
				vHavePermissionToReturnCashDirectlyFromCashBox = UserHavePermissionToReturnCashDirectlyFromCashBox;
				If ValueIsFilled(pCashRegister) Then
					If pCashRegister.CashReturnDirectlyFromCashBoxIsAllowed Then
						vHavePermissionToReturnCashDirectlyFromCashBox = True;
					EndIf;
				EndIf;
				If Not vHavePermissionToReturnCashDirectlyFromCashBox Then
					If Not vPaymentMethod.IsForReturnOnly Or vPaymentMethod.PrintCheque Then
						vList.Delete(vListItem);
						Continue;
					EndIf;
				EndIf;
			EndIf;
			If UserShowReturnPaymentMethodsInReturnDocumentsOnly Then
				If Not vPaymentMethod.IsForReturnOnly Then
					vList.Delete(vListItem);
					Continue;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
	Else
		// Remove payment methods for return only
		i = 0;
		While i < vList.Count() Do
			vListItem = vList.Get(i);
			vPaymentMethod = vListItem.Value;
			If vPaymentMethod.IsForReturnOnly Then
				vList.Delete(vListItem);
				Continue;
			EndIf;
			i = i + 1;
		EndDo;
		// Remove not credit cards
		If pCreditCardsOnly Then
			i = 0;
			While i < vList.Count() Do
				vListItem = vList.Get(i);
				vPaymentMethod = vListItem.Value;
				If Not vPaymentMethod.IsByCreditCard Or vPaymentMethod.IsForResortFee Then
					vList.Delete(vListItem);
					Continue;
				EndIf;
				i = i + 1;
			EndDo;
		EndIf;
	EndIf;
	Return vList;
EndFunction // cmGetListOfPaymentMethodsAllowed

// -----------------------------------------------------------------------------
// Description: Returns list of cash registers allowed for the current user
// Parameters: Company, Workstation, Payment method
// Return value: Value list of cash registers
// -----------------------------------------------------------------------------
Function cmGetListOfCashRegistersAllowed(pCompany = Undefined, pWorkstation, pPaymentMethod = Undefined) Export
	vList = New ValueList();
	If Not ValueIsFilled(pWorkstation) Then
		Return vList;
	EndIf;
	If Not ValueIsFilled(pWorkstation.CashRegisters) Then
		Return vList;
	EndIf;
	For Each vRow In pWorkstation.CashRegisters Do
		If ValueIsFilled(vRow.CashRegister) Then
			If vRow.CashRegister.Owner = pCompany Or 
			   Not ValueIsFilled(pCompany) Then
				If vRow.CashRegister.DeletionMark Then
					Continue;
				EndIf;
				If ValueIsFilled(pPaymentMethod) Then
					If Not pPaymentMethod.BookByCashRegister And Not vRow.CashRegister.CashReturnDirectlyFromCashBoxIsAllowed Then
						Continue;
					EndIf;
				EndIf;
				vList.Add(vRow.CashRegister);
			EndIf;
		EndIf;
	EndDo;
	// Add cash registers that are used based on agent contract
	If vList.Count() = 0 And ValueIsFilled(pCompany) And ValueIsFilled(pCompany.CompanyToUseCashRegistersFrom) Then
		For Each vRow In pWorkstation.CashRegisters Do
			vCashRegister = vRow.CashRegister;
			If ValueIsFilled(vCashRegister) And pCompany.CompanyToUseCashRegistersFrom = vCashRegister.Owner Then
				If vCashRegister.DeletionMark Then
					Continue;
				EndIf;
				If ValueIsFilled(pPaymentMethod) Then
					If Not pPaymentMethod.BookByCashRegister And Not vCashRegister.CashReturnDirectlyFromCashBoxIsAllowed Then
						Continue;
					EndIf;
				EndIf;
				vList.Add(vCashRegister);
			EndIf;
		EndDo;
	EndIf;
	Return vList;
EndFunction // cmGetListOfCashRegistersAllowed

// -----------------------------------------------------------------------------
// Description: Returns list of all active cash registers
// Parameters: Company
// Return value: Value list of cash registers
// -----------------------------------------------------------------------------
Function cmGetListOfAllCashRegisters(pCompany = Undefined) Export
	vList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisters.Ref AS CashRegister
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CashRegisters.DeletionMark = FALSE
	|ORDER BY
	|	CashRegisters.SortCode";
	vQryResult = vQry.Execute().Unload();
	For Each vRow In vQryResult Do
		If ValueIsFilled(vRow.CashRegister) Then
			If ValueIsFilled(pCompany) Then
				If vRow.CashRegister.Owner <> pCompany Then
					Continue;
				EndIf;
			EndIf;
			vList.Add(vRow.CashRegister);
		EndIf;
	EndDo;
	// Add cash registers that are used basen on agent contract
	If vList.Count() = 0 And ValueIsFilled(pCompany) And ValueIsFilled(pCompany.CompanyToUseCashRegistersFrom) Then
		For Each vRow In vQryResult Do
			vCashRegister = vRow.CashRegister;
			If ValueIsFilled(vCashRegister) And pCompany.CompanyToUseCashRegistersFrom = vCashRegister.Owner Then
				vList.Add(vCashRegister);
			EndIf;
		EndDo;
	EndIf;	
	Return vList;
EndFunction // cmGetListOfAllCashRegisters

// -----------------------------------------------------------------------------
// Description: Returns list of all client or customer credit cards 
// Parameters: Card owner
// Return value: Value list of credit cards
// -----------------------------------------------------------------------------
Function cmGetListOfPayersCreditCards(pCardOwner) Export
	vList = New ValueList();
	If Not ValueIsFilled(pCardOwner) Then
		Return vList;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CreditCards.Ref AS CreditCard
	|FROM
	|	Catalog.CreditCards AS CreditCards
	|WHERE
	|	CreditCards.CardOwner = &qCardOwner
	|	AND CreditCards.DeletionMark = FALSE";
	vQry.SetParameter("qCardOwner", pCardOwner);
	vCards = vQry.Execute().Unload();
	vList.LoadValues(vCards.UnloadColumn("CreditCard"));
	Return vList;
EndFunction // cmGetListOfPayersCreditCards

// -----------------------------------------------------------------------------
// Description: Returns list of all client discount cards 
// Parameters: Card owner
// Return value: Value table of discount cards data
// -----------------------------------------------------------------------------
Function cmGetListOfClientDiscountCards(pClient) Export
	vCards = New ValueTable();
	If Not ValueIsFilled(pClient) Then
		Return vCards;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref AS DiscountCard,
	|	DiscountCards.Code AS Code,
	|	DiscountCards.Description AS Description,
	|	DiscountCards.Identifier AS Identifier,
	|	DiscountCards.Client AS Client,
	|	DiscountCards.DiscountType AS DiscountType,
	|	DiscountCards.ClientType AS ClientType,
	|	DiscountCards.TurnOffAutomaticDiscounts AS TurnOffAutomaticDiscounts,
	|	DiscountCards.ValidFrom AS ValidFrom,
	|	DiscountCards.ValidTo AS ValidTo,
	|	DiscountCards.IsBlocked AS IsBlocked,
	|	DiscountCards.Remarks AS Remarks
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	DiscountCards.Client = &qClient
	|	AND NOT DiscountCards.DeletionMark
	|
	|ORDER BY
	|	Code";
	vQry.SetParameter("qClient", pClient);
	vCards = vQry.Execute().Unload();
	Return vCards;
EndFunction // cmGetListOfClientDiscountCards

// -----------------------------------------------------------------------------
// Description: Creates structure with credit card data. Fills credit card number
// Parameters: Credit card number
// Return value: Credit card data structure
// -----------------------------------------------------------------------------
Function cmParseCreditCardData(pText) Export
	vData = New Structure("CardType, CardNumber, CardHolder, CardValidTillDate, CardSecurityCode, CardIssuer, CardOwner");
	vData.CardType = Catalogs.CreditCardTypes.EmptyRef();
	vData.CardNumber = TrimAll(pText);
	Return vData;
EndFunction // cmParseCreditCardData

// -----------------------------------------------------------------------------
// Description: Masks credit card number with * chars
// Parameters: Credit card number
// Return value: Masked credit card number
// -----------------------------------------------------------------------------
Function cmGetCreditCardDescription(pCardNumber) Export
	vCardDescription = "";
	vCardNumber = TrimAll(pCardNumber);
	vCardNumberLength = StrLen(vCardNumber);
	vLeftVisiblePartIndex = 6;
	vMidVisiblePartIndex = vCardNumberLength - 4;
	vRightVisiblePartIndex = vCardNumberLength;
	For i = 1 To vCardNumberLength Do
		If i <= vLeftVisiblePartIndex Or 
		   i > vMidVisiblePartIndex And i <= vRightVisiblePartIndex Then
			vCardDescription = vCardDescription + Mid(vCardNumber, i, 1);
		Else
			vCardDescription = vCardDescription + "*";
		EndIf;
	EndDo;
	Return vCardDescription; 
EndFunction // cmGetCreditCardDescription	

// -----------------------------------------------------------------------------
// Description: Recalculates price based on amount and quantity
// Parameters: Amount, Quantity
// Return value: Price
// -----------------------------------------------------------------------------
Function cmRecalculatePrice(pSum, pQuantity) Export
	vQuantity = pQuantity;
	If vQuantity = 0 Then
		vQuantity = 1;
	EndIf;
	vPrice = Round(pSum / vQuantity, 2);
	Return vPrice;
EndFunction // cmRecalculatePrice

// -----------------------------------------------------------------------------
// Description: Returns amount presentation in words
// Parameters: Amount, Currency, Language
// Return value: Amount presentation in words
// -----------------------------------------------------------------------------
Function cmSumInWords(pSum, pCurrency, pLang) Export
	vLocalizationCode = "";
	If ValueIsFilled(pLang) Then
		If Not IsBlankString(pLang.LocalizationCode) Then
			vLocalizationCode = TrimAll(pLang.LocalizationCode);
		Else
			vLocalizationCode = "ru_RU";
		EndIf;
	EndIf;
	vNumberInWordsAttributes = "";
	If ValueIsFilled(pCurrency) Then
		If ValueIsFilled(pLang) Then
			vSumInWordsAttributesRow = pCurrency.SumInWordsAttributes.Find(pLang, "Language");
			If vSumInWordsAttributesRow <> Undefined Then
				vNumberInWordsAttributes = TrimAll(vSumInWordsAttributesRow.NumberInWordsAttributes);
			EndIf;
		Else
			vNumberInWordsAttributes = "рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2";
		EndIf;
	EndIf;
	vSumInWords = NumberInWords(pSum, "L=" + vLocalizationCode + "; SN=True; FN=True; FS=False", vNumberInWordsAttributes);
	Return vSumInWords;
EndFunction // cmSumInWords

// -----------------------------------------------------------------------------
//  Description: Returns value table with charges not in settlements yet
//
// Parameters:
//  pDate			 - 	 - 
//  pCustomer		 - 	 - 
//  pContract		 - 	 - 
//  pParentDoc		 - 	 - 
//  pGuestGroup		 - 	 - 
//  pCurrency		 - 	 - 
//  pHotel			 - 	 - 
//  pChargesToSkip	 - 	 - 
//  pFolio			 - 	 - 
// 
// Returns:
//  ValueTable - Value table with charges that are not in settlements at the given date
//
Function cmGetCurrentAccountsReceivableChargesWithBalances(Val pDate = Undefined, pCustomer = Undefined, pContract = Undefined, pParentDoc = Undefined, pGuestGroup = Undefined, pCurrency, pHotel = Undefined, pChargesToSkip = Undefined, pFolio = Undefined, pSkipRoomRate = False) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;

	// Build query to get services
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	CurrentAccountsReceivableBalance.Hotel,
	|	CurrentAccountsReceivableBalance.Company,
	|	CurrentAccountsReceivableBalance.Customer,
	|	CurrentAccountsReceivableBalance.Contract,
	|	CurrentAccountsReceivableBalance.GuestGroup,
	|	CurrentAccountsReceivableBalance.FolioCurrency,
	|	CurrentAccountsReceivableBalance.Charge.Folio AS Folio,
	|	CurrentAccountsReceivableBalance.Charge.ParentDoc AS ParentDoc,
	|	CurrentAccountsReceivableBalance.Charge.HotelProduct AS HotelProduct,
	|	CurrentAccountsReceivableBalance.Charge AS Charge,
	|	CurrentAccountsReceivableBalance.Charge.Discount AS Discount,
	|	CurrentAccountsReceivableBalance.Charge.DiscountSum AS DiscountSum,
	|	CurrentAccountsReceivableBalance.Charge.AgentCommissionType AS AgentCommissionType,
	|	CurrentAccountsReceivableBalance.Charge.AgentCommission AS AgentCommission,
	|	CurrentAccountsReceivableBalance.Charge.Folio.Description AS FolioDescription,
	|	SUM(CurrentAccountsReceivableBalance.CommissionSumBalance),
	|	SUM(CurrentAccountsReceivableBalance.SumBalance),
	|	SUM(CurrentAccountsReceivableBalance.VATSumBalance),
	|	SUM(CurrentAccountsReceivableBalance.QuantityBalance)
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Balance(
	|		&qPeriod, TRUE
	|" +
			?(ValueIsFilled(pHotel), " AND Hotel = &qHotel" , "") + 
			?(ValueIsFilled(pCustomer), " AND (Customer = &qCustomer OR &qIsIndividualsCustomer AND Customer <> &qEmptyCustomer AND Customer.IsIndividual OR &qIsIndividualsCustomer AND Customer = &qEmptyCustomer)" , "") + 
			?(ValueIsFilled(pContract), " AND Contract = &qContract" , "") + 
			?(ValueIsFilled(pParentDoc), " AND Charge.ParentDoc = &qParentDoc" , "") + 
			?(pSkipRoomRate, " AND (Charge.IsAdditional OR Charge.IsManual)", "") + 
			?(ValueIsFilled(pFolio), " AND (Charge.Folio = &qFolio OR Charge.ChargeTransfer.FolioFrom = &qFolio OR Charge.ChargeTransfer.FolioTo = &qFolio)" , "") + 
			?(ValueIsFilled(pGuestGroup), " AND GuestGroup = &qGuestGroup" , "") + "
	|		AND FolioCurrency = &qCurrency
	|		AND (&qAll OR NOT &qAll AND Charge NOT IN (&qChargesToSkip))) AS CurrentAccountsReceivableBalance
	|GROUP BY
	|	CurrentAccountsReceivableBalance.Hotel,
	|	CurrentAccountsReceivableBalance.Company,
	|	CurrentAccountsReceivableBalance.Customer,
	|	CurrentAccountsReceivableBalance.Contract,
	|	CurrentAccountsReceivableBalance.GuestGroup,
	|	CurrentAccountsReceivableBalance.FolioCurrency,
	|	CurrentAccountsReceivableBalance.Charge
	|ORDER BY
	|	Charge.Date,
	|	Charge.PointInTime";
	// Set query parameters
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qCurrency", pCurrency);
	vQry.SetParameter("qAll", ?(pChargesToSkip = Undefined, True, False));
	vQry.SetParameter("qChargesToSkip", pChargesToSkip);
	// Individuals customer
	vIsIndividualsCustomer = False;
	If ValueIsFilled(pCustomer) And ValueIsFilled(SessionParameters.CurrentHotel) Then
		If pCustomer = SessionParameters.CurrentHotel.IndividualsCustomer Then
			vIsIndividualsCustomer = True;
		EndIf;
	EndIf;
	vQry.SetParameter("qIsIndividualsCustomer", vIsIndividualsCustomer);
	// Run query and return results
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetCurrentAccountsReceivableChargesWithBalances

// -----------------------------------------------------------------------------
// Description: Returns VAT invoice last used number
// Parameters: Company
// Return value: String, maximum VAT invoice number
// -----------------------------------------------------------------------------
Function cmGetLastUsedVATInvoiceNumber(pCompany) Export
	vNum = "";
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Settlement.InvoiceNumber AS InvoiceNumber
	|FROM
	|	Document.Settlement AS Settlement
	|WHERE
	|	Settlement.InvoiceNumber > &qEmptyNumber
	|	AND Settlement.Company = &qCompany
	|ORDER BY
	|	InvoiceNumber DESC";
	vQry.SetParameter("qEmptyNumber", "                    ");
	vQry.SetParameter("qCompany", pCompany);
	vQryRes = vQry.Execute().Unload();
	For Each vRow In vQryRes Do
		vNum = TrimAll(vRow.InvoiceNumber);
		Break;
	EndDo;
	Return vNum;
EndFunction // cmGetLastUsedVATInvoiceNumber

// -----------------------------------------------------------------------------
// Description: Returns next vacant VAT invoice number
// Parameters: VAT invoice number last used
// Return value: String, new VAT invoice number
// -----------------------------------------------------------------------------
Function cmGetNextVATInvoiceNumber(pLastNumber = "") Export
	// Add 1 to the numeric right part of number
	vNextNum = "";
	vNum = TrimAll(pLastNumber);
	vNumStr = "";
	vPrefixStr = "";
	i = StrLen(vNum);
	While i > 0 Do
		vChar = Mid(vNum, i, 1);
		If vChar = "0" Or vChar = "1" Or vChar = "2" Or vChar = "3" Or vChar = "4" Or
		   vChar = "5" Or vChar = "6" Or vChar = "7" Or vChar = "8" Or vChar = "9" Then
			vNumStr = vChar + vNumStr;
		Else
			vPrefixStr = Left(vNum, i);
			Break;
		EndIf;
		i = i - 1; 
	EndDo;
	If Not IsBlankString(vNumStr) Then
		vNumStrLen = StrLen(vNumStr);
		vNumNum = Number(vNumStr);
		vNextNum = vPrefixStr + Format(vNumNum + 1, "ND=" + String(vNumStrLen) + "; NZ=; NLZ=; NG=");
	Else
		vNextNum = vPrefixStr + "1";
	EndIf;
	Return vNextNum;
EndFunction // cmGetNextVATInvoiceNumber

// -----------------------------------------------------------------------------
// Description: Returns value table with customer accounts balances
// Parameters: Date to check balances at, Filter attributes: Customer, Contract, Guest group, Currency, Company, Hotel
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetCustomerAccountsBalances(Val pDate = Undefined, pCustomer = Undefined, pContract = Undefined, pGuestGroup = Undefined, 
                                                              pCurrency = Undefined, pCompany = Undefined, pHotel = Undefined, 
															  pShowCurrentAccountsReceivable = Undefined, pShowForecastBalance = Undefined) Export
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
	EndIf;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	CustomerAccounts.AccountingCustomer,
	|	CustomerAccounts.AccountingContract,
	|	CustomerAccounts.GuestGroup,
	|	CustomerAccounts.AccountingCurrency,
	|	CustomerAccounts.Company,
	|	CustomerAccounts.Hotel,
	|	SUM(CustomerAccounts.Balance) AS Balance
	|FROM (
	|	SELECT
	|		CustomerAccountsBalance.AccountingCustomer AS AccountingCustomer,
	|		CustomerAccountsBalance.AccountingContract AS AccountingContract,
	|		CustomerAccountsBalance.GuestGroup AS GuestGroup,
	|		CustomerAccountsBalance.AccountingCurrency AS AccountingCurrency,
	|		CustomerAccountsBalance.Company AS Company,
	|		CustomerAccountsBalance.Hotel AS Hotel,
	|		CustomerAccountsBalance.SumBalance AS Balance
	|	FROM
	|		AccumulationRegister.CustomerAccounts.Balance(
	|		&qPeriod, TRUE " +
			?(pHotel <> Undefined, "AND (Hotel = &qHotel OR Hotel = &qEmptyHotel) ", "") + 
			?(pCustomer <> Undefined, "AND AccountingCustomer = &qCustomer ", "") + 
			?(pContract <> Undefined, "AND AccountingContract = &qContract ", "") + 
			?(pGuestGroup <> Undefined, "AND GuestGroup = &qGuestGroup ", "") + 
			?(pCompany <> Undefined, "AND Company = &qCompany ", "") + 
			?(pCurrency <> Undefined, "AND AccountingCurrency = &qCurrency ", "") + "
	|	) AS CustomerAccountsBalance
	|	UNION ALL
	|	SELECT
	|		CurrentAccountsReceivableBalance.Customer,
	|		CurrentAccountsReceivableBalance.Contract,
	|		CurrentAccountsReceivableBalance.GuestGroup,
	|		CurrentAccountsReceivableBalance.FolioCurrency,
	|		CurrentAccountsReceivableBalance.Company,
	|		CurrentAccountsReceivableBalance.Hotel,
	|		(CurrentAccountsReceivableBalance.SumBalance - CurrentAccountsReceivableBalance.CommissionSumBalance)
	|	FROM
	|		AccumulationRegister.CurrentAccountsReceivable.Balance(
	|		, &qShowCurrentAccountsReceivable " +
			?(pHotel <> Undefined, "AND Hotel = &qHotel ", "") + 
			?(pCustomer <> Undefined, "AND (Customer = &qCustomer OR &qIndividualsCustomerIsChoosen AND Customer <> &qEmptyCustomer AND Customer.IsIndividual OR &qIndividualsCustomerIsChoosen AND Customer = &qEmptyCustomer) ", "") + 
			?(pContract <> Undefined, "AND Contract = &qContract ", "") + 
			?(pGuestGroup <> Undefined, "AND GuestGroup = &qGuestGroup ", "") + 
			?(pCompany <> Undefined, "AND Company = &qCompany ", "") + 
			?(pCurrency <> Undefined, "AND FolioCurrency = &qCurrency ", "") + "
	|	) AS CurrentAccountsReceivableBalance
	|	UNION ALL
	|	SELECT
	|		CustomerAccountsForecast.Customer,
	|		CustomerAccountsForecast.Contract,
	|		CustomerAccountsForecast.GuestGroup,
	|		CustomerAccountsForecast.ReportingCurrency,
	|		CustomerAccountsForecast.Company,
	|		CustomerAccountsForecast.Hotel,
	|		(CustomerAccountsForecast.SalesTurnover - CustomerAccountsForecast.CommissionSumTurnover)
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|		&qForecastPeriodFrom, &qForecastPeriodTo, PERIOD, &qShowForecastBalance " +
			?(pHotel <> Undefined, "AND Hotel = &qHotel ", "") + 
			?(pCustomer <> Undefined, "AND (Customer = &qCustomer OR &qIndividualsCustomerIsChoosen AND Customer <> &qEmptyCustomer AND Customer.IsIndividual OR &qIndividualsCustomerIsChoosen AND Customer = &qEmptyCustomer) ", "") + 
			?(pContract <> Undefined, "AND Contract = &qContract ", "") + 
			?(pGuestGroup <> Undefined, "AND GuestGroup = &qGuestGroup ", "") + 
			?(pCompany <> Undefined, "AND Company = &qCompany ", "") + 
			?(pCurrency <> Undefined, "AND ReportingCurrency = &qCurrency ", "") + "
	|	) AS CustomerAccountsForecast
	|) AS CustomerAccounts
	|GROUP BY
	|	CustomerAccounts.AccountingCustomer,
	|	CustomerAccounts.AccountingContract,
	|	CustomerAccounts.GuestGroup,
	|	CustomerAccounts.AccountingCurrency,
	|	CustomerAccounts.Company,
	|	CustomerAccounts.Hotel
	|ORDER BY
	|	CustomerAccounts.AccountingCustomer.Description,
	|	CustomerAccounts.AccountingContract.Description,
	|	CustomerAccounts.GuestGroup.CheckInDate,
	|	CustomerAccounts.GuestGroup.Code,
	|	CustomerAccounts.Hotel.SortCode,
	|	CustomerAccounts.Company.SortCode,
	|	CustomerAccounts.AccountingCurrency.SortCode";
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qForecastPeriodFrom", tcOnServer.GetForecastStartDate(pHotel));
	vQry.SetParameter("qForecastPeriodTo", '39991231235959');
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qCurrency", pCurrency);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	If pShowCurrentAccountsReceivable = Undefined Then
		vQry.SetParameter("qShowCurrentAccountsReceivable", ?(ValueIsFilled(pHotel), pHotel.ShowCurrentAccountsReceivable, False));
	Else
		vQry.SetParameter("qShowCurrentAccountsReceivable", pShowCurrentAccountsReceivable);
	EndIf;
	If pShowForecastBalance = Undefined Then
		vQry.SetParameter("qShowForecastBalance", False);
	Else
		vQry.SetParameter("qShowForecastBalance", True);
	EndIf;
	If ValueIsFilled(pHotel) And ValueIsFilled(pCustomer) And pCustomer = pHotel.IndividualsCustomer Then
		vQry.SetParameter("qIndividualsCustomerIsChoosen", True);
	Else
		vQry.SetParameter("qIndividualsCustomerIsChoosen", False);
	EndIf;
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vResults = vQry.Execute().Unload();
	Return vResults;
EndFunction // cmGetCustomerAccountsBalances

// -----------------------------------------------------------------------------
// Description: Calculates and returnes customer undistributed advances
// Parameters: Date to check balances at, Filter attributes: Customer, Contract, Guest group, Currency, Company, Hotel
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetCustomerUndistributedAdvances(pCustomer = Undefined, pContract = Undefined, pGuestGroup = Undefined, 
                                            pCurrency = Undefined, pCompany = Undefined, pHotel = Undefined, pPeriod = Undefined) Export
	// Get accounting balances
	vCustomerAccounts = cmGetCustomerAccountsBalances(pPeriod, 
	                                                  ?(ValueIsFilled(pCustomer), pCustomer, Undefined),
													  ?(ValueIsFilled(pContract), pContract, Undefined), 
													  ?(ValueIsFilled(pGuestGroup), pGuestGroup, Undefined), 
	                                                  ?(ValueIsFilled(pCurrency), pCurrency, Undefined),
													  ?(ValueIsFilled(pCompany), pCompany, Undefined), 
													  ?(ValueIsFilled(pHotel), pHotel, Undefined), False);
	vCustomerAccounts.GroupBy("AccountingCurrency", "Balance");
	// Return table
	Return vCustomerAccounts;
EndFunction // cmGetCustomerUndistributedAdvances

// -----------------------------------------------------------------------------
//  Calculates and returnes customer undistributed deposits
//
// Parameters:
//  pCustomer	 - 	 - 
//  pContract	 - 	 - 
//  pGuestGroup	 - 	 - 
//  pCurrency	 - 	 - 
//  pCompany	 - 	 - 
//  pHotel		 - 	 - 
//  pPeriod		 - 	 - 
// 
// Returns:
//  ValueTable - List documents
//
Function cmGetCustomerUndistributedDeposits(pCustomer = Undefined, pContract = Undefined, pGuestGroup = Undefined, 
                                            pCurrency = Undefined, pCompany = Undefined, pHotel = Undefined, Val pPeriod = Undefined) Export
	// Get deposit balances
	If Not ValueIsFilled(pPeriod) Then
		pPeriod = '39991231235959';
	EndIf;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	CustomerDeposits.AccountingCustomer,
	|	CustomerDeposits.AccountingContract,
	|	CustomerDeposits.GuestGroup,
	|	CustomerDeposits.AccountingCurrency,
	|	CustomerDeposits.Company,
	|	CustomerDeposits.Hotel,
	|	SUM(CustomerDeposits.Balance) AS Balance
	|FROM (
	|	SELECT
	|		CustomerDepositsBalance.ProformaInvoice.AccountingCustomer AS AccountingCustomer,
	|		CustomerDepositsBalance.ProformaInvoice.AccountingContract AS AccountingContract,
	|		CustomerDepositsBalance.ProformaInvoice.GuestGroup AS GuestGroup,
	|		CustomerDepositsBalance.AccountingCurrency AS AccountingCurrency,
	|		CustomerDepositsBalance.ProformaInvoice.Company AS Company,
	|		CustomerDepositsBalance.Hotel AS Hotel,
	|		CustomerDepositsBalance.SumBalance AS Balance
	|	FROM
	|		AccumulationRegister.CustomerDeposits.Balance(
	|		&qPeriod, TRUE " +
			?(pHotel <> Undefined, "AND Hotel = &qHotel ", "") + 
			?(pCustomer <> Undefined, "AND ProformaInvoice.AccountingCustomer = &qCustomer ", "") + 
			?(pContract <> Undefined, "AND ProformaInvoice.AccountingContract = &qContract ", "") + 
			?(pGuestGroup <> Undefined, "AND ProformaInvoice.GuestGroup = &qGuestGroup ", "") + 
			?(pCompany <> Undefined, "AND ProformaInvoice.Company = &qCompany ", "") + 
			?(pCurrency <> Undefined, "AND AccountingCurrency = &qCurrency ", "") + "
	|	) AS CustomerDepositsBalance
	|) AS CustomerDeposits
	|GROUP BY
	|	CustomerDeposits.AccountingCustomer,
	|	CustomerDeposits.AccountingContract,
	|	CustomerDeposits.GuestGroup,
	|	CustomerDeposits.AccountingCurrency,
	|	CustomerDeposits.Company,
	|	CustomerDeposits.Hotel
	|ORDER BY
	|	CustomerDeposits.AccountingCustomer.Description,
	|	CustomerDeposits.AccountingContract.Description,
	|	CustomerDeposits.GuestGroup.CheckInDate,
	|	CustomerDeposits.GuestGroup.Code,
	|	CustomerDeposits.Hotel.SortCode,
	|	CustomerDeposits.Company.SortCode,
	|	CustomerDeposits.AccountingCurrency.SortCode";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qCurrency", pCurrency);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qHotel", pHotel);
	vResults = vQry.Execute().Unload();
	vResults.GroupBy("AccountingCurrency", "Balance");
	// Return table
	Return vResults;
EndFunction // cmGetCustomerUndistributedDeposits

// -----------------------------------------------------------------------------
//  Get list of invoices unpaied
//
// Parameters:
//  pDate		 - 	 - 
//  pCustomer	 - 	 - 
//  pContract	 - 	 - 
//  pGuestGroup	 - 	 - 
//  pCurrency	 - 	 - 
//  pCompany	 - 	 - 
//  pHotel		 - 	 - 
// 
// Returns:
//  ValueTable - Value table with invoices
//
Function cmGetInvoicesWithBalances(Val pDate = Undefined, pCustomer = Undefined, pContract = Undefined, pGuestGroup = Undefined, 
                                                          pCurrency = Undefined, pCompany = Undefined, pHotel = Undefined) Export
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
	EndIf;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	InvoiceAccountsBalance.Invoice AS Invoice,
	|	InvoiceAccountsBalance.Invoice.Number AS InvoiceNumber,
	|	InvoiceAccountsBalance.Invoice.Date AS InvoiceDate,
	|	InvoiceAccountsBalance.Company AS Company,
	|	InvoiceAccountsBalance.AccountingCustomer AS AccountingCustomer,
	|	InvoiceAccountsBalance.AccountingContract AS AccountingContract,
	|	InvoiceAccountsBalance.GuestGroup AS GuestGroup,
	|	InvoiceAccountsBalance.Invoice.Sum AS Sum,
	|	InvoiceAccountsBalance.Invoice.VATSum AS VATSum,
	|	InvoiceAccountsBalance.AccountingCurrency AS AccountingCurrency,
	|	InvoiceAccountsBalance.SumBalance AS Balance
	|FROM
	|	AccumulationRegister.InvoiceAccounts.Balance(&qPeriod, Invoice REFS Document.ProformaInvoice " + 
			?(pHotel <> Undefined, "AND Hotel = &qHotel ", "") + 
			?(pCustomer <> Undefined, "AND AccountingCustomer = &qCustomer ", "") + 
			?(pContract <> Undefined, "AND AccountingContract = &qContract ", "") + 
			?(pGuestGroup <> Undefined, "AND GuestGroup = &qGuestGroup ", "") + 
			?(pCompany <> Undefined, "AND Company = &qCompany ", "") + 
			?(pCurrency <> Undefined, "AND AccountingCurrency = &qCurrency ", "") + "
	|	) AS InvoiceAccountsBalance
	|ORDER BY
	|	InvoiceAccountsBalance.Invoice.PointInTime";
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qCurrency", pCurrency);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qHotel", pHotel);
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // cmGetInvoicesWithBalances

// -----------------------------------------------------------------------------
//  Get list of invoices unpaied
//
// Parameters:
//  pDate		 - 	 - 
//  pCustomer	 - 	 - 
//  pContract	 - 	 - 
//  pGuestGroup	 - 	 - 
//  pCurrency	 - 	 - 
//  pCompany	 - 	 - 
//  pHotel		 - 	 - 
// 
// Returns:
//  ValueTable - Value table with invoices
//
Function cmGetSettlementsWithBalances(Val pDate = Undefined, pCustomer = Undefined, pContract = Undefined, pGuestGroup = Undefined, 
                                                          pCurrency = Undefined, pCompany = Undefined, pHotel = Undefined) Export
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
	EndIf;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	InvoiceAccountsBalance.Invoice AS Invoice,
	|	InvoiceAccountsBalance.Invoice.Number AS InvoiceNumber,
	|	InvoiceAccountsBalance.Invoice.Date AS InvoiceDate,
	|	InvoiceAccountsBalance.Company AS Company,
	|	InvoiceAccountsBalance.AccountingCustomer AS AccountingCustomer,
	|	InvoiceAccountsBalance.AccountingContract AS AccountingContract,
	|	InvoiceAccountsBalance.GuestGroup AS GuestGroup,
	|	InvoiceAccountsBalance.Invoice.SumDue AS Sum,
	|	InvoiceAccountsBalance.Invoice.VATSum AS VATSum,
	|	InvoiceAccountsBalance.AccountingCurrency AS AccountingCurrency,
	|	InvoiceAccountsBalance.SumBalance AS Balance
	|FROM
	|	AccumulationRegister.InvoiceAccounts.Balance(&qPeriod, Invoice REFS Document.Settlement " + 
			?(pHotel <> Undefined, "AND Hotel = &qHotel ", "") + 
			?(pCustomer <> Undefined, "AND AccountingCustomer = &qCustomer ", "") + 
			?(pContract <> Undefined, "AND AccountingContract = &qContract ", "") + 
			?(pGuestGroup <> Undefined, "AND GuestGroup = &qGuestGroup ", "") + 
			?(pCompany <> Undefined, "AND Company = &qCompany ", "") + 
			?(pCurrency <> Undefined, "AND AccountingCurrency = &qCurrency ", "") + "
	|	) AS InvoiceAccountsBalance
	|ORDER BY
	|	InvoiceAccountsBalance.Invoice.PointInTime";
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qCurrency", pCurrency);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qHotel", pHotel);
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // cmGetSettlementsWithBalances

// -----------------------------------------------------------------------------
// Description: Returns amount of customer accounts balance
// Parameters: Date to check balance at, Filter attributes: Customer, Contract, Guest group, Currency, Company, Hotel
// Return value: Number, balance amount
// -----------------------------------------------------------------------------
Function cmGetCustomerAccountsBalance(Val pDate = Undefined, pCustomer, pContract, pGuestGroup, pCurrency, pCompany, pHotel) Export
	vBalance = 0;
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
	EndIf;
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerAccountsBalance.Company AS Company,
	|	CustomerAccountsBalance.AccountingCustomer AS AccountingCustomer,
	|	CustomerAccountsBalance.AccountingContract AS AccountingContract,
	|	CustomerAccountsBalance.GuestGroup AS GuestGroup,
	|	CustomerAccountsBalance.AccountingCurrency AS AccountingCurrency,
	|	CustomerAccountsBalance.Hotel AS Hotel,
	|	CustomerAccountsBalance.SumBalance AS Balance
	|FROM
	|	AccumulationRegister.CustomerAccounts.Balance(
	|			&qPeriod,
	|			AccountingCustomer = &qCustomer
	|				AND AccountingContract = &qContract
	|				AND AccountingCurrency = &qCurrency
	|				AND Company = &qCompany
	|				AND GuestGroup = &qGuestGroup
	|				AND Hotel = &qHotel) AS CustomerAccountsBalance";
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qCurrency", pCurrency);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qHotel", pHotel);
	vRes = vQry.Execute().Unload();
	For Each vRow In vRes Do
		vBalance = vBalance + vRow.Balance;
	EndDo;
	Return vBalance;
EndFunction // cmGetCustomerAccountsBalance	

// -----------------------------------------------------------------------------
// Description: Returns value table with invoice balances
// Parameters: Date to check balance at, List of invoices to get balances for
// Return value: Value table with invoice balances
// -----------------------------------------------------------------------------
Function cmGetInvoiceBalances(Val pDate = Undefined, pInvoices) Export
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
	EndIf;
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	InvoiceAccountsBalance.Company AS Company,
	|	InvoiceAccountsBalance.Invoice AS Invoice,
	|	InvoiceAccountsBalance.Hotel AS Hotel,
	|	InvoiceAccountsBalance.SumBalance AS Balance
	|FROM
	|	AccumulationRegister.InvoiceAccounts.Balance(&qPeriod, Invoice IN (&qInvoices)) AS InvoiceAccountsBalance";
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qInvoices", pInvoices);
	vRes = vQry.Execute().Unload();
	Return vRes;
EndFunction // cmGetInvoiceBalances

// -----------------------------------------------------------------------------
// Description: Returns value table with invoice balances
// Parameters: Date to check balance at, List of invoices to get balances for
// Return value: Value table with invoice balances
// -----------------------------------------------------------------------------
Function cmGetInvoiceDeposits(Val pDate = Undefined, pInvoices) Export
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
	EndIf;
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	InvoiceDepositsBalance.ProformaInvoice.Company AS Company,
	|	InvoiceDepositsBalance.ProformaInvoice AS Invoice,
	|	InvoiceDepositsBalance.Hotel,
	|	InvoiceDepositsBalance.SumBalance AS Balance
	|FROM
	|	AccumulationRegister.CustomerDeposits.Balance(&qPeriod, ProformaInvoice IN (&qInvoices)) AS InvoiceDepositsBalance";
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qInvoices", pInvoices);
	vRes = vQry.Execute().Unload();
	Return vRes;
EndFunction // cmGetInvoiceDeposits

// -----------------------------------------------------------------------------
// Description: Returns value table with list of all currencies
// Parameters: None
// Return value: Value table with currencies
// -----------------------------------------------------------------------------
Function cmGetAllCurrencies() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	Currencies.Ref AS Currency
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.DeletionMark = FALSE
	|ORDER BY Currencies.SortCode";
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllCurrencies

// -----------------------------------------------------------------------------
// Description: Returns value table with list of all card types
// Parameters: None
// Return value: Value table with client identification card types
// -----------------------------------------------------------------------------
Function cmGetAllIdentificationCardTypes() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	IdentificationCardTypes.Ref AS IdentificationCardType,
	|	IdentificationCardTypes.DoNotUseChargingRules AS DoNotUseChargingRules,
	|	IdentificationCardTypes.ExternalSystemsAllowed AS ExternalSystemsAllowed,
	|	IdentificationCardTypes.AdditionalServicesFolioCondition AS AdditionalServicesFolioCondition,
	|	IdentificationCardTypes.DoServiceRegistrationWithoutChargesControl AS DoServiceRegistrationWithoutChargesControl,
	|	IdentificationCardTypes.Description AS Description,
	|	IdentificationCardTypes.Code AS Code,
	|	IdentificationCardTypes.SortCode AS SortCode,
	|	IdentificationCardTypes.ColorName AS ColorName
	|FROM
	|	Catalog.IdentificationCardTypes AS IdentificationCardTypes
	|WHERE
	|	NOT IdentificationCardTypes.DeletionMark
	|	AND NOT IdentificationCardTypes.IsFolder
	|
	|ORDER BY
	|	IdentificationCardTypes.SortCode,
	|	IdentificationCardTypes.Description";
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllIdentificationCardTypes

// -----------------------------------------------------------------------------
// Description: Returns value list with all reasons for price chnage
// Parameters: None
// Return value: Value list with reasons
// -----------------------------------------------------------------------------
Function cmGetAllReasonsForPriceChange() Export
	// Build and run query
	vQryResult = cmGetAllPriceChangeReasons();
	vList = New ValueList();
	vList.LoadValues(vQryResult.UnloadColumn("Description"));
	Return vList;
EndFunction // cmGetAllReasonsForPriceChange

// -----------------------------------------------------------------------------
// Description: Returns currency presentation
// Parameters: Currency, Language
// Return value: String, Currency presentation
// -----------------------------------------------------------------------------
Function cmGetCurrencyPresentation(pCurrency, Val pLang = Undefined) Export
	If Not ValueIsFilled(pLang) Then
		pLang = SessionParameters.CurrentLanguage;
	EndIf;
	vCurrencyStr = "";
	If ValueIsFilled(pCurrency) Then
		If IsBlankString(pCurrency.CurrencySymbol) Then
			vCurrencyStr = pCurrency.GetObject().pmGetCurrencyDescription(pLang);
		Else
			vCurrencyStr = TrimAll(pCurrency.CurrencySymbol);
		EndIf;
	EndIf;
	Return vCurrencyStr;
EndFunction // cmGetCurrencyPresentation	

// -----------------------------------------------------------------------------
// Description: Returns value table with guest group client folios with debts
// Parameters: Guest group
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetGuestGroupClientsFoliosWithDebts(pGuestGroup) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccountsBalance.Folio AS Folio
	|FROM
	|	AccumulationRegister.Accounts.Balance(&qEndOfTime, Folio.GuestGroup <> &qGuestGroup) AS AccountsBalance
	|WHERE
	|	AccountsBalance.Folio.Client IN (
	|	SELECT
	|		Folio.Client
	|	FROM
	|		Document.Folio AS Folio
	|	WHERE
	|		Folio.GuestGroup = &qGuestGroup
	|		AND Folio.Client <> &qEmptyClient
	|	GROUP BY
	|		Folio.Client
	|	)
	|GROUP BY
	|	AccountsBalance.Folio";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qEndOfTime", '39991231235959');
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vFolios = vQry.Execute().Unload();
	
	vFoliosList = New ValueList();
	vFoliosList.LoadValues(vFolios.UnloadColumn("Folio"));
	
	Return vFoliosList;
EndFunction // cmGetGuestGroupClientsFoliosWithDebts

// -----------------------------------------------------------------------------
// Description: Returns value table with client folios with debts
// Parameters: Client, Guest group
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetClientFoliosWithDebts(pClient, pGuestGroup) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccountsBalance.Folio AS Folio
	|FROM
	|	AccumulationRegister.Accounts.Balance(
	|			&qEndOfTime,
	|			Folio.IsClosed
	|				AND Folio.Client = &qClient
	|				AND Folio.GuestGroup <> &qGuestGroup) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.Folio";
	vQry.SetParameter("qClient", pClient);
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qEndOfTime", '39991231235959');
	vFolios = vQry.Execute().Unload();
	
	vFoliosList = New ValueList();
	vFoliosList.LoadValues(vFolios.UnloadColumn("Folio"));
	
	Return vFoliosList;
EndFunction // cmGetClientFoliosWithDebts

// -----------------------------------------------------------------------------
// Description: Returns value table with accommodation/reservation folios with debts
// Parameters: Value list of documents to check, Return folios with negative balances only
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetDocumentFoliosWithDebts(pDocsList, pDepositsOnly = False) Export
	vDocsList = Undefined;
	If TypeOf(pDocsList) = Type("ValueTable") Then
		vDocsList = New ValueList();
		vDocsList.LoadValues(pDocsList.UnloadColumn("Document"));
	ElsIf TypeOf(pDocsList) = Type("Array") Then
		vDocsList = New ValueList();
		vDocsList.LoadValues(pDocsList);
	ElsIf TypeOf(pDocsList) <> Type("ValueList") Then
		vDocsList = New ValueList();
		vDocsList.Add(pDocsList);
	Else
		vDocsList = pDocsList;
	EndIf;
	// Add group folios
	vGuestGroups = New ValueList();
	vFoliosList = New ValueList();
	For Each vDocItem In vDocsList Do
		vDoc = vDocItem.Value;
		If ValueIsFilled(vDoc) And ValueIsFilled(vDoc.GuestGroup) Then
			vGuestGroup = vDoc.GuestGroup;
			If vGuestGroups.FindByValue(vGuestGroup) = Undefined Then
				vGuestGroups.Add(vGuestGroup);
				For Each vCRRow In vGuestGroup.ChargingRules Do
					If ValueIsFilled(vCRRow.ChargingFolio) And vFoliosList.FindByValue(vCRRow.ChargingFolio) = Undefined Then
						vFoliosList.Add(vCRRow.ChargingFolio);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccountsBalance.Folio, " + 
	?(pDepositsOnly, "(AccountsBalance.SumBalance + AccountsBalance.LimitBalance) AS SumBalance ", "AccountsBalance.SumBalance ") + "
	|FROM
	|	AccumulationRegister.Accounts.Balance(&qEndOfTime, Folio.ParentDoc IN (&qDocsList) OR Folio IN (&qFoliosList)) AS AccountsBalance " +
	?(pDepositsOnly, "WHERE (AccountsBalance.SumBalance + AccountsBalance.LimitBalance) < 0 ", "") + "
	|ORDER BY
	|	AccountsBalance.Folio.Room,
	|	AccountsBalance.Folio.DateTimeFrom,
	|	AccountsBalance.Folio.Client";
	vQry.SetParameter("qEndOfTime", '39991231235959');
	vQry.SetParameter("qDocsList", vDocsList);
	vQry.SetParameter("qFoliosList", vFoliosList);
	vFolios = vQry.Execute().Unload();
	Return vFolios;
EndFunction // cmGetDocumentFoliosWithDebts

// -----------------------------------------------------------------------------
// Description: Returns value table with accommodation/reservation folios with advances not cleared
// Parameters: Value list of documents to check
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetDocumentFoliosWithNotClearedAdvances(pDocsList) Export
	vFolios = New ValueTable();
	vAdvancePaymentSection = Undefined;
	vAdvanceSettlementPaymentMethod = Undefined;
	cmFillAdvanceAndAdvanceSettlementParameters(SessionParameters.CurrentHotel, SessionParameters.CurrentUser, vAdvancePaymentSection, vAdvanceSettlementPaymentMethod);
	If ValueIsFilled(vAdvancePaymentSection) And ValueIsFilled(vAdvanceSettlementPaymentMethod) Then
		vDocsList = Undefined;
		If TypeOf(pDocsList) = Type("ValueTable") Then
			vDocsList = New ValueList();
			vDocsList.LoadValues(pDocsList.UnloadColumn("Document"));
		ElsIf TypeOf(pDocsList) = Type("Array") Then
			vDocsList = New ValueList();
			vDocsList.LoadValues(pDocsList);
		ElsIf TypeOf(pDocsList) <> Type("ValueList") Then
			vDocsList = New ValueList();
			vDocsList.Add(pDocsList);
		Else
			vDocsList = pDocsList;
		EndIf;
		// Add group folios
		vGuestGroups = New ValueList();
		vFoliosList = New ValueList();
		For Each vDocItem In vDocsList Do
			vDoc = vDocItem.Value;
			If ValueIsFilled(vDoc) And ValueIsFilled(vDoc.GuestGroup) Then
				vGuestGroup = vDoc.GuestGroup;
				If vGuestGroups.FindByValue(vGuestGroup) = Undefined Then
					vGuestGroups.Add(vGuestGroup);
					For Each vCRRow In vGuestGroup.ChargingRules Do
						If ValueIsFilled(vCRRow.ChargingFolio) And vFoliosList.FindByValue(vCRRow.ChargingFolio) = Undefined Then
							vFoliosList.Add(vCRRow.ChargingFolio);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndDo;
		// Run query
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	AccountsBalance.Folio AS Folio,
		|	AccountsBalance.SumBalance AS SumBalance
		|FROM
		|	AccumulationRegister.Accounts.Balance(
		|			&qEndOfTime,
		|			PaymentSection.ChequeItemType = VALUE(Enum.ChequeItemTypes.Payment)
		|					AND Folio.ParentDoc IN (&qDocsList)
		|				OR Folio IN (&qFoliosList)) AS AccountsBalance
		|WHERE
		|	ISNULL(AccountsBalance.Folio.PaymentMethod.BookByCashRegister, FALSE)
		|	AND ISNULL(AccountsBalance.Folio.PaymentMethod.PrintCheque, FALSE)
		|
		|ORDER BY
		|	AccountsBalance.Folio.Room,
		|	AccountsBalance.Folio.DateTimeFrom,
		|	AccountsBalance.Folio.Client";
		vQry.SetParameter("qEndOfTime", '39991231235959');
		vQry.SetParameter("qDocsList", vDocsList);
		vQry.SetParameter("qFoliosList", vFoliosList);
		vFolios = vQry.Execute().Unload();
	EndIf;
	Return vFolios;
EndFunction // cmGetDocumentFoliosWithNotClearedAdvances

// -----------------------------------------------------------------------------
// Description: Calculates and returns customer balance taking active reservations into account
// Parameters: Customer, Contract. Hotel, Date to get balances at, Currency
// Return value: Number
// -----------------------------------------------------------------------------
Function cmCalculateCustomerOperationalBalance(pCustomer, pContract = Undefined, pHotel = Undefined, Val pPeriod = Undefined, rCurrency = Undefined) Export
	vBalance = 0;
	// Check parameters
	If Not ValueIsFilled(pCustomer) Then
		Return vBalance;
	EndIf;
	// Initialize parameters
	If Not ValueIsFilled(pPeriod) Then
		pPeriod = '39991231235959';
	EndIf;
	If Not ValueIsFilled(pHotel) Then
		pHotel = SessionParameters.CurrentHotel;
	EndIf;
	// Get customer/contract currency
	rCurrency = pCustomer.AccountingCurrency;
	If ValueIsFilled(pContract) Then
		rCurrency = pContract.AccountingCurrency;
	EndIf;
	If Not ValueIsFilled(rCurrency) Then
		Return vBalance;
	EndIf;
	// 1. Get customer accounting balance
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerAccountsBalance.AccountingCurrency,
	|	SUM(CustomerAccountsBalance.SumBalance) AS SumBalance
	|FROM
	|	AccumulationRegister.CustomerAccounts.Balance(
	|			&qPeriod,
	|			AccountingCustomer = &qCustomer " + 
					?(ValueIsFilled(pContract), "AND AccountingContract = &qContract ", "") + "
	|				AND Hotel = &qHotel) AS CustomerAccountsBalance
	|GROUP BY
	|	CustomerAccountsBalance.AccountingCurrency";
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPeriod", pPeriod);
	vAccountingBalances = vQry.Execute().Unload();
	For Each vAccountingBalancesRow In vAccountingBalances Do
		If vAccountingBalancesRow.AccountingCurrency <> rCurrency Then
			vBalance = vBalance + cmConvertCurrencies(vAccountingBalancesRow.SumBalance, vAccountingBalancesRow.AccountingCurrency, , rCurrency, , CurrentSessionDate(), pHotel);
		Else
			vBalance = vBalance + vAccountingBalancesRow.SumBalance;
		EndIf;
	EndDo;
	// 2. Add customer current accounts receivable balance
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentAccountsReceivableBalance.FolioCurrency, 
	|	SUM(CurrentAccountsReceivableBalance.SumBalance - CurrentAccountsReceivableBalance.CommissionSumBalance) AS SumBalance
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Balance(
	|			&qPeriod,
	|			Customer = &qCustomer " + 
					?(ValueIsFilled(pContract), "AND Contract = &qContract ", "") + "
	|				AND Hotel = &qHotel) AS CurrentAccountsReceivableBalance
	|GROUP BY
	|	CurrentAccountsReceivableBalance.FolioCurrency";
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPeriod", pPeriod);
	vCurrentAccountsReceivableBalances = vQry.Execute().Unload();
	For Each vCurrentAccountsReceivableBalancesRow In vCurrentAccountsReceivableBalances Do
		If vCurrentAccountsReceivableBalancesRow.FolioCurrency <> rCurrency Then
			vBalance = vBalance + cmConvertCurrencies(vCurrentAccountsReceivableBalancesRow.SumBalance, vCurrentAccountsReceivableBalancesRow.FolioCurrency, , rCurrency, , CurrentSessionDate(), pHotel);
		Else
			vBalance = vBalance + vCurrentAccountsReceivableBalancesRow.SumBalance;
		EndIf;
	EndDo;
	// 3. Add customer planned services turnover
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesForecastTurnovers.ReportingCurrency,
	|	SUM(SalesForecastTurnovers.SalesTurnover - SalesForecastTurnovers.CommissionSumTurnover) AS SalesTurnover
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			Customer = &qCustomer " +  
					?(ValueIsFilled(pContract), "AND Contract = &qContract ", "") + "
	|				AND Hotel = &qHotel) AS SalesForecastTurnovers
	|GROUP BY
	|	SalesForecastTurnovers.ReportingCurrency";
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPeriodFrom", tcOnServer.GetForecastStartDate(pHotel));
	vQry.SetParameter("qPeriodTo", '39991231235959');
	vPlannedServicesTurnovers = vQry.Execute().Unload();
	For Each vPlannedServicesTurnoversRow In vPlannedServicesTurnovers Do
		If vPlannedServicesTurnoversRow.ReportingCurrency <> rCurrency Then
			vBalance = vBalance + cmConvertCurrencies(vPlannedServicesTurnoversRow.SalesTurnover, vPlannedServicesTurnoversRow.ReportingCurrency, , rCurrency, , CurrentSessionDate(), pHotel);
		Else
			vBalance = vBalance + vPlannedServicesTurnoversRow.SalesTurnover;
		EndIf;
	EndDo;
	// Return balance
	Return vBalance;
EndFunction // cmCalculateCustomerOperationalBalance

// -----------------------------------------------------------------------------
// Description: Calculates and returns agent commission amount for the given period
// Parameters: Agent, Customer, Contract, Hotel, Begin of period, End of period, Currency
// Return value: Number
// -----------------------------------------------------------------------------
Function cmCalculateAgentCommissionTurnovers(pAgent, pCustomer, pContract = Undefined, pHotel = Undefined, Val pPeriodFrom = Undefined, Val pPeriodTo = Undefined, rCurrency = Undefined) Export
	vCommissionTurnover = 0;
	// Check parameters
	If Not ValueIsFilled(pAgent) Then
		Return vCommissionTurnover;
	EndIf;
	// Initialize parameters
	If Not ValueIsFilled(pPeriodFrom) Then
		pPeriodFrom = '00010101';
	EndIf;
	If Not ValueIsFilled(pPeriodTo) Then
		pPeriodTo = '00010101';
	EndIf;
	If Not ValueIsFilled(pHotel) Then
		pHotel = SessionParameters.CurrentHotel;
	EndIf;
	// Get customer/contract currency
	rCurrency = pAgent.AccountingCurrency;
	If ValueIsFilled(pContract) Then
		rCurrency = pContract.AccountingCurrency;
	EndIf;
	If Not ValueIsFilled(rCurrency) Then
		Return vCommissionTurnover;
	EndIf;
	// 1. Get customer commission turnover
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesTurnovers.ReportingCurrency,
	|	SUM(SalesTurnovers.CommissionSumTurnover) AS CommissionSumTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			Agent = &qAgent " + 
					?(ValueIsFilled(pCustomer), "AND ParentDoc.Customer = &qCustomer ", "") + 
					?(ValueIsFilled(pContract), "AND ParentDoc.Contract = &qContract ", "") + "
	|				AND Hotel = &qHotel) AS SalesTurnovers
	|GROUP BY
	|	SalesTurnovers.ReportingCurrency";
	vQry.SetParameter("qAgent", pAgent);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vServicesTurnovers = vQry.Execute().Unload();
	For Each vServicesTurnoversRow In vServicesTurnovers Do
		If vServicesTurnoversRow.ReportingCurrency <> rCurrency Then
			vCommissionTurnover = vCommissionTurnover + cmConvertCurrencies(vServicesTurnoversRow.CommissionSumTurnover, vServicesTurnoversRow.ReportingCurrency, , rCurrency, , CurrentSessionDate(), pHotel);
		Else
			vCommissionTurnover = vCommissionTurnover + vServicesTurnoversRow.CommissionSumTurnover;
		EndIf;
	EndDo;
	// 2. Add customer planned services commission turnover
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesForecastTurnovers.ReportingCurrency,
	|	SUM(SalesForecastTurnovers.CommissionSumTurnover) AS CommissionSumTurnover
	|FROM
	|	AccumulationRegister.SalesForecast.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			Agent = &qAgent " + 
					?(ValueIsFilled(pCustomer), "AND ParentDoc.Customer = &qCustomer ", "") + 
					?(ValueIsFilled(pContract), "AND ParentDoc.Contract = &qContract ", "") + "
	|				AND Hotel = &qHotel) AS SalesForecastTurnovers
	|GROUP BY
	|	SalesForecastTurnovers.ReportingCurrency";
	vQry.SetParameter("qAgent", pAgent);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qHotel", pHotel);
	vForecastStartDate = tcOnServer.GetForecastStartDate(pHotel);
	vForecastEndDate = ?(ValueIsFilled(pPeriodTo), pPeriodTo, '39991231235959');
	If pPeriodFrom < vForecastStartDate And vForecastStartDate < vForecastEndDate Then
		vQry.SetParameter("qPeriodFrom", vForecastStartDate);
		vQry.SetParameter("qPeriodTo", vForecastEndDate);
	Else
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", pPeriodTo);
	EndIf;
	vPlannedServicesTurnovers = vQry.Execute().Unload();
	For Each vPlannedServicesTurnoversRow In vPlannedServicesTurnovers Do
		If vPlannedServicesTurnoversRow.ReportingCurrency <> rCurrency Then
			vCommissionTurnover = vCommissionTurnover + cmConvertCurrencies(vPlannedServicesTurnoversRow.CommissionSumTurnover, vPlannedServicesTurnoversRow.ReportingCurrency, , rCurrency, , CurrentSessionDate(), pHotel);
		Else
			vCommissionTurnover = vCommissionTurnover + vPlannedServicesTurnoversRow.CommissionSumTurnover;
		EndIf;
	EndDo;
	// Return commission turnover
	Return vCommissionTurnover;
EndFunction // cmCalculateAgentCommissionTurnovers

// -----------------------------------------------------------------------------
//  Creates new or returns existing client identification card by card identifier
//
// Parameters:
//  pIdentifier				 - 	 - 
//  pIDCardRef				 - 	 - 
//  pParentDoc				 - 	 - 
//  pFolio					 - 	 - 
//  pClient					 - 	 - 
//  pRoom					 - 	 - 
//  pDateTimeFrom			 - 	 - 
//  pDateTimeTo				 - 	 - 
//  pAdd					 - 	 - 
//  pCardUID				 - 	 - 
//  pUseDeleted				 - 	 - 
//  pIdentificationCardType	 - 	 - 
// 
// Returns:
//  CatalogRef.IdentificationCards - Ref
//
Function cmGetClientIdentificationCard(pIdentifier, pIDCardRef, pParentDoc, pFolio, pClient, pRoom, pDateTimeFrom, pDateTimeTo, pAdd = True, pCardUID = Undefined, pUseDeleted = False, pIdentificationCardType = Undefined, pDoorLockSystemAuthorization = Undefined) Export
	vIDCardRef = Catalogs.IdentificationCards.EmptyRef();
	// Get list of cards for the current folio
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Ref AS Ref,
	|	IdentificationCards.Code AS Code,
	|	IdentificationCards.Description AS Description,
	|	IdentificationCards.IsBlocked AS IsBlocked,
	|	IdentificationCards.IsCheckedOut AS IsCheckedOut,
	|	IdentificationCards.Identifier AS Identifier,
	|	IdentificationCards.ParentDoc AS ParentDoc,
	|	IdentificationCards.Folio AS Folio,
	|	IdentificationCards.GuestGroup AS GuestGroup,
	|	IdentificationCards.Client AS Client,
	|	IdentificationCards.Room AS Room,
	|	IdentificationCards.DateTimeFrom AS DateTimeFrom,
	|	IdentificationCards.DateTimeTo AS DateTimeTo,
	|	IdentificationCards.Hotel AS Hotel,
	|	IdentificationCards.BlockReason AS BlockReason
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	(&qUseDeleted
	|			OR NOT &qUseDeleted
	|				AND NOT IdentificationCards.DeletionMark)
	|	AND NOT IdentificationCards.IsBlocked
	|	AND (IdentificationCards.Folio = &qFolio
	|				AND &qFolioIsNotEmpty
	|			OR IdentificationCards.ParentDoc = &qParentDoc
	|				AND &qParentDocIsNotEmpty)
	|
	|ORDER BY
	|	Code";
	vQry.SetParameter("qUseDeleted", pUseDeleted);
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qFolioIsNotEmpty", ValueIsFilled(pFolio));
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qParentDocIsNotEmpty", ValueIsFilled(pParentDoc));
	vCards = vQry.Execute().Unload();
	If ValueIsFilled(pFolio) And (pAdd Or vCards.Count() = 0) Then
		// Create new client identification card
		If ValueIsFilled(pIDCardRef) Then
			vIDCardObj = pIDCardRef.GetObject();
		Else
			vIDCardObj = Catalogs.IdentificationCards.CreateItem();
			vIDCardObj.SetNewCode();
		EndIf;
		vIDCardObj.Description = ?(ValueIsFilled(pClient), TrimAll(pClient.FullName), "");
		If ValueIsFilled(pIdentifier) Then
			vIDCardObj.Identifier = pIdentifier;
		Else
			vIDCardObj.Identifier = Format(cmCastToNumber(vIDCardObj.Code), "ND=12; NFD=0; NZ=; NLZ=; NG=");
		EndIf;
		vIDCardObj.Folio = pFolio;
		vIDCardObj.ParentDoc = pParentDoc;
		vIDCardObj.GuestGroup = pFolio.GuestGroup;
		vIDCardObj.Client = pClient;
		vIDCardObj.Room = pRoom;
		vIDCardObj.DateTimeFrom = pDateTimeFrom;
		vIDCardObj.DateTimeTo = pDateTimeTo;
		vIDCardObj.IsBlocked = False;
		vIDCardObj.BlockReason = "";
		vIDCardObj.IsCheckedOut = pFolio.IsClosed;
		vIDCardObj.Hotel = pFolio.Hotel;
		If pCardUID <> Undefined Then
			vIDCardObj.CardUID = TrimAll(pCardUID);
		EndIf;
		If pIdentificationCardType <> Undefined Then
			vIDCardObj.IdentificationCardType = pIdentificationCardType;
		EndIf;  
		If pDoorLockSystemAuthorization <> Undefined Then
			vIDCardObj.DoorLockSystemAuthorization = pDoorLockSystemAuthorization;
		EndIf;
		vIDCardObj.Author = SessionParameters.CurrentUser;
		vIDCardObj.CreateDate = CurrentSessionDate();
		vIDCardObj.DeletionMark = False;
		vIDCardObj.Write();
		// Get ref
		vIDCardRef = vIDCardObj.Ref;
	Else
		If vCards.Count() > 0 Then
			vIDCardRef = vCards.Get(0).Ref;
			If vIDCardRef.DeletionMark Then
				vIDCardObj = vIDCardRef.GetObject();
				vIDCardObj.SetDeletionMark(False);
			EndIf;
		EndIf;
	EndIf;
	Return vIDCardRef;
EndFunction // cmGetClientIdentificationCard

// -----------------------------------------------------------------------------
// Description: Function tries to find and return client identification card by card identifier
// Parameters: Card identifier
// Return value: Client identification card reference or empty reference
// -----------------------------------------------------------------------------
Function cmGetClientIdentificationCardById(pIdentifier, pUseDeleted = False) Export
	vCardRef = Catalogs.IdentificationCards.EmptyRef();
	// Try to find client identification card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Ref AS Ref
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	(IdentificationCards.Identifier = &qIdentifier
	|			OR IdentificationCards.CardUID = &qIdentifier)
	|				AND (&qUseDeleted
	|					OR NOT &qUseDeleted
	|						AND NOT IdentificationCards.DeletionMark
	|						AND NOT IdentificationCards.IsCheckedOut)
	|
	|ORDER BY
	|	IdentificationCards.DeletionMark,
	|	IdentificationCards.CreateDate DESC,
	|	IdentificationCards.Code DESC";
	vQry.SetParameter("qUseDeleted", pUseDeleted);
	vQry.SetParameter("qIdentifier", TrimAll(pIdentifier));
	vCards = vQry.Execute().Unload();
	If vCards.Count() > 0 Then
		vCardRef = vCards.Get(0).Ref;
	EndIf;
	Return vCardRef;
EndFunction // cmGetClientIdentificationCardById

// -----------------------------------------------------------------------------
// Description: Builds client identification card identifier from the data being read from the card
// Parameters: Data being read from the card
// Return value: String, card identifier
// -----------------------------------------------------------------------------
Function cmGetCardIdentifier(pCardData) Export
	vCardID = pCardData;
	If StrLen(pCardData) > 3 Then
		// Remove prefix and suffix chars
		If Right(pCardData, 3) = "+++" Then
			vCardID = Mid(TrimAll(pCardData), 2);
			vCardID = Left(vCardID, StrLen(vCardID) - 3);
		ElsIf Right(pCardData, 2) = "?," Then
			vCardID = Mid(TrimAll(pCardData), 2);
			vCardID = Left(vCardID, StrLen(vCardID) - 2);
		ElsIf CharCode(Left(pCardData, 1)) = 1110 And CharCode(Mid(pCardData, 14, 1)) = 191 Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf CharCode(Left(pCardData, 1)) = 1110 And CharCode(Mid(pCardData, 2, 1)) = 59 And CharCode(Mid(pCardData, 15, 1)) = 58 Then
			vCardID = Mid(pCardData, 3, 12);
		ElsIf CharCode(Left(pCardData, 1)) = 186 And CharCode(Mid(pCardData, 14, 1)) = 191 Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf Left(pCardData, 1) = ";" And Mid(pCardData, 14, 1) = "?" Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf Upper(Right(pCardData, 7)) = "NO CARD" And StrLen(TrimAll(pCardData)) > 7 Then
			vCardID = TrimAll(Left(TrimAll(pCardData), StrLen(TrimAll(pCardData)) - 7));
		EndIf;
	Else
		vCardID = "";
	EndIf;
	Return vCardID;
EndFunction // cmGetCardIdentifier	

// -----------------------------------------------------------------------------
// Description: Returns value table with client identification cards by folio
// Parameters: Folio
// Return value: Value table with client identification cards
// -----------------------------------------------------------------------------
Function cmGetClientIdentificationCardsByFolio(pFolio) Export
	// Try to find client identification cards by folio
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Ref AS Ref
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	NOT IdentificationCards.DeletionMark
	|	AND IdentificationCards.Folio = &qFolio
	|
	|ORDER BY
	|	IdentificationCards.Code";
	vQry.SetParameter("qFolio", pFolio);
	vCards = vQry.Execute().Unload();
	Return vCards;
EndFunction // cmGetClientIdentificationCardsByFolio

// -----------------------------------------------------------------------------
// Description: Returns value table with client identification cards by parent document
// Parameters: Parent document (accommodation, reservation, resource reservation, set room quota)
// Return value: Value table with client identification cards
// -----------------------------------------------------------------------------
Function cmGetClientIdentificationCardsByParentDoc(pParentDoc, pAll = False) Export
	// Try to find client identification cards by parent doc
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Ref AS Ref
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	(NOT IdentificationCards.DeletionMark
	|			OR &qAll)
	|	AND IdentificationCards.ParentDoc = &qParentDoc
	|
	|ORDER BY
	|	IdentificationCards.Code";
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qAll", pAll);
	vCards = vQry.Execute().Unload();
	Return vCards;
EndFunction // cmGetClientIdentificationCardsByParentDoc

// -----------------------------------------------------------------------------
// Description: Returns value table with client identification cards by room
// Parameters: Room item reference
// Return value: Value table with client identification cards
// -----------------------------------------------------------------------------
Function cmGetClientIdentificationCardsByRoom(pRoom, pAll = False, pGuestGroup = Undefined, pWithoutCheckedOutCards = False) Export
	// Try to find client identification cards by parent doc
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Ref AS Ref
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	(NOT IdentificationCards.DeletionMark
	|				AND (&qWithoutCheckedOutCards
	|						AND NOT IdentificationCards.IsCheckedOut
	|					OR NOT &qWithoutCheckedOutCards)
	|			OR &qAll)
	|	AND IdentificationCards.Room = &qRoom
	|	AND (NOT &qGuestGroupIsFilled
	|			OR &qGuestGroupIsFilled
	|				AND IdentificationCards.GuestGroup = &qGuestGroup)
	|
	|ORDER BY
	|	IdentificationCards.Code";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qAll", pAll);
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qGuestGroupIsFilled", ?(pGuestGroup = Undefined, False, True));
	vQry.SetParameter("qWithoutCheckedOutCards", pWithoutCheckedOutCards);
	vCards = vQry.Execute().Unload();
	Return vCards;
EndFunction // cmGetClientIdentificationCardsByRoom

// -----------------------------------------------------------------------------
// Description: Returns charging folio for given document and service
// Parameters: Reference to accommodation, reservation, resource reservation or 
//             set room quota document, Service reference
// Return value: Folio reference
// -----------------------------------------------------------------------------
Function cmGetDocumentChargingFolioForService(pDoc, pService, pDate) Export
	vFolio = Undefined;
	If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Or
	   TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
		vChargingRules = pDoc.ChargingRules.Unload();
		If Not pDoc.IgnoreGroupChargingRules Then
			cmAddGuestGroupChargingRules(vChargingRules, pDoc.GuestGroup);
		EndIf;
		For Each vCRRow In vChargingRules Do
			If cmIsServiceFitToTheChargingRule(vCRRow, pService, BegOfDay(pDate), False, False) Then
				vFolio = vCRRow.ChargingFolio;
				Break;
			EndIf;
		EndDo;
	ElsIf TypeOf(pDoc) = Type("DocumentRef.ResourceReservation") Then
		vFolio = pDoc.ChargingFolio;
	EndIf;
	Return vFolio;
EndFunction // cmGetDocumentChargingFolioForService 

// -----------------------------------------------------------------------------
// Description: Returns service by service code
// Parameters: Service code
// Return value: Service reference
// -----------------------------------------------------------------------------
Function cmGetServiceByCode(pServiceCode) Export
	vService = Catalogs.Services.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Services.Ref AS Ref
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	Services.Code = &qCode
	|	AND NOT Services.DeletionMark
	|	AND NOT Services.IsFolder";
	vQry.SetParameter("qCode", pServiceCode);
	vServices = vQry.Execute().Unload();
	If vServices.Count() > 0 Then
		vService = vServices.Get(0).Ref;
	EndIf;
	Return vService;
EndFunction // cmGetServiceByCode

// -----------------------------------------------------------------------------
// Description: Returns list of service groups with service given
// Parameters: Service
// Return value: Value list of service groups
// -----------------------------------------------------------------------------
Function cmGetListOfServiceServiceGroups(pService) Export
	vStruct = CachedAccounts.GetListOfServiceServiceGroups(pService);
	vList = New ValueList();
	For Each vStructKeyAndValue In vStruct Do
		vList.Add(vStructKeyAndValue.Value);
	EndDo;
	Return vList;
EndFunction // cmGetListOfServiceServiceGroups

// -----------------------------------------------------------------------------
// Description: Returns list of contracts valid for the given period
// Parameters: Customer, Begin of period, End of period
// Return value: Value list of contracts
// -----------------------------------------------------------------------------
Function cmGetListOfValidContracts(pOwner, pPeriodFrom = '00010101', pPeriodTo = '00010101', pCreateDate = '00010101', pHotel = Undefined) Export
	vHotel = pHotel;
	If vHotel = Undefined Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;	
	// Build list of valid contracts
	vValidContracts = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Contracts.Ref AS Ref
	|FROM
	|	Catalog.Contracts AS Contracts
	|WHERE
	|	(Contracts.Owner = &qOwner
	|			OR &qOwnerIsEmpty)
	|	AND NOT Contracts.DeletionMark
	|	AND (Contracts.PeriodCheckType = 0
	|				AND ((Contracts.ValidFromDate <= &qPeriodFrom
	|						OR Contracts.ValidFromDate = &qEmptyDate)
	|						AND (Contracts.ValidToDate >= &qPeriodFrom
	|							OR Contracts.ValidToDate = &qEmptyDate)
	|					OR &qPeriodFrom = &qEmptyDate)
	|				AND ((Contracts.ValidFromDate <= &qPeriodTo
	|						OR Contracts.ValidFromDate = &qEmptyDate)
	|						AND (Contracts.ValidToDate >= &qPeriodTo
	|							OR Contracts.ValidToDate = &qEmptyDate)
	|					OR &qPeriodTo = &qEmptyDate)
	|			OR Contracts.PeriodCheckType = 1
	|				AND (Contracts.ValidFromDate <= &qCreateDate
	|					OR Contracts.ValidFromDate = &qEmptyDate
	|					OR &qCreateDate = &qEmptyDate)
	|				AND (Contracts.ValidToDate >= &qCreateDate
	|					OR Contracts.ValidToDate = &qEmptyDate
	|					OR &qCreateDate = &qEmptyDate))
	|	AND (Contracts.Hotel = &qHotel
	|			OR Contracts.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|
	|ORDER BY
	|	Contracts.Description";
	vQry.SetParameter("qOwner", pOwner);
	vQry.SetParameter("qOwnerIsEmpty", Not ValueIsFilled(pOwner));
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", BegOfDay(pPeriodTo));
	vQry.SetParameter("qCreateDate", BegOfDay(pCreateDate));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", vHotel);

	vQryRes = vQry.Execute().Select();
	
	While vQryRes.Next() Do
		vValidContracts.Add(vQryRes.Ref);
	EndDo;
	Return vValidContracts;
EndFunction // cmGetListOfValidContracts

// -----------------------------------------------------------------------------
// Description: Returns first transaction for the given folio
// Parameters: Folio
// Return value: Refrence to the charge/payment
// -----------------------------------------------------------------------------
Function cmGetFirstFolioTransaction(pFolio) Export
	vTran = Undefined;
	vQry =  New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Accounts.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.Folio = &qFolio
	|
	|ORDER BY
	|	Accounts.Period";
	vQry.SetParameter("qFolio", pFolio);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vTran = vQryRes.Get(0).Recorder;
	EndIf;
	Return vTran;
EndFunction // cmGetFirstFolioTransaction

// -----------------------------------------------------------------------------
// Description: Returns value table with one row with first folio transaction and 
//              last folio transaction dates specified
// Parameters: Folio
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetFirstLastFolioCharges(pFolio) Export
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	Accounts.Folio AS Folio,
	|	MAX(Accounts.Period) AS FolioChargeMaxDate,
	|	MIN(Accounts.Period) AS FolioChargeMinDate
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|WHERE
	|	Accounts.Folio = &qFolio
	|	AND Accounts.RecordType = &qReceipt
	|
	|GROUP BY
	|	Accounts.Folio";
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmGetFirstLastFolioCharges

// -----------------------------------------------------------------------------
// Description: Returns client with maximum amount of services charged for the given group
// Parameters: Guest group, Client
// Return value: Client reference
// -----------------------------------------------------------------------------
Function cmGetHeadOfGroupClient(pGuestGroup, pClient, rClientDoc) Export
	vHGClient = pClient;
	rClientDoc = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	SalesTurnovers.Client AS Client,
	|	SalesTurnovers.ParentDoc AS ParentDoc,
	|	SalesTurnovers.AccommodationType,
	|	ISNULL(SalesTurnovers.ParentDoc.IsMaster, FALSE) AS IsMaster,
	|	SalesTurnovers.RoomRevenueTurnover AS RoomRevenueTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(, , Period, GuestGroup = &qGuestGroup) AS SalesTurnovers
	|
	|ORDER BY
	|	IsMaster DESC,
	|	RoomRevenueTurnover DESC,
	|	SalesTurnovers.AccommodationType.SortCode";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vTopClients = vQry.Execute().Unload();
	If vTopClients.Count() > 0 Then
		vHGClient = vTopClients.Get(0).Client;
		rClientDoc = vTopClients.Get(0).ParentDoc;
	EndIf;
	// Return
	Return vHGClient;
EndFunction // cmGetHeadOfGroupClient

// -----------------------------------------------------------------------------
// Description: Returns minimum check-in date, maximum check-out date and number of guests for the given group
// Parameters: Guest group
// Return value: Value table with one row
// -----------------------------------------------------------------------------
Function cmGetGroupPeriodAndGuestsCheckedIn(pGuestGroup) Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GroupProperties.GuestGroup AS GuestGroup,
	|	MIN(GroupProperties.CheckInDate) AS CheckInDate,
	|	MAX(GroupProperties.CheckOutDate) AS CheckOutDate,
	|	SUM(GroupProperties.NumberOfPersons) AS GuestsCheckedIn,
	|	SUM(GroupProperties.NumberOfAdults) AS NumberOfAdults,
	|	SUM(GroupProperties.NumberOfTeenagers) AS NumberOfTeenagers,
	|	SUM(GroupProperties.NumberOfChildren) AS NumberOfChildren,
	|	SUM(GroupProperties.NumberOfInfants) AS NumberOfInfants
	|FROM
	|	(SELECT
	|		Accommodations.GuestGroup AS GuestGroup,
	|		Accommodations.CheckInDate AS CheckInDate,
	|		Accommodations.CheckOutDate AS CheckOutDate,
	|		Accommodations.NumberOfPersons AS NumberOfPersons,
	|		Accommodations.NumberOfAdults AS NumberOfAdults,
	|		Accommodations.NumberOfTeenagers AS NumberOfTeenagers,
	|		Accommodations.NumberOfChildren AS NumberOfChildren,
	|		Accommodations.NumberOfInfants AS NumberOfInfants
	|	FROM
	|		Document.Accommodation AS Accommodations
	|	WHERE
	|		Accommodations.Posted
	|		AND Accommodations.GuestGroup = &qGuestGroup
	|		AND Accommodations.AccommodationStatus.IsActive
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Reservations.GuestGroup,
	|		Reservations.CheckInDate,
	|		Reservations.CheckOutDate,
	|		Reservations.NumberOfPersons,
	|		Reservations.NumberOfAdults,
	|		Reservations.NumberOfTeenagers,
	|		Reservations.NumberOfChildren,
	|		Reservations.NumberOfInfants
	|	FROM
	|		Document.Reservation AS Reservations
	|	WHERE
	|		Reservations.Posted
	|		AND Reservations.GuestGroup = &qGuestGroup
	|		AND NOT Reservations.ReservationStatus.IsCheckIn
	|		AND (Reservations.ReservationStatus.IsActive
	|				OR Reservations.ReservationStatus.IsPreliminary)) AS GroupProperties
	|
	|GROUP BY
	|	GroupProperties.GuestGroup";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vGroupParams = vQry.Execute().Unload();
	// Return
	Return vGroupParams;
EndFunction // cmGetGroupPeriodAndGuestsCheckedIn

// -----------------------------------------------------------------------------
// Description: Returns calendar day type for the given room rate and date
// Parameters: Room rate, Date
// Return value: Calendar day type reference
// -----------------------------------------------------------------------------
Function cmGetCalendarDayType(pRoomRate, pDate, pCheckInDate = Undefined, pCheckOutDate = Undefined, rPriceTag = Undefined, pRoomType = Undefined, pPriceCalculationDate = '00010101') Export
	vCalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
	rPriceTag = Catalogs.PriceTags.EmptyRef();
	If ValueIsFilled(pRoomRate) And ValueIsFilled(pRoomRate.Calendar) Then
		If pCheckInDate <> Undefined And pCheckOutDate <> Undefined And pDate >= BegOfDay(pCheckInDate) And pDate <= pCheckOutDate Then
			vCalendarDays = CachedSettings.cmGetCalendarDays(pRoomRate.Calendar, pCheckInDate, pCheckOutDate, pCheckInDate, pCheckOutDate, pRoomType, pPriceCalculationDate);
			vCalendarDaysRow = vCalendarDays.Find(BegOfDay(pDate), "Period");
			If vCalendarDaysRow <> Undefined Then
				vCalendarDayType = vCalendarDaysRow.CalendarDayType;
				rPriceTag = vCalendarDaysRow.PriceTag;
			EndIf;
		Else
			vCalendarDays = Catalogs.Calendars.pmGetDays(pRoomRate.Calendar, pDate, pDate, pCheckInDate, pCheckOutDate, pRoomType, pPriceCalculationDate);
			If vCalendarDays.Count() > 0 Then
				vCalendarDaysRow = vCalendarDays.Get(0);
				If ValueIsFilled(pRoomType) And ValueIsFilled(vCalendarDaysRow.CalendarDayTypeByRoomType) Then
					vCalendarDayType = vCalendarDaysRow.CalendarDayTypeByRoomType;
				Else	  
					vCalendarDayType = vCalendarDaysRow.CalendarDayType;
				EndIf;
				If ValueIsFilled(pRoomType) And ValueIsFilled(vCalendarDaysRow.PriceTagByRoomType) Then
					rPriceTag = vCalendarDaysRow.PriceTagByRoomType;
				Else
					rPriceTag = vCalendarDaysRow.PriceTag;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vCalendarDayType;
EndFunction // cmGetCalendarDayType

// -----------------------------------------------------------------------------
Function cmGetCalendarDayTypes(pRoomRate, pPeriodFrom, pPeriodTo, pRoomType, pHotel, pPriceCalculationDate = '00010101') Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CalendarDays.AccountingDate AS AccountingDate,
	|	ActiveRoomTypes.RoomType AS RoomType,
	|	CASE
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|			THEN CalendarDays.CalendarDayType
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|			THEN CalendarDays.CalendarDayType
	|		ELSE CalendarDaysByRoomTypes.CalendarDayType
	|	END AS CalendarDayType
	|FROM
	|	InformationRegister.CalendarDays.SliceLast(
	|			&qPriceCalculationDate,
	|			Calendar = &qCalendar
	|				AND (AccountingDate BETWEEN &qDateFrom AND &qDateTo)) AS CalendarDays
	|		LEFT JOIN (SELECT
	|			RoomTypes.Ref AS RoomType
	|		FROM
	|			Catalog.RoomTypes AS RoomTypes
	|		WHERE
	|			RoomTypes.Owner IN HIERARCHY(&qHotel)
	|			AND RoomTypes.Ref IN HIERARCHY(&qRoomType)
	|			AND NOT RoomTypes.IsFolder
	|			AND NOT RoomTypes.DeletionMark) AS ActiveRoomTypes
	|		ON (TRUE)
	|		LEFT JOIN (SELECT
	|			CalendarDaysByRoomTypesSliceLast.RoomType AS RoomType,
	|			CalendarDaysByRoomTypesSliceLast.AccountingDate AS AccountingDate,
	|			CalendarDaysByRoomTypesSliceLast.CalendarDayType AS CalendarDayType
	|		FROM
	|			InformationRegister.CalendarDaysByRoomTypes.SliceLast(
	|					&qPriceCalculationDate,
	|						AccountingDate BETWEEN &qDateFrom AND &qDateTo
	|						AND Calendar = &qCalendar
	|						AND RoomType IN HIERARCHY (&qRoomType)
	|						AND Hotel IN HIERARCHY (&qHotel)) AS CalendarDaysByRoomTypesSliceLast) AS CalendarDaysByRoomTypes
	|		ON CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
	|			AND (ActiveRoomTypes.RoomType = CalendarDaysByRoomTypes.RoomType)";
	vQry.SetParameter("qCalendar", pRoomRate.Calendar);
	vQry.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(pPriceCalculationDate), pPriceCalculationDate, CurrentSessionDate()));
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qDateFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qDateTo", BegOfDay(pPeriodTo));
	vCalendarDayTypes = vQry.Execute().Unload();
	vCalendarDayTypes.Indexes.Add("AccountingDate, RoomType");
	Return vCalendarDayTypes;
EndFunction // cmGetCalendarDayTypes

// -----------------------------------------------------------------------------
// Description: Returns calendar day type for the given document (accommodation
//              or reservation) and date
// Parameters: Document object (Accommodation object or Reservation object), Date
// Return value: Calendar day type reference
// -----------------------------------------------------------------------------
Function cmGetDocumentCalendarDayType(pDocObj, pDate) Export
	vCalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
	// Try to find accommodation services for the given accounting date
	vRIRows = pDocObj.Services.FindRows(New Structure("AccountingDate, IsRoomRevenue", pDate, True));
	If vRIRows.Count() > 0 Then
		vRIRow = vRIRows.Get(0);
		vCalendarDayType = vRIRow.CalendarDayType;
	EndIf;
	// If nothing was found then try to get calendar day type by room rate
	If Not ValueIsFilled(vCalendarDayType) Then
		vRoomRate = pDocObj.RoomRate;
		vPriceCalculationDate = ?(ValueIsFilled(pDocObj.PriceCalculationDate), pDocObj.PriceCalculationDate, '39991231235959');
		vRoomRatesRow = pDocObj.RoomRates.Find(pDate, "AccountingDate");
		If vRoomRatesRow <> Undefined And ValueIsFilled(vRoomRatesRow.RoomRate) Then
			vRoomRate = vRoomRatesRow.RoomRate;
			If ValueIsFilled(vRoomRatesRow.PriceCalculationDate) Then
				vPriceCalculationDate = vRoomRatesRow.PriceCalculationDate;
			EndIf;
		EndIf;
		vCalendarDayType = cmGetCalendarDayType(vRoomRate, pDate, pDocObj.CheckInDate, pDocObj.CheckOutDate, , ?(ValueIsFilled(pDocObj.RoomTypeUpgrade), pDocObj.RoomTypeUpgrade, pDocObj.RoomType), vPriceCalculationDate);
	EndIf;
	Return vCalendarDayType;
EndFunction // cmGetDocumentCalendarDayType

// -----------------------------------------------------------------------------
// Description: Returns value table with folios locked by processing
// Parameters: Persistent objects structure
// Return value: Value table with list of locked folios
// -----------------------------------------------------------------------------
Function cmGetLockedFolios(amPersistentObjects) Export
	vLockedFolios = Undefined;
	If amPersistentObjects <> Undefined Then 
		amPersistentObjects.Property("LockedFolios", vLockedFolios);
		If vLockedFolios = Undefined Then
			vLockedFolios = New ValueTable();
			vLockedFolios.Columns.Add("Ref");
			vLockedFolios.Columns.Add("Folio", cmGetDocumentTypeDescription("Folio"));
			vLockedFolios.Columns.Add("OldParentDoc");
			amPersistentObjects.Insert("LockedFolios", vLockedFolios);
		EndIf;
	EndIf;
	Return vLockedFolios;
EndFunction // cmGetLockedFolios

// -----------------------------------------------------------------------------
// Description: Removes all document folios from the locked folios list
// Parameters: Accommodation/Reservation, Persistent objects structure
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmUnlockFoliosByRef(pObjectRef, amPersistentObjects) Export
	If amPersistentObjects <> Undefined Then 
		vLockedFolios = cmGetLockedFolios(amPersistentObjects);
		vLockedFoliosRows = vLockedFolios.FindRows(New Structure("Ref", pObjectRef));
		For Each vLockedFoliosRow In vLockedFoliosRows Do
			Try
				vFolioObj = vLockedFoliosRow.Folio.GetObject();
				If ValueIsFilled(vFolioObj.ParentDoc) And Not vFolioObj.ParentDoc.Posted Then
					If ValueIsFilled(vLockedFoliosRow.OldParentDoc) And vFolioObj.ParentDoc <> vLockedFoliosRow.OldParentDoc Then
						vFolioObj.ParentDoc = vLockedFoliosRow.OldParentDoc;
						vFolioObj.Write(DocumentWriteMode.Write);
					EndIf;
				EndIf;
			Except
			EndTry;
			vLockedFolios.Delete(vLockedFoliosRow);
		EndDo;
	EndIf;
EndProcedure // cmUnlockFoliosByRef

// -----------------------------------------------------------------------------
// Description: Adds all document folios to the locked folios list
// Parameters: Charging rules value table, Accommodation/Reservation, Persistent objects structure
// Return value: Whether folios were locked successfully or not
// -----------------------------------------------------------------------------
Function cmLockChargingRules(pChargingRules, pObjectRef, amPersistentObjects) Export
	vFoliosAreLocked = True;
	vLockedFolios = cmGetLockedFolios(amPersistentObjects);
	For Each vCRRow In pChargingRules Do
		If ValueIsFilled(vCRRow.ChargingFolio) And ValueIsFilled(vCRRow.ChargingFolio.ParentDoc) Then
			If Not vCRRow.IsTransfer Then
				Try
					vOldParentDoc = vCRRow.ChargingFolio.ParentDoc;
					// Update folio parent document
					vFolioObject = vCRRow.ChargingFolio.GetObject();
					vFolioObject.ParentDoc = pObjectRef;
					vFolioObject.Write(DocumentWriteMode.Write);
					// Save this folio as locked by the current user session
					vLockedFoliosRows = vLockedFolios.FindRows(New Structure("Ref, Folio", pObjectRef, vCRRow.ChargingFolio));
					If vLockedFoliosRows.Count() = 0 Then
						vLockedFoliosRow = vLockedFolios.Add();
						vLockedFoliosRow.Ref = pObjectRef;
						vLockedFoliosRow.Folio = vFolioObject.Ref;
						vLockedFoliosRow.OldParentDoc = vOldParentDoc;
					EndIf;
				Except
					vFoliosAreLocked = False;
					Break;
				EndTry;
			EndIf;
		Else
			vFoliosAreLocked = False;
			Break;
		EndIf;
	EndDo;
	If Not vFoliosAreLocked Then
		cmUnlockFoliosByRef(pObjectRef, amPersistentObjects);
	EndIf;
	Return vFoliosAreLocked;
EndFunction // cmLockChargingRules

// -----------------------------------------------------------------------------
//  Calculates minimum and maximum accounting dates for the given folio, accommodation/reservation
//
// Parameters:
//  pFolio		 - 	 - 
//  pDoc		 - 	 - 
//  rDateFrom	 - 	 - 
//  rDateTo		 - 	 - 
//
Procedure cmGetServicesPeriodByFolio(pFolio, pDoc, rDateFrom, rDateTo) Export
	If ValueIsFilled(pFolio) Then
		rDateFrom = pFolio.DateTimeFrom;
		rDateTo = pFolio.DateTimeTo;
		If pDoc.Services.Count() > 0 Then
			// Try to get min/max dates from folio charges
			vFirstLastCharges = cmGetFirstLastFolioCharges(pFolio);
			// Try to get min/max dates from services in the document
			vServices = pDoc.Services.Unload();
			vServices.Sort("AccountingDate");
			vRowsByFolio = vServices.FindRows(New Structure("Folio", pFolio));
			If vRowsByFolio.Count() > 0 Then
				rDateFrom = vRowsByFolio.Get(0).AccountingDate;
				rDateTo = vRowsByFolio.Get(vRowsByFolio.Count()-1).AccountingDate;
				// Compare with first last folio charge dates
				If vFirstLastCharges.Count() > 0 Then
					vFirstLastChargesRow = vFirstLastCharges.Get(0);
					If ValueIsFilled(vFirstLastChargesRow.FolioChargeMaxDate) And 
					   ValueIsFilled(vFirstLastChargesRow.FolioChargeMinDate) Then
						If BegOfDay(vFirstLastChargesRow.FolioChargeMinDate) = BegOfDay(rDateFrom) And 
						   ValueIsFilled(pFolio.DateTimeFrom) Then
							rDateFrom = pFolio.DateTimeFrom;
						EndIf;
						If BegOfDay(vFirstLastChargesRow.FolioChargeMaxDate) = BegOfDay(rDateTo) And 
						   ValueIsFilled(pFolio.DateTimeTo) Then
							rDateTo = pFolio.DateTimeTo;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // cmGetServicesPeriodByFolio

// -----------------------------------------------------------------------------
// Description: Calculates coupon barcode
// Parameters: Type of document as number: 1 - Charge, 2 - Reservation, 3 - Resource reservation
//             Document number
//             Service
// Return value: Coupon number as string
// -----------------------------------------------------------------------------
Function cmBuildCouponBarCode(pType, pNumber, pService, pDate, pQuantity) Export
	vDocTypeStr = Format(pType, "ND=1; NFD=0; NZ=; NLZ=; NG=");
	vDocNumberStr = Format(Number(cmGetDocumentNumberPresentation(TrimAll(pNumber))), "ND=9; NFD=0; NZ=; NLZ=; NG=");
	Try
		vSrvCodeStr = Format(Number(TrimAll(pService.Code)), "ND=5; NFD=0; NZ=; NLZ=; NG=");
	Except
		Raise NStr("en='Numbered service codes are supported only!';ru='Поддерживаются только числовые коды услуг!';de='Nur Zahlencodes der Dienstleistungen werden unterstützt!'");
	EndTry;
	vDayNumStr = Format((BegOfDay(pDate) - '20100101') / (24 * 3600), "ND=4; NFD=0; NZ=; NLZ=; NG=");
	vQuantityStr = Format(pType, "ND=3; NFD=0; NZ=; NLZ=; NG=");
	vCouponBarCode = "C" + vDocTypeStr + vDocNumberStr + vSrvCodeStr + vDayNumStr + vQuantityStr + "P";
	Return vCouponBarCode;
EndFunction // cmBuildCouponBarCode

// -----------------------------------------------------------------------------
// Description: Parses coupon barcode
// Parameters: String, coupon barcode
// Return value: Structure with fields: AccountingDate, Service, GuestGroup, Room, Resource, 
//                                      Client, Quantity, Folio, Recorder, GuestGroup
// -----------------------------------------------------------------------------
Function cmParseCouponBarCode(pCouponBarCode, pHotel) Export
	// Initialize structure
	vStruct = New Structure("AccountingDate, Service, Room, Resource, Client, Quantity, Folio, Recorder, GuestGroup");
	// Normalize barcode
	pCouponBarCode = TrimAll(pCouponBarCode);
	If Upper(Left(pCouponBarCode, 1)) <> "C" And Upper(Right(pCouponBarCode, 1)) <> "P" Then
		pCouponBarCode = "C" + pCouponBarCode + "P";
	EndIf;
	// Parse barcode
	vDocType = Number(Mid(pCouponBarCode, 2, 1));
	vDocNumber = cmGetDocumentNumberFromPresentation(Mid(pCouponBarCode, 3, 9), pHotel);
	vSrvCode = Format(Number(Mid(pCouponBarCode, 12, 5)), "ND=5; NFD=0; NZ=; NG=");
	vService = Catalogs.Services.FindByCode(vSrvCode);
	vAccountingDate = '20100101' + Number(Mid(pCouponBarCode, 17, 4)) * 24 * 3600;
	vQuantity = Number(Mid(pCouponBarCode, 21, 3));
	// Get document, folio and client
	vGuestGroup = Catalogs.GuestGroups.EmptyRef();
	vRoom = Catalogs.Clients.EmptyRef();
	vResource = Catalogs.Resources.EmptyRef();
	vClient = Catalogs.Clients.EmptyRef();
	vRecorder = Undefined;
	vFolio = Documents.Folio.EmptyRef();
	If vDocType = 1 Then // Charge
		vRecorder = Documents.Charge.FindByNumber(vDocNumber, vAccountingDate);
		If ValueIsFilled(vRecorder) Then
			vFolio = vRecorder.Folio;
			If ValueIsFilled(vRecorder.ParentDoc) Then
				If TypeOf(vRecorder.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vRecorder.ParentDoc) = Type("DocumentRef.Reservation") Then
					vClient = vRecorder.ParentDoc.Guest;
					vRoom = vRecorder.ParentDoc.Room;
					vGuestGroup = vRecorder.ParentDoc.GuestGroup;
				ElsIf TypeOf(vRecorder.ParentDoc) = Type("DocumentRef.ResourceReservation") Then
					vClient = vRecorder.ParentDoc.Client;
					vResource = vRecorder.ParentDoc.vResource;
					vGuestGroup = vRecorder.ParentDoc.GuestGroup;
				EndIf;
			Else
				vClient = vFolio.Client;
				vRoom = vFolio.Room;
				vGuestGroup = vFolio.GuestGroup;
			EndIf;
		EndIf;
	ElsIf vDocType = 2 Then // Reservation
		vRecorder = Documents.Reservation.FindByNumber(vDocNumber, vAccountingDate);
		If ValueIsFilled(vRecorder) Then
			vClient = vRecorder.Guest;
			vRoom = vRecorder.Room;
			vGuestGroup = vRecorder.GuestGroup;
			vSrvRows = vRecorder.Services.FindRows(New Structure("Service, AccountingDate", vService, vAccountingDate));
			If vSrvRows.Count() > 0 Then
				vSrvRow = vSrvRows.Get(0);
				vFolio = vSrvRow.Folio;
			EndIf;
		EndIf;
	ElsIf vDocType = 3 Then // Resource reservation
		vRecorder = Documents.ResourceReservation.FindByNumber(vDocNumber, vAccountingDate);
		If ValueIsFilled(vRecorder) Then
			vClient = vRecorder.Client;
			vResource = vRecorder.Resource;
			vFolio = vRecorder.ChargingFolio;
			vGuestGroup = vRecorder.GuestGroup;
		EndIf;
	EndIf;
	// Fill structure
	vStruct.AccountingDate = vAccountingDate;
	vStruct.Service = vService;
	vStruct.Room = vRoom;
	vStruct.Resource = vResource;
	vStruct.Client = vClient;
	vStruct.Quantity = vQuantity;
	vStruct.Folio = vFolio;
	vStruct.Recorder = vRecorder;
	vStruct.GuestGroup = vGuestGroup;
	// Return structure
	Return vStruct;
EndFunction // cmParseCouponBarCode

// -----------------------------------------------------------------------------
// Description: Returns value table with employees allowed to perform service specified
// Parameters: Service, Date to be used to get valid performers
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetServicePerformers(pService, pDate, pHotel) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServicePerformersSliceLast.Period AS Period,
	|	ServicePerformersSliceLast.Service AS Service,
	|	ServicePerformersSliceLast.Hotel AS Hotel,
	|	ServicePerformersSliceLast.Employee AS Employee
	|FROM
	|	InformationRegister.ServicePerformers.SliceLast(
	|			&qDate,
	|			(Service = &qService
	|				OR Service = &qServiceParent
	|				OR Service = &qServiceParentParent
	|				OR Service = &qServiceParentParentParent)
	|				AND (Hotel = &qHotel
	|					OR Hotel = &qEmptyHotel)) AS ServicePerformersSliceLast
	|
	|ORDER BY
	|	ServicePerformersSliceLast.Service.SortCode,
	|	ServicePerformersSliceLast.Service.Description,
	|	ServicePerformersSliceLast.Employee.SortCode,
	|	ServicePerformersSliceLast.Employee.Description";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qService", pService);
	If ValueIsFilled(pService) Then
		vQry.SetParameter("qServiceParent", pService.Parent);
		If ValueIsFilled(pService.Parent) Then
			vQry.SetParameter("qServiceParentParent", pService.Parent.Parent);
			If ValueIsFilled(pService.Parent.Parent) Then
				vQry.SetParameter("qServiceParentParentParent", pService.Parent.Parent.Parent);
			Else
				vQry.SetParameter("qServiceParentParentParent", Undefined);
			EndIf;
		Else
			vQry.SetParameter("qServiceParentParent", Undefined);
			vQry.SetParameter("qServiceParentParentParent", Undefined);
		EndIf;
	Else
		vQry.SetParameter("qServiceParent", Undefined);
		vQry.SetParameter("qServiceParentParent", Undefined);
		vQry.SetParameter("qServiceParentParentParent", Undefined);
	EndIf;
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	Return vQry.Execute().Unload();
EndFunction // cmGetServicePerformers

// -----------------------------------------------------------------------------
// Description: Returns bound service for the given one
// Parameters: Service catalog item reference
// Return value: Bound service reference if defined or Undefined otherwise
// -----------------------------------------------------------------------------
Function cmGetBoundService(pService) Export
	vBoundService = Undefined;
	If ValueIsFilled(pService) Then
		If ValueIsFilled(pService.BoundService) Then
			vBoundService = pService.BoundService;
		Else
			// Check folders
			vParent = pService.Parent;
			While ValueIsFilled(vParent) Do
				If ValueIsFilled(vParent.BoundService) Then
					vBoundService = vParent.BoundService;
					Break;
				EndIf;
				vParent = vParent.Parent;
			EndDo;
		EndIf;
	EndIf;
	Return vBoundService;
EndFunction // cmGetBoundService

// -----------------------------------------------------------------------------
// Description: Returns boolean flag indicating that document (accommodation or reservation) 
//              customer is payer for some room rate services
// Parameters: Document charging rules, Customer reference, Contract reference, Guest group reference
// Return value: Boolean, true - if customer is payer for some services, false - if not
// -----------------------------------------------------------------------------
Function cmCustomerIsPayer(pChargingRules, pCustomer, pContract, pGuestGroup, pIgnoreGroupChargingRules = False) Export
	If Not pIgnoreGroupChargingRules Then
		cmAddGuestGroupChargingRules(pChargingRules, pGuestGroup);
	EndIf;
	vCustomerIsPayer = False;
	If ValueIsFilled(pCustomer) And pChargingRules.Find(pCustomer, "Owner") <> Undefined Or 
	   ValueIsFilled(pContract) And pChargingRules.Find(pContract, "Owner") <> Undefined Then
		If Not pCustomer.DoNotPostCommission Then
			vCustomerIsPayer = True;
		EndIf;
	EndIf;
	Return vCustomerIsPayer;
EndFunction // cmCustomerIsPayer 

// -----------------------------------------------------------------------------
// Description: Adds guest group charging rules to the document charging rules value table
// Parameters: Document charging rules, Guest group reference
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmAddGuestGroupChargingRules(pChargingRules, pGuestGroup) Export
	If ValueIsFilled(pGuestGroup) And pGuestGroup.ChargingRules.Count() > 0 Then
		For Each vGGCRRow In pGuestGroup.ChargingRules Do
			vCRRow = pChargingRules.Insert(pGuestGroup.ChargingRules.IndexOf(vGGCRRow));
			FillPropertyValues(vCRRow, vGGCRRow);
			If ValueIsFilled(vCRRow.ChargingFolio) Then
				If ValueIsFilled(vCRRow.ChargingFolio.Contract) Then
					vCRRow.Owner = vCRRow.ChargingFolio.Contract;
				ElsIf ValueIsFilled(vCRRow.ChargingFolio.Customer) Then
					vCRRow.Owner = vCRRow.ChargingFolio.Customer;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // cmAddGuestGroupChargingRules

// -----------------------------------------------------------------------------
// Description: returns hotel default credit limit
// Parameters: Hotel item reference
// Return value: Credit limit
// -----------------------------------------------------------------------------
Function cmGetDefaultCreditLimit(pHotel) Export
	vCreditLimit = 0;
	If ValueIsFilled(pHotel) Then
		For Each vCRRow In pHotel.ChargingRules Do
			If ValueIsFilled(vCRRow.ChargingFolio) Then
				If vCRRow.ChargingFolio.CreditLimit <> 0 Then
					vCreditLimit = vCRRow.ChargingFolio.CreditLimit;
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vCreditLimit;
EndFunction // cmGetDefaultCreditLimit

// -----------------------------------------------------------------------------
// Description: Returns value list of customer account documents for guest group
// Parameters: Guest group reference
// Return value: ValueList with document references
// -----------------------------------------------------------------------------
Function cmGetGuestGroupAccountingDocuments(pGuestGroup) Export
	vDocsList = New ValueList();
	vQry = New Query();
	vQry.Text = "SELECT
	            |	CustomerDocs.Ref AS Ref
	            |FROM
	            |	(SELECT
	            |		CustomerAdvanceDistribution.Ref AS Ref
	            |	FROM
	            |		Document.CustomerAdvanceDistribution AS CustomerAdvanceDistribution
	            |	WHERE
	            |		CustomerAdvanceDistribution.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		CustomerAdvanceDistributionGuestGroups.Ref
	            |	FROM
	            |		Document.CustomerAdvanceDistribution.GuestGroups AS CustomerAdvanceDistributionGuestGroups
	            |	WHERE
	            |		CustomerAdvanceDistributionGuestGroups.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		Return.Ref
	            |	FROM
	            |		Document.Return AS Return
	            |	WHERE
	            |		Return.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		Payments.Ref
	            |	FROM
	            |		Document.Payment AS Payments
	            |	WHERE
	            |		Payments.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		CustomerPayments.Ref
	            |	FROM
	            |		Document.CustomerPayment AS CustomerPayments
	            |	WHERE
	            |		CustomerPayments.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		CustomerPaymentContracts.Ref
	            |	FROM
	            |		Document.CustomerPayment.Contracts AS CustomerPaymentContracts
	            |	WHERE
	            |		CustomerPaymentContracts.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		DebitNote.Ref
	            |	FROM
	            |		Document.DebitNote AS DebitNote
	            |	WHERE
	            |		DebitNote.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		DebitNoteInvoices.Ref
	            |	FROM
	            |		Document.DebitNote.Invoices AS DebitNoteInvoices
	            |	WHERE
	            |		DebitNoteInvoices.Invoice.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		CreditNote.Ref
	            |	FROM
	            |		Document.CreditNote AS CreditNote
	            |	WHERE
	            |		CreditNote.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		CreditNoteInvoices.Ref
	            |	FROM
	            |		Document.CreditNote.Invoices AS CreditNoteInvoices
	            |	WHERE
	            |		CreditNoteInvoices.Invoice.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		Settlement.Ref
	            |	FROM
	            |		Document.Settlement AS Settlement
	            |	WHERE
	            |		Settlement.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		SettlementServices.Ref
	            |	FROM
	            |		Document.Settlement.Services AS SettlementServices
	            |	WHERE
	            |		SettlementServices.GuestGroup = &qGuestGroup) AS CustomerDocs
	            |
	            |GROUP BY
	            |	CustomerDocs.Ref";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocsList.Add(vDocsRow.Ref);
	EndDo;
	Return vDocsList;
EndFunction // cmGetGuestGroupAccountingDocuments

// -----------------------------------------------------------------------------
// Description: Returns value list of proforma invoices for guest group
// Parameters: Guest group reference
// Return value: ValueList with proforma invoice references
// -----------------------------------------------------------------------------
Function cmGetGuestGroupProformaInvoices(pGuestGroup) Export
	vDocsList = New ValueList();
	vQry = New Query();
	vQry.Text = "SELECT DISTINCT
	            |	Invoices.Ref AS Ref
	            |FROM
	            |	(SELECT
	            |		Invoice.Ref AS Ref
	            |	FROM
	            |		Document.ProformaInvoice AS Invoice
	            |	WHERE
	            |		Invoice.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		InvoiceServices.Ref
	            |	FROM
	            |		Document.ProformaInvoice.Services AS InvoiceServices
	            |	WHERE
	            |		InvoiceServices.GuestGroup = &qGuestGroup) AS Invoices
	            |
	            |GROUP BY
	            |	Invoices.Ref";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocsList.Add(vDocsRow.Ref);
	EndDo;
	Return vDocsList;
EndFunction // cmGetGuestGroupProformaInvoices

// -----------------------------------------------------------------------------
// Description: Returns value list of invoices for guest group
// Parameters: Guest group reference
// Return value: ValueList with settlement invoice references
// -----------------------------------------------------------------------------
Function cmGetGuestGroupInvoices(pGuestGroup) Export
	vDocsList = New ValueList();
	vQry = New Query();
	vQry.Text = "SELECT DISTINCT
	            |	Invoices.Ref AS Ref
	            |FROM
	            |	(SELECT
	            |		Invoice.Ref AS Ref
	            |	FROM
	            |		Document.Settlement AS Invoice
	            |	WHERE
	            |		Invoice.GuestGroup = &qGuestGroup
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		InvoiceServices.Ref
	            |	FROM
	            |		Document.Settlement.Services AS InvoiceServices
	            |	WHERE
	            |		InvoiceServices.GuestGroup = &qGuestGroup) AS Invoices
	            |
	            |GROUP BY
	            |	Invoices.Ref";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocsList.Add(vDocsRow.Ref);
	EndDo;
	Return vDocsList;
EndFunction // cmGetGuestGroupInvoices

// -----------------------------------------------------------------------------
// Description: Returns if this charge is closed by settllement. 
//              It is so if both SumBalance And QuantityBalance columns of the returned row are zero
// Parameters: Charge document reference
// Return value: Value table row with SumBalance and QuantityBalance fields
// -----------------------------------------------------------------------------
Function cmGetChargeCurrentAccountsReceivableBalance(pCharge) Export
	vChargeBalancesRow = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentAccountsReceivableBalance.Charge AS Charge,
	|	CurrentAccountsReceivableBalance.SumBalance AS SumBalance,
	|	CurrentAccountsReceivableBalance.QuantityBalance AS QuantityBalance
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Balance(&qEmptyDate, Charge = &qCharge) AS CurrentAccountsReceivableBalance";
	vQry.SetParameter("qCharge", pCharge);
	vQry.SetParameter("qEmptyDate", '00010101');
	vChargeBalances = vQry.Execute().Unload();
	If vChargeBalances.Count() > 0 Then
		vChargeBalancesRow = vChargeBalances.Get(0);
	EndIf;
	Return vChargeBalancesRow;
EndFunction // cmGetChargeCurrentAccountsReceivableBalance 

// -----------------------------------------------------------------------------
// Description: Returns if this charge is in closed day. 
//              It is so if for charge company and hotel there is close of period 
//              document with date greater or equal charge date
// Parameters: Charge document reference
// Return value: True or False
// -----------------------------------------------------------------------------
Function cmIfChargeIsInClosedDay(pDoc) Export
	vHotel = pDoc.Hotel;
	If ValueIsFilled(vHotel) And vHotel.DoNotEditClosedDateDocs Then
		vHotelAccountingDate = vHotel.AccountingDate;
		If Not ValueIsFilled(vHotelAccountingDate) Then
			vHotelAccountingDate = BegOfDay(CurrentSessionDate());
		EndIf;
		If pDoc.Date < vHotelAccountingDate Then
			Return True;
		Else
			Return False;
		EndIf;
	Else 
		Return False;
	EndIf;
EndFunction // cmIfChargeIsInClosedDay

// -----------------------------------------------------------------------------
Function cmIfChargeIsCanceled(pCharge, rStorno = Undefined) Export
	vCanceled = False;
	rStorno = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Storno.Ref AS Ref
	|FROM
	|	Document.Storno AS Storno
	|WHERE
	|	Storno.Posted
	|	AND (Storno.ParentCharge = &qCharge
	|			OR &qRoomRevenueChargeIsFilled
	|				AND Storno.ParentCharge = &qRoomRevenueCharge)
	|
	|ORDER BY
	|	Storno.PointInTime";
	vQry.SetParameter("qCharge", pCharge);
	vQry.SetParameter("qRoomRevenueCharge", pCharge.RoomRevenueCharge);
	vQry.SetParameter("qRoomRevenueChargeIsFilled", ValueIsFilled(pCharge.RoomRevenueCharge) And pCharge.IsMergedToRoomRevenue);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vCanceled = True;
		rStorno = vDocs.Get(0).Ref;
	EndIf;
	Return vCanceled;
EndFunction // cmIfChargeIsCanceled

// -----------------------------------------------------------------------------
// Description: Returns if this document charges are closed by settllements. 
//              It is so if both SumBalance And QuantityBalance columns of the returned row are zero
// Parameters: Accommodation/Reservation/Resource reservation document reference
// Return value: Value table row with SumBalance and QuantityBalance fields
// -----------------------------------------------------------------------------
Function cmGetDocumentCurrentAccountsReceivableBalance(pParentDoc) Export
	vDocBalancesRow = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentAccountsReceivableBalance.Charge.ParentDoc AS ParentDoc,
	|	SUM(CurrentAccountsReceivableBalance.SumBalance) AS SumBalance,
	|	SUM(CurrentAccountsReceivableBalance.QuantityBalance) AS QuantityBalance
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Balance(&qEmptyDate, Charge.ParentDoc = &qParentDoc) AS CurrentAccountsReceivableBalance
	|
	|GROUP BY
	|	CurrentAccountsReceivableBalance.Charge.ParentDoc";
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qEmptyDate", '00010101');
	vDocBalances = vQry.Execute().Unload();
	If vDocBalances.Count() > 0 Then
		vDocBalancesRow = vDocBalances.Get(0);
	EndIf;
	Return vDocBalancesRow;
EndFunction // cmGetDocumentCurrentAccountsReceivableBalance

// -----------------------------------------------------------------------------
// Description: Returns if this room service document charges are closed by settllements. 
//              It is so if both SumBalance And QuantityBalance columns of the returned row are zero
// Parameters: Record phone call or Record roomservice document references
// Return value: Value table row with SumBalance and QuantityBalance fields
// -----------------------------------------------------------------------------
Function cmGetRoomServiceDocumentCurrentAccountsReceivableBalance(pParentDoc) Export
	vDocBalancesRow = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentAccountsReceivableBalance.Charge.ParentDoc AS ParentDoc,
	|	SUM(CurrentAccountsReceivableBalance.SumBalance) AS SumBalance,
	|	SUM(CurrentAccountsReceivableBalance.QuantityBalance) AS QuantityBalance
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Balance(&qEmptyDate, Charge.ParentRoomService = &qParentDoc) AS CurrentAccountsReceivableBalance
	|
	|GROUP BY
	|	CurrentAccountsReceivableBalance.Charge.ParentDoc";
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qEmptyDate", '00010101');
	vDocBalances = vQry.Execute().Unload();
	If vDocBalances.Count() > 0 Then
		vDocBalancesRow = vDocBalances.Get(0);
	EndIf;
	Return vDocBalancesRow;
EndFunction // cmGetRoomServiceDocumentCurrentAccountsReceivableBalance

// -----------------------------------------------------------------------------
// Description: Returns table of price tag ranges valid for the date and type specified
// Parameters: Hotel reference, price tag type enum reference, accounting date
// Return value: Value table with rows from the PriceTagRanges information register 
// -----------------------------------------------------------------------------
Function cmGetPriceTagRanges(pHotel, pPriceTagType, pPriceCalculationDate = Undefined, pReUse = False) Export 
	If pReUse Then
		Return CachedSettings.cmGetPriceTagRangesReUse(pHotel, pPriceTagType, pPriceCalculationDate);
	Else 
		vPriceCalculationDate = pPriceCalculationDate;
		If pPriceCalculationDate = Undefined Then
			vPriceCalculationDate = CurrentSessionDate();
		EndIf;
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	PriceTagsSliceLast.SetPriceTagRanges AS SetPriceTagRanges
		|INTO ActiveOrders
		|FROM
		|	InformationRegister.PriceTags.SliceLast(
		|			&qPriceCalculationDate,
		|			Hotel = &qHotel
		|				AND PriceTagType = &qPriceTagType) AS PriceTagsSliceLast
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PriceTagRanges.StartValue AS StartValue,
		|	PriceTagRanges.EndValue AS EndValue,
		|	PriceTagRanges.PriceTag AS PriceTag,
		|	PriceTagRanges.SetPriceTagRanges.EndValueNotIncluded AS EndValueNotIncluded
		|FROM
		|	InformationRegister.PriceTagRanges AS PriceTagRanges
		|WHERE
		|	PriceTagRanges.Hotel = &qHotel
		|	AND PriceTagRanges.PriceTagType = &qPriceTagType
		|	AND PriceTagRanges.SetPriceTagRanges IN
		|			(SELECT
		|				ActiveOrders.SetPriceTagRanges
		|			FROM
		|				ActiveOrders AS ActiveOrders)
		|
		|ORDER BY
		|	StartValue,
		|	EndValue";
		vQry.SetParameter("qPriceCalculationDate", vPriceCalculationDate);	
		vQry.SetParameter("qHotel", pHotel);	
		vQry.SetParameter("qPriceTagType", pPriceTagType);	  
		Return vQry.Execute().Unload();
	EndIf;
EndFunction // cmGetPriceTagRanges

// -----------------------------------------------------------------------------
// Description: Returns table of occuancy percent values for each date from the period specified
// Parameters: Hotel, Period from as date, Period to as date
// Return value: Value table with rows of accounting date and occupancy percent
// -----------------------------------------------------------------------------
Function cmFillOccupationPercents(pHotel, pPeriodFrom, pPeriodTo, pReUse = False) Export   
	If pReUse Then
		Return CachedSettings.cmFillOccupationPercentsReUse(pHotel, pPeriodFrom, pPeriodTo);
	Else
		vOccupationPercents = New ValueTable();
		vOccupationPercents.Columns.Add("AccountingDate", cmGetDateTypeDescription());
		vOccupationPercents.Columns.Add("OccupationPercent", cmGetNumberTypeDescription(19, 7));
		// Fill occupation percents
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	TotalRooms.Period AS Period,
		|	ISNULL(TotalRooms.CounterClosingBalance, 0) AS CounterClosingBalance,
		|	ISNULL(TotalRooms.TotalRoomsClosingBalance, 0) AS TotalRooms,
		|	-ISNULL(TotalRooms.RoomsBlockedClosingBalance, 0) AS TotalRoomsBlocked,
		|	ISNULL(RoomSales.RoomsRented, 0) AS RoomsRented
		|FROM
		|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel = &qHotel) AS TotalRooms
		|		LEFT JOIN (SELECT
		|			RoomSalesTurnovers.Period AS Period,
		|			SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRented
		|		FROM
		|			(SELECT
		|				RoomSales.Period AS Period,
		|				RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
		|				0 AS CounterClosingBalance
		|			FROM
		|				AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Day, Hotel = &qHotel) AS RoomSales
		|			
		|			UNION ALL
		|			
		|			SELECT
		|				RoomSalesForecast.Period,
		|				RoomSalesForecast.RoomsRentedTurnover,
		|				0
		|			FROM
		|				AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, &qForecastPeriodTo, Day, Hotel = &qHotel) AS RoomSalesForecast
		|			
		|			UNION ALL
		|			
		|			SELECT
		|				CommitmentBlocks.Period,
		|				CommitmentBlocks.RoomsRemainsClosingBalance,
		|				CommitmentBlocks.CounterClosingBalance
		|			FROM
		|				AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
		|						&qPeriodFrom,
		|						&qPeriodTo,
		|						Day,
		|						RegisterRecordsAndPeriodBoundaries,
		|						Hotel = &qHotel
		|							AND RoomQuota.IsCommitment) AS CommitmentBlocks) AS RoomSalesTurnovers
		|		
		|		GROUP BY
		|			RoomSalesTurnovers.Period) AS RoomSales
		|		ON TotalRooms.Period = RoomSales.Period
		|
		|ORDER BY
		|	Period";
		vQry.SetParameter("qHotel", pHotel);
		vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
		vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
		vForecastStartDate = tcOnServer.GetForecastStartDate(pHotel);
		vQry.SetParameter("qForecastPeriodFrom", Max(BegOfDay(pPeriodFrom), vForecastStartDate));
		vQry.SetParameter("qForecastPeriodTo", Max(EndOfDay(pPeriodTo), EndOfDay(vForecastStartDate - 24 * 3600)));
		vDays = vQry.Execute().Unload();
		For Each vDaysRow In vDays Do
			vAccountingDate = BegOfDay(vDaysRow.Period);
			vOPRow = vOccupationPercents.Find(vAccountingDate, "AccountingDate");
			If vOPRow = Undefined Then
				vOPRow = vOccupationPercents.Add();
				vOPRow.AccountingDate = vAccountingDate;
				If vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked <> 0 Then
					vOPRow.OccupationPercent = Round(100 * vDaysRow.RoomsRented / (vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked), 2);
				Else
					vOPRow.OccupationPercent = 0;
				EndIf;
			EndIf;
		EndDo;   
	Return vOccupationPercents;	
	EndIf;
EndFunction // cmFillOccupationPercents

// -----------------------------------------------------------------------------
// Description: Returns table of occuancy percent values for each date from the 
//              period specified and for each room type
// Parameters: Hotel, Period from as date, Period to as date
// Return value: Value table with rows of accounting date, room type and occupancy percent
// -----------------------------------------------------------------------------
Function cmFillOccupationPercentsPerRoomType(pHotel, pRoomType, pPeriodFrom, pPeriodTo) Export
	vOccupationPercents = New ValueTable();
	vOccupationPercents.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vOccupationPercents.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vOccupationPercents.Columns.Add("OccupationPercent", cmGetNumberTypeDescription(19, 7));
	// Check room type parameter
	vRoomTypeIsEmpty = False;
	vRoomTypesList = New ValueList();
	If TypeOf(pRoomType) = Type("ValueList") Then
		vRoomTypesList = pRoomType;
	ElsIf ValueIsFilled(pRoomType) Then
		If pRoomType.IsFolder Then
			vRoomTypes = cmGetAllRoomTypes(pHotel, pRoomType);
			For Each vRoomTypesRow In vRoomTypes Do
				vRoomTypesList.Add(vRoomTypesRow.RoomType);
			EndDo;
		Else
			vRoomTypesList.Add(pRoomType);
		EndIf;
	Else
		vRoomTypeIsEmpty = True;
	EndIf;
	// Fill occupation percents
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	TotalRooms.Period AS Period,
	|	TotalRooms.RoomType AS RoomType,
	|	TotalRooms.RoomType.SortCode AS RoomTypeSortCode,
	|	ISNULL(TotalRooms.CounterClosingBalance, 0) AS CounterClosingBalance,
	|	ISNULL(TotalRooms.TotalRoomsClosingBalance, 0) AS TotalRooms,
	|	-ISNULL(TotalRooms.RoomsBlockedClosingBalance, 0) AS TotalRoomsBlocked,
	|	ISNULL(RoomSales.RoomsRented, 0) AS RoomsRented
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel = &qHotel
	|				AND (RoomType IN (&qRoomTypesList)
	|					OR &qRoomTypeIsEmpty)
	|				AND NOT RoomType.DeletionMark) AS TotalRooms
	|		LEFT JOIN (SELECT
	|			RoomSalesTurnovers.Period AS Period,
	|			RoomSalesTurnovers.RoomType AS RoomType,
	|			SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRented
	|		FROM
	|			(SELECT
	|				RoomSales.Period AS Period,
	|				RoomSales.RoomType AS RoomType,
	|				RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
	|				0 AS CounterClosingBalance
	|			FROM
	|				AccumulationRegister.Sales.Turnovers(
	|						&qPeriodFrom,
	|						&qPeriodTo,
	|						Day,
	|						Hotel = &qHotel
	|							AND (RoomType IN (&qRoomTypesList)
	|								OR &qRoomTypeIsEmpty)
	|							AND NOT RoomType.DeletionMark) AS RoomSales
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				RoomSalesForecast.Period,
	|				RoomSalesForecast.RoomType,
	|				RoomSalesForecast.RoomsRentedTurnover,
	|				0
	|			FROM
	|				AccumulationRegister.SalesForecast.Turnovers(
	|						&qForecastPeriodFrom,
	|						&qForecastPeriodTo,
	|						Day,
	|						Hotel = &qHotel
	|							AND (RoomType IN (&qRoomTypesList)
	|								OR &qRoomTypeIsEmpty)
	|							AND NOT RoomType.DeletionMark) AS RoomSalesForecast
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				CommitmentBlocks.Period,
	|				CommitmentBlocks.RoomType,
	|				CommitmentBlocks.RoomsRemainsClosingBalance,
	|				CommitmentBlocks.CounterClosingBalance
	|			FROM
	|				AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|						&qPeriodFrom,
	|						&qPeriodTo,
	|						Day,
	|						RegisterRecordsAndPeriodBoundaries,
	|						Hotel = &qHotel
	|							AND (RoomType IN (&qRoomTypesList)
	|								OR &qRoomTypeIsEmpty)
	|							AND NOT RoomType.DeletionMark
	|							AND RoomQuota.IsCommitment) AS CommitmentBlocks) AS RoomSalesTurnovers
	|		
	|		GROUP BY
	|			RoomSalesTurnovers.Period,
	|			RoomSalesTurnovers.RoomType) AS RoomSales
	|		ON TotalRooms.Period = RoomSales.Period
	|			AND TotalRooms.RoomType = RoomSales.RoomType
	|
	|ORDER BY
	|	Period,
	|	RoomTypeSortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomTypesList", vRoomTypesList);
	vQry.SetParameter("qRoomTypeIsEmpty", vRoomTypeIsEmpty);
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
	vForecastStartDate = tcOnServer.GetForecastStartDate(pHotel);
	vQry.SetParameter("qForecastPeriodFrom", Max(BegOfDay(pPeriodFrom), BegOfDay(vForecastStartDate)));
	vQry.SetParameter("qForecastPeriodTo", Max(EndOfDay(pPeriodTo), EndOfDay(vForecastStartDate-24*3600)));
	vDays = vQry.Execute().Unload();
	For Each vDaysRow In vDays Do
		vAccountingDate = BegOfDay(vDaysRow.Period);
		vOPRows = vOccupationPercents.FindRows(New Structure("AccountingDate, RoomType", vAccountingDate, vDaysRow.RoomType));
		If vOPRows.Count() = 0 Then
			vOPRow = vOccupationPercents.Add();
			vOPRow.AccountingDate = vAccountingDate;
			vOPRow.RoomType = vDaysRow.RoomType;
			If vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked <> 0 Then
				vOPRow.OccupationPercent = Round(100 * vDaysRow.RoomsRented / (vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked), 2);
			Else
				vOPRow.OccupationPercent = 0;
			EndIf;
		EndIf;
	EndDo;
	Return vOccupationPercents;
EndFunction // cmFillOccupationPercentsPerRoomType

// -----------------------------------------------------------------------------
// Description: Returns table of occuancy percent values for each date from the 
//              period specified and for each room class
// Parameters: Hotel, Period from as date, Period to as date
// Return value: Value table with rows of accounting date, room type and occupancy percent
// -----------------------------------------------------------------------------
Function cmFillOccupationPercentsPerRoomClass(pHotel, pRoomType, pPeriodFrom, pPeriodTo) Export
	vOccupationPercents = New ValueTable();
	vOccupationPercents.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vOccupationPercents.Columns.Add("RoomClass", cmGetCatalogTypeDescription("RoomTypeClasses"));
	vOccupationPercents.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vOccupationPercents.Columns.Add("OccupationPercent", cmGetNumberTypeDescription(19, 7));
	// Check room type parameter
	vRoomTypeIsEmpty = False;
	vRoomTypesList = New ValueList();
	vRoomClassesList = New ValueList();
	If TypeOf(pRoomType) = Type("ValueList") Then
		vRoomTypesList = pRoomType;
	ElsIf ValueIsFilled(pRoomType) Then
		If pRoomType.IsFolder Then
			vRoomTypes = cmGetAllRoomTypes(pHotel, pRoomType);
			For Each vRoomTypesRow In vRoomTypes Do
				vRoomTypesList.Add(vRoomTypesRow.RoomType);
			EndDo;
		Else
			vRoomTypesList.Add(pRoomType);
		EndIf;
	Else
		vRoomTypeIsEmpty = True;
	EndIf;
	If vRoomTypesList.Count() > 0 Then
		For Each vRoomTypesListItem In vRoomTypesList Do
			vRT = vRoomTypesListItem.Value;
			If vRoomClassesList.FindByValue(vRT.RoomClass) = Undefined Then
				vRoomClassesList.Add(vRT.RoomClass);
			EndIf;
		EndDo;
	EndIf;
	// Fill occupation percents
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.Period AS Period,
	|	RoomSalesTurnovers.RoomType AS RoomType,
	|	SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRented
	|INTO RoomSales
	|FROM
	|	(SELECT
	|		RoomSales.Period AS Period,
	|		RoomSales.RoomType AS RoomType,
	|		RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
	|		0 AS CounterClosingBalance
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				Hotel = &qHotel
	|					AND (RoomType.RoomClass IN (&qRoomClassesList)
	|						OR &qRoomTypeIsEmpty)
	|					AND NOT RoomType.DeletionMark) AS RoomSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RoomSalesForecast.Period,
	|		RoomSalesForecast.RoomType,
	|		RoomSalesForecast.RoomsRentedTurnover,
	|		0
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Day,
	|				Hotel = &qHotel
	|					AND (RoomType.RoomClass IN (&qRoomClassesList)
	|						OR &qRoomTypeIsEmpty)
	|					AND NOT RoomType.DeletionMark) AS RoomSalesForecast
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CommitmentBlocks.Period,
	|		CommitmentBlocks.RoomType,
	|		CommitmentBlocks.RoomsRemainsClosingBalance,
	|		CommitmentBlocks.CounterClosingBalance
	|	FROM
	|		AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Day,
	|				RegisterRecordsAndPeriodBoundaries,
	|				Hotel = &qHotel
	|					AND (RoomType.RoomClass IN HIERARCHY (&qRoomClassesList)
	|						OR &qRoomTypeIsEmpty)
	|					AND NOT RoomType.DeletionMark
	|					AND RoomQuota.IsCommitment) AS CommitmentBlocks) AS RoomSalesTurnovers
	|
	|GROUP BY
	|	RoomSalesTurnovers.Period,
	|	RoomSalesTurnovers.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalRooms.Period AS Period,
	|	TotalRooms.RoomType AS RoomType,
	|	TotalRooms.RoomType.RoomClass AS RoomClass,
	|	ISNULL(TotalRooms.CounterClosingBalance, 0) AS CounterClosingBalance,
	|	ISNULL(TotalRooms.TotalRoomsClosingBalance, 0) AS TotalRooms,
	|	-ISNULL(TotalRooms.RoomsBlockedClosingBalance, 0) AS TotalRoomsBlocked,
	|	ISNULL(RoomSales.RoomsRented, 0) AS RoomsRented
	|INTO TotalRoomsByRoomTypes
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel = &qHotel
	|				AND (RoomType.RoomClass IN (&qRoomClassesList)
	|					OR &qRoomTypeIsEmpty)
	|				AND NOT RoomType.DeletionMark) AS TotalRooms
	|		LEFT JOIN RoomSales AS RoomSales
	|		ON TotalRooms.Period = RoomSales.Period
	|			AND TotalRooms.RoomType = RoomSales.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalRoomsByRoomTypes.Period AS Period,
	|	TotalRoomsByRoomTypes.RoomClass AS RoomClass,
	|	ISNULL(TotalRoomsByRoomTypes.RoomClass.SortCode, 999999999) AS RoomClassSortCode,
	|	SUM(TotalRoomsByRoomTypes.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(TotalRoomsByRoomTypes.TotalRooms) AS TotalRooms,
	|	SUM(TotalRoomsByRoomTypes.TotalRoomsBlocked) AS TotalRoomsBlocked,
	|	SUM(TotalRoomsByRoomTypes.RoomsRented) AS RoomsRented
	|INTO TotalsByRoomClasses
	|FROM
	|	TotalRoomsByRoomTypes AS TotalRoomsByRoomTypes
	|
	|GROUP BY
	|	TotalRoomsByRoomTypes.Period,
	|	TotalRoomsByRoomTypes.RoomClass,
	|	ISNULL(TotalRoomsByRoomTypes.RoomClass.SortCode, 999999999)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllRoomTypes.Ref AS RoomType,
	|	AllRoomTypes.SortCode AS RoomTypeSortCode,
	|	ISNULL(TotalsByRoomClasses.Period, &qEmptyDate) AS Period,
	|	ISNULL(TotalsByRoomClasses.RoomClass, VALUE(Catalog.RoomTypeClasses.EmptyRef)) AS RoomClass,
	|	ISNULL(TotalsByRoomClasses.RoomClassSortCode, 999999999) AS RoomClassSortCode,
	|	ISNULL(TotalsByRoomClasses.CounterClosingBalance, 0) AS CounterClosingBalance,
	|	ISNULL(TotalsByRoomClasses.TotalRooms, 0) AS TotalRooms,
	|	ISNULL(TotalsByRoomClasses.TotalRoomsBlocked, 0) AS TotalRoomsBlocked,
	|	ISNULL(TotalsByRoomClasses.RoomsRented, 0) AS RoomsRented
	|FROM
	|	Catalog.RoomTypes AS AllRoomTypes
	|		LEFT JOIN TotalsByRoomClasses AS TotalsByRoomClasses
	|		ON AllRoomTypes.RoomClass = TotalsByRoomClasses.RoomClass
	|WHERE
	|	AllRoomTypes.Owner = &qHotel
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND AllRoomTypes.Ref IN (&qRoomTypesList))
	|	AND NOT AllRoomTypes.DeletionMark
	|	AND NOT AllRoomTypes.IsFolder
	|	AND NOT AllRoomTypes.IsVirtual
	|
	|ORDER BY
	|	Period,
	|	RoomClassSortCode,
	|	RoomTypeSortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomTypesList", vRoomTypesList);
	vQry.SetParameter("qRoomTypeIsEmpty", vRoomTypeIsEmpty);
	vQry.SetParameter("qRoomClassesList", vRoomClassesList);
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
	vForecastStartDate = tcOnServer.GetForecastStartDate(pHotel);
	vQry.SetParameter("qForecastPeriodFrom", Max(BegOfDay(pPeriodFrom), BegOfDay(vForecastStartDate)));
	vQry.SetParameter("qForecastPeriodTo", Max(EndOfDay(pPeriodTo), EndOfDay(vForecastStartDate-24*3600)));
	vQry.SetParameter("qEmptyDate", '00010101');
	vDays = vQry.Execute().Unload();
	For Each vDaysRow In vDays Do
		If ValueIsFilled(vDaysRow.Period) Then
			vAccountingDate = BegOfDay(vDaysRow.Period);
			vOPRows = vOccupationPercents.FindRows(New Structure("AccountingDate, RoomType", vAccountingDate, vDaysRow.RoomType));
			If vOPRows.Count() = 0 Then
				vOPRow = vOccupationPercents.Add();
				vOPRow.AccountingDate = vAccountingDate;
				vOPRow.RoomClass = vDaysRow.RoomClass;
				vOPRow.RoomType = vDaysRow.RoomType;
				If vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked <> 0 Then
					vOPRow.OccupationPercent = Round(100 * vDaysRow.RoomsRented / (vDaysRow.TotalRooms - vDaysRow.TotalRoomsBlocked), 2);
				Else
					vOPRow.OccupationPercent = 0;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	Return vOccupationPercents;
EndFunction // cmFillOccupationPercentsPerRoomClass

// -----------------------------------------------------------------------------
// Description: Returns table of occuancy percent values for each date from the 
//              period specified and for each room type and day type
// Parameters: Hotel, Period from as date, Period to as date
// Return value: Value table with rows of accounting date, room type and occupancy percent
// -----------------------------------------------------------------------------
Function cmFillOccupationPercentsPerRoomTypePerDayType(pHotel, pRoomType, pPeriodFrom, pPeriodTo, pRoomRate, pPriceCalculationDate = '00010101') Export
	vOccupationPercents = New ValueTable();
	vOccupationPercents.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vOccupationPercents.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vOccupationPercents.Columns.Add("OccupationPercent", cmGetNumberTypeDescription(19, 7));
	// Check room type parameter
	vRoomTypeIsEmpty = False;
	vRoomTypesList = New ValueList();
	If TypeOf(pRoomType) = Type("ValueList") Then
		vRoomTypesList = pRoomType;
	ElsIf ValueIsFilled(pRoomType) Then
		If pRoomType.IsFolder Then
			vRoomTypes = cmGetAllRoomTypes(pHotel, pRoomType);
			For Each vRoomTypesRow In vRoomTypes Do
				vRoomTypesList.Add(vRoomTypesRow.RoomType);
			EndDo;
		Else
			vRoomTypesList.Add(pRoomType);
		EndIf;
	Else
		vRoomTypeIsEmpty = True;
	EndIf;
	// Fill occupation percents
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|			THEN CalendarDays.CalendarDayType
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|			THEN CalendarDays.CalendarDayType
	|		ELSE CalendarDaysByRoomTypes.CalendarDayType
	|	END AS DayType,
	|	CASE
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|			THEN CalendarDays.CalendarDayType.SortCode
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|			THEN CalendarDays.CalendarDayType.SortCode
	|		ELSE CalendarDaysByRoomTypes.CalendarDayType.SortCode
	|	END AS DayTypeSortCode
	|INTO CalendarDayTypes
	|FROM
	|	InformationRegister.CalendarDays.SliceLast(
	|			&qPriceCalculationDate,
	|			Calendar = &qCalendar
	|				AND AccountingDate >= &qPeriodFrom
	|				AND AccountingDate <= &qPeriodTo) AS CalendarDays
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
	|				&qPriceCalculationDate,
	|					AccountingDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|					AND Calendar = &qCalendar
	|					AND (RoomType IN (&qRoomTypesList)
	|						OR &qRoomTypeIsEmpty)) AS CalendarDaysByRoomTypes
	|		ON CalendarDays.Calendar = CalendarDaysByRoomTypes.Calendar
	|			AND CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
	|WHERE
	|	CalendarDays.Calendar = &qCalendar
	|	AND CalendarDays.AccountingDate >= &qPeriodFrom
	|	AND CalendarDays.AccountingDate <= &qPeriodTo
	|
	|GROUP BY
	|	CASE
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|			THEN CalendarDays.CalendarDayType
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|			THEN CalendarDays.CalendarDayType
	|		ELSE CalendarDaysByRoomTypes.CalendarDayType
	|	END,
	|	CASE
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|			THEN CalendarDays.CalendarDayType.SortCode
	|		WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|			THEN CalendarDays.CalendarDayType.SortCode
	|		ELSE CalendarDaysByRoomTypes.CalendarDayType.SortCode
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DayTypesDays.CalendarDayType AS DayType,
	|	MIN(DayTypesDays.AccountingDate) AS MinPeriodFrom,
	|	MAX(DayTypesDays.AccountingDate) AS MaxPeriodTo
	|FROM
	|	InformationRegister.CalendarDays.SliceLast(
	|			&qPriceCalculationDate,
	|			Calendar = &qCalendar
	|				AND AccountingDate >= &qStartPeriodFrom
	|				AND AccountingDate <= &qEndPeriodTo
	|				AND CalendarDayType IN
	|					(SELECT
	|						CalendarDayTypes.DayType
	|					FROM
	|						CalendarDayTypes)) AS DayTypesDays
	|
	|GROUP BY
	|	DayTypesDays.CalendarDayType";
	vQry.SetParameter("qCalendar", ?(ValueIsFilled(pRoomRate), pRoomRate.Calendar, Undefined));
	vQry.SetParameter("qPriceCalculationDate", ?(ValueIsFilled(pPriceCalculationDate), pPriceCalculationDate, CurrentSessionDate()));
	vQry.SetParameter("qStartPeriodFrom", BegOfDay(pPeriodFrom) - 24 * 3600 * 180);
	vQry.SetParameter("qEndPeriodTo", EndOfDay(pPeriodTo) + 24 * 3600 * 180);
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
	vQry.SetParameter("qRoomTypesList", vRoomTypesList);
	vQry.SetParameter("qRoomTypeIsEmpty", vRoomTypeIsEmpty);
	vDayTypes = vQry.Execute().Unload();
	// Do for each day type found
	For Each vDayTypesRow In vDayTypes Do
		vQry.Text = 
		"SELECT
		|	PerDayType.RoomType AS RoomType,
		|	SUM(ISNULL(PerDayType.TotalRooms, 0)) AS TotalRooms,
		|	SUM(ISNULL(PerDayType.TotalRoomsBlocked, 0)) AS TotalRoomsBlocked,
		|	SUM(ISNULL(PerDayType.RoomsRented, 0)) AS RoomsRented
		|FROM
		|	(SELECT
		|		TotalRooms.RoomType AS RoomType,
		|		TotalRooms.Period AS Period,
		|		TotalRooms.CounterClosingBalance AS CounterClosingBalance,
		|		ISNULL(TotalRooms.TotalRoomsClosingBalance, 0) AS TotalRooms,
		|		-ISNULL(TotalRooms.RoomsBlockedClosingBalance, 0) AS TotalRoomsBlocked,
		|		ISNULL(RoomSales.RoomsRented, 0) AS RoomsRented
		|	FROM
		|		AccumulationRegister.RoomInventory.BalanceAndTurnovers(
		|				&qPeriodFrom,
		|				&qPeriodTo,
		|				Day,
		|				RegisterRecordsAndPeriodBoundaries,
		|				Hotel = &qHotel
		|					AND (RoomType IN (&qRoomTypesList)
		|						OR &qRoomTypeIsEmpty)
		|					AND NOT RoomType.DeletionMark) AS TotalRooms
		|			LEFT JOIN (SELECT
		|				RoomSalesTurnovers.RoomType AS RoomType,
		|				RoomSalesTurnovers.Period AS Period,
		|				SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRented
		|			FROM
		|				(SELECT
		|					RoomSales.Period AS Period,
		|					RoomSales.RoomType AS RoomType,
		|					RoomSales.RoomsRentedTurnover AS RoomsRentedTurnover,
		|					0 AS CounterClosingBalance
		|				FROM
		|					AccumulationRegister.Sales.Turnovers(
		|							&qPeriodFrom,
		|							&qPeriodTo,
		|							Day,
		|							Hotel = &qHotel
		|								AND (RoomType IN (&qRoomTypesList)
		|									OR &qRoomTypeIsEmpty)
		|								AND NOT RoomType.DeletionMark) AS RoomSales
		|				
		|				UNION ALL
		|				
		|				SELECT
		|					RoomSalesForecast.Period,
		|					RoomSalesForecast.RoomType,
		|					RoomSalesForecast.RoomsRentedTurnover,
		|					0
		|				FROM
		|					AccumulationRegister.SalesForecast.Turnovers(
		|							&qForecastPeriodFrom,
		|							&qForecastPeriodTo,
		|							Day,
		|							Hotel = &qHotel
		|								AND (RoomType IN (&qRoomTypesList)
		|									OR &qRoomTypeIsEmpty)
		|								AND NOT RoomType.DeletionMark) AS RoomSalesForecast
		|				
		|				UNION ALL
		|				
		|				SELECT
		|					CommitmentBlocks.Period,
		|					CommitmentBlocks.RoomType,
		|					CommitmentBlocks.RoomsRemainsClosingBalance,
		|					CommitmentBlocks.CounterClosingBalance
		|				FROM
		|					AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
		|							&qPeriodFrom,
		|							&qPeriodTo,
		|							Day,
		|							RegisterRecordsAndPeriodBoundaries,
		|							Hotel IN HIERARCHY (&qHotel)
		|								AND (RoomType IN (&qRoomTypesList)
		|									OR &qRoomTypeIsEmpty)
		|								AND NOT RoomType.DeletionMark
		|								AND RoomQuota.IsCommitment) AS CommitmentBlocks) AS RoomSalesTurnovers
		|			
		|			GROUP BY
		|				RoomSalesTurnovers.RoomType,
		|				RoomSalesTurnovers.Period) AS RoomSales
		|			ON TotalRooms.Period = RoomSales.Period
		|				AND TotalRooms.RoomType = RoomSales.RoomType) AS PerDayType
		|
		|GROUP BY
		|	PerDayType.RoomType";
		vQry.SetParameter("qHotel", pHotel);
		vQry.SetParameter("qRoomTypesList", vRoomTypesList);
		vQry.SetParameter("qRoomTypeIsEmpty", vRoomTypeIsEmpty);
		vQry.SetParameter("qPeriodFrom", vDayTypesRow.MinPeriodFrom);
		vQry.SetParameter("qPeriodTo", EndOfDay(vDayTypesRow.MaxPeriodTo));
		vForecastStartDate = tcOnServer.GetForecastStartDate(pHotel);
		vQry.SetParameter("qForecastPeriodFrom", Max(vDayTypesRow.MinPeriodFrom, BegOfDay(vForecastStartDate)));
		vQry.SetParameter("qForecastPeriodTo", Max(EndOfDay(vDayTypesRow.MaxPeriodTo), EndOfDay(vForecastStartDate-24*3600)));
		vStats = vQry.Execute().Unload();
		For Each vStatsRow In vStats Do
			vOccupationPercent = 0;
			If vStatsRow.TotalRooms <> Null And vStatsRow.TotalRoomsBlocked <> Null And vStatsRow.RoomsRented <> Null And 
			  (vStatsRow.TotalRooms - vStatsRow.TotalRoomsBlocked) <> 0 Then
				vOccupationPercent = Round(100*vStatsRow.RoomsRented/(vStatsRow.TotalRooms - vStatsRow.TotalRoomsBlocked), 2);
			EndIf;
			vAccountingDate = Max(vDayTypesRow.MinPeriodFrom, BegOfDay(pPeriodFrom));
			vMaxAccountingDate = Min(vDayTypesRow.MaxPeriodTo, BegOfDay(pPeriodTo));
			While vAccountingDate <= vMaxAccountingDate Do
				vOPRow = vOccupationPercents.Find(vAccountingDate, "AccountingDate");
				If vOPRow = Undefined Then
					vOPRow = vOccupationPercents.Add();
					vOPRow.AccountingDate = vAccountingDate;
					vOPRow.RoomType = vStatsRow.RoomType;
					vOPRow.OccupationPercent = vOccupationPercent;
				EndIf;
				vAccountingDate = vAccountingDate + 24 * 3600;
			EndDo;
		EndDo;
	EndDo;
	Return vOccupationPercents;
EndFunction // cmFillOccupationPercentsPerRoomTypePerDayType

// -----------------------------------------------------------------------------
// Description: Returns gift certificate balance for the given hotel
// Parameters: Hotel, Gift certificate code
// Return value: Gift certificate balance amount
// -----------------------------------------------------------------------------
Function cmGetGiftCertificateBalance(pHotel, pGiftCertificate, pDate) Export
	If IsBlankString(TrimAll(pGiftCertificate)) Then
		Return 0;
	EndIf;
	vGiftCertificatesArePerHotel = Constants.GiftCertificatesArePerHotel.Get();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GiftCertificatesBalance.GiftCertificate,
	|	GiftCertificatesBalance.AmountBalance
	|FROM
	|	AccumulationRegister.GiftCertificatesBalance.Balance(
	|			&qDate,
	|			GiftCertificate = &qGiftCertificate
	|				AND (NOT &qHotelIsFilled
	|					OR &qHotelIsFilled
	|						AND Hotel = &qHotel)) AS GiftCertificatesBalance";
	vQry.SetParameter("qDate", New Boundary(pDate, BoundaryType.Excluding));
	vQry.SetParameter("qGiftCertificate", TrimAll(pGiftCertificate));
	vQry.SetParameter("qHotel", ?(vGiftCertificatesArePerHotel, pHotel, Catalogs.Hotels.EmptyRef()));
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(?(vGiftCertificatesArePerHotel, pHotel, Catalogs.Hotels.EmptyRef())));
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		Return vQryRes.Get(0).AmountBalance;
	Else
		Return 0;
	EndIf;
EndFunction // cmGetGiftCertificateBalance

// -----------------------------------------------------------------------------
// Description: Returns whether gift certificate is blocked or not for the given hotel
// Parameters: Hotel, Gift certificate code, Date to check
// Return value: Boolean true if certificate is blocked, block reason as string
// -----------------------------------------------------------------------------
Function cmGiftCertificateIsBlocked(Val pHotel, pGiftCertificate, pDate, rBlockReason) Export
	rBlockReason = "";
	If IsBlankString(TrimAll(pGiftCertificate)) Then
		Return False;
	EndIf;
	vGiftCertificatesArePerHotel = Constants.GiftCertificatesArePerHotel.Get();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BlockedGiftCertificates.GiftCertificate,
	|	BlockedGiftCertificates.BlockReason,
	|	BlockedGiftCertificates.BlockDate,
	|	BlockedGiftCertificates.BlockAuthor,
	|	BlockedGiftCertificates.Hotel,
	|	BlockedGiftCertificates.Period
	|FROM
	|	InformationRegister.GiftCertificates AS BlockedGiftCertificates
	|WHERE
	|	BlockedGiftCertificates.GiftCertificate = &qGiftCertificate
	|	AND BlockedGiftCertificates.BlockDate <> &qEmptyDate
	|	AND BlockedGiftCertificates.BlockDate <= &qDate
	|	AND (NOT &qHotelIsFilled
	|			OR &qHotelIsFilled
	|				AND BlockedGiftCertificates.Hotel = &qHotel)";
	vQry.SetParameter("qDate", BegOfDay(pDate));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qGiftCertificate", TrimAll(pGiftCertificate));
	vQry.SetParameter("qHotel", ?(vGiftCertificatesArePerHotel, pHotel, Catalogs.Hotels.EmptyRef()));
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(?(vGiftCertificatesArePerHotel, pHotel, Catalogs.Hotels.EmptyRef())));
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		For Each vQryResRow In vQryRes Do
			rBlockReason = TrimAll(vQryResRow.BlockReason);
			Return True;
		EndDo;
		Return False;
	Else
		Return False;
	EndIf;
EndFunction // cmGiftCertificateIsBlocked

// -----------------------------------------------------------------------------
// Description: Returns whether gift certificate was issued
// Parameters: Hotel, Gift certificate code
// Return value: Boolean true if certificate is found, false if not
// -----------------------------------------------------------------------------
Function cmGiftCertificateExists(pHotel, pGiftCertificate) Export
	If IsBlankString(TrimAll(pGiftCertificate)) Then
		Return False;
	EndIf;
	vGiftCertificatesArePerHotel = Constants.GiftCertificatesArePerHotel.Get();
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	GiftCertificates.GiftCertificate,
	|	GiftCertificates.Hotel
	|FROM
	|	AccumulationRegister.GiftCertificatesBalance AS GiftCertificates
	|WHERE
	|	GiftCertificates.GiftCertificate = &qGiftCertificate
	|	AND GiftCertificates.RecordType = &qReceipt
	|	AND (NOT &qHotelIsFilled
	|			OR &qHotelIsFilled
	|				AND GiftCertificates.Hotel = &qHotel)";
	vQry.SetParameter("qGiftCertificate", TrimAll(pGiftCertificate));
	vQry.SetParameter("qHotel", ?(vGiftCertificatesArePerHotel, pHotel, Catalogs.Hotels.EmptyRef()));
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(?(vGiftCertificatesArePerHotel, pHotel, Catalogs.Hotels.EmptyRef())));
	vQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmGiftCertificateExists

// -----------------------------------------------------------------------------
Function cmGetGiftCertificateCharges(pGiftCertificate, pCharge2Skip = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charge.Service AS Service,
	|	Charge.Ref AS Charge,
	|	Charge.GiftCertificate AS GiftCertificate
	|FROM
	|	Document.Charge AS Charge
	|WHERE
	|	Charge.Posted
	|	AND Charge.GiftCertificate = &qGiftCertificate
	|	AND Charge.Service.IsGiftCertificate
	|	AND Charge.GiftCertificate <> &qEmptyString
	|	AND (&qCharge2SkipIsEmpty
	|			OR NOT &qCharge2SkipIsEmpty
	|				AND Charge.Ref <> &qCharge2Skip)
	|
	|GROUP BY
	|	Charge.Service,
	|	Charge.Ref,
	|	Charge.GiftCertificate
	|
	|ORDER BY
	|	GiftCertificate";
	vQry.SetParameter("qGiftCertificate", TrimAll(pGiftCertificate));
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qCharge2SkipIsEmpty", Not ValueIsFilled(pCharge2Skip));
	vQry.SetParameter("qCharge2Skip", pCharge2Skip);
	Return vQry.Execute().Unload();
EndFunction // cmGetGiftCertificateCharges

// -----------------------------------------------------------------------------
// Description: Returns gift certificate data record
// Parameters: Hotel, Gift certificate code
// Return value: Gift certificate record manager object
// -----------------------------------------------------------------------------
Function cmGetGiftCertificateRecordManager(pHotel, pGiftCertificate) Export
	If IsBlankString(TrimAll(pGiftCertificate)) Then
		Return Undefined;
	EndIf;
	vGiftCertificatesArePerHotel = Constants.GiftCertificatesArePerHotel.Get();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.GiftCertificates AS GiftCertificates
	|WHERE
	|	GiftCertificates.GiftCertificate = &qGiftCertificate
	|	AND (NOT &qHotelIsFilled
	|			OR &qHotelIsFilled
	|				AND GiftCertificates.Hotel = &qHotel)";
	vQry.SetParameter("qGiftCertificate", TrimAll(pGiftCertificate));
	vQry.SetParameter("qHotel", ?(vGiftCertificatesArePerHotel, pHotel, Catalogs.Hotels.EmptyRef()));
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(?(vGiftCertificatesArePerHotel, pHotel, Catalogs.Hotels.EmptyRef())));
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vRow = vQryRes.Get(0);
		vRM = InformationRegisters.GiftCertificates.CreateRecordManager();
		vRM.Period = vRow.Period;
		vRM.Hotel = vRow.Hotel;
		vRM.GiftCertificate = vRow.GiftCertificate;
		vRM.Read();
		If vRM.Selected() Then
			Return vRM;
		Else
			Return Undefined;
		EndIf;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetGiftCertificateRecordManager

// -----------------------------------------------------------------------------
// Description: Returns service item output in grams as number
// Parameters: service item output in grams as string
// Return value: service item output in grams as number
// -----------------------------------------------------------------------------
Function cmParseServiceItemOutputString(pOutput) Export
	If IsBlankString(pOutput) Then
		Return 0;
	Else
		vOutputAmount = 0;
		vOutput = TrimAll(pOutput);
		vOutput = StrReplace(vOutput, "\", "/");
		While Not IsBlankString(vOutput) Do
			vSlashPos = Find(vOutput, "/");
			If vSlashPos > 1 Then
				vWord = TrimAll(Left(vOutput, vSlashPos - 1));
				vOutput = TrimAll(Mid(vOutput, vSlashPos + 1)); 
				If cmIsNumber(vWord) Then
					vOutputAmount = vOutputAmount + Number(vWord);
				EndIf;
			Else
				If cmIsNumber(vOutput) Then
					vOutputAmount = vOutputAmount + Number(vOutput);
				EndIf;
				Break;
			EndIf;
		EndDo;
		Return vOutputAmount;
	EndIf;
EndFunction // cmParseServiceItemOutputString

// -----------------------------------------------------------------------------
//  Searches for customer in hotel database by customer from external database
//
// Parameters:
//  pCustomer	 - Structure - Parametrs
// 
// Returns:
//  CatalogRef.Customers - Ref
//
Function cmFindCustomers(pCustomer) Export 
	If pCustomer.Code = "" Then 
		If pCustomer.TIN <> "" Then
			 vCustomer = Catalogs.Customers.FindByAttribute("TIN", pCustomer.TIN);
		 EndIf;	
		 Return ?(ValueIsFilled(vCustomer), vCustomer, Catalogs.Customers.EmptyRef());
	Else	
		// 1. Find by external code
		vCustomer = Catalogs.Customers.FindByAttribute("ExternalCode", pCustomer.Code);
		
		// 2. Find by TIN
		If Not ValueIsFilled(vCustomer) Then
			If pCustomer.TIN <> "" Then
				vCustomer = Catalogs.Customers.FindByAttribute("TIN", pCustomer.TIN);
			EndIf;	
		EndIf;	
		
		If ValueIsFilled(vCustomer) Then
			Return 	vCustomer;
		EndIf;	
		
		// 3. Create new Customer
		vCustomer = Catalogs.Customers.CreateItem();
		
		vCustomer.Description 			= pCustomer.Description;
		vCustomer.LegacyName 			= pCustomer.FullDescription;
		vCustomer.TIN 					= pCustomer.TIN;
		vCustomer.KPP 					= pCustomer.KPP;
		vCustomer.ExternalCode 			= pCustomer.Code;
		vCustomer.PostAddress 			= pCustomer.PostAddress;
		vCustomer.LegacyAddress 		= pCustomer.LegalAddress;
		vCustomer.Phone 				= pCustomer.Phone;
		vCustomer.EMail 				= pCustomer.EMail;
		
		vCustomer.Write();
		
		// 4. Create new BankAccounts
		If ValueIsFilled(pCustomer.BankAccountBIC) And ValueIsFilled(pCustomer.BankAccountNumber) Then
			
			vBankAccounts = Catalogs.BankAccounts.CreateItem();
			
			vBankAccounts.Parent 				= vCustomer;
			vBankAccounts.BankBIC 				= pCustomer.BankAccountBIC;
			vBankAccounts.AccountNumber			= pCustomer.BankAccountNumber;
			vBankAccounts.BankName			 	= pCustomer.BankAccountBankName;
			vBankAccounts.BankCorrAccountNumber	= pCustomer.BankAccountBankCorrAccount;

			vBankAccounts.Write();

		EndIf;
		
		Return ?(ValueIsFilled(vCustomer), vCustomer, Catalogs.Customers.EmptyRef());
	EndIf;	
EndFunction //  FindCustomers()

// -----------------------------------------------------------------------------
// Searches for storned transactions in value table and removes those pares
// -----------------------------------------------------------------------------
Procedure cmRemoveTransactionsWithStorno(pTransactions) Export
	// Group by transactions by charge
	vTransactions = pTransactions.Copy(); 
	For Each vTransactionsRow In vTransactions Do
		If TypeOf(vTransactionsRow.Document) = Type("DocumentRef.Storno") Then
			If vTransactionsRow.Sum < 0 And vTransactionsRow.Quantity > 0 Or 
			   vTransactionsRow.Sum > 0 And vTransactionsRow.Quantity < 0 Then
				vTransactionsRow.Quantity = -vTransactionsRow.Quantity;
			EndIf;
		EndIf;
	EndDo;
	vTransactions.GroupBy("Charge", "Sum, Quantity");
	// Check all transactions in list
	i = 0;
	While i < pTransactions.Count() Do
		vTrnRow = pTransactions.Get(i);
		If ValueIsFilled(vTrnRow.Charge) Then
			vCharge = vTrnRow.Charge;
			vCheckRow = vTransactions.Find(vCharge, "Charge");
			If vCheckRow <> Undefined Then
				If vCheckRow.Sum = 0 And vCheckRow.Quantity = 0 Then
					pTransactions.Delete(i);
					Continue;
				EndIf;
			EndIf;
			If vCharge.IsCorrection And ValueIsFilled(vCharge.CorrectedCharge) Then
				vRows = pTransactions.FindRows(New Structure("Charge", vCharge.CorrectedCharge));
				If vRows.Count() = 1 Then
					vRow = vRows.Get(0);
					vRow.Sum = vRow.Sum + vTrnRow.Sum;
					vRow.VATSum = vRow.VATSum + vTrnRow.VATSum;
					vRow.Price = ?(vRow.Quantity = 0, vRow.Sum, Round(vRow.Sum / vRow.Quantity, 2));
					
					pTransactions.Delete(i);
					Continue;
				EndIf;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
EndProcedure // cmRemoveTransactionsWithStorno

// -----------------------------------------------------------------------------
// Checks room rate - card type bindings for given reservation or accommodation
// Returns card type
// -----------------------------------------------------------------------------
Function cmGetRoomRateBindingsCardType(pDocRef) Export
	vCardType = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRateCardTypeBindings.IdentificationCardType AS IdentificationCardType
	|FROM
	|	InformationRegister.RoomRateCardTypeBindings AS RoomRateCardTypeBindings
	|WHERE
	|	RoomRateCardTypeBindings.RoomRate = &qRoomRate
	|	AND (RoomRateCardTypeBindings.AccommodationType = &qAccommodationType
	|				AND RoomRateCardTypeBindings.AccommodationType <> &qEmptyAccommodationType
	|			OR RoomRateCardTypeBindings.ClientType = &qClientType
	|				AND RoomRateCardTypeBindings.ClientType <> &qEmptyClientType
	|			OR RoomRateCardTypeBindings.CustomerType = &qCustomerType
	|				AND RoomRateCardTypeBindings.CustomerType <> &qEmptyCustomerType
	|			OR RoomRateCardTypeBindings.DiscountType = &qDiscountType
	|				AND RoomRateCardTypeBindings.DiscountType <> &qEmptyDiscountType
	|			OR RoomRateCardTypeBindings.MarketingCode = &qMarketingCode
	|				AND RoomRateCardTypeBindings.MarketingCode <> &qEmptyMarketingCode)
	|
	|ORDER BY
	|	RoomRateCardTypeBindings.IdentificationCardType.SortCode,
	|	RoomRateCardTypeBindings.IdentificationCardType.Description";
	vQry.SetParameter("qRoomRate", pDocRef.RoomRate);
	vQry.SetParameter("qAccommodationType", pDocRef.AccommodationType);
	vQry.SetParameter("qEmptyAccommodationType", Catalogs.AccommodationTypes.EmptyRef());
	vQry.SetParameter("qClientType", pDocRef.ClientType);
	vQry.SetParameter("qEmptyClientType", Catalogs.ClientTypes.EmptyRef());
	vQry.SetParameter("qCustomerType", pDocRef.CustomerType);
	vQry.SetParameter("qEmptyCustomerType", Catalogs.CustomerTypes.EmptyRef());
	vQry.SetParameter("qDiscountType", pDocRef.DiscountType);
	vQry.SetParameter("qEmptyDiscountType", Catalogs.DiscountTypes.EmptyRef());
	vQry.SetParameter("qMarketingCode", pDocRef.MarketingCode);
	vQry.SetParameter("qEmptyMarketingCode", Catalogs.MarketingCodes.EmptyRef());
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vCardType = vQryRes.Get(0).IdentificationCardType;
	EndIf;
	Return vCardType;
EndFunction // cmGetRoomRateBindingsCardType

// -----------------------------------------------------------------------------
// Retrieves room rate restrictions for the given date 
// Returns structure
// -----------------------------------------------------------------------------
Function cmGetRoomRateRestrictions(pHotel, pRoomRate, pPeriod, pRoomType, pWithoutOnline = False, pShowTurnedOff = False) Export
	vRestrStruct = New Structure("StopSale, MLOS, MaxLOS, MinDaysBeforeCheckIn, MaxDaysBeforeCheckIn, CTA, CTD", False, 0, 0, 0, 0, False, False);
	If Not ValueIsFilled(pPeriod) Or Not ValueIsFilled(pRoomRate) Then
		Return vRestrStruct;
	EndIf;
	// Get week days
	vDayOfWeek = WeekDay(pPeriod);
	// Get accounting dates
	vAccountingDate = BegOfDay(pPeriod);
	// Try to get calendar day type for the check-in date
	vCalendarDayType = cmGetCalendarDayType(pRoomRate, vAccountingDate, Undefined, Undefined, Undefined, pRoomType);
	// Run query to search for restriction records
	vQry = New Query();
	vQry.Text = "SELECT
	            |	RoomRateRestrictions.Hotel AS Hotel,
	            |	RoomRateRestrictions.RoomRate AS RoomRate,
	            |	RoomRateRestrictions.RoomType AS RoomType,
	            |	RoomRateRestrictions.CalendarDayType AS CalendarDayType,
	            |	RoomRateRestrictions.DayOfWeek AS DayOfWeek,
	            |	RoomRateRestrictions.AccountingDate AS AccountingDate,
	            |	RoomRateRestrictions.StopSale AS StopSale,
	            |	RoomRateRestrictions.MLOS AS MLOS,
	            |	RoomRateRestrictions.MaxLOS AS MaxLOS,
	            |	RoomRateRestrictions.CTA AS CTA,
	            |	RoomRateRestrictions.CTD AS CTD,
	            |	RoomRateRestrictions.MinDaysBeforeCheckIn AS MinDaysBeforeCheckIn,
	            |	RoomRateRestrictions.MaxDaysBeforeCheckIn AS MaxDaysBeforeCheckIn,
	            |	RoomRateRestrictions.IsForOnlineOnly AS IsForOnlineOnly
	            |FROM
	            |	InformationRegister.RoomRateRestrictions AS RoomRateRestrictions
	            |WHERE
	            |	(RoomRateRestrictions.RoomRate = &qRoomRate
	            |			OR RoomRateRestrictions.RoomRate = VALUE(Catalog.RoomRates.EmptyRef))
	            |	AND (RoomRateRestrictions.Hotel = &qEmptyHotel
	            |			OR &qHotelIsFilled
	            |				AND RoomRateRestrictions.Hotel = &qHotel
	            |			OR NOT &qHotelIsFilled)
	            |	AND (RoomRateRestrictions.RoomType = &qEmptyRoomType
	            |			OR &qRoomTypeIsFilled
	            |				AND RoomRateRestrictions.RoomType = &qRoomType)
	            |	AND (RoomRateRestrictions.CalendarDayType = &qEmptyCalendarDayType
	            |			OR &qCalendarDayTypeIsFilled
	            |				AND RoomRateRestrictions.CalendarDayType = &qCalendarDayType
	            |				AND RoomRateRestrictions.DayOfWeek = 0)
	            |	AND (RoomRateRestrictions.CalendarDayType = &qEmptyCalendarDayType
	            |			OR &qCalendarDayTypeIsFilled
	            |				AND RoomRateRestrictions.CalendarDayType = &qCalendarDayType
	            |				AND RoomRateRestrictions.DayOfWeek <> 0
	            |				AND RoomRateRestrictions.DayOfWeek = &qDayOfWeek)
	            |	AND (RoomRateRestrictions.DayOfWeek = 0
	            |			OR RoomRateRestrictions.DayOfWeek = &qDayOfWeek
	            |				AND RoomRateRestrictions.DayOfWeek <> 0
	            |				AND RoomRateRestrictions.CalendarDayType = &qEmptyCalendarDayType)
	            |	AND (RoomRateRestrictions.AccountingDate = &qEmptyDate
	            |			OR &qAccountingDateIsFilled
	            |				AND RoomRateRestrictions.AccountingDate = &qAccountingDate)
	            |	AND (NOT &qWithoutOnline
	            |			OR &qWithoutOnline
	            |				AND NOT RoomRateRestrictions.IsForOnlineOnly)
	            |	AND (&qShowTurnedOff
	            |			OR NOT &qShowTurnedOff
	            |				AND (RoomRateRestrictions.CTA
	            |					OR RoomRateRestrictions.CTD
	            |					OR RoomRateRestrictions.StopSale
	            |					OR RoomRateRestrictions.MLOS <> 0
	            |					OR RoomRateRestrictions.MaxLOS <> 0
	            |					OR RoomRateRestrictions.MinDaysBeforeCheckIn <> 0
	            |					OR RoomRateRestrictions.MaxDaysBeforeCheckIn <> 0))";
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pHotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsFilled", ValueIsFilled(pRoomType));
	vQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	vQry.SetParameter("qCalendarDayType", vCalendarDayType);
	vQry.SetParameter("qCalendarDayTypeIsFilled", ValueIsFilled(vCalendarDayType));
	vQry.SetParameter("qEmptyCalendarDayType", Catalogs.CalendarDayTypes.EmptyRef());
	vQry.SetParameter("qDayOfWeek", vDayOfWeek);
	vQry.SetParameter("qAccountingDate", vAccountingDate);
	vQry.SetParameter("qAccountingDateIsFilled", ValueIsFilled(vAccountingDate));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qWithoutOnline", pWithoutOnline);
	vQry.SetParameter("qShowTurnedOff", pShowTurnedOff);
	vRestrictions = vQry.Execute().Unload();
	For Each vRestrictionsRow In vRestrictions Do
		If vRestrictionsRow.StopSale Then
			vRestrStruct.StopSale = True;
		EndIf;
		If vRestrictionsRow.CTA Then
			vRestrStruct.CTA = True;
		EndIf;
		If vRestrictionsRow.CTD Then
			vRestrStruct.CTD = True;
		EndIf;
		If vRestrictionsRow.MLOS > vRestrStruct.MLOS Then
			vRestrStruct.MLOS = vRestrictionsRow.MLOS;
		EndIf;
		If vRestrictionsRow.MaxLOS <> 0 And (vRestrStruct.MaxLOS = 0 Or vRestrictionsRow.MaxLOS < vRestrStruct.MaxLOS) Then
			vRestrStruct.MaxLOS = vRestrictionsRow.MaxLOS;
		EndIf;
		If vRestrictionsRow.MinDaysBeforeCheckIn > vRestrStruct.MinDaysBeforeCheckIn Then
			vRestrStruct.MinDaysBeforeCheckIn = vRestrictionsRow.MinDaysBeforeCheckIn;
		EndIf;
		If vRestrictionsRow.MaxDaysBeforeCheckIn <> 0 And (vRestrStruct.MaxDaysBeforeCheckIn = 0 Or vRestrictionsRow.MaxDaysBeforeCheckIn < vRestrStruct.MaxDaysBeforeCheckIn) Then
			vRestrStruct.MaxDaysBeforeCheckIn = vRestrictionsRow.MaxDaysBeforeCheckIn;
		EndIf;
	EndDo;
	Return vRestrStruct;
EndFunction // cmGetRoomRateRestrictions

// -----------------------------------------------------------------------------
// Writes charge delete event to the information register
// -----------------------------------------------------------------------------
Procedure cmWriteChargeDeleteEvent(pCharge) Export
	// Write record to the information register
	vRecMgr = InformationRegisters.ChargeDeleteEvents.CreateRecordManager();
	vRecMgr.Period = CurrentSessionDate();
	vRecMgr.User = SessionParameters.CurrentUser;
	vRecMgr.Charge = pCharge;
	vRecMgr.Hotel = pCharge.Hotel;
	vRecMgr.Write();
EndProcedure // cmWriteChargeDeleteEvent

// -----------------------------------------------------------------------------
// Retrieves charge delete event from the information register
// -----------------------------------------------------------------------------
Function cmGetChargeDeleteEvent(pCharge) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ChargeDeleteEvents.Period AS Period,
	|	ChargeDeleteEvents.User AS User,
	|	ChargeDeleteEvents.Hotel AS Hotel,
	|	ChargeDeleteEvents.Charge AS Charge
	|FROM
	|	InformationRegister.ChargeDeleteEvents AS ChargeDeleteEvents
	|WHERE
	|	ChargeDeleteEvents.Charge = &qCharge
	|
	|ORDER BY
	|	Period DESC";
	vQry.SetParameter("qCharge", pCharge);
	vRecs = vQry.Execute().Unload();
	If vRecs.Count() > 0 Then
		Return vRecs.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetChargeDeleteEvent

// -----------------------------------------------------------------------------
// Creates online cheque and sends it to the payer
// -----------------------------------------------------------------------------
Procedure cmCreateAndSendOnlineCheque(pPaymentRef, pDepartmentToSendError = Undefined) Export
	tcCashRegisters.CreateAndSendOnlineCheque(pPaymentRef, pDepartmentToSendError);
EndProcedure // cmCreateAndSendOnlineCheque

// -----------------------------------------------------------------------------
// Sends online cheque to the payer
// -----------------------------------------------------------------------------
Function cmSendOnlineCheque(pPaymentRef, pPayerAddress = "", rMessage) Export
	Return tcCashRegisters.SendOnlineCheque(pPaymentRef, pPayerAddress, rMessage);
EndFunction // cmSendOnlineCheque

// -----------------------------------------------------------------------------
// Function builds online cheque text based on its attributes
// -----------------------------------------------------------------------------
Function cmGetChequeAttributes(pPaymentRef) Export
	Return tcCashRegisters.GetChequeAttributes(pPaymentRef);
EndFunction // cmGetChequeAttributes

// -----------------------------------------------------------------------------
// Function builds online cheque text based on its attributes
// -----------------------------------------------------------------------------
Function cmBuildOnlineChequeText(pPayment, rPayerAddress, rFiscalStorageFactoryNumber, rChequeFiscalNumber, rChequeVerificationAddress, rChequeSequenceNumber = "", rCashDayChequeNumber = "") Export
	Return tcCashRegisters.BuildOnlineChequeText(pPayment, rPayerAddress, rFiscalStorageFactoryNumber, rChequeFiscalNumber, rChequeVerificationAddress, rChequeSequenceNumber, rCashDayChequeNumber);
EndFunction // cmBuildOnlineChequeText

// -----------------------------------------------------------------------------
// Function creates array of rows to be printed on cash register cheque
// -----------------------------------------------------------------------------
Function cmGetPrintableChequePositions(pObj, rIsPrepayment = False, pUseAveragePrice = False) Export
	Return tcCashRegisters.GetPrintableChequePositions(pObj, rIsPrepayment, pUseAveragePrice);
EndFunction // cmGetPrintableChequePositions

// -----------------------------------------------------------------------------
// Fills cheque total VAT amount for the given VAT rate
// -----------------------------------------------------------------------------
Procedure cmSetChequeVATAmount(vChequeAttributes, vVATRate, vVATSum) Export
	tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, vVATSum);
EndProcedure // cmSetChequeVATAmount

// -----------------------------------------------------------------------------
// Function initializes cheque attributes
// -----------------------------------------------------------------------------
Function cmInitializeChequeAttributes(pObj, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	Return tcCashRegisters.InitializeChequeAttributes(pObj, , pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
EndFunction // cmInitializeChequeAttributes

// -----------------------------------------------------------------------------
Function cmGetChequeItemType(pObj, pService = Undefined, pPaymentSection = Undefined, pIsPrepayment = False) Export
	Return tcCashRegisters.GetChequeItemType(pObj, pService, pPaymentSection, pIsPrepayment);
EndFunction // cmGetChequeItemType

// -----------------------------------------------------------------------------
Function cmGetChequePaymentMode(pPaymentMethod, pPaymentSection = Undefined, pIsPrepayment = False) Export
	Return tcCashRegisters.GetChequePaymentMode(pPaymentMethod, pPaymentSection, pIsPrepayment);
EndFunction // cmGetChequePaymentMode

// -----------------------------------------------------------------------------
// Returns int value for the given cheque calculation method type
// -----------------------------------------------------------------------------
Function cmGetChequePaymentModeTypeValue(pCMTValue) Export
	Return tcCashRegisters.GetChequePaymentModeTypeValue(pCMTValue)
EndFunction // cmGetChequePaymentModeTypeValue

// -----------------------------------------------------------------------------
// Returns int value for the given cheque position type
// -----------------------------------------------------------------------------
Function cmGetChequeItemTypeValue(pPTValue) Export
	Return tcCashRegisters.GetChequeItemTypeValue(pPTValue);
EndFunction // cmGetChequeItemTypeValue

// -----------------------------------------------------------------------------
// Fills parameters used to register advance payments and advance settlement payments
// -----------------------------------------------------------------------------
Procedure cmFillAdvanceAndAdvanceSettlementParameters(pHotel, pEmployee, rAdvancePaymentSection, rAdvanceSettlementPaymentMethod, rMultipleAdvanceSectionsAreUsed = False, rAdvancePaymentSections = Undefined) Export
	rAdvancePaymentSection = Undefined;
	rAdvancePaymentSections = New ValueList();
	rAdvanceSettlementPaymentMethod = Undefined;
	rMultipleAdvanceSectionsAreUsed = False;
	// Try to find advance payment section
	vPSs = cmGetAllPaymentSections(pHotel);
	For Each vPSsRow In vPSs Do
		vPSRef = vPSsRow.PaymentSection;
		If vPSRef.ChequeItemType = Enums.ChequeItemTypes.Payment Then
			If Not ValueIsFilled(rAdvancePaymentSection) Then
				rAdvancePaymentSection = vPSRef;
			Else
				rMultipleAdvanceSectionsAreUsed = True;
			EndIf;
			rAdvancePaymentSections.Add(vPSRef);
		EndIf;
	EndDo;
	// Try to find advance settlement payment method
	vPMsList = cmGetListOfPaymentMethodsAllowed(pEmployee, False, Undefined, False);
	For Each vPMsListItem In vPMsList Do
		vPMRef = vPMsListItem.Value;
		If vPMRef = Catalogs.PaymentMethods.AdvanceSettlement Then
			rAdvanceSettlementPaymentMethod = vPMRef;
			Break;
		EndIf;
	EndDo;
EndProcedure // cmFillAdvanceAndAdvanceSettlementParameters

// -----------------------------------------------------------------------------
Function cmGetAdvancePaymentSections(pHotel) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PaymentSections.Ref AS Ref,
	|	PaymentSections.VATRate AS VATRate
	|FROM
	|	Catalog.PaymentSections AS PaymentSections
	|WHERE
	|	PaymentSections.ChequeItemType = VALUE(Enum.ChequeItemTypes.Payment)
	|	AND (PaymentSections.Hotel = &qHotel
	|			OR PaymentSections.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND NOT PaymentSections.DeletionMark
	|
	|ORDER BY
	|	PaymentSections.Code";
	vQry.SetParameter("qHotel", pHotel);
	Return vQry.Execute().Unload();
EndFunction // cmGetAdvancePaymentSections

// -----------------------------------------------------------------------------
Function cmGetAllMealBoardTerms(pHotel) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServicePackages.Ref AS Ref
	|FROM
	|	Catalog.ServicePackages AS ServicePackages
	|WHERE
	|	NOT ServicePackages.DeletionMark
	|	AND NOT ServicePackages.IsFolder
	|	AND ServicePackages.IsMealBoardTerm
	|	AND (ServicePackages.Hotel = &qHotel
	|			OR ServicePackages.Hotel = &qEmptyHotel
	|			OR &qHotel = &qEmptyHotel)
	|
	|ORDER BY
	|	ServicePackages.SortCode,
	|	ServicePackages.Description";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vRefs = vQry.Execute().Unload();
	Return vRefs;
EndFunction // cmGetAllMealBoardTerms

// -----------------------------------------------------------------------------
Function cmGetChargingRulesRowFolio(pGuestGroup, pDoc, pLineNumber) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.GuestGroup = &qGuestGroup
	|	AND (&qDocIsFilled
	|				AND Folio.ParentDoc = &qDoc
	|			OR NOT &qDocIsFilled
	|				AND Folio.ParentDoc = UNDEFINED)
	|	AND Folio.LineNumber = &qLineNumber
	|
	|ORDER BY
	|	Folio.PointInTime DESC";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qDoc", pDoc);
	vQry.SetParameter("qDocIsFilled", ValueIsFilled(pDoc));
	vQry.SetParameter("qLineNumber", pLineNumber);
	vFolios = vQry.Execute().Unload();
	If vFolios.Count() > 0 Then
		Return vFolios.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // cmGetChargingRulesRowFolio

// -----------------------------------------------------------------------------
Procedure cmUpdateChargingRulesFoliosLineNumbers(pChargingRules) Export
	For Each vCRRow In pChargingRules Do
		vLineNumber = pChargingRules.IndexOf(vCRRow) + 1;
		If ValueIsFilled(vCRRow.ChargingFolio) Then
			vFolioObj = vCRRow.ChargingFolio.GetObject();
			If vFolioObj.LineNumber <> vLineNumber Then
				vFolioObj.LineNumber = vLineNumber;
				vFolioObj.DataExchange.Load = True;
				vFolioObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // cmUpdateChargingRulesFoliosLineNumbers

// -----------------------------------------------------------------------------
Function cmGetFormulaExecutionText(Val pFormula, pObj = Undefined) Export
	pFormula = StrReplace(pFormula, "[VATRate]", "cmGetVATTaxRate(vSrvVATRate, [AccountingDate])");
	pFormula = StrReplace(pFormula, "[ItemVATRate]", "cmGetVATTaxRate(vItemVATRate, [AccountingDate])");
	If TypeOf(pObj) = Type("DocumentObject.Charge") Then
		pFormula = StrReplace(pFormula, "[AccountingDate]", "BegOfDay(Date)");
		pFormula = StrReplace(pFormula, "[NumberOfRooms]", "?(IsRoomRevenue And IsInPrice And RoomsRented <> 0, RoomsRented, 0)");
		pFormula = StrReplace(pFormula, "[NumberOfPersons]", "?(IsRoomRevenue And IsInPrice And GuestDays <> 0, GuestDays, 0)");
		pFormula = StrReplace(pFormula, "[NumberOfAdults]", "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfAdults, 1)");
		pFormula = StrReplace(pFormula, "[NumberOfTeenagers]", "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfTeenagers, 0)");
		pFormula = StrReplace(pFormula, "[NumberOfChildren]", "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfChildren, 0)");
		pFormula = StrReplace(pFormula, "[NumberOfInfants]", "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfInfants, 0)");
		pFormula = StrReplace(pFormula, "[RateAmount]", "?(IsRoomRevenue And IsInPrice, vRateSumInReportingCurrency, 0)");
		pFormula = StrReplace(pFormula, "[TouristTaxAmountRU]", "?(IsRoomRevenue And IsInPrice And Not IsSplit And Not RoomRevenueAmountsOnly And vSrvSumInReportingCurrency <> 0 And vAccommodationTypesListItemIndex = 0 And ValueIsFilled(ParentDoc) And (TypeOf(ParentDoc) = Type(""DocumentRef.Accommodation"") Or TypeOf(ParentDoc) = Type(""DocumentRef.Reservation"")) And Not ValueIsFilled(ParentDoc.TouristicTaxExemptionReason) And ParentDoc.DurationInDays <> 0, Round(cmConvertCurrencies(ParentDoc.TouristTaxSumInBaseCurrency/ParentDoc.DurationInDays, Hotel.BaseCurrency, , ReportingCurrency, , ExchangeRateDate, Hotel), 2), 0)");
	ElsIf TypeOf(pObj) = Type("DocumentObject.Accommodation") Then
		pFormula = StrReplace(pFormula, "[AccountingDate]", "vSrvRec.AccountingDate");
		pFormula = StrReplace(pFormula, "[NumberOfRooms]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.RoomsRented <> 0, vSrvRec.RoomsRented, 0)");
		pFormula = StrReplace(pFormula, "[NumberOfPersons]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.GuestDays <> 0, vSrvRec.GuestDays, 0)");
		pFormula = StrReplace(pFormula, "[NumberOfAdults]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.GuestDays <> 0, NumberOfAdults, 0)");
		pFormula = StrReplace(pFormula, "[NumberOfTeenagers]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.GuestDays <> 0, NumberOfTeenagers, 0)");
		pFormula = StrReplace(pFormula, "[NumberOfChildren]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.GuestDays <> 0, NumberOfChildren, 0)");
		pFormula = StrReplace(pFormula, "[NumberOfInfants]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.GuestDays <> 0, NumberOfInfants, 0)");
		pFormula = StrReplace(pFormula, "[RateAmount]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice, vRateSumInReportingCurrency, 0)");
		pFormula = StrReplace(pFormula, "[TouristTaxAmountRU]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And Not vSrvRec.IsSplit And Not vSrvRec.RoomRevenueAmountsOnly And vSrvSumInReportingCurrency <> 0 And vAccommodationTypesListItemIndex = 0 And Not ValueIsFilled(TouristicTaxExemptionReason) And DurationInDays <> 0, Round(cmConvertCurrencies(TouristTaxSumInBaseCurrency/DurationInDays, Hotel.BaseCurrency, , ReportingCurrency, , ExchangeRateDate, Hotel), 2), 0)");
	ElsIf TypeOf(pObj) = Type("DocumentObject.Reservation") Then
		pFormula = StrReplace(pFormula, "[AccountingDate]", "vSrvRec.AccountingDate");
		pFormula = StrReplace(pFormula, "[NumberOfRooms]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.RoomsRented <> 0, vSrvRec.RoomsRented, 0)");
		pFormula = StrReplace(pFormula, "[NumberOfPersons]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.GuestDays <> 0, vSrvRec.GuestDays, 0)/?(vRoomQuantity = 0, 1, vRoomQuantity)");
		pFormula = StrReplace(pFormula, "[NumberOfAdults]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.GuestDays <> 0, NumberOfAdults, 0)/?(vRoomQuantity = 0, 1, vRoomQuantity)");
		pFormula = StrReplace(pFormula, "[NumberOfTeenagers]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.GuestDays <> 0, NumberOfTeenagers, 0)/?(vRoomQuantity = 0, 1, vRoomQuantity)");
		pFormula = StrReplace(pFormula, "[NumberOfChildren]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.GuestDays <> 0, NumberOfChildren, 0)/?(vRoomQuantity = 0, 1, vRoomQuantity)");
		pFormula = StrReplace(pFormula, "[NumberOfInfants]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And vSrvRec.GuestDays <> 0, NumberOfInfants, 0)/?(vRoomQuantity = 0, 1, vRoomQuantity)");
		pFormula = StrReplace(pFormula, "[RateAmount]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice, vRateSumInReportingCurrency, 0)");
		pFormula = StrReplace(pFormula, "[TouristTaxAmountRU]", "?(vSrvRec.IsRoomRevenue And vSrvRec.IsInPrice And Not vSrvRec.IsSplit And Not vSrvRec.RoomRevenueAmountsOnly And vSrvSumInReportingCurrency <> 0 And vAccommodationTypesListItemIndex = 0 And Not ValueIsFilled(TouristicTaxExemptionReason) And DurationInDays <> 0, Round(cmConvertCurrencies(TouristTaxSumInBaseCurrency/DurationInDays, Hotel.BaseCurrency, , ReportingCurrency, , ExchangeRateDate, Hotel), 2), 0)");
	ElsIf TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
		pFormula = StrReplace(pFormula, "[AccountingDate]", "vSrvRec.AccountingDate");
		pFormula = StrReplace(pFormula, "[NumberOfRooms]", "0");
		pFormula = StrReplace(pFormula, "[NumberOfPersons]", "NumberOfPersons");
		pFormula = StrReplace(pFormula, "[NumberOfAdults]", "0");
		pFormula = StrReplace(pFormula, "[NumberOfTeenagers]", "0");
		pFormula = StrReplace(pFormula, "[NumberOfChildren]", "0");
		pFormula = StrReplace(pFormula, "[NumberOfInfants]", "0");
		pFormula = StrReplace(pFormula, "[RateAmount]", "?(vSrvRec.IsResourceRevenue, vRateSumInReportingCurrency, 0)");
		pFormula = StrReplace(pFormula, "[TouristTaxAmountRU]", "0");
	EndIf;	
	pFormula = StrReplace(pFormula, "[ItemPrice]", "vItemPrice");
	pFormula = StrReplace(pFormula, "[ItemQuantity]", "vItemQuantity");
	pFormula = StrReplace(pFormula, "[Amount]", "vSrvSumInReportingCurrency");
	pFormula = StrReplace(pFormula, "[VATAmount]", "vSrvVATSumInReportingCurrency");
	pFormula = StrReplace(pFormula, "[DiscountAmount]", "vSrvDiscountSumInReportingCurrency");
	pFormula = StrReplace(pFormula, "[CommissionAmount]", "vSrvCommissionSumInReportingCurrency");
	pFormula = StrReplace(pFormula, "[Price]", "vSrvPrice");
	pFormula = StrReplace(pFormula, "[Quantity]", "vSrvQuantity");
	Return pFormula;
EndFunction // cmGetFormulaExecutionText

// -----------------------------------------------------------------------------
Function cmGetServiceBreakdownList(pService, pDate, pHotel, pRoomRate, pRoomType, pAccommodationType) Export
	vStruct = CachedAccounts.GetServiceBreakdownList(pService, pDate, pHotel, pRoomRate, pRoomType, pAccommodationType);
	Return vStruct.BreakdownList;
EndFunction // cmGetServiceBreakdownList

// -----------------------------------------------------------------------------
Function GetServiceBreakdownListActiveDate(pService, pDate, pHotel) Export
	vDate = '00010101';
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BreakDownListSettingsSliceLast.Service AS Service,
	|	MAX(BreakDownListSettingsSliceLast.Period) AS MaxPeriod
	|FROM
	|	InformationRegister.BreakDownListSettings.SliceLast(
	|			&qDate,
	|			Service = &qService
	|				AND (Hotel = &qHotel
	|					OR Hotel = VALUE(Catalog.Hotels.EmptyRef))) AS BreakDownListSettingsSliceLast
	|
	|GROUP BY
	|	BreakDownListSettingsSliceLast.Service";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qService", pService);
	vQry.SetParameter("qHotel", pHotel);
	vBDLSettings = vQry.Execute().Unload();
	If vBDLSettings.Count() > 0 Then
		vDate = vBDLSettings.Get(0).MaxPeriod;
	EndIf;
	Return vDate;
EndFunction // GetServiceBreakdownListActiveDate

// -----------------------------------------------------------------------------
Function cmGetAccountCodeForVATRate(pHotel, pCompany, pVATRate) Export
	vAccount = Undefined;
	vCode = "";
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	VATRateAccountingCodes.VATRate AS VATRate,
	|	VATRateAccountingCodes.Hotel AS Hotel,
	|	VATRateAccountingCodes.Company AS Company,
	|	VATRateAccountingCodes.Account AS Account,
	|	VATRateAccountingCodes.Code AS Code
	|FROM
	|	InformationRegister.VATRateAccountingCodes AS VATRateAccountingCodes
	|WHERE
	|	VATRateAccountingCodes.VATRate = &qVATRate
	|	AND (VATRateAccountingCodes.Hotel = &qHotel
	|			OR VATRateAccountingCodes.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND (VATRateAccountingCodes.Company = &qCompany
	|					OR VATRateAccountingCodes.Company = VALUE(Catalog.Companies.EmptyRef)))
	|
	|ORDER BY
	|	VATRateAccountingCodes.Hotel.Code DESC,
	|	VATRateAccountingCodes.Company.Code DESC";
	vQry.SetParameter("qVATRate", pVATRate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", NOT ValueIsFilled(pCompany));
	
	vCodes = vQry.Execute().Unload();
	For Each vCodesRow In vCodes Do
		vAccount = vCodesRow.Account;
		vCode = TrimAll(vCodesRow.Code);
		Break;
	EndDo;
	
	Return New Structure("Account, Code", vAccount, vCode);
EndFunction // cmGetAccountCodeForVATRate

// -----------------------------------------------------------------------------
Function cmGetAccountCodeForService(pHotel, pCompany, pService, pVATRate, pDate) Export
	vCode = "";
	vCodeDt = "";
	vCodeCr = "";
	vAccount = Undefined;
	vDate = '00010101';
	
	// Get date of active settings
	vDateQry = New Query();
	vDateQry.Text = 
	"SELECT
	|	ServiceAccountingCodesDate.Period AS Period
	|FROM
	|	InformationRegister.ServiceAccountingCodes.SliceLast(
	|			&qDate,
	|			Service = &qService
	|				AND (VATRate = &qVATRate
	|					OR VATRate = VALUE(Catalog.VATRates.EmptyRef))
	|				AND (Hotel = &qHotel
	|					OR Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|				AND (&qCompanyIsEmpty
	|					OR NOT &qCompanyIsEmpty
	|						AND (Company = &qCompany
	|							OR Company = VALUE(Catalog.Companies.EmptyRef)))) AS ServiceAccountingCodesDate";
	vDateQry.SetParameter("qService", pService);
	vDateQry.SetParameter("qVATRate", pVATRate);
	vDateQry.SetParameter("qHotel", pHotel);
	vDateQry.SetParameter("qCompany", pCompany);
	vDateQry.SetParameter("qCompanyIsEmpty", NOT ValueIsFilled(pCompany));
	vDateQry.SetParameter("qDate", pDate);
	vDates = vDateQry.Execute().Unload();
	If vDates.Count() > 0 Then
		vDate = vDates.Get(0).Period;
	EndIf;
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServiceAccountingCodes.Service AS Service,
	|	ServiceAccountingCodes.VATRate AS VATRate,
	|	ServiceAccountingCodes.Hotel AS Hotel,
	|	ServiceAccountingCodes.Company AS Company,
	|	ServiceAccountingCodes.Account AS Account,
	|	ServiceAccountingCodes.CodeDt AS CodeDt, 
	|	ServiceAccountingCodes.CodeCr AS CodeCr,
	|	ServiceAccountingCodes.Code AS Code
	|FROM
	|	InformationRegister.ServiceAccountingCodes AS ServiceAccountingCodes
	|WHERE
	|	ServiceAccountingCodes.Service = &qService
	|	AND ServiceAccountingCodes.Period = &qDate
	|	AND (ServiceAccountingCodes.VATRate = &qVATRate
	|			OR ServiceAccountingCodes.VATRate = VALUE(Catalog.VATRates.EmptyRef))
	|	AND (ServiceAccountingCodes.Hotel = &qHotel
	|			OR ServiceAccountingCodes.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND (ServiceAccountingCodes.Company = &qCompany
	|					OR ServiceAccountingCodes.Company = VALUE(Catalog.Companies.EmptyRef)))
	|
	|ORDER BY
	|	ServiceAccountingCodes.VATRate.Code DESC,
	|	ServiceAccountingCodes.Hotel.Code DESC,
	|	ServiceAccountingCodes.Company.Code DESC";
	vQry.SetParameter("qService", pService);
	vQry.SetParameter("qVATRate", pVATRate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", NOT ValueIsFilled(pCompany));
	vQry.SetParameter("qDate", vDate);
	
	vCodes = vQry.Execute().Unload();
	For Each vCodesRow In vCodes Do
		vAccount = vCodesRow.Account;
		vCode = TrimAll(vCodesRow.Code);
		vCodeDt = TrimAll(vCodesRow.CodeDt);
		vCodeCr = TrimAll(vCodesRow.CodeCr);
		Break;
	EndDo;
	
	Return New Structure("Account, Code, CodeDt, CodeCr", vAccount, vCode, vCodeDt, vCodeCr);
EndFunction // cmGetAccountCodeForService

// -----------------------------------------------------------------------------
Function cmGetAccountCodeForPOSAndPaymentMethod(pHotel, pCompany, pCashRegister, pPaymentMethod, pPaymentSection) Export
	vAccount = Undefined;
	vCode = "";
	vCommissionPercent = 0;
	vCommissionAccount = Undefined;
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PaymentMethodAndPOSAccountingCodes.PaymentMethod AS PaymentMethod,
	|	PaymentMethodAndPOSAccountingCodes.PaymentSection AS PaymentSection,
	|	PaymentMethodAndPOSAccountingCodes.CashRegister AS CashRegister,
	|	PaymentMethodAndPOSAccountingCodes.Hotel AS Hotel,
	|	PaymentMethodAndPOSAccountingCodes.Company AS Company,
	|	PaymentMethodAndPOSAccountingCodes.Account AS Account,
	|	PaymentMethodAndPOSAccountingCodes.Code AS Code,
	|	PaymentMethodAndPOSAccountingCodes.CommissionPercent AS CommissionPercent,
	|	PaymentMethodAndPOSAccountingCodes.CommissionAccount AS CommissionAccount
	|FROM
	|	InformationRegister.PaymentMethodAndPOSAccountingCodes AS PaymentMethodAndPOSAccountingCodes
	|WHERE
	|	PaymentMethodAndPOSAccountingCodes.PaymentMethod = &qPaymentMethod
	|	AND PaymentMethodAndPOSAccountingCodes.PaymentSection = &qPaymentSection
	|	AND PaymentMethodAndPOSAccountingCodes.CashRegister = &qCashRegister
	|	AND (PaymentMethodAndPOSAccountingCodes.Hotel = &qHotel
	|			OR PaymentMethodAndPOSAccountingCodes.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND (PaymentMethodAndPOSAccountingCodes.Company = &qCompany
	|					OR PaymentMethodAndPOSAccountingCodes.Company = VALUE(Catalog.Companies.EmptyRef)))
	|
	|ORDER BY
	|	PaymentMethodAndPOSAccountingCodes.Hotel.Code DESC,
	|	PaymentMethodAndPOSAccountingCodes.Company.Code DESC";
	vQry.SetParameter("qPaymentMethod", pPaymentMethod);
	vQry.SetParameter("qPaymentSection", pPaymentSection);
	vQry.SetParameter("qCashRegister", pCashRegister);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", NOT ValueIsFilled(pCompany));
	
	vCodes = vQry.Execute().Unload();
	For Each vCodesRow In vCodes Do
		vAccount = vCodesRow.Account;
		vCode = TrimAll(vCodesRow.Code);
		vCommissionPercent = vCodesRow.CommissionPercent;
		vCommissionAccount = vCodesRow.CommissionAccount;
		Break;
	EndDo;
	
	Return New Structure("Account, Code, CommissionPercent, CommissionAccount", vAccount, vCode, vCommissionPercent, vCommissionAccount);
EndFunction // cmGetAccountCodeForPOSAndPaymentMethod

// -----------------------------------------------------------------------------
Function cmGetAccountCodeForCustomer(pHotel, pCompany, pCustomer, pContract = Undefined, pFolioDescription = "") Export
	vAccount = Undefined;
	vCode = "";
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerAccountingCodes.Customer AS Customer,
	|	CustomerAccountingCodes.Contract AS Contract,
	|	CustomerAccountingCodes.Hotel AS Hotel,
	|	CustomerAccountingCodes.Company AS Company,
	|	CustomerAccountingCodes.FolioDescription AS FolioDescription,
	|	CustomerAccountingCodes.Account AS Account,
	|	CustomerAccountingCodes.Code AS Code
	|FROM
	|	InformationRegister.CustomerAccountingCodes AS CustomerAccountingCodes
	|WHERE
	|	CustomerAccountingCodes.Customer = &qCustomer
	|	AND ((CustomerAccountingCodes.Contract = &qContract
	|				OR CustomerAccountingCodes.Contract = VALUE(Catalog.Contracts.EmptyRef))
	|				AND &qContractIsFilled
	|			OR NOT &qContractIsFilled
	|				AND CustomerAccountingCodes.Contract = VALUE(Catalog.Contracts.EmptyRef))
	|	AND (NOT &qFolioDescriptionIsFilled
	|				AND CustomerAccountingCodes.FolioDescription = """"
	|			OR &qFolioDescriptionIsFilled
	|				AND CustomerAccountingCodes.FolioDescription = &qFolioDescription)
	|	AND (CustomerAccountingCodes.Hotel = &qHotel
	|			OR CustomerAccountingCodes.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND (CustomerAccountingCodes.Company = &qCompany
	|					OR CustomerAccountingCodes.Company = VALUE(Catalog.Companies.EmptyRef)))
	|
	|ORDER BY
	|	CustomerAccountingCodes.Hotel.Code DESC,
	|	CustomerAccountingCodes.Company.Code DESC";
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qContractIsFilled", ValueIsFilled(pContract));
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", NOT ValueIsFilled(pCompany));
	vQry.SetParameter("qFolioDescription", TrimAll(pFolioDescription));
	vQry.SetParameter("qFolioDescriptionIsFilled", ValueIsFilled(TRimAll(pFolioDescription)));
	
	vCodes = vQry.Execute().Unload();
	For Each vCodesRow In vCodes Do
		vAccount = vCodesRow.Account;
		vCode = TrimAll(vCodesRow.Code);
		Break;
	EndDo;
	
	Return New Structure("Account, Code", vAccount, vCode);
EndFunction // cmGetAccountCodeForCustomer

// -----------------------------------------------------------------------------
Function cmGetFoliosForDirectPostings(pHotel = Undefined, pCompany = Undefined, pCustomer = Undefined, pClient = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref,
	|	Folio.Number AS Number,
	|	Folio.Description AS Description,
	|	ISNULL(Folio.Client.FullName, """") AS ClientFullName
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.IsForDirectPostings
	|	AND NOT Folio.IsClosed
	|	AND NOT Folio.DeletionMark
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Folio.Hotel = &qHotel)
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND Folio.Company = &qCompany)
	|	AND (&qCustomerIsEmpty
	|			OR NOT &qCustomerIsEmpty
	|				AND Folio.Customer = &qCustomer)
	|	AND (&qClientIsEmpty
	|			OR NOT &qClientIsEmpty
	|				AND Folio.Client = &qClient)
	|
	|ORDER BY
	|	Folio.PointInTime DESC";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(pCustomer));
	vQry.SetParameter("qClient", pClient);
	vQry.SetParameter("qClientIsEmpty", Not ValueIsFilled(pClient));
	vFolios = vQry.Execute().Unload();
	vFoliosList = New ValueList();
	For Each vFoliosRow In vFolios Do
		vFoliosList.Add(vFoliosRow.Ref, NStr("en='N '; ru='№ '; de='Nr. '") + TrimAll(vFoliosRow.Number) + ?(IsBlankString(vFoliosRow.Description), "", " - " + TrimAll(vFoliosRow.Description)) + ?(IsBlankString(vFoliosRow.ClientFullName), "", " - " + TrimAll(vFoliosRow.ClientFullName)));
	EndDo;
	Return vFoliosList;
EndFunction // cmGetFoliosForDirectPostings

// -----------------------------------------------------------------------------
Function cmGetExternalPOSFolios(pHotel = Undefined, pCompany = Undefined, pCustomer = Undefined, pClient = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref,
	|	Folio.Number AS Number,
	|	Folio.Description AS Description,
	|	ISNULL(Folio.Client.FullName, """") AS ClientFullName
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.IsForExternalPOS
	|	AND NOT Folio.IsClosed
	|	AND NOT Folio.DeletionMark
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Folio.Hotel = &qHotel)
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND Folio.Company = &qCompany)
	|	AND (&qCustomerIsEmpty
	|			OR NOT &qCustomerIsEmpty
	|				AND Folio.Customer = &qCustomer)
	|	AND (&qClientIsEmpty
	|			OR NOT &qClientIsEmpty
	|				AND Folio.Client = &qClient)
	|
	|ORDER BY
	|	Folio.PointInTime DESC";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(pCustomer));
	vQry.SetParameter("qClient", pClient);
	vQry.SetParameter("qClientIsEmpty", Not ValueIsFilled(pClient));
	vFolios = vQry.Execute().Unload();
	vFoliosList = New ValueList();
	For Each vFoliosRow In vFolios Do
		vFoliosList.Add(vFoliosRow.Ref, NStr("en='N '; ru='№ '; de='Nr. '") + TrimAll(vFoliosRow.Number) + ?(IsBlankString(vFoliosRow.Description), "", " - " + TrimAll(vFoliosRow.Description)) + ?(IsBlankString(vFoliosRow.ClientFullName), "", " - " + TrimAll(vFoliosRow.ClientFullName)));
	EndDo;
	Return vFoliosList;
EndFunction // cmGetExternalPOSFolios

// -----------------------------------------------------------------------------
Function cmGetPostingFormulaExecutionText(Val pFormula, pConstValue, pObj = Undefined) Export
	If ValueIsFilled(pConstValue) And Not IsBlankString(pConstValue.ValueSymbol) Then
		vVariableName = TrimAll(pConstValue.ValueSymbol);
		vVariableValue = Format(pConstValue.Value, "ND=17; NFD=7; NDS=.; NZ=; NG=");
		pFormula = StrReplace(pFormula, vVariableName, vVariableValue);
	EndIf;
	pFormula = StrReplace(pFormula, "[VATRate]", "cmGetVATTaxRate(vSrvVATRate, [AccountingDate])");
	pFormula = StrReplace(pFormula, Upper("[VATRate]"), "cmGetVATTaxRate(vSrvVATRate, [AccountingDate])");
	pFormula = StrReplace(pFormula, "[AccountingDate]", "BegOfDay(Date)");
	pFormula = StrReplace(pFormula, Upper("[AccountingDate]"), "BegOfDay(Date)");
	pFormula = StrReplace(pFormula, "[NumberOfRooms]", "?(IsRoomRevenue And IsInPrice And RoomsRented <> 0, Int(RoomsRented), 0)");
	pFormula = StrReplace(pFormula, Upper("[NumberOfRooms]"), "?(IsRoomRevenue And IsInPrice And RoomsRented <> 0, Int(RoomsRented), 0)");
	pFormula = StrReplace(pFormula, "[NumberOfPersons]", "?(IsRoomRevenue And IsInPrice And GuestDays <> 0, GuestDays, 0)");
	pFormula = StrReplace(pFormula, Upper("[NumberOfPersons]"), "?(IsRoomRevenue And IsInPrice And GuestDays <> 0, GuestDays, 0)");
	pFormula = StrReplace(pFormula, "[NumberOfAdults]", "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfAdults, 0)");
	pFormula = StrReplace(pFormula, Upper("[NumberOfAdults]"), "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfAdults, 0)");
	pFormula = StrReplace(pFormula, "[NumberOfTeenagers]", "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfTeenagers, 0)");
	pFormula = StrReplace(pFormula, Upper("[NumberOfTeenagers]"), "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfTeenagers, 0)");
	pFormula = StrReplace(pFormula, "[NumberOfChildren]", "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfChildren, 0)");
	pFormula = StrReplace(pFormula, Upper("[NumberOfChildren]"), "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfChildren, 0)");
	pFormula = StrReplace(pFormula, "[NumberOfInfants]", "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfInfants, 0)");
	pFormula = StrReplace(pFormula, Upper("[NumberOfInfants]"), "?(IsRoomRevenue And IsInPrice And ValueIsFilled(AccommodationTemplate) And GuestDays <> 0, AccommodationTemplate.NumberOfInfants, 0)");
	pFormula = StrReplace(pFormula, "[Amount]", "vSrvSumInPostingCurrency");
	pFormula = StrReplace(pFormula, Upper("[Amount]"), "vSrvSumInPostingCurrency");
	pFormula = StrReplace(pFormula, "[VATAmount]", "vSrvVATSumInPostingCurrency");
	pFormula = StrReplace(pFormula, Upper("[VATAmount]"), "vSrvVATSumInPostingCurrency");
	pFormula = StrReplace(pFormula, "[DiscountAmount]", "vSrvDiscountSumInPostingCurrency");
	pFormula = StrReplace(pFormula, Upper("[DiscountAmount]"), "vSrvDiscountSumInPostingCurrency");
	pFormula = StrReplace(pFormula, "[CommissionAmount]", "vSrvCommissionSumInPostingCurrency");
	pFormula = StrReplace(pFormula, Upper("[CommissionAmount]"), "vSrvCommissionSumInPostingCurrency");
	pFormula = StrReplace(pFormula, "[Price]", "vSrvPrice");
	pFormula = StrReplace(pFormula, Upper("[Price]"), "vSrvPrice");
	pFormula = StrReplace(pFormula, "[Quantity]", "vSrvQuantity");
	pFormula = StrReplace(pFormula, Upper("[Quantity]"), "vSrvQuantity");
	pFormula = StrReplace(pFormula, "[RateAmount]", "vRateSumInPostingCurrency");
	Return pFormula;
EndFunction // cmGetPostingFormulaExecutionText

// -----------------------------------------------------------------------------
Function cmGetPostingDescriptionByTemplate(pTemplate) Export
	vTemplate = TrimAll(pTemplate);
	vTemplate = StrReplace(vTemplate, "[PostingService]", "TrimAll(pService)");
	vTemplate = StrReplace(vTemplate, "[", "");
	vTemplate = StrReplace(vTemplate, "]", "");
	Return vTemplate;
EndFunction // cmGetPostingDescriptionByTemplate

// -----------------------------------------------------------------------------
Function cmGetProformaInvoiceService(pPayment, rVATRate) Export
	vService = Undefined;
	vHotel = pPayment.Hotel;
	vPaymentMethod = pPayment.PaymentMethod;
	vPaymentSection = pPayment.PaymentSection;
	vDiscountCard = Undefined;
	If TypeOf(pPayment) <> Type("DocumentRef.CustomerPayment") And TypeOf(pPayment) <> Type("DocumentRef.DepositTransfer") Then
		vDiscountCard = pPayment.DiscountCard;
	EndIf;
	If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) And ValueIsFilled(vDiscountCard.DiscountType.ProformaInvoiceService) And 
	  (vDiscountCard.LoyaltyType = Enums.LoyaltyType.Bonuses Or vDiscountCard.LoyaltyType = Enums.LoyaltyType.Certificate) And
	  ValueIsFilled(vPaymentMethod) And Not vPaymentMethod.IsByBonuses And Not vPaymentMethod.IsByGiftCertificate Then
		vService = vDiscountCard.DiscountType.ProformaInvoiceService;
	ElsIf ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.ProformaInvoiceService) Then
		vService = vPaymentSection.ProformaInvoiceService;
		If ValueIsFilled(vPaymentSection.VATRate) Then
			rVATRate = vPaymentSection.VATRate;
		EndIf;
	ElsIf ValueIsFilled(vHotel) And ValueIsFilled(vHotel.ProformaInvoiceService) Then
		vService = vHotel.ProformaInvoiceService;
		vSrvAttrs = vService.GetObject().pmGetServicePrices(pPayment.Hotel, pPayment.Date, Catalogs.ClientTypes.EmptyRef());
		If vSrvAttrs.Count() > 0 Then
			vVATRate = vSrvAttrs.Get(0).VATRate;
			If ValueIsFilled(vVATRate) Then
				rVATRate = vVATRate;
			EndIf;
		EndIf;
	EndIf;
	Return vService;
EndFunction // cmGetProformaInvoiceService

// -----------------------------------------------------------------------------
Function cmUseFOPostingsForIncome(pHotel) Export
	vCounter = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(ChartOfAccountsFOPostingsListSettings.Ref) AS Counter
	|FROM
	|	ChartOfAccounts.ChartOfAccountsFO.PostingsListSettings AS ChartOfAccountsFOPostingsListSettings
	|WHERE
	|	ChartOfAccountsFOPostingsListSettings.Account = ChartOfAccountsFOPostingsListSettings.Ref
	|	AND NOT ChartOfAccountsFOPostingsListSettings.Ref.DeletionMark
	|	AND (ChartOfAccountsFOPostingsListSettings.Ref.Hotel = &qHotel
	|			OR ChartOfAccountsFOPostingsListSettings.Ref.Hotel = &qEmptyHotel)";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vRows = vQry.Execute().Unload();
	For Each vRow In vRows Do
		If vRow.Counter <> Null Then
			vCounter = vCounter + vRow.Counter;
		EndIf;
	EndDo;
	Return ?(vCounter > 0, True, False);
EndFunction // cmUseFOPostingsForIncome

// -----------------------------------------------------------------------------
Function cmCompareDiscounts(pNewDiscount, pOldDiscount) Export
	vResult = False;
	If pNewDiscount = 0 Then
		vResult = False;
	ElsIf pOldDiscount = 0 Then
		vResult = True;
	Else
		If pNewDiscount > 0 Then
			If pOldDiscount > 0 Then
				If pNewDiscount >= pOldDiscount Then
					vResult = True;
				Else
					vResult = False;
				EndIf;
			Else
				vResult = True;
			EndIf;
		Else
			If pOldDiscount < 0 Then
				If pNewDiscount >= pOldDiscount Then
					vResult = True;
				Else
					vResult = False;
				EndIf;
			Else
				vResult = False;
			EndIf;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // cmCompareDiscounts

// -----------------------------------------------------------------------------
Function cmGetAdvancesForAdvanceClearing(pFolio, pDate) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerAccounts.AccountingCurrency AS Currency,
	|	CustomerAccounts.PaymentMethod AS PaymentMethod,
	|	SUM(CASE
	|			WHEN CustomerAccounts.PaymentSection.ChequeItemType = VALUE(Enum.ChequeItemTypes.Payment)
	|					AND CustomerAccounts.Recorder.PaymentMethod <> &qAdvanceSettlement
	|				THEN CustomerAccounts.Sum
	|			ELSE -CustomerAccounts.Sum
	|		END) AS Sum
	|FROM
	|	AccumulationRegister.CustomerAccounts AS CustomerAccounts
	|WHERE
	|	CustomerAccounts.Folio = &qFolio
	|	AND CustomerAccounts.RecordType = &qRecordType
	|	AND CustomerAccounts.Recorder.Date < &qDate
	|	AND CustomerAccounts.PaymentMethod <> &qSettlement
	|	AND (CustomerAccounts.PaymentSection.ChequeItemType = VALUE(Enum.ChequeItemTypes.Payment)
	|				AND CustomerAccounts.Recorder.PaymentMethod <> &qAdvanceSettlement
	|			OR CustomerAccounts.PaymentSection.ChequeItemType <> VALUE(Enum.ChequeItemTypes.Payment)
	|				AND CustomerAccounts.Recorder.PaymentMethod = &qAdvanceSettlement)
	|
	|GROUP BY
	|	CustomerAccounts.AccountingCurrency,
	|	CustomerAccounts.PaymentMethod
	|
	|ORDER BY
	|	CustomerAccounts.AccountingCurrency.Code,
	|	CustomerAccounts.PaymentMethod.SortCode,
	|	CustomerAccounts.PaymentMethod.Code";
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qSettlement", Catalogs.PaymentMethods.Settlement);
	vQry.SetParameter("qAdvanceSettlement", Catalogs.PaymentMethods.AdvanceSettlement);
	vQry.SetParameter("qRecordType", AccumulationRecordType.Expense);
	vPMs = vQry.Execute().Unload();
	Return vPMs;
EndFunction // cmGetAdvancesForAdvanceClearing

// -----------------------------------------------------------------------------
Procedure cmGetPaymentsForInvoiceTransactions(pFoliosList, pPaymentsList, pInvoice, rPaymentAmounts, rPaymentAmountsNoPriorityAndService) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	InvoicePayments.Folio AS Folio,
	|	InvoicePayments.Priority AS Priority,
	|	InvoicePayments.Currency AS Currency,
	|	InvoicePayments.Currency.Code AS CurrencyCode,
	|	InvoicePayments.PaymentMethod AS PaymentMethod,
	|	InvoicePayments.PaymentMethod.SortCode AS PaymentMethodSortCode,
	|	InvoicePayments.PaymentMethod.Code AS PaymentMethodCode,
	|	InvoicePayments.Service AS Service,
	|	ISNULL(InvoicePayments.Service.Code, """") AS ServiceCode,
	|	SUM(InvoicePayments.Sum) AS Sum
	|FROM
	|	(SELECT
	|		1 AS Priority,
	|		CustomerAccounts.Folio AS Folio,
	|		CustomerAccounts.AccountingCurrency AS Currency,
	|		CustomerAccounts.PaymentMethod AS PaymentMethod,
	|		CustomerAccounts.Service AS Service,
	|		CASE
	|			WHEN CustomerAccounts.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CustomerAccounts.Sum
	|			ELSE -CustomerAccounts.Sum
	|		END AS Sum
	|	FROM
	|		AccumulationRegister.CustomerAccounts AS CustomerAccounts
	|	WHERE
	|		CustomerAccounts.Folio IN(&qFoliosList)
	|		AND CustomerAccounts.Recorder <> &qThisInvoice
	|		AND CustomerAccounts.PaymentMethod <> VALUE(Catalog.PaymentMethods.EmptyRef)
	|		AND CustomerAccounts.Recorder.PaymentMethod <> VALUE(Catalog.PaymentMethods.Settlement)
	|		AND CustomerAccounts.Recorder.PaymentMethod <> VALUE(Catalog.PaymentMethods.AdvanceSettlement)
	|		AND CustomerAccounts.PaymentMethod <> VALUE(Catalog.PaymentMethods.DepositTransfer)
	|		AND CustomerAccounts.Recorder IN(&qInvoicePaymentsList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		1,
	|		CustomerAccounts.Folio,
	|		CustomerAccounts.AccountingCurrency,
	|		CustomerAccounts.PaymentMethod,
	|		CustomerAccounts.Service,
	|		CASE
	|			WHEN CustomerAccounts.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CustomerAccounts.Sum
	|			ELSE -CustomerAccounts.Sum
	|		END
	|	FROM
	|		AccumulationRegister.CustomerAccounts AS CustomerAccounts
	|	WHERE
	|		CustomerAccounts.Folio IN(&qFoliosList)
	|		AND CustomerAccounts.Recorder <> &qThisInvoice
	|		AND CustomerAccounts.PaymentMethod <> VALUE(Catalog.PaymentMethods.EmptyRef)
	|		AND CustomerAccounts.Recorder.PaymentMethod <> VALUE(Catalog.PaymentMethods.Settlement)
	|		AND CustomerAccounts.Recorder.PaymentMethod <> VALUE(Catalog.PaymentMethods.AdvanceSettlement)
	|		AND CustomerAccounts.PaymentMethod <> VALUE(Catalog.PaymentMethods.DepositTransfer)
	|		AND CustomerAccounts.Recorder.Payment IN(&qInvoicePaymentsList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		2,
	|		CustomerAccounts.Folio,
	|		CustomerAccounts.AccountingCurrency,
	|		CustomerAccounts.PaymentMethod,
	|		CustomerAccounts.Service,
	|		CASE
	|			WHEN CustomerAccounts.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN CustomerAccounts.Sum
	|			ELSE -CustomerAccounts.Sum
	|		END
	|	FROM
	|		AccumulationRegister.CustomerAccounts AS CustomerAccounts
	|	WHERE
	|		CustomerAccounts.Folio IN(&qFoliosList)
	|		AND CustomerAccounts.Recorder <> &qThisInvoice
	|		AND CustomerAccounts.PaymentMethod <> VALUE(Catalog.PaymentMethods.EmptyRef)
	|		AND CustomerAccounts.Recorder.PaymentMethod <> VALUE(Catalog.PaymentMethods.Settlement)
	|		AND CustomerAccounts.Recorder.PaymentMethod <> VALUE(Catalog.PaymentMethods.AdvanceSettlement)
	|		AND CustomerAccounts.PaymentMethod <> VALUE(Catalog.PaymentMethods.DepositTransfer)
	|		AND NOT CustomerAccounts.Recorder IN (&qInvoicePaymentsList)
	|		AND NOT CustomerAccounts.Recorder.Payment IN (&qInvoicePaymentsList)) AS InvoicePayments
	|
	|GROUP BY
	|	InvoicePayments.Folio,
	|	InvoicePayments.Priority,
	|	InvoicePayments.Currency,
	|	InvoicePayments.Currency.Code,
	|	InvoicePayments.PaymentMethod,
	|	InvoicePayments.PaymentMethod.SortCode,
	|	InvoicePayments.PaymentMethod.Code,
	|	InvoicePayments.Service,
	|	ISNULL(InvoicePayments.Service.Code, """")
	|
	|ORDER BY
	|	Folio,
	|	Priority,
	|	Sum,
	|	CurrencyCode,
	|	PaymentMethodSortCode,
	|	PaymentMethodCode,
	|	ServiceCode";
	vQry.SetParameter("qFoliosList", pFoliosList);
	vQry.SetParameter("qThisInvoice", pInvoice);
	vQry.SetParameter("qInvoicePaymentsList", pPaymentsList);
	rPaymentAmounts = vQry.Execute().Unload();
	// Convert currencies
	For Each vPMsRow In rPaymentAmounts Do
		vPMsRow.Sum = cmConvertCurrencies(vPMsRow.Sum, vPMsRow.Currency, , pInvoice.AccountingCurrency, , pInvoice.Date, pInvoice.Hotel);
	EndDo;
	rPaymentAmounts.Columns.Delete("Currency");
	// Fill value table with payment method totals only
	rPaymentAmountsNoPriorityAndService = rPaymentAmounts.Copy();
	rPaymentAmountsNoPriorityAndService.GroupBy("Folio, PaymentMethod", "Sum");
EndProcedure // cmGetPaymentsForInvoiceTransactions

// -----------------------------------------------------------------------------
// Returns reservation payments by dates
// -----------------------------------------------------------------------------
Function cmGetReservationPayments(pRef, pGuestPayOnly) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccountsTurnovers.Period AS AccountingDate,
	|	AccountsTurnovers.FolioCurrency AS FolioCurrency,
	|	AccountsTurnovers.SumExpense AS SumExpense
	|FROM
	|	AccumulationRegister.Accounts.Turnovers(
	|			,
	|			,
	|			Day,
	|			(Folio.ParentDoc = &qRef
	|				OR Folio.ParentDoc.Reservation = &qRef
	|				OR Folio.ParentDoc = &qRefReservation
	|					AND &qRefReservationIsFilled)
	|				AND (NOT &qGuestPayOnly
	|					OR &qGuestPayOnly
	|						AND (Folio.Customer = VALUE(Catalog.Customers.EmptyRef)
	|							OR ISNULL(Folio.Customer.IsIndividual, FALSE)))) AS AccountsTurnovers
	|
	|ORDER BY
	|	AccountingDate";
	vQry.SetParameter("qRef", pRef);
	If TypeOf(pRef) = Type("DocumentRef.Accommodation") Then
		vQry.SetParameter("qRefReservation", pRef.Reservation);
		vQry.SetParameter("qRefReservationIsFilled", ValueIsFilled(pRef.Reservation));
	Else
		vQry.SetParameter("qRefReservation", Undefined);
		vQry.SetParameter("qRefReservationIsFilled", False);
	EndIf;
	vQry.SetParameter("qGuestPayOnly", pGuestPayOnly);
	vPayments = vQry.Execute().Unload();
	Return vPayments;
EndFunction // cmGetReservationPayments

// -----------------------------------------------------------------------------
// Checks if input string is of x/y format where x and y are numbers and y > x
// -----------------------------------------------------------------------------
Function cmParseFractionFormat(pFraction, rNominator = 0, rDenominator = 0) Export
	Try
		vSlashPos = StrFind(pFraction, "/");
		If vSlashPos = 0 Then
			Return False;
		EndIf;
		rNominator = Number(TrimAll(Left(pFraction, vSlashPos - 1)));
		rDenominator = Number(TrimAll(Mid(pFraction, vSlashPos + 1)));
		If rNominator <= 0 Or rDenominator <= 0 Then
			Return False;
		EndIf;
		If rDenominator <= rNominator Then
			Return False;
		EndIf;
		Return True;
	Except
		Return False;
	EndTry;
EndFunction // cmParseFractionFormat

// -----------------------------------------------------------------------------
// Function changes price according to the share percent specified
// -----------------------------------------------------------------------------
Function cmApplySharePercent(pPrice, pSharePercent) Export
	vPrice = pPrice;
	If vPrice = 0 Then
		Return vPrice;
	EndIf;
	vSharePercent = TrimAll(pSharePercent);
	If IsBlankString(vSharePercent) Then
		Return vPrice;
	EndIf;
	If cmIsNumber(vSharePercent) Then
		vPrice = Round(pPrice * Number(vSharePercent) / 100, 2);
	Else
		vNom = 0;
		vDenom = 0;
		If cmParseFractionFormat(vSharePercent, vNom, vDenom) Then
			If vDenom <> 0 Then
				vPrice = Round(pPrice * vNom / vDenom, 2);
			EndIf;
		EndIf;
	EndIf;
	Return vPrice;
EndFunction // cmApplySharePercent

// -----------------------------------------------------------------------------
Function cmHasRightsToEditInvoice(pCompany, pInvoiceDate, pExternalCode) Export
	vEditIsAllowed = True;
	If ValueIsFilled(pCompany) Then
		If pCompany.TaxAccountingPeriodType <> Enums.TaxAccountingPeriodTypes.None Then
			vCheckDate = '00010101';
			vTaxAccountingPeriodType = pCompany.TaxAccountingPeriodType;
			If vTaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Year Then
				vCheckDate = BegOfYear(CurrentSessionDate());
			ElsIf vTaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.HalfYear Then
				If CurrentSessionDate() < EndOfMonth(AddMonth(BegOfYear(CurrentSessionDate()), 5)) Then
					vCheckDate = BegOfYear(CurrentSessionDate());
				Else
					vCheckDate = AddMonth(BegOfYear(CurrentSessionDate()), 6);
				EndIf;
			ElsIf vTaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Quarter Then
				vCheckDate = BegOfQuarter(CurrentSessionDate());
			ElsIf vTaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Month Or 
			      Not ValueIsFilled(vTaxAccountingPeriodType) Then
				vCheckDate = BegOfMonth(CurrentSessionDate());
			ElsIf vTaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Decade Then
				vDay = Day(CurrentSessionDate());
				If vDay <= 10 Then
					vCheckDate = BegOfMonth(CurrentSessionDate());
				ElsIf vDay <= 20 Then
					vCheckDate = BegOfMonth(CurrentSessionDate()) + 11 * 24 * 3600;
				ElsIf vDay <= 31 Then
					vCheckDate = BegOfMonth(CurrentSessionDate()) + 21 * 24 * 3600;
				EndIf;
			EndIf;
			If pInvoiceDate < vCheckDate Then
				If Not cmCheckUserPermissions("HavePermissionToEditInvoicesCreatedInThePastAccountingPeriods") Then
					vEditIsAllowed = False;
				EndIf;
			Else
				If Not cmCheckUserPermissions("HavePermissionToEditInvoicesCreatedInTheCurrentAccountingPeriod") Then
					vEditIsAllowed = False;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If Not IsBlankString(pExternalCode) And Not cmCheckUserPermissions("HavePermissionToEditExportedSettlements") Then
		vEditIsAllowed = False;
	EndIf;
	Return vEditIsAllowed;
EndFunction // cmHasRightsToEditInvoice

// -----------------------------------------------------------------------------
Function cmGetTransactionsQueryText(pShowOrderItems = False) Export
	vTransactionsQryText = 
	"SELECT
	|	AllFolioMovements.Recorder AS Recorder,
	|	AllFolioMovements.Recorder.Number AS RecorderNumber,
	|	ISNULL(AllFolioMovements.Recorder.Quantity, 0) AS RecorderQuantity,
	|	AllFolioMovements.Recorder.ParentCharge AS RecorderParentCharge,
	|	Invoices.Ref AS RecorderInvoice,
	|	Invoices.Number AS RecorderInvoiceNumber,
	|	SUM(AllFolioMovements.Sum) AS Sum
	|INTO AllFolioRecorders
	|FROM
	|	AccumulationRegister.Accounts AS AllFolioMovements
	|		LEFT JOIN Document.Settlement AS Invoices
	|		ON AllFolioMovements.Recorder.Invoice = Invoices.Ref
	|WHERE
	|	AllFolioMovements.Folio = &qFolio
	|	AND &qShowInvoices
	|
	|GROUP BY
	|	AllFolioMovements.Recorder,
	|	ISNULL(AllFolioMovements.Recorder.Quantity, 0),
	|	Invoices.Ref,
	|	AllFolioMovements.Recorder.Number,
	|	AllFolioMovements.Recorder.ParentCharge,
	|	Invoices.Number
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoicePayments.PaymentDoc AS PaymentDoc,
	|	InvoicePayments.Ref AS Ref
	|INTO InvoicePayments
	|FROM
	|	Document.Settlement.PaymentDocuments AS InvoicePayments
	|		INNER JOIN AllFolioRecorders AS AllFolioRecorders
	|		ON InvoicePayments.PaymentDoc = AllFolioRecorders.Recorder
	|WHERE
	|	InvoicePayments.Ref.Posted
	|	AND CASE
	|			WHEN NOT InvoicePayments.PaymentDoc REFS Document.DepositTransfer
	|				THEN TRUE
	|			WHEN InvoicePayments.PaymentDoc REFS Document.DepositTransfer
	|					AND (AllFolioRecorders.Sum >= 0
	|							AND InvoicePayments.Sum >= 0
	|						OR AllFolioRecorders.Sum < 0
	|							AND InvoicePayments.Sum < 0)
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceServices.Charge AS Charge,
	|	InvoiceServices.Ref AS Ref
	|INTO InvoiceServices
	|FROM
	|	Document.Settlement.Services AS InvoiceServices
	|		INNER JOIN AllFolioRecorders AS AllFolioRecorders
	|		ON InvoiceServices.Charge = AllFolioRecorders.Recorder
	|			AND InvoiceServices.Quantity = AllFolioRecorders.RecorderQuantity
	|WHERE
	|	AllFolioRecorders.Recorder REFS Document.Charge
	|	AND InvoiceServices.Ref.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceStornos.Charge AS Charge,
	|	InvoiceStornos.Ref AS Ref
	|INTO InvoiceStornos
	|FROM
	|	Document.Settlement.Services AS InvoiceStornos
	|		INNER JOIN AllFolioRecorders AS AllFolioRecorders
	|		ON InvoiceStornos.Charge = AllFolioRecorders.RecorderParentCharge
	|WHERE
	|	AllFolioRecorders.Recorder REFS Document.Storno
	|	AND InvoiceStornos.Ref.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllFolioTransactions.Recorder AS Recorder,
	|	CASE
	|		WHEN AllFolioTransactions.Recorder REFS Document.Settlement
	|			THEN AllFolioTransactions.Recorder
	|		WHEN InvoicePayments.PaymentDoc IS NOT NULL 
	|			THEN InvoicePayments.Ref
	|		WHEN InvoiceServices.Charge IS NOT NULL 
	|			THEN InvoiceServices.Ref
	|		WHEN InvoiceStornos.Charge IS NOT NULL 
	|			THEN InvoiceStornos.Ref
	|		WHEN AllFolioTransactions.RecorderInvoice IS NOT NULL 
	|			THEN AllFolioTransactions.RecorderInvoice
	|	END AS Invoice,
	|	CASE
	|		WHEN AllFolioTransactions.Recorder REFS Document.Settlement
	|			THEN AllFolioTransactions.RecorderNumber
	|		WHEN InvoicePayments.PaymentDoc IS NOT NULL 
	|			THEN InvoicePayments.Ref.Number
	|		WHEN InvoiceServices.Charge IS NOT NULL 
	|			THEN InvoiceServices.Ref.Number
	|		WHEN InvoiceStornos.Charge IS NOT NULL 
	|			THEN InvoiceStornos.Ref.Number
	|		WHEN AllFolioTransactions.RecorderInvoice IS NOT NULL 
	|			THEN AllFolioTransactions.RecorderInvoiceNumber
	|	END AS InvoiceNumber
	|INTO AllFolioTransactions
	|FROM
	|	AllFolioRecorders AS AllFolioTransactions
	|		LEFT JOIN InvoicePayments AS InvoicePayments
	|		ON (InvoicePayments.PaymentDoc = AllFolioTransactions.Recorder)
	|		LEFT JOIN InvoiceServices AS InvoiceServices
	|		ON (InvoiceServices.Charge = AllFolioTransactions.Recorder)
	|		LEFT JOIN InvoiceStornos AS InvoiceStornos
	|		ON (InvoiceStornos.Charge = AllFolioTransactions.RecorderParentCharge)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TransactionLastInvoices.Recorder AS Recorder,
	|	MAX(TransactionLastInvoices.InvoiceNumber) AS MaxInvoiceNumber
	|INTO TransactionLastInvoices
	|FROM
	|	AllFolioTransactions AS TransactionLastInvoices
	|
	|GROUP BY
	|	TransactionLastInvoices.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FolioTransactionsWithInvoice.Recorder AS Recorder,
	|	FolioTransactionsWithInvoice.Invoice AS Invoice
	|INTO FolioTransactionsWithInvoice
	|FROM
	|	AllFolioTransactions AS FolioTransactionsWithInvoice
	|		INNER JOIN TransactionLastInvoices AS TransactionLastInvoices
	|		ON FolioTransactionsWithInvoice.Recorder = TransactionLastInvoices.Recorder
	|			AND FolioTransactionsWithInvoice.InvoiceNumber = TransactionLastInvoices.MaxInvoiceNumber
	|
	|GROUP BY
	|	FolioTransactionsWithInvoice.Recorder,
	|	FolioTransactionsWithInvoice.Invoice
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accounts.Recorder AS Recorder,
	|	Accounts.Period AS Period,
	|	Accounts.RecordType AS RecordType,
	|	Accounts.Folio AS Folio,
	|	Accounts.ParentDoc AS ParentDoc,
	|	Accounts.Charge AS Charge,
	|	Accounts.PaymentMethod AS PaymentMethod,
	|	Accounts.Sum AS Sum,
	|	Accounts.VATSum AS VATSum,
	|	Accounts.Limit AS Limit,
	|	Accounts.PaymentSection AS PaymentSection,
	|	CASE
	|		WHEN &qShowOrderItems
	|			THEN Accounts.ChequeService
	|		ELSE ISNULL(Charges.Service, VALUE(Catalog.Services.EmptyRef))
	|	END AS ChargeService,
	|	CASE
	|		WHEN &qShowOrderItems
	|			THEN Accounts.ChequeServicePrice
	|		ELSE ISNULL(Charges.Price, 0)
	|	END AS ChargePrice,
	|	CASE
	|		WHEN &qShowOrderItems
	|			THEN Accounts.ChequeServiceQuantity
	|		ELSE ISNULL(Charges.Quantity, 0)
	|	END AS ChargeQuantity,
	|	ISNULL(Charges.IsInPrice, FALSE) AS ChargeIsInPrice,
	|	ISNULL(Charges.IsRoomRevenue, FALSE) AS ChargeIsRoomRevenue,
	|	ISNULL(Charges.IsResourceRevenue, FALSE) AS ChargeIsResourceRevenue,
	|	ISNULL(Charges.RoomRevenueAmountsOnly, FALSE) AS ChargeRoomRevenueAmountsOnly,
	|	ISNULL(Charges.IsSplit, FALSE) AS ChargeIsSplit,
	|	ISNULL(Charges.IsFixedCharge, FALSE) AS ChargeIsFixedCharge,
	|	Charges.CalendarDayType AS ChargeCalendarDayType,
	|	Charges.Room AS ChargeRoom,
	|	Charges.Resource AS ChargeResource,
	|	Charges.VATRate AS ChargeVATRate,
	|	Charges.Performer AS ChargePerformer,
	|	Charges.RoomRate AS ChargeRoomRate,
	|	Charges.ParentDoc AS ChargeParentDoc,
	|	CASE
	|		WHEN &qShowOrderItems
	|			THEN Accounts.MarkingCode
	|		ELSE Charges.MarkingCode
	|	END AS MarkingCode,
	|	CASE
	|		WHEN &qShowOrderItems
	|			THEN Accounts.Item
	|		ELSE VALUE(Catalog.OrderItems.EmptyRef)
	|	END AS Item,
	|	ISNULL(Charges.DiscountSum, 0) AS ChargeDiscountSum
	|INTO AccountsWithCharges
	|FROM
	|	AccumulationRegister.Accounts AS Accounts
	|		LEFT JOIN Document.Charge AS Charges
	|		ON Accounts.Charge = Charges.Ref
	|WHERE
	|	Accounts.Folio = &qFolio
	|	AND CASE
	|			WHEN Accounts.Recorder REFS Document.CloseOfPeriod
	|				THEN FALSE
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qParentDocIsUndefined
	|				THEN TRUE
	|			ELSE Accounts.ParentDoc = &qParentDoc
	|		END
	|	AND CASE
	|			WHEN &qRecordersListIsUndefined
	|				THEN TRUE
	|			ELSE Accounts.Recorder IN (&qRecordersList)
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accounts.Recorder AS Recorder,
	|	Accounts.Period AS Period,
	|	Accounts.RecordType AS RecordType,
	|	Accounts.Folio AS Folio,
	|	Accounts.Folio.FolioCurrency AS FolioCurrency,
	|	Accounts.ParentDoc AS ParentDoc,
	|	Accounts.Charge AS Charge,
	|	Accounts.PaymentMethod AS PaymentMethod,
	|	Accounts.Sum AS Sum,
	|	Accounts.VATSum AS VATSum,
	|	Accounts.Limit AS Limit,
	|	Accounts.PaymentSection AS PaymentSection,
	|	ISNULL(Accounts.PaymentSection.Code, 0) AS PaymentSectionCode,
	|	Accounts.ChargeService AS ChargeService,
	|	Accounts.ChargePrice AS ChargePrice,
	|	Accounts.ChargeQuantity AS ChargeQuantity,
	|	Accounts.ChargeService.QuantityCalculationRule AS ChargeServiceQuantityCalculationRule,
	|	Accounts.ChargeIsInPrice AS ChargeIsInPrice,
	|	Accounts.ChargeIsRoomRevenue AS ChargeIsRoomRevenue,
	|	Accounts.ChargeIsResourceRevenue AS ChargeIsResourceRevenue,
	|	Accounts.ChargeRoomRevenueAmountsOnly AS ChargeRoomRevenueAmountsOnly,
	|	Accounts.ChargeIsSplit AS ChargeIsSplit,
	|	Accounts.ChargeIsFixedCharge AS ChargeIsFixedCharge,
	|	Accounts.ChargeCalendarDayType AS ChargeCalendarDayType,
	|	Accounts.ChargeRoom AS ChargeRoom,
	|	Accounts.ChargeResource AS ChargeResource,
	|	Accounts.ChargeVATRate AS ChargeVATRate,
	|	Accounts.ChargePerformer AS ChargePerformer,
	|	Accounts.ChargeRoomRate AS ChargeRoomRate,
	|	Accounts.ChargeParentDoc AS ChargeParentDoc,
	|	Accounts.ChargeDiscountSum AS ChargeDiscountSum,
	|	Accounts.MarkingCode AS MarkingCode,
	|	Accounts.Item AS Item,
	|	ISNULL(CASE
	|			WHEN Accounts.ParentDoc REFS Document.Accommodation
	|				THEN CAST(Accounts.ParentDoc AS Document.Accommodation).Number
	|			WHEN Accounts.ParentDoc REFS Document.Reservation
	|				THEN CAST(Accounts.ParentDoc AS Document.Reservation).Number
	|			WHEN Accounts.ParentDoc REFS Document.ResourceReservation
	|				THEN CAST(Accounts.ParentDoc AS Document.ResourceReservation).Number
	|			WHEN Accounts.ParentDoc REFS Document.Folio
	|				THEN CAST(Accounts.ParentDoc AS Document.Folio).Number
	|			WHEN Accounts.ParentDoc REFS Document.SetRoomQuota
	|				THEN CAST(Accounts.ParentDoc AS Document.SetRoomQuota).Number
	|			ELSE NULL
	|		END, ""999999999999"") AS ParentDocNumber,
	|	ISNULL(CASE
	|			WHEN Accounts.ParentDoc REFS Document.Accommodation
	|				THEN CAST(Accounts.ParentDoc AS Document.Accommodation).GuestGroup
	|			WHEN Accounts.ParentDoc REFS Document.Reservation
	|				THEN CAST(Accounts.ParentDoc AS Document.Reservation).GuestGroup
	|			WHEN Accounts.ParentDoc REFS Document.ResourceReservation
	|				THEN CAST(Accounts.ParentDoc AS Document.ResourceReservation).GuestGroup
	|			WHEN Accounts.ParentDoc REFS Document.Folio
	|				THEN CAST(Accounts.ParentDoc AS Document.Folio).GuestGroup
	|			ELSE NULL
	|		END, VALUE(Catalog.GuestGroups.EmptyRef)) AS ParentDocGuestGroup,
	|	ISNULL(CASE
	|			WHEN Accounts.ParentDoc REFS Document.Accommodation
	|				THEN CAST(Accounts.ParentDoc AS Document.Accommodation).AccommodationType
	|			WHEN Accounts.ParentDoc REFS Document.Reservation
	|				THEN CAST(Accounts.ParentDoc AS Document.Reservation).AccommodationType
	|			ELSE NULL
	|		END, VALUE(Catalog.AccommodationTypes.EmptyRef)) AS ParentDocAccommodationType,
	|	CASE
	|		WHEN Accounts.ParentDoc REFS Document.ResourceReservation
	|			THEN CAST(Accounts.ParentDoc AS Document.ResourceReservation).Client
	|		WHEN Accounts.ParentDoc REFS Document.Folio
	|			THEN CAST(Accounts.ParentDoc AS Document.Folio).Client
	|		ELSE NULL
	|	END AS ParentDocClient,
	|	CASE
	|		WHEN Accounts.ParentDoc REFS Document.Accommodation
	|			THEN CAST(Accounts.ParentDoc AS Document.Accommodation).Guest
	|		WHEN Accounts.ParentDoc REFS Document.Reservation
	|			THEN CAST(Accounts.ParentDoc AS Document.Reservation).Guest
	|		ELSE NULL
	|	END AS ParentDocGuest,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.Charge
	|				THEN CAST(Accounts.Recorder AS Document.Charge).Number
	|			WHEN Accounts.Recorder REFS Document.CreditNote
	|				THEN CAST(Accounts.Recorder AS Document.CreditNote).Number
	|			WHEN Accounts.Recorder REFS Document.DebitNote
	|				THEN CAST(Accounts.Recorder AS Document.DebitNote).Number
	|			WHEN Accounts.Recorder REFS Document.DepositTransfer
	|				THEN CAST(Accounts.Recorder AS Document.DepositTransfer).Number
	|			WHEN Accounts.Recorder REFS Document.Payment
	|				THEN CAST(Accounts.Recorder AS Document.Payment).Number
	|			WHEN Accounts.Recorder REFS Document.Preauthorisation
	|				THEN CAST(Accounts.Recorder AS Document.Preauthorisation).Number
	|			WHEN Accounts.Recorder REFS Document.Return
	|				THEN CAST(Accounts.Recorder AS Document.Return).Number
	|			WHEN Accounts.Recorder REFS Document.Settlement
	|				THEN CAST(Accounts.Recorder AS Document.Settlement).Number
	|			WHEN Accounts.Recorder REFS Document.Storno
	|				THEN CAST(Accounts.Recorder AS Document.Storno).Number
	|			ELSE NULL
	|		END, """") AS RecorderNumber,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.Charge
	|				THEN CAST(Accounts.Recorder AS Document.Charge).Date
	|			WHEN Accounts.Recorder REFS Document.CreditNote
	|				THEN CAST(Accounts.Recorder AS Document.CreditNote).Date
	|			WHEN Accounts.Recorder REFS Document.DebitNote
	|				THEN CAST(Accounts.Recorder AS Document.DebitNote).Date
	|			WHEN Accounts.Recorder REFS Document.DepositTransfer
	|				THEN CAST(Accounts.Recorder AS Document.DepositTransfer).Date
	|			WHEN Accounts.Recorder REFS Document.Payment
	|				THEN CAST(Accounts.Recorder AS Document.Payment).Date
	|			WHEN Accounts.Recorder REFS Document.Preauthorisation
	|				THEN CAST(Accounts.Recorder AS Document.Preauthorisation).Date
	|			WHEN Accounts.Recorder REFS Document.Return
	|				THEN CAST(Accounts.Recorder AS Document.Return).Date
	|			WHEN Accounts.Recorder REFS Document.Settlement
	|				THEN CAST(Accounts.Recorder AS Document.Settlement).Date
	|			WHEN Accounts.Recorder REFS Document.Storno
	|				THEN CAST(Accounts.Recorder AS Document.Storno).Date
	|			ELSE NULL
	|		END, &qEmptyDate) AS RecorderDate,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.Charge
	|				THEN CAST(Accounts.Recorder AS Document.Charge).IsCorrection
	|			ELSE NULL
	|		END, FALSE) AS RecorderIsCorrection,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.Charge
	|				THEN CAST(Accounts.Recorder AS Document.Charge).IsAdditional
	|			WHEN Accounts.Recorder REFS Document.Storno
	|				THEN CAST(Accounts.Recorder AS Document.Storno).IsAdditional
	|			ELSE NULL
	|		END, FALSE) AS RecorderIsAdditional,
	|	CAST(ISNULL(CASE
	|				WHEN Accounts.Recorder REFS Document.Charge
	|					THEN CAST(Accounts.Recorder AS Document.Charge).Remarks
	|				WHEN Accounts.Recorder REFS Document.CreditNote
	|					THEN CAST(Accounts.Recorder AS Document.CreditNote).Remarks
	|				WHEN Accounts.Recorder REFS Document.DebitNote
	|					THEN CAST(Accounts.Recorder AS Document.DebitNote).Remarks
	|				WHEN Accounts.Recorder REFS Document.DepositTransfer
	|					THEN CAST(Accounts.Recorder AS Document.DepositTransfer).Remarks
	|				WHEN Accounts.Recorder REFS Document.Payment
	|					THEN CAST(Accounts.Recorder AS Document.Payment).Remarks
	|				WHEN Accounts.Recorder REFS Document.Preauthorisation
	|					THEN CAST(Accounts.Recorder AS Document.Preauthorisation).Remarks
	|				WHEN Accounts.Recorder REFS Document.Return
	|					THEN CAST(Accounts.Recorder AS Document.Return).Remarks
	|				WHEN Accounts.Recorder REFS Document.Settlement
	|					THEN CAST(Accounts.Recorder AS Document.Settlement).Remarks
	|				WHEN Accounts.Recorder REFS Document.Storno
	|					THEN CAST(Accounts.Recorder AS Document.Storno).Remarks
	|				ELSE NULL
	|			END, """") AS STRING(256)) AS RecorderRemarks,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.DepositTransfer
	|				THEN CAST(Accounts.Recorder AS Document.DepositTransfer).FolioFrom
	|			ELSE NULL
	|		END, VALUE(Document.Folio.EmptyRef)) AS RecorderFolioFrom,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.DepositTransfer
	|				THEN CAST(Accounts.Recorder AS Document.DepositTransfer).FolioTo
	|			ELSE NULL
	|		END, VALUE(Document.Folio.EmptyRef)) AS RecorderFolioTo,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.Charge
	|				THEN CAST(Accounts.Recorder AS Document.Charge).PaymentSection
	|			WHEN Accounts.Recorder REFS Document.CreditNote
	|				THEN CAST(Accounts.Recorder AS Document.CreditNote).PaymentSection
	|			WHEN Accounts.Recorder REFS Document.DebitNote
	|				THEN CAST(Accounts.Recorder AS Document.DebitNote).PaymentSection
	|			WHEN Accounts.Recorder REFS Document.DepositTransfer
	|				THEN CAST(Accounts.Recorder AS Document.DepositTransfer).PaymentSection
	|			WHEN Accounts.Recorder REFS Document.Payment
	|				THEN CAST(Accounts.Recorder AS Document.Payment).PaymentSection
	|			WHEN Accounts.Recorder REFS Document.Return
	|				THEN CAST(Accounts.Recorder AS Document.Return).PaymentSection
	|			WHEN Accounts.Recorder REFS Document.Settlement
	|				THEN CAST(Accounts.Recorder AS Document.Settlement).PaymentSection
	|			ELSE NULL
	|		END, VALUE(Catalog.PaymentSections.EmptyRef)) AS RecorderPaymentSection,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.Storno
	|				THEN CAST(Accounts.Recorder AS Document.Storno).ParentCharge
	|			ELSE NULL
	|		END, VALUE(Document.Charge.EmptyRef)) AS RecorderParentCharge,
	|	CASE
	|		WHEN Accounts.Recorder REFS Document.Payment
	|			THEN CAST(Accounts.Recorder AS Document.Payment).Payer
	|		WHEN Accounts.Recorder REFS Document.Preauthorisation
	|			THEN CAST(Accounts.Recorder AS Document.Preauthorisation).Payer
	|		WHEN Accounts.Recorder REFS Document.Return
	|			THEN CAST(Accounts.Recorder AS Document.Return).Payer
	|		ELSE NULL
	|	END AS RecorderPayer,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.Charge
	|				THEN CAST(Accounts.Recorder AS Document.Charge).ServiceDate
	|			ELSE NULL
	|		END, &qEmptyDate) AS RecorderServiceDate,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.Charge
	|				THEN CAST(Accounts.Recorder AS Document.Charge).CorrectionDate
	|			ELSE NULL
	|		END, &qEmptyDate) AS RecorderCorrectionDate,
	|	ISNULL(CASE
	|			WHEN Accounts.Recorder REFS Document.Charge
	|				THEN CAST(Accounts.Recorder AS Document.Charge).CorrectedCharge
	|			ELSE NULL
	|		END, VALUE(Document.Charge.EmptyRef)) AS RecorderCorrectedCharge
	|INTO RawAccounts
	|FROM
	|	AccountsWithCharges AS Accounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP AccountsWithCharges
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FolioTransactions.Document AS Document,
	|	PaymentMethods.Ref AS DocumentPaymentMethod,
	|	ISNULL(PaymentMethods.IsByCreditCard, FALSE) AS DocumentPaymentMethodIsByCreditCard,
	|	CASE
	|		WHEN FolioTransactions.Document REFS Document.Payment
	|			THEN CAST(FolioTransactions.Document AS Document.Payment).TerminalNumber
	|		WHEN FolioTransactions.Document REFS Document.Return
	|			THEN CAST(FolioTransactions.Document AS Document.Return).TerminalNumber
	|		WHEN FolioTransactions.Document REFS Document.Preauthorisation
	|			THEN CAST(FolioTransactions.Document AS Document.Preauthorisation).TerminalNumber
	|		ELSE NULL
	|	END AS DocumentTerminalNumber,
	|	CASE
	|		WHEN FolioTransactions.Document REFS Document.Payment
	|			THEN CAST(FolioTransactions.Document AS Document.Payment).ReferenceNumber
	|		WHEN FolioTransactions.Document REFS Document.Return
	|			THEN CAST(FolioTransactions.Document AS Document.Return).ReferenceNumber
	|		WHEN FolioTransactions.Document REFS Document.Preauthorisation
	|			THEN CAST(FolioTransactions.Document AS Document.Preauthorisation).ReferenceNumber
	|		ELSE NULL
	|	END AS DocumentReferenceNumber,
	|	CASE
	|		WHEN FolioTransactions.Document REFS Document.Payment
	|			THEN CAST(FolioTransactions.Document AS Document.Payment).AuthorizationCode
	|		WHEN FolioTransactions.Document REFS Document.Return
	|			THEN CAST(FolioTransactions.Document AS Document.Return).AuthorizationCode
	|		WHEN FolioTransactions.Document REFS Document.Preauthorisation
	|			THEN CAST(FolioTransactions.Document AS Document.Preauthorisation).AuthorizationCode
	|		ELSE NULL
	|	END AS DocumentAuthorizationCode,
	|	CASE
	|		WHEN FolioTransactions.Document REFS Document.Charge
	|			THEN CAST(FolioTransactions.Document AS Document.Charge).PaymentSection
	|		WHEN FolioTransactions.Document REFS Document.Settlement
	|			THEN CAST(FolioTransactions.Document AS Document.Settlement).PaymentSection
	|		WHEN FolioTransactions.Document REFS Document.CreditNote
	|			THEN CAST(FolioTransactions.Document AS Document.CreditNote).PaymentSection
	|		WHEN FolioTransactions.Document REFS Document.DebitNote
	|			THEN CAST(FolioTransactions.Document AS Document.DebitNote).PaymentSection
	|		WHEN FolioTransactions.Document REFS Document.Payment
	|			THEN CAST(FolioTransactions.Document AS Document.Payment).PaymentSection
	|		WHEN FolioTransactions.Document REFS Document.Return
	|			THEN CAST(FolioTransactions.Document AS Document.Return).PaymentSection
	|		ELSE NULL
	|	END AS DocumentPaymentSection,
	|	CASE
	|		WHEN FolioTransactions.Document REFS Document.Charge
	|			THEN CAST(FolioTransactions.Document AS Document.Charge).DiscountCard
	|		WHEN FolioTransactions.Document REFS Document.Payment
	|			THEN CAST(FolioTransactions.Document AS Document.Payment).DiscountCard
	|		WHEN FolioTransactions.Document REFS Document.Return
	|			THEN CAST(FolioTransactions.Document AS Document.Return).DiscountCard
	|		ELSE NULL
	|	END AS DocumentDiscountCard,
	|	CASE
	|		WHEN FolioTransactions.Document REFS Document.Charge
	|			THEN CAST(FolioTransactions.Document AS Document.Charge).Sum
	|		WHEN FolioTransactions.Document REFS Document.Storno
	|			THEN CAST(FolioTransactions.Document AS Document.Storno).Sum
	|		WHEN FolioTransactions.Document REFS Document.Payment
	|			THEN CAST(FolioTransactions.Document AS Document.Payment).Sum
	|		WHEN FolioTransactions.Document REFS Document.Return
	|			THEN CAST(FolioTransactions.Document AS Document.Return).Sum
	|		WHEN FolioTransactions.Document REFS Document.Preauthorisation
	|			THEN CAST(FolioTransactions.Document AS Document.Preauthorisation).Sum
	|		ELSE NULL
	|	END AS DocumentSum,
	|	FolioTransactions.FolioCurrency AS DocumentFolioCurrency,
	|	CASE
	|		WHEN Clients.Ref IS NULL
	|			THEN Customers.Ref
	|		ELSE Clients.Ref
	|	END AS DocumentPayer,
	|	ISNULL(CASE
	|			WHEN Clients.Ref IS NULL
	|				THEN Customers.Description
	|			ELSE Clients.Description
	|		END, """") AS DocumentPayerDescription,
	|	FoliosFrom.Ref AS DocumentFolioFrom,
	|	FoliosFrom.Room AS DocumentFolioFromRoom,
	|	FoliosFrom.Client AS DocumentFolioFromClient,
	|	FoliosFrom.Customer AS DocumentFolioFromCustomer,
	|	FoliosFrom.Number AS DocumentFolioFromNumber,
	|	FoliosTo.Ref AS DocumentFolioTo,
	|	FoliosTo.Room AS DocumentFolioToRoom,
	|	FoliosTo.Client AS DocumentFolioToClient,
	|	FoliosTo.Customer AS DocumentFolioToCustomer,
	|	ISNULL(FoliosTo.Number, """") AS DocumentFolioToNumber,
	|	FolioTransactions.Charge AS Charge,
	|	FolioTransactions.RecordType AS RecordType,
	|	FolioTransactions.Folio AS Folio,
	|	FolioTransactions.Folio.ParentDoc AS FolioParentDoc,
	|	FolioTransactions.ChargeParentDoc AS ChargeParentDoc,
	|	FolioTransactions.GuestGroupCode AS GuestGroupCode,
	|	FolioTransactions.ReservationNumber AS ReservationNumber,
	|	FolioTransactions.Folio.Client AS FolioClient,
	|	FolioTransactions.PaymentSection AS PaymentSection,
	|	FolioTransactions.PaymentSectionCode AS PaymentSectionCode,
	|	FolioTransactions.Service AS Service,
	|	FolioTransactions.Service.SortCode AS ServiceSortCode,
	|	FolioTransactions.Service.Code AS ServiceCode,
	|	FolioTransactions.Service.Description AS ServiceDescription,
	|	FolioTransactions.Service.IsInPrice AS ServiceIsInprice,
	|	FolioTransactions.Service.IsRoomRevenue AS ServiceIsRoomRevenue,
	|	FolioTransactions.Service.IsResourceRevenue AS ServiceIsResourceRevenue,
	|	FolioTransactions.Service.RoomRevenueAmountsOnly AS ServiceRoomRevenueAmountsOnly,
	|	FolioTransactions.NettoPrice AS NettoPrice,
	|	FolioTransactions.Period AS Period,
	|	FolioTransactions.AccountingDate AS AccountingDate,
	|	FolioTransactions.AccountingMonth AS AccountingMonth,
	|	FolioTransactions.ServiceDate AS ServiceDate,
	|	FolioTransactions.CorrectedServiceDate AS CorrectedServiceDate,
	|	FolioTransactions.Remarks AS Remarks,
	|	FolioTransactions.PaymentMethod AS PaymentMethod,
	|	FolioTransactions.PaymentMethod.SortCode AS PaymentMethodSortCode,
	|	FolioTransactions.PaymentMethod.Code AS PaymentMethodCode,
	|	FolioTransactions.PaymentMethod.Description AS PaymentMethodDescription,
	|	FolioTransactions.RecorderNumber AS RecorderNumber,
	|	FolioTransactions.Payer AS Payer,
	|	FolioTransactions.IsRoomRevenue AS IsRoomRevenue,
	|	FolioTransactions.IsInPrice AS IsInPrice,
	|	FolioTransactions.IsSplit AS IsSplit,
	|	FolioTransactions.CalendarDayType AS CalendarDayType,
	|	FolioTransactions.Room AS Room,
	|	FolioTransactions.Resource AS Resource,
	|	FolioTransactions.VATRate AS VATRate,
	|	FolioTransactions.Performer AS Performer,
	|	ISNULL(FolioTransactions.Room.SortCode, 99999999) AS RoomSortCode,
	|	ISNULL(FolioTransactions.Resource.SortCode, 0) AS ResourceSortCode,
	|	FolioTransactions.AccommodationType AS AccommodationType,
	|	ISNULL(FolioTransactions.AccommodationType.SortCode, 99999999) AS AccommodationTypeSortCode,
	|	ISNULL(FolioTransactions.AccommodationType.Description, """") AS AccommodationTypeDescription,
	|	FolioTransactions.Client AS Client,
	|	ISNULL(FolioTransactions.Client.FullName, """") AS ClientFullName,
	|	FolioTransactions.RoomRate AS RoomRate,
	|	FolioTransactions.RoomRate.Code AS RoomRateCode,
	|	ISNULL(FolioTransactions.RoomRate.Description, """") AS RoomRateDescription,
	|	FolioTransactions.MarkingCode AS MarkingCode,
	|	FolioTransactions.Item AS Item,
	|	FolioTransactions.Item.Code AS ItemCode,
	|	FolioTransactions.Item.Description AS ItemDescription,
	|	FolioTransactions.IsCorrection AS IsCorrection,
	|	FolioTransactions.IsStorno AS IsStorno,
	|	FolioTransactions.Invoice AS Invoice,
	|	FolioTransactions.Price AS Price,
	|	FolioTransactions.Discount AS Discount,
	|	FolioTransactions.Sum AS Sum,
	|	FolioTransactions.VATSum AS VATSum,
	|	FolioTransactions.Quantity AS Quantity,
	|	FolioTransactions.Limit AS Limit,
	|	FolioTransactions.PaymentSum AS PaymentSum
	|FROM
	|	(SELECT
	|		FolioTransactionsWithDuplicates.Document AS Document,
	|		FolioTransactionsWithDuplicates.Charge AS Charge,
	|		FolioTransactionsWithDuplicates.RecordType AS RecordType,
	|		FolioTransactionsWithDuplicates.Folio AS Folio,
	|		FolioTransactionsWithDuplicates.FolioCurrency AS FolioCurrency,
	|		FolioTransactionsWithDuplicates.FolioFrom AS FolioFrom,
	|		FolioTransactionsWithDuplicates.FolioTo AS FolioTo,
	|		FolioTransactionsWithDuplicates.ChargeParentDoc AS ChargeParentDoc,
	|		FolioTransactionsWithDuplicates.GuestGroupCode AS GuestGroupCode,
	|		FolioTransactionsWithDuplicates.ReservationNumber AS ReservationNumber,
	|		FolioTransactionsWithDuplicates.PaymentSection AS PaymentSection,
	|		FolioTransactionsWithDuplicates.PaymentSectionCode AS PaymentSectionCode,
	|		FolioTransactionsWithDuplicates.Service AS Service,
	|		FolioTransactionsWithDuplicates.NettoPrice AS NettoPrice,
	|		FolioTransactionsWithDuplicates.Period AS Period,
	|		FolioTransactionsWithDuplicates.AccountingDate AS AccountingDate,
	|		FolioTransactionsWithDuplicates.AccountingMonth AS AccountingMonth,
	|		FolioTransactionsWithDuplicates.ServiceDate AS ServiceDate,
	|		FolioTransactionsWithDuplicates.CorrectedServiceDate AS CorrectedServiceDate,
	|		FolioTransactionsWithDuplicates.Remarks AS Remarks,
	|		FolioTransactionsWithDuplicates.PaymentMethod AS PaymentMethod,
	|		FolioTransactionsWithDuplicates.RecorderNumber AS RecorderNumber,
	|		FolioTransactionsWithDuplicates.Payer AS Payer,
	|		FolioTransactionsWithDuplicates.IsInPrice AS IsInPrice,
	|		FolioTransactionsWithDuplicates.IsRoomRevenue AS IsRoomRevenue,
	|		FolioTransactionsWithDuplicates.IsResourceRevenue AS IsResourceRevenue,
	|		FolioTransactionsWithDuplicates.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
	|		FolioTransactionsWithDuplicates.IsSplit AS IsSplit,
	|		FolioTransactionsWithDuplicates.CalendarDayType AS CalendarDayType,
	|		FolioTransactionsWithDuplicates.Room AS Room,
	|		FolioTransactionsWithDuplicates.Resource AS Resource,
	|		FolioTransactionsWithDuplicates.VATRate AS VATRate,
	|		FolioTransactionsWithDuplicates.Performer AS Performer,
	|		FolioTransactionsWithDuplicates.AccommodationType AS AccommodationType,
	|		FolioTransactionsWithDuplicates.Client AS Client,
	|		FolioTransactionsWithDuplicates.RoomRate AS RoomRate,
	|		FolioTransactionsWithDuplicates.MarkingCode AS MarkingCode,
	|		FolioTransactionsWithDuplicates.Item AS Item,
	|		FolioTransactionsWithDuplicates.IsCorrection AS IsCorrection,
	|		FolioTransactionsWithDuplicates.IsStorno AS IsStorno,
	|		FolioTransactionsWithDuplicates.Invoice AS Invoice,
	|		MAX(FolioTransactionsWithDuplicates.Price) AS Price,
	|		SUM(FolioTransactionsWithDuplicates.Discount) AS Discount,
	|		SUM(FolioTransactionsWithDuplicates.Sum) AS Sum,
	|		SUM(FolioTransactionsWithDuplicates.VATSum) AS VATSum,
	|		SUM(FolioTransactionsWithDuplicates.Quantity) AS Quantity,
	|		SUM(FolioTransactionsWithDuplicates.Limit) AS Limit,
	|		SUM(FolioTransactionsWithDuplicates.PaymentSum) AS PaymentSum
	|	FROM
	|		(SELECT
	|			CASE
	|				WHEN &qHideCorrections
	|						AND Accounts.RecorderIsCorrection
	|						AND Accounts.RecorderCorrectedCharge <> &qEmptyCharge
	|					THEN Accounts.RecorderCorrectedCharge
	|				WHEN &qHideCorrections
	|						AND Accounts.Recorder REFS Document.Storno
	|					THEN Accounts.RecorderParentCharge
	|				ELSE Accounts.Recorder
	|			END AS Document,
	|			CASE
	|				WHEN &qHideCorrections
	|						AND Accounts.RecorderIsCorrection
	|						AND Accounts.RecorderCorrectedCharge <> &qEmptyCharge
	|					THEN Accounts.RecorderCorrectedCharge
	|				WHEN &qHideCorrections
	|						AND Accounts.Recorder REFS Document.Storno
	|					THEN Accounts.RecorderParentCharge
	|				ELSE Accounts.Charge
	|			END AS Charge,
	|			Accounts.RecordType AS RecordType,
	|			Accounts.Folio AS Folio,
	|			Accounts.FolioCurrency AS FolioCurrency,
	|			Accounts.RecorderFolioFrom AS FolioFrom,
	|			Accounts.RecorderFolioTo AS FolioTo,
	|			Accounts.ChargeParentDoc AS ChargeParentDoc,
	|			Accounts.ParentDocGuestGroupCode AS GuestGroupCode,
	|			Accounts.ParentDocNumber AS ReservationNumber,
	|			CASE
	|				WHEN Accounts.RecordType = &qExpense
	|					THEN Accounts.RecorderPaymentSection
	|				ELSE Accounts.PaymentSection
	|			END AS PaymentSection,
	|			CASE
	|				WHEN Accounts.RecordType = &qExpense
	|					THEN Accounts.RecorderPaymentSectionCode
	|				ELSE Accounts.PaymentSectionCode
	|			END AS PaymentSectionCode,
	|			CASE
	|				WHEN Accounts.RecordType = &qExpense
	|					THEN NULL
	|				ELSE Accounts.ChargeService
	|			END AS Service,
	|			CASE
	|				WHEN &qHideCorrections
	|						AND Accounts.RecorderIsCorrection
	|						AND Accounts.RecorderCorrectedCharge <> &qEmptyCharge
	|					THEN Accounts.RecorderCorrectedChargePrice
	|				ELSE Accounts.ChargePrice
	|			END AS NettoPrice,
	|			CASE
	|				WHEN &qHideCorrections
	|						AND Accounts.RecorderIsCorrection
	|					THEN Accounts.RecorderCorrectionDate
	|				WHEN &qHideCorrections
	|						AND Accounts.Recorder REFS Document.Storno
	|					THEN Accounts.RecorderParentChargeDate
	|				ELSE Accounts.RecorderDate
	|			END AS Period,
	|			CASE
	|				WHEN Accounts.RecorderIsCorrection
	|					THEN BEGINOFPERIOD(Accounts.RecorderCorrectionDate, DAY)
	|				WHEN Accounts.Recorder REFS Document.Storno
	|					THEN BEGINOFPERIOD(Accounts.RecorderParentChargeDate, DAY)
	|				ELSE BEGINOFPERIOD(Accounts.Period, DAY)
	|			END AS AccountingDate,
	|			CASE
	|				WHEN Accounts.RecorderIsCorrection
	|					THEN BEGINOFPERIOD(Accounts.RecorderCorrectionDate, MONTH)
	|				WHEN Accounts.Recorder REFS Document.Storno
	|					THEN BEGINOFPERIOD(Accounts.RecorderParentChargeDate, MONTH)
	|				ELSE BEGINOFPERIOD(Accounts.Period, MONTH)
	|			END AS AccountingMonth,
	|			CASE
	|				WHEN Accounts.RecorderServiceDate <> &qEmptyDate
	|					THEN BEGINOFPERIOD(Accounts.RecorderServiceDate, DAY)
	|				WHEN &qHideCorrections
	|						AND Accounts.RecorderIsCorrection
	|					THEN BEGINOFPERIOD(Accounts.RecorderCorrectedChargeServiceDate, DAY)
	|				WHEN &qHideCorrections
	|						AND Accounts.Recorder REFS Document.Storno
	|					THEN BEGINOFPERIOD(Accounts.RecorderParentChargeServiceDate, DAY)
	|				ELSE BEGINOFPERIOD(Accounts.Period, DAY)
	|			END AS ServiceDate,
	|			CASE
	|				WHEN Accounts.RecordType <> &qExpense
	|						AND Accounts.ChargeServiceQuantityCalculationRuleType = VALUE(Enum.QuantityCalculationRuleTypes.Breakfast)
	|					THEN CASE
	|							WHEN Accounts.RecorderIsCorrection
	|									AND NOT ISNULL(Accounts.RecorderCorrectedChargeIsAdditional, TRUE)
	|								THEN DATEADD(BEGINOFPERIOD(Accounts.RecorderCorrectedChargeDate, DAY), DAY, -1)
	|							WHEN ISNULL(Accounts.Recorder.IsCorrection, FALSE)
	|									AND ISNULL(Accounts.RecorderCorrectedChargeIsAdditional, FALSE)
	|								THEN DATEADD(BEGINOFPERIOD(Accounts.RecorderCorrectedChargeServiceDate, DAY), DAY, -1)
	|							WHEN Accounts.Recorder REFS Document.Storno
	|									AND NOT ISNULL(Accounts.RecorderParentChargeIsAdditional, TRUE)
	|								THEN DATEADD(BEGINOFPERIOD(Accounts.RecorderParentChargeDate, DAY), DAY, -1)
	|							WHEN Accounts.Recorder REFS Document.Storno
	|									AND ISNULL(Accounts.RecorderParentChargeIsAdditional, FALSE)
	|								THEN DATEADD(BEGINOFPERIOD(Accounts.RecorderParentChargeServiceDate, DAY), DAY, -1)
	|							WHEN Accounts.Recorder REFS Document.Charge
	|									AND NOT ISNULL(Accounts.RecorderIsAdditional, TRUE)
	|								THEN DATEADD(BEGINOFPERIOD(Accounts.RecorderDate, DAY), DAY, -1)
	|							WHEN Accounts.Recorder REFS Document.Charge
	|									AND ISNULL(Accounts.RecorderIsAdditional, FALSE)
	|								THEN DATEADD(BEGINOFPERIOD(Accounts.RecorderServiceDate, DAY), DAY, -1)
	|							ELSE BEGINOFPERIOD(Accounts.Period, DAY)
	|						END
	|				WHEN Accounts.RecordType <> &qExpense
	|						AND Accounts.ChargeServiceQuantityCalculationRuleType = VALUE(Enum.QuantityCalculationRuleTypes.BreakfastServiceDateShift)
	|					THEN CASE
	|							WHEN Accounts.RecorderIsCorrection
	|									AND BEGINOFPERIOD(Accounts.RecorderCorrectedChargeServiceDate, DAY) <> BEGINOFPERIOD(Accounts.RecorderCorrectedChargeDate, DAY)
	|								THEN DATEADD(BEGINOFPERIOD(Accounts.RecorderCorrectedChargeServiceDate, DAY), DAY, -1)
	|							WHEN Accounts.RecorderIsCorrection
	|									AND BEGINOFPERIOD(Accounts.RecorderCorrectedChargeServiceDate, DAY) = BEGINOFPERIOD(Accounts.RecorderCorrectedChargeDate, DAY)
	|								THEN BEGINOFPERIOD(Accounts.RecorderCorrectedChargeServiceDate, DAY)
	|							WHEN Accounts.Recorder REFS Document.Storno
	|									AND BEGINOFPERIOD(Accounts.RecorderParentChargeServiceDate, DAY) <> BEGINOFPERIOD(Accounts.RecorderParentChargeDate, DAY)
	|								THEN DATEADD(BEGINOFPERIOD(Accounts.RecorderParentChargeServiceDate, DAY), DAY, -1)
	|							WHEN Accounts.Recorder REFS Document.Storno
	|									AND BEGINOFPERIOD(Accounts.RecorderParentChargeServiceDate, DAY) = BEGINOFPERIOD(Accounts.RecorderParentChargeDate, DAY)
	|								THEN BEGINOFPERIOD(Accounts.RecorderParentChargeServiceDate, DAY)
	|							WHEN Accounts.Recorder REFS Document.Charge
	|									AND BEGINOFPERIOD(Accounts.RecorderServiceDate, DAY) <> BEGINOFPERIOD(Accounts.RecorderDate, DAY)
	|								THEN DATEADD(BEGINOFPERIOD(Accounts.Recorder.ServiceDate, DAY), DAY, -1)
	|							WHEN Accounts.Recorder REFS Document.Charge
	|									AND BEGINOFPERIOD(Accounts.RecorderServiceDate, DAY) = BEGINOFPERIOD(Accounts.RecorderDate, DAY)
	|								THEN BEGINOFPERIOD(Accounts.RecorderServiceDate, DAY)
	|							ELSE BEGINOFPERIOD(Accounts.Period, DAY)
	|						END
	|				ELSE CASE
	|						WHEN Accounts.RecorderIsCorrection
	|							THEN BEGINOFPERIOD(Accounts.RecorderCorrectedChargeServiceDate, DAY)
	|						WHEN Accounts.Recorder REFS Document.Storno
	|							THEN BEGINOFPERIOD(Accounts.RecorderParentChargeServiceDate, DAY)
	|						WHEN Accounts.Recorder REFS Document.Charge
	|							THEN BEGINOFPERIOD(Accounts.RecorderServiceDate, DAY)
	|						ELSE BEGINOFPERIOD(Accounts.Period, DAY)
	|					END
	|			END AS CorrectedServiceDate,
	|			CASE
	|				WHEN &qHideCorrections
	|						AND Accounts.RecorderIsCorrection
	|						AND Accounts.RecorderCorrectedCharge <> &qEmptyCharge
	|					THEN Accounts.RecorderCorrectedChargeRemarks
	|				WHEN &qHideCorrections
	|						AND Accounts.Recorder REFS Document.Storno
	|					THEN Accounts.RecorderParentChargeRemarks
	|				ELSE Accounts.RecorderRemarks
	|			END AS Remarks,
	|			Accounts.PaymentMethod AS PaymentMethod,
	|			CASE
	|				WHEN &qHideCorrections
	|						AND Accounts.RecorderIsCorrection
	|						AND Accounts.RecorderCorrectedCharge <> &qEmptyCharge
	|					THEN Accounts.RecorderCorrectedChargeNumber
	|				WHEN &qHideCorrections
	|						AND Accounts.Recorder REFS Document.Storno
	|					THEN Accounts.RecorderParentChargeNumber
	|				ELSE Accounts.RecorderNumber
	|			END AS RecorderNumber,
	|			Accounts.RecorderPayer AS Payer,
	|			Accounts.ChargeIsInPrice AS IsInPrice,
	|			Accounts.ChargeIsRoomRevenue AS IsRoomRevenue,
	|			Accounts.ChargeIsResourceRevenue AS IsResourceRevenue,
	|			Accounts.ChargeRoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
	|			Accounts.ChargeIsSplit AS IsSplit,
	|			Accounts.ChargeCalendarDayType AS CalendarDayType,
	|			Accounts.ChargeRoom AS Room,
	|			Accounts.ChargeResource AS Resource,
	|			CASE
	|				WHEN Accounts.RecordType = &qExpense
	|					THEN NULL
	|				ELSE Accounts.ChargeVATRate
	|			END AS VATRate,
	|			CASE
	|				WHEN NOT Accounts.ChargeIsFixedCharge
	|					THEN Accounts.ChargePerformer
	|				ELSE &qEmptyEmployee
	|			END AS Performer,
	|			Accounts.ParentDocAccommodationType AS AccommodationType,
	|			CASE
	|				WHEN Accounts.ParentDocClient IS NULL
	|					THEN Accounts.ParentDocGuest
	|				ELSE Accounts.ParentDocClient
	|			END AS Client,
	|			Accounts.ChargeRoomRate AS RoomRate,
	|			CASE
	|				WHEN &qHideCorrections
	|						AND NOT &qShowOrderItems
	|						AND Accounts.RecorderIsCorrection
	|						AND Accounts.RecorderCorrectedCharge <> &qEmptyCharge
	|					THEN ISNULL(Accounts.RecorderCorrectedChargeMarkingCode, """")
	|				WHEN &qHideCorrections
	|						AND NOT &qShowOrderItems
	|						AND Accounts.Recorder REFS Document.Storno
	|					THEN ISNULL(Accounts.RecorderParentChargeMarkingCode, """")
	|				ELSE ISNULL(Accounts.MarkingCode, """")
	|			END AS MarkingCode,
	|			ISNULL(Accounts.Item, VALUE(Catalog.OrderItems.EmptyRef)) AS Item,
	|			CASE
	|				WHEN &qHideCorrections
	|					THEN FALSE
	|				ELSE Accounts.RecorderIsCorrection
	|			END AS IsCorrection,
	|			CASE
	|				WHEN &qHideCorrections
	|					THEN FALSE
	|				WHEN Accounts.Recorder REFS Document.Storno
	|					THEN TRUE
	|				ELSE FALSE
	|			END AS IsStorno,
	|			FolioTransactionsWithInvoice.Invoice AS Invoice,
	|			CASE
	|				WHEN &qHideCorrections
	|						AND Accounts.RecorderIsCorrection
	|						AND Accounts.RecorderCorrectedCharge <> &qEmptyCharge
	|					THEN 0
	|				ELSE Accounts.ChargePrice
	|			END AS Price,
	|			Accounts.ChargeDiscountSum AS Discount,
	|			Accounts.Sum AS Sum,
	|			Accounts.VATSum AS VATSum,
	|			CASE
	|				WHEN &qHideCorrections
	|						AND Accounts.Recorder REFS Document.Storno
	|					THEN -Accounts.ChargeQuantity
	|				ELSE Accounts.ChargeQuantity
	|			END AS Quantity,
	|			Accounts.Limit AS Limit,
	|			CASE
	|				WHEN Accounts.RecordType = &qExpense
	|						AND Accounts.PaymentMethod <> &qSettlement
	|					THEN Accounts.Sum
	|				ELSE 0
	|			END AS PaymentSum
	|		FROM
	|			(SELECT
	|				Accounts.Recorder AS Recorder,
	|				Accounts.Period AS Period,
	|				Accounts.RecordType AS RecordType,
	|				Accounts.Folio AS Folio,
	|				Accounts.FolioCurrency AS FolioCurrency,
	|				Accounts.PaymentSection AS PaymentSection,
	|				Accounts.PaymentSectionCode AS PaymentSectionCode,
	|				Accounts.ParentDoc AS ParentDoc,
	|				Accounts.Charge AS Charge,
	|				Accounts.PaymentMethod AS PaymentMethod,
	|				Accounts.Sum AS Sum,
	|				Accounts.VATSum AS VATSum,
	|				Accounts.Limit AS Limit,
	|				Accounts.ChargeService AS ChargeService,
	|				Accounts.ChargePrice AS ChargePrice,
	|				Accounts.ChargeQuantity AS ChargeQuantity,
	|				Accounts.ChargeServiceQuantityCalculationRule AS ChargeServiceQuantityCalculationRule,
	|				Accounts.ChargeServiceQuantityCalculationRule.QuantityCalculationRuleType AS ChargeServiceQuantityCalculationRuleType,
	|				Accounts.ChargeIsInPrice AS ChargeIsInPrice,
	|				Accounts.ChargeIsRoomRevenue AS ChargeIsRoomRevenue,
	|				Accounts.ChargeIsResourceRevenue AS ChargeIsResourceRevenue,
	|				Accounts.ChargeRoomRevenueAmountsOnly AS ChargeRoomRevenueAmountsOnly,
	|				Accounts.ChargeIsSplit AS ChargeIsSplit,
	|				Accounts.ChargeIsFixedCharge AS ChargeIsFixedCharge,
	|				Accounts.ChargeCalendarDayType AS ChargeCalendarDayType,
	|				Accounts.ChargeRoom AS ChargeRoom,
	|				Accounts.ChargeResource AS ChargeResource,
	|				Accounts.ChargeVATRate AS ChargeVATRate,
	|				Accounts.ChargePerformer AS ChargePerformer,
	|				Accounts.ChargeRoomRate AS ChargeRoomRate,
	|				Accounts.ChargeParentDoc AS ChargeParentDoc,
	|				Accounts.ChargeDiscountSum AS ChargeDiscountSum,
	|				Accounts.MarkingCode AS MarkingCode,
	|				Accounts.Item AS Item,
	|				Accounts.ParentDocNumber AS ParentDocNumber,
	|				Accounts.ParentDocGuestGroup AS ParentDocGuestGroup,
	|				ISNULL(GuestGroups.Code, 999999999999) AS ParentDocGuestGroupCode,
	|				Accounts.ParentDocAccommodationType AS ParentDocAccommodationType,
	|				Accounts.ParentDocClient AS ParentDocClient,
	|				Accounts.ParentDocGuest AS ParentDocGuest,
	|				Accounts.RecorderNumber AS RecorderNumber,
	|				Accounts.RecorderDate AS RecorderDate,
	|				Accounts.RecorderIsCorrection AS RecorderIsCorrection,
	|				Accounts.RecorderIsAdditional AS RecorderIsAdditional,
	|				Accounts.RecorderRemarks AS RecorderRemarks,
	|				Accounts.RecorderFolioFrom AS RecorderFolioFrom,
	|				Accounts.RecorderFolioTo AS RecorderFolioTo,
	|				ISNULL(CorrectedCharges.Ref, &qEmptyCharge) AS RecorderCorrectedCharge,
	|				ISNULL(CorrectedCharges.Date, &qEmptyDate) AS RecorderCorrectedChargeDate,
	|				ISNULL(CorrectedCharges.Number, """") AS RecorderCorrectedChargeNumber,
	|				ISNULL(CorrectedCharges.Price, 0) AS RecorderCorrectedChargePrice,
	|				CAST(ISNULL(CorrectedCharges.Remarks, """") AS STRING(256)) AS RecorderCorrectedChargeRemarks,
	|				ISNULL(CorrectedCharges.IsAdditional, FALSE) AS RecorderCorrectedChargeIsAdditional,
	|				ISNULL(CorrectedCharges.ServiceDate, &qEmptyDate) AS RecorderCorrectedChargeServiceDate,
	|				ISNULL(CorrectedCharges.MarkingCode, """") AS RecorderCorrectedChargeMarkingCode,
	|				Accounts.RecorderPaymentSection AS RecorderPaymentSection,
	|				ISNULL(Accounts.RecorderPaymentSection.Code, 0) AS RecorderPaymentSectionCode,
	|				ISNULL(ParentCharges.Ref, &qEmptyCharge) AS RecorderParentCharge,
	|				ISNULL(ParentCharges.Number, """") AS RecorderParentChargeNumber,
	|				ISNULL(ParentCharges.IsAdditional, FALSE) AS RecorderParentChargeIsAdditional,
	|				CAST(ISNULL(ParentCharges.Remarks, """") AS STRING(256)) AS RecorderParentChargeRemarks,
	|				ISNULL(ParentCharges.Date, &qEmptyDate) AS RecorderParentChargeDate,
	|				ISNULL(ParentCharges.ServiceDate, &qEmptyDate) AS RecorderParentChargeServiceDate,
	|				ISNULL(ParentCharges.MarkingCode, """") AS RecorderParentChargeMarkingCode,
	|				Accounts.RecorderPayer AS RecorderPayer,
	|				Accounts.RecorderCorrectionDate AS RecorderCorrectionDate,
	|				Accounts.RecorderServiceDate AS RecorderServiceDate
	|			FROM
	|				RawAccounts AS Accounts
	|					LEFT JOIN Document.Charge AS CorrectedCharges
	|					ON Accounts.RecorderCorrectedCharge = CorrectedCharges.Ref
	|					LEFT JOIN Document.Charge AS ParentCharges
	|					ON Accounts.RecorderParentCharge = ParentCharges.Ref
	|					LEFT JOIN Catalog.GuestGroups AS GuestGroups
	|					ON Accounts.ParentDocGuestGroup = GuestGroups.Ref) AS Accounts
	|				LEFT JOIN FolioTransactionsWithInvoice AS FolioTransactionsWithInvoice
	|				ON Accounts.Recorder = FolioTransactionsWithInvoice.Recorder) AS FolioTransactionsWithDuplicates
	|	
	|	GROUP BY
	|		FolioTransactionsWithDuplicates.Document,
	|		FolioTransactionsWithDuplicates.Charge,
	|		FolioTransactionsWithDuplicates.RecordType,
	|		FolioTransactionsWithDuplicates.Folio,
	|		FolioTransactionsWithDuplicates.FolioCurrency,
	|		FolioTransactionsWithDuplicates.FolioFrom,
	|		FolioTransactionsWithDuplicates.FolioTo,
	|		FolioTransactionsWithDuplicates.ChargeParentDoc,
	|		FolioTransactionsWithDuplicates.GuestGroupCode,
	|		FolioTransactionsWithDuplicates.ReservationNumber,
	|		FolioTransactionsWithDuplicates.PaymentSection,
	|		FolioTransactionsWithDuplicates.PaymentSectionCode,
	|		FolioTransactionsWithDuplicates.Service,
	|		FolioTransactionsWithDuplicates.NettoPrice,
	|		FolioTransactionsWithDuplicates.Period,
	|		FolioTransactionsWithDuplicates.AccountingDate,
	|		FolioTransactionsWithDuplicates.AccountingMonth,
	|		FolioTransactionsWithDuplicates.ServiceDate,
	|		FolioTransactionsWithDuplicates.CorrectedServiceDate,
	|		FolioTransactionsWithDuplicates.Remarks,
	|		FolioTransactionsWithDuplicates.PaymentMethod,
	|		FolioTransactionsWithDuplicates.RecorderNumber,
	|		FolioTransactionsWithDuplicates.Payer,
	|		FolioTransactionsWithDuplicates.IsInPrice,
	|		FolioTransactionsWithDuplicates.IsRoomRevenue,
	|		FolioTransactionsWithDuplicates.IsResourceRevenue,
	|		FolioTransactionsWithDuplicates.RoomRevenueAmountsOnly,
	|		FolioTransactionsWithDuplicates.IsSplit,
	|		FolioTransactionsWithDuplicates.CalendarDayType,
	|		FolioTransactionsWithDuplicates.Room,
	|		FolioTransactionsWithDuplicates.Resource,
	|		FolioTransactionsWithDuplicates.VATRate,
	|		FolioTransactionsWithDuplicates.Performer,
	|		FolioTransactionsWithDuplicates.AccommodationType,
	|		FolioTransactionsWithDuplicates.Client,
	|		FolioTransactionsWithDuplicates.RoomRate,
	|		FolioTransactionsWithDuplicates.MarkingCode,
	|		FolioTransactionsWithDuplicates.Item,
	|		FolioTransactionsWithDuplicates.IsCorrection,
	|		FolioTransactionsWithDuplicates.IsStorno,
	|		FolioTransactionsWithDuplicates.Invoice) AS FolioTransactions
	|		LEFT JOIN Document.Folio AS FoliosFrom
	|		ON FolioTransactions.FolioFrom = FoliosFrom.Ref
	|		LEFT JOIN Document.Folio AS FoliosTo
	|		ON FolioTransactions.FolioTo = FoliosTo.Ref
	|		LEFT JOIN Catalog.PaymentMethods AS PaymentMethods
	|		ON FolioTransactions.PaymentMethod = PaymentMethods.Ref
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON FolioTransactions.Payer = Customers.Ref
	|		LEFT JOIN Catalog.Clients AS Clients
	|		ON FolioTransactions.Payer = Clients.Ref
	|
	|ORDER BY
	|	CorrectedServiceDate,
	|	GuestGroupCode,
	|	ReservationNumber,
	|	AccommodationTypeSortCode,
	|	ServiceIsInprice DESC,
	|	ServiceIsRoomRevenue DESC,
	|	ServiceIsResourceRevenue DESC,
	|	ServiceRoomRevenueAmountsOnly,
	|	IsInPrice DESC,
	|	IsRoomRevenue DESC,
	|	FolioTransactions.IsResourceRevenue DESC,
	|	FolioTransactions.RoomRevenueAmountsOnly,
	|	IsSplit,
	|	Period,
	|	IsCorrection,
	|	IsStorno,
	|	ServiceSortCode,
	|	ServiceCode";
	Return vTransactionsQryText;
EndFunction // cmGetTransactionsQueryText

// -----------------------------------------------------------------------------
Function cmGetRoomRateAmounts(pRoomRevenueCharge) Export
	vRoomRateAmountsRow = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(Amounts.Sum) AS Sum,
	|	SUM(Amounts.DiscountSum) AS DiscountSum,
	|	SUM(Amounts.CommissionSum) AS CommissionSum,
	|	SUM(Amounts.Amount) AS Amount,
	|	SUM(Amounts.AmountWithoutCommission) AS AmountWithoutCommission,
	|	SUM(Amounts.VATSum) AS VATSum
	|FROM
	|	(SELECT
	|		Charges.Folio.Customer AS FolioCustomer,
	|		Charges.Folio.Agent AS FolioAgent,
	|		SUM(Charges.Sum) AS Sum,
	|		SUM(Charges.DiscountSum) AS DiscountSum,
	|		SUM(Charges.CommissionSum) AS CommissionSum,
	|		SUM(Charges.VATSum) AS VATSum,
	|		SUM(Charges.Sum - Charges.DiscountSum) AS Amount,
	|		CASE
	|			WHEN Charges.Folio.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|					AND NOT ISNULL(Charges.Folio.Customer.DoNotPostCommission, FALSE)
	|					AND Charges.Folio.Agent = Charges.Folio.Customer
	|				THEN SUM(Charges.Sum - Charges.DiscountSum - Charges.CommissionSum)
	|			ELSE SUM(Charges.Sum - Charges.DiscountSum)
	|		END AS AmountWithoutCommission
	|	FROM
	|		Document.Charge AS Charges
	|	WHERE
	|		(Charges.Ref = &qRoomRevenueCharge
	|				OR Charges.RoomRevenueCharge = &qRoomRevenueCharge
	|					AND Charges.IsMergedToRoomRevenue)
	|		AND Charges.Posted
	|	
	|	GROUP BY
	|		Charges.Folio.Customer,
	|		Charges.Folio.Agent,
	|		Charges.Folio.Customer.DoNotPostCommission
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Stornos.ParentCharge.Folio.Customer,
	|		Stornos.ParentCharge.Folio.Agent,
	|		SUM(Stornos.Sum),
	|		SUM(Stornos.DiscountSum),
	|		SUM(Stornos.CommissionSum),
	|		SUM(Stornos.VATSum),
	|		SUM(Stornos.Sum - Stornos.DiscountSum),
	|		CASE
	|			WHEN Stornos.ParentCharge.Folio.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|					AND NOT ISNULL(Stornos.ParentCharge.Folio.Customer.DoNotPostCommission, FALSE)
	|					AND Stornos.ParentCharge.Folio.Agent = Stornos.ParentCharge.Folio.Customer
	|				THEN SUM(Stornos.Sum - Stornos.DiscountSum - Stornos.CommissionSum)
	|			ELSE SUM(Stornos.Sum - Stornos.DiscountSum)
	|		END
	|	FROM
	|		Document.Storno AS Stornos
	|	WHERE
	|		(Stornos.ParentCharge = &qRoomRevenueCharge
	|				OR Stornos.ParentCharge.RoomRevenueCharge = &qRoomRevenueCharge
	|					AND Stornos.ParentCharge.IsMergedToRoomRevenue)
	|		AND Stornos.Posted
	|	
	|	GROUP BY
	|		Stornos.ParentCharge.Folio.Customer,
	|		Stornos.ParentCharge.Folio.Agent,
	|		Stornos.ParentCharge.Folio.Customer.DoNotPostCommission
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualStornos.Folio.Customer,
	|		VirtualStornos.Folio.Agent,
	|		-SUM(VirtualStornos.Sum),
	|		-SUM(VirtualStornos.DiscountSum),
	|		-SUM(VirtualStornos.CommissionSum),
	|		-SUM(VirtualStornos.VATSum),
	|		-SUM(VirtualStornos.Sum - VirtualStornos.DiscountSum),
	|		CASE
	|			WHEN VirtualStornos.Folio.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|					AND NOT ISNULL(VirtualStornos.Folio.Customer.DoNotPostCommission, FALSE)
	|					AND VirtualStornos.Folio.Agent = VirtualStornos.Folio.Customer
	|				THEN -SUM(VirtualStornos.Sum - VirtualStornos.DiscountSum - VirtualStornos.CommissionSum)
	|			ELSE -SUM(VirtualStornos.Sum - VirtualStornos.DiscountSum)
	|		END
	|	FROM
	|		Document.Charge AS VirtualStornos
	|			INNER JOIN Document.Storno AS Stornos
	|			ON (VirtualStornos.RoomRevenueCharge = &qRoomRevenueCharge)
	|				AND (VirtualStornos.IsMergedToRoomRevenue)
	|				AND (VirtualStornos.Posted)
	|				AND VirtualStornos.RoomRevenueCharge = Stornos.ParentCharge
	|				AND (Stornos.Posted)
	|	
	|	GROUP BY
	|		VirtualStornos.Folio.Customer,
	|		VirtualStornos.Folio.Agent,
	|		VirtualStornos.Folio.Customer.DoNotPostCommission) AS Amounts";
	vQry.SetParameter("qRoomRevenueCharge", pRoomRevenueCharge);
	vQryResults = vQry.Execute().Unload();
	If vQryResults.Count() > 0 Then
		vRoomRateAmountsRow = vQryResults.Get(0);
	EndIf;
	Return vRoomRateAmountsRow;
EndFunction // cmGetRoomRateAmounts

// -----------------------------------------------------------------------------
Function cmGetRoomRateTransactions(pRoomRevenueCharge) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Stornos.Ref AS Ref,
	|	BEGINOFPERIOD(Stornos.Date, DAY) AS AccountingDate,
	|	Stornos.ParentCharge AS ParentCharge,
	|	Stornos.ParentCharge.ParentDoc AS ParentDoc,
	|	Stornos.ParentCharge.Folio AS Folio,
	|	Stornos.ParentCharge.Folio.Customer AS FolioCustomer,
	|	Stornos.ParentCharge.Folio.Agent AS FolioAgent,
	|	Stornos.ParentCharge.ServiceDate AS ServiceDate,
	|	Stornos.Service AS Service,
	|	Stornos.Price AS Price,
	|	Stornos.Quantity AS Quantity,
	|	Stornos.Unit AS Unit,
	|	Stornos.VATRate AS VATRate,
	|	Stornos.ParentCharge.Discount AS Discount,
	|	Stornos.ParentCharge.AgentCommission AS AgentCommission,
	|	Stornos.PointInTime AS PointInTime,
	|	Stornos.Sum AS Sum,
	|	Stornos.DiscountSum AS DiscountSum,
	|	Stornos.CommissionSum AS CommissionSum,
	|	Stornos.VATSum AS VATSum,
	|	Stornos.Sum - Stornos.DiscountSum AS Amount,
	|	CASE
	|		WHEN Stornos.ParentCharge.Folio.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|				AND NOT ISNULL(Stornos.ParentCharge.Folio.Customer.DoNotPostCommission, FALSE)
	|				AND Stornos.ParentCharge.Folio.Agent = Stornos.ParentCharge.Folio.Customer
	|			THEN Stornos.Sum - Stornos.DiscountSum - Stornos.CommissionSum
	|		ELSE Stornos.Sum - Stornos.DiscountSum
	|	END AS AmountWithoutCommission
	|INTO StornoDocuments
	|FROM
	|	Document.Storno AS Stornos
	|WHERE
	|	(Stornos.ParentCharge = &qRoomRevenueCharge
	|			OR Stornos.ParentCharge.RoomRevenueCharge = &qRoomRevenueCharge
	|				AND Stornos.ParentCharge.IsMergedToRoomRevenue)
	|	AND Stornos.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Stornos.Ref AS Ref,
	|	BEGINOFPERIOD(Stornos.Date, DAY) AS AccountingDate,
	|	RoomRateCharges.Ref AS ParentCharge,
	|	RoomRateCharges.ParentDoc AS ParentDoc,
	|	RoomRateCharges.Folio AS Folio,
	|	RoomRateCharges.Folio.Customer AS FolioCustomer,
	|	RoomRateCharges.Folio.Agent AS FolioAgent,
	|	RoomRateCharges.ServiceDate AS ServiceDate,
	|	RoomRateCharges.Service AS Service,
	|	RoomRateCharges.Price AS Price,
	|	-RoomRateCharges.Quantity AS Quantity,
	|	RoomRateCharges.Unit AS Unit,
	|	RoomRateCharges.VATRate AS VATRate,
	|	RoomRateCharges.Discount AS Discount,
	|	RoomRateCharges.AgentCommission AS AgentCommission,
	|	Stornos.PointInTime AS PointInTime,
	|	-RoomRateCharges.Sum AS Sum,
	|	-RoomRateCharges.DiscountSum AS DiscountSum,
	|	-RoomRateCharges.CommissionSum AS CommissionSum,
	|	-RoomRateCharges.VATSum AS VATSum,
	|	-(RoomRateCharges.Sum - RoomRateCharges.DiscountSum) AS Amount,
	|	CASE
	|		WHEN RoomRateCharges.Folio.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|				AND NOT ISNULL(RoomRateCharges.Folio.Customer.DoNotPostCommission, FALSE)
	|				AND RoomRateCharges.Folio.Agent = RoomRateCharges.Folio.Customer
	|			THEN -(RoomRateCharges.Sum - RoomRateCharges.DiscountSum - RoomRateCharges.CommissionSum)
	|		ELSE -(RoomRateCharges.Sum - RoomRateCharges.DiscountSum)
	|	END AS AmountWithoutCommission
	|INTO RoomRateChargeVirtualStornos
	|FROM
	|	Document.Charge AS RoomRateCharges
	|		INNER JOIN Document.Storno AS Stornos
	|		ON RoomRateCharges.RoomRevenueCharge = Stornos.ParentCharge
	|			AND (Stornos.Posted)
	|WHERE
	|	RoomRateCharges.RoomRevenueCharge = &qRoomRevenueCharge
	|	AND RoomRateCharges.IsMergedToRoomRevenue
	|	AND RoomRateCharges.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Charges.Ref AS Ref,
	|	BEGINOFPERIOD(Charges.Date, DAY) AS AccountingDate,
	|	Charges.ParentDoc AS ParentDoc,
	|	Charges.Folio AS Folio,
	|	Charges.Folio.Customer AS FolioCustomer,
	|	Charges.Folio.Agent AS FolioAgent,
	|	Charges.ServiceDate AS ServiceDate,
	|	Charges.Service AS Service,
	|	Charges.Price AS Price,
	|	Charges.Quantity AS Quantity,
	|	Charges.Unit AS Unit,
	|	Charges.VATRate AS VATRate,
	|	Charges.Discount AS Discount,
	|	Charges.AgentCommission AS AgentCommission,
	|	Charges.PointInTime AS PointInTime,
	|	Charges.Sum AS Sum,
	|	Charges.DiscountSum AS DiscountSum,
	|	Charges.CommissionSum AS CommissionSum,
	|	Charges.VATSum AS VATSum,
	|	Charges.Sum - Charges.DiscountSum AS Amount,
	|	CASE
	|		WHEN Charges.Folio.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|				AND NOT ISNULL(Charges.Folio.Customer.DoNotPostCommission, FALSE)
	|				AND Charges.Folio.Agent = Charges.Folio.Customer
	|			THEN Charges.Sum - Charges.DiscountSum - Charges.CommissionSum
	|		ELSE Charges.Sum - Charges.DiscountSum
	|	END AS AmountWithoutCommission
	|FROM
	|	Document.Charge AS Charges
	|WHERE
	|	(Charges.Ref = &qRoomRevenueCharge
	|			OR Charges.RoomRevenueCharge = &qRoomRevenueCharge
	|				AND Charges.IsMergedToRoomRevenue)
	|	AND Charges.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	Stornos.Ref,
	|	Stornos.AccountingDate,
	|	Stornos.ParentDoc,
	|	Stornos.Folio,
	|	Stornos.FolioCustomer,
	|	Stornos.FolioAgent,
	|	Stornos.ServiceDate,
	|	Stornos.Service,
	|	Stornos.Price,
	|	Stornos.Quantity,
	|	Stornos.Unit,
	|	Stornos.VATRate,
	|	Stornos.Discount,
	|	Stornos.AgentCommission,
	|	Stornos.PointInTime,
	|	Stornos.Sum,
	|	Stornos.DiscountSum,
	|	Stornos.CommissionSum,
	|	Stornos.VATSum,
	|	Stornos.Amount,
	|	Stornos.AmountWithoutCommission
	|FROM
	|	StornoDocuments AS Stornos
	|
	|UNION ALL
	|
	|SELECT
	|	VirtualStornos.Ref,
	|	VirtualStornos.AccountingDate,
	|	VirtualStornos.ParentDoc,
	|	VirtualStornos.Folio,
	|	VirtualStornos.FolioCustomer,
	|	VirtualStornos.FolioAgent,
	|	VirtualStornos.ServiceDate,
	|	VirtualStornos.Service,
	|	VirtualStornos.Price,
	|	VirtualStornos.Quantity,
	|	VirtualStornos.Unit,
	|	VirtualStornos.VATRate,
	|	VirtualStornos.Discount,
	|	VirtualStornos.AgentCommission,
	|	VirtualStornos.PointInTime,
	|	VirtualStornos.Sum,
	|	VirtualStornos.DiscountSum,
	|	VirtualStornos.CommissionSum,
	|	VirtualStornos.VATSum,
	|	VirtualStornos.Amount,
	|	VirtualStornos.AmountWithoutCommission
	|FROM
	|	RoomRateChargeVirtualStornos AS VirtualStornos
	|
	|ORDER BY
	|	PointInTime";
	vQry.SetParameter("qRoomRevenueCharge", pRoomRevenueCharge);
	Return vQry.Execute().Unload();
EndFunction // cmGetRoomRateTransactions

// -----------------------------------------------------------------------------
Function cmIsSpecialOfferActive(pSpecialOffer, pAccountingDate, pHotel) Export
	vResult = True;
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	SpecialOfferPeriods.SpecialOffer AS SpecialOffer,
	|	SpecialOfferPeriods.Hotel AS Hotel,
	|	SpecialOfferPeriods.DateValidFrom AS DateValidFrom,
	|	SpecialOfferPeriods.DateValidTo AS DateValidTo,
	|	SpecialOfferPeriods.CheckInDateFrom AS CheckInDateFrom,
	|	SpecialOfferPeriods.CheckInDateTo AS CheckInDateTo,
	|	SpecialOfferPeriods.PeriodOfStayFrom AS PeriodOfStayFrom,
	|	SpecialOfferPeriods.PeriodOfStayTo AS PeriodOfStayTo,
	|	SpecialOfferPeriods.ApplyToDatesInsidePeriodOfStayOnly AS ApplyToDatesInsidePeriodOfStayOnly
	|FROM
	|	InformationRegister.SpecialOfferPeriods AS SpecialOfferPeriods
	|WHERE
	|	SpecialOfferPeriods.SpecialOffer = &qSpecialOffer
	|	AND (SpecialOfferPeriods.Hotel = &qHotel
	|			OR SpecialOfferPeriods.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND SpecialOfferPeriods.PeriodOfStayFrom <= &qAccountingDate
	|	AND (SpecialOfferPeriods.PeriodOfStayTo >= &qAccountingDate
	|			OR SpecialOfferPeriods.PeriodOfStayTo = &qEmptyDate)
	|
	|ORDER BY
	|	PeriodOfStayFrom,
	|	PeriodOfStayTo";
	vQry.SetParameter("qSpecialOffer", pSpecialOffer);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQryRes = vQry.Execute();
	If vQryRes.IsEmpty() Then
		vResult = False;
	EndIf;
	Return vResult;
EndFunction // cmIsSpecialOfferActive

// -----------------------------------------------------------------------------
Procedure cmGetCacheEffectivePeriod(pRatesList, pDayTypes, rDateFrom, rDateTo) Export
	vCurDate = BegOfDay(CurrentSessionDate());
	
	vCalendarsList = New ValueList();
	For Each vRatesListItem In pRatesList Do
		vRate = vRatesListItem.Value;
		vCalendar = vRate.Calendar;
		If vCalendarsList.FindByValue(vCalendar) = Undefined Then
			vCalendarsList.Add(vCalendar);
		EndIf;
	EndDo;
	
	For Each vCalendarsListItem In vCalendarsList Do
		vCalendar = vCalendarsListItem.Value;
		For Each vDayTypesRow In pDayTypes Do
			vDayType = vDayTypesRow.CalendarDayType;
			
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	MIN(CalendarDays.AccountingDate) AS MinPeriod,
			|	MAX(CalendarDays.AccountingDate) AS MaxPeriod
			|FROM
			|	InformationRegister.CalendarDays.SliceLast(
			|			,
			|			Calendar = &qCalendar
			|				AND CalendarDayType = &qCalendarDayType) AS CalendarDays";
			vQry.SetParameter("qCalendar", vCalendar);
			vQry.SetParameter("qCalendarDayType", vDayType);
			vDTMinMaxs = vQry.Execute().Unload();
			For Each vDTMinMaxsRow In vDTMinMaxs Do
				If vDTMinMaxsRow.MinPeriod <> Null And vDTMinMaxsRow.MaxPeriod <> Null Then
					rDateFrom = Min(rDateFrom, Max(vDTMinMaxsRow.MinPeriod, vCurDate));
					rDateTo = Max(rDateTo, Max(vDTMinMaxsRow.MaxPeriod, vCurDate));
				EndIf;
			EndDo;
			
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	MIN(CalendarDaysByRoomTypes.AccountingDate) AS MinPeriod,
			|	MAX(CalendarDaysByRoomTypes.AccountingDate) AS MaxPeriod
			|FROM
			|	InformationRegister.CalendarDaysByRoomTypes.SliceLast(
			|			,
			|			Calendar = &qCalendar
			|				AND CalendarDayType = &qCalendarDayType) AS CalendarDaysByRoomTypes";
			vQry.SetParameter("qCalendar", vCalendar);
			vQry.SetParameter("qCalendarDayType", vDayType);
			vDTMinMaxs = vQry.Execute().Unload();
			For Each vDTMinMaxsRow In vDTMinMaxs Do
				If vDTMinMaxsRow.MinPeriod <> Null And vDTMinMaxsRow.MaxPeriod <> Null Then
					rDateFrom = Min(rDateFrom, Max(vDTMinMaxsRow.MinPeriod, vCurDate));
					rDateTo = Max(rDateTo, Max(vDTMinMaxsRow.MaxPeriod, vCurDate));
				EndIf;
			EndDo;
		EndDo;
	EndDo;
EndProcedure // cmGetCacheEffectivePeriod

// -----------------------------------------------------------------------------
Procedure cmRunFillRoomRatePricesCacheAtServer(pHotel, pRoomRatesList, pPeriodFrom, pPeriodTo) Export
	vParams = New Array();
	vParams.Add(pHotel);
	vParams.Add(pRoomRatesList);
	vParams.Add(pPeriodFrom);
	vParams.Add(pPeriodTo);
	vBJ = BackgroundJobs.Execute("JobsScheduled.cmFillRoomRatePricesCache", vParams, , NStr("en='Fill room rate prices cache: '; ru='Заполнение кэша цен тарифов: '; de='Zimmerpreis Preise Cache füllen: '") + TrimAll(pHotel) + ", " + cmGetListPresentation(pRoomRatesList) + ", " + Format(pPeriodFrom, "DF=dd.MM.yyyy") + " - " + Format(pPeriodTo, "DF=dd.MM.yyyy")); 
EndProcedure // cmRunFillRoomRatePricesCacheAtServer

// -----------------------------------------------------------------------------
Function cmGetRoomRateOverrides(pRoomRate, pHotel, pAccommodationTemplate, pRoomType) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRateOverrides.RoomRate AS RoomRate,
	|	RoomRateOverrides.Hotel AS Hotel,
	|	RoomRateOverrides.AccommodationTemplate AS AccommodationTemplate,
	|	RoomRateOverrides.RoomType AS RoomType,
	|	RoomRateOverrides.AccommodationType AS AccommodationType,
	|	RoomRateOverrides.TemplateLineNumber AS TemplateLineNumber,
	|	RoomRateOverrides.ToAccommodationType AS ToAccommodationType
	|FROM
	|	InformationRegister.RoomRateOverrides AS RoomRateOverrides
	|WHERE
	|	RoomRateOverrides.RoomRate = &qRoomRate
	|	AND RoomRateOverrides.Hotel = &qHotel
	|	AND (RoomRateOverrides.AccommodationTemplate = &qAccommodationTemplate
	|			OR NOT &qAccommodationTemplateIsFilled)
	|	AND (RoomRateOverrides.RoomType = &qRoomType
	|			OR NOT &qRoomTypeIsFilled
	|			OR RoomRateOverrides.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))";
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qAccommodationTemplate", pAccommodationTemplate);
	vQry.SetParameter("qAccommodationTemplateIsFilled", ValueIsFilled(pAccommodationTemplate));
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsFilled", ValueIsFilled(pRoomType));
	Return vQry.Execute().Unload();
EndFunction // cmGetRoomRateOverrides

// -----------------------------------------------------------------------------
Function cmGetChargeCorrectionCharges(pCharge) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charge.Ref AS Ref
	|FROM
	|	Document.Charge AS Charge
	|WHERE
	|	Charge.CorrectedCharge = &qCorrectedCharge
	|	AND Charge.Ref <> &qCorrectedCharge
	|	AND Charge.Posted
	|	AND &qCorrectedCharge <> VALUE(Document.Charge.EmptyRef)
	|	AND &qCorrectedCharge <> UNDEFINED
	|
	|ORDER BY
	|	Charge.PointInTime,
	|	Charge.Number";
	vQry.SetParameter("qCorrectedCharge", pCharge);
	Return vQry.Execute().Unload();
EndFunction // cmGetChargeCorrectionCharges

// -----------------------------------------------------------------------------
Procedure cmCreateNoVATVATRate() Export
	SetPrivilegedMode(True);
	vNoVATObj = Catalogs.VATRates.CreateItem();
	vNoVATObj.Description = NStr("en='No VAT'; ru='Без НДС'; de='Keine MwSt'");
	vNoVATObj.NoVAT = True;
	vNoVATObj.TaxGroup = 4;
	vNoVATObj.TaxRate = 0;
	vNoVATObj.Write();
	SetPrivilegedMode(False);
EndProcedure // cmCreateNoVATVATRate

// -----------------------------------------------------------------------------
Function cmCalculateTouristTaxSum(pHotel, pIsForHotelProductServices = False, rTouristTaxAccountingDate, pTouristTaxBaseAmount, pDurationInDays = 1, pClient, pClientAge, pCheckInDate, pCheckOutDate, rTouristTaxService, rTouristicTaxExemptionReason = Undefined, rTouristicTaxExemptionReasonFillDate = '00010101', rTouristTaxRate = 0, rMinAmountPerDay = 0, rTouristicTaxIsByMinAmount = False, pDoUpdate = False, pRoomQuantity = 1, pRoomRate = Undefined) Export
	vTouristTaxAmount = 0;
	If pTouristTaxBaseAmount <> 0 Then
		vTouristTaxDateSettingType = pHotel.TouristTaxAccountingDateSettingType;
		vTouristTaxAccountingDate = rTouristTaxAccountingDate;
		If vTouristTaxDateSettingType = Enums.TouristTaxAccountingDateSettingTypes.UseCheckInDate Then
			If ValueIsFilled(pCheckInDate) And BegOfDay(pCheckInDate) <> vTouristTaxAccountingDate Then
				vTouristTaxAccountingDate = BegOfDay(pCheckInDate);
			EndIf;
		ElsIf vTouristTaxDateSettingType = Enums.TouristTaxAccountingDateSettingTypes.UseCheckOutDate Then
			If ValueIsFilled(pCheckOutDate) And BegOfDay(pCheckOutDate) <> vTouristTaxAccountingDate Then
				vTouristTaxAccountingDate = BegOfDay(pCheckOutDate);
			EndIf;
		EndIf;
		If ValueIsFilled(vTouristTaxAccountingDate) And rTouristTaxAccountingDate <> vTouristTaxAccountingDate And pDoUpdate Then
			rTouristTaxAccountingDate = vTouristTaxAccountingDate;
		EndIf;
		If ValueIsFilled(rTouristTaxAccountingDate) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	TouristTaxSettingsSliceLast.TouristTaxRate AS TouristTaxRate,
			|	TouristTaxSettingsSliceLast.MinAmountPerDay AS MinAmountPerDay
			|FROM
			|	InformationRegister.TouristTaxSettings.SliceLast(
			|			&qDate,
			|			Hotel = &qHotel
			|				AND IsForHotelProductServices = &qIsForHotelProductServices) AS TouristTaxSettingsSliceLast";
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qIsForHotelProductServices", pIsForHotelProductServices);
			vQry.SetParameter("qDate", rTouristTaxAccountingDate);
			vRateRows = vQry.Execute().Unload();
			For Each vRatesRow In vRateRows Do
				If ValueIsFilled(pHotel.TouristicTaxExemptionReasonForGuestsUnder18YearsOld) Then
					If ValueIsFilled(pClient) And pClient.Age > 0 And pClient.Age < 18 Then
						If Not ValueIsFilled(rTouristicTaxExemptionReason) And pDoUpdate Then
							rTouristicTaxExemptionReason = pHotel.TouristicTaxExemptionReasonForGuestsUnder18YearsOld;
							rTouristicTaxExemptionReasonFillDate = ?(ValueIsFilled(pHotel.AccountingDate), pHotel.AccountingDate, BegOfDay(CurrentSessionDate()));
						EndIf;
					Else
						If pClientAge > 0 And pClientAge < 18 Then
							If Not ValueIsFilled(rTouristicTaxExemptionReason) And pDoUpdate Then
								rTouristicTaxExemptionReason = pHotel.TouristicTaxExemptionReasonForGuestsUnder18YearsOld;
								rTouristicTaxExemptionReasonFillDate = ?(ValueIsFilled(pHotel.AccountingDate), pHotel.AccountingDate, BegOfDay(CurrentSessionDate()));
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				
				If ValueIsFilled(pHotel.TouristicTaxExemptionReasonForGuestsFromHomeRegion) Then
					If ValueIsFilled(pClient) And Not IsBlankString(pClient.Address) Then
						vAddrStruct = cmParseAddress(pClient.Address);
						If Not IsBlankString(pHotel.Cities) And Not IsBlankString(vAddrStruct.City) And StrFind(lower(pHotel.Cities), lower(vAddrStruct.City)) > 0 Or
						   Not IsBlankString(pHotel.Region) And Not IsBlankString(vAddrStruct.Region) And lower(pHotel.Region) = lower(vAddrStruct.Region) Then
							If Not ValueIsFilled(rTouristicTaxExemptionReason) And pDoUpdate Then
								rTouristicTaxExemptionReason = pHotel.TouristicTaxExemptionReasonForGuestsFromHomeRegion;
								rTouristicTaxExemptionReasonFillDate = ?(ValueIsFilled(pHotel.AccountingDate), pHotel.AccountingDate, BegOfDay(CurrentSessionDate()));
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				
				rTouristTaxRate = vRatesRow.TouristTaxRate;
				rMinAmountPerDay = vRatesRow.MinAmountPerDay;
				
				vTouristTaxAmount = 0;
				If Not ValueIsFilled(rTouristTaxService) Then
					rTouristTaxService = pHotel.TouristTaxService;
					If ValueIsFilled(pRoomRate) And ValueIsFilled(pRoomRate.TouristTaxService) Then
						rTouristTaxService = pRoomRate.TouristTaxService;
					EndIf;
				EndIf;
				vTouristTaxAddToRate = pHotel.TouristTaxAddToRate;
				If ValueIsFilled(pRoomRate) And pRoomRate.TouristTaxAddToRate Then
					vTouristTaxAddToRate = pRoomRate.TouristTaxAddToRate;
					rTouristTaxService = Catalogs.Services.EmptyRef();
				EndIf;
				If vTouristTaxAddToRate Or ValueIsFilled(rTouristTaxService) Then
					vTouristTaxAmount = Round((pTouristTaxBaseAmount/?(pRoomQuantity = 0, 1, pRoomQuantity)/?(pDurationInDays = 0, 1, pDurationInDays)) * (vRatesRow.TouristTaxRate / 100), 2);
				Else
					vTouristTaxAmount = Round((pTouristTaxBaseAmount/?(pRoomQuantity = 0, 1, pRoomQuantity)/?(pDurationInDays = 0, 1, pDurationInDays)) * (vRatesRow.TouristTaxRate / (100 + vRatesRow.TouristTaxRate)), 2);
				EndIf;
				If vTouristTaxAmount <= vRatesRow.MinAmountPerDay Then
					vTouristTaxAmount = vRatesRow.MinAmountPerDay;
					If pDoUpdate And Not rTouristicTaxIsByMinAmount Then
						rTouristicTaxIsByMinAmount = True;
					EndIf;
				Else
					If pDoUpdate And rTouristicTaxIsByMinAmount Then
						rTouristicTaxIsByMinAmount = False;
					EndIf;
				EndIf;
				
				Break;
			EndDo;
		EndIf;
	EndIf;
	Return vTouristTaxAmount;
EndFunction // cmCalculateTouristTaxSum

// -----------------------------------------------------------------------------
Function cmGetTouristTaxSettings(pHotel, pAccountingDate) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	TouristTaxSettingsSliceLast.IsForHotelProductServices AS IsForHotelProductServices,
	|	TouristTaxSettingsSliceLast.TouristTaxRate AS TouristTaxRate,
	|	TouristTaxSettingsSliceLast.MinAmountPerDay AS MinAmountPerDay
	|FROM
	|	InformationRegister.TouristTaxSettings.SliceLast(&qDate, Hotel = &qHotel) AS TouristTaxSettingsSliceLast";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qDate", pAccountingDate);
	Return vQry.Execute().Unload();
EndFunction // cmGetTouristTaxSettings

// -----------------------------------------------------------------------------
Function cmIfTouristTaxIsCharging(pHotel, pAccountingDate, pRoomRate = Undefined) Export
	vIsCharging = False;
	If pHotel.TouristTaxIsUsed And (ValueIsFilled(pHotel.TouristTaxService) Or ValueIsFilled(pRoomRate) And ValueIsFilled(pRoomRate.TouristTaxService)) Then
		vIsCharging = True;
	EndIf;
	Return vIsCharging;
EndFunction // cmIfTouristTaxIsCharging

// -----------------------------------------------------------------------------
Function cmGetServiceGroupServices(pServiceGroup, rTopLevelParent = Undefined) Export
	vServicesList = New ValueList();
	rTopLevelParent = Undefined;
	If ValueIsFilled(pServiceGroup) Then
		If pServiceGroup.IncludeAll Then
			vAllServices = cmGetAllServices(, True);
			For Each vAllServicesRow In vAllServices Do
				If vServicesList.FindByValue(vAllServicesRow.Service) = Undefined Then
					vServicesList.Add(vAllServicesRow.Service);
				EndIf;
			EndDo;
		Else
			For Each vSrvRow In pServiceGroup.Services Do
				vService = vSrvRow.Service;
				If ValueIsFilled(vService) Then
					If vService.IsFolder Then
						vGroupServices = cmGetAllServices(vService, True);
						For Each vGroupServicesRow In vGroupServices Do
							If vServicesList.FindByValue(vGroupServicesRow.Service) = Undefined Then
								vServicesList.Add(vGroupServicesRow.Service);
							EndIf;
						EndDo;
					Else
						If vServicesList.FindByValue(vService) = Undefined Then
							vServicesList.Add(vService);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	vMinLevel = 99;
	vMinLevelParent = Undefined;
	For Each vServicesListItem In vServicesList Do
		vService = vServicesListItem.Value;
		If ValueIsFilled(vService) Then
			If vService.Level() < vMinLevel Then
				vMinLevel = vService.Level();
				vMinLevelParent = vService.Parent;
			ElsIf vService.Level() = vMinLevel And ValueIsFilled(vService.Parent) And vService.Parent <> vMinLevelParent Then
				vMinLevel = vService.Parent.Level();
				vMinLevelParent = vService.Parent.Parent;
			EndIf;
		EndIf;
	EndDo;
	If ValueIsFilled(vMinLevelParent) Then
		rTopLevelParent = vMinLevelParent;
	EndIf;
	Return vServicesList;
EndFunction // cmGetServiceGroupServices

// -----------------------------------------------------------------------------
Function cmGetRoomRateService(pHotel, pRoomRate, pClientType, pRoomType, pDate, rVATRate) Export
	vService = pRoomRate.AccommodationService;
	If ValueIsFilled(vService) Then
		vServiceAttrs = vService.GetObject().pmGetServicePrices(pHotel, pDate, pClientType);
		For Each vServiceAttrsRow In vServiceAttrs Do
			If ValueIsFilled(vServiceAttrsRow.VATRate) Then
				rVATRate = vServiceAttrsRow.VATRate;
				Break;
			EndIf;
		EndDo;
	Else
		vStruct = CachedAccounts.GetRoomRatePrices(pRoomRate, pDate, , pClientType, pRoomType, , , , pDate, pDate, , , , pHotel);
		For Each vRow In vStruct.Prices Do
			If vRow.IsInPrice And vRow.IsRoomRevenue And Not vRow.RoomRevenueAmountsOnly And ValueIsFilled(vRow.Service) Then
				vService = vRow.Service;
				rVATRate = vRow.VATRate;
				Break;
			EndIf;
		EndDo;
	EndIf;
	Return vService;
EndFunction // cmGetRoomRateService

// -----------------------------------------------------------------------------
Function cmGetServiceDateMove(pQuantityCalculationRule, pQuantityCalculationRuleType = Undefined, pChargeMealsAtFirstDay = Undefined, pIsManualService = False, pObject, pIsAccommodation = False, rAccountingDateMove = 0) Export
	vIsAccommodation = pIsAccommodation;
	If Not vIsAccommodation Then
		If TypeOf(pObject) = Type("DocumentRef.Accommodation") Or TypeOf(pObject) = Type("DocumentObject.Accommodation") Then
			vIsAccommodation = True;
		EndIf;
	EndIf;
	vServiceDateMove = 0;
	rAccountingDateMove = 0;
	vQuantityCalculationRuleType = pQuantityCalculationRuleType;
	If Not ValueIsFilled(vQuantityCalculationRuleType) And ValueIsFilled(pQuantityCalculationRule) Then
		vQuantityCalculationRuleType = pQuantityCalculationRule.QuantityCalculationRuleType;
	EndIf;
	vChargeMealsAtFirstDay = pChargeMealsAtFirstDay;
	If vChargeMealsAtFirstDay = Undefined And ValueIsFilled(pQuantityCalculationRule) Then
		vChargeMealsAtFirstDay = pQuantityCalculationRule.ChargeMealsAtFirstDay;
	EndIf;
	vCheckInDate = '00010101';
	vCheckOutDate = '00010101';
	vBegOfCheckInDate = '00010101';
	vBegOfCheckOutDate = '00010101';
	If Not pIsManualService Then
		If vQuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.BreakfastServiceDateShift Then
			If Not vChargeMealsAtFirstDay Then
				vServiceDateMove = 1;
			Else
				GetAccommodationPeriodDates(pObject, vIsAccommodation, vCheckInDate, vCheckOutDate, vBegOfCheckInDate, vBegOfCheckOutDate);
				If vBegOfCheckInDate < vBegOfCheckOutDate Then
					vServiceDateMove = 1;
				EndIf;
			EndIf;
		ElsIf vQuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Breakfast Then
			If Not vChargeMealsAtFirstDay Then
				rAccountingDateMove = 1;
			Else
				GetAccommodationPeriodDates(pObject, vIsAccommodation, vCheckInDate, vCheckOutDate, vBegOfCheckInDate, vBegOfCheckOutDate);
				If vBegOfCheckInDate < vBegOfCheckOutDate Then
					rAccountingDateMove = 1;
				EndIf;
			EndIf;
		ElsIf vQuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.EarlyCheckIn Then
			vSkipEarlyCheckIn = False;
			GetAccommodationPeriodDates(pObject, vIsAccommodation, vCheckInDate, vCheckOutDate, vBegOfCheckInDate, vBegOfCheckOutDate);
			vTQ = (vCheckOutDate - vCheckInDate)/(3600 * 24);
			If vTQ <= 1 Then
				If Not pQuantityCalculationRule.FirstDayStartsAtReferenceHourTime Then
					vSkipEarlyCheckIn = True;
				EndIf;
			EndIf;
			If Not vSkipEarlyCheckIn Then
				rAccountingDateMove = -1;
			EndIf;
		ElsIf pQuantityCalculationRule.ReferenceHourIsUsed And vQuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.EarlyCheckInNoDateShift Then
			GetAccommodationPeriodDates(pObject, vIsAccommodation, vCheckInDate, vCheckOutDate, vBegOfCheckInDate, vBegOfCheckOutDate);
			vHotel = pObject.Hotel;
			If ValueIsFilled(vHotel.AccountingDate) And ValueIsFilled(vHotel.CloseOfDayDefaultTime) Then
				If (vCheckInDate - vBegOfCheckInDate) < (vHotel.CloseOfDayDefaultTime - BegOfDay(vHotel.CloseOfDayDefaultTime)) Then
					rAccountingDateMove = -1;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vServiceDateMove;
EndFunction // cmGetServiceDateMove

// -----------------------------------------------------------------------------
Function cmGetAccountingDateMove(pQuantityCalculationRule, pIsManualService = False, pObject, pIsAccommodation = False) Export
	vIsAccommodation = pIsAccommodation;
	If Not vIsAccommodation Then
		If TypeOf(pObject) = Type("DocumentRef.Accommodation") Or TypeOf(pObject) = Type("DocumentObject.Accommodation") Then
			vIsAccommodation = True;
		EndIf;
	EndIf;
	vAccountingDateMove = 0;
	vQuantityCalculationRuleType = pQuantityCalculationRule.QuantityCalculationRuleType;
	vChargeMealsAtFirstDay = pQuantityCalculationRule.ChargeMealsAtFirstDay;
	vCheckInDate = '00010101';
	vCheckOutDate = '00010101';
	vBegOfCheckInDate = '00010101';
	vBegOfCheckOutDate = '00010101';
	If Not pIsManualService Then
		If vQuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.BreakfastServiceDateShift Or 
		   vQuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Breakfast Then
			If Not vChargeMealsAtFirstDay Then
				vAccountingDateMove = ?(vQuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.BreakfastServiceDateShift, 1, -1);
			Else
				GetAccommodationPeriodDates(pObject, vIsAccommodation, vCheckInDate, vCheckOutDate, vBegOfCheckInDate, vBegOfCheckOutDate);
				If vBegOfCheckInDate < vBegOfCheckOutDate Then
					vAccountingDateMove = ?(vQuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.BreakfastServiceDateShift, 1, -1);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vAccountingDateMove;
EndFunction // cmGetAccountingDateMove

// -----------------------------------------------------------------------------
Procedure GetAccommodationPeriodDates(pObject, pIsAccommodation, rCheckInDate, rCheckOutDate, rBegOfCheckInDate, rBegOfCheckOutDate)
	rCheckInDate = '00010101';
	rCheckOutDate = '00010101';
	rBegOfCheckInDate = '00010101';
	rBegOfCheckOutDate = '00010101';
	If pIsAccommodation Or TypeOf(pObject) = Type("DocumentRef.Accommodation") Then
		rCheckInDate = pObject.CheckInDate;
		rCheckOutDate = pObject.CheckOutDate;
		rBegOfCheckInDate = BegOfDay(pObject.CheckInDate);
		rBegOfCheckOutDate = BegOfDay(pObject.CheckOutDate);
		vVaucher = pObject.HotelProduct;
		If ValueIsFilled(vVaucher) And vVaucher.FixProductPeriod And Not vVaucher.IsFolder And 
		   ValueIsFilled(vVaucher.CheckInDate) And ValueIsFilled(vVaucher.CheckOutDate) And 
		   BegOfDay(vVaucher.CheckInDate) <= BegOfDay(vVaucher.CheckOutDate) Then
			rCheckInDate = vVaucher.CheckInDate;
			rCheckOutDate = vVaucher.CheckOutDate;
			rBegOfCheckInDate = BegOfDay(vVaucher.CheckInDate);
			rBegOfCheckOutDate = BegOfDay(vVaucher.CheckOutDate);
		ElsIf pObject.IsByReservation And ValueIsFilled(pObject.Reservation) Then
			vReservation = pObject.Reservation;
			If pObject.FixReservationConditions Then
				If BegOfDay(vReservation.CheckInDate) < BegOfDay(pObject.CheckInDate) Then
					rCheckInDate = vReservation.CheckInDate;
					rBegOfCheckInDate = BegOfDay(vReservation.CheckInDate);
				EndIf;
				If BegOfDay(vReservation.CheckOutDate) > BegOfDay(pObject.CheckOutDate) Then
					rCheckOutDate = vReservation.CheckOutDate;
					rBegOfCheckOutDate = BegOfDay(vReservation.CheckOutDate);
				EndIf;
			ElsIf ValueIsFilled(pObject.AccountingCheckInDate) And 
			      pObject.AccountingCheckInDate = BegOfDay(vReservation.CheckInDate) And 
			     (BegOfDay(pObject.CheckInDate) - pObject.AccountingCheckInDate)/(24*3600) = 1 Then
				rBegOfCheckInDate = pObject.AccountingCheckInDate;
			EndIf;
		EndIf;
	ElsIf TypeOf(pObject) = Type("DocumentRef.Folio") Then
		rCheckInDate = pObject.DateTimeFrom;
		rCheckOutDate = pObject.DateTimeTo;
		rBegOfCheckInDate = BegOfDay(pObject.DateTimeFrom);
		rBegOfCheckOutDate = BegOfDay(pObject.DateTimeTo);
	ElsIf TypeOf(pObject) = Type("DocumentRef.ResourceReservation") Then
		rCheckInDate = pObject.DateTimeFrom;
		rCheckOutDate = pObject.DateTimeTo;
		rBegOfCheckInDate = BegOfDay(pObject.DateTimeFrom);
		rBegOfCheckOutDate = BegOfDay(pObject.DateTimeTo);
	Else
		rCheckInDate = pObject.CheckInDate;
		rCheckOutDate = pObject.CheckOutDate;
		rBegOfCheckInDate = BegOfDay(pObject.CheckInDate);
		rBegOfCheckOutDate = BegOfDay(pObject.CheckOutDate);
		vVaucher = pObject.HotelProduct;
		If ValueIsFilled(vVaucher) And vVaucher.FixProductPeriod And Not vVaucher.IsFolder And 
		   ValueIsFilled(vVaucher.CheckInDate) And ValueIsFilled(vVaucher.CheckOutDate) And
		   BegOfDay(vVaucher.CheckInDate) <= BegOfDay(vVaucher.CheckOutDate) Then
			rCheckInDate = vVaucher.CheckInDate;
			rCheckOutDate = vVaucher.CheckOutDate;
			rBegOfCheckInDate = BegOfDay(vVaucher.CheckInDate);
			rBegOfCheckOutDate = BegOfDay(vVaucher.CheckOutDate);
		EndIf;
	EndIf;
EndProcedure // GetAccommodationPeriodDates

#EndRegion
