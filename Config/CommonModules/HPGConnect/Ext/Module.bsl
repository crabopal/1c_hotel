// --------------------------------------------------------------------------------
&AtServer
Function GetInteractionParameters(pToken, pInteractionID, pHotelCode) Export
	vResult = Undefined;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	NOT ExternalSystemInteractions.DeletionMark
		|	AND ExternalSystemInteractions.IsActive
		|	AND ExternalSystemInteractions.OAuth_AccessToken = &qOAuth_AccessToken
		|	AND ExternalSystemInteractions.InteractionID = &qInteractionID
		|	AND ExternalSystemInteractions.Hotel.Code = &qHotelCode";
	vQuery.SetParameter("qHotelCode", pHotelCode);
	vQuery.SetParameter("qInteractionID", pInteractionID);
	vQuery.SetParameter("qOAuth_AccessToken", pToken);
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		vResult = vSelectionDetailRecords.Ref; 
		Break;
	EndDo;
	
	Return vResult;
EndFunction // GetInteractionParameters

// --------------------------------------------------------------------------------
&AtServer
Function HPGDataRequest(pExternalSystemCode, pExternalSystemInteractions, pRequestID, pDebugMode = False, pPeriodFrom = Undefined) Export
	vResult = New Structure("JSONString, ErrorDescription", "", "");
	
	vHotel = pExternalSystemInteractions.Hotel;
	vHotelCode = TrimAll(vHotel.Code);
	
	vSourcesOfBusinessArray = GetSourcesOfBusinessArray(pExternalSystemCode, vHotel);
	
	vStartDate = CurrentSessionDate();
	vPeriodFrom = pExternalSystemInteractions.LastFullSynchronizationTime;	
	If NOT ValueIsFilled(vPeriodFrom) Then
		vPeriodFrom = CurrentDate() - 24*60*60*7;
	EndIf;
	If ValueIsFilled(pPeriodFrom) Then
		vPeriodFrom = pPeriodFrom;
	EndIf;
	
	// Data in changed documents
	vDocuments = GetChangedReservations(vPeriodFrom, vSourcesOfBusinessArray, vHotel);
	
	// Blocked cards
	vBlockedCards = GetBlockedDiscountCards(vPeriodFrom, vHotel);
	
	// Transactions of checked-out guests
	vTransactions = GetTransactions(vPeriodFrom, vSourcesOfBusinessArray, vHotel);
	
	// Extra managers list
	vExtraMgrList = New ValueList();
	vBlockedCardsList = New ValueList();
	For Each vBlockedCardsRow In vBlockedCards Do
		If vExtraMgrList.FindByValue(vBlockedCardsRow.Manager) = Undefined Then
			vExtraMgrList.Add(vBlockedCardsRow.Manager);
		EndIf;
		If vBlockedCardsList.FindByValue(vBlockedCardsRow.DiscountCard) = Undefined Then
			vBlockedCardsList.Add(vBlockedCardsRow.DiscountCard);
		EndIf;
	EndDo;
	For Each vTransactionsRow In vTransactions Do
		If vExtraMgrList.FindByValue(vTransactionsRow.Manager) = Undefined Then
			vExtraMgrList.Add(vTransactionsRow.Manager);
		EndIf;
	EndDo;
	
	vResultErrorDescription = "";
	vJSONResultString = "";
	
	// Get managers data
	vCatalogItemsResult = GetHPGJSONCatalogData("Manager", "Managers", vDocuments, vHotelCode, pRequestID, pDebugMode, vExtraMgrList);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vCatalogItemsResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vCatalogItemsResult.JSONString;
	Else
		SendQuery(vCatalogItemsResult.JSONString, pExternalSystemInteractions, "ManagersResponse");
	EndIf;
	
	// Get client types data
	vCatalogItemsResult = GetHPGJSONCatalogData("ClientType", "ClientTypes", vDocuments, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vCatalogItemsResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vCatalogItemsResult.JSONString;
	Else
		SendQuery(vCatalogItemsResult.JSONString, pExternalSystemInteractions, "ClientTypesResponse");
	EndIf;
	
	// Get room types data
	vCatalogItemsResult = GetHPGJSONCatalogData("RoomType", "RoomTypes", vDocuments, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vCatalogItemsResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vCatalogItemsResult.JSONString;
	Else
		SendQuery(vCatalogItemsResult.JSONString, pExternalSystemInteractions, "RoomTypesResponse");
	EndIf;
	
	// Get sources data
	vCatalogItemsResult = GetHPGJSONCatalogData("SourceOfBusiness", "Sources", vDocuments, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vCatalogItemsResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vCatalogItemsResult.JSONString;
	Else
		SendQuery(vCatalogItemsResult.JSONString, pExternalSystemInteractions, "SourcesResponse");
	EndIf;
	
	// Get marketing codes data
	vCatalogItemsResult = GetHPGJSONCatalogData("MarketingCode", "MarketingCodes", vDocuments, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vCatalogItemsResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vCatalogItemsResult.JSONString;
	Else
		SendQuery(vCatalogItemsResult.JSONString, pExternalSystemInteractions, "MarketingCodesResponse");
	EndIf;
	
	// Get room rates data
	vCatalogItemsResult = GetHPGJSONCatalogData("RoomRate", "RoomRates", vDocuments, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vCatalogItemsResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vCatalogItemsResult.JSONString;
	Else
		SendQuery(vCatalogItemsResult.JSONString, pExternalSystemInteractions, "RoomRatesResponse");
	EndIf;
	
	// Get service packages data
	vCatalogItemsResult = GetHPGJSONCatalogData("ServicePackage", "Packages", vDocuments, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vCatalogItemsResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vCatalogItemsResult.JSONString;
	Else
		SendQuery(vCatalogItemsResult.JSONString, pExternalSystemInteractions, "PackagesResponse");
	EndIf;
	
	// Get customers data
	vCustomersResult = GetHPGJSONCustomersData(vDocuments, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vCustomersResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vCustomersResult.JSONString;
	Else
		SendQuery(vCustomersResult.JSONString, pExternalSystemInteractions, "CustomersResponse");
	EndIf;
	
	// Get guests data
	vChangedClientsCardsList = New ValueList();
	vGuestsResult = GetHPGJSONGuestsData(vDocuments, vHotelCode, pRequestID, pDebugMode, vPeriodFrom, vChangedClientsCardsList);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vGuestsResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vGuestsResult.JSONString;
	Else
		SendQuery(vGuestsResult.JSONString, pExternalSystemInteractions, "GuestsResponse");
	EndIf;
	
	// Get discount cards
	vDCResult = GetHPGJSONDiscountCardsData(vDocuments, vChangedClientsCardsList, vBlockedCardsList, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vDCResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vDCResult.JSONString;
	Else
		SendQuery(vDCResult.JSONString, pExternalSystemInteractions, "DiscountCardsResponse");
	EndIf;
	
	// Get items data
	vItemsResult = GetHPGJSONItemsData(vTransactions, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vItemsResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vItemsResult.JSONString;
	Else
		SendQuery(vItemsResult.JSONString, pExternalSystemInteractions, "ItemsResponse");
	EndIf;
	
	// Get reservations data
	vResResult = GetHPGJSONReservationsData(vDocuments, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vResResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vResResult.JSONString;
	Else
		SendQuery(vResResult.JSONString, pExternalSystemInteractions, "ReservationsResponse");
	EndIf;
	
	// Get transactions data
	vTranResult = GetHPGJSONTransactionsData(vTransactions, vHotelCode, pRequestID, pDebugMode);
	If pDebugMode Then
		vResultErrorDescription = vResultErrorDescription + ?(IsBlankString(vResultErrorDescription), "", ", ") + vTranResult.ErrorDescription;
		vJSONResultString = vJSONResultString + ?(IsBlankString(vJSONResultString), "", ", ") + vTranResult.JSONString;
	Else
		SendQuery(vTranResult.JSONString, pExternalSystemInteractions, "TransactionsResponse");
	EndIf;
	
	// Save integration state
	vExtSysIntObj = pExternalSystemInteractions.GetObject();
	If IsBlankString(vResultErrorDescription) Then
		vExtSysIntObj.LastFullSynchronizationTime = vStartDate;
		vExtSysIntObj.Status = Enums.IntegrationStatuses.Success;
	Else
		vExtSysIntObj.Status = Enums.IntegrationStatuses.Error;
		vExtSysIntObj.ErrorDescription = vResultErrorDescription;
	EndIf;
	vExtSysIntObj.Write();
	
	// Fill result structure
	vResult.ErrorDescription = vResultErrorDescription;
	vResult.JSONString = vJSONResultString;
	
	Return vResult;
EndFunction // HPGDataRequest

// --------------------------------------------------------------------------------
&AtServer
Function GetHPGJSONCatalogData(pDataType, pDataTypes, pDocuments, pHotelCode, pRequestID, pDebugMode, pExtraList = Undefined)
	vResult = New Structure("JSONString, ErrorDescription", "", "");
	
	vMessageName = lower(pDataTypes) + "Response";
	
	vList = New ValueList();
	vItems = pDocuments.Copy(, pDataType);
	vItems.GroupBy(pDataType, );
	vList.LoadValues(vItems.UnloadColumn(pDataType));
	If pExtraList <> Undefined Then
		For Each vExtraListItem In pExtraList Do
			If vList.FindByValue(vExtraListItem.Value) = Undefined Then
				vList.Add(vExtraListItem.Value);
			EndIf;
		EndDo;
	EndIf;
	vCatalogName = pDataTypes;
	If vCatalogName = "Sources" Then
		vCatalogName = "SourcesOfBusiness";
	ElsIf vCatalogName = "Packages" Then
		vCatalogName = "ServicePackages";
	ElsIf vCatalogName = "Managers" Then
		vCatalogName = "Employees";
	EndIf;
	vData = GetCatalogItems(vCatalogName, vList);
	If vCatalogName = "Employees" Then
		vData.Columns.Add("isBlocked");
		For Each vDataRow In vData Do
			If vDataRow.Ref.DeletionMark Or Not vDataRow.Ref.AllowAccessToSystem Then
				vDataRow.isBlocked = "true";
			Else
				vDataRow.isBlocked = "false";
			EndIf;
		EndDo;
	EndIf;
		
	vParams = New Structure;
	vParams.Insert("messageName", vMessageName);
	vParams.Insert("hotelCode", pHotelCode);
	vParams.Insert("requestID", pRequestID);
	vParams.Insert(lower(pDataTypes), vData);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for HPG - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString = Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	If pDebugMode Then
		vPos = StrFind(vJSONString, """" + lower(Left(pDataTypes, 1)) + Mid(pDataTypes, 2) + """");
		If vPos > 0 Then
			vJSONString = Mid(vJSONString, vPos);
			vJSONString = Left(vJSONString, StrLen(vJSONString) - 1);
		EndIf;
	EndIf;
	vResult.JSONString = vJSONString;
	
	Return vResult;
EndFunction // GetHPGJSONCatalogData

// --------------------------------------------------------------------------------
&AtServer
Function GetHPGJSONGuestsData(pDocuments, pHotelCode, pRequestID, pDebugMode, pPeriodFrom, rCardsList)
	vResult = New Structure("JSONString, ErrorDescription", "", "");
	
	vMessageName = "GuestsResponse";
	
	vList = New ValueList();
	vItems = pDocuments.Copy(, "Guest");
	vItems.GroupBy("Guest", );
	vList.LoadValues(vItems.UnloadColumn("Guest"));
	
	vGuests = GetGuests(vList, pPeriodFrom);
	
	rCardsList = New ValueList();
	
	vData = New ValueTable();
	vData.Columns.Add("code");
	vData.Columns.Add("fullName");
	vData.Columns.Add("email");
	vData.Columns.Add("phone");
	vData.Columns.Add("birthdate");
	vData.Columns.Add("sex");
	vData.Columns.Add("clientTypeCode");
	vData.Columns.Add("cardID");
	vData.Columns.Add("createdBy");
	vData.Columns.Add("created");
	vData.Columns.Add("changedBy");
	vData.Columns.Add("changed");
	For Each vGuestsRow In vGuests Do
		vDataRow = vData.Add();
		vDataRow.code = vGuestsRow.code;
		vDataRow.fullName = vGuestsRow.fullName;
		vDataRow.email = vGuestsRow.email;
		vDataRow.phone = vGuestsRow.phone;
		vDataRow.birthdate = ?(ValueIsFilled(vGuestsRow.birthdate), Format(vGuestsRow.birthdate, "DF=yyyy-MM-dd"), "");
		vDataRow.sex = TrimAll(vGuestsRow.sex);
		vDataRow.clientTypeCode = TrimAll(vGuestsRow.clientTypeCode);
		If ValueIsFilled(vGuestsRow.card) Then
			If rCardsList.FindByValue(vGuestsRow.card) = Undefined Then
				rCardsList.Add(vGuestsRow.card);
			EndIf;
		EndIf;
		vDataRow.cardID = TrimAll(vGuestsRow.cardID);
		vDataRow.createdBy = TrimAll(vGuestsRow.createdBy);
		vDataRow.created = Format(vGuestsRow.created, "DF=yyyy-MM-ddTHH:mm:ss");
		vDataRow.changedBy = ?(vGuestsRow.changedBy = Null, "", vGuestsRow.changedBy);
		vDataRow.changed = ?(vGuestsRow.changed = Null, "", Format(vGuestsRow.changed, "DF=yyyy-MM-ddTHH:mm:ss"));
	EndDo;
		
	vParams = New Structure;
	vParams.Insert("messageName", vMessageName);
	vParams.Insert("hotelCode", pHotelCode);
	vParams.Insert("requestID", pRequestID);
	vParams.Insert("guests", vData);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for HPG - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString = Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	If pDebugMode Then
		vPos = StrFind(vJSONString, """guests""");
		If vPos > 0 Then
			vJSONString = Mid(vJSONString, vPos);
			vJSONString = Left(vJSONString, StrLen(vJSONString) - 1);
		EndIf;
	EndIf;
	vResult.JSONString = vJSONString;
	
	Return vResult;
EndFunction // GetHPGJSONGuestsData

// --------------------------------------------------------------------------------
&AtServer
Function GetHPGJSONCustomersData(pDocuments, pHotelCode, pRequestID, pDebugMode)
	vResult = New Structure("JSONString, ErrorDescription", "", "");
	
	vMessageName = "CustomersResponse";
	
	vList = New ValueList();
	vItems = pDocuments.Copy(, "Customer");
	vItems.GroupBy("Customer", );
	vList.LoadValues(vItems.UnloadColumn("Customer"));
	
	vListAgents = New ValueList();
	vItems = pDocuments.Copy(, "Agent");
	vItems.GroupBy("Agent", );
	vListAgents.LoadValues(vItems.UnloadColumn("Agent"));
	
	For Each vListAgentsItem In vListAgents Do
		If vList.FindByValue(vListAgentsItem.Value) = Undefined Then
			vList.Add(vListAgentsItem.Value);
		EndIf;
	EndDo;
	
	// Agent 2
	vAgents2List = New ValueList();
	For Each vDocumentsRow In pDocuments Do
		vAgent2 = Undefined;
		vDocCustFileds = cmGetReservationCustomFieldsValues(vDocumentsRow.Reservation);
		If vDocCustFileds.Count() > 0 Then
			vAgent2Row = vDocCustFileds.Find("Agent2                                            ", "CharacteristicCode");
			If vAgent2Row <> Undefined Then
				If ValueIsFilled(vAgent2Row.CharacteristicValue) Then
					vAgent2 = vAgent2Row.CharacteristicValue;
					If vAgents2List.FindByValue(vAgent2) = Undefined Then
						vAgents2List.Add(vAgent2);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	For Each vAgents2ListItem In vAgents2List Do
		If vList.FindByValue(vAgents2ListItem.Value) = Undefined Then
			vList.Add(vAgents2ListItem.Value);
		EndIf;
	EndDo;
	
	vCustomers = GetCustomers(vList);
	
	vData = New ValueTable();
	vData.Columns.Add("code");
	vData.Columns.Add("description");
	vData.Columns.Add("TIN");
	vData.Columns.Add("KPP");
	vData.Columns.Add("email");
	vData.Columns.Add("phone");
	For Each vCustomersRow In vCustomers Do
		vDataRow = vData.Add();
		vDataRow.code = vCustomersRow.code;
		vDataRow.description = vCustomersRow.description;
		vDataRow.TIN = vCustomersRow.TIN;
		vDataRow.KPP = vCustomersRow.KPP;
		vDataRow.email = vCustomersRow.email;
		vDataRow.phone = vCustomersRow.phone;
	EndDo;
		
	vParams = New Structure;
	vParams.Insert("messageName", vMessageName);
	vParams.Insert("hotelCode", pHotelCode);
	vParams.Insert("requestID", pRequestID);
	vParams.Insert("customers", vData);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for HPG - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString = Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	If pDebugMode Then
		vPos = StrFind(vJSONString, """customers""");
		If vPos > 0 Then
			vJSONString = Mid(vJSONString, vPos);
			vJSONString = Left(vJSONString, StrLen(vJSONString) - 1);
		EndIf;
	EndIf;
	vResult.JSONString = vJSONString;
	
	Return vResult;
EndFunction // GetHPGJSONCustomersData

// --------------------------------------------------------------------------------
&AtServer
Function GetHPGJSONDiscountCardsData(pDocuments, pChangedClientsCardsList, pBlockedCardsList, pHotelCode, pRequestID, pDebugMode)
	vResult = New Structure("JSONString, ErrorDescription", "", "");
	
	vMessageName = "DiscountCardsResponse";
	
	vCardsList = New ValueList();
	vItems = pDocuments.Copy(, "DiscountCard");
	vItems.GroupBy("DiscountCard", );
	vCardsList.LoadValues(vItems.UnloadColumn("DiscountCard"));
	For Each vBlockedCardsListItem In pBlockedCardsList Do
		If vCardsList.FindByValue(vBlockedCardsListItem.Value) = Undefined Then
			vCardsList.Add(vBlockedCardsListItem.Value);
		EndIf;
	EndDo;
	For Each vChangedClientsCardsListItem In pChangedClientsCardsList Do
		If vCardsList.FindByValue(vChangedClientsCardsListItem.Value) = Undefined Then
			vCardsList.Add(vChangedClientsCardsListItem.Value);
		EndIf;
	EndDo;
	
	vCards = GetDiscountCards(vCardsList);
	
	vData = New ValueTable();
	vData.Columns.Add("cardID");
	vData.Columns.Add("clientTypeCode");
	vData.Columns.Add("guestCode");
	vData.Columns.Add("isBlocked");
	vData.Columns.Add("createdHotel");
	vData.Columns.Add("createdBy");
	vData.Columns.Add("created");
	vData.Columns.Add("changedBy");
	vData.Columns.Add("changed");
	For Each vCardsRow In vCards Do
		vDataRow = vData.Add();
		vDataRow.cardID = vCardsRow.cardID;
		vDataRow.clientTypeCode = TrimAll(vCardsRow.clientTypeCode);
		vDataRow.guestCode = TrimAll(vCardsRow.guestCode);
		vDataRow.isBlocked = ?(vCardsRow.isBlocked, "true", "false");
		vDataRow.createdHotel = TrimAll(vCardsRow.createdHotelCode);
		vDataRow.createdBy = TrimAll(vCardsRow.CreatedByCode);
		vDataRow.created = ?(ValueIsFilled(vCardsRow.created), Format(vCardsRow.created, "DF=yyyy-MM-ddTHH:mm:ss"), "");
		vDataRow.changedBy = TrimAll(vCardsRow.changedByCode);
		vDataRow.changed = ?(ValueIsFilled(vCardsRow.changed), Format(vCardsRow.changed, "DF=yyyy-MM-ddTHH:mm:ss"), "");
	EndDo;
		
	vParams = New Structure;
	vParams.Insert("messageName", vMessageName);
	vParams.Insert("hotelCode", pHotelCode);
	vParams.Insert("requestID", pRequestID);
	vParams.Insert("discountCards", vData);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for HPG - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString = Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	If pDebugMode Then
		vPos = StrFind(vJSONString, """discountCards""");
		If vPos > 0 Then
			vJSONString = Mid(vJSONString, vPos);
			vJSONString = Left(vJSONString, StrLen(vJSONString) - 1);
		EndIf;
	EndIf;
	vResult.JSONString = vJSONString;
	
	Return vResult;
EndFunction // GetHPGJSONDiscountCardsData

// --------------------------------------------------------------------------------
&AtServer
Function GetHPGJSONItemsData(pTransactions, pHotelCode, pRequestID, pDebugMode)
	vResult = New Structure("JSONString, ErrorDescription", "", "");
	
	vMessageName = "itemsResponse";
	
	vData = New ValueTable();
	vData.Columns.Add("code");
	vData.Columns.Add("description");
	vData.Columns.Add("type");
	For Each vTransactionsRow In pTransactions Do
		vDataRow = vData.Find(vTransactionsRow.itemCode, "code");
		If vDataRow = Undefined Then
			vDataRow = vData.Add();
			vDataRow.code = vTransactionsRow.itemCode;
			vDataRow.description = vTransactionsRow.itemDescription;
			If vTransactionsRow.transactionType = "charge" Then
				vDataRow.type = "charge";
			Else
				vDataRow.type = "payment";
			EndIf;
		EndIf;
	EndDo;
		
	vParams = New Structure;
	vParams.Insert("messageName", vMessageName);
	vParams.Insert("hotelCode", pHotelCode);
	vParams.Insert("requestID", pRequestID);
	vParams.Insert("items", vData);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for HPG - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString = Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	If pDebugMode Then
		vPos = StrFind(vJSONString, """items""");
		If vPos > 0 Then
			vJSONString = Mid(vJSONString, vPos);
			vJSONString = Left(vJSONString, StrLen(vJSONString) - 1);
		EndIf;
	EndIf;
	vResult.JSONString = vJSONString;
	
	Return vResult;
EndFunction // GetHPGJSONItemsData

// --------------------------------------------------------------------------------
&AtServer
Function GetHPGJSONTransactionsData(pTransactions, pHotelCode, pRequestID, pDebugMode)
	vResult = New Structure("JSONString, ErrorDescription", "", "");
	
	vMessageName = "TransactionsResponse";
	
	vData = New ValueTable();
	vData.Columns.Add("transactionCode");
	vData.Columns.Add("reservationCode");
	vData.Columns.Add("transactionType");
	vData.Columns.Add("transactionDate");
	vData.Columns.Add("itemCode");
	vData.Columns.Add("amount");
	vData.Columns.Add("discountPercent");
	vData.Columns.Add("notes");
	vData.Columns.Add("managerCode");
	For Each vTransactionsRow In pTransactions Do
		vDataRow = vData.Add();
		FillPropertyValues(vDataRow, vTransactionsRow, , "amount, discountPercent, transactionDate");
		vDataRow.amount = Format(vTransactionsRow.amount, "NFD=2; NDS=.; NZ=; NG=");
		vDataRow.discountPercent = Format(vTransactionsRow.discountPercent, "NFD=1; NDS=.; NZ=; NG=");
		vDataRow.transactionDate = Format(vTransactionsRow.transactionDate, "DF=yyyy-MM-ddTHH:mm:ss");
	EndDo;
		
	vParams = New Structure;
	vParams.Insert("messageName", vMessageName);
	vParams.Insert("hotelCode", pHotelCode);
	vParams.Insert("requestID", pRequestID);
	vParams.Insert("transactions", vData);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for HPG - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString = Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	If pDebugMode Then
		vPos = StrFind(vJSONString, """transactions""");
		If vPos > 0 Then
			vJSONString = Mid(vJSONString, vPos);
			vJSONString = Left(vJSONString, StrLen(vJSONString) - 1);
		EndIf;
	EndIf;
	vResult.JSONString = vJSONString;
	
	Return vResult;
EndFunction // GetHPGJSONTransactionsData

// --------------------------------------------------------------------------------
&AtServer
Function GetHPGJSONReservationsData(pDocuments, pHotelCode, pRequestID, pDebugMode)
	vResult = New Structure("JSONString, ErrorDescription", "", "");
	
	vMessageName = "ReservationsResponse";
	
	vData = New ValueTable();
	vData.Columns.Add("reservationCode");
	vData.Columns.Add("status");
	vData.Columns.Add("arrival");
	vData.Columns.Add("departure");
	vData.Columns.Add("nights");
	vData.Columns.Add("roomTypeCode");
	vData.Columns.Add("roomRateCode");
	vData.Columns.Add("packageCode");
	vData.Columns.Add("sourceCode");
	vData.Columns.Add("marketingCode");
	vData.Columns.Add("clientTypeCode");
	vData.Columns.Add("guestCode");
	vData.Columns.Add("cardID");
	vData.Columns.Add("agent1Code");
	vData.Columns.Add("agent1Commission");
	vData.Columns.Add("agent2Code");
	vData.Columns.Add("agent2Commission");
	vData.Columns.Add("adults");
	vData.Columns.Add("children");
	vData.Columns.Add("price");
	vData.Columns.Add("email");
	vData.Columns.Add("phone");
	vData.Columns.Add("customerCode");
	vData.Columns.Add("room");
	vData.Columns.Add("revenueTotal");
	vData.Columns.Add("revenueReward");
	vData.Columns.Add("revenueRoom");
	vData.Columns.Add("revenueEat");
	vData.Columns.Add("revenueServices");
	vData.Columns.Add("createdBy");
	vData.Columns.Add("created");
	vData.Columns.Add("changedBy");
	vData.Columns.Add("changed");
	For Each vDocumentsRow In pDocuments Do
		vDoc = vDocumentsRow.Reservation;
		
		// Calculate document sales and sales forecast
		vRevenueRoom = 0;
		vRevenueEat = 0;
		vRevenueServices = 0;
		vRevenueReward = 0;
		CalculateDocumentSales(vDoc, vRevenueRoom, vRevenueEat, vRevenueServices, vRevenueReward);
		vRevenueTotal = vRevenueRoom + vRevenueEat + vRevenueServices;
		
		vAgent2 = Undefined;
		vAgent2Commission = 0;
		vDocCustFileds = cmGetReservationCustomFieldsValues(vDoc);
		If vDocCustFileds.Count() > 0 Then
			vAgent2Row = vDocCustFileds.Find("Agent2                                            ", "CharacteristicCode");
			If vAgent2Row <> Undefined Then
				If ValueIsFilled(vAgent2Row.CharacteristicValue) Then
					vAgent2 = vAgent2Row.CharacteristicValue;
					vAgent2Commission = vAgent2.AgentCommission;
				EndIf;
			EndIf;
		EndIf;
		
		vDataRow = vData.Add();
		vDataRow.reservationCode = TrimAll(vDoc.Number);
		vDataRow.status = ?(TypeOf(vDoc) = Type("DocumentRef.Accommodation"), ?(vDoc.AccommodationStatus.IsActive, ?(vDoc.AccommodationStatus.IsInHouse, "checked-in", "checked-out"), "canceled"), ?(vDoc.ReservationStatus.IsActive, "reserved", "canceled"));
		vDataRow.arrival = Format(vDoc.CheckInDate, "DF=yyyy-MM-ddTHH:mm:ss");
		vDataRow.departure = Format(vDoc.CheckOutDate, "DF=yyyy-MM-ddTHH:mm:ss");
		vDataRow.nights = Format(vDoc.Duration, "NFD=0; NZ=; NG=");
		vDataRow.roomTypeCode = TrimAll(vDoc.RoomType.Code);
		vDataRow.roomRateCode = TrimAll(vDoc.RoomRate.Code);
		vDataRow.packageCode = ?(ValueIsFilled(vDoc.ServicePackage), TrimAll(vDoc.ServicePackage.Code), "");
		vDataRow.sourceCode = ?(ValueIsFilled(vDoc.SourceOfBusiness), TrimAll(vDoc.SourceOfBusiness.Code), "");
		vDataRow.marketingCode = ?(ValueIsFilled(vDoc.MarketingCode), TrimAll(vDoc.MarketingCode.Code), "");
		vDataRow.clientTypeCode = ?(ValueIsFilled(vDoc.ClientType), TrimAll(vDoc.ClientType.Code), "");
		vDataRow.guestCode = ?(ValueIsFilled(vDoc.Guest), TrimAll(vDoc.Guest.Code), "");
		vDataRow.cardID = ?(ValueIsFilled(vDoc.DiscountCard), TrimAll(vDoc.DiscountCard.Identifier), "");
		vDataRow.agent1Code = ?(ValueIsFilled(vDoc.Agent), TrimAll(vDoc.Agent.Code), "");
		vDataRow.agent1Commission = Format(vDoc.AgentCommission, "NFD=1; NDS=.; NZ=; NG=");
		vDataRow.agent2Code = ?(ValueIsFilled(vAgent2), TrimAll(vAgent2.Code), "");
		vDataRow.agent2Commission = Format(vAgent2Commission, "NFD=1; NDS=.; NZ=; NG=");
		vDataRow.adults = Format(vDoc.NumberOfAdults, "NFD=0; NZ=; NG=");
		vDataRow.children = Format(vDoc.NumberOfTeenagers + vDoc.NumberOfChildren + vDoc.NumberOfInfants, "NFD=0; NZ=; NG=");
		vDataRow.price = Format(GetReservationPrice(vDoc), "NFD=2; NDS=.; NZ=; NG=");
		vDataRow.email = TrimAll(vDoc.EMail);
		vDataRow.phone = TrimAll(vDoc.Phone);
		vDataRow.customerCode = ?(ValueIsFilled(vDoc.Customer), TrimAll(vDoc.Customer.Code), "");
		vDataRow.room = TrimAll(vDoc.Room);
		vDataRow.revenueTotal = Format(vRevenueTotal, "NFD=2; NDS=.; NZ=; NG=");
		vDataRow.revenueRoom = Format(vRevenueRoom, "NFD=2; NDS=.; NZ=; NG=");
		vDataRow.revenueEat = Format(vRevenueEat, "NFD=2; NDS=.; NZ=; NG=");
		vDataRow.revenueServices = Format(vRevenueServices, "NFD=2; NDS=.; NZ=; NG=");
		vDataRow.revenueReward = Format(vRevenueReward, "NFD=2; NDS=.; NZ=; NG=");
		vDataRow.createdBy = TrimAll(vDoc.Author.Code);
		vDataRow.created = Format(vDoc.Date, "DF=yyyy-MM-ddTHH:mm:ss");
		If TypeOf(vDoc) = Type("DocumentRef.Accommodation") Then
			vDataRow.changedBy = ?(ValueIsFilled(vDoc.CheckOutOperationAuthor), TrimAll(vDoc.CheckOutOperationAuthor.Code), "");
			vDataRow.changed = ?(ValueIsFilled(vDoc.CheckOutOperationTime), Format(vDoc.CheckOutOperationTime, "DF=yyyy-MM-ddTHH:mm:ss"), "");
		Else
			vLastChangeEmployee = Undefined;
			vLastChangeDate = '00010101';
			GetReservationLastChange(vDoc, vLastChangeEmployee, vLastChangeDate);
			vDataRow.changedBy = ?(ValueIsFilled(vLastChangeEmployee), TrimAll(vLastChangeEmployee.Code), "");
			vDataRow.changed = ?(ValueIsFilled(vLastChangeDate), Format(vLastChangeDate, "DF=yyyy-MM-ddTHH:mm:ss"), "");
		EndIf;
	EndDo;
		
	vParams = New Structure;
	vParams.Insert("messageName", vMessageName);
	vParams.Insert("hotelCode", pHotelCode);
	vParams.Insert("requestID", pRequestID);
	vParams.Insert("reservations", vData);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for HPG - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString = Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	If pDebugMode Then
		vPos = StrFind(vJSONString, """reservations""");
		If vPos > 0 Then
			vJSONString = Mid(vJSONString, vPos);
			vJSONString = Left(vJSONString, StrLen(vJSONString) - 1);
		EndIf;
	EndIf;
	vResult.JSONString = vJSONString;
	
	Return vResult;
EndFunction // GetHPGJSONReservationsData

// --------------------------------------------------------------------------------
&AtServer
Function GetSourcesOfBusinessArray(pExternalSystemCode, pHotel)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	(ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|			OR ExternalSystemsObjectCodesMappings.Hotel = &qEmptyHotel)
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""SourcesOfBusiness""";
	vQuery.SetParameter("qExternalSystemCode", pExternalSystemCode);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQueryResult = vQuery.Execute().Unload();
	Return vQueryResult.UnloadColumn("ObjectRef");
EndFunction // GetSourcesOfBusinessArray

// --------------------------------------------------------------------------------
&AtServer
Function GetChangedReservations(pPeriodFrom, pSourcesOfBusinessArray, pHotel)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Docs.Reservation AS Reservation,
		|	Docs.Reservation.ClientType AS ClientType,
		|	Docs.Reservation.SourceOfBusiness AS SourceOfBusiness,
		|	Docs.Reservation.MarketingCode AS MarketingCode,
		|	Docs.Reservation.RoomRate AS RoomRate,
		|	Docs.Reservation.ServicePackage AS ServicePackage,
		|	Docs.Reservation.RoomType AS RoomType,
		|	Docs.Reservation.DiscountCard AS DiscountCard,
		|	Docs.Reservation.Customer AS Customer,
		|	Docs.Reservation.Agent AS Agent,
		|	Docs.Reservation.Guest AS Guest,
		|	Docs.Reservation.Author AS Manager,
		|	Docs.Reservation.SortCode AS SortCode
		|FROM
		|	(SELECT
		|		ReservationChangeHistory.Reservation AS Reservation
		|	FROM
		|		InformationRegister.ReservationChangeHistory AS ReservationChangeHistory
		|	WHERE
		|		ReservationChangeHistory.Period >= &qPeriodFrom
		|		AND ReservationChangeHistory.Hotel >= &qHotel
		|		AND ReservationChangeHistory.Reservation.Posted
		|		AND ReservationChangeHistory.Reservation.Guest <> VALUE(Catalog.Clients.EmptyRef)
		|		AND ReservationChangeHistory.Reservation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|		AND ReservationChangeHistory.Reservation.SourceOfBusiness IN(&qSourcesOfBusiness)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AccommodationChangeHistory.Accommodation
		|	FROM
		|		InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
		|	WHERE
		|		AccommodationChangeHistory.Period >= &qPeriodFrom
		|		AND AccommodationChangeHistory.Hotel >= &qHotel
		|		AND AccommodationChangeHistory.Accommodation.Posted
		|		AND AccommodationChangeHistory.Accommodation.Guest <> VALUE(Catalog.Clients.EmptyRef)
		|		AND AccommodationChangeHistory.Accommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|		AND AccommodationChangeHistory.Accommodation.SourceOfBusiness IN(&qSourcesOfBusiness)) AS Docs
		|WHERE
		|	NOT ISNULL(Docs.Reservation.ReservationStatus.IsCheckIn, FALSE)
		|
		|GROUP BY
		|	Docs.Reservation,
		|	Docs.Reservation.ClientType,
		|	Docs.Reservation.SourceOfBusiness,
		|	Docs.Reservation.MarketingCode,
		|	Docs.Reservation.RoomRate,
		|	Docs.Reservation.ServicePackage,
		|	Docs.Reservation.RoomType,
		|	Docs.Reservation.DiscountCard,
		|	Docs.Reservation.Customer,
		|	Docs.Reservation.Agent,
		|	Docs.Reservation.Guest,
		|	Docs.Reservation.Author,
		|	Docs.Reservation.SortCode
		|
		|ORDER BY
		|	SortCode";
	vQuery.SetParameter("qPeriodFrom", pPeriodFrom);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qSourcesOfBusiness", pSourcesOfBusinessArray);
	vData = vQuery.Execute().Unload();
	Return vData;
EndFunction // GetChangedReservations

// --------------------------------------------------------------------------------
&AtServer
Function GetBlockedDiscountCards(pPeriodFrom, pHotel) Export
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	DiscountCards.Ref AS DiscountCard,
		|	DiscountCards.Author AS Manager
		|FROM
		|	Catalog.DiscountCards AS DiscountCards
		|WHERE
		|	DiscountCards.IsBlocked
		|	AND NOT DiscountCards.DeletionMark
		|	AND DiscountCards.IsBlockedDate >= &qPeriodFrom
		|
		|ORDER BY
		|	DiscountCards.Identifier";
	vQuery.SetParameter("qPeriodFrom", pPeriodFrom);
	vCards = vQuery.Execute().Unload();
	Return vCards;
EndFunction // GetBlockedDiscountCards

// --------------------------------------------------------------------------------
&AtServer
Function GetTransactions(pPeriodFrom, pSourcesOfBusinessArray, pHotel) Export
	vQuery = New Query;
	vQuery.Text = 
		"SELECT DISTINCT
		|	AccommodationChangeHistory.Accommodation AS Accommodation
		|INTO CheckedOutAccommodations
		|FROM
		|	InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
		|WHERE
		|	AccommodationChangeHistory.Period >= &qPeriodFrom
		|	AND AccommodationChangeHistory.Hotel >= &qHotel
		|	AND AccommodationChangeHistory.Accommodation.SourceOfBusiness IN(&qSourcesOfBusiness)
		|	AND AccommodationChangeHistory.Accommodation.Posted
		|	AND AccommodationChangeHistory.Accommodation.AccommodationStatus.IsActive
		|	AND NOT AccommodationChangeHistory.Accommodation.AccommodationStatus.IsInHouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Transactions.Recorder AS transaction,
		|	Transactions.Recorder.Number AS transactionCode,
		|	Transactions.Recorder.ParentDoc.Number AS reservationCode,
		|	CASE
		|		WHEN Transactions.Recorder REFS Document.Charge
		|			THEN ""Charge""
		|		WHEN Transactions.Recorder REFS Document.Storno
		|			THEN ""Charge""
		|		WHEN Transactions.Recorder REFS Document.Payment
		|			THEN CASE
		|					WHEN Transactions.PaymentMethod.IsByBonuses
		|						THEN ""bonusesPayment""
		|					ELSE ""Payment""
		|				END
		|		WHEN Transactions.Recorder REFS Document.Return
		|			THEN CASE
		|					WHEN Transactions.PaymentMethod.IsByBonuses
		|						THEN ""bonusesReturn""
		|					ELSE ""Return""
		|				END
		|		WHEN Transactions.Recorder REFS Document.DepositTransfer
		|			THEN ""Payment""
		|		ELSE """"
		|	END AS transactionType,
		|	BEGINOFPERIOD(Transactions.Recorder.Date, DAY) AS transactionDate,
		|	CASE
		|		WHEN Transactions.Recorder REFS Document.Charge
		|			THEN Transactions.Service.Code
		|		WHEN Transactions.Recorder REFS Document.Storno
		|			THEN Transactions.Service.Code
		|		WHEN Transactions.Recorder REFS Document.Payment
		|			THEN Transactions.PaymentMethod.Code
		|		WHEN Transactions.Recorder REFS Document.Return
		|			THEN Transactions.PaymentMethod.Code
		|		WHEN Transactions.Recorder REFS Document.DepositTransfer
		|			THEN Transactions.PaymentMethod.Code
		|		ELSE """"
		|	END AS itemCode,
		|	CASE
		|		WHEN Transactions.Recorder REFS Document.Charge
		|			THEN Transactions.Service.Description
		|		WHEN Transactions.Recorder REFS Document.Storno
		|			THEN Transactions.Service.Description
		|		WHEN Transactions.Recorder REFS Document.Payment
		|			THEN Transactions.PaymentMethod.Description
		|		WHEN Transactions.Recorder REFS Document.Return
		|			THEN Transactions.PaymentMethod.Description
		|		WHEN Transactions.Recorder REFS Document.DepositTransfer
		|			THEN Transactions.PaymentMethod.Description
		|		ELSE """"
		|	END AS itemDescription,
		|	CASE
		|		WHEN Transactions.Recorder REFS Document.Charge
		|			THEN Transactions.Sum
		|		WHEN Transactions.Recorder REFS Document.Storno
		|			THEN -Transactions.Sum
		|		WHEN Transactions.Recorder REFS Document.Payment
		|			THEN -Transactions.Sum
		|		WHEN Transactions.Recorder REFS Document.Return
		|			THEN Transactions.Sum
		|		WHEN Transactions.Recorder REFS Document.DepositTransfer
		|			THEN Transactions.Sum
		|		ELSE 0
		|	END AS amount,
		|	CASE
		|		WHEN Transactions.Recorder REFS Document.Charge
		|			THEN Transactions.Recorder.Discount
		|		WHEN Transactions.Recorder REFS Document.Storno
		|			THEN 0
		|		WHEN Transactions.Recorder REFS Document.Payment
		|			THEN 0
		|		WHEN Transactions.Recorder REFS Document.Return
		|			THEN 0
		|		WHEN Transactions.Recorder REFS Document.DepositTransfer
		|			THEN 0
		|		ELSE 0
		|	END AS discountPercent,
		|	Transactions.Recorder.Remarks AS notes,
		|	Transactions.Recorder.Author AS Manager,
		|	Transactions.Recorder.Author.Code AS managerCode
		|FROM
		|	AccumulationRegister.Accounts AS Transactions
		|WHERE
		|	Transactions.ParentDoc IN
		|			(SELECT
		|				CheckedOutAccommodations.Accommodation
		|			FROM
		|				CheckedOutAccommodations AS CheckedOutAccommodations)";
	vQuery.SetParameter("qPeriodFrom", pPeriodFrom);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qSourcesOfBusiness", pSourcesOfBusinessArray);
	vTransactions = vQuery.Execute().Unload();
	Return vTransactions;
EndFunction // GetTransactions

// --------------------------------------------------------------------------------
&AtServer
Function GetCatalogItems(pCatalogName, pItemsList)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Items.Ref AS Ref,
		|	Items.Code AS code,
		|	Items.Description AS description
		|FROM
		|	Catalog." + pCatalogName + " AS Items
		|WHERE
		|	Items.Ref IN(&qItemsList)
		|
		|ORDER BY
		|	Items.Description";
	vQuery.SetParameter("qItemsList", pItemsList);
	vData = vQuery.Execute().Unload();
	Return vData;
EndFunction // GetCatalogItems

// --------------------------------------------------------------------------------
&AtServer
Function GetCustomers(pItemsList)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Items.Ref AS Ref,
		|	Items.Code AS code,
		|	Items.Description AS description,
		|	Items.TIN AS TIN,
		|	Items.KPP AS KPP,
		|	Items.EMail AS EMail,
		|	Items.Phone AS Phone
		|FROM
		|	Catalog.Customers AS Items
		|WHERE
		|	Items.Ref IN(&qItemsList)
		|
		|ORDER BY
		|	Items.Description";
	vQuery.SetParameter("qItemsList", pItemsList);
	vData = vQuery.Execute().Unload();
	Return vData;
EndFunction // GetCustomers

// --------------------------------------------------------------------------------
&AtServer
Function GetGuests(pItemsList, pPreiodFrom)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT DISTINCT
		|	Items.Client AS Ref,
		|	Items.Client.Code AS code,
		|	Items.Client.FullName AS fullName,
		|	Items.Client.EMail AS email,
		|	Items.Client.Phone AS phone,
		|	Items.Client.DateOfBirth AS birthdate,
		|	CASE
		|		WHEN Items.Client.Sex = VALUE(Enum.Sex.Female)
		|			THEN ""F""
		|		ELSE ""M""
		|	END AS sex,
		|	Items.Client.ClientType.Code AS clientTypeCode,
		|	Items.Client.DiscountCard AS card,
		|	Items.Client.DiscountCard.Identifier AS cardID,
		|	Items.Client.DiscountCard.Author.Code AS createdBy,
		|	Items.Client.DiscountCard.CreateDate AS created,
		|	ClientLastChanges.User.Code AS changedBy,
		|	ClientLastChanges.Period AS changed
		|FROM
		|	(SELECT
		|		Clients.Ref AS Client
		|	FROM
		|		Catalog.Clients AS Clients
		|	WHERE
		|		Clients.Ref IN(&qItemsList)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ClientChangeHistory.Client
		|	FROM
		|		InformationRegister.ClientChangeHistory AS ClientChangeHistory
		|	WHERE
		|		ClientChangeHistory.Period >= &qPeriodFrom
		|	
		|	GROUP BY
		|		ClientChangeHistory.Client) AS Items
		|		LEFT JOIN InformationRegister.ClientChangeHistory.SliceLast(, Client IN (&qItemsList)) AS ClientLastChanges
		|		ON (ClientLastChanges.Client = Items.Client)
		|WHERE
		|	Items.Client.DiscountCard <> VALUE(Catalog.DiscountCards.EmptyRef)
		|
		|ORDER BY
		|	Items.Client.Description";
	vQuery.SetParameter("qItemsList", pItemsList);
	vQuery.SetParameter("qPeriodFrom", pPreiodFrom);
	vData = vQuery.Execute().Unload();
	Return vData;
EndFunction // GetGuests

// --------------------------------------------------------------------------------
&AtServer
Function GetDiscountCards(pDiscountCardsList)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	DiscountCards.Ref AS DiscountCard,
		|	DiscountCards.Identifier AS CardID,
		|	ISNULL(DiscountCards.Client.Code, """") AS guestCode,
		|	DiscountCards.ClientType AS ClientType,
		|	DiscountCards.ClientType.Code AS ClientTypeCode,
		|	DiscountCards.IsBlocked AS IsBlocked,
		|	DiscountCards.CreateDate AS Created,
		|	DiscountCards.Author AS CreatedBy,
		|	DiscountCards.Author.Code AS CreatedByCode,
		|	DiscountCards.CreateHotel AS CreatedHotel,
		|	DiscountCards.CreateHotel.Code AS CreatedHotelCode,
		|	DiscountCards.IsBlockedDate AS changed,
		|	DiscountCards.IsBlockedAuthor AS changedBy,
		|	DiscountCards.IsBlockedAuthor.Code AS changedByCode
		|FROM
		|	Catalog.DiscountCards AS DiscountCards
		|WHERE
		|	DiscountCards.Ref IN(&qDiscountCards)
		|
		|ORDER BY
		|	DiscountCards.Identifier";
	vQuery.SetParameter("qDiscountCards", pDiscountCardsList);
	vCards = vQuery.Execute().Unload();
	Return vCards;
EndFunction // GetDiscountCards

// --------------------------------------------------------------------------------
Procedure CalculateDocumentSales(pDoc, rRevenueRoom, rRevenueEat, rRevenueServices, rRevenueReward)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	TotalSales.ServiceType AS ServiceType,
	|	SUM(TotalSales.Sum) AS Sum,
	|	SUM(TotalSales.RoomRevenue) AS RoomRevenue,
	|	SUM(TotalSales.SumReward) AS SumReward
	|FROM
	|	(SELECT
	|		SalesForecastTurnovers.Service.ServiceType AS ServiceType,
	|		SalesForecastTurnovers.SalesTurnover AS Sum,
	|		SalesForecastTurnovers.RoomRevenueTurnover AS RoomRevenue,
	|		0 AS SumReward
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				ParentDoc.Number = &qDocNumber
	|					AND Hotel = &qHotel) AS SalesForecastTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesTurnovers.Service.ServiceType,
	|		SalesTurnovers.SalesTurnover,
	|		SalesTurnovers.RoomRevenueTurnover,
	|		SalesTurnovers.SalesTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				,
	|				,
	|				Period,
	|				ParentDoc.Number = &qDocNumber
	|					AND Hotel = &qHotel) AS SalesTurnovers) AS TotalSales
	|
	|GROUP BY
	|	TotalSales.ServiceType";
	vQry.SetParameter("qDocNumber", pDoc.Number);
	vQry.SetParameter("qHotel", pDoc.Hotel);
	vForecastStartDate = tcOnServer.GetForecastStartDate(pDoc.Hotel);
	vQry.SetParameter("qForecastPeriodFrom", vForecastStartDate);
	vQry.SetParameter("qForecastPeriodTo", '39991231235959');
	
	vTotals = vQry.Execute().Unload();
	For Each vTotalsRow In vTotals Do
		If vTotalsRow.RoomRevenue <> 0 Then
			rRevenueRoom = rRevenueRoom + vTotalsRow.RoomRevenue;
		Else
			If ValueIsFilled(vTotalsRow.ServiceType) And vTotalsRow.ServiceType.RevenueSegment = Enums.RevenueSegments.FaB Then
				rRevenueEat = rRevenueEat + vTotalsRow.Sum;
			Else
				rRevenueServices = rRevenueServices + vTotalsRow.Sum;
			EndIf;
		EndIf;
		If pDoc.Discount = 0 Then
			rRevenueReward = rRevenueReward + vTotalsRow.SumReward;
		EndIf;
	EndDo;
EndProcedure // CalculateDocumentSales

// --------------------------------------------------------------------------------
Procedure GetReservationLastChange(pDoc, rLastChangeEmployee, rLastChangeDate)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationChangeHistorySliceLast.Period AS Period,
	|	ReservationChangeHistorySliceLast.User AS User
	|FROM
	|	InformationRegister.ReservationChangeHistory.SliceLast(&qPeriod, Reservation = &qRef) AS ReservationChangeHistorySliceLast";
	vQry.SetParameter("qRef", pDoc);
	vQry.SetParameter("qPeriod", CurrentSessionDate());
	vRcds = vQry.Execute().Unload();
	If vRcds.Count() > 0 Then
		vRcdsRow = vRcds.Get(0);
		rLastChangeEmployee = vRcdsRow.User;
		rLastChangeDate = vRcdsRow.Period;
	EndIf;
EndProcedure // GetReservationLastChange

// --------------------------------------------------------------------------------
Function GetReservationPrice(pDoc)
	vPrice = 0;
	If ValueIsFilled(pDoc) Then
		vDate = '00010101';
		For Each vSrvRow In pDoc.Services Do
			If Not ValueIsFilled(vDate) Then
				vDate = vSrvRow.AccountingDate;
			EndIf;
			If vSrvRow.AccountingDate = vDate Then
				If vSrvRow.IsInPrice Then
					vPrice = vPrice + vSrvRow.Sum - vSrvRow.DiscountSum;
				EndIf;
			Else
				Break;
			EndIf;
		EndDo;
	EndIf;
	Return vPrice;
EndFunction // GetReservationPrice

// --------------------------------------------------------------------------------
&AtServer
Procedure InitializeJSONSettings() Export
	
	// HPGDataRequest
	vJSONString						= "{""requestID"": ""2019-01-28T16:25:03"",""success"": true,""errorDescription"": """"}";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "HPGDataRequest", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;
	
	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_HPGDataRequest_Response";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "HPGDataRequest", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// ManagersResponse
	vJSONString						= "{  ""messageName"": ""ManagersResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""managers"":  [  {  ""code"": ""LMY"",  ""description"": ""Лежнев М.Ю."", ""isBlocked"": ""false""  }  ] }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "ManagersResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;
	
	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_ManagersResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "ManagersResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// ClientTypesResponse
	vJSONString						= "{  ""messageName"": ""ClientTypesResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""clientTypes"":  [  {  ""code"": ""VIP1"",  ""description"": ""VIP level 1""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "ClientTypesResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;
	
	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_ClientTypesResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "ClientTypesResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// RoomTypesResponse
	vJSONString						= "{  ""messageName"": ""RoomTypesResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""roomTypes"":  [  {  ""code"": ""DBL"",  ""description"": ""Double Standard""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "RoomTypesResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;
	
	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_RoomTypesResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "RoomTypesResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// SourcesResponse
	vJSONString						= "{  ""messageName"": ""SourcesResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""sources"":  [  {  ""code"": ""IND1"",  ""description"": ""Individuals, OTA""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "SourcesResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;
	
	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_SourcesResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "SourcesResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// MarketingCodesResponse
	vJSONString						= "{  ""messageName"": ""MarketingCodesResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""marketingCodes"":  [  {  ""code"": ""FAM"",  ""description"": ""Families""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "MarketingCodesResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;
	
	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_MarketingCodesResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "MarketingCodesResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// RoomRatesResponse
	vJSONString						= "{  ""messageName"": ""RoomRatesResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""roomRates"":  [  {  ""code"": ""RACK"",  ""description"": ""Базовый""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "RoomRatesResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;
	
	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_RoomRatesResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "RoomRatesResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);

	// PackagesResponse
	vJSONString						= "{  ""messageName"": ""PackagesResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""packages"":  [  {  ""code"": ""AI"",  ""description"": ""All inclusive""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "PackagesResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;
	
	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_PackagesResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "PackagesResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// ItemsResponse
	vJSONString						= "{  ""messageName"": ""ItemsResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""items"":  [  {  ""code"": ""120"",  ""description"": ""Проживание"",  ""type"": ""charge""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "ItemsResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;

	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_ItemsResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "ItemsResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// CustomersResponse
	vJSONString						= "{  ""messageName"": ""CustomersResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""customers"":  [  {  ""code"": ""TLS00000567"",  ""description"": ""Роза ветров, ООО"",  ""TIN"": ""1232234234332"",  ""KPP"": ""232322323"", ""email"": ""mail3@mail.ru"",  ""phone"": ""74956389678""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "CustomersResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;

	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_CustomersResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "CustomersResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// GuestsResponse
	vJSONString						= "{  ""messageName"": ""GuestsResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""guests"":  [  {  ""code"": ""TLS000002345"",  ""fullName"": ""Иванова Ольга Петровна"", ""email"": ""mail1@mail.ru"",  ""phone"": ""79012345678"",  ""birthdate"": ""1980-08-31"",  ""sex"": ""F"",  ""clientTypeCode"": ""VIP1"",  ""cardID"": ""456987"",  ""createdBy"": ""BPG"",  ""created"": ""2018-09-12T13:44:23"",  ""changedBy"": ""BPG"",  ""changed"": ""2018-09-12T13:44:23""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "GuestsResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;
	
	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_GuestsResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "GuestsResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// DiscountCardsResponse
	vJSONString						= "{  ""messageName"": ""DiscountCardsResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""discountCards"":  [  {  ""cardID"": ""456987"",  ""clientTypeCode"": ""ORNBN"",  ""guestCode"": ""TLS000034567"",  ""isBlocked"": ""false"",  ""createdHotel"": ""TLS"",  ""createdBy"": ""BPG"",  ""created"": ""2019-03-08T10:23:45"",  ""changedBy"": ""BPG"",  ""changed"": ""2019-03-08T10:23:45""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "DiscountCardsResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;

	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_DiscountCardsResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "DiscountCardsResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// ReservationsResponse
	vJSONString						= "{  ""messageName"": ""ReservationsResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""reservations"":  [  {  ""reservationCode"": ""070400034567"",  ""status"": ""Reserved"",  ""arrival"": ""2019-02-28T17:00:00"",  ""departure"": ""2019-03-08:15:00:00"",  ""nights"": ""8"",  ""roomTypeCode"": ""DBL"",  ""roomRateCode"": ""RACK"",  ""packageCode"": ""AI"",  ""sourceCode"": ""IND1"",  ""marketingCode"": ""IND"",  ""clientTypeCode"": ""VIP1"",  ""guestCode"": ""TLS000034567"",  ""cardID"": ""1333213"",  ""agent1Code"": ""TLS000000345"",  ""agent1Commission"": ""20"",  ""agent2Code"": """",  ""agent2Commission"": ""0"",  ""adults"": ""2"",  ""children"": ""0"",  ""price"": ""0"",  ""email"": ""mail3@mail.ru"",  ""phone"": ""79345678923"",  ""customerCode"": ""TLS000000345"",  ""room"": ""4203"",  ""revenueTotal"": ""50000.00"",  ""revenueReward"": ""40000.00"",  ""revenueRoom"": ""25000.00"",  ""revenueEat"": ""15000.00"",  ""revenueServices"": ""0"",  ""createdBy"": ""LMY"",  ""created"": ""2018-12-23T10:25:34"",  ""changedBy"": ""BPG"",  ""changed"": ""2019-01-26T19:45:23""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "ReservationsResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;

	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_ReservationsResponse";
	vLoadRule.Write();
	
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "ReservationsResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	
	// TransactionsResponse
	vJSONString						= "{  ""messageName"": ""TransactionsResponse"",  ""hotelCode"": ""TLS"",  ""requestID"": ""2019-01-28T16:25:03.123"",  ""transactions"":  [  {  ""transactionCode"": ""070400456987"",  ""reservationCode"": ""070400034567"",  ""transactionType"": ""charge"",  ""transactionDate"": ""2019-03-08T00:00:00"",  ""itemCode"": ""3456"",  ""amount"": ""2300.00"",  ""discountPercent"": ""10.0"",  ""notes"": ""Пользовательские примечания к транзакции"",  ""managerCode"": ""BPG""  }  ]  }";
	vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("HPG", "TransactionsResponse", Enums.DataConvertationTypes.JSONLoad);
	If Not ValueIsFilled(vRules) Then 
		vLoadRule 					= Catalogs.DataConvertationRules.CreateItem();
	Else
		vLoadRule 					= vRules.GetObject();
	EndIf;
	
	vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
	vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
	vLoadRule.Description			= "HPG_TransactionsResponse";
	vLoadRule.Write();
		
	Catalogs.DataConvertationRules.WriteFunctionMapping("HPG", "TransactionsResponse", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);

EndProcedure // InitializeJSONSettings

// --------------------------------------------------------------------------------
//#TODO Make universal connection module
// --------------------------------------------------------------------------------
Function SendQuery(pJSON, pExternalSystemInteractions, pAction)
	Try
		// Get callback connection parameters
		vHTTPServer = TrimAll(pExternalSystemInteractions.HTTPServer);
		vHTTPServerPort = ?(pExternalSystemInteractions.HTTPPort = 0, 80, pExternalSystemInteractions.HTTPPort);
		vHTTPAddress = TrimAll(pExternalSystemInteractions.HttpAddress);
		vHTTPUser = TrimAll(pExternalSystemInteractions.Login);
		vHTTPPwd = TrimAll(pExternalSystemInteractions.Password);
		vUseSSL = pExternalSystemInteractions.HTTPUseSSL;
	
		// HTTP header
		vHTTPHeader = New Map;
		vHTTPHeader.Insert("Content-Type", "application/json;charset=utf-8");
		vHTTPHeader.Insert("POST", pAction);
		vHTTPHeader.Insert("Host", vHTTPServer);
						
		// HTTP connection
		vSSL = Undefined;
		If vUseSSL Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);       	
		EndIf;
		vHTTPConnection = New HTTPConnection(vHTTPServer, vHTTPServerPort, vHTTPUser, vHTTPPwd, , , vSSL);

		// Send JSON data
		vHTTPRequest = New HTTPRequest(vHTTPAddress, vHTTPHeader);
		vHTTPRequest.SetBodyFromString(pJSON);
		vRs = vHTTPConnection.Post(vHTTPRequest);
		
		Return vRs.GetBodyAsString();
	Except
		vError = ErrorDescription();
		WriteLogEvent("HPG_SendQuery", EventLogLevel.Warning,,CurrentSessionDate(),"Неудалось отправить HPG POST запрос! " + vError);
		Return vError;
	EndTry;
	Return Undefined;	
EndFunction // SendQuery
