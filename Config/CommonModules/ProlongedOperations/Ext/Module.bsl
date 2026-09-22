
#Region tcDesktop

Procedure tcDesktop_GetRoomStatusesTable(pTempStorageAddress, pCurrentHotel) Export	
	vDate = CurrentSessionDate();
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Rooms.RoomStatus AS RoomStatus,
	|	SUM(1) AS RoomQuantity
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND NOT Rooms.IsVirtual
	|	AND NOT ISNULL(Rooms.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|	AND Rooms.OperationStartDate <= &qDate
	|	AND (Rooms.OperationEndDate >= &qDate
	|			OR Rooms.OperationEndDate = DATETIME(1, 1, 1, 0, 0, 0))
	|	AND (NOT &qHotelIsFilled
	|			OR &qHotelIsFilled
	|				AND Rooms.Owner IN HIERARCHY (&qHotel))
	|
	|GROUP BY
	|	Rooms.RoomStatus
	|
	|ORDER BY
	|	Rooms.RoomStatus.SortCode";
	
	vQuery.SetParameter("qDate", vDate);
	vQuery.SetParameter("qHotel", pCurrentHotel);
	vQuery.SetParameter("qHotelIsFilled", ValueIsFilled(pCurrentHotel));
	vQueryResult = vQuery.Execute().Unload();
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Rooms.RoomStatus AS RoomStatus,
	|	SUM(1) AS RoomQuantity,
	|	Rooms.RoomType AS RoomType
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND NOT Rooms.IsVirtual
	|	AND NOT ISNULL(Rooms.RoomType.DoesNotAffectRoomRevenueStatistics, FALSE)
	|	AND Rooms.OperationStartDate <= &qDate
	|	AND (Rooms.OperationEndDate >= &qDate
	|			OR Rooms.OperationEndDate = DATETIME(1, 1, 1, 0, 0, 0))
	|	AND (NOT &qHotelIsFilled
	|			OR &qHotelIsFilled
	|				AND Rooms.Owner IN HIERARCHY (&qHotel))
	|
	|GROUP BY
	|	Rooms.RoomStatus,
	|	Rooms.RoomType
	|
	|ORDER BY
	|	Rooms.RoomStatus.SortCode,
	|	Rooms.RoomType.SortCode";
	
	vQuery.SetParameter("qDate", vDate);
	vQuery.SetParameter("qHotel", pCurrentHotel);
	vQuery.SetParameter("qHotelIsFilled", ValueIsFilled(pCurrentHotel));
	vQueryDetailedResult = vQuery.Execute().Unload();
	
	vType = New Array();
    vType.Add(Type("CatalogRef.RoomStatuses"));
	vType.Add(Type("CatalogRef.RoomTypes"));
	vRoomsTable = New ValueTree();
	vRoomsTable.Columns.Add("RoomStatus", New TypeDescription(vType));
	vRoomsTable.Columns.Add("RoomQuantity", New TypeDescription("Number")); 
	
	For Each vRow In vQueryResult Do
		vNewParentRow = vRoomsTable.Rows.Add();
		vNewParentRow.RoomStatus = vRow.RoomStatus; 
		vNewParentRow.RoomQuantity = vRow.RoomQuantity;
		vDetailedInformationRows = vQueryDetailedResult.FindRows(New Structure("RoomStatus", vRow.RoomStatus));
		For Each vDetailedInformationRow In vDetailedInformationRows Do
			vNewChildRow = vNewParentRow.Rows.Add();
			vNewChildRow.RoomStatus = vDetailedInformationRow.RoomType;
			vNewChildRow.RoomQuantity = vDetailedInformationRow.RoomQuantity; 
		EndDo;
	EndDo;
		
	PutToTempStorage(vRoomsTable, pTempStorageAddress);
EndProcedure

Procedure tcDesktop_GetSummaryPercent(pTempStorageAddress, pCurrentHotel) Export
	Var TotalPerDay;
	vDate = tcOnServer.GetForecastStartDate(pCurrentHotel);
	vBegOfPeriod = BegOfDay(vDate);
	vEndOfPeriod = EndOfDay(vDate);
	// Initialize typesof data to show
	vInRooms = True;
	If ValueIsFilled(pCurrentHotel) Then
		vInRooms = Not pCurrentHotel.ShowReportsInBeds;
	EndIf;
	
	// Run query to get total number of rooms, rooms blocked, vacant number of rooms
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventoryBalanceAndTurnovers.Period AS Period,
	|	SUM(RoomInventoryBalanceAndTurnovers.CounterClosingBalance) AS CounterClosingBalance,
	|	SUM(RoomInventoryBalanceAndTurnovers.TotalRoomsClosingBalance) AS TotalRoomsClosingBalance,
	|	SUM(RoomInventoryBalanceAndTurnovers.TotalBedsClosingBalance) AS TotalBedsClosingBalance,
	|	-SUM(RoomInventoryBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
	|	-SUM(RoomInventoryBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			NOT &qHotelIsFilled
	|				OR &qHotelIsFilled
	|					AND Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryBalanceAndTurnovers
	|
	|GROUP BY
	|	RoomInventoryBalanceAndTurnovers.Period
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", pCurrentHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pCurrentHotel));
	vQryResult = vQry.Execute().Unload();
	
	vResources = "TotalRoomsClosingBalance, TotalBedsClosingBalance, RoomsBlockedClosingBalance, BedsBlockedClosingBalance";
	TotalPerDay = tcDesktop_GetQResultTableTotals(TotalPerDay, vQryResult, vQryResult, vResources);
	vTotalRooms = cmCastToNumber(TotalPerDay.TotalRoomsClosingBalance);
	vTotalBeds = cmCastToNumber(TotalPerDay.TotalBedsClosingBalance);	
	vBlockedRooms = cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
	vBlockedBeds = cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
	vRoomsForSale = vTotalRooms - vBlockedRooms;
	vBedsForSale = vTotalBeds - vBlockedBeds;
	
	// Run query to get number of blocked rooms per room block types
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType AS RoomBlockType,
	|	RoomBlocksBalanceAndTurnovers.Period AS Period,
	|	SUM(RoomBlocksBalanceAndTurnovers.RoomsBlockedClosingBalance) AS RoomsBlockedClosingBalance,
	|	SUM(RoomBlocksBalanceAndTurnovers.BedsBlockedClosingBalance) AS BedsBlockedClosingBalance
	|FROM
	|	AccumulationRegister.RoomBlocks.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			NOT &qHotelIsFilled
	|				OR &qHotelIsFilled
	|					AND Hotel IN HIERARCHY (&qHotel)) AS RoomBlocksBalanceAndTurnovers
	|
	|GROUP BY
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType,
	|	RoomBlocksBalanceAndTurnovers.Period
	|
	|ORDER BY
	|	RoomBlocksBalanceAndTurnovers.RoomBlockType.SortCode,
	|	Period";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", pCurrentHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pCurrentHotel));
	vQryResult = vQry.Execute().Unload();
	
	// Get list of room block types
	vSpecRoomsBlocked = 0;
	vSpecBedsBlocked = 0;
	vRoomBlockTypes = vQryResult.Copy();
	vRoomBlockTypes.GroupBy("RoomBlockType");
	If vQryResult.Count() > 0 Then
		// Put room blocks per room block type
		For Each vRow In vRoomBlockTypes Do
			vRoomBlockType = vRow.RoomBlockType;
			
			// Get records for the current room block type only
			vQrySubresult = vQryResult.FindRows(New Structure("RoomBlockType", vRoomBlockType));
			TotalPerDay = tcDesktop_GetQResultTableTotals(TotalPerDay, vQrySubresult, vQryResult, "RoomsBlockedClosingBalance, BedsBlockedClosingBalance");
			
			If vInRooms Then
				vBlockedRooms = cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);					
				If vRoomBlockType.AddToRoomsRentedInSummaryIndexes Then
					vSpecRoomsBlocked = vSpecRoomsBlocked + cmCastToNumber(TotalPerDay.RoomsBlockedClosingBalance);
				EndIf;
			Else
				vBlockedBeds = cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);				
				If vRoomBlockType.AddToRoomsRentedInSummaryIndexes Then
					vSpecBedsBlocked = vSpecBedsBlocked + cmCastToNumber(TotalPerDay.BedsBlockedClosingBalance);
				EndIf;
			EndIf;
		EndDo;
	EndIf;	
	
	// Run query to get room sales
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomSalesTurnovers.Period AS Period,
	|	RoomSalesTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
	|	RoomSalesTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
	|	SUM(RoomSalesTurnovers.SalesTurnover) AS SalesTurnover,
	|	SUM(RoomSalesTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(RoomSalesTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(RoomSalesTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(RoomSalesTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(RoomSalesTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Day,
	|			NOT &qHotelIsFilled
	|				OR &qHotelIsFilled
	|					AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesTurnovers
	|
	|GROUP BY
	|	RoomSalesTurnovers.Period,
	|	RoomSalesTurnovers.RoomRate.IsComplimentary,
	|	RoomSalesTurnovers.RoomRate.IsHouseUse
	|
	|ORDER BY
	|	Period,
	|	RoomRateIsComplimentary,
	|	RoomRateIsHouseUse";
	vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
	vQry.SetParameter("qPeriodTo", vEndOfPeriod);
	vQry.SetParameter("qHotel", pCurrentHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pCurrentHotel));
	vQryResult = vQry.Execute().Unload();
	
	// Add forecast sales if period is set in the future
	If vEndOfPeriod >= EndOfDay(CurrentSessionDate() - 24 * 3600) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomSalesForecastTurnovers.Period AS Period,
		|	RoomSalesForecastTurnovers.RoomRate.IsComplimentary AS RoomRateIsComplimentary,
		|	RoomSalesForecastTurnovers.RoomRate.IsHouseUse AS RoomRateIsHouseUse,
		|	SUM(RoomSalesForecastTurnovers.SalesTurnover) AS SalesTurnover,
		|	SUM(RoomSalesForecastTurnovers.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
		|	SUM(RoomSalesForecastTurnovers.RoomRevenueTurnover) AS RoomRevenueTurnover,
		|	SUM(RoomSalesForecastTurnovers.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
		|	SUM(RoomSalesForecastTurnovers.RoomsRentedTurnover) AS RoomsRentedTurnover,
		|	SUM(RoomSalesForecastTurnovers.BedsRentedTurnover) AS BedsRentedTurnover
		|FROM
		|	AccumulationRegister.SalesForecast.Turnovers(&qPeriodFrom, &qPeriodTo, Day, 
		|			NOT &qHotelIsFilled
		|				OR &qHotelIsFilled
		|					AND Hotel IN HIERARCHY (&qHotel)) AS RoomSalesForecastTurnovers
		|GROUP BY
		|	RoomSalesForecastTurnovers.Period,
		|	RoomSalesForecastTurnovers.RoomRate.IsComplimentary,
		|	RoomSalesForecastTurnovers.RoomRate.IsHouseUse
		|ORDER BY
		|	Period,
		|	RoomRateIsComplimentary,
		|	RoomRateIsHouseUse";
		vQry.SetParameter("qPeriodFrom", vBegOfPeriod);
		vQry.SetParameter("qPeriodTo", vEndOfPeriod);
		vQry.SetParameter("qHotel", pCurrentHotel);
		vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pCurrentHotel));
		vForecastQryResult = vQry.Execute().Unload();
		
		// Merge forecast sales with real ones
		For Each vForecastRow In vForecastQryResult Do
			vFound = False;
			For Each vRow In vQryResult Do
				If vRow.Period = vForecastRow.Period And
					vRow.RoomRateIsComplimentary = vForecastRow.RoomRateIsComplimentary  
					And vRow.RoomRateIsHouseUse = vForecastRow.RoomRateIsHouseUse Then
					vFound = True;
					Break;
				EndIf;
			EndDo;
			If Not vFound Then
				vRow = vQryResult.Add();
				vRow.Period = vForecastRow.Period;
				vRow.RoomRateIsComplimentary = vForecastRow.RoomRateIsComplimentary;
				vRow.RoomRateIsHouseUse = vForecastRow.RoomRateIsHouseUse;
				vRow.SalesTurnover = 0;
				vRow.SalesWithoutVATTurnover = 0;
				vRow.RoomRevenueTurnover = 0;
				vRow.RoomRevenueWithoutVATTurnover = 0;
				vRow.RoomsRentedTurnover = 0;
				vRow.BedsRentedTurnover = 0;
			EndIf;
			vRow.SalesTurnover = vRow.SalesTurnover + vForecastRow.SalesTurnover;
			vRow.SalesWithoutVATTurnover = vRow.SalesWithoutVATTurnover + vForecastRow.SalesWithoutVATTurnover;
			vRow.RoomRevenueTurnover = vRow.RoomRevenueTurnover + vForecastRow.RoomRevenueTurnover;
			vRow.RoomRevenueWithoutVATTurnover = vRow.RoomRevenueWithoutVATTurnover + vForecastRow.RoomRevenueWithoutVATTurnover;
			vRow.RoomsRentedTurnover = vRow.RoomsRentedTurnover + vForecastRow.RoomsRentedTurnover;
			vRow.BedsRentedTurnover = vRow.BedsRentedTurnover + vForecastRow.BedsRentedTurnover;
		EndDo;
	EndIf;	
	
	vResources = "SalesTurnover, SalesWithoutVATTurnover, RoomRevenueTurnover, RoomRevenueWithoutVATTurnover, RoomsRentedTurnover, BedsRentedTurnover";
	
	// Split table to total and complimentary only
	vQryResultComplArray = vQryResult.Copy().FindRows(New Structure("RoomRateIsComplimentary", True));
	vQryResult.GroupBy("Period", vResources);
	vQryResultCompl = vQryResult.CopyColumns();
	For Each vRow In vQryResultComplArray Do
		vTabRow = vQryResultCompl.Add();
		FillPropertyValues(vTabRow, vRow);
	EndDo;
	vQryResultCompl.GroupBy("Period", vResources);
	
	// Put rooms rented
	TotalPerDay = tcDesktop_GetQResultTableTotals(TotalPerDay, vQryResult, vQryResult, vResources);
	If vInRooms Then
		vRoomsRented = cmCastToNumber(TotalPerDay.RoomsRentedTurnover);
	Else
		vBedsRented = cmCastToNumber(TotalPerDay.BedsRentedTurnover);
	EndIf;	
	// Put occupation percents	
	If vInRooms Then
		vResult = Round(?((vRoomsForSale + vSpecRoomsBlocked) <> 0, 100 * (vRoomsRented + vSpecRoomsBlocked) / (vRoomsForSale + vSpecRoomsBlocked), 0), 2);
	Else
		vResult = Round(?((vBedsForSale + vSpecBedsBlocked) <> 0, 100 * (vBedsRented + vSpecBedsBlocked) / (vBedsForSale + vSpecBedsBlocked), 0), 2);
	EndIf;
	
	PutToTempStorage(vResult,pTempStorageAddress);
EndProcedure // GetSummaryPercent

Function  tcDesktop_GetQResultTableTotals(pTotalPerDay, pTbl, pTemplate, pResources)
	// Convert pTbl to the value table if necessary
	vTbl = pTbl;
	If TypeOf(pTbl) = Type("Array") Then                 
		vTbl = pTemplate.CopyColumns();
		For Each vRow In pTbl Do
			vTblRow = vTbl.Add();
			FillPropertyValues(vTblRow, vRow);
		EndDo;
	EndIf;
	
	If vTbl.Count() = 0 Then
		vTbl.Add();
	EndIf;
	
	vTbl.GroupBy(, pResources);
	pTotalPerDay = vTbl.Get(0);
	Return pTotalPerDay;
EndFunction

Procedure tcDesktop_GetCheckInOutCount(pTempStorageAddress, pCurrentHotel) Export 
	vResult = New Structure("CheckInGuests, CheckInRooms, CheckInAdults, CheckInTeenagers, CheckInChildren, CheckInInfants, CheckOutGuests, CheckOutRooms, CheckOutAdults, CheckOutTeenagers, CheckOutChildren, CheckOutInfants", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
	
	vDate = tcOnServer.GetForecastStartDate(pCurrentHotel);
	
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	SUM(NestedSelect.CheckOutRooms) AS CheckOutRooms,
	|	SUM(NestedSelect.CheckOutGuests) AS CheckOutGuests,
	|	SUM(NestedSelect.CheckOutAdults) AS CheckOutAdults,
	|	SUM(NestedSelect.CheckOutTeenagers) AS CheckOutTeenagers,
	|	SUM(NestedSelect.CheckOutChildren) AS CheckOutChildren,
	|	SUM(NestedSelect.CheckOutInfants) AS CheckOutInfants,
	|	SUM(NestedSelect.CheckInGuests) AS CheckInGuests,
	|	SUM(NestedSelect.CheckInRooms) AS CheckInRooms,
	|	SUM(NestedSelect.CheckInAdults) AS CheckInAdults,
	|	SUM(NestedSelect.CheckInTeenagers) AS CheckInTeenagers,
	|	SUM(NestedSelect.CheckInChildren) AS CheckInChildren,
	|	SUM(NestedSelect.CheckInInfants) AS CheckInInfants
	|FROM
	|	(SELECT
	|		SUM(RoomInventory.InHouseRooms) AS CheckOutRooms,
	|		SUM(RoomInventory.InHouseGuests) AS CheckOutGuests,
	|		SUM(RoomInventory.InHouseAdults) AS CheckOutAdults,
	|		SUM(RoomInventory.InHouseTeenagers) AS CheckOutTeenagers,
	|		SUM(RoomInventory.InHouseChildren) AS CheckOutChildren,
	|		SUM(RoomInventory.InHouseInfants) AS CheckOutInfants,
	|		SUM(0) AS CheckInGuests,
	|		SUM(0) AS CheckInRooms,
	|		SUM(0) AS CheckInAdults,
	|		SUM(0) AS CheckInTeenagers,
	|		SUM(0) AS CheckInChildren,
	|		SUM(0) AS CheckInInfants
	|	FROM
	|		(SELECT
	|			CASE
	|				WHEN SUM(RoomInventoryMovements.ExpectedRoomsCheckedOut) < 0
	|					THEN 0
	|				ELSE SUM(RoomInventoryMovements.ExpectedRoomsCheckedOut)
	|			END AS InHouseRooms,
	|			SUM(RoomInventoryMovements.ExpectedBedsCheckedOut) AS InHouseBeds,
	|			SUM(RoomInventoryMovements.ExpectedGuestsCheckedOut) AS InHouseGuests,
	|			SUM(ISNULL(RoomInventoryMovements.Recorder.NumberOfAdults, 0)) AS InHouseAdults,
	|			SUM(ISNULL(RoomInventoryMovements.Recorder.NumberOfTeenagers, 0)) AS InHouseTeenagers,
	|			SUM(ISNULL(RoomInventoryMovements.Recorder.NumberOfChildren, 0)) AS InHouseChildren,
	|			SUM(ISNULL(RoomInventoryMovements.Recorder.NumberOfInfants, 0)) AS InHouseInfants
	|		FROM
	|			AccumulationRegister.RoomInventory AS RoomInventoryMovements
	|		WHERE
	|			RoomInventoryMovements.IsAccommodation
	|			AND RoomInventoryMovements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND (NOT &qHotelIsFilled
	|					OR &qHotelIsFilled
	|						AND RoomInventoryMovements.Hotel IN HIERARCHY (&qHotel))
	|			AND RoomInventoryMovements.Period <= &qPeriodTo
	|			AND RoomInventoryMovements.Period = RoomInventoryMovements.CheckOutDate
	|			AND RoomInventoryMovements.IsInHouse
	|			AND RoomInventoryMovements.IsCheckOut) AS RoomInventory
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(ExpectedCheckInMovements.GuestsReserved),
	|		SUM(ExpectedCheckInMovements.RoomsReserved),
	|		SUM(ISNULL(ExpectedCheckInMovements.Recorder.NumberOfAdults, 0)),
	|		SUM(ISNULL(ExpectedCheckInMovements.Recorder.NumberOfTeenagers, 0)),
	|		SUM(ISNULL(ExpectedCheckInMovements.Recorder.NumberOfChildren, 0)),
	|		SUM(ISNULL(ExpectedCheckInMovements.Recorder.NumberOfInfants, 0))
	|	FROM
	|		AccumulationRegister.RoomInventory AS ExpectedCheckInMovements
	|	WHERE
	|		ExpectedCheckInMovements.IsReservation
	|		AND ExpectedCheckInMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND (NOT &qHotelIsFilled
	|				OR &qHotelIsFilled
	|					AND ExpectedCheckInMovements.Hotel IN HIERARCHY (&qHotel))
	|		AND ExpectedCheckInMovements.Period < &qPeriodTo
	|		AND ExpectedCheckInMovements.Period = ExpectedCheckInMovements.CheckInDate) AS NestedSelect";
	vQry.SetParameter("qHotel", pCurrentHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pCurrentHotel));
	vQry.SetParameter("qPeriodTo", EndOfDay(vDate));
	
	vResultQry = vQry.Execute().Select();
	While vResultQry.Next() Do
		vResult.CheckInGuests		= ?(vResultQry.CheckInGuests = Null, 0, vResultQry.CheckInGuests);
		vResult.CheckInRooms 		= ?(vResultQry.CheckInRooms = Null, 0, vResultQry.CheckInRooms);
		vResult.CheckInAdults 		= ?(vResultQry.CheckInAdults = Null, 0, vResultQry.CheckInAdults);
		vResult.CheckInTeenagers	= ?(vResultQry.CheckInTeenagers = Null, 0, vResultQry.CheckInTeenagers);
		vResult.CheckInChildren 	= ?(vResultQry.CheckInChildren = Null, 0, vResultQry.CheckInChildren);
		vResult.CheckInInfants 		= ?(vResultQry.CheckInInfants = Null, 0, vResultQry.CheckInInfants);
		vResult.CheckOutGuests 		= ?(vResultQry.CheckOutGuests = Null, 0, vResultQry.CheckOutGuests);
		vResult.CheckOutRooms 		= ?(vResultQry.CheckOutRooms = Null, 0, vResultQry.CheckOutRooms);
		vResult.CheckOutAdults 		= ?(vResultQry.CheckOutAdults = Null, 0, vResultQry.CheckOutAdults);
		vResult.CheckOutTeenagers	= ?(vResultQry.CheckOutTeenagers = Null, 0, vResultQry.CheckOutTeenagers);
		vResult.CheckOutChildren 	= ?(vResultQry.CheckOutChildren = Null, 0, vResultQry.CheckOutChildren);
		vResult.CheckOutInfants		= ?(vResultQry.CheckOutInfants = Null, 0, vResultQry.CheckOutInfants);
	EndDo;
	
	PutToTempStorage(vResult, pTempStorageAddress);
EndProcedure

Procedure tcDesktop_GetInvoiceCount(pTempStorageAddress, pCurrentUser, pCurrentHotel) Export
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	COUNT(DocumentInvoice.Ref) AS RefCount,
	|	SUM(DocumentInvoice.Sum) AS Sum
	|FROM
	|	Document.ProformaInvoice AS DocumentInvoice
	|		LEFT JOIN AccumulationRegister.InvoiceAccounts.Balance(&qDate, ) AS InvoiceAccountsBalance
	|		ON (InvoiceAccountsBalance.Invoice = DocumentInvoice.Ref)
	|WHERE
	|	CASE
	|			WHEN DocumentInvoice.Posted
	|				THEN CASE
	|						WHEN DocumentInvoice.CheckDate <> &qEmptyDate
	|								AND BEGINOFPERIOD(DocumentInvoice.CheckDate, DAY) < BEGINOFPERIOD(&qCurrentDate, DAY)
	|								AND ISNULL(InvoiceAccountsBalance.SumBalance, 0) > 0
	|							THEN 6
	|						ELSE CASE
	|								WHEN ISNULL(DocumentInvoice.Sum, 0) - ISNULL(InvoiceAccountsBalance.SumBalance, 0) >= ISNULL(DocumentInvoice.Sum, 0)
	|									THEN 5
	|								ELSE CASE
	|										WHEN ISNULL(DocumentInvoice.Sum, 0) - ISNULL(InvoiceAccountsBalance.SumBalance, 0) > 0
	|											THEN 3
	|										ELSE 1
	|									END
	|							END
	|					END
	|			ELSE 0
	|		END IN (&qPayedStatus)
	|	AND (NOT &qHotelIsFilled
	|			OR &qHotelIsFilled
	|				AND DocumentInvoice.Hotel IN HIERARCHY (&qHotel))";
	If ValueIsFilled(pCurrentUser.Customer) Then
		vQry.Text = vQry.Text + " AND DocumentInvoice.AccountingCustomer IN HIERARCHY (&qCustomer) ";
		vQry.SetParameter("qCustomer", pCurrentUser.Customer);
	EndIf;
	vQry.SetParameter("qHotel", pCurrentHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pCurrentHotel));
	vQry.SetParameter("qDate", '39991231235959');
	vQry.SetParameter("qPayedStatus", 6);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vResultQry = vQry.Execute().Select();
	vResult = New Structure("Count, Sum", 0, 0);
	While vResultQry.Next() Do
		vResult.Count 	= vResultQry.RefCount;
		vResult.Sum 	= vResultQry.Sum;
	EndDo;
	PutToTempStorage(vResult,pTempStorageAddress);
EndProcedure // GetInvoiceCount

Procedure tcDesktop_GetInHouse(pTempStorageAddress, pCurrentHotel, pDate) Export 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(DISTINCT Accommodation.Room) AS Rooms,
	|	SUM(Accommodation.NumberOfAdults) AS InHouseAdults,
	|	SUM(Accommodation.NumberOfTeenagers) AS InHouseTeenagers,
	|	SUM(Accommodation.NumberOfChildren) AS InHouseChildren,
	|	SUM(Accommodation.NumberOfInfants) AS InHouseInfants
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND (NOT &qHotelIsFilled
	|			OR &qHotelIsFilled
	|				AND Accommodation.Hotel = &qHotel)";
	
	vQry.SetParameter("qHotel", pCurrentHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pCurrentHotel));
	vInvResult = vQry.Execute();
	
	vResult = New Structure("InHouseGuests, InHouseRooms, InHouseAdults, InHouseTeenagers, InHouseChildren, InHouseInfants", 0, 0, 0, 0, 0, 0);
	
	If Not vInvResult.IsEmpty() Then
		vRes = vInvResult.Select();
		vRes.Next();
		vResult.InHouseRooms = ?(vRes.Rooms = Null, 0, vRes.Rooms);
		vResult.InHouseAdults = ?(vRes.InHouseAdults = Null, 0, vRes.InHouseAdults);
		vResult.InHouseTeenagers = ?(vRes.InHouseTeenagers = Null, 0, vRes.InHouseTeenagers);
		vResult.InHouseChildren = ?(vRes.InHouseChildren = Null, 0, vRes.InHouseChildren);
		vResult.InHouseInfants = ?(vRes.InHouseInfants = Null, 0, vRes.InHouseInfants);
		vResult.InHouseGuests = vResult.InHouseAdults + vResult.InHouseTeenagers + vResult.InHouseChildren + vResult.InHouseInfants;
	EndIf;
	
	PutToTempStorage(vResult, pTempStorageAddress);
EndProcedure

#EndRegion

#Region GuestGroups

Function GuestGroups_SetRoomPrice(pObj, pRoomPrice)
	Try
		pObj.Prices.Clear();
		If ValueIsFilled(pObj.AccommodationType) And 
			pObj.AccommodationType.Type = Enums.AccomodationTypes.Room And 
			pRoomPrice > 0 Then
			vNewPrice = pObj.Prices.Add();
			If ValueIsFilled(pObj.RoomRate) Then
				vRoomRate = pObj.RoomRate;
			Else
				vRoomRate = pObj.Hotel.RoomRate;
			EndIf;
			vPrices = vRoomRate.GetObject().pmGetRoomRatePrices(pObj.CheckInDate, pObj.PriceCalculationDate, pObj.ClientType, 
			                                                    pObj.RoomType, pObj.AccommodationType, , , pObj.CheckInDate, pObj.CheckOutDate);
			If ValueIsFilled(pObj.ClientType) And (vPrices.Count() = 0 Or vPrices.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
				vPrices = vRoomRate.GetObject().pmGetRoomRatePrices(pObj.CheckInDate, pObj.PriceCalculationDate, Catalogs.ClientTypes.EmptyRef(), 
				                                                    pObj.RoomType, pObj.AccommodationType, , , pObj.CheckInDate, pObj.CheckOutDate);
			EndIf;
			For Each vPricesRow In vPrices Do
				If ValueIsFilled(vPricesRow.ServicePackage) Then
					Continue;
				EndIf;
				If vPricesRow.IsRoomRevenue Then
					vNewPrice.Service = vPricesRow.Service;
					vNewPrice.Unit = vPricesRow.Service.Unit;
					vNewPrice.Currency = vPricesRow.Currency;
					Break;
				EndIf;
			EndDo;
			vNewPrice.Price = pRoomPrice;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction

Function GuestGroups_SetGuestPrice(pObj, pGuestPrice)
	Try
		pObj.Prices.Clear();
		If pGuestPrice > 0 Then
			vNewPrice = pObj.Prices.Add();
			If ValueIsFilled(pObj.RoomRate) Then
				vRoomRate = pObj.RoomRate;
			Else
				vRoomRate = pObj.Hotel.RoomRate;
			EndIf;
			vPrices = vRoomRate.GetObject().pmGetRoomRatePrices(pObj.CheckInDate, pObj.PriceCalculationDate, pObj.ClientType, 
			                                                    pObj.RoomType, pObj.AccommodationType, , , pObj.CheckInDate, pObj.CheckOutDate);
			If ValueIsFilled(pObj.ClientType) And (vPrices.Count() = 0 Or vPrices.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
				vPrices = vRoomRate.GetObject().pmGetRoomRatePrices(pObj.CheckInDate, pObj.PriceCalculationDate, Catalogs.ClientTypes.EmptyRef(), 
				                                                    pObj.RoomType, pObj.AccommodationType, , , pObj.CheckInDate, pObj.CheckOutDate);
			EndIf;
			For Each vPricesRow In vPrices Do
				If ValueIsFilled(vPricesRow.ServicePackage) Then
					Continue;
				EndIf;
				If vPricesRow.IsRoomRevenue Then
					vNewPrice.Service = vPricesRow.Service;
					vNewPrice.Unit = vPricesRow.Service.Unit;
					vNewPrice.Currency = vPricesRow.Currency;
					Break;
				EndIf;
			EndDo;
			vNewPrice.Price = pGuestPrice;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // SetGuestPrice

Function GuestGroups_SetRoomRate(pObj, pRef, pRoomRate, pAccountingDate, pLineNumber, pTemplate)
	Try
		// New accommodation type
		vOldTemplate = pObj.AccommodationTemplate;
		vOldAccommodationType = pObj.AccommodationType;
		vOldRoomRate = pObj.RoomRate;
		vOldRoomType = ?(ValueIsFilled(pObj.RoomTypeUpgrade), pObj.RoomTypeUpgrade, pObj.RoomType);
		If ValueIsFilled(pAccountingDate) Then
			For Each vRRRow In pObj.RoomRates Do
				If ValueIsFilled(vRRRow.AccountingDate) And vRRRow.AccountingDate <= pAccountingDate Then
					If ValueIsFilled(vRRRow.RoomRate) Then
						vOldRoomRate = vRRRow.RoomRate;
					EndIf;
					If Not ValueIsFilled(pObj.RoomTypeUpgrade) And ValueIsFilled(vRRRow.RoomType) Then
						vOldRoomType = vRRRow.RoomType;
					EndIf;
					If ValueIsFilled(vRRRow.AccommodationType) Then
						vOldAccommodationType = vRRRow.AccommodationType;
					EndIf;
					If ValueIsFilled(vRRRow.AccommodationTemplate) Then
						vOldTemplate = vRRRow.AccommodationTemplate;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		vNewAccommodationType = Undefined;
		If pLineNumber > 0 Then
			vOldTemplate = ?(ValueIsFilled(vOldTemplate), vOldTemplate, pTemplate);
			vOverrides = New ValueTable();
			If ValueIsFilled(vOldTemplate) Then
				vOverrides = cmGetRoomRateOverrides(pRoomRate, pObj.Hotel, vOldTemplate, vOldRoomType);
			EndIf;
			If vOverrides.Count() > 0 Then
				vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vOldAccommodationType, pLineNumber));
				If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
					vNewAccommodationType = vOverrideRows.Get(0).ToAccommodationType;
				EndIf;
			Else
				// Restore accommodation type from template
				If ValueIsFilled(vOldTemplate) Then
					If vOldTemplate.AccommodationTypes.Count() > 0 And pLineNumber > 0 And ValueIsFilled(vOldTemplate.AccommodationTypes.Get(pLineNumber - 1).AccommodationType) Then
						vNewAccommodationType = vOldTemplate.AccommodationTypes.Get(pLineNumber - 1).AccommodationType;

						vOldRoomRateAccommodationType = Undefined;
						vOldRoomRateOverrides = cmGetRoomRateOverrides(pRef.RoomRate, pObj.Hotel, vOldTemplate, vOldRoomType);
						If vOldRoomRateOverrides.Count() > 0 Then
							vOldRoomRateOverridesRows = vOldRoomRateOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vNewAccommodationType, pLineNumber));
							If vOldRoomRateOverridesRows.Count() > 0 And ValueIsFilled(vOldRoomRateOverridesRows.Get(0).ToAccommodationType) Then
								vOldRoomRateAccommodationType = vOldRoomRateOverridesRows.Get(0).ToAccommodationType;
							EndIf;
						EndIf;
						If Not ValueIsFilled(vOldRoomRateAccommodationType) Then
							vNewAccommodationType = Undefined;
						ElsIf vOldRoomRateAccommodationType <> pRef.AccommodationType Then
							vNewAccommodationType = Undefined;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Process room rate change
		If ValueIsFilled(pAccountingDate) And BegOfDay(pObj.CheckInDate) < pAccountingDate And BegOfDay(pObj.CheckOutDate) >= pAccountingDate Then
			vRRRow = pObj.RoomRates.Find(pAccountingDate, "AccountingDate");
			If vRRRow = Undefined Then
				vRRRow = pObj.RoomRates.Add();
				vRRRow.AccountingDate = pAccountingDate;
			EndIf;
			vRRRow.RoomRate = pRoomRate;
			vRRRow.PriceCalculationDate = '00010101';
			If ValueIsFilled(vNewAccommodationType) Then
				vRRRow.AccommodationType = vNewAccommodationType;
			EndIf;
			pObj.RoomRates.Sort("AccountingDate, ChangeTime");
		Else
			// Update accommodation type
			If ValueIsFilled(vNewAccommodationType) Then
				pObj.AccommodationType = vNewAccommodationType;
			EndIf;
			// Fill room rate
			pObj.RoomRate = pRoomRate;
			// Check user permissions to use this room rate
			vRoomRatesAllowed = cmGetAllowedRoomRates(pObj.CheckInDate, pObj.CheckOutDate, cmGetReservationCreateDate(pRef), pObj.RoomType);
			If vRoomRatesAllowed.Count() > 0 Then
				If vRoomRatesAllowed.FindByValue(pObj.RoomRate) = Undefined Then
					pObj.RoomRate = Catalogs.RoomRates.EmptyRef();
					Return NStr("en='You do not have rights to use room rate choosen!';ru='Нет прав на использование выбранного тарифа!';de='Sie haben keine Rechte, den ausgewählten Tarif zu verwenden!'");
				EndIf;
			EndIf;
			// Room rate type
			If ValueIsFilled(pObj.RoomRate.RoomRateType) Then
				pObj.RoomRateType = pObj.RoomRate.RoomRateType;
			EndIf;
			// Source of business
			If ValueIsFilled(pObj.RoomRate.SourceOfBusiness) Then
				pObj.SourceOfBusiness = pObj.RoomRate.SourceOfBusiness;
			EndIf;
			// Marketing code
			If ValueIsFilled(pObj.RoomRate.MarketingCode) Then
				pObj.MarketingCode = pObj.RoomRate.MarketingCode;
			EndIf;
			// Client type
			If ValueIsFilled(pObj.RoomRate.ClientType) Then
				pObj.ClientType = pObj.RoomRate.ClientType;
				pObj.ClientTypeConfirmationText = pObj.RoomRate.ClientTypeConfirmationText;
			EndIf;
			// Company
			If ValueIsFilled(pObj.RoomRate.Company) Then
				pObj.Company = pObj.RoomRate.Company;
			EndIf;
			// Do not print rate
			If Not pObj.DoNotPrintRate Then
				pObj.DoNotPrintRate = pObj.RoomRate.DoNotPrintRate;
			EndIf;
			// Update first room rates row
			If pObj.RoomRates.Count() > 0 Then
				v1RRRow = pObj.RoomRates.Find(BegOfDay(pObj.CheckInDate), "AccountingDate");
				If v1RRRow = Undefined Then
					v1RRRow = pObj.RoomRates.Insert(0);
					v1RRRow.AccountingDate = BegOfDay(pObj.CheckInDate);
				EndIf;
				v1RRRow.RoomRate = pObj.RoomRate;
				v1RRRow.AccommodationType = pObj.AccommodationType;
				pObj.RoomRates.Sort("AccountingDate, ChangeTime");
			EndIf;
			// Reset price calculation date
			If pObj.RoomRate <> pRef.RoomRate Then
				pObj.PriceCalculationDate = '00010101';
			EndIf;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // SetRoomRate

Function GuestGroups_SetServicePackage(pObj, pServicePackage)
	Try
		pObj.ServicePackage = pServicePackage;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // SetServicePackage

Function GuestGroups_SetServicePackages(pObj, pServicePackagesStruct)
	Try
		If pServicePackagesStruct.ModificationMode = 0 Then
			pObj.ServicePackages.Clear();
		EndIf;
		If pServicePackagesStruct.ModificationMode = 0 Or pServicePackagesStruct.ModificationMode = 1 Then
			If pServicePackagesStruct.TermsAreUsed Then
				If pServicePackagesStruct.ServicePackages.Count() > 0 Then
					For Each vSPItem In pServicePackagesStruct.ServicePackages Do
						vSPStruct = vSPItem.Value;
						vSP = vSPStruct.ServicePackage;
						If vSP.IsPerPerson Or Not vSP.IsPerPerson And ValueIsFilled(pObj.AccommodationTemplate) Then
							vSPRow = pObj.ServicePackages.Add();
							FillPropertyValues(vSPRow, vSPStruct);
						EndIf;
					EndDo;
				EndIf;
			Else
				pObj.ServicePackage = Undefined;
				If pServicePackagesStruct.ServicePackages.Count() > 0 Then
					vIsFirstItem = True;
					For Each vSPItem In pServicePackagesStruct.ServicePackages Do
						vSPStruct = vSPItem.Value;
						vSP = vSPStruct.ServicePackage;
						If vSP.IsPerPerson Or Not vSP.IsPerPerson And ValueIsFilled(pObj.AccommodationTemplate) Then
							If vIsFirstItem And vSPStruct.Quantity = 1 And Not ValueIsFilled(vSPStruct.DateFrom) And Not ValueIsFilled(vSPStruct.DateTo) Then
								vIsFirstItem = False;
								pObj.ServicePackage = vSP;
							Else
								vSPRow = pObj.ServicePackages.Add();
								FillPropertyValues(vSPRow, vSPStruct);
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		ElsIf pServicePackagesStruct.ModificationMode = 2 Then // Remove packages
			For Each vSPItem In pServicePackagesStruct.ServicePackages Do
				vSPStruct = vSPItem.Value;
				i = 0;
				While i < pObj.ServicePackages.Count() Do
					vObjSPRow = pObj.ServicePackages.Get(i);
					If vObjSPRow.ServicePackage = vSPStruct.ServicePackage And 
					   vObjSPRow.Quantity = vSPStruct.Quantity And
					   vObjSPRow.DateFrom = vSPStruct.DateFrom And
					   vObjSPRow.DateTo = vSPStruct.DateTo Then
						pObj.ServicePackages.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // SetServicePackages

Function GuestGroups_SetDiscountType(pObj, pDiscountType)
	Try
		pObj.DiscountType = pDiscountType;
		If ValueIsFilled(pDiscountType) Then
			pObj.DiscountServiceGroup = pObj.DiscountType.DiscountServiceGroup;
			If pObj.DiscountType.IsAccumulatingDiscount Then
				// Fill manual services accumulation discounts
				For Each vCurRow In pObj.Services Do
					If vCurRow.IsManual Then
						If cmIsServiceInServiceGroup(vCurRow.Service, pObj.DiscountServiceGroup) Then
							pObj.pmCalculateAccumulationDiscountForAdditionalService(vCurRow);
							pObj.pmCalculateServiceDiscounts(vCurRow);
						Else
							vCurRow.DiscountType = Catalogs.DiscountTypes.EmptyRef();
							vCurRow.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
							vCurRow.Discount = 0;
							vCurRow.DiscountConfirmationText = "";
						EndIf;
					EndIf;
				EndDo;
			Else
				vDiscountTypeObj = pObj.DiscountType.GetObject();
				pObj.Discount = vDiscountTypeObj.pmGetDiscount(pObj.CheckInDate, , pObj.Hotel);
			EndIf;
		Else
			pObj.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
			pObj.Discount = 0;
			pObj.DiscountConfirmationText = "";
			// Clear manual services discounts
			For Each vCurRow In pObj.Services Do
				If vCurRow.IsManual And ValueIsFilled(vCurRow.DiscountType) Then
					vCurRow.DiscountType = Catalogs.DiscountTypes.EmptyRef();
					vCurRow.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
					vCurRow.Discount = 0;
					vCurRow.DiscountConfirmationText = "";
				EndIf;
			EndDo;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // SetDiscountType

Function GuestGroups_SetReservationStatus(pObj, pRef, pReservationStatus, pAnnulationReason)
	Try
		If TypeOf(pRef) = Type("DocumentRef.Reservation") Then
			pObj.ReservationStatus = pReservationStatus;
			pObj.AnnulationReason = pAnnulationReason;
			pObj.pmSetDoCharging();
			// Guarantee type
			If ValueIsFilled(pReservationStatus.GuaranteeType) Then
				pObj.GuaranteeType = pReservationStatus.GuaranteeType;
			EndIf;
		EndIf;
	Except
		vError = cmGetRootErrorDescription(ErrorInfo());
		WriteLogEvent("GuestGroups_SetReservationStatus", EventLogLevel.Error, , pRef, vError);
		Return vError;
	EndTry;
	Return "";
EndFunction // SetReservationStatus

Procedure GuestGroups_SetReservationsStatus(pGuestGroup, pReservationStatus, pFuncLogName) Export
	vReservations = pGuestGroup.GetObject().pmGetReservations(True, True);
	For Each vReservationsRow In vReservations Do
		If ValueIsFilled(vReservationsRow.Status) And vReservationsRow.Status.IsActive And vReservationsRow.Status <> pReservationStatus Then
			vReservationObj = vReservationsRow.Reservation.GetObject();
			vReservationObj.ReservationStatus = pReservationStatus;
			vReservationObj.pmSetDoCharging();
			Try
				vReservationObj.Write(DocumentWriteMode.Posting);
				// Write to the document change history
				vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			Except
				// Log exception if any
				WriteLogEvent(pFuncLogName, 
				              EventLogLevel.Warning, vReservationObj.Metadata(), vReservationObj.Ref, 
				              NStr("en = 'Error updating reservation status to '; 
							  	   |de = 'Fehler bei der Änderung des Reservierungsstatus für '; 
								   |ru = 'Ошибка при изменении статуса брони на '") + TrimAll(pReservationStatus) + ":" + Chars.LF + 
				              cmGetRootErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
	EndDo;
EndProcedure // GuestGroups_SetReservationsStatus

Function GuestGroups_SetAccommodationPeriod(vObj, pRef, pCheckInDate, pCheckOutDate)
	Try
		vObj.CheckInDate = cm1SecondShift(pCheckInDate);
		vObj.CheckOutDate = cm0SecondShift(pCheckOutDate);
		vObj.Duration = vObj.pmCalculateDuration();
		// Check user permissions to use this room rate
		vRoomRatesAllowed = cmGetAllowedRoomRates(vObj.CheckInDate, vObj.CheckOutDate, cmGetReservationCreateDate(pRef), vObj.RoomType);
		If vRoomRatesAllowed.Count() > 0 Then
			If vRoomRatesAllowed.FindByValue(vObj.RoomRate) = Undefined Then
				Return NStr("en='You do not have rights to use room rate choosen!';ru='Нет прав на использование выбранного тарифа!';de='Sie haben keine Rechte, den ausgewählten Tarif zu verwenden!'");
			EndIf;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // SetAccommodationPeriod

Procedure GuestGroups_AddPacketReservations(pList, pCurrentUser, ReservationsCount) Export
	vProgress = 0;
	If ReservationsCount > 0 Then
		vStep = 100/ReservationsCount;
		For i = 1 to ReservationsCount - 1 Do
			GuestGroups_AddPacketReservation(pList, pCurrentUser);
			vProgress = vProgress + vStep;
			tcCommonFunctionOnClientServer.UserMessage("<progress>" + vProgress + "</progress>");
		EndDo;
	EndIf;
EndProcedure

Procedure GuestGroups_AddPacketReservation(pList, pCurrentUser, pRoomQuantity = 0) Export
	vNewDocNumber = "";
	For Each pListItem In pList Do
		vTemplateDoc = pListItem.Value;
		vNewDocObj = vTemplateDoc.Copy();
		If Not IsBlankString(vNewDocNumber) Then
			vNewDocObj.Number = vNewDocNumber;
		EndIf;
		vNewDocObj.pmFillAuthorAndDate();
		vNewDocObj.Room = Catalogs.Rooms.EmptyRef();
		vNewDocObj.Guest = Catalogs.Clients.EmptyRef();
		vNewDocObj.GuestFullName = "";
		vNewDocObj.GuestAge = 0;
		// Clear occupation percents
		vNewDocObj.pmClearOccupationPercents();
		// Recalculate resources
		If pRoomQuantity > 0 Then
			vNewDocObj.RoomQuantity = pRoomQuantity;
			vAccommodationTemplate = vNewDocObj.AccommodationTemplate;
			If ValueIsFilled(vAccommodationTemplate) Then
				vNewDocObj.NumberOfAdults = vNewDocObj.RoomQuantity * vAccommodationTemplate.NumberOfAdults;
				vNewDocObj.NumberOfTeenagers = vNewDocObj.RoomQuantity * vAccommodationTemplate.NumberOfTeenagers;
				vNewDocObj.NumberOfChildren = vNewDocObj.RoomQuantity * vAccommodationTemplate.NumberOfChildren;
				vNewDocObj.NumberOfInfants = vNewDocObj.RoomQuantity * vAccommodationTemplate.NumberOfInfants;
				vNewDocObj.NumberOfPersons = vNewDocObj.RoomQuantity;
			EndIf;
		EndIf;
		// Calculate services
		vNewDocObj.pmCalculateServices( , , , , , vNewDocObj.IsForFolioSplit);
		// Write reservation
		vNewDocObj.Write(DocumentWriteMode.Posting);
		vNewDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), pCurrentUser);
		If IsBlankString(vNewDocNumber) Then
			vNewDocNumber = TrimAll(vNewDocObj.Number);
		EndIf;
	EndDo;
EndProcedure // AddPacketReservationsAtServer

Procedure GuestGroups_SplitRoomsFromBlock(pResRef, pQty, pAsBlock = False) Export
	vError = "";
    vErrorsCount = 0;
	vProgress = 0;
	vStep = 100 / ?(pQty <= 0, 1, pQty);
	
	vGuestGroup = pResRef.GuestGroup;
	
	vOneRoomDocs = cmGetOneRoomReservations(pResRef.Number, vGuestGroup, pResRef.CheckInDate, pResRef.CheckOutDate);
	For i = ?(pAsBlock, pQty, 1) To pQty Do
		Try
			BeginTransaction(DataLockControlMode.Managed);

			vError = "";

			vMainRoomDoc = Undefined;
			vMainRoomDocNumber = "";
			For Each vOneRoomDocsRow In vOneRoomDocs Do
				vBaseRef = vOneRoomDocsRow.Ref;
				
				// Create new reservation
				vResObj = vBaseRef.Copy();
				
				// Fill number
				If Not IsBlankString(vMainRoomDocNumber) Then
					vResObj.Number = vMainRoomDocNumber;
				EndIf;
				
				// Initialize attributes
				vResObj.pmFillAuthorAndDate();
				vResObj.Room = Undefined;
				vResObj.Guest = Undefined;
				vResObj.GuestFullName = "";
				vResObj.GuestAge = 0;
				vResObj.EMail = "";
				vResObj.Phone = "";
				vResObj.Fax = "";
				
				vResObj.WaitTillDate = '00010101';
				
				vResObj.RoomQuantity = ?(pAsBlock, pQty, 1);
				vResObj.NumberOfBeds = Round(vBaseRef.NumberOfBeds / ?(vBaseRef.RoomQuantity = 0, 1, vBaseRef.RoomQuantity), 0);
				vResObj.NumberOfRooms = Round(vBaseRef.NumberOfRooms / ?(vBaseRef.RoomQuantity = 0, 1, vBaseRef.RoomQuantity), 0);
				vResObj.NumberOfAdditionalBeds = Round(vBaseRef.NumberOfAdditionalBeds / ?(vBaseRef.RoomQuantity = 0, 1, vBaseRef.RoomQuantity), 0);
				vResObj.NumberOfPersons = ?(pAsBlock, pQty, 1);
				vResObj.NumberOfAdults = Round(vBaseRef.NumberOfAdults / ?(vBaseRef.RoomQuantity = 0, 1, vBaseRef.RoomQuantity), 0) * ?(pAsBlock, pQty, 1);
				vResObj.NumberOfTeenagers = Round(vBaseRef.NumberOfTeenagers / ?(vBaseRef.RoomQuantity = 0, 1, vBaseRef.RoomQuantity), 0) * ?(pAsBlock, pQty, 1);
				vResObj.NumberOfChildren = Round(vBaseRef.NumberOfChildren / ?(vBaseRef.RoomQuantity = 0, 1, vBaseRef.RoomQuantity), 0) * ?(pAsBlock, pQty, 1);
				vResObj.NumberOfInfants = Round(vBaseRef.NumberOfInfants / ?(vBaseRef.RoomQuantity = 0, 1, vBaseRef.RoomQuantity), 0) * ?(pAsBlock, pQty, 1);
				
				vResObj.pmCalculateResources();
				
				// Charging rules
				If vMainRoomDoc = Undefined Then
					// Create folios as copy of base folios
					cmCreateChargingRulesBasedOnParent(vResObj, vBaseRef);
				Else
					// Use folios from the main room document
					cmUseParentChargingRules(vResObj, vMainRoomDoc, True);
				EndIf;
				
				// Calculate services
				vResObj.pmCalculateServices( , , , , , vResObj.IsForFolioSplit);
				
				// Update base document
				vBaseObj = vBaseRef.GetObject();
				vBaseObj.RoomQuantity = vBaseObj.RoomQuantity - vResObj.RoomQuantity;
				vBaseObj.NumberOfPersons = vBaseObj.NumberOfPersons - vResObj.NumberOfPersons;
				vBaseObj.NumberOfAdults = vBaseObj.NumberOfAdults - vResObj.NumberOfAdults;
				vBaseObj.NumberOfTeenagers = vBaseObj.NumberOfTeenagers - vResObj.NumberOfTeenagers;
				vBaseObj.NumberOfChildren = vBaseObj.NumberOfChildren - vResObj.NumberOfChildren;
				vBaseObj.NumberOfInfants = vBaseObj.NumberOfInfants - vResObj.NumberOfInfants;
				
				// Cutoff date
				If vBaseObj.RoomQuantity = 1 Then
					vBaseObj.WaitTillDate = '00010101';
				EndIf;
				
				// Recalculate base document resources
				vBaseObj.pmCalculateResources();
				
				// Calculate services
				vBaseObj.pmCalculateServices( , , , , , vBaseObj.IsForFolioSplit);
				
				// Write reservation
				vBaseObj.Write(DocumentWriteMode.Posting);
				
				// Write reservation
				vResObj.Write(DocumentWriteMode.Posting);

				// Read base document custom attributes
				vCustomFields = cmGetReservationCustomFieldsValues(vBaseObj.Ref);
				// Write custom attributes to the new document
				For Each vCustomFieldsRow In vCustomFields Do
					vRcdMgr = InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
					vRcdMgr.Owner = vResObj.Ref;
					vRcdMgr.Characteristic = vCustomFieldsRow.Characteristic;
					vRcdMgr.CharacteristicValue = vCustomFieldsRow.CharacteristicValue;
					vRcdMgr.Write(True);
				EndDo;

				// Write to reservation change history
				vResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				
				// Save parameters of main room document
				If vMainRoomDoc = Undefined Then
					vMainRoomDoc = vResObj.Ref;
					vMainRoomDocNumber = TrimR(vResObj.Number);
				EndIf;
			EndDo;
			
			CommitTransaction();
			
			// Wait 1 second to allow other users to do something while splitting huge groups
			cmWait(1);
		Except
			vError = cmGetRootErrorDescription(ErrorInfo());
			WriteLogEvent("GuestGroups_SplitRoomsFromBlock", EventLogLevel.Error, , , vError);
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
		    vErrorsCount = vErrorsCount + 1;
			If vErrorsCount > 10 Then
				Break;
			EndIf;
			i = i - 1;
			vProgress = vProgress - vStep;
			
			// Wait 5 second to allow other users to finish what they are doing
			cmWait(5);
		EndTry;
		
		vProgress = vProgress + vStep;
		tcCommonFunctionOnClientServer.UserMessage("<progress>" + vProgress + "</progress>");
	EndDo;
	
	// Write to base documents change history
	Try
		For Each vOneRoomDocsRow In vOneRoomDocs Do
			vBaseRef = vOneRoomDocsRow.Ref;
			vBaseObj = vBaseRef.GetObject();
			vBaseObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndDo;
	Except
	EndTry;

	If IsBlankString(vError) Then
		If ValueIsFilled(vGuestGroup) And vGuestGroup.TouristicTaxIsCalculatedForMainGroupDocumentOnly And 
		   ValueIsFilled(vGuestGroup.ClientDoc) And vGuestGroup.ClientDoc.Posted And 
		  (TypeOf(vGuestGroup.ClientDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vGuestGroup.ClientDoc) = Type("DocumentRef.Reservation")) Then
			vObj = vGuestGroup.ClientDoc.GetObject();
			vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit);
			vObj.Write(DocumentWriteMode.Posting);
			If TypeOf(vObj) = Type("DocumentObject.Accommodation") Then
				vObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			ElsIf TypeOf(vObj) = Type("DocumentObject.Reservation") Then
				vObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
		EndIf;
	EndIf;
	
	// Raise error if ther were more then 10 errors while splitting block
	If Not IsBlankString(vError) And vErrorsCount > 10 Then
		Raise vError;
	EndIf;
EndProcedure // GuestGroups_SplitRoomsFromBlock

Procedure GuestGroups_SplitRoomsFromBlocks(pBlocksList, pQty, pAsBlock = False) Export
	For Each vBlocksListItem In pBlocksList Do
		// Get quantity to split
		vBlockRef = vBlocksListItem.Value;
		vRoomQuantity = tcOnServer.cmGetAttributeByRef(vBlockRef, "RoomQuantity");
		If vRoomQuantity > 1 Then
			vQty = 1;
			If pQty = -1 Then
				vQty = vRoomQuantity - 1;
			ElsIf pQty > 0 And pQty < vRoomQuantity Then
				vQty = pQty;
			EndIf;
			
			// Do split
			GuestGroups_SplitRoomsFromBlock(vBlockRef, vQty, pAsBlock);
		EndIf;
	EndDo;
EndProcedure // GuestGroups_SplitRoomsFromBlocks

Function GuestGroups_SetMarketingCode(pObj, pMarketingCode)
	Try
		pObj.MarketingCode = pMarketingCode;
		If ValueIsFilled(pObj.MarketingCode) Then
			If Not ValueIsFilled(pObj.RoomRateType) Then
				pObj.RoomRateType = pObj.MarketingCode.RoomRateType;
			EndIf;
		EndIf;

	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetMarketingCode

Function GuestGroups_SetSourceOfBusiness(pObj, pSourceOfBusiness)
	Try
		pObj.SourceOfBusiness = pSourceOfBusiness;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetSourceOfBusiness

Function GuestGroups_SetTripPurpose(pObj, pTripPurpose)
	Try
		pObj.TripPurpose = pTripPurpose;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetTripPurpose

Function GuestGroups_SetBoardPlace(pObj, pBoardPlace, pAccountingDate)
	Try
		If ValueIsFilled(pAccountingDate) And BegOfDay(pObj.CheckInDate) < pAccountingDate And BegOfDay(pObj.CheckOutDate) >= pAccountingDate Then
			vRRRow = pObj.RoomRates.Find(pAccountingDate, "AccountingDate");
			If vRRRow = Undefined Then
				vRRRow = pObj.RoomRates.Add();
				vRRRow.AccountingDate = pAccountingDate;
			EndIf;
			vRRRow.BoardPlace = pBoardPlace;
			pObj.RoomRates.Sort("AccountingDate, ChangeTime");
		Else
			pObj.BoardPlace = pBoardPlace;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetBoardPlace

Function GuestGroups_SetGuest(pObj, pGuest)
	Try
		pObj.Guest = pGuest;
		If ValueIsFilled(pObj.Guest) Then
			If ValueIsFilled(pObj.Guest.ClientType) Then
				pObj.ClientType = pObj.Guest.ClientType;
			EndIf;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetGuest

Function GuestGroups_SetClientType(pObj, pClientType)
	Try
		pObj.ClientType = pClientType;
		If ValueIsFilled(pObj.ClientType) Then
			If ValueIsFilled(pObj.ClientType.Parent) 
				And ValueIsFilled(pObj.ClientType.Parent.HotelProduct) 
				And Not ValueIsFilled(pObj.ClientType.HotelProduct) 
				And Not ValueIsFilled(pObj.HotelProduct) Then 
				pObj.HotelProduct = pObj.ClientType.Parent.HotelProduct;
			ElsIf ValueIsFilled(pObj.ClientType.HotelProduct) And Not ValueIsFilled(pObj.HotelProduct) Then
				pObj.HotelProduct = pObj.ClientType.HotelProduct;
			EndIf;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetClientType

Function GuestGroups_SetBedsSetup(pObj, pBedsSetup)
	Try
		If ValueIsFilled(pObj.RoomType) And pObj.RoomType.AllowedBedsSetups.Find(pBedsSetup, "BedsSetup") <> Undefined Then
			pObj.BedsSetup = pBedsSetup;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetBedsSetup

Function GuestGroups_SetAgentCommission(pObj, pAgentCommission)
	Try
		pObj.AgentCommission = pAgentCommission;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetAgentCommission

Function GuestGroups_SetGuaranteeType(vObj, pGuaranteeType)
	Try
		vObj.GuaranteeType = pGuaranteeType;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetGuaranteeType

Function GuestGroups_SetFixedCharges(vObj, pFixedChargesStruct)
	// Process documents of the same accommodation type only
	If Not ValueIsFilled(pFixedChargesStruct.FixedChargesCopyFrom) Then
		Return "";
	EndIf;
	vBasisDoc = pFixedChargesStruct.FixedChargesCopyFrom;
	If vBasisDoc = vObj.Ref Then
		Return "";
	EndIf;
	If vObj.AccommodationType <> vBasisDoc.AccommodationType Then
		Return "";
	EndIf;
	Try
		// Delete old manual services from the document
		If pFixedChargesStruct.ModificationMode = 1 Then
			vInt = 0;
			While vInt < vObj.Services.Count() Do
				vSrvRow = vObj.Services.Get(vInt);
				If vSrvRow.IsManual Then
					vObj.Services.Delete(vInt);
				Else
					vInt = vInt + 1;
				EndIf;
			EndDo;
		EndIf;
		// Add manual postings from the basis document
		For Each vBasisSrvRow In vBasisDoc.Services Do
			If vBasisSrvRow.IsManual Then
				vSrvRow = vObj.Services.Add();
				FillPropertyValues(vSrvRow, vBasisSrvRow, , "LineNumber, ClientType, SourceOfBusiness, MarketingCode, BoardPlace, IsManualAuthor, IsManualDate, DoResourceReservation, RateSum, RoomType, Room, AccommodationType, RoomRate, GuestsCheckedIn, GuestDays, AdditionalBedsRented, BedsRented, RoomsRented, PriceTag, CalendarDayType");
				// Check service charging rules
				vBasisCRRow = vBasisDoc.ChargingRules.Find(vBasisSrvRow.Folio, "ChargingFolio");
				If vBasisCRRow <> Undefined And Not vBasisCRRow.IsTransfer Then
					vChargingRules = vObj.ChargingRules.Unload();
					If Not vObj.IgnoreGroupChargingRules Then
						cmAddGuestGroupChargingRules(vChargingRules, vObj.GuestGroup);
					EndIf;
					vObj.pmSetServiceFolioBasedOnChargingRules(vSrvRow, vChargingRules, True);
					If ValueIsFilled(vSrvRow.Folio) Then
						vSrvRow.FolioCurrency = vSrvRow.Folio.FolioCurrency;
						vSrvRow.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vSrvRow.FolioCurrency, ?(ValueIsFilled(vSrvRow.AccountingDate), vSrvRow.AccountingDate, vObj.ExchangeRateDate));
					EndIf;
				EndIf;
				// Discounts
				vObj.pmCalculateServiceDiscounts(vSrvRow);
				// Calculate commission for this service if applicable
				vComplexCommission = vObj.pmGetComplexCommission();
				vRoomRates = vObj.pmGetAccommodationPlan();
				vObj.pmSetServiceCommissions(vSrvRow, vRoomRates, vComplexCommission);
			EndIf;
		EndDo;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetFixedCharges

Function GuestGroups_SetChargingRules(vObj, pChargingRulesStruct)
	Try
		// Find charging rule with folio of the given type
		If ValueIsFilled(pChargingRulesStruct.ChargingRuleFolio) Then
			vNewCRRow = vObj.ChargingRules.Insert(0);
			vNewCRRow.ChargingRule = pChargingRulesStruct.ChargingRule; 
			vNewCRRow.ChargingRuleValue = pChargingRulesStruct.ChargingRuleValue; 
			vNewCRRow.ChargingFolio = pChargingRulesStruct.ChargingRuleFolio; 
			vNewCRRow.ValidFromDate = pChargingRulesStruct.ValidFromDate; 
			vNewCRRow.ValidToDate = pChargingRulesStruct.ValidToDate; 
			vNewCRRow.IsTransfer = True;
			vNewCRRow.IsMaster = vNewCRRow.ChargingFolio.IsMaster;
			If ValueIsFilled(vNewCRRow.ChargingFolio.Contract) Then
				vNewCRRow.Owner = vNewCRRow.ChargingFolio.Contract;
			ElsIf ValueIsFilled(vNewCRRow.ChargingFolio.Customer) Then
				vNewCRRow.Owner = vNewCRRow.ChargingFolio.Customer;
			ElsIf ValueIsFilled(vNewCRRow.ChargingFolio.Client) Then
				vNewCRRow.Owner = vNewCRRow.ChargingFolio.Client;
			EndIf;
		Else
			vCRRowFound = Undefined;
			For Each vCRRow In vObj.ChargingRules Do
				If ValueIsFilled(vCRRow.ChargingFolio) And lower(TrimAll(vCRRow.ChargingFolio.Description)) = lower(TrimAll(pChargingRulesStruct.FolioDescription)) Then
					vCRRowFound = vCRRow;
					Break;
				EndIf;
			EndDo;
			If vCRRowFound <> Undefined And ValueIsFilled(vCRRowFound.ChargingFolio) Then
				vNewCRRow = vObj.ChargingRules.Insert(0);
				FillPropertyValues(vNewCRRow, vCRRowFound);
				vNewCRRow.ChargingRule = pChargingRulesStruct.ChargingRule; 
				vNewCRRow.ChargingRuleValue = pChargingRulesStruct.ChargingRuleValue; 
				vNewCRRow.ValidFromDate = pChargingRulesStruct.ValidFromDate; 
				vNewCRRow.ValidToDate = pChargingRulesStruct.ValidToDate; 
			EndIf;
		EndIf;
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetChargingRules

Function GuestGroups_SetExtra(vObj, pExtra)
	Try
		If pExtra.Name = "PlannedPaymentMethod" And ValueIsFilled(pExtra.Value) Then   
			vObj[pExtra.Name] = pExtra.Value;
			PlannedPaymentMethodOnChangeAtServer(vObj);
		Else
			If pExtra.Name = "DoChargingToDate" Then
				If TypeOf(vObj) = Type("DocumentObject.Accommodation") Then
					vObj[pExtra.Name] = pExtra.Value;
				EndIf;
			Else
				vObj[pExtra.Name] = pExtra.Value;
			EndIf;
		EndIf
	Except
		Return cmGetRootErrorDescription(ErrorInfo());
	EndTry;
	Return "";
EndFunction // GuestGroups_SetExtra

Procedure PlannedPaymentMethodOnChangeAtServer(pObj)
	If ValueIsFilled(pObj.PlannedPaymentMethod) Then
		vFolioToUpdate = Undefined;
		vChargingRules = pObj.ChargingRules.Unload();
		If Not pObj.IgnoreGroupChargingRules Then
			cmAddGuestGroupChargingRules(vChargingRules, pObj.GuestGroup);
		EndIf;
		If vChargingRules.Count() > 0 Then
			// Set planned payment method to the accommodation service folio
			If pObj.Services.Count() > 0 Then
				vIndx = pObj.Services.Count() - 1;
				While vIndx >= 0 Do
					vSrvRow = pObj.Services.Get(vIndx);
					If ValueIsFilled(vSrvRow.Folio) Then
						If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice And Not vSrvRow.RoomRevenueAmountsOnly Then
							vFolioToUpdate = vSrvRow.Folio;
							Break;
						EndIf;
					EndIf;
					vIndx = vIndx - 1;
				EndDo;
			EndIf;
			If Not ValueIsFilled(vFolioToUpdate) Then
				// Set planned payment method to the folio from the first charging rule
				vCRRow = vChargingRules.Get(0);
				If ValueIsFilled(vCRRow.ChargingFolio) Then
					vFolioToUpdate = vCRRow.ChargingFolio;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vFolioToUpdate) Then
			If vFolioToUpdate.PaymentMethod <> pObj.PlannedPaymentMethod Then
				vFolioObj = vFolioToUpdate.GetObject();
				vFolioObj.PaymentMethod = pObj.PlannedPaymentMethod;
				vFolioObj.Write(DocumentWriteMode.Write);
			Endif;
		EndIf;
	EndIf;
EndProcedure // PlannedPaymentMethodOnChangeAtServer

Procedure GuestGroups_SetCustom(pRef, pCustomField, pValue)
	vRef = pRef;
	If TypeOf(vRef) = Type("DocumentRef.Accommodation") And 
	   ValueIsFilled(vRef.Reservation) Then
		vRef = pRef.Reservation;
	EndIf;
	vRcdMgr = InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
	vRcdMgr.Owner = vRef;
	vRcdMgr.Characteristic = pCustomField;
	vRcdMgr.CharacteristicValue = pValue;
	vRcdMgr.Write(True);
EndProcedure // GuestGroups_SetCustom  

Procedure GuestGroups_SetAllAttributes(pRefList, pCheckAttribute, pValueAttribute, pCustomFieldsList) Export
	vTemplate = Undefined;
	vGuestGroup = Undefined;
	vProgress = 0;
	If pRefList.Count() > 0 Then
		vStep = 100 / pRefList.Count();
		For Each vRefListRow In pRefList Do
			vObj = vRefListRow.Value.GetObject();
			If vGuestGroup = Undefined Then
				vGuestGroup = vObj.GuestGroup;
			EndIf;

			vLineNumber = 0;
			If Not IsBlankString(vRefListRow.Presentation) And cmIsNumber(vRefListRow.Presentation) Then
				vLineNumber = Number(vRefListRow.Presentation);
			EndIf;

			vError = "";
			If pCheckAttribute.RoomPrice And IsBlankString(vError) Then
				vError = GuestGroups_SetRoomPrice(vObj, pValueAttribute.RoomPrice);	
			EndIf;
			If pCheckAttribute.GuestPrice And IsBlankString(vError) Then
				vError = GuestGroups_SetGuestPrice(vObj, pValueAttribute.GuestPrice);	
			EndIf;
			If pCheckAttribute.RoomRate And IsBlankString(vError) Then
				If vLineNumber = 1 Then
					vTemplate = vObj.AccommodationTemplate;
				EndIf;
				vError = GuestGroups_SetRoomRate(vObj, vRefListRow.Value, pValueAttribute.RoomRate.RoomRate, pValueAttribute.RoomRate.AccountingDate, vLineNumber, vTemplate);	
			EndIf;
			If pCheckAttribute.ServicePackage And IsBlankString(vError) Then
				vError = GuestGroups_SetServicePackage(vObj, pValueAttribute.ServicePackage);	
			EndIf;
			If pCheckAttribute.ServicePackages And IsBlankString(vError) Then
				vError = GuestGroups_SetServicePackages(vObj, pValueAttribute.ServicePackages);	
			EndIf;
			If pCheckAttribute.DiscountType And IsBlankString(vError) Then
				vError = GuestGroups_SetDiscountType(vObj, pValueAttribute.DiscountType);	
			EndIf;
			If pCheckAttribute.MarketingCode And IsBlankString(vError) Then
				vError = GuestGroups_SetMarketingCode(vObj, pValueAttribute.MarketingCode);	
			EndIf;
			If pCheckAttribute.SourceOfBusiness And IsBlankString(vError) Then
				vError = GuestGroups_SetSourceOfBusiness(vObj, pValueAttribute.SourceOfBusiness);	
			EndIf;
			If pCheckAttribute.TripPurpose And IsBlankString(vError) Then
				vError = GuestGroups_SetTripPurpose(vObj, pValueAttribute.TripPurpose);	
			EndIf;
			If pCheckAttribute.BoardPlace And IsBlankString(vError) Then
				vError = GuestGroups_SetBoardPlace(vObj, pValueAttribute.BoardPlace.BoardPlace, pValueAttribute.BoardPlace.AccountingDate);
			EndIf;
			If pCheckAttribute.Guest And IsBlankString(vError) Then
				vError = GuestGroups_SetGuest(vObj, pValueAttribute.Guest); 	
			EndIf;
			If pCheckAttribute.ClientType And IsBlankString(vError) Then
				vError = GuestGroups_SetClientType(vObj, pValueAttribute.ClientType);	
			EndIf;
			If pCheckAttribute.AgentCommission And IsBlankString(vError) Then
				vError = GuestGroups_SetAgentCommission(vObj, pValueAttribute.AgentCommission);	
			EndIf;
			If pCheckAttribute.ReservationStatus And IsBlankString(vError) Then
				vError = GuestGroups_SetReservationStatus(vObj, vRefListRow.Value, pValueAttribute.ReservationStatus, pValueAttribute.AnnulationReason);	
			EndIf;
			If pCheckAttribute.GuaranteeTypes And IsBlankString(vError) Then
				vError = GuestGroups_SetGuaranteeType(vObj, pValueAttribute.GuaranteeTypes);	
			EndIf;
			If pCheckAttribute.Date And IsBlankString(vError) Then
				vError = GuestGroups_SetAccommodationPeriod(vObj, vRefListRow.Value, pValueAttribute.Date.CheckInDate, pValueAttribute.Date.CheckOutDate);	
			EndIf;
			If pCheckAttribute.BedsSetup And IsBlankString(vError) Then
				vError = GuestGroups_SetBedsSetup(vObj, pValueAttribute.BedsSetup);
			EndIf;

			If IsBlankString(vError) Then
				For Each vCustomFields In pCustomFieldsList Do
					If pCheckAttribute["Check" + TrimAll(vCustomFields.Value.Code)] Then
						GuestGroups_SetCustom(vObj.Ref, vCustomFields.Value, pValueAttribute[TrimAll(vCustomFields.Value.Code)]);	
					EndIf;
				EndDo;

				vCheckExtraList = Undefined;
				vNameExtra = New ValueList();
				If pCheckAttribute.Extra Then
					For Each vExtra In pValueAttribute.Extra Do 
						vError = GuestGroups_SetExtra(vObj, vExtra);
						vNameExtra.Add(vExtra.Name);
						If Not IsBlankString(vError) Then
							Break;
						EndIf;
					EndDo;
					vCheckExtraList = ExtraList();	
				EndIf;
			EndIf;

			If pCheckAttribute.FixedCharges And IsBlankString(vError) Then
				vError = GuestGroups_SetFixedCharges(vObj, pValueAttribute.FixedCharges);
			EndIf;
			If pCheckAttribute.ChargingRules And IsBlankString(vError) Then
				vError = GuestGroups_SetChargingRules(vObj, pValueAttribute.ChargingRules);
			EndIf;
			
			If IsBlankString(vError) Then
				vCheckPosting = CheckPosting(pCheckAttribute, vNameExtra, vCheckExtraList);
				vCheckCalculateServices = CheckCalculateServices(pCheckAttribute, vNameExtra, vCheckExtraList);
				vCheckSetDiscounts = CheckSetDiscounts(pCheckAttribute, vNameExtra, vCheckExtraList);
				
				If vCheckSetDiscounts Then
					vObj.pmSetDiscounts();
				EndIf;
				
				If vCheckCalculateServices Then
					vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit);
				EndIf;
				
				If Not vCheckPosting Then  
					vObj.Write(DocumentWriteMode.Write);
				Else
					vObj.Write(DocumentWriteMode.Posting);
				EndIf;
				
				If TypeOf(vObj) = Type("DocumentObject.Accommodation") Then
					vObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				ElsIf TypeOf(vObj) = Type("DocumentObject.Reservation") Then
					vObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
				
				vProgress = vProgress + vStep;
				tcCommonFunctionOnClientServer.UserMessage("<progress>" + vProgress + "</progress>");
			Else
				tcCommonFunctionOnClientServer.UserMessage(vError);
			EndIf;
		EndDo;
			
		If IsBlankString(vError) Then
			If ValueIsFilled(vGuestGroup) And vGuestGroup.TouristicTaxIsCalculatedForMainGroupDocumentOnly And 
			   ValueIsFilled(vGuestGroup.ClientDoc) And vGuestGroup.ClientDoc.Posted And 
			  (TypeOf(vGuestGroup.ClientDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vGuestGroup.ClientDoc) = Type("DocumentRef.Reservation")) Then
				vObj = vGuestGroup.ClientDoc.GetObject();
				vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit);
				vObj.Write(DocumentWriteMode.Posting);
				If TypeOf(vObj) = Type("DocumentObject.Accommodation") Then
					vObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				ElsIf TypeOf(vObj) = Type("DocumentObject.Reservation") Then
					vObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // GuestGroups_SetAllAttributes

Function ExtraList()
	vListArray = New Array();
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","ContactPerson",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","Phone",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","Fax",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","EMail",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","GuestGroup",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","HotelProduct",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","GuaranteeType",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","Rating",True,False,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","WaitTillDate",True,False,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","RoomQuota",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","RoomType",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","ClientTypeConfirmationText",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","MarketingCodeConfirmationText",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","DiscountCard",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","DiscountConfirmationText",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","Discount",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","DiscountSum",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","DiscountServiceGroup",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","TurnOffAutomaticDiscounts",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","PlannedPaymentMethod",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","CreditCard",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","Company",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","Car",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","Remarks",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","HousekeepingRemarks",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","ConfirmationReply",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","IsClosedForEdit",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","ExchangeRateDate",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","IsMaster",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","FeeTerms",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","RoomTypeUpgrade",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","PriceChangeReason",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","DoNotPrintRate",False,True,False,False));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","PriceCalculationDate",True,False,True,True));
	vListArray.Add(New Structure("Name, Posting, Write, CalculateServices, SetDiscounts","DoChargingToDate",True,False,False,False));
	Return vListArray;
EndFunction // ExtraList

Function CheckPosting(pCheckAttribute, pNameExtra, pCheckExtraList)
	vCheckResult = False;
	If pCheckAttribute.RoomPrice Then
		Return True;		
	EndIf;
	If pCheckAttribute.GuestPrice Then
		Return True;		
	EndIf;
	If pCheckAttribute.RoomRate Then
		Return True;	
	EndIf;
	If pCheckAttribute.ServicePackage Then
		Return True;		
	EndIf;
	If pCheckAttribute.ServicePackages Then
		Return True;		
	EndIf;
	If pCheckAttribute.DiscountType Then
		Return True;		
	EndIf;
	If pCheckAttribute.MarketingCode Then
		Return True;		
	EndIf;
	If pCheckAttribute.SourceOfBusiness Then
		Return True;		
	EndIf;
	If pCheckAttribute.TripPurpose Then
		Return False;		
	EndIf;
	If pCheckAttribute.Guest Then
		Return True;	
	EndIf;
	If pCheckAttribute.ClientType Then
		Return True;			
	EndIf;
	If pCheckAttribute.AgentCommission Then
		Return True;		
	EndIf;
	If pCheckAttribute.ReservationStatus Then
		Return True;	
	EndIf;
	If pCheckAttribute.GuaranteeTypes Then
		Return True;		
	EndIf;
	If pCheckAttribute.Date Then
		Return True;		
	EndIf;
	If pCheckAttribute.FixedCharges Then
		Return True;		
	EndIf;
	If pCheckAttribute.ChargingRules Then
		Return True;		
	EndIf;
	If pCheckAttribute.BoardPlace Then
		Return True;		
	EndIf;
	If pCheckAttribute.Extra Then
		For Each vCheckExtra In pCheckExtraList Do
			vCheckE = pNameExtra.FindByValue(vCheckExtra.Name);
			If vCheckE <> Undefined And vCheckExtra.Posting Then
				vCheckResult = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	Return vCheckResult;
EndFunction // CheckPosting

Function CheckCalculateServices(pCheckAttribute, pNameExtra, pCheckExtraList)
	vCheckResult = False;
	If pCheckAttribute.RoomPrice Then
		Return True;		
	EndIf;
	If pCheckAttribute.GuestPrice Then
		Return True;		
	EndIf;
	If pCheckAttribute.RoomRate Then
		Return True;	
	EndIf;
	If pCheckAttribute.ServicePackage Then
		Return True;		
	EndIf;
	If pCheckAttribute.ServicePackages Then
		Return True;		
	EndIf;
	If pCheckAttribute.DiscountType Then
		Return True;		
	EndIf;
	If pCheckAttribute.MarketingCode Then
		Return True;		
	EndIf;
	If pCheckAttribute.SourceOfBusiness Then
		Return True;		
	EndIf;
	If pCheckAttribute.TripPurpose Then
		Return False;		
	EndIf;
	If pCheckAttribute.Guest Then
		Return True;	
	EndIf;
	If pCheckAttribute.ClientType Then
		Return True;			
	EndIf;
	If pCheckAttribute.AgentCommission Then
		Return True;		
	EndIf;
	If pCheckAttribute.ReservationStatus Then
		Return True;	
	EndIf;
	If pCheckAttribute.GuaranteeTypes Then
		Return True;		
	EndIf;
	If pCheckAttribute.Date Then
		Return True;		
	EndIf;
	If pCheckAttribute.FixedCharges Then
		Return True;		
	EndIf;
	If pCheckAttribute.ChargingRules Then
		Return True;		
	EndIf;
	If pCheckAttribute.BoardPlace Then
		Return True;		
	EndIf;
	If pCheckAttribute.Extra Then
		For Each vCheckExtra In pCheckExtraList Do
			vCheckE = pNameExtra.FindByValue(vCheckExtra.Name);
			If vCheckE <> Undefined And vCheckExtra.CalculateServices Then
				vCheckResult = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	Return vCheckResult;
EndFunction // CheckCalculateServices

Function CheckSetDiscounts(pCheckAttribute, pNameExtra, pCheckExtraList)
	vCheckResult = False;
	If pCheckAttribute.RoomPrice Then
		Return True;		
	EndIf;
	If pCheckAttribute.GuestPrice Then
		Return True;		
	EndIf;
	If pCheckAttribute.RoomRate Then
		Return True;	
	EndIf;
	If pCheckAttribute.ServicePackage Then
		Return False;		
	EndIf;
	If pCheckAttribute.ServicePackages Then
		Return False;		
	EndIf;
	If pCheckAttribute.DiscountType Then
		Return True;		
	EndIf;
	If pCheckAttribute.MarketingCode Then
		Return True;		
	EndIf;
	If pCheckAttribute.SourceOfBusiness Then
		Return False;		
	EndIf;
	If pCheckAttribute.TripPurpose Then
		Return False;		
	EndIf;
	If pCheckAttribute.Guest Then
		Return True;	
	EndIf;
	If pCheckAttribute.ClientType Then
		Return True;			
	EndIf;
	If pCheckAttribute.AgentCommission Then
		Return True;		
	EndIf;
	If pCheckAttribute.ReservationStatus Then
		Return True;	
	EndIf;
	If pCheckAttribute.GuaranteeTypes Then
		Return True;		
	EndIf;
	If pCheckAttribute.Date Then
		Return True;		
	EndIf;
	If pCheckAttribute.BoardPlace Then
		Return False;		
	EndIf;
	If pCheckAttribute.Extra Then
		For Each vCheckExtra In pCheckExtraList Do
			vCheckE = pNameExtra.FindByValue(vCheckExtra.Name);
			If vCheckE <> Undefined And vCheckExtra.SetDiscounts Then
				vCheckResult = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	Return vCheckResult;
EndFunction // CheckSetDiscounts

Procedure GuestGroups_GetGroupTotals(pGuestGroup, pTempStorageAddress) Export
	vGroupDataStruct = New Structure("GuestGroup,
									 |TotalGuestsByGroup,
									 |TotalGuestsReservedByGroup, 
									 |TotalGuestsCheckInByGroup, 
	                                 |TotalRoomsByGroup, 
	                                 |TotalRoomReservedByGroup, 
									 |TotalRoomCheckInByGroup, 
									 |TotalGroupSales, 
									 |TotalGroupPayments, 
									 |TotalGroupBalance, 
									 |TGroupResources", 
	                                 pGuestGroup, 0, 0, 0, 0, 0, 0, "", "", "", "");
		
	vGuestGroupObj = pGuestGroup.GetObject();
	
	// Group is preliminary status
	vIsPreliminary = vGuestGroupObj.pmIsPreliminary();
	
	vHotel = vGuestGroupObj.Owner;
	
	vTotals = vGuestGroupObj.pmGetRoomInventoryTotals();
	If vTotals.Count() > 0 Then
		vTotalsRow = vTotals[0];
		vGroupDataStruct.TotalGuestsReservedByGroup = vTotalsRow.GuestsExpected;
		vGroupDataStruct.TotalRoomReservedByGroup = vTotalsRow.RoomsExpected;
		vGroupDataStruct.TotalGuestsCheckInByGroup = vTotalsRow.GuestsCheckedIn;
		vGroupDataStruct.TotalRoomCheckInByGroup = vTotalsRow.RoomsCheckedIn;
		vGroupDataStruct.TotalGuestsByGroup = vTotalsRow.GuestsExpected + vTotalsRow.GuestsCheckedIn;
		vGroupDataStruct.TotalRoomsByGroup = vTotalsRow.RoomsExpected + vTotalsRow.RoomsCheckedIn;
	EndIf;
	
	// Sales
	vGuestGroupBalance = 0;
	vGuestGroupSales = 0;
	vSalesInBaseCurrency = 0;
	vSales = vGuestGroupObj.pmGetSalesTotals();
	vSales.GroupBy("Currency", "Sales, SalesForecast, ExpectedSales");
	For Each vSalesRow In vSales Do
		If Not vIsPreliminary Then
			vGroupDataStruct.TotalGroupSales = vGroupDataStruct.TotalGroupSales + ?(IsBlankString(vGroupDataStruct.TotalGroupSales), "", ", ") + cmFormatSum(vSalesRow.Sales + vSalesRow.SalesForecast, vSalesRow.Currency);
			vSalesInBaseCurrency = cmConvertCurrencies(vSalesRow.Sales + vSalesRow.SalesForecast, vSalesRow.Currency, , vHotel.BaseCurrency, , CurrentSessionDate(), vHotel);
			vGuestGroupBalance = vGuestGroupBalance + vSalesInBaseCurrency;
			vGuestGroupSales = vGuestGroupSales + vSalesInBaseCurrency;
		Else
			vGroupDataStruct.TotalGroupSales = vGroupDataStruct.TotalGroupSales + ?(IsBlankString(vGroupDataStruct.TotalGroupSales), "", ", ") + cmFormatSum(vSalesRow.Sales + vSalesRow.ExpectedSales, vSalesRow.Currency);
			vSalesInBaseCurrency = cmConvertCurrencies(vSalesRow.Sales + vSalesRow.ExpectedSales, vSalesRow.Currency, , vHotel.BaseCurrency, , CurrentSessionDate(), vHotel);
			vGuestGroupBalance = vGuestGroupBalance + vSalesInBaseCurrency;
			vGuestGroupSales = vGuestGroupSales + vSalesInBaseCurrency;
		EndIf;
	EndDo;
	
	// Payments
	vPayments = vGuestGroupObj.pmGetPaymentsTotals();
	vPayments.GroupBy("Currency", "Sum");
	For Each vPaymentsRow In vPayments Do
		vGroupDataStruct.TotalGroupPayments = vGroupDataStruct.TotalGroupPayments + ?(IsBlankString(vGroupDataStruct.TotalGroupPayments), "", ", ") + cmFormatSum(vPaymentsRow.Sum, vPaymentsRow.Currency);
		vGuestGroupBalance = vGuestGroupBalance - cmConvertCurrencies(vPaymentsRow.Sum, vPaymentsRow.Currency, , vHotel.BaseCurrency, , CurrentSessionDate(), vHotel);
	EndDo;
	
	// Balance
	vGroupDataStruct.TotalGroupBalance = cmFormatSum(vGuestGroupBalance, vHotel.BaseCurrency);
	
	// Get group resources
	vGroupDataStruct.TGroupResources = vGuestGroupObj.pmGetResourceCodes();
	
	PutToTempStorage(vGroupDataStruct, pTempStorageAddress);
EndProcedure // GuestGroups_GetGroupTotals

#EndRegion

#Region FrontOffice

Procedure FrontOffice_GetTotalsRooms(pHotel, pRoom, pRoomType, pCustomer, pContract, pAgent, pRoomQuota, pRoomRate, pClient, pGuestGroup, pCheckInDate, pCheckOutDate, pBedsSetup, pTempStorageAddress) Export
	vRooms = New Structure("CheckOutRooms, CheckInRooms, InHouseRooms, CheckOutBeds, CheckInBeds, InHouseBeds, CheckOutGuests, CheckInGuests, InHouseGuests", 0, 0, 0, 0, 0, 0, 0, 0, 0);
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	SUM(NestedSelect.CheckOutRooms) AS CheckOutRooms,
	|	SUM(NestedSelect.CheckOutBeds) AS CheckOutBeds,
	|	SUM(NestedSelect.CheckOutGuests) AS CheckOutGuests,
	|	SUM(NestedSelect.CheckInRooms) AS CheckInRooms,
	|	SUM(NestedSelect.CheckInBeds) AS CheckInBeds,
	|	SUM(NestedSelect.CheckInGuests) AS CheckInGuests,
	|	SUM(NestedSelect.InHouseRooms) AS InHouseRooms,
	|	SUM(NestedSelect.InHouseBeds) AS InHouseBeds,
	|	SUM(NestedSelect.InHouseGuests) AS InHouseGuests
	|FROM
	|	(SELECT
	|		0 AS CheckInRooms,
	|		0 AS CheckInBeds,
	|		0 AS CheckInGuests,
	|		CASE
	|			WHEN SUM(ExpectedCheckOutMovements.ExpectedRoomsCheckedOut) < 0
	|				THEN 0
	|			ELSE SUM(ExpectedCheckOutMovements.ExpectedRoomsCheckedOut)
	|		END AS CheckOutRooms,
	|		CASE
	|			WHEN SUM(ExpectedCheckOutMovements.ExpectedBedsCheckedOut) < 0
	|				THEN 0
	|			ELSE SUM(ExpectedCheckOutMovements.ExpectedBedsCheckedOut)
	|		END AS CheckOutBeds,
	|		CASE
	|			WHEN SUM(ExpectedCheckOutMovements.ExpectedGuestsCheckedOut) < 0
	|				THEN 0
	|			ELSE SUM(ExpectedCheckOutMovements.ExpectedGuestsCheckedOut)
	|		END AS CheckOutGuests,
	|		0 AS InHouseRooms,
	|		0 AS InHouseBeds,
	|		0 AS InHouseGuests
	|	FROM
	|		AccumulationRegister.RoomInventory AS ExpectedCheckOutMovements
	|	WHERE
	|		ExpectedCheckOutMovements.IsAccommodation
	|		AND ExpectedCheckOutMovements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND (NOT &qHotelIsFilled
	|				OR &qHotelIsFilled
	|					AND ExpectedCheckOutMovements.Hotel IN HIERARCHY (&qHotel))
	|		AND (NOT &qRoomIsFilled
	|				OR &qRoomIsFilled
	|					AND ExpectedCheckOutMovements.Room IN HIERARCHY (&qRoom))
	|		AND (NOT &qRoomTypeIsFilled
	|				OR &qRoomTypeIsFilled
	|					AND ExpectedCheckOutMovements.RoomType IN HIERARCHY (&qRoomType))
	|		AND (NOT &qCustomerIsFilled
	|				OR &qCustomerIsFilled
	|					AND ExpectedCheckOutMovements.Customer IN HIERARCHY (&qCustomer))
	|		AND (NOT &qContractIsFilled
	|				OR &qContractIsFilled
	|					AND ExpectedCheckOutMovements.Contract = &qContract)
	|		AND (NOT &qAgentIsFilled
	|				OR &qAgentIsFilled
	|					AND ExpectedCheckOutMovements.Agent IN HIERARCHY (&qAgent))
	|		AND (NOT &qAllotmentIsFilled
	|				OR &qAllotmentIsFilled
	|					AND ExpectedCheckOutMovements.RoomQuota IN HIERARCHY (&qAllotment))
	|		AND (NOT &qRoomRateIsFilled
	|				OR &qRoomRateIsFilled
	|					AND ExpectedCheckOutMovements.RoomRate IN HIERARCHY (&qRoomRate))
	|		AND (NOT &qClientIsFilled
	|				OR &qClientIsFilled
	|					AND ExpectedCheckOutMovements.Guest IN HIERARCHY (&qClient))
	|		AND (NOT &qGuestGroupIsFilled
	|				OR &qGuestGroupIsFilled
	|					AND ExpectedCheckOutMovements.GuestGroup = &qGuestGroup)
	|		AND (NOT &qBedsSetupIsFilled
	|				OR &qBedsSetupIsFilled
	|					AND ExpectedCheckOutMovements.Recorder.BedsSetup = &qBedsSetup)
	|		AND ExpectedCheckOutMovements.Period >= &qCheckOutPeriodFrom
	|		AND ExpectedCheckOutMovements.Period <= &qCheckOutPeriodTo
	|		AND ExpectedCheckOutMovements.Period = ExpectedCheckOutMovements.CheckOutDate
	|		AND ExpectedCheckOutMovements.CheckInDate >= &qInHouseCheckInPeriodFrom
	|		AND ExpectedCheckOutMovements.CheckInDate <= &qInHouseCheckInPeriodTo
	|		AND ExpectedCheckOutMovements.IsInHouse
	|		AND ExpectedCheckOutMovements.IsCheckOut
	|		AND NOT ExpectedCheckOutMovements.RoomType.DoesNotAffectRoomRevenueStatistics
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SUM(ExpectedCheckInMovements.RoomsReserved),
	|		SUM(ExpectedCheckInMovements.BedsReserved),
	|		SUM(ExpectedCheckInMovements.GuestsReserved),
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		AccumulationRegister.RoomInventory AS ExpectedCheckInMovements
	|	WHERE
	|		ExpectedCheckInMovements.IsReservation
	|		AND ExpectedCheckInMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND (NOT &qHotelIsFilled
	|				OR &qHotelIsFilled
	|					AND ExpectedCheckInMovements.Hotel IN HIERARCHY (&qHotel))
	|		AND (NOT &qRoomIsFilled
	|				OR &qRoomIsFilled
	|					AND ExpectedCheckInMovements.Room IN HIERARCHY (&qRoom))
	|		AND (NOT &qRoomTypeIsFilled
	|				OR &qRoomTypeIsFilled
	|					AND ExpectedCheckInMovements.RoomType IN HIERARCHY (&qRoomType))
	|		AND (NOT &qCustomerIsFilled
	|				OR &qCustomerIsFilled
	|					AND ExpectedCheckInMovements.Customer IN HIERARCHY (&qCustomer))
	|		AND (NOT &qContractIsFilled
	|				OR &qContractIsFilled
	|					AND ExpectedCheckInMovements.Contract = &qContract)
	|		AND (NOT &qAgentIsFilled
	|				OR &qAgentIsFilled
	|					AND ExpectedCheckInMovements.Agent IN HIERARCHY (&qAgent))
	|		AND (NOT &qAllotmentIsFilled
	|				OR &qAllotmentIsFilled
	|					AND ExpectedCheckInMovements.RoomQuota IN HIERARCHY (&qAllotment))
	|		AND (NOT &qRoomRateIsFilled
	|				OR &qRoomRateIsFilled
	|					AND ExpectedCheckInMovements.RoomRate IN HIERARCHY (&qRoomRate))
	|		AND (NOT &qClientIsFilled
	|				OR &qClientIsFilled
	|					AND ExpectedCheckInMovements.Guest IN HIERARCHY (&qClient))
	|		AND (NOT &qGuestGroupIsFilled
	|				OR &qGuestGroupIsFilled
	|					AND ExpectedCheckInMovements.GuestGroup = &qGuestGroup)
	|		AND (NOT &qBedsSetupIsFilled
	|				OR &qBedsSetupIsFilled
	|					AND ExpectedCheckInMovements.Recorder.BedsSetup = &qBedsSetup)
	|		AND ExpectedCheckInMovements.Period >= &qExpectedPeriodFrom
	|		AND ExpectedCheckInMovements.Period <= &qExpectedPeriodTo
	|		AND ExpectedCheckInMovements.Period = ExpectedCheckInMovements.CheckInDate
	|		AND ExpectedCheckInMovements.CheckOutDate >= &qInHouseCheckOutPeriodFrom
	|		AND ExpectedCheckInMovements.CheckOutDate <= &qInHouseCheckOutPeriodTo
	|		AND NOT ExpectedCheckInMovements.RoomType.DoesNotAffectRoomRevenueStatistics
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(InHouseGuestsMovements.InHouseRooms),
	|		SUM(InHouseGuestsMovements.InHouseBeds),
	|		SUM(InHouseGuestsMovements.InHouseGuests)
	|	FROM
	|		(SELECT
	|			Accommodations.Room AS Room,
	|			1 AS InHouseRooms,
	|			SUM(Accommodations.NumberOfBeds) AS InHouseBeds,
	|			SUM(Accommodations.NumberOfPersons) AS InHouseGuests
	|		FROM
	|			Document.Accommodation AS Accommodations
	|		WHERE
	|			Accommodations.Posted
	|			AND Accommodations.AccommodationStatus.IsActive
	|			AND Accommodations.AccommodationStatus.IsInHouse
	|			AND (NOT &qHotelIsFilled
	|					OR &qHotelIsFilled
	|						AND Accommodations.Hotel IN HIERARCHY (&qHotel))
	|			AND (NOT &qRoomIsFilled
	|					OR &qRoomIsFilled
	|						AND Accommodations.Room IN HIERARCHY (&qRoom))
	|			AND (NOT &qRoomTypeIsFilled
	|					OR &qRoomTypeIsFilled
	|						AND Accommodations.RoomType IN HIERARCHY (&qRoomType))
	|			AND (NOT &qCustomerIsFilled
	|					OR &qCustomerIsFilled
	|						AND Accommodations.Customer IN HIERARCHY (&qCustomer))
	|			AND (NOT &qContractIsFilled
	|					OR &qContractIsFilled
	|						AND Accommodations.Contract = &qContract)
	|			AND (NOT &qAgentIsFilled
	|					OR &qAgentIsFilled
	|						AND Accommodations.Agent IN HIERARCHY (&qAgent))
	|			AND (NOT &qAllotmentIsFilled
	|					OR &qAllotmentIsFilled
	|						AND Accommodations.RoomQuota IN HIERARCHY (&qAllotment))
	|			AND (NOT &qRoomRateIsFilled
	|					OR &qRoomRateIsFilled
	|						AND Accommodations.RoomRate IN HIERARCHY (&qRoomRate))
	|			AND (NOT &qClientIsFilled
	|					OR &qClientIsFilled
	|						AND Accommodations.Guest IN HIERARCHY (&qClient))
	|			AND (NOT &qGuestGroupIsFilled
	|					OR &qGuestGroupIsFilled
	|						AND Accommodations.GuestGroup = &qGuestGroup)
	|			AND (NOT &qBedsSetupIsFilled
	|					OR &qBedsSetupIsFilled
	|						AND Accommodations.BedsSetup = &qBedsSetup)
	|			AND Accommodations.CheckOutDate >= &qInHouseCheckOutPeriodFrom
	|			AND Accommodations.CheckOutDate <= &qInHouseCheckOutPeriodTo
	|			AND Accommodations.CheckInDate >= &qInHouseCheckInPeriodFrom
	|			AND Accommodations.CheckInDate <= &qInHouseCheckInPeriodTo
	|		
	|		GROUP BY
	|			Accommodations.Room) AS InHouseGuestsMovements) AS NestedSelect";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pHotel));
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRoom));
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsFilled", ValueIsFilled(pRoomType));
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qCustomerIsFilled", ValueIsFilled(pCustomer));
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qContractIsFilled", ValueIsFilled(pContract));
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qRoomRateIsFilled", ValueIsFilled(pRoomRate));
	vQry.SetParameter("qAgent", pAgent);
	vQry.SetParameter("qAgentIsFilled", ValueIsFilled(pAgent));
	vQry.SetParameter("qAllotment", pRoomQuota);
	vQry.SetParameter("qAllotmentIsFilled", ValueIsFilled(pRoomQuota));
	vQry.SetParameter("qClient", pClient);
	vQry.SetParameter("qClientIsFilled", ValueIsFilled(pClient));
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qGuestGroupIsFilled", ValueIsFilled(pGuestGroup));
	vQry.SetParameter("qBedsSetup", pBedsSetup);
	vQry.SetParameter("qBedsSetupIsFilled", ValueIsFilled(pBedsSetup));
	If ValueIsFilled(pCheckOutDate) Then
		vQry.SetParameter("qCheckOutPeriodFrom", BegOfDay(pCheckOutDate));
		vQry.SetParameter("qCheckOutPeriodTo", EndOfDay(pCheckOutDate));
		vQry.SetParameter("qInHouseCheckOutPeriodFrom", BegOfDay(pCheckOutDate));
		vQry.SetParameter("qInHouseCheckOutPeriodTo", EndOfDay(pCheckOutDate));
	Else
		vQry.SetParameter("qCheckOutPeriodFrom", '00010101');
		vQry.SetParameter("qCheckOutPeriodTo", EndOfDay(CurrentSessionDate()));
		vQry.SetParameter("qInHouseCheckOutPeriodFrom", '00010101');
		vQry.SetParameter("qInHouseCheckOutPeriodTo", '39991231235959');
	EndIf;
	If ValueIsFilled(pCheckInDate) Then
		vQry.SetParameter("qExpectedPeriodFrom", BegOfDay(pCheckInDate));
		vQry.SetParameter("qExpectedPeriodTo", EndOfDay(pCheckInDate));
		vQry.SetParameter("qInHouseCheckInPeriodFrom", BegOfDay(pCheckInDate));
		vQry.SetParameter("qInHouseCheckInPeriodTo", EndOfDay(pCheckInDate));
	Else
		vQry.SetParameter("qExpectedPeriodFrom", '00010101');
		vQry.SetParameter("qExpectedPeriodTo", EndOfDay(CurrentSessionDate()));
		vQry.SetParameter("qInHouseCheckInPeriodFrom", '00010101');
		vQry.SetParameter("qInHouseCheckInPeriodTo", '39991231235959');
	EndIf;
	vResults = vQry.Execute().Unload();
	For Each vResultsRow In vResults Do
		vRooms.CheckInRooms = vResultsRow.CheckInRooms;
		vRooms.CheckOutRooms = vResultsRow.CheckOutRooms;
		vRooms.InHouseRooms = vResultsRow.InHouseRooms;
		vRooms.CheckInBeds = vResultsRow.CheckInBeds;
		vRooms.CheckOutBeds = vResultsRow.CheckOutBeds;
		vRooms.InHouseBeds = vResultsRow.InHouseBeds;
		vRooms.CheckInGuests = vResultsRow.CheckInGuests;
		vRooms.CheckOutGuests = vResultsRow.CheckOutGuests;
		vRooms.InHouseGuests = vResultsRow.InHouseGuests;
		Break;
	EndDo;
	PutToTempStorage(vRooms, pTempStorageAddress);
EndProcedure // FrontOffice_GetTotalsRooms

#EndRegion

#Region Roscongress

Procedure Roscongress_LoadReservations(pReservationsStructure, pIsDebug = False) Export
	vInteractionParameters 	= Roscongress_GetInteractionParametersRefByID("Roscongress");						
	If ValueIsFilled(vInteractionParameters) Then
		For Each vReservationRow In pReservationsStructure.Reservations Do
			If Not vReservationRow.IsActive Then
            	BeginTransaction(DataLockControlMode.Managed);
				Try
					vSuccess					= True;
					vErrors 					= New Array;
					
					vQuery = New Query;
					vQuery.Text = 
					"SELECT
					|	GuestGroups.Ref,
					|	GuestGroups.Owner AS Hotel
					|FROM
					|	Catalog.GuestGroups AS GuestGroups
					|WHERE
					|	GuestGroups.ExternalCode = &qExternalCode
					|	AND NOT GuestGroups.DeletionMark
					|	AND NOT GuestGroups.IsFolder
					|
					|ORDER BY
					|	GuestGroups.Code";
					
					vQuery.SetParameter("qExternalCode", vReservationRow.ReservationNumber);
					
					vQueryResult = vQuery.Execute().Unload();
					
					For Each vRow in vQueryResult Do 
						vResult = cmCancelGroupReservation(vReservationRow.ReservationNumber,TrimR(vRow.Hotel.Code),vInteractionParameters.InteractionID);
						If ValueIsFilled(vResult) Then
							vError = New Structure("ReservationRoomId, ErrorDescription, RoomType");
							vError.ErrorDescription 	= "Failed to find room by code.";
							vErrors.Add(vError);
							vSuccess		= True;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
						EndIf;
					EndDo;
					
					vCommited = True;
					CommitTransaction();
				Except
					RollbackTransaction();
					vCommited = False;
					WriteLogEvent(vInteractionParameters.InteractionID + "_Roscongress_LoadReservations", EventLogLevel.Error,,CurrentSessionDate(), "Не удалось аннулировать заказ: " + ErrorDescription());
				EndTry;
				
				If vCommited Then
					SendQueryInRoscongress(vInteractionParameters, vReservationRow.ReservationNumber, Undefined, "Roscongress_request_CancelReservations", vLogEventType, vSuccess, vErrors);	
				EndIf;
			EndIf;			
		EndDo;
				
		For Each vReservationRow In pReservationsStructure.Reservations Do			
			If vReservationRow.IsActive Then 
				vResStatus = "Book";
				If vReservationRow.IsPayed Then 
					vResStatus = "Payed";
				EndIf;	
					
				For Each vRoomRow In vReservationRow.Rooms Do
					If vRoomRow.Annulated And Not vRoomRow.ConfirmFromHotel Then
						Roscongress_CanceledReservationsByGuests(vRoomRow.Guests, vReservationRow.ReservationNumber, vRoomRow.ID, vInteractionParameters, Not pIsDebug);		
					EndIf;
				EndDo;
				
				vLoadReservations = New Array;
				For Each vRoomRow In vReservationRow.Rooms Do			
					If Not vRoomRow.ConfirmFromHotel And Not vRoomRow.Annulated Then 
						If vRoomRow.CheckInTime <> Undefined Then
							vCheckInTime = vRoomRow.CheckInTime;
						ElsIf vRoomRow.IsEarlyCheckIn = True Then
							vCheckInTime = "0600";
						Else
							vCheckInTime = "1200";	
						EndIf;
						
						If vRoomRow.CheckOutTime <> Undefined Then
							vCheckOutTime = vRoomRow.CheckOutTime;
						ElsIf vRoomRow.IsLateCheckOut = True Then
							vCheckOutTime = "2200";
						Else
							vCheckOutTime = "1200";	
						EndIf;
						
						vPeriodFrom = Date(StrReplace(vRoomRow.CheckInDate,"-","") + vCheckInTime + "00");
						vPeriodTo 	= Date(StrReplace(vRoomRow.CheckOutDate,"-","") + vCheckOutTime + "00");
						
						vHotel		= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), vInteractionParameters.InteractionID, "Hotels", vRoomRow.RoomType);
						vRoomData	= GetRoomByCode(vHotel, Format(vRoomRow.RoomNumber,"NG="));
						vRoom		= vRoomData.Room;
						vRoomType	= vRoomData.RoomType;
						
						Try								
							If ValueIsFilled(vRoom) Then
								If CheckReservations(vInteractionParameters, vReservationRow.ReservationNumber + "/" + Format(vRoomRow.ID, "NG=") + "/%", vPeriodFrom, vPeriodTo, vRoom) Then
									If Roscongress_CanceledReservationsByGuests(vRoomRow.Guests, vReservationRow.ReservationNumber, vRoomRow.ID, vInteractionParameters, False) Then
										vLoadReservations.Add(vRoomRow);
										Continue;
									EndIf;
								EndIf; 
							EndIf;
						Except
							WriteLogEvent(vInteractionParameters.InteractionID + "_Roscongress_LoadReservations", EventLogLevel.Error,,CurrentSessionDate(), "Не удалось загрузить бронь: " + ErrorDescription());
						EndTry;

						Roscongress_LoadReservationsByRooms(vInteractionParameters, vReservationRow, vRoomRow, vResStatus, vHotel, vPeriodFrom, vPeriodTo, vRoom, vRoomType, Not pIsDebug);    		
					EndIf;
				EndDo;
				
				For Each vRoomRow In vLoadReservations Do 
					If vRoomRow.CheckInTime <> Undefined Then
						vCheckInTime = vRoomRow.CheckInTime;
					ElsIf vRoomRow.IsEarlyCheckIn = True Then
						vCheckInTime = "0600";
					Else
						vCheckInTime = "1200";	
					EndIf;
					
					If vRoomRow.CheckOutTime <> Undefined Then
						vCheckOutTime = vRoomRow.CheckOutTime;
					ElsIf vRoomRow.IsLateCheckOut = True Then
						vCheckOutTime = "2200";
					Else
						vCheckOutTime = "1200";	
					EndIf;
					
					vPeriodFrom = Date(StrReplace(vRoomRow.CheckInDate,"-","") + vCheckInTime + "00");
					vPeriodTo 	= Date(StrReplace(vRoomRow.CheckOutDate,"-","") + vCheckOutTime + "00");
					
					vHotel		= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), vInteractionParameters.InteractionID, "Hotels", vRoomRow.RoomType);
					vRoomData	= GetRoomByCode(vHotel, Format(vRoomRow.RoomNumber,"NG="));
					vRoom		= vRoomData.Room;
					vRoomType	= vRoomData.RoomType;
										
					Roscongress_LoadReservationsByRooms(vInteractionParameters, vReservationRow, vRoomRow, vResStatus, vHotel, vPeriodFrom, vPeriodTo, vRoom, vRoomType, Not pIsDebug); 	
				EndDo;	
			EndIf;		
		EndDo;
	EndIf;
EndProcedure // Roscongress_LoadReservations

Procedure Roscongress_SendAllotment() Export
	vExternalSystemCode 	= "Roscongress";
	
	vInteractionParameters 	= Roscongress_GetInteractionParametersRefByID(vExternalSystemCode);

	If ValueIsFilled(vInteractionParameters.LogFolder) Then
		vLogFilePath = vInteractionParameters.LogFolder + "\Roscongress_SendAllotment.txt";
	Else
		vLogFilePath = Undefined;	
	EndIf;
		
	If ValueIsFilled(vInteractionParameters.ActiveFromDate) and ValueIsFilled(vInteractionParameters.ActiveToDate) Then
		vRoomTable 		= Roscongress_GetAllRoomBalances(vInteractionParameters);
		vJSONRequest 	= Roscongress_GenerateJSON_Allotment(vRoomTable);
		Try
			If vLogFilePath <> Undefined Then 
				vTXTFile = New TextWriter;
				vTXTFile.Open(vLogFilePath,,,True);
				
				vTXTFile.WriteLine("<Request>");
				vTXTFile.WriteLine("Request DATE: " + String(CurrentSessionDate()));
				vTXTFile.WriteLine(vJSONRequest);
				vTXTFile.WriteLine("</Request>");
				
				vTXTFile.WriteLine("<Response>");
				vTXTFile.WriteLine("</Response>");
				
				vTXTFile.Close();
			EndIf;
		Except
			WriteLogEvent(vInteractionParameters.InteractionID + "_Roscongress_SendAllotment", EventLogLevel.Warning,,CurrentSessionDate(), "Не удалось сделать запись в лог: " + vLogFilePath + " по причине: " + ErrorDescription());
		EndTry;
	EndIf;
EndProcedure

Function CheckReservations(pInteractionParameters, pExternalCode, pPeriodFrom, pPeriodTo, pRoom)
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Reservation.Ref AS Ref,
	|	Reservation.ReservationStatus.IsCheckIn AS IsCheckIn
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.RoomQuota = &qRoomQuota
	|	AND Reservation.Posted
	|	AND (Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsCheckIn)
	|	AND NOT Reservation.ReservationStatus.IsAnnulation
	|	AND Reservation.Room = &qRoom
	|	AND Reservation.CheckInDate < &qPeriodTo
	|	AND Reservation.CheckOutDate > &qPeriodFrom
	|	AND NOT Reservation.ExternalCode LIKE &qExternalCode"; 
	vQuery.SetParameter("qRoomQuota", pInteractionParameters.Allotment);
	vQuery.SetParameter("qExternalCode", pExternalCode);
	vQuery.SetParameter("qPeriodFrom", pPeriodFrom);
	vQuery.SetParameter("qPeriodTo", pPeriodTo);
	vQuery.SetParameter("qRoom", pRoom);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		For Each vRow In vResult Do
			If vRow.IsCheckIn Then 
				Return False;	  
			EndIf;
		EndDo; 
		Return True;	
	EndIf;
	Return False;
EndFunction // CheckReservations

Procedure Roscongress_LoadReservationsByRooms(pInteractionParameters, pReservationRow, pRoomRow, pResStatus, pHotel, pPeriodFrom, pPeriodTo, pRoom, pRoomType, pSend = True)
	vCommited		= False;
	vLogEventType 	= Undefined;
	vSuccess		= True;
	vErrors 		= New Array;
		
	BeginTransaction(DataLockControlMode.Managed);
	Try
		If ValueIsFilled(pInteractionParameters.Allotment) Then											
			If Not ValueIsFilled(pRoom) Then
				vError = New Structure("ReservationRoomId, ErrorDescription, RoomType, RoomNumber");
				vError.ReservationRoomId 	= Format(pRoomRow.ID,"NG=");
				vError.RoomType 			= Format(pRoomRow.RoomType,"NG=");
				vError.RoomNumber 			= Format(pRoomRow.RoomNumber,"NG=");
				vError.ErrorDescription 	= "Failed to find room by code.";
				vErrors.Add(vError);
				vSuccess			= False;
			EndIf;
												
			If vSuccess Then  
				vExternalGroupReservation 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
				
				vAccomondationTypes = Undefined;
				
				vAccomondationTemplate 	= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInteractionParameters.InteractionID, "AccommodationTemplates", pRoomRow.AccommodationType);
				If ValueIsFilled(vAccomondationTemplate) Then
					vAccomondationTypes = vAccomondationTemplate.AccommodationTypes;
				EndIf;
				
				If Not ValueIsFilled(vAccomondationTypes) Then
					vError = New Structure("ReservationRoomId, ErrorDescription, RoomType");
					vError.ReservationRoomId 	= Format(pRoomRow.ID,"NG=");
					vError.RoomType 			= Format(pRoomRow.RoomType,"NG=");
					vError.ErrorDescription 	= "Failed to find accomondation type.";
					vErrors.Add(vError);
					vSuccess			= False;
				ElsIf vAccomondationTypes.Count() < pRoomRow.Guests.Count() Then
					vError = New Structure("ReservationRoomId, ErrorDescription, RoomType");
					vError.ReservationRoomId 	= Format(pRoomRow.ID,"NG=");
					vError.RoomType 			= Format(pRoomRow.RoomType,"NG=");
					vError.ErrorDescription 	= "Not enough accommodation types in accommodation template! Guest count: " + String(pRoomRow.Guests.Count()) + ", Accommodation count: " + String(vAccomondationTypes.Count());
					vErrors.Add(vError);
					vSuccess			= False;	
				EndIf;
														
				If pRoomRow.Guests.Count() = 0 Then
					vError = New Structure("ReservationRoomId, ErrorDescription, RoomType");
					vError.ReservationRoomId 	= Format(pRoomRow.ID,"NG=");
					vError.RoomType 			= Format(pRoomRow.RoomType,"NG=");
					vError.ErrorDescription 	= "Cant create reservation with 0 guests!";
					vErrors.Add(vError);
					vSuccess = False;
				EndIf;
				
				If vSuccess Then
					vGuestsIndex = 1;
					 
					For Each vGuestRow In pRoomRow.Guests Do 
						If Not vSuccess Then
							Break;	
						EndIf;
						vExternalGroupReservationRow 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/","WriteExternalGroupReservationRow"));
						vExternalGroupReservationRow.ReservationCode 	= pReservationRow.ReservationNumber + "/" + Format(pRoomRow.ID,"NG=") + "/" + String(vGuestsIndex);
						vExternalGroupReservationRow.GroupCode 			= pReservationRow.ReservationNumber;
						vExternalGroupReservationRow.Room				= pRoom.Description;
						vExternalGroupReservationRow.ReservationStatus	= pResStatus;
						
						vExternalGroupReservationRow.PeriodFrom			= pPeriodFrom;
						vExternalGroupReservationRow.PeriodTo			= pPeriodTo;
						vExternalGroupReservationRow.RoomType			= pRoomType.Code;
						vExternalGroupReservationRow.AccommodationType	= TrimAll(vAccomondationTypes[vGuestsIndex-1].AccommodationType.Code);
						vExternalGroupReservationRow.NumberOfRooms		= 1;
						vExternalGroupReservationRow.NumberOfPersons	= 1;
						vExternalGroupReservationRow.ExternalSystemCode	= pInteractionParameters.InteractionID;
						vExternalGroupReservationRow.DoPosting			= True;
						vExternalGroupReservationRow.RoomRate			= pInteractionParameters.InteractionID;
						vExternalGroupReservationRow.Customer           = pInteractionParameters.InteractionID;			
						vExternalGroupReservationRow.RoomQuota          = pInteractionParameters.Allotment.Code;
						vExternalGroupReservationRow.Hotel				= pHotel.Code;
						
						If pRoomRow.Property("Comment") And ValueIsFilled(pRoomRow.Comment) Then
							vExternalGroupReservationRow.ReservationRemarks = TrimAll(pRoomRow.Comment);
						EndIf;
						
						vGuest = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
						If vGuestRow.Property("LastName") and vGuestRow.Property("FirstName") and ValueIsFilled(vGuestRow.LastName) and ValueIsFilled(vGuestRow.FirstName) Then   
							vGuest.ClientLastName 	= vGuestRow.LastName;
							vGuest.ClientFirstName 	= vGuestRow.FirstName;
							If vGuestRow.Property("SecondName") Then
								vGuest.ClientSecondName = vGuestRow.SecondName;
							EndIf;
						Else
							cmParseClientFullName(vGuestRow.FullName, vGuest.ClientLastName, vGuest.ClientFirstName, vGuest.ClientSecondName);	
						EndIf;
						
						If vGuestRow.Property("DateOfBirth") and ValueIsFilled(vGuestRow.DateOfBirth) Then
							vGuest.ClientBirthDate = Date(StrReplace(vGuestRow.DateOfBirth,"-","") + "000000"); 	
						EndIf;
						
						vExternalGroupReservationRow.Client	= vGuest;
						
						If Roscongress_CheckReservation(pHotel, vExternalGroupReservationRow, vGuestRow.FullName, vSuccess) Then
							vExternalGroupReservation.WriteExternalGroupReservationRow.Add(vExternalGroupReservationRow);
						ElsIf Not vSuccess Then
							vError = New Structure("ReservationRoomId, ErrorDescription, RoomType, RoomNumber");
							vError.ReservationRoomId 	= Format(pRoomRow.ID,"NG=");
							vError.RoomType 			= Format(pRoomRow.RoomType,"NG=");  
							vError.RoomNumber 			= Format(pRoomRow.RoomNumber,"NG=");
							vError.ErrorDescription 	= "Reservation is check-in";
							vErrors.Add(vError);	
						EndIf;
						vGuestsIndex = vGuestsIndex + 1;
					EndDo;
				EndIf;
			EndIf;
		Else
			vError = New Structure("ReservationRoomId, ErrorDescription, RoomType");
			vError.ReservationRoomId 	= Format(pRoomRow.ID,"NG=");
			vError.RoomType 			= Format(pRoomRow.RoomType,"NG=");
			vError.ErrorDescription 	= "Interaction parameters not filled: Allotment missing.";
			vErrors.Add(vError);
			vSuccess			= False;
		EndIf;
		
		If vSuccess and vExternalGroupReservation.WriteExternalGroupReservationRow.Count() > 0 Then
			vAnswerXDTO = cmWriteExternalGroupReservation(vExternalGroupReservation);
			If ValueIsFilled(vAnswerXDTO.ErrorDescription) Then
				vError = New Structure("ReservationRoomId, ErrorDescription, RoomType");
				vError.ReservationRoomId 	= Format(pRoomRow.ID,"NG=");;
				vError.RoomType 			= Format(pRoomRow.RoomType,"NG=");
				vError.ErrorDescription 	= "Failed to create reservation : " + vAnswerXDTO.ErrorDescription;
				vErrors.Add(vError);
				vSuccess			= False;		
			EndIf;
		EndIf;
		
		vCommited = True;
		CommitTransaction();
	Except   
		RollbackTransaction();
		
		vErrorDescription = ErrorDescription();
		vError = New Structure("ReservationRoomId, ErrorDescription, RoomType");
		vError.ReservationRoomId 	= Format(pRoomRow.ID,"NG=");
		vError.RoomType 			= Format(pRoomRow.RoomType,"NG=");
		vError.ErrorDescription 	= "Failed to fill reservation row: " + vErrorDescription;
		vErrors.Add(vError);
		
		vSuccess = False;		
		vCommited = False;	
		WriteLogEvent(pInteractionParameters.InteractionID + "_Roscongress_LoadReservations", EventLogLevel.Error,,CurrentSessionDate(), "Не удалось создать брони: " + ErrorDescription());
	EndTry;
	
	If vCommited Then
		SendQueryInRoscongress(pInteractionParameters, pReservationRow.ReservationNumber, pRoomRow.ID, "Roscongress_request_LoadReservations", vLogEventType, vSuccess, vErrors);
	EndIf;	
EndProcedure // Roscongress_LoadReservationsByRooms

Function Roscongress_CanceledReservationsByGuests(pGuests, pReservationNumber, pID, pInteractionParameters, pSend = True)
	vSuccess		= True;
	vErrors 		= New Array;
	
	BeginTransaction(DataLockControlMode.Managed);
	Try                   
		vGuestsCount = pGuests.Count();
		For vGuestsIndex = 1 To vGuestsCount Do
			vReservationCode = pReservationNumber + "/" + Format(pID, "NG=") + "/" + String(vGuestsIndex);
			
			vQuery = New Query;
			vQuery.Text = 
			"SELECT TOP 1
			|	Reservation.Ref,
			|	Reservation.Hotel,
			|	Reservation.Hotel.Code
			|FROM
			|	Document.Reservation AS Reservation
			|WHERE
			|	NOT Reservation.DeletionMark
			|	AND Reservation.ExternalCode = &qExternalCode
			|	AND Reservation.Posted";
			
			vQuery.SetParameter("qExternalCode", vReservationCode);
			
			vQueryResult = vQuery.Execute().Unload();
			
			For Each vHotelCodeRow In vQueryResult Do
				vResult = cmCancelGroupReservation(pReservationNumber, TrimR(vHotelCodeRow.HotelCode), pInteractionParameters.InteractionID,,, vReservationCode);
				If ValueIsFilled(vResult) Then
					vError = New Structure("ReservationRoomId, ErrorDescription, RoomType");
					vError.ErrorDescription 	= "Failed to find room by code. Error:" + vResult;
					vErrors.Add(vError);
					vSuccess		= True;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				EndIf;  
			EndDo;
		EndDo;
		
		vCommited = True;
		CommitTransaction();
	Except
		RollbackTransaction();
		vCommited = False;
		WriteLogEvent(pInteractionParameters.InteractionID + "_Roscongress_LoadReservations", EventLogLevel.Error,, CurrentSessionDate(), "Не удалось аннулировать брони: " + ErrorDescription());
	EndTry;
	
	If vCommited And pSend Then
		SendQueryInRoscongress(pInteractionParameters, pReservationNumber, pID, "Roscongress_request_CancelReservations", vLogEventType, vSuccess, vErrors);	
	EndIf;
	Return vCommited;
EndFunction //Roscongress_CanceledReservationsByGuests

Function Roscongress_GetInteractionParametersRefByID(pInterectionID) Export
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	ExternalSystemInteractions.Ref AS Ref
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	ExternalSystemInteractions.InteractionID = &qInteractionID
	|	AND NOT ExternalSystemInteractions.DeletionMark
	|	AND NOT ExternalSystemInteractions.IsFolder";
	vQuery.SetParameter("qInteractionID", pInterectionID);
	vQueryResult = vQuery.Execute().Unload();
	For each vQueryResultRow in vQueryResult Do
		Return vQueryResultRow.Ref; 
	EndDo;
	Return Undefined;
EndFunction

Procedure SendQueryInRoscongress(pInteractionParameters, pReservationNumber, pID, pName, pLogEventType, pSuccess, pErrors)
	vJSONRequest	= Roscongress_GenerateJSON_Reservations(Format(pReservationNumber, "NG="), ?(pID <> Undefined, Format(pID, "NG="), pID), pSuccess, pErrors);
	vJSONResponse	= Roscongress_SendQuery(vJSONRequest, pInteractionParameters);
	Try	
		If pLogEventType = Undefined Then
			If pSuccess Then
				pLogEventType	= Enums.ExternalSystemEventTypes.Success;
			Else
				pLogEventType	= Enums.ExternalSystemEventTypes.Error;	
			EndIf;
		EndIf;		
		If pInteractionParameters.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, pName, pLogEventType, vJSONRequest, vJSONResponse, Catalogs.DataConvertationRules.MapToJSON(pErrors));
		EndIf;
	Except
		WriteLogEvent(pInteractionParameters.InteractionID + "_Roscongress_LoadReservations", EventLogLevel.Warning,,CurrentSessionDate(), "Не удалось сделать запись в лог по причине: " + ErrorDescription());
	EndTry;	
EndProcedure // SendQueryInRoscongress

Function Roscongress_GenerateJSON_Reservations(pReservationNumber, pRoomID, pReservationSuccess, pReservationErrors)
	
	vJSONResponse 	= New JSONWriter;
	vJSONResponse.ValidateStructure = False;
	vJSONResponse.SetString();
	
	vJSONResponse.WriteStartObject();
	
	vJSONResponse.WritePropertyName("ReservationNumber");
	vJSONResponse.WriteValue(pReservationNumber);
	
	vJSONResponse.WritePropertyName("RoomId");
		vJSONResponse.WriteValue(pRoomID);
	
	vJSONResponse.WritePropertyName("Success");
	vJSONResponse.WriteValue(pReservationSuccess);
	
	vJSONResponse.WritePropertyName("Errors");
	vJSONResponse.WriteStartArray();
	For each vErrorRow in pReservationErrors Do 
		If vErrorRow.Property("RoomNumber") Then
			vJSONResponse.WriteValue("RoomType: " + String(vErrorRow.RoomType) + "; RoomNumber" + vErrorRow.RoomNumber + ";" + vErrorRow.ErrorDescription);
		Else
			vJSONResponse.WriteValue("RoomType: " + String(vErrorRow.RoomType) + "; " + vErrorRow.ErrorDescription);
		EndIf;
	EndDo;
	vJSONResponse.WriteEndArray();
	
	vJSONResponse.WriteEndObject();
	
	Return vJSONResponse.Close();
	
EndFunction

Function Roscongress_SendQuery(pJSON, pInteractionParameters)
	Try
		// HTTP
		vHTTPHeader = New Map;
		vHTTPHeader.Insert("Content-Type", "application/json;charset=utf-8");
		vHTTPHeader.Insert("POST", "http://booking.roscongress.org/api/HotelReservationSendResponse");
		vHTTPHeader.Insert("Host", pInteractionParameters.WSHost);
		
		// HTTP SSL
		vSSL = Undefined;
		If pInteractionParameters.HttpUseSsl Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);
			vHTTPHeader.Insert("POST", "https://booking.roscongress.org/api/HotelReservationSendResponse");
		EndIf;
		
		// HTTP connection
		vHTTPConnection = New HTTPConnection(pInteractionParameters.WSHost,,,,, 15, vSSL);
		
		// Send query
		vHTTPRequest = New HTTPRequest("api/HotelReservationSendResponse", vHTTPHeader);
		vHTTPRequest.SetBodyFromString(pJSON);
		rs = vHTTPConnection.Post(vHTTPRequest);
		vHTTPConnection = Undefined;
		Return rs.GetBodyAsString();
	Except
		vError = ErrorDescription();
		WriteLogEvent("Roscongress_SendQuery", EventLogLevel.Warning,,CurrentSessionDate(), "Не удалось отправить POST запрос в Россконгресс! " + vError);
		Return vError;
	EndTry;
	
	Return Undefined;	
EndFunction

Function Roscongress_GetBalances(pHotel, pAllotment, pPeriodFrom, pPeriodTo, pExtSystemCode = Undefined, pRoomType, pObjectExternalCode)
	TRooms = New ValueTable;
	TRooms.Columns.Add("RoomType");
	TRooms.Columns.Add("Allotment");
	TRooms.Columns.Add("PeriodFrom");
	TRooms.Columns.Add("PeriodTo");
	TRooms.Columns.Add("VacantRooms");
	TRooms.Columns.Add("VacantBeds");
	TRooms.Columns.Add("StopSale");
	TRooms.Columns.Add("Hotel");
	TRooms.Columns.Add("RoomTypeExtCode");
	TRooms.Columns.Add("SortCode");
	
	// Call API to get value table with balances
	vBalances = cmGetRoomQuotaBalances(pHotel,pRoomType , , , , pAllotment, pPeriodFrom, pPeriodTo);
	
	// Check for stop internet sales
	For Each vRow In vBalances Do
		r = TRooms.Add();
		r.Hotel				= pHotel;
		r.RoomTypeExtCode	= pObjectExternalCode;
		r.RoomType 			= vRow.RoomType;
		r.SortCode 			= vRow.RoomType.SortCode;
		If vRow.Period = Null Then
			r.PeriodFrom = BegOfDay(pPeriodFrom);
			r.PeriodTo = BegOfDay(pPeriodTo);
			r.VacantRooms = 0;
			r.VacantBeds = 0;
		Else
			r.PeriodFrom = BegOfDay(vRow.Period);
			r.PeriodTo = r.PeriodFrom;
			If ValueIsFilled(pAllotment) Then
				r.VacantRooms = ?(vRow.RoomsRemains=Null,0,?(vRow.RoomsRemains>0,vRow.RoomsRemains,0));
				r.VacantBeds = ?(vRow.BedsRemains=Null,0,?(vRow.BedsRemains>0,vRow.BedsRemains,0));
			Else
				r.VacantRooms = ?(vRow.RoomsVacant=Null,0,?(vRow.RoomsVacant>0,vRow.RoomsVacant,0));
				r.VacantBeds = ?(vRow.BedsVacant=Null,0,?(vRow.BedsVacant>0,vRow.BedsVacant,0));
			EndIf;
		EndIf;
	EndDo;
	TRooms.Sort("RoomType, Allotment, PeriodFrom, PeriodTo");	
	
	// Remove room types without mappings
	vRoomTypesWithoutMappings = New ValueList();
	If pExtSystemCode <> Undefined Then
		i = 0;
		While i < TRooms.Count() Do
			row = TRooms.Get(i);
			If vRoomTypesWithoutMappings.FindByValue(row.RoomType) <> Undefined Then
				TRooms.Delete(i);
			ElsIf Not cmCheckExternalSystemCodeMapping(pHotel, pExtSystemCode, row.RoomType, "RoomTypes") Then
				vRoomTypesWithoutMappings.Add(row.RoomType);
				TRooms.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	
	// Check for stop internet sales
	For Each row In TRooms Do
		vRemarks = "";
		row.StopSale = cmIsStopInternetSalePeriod(row.RoomType, row.PeriodFrom, EndOfDay(row.PeriodTo), vRemarks);
	EndDo;
	
	Return TRooms;
EndFunction // GetBalances

Function Roscongress_CheckReservation(pHotelRef, pReservationRow, pGuestFullName, rSuccess)
	vReservation = cmGetReservationByExternalCode(pHotelRef, pReservationRow.ReservationCode);
	If vReservation = Documents.Reservation.EmptyRef() Then
		Return True;
	Else   
		If 	vReservation.ReservationStatus 			= cmGetObjectRefByExternalSystemCode(pHotelRef, pReservationRow.ExternalSystemCode, "ReservationStatuses", pReservationRow.ReservationStatus)
			And vReservation.RoomType 				= cmGetObjectRefByExternalSystemCode(pHotelRef, pReservationRow.ExternalSystemCode, "RoomTypes", pReservationRow.RoomType)
			And vReservation.Room	 				= cmGetObjectRefByExternalSystemCode(pHotelRef, pReservationRow.ExternalSystemCode, "Rooms", pReservationRow.Room)
			And vReservation.AccommodationType 		= cmGetObjectRefByExternalSystemCode(pHotelRef, pReservationRow.ExternalSystemCode, "AccommodationTypes", pReservationRow.AccommodationType)
			And vReservation.CheckInDate			= (Date(pReservationRow.PeriodFrom) + 1)
			And vReservation.CheckOutDate			= Date(pReservationRow.PeriodTo) 
			And Upper(vReservation.GuestFullName)	= Upper(pGuestFullName)
			And vReservation.Remarks				= pReservationRow.ReservationRemarks Then
			Return False;
		Else
			If Not vReservation.ReservationStatus.IsCheckIn Then
				Return True;
			Else  
				rSuccess = False;
				Return False;	
			EndIf;
		EndIf;
	EndIf;
EndFunction

Function Roscongress_GetAllRoomBalances(pInteractionParameters)
	
	vResult = New ValueTable;
	vResult.Columns.Add("Date");
	vResult.Columns.Add("Code");
	vResult.Columns.Add("Balance");
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectRef,
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
	|	ExternalSystemsObjectCodesMappings.Hotel
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomTypes""
	|
	|ORDER BY
	|	ObjectExternalCode";
	
	vQuery.SetParameter("qExternalSystemCode", pInteractionParameters.InteractionID);
	
	vQueryResult = vQuery.Execute().Unload();
	
	vRoomTypes = New ValueTable;
	vRoomTypes.Columns.Add("Code");
	vRoomTypes.Columns.Add("Hotel");
	vRoomTypes.Columns.Add("Ref");
	vRoomTypes.Columns.Add("Balance");
	
	For each vRow in vQueryResult Do
		vCode = vRow.ObjectExternalCode;
		vExtraCodeStartPos 	= StrFind(vRow.ObjectExternalCode,"[");
		If  vExtraCodeStartPos > 0 Then
			vCode = Left(vRow.ObjectExternalCode, vExtraCodeStartPos - 2);	
		EndIf;
		vNewRow 			= vRoomTypes.Add();
		vNewRow.Code 		= vCode;
		vNewRow.Hotel		= vRow.Hotel;
		vNewRow.Ref			= vRow.ObjectRef;
		vNewRow.Balance		= 0;
	EndDo;
	
	For each vRow in vRoomTypes Do
		vBalances = Roscongress_GetBalances(vRow.Hotel, pInteractionParameters.Allotment, pInteractionParameters.ActiveFromDate, pInteractionParameters.ActiveToDate, pInteractionParameters.InteractionID, vRow.Ref, vRow.Code);
		For each vBalancesRow in vBalances Do
			vFilter 	= New Structure("Date, Code", vBalancesRow.PeriodFrom, vBalancesRow.RoomTypeExtCode);
			vFoundRows 	= vResult.FindRows(vFilter);
			If vFoundRows.Count() = 1 Then 
				vFoundRows[0].Date 		= vBalancesRow.PeriodFrom;
				vFoundRows[0].Code		= vBalancesRow.RoomTypeExtCode;
				vFoundRows[0].Balance	= vFoundRows[0].Balance + vBalancesRow.VacantRooms;
			Else
				vNewRow 			= vResult.Add();
				vNewRow.Date 		= vBalancesRow.PeriodFrom;
				vNewRow.Code		= vBalancesRow.RoomTypeExtCode;
				vNewRow.Balance		= vBalancesRow.VacantRooms;
			EndIf;
		EndDo;
	EndDo;
	
	vResult.Sort("Date");
	
	Return vResult;
EndFunction

Function Roscongress_GenerateJSON_Allotment(pAllotmentTable)
	
	vJSONResponse 	= New JSONWriter;
	vJSONResponse.ValidateStructure = False;
	vJSONResponse.SetString();
	
	vJSONResponse.WriteStartObject();
	vJSONResponse.WritePropertyName("Allotments");
	vJSONResponse.WriteStartArray();
	vPrevDate = Undefined;
	For each vAllotmentRow in pAllotmentTable Do		
		If vPrevDate <> vAllotmentRow.Date Then
			If vPrevDate <> Undefined Then
				vJSONResponse.WriteEndArray();
				vJSONResponse.WriteEndObject();
			EndIf;
			vJSONResponse.WriteStartObject();
			vJSONResponse.WritePropertyName("AllotmentDate");
			vJSONResponse.WriteValue(Format(vAllotmentRow.Date,"DF=yyyyMMdd"));
			
			vJSONResponse.WritePropertyName("RoomTypes");
			vJSONResponse.WriteStartArray();
			vJSONResponse.WriteStartObject();
			vJSONResponse.WritePropertyName("Code");
			vJSONResponse.WriteValue(vAllotmentRow.Code);
			
			vJSONResponse.WritePropertyName("Rooms");
			vJSONResponse.WriteValue(vAllotmentRow.Balance);
			vJSONResponse.WriteEndObject();
		Else
			vJSONResponse.WriteStartObject();
			vJSONResponse.WritePropertyName("Code");
			vJSONResponse.WriteValue(vAllotmentRow.Code);
			
			vJSONResponse.WritePropertyName("Rooms");
			vJSONResponse.WriteValue(vAllotmentRow.Balance);
			vJSONResponse.WriteEndObject();
		EndIf;
		
		vPrevDate = vAllotmentRow.Date;
	EndDo;
	If vPrevDate <> Undefined Then
		vJSONResponse.WriteEndArray();
		vJSONResponse.WriteEndObject();
	EndIf;
	
	vJSONResponse.WriteEndArray();	
	vJSONResponse.WriteEndObject();
	
	Return vJSONResponse.Close();
	
EndFunction

Function GetRoomByCode(pHotel, pRoomCode)
	
	vResult = New Structure("Room, RoomType", Undefined, Undefined);
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	Rooms.Ref AS Ref,
		|	Rooms.RoomType
		|FROM
		|	Catalog.Rooms AS Rooms
		|WHERE
		|	NOT Rooms.DeletionMark
		|	AND Rooms.Owner = &qHotel
		|	AND Rooms.Description = &qRoomCode";
	
	vQuery.SetParameter("qHotel", 		pHotel);
	vQuery.SetParameter("qRoomCode", 	pRoomCode);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vResult.Room 		= vSelectionDetailRecords.Ref;
		vResult.RoomType 	= vSelectionDetailRecords.RoomType;
	EndDo;
	
	Return vResult;
	
EndFunction  

#EndRegion

#Region Contract

Procedure Contract_RecalculatePricesForActiveReservations(pContract, pCurrentUser) Export
	// Build list of contract active reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Ref AS Ref,
	|	Reservations.SortCode AS SortCode
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Contract = &qContract
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|	AND (Reservations.Hotel = &qHotel
	|			OR &qContractHotelIsEmpty)
	|	AND Reservations.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	Accommodations.Ref,
	|	Accommodations.SortCode
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Contract = &qContract
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND (Accommodations.Hotel = &qHotel
	|			OR &qContractHotelIsEmpty)
	|	AND Accommodations.Posted
	|
	|ORDER BY
	|	SortCode";
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qHotel", pContract.Hotel);
	vQry.SetParameter("qContractHotelIsEmpty", Not ValueIsFilled(pContract.Hotel));
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vProgress = 0;
		vStep = 100 / vDocs.Count();
		For Each vDocsRow In vDocs Do
			vDocObj = vDocsRow.Ref.GetObject();
			If ValueIsFilled(pContract.RoomQuota) And vDocObj.RoomQuota <> pContract.RoomQuota Then
				vDocObj.RoomQuota = pContract.RoomQuota;
			EndIf;
			If ValueIsFilled(pContract.AgentCommissionType) Or pContract.AgentCommission <> 0 Then
				vDocObj.Agent = ?(ValueIsFilled(pContract.Agent), pContract.Agent, pContract.Owner);
				vDocObj.AgentCommissionType = pContract.AgentCommissionType;
				vDocObj.AgentCommission = pContract.AgentCommission;
				vDocObj.AgentCommissionServiceGroup = pContract.AgentCommissionServiceGroup;
			Else
				vDocObj.Agent = Catalogs.Customers.EmptyRef();
				vDocObj.AgentCommissionType = Undefined;
				vDocObj.AgentCommission = 0;
				vDocObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
			EndIf;
			vDocObj.pmSetDiscounts();
			If TypeOf(vDocObj) = Type("DocumentObject.Reservation") Then
				If pContract.PlannedPaymentMethod <> vDocObj.PlannedPaymentMethod Then
					If pContract.ChargingRules.Count() = 0 Then
						Reservation_RemoveCustomerChargingRules(vDocObj);
						Reservation_ChargingRulesAfterDeleteRow(vDocObj);
					Else
						Reservation_AddBankTransferCR(vDocObj);
					EndIf;
				Else
					vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
				EndIf;
			Else
				vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
			EndIf;
			vDocObj.Write(DocumentWriteMode.Posting);
			If TypeOf(vDocObj) = Type("DocumentObject.Reservation") Then
				vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			Else
				vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
			vProgress = vProgress + vStep;
			tcCommonFunctionOnClientServer.UserMessage("<progress>" + vProgress + "</progress>");
		EndDo;
	EndIf;
EndProcedure // Contract_RecalculatePricesForActiveReservations

Procedure Reservation_ChargingRulesAfterDeleteRow(pDocObj)
	// Check that charging rules are not empty
	If pDocObj.ChargingRules.Count() = 0 Then
		// Initialize charging rules by default
		Reservation_LoadDefaultChargingRules(pDocObj);
	Else
		// Check if there is base rule
		vBaseRuleFound = False;
		For Each vCRRow In pDocObj.ChargingRules Do
			If Not ValueIsFilled(vCRRow.Owner) And vCRRow.ChargingRule = Enums.ChargingRuleTypes.Any Then
				vBaseRuleFound = True;
			EndIf;
		EndDo;
		If Not vBaseRuleFound Then
			// Initialize charging rules by default
			Reservation_LoadDefaultChargingRules(pDocObj);
		Else
			// Automatic services list calculation	
			pDocObj.pmCalculateServices( , , , , , pDocObj.IsForFolioSplit);
		EndIf;
	EndIf;
EndProcedure // Reservation_ChargingRulesAfterDeleteRow

Procedure Reservation_LoadDefaultChargingRules(pDocObj)
	If ValueIsFilled(pDocObj.Hotel) Then
		// Load default charging rules
		pDocObj.pmLoadDefaultChargingRules();
		// Automatic services list calculation	
		pDocObj.pmCalculateServices( , , , , , pDocObj.IsForFolioSplit);	
	EndIf;
EndProcedure // Reservation_LoadDefaultChargingRules

Procedure Reservation_RemoveCustomerChargingRules(pDocObj)
	If ValueIsFilled(pDocObj.Hotel) And ValueIsFilled(pDocObj.GuestGroup) Then
		vInt = 0;
		While vInt < pDocObj.ChargingRules.Count() Do
			vCRRow = pDocObj.ChargingRules.Get(vInt);
			If ValueIsFilled(vCRRow.Owner) And 
				(TypeOf(vCRRow.Owner) = Type("CatalogRef.Customers") Or TypeOf(vCRRow.Owner) = Type("CatalogRef.Contracts")) Then
				// Check if hotel base charging rules have row with rule equal to the current one
				vBaseRuleIsFound = False;
				If ValueIsFilled(pDocObj.Hotel) And pDocObj.Hotel.ChargingRules.Count() > 0 And 
					ValueIsFilled(vCRRow.ChargingFolio) And Not vCRRow.ChargingFolio.IsMaster Then
					// Try to find hotel template rule of the same type
					vHotelCRRows = pDocObj.Hotel.ChargingRules.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", vCRRow.ChargingRule, vCRRow.ChargingRuleValue, vCRRow.ValidFromDate, vCRRow.ValidToDate));
					If vHotelCRRows.Count() = 1 Then
						vBaseRuleIsFound = True;
						vHotelCRRow = vHotelCRRows.Get(0);
						// Update charging folio
						vFolioObj = vCRRow.ChargingFolio.GetObject();
						cmFillFolioFromTemplate(vFolioObj, vHotelCRRow.ChargingFolio, pDocObj.Hotel, pDocObj.Date);
						If Not ValueIsFilled(vFolioObj.ParentDoc)  
							Or ValueIsFilled(vFolioObj.ParentDoc) And TypeOf(vFolioObj.ParentDoc) <> Type("DocumentRef.Accommodation") Then
							vFolioObj.ParentDoc = pDocObj.Ref;
						EndIf;
						If Not vFolioObj.DoNotUpdateCompany Then
							vFolioObj.Company = pDocObj.Company;
						EndIf;
						vFolioObj.Client = pDocObj.Guest;
						vFolioObj.GuestGroup = pDocObj.GuestGroup;
						vFolioObj.DateTimeFrom = pDocObj.CheckInDate;
						vFolioObj.DateTimeTo = pDocObj.CheckOutDate;
						vFolioObj.Customer = Catalogs.Customers.EmptyRef();
						vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
						vFolioObj.Write(DocumentWriteMode.Write);
						// Update owner
						vCRRow.Owner = Undefined;
					EndIf;
				EndIf;
				If Not vBaseRuleIsFound Then
					pDocObj.ChargingRules.Delete(vInt);
				Else
					vInt = vInt + 1;
				EndIf;
			Else
				vInt = vInt + 1;
			EndIf;
		EndDo;
		cmUpdateChargingRulesFoliosLineNumbers(pDocObj.ChargingRules);
	EndIf;
EndProcedure // Reservation_RemoveCustomerChargingRules

Procedure Reservation_AddBankTransferCR(pDocObj) Export
	If ValueIsFilled(pDocObj.Hotel) Then
		// Add bank transfer charging rule
		pDocObj.pmAddBankTransferChargingRule();
		// Automatic services list calculation	
		pDocObj.pmCalculateServices( , , , , , pDocObj.IsForFolioSplit);
	EndIf;
EndProcedure // Reservation_AddBankTransferCR

#EndRegion

#Region ReservationsList

Procedure ReservationsList_RecalculateServices(pHotel, pCustomer, pContract, pRoomRate, pService, pWhatToProcess, pRefreshPriceCalculationDate, pRefreshChargingRules, pUser, pDateFrom, pDateTo, pReservationStatus = Undefined, pAuthor = Undefined) Export
	// Process reservations
	vQry = New Query();
	If pWhatToProcess = 0 Then
		If ValueIsFilled(pService) Then
			vQry.Text = 
			"SELECT DISTINCT
			|	ReservationServices.Ref AS Ref
			|FROM
			|	Document.Reservation.Services AS ReservationServices
			|WHERE
			|	ReservationServices.Ref.Hotel = &qHotel
			|	AND ReservationServices.Service = &qService
			|	AND (ReservationServices.Ref.Customer IN HIERARCHY (&qCustomer)
			|			OR &qCustomerIsEmpty)
			|	AND (ReservationServices.Ref.Contract = &qContract
			|			OR &qContractIsEmpty)
			|	AND (ReservationServices.RoomRate IN HIERARCHY (&qRoomRate)
			|			OR &qRoomRateIsEmpty)
			|	AND ReservationServices.Ref.Posted
			|	AND ReservationServices.Ref.CheckInDate < &qDateTo
			|	AND ReservationServices.Ref.CheckOutDate > &qDateFrom
			|	AND CASE
			|			WHEN &qReservationStatusIsEmpty
			|				THEN ReservationServices.Ref.ReservationStatus.IsActive
			|						OR ReservationServices.Ref.ReservationStatus.IsPreliminary
			|			ELSE ReservationServices.Ref.ReservationStatus = &qReservationStatus
			|		END
			|	AND CASE
			|			WHEN &qAuthorNotFilled
			|				THEN TRUE
			|			ELSE ReservationServices.Ref.Author = &qAuthor
			|		END
			|
			|ORDER BY
			|	ReservationServices.Ref.SortCode";
		Else
			vQry.Text = 
			"SELECT DISTINCT
			|	Reservations.Ref AS Ref
			|FROM
			|	Document.Reservation AS Reservations
			|WHERE
			|	Reservations.Hotel = &qHotel
			|	AND (Reservations.Customer IN HIERARCHY (&qCustomer)
			|			OR &qCustomerIsEmpty)
			|	AND (Reservations.Contract = &qContract
			|			OR &qContractIsEmpty)
			|	AND (Reservations.RoomRate IN HIERARCHY (&qRoomRate)
			|			OR &qRoomRateIsEmpty)
			|	AND Reservations.Posted
			|	AND Reservations.CheckInDate < &qDateTo
			|	AND Reservations.CheckOutDate > &qDateFrom
			|	AND CASE
			|			WHEN &qReservationStatusIsEmpty
			|				THEN Reservations.ReservationStatus.IsActive
			|						OR Reservations.ReservationStatus.IsPreliminary
			|			ELSE Reservations.ReservationStatus = &qReservationStatus
			|		END
			|	AND CASE
			|			WHEN &qAuthorNotFilled
			|				THEN TRUE
			|			ELSE Reservations.Author = &qAuthor
			|		END
			|
			|ORDER BY
			|	Reservations.SortCode";
		EndIf;
	ElsIf pWhatToProcess = 1 Then
		If ValueIsFilled(pService) Then
			vQry.Text = 
			"SELECT DISTINCT
			|	Documents.Ref AS Ref,
			|	Documents.SortCode AS SortCode
			|FROM
			|	(SELECT
			|		ReservationServices.Ref AS Ref,
			|		ReservationServices.Ref.SortCode AS SortCode
			|	FROM
			|		Document.Reservation.Services AS ReservationServices
			|	WHERE
			|		ReservationServices.Ref.Hotel = &qHotel
			|		AND ReservationServices.Service = &qService
			|		AND ReservationServices.Ref.CheckInDate < &qDateTo
			|		AND ReservationServices.Ref.CheckOutDate > &qDateFrom
			|		AND (ReservationServices.Ref.Customer IN HIERARCHY (&qCustomer)
			|				OR &qCustomerIsEmpty)
			|		AND (ReservationServices.Ref.Contract = &qContract
			|				OR &qContractIsEmpty)
			|		AND (ReservationServices.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND ReservationServices.Ref.Posted
			|		AND CASE
			|				WHEN &qReservationStatusIsEmpty
			|					THEN ReservationServices.Ref.ReservationStatus.IsActive
			|							OR ReservationServices.Ref.ReservationStatus.IsPreliminary
			|				ELSE ReservationServices.Ref.ReservationStatus = &qReservationStatus
			|			END
			|		AND CASE
			|				WHEN &qAuthorNotFilled
			|					THEN TRUE
			|				ELSE ReservationServices.Ref.Author = &qAuthor
			|			END
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		AccommodationServices.Ref,
			|		AccommodationServices.Ref.SortCode
			|	FROM
			|		Document.Accommodation.Services AS AccommodationServices
			|	WHERE
			|		AccommodationServices.Ref.Hotel = &qHotel
			|		AND AccommodationServices.Service = &qService
			|		AND AccommodationServices.Ref.CheckInDate < &qDateTo
			|		AND AccommodationServices.Ref.CheckOutDate > &qDateFrom
			|		AND (AccommodationServices.Ref.Customer IN HIERARCHY (&qCustomer)
			|				OR &qCustomerIsEmpty)
			|		AND (AccommodationServices.Ref.Contract = &qContract
			|				OR &qContractIsEmpty)
			|		AND (AccommodationServices.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND AccommodationServices.Ref.Posted
			|		AND AccommodationServices.Ref.AccommodationStatus.IsActive
			|		AND AccommodationServices.Ref.AccommodationStatus.IsInHouse
			|		AND CASE
			|				WHEN &qAuthorNotFilled
			|					THEN TRUE
			|				ELSE AccommodationServices.Ref.Author = &qAuthor
			|			END) AS Documents
			|
			|ORDER BY
			|	Documents.SortCode";
		Else
			vQry.Text = 
			"SELECT DISTINCT
			|	Documents.Ref AS Ref,
			|	Documents.SortCode AS SortCode
			|FROM
			|	(SELECT
			|		Reservations.Ref AS Ref,
			|		Reservations.SortCode AS SortCode
			|	FROM
			|		Document.Reservation AS Reservations
			|	WHERE
			|		Reservations.Hotel = &qHotel
			|		AND (Reservations.Customer IN HIERARCHY (&qCustomer)
			|				OR &qCustomerIsEmpty)
			|		AND (Reservations.Contract = &qContract
			|				OR &qContractIsEmpty)
			|		AND (Reservations.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND Reservations.Posted
			|		AND Reservations.CheckInDate < &qDateTo
			|		AND Reservations.CheckOutDate > &qDateFrom
			|		AND CASE
			|				WHEN &qReservationStatusIsEmpty
			|					THEN Reservations.ReservationStatus.IsActive
			|							OR Reservations.ReservationStatus.IsPreliminary
			|				ELSE Reservations.ReservationStatus = &qReservationStatus
			|			END
			|		AND CASE
			|				WHEN &qAuthorNotFilled
			|					THEN TRUE
			|				ELSE Reservations.Author = &qAuthor
			|			END
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		Accommodations.Ref,
			|		Accommodations.SortCode
			|	FROM
			|		Document.Accommodation AS Accommodations
			|	WHERE
			|		Accommodations.Hotel = &qHotel
			|		AND (Accommodations.Customer IN HIERARCHY (&qCustomer)
			|				OR &qCustomerIsEmpty)
			|		AND (Accommodations.Contract = &qContract
			|				OR &qContractIsEmpty)
			|		AND (Accommodations.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND Accommodations.Posted
			|		AND Accommodations.CheckInDate < &qDateTo
			|		AND Accommodations.CheckOutDate > &qDateFrom
			|		AND Accommodations.AccommodationStatus.IsActive
			|		AND Accommodations.AccommodationStatus.IsInHouse
			|		AND CASE
			|				WHEN &qAuthorNotFilled
			|					THEN TRUE
			|				ELSE Accommodations.Author = &qAuthor
			|			END) AS Documents
			|
			|ORDER BY
			|	Documents.SortCode";
		EndIf;
	Else
		If ValueIsFilled(pService) Then
			vQry.Text = 
			"SELECT DISTINCT
			|	Documents.Ref AS Ref,
			|	Documents.SortCode AS SortCode
			|FROM
			|	(SELECT
			|		ReservationServices.Ref AS Ref,
			|		ReservationServices.Ref.SortCode AS SortCode
			|	FROM
			|		Document.Reservation.Services AS ReservationServices
			|	WHERE
			|		ReservationServices.Ref.Hotel = &qHotel
			|		AND ReservationServices.Service = &qService
			|		AND (ReservationServices.Ref.Customer IN HIERARCHY (&qCustomer)
			|				OR &qCustomerIsEmpty)
			|		AND (ReservationServices.Ref.Contract = &qContract
			|				OR &qContractIsEmpty)
			|		AND (ReservationServices.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND ReservationServices.Ref.CheckInDate < &qDateTo
			|		AND ReservationServices.Ref.CheckOutDate > &qDateFrom
			|		AND ReservationServices.Ref.Posted
			|		AND CASE
			|				WHEN &qReservationStatusIsEmpty
			|					THEN ReservationServices.Ref.ReservationStatus.IsActive
			|							OR ReservationServices.Ref.ReservationStatus.IsPreliminary
			|				ELSE ReservationServices.Ref.ReservationStatus = &qReservationStatus
			|			END
			|		AND CASE
			|				WHEN &qAuthorNotFilled
			|					THEN TRUE
			|				ELSE ReservationServices.Ref.Author = &qAuthor
			|			END
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		AccommodationServices.Ref,
			|		AccommodationServices.Ref.SortCode
			|	FROM
			|		Document.Accommodation.Services AS AccommodationServices
			|	WHERE
			|		AccommodationServices.Ref.Hotel = &qHotel
			|		AND AccommodationServices.Service = &qService
			|		AND (AccommodationServices.Ref.Customer IN HIERARCHY (&qCustomer)
			|				OR &qCustomerIsEmpty)
			|		AND (AccommodationServices.Ref.Contract = &qContract
			|				OR &qContractIsEmpty)
			|		AND (AccommodationServices.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND AccommodationServices.Ref.CheckInDate < &qDateTo
			|		AND AccommodationServices.Ref.CheckOutDate > &qDateFrom
			|		AND AccommodationServices.Ref.Posted
			|		AND AccommodationServices.Ref.AccommodationStatus.IsActive
			|		AND CASE
			|				WHEN &qAuthorNotFilled
			|					THEN TRUE
			|				ELSE AccommodationServices.Ref.Author = &qAuthor
			|			END) AS Documents
			|
			|ORDER BY
			|	Documents.SortCode";
		Else
			vQry.Text = 
			"SELECT DISTINCT
			|	Documents.Ref AS Ref,
			|	Documents.SortCode AS SortCode
			|FROM
			|	(SELECT
			|		Reservations.Ref AS Ref,
			|		Reservations.SortCode AS SortCode
			|	FROM
			|		Document.Reservation AS Reservations
			|	WHERE
			|		Reservations.Hotel = &qHotel
			|		AND (Reservations.Customer IN HIERARCHY (&qCustomer)
			|				OR &qCustomerIsEmpty)
			|		AND (Reservations.Contract = &qContract
			|				OR &qContractIsEmpty)
			|		AND (Reservations.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND Reservations.Posted
			|		AND Reservations.CheckInDate < &qDateTo
			|		AND Reservations.CheckOutDate > &qDateFrom
			|		AND CASE
			|				WHEN &qReservationStatusIsEmpty
			|					THEN Reservations.ReservationStatus.IsActive
			|							OR Reservations.ReservationStatus.IsPreliminary
			|				ELSE Reservations.ReservationStatus = &qReservationStatus
			|			END
			|		AND CASE
			|				WHEN &qAuthorNotFilled
			|					THEN TRUE
			|				ELSE Reservations.Author = &qAuthor
			|			END
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		Accommodations.Ref,
			|		Accommodations.SortCode
			|	FROM
			|		Document.Accommodation AS Accommodations
			|	WHERE
			|		Accommodations.Hotel = &qHotel
			|		AND (Accommodations.Customer IN HIERARCHY (&qCustomer)
			|				OR &qCustomerIsEmpty)
			|		AND (Accommodations.Contract = &qContract
			|				OR &qContractIsEmpty)
			|		AND (Accommodations.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND Accommodations.Posted
			|		AND Accommodations.CheckInDate < &qDateTo
			|		AND Accommodations.CheckOutDate > &qDateFrom
			|		AND Accommodations.AccommodationStatus.IsActive
			|		AND CASE
			|				WHEN &qAuthorNotFilled
			|					THEN TRUE
			|				ELSE Accommodations.Author = &qAuthor
			|			END) AS Documents
			|
			|ORDER BY
			|	Documents.SortCode";
		EndIf;
	EndIf;
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(pCustomer));
	vQry.SetParameter("qContract", pContract);
	vQry.SetParameter("qContractIsEmpty", Not ValueIsFilled(pContract));
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qRoomRateIsEmpty", Not ValueIsFilled(pRoomRate));
	vQry.SetParameter("qService", pService);
	vQry.SetParameter("qDateFrom", BegOfDay(pDateFrom));
	vQry.SetParameter("qDateTo", ?(ValueIsFilled(pDateTo), EndOfDay(pDateTo), EndOfDay('39991231')));   
	vQry.SetParameter("qAuthor", pAuthor);
	vQry.SetParameter("qAuthorNotFilled", Not ValueIsFilled(pAuthor)); 
	vQry.SetParameter("qReservationStatus", pReservationStatus);
	vQry.SetParameter("qReservationStatusIsEmpty", Not ValueIsFilled(pReservationStatus));
	vDocs = vQry.Execute().Unload();
	
	vProgress = 0;
	vStep = 100 / vDocs.Count();
	For Each vDocsRow In vDocs Do
		Try
			vDocObj = vDocsRow.Ref.GetObject();
			If pRefreshPriceCalculationDate Then
				vDocObj.PriceCalculationDate = '00010101';
				vDocObj.pmClearOccupationPercents();
			EndIf;
			If pRefreshChargingRules Then
				vDocObj.pmLoadDefaultChargingRules();
			EndIf;
			vDocObj.pmCalculateResources();
			vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
			vPayerStr = "";
			vPayer = vDocObj.pmSetPlannedPaymentMethod(vPayerStr);
			vDocObj.Write(DocumentWriteMode.Posting);
			If TypeOf(vDocObj) = Type("DocumentObject.Reservation") Then
				vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), pUser);
			Else
				vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), pUser);
			EndIf;
		Except
			vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Failed to process group '; ru='Ошибка при обработке группы '; de='Fehler beim Verarbeiten der Gruppe '") + TrimAll(vDocObj.GuestGroup.Code) + NStr("en=' and document '; ru=' и документа '; de=' und dokument '") + TrimAll(vDocObj.Ref) + ": " + vErrorDescription);
		EndTry;
		vProgress = vProgress + vStep;
		tcCommonFunctionOnClientServer.UserMessage("<progress>" + vProgress + "</progress>");
	EndDo;
EndProcedure // ReservationsList_RecalculateServices

Procedure ReservationsList_WriteRoomAssignment(pHotel, pRoomsAssigned, pUser) Export
	If pRoomsAssigned.Count() = 0 Then
		Return;
	EndIf;
	
	vProgress = 0;
	vStep = 100 / pRoomsAssigned.Count();
	
	For Each vRowData In pRoomsAssigned Do
		vResRef = vRowData.Reservation;
		vRoom = vRowData.Room;
		vRoomType = vRowData.RoomType;
		vRoomTypeUpgrade = vRowData.RoomTypeUpgrade;
		vOneRoomReservations = cmGetOneRoomReservations(vResRef.Number, vResRef.GuestGroup, vResRef.CheckInDate, vResRef.CheckOutDate, False);
		BeginTransaction(DataLockControlMode.Managed);
		Try
			For Each vResRow In vOneRoomReservations Do
				vResObj = vResRow.Ref.GetObject();
				If vResObj.Room <> vRoom Then
					
					vResObj.Room = vRoom;
					vResObj.RoomType = vRoomType;
					vResObj.RoomTypeUpgrade = vRoomTypeUpgrade;
					
					// Set room company
					If ValueIsFilled(vRoom) Then
						If ValueIsFilled(vRoom.Company) Then
							If vResObj.Company <> vRoom.Company And 
							  (Not ValueIsFilled(vResObj.Contract) Or 
							       ValueIsFilled(vResObj.Contract) And Not ValueIsFilled(vResObj.Contract.Company)) Then
								vResObj.Company = vRoom.Company;
							EndIf;
						EndIf;
					ElsIf ValueIsFilled(vRoomType) Then
						If ValueIsFilled(vRoomType.Company) Then
							If vResObj.Company <> vRoomType.Company And 
							  (Not ValueIsFilled(vResObj.Contract) Or 
							       ValueIsFilled(vResObj.Contract) And Not ValueIsFilled(vResObj.Contract.Company)) Then
								vResObj.Company = vRoomType.Company;
							EndIf;
						EndIf;
					EndIf;
					
					// Recalculate services
					vWarnings = "";
					If vResObj.pmCalculateServices(vWarnings , , , , , vResObj.IsForFolioSplit) Then
						tcCommonFunctionOnClientServer.UserMessage(cmNStr(vWarnings));
					EndIf;
					
					// Write document
					vResObj.Write(DocumentWriteMode.Posting);
					vResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndDo;
			
			// Reset flag that row has been changed
			vRowData.IsChanged = False;    
			
			CommitTransaction();
		Except     
			RollbackTransaction();
			vError = cmGetRootErrorDescription(ErrorInfo());
		EndTry;
		
		vProgress = vProgress + vStep;
		tcCommonFunctionOnClientServer.UserMessage("<progress>" + vProgress + "</progress>");
	EndDo;
EndProcedure // ReservationsList_WriteRoomAssignment

#EndRegion

#Region AccommodationsList

Procedure AccommodationsList_CheckOut(pHotel, pAccList, pCheckOutDate, pFixReservationConditions, pHavePermissionToCheckOutOnExpectedCheckOutTime, pCurrentUser) Export
	If pAccList.Count() = 0 Then
		Return;
	EndIf;
	
	vErrorDescription = "";
	vCurRoom = Undefined;
	vCheckOutDate = pCheckOutDate;
	
	vProgress = 0;
	vStep = 100 / pAccList.Count();
	
	// Do check-out for each document in the list
	BeginTransaction(DataLockControlMode.Managed);
	For Each vAccItem In pAccList Do
		vAccDoc = vAccItem.Value;
		// Commit transaction if room has changed
		If vCurRoom <> Undefined And vCurRoom <> vAccDoc.Room Then
			If TransactionActive() Then
				CommitTransaction();
				// Start transaction
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndIf;
		If vCurRoom <> vAccDoc.Room Then
			vCurRoom = vAccDoc.Room;
		EndIf;
		Try
			// Process document
			If vAccDoc.Posted And TypeOf(vAccDoc) = Type("DocumentRef.Accommodation") Then
				vSkipDocument = False;
				If pHavePermissionToCheckOutOnExpectedCheckOutTime Then
					vCheckOutDate = vAccDoc.CheckOutDate;
					If BegOfDay(vCheckOutDate) > BegOfDay(CurrentSessionDate()) Then
						vSkipDocument = True;
					EndIf;
				EndIf;
				If Not vSkipDocument Then
					// Do check-out
					vAccObj = vAccDoc.GetObject();
					If pFixReservationConditions Then
						vAccObj.FixReservationConditions = pFixReservationConditions;
					EndIf;
					vAccObj.pmCheckOut(vCheckOutDate, , vAccObj.IsForFolioSplit);
					vAccObj.Write(DocumentWriteMode.Posting);
					vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), pCurrentUser);
					// Hide client name data if necessary
					vAccObj.pmHideClientNameAndNameHistory();
				EndIf;
			Else
				Raise NStr("ru='Отметили в списке размещений для выселения не проведенное размещение! Процедура выселения возможна только для проведенных размещений. Операция отменена.';
				           |de='Sie haben in der Unterbringungsliste für die Räumung einer nicht erfolgten Unterbringung markiert! Die Räumung ist nur für erfolgte Unterbringungen möglich. Die Operation wurde abgebrochen.'; 
				           |en='You have selected not posted accommodation for check out! Check out procedure is possible for posted accommodations only. Operation is canceled.'");
			EndIf;
		Except     
			vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			WriteLogEvent(NStr("en='Accommodation.CheckOut';ru='Размещение.Выселение';de='Accommodation.CheckOut'"), EventLogLevel.Error, vAccDoc.Metadata(), vAccDoc, vErrorDescription);
			tcCommonFunctionOnClientServer.UserMessage(vErrorDescription);
			
			// Try to save current accommodation with in-house state
			If (Find(vErrorDescription, "CHECKOUT_WITH_DEBT") > 0 Or Find(vErrorDescription, "ADVANCES_NOT_CLEARED") > 0) And vAccDoc <> Undefined Then
				BeginTransaction(DataLockControlMode.Managed);
				Try
					// Do change check-out date and time
					For Each vAccItem In pAccList Do
						vAccDoc = vAccItem.Value;
						If vCurRoom = vAccDoc.Room Then
							vAccObj = vAccDoc.GetObject();
							If pFixReservationConditions Then
								vAccObj.FixReservationConditions = pFixReservationConditions;
							EndIf;
							vAccObj.CheckOutDate = vCheckOutDate;
							// Calculate duration
							vAccObj.Duration = vAccObj.pmCalculateDuration();
							// Automatic services list calculation
							vAccObj.pmCalculateServices( , , , , , vAccObj.IsForFolioSplit);
							vAccObj.Write(DocumentWriteMode.Posting);
							vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), pCurrentUser);
						EndIf;
					EndDo;
					If TransactionActive() Then
						CommitTransaction();
					EndIf;
				Except
					If TransactionActive() Then
						RollbackTransaction();
					EndIf;
				EndTry;
			EndIf;
		EndTry;
		
		vProgress = vProgress + vStep;
		tcCommonFunctionOnClientServer.UserMessage("<progress>" + vProgress + "</progress>");
	EndDo;
    If TransactionActive() Then
		CommitTransaction();
	EndIf;
EndProcedure // AccommodationsList_CheckOut

Procedure AccommodationsList_CheckIn(pHotel, pResList, pCheckinDate, pFixReservationConditions, pCurrentUser) Export
	If pResList.Count() = 0 Then
		Return;
	EndIf;
	
	vErrorDescription = "";
	vCurRoom = Undefined;
	
	vProgress = 0;
	vStep = 100 / pResList.Count();
	
	// Do check-out for each document in the list
	BeginTransaction(DataLockControlMode.Managed);
	For Each vResItem In pResList Do
		vResDoc = vResItem.Value;
		
		// Commit transaction if room has changed
		If vCurRoom <> Undefined And vCurRoom <> vResDoc.Room Then
			If TransactionActive() Then
				CommitTransaction();
				// Start transaction
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndIf;
		If vCurRoom <> vResDoc.Room Then
			vCurRoom = vResDoc.Room;
		EndIf;
			
		Try
			// Do check-in
			vAccObj = Documents.Accommodation.CreateDocument();
			vAccObj.Fill(vResDoc);
			If pFixReservationConditions Then
				vAccObj.FixReservationConditions = pFixReservationConditions;
			EndIf; 
			vUseCurrentTime = True;
			If ValueIsFilled(vResDoc.Hotel) Then
				vUseCurrentTime = Not vResDoc.Hotel.UseReservationTimeForCheckIn;
			EndIf;
			If ValueIsFilled(vResDoc.ReservationStatus) And vResDoc.ReservationStatus.UseReservationTimeForCheckIn Then
				vUseCurrentTime = False;
			EndIf;
			If vUseCurrentTime Then
            	vAccObj.CheckInDate = cm1SecondShift(pCheckinDate); 
			Else 
            	vAccObj.CheckInDate = cm1SecondShift(vResDoc.CheckinDate); 
			EndIf;
			vAccObj.Duration = vAccObj.pmCalculateDuration();
			vAccObj.pmCalculateServices( , , , , , vAccObj.IsForFolioSplit);
			vAccObj.Write(DocumentWriteMode.Posting);
			vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), pCurrentUser);
		Except    

			RollbackTransaction();

			vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
			WriteLogEvent(NStr("en='Accommodation.CheckIn';ru='Размещение.Заселение';de='Accommodation.CheckIn'"), EventLogLevel.Error, vResDoc.Metadata(), vResDoc, vErrorDescription);
			tcCommonFunctionOnClientServer.UserMessage(vErrorDescription);
		EndTry;
		
		vProgress = vProgress + vStep;
		tcCommonFunctionOnClientServer.UserMessage("<progress>" + vProgress + "</progress>");
	EndDo;
    If TransactionActive() Then
		CommitTransaction();
	EndIf;
EndProcedure // AccommodationsList_CheckIn

#EndRegion

#Region Telegram

Procedure Telegram_SendNotification(pHotel, pChatRole) Export
	Catalogs.ChatBots.SendNotification(pHotel, pChatRole);
EndProcedure

#EndRegion

#Region RoomRate

Procedure RoomRate_RepostPriceOrders(pOldRoomRate, pRoomRate) Export
	If ValueIsFilled(pOldRoomRate) And pOldRoomRate <> pRoomRate Then
		RoomRate_RepostRoomRatePriceOrders(pOldRoomRate);
	EndIf;
	If ValueIsFilled(pRoomRate) Then
		RoomRate_RepostRoomRatePriceOrders(pRoomRate);
	EndIf;
EndProcedure // RoomRate_RepostPriceOrders

Procedure RoomRate_RepostRoomRatePriceOrders(pRoomRate)
	// Get minimum of date valid from
	vMinDateValidFrom = '00010101';
	If pRoomRate.Formulas.Count() > 0 Then
		vMinDateValidFrom = pRoomRate.Formulas.Get(0).DateValidFrom;
	EndIf;
	// Run query to get documents to process
	vHotels = New ValueList();
	
	// Get active calendar day types
	vActiveDayTypesList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	CalendarRows.CalendarDayType AS CalendarDayType
	|FROM
	|	(SELECT DISTINCT
	|		CalendarDays.CalendarDayType AS CalendarDayType
	|	FROM
	|		InformationRegister.CalendarDays.SliceLast(
	|				,
	|				Calendar = &qCalendar
	|					AND AccountingDate >= &qCurrentDate) AS CalendarDays
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		CalendarDaysByRoomTypes.CalendarDayType
	|	FROM
	|		InformationRegister.CalendarDaysByRoomTypes.SliceLast(
	|				,
	|				Calendar = &qCalendar
	|					AND AccountingDate >= &qCurrentDate) AS CalendarDaysByRoomTypes
	|	WHERE
	|		CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)) AS CalendarRows";
	vQry.SetParameter("qCalendar", pRoomRate.Calendar);
	vQry.SetParameter("qCurrentDate", BegOfDay(CurrentSessionDate()));
	vDayTypes = vQry.Execute().Unload();
	vActiveDayTypesList.LoadValues(vDayTypes.UnloadColumn("CalendarDayType"));
	
	// Get set room rate prices documents to be reposted
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	RoomRatePricesMovements.SetRoomRatePrices AS Ref
	|FROM
	|	InformationRegister.RoomRatePrices AS RoomRatePricesMovements
	|WHERE
	|	(RoomRatePricesMovements.RoomRate = &qRoomRate
	|			OR RoomRatePricesMovements.RoomRate.BasedOnRoomRate = &qRoomRate)
	|	AND RoomRatePricesMovements.CalendarDayType IN(&qCalendarDayTypesList)
	|	AND RoomRatePricesMovements.SetRoomRatePrices.Date >= &qMinDateValidFrom
	|
	|ORDER BY
	|	RoomRatePricesMovements.SetRoomRatePrices.PointInTime";
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qCalendarDayTypesList", vActiveDayTypesList);
	vQry.SetParameter("qMinDateValidFrom", vMinDateValidFrom);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		// Repost document
		vDocObj = vDocsRow.Ref.GetObject();
		vDocObj.Write(DocumentWriteMode.Posting);
		If vHotels.FindByValue(vDocObj.Hotel) = Undefined Then
			vHotels.Add(vDocObj.Hotel);
		EndIf;
	EndDo;
	
	// Recalculate price cache
	For Each vHotelItem In vHotels Do
		vHotel = vHotelItem.Value;
		If ValueIsFilled(vHotel) And vHotel.UseRoomRateDailyPrices Then
			vRatesList = New ValueList();
			vRatesList.Add(pRoomRate);
		
			vDateFrom = '39991231';
			vDateTo = '00010101';
			
			GetCacheEffectivePeriod(vRatesList, vActiveDayTypesList, vDateFrom, vDateTo);
			
			If vDateFrom <= vDateTo Then
				JobsScheduled.cmFillRoomRatePricesCache(vHotel, vRatesList, vDateFrom, vDateTo);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // RoomRate_RepostRoomRatePriceOrders

// -----------------------------------------------------------------------------
Procedure GetCacheEffectivePeriod(pRatesList, pDayTypesList, rDateFrom, rDateTo)
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
		For Each vDayTypesItem In pDayTypesList Do
			vDayType = vDayTypesItem.Value;
			
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	MIN(CalendarDays.AccountingDate) AS MinPeriod,
			|	MAX(CalendarDays.AccountingDate) AS MaxPeriod
			|FROM
			|	InformationRegister.CalendarDays.SliceLast(, Calendar = &qCalendar AND CalendarDayType = &qCalendarDayType) AS CalendarDays  ";
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
EndProcedure // GetCacheEffectivePeriod

#EndRegion

#Region RoomType

Procedure RoomType_UpdateRoomAttributes(pRoomType, pCurrentUser) Export
	// Get list of all rooms of the given room type
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Rooms.Ref AS Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	Rooms.RoomType = &qRoomType
	|	AND NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|
	|ORDER BY
	|	Rooms.SortCode";
	vQry.SetParameter("qRoomType", pRoomType);
	vRooms = vQry.Execute().Unload();
	For Each vRoomsRow In vRooms Do
		vRoom = vRoomsRow.Ref;
		// Run query to get document used to set this room type
		Try
			vDocsQry = New Query();
			vDocsQry.Text = 
			"SELECT
			|	AddRooms.Ref AS Ref,
			|	AddRooms.Date AS Date,
			|	AddRooms.RoomType AS RoomType
			|FROM
			|	Document.AddRoom AS AddRooms
			|WHERE
			|	AddRooms.Room = &qRoom
			|	AND AddRooms.Posted
			|
			|UNION ALL
			|
			|SELECT
			|	ChangeRooms.Ref,
			|	ChangeRooms.Date,
			|	ChangeRooms.RoomType
			|FROM
			|	Document.ChangeRoom AS ChangeRooms
			|WHERE
			|	ChangeRooms.Room = &qRoom
			|	AND ChangeRooms.Posted
			|
			|ORDER BY
			|	Date DESC";
			vDocsQry.SetParameter("qRoom", vRoom);
			vDocs = vDocsQry.Execute().Unload();
			For Each vDocsRow In vDocs Do
				If vDocsRow.RoomType = pRoomType Then
					vDocObj = vDocsRow.Ref.GetObject();
					vDocObj.NumberOfBedsPerRoom = pRoomType.NumberOfBedsPerRoom;
					vDocObj.NumberOfPersonsPerRoom = pRoomType.NumberOfPersonsPerRoom;
					vDocObj.Write(DocumentWriteMode.Posting);
				EndIf;
				Break;
			EndDo;
		Except
			vErrorText = TrimAll(vRoom) + ": " + cmGetRootErrorDescription(ErrorInfo()) + "!";
			tcCommonFunctionOnClientServer.UserMessage(vErrorText);
			WriteLogEvent(NStr("en='Room.UpdateRoomAttributes'; ru='Номер.ОбновлениеПараметровНомера'; de='Zimmer.ZimmerAttributeAktualisieren'"), EventLogLevel.Warning, vRoom.Metadata(), vRoom, vErrorText);
		EndTry;
	EndDo;
EndProcedure // RoomType_UpdateRoomAttributes

#EndRegion

#Region DataProcessors

// Run DataProcessor as a background job
//
// Parameters:
//  pProcessing	 - String	 - 
//  pParameters	 - Structure - 
//
Procedure RunDataProcessor(pProcessing, pParameters) Export
	WriteLogEvent("RunDataProcessor."+pProcessing, 
					EventLogLevel.Information, 
					, 
					Undefined, 
					"Run data processor");

	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DataProcessors.Ref AS Ref
	|FROM
	|	Catalog.DataProcessors AS DataProcessors
	|WHERE
	|	NOT DataProcessors.DeletionMark
	|	AND NOT DataProcessors.IsFolder
	|	AND DataProcessors.Processing = &qDataProcessor
	|
	|ORDER BY
	|	DataProcessors.SortCode,
	|	DataProcessors.Code";
	vQry.SetParameter("qDataProcessor", pProcessing);
	vQryRes = vQry.Execute();
	If Not vQryRes.IsEmpty() Then
		vDPList = vQryRes.Select();
		While vDPList.Next() Do
			// Get object data processor
			vDPO = DataProcessors[pProcessing].Create();
			vDPO.DataProcessor = vDPList.Ref;
			// Load default settings
			vDPO.pmLoadDataProcessorAttributes();
			// I'll try to set the attributes
			If TypeOf(pParameters) = Type("Structure") Then
				// Set user settings
				For Each vAttr In pParameters Do
					Try
						vDPO[vAttr.Key] = vAttr.Value;
					Except
					EndTry;
				EndDo;
			EndIf;
			// Run data processor
			vDPO.pmRun();
		EndDo;
	EndIf;
EndProcedure // RunDataProcessor()

#EndRegion

#Region HTTP_data_request

&AtServer
Function ExternalSystemDataRequest(pInteractionParameters, pDataTypesArray, pAdditionalParameters = Undefined, doNotSendData = False, pSendGuestArray = False) Export
	
	Try
		vResult = New Map;
		
		vCurrentSessionDate = CurrentSessionDate();
		
		If pAdditionalParameters <> Undefined Then
			vAdditionalParameters = pAdditionalParameters;
		Else
			vAdditionalParameters = New Structure;
		EndIf;
		
		For Each vDataRequest In pDataTypesArray Do				
			vData = GetData(pInteractionParameters, vDataRequest, vAdditionalParameters, pSendGuestArray);
			vResult.Insert(vDataRequest, vData);
		EndDo;
		
		vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vResult, "DF='dd.MM.yyyy HH:mm:ss'");
		
	Except
		vError = ErrorDescription();
		vResult.Insert("Error", vError);	
	EndTry;
	
	If Not doNotSendData Then
		vHeaders = New Structure;
		vHeaders.Insert("authorization", pInteractionParameters.OAuth_AccessToken);
		Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vHeaders, Undefined, "POST", "DataRequest", vResponseBody, "JSON");
		vObj 								= pInteractionParameters.GetObject();
		vObj.LastFullSynchronizationTime 	= vCurrentSessionDate; 
		vObj.Write();
	EndIf;
	
	Return vResult;
	
EndFunction

&AtServer
Function GetData(pInteractionParameters, pDataType, pAdditionalParameters = Undefined, pSendGuestArray = False)
	
	vResult 	= Undefined;
	vPeriodFrom = Undefined;
	
	If pAdditionalParameters <> Undefined Then
		pAdditionalParameters.Property("PeriodFrom", vPeriodFrom);
	EndIf;
	
	If pDataType = "reservations" Then
		vHotel 					= pInteractionParameters.Hotel;	
 	
		If Not ValueIsFilled(vPeriodFrom) Then
			vPeriodFrom = pInteractionParameters.LastFullSynchronizationTime;
		EndIf;
		
		// Data in changed documents
		vResult = GetChangedReservations(vPeriodFrom, vHotel, pInteractionParameters.Code, pSendGuestArray);
	EndIf;

	Return vResult;
	
EndFunction

&AtServer
Function GetChangedReservations(pPeriodFrom, pHotel, pExternalSystemCode, pSendGuestArray = False)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Docs.SortCode AS SortCode,
		|	Docs.Number AS ConfNumber,
		|	ISNULL(ReservationStatusesCodes.ObjectExternalCode, Docs.ReservationStatus) AS ReservationStatus,
		|	Docs.CheckInDate AS ArrivalDate,
		|	Docs.CheckOutDate AS DepartureDate,
		|	ClientsList.Salutation.Description AS Title,
		|	ClientsList.FirstName AS FirstName,
		|	ClientsList.LastName AS LastName,
		|	ClientsList.SecondName AS MiddleName,
		|	CASE
		|		WHEN Docs.Phone = """"
		|			THEN ClientsList.Phone
		|		ELSE Docs.Phone
		|	END AS PhoneNumber,
		|	CASE
		|		WHEN Docs.EMail = """"
		|			THEN ClientsList.EMail
		|		ELSE Docs.EMail
		|	END AS Email,
		|	Docs.NumberOfAdults AS Adults,
		|	Docs.NumberOfTeenagers + Docs.NumberOfChildren + Docs.NumberOfInfants AS Children,
		|	Docs.ClientType AS VipCode,
		|	Docs.GuestGroup.Description AS GroupNameID,
		|	Docs.GuestGroup AS GuestGroup,
		|	Docs.Customer.Description AS CompanyName,
		|	Docs.RoomRate AS RoomRate,
		|	Docs.RoomType AS RoomType,
		|	Docs.Room AS RoomNo,
		|	Docs.Date AS CreationDate,
		|	Docs.Remarks AS Comments,
		|	Docs.Reservation AS Ref,
		|	Docs.Number AS Number,
		|	Docs.AccommodationTemplate AS AccommodationTemplate,
		|	Docs.Duration AS Duration,
		|	Docs.Hotel AS Hotel
		|INTO ReservationsData
		|FROM
		|	InformationRegister.ReservationChangeHistory.SliceLast(
		|			,
		|			Period >= &qPeriodFrom
		|				AND Hotel = &qHotel) AS Docs
		|		INNER JOIN Catalog.ReservationStatuses AS ReservationStatuses
		|		ON Docs.ReservationStatus = ReservationStatuses.Ref
		|			AND (NOT ReservationStatuses.IsCheckIn)
		|		INNER JOIN Catalog.Clients AS ClientsList
		|		ON Docs.Guest = ClientsList.Ref
		|		LEFT JOIN Catalog.AccommodationTypes AS AccommodationTypes
		|		ON Docs.AccommodationType = AccommodationTypes.Ref
		|		LEFT JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS ReservationStatusesCodes
		|		ON Docs.ReservationStatus = ReservationStatusesCodes.ObjectRef
		|			AND (ReservationStatusesCodes.ObjectTypeName = ""ReservationStatuses"")
		|			AND (ReservationStatusesCodes.ExternalSystemCode = &qExternalSystemCode)
		|WHERE
		|	Docs.Posted
		|	AND CASE
		|			WHEN Docs.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|				THEN AccommodationTypes.Type = VALUE(Enum.AccomodationTypes.Room)
		|						OR AccommodationTypes.Type = VALUE(Enum.AccomodationTypes.Beds)
		|			ELSE TRUE
		|		END
		|
		|UNION ALL
		|
		|SELECT
		|	Docs.SortCode,
		|	Docs.Number,
		|	ISNULL(AccommodationStatusesCodes.ObjectExternalCode, Docs.AccommodationStatus),
		|	Docs.CheckInDate,
		|	Docs.CheckOutDate,
		|	ClientsList.Salutation.Description,
		|	ClientsList.FirstName,
		|	ClientsList.LastName,
		|	ClientsList.SecondName,
		|	CASE
		|		WHEN Docs.Phone = """"
		|			THEN ClientsList.Phone
		|		ELSE Docs.Phone
		|	END,
		|	CASE
		|		WHEN Docs.EMail = """"
		|			THEN ClientsList.EMail
		|		ELSE Docs.EMail
		|	END,
		|	Docs.NumberOfAdults,
		|	Docs.NumberOfTeenagers + Docs.NumberOfChildren + Docs.NumberOfInfants,
		|	Docs.ClientType,
		|	Docs.GuestGroup.Description,
		|	Docs.GuestGroup,
		|	Docs.Customer.Description,
		|	Docs.RoomRate,
		|	Docs.RoomType,
		|	Docs.Room.Description,
		|	Docs.Date,
		|	Docs.Remarks,
		|	Docs.Accommodation,
		|	Docs.Number,
		|	Docs.AccommodationTemplate,
		|	Docs.Duration,
		|	Docs.Hotel
		|FROM
		|	InformationRegister.AccommodationChangeHistory.SliceLast(
		|			,
		|			Period >= &qPeriodFrom
		|				AND Hotel = &qHotel) AS Docs
		|		INNER JOIN Catalog.AccommodationStatuses AS AccommodationStatuses
		|		ON Docs.AccommodationStatus = AccommodationStatuses.Ref
		|			AND (AccommodationStatuses.IsActive)
		|		INNER JOIN Catalog.Clients AS ClientsList
		|		ON Docs.Guest = ClientsList.Ref
		|		LEFT JOIN Catalog.AccommodationTypes AS AccommodationTypes
		|		ON Docs.AccommodationType = AccommodationTypes.Ref
		|		LEFT JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS AccommodationStatusesCodes
		|		ON Docs.AccommodationStatus = AccommodationStatusesCodes.ObjectRef
		|			AND (AccommodationStatusesCodes.ObjectTypeName = ""AccommodationStatuses"")
		|			AND (AccommodationStatusesCodes.ExternalSystemCode = &qExternalSystemCode)
		|WHERE
		|	Docs.Posted
		|	AND CASE
		|			WHEN Docs.AccommodationTemplate = VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|				THEN AccommodationTypes.Type = VALUE(Enum.AccomodationTypes.Room)
		|						OR AccommodationTypes.Type = VALUE(Enum.AccomodationTypes.Beds)
		|			ELSE TRUE
		|		END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsData.Ref AS Ref,
		|	Folio.Ref AS Folio,
		|	Folio.FolioCurrency AS FolioCurrency
		|INTO FolioList
		|FROM
		|	Document.Folio AS Folio
		|		INNER JOIN ReservationsData AS ReservationsData
		|		ON Folio.GuestGroup = ReservationsData.GuestGroup
		|			AND (CAST(Folio.ParentDoc AS Document.Accommodation).Number = ReservationsData.Number)
		|WHERE
		|	Folio.ParentDoc REFS Document.Reservation
		|
		|UNION ALL
		|
		|SELECT
		|	ReservationsData.Ref,
		|	Folio.Ref,
		|	Folio.FolioCurrency
		|FROM
		|	Document.Folio AS Folio
		|		INNER JOIN ReservationsData AS ReservationsData
		|		ON Folio.GuestGroup = ReservationsData.GuestGroup
		|			AND (CAST(Folio.ParentDoc AS Document.Accommodation).Number = ReservationsData.Number)
		|WHERE
		|	Folio.ParentDoc REFS Document.Accommodation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(SalesList.Sales) AS TotalAmount,
		|	SalesList.Ref AS Ref,
		|	SalesList.FolioCurrency AS FolioCurrency
		|INTO ReservationsTotalAmount
		|FROM
		|	(SELECT
		|		FolioList.Ref AS Ref,
		|		SalesList.Sales AS Sales,
		|		ISNULL(CurrenciesCodes.ObjectExternalCode, FolioList.FolioCurrency) AS FolioCurrency
		|	FROM
		|		AccumulationRegister.Sales AS SalesList
		|			INNER JOIN FolioList AS FolioList
		|			ON SalesList.Folio = FolioList.Folio
		|			LEFT JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS CurrenciesCodes
		|			ON (FolioList.FolioCurrency = CurrenciesCodes.ObjectRef)
		|				AND (CurrenciesCodes.ObjectTypeName = ""Currencies"")
		|				AND (CurrenciesCodes.ExternalSystemCode = &qExternalSystemCode)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FolioList.Ref,
		|		SalesForecast.Sales,
		|		ISNULL(CurrenciesCodes.ObjectExternalCode, FolioList.FolioCurrency)
		|	FROM
		|		AccumulationRegister.SalesForecast AS SalesForecast
		|			INNER JOIN FolioList AS FolioList
		|			ON SalesForecast.Folio = FolioList.Folio
		|			LEFT JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS CurrenciesCodes
		|			ON (FolioList.FolioCurrency = CurrenciesCodes.ObjectRef)
		|				AND (CurrenciesCodes.ObjectTypeName = ""Currencies"")
		|				AND (CurrenciesCodes.ExternalSystemCode = &qExternalSystemCode)) AS SalesList
		|
		|GROUP BY
		|	SalesList.Ref,
		|	SalesList.FolioCurrency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ReservationsFullData.SortCode AS SortCode,
		|	ReservationsFullData.ConfNumber AS ConfNumber,
		|	ReservationsFullData.ReservationStatus AS ReservationStatus,
		|	ReservationsFullData.ArrivalDate AS ArrivalDate,
		|	ReservationsFullData.DepartureDate AS DepartureDate,
		|	ISNULL(ReservationsFullData.Title, """") AS Title,
		|	ReservationsFullData.FirstName AS FirstName,
		|	ReservationsFullData.LastName AS LastName,
		|	ReservationsFullData.MiddleName AS MiddleName,
		|	ReservationsFullData.PhoneNumber AS PhoneNumber,
		|	ReservationsFullData.Email AS Email,
		|	ReservationsFullData.Adults AS Adults,
		|	ReservationsFullData.Children AS Children,
		|	ReservationsFullData.VipCode AS VipCode,
		|	ReservationsFullData.GroupNameID AS GroupNameID,
		|	ISNULL(ReservationsFullData.CompanyName, """") AS CompanyName,
		|	ISNULL(RoomTypesCodes.ObjectExternalCode, ReservationsFullData.RoomType) AS RoomType,
		|	ReservationsFullData.RoomNo AS RoomNo,
		|	ReservationsFullData.CreationDate AS CreationDate,
		|	CAST(ReservationsFullData.Comments AS STRING(999)) AS Comments,
		|	ISNULL(ReservationsTotalAmount.TotalAmount, 0) AS TotalAmount,
		|	ISNULL(ReservationsTotalAmount.FolioCurrency, VALUE(Catalog.Currencies.EmptyRef)) AS CurrencyCode,
		|	ReservationsFullData.Hotel AS Hotel,
		|	CASE
		|		WHEN ReservationsFullData.Duration = 0
		|			THEN ISNULL(ReservationsTotalAmount.TotalAmount, 0)
		|		ELSE ISNULL(ReservationsTotalAmount.TotalAmount, 0) / ReservationsFullData.Duration
		|	END AS RateAmount,
		|	ISNULL(AccommodationTemplatesCodes.ObjectExternalCode, ReservationsFullData.AccommodationTemplate) AS AccommodationTemplate,
		|	ISNULL(RoomRatesCodes.ObjectExternalCode, ReservationsFullData.RoomRate) AS RoomRate,
		|	ReservationsFullData.Ref AS Ref
		|FROM
		|	ReservationsData AS ReservationsFullData
		|		LEFT JOIN ReservationsTotalAmount AS ReservationsTotalAmount
		|		ON ReservationsFullData.Ref = ReservationsTotalAmount.Ref
		|		LEFT JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS RoomTypesCodes
		|		ON ReservationsFullData.RoomType = RoomTypesCodes.ObjectRef
		|			AND (RoomTypesCodes.ObjectTypeName = ""RoomTypes"")
		|			AND (RoomTypesCodes.ExternalSystemCode = &qExternalSystemCode)
		|		LEFT JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS RoomRatesCodes
		|		ON ReservationsFullData.RoomRate = RoomRatesCodes.ObjectRef
		|			AND (RoomRatesCodes.ObjectTypeName = ""RoomRates"")
		|			AND (RoomRatesCodes.ExternalSystemCode = &qExternalSystemCode)
		|		LEFT JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS AccommodationTemplatesCodes
		|		ON ReservationsFullData.AccommodationTemplate = AccommodationTemplatesCodes.ObjectRef
		|			AND (AccommodationTemplatesCodes.ObjectTypeName = ""AccommodationTemplates"")
		|			AND (AccommodationTemplatesCodes.ExternalSystemCode = &qExternalSystemCode)"; 
	vQuery.SetParameter("qPeriodFrom", pPeriodFrom);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qExternalSystemCode", pExternalSystemCode);
	vData = vQuery.Execute().Unload();
	If pSendGuestArray Then
		vData.Columns.Add("Guest", New TypeDescription("Array"));
		vQ = New Query();
		vQ.Text = 
		"SELECT
		|	Accommodation.GuestGroup AS GuestGroup,
		|	Accommodation.Number AS Number,
		|	Accommodation.Ref AS Ref
		|INTO DocumentMainList
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	Accommodation.Ref IN(&qDocumenRefList)
		|
		|UNION ALL
		|
		|SELECT
		|	Reservation.GuestGroup,
		|	Reservation.Number,
		|	Reservation.Ref
		|FROM
		|	Document.Reservation AS Reservation
		|WHERE
		|	Reservation.Ref IN(&qDocumenRefList)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ClientsList.FirstName AS FirstName,
		|	ClientsList.LastName AS LastName,
		|	ClientsList.SecondName AS MiddleName,
		|	CASE
		|		WHEN Reservation.Phone = """"
		|			THEN ClientsList.Phone
		|		ELSE Reservation.Phone
		|	END AS PhoneNumber,
		|	CASE
		|		WHEN Reservation.EMail = """"
		|			THEN ClientsList.EMail
		|		ELSE Reservation.EMail
		|	END AS Email,
		|	DocumentMainList.Ref AS MainRef,
		|	Reservation.Ref AS Ref
		|FROM
		|	Document.Reservation AS Reservation
		|		INNER JOIN Catalog.ReservationStatuses AS ReservationStatuses
		|		ON Reservation.ReservationStatus = ReservationStatuses.Ref
		|			AND (NOT ReservationStatuses.IsCheckIn)
		|		INNER JOIN Catalog.Clients AS ClientsList
		|		ON Reservation.Guest = ClientsList.Ref
		|		INNER JOIN DocumentMainList AS DocumentMainList
		|		ON Reservation.Number = DocumentMainList.Number
		|			AND Reservation.GuestGroup = DocumentMainList.GuestGroup
		|WHERE
		|	Reservation.Posted
		|
		|UNION ALL
		|
		|SELECT
		|	ClientsList.FirstName,
		|	ClientsList.LastName,
		|	ClientsList.SecondName,
		|	CASE
		|		WHEN Accommodation.Phone = """"
		|			THEN ClientsList.Phone
		|		ELSE Accommodation.Phone
		|	END,
		|	CASE
		|		WHEN Accommodation.EMail = """"
		|			THEN ClientsList.EMail
		|		ELSE Accommodation.EMail
		|	END,
		|	DocumentMainList.Ref,
		|	Accommodation.Ref
		|FROM
		|	Document.Accommodation AS Accommodation
		|		INNER JOIN Catalog.AccommodationStatuses AS AccommodationStatuses
		|		ON Accommodation.AccommodationStatus = AccommodationStatuses.Ref
		|			AND (AccommodationStatuses.IsActive)
		|		INNER JOIN Catalog.Clients AS ClientsList
		|		ON Accommodation.Guest = ClientsList.Ref
		|		INNER JOIN DocumentMainList AS DocumentMainList
		|		ON Accommodation.Number = DocumentMainList.Number
		|			AND Accommodation.GuestGroup = DocumentMainList.GuestGroup
		|WHERE
		|	Accommodation.Posted";
		vQ.SetParameter("qHotel", pHotel);
		vQ.SetParameter("qDocumenRefList", vData.UnloadColumn("Ref"));
		vGuestDate = vQ.Execute().Unload();
		
		For Each vRow In vData Do 
			vRow.Guest = vGuestDate.FindRows(New Structure("MainRef", vRow.Ref));		
		EndDo;
		
		vGuestDate.Columns.Delete("MainRef");
	EndIf;
	Return vData;
EndFunction // GetChangedReservations

#EndRegion

#Region LoadAddressClassifierRu

Procedure LoadAddressClassifierRu_LoadClassifiers(pAddressClassifierFile, pStreetsClassifierFile, pAbbreviationsClassifierFile, pLoadRegionsList) Export
	// Initialize cache value tables
	vRegions = New ValueTable();
	vAreas = New ValueTable();
	vCities = New ValueTable();
	vStreets = New ValueTable();
	vAbbreviations = New ValueTable();
	
	// Open abbreviations classifier
	vAbbreviationsClassifier = New XBase(pAbbreviationsClassifierFile, , True);
	If vAbbreviationsClassifier.IsOpen() Then		
		tcCommonFunctionOnClientServer.UserMessage("<message>"+NStr("ru = 'Загружается файл '; en = 'Processing file '; de = 'Processing file '") + "Abbreviations Classifier File</message>");
		tcCommonFunctionOnClientServer.UserMessage("<progress>" + Format(0, "NG=") + "</progress>");

		Try
			BeginTransaction(DataLockControlMode.Managed);
			// Check classifier file fields
			If (vAbbreviationsClassifier.Fields.Find("KOD_T_ST") = Undefined)
			Or (vAbbreviationsClassifier.Fields.Find("SOCRNAME") = Undefined)
			Or (vAbbreviationsClassifier.Fields.Find("SCNAME") = Undefined)
			Or (vAbbreviationsClassifier.Fields.Find("LEVEL") = Undefined) Then
				Raise NStr("ru = 'Классификатор сокращений неправильной структуры! Не загружен!'; en = 'Abbreviations classifier has wrong structure! Load canceled!'; de = 'Abbreviations classifier has wrong structure! Load canceled!'");
			Else
				vAbbreviationsClassifier.First();
				If Not vAbbreviationsClassifier.EOF() Then
					SetEncoding(vAbbreviationsClassifier);
					
					vAbbreviationObjType = Number(vAbbreviationsClassifier.LEVEL);
					If vAbbreviationObjType <> 6 Then
						vFacet = Number(TrimAll(vAbbreviationsClassifier.KOD_T_ST));
						vAbbreviationRef = Catalogs.Abbreviations.FindByCode(vFacet);
						If Not ValueIsFilled(vAbbreviationRef) Then
							vAbbreviationObj = Catalogs.Abbreviations.CreateItem();
							vAbbreviationObj.Code = vFacet;
						Else
							vAbbreviationObj = vAbbreviationRef.GetObject();
						EndIf;
						
						vAbbreviationObj.Description = TrimAll(vAbbreviationsClassifier.SOCRNAME);
						vAbbreviationObj.Abbreviation = TrimAll(vAbbreviationsClassifier.SCNAME);
						vAbbreviationObj.AbbreviationType = GetAbbreviationTypeForLevel(vAbbreviationObjType);
						
						vAbbreviationObj.Write();
					EndIf;
					
						vProgress = 0;
						vStep = 100 / vAbbreviationsClassifier.RecCount();
						
					While vAbbreviationsClassifier.Next() Do
						vProgress = vProgress + vStep*vAbbreviationsClassifier.RecNo();
						tcCommonFunctionOnClientServer.UserMessage("<progress>" +vProgress+ "</progress>");
						
						vAbbreviationObjType = Number(vAbbreviationsClassifier.LEVEL);
						If vAbbreviationObjType <> 6 Then
							vFacet = Number(TrimAll(vAbbreviationsClassifier.KOD_T_ST));
							vAbbreviationRef = Catalogs.Abbreviations.FindByCode(vFacet);
							If Not ValueIsFilled(vAbbreviationRef) Then
								vAbbreviationObj = Catalogs.Abbreviations.CreateItem();
								vAbbreviationObj.Code = vFacet;
							Else
								vAbbreviationObj = vAbbreviationRef.GetObject();
							EndIf;
							
							vAbbreviationObj.Description = TrimAll(vAbbreviationsClassifier.SOCRNAME);
							vAbbreviationObj.Abbreviation = TrimAll(vAbbreviationsClassifier.SCNAME);
							vAbbreviationObj.AbbreviationType = GetAbbreviationTypeForLevel(vAbbreviationObjType);
							
							vAbbreviationObj.Write();
						EndIf;
					EndDo;
				EndIf;
				vAbbreviationsClassifier.CloseFile();
			EndIf;
			CommitTransaction();
			Except
			vErrorDescription = ErrorDescription();
			RollbackTransaction();
			Raise vErrorDescription;
		EndTry;		
	EndIf;
	
	// Load all abbreviations to the cache value table
	vAbbreviations = GetAllAbbreviations();
	
	// Load regions
	LoadRegions(vAbbreviations);
	
	// Load all regions to the cache value table
	vRegions = GetAllRegions();
	
	// Process all checked regions
	For Each vRegionItem In pLoadRegionsList Do
		If vRegionItem.Check Then
			// Current region code
			vRegionCode = Format(Number(vRegionItem.Value), "ND=2; NLZ=");
			vRegion = GetRegionRef(vRegions, vRegionCode);
			
			// Load current classifier data to the cache value tables
			vAreas.Indexes.Clear();
			vAreas.Clear();
			vAreas = GetRegionAreas(vRegion);
			vCities.Indexes.Clear();
			vCities.Clear();
			vCities = GetRegionCities(vRegion);
			vStreets.Indexes.Clear();
			vStreets.Clear();
			vStreets = GetRegionStreets(vRegion);
			
			// Add indexes to the cache tables
			vAreas.Indexes.Add("Region, Code");
			vCities.Indexes.Add("Region, Area, Code");
			vStreets.Indexes.Add("Region, Area, City, Code");
			
			// Build index string to index xBase KLADR files
			vIndexStr = "SUBSTR(CODE,1,2)='" + vRegionCode + "'";
			
			// Open address classifier
			vAddressClassifier = New XBase(pAddressClassifierFile);
			If vAddressClassifier.IsOpen() Then
								
				tcCommonFunctionOnClientServer.UserMessage("<progress>" + Format(0, "NG=") + "</progress>");

				Try
					BeginTransaction(DataLockControlMode.Managed);
					// Check classifier file fields
					If (vAddressClassifier.Fields.Find("CODE") = Undefined)
					Or (vAddressClassifier.Fields.Find("NAME") = Undefined)
					Or (vAddressClassifier.Fields.Find("SOCR") = Undefined)
					Or (vAddressClassifier.Fields.Find("INDEX") = Undefined) Then
						Raise NStr("ru = 'Классификатор адресов неправильной структуры! Не загружен!'; en = 'Address classifier has wrong structure! Load canceled!'; de = 'Address classifier has wrong structure! Load canceled!'");
					Else 
						vAddressClassifier.Indexes.Add("MAIN","RECNO()", , , vIndexStr);
						vAddressClassifier.CreateIndex(TempFilesDir() + "mainkldr.cdx");
						vAddressClassifier.CloseFile();
						
						vAddressClassifier = New XBase(pAddressClassifierFile, TempFilesDir() + "mainkldr.cdx", True);
						If Not vAddressClassifier.IsOpen() Then
							vAddressClassifier.OpenFile(pAddressClassifierFile, TempFilesDir() + "mainkldr.cdx", True);
						EndIf;
						vAddressClassifier.CurrentIndex = vAddressClassifier.Indexes.Find("MAIN");
							
						SetEncoding(vAddressClassifier);
						
						// Calculate number of records to process
						vRecNumber = 0;
						vAddressClassifier.First();
						If Not vAddressClassifier.EOF() Then
							vRecNumber = vRecNumber + 1;
							While vAddressClassifier.Next() Do
								vRecNumber = vRecNumber + 1;
							EndDo;
						EndIf;

						// Load records
						tcCommonFunctionOnClientServer.UserMessage("<message>" + NStr("ru = 'Загружаем адреса для региона: '; en = 'Loading addresses for the region: '; de = 'Laden Sie Adressen für die Region: '") + vRegionItem + "</message>");
						vRecNo = 0;
						vAddressClassifier.First();
						If Not vAddressClassifier.EOF() Then
							vFormat2003 = True;
							LoadAddressItem(vAddressClassifier.CODE,
							                vAddressClassifier.NAME,
							                vAddressClassifier.SOCR,
							                vAddressClassifier.INDEX,
							                100000000, ?(vFormat2003, 100, 1), 
							                vFormat2003,
							                vAbbreviations, vRegions, vAreas, vCities, vStreets, False);
											
							vRecNo = vRecNo + 1;
							While vAddressClassifier.Next() Do
								LoadAddressItem(vAddressClassifier.CODE,
								                vAddressClassifier.NAME,
								                vAddressClassifier.SOCR,
								                vAddressClassifier.INDEX,
								                1000000000000, ?(vFormat2003, 100, 1), 
							                    vFormat2003,
							                    vAbbreviations, vRegions, vAreas, vCities, vStreets, False);
											
								vRecNo = vRecNo + 1;
								If vRecNo / 100 = Int(vRecNo / 100) Then
									tcCommonFunctionOnClientServer.UserMessage("<progress>" +Int((vRecNo/vRecNumber)*100)+ "</progress>");
								EndIf;
							EndDo;
						EndIf;
						vAddressClassifier.CloseFile();
					EndIf;
					CommitTransaction();
				Except
					vErrorDescription = ErrorDescription();
					RollbackTransaction();
					Raise vErrorDescription;
				EndTry;
			EndIf;

			// Open streets classifier
			vStreetsClassifier = New XBase(pStreetsClassifierFile);
			If vStreetsClassifier.IsOpen() Then
				tcCommonFunctionOnClientServer.UserMessage("<progress>" + Format(0,"NG=") + "</progress>");

				Try
					BeginTransaction(DataLockControlMode.Managed);
					// Check classifier file fields
					If (vStreetsClassifier.Fields.Find("CODE") = Undefined)
					Or (vStreetsClassifier.Fields.Find("NAME") = Undefined)
					Or (vStreetsClassifier.Fields.Find("SOCR") = Undefined)
					Or (vStreetsClassifier.Fields.Find("INDEX") = Undefined) Then
						Raise NStr("ru = 'Классификатор улиц неправильной структуры! Не загружен!'; en = 'Streets classifier has wrong structure! Load canceled!'; de = 'Streets classifier has wrong structure! Load canceled!'");
					Else
						vStreetsClassifier.Indexes.Add("MAIN","RECNO()", , , vIndexStr);
						vStreetsClassifier.CreateIndex(TempFilesDir() + "mainkldr.cdx");
						vStreetsClassifier.CloseFile();
						
						vStreetsClassifier = New XBase(pStreetsClassifierFile, TempFilesDir() + "mainkldr.cdx", True);
						If Not vStreetsClassifier.IsOpen() Then
							vStreetsClassifier.OpenFile(pStreetsClassifierFile, TempFilesDir() + "mainkldr.cdx", True);
						EndIf;
						vStreetsClassifier.CurrentIndex = vStreetsClassifier.Indexes.Find("MAIN");

						SetEncoding(vStreetsClassifier);
						
						// Calculate number of records to process
						vRecNumber = 0;
						vStreetsClassifier.First();
						If Not vStreetsClassifier.EOF() Then
							vRecNumber = vRecNumber + 1;
							While vStreetsClassifier.Next() Do
								vRecNumber = vRecNumber + 1;
							EndDo;
						EndIf;

						// Load records
						tcCommonFunctionOnClientServer.UserMessage("<message>" + NStr("ru = 'Загружаем улицы для региона: '; en = 'Loading streets for the region: '; de = 'Laden Sie Straßen für die Region: '") + vRegionItem +"</message>");
						vRecNo = 0;
						vStreetsClassifier.First();
						
						If Not vStreetsClassifier.EOF() Then
							vFormat2003 = True;
							LoadAddressItem(vStreetsClassifier.CODE,
							                vStreetsClassifier.NAME,
							                vStreetsClassifier.SOCR,
							                vStreetsClassifier.INDEX,
							                100000000, ?(vFormat2003, 100, 1), 
							                vFormat2003,
							                vAbbreviations, vRegions, vAreas, vCities, vStreets, True);
											
							vRecNo = vRecNo + 1;
							While vStreetsClassifier.Next() Do
								LoadAddressItem(vStreetsClassifier.CODE,
								                vStreetsClassifier.NAME,
								                vStreetsClassifier.SOCR,
								                vStreetsClassifier.INDEX,
								                100000000, ?(vFormat2003, 100, 1),
							                    vFormat2003,
							                    vAbbreviations, vRegions, vAreas, vCities, vStreets, True);
																				
								vRecNo = vRecNo + 1;
								If vRecNo / 100 = Int(vRecNo / 100) Then
									tcCommonFunctionOnClientServer.UserMessage("<progress>" +Int((vRecNo/vRecNumber)*100)+ "</progress>");
								EndIf;
							EndDo;
						EndIf;
						vStreetsClassifier.CloseFile();
					EndIf;
					CommitTransaction();
				Except
					vErrorDescription = ErrorDescription();
					RollbackTransaction();
					Raise vErrorDescription;
				EndTry;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // LoadClassifiers

Procedure SetEncoding(pFileBD)
	pFileBD.Encoding = XBaseEncoding.OEM;
EndProcedure // SetEncoding

Function GetAbbreviationTypeForLevel(pLevel)
	If pLevel = 1 Then
		Return Enums.AbbreviationTypes.Region;
	ElsIf pLevel = 2 Then
		Return Enums.AbbreviationTypes.Area;
	ElsIf pLevel = 3 Then
		Return Enums.AbbreviationTypes.City;
	ElsIf pLevel = 4 Then
		Return Enums.AbbreviationTypes.City;
	ElsIf pLevel = 5 Then
		Return Enums.AbbreviationTypes.Street;
	Else
		Return Enums.AbbreviationTypes.EmptyRef();
	EndIf;
EndFunction // GetAbbreviationTypeForLevel

Function GetAllAbbreviations()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Abbreviations.Ref AS Ref,
	|	Abbreviations.Description AS Description,
	|	Abbreviations.Abbreviation AS Abbreviation,
	|	Abbreviations.AbbreviationType AS AbbreviationType
	|FROM
	|	Catalog.Abbreviations AS Abbreviations";
	Return vQry.Execute().Unload();
EndFunction // GetAllAbbreviations

Procedure LoadRegions(pAbbreviations)
	// Show progress bar
	
	Russia = Catalogs.Countries.FindByCode(643);
	tcCommonFunctionOnClientServer.UserMessage("<message>"+NStr("ru = 'Загрузка регионов'; en = 'Load regions'; de = 'Load regions'")+"</message>");
	tcCommonFunctionOnClientServer.UserMessage("<progress>" + Format(0, "NG=") + "</progress>");
	
	Try
		BeginTransaction(DataLockControlMode.Managed);
		// Update Russia regions lst from the template
		vRegions = DataProcessors.LoadAddressClassifierRu.GetTemplate("RegionsListRu");
		vRegionsCount = vRegions.TableHeight - 1;
		vTemplateRegionsList = New ValueList();
		For vInt = 2 To (vRegionsCount + 1) Do
			tcCommonFunctionOnClientServer.UserMessage("<progress>" + Format((vInt - 1) * 100 / vRegionsCount, "NG=") + "</progress>");

			vRegionCode = Format(Int(Number(vRegions.Area(vInt, 1, vInt, 1).Text)/RegionMask()), "ND=2; NFD=0; NZ=; NLZ=; NG=");
			vRegionRef = cmGetRegionByCode(vRegionCode, Russia);
			If ValueIsFilled(vRegionRef) Then
				vRegionObj = vRegionRef.GetObject();
			Else
				vRegionObj = Catalogs.Regions.CreateItem();
				vRegionObj.Code = vRegionCode;
				vRegionObj.Country = Russia;
			EndIf;
			
			vAbbreviation = TrimAll(vRegions.Area(vInt, 3, vInt, 3).Text);
			vRegionObj.Description = TrimAll(vRegions.Area(vInt, 2, vInt, 2).Text) + " " + vAbbreviation;
			vRegionObj.Abbreviation = GetAbbreviationRef(pAbbreviations, vAbbreviation, Enums.AbbreviationTypes.Region);
			vRegionObj.PostCode = TrimAll(vRegions.Area(vInt, 4, vInt, 4).Text);
			
			vRegionObj.Write();
			
			vTemplateRegionsList.Add(vRegionObj.Ref);
		EndDo;
		// Delete regions that are not in the template anymore
		If vTemplateRegionsList.Count() > 0 Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Regions.Ref AS Ref
			|FROM
			|	Catalog.Regions AS Regions
			|WHERE
			|	Regions.Country = &qRussia
			|	AND NOT Regions.Ref IN (&qTemplateRegionsList)
			|	AND NOT Regions.DeletionMark
			|
			|ORDER BY
			|	Regions.Code";
			vQry.SetParameter("qRussia", Russia);
			vQry.SetParameter("qTemplateRegionsList", vTemplateRegionsList);
			vRegionsToDelete = vQry.Execute().Unload();
			For Each vRegionsToDeleteRow In vRegionsToDelete Do
				vRegionsToDeleteRow.Ref.GetObject().SetDeletionMark(True);
			EndDo;
		EndIf;
		CommitTransaction();
	Except
		vErrorDescription = ErrorDescription();
		RollbackTransaction();
		Raise vErrorDescription;
	EndTry;
EndProcedure // LoadRegions

Function GetAllRegions()
	Russia = Catalogs.Countries.FindByCode(643);
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Regions.Ref AS Ref,
	|	Regions.Code AS Code,
	|	Regions.Description AS Description,
	|	Regions.Abbreviation AS Abbreviation,
	|	Regions.Country AS Country
	|FROM
	|	Catalog.Regions AS Regions
	|WHERE
	|	Regions.Country = &qCountry
	|	AND Regions.DeletionMark = FALSE";
	vQry.SetParameter("qCountry", Russia);
	Return vQry.Execute().Unload();
EndFunction // GetAllRegions

Function GetAbbreviationRef(pAbbreviations, pAbbreviation, pAbbreviationType)
	vAbbreviation = Catalogs.Abbreviations.EmptyRef();
	If pAbbreviations.Count() > 0 Then
		vRows = pAbbreviations.FindRows(New Structure("Abbreviation, AbbreviationType", pAbbreviation, pAbbreviationType));
		For Each vRow In vRows Do
			vAbbreviation = vRow.Ref;
			Break;
		EndDo;
	EndIf;
	Return vAbbreviation;
EndFunction // GetAbbreviationRef

Function RegionMask() Export
	Return 100000000000000000000000;
EndFunction // RegionMask

Function AreaMask() Export
	Return 100000000000000000000;
EndFunction // AreaMask

Function CityMask() Export
	Return 100000000000000;
EndFunction // CityMask

Function StreetMask() Export
	Return 10000000000;
EndFunction // StreetMask

Function HouseMask() Export
	Return 10000000000;
EndFunction // HouseMask

Function FlatMask() Export
	Return 1000000;
EndFunction // FlatMask

Procedure LoadAddressItem(Val pItemCode, Val pDescription, Val pAbbreviation, Val pPostCode, Val pMultiplier, Val pDivider = 1, pFormat2003, 
	                      pAbbreviations, pRegions, pAreas, pCities, pStreets, pIsLoadStreets)
	Russia = Catalogs.Countries.FindByCode(643);					  
	If TrimAll(String(pItemCode)) = "" Then
		Return;
	EndIf;
	If TrimAll(String(pDescription)) = "" Then
		Return;
	EndIf;
	If TrimAll(String(pAbbreviation)) = "" Then
		Return;
	EndIf;

	If Not ValueIsFilled(pPostCode) Then
		pPostCode = "";
	Else
		pPostCode = Format(Number(pPostCode), "ND=6; NFD=0; NZ=; NLZ=; NG=");
		pPostCode = StrReplace(pPostCode, Char(160), "");
	EndIf;
	
	vExternalCode = TrimAll(pItemCode);
	If pFormat2003 And Right(vExternalCode, 2) > "00" Then
		// Old name
		Return;
	EndIf;
	
	pItemCode  = Number(StrReplace(TrimAll(pItemCode), " ", "0"));
	pItemCode = Int(pItemCode / pDivider) * pMultiplier * 100 + pItemCode % pDivider;

	vRegionCode = Format(Int(pItemCode / RegionMask()), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	vAreaCode = Format(Int(pItemCode / AreaMask()) % 1000, "ND=3; NFD=0; NZ=; NLZ=; NG=");
	vCityCode = Format(Int(pItemCode / CityMask()) % 1000000, "ND=6; NFD=0; NZ=; NLZ=; NG=");
	vStreetCode = Format(Int(pItemCode / StreetMask()) % 10000, "ND=4; NFD=0; NZ=; NLZ=; NG=");
	
	If pIsLoadStreets And vStreetCode = "0000" Then
		Return;	
	EndIf;
	
	// Define levels
	vIsStreetLevel = False;
	If vStreetCode > "0000" Then
		vIsStreetLevel = True;
	EndIf;
	
	vIsCityLevel = False;
	If vCityCode > "000000" Then
		vIsCityLevel = True;
	EndIf;
	
	vIsAreaLevel = False;
	If vAreaCode > "000" Then
		vIsAreaLevel = True;
	EndIf;
	
	vIsRegionLevel = False;
	If vRegionCode > "00" Then
		vIsRegionLevel = True;
	EndIf;
	
	// Get objects
	vRegion = GetRegionRef(pRegions, vRegionCode);
	vArea = GetAreaRef(pAreas, vRegion, vAreaCode);
	vCity = GetCityRef(pCities, vRegion, vArea, vCityCode);
	vStreet = GetStreetRef(pStreets, vRegion, vArea, vCity, vStreetCode);
	
	// Load if not found or update
	If vIsStreetLevel Then
		vDoWrite = False;
		If ValueIsFilled(vStreet) Then
			vStreetObj = vStreet.GetObject();
		Else
			vStreetObj = Catalogs.Streets.CreateItem();
			vStreetObj.Code = vStreetCode;
			vDoWrite = True;
		EndIf;
		vDescription = TrimAll(pDescription) + " " + TrimAll(pAbbreviation);
		vAbbreviation = GetAbbreviationRef(pAbbreviations, TrimAll(pAbbreviation), Enums.AbbreviationTypes.Street);
		vPostCode = TrimAll(pPostCode);
		If vDoWrite Then
			vStreetObj.Description = vDescription;
			vStreetObj.Abbreviation = vAbbreviation;
			vStreetObj.PostCode = vPostCode;
			vStreetObj.City = vCity;
			vStreetObj.Area = vArea;
			vStreetObj.Region = vRegion;
			vStreetObj.Country = Russia;
			vStreetObj.ExternalCode = vExternalCode;
			
			vStreetObj.Write();
			
			// Add street to the cache
			vStreetRow = pStreets.Add();
			vStreetRow.Code = vStreetObj.Code;
			vStreetRow.Description = vStreetObj.Description;
			vStreetRow.Abbreviation = vStreetObj.Abbreviation;
			vStreetRow.City = vStreetObj.City;
			vStreetRow.Area = vStreetObj.Area;
			vStreetRow.Region = vStreetObj.Region;
			vStreetRow.Country = vStreetObj.Country;
			vStreetRow.Ref = vStreetObj.Ref;
		Else
			If TrimAll(vStreetObj.Description) <> vDescription Then
				vStreetObj.Description = vDescription;
			EndIf;
			If vStreetObj.Abbreviation <> vAbbreviation Then
				vStreetObj.Abbreviation = vAbbreviation;
			EndIf;
			If TrimAll(vStreetObj.PostCode) <> vPostCode Then
				vStreetObj.PostCode = vPostCode;
			EndIf;
			If vStreetObj.City <> vCity Then
				vStreetObj.City = vCity;
			EndIf;
			If vStreetObj.Area <> vArea Then
				vStreetObj.Area = vArea;
			EndIf;
			If vStreetObj.Region <> vRegion Then
				vStreetObj.Region = vRegion;
			EndIf;
			If vStreetObj.Country <> Russia Then
				vStreetObj.Country = Russia;
			EndIf;
			If TrimAll(vStreetObj.ExternalCode) <> vExternalCode Then
				vStreetObj.ExternalCode = vExternalCode;
			EndIf;
			If vStreetObj.Modified() Then
				vStreetObj.Write();
			EndIf;
		EndIf;
	ElsIf vIsCityLevel Then
		vDoWrite = False;
		If ValueIsFilled(vCity) Then
			vCityObj = vCity.GetObject();
		Else
			vCityObj = Catalogs.Cities.CreateItem();
			vCityObj.Code = vCityCode;
			vDoWrite = True;
		EndIf;
		vDescription = TrimAll(pDescription) + " " + TrimAll(pAbbreviation);
		vAbbreviation = GetAbbreviationRef(pAbbreviations, TrimAll(pAbbreviation), Enums.AbbreviationTypes.City);
		vPostCode = TrimAll(pPostCode);
		If vDoWrite Then
			vCityObj.Description = vDescription;
			vCityObj.Abbreviation = vAbbreviation;
			vCityObj.PostCode = vPostCode;
			vCityObj.Area = vArea;
			vCityObj.Region = vRegion;
			vCityObj.Country = Russia;
			vCityObj.ExternalCode = vExternalCode;
			
			vCityObj.Write();
			
			// Add city to the cache
			vCityRow = pCities.Add();
			vCityRow.Code = vCityObj.Code;
			vCityRow.Description = vCityObj.Description;
			vCityRow.Abbreviation = vCityObj.Abbreviation;
			vCityRow.Area = vCityObj.Area;
			vCityRow.Region = vCityObj.Region;
			vCityRow.Country = vCityObj.Country;
			vCityRow.Ref = vCityObj.Ref;
		Else
			If TrimAll(vCityObj.Description) <> vDescription Then
				vCityObj.Description = vDescription;
			EndIf;
			If vCityObj.Abbreviation <> vAbbreviation Then
				vCityObj.Abbreviation = vAbbreviation;
			EndIf;
			If TrimAll(vCityObj.PostCode) <> vPostCode Then
				vCityObj.PostCode = vPostCode;
			EndIf;
			If vCityObj.Area <> vArea Then
				vCityObj.Area = vArea;
			EndIf;
			If vCityObj.Region <> vRegion Then
				vCityObj.Region = vRegion;
			EndIf;
			If vCityObj.Country <> Russia Then
				vCityObj.Country = Russia;
			EndIf;
			If TrimAll(vCityObj.ExternalCode) <> vExternalCode Then
				vCityObj.ExternalCode = vExternalCode;
			EndIf;
			If vCityObj.Modified() Then
				vCityObj.Write();
			EndIf;
		EndIf;
	ElsIf vIsAreaLevel Then
		vDoWrite = False;
		If ValueIsFilled(vArea) Then
			vAreaObj = vArea.GetObject();
		Else
			vAreaObj = Catalogs.Areas.CreateItem();
			vAreaObj.Code = vAreaCode;
			vDoWrite = True;
		EndIf;
		vDescription = TrimAll(pDescription) + " " + TrimAll(pAbbreviation);
		vAbbreviation = GetAbbreviationRef(pAbbreviations, TrimAll(pAbbreviation), Enums.AbbreviationTypes.Area);
		vPostCode = TrimAll(pPostCode);
		If vDoWrite Then
			vAreaObj.Description = vDescription;
			vAreaObj.Abbreviation = vAbbreviation;
			vAreaObj.PostCode = vPostCode;
			vAreaObj.Region = vRegion;
			vAreaObj.Country = Russia;
			vAreaObj.ExternalCode = vExternalCode;
			
			vAreaObj.Write();
			
			// Add area to the cache
			vAreaRow = pAreas.Add();
			vAreaRow.Code = vAreaObj.Code;
			vAreaRow.Description = vAreaObj.Description;
			vAreaRow.Abbreviation = vAreaObj.Abbreviation;
			vAreaRow.Region = vAreaObj.Region;
			vAreaRow.Country = vAreaObj.Country;
			vAreaRow.Ref = vAreaObj.Ref;
		Else
			If TrimAll(vAreaObj.Description) <> vDescription Then
				vAreaObj.Description = vDescription;
			EndIf;
			If vAreaObj.Abbreviation <> vAbbreviation Then
				vAreaObj.Abbreviation = vAbbreviation;
			EndIf;
			If TrimAll(vAreaObj.PostCode) <> vPostCode Then
				vAreaObj.PostCode = vPostCode;
			EndIf;
			If vAreaObj.Region <> vRegion Then
				vAreaObj.Region = vRegion;
			EndIf;
			If vAreaObj.Country <> Russia Then
				vAreaObj.Country = Russia;
			EndIf;
			If TrimAll(vAreaObj.ExternalCode) <> vExternalCode Then
				vAreaObj.ExternalCode = vExternalCode;
			EndIf;
			If vAreaObj.Modified() Then
				vAreaObj.Write();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // LoadAddressItem

Function GetAreaRef(pAreas, pRegion, pAreaCode)
	vArea = Catalogs.Areas.EmptyRef();
	If pAreas.Count() > 0 Then
		vRows = pAreas.FindRows(New Structure("Region, Code", pRegion, GetFullAreaCode(pAreaCode)));
		For Each vRow In vRows Do
			vArea = vRow.Ref;
			Break;
		EndDo;
	EndIf;
	Return vArea;
EndFunction // GetAreaRef

Function GetCityRef(pCities, pRegion, pArea, pCityCode)
	vCity = Catalogs.Cities.EmptyRef();
	If pCities.Count() > 0 Then
		vRows = pCities.FindRows(New Structure("Region, Area, Code", pRegion, pArea, GetFullCityCode(pCityCode)));
		For Each vRow In vRows Do
			vCity = vRow.Ref;
			Break;
		EndDo;
	EndIf;
	Return vCity;
EndFunction // GetCityRef

Function GetStreetRef(pStreets, pRegion, pArea, pCity, pStreetCode)
	vStreet = Catalogs.Streets.EmptyRef();
	If pStreets.Count() > 0 Then
		vRows = pStreets.FindRows(New Structure("Region, Area, City, Code", pRegion, pArea, pCity, GetFullStreetCode(pStreetCode)));
		For Each vRow In vRows Do
			vStreet = vRow.Ref;
			Break;
		EndDo;
	EndIf;
	Return vStreet;
EndFunction // GetStreetRef

Function GetFullStreetCode(pStreetCode)
	Return pStreetCode + "                  ";
EndFunction // GetFullStreetCode

Function GetRegionRef(pRegions, pRegionCode)
	vRegion = Catalogs.Regions.EmptyRef();
	If pRegions.Count() > 0 Then
		vRows = pRegions.FindRows(New Structure("Code", GetFullRegionCode(pRegionCode)));
		For Each vRow In vRows Do
			vRegion = vRow.Ref;
			Break;
		EndDo;
	EndIf;
	Return vRegion;
EndFunction // GetRegionRef

Function GetRegionAreas(pRegion)
	Russia = Catalogs.Countries.FindByCode(643);
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Areas.Ref,
	|	Areas.Code,
	|	Areas.Description,
	|	Areas.Abbreviation,
	|	Areas.Region,
	|	Areas.Country
	|FROM
	|	Catalog.Areas AS Areas
	|WHERE
	|	Areas.Country = &qCountry
	|	AND Areas.Region = &qRegion
	|	AND Areas.DeletionMark = FALSE";
	vQry.SetParameter("qCountry", Russia);
	vQry.SetParameter("qRegion", pRegion);
	Return vQry.Execute().Unload();
EndFunction // GetRegionAreas

Function GetRegionCities(pRegion)
	Russia = Catalogs.Countries.FindByCode(643);
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Cities.Ref,
	|	Cities.Code,
	|	Cities.Description,
	|	Cities.Abbreviation,
	|	Cities.Area,
	|	Cities.Region,
	|	Cities.Country
	|FROM
	|	Catalog.Cities AS Cities
	|WHERE
	|	Cities.Country = &qCountry
	|	AND Cities.Region = &qRegion
	|	AND Cities.DeletionMark = FALSE";
	vQry.SetParameter("qCountry", Russia);
	vQry.SetParameter("qRegion", pRegion);
	Return vQry.Execute().Unload();
EndFunction // GetRegionCities

Function GetRegionStreets(pRegion)
	Russia = Catalogs.Countries.FindByCode(643);
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Streets.Ref,
	|	Streets.Code,
	|	Streets.Description,
	|	Streets.Abbreviation,
	|	Streets.City,
	|	Streets.Area,
	|	Streets.Region,
	|	Streets.Country
	|FROM
	|	Catalog.Streets AS Streets
	|WHERE
	|	Streets.Country = &qCountry
	|	AND Streets.Region = &qRegion
	|	AND Streets.DeletionMark = FALSE";
	vQry.SetParameter("qCountry", Russia);
	vQry.SetParameter("qRegion", pRegion);
	Return vQry.Execute().Unload();
EndFunction // GetRegionStreets

Function GetFullRegionCode(pRegionCode)
	Return pRegionCode + "          ";
EndFunction // GetFullRegionCode

Function GetFullAreaCode(pAreaCode)
	Return pAreaCode + "         ";
EndFunction // GetFullAreaCode

Function GetFullCityCode(pCityCode)
	Return pCityCode + "                ";
EndFunction // GetFullCityCode

#EndRegion

#Region SMSDelivery

Procedure MessagesDeliverySend(pReceivers, pDeliveryType, pDistributionListId, pAttachmentPath, pIsByCustomers, pSMSTemplate, pSender) Export 
	vClientsList = New ValueList();
	// Processing
	vSMTPConnection = Undefined;
	vLogoff = False;
	vProgress = 0;
	vStep = 100 / pReceivers.Count();
	For vInt = 1 To pReceivers.Count() Do							
		vProgress = vProgress + vStep * (vInt - 1);
		tcCommonFunctionOnClientServer.UserMessage("<progress>" + vProgress + "</progress>");
		vRow = pReceivers.Get(vInt - 1); 
		If vRow.IsSent Then
			Continue;
		EndIf;
		vMessage = "";
		// Show progress for the current phone number
		If pDeliveryType = Enums.DeliveryTypes.SMS Or pDeliveryType = Enums.DeliveryTypes.Both Then
			If IsBlankString(vRow.Phone) Then
				Continue;
			EndIf;
			// Call API
			vResult = "";
			vMessageID = "";
			vCost = 0;
			If SMS.SendMessage(TrimR(vRow.SMSText), TrimAll(vRow.Phone), pSMSTemplate, pSender, ?(pIsByCustomers, vRow.Customer, vRow.Client), vRow.ClientDoc, , , vResult, vMessageID, vCost) Then
				vRow.Result = "";
				vRow.IsSent = True;
				vRow.MessageID = vMessageID;
				vRow.Cost = vCost;
			Else
				vRow.Result = vResult;
				vRow.MessageID = vMessageID;
				vRow.Cost = vCost;
			EndIf;
			vMessage = "LineNumber:" + Format(vInt, "NFD=0; NZ=; NG=") + ";" + 
			           "Result:" + TrimAll(vRow.Result) + ";" +
					   "IsSent:" + ?(vRow.IsSent = True, "True", "False") + ";" +
					   "MessageID:" + Format(vRow.MessageID, "NFD=0; NZ=; NG=") + ";" +
					   "Cost:" + Format(vRow.Cost, "NFD=0; NZ=; NG=");
			tcCommonFunctionOnClientServer.UserMessage("<message>" + vMessage + "</message>");
		EndIf;
		If pDeliveryType = Enums.DeliveryTypes.EMail Or pDeliveryType = Enums.DeliveryTypes.Both Then
			If IsBlankString(vRow.EMail) Then
				Continue;
			EndIf;
			vLanguage = SessionParameters.CurrentLanguage;
			If pIsByCustomers Then
				If ValueIsFilled(vRow.Customer) And ValueIsFilled(vRow.Customer.Language) Then
					vLanguage = vRow.Customer.Language;
				EndIf;
			Else
				If ValueIsFilled(vRow.Client) And ValueIsFilled(vRow.Client.Language) Then
					vLanguage = vRow.Client.Language;
				EndIf;
			EndIf;
			// Call API
			vErrorMessage = "";
			If JobsScheduled.cmSendTextByEMail(cmNStr(TrimAll(pSMSTemplate), vLanguage), TrimR(vRow.SMSText), TrimAll(vRow.EMail), False, vErrorMessage, vSMTPConnection, vLogoff, TrimAll(pAttachmentPath), pSMSTemplate, vRow.ParentDoc, vRow.Client, vRow.AmountStr, vRow.DiscountCard) Then
				vRow.Result = "IsSent";
				vRow.IsSent = True;
				vRow.MessageID = "";
				vRow.Cost = 0;
			Else
				vRow.Result = "UnDeliverable";
				vRow.IsSent = False;
				vRow.MessageID = "";
				vRow.Cost = 0;
			EndIf;
			vMessage = "LineNumber: " + Format(vInt, "NFD=0; NZ=; NG=") + ";" + 
			           "Result: " + TrimAll(vRow.Result) + ";" +
					   "IsSent:" + ?(vRow.IsSent = True,"True","False") + ";" +
					   "MessageID: " + Format(vRow.MessageID, "NFD=0; NZ=; NG=") + ";" +
					   "Cost: " + Format(vRow.Cost, "NFD=0; NZ=; NG=");
			tcCommonFunctionOnClientServer.UserMessage("<message>" + vMessage + "</message>");
		EndIf;
		If pDeliveryType = Enums.DeliveryTypes.Unisender Then
			If IsBlankString(vRow.EMail) And IsBlankString(vRow.Phone) Then
				Continue;
			EndIf;
			If Not ValueIsFilled(vRow.Client) Then
				Continue;
			EndIf;
			If Not IsBlankString(vRow.EMail) And TrimAll(vRow.EMail) <> TrimAll(vRow.Client.EMail) Then
				vClientObj = vRow.Client.GetObject();
				vClientObj.EMail = TrimAll(vRow.EMail);
				vClientObj.Write();
				vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
			If Not IsBlankString(vRow.Phone) And TrimAll(vRow.Phone) <> TrimAll(vRow.Client.Phone) Then
				vClientObj = vRow.Client.GetObject();
				vClientObj.Phone = TrimAll(vRow.Phone);
				vClientObj.Write();
				vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
			vClientsList.Add(vRow.Client);
			If vClientsList.Count() = 20 Then
				vLog = Unisender.ExportClientsList(vClientsList, pDistributionListId);
				vClientsList.Clear();
			EndIf;
			vRow.IsSent = True;	
			vMessage = "LineNumber: " + Format(vInt, "NFD=0; NZ=; NG=") + ";" + 
			           "Result: " + TrimAll(vRow.Result) + ";" +
					  "IsSent:" + ?(vRow.IsSent = True,"True","False") + ";" +
					   "MessageID: " + Format(vRow.MessageID, "NFD=0; NZ=; NG=") + ";" +
					   "Cost: " + Format(vRow.Cost, "NFD=0; NZ=; NG=");
			tcCommonFunctionOnClientServer.UserMessage("<message>" + vMessage + "</message>");
		EndIf;
	EndDo;
	If pDeliveryType = Enums.DeliveryTypes.Unisender Then
		If vClientsList.Count() > 0 Then
			vLog = Unisender.ExportClientsList(vClientsList, pDistributionListId);
		EndIf;
	EndIf;
	If pDeliveryType = Enums.DeliveryTypes.EMail Or pDeliveryType = Enums.DeliveryTypes.Both Then
		If vSMTPConnection <> Undefined Then
			vSMTPConnection.Logoff();
		EndIf;
		vSMTPConnection = Undefined;
	EndIf;
EndProcedure // FormMainActionsFormMainSend

#EndRegion

#Region ScheduledJobsManagementConsole

Procedure ScheduledJobsManagementConsole_GetListBackgroundJob(pAddressStorage, pParameters) Export
	
	vTableProperties = NewPropertiesForBackgroundJob();
	
	vFilter = GetFilterStructure(pParameters);
	
	vBackgroundJobs = BackgroundJobs.GetBackgroundJobs(vFilter);
	
	For Each vRow_BackgroundJob In vBackgroundJobs Do
		
		If vRow_BackgroundJob.MethodName = "ProlongedOperations.ScheduledJobsManagementConsole_GetListBackgroundJob"
			Or vRow_BackgroundJob.MethodName = "ProlongedOperations.ScheduledJobsManagementConsole_GetListGetListScheduledJobs"
			Or vRow_BackgroundJob.MethodName = "JobsScheduled.cmExecuteIntegrationServiceProcessing"
			Or vRow_BackgroundJob.MethodName = "JobsScheduled.cmExchangePlanDataProcessing"
			Or vRow_BackgroundJob.MethodName = ""
			Or vRow_BackgroundJob.MethodName = Undefined Then
			Continue;	
		EndIf;
		
		vUpdate = vTableProperties.Add();
		
		FillPropertyValues(vUpdate, vRow_BackgroundJob);

		If Not ValueIsFilled(vUpdate.Description) Then
			vUpdate.Description = TrimAll(vRow_BackgroundJob.ScheduledJob.Metadata) 	
		EndIf;	
		
		If vRow_BackgroundJob.ErrorInfo <> Undefined Then
			vUpdate.ErrorInfo = vRow_BackgroundJob.ErrorInfo.Description; 
		EndIf;
		
		If vRow_BackgroundJob.ScheduledJob <> Undefined Then
			vUpdate.ScheduledJobID 			= vRow_BackgroundJob.ScheduledJob.UUID;
			vUpdate.ScheduledJobDescription = vRow_BackgroundJob.ScheduledJob.Description;
			If  ValueIsFilled(vRow_BackgroundJob.ScheduledJob.Description) Then
				vUpdate.ScheduledJobDescription = vRow_BackgroundJob.ScheduledJob.Description;
			Else
				vUpdate.ScheduledJobDescription = TrimAll(vRow_BackgroundJob.ScheduledJob.Metadata) 	
			EndIf;
		ElsIf ValueIsFilled(vRow_BackgroundJob.Key) Then
			Try
				vScheduledJob = ScheduledJobs.FindByUUID(New UUID(vRow_BackgroundJob.Key));
			Except
				vScheduledJob = Undefined;
			EndTry;			
			If vScheduledJob <> Undefined Then
				vUpdate.ScheduledJobID 			= vScheduledJob.UUID;
				If  ValueIsFilled(vScheduledJob.Description) Then
					vUpdate.ScheduledJobDescription = vScheduledJob.Description;
				Else
					vUpdate.ScheduledJobDescription = TrimAll(vScheduledJob.Metadata) 	
				EndIf;		
			EndIf;
		EndIf;
		
		
		vBackgroundJobMessages = AsyncCalls.GetBackgroundJobUserMessages(vRow_BackgroundJob);
		vUpdate.UserMessages = "";
		For Each vMsg In vBackgroundJobMessages Do
			vUpdate.UserMessages = vUpdate.UserMessages + vMsg + Chars.LF;	
		EndDo;
	EndDo;
		
	PutToTempStorage(vTableProperties, pAddressStorage);
EndProcedure // ScheduledJobsManagementConsole_GetListBackgroundJob

Function NewPropertiesForBackgroundJob()	
	
	vNewTable = New ValueTable();
	vNewTable.Columns.Add("Description",                New TypeDescription("String"));
	vNewTable.Columns.Add("Begin",                     	New TypeDescription("Date"));
	vNewTable.Columns.Add("End",                        New TypeDescription("Date"));
	vNewTable.Columns.Add("State",                      New TypeDescription("String"));
	vNewTable.Columns.Add("Location",                   New TypeDescription("String"));
	vNewTable.Columns.Add("ErrorInfo", 					New TypeDescription("String"));
	vNewTable.Columns.Add("UUID",                       New TypeDescription("UUID"));
	vNewTable.Columns.Add("Key",                        New TypeDescription("String"));
	vNewTable.Columns.Add("MethodName",                 New TypeDescription("String"));
	vNewTable.Columns.Add("ScheduledJobID",        		New TypeDescription("String"));
	vNewTable.Columns.Add("ScheduledJobDescription",	New TypeDescription("String"));
	vNewTable.Columns.Add("UserMessages",             	New TypeDescription("String"));
	
	Return vNewTable;
EndFunction // NewPropertiesForBackgroundJob  

Function GetFilterStructure(pParameters)
	vFilter = New Structure;
	vStateArray = New Array;
	
	If pParameters.FilterByActiveState Then 
		vStateArray.Add(BackgroundJobState.Active);
	EndIf;
	
	If pParameters.FilterByCompletedState Then 
		vStateArray.Add(BackgroundJobState.Completed);
	EndIf;
	
	If pParameters.FilterByFailedState Then 
		vStateArray.Add(BackgroundJobState.Failed);
	EndIf;
	
	If pParameters.FilterByCanceledState Then 
		vStateArray.Add(BackgroundJobState.Canceled);
	EndIf;
	
	If vStateArray.Count() <> 4 Then
		If vStateArray.Count() = 1 Then
			vFilter.Insert("State", vStateArray[0]);
		Else
			vFilter.Insert("State", vStateArray);
		EndIf;
	EndIf;
	
	If pParameters.FilterKindByPeriod <> 0 Then
		vFilter.Insert("Begin", pParameters.FilterPeriodFrom);
		vFilter.Insert("End",   pParameters.FilterPeriodTo);
	EndIf;
	
	Return vFilter; 
EndFunction // GetFilterStructure

Procedure ScheduledJobsManagementConsole_GetListGetListScheduledJobs(pAddressStorage) Export 
	
	vTableProperties = NewPropertiesForScheduledJob();
	vScheduledJobs = ScheduledJobs.GetScheduledJobs();

	For Each vRow_ScheduledJob In vScheduledJobs Do		
		vUpdate = vTableProperties.Add();	
		FillPropertyValues(vUpdate, vRow_ScheduledJob);
		
		If Not ValueIsFilled(vRow_ScheduledJob.Description) Then
			vUpdate.Description = TrimAll(vRow_ScheduledJob.Metadata) 	
		EndIf;
		
		If vRow_ScheduledJob.Predefined Then
			vUpdate.PredefinedPic = 11;	
		Else
			vUpdate.PredefinedPic = 7;	
		EndIf;
		vBackgroundJobs = BackgroundJobs.GetBackgroundJobs(New Structure("Key", vRow_ScheduledJob.UUID));
		If vRow_ScheduledJob.LastJob <> Undefined Then
			vUpdate.StartDate = vRow_ScheduledJob.LastJob.Begin;
			vUpdate.EndDate = vRow_ScheduledJob.LastJob.End;
			vUpdate.State = vRow_ScheduledJob.LastJob.State;
			vUpdate.LastJobUUID = vRow_ScheduledJob.LastJob.UUID;
		EndIf;
		
		If vBackgroundJobs.Count() > 0 Then
			vJob = vBackgroundJobs.Get(0);
			If vRow_ScheduledJob.LastJob <> Undefined Then
				If vRow_ScheduledJob.LastJob <> vJob Then
					If vRow_ScheduledJob.LastJob.Begin <= vJob.Begin Then
						vUpdate.StartDate = vJob.Begin;
						vUpdate.EndDate = vJob.End;
						vUpdate.State = vJob.State;
						vUpdate.LastJobUUID = vJob.UUID;
					EndIf;
				EndIf;
			Else
				vUpdate.StartDate = vJob.Begin;
				vUpdate.EndDate = vJob.End;
				vUpdate.State = vJob.State;
				vUpdate.LastJobUUID = vJob.UUID;
			EndIf;
		EndIf;
	EndDo;
	vTableProperties.Sort("Predefined Desc, Description");
	PutToTempStorage(vTableProperties, pAddressStorage);
EndProcedure // ScheduledJobsManagementConsole_GetListGetListScheduledJobs

Function NewPropertiesForScheduledJob()		
	vNewTable = New ValueTable();
	
	vNewTable.Columns.Add("UUID",                       New TypeDescription("UUID"));
	vNewTable.Columns.Add("LastJobUUID",                New TypeDescription("UUID"));
	vNewTable.Columns.Add("Predefined",					New TypeDescription("Boolean"));
	vNewTable.Columns.Add("Key",                        New TypeDescription("String"));
	vNewTable.Columns.Add("Description",                New TypeDescription("String"));
	vNewTable.Columns.Add("Use",						New TypeDescription("Boolean"));
	vNewTable.Columns.Add("Schedule",					New TypeDescription("String"));
	vNewTable.Columns.Add("StartDate",                  New TypeDescription("Date"));
	vNewTable.Columns.Add("EndDate",                    New TypeDescription("Date"));
	vNewTable.Columns.Add("State",                      New TypeDescription("String"));
	vNewTable.Columns.Add("PredefinedPic",              New TypeDescription("Number"));
	vNewTable.Columns.Add("UserName",                   New TypeDescription("String"));
		
	Return vNewTable;
EndFunction // NewPropertiesForScheduledJob

#EndRegion

#Region ISD 

Procedure GetISDNewKey(pInteractionParameters, pAction, pAccommodationRef, pKeyParams, pAddressStorage) Export 
		
	vResult = ISD.IssueCard(pInteractionParameters, pAction, pAccommodationRef, pKeyParams);	
	
	PutToTempStorage(vResult, pAddressStorage);
		
EndProcedure
	
#EndRegion

#Region FindRoomRates

// -----------------------------------------------------------------------------
&AtServer
Procedure FindRoomRates_BuildRoomTypesListDaily(pTempStorageAddress, pHotel, pRoomQuota, pCheckInDate, pCheckOutDate, pRoomRate, pRoomRatesList, pClientType, pWindowView, pCustomer, pContract, pCUCustomer, pNumberOfAdults, pNumberOfKids, pAgeArray) Export
	// Build structure with children ages
	vChildrenAgesStruct = Undefined;
	If ValueIsFilled(pRoomQuota) And ValueIsFilled(pRoomQuota.Contract) Then
		vAllotmentContract = pRoomQuota.Contract;
		If vAllotmentContract.TeenagersMaxAge <> 0 Or vAllotmentContract.ChildrenMaxAge <> 0 Or vAllotmentContract.InfantsMaxAge <> 0 Then
			vChildrenAgesStruct = vAllotmentContract;
		EndIf;
	EndIf;
	
	// Get active special offers
	If ValueIsFilled(pHotel) And (pHotel.TeenagersMaxAge <> 0 Or pHotel.ChildrenMaxAge <> 0 Or pHotel.InfantsMaxAge <> 0) Then
		If ValueIsFilled(pRoomRate) Then
			vDuration = (BegOfDay(pCheckOutDate) - BegOfDay(pCheckInDate)) / (24 * 3600);
			vOffers = cmGetConfirmedSpecialOffersForReservation(Undefined, pHotel, pRoomRate, pRoomRate.RoomRateType, Undefined, pClientType, pCustomer, ?(ValueIsFilled(pCustomer), pCustomer.CustomerType, Undefined), Undefined, Undefined, Undefined, Undefined, pCheckInDate, vDuration, pCheckOutDate, CurrentSessionDate(), Undefined);
			For Each vOffersRow In vOffers Do
				vOffer = vOffersRow.SpecialOffer;
				If vOffer.TeenagersMaxAge <> 0 Or vOffer.ChildrenMaxAge <> 0 Or vOffer.InfantsMaxAge <> 0 Then
					vChildrenAgesStruct = vOffer;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Get available room types
	vGuestsQuantity = pNumberOfAdults + pNumberOfKids;
	vRoomTypes = cmGetRoomTypesByGuestQuantity(vGuestsQuantity, Catalogs.RoomTypes.EmptyRef(), pHotel);
	
	vShiftInSeconds = ?(ValueIsFilled(pRoomRate), -(pRoomRate.ReferenceHour - BegOfDay(pRoomRate.ReferenceHour)), -43200);
	
	// Build and run query with daily room inventory balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BEGINOFPERIOD(ExpectedGuestGroupsTurnovers.Period, DAY) AS Period,
	|	ExpectedGuestGroupsTurnovers.Hotel AS Hotel,
	|	ExpectedGuestGroupsTurnovers.RoomType AS RoomType,
	|	MAX(ISNULL(ExpectedGuestGroupsTurnovers.RoomsReservedTurnover, 0)) AS PreliminaryRooms,
	|	MAX(ISNULL(ExpectedGuestGroupsTurnovers.BedsReservedTurnover, 0)) AS PreliminaryBeds
	|INTO PreliminaryTotalsByDays
	|FROM
	|	AccumulationRegister.ExpectedGuestGroups.Turnovers(
	|			&qTentativeDateTimeFrom,
	|			&qTentativeDateTimeTo,
	|			DAY,
	|			(Hotel = &qHotel
	|				OR &qHotelIsEmpty)
	|				AND RoomType IN (&qRoomTypesList)
	|				AND CASE
	|					WHEN RoomQuota = VALUE(Catalog.RoomQuotas.EmptyRef)
	|						THEN TRUE
	|					WHEN GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|						THEN TRUE
	|					WHEN NOT ISNULL(RoomQuota.DoWriteOff, FALSE)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|				AND (&qRoomQuotaIsSet
	|						AND RoomQuota = &qRoomQuota
	|					OR NOT &qRoomQuotaIsSet)) AS ExpectedGuestGroupsTurnovers
	|
	|GROUP BY
	|	BEGINOFPERIOD(ExpectedGuestGroupsTurnovers.Period, DAY),
	|	ExpectedGuestGroupsTurnovers.Hotel,
	|	ExpectedGuestGroupsTurnovers.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalance.Period, SECOND, &qShiftInSeconds), DAY) AS Period,
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	MAX(RoomInventoryBalance.CounterClosingBalance) AS CounterClosingBalance,
	|	MIN(ISNULL(RoomInventoryBalance.RoomsVacantClosingBalance, 0)) AS RoomsVacant,
	|	MIN(ISNULL(RoomInventoryBalance.BedsVacantClosingBalance, 0)) AS BedsVacant
	|INTO RoomInventoryBalanceByDays
	|FROM
	|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|			&qDateTimeFrom,
	|			&qDateTimeTo,
	|			Minute,
	|			RegisterRecordsAndPeriodBoundaries,
	|			&qHotelIsEmpty
	|				OR Hotel IN HIERARCHY (&qHotel)
	|					AND RoomType IN (&qRoomTypesList)) AS RoomInventoryBalance
	|
	|GROUP BY
	|	BEGINOFPERIOD(DATEADD(RoomInventoryBalance.Period, SECOND, &qShiftInSeconds), DAY),
	|	RoomInventoryBalance.Hotel,
	|	RoomInventoryBalance.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(RoomQuotaSalesBalance.Period, DAY) AS Period,
	|	RoomQuotaSalesBalance.Hotel AS Hotel,
	|	RoomQuotaSalesBalance.RoomType AS RoomType,
	|	RoomQuotaSalesBalance.CounterClosingBalance AS CounterClosingBalance,
	|	RoomQuotaSalesBalance.RoomsInQuotaClosingBalance AS RoomsInQuota,
	|	RoomQuotaSalesBalance.BedsInQuotaClosingBalance AS BedsInQuota,
	|	RoomQuotaSalesBalance.RoomsRemainsClosingBalance AS RoomsRemains,
	|	RoomQuotaSalesBalance.BedsRemainsClosingBalance AS BedsRemains
	|INTO RoomQuotaBalanceByDays
	|FROM
	|	AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|			&qDateTimeFrom,
	|			&qDateTimeTo,
	|			Day,
	|			RegisterRecordsAndPeriodBoundaries,
	|			(&qHotelIsEmpty
	|				OR Hotel = &qHotel)
	|				AND RoomType IN (&qRoomTypesList)
	|				AND &qRoomQuotaIsSet
	|				AND RoomQuota = &qRoomQuota) AS RoomQuotaSalesBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalanceByDays.Period AS Period,
	|	RoomInventoryBalanceByDays.Hotel AS Hotel,
	|	RoomInventoryBalanceByDays.RoomType AS RoomType,
	|	CASE
	|		WHEN &qRoomQuotaIsSet
	|				AND &qDoWriteOff
	|			THEN ISNULL(RoomQuotaBalanceByDays.RoomsRemains, 0)
	|		WHEN &qRoomQuotaIsSet
	|				AND NOT &qDoWriteOff
	|				AND ISNULL(RoomInventoryBalanceByDays.RoomsVacant, 0) < ISNULL(RoomQuotaBalanceByDays.RoomsRemains, 0)
	|			THEN ISNULL(RoomInventoryBalanceByDays.RoomsVacant, 0)
	|		WHEN &qRoomQuotaIsSet
	|				AND NOT &qDoWriteOff
	|				AND ISNULL(RoomInventoryBalanceByDays.RoomsVacant, 0) >= ISNULL(RoomQuotaBalanceByDays.RoomsRemains, 0)
	|			THEN ISNULL(RoomQuotaBalanceByDays.RoomsRemains, 0)
	|		ELSE ISNULL(RoomInventoryBalanceByDays.RoomsVacant, 0)
	|	END AS RoomsVacant,
	|	CASE
	|		WHEN &qRoomQuotaIsSet
	|				AND &qDoWriteOff
	|			THEN ISNULL(RoomQuotaBalanceByDays.BedsRemains, 0)
	|		WHEN &qRoomQuotaIsSet
	|				AND NOT &qDoWriteOff
	|				AND ISNULL(RoomInventoryBalanceByDays.BedsVacant, 0) < ISNULL(RoomQuotaBalanceByDays.BedsRemains, 0)
	|			THEN ISNULL(RoomInventoryBalanceByDays.BedsVacant, 0)
	|		WHEN &qRoomQuotaIsSet
	|				AND NOT &qDoWriteOff
	|				AND ISNULL(RoomInventoryBalanceByDays.BedsVacant, 0) >= ISNULL(RoomQuotaBalanceByDays.BedsRemains, 0)
	|			THEN ISNULL(RoomQuotaBalanceByDays.BedsRemains, 0)
	|		ELSE ISNULL(RoomInventoryBalanceByDays.BedsVacant, 0)
	|	END AS BedsVacant
	|INTO RoomTypesBalanceByDays
	|FROM
	|	RoomInventoryBalanceByDays AS RoomInventoryBalanceByDays
	|		LEFT JOIN RoomQuotaBalanceByDays AS RoomQuotaBalanceByDays
	|		ON RoomInventoryBalanceByDays.Hotel = RoomQuotaBalanceByDays.Hotel
	|			AND RoomInventoryBalanceByDays.RoomType = RoomQuotaBalanceByDays.RoomType
	|			AND RoomInventoryBalanceByDays.Period = RoomQuotaBalanceByDays.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventoryBalance.Period AS Period,
	|	RoomInventoryBalance.Hotel AS Hotel,
	|	RoomInventoryBalance.RoomType AS RoomType,
	|	RoomInventoryBalance.RoomsVacant AS RoomsVacant,
	|	RoomInventoryBalance.BedsVacant AS BedsVacant,
	|	ISNULL(PreliminaryTotals.PreliminaryRooms, 0) AS TentativeRooms,
	|	ISNULL(PreliminaryTotals.PreliminaryBeds, 0) AS TentativeBeds,
	|	RoomInventoryBalance.RoomsVacant - ISNULL(PreliminaryTotals.PreliminaryRooms, 0) AS RoomsAvailableWithTentative,
	|	RoomInventoryBalance.BedsVacant - ISNULL(PreliminaryTotals.PreliminaryBeds, 0) AS BedsAvailableWithTentative
	|INTO RoomInventoryBalanceWithTentative
	|FROM
	|	RoomTypesBalanceByDays AS RoomInventoryBalance
	|		LEFT JOIN PreliminaryTotalsByDays AS PreliminaryTotals
	|		ON RoomInventoryBalance.Period = PreliminaryTotals.Period
	|			AND RoomInventoryBalance.Hotel = PreliminaryTotals.Hotel
	|			AND RoomInventoryBalance.RoomType = PreliminaryTotals.RoomType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.Period AS AccountingDate,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.RoomsVacant AS RoomsVacant,
	|	RoomInventory.BedsVacant AS BedsVacant,
	|	RoomInventory.TentativeRooms AS TentativeRooms,
	|	RoomInventory.TentativeBeds AS TentativeBeds,
	|	RoomInventory.RoomsAvailableWithTentative AS RoomsAvailableWithTentative,
	|	RoomInventory.BedsAvailableWithTentative AS BedsAvailableWithTentative
	|FROM
	|	(SELECT
	|		RoomInventoryBalanceWithTentative.Period AS Period,
	|		RoomInventoryBalanceWithTentative.Hotel AS Hotel,
	|		RoomInventoryBalanceWithTentative.RoomType AS RoomType,
	|		RoomInventoryBalanceWithTentative.RoomsVacant AS RoomsVacant,
	|		RoomInventoryBalanceWithTentative.BedsVacant AS BedsVacant,
	|		RoomInventoryBalanceWithTentative.TentativeRooms AS TentativeRooms,
	|		RoomInventoryBalanceWithTentative.TentativeBeds AS TentativeBeds,
	|		RoomInventoryBalanceWithTentative.RoomsAvailableWithTentative AS RoomsAvailableWithTentative,
	|		RoomInventoryBalanceWithTentative.BedsAvailableWithTentative AS BedsAvailableWithTentative
	|	FROM
	|		RoomInventoryBalanceWithTentative AS RoomInventoryBalanceWithTentative
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DailyPeriods.Period,
	|		VirtualRoomTypes.Owner,
	|		VirtualRoomTypes.Ref,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		Catalog.RoomTypes AS VirtualRoomTypes
	|			LEFT JOIN (SELECT
	|				BEGINOFPERIOD(RoomInventoryMarkup.Period, DAY) AS Period,
	|				RoomInventoryMarkup.CounterClosingBalance AS CounterClosingBalance
	|			FROM
	|				AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|						&qDateTimeFrom,
	|						&qDateTimeTo,
	|						DAY,
	|						RegisterRecordsAndPeriodBoundaries,
	|						&qHotelIsEmpty
	|							OR Hotel IN HIERARCHY (&qHotel)) AS RoomInventoryMarkup) AS DailyPeriods
	|			ON (TRUE)
	|	WHERE
	|		VirtualRoomTypes.IsVirtual
	|		AND NOT VirtualRoomTypes.IsFolder
	|		AND (&qHotelIsEmpty
	|				OR VirtualRoomTypes.Owner IN HIERARCHY (&qHotel))) AS RoomInventory
	|WHERE
	|	NOT RoomInventory.RoomType.DeletionMark
	|	AND (NOT &qWindowViewIsFilled
	|			OR &qWindowViewIsFilled
	|				AND RoomInventory.RoomType.WindowView = &qWindowView)
	|	AND CASE
	|			WHEN &qCUCustomer <> VALUE(Catalog.Customers.EmptyRef)
	|				THEN RoomInventory.RoomsVacant <> 0
	|						AND RoomInventory.BedsVacant <> 0
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	RoomInventory.Period,
	|	RoomInventory.RoomType.SortCode"; 
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qRoomQuota", pRoomQuota);
	vQry.SetParameter("qRoomQuotaIsSet", ValueIsFilled(pRoomQuota));
	vQry.SetParameter("qDoWriteOff", ?(ValueIsFilled(pRoomQuota), pRoomQuota.DoWriteOff, False));
	vQry.SetParameter("qDateTimeFrom", cm1SecondShift(pCheckInDate));
	vQry.SetParameter("qDateTimeTo", cm0SecondShift(pCheckOutDate));
	vQry.SetParameter("qTentativeDateTimeFrom", BegOfDay(pCheckInDate));
	vQry.SetParameter("qTentativeDateTimeTo", EndOfDay(pCheckOutDate) - 24 * 3600);
	vQry.SetParameter("qRoomTypesList", vRoomTypes.UnloadColumn("RoomType"));
	vQry.SetParameter("qEmptyNumber", 0);
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vQry.SetParameter("qWindowViewIsFilled", ValueIsFilled(pWindowView));
	vQry.SetParameter("qWindowView", pWindowView);
	vQry.SetParameter("qCUCustomer", pCUCustomer);
	vQry.SetParameter("qShiftInSeconds", vShiftInSeconds);
	vRoomTypesBalancesDaily = vQry.Execute().Unload();
	
	vRoomTypesList = vRoomTypesBalancesDaily.Copy(, "RoomType");
	vRoomTypesList.GroupBy("RoomType", );
	
	// Create table with prices
	vRoomTypesPricesDaily = New ValueTable();
	vRoomTypesPricesDaily.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vRoomTypesPricesDaily.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vRoomTypesPricesDaily.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vRoomTypesPricesDaily.Columns.Add("Currency", cmGetCatalogTypeDescription("Currencies"));
	vRoomTypesPricesDaily.Columns.Add("RoomPrice", cmGetSumTypeDescription());
	
	// Get room type prices for default room rate and other room rates available for the given guest 
	If ValueIsFilled(pRoomRate) Then
		// Force current room rate be the first in the list
		vRoomRateItem = pRoomRatesList.FindByValue(pRoomRate);
		If vRoomRateItem <> Undefined Then
			pRoomRatesList.Delete(vRoomRateItem);
		EndIf;
		pRoomRatesList.Insert(0, pRoomRate);
		
		// Process room rates with price cache filled only 
		If cmRoomRatePricesCacheIsFilled(pHotel, pRoomRatesList, pClientType, pCheckInDate, pCheckOutDate) Then
			// Get accommodation templates suitable for each room rate / room type
			vAccTemplates = cmGetAccommodationTemplateDetailsByGuestsQuantity(pNumberOfAdults, pNumberOfKids, pAgeArray, pHotel, True, vChildrenAgesStruct);
			vAccTemplatesList = New ValueList();
			vAccTemplatesList.LoadValues(vAccTemplates.UnloadColumn("AccommodationTemplate"));
			
			// Get prices for each suitable template
			vPrices = cmGetCachedPricesForPriceTagsByDays(pHotel, pClientType, BegOfDay(pCheckInDate), BegOfDay(pCheckOutDate), pRoomRatesList, vAccTemplatesList);
			
			vInt = 0;
			While vInt < Min(pRoomRatesList.Count(), 10) Do
				vRoomRate = pRoomRatesList.Get(vInt).Value;
			
				// Check room rate is valid period
				If ValueIsFilled(vRoomRate.DateValidFrom) Or ValueIsFilled(vRoomRate.DateValidTo) Then
					If ValueIsFilled(vRoomRate.DateValidFrom) And pCheckInDate < vRoomRate.DateValidFrom Then
						vInt = vInt + 1;
						Continue;
					EndIf;
					If ValueIsFilled(vRoomRate.DateValidTo) And pCheckOutDate > EndOfDay(vRoomRate.DateValidTo) Then
						vInt = vInt + 1;
						Continue;
					EndIf;
				EndIf;
				
				vCurAccommodationTemplate = Undefined;
				vRoomTypesToSkip = New ValueList();
			
				For Each vRoomTypesRow In vRoomTypesList Do
					vCurRoomType = vRoomTypesRow.RoomType;
					
					// Check room rate restrictions
					If vRoomTypesToSkip.FindByValue(vCurRoomType) <> Undefined Then
						vCurRoomType = Undefined;
						Continue;
					EndIf;
					If Not cmCheckRoomRateRestrictions(pHotel, vRoomRate, vCurRoomType, cm1SecondShift(pCheckInDate), cm0SecondShift(pCheckOutDate), cmCalculateDuration(vRoomRate, cm1SecondShift(pCheckInDate), cm0SecondShift(pCheckOutDate))) Then
						vRoomTypesToSkip.Add(vCurRoomType);
						vCurRoomType = Undefined;
						Continue;
					EndIf;
					
					// Get prices for current room rate and room type
					vRoomRateRoomTypePrices = vPrices.FindRows(New Structure("RoomRate, RoomType", vRoomRate, vCurRoomType));
					If vRoomRateRoomTypePrices <> Undefined And vRoomRateRoomTypePrices.Count() > 0 Then
						vCurAccommodationTemplate = Undefined;
						vCurrency = Catalogs.Currencies.EmptyRef();
						For Each vRoomRateRoomTypePricesRow In vRoomRateRoomTypePrices Do
							vWrkAccommodationTemplate = vRoomRateRoomTypePricesRow.AccommodationTemplate;
							If ValueIsFilled(vWrkAccommodationTemplate) Then
								If vWrkAccommodationTemplate.RoomTypes.Count() <> 0 And vWrkAccommodationTemplate.RoomTypes.Find(vCurRoomType, "RoomType") = Undefined Then
									vDoContinue = True;
									If ValueIsFilled(vCurRoomType) And Not vCurRoomType.IsFolder And ValueIsFilled(vCurRoomType.RoomClass) And vWrkAccommodationTemplate.RoomTypes.Find(vCurRoomType.RoomClass, "RoomClass") <> Undefined Then
										vDoContinue = False;
									EndIf;
									If vDoContinue Then
										Continue;
									EndIf;
								EndIf;
							EndIf;
							If ValueIsFilled(vCurAccommodationTemplate) And vCurAccommodationTemplate <> vWrkAccommodationTemplate Then
								Continue;
							EndIf;
							If Not ValueIsFilled(vCurAccommodationTemplate) And ValueIsFilled(vWrkAccommodationTemplate) Then
								vCurAccommodationTemplate = vWrkAccommodationTemplate;
								If Not ValueIsFilled(vCurrency) Then
									vCurrency = vRoomRateRoomTypePricesRow.Currency;
								EndIf;
							EndIf;
							If ValueIsFilled(vCurAccommodationTemplate) And vCurAccommodationTemplate = vWrkAccommodationTemplate Then
								vDailyPriceRows = vRoomTypesPricesDaily.FindRows(New Structure("AccountingDate, RoomRate, RoomType", vRoomRateRoomTypePricesRow.Period, vRoomRate, vCurRoomType));
								If vDailyPriceRows.Count() > 0 Then
									vDailyPriceRow = vDailyPriceRows.Get(0);
								Else
									vDailyPriceRow = vRoomTypesPricesDaily.Add();
								EndIf;
								vDailyPriceRow.AccountingDate = vRoomRateRoomTypePricesRow.Period;
								vDailyPriceRow.RoomRate = vRoomRate;
								vDailyPriceRow.RoomType = vCurRoomType;
								vDailyPriceRow.Currency = vCurrency;
								vDailyPriceRow.RoomPrice = vDailyPriceRow.RoomPrice + vRoomRateRoomTypePricesRow.Amount;
							EndIf;
						EndDo; // By prices
					EndIf; // Room rate/Room type prices found
				EndDo; // By room types
				vInt = vInt + 1;
			EndDo; // By room rates	
		EndIf; // Prices cache is filled
	EndIf; // Room rate is filled
	
	vReturnStruct = New Structure("RoomTypesBalancesDaily, RoomTypesPricesDaily", vRoomTypesBalancesDaily, vRoomTypesPricesDaily);
	PutToTempStorage(vReturnStruct, pTempStorageAddress);
EndProcedure // BuildRoomTypesListDaily

#EndRegion 

#Region GetListTransactions

// --------------------------------------------------------------------------------
Procedure GetListTransactionsFromExternalSystem(pAddressStorage, pDiscountCard, pExternalSystem) Export 
	If pExternalSystem.IntegrationType = Enums.Integrations.ISD Then
		vDPO = ISD;	        
		vKeyParams = New Structure;   
		vKeyParams.Insert("media_num", pDiscountCard.Identifier);
		vKeyParams.Insert("pointsale", ISD.GetPSALID(pExternalSystem));
		vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
		vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
		vKeyParams.Insert("User", String(SessionParameters.CurrentUser));

		vDPO.GetBonusesTransactions(pExternalSystem, vKeyParams, pAddressStorage)
	Else	
		vDP = pExternalSystem.DataProcessor;
		If Not ValueIsFilled(vDP) Then
			tcCommonFunctionOnClientServer.UserMessage(Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'"));
			Return;
		EndIf;
		vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
		If vDPO = Undefined Then
			tcCommonFunctionOnClientServer.UserMessage(Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработчик'"));
			Return;
		EndIf;
		vDPO.GetBonusesTransactions(pDiscountCard, pAddressStorage)
	EndIf; 
EndProcedure // GetListTransactionsFromExternalSystem

#EndRegion

#Region ClearKLADRAndFIAS

Procedure ClearKLADRAndFIAS() Export
	ClearCatalogByCatalogMetadata(Metadata.Catalogs.Streets);
	
	ClearCatalogByCatalogMetadata(Metadata.Catalogs.Cities);
	
	ClearCatalogByCatalogMetadata(Metadata.Catalogs.Areas);
	
	ClearCatalogByCatalogMetadata(Metadata.Catalogs.Regions, True);	
EndProcedure // ClearKLADRAndFIAS

Procedure ClearCatalogByCatalogMetadata(pMetadata, pCheckRef = False)
	// Do in transaction
	Try
		vCount = 0;
		vElementsCount = GetCountElementsByCatalogName(pMetadata.Name);
		tcCommonFunctionOnClientServer.UserMessage("<message>" + StrTemplate(NStr("en = 'Removing [%1]: %2 from %3 elements'; de = 'Entfernen von [%1]: %2 aus %3 Elementen'; ru = 'Удаление [%1]: %2 из %3 элементов'"), pMetadata.Synonym, vCount, vElementsCount) + "</message>");
		BeginTransaction(DataLockControlMode.Managed);
		vSelect = Catalogs[pMetadata.Name].Select();
		While vSelect.Next() Do 
			vNotNext = True;
			If pCheckRef Then
				vRefArr = New Array();
				vRefArr.Add(vSelect.Ref);
				vNotNext = FindByRef(vRefArr).Count() = 0;
			EndIf;
			If vNotNext Then
				vSelect.GetObject().Delete();
				vCount = vCount + 1;
			EndIf;  
			// Commit each 1000 records
			If vCount / 1000 = Int(vCount / 1000) Then
				tcCommonFunctionOnClientServer.UserMessage("<message>" + StrTemplate(NStr("en = 'Removing [%1]: %2 from %3 elements'; de = 'Entfernen von [%1]: %2 aus %3 Elementen'; ru = 'Удаление [%1]: %2 из %3 элементов'"), pMetadata.Synonym, vCount, vElementsCount) + "</message>");
				CommitTransaction();
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;	
		EndDo;
		CommitTransaction();
	Except
		vMessage = ErrorDescription();
		WriteLogEvent(NStr("en='DataProcessor.ClearKLADRAndFIAS';ru='Обработка.КЛАДРиФИАС';de='DataProcessor.ClearKLADRAndFIAS'"), EventLogLevel.Error, Metadata.DataProcessors.ClearKLADRAndFIAS, Undefined, vMessage);
		If TransactionActive() Then
			RollbackTransaction();
		Endif;
	EndTry;	
EndProcedure // ClearCatalogByCatalogMetadata

Function GetCountElementsByCatalogName(pCatalogName)
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	COUNT(" + pCatalogName + ".Ref) AS Count
	|FROM
	|	Catalog." + pCatalogName + " AS " + pCatalogName;
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		Return vResult[0].Count;	
	Else
		Return 0;
	EndIf;
EndFunction // GetCountElementsByСatalog

#EndRegion 

#Region RTK 
                      
Procedure RTKBackgroundJobRequest(pName, pHotel, pParameters) Export 
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	Try
		vInteractionParametersRows = cmGetInteractionByID("RTK", False); 	
		If vInteractionParametersRows.Count() > 0 Then
			vInteractionParameters = vInteractionParametersRows[0].Ref; 	
		EndIf;
		If ValueIsFilled(vInteractionParameters) Then
			vDataProcessors = vInteractionParameters.DataProcessor;	
			If ValueIsFilled(vDataProcessors) Then
				vObjDataProcessors = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDataProcessors, True);
				If vObjDataProcessors <> Undefined Then
					vObjDataProcessors.pmBackgroundJobRequest(pName, pHotel, pParameters);
				Else
					vMessage = Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'"); 
					WriteLogEvent("RTK.pmBackgroundJobRequest", EventLogLevel.Error, , , vMessage);
				EndIf;
			Else
				vMessage = Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'"); 
				WriteLogEvent("RTK.pmBackgroundJobRequest", EventLogLevel.Error, , , vMessage);
			EndIf;
		EndIf;
	Except
		vMessage = ErrorDescription();
		WriteLogEvent("RTK.pmBackgroundJobRequest", EventLogLevel.Error, , , vMessage);
	EndTry;		
EndProcedure // RTKBackgroundJobRequest

#EndRegion

#Region DatabaseUpdate

Procedure ConvertCalendarsData(pPeriodFrom, pPeriodTo) Export
	// Calendar days conversion
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CalendarDays.Period AS Period,
	|	CalendarDays.Calendar AS Calendar,
	|	CalendarDays.AccountingDate AS AccountingDate,
	|	CalendarDays.CalendarDayType AS CalendarDayType,
	|	CalendarDays.Timetable AS Timetable,
	|	CalendarDays.PriceTag AS PriceTag
	|FROM
	|	InformationRegister.CalendarDays AS CalendarDays
	|WHERE
	|	CalendarDays.AccountingDate = &qEmptyDate
	|	AND CalendarDays.Period >= &qPeriodFrom
	|	AND CalendarDays.Period <= &qPeriodTo
	|
	|ORDER BY
	|	Period DESC";
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(pPeriodTo), BegOfDay(pPeriodTo), '39991231'));
	vRcds = vQry.Execute().Select();
	i = 0;
	While vRcds.Next() Do
		i = i + 1;
		vRcdMgr = InformationRegisters.CalendarDays.CreateRecordManager();
		vRcdMgr.Period = vRcds.Period;
		vRcdMgr.Calendar = vRcds.Calendar;
		vRcdMgr.AccountingDate = vRcds.AccountingDate;
		vRcdMgr.Read();
		If vRcdMgr.Selected() Then
			Try
				If i = 1 Then
					BeginTransaction();
				EndIf;
				vRcdMgr.Delete();
				
				vRcdMgr.Period = '20000101';
				vRcdMgr.Calendar = vRcds.Calendar;
				vRcdMgr.AccountingDate = BegOfDay(vRcds.Period);
				vRcdMgr.CalendarDayType = vRcds.CalendarDayType;
				vRcdMgr.TimeTable = vRcds.TimeTable;
				vRcdMgr.PriceTag = vRcds.PriceTag;
				vRcdMgr.Author = SessionParameters.CurrentUser;
				vRcdMgr.Remarks = "-> 9.1";
				vRcdMgr.Write(True);
				If Int(i/1000) = i/1000 Then
					CommitTransaction();
					BeginTransaction();
				EndIf;
			Except
				vErrorInfo = ErrorInfo();
				If TransactionActive() Then
					RollbackTransaction();
					i = 0;
				EndIf;
				tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(vErrorInfo), MessageStatus.Attention);
			EndTry;
		EndIf;
	EndDo;
	If TransactionActive() Then
		CommitTransaction();
	EndIf;
	// Calendar days by room types conversion
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CalendarDaysByRoomTypes.Period AS Period,
	|	CalendarDaysByRoomTypes.Calendar AS Calendar,
	|	CalendarDaysByRoomTypes.RoomType AS RoomType,
	|	CalendarDaysByRoomTypes.AccountingDate AS AccountingDate,
	|	CalendarDaysByRoomTypes.Hotel AS Hotel,
	|	CalendarDaysByRoomTypes.CalendarDayType AS CalendarDayType
	|FROM
	|	InformationRegister.CalendarDaysByRoomTypes AS CalendarDaysByRoomTypes
	|WHERE
	|	CalendarDaysByRoomTypes.AccountingDate = &qEmptyDate
	|	AND CalendarDaysByRoomTypes.Period >= &qPeriodFrom
	|	AND CalendarDaysByRoomTypes.Period <= &qPeriodTo
	|
	|ORDER BY
	|	Period DESC";
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(pPeriodTo), BegOfDay(pPeriodTo), '39991231'));
	vRcds = vQry.Execute().Select();
	i = 0;
	While vRcds.Next() Do
		i = i + 1;
		vRcdMgr = InformationRegisters.CalendarDaysByRoomTypes.CreateRecordManager();
		vRcdMgr.Period = vRcds.Period;
		vRcdMgr.Calendar = vRcds.Calendar;
		vRcdMgr.RoomType = vRcds.RoomType;
		vRcdMgr.AccountingDate = vRcds.AccountingDate;
		vRcdMgr.Hotel = vRcds.Hotel;
		vRcdMgr.Read();
		If vRcdMgr.Selected() Then
			Try
				If i = 1 Then
					BeginTransaction();
				EndIf;
				vRcdMgr.Delete();
				
				vRcdMgr.Period = '20000101';
				vRcdMgr.Calendar = vRcds.Calendar;
				vRcdMgr.RoomType = vRcds.RoomType;
				vRcdMgr.AccountingDate = BegOfDay(vRcds.Period);
				vRcdMgr.Hotel = vRcds.Hotel;
				vRcdMgr.CalendarDayType = vRcds.CalendarDayType;
				vRcdMgr.Author = SessionParameters.CurrentUser;
				vRcdMgr.Remarks = "-> 9.1";
				vRcdMgr.Write(True);
				If Int(i/1000) = i/1000 Then
					CommitTransaction();
					BeginTransaction();
				EndIf;
			Except
				vErrorInfo = ErrorInfo();
				If TransactionActive() Then
					RollbackTransaction();
					i = 0;
				EndIf;
				tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(vErrorInfo), MessageStatus.Attention);
			EndTry;
		EndIf;
	EndDo;
	If TransactionActive() Then
		CommitTransaction();
	EndIf;
EndProcedure // ConvertCalendarsData

#EndRegion
