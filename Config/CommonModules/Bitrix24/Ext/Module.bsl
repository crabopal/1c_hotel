
#Region Public

// --------------------------------------------------------------------------------
// 
// Returns:
//  String - Token
//
Function AppCode() Export
	Return "app.5da984b4ca1010.65051253";
EndFunction

// --------------------------------------------------------------------------------
//  Description: Selects Clients must to be export to Bitrix 24.
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions 
// 
// Returns:
//  Array - Array of clients.
//
Function GetClientsAreChangedToExport(pExternalSystemInfoRef) Export
	vQuery = New Query;
	vQuery.Text =
	"SELECT
	|	nst_Table.Client AS Client,
	|	MAX(nst_Table.Period) AS LastUpdatePeriod
	|INTO tt_LastUpdate
	|FROM
	|	(SELECT
	|		IR_ClientChangeHistory.Client AS Client,
	|		MAX(IR_ClientChangeHistory.Period) AS Period
	|	FROM
	|		InformationRegister.ClientChangeHistory AS IR_ClientChangeHistory
	|	
	|	GROUP BY
	|		IR_ClientChangeHistory.Client
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		IR_ReservationChangeHistory.Guest,
	|		MAX(IR_ReservationChangeHistory.Period)
	|	FROM
	|		InformationRegister.ReservationChangeHistory AS IR_ReservationChangeHistory
	|	
	|	GROUP BY
	|		IR_ReservationChangeHistory.Guest
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AccommodationChangeHistory.Guest,
	|		MAX(AccommodationChangeHistory.Period)
	|	FROM
	|		InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|	
	|	GROUP BY
	|		AccommodationChangeHistory.Guest) AS nst_Table
	|
	|GROUP BY
	|	nst_Table.Client
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	tt_LastUpdate.Client AS Client
	|FROM
	|	tt_LastUpdate AS tt_LastUpdate
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""clients"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND tt_LastUpdate.Client = ExternalSystemIntegrationData.RefKey1
	|			AND tt_LastUpdate.LastUpdatePeriod < ExternalSystemIntegrationData.DataValue
	|WHERE
	|	ExternalSystemIntegrationData.DataValue IS NULL
	|	AND tt_LastUpdate.Client > VALUE(Catalog.Clients.EmptyRef)
	|	AND NOT tt_LastUpdate.Client.DeletionMark
	|	AND tt_LastUpdate.Client.FirstName <> """"
	|	AND tt_LastUpdate.Client.LastName <> """"
	|	AND (tt_LastUpdate.Client.Phone <> """"
	|			OR tt_LastUpdate.Client.EMail <> """")";
	vQuery.SetParameter("qExternalSystemRef", pExternalSystemInfoRef);
	Return vQuery.Execute().Unload().UnloadColumn(0);
EndFunction // GetClientsAreChangedToExport

// --------------------------------------------------------------------------------
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
// 
// Returns:
//  Array - Array of customers.
//
Function GetCustomersAreChangedToExport(ExternalSystemInfoRef) Export
	
	Query				=	New Query;
	Query.Text			=
	"SELECT
	|	nst_Table.Customer AS Customer,
	|	MAX(nst_Table.Period) AS LastUpdatePeriod
	|INTO tt_LastUpdate
	|FROM
	|	(SELECT
	|		CustomerChangeHistory.Customer AS Customer,
	|		MAX(CustomerChangeHistory.Period) AS Period
	|	FROM
	|		InformationRegister.CustomerChangeHistory AS CustomerChangeHistory
	|	
	|	GROUP BY
	|		CustomerChangeHistory.Customer
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		IR_ReservationChangeHistory.Customer,
	|		MAX(IR_ReservationChangeHistory.Period)
	|	FROM
	|		InformationRegister.ReservationChangeHistory AS IR_ReservationChangeHistory
	|	
	|	GROUP BY
	|		IR_ReservationChangeHistory.Customer
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AccommodationChangeHistory.Customer,
	|		MAX(AccommodationChangeHistory.Period)
	|	FROM
	|		InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|	
	|	GROUP BY
	|		AccommodationChangeHistory.Customer) AS nst_Table
	|
	|GROUP BY
	|	nst_Table.Customer
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	tt_LastUpdate.Customer AS Customer
	|FROM
	|	tt_LastUpdate AS tt_LastUpdate
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""customers"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND tt_LastUpdate.LastUpdatePeriod < ExternalSystemIntegrationData.DataValue
	|			AND tt_LastUpdate.Customer = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	ExternalSystemIntegrationData.DataValue IS NULL
	|	AND tt_LastUpdate.Customer > VALUE(Catalog.Customers.EmptyRef)
	|	AND NOT tt_LastUpdate.Customer.DeletionMark
	|	AND tt_LastUpdate.Customer.Description <> """"
	|	AND NOT tt_LastUpdate.Customer.IsIndividual
	|	AND NOT tt_LastUpdate.Customer.IsFolder
	|	AND NOT tt_LastUpdate.Customer.DeletionMark";
	
	Query.SetParameter("qExternalSystemRef", ExternalSystemInfoRef);
	Return Query.Execute().Unload().UnloadColumn(0);
	
EndFunction // GetClientsAreChangedToExport

// --------------------------------------------------------------------------------
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  pStartDate				 - Date	 - Start date
// 
// Returns:
//  Array - Deals to export
//
Function GetDealsAreChangedToExport(pExternalSystemInfoRef, pStartDate = Undefined) Export
	vQuery = New Query;
	vQuery.Text =
	"SELECT
	|	ExternalSystemIntegrationData.RefKey1 AS GroupType
	|INTO DoNotUnloadGroupTypes
	|FROM
	|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|WHERE
	|	ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef
	|	AND ExternalSystemIntegrationData.DataType = ""DoNotUnloadGroupType""
	|	AND ExternalSystemIntegrationData.DataValue = TRUE
	|
	|GROUP BY
	|	ExternalSystemIntegrationData.RefKey1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GroupTypesList.Ref AS GroupType
	|INTO GroupTypesList
	|FROM
	|	(SELECT
	|		GroupTypes.Ref AS Ref
	|	FROM
	|		Catalog.GroupTypes AS GroupTypes
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VALUE(Catalog.GroupTypes.EmptyRef)) AS GroupTypesList
	|		LEFT JOIN DoNotUnloadGroupTypes AS DoNotUnloadGroupTypes
	|		ON GroupTypesList.Ref = DoNotUnloadGroupTypes.GroupType
	|WHERE
	|	DoNotUnloadGroupTypes.GroupType IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExternalSystemIntegrationData.DataValue AS Value
	|INTO DoNotUnloadTransactionsByBusinessBlock
	|FROM
	|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|WHERE
	|	ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef
	|	AND ExternalSystemIntegrationData.DataType = ""DoNotUnloadTransactionsByBusinessBlock""
	|
	|GROUP BY
	|	ExternalSystemIntegrationData.DataValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(nst_Table.Period) AS LastUpdatePeriod,
	|	nst_Table.GuestGroup AS GuestGroup,
	|	nst_Table.GuestGroup.GroupType AS GroupType
	|INTO tt_LastUpdate
	|FROM
	|	(SELECT
	|		IR_ReservationChangeHistory.GuestGroup AS GuestGroup,
	|		MAX(IR_ReservationChangeHistory.Period) AS Period,
	|		RoomQuotas.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock) AS IsBusinessBlock
	|	FROM
	|		InformationRegister.ReservationChangeHistory AS IR_ReservationChangeHistory
	|			LEFT JOIN Catalog.RoomQuotas AS RoomQuotas
	|			ON IR_ReservationChangeHistory.RoomQuota = RoomQuotas.Ref
	|	WHERE
	|		IR_ReservationChangeHistory.Period >= &qPeriodFrom
	|		AND CASE
	|				WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|					THEN IR_ReservationChangeHistory.Hotel IN (&qHotel)
	|				ELSE TRUE
	|			END
	|	
	|	GROUP BY
	|		IR_ReservationChangeHistory.GuestGroup,
	|		RoomQuotas.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AccommodationChangeHistory.GuestGroup,
	|		MAX(AccommodationChangeHistory.Period),
	|		RoomQuotas.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|	FROM
	|		InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|			LEFT JOIN Catalog.RoomQuotas AS RoomQuotas
	|			ON AccommodationChangeHistory.RoomQuota = RoomQuotas.Ref
	|	WHERE
	|		AccommodationChangeHistory.Period >= &qPeriodFrom
	|		AND CASE
	|				WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|					THEN AccommodationChangeHistory.Hotel IN (&qHotel)
	|				ELSE TRUE
	|			END
	|	
	|	GROUP BY
	|		AccommodationChangeHistory.GuestGroup,
	|		RoomQuotas.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ResourceReservationChangeHistory.GuestGroup,
	|		MAX(ResourceReservationChangeHistory.Period),
	|		FALSE
	|	FROM
	|		InformationRegister.ResourceReservationChangeHistory AS ResourceReservationChangeHistory
	|	WHERE
	|		ResourceReservationChangeHistory.Period >= &qPeriodFrom
	|		AND CASE
	|				WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|					THEN ResourceReservationChangeHistory.Hotel IN (&qHotel)
	|				ELSE TRUE
	|			END
	|	
	|	GROUP BY
	|		ResourceReservationChangeHistory.GuestGroup) AS nst_Table
	|		LEFT JOIN DoNotUnloadTransactionsByBusinessBlock AS DoNotUnloadTransactionsByBusinessBlock
	|		ON (TRUE)
	|WHERE
	|	CASE
	|			WHEN ISNULL(DoNotUnloadTransactionsByBusinessBlock.Value, FALSE)
	|				THEN NOT ISNULL(nst_Table.IsBusinessBlock, FALSE)
	|			ELSE TRUE
	|		END
	|
	|GROUP BY
	|	nst_Table.GuestGroup,
	|	nst_Table.GuestGroup.GroupType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	tt_LastUpdate.GuestGroup AS GuestGroup
	|FROM
	|	tt_LastUpdate AS tt_LastUpdate
	|		INNER JOIN GroupTypesList AS GroupTypesList
	|		ON tt_LastUpdate.GroupType = GroupTypesList.GroupType
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""deals"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND tt_LastUpdate.LastUpdatePeriod < ExternalSystemIntegrationData.DataValue
	|			AND tt_LastUpdate.GuestGroup = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	ExternalSystemIntegrationData.DataValue IS NULL
	|	AND tt_LastUpdate.GuestGroup > VALUE(Catalog.GuestGroups.EmptyRef)
	|	AND NOT tt_LastUpdate.GuestGroup.DeletionMark
	|
	|ORDER BY
	|	GuestGroup"; 
	vQuery.SetParameter("qHotel", pExternalSystemInfoRef.Hotel);
	vQuery.SetParameter("qExternalSystemRef", pExternalSystemInfoRef);
	vQuery.SetParameter("qPeriodFrom", pStartDate);
	Return vQuery.Execute().Unload().UnloadColumn(0);
EndFunction // GetClientsAreChangedToExport

// --------------------------------------------------------------------------------
//  Process methods anf operations to export clients in array ot having changes in 1C 
//  database by selection algorith.
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  LogDataContainer		 - String								 - messages
//  RefsArrayToExport		 - Array								 - Refs
//  pDataType				 - String								 - Data type
//  pDealsStartDate			 - Date									 - Start date
// 
// Returns:
//  String - Result message
//
Function ExportData(pExternalSystemInfoRef, pLogDataContainer = Undefined, pRefsArrayToExport = Undefined, pDataType, pDealsStartDate = Undefined, pDealsEndDate = Undefined, pEndSessionTime = Undefined, rContinue = True, pUnmappedOnly = False) Export
	If pEndSessionTime <> Undefined Then
		vCurrentTime = CurrentUniversalDateInMilliseconds();
		If vCurrentTime > pEndSessionTime Then
			Return "Остановлено выполнение по тайм-ауту.";
		EndIf;
	EndIf;
	
	If pDataType = "Clients" Then
		CreateAndUpdateTags(pExternalSystemInfoRef);
	EndIf;
	
	// 01. Connection properties and operation init.
	pLogDataContainer = LogDataInit("Integration with B24. Export clients", pExternalSystemInfoRef);
	
	vApiConnectionProps = GetConnectionProps(pExternalSystemInfoRef, pLogDataContainer);
	
	vStrOperationName = GetNString(vApiConnectionProps.Server, "Экспорт изменений на портал Битрикс 24 %1", "Changes export to Bitrix 24 portal %1");
	vOperationID = LogDataStart(pLogDataContainer, vStrOperationName);
	
	vStartSynchronizationTime = CurrentSessionDate();
	vUpdateLastFullSynchronizationTime = False;
	
	// 02. Check for changes are exist.
	If pRefsArrayToExport = Undefined Then
		If pDataType = "Customers" Then
			pRefsArrayToExport = GetCustomersAreChangedToExport(pExternalSystemInfoRef);
		ElsIf pDataType = "Clients" Then
			pRefsArrayToExport = GetClientsAreChangedToExport(pExternalSystemInfoRef);
		ElsIf pDataType = "Deals" Then
			If pDealsStartDate = Undefined And pDealsEndDate = Undefined Then
				If ValueIsFilled(pExternalSystemInfoRef.LastFullSynchronizationTime) Then
					vStartDate = pExternalSystemInfoRef.LastFullSynchronizationTime;
				Else
					vStartDate = CurrentSessionDate() - 24*60*60;
				EndIf;
				
				pRefsArrayToExport = GetDealsAreChangedToExport(pExternalSystemInfoRef, vStartDate);
				vUpdateLastFullSynchronizationTime = True;
			Else
				pRefsArrayToExport = GetDealsByCheackInDate(pExternalSystemInfoRef, pDealsStartDate, pDealsEndDate, pUnmappedOnly);
			EndIf;
		Else
			rContinue = False;
			Return "Ошибка выгрузки. Неизвестный тип данных выгрузки.";
		EndIf;
	EndIf;
	
	vCountOfChanges = pRefsArrayToExport.Count();
	
	If vCountOfChanges = 0 Then
		rContinue = False;
		Return "Выгрузка отменена. Нет данных для выгрузки.";
	EndIf;
	
	// Export Client and customers that not exported yet
	vClientsInDeals = Undefined;
	vCustomersInDeals = Undefined;
	If pDataType = "Deals" Then
		vClientsInDeals = GetClientsByGuestGroups(pExternalSystemInfoRef, pRefsArrayToExport, True);
		vCustomersInDeals = GetCustomersByGuestGroups(pExternalSystemInfoRef, pRefsArrayToExport, True);
		If vClientsInDeals.Count() > 0 Then
			vClientsArray = vClientsInDeals.UnloadColumn(0);
			ExportData(pExternalSystemInfoRef, , vClientsArray, "Clients", , , pEndSessionTime);
		EndIf;
		If vCustomersInDeals.Count() > 0 Then
			vCustomersArray = vCustomersInDeals.UnloadColumn(0);
			ExportData(pExternalSystemInfoRef, , vCustomersArray, "Customers", , , pEndSessionTime);
		EndIf;
	EndIf;
	
	If pEndSessionTime <> Undefined Then
		vCurrentTime = CurrentUniversalDateInMilliseconds();
		If vCurrentTime > pEndSessionTime Then
			Return "Остановлено выполнение по тайм-ауту.";
		EndIf;
	EndIf;
	
	// 03. API connection init.
	vApiConnection = ApiConnectionInit(pExternalSystemInfoRef, vApiConnectionProps, pLogDataContainer);
	
	If vApiConnection = Undefined Then
		Return "Ошибка выгрузки. Не удалось установить соединение.";
	EndIf;
	
	// 04. Init data to export.
	vClientFieldPMSCode = Undefined;
	vFieldsB24TypesMap = New Map;
	If pDataType = "Customers" Then
		vDataTable = GetDataCustomersToExport(pExternalSystemInfoRef, pRefsArrayToExport, vFieldsB24TypesMap, pLogDataContainer);
	ElsIf pDataType = "Clients" Then
		vDataTable = GetDataClientsToExport(pExternalSystemInfoRef, pRefsArrayToExport, vFieldsB24TypesMap, pLogDataContainer, vClientFieldPMSCode);
	ElsIf pDataType = "Deals" Then
		vDataTable = GetDataDealsToExport(pExternalSystemInfoRef, pRefsArrayToExport, vFieldsB24TypesMap, pLogDataContainer);
	EndIf;
	
	vClientsTags = Undefined;
	vBitrixClientTags = Undefined;
	If pDataType = "Clients" Then
		vClientsTags = GetClientsTags(pRefsArrayToExport);
		vBitrixClientTags = InformationRegisters.ExternalSystemIntegrationData.GetData(pExternalSystemInfoRef, "clientTags");
	EndIf;
	
	// 05. Export changes to Bitrix 24.
	vClientApiMethods = New Structure;
	vClientApiMethods.Insert("Add", GetApiMethod(pDataType, "", "Add"));
	vClientApiMethods.Insert("Update", GetApiMethod(pDataType, "", "Update"));
	
	vSuccessCounter = 0;
	vErrorsCounter = 0;
	
	If pDataType = "Deals" Then
		vClientsInDeals = GetClientsByGuestGroups(pExternalSystemInfoRef, pRefsArrayToExport, , True);
	EndIf;
	
	vDataTable.Columns.Add("Success", cmGetBooleanTypeDescription());
	
	If pEndSessionTime <> Undefined Then
		vCurrentTime = CurrentUniversalDateInMilliseconds();
		If vCurrentTime > pEndSessionTime Then
			Return "Остановлено выполнение по тайм-ауту.";
		EndIf;
	EndIf;
	
	vIsStoppedExecutionOnTimeout = False;
	
	vDatas = New Map;
	vRequestDatas = New Map;
	vFindIDDatas = New Map;
	
	vDealSalesByGuestGroups = Undefined;
	If pDataType = "Deals" Then
		vDealSalesByGuestGroups = GetSalesTotalsByGuestGroups(pRefsArrayToExport);
	EndIf;
	
	vDataTableCount = vDataTable.Count() - 1;
	For vDataNumber = 0 To vDataTableCount Do
		vSingleDataRow = vDataTable[vDataNumber];
		vDataUUID = "C" + StrReplace(TrimAll(vSingleDataRow.Ref.UUID()), "-", "");
		
		If Not ValueIsFilled(vSingleDataRow.B24ContactID) Then
			If pDataType = "Clients" And vClientFieldPMSCode <> Undefined Then
				vLastNaneCode = "LAST_NAME";
				vPMSCode = vSingleDataRow[vClientFieldPMSCode];
				If cmIsNumber(vPMSCode) Then
					vPMSCode = Format(Number(vPMSCode), "NZ=; NG=");
				EndIf;
				
				vFindClientRequestString = GetApiMethod("Clients", "", "List") + "?start=-1&filter[" + vLastNaneCode + "]=" + ConvertStringToURL(vSingleDataRow[vLastNaneCode]) + "&filter[" + vClientFieldPMSCode + "]=" + vPMSCode + "&select[]=id&order[ID]=ASC";
				vFindIDDatas.Insert(vDataUUID, vFindClientRequestString);
			ElsIf pDataType = "Customers" And Not IsBlankString(vSingleDataRow.Ref.TIN) Then
				vFindClientRequestString = "crm.requisite.list?start=-1&select[]=ENTITY_ID&filter[ENTITY_TYPE_ID]=4&filter[RQ_INN]=" + TrimAll(vSingleDataRow.Ref.TIN) + "&order[ENTITY_ID]=ASC";
				vFindIDDatas.Insert(vDataUUID, vFindClientRequestString);
			EndIf;
		EndIf;
		
		vDatas.Insert(vDataUUID, vSingleDataRow);
		If vDatas.Count() < 50 And vDataNumber <> vDataTableCount Then
			Continue;
		EndIf;
		
		If vFindIDDatas.Count() > 0 Then
			vAnswerStructure = ExecuteApiRequestBatchJSON(vApiConnection, vApiConnectionProps, vFindIDDatas, Undefined, 0, pExternalSystemInfoRef);
			vAnswerResult = GetPropertyOfStructure(vAnswerStructure, "result.result");
			If vAnswerResult = Undefined Then
				vDatas = New Map;
				vRequestDatas = New Map;
				vFindIDDatas = New Map;
				Continue;
			EndIf;
			
			For Each vAnswerResultRow In vAnswerResult Do
				vAnswerResultRowValue = vAnswerResultRow.Value;
				vAnswerResultRowKey = vAnswerResultRow.Key;
				
				If TypeOf(vAnswerResultRowValue) = Type("Array") Then
					For Each vFindClientResultRow In vAnswerResultRowValue Do
						If pDataType = "Clients" Then
							vDatas[vAnswerResultRowKey].B24ContactID = vFindClientResultRow.ID;
						ElsIf pDataType = "Customers" Then
							vDatas[vAnswerResultRowKey].B24ContactID = vFindClientResultRow.ENTITY_ID;
						EndIf;
						Break;
					EndDo;
				EndIf;
			EndDo;
			vFindIDDatas = New Map;
			cmWait(1);
		EndIf;
		
		For Each vDataRow In vDatas Do
			vSingleData = vDataRow.Value;
			
			vRequestArray = ComposeArrayOfFieldsToExport(vSingleData, vFieldsB24TypesMap);
			
			If Not ValueIsFilled(vSingleData.B24ContactID) Then
				vApiMethod = vClientApiMethods.Add;
			Else
				vApiMethod = vClientApiMethods.Update;
				vRequestArray.Add("id=" + ConvertNumberToString(vSingleData.B24ContactID));
			EndIf;
			
			vRequestString = vApiMethod + "?" + StrConcat(vRequestArray, "&");
			
			If pDataType = "Clients" And vClientsTags <> Undefined And vBitrixClientTags <> Undefined Then
				vClientTags = vClientsTags.FindRows(New Structure("Client", vSingleData.Ref));
				If vClientTags.Count() > 0 Then
					i = 0;
					For Each vClientTag in vClientsTags Do
						vBitrixTag = vBitrixClientTags.Find(vClientTag.Tag);
						If vBitrixTag <> Undefined Then
							vRequestString = vRequestString + "&fields[UF_CRM_1CHOTELTAGS][" + i + "]=" + vBitrixTag.ID;
							i = i + 1;
						EndIf;
					EndDo;
				EndIf;
			ElsIf pDataType = "Deals" Then
				vClientsInCurrentDeal = vClientsInDeals.FindRows(New Structure("GuestGroup", vSingleData.Ref));
				vOnlyFirstGuest = ValueIsFilled(vSingleData.Ref.GroupType);
				i = 0;
				For Each vClient in vClientsInCurrentDeal Do
					If ValueIsFilled(vClient.ExternalSystemDataCode) Then
						vRequestString = vRequestString + "&fields[CONTACT_IDS][" + Format(i, "NZ=0; NG=") + "]=" + Format(vClient.ExternalSystemDataCode, "NZ=0; NG=");
						i = i + 1;
					Else
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pExternalSystemInfoRef, "Deals", Enums.ExternalSystemEventTypes.Warning, "", "", "Failed to find client ID for deal: " + vClient.Guest);
					EndIf;
					If vOnlyFirstGuest Then
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			vRequestDatas.Insert(vDataRow.Key, vRequestString);
		EndDo;
		
		ExportDataRow(vApiConnection, vApiConnectionProps, vRequestDatas, vDatas, pExternalSystemInfoRef, pDataType, vStartSynchronizationTime, vSuccessCounter, vErrorsCounter);
		cmWait(1);
		
		If pDataType = "Deals" Then
			vProductDatas = New Map;
			For Each vDataRow In vDatas Do
				vSingleData = vDataRow.Value;
				
				If Not vSingleData.Success Then
					Continue;
				EndIf;
				
				If Not ValueIsFilled(vSingleData.B24ContactID) Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pExternalSystemInfoRef, "Deals", Enums.ExternalSystemEventTypes.Warning, "", "", "Failed to find deal ID to unload products:" + vSingleData.Ref);
					Continue;
				EndIf;
				
				vDealRequestString = "crm.deal.productrows.set" + "?id=" + Format(vSingleData.B24ContactID, "NZ=0; NG=");
				vDealSales 		= vDealSalesByGuestGroups.FindRows(New Structure("GuestGroup", vSingleData.Ref));
				i = 0;
				For Each vDealSale in vDealSales Do
					ValueForURL			= ConvertStringToURL(XMLString(vDealSale.Service.Description));
					vDealRequestString 	= vDealRequestString + "&rows[" + Format(i, "NZ=0; NG=") + "][PRODUCT_NAME]=" +ValueForURL; 
					vDealRequestString 	= vDealRequestString + "&rows[" + Format(i, "NZ=0; NG=") + "][PRICE]=" + Format(vDealSale.Sales + vDealSale.SalesForecast, "NZ=0; NG=");
					vDealRequestString 	= vDealRequestString + "&rows[" + Format(i, "NZ=0; NG=") + "][QUANTITY]=" + Format(1, "NZ=0; NG="); 
					i = i + 1;
				EndDo;
				
				vProductDatas.Insert(vDataRow.Key, vDealRequestString);
			EndDo;
			
			If vProductDatas.Count() > 0 Then
				vAnswerStructure = ExecuteApiRequestBatchJSON(vApiConnection, vApiConnectionProps, vProductDatas, Undefined, 0, pExternalSystemInfoRef);
				cmWait(1);
			EndIf;
		EndIf;
		
		vDatas = New Map;
		vRequestDatas = New Map;
		
		If pEndSessionTime <> Undefined Then
			vCurrentTime = CurrentUniversalDateInMilliseconds();
			If vCurrentTime > pEndSessionTime Then
				vIsStoppedExecutionOnTimeout = True;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	If pDataType = "Deals" And Not vIsStoppedExecutionOnTimeout And vErrorsCounter = 0 And vUpdateLastFullSynchronizationTime Then
		vExtSysObj = pExternalSystemInfoRef.GetObject();
		vExtSysObj.LastFullSynchronizationTime = vStartSynchronizationTime;
		vExtSysObj.Write();
	EndIf;
	
	vMessageParamsArray = New Array;
	vMessageParamsArray.Add(ConvertNumberToString(vSuccessCounter));
	vMessageParamsArray.Add(ConvertNumberToString(vErrorsCounter));
	
	If Not vIsStoppedExecutionOnTimeout Then
		vStrFinalMessage = GetNString(vMessageParamsArray, "Выгрузка завершена. %1 выгружены успешно и у %2 возникли ошибки", "%1 were have been exported successful and %2 had errors");
		rContinue = False;
	Else
		vMessageParamsArray.Add(Bitrix24.ConvertNumberToString(vCountOfChanges));
		vStrFinalMessage = GetNString(vMessageParamsArray, "Остановлено выполнение по тайм-ауту. %1 выгружены успешно и у %2 возникли ошибки из %3", "%1 were have been exported successful and %2 had errors from %3");
	EndIf;
	
	If pExternalSystemInfoRef.DebugMode Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pExternalSystemInfoRef, pDataType, Enums.ExternalSystemEventTypes.Info, "", "", vStrFinalMessage);
	EndIf;
	
	LogDataFinish(pLogDataContainer, vOperationID, vStrFinalMessage);
	LogDataWrite(pLogDataContainer);
	
	Return vStrFinalMessage;
EndFunction // ExportData

// --------------------------------------------------------------------------------
//  Description: Process methods anf operations to import and export data via 1C and Bitrix 24.
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions 
//  FirstImportThenExport	 - Boolean - First import then export 
//  pSycnTasks				 - Boolean	 - Sycn tasks
//  pSyncCustomers			 - Boolean	 - Sync customers
//  pSyncDeals				 - Boolean	 - Sync deals 
//
Procedure SynchDataWithBitrix24(pExternalSystemInfoRef, pFirstImportThenExport = True, pSycnTasks = False, pSyncClients = False, pSyncCustomers = False, pSyncDeals = False) Export
	If pExternalSystemInfoRef.SessionStartTime + 60*60 <= CurrentSessionDate() Then
		vApiConnectionProps = GetConnectionProps(pExternalSystemInfoRef);
		RefreshAccessTokenB24(vApiConnectionProps);
	EndIf;
	
	If pSycnTasks Then
		SyncTasks(pExternalSystemInfoRef);
	EndIf;
	
	If pFirstImportThenExport Then
		vEndSessionTime = Undefined;
		If pExternalSystemInfoRef.SessionTimeout > 0 Then
			vSeconds = 60;
			vMilliseconds = 1000;
			
			vDurationMiliSeconds = pExternalSystemInfoRef.SessionTimeout * vSeconds * vMilliseconds;
			vStartTime = CurrentUniversalDateInMilliseconds();
			vEndSessionTime = vStartTime + vDurationMiliSeconds;
		EndIf;
		
		If pSyncClients Then
			ImportData(pExternalSystemInfoRef, , , , "Clients");
			cmWait(1);
			ExportData(pExternalSystemInfoRef, , , "Clients", , , vEndSessionTime);
		EndIf;
		
		If pExternalSystemInfoRef.SessionTimeout > 0 Then
			vCurrentTime = CurrentUniversalDateInMilliseconds();
			If vCurrentTime > vEndSessionTime Then
				Return;
			EndIf;
		EndIf;
		
		If pSyncCustomers Then
			cmWait(1);
			ImportData(pExternalSystemInfoRef, , , , "Customers");
			cmWait(1);
			ExportData(pExternalSystemInfoRef, , , "Customers", , , vEndSessionTime);
		EndIf;
		
		If pExternalSystemInfoRef.SessionTimeout > 0 Then
			vCurrentTime = CurrentUniversalDateInMilliseconds();
			If vCurrentTime > vEndSessionTime Then
				Return;
			EndIf;
		EndIf;
		
		If pSyncDeals Then
			cmWait(1);
			ExportData(pExternalSystemInfoRef, , , "Deals", , , vEndSessionTime);
		EndIf;
	Else
		
		If pExternalSystemInfoRef.SessionTimeout > 0 Then
			vSeconds = 60;
			vMilliseconds = 1000;
			
			vDurationMiliSeconds = pExternalSystemInfoRef.SessionTimeout * vSeconds * vMilliseconds;
			vStartTime = CurrentUniversalDateInMilliseconds();
			vEndSessionTime = vStartTime + vDurationMiliSeconds;
		EndIf;
		
		If pSyncClients Then
			ExportData(pExternalSystemInfoRef, , , "Clients", , , vEndSessionTime);
			cmWait(1);
			ImportData(pExternalSystemInfoRef, , , , "Clients");
		EndIf;
		
		If pExternalSystemInfoRef.SessionTimeout > 0 Then
			vCurrentTime = CurrentUniversalDateInMilliseconds();
			If vCurrentTime > vEndSessionTime Then
				Return;
			EndIf;
		EndIf;
		
		If pSyncCustomers Then
			cmWait(1);
			ExportData(pExternalSystemInfoRef, , , "Customers", , , vEndSessionTime);
			cmWait(1);
			ImportData(pExternalSystemInfoRef, , , , "Customers");
		EndIf;
		
		If pExternalSystemInfoRef.SessionTimeout > 0 Then
			vCurrentTime = CurrentUniversalDateInMilliseconds();
			If vCurrentTime > vEndSessionTime Then
				Return;
			EndIf;
		EndIf;
		
		If pSyncDeals Then
			cmWait(1);
			ExportData(pExternalSystemInfoRef, , , "Deals", , , vEndSessionTime);
		EndIf;
	EndIf;
	
EndProcedure //  SynchDataWithBitrix24()

// --------------------------------------------------------------------------------
//  Description: Create value table with 1C data in bitrix 24 fields to fill htttp request string fo API.
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  RefsArray				 - Array								 - Refs
//  FieldsB24TypesMap		 - String								 - Fields
//  LogDataContainer		 - String								 - Messages
// 
// Returns:
//  ValueTable - Result
//
Function GetDataClientsToExport(ExternalSystemInfoRef, RefsArray, FieldsB24TypesMap, LogDataContainer = Undefined, rClientFieldPMSCode = Undefined) Export
	
	// 02. Fields table init.
	FieldsTable				=	CreateAttributesTableForClients(ExternalSystemInfoRef);
	vAdditionalInfoMap		=	New Map;
	cmGetDataFieldsMap		=	New Map;
	ArrayOfSelections		=	New Array;
	ArrayExtraFields 		= New Array;
	
	vClientFieldPMSFieldsTableArr = FieldsTable.FindRows(New Structure("Attribute1C", "Code"));
	If vClientFieldPMSFieldsTableArr.Count() > 0 Then
		rClientFieldPMSCode = vClientFieldPMSFieldsTableArr[0].AttributeB24;
	EndIf;
	
	
	// 03. Compose query string to get data.
	For Each FieldsTableRow In FieldsTable Do
		
		If FieldsTableRow.AttributeB24 = "UF_CRM_1CHOTELTAGS" Then
			Continue;
		EndIf;
		
		// Add types of the field.
		If FieldsB24TypesMap[FieldsTableRow.AttributeB24] = Undefined Then
			
			FieldsB24TypesMap.Insert(FieldsTableRow.AttributeB24, FieldsTableRow.Type);
			
		Else
			
			Continue;
			
		EndIf;
		
		
		
		// Check for datapath cuz we need Catalog.Clients only for Query.
		If StrCompare(FieldsTableRow.DataPath, "Clients") = 0 Then
			
			If rClientFieldPMSCode = FieldsTableRow.AttributeB24 Then
				ArrayOfSelections.Add("CAST(" +FieldsTableRow.Attribute1C + " AS STRING(0)) AS " + FieldsTableRow.AttributeB24);
			Else
				ArrayOfSelections.Add(FieldsTableRow.Attribute1C + " AS " + FieldsTableRow.AttributeB24);
			EndIf;
			
		Else
			
			ArrayExtraFields.Add(FieldsTableRow.AttributeB24);
			
			// Need mapping fields to fill with cmGetClientStats().
			If strPos(FieldsTableRow.DataPath, "cmGetClientStats") Then
				
				cmGetDataFieldsMap.Insert(FieldsTableRow.Attribute1C, FieldsTableRow.AttributeB24);
				
			ElsIf strPos(FieldsTableRow.DataPath, "AdditionalInfo") Then
				
				vAdditionalInfoMap.Insert(FieldsTableRow.Attribute1C, FieldsTableRow.AttributeB24);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	
	If ArrayOfSelections.Count() = 0 Then
		
		Return new ValueTable;
		
	EndIf;
	
	
	// 04. Getting main data from catalog.
	Query				=	New Query;
	Query.Text			=
	"SELECT
	|	&strClientFieldsPath AS strClientFieldsPath,
	|	Clients.Ref AS Ref,
	|	Clients.Description AS Description,
	|	ExternalSystemIntegrationData.ExternalSystemDataCode AS B24ContactID
	|FROM
	|	Catalog.Clients AS Clients
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""clients"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND Clients.Ref = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	Clients.Ref IN(&RefsArray)";
	
	Query.SetParameter("RefsArray",	RefsArray);
	Query.SetParameter("qExternalSystemRef",	ExternalSystemInfoRef);
	
	strClientFieldsPath	=	StrConcat(ArrayOfSelections, ", ");
	Query.Text			=	StrReplace(Query.Text, "&strClientFieldsPath AS strClientFieldsPath", strClientFieldsPath);
	DataTable			=	Query.Execute().Unload();
	
	If rClientFieldPMSCode <> Undefined Then
		For Each vDataTableRow In DataTable Do
			vPMSCode = vDataTableRow[rClientFieldPMSCode];
			If cmIsNumber(vPMSCode) Then
				vDataTableRow[rClientFieldPMSCode] = Format(Number(vPMSCode), "NZ=; NG=");
			EndIf;
		EndDo;
	EndIf;
	
	For Each fld In ArrayExtraFields Do
		DataTable.Columns.Add(fld);
	EndDo;
	
	// 05. Add data from another sources.
	If cmGetDataFieldsMap.Count() > 0 Then
		
		For Each DataRow In DataTable Do
			
			cmGetData	=	cmGetClientStats(DataRow.Ref,ExternalSystemInfoRef.WSHost);
			
			If cmGetData <> Undefined And TypeOf(cmGetData) = Type("Structure") Then
				
				For Each Field1CtoFieldB24 In cmGetDataFieldsMap Do
					
					vFieldValue = Undefined;
					cmGetData.Property(Field1CtoFieldB24.Key, vFieldValue);
					DataRow[Field1CtoFieldB24.Value] = vFieldValue;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If vAdditionalInfoMap.Count() > 0 Then
		For Each DataRow In DataTable Do
			For Each vAdditionalInfo in vAdditionalInfoMap Do
				If vAdditionalInfo.Key = "DiscountCardType" Then
					vValue = "";
					
					vClient = DataRow.Ref;
					If ValueIsFilled(vClient) Then
						vDiscountCard = vClient.DiscountCard;
						
						If ValueIsFilled(vDiscountCard) Then
							vValue = TrimAll(vDiscountCard.DiscountType);
						EndIf;
					EndIf;
				EndIf;
				
				If TypeOf(vValue) = Type("String") Then
					DataRow[vAdditionalInfo.Value] = vValue;
				Else	
					DataRow[vAdditionalInfo.Value] = Format(vValue, "NZ=0; NG=");
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	FillMappedData(ExternalSystemInfoRef, DataTable, "TYPE_ID", "ClientTypes", "CLIENT");
	
	Return DataTable;
	
EndFunction //  GetDataClientsToExport()

// --------------------------------------------------------------------------------
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  RefsArray				 - Array								 - Refs
//  FieldsB24TypesMap		 - String								 - Fields
//  LogDataContainer		 - String								 - Messages
// 
// Returns:
//  ValueTable - Result
//
Function GetDataCustomersToExport(ExternalSystemInfoRef, RefsArray, FieldsB24TypesMap, LogDataContainer = Undefined) Export
	
	// 02. Fields table init.
	FieldsTable				=	CreateAttributesTableForCustomers(ExternalSystemInfoRef);
	cmGetDataFieldsMap		=	New Map;
	ArrayOfSelections		=	New Array;
	ArrayExtraFields 		= New Array;
	
	
	// 03. Compose query string to get data.
	For Each FieldsTableRow In FieldsTable Do
		
		// Add types of the field.
		If FieldsB24TypesMap[FieldsTableRow.AttributeB24] = Undefined Then
			
			FieldsB24TypesMap.Insert(FieldsTableRow.AttributeB24, FieldsTableRow.Type);
			
		Else
			
			Continue;
			
		EndIf;
		
		
		
		// Check for datapath cuz we need Catalog.Clients only for Query.
		If StrCompare(FieldsTableRow.DataPath, "Customers") = 0 Then
			
			ArrayOfSelections.Add(FieldsTableRow.Attribute1C + " AS " + FieldsTableRow.AttributeB24);
			
		Else
			
		EndIf;
		
	EndDo;
	
	
	If ArrayOfSelections.Count() = 0 Then
		
		Return new ValueTable;
		
	EndIf;
	
	
	// 04. Getting main data from catalog.
	Query				=	New Query;
	Query.Text			=
	"SELECT
	|	&strClientFieldsPath AS strClientFieldsPath,
	|	Customers.Ref AS Ref,
	|	Customers.Description AS Description,
	|	ExternalSystemIntegrationData.ExternalSystemDataCode AS B24ContactID
	|FROM
	|	Catalog.Customers AS Customers
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""customers"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND Customers.Ref = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	Customers.Ref IN(&RefsArray)
	|	AND NOT Customers.IsIndividual
	|	AND NOT Customers.IsFolder
	|	AND NOT Customers.DeletionMark";
	
	Query.SetParameter("RefsArray",	RefsArray);
	Query.SetParameter("qExternalSystemRef",	ExternalSystemInfoRef);
	
	strClientFieldsPath	=	StrConcat(ArrayOfSelections, ", ");
	Query.Text			=	StrReplace(Query.Text, "&strClientFieldsPath AS strClientFieldsPath", strClientFieldsPath);
	DataTable			=	Query.Execute().Unload();
	
	For Each fld In ArrayExtraFields Do
		DataTable.Columns.Add(fld);
	EndDo;
	
	FillMappedData(ExternalSystemInfoRef, DataTable, "COMPANY_TYPE", "CustomerTypes", "CUSTOMER");
	FillMappedData(ExternalSystemInfoRef, DataTable, "INDUSTRY", "CustomerIndustries", "OTHER");
	
	Return DataTable;
	
EndFunction //  GetDataCustomersToExport()

// --------------------------------------------------------------------------------
// Returns value table with guest group data that have to be exported by the array of such groups ids
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  RefsArray				 - Array								 - Refs
//  FieldsB24TypesMap		 - String								 - Fields
//  LogDataContainer		 - String								 - Messages
// 
// Returns:
//  ValueTable - Result
//
Function GetDataDealsToExport(pExternalSystemInfoRef, pRefsArray, rFieldsB24TypesMap, pLogDataContainer = Undefined) Export
	vFieldsTable = CreateAttributesTableForDeals(pExternalSystemInfoRef);
	vAdditionalInfoMap = New Map;
	vArrayOfSelections = New Array;
	vArrayExtraFields = New Array;
	
	For Each FieldsTableRow In vFieldsTable Do
		If FieldsTableRow.AttributeB24 = "CONTACT_IDS" Then
			Continue;
		EndIf;
		
		If rFieldsB24TypesMap[FieldsTableRow.AttributeB24] = Undefined Then
			rFieldsB24TypesMap.Insert(FieldsTableRow.AttributeB24, FieldsTableRow.Type);
		Else
			Continue;
		EndIf;
		
		If StrCompare(FieldsTableRow.DataPath, "GuestGroups") = 0 Then
			vArrayOfSelections.Add(FieldsTableRow.Attribute1C + " AS " + FieldsTableRow.AttributeB24);
		Else
			vArrayExtraFields.Add(FieldsTableRow.AttributeB24);
			If strPos(FieldsTableRow.DataPath, "AdditionalInfo") Then
				vAdditionalInfoMap.Insert(FieldsTableRow.Attribute1C, FieldsTableRow.AttributeB24);
			EndIf;
		EndIf;
	EndDo;
	
	If vArrayOfSelections.Count() = 0 Then
		Return New ValueTable;
	EndIf;
	
	vQuery = New Query;
	vQuery.Text =
	"SELECT
	|	&strClientFieldsPath AS strClientFieldsPath,
	|	GuestGroups.Ref AS Ref,
	|	GuestGroups.Description AS Description,
	|	ExternalSystemIntegrationData.ExternalSystemDataCode AS B24ContactID
	|FROM
	|	Catalog.GuestGroups AS GuestGroups
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""deals"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND GuestGroups.Ref = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	GuestGroups.Ref IN(&RefsArray)";
	
	vQuery.SetParameter("RefsArray", pRefsArray);
	vQuery.SetParameter("qExternalSystemRef", pExternalSystemInfoRef);
	
	vStrDealFieldsPath = StrConcat(vArrayOfSelections, ", ");
	vQuery.Text = StrReplace(vQuery.Text, "&strClientFieldsPath AS strClientFieldsPath", vStrDealFieldsPath);
	vDataTable = vQuery.Execute().Unload();
	
	For Each vFld In vArrayExtraFields Do
		vDataTable.Columns.Add(vFld);
	EndDo;
	
	FillMappedData(pExternalSystemInfoRef, vDataTable, "STAGE_ID", "DealStatuses", "CUSTOMER", , , "CATEGORY_ID");
	FillMappedData(pExternalSystemInfoRef, vDataTable, "CATEGORY_ID", "DealCategory");
	FillMappedData(pExternalSystemInfoRef, vDataTable, "COMPANY_ID", "customers", "CUSTOMER", "updatePeriod", "ExternalSystemDataCode");
	FillMappedData(pExternalSystemInfoRef, vDataTable, "CONTACT_ID", "clients", "", "updatePeriod", "ExternalSystemDataCode");
	
	If vAdditionalInfoMap.Count() = 0 Then
		Return vDataTable;
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	UTMTags.GuestGroup AS GuestGroup,
	|	UTMTags.utm_source AS utm_source,
	|	UTMTags.utm_campaign AS utm_campaign,
	|	UTMTags.utm_medium AS utm_medium,
	|	UTMTags.utm_content AS utm_content
	|FROM
	|	InformationRegister.UTMTags AS UTMTags
	|WHERE
	|	UTMTags.GuestGroup IN(&qGuestGroups)";
	vQuery.SetParameter("qGuestGroups", pRefsArray);
	
	vUTMData = vQuery.Execute().Unload();
	
	vValueTablesArr = GetGuestGroupsInfo(pRefsArray, pExternalSystemInfoRef);
	
	vDocumentsListByRoomDataList = vValueTablesArr[4].Unload();
	vAdditionalInfoDataList = vValueTablesArr[7].Unload();
	vInfoBaseURL= GetInfoBaseURL();
	
	vDocumentsListByRoomDataListCopy = vDocumentsListByRoomDataList.Copy();
	vDocumentsListByRoomDataListCopy.GroupBy("GuestGroup, Number");
	
	vURLIntegration = Undefined;
	
	For Each DataRow In vDataTable Do
		vGuestGroup = DataRow.Ref;
		vGuestGroupObj = vGuestGroup.GetObject();
		vHotel = vGuestGroupObj.Owner;
		
		vAdditionalInfoDataArr = vAdditionalInfoDataList.FindRows(New Structure("GuestGroup", vGuestGroup));
		If vAdditionalInfoDataArr.Count() > 0 Then
			vGuestGroupAdditionalInfo = vAdditionalInfoDataArr[0];
		Else
			vGuestGroupAdditionalInfo = New Structure("Hotel, Sales, Payments, NumberOfAdults, NumberOfChildren, NumberOfTeenagers, NumberOfInfants, RoomsReserved", "", 0, 0, 0, 0, 0, 0, 0);
		EndIf;
		
		For Each vAdditionalInfo in vAdditionalInfoMap Do
			vValue = "";
			If StrFind(vAdditionalInfo.Key, "utm") > 0 Then
				vUTMRow = vUTMData.Find(vGuestGroup, "GuestGroup");
				If vUTMRow <> Undefined Then
					vValue = vUTMRow[vAdditionalInfo.Key];
				EndIf;
			ElsIf vAdditionalInfo.Key = "Title" Then
				vValue = "Бронь №" + Format(vGuestGroupObj.Code,"NG=") + " c " + Format(vGuestGroupObj.CheckInDate,"DF=dd.MM.yyyy") + " на " + vGuestGroupObj.Duration + " ночей, "+TrimAll(vGuestGroupObj.Owner);
			ElsIf vAdditionalInfo.Key = "Summ" Then
				vValue = vGuestGroupAdditionalInfo.Sales;
			ElsIf vAdditionalInfo.Key = "NumberOfAdults" Then
				vValue = vGuestGroupAdditionalInfo.NumberOfAdults;
			ElsIf vAdditionalInfo.Key = "NumberOfChildren" Then
				vValue = vGuestGroupAdditionalInfo.NumberOfChildren;
			ElsIf vAdditionalInfo.Key = "NumberOfTeenagers" Then
				vValue = vGuestGroupAdditionalInfo.NumberOfTeenagers;
			ElsIf vAdditionalInfo.Key = "NumberOfInfants" Then
				vValue = vGuestGroupAdditionalInfo.NumberOfInfants;
			ElsIf vAdditionalInfo.Key = "RoomsQuantity" Then
				vValue = vGuestGroupAdditionalInfo.RoomsReserved;
			ElsIf vAdditionalInfo.Key = "ExternalRef" Then
				vValue = TrimAll(vInfoBaseURL) + "#" + GetURL(vGuestGroup);
			ElsIf vAdditionalInfo.Key = "B24EmployeeID" Then
				vValue = vGuestGroupObj.Author.B24EmployeeID;
			ElsIf vAdditionalInfo.Key = "Hotel" Then
				vValue = vGuestGroupAdditionalInfo.Hotel;
			ElsIf vAdditionalInfo.Key = "GuestGroupReservationLink" Then
				vValue = GetGuestGroupURL(vGuestGroup, pExternalSystemInfoRef, vURLIntegration);
			ElsIf vAdditionalInfo.Key = "GuestGroupBalance" Then
				vValue = "";
				vGuestGroupBalance = vGuestGroupAdditionalInfo.Sales - vGuestGroupAdditionalInfo.Payments;
				If vGuestGroupBalance > 0 Then
					vValue = cmFormatSum(cmConvertCurrencies(vGuestGroupAdditionalInfo.Sales - vGuestGroupAdditionalInfo.Payments, vGuestGroupAdditionalInfo.SalesCurrency, , vHotel.FolioCurrency, , CurrentSessionDate(), vHotel), vHotel.FolioCurrency);
				EndIf;
			ElsIf vAdditionalInfo.Key = "GuestGroupPayments" Then
				vValue = "";
				If vGuestGroupAdditionalInfo.Payments > 0 Then
					vValue = cmFormatSum(cmConvertCurrencies(vGuestGroupAdditionalInfo.Payments, vGuestGroupAdditionalInfo.PaymentsCurrency, , vHotel.FolioCurrency, , CurrentSessionDate(), vHotel), vHotel.FolioCurrency);
				EndIf;
			ElsIf vAdditionalInfo.Key = "GuestGroupReservationInfo" Then
				vValue = "";
				vGuestListByNumber = vDocumentsListByRoomDataListCopy.FindRows(New Structure("GuestGroup", vGuestGroup));
				For Each vGuestListByNumberRow In vGuestListByNumber Do
					vMainGuest = Undefined;
					vNumberOfAdults = 0;
					vNumberOfTeenagers = 0;
					vNumberOfChildren = 0;
					vNumberOfInfants = 0;
					
					vGuestListArr = vDocumentsListByRoomDataList.FindRows(New Structure("GuestGroup, Number", vGuestGroup, vGuestListByNumberRow.Number));
					For Each vGuestListRow In vGuestListArr Do
						If vGuestListRow.AccommodationTemplate <> Catalogs.AccommodationTemplates.EmptyRef() Then
							vMainGuest = vGuestListRow.Ref;
						EndIf;
						
						vNumberOfAdults = vNumberOfAdults + vGuestListRow.NumberOfAdults;
						vNumberOfTeenagers = vNumberOfTeenagers + vGuestListRow.NumberOfTeenagers;
						vNumberOfChildren = vNumberOfChildren + vGuestListRow.NumberOfChildren;
						vNumberOfInfants = vNumberOfInfants + vGuestListRow.NumberOfInfants;
					EndDo;
					
					If Not ValueIsFilled(vMainGuest) Then
						Continue;
					EndIf;
					
					vRoomType = vMainGuest.RoomType;
					
					vValue = vValue + ?(IsBlankString(vValue), "", Chars.LF + Chars.LF) +
					StrTemplate(
					NStr("en = 'Reservation: %1 %2
					|%3 / %4
					|Guest: %5 %6
					|Room category: %7
					|Room: %8
					|Adults: %9 Children: %10'; de = 'Reservierung: %1 %2
					|%3 / %4
					|Gast: %5 %6
					|Zimmerkategorie: %7
					|Zimmer: %8
					|Erwachsene: %9 Kinder: %10'; ru = 'Бронь: %1 %2
					|%3 / %4
					|Гость: %5 %6
					|Категория номера: %7
					|Номер: %8
					|Взрослых: %9 Детей: %10'"),
					vMainGuest.Number, "(" +TrimAll(vMainGuest.RoomRate) + ")", Format(vMainGuest.CheckInDate, "DF=dd.MM.yyyy"), Format(vMainGuest.CheckOutDate, "DF=dd.MM.yyyy"),
					vMainGuest.GuestFullName, "(" + TrimAll(vMainGuest.DiscountType) + ")", TrimAll(vRoomType.Code) + " - " + TrimAll(vRoomType.Description),TrimAll(vMainGuest.Room),
					Format(vNumberOfAdults, "NFD=0; NZ=; NG="), Format(vNumberOfTeenagers + vNumberOfChildren + vNumberOfInfants, "NFD=0; NZ=; NG="));
				EndDo;
			ElsIf vAdditionalInfo.Key = "GuestGroupDiscountType" Then
				vValue = "";
				vClientDoc = vGuestGroupObj.ClientDoc;
				If ValueIsFilled(vClientDoc) Then
					vValue = TrimAll(vClientDoc.DiscountType);
				EndIf;
			ElsIf vAdditionalInfo.Key = "GuestGroupDiscountCardType" Then
				vValue = "";
				vClientDoc = vGuestGroupObj.ClientDoc;
				If ValueIsFilled(vClientDoc) Then
					vDiscountCard = Catalogs.DiscountCards.EmptyRef();
					If TypeOf(vClientDoc) = Type("DocumentRef.Folio") Then
						vDiscountCard = vClientDoc.FolioDiscountCard;
					Else
						vDiscountCard = vClientDoc.DiscountCard;
					EndIf;
					
					If ValueIsFilled(vDiscountCard) Then
						vValue = TrimAll(vDiscountCard.DiscountType);
					EndIf;
				EndIf;
			ElsIf vAdditionalInfo.Key = "IsCustomerPays" Then
				vPayer = vGuestGroupObj.pmSetPlannedPaymentMethod();
				vValue = Format(vPayer = Enums.WhoPays.Customer, "BF=N; BT=Y");
			ElsIf vAdditionalInfo.Key = "GuestGroupMarketingCode" Then
				vValue = "";
				
				vMarketingCode = vGuestGroupObj.MarketingCode;
				If Not ValueIsFilled(vMarketingCode) Then
					vClientDoc = vGuestGroupObj.ClientDoc;
					If ValueIsFilled(vClientDoc) Then
						vMarketingCode = vClientDoc.MarketingCode;
					EndIf;
				EndIf;
				
				If ValueIsFilled(vMarketingCode) Then
					vValue = TrimAll(vMarketingCode);
				EndIf;
			ElsIf vAdditionalInfo.Key = "GuestGroupRoomRate" Then
				vValue = "";
				
				vRoomRate = vGuestGroupObj.RoomRate;
				If Not ValueIsFilled(vRoomRate) Then
					vClientDoc = vGuestGroupObj.ClientDoc;
					If ValueIsFilled(vClientDoc) Then
						vRoomRate = vClientDoc.RoomRate;
					EndIf;
				EndIf;
				
				If ValueIsFilled(vRoomRate) Then
					vValue = StrTemplate("%1 - %2", TrimAll(vRoomRate.Code), TrimAll(vRoomRate.Description));
				EndIf;
			EndIf;
			If TypeOf(vValue) = Type("String") Then
				DataRow[vAdditionalInfo.Value] = vValue;
			Else
				DataRow[vAdditionalInfo.Value] = Format(vValue, "NZ=0; NG=");
			EndIf;
		EndDo;
	EndDo;
	
	Return vDataTable;
EndFunction // GetDataDealsToExport

// --------------------------------------------------------------------------------
Function GetGuestGroupURL(pGuestGroup, pExternalSystemInfoRef, rIntegration = Undefined)
	If Not ValueIsFilled(pGuestGroup) Then
		Return "";
	EndIf;
	
	vHotel = pGuestGroup.Owner;
	If rIntegration = Undefined Then
		rIntegration = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsGuestlink(vHotel);
	EndIf;
	
	If rIntegration = Undefined Then
		Return "";
	EndIf;
	
	vOnlineLink = TrimAll(rIntegration.HttpAddress);
	If IsBlankString(vOnlineLink) Then
		Return "";
	EndIf;
	
	vLang = Lower(TrimAll(vHotel.Language));
	If ValueIsFilled(pGuestGroup.Client) Then
		vLang = Lower(TrimAll(pGuestGroup.Client.Language));
	EndIf;
	
	If ValueIsFilled(pGuestGroup.ClientDoc) Then
		vCompany = pGuestGroup.ClientDoc.Company;
	Else
		vCompany = vHotel.Company;
	EndIf;
	
	vID = Catalogs.ExternalSystemInteractions.GetHotelID(rIntegration, vHotel, vCompany);
	
	vOnlineLink = vOnlineLink + "my.php?uuid=" + String(pGuestGroup.UUID()) + "&hotel=" + vID + ?(Not IsBlankString(vLang), "&lang=" + vLang, "");
	Return SMS.GetShortLink(vOnlineLink, pExternalSystemInfoRef.URLShortener);
EndFunction // GetGuestGroupURL

// --------------------------------------------------------------------------------
Function GetGuestGroupsInfo(pRefsArray, pExternalSystemInfoRef)
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	AccommodationStatuses.Ref AS Ref,
	|	AccommodationStatuses.IsActive AS IsActive,
	|	TRUE AS IsCheckIn
	|INTO StatusList
	|FROM
	|	Catalog.AccommodationStatuses AS AccommodationStatuses
	|WHERE
	|	NOT AccommodationStatuses.IsFolder
	|
	|UNION ALL
	|
	|SELECT
	|	ReservationStatuses.Ref,
	|	ReservationStatuses.IsActive
	|		OR ReservationStatuses.IsCheckIn
	|		OR ReservationStatuses.IsPreliminary,
	|	ReservationStatuses.IsCheckIn
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.IsFolder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroups.Ref AS GuestGroup,
	|	ISNULL(StatusList.IsActive, FALSE) AS IsActive,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS Hotel
	|INTO GuestGroupsList
	|FROM
	|	Catalog.GuestGroups AS GuestGroups
	|		LEFT JOIN StatusList AS StatusList
	|		ON GuestGroups.Status = StatusList.Ref
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON GuestGroups.Owner = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemInfoRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""Hotels"")
	|WHERE
	|	NOT GuestGroups.IsFolder
	|	AND NOT GuestGroups.DeletionMark
	|	AND GuestGroups.Ref IN(&qGuestGroups)
	|
	|INDEX BY
	|	GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Payments.GuestGroup AS GuestGroup,
	|	SUM(Payments.SumExpense) AS Sum,
	|	Payments.AccountingCurrency AS Currency
	|INTO PaymentsList
	|FROM
	|	AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
	|			,
	|			,
	|			PERIOD,
	|			RegisterRecordsAndPeriodBoundaries,
	|			GuestGroup IN
	|				(SELECT
	|					GuestGroupsList.GuestGroup AS GuestGroup
	|				FROM
	|					GuestGroupsList AS GuestGroupsList)) AS Payments
	|
	|GROUP BY
	|	Payments.GuestGroup,
	|	Payments.AccountingCurrency
	|
	|INDEX BY
	|	GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesList.GuestGroup AS GuestGroup,
	|	SUM(SalesList.Sum) AS Sum,
	|	SalesList.Currency AS Currency
	|INTO SalesList
	|FROM
	|	(SELECT
	|		SalesTurnovers.GuestGroup AS GuestGroup,
	|		SalesTurnovers.SalesTurnover AS Sum,
	|		SalesTurnovers.ReportingCurrency AS Currency
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				,
	|				,
	|				Period,
	|				GuestGroup IN
	|					(SELECT
	|						GuestGroupsList.GuestGroup
	|					FROM
	|						GuestGroupsList AS GuestGroupsList
	|					WHERE
	|						GuestGroupsList.IsActive)) AS SalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.GuestGroup,
	|		SalesForecastTurnovers.SalesTurnover,
	|		SalesForecastTurnovers.ReportingCurrency
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				,
	|				,
	|				Period,
	|				GuestGroup IN
	|					(SELECT
	|						GuestGroupsList.GuestGroup
	|					FROM
	|						GuestGroupsList AS GuestGroupsList
	|					WHERE
	|						GuestGroupsList.IsActive)) AS SalesForecastTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AccountsReceivableForecastTurnovers.GuestGroup,
	|		AccountsReceivableForecastTurnovers.ExpectedSalesTurnover,
	|		AccountsReceivableForecastTurnovers.FolioCurrency
	|	FROM
	|		AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|				,
	|				,
	|				Period,
	|				GuestGroup IN
	|					(SELECT
	|						GuestGroupsList.GuestGroup
	|					FROM
	|						GuestGroupsList AS GuestGroupsList
	|					WHERE
	|						NOT GuestGroupsList.IsActive)) AS AccountsReceivableForecastTurnovers) AS SalesList
	|
	|GROUP BY
	|	SalesList.GuestGroup,
	|	SalesList.Currency
	|
	|INDEX BY
	|	GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodation.Ref AS Ref,
	|	Accommodation.Number AS Number,
	|	Accommodation.NumberOfAdults AS NumberOfAdults,
	|	Accommodation.NumberOfTeenagers AS NumberOfTeenagers,
	|	Accommodation.NumberOfChildren AS NumberOfChildren,
	|	Accommodation.NumberOfInfants AS NumberOfInfants,
	|	Accommodation.GuestGroup AS GuestGroup,
	|	Accommodation.AccommodationTemplate AS AccommodationTemplate
	|INTO DocumentsListByRoom
	|FROM
	|	Document.Accommodation AS Accommodation
	|		INNER JOIN StatusList AS StatusList
	|		ON Accommodation.AccommodationStatus = StatusList.Ref
	|			AND (StatusList.IsActive)
	|		INNER JOIN GuestGroupsList AS GuestGroupsList
	|		ON Accommodation.GuestGroup = GuestGroupsList.GuestGroup
	|			AND (GuestGroupsList.IsActive)
	|WHERE
	|	Accommodation.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	Reservation.Ref,
	|	Reservation.Number,
	|	Reservation.NumberOfAdults,
	|	Reservation.NumberOfTeenagers,
	|	Reservation.NumberOfChildren,
	|	Reservation.NumberOfInfants,
	|	Reservation.GuestGroup,
	|	Reservation.AccommodationTemplate
	|FROM
	|	Document.Reservation AS Reservation
	|		INNER JOIN GuestGroupsList AS GuestGroupsList
	|		ON Reservation.GuestGroup = GuestGroupsList.GuestGroup
	|		INNER JOIN StatusList AS StatusList
	|		ON Reservation.ReservationStatus = StatusList.Ref
	|			AND (NOT StatusList.IsCheckIn)
	|WHERE
	|	Reservation.Posted
	|	AND CASE
	|			WHEN GuestGroupsList.IsActive
	|				THEN StatusList.IsActive
	|			ELSE NOT StatusList.IsActive
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomsReservedByGuestGroup.GuestGroup AS GuestGroup,
	|	SUM(RoomsReservedByGuestGroup.RoomsReserved) AS RoomsReserved
	|INTO RoomsReservedByGuestGroup
	|FROM
	|	(SELECT
	|		RoomInventory.GuestGroup AS GuestGroup,
	|		RoomInventory.ExpectedRoomsCheckedIn + RoomInventory.RoomsCheckedIn AS RoomsReserved
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventory
	|			INNER JOIN GuestGroupsList AS GuestGroupsList
	|			ON RoomInventory.GuestGroup = GuestGroupsList.GuestGroup
	|				AND (GuestGroupsList.IsActive)
	|	WHERE
	|		(RoomInventory.IsCheckIn
	|				OR RoomInventory.IsReservation)
	|		AND RoomInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND NOT RoomInventory.RoomType.DoesNotAffectRoomRevenueStatistics
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Reservation.GuestGroup,
	|		Reservation.NumberOfRooms
	|	FROM
	|		Document.Reservation AS Reservation
	|			INNER JOIN GuestGroupsList AS GuestGroupsList
	|			ON Reservation.GuestGroup = GuestGroupsList.GuestGroup
	|				AND (NOT GuestGroupsList.IsActive)
	|			INNER JOIN StatusList AS StatusList
	|			ON Reservation.ReservationStatus = StatusList.Ref
	|				AND (NOT StatusList.IsCheckIn)
	|				AND (NOT StatusList.IsActive)
	|	WHERE
	|		Reservation.Posted
	|		AND Reservation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)) AS RoomsReservedByGuestGroup
	|
	|GROUP BY
	|	RoomsReservedByGuestGroup.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsListByRoom.GuestGroup AS GuestGroup,
	|	SUM(DocumentsListByRoom.NumberOfAdults) AS NumberOfAdults,
	|	SUM(DocumentsListByRoom.NumberOfTeenagers) AS NumberOfTeenagers,
	|	SUM(DocumentsListByRoom.NumberOfChildren) AS NumberOfChildren,
	|	SUM(DocumentsListByRoom.NumberOfInfants) AS NumberOfInfants,
	|	MAX(ISNULL(RoomsReservedByGuestGroup.RoomsReserved, 0)) AS RoomsReserved
	|INTO DocumentsList
	|FROM
	|	DocumentsListByRoom AS DocumentsListByRoom
	|		LEFT JOIN RoomsReservedByGuestGroup AS RoomsReservedByGuestGroup
	|		ON DocumentsListByRoom.GuestGroup = RoomsReservedByGuestGroup.GuestGroup
	|
	|GROUP BY
	|	DocumentsListByRoom.GuestGroup
	|
	|INDEX BY
	|	GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroupsList.GuestGroup AS GuestGroup,
	|	GuestGroupsList.Hotel AS Hotel,
	|	ISNULL(SalesList.Sum, 0) AS Sales,
	|	ISNULL(SalesList.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS SalesCurrency,
	|	ISNULL(PaymentsList.Sum, 0) AS Payments,
	|	ISNULL(PaymentsList.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS PaymentsCurrency,
	|	ISNULL(DocumentsList.NumberOfAdults, 0) AS NumberOfAdults,
	|	ISNULL(DocumentsList.NumberOfTeenagers, 0) AS NumberOfTeenagers,
	|	ISNULL(DocumentsList.NumberOfChildren, 0) AS NumberOfChildren,
	|	ISNULL(DocumentsList.NumberOfInfants, 0) AS NumberOfInfants,
	|	ISNULL(DocumentsList.RoomsReserved, 0) AS RoomsReserved
	|FROM
	|	GuestGroupsList AS GuestGroupsList
	|		LEFT JOIN SalesList AS SalesList
	|		ON GuestGroupsList.GuestGroup = SalesList.GuestGroup
	|		LEFT JOIN PaymentsList AS PaymentsList
	|		ON GuestGroupsList.GuestGroup = PaymentsList.GuestGroup
	|		LEFT JOIN DocumentsList AS DocumentsList
	|		ON GuestGroupsList.GuestGroup = DocumentsList.GuestGroup
	|
	|ORDER BY
	|	GuestGroup";
	vQ.SetParameter("qExternalSystemInfoRef", pExternalSystemInfoRef);
	vQ.SetParameter("qGuestGroups", pRefsArray);
	Return vQ.ExecuteBatchWithIntermediateData()
EndFunction // GetGuestGroupsInfo

// --------------------------------------------------------------------------------
// Imports clients that were changed in Bitrix24 by the array of such client's ids
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  LogDataContainer		 - String								 - Messages
//  IDsArrayToImport		 - Array								 - IDsArrayToImport
//  pIsBackgroundJob		 - Boolean								 - IsBackgroundJob
//  pDataType				 - String								 - Fields
// 
// Returns:
//  Structure - Result
//
Function ImportData(pExternalSystemInfoRef, pLogDataContainer = Undefined, pIDsArrayToImport = Undefined, pIsBackgroundJob = False, pDataType) Export
	vResult = New Structure("Created, Found, Failed, Message", 0, 0, 0, "");
	pLogDataContainer = LogDataInit("Integration with B24. Import clients", pExternalSystemInfoRef);
	
	vApiConnectionProps = GetConnectionProps(pExternalSystemInfoRef, pLogDataContainer);
	vStrOperationName = GetNString(vApiConnectionProps.Server, "Импорт изменений с портала Битрикс 24 %1", "Changes import from Bitrix 24 portal %1");
	vOperationID = LogDataStart(pLogDataContainer, vStrOperationName);
	vApiConnection = ApiConnectionInit(pExternalSystemInfoRef, vApiConnectionProps, pLogDataContainer);
	
	If vApiConnection = Undefined Then
		LogDataFinish(pLogDataContainer, vOperationID);
		Return vResult;
	EndIf;
	
	If pIDsArrayToImport = Undefined Then
		pIDsArrayToImport = GetDataChangesToImport(pExternalSystemInfoRef, vApiConnection, vApiConnectionProps, pLogDataContainer, pDataType);
	EndIf;
	
	If pIDsArrayToImport = Undefined Or pIDsArrayToImport.Count() = 0 Then
		LogDataFinish(pLogDataContainer, vOperationID);
		LogDataWrite(pLogDataContainer);
		vResult.Message = NStr("en='Download is canceled. There are no changes for download.'; ru='Загрузка отменена. Изменений для загрузки нет.'; de='Download abgebrochen. Es gibt keine Änderungen zum Herunterladen.'");
		Return vResult;
	EndIf;
	
	vFieldPMSCode = Undefined;
	If pDataType = "Clients" Then
		vFieldsTable = CreateAttributesTableForClients(pExternalSystemInfoRef);
		
		vClientFieldPMSFieldsTableArr = vFieldsTable.FindRows(New Structure("Attribute1C", "Code"));
		If vClientFieldPMSFieldsTableArr.Count() > 0 Then
			vFieldPMSCode = vClientFieldPMSFieldsTableArr[0].AttributeB24;
		EndIf;
	ElsIf pDataType = "Customers" Then
		vFieldsTable = CreateAttributesTableForCustomers(pExternalSystemInfoRef);
	EndIf;
	
	vFieldsMap = New Map;
	vRequestString = GetApiMethod(pDataType, "", "List") + "?filter[ID]={ID}";
	vFielsToImport = vFieldsTable.FindRows( New Structure("DirectionIn", True) );
	
	For Each vFieldsRow In vFielsToImport Do
		vRequestString = vRequestString + "&select[]=" + vFieldsRow.AttributeB24;
		vFieldsMap.Insert(vFieldsRow.AttributeB24, vFieldsRow.Attribute1C);
	EndDo;
	
	vSuccessCounter = 0;
	vErrorsCounter = 0;
	vTableOfData = GetDataByBitrixIds(pIDsArrayToImport, pExternalSystemInfoRef, pDataType);
	
	vDatas = New Map;
	vRequestDatas = New Map;
	vFindTINDatas = New Map;
	
	vDataTableCount = vTableOfData.Count() - 1;
	For vDataNumber = 0 To vDataTableCount Do
		vSingleDataRow = vTableOfData[vDataNumber];
		vDataUUID = "D" + vSingleDataRow.ID;
		
		If Not ValueIsFilled(vSingleDataRow.Ref) And pDataType = "Customers" Then
			vFindCustomerRequestString = "crm.requisite.list?select[]=RQ_INN&filter[ENTITY_TYPE_ID]=4&filter[ENTITY_ID]=" + Format(vSingleDataRow.ID, "NZ=0; NG=");
			vFindTINDatas.Insert(vDataUUID, vFindCustomerRequestString);
		EndIf;
		
		vDatas.Insert(vDataUUID, vSingleDataRow);
		If vDatas.Count() < 50 And vDataNumber <> vDataTableCount Then
			Continue;
		EndIf;
		
		If vFindTINDatas.Count() > 0 Then
			vAnswerStructure = ExecuteApiRequestBatchJSON(vApiConnection, vApiConnectionProps, vFindTINDatas, Undefined, 0, pExternalSystemInfoRef);
			vAnswerResult = GetPropertyOfStructure(vAnswerStructure, "result.result");
			If vAnswerResult = Undefined Then
				vDatas = New Map;
				vRequestDatas = New Map;
				vFindTINDatas = New Map;
				Continue;
			EndIf;
			
			For Each vAnswerResultRow In vAnswerResult Do
				vAnswerResultRowValue = vAnswerResultRow.Value;
				vAnswerResultRowKey = vAnswerResultRow.Key;
				
				If TypeOf(vAnswerResultRowValue) = Type("Array") Then
					For Each vFindClientResultRow In vAnswerResultRowValue Do
						vDatas[vAnswerResultRowKey].TIN = TrimAll(vFindClientResultRow.RQ_INN);
						Break;
					EndDo;
				EndIf;
			EndDo;
			vFindTINDatas = New Map;
			cmWait(1);
		EndIf;
		
		For Each vDataRow In vDatas Do
			vSingleData = vDataRow.Value;
			vRequestDatas.Insert(vDataRow.Key, StrReplace(vRequestString, "{ID}", vSingleData.ID));
		EndDo;
		
		vImportResult = ImportSingleDataRow(vApiConnection, vApiConnectionProps, vRequestDatas, vDatas, vFieldsMap, pExternalSystemInfoRef, pDataType, vFieldPMSCode);
		vResult.Found = vResult.Found + vImportResult.Found;
		vResult.Created = vResult.Created + vImportResult.Created;
		vResult.Failed = vResult.Failed + vImportResult.Failed;
		vSuccessCounter = vSuccessCounter + vImportResult.Success;
		
		vDatas = New Map;
		vRequestDatas = New Map;
		
		If pIsBackgroundJob Then
			vMessageStructure = New Structure;
			vMessageStructure.Insert("Percent", (vDataNumber * 100) / (vDataTableCount + 1));
			vMessageStructure.Insert("Count", vDataNumber);
			vMessage = Catalogs.DataConvertationRules.MapToJSON(vMessageStructure);
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
	EndDo;
	
	vMessageParamsArray = New Array;
	vMessageParamsArray.Add(ConvertNumberToString(vSuccessCounter));
	vMessageParamsArray.Add(ConvertNumberToString(vErrorsCounter));
	vResult.Message = GetNString(vMessageParamsArray, "%1 загружены успешно и у %2 возникли ошибки", "%1 were imported successful and %2 has errors");
	
	Return vResult;
EndFunction // ImportData

// --------------------------------------------------------------------------------
// Looks up the client with addition parameters such as Last name, 
// phone number, email in case it has no BItrix 24 ID.
//
// Parameters:
//  pExternalSystemRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  LastName			 - String								 - LastName
//  Email				 - String								 - Email
//  Phone				 - String								 - Phone
//  FirstName			 - String								 - FirstName
//  SecondName			 - String								 - SecondName
//  DateOfBirth			 - Date									 - DateOfBirth
// 
// Returns:
//  CatalogRef.Clients - Ref
//
Function FindClientByAdditionalFields(pExternalSystemRef, LastName, Email, Phone, FirstName = Undefined, SecondName = Undefined, DateOfBirth = Undefined, pPMSCode = Undefined) Export
	
	ClientFound		=	PredefinedValue("Catalog.Clients.EmptyRef");
	
	If pPMSCode <> Undefined And Not IsBlankString(pPMSCode) Then
		vPMSCode = pPMSCode;
		If cmIsNumber(vPMSCode) Then
			vPMSCode = Format(Number(vPMSCode), "ND=12; NZ=; NLZ=; NG=");
		EndIf;
		vClientByPMSCode = Catalogs.Clients.FindByCode(vPMSCode);
		If vClientByPMSCode <> Undefined And Not IsBlankString(vClientByPMSCode.DataVersion) Then
			Return vClientByPMSCode;
		EndIf;
	EndIf;
	
	vEmails = New Array;
	vPhones = New Array;
	If TypeOf(Email) = Type("Array") Then
		For Each vRow in Email Do
			vEmails.Add(vRow.VALUE);
		EndDo;
	Else
		vEmails.Add(Email);
	EndIf;
	
	If TypeOf(Phone) = Type("Array") Then
		For Each vRow in Phone Do
			vPhone   = SMS.GetValidPhoneNumber(vRow.VALUE);
			vPhone   = StrReplace(vPhone, "+", "");
			vPhones.Add(vPhone);
		EndDo;
	Else
		vPhone   = SMS.GetValidPhoneNumber(Phone);
		vPhone   = StrReplace(vPhone, "+", "");
		vPhones.Add(vPhone);	
	EndIf;
	
	vDateOfBirth = Undefined;
	If DateOfBirth <> Undefined And TypeOf(DateOfBirth) = Type("String") Then
		vDateOfBirth = StrReplace(DateOfBirth, "-", "");
		vDateOfBirth = Left(vDateOfBirth, 8);
		Try
			vDateOfBirth = Date(vDateOfBirth);
		Except
			vDateOfBirth = Undefined;
		EndTry;
	EndIf;
	
	If (LastName = Undefined OR IsBlankString(LastName)) OR (vEmails.Count() = 0 And vPhones.Count() = 0) Then
		
		Return ClientFound;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Clients.Ref AS Ref,
	|	Clients.Phone AS Phone,
	|	Clients.EMail AS EMail,
	|	Clients.Code AS Code
	|INTO ClientsByNameAndBirthDate
	|FROM
	|	Catalog.Clients AS Clients
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""clients"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND Clients.Ref = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	NOT Clients.DeletionMark
	|	AND Clients.LastName = &LastName
	|	AND (CASE
	|				WHEN &FirstNameFilled
	|					THEN Clients.FirstName = &FirstName
	|				ELSE TRUE
	|			END
	|			OR Clients.FirstName = """")
	|	AND (CASE
	|				WHEN &SecondNameFilled
	|					THEN Clients.SecondName = &SecondName
	|				ELSE TRUE
	|			END
	|			OR Clients.SecondName = """")
	|	AND (CASE
	|				WHEN &DateOfBirthFilled
	|					THEN Clients.DateOfBirth = &DateOfBirth
	|				ELSE TRUE
	|			END
	|			OR Clients.DateOfBirth = &EmptyDate)
	|	AND ExternalSystemIntegrationData.ExternalSystemDataCode IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	ClientsByNameAndBirthDate.Ref AS Ref
	|FROM
	|	ClientsByNameAndBirthDate AS ClientsByNameAndBirthDate
	|WHERE
	|	(ClientsByNameAndBirthDate.Phone IN (&Phones)
	|			OR ClientsByNameAndBirthDate.EMail IN (&Emails)
	|			OR ClientsByNameAndBirthDate.Phone = """"
	|				AND ClientsByNameAndBirthDate.EMail = """")
	|
	|ORDER BY
	|	ClientsByNameAndBirthDate.Code DESC";
	
	Query.SetParameter("DateOfBirth", 			vDateOfBirth);
	Query.SetParameter("DateOfBirthFilled", 	ValueIsFilled(vDateOfBirth));
	Query.SetParameter("Emails", 				vEmails);
	Query.SetParameter("FirstName", 			FirstName);
	Query.SetParameter("FirstNameFilled", 		ValueIsFilled(FirstName));
	Query.SetParameter("LastName", 				LastName);
	Query.SetParameter("Phones", 				vPhones);
	Query.SetParameter("SecondName", 			SecondName);
	Query.SetParameter("SecondNameFilled", 		ValueIsFilled(SecondName));
	Query.SetParameter("EmptyDate", 			Date("00010101"));
	Query.SetParameter("qExternalSystemRef", 	pExternalSystemRef);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		ClientFound = SelectionDetailRecords.Ref; 
	EndDo;
	
	Return ClientFound;
	
EndFunction //  FindClientByAdditionalFields()

// --------------------------------------------------------------------------------
// Initializes the properties for http conection to the API server.
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  LogData					 - String								 - Messages
// 
// Returns:
//  Structure - Structure with connection properties
//
Function GetConnectionProps(ExternalSystemInfoRef, LogData = Undefined) Export
	
	// 01. Main structure init.
	DataStructure		=	New Structure;
	
	// 02. Gettind http connection infj with Request.
	Query				=	New Query;
	Query.Text			= 
	"SELECT
	|	ExternalSystemInteractions.Ref AS ExternalSystemInfo,
	|	ExternalSystemInteractions.HttpServer AS Server,
	|	ExternalSystemInteractions.HttpPort AS Port,
	|	ExternalSystemInteractions.HttpUseSsl AS UseSsl,
	|	ExternalSystemInteractions.OAuth_RefreshToken AS RefreshToken,
	|	ExternalSystemInteractions.OAuth_AccessToken AS Token,
	|	ExternalSystemInteractions.InteractionID AS InteractionID,
	|	ExternalSystemInteractions.Login AS Login,
	|	ExternalSystemInteractions.Password AS Password
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	ExternalSystemInteractions.Ref = &Ref";
	
	Query.SetParameter("Ref", ExternalSystemInfoRef);
	
	RequestResult			=	Query.Execute();
	
	For Each currentCol In RequestResult.Columns Do
		
		DataStructure.Insert(currentCol.Name);
		
	EndDo;
	
	If NOT RequestResult.IsEmpty() Then
		
		FillPropertyValues(DataStructure, RequestResult.Unload()[0]);
		
	EndIf;
	
	
	// 03. Check fo errors.
	If NOT ValueIsFilled(DataStructure.Server) And LogData <> Undefined Then
		
		strError		=	GetNString(ExternalSystemInfoRef, "Для %1 не указан сервер");
		LogDataAdd(LogData, strError, TRUE);
		
	EndIf;
	
	
	// 04. Finish.
	Return DataStructure;
	
EndFunction //  GetConnectionProps()

// --------------------------------------------------------------------------------
// API connection initialization.
//
// Parameters:
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  ApiConnectionProps		 - Structure							 - ApiConnectionProps
//  LogDataContainer		 - String								 - Messages
// 
// Returns:
//  HTTPConnection
//
Function ApiConnectionInit(ExternalSystemInfoRef, ApiConnectionProps = Undefined, LogDataContainer = Undefined) Export
	
	// 01. Connection properties init.
	If ApiConnectionProps = Undefined Then
		
		ApiConnectionProps	=	GetConnectionProps(ExternalSystemInfoRef, LogDataContainer);
		
	EndIf;
	
	ssl						=	?(ApiConnectionProps.UseSsl = True, New OpenSSLSecureConnection, Undefined);
	
	
	// 02. HTTP connection init.
	Try
		
		Connection			=	New HTTPConnection(ApiConnectionProps.Server, ApiConnectionProps.Port, , , , ,ssl);
		
		strMessage			=	GetNString(ApiConnectionProps.Server, "Соединение с сервером %1 установлено", "Connected to the API server %1");
		LogDataAdd(LogDataContainer, strMessage, False);
		
	Except
		
		strError			=	GetNString(ApiConnectionProps.Server, "Не удалось установить соединение с сервером %1. Проверьте правильность данных подключения", "Can not connect to the API server %1. Please validate your connection properties");
		LogDataAdd(LogDataContainer, strError, True);
		
	EndTry;
	
	
	// 03. Finish;
	Return Connection;
	
EndFunction //  ApiConnectionInit()

// --------------------------------------------------------------------------------
//  Description: Makes http request to API server.
//
// Parameters:
//  ApiConnection			 - Structure							 - ApiConnection
//  ApiConnectionProps		 - Structure							 - ApiConnectionProps
//  Method					 - String								 - Method
//  RequestData				 - String								 - RequestData
//  LogDataContainer		 - String								 - LogDataContainer
//  ReturnAs				 - Number								 - ReturnAs
//  Counter					 - Number								 - Counter
//  ExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  rUpdateFailed			 - Boolean								 - UpdateFailed
//  pClientID				 - String								 - ClientID
//  pDataType				 - String								 - DataType
// 
// Returns:
//  String - HttpAnswer
//
Function ExecuteApiRequest(ApiConnection, ApiConnectionProps, val Method = "", RequestData = "", LogDataContainer = Undefined, ReturnAs = 1, Counter = 0, ExternalSystemInfoRef, rUpdateFailed = False, pClientID = "", pDataType) Export
	
	Counter					=	Counter + 1;
	BodyRequestArray		=	New Array;
	
	// 01. Params init for batch or simple Request.
	If TypeOf(RequestData)	 = Type("Array") Then
		
		// 01. Compose Request text.
		For Each RequestItem In RequestData Do
			
			BodyRequestArray.Add("cmd[]=" + Method + "?" + RequestItem);
			
		EndDo;
		
		// 02. use batch method to Execute multiple Request.
		UseMethod			=	"batch";
		
	ElsIf NOT IsBlankString(RequestData) Then
		
		// 03. Simple Request.
		UseMethod			=	Method + "?" + RequestData;
		
	Else
		
		UseMethod			=	Method;
		
	EndIf;
	
	BodyRequestForLog	=	StrConcat(BodyRequestArray, "&");
	
	
	// 02. Http Request init.
	HttpRequest			=	Новый HTTPRequest("/rest/" + UseMethod);
	HttpRequest.Headers.Insert("Content-Type",		"application/x-www-form-urlencoded; charset=utf-8");
	
	BodyRequestArray.Insert(0, "auth=" + ApiConnectionProps.Token);
	BodyRequestArray.Add("LastParametr=LastParameterValue"); // 1C could cut chars, so add this parametr to be unusefull.
	
	HttpRequest.SetBodyFromString( StrConcat(BodyRequestArray, "&") );
	
	
	// 03. Http Request answer. 
	HttpAnswer			=	SendHTTPRequest(ExternalSystemInfoRef, , HttpRequest.ResourceAddress, "POST", , , , , , ,ApiConnection, HttpRequest);//ApiConnection.Post(HttpRequest);
	strHttpAnswer	 	=	HttpAnswer.Body;
	strHttpAnswer		=	ConvertSpecCharsToString(strHttpAnswer);
	
	strMessage			=	"..." + HttpRequest.ResourceAddress + ?(IsBlankString(BodyRequestForLog), "", "?") + BodyRequestForLog;
	LogDataAdd(LogDataContainer, strMessage);
	
	// 04. Check answer for errors.
	If HttpAnswer.StatusCode = 503 Then
		
		// Too many Requests.
		strError		=	GetNString(ApiConnectionProps.Server, "Слишком много запросов в секунду, сервер %1 ответил отказом", "Too many Requests per second, server %1 refused");
		LogDataAdd(LogDataContainer, strError, True);
		
		If Counter < 3 Then
			
			strMessage		=	GetNString(, "Включена пауза для снятия нагрузки на сервер запросов", "Requests a paused to prevent server overload");
			LogDataAdd(LogDataContainer, strMessage, True);
			cmWait(1);
			Return ExecuteApiRequest(ApiConnection, ApiConnectionProps, Method, RequestData, LogDataContainer, ReturnAs, Counter, ExternalSystemInfoRef, rUpdateFailed, pClientID, pDataType);
			
		Else
			
			Return Undefined;
			
		EndIf;
		
	ElsIf ( strPos(strHttpAnswer, "expired_token") OR strPos(strHttpAnswer, "no_auth_found") OR strPos(strHttpAnswer, "invalid_token") )
		And Counter = 1 
		And RefreshAccessTokenB24(ApiConnectionProps, LogDataContainer) Then // Temporary instead of RefreshAccessTokenB24
		
		Return ExecuteApiRequest(ApiConnection, ApiConnectionProps, Method, RequestData, LogDataContainer, ReturnAs, Counter, ExternalSystemInfoRef, rUpdateFailed, pClientID, pDataType);
	ElsIf strPos(strHttpAnswer, "not found") > 0 And Counter = 1 Then	
		If ValueIsFilled(pDataType) Then
			ClientApiMethods		=	New Structure;
			ClientApiMethods.Insert("Add",		GetApiMethod(pDataType, "", "Add"));
			ClientApiMethods.Insert("Update",	GetApiMethod(pDataType, "", "Update"));
			
			If strPos(Method, ClientApiMethods.Update) > 0 Then
				rUpdateFailed = True;
				Method = StrReplace(Method, ClientApiMethods.Update, ClientApiMethods.Add);
				Method = StrReplace(Method, "id=" + ConvertNumberToString(pClientID), "");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalSystemInfoRef, ClientApiMethods.Add, Enums.ExternalSystemEventTypes.Warning, Method, strHttpAnswer, "Failed to update " + pDataType + ", trying to ADD");
				
				Return ExecuteApiRequest(ApiConnection, ApiConnectionProps, Method, RequestData, LogDataContainer, ReturnAs, Counter, ExternalSystemInfoRef, rUpdateFailed, , pDataType);
			EndIf;
		Else
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalSystemInfoRef, "Bitrix24.ExecuteApiRequest", Enums.ExternalSystemEventTypes.Error, Method, strHttpAnswer, "Failed to get or update data");	
		EndIf;
		
	ElsIf HttpAnswer.StatusCode <> 200 Then
		
		LogDataAdd(LogDataContainer, strHttpAnswer, True);
		
		Return Undefined;
		
	EndIf;
	
	
	// 05. Retun data from the answer map.
	If ReturnAs = 0 Then
		
		Return HttpAnswer;
		
	ElsIf ReturnAs = 1 Then
		
		Return ConvertJsonToStructure(strHttpAnswer, LogDataContainer);
		
	ElsIf ReturnAs = 2 Then
		
		Return ConvertJsonToMap(strHttpAnswer, LogDataContainer);
		
	ElsIf ReturnAs = 3 Then
		
		Return strHttpAnswer;
		
	EndIf;
	
EndFunction //  ExecuteApiRequest()

// --------------------------------------------------------------------------------
//
// Parameters:
//  pApiConnection			 - Structure							 - ApiConnection
//  pApiConnectionProps		 - Structure							 - ApiConnectionProps
//  pRequestDataArray		 - Structure							 - RequestData
//  pLogDataContainer		 - Structure							 - LogDataContainer
//  rCounter				 - Number								 - Counter
//  pExternalSystemInfoRef	 - CatalogRef.ExternalSystemInteractions - 
// 
// Returns:
//  Structure - HttpAnswer
//
Function ExecuteApiRequestBatchJSON(pApiConnection, pApiConnectionProps, pRequestDatas, pLogDataContainer, rCounter, pExternalSystemInfoRef, pHalt = 0) Export
	rCounter = rCounter + 1;
	
	vCommandsMap = New Structure;
	vCommandsMap.Insert("halt", pHalt);
	vCommandsMap.Insert("cmd", pRequestDatas);
	vCommandsMap.Insert("auth", pApiConnectionProps.Token);
	
	vCommands = tcConnectedHardwareOnClientServer.MapToJson(vCommandsMap);
	
	HttpRequest = New HTTPRequest("/rest/batch");
	HttpRequest.Headers.Insert("Content-Type", "application/json");
	HttpRequest.SetBodyFromString(vCommands);
	
	vHttpAnswer = SendHTTPRequest(pExternalSystemInfoRef, , HttpRequest.ResourceAddress, "POST", , , , , , , pApiConnection, HttpRequest);

	vStrMessage = "..." + HttpRequest.ResourceAddress;
	LogDataAdd(pLogDataContainer, vStrMessage);
	
	If vHttpAnswer.StatusCode = 503 Then
		vStrError = GetNString(pApiConnectionProps.Server, "Слишком много запросов в секунду, сервер %1 ответил отказом", "Too many Requests per second, server %1 refused");
		LogDataAdd(pLogDataContainer, vStrError, True);
		
		If rCounter < 3 Then
			vStrMessage = GetNString(, "Включена пауза для снятия нагрузки на сервер запросов", "Requests a paused to prevent server overload");
			LogDataAdd(pLogDataContainer, vStrMessage, True);
			cmWait(1);
			Return ExecuteApiRequestBatchJSON(pApiConnection, pApiConnectionProps, pRequestDatas, pLogDataContainer, rCounter, pExternalSystemInfoRef);
		Else
			Return Undefined;
		EndIf;
	ElsIf vHttpAnswer.StatusCode = 401 And rCounter = 1 And RefreshAccessTokenB24(pApiConnectionProps, pLogDataContainer) Then
		Return ExecuteApiRequestBatchJSON(pApiConnection, pApiConnectionProps, pRequestDatas, pLogDataContainer, rCounter, pExternalSystemInfoRef);
	ElsIf vHttpAnswer.StatusCode <> 200 Then
		LogDataAdd(pLogDataContainer, vHttpAnswer.Body, True);
		Return Undefined;
	EndIf;
	
	Return ConvertJsonToStructure(vHttpAnswer.Body, pLogDataContainer);
EndFunction // ExecuteApiRequestJSON

// --------------------------------------------------------------------------------
// Makes an http request to get file via URL presented.
//
// Parameters:
//  ApiConnection	 - Structure
//  Address			 - String
//  LogDataContainer - String
// 
// Returns:
//  BinaryData - Binary data if sucess and Undefined if failed
//
Function GetFileByUrl(ApiConnection, Address, LogDataContainer = Undefined) Export
	
	// 01. Operation init.
	ResultBinaryData	=	Undefined;
	IemOperationName	=	GetNString(, "Получение файла", "Getting file");
	OperationId			=	LogDataStart(LogDataContainer, IemOperationName);
	
	
	// 02. Getting file.
	tmpFile				=	GetTempFileName();
	HttpAnswer			=	ApiConnection.Post( New HTTPRequest(Address), tmpFile );
	
	FileOnDisk			=	New File(tmpFile);
	FileExist			=	tcCommonFunctionOnClientServer.cmExists(FileOnDisk) And FileOnDisk.IsFile() And FileOnDisk.Size() > 0;
	
	LogDataAdd(LogDataContainer, "file url request ..." + Address);
	
	If HttpAnswer.StatusCode <> 200 OR NOT FileExist Then
		
		strError		=	GetNString(, "Получен некорректный результат файла: %1", "Incorrect file result has been got: %1");
		LogDataAdd(LogDataContainer, strError, True);
		
	Else
		
		ResultBinaryData=	New BinaryData(tmpFile);
		
		try DeleteFiles(tmpFile); Except EndTry;
		
	EndIf;
	
	
	LogDataFinish(LogDataContainer, OperationId);
	
	Return ResultBinaryData;
	
EndFunction //  GetFileByUrl()

// --------------------------------------------------------------------------------
//  GetBitrix24DealField
//
// Parameters:
//  ExternalSystemInfoRef	 - ExternalSystemInfoRef - External system interactions
//  pDealID					 - String				 - DealID
//  pField					 - String				 - Field
// 
// Returns:
//  String - Result
//
Function GetBitrix24DealField(ExternalSystemInfoRef, pDealID, pField) Export
	
	vResult = "";
	
	vMethod = "crm.deal.get?id=" + pDealID;
	
	ApiConnectionProps		=	GetConnectionProps(ExternalSystemInfoRef, Undefined);
	
	// 02. API connection init.
	ApiConnection			=	ApiConnectionInit(ExternalSystemInfoRef, ApiConnectionProps);
	
	If ApiConnection = Undefined Then
		
		Return vResult;
		
	EndIf;
	
	vResponse = ExecuteApiRequest(ApiConnection, ApiConnectionProps, vMethod, , , , , ExternalSystemInfoRef, , , "");
	If vResponse <> Undefined And vResponse.result <> Undefined Then
		vResult = vResponse.result[?(Not IsBlankString(pField), pField, "UF_CRM_HOTEL")];
	EndIf;
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
//  Description: Gets new token when we have no Refresh_token.
//
// Parameters:
//  ApiConnectionProps	 - Structure - ApiConnectionProps
//  LogDataContainer	 - String	 - LogDataContainer
//  pAuthCode			 - String	 - AuthCode
// 
// Returns:
//  Boolean - True in success
//
Function GetNewAccessTokenB24(ApiConnectionProps, LogDataContainer = Undefined, pAuthCode = Undefined) Export
	
	// 01. Init connection.
	AccessToken				=	Undefined;
	RefreshToken			=	Undefined;
	AuthServer = "oauth.bitrix.info";
	
	strOperationName		=	GetNString(ApiConnectionProps.Server, "Получение нового токена для портала Битрикс 24 %1", "New token Request for Bitrix 24 portal %1");
	OperationID				=	LogDataStart(LogDataContainer, strOperationName);
	
	ssl						=	?(ApiConnectionProps.UseSsl = True, New OpenSSLSecureConnection, Undefined);
	//StartConnection			=	New HTTPConnection(ApiConnectionProps.Server, ApiConnectionProps.Port, ApiConnectionProps.Login, ApiConnectionProps.Password,,, ssl);
	StartConnection			=	New HTTPConnection(AuthServer, 443, , , , , ssl);
	
	If StartConnection = Undefined Then
		
		strError		=	GetNString(ApiConnectionProps.Server, "Невозможно подключиться к серверу: %1", "Unable to connect to the server: %1");
		LogDataFinish(LogDataContainer, OperationID, strError, True);
		Return False;
		
	EndIf;
	
	
	Code 			= pAuthCode;
	
	If Code = Undefined Then
		// 02. Getting redirect URL.
		Headers					=	New Map;
		HttpRequest				=	New HttpRequest("oauth/authorize/?client_id=" + AppCode(), Headers);
		HTTPResponse			=	StartConnection.Get(HttpRequest);
		
		If HTTPResponse.StatusCode <> 302 And HTTPResponse.StatusCode <> 200 Then
			
			strError		=	GetNString(HTTPResponse.StatusCode, "Сервер авторизации должен был вернуть статус 302, но вернул %1", "Authorization server had to response 302 but returned %1");
			LogDataFinish(LogDataContainer, OperationID, strError, True);
			Return False;
			
		EndIf;
		
		
		// 03. Getting Code value.
		Cookie					=	HTTPResponse.Headers.Get("Set-Cookie");
		Code					= 	cmGetAuthCode(HTTPResponse);
		
		If NOT ValueIsFilled(Code) Then
			strError		=	GetNString(, "Сервер авторизации не вернул код для авторизации", "Authorization server haven't returned Code value");
			LogDataFinish(LogDataContainer, OperationID, strError, True);
			Return False;
		EndIf;
		
	EndIf;
	
	// 04. Getting access token Request.
	//StartConnection			=	New HTTPConnection(ApiConnectionProps.Server, ApiConnectionProps.Port,,,,, ssl);
	StartConnection			=	New HTTPConnection(AuthServer, 443, , , , , ssl);
	
	HttpRequest = New HTTPRequest("oauth/token/?grant_type=authorization_code&client_id=" + AppCode() + "&client_secret=" + ClientSecret() + "&code=" + Code);
	HttpRequest.Headers.Insert("Cookie",	Cookie);
	
	HTTPResponse			=	StartConnection.Get(HttpRequest);
	
	TokenHasBeenWritten		=	WriteTokensFromHttpResponse(HTTPResponse, ApiConnectionProps, LogDataContainer);
	
	LogDataFinish(LogDataContainer, OperationID);
	
	Return TokenHasBeenWritten
	
EndFunction //  GetNewAccessTokenB24()

// --------------------------------------------------------------------------------
//  Description: Makes api request and writes access + refresh tokens to External system objest then.
//
// Parameters:
//  ApiConnectionProps	 - Structure - ApiConnectionProps
//  LogDataContainer	 - String	 - LogDataContainer
// 
// Returns:
//  Boolean - True in success
//
Function RefreshAccessTokenB24(ApiConnectionProps, LogDataContainer = Undefined) Экспорт
	
	strOperationName		=	GetNString(ApiConnectionProps.Server, "Обновление токена для портала Битрикс 24 %1", "Token refreshing for Bitrix 24 portal %1");
	OperationID				=	LogDataStart(LogDataContainer, strOperationName);
	AuthServer 				=	"oauth.bitrix.info";
	
	// 01. Check parameters for token refresh avalibility.
	If IsBlankString(ApiConnectionProps.RefreshToken) Then
		
		If IsBlankString(ApiConnectionProps.Login) OR IsBlankString(ApiConnectionProps.Server) OR IsBlankString(ApiConnectionProps.Port) Then
			
			strError			=	GetNString(ApiConnectionProps.Server, "Для поратала Битрикс 24 %1 не установлены первоначальные настройки обновления токена", "The initial settings to refresh token for Bitrix 24 portal %1 haven't been set yet");
			LogDataFinish(LogDataContainer, OperationID, strError, True);
			
			Return False;
			
		Else
			
			TokenHasBeenWritten	=	GetNewAccessTokenB24(ApiConnectionProps, LogDataContainer);
			LogDataFinish(LogDataContainer, OperationID);
			
			Return TokenHasBeenWritten;
			
		EndIf;
		
	EndIf;
	
	
	// 02. Get refres token info.
	
	ApiConnection		=	New HTTPConnection(AuthServer, 443, , , , , New OpenSSLSecureConnection);
	
	If ApiConnection = Undefined Then
		
		LogDataFinish(LogDataContainer, OperationID);
		Return False;
		
	EndIf;
	
	RequestString			=	"/oauth/token/?grant_type=refresh_token&client_id=" + AppCode() + "&client_secret=" + ClientSecret() + "&refresh_token=" + ApiConnectionProps.RefreshToken;
	HttpRequest				=	New HTTPRequest(RequestString);
	vResponse				= 	SendHTTPRequest(ApiConnectionProps.ExternalSystemInfo, , HttpRequest.ResourceAddress, "POST", , , , , , ,ApiConnection, HttpRequest, True);
	HttpRequestAnswer		=	vResponse.Raw;// ApiConnection.Post(New HTTPRequest(RequestString));
	
	TokenHasBeenWritten	=	WriteTokensFromHttpResponse(HttpRequestAnswer, ApiConnectionProps, LogDataContainer);
	
	LogDataFinish(LogDataContainer, OperationID);
	
	// 03. Get result.
	Return TokenHasBeenWritten;
	
EndFunction

// --------------------------------------------------------------------------------
//  Description: Send ai request to Bitrix to get all current bound events.
//
// Parameters:
//  SystemInfoRef		 - ExternalSystemInfoRef - External system interactions
//  ApiConnection		 - Structure			 - ApiConnection
//  ApiConnectionProps	 - Structure			 - ApiConnectionProps
//  LogDataContainer	 - String				 - LogDataContainer
// 
// Returns:
//  Array - Array of bound events (string)
//
Function GetBoundEvents(SystemInfoRef, ApiConnection = Undefined, ApiConnectionProps = Undefined, LogDataContainer = Undefined) Export
	
	EventsArray			=	New Array;
	
	If ApiConnection = Undefined Then
		
		ApiConnection	=	ApiConnectionInit(SystemInfoRef, ApiConnectionProps, LogDataContainer);
		
	EndIf;
	
	strOpearionName		=	GetNString(ApiConnectionProps.Server, "Получение отслеживаемых событий для %1", "Getting active events for %1");
	OperationID			=	LogDataStart(LogDataContainer, strOpearionName);
	
	
	ServerAnswer		=	ExecuteApiRequest(ApiConnection, ApiConnectionProps, "event.get", , LogDataContainer, , , SystemInfoRef, , , "");
	ResultProperty		=	GetPropertyOfStructure(ServerAnswer, "RESULT");
	
	If TypeOf(ResultProperty) <> Type("Array") OR ResultProperty.Count() = 0 Then
		
		LogDataFinish(LogDataContainer, OperationID, "Result is empty");
		Return EventsArray;
		
	EndIf;
	
	
	For Each ResultItem In ResultProperty Do
		
		EventsArray.Add(ResultItem.Event);
		
	EndDo;
	
	
	strFinalMessage		=	GetNString(EventsArray.Count(), "Получено %1 событий", " %1 events have been recieved");
	LogDataFinish(LogDataContainer, OperationID, strFinalMessage);
	Return EventsArray;
	
EndFunction //  GetBoundEvents()

// --------------------------------------------------------------------------------
//  Description: Create an Array with supported events.
//
// Parameters:
//  pCustomersEvents - Boolean	 - CustomersEvents
//  pClientsEvents	 - Boolean	 - ClientsEvents
// 
// Returns:
//  Array - Array of events (string)
//
Function GetEventsListForData(pCustomersEvents = False, pClientsEvents = True) Export
	
	EventsArray		=	New Array;
	
	If pClientsEvents Then
		EventsArray.Add("onCrmContactAdd");
		EventsArray.Add("onCrmContactUpdate");
	EndIf;
	
	If pCustomersEvents Then
		EventsArray.Add("onCrmCompanyAdd");
		EventsArray.Add("onCrmCompanyUpdate");
		EventsArray.Add("onCrmCompanyDelete");
	EndIf;
	
	Return EventsArray;
	
EndFunction //  GetEventsListForClients()

// --------------------------------------------------------------------------------
//  Description: Send api request to Bitrix to update current events.
//
// Parameters:
//  SystemInfoRef		 - ExternalSystemInfoRef - External system interactions
//  EventsMustToBeBound	 - ValueTable			 - EventsMustToBeBound
//  ApiConnection		 - Structure			 - ApiConnection
//  ApiConnectionProps	 - Structure			 - ApiConnectionProps
//  LogDataContainer	 - String				 - LogDataContainer
//  pEventMode			 - String				 - EventMode
//
Procedure UpdateBoundEventsForClients(SystemInfoRef, EventsMustToBeBound, ApiConnection = Undefined, ApiConnectionProps = Undefined, LogDataContainer = Undefined, pEventMode = "offline") Export
	
	// 01. Init operation log.
	If ApiConnection = Undefined Then
		
		ApiConnection	=	ApiConnectionInit(SystemInfoRef, ApiConnectionProps, LogDataContainer);
		
	EndIf;
	
	strOpearionName	=	GetNString(ApiConnectionProps.Server, "Установка отслеживаемых событий для %1", "Binding events for %1");
	OperationID		=	LogDataStart(LogDataContainer, strOpearionName);
	
	
	// 02. Get array of events to bind.
	EventsAlreadyBound	=	GetBoundEvents(SystemInfoRef, ApiConnection, ApiConnectionProps, LogDataContainer);
	EventsToBind		=	New Array;
	
	For Each SingleEventMustToBeBound In EventsMustToBeBound Do
		
		If EventsAlreadyBound.Find(SingleEventMustToBeBound) = Undefined Then
			
			EventsToBind.Add(SingleEventMustToBeBound);
			
		EndIf;
		
	EndDo;
	
	// 03. Get array of events to unbind.
	EventsToUnBind		=	New Array;
	
	//For Each SingleEventAlreadyBound In EventsAlreadyBound Do
	
	//	If EventsMustToBeBound.Find(SingleEventAlreadyBound) = Undefined Then
	
	//		EventsToUnBind.Add(SingleEventAlreadyBound);
	
	//	EndIf;
	
	//EndDo;
	
	
	// 04. Bind events.
	Method				=	GetApiMethod("event", "", "Bind");
	
	For Each Event In EventsToBind Do
		
		AnswerStructure	=	ExecuteApiRequest(ApiConnection, ApiConnectionProps, Method, "event_type=" + pEventMode + "&event=" + Event, LogDataContainer, , , SystemInfoRef, , , "");
		
		If AnswerStructure <> Undefined And GetPropertyOfStructure(AnswerStructure, "result.count") > 0 Then
			
			LogDataAdd(LogDataContainer, "Event " + Event + " has been binded");
			
		EndIf;
		
	EndDo;
	
	
	// 05. Unbind events.
	Method				=	GetApiMethod("event", "", "Unbind");
	
	For Each Event In EventsToUnBind Do
		
		AnswerStructure	=	ExecuteApiRequest(ApiConnection, ApiConnectionProps, Method, "event=" + Event, LogDataContainer, , , SystemInfoRef, , , "");  //event_type=offline
		
		If AnswerStructure <> Undefined And GetPropertyOfStructure(AnswerStructure, "result.count") > 0 Then
			
			LogDataAdd(LogDataContainer, "Event " + Event + " has been unbinded");
			
		EndIf;
		
	EndDo;
	
	
	// 03. Log data.
	LogDataFinish(LogDataContainer, OperationID);
	
EndProcedure //  UpdateBoundEventsForClients()

// --------------------------------------------------------------------------------
//  Description: Sends api method to get all fields from Bitrix 24.
//
// Parameters:
//  OnlyUserFields		 - Boolean			 - OnlyUserFields
//  SystemInfoRef		 - ExternalSystemInfoRef - External system interactions
//  ApiConnection		 - Structure			 - ApiConnection
//  ApiConnectionProps	 - Structure			 - ApiConnectionProps
//  LogDataContainer	 - String				 - LogDataContainer
//  pDataType			 - String				 - DataType
// 
// Returns:
//  Array - Array of flield's data structures
//
Function GetFieldsForData(OnlyUserFields = False, SystemInfoRef, ApiConnection = Undefined, ApiConnectionProps = Undefined, LogDataContainer = Undefined, pDataType) Export
	
	// 01. Operation init.
	If ApiConnection = Undefined Then
		
		ApiConnection	=	ApiConnectionInit(SystemInfoRef, ApiConnectionProps, LogDataContainer);
		
	EndIf;
	
	FieldsDataArray		=	New Array;
	
	
	// 02. Getting fields list.
	ApiMethod			=	GetApiMethod(pDataType, "", "Fields");
	
	ServerAnswer		=	ExecuteApiRequest(ApiConnection, ApiConnectionProps, ApiMethod, , LogDataContainer, , , SystemInfoRef, , , "");
	ResultProperty		=	GetPropertyOfStructure(ServerAnswer, "RESULT");
	
	If TypeOf(ResultProperty) <> Type("Structure") OR ResultProperty.Count() = 0 Then
		
		Return FieldsDataArray;
		
	EndIf;
	
	
	// 03. Add information about fields.
	For Each KeyAndValue In ResultProperty Do
		
		DetaildInfo		=	KeyAndValue.Value;
		
		DetaildInfo.Insert("fieldName",		KeyAndValue.Key);
		DetaildInfo.Insert("IsUserField",	DetaildInfo.Property("formLabel"));
		
		FieldsDataArray.Add(DetaildInfo);
		
	EndDo;
	
	Return FieldsDataArray;
	
EndFunction //  GetFieldsForClients()

// --------------------------------------------------------------------------------
//  Description: Sends api method to update user fields in Bitrix 24.
//
// Parameters:
//  SystemInfoRef		 - ExternalSystemInfoRef - External system interactions
//  ApiConnection		 - Structure			 - ApiConnection
//  ApiConnectionProps	 - Structure			 - ApiConnectionProps
//  FieldDataStructure	 - Structure			 - FieldDataStructure
//  LogDataContainer	 - String				 - LogDataContainer
//  DeleteField			 - Boolean				 - DeleteField
// 
// Returns:
//  Boolean - True in success
//
Function UpdateUserFieldForClients(SystemInfoRef, ApiConnection = Undefined, ApiConnectionProps = Undefined, FieldDataStructure,  LogDataContainer = Undefined, DeleteField = False) Export
	
	// 01. Api connection init.
	If ApiConnection = Undefined Then
		
		ApiConnection	=	ApiConnectionInit(SystemInfoRef, ApiConnectionProps, LogDataContainer);
		
	EndIf;
	
	
	// 02. Init the operation.
	DataForRequestStr	=	"";
	
	If NOT ValueIsFilled(FieldDataStructure.ID) Then
		
		ApiMethod		=	GetApiMethod("Clients", "UserFields", "Add");
		
		strOpearionName	=	GetNString(FieldDataStructure.EDIT_FORM_LABEL, "Добавление пользовательского поля %1", "Add user field %1");
		
	ElsIf DeleteField = True Then
		
		ApiMethod		=	GetApiMethod("Clients", "UserFields", "Delete");
		AddParametrToURL(DataForRequestStr, "id", FieldDataStructure.ID);
		
		strOpearionName	=	GetNString(FieldDataStructure.ID, "Удаление пользовательского поля ID %1", "Delete user field ID %1");
		
	Else
		
		ApiMethod		=	GetApiMethod("Clients", "UserFields", "Update");
		AddParametrToURL(DataForRequestStr, "id", FieldDataStructure.ID);
		
		strOpearionName	=	GetNString(FieldDataStructure.ID, "Обновление пользовательского поля ID %1", "Update user field ID %1");
		
	EndIf;
	
	OperationID		=	LogDataStart(LogDataContainer, strOpearionName);
	
	
	// 03. Compose data request string.
	For Each FieldKeyAndValue In FieldDataStructure Do
		
		AddParametrToURL(DataForRequestStr, FieldKeyAndValue.Key, FieldKeyAndValue.Value, "fields");
		
	EndDo;
	
	
	// 04. Request for changes on Bitrix 24 side.
	ServerAnswer		=	ExecuteApiRequest(ApiConnection, ApiConnectionProps, ApiMethod, DataForRequestStr, LogDataContainer, , , SystemInfoRef, , , "");
	ResultProperty		=	GetPropertyOfStructure(ServerAnswer, "result");
	
	
	
	// 05. End of operation.
	LogDataFinish(LogDataContainer, OperationID);
	Return ResultProperty;
	
EndFunction //  UpdateUserFieldForClients()

// --------------------------------------------------------------------------------
//  Description: Create an api method.
//
// Parameters:
//  pObject	 - String	 - Object
//  Section	 - String	 - Section
//  Action	 - String	 - Action
// 
// Returns:
//  String - Result
//
Function GetApiMethod(pObject, Section, Action) Export
	
	strMethod	=	"";
	
	If StrCompare(pObject, "Clients") = 0 OR StrCompare(pObject, "Client") = 0 Then
		
		// 01. Root path.
		strMethod	=	"crm.contact";
		
		
		// 02. Path to section.
		If StrCompare(Section, "UserFields") = 0 OR StrCompare(Section, "UserField") = 0 Then
			
			strMethod	=	strMethod + ".userfield";
			
		EndIf;
		
		
		// 03. Path to action.
		If NOT IsBlankString(Action) Then
			
			strMethod	=	strMethod + "." + lower(Action);
			
		EndIf;
		
	ElsIf StrCompare(pObject, "Events") = 0 OR StrCompare(pObject, "Event") = 0 Then
		
		// 01. Root path.
		strMethod	=	"event";
		
		
		// 02. Path to section.
		If StrCompare(Section, "Offline") = 0 Then
			
			strMethod	=	strMethod + ".offline";
			
		EndIf;
		
		
		// 03. Path to action.
		If NOT IsBlankString(Action) Then
			
			strMethod	=	strMethod + "." + lower(Action);
			
		EndIf;
		
	ElsIf StrCompare(pObject, "Customers") = 0 OR StrCompare(pObject, "Customer") = 0 Then
		
		// 01. Root path.
		strMethod	=	"crm.company";
		
		
		// 02. Path to section.
		If StrCompare(Section, "UserFields") = 0 OR StrCompare(Section, "UserField") = 0 Then
			
			strMethod	=	strMethod + ".userfield";
			
		EndIf;
		
		
		// 03. Path to action.
		If NOT IsBlankString(Action) Then
			
			strMethod	=	strMethod + "." + lower(Action);
			
		EndIf;
		
	ElsIf StrCompare(pObject, "Deals") = 0 OR StrCompare(pObject, "Deal") = 0 Then
		
		// 01. Root path.
		strMethod	=	"crm.deal";
		
		
		// 02. Path to section.
		If StrCompare(Section, "UserFields") = 0 OR StrCompare(Section, "UserField") = 0 Then
			
			strMethod	=	strMethod + ".userfield";
			
		EndIf;
		
		
		// 03. Path to action.
		If NOT IsBlankString(Action) Then
			
			strMethod	=	strMethod + "." + lower(Action);
			
		EndIf;
		
	EndIf;
	
	Return strMethod;
	
EndFunction //  GetApiMethod()

// --------------------------------------------------------------------------------
//
// Parameters:
//  TextVars - Array	 - TextVars
//  Russian	 - String	 - Russian
//  English	 - String	 - English
//  German	 - String	 - German 
// 
// Returns:
//  String - Result 
//
Function GetNString(val TextVars = Undefined, val Russian, val English = "", val German = "") Export
	
	TextsArray		=	New Array;
	
	If TypeOf(TextVars) = Undefined Then
		
		TextVars	=	new Array;
		
	ElsIf TypeOf(TextVars) <> Type("Array") Then
		
		strTextVars	=	String(TextVars);
		
		TextVars	=	new Array;
		TextVars.Add(strTextVars);
		
	EndIf;
	
	TextVarsCount	=	TextVars.Count();
	
	For i=1 To TextVarsCount Do
		
		TextVar		=	TextVars[i-1];
		
		Russian	=	StrReplace(Russian, "%"+i, TextVar);
		English	=	StrReplace(English, "%"+i, TextVar);
		German	=	StrReplace(German, "%"+i, TextVar);
		
	EndDo;
	
	
	// 01. Russian.
	If NOT IsBlankString(Russian) Then
		
		TextsArray.Add("ru = '" + Russian + "'");
		
	EndIf;
	
	// 03. English.
	If NOT IsBlankString(English) Then
		
		TextsArray.Add("en = '" + English + "'");
		
	EndIf;
	
	// 03. German.
	If NOT IsBlankString(German) Then
		
		TextsArray.Add("de = '" + German + "'");
		
	EndIf;
	
	
	// 99. Finish.
	FinalNString	=	StrConcat(TextsArray, ";" + Chars.LF);
	Return NStr(FinalNString);
	
EndFunction //  GetNString()

// --------------------------------------------------------------------------------
//
// Parameters:
//  StringValue	 - String	 - StringValue
// 
// Returns:
//  String - Result
//
Function ConvertSpecCharsToString(val StringValue) Export
	
	CharsList			=	GetSpecCharsListToDecode();
	
	For Each currentListItem In CharsList Do
		
		StringValue		=	StrReplace(StringValue, currentListItem.Value,  currentListItem.Presentation);
		
	EndDo;
	
	Return StringValue;
	
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  JsonStringValue	 - String	 - JsonStringValue
//  LogDataContainer - String	 - LogDataContainer
// 
// Returns:
//  Map - Result
//
Function ConvertJsonToMap(val JsonStringValue, LogDataContainer = Undefined) Export
	
	JsonReader			=	Новый JSONReader;
	JsonReader.SetString(JsonStringValue);
	
	Try
		
		Return ReadJSON(JsonReader, True);
		
	Except
		
		If LogDataContainer <> Undefined Then
			
			LogDataAdd(LogDataContainer, BriefErrorDescription(ErrorInfo()), True);
			
		EndIf;
		
		Return Undefined;
		
	EndTry;
	
EndFunction //  ConvertJsonToMap()

// --------------------------------------------------------------------------------
//
// Parameters:
//  JsonStringValue	 - String	 - JsonStringValue
//  LogDataContainer - String	 - LogDataContainer
// 
// Returns:
//  Structure - Result
//
Function ConvertJsonToStructure(val JsonStringValue, LogDataContainer = Undefined) Export
	
	JsonReader			=	Новый JSONReader;
	JsonReader.SetString(JsonStringValue);
	
	Try
		
		Return ReadJSON(JsonReader);
		
	Except
		
		If LogDataContainer <> Undefined Then
			
			LogDataAdd(LogDataContainer, BriefErrorDescription(ErrorInfo()), True);
			
		EndIf;
		
		Return Undefined;
		
	EndTry;
	
EndFunction //  ConvertJsonToStructure()

// --------------------------------------------------------------------------------
//
// Parameters:
//  StringValue	 - String	 - StringValue
// 
// Returns:
//  String - ConvertString
//
Function ConvertStringToURL(StringValue) Export
	
	Return EncodeString(StringValue, StringEncodingMethod.URLEncoding, TextEncoding.UTF8);
	
EndFunction //  ConvertStringToURL()

// --------------------------------------------------------------------------------
Function ConvertUrlToString(StringValue) Export
	
	Return DecodeString(StringValue, StringEncodingMethod.URLEncoding, TextEncoding.UTF8);
	
EndFunction //  ConvertUrlToString()

// --------------------------------------------------------------------------------
Function ConvertStringToDate(stringValue) Export
	
	Return DATE(1,1,1);
	
EndFunction //  ConvertCtringToDate()

// --------------------------------------------------------------------------------
Function ConvertStringToValueStorage(stringValue) Export
	
	Try
		
		BinaryData		=	Base64Value(stringValue);
		
		Return New ValueStorage(BinaryData);
		
	Except
		
		Return Undefined;
		
	EndTry;
	
EndFunction //  ConvertStringToValueStorage()

// --------------------------------------------------------------------------------
Function ConvertNumberToString(NumberValue, AfterPoint = Undefined) Export
	
	If AfterPoint = Undefined Then
		
		FormatString	=	"NZ=0; NG=0";
		
	Else
		
		FormatString	=	"NFD=" + AfterPoint + "; NZ=0; NG=0";
		
	EndIf;
	
	
	Return Format(NumberValue, FormatString);
	
EndFunction //  ConvertNumberToString()

// --------------------------------------------------------------------------------
Function ConvertDateToString(DateTimeValue, ShowTime = True, ShowDate = True) Export
	
	If ShowTime And ShowDate Then
		
		return Format(DateTimeValue, "DF='dd.MM.yyyy HH:mm:ss'");
		
	ElsIf ShowDate Then
		
		return Format(DateTimeValue, "DF='dd.MM.yyyy'");
		
	ElsIf ShowTime Then
		
		return Format(DateTimeValue, "DF='HH:mm:ss'");
		
	Else
		
		Return TrimAll(DateTimeValue);
		
	EndIf;
	
EndFunction //  ConvertDateToString()

// --------------------------------------------------------------------------------
Function strPos(val StringValue, val SubStringValue, FromBegin = True, StartIndex = 1, EntryNumber = 1) Export
	
	valSearchDirection	=	?(FromBegin, SearchDirection.FromBegin, SearchDirection.FromEnd);
	valStringValue		=	lower(StringValue);
	valSubStringValue	=	lower(SubStringValue);
	
	Return strFind(valStringValue, valSubStringValue, valSearchDirection, StartIndex, EntryNumber);
	
EndFunction //  strPos()

// --------------------------------------------------------------------------------
Procedure AddParametrToURL(RequestString, Parameter, val Value, ArrayParametr = "") Export
	
	ValueForURL				=	ConvertStringToURL(XMLСтрока(Value));
	valSeparator			=	?(IsBlankString(RequestString), "", "&");
	
	If IsBlankString(ArrayParametr) Then
		
		RequestString		=	RequestString + valSeparator + 
		
		Parameter + "=" + ValueForURL;
	Else
		
		
		RequestString		=	RequestString + valSeparator + 
		
		ArrayParametr + "[" + Parameter + "]=" + ValueForURL;
		
	EndIf;
	
EndProcedure

// --------------------------------------------------------------------------------
Function GetPropertyOfStructure(val Structure, Field, MergeArrays = Undefined) Export
	
	FieldValue			=	Undefined;
	FieldsArray			=	StrSplit(Field, ".");
	
	For Each SubField In FieldsArray Do
		
		If TypeOf(Structure) <> Type("Structure") Then
			
			Return FieldValue;
			
		elsIf Structure.Property(SubField, FieldValue) Then
			
			Structure	=	FieldValue;
			
		EndIf;
		
	EndDo;
	
	
	If FieldValue <> Undefined And MergeArrays <> Undefined And TypeOf(FieldValue) = Type("Array") And TypeOf(MergeArrays) = Type("Array") Then
		
		For Each NewValue In FieldValue Do
			
			If MergeArrays.Find(NewValue) = Undefined Then
				
				MergeArrays.Add(NewValue);
				
			EndIf;
			
		EndDo;
		
		FieldValue		=	MergeArrays;
		
	EndIf;
	
	
	Return FieldValue;
	
EndFunction //  GetPropertyOfStructure()

// --------------------------------------------------------------------------------
Function ConvertStringToNumber(StringValue) Export
	
	If TypeOf(StringValue) = Type("Number") Then
		
		Return StringValue;
		
	EndIf;
	
	Try
		
		Return Number(StringValue);
		
	Except
		
		Return 0;
		
	EndTry;
	
EndFunction //  ConvertStringToNumber()

// --------------------------------------------------------------------------------
//	Description: Log data contanier initialization.
//	Returns: Structure with log data container.
Function LogDataInit(Key, DataRef = Undefined) Export
	
	LogDataStructure		=	New Structure;
	LogDataStructure.Insert("Key",					Key);
	LogDataStructure.Insert("DataRef",				DataRef);
	LogDataStructure.Insert("Events",				New Array);
	LogDataStructure.Insert("InitDateTime",			CurrentDate());
	LogDataStructure.Insert("InitPoint",			CurrentUniversalDateInMilliseconds());
	LogDataStructure.Insert("CountOfErrors",		0);
	
	Return LogDataStructure;
	
EndFunction //  LogDataInit()

// --------------------------------------------------------------------------------
//	Description: Adds an event to log data container with operatoin start data.
//	Returns: The ID of event added, to use it later when opertion is finished.
Function LogDataStart(LogDataContainer, OperationName) Export
	
	strMessage	=	GetNString(OperationName, "Начало операции ""%1""", "Start operation ""%1""");
	LogDataAdd(LogDataContainer, strMessage, False, OperationName, 1);
	
	Return LogDataContainer.Events.UBound();
	
EndFunction //  LogDataStart()

// --------------------------------------------------------------------------------
//	Description: Adds an event to log data container.
Procedure LogDataAdd(LogDataContainer, Text, IsError = False, OperationName = "", ShiftValue = 0) Export
	
	If LogDataContainer = Undefined Then
		
		LogDataContainer	=	LogDataInit(Undefined);
		
	EndIf;
	
	LogStructure		=	New Structure;
	LogStructure.Insert("DateTime",			CurrentDate());
	LogStructure.Insert("Text",				Text);
	LogStructure.Insert("IsError",			IsError);
	LogStructure.Insert("StartPoint",		CurrentUniversalDateInMilliseconds());
	LogStructure.Insert("OperationName",	OperationName);
	LogStructure.Insert("ShiftValue",		ShiftValue);
	
	
	If IsError Then
		WriteLogEvent("Bitrix24."+OperationName,EventLogLevel.Error, , ,Text);
		LogDataContainer.CountOfErrors	=	LogDataContainer.CountOfErrors + 1;
		
	EndIf;
	
	LogDataContainer.Events.Add(LogStructure);
	
EndProcedure //  LogDataAdd()

// --------------------------------------------------------------------------------
//	Description: Adds an event to log data container with operatoin finish data.
Procedure LogDataFinish(LogDataContainer, OperationID, Text = "", IsError = False) Export
	
	If NOT IsBlankString(Text) Then
		
		LogDataAdd(LogDataContainer, Text, IsError);
		
	EndIf;
	
	
	StartOperationEvent		=	LogDataContainer.Events.Get(OperationID);
	
	If StartOperationEvent <> Undefined And StartOperationEvent.OperationName <> Undefined And StartOperationEvent.StartPoint <> Undefined Then
		
		nStringParamsArray	=	new Array;
		nStringParamsArray.Add(StartOperationEvent.OperationName);
		nStringParamsArray.Add((CurrentUniversalDateInMilliseconds() - StartOperationEvent.StartPoint)/1000);
		
		strMessage			=	GetNString(nStringParamsArray, "Конец операции ""%1"". Заняло %2 с.", "Finish operation ""%1"". It token %2 s.");
		LogDataAdd(LogDataContainer, strMessage, , , -1);
		
	EndIf;
	
EndProcedure //  LogDataFinish()

// --------------------------------------------------------------------------------
//	Description: Create one string with all events stroed in log data container.
//	Returns: String.
Function LogDataGetEvents(LogDataContainer, UseIndent = True) Export
	
	If LogDataContainer = Undefined Then
		
		Return "";
		
	EndIf;
	
	tDocWithEvents		=	New TextDocument;
	strError			=	GetNString(, "Возникла ошибка. ", "Error occurred. ");
	CurrIndent			=	0;
	
	AllReadyHasNewLine	=	False;
	UpdateIndent		=	False;
	strIndent			=	"";
	
	For Each MessageInfo In LogDataContainer.Events Do
		
		// New line for Start of Operation.
		If UseIndent And MessageInfo.ShiftValue = 1 And NOT AllReadyHasNewLine Then
			
			tDocWithEvents.AddLine("");
			
		EndIf;
		
		
		// No tab for finish operation.
		If UseIndent And MessageInfo.ShiftValue = -1 Then
			
			UpdateIndent	=	True;
			CurrIndent		=	 CurrIndent - 1;
			
		EndIf;
		
		
		
		// Set current indent string.
		If UseIndent And UpdateIndent Then
			
			strIndent		=	"";
			
			For i=1 To CurrIndent Do
				
				strIndent	=	strIndent + Chars.Tab;
				
			EndDo;
			
			UpdateIndent	=	False;
			
		EndIf;
		
		
		
		
		// Add event message.
		strMesage			=	ConvertDateToString(MessageInfo.DateTime) + " > " + strIndent + ?(MessageInfo.IsError, strError, "") + MessageInfo.Text;
		tDocWithEvents.AddLine(strMesage);
		
		
		
		// Set indent for nex lines if it's a start of operation.
		If UseIndent And MessageInfo.ShiftValue = 1 Then
			
			CurrIndent		=	 CurrIndent + MessageInfo.ShiftValue;
			UpdateIndent	=	True;
			
		EndIf;
		
		
		// New line after Finish of Operation.
		If UseIndent And MessageInfo.ShiftValue = -1 Then
			
			tDocWithEvents.AddLine("");
			AllReadyHasNewLine	=	True;
			
		ElsIF AllReadyHasNewLine Then
			
			AllReadyHasNewLine	=	False;
			
		EndIf;
		
	EndDo;
	
	Return tDocWithEvents.GetText();
	
EndFunction //  LogDataGetEvents()

// --------------------------------------------------------------------------------
//	Description: Create main table with atributes (fields) mapped via 1C and Bitrix which are stored in Info Reg.
//	Returns: Value table.
Function CreateAttributesTableForClients(ExternalSystemInfoRef) Export
	
	Query				=	New Query;
	Query.Text			= 
	"SELECT
	|	TRUE AS IsSet,
	|	IR_ExternalSystemsObjectCodesMappings.ObjectDescription AS Attribute1C,
	|	IR_ExternalSystemsObjectCodesMappings.ObjectDataPath AS DataPath,
	|	IR_ExternalSystemsObjectCodesMappings.ObjectExternalCode AS AttributeB24,
	|	IR_ExternalSystemsObjectCodesMappings.Type AS Type,
	|	TRUE AS DirectionOut,
	|	CASE
	|		WHEN IR_ExternalSystemsObjectCodesMappings.ObjectDataPath = ""Clients""
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DirectionIn
	|FROM
	|	Catalog.ExternalSystemInteractions AS ctl_ExternalSystemInteractions
	|		INNER JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS IR_ExternalSystemsObjectCodesMappings
	|		ON ctl_ExternalSystemInteractions.Hotel = IR_ExternalSystemsObjectCodesMappings.Hotel
	|			AND ctl_ExternalSystemInteractions.HttpServer = IR_ExternalSystemsObjectCodesMappings.ExternalSystemCode
	|			AND (IR_ExternalSystemsObjectCodesMappings.ObjectTypeName = &ObjectTypeName)
	|WHERE
	|	IR_ExternalSystemsObjectCodesMappings.ObjectDescription > """"
	|	AND IR_ExternalSystemsObjectCodesMappings.ObjectDataPath > """"
	|	AND IR_ExternalSystemsObjectCodesMappings.ObjectExternalCode > """"
	|	AND ctl_ExternalSystemInteractions.Ref = &ExternalSystem";
	
	
	Query.SetParameter("ObjectTypeName",	GetApiMethod("Clients", "", "Fields"));
	Query.SetParameter("ExternalSystem",	ExternalSystemInfoRef);
	
	DataTable			=	Query.Execute().Unload();
	
	Return DataTable;
	
EndFunction //  CreateAttributesTableForClients()

// --------------------------------------------------------------------------------
Function CreateAttributesTableForCustomers(ExternalSystemInfoRef) Export
	
	Query				=	New Query;
	Query.Text			= 
	"SELECT
	|	TRUE AS IsSet,
	|	IR_ExternalSystemsObjectCodesMappings.ObjectDescription AS Attribute1C,
	|	IR_ExternalSystemsObjectCodesMappings.ObjectDataPath AS DataPath,
	|	IR_ExternalSystemsObjectCodesMappings.ObjectExternalCode AS AttributeB24,
	|	IR_ExternalSystemsObjectCodesMappings.Type AS Type,
	|	TRUE AS DirectionOut,
	|	CASE
	|		WHEN IR_ExternalSystemsObjectCodesMappings.ObjectDataPath = ""Customers""
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DirectionIn
	|FROM
	|	Catalog.ExternalSystemInteractions AS ctl_ExternalSystemInteractions
	|		INNER JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS IR_ExternalSystemsObjectCodesMappings
	|		ON ctl_ExternalSystemInteractions.Hotel = IR_ExternalSystemsObjectCodesMappings.Hotel
	|			AND ctl_ExternalSystemInteractions.HttpServer = IR_ExternalSystemsObjectCodesMappings.ExternalSystemCode
	|			AND (IR_ExternalSystemsObjectCodesMappings.ObjectTypeName = &ObjectTypeName)
	|WHERE
	|	IR_ExternalSystemsObjectCodesMappings.ObjectDescription > """"
	|	AND IR_ExternalSystemsObjectCodesMappings.ObjectDataPath > """"
	|	AND IR_ExternalSystemsObjectCodesMappings.ObjectExternalCode > """"
	|	AND ctl_ExternalSystemInteractions.Ref = &ExternalSystem";
	
	
	Query.SetParameter("ObjectTypeName",	GetApiMethod("Customers", "", "Fields"));
	Query.SetParameter("ExternalSystem",	ExternalSystemInfoRef);
	
	DataTable			=	Query.Execute().Unload();
	
	Return DataTable;
	
EndFunction //  CreateAttributesTableForClients()

// --------------------------------------------------------------------------------
Function CreateAttributesTableForDeals(ExternalSystemInfoRef) Export
	
	Query				=	New Query;
	Query.Text			= 
	"SELECT
	|	TRUE AS IsSet,
	|	IR_ExternalSystemsObjectCodesMappings.ObjectDescription AS Attribute1C,
	|	IR_ExternalSystemsObjectCodesMappings.ObjectDataPath AS DataPath,
	|	IR_ExternalSystemsObjectCodesMappings.ObjectExternalCode AS AttributeB24,
	|	IR_ExternalSystemsObjectCodesMappings.Type AS Type,
	|	TRUE AS DirectionOut,
	|	CASE
	|		WHEN IR_ExternalSystemsObjectCodesMappings.ObjectDataPath = ""Deals""
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DirectionIn
	|FROM
	|	Catalog.ExternalSystemInteractions AS ctl_ExternalSystemInteractions
	|		INNER JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS IR_ExternalSystemsObjectCodesMappings
	|		ON ctl_ExternalSystemInteractions.Hotel = IR_ExternalSystemsObjectCodesMappings.Hotel
	|			AND ctl_ExternalSystemInteractions.HttpServer = IR_ExternalSystemsObjectCodesMappings.ExternalSystemCode
	|			AND (IR_ExternalSystemsObjectCodesMappings.ObjectTypeName = &ObjectTypeName)
	|WHERE
	|	IR_ExternalSystemsObjectCodesMappings.ObjectDescription > """"
	|	AND IR_ExternalSystemsObjectCodesMappings.ObjectDataPath > """"
	|	AND IR_ExternalSystemsObjectCodesMappings.ObjectExternalCode > """"
	|	AND ctl_ExternalSystemInteractions.Ref = &ExternalSystem";
	
	
	Query.SetParameter("ObjectTypeName",	GetApiMethod("Deals", "", "Fields"));
	Query.SetParameter("ExternalSystem",	ExternalSystemInfoRef);
	
	DataTable			=	Query.Execute().Unload();
	
	Return DataTable;
	
EndFunction //  CreateAttributesTableForClients()

// --------------------------------------------------------------------------------
//	Description: Create value list with list of spec chars in value and 1C chars in Presentation.
//	Returns: Value list with spec chars.
Function GetSpecCharsListToDecode() Export
	
	CharsList	=	New ValueList;
	
	CharsList.Add("\u0430", "а");
	CharsList.Add("\u0431", "б");
	CharsList.Add("\u0432", "в");
	CharsList.Add("\u0433", "г");
	CharsList.Add("\u0434", "д");
	CharsList.Add("\u0435", "е");
	CharsList.Add("\u0451", "ё");
	CharsList.Add("\u0436", "ж");
	CharsList.Add("\u0437", "з");
	CharsList.Add("\u0438", "и");
	CharsList.Add("\u0439", "й");
	CharsList.Add("\u043a", "к");
	CharsList.Add("\u043b", "л");
	CharsList.Add("\u043c", "м");
	CharsList.Add("\u043d", "н");
	CharsList.Add("\u043e", "о");
	CharsList.Add("\u043f", "п");
	CharsList.Add("\u0440", "р");
	CharsList.Add("\u0441", "с");
	CharsList.Add("\u0442", "т");
	CharsList.Add("\u0443", "у");
	CharsList.Add("\u0444", "ф");
	CharsList.Add("\u0445", "х");
	CharsList.Add("\u0446", "ц");
	CharsList.Add("\u0447", "ч");
	CharsList.Add("\u0448", "ш");
	CharsList.Add("\u0448", "щ");
	CharsList.Add("\u044a", "ъ");
	CharsList.Add("\u044b", "ы");
	CharsList.Add("\u044c", "ь");
	CharsList.Add("\u044d", "э");
	CharsList.Add("\u044e", "ю");
	CharsList.Add("\u044f", "я");
	
	CharsList.Add("\u0410", "А");
	CharsList.Add("\u0411", "Б");
	CharsList.Add("\u0412", "В");
	CharsList.Add("\u0413", "Г");
	CharsList.Add("\u0414", "Д");
	CharsList.Add("\u0415", "Е");
	CharsList.Add("\u0401", "Ё");
	CharsList.Add("\u0416", "Ж");
	CharsList.Add("\u0417", "З");
	CharsList.Add("\u0418", "И");
	CharsList.Add("\u0419", "Й");
	CharsList.Add("\u041a", "К");
	CharsList.Add("\u041b", "Л");
	CharsList.Add("\u041c", "М");
	CharsList.Add("\u041d", "Н");
	CharsList.Add("\u041e", "О");
	CharsList.Add("\u041f", "П");
	CharsList.Add("\u0420", "Р");
	CharsList.Add("\u0421", "С");
	CharsList.Add("\u0422", "Т");
	CharsList.Add("\u0423", "У");
	CharsList.Add("\u0424", "Ф");
	CharsList.Add("\u0425", "Х");
	CharsList.Add("\u0426", "Ц");
	CharsList.Add("\u0427", "Ч");
	CharsList.Add("\u0428", "Ш");
	CharsList.Add("\u0428", "Щ");
	CharsList.Add("\u042a", "Ъ");
	CharsList.Add("\u042b", "Ы");
	CharsList.Add("\u042c", "Ь");
	CharsList.Add("\u042d", "Э");
	CharsList.Add("\u042e", "Ю");
	CharsList.Add("\u042f", "Я");
	
	CharsList.Add("\u0022", "'");
	
	CharsList.Add("\u003E", ">");
	CharsList.Add("\u003е", ">");
	
	CharsList.Add("\u003C", "<");
	CharsList.Add("\u003c", "<");
	
	CharsList.Add("\u0027", "'");
	
	Return CharsList;
	
EndFunction //  GetCharsListDecodeTo()

// --------------------------------------------------------------------------------
Function ConvertUnicode(pString) Export 
	vReturnString = "";
	
	vMaskChar = New Array(74);
	
	vMaskChar[0]="А";   vMaskChar[1]="Б";  vMaskChar[2]="В";  vMaskChar[3]="Г";  vMaskChar[4]="Ґ";  vMaskChar[5]="Д";
	vMaskChar[6]="Е";   vMaskChar[7]="Є";  vMaskChar[8]="Ж";  vMaskChar[9]="З";  vMaskChar[10]="И"; vMaskChar[11]="І";
	vMaskChar[12]="Ї";  vMaskChar[13]="Й"; vMaskChar[14]="К"; vMaskChar[15]="Л"; vMaskChar[16]="М"; vMaskChar[17]="Н";
	vMaskChar[18]="О";  vMaskChar[19]="П"; vMaskChar[20]="Р"; vMaskChar[21]="С"; vMaskChar[22]="Т"; vMaskChar[23]="У";
	vMaskChar[24]="Ф";  vMaskChar[25]="Х"; vMaskChar[26]="Ц"; vMaskChar[27]="Ч"; vMaskChar[28]="Ш"; vMaskChar[29]="Щ";
	vMaskChar[30]="Ь";  vMaskChar[31]="Ю"; vMaskChar[32]="Я"; vMaskChar[70]="Ы"; vMaskChar[71]="Ё"; vMaskChar[72]="Ъ";
	vMaskChar[73]="Э";
	
	
	vMaskChar[33]="а";  vMaskChar[34]="б"; vMaskChar[35]="в"; vMaskChar[36]="г"; vMaskChar[37]="ґ"; vMaskChar[38]="д";
	vMaskChar[39]="е";  vMaskChar[40]="є"; vMaskChar[41]="ж"; vMaskChar[42]="з"; vMaskChar[43]="и"; vMaskChar[44]="і";
	vMaskChar[45]="ї";  vMaskChar[46]="й"; vMaskChar[47]="к"; vMaskChar[48]="л"; vMaskChar[49]="м"; vMaskChar[50]="н";
	vMaskChar[51]="о";  vMaskChar[52]="п"; vMaskChar[53]="р"; vMaskChar[54]="с"; vMaskChar[55]="т"; vMaskChar[56]="у";
	vMaskChar[57]="ф";  vMaskChar[58]="х"; vMaskChar[59]="ц"; vMaskChar[60]="ч"; vMaskChar[61]="ш"; vMaskChar[62]="щ";
	vMaskChar[63]="ь";  vMaskChar[64]="ю"; vMaskChar[65]="я"; vMaskChar[66]="ы"; vMaskChar[67]="ё"; vMaskChar[68]="ъ"; 
	vMaskChar[69]="э";    
	
	vMaskCharCode = New Array(74);
	
	vMaskCharCode[0]="0410";   vMaskCharCode[1]="0411";  vMaskCharCode[2]="0412";  vMaskCharCode[3]="0413";  vMaskCharCode[4]="0490";  vMaskCharCode[5]="0414";
	vMaskCharCode[6]="0415";   vMaskCharCode[7]="0404";  vMaskCharCode[8]="0416";  vMaskCharCode[9]="0417";  vMaskCharCode[10]="0418"; vMaskCharCode[11]="0406";
	vMaskCharCode[12]="0407";  vMaskCharCode[13]="0419"; vMaskCharCode[14]="041A"; vMaskCharCode[15]="041B"; vMaskCharCode[16]="041C"; vMaskCharCode[17]="041D";
	vMaskCharCode[18]="041E";  vMaskCharCode[19]="041F"; vMaskCharCode[20]="0420"; vMaskCharCode[21]="0421"; vMaskCharCode[22]="0422"; vMaskCharCode[23]="0423";
	vMaskCharCode[24]="0424";  vMaskCharCode[25]="0425"; vMaskCharCode[26]="0426"; vMaskCharCode[27]="0427"; vMaskCharCode[28]="0428"; vMaskCharCode[29]="0429";
	vMaskCharCode[30]="042C";  vMaskCharCode[31]="042E"; vMaskCharCode[32]="042F"; vMaskCharCode[70]="042B"; vMaskCharCode[71]="0401"; vMaskCharCode[72]="042A";
	vMaskCharCode[73]="042D"; 
	
	vMaskCharCode[33]="0430";  vMaskCharCode[34]="0431"; vMaskCharCode[35]="0432"; vMaskCharCode[36]="0433"; vMaskCharCode[37]="0491"; vMaskCharCode[38]="0434";
	vMaskCharCode[39]="0435";  vMaskCharCode[40]="0454"; vMaskCharCode[41]="0436"; vMaskCharCode[42]="0437"; vMaskCharCode[43]="0438"; vMaskCharCode[44]="0456";
	vMaskCharCode[45]="0457";  vMaskCharCode[46]="0439"; vMaskCharCode[47]="043A"; vMaskCharCode[48]="043B"; vMaskCharCode[49]="043C"; vMaskCharCode[50]="043D";
	vMaskCharCode[51]="043E";  vMaskCharCode[52]="043F"; vMaskCharCode[53]="0440"; vMaskCharCode[54]="0441"; vMaskCharCode[55]="0442"; vMaskCharCode[56]="0443";
	vMaskCharCode[57]="0444";  vMaskCharCode[58]="0445"; vMaskCharCode[59]="0446"; vMaskCharCode[60]="0447"; vMaskCharCode[61]="0448"; vMaskCharCode[62]="0449";
	vMaskCharCode[63]="044C";  vMaskCharCode[64]="044E"; vMaskCharCode[65]="044F"; vMaskCharCode[66]="044B"; vMaskCharCode[67]="0451"; vMaskCharCode[68]="044A";
	vMaskCharCode[69]="044D"; 
	
	vTempString = "";
	For vInd = 1 To StrLen(pString) Do
		If Left(pString, 1) = "\" Then
			If Left(pString, 2) = "\u" Then
				vTempString = Right(Left(pString, 6),4);
				If vMaskCharCode.Find(vTempString) = Undefined Then
					vReplaceString = Right(vTempString, 1);
					vTempString = StrReplace(vTempString, vReplaceString, Title(vReplaceString));
					If vMaskCharCode.Find(vTempString) <> Undefined Then
						vReturnString = vReturnString + vMaskChar[vMaskCharCode.Find(vTempString)];
					EndIf;
				Else
					vReturnString = vReturnString + vMaskChar[vMaskCharCode.Find(vTempString)];
				EndIf;
				pString = Right(pString, (StrLen(pString)-6)); 
			Else  
				pString = Right(pString, (StrLen(pString)-2));
			EndIf;
		Else
			vReturnString = vReturnString + Left(pString, 1);
			pString = Right(pString, (StrLen(pString)-1));     
		EndIf;         
	EndDo;   
	Return vReturnString;
EndFunction // ConvertUnicode

// --------------------------------------------------------------------------------
Function EncodeURL(pURL) Export
	vResult = "";
	For vInd = 1 To StrLen(pURL) Do
		ch = Mid(pURL,vInd,1);
		vch = CharCode(ch);
		If ("A" <= ch ) And ( ch <= "Z") Then        // "A".."Z"
			vResult = vResult + ch;
		ElsIf ("a" <= ch ) And ( ch <= "z") Then    // "a".."z"
			vResult = vResult + ch;
		ElsIf ("0" <= ch ) And ( ch <= "9") Then    // "0".."9"
			vResult = vResult + ch;
		ElsIf (ch = " ") Or ( ch = "+") Then            // space
			vResult = vResult + "+";
		ElsIf (ch = "-" ) Or ( ch = "_") Then        // unreserved
			// ch == '.' || ch == '!'
			// ch == '~' || ch == '*'
			// ch == '\'' || ch == '('
			// ch == ')') Then
			vResult = vResult + ch;
		ElsIf (vch <= 127) Then        // other ASCII
			vResult = vResult + hex(vch);
		ElsIf (vch <= 2047) Then        // non-ASCII <= 0x7FF
			vResult = vResult + hex(192 + Int(vch / 64));
			vResult = vResult + hex(128 + (vch % 64));
		Else                    // 0x7FF < ch <= 0xFFFF 
			vResult = vResult + hex(224 + Int(vch / 4096));
			vResult = vResult + hex(128 + (Int(vch / 64) % 64));
			vResult = vResult + hex(128 + (vch % 64));
		EndIf;
	EndDo; 
	
	Return vResult;
EndFunction // EncodeURL

// --------------------------------------------------------------------------------
// Get all Messages with no bitrix Id, but those for emplyee or departments which are connected with bitrix24
Procedure SyncTasks(ExternalSystemInfoRef) Export
	
	ApiConnectionProps	= GetConnectionProps(ExternalSystemInfoRef);
	
	// API connection init.
	ApiConnection =	ApiConnectionInit(ExternalSystemInfoRef, ApiConnectionProps);
	
	If ApiConnection = Undefined Then
		Return;
	EndIf;
	
	rErrorMessage = "";
	vQ = New Query("SELECT DISTINCT
	|	Messages.Recorder AS Ref
	|FROM
	|	InformationRegister.Messages AS Messages
	|WHERE
	|	Messages.B24TaskID = 0
	|	AND (Messages.ForDepartment <> &qEmptyDepartment
	|				AND Messages.ForDepartment.HeadOfDepartment.B24EmployeeID <> 0
	|			OR Messages.ForEmployee <> &qEmptyEmployee
	|				AND Messages.ForEmployee.B24EmployeeID <> 0)
	|	AND NOT Messages.IsClosed");
	vQ.SetParameter("qEmptyDepartment",Catalogs.Departments.EmptyRef());
	vQ.SetParameter("qEmptyEmployee",Catalogs.Employees.EmptyRef());
	qRes = vQ.Execute().Select();
	If qRes.Count() > 0 Then
		vAccessToken = ApiConnectionProps.Token;
		While qRes.Next() Do
			
			vID = CreateNewTask(ExternalSystemInfoRef, vAccessToken, qRes.Ref, rErrorMessage, ApiConnection);
			
			// Post a message to Traktir Front
			PostTraktirInfo(qRes.Ref, ExternalSystemInfoRef);
			
		EndDo;	
	EndIf;
EndProcedure // SyncTasks

// --------------------------------------------------------------------------------
Function GetClientsFieldsMapping() Export
	
	vResult = New ValueTable;
	vResult.Columns.Add("Bitrix");
	vResult.Columns.Add("Hotel");
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "NAME";
	vNewRow.Hotel 	= "FirstName";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "SECOND_NAME";
	vNewRow.Hotel 	= "SecondName";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "LAST_NAME";
	vNewRow.Hotel 	= "LastName";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "ADDRESS";
	vNewRow.Hotel 	= "Address";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "EMAIL";
	vNewRow.Hotel 	= "EMail";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "PHONE";
	vNewRow.Hotel 	= "Phone";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "BIRTHDATE";
	vNewRow.Hotel 	= "DateOfBirth";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "PHOTO";
	vNewRow.Hotel 	= "Photo";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "ADDRESS_CITY";
	vNewRow.Hotel 	= "City";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "ADDRESS_COUNTRY";
	vNewRow.Hotel 	= "Citizenship";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "ADDRESS_REGION";
	vNewRow.Hotel 	= "Region";
	
	vNewRow 		= vResult.Add();
	vNewRow.Bitrix 	= "COMMENTS";
	vNewRow.Hotel 	= "Remarks";
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
Function GetCustomersFieldsMapping() Export
	
	vResult = New ValueTable;
	vResult.Columns.Add("Bitrix");
	vResult.Columns.Add("Hotel");
	vResult.Columns.Add("DataPath");
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "TITLE";
	vNewRow.Hotel 		= "Description";
	vNewRow.DataPath 	= "Customers";
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "ADDRESS";
	vNewRow.Hotel 		= "PostAddress";
	vNewRow.DataPath 	= "Customers";
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
Function GetDealsFieldsMapping() Export
	
	vResult = New ValueTable;
	vResult.Columns.Add("Bitrix");
	vResult.Columns.Add("Hotel");
	vResult.Columns.Add("DataPath");
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "UTM_CAMPAIGN";
	vNewRow.Hotel 		= "utm_campaign";
	vNewRow.DataPath 	= "AdditionalInfo";
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "UTM_CONTENT";
	vNewRow.Hotel 		= "utm_content";
	vNewRow.DataPath 	= "AdditionalInfo";
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "UTM_MEDIUM";
	vNewRow.Hotel 		= "utm_medium";
	vNewRow.DataPath 	= "AdditionalInfo";
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "UTM_SOURCE";
	vNewRow.Hotel 		= "utm_source";
	vNewRow.DataPath 	= "AdditionalInfo";
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "CONTACT_IDS";
	vNewRow.Hotel 		= "ClientsList";
	vNewRow.DataPath 	= "AdditionalInfo";
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "OPPORTUNITY";
	vNewRow.Hotel 		= "Summ";
	vNewRow.DataPath 	= "AdditionalInfo";
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "TITLE";
	vNewRow.Hotel 		= "Title";
	vNewRow.DataPath 	= "AdditionalInfo";
	
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "COMPANY_ID";
	vNewRow.Hotel 		= "Customer";
	vNewRow.DataPath 	= "GuestGroups";
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "CONTACT_ID";
	vNewRow.Hotel 		= "Client";
	vNewRow.DataPath 	= "GuestGroups";
	
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "DATE_CREATE";
	vNewRow.Hotel 		= "CreateDate";
	vNewRow.DataPath 	= "GuestGroups";
	
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "STAGE_ID";
	vNewRow.Hotel 		= "Status";
	vNewRow.DataPath 	= "GuestGroups";
	
	vNewRow 			= vResult.Add();
	vNewRow.Bitrix 		= "CATEGORY_ID";
	vNewRow.Hotel 		= "GroupType";
	vNewRow.DataPath 	= "GuestGroups";
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
Function GetClientsCount(ExternalSystemInfoRef) Export
	
	vResult = 0;
	
	ApiConnectionProps	= GetConnectionProps(ExternalSystemInfoRef);
	ApiConnection		=	ApiConnectionInit(ExternalSystemInfoRef, ApiConnectionProps);	
	Method				=	GetApiMethod("Clients", "", "List");			
	RequestString		=	"select[]=NAME&select[]=SECOND_NAME&select[]=LAST_NAME&select[]=PHONE&select[]=EMAIL&select[]=BIRTHDATE";
	AnswerRequest		=	ExecuteApiRequest(ApiConnection, ApiConnectionProps, Method, RequestString, Undefined, , , ExternalSystemInfoRef, , , "");
	ResultProperty		=	GetPropertyOfStructure(AnswerRequest, "result", ResultProperty);
	
	vResult				=	GetPropertyOfStructure(AnswerRequest, "total");
	
	Try
		vResult = Number(vResult);
	Except
		vResult = 0;
	EndTry;
	
	Return vResult;
	
EndFunction 

// --------------------------------------------------------------------------------
Function LoadAllData(pExternalSystemInfoRef, pIsBackgroundJob = False, pResultStorageAddress = Undefined, pDataType) Export
	vResult = New Structure("Created, Found, Failed, Message", 0, 0, 0, "");
	
	If NOT ValueIsFilled(pExternalSystemInfoRef) Then
		Return vResult;
	EndIf;
	
	vPageCount = 0;
	vIDSArray = New Array;
	
	vApiConnectionProps = GetConnectionProps(pExternalSystemInfoRef);
	vApiConnection = ApiConnectionInit(pExternalSystemInfoRef, vApiConnectionProps);
	
	vMethod = GetApiMethod(pDataType, "", "List");
	vRequestString = "select[]=ID&start={PAGE}";
	
	vAnswerRequest = ExecuteApiRequest(vApiConnection, vApiConnectionProps, vMethod, StrReplace(vRequestString, "{PAGE}", "0"), Undefined, , , pExternalSystemInfoRef, , , "");
	vResultProperty = GetPropertyOfStructure(vAnswerRequest, "result");
	If TypeOf(vResultProperty) = Type("Array") And vResultProperty.Count() > 0 Then
		For Each vData In vResultProperty Do
			vIDSArray.Add(Format(vData.ID, "NZ=; NG="));
		EndDo;
	EndIf;
	
	vTotal = GetPropertyOfStructure(vAnswerRequest, "total");
	If vTotal <> Undefined Then
		vPageCount = Int(vTotal / 50) + 1;
	EndIf;
	
	cmWait(1);
	
	vRequestDatas = New Map;
	For vPage = 1 To vPageCount - 1 Do
		vDataUUID = "Page" + Format(vPage, "NZ=; NG=");
		
		vRequestDatas.Insert(vDataUUID, vMethod + "?" + StrReplace(vRequestString, "{PAGE}", Format(vPage * 50, "NZ=; NG=")));
		If vRequestDatas.Count() < 50 And vPage <> vPageCount - 1 Then
			Continue;
		EndIf;
		
		vAnswerStructure = ExecuteApiRequestBatchJSON(vApiConnection, vApiConnectionProps, vRequestDatas, Undefined, 0, pExternalSystemInfoRef);
		vAnswerResult = GetPropertyOfStructure(vAnswerStructure, "result.result");
		
		If vAnswerResult = Undefined Then
			Break;
		EndIf;
		
		For Each vAnswerResultRow In vAnswerResult Do
			vAnswerResultRowValue = vAnswerResultRow.Value;
			For Each vAnswerResultRowValueRow In vAnswerResultRowValue Do
				vIDSArray.Add(Format(vAnswerResultRowValueRow.ID, "NZ=; NG="));
			EndDo;
		EndDo;
		
		vRequestDatas = New Map;
		cmWait(1);
	EndDo;
	
	If vIDSArray.Count() > 0 Then
		vResult = ImportData(pExternalSystemInfoRef, Undefined, vIDSArray, pIsBackgroundJob, pDataType);
	EndIf;
	
	If pResultStorageAddress <> Undefined Then
		PutToTempStorage(vResult, pResultStorageAddress);
	EndIf;
	
	Return vResult;
EndFunction // LoadAllData

// --------------------------------------------------------------------------------
Function GetBitrix24Catalog(ExternalSystemInfoRef, pCatalogID) Export
	
	vResult = New ValueTable;
	vResult.Columns.Add("id");
	vResult.Columns.Add("name");
	
	vMethod = "crm.status.entity.items?entityId=" + pCatalogID;
	
	ApiConnectionProps		=	GetConnectionProps(ExternalSystemInfoRef);
	
	// 02. API connection init.
	ApiConnection			=	ApiConnectionInit(ExternalSystemInfoRef, ApiConnectionProps);
	
	If ApiConnection = Undefined Then
		
		Return vResult;
		
	EndIf;
	
	vResponse = ExecuteApiRequest(ApiConnection, ApiConnectionProps, vMethod, , , , , ExternalSystemInfoRef, , , "");
	
	If vResponse <> Undefined And vResponse.result <> Undefined Then
		For Each vRow in vResponse.result Do
			vNewRow 		= vResult.Add();
			vNewRow.id 		= vRow.STATUS_ID;
			vNewRow.name 	= vRow.NAME;
		EndDo;
	EndIf;
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
Function GetBitrix24DealsCategory(ExternalSystemInfoRef) Export
	
	vResult = New ValueTable;
	vResult.Columns.Add("id");
	vResult.Columns.Add("name");
	
	vMethod = "crm.dealcategory.list";
	
	ApiConnectionProps		=	GetConnectionProps(ExternalSystemInfoRef);
	
	// 02. API connection init.
	ApiConnection			=	ApiConnectionInit(ExternalSystemInfoRef, ApiConnectionProps);
	
	If ApiConnection = Undefined Then
		
		Return vResult;
		
	EndIf;
	
	vResponse = ExecuteApiRequest(ApiConnection, ApiConnectionProps, vMethod, , , , , ExternalSystemInfoRef, , , "");
	
	If vResponse <> Undefined And vResponse.result <> Undefined Then
		For Each vRow in vResponse.result Do
			vNewRow 		= vResult.Add();
			vNewRow.id 		= vRow.ID;
			vNewRow.name 	= vRow.NAME;
		EndDo;
	EndIf;
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
// Returns deals stages list by category deal id
Function GetBitrix24DealsStageList(ExternalSystemInfoRef, pDealCategoryID) Export
	
	vResult = New ValueTable;
	vResult.Columns.Add("id");
	vResult.Columns.Add("name");
	
	vMethod = "crm.dealcategory.stage.list?id=" + pDealCategoryID;
	
	ApiConnectionProps		=	GetConnectionProps(ExternalSystemInfoRef);
	
	// 02. API connection init.
	ApiConnection			=	ApiConnectionInit(ExternalSystemInfoRef, ApiConnectionProps);
	
	If ApiConnection = Undefined Then
		
		Return vResult;
		
	EndIf;
	
	vResponse = ExecuteApiRequest(ApiConnection, ApiConnectionProps, vMethod, , , , , ExternalSystemInfoRef, , , "");
	
	If vResponse <> Undefined And vResponse.result <> Undefined Then
		For Each vRow in vResponse.result Do
			vNewRow 		= vResult.Add();
			vNewRow.id 		= vRow.STATUS_ID;
			vNewRow.name 	= vRow.NAME;
		EndDo;
	EndIf;
	
	Return vResult;
	
	
EndFunction

// --------------------------------------------------------------------------------
Function CreateAndUpdateTags(ExternalSystemInfoRef) Export
	
	vResult = False;
	
	vTagsFieldSettings = New Structure;
	vTagsFieldSettings.Insert("FIELD_NAME", 		"1CHotelTags"); 
	vTagsFieldSettings.Insert("EDIT_FORM_LABEL", 	"1С:Отель Теги");
	vTagsFieldSettings.Insert("LIST_COLUMN_LABEL", 	"1С:Отель Теги");
	vTagsFieldSettings.Insert("USER_TYPE_ID", 		"enumeration");
	vTagsFieldSettings.Insert("MULTIPLE", 			"Y");
	vTagsFieldSettings.Insert("IS_SEARCHABLE", 		"Y");
	vTagsFieldSettings.Insert("SHOW_IN_LIST", 		"Y");
	
	vMethod				= ""; 
	vID					= Undefined;
	vClientTagsField 	= InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalSystemInfoRef, "clientTagsField");
	
	If vClientTagsField.Count() > 0 Then
		vID = vClientTagsField[0].id;
	EndIf;	
	
	vClientTags = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalSystemInfoRef, "clientTags");
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Tags.Ref AS Ref,
	|	Tags.Description AS Description
	|FROM
	|	Catalog.Tags AS Tags
	|WHERE
	|	NOT Tags.DeletionMark
	|
	|ORDER BY
	|	Tags.Code";
	
	vAllTags = vQuery.Execute().Unload();
	
	If vID = Undefined Then
		vMethod = "crm.contact.userfield.add?";
		vFirst = True;
		For Each vKeyAndValue in vTagsFieldSettings Do
			ValueForURL	= ConvertStringToURL(XMLString(vKeyAndValue.Value));
			If vFirst Then
				vMethod = vMethod + "fields[" + vKeyAndValue.Key + "]=" + ValueForURL; 
				vFirst = False;
			Else
				vMethod = vMethod + "&fields[" + vKeyAndValue.Key + "]=" + ValueForURL;
			EndIf;
		EndDo;
		
		i = 0;
		For Each vTag in vAllTags Do
			ValueForURL	= ConvertStringToURL(XMLString(vTag.Description));
			vMethod 	= vMethod + "&fields[LIST][" + i + "][VALUE]=" + ValueForURL;
			i = i + 1;
		EndDo;
		
	Else
		i = 0;
		ValueForURL	= ConvertStringToURL(XMLString(vID));
		vMethod = "crm.contact.userfield.update?id=" + ValueForURL + "&fields[ID]=" + ValueForURL;
		For Each vTag in vAllTags Do
			vFound = Undefined;
			If vClientTags.Count() > 0 Then
				vFound = vClientTags.Find(vTag.Ref, "RefKey1");
			EndIf;
			If vFound = Undefined Then
				ValueForURL	= ConvertStringToURL(XMLString(vTag.Description));
				vMethod 	= vMethod + "&fields[LIST][" + i + "][VALUE]=" + ValueForURL;
			Else
				ValueForURL	= ConvertStringToURL(XMLString(vTag.Description));
				vMethod 	= vMethod + "&fields[LIST][" + i + "][ID]=" + vFound.id + "&fields[LIST][" + i + "][VALUE]=" + ValueForURL;	
			EndIf;
			i = i + 1;
		EndDo;
		
	EndIf;
	
	ApiConnectionProps		=	GetConnectionProps(ExternalSystemInfoRef);
	
	// 02. API connection init.
	ApiConnection			=	ApiConnectionInit(ExternalSystemInfoRef, ApiConnectionProps);
	
	If ApiConnection = Undefined Then
		Return vResult;
	EndIf;
	
	vRequestDatas = New Structure;
	vRequestDatas.Insert("contact", vMethod);
	vRequestDatas.Insert("contact_get", "crm.contact.userfield.get?id=" + ?(vID = Undefined, "$result[contact]", vID));
	
	vAnswerStructure = ExecuteApiRequestBatchJSON(ApiConnection, ApiConnectionProps, vRequestDatas, Undefined, 0, ExternalSystemInfoRef, 1);
	vAnswerResult = GetPropertyOfStructure(vAnswerStructure, "result.result");
	
	If vAnswerResult <> Undefined Then
		For Each vAnswerResultRow In vAnswerResult Do
			vAnswerResultRowValue = vAnswerResultRow.Value;
			vAnswerResultRowKey = vAnswerResultRow.Key;
			
			If vAnswerResultRowKey = "contact" And (TypeOf(vAnswerResultRowValue) = Type("Number") OR TypeOf(vAnswerResultRowValue) = Type("String")) Then
				vID = Format(vAnswerResultRowValue, "NZ=0; NG=");
				InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(ExternalSystemInfoRef, "clientTagsField");
				InformationRegisters.ExternalSystemIntegrationData.WriteData(ExternalSystemInfoRef, "clientTagsField", "id", Undefined, Undefined, vID, vID);
				vResult = True;
			EndIf;
			
			If vAnswerResultRowKey = "contact_get" Then
				InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(ExternalSystemInfoRef, "clientTags");
				For Each vTagBitrix In vAnswerResultRowValue.LIST Do
					For Each vTag in vAllTags Do
						If TrimAll(vTagBitrix.VALUE) = TrimAll(vTag.Description) Then
							vTagID = Format(vTagBitrix.ID, "NZ=0; NG=");
							InformationRegisters.ExternalSystemIntegrationData.WriteData(ExternalSystemInfoRef, "clientTags", "id", vTag.Ref, Undefined, vTagID, vTagID);
						EndIf;
					EndDo;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	cmWait(1);
	
	Return vResult;
EndFunction // CreateAndUpdateTags

// --------------------------------------------------------------------------------
Function ClearUnusedTagsInBitrix(ExternalSystemInfoRef) Export
	
	vResult = False;
	
	ApiConnectionProps		=	GetConnectionProps(ExternalSystemInfoRef);
	
	// 02. API connection init.
	ApiConnection			=	ApiConnectionInit(ExternalSystemInfoRef, ApiConnectionProps);
	
	If ApiConnection = Undefined Then
		
		Return vResult;
		
	EndIf;
	
	vID					= Undefined;
	vClientTagsField 	= InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalSystemInfoRef, "clientTagsField");
	
	If vClientTagsField.Count() > 0 Then
		vID = vClientTagsField[0].id;	
	EndIf;
	
	If vID = Undefined Then
		Return True;
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Tags.Ref AS Ref,
	|	Tags.Description AS Description
	|FROM
	|	Catalog.Tags AS Tags
	|WHERE
	|	NOT Tags.DeletionMark
	|
	|ORDER BY
	|	Tags.Code";
	
	vAllTags = vQuery.Execute().Unload();
	
	vArrayToDetele 	= New Array;
	vMethod			= "crm.contact.userfield.get?id=" + vID;
	vResponse 		= ExecuteApiRequest(ApiConnection, ApiConnectionProps, vMethod, , , , , ExternalSystemInfoRef, , , "");
	If vResponse <> Undefined And vResponse.result <> Undefined Then
		InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(ExternalSystemInfoRef, "clientTags");
		For Each vTagBitrix in vResponse.result.LIST Do
			vFound = False;
			For Each vTag in vAllTags Do
				If TrimAll(vTagBitrix.VALUE) = TrimAll(vTag.Description) Then
					vFound = True;
					Break;
				EndIf;
			EndDo;
			
			vTagID = Format(vTagBitrix.ID, "NZ=0; NG=");
			If vFound Then					
				InformationRegisters.ExternalSystemIntegrationData.WriteData(ExternalSystemInfoRef, "clientTags", "id", vTag.Ref, Undefined, vTagID, vTagID);
			Else
				vArrayToDetele.Add(vTagID);
			EndIf;
			
		EndDo;
	EndIf;
	
	If vArrayToDetele.Count() > 0 Then
		i = 0;
		ValueForURL	= ConvertStringToURL(XMLString(vID));
		vMethod = "crm.contact.userfield.update?id=" + ValueForURL + "&fields[ID]=" + ValueForURL;
		For Each vTagToDelete in vArrayToDetele Do
			vMethod 	= vMethod + "&fields[LIST][" + i + "][ID]=" + vTagToDelete + "&fields[LIST][" + i + "][VALUE]=";	
			i = i + 1;
		EndDo;
		
		vResponse 		= ExecuteApiRequest(ApiConnection, ApiConnectionProps, vMethod, , , , , ExternalSystemInfoRef, , , "");
		If vResponse <> Undefined And vResponse.result <> Undefined Then
			Return True;
		Else
			Return False;
		EndIf;
	Else
		Return True;
	EndIf;
	
EndFunction

// --------------------------------------------------------------------------------
// 
// Returns:
//  ValueList - Extra Fields 
//
Function GetClientsExtraFields(pFieldsForClientsTable) Export 
	vExtraFields = New ValueList;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_CurrentReservation"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_CurrentReservation");
		vExtraField.Insert("EDIT_FORM_LABEL", "Бронирование");
		vExtraField.Insert("USER_TYPE_ID", "string");
		vExtraField.Insert("SHOW_IN_LIST", "Y");
		vExtraField.Insert("SHOW_FILTER", "N");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Reservation'; de = 'Reservierung'; ru = 'Бронирование'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_CurrentReservationRemarks"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_CurrentReservationRemarks");
		vExtraField.Insert("EDIT_FORM_LABEL", "Примечания к брони");
		vExtraField.Insert("USER_TYPE_ID", "string");
		vExtraField.Insert("SHOW_IN_LIST", "N");
		vExtraField.Insert("SHOW_FILTER", "N");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Reservation remarks'; de = 'Bemerkungen zur Reservierung'; ru = 'Примечания к бронированию'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_ReservationLink"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_ReservationLink");
		vExtraField.Insert("EDIT_FORM_LABEL", "Открыть в 1С-Отель");
		vExtraField.Insert("USER_TYPE_ID", "string");
		vExtraField.Insert("SHOW_IN_LIST", "N");
		vExtraField.Insert("SHOW_FILTER", "N");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Reservation link '; de = 'Reservierungslink'; ru = 'Ссылка на бронирования'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_GuestReservationLink"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_GuestReservationLink");
		vExtraField.Insert("EDIT_FORM_LABEL", "Ссылка для гостя");
		vExtraField.Insert("USER_TYPE_ID", "url");
		vExtraField.Insert("SHOW_IN_LIST", "N");
		vExtraField.Insert("SHOW_FILTER", "N");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Link for guest'; de = 'Link für Gast'; ru = 'Ссылка для гостя'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_ReservationCheckInDate"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_ReservationCheckInDate");
		vExtraField.Insert("EDIT_FORM_LABEL", "Заезд");
		vExtraField.Insert("USER_TYPE_ID", "date");
		vExtraField.Insert("SHOW_IN_LIST", "Y");
		vExtraField.Insert("SHOW_FILTER", "Y");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Check in date'; de = 'Check-in Datum'; ru = 'Дата заезда'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_ReservationCheckOutDate"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_ReservationCheckOutDate");
		vExtraField.Insert("EDIT_FORM_LABEL", "Выезд");
		vExtraField.Insert("USER_TYPE_ID", "date");
		vExtraField.Insert("SHOW_IN_LIST", "Y");
		vExtraField.Insert("SHOW_FILTER", "Y");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Check out date'; de = 'Check-out Datum'; ru = 'Дата выезда'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_ReservationStatus"))).Count() = 0 Then	
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_ReservationStatus");
		vExtraField.Insert("EDIT_FORM_LABEL", "Статус брони");
		vExtraField.Insert("USER_TYPE_ID", "string");
		vExtraField.Insert("SHOW_IN_LIST", "N");
		vExtraField.Insert("SHOW_FILTER", "N");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Reservation status'; de = 'Reservierungsstatus'; ru = 'Статус брони'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_Nights"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_Nights");
		vExtraField.Insert("EDIT_FORM_LABEL", "Ночей");
		vExtraField.Insert("USER_TYPE_ID", "integer");
		vExtraField.Insert("SHOW_IN_LIST", "Y");
		vExtraField.Insert("SHOW_FILTER", "Y");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Number of nights'; de = 'Anzahl der Nächte'; ru = 'Количество ночей'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_Visits"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_Visits");
		vExtraField.Insert("EDIT_FORM_LABEL", "Заездов");
		vExtraField.Insert("USER_TYPE_ID", "integer");
		vExtraField.Insert("SHOW_IN_LIST", "Y");
		vExtraField.Insert("SHOW_FILTER", "Y");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Number of visits'; de = 'Anzahl der Besuche'; ru = 'Количество заездов'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_AvgDepth"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_AvgDepth");
		vExtraField.Insert("EDIT_FORM_LABEL", "Глубина бронирования");
		vExtraField.Insert("USER_TYPE_ID", "integer");
		vExtraField.Insert("SHOW_IN_LIST", "Y");
		vExtraField.Insert("SHOW_FILTER", "Y");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Reservation depth'; de = 'Reservierungstiefe'; ru = 'Глубина бронирования'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_BonusesSumm"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_BonusesSumm");
		vExtraField.Insert("EDIT_FORM_LABEL", "Бонусов");
		vExtraField.Insert("USER_TYPE_ID", "integer");
		vExtraField.Insert("SHOW_IN_LIST", "Y");
		vExtraField.Insert("SHOW_FILTER", "Y");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Number of bonuses'; de = 'Anzahl der Boni'; ru = 'Количество бонусов'"));
	EndIf;
	
	If pFieldsForClientsTable.FindRows(New Structure("AttributeB24", Upper("UF_CRM_MemberLevel"))).Count() = 0 Then
		vExtraField = New Structure;
		vExtraField.Insert("FIELD_NAME", "UF_CRM_MemberLevel");
		vExtraField.Insert("EDIT_FORM_LABEL", "Уровень программы лояльности");
		vExtraField.Insert("USER_TYPE_ID", "string");
		vExtraField.Insert("SHOW_IN_LIST", "Y");
		vExtraField.Insert("SHOW_FILTER", "Y");
		vExtraField.Insert("ID", "");
		vExtraFields.Add(vExtraField, NStr("en = 'Loyalty program level'; de = 'Ebene des Treueprogramms'; ru = 'Уровень программы лояльности'"));
	EndIf;
	
	Return vExtraFields;
EndFunction // GetClientsExtraFields

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function ClientSecret()
	Return "m0nh1Nl107D4uYPucNXVoE009F42FetO7TNlWzGYcOzJCS9bZW";
EndFunction

// --------------------------------------------------------------------------------
Procedure ExportDataRow(pApiConnection, pApiConnectionProps, pRequestDatas, pDatas, pExternalSystemInfoRef, pDataType, pStartSynchronizationTime, rSuccessCounter, rErrorsCounter)
	vLogDataContainerForItem = Undefined;
	
	vAnswerStructure = ExecuteApiRequestBatchJSON(pApiConnection, pApiConnectionProps, pRequestDatas, vLogDataContainerForItem, 0, pExternalSystemInfoRef);
	
	If vAnswerStructure = Undefined Then
		rErrorsCounter = rErrorsCounter + pRequestDatas.Count();
		Return;
	EndIf;
	
	vAnswerResult = GetPropertyOfStructure(vAnswerStructure, "result.result_error");
	If vAnswerResult <> Undefined Then
		For Each vAnswerResultRow In vAnswerResult Do
			vAnswerResultRowValue = vAnswerResultRow.Value;
			vAnswerResultRowKey = vAnswerResultRow.Key;
			
			vError = "";
			vErrorDescription = "";
			vAnswerResultRowValue.Property("error", vError);
			vAnswerResultRowValue.Property("error_description", vErrorDescription);
			
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pExternalSystemInfoRef, "Bitrix24.ExportDataRow", Enums.ExternalSystemEventTypes.Error, pRequestDatas[vAnswerResultRowKey], vError, vErrorDescription);
			
			vSingleClientDataRow = pDatas[vAnswerResultRowKey];
			vSingleClientDataRow.Success = False;
			
			If ValueIsFilled(vSingleClientDataRow.B24ContactID) And (StrFind(Lower(vError), "not found") > 0 Or StrFind(Lower(vErrorDescription), "not found") > 0) Then
				InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(pApiConnectionProps.ExternalSystemInfo, Lower(pDataType), "updatePeriod", vSingleClientDataRow.Ref, Undefined, Undefined, vSingleClientDataRow.B24ContactID);
			EndIf;
			
			rErrorsCounter = rErrorsCounter + 1;
		EndDo;
	EndIf;
	
	vAnswerResult = GetPropertyOfStructure(vAnswerStructure, "result.result");
	If vAnswerResult <> Undefined Then
		For Each vAnswerResultRow In vAnswerResult Do
			vAnswerResultRowValue = vAnswerResultRow.Value;
			vAnswerResultRowKey = vAnswerResultRow.Key;
			
			If StrStartsWith(pRequestDatas[vAnswerResultRowKey], "crm.item") Then
				vAnswerResultRowValue = GetPropertyOfStructure(vAnswerResultRowValue, "item.Id");
			EndIf;
			
			vExtCode = "";
			
			vSingleClientDataRow = pDatas[vAnswerResultRowKey];
			
			vSingleClientDataRow.Success = False;
			If ValueIsFilled(vSingleClientDataRow.B24ContactID) And TypeOf(vAnswerResultRowValue) = Type("Boolean") Then
				vSingleClientDataRow.Success = (vAnswerResultRowValue = True);
				vExtCode = vSingleClientDataRow.B24ContactID;
			Else
				vSingleClientDataRow.Success = TypeOf(vAnswerResultRowValue) = Type("Number") And vAnswerResultRowValue > 0;
				vExtCode = vAnswerResultRowValue;
			EndIf;
			
			If vSingleClientDataRow.Success Then
				rSuccessCounter = rSuccessCounter + 1;
			EndIf;
			
			If ValueIsFilled(vExtCode) Then
				If ValueIsFilled(vSingleClientDataRow.B24ContactID) Then
					InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(pApiConnectionProps.ExternalSystemInfo, Lower(pDataType), "updatePeriod", vSingleClientDataRow.Ref, Undefined, Undefined, vSingleClientDataRow.B24ContactID);
				EndIf;
				vSingleClientDataRow.B24ContactID = Format(vExtCode, "NZ=0; NG=");
				InformationRegisters.ExternalSystemIntegrationData.WriteData(pApiConnectionProps.ExternalSystemInfo, Lower(pDataType), "updatePeriod", vSingleClientDataRow.Ref, Undefined, pStartSynchronizationTime, vSingleClientDataRow.B24ContactID);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // ExportDataRow

// --------------------------------------------------------------------------------
Function GetDealsByCheackInDate(pExternalSystemInfoRef, pStartDate, pEndDate, pUnmappedOnly)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemIntegrationData.RefKey1 AS GroupType
	|INTO DoNotUnloadGroupTypes
	|FROM
	|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|WHERE
	|	ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef
	|	AND ExternalSystemIntegrationData.DataType = ""DoNotUnloadGroupType""
	|	AND ExternalSystemIntegrationData.DataValue = TRUE
	|
	|GROUP BY
	|	ExternalSystemIntegrationData.RefKey1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GroupTypesList.Ref AS GroupType
	|INTO GroupTypesList
	|FROM
	|	(SELECT
	|		GroupTypes.Ref AS Ref
	|	FROM
	|		Catalog.GroupTypes AS GroupTypes
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VALUE(Catalog.GroupTypes.EmptyRef)) AS GroupTypesList
	|		LEFT JOIN DoNotUnloadGroupTypes AS DoNotUnloadGroupTypes
	|		ON GroupTypesList.Ref = DoNotUnloadGroupTypes.GroupType
	|WHERE
	|	DoNotUnloadGroupTypes.GroupType IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExternalSystemIntegrationData.DataValue AS Value
	|INTO DoNotUnloadTransactionsByBusinessBlock
	|FROM
	|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|WHERE
	|	ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef
	|	AND ExternalSystemIntegrationData.DataType = ""DoNotUnloadTransactionsByBusinessBlock""
	|
	|GROUP BY
	|	ExternalSystemIntegrationData.DataValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsList.GuestGroup AS GuestGroup
	|FROM
	|	(SELECT
	|		Reservation.GuestGroup AS GuestGroup,
	|		RoomQuotas.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock) AS IsBusinessBlock,
	|		GuestGroups.GroupType AS GroupType
	|	FROM
	|		Document.Reservation AS Reservation
	|			LEFT JOIN Catalog.RoomQuotas AS RoomQuotas
	|			ON Reservation.RoomQuota = RoomQuotas.Ref
	|			LEFT JOIN Catalog.GuestGroups AS GuestGroups
	|			ON Reservation.GuestGroup = GuestGroups.Ref
	|	WHERE
	|		Reservation.Posted
	|		AND Reservation.CheckInDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|		AND CASE
	|				WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|					THEN Reservation.Hotel = &qHotel
	|				ELSE TRUE
	|			END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Accommodation.GuestGroup,
	|		RoomQuotas.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock),
	|		GuestGroups.GroupType
	|	FROM
	|		Document.Accommodation AS Accommodation
	|			LEFT JOIN Catalog.RoomQuotas AS RoomQuotas
	|			ON Accommodation.RoomQuota = RoomQuotas.Ref
	|			LEFT JOIN Catalog.GuestGroups AS GuestGroups
	|			ON Accommodation.GuestGroup = GuestGroups.Ref
	|	WHERE
	|		Accommodation.Posted
	|		AND Accommodation.CheckInDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|		AND CASE
	|				WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|					THEN Accommodation.Hotel = &qHotel
	|				ELSE TRUE
	|			END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ResourceReservation.GuestGroup,
	|		FALSE,
	|		GuestGroups.GroupType
	|	FROM
	|		Document.ResourceReservation AS ResourceReservation
	|			LEFT JOIN Catalog.GuestGroups AS GuestGroups
	|			ON ResourceReservation.GuestGroup = GuestGroups.Ref
	|	WHERE
	|		ResourceReservation.Posted
	|		AND ResourceReservation.DateTimeFrom BETWEEN &qPeriodFrom AND &qPeriodTo
	|		AND CASE
	|				WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|					THEN ResourceReservation.Hotel = &qHotel
	|				ELSE TRUE
	|			END) AS DocumentsList
	|		INNER JOIN GroupTypesList AS GroupTypesList
	|		ON DocumentsList.GroupType = GroupTypesList.GroupType
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""deals"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND DocumentsList.GuestGroup = ExternalSystemIntegrationData.RefKey1
	|		LEFT JOIN DoNotUnloadTransactionsByBusinessBlock AS DoNotUnloadTransactionsByBusinessBlock
	|		ON (TRUE)
	|WHERE
	|	DocumentsList.GuestGroup <> VALUE(Catalog.GuestGroups.EmptyRef)
	|	AND CASE
	|			WHEN &qUnmappedOnly
	|				THEN ExternalSystemIntegrationData.DataValue IS NULL
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN ISNULL(DoNotUnloadTransactionsByBusinessBlock.Value, FALSE)
	|				THEN NOT ISNULL(DocumentsList.IsBusinessBlock, FALSE)
	|			ELSE TRUE
	|		END
	|
	|GROUP BY
	|	DocumentsList.GuestGroup
	|
	|ORDER BY
	|	GuestGroup";
	
	vQuery.SetParameter("qPeriodFrom", ?(pStartDate = Undefined, '00010101', BegOfDay(pStartDate)));
	vQuery.SetParameter("qPeriodTo", ?(pEndDate = Undefined Or Not ValueIsFilled(pEndDate), '39991231235959', EndOfDay(pEndDate)));
	vQuery.SetParameter("qHotel", pExternalSystemInfoRef.Hotel);
	vQuery.SetParameter("qExternalSystemRef", pExternalSystemInfoRef);
	vQuery.SetParameter("qUnmappedOnly", pUnmappedOnly);
	
	Return vQuery.Execute().Unload().UnloadColumn(0);
EndFunction // GetDealsByCheackInDate

// --------------------------------------------------------------------------------
//	Description: Processes opertaions to import single client to 1C by request string to API.
//	Returns: True in success and False in failed result.
Function ImportSingleDataRow(pApiConnection, pApiConnectionProps, pRequestDatas, pDatas, FieldsMap, pExternalSystemInfoRef, pDataType, pFieldPMSCode = Undefined)
	vResult = New Structure("Created, Found, Success, Failed", 0, 0, 0, 0);
	vLogDataContainerForItem = Undefined;
	
	vAnswerStructure = ExecuteApiRequestBatchJSON(pApiConnection, pApiConnectionProps, pRequestDatas, vLogDataContainerForItem, 0, pExternalSystemInfoRef, 0);
	
	If vAnswerStructure = Undefined Then
		vResult.Failed = pRequestDatas.Count();
		Return vResult;
	EndIf;
	
	vAnswerResult = GetPropertyOfStructure(vAnswerStructure, "result.result_error");
	If vAnswerResult <> Undefined Then
		vResult.Failed = vAnswerResult.Count();
	EndIf;
	
	vAnswerResult = GetPropertyOfStructure(vAnswerStructure, "result.result");
	If vAnswerResult <> Undefined Then
		For Each vAnswerResultRow In vAnswerResult Do
			vAnswerResultRowKey = vAnswerResultRow.Key;
			vAnswerResultRowValue = vAnswerResultRow.Value;
			
			vDataStructureB24 = Undefined;
			For Each vAnswerResultRowValueRow In vAnswerResultRowValue Do
				vDataStructureB24 = vAnswerResultRowValueRow;
				Break;
			EndDo;
			
			If vDataStructureB24 = Undefined Then
				Continue;
			EndIf;
			
			If Not ValueIsFilled(pDatas[vAnswerResultRowKey].Ref) Then
				If pDataType = "Clients" Then
					vEmail = Undefined;
					vPhone = Undefined;
					vLastName = Undefined;
					vFirstName = Undefined;
					vSecondName = Undefined;
					vDateOfBirth = Undefined;
					vPMSCode = Undefined;
					vDataStructureB24.Property("EMAIL", vEmail);
					vDataStructureB24.Property("PHONE", vPhone);
					vDataStructureB24.Property("LAST_NAME", vLastName);
					vDataStructureB24.Property("SECOND_NAME", vSecondName);
					vDataStructureB24.Property("NAME", vFirstName);
					vDataStructureB24.Property("BIRTHDATE", vDateOfBirth);
					
					If pFieldPMSCode <> Undefined Then
						vDataStructureB24.Property(pFieldPMSCode, vPMSCode);
					EndIf;
					
					If vLastName = Undefined OR IsBlankString(vLastName) Then
						vResult.Failed = vResult.Failed + 1;
						Continue;
					EndIf;
					
					pDatas[vAnswerResultRowKey].Ref = FindClientByAdditionalFields(pApiConnectionProps.ExternalSystemInfo, vLastName, vEmail, vPhone, vFirstName, vSecondName, vDateOfBirth, vPMSCode);
				ElsIf pDataType = "Customers" Then
					vCustomerDescription = Undefined;
					vDataStructureB24.Property("TITLE",  vCustomerDescription);
					vTIN = pDatas[vAnswerResultRowKey].TIN;
					pDatas[vAnswerResultRowKey].Ref = FindCustomerByAdditionalFields(pApiConnectionProps.ExternalSystemInfo, vCustomerDescription, vTIN);
				EndIf;
			EndIf;
			
			If ValueIsFilled(pDatas[vAnswerResultRowKey].Ref) Then
				vDataObject = pDatas[vAnswerResultRowKey].Ref.GetObject();
				vResult.Found = vResult.Found + 1;
			Else
				If pDataType = "Clients" Then
					vDataObject = Catalogs.Clients.CreateItem();
				ElsIf pDataType = "Customers" Then
					vDataObject= Catalogs.Customers.CreateItem();
				EndIf;
				
				vDataObject.SetNewCode();
				vResult.Created = vResult.Created + 1;
			EndIf;
			
			For Each vKeyAndValue In vDataStructureB24 Do
				vKey1C = FieldsMap[vKeyAndValue.Key];
				If vKey1C <> Undefined And vKey1C <> "Code" Then
					ConvertBitrixValueTo1C(vKeyAndValue.Value, vDataObject[vKey1C], pApiConnection, vLogDataContainerForItem, pExternalSystemInfoRef);
				EndIf;
			EndDo;
			
			Try
				vDataObject.Write();
				
				pDatas[vAnswerResultRowKey].Ref = vDataObject.Ref;
				vResult.Success = vResult.Success + 1;
			Except
				vResult.Failed = vResult.Failed + 1;
			EndTry;
			
			If ValueIsFilled(pDatas[vAnswerResultRowKey].ID) And ValueIsFilled(pDatas[vAnswerResultRowKey].Ref) Then
				InformationRegisters.ExternalSystemIntegrationData.WriteData(pApiConnectionProps.ExternalSystemInfo, Lower(pDataType), "updatePeriod", pDatas[vAnswerResultRowKey].Ref, Undefined, CurrentSessionDate(), Format(pDatas[vAnswerResultRowKey].ID, "NG="));
			EndIf;
		EndDo;
	EndIf;
	cmWait(1);
	Return vResult;
EndFunction // ImportSingleDataRow

// --------------------------------------------------------------------------------
//	Description: Makes API request to Bitrix ti geet IDs of clients are must to be imported to 1C.
//	Returns: Array of IDs of clients.
Function GetDataChangesToImport(ExternalSystemInfoRef, ApiConnection, ApiConnectionProps, LogDataContainer, pDataType)
	vArrayOfDataIds = New Array;
	vApiMethodForEvents = GetApiMethod("Event", "Offline", "Get");
	
	If pDataType = "Clients" Then
		EventNamesArray = GetEventsListForData(False, True);
	ElsIf pDataType = "Customers" Then
		EventNamesArray = GetEventsListForData(True, False);
	EndIf;
	
	EventsForRequest = New Array;
	For Each EventName In EventNamesArray Do
		EventsForRequest.Add("filter[event_name]=" + EventName);
	EndDo;
	
	vIsNextGoing = True;
	
	vHasErrors = False;
	While vIsNextGoing Do
		AnswerStructure = ExecuteApiRequest(ApiConnection, ApiConnectionProps, vApiMethodForEvents, EventsForRequest, LogDataContainer, , , ExternalSystemInfoRef, , , "");
		vResultArray = GetPropertyOfStructure(AnswerStructure, "result.result");
		
		If vResultArray = Undefined OR TypeOf(vResultArray) <> Type("Array") Then
			vHasErrors = True;
			Break;
		ElsIf vResultArray.Count() = 0 Then
			Break;
		EndIf;
		
		vDataCount = 0;
		For Each vResultItemStructure In vResultArray Do
			vEventsArray = GetPropertyOfStructure(vResultItemStructure, "events");
			
			If vEventsArray = Undefined OR vEventsArray.Count() = 0 Then
				Continue;
			EndIf;
			
			// 03. Read events.
			For Each SingleEventStructure In vEventsArray Do
				vDataId = Format(GetPropertyOfStructure(SingleEventStructure, "EVENT_DATA.FIELDS.ID"), "NZ=; NG=");
				If vDataId <> Undefined And vArrayOfDataIds.Find(vDataId) = Undefined Then
					vArrayOfDataIds.Add(vDataId);
				EndIf;
			EndDo;
			
			vDataCount = vDataCount + vEventsArray.Count();
		EndDo;
		
		vIsNextGoing = vDataCount >= 50;
		cmWait(1);
	EndDo;
	
	If vHasErrors And vArrayOfDataIds.Count() = 0 Then
		strError = GetNString(ApiConnectionProps.Server, "Не удалось получить изменения для портала %1", "It's unable to get changes from %1");
		LogDataAdd(LogDataContainer, strError, True);
	ElsIf vArrayOfDataIds.Count() = 0 Then
		strMessage = GetNString(ApiConnectionProps.Server, "Отсутствуют данные для импорта в 1С с портала %1", "There is no any change to import to 1C from %1");
		LogDataAdd(LogDataContainer, strMessage,);
	EndIf;
	
	Return vArrayOfDataIds;
EndFunction // GetDataChangesToImport

// --------------------------------------------------------------------------------
//	Description: Looks up clients elemets by Bitrix 24 IDs.
//	Returns: Value table with cols: ID, Ref, Descrition.
Function GetDataByBitrixIds(pArrayOfDataIds, pExternalSystemInfoRef, pDataType)
	vQuery = New Query;
	
	vQuery.Text =
	"SELECT
	|	TableData.ID AS ID
	|INTO tt_TableData
	|FROM
	|	&TableData AS TableData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	tt_TableData.ID AS ID,
	|	ISNULL(ExternalSystemIntegrationData.RefKey1, &qEpmtyRef) AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.RefKey1.Description, ""<object not found>"") AS Description,
	|	CAST("""" AS STRING(14)) AS TIN
	|FROM
	|	tt_TableData AS tt_TableData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = &qDataType)
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND tt_TableData.ID = ExternalSystemIntegrationData.ExternalSystemDataCode";
	
	vTableData = New ValueTable;
	vTableData.Columns.Add("ID", cmGetStringTypeDescription(100));
	
	For Each vArrayOfDataIdRow In pArrayOfDataIds Do
		vNewRow = vTableData.Add();
		vNewRow.ID = vArrayOfDataIdRow;
	EndDo;
	
	vTableData.GroupBy("ID");
	
	vQuery.SetParameter("TableData", vTableData);
	vQuery.SetParameter("qDataType", Lower(pDataType));
	vQuery.SetParameter("qExternalSystemRef", pExternalSystemInfoRef);
	
	If pDataType = "Clients" Then
		vQuery.SetParameter("qEpmtyRef", Catalogs.Clients.EmptyRef());
	Else
		vQuery.SetParameter("qEpmtyRef", Catalogs.Customers.EmptyRef());
	EndIf;
	
	Return vQuery.Execute().Unload();
EndFunction // GetDataByBitrixIds

// --------------------------------------------------------------------------------
Function FindCustomerByAdditionalFields(pExternalSystemRef, pDescription, pTIN = "")
	
	vResult = Catalogs.Customers.EmptyRef();
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	Customers.Ref AS Ref
	|FROM
	|	Catalog.Customers AS Customers
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""customers"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND Customers.Ref = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	NOT Customers.DeletionMark
	|	AND ExternalSystemIntegrationData.ExternalSystemDataCode IS NULL
	|	AND (Customers.Description LIKE &qDescription
	|			OR Customers.LegacyName LIKE &qDescription
	|			OR CASE
	|				WHEN &qTIN <> """"
	|					THEN Customers.TIN = &qTIN
	|				ELSE FALSE
	|			END)";
	
	Query.SetParameter("qDescription", "%" + pDescription + "%");
	Query.SetParameter("qTIN", pTIN);
	Query.SetParameter("qExternalSystemRef", pExternalSystemRef);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		vResult = SelectionDetailRecords.Ref;
	EndDo;
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
//	Description: Proceeds and http request answer and writes access + refresh tokens to External system objest then.
//	Returns: True in success.
Function WriteTokensFromHttpResponse(HttpRequestAnswer, ApiConnectionProps, LogDataContainer)
	
	vResult					=   False;
	NewAccessToken			=	Undefined;
	NewRefreshToken			=	Undefined;
	
	strOperationName		=	GetNString(ApiConnectionProps.Server, "Запись нового токена для портала Битрикс 24 %1", "New token saving for Bitrix 24 portal %1");
	OperationID				=	LogDataStart(LogDataContainer, strOperationName);
	
	If HttpRequestAnswer.StatusCode <> 200 Then
		
		strError			=	GetNString(HttpRequestAnswer.StatusCode, "При попытке получить новый токен, ответ сервера имеет статус %1", "Trying to get access token server returned status code %1");
		LogDataAdd(LogDataContainer, strError, True);
		
	Else
		
		strAnswer			=	HttpRequestAnswer.GetBodyAsString();
		AnswerStructure		=	ConvertJsonToStructure( ConvertSpecCharsToString(strAnswer) );
		
		If AnswerStructure = Undefined OR NOT AnswerStructure.Property("access_token", NewAccessToken) OR NOT AnswerStructure.Property("refresh_token", NewRefreshToken) Then
			
			strError		=	GetNString(HttpRequestAnswer.StatusCode, "Ответ сервера не содержит новый токен %1", "Request answer doesn't contain new access token %1");
			LogDataAdd(LogDataContainer, strError, True);
			
		EndIf;
		
	EndIf;
	
	
	// 04. Write result.
	If NewAccessToken <> Undefined And NewRefreshToken <> Undefined Then
		
		Try
			
			SystemInfoObject	=	ApiConnectionProps.ExternalSystemInfo.GetObject();
			
			SystemInfoObject.OAuth_AccessToken				=	NewAccessToken;
			SystemInfoObject.OAuth_RefreshToken				=	NewRefreshToken;
			SystemInfoObject.DataExchange.Load				=	True;
			SystemInfoObject.SessionStartTime				= CurrentSessionDate();
			SystemInfoObject.Write();
			
			strMessage							=	GetNString(NewAccessToken, "Токен был успешно обновлен: %1", "Access token update is succeed: %1");
			LogDataAdd(LogDataContainer, strMessage, False);
			
			ApiConnectionProps.Token			=	NewAccessToken;
			ApiConnectionProps.RefreshToken		=	NewRefreshToken;
			vResult = True;
		Except
			
			strError			=	BriefErrorDescription(ErrorInfo());
			LogDataAdd(LogDataContainer, strError, True);
			
		EndTry;
		
	EndIf;
	
	LogDataFinish(LogDataContainer, OperationID);
	
	Return vResult;
	
EndFunction //  WriteTokensFromHttpResponse()

// --------------------------------------------------------------------------------
Function ConvertValueStorageToString(ValueStorage)
	
	If TypeOf(ValueStorage) = Type("ValueStorage") Then
		
		BinaryData	=	ValueStorage.Get();
		
		If BinaryData <> Undefined And TypeOf(BinaryData) = Type("BinaryData") Then
			
			Return Base64String(BinaryData);
			
		EndIf;
		
	ElsIf TypeOf(ValueStorage) = Type("BinaryData") Then
		
		Return Base64String(BinaryData);
		
	EndIf;
	
	
	Return "";
	
EndFunction //  ConvertValueStorageToString()

// --------------------------------------------------------------------------------
Function getSourcesOfBusiness(ValueBitrix)
	Return cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), "BITRIX24", "SourcesOfBusiness", ValueBitrix);
EndFunction

// --------------------------------------------------------------------------------
Procedure ConvertBitrixValueTo1C(val ValueBitrix, Value1C, ApiConnection, LogDataContainer = Undefined, ExternalSystemInfoRef)
	
	TypeOf1cValue	=	TypeOf(Value1C);
	TypeOfBxValue	=	TypeOf(ValueBitrix);
	
	If TypeOfBxValue = Type("Array") Then
		
		If ValueBitrix.Count() = 0 Then
			
			ValueBitrix	=	Undefined;
			
		Else
			
			ValueBitrix	=	ValueBitrix[0];
			
		EndIf;
		
	EndIf;
	
	
	If TypeOf1cValue = Type("ValueStorage") And TypeOf(ValueBitrix) = TYpe("Structure") And ValueBitrix.Property("downloadUrl") Then
		
		BinaryData	=	GetFileByUrl(ApiConnection, ValueBitrix.downloadUrl, LogDataContainer);
		
		If TypeOf(BinaryData) = Type("BinaryData") Then
			
			Value1C		=	New ValueStorage(BinaryData);
			
		EndIf;
		
	ElsIf TypeOf1cValue = Type("String") And TypeOf(ValueBitrix) = Type("Structure") And ValueBitrix.Property("VALUE") Then
		
		If Not IsBlankString(ValueBitrix.VALUE) Then
			Value1C		=	ValueBitrix.VALUE;
		EndIf;
		
	ElsIf TypeOf1cValue = Type("CatalogRef.SourcesOfBusiness") Then
		
		Value1C = getSourcesOfBusiness(ValueBitrix);
		
	ElsIf TypeOf1cValue = Type("CatalogRef.ClientTypes") Then
		
		vMappingData = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalSystemInfoRef, "ClientTypes", , , , , ValueBitrix);
		If vMappingData.Count() > 0 Then
			Value1C = vMappingData[0].RefKey1;
		Else
			Value1C = Undefined;	
		EndIf;
		
	ElsIf TypeOf1cValue = Type("CatalogRef.CustomerTypes") Then
		
		vMappingData = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalSystemInfoRef, "CustomerTypes", , , , , ValueBitrix);
		If vMappingData.Count() > 0 Then
			Value1C = vMappingData[0].RefKey1;
		Else
			Value1C = Undefined;	
		EndIf;
		
	ElsIf TypeOf1cValue = Type("CatalogRef.CustomerIndustries") Then
		
		vMappingData = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalSystemInfoRef, "CustomerIndustries", , , , , ValueBitrix);
		If vMappingData.Count() > 0 Then
			Value1C = vMappingData[0].RefKey1;
		Else
			Value1C = Undefined;	
		EndIf;
		
	Elsif TypeOf1cValue = TypeOf(ValueBitrix) Then
		
		Value1C		=	ValueBitrix;
		
	Else
		
		Try
			
			Value1C	=	XMLValue(TypeOf1cValue, ValueBitrix);
			
		Except
			
			Value1C	=	ValueBitrix;
			
		EndTry;
		
	EndIf;
	
EndProcedure //  ConvertBitrixValueTo1C()

// --------------------------------------------------------------------------------
Function  Convert1cValueToBitrix(Value1C, TypeB24)
	
	If StrCompare(TypeB24, "file") = 0 Then
		
		ValueBitrix		=	ConvertValueStorageToString(Value1C);
		
	ElsIf TypeOf(Value1C) = Type("CatalogRef.Countries") Then
		
		ValueBitrix		=	TrimAll(Value1C);
		
	ElsIf TypeOf(Value1C) = Type("CatalogRef.Clients") Then
		
		ValueBitrix		=	TrimAll(Value1C.FullName);
		
	Else
		
		ValueBitrix		=	XMLString(Value1C);   
		
	EndIf;
	
	Return ValueBitrix;
	
EndFunction //  ConvertBitrixValueTo1C()

// --------------------------------------------------------------------------------
//	Description: Makes request string to API from Data container (structure, query selection) and types of B24 fields.
//	Returns: Array with string.
Function ComposeArrayOfFieldsToExport(DataContainer, FieldsB24TypesMap)
	
	tmplMultiField		=	"fields[{FieldB24}][0][VALUE]={ValueOfFieldB24}&fields[{FieldB24}][0][VALUE_TYPE]=WORK";
	tmplOrdinary		=	"fields[{FieldB24}]={ValueOfFieldB24}";
	
	
	FieldsArrayToExport	=	New Array;
	
	For Each FieldKeyValue In FieldsB24TypesMap Do
		
		FieldB24		=	FieldKeyValue.Key;
		TypeOfField		=	FieldKeyValue.Value;
		
		If TypeOf(DataContainer[FieldB24]) = Type("Date") And NOT ValueIsFilled(DataContainer[FieldB24]) Then
			Continue;
		EndIf;
		
		ValueOfFieldB24	=	Convert1cValueToBitrix(DataContainer[FieldB24], TypeOfField);
		
		// Create string request.
		If StrCompare(TypeOfField, "crm_multifield") = 0 Then
			
			If FieldB24 = "EMAIL" Or FieldB24 = "PHONE" Then
				If IsBlankString(ValueOfFieldB24) Then
					Continue;
				EndIf;
			EndIf;
			
			If FieldB24 = "EMAIL" And Not tcCommonFunctionOnClientServer.CheckEmail(ValueOfFieldB24, , False) Then
				Continue;
			ElsIf FieldB24 = "PHONE" And (Not cmIsNumber(ValueOfFieldB24) Or StrLen(ValueOfFieldB24) < 3) Then
				Continue;
			EndIf;
			
			strField	=	tmplMultiField;
			strField	=	StrReplace(strField, "{FieldB24}", FieldB24);
			strField	=	StrReplace(strField, "{ValueOfFieldB24}", ConvertStringToURL(ValueOfFieldB24));
			
		Else
			
			strField	=	tmplOrdinary;
			strField	=	StrReplace(strField, "{FieldB24}", FieldB24);
			strField	=	StrReplace(strField, "{ValueOfFieldB24}", ConvertStringToURL(ValueOfFieldB24));
			
			
		EndIf;
		
		FieldsArrayToExport.Add(strField);
		
	EndDo;
	
	Return FieldsArrayToExport;
	
EndFunction //  CreateExportFieldsStructure()

// --------------------------------------------------------------------------------
//	Description: Writes logs to log evet in 1C.
Procedure LogDataWrite(LogDataContainer)
	
	// 01. Check for information is correct.
	If LogDataContainer = Undefined OR NOT LogDataContainer.Property("Key") Then
		
		Return;
		
	EndIf;
	
	
	// 02. Local vars init.
	DurationOf			=	CurrentUniversalDateInMilliseconds() - LogDataContainer.InitPoint;
	
	StartDateTime		=	LogDataContainer.InitDateTime;
	FinishDateTime		=	CurrentDate();
	
	CountOfTotal		=	LogDataContainer.Events.Count();
	CountOfErrors		=	LogDataContainer.CountOfErrors;
	
	
	// 03. Compose log data message to log journal.
	ArrayOfParams		=	New Array;
	ArrayOfParams.Add(ConvertNumberToString(DurationOf/1000));
	ArrayOfParams.Add(ConvertDateToString(StartDateTime, , False));
	ArrayOfParams.Add(ConvertDateToString(FinishDateTime, , False));
	ArrayOfParams.Add(ConvertNumberToString(CountOfTotal));
	ArrayOfParams.Add(ConvertNumberToString(CountOfErrors));
	
	strLogDataInfo	=	GetNString(ArrayOfParams, "Длительность %1 с. (%2-%3), событий %4 из них %5 с ошибками", "Duration %1 с. (%2-%3), total events  %4 and %5 with errors",);
	strLogDataInfo	=	strLogDataInfo + Chars.LF + LogDataGetEvents(LogDataContainer);
	
	
	WriteLogEvent(LogDataContainer.Key, EventLogLevel.Information, Metadata.DataProcessors.Bitrix24, LogDataContainer.DataRef, strLogDataInfo)
	
EndProcedure //  LogDataWrite ()

// --------------------------------------------------------------------------------
Function hex(Val pValue) 
	pValue = Number(pValue);
	If pValue <= 0 Then 
		vResult = "0";
	Else
		pValue = Int(pValue);
		vResult = "";
		While pValue > 0 Do
			vResult = Mid("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", pValue%16 + 1, 1)+vResult;
			pValue = Int(pValue/16) ;
		EndDo;
	EndIf;
	If StrLen(vResult) < 2 Then
		vResult = "0" + vResult;
	EndIf; 
	Return "%" + vResult;
EndFunction // hex

// --------------------------------------------------------------------------------
Function GetB24EmployeeID(ExternalSystemInfoRef, pAccessToken, pB24Login, pHTTPConnection)
	vID = 0;
	vResource = "/rest/user.get.json?auth="+TrimAll(pAccessToken)+"&EMAIL="+TrimAll(pB24Login);
	vRequest  = New HTTPRequest(vResource);
	vResponse = SendHTTPRequest(ExternalSystemInfoRef, , vResource, "GET", , , , , , , pHTTPConnection, vRequest);
	vResponseText = vResponse.Body;
	
	vEmployeesTable = GetB24EmployeeTableFromJSON(vResponseText);
	If vEmployeesTable.Count() = 1 Then
		vID = TrimAll(vEmployeesTable.Get(0).ID);
		If Not ValueIsFilled(vID) Then
			vID = 0;
		EndIf;
	EndIf;
	Return vID;
EndFunction // GetB24EmployeeID

// --------------------------------------------------------------------------------
Function GetB24EmployeeTableFromJSON(pJSON)
	vEmployeeTable = New ValueTable;
	vEmployeeTable.Columns.Add("ID");
	vEmployeeTable.Columns.Add("FirstName");
	vEmployeeTable.Columns.Add("LastName");
	vEmployeeTable.Columns.Add("SecondName");
	vEmployeeTable.Columns.Add("EMail");
	vEmployeesCount = 0;
	If Left(pJSON, 1) = "{" Then
		vData = StrReplace(pJSON, "{""result"":[", "");
		vData = StrReplace(vData, "]", "");
		vStrRows = StrReplace(vData,"},",Chars.LF);
		For vInd=1 To StrLineCount(vStrRows) Do
			vCurString = StrGetLine(vStrRows,vInd);
			vCurString = StrReplace(vCurString, "{", "");
			vCurString = StrReplace(vCurString, "}", "");
			vStrRows2 = StrReplace(vCurString,",",Chars.LF);
			If StrLineCount(vStrRows2) > 1 Then
				vNewRow = vEmployeeTable.Add();
			EndIf;
			For vN=1 To StrLineCount(vStrRows2) Do
				vCurString2 = StrGetLine(vStrRows2,vN);
				vPosition = Find(vCurString2, ":");
				vParameter = StrReplace(Left(vCurString2, vPosition-1), """", "");
				vValue = StrReplace(Right(vCurString2, StrLen(vCurString2)-vPosition), """", "");
				Try
					If TrimAll(vParameter) = "ID" Then
						vNewRow.ID = TrimAll(vValue);
					ElsIf TrimAll(vParameter) = "EMAIL" Then
						vNewRow.EMail = TrimAll(vValue);
					ElsIf TrimAll(vParameter) = "NAME" Then
						vNewRow.FirstName = ConvertUnicode(TrimAll(vValue));
					ElsIf TrimAll(vParameter) = "LAST_NAME" Then
						vNewRow.LastName = ConvertUnicode(TrimAll(vValue));
					ElsIf TrimAll(vParameter) = "SECOND_NAME" Then
						vNewRow.SecondName = ConvertUnicode(TrimAll(vValue));
					ElsIf TrimAll(vParameter) = "total" Then
						vEmployeesCount = Number(vValue);
					EndIf;
				Except
				EndTry;
			EndDo;
		EndDo;
	EndIf;
	Return vEmployeeTable;
EndFunction // GetB24EmployeeTableFromJSON

// --------------------------------------------------------------------------------
Function GetDataFromJSON(pJSON)
	vParametersTable = New ValueTable;
	vParametersTable.Columns.Add("Parameter");
	vParametersTable.Columns.Add("Value");
	If Left(pJSON, 1) = "{" Then
		vData = StrReplace(pJSON, "{", "");
		vData = StrReplace(vData, "}", "");
		vStrRows = StrReplace(vData,",""",Chars.LF);
		For vInd=1 To StrLineCount(vStrRows) Do
			vCurString = StrGetLine(vStrRows,vInd);
			vPosition = Find(vCurString, ":");
			vNewRow = vParametersTable.Add();
			vNewRow.Parameter = StrReplace(Left(vCurString, vPosition-1), """", "");
			vNewRow.Value = StrReplace(Right(vCurString, StrLen(vCurString)-vPosition), """", "");
		EndDo;
	EndIf;
	Return vParametersTable;
EndFunction // GetDataFromJSON

// --------------------------------------------------------------------------------
Function CreateNewTask(ExternalSystemInfoRef, pAccessToken, pMessageRef, rErrorMessage = "", pHTTPConnection)
	vID = 0;
	vDescription = TrimAll(pMessageRef.Remarks);
	If ValueIsFilled(vDescription) Then
		If StrLen(vDescription) > 60 Then
			vTitle = Left(vDescription, 60)+"...";
		Else
			vTitle = vDescription;
		EndIf;
		vResponsibleID = 0;
		vEmployee = Undefined;
		If ValueIsFilled(pMessageRef.ForEmployee) Then
			vEmployee = pMessageRef.ForEmployee;
		ElsIf ValueIsFilled(pMessageRef.ForDepartment) And ValueIsFilled(pMessageRef.ForDepartment.HeadOfDepartment) Then
			vEmployee = pMessageRef.ForDepartment.HeadOfDepartment;
		EndIf;
		If vEmployee <> UNdefined Then
			vResponsibleID = vEmployee.B24EmployeeID;
			If Not ValueIsFilled(vResponsibleID) Then
				If Not ValueIsFilled(vEmployee.B24Login) Or Not ValueIsFilled(vEmployee.B24Password) Or
					Not ValueIsFilled(vEmployee.B24RefreshToken) Then
					rErrorMessage = NStr("ru='Задача не создана! У сотрудника " + TrimAll(vEmployee.Description) + " не заполнены данные для авторизации в системе Битрикс24'; en='Task has not been created! An employee " + TrimAll(vEmployee.Description) + " is not filled with data for system authorization Bitrix24'; de='Aufgabe wurde noch nicht erstellt! Ein Mitarbeiter " + TrimAll(vEmployee.Description) + " wird nicht mit Daten für die Systemberechtigung Bitrix24 gefüllt'");
				Else
					vResponsibleID = Number(GetB24EmployeeID(ExternalSystemInfoRef, pAccessToken, vEmployee.B24Login, pHTTPConnection));
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vResponsibleID) Then
			vID = pMessageRef.B24TaskID;
			vError = "";
			If ValueIsFilled(vID) Then
				// Check the existence of the deal
				Try
					vResource = "/rest/task.item.getdata?auth="+TrimAll(pAccessToken)+"&id="+String(vID);
					vRequest  = New HTTPRequest(vResource);
					vResponse = SendHTTPRequest(ExternalSystemInfoRef, , vResource, "GET", , , , , , , pHTTPConnection, vRequest);
					vResponseText = vResponse.Body;
				Except
					vError = ErrorDescription();
					If Find(vError, "TASK_NOT_FOUND_OR_NOT_ACCESSIBLE") > 0 Then
						vMessageObject = pMessageRef.GetObject();
						vMessageObject.B24TaskID = 0;
						vMessageObject.Write();
						vID = 0;
						rErrorMessage = NStr("ru='Задача не найдена! Yет доступа на просмотр задачи либо она была удалена. " + Chars.LF + "При следующем нажатии на кнопку ""Задача в Битрикс24"" будет создана новая задача!'; en='The deal not found! You do not have access to view the task or it has been deleted. " + Chars.LF + "The next time you click on ""Bitrix24 task"" will create a new task!'; de='Der Deal wurde nicht gefunden! Sie haben keinen Zugriff, um die Aufgabe zu sehen oder sie gelöscht wurde. " + Chars.LF + "Das nächste Mal, wenn Sie auf ""Bitrix24 Aufgabe"" klicken wird ein neues Aufgabe zu schaffen!'");
					Else
						Raise vError;
					EndIf;
				EndTry;
			Else
				If ValueIsFilled(pMessageRef.CloseToDate) Then
					vDeadlineURL = "&DATA[DEADLINE]=" + Format(pMessageRef.CloseToDate, "DF=yyyy-MM-ddTHH:mm:ss");
				Else
					vDeadlineURL = "";
				EndIf;
				vResource = "/rest/task.item.add?auth="+TrimAll(pAccessToken)+"&DATA[TITLE]="+EncodeURL(TrimAll(vTitle))+"&DATA[DESCRIPTION]="+EncodeURL(StrReplace(TrimAll(vDescription), Chars.LF, "<br>"))+"&DATA[RESPONSIBLE_ID]="+Format(vResponsibleID, "NG=")+vDeadlineURL;
				vRequest  = New HTTPRequest(vResource);
				vResponse = SendHTTPRequest(ExternalSystemInfoRef, , vResource, "GET", , , , , , , pHTTPConnection, vRequest);
				vResponseText = vResponse.Body;
				
				vDataTable = GetDataFromJSON(vResponseText);
				vResultRow = vDataTable.Find("result", "Parameter");
				If vResultRow <> Undefined Then
					vID = vResultRow.Value;
					If Not ValueIsFilled(vID) Then
						vID = 0;
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(vID) Then
				If pMessageRef.B24TaskID <> Number(vID) Then
					vMessageObject = pMessageRef.GetObject();
					vMessageObject.B24TaskID = Number(vID);
					vMessageObject.Write();
				EndIf;
			EndIf;
		EndIf;
	Else
		rErrorMessage = NStr("ru='Задача не создана! Должен быть заполнен текст задачи!'; en='Task has not been created! Must be filled task text!'; de='Aufgabe wurde noch nicht erstellt! Muss Aufgabentext ausgefüllt werden!'");
	EndIf;
	Return vID;
EndFunction // CreateNewTask

// --------------------------------------------------------------------------------
Procedure PostTraktirInfo(pTask, ExternalSystemInfoRef)
	If Not ValueIsFilled(pTask) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(pTask.ForDepartment) Then
		Return;
	EndIf;
	
	vAddress = cmGetObjectExternalSystemCodeByRef(pTask.ForDepartment.Hotel,"TraktirFO","Departments",pTask.ForDepartment,True);
	If IsBlankString(vAddress) Then
		Return;
	EndIf;
	pos = StrFind(vAddress,"/front4/hs/");
	If pos = 0 Then
		Return;
	EndIf;
	vResourceLink = Mid(vAddress,pos);
	vAddress = Left(vAddress,pos-1);
	Try	
		vHTTP = New HTTPConnection(vAddress);
		vResource = vResourceLink+"&id="+pTask.Number+"&text="+TrimAll(pTask.Remarks);
		vRequest  = New HTTPRequest(vResource);
		vResponseStructure = SendHTTPRequest(ExternalSystemInfoRef, , vResource, "GET", , , , , , , vHTTP, vRequest, True);
		vResponse	= vResponseStructure.Raw; 
		If vResponse.StatusCode <> 200 Then
			WriteLogEvent("Обмен с Трактир Фронт4",EventLogLevel.Error, , ,""+vResponse.StatusCode+":"+vResponse.GetBodyAsString(TextEncoding.UTF8));
		Else
			vTaskObj = pTask.GetObject();
			// In case B24 sync is not working we have to put message only once to Traktir FO, so mark with some id to stop sync
			If vTaskObj.B24TaskID = 0 Then
				vTaskObj.B24TaskID = 1;
				vTaskObj.Write();
			EndIf;
		EndIf;
		
	Except
		WriteLogEvent("Обмен с Трактир Фронт4",EventLogLevel.Error, , ,ErrorDescription());
	EndTry;	
EndProcedure

// --------------------------------------------------------------------------------
Function GetClientsTags(pClientsArray) 
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ClientTags.Client AS Client,
	|	ClientTags.Tag AS Tag
	|FROM
	|	InformationRegister.ClientTags AS ClientTags
	|WHERE
	|	ClientTags.Client IN(&qClients)";
	
	vQuery.SetParameter("qClients", pClientsArray);
	
	vResult = vQuery.Execute().Unload();
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
Procedure FillMappedData(pExternalSystemInfoRef, rDataTable, pRefFieldName, pDataType, pDefaultValue = "", pDataName = "ID", pValueFieldName = "id", pRefFieldName2 = "")
	If rDataTable.Columns.Find(pRefFieldName) <> Undefined Then
		vCheckRefKey2 = ValueIsFilled(pRefFieldName2) And rDataTable.Columns.Find(pRefFieldName2) <> Undefined;
		
		vDataTableByRef1 = rDataTable.Copy();
		vDataTableByRef1.GroupBy(pRefFieldName);
		
		vRefFieldArr = vDataTableByRef1.UnloadColumn(pRefFieldName);
		vRefField2Arr = Undefined;
		If vCheckRefKey2 Then
			vDataTableByRef2 = rDataTable.Copy();
			vDataTableByRef2.GroupBy(pRefFieldName2);
			
			vRefField2Arr = vDataTableByRef2.UnloadColumn(pRefFieldName2);
		EndIf;
		
		vMappedData = InformationRegisters.ExternalSystemIntegrationData.GetData(pExternalSystemInfoRef, pDataType, pDataName, vRefFieldArr, vRefField2Arr);
		
		rDataTable.Columns.Add("TempColumn");
		
		For Each vRow in rDataTable Do
			vFindParams = New Structure("RefKey1", vRow[pRefFieldName]);
			If vCheckRefKey2 Then
				vFindParams.Insert("RefKey2", vRow[pRefFieldName2]);
			EndIf;
			vMappedValue = vMappedData.FindRows(vFindParams);
			If vMappedValue.Count() > 0 Then
				vRow.TempColumn = vMappedValue[vMappedValue.Count() - 1][pValueFieldName];
			Else
				vRow.TempColumn = pDefaultValue;
			EndIf;
		EndDo;
		
		rDataTable.Columns.Delete(pRefFieldName);
		rDataTable.Columns.Add(pRefFieldName);
		For Each vRow In rDataTable Do
			vRow[pRefFieldName] = vRow.TempColumn;
		EndDo;
		rDataTable.Columns.Delete("TempColumn");
	EndIf;
EndProcedure // FillMappedData

// --------------------------------------------------------------------------------
Function GetClientsByGuestGroups(ExternalSystemInfoRef, pGuestGroupsArray, pUnmappedOnly = False, pIncludeGuestGroup = False)
	
	vQuery = New Query;
	vQuery.Text =
	"SELECT DISTINCT
	|	AccommodationStatuses.Ref AS Status
	|INTO StatusList
	|FROM
	|	Catalog.AccommodationStatuses AS AccommodationStatuses
	|WHERE
	|	AccommodationStatuses.IsActive
	|
	|UNION ALL
	|
	|SELECT
	|	ReservationStatuses.Ref
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.IsCheckIn
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocList.GuestGroup AS GuestGroup,
	|	DocList.Guest AS Guest,
	|	ExternalSystemIntegrationData.ExternalSystemDataCode AS ExternalSystemDataCode
	|FROM
	|	(SELECT
	|		AccommodationList.GuestGroup AS GuestGroup,
	|		AccommodationList.Guest AS Guest
	|	FROM
	|		Document.Accommodation AS AccommodationList
	|			INNER JOIN StatusList AS StatusList
	|			ON AccommodationList.AccommodationStatus = StatusList.Status
	|	WHERE
	|		AccommodationList.Posted
	|		AND AccommodationList.GuestGroup IN(&qGuestGroups)
	|		AND AccommodationList.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		ReservationList.GuestGroup,
	|		ReservationList.Guest
	|	FROM
	|		Document.Reservation AS ReservationList
	|			INNER JOIN StatusList AS StatusList
	|			ON ReservationList.ReservationStatus = StatusList.Status
	|	WHERE
	|		ReservationList.Posted
	|		AND ReservationList.GuestGroup IN(&qGuestGroups)
	|		AND ReservationList.Guest <> VALUE(Catalog.Clients.EmptyRef)) AS DocList
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""clients"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND DocList.Guest = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	CASE
	|			WHEN &qUnmappedOnly
	|				THEN ExternalSystemIntegrationData.DataValue IS NULL
	|			ELSE TRUE
	|		END";
	
	If Not pIncludeGuestGroup Then
		vQuery.Text = StrReplace(vQuery.Text, "DocList.GuestGroup AS GuestGroup,", "");
	EndIf;
	
	vQuery.SetParameter("qGuestGroups", 		pGuestGroupsArray); 
	vQuery.SetParameter("qExternalSystemRef", 	ExternalSystemInfoRef); 
	vQuery.SetParameter("qUnmappedOnly", 		pUnmappedOnly);
	vResult = vQuery.Execute().Unload();
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
Function GetCustomersByGuestGroups(ExternalSystemInfoRef, pGuestGroupsArray, pUnmappedOnly = False)
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT DISTINCT
	|	AccommodationStatuses.Ref AS Status
	|INTO StatusList
	|FROM
	|	Catalog.AccommodationStatuses AS AccommodationStatuses
	|WHERE
	|	AccommodationStatuses.IsActive
	|
	|UNION ALL
	|
	|SELECT
	|	ReservationStatuses.Ref
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.IsCheckIn
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DocList.Customer AS Customer,
	|	ExternalSystemIntegrationData.ExternalSystemDataCode AS ExternalSystemDataCode
	|FROM
	|	(SELECT
	|		AccommodationList.Customer AS Customer
	|	FROM
	|		Document.Accommodation AS AccommodationList
	|			INNER JOIN StatusList AS StatusList
	|			ON AccommodationList.AccommodationStatus = StatusList.Status
	|	WHERE
	|		AccommodationList.Posted
	|		AND AccommodationList.GuestGroup IN(&qGuestGroups)
	|		AND AccommodationList.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReservationList.Customer
	|	FROM
	|		Document.Reservation AS ReservationList
	|			INNER JOIN StatusList AS StatusList
	|			ON ReservationList.ReservationStatus = StatusList.Status
	|	WHERE
	|		ReservationList.Posted
	|		AND ReservationList.GuestGroup IN(&qGuestGroups)
	|		AND ReservationList.Customer <> VALUE(Catalog.Customers.EmptyRef)) AS DocList
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystemRef)
	|			AND (ExternalSystemIntegrationData.DataType = ""customers"")
	|			AND (ExternalSystemIntegrationData.DataName = ""updatePeriod"")
	|			AND DocList.Customer = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	CASE
	|			WHEN &qUnmappedOnly
	|				THEN ExternalSystemIntegrationData.DataValue IS NULL
	|			ELSE TRUE
	|		END";
	
	vQuery.SetParameter("qGuestGroups", 		pGuestGroupsArray); 
	vQuery.SetParameter("qExternalSystemRef", 	ExternalSystemInfoRef);
	vQuery.SetParameter("qUnmappedOnly", 		pUnmappedOnly);
	vResult = vQuery.Execute().Unload();
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
Function GetSalesTotalsByGuestGroups(pGuestGroups)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentAccountsReceivableTurnovers.GuestGroup AS GuestGroup,
	|	CurrentAccountsReceivableTurnovers.Charge.Service AS Service,
	|	CurrentAccountsReceivableTurnovers.FolioCurrency AS FolioCurrency,
	|	SUM(CurrentAccountsReceivableTurnovers.SumReceipt - CurrentAccountsReceivableTurnovers.CommissionSumReceipt) AS SalesTurnover,
	|	SUM(CASE
	|			WHEN CurrentAccountsReceivableTurnovers.SumReceipt = 0
	|				THEN CurrentAccountsReceivableTurnovers.SumReceipt - CurrentAccountsReceivableTurnovers.VATSumReceipt - CurrentAccountsReceivableTurnovers.CommissionSumReceipt
	|			ELSE CurrentAccountsReceivableTurnovers.SumReceipt - CurrentAccountsReceivableTurnovers.VATSumReceipt - (CurrentAccountsReceivableTurnovers.CommissionSumReceipt - CurrentAccountsReceivableTurnovers.CommissionSumReceipt * CurrentAccountsReceivableTurnovers.VATSumReceipt / CurrentAccountsReceivableTurnovers.SumReceipt)
	|		END) AS SalesWithoutVATTurnover,
	|	SUM(CurrentAccountsReceivableTurnovers.SumReceipt) AS SalesWithCommissionTurnover,
	|	SUM(CASE
	|			WHEN CurrentAccountsReceivableTurnovers.SumReceipt = 0
	|				THEN CurrentAccountsReceivableTurnovers.SumReceipt - CurrentAccountsReceivableTurnovers.VATSumReceipt
	|			ELSE CurrentAccountsReceivableTurnovers.SumReceipt - CurrentAccountsReceivableTurnovers.VATSumReceipt
	|		END) AS SalesWithCommissionWithoutVATTurnover
	|INTO ChargedAmounts
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Turnovers(, , PERIOD, GuestGroup IN (&qGuestGroups)) AS CurrentAccountsReceivableTurnovers
	|
	|GROUP BY
	|	CurrentAccountsReceivableTurnovers.GuestGroup,
	|	CurrentAccountsReceivableTurnovers.Charge.Service,
	|	CurrentAccountsReceivableTurnovers.FolioCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsReceivableForecastTurnovers.GuestGroup AS GuestGroup,
	|	AccountsReceivableForecastTurnovers.Service AS Service,
	|	AccountsReceivableForecastTurnovers.FolioCurrency AS FolioCurrency,
	|	ISNULL(AccountsReceivableForecastTurnovers.ParentDoc.ReservationStatus.IsActive, FALSE) AS IsActiveReservation,
	|	ISNULL(AccountsReceivableForecastTurnovers.ParentDoc.ReservationStatus.IsPreliminary, FALSE) AS IsPreliminaryReservation,
	|	ISNULL(AccountsReceivableForecastTurnovers.ParentDoc.AccommodationStatus.IsActive, FALSE) AS IsActiveAccommodation,
	|	ISNULL(AccountsReceivableForecastTurnovers.ParentDoc.ResourceReservationStatus.IsActive, FALSE) AS IsActiveResourceReservation,
	|	AccountsReceivableForecastTurnovers.SalesTurnover - AccountsReceivableForecastTurnovers.CommissionSumTurnover AS SalesTurnover,
	|	AccountsReceivableForecastTurnovers.SalesWithoutVATTurnover - AccountsReceivableForecastTurnovers.CommissionSumWithoutVATTurnover AS SalesWithoutVATTurnover,
	|	AccountsReceivableForecastTurnovers.ExpectedSalesTurnover - AccountsReceivableForecastTurnovers.ExpectedCommissionSumTurnover AS ExpectedSalesTurnover,
	|	AccountsReceivableForecastTurnovers.ExpectedSalesWithoutVATTurnover - AccountsReceivableForecastTurnovers.ExpectedCommissionSumWithoutVATTurnover AS ExpectedSalesWithoutVATTurnover,
	|	AccountsReceivableForecastTurnovers.SalesTurnover AS SalesWithCommissionTurnover,
	|	AccountsReceivableForecastTurnovers.SalesWithoutVATTurnover AS SalesWithCommissionWithoutVATTurnover,
	|	AccountsReceivableForecastTurnovers.ExpectedSalesTurnover AS ExpectedSalesWithCommissionTurnover,
	|	AccountsReceivableForecastTurnovers.ExpectedSalesWithoutVATTurnover AS ExpectedSalesWithCommissionWithoutVATTurnover
	|INTO ForecastAmounts
	|FROM
	|	AccumulationRegister.AccountsReceivableForecast.Turnovers(&qForecastPeriodFrom, &qForecastPeriodTo, PERIOD, GuestGroup IN (&qGuestGroups)) AS AccountsReceivableForecastTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroupSales.GuestGroup AS GuestGroup,
	|	GuestGroupSales.Service AS Service,
	|	GuestGroupSales.ReportingCurrency AS Currency,
	|	GuestGroupSales.Service.SortCode AS ServiceSortCode,
	|	GuestGroupSales.ReportingCurrency.SortCode AS CurrencySortCode,
	|	SUM(GuestGroupSales.SalesTurnover) AS Sales,
	|	SUM(GuestGroupSales.SalesWithoutVATTurnover) AS SalesWithoutVAT,
	|	SUM(GuestGroupSales.SalesForecastTurnover) AS SalesForecast,
	|	SUM(GuestGroupSales.SalesWithoutVATForecastTurnover) AS SalesWithoutVATForecast,
	|	SUM(GuestGroupSales.ExpectedSalesTurnover) AS ExpectedSales,
	|	SUM(GuestGroupSales.ExpectedSalesWithoutVATTurnover) AS ExpectedSalesWithoutVAT,
	|	SUM(GuestGroupSales.SalesWithCommissionTurnover) AS SalesWithCommission,
	|	SUM(GuestGroupSales.SalesWithCommissionWithoutVATTurnover) AS SalesWithCommissionWithoutVAT,
	|	SUM(GuestGroupSales.SalesWithCommissionForecastTurnover) AS SalesWithCommissionForecast,
	|	SUM(GuestGroupSales.SalesWithCommissionWithoutVATForecastTurnover) AS SalesWithCommissionWithoutVATForecast,
	|	SUM(GuestGroupSales.ExpectedSalesWithCommissionTurnover) AS ExpectedSalesWithCommission,
	|	SUM(GuestGroupSales.ExpectedSalesWithCommissionWithoutVATTurnover) AS ExpectedSalesWithCommissionWithoutVAT
	|FROM
	|	(SELECT
	|		ChargedAmounts.GuestGroup AS GuestGroup,
	|		ChargedAmounts.Service AS Service,
	|		ChargedAmounts.FolioCurrency AS ReportingCurrency,
	|		ISNULL(ChargedAmounts.SalesTurnover, 0) AS SalesTurnover,
	|		ISNULL(ChargedAmounts.SalesWithoutVATTurnover, 0) AS SalesWithoutVATTurnover,
	|		0 AS SalesForecastTurnover,
	|		0 AS SalesWithoutVATForecastTurnover,
	|		0 AS ExpectedSalesTurnover,
	|		0 AS ExpectedSalesWithoutVATTurnover,
	|		ISNULL(ChargedAmounts.SalesWithCommissionTurnover, 0) AS SalesWithCommissionTurnover,
	|		ISNULL(ChargedAmounts.SalesWithCommissionWithoutVATTurnover, 0) AS SalesWithCommissionWithoutVATTurnover,
	|		0 AS SalesWithCommissionForecastTurnover,
	|		0 AS SalesWithCommissionWithoutVATForecastTurnover,
	|		0 AS ExpectedSalesWithCommissionTurnover,
	|		0 AS ExpectedSalesWithCommissionWithoutVATTurnover
	|	FROM
	|		ChargedAmounts AS ChargedAmounts
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ForecastAmounts.GuestGroup,
	|		ForecastAmounts.Service,
	|		ForecastAmounts.FolioCurrency,
	|		0,
	|		0,
	|		ISNULL(ForecastAmounts.SalesTurnover, 0),
	|		ISNULL(ForecastAmounts.SalesWithoutVATTurnover, 0),
	|		ISNULL(ForecastAmounts.ExpectedSalesTurnover, 0),
	|		ISNULL(ForecastAmounts.ExpectedSalesWithoutVATTurnover, 0),
	|		0,
	|		0,
	|		ISNULL(ForecastAmounts.SalesWithCommissionTurnover, 0),
	|		ISNULL(ForecastAmounts.SalesWithCommissionWithoutVATTurnover, 0),
	|		ISNULL(ForecastAmounts.ExpectedSalesWithCommissionTurnover, 0),
	|		ISNULL(ForecastAmounts.ExpectedSalesWithCommissionWithoutVATTurnover, 0)
	|	FROM
	|		ForecastAmounts AS ForecastAmounts
	|	WHERE
	|		(ForecastAmounts.IsActiveReservation = TRUE
	|				OR ForecastAmounts.IsPreliminaryReservation = TRUE
	|				OR ForecastAmounts.IsActiveAccommodation = TRUE
	|				OR ForecastAmounts.IsActiveResourceReservation = TRUE)) AS GuestGroupSales
	|
	|GROUP BY
	|	GuestGroupSales.GuestGroup,
	|	GuestGroupSales.Service,
	|	GuestGroupSales.ReportingCurrency,
	|	GuestGroupSales.Service.SortCode,
	|	GuestGroupSales.ReportingCurrency.SortCode
	|
	|ORDER BY
	|	ServiceSortCode,
	|	CurrencySortCode";
	vQry.SetParameter("qGuestGroups", pGuestGroups);
	vQry.SetParameter("qForecastPeriodFrom", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qForecastPeriodTo", '39991231235959');
	Return vQry.Execute().Unload();
EndFunction // GetSalesTotalsByGuestGroups

// --------------------------------------------------------------------------------
Function SendHTTPRequest(pExternalSystemInteractions, pRequestHeaders = Undefined, pRequestURL = Undefined, pMethod, pMethodAction = Undefined, pRequestBody = Undefined, 
	pContentType = Undefined, pUseServerLogin = False, pRequestParameters = Undefined, pMaxLogLength = 250000, pHTTPConnection = Undefined, pHTTPRequest = Undefined, 
	pGetRaw = False, pHTTPServer = Undefined, pAddHostHeader = true, pFunctionName = "") Export
	
	vResult = New Structure("StatusCode, Body, Error, Raw");
	
	Try
		// Get callback connection parameters
		If pHTTPServer = Undefined Then
			vHTTPServer = TrimAll(pExternalSystemInteractions.HTTPServer);
			If NOT ValueIsFilled(vHTTPServer) Then
				vHTTPServer = TrimAll(pExternalSystemInteractions.WSHost);	
			EndIf;
			vPort = pExternalSystemInteractions.HttpPort;
			If vPort <> 80 And vPort <> 0 Then
				vHTTPServer = vHTTPServer + ":" + Format(vPort, "NFD=0; NG=");
			EndIf;
		Else
			vHTTPServer	= pHTTPServer;
		EndIf;
		vUseSSL 	= pExternalSystemInteractions.HTTPUseSSL;
		
		If pUseServerLogin = True Then
			vHTTPUser 	= TrimAll(pExternalSystemInteractions.Login);
			vHTTPPwd 	= TrimAll(pExternalSystemInteractions.Password);
		Else
			vHTTPUser 	= Undefined;
			vHTTPPwd 	= Undefined;	
		EndIf;
		
		If NOT ValueIsFilled(pRequestURL) Then
			vRequestURL = TrimAll(pExternalSystemInteractions.HttpAddress);
		Else
			vRequestURL = pRequestURL;
		EndIf;
		
		// HTTP header
		vHTTPHeader = New Map;
		If pAddHostHeader Then
			vHTTPHeader.Insert("Host", vHTTPServer);
		EndIf;
		
		If pMethod = "POST" Then
			If pMethodAction <> Undefined Then
				vHTTPHeader.Insert("POST", pMethodAction);
			EndIf;
		EndIf;
		
		If pRequestBody <> Undefined Then
			If StrFind(Upper(pContentType), "application/json") > 0 Or pContentType = "JSON" Then
				vHTTPHeader.Insert("Content-Type", "application/json;charset=utf-8");
			ElsIf StrFind(Upper(pContentType), "application/xml") > 0 Or pContentType = "XML" Then
				vHTTPHeader.Insert("Content-Type", "application/xml;charset=utf-8");
			Else
				vHTTPHeader.Insert("Content-Type", pContentType);	
			EndIf;
		EndIf;
		
		If pRequestHeaders <> Undefined Then
			For each vHeader in pRequestHeaders Do
				vHTTPHeader.Insert(vHeader.Key, vHeader.Value);	
			EndDo;
		EndIf;
		
		// HTTP connection
		vSSL = Undefined;
		If vUseSSL Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);       	
		EndIf;
		
		If pHTTPConnection = Undefined Then
			vHTTPConnection = New HTTPConnection(vHTTPServer, , vHTTPUser, vHTTPPwd, , , vSSL);
		Else
			vHTTPConnection = pHTTPConnection;	
		EndIf;
		
		If pRequestParameters <> Undefined Then
			vFirst = True;
			For each vKeyAndValue in pRequestParameters Do
				If vFirst Then
					vRequestURL = vRequestURL + "?" + vKeyAndValue.Key + "=" + vKeyAndValue.Value; 
				Else
					vRequestURL = vRequestURL + "&" + vKeyAndValue.Key + "=" + vKeyAndValue.Value;
				EndIf;			
				vFirst 		= False;
			EndDo;
		EndIf;
		
		vRequestBody = "";
		// Send data
		If pHTTPRequest = Undefined Then
			vHTTPRequest = New HTTPRequest(vRequestURL, vHTTPHeader);
		Else
			vHTTPRequest 	= pHTTPRequest;
			vRequestBody	= vHTTPRequest.GetBodyAsString();
		EndIf;
		
		If pRequestBody <> Undefined Then 
			vHTTPRequest.SetBodyFromString(pRequestBody);
			vRequestBody = pRequestBody;
		EndIf;
		
		If pMethod = "POST" Then
			vRs = vHTTPConnection.Post(vHTTPRequest);
		ElsIf pMethod = "PATCH" Then
			vRs = vHTTPConnection.CallHTTPMethod("PATCH",vHTTPRequest);
		ElsIf pMethod = "GET" Then
			vRs = vHTTPConnection.Get(vHTTPRequest);
		ElsIf pMethod = "DELETE" Then
			vRs = vHTTPConnection.Delete(vHTTPRequest);
		ElsIf pMethod = "PUT" Then
			vRs = vHTTPConnection.Put(vHTTPRequest);
		EndIf;
		
		vResult.StatusCode	= vRs.StatusCode;
		vResult.Body 		= vRs.GetBodyAsString();
		
		If vResult.StatusCode <> 200 Then
			Try
				vBodyStr = Catalogs.DataConvertationRules.JSONtoStructure(vResult.Body);
				If Not vBodyStr.Property("error_description", vResult.Error) Then
					vResult.Error = vResult.Body;		
				EndIf;
			Except
				vResult.Error = vResult.Body;
			EndTry;	
		EndIf;
		
		If pGetRaw Then
			vResult.Raw = vRs;
		EndIf;
	Except
		vError = String(pExternalSystemInteractions) + NStr("en = 'Failed to send request!'; de = 'Anfrage konnte nicht gesendet werden!'; ru = 'Неудалось отправить запрос!'") + ErrorDescription();
		WriteLogEvent("SendHTTPRequest", EventLogLevel.Warning, ,CurrentSessionDate(), "" + vError);
		vResult.Error = vError;
		Return vResult;
	EndTry;
	
	If pExternalSystemInteractions.DebugMode Or Not IsBlankString(vResult.Error) Then
		
		vLogStructure = New Structure;
		vLogStructure.Insert("Action", 						"SendHTTPRequest");
		vLogStructure.Insert("ExternalSystemInteractions", 	String(pExternalSystemInteractions));
		vLogStructure.Insert("RequestURL", 					vRequestURL);
		vLogStructure.Insert("FunctionName", 				pFunctionName);
		If StrLen(vRequestURL) > 100 Then
			vMap = New Map;
			vMap.Insert("RequestURL", 	vRequestURL);
			vMap.Insert("RequestBody", 	vRequestBody);
			vRequestBody = Catalogs.DataConvertationRules.MapToJSON(vMap);
		EndIf;
		vLogStructure.Insert("RequestBody", 				vRequestBody);
		vLogStructure.Insert("ResponseStatus", 				vResult.StatusCode);
		vLogStructure.Insert("ResponseBody", 				vResult.Body);
		vLogStructure.Insert("Error", 						vResult.Error);
		
		Catalogs.ExternalSystemInteractions.WriteLog(pExternalSystemInteractions, vLogStructure, pMaxLogLength);
		
	EndIf;
	
	Return vResult;	
	
EndFunction // SendHTTPRequest

#EndRegion
