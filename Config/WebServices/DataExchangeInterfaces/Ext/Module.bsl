#Region EventHandlers 

// --------------------------------------------------------------------------------
Function Synchronize(pExchangePlanName, pMessageNo, pSourceNodeCode, pTargetNodeCode, pChangedData, pFileSize)
	vResult = "OK";	
	
	// Try to find source and target nodes by codes
	vSourceNode = ExchangePlans[pExchangePlanName].FindByCode(TrimR(pSourceNodeCode));
	If Not ValueIsFilled(vSourceNode) Then
		Raise NStr("en='Source node code is wrong: '; de='Source node code is wrong: '; ru='Неправильно указан код узла источника данных: '") + TrimR(pSourceNodeCode) + " (" + TrimR(pExchangePlanName) + ")!";
	EndIf;
	If vSourceNode.DeletionMark Then
		Raise NStr("en='On-line synchronization is switched off for marked for deletion node: '; de='On-line synchronization is switched off for marked for deletion node: '; ru='On-line синхронизация выключена для помеченного на удаление узла: '") + TrimR(pSourceNodeCode) + " (" + TrimR(pExchangePlanName) + ")!";
	EndIf;
	If Not vSourceNode.OnlineSyncIsActive Then
		Raise NStr("en='On-line synchronization is switched off for node: '; de='On-line synchronization is switched off for node: '; ru='On-line синхронизация выключена для узла: '") + TrimR(pSourceNodeCode) + " (" + TrimR(pExchangePlanName) + ")!";
	EndIf;
	vTargetNode = ExchangePlans[pExchangePlanName].FindByCode(TrimR(pTargetNodeCode));
	If Not ValueIsFilled(vTargetNode) Then
		Raise NStr("en='Target node code is wrong: '; de='Target node code is wrong: '; ru='Неправильно указан код узла получателя данных: '") + TrimR(pTargetNodeCode) + " (" + TrimR(pExchangePlanName) + ")!";
	EndIf;
	If vTargetNode.DeletionMark Then
		Raise NStr("en='On-line synchronization is switched off for marked for deletion node: '; de='On-line synchronization is switched off for marked for deletion node: '; ru='On-line синхронизация выключена для помеченного на удаление узла: '") + TrimR(pTargetNodeCode) + " (" + TrimR(pExchangePlanName) + ")!";
	EndIf;
	If Not vTargetNode.OnlineSyncIsActive Then
		Raise NStr("en='On-line synchronization is switched off for node: '; de='On-line synchronization is switched off for node: '; ru='On-line синхронизация выключена для узла: '") + TrimR(pTargetNodeCode) + " (" + TrimR(pExchangePlanName) + ")!";
	EndIf;
	
	Try  
		InformationRegisters.ExchangePlanData.WriteData(pMessageNo, vSourceNode, vTargetNode, Base64Value(pChangedData), pFileSize, False, '00010101', True, CurrentSessionDate(), False, '00010101');		
	Except
		vResult = ErrorDescription();
		WriteLogEvent(NStr("en='On-line synchronize'; ru='Синхронизация on-line'; de='Online-Synchronisation'"), EventLogLevel.Error, , , vResult);
	EndTry;
	
	// Return changes being read
	Return vResult;
EndFunction // Synchronize

// --------------------------------------------------------------------------------
Function CheckIfDiscountCardNeedToBeIssued(pClientCode, pHotelCode, pCheckPeriod, pLanguageCode, pReservationData)
	vErrorDescription = "";
	Try
		// Process parameters
		vHotel = Catalogs.Hotels.FindByCode(pHotelCode);
		vClient = Catalogs.Clients.FindByCode(pClientCode);
		vLanguage = Catalogs.Languages.FindByCode(pLanguageCode);
		// Try to find rule suitable for the client
		vClientResource = 0;
		vClientRule = Undefined;
		// Run query to get discount card issue rules
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	DiscountCardIssueRules.AccumulatingDiscountType AS AccumulatingDiscountType,
		|	DiscountCardIssueRules.ResourceFrom AS ResourceFrom,
		|	DiscountCardIssueRules.ResourceTo AS ResourceTo,
		|	DiscountCardIssueRules.DiscountType,
		|	DiscountCardIssueRules.ClientType,
		|	DiscountCardIssueRules.ValidFrom,
		|	DiscountCardIssueRules.ValidTo,
		|	DiscountCardIssueRules.Notification,
		|	DiscountCardIssueRules.ExternalAlgorithm,
		|	DiscountCardIssueRules.UseResourcesPayedAsIndividual,
		|	DiscountCardIssueRules.UseResourcesPayedByRackRates
		|FROM
		|	InformationRegister.DiscountCardIssueRules AS DiscountCardIssueRules
		|
		|ORDER BY
		|	DiscountCardIssueRules.AccumulatingDiscountType.Order,
		|	ResourceFrom,
		|	ResourceTo";
		vRules = vQry.Execute().Unload();
		If vRules.Count() = 0 Then
			// No rules found
			vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/data/", "CheckIfDiscountCardNeedToBeIssued"));
			vRetXDTO.ErrorDescription = "";
			vRetXDTO.ClientResource = 0;
			vRetXDTO.ClientTypeCode = "";
			vRetXDTO.DiscountTypeCode = "";
			vRetXDTO.ValidFrom = '00010101';
			vRetXDTO.ValidTo = '00010101';
			vRetXDTO.Notification = "";
			Return vRetXDTO;
		EndIf;
		// Get client object
		vClientObj = vClient.GetObject();
		// Process rules
		vCurAccumulatingDiscountType = Undefined;
		For Each vRulesRow In vRules Do
			// Get type of client stats to check
			If Not ValueIsFilled(vRulesRow.AccumulatingDiscountType) Then
				// Wrong rule record
				Continue;
			EndIf;
			If vCurAccumulatingDiscountType <> vRulesRow.AccumulatingDiscountType Then
				vCurAccumulatingDiscountType = vRulesRow.AccumulatingDiscountType;
				vClientResource = 0;
				// Check for an external algorithm
				vExternalDataProcessor = vRulesRow.ExternalAlgorithm;
				If ValueIsFilled(vExternalDataProcessor) Then
					If vExternalDataProcessor.ExternalProcessingType <> Enums.ExternalProcessingTypes.Algorithm Then
						Raise NStr("en='Wrong external extension type! Should be <algorithm>';
						           |ru='Неверно указан тип внешнего модуля! Должен быть <Алгоритм>';
								   |de='Der Typ des externen Moduls ist falsch angegeben! Es muss einen <Algorithmus> geben'");
					Else
						vExternalAlgorithm = TrimR(vExternalDataProcessor.Algorithm);
						If IsBlankString(vExternalAlgorithm) Then
							Raise NStr("en='External algorithm is empty!';ru='Внешний алгоритм не указан!';de='Externer Algorithmus nicht angegeben!'");
						Else
							Execute(vExternalAlgorithm);
						EndIf;
					EndIf;
				Else
					// Get client statistics
					If vCurAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByNumberOfGuestVisits Then
						WriteLogEvent("CheckIfDiscountCardNeedToBeIssued", , , , "pCheckPeriod = " + pCheckPeriod);
						vClientResource = vClientObj.pmCountNumberOfCheckIns(, pCheckPeriod, vRulesRow.UseResourcesPayedAsIndividual, vRulesRow.UseResourcesPayedByRackRates);
					ElsIf vCurAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByAccommodationDuration Then
						vClientResource = vClientObj.pmCountNumberOfNights(, pCheckPeriod, vRulesRow.UseResourcesPayedAsIndividual, vRulesRow.UseResourcesPayedByRackRates);
					ElsIf vCurAccumulatingDiscountType = Enums.AccumulatingDiscountTypes.ByServicesTotalSum Then
						vRevenues = vClientObj.pmGetClientRevenueStatistics(, pCheckPeriod, vRulesRow.UseResourcesPayedAsIndividual, vRulesRow.UseResourcesPayedByRackRates);
						vClientResource = vRevenues.Total("SalesTurnover");
					EndIf;
				EndIf;
			EndIf;
			If vRulesRow.ResourceFrom <= vClientResource And (vRulesRow.ResourceTo = 0 Or vRulesRow.ResourceTo > vClientResource) Then
				If vClientRule = Undefined Then
					vClientRule = vRulesRow;
				Else
					If ValueIsFilled(vClientRule.DiscountType) And ValueIsFilled(vRulesRow.DiscountType) And vRulesRow.DiscountType.SortCode > vClientRule.DiscountType.SortCode Then
						vClientRule = vRulesRow;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorDescription());
	EndTry;
	// Build return XDTO object
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/dataexchange/", "CheckIfDiscountCardNeedToBeIssued"));
	vRetXDTO.ErrorDescription = vErrorDescription;
	If vClientRule <> Undefined Then
		vRetXDTO.ClientResource = vClientResource;
		vRetXDTO.ClientTypeCode = ?(ValueIsFilled(vClientRule.ClientType), TrimAll(vClientRule.ClientType.Code), "");
		vRetXDTO.DiscountTypeCode = ?(ValueIsFilled(vClientRule.DiscountType), TrimAll(vClientRule.DiscountType.Code), "");
		vRetXDTO.ValidFrom = vClientRule.ValidFrom;
		vRetXDTO.ValidTo = vClientRule.ValidTo;
		vRetXDTO.Notification = cmNStr(TrimAll(vClientRule.Notification), vLanguage);
	Else
		vRetXDTO.ClientResource = -1;
		vRetXDTO.ClientTypeCode = "";
		vRetXDTO.DiscountTypeCode = "";
		vRetXDTO.ValidFrom = '00010101';
		vRetXDTO.ValidTo = '00010101';
		vRetXDTO.Notification = "";
	EndIf;
	// Return results
	Return vRetXDTO;
EndFunction // CheckIfDiscountCardNeedToBeIssued

#EndRegion