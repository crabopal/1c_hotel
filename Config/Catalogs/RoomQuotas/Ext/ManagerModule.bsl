
#Region EventHandlers

Procedure ChoiceDataGetProcessing(pChoiceData, pParameters, pStandardProcessing)
	If Not pParameters.Filter.Property("Hotel") Then
		vHotelFilter = New Array;
		vHotelFilter.Add(SessionParameters.CurrentHotel);
		vHotelFilter.Add(Catalogs.Hotels.EmptyRef());
		
		pParameters.Filter.Insert("Hotel", vHotelFilter);
	EndIf;
EndProcedure

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
Function CalculateBusinessBlockBudget(pAllotment, pRecalculateForecast = False) Export
	vMessage = "";
	If pAllotment.AllotmentBusinessType <> Enums.AllotmentBusinessTypes.BusinessBlock Then
		Return vMessage;
	EndIf;
	
	// Preprocessing
	vHotel = pAllotment.Hotel;
	If Not ValueIsFilled(vHotel) Then
		vMessage = NStr("en='Business block hotel is empty!'; ru='В бизнес-блоке не указана гостиница!'; de='Im Geschäftsblock ist kein Hotel angegeben!'");
		Return vMessage;
	EndIf;
	vHotelAccountingDate = vHotel.AccountingDate;
	If Not ValueIsFilled(vHotelAccountingDate) Then
		vHotelAccountingDate = BegOfDay(CurrentSessionDate());
	EndIf;
	
	// Get room rate
	vRoomRate = ?(ValueIsFilled(pAllotment.RoomRate), pAllotment.RoomRate, vHotel.RoomRate);
	If Not ValueIsFilled(vRoomRate) Then
		vMessage = NStr("en='Business block room rate is empty!'; ru='В бизнес-блоке не указан тариф!'; de='Im Geschäftsblock ist kein Tarif angegeben!'");
		Return vMessage;
	EndIf;
	
	// Check budget currency
	If Not ValueIsFilled(pAllotment.BudgetCurrency) Then
		vMessage = NStr("en='Business block budget currency is empty!'; ru='В бизнес-блоке не указана валюта бюджета!'; de='Die Budgetwährung ist im Geschäftsblock nicht angegeben!'");
		Return vMessage;
	EndIf;

	// We have to repost all documents related to the allotment and get sales statistics
	Try
		// Clear allotment budget
		vAllotmentObj = pAllotment.GetObject();
		vAllotmentObj.BudgetReservationAmount = 0;
		vAllotmentObj.BudgetADR = 0;
		vAllotmentObj.RoomNights = 0;
		vAllotmentObj.Write();
		
		// Do reposting
		If pRecalculateForecast Then
			vAllotmentOperations = vAllotmentObj.pmGetAllotmentDocuments();
			For Each vAllotmentOperationsRow In vAllotmentOperations Do
				vDocRef = vAllotmentOperationsRow.Ref;
				If TypeOf(vDocRef) = Type("DocumentRef.SetRoomQuota") Then
					If vDocRef.DateTo > vHotelAccountingDate Then
						vDocObj = vDocRef.GetObject();
						vDocObj.Write(DocumentWriteMode.Posting);
					EndIf;
				ElsIf TypeOf(vDocRef) = Type("DocumentRef.Reservation") Or 
					  TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Then
					If vDocRef.CheckOutDate > vHotelAccountingDate Then
						vDocObj = vDocRef.GetObject();
						vDocObj.Write(DocumentWriteMode.Posting);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		// Calculate total number of room nights per all days and room types
		vTotalRoomNights = 0;
		
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	BusinessBlockTotals.RoomQuota AS RoomQuota,
		|	SUM(BusinessBlockTotals.RoomsInQuota) AS RoomsInQuota,
		|	SUM(BusinessBlockTotals.BedsInQuota) AS BedsInQuota,
		|	MAX(BusinessBlockTotals.Counter) AS Counter
		|FROM
		|	(SELECT
		|		BusinessBlockBalances.Period AS PeriodDate,
		|		BusinessBlockBalances.Hotel AS Hotel,
		|		BusinessBlockBalances.RoomQuota AS RoomQuota,
		|		BusinessBlockBalances.RoomType AS RoomType,
		|		BusinessBlockBalances.InitialRoomsInQuotaClosingBalance AS InitialRoomsInQuota,
		|		BusinessBlockBalances.InitialBedsInQuotaClosingBalance AS InitialBedsInQuota,
		|		BusinessBlockBalances.RoomsInQuotaClosingBalance AS RoomsInQuota,
		|		BusinessBlockBalances.BedsInQuotaClosingBalance AS BedsInQuota,
		|		BusinessBlockBalances.RoomsRemainsClosingBalance AS RoomsRemains,
		|		BusinessBlockBalances.BedsRemainsClosingBalance AS BedsRemains,
		|		BusinessBlockBalances.CounterClosingBalance AS Counter
		|	FROM
		|		AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
		|				,
		|				,
		|				DAY,
		|				RegisterRecordsAndPeriodBoundaries,
		|				RoomQuota = &qAllotment
		|					AND Hotel = &qHotel
		|					AND NOT RoomType.IsVirtual
		|					AND NOT RoomType.DeletionMark) AS BusinessBlockBalances) AS BusinessBlockTotals
		|
		|GROUP BY
		|	BusinessBlockTotals.RoomQuota";
		vQry.SetParameter("qAllotment", pAllotment);
		vQry.SetParameter("qHotel", vHotel);
		vTotals = vQry.Execute().Unload();
		For Each vTotalsRow In vTotals Do
			vTotalRoomNights = vTotalRoomNights + vTotalsRow.RoomsInQuota;
		EndDo;
		If vTotalRoomNights < 0 Then
			vTotalRoomNights = 0;
		EndIf;
		
		// Get sales statistics by allotment
		vTotalRoomRevenue = 0;

		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	TotalAllotmentSales.RoomQuota AS RoomQuota,
		|	SUM(TotalAllotmentSales.RoomRevenue) AS RoomRevenue,
		|	SUM(TotalAllotmentSales.Sales) AS Sales
		|FROM
		|	(SELECT
		|		SalesForecastTurnovers.RoomQuota AS RoomQuota,
		|		SalesForecastTurnovers.RoomRevenueTurnover AS RoomRevenue,
		|		SalesForecastTurnovers.SalesTurnover AS Sales
		|	FROM
		|		AccumulationRegister.SalesForecast.Turnovers(
		|				&qForecastStartDate,
		|				,
		|				Period,
		|				RoomQuota = &qAllotment
		|					AND Hotel = &qHotel) AS SalesForecastTurnovers
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SalesFactTurnovers.RoomQuota,
		|		SalesFactTurnovers.RoomRevenueTurnover,
		|		SalesFactTurnovers.SalesTurnover
		|	FROM
		|		AccumulationRegister.Sales.Turnovers(
		|				,
		|				,
		|				Period,
		|				RoomQuota = &qAllotment
		|					AND Hotel = &qHotel) AS SalesFactTurnovers) AS TotalAllotmentSales
		|
		|GROUP BY
		|	TotalAllotmentSales.RoomQuota";
		vQry.SetParameter("qAllotment", pAllotment);
		vQry.SetParameter("qHotel", vHotel);
		vForecastStartDate = tcOnServer.GetForecastStartDate(vHotel);
		vQry.SetParameter("qForecastStartDate", vForecastStartDate);
		vStats = vQry.Execute().Unload();
		For Each vStatsRow In vStats Do
			vTotalRoomRevenue = vTotalRoomRevenue + vStatsRow.RoomRevenue;
		EndDo;
		
		// Update allotment budget fields
		vAllotmentObj = pAllotment.GetObject();
		vAllotmentObj.RoomNights = vTotalRoomNights;
		vAllotmentObj.BudgetReservationAmount = Round(cmConvertCurrencies(vTotalRoomRevenue, vHotel.ReportingCurrency, , pAllotment.BudgetCurrency, , CurrentSessionDate(), vHotel), 2);
		vAllotmentObj.BudgetADR = 0;
		If vAllotmentObj.RoomNights <> 0 Then
			vAllotmentObj.BudgetADR = Round(vAllotmentObj.BudgetReservationAmount/vAllotmentObj.RoomNights, 2);
		EndIf;
		vAllotmentObj.BudgetAmount = vAllotmentObj.BudgetReservationAmount + vAllotmentObj.BudgetMICEAmount;
		vAllotmentObj.Write();
	Except
		vMessage = cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	
	Return vMessage;
EndFunction // CalculateBusinessBlockBudget

#EndRegion