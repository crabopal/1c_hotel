
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Any	 - Additional parameters
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
Procedure pmFillAttributesWithDefaultValues() Export  
	vOneYear = 365 * 24 * 3600;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Period) Then
		Period = BegOfDay(CurrentSessionDate()) - vOneYear
	EndIf;
	If Not PurgeChargesMarkedForDeletion  
	   And Not PurgeFoliosMarkedForDeletion 
	   And Not PurgeChangeHistoryRecords 
	   And Not PurgeUserActionsHistory Then
		PurgeChargesMarkedForDeletion = True;
		PurgeFoliosMarkedForDeletion = True;
		MarkClientsWithoutReferencesDeleted = True;
		PurgeChangeHistoryRecords = False;
		PurgeClientDataScans = False;
		SaveClientDataScans2Disc = False;
		ClearProcessedOnly = False;
		PurgeClientIdentificationData = False;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Run data processor in silent mode
//
// Parameters:
//  pParameter		 - Any - Additional parameters
//  pIsInteractive	 - Boolean - is interactive use 
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Clear database
	pmClearDatabase(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
//
// Parameters:
//  pIsInteractive	 - Boolean	 - is interactive use
//
Procedure pmClearDatabase(pIsInteractive = False) Export   
	vFuncLogName = NStr("en = 'DataProcessor.ClearDatabase'; de = 'DataProcessor.ClearDatabase'; ru = 'Обработка.ОчисткаБазыДанных'");
	WriteLogEvent(vFuncLogName, EventLogLevel.Information, Metadata(), Undefined, NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'"));   
	vRegistersToPurge = New Array;
	// Check parameters
	If Not ValueIsFilled(Period) Then
		vMessage = NStr("ru='Не указана дата, по которую удалять объекты и записи!';
						|de='Das Datum, an dem die Objekte und die Eintragungen gelöscht werden sollen, ist nicht angegeben!';
						|en='Date to keep objects and records is not specified!'");
		WriteLogEvent(vFuncLogName, EventLogLevel.Warning, Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	// Process charges
	If PurgeChargesMarkedForDeletion Then
		PurgeChargesMarkedForDeletion(pIsInteractive);
	EndIf;
	// Process folios
	If PurgeFoliosMarkedForDeletion Then
		PurgeFoliosMarkedForDeletion(pIsInteractive);
	EndIf;
	// Process history records
	If PurgeChangeHistoryRecords Then
		// Accommodation change history
		vInfRegMgr = InformationRegisters.AccommodationChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Accommodation changes history", "История изменений размещений", "Unterkunftänderungen geschichte", True);
		// Reservation change history
		vInfRegMgr = InformationRegisters.ReservationChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Reservation changes history", "История изменений резервирований", "Reservierungsänderungen geschichte", True);
		// Resource reservation change history
		vInfRegMgr = InformationRegisters.ResourceReservationChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Resource reservation changes history", "История изменений брони ресурсов", "Ressourcenreservierungsänderungen geschichte", True);
		// Foreigner registry record change history
		vInfRegMgr = InformationRegisters.ForeignerRegistryRecordChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Foreigner registry records", "Журнал регистрации иностранцев", "Ausländerregistereinträge", True);
		// Client change history
		vInfRegMgr = InformationRegisters.ClientChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Client changes history", "История изменений клиентов", "Kundenänderungen geschichte", False);
		// Customer change history
		vInfRegMgr = InformationRegisters.CustomerChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Customer changes history", "История изменений контрагентов", "Firmenänderungen geschichte", False);
		// Contract change history
		vInfRegMgr = InformationRegisters.ClientChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Contract changes history", "История изменений договоров", "Vertragsänderungen geschichte", False);
		// Room status change history
		vInfRegMgr = InformationRegisters.RoomStatusChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Room status changes history", "История изменений статусов номеров", "Zimmerstatusänderungen geschichte", False);
		// Room rates change history
		vInfRegMgr = InformationRegisters.RoomRateChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Room rate changes history", "История изменений тарифов", "Zimmerpreisesänderungen geschichte", True);
		// Set room rate prices change history
		vInfRegMgr = InformationRegisters.SetRoomRatePricesChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Room rate prices specification changes history", "История изменений спецификаций цен тарифов", "Zimmerpreis Preise Spezifikation Änderungen Geschichte", True);
		// Set room rate formulas change history
		vInfRegMgr = InformationRegisters.SetRoomRateFormulasChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Room rate formulas specification changes history", "История изменений спецификаций формул тарифов", "Geschichte der Änderungen der Zimmerpreisformeln", True);
		// Set price tag ranges change history
		vInfRegMgr = InformationRegisters.SetPriceTagRangesChangeHistory;
		PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "Price tag ranges specification changes history", "История изменений спецификаций диапазонов признаков цен", "Preisschildbereiche Spezifikationsänderungen Historie", True);
	EndIf;
	// Process user actions history
	If PurgeUserActionsHistory Then
	    PurgeInformationRegisterHistory(pIsInteractive); 
	EndIf;
	// Purge platform change history versions
	If PurgePlatformChangeHistoryRecords Then
		PurgePlatformChangeHistoryRecords();
	EndIf;
	
	// Process clients without references
	If MarkClientsWithoutReferencesDeleted Then
		MarkClientsWithoutReferencesDeleted(pIsInteractive);
	EndIf;
	// Process client data scans
	If PurgeClientDataScans Then
		PurgeClientDataScans(pIsInteractive);
	EndIf;
	// Process client identification data
	If PurgeClientIdentificationData Then
		PurgeClientIdentificationData(pIsInteractive);
	EndIf;
	// Process program messages
	If PurgeMessages Then
		PurgeMessages(pIsInteractive);
	EndIf;
	// Process SMS messages
	If PurgeSMSMessages Then
		PurgeSMSDelivery(pIsInteractive);
		PurgeSMSMessagesBeingSent(pIsInteractive);
	EndIf;
	// Process on-line requests statistics
	If PurgeOnlineRequestStatistics Then
		PurgeOnlineRequestsStatistics(pIsInteractive);
	EndIf;
	// Process room rate daily prices
	If PurgeRoomRateDailyPrices Then
		PurgeRoomRateDailyPrices(pIsInteractive);
	EndIf;
	// Process external system integration logs
	If PurgeExternalSystemIntegrationLogs Then
		PurgeExternalSystemIntegrationLogs(pIsInteractive);
		PurgeFIASPriorityEvents(pIsInteractive);
	EndIf;
    // Process APDEX time measurements
	If PurgeAPDEXTimeMeasurements Then
		PurgeAPDEXTimeMeasurements(pIsInteractive);
	EndIf;
	If PurgeExchangePlanData Then
		PurgeExchangePlanData(pIsInteractive);	
	EndIf;  
	
	// Update client's age attribute
	pmUpdateClientsAge(pIsInteractive);
	WriteLogEvent(vFuncLogName, EventLogLevel.Information, Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure

// -----------------------------------------------------------------------------
//
// Parameters:
//  pIsInteractive	 - Boolean	 - is interactive use
//
Procedure pmUpdateClientsAge(pIsInteractive = False) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Client
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	NOT Clients.IsFolder
	|	AND NOT Clients.DeletionMark
	|	AND Clients.DateOfBirth <> &qEmptyDate
	|	AND DAY(Clients.DateOfBirth) = &qDay
	|	AND MONTH(Clients.DateOfBirth) = &qMonth
	|	AND YEAR(&qSessionDate) - YEAR(Clients.DateOfBirth) <> Clients.Age
	|
	|ORDER BY
	|	Clients.FullName";
	vDay = Day(CurrentSessionDate());
	vQry.SetParameter("qDay", vDay);
	vMonth = Month(CurrentSessionDate());
	vQry.SetParameter("qMonth", vMonth);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qSessionDate", CurrentSessionDate());
	vClients = vQry.Execute().Unload();
	For Each vClientsRow In vClients Do
		vCltObj = vClientsRow.Client.GetObject();
		vCltObj.Age = vCltObj.pmGetClientAge(CurrentSessionDate());
		vCltObj.AgeRange = vCltObj.pmGetClientAgeRange();
		vCltObj.Write();
		vCltObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		#IF CLIENT THEN
			If pIsInteractive Then
				Status(NStr("en='Processed '; de='Verarbeitet '; ru='Обработано '") + (vClients.IndexOf(vClientsRow) + 1) + NStr("en = ' cleints from '; de = ' Kunden von '; ru = ' клиентов из '") + vClients.Count() + "...");
				UserInterruptProcessing();
			EndIf;
		#ENDIF
	EndDo;
EndProcedure // pmUpdateClientsAge

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure DeleteDocumentsBatch(pDocsArray, pIsInteractive)
	// Check references to the objects
	vRefTab = FindByRef(pDocsArray);
	// Clear charges with references from the batch
	For Each vRefTabRow In vRefTab Do
		vDocRef = vRefTabRow[0];
		vDocRefIndex = pDocsArray.Find(vDocRef);
		If vDocRefIndex <> Undefined Then
			pDocsArray.Delete(vDocRefIndex);
		EndIf;
	EndDo;
	// Delete all documents left in one transaction  
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCount = pDocsArray.Count();
		For Each vDocRef In pDocsArray Do
			vDocObj = vDocRef.GetObject();
			vDocObj.DataExchange.Load = True;
			vDocObj.Delete();
		EndDo;
		
		// Log current state
		vMessage = NStr("ru='Удалено документов: " + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + "'; 
		                |de='Documents deleted: " + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + "'; 
						|en='Documents deleted: " + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + "'");
		WriteLogEvent(NStr("en = 'DataProcessor.ClearDatabase'; de = 'DataProcessor.ClearDatabase'; ru = 'Обработка.ОчисткаБазыДанных'"), EventLogLevel.Information, Metadata(), Undefined, vMessage);
		CommitTransaction();
	Except  
		RollbackTransaction();
		vErrMsg = ErrorDescription();
		AddWarningLog(pIsInteractive, vErrMsg);
	EndTry;
	pDocsArray.Clear();
EndProcedure // DeleteDocumentsBatch 

// -----------------------------------------------------------------------------
Procedure PurgeChargesMarkedForDeletion(pIsInteractive)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charge.Ref AS Ref
	|FROM
	|	Document.Charge AS Charge
	|WHERE
	|	Charge.Date <= &qPeriod
	|	AND Charge.DeletionMark
	|	AND (Charge.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	Charge.PointInTime";
	vQry.SetParameter("qPeriod", EndOfDay(Period));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vChargesQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	// Process charges by 1000 pieces in batch
	vDocsArray = New Array();
	While vChargesQryRes.Next() Do
		vDocsArray.Add(vChargesQryRes.Ref);
		// Check count
		If vDocsArray.Count() = 1000 Then
			DeleteDocumentsBatch(vDocsArray, pIsInteractive);
		EndIf;
	EndDo;
	DeleteDocumentsBatch(vDocsArray, pIsInteractive);
EndProcedure // PurgeChargesMarkedForDeletion

// -----------------------------------------------------------------------------
Procedure PurgeFoliosMarkedForDeletion(pIsInteractive)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.Date <= &qPeriod
	|	AND Folio.DeletionMark
	|	AND (Folio.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	Folio.PointInTime";
	vQry.SetParameter("qPeriod", EndOfDay(Period));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vFoliosQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	// Process folios by 1000 pieces in batch
	vDocsArray = New Array();
	While vFoliosQryRes.Next() Do
		vDocsArray.Add(vFoliosQryRes.Ref);
		// Check count
		If vDocsArray.Count() = 1000 Then
			DeleteDocumentsBatch(vDocsArray, pIsInteractive);
		EndIf;
	EndDo;
	DeleteDocumentsBatch(vDocsArray, pIsInteractive);
EndProcedure // PurgeFoliosMarkedForDeletion

// -----------------------------------------------------------------------------
Procedure PurgeChangeHistoryRecords(pIsInteractive, pInfRegMgr, pInfRegNameEn, pInfRegNameRu, pInfRegNameDe, pCheckHotel)
	vInfRegSel = pInfRegMgr.Select(, EndOfDay(Period));
	// Do in transaction
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCount = 0;
		
		While vInfRegSel.Next() Do
			// Check hotel
			If pCheckHotel Then
				If ValueIsFilled(Hotel) And ValueIsFilled(vInfRegSel.Hotel) Then
					If Hotel.IsFolder Then
						If Not vInfRegSel.Hotel.BelongsToItem(Hotel) Then
							Continue;
						EndIf;
					Else
						If vInfRegSel.Hotel <> Hotel Then
							Continue;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			vInfRegRecMgr = vInfRegSel.GetRecordManager();
			vInfRegRecMgr.Delete();
			vCount = vCount + 1;
			// Commit each 1000 records
			If vCount / 1000 = Int(vCount / 1000) Then
				CommitTransaction();
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndDo;
		
		// Log current state
		vMessage = NStr("ru='Удалено " + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + " записей регистра <" + pInfRegNameRu + ">'; 
		                |de='" + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + " <" + pInfRegNameDe + "> registereinträge gelöscht'; 
						|en='" + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + " <" + pInfRegNameEn + "> register records deleted'");
		WriteLogEvent(NStr("en='DataProcessor.ClearDatabase';ru='Обработка.ОчисткаБазыДанных';de='DataProcessor.ClearDatabase'"), EventLogLevel.Information, Metadata(), Undefined, vMessage);
		CommitTransaction();
	Except            
		RollbackTransaction();
		vErrMsg = ErrorDescription();
		AddWarningLog(pIsInteractive, vErrMsg);
	EndTry;
EndProcedure // PurgeChangeHistoryRecords

// -----------------------------------------------------------------------------
Procedure PurgeClientDataScans(pIsInteractive)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientDataScans.Ref AS Ref,
	|	ClientDataScans.Posted AS Posted
	|FROM
	|	Document.ClientDataScans AS ClientDataScans
	|WHERE
	|	ClientDataScans.Date <= &qPeriod
	|	AND (NOT &qClearProcessedOnly
	|			OR &qClearProcessedOnly
	|				AND ClientDataScans.Posted
	|				AND ClientDataScans.Status = &qProcessed)
	|	AND (ClientDataScans.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	ClientDataScans.PointInTime";
	vQry.SetParameter("qProcessed", Enums.ScanStatuses.IsProcessed);
	vQry.SetParameter("qClearProcessedOnly", ClearProcessedOnly);
	vQry.SetParameter("qPeriod", EndOfDay(Period));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vDocs = vQry.Execute().Select(QueryResultIteration.Linear);
	// Process data scans by 1000 pieces in batch
	vDocsArray = New Array();
	While vDocs.Next() Do
		If SaveClientDataScans2Disc Then
			If Not vDocs.Posted Then
				vDocsArray.Add(vDocs.Ref);
			Else
				vClientDataScanRef = vDocs.Ref;
				If vClientDataScanRef.ScanPictures.Count() > 0 Then
					vClientDataScanObj = vClientDataScanRef.GetObject();
					vInd = 0;
					While vInd < vClientDataScanObj.ScanPictures.Count() Do
						vPictRow = vClientDataScanObj.ScanPictures.Get(vInd);
						vPicture = vPictRow.ScanPicture.Get();
						If vPicture = Undefined Then
							vClientDataScanObj.ScanPictures.Delete(vInd);
							Continue;
						ElsIf TypeOf(vPicture) = Type("Picture") Then
							// Save picture to disk
							vCatalogName = "";
							vFileName = vClientDataScanObj.pmGetImageFileName(vPictRow, vCatalogName);
							vCatalog = New File(vCatalogName);
							If Not tcCommonFunctionOnClientServer.cmExists(vCatalog) Then
								CreateDirectory(vCatalogName);
							EndIf;
							vPicture.Write(vCatalogName + vFileName);
							
							// Add new row as copy of old one except picture
							vNewPictRow = vClientDataScanObj.ScanPictures.Insert(vInd+1);
							FillPropertyValues(vNewPictRow, vPictRow, , "LineNumber, ScanPicture");
							vNewPictRow.ScanPicture = New ValueStorage(vFileName);
							
							// Delete old one to be able to release space used by picture after database shrink
							vClientDataScanObj.ScanPictures.Delete(vInd);
						EndIf;
						vInd = vInd + 1;
					EndDo;
					vClientDataScanObj.Write(DocumentWriteMode.Write);
				Else
					vDocsArray.Add(vDocs.Ref);
				EndIf;
			EndIf;
		Else
			vDocsArray.Add(vDocs.Ref);
		EndIf;
		// Check count
		If vDocsArray.Count() = 1000 Then
			DeleteDocumentsBatch(vDocsArray, pIsInteractive);
		EndIf;
	EndDo;
	DeleteDocumentsBatch(vDocsArray, pIsInteractive);
EndProcedure // PurgeClientDataScans

// -----------------------------------------------------------------------------
Procedure PurgeClientIdentificationDataFromStructure(pObj)
	pObj.IdentityDocumentIssueDate = Undefined;
	pObj.IdentityDocumentIssuedBy = "";
	pObj.IdentityDocumentNumber = "";
	pObj.IdentityDocumentSeries = "";
	pObj.IdentityDocumentValidToDate = Undefined; 
	pObj.IdentityDocumentUnitCode = "";   
	pObj.AddressRegistrationDate = Undefined;
	pObj.AddressRegistrationDateTo = Undefined;
	pObj.PostalAddress = ""; 
	pObj.PlaceOfBirth = ""; 
	pObj.SocialSecurityNumber = "";
	pObj.PolicyOfMedicalInsurance = "";
	pObj.AmbulatoryCard = "";
	pObj.PersonalNumber = "";
    pObj.Photo = Undefined; 
	pObj.Signature = Undefined;
    pObj.AddressPresentation = "";
	pObj.IdentityDocumentPresentation = "";
	pObj.TIN = "";
	pObj.Phone = "";
	pObj.EMail = "";
	pObj.Fax = "";
	pObj.EMailAdditional = "";
EndProcedure // PurgeClientIdentificationDataFromStructure

// -----------------------------------------------------------------------------
Procedure PurgeClientAddress(pObj)
	// Clear street, house, flat from guest address and leave region and city to save geo analitics
	vAddressStruct = cmParseAddress(pObj.Address);
	vAddressStruct.Street = "";
	vAddressStruct.House = "";
	vAddressStruct.Flat = "";
	pObj.Address = cmBuildAddress(vAddressStruct.Country, vAddressStruct.PostCode, vAddressStruct.Region, vAddressStruct.Area, vAddressStruct.City);
EndProcedure // PurgeClientAddress

// -----------------------------------------------------------------------------
Procedure MarkClientsWithoutReferencesDeleted(pIsInteractive)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Ref,
	|	Clients.Code AS Code,
	|	Clients.FullName AS FullName,
	|	GuestAccommodations.Guest AS AccommodationGuest,
	|	GuestReservations.Guest AS ReservationGuest,
	|	GuestResourceReservations.Client AS ResourceReservationClient,
	|	Foreigners.Guest AS ForeignersGuest,
	|	GuestFolios.Client AS FoliosClient
	|FROM
	|	Catalog.Clients AS Clients
	|		LEFT JOIN Document.Accommodation AS GuestAccommodations
	|		ON Clients.Ref = GuestAccommodations.Guest
	|		LEFT JOIN Document.Reservation AS GuestReservations
	|		ON Clients.Ref = GuestReservations.Guest
	|		LEFT JOIN Document.ResourceReservation AS GuestResourceReservations
	|		ON Clients.Ref = GuestResourceReservations.Client
	|		LEFT JOIN Document.ForeignerRegistryRecord AS Foreigners
	|		ON Clients.Ref = Foreigners.Guest
	|		LEFT JOIN Document.Folio AS GuestFolios
	|		ON Clients.Ref = GuestFolios.Client
	|WHERE
	|	Clients.CreateDate <= &qPeriod
	|	AND NOT Clients.IsFolder
	|	AND NOT Clients.DeletionMark
	|	AND NOT Clients.IsInBlackList
	|	AND NOT Clients.IsInWhiteList
	|	AND Clients.IdentityDocumentNumber = &qEmptyString
	|	AND GuestAccommodations.Guest IS NULL
	|	AND GuestReservations.Guest IS NULL
	|	AND GuestResourceReservations.Client IS NULL
	|	AND Foreigners.Guest IS NULL
	|	AND GuestFolios.Client IS NULL
	|
	|ORDER BY
	|	Clients.CreateDate";
	vQry.SetParameter("qPeriod", EndOfDay(Period));
	vQry.SetParameter("qEmptyString", "");
	vClients = vQry.Execute().Select(QueryResultIteration.Linear);
	// Process clients
	vClientRef = Undefined;
	While vClients.Next() Do
		Try
			vClientObj = vClients.Ref.GetObject();
			vClientObj.DataExchange.Load = True;
			vClientObj.SetDeletionMark(True);
			WriteLogEvent(NStr("en='DataProcessor.ClearDatabase';ru='Обработка.ОчисткаБазыДанных';de='DataProcessor.ClearDatabase'"), EventLogLevel.Information, vClients.Ref.Metadata(), vClients.Ref, NStr("en='Client is marked for deletion: ';ru='Клиент помечен на удаление: ';de='Der Kunde ist zum Löschen markiert: '") + TrimAll(vClients.FullName) + " (" + TrimAll(vClients.Code) + ")");
		Except
			vErrMsg = NStr("en = 'Error trying to mark client deleted: '; de = 'Fehler bei der Markierung des Kunden zum Löschen: '; ru = 'Ошибка пометки клиента на удаление: '") + TrimAll(vClients.FullName) + " (" + TrimAll(vClients.Code) + ")" + Chars.LF + ErrorDescription();
			AddWarningLog(pIsInteractive, vErrMsg);		
		EndTry;
	EndDo;
EndProcedure // MarkClientsWithoutReferencesDeleted

// -----------------------------------------------------------------------------
Procedure PurgeClientIdentificationData(pIsInteractive)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Ref,
	|	Clients.Code AS Code,
	|	Clients.FullName AS FullName,
	|	LastCheckOuts.CheckOutDate AS CheckOutDate,
	|	Foreigners.Ref AS ForeignerRegistryRecord
	|FROM
	|	Catalog.Clients AS Clients
	|		LEFT JOIN (SELECT
	|			Accommodations.Guest AS Guest,
	|			MAX(Accommodations.CheckOutDate) AS CheckOutDate
	|		FROM
	|			Document.Accommodation AS Accommodations
	|		WHERE
	|			Accommodations.Posted
	|			AND Accommodations.AccommodationStatus.IsActive
	|		
	|		GROUP BY
	|			Accommodations.Guest) AS LastCheckOuts
	|		ON Clients.Ref = LastCheckOuts.Guest
	|		LEFT JOIN Document.ForeignerRegistryRecord AS Foreigners
	|		ON Clients.Ref = Foreigners.Guest
	|WHERE
	|	Clients.CreateDate <= &qPeriod
	|	AND NOT Clients.IsFolder
	|	AND Clients.IdentityDocumentNumber > &qEmptyString
	|	AND ISNULL(LastCheckOuts.CheckOutDate, &qEmptyDate) <= &qPeriod
	|
	|ORDER BY
	|	Clients.CreateDate";
	vQry.SetParameter("qPeriod", EndOfDay(Period));
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyDate", '00010101');
	vClients = vQry.Execute().Select(QueryResultIteration.Linear);
	// Process clients
	vRecMgr = InformationRegisters.ClientChangeHistory.CreateRecordManager();
	vForRecMgr = InformationRegisters.ForeignerRegistryRecordChangeHistory.CreateRecordManager();
	While vClients.Next() Do   
		BeginTransaction(DataLockControlMode.Managed);
		Try
			vClientObj = vClients.Ref.GetObject();
			If Not IsBlankString(vClientObj.IdentityDocumentNumber) Then
				PurgeClientIdentificationDataFromStructure(vClientObj);
				PurgeClientAddress(vClientObj);
				// Save changes
				vClientObj.Write();
				// Clear client change history records
				vCCHQry = New Query();
				vCCHQry.Text = 
				"SELECT
				|	ClientChangeHistory.Period AS Period,
				|	ClientChangeHistory.Client AS Client
				|FROM
				|	InformationRegister.ClientChangeHistory AS ClientChangeHistory
				|WHERE
				|	ClientChangeHistory.Client = &qClient
				|
				|ORDER BY
				|	Period";
				vCCHQry.SetParameter("qClient", vClientObj.Ref);
				vCCHRows = vCCHQry.Execute().Unload();
				For Each vCCHRow In vCCHRows Do
					vRecMgr.Period = vCCHRow.Period;
					vRecMgr.Client = vClientObj.Ref;
					vRecMgr.Read();
					If vRecMgr.Selected() Then
						PurgeClientIdentificationDataFromStructure(vRecMgr);
						PurgeClientAddress(vRecMgr);
						// Save changes
						vRecMgr.Write(True);
					EndIf;
				EndDo;
			EndIf;
			// Clear client foreigner registry record
			If ValueIsFilled(vClients.ForeignerRegistryRecord) Then
				vDocObj = vClients.ForeignerRegistryRecord.GetObject();
				PurgeClientIdentificationDataFromStructure(vDocObj);
				// Save changes
				vDocObj.Write(DocumentWriteMode.Write);
				// Clear foreigner registry record change history records
				vCHQry = New Query();
				vCHQry.Text = 
				"SELECT
				|	ForeignerRegistryRecordChangeHistory.Period AS Period,
				|	ForeignerRegistryRecordChangeHistory.ForeignerRegistryRecord AS ForeignerRegistryRecord
				|FROM
				|	InformationRegister.ForeignerRegistryRecordChangeHistory AS ForeignerRegistryRecordChangeHistory
				|WHERE
				|	ForeignerRegistryRecordChangeHistory.ForeignerRegistryRecord = &qForeignerRegistryRecord
				|
				|ORDER BY
				|	Period";
				vCHQry.SetParameter("qForeignerRegistryRecord", vDocObj.Ref);
				vCHRows = vCHQry.Execute().Unload();
				For Each vCHRow In vCHRows Do
					vForRecMgr.Period = vCHRow.Period;
					vForRecMgr.ForeignerRegistryRecord = vDocObj.Ref;
					vForRecMgr.Read();
					If vForRecMgr.Selected() Then
						PurgeClientIdentificationDataFromStructure(vForRecMgr);
						// Save changes
						vForRecMgr.Write(True);
					EndIf;
				EndDo;
			EndIf;
			vMsgErr = StrTemplate(NStr("en = 'Indentification data were cleared for the client %1 (%2)'; 
									   |de = 'Identifikationsdaten des Kunden wurden gelöscht %1 (%2)'; 
									   |ru = 'Очищены идентификационные данные клиента %1 (%2)'"), TrimAll(vClients.FullName), TrimAll(vClients.Code));
			WriteLogEvent(NStr("en = 'DataProcessor.ClearDatabase'; de = 'DataProcessor.ClearDatabase'; ru = 'Обработка.ОчисткаБазыДанных'"), EventLogLevel.Information, vClients.Ref.Metadata(), vClients.Ref, vMsgErr);
			CommitTransaction();
		Except           
			RollbackTransaction();
			vErrMsg = ErrorDescription();
			AddWarningLog(pIsInteractive, vErrMsg);		
		EndTry;
	EndDo;
EndProcedure // PurgeClientIdentificationData

// -----------------------------------------------------------------------------
Procedure PurgeMessages(pIsInteractive)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Message.Ref AS Ref
	|FROM
	|	Document.Message AS Message
	|WHERE
	|	Message.Date <= &qPeriod
	|
	|ORDER BY
	|	Message.PointInTime";
	vQry.SetParameter("qPeriod", EndOfDay(Period));
	vDocs = vQry.Execute().Select(QueryResultIteration.Linear);
	// Process documents by 1000 pieces in batch
	vDocsArray = New Array();
	While vDocs.Next() Do
		vDocsArray.Add(vDocs.Ref);
		// Check count
		If vDocsArray.Count() = 1000 Then
			DeleteDocumentsBatch(vDocsArray, pIsInteractive);
		EndIf;
	EndDo;
	DeleteDocumentsBatch(vDocsArray, pIsInteractive);
EndProcedure // PurgeMessages

// -----------------------------------------------------------------------------
Procedure PurgeSMSDelivery(pIsInteractive)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SMSDelivery.Ref
	|FROM
	|	Document.SMSDelivery AS SMSDelivery
	|WHERE
	|	SMSDelivery.Date <= &qPeriod
	|	AND (SMSDelivery.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	SMSDelivery.PointInTime";
	vQry.SetParameter("qPeriod", EndOfDay(Period));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vDocs = vQry.Execute().Select(QueryResultIteration.Linear);
	// Process documents by 1000 pieces in batch
	vDocsArray = New Array();
	While vDocs.Next() Do
		vDocsArray.Add(vDocs.Ref);
		// Check count
		If vDocsArray.Count() = 1000 Then
			DeleteDocumentsBatch(vDocsArray, pIsInteractive);
		EndIf;
	EndDo;
	DeleteDocumentsBatch(vDocsArray, pIsInteractive);
EndProcedure // PurgeSMSDelivery

// -----------------------------------------------------------------------------
Procedure PurgeSMSMessagesBeingSent(pIsInteractive)
	vInfRegSel = InformationRegisters.SMSMessages.Select(, EndOfDay(Period));
	// Do in transaction
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCount = 0;
		While vInfRegSel.Next() Do
			vInfRegRecMgr = vInfRegSel.GetRecordManager();
			vInfRegRecMgr.Delete();
			vCount = vCount + 1;
			// Commit each 1000 records
			If vCount / 1000 = Int(vCount / 1000) Then
				CommitTransaction();
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndDo;
		// Log current state
		vMessage = NStr("ru='Удалено записей регистра истории отправленных СМС: " + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + "'; 
		                |de='SMS messages being sent records deleted: " + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + "'; 
						|en='SMS messages being sent records deleted: " + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + "'");
		WriteLogEvent(NStr("en='DataProcessor.ClearDatabase';ru='Обработка.ОчисткаБазыДанных';de='DataProcessor.ClearDatabase'"), EventLogLevel.Information, Metadata(), Undefined, vMessage);
		CommitTransaction();
	Except
		RollbackTransaction();
		
		vErrMsg = ErrorDescription();
		AddWarningLog(pIsInteractive, vErrMsg);
	EndTry;
EndProcedure // PurgeSMSMessagesBeingSent

// -----------------------------------------------------------------------------
Procedure PurgeOnlineRequestsStatistics(pIsInteractive)
	vInfRegSel = InformationRegisters.OnlineRequests.Select(, EndOfDay(Period));
	// Do in transaction 
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCount = 0;
		While vInfRegSel.Next() Do
			vInfRegRecMgr = vInfRegSel.GetRecordManager();
			vInfRegRecMgr.Delete();
			vCount = vCount + 1;
			// Commit each 1000 records
			If vCount / 1000 = Int(vCount / 1000) Then
				CommitTransaction();
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndDo;
		
		// Log current state
		vMessage = NStr("ru='Удалено записей регистра статистики он-лайн запросов: " + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + "'; 
		                |de='Gelöschte Einträge im Statistikregister der Online-Anfragen: " + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + "'; 
						|en='Deleted entries in the statistics register of online requests: " + Format(vCount, "ND=17; NFD=0; NZ=; NG=") + "'");
		WriteLogEvent(NStr("en = 'DataProcessor.ClearDatabase'; de = 'DataProcessor.ClearDatabase'; ru = 'Обработка.ОчисткаБазыДанных'"), EventLogLevel.Information, Metadata(), Undefined, vMessage);
		CommitTransaction();
	Except
		RollbackTransaction();
		
		vErrMsg = ErrorDescription();
		AddWarningLog(pIsInteractive, vErrMsg);
	EndTry;
EndProcedure // PurgeOnlineRequestsStatistics

// -----------------------------------------------------------------------------
Procedure PurgeRoomRateDailyPrices(pIsInteractive)
	vInfRegSel = InformationRegisters.RoomRateDailyPrices.Select(, EndOfDay(Period));
	// Do in transaction   
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCount = 0;
		While vInfRegSel.Next() Do
			vInfRegRecMgr = vInfRegSel.GetRecordManager();
			vInfRegRecMgr.Delete();
			vCount = vCount + 1;
			// Commit each 1000 records
			If vCount / 1000 = Int(vCount / 1000) Then
				CommitTransaction();
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndDo;
		// Log current state
		vMessage = NStr("en = 'Deleted entries in the room rate daily prices: %1'; 
								|de = 'Gelöschte Einträge im Zimmerpreis Tagespreise: %1'; 
								|ru = 'Удалено записей регистра цен по дням: %1'");
		
		WriteLogEvent(NStr("en = 'DataProcessor.ClearDatabase'; de = 'DataProcessor.ClearDatabase'; ru = 'Обработка.ОчисткаБазыДанных'"), EventLogLevel.Information, Metadata(), Undefined, StrTemplate(vMessage, Format(vCount, "ND=17; NFD=0; NZ=; NG=")));
		CommitTransaction(); 
	Except     
		RollbackTransaction();
		
		vErrMsg = ErrorDescription();
		AddWarningLog(pIsInteractive, vErrMsg);
	EndTry;
EndProcedure // PurgeRoomRateDailyPrices()

// -----------------------------------------------------------------------------
Procedure PurgeExternalSystemIntegrationLogs(pIsInteractive)  
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemIntegrationLogs.Period AS Period,
	|	ExternalSystemIntegrationLogs.ExternalSystem AS ExternalSystem
	|FROM
	|	InformationRegister.ExternalSystemIntegrationLogs AS ExternalSystemIntegrationLogs
	|WHERE
	|	CASE
	|			WHEN &qExternalSystem = VALUE(Catalog.ExternalSystemInteractions.Emptyref)
	|				THEN TRUE
	|			ELSE ExternalSystemIntegrationLogs.ExternalSystem = &qExternalSystem
	|		END
	|	AND ExternalSystemIntegrationLogs.Period <= &qPeriodTo
	|
	|GROUP BY
	|	ExternalSystemIntegrationLogs.Period,
	|	ExternalSystemIntegrationLogs.ExternalSystem";
	
	vQuery.SetParameter("qPeriodTo", EndOfDay(Period));
	vQuery.SetParameter("qExternalSystem", ExternalInteraction);
	
	vResult = vQuery.Execute();
	
	vInfRegSel = vResult.Select();
	
	// Do in transaction
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCount = 0;
		While vInfRegSel.Next() Do
			vRecordSet	= InformationRegisters.ExternalSystemIntegrationLogs.CreateRecordSet();
			vRecordSet.Filter.ExternalSystem.Set(vInfRegSel.ExternalSystem);
			vRecordSet.Filter.Period.Set(vInfRegSel.Period);
			vRecordSet.Write();
			
			vCount = vCount + 1;
			// Commit each 1000 records
			If vCount / 1000 = Int(vCount / 1000) Then
				CommitTransaction();
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndDo;
		// Log current state
		vMessage = NStr("en = 'Removed log entries with external systems: %1'; de = 'Protokolleinträge mit externen Systemen entfernt: %1'; ru = 'Удалено записей логов с внешними системами: %1'");
		
		WriteLogEvent(NStr("en = 'DataProcessor.ClearDatabase'; de = 'DataProcessor.ClearDatabase'; ru = 'Обработка.ОчисткаБазыДанных'"), EventLogLevel.Information, Metadata(), Undefined, StrTemplate(vMessage, Format(vCount, "ND=17; NFD=0; NZ=; NG=")));   
		CommitTransaction();
	Except
		RollbackTransaction();
		
		vErrMsg = ErrorDescription();
		AddWarningLog(pIsInteractive, vErrMsg);
	EndTry;
EndProcedure // PurgeExternalSystemIntegrationLogs()

// -----------------------------------------------------------------------------
Procedure PurgeFIASPriorityEvents(pIsInteractive)  
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	FIASPriorityEvents.CommandUUID AS CommandUUID,
	|	FIASPriorityEvents.InteractionParameters AS InteractionParameters
	|FROM
	|	InformationRegister.FIASPriorityEvents AS FIASPriorityEvents
	|WHERE
	|	CASE
	|			WHEN &qExternalSystem = VALUE(Catalog.ExternalSystemInteractions.Emptyref)
	|				THEN TRUE
	|			ELSE FIASPriorityEvents.InteractionParameters = &qExternalSystem
	|		END
	|	AND FIASPriorityEvents.Date <= &qPeriodTo
	|
	|GROUP BY
	|	FIASPriorityEvents.CommandUUID,
	|	FIASPriorityEvents.InteractionParameters";
	
	vQuery.SetParameter("qPeriodTo", EndOfDay(Period));
	vQuery.SetParameter("qExternalSystem", ExternalInteraction);
	
	vResult = vQuery.Execute();
	
	vInfRegSel = vResult.Select();
	
	// Do in transaction  
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCount = 0;
		While vInfRegSel.Next() Do
			InformationRegisters.FIASPriorityEvents.DeleteEvent(vInfRegSel.CommandUUID, vInfRegSel.InteractionParameters); 
			
			vCount = vCount + 1;
			// Commit each 1000 records
			If vCount / 1000 = Int(vCount / 1000) Then
				CommitTransaction();
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndDo;
		              
		// Log current state
		vMessage = NStr("en = 'Removed log entries with FIAS: %1'; de = 'Protokolleinträge mit FIAS: %1'; ru = 'Удалено записей логов с FIAS: %1'");
		
		WriteLogEvent(NStr("en = 'DataProcessor.ClearDatabase'; de = 'DataProcessor.ClearDatabase'; ru = 'Обработка.ОчисткаБазыДанных'"), EventLogLevel.Information, Metadata(), Undefined, StrTemplate(vMessage, Format(vCount, "ND=17; NFD=0; NZ=; NG=")));
		CommitTransaction();
	Except
		RollbackTransaction();
		
		vErrMsg = ErrorDescription();
		AddWarningLog(pIsInteractive, vErrMsg);
	EndTry;
EndProcedure // PurgeExternalSystemIntegrationFIASPriorityEvents()

// -----------------------------------------------------------------------------
Procedure PurgeAPDEXTimeMeasurements(pIsInteractive)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	APDEXTimeMeasurements.KeyOperation AS KeyOperation,
		|	APDEXTimeMeasurements.DateFrom AS DateFrom,
		|	APDEXTimeMeasurements.SessionNumber AS SessionNumber,
		|	APDEXTimeMeasurements.Hotel AS Hotel,
		|	APDEXTimeMeasurements.Duration AS Duration,
		|	APDEXTimeMeasurements.Remarks AS Remarks,
		|	APDEXTimeMeasurements.Weight AS Weight,
		|	APDEXTimeMeasurements.Date AS Date,
		|	APDEXTimeMeasurements.DateTo AS DateTo,
		|	APDEXTimeMeasurements.User AS User,
		|	APDEXTimeMeasurements.PeriodUTC AS PeriodUTC
		|FROM
		|	InformationRegister.APDEXTimeMeasurements AS APDEXTimeMeasurements
		|WHERE
		|	APDEXTimeMeasurements.PeriodUTC <= &qPeriodTo
		|	AND CASE
		|			WHEN &qHotel = VALUE(Catalog.Hotels.Emptyref)
		|				THEN TRUE
		|			ELSE APDEXTimeMeasurements.Hotel = &qHotel
		|		END";
	
	vQuery.SetParameter("qPeriodTo", EndOfDay(Period));
	vQuery.SetParameter("qHotel", Hotel);
	
	vResult = vQuery.Execute();
	
	vInfRegSel = vResult.Select();

	// Do in transaction   
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCount = 0;
		While vInfRegSel.Next() Do
			vRecordSet	= InformationRegisters.APDEXTimeMeasurements.CreateRecordSet();
			vRecordSet.Filter.KeyOperation.Set(vInfRegSel.KeyOperation);
			vRecordSet.Filter.DateFrom.Set(vInfRegSel.DateFrom);
			vRecordSet.Filter.SessionNumber.Set(vInfRegSel.SessionNumber);
			vRecordSet.Filter.Hotel.Set(vInfRegSel.Hotel);
			vRecordSet.Write();

			vCount = vCount + 1;
			// Commit each 1000 records
			If vCount / 1000 = Int(vCount / 1000) Then
				CommitTransaction();
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndDo;
		CommitTransaction();              
		// Log current state
		vMessageTemplate = NStr("en = 'Removed measurement records APDEX: %1'; de = 'Entfernte Messdatensätze APDEX: %1'; ru = 'Удалено записей замеров APDEX: %1'");
		vMessage = StrTemplate(vMessageTemplate, Format(vCount, "ND=17; NFD=0; NZ=; NG="));
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
		EndIf;

		WriteLogEvent(NStr("en='DataProcessor.ClearDatabase';ru='Обработка.ОчисткаБазыДанных';de='DataProcessor.ClearDatabase'"), EventLogLevel.Information, Metadata(), Undefined, vMessage);
	Except
		RollbackTransaction();
		
		vErrMsg = ErrorDescription();
		AddWarningLog(pIsInteractive, vErrMsg);
	EndTry;
EndProcedure // PurgeAPDEXTimeMeasurements()

// -----------------------------------------------------------------------------
Procedure PurgeExchangePlanData(pIsInteractive)  
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExchangePlanData.MessageNo AS MessageNo,
	|	ExchangePlanData.SenderNode AS SenderNode,
	|	ExchangePlanData.ReceiverNode AS ReceiverNode
	|FROM
	|	InformationRegister.ExchangePlanData AS ExchangePlanData
	|WHERE
	|	(ExchangePlanData.IsSent
	|				AND ExchangePlanData.DateSent <= &qPeriodTo
	|			OR ExchangePlanData.IsReceived
	|				AND ExchangePlanData.IsLoaded
	|				AND ExchangePlanData.DateLoaded <= &qPeriodTo)";
	
	vQuery.SetParameter("qPeriodTo", EndOfDay(Period));
	
	vResult = vQuery.Execute();
	
	vInfRegSel = vResult.Select();
	
	// Do in transaction
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCount = 0;
		While vInfRegSel.Next() Do
			vRecordSet	= InformationRegisters.ExchangePlanData.CreateRecordSet();
			vRecordSet.Filter.MessageNo.Set(vInfRegSel.MessageNo);
			vRecordSet.Filter.SenderNode.Set(vInfRegSel.SenderNode);
			vRecordSet.Filter.ReceiverNode.Set(vInfRegSel.ReceiverNode);
			vRecordSet.Write();
			
			vCount = vCount + 1;
			// Commit each 1000 records
			If vCount / 1000 = Int(vCount / 1000) Then
				CommitTransaction();
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndDo;
		              
		CommitTransaction();
	Except
		RollbackTransaction();
		
		vErrMsg = ErrorDescription();
		AddWarningLog(pIsInteractive, vErrMsg);
	EndTry;
EndProcedure // PurgeExchangePlanData()

// -----------------------------------------------------------------------------
Procedure PurgePlatformChangeHistoryRecords()
	For Each vCatalogItem In Metadata.Catalogs Do
		If vCatalogItem.DataHistory = Metadata.ObjectProperties.DataHistoryUse.Use Then
			DataHistory.DeleteVersions(vCatalogItem, Period);
		EndIf;
	EndDo;
	For Each vDocumentItem In Metadata.Documents Do
		If vDocumentItem.DataHistory = Metadata.ObjectProperties.DataHistoryUse.Use Then
			DataHistory.DeleteVersions(vDocumentItem, Period);
		EndIf;
	EndDo;
	For Each vInfRegItem In Metadata.InformationRegisters Do
		If vInfRegItem.DataHistory = Metadata.ObjectProperties.DataHistoryUse.Use Then
			DataHistory.DeleteVersions(vInfRegItem, Period);
		EndIf;
	EndDo;
EndProcedure // PurgePlatformChangeHistoryRecords

// -----------------------------------------------------------------------------
//
// Parameters:
//  pIsInteractive	 - Boolean - Is interactive action
//
Procedure PurgeInformationRegisterHistory(pIsInteractive)         
	// User actions history
	vInfRegMgr = InformationRegisters.UserActionsHistory;
	PurgeChangeHistoryRecords(pIsInteractive, vInfRegMgr, "User actions history", "История действий пользователей", "Benutzeraktionenverlauf", True);
EndProcedure

// -----------------------------------------------------------------------------
Procedure AddWarningLog(Val pIsInteractive, pErrMsg)
	WriteLogEvent(NStr("en = 'DataProcessor.ClearDatabase'; de = 'DataProcessor.ClearDatabase'; ru = 'Обработка.ОчисткаБазыДанных'"), EventLogLevel.Warning, Metadata(), Undefined, pErrMsg);
	If pIsInteractive Then
		tcCommonFunctionOnClientServer.TextMessage(pErrMsg, MessageStatus.Attention);
	EndIf;
EndProcedure

#EndRegion 
