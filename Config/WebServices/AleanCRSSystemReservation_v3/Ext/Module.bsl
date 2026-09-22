#Region EventHandlers 

// -----------------------------------------------------------------------------
Function ActivateInteraction(pInteractionID)
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.ActivateInteraction'; de='AleanCRSSystem_v3.ActivateInteraction'; ru='AleanCRSSystem_v3.ActivateInteraction'"), 
					EventLogLevel.Information, 
					, 
					Undefined, 
					NStr("en='Input parameters: ';ru='Входные параметры: ';de='Input parameters: '")+Chars.LF+
					"InteractionID: "+pInteractionID);
	// Try to find existing interaction by id
	vInteractionObj = Undefined;
	vInteractions = cmGetInteractionByID(pInteractionID, True);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteractionObj = vInteractions.Get(0).Ref.GetObject();
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	vInteractionObj.IsActive = True;
	vInteractionObj.Write();
	
	vExternalInteraction = vInteractionObj.Ref;
    If vExternalInteraction.DebugMode Then
        InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExternalInteraction, "ActivateInteraction", Enums.ExternalSystemEventTypes.Info, , , "IsActive = True", vExternalInteraction.MaxLogLenght);
    EndIf;
    
	// After switching on, you need to perform a full synchronization.
	vParametersDataProcessor = New Structure;
	vParametersDataProcessor.Insert("ForceFullSynchronization",True);
	vParametersDataProcessor.Insert("SynchronizationRoomPrices",True);
	vParametersDataProcessor.Insert("ForceFullRoomPricesSynchronization",True);
	
	vProcedureParametrs    = New Array;
	vTempStorageAdress 	 	= PutToTempStorage(Null);
	vProcedureParametrs.Add("AleanCRSSystemInventorySynchronization3");
	vProcedureParametrs.Add(vParametersDataProcessor);
	
	If vExternalInteraction.DebugMode Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExternalInteraction, "ActivateInteraction", Enums.ExternalSystemEventTypes.Warning, , , "StartBackgroundJob.AleanCRSSystemInventorySynchronization3", vExternalInteraction.MaxLogLenght);
	EndIf;
	
	vBackgroundJob	= AsyncCalls.StartBackgroundJob("ProlongedOperations.RunDataProcessor", vProcedureParametrs, vTempStorageAdress);
	Return Undefined;
EndFunction // ActivateInteraction

// -----------------------------------------------------------------------------
Function CancelReservation(pInteractID, pReservationNumber, pReservationDataXML)
	vInteraction = Undefined;
	vInteractions = cmGetInteractionByID(pInteractID);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteraction = vInteractions.Get(0).Ref;
		If Not vInteraction.IsActive Then
			vMsg = NStr("en='Interaction with given interaction ID is not active!'; de='Interaction with given interaction ID is not active!'; ru='Взаимодействие с переданным идентификатором не активно!'")+ ": "+pInteractID ;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "CancelReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
			Raise vMsg; 
		EndIf;
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	
	If vInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'")+ Chars.LF + 
			"pInteractID: " + pInteractID + Chars.LF +
			"pReservationNumber: " + pReservationNumber;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "CancelReservation", Enums.ExternalSystemEventTypes.Info, pReservationDataXML, , vMsg);
	EndIf;

	
	// Try to parse XML data into DOM object 
	vReader = New XMLReader();
	vReader.SetString(pReservationDataXML);
	vDOMBuilder = New DOMBuilder();
	vDOMObj = vDOMBuilder.Read(vReader);
	
	// Try to read main reservation data from the root element attributes
	vReservationItems = vDOMObj.GetElementByTagName("Reservation");
	If vReservationItems.Count() = 0 Then
		vMsg = NStr("en='Main <Reservation> element is missing in the XML data!'; de='Main <Reservation> element is missing in the XML data!'; ru='В XML данных не найден элемент <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "CancelReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	ElsIf vReservationItems.Count() > 1 Then
		vMsg = NStr("en='More then one <Reservation> element is found in the XML data!'; de='More then one <Reservation> element is found in the XML data!'; ru='В XML данных найдено более одного элемента <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "CancelReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	vReservationItem = vReservationItems.Item(0);
	
	vCancelReservationResult = DoCancelReservation(vInteraction, vReservationItem);
	
	// Close reader
	vReader.Close();
	
	// Return success
	If vInteraction.DebugMode Then
		vMessage =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "CancelReservation", Enums.ExternalSystemEventTypes.Success, ,vCancelReservationResult, vMessage);
	EndIf;
	
	Return vCancelReservationResult;
EndFunction // CancelReservation

// -----------------------------------------------------------------------------
Function DeactivateInteraction(pInteractionID)
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.DeactivateInteraction'; de='AleanCRSSystem_v3.DeactivateInteraction'; ru='AleanCRSSystem_v3.DeactivateInteraction'"), 
					EventLogLevel.Information, 
					, 
					Undefined, 
					NStr("en='Input parameters: ';ru='Входные параметры: ';de='Input parameters: '")+Chars.LF+
					"InteractionID: "+pInteractionID);
	
	// Try to find existing interaction by id
	vInteractionObj = Undefined;
	vInteractions = cmGetInteractionByID(pInteractionID, True);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteractionObj = vInteractions.Get(0).Ref.GetObject();
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	vInteractionObj.IsActive = False;
	vInteractionObj.Write();
	
	InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionObj.Ref, "DeactivateInteraction", Enums.ExternalSystemEventTypes.Info, , , "IsActive = False");
	
	Return Undefined;
EndFunction // DeactivateInteraction

// -----------------------------------------------------------------------------
Function GetExternalList()
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.GetExternalList'; de='AleanCRSSystem_v3.GetExternalList'; ru='AleanCRSSystem_v3.GetExternalList'"), 
					EventLogLevel.Information, 
					, 
					Undefined);
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalSystemInteractions.Ref AS Ref
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	NOT ExternalSystemInteractions.DeletionMark
	|	AND NOT ExternalSystemInteractions.IsFolder
	|	AND ExternalSystemInteractions.IntegrationType = &qIntegrationType";
	vQry.SetParameter("qIntegrationType", Enums.Integrations.AleanCRS);
	vInteractions = vQry.Execute().Unload();
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterExternalList", "GetExternalList"));
	vRetXDTO.ExternalList = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterExternalList", "ExternalList"));
	vRetRowType = XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterExternalList", "ExternalItem");
	For Each vInteractionsRow In vInteractions Do
		vInteraction = vInteractionsRow.Ref;
		vRetRow = XDTOFactory.Create(vRetRowType);
		vRetRow.ExternalID = TrimR(vInteraction.Code);
		vRetRow.ExternalName = TrimR(vInteraction.Description);
		vRetXDTO.ExternalList.ExternalItem.Add(vRetRow);
	EndDo;
	Return vRetXDTO;
EndFunction // GetExternalList

// -----------------------------------------------------------------------------
Function GetTranslationTable(pInteractionID)
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.GetTranslationTable'; de='AleanCRSSystem_v3.GetTranslationTable'; ru='AleanCRSSystem_v3.GetTranslationTable'"), 
					EventLogLevel.Information, 
					, 
					Undefined, 
					NStr("en='Input parameters: ';ru='Входные параметры: ';de='Input parameters: '")+Chars.LF+
					"InteractionID: "+pInteractionID);
	
	// Try to find existing interaction by id
	vInteraction = Undefined;
	vInteractions = cmGetInteractionByID(pInteractionID, True);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteraction = vInteractions.Get(0).Ref;
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	vHotel = vInteraction.Hotel;
	If vInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetTranslationTable", Enums.ExternalSystemEventTypes.Info, pInteractionID, , vMsg);
	EndIf;
	
	vTranslationTable = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "TranslationTable"));
	vTranslationTable.InteractID = pInteractionID;
	vTranslationTable.ExternalID = TrimR(vInteraction.Code);
	vTranslationTable.ExternalName = TrimR(vInteraction.Description);
	vTranslationTable.Inactive = Not vInteraction.IsActive;
	vTranslationTable.RoomCategoryTranslationList = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "RoomCategoryTranslationList"));
	vTranslationTable.AbodePacketTranslationList = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "AbodePacketTranslationList"));
	vTranslationTable.ServiceTranslationList = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "ServiceTranslationList"));
	vTranslationTable.TouristTypeTranslationList = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "TouristTypeTranslationList"));
	vTranslationTable.RoomPlacingAvailabilityList = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "RoomPlacingAvailabilityList"));
	// Do for each room type
	vRoomTypeType = XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "RoomCategoryTranslationItem");
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomTypes.Ref,
	|	RoomTypes.Code,
	|	RoomTypes.Description,
	|	RoomTypes.Parent,
	|	RoomTypes.SortCode AS SortCode
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|WHERE
	|	RoomTypes.Owner = &qHotel
	|
	|ORDER BY
	|	SortCode";
	vQry.SetParameter("qHotel", vHotel);
	vRoomTypes = vQry.Execute().Unload();
	For Each vRoomTypesRow In vRoomTypes Do
		vRoomTypeXDTO = XDTOFactory.Create(vRoomTypeType);
		vRoomTypeXDTO.ExternalID = TrimR(vRoomTypesRow.Code);
		vRoomTypeXDTO.ExternalName = TrimR(vRoomTypesRow.Description);
		vRoomTypeExtCodes = cmGetObjectExternalSystemCodeByRef(vHotel, pInteractionID, "RoomTypes", vRoomTypesRow.Ref, True);
		If Not IsBlankString(vRoomTypeExtCodes) Then
			vSlashPos = Find(vRoomTypeExtCodes, "/");
			If vSlashPos = 0 Then
				vRoomCategoryCID = TrimR(vRoomTypeExtCodes);
			Else
				vRoomCategoryCID = Left(vRoomTypeExtCodes, vSlashPos - 1);
			EndIf;
			vRoomTypeXDTO.RoomCategoryCID = vRoomCategoryCID;
		EndIf;
		vTranslationTable.RoomCategoryTranslationList.RoomCategoryTranslationItem.Add(vRoomTypeXDTO);
	EndDo;
	// Do for each room rate
	vRoomRateType = XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "AbodePacketTranslationItem");
	vRoomRateList = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "RoomRates");
	For Each vRoomRatesRow In vRoomRateList Do
		vRoomRateXDTO = XDTOFactory.Create(vRoomRateType);
		vRoomRateXDTO.ExternalID = vRoomRatesRow.DataValue;
		vRoomRateXDTO.ExternalName = TrimR(vRoomRatesRow.RefKey1.Description)+ " " + TrimR(vRoomRatesRow.RefKey2);
		vAbodePacketShortName = vRoomRatesRow.ExternalSystemDataCode;
		If Not IsBlankString(vAbodePacketShortName) Then
			vRoomRateXDTO.AbodePacketCID = vAbodePacketShortName;
		EndIf;
		vTranslationTable.AbodePacketTranslationList.AbodePacketTranslationItem.Add(vRoomRateXDTO);
	EndDo;
	// Do for each services
	vServicePackageType = XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "ServiceTranslationItem");
	vServiceGroupsList = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "ServiceGroups");
	vServicesList = New Array;
	For Each vServiceGroupsListRow In vServiceGroupsList Do
		If TypeOf(vServiceGroupsListRow.RefKey1) = Type("CatalogRef.OrderTypes") Then
			For Each vSrv In vServiceGroupsListRow.RefKey1.ServicesAllowed Do
				If vServicesList.Find(vSrv.Service) = Undefined And (vSrv.Service.Hotel = vHotel Or	vSrv.Service.Hotel = Catalogs.Hotels.EmptyRef()) Then
					vServicesList.Add(vSrv.Service);
				EndIf;	
			EndDo; 
		ElsIf TypeOf(vServiceGroupsListRow.RefKey1) = Type("CatalogRef.ServiceGroups") Then	
	     For Each vSrv In vServiceGroupsListRow.RefKey1.Services Do
				If vServicesList.Find(vSrv.Service) = Undefined And (vSrv.Service.Hotel = vHotel Or	vSrv.Service.Hotel = Catalogs.Hotels.EmptyRef()) Then
					vServicesList.Add(vSrv.Service);
				EndIf;	
			EndDo; 
		EndIf;
	EndDo;
	For Each vServiceRow In vServicesList Do
		vServicePackageXDTO = XDTOFactory.Create(vServicePackageType);
		vServicePackageXDTO.ExternalID = TrimAll(vServiceRow.Code);
		vServicePackageXDTO.ExternalName = TrimR(vServiceRow.Description);
		vServicePackageShortName = cmGetObjectExternalSystemCodeByRef(vHotel, pInteractionID, "Services", vServiceRow, True);
		If Not IsBlankString(vServicePackageShortName) Then
			vServicePackageXDTO.ServiceCID = vServicePackageShortName;
		EndIf;
		vTranslationTable.ServiceTranslationList.ServiceTranslationItem.Add(vServicePackageXDTO);
	EndDo;
	// Delete old refs
	vServiceListMap = ChannelManagers.GetMappedListObjects(vHotel, pInteractionID, "Services");
	For Each vRowService In vServiceListMap Do
		If vServicesList.Find(vRowService.ObjectRef) = Undefined Then
			cmDeleteExternalSystemObjectMapping(vHotel, pInteractionID, "Services", vRowService.ObjectRef);
		EndIf;	
	EndDo;
	
	// Do for each accommodation type
	vAccommodationTypeType = XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "TouristTypeTranslationItem");
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationTypes.Ref,
	|	AccommodationTypes.Code,
	|	AccommodationTypes.Description,
	|	AccommodationTypes.Type,
	|	AccommodationTypes.Code,
	|	AccommodationTypes.Description,
	|	AccommodationTypes.AllowedClientAgeRange
	|FROM
	|	Catalog.AccommodationTypes AS AccommodationTypes
	|WHERE
	|	NOT AccommodationTypes.DeletionMark
	|	AND (AccommodationTypes.Hotel = &qHotel
	|			OR AccommodationTypes.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	AccommodationTypes.SortCode";
	vQry.SetParameter("qHotel", vHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vAccTypes = vQry.Execute().Unload();
	For Each vAccTypesRow In vAccTypes Do
		vAccTypeXDTO = XDTOFactory.Create(vAccommodationTypeType);
		vAccTypeXDTO.ExternalAge = TrimR(vAccTypesRow.Code) + "/" + TrimR(vAccTypesRow.Description);
		vTouristTypeShortName = cmGetObjectExternalSystemCodeByRef(vHotel, pInteractionID, "AccommodationTypes", vAccTypesRow.Ref, True);
		If Not IsBlankString(vTouristTypeShortName) Then
			vSlashPos = Find(vTouristTypeShortName, "/");
			If vSlashPos > 1 Then
				vAccTypeXDTO.PlaceKind = Left(vTouristTypeShortName, vSlashPos - 1);
				vAccTypeXDTO.TouristTypeCID = Mid(vTouristTypeShortName, vSlashPos + 1);
			Else
				vAccTypeXDTO.PlaceKind = "BASE";
				vAccTypeXDTO.TouristTypeCID = vTouristTypeShortName;
			EndIf;
		Else
			If vAccTypesRow.Type = Enums.AccomodationTypes.Room Or vAccTypesRow.Type = Enums.AccomodationTypes.Beds Then
				vAccTypeXDTO.PlaceKind = "BASE";
			ElsIf vAccTypesRow.Type = Enums.AccomodationTypes.AdditionalBed Then 
				vAccTypeXDTO.PlaceKind = "EXT";
			Else
				vAccTypeXDTO.PlaceKind = "NO_PLACE";
			EndIf;
		EndIf;
		vTranslationTable.TouristTypeTranslationList.TouristTypeTranslationItem.Add(vAccTypeXDTO);
	EndDo;
	
	// Get room placing availability list
	vExtRoomTypes = ChannelManagers.GetMappedListObjects(vHotel, pInteractionID, "RoomTypes");
	vExtAccommodationTypes = ChannelManagers.GetMappedListObjects(vHotel, pInteractionID, "AccommodationTypes");
	
	vAvailabilityList = GetExtAccommodationTemplates(vInteraction);
	
	vAlreadyExportList = New Array;
	If vExtRoomTypes.Count() > 0 And vExtAccommodationTypes.Count() > 0 Then
		
		vAccommodationTemplateBed = cmGetAccommodationTypeBed(vHotel);
		
		For Each vRoomTypeRow In vExtRoomTypes Do
			If IsBlankString(vRoomTypeRow.ObjectExternalCode) Then
				Continue;
			EndIf;	
			vRoomType = vRoomTypeRow.ObjectRef;
			
			// Build and run query
			vQry = New Query;
			vQry.Text = 
			"SELECT
			|	AccTemplates.Ref AS AccommodationTemplate,
			|	CASE
			|		WHEN AccTemplates.Ref.NumberOfTeenagers + AccTemplates.Ref.NumberOfChildren + AccTemplates.Ref.NumberOfInfants = 0
			|			THEN 0
			|		ELSE 1
			|	END AS SortCode
			|FROM
			|	Catalog.AccommodationTemplates.RoomTypes AS AccTemplates
			|WHERE
			|	(AccTemplates.Ref.Hotel = &qHotel
			|			OR AccTemplates.Ref.Hotel = &qEmptyHotel)
			|	AND (AccTemplates.RoomType = &qRoomType
			|			OR AccTemplates.RoomClass = &qRoomClass
			|				AND AccTemplates.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef))
			|	AND AccTemplates.Ref.DeletionMark = FALSE
			|	AND AccTemplates.Ref.IsForFolioSplit = FALSE
			|
			|GROUP BY
			|	AccTemplates.Ref,
			|	CASE
			|		WHEN AccTemplates.Ref.NumberOfTeenagers + AccTemplates.Ref.NumberOfChildren + AccTemplates.Ref.NumberOfInfants = 0
			|			THEN 0
			|		ELSE 1
			|	END
			|
			|ORDER BY
			|	SortCode,
			|	AccTemplates.Ref.Code";
			vQry.SetParameter("qHotel", vHotel);
			vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());            
			vQry.SetParameter("qRoomType", vRoomType);
			vQry.SetParameter("qRoomClass", Catalogs.RoomTypeClasses.EmptyRef());
			If ValueIsFilled(vRoomType) And Not vRoomType.IsFolder And ValueIsFilled(vRoomType.RoomClass) Then
				vQry.SetParameter("qRoomClass", vRoomType.RoomClass);
			EndIf;
			
			vResvQryTab =  vQry.Execute().Unload();
			vCurTabAccTemp = vAvailabilityList.FindRows(New Structure("RoomType", vRoomType));
			For Each vInd In vCurTabAccTemp Do 
				If vResvQryTab.Find(vInd.AccommodationTemplate) = Undefined Then
					vNR = vResvQryTab.Add();
					vNR.AccommodationTemplate = vInd.AccommodationTemplate;
					// Disable in saved values
					vInd.Excluded = True;
				EndIf;	
			EndDo;	
			For Each vResvQry In vResvQryTab Do
				vAccTemplate = vResvQry.AccommodationTemplate;
				vRoomPlacingAvailabilityItem = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "RoomPlacingAvailability"));
				
				vRoomPlacingAvailabilityItem.RoomCategoryCID = vRoomTypeRow.ObjectExternalCode;
				vRoomPlacingAvailabilityItem.Excluded = False;
				
				vUUID = vRoomTypeRow.ObjectExternalCode;
				
				vAccommodationTypes = vAccTemplate.AccommodationTypes.Unload();
				vAccommodationTypes.Columns.Add("TouristTypeCID");
				vAccommodationTypes.Columns.Add("Quantity");
				vAccommodationTypes.Columns.Add("PlaceKind");
				
				For Each vAccTypeRow In vAccommodationTypes Do
					vCurrAccommodationType = vAccTypeRow.AccommodationType;
					vTouristTypeCID = GetTouristTypeCID(vHotel, vCurrAccommodationType, vInteraction.InteractionID);						
					If IsBlankString(vTouristTypeCID) And vCurrAccommodationType.Type <> Enums.AccomodationTypes.AdditionalBed Then
						vTouristTypeCID = GetTouristTypeCID(vHotel, vAccommodationTemplateBed, vInteraction.InteractionID);
						If IsBlankString(vTouristTypeCID) Then	
							Continue;
						EndIf;
					ElsIf IsBlankString(vTouristTypeCID) Then	
						Continue;
					EndIf;	
					
					vAccTemplateExternalCode = "";
					If vCurrAccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Then
						vAccTemplateExternalCode = "EXT";
					Else 
						vAccTemplateExternalCode = "BASE";
					EndIf;	
					
					vAccTypeRow.TouristTypeCID = vTouristTypeCID;
					vAccTypeRow.PlaceKind = vAccTemplateExternalCode;
					vAccTypeRow.Quantity = 1;
				EndDo;
				
				vAccommodationTypes.GroupBy("TouristTypeCID, PlaceKind", "Quantity");
				vAccommodationTypes.Sort("PlaceKind, TouristTypeCID, Quantity");
				For Each vExtRow In vAccommodationTypes Do
					If IsBlankString(vExtRow.PlaceKind) Or IsBlankString(vExtRow.TouristTypeCID) Then
						Continue;
					EndIf;	
					vUUID = vUUID + vExtRow.TouristTypeCID + vExtRow.PlaceKind + String(vExtRow.Quantity);
				EndDo;
				
				vCurrMap = vAvailabilityList.Find(vUUID);
				If vCurrMap = Undefined Then
					If vRoomTypeRow.ObjectExternalCode = vUUID Then
						Continue;
					EndIf;	
					
				InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, vAccTemplate.Metadata().Name, vAccTemplate.Metadata().Synonym, vRoomType, vAccTemplate, False, vUUID);

				Else
					vRoomPlacingAvailabilityItem.Excluded = vCurrMap.Excluded;
				EndIf;	
				If vAlreadyExportList.Find(vUUID) = Undefined Then
					vAlreadyExportList.Add(vUUID);
				Else
					Continue;
				EndIf;	
				For Each vExtRow In vAccommodationTypes Do
					If IsBlankString(vExtRow.TouristTypeCID) Or Not ValueIsFilled(vExtRow.TouristTypeCID) Then
						Continue;
					EndIf;	
					vRoomPlacingXDTO = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tma-HotelAdapterTranslationTable.v3", "RoomPlacing"));
					FillPropertyValues(vRoomPlacingXDTO,vExtRow); 
					vRoomPlacingAvailabilityItem.RoomPlacing.Add(vRoomPlacingXDTO);
				EndDo;
				vTranslationTable.RoomPlacingAvailabilityList.RoomPlacingAvailability.Add(vRoomPlacingAvailabilityItem);
			EndDo;	
		EndDo;
	EndIf;	
	
	// Build string XML
	vTempFileName = GetTempFileName("xml");
	vXMLWriter = New XMLWriter();
	vXMLWriterSettings = New XMLWriterSettings("UTF-16", "1.0", False, False);
	vXMLWriter.OpenFile(vTempFileName, vXMLWriterSettings);
	vXMLWriter.WriteXMLDeclaration();
	XDTOFactory.WriteXML(vXMLWriter, vTranslationTable);
	vXMLWriter.Close();
	
	vTextFile 	= New TextReader(vTempFileName, "UTF-16");
	vStringXML 	= vTextFile.Read();
	vTextFile.Close();
	
	If vExtRoomTypes.Count() = 0 And vExtAccommodationTypes.Count() = 0 Then 
		vStringXML = StrReplace(vStringXML,"<RoomPlacingAvailabilityList/>","");
	EndIf;	
		
	Try DeleteFiles(vTempFileName); Except EndTry;
	
	// Write xml in log
	If vInteraction.DebugMode Then
		vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetTranslationTable", Enums.ExternalSystemEventTypes.Success, , vStringXML, vMsg);
	EndIf;
 
	Return vStringXML;
EndFunction // GetTranslationTable

// -----------------------------------------------------------------------------
Function MakeReservation(pInteractID, pReservationDataXML, rReservationNumber, rInvoiceNumber)
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.MakeReservation'; de='AleanCRSSystem_v3.MakeReservation'; ru='AleanCRSSystem_v3.MakeReservation'"), 
					EventLogLevel.Information, 
					, 
					Undefined, 
					NStr("en='Input parameters: ';ru='Входные параметры: ';de='Input parameters: '")+Chars.LF+
					"InteractID: "+pInteractID+Chars.LF+
					"ReservationNumber: "+rReservationNumber+Chars.LF+
					"InvoiceNumber: "+rInvoiceNumber+Chars.LF+
					"ReservationDataXML: "+pReservationDataXML);
	
	rReservationNumber = "";
	vInteraction = Undefined;
	vInteractions = cmGetInteractionByID(pInteractID);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteraction = vInteractions.Get(0).Ref;
		If Not vInteraction.IsActive Then
			Raise NStr("en='Interaction with given interaction ID is not active!'; de='Interaction with given interaction ID is not active!'; ru='Взаимодействие с переданным идентификатором не активно!'");
		EndIf;
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	If vInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "MakeReservation", Enums.ExternalSystemEventTypes.Info, pReservationDataXML, , vMsg);
	EndIf;
	
	// Try to parse XML data into DOM object 
	vReader = New XMLReader();
	vReader.SetString(pReservationDataXML);
	vDOMBuilder = New DOMBuilder();
	vDOMObj = vDOMBuilder.Read(vReader);
	
	// Try to read main reservation data from the root element attributes
	vReservationItems = vDOMObj.GetElementByTagName("Reservation");
	If vReservationItems.Count() = 0 Then
		vMsg = NStr("en='Main <Reservation> element is missing in the XML data!'; de='Main <Reservation> element is missing in the XML data!'; ru='В XML данных не найден элемент <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "MakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	ElsIf vReservationItems.Count() > 1 Then
		vMsg = NStr("en='More then one <Reservation> element is found in the XML data!'; de='More then one <Reservation> element is found in the XML data!'; ru='В XML данных найдено более одного элемента <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "MakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	vReservationItem = vReservationItems.Item(0);
	
	vMakeReservationResult = DoMakeReservation(vInteraction, vReservationItem, rReservationNumber, rInvoiceNumber);
	
	// Close reader
	vReader.Close();
	
	// Return success
	If vInteraction.DebugMode Then
		vMessage =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "MakeReservation", Enums.ExternalSystemEventTypes.Success, ,vMakeReservationResult, vMessage);
	EndIf;

	// Return guest group code and status
	Return vMakeReservationResult;
EndFunction // MakeReservation

// -----------------------------------------------------------------------------
Function ModifyReservation(pInteractID, pReservationNumber, pReservationDataXML)
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.ModifyReservation'; de='AleanCRSSystem_v3.ModifyReservation'; ru='AleanCRSSystem_v3.ModifyReservation'"), 
	EventLogLevel.Information, 
	, 
	Undefined, 
	NStr("en='Input parameters: ';ru='Входные параметры: ';de='Input parameters: '")+Chars.LF+
	"InteractID: "+pInteractID+Chars.LF+
	"ReservationNumber: "+pReservationNumber+Chars.LF+
	"ReservationDataXML: "+pReservationDataXML);
	
	vInteraction = Undefined;
	vInteractions = cmGetInteractionByID(pInteractID);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteraction = vInteractions.Get(0).Ref;
		If Not vInteraction.IsActive Then
			Raise NStr("en='Interaction with given interaction ID is not active!'; de='Interaction with given interaction ID is not active!'; ru='Взаимодействие с переданным идентификатором не активно!'");
		EndIf;
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	If vInteraction.DebugMode Then
		WriteLogEvent("AleanCRSSystem_v3.ModifyReservation", EventLogLevel.Information, , , pReservationDataXML);
	EndIf;
	
	// Try to parse XML data into DOM object 
	vReader = New XMLReader();
	vReader.SetString(pReservationDataXML);
	vDOMBuilder = New DOMBuilder();
	vDOMObj = vDOMBuilder.Read(vReader);
	
	// Try to read main reservation data from the root element attributes
	vReservationItems = vDOMObj.GetElementByTagName("Reservation");
	If vReservationItems.Count() = 0 Then
		Raise NStr("en='Main <Reservation> element is missing in the XML data!'; de='Main <Reservation> element is missing in the XML data!'; ru='В XML данных не найден элемент <Reservation>!'");
	ElsIf vReservationItems.Count() > 1 Then
		Raise NStr("en='More then one <Reservation> element is found in the XML data!'; de='More then one <Reservation> element is found in the XML data!'; ru='В XML данных найдено более одного элемента <Reservation>!'");
	EndIf;
	vReservationItem = vReservationItems.Item(0);
	
	vModifyReservationResult = DoModifyReservation(vInteraction, vReservationItem);
	
	// Close reader
	vReader.Close();
	
	// Return success
	If vInteraction.DebugMode Then
		WriteLogEvent("AleanCRSSystem_v3.ModifyReservation", EventLogLevel.Information, , , "Result: " + vModifyReservationResult);
	EndIf;
	
	// Return status
	Return vModifyReservationResult;
EndFunction // ModifyReservation

// -----------------------------------------------------------------------------
Function ModifyReservationEx(pInteractID, pReservationNumber, pInvoiceNumber = Undefined, pReservationDataXML)
	vInteraction = Undefined;
	vInteractions = cmGetInteractionByID(pInteractID);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteraction = vInteractions.Get(0).Ref;
		If Not vInteraction.IsActive Then
			Raise NStr("en='Interaction with given interaction ID is not active!'; de='Interaction with given interaction ID is not active!'; ru='Взаимодействие с переданным идентификатором не активно!'");
		EndIf;
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	
	If vInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'")+ Chars.LF + 
			"InteractID: " + pInteractID + Chars.LF +
			"ReservationNumber: " + pReservationNumber + Chars.LF +
			"InvoiceNumber: " + pInvoiceNumber;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "ModifyReservationEx", Enums.ExternalSystemEventTypes.Info, pReservationDataXML, , vMsg);
	EndIf;

	// Try to parse XML data into DOM object 
	vReader = New XMLReader();
	vReader.SetString(pReservationDataXML);
	vDOMBuilder = New DOMBuilder();
	vDOMObj = vDOMBuilder.Read(vReader);
	
	// Try to read main reservation data from the root element attributes
	vReservationItems = vDOMObj.GetElementByTagName("Reservation");
	If vReservationItems.Count() = 0 Then
		vMsg = NStr("en='Main <Reservation> element is missing in the XML data!'; de='Main <Reservation> element is missing in the XML data!'; ru='В XML данных не найден элемент <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "ModifyReservationEx", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	ElsIf vReservationItems.Count() > 1 Then
		vMsg = NStr("en='More then one <Reservation> element is found in the XML data!'; de='More then one <Reservation> element is found in the XML data!'; ru='В XML данных найдено более одного элемента <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "ModifyReservationEx", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	vReservationItem = vReservationItems.Item(0);
	
	vModifyReservationResult = DoModifyReservation(vInteraction, vReservationItem);
	
	// Close reader
	vReader.Close();
	
	// Return success
	If vInteraction.DebugMode Then
		vMessage =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "ModifyReservationEx", Enums.ExternalSystemEventTypes.Success, ,vModifyReservationResult, vMessage);
	EndIf;

	// Return status
	Return vModifyReservationResult;
EndFunction // ModifyReservation

// -----------------------------------------------------------------------------
Function NewInteraction(pInteractionID, pInteractionBeginDate, pInteractionEndDate, pInteractionParams, pInheritLastTranslationTable, pExternalID, pExternalName)
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.NewInteraction'; de='AleanCRSSystem_v3.NewInteraction'; ru='AleanCRSSystem_v3.NewInteraction'"), 
				EventLogLevel.Information, 
				, 
				Undefined, 
				NStr("en='Input parameters: ';ru='Входные параметры: ';de='Input parameters: '")+Chars.LF+
				"InteractionID: "+pInteractionID+Chars.LF+
				"InteractionBeginDate: "+pInteractionBeginDate+Chars.LF+
				"InteractionEndDate: "+pInteractionEndDate+Chars.LF+
				"InteractionParams: "+pInteractionParams+Chars.LF+
				"InteractionEndDate: "+pInheritLastTranslationTable+Chars.LF+
				"ExternalID: "+pExternalID+Chars.LF+
				"ExternalName: "+pExternalName);
	
	// Try to find existing interaction by id
	vInteractionObj = Undefined;
	vInteractions = cmGetInteractionByID(pInteractionID);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteractionObj = vInteractions.Get(0).Ref.GetObject();
		If Not IsBlankString(pExternalID) Then
			vInteractionObj.Code = TrimR(pExternalID);
		EndIf;
		If Not IsBlankString(pExternalName) Then
			vInteractionObj.Description = TrimR(pExternalName);
		EndIf;
	Else
		// Check if interaction is already created
		vInteractionRef = Catalogs.ExternalSystemInteractions.FindByCode(TrimR(pExternalID), False);
		If Not ValueIsFilled(vInteractionRef) Then
			vInteractionObj = Catalogs.ExternalSystemInteractions.CreateItem();
			If Not IsBlankString(pExternalID) Then
				vInteractionObj.Code = TrimR(pExternalID);
			Else
				vInteractionObj.SetNewCode();
			EndIf;
			If Not IsBlankString(pExternalName) Then
				vInteractionObj.Description = TrimR(pExternalName);
			Else
				vInteractionObj.Description = "КСБ Алеан - " + TrimAll(SessionParameters.CurrentHotel) + " - " + Format(CurrentSessionDate(), "DF=yyyy") + " - " + CurrentSessionDate();
			EndIf;
			vInteractionObj.Hotel = SessionParameters.CurrentHotel;
		Else
			vInteractionObj = vInteractionRef.GetObject();
		EndIf;
		vInteractionObj.InteractionID = TrimR(pInteractionID);
	EndIf;
	If ValueIsFilled(pInteractionBeginDate) Then
		vInteractionObj.ActiveFromDate = pInteractionBeginDate;
	EndIf;
	If ValueIsFilled(pInteractionEndDate) Then
		vInteractionObj.ActiveToDate = pInteractionEndDate;
	EndIf;
	If Not IsBlankString(String(pInteractionParams)) Then
		vInteractionObj.Parameters = New ValueStorage("<Interaction>" + Chars.LF + TrimR(pInteractionParams) + Chars.LF + "</Interaction>");
    EndIf;
    vInteractionObj.IntegrationType = Enums.Integrations.AleanCRS;
	vInteractionObj.Write();
    // Create dataprocessor
    Catalogs.ExternalSystemInteractions.GetObjetForm(vInteractionObj.Ref, "", True);

	If pInheritLastTranslationTable Then
		cmCopyLastTranslationTableData();
	EndIf;
	Return "";
EndFunction // NewInteraction

// -----------------------------------------------------------------------------
Function SynchronizeReservations(pInteractID, pReservationSyncXML)
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.SynchronizeReservations'; de='AleanCRSSystem_v3.SynchronizeReservations'; ru='AleanCRSSystem_v3.SynchronizeReservations'"), 
					EventLogLevel.Information, 
					, 
					Undefined, 
					NStr("en='Input parameters: ';ru='Входные параметры: ';de='Input parameters: '")+Chars.LF+
					"InteractID: "+pInteractID+Chars.LF+
					"ReservationSyncXML: "+pReservationSyncXML);
	
	vInteraction = Undefined;
	vInteractions = cmGetInteractionByID(pInteractID);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteraction = vInteractions.Get(0).Ref;
		If Not vInteraction.IsActive Then
			Raise NStr("en='Interaction with given interaction ID is not active!'; de='Interaction with given interaction ID is not active!'; ru='Взаимодействие с переданным идентификатором не активно!'");
		EndIf;
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	If vInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'")+ Chars.LF + "pInteractID: " + pInteractID;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "SynchronizeReservations", Enums.ExternalSystemEventTypes.Warning, pReservationSyncXML, , vMsg);
	EndIf;
	
	vSyncReservationsResult = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tws-HotelAdapterReservationProtocol", "SynchronizeReservationsResult"));
	vSyncReservationProtocol = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tws-HotelAdapterReservationProtocol", "ReservationProtocol"));
	
	// Try to parse XML data into DOM object 
	vReader = New XMLReader();
	vReader.SetString(pReservationSyncXML);
	vDOMBuilder = New DOMBuilder();
	vDOMObj = vDOMBuilder.Read(vReader);
	
	Try
		// Try to read canceled reservations data from the root element attributes
		vCanceledReservationItems = vDOMObj.GetElementByTagName("CanceledReservation");
		If vCanceledReservationItems.Count() > 0 Then
			For i = 0 To (vCanceledReservationItems.Count() - 1) Do
				vReservationItem = vCanceledReservationItems.Item(i);
				vResAttrs = vReservationItem.Attributes;
				vExtOrderNumber = vResAttrs.GetNamedItem("OrderNumber").Value;
				vCancelReservationResult = DoCancelReservation(vInteraction, vReservationItem);
				
				vProtocolResult = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tws-HotelAdapterReservationProtocol", "ReservationProtocolResult"));
				vProtocolResult.OrderNumber = vExtOrderNumber;
				vProtocolResult.CancelReservationResult = GetCancelReservationResult(vCancelReservationResult);
				vSyncReservationProtocol.ReservationResult.Add(vProtocolResult);
			EndDo;
		EndIf;
		
		// Try to read modified and new reservations data from the root element attributes
		vReservationItems = vDOMObj.GetElementByTagName("Reservation");
		If vReservationItems.Count() > 0 Then
			For i = 0 To (vReservationItems.Count() - 1) Do
				vReservationItem = vReservationItems.Item(i);
				vResAttrs = vReservationItem.Attributes;
				vExtOrderNumber = vResAttrs.GetNamedItem("OrderNumber").Value;
				vIntGroupNumber = "";
				Try
					vIntGroupNumber = GetGuestGroupCode(vResAttrs.GetNamedItem("SupplierOrderNumber").Value);
				Except
				EndTry;
				If Not IsBlankString(vIntGroupNumber) Then
					BeginTransaction(DataLockControlMode.Managed);
					vModifyReservationResult = DoModifyReservation(vInteraction, vReservationItem);
					CommitTransaction();
					
					vProtocolResult = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tws-HotelAdapterReservationProtocol", "ReservationProtocolResult"));
					vProtocolResult.OrderNumber = vExtOrderNumber;
					vProtocolResult.SupplierOrderNumber = vIntGroupNumber;
					vProtocolResult.ModifyReservationResult = GetModifyReservationResult(vModifyReservationResult);
					
					vSyncReservationProtocol.ReservationResult.Add(vProtocolResult);
				Else
					vIntGroupNumber = "";
					vIntInvoiceNumber = "";
					BeginTransaction(DataLockControlMode.Managed);
					vReservationResult = DoMakeReservation(vInteraction, vReservationItem, vIntGroupNumber, vIntInvoiceNumber);
					CommitTransaction();
					
					vProtocolResult = XDTOFactory.Create(XDTOFactory.Type("urn:schemas-som-ru:tws-HotelAdapterReservationProtocol", "ReservationProtocolResult"));
					vProtocolResult.OrderNumber = vExtOrderNumber;
					vProtocolResult.SupplierOrderNumber = vIntGroupNumber;
					vProtocolResult.SupplierInvoiceNumber = vIntInvoiceNumber;
					vProtocolResult.ReservationResult = GetReservationResult(vReservationResult);
					
					vSyncReservationProtocol.ReservationResult.Add(vProtocolResult);
				EndIf;
			EndDo;
		EndIf;
		vSyncReservationsResult.ReservationProtocol = vSyncReservationProtocol;
		
		// Close reader
		vReader.Close();
	Except
		vErrorDescription = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Try
			// Close reader
			vReader.Close();
		Except
		EndTry;
		Raise vErrorDescription;
	EndTry;
	
	// Return success
	If vInteraction.DebugMode Then
		vMessage =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "SynchronizeReservations", Enums.ExternalSystemEventTypes.Success, ,,vMessage);
	EndIf;

	Return vSyncReservationsResult;
EndFunction // SynchronizeReservations

// -----------------------------------------------------------------------------
Function UpdateInteraction(pInteractionID, pInteractionBeginDate, pInteractionEndDate, pInteractionParams)
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.ActivateInteraction'; de='AleanCRSSystem_v3.ActivateInteraction'; ru='AleanCRSSystem_v3.ActivateInteraction'"), 
						EventLogLevel.Information, 
						, 
						Undefined, 
						NStr("en='Input parameters: ';ru='Входные параметры: ';de='Input parameters: '")+Chars.LF+
						"InteractionID: "+pInteractionID+Chars.LF+
						"InteractionBeginDate: "+pInteractionBeginDate+Chars.LF+
						"InteractionEndDate: "+pInteractionEndDate+Chars.LF+
						"InteractionParams: "+pInteractionParams);
	
	// Try to find existing interaction by id
	vInteractionObj = Undefined;
	vInteractions = cmGetInteractionByID(pInteractionID, True);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteractionObj = vInteractions.Get(0).Ref.GetObject();
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	
	InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionObj.Ref, "UpdateInteraction", Enums.ExternalSystemEventTypes.Info);
	
	If ValueIsFilled(pInteractionBeginDate) Then
		vInteractionObj.ActiveFromDate = pInteractionBeginDate;
	Else
		vInteractionObj.ActiveFromDate = '00010101';
	EndIf;
	If ValueIsFilled(pInteractionEndDate) Then
		vInteractionObj.ActiveToDate = pInteractionEndDate;
	Else
		vInteractionObj.ActiveToDate = '00010101';
	EndIf;
	vInteractionObj.Write();
	Return "";
EndFunction // UpdateInteraction

// -----------------------------------------------------------------------------
Function UpdateTranslationTable(pInteractionID, pTranslationTableXML)
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.UpdateTranslationTable'; de='AleanCRSSystem_v3.UpdateTranslationTable'; ru='AleanCRSSystem_v3.UpdateTranslationTable'"), 
				EventLogLevel.Information, 
				, 
				Undefined, 
				NStr("en='Input parameters: ';ru='Входные параметры: ';de='Input parameters: '")+Chars.LF+
				"InteractionID: "+pInteractionID+Chars.LF+
				"TranslationTableXML: "+pTranslationTableXML);
	// Try to find existing interaction by id
	vInteraction = Undefined;
	vInteractions = cmGetInteractionByID(pInteractionID, True);
	If vInteractions.Count() > 1 Then
		Raise NStr("en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
	ElsIf vInteractions.Count() = 1 Then
		vInteraction = vInteractions.Get(0).Ref;
	Else
		Raise NStr("en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
	EndIf;
	
	If vInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'")+ Chars.LF + "InteractID: " + pInteractionID;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "UpdateTranslationTable", Enums.ExternalSystemEventTypes.Info, pTranslationTableXML, , vMsg);
	EndIf;

	// Working storage variables
	vRoomTypesAreCleared = False;
	vRoomRatesAreCleared = False;
	vServicePackagesAreCleared = False;
	vAccommodationTypesAreCleared = False;
	// Parse input XML
	vReader = New XMLReader();
	vReader.SetString(pTranslationTableXML);
	While vReader.Read() Do
		// Room types
		If vReader.NodeType = XMLNodeType.StartElement And vReader.Name = "RoomCategoryTranslationItem" Then
			If Not vRoomTypesAreCleared Then
				cmClearExternalSystemObjectMapping(vInteraction.Hotel, pInteractionID, "RoomTypes");
				vRoomTypesAreCleared = True;
			EndIf;
			vExternalID = vReader.GetAttribute("ExternalID");
			vExtSystemCode = "";
			vExtSystemCode = vReader.GetAttribute("RoomCategoryCID");
			cmSaveExternalSystemObjectMapping(vInteraction.Hotel, pInteractionID, "RoomTypes", TrimR(vExternalID), vExtSystemCode);
			// Room rates
		ElsIf vReader.NodeType = XMLNodeType.StartElement And vReader.Name = "AbodePacketTranslationItem" Then
			vAbodePacketShortName = vReader.GetAttribute("AbodePacketCID");
			vExternalID = vReader.GetAttribute("ExternalID");
			vRateRows = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "RoomRates",,,, vExternalID);
			If vRateRows.Count() = 0 Then
				vMessage = NStr("en = 'Failed to match tariff'; de = 'Tarif konnte nicht übereinstimmen'; ru = 'Не удалось установить соответствие по тарифу'") + vAbodePacketShortName;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "UpdateTranslationTable", Enums.ExternalSystemEventTypes.Error,,,vMessage);
				raise vMessage;
			EndIf;	
			vRowRate = vRateRows[0];
			vRmg = InformationRegisters.ExternalSystemIntegrationData.CreateRecordManager(); 
			FillPropertyValues(vRmg, vRowRate, , "ExternalSystemDataCode");
			vRmg.ExternalSystemDataCode = vAbodePacketShortName;
			vRmg.Write(True);
			// Service packages
		ElsIf vReader.NodeType = XMLNodeType.StartElement And vReader.Name = "ServiceTranslationItem" Then
			If Not vServicePackagesAreCleared Then
				cmClearExternalSystemObjectMapping(vInteraction.Hotel, pInteractionID, "Services");
				vServicePackagesAreCleared = True;
			EndIf;
			vServicePackageShortName = vReader.GetAttribute("ServiceCID");
			If Not IsBlankString(vServicePackageShortName) Then
				vExternalID = vReader.GetAttribute("ExternalID");
				cmSaveExternalSystemObjectMapping(vInteraction.Hotel, pInteractionID, "Services", TrimR(vExternalID), TrimR(vServicePackageShortName));
			EndIf;
			// Accommodation types
		ElsIf vReader.NodeType = XMLNodeType.StartElement And vReader.Name = "TouristTypeTranslationItem" Then
			If Not vAccommodationTypesAreCleared Then
				cmClearExternalSystemObjectMapping(vInteraction.Hotel, pInteractionID, "AccommodationTypes");
				vAccommodationTypesAreCleared = True;
			EndIf;
			vTouristTypeShortName = vReader.GetAttribute("TouristTypeCID");
			vPlaceKind = vReader.GetAttribute("PlaceKind");
			vAccTypeCode = TrimR(vReader.GetAttribute("ExternalAge"));
			vSlashPos = Find(vAccTypeCode, "/");
			If vSlashPos > 1 Then
				vAccTypeCode = Left(vAccTypeCode, vSlashPos - 1);
			EndIf;
			cmSaveExternalSystemObjectMapping(vInteraction.Hotel, pInteractionID, "AccommodationTypes", vAccTypeCode, TrimR(vPlaceKind) + "/" + TrimR(vTouristTypeShortName));
		EndIf;
	EndDo;
	vReader.Close();
	vReader = Undefined;
	// Clear empty rows
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(vInteraction, "RoomRates", , , ,,"");
	// Clear excluded accommodation templates
	vCurMappingTable = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "AccommodationTemplates");
	If vCurMappingTable.Count() > 0  Then
		vReader = New XMLReader();
		vReader.SetString(pTranslationTableXML);
		vDOMBuilder = New DOMBuilder();
		vDOMObj = vDOMBuilder.Read(vReader);
		vRoomPlacingAvailabilityList = vDOMObj.GetElementByTagName("RoomPlacingAvailabilityList");
		If vRoomPlacingAvailabilityList.Count() > 0 Then
			vRoomPlacingAvailabilityItems = vRoomPlacingAvailabilityList.Item(0);
			If vRoomPlacingAvailabilityItems.ChildNodes.Count() > 0 Then
				For Each vRowList In vRoomPlacingAvailabilityItems.ChildNodes Do
					vExcluded = XMLValue(Type("Boolean"),vRowList.Attributes.GetNamedItem("Excluded").Value);
					// Update excluded items
					vUUID = vRowList.Attributes.GetNamedItem("RoomCategoryCID").Value;
					
					vAccTemplateTab = New ValueTable;
					vAccTemplateTab.Columns.Add("PlaceKind");
					vAccTemplateTab.Columns.Add("TouristTypeCID");
					vAccTemplateTab.Columns.Add("Quantity");
					
					For Each vAccType In vRowList.ChildNodes Do
						vNewRow = vAccTemplateTab.Add();
						// Bild row
						vRoomPlacingAttrs = vAccType.Attributes;
						vNewRow.PlaceKind = vRoomPlacingAttrs.GetNamedItem("PlaceKind").Value;
						vNewRow.TouristTypeCID =  vRoomPlacingAttrs.GetNamedItem("TouristTypeCID").Value;
						vNewRow.Quantity =  XMLValue(Type("Number"),vRoomPlacingAttrs.GetNamedItem("Quantity").Value);
					EndDo; 
					vAccTemplateTab.GroupBy("PlaceKind, TouristTypeCID", "Quantity");
					vAccTemplateTab.Sort("PlaceKind, TouristTypeCID, Quantity");
					
					For Each vAccTypeRow In vAccTemplateTab Do
						vUUID = vUUID + vAccTypeRow.TouristTypeCID + vAccTypeRow.PlaceKind + String(vAccTypeRow.Quantity);
					EndDo;
					
					// Check mapping
					vFilterRows = vCurMappingTable.FindRows(New Structure("ExternalSystemDataCode", vUUID));
					// Change row
					For Each vElement In vFilterRows Do
						vRmg = InformationRegisters.ExternalSystemIntegrationData.CreateRecordManager(); 
						FillPropertyValues(vRmg, vElement, "DataValue");
						vRmg.DataValue = vExcluded;
						vRmg.Write(True);
					EndDo; 
				EndDo;
			Else
				ClearExcludedAccommadationTypes(vCurMappingTable);
			EndIf;	
		Else
			ClearExcludedAccommadationTypes(vCurMappingTable);
		EndIf;
    EndIf;
    
	// Save mapping room place kind
    If vCurMappingTable.Count() > 0 Then 
        // Clear old rows
        vExtRoomTypes = ChannelManagers.GetMappedListObjects(vInteraction.Hotel, pInteractionID, "RoomTypes");
		
		vRoomTypes = vCurMappingTable.Copy(New Structure("ExternalSystem, DataType", vInteraction, "AccommodationTemplates"), "RefKey1"); 
		vRoomTypes.GroupBy("RefKey1"); // RefKey1 - RoomType, RefKey2 - AccommodationTemplate  
		
		For Each vRoomTypeRow In vRoomTypes Do
		    vRoomType = vRoomTypeRow.RefKey1; 
			vFilterRows = vExtRoomTypes.FindRows(New Structure("ObjectRef", vRoomType));
			If vFilterRows.Count() = 0 Then
				vRmg = InformationRegisters.ExternalSystemIntegrationData.CreateRecordSet();
				vRmg.Filter.ExternalSystem.Set(vInteraction);
				vRmg.Filter.RefKey1.Set(vRoomType);  
				vRmg.Write();
			EndIf;	
		EndDo;
    EndIf;	
	
	// Return success
	If vInteraction.DebugMode Then
		vMessage =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "UpdateTranslationTable", Enums.ExternalSystemEventTypes.Success,,,vMessage);
	EndIf;

	// Return
	Return "";
EndFunction // UpdateTranslationTable

// -----------------------------------------------------------------------------
Function VerifyPromoActionMember(pPromoCode, pMemberID, rVerificationCode)
	WriteLogEvent(NStr("en='AleanCRSSystem_v3.VerifyPromoActionMember'; de='AleanCRSSystem_v3.VerifyPromoActionMember'; ru='AleanCRSSystem_v3.VerifyPromoActionMember'"), 
					EventLogLevel.Information, 
					, 
					Undefined, 
					NStr("en='Input parameters: ';ru='Входные параметры: ';de='Input parameters: '")+Chars.LF+
					"PromoCode: "+pPromoCode+Chars.LF+
					"MemberID: "+pMemberID+Chars.LF+
					"VerificationCode: "+rVerificationCode);
	
	rVerificationCode = "";
	vErrorDescription = "";
	
	If IsBlankString(pPromoCode) Then
		Raise NStr("en='Promo code should be filled!'; ru='Не указан код промоакции!'; de='Promotion-Code fehlt!'");
	EndIf;
	
	vPhone = "";
	If Not IsBlankString(pMemberID) Then
		vPhone = SMS.GetValidPhoneNumber(pMemberID);
	Else
		Raise NStr("en='Phone number to send SMS with verification code is empty!'; ru='Не указан номер телефона для отправки СМС с кодом подтверждения!'; de='Keine Telefonnummer für das Versenden von SMS mit Bestätigungscode!'");
	EndIf;
	
	vClients = GetClientsByPromoCodeAndMemberID(pPromoCode, vPhone);
	If vClients.Count() > 0 Then
		vDefaultClient = vClients.Get(0).Client;
		// Generate unique verification code
		If rVerificationCode = "" Then
			rVerificationCode = GenerateVerificationCode();
		EndIf;
		// Send verification code by SMS
		vSMSTemplate = Catalogs.SMSTemplates.SendVerificationCodeMessage;
		vMessageText = SMS.GetSMSTextByLanguage(vSMSTemplate, vDefaultClient.Language);
		If IsBlankString(vMessageText) Then
			vMessageText = cmNStr("en='Your verification code is '; ru='Код подтверждения '; de='Ihr Bestätigungscode ist '", vDefaultClient.Language) + "&VerificationCode";
		EndIf;
		vMessageText = StrReplace(vMessageText, "&VerificationCode", rVerificationCode);
		vMessageID = Undefined;
		SMS.SendMessage(vMessageText, vPhone, vSMSTemplate, TrimAll(vSMSTemplate.Sender), vDefaultClient, , SessionParameters.CurrentUser, , vErrorDescription, vMessageID);
		If ValueIsFilled(vMessageID) Then
			// Save verification code to the database
			vRcdMgr = InformationRegisters.ClientVerificationCodes.CreateRecordManager();
			vRcdMgr.PromoCode = pPromoCode;
			vRcdMgr.Phone = vPhone;
			vRcdMgr.VerificationCode = rVerificationCode;
			vRcdMgr.IsSent = True;
			vRcdMgr.DateSent = CurrentSessionDate();
			vRcdMgr.IsUsed = False;
			vRcdMgr.DateUsed = '00010101';
			vRcdMgr.Write(True);
			Return "vprVerificationCodeSent";
		Else
			Raise vErrorDescription;
		EndIf;
	Else
		Return "vprNotMember";
	EndIf;
EndFunction // VerifyPromoActionMember

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function InitServices()
	// Get services
	vServices = New ValueTable();
	vServices.Columns.Add("ServiceCID", cmGetStringTypeDescription());
	vServices.Columns.Add("ServiceMethod", cmGetStringTypeDescription());
	vServices.Columns.Add("OrderAmount", cmGetNumberTypeDescription(19, 7));
	vServices.Columns.Add("BeginDate", cmGetDateTypeDescription());
	vServices.Columns.Add("EndDate", cmGetDateTypeDescription());
	vServices.Columns.Add("IsAvoided", cmGetBooleanTypeDescription());
	vServices.Columns.Add("AvoidanceDateTime", cmGetDateTimeTypeDescription());
	Return vServices;
EndFunction // InitServices

// -----------------------------------------------------------------------------
Procedure LoadServices(pServices, pItem, pTagName)
	vServiceItems = pItem.GetElementByTagName(pTagName);
	If vServiceItems.Count() > 0 Then
		For s = 0 To (vServiceItems.Count() - 1) Do
			vServiceItem = vServiceItems.Item(s);
			vServiceAttrs = vServiceItem.Attributes;
			vRow = pServices.Add();
			vRow.ServiceCID = TrimR(vServiceAttrs.GetNamedItem("ServiceCID").Value);
			Try
				vRow.ServiceMethod = TrimR(vServiceAttrs.GetNamedItem("ServiceMethod").Value);
			Except
			EndTry;
			Try
				vRow.OrderAmount = vServiceAttrs.GetNamedItem("OrderAmount").Value;
			Except
			EndTry;
			Try
				vRow.BeginDate = vServiceAttrs.GetNamedItem("BeginDateTime").Value;
			Except
			EndTry;
			Try
				vRow.EndDate = vServiceAttrs.GetNamedItem("EndDateTime").Value;
			Except
			EndTry;
			Try
				vRow.IsAvoided = vServiceAttrs.GetNamedItem("IsAvoided").Value;
			Except
			EndTry;
			Try
				vRow.AvoidanceDateTime = vServiceAttrs.GetNamedItem("AvoidanceDateTime").Value;
			Except
			EndTry;
		EndDo;
	EndIf;
EndProcedure // LoadServices

// -----------------------------------------------------------------------------
Function GetExtGroupNumber(pExtOrderNumber, rExtRoomOrderNumber)
	vExtGroupNumber = pExtOrderNumber;
	rExtRoomOrderNumber = "";
	vSlashPos = Find(pExtOrderNumber, "/");
	If vSlashPos > 1 Then
		vExtGroupNumber = TrimAll(Left(pExtOrderNumber, vSlashPos - 1));
		rExtRoomOrderNumber = TrimAll(Mid(pExtOrderNumber, vSlashPos + 1));
	EndIf;
	Return vExtGroupNumber;
EndFunction // GetExtGroupNumber

// -----------------------------------------------------------------------------
Function GetGuestGroupCode(pGroupNumber)
	vGuestGroupCode = TrimAll(pGroupNumber);
	vSlashPos = Find(vGuestGroupCode, "/");
	If vSlashPos > 1 Then
		vGuestGroupCode = TrimAll(Left(vGuestGroupCode, vSlashPos - 1));
	EndIf;
	Return vGuestGroupCode;
EndFunction // GetGuestGroupCode

// -----------------------------------------------------------------------------
Function TraceValueTableRow(pRow, pTable)
	vRowStr = "";
	vColIndex = 0;
	For Each vCol In pTable.Columns Do
		If vColIndex > 0 Then
			vRowStr = vRowStr + ", ";
		EndIf;
		vRowStr = vRowStr + vCol.Title + ": " + pRow[vCol.Name];
		vColIndex = vColIndex + 1;
	EndDo;
	Return vRowStr;
EndFunction // TraceValueTableRow

// -----------------------------------------------------------------------------
Function GetGroupCustomersAndContracts(pGuestGroup)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Customer,
	|	Reservation.Contract
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND Reservation.ReservationStatus.IsActive
	|	AND Reservation.GuestGroup = &qGuestGroup
	|
	|GROUP BY
	|	Reservation.Customer,
	|	Reservation.Contract
	|
	|ORDER BY
	|	Reservation.Customer.Description,
	|	Reservation.Contract.Description";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	Return vQry.Execute().Unload();
EndFunction // GetGroupCustomersAndContracts

// -----------------------------------------------------------------------------
Function DoMakeReservation(vInteraction, vReservationItem, rReservationNumber, rInvoiceNumber) 
	If vInteraction.DebugMode Then
		vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Info, rReservationNumber, , vMsg);
	EndIf;
	
	rReservationNumber = "";
	rInvoiceNumber = "";
	
	vCurMappingTable = GetExtAccommodationTemplates(vInteraction);
	
	// Try to find canceled reservation status
	vAnnulationStatus = GetAnnulationStatus();
	
	// Tis is reference to the new guest group
	vGuestGroup = Catalogs.GuestGroups.EmptyRef();
	
	vResAttrs = vReservationItem.Attributes;
	vExtOrderNumber = vResAttrs.GetNamedItem("OrderNumber").Value;
	vExtRoomOrderNumber = "";
	vExtGroupNumber = GetExtGroupNumber(vExtOrderNumber, vExtRoomOrderNumber);
	vGuestGroup = cmGetGuestGroupByExternalCode(vInteraction.Hotel, vExtGroupNumber, "", "", False);
	// SUM
	vExternalResAmount = vResAttrs.GetNamedItem("Price").Value;
	vCurResAmount = 0;
	vCustomerIsPayer = True;
	vCustomer = Catalogs.Customers.EmptyRef();
	vCustomerName = vResAttrs.GetNamedItem("OrgJuridicalPersonCID").Value;
	vCustomerTIN = vResAttrs.GetNamedItem("OrgJuridicalPersonTIN").Value;
	vCustomerKPP = "";
	Try
		vCustomerKPP = vResAttrs.GetNamedItem("OrgJuridicalPersonKPP").Value;
	Except
	EndTry;
	vGroupCustomerName = vCustomerName;
	If ValueIsFilled(vGuestGroup) Then
		If ValueIsFilled(vGuestGroup.Customer) Then
			vCustomer = vGuestGroup.Customer;
		EndIf;
		If ValueIsFilled(vGuestGroup.ClientDoc) And TypeOf(vGuestGroup.ClientDoc) <> Type("DocumentRef.ResourceReservation") Then
			vCustomerIsPayer = False;
			For Each vCRRow In vGuestGroup.ClientDoc.ChargingRules Do
				If ValueIsFilled(vCRRow.Owner) Then
					If vCRRow.Owner = vCustomer Or TypeOf(vCRRow.Owner) = Type("CatalogRef.Contracts") And vCRRow.Owner.Owner = vCustomer Then
						vCustomerIsPayer = True;
						Break;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	Else
		vCustomer = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "Customers", vGroupCustomerName);
		If Not ValueIsFilled(vCustomer) And Not IsBlankString(vCustomerTIN) And Not IsBlankString(vCustomerKPP) Then
			vCustomer = cmGetCustomerByTIN(TrimAll(vCustomerTIN), TrimAll(vCustomerKPP), TrimAll(vCustomerName));
		EndIf;
	EndIf;
	If ValueIsFilled(vCustomer) Then
		vGroupCustomerName = TrimAll(vCustomer.Description);
		If IsBlankString(vCustomer.TIN) And Not IsBlankString(vCustomerTIN) Then
			vCustomerObj = vCustomer.GetObject();
			vCustomerObj.TIN = TrimAll(vCustomerTIN);
			vCustomerObj.KPP = TrimAll(vCustomerKPP);
			vCustomerObj.Write();
			vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndIf;
	
	vRoomTypeCode = vResAttrs.GetNamedItem("RoomCategoryCID").Value;
	vRoomType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "RoomTypes", vRoomTypeCode);
	vNumberOfBedsPerRoom = 1;
	vNumberOfPersonsPerRoom = 1;
	If ValueIsFilled(vRoomType) Then
		vNumberOfBedsPerRoom = vRoomType.NumberOfBedsPerRoom;
		vNumberOfPersonsPerRoom = vRoomType.NumberOfPersonsPerRoom;
	EndIf;
	
	vBaseSeatQuantity = Number(vResAttrs.GetNamedItem("BaseSeatQuantity").Value);
	vRoomQuantity = vBaseSeatQuantity / vNumberOfBedsPerRoom;
	If vRoomQuantity <> Int(vBaseSeatQuantity / vNumberOfBedsPerRoom) Then
		vRoomQuantity = Int(vRoomQuantity) + 1;
	EndIf;
	vExtSeatQuantity = Number(vResAttrs.GetNamedItem("ExtSeatQuantity").Value);
	vCheckInDate = cmGetDateFromTimestampPresentation(vResAttrs.GetNamedItem("BeginDateTime").Value);
	If Not ValueIsFilled(vCheckInDate) Then
		vMsg =  NStr("en = 'Error parsing <BeginDateTime> attribute of the <Reservation> element!'; 
					 |de = 'Error parsing <BeginDateTime> attribute of the <Reservation> element!'; 
					 |ru = 'Ошибка разбора значения атрибута <BeginDateTime> элемента <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	vCheckOutDate = cmGetDateFromTimestampPresentation(vResAttrs.GetNamedItem("EndDateTime").Value);
	If Not ValueIsFilled(vCheckOutDate) Then
		vMsg =  NStr("en = 'Error parsing <EndDateTime> attribute of the <Reservation> element!'; 
					 |de = 'Error parsing <EndDateTime> attribute of the <Reservation> element!'; 
					 |ru = 'Ошибка разбора значения атрибута <EndDateTime> элемента <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	vReservationCreateDate = cmGetDateFromTimestampPresentation(vResAttrs.GetNamedItem("OrderDateTime").Value);
	If Not ValueIsFilled(vReservationCreateDate) Then
		vMsg = NStr("en = 'Error parsing <OrderDateTime> attribute of the <Reservation> element!'; 
					|de = 'Error parsing <OrderDateTime> attribute of the <Reservation> element!'; 
					|ru = 'Ошибка разбора значения атрибута <OrderDateTime> элемента <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	Else
		vServerTimeZone = StandardTimeOffset(,) + DaylightTimeOffset(,);
		vReservationCreateDate = vReservationCreateDate + vServerTimeZone;
	EndIf;
	
	// Check reservation check-in date. If it is in the past then do nothing  
	If vInteraction.UniqueProfilesControl Then  
		If vCheckInDate < CurrentSessionDate() Then
			vMsg = NStr("en = 'Check-in date is in the past! External call is skipped.'; 
						|de = 'Check-in date is in the past! External call is skipped.'; 
						|ru = 'Дата заезда в прошлом! Внешний вызов игнорируется.'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
			Raise vMsg;
		EndIf;  	
	Else	
		If BegOfDay(vCheckInDate) < BegOfDay(CurrentSessionDate()) Then
			vMsg = NStr("en = 'Check-in date is in the past! External call is skipped.'; 
						|de = 'Check-in date is in the past! External call is skipped.'; 
						|ru = 'Дата заезда в прошлом! Внешний вызов игнорируется.'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
			Raise vMsg;
		EndIf;   
	EndIf;
	
	// Try to bind to promo action
	vDiscountTypeCode = "";
	vDiscountCardID = "";
	vPromoCode = "";
	vPromoPhone = "";
	vPromoVerificationCode = "";
	If vResAttrs.GetNamedItem("PromoMemberID") <> Undefined Then
		vPromoCode = vResAttrs.GetNamedItem("PromoCode").Value;
		vPromoPhone = vResAttrs.GetNamedItem("PromoMemberID").Value;
		vPromoVerificationCode = vResAttrs.GetNamedItem("PromoVerificationCode").Value;
		If Not IsBlankString(vPromoPhone) Then
			// Try to check verification code over phone
			vRcdMgr = GetVerificationRecordByPhoneAndCode(vPromoCode, vPromoPhone, vPromoVerificationCode);
			If vRcdMgr <> Undefined Then
				If Not vRcdMgr.IsUsed Then
					vRcdMgr.IsUsed = True;
					vRcdMgr.DateUsed = CurrentSessionDate();
					vRcdMgr.Write();
				EndIf;
				// Try to find discount type by promo code
				If Not IsBlankString(vPromoCode) Then
					vDiscountType = GetDiscountTypeByPromoCode(vPromoCode);
					If ValueIsFilled(vDiscountType) Then
						vDiscountTypeCode = TrimR(vDiscountType.Code);
					Else
						vDiscountCard = GetDiscountCardByPromoCode(vPromoCode, vPromoPhone);
						If ValueIsFilled(vDiscountCard) Then
							vDiscountCardID = TrimR(vDiscountCard.Identifier);
						EndIf;
					EndIf;
				EndIf;
			Else
				vMsg = NStr("en = 'Failed to confirm verification code!'; 
						 	|de = 'Der Bestätigungscode konnte nicht bestätigt werden!'; 
							|ru = 'Не удалось проверить код подтверждения!'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
				Raise vMsg;
			EndIf;
		EndIf;
	EndIf;
	
	// Try to bind to the allotment and check-in period
	vRoomQuota = vInteraction.Allotment;
	vRoomQuotaCode = "";
	If ValueIsFilled(vRoomQuota) Then
		vRoomQuotaCode = vRoomQuota.Code;	
	EndIf;	
	If vInteraction.IsByCheckInPeriods Then
		vCheckInPeriods = cmGetCheckInPeriodsWithBalances(vInteraction.Hotel, vInteraction.Allotment, vRoomType, vCustomer, vCheckInDate, vCheckOutDate);
		If vInteraction.DebugMode Then
			vEventData = "Check-in periods found are: " + Chars.LF;
			For Each vCheckInPeriodsRow In vCheckInPeriods Do
				vEventData = vEventData + TraceValueTableRow(vCheckInPeriodsRow, vCheckInPeriods) + Chars.LF;
			EndDo;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Warning, , , vEventData);
		EndIf;
		If vCheckInPeriods.Count() > 0 Then
			vAllotments = cmGetSuitableAllotments(vCheckInPeriods, vCheckInDate, vCheckOutDate);
			If vInteraction.DebugMode Then
				vEventData = "Allotments found are: " + Chars.LF;
				For Each vAllotmentsRow In vAllotments Do
					vEventData = vEventData + TraceValueTableRow(vAllotmentsRow, vAllotments) + Chars.LF;
				EndDo;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Info, , , vEventData);
			EndIf;
			If vAllotments.Count() > 0 Then
				vAllotmentsRow = vAllotments.Get(0);
				If ValueIsFilled(vInteraction.Allotment) And 
					ValueIsFilled(vAllotmentsRow.RoomQuota) And 
					vAllotmentsRow.RoomsRemains >= vRoomQuantity Then
					vRoomQuota = vAllotmentsRow.RoomQuota;
					vRoomQuotaCode = vRoomQuota.Code;
				ElsIf Not ValueIsFilled(vInteraction.Allotment) And 
					Not ValueIsFilled(vAllotmentsRow.RoomQuota) And 
					vAllotmentsRow.RoomsVacant >= vRoomQuantity Then
					vRoomQuota = vAllotmentsRow.RoomQuota;
					vRoomQuotaCode = vRoomQuota.Code;
				Else
					Return "rrInsufficientResources";
				EndIf;
			Else
				Return "rrInsufficientResources";
			EndIf;
		Else
			Return "rrInsufficientResources";
		EndIf;
	Else // Check if there are vacant rooms for this reservation
		vMsgTextRu = "";
		vMsgTextEn = "";
		vMsgTextDe = "";
		If Not cmCheckRoomAvailability(vInteraction.Hotel, vRoomQuota, vRoomType, Catalogs.Rooms.EmptyRef(), Undefined, False, True,
			(vBaseSeatQuantity + vExtSeatQuantity), vRoomQuantity, vBaseSeatQuantity, vExtSeatQuantity, 
			vNumberOfBedsPerRoom, vNumberOfPersonsPerRoom, vCheckInDate, vCheckOutDate, 
			vMsgTextRu, vMsgTextEn, vMsgTextDe) Then
			Return "rrInsufficientResources";
		EndIf;
	EndIf;
	
	// Fill contract by room type
	vContractName = "";
	If ValueIsFilled(vCustomer) Then
		vContract = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "Contracts", vCustomerName);
		If ValueIsFilled(vContract) Then
			vContractName = vCustomerName;
		EndIf;
	EndIf;
	
	// Get list of all guests in the reservation
	vGuests = New ValueTable();
	vGuests.Columns.Add("ID", cmGetStringTypeDescription());
	vGuests.Columns.Add("FullName", cmGetStringTypeDescription());
	vGuests.Columns.Add("FirstName", cmGetStringTypeDescription());
	vGuests.Columns.Add("LastName", cmGetStringTypeDescription());
	vGuests.Columns.Add("SecondName", cmGetStringTypeDescription());
	vGuests.Columns.Add("SexCode", cmGetStringTypeDescription());
	vGuests.Columns.Add("Passport", cmGetStringTypeDescription());
	vGuests.Columns.Add("PassportSeries", cmGetStringTypeDescription());
	vGuests.Columns.Add("PassportNumber", cmGetStringTypeDescription());
	vGuests.Columns.Add("BirthDate", cmGetDateTypeDescription());
	vGuests.Columns.Add("Age", cmGetNumberTypeDescription(4, 0));
	
	vTouristItems = vReservationItem.GetElementByTagName("Tourist");
	If vTouristItems.Count() > 0 Then
		For i = 0 To (vTouristItems.Count() - 1) Do
			vTouristItem = vTouristItems.Item(i);
			vTouristAttrs = vTouristItem.Attributes;
			
			vGuestsRow = vGuests.Add();
			vGuestsRow.ID = vTouristAttrs.GetNamedItem("TouristID").Value;
			Try
				vGuestsRow.Passport = vTouristAttrs.GetNamedItem("PassportData").Value;
				If Not IsBlankString(vGuestsRow.Passport) Then
					vGuestsRow.Passport = StrReplace(vGuestsRow.Passport, "№", "");
					vGuestsRow.Passport = StrReplace(vGuestsRow.Passport, "#", "");
					vGuestsRow.Passport = StrReplace(vGuestsRow.Passport, "N", "");
					vGuestsRow.Passport = StrReplace(vGuestsRow.Passport, "  ", " ");
					vGuestsRow.Passport = StrReplace(vGuestsRow.Passport, "  ", " ");
					If StrLen(vGuestsRow.Passport) > 6 Then
						cmParsePassportNumber(TrimAll(vGuestsRow.Passport), vGuestsRow.PassportSeries, vGuestsRow.PassportNumber);
					EndIf;
				EndIf;
			Except
			EndTry;
			Try
				vGuestsRow.BirthDate = cmGetDateFromDatePresentation(vTouristAttrs.GetNamedItem("BirthDate").Value);
			Except
			EndTry;
			Try
				vGuestsRow.Age = Number(vTouristAttrs.GetNamedItem("Age").Value);
			Except
			EndTry;
			vMLTextItems = vTouristItem.GetElementByTagName("MLText");
			If vMLTextItems.Count() = 0 Then
				Raise NStr("en = '<MLText> element is missing in the XML data!'; de = '<MLText> element is missing in the XML data!'; ru = 'В XML данных не найден элемент <MLText>!'");
			EndIf;
			vMLTextItem = vMLTextItems.Item(0);
			vMLTextAttrs = vMLTextItem.Attributes;
			vGuestsRow.FullName = vMLTextAttrs.GetNamedItem("Text").Value;
			vGuestsRow.SexCode = "M";
			
			// Try to parse guest full name to the 3 parts
			If Not IsBlankString(vGuestsRow.FullName) Then
				vGuestSex = Undefined;
				cmParseClientFullName(vGuestsRow.FullName, vGuestsRow.LastName, vGuestsRow.FirstName, vGuestsRow.SecondName, vGuestSex);
				If ValueIsFilled(vGuestSex) Then
					If vGuestSex = Enums.Sex.Male Then
						vGuestsRow.SexCode = "M";
					Else
						vGuestsRow.SexCode = "F";
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Get order wishes
	vOrderWishes = "";
	vOrderWishesItems = vReservationItem.GetElementByTagName("OrderWishes");
	If vOrderWishesItems.Count() > 0 Then
		For i = 0 To (vOrderWishesItems.Count() - 1) Do
			vOrderWishesItem = vOrderWishesItems.Item(i);
			vMLTextItems = vOrderWishesItem.GetElementByTagName("MLText");
			If vMLTextItems.Count() = 0 Then
				vMsg =  NStr("en = '<MLText> element is missing in the XML data!'; de = '<MLText> element is missing in the XML data!'; ru = 'В XML данных не найден элемент <MLText>!'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
				Raise vMsg;
			EndIf;
			vMLTextItem = vMLTextItems.Item(0);
			vMLTextAttrs = vMLTextItem.Attributes;
			If IsBlankString(vOrderWishes) Then
				vOrderWishes = vMLTextAttrs.GetNamedItem("Text").Value;
			Else
				vOrderWishes = vOrderWishes + Chars.LF + vMLTextAttrs.GetNamedItem("Text").Value;
			EndIf;				
		EndDo;
	EndIf;
	
	// Get list of all rooms in the reservation
	vRoomItems = vReservationItem.GetElementByTagName("Room");
	If vRoomItems.Count() = 0 Then
		vMsg = NStr("en = '<Room> element is missing in the XML data!'; de = '<Room> element is missing in the XML data!'; ru = 'В XML данных не найден элемент <Room>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	vRoomsCount = vRoomItems.Count();
	If ValueIsFilled(vGuestGroup) And ValueIsFilled(vCheckInDate) Then
		vGuestGroupObj = vGuestGroup.GetObject();
		// Check if this is preliminary guest group
		vIsPreliminary = vGuestGroupObj.pmIsPreliminary();
		// Fill guest group room inventory totals
		vRITotalsRooms = 0;
		vRITotals = vGuestGroupObj.pmGetRoomInventoryTotals(vCheckInDate);
		If vRITotals.Count() > 0 Then
			vRITotalsRow = vRITotals.Get(0);
			If Not vIsPreliminary Then
				vRITotalsRooms = vRITotalsRow.RoomsReserved + vRITotalsRow.RoomsCheckedIn;
			Else
				vRITotalsRooms = vRITotalsRow.RoomsExpected;
			EndIf;
		EndIf;
		vRoomsCount = vRoomsCount + vRITotalsRooms;
	EndIf;
	BeginTransaction();
	Try
		For i = 0 To (vRoomItems.Count() - 1) Do
			vRoomItem = vRoomItems.Item(i);
			vRoomFirstGuest = True;
			vReservationNumber = "";
			vLastUsedGuestIndex = 0;
			vRoomPlaceItemIsSet = False;
			vRoomReservation = Undefined;
			vRoomAttrs = vRoomItem.Attributes;
			vReservationStatusCode = "";
			vRoomIsCanceled = False;
			Try
				vRoomIsCanceled = vRoomAttrs.GetNamedItem("IsAvoided").Value;
			Except
			EndTry;
			If vRoomIsCanceled Then
				vReservationStatusCode = TrimR(vAnnulationStatus.Code);
			EndIf;
			vPricePerRoom = True;
			Try
				vPricePerRoom = XMLValue(Type("Boolean"), vRoomAttrs.GetNamedItem("PricePerRoom").Value);
			Except
			EndTry;
			// Get room services
			vRoomServices = InitServices();
			vRoomServiceListItems = vRoomItem.GetElementByTagName("RoomServiceList");
			If vRoomServiceListItems.Count() > 0 Then
				vRoomServiceListItem = vRoomServiceListItems.Item(0);
				LoadServices(vRoomServices, vRoomServiceListItem, "RoomService");
			EndIf;
			vAccTemplate = Undefined;
			
			// Get places for the given room
			vPlaceItems = vRoomItem.GetElementByTagName("Place");
			If vPlaceItems.Count() = 0 Then
				vMsg = NStr("en = '<Place> element is missing in the XML data!'; de = '<Place> element is missing in the XML data!'; ru = 'В XML данных не найден элемент <Place>!'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
				Raise vMsg;
			EndIf;
			
			vTabPriceRoom = New ValueTable;
			vTabPriceRoom.Columns.Add("Quantity");
			vTabPriceRoom.Columns.Add("PlaceKind");
			vTabPriceRoom.Columns.Add("TouristTypeCID");
			vTabPriceRoom.Columns.Add("AccommodationType");
			vTabPriceRoom.Columns.Add("TouristID");
			
			For j = 0 To (vPlaceItems.Count() - 1) Do
				vPlaceItem = vPlaceItems.Item(j);
				vPlaceAttrs = vPlaceItem.Attributes;
				
				vPlaceKind = TrimR(vPlaceAttrs.GetNamedItem("PlaceKind").Value);
				vTouristTypeCID = vPlaceAttrs.GetNamedItem("TouristTypeCID").Value;
				
				vGuestID = "";
				Try
					vGuestID = vPlaceAttrs.GetNamedItem("TouristID").Value;
				Except
				EndTry;
				
				vAccTypeCode = TrimR(vPlaceKind + "/" + vTouristTypeCID);
				vAccType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "AccommodationTypes", vAccTypeCode);
				
				If Not IsBlankString(vTouristTypeCID) And Not IsBlankString(vPlaceKind) Then
					vNewRowTabPriceRoom = vTabPriceRoom.Add();
					vNewRowTabPriceRoom.Quantity = 1;
					vNewRowTabPriceRoom.PlaceKind = vPlaceKind;
					vNewRowTabPriceRoom.TouristTypeCID = vTouristTypeCID;
					vNewRowTabPriceRoom.AccommodationType = vAccType;
					vNewRowTabPriceRoom.TouristID = vGuestID;
				EndIf;	
			EndDo;
			
			// Get accommodation template
			vAccTemplateList = vTabPriceRoom.Copy();
			vAccTemplateList.GroupBy("PlaceKind, TouristTypeCID", "Quantity");
			vAccTemplateList.Sort("PlaceKind, TouristTypeCID, Quantity");
			vUUID = vRoomTypeCode;
			For Each vResRow In vAccTemplateList Do 
				vUUID = vUUID + vResRow.TouristTypeCID + vResRow.PlaceKind + String(vResRow.Quantity);
			EndDo;
			If vCurMappingTable.Count() = 0 Then
				vMsg = Nstr("en = 'List accomodation templates is empty'; 
							|de = 'Keine Übereinstimmung in ALEAN CRS für Unterkunftsvorlagen gefunden'; 
							|ru = 'Список шаблонов размещения пустой. Необходимо выполнить первичную синхронизацию'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
				Raise vMsg;
			Else
				vRowFilter = vCurMappingTable.Find(vUUID);
				If Not vRowFilter = Undefined Then
					vAccTemplate = vRowFilter.AccommodationTemplate;
				EndIf;	
			EndIf;
			vAccommodationTypesList = New Array;
			If Not vAccTemplate = Undefined Then
				vAccommodationTypesList = vAccTemplate.AccommodationTypes.UnloadColumn("AccommodationType");
			Else
				If vInteraction.DebugMode Then
					vMsg = Nstr("en = 'Accomodation template not found!'; de = 'Accomodation template not found!'; ru = 'Шаблон размещения не найден'");
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
				EndIf;	
			EndIf;	
			For j = 0 To (vPlaceItems.Count() - 1) Do
				vPlaceItem = vPlaceItems.Item(j);
				vPlaceAttrs = vPlaceItem.Attributes;
				
				// Accommodation type code
				vAccommodationTypeCode = TrimR(vPlaceAttrs.GetNamedItem("PlaceKind").Value + "/" + vPlaceAttrs.GetNamedItem("TouristTypeCID").Value);
				vAccommodationType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "AccommodationTypes", vAccommodationTypeCode);
				If Not ValueIsFilled(vAccommodationType) Then
					vMsg = NStr("en = 'Accommodation type mapping is missing for external code! '; 
								|de = 'Accommodation type mapping is missing for external code! '; 
								|ru = 'Не задано соответствие кодов для вида размещения с внешним кодом! '") + vAccommodationTypeCode;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
					Raise vMsg;
				EndIf;
				vAccommodationTypeIsSet = False;
				If vAccommodationTypesList.Count() > 0 Then
					vIDRow = vAccommodationTypesList.Find(vAccommodationType);
					If vIDRow = Undefined Then
						vIDRow = 0;
					EndIf;
					vAccommodationType =  vAccommodationTypesList.Get(vIDRow);
					vAccommodationTypeCode = TrimR(vAccommodationType.Code);
					vAccommodationTypesList.Delete(vIDRow);
					vAccommodationTypeIsSet = True;
					If vInteraction.DebugMode Then
						vMsg = Nstr("en = 'Accomodation type set by accomodation template'; 
									|de = 'Accomodation type set by accomodation template'; 
									|ru = 'Вид  размещения подставлен по шаблону'");
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
					EndIf;	
				EndIf;	
				If vAccommodationTypeIsSet = False Then	
					If vPlaceItems.Count() = 1 Then
						If vAccommodationType.Type = Enums.AccomodationTypes.Beds Then
							vNewAccommodationType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "AccommodationTypes", "OneGuestInRoom");
							If ValueIsFilled(vNewAccommodationType) Then
								vAccommodationType = vNewAccommodationType;
								vAccommodationTypeCode = TrimR(vNewAccommodationType.Code);
							EndIf;
						EndIf;
					ElsIf vPlaceItems.Count() >= 2 Then
						If vAccommodationType.Type = Enums.AccomodationTypes.Beds Then
							If vRoomPlaceItemIsSet Then
								vNewAccommodationType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "AccommodationTypes", "Together");
								If ValueIsFilled(vNewAccommodationType) Then
									vAccommodationType = vNewAccommodationType;
									vAccommodationTypeCode = TrimR(vNewAccommodationType.Code);
								EndIf;
							Else
								vNewAccommodationType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "AccommodationTypes", "MainGuestInRoom");
								If ValueIsFilled(vNewAccommodationType) Then
									vAccommodationType = vNewAccommodationType;
									vAccommodationTypeCode = TrimR(vNewAccommodationType.Code);
									vRoomPlaceItemIsSet = True;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				
				// Load place services
				vPlaceServices = InitServices();
				vPlaceServiceListItems = vPlaceItem.GetElementByTagName("PlaceServiceList");
				If vPlaceServiceListItems.Count() > 0 Then
					vPlaceServiceListItem = vPlaceServiceListItems.Item(0);
					LoadServices(vPlaceServices, vPlaceServiceListItem, "PlaceService");
				EndIf;
				
				// Read guest ID and try to match it with guest data
				vGuestsRow = Undefined;
				vGuestID = "";
				Try
					vGuestID = vPlaceAttrs.GetNamedItem("TouristID").Value;
				Except
				EndTry;
				If Not IsBlankString(vGuestID) Then
					vGuestsRow = vGuests.Find(vGuestID, "ID");
				EndIf;
				vGuestIndex = Format((i * 1000 + vLastUsedGuestIndex), "ND=6; NFD=0; NZ=; NLZ=; NG=");
				vLastUsedGuestIndex = vLastUsedGuestIndex + 1;
				
				// Room rates value table
				vRoomRates = New ValueTable();
				vRoomRates.Columns.Add("AccountingDate", cmGetDateTypeDescription());
				vRoomRates.Columns.Add("RoomRateCode", cmGetStringTypeDescription());
				vRoomRates.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
				vRoomRates.Columns.Add("PriceTag");
				vRoomRateCode = "";
				
				// Read room rates
				vPlacePacketItems = vPlaceItem.GetElementByTagName("PlacePacket");
				vRoomRateCheckOutDate = Undefined;
				If vPlacePacketItems.Count() > 0 Then
					For k = 0 To (vPlacePacketItems.Count() - 1) Do
						vPlacePacketItem = vPlacePacketItems.Item(k);
						vPlacePacketAttrs = vPlacePacketItem.Attributes;
						
						vPacketShortName = vPlacePacketAttrs.GetNamedItem("PacketCID").Value;
						vRoomRatesQryRes = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "RoomRates",,,,,vPacketShortName);
						If vRoomRatesQryRes.Count() = 0 Then
							vMsg = NStr("en = 'Failed to read mapping for the room rate with code '; de = 'Failed to read mapping for the room rate with code '; ru = 'Не удалось найти соответствие для тарифа с кодом '") + vPacketShortName + "!";
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
							Raise vMsg;
						EndIf;
						vRoomRate = vRoomRatesQryRes[0].RefKey1;
						vPriceTag = vRoomRatesQryRes[0].RefKey2;
						
						vPacketBeginDate = cmGetDateFromTimestampPresentation(vPlacePacketAttrs.GetNamedItem("BeginDateTime").Value);
						If Not ValueIsFilled(vPacketBeginDate) Then
							vMsg = NStr("en = 'Error parsing <BeginDateTime> attribute of the <PlacePacket> element!'; de = 'Error parsing <BeginDateTime> attribute of the <PlacePacket> element!'; ru = 'Ошибка разбора значения атрибута <BeginDateTime> элемента <PlacePacket>!'");
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
							Raise vMsg;
						EndIf;
						vPacketEndDate = cmGetDateFromTimestampPresentation(vPlacePacketAttrs.GetNamedItem("EndDateTime").Value);
						If Not ValueIsFilled(vPacketEndDate) Then
							vMsg = NStr("en = 'Error parsing <EndDateTime> attribute of the <PlacePacket> element!'; de = 'Error parsing <EndDateTime> attribute of the <PlacePacket> element!'; ru = 'Ошибка разбора значения атрибута <EndDateTime> элемента <PlacePacket>!'");
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
							Raise vMsg;
						EndIf;
						
						If k = 0 Then
							If IsBlankString(vRoomRateCode) Then
								vRoomRateCode = TrimAll(vRoomRate.Code);
								vRoomRateCheckOutDate = vPacketEndDate; 
							EndIf;
						EndIf;
						
						// Fill room rates
						If vPlacePacketItems.Count() > 1 Then
							vCurDate = vPacketBeginDate;
							While vCurDate < vPacketEndDate Do
								vRoomRatesRow = vRoomRates.Add();
								vRoomRatesRow.AccountingDate = vCurDate;
								vRoomRatesRow.RoomRateCode = TrimAll(vRoomRate.Code);
								vRoomRatesRow.RoomRate = vRoomRate;
								vRoomRatesRow.PriceTag = vPriceTag;
								vCurDate = vCurDate + 24 * 3600;
							EndDo;
						EndIf;
					EndDo;
				EndIf;
				// Set the date of departure at the current rate to correctly calculate the restrictions.
				vCurrCheckOutDate = vCheckOutDate;
				If vRoomRates.Count() > 0 Then
					If Not vRoomRateCheckOutDate = Undefined And vCurrCheckOutDate > vRoomRateCheckOutDate Then
						vCurrCheckOutDate = vRoomRateCheckOutDate;
					EndIf;	
				EndIf;	
				// Fill reservation remarks
				vRoomServicePackagesList = Undefined;
				vRemarks = "";
				For Each vRoomServicesRow In vRoomServices Do
					If Not vRoomServicesRow.IsAvoided Then
						vRemarks = ?(IsBlankString(vRemarks), "", Chars.LF);
						vRemarks = vRoomServicesRow.ServiceCID + 
									NStr("en=', q-ty '; ru=', кол-во '") + Format(vRoomServicesRow.OrderAmount, "ND=10; NFD=0") + 
									?(ValueIsFilled(vRoomServicesRow.BeginDate), NStr("en=', period '; de=', period '; ru=', период '") + 
									Format(vRoomServicesRow.BeginDate, "DF=dd.MM.yy") + " - " + Format(vRoomServicesRow.EndDate, "DF=dd.MM.yy"), ""); 
						vServicePackage = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, TrimR(vInteraction.InteractionID), "ServicePackages", TrimAll(vRoomServicesRow.ServiceCID));
						If ValueIsFilled(vServicePackage) Then
							vServicePackageCode = TrimAll(vServicePackage.Code);
							If vRoomServicePackagesList = Undefined Then
								vRoomServicePackagesList = New ValueList();
							EndIf;
							vServicePackageStruct = New Structure("Service, IsRemoved, Quantity", vServicePackageCode, False, vRoomServicesRow.OrderAmount);
							vRoomServicePackagesList.Add(vServicePackageStruct);
						EndIf;
					Else
						vServicePackage = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, TrimR(vInteraction.InteractionID), "ServicePackages", TrimAll(vRoomServicesRow.ServiceCID));
						If ValueIsFilled(vServicePackage) Then
							vServicePackageCode = TrimAll(vServicePackage.Code);
							If vRoomServicePackagesList = Undefined Then
								vRoomServicePackagesList = New ValueList();
							EndIf;
							vServicePackageStruct = New Structure("Service, IsRemoved, Quantity", vServicePackageCode, True, vRoomServicesRow.OrderAmount);
							vRoomServicePackagesList.Add(vServicePackageStruct);
						EndIf;
					EndIf;
				EndDo;
				vPlaceServicePackagesList = Undefined;
				For Each vPlaceServicesRow In vPlaceServices Do
					If Not vPlaceServicesRow.IsAvoided Then
						vRemarks = ?(IsBlankString(vRemarks), "", Chars.LF);
						vRemarks = vPlaceServicesRow.ServiceCID + 
									NStr("en=', q-ty '; ru=', кол-во '") + Format(vPlaceServicesRow.OrderAmount, "ND=10; NFD=0") + 
									?(ValueIsFilled(vPlaceServicesRow.BeginDate), NStr("en=', period '; de=', period '; ru=', период '") + 
									Format(vPlaceServicesRow.BeginDate, "DF=dd.MM.yy") + " - " + Format(vPlaceServicesRow.EndDate, "DF=dd.MM.yy"), ""); 
						vServicePackage = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, TrimR(vInteraction.InteractionID), "ServicePackages", TrimAll(vPlaceServicesRow.ServiceCID));
						If ValueIsFilled(vServicePackage) Then
							vServicePackageCode = TrimAll(vServicePackage.Code);
							If vPlaceServicePackagesList = Undefined Then
								vPlaceServicePackagesList = New ValueList();
							EndIf;
							vServicePackageStruct = New Structure("Service, IsRemoved, Quantity", vServicePackageCode, False, vPlaceServicesRow.OrderAmount);
							vPlaceServicePackagesList.Add(vServicePackageStruct);
						EndIf;
					Else
						vServicePackage = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, TrimR(vInteraction.InteractionID), "ServicePackages", TrimAll(vPlaceServicesRow.ServiceCID));
						If ValueIsFilled(vServicePackage) Then
							vServicePackageCode = TrimAll(vServicePackage.Code);
							If vPlaceServicePackagesList = Undefined Then
								vPlaceServicePackagesList = New ValueList();
							EndIf;
							vServicePackageStruct = New Structure("Service, IsRemoved, Quantity", vServicePackageCode, True, vPlaceServicesRow.OrderAmount);
							vPlaceServicePackagesList.Add(vServicePackageStruct);
						EndIf;
					EndIf;
				EndDo;
				
				// Create reservation document based on data parsed
				If vInteraction.DebugMode Then
					vEventData = "ExtOrderNumber/GuestIndex: " + vExtOrderNumber + "/" + vGuestIndex + ", ExtGroupNumber: " + vExtGroupNumber + ", GroupCustomerName: " + vGroupCustomerName + 
								 ", ReservationStatusCode: " + vReservationStatusCode + ", CheckInDate: " + vCheckInDate + ", CheckOutDate: " + vCheckOutDate + ", HotelCode: " + TrimR(vInteraction.Hotel.Code) + 
								 ", RoomTypeCode: " + vRoomTypeCode + ", AccommodationTypeCode: " + vAccommodationTypeCode + ", AllotmentCode: " + vRoomQuotaCode + ", RoomRateCode: " + vRoomRateCode + 
								 ", GroupCustomerName: " + vGroupCustomerName + ", Guest: " + ?(vGuestsRow = Undefined, "", vGuestsRow.LastName) + " " + ?(vGuestsRow = Undefined, "", vGuestsRow.FirstName) + 
								 " " + ?(vGuestsRow = Undefined, "", vGuestsRow.SecondName) + ", Sex: " + ?(vGuestsRow = Undefined, "", vGuestsRow.SexCode) + ", CitizenshipCode: " + 
								 TrimAll(vInteraction.Hotel.Citizenship.Code) + ", BirthDate: " + ?(vGuestsRow = Undefined, '00010101', vGuestsRow.BirthDate) + 
								 ", Remarks: " + vRemarks + ", ReservationCreateDate: " + vReservationCreateDate + ", ReservationNumber: " + vReservationNumber + 
								 ", RoomReservation: " + vRoomReservation + ", CustomerIsPayer: " + vCustomerIsPayer;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Info, , , vEventData);
				EndIf;
				vRoomFirstGuest = False;
				vErrorDescription = "";
				
				If Not (ValueIsFilled(vAccommodationType) And vAccommodationType.Type = Enums.AccomodationTypes.Room Or vAccommodationType.Type = Enums.AccomodationTypes.Beds) Then
					vAccTemplate = Undefined;
				EndIf;	
				vResObj = cmWriteExternalReservationRow(vExtOrderNumber+"/"+vGuestIndex, vExtGroupNumber, "", vGroupCustomerName,  
														vReservationStatusCode, vCheckInDate, vCurrCheckOutDate, TrimR(vInteraction.Hotel.Code), vRoomTypeCode, 
														vAccommodationTypeCode, "", vRoomQuotaCode, vRoomRateCode,
														vGroupCustomerName, vContractName, "", "", 
														1, 1, 
														vExtOrderNumber + "/" + vGuestIndex, ?(vGuestsRow = Undefined, "", vGuestsRow.LastName), 
														?(vGuestsRow = Undefined, "", vGuestsRow.FirstName), ?(vGuestsRow = Undefined, "", vGuestsRow.SecondName), 
														?(vGuestsRow = Undefined, "", vGuestsRow.SexCode), TrimAll(vInteraction.Hotel.Citizenship.Code), 
														?(vGuestsRow = Undefined, '00010101', vGuestsRow.BirthDate), 
														"", "", "", "", , vRemarks, "", 
														"", vReservationCreateDate, TrimR(vInteraction.InteractionID), True, vDiscountCardID, 
														vErrorDescription, True, vReservationNumber, vRoomReservation, Not vCustomerIsPayer, , , , 
														vRoomServicePackagesList, , vDiscountTypeCode, , , vPlaceServicePackagesList, , , , , , , , , , , , , ,  , , , , , vAccTemplate);
				If Not IsBlankString(vErrorDescription) Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vErrorDescription);
					Raise vErrorDescription;
				EndIf;
				
				// Try to save guest passport data
				If ValueIsFilled(vResObj.Guest) And vGuestsRow <> Undefined And Not IsBlankString(vGuestsRow.PassportNumber) Then
					vGuestObj = vResObj.Guest.GetObject();
					vGuestObj.IdentityDocumentSeries = vGuestsRow.PassportSeries;
					vGuestObj.IdentityDocumentNumber = vGuestsRow.PassportNumber;
					vGuestObj.Write();
					vGuestObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
				
				// Try to fill guest group reference
				If Not ValueIsFilled(vGuestGroup) Then
					vGuestGroup = vResObj.GuestGroup;
				EndIf;
				If Not IsBlankString(vOrderWishes) Then
					If TrimR(vGuestGroup.Remarks) <> TrimR(vOrderWishes) Then
						vGuestGroupObj = vGuestGroup.GetObject();
						vGuestGroupObj.Remarks = vOrderWishes;
						vGuestGroupObj.Write();
					EndIf;
				EndIf;
				
				// Save reservation number to join all room guests together
				If IsBlankString(vReservationNumber) Then
					vReservationNumber = vResObj.Number;
				EndIf;
				If ValueIsFilled(vResObj.AccommodationType) And vResObj.AccommodationType.Type = Enums.AccomodationTypes.Room Then
					vRoomReservation = vResObj.Ref;
				EndIf;
				
				// Try to update room rates
				If vRoomRates.Count() > 0 Then
					vResObj.CheckOutDate = vCheckOutDate; // Set max date
					For Each vRoomRatesRow In vRoomRates Do
						vDocRoomRatesRow = vResObj.RoomRates.Find(vRoomRatesRow.AccountingDate, "AccountingDate");
						If vDocRoomRatesRow = Undefined Then
							vDocRoomRatesRow = vResObj.RoomRates.Add();
							vDocRoomRatesRow.AccountingDate = vRoomRatesRow.AccountingDate;
						EndIf;
						vDocRoomRatesRow.RoomRate = vRoomRatesRow.RoomRate;
					EndDo;
					vResObj.RoomRates.Sort("AccountingDate");
					vResObj.pmCalculateDuration();
					vResObj.pmCalculateServices();
					vResObj.Write(DocumentWriteMode.Posting);
				EndIf;
				vListOrder = Orders.cmGetOrdersByParentDoc(vResObj.Ref);
				vOrdersSum =  vListOrder.Total("Sum");
				vCurResAmount = vCurResAmount + vResObj.Services.Total("Sum") + vOrdersSum; 
			EndDo;
		EndDo;
		
		// Check customers and contracts per guest group. If more then one customer/contract then reset group flag
		If ValueIsFilled(vGuestGroup) Then
			vGroupCustomersAndContracts = GetGroupCustomersAndContracts(vGuestGroup);
			If vGroupCustomersAndContracts.Count() > 1 Then
				vGuestGroupObj = vGuestGroup.GetObject();
				vGuestGroupObj.OneCustomerPerGuestGroup = False;
				vGuestGroupObj.Write();
			EndIf;				
		EndIf;	   
		vCurResAmount = Format(vCurResAmount, "NG=");
		vExternalResAmount = String(vExternalResAmount);
		vCurResAmount 	   = СтрЗаменить(vCurResAmount, ".", ",");
		vExternalResAmount = СтрЗаменить(vExternalResAmount, ".", ",");
		If vExternalResAmount = vCurResAmount Then  
			CommitTransaction();
		Else     
			If TransactionActive() Then
				RollbackTransaction();    
			EndIf;   
			vErrorDescription = "tma_RemotingBookingPrice_Error = 'Заказ невозможен. Цена предложения не соответствует цене в удалённой системе'" + Chars.LF 
								+ "Цена КСБ: "+vExternalResAmount+ " Цена отеля: " + vCurResAmount;  
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation.BookingPrice_Error", Enums.ExternalSystemEventTypes.Error, , vErrorDescription, "RollbackTransaction");	
			Raise vErrorDescription;
		EndIf;
	Except     
		If TransactionActive() Then
			RollbackTransaction();    
		EndIf;
		vErrorDescription = ErrorDescription(); 
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation.Write_Error", Enums.ExternalSystemEventTypes.Error, , vErrorDescription, "Error"); 
		Raise vErrorDescription;
	EndTry;
	
	// Return guest group code and status
	rReservationNumber = Format(vGuestGroup.Code, "ND=12; NFD=0; NG=") + "/" + vExtRoomOrderNumber;
	If vInteraction.DebugMode Then
		vMessage =  NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Success, , rReservationNumber, vMessage);
	EndIf;

	Return "rrReserved";
EndFunction // DoMakeReservation

// -----------------------------------------------------------------------------
Function DoModifyReservation(vInteraction, vReservationItem)
	If vInteraction.DebugMode Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Info, , , vMsg);
	EndIf;
	
	BeginTransaction();
	
	vHotelObj = vInteraction.Hotel.GetObject();
	
	vResAttrs = vReservationItem.Attributes;
	vExtOrderNumber = TrimR(vResAttrs.GetNamedItem("OrderNumber").Value);
	vExtOrderNumberLen = StrLen(vExtOrderNumber);
	vExtRoomOrderNumber = "";
	vExtGroupNumber = GetExtGroupNumber(vExtOrderNumber, vExtRoomOrderNumber);
	vGroupNumber = "";
	Try
		vGroupNumber = GetGuestGroupCode(vResAttrs.GetNamedItem("SupplierOrderNumber").Value);
	Except
	EndTry;
	
	// SUM
	vExternalResAmount = vResAttrs.GetNamedItem("Price").Value;
	vCurResAmount = 0;

	vCurMappingTable = GetExtAccommodationTemplates(vInteraction);
	
	// Try to find reference to existing guest group
	vUnpostedReservations = New ValueList();
	vGuestGroup = cmGetGuestGroupByExternalCode(vInteraction.Hotel, vExtGroupNumber, "", "", False);
	If Not ValueIsFilled(vGuestGroup) And Not IsBlankString(vGroupNumber) Then
		vGuestGroup = Catalogs.GuestGroups.FindByCode(Number(vGroupNumber), False, , vInteraction.Hotel);
	EndIf;
	If Not ValueIsFilled(vGuestGroup) Then
		Return "mrrAbsent";
	Else
		// Try to find canceled reservation status
		vAnnulationStatus = cmGetReservationAnnulationStatus(vGuestGroup.ClientDoc);
		// Undo posting for each reservation in guest group
		vGuestGroupObj = vGuestGroup.GetObject();
		vReservations = vGuestGroupObj.pmGetReservations(True, True);
		If vReservations.Count() > 0 Then
			For Each vReservationsRow In vReservations Do
				vReservationRef = vReservationsRow.Reservation;
				vReservationObj = vReservationRef.GetObject();
				If Left(TrimR(vReservationObj.ExternalCode), vExtOrderNumberLen) = vExtOrderNumber Then
					If vInteraction.DebugMode Then
						vEventData = 
						"GuestGroup: " + vGuestGroup + ", ExtGroupNumber: " + vExtGroupNumber + 
						", ReservationStatusCode: " + TrimAll(vReservationRef.ReservationStatus) + ", CheckInDate: " + vReservationRef.CheckInDate + ", CheckOutDate: " + vReservationRef.CheckOutDate + ", HotelCode: " + TrimR(vInteraction.Hotel.Code) + ", RoomType: " + TrimAll(vReservationRef.RoomType) + 
						", AccommodationTypeCode: " + TrimAll(vReservationRef.AccommodationType) + ", AllotmentCode: " + TrimAll(vReservationRef.RoomQuota) + ", RoomRateCode: " + TrimAll(vReservationRef.RoomRate) + 
						", GroupCustomerName: " + TrimAll(vReservationRef.Customer) + ", Guest: " + TrimAll(vReservationRef.GuestFullName);
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Info, , , vEventData);
					EndIf;
					vReservationObj.Write(DocumentWriteMode.UndoPosting);
					vUnpostedReservations.Add(vReservationObj.Ref);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	vCustomer = Catalogs.Customers.EmptyRef();
	vCustomerName = vResAttrs.GetNamedItem("OrgJuridicalPersonCID").Value;
	vCustomerTIN = vResAttrs.GetNamedItem("OrgJuridicalPersonTIN").Value;
	vCustomerKPP = "";
	
	Try
		vCustomerKPP = vResAttrs.GetNamedItem("OrgJuridicalPersonKPP").Value;
	Except
	EndTry;
	vGroupCustomerName = vCustomerName;
	If Not IsBlankString(vCustomerTIN) And Not IsBlankString(vCustomerKPP) Then
		vCustomer = cmGetCustomerByTIN(TrimAll(vCustomerTIN), TrimAll(vCustomerKPP), TrimAll(vCustomerName));
	EndIf;
	If Not ValueIsFilled(vCustomer) Then
		vCustomer = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "Customers", vGroupCustomerName);
	EndIf;
	If ValueIsFilled(vCustomer) Then
		vGroupCustomerName = TrimAll(vCustomer.Description);
		If IsBlankString(vCustomer.TIN) And Not IsBlankString(vCustomerTIN) Then
			vCustomerObj = vCustomer.GetObject();
			vCustomerObj.TIN = TrimAll(vCustomerTIN);
			vCustomerObj.KPP = TrimAll(vCustomerKPP);
			vCustomerObj.Write();
			vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndIf;
	vRoomTypeCode = vResAttrs.GetNamedItem("RoomCategoryCID").Value;
	vRoomType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "RoomTypes", vRoomTypeCode);
	vNumberOfBedsPerRoom = 1;
	If ValueIsFilled(vRoomType) Then
		vNumberOfBedsPerRoom = vRoomType.NumberOfBedsPerRoom;
	EndIf;
	
	vBaseSeatQuantity = Number(vResAttrs.GetNamedItem("BaseSeatQuantity").Value);
	vRoomQuantity = vBaseSeatQuantity/vNumberOfBedsPerRoom;
	If vRoomQuantity <> Int(vBaseSeatQuantity/vNumberOfBedsPerRoom) Then
		vRoomQuantity = Int(vRoomQuantity) + 1;
	EndIf;
	vExtSeatQuantity = Number(vResAttrs.GetNamedItem("ExtSeatQuantity").Value);
	vCheckInDate = cmGetDateFromTimestampPresentation(vResAttrs.GetNamedItem("BeginDateTime").Value);
	If Not ValueIsFilled(vCheckInDate) Then
		vMsg = NStr("en='Error parsing <BeginDateTime> attribute of the <Reservation> element!'; de='Error parsing <BeginDateTime> attribute of the <Reservation> element!'; ru='Ошибка разбора значения атрибута <BeginDateTime> элемента <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	vCheckOutDate = cmGetDateFromTimestampPresentation(vResAttrs.GetNamedItem("EndDateTime").Value);
	If Not ValueIsFilled(vCheckOutDate) Then
		vMsg = NStr("en='Error parsing <EndDateTime> attribute of the <Reservation> element!'; de='Error parsing <EndDateTime> attribute of the <Reservation> element!'; ru='Ошибка разбора значения атрибута <EndDateTime> элемента <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	vDuration = Number(vResAttrs.GetNamedItem("OrderAmount").Value);
	vReservationCreateDate = cmGetDateFromTimestampPresentation(vResAttrs.GetNamedItem("OrderDateTime").Value);
	
	If Not ValueIsFilled(vReservationCreateDate) Then
		vMsg = NStr("en='Error parsing <OrderDateTime> attribute of the <Reservation> element!'; de='Error parsing <OrderDateTime> attribute of the <Reservation> element!'; ru='Ошибка разбора значения атрибута <OrderDateTime> элемента <Reservation>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	
	// Check reservation check-in date. If it is in the past then do nothing  
	If vInteraction.UniqueProfilesControl Then
		If vCheckInDate < CurrentSessionDate() Then
			// Check if there are any unposted reservations left
			For Each vUnpostedReservationItem In vUnpostedReservations Do
				vUnpostedReservation = vUnpostedReservationItem.Value;
				If Not vUnpostedReservation.Posted Then
					// Restore reservation state
					vResObj = vUnpostedReservation.GetObject();
					vResObj.Write(DocumentWriteMode.Posting);
				EndIf;
			EndDo;
			vMsg = NStr("en='Check-in date is in the past! External call is skipped.'; de='Check-in date is in the past! External call is skipped.'; ru='Дата заезда в прошлом! Внешний вызов игнорируется.'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
			Raise vMsg;
		EndIf;  
	Else	
		If BegOfDay(vCheckInDate) < BegOfDay(CurrentSessionDate()) Then
			// Check if there are any unposted reservations left
			For Each vUnpostedReservationItem In vUnpostedReservations Do
				vUnpostedReservation = vUnpostedReservationItem.Value;
				If Not vUnpostedReservation.Posted Then
					// Restore reservation state
					vResObj = vUnpostedReservation.GetObject();
					vResObj.Write(DocumentWriteMode.Posting);
				EndIf;
			EndDo;
			vMsg = NStr("en='Check-in date is in the past! External call is skipped.'; de='Check-in date is in the past! External call is skipped.'; ru='Дата заезда в прошлом! Внешний вызов игнорируется.'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
			Raise vMsg;
		EndIf;  
	EndIf;
	
	// Try to bind to promo action
	vDiscountTypeCode = "";
	vDiscountCardID = "";
	vPromoCode = "";
	vPromoPhone = "";
	vPromoVerificationCode = "";
	If vResAttrs.GetNamedItem("PromoMemberID") <> Undefined Then
		vPromoCode = vResAttrs.GetNamedItem("PromoCode").Value;
		vPromoPhone = vResAttrs.GetNamedItem("PromoMemberID").Value;
		vPromoVerificationCode = vResAttrs.GetNamedItem("PromoVerificationCode").Value;
		If Not IsBlankString(vPromoPhone) Then
			// Try to check verification code over phone
			vRcdMgr = GetVerificationRecordByPhoneAndCode(vPromoCode, vPromoPhone, vPromoVerificationCode);
			If vRcdMgr <> Undefined Then
				If Not vRcdMgr.IsUsed Then
					vRcdMgr.IsUsed = True;
					vRcdMgr.DateUsed = CurrentSessionDate();
					vRcdMgr.Write();
				EndIf;
				// Try to find discount type by promo code
				If Not IsBlankString(vPromoCode) Then
					vDiscountType = GetDiscountTypeByPromoCode(vPromoCode);
					If ValueIsFilled(vDiscountType) Then
						vDiscountTypeCode = TrimR(vDiscountType.Code);
					Else
						vDiscountCard = GetDiscountCardByPromoCode(vPromoCode, vPromoPhone);
						If ValueIsFilled(vDiscountCard) Then
							vDiscountCardID = TrimR(vDiscountCard.Identifier);
						EndIf;
					EndIf;
				EndIf;
			Else
				vMsg = NStr("en='Failed to confirm verification code!'; de='Der Bestätigungscode konnte nicht bestätigt werden!'; ru='Не удалось проверить код подтверждения!'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
				Raise vMsg;
			EndIf;
		EndIf;
	EndIf;
	
	// We do not update allotment in modification mode
	vRoomQuota = Catalogs.RoomQuotas.EmptyRef();
	vRoomQuotaCode = "";
	
	// Fill contract by room type
	vContractName = "";
	If ValueIsFilled(vCustomer) Then
		vContract = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "Contracts", TrimAll(vCustomerName));
		If ValueIsFilled(vContract) Then
			vContractName = TrimAll(vCustomerName);
		EndIf;
	EndIf;
	
	// Get list of all guests in the reservation
	vGuests = New ValueTable();
	vGuests.Columns.Add("ID", cmGetStringTypeDescription());
	vGuests.Columns.Add("FullName", cmGetStringTypeDescription());
	vGuests.Columns.Add("FirstName", cmGetStringTypeDescription());
	vGuests.Columns.Add("LastName", cmGetStringTypeDescription());
	vGuests.Columns.Add("SecondName", cmGetStringTypeDescription());
	vGuests.Columns.Add("SexCode", cmGetStringTypeDescription());
	vGuests.Columns.Add("Passport", cmGetStringTypeDescription());
	vGuests.Columns.Add("PassportSeries", cmGetStringTypeDescription());
	vGuests.Columns.Add("PassportNumber", cmGetStringTypeDescription());
	vGuests.Columns.Add("BirthDate", cmGetDateTypeDescription());
	vGuests.Columns.Add("Age", cmGetNumberTypeDescription(4, 0));
	
	vTouristItems = vReservationItem.GetElementByTagName("Tourist");
	If vTouristItems.Count() > 0 Then
		For i = 0 To (vTouristItems.Count() - 1) Do
			vTouristItem = vTouristItems.Item(i);
			vTouristAttrs = vTouristItem.Attributes;
			
			vGuestsRow = vGuests.Add();
			vGuestsRow.ID = vTouristAttrs.GetNamedItem("TouristID").Value;
			Try
				vGuestsRow.Passport = vTouristAttrs.GetNamedItem("PassportData").Value;
				If Not IsBlankString(vGuestsRow.Passport) Then
					vGuestsRow.Passport = StrReplace(vGuestsRow.Passport, "№", "");
					vGuestsRow.Passport = StrReplace(vGuestsRow.Passport, "#", "");
					vGuestsRow.Passport = StrReplace(vGuestsRow.Passport, "N", "");
					vGuestsRow.Passport = StrReplace(vGuestsRow.Passport, "  ", " ");
					vGuestsRow.Passport = StrReplace(vGuestsRow.Passport, "  ", " ");
					If StrLen(vGuestsRow.Passport) > 6 Then
						cmParsePassportNumber(TrimAll(vGuestsRow.Passport), vGuestsRow.PassportSeries, vGuestsRow.PassportNumber);
					EndIf;
				EndIf;
			Except
			EndTry;
			Try
				vGuestsRow.BirthDate = cmGetDateFromDatePresentation(vTouristAttrs.GetNamedItem("BirthDate").Value);
			Except
			EndTry;
			Try
				vGuestsRow.Age = Number(vTouristAttrs.GetNamedItem("Age").Value);
			Except
			EndTry;
			vMLTextItems = vTouristItem.GetElementByTagName("MLText");
			If vMLTextItems.Count() = 0 Then
				vMsg = NStr("en='<MLText> element is missing in the XML data!'; de='<MLText> element is missing in the XML data!'; ru='В XML данных не найден элемент <MLText>!'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
				Raise vMsg;
			EndIf;
			vMLTextItem = vMLTextItems.Item(0);
			vMLTextAttrs = vMLTextItem.Attributes;
			vGuestsRow.FullName = vMLTextAttrs.GetNamedItem("Text").Value;
			vGuestsRow.SexCode = "M";
			
			// Try to parse guest full name to the 3 parts
			If Not IsBlankString(vGuestsRow.FullName) Then
				vGuestSex = Undefined;
				cmParseClientFullName(vGuestsRow.FullName, vGuestsRow.LastName, vGuestsRow.FirstName, vGuestsRow.SecondName, vGuestSex);
				If ValueIsFilled(vGuestSex) Then
					If vGuestSex = Enums.Sex.Male Then
						vGuestsRow.SexCode = "M";
					Else
						vGuestsRow.SexCode = "F";
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Get order wishes
	vOrderWishes = "";
	vOrderWishesItems = vReservationItem.GetElementByTagName("OrderWishes");
	If vOrderWishesItems.Count() > 0 Then
		For i = 0 To (vOrderWishesItems.Count() - 1) Do
			vOrderWishesItem = vOrderWishesItems.Item(i);
			vMLTextItems = vOrderWishesItem.GetElementByTagName("MLText");
			If vMLTextItems.Count() = 0 Then
				vMsg = NStr("en='<MLText> element is missing in the XML data!'; de='<MLText> element is missing in the XML data!'; ru='В XML данных не найден элемент <MLText>!'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
				Raise vMsg;
			EndIf;
			vMLTextItem = vMLTextItems.Item(0);
			vMLTextAttrs = vMLTextItem.Attributes;
			If IsBlankString(vOrderWishes) Then
				vOrderWishes = vMLTextAttrs.GetNamedItem("Text").Value;
			Else
				vOrderWishes = vOrderWishes + Chars.LF + vMLTextAttrs.GetNamedItem("Text").Value;
			EndIf;				
		EndDo;
	EndIf;
	If Not IsBlankString(vOrderWishes) Then
		If TrimR(vGuestGroupObj.Remarks) <> TrimR(vOrderWishes) Then
			vGuestGroupObj.Remarks = vOrderWishes;
			vGuestGroupObj.Write();
		EndIf;
	EndIf;
	
	// Get list of all rooms in the reservation
	vRoomItems = vReservationItem.GetElementByTagName("Room");
	If vRoomItems.Count() = 0 Then
		vMsg = NStr("en='<Room> element is missing in the XML data!'; de='<Room> element is missing in the XML data!'; ru='В XML данных не найден элемент <Room>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	vRoomsCount = vRoomItems.Count();
	If ValueIsFilled(vCheckInDate) Then
		// Check if this is preliminary guest group
		vIsPreliminary = vGuestGroupObj.pmIsPreliminary();
		// Fill guest group room inventory totals
		vRITotalsRooms = 0;
		vRITotals = vGuestGroupObj.pmGetRoomInventoryTotals(vCheckInDate);
		If vRITotals.Count() > 0 Then
			vRITotalsRow = vRITotals.Get(0);
			If Not vIsPreliminary Then
				vRITotalsRooms = vRITotalsRow.RoomsReserved + vRITotalsRow.RoomsCheckedIn;
			Else
				vRITotalsRooms = vRITotalsRow.RoomsExpected;
			EndIf;
		EndIf;
		vRoomsCount = vRoomsCount + vRITotalsRooms;
	EndIf;
	
	vLogEventData = "Customer: " + vCustomerName + Chars.LF +
					"Room type: " + vRoomTypeCode + Chars.LF +
					"CheckInDate: " + vCheckInDate + Chars.LF +
					"CheckOutDate: " + vCheckOutDate + Chars.LF +
					"Amount: " + vResAttrs.GetNamedItem("Price").Value + Chars.LF;
	
	For i = 0 To (vRoomItems.Count() - 1) Do
		vRoomItem = vRoomItems.Item(i);
		vLastUsedGuestIndex = 0;
		vRoomFirstGuest = True;
		vReservationNumber = "";
		vRoomPlaceItemIsSet = False;
		vRoomReservation = Undefined;
		// Check if this room should be canceled
		vReservationStatusCode = "";
		vRoomAttrs = vRoomItem.Attributes;
		vRoomIsCanceled = False;
		vAccommodationTypeRoomIsFound = False;
		Try
			vRoomIsCanceled = XMLValue(Type("Boolean"),vRoomAttrs.GetNamedItem("IsAvoided").Value);
		Except
		EndTry;
		vPricePerRoom = True;
		Try
			vPricePerRoom = XMLValue(Type("Boolean"),vRoomAttrs.GetNamedItem("PricePerRoom").Value);
		Except
		EndTry;
		
		vPricePerRoom = vRoomAttrs.GetNamedItem("PricePerRoom").Value;
		vLogEventData = vLogEventData + "PricePerRoom: " + vPricePerRoom + Chars.LF;
		vLogEventData = vLogEventData + "RoomIsCanceled: " + vRoomIsCanceled + Chars.LF;
		
		If vRoomIsCanceled Then
			vReservationStatusCode = TrimR(vAnnulationStatus.Code);
		EndIf;
		// Get room services
		vRoomServices = InitServices();
		vRoomServiceListItems = vRoomItem.GetElementByTagName("RoomServiceList");
		If vRoomServiceListItems.Count() > 0 Then
			vRoomServiceListItem = vRoomServiceListItems.Item(0);
			LoadServices(vRoomServices, vRoomServiceListItem, "RoomService");
		EndIf;
		vResObj = Undefined;
		vAccTemplate = Undefined;
		// Get places for the given room
		vPlaceItems = vRoomItem.GetElementByTagName("Place");
		If vPlaceItems.Count() = 0 Then
			vMsg = NStr("en='<Place> element is missing in the XML data!'; de='<Place> element is missing in the XML data!'; ru='В XML данных не найден элемент <Place>!'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
			Raise vMsg;
		EndIf;
		
		vTabPriceRoom = New ValueTable;
		vTabPriceRoom.Columns.Add("Quantity");
		vTabPriceRoom.Columns.Add("PlaceKind");
		vTabPriceRoom.Columns.Add("TouristTypeCID");
		vTabPriceRoom.Columns.Add("AccommodationType");
		vTabPriceRoom.Columns.Add("TouristID");
		
		For j = 0 To (vPlaceItems.Count() - 1) Do
			vPlaceItem = vPlaceItems.Item(j);
			vPlaceAttrs = vPlaceItem.Attributes;
			
			vPlaceKind = TrimR(vPlaceAttrs.GetNamedItem("PlaceKind").Value);
			vTouristTypeCID = vPlaceAttrs.GetNamedItem("TouristTypeCID").Value;
			
			vGuestID = "";
			Try
				vGuestID = vPlaceAttrs.GetNamedItem("TouristID").Value;
			Except
			EndTry;

			vAccTypeCode = TrimR(vPlaceKind + "/" + vTouristTypeCID);
			vAccType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "AccommodationTypes", vAccTypeCode);
			
			If Not IsBlankString(vTouristTypeCID) And Not IsBlankString(vPlaceKind) Then
				vNewRowTabPriceRoom = vTabPriceRoom.Add();
				vNewRowTabPriceRoom.Quantity = 1;
				vNewRowTabPriceRoom.PlaceKind = vPlaceKind;
				vNewRowTabPriceRoom.TouristTypeCID = vTouristTypeCID;
				vNewRowTabPriceRoom.AccommodationType = vAccType;
				vNewRowTabPriceRoom.TouristID = vGuestID;
			EndIf;	
		EndDo;
		
		// Get accommodation template
		vAccTemplateList = vTabPriceRoom.Copy();
		vAccTemplateList.GroupBy("PlaceKind, TouristTypeCID","Quantity");
		vAccTemplateList.Sort("PlaceKind, TouristTypeCID, Quantity");
		vUUID = vRoomTypeCode;
		For Each vResRow In vAccTemplateList Do 
			vUUID = vUUID + vResRow.TouristTypeCID + vResRow.PlaceKind + String(vResRow.Quantity);
		EndDo;
		If vCurMappingTable = Undefined Or vCurMappingTable.Count() = 0 Then
			vMsg = Nstr("en = 'List accomodation templates is empty'; de = 'Keine Übereinstimmung in ALEAN CRS für Unterkunftsvorlagen gefunden'; ru = 'Список шаблонов размещения пустой. Необходимо выполнить первичную синхронизацию'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
			Raise vMsg;
		Else
			vFilter = vCurMappingTable.FindRows(New Structure("RoomType", vRoomType));
			If vFilter.Count() > 0 Then
				For Each vRowFilter In vFilter Do
					If vRowFilter.UUID = vUUID Then
						vAccTemplate = vRowFilter.AccommodationTemplate;
					EndIf;	
				EndDo;	
			Else
				vMsg = Nstr("en = 'Not found accommodation template'; de = 'Not found accommodation template'; ru = 'Не найден шаблон размещения'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
				Raise vMsg;
			EndIf;	
		EndIf;
		
		vAccommodationTypesList = New Array;
		If Not vAccTemplate = Undefined Then
			vAccommodationTypesList = vAccTemplate.AccommodationTypes.UnloadColumn("AccommodationType");
		Else
			If vInteraction.DebugMode Then
				vMsg = Nstr("en = 'Accomodation template not found!'; de = 'Accomodation template not found!'; ru = 'Шаблон размещения не найден'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
			EndIf;	
		EndIf;	
		For j = 0 To (vPlaceItems.Count() - 1) Do
			vPlaceItem = vPlaceItems.Item(j);
			vPlaceAttrs = vPlaceItem.Attributes;
			
			// Accommodation type code
			vAccommodationTypeCode = TrimR(vPlaceAttrs.GetNamedItem("PlaceKind").Value + "/" + vPlaceAttrs.GetNamedItem("TouristTypeCID").Value);
			vAccommodationType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "AccommodationTypes", vAccommodationTypeCode);
			If Not ValueIsFilled(vAccommodationType) Then
				vMsg = NStr("en = 'Accommodation type mapping is missing for external code! '; de = 'Accommodation type mapping is missing for external code! '; ru = 'Не задано соответствие кодов для вида размещения с внешним кодом! '") + vAccommodationTypeCode;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
				Raise vMsg;
			EndIf;
			vAccommodationTypeIsSet = False;
			If vAccommodationTypesList.Count() > 0 Then
				vIDRow = vAccommodationTypesList.Find(vAccommodationType);
				If vIDRow = Undefined Then
					vIDRow = 0;
				EndIf;
				vAccommodationType =  vAccommodationTypesList.Get(vIDRow);
				vAccommodationTypeCode = TrimR(vAccommodationType.Code);
				vAccommodationTypesList.Delete(vIDRow);
				vAccommodationTypeIsSet = True;
				If vInteraction.DebugMode Then
					vMsg = Nstr("en = 'Accomodation type set by accomodation template'; de = 'Accomodation type set by accomodation template'; ru = 'Вид  размещения подставлен по шаблону'");
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Info, , , vMsg);
				EndIf;	
			EndIf;	
			If vAccommodationTypeIsSet = False Then	
				If vPlaceItems.Count() = 1 Then
					If vAccommodationType.Type = Enums.AccomodationTypes.Beds Then
						vNewAccommodationType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "AccommodationTypes", "OneGuestInRoom");
						If ValueIsFilled(vNewAccommodationType) Then
							vAccommodationType = vNewAccommodationType;
							vAccommodationTypeCode = TrimR(vNewAccommodationType.Code);
						EndIf;
					EndIf;
				ElsIf vPlaceItems.Count() >= 2 Then
					If vAccommodationType.Type = Enums.AccomodationTypes.Beds Then
						If vRoomPlaceItemIsSet Then
							vNewAccommodationType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "AccommodationTypes", "Together");
							If ValueIsFilled(vNewAccommodationType) Then
								vAccommodationType = vNewAccommodationType;
								vAccommodationTypeCode = TrimR(vNewAccommodationType.Code);
							EndIf;
						Else
							vNewAccommodationType = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "AccommodationTypes", "MainGuestInRoom");
							If ValueIsFilled(vNewAccommodationType) Then
								vAccommodationType = vNewAccommodationType;
								vAccommodationTypeCode = TrimR(vNewAccommodationType.Code);
								vRoomPlaceItemIsSet = True;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			// Load place services
			vPlaceServices = InitServices();
			vPlaceServiceListItems = vPlaceItem.GetElementByTagName("PlaceServiceList");
			If vPlaceServiceListItems.Count() > 0 Then
				vPlaceServiceListItem = vPlaceServiceListItems.Item(0);
				LoadServices(vPlaceServices, vPlaceServiceListItem, "PlaceService");
			EndIf;
			
			// Read guest ID and try to match it with guest data
			vGuestsRow = Undefined;
			vGuestID = "";
			Try
				vGuestID = vPlaceAttrs.GetNamedItem("TouristID").Value;
			Except
			EndTry;
			If Not IsBlankString(vGuestID) Then
				vGuestsRow = vGuests.Find(vGuestID, "ID");
			EndIf;
			vGuestIndex = Format((i*1000 + vLastUsedGuestIndex), "ND=6; NFD=0; NZ=; NLZ=; NG=");
			vLastUsedGuestIndex = vLastUsedGuestIndex + 1;
			
			// Room rates value table
			vRoomRates = New ValueTable();
			vRoomRates.Columns.Add("AccountingDate", cmGetDateTypeDescription());
			vRoomRates.Columns.Add("RoomRateCode", cmGetStringTypeDescription());
			vRoomRates.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
			vRoomRates.Columns.Add("PriceTag");
			vRoomRateCode = "";
			
			// Read room rates
			vPlacePacketItems = vPlaceItem.GetElementByTagName("PlacePacket");
			If vPlacePacketItems.Count() > 0 Then
				For k = 0 To (vPlacePacketItems.Count() - 1) Do
					vPlacePacketItem = vPlacePacketItems.Item(k);
					vPlacePacketAttrs = vPlacePacketItem.Attributes;
					
					vPacketShortName = vPlacePacketAttrs.GetNamedItem("PacketCID").Value;
					vRoomRatesQryRes = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "RoomRates",,,,,vPacketShortName);
					If vRoomRatesQryRes.Count() = 0 Then
						vMsg = NStr("en='Failed to read mapping for the room rate with code '; de='Failed to read mapping for the room rate with code '; ru='Не удалось найти соответствие для тарифа с кодом '") + vPacketShortName + "!";
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
						Raise vMsg;
					EndIf;
					vRoomRate = vRoomRatesQryRes[0].RefKey1;
					vPriceTag = vRoomRatesQryRes[0].RefKey2;

					vPacketBeginDate = cmGetDateFromTimestampPresentation(vPlacePacketAttrs.GetNamedItem("BeginDateTime").Value);
					If Not ValueIsFilled(vPacketBeginDate) Then
						vMsg = NStr("en='Error parsing <BeginDateTime> attribute of the <PlacePacket> element!'; de='Error parsing <BeginDateTime> attribute of the <PlacePacket> element!'; ru='Ошибка разбора значения атрибута <BeginDateTime> элемента <PlacePacket>!'");
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
						Raise vMsg;
					EndIf;
					vPacketEndDate = cmGetDateFromTimestampPresentation(vPlacePacketAttrs.GetNamedItem("EndDateTime").Value);
					If Not ValueIsFilled(vPacketEndDate) Then
						vMsg = NStr("en='Error parsing <EndDateTime> attribute of the <PlacePacket> element!'; de='Error parsing <EndDateTime> attribute of the <PlacePacket> element!'; ru='Ошибка разбора значения атрибута <EndDateTime> элемента <PlacePacket>!'");
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Error, , , vMsg);
						Raise vMsg;
					EndIf;
					
					If k = 0 Then
						vRoomRateCode = TrimAll(vRoomRate.Code);
					EndIf;
					
					// Fill room rates
					If vPlacePacketItems.Count() > 1 Then
						vCurDate = vPacketBeginDate;
						While vCurDate < vPacketEndDate Do
							vRoomRatesRow = vRoomRates.Add();
							vRoomRatesRow.AccountingDate = vCurDate;
							vRoomRatesRow.RoomRateCode = TrimAll(vRoomRate.Code);
							vRoomRatesRow.RoomRate = vRoomRate;
							vRoomRatesRow.PriceTag = vPriceTag;
							vCurDate = vCurDate + 24*3600;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
			
			// Fill reservation remarks
			vRoomServicePackagesList = Undefined;
			vRemarks = "";
			For Each vRoomServicesRow In vRoomServices Do
				If Not vRoomServicesRow.IsAvoided Then
					vRemarks = ?(IsBlankString(vRemarks), "", Chars.LF);
					vRemarks = vRoomServicesRow.ServiceCID + 
					NStr("en=', q-ty '; de=', q-ty '; ru=', кол-во '") + Format(vRoomServicesRow.OrderAmount, "ND=10; NFD=0") 
					+ ?(ValueIsFilled(vRoomServicesRow.BeginDate), NStr("en=', period '; de=', period '; ru=', период '") + Format(vRoomServicesRow.BeginDate, "DF=dd.MM.yy") + " - " + Format(vRoomServicesRow.EndDate, "DF=dd.MM.yy"), ""); 
					vServicePackage = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, TrimR(vInteraction.InteractionID), "ServicePackages", TrimAll(vRoomServicesRow.ServiceCID));
					If ValueIsFilled(vServicePackage) Then
						vServicePackageCode = TrimAll(vServicePackage.Code);
						If vRoomServicePackagesList = Undefined Then
							vRoomServicePackagesList = New ValueList();
						EndIf;
						vServicePackageStruct = New Structure("Service, IsRemoved", vServicePackageCode, False);
						vRoomServicePackagesList.Add(vServicePackageStruct);
					EndIf;
				Else
					vServicePackage = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, TrimR(vInteraction.InteractionID), "ServicePackages", TrimAll(vRoomServicesRow.ServiceCID));
					If ValueIsFilled(vServicePackage) Then
						vServicePackageCode = TrimAll(vServicePackage.Code);
						If vRoomServicePackagesList = Undefined Then
							vRoomServicePackagesList = New ValueList();
						EndIf;
						vServicePackageStruct = New Structure("Service, IsRemoved", vServicePackageCode, False);
						vRoomServicePackagesList.Add(vServicePackageStruct);
					EndIf;
				EndIf;
			EndDo;
			vExtReservationCode = vExtOrderNumber+"/"+vGuestIndex;
			vPlaceServicePackagesList = Undefined;
			For Each vPlaceServicesRow In vPlaceServices Do
				If Not vPlaceServicesRow.IsAvoided Then
					vRemarks = ?(IsBlankString(vRemarks), "", Chars.LF);
					vRemarks = vPlaceServicesRow.ServiceCID + 
					NStr("en=', q-ty '; de=', q-ty '; ru=', кол-во '") + Format(vPlaceServicesRow.OrderAmount, "ND=10; NFD=0") + 
					?(ValueIsFilled(vPlaceServicesRow.BeginDate), NStr("en=', period '; de=', period '; ru=', период '") + Format(vPlaceServicesRow.BeginDate, "DF=dd.MM.yy") + " - " + Format(vPlaceServicesRow.EndDate, "DF=dd.MM.yy"), ""); 
					vServicePackage = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, TrimR(vInteraction.InteractionID), "ServicePackages", TrimAll(vPlaceServicesRow.ServiceCID));
					If ValueIsFilled(vServicePackage) Then
						vServicePackageCode = TrimAll(vServicePackage.Code);
						If vPlaceServicePackagesList = Undefined Then
							vPlaceServicePackagesList = New ValueList();
						EndIf;
						vServicePackageStruct = New Structure("Service, IsRemoved", vServicePackageCode, False);
						vPlaceServicePackagesList.Add(vServicePackageStruct);
					EndIf;
				Else
					vServicePackage = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, TrimR(vInteraction.InteractionID), "ServicePackages", TrimAll(vPlaceServicesRow.ServiceCID));
					If ValueIsFilled(vServicePackage) Then
						vServicePackageCode = TrimAll(vServicePackage.Code);
						If vPlaceServicePackagesList = Undefined Then
							vPlaceServicePackagesList = New ValueList();
						EndIf;
						vServicePackageStruct = New Structure("Service, IsRemoved", vServicePackageCode, True);
						vPlaceServicePackagesList.Add(vServicePackageStruct);
					EndIf;
				EndIf;
			EndDo;
			// Try to find existing reservation with given external code
			If Not IsBlankString(vExtReservationCode) Then
				vDocRef = cmGetReservationByExternalCode(vInteraction.Hotel, vExtReservationCode);
			EndIf;
			// Check delete service package in KSB 
			If ValueIsFilled(vDocRef) Then
				If vPlaceServicePackagesList = Undefined Then
					vPlaceServicePackagesList = New ValueList();
				EndIf;	
				// Check main service package
				vMainSP = vDocRef.ServicePackage;
				If ValueIsFilled(vMainSP) Then
					vMainSPCode = TrimAll(vMainSP.Code);
					vItemRow = Undefined;
					For Each vSP In vPlaceServicePackagesList Do
						If vSP.Value.Service = vMainSPCode Then
							vItemRow = vSP;
							Break;
						EndIf;	
					EndDo;	
					If vItemRow = Undefined Then
						vPlaceServicePackagesList.Add(New Structure("Service, IsRemoved", vMainSPCode, True));
					Else
						vPlaceServicePackagesList.Delete(vItemRow);
					EndIf;	
				EndIf;
				// Check other service package
				For Each vSPRow In vDocRef.ServicePackages Do
					vSPCode = TrimAll(vSPRow.ServicePackage.Code);
					vItemRow = Undefined;
					For Each vSP In vPlaceServicePackagesList Do
						If vSP.Value.Service = vMainSPCode Then
							vItemRow = vSP;
							Break;
						EndIf;	
					EndDo;	
					If vItemRow = Undefined Then
						vPlaceServicePackagesList.Add(New Structure("Service, IsRemoved", vSPCode, True));
					Else
						vPlaceServicePackagesList.Delete(vItemRow);	
					EndIf;		
				EndDo; 
			EndIf;	
			// Create reservation document based on data parsed
			vRoomFirstGuest = False;
			vErrorDescription = "";
			vOldReservationStatus = Undefined;
			If vInteraction.DebugMode Then
				vEventData = 
							"ExtOrderNumber/GuestIndex: " + vExtReservationCode + ", ExtGroupNumber: " + vExtGroupNumber + ", GroupCustomerName: " + vGroupCustomerName + 
							", ReservationStatusCode: " + vReservationStatusCode + ", CheckInDate: " + vCheckInDate + ", CheckOutDate: " + vCheckOutDate + ", HotelCode: " + TrimR(vInteraction.Hotel.Code) + ", RoomTypeCode: " + vRoomTypeCode + 
							", AccommodationTypeCode: " + vAccommodationTypeCode + ", AllotmentCode: " + vRoomQuotaCode + ", RoomRateCode: " + vRoomRateCode + 
							", GroupCustomerName: " + vGroupCustomerName + ", Guest: " + ?(vGuestsRow = Undefined, "", vGuestsRow.LastName) + " " + ?(vGuestsRow = Undefined, "", vGuestsRow.FirstName) + " " + ?(vGuestsRow = Undefined, "", vGuestsRow.SecondName) + 
							", Sex: " + ?(vGuestsRow = Undefined, "", vGuestsRow.SexCode) + ", CitizenshipCode: " + TrimAll(vInteraction.Hotel.Citizenship.Code) + ", BirthDate: " + ?(vGuestsRow = Undefined, '00010101', vGuestsRow.BirthDate) + 
							", Remarks: " + vRemarks + ", ReservationCreateDate: " + vReservationCreateDate + ", ReservationNumber: " + vReservationNumber + ", RoomReservation: " + vRoomReservation;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Info, , , vEventData);
			EndIf;
			If Not (ValueIsFilled(vAccommodationType) And vAccommodationType.Type = Enums.AccomodationTypes.Room Or vAccommodationType.Type = Enums.AccomodationTypes.Beds) Then
				vAccTemplate = Undefined;
			EndIf;	
			vResObj = cmWriteExternalReservationRow(vExtReservationCode, vExtGroupNumber, "", vGroupCustomerName,  
													vReservationStatusCode, vCheckInDate, vCheckOutDate, TrimR(vInteraction.Hotel.Code), vRoomTypeCode, 
													vAccommodationTypeCode, "", vRoomQuotaCode, vRoomRateCode,
													vGroupCustomerName, vContractName, "", "", 
													1, 1, 
													vExtOrderNumber+"/"+vGuestIndex, ?(vGuestsRow = Undefined, "", vGuestsRow.LastName), ?(vGuestsRow = Undefined, "", vGuestsRow.FirstName), 
													?(vGuestsRow = Undefined, "", vGuestsRow.SecondName), 
													?(vGuestsRow = Undefined, "", vGuestsRow.SexCode), TrimAll(vInteraction.Hotel.Citizenship.Code), ?(vGuestsRow = Undefined, '00010101', vGuestsRow.BirthDate), 
													"", "", "", "", , vRemarks, "", 
													"", vReservationCreateDate, TrimR(vInteraction.InteractionID), True, vDiscountCardID, 
													vErrorDescription, True, vReservationNumber, vRoomReservation, , , vOldReservationStatus, , vRoomServicePackagesList, , vDiscountTypeCode, , , 
													vPlaceServicePackagesList,,,,,,,,,,,,,,,,,,, vAccTemplate);
			If Not IsBlankString(vErrorDescription) Then
				Raise vErrorDescription;
			EndIf;
			
			// Try to save guest passport data
			If ValueIsFilled(vResObj.Guest) And vGuestsRow <> Undefined And Not IsBlankString(vGuestsRow.PassportNumber) Then
				vGuestObj = vResObj.Guest.GetObject();
				vGuestObj.IdentityDocumentSeries = vGuestsRow.PassportSeries;
				vGuestObj.IdentityDocumentNumber = vGuestsRow.PassportNumber;
				vGuestObj.Write();
				vGuestObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
			
			// Save reservation number to join all room guests together
			If IsBlankString(vReservationNumber) Then
				vReservationNumber = vResObj.Number;
			EndIf;
			If ValueIsFilled(vResObj.AccommodationType) And vResObj.AccommodationType.Type = Enums.AccomodationTypes.Room Then
				vRoomReservation = vResObj.Ref;
				If ValueIsFilled(vOldReservationStatus) And vOldReservationStatus.IsActive And Not vOldReservationStatus.IsCheckIn And 
					Not ValueIsFilled(vResObj.RoomQuota) Then
					vAccommodationTypeRoomIsFound = True;
				EndIf;
			EndIf;
			
			// Try to update room rates
			If vRoomRates.Count() > 0 Then
				vResObj.RoomRates.Clear();
				For Each vRoomRatesRow In vRoomRates Do
					vDocRoomRatesRow = vResObj.RoomRates.Find(vRoomRatesRow.AccountingDate, "AccountingDate");
					If vDocRoomRatesRow = Undefined Then
						vDocRoomRatesRow = vResObj.RoomRates.Add();
						vDocRoomRatesRow.AccountingDate = vRoomRatesRow.AccountingDate;
					EndIf;
					vDocRoomRatesRow.RoomRate = vRoomRatesRow.RoomRate;
				EndDo;
				For Each vRoomRatesRow In vRoomRates Do
					vDocServiceRows = vResObj.Services.FindRows(New Structure("AccountingDate", vRoomRatesRow.AccountingDate));
					For Each vDocServiceRow In vDocServiceRows Do
					      If vDocServiceRow.PriceTag <> vRoomRatesRow.PriceTag Then
						     vDocServiceRow.PriceTag = vRoomRatesRow.PriceTag;
					      EndIf;
					EndDo; 
				EndDo;

				vResObj.RoomRates.Sort("AccountingDate");
				vResObj.pmCalculateServices();
				vResObj.Write(DocumentWriteMode.Posting);
			EndIf;
			vListOrder = Orders.cmGetOrdersByParentDoc(vResObj.Ref);
			vOrdersSum =  vListOrder.Total("Sum");
			vCurResAmount = vCurResAmount + vResObj.Services.Total("Sum") + vOrdersSum; 
		EndDo;
	EndDo;
	
	// Check if there are any unposted reservations left
	For Each vUnpostedReservationItem In vUnpostedReservations Do
		vUnpostedReservation = vUnpostedReservationItem.Value;
		If Not vUnpostedReservation.Posted Then
			// Cancel this reservation in the usual way
			vResObj = vUnpostedReservation.GetObject();
			vResObj.ReservationStatus = vAnnulationStatus;
			vResObj.Write(DocumentWriteMode.Posting);
			vResObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndDo;
	
	// Check customers and contracts per guest group. If more then one customer/contract then reset group flag
	If ValueIsFilled(vGuestGroup) Then
		vGroupCustomersAndContracts = GetGroupCustomersAndContracts(vGuestGroup);
		If vGroupCustomersAndContracts.Count() > 1 Then
			vGuestGroupObj = vGuestGroup.GetObject();
			vGuestGroupObj.OneCustomerPerGuestGroup = False;
			vGuestGroupObj.Write();
		EndIf;				
	EndIf;	
	
	vCurResAmount = Format(vCurResAmount, "NG=");
	vExternalResAmount = String(vExternalResAmount);
	If vExternalResAmount = vCurResAmount Then
		CommitTransaction();
	Else
		RollbackTransaction();
		vErrorDescription = "tma_RemotingBookingPrice_Error = 'Заказ невозможен. Цена предложения не соответствует цене в удалённой системе'" + Chars.LF 
							+ "Цена КСБ: " + vExternalResAmount + " Цена отеля: " + vCurResAmount;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoMakeReservation.BookingPrice_Error", Enums.ExternalSystemEventTypes.Error, , vErrorDescription, "RollbackTransaction");
		Raise vErrorDescription;
	EndIf;	
	
	// Return success
	If vInteraction.DebugMode Then
		vMessage =  NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DoModifyReservation", Enums.ExternalSystemEventTypes.Success, , , vMessage);
	EndIf;
	// Return status
	Return "mrrModified";
EndFunction // DoModifyReservation 

// -----------------------------------------------------------------------------
Function GetAnnulationStatus()
	vAnnulationStatus = Catalogs.ReservationStatuses.EmptyRef();
	// Try to find canceled reservation status
	vStatuses = cmGetAllReservationStatuses(True);
	For Each vStatusesRow In vStatuses Do
		vStatusRef = vStatusesRow.ReservationStatus;
		If Not vStatusRef.IsActive And 
		   Not vStatusRef.IsCheckIn And 
		   Not vStatusRef.IsInWaitingList And 
		   Not vStatusRef.IsNoShow And 
		   Not vStatusRef.DoNotCreateReservationsInBlock And 
		   Not vStatusRef.IsPreliminary Then
			vAnnulationStatus = vStatusRef;
			Break;
		EndIf;
	EndDo;
	If Not ValueIsFilled(vAnnulationStatus) Then
		Raise NStr("en='There is no reservation annulation status defined in system!';ru='В справочнике статусов брони не найден статус аннуляции брони!';de='Im Verzeichnis der Reservierungsstatus wurde kein Reservierungsstorno-Status gefunden!'");
	EndIf;
	Return vAnnulationStatus;
EndFunction // GetAnnulationStatus

// -----------------------------------------------------------------------------
Function DoCancelReservation(pInteraction, vReservationItem)
	If pInteraction.DebugMode Then
		vMessage = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteraction, "DoCancelReservation", Enums.ExternalSystemEventTypes.Info, , , vMessage);
	EndIf;

	vResAttrs = vReservationItem.Attributes;
	vExtOrderNumber = vResAttrs.GetNamedItem("OrderNumber").Value;
	vExtRoomOrderNumber = "";
	vExtGroupNumber = GetExtGroupNumber(vExtOrderNumber, vExtRoomOrderNumber);
	vGroupNumber = "";
	vSupplierOrderNumber = "";
	Try
		vSupplierOrderNumber = vResAttrs.GetNamedItem("SupplierOrderNumber").Value;
	Except
	EndTry;
	If Not IsBlankString(vSupplierOrderNumber) Then
		Try
			vGroupNumber = GetGuestGroupCode(vSupplierOrderNumber);
		Except
		EndTry;
	EndIf;
	
	// Try to find reference to existing guest group
	vAnnulationStatus = Undefined;
	If Not IsBlankString(vGroupNumber) Then
		vGuestGroup = Catalogs.GuestGroups.FindByCode(Number(vGroupNumber), False, , pInteraction.Hotel);
	Else
		vGuestGroup = cmGetGuestGroupByExternalCode(pInteraction.Hotel, vExtGroupNumber, "", "", False);
	EndIf;
	If Not ValueIsFilled(vGuestGroup) Then
		Return "crrAbsent";
	Else
		// Try to find canceled reservation status
		vAnnulationStatus = cmGetReservationAnnulationStatus(vGuestGroup.ClientDoc);
	EndIf;
	
	// Change status for each reservation in guest group
	vGuestGroupObj = vGuestGroup.GetObject();
	vReservations = vGuestGroupObj.pmGetReservations(True, True);
	If vReservations.Count() = 0 Then
		Return "crrAvoided";
	EndIf;
	
	// Get list of all guests in the reservation
	vGuests = New ValueTable();
	vGuests.Columns.Add("ID", cmGetStringTypeDescription());
	
	vTouristItems = vReservationItem.GetElementByTagName("Tourist");
	If vTouristItems.Count() > 0 Then
		For i = 0 To (vTouristItems.Count() - 1) Do
			vTouristItem = vTouristItems.Item(i);
			vTouristAttrs = vTouristItem.Attributes;
			
			vGuestsRow = vGuests.Add();
			vGuestsRow.ID = vTouristAttrs.GetNamedItem("TouristID").Value;
		EndDo;
	EndIf;
	
	// Get list of all rooms in the reservation
	vRoomItems = vReservationItem.GetElementByTagName("Room");
	If vRoomItems.Count() = 0 Then
		vMessage =  NStr("en='<Room> element is missing in the XML data!'; de='<Room> element is missing in the XML data!'; ru='В XML данных не найден элемент <Room>!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteraction, "DoCancelReservation", Enums.ExternalSystemEventTypes.Error, , , vMessage);
		Raise vMessage;
	EndIf;
	For i = 0 To (vRoomItems.Count() - 1) Do
		vRoomItem = vRoomItems.Item(i);
		vRoomAttrs = vRoomItem.Attributes;
		vRoomIsCanceled = True;
		vAccommodationTypeRoomIsFound = False;
		// Get places for the given room
		vPlaceItems = vRoomItem.GetElementByTagName("Place");
		If vPlaceItems.Count() = 0 Then
			vMessage =  NStr("en='<Place> element is missing in the XML data!'; de='<Place> element is missing in the XML data!'; ru='В XML данных не найден элемент <Place>!'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteraction, "DoCancelReservation", Enums.ExternalSystemEventTypes.Error, , , vMessage);
			Raise vMessage;
		EndIf;
		vReservation = Undefined;
		For j = 0 To (vPlaceItems.Count() - 1) Do
			vPlaceItem = vPlaceItems.Item(j);
			vPlaceAttrs = vPlaceItem.Attributes;
			
			// Read guest ID and try to match it with guest data
			vGuestsRow = Undefined;
			vGuestID = "";
			Try
				vGuestID = vPlaceAttrs.GetNamedItem("TouristID").Value;
			Except
			EndTry;
			If Not IsBlankString(vGuestID) Then
				vGuestsRow = vGuests.Find(vGuestID, "ID");
			EndIf;
			vGuestIndex = Format((i*1000 + j), "ND=6; NFD=0; NZ=; NLZ=; NG=");
			
			// Build reservation unique code
			vExtReservationCode = vExtOrderNumber + "/" + vGuestIndex;
			
			// Try to find reservation by external code
			vReservation = cmGetReservationByExternalCode(pInteraction.Hotel, vExtReservationCode);
			If ValueIsFilled(vReservation) Then
				// Cancel reservation
				If vRoomIsCanceled Then
					If pInteraction.DebugMode Then
						vMessage = 
								"ExtOrderNumber/GuestIndex: " + vExtOrderNumber + "/" + vGuestIndex + 
								", ExtGroupNumber: " + vExtGroupNumber + 
								", ReservationStatusCode: " + TrimAll(vReservation.ReservationStatus) + 
								", CheckInDate: " + vReservation.CheckInDate + 
								", CheckOutDate: " + vReservation.CheckOutDate + 
								", HotelCode: " + TrimR(pInteraction.Hotel.Code) + 
								", RoomType: " + TrimAll(vReservation.RoomType) + 
								", AccommodationTypeCode: " + TrimAll(vReservation.AccommodationType) + 
								", AllotmentCode: " + TrimAll(vReservation.RoomQuota) + 
								", RoomRateCode: " + TrimAll(vReservation.RoomRate) + 
								", GroupCustomerName: " + TrimAll(vReservation.Customer) + 
								", Guest: " + TrimAll(vReservation.GuestFullName);
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteraction, "DoCancelReservation", Enums.ExternalSystemEventTypes.Info, , , vMessage);
					EndIf;
					If ValueIsFilled(vReservation.AccommodationType) And vReservation.AccommodationType.Type = Enums.AccomodationTypes.Room And 
						ValueIsFilled(vReservation.ReservationStatus) And vReservation.ReservationStatus.IsActive And Not vReservation.ReservationStatus.IsCheckIn And 
						Not ValueIsFilled(vReservation.RoomQuota) Then
						vAccommodationTypeRoomIsFound = True;
					EndIf;     
					// Check reservation check-in date. If it is in the past then do nothing
					If BegOfDay(vReservation.CheckInDate) < BegOfDay(CurrentSessionDate()) Then
						vRetMsg = NStr("en='Check-in date is in the past! External call is skipped.'; de='Check-in date is in the past! External call is skipped.'; ru='Дата заезда в прошлом! Внешний вызов игнорируется.'");
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteraction, "DoCancelReservation", Enums.ExternalSystemEventTypes.Error, , , vRetMsg);
						Raise vRetMsg;
					EndIf;
					If vReservation.ReservationStatus = vAnnulationStatus Then
						Continue;
					EndIf;	
					If ValueIsFilled(vReservation.ReservationStatus) And Not vReservation.ReservationStatus.IsCheckIn 
						And (BegOfDay(vReservation.CheckInDate) > BegOfDay(CurrentSessionDate()) Or BegOfDay(vReservation.CheckInDate) = BegOfDay(CurrentSessionDate()) And CurrentSessionDate() < BegOfDay(CurrentSessionDate()) + 3600 * 12 ) Then
						
						vReservationObj = vReservation.GetObject();
						vReservationObj.ReservationStatus = vAnnulationStatus;
						vReservationObj.pmSetDoCharging();
						vReservationObj.Write(DocumentWriteMode.Posting);
						vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					Else
						If pInteraction.DebugMode Then
							vMessage = "Skipping status update: current status is " + TrimAll(vReservation.ReservationStatus);
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteraction, "DoCancelReservation", Enums.ExternalSystemEventTypes.Warning, , , vMessage);
						EndIf;       
						Return "crrAvoided";
					EndIf;
				EndIf;
			Else
				Return "crrAvoided";
			EndIf;
		EndDo;
	EndDo;
	If pInteraction.DebugMode Then
		vMessage =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteraction, "DoCancelReservation", Enums.ExternalSystemEventTypes.Warning, , , vMessage);
	EndIf;

	Return "crrCanceled";
EndFunction // DoCancelReservation

// -----------------------------------------------------------------------------
Function GetReservationResult(pCreateReservationResult)
	If pCreateReservationResult = "rrReserved" Then
		Return "RESERVED";
	ElsIf pCreateReservationResult = "rrReservedNeedConfirmation" Then
		Return "RESERVED_NEED_CONFIRMATION";
	ElsIf pCreateReservationResult = "rrOrderedByRequest" Then
		Return "ORDERED_BY_REQUEST";
	ElsIf pCreateReservationResult = "rrInvalidTouristAge" Then
		Return "FAILED";
	ElsIf pCreateReservationResult = "rrInsufficientResources" Then
		Return "INSUFFICIENT_RESOURCES";
	ElsIf pCreateReservationResult = "rrFailed" Then
		Return "FAILED";
	Else
		Return "FAILED";
	EndIf;
EndFunction // GetReservationResult

// -----------------------------------------------------------------------------
Function GetModifyReservationResult(pModifyReservationResult)
	If pModifyReservationResult = "mrrModified" Then
		Return "MODIFIED";
	ElsIf pModifyReservationResult = "mrrAbsent" Then
		Return "ABSENT";
	ElsIf pModifyReservationResult = "mrrAvoided" Then
		Return "AVOIDED";
	ElsIf pModifyReservationResult = "mrrFailed" Then
		Return "FAILED";
	Else
		Return "FAILED";
	EndIf;
EndFunction // GetModifyReservationResult

// -----------------------------------------------------------------------------
Function GetCancelReservationResult(pCancelReservationResult)
	If pCancelReservationResult = "crrCanceled" Then
		Return "CANCELED";
	ElsIf pCancelReservationResult = "crrAbsent" Then
		Return "ABSENT";
	ElsIf pCancelReservationResult = "crrAvoided" Then
		Return "AVOIDED";
	ElsIf pCancelReservationResult = "crrFailed" Then
		Return "FAILED";
	Else
		Return "FAILED";
	EndIf;
EndFunction // GetCancelReservationResult

// -----------------------------------------------------------------------------
Function GetClientsByPromoCodeAndMemberID(pPromoCode, pMemberID)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DiscountTypes.Ref AS DiscountType
	|INTO DiscountTypes
	|FROM
	|	Catalog.DiscountTypes AS DiscountTypes
	|WHERE
	|	NOT DiscountTypes.IsFolder
	|	AND NOT DiscountTypes.DeletionMark
	|	AND DiscountTypes.DateValidFrom <= &qCurrentDate
	|	AND (DiscountTypes.DateValidTo > &qCurrentDate
	|			OR DiscountTypes.DateValidTo = &qEmptyDate)
	|	AND (DiscountTypes.Description = &qPromoCode
	|			OR DiscountTypes.Code = &qPromoCode)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscountCards.Client AS Client
	|INTO DiscountCards
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	NOT DiscountCards.DeletionMark
	|	AND NOT DiscountCards.IsBlocked
	|	AND DiscountCards.ValidFrom <= &qCurrentDate
	|	AND (DiscountCards.ValidTo > &qCurrentDate
	|			OR DiscountCards.ValidTo = &qEmptyDate)
	|	AND DiscountCards.Identifier = &qPromoCode
	|	AND DiscountCards.Client.Phone = &qMemberID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ClientsWithDiscountTypes.Ref AS Client
	|INTO ClientsWithDiscountTypes
	|FROM
	|	Catalog.Clients AS ClientsWithDiscountTypes
	|WHERE
	|	NOT ClientsWithDiscountTypes.IsFolder
	|	AND NOT ClientsWithDiscountTypes.DeletionMark
	|	AND ClientsWithDiscountTypes.Phone = &qMemberID
	|	AND (ClientsWithDiscountTypes.DiscountType IN
	|				(SELECT
	|					DiscountTypes.DiscountType
	|				FROM
	|					DiscountTypes AS DiscountTypes)
	|			OR ClientsWithDiscountTypes.ClientType.DiscountType IN
	|				(SELECT
	|					DiscountTypes.DiscountType
	|				FROM
	|					DiscountTypes AS DiscountTypes))
	|
	|GROUP BY
	|	ClientsWithDiscountTypes.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscountCardsByDiscountTypes.Client AS Client
	|INTO ClientsWithDiscountCards
	|FROM
	|	Catalog.DiscountCards AS DiscountCardsByDiscountTypes
	|WHERE
	|	NOT DiscountCardsByDiscountTypes.DeletionMark
	|	AND DiscountCardsByDiscountTypes.Client.Phone = &qMemberID
	|	AND NOT DiscountCardsByDiscountTypes.IsBlocked
	|	AND DiscountCardsByDiscountTypes.ValidFrom <= &qCurrentDate
	|	AND (DiscountCardsByDiscountTypes.ValidTo > &qCurrentDate
	|			OR DiscountCardsByDiscountTypes.ValidTo = &qEmptyDate)
	|	AND DiscountCardsByDiscountTypes.DiscountType IN
	|			(SELECT
	|				DiscountTypes.DiscountType
	|			FROM
	|				DiscountTypes AS DiscountTypes)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ClientsList.Client
	|FROM
	|	(SELECT
	|		ClientsWithDiscountTypes.Client AS Client
	|	FROM
	|		ClientsWithDiscountTypes AS ClientsWithDiscountTypes
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ClientsWithDiscountCards.Client
	|	FROM
	|		ClientsWithDiscountCards AS ClientsWithDiscountCards
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DiscountCards.Client
	|	FROM
	|		DiscountCards AS DiscountCards) AS ClientsList
	|
	|ORDER BY
	|	ClientsList.Client.FullName,
	|	ClientsList.Client.Code";
	vQry.SetParameter("qPromoCode", pPromoCode);
	vQry.SetParameter("qMemberID", pMemberID);
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vQry.SetParameter("qEmptyDate", '00010101');
	vClients = vQry.Execute().Unload();
	Return vClients;
EndFunction // GetClientsByPromoCodeAndMemberID

// -----------------------------------------------------------------------------
Function GenerateVerificationCode()
	vRnd = New RandomNumberGenerator(CurrentSessionDate() - '20000101');
	Return Format(vRnd.RandomNumber(10000, 99999), "ND=5; NFD=; NLZ=; NG=");
EndFunction // GenerateVerificationCode

// -----------------------------------------------------------------------------
Function GetVerificationRecordByPhoneAndCode(pPromoCode, pPromoPhone, pPromoVerificationCode)
	vRcdMgr = InformationRegisters.ClientVerificationCodes.CreateRecordManager();
	vRcdMgr.PromoCode = pPromoCode;
	vRcdMgr.Phone = SMS.GetValidPhoneNumber(pPromoPhone);
	vRcdMgr.Read();
	If vRcdMgr.Selected() Then
		If TrimAll(vRcdMgr.VerificationCode) = TrimAll(pPromoVerificationCode) Then
			Return vRcdMgr;
		Else
			Return Undefined;
		EndIf;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetVerificationRecordByPhoneAndCode

// -----------------------------------------------------------------------------
Function GetDiscountTypeByPromoCode(pPromoCode)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DiscountTypes.Ref AS DiscountType
	|FROM
	|	Catalog.DiscountTypes AS DiscountTypes
	|WHERE
	|	NOT DiscountTypes.IsFolder
	|	AND NOT DiscountTypes.DeletionMark
	|	AND DiscountTypes.DateValidFrom <= &qCurrentDate
	|	AND (DiscountTypes.DateValidTo > &qCurrentDate
	|			OR DiscountTypes.DateValidTo = &qEmptyDate)
	|	AND (DiscountTypes.Description = &qPromoCode
	|			OR DiscountTypes.Code = &qPromoCode)
	|
	|ORDER BY
	|	DiscountTypes.SortCode,
	|	DiscountTypes.Code DESC";
	vQry.SetParameter("qPromoCode", pPromoCode);
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vQry.SetParameter("qEmptyDate", '00010101');
	vDTs = vQry.Execute().Unload();
	For Each vDTsRow In vDTs Do
		Return vDTsRow.DiscountType;
	EndDo;
	Return Undefined;
EndFunction // GetDiscountTypeByPromoCode

// -----------------------------------------------------------------------------
Function GetDiscountCardByPromoCode(pPromoCode, pPhone)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref AS DiscountCard
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	NOT DiscountCards.DeletionMark
	|	AND NOT DiscountCards.IsBlocked
	|	AND DiscountCards.ValidFrom <= &qCurrentDate
	|	AND (DiscountCards.ValidTo > &qCurrentDate
	|			OR DiscountCards.ValidTo = &qEmptyDate)
	|	AND DiscountCards.Identifier = &qPromoCode
	|	AND DiscountCards.Client.Phone = &qPhone
	|
	|ORDER BY
	|	DiscountCards.Code DESC";
	vQry.SetParameter("qPromoCode", pPromoCode);
	vQry.SetParameter("qPhone", pPhone);
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vQry.SetParameter("qEmptyDate", '00010101');
	vDCs = vQry.Execute().Unload();
	For Each vDCsRow In vDCs Do
		Return vDCsRow.DiscountCard;
	EndDo;
	Return Undefined;
EndFunction // GetDiscountCardByPromoCode

// -----------------------------------------------------------------------------
Procedure ClearExcludedAccommadationTypes(Val pCurMappingTable)
	For Each vCurRow In pCurMappingTable Do
		vRmg = InformationRegisters.ExternalSystemIntegrationData.CreateRecordManager();
		FillPropertyValues(vRmg, vCurRow, ,"DataValue");
		vRmg.DataValue = False;
		vRmg.Write(True);
	EndDo;
EndProcedure // ClearExcludedAccommadationTypes

// -----------------------------------------------------------------------------
Function GetTouristTypeCID(Val pHotel, Val pCurrAccommodationType, pInteractionID)
	
	vTouristTypeCID = "";
	vTouristTypeName = cmGetObjectExternalSystemCodeByRef(pHotel, TrimR(pInteractionID), "AccommodationTypes", pCurrAccommodationType, True);
	vSlashPos = Find(vTouristTypeName, "/");
	If vSlashPos > 1 Then
		vTouristTypeCID = Mid(vTouristTypeName, vSlashPos + 1);
	EndIf;
	Return vTouristTypeCID;
	
EndFunction // GetTouristTypeCID

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
EndFunction // GetExtAccommodationTemplates 

#EndRegion