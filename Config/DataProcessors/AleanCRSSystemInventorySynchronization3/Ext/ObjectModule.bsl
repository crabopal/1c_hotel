
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If IsBlankString(ServerServicesWSDLHost) Then
		ServerServicesWSDLHost = "http://extgate.alean.ru:8082/webservice/ewebsvc.dll/wsdl/IewsServer";
	EndIf;
	If IsBlankString(InventoryServicesWSDLHost) Then
		InventoryServicesWSDLHost = "http://extgate.alean.ru:8082/webservice/ewebsvc.dll/wsdl/ItwsHotelAdapterInventory";
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Check parameters
	If Not ValueIsFilled(ExternalInteraction) Then
		Raise NStr("en='External interaction settings are not filled!';ru='Не указаны настройки внешнего взаимодействия!';de='Die Einstellungen der externen Kommunikation sind nicht angegeben!'");
	EndIf;
	
	If ExternalInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'")+ Chars.LF + 
			"ConnectionID: " + ConnectionID + Chars.LF +
			"ServerServicesWSDLHost: " + ServerServicesWSDLHost + Chars.LF +
			"InventoryServicesWSDLHost: " + InventoryServicesWSDLHost + Chars.LF +
		    "ForceFullSynchronization: " + ForceFullSynchronization + Chars.LF +
			"ForceNewSession: " + ForceNewSession + Chars.LF +
			"SynchronizationRoomPrices: " + SynchronizationRoomPrices + Chars.LF +
			"ForceFullRoomPricesSynchronization: " + ForceFullRoomPricesSynchronization;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmRun", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
	EndIf;

	If IsBlankString(ServerServicesWSDLHost) Then
		vMsg =  NStr("en='Server services WSDL address is empty!'; de='Server services WSDL address is empty!'; ru='Не указан адрес WSDL службы Server services!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmRun.CheckAttribute", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	If IsBlankString(InventoryServicesWSDLHost) Then
		vMsg = NStr("en='Inventory services WSDL address is empty!'; de='Inventory services WSDL address is empty!'; ru='Не указан адрес WSDL службы Inventory services!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmRun.CheckAttribute", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	
	vLastSyncDate = CurrentSessionDate();
	
	// Create WEB-services proxy
	vAleanCRSServerServiceDefinition = New WSDefinitions(TrimR(ServerServicesWSDLHost));
	vAleanCRSServerServiceProxy = New WSProxy(vAleanCRSServerServiceDefinition, "urn:webservice-electrasoft-ru", "IewsServerservice", "IewsServerPort");
	
	// Check if interaction is active
	If Not ExternalInteraction.IsActive Then
		If Not IsBlankString(ExternalInteraction.SessionID) Then
			vAleanCRSServerServiceProxy.Logout(TrimR(ExternalInteraction.SessionID));
			
			// Clear session attributes
			vExternalInteractionObj = ExternalInteraction.GetObject();
			vExternalInteractionObj.pmClearSessionAttributes();
			vExternalInteractionObj.Write();
			
			// Finish processing
			Return;
		EndIf;
		// Raise exception to inform system administrators to stop background job
		vMsg =  NStr("en='External interaction is not active now!'; de='External interaction is not active now!'; ru='Внешнее взаимодействие на текущий момент не активно!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmRun.CheckAttribute", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	
	// Check should we create new session or we can use old one
	vCreateNewSession = False;
	If ForceNewSession Then
		vCreateNewSession = True;
	ElsIf IsBlankString(ExternalInteraction.SessionID) Then
		vCreateNewSession = True;
	ElsIf Not ValueIsFilled(ExternalInteraction.SessionLastActivityTime) Then
		vCreateNewSession = True;
	ElsIf ExternalInteraction.SessionTimeout > 0 And (CurrentSessionDate() - ExternalInteraction.SessionLastActivityTime)/60 > ExternalInteraction.SessionTimeout Then
		vCreateNewSession = True;
	EndIf;
	
	// Check if session is alive
	If Not vCreateNewSession Then
		Try 
			// Ping external system and check that it is alive
			vAleanCRSServerServiceProxy.Ping(TrimR(ExternalInteraction.SessionID));
		Except
			vCreateNewSession = True;
		EndTry;
	ElsIf IsBlankString(ExternalInteraction.SessionID) Then
		Try 
			// Ping external system and logout 
			vAleanCRSServerServiceProxy.Ping(TrimR(ExternalInteraction.SessionID));
			vAleanCRSServerServiceProxy.Logout(TrimR(ExternalInteraction.SessionID));
		Except
		EndTry;
	EndIf;
	// Create new session
	If vCreateNewSession Then
		// Clear previous session data first
		vExternalInteractionObj = ExternalInteraction.GetObject();
		vExternalInteractionObj.pmClearSessionAttributes();
		vExternalInteractionObj.Write();
		// Try to login to the Alean CRS system and get new session id
		vLoginResult = "";
		vSessionID = "";
		vAleanCRSServerServiceProxy.Login(TrimAll(ConnectionID), TrimR(ExternalInteraction.Login), TrimR(ExternalInteraction.Password), "RU", "", "", (ExternalInteraction.SessionTimeout * 60 * 1000), vLoginResult, vSessionID);
		If TrimAll(vLoginResult) = "lrSuccess" Then
			// Save session ID and session times
			vExternalInteractionObj.pmSetNewSessionAttributes(vSessionID);
			vExternalInteractionObj.Write();
			// Refresh link
			ExternalInteraction = vExternalInteractionObj.Ref;
		Else
			vMsg =  NStr("en='External interaction login error! '; de='External interaction login error! '; ru='Ошибка подключения внешнего взаимодействия! '") + TrimAll(vLoginResult);
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmRun.CreateNewSession", Enums.ExternalSystemEventTypes.Error, , , vMsg);
			Raise vMsg;
		EndIf;
	EndIf;
	
	// Make decision do we have to export changes or do full synchronization
	vFull = pmCheckFullSyncTime(ExternalInteraction, pIsInteractive, False);
		
	// Synchronize room inventory
	If SynchronizeRoomInventory Then
		pmSynchronize(pIsInteractive, ?(vFull, vFull, ForceFullSynchronization), vLastSyncDate);
	EndIf;
	// Synchronize prices
	If SynchronizationRoomPrices Then
		pmSynchronizeRoomRatePrices(pIsInteractive, ?(vFull, vFull, ForceFullRoomPricesSynchronization), vLastSyncDate);
	EndIf;
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure pmSynchronizeRoomRatePrices(pIsInteractive = False, pFull = False, pLastSyncDate = '00010101') Export
	If ExternalInteraction.DebugMode Then
		vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'")+ Chars.LF + "IsInteractive: " + pIsInteractive + Chars.LF + "IsFull: " + pFull;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronizeRoomRatePrices.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
	EndIf;
	vPricesDataXML = "";   
	// Update interaction info
	vExternalInteractionObj = ExternalInteraction.GetObject();
	vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
	vExternalInteractionObj.ErrorDescription = NStr("en = 'Uploading prices'; de = 'Preise hochladen'; ru = 'Выгрузка цен'");
	vExternalInteractionObj.Write();

	Try
		// Do all in transaction
		BeginTransaction(DataLockControlMode.Managed);
		
		// Create WEB-services proxy
		vAleanCRSServerDefinition = New WSDefinitions(TrimR(InventoryServicesWSDLHost));
		vAleanCRSServerProxy = New WSProxy(vAleanCRSServerDefinition, "urn:webservice-electrasoft-ru", "ItwsHotelAdapterInventory3service", "ItwsHotelAdapterInventory3Port");
		
		// Build XML
		vTempFileName = GetTempFileName("xml");
		vXMLWriter = New XMLWriter();
		vXMLWriterSettings = New XMLWriterSettings("UTF-16", "1.0", True, False);
		vXMLWriter.OpenFile(vTempFileName, vXMLWriterSettings);
		vXMLWriter.WriteXMLDeclaration();
		vXMLWriter.WriteStartElement("TariffList");  //Start TariffList
		vXMLWriter.WriteNamespaceMapping("xsd", "http://www.w3.org/2001/XMLSchema");
		vXMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
		vXMLWriter.WriteNamespaceMapping("", "urn:schemas-som-ru:tws-HotelAdapterTariffList.v3");
		vXMLWriter.WriteAttribute("InventoryType", ?(pFull, "FULL", "CHANGED"));
		vXMLWriter.WriteAttribute("CurrencyISOCode", "RUB");
		
		vExistPeriodTo = Date(1, 1, 1);
		
		// Add room rate prices to xml
		AddRoomRatePricesToXML(vXMLWriter, pFull, vExistPeriodTo);
		
		vSaveSyncTable = ValueIsFilled(vExistPeriodTo);
		
		// Add service package prices to xml
		If pFull Then
			AddPricesAdditionalServicesToXML(vXMLWriter, vExistPeriodTo);
		EndIf;
		
		vXMLWriter.WriteEndElement(); // End TariffList
		
		vXMLWriter.Close();
		
		vTextFile = New TextReader(vTempFileName, "UTF-16");
		vPricesDataXML = vTextFile.Read();
		vTextFile.Close();
		
		DeleteFiles(vTempFileName);
		
		// Write to events log in debug mode
		If ExternalInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronizeRoomRatePrices.BeforeSend", Enums.ExternalSystemEventTypes.Warning, ,vPricesDataXML, "XML", 99999999);
		EndIf;
		
		vMessage = "";
		If ValueIsFilled(vExistPeriodTo) Then
			// Call WEB-service
			vAleanCRSServerProxy.SynchronizeTariff(TrimR(ExternalInteraction.SessionID), TrimR(ExternalInteraction.InteractionID), vPricesDataXML,"");
			
			// Write to events log in debug mode
			If ExternalInteraction.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronizeRoomRatePrices.AfterSend", Enums.ExternalSystemEventTypes.Success, , , "Call to Synchronize prices completed...");
			EndIf;
			
			// Update interaction 
			vExternalInteractionObj = ExternalInteraction.GetObject();
			vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
			vExternalInteractionObj.ErrorDescription = NStr("en = 'Save downloaded prices'; de = 'Heruntergeladene Preise speichern'; ru = 'Сохраняем выгруженные цены'");
			vExternalInteractionObj.Write();     
			
			// Save copy of room rates prices to the channel managers prices table
			If vSaveSyncTable Then
				SaveSyncTable(pFull, vExistPeriodTo);
			EndIf;
		Else
			If pFull Then
				vMessage = NStr("en = 'No price to sync'; de = 'No price to sync'; ru = 'Нет цен для синхронизации'");
			Else
				vMessage = NStr("en = 'No price changes to sync'; de = 'No price changes to sync'; ru = 'Нет изменений в ценах для синхронизации'");
			EndIf;
			If ExternalInteraction.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronizeRoomRatePrices.Result", Enums.ExternalSystemEventTypes.Warning, , , vMessage);
			EndIf;
		EndIf;
		
		// Update interaction state
		vExternalInteractionObj = ExternalInteraction.GetObject();
		vExternalInteractionObj.pmUpdateSessionAttributes(pFull);
		vExternalInteractionObj.LastExportTimestampForPrices = pLastSyncDate;
		vExternalInteractionObj.LastExportTimestampForRestrictions = pLastSyncDate;
		vExternalInteractionObj.Status = Enums.IntegrationStatuses.Success;
		vExternalInteractionObj.ErrorDescription = "";
		vExternalInteractionObj.Write();
		
		// Commit transaction and release locks 
		If TransactionActive() Then
			CommitTransaction();
		EndIf;
		
		// Log current state
		If IsBlankString(vMessage) Then
			If pFull Then
				vMessage = NStr("en='Full synchronization is done for ';ru='Выполнена полная синхронизация цен по настройке ';de='Eine vollständige Synchronisation nach Einstellung wurde durchgeführt '") + TrimAll(ExternalInteraction);
			Else
				vMessage = NStr("en='Changes are synchronized for for ';ru='Выполнена синхронизация изменений цен по настройке ';de='Die Synchronisation von Änderungen nach Einstellung wurde durchgeführt '") + TrimAll(ExternalInteraction);
			EndIf;
		EndIf;
		// Write to events log in debug mode
		If ExternalInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronizeRoomRatePrices.Result", Enums.ExternalSystemEventTypes.Success, , , vMessage);
		EndIf;
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
		EndIf;
	Except
		// Get error description first
		vErrDescription = ErrorDescription();
		// Rollback transaction and release locks 
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		// Build error message
		vMessage = NStr("en='Prices synchronization error!';ru='Ошибка синхронизации цен!';de='Preise Synchronisierungsfehler!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronizeRoomRatePrices", Enums.ExternalSystemEventTypes.Error, vPricesDataXML, vErrDescription, vMessage, 99999999);
		
		// Exit
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
		EndIf;
		// Save error to the interaction object
		vExternalInteractionObj = ExternalInteraction.GetObject();
		vExternalInteractionObj.Status = Enums.IntegrationStatuses.Error;
		vExternalInteractionObj.ErrorDescription = vMessage;
		vExternalInteractionObj.Write();
	EndTry;
	If ExternalInteraction.DebugMode Then
		vMessage = NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronizeRoomRatePrices.End", Enums.ExternalSystemEventTypes.Warning, , , vMessage);
	EndIf;
EndProcedure // pmSynchronizeRoomRatePrices

// -----------------------------------------------------------------------------
Procedure pmSynchronize(pIsInteractive = False, pFull = False, pLastSyncDate = '00010101') Export
	If ExternalInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'")+ Chars.LF + "IsInteractive: " + pIsInteractive + Chars.LF + "IsFull: " + pFull;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronize.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
	EndIf;
	vInventoryDataXML = ""; 
	// Update interaction info
	vExternalInteractionObj = ExternalInteraction.GetObject();
	vExternalInteractionObj.Status = Enums.IntegrationStatuses.Warning;
	vExternalInteractionObj.ErrorDescription = NStr("en = 'Unloading balances'; de = 'Entladen von Waagen'; ru = 'Выгрузка остатков'");
	vExternalInteractionObj.Write();

	Try
		// Build list of allotments to get balances from
		vGetRoomInventoryBalances = False;
		vGetAllotmentBalances = False;
		vAllotmentsList = New ValueList();
		If ValueIsFilled(ExternalInteraction.Allotment) Then
			vGetAllotmentBalances = True;
			vAllotments = cmGetAllRoomQuotas(ExternalInteraction.Allotment);
			For Each vAllotmentsRow In vAllotments Do
				vAllotmentsList.Add(vAllotmentsRow.RoomQuota);
			EndDo;				
		Else
			vGetRoomInventoryBalances = True;
		EndIf;
		
		// Create WEB-services proxy
		vAleanCRSServerInventoryDefinition = New WSDefinitions(TrimR(InventoryServicesWSDLHost));
		vAleanCRSServerInventoryProxy = New WSProxy(vAleanCRSServerInventoryDefinition, "urn:webservice-electrasoft-ru", "ItwsHotelAdapterInventory3service", "ItwsHotelAdapterInventory3Port");
		
		// Build XML with balances
		vTempFileName = GetTempFileName("xml");
		vXMLWriter = New XMLWriter();
		vXMLWriter.OpenFile(vTempFileName, "UTF-8");
		vXMLWriter.WriteStartElement("Inventory");
		vXMLWriter.WriteNamespaceMapping("", "urn:schemas-som-ru:tws-HotelAdapterInventory.v3");
		
		If ExternalInteraction.IsByCheckInPeriods Then
			vXMLWriter.WriteAttribute("InventoryType", "VISITTIMETABLE");
			// Run query to get balances by dates
			If ExternalInteraction.IsByAllotments Then
				vPeriodsBalances = GetCheckInPeriodsBalancesByAllotments(vGetRoomInventoryBalances, vGetAllotmentBalances, vAllotmentsList);
				// Fill XML with check-in periods
				FillCheckInPeriodsByAllotmentsXML(vPeriodsBalances, vXMLWriter);
			Else
				vPeriodsBalances = GetCheckInPeriodsBalances(vGetRoomInventoryBalances, vGetAllotmentBalances, vAllotmentsList);
				// Fill XML with check-in periods
				FillCheckInPeriodsXML(vPeriodsBalances, vXMLWriter);
			EndIf;
			vFullBalances = vPeriodsBalances;
		Else
			vXMLWriter.WriteAttribute("InventoryType", ?(pFull, "FULL", "CHANGED"));
			// Run query to get balances by dates
			vFullBalances = Undefined;
			vDailyBalances = GetDailyBalances(pFull, vGetRoomInventoryBalances, vGetAllotmentBalances, vAllotmentsList, vFullBalances);
			// Fill XML with daily balances
			FillDailyBalancesXML(vDailyBalances, vXMLWriter);
		EndIf;
		
		vXMLWriter.Close();
		
		vTextFile = New TextReader(vTempFileName, "UTF-8");
		vInventoryDataXML = vTextFile.Read();
		vTextFile.Close();
		
		DeleteFiles(vTempFileName);
		
		// Write to events log in debug mode
		If ExternalInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronize.BeforeSend", Enums.ExternalSystemEventTypes.Warning, ,vInventoryDataXML, "XML", 99999999);
		EndIf;
		
		// Call WEB-service
		vAleanCRSServerInventoryProxy.SynchronizeInventory(TrimR(ExternalInteraction.SessionID), TrimR(ExternalInteraction.InteractionID), vInventoryDataXML, "");
		
		// Write to events log in debug mode
		If ExternalInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronize.AfterSend", Enums.ExternalSystemEventTypes.Success, , , "Call to Synchronize() completed...");
		EndIf;
	
		// Log current state
		vMessage = "";
		If pFull Then
			vMessage = NStr("en='Full synchronization is done for ';ru='Выполнена полная синхронизация остатков по настройке ';de='Eine vollständige Synchronisation nach Einstellung wurde durchgeführt '") + TrimAll(ExternalInteraction);
		Else
			vMessage = NStr("en='Changes are synchronized for for ';ru='Выполнена синхронизация изменений остатков по настройке ';de='Die Synchronisation von Änderungen nach Einstellung wurde durchgeführt '") + TrimAll(ExternalInteraction);
		EndIf;
		If ExternalInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronize.Result", Enums.ExternalSystemEventTypes.Warning, , , vMessage);
		EndIf;
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
		EndIf;   
		
		// Update interaction state
		vExternalInteractionObj = ExternalInteraction.GetObject();
		vExternalInteractionObj.pmUpdateSessionAttributes(pFull); 
		vExternalInteractionObj.LastExportTimestampForInventory = pLastSyncDate;
		vExternalInteractionObj.Status = Enums.IntegrationStatuses.Success;
		vExternalInteractionObj.ErrorDescription = "";
		vExternalInteractionObj.Write();
	Except
		// Get error description first
		vErrDescription = ErrorDescription();
		
		// Build error message
		vMessage = NStr("en='Synchronization error!';ru='Ошибка синхронизации!';de='Synchronisationsfehler!'");
		
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronize.Except", Enums.ExternalSystemEventTypes.Error, vInventoryDataXML, vErrDescription, vMessage, 99999999);

		// Exit
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
		EndIf;
		// Save error to the interaction object
		vExternalInteractionObj = ExternalInteraction.GetObject();
		vExternalInteractionObj.Status = Enums.IntegrationStatuses.Error;
		vExternalInteractionObj.ErrorDescription = vMessage;
		vExternalInteractionObj.Write();
	EndTry;
	
	If ExternalInteraction.DebugMode Then
		vMessage =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "pmSynchronize.End", Enums.ExternalSystemEventTypes.Warning, , , vMessage);
	EndIf;
EndProcedure // pmSynchronize

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetCheckInPeriodsBalances(pGetRoomInventoryBalances, pGetAllotmentBalances, pAllotmentsList)
	vPeriodFrom = CurrentDate();	
	vPeriodTo = EndOfDay(ExternalInteraction.ActiveToDate);

	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CheckInPeriods.Hotel AS Hotel,
	|	CheckInPeriods.RoomQuota AS RoomQuota,
	|	BEGINOFPERIOD(CheckInPeriods.CheckInDate, DAY) AS CheckInDate,
	|	CheckInPeriods.Duration AS Duration,
	|	BEGINOFPERIOD(CheckInPeriods.CheckOutDate, DAY) AS CheckOutDate,
	|	BEGINOFPERIOD(CheckInPeriods.CheckInDate, DAY) AS Period
	|INTO CheckInPeriods
	|FROM
	|	InformationRegister.RoomQuotaCheckInPeriods AS CheckInPeriods
	|WHERE
	|	NOT CheckInPeriods.IsNotActive
	|	AND CheckInPeriods.Hotel = &qHotel
	|	AND (&qGetAllotmentBalances
	|				AND CheckInPeriods.RoomQuota IN (&qAllotmentsList)
	|			OR &qGetRoomInventoryBalances
	|				AND CheckInPeriods.RoomQuota = &qEmptyRoomQuota)
	|	AND CheckInPeriods.CheckInDate >= &qPeriodFrom
	|	AND CheckInPeriods.CheckInDate < &qPeriodTo
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodBalances.Hotel AS Hotel,
	|	PeriodBalances.RoomType AS RoomType,
	|	PeriodBalances.CheckInDate AS CheckInDate,
	|	PeriodBalances.Duration AS Duration,
	|	PeriodBalances.CheckOutDate AS CheckOutDate,
	|	SUM(PeriodBalances.RoomsVacant) AS RoomsVacant,
	|	SUM(PeriodBalances.BedsVacant) AS BedsVacant,
	|	PeriodBalances.Period AS Period
	|FROM
	|	(SELECT
	|		VisitPeriods.Hotel AS Hotel,
	|		Balances.RoomType AS RoomType,
	|		VisitPeriods.RoomQuota AS RoomQuota,
	|		VisitPeriods.CheckInDate AS CheckInDate,
	|		VisitPeriods.Duration AS Duration,
	|		VisitPeriods.CheckOutDate AS CheckOutDate,
	|		MIN(Balances.RoomsVacant) AS RoomsVacant,
	|		MIN(Balances.BedsVacant) AS BedsVacant,
	|		VisitPeriods.Period AS Period
	|	FROM
	|		CheckInPeriods AS VisitPeriods
	|			LEFT JOIN (SELECT
	|				RoomQuotas.Hotel AS Hotel,
	|				RoomQuotas.RoomQuota AS RoomQuota,
	|				RoomQuotas.RoomType AS RoomType,
	|				RoomQuotas.Period AS Period,
	|				SUM(RoomQuotas.RoomsVacant) AS RoomsVacant,
	|				SUM(RoomQuotas.BedsVacant) AS BedsVacant
	|			FROM
	|				(SELECT
	|					RoomTypes.Owner AS Hotel,
	|					RoomTypes.Ref AS RoomType,
	|					&qEmptyRoomQuota AS RoomQuota,
	|					BEGINOFPERIOD(RoomInventory.Period, DAY) AS Period,
	|					ISNULL(RoomInventory.RoomsVacant, 0) AS RoomsVacant,
	|					ISNULL(RoomInventory.BedsVacant, 0) AS BedsVacant
	|				FROM
	|					Catalog.RoomTypes AS RoomTypes
	|						LEFT JOIN (SELECT
	|							RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
	|							RoomInventoryBalanceAndTurnovers.Period AS Period,
	|							RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|							RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance AS RoomsVacant,
	|							RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance AS BedsVacant
	|						FROM
	|							AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|									&qPeriodFrom,
	|									&qPeriodTo,
	|									Day,
	|									RegisterRecordsAndPeriodBoundaries,
	|									&qGetRoomInventoryBalances
	|										AND Hotel = &qHotel) AS RoomInventoryBalanceAndTurnovers) AS RoomInventory
	|						ON (RoomInventory.RoomType = RoomTypes.Ref)
	|				WHERE
	|					&qGetRoomInventoryBalances
	|					AND NOT RoomTypes.DeletionMark
	|					AND NOT RoomTypes.IsFolder
	|					AND NOT RoomTypes.IsVirtual
	|				
	|				UNION ALL
	|				
	|				SELECT
	|					RoomTypes.Owner,
	|					RoomTypes.Ref,
	|					RoomQuotaSales.RoomQuota,
	|					BEGINOFPERIOD(RoomQuotaSales.Period, DAY),
	|					ISNULL(RoomQuotaSales.RoomsRemains, 0),
	|					ISNULL(RoomQuotaSales.BedsRemains, 0)
	|				FROM
	|					Catalog.RoomTypes AS RoomTypes
	|						LEFT JOIN (SELECT
	|							RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
	|							RoomQuotaSalesBalanceAndTurnovers.RoomQuota AS RoomQuota,
	|							RoomQuotaSalesBalanceAndTurnovers.Period AS Period,
	|							RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|							RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
	|							RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains
	|						FROM
	|							AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|									&qPeriodFrom,
	|									&qPeriodTo,
	|									Day,
	|									RegisterRecordsAndPeriodBoundaries,
	|									&qGetAllotmentBalances
	|										AND Hotel = &qHotel
	|										AND RoomQuota IN (&qAllotmentsList)) AS RoomQuotaSalesBalanceAndTurnovers) AS RoomQuotaSales
	|						ON (RoomQuotaSales.RoomType = RoomTypes.Ref)
	|				WHERE
	|					&qGetAllotmentBalances
	|					AND NOT RoomTypes.DeletionMark
	|					AND NOT RoomTypes.IsFolder
	|					AND NOT RoomTypes.IsVirtual) AS RoomQuotas
	|			
	|			GROUP BY
	|				RoomQuotas.Hotel,
	|				RoomQuotas.RoomType,
	|				RoomQuotas.RoomQuota,
	|				RoomQuotas.Period) AS Balances
	|			ON VisitPeriods.Hotel = Balances.Hotel
	|				AND VisitPeriods.RoomQuota = Balances.RoomQuota
	|				AND (Balances.Period >= VisitPeriods.CheckInDate)
	|				AND (Balances.Period < VisitPeriods.CheckOutDate)
	|	
	|	GROUP BY
	|		VisitPeriods.Hotel,
	|		Balances.RoomType,
	|		VisitPeriods.RoomQuota,
	|		VisitPeriods.CheckInDate,
	|		VisitPeriods.Duration,
	|		VisitPeriods.CheckOutDate,
	|		VisitPeriods.Period) AS PeriodBalances
	|
	|GROUP BY
	|	PeriodBalances.Hotel,
	|	PeriodBalances.RoomType,
	|	PeriodBalances.CheckInDate,
	|	PeriodBalances.Duration,
	|	PeriodBalances.CheckOutDate,
	|	PeriodBalances.Period
	|
	|ORDER BY
	|	PeriodBalances.Hotel.SortCode,
	|	PeriodBalances.Hotel.Description,
	|	PeriodBalances.RoomType.SortCode,
	|	PeriodBalances.RoomType.Description,
	|	PeriodBalances.CheckInDate,
	|	PeriodBalances.Duration";
	vQry.SetParameter("qHotel", ExternalInteraction.Hotel);
	vQry.SetParameter("qGetRoomInventoryBalances", pGetRoomInventoryBalances);
	vQry.SetParameter("qGetAllotmentBalances", pGetAllotmentBalances);
	vQry.SetParameter("qAllotmentsList", pAllotmentsList);
	vQry.SetParameter("qPeriodFrom", BegOfDay(vPeriodFrom));
	vQry.SetParameter("qPeriodTo", vPeriodTo);
	vQry.SetParameter("qEmptyRoomQuota", Catalogs.RoomQuotas.EmptyRef());
	// Run query
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // GetCheckInPeriodsBalances

// -----------------------------------------------------------------------------
Function GetCheckInPeriodsBalancesByAllotments(pGetRoomInventoryBalances, pGetAllotmentBalances, pAllotmentsList)
	vPeriodFrom = CurrentDate();	
	vPeriodTo = EndOfDay(ExternalInteraction.ActiveToDate);
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CheckInPeriods.Hotel AS Hotel,
	|	CheckInPeriods.RoomQuota AS RoomQuota,
	|	BEGINOFPERIOD(CheckInPeriods.CheckInDate, DAY) AS CheckInDate,
	|	CheckInPeriods.Duration AS Duration,
	|	BEGINOFPERIOD(CheckInPeriods.CheckOutDate, DAY) AS CheckOutDate,
	|	BEGINOFPERIOD(CheckInPeriods.CheckInDate, DAY) AS Period
	|INTO CheckInPeriods
	|FROM
	|	InformationRegister.RoomQuotaCheckInPeriods AS CheckInPeriods
	|WHERE
	|	NOT CheckInPeriods.IsNotActive
	|	AND CheckInPeriods.Hotel = &qHotel
	|	AND (&qGetAllotmentBalances
	|				AND CheckInPeriods.RoomQuota IN (&qAllotmentsList)
	|			OR &qGetRoomInventoryBalances
	|				AND CheckInPeriods.RoomQuota = &qEmptyRoomQuota)
	|	AND CheckInPeriods.CheckInDate >= &qPeriodFrom
	|	AND CheckInPeriods.CheckInDate < &qPeriodTo
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodBalances.Hotel AS Hotel,
	|	PeriodBalances.RoomType AS RoomType,
	|	PeriodBalances.RoomQuota AS RoomQuota,
	|	PeriodBalances.RoomQuota.Code AS RoomQuotaCode,
	|	PeriodBalances.CheckInDate AS CheckInDate,
	|	PeriodBalances.Duration AS Duration,
	|	PeriodBalances.CheckOutDate AS CheckOutDate,
	|	SUM(PeriodBalances.RoomsVacant) AS RoomsVacant,
	|	SUM(PeriodBalances.BedsVacant) AS BedsVacant,
	|	PeriodBalances.Period AS Period
	|FROM
	|	(SELECT
	|		VisitPeriods.Hotel AS Hotel,
	|		Balances.RoomType AS RoomType,
	|		VisitPeriods.RoomQuota AS RoomQuota,
	|		VisitPeriods.CheckInDate AS CheckInDate,
	|		VisitPeriods.Duration AS Duration,
	|		VisitPeriods.CheckOutDate AS CheckOutDate,
	|		MIN(Balances.RoomsVacant) AS RoomsVacant,
	|		MIN(Balances.BedsVacant) AS BedsVacant,
	|		VisitPeriods.Period AS Period
	|	FROM
	|		CheckInPeriods AS VisitPeriods
	|			LEFT JOIN (SELECT
	|				RoomQuotas.Hotel AS Hotel,
	|				RoomQuotas.RoomQuota AS RoomQuota,
	|				RoomQuotas.RoomType AS RoomType,
	|				RoomQuotas.Period AS Period,
	|				SUM(RoomQuotas.RoomsVacant) AS RoomsVacant,
	|				SUM(RoomQuotas.BedsVacant) AS BedsVacant
	|			FROM
	|				(SELECT
	|					RoomTypes.Owner AS Hotel,
	|					RoomTypes.Ref AS RoomType,
	|					&qEmptyRoomQuota AS RoomQuota,
	|					BEGINOFPERIOD(RoomInventory.Period, DAY) AS Period,
	|					ISNULL(RoomInventory.RoomsVacant, 0) AS RoomsVacant,
	|					ISNULL(RoomInventory.BedsVacant, 0) AS BedsVacant
	|				FROM
	|					Catalog.RoomTypes AS RoomTypes
	|						LEFT JOIN (SELECT
	|							RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
	|							RoomInventoryBalanceAndTurnovers.Period AS Period,
	|							RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|							RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance AS RoomsVacant,
	|							RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance AS BedsVacant
	|						FROM
	|							AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|									&qPeriodFrom,
	|									&qPeriodTo,
	|									Day,
	|									RegisterRecordsAndPeriodBoundaries,
	|									&qGetRoomInventoryBalances
	|										AND Hotel = &qHotel) AS RoomInventoryBalanceAndTurnovers) AS RoomInventory
	|						ON (RoomInventory.RoomType = RoomTypes.Ref)
	|				WHERE
	|					&qGetRoomInventoryBalances
	|					AND NOT RoomTypes.DeletionMark
	|					AND NOT RoomTypes.IsFolder
	|					AND NOT RoomTypes.IsVirtual
	|				
	|				UNION ALL
	|				
	|				SELECT
	|					RoomTypes.Owner,
	|					RoomTypes.Ref,
	|					RoomQuotaSales.RoomQuota,
	|					BEGINOFPERIOD(RoomQuotaSales.Period, DAY),
	|					ISNULL(RoomQuotaSales.RoomsRemains, 0),
	|					ISNULL(RoomQuotaSales.BedsRemains, 0)
	|				FROM
	|					Catalog.RoomTypes AS RoomTypes
	|						LEFT JOIN (SELECT
	|							RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
	|							RoomQuotaSalesBalanceAndTurnovers.RoomQuota AS RoomQuota,
	|							RoomQuotaSalesBalanceAndTurnovers.Period AS Period,
	|							RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|							RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
	|							RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains
	|						FROM
	|							AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|									&qPeriodFrom,
	|									&qPeriodTo,
	|									Day,
	|									RegisterRecordsAndPeriodBoundaries,
	|									&qGetAllotmentBalances
	|										AND Hotel = &qHotel
	|										AND RoomQuota IN (&qAllotmentsList)) AS RoomQuotaSalesBalanceAndTurnovers) AS RoomQuotaSales
	|						ON (RoomQuotaSales.RoomType = RoomTypes.Ref)
	|				WHERE
	|					&qGetAllotmentBalances
	|					AND NOT RoomTypes.DeletionMark
	|					AND NOT RoomTypes.IsFolder
	|					AND NOT RoomTypes.IsVirtual) AS RoomQuotas
	|			
	|			GROUP BY
	|				RoomQuotas.Hotel,
	|				RoomQuotas.RoomType,
	|				RoomQuotas.RoomQuota,
	|				RoomQuotas.Period) AS Balances
	|			ON VisitPeriods.Hotel = Balances.Hotel
	|				AND VisitPeriods.RoomQuota = Balances.RoomQuota
	|				AND (Balances.Period >= VisitPeriods.CheckInDate)
	|				AND (Balances.Period < VisitPeriods.CheckOutDate)
	|	
	|	GROUP BY
	|		VisitPeriods.Hotel,
	|		Balances.RoomType,
	|		VisitPeriods.RoomQuota,
	|		VisitPeriods.CheckInDate,
	|		VisitPeriods.Duration,
	|		VisitPeriods.CheckOutDate,
	|		VisitPeriods.Period) AS PeriodBalances
	|
	|GROUP BY
	|	PeriodBalances.Hotel,
	|	PeriodBalances.RoomType,
	|	PeriodBalances.RoomQuota,
	|	PeriodBalances.RoomQuota.Code,
	|	PeriodBalances.CheckInDate,
	|	PeriodBalances.Duration,
	|	PeriodBalances.CheckOutDate,
	|	PeriodBalances.Period
	|
	|ORDER BY
	|	PeriodBalances.Hotel.SortCode,
	|	PeriodBalances.Hotel.Description,
	|	PeriodBalances.RoomType.SortCode,
	|	PeriodBalances.RoomType.Description,
	|	PeriodBalances.RoomQuota.SortCode,
	|	PeriodBalances.RoomQuota.Code,
	|	PeriodBalances.CheckInDate,
	|	PeriodBalances.Duration";
	vQry.SetParameter("qHotel", ExternalInteraction.Hotel);
	vQry.SetParameter("qGetRoomInventoryBalances", pGetRoomInventoryBalances);
	vQry.SetParameter("qGetAllotmentBalances", pGetAllotmentBalances);
	vQry.SetParameter("qAllotmentsList", pAllotmentsList);
	vQry.SetParameter("qPeriodFrom", BegOfDay(vPeriodFrom));
	vQry.SetParameter("qPeriodTo", vPeriodTo);
	vQry.SetParameter("qEmptyRoomQuota", Catalogs.RoomQuotas.EmptyRef());
	// Run query
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // GetCheckInPeriodsBalancesByAllotments

// -----------------------------------------------------------------------------
Function GetDailyBalances(pFull, pGetRoomInventoryBalances, pGetAllotmentBalances, pAllotmentsList, rBalances)
	// Fill sync period
	vPeriodFrom = CurrentDate();	
	vPeriodTo = EndOfDay(ExternalInteraction.ActiveToDate);
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Balances.Hotel AS Hotel,
	|	Balances.RoomType AS RoomType,
	|	Balances.Period AS Period,
	|	SUM(Balances.RoomsVacant) AS RoomsVacant,
	|	SUM(Balances.BedsVacant) AS BedsVacant
	|FROM
	|	(SELECT
	|		RoomQuotas.Hotel AS Hotel,
	|		RoomQuotas.RoomQuota AS RoomQuota,
	|		RoomQuotas.RoomType AS RoomType,
	|		RoomQuotas.Period AS Period,
	|		CASE
	|			WHEN RoomQuotas.RoomQuota = &qEmptyRoomQuota
	|				THEN RoomQuotas.RoomsVacant
	|			ELSE RoomQuotas.RoomsRemains
	|		END AS RoomsVacant,
	|		CASE
	|			WHEN RoomQuotas.RoomQuota = &qEmptyRoomQuota
	|				THEN RoomQuotas.BedsVacant
	|			ELSE RoomQuotas.BedsRemains
	|		END AS BedsVacant
	|	FROM
	|		(SELECT
	|			RoomTypes.Owner AS Hotel,
	|			RoomTypes.Ref AS RoomType,
	|			&qEmptyRoomQuota AS RoomQuota,
	|			RoomInventory.Period AS Period,
	|			ISNULL(RoomInventory.RoomsVacant, 0) AS RoomsVacant,
	|			ISNULL(RoomInventory.BedsVacant, 0) AS BedsVacant,
	|			0 AS RoomsRemains,
	|			0 AS BedsRemains
	|		FROM
	|			Catalog.RoomTypes AS RoomTypes
	|				LEFT JOIN (SELECT
	|					RoomInventoryBalanceAndTurnovers.RoomType AS RoomType,
	|					RoomInventoryBalanceAndTurnovers.Period AS Period,
	|					RoomInventoryBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|					RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance AS RoomsVacant,
	|					RoomInventoryBalanceAndTurnovers.BedsVacantClosingBalance AS BedsVacant
	|				FROM
	|					AccumulationRegister.RoomInventory.BalanceAndTurnovers(
	|							&qPeriodFrom,
	|							&qPeriodTo,
	|							Day,
	|							RegisterRecordsAndPeriodBoundaries,
	|							&qGetRoomInventoryBalances
	|								AND Hotel = &qHotel) AS RoomInventoryBalanceAndTurnovers) AS RoomInventory
	|				ON (RoomInventory.RoomType = RoomTypes.Ref)
	|		WHERE
	|			&qGetRoomInventoryBalances
	|			AND NOT RoomTypes.DeletionMark
	|			AND NOT RoomTypes.IsFolder
	|			AND NOT RoomTypes.IsVirtual
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			RoomTypes.Owner,
	|			RoomTypes.Ref,
	|			RoomQuotaSales.RoomQuota,
	|			RoomQuotaSales.Period,
	|			0,
	|			0,
	|			ISNULL(RoomQuotaSales.RoomsRemains, 0),
	|			ISNULL(RoomQuotaSales.BedsRemains, 0)
	|		FROM
	|			Catalog.RoomTypes AS RoomTypes
	|				LEFT JOIN (SELECT
	|					RoomQuotaSalesBalanceAndTurnovers.RoomType AS RoomType,
	|					RoomQuotaSalesBalanceAndTurnovers.RoomQuota AS RoomQuota,
	|					RoomQuotaSalesBalanceAndTurnovers.Period AS Period,
	|					RoomQuotaSalesBalanceAndTurnovers.CounterClosingBalance AS CounterClosingBalance,
	|					RoomQuotaSalesBalanceAndTurnovers.RoomsRemainsClosingBalance AS RoomsRemains,
	|					RoomQuotaSalesBalanceAndTurnovers.BedsRemainsClosingBalance AS BedsRemains
	|				FROM
	|					AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(
	|							&qPeriodFrom,
	|							&qPeriodTo,
	|							Day,
	|							RegisterRecordsAndPeriodBoundaries,
	|							&qGetAllotmentBalances
	|								AND Hotel = &qHotel
	|								AND RoomQuota IN (&qAllotmentsList)) AS RoomQuotaSalesBalanceAndTurnovers) AS RoomQuotaSales
	|				ON (RoomQuotaSales.RoomType = RoomTypes.Ref)
	|		WHERE
	|			&qGetAllotmentBalances
	|			AND NOT RoomTypes.DeletionMark
	|			AND NOT RoomTypes.IsFolder
	|			AND NOT RoomTypes.IsVirtual) AS RoomQuotas) AS Balances
	|WHERE
	|	Balances.Period <> DATETIME(1, 1, 1)
	|
	|GROUP BY
	|	Balances.Hotel,
	|	Balances.RoomType,
	|	Balances.Period
	|
	|ORDER BY
	|	Balances.Hotel.SortCode,
	|	Balances.Hotel.Description,
	|	Balances.RoomType.SortCode,
	|	Balances.RoomType.Description,
	|	Period";
	vQry.SetParameter("qPeriod", CurrentSessionDate());
	vQry.SetParameter("qChannelManager", ExternalInteraction);
	vQry.SetParameter("qHotel", ExternalInteraction.Hotel);
	vQry.SetParameter("qGetRoomInventoryBalances", pGetRoomInventoryBalances);
	vQry.SetParameter("qGetAllotmentBalances", pGetAllotmentBalances);
	vQry.SetParameter("qAllotmentsList", pAllotmentsList);
	vQry.SetParameter("qPeriodFrom", BegOfDay(vPeriodFrom));
	vQry.SetParameter("qPeriodTo", vPeriodTo);
	vQry.SetParameter("qEmptyRoomQuota", Catalogs.RoomQuotas.EmptyRef());
	rBalances = vQry.Execute().Unload();
	If Not pFull Then
		vChangedBalances = ChannelManagers.GetRoomInventoryChanges(rBalances, ExternalInteraction, ExternalInteraction.Hotel, pAllotmentsList, Undefined, vPeriodFrom, vPeriodTo);
		Return vChangedBalances;
	Else
		Return rBalances;
	EndIf;
EndFunction // GetDailyBalances

// -----------------------------------------------------------------------------
Procedure FillCheckInPeriodsXML(pCheckInPeriods, pXMLWriter)
	vCurRoomType = Undefined;
	vSkipRoomType = False;
	For Each vBalancesRow In pCheckInPeriods Do
		If vCurRoomType <> vBalancesRow.RoomType Then
			If vCurRoomType <> Undefined And Not vSkipRoomType Then
				pXMLWriter.WriteEndElement();
			EndIf;
			vCurRoomType = vBalancesRow.RoomType;
			
			// Get room type external names
			vRoomCategoryShortName = "";
			vRoomTypeShortName = "";
			vRoomCategoryExtCodes = cmGetObjectExternalSystemCodeByRef(ExternalInteraction.Hotel, TrimR(ExternalInteraction.InteractionID), "RoomTypes", vCurRoomType, True);
			If IsBlankString(vRoomCategoryExtCodes) Then
				vSkipRoomType = True;
				Continue;
			Else
				vSkipRoomType = False;
			EndIf;
			
			// Try to split names to room type short name and room category short name
			vSlashPos = Find(vRoomCategoryExtCodes, "/");
			If vSlashPos > 1 Then
				vRoomCategoryShortName = Left(vRoomCategoryExtCodes, vSlashPos - 1);
				vRoomTypeShortName = Mid(vRoomCategoryExtCodes, vSlashPos + 1);
			Else
				vRoomCategoryShortName = TrimR(vRoomCategoryExtCodes);
			EndIf;
			
			// Build room category XDTO object
			pXMLWriter.WriteStartElement("RoomCategory");
			pXMLWriter.WriteAttribute("RoomCategoryCID", vRoomCategoryShortName);
		EndIf;
		If vSkipRoomType Then
			Continue;
		EndIf;
		
		// Check stop sale
		If vCurRoomType.StopSale Then
			vRemarks = "";
			If cmIsStopInternetSalePeriod(vCurRoomType, vBalancesRow.CheckInDate, vBalancesRow.CheckOutDate, vRemarks) Then
				vBalancesRow.RoomsVacant = 0;
			EndIf;
		EndIf;
		
		pXMLWriter.WriteStartElement("VisitTimeTableInventory");
		pXMLWriter.WriteAttribute("Date", Format(vBalancesRow.CheckInDate, "DF=yyyy-MM-dd"));
		pXMLWriter.WriteAttribute("Duration", Format(vBalancesRow.Duration, "ND=6; NFD=0; NZ=; NG="));
		pXMLWriter.WriteAttribute("Quantity", Format(?(vBalancesRow.RoomsVacant < 0, 0, vBalancesRow.RoomsVacant), "ND=10; NFD=0; NZ=; NG="));
		pXMLWriter.WriteEndElement();
	EndDo;
	If vCurRoomType <> Undefined And Not vSkipRoomType Then
		pXMLWriter.WriteEndElement();
	EndIf;
	pXMLWriter.WriteEndElement();
EndProcedure // FillCheckInPeriodsXML

// -----------------------------------------------------------------------------
Procedure FillCheckInPeriodsByAllotmentsXML(pCheckInPeriods, pXMLWriter)
	vCurRoomType = Undefined;
	vSkipRoomType = False;
	For Each vBalancesRow In pCheckInPeriods Do
		If vCurRoomType <> vBalancesRow.RoomType Then
			If vCurRoomType <> Undefined And Not vSkipRoomType Then
				pXMLWriter.WriteEndElement();
			EndIf;
			vCurRoomType = vBalancesRow.RoomType;
			
			// Get room type external names
			vRoomCategoryShortName = "";
			vRoomTypeShortName = "";
			vRoomCategoryExtCodes = cmGetObjectExternalSystemCodeByRef(ExternalInteraction.Hotel, TrimR(ExternalInteraction.InteractionID), "RoomTypes", vCurRoomType, True);
			If IsBlankString(vRoomCategoryExtCodes) Then
				vSkipRoomType = True;
				Continue;
			Else
				vSkipRoomType = False;
			EndIf;
			
			// Try to split names to room type short name and room category short name
			vSlashPos = Find(vRoomCategoryExtCodes, "/");
			If vSlashPos > 1 Then
				vRoomCategoryShortName = Left(vRoomCategoryExtCodes, vSlashPos - 1);
				vRoomTypeShortName = Mid(vRoomCategoryExtCodes, vSlashPos + 1);
			Else
				vRoomCategoryShortName = TrimR(vRoomCategoryExtCodes);
			EndIf;
			
			// Build room category XDTO object
			pXMLWriter.WriteStartElement("RoomCategory");
			pXMLWriter.WriteAttribute("RoomCategoryCID", vRoomCategoryShortName);
		EndIf;
		If vSkipRoomType Then
			Continue;
		EndIf;
		
		// Check stop sale
		If vCurRoomType.StopSale Then
			vRemarks = "";
			If cmIsStopInternetSalePeriod(vCurRoomType, vBalancesRow.CheckInDate, vBalancesRow.CheckOutDate, vRemarks) Then
				vBalancesRow.RoomsVacant = 0;
			EndIf;
		EndIf;
		
		pXMLWriter.WriteStartElement("VisitTimeTableInventory");
		pXMLWriter.WriteAttribute("Date", Format(vBalancesRow.CheckInDate, "DF=yyyy-MM-dd"));
		pXMLWriter.WriteAttribute("Duration", Format(vBalancesRow.Duration, "ND=6; NFD=0; NZ=; NG="));
		pXMLWriter.WriteAttribute("Quantity", Format(?(vBalancesRow.RoomsVacant < 0, 0, vBalancesRow.RoomsVacant), "ND=10; NFD=0; NZ=; NG="));
		pXMLWriter.WriteEndElement();
	EndDo;
	If vCurRoomType <> Undefined And Not vSkipRoomType Then
		pXMLWriter.WriteEndElement();
	EndIf;
	pXMLWriter.WriteEndElement();
EndProcedure // FillCheckInPeriodsByAllotmentsXML

// -----------------------------------------------------------------------------
Procedure FillDailyBalancesXML(pDailyBalances, pXMLWriter)
	vCurRoomType = Undefined;
	vSkipRoomType = False;
	For Each vBalancesRow In pDailyBalances Do
		If vCurRoomType <> vBalancesRow.RoomType Then
			If vCurRoomType <> Undefined And Not vSkipRoomType Then
				pXMLWriter.WriteEndElement();
			EndIf;
			vCurRoomType = vBalancesRow.RoomType;
			
			// Get room type external names
			vRoomCategoryShortName = "";
			vRoomTypeShortName = "";
			vRoomCategoryExtCodes = cmGetObjectExternalSystemCodeByRef(ExternalInteraction.Hotel, TrimR(ExternalInteraction.InteractionID), "RoomTypes", vCurRoomType, True);
			If IsBlankString(vRoomCategoryExtCodes) Then
				vSkipRoomType = True;
				Continue;
			Else
				vSkipRoomType = False;
			EndIf;
			
			// Try to split names to room type short name and room category short name
			vSlashPos = Find(vRoomCategoryExtCodes, "/");
			If vSlashPos > 1 Then
				vRoomCategoryShortName = Left(vRoomCategoryExtCodes, vSlashPos - 1);
				vRoomTypeShortName = Mid(vRoomCategoryExtCodes, vSlashPos + 1);
			Else
				vRoomCategoryShortName = TrimR(vRoomCategoryExtCodes);
			EndIf;
			
			// Build room category XDTO object
			pXMLWriter.WriteStartElement("RoomCategory");
			pXMLWriter.WriteAttribute("RoomCategoryCID", vRoomCategoryShortName);
		EndIf;
		If vSkipRoomType Then
			Continue;
		EndIf;
		
		// Check stop sale
		If vCurRoomType.StopSale Then
			vRemarks = "";
			If cmIsStopInternetSalePeriod(vCurRoomType, EndOfDay(vBalancesRow.Period), EndOfDay(vBalancesRow.Period), vRemarks) Then
				vBalancesRow.RoomsVacant = 0;
			EndIf;
		EndIf;
		
		pXMLWriter.WriteStartElement("DailyInventory");
		pXMLWriter.WriteAttribute("Date", Format(vBalancesRow.Period, "DF=yyyy-MM-dd"));
		pXMLWriter.WriteAttribute("Quantity", Format(?(vBalancesRow.RoomsVacant < 0, 0, vBalancesRow.RoomsVacant), "ND=10; NFD=0; NZ=; NG="));
		pXMLWriter.WriteEndElement();
	EndDo;
	If vCurRoomType <> Undefined And Not vSkipRoomType Then
		pXMLWriter.WriteEndElement();
	EndIf;
	pXMLWriter.WriteEndElement();
EndProcedure // FillDailyBalancesXML	

// -----------------------------------------------------------------------------
Procedure AddRoomRatePricesToXML(pXMLWriter, pFull, pExistPeriodTo)
	Var vRoomRatePricesList; 
	vHotel = ExternalInteraction.Hotel;
	vAccommodationTemplateBed = cmGetAccommodationTypeBed(vHotel);
	If vAccommodationTemplateBed.IsEmpty() Then
		vMessage =  Nstr("en = 'No match found in ALEAN CRS for bed placement type '; de = 'Keine Übereinstimmung in ALEAN CRS für Bett Platzierungsart gefunden'; ru = 'Не найдено соответствие в ALEAN CRS  для вида размещения место'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "AddRoomRatePricesToXML", Enums.ExternalSystemEventTypes.Error, , , vMessage);
		Raise vMessage; 
	EndIf;	
	
	// Get table for place kind
	vDailyRatesByPlace = New ValueTable;
	vDailyRatesByPlace.Columns.Add("PlaceKind");
	vDailyRatesByPlace.Columns.Add("TouristTypeCID");
	vDailyRatesByPlace.Columns.Add("PacketCID");
	vDailyRatesByPlace.Columns.Add("RoomCategoryCID");
	vDailyRatesByPlace.Columns.Add("PeriodFrom");
	vDailyRatesByPlace.Columns.Add("PeriodTo");
	vDailyRatesByPlace.Columns.Add("Price");

	vSentPricesByRoom = New Array;
	
	vCurMappingTable = GetExtAccommodationTemplates(ExternalInteraction);
	If vCurMappingTable.Count() = 0 Then
		vMessage = Nstr("en = 'No match found in ALEAN CRS for accomodation templates'; de = 'Keine Übereinstimmung in ALEAN CRS für Unterkunftsvorlagen gefunden'; ru = 'Не найдено соответствие в ALEAN CRS для шаблонов размещения. Необходимо выполнить первичную синхронизацию'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, "AddRoomRatePricesToXML", Enums.ExternalSystemEventTypes.Error, , , vMessage);
		Raise vMessage; 
	EndIf;	
	
	vAccTemplateList = vCurMappingTable.Copy();
	vAccTemplateList.GroupBy("RoomType, AccommodationTemplate, Excluded");

	If Not pFull Then
		// CHANGED SYNC
		// 1. Get periods room rates prices
		vRoomRateChanges = GetRoomRateChangesTable(vHotel);
		For Each vRoomRateRow in vRoomRateChanges Do
			vAccTemplates = vAccTemplateList.FindRows(New Structure("RoomType", vRoomRateRow.RoomType));
			If vAccTemplates.Count() = 0 Then
				Continue;
			EndIf;	
			
			If Not ValueIsFilled(pExistPeriodTo) Or vRoomRateRow.PeriodTo > pExistPeriodTo Then
				pExistPeriodTo = vRoomRateRow.PeriodTo;
			EndIf;	
			
			vRoomTypeExtName = cmGetObjectExternalSystemCodeByRef(vHotel, TrimR(ExternalInteraction.InteractionID), "RoomTypes", vRoomRateRow.RoomType);
			vSlashPos = Find(vRoomTypeExtName, "/");
			If vSlashPos > 1 Then
				vRoomTypeExtName = Left(vRoomTypeExtName, vSlashPos - 1);
			EndIf;

			// 2. Get table room rates prices
			vTabPrices = GetPrices(vHotel, vRoomRateRow.RoomRate, vRoomRateRow.RoomType, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo, vRoomRateRow.PriceTag);
			
			For Each vAccTemplateRow in vAccTemplates Do
				If vAccTemplateRow.Excluded Then
					Continue;
				EndIf;
				
				vAccTemplate = vAccTemplateRow.AccommodationTemplate;
				
				// By rooms
				vTabPriceRoom = GetEmptyTabPricesByRoom();
				
				vHashAccommodationTypes = "";
				
				FillPricesByAccTemplates(vAccommodationTemplateBed, vAccTemplate, vHashAccommodationTypes, vHotel, vTabPriceRoom, vTabPrices);

				// Check if it was unloaded
				vHashTemplate = String(vHotel) + vRoomRateRow.RoomRateExtCode + String(vRoomRateRow.RoomType) + String(vRoomRateRow.PeriodFrom) + String(vRoomRateRow.PeriodTo) + vHashAccommodationTypes;
				If vSentPricesByRoom.Find(vHashTemplate) = Undefined Then
					vSentPricesByRoom.Add(vHashTemplate);
				Else
					Continue;
				EndIf;	
				// Add to xml
				If vTabPriceRoom.Count() > 0 Then
					FillTariffInPeriodsByRoomXML(pXMLWriter, vHotel, vRoomRateRow.RoomRate, vRoomRateRow.RoomRateExtCode, vRoomRateRow.RoomType, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo, vTabPriceRoom, vAccTemplate.IsForFolioSplit);
				EndIf;
			EndDo;
		EndDo;	
	Else
		// FULL SYNC
		// 1. Get periods room rates prices
		vRoomRatesList = InformationRegisters.ExternalSystemIntegrationData.GetDataList(ExternalInteraction, "RoomRates");
		
		vCurrentDate = BegOfDay(CurrentSessionDate());
		If ExternalInteraction.ActiveDays = 0 Then
			vSyncPeriod = 400;
		Else
			vSyncPeriod = ExternalInteraction.ActiveDays;
		EndIf;
		If ValueIsFilled(ExternalInteraction.ActiveFromDate) And ExternalInteraction.ActiveFromDate > vCurrentDate Then
			vPeriodFrom = BegOfDay(ExternalInteraction.ActiveFromDate);
		Else
			vPeriodFrom = vCurrentDate;
		EndIf;
		
		If ValueIsFilled(ExternalInteraction.ActiveToDate) Then
			vPeriodTo = EndOfDay(ExternalInteraction.ActiveToDate);
		Else
			vPeriodTo = EndOfDay(vPeriodFrom + 24*3600 * vSyncPeriod);
		EndIf;

		For Each vRoomRatesQryRes In vRoomRatesList Do
			vRoomRate = vRoomRatesQryRes.RefKey1;
			vRoomRateExtCode = TrimAll(vRoomRatesQryRes.ExternalSystemDataCode); 
			If IsBlankString(vRoomRateExtCode) Then
				Continue;
			EndIf;	
			vRoomTypesList = ChannelManagers.GetMappedListObjects(vHotel, TrimAll(ExternalInteraction.InteractionID), "RoomTypes");
			For Each vRoomTypeQryRes In vRoomTypesList Do
				If IsBlankString(vRoomTypeQryRes.ObjectExternalCode) Then
					Continue;
				EndIf;
				vRoomType = vRoomTypeQryRes.ObjectRef;
				If IsBlankString(vRoomTypeQryRes.ObjectExternalCode) Then
					Continue;
				EndIf;	
				
				vRoomRatePrices = GetPrices(vHotel, vRoomRate, vRoomType, vPeriodFrom, vPeriodTo, vRoomRatesQryRes.RefKey2);
				vRoomRatePrices.Columns.Add("RoomRateExtCode"); 
				vRoomRatePrices.FillValues(vRoomRateExtCode, "RoomRateExtCode");
				vRoomRatePrices.GroupBy("RoomRate, RoomType, Period, PeriodFrom, PeriodTo, Pricetag, RoomRateExtCode", "Price");
				
				If ValueIsFilled(vRoomRate.BasedOnRoomRate) Then  
					vRoomRatePricesChRows = vRoomRatePrices.FindRows(New Structure("RoomRate", vRoomRate.BasedOnRoomRate));
					For Each vIndRow In vRoomRatePricesChRows Do
						vIndRow.RoomRate = vRoomRate;
					EndDo;		
				EndIf;
				
				MergeRatesTable(vRoomRatePrices);
				
				If vRoomRatePricesList = Undefined Then
					vRoomRatePricesList = vRoomRatePrices;
				Else
					For Each vInd In vRoomRatePrices Do
						vRow = vRoomRatePricesList.Add();
						FillPropertyValues(vRow,vInd);
					EndDo;	
				EndIf;
			EndDo;	
		EndDo;
		// 2. Get table room rates prices
		If vRoomRatePricesList.Count() > 0 Then
			vRoomRatePricesList.GroupBy("RoomRate, RoomType, PeriodFrom, PeriodTo, Pricetag, RoomRateExtCode");
		EndIf;
		For Each vRoomRateRow In vRoomRatePricesList Do
			vAccTemplates = vAccTemplateList.FindRows(New Structure("RoomType", vRoomRateRow.RoomType));
			If vAccTemplates.Count() = 0 Then
				Continue;
			EndIf;	
			If Not ValueIsFilled(pExistPeriodTo) Or vRoomRateRow.PeriodTo > pExistPeriodTo Then
				pExistPeriodTo = vRoomRateRow.PeriodTo;
			EndIf;
			vTabPrices = GetPrices(vHotel, vRoomRateRow.RoomRate, vRoomRateRow.RoomType, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo, vRoomRateRow.Pricetag); 
			
			vRoomTypeExtName = cmGetObjectExternalSystemCodeByRef(vHotel, TrimR(ExternalInteraction.InteractionID), "RoomTypes", vRoomRateRow.RoomType);
			vSlashPos = Find(vRoomTypeExtName, "/");
			If vSlashPos > 1 Then
				vRoomTypeExtName = Left(vRoomTypeExtName, vSlashPos - 1);
			EndIf;

			For Each vAccTemplateRow in vAccTemplates Do
				If vAccTemplateRow.Excluded Then
					Continue;
				EndIf;
				vAccTemplate = vAccTemplateRow.AccommodationTemplate;
								
				// By rooms
				vTabPriceRoom = GetEmptyTabPricesByRoom();

				vHashAccommodationTypes = "";
				
				FillPricesByAccTemplates(vAccommodationTemplateBed, vAccTemplate, vHashAccommodationTypes, vHotel, vTabPriceRoom, vTabPrices);
				
				// Check if it was unloaded
				vHashTemplate = String(vHotel) + vRoomRateRow.RoomRateExtCode + String(vRoomRateRow.RoomType) + String(vRoomRateRow.PeriodFrom) + String(vRoomRateRow.PeriodTo) + vHashAccommodationTypes;
				If vSentPricesByRoom.Find(vHashTemplate) = Undefined Then
					vSentPricesByRoom.Add(vHashTemplate);
				Else
					Continue;
				EndIf;	
				
				// Add to xml
				If vTabPriceRoom.Count() > 0 Then
					FillTariffInPeriodsByRoomXML(pXMLWriter, vHotel, vRoomRateRow.RoomRate, vRoomRateRow.RoomRateExtCode, vRoomRateRow.RoomType, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo, vTabPriceRoom, False);
				EndIf;
			EndDo;
		EndDo;									   
	EndIf;
	// Временно отключаем выгрузку цен по местам, т.к. на стороне КСБ нестыковки. Проблема в том, что КСБ не может учитывать вид размещения на один период разные цены, в зависимости от кол-ва чел в номере.
	// Пример: Вид. размещения "Место" - в отеле: Место_2-е - 5000р(при двухместном размещении) и Место_1-е - 10000р(при одноместном размещении) в КСБ: - Base_Turist. Все беды от того, что КСБ не может стыковать 1:1.
	// 3. Add to xml prices by place kind
	// DailyRatesByPlace.GroupBy("PlaceKind, TouristTypeCID, PacketCID, RoomCategoryCID, PeriodFrom, PeriodTo, Price");
	// FillTariffInPeriodsByRoomXML(pXMLWriter, vHotel,,,,, vDailyRatesByPlace, True);
EndProcedure

// -----------------------------------------------------------------------------
Procedure FillPricesByAccTemplates(Val vAccommodationTemplateBed, Val vAccTemplate, vHashAccommodationTypes, Val vHotel, Val vTabPriceRoom, Val vTabPrices)
	
	Var vAccTemplateExternalCode, vAccTypeRow, vCurrAccommodationType, vFilterPrices, vMsg, vNewRowTabPriceRoom, vTouristTypeCID;
	
	For Each  vAccTypeRow In vAccTemplate.AccommodationTypes Do
		vCurrAccommodationType = vAccTypeRow.AccommodationType;
		vTouristTypeCID = GetTouristTypeCID(vHotel, vCurrAccommodationType);						
		If IsBlankString(vTouristTypeCID) And vCurrAccommodationType.Type <> Enums.AccomodationTypes.AdditionalBed Then
			vTouristTypeCID = GetTouristTypeCID(vHotel, vAccommodationTemplateBed);
			If IsBlankString(vTouristTypeCID) Then	
				vMsg = Nstr("en = 'No match found in ALEAN CRS for placement type'; de = 'Keine Übereinstimmung in ALEAN CRS für Platzierungsart gefunden'; ru = 'Не найдено соответствие в ALEAN CRS  для вида размещения'")+" "+vCurrAccommodationType;
				tcCommonFunctionOnClientServer.TextMessage(vMsg);
			EndIf;
		ElsIf IsBlankString(vTouristTypeCID) Then	
			vMsg = Nstr("en = 'No match found in ALEAN CRS for placement type'; de = 'Keine Übereinstimmung in ALEAN CRS für Platzierungsart gefunden'; ru = 'Не найдено соответствие в ALEAN CRS  для вида размещения'")+" "+vCurrAccommodationType;
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
		EndIf;	
		
		vAccTemplateExternalCode = "";
		If vCurrAccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Then
			vAccTemplateExternalCode = "EXT";
		Else 
			vAccTemplateExternalCode = "BASE";
		EndIf;	
		
		vFilterPrices = vTabPrices.FindRows(New Structure("AccommodationType", vAccTypeRow.AccommodationType));
		
		vNewRowTabPriceRoom = vTabPriceRoom.Add();
		
		If vFilterPrices.Count() = 0 Then
			vNewRowTabPriceRoom.AccommodationType =  vAccTypeRow.AccommodationType;
			vNewRowTabPriceRoom.Price =  0;
			vNewRowTabPriceRoom.Quantity = 1;
		Else
			vNewRowTabPriceRoom.AccommodationType =  vAccTypeRow.AccommodationType;
			vNewRowTabPriceRoom.Price =  vFilterPrices[0].Price;
			vNewRowTabPriceRoom.Quantity = 1;
		EndIf;	
		vNewRowTabPriceRoom.PlaceKind = vAccTemplateExternalCode;
		vNewRowTabPriceRoom.TouristTypeCID = vTouristTypeCID;
		
		vHashAccommodationTypes = vHashAccommodationTypes + vAccTemplateExternalCode+ vTouristTypeCID;
	EndDo;

EndProcedure

// -----------------------------------------------------------------------------
Function GetEmptyTabPricesByRoom()
	
	vTabPriceRoom = New ValueTable;
	vTabPriceRoom.Columns.Add("AccommodationType");
	vTabPriceRoom.Columns.Add("Price");
	vTabPriceRoom.Columns.Add("Quantity");
	vTabPriceRoom.Columns.Add("PlaceKind");
	vTabPriceRoom.Columns.Add("TouristTypeCID");
	Return vTabPriceRoom;

EndFunction

// -----------------------------------------------------------------------------
Function GetExtAccommodationTemplates(pInteraction)
	vAvailabilityList = New ValueTable;
	vAvailabilityList.Columns.Add("AccommodationTemplate");
	vAvailabilityList.Columns.Add("RoomCategoryCID");
	vAvailabilityList.Columns.Add("RoomType");
	vAvailabilityList.Columns.Add("UUID");
	vAvailabilityList.Columns.Add("Excluded");

	vCurData = InformationRegisters.ExternalSystemIntegrationData.GetDataList(pInteraction, "AccommodationTemplates");
	For Each vRow In vCurData Do
	    vNewRowData = vAvailabilityList.Add();
		vNewRowData.AccommodationTemplate 	= vRow.RefKey2;
		vNewRowData.RoomCategoryCID 		= cmGetObjectExternalSystemCodeByRef(pInteraction.Hotel, pInteraction.InteractionID, "AccommodationTemplates", vRow.RefKey1, True);
		vNewRowData.RoomType 				= vRow.RefKey1;
		vNewRowData.UUID 					= vRow.ExternalSystemDataCode;
		vNewRowData.Excluded 				= vRow.DataValue ;
	EndDo;
	
	Return vAvailabilityList;
EndFunction

// -----------------------------------------------------------------------------
Procedure AddPricesAdditionalServicesToXML(pXMLWriter, pExistPeriodTo)
		
	vCurrentDate = BegOfDay(CurrentSessionDate());
	If ValueIsFilled(ExternalInteraction.ActiveFromDate) And ExternalInteraction.ActiveFromDate > vCurrentDate Then
		vPeriodFrom = BegOfDay(ExternalInteraction.ActiveFromDate);
	Else
		vPeriodFrom = vCurrentDate;
	EndIf;
	If ValueIsFilled(ExternalInteraction.ActiveToDate) Then
		vPeriodTo = EndOfDay(ExternalInteraction.ActiveToDate);
	Else
		vPeriodTo = EndOfDay(vPeriodFrom + 24*3600*365);
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
				"SELECT
				|	ExternalSystemsObjectCodesMappings.ObjectRef AS Ref,
				|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode
				|INTO qTabServices
				|FROM
				|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
				|WHERE
				|	ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Services""
				|	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode <> """"
				|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ServicePrices.Period AS PeriodFrom,
				|	ServicePrices.Service AS Service,
				|	ServicePrices.Price AS Price,
				|	qTabServices.ObjectExternalCode AS ExternalCode,
				|	DATETIME(1, 1, 1) AS PeriodTo
				|FROM
				|	InformationRegister.ServicePrices AS ServicePrices
				|		LEFT JOIN qTabServices AS qTabServices
				|		ON ServicePrices.Service = qTabServices.Ref
				|WHERE
				|	ServicePrices.Service IN
				|			(SELECT
				|				qTabServices.Ref AS Ref
				|			FROM
				|				qTabServices AS qTabServices)
				|	AND (ServicePrices.Hotel = &qHotel
				|			OR ServicePrices.Hotel = VALUE(Catalog.Hotels.EmptyRef))
				|	AND ServicePrices.ClientType = VALUE(Catalog.ClientTypes.EmptyRef)
				|
				|GROUP BY
				|	ServicePrices.Period,
				|	ServicePrices.Service,
				|	qTabServices.ObjectExternalCode,
				|	ServicePrices.Price
				|
				|ORDER BY
				|	Service,
				|	PeriodFrom";
	vQuery.SetParameter("qExternalSystemCode", ExternalInteraction.InteractionID);
	vQuery.SetParameter("qHotel", ExternalInteraction.Hotel);
	vPrices = vQuery.Execute().Unload();
	MergeServicesTable(vPrices, vPeriodTo) ;
		
	For Each vRow In vPrices Do
		If vRow.PeriodTo < vPeriodFrom Then
			Continue;
		EndIf;	
		// STEP 1. Record PlaceKind for "BASE" 
		pXMLWriter.WriteStartElement("ServiceTariff");  //Start ServiceTariff
		pXMLWriter.WriteAttribute("PlaceKind", "BASE"); //PlaceKind
		pXMLWriter.WriteAttribute("ServiceCID", vRow.ExternalCode); //ServiceCID
		// Period
		pXMLWriter.WriteStartElement("PeriodList");  //Start PeriodList
		pXMLWriter.WriteStartElement("Period");  //Start Period
		pXMLWriter.WriteAttribute("From", Format(vRow.PeriodFrom, "DF=yyyy-MM-dd"));  //Period from
		pXMLWriter.WriteAttribute("To", Format(vRow.PeriodTo, "DF=yyyy-MM-dd"));    //Period to
		pXMLWriter.WriteAttribute("Price", Format(vRow.Price, "ND=10; NFD=2; NDS=.; NZ=0.00; NG=; DF=yyyy-MM-dd")); //Price
		pXMLWriter.WriteEndElement(); //End Period
		pXMLWriter.WriteEndElement(); //End PeriodList
		pXMLWriter.WriteEndElement(); //End ServiceTariff
		
		// STEP 2. Record PlaceKind for "EXT" 
		pXMLWriter.WriteStartElement("ServiceTariff");  //Start ServiceTariff
		pXMLWriter.WriteAttribute("PlaceKind",  "EXT"); //PlaceKind
		pXMLWriter.WriteAttribute("ServiceCID",vRow.ExternalCode); //ServiceCID
		// Period
		pXMLWriter.WriteStartElement("PeriodList");  //Start PeriodList
		pXMLWriter.WriteStartElement("Period");  //Start Period
		pXMLWriter.WriteAttribute("From", Format(vRow.PeriodFrom, "DF=yyyy-MM-dd"));  //Period from
		pXMLWriter.WriteAttribute("To", Format(vRow.PeriodTo, "DF=yyyy-MM-dd"));    //Period to
		pXMLWriter.WriteAttribute("Price", Format(vRow.Price, "ND=10; NFD=2; NDS=.; NZ=0.00; NG=; DF=yyyy-MM-dd")); //Price
		pXMLWriter.WriteEndElement(); //End Period
		pXMLWriter.WriteEndElement(); //End PeriodList
		pXMLWriter.WriteEndElement(); //End ServiceTariff
		
		If Not ValueIsFilled(pExistPeriodTo) And ValueIsFilled(vPeriodTo) Then
			pExistPeriodTo = vPeriodTo;
		EndIf;	
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
Function GetRoomRateChangesTable(Val vHotel)
	vCurrentDate = BegOfDay(CurrentSessionDate());
	If ExternalInteraction.ActiveDays = 0 Then
		vSyncPeriod = 400;
	Else
		vSyncPeriod = ExternalInteraction.ActiveDays;
	EndIf;
	If ValueIsFilled(ExternalInteraction.ActiveFromDate) And ExternalInteraction.ActiveFromDate > vCurrentDate Then
		vPeriodFrom = BegOfDay(ExternalInteraction.ActiveFromDate);
	Else
		vPeriodFrom = vCurrentDate;
	EndIf;
	
	If ValueIsFilled(ExternalInteraction.ActiveToDate) Then
		vPeriodTo = EndOfDay(ExternalInteraction.ActiveToDate);
	Else
		vPeriodTo = EndOfDay(vPeriodFrom + 24*3600*vSyncPeriod);
	EndIf;

	vRoomRateChanges = new ValueTable;
	vRoomRateChanges.Columns.Add("Hotel");
	vRoomRateChanges.Columns.Add("RoomRate");
	vRoomRateChanges.Columns.Add("RoomType");
	vRoomRateChanges.Columns.Add("PeriodFrom");
	vRoomRateChanges.Columns.Add("PeriodTo");
	vRoomRateChanges.Columns.Add("RoomRateExtCode");
	vRoomRateChanges.Columns.Add("PriceTag");
	
	vRoomRatesQryRes = InformationRegisters.ExternalSystemIntegrationData.GetDataList(ExternalInteraction, "RoomRates");
	vRoomTypesList = ChannelManagers.GetMappedListObjects(vHotel, TrimAll(ExternalInteraction.InteractionID), "RoomTypes");
	For Each  vRoomRates In vRoomRatesQryRes Do
		vRoomRate = vRoomRates.RefKey1;
		vRoomRateCode = TrimAll(vRoomRates.ExternalSystemDataCode);
		If IsBlankString(vRoomRateCode) Then 
			Continue;
		EndIf;	
		vChangedRates = ChannelManagers.GetPeriodsOfChangedRates(ExternalInteraction, vHotel, vRoomRate, vPeriodFrom, vPeriodTo, vRoomRates.RefKey2);
		For Each vChangedRatesRow In vChangedRates Do
			vFilter =  vRoomTypesList.FindRows(New Structure("ObjectRef",vChangedRatesRow.RoomType));
			If vFilter.Count() = 0 Then
				Continue;
			Else
				If IsBlankString(vFilter[0].ObjectExternalCode) Then
					Continue;
				EndIf;	
			EndIf;	
			vRoomRatePrices = GetPrices(vHotel, vRoomRate, vChangedRatesRow.RoomType, vChangedRatesRow.Period, vChangedRatesRow.Period, vChangedRatesRow.PriceTag);
			vRoomRatePrices.Columns.Add("RoomRateExtCode"); 
			vRoomRatePrices.FillValues(vRoomRateCode, "RoomRateExtCode");
			vRoomRatePrices.GroupBy("RoomRate, RoomType, Period, PeriodFrom, PeriodTo, Pricetag, RoomRateExtCode", "Price");
			
			If ValueIsFilled(vRoomRate.BasedOnRoomRate) Then  
				vRoomRatePricesChRows = vRoomRatePrices.FindRows(New Structure("RoomRate", vRoomRate.BasedOnRoomRate));
				For Each vIndRow In vRoomRatePricesChRows Do
					vIndRow.RoomRate = vRoomRate;
				EndDo;		
			EndIf;        
			
			MergeRatesTable(vRoomRatePrices);
			
			For Each vRowRate In vRoomRatePrices Do
			    vRow = vRoomRateChanges.Add();
				FillPropertyValues(vRow, vRowRate);
			EndDo; 
		EndDo;
	EndDo;
	Return vRoomRateChanges;
EndFunction

// -----------------------------------------------------------------------------
Function GetPrices(pHotel, pRoomRate, pRoomType, pPeriodFrom, pPeriodTo, pPriceTag = Undefined)
	// Add actual records
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRatesSliceLast.SetRoomRateFormulas AS Recorder,
	|	RoomRatesSliceLast.RoomRate AS RoomRate
	|INTO ActiveSetRoomRateFormulas
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPriceCalculationDate,
	|			RoomRate = &qRoomRate
	|				AND Hotel = &qHotel
	|				AND IsFormula) AS RoomRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRateFormulas.RoomRate.BasedOnRoomRate AS BasedOnRoomRate,
	|	RoomRateFormulas.RoomRate.BasedOnPriceTag AS BasedOnPriceTag,
	|	RoomRateFormulas.RoomRate AS RoomRate,
	|	RoomRateFormulas.Hotel AS Hotel,
	|	RoomRateFormulas.IsFormula AS IsFormula,
	|	RoomRateFormulas.Service AS Service,
	|	RoomRateFormulas.RoomType AS RoomType,
	|	RoomRateFormulas.AccommodationType AS AccommodationType,
	|	RoomRateFormulas.ClientType AS ClientType,
	|	RoomRateFormulas.CalendarDayType AS CalendarDayType,
	|	RoomRateFormulas.Recorder AS Recorder,
	|	RoomRateFormulas.Period AS Period,
	|	RoomRateFormulas.BracketsConstant AS BracketsConstant,
	|	RoomRateFormulas.Constant AS Constant,
	|	RoomRateFormulas.Multiplier AS Multiplier,
	|	RoomRateFormulas.ReplaceWithService AS ReplaceWithService
	|INTO RoomRateFormulas
	|FROM
	|	InformationRegister.RoomRateFormulas AS RoomRateFormulas
	|		INNER JOIN ActiveSetRoomRateFormulas AS ActiveSetRoomRateFormulas
	|		ON RoomRateFormulas.Recorder = ActiveSetRoomRateFormulas.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomRateDailyPrices.Hotel AS Hotel,
	|	RoomRateDailyPrices.RoomRate AS RoomRate,
	|	RoomRateDailyPrices.RoomType AS RoomType,
	|	RoomRateDailyPrices.Period AS Period,
	|	RoomRateDailyPrices.AccommodationType AS AccommodationType,
	|	(RoomRateDailyPrices.Price + ISNULL(RoomRateFormulas.BracketsConstant, 0)) * ISNULL(RoomRateFormulas.Multiplier, 1) + ISNULL(RoomRateFormulas.Constant, 0) AS Price,
	|	RoomRateDailyPrices.Currency AS Currency,
	|	1 AS Quantity,
	|	RoomRateDailyPrices.Period AS PeriodFrom,
	|	DATETIME(1, 1, 1) AS PeriodTo,
	|	RoomRateDailyPrices.PriceTag AS PriceTag
	|FROM
	|	InformationRegister.RoomRateDailyPrices AS RoomRateDailyPrices
	|		LEFT JOIN InformationRegister.CalendarDays.SliceLast(&qPriceCalculationDate, ) AS CalendarDays
	|		ON RoomRateDailyPrices.RoomRate.Calendar = CalendarDays.Calendar
	|			AND RoomRateDailyPrices.Period = CalendarDays.AccountingDate
	|		LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(&qPriceCalculationDate, ) AS CalendarDaysByRoomTypes
	|		ON RoomRateDailyPrices.RoomRate.Calendar = CalendarDaysByRoomTypes.Calendar
	|			AND RoomRateDailyPrices.Period = CalendarDaysByRoomTypes.AccountingDate
	|			AND RoomRateDailyPrices.RoomType = CalendarDaysByRoomTypes.RoomType
	|		LEFT JOIN RoomRateFormulas AS RoomRateFormulas
	|		ON (RoomRateFormulas.RoomRate = &qRoomRate)
	|			AND RoomRateDailyPrices.Hotel = RoomRateFormulas.Hotel
	|			AND (NOT RoomRateFormulas.IsFormula
	|				OR RoomRateFormulas.IsFormula
	|					AND RoomRateDailyPrices.RoomType = RoomRateFormulas.RoomType
	|					AND RoomRateDailyPrices.ClientType = &qClientType
	|					AND RoomRateDailyPrices.AccommodationType = RoomRateFormulas.AccommodationType
	|					AND (CalendarDaysByRoomTypes.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|							AND CalendarDaysByRoomTypes.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|						OR CalendarDays.CalendarDayType = RoomRateFormulas.CalendarDayType
	|							AND NOT CalendarDays.CalendarDayType IS NULL
	|							AND (CalendarDaysByRoomTypes.CalendarDayType IS NULL OR CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef))
	|						OR RoomRateFormulas.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)))
	|			AND (RoomRateFormulas.BasedOnPriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|				OR RoomRateDailyPrices.PriceTag = RoomRateFormulas.BasedOnPriceTag
	|					AND RoomRateFormulas.BasedOnPriceTag <> VALUE(Catalog.PriceTags.EmptyRef))
	|WHERE
	|	RoomRateDailyPrices.Hotel = &qHotel
	|	AND RoomRateDailyPrices.RoomRate = &qRoomRateInCache
	|	AND RoomRateDailyPrices.RoomType = &qRoomType
	|	AND RoomRateDailyPrices.Period >= &qPeriodFrom
	|	AND RoomRateDailyPrices.Period <= &qPeriodTo
	|	AND RoomRateDailyPrices.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef)
	|	AND RoomRateDailyPrices.ClientType = VALUE(Catalog.ClientTypes.EmptyRef)
	|	AND CASE
	|			WHEN &qPriceTagFilled
	|				THEN RoomRateDailyPrices.PriceTag = &qPriceTag
	|			ELSE RoomRateDailyPrices.PriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|		END
	|
	|ORDER BY
	|	Period,
	|	RoomRateDailyPrices.AccommodationType.SortCode,
	|	RoomRateDailyPrices.AccommodationType.Code";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomRate", pRoomRate);
	If ValueIsFilled(pRoomRate) Then
		vQry.SetParameter("qRoomRateInCache", ?(ValueIsFilled(pRoomRate.BasedOnRoomRate), pRoomRate.BasedOnRoomRate, pRoomRate));
	Else
		vQry.SetParameter("qRoomRateInCache", Catalogs.RoomRates.EmptyRef());
	EndIf;
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(pPeriodTo));
	vQry.SetParameter("qPriceTag", pPriceTag);                         
	vQry.SetParameter("qClientType",  Catalogs.ClientTypes.EmptyRef());
	vQry.SetParameter("qPriceTagFilled", ValueIsFilled(pPriceTag));
	vQry.SetParameter("qPriceCalculationDate", CurrentSessionDate());
	
	vResult = vQry.Execute().Unload();
	
	// Process service packages for dependent rates and special dates
	vServicePackagesList = New ValueList();
	vServicePackagesCache = Undefined;
	If ValueIsFilled(pRoomRate.BasedOnRoomRate) Then
		// We have to take differencies in the packages into account only
		vServicePackagesListForBasedOnRoomRate = pRoomRate.BasedOnRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
		vServicePackagesList = pRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);

		// Add to the current rate service packages list service packages that were removed from the base room rate
		i = 0;
		While i < vServicePackagesListForBasedOnRoomRate.Count() Do
			vSPRemovedFromBasedRR = vServicePackagesListForBasedOnRoomRate.Get(i).Value;
			If vServicePackagesList.FindByValue(vSPRemovedFromBasedRR) = Undefined Then
				vServicePackagesList.Add(vSPRemovedFromBasedRR, , True);
			EndIf;
			i = i + 1;
		EndDo;
		
		// Delete service packages that are present in the based on room rate list of service packages
		If vServicePackagesListForBasedOnRoomRate.Count() > 0 Then
			i = 0;
			While i < vServicePackagesList.Count() Do
				vServicePackagesListItem = vServicePackagesList.Get(i);
				If Not vServicePackagesListItem.Check Then
					vCurServicePackage = vServicePackagesListItem.Value;
					If vServicePackagesListForBasedOnRoomRate.FindByValue(vCurServicePackage) <> Undefined Then
						vDeleteSP = True;
						For Each vSPRow In vCurServicePackage.Services Do
							If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
								vDeleteSP = False;
								Break;
							EndIf;
						EndDo;
						If vDeleteSP Then
							vServicePackagesList.Delete(i);
						Else
							vServicePackagesListItem.Presentation = "<<DO_NOT_PROCESS>>";
							i = i + 1;
						EndIf;
					Else
						i = i + 1;
					EndIf;
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	Else
		vServicePackagesList = pRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
		i = 0;
		While i < vServicePackagesList.Count() Do
			vCurServicePackage = vServicePackagesList.Get(i).Value;
			vDeleteSP = True;
			For Each vSPRow In vCurServicePackage.Services Do
				If vSPRow.IsInPrice And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
					vDeleteSP = False;
					Break;
				EndIf;
			EndDo;
			If vDeleteSP Then
				vServicePackagesList.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	For Each vPriceRow In vResult Do
		vCurDate = BegOfDay(vPriceRow.Period);
		vCurCalendarDayType = Undefined;
		For Each vServicePackagesItem In vServicePackagesList Do
			vCurServicePackage = vServicePackagesItem.Value;
			// Check if service package is valid
			If vCurServicePackage.DateValidFrom <= vCurDate And (vCurServicePackage.DateValidTo >= vCurDate Or Not ValueIsFilled(vCurServicePackage.DateValidTo)) Then
				// Get service package services
				vCurServicePackageServices = Undefined;
				If vServicePackagesCache <> Undefined Then
					vCurServicePackageServices = vServicePackagesCache.FindRows(New Structure("ServicePackage, Period", vCurServicePackage, vCurDate));
					If vCurServicePackageServices.Count() = 0 Then
						vCurServicePackageServices = Undefined;
					EndIf;
				EndIf;
				If vCurServicePackageServices = Undefined Then
					vCurServicePackageServices = Catalogs.ServicePackages.GetServices(vCurServicePackage, vCurDate);
					If vServicePackagesCache = Undefined Then
						vServicePackagesCache = vCurServicePackageServices.Copy();
					Else
						For Each vCurServicePackageServicesRow In vCurServicePackageServices Do
							vServicePackagesCacheRow = vServicePackagesCache.Add();
							FillPropertyValues(vServicePackagesCacheRow, vCurServicePackageServicesRow);
						EndDo;
					EndIf;
				EndIf;
				For Each vSPRow In vCurServicePackageServices Do
					If vSPRow.IsInPrice And ValueIsFilled(pRoomRate) And 
					  (ValueIsFilled(vSPRow.AccountingDate) And vSPRow.AccountingDate = vCurDate Or
					   vSPRow.AccountingDayNumber = 0 And Not ValueIsFilled(vSPRow.AccountingDate) And ValueIsFilled(pRoomRate.BasedOnRoomRate) And vServicePackagesItem.Presentation <> "<<DO_NOT_PROCESS>>") Then
						If vServicePackagesItem.Check And (vSPRow.AccountingDayNumber <> 0 Or ValueIsFilled(vSPRow.AccountingDate)) Then
						   Continue;
						EndIf;
											
						// Get and check date calendar day type
						If ValueIsFilled(vSPRow.CalendarDayType) Then
							If vCurCalendarDayType = Undefined Then
								vPriceTag = Undefined;
								vCurCalendarDayType = cmGetCalendarDayType(pRoomRate, vCurDate, Undefined, Undefined, vPriceTag, vPriceRow.RoomType);
							EndIf;
							If vSPRow.CalendarDayType <> vCurCalendarDayType Then
								Continue;
							EndIf;
						EndIf;
						
						// Update price rows in prices
						If (Not ValueIsFilled(vSPRow.RoomType) Or ValueIsFilled(vSPRow.RoomType) And vSPRow.RoomType = vPriceRow.RoomType) And 
						   (Not ValueIsFilled(vSPRow.AccommodationType) Or ValueIsFilled(vSPRow.AccommodationType) And vSPRow.AccommodationType = vPriceRow.AccommodationType) Then
							vPrice = cmConvertCurrencies(vSPRow.Price * ?(vSPRow.Quantity > 0, vSPRow.Quantity, 1), vSPRow.Currency, , vPriceRow.Currency, , vCurDate, pHotel);
							vPriceRow.Price = vPriceRow.Price + ?(vServicePackagesItem.Check, -vPrice, vPrice);
						EndIf;
					EndIf;
				EndDo; // by service package services
			EndIf;
		EndDo; // by service packages
	EndDo; // by prices
	
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
Procedure FillTariffInPeriodsByRoomXML(pXMLWriter, pHotel, pRoomRate = Undefined, pRateExtCode = "", pRoomType = Undefined, pPeriodFrom = Undefined, pPeriodTo = Undefined, Val pTabPrices, pIsPlaceKind)
	If Not pIsPlaceKind Then             
		// By room
		vAmount = pTabPrices.Total("Price");
		vAccTemplateQuantity = pTabPrices.Copy();
		
		// Get room type external name 
		vRoomTypeExtName = cmGetObjectExternalSystemCodeByRef(pHotel,TrimR(ExternalInteraction.InteractionID),"RoomTypes",pRoomType);
		vSlashPos = Find(vRoomTypeExtName, "/");
		If vSlashPos > 1 Then
			vRoomTypeExtName = Left(vRoomTypeExtName, vSlashPos - 1);
		EndIf;
		
		vAccTemplateQuantity.GroupBy("PlaceKind,TouristTypeCID","Quantity");
		pXMLWriter.WriteStartElement("RoomTariff");  //Start RoomTariff
		
		pXMLWriter.WriteAttribute("RoomCategoryCID", vRoomTypeExtName);  //Room type
		pXMLWriter.WriteAttribute("PacketCID", pRateExtCode);   //Room rate
		
		// Period
		vPeriodFrom = Format(pPeriodFrom, "DF=yyyy-MM-dd");
		vPeriodTo = Format(pPeriodTo, "DF=yyyy-MM-dd");
		
		pXMLWriter.WriteStartElement("PeriodList");  //Start PeriodList
		pXMLWriter.WriteStartElement("Period");  //Start Period
		pXMLWriter.WriteAttribute("From", vPeriodFrom);  //Period from
		pXMLWriter.WriteAttribute("To", vPeriodTo);    //Period to
		pXMLWriter.WriteAttribute("Price", Format(vAmount, "ND=10; NFD=2; NDS=.; NZ=0.00; NG=; DF=yyyy-MM-dd")); //Price
		pXMLWriter.WriteEndElement(); //End Period
		pXMLWriter.WriteEndElement(); //End PeriodList
		
		// TouristTypeList
		pXMLWriter.WriteStartElement("TouristTypeList");  //Start TouristTypeList
		For Each vResRow In vAccTemplateQuantity Do 
			If IsBlankString(vResRow.TouristTypeCID) Then
				Continue;
			EndIf;	
			pXMLWriter.WriteStartElement("TouristType");  //Start TouristType
			pXMLWriter.WriteAttribute("PlaceKind", vResRow.PlaceKind); //PlaceKind
			pXMLWriter.WriteAttribute("TouristTypeCID", vResRow.TouristTypeCID);   //TouristTypeCID
			pXMLWriter.WriteAttribute("Quantity", Format(vResRow.Quantity, "ND=10; NFD=0; NZ=; NG=")); //Quantity
			pXMLWriter.WriteEndElement(); //End TouristType
		EndDo;
		pXMLWriter.WriteEndElement(); //End TouristTypeList
		pXMLWriter.WriteEndElement(); //End RoomTariff
	Else
		// By place kind
		vCache = New Array;
		
		For Each vResRow In pTabPrices Do 
			If IsBlankString(vResRow.TouristTypeCID) or IsBlankString(vResRow.PlaceKind) Then
				Continue;
			EndIf;	

			vHashTemplate = vResRow.PacketCID + vResRow.RoomCategoryCID + vResRow.TouristTypeCID + vResRow.PlaceKind + String(vResRow.PeriodFrom) + String(vResRow.PeriodTo);

			If vCache.Find(vHashTemplate) = Undefined Then
				vCache.Add(vHashTemplate);
			Else
				Continue;
			EndIf;	
						
			pXMLWriter.WriteStartElement("PlaceTariff");  //Start PlaceTariff
			
			pXMLWriter.WriteAttribute("RoomCategoryCID", vResRow.RoomCategoryCID);  //Room type
			pXMLWriter.WriteAttribute("PacketCID", vResRow.PacketCID);   //Room rate
			pXMLWriter.WriteAttribute("PlaceKind", vResRow.PlaceKind); //PlaceKind
			pXMLWriter.WriteAttribute("TouristTypeCID", vResRow.RoomCategoryCID);   //TouristTypeCID
			
			// Period
			pXMLWriter.WriteStartElement("PeriodList");  //Start PeriodList
			pXMLWriter.WriteStartElement("Period");  //Start Period
			pXMLWriter.WriteAttribute("From", Format(vResRow.PeriodFrom, "DF=yyyy-MM-dd"));  //Period from
			pXMLWriter.WriteAttribute("To", Format(vResRow.PeriodTo, "DF=yyyy-MM-dd"));    //Period to
			pXMLWriter.WriteAttribute("Price", Format(vResRow.Price, "ND=10; NFD=2; NDS=.; NZ=0.00; NG=; DF=yyyy-MM-dd")); //Price
			pXMLWriter.WriteEndElement(); //End Period
			pXMLWriter.WriteEndElement(); //End PeriodList

			pXMLWriter.WriteEndElement(); //End PlaceTariff
		EndDo;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Function GetTouristTypeCID(Val pHotel, Val pCurrAccommodationType)
	
	Var vSlashPos, vTouristTypeCID, vTouristTypeName;
	
	vTouristTypeCID = "";
	vTouristTypeName = cmGetObjectExternalSystemCodeByRef(pHotel, TrimR(ExternalInteraction.InteractionID), "AccommodationTypes", pCurrAccommodationType, True);
	vSlashPos = Find(vTouristTypeName, "/");
	If vSlashPos > 1 Then
		vTouristTypeCID = Mid(vTouristTypeName, vSlashPos + 1);
	EndIf;
	Return vTouristTypeCID;

EndFunction

// -----------------------------------------------------------------------------
Procedure MergeRatesTable(TRates) 
	// Merge identical values in consequent days to one row
	If TRates.Count() > 1 Then
		prev = TRates.Get(0);

		i = 1;
		While i < TRates.Count() Do
			curr = TRates.Get(i);
			If curr.RoomRate = prev.RoomRate And
				curr.RoomType = prev.RoomType And
				curr.PriceTag = prev.PriceTag And
				curr.Price = prev.Price Then
				// Nothing has changed but period, then merge rows - just move PeriodTo to next date
				prev.PeriodTo = curr.PeriodFrom;
				
				TRates.Delete(curr);
			Else
				If Not ValueIsFilled(prev.PeriodTo) Then
					// If the first row
					prev.PeriodTo = prev.PeriodFrom;
				EndIf;	
				
				prev = curr;
				
				If Not ValueIsFilled(prev.PeriodTo) Then
					// In other situations
					prev.PeriodTo = curr.PeriodFrom;
				EndIf;
				
				i=i+1;
			EndIf;	
		EndDo;
	ElsIf TRates.Count() = 1 Then
		prev = TRates.Get(0);
		prev.PeriodTo = prev.PeriodFrom;
	EndIf;
EndProcedure // GetRates

// -----------------------------------------------------------------------------
Procedure MergeServicesTable(pServices, pPeriodTo) 
	// Merge identical values in consequent days to one row
	If pServices.Count() > 1 Then
		prev = pServices.Get(0);
		
		i = 1;
		While i < pServices.Count() Do
			curr = pServices.Get(i);
			If curr.Service = prev.Service And curr.Price = prev.Price Then
				// Nothing has changed but period, then merge rows - just move PeriodTo to next date
				prev.PeriodTo = curr.PeriodFrom;
				
				pServices.Delete(curr);
			Else
				If curr.Service = prev.Service Then
					prev.PeriodTo = curr.PeriodFrom - 24*3600;
				Else	
					prev.PeriodTo = pPeriodTo;
				EndIf;
				prev = curr;
				
				If Not ValueIsFilled(prev.PeriodTo) Then
					// In other situations
					prev.PeriodTo = pPeriodTo;
				EndIf;
				
				i=i+1;
			EndIf;	
		EndDo;
	ElsIf pServices.Count() = 1 Then
		prev = pServices.Get(0);
		prev.PeriodTo = pPeriodTo;
	EndIf;
EndProcedure // GetRates

// -----------------------------------------------------------------------------
Procedure SaveSyncTable(pFull, pPeriodTo)
	vPeriodFrom = BegOfDay(CurrentDate());
	vHotel = ExternalInteraction.Hotel;
	// Get periods for full sync
	If pFull Then
		If ValueIsFilled(ExternalInteraction.ActiveToDate) Then
			vPeriodTo = EndOfDay(ExternalInteraction.ActiveToDate);
		Else
			vPeriodTo = vPeriodFrom + 24*3600*400;
		EndIf;	
	EndIf;	
	
	// Get mapping objects
	vRoomRatesList = InformationRegisters.ExternalSystemIntegrationData.GetDataList(ExternalInteraction, "RoomRates");
	vRoomTypesList = ChannelManagers.GetMappedListObjects(vHotel, TrimAll(ExternalInteraction.InteractionID), "RoomTypes");
	
	vFilter = vRoomRatesList.FindRows(New Structure("ExternalSystemDataCode", ""));
	For Each vRowFilter In vFilter Do
		vRoomRatesList.Delete(vRowFilter);
	EndDo;
	vRoomRatesList.GroupBy("RefKey1, RefKey2");
	
	vFilter = vRoomTypesList.FindRows(New Structure("ObjectExternalCode", ""));
	For Each vRowFilter In vFilter Do
		vRoomTypesList.Delete(vRowFilter);
	EndDo;
	vRoomTypesList.GroupBy("ObjectRef");

	If Not pFull Then
		// Changes
		vRoomRateChanges = GetRoomRateChangesTable(vHotel);
		vRoomRateChanges.GroupBy("RoomRate, RoomType, PeriodFrom, PeriodTo, Pricetag");
		// Merge identical values in consequent days to one row
		If vRoomRateChanges.Count() > 1 Then
			prev = vRoomRateChanges.Get(0);
			i = 1;
			While i < vRoomRateChanges.Count() Do
				curr = vRoomRateChanges.Get(i);
				If curr.RoomRate = prev.RoomRate And
					curr.RoomType = prev.RoomType And
					curr.PriceTag = prev.PriceTag And
					curr.PeriodFrom = (prev.PeriodTo + 86400) Then
					// Nothing has changed but period, then merge rows - just move PeriodTo to next date
					prev.PeriodTo = curr.PeriodTo;
					vRoomRateChanges.Delete(curr);
				Else
					If Not ValueIsFilled(prev.PeriodTo) Then
						// If the first row
						prev.PeriodTo = prev.PeriodFrom;
					EndIf;	
					prev = curr;
					If Not ValueIsFilled(prev.PeriodTo) Then
						// In other situations
						prev.PeriodTo = curr.PeriodFrom;
					EndIf;
					i=i+1;
				EndIf;	
			EndDo;
		ElsIf vRoomRateChanges.Count() = 1 Then
			prev = vRoomRateChanges.Get(0);
			prev.PeriodTo = prev.PeriodFrom;
		EndIf;
	EndIf;
EndProcedure	

// -----------------------------------------------------------------------------
Function pmCheckFullSyncTime(pChannelManager, pIsInteractive = False, Val pFull = False)
	vFull = pFull;
	If Not pIsInteractive And Not pFull Then
		If ValueIsFilled(pChannelManager.FullSynchronizationTime) And ValueIsFilled(pChannelManager.SessionLastActivityTime) Then
			If BegOfDay(pChannelManager.LastFullSynchronizationTime) < BegOfDay(CurrentSessionDate()) Then
				vFullSyncDateTime = BegOfDay(CurrentSessionDate()) + (pChannelManager.FullSynchronizationTime - BegOfDay(pChannelManager.FullSynchronizationTime));
				If CurrentSessionDate() >= vFullSyncDateTime Then
					vFull = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vFull;
EndFunction // CheckFullSyncTime

#EndRegion
