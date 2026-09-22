#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vObj = FormAttributeToValue("Object");

	// Interaction parameters	
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		vObj.InteractionParameters = vInteractionParameters;
		If ValueIsFilled(vInteractionParameters) And ValueIsFilled(vInteractionParameters.Hotel) Then
			vObj.Hotel = vInteractionParameters.Hotel;
		EndIf;
	EndIf;
	vHotel = vObj.Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	
	vDataProcessor = Undefined;
	If Parameters.Property("DataProcessor") And ValueIsFilled(Parameters.DataProcessor) Then
		vDataProcessor = Parameters.DataProcessor;
	ElsIf ValueIsFilled(vInteractionParameters) And ValueIsFilled(vInteractionParameters.DataProcessor) Then
		vDataProcessor = vInteractionParameters.DataProcessor;
	EndIf;
	If ValueIsFilled(vDataProcessor) Then
		vObj.DataProcessor = vDataProcessor;
		// Load other data processor attributes 
		vObj.pmLoadDataProcessorAttributes();
		If ValueIsFilled(vObj.Hotel) Then
			vHotel = vObj.Hotel;
		EndIf;
		If ValueIsFilled(vObj.InteractionParameters) Then
			vInteractionParameters = vObj.InteractionParameters;
			If ValueIsFilled(vInteractionParameters.Hotel) Then
				vHotel = vInteractionParameters.Hotel;
				vObj.Hotel = vHotel;
			EndIf;
		EndIf;
	EndIf;
	
	If ValueIsFilled(vInteractionParameters) Then
		vChangesSyncDPKey = "OTAGateway_ChangesSync_" + TrimAll(vInteractionParameters.Code);
		vChangesSyncDPDescription = NStr("en='OTAGateway:CM changes synchronization and reservations import';
		                                 |ru='OTAGateway:CM синхронизация изменений и загрузка брони';
		                                 |de='OTAGateway:CM änderungen synchronisieren und Reservierungen laden'") + 
		                            " (" + TrimAll(vHotel) + ")";
		vFullSyncDPKey = "OTAGateway_FullSync_" + TrimAll(vInteractionParameters.Code);
		vFullSyncDPDescription = NStr("en='OTAGateway:CM full synchronization';
		                              |ru='OTAGateway:CM полная синхронизация';
		                              |de='OTAGateway:CM vollständige Synchronisation'") + 
		                         " (" + TrimAll(vHotel) + ")";
	
		// Fill form attributes
		If ValueIsFilled(vDataProcessor) Then
			If TrimAll(vDataProcessor.Key) = vFullSyncDPKey Then
				DataProcessorFullSync = vDataProcessor;
			Else
				DataProcessorChangesSync = vDataProcessor;
			EndIf;
		EndIf;
		If Not ValueIsFilled(DataProcessorChangesSync) Then
			// Try to find data processor for changes sync by key
			vDataProcessor = cmGetDataProcessorByKey(vChangesSyncDPKey);
			If Not ValueIsFilled(vDataProcessor) Then
				vNewDP = Catalogs.DataProcessors.CreateItem();
				vNewDP.Processing = "TLConnectWizard";
				vNewDP.Description = vChangesSyncDPDescription;
				vNewDP.Key = vChangesSyncDPKey;
				vNewDP.Hotel = vHotel;
				vNewDP.IsSystem = True;
				vNewDP.Write();
				
				vDataProcessor = vNewDP.Ref;
			Else
				// Update DP description if it is old one
				If TrimAll(vDataProcessor.Description) <> vChangesSyncDPDescription Then
					vObjDP = vDataProcessor.GetObject();
					vObjDP.Description = vChangesSyncDPDescription;
					vObjDP.Key = vChangesSyncDPKey;
					vObjDP.Hotel = vHotel;
					vObjDP.IsSystem = True;
					vObjDP.Write();
				EndIf;
			EndIf;
			DataProcessorChangesSync = vDataProcessor;
			
			// By default changes sync DP is used
			vObj.DataProcessor = DataProcessorChangesSync;
		Else
			// Update DP description and key
			If TrimAll(DataProcessorChangesSync.Description) <> vChangesSyncDPDescription Or 
			   TrimAll(DataProcessorChangesSync.Key) <> vChangesSyncDPKey Then
				vObjDP = DataProcessorChangesSync.GetObject();
				vObjDP.Description = vChangesSyncDPDescription;
				vObjDP.Key = vChangesSyncDPKey;
				vObjDP.Hotel = vHotel;
				vObjDP.IsSystem = True;
				vObjDP.Write();
			EndIf;
		EndIf;
		If Not ValueIsFilled(DataProcessorFullSync) Then
			// Try to find data processor for changes sync by key
			vDataProcessor = cmGetDataProcessorByKey(vFullSyncDPKey);
			If Not ValueIsFilled(vDataProcessor) Then
				vNewDP = Catalogs.DataProcessors.CreateItem();
				vNewDP.Processing = "OTAGatewayWizard";
				vNewDP.Description = vFullSyncDPDescription;
				vNewDP.Key = vFullSyncDPKey;
				vNewDP.Hotel = vHotel;
				vNewDP.IsSystem = True;
				vNewDP.Write();
				
				vDataProcessor = vNewDP.Ref;
			Else
				// Update DP description if it is old one
				If TrimAll(vDataProcessor.Description) <> vFullSyncDPDescription Then
					vObjDP = vDataProcessor.GetObject();
					vObjDP.Description = vFullSyncDPDescription;
					vObjDP.Key = vFullSyncDPKey;
					vObjDP.Hotel = vHotel;
					vObjDP.IsSystem = True;
					vObjDP.Write();
				EndIf;
			EndIf;
			DataProcessorFullSync = vDataProcessor;
		Else
			// Update DP description and key
			If TrimAll(DataProcessorFullSync.Description) <> vFullSyncDPDescription Or 
			   TrimAll(DataProcessorFullSync.Key) <> vFullSyncDPKey Then
				vObjDP = DataProcessorFullSync.GetObject();
				vObjDP.Description = vFullSyncDPDescription;
				vObjDP.Key = vFullSyncDPKey;
				vObjDP.Hotel = vHotel;
				vObjDP.IsSystem = True;
				vObjDP.Write();
			EndIf;
		EndIf;
	EndIf;

	// Restore form object
	ValueToFormAttribute(vObj, "Object");

	If Object.AmountOfDaysToUpdate <= 0 Then
		Object.AmountOfDaysToUpdate = 100;	
	EndIf;
	
	LoadInteractionParameters();
	LoadRoomTypesTable();
	LoadRoomRatesTable();
	LoadReservationStatuses();	
	LoadAgents();
	LoadAgentsData();
	LoadHotelData();
	
	Items.AgentsRoomRates.RowFilter = New FixedStructure("Agent", Undefined);
	Items.AgentsRoomTypes.RowFilter = New FixedStructure("Agent", Undefined);
	
	FillHotelPhonesChoiceList();
	
	If Not ValueIsFilled(DefaultCheckInTime) Or Not ValueIsFilled(DefaultCheckOutTime) Then
		SetDefaultCheckTimes();	
	EndIf;
	
	If Not ValueIsFilled(HTTPServer) Then
		HTTPServer 	= "api.reservationsteps.ru";
		HTTPAddress = "/v1/api/";
		HTTPUseSSL	= True;
	EndIf;

	If IsInRoleAtServer("Administrator") Then
		If ValueIsFilled(DataProcessorChangesSync) Then
			SetupBackgroundJobChangesSyncSchedule_AtServer(True);
		Else
			ScheduleChangesSync = New JobSchedule;
		EndIf;
		
		If ValueIsFilled(DataProcessorFullSync) Then
			SetupBackgroundJobFullSyncSchedule_AtServer(True);
		Else
			ScheduleFullSync = New JobSchedule;
		EndIf;
	Else
		Items.MainPages_BackgroundJob.Visible = False;
        Items.SettingsPages_MainInfo.ReadOnly = True;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(Items.Group_MainPages.CurrentPage);
	
	FillToolTipSyncData();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillToolTipSyncData()
	If Object.AmountOfDaysToUpdate > 0 Then
		vCurDate = CurrentDate();
		vLastDayOfUnloading = vCurDate + (Object.AmountOfDaysToUpdate * 86400);  
		Items.ToolTipSyncData.Title = StrTemplate(NStr("en = 'Unload for %1 days (from %2 to %3)'; de = 'Entladen für %1 Tage (von %2 bis %3)'; ru = 'Выгрузка на %1 дней  (с %2 по %3)'"), Object.AmountOfDaysToUpdate, Format(vCurDate, "DF=dd.MM.yyyy"), Format(vLastDayOfUnloading, "DF=dd.MM.yyyy"));
	Else
		Items.ToolTipSyncData.Title = NStr("en = 'Data is synchronized from the current date for N days specified in the settings tab.'; de = 'Data is synchronized from the current date for N days specified in the settings tab.'; ru = 'Данные выгружаются с текущей даты на N дней, указанных на вкладке настроек.'");	
	EndIf;		
EndProcedure // FillToolTipSyncData

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	
	vRoomTypesCheck = New Array;
	vRoomTypesCheck.Add("RoomType");
	vRoomTypesCheck.Add("AccommodationTemplate");
	vRoomTypesCheck.Add("Name");
	vRoomTypesCheck.Add("DefaultPrice");
	
	vRoomRatesCheck = New Array;
	vRoomRatesCheck.Add("RoomRate");
	vRoomRatesCheck.Add("Name");
	
	// Room types
	i = 1;
	vRoomTypes = RoomTypes.GetItems();
	For Each vRoomType In vRoomTypes Do
		For Each vCheck In vRoomTypesCheck Do
			If Not ValueIsFilled(vRoomType[vCheck]) Then			
				pCancel = True;
				vFieldTitle	 		= Items.Find("RoomTypes" + vCheck).Title; 
				vUserMsg 			= New UserMessage;
				vUserMsg.Text 		= tcCommonFunctions.cmSetTextParameters(NStr("ru = 'В строке &1 категорий номеров незаполнено поле &2 !'"), i, vFieldTitle); 
				vUserMsg.DataPath 	= "RoomTypes";
				vUserMsg.Message();
				Return;
			EndIf;
		EndDo;
		
		j = 1;
		vVirtualRoomTypes = vRoomType.GetItems();
		For Each vVirtualRoomType In vVirtualRoomTypes Do
			For Each vCheck In vRoomTypesCheck Do
				If Not ValueIsFilled(vVirtualRoomType[vCheck]) Then
					pCancel = True;
					vFieldTitle	 		= Items.Find("RoomTypes" + vCheck).Title; 
					vUserMsg 			= New UserMessage;
					vUserMsg.Text 		= tcCommonFunctions.cmSetTextParameters(NStr("ru = 'В строке &1 категорий номеров незаполнено поле &2 !'"), String(i) + "." + j, vFieldTitle); 
					vUserMsg.DataPath 	= "RoomTypes";
					vUserMsg.Message();
					Return;
				EndIf;
			EndDo;
			j = j + 1;
		EndDo;
		
		i = i + 1;
	EndDo;
	
	// Room rates
	i = 1;	
	For Each vRoomType In RoomRates Do
		For Each vCheck In vRoomRatesCheck Do
			If Not ValueIsFilled(vRoomType[vCheck]) Then			
				pCancel = True;
				vFieldTitle	 		= Items.Find("RoomRates" + vCheck).Title; 
				vUserMsg 			= New UserMessage;
				vUserMsg.Text 		= tcCommonFunctions.cmSetTextParameters(NStr("ru = 'В строке &1 тарифов незаполнено поле &2 !'"), i, vFieldTitle); 
				vUserMsg.DataPath 	= "RoomRates";
				vUserMsg.Message();
				Return;
			EndIf;
		EndDo;		
		i = i + 1;
	EndDo;

	// Agents
	For Each vAgent In Agents Do
		If ValueIsFilled(vAgent.Agent) Then
			vFoundRows = Agents.FindRows(New Structure("Agent", vAgent.Agent));
			If vFoundRows.Count() > 1 Then
				vUserMsg 			= New UserMessage;
				vUserMsg.Text 		= NStr("ru = 'Нельзя указывать одного контрагента в качестве нескольких агентов!'"); 
				vUserMsg.DataPath 	= "Agents";
				vUserMsg.Message();
				Return;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure AmountOfDaysToUpdateOnChange(pItem)
	FillToolTipSyncData();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	
	If Debug Then
		Active = True;
	EndIf;
		
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	
	If Not Active Then
		Debug = False;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesOnEditEnd(pItem, pNewRow, pCancelEdit)
	
	If Not pNewRow And Not pCancelEdit And Items.RoomTypes.CurrentData <> Undefined Then
		vTreeRow 			= RoomTypes.FindByID(Items.RoomTypes.CurrentData.GetID());
	    vTreeRow.isModified = True;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesOnEditEnd(pItem, pNewRow, pCancelEdit)
	
	If Not pNewRow And Not pCancelEdit And Items.RoomRates.CurrentData <> Undefined Then
		vRow 			= RoomRates.FindByID(Items.RoomRates.CurrentData.GetID());
	    vRow.isModified = True;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Group_MainPagesOnCurrentPageChange(pItem, pCurrentPage)
	
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(pCurrentPage);
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Settings_SettingsPagesOnCurrentPageChange(pItem, pCurrentPage)
	
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(pCurrentPage);
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesBeforeDeleteRow(pItem, pCancel)
	
	If Items.RoomRates.CurrentData <> Undefined Then
		vRowID 	= Items.RoomRates.CurrentData.GetID();
		vRow 	= RoomRates.FindByID(vRowID);
		
		// Add to deletetion table so we can send delete request to external system
		If ValueIsFilled(vRow.ID) Then
			vNewDeletionRow 			= DataDeletionTable.Add();
			vNewDeletionRow.DataType 	= "roomrates";
			vNewDeletionRow.DataID 		= vRow.ID;
		EndIf;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentOnChange(pItem)
	
	FilterAgentsData();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesRoomTypeOnChange(pItem)
	
	If Items.RoomTypes.CurrentData <> Undefined Then
		vTreeRow 			= RoomTypes.FindByID(Items.RoomTypes.CurrentData.GetID());
	    vTreeRow.isModified = True;
		
		vTreeRowChilds = vTreeRow.GetItems();
		For Each vTreeRowChild In vTreeRowChilds Do
			vTreeRowChild.RoomType 		= vTreeRow.RoomType;
			vTreeRowChild.isModified 	= True;
		EndDo;
		
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	
	SetDefaultCheckTimes();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadReservationsFromFileStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisForm));
EndProcedure // LoadReservationsFromFileStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure LastExportTimestampForInventoryOnChange(Item)
	LastExportTimestampForInventoryWasChanged = True;
EndProcedure // LastExportTimestampForInventoryOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure LastExportTimestampForPricesOnChange(Item)
	LastExportTimestampForPricesWasChanged = True;
EndProcedure // LastExportTimestampForPricesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure LastExportTimestampForRestrictionsOnChange(Item)
	LastExportTimestampForRestrictionsWasChanged = True;
EndProcedure // LastExportTimestampForRestrictionsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure UseBackgroundJobChangesSyncOnChange(pItem)
	If ValueIsFilled(EmployeeChangesSync) Then
		If ScheduleChangesSync <> Undefined Then
			If UseBackgroundJobChangesSync Then
				If Not IsInRoleAtServer("Administrator") Then
					Raise(NStr("en='A background job should be configured by administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
				EndIf;
				Items.Text_BackgroundJobInfo_ChangesSync.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
			Else 
				Items.Text_BackgroundJobInfo_ChangesSync.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
			EndIf;
			If Not ScheduleChangesSync = Undefined Then
				Save_AtServer();
				SetupBackgroundJobChangesSyncSchedule_AtServer();
			EndIf;
		Else
			UseBackgroundJobChangesSync = False;
			Raise(NStr("en='Schedule is not setup!';ru='Не настроено расписание!';de='Kein Zeitplan konfiguriert!'"));
		EndIf;
	Else 
		UseBackgroundJobChangesSync = False;
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure // UseBackgroundJobChangesSyncOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure UseBackgroundJobFullSyncOnChange(pItem)
	If ValueIsFilled(EmployeeFullSync) Then
		If ScheduleFullSync <> Undefined Then
			If UseBackgroundJobFullSync Then
				If Not IsInRoleAtServer("Administrator") Then
					Raise(NStr("en='A background job should be configured by administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
				EndIf;
				Items.Text_BackgroundJobInfo_FullSync.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
			Else 
				Items.Text_BackgroundJobInfo_FullSync.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
			EndIf;
			If Not ScheduleFullSync = Undefined Then
				Save_AtServer();
				SetupBackgroundJobFullSyncSchedule_AtServer();
			EndIf;
		Else
			UseBackgroundJobFullSync = False;
			Raise(NStr("en='Schedule is not setup!';ru='Не настроено расписание!';de='Kein Zeitplan konfiguriert!'"));
		EndIf;
	Else 
		UseBackgroundJobFullSync = False;
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure // UseBackgroundJobFullSyncOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadRoomRatesFromGateway(pCommand)
	
	LoadRoomRatesFromOTA();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadRoomTypesFromGateway(pCommand)
	
	LoadRoomTypesFromOTA();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ConnectionTest(pCommand)
	
	If Save_AtServer() Then
		ConnectionTest_AtServer();
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	
	Save_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypes_Add(pCommand)
	
	vNewRow 		= RoomTypes.GetItems().Add();	
	vNewRow.UUID 	= String(New UUID);	
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypes_AddVirtual(pCommand)
	
	If Items.RoomTypes.CurrentData <> Undefined And Items.RoomTypes.CurrentData.GetParent() = Undefined Then
		If Not ValueIsFilled(Items.RoomTypes.CurrentData.RoomType) Then
			vUserMsg 		= New UserMessage;
			vUserMsg.Text 	= NStr("en = 'Fill the room type!'; de = 'Füllen Sie die Zimmertyp aus!'; ru = 'Заполните категорию номера!'");
			vUserMsg.Field	= "RoomTypes";
			vUserMsg.Message();	
			Return;
		EndIf;
		vRowParent		= RoomTypes.FindByID(Items.RoomTypes.CurrentData.GetID());
		If vRowParent <> Undefined Then
			vParentItems 		= vRowParent.GetItems();
			vNewRow				= vParentItems.Add();
			vNewRow.RoomType 	= vRowParent.RoomType;
			vNewRow.UUID		= String(New UUID);
			vNewRow.Virtual 	= True;
		EndIf;
	Else
		vUserMsg 		= New UserMessage;
		vUserMsg.Text 	= NStr("en = 'Select a row with a real category!'; de = 'Wählen Sie eine Linie mit einer realen Kategorie!'; ru = 'Выберите строку с реальной категорией!'");
		vUserMsg.Field	= "RoomTypes";
		vUserMsg.Message();	
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypes_Delete(pCommand)
	
	If Items.RoomTypes.CurrentData <> Undefined Then
		vRowID 	= Items.RoomTypes.CurrentData.GetID();
		vRow 	= RoomTypes.FindByID(vRowID);
		vParent = vRow.GetParent();
		
		// Add to deletetion table so we can send delete request to external system
		If ValueIsFilled(vRow.ID) Then
			vNewDeletionRow 			= DataDeletionTable.Add();
			vNewDeletionRow.DataType 	= "roomtypes";
			vNewDeletionRow.DataID 		= vRow.ID;
		EndIf;

		vChildRows = vRow.GetItems();
		For Each vChildRow In vChildRows Do
			If ValueIsFilled(vChildRow.ID) Then
				vNewDeletionRow 			= DataDeletionTable.Add();
				vNewDeletionRow.DataType 	= "roomtypes_virtual";
				vNewDeletionRow.DataID 		= vChildRow.ID;
			EndIf;
		EndDo;
		
		If vParent = Undefined Then
			vTreeItems = RoomTypes.GetItems();
			vTreeItems.Delete(vRow);
		Else
			vTreeItems = vParent.GetItems();
			vTreeItems.Delete(vRow);	
		EndIf;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateRoomTypes(pCommand)
	
	UpdateRoomTypesAtChannel(Not SyncChangesOnly);
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetRoomTypes(pCommand)
	
	GetRoomTypes_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetUserInfo(pCommand)
	
	GetUserInfo_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteRoomType(pCommand)
	
	If ValueIsFilled(DeleteRoomType_ID) Then
		DeleteRoomType_AtServer();
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetRoomRates(pCommand)
	
	GetRoomRates_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteRoomRate(pCommand)
	
	If ValueIsFilled(DeleteRoomRate_ID) Then
		DeleteRoomRate_AtServer();
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateRoomRates(pCommand)
	
	UpdateRoomRates_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetRestrictionPlans(pCommand)
	
	GetRestrictionPlans_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateRestrictionPlans(pCommand)
	
	UpdateRestrictionPlans_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdatePrices(pCommand)
	
	UpdatePrices_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateAvailability(pCommand)
	
	UpdateAvailability_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetAvailability(pCommand)

	If ValueIsFilled(GetData_Period.StartDate) And ValueIsFilled(GetData_Period.EndDate) Then
		GetAvailability_AtServer();
	Else
		tcCommonFunctionOnClientServer.TextMessage("Choose period!");	
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetPrices(pCommand)
	
	If ValueIsFilled(GetData_Period.StartDate) And ValueIsFilled(GetData_Period.EndDate) Then
		vRoomRateList = New ValueList;

		For Each vRoomRate In RoomRates Do
			If ValueIsFilled(vRoomRate.ID) Then
				vRoomRateList.Add(vRoomRate.RoomRate);
			EndIf;
		EndDo;
		
		If vRoomRateList.Count() > 0 Then
			vRoomRateList.ShowChooseItem(New NotifyDescription("AfterRoomRateChose", ThisForm), NStr("en = 'Choose a roomrate'; de = 'Wählen Sie einen Zimmerpreis'; ru = 'Выберите тариф'"));
		Else
			tcCommonFunctionOnClientServer.TextMessage("No room rates found.");
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage("Choose period!");	
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetRestrictions(pCommand)
	
	If ValueIsFilled(GetData_Period.StartDate) And ValueIsFilled(GetData_Period.EndDate) Then
		GetRestrictions_AtServer();
	Else
		tcCommonFunctionOnClientServer.TextMessage("Choose period!");	
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetReservations(pCommand)
	
	GetReservations_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillRoomTypes(pCommand)
	
	OpenForm("Catalog.AccommodationTemplates.ChoiceForm",,,,,, New NotifyDescription("AfterAccommodationTemplateChoice", ThisForm));
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadAgentData(pCommand)
	
	If Save_AtServer() And ValueIsFilled(Agent) Then
		
		LoadAgentData_AtServer(Agent);
		
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActivateAgent(pCommand)
	
	If Save_AtServer() And Items.Agents.CurrentData <> Undefined Then

		If ValueIsFilled(Items.Agents.CurrentData.Agent) And ValueIsFilled(Items.Agents.CurrentData.ExternalHotelID) And Not ValueIsFilled(Items.Agents.CurrentData.OTAGatewayID) Then
			ActivateAgent_AtServer(Items.Agents.CurrentData.ExternalHotelID, Items.Agents.CurrentData.ID);
		EndIf;
		
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DeactivateAgent(pCommand)
	
	If Save_AtServer() And Items.Agents.CurrentData <> Undefined Then

		If ValueIsFilled(Items.Agents.CurrentData.Agent) And ValueIsFilled(Items.Agents.CurrentData.ExternalHotelID) And ValueIsFilled(Items.Agents.CurrentData.OTAGatewayID) Then
			DeactivateAgent_AtServer(Items.Agents.CurrentData.OTAGatewayID, Items.Agents.CurrentData.ID);
		EndIf;
		
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAgentData(pCommand)
	
	If Save_AtServer() And ValueIsFilled(Agent) Then
		UpdateAgentDataInGateway(Agent);
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetMappedOTARoomRates(pCommand)
	
	If ValueIsFilled(GetDataAgent) Then
		GetMappedOTARoomRates_AtServer();
	Else
		tcCommonFunctionOnClientServer.TextMessage("Choose agent!");	
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetMappedOTARoomTypes(pCommand)
	
	If ValueIsFilled(GetDataAgent) Then
		GetMappedOTARoomTypes_AtServer();
	Else
		tcCommonFunctionOnClientServer.TextMessage("Choose agent!");	
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetMappedOTAOccupancies(pCommand)
	
	If ValueIsFilled(GetDataAgent) Then
		GetMappedOTAOccupancies_AtServer();
	Else
		tcCommonFunctionOnClientServer.TextMessage("Choose agent!");	
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateAccountData(pCommand)
	
	If Save_AtServer() Then
		UpdateAccountData_AtServer();
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GetAccountData(pCommand)
	
	GetAccountData_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadAgentsFromGateway(pCommand)
	
	If Save_AtServer() Then
		LoadAgentsFromGateway_AtServer();
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobChangesSyncSchedule(pCommand)
	If ValueIsFilled(EmployeeChangesSync) Then
		If Not IsInRoleAtServer("Administrator") Then
			Raise(NStr("en='A background job can be configured by system administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
		Else 				
			vScheduleDlg = New ScheduledJobDialog(ScheduleChangesSync);
			vScheduleDlg.Show(New NotifyDescription("SetupBackgroundJobChangesSyncSchedule_AfterInput", ThisForm, New Structure()));		
		EndIf;
	Else 
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure // SetupBackgroundJobChangesSyncSchedule

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobFullSyncSchedule(pCommand)
	If ValueIsFilled(EmployeeFullSync) Then
		If Not IsInRoleAtServer("Administrator") Then
			Raise(NStr("en='A background job can be configured by system administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
		Else 				
			vScheduleDlg = New ScheduledJobDialog(ScheduleFullSync);
			vScheduleDlg.Show(New NotifyDescription("SetupBackgroundJobFullSyncSchedule_AfterInput", ThisForm, New Structure()));
		EndIf;
	Else 
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure // SetupBackgroundJobFullSyncSchedule

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobChangesSyncSchedule_AfterInput(pValue, pParametrs) Export
	If pValue <> Undefined Then
		ScheduleChangesSync = pValue;
	EndIf;
	
	SetupBackgroundJobChangesSyncSchedule_AtServer();
EndProcedure // SetupBackgroundJobChangesSyncSchedule_AfterInput

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobFullSyncSchedule_AfterInput(pValue, pParametrs) Export
	If pValue <> Undefined Then
		ScheduleFullSync = pValue;
	EndIf;
	
	SetupBackgroundJobFullSyncSchedule_AtServer();
EndProcedure // SetupBackgroundJobFullSyncSchedule_AfterInput

// -----------------------------------------------------------------------------
&AtServer
Procedure GetUserInfo_AtServer()
	
	vResult = OTAGateway.GetUserInfo(Object.InteractionParameters, True);
	
	If Not IsBlankString(vResult.Raw) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
		ValueToFormAttribute(vValueTree, "DataViewTree");
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteRoomType_AtServer()
	
	vResult = OTAGateway.DeleteRoomType(Object.InteractionParameters, , Object.AccountID, DeleteRoomType_ID);
	
	If CheckServiceResult(vResult, True) Then
		vRowToDelete 	= Undefined;
		vTreeItems 		= RoomTypes.GetItems();
		For Each vTreeRow In vTreeItems Do
			If vTreeRow.ID = DeleteRoomType_ID Then
				
				vRowToDelete = vTreeRow;
				
				vChildRows = vTreeRow.GetItems();
				For Each vChildRow In vChildRows Do
					If ValueIsFilled(vChildRow.ID) Then
						vNewDeletionRow 			= DataDeletionTable.Add();
						vNewDeletionRow.DataType 	= "roomtypes_virtual";
						vNewDeletionRow.DataID 		= vChildRow.ID;
					EndIf;
				EndDo;
				
			Else
				
				vChildRowToDelete = Undefined;
				vChildRows = vTreeRow.GetItems();
				For Each vChildRow In vChildRows Do
					If ValueIsFilled(vChildRow.ID) And vChildRow.ID = DeleteRoomType_ID Then
						vChildRowToDelete = vChildRow;
						Break;
					EndIf;
				EndDo;
				
				If vChildRowToDelete <> Undefined Then
					vChildRows.Delete(vChildRowToDelete);
				EndIf;
				
			EndIf;
		EndDo;
		
		If vRowToDelete <> Undefined Then
			vTreeItems.Delete(vRowToDelete);
		EndIf;

		Save_AtServer();
		
	EndIf;
		
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetRoomRates_AtServer()
	
	vResult = OTAGateway.GetRoomRates(Object.InteractionParameters, True, Object.AccountID);
	
	If Not IsBlankString(vResult.Raw) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
		ValueToFormAttribute(vValueTree, "DataViewTree");
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetRoomTypes_AtServer()
	
	vResult = OTAGateway.GetRoomTypes(Object.InteractionParameters, True, Object.AccountID);
	
	If Not IsBlankString(vResult.Raw) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
		ValueToFormAttribute(vValueTree, "DataViewTree");
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteRoomRate_AtServer()
	
	vResult = OTAGateway.DeleteRoomRate(Object.InteractionParameters, , Object.AccountID, DeleteRoomRate_ID);
	
	If CheckServiceResult(vResult, True) Then
		vRowToDelete = Undefined;
		For Each vRow In RoomRates Do
			If ValueIsFilled(vRow.ID) And vRow.ID = DeleteRoomRate_ID Then
				vRowToDelete = vRow;
				Break;
			EndIf;
		EndDo;
		RoomRates.Delete(vRowToDelete);
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ConnectionTest_AtServer()
	
	vColors = GetFormItemsColors();
	
	vPingResult = OTAGateway.Ping(Object.InteractionParameters);
	
	If vPingResult.Success Then
		Items.HTTPServer.BackColor = vColors.Success;		
	Else
		Items.HTTPServer.BackColor = vColors.Failure;
		
		vUserMsg 		= New UserMessage;
		vUserMsg.Text 	= NStr("en = 'Failed to connect to the server'; de = 'Verbindung zum Server fehlgeschlagen'; ru = 'Не удалось подключиться к серверу'") + "; " + vPingResult.Error;
		vUserMsg.Field	= "HTTPServer";
		vUserMsg.Message();
		
		Return;
	EndIf;
	
	vTokenResult = OTAGateway.GetNewToken(Object.InteractionParameters);
	
	If vTokenResult.Success Then
		Items.Username.BackColor = vColors.Success;
		Items.Password.BackColor = vColors.Success;
	Else
		Items.Username.BackColor = vColors.Failure;
		Items.Password.BackColor = vColors.Failure;
		
		vUserMsg 		= New UserMessage;
		vUserMsg.Text 	= NStr("en = 'Wrong username or password!'; de = 'Benutzername oder Passwort falsch!'; ru = 'Неверное имя пользователя или пароль!'")+ "; " + vTokenResult.Error;
		vUserMsg.Field	= "Password";
		vUserMsg.Message();
		
		Return;
	EndIf;

	If vPingResult.Success And vTokenResult.Success Then
		vUserMsg 		= New UserMessage;
		vUserMsg.Text 	= NStr("en = 'Successful connection!'; de = 'Erfolgreiche Verbindung!'; ru = 'Успешное подключение!'");
		vUserMsg.Field	= "Ping";
		vUserMsg.Message();
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateRoomRates_AtServer()
	
	If Save_AtServer() Then
	
		vResult = OTAGateway.CreateAndUpdateRoomRates(Object.InteractionParameters,, RoomRates, Object.AccountID, Not SyncChangesOnly);
		
		CheckServiceResult(vResult, True);
		
		SaveRoomRatesTable();
		
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateRestrictionPlans_AtServer()
	
	If Save_AtServer() Then
		
		For Each vRoomRate In RoomRates Do
			If ValueIsFilled(vRoomRate.ID) Then
				vResult = OTAGateway.CreateAndUpdateRestrictionPlans(Object.InteractionParameters,, vRoomRate.RoomRate, vRoomRate.ID ,Object.AccountID, Object.AmountOfDaysToUpdate, Not SyncChangesOnly);
				
				CheckServiceResult(vResult, True);
			EndIf;
		 EndDo;
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetRestrictionPlans_AtServer()
	
	vResult = OTAGateway.GetRestrictionPlans(Object.InteractionParameters, True, Object.AccountID);
	
	If Not IsBlankString(vResult.Raw) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
		ValueToFormAttribute(vValueTree, "DataViewTree");
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdatePrices_AtServer()
	
	If Save_AtServer() Then
	
		vResult = OTAGateway.CreateAndUpdatePrices(Object.InteractionParameters,, Object.AccountID, Object.AmountOfDaysToUpdate, Not SyncChangesOnly);
		
		CheckServiceResult(vResult, True);
		
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterRoomRateChose(pValue, pParams) Export
	
	If pValue = Undefined Or Not ValueIsFilled(pValue.Value) Then
		Return;
	EndIf;
	
	GetPrices_AtServer(pValue.Value);
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetPrices_AtServer(pRoomRate)
	
	vResult = OTAGateway.GetPrices(Object.InteractionParameters, True, Object.AccountID, pRoomRate, GetData_Period.StartDate, GetData_Period.EndDate);
	
	If Not IsBlankString(vResult.Raw) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
		ValueToFormAttribute(vValueTree, "DataViewTree");
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateAvailability_AtServer()
	
	If Save_AtServer() Then
	
		vResult = OTAGateway.UpdateAvailability(Object.InteractionParameters, ,Object.AccountID, Object.AmountOfDaysToUpdate, Not SyncChangesOnly);
		
		CheckServiceResult(vResult, True);
		
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetAvailability_AtServer()
	
	vResult = OTAGateway.GetAvailability(Object.InteractionParameters, True, Object.AccountID, GetData_Period.StartDate, GetData_Period.EndDate);
	
	If Not IsBlankString(vResult.Raw) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
		ValueToFormAttribute(vValueTree, "DataViewTree");
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetRestrictions_AtServer()
	
	vResult = OTAGateway.GetRestrictions(Object.InteractionParameters, True, Object.AccountID, GetData_Period.StartDate, GetData_Period.EndDate);
	
	If Not IsBlankString(vResult.Raw) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
		ValueToFormAttribute(vValueTree, "DataViewTree");
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetReservations_AtServer()
	If Not ValueIsFilled(LoadReservationsFromFile) Then	
		OTAGateway.GetBookings(Object.InteractionParameters, Object.AccountID, Object.LoadAdultGuestsAmountFromExtraDataArray, Object.LoadChildGuestsAmountFromExtraDataArray, Object.GetPrices);
	Else
		OTAGateway.GetBookingsFromFile(Object.InteractionParameters, LoadReservationsFromFile, Object.AccountID, Object.LoadAdultGuestsAmountFromExtraDataArray, Object.LoadChildGuestsAmountFromExtraDataArray, Object.GetPrices);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterAccommodationTemplateChoice(pValue, pParams) Export
	
	If Not ValueIsFilled(pValue) Then
		Return;
	EndIf;
	
	FillRoomTypes_AtServer(pValue);
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomTypes_AtServer(pAccommodationTemplate)
	
	If Not ValueIsFilled(pAccommodationTemplate) Then
		Return;
	EndIf;
	
	vRoomTypes 		= pAccommodationTemplate.RoomTypes;
	vRoomTypeTree 	= RoomTypes.GetItems();
	For Each vRoomTypeRow In vRoomTypes Do
		vExists = False;
		For Each vRoomTypeTreeRow In vRoomTypeTree Do
			If vRoomTypeTreeRow.RoomType = vRoomTypeRow.RoomType And vRoomTypeTreeRow.AccommodationTemplate = pAccommodationTemplate Then
				vExists = True;
				Break;
			EndIf;
		EndDo;
		If Not vExists Then
			vNewRow 						= vRoomTypeTree.Add();
			vNewRow.RoomType 				= vRoomTypeRow.RoomType;
			vNewRow.AccommodationTemplate 	= pAccommodationTemplate;
			vNewRow.Name 					= vRoomTypeRow.RoomType.Description;
		EndIf;
	EndDo;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ActivateAgent_AtServer(pExternalHotelID, pOTAID)
	
	vOTACredentials = New Structure("hotel_id", pExternalHotelID);
	vResult = OTAGateway.CreateNewChannel(Object.InteractionParameters, , Object.AccountID, pOTAID, vOTACredentials); 
	
	If vResult.Success Then
		vAgentsRows = Agents.FindRows(New Structure("ExternalHotelID, ID", pExternalHotelID, pOTAID));
		For Each vRow In vAgentsRows Do
			vRow.OTAGatewayID = Format(vResult.Result,"NG=");
		EndDo;
		
		Save_AtServer();
		Items.Agents.Refresh();
	Else
		tcCommonFunctionOnClientServer.TextMessage(vResult.Error);
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DeactivateAgent_AtServer(pOTAGatewayID, pOTAID)
	
	vResult = OTAGateway.DeleteChannel(Object.InteractionParameters, , Object.AccountID, pOTAID, pOTAGatewayID); 

	If vResult.Success Then
		vAgentsRows = Agents.FindRows(New Structure("OTAGatewayID", pOTAGatewayID));
		For Each vRow In vAgentsRows Do
			vRow.OTAGatewayID = Undefined;
		EndDo;
		
		Save_AtServer();
		Items.Agents.Refresh();
	Else
		tcCommonFunctionOnClientServer.TextMessage(vResult.Error);
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetMappedOTARoomRates_AtServer()
	
	vResult = OTAGateway.GetMappedOTARoomRates(Object.InteractionParameters, Object.AccountID, GetDataAgent, True);
	
	If Not IsBlankString(vResult.Raw) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
		ValueToFormAttribute(vValueTree, "DataViewTree");
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetMappedOTARoomTypes_AtServer()
	
	vResult = OTAGateway.GetMappedOTARoomTypes(Object.InteractionParameters, Object.AccountID, GetDataAgent, True);
	
	If Not IsBlankString(vResult.Raw) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
		ValueToFormAttribute(vValueTree, "DataViewTree");
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetMappedOTAOccupancies_AtServer()
	
	vResult = OTAGateway.GetMappedOTAOccupancies(Object.InteractionParameters, Object.AccountID, GetDataAgent, True);
	
	If Not IsBlankString(vResult.Raw) Then
		vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
		ValueToFormAttribute(vValueTree, "DataViewTree");
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateAccountData_AtServer()
	
	vUpdateStructure = New Structure;
	If ValueIsFilled(HotelPhone) Then
		vUpdateStructure.Insert("phone", HotelPhone);
	EndIf;
	
	If ValueIsFilled(HotelTimezone) Then
		vUpdateStructure.Insert("timezone", HotelTimezone);
	EndIf;

	If ValueIsFilled(DefaultCheckInTime) Then
		vUpdateStructure.Insert("checkin", Format(DefaultCheckInTime, "DF=H:mm"));
	EndIf;

	If ValueIsFilled(DefaultCheckOutTime) Then
		vUpdateStructure.Insert("checkout", Format(DefaultCheckOutTime, "DF=H:mm"));
	EndIf;

	If ValueIsFilled(HotelEmail) Then
		vUpdateStructure.Insert("email", HotelEmail);
	EndIf;

	If vUpdateStructure.Count() > 0 Then
		vResult = OTAGateway.UpdateAccount(Object.InteractionParameters,, Object.AccountID, vUpdateStructure);
		If vResult.Success Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success'; de = 'Success'; ru = 'Успешно'"));
		Else
			tcCommonFunctionOnClientServer.TextMessage(vResult.Error);
		EndIf;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadAgentsFromGateway_AtServer()
	
	Agents.Clear();
	AgentsRoomRates.Clear();
	AgentsRoomTypes.Clear();
	AgentsOccupancies.Clear();
	LoadAgents();
	LoadAgentsData();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure GetAccountData_AtServer()
	
	If ValueIsFilled(Object.AccountID) Then
		vResult = OTAGateway.GetAccount(Object.InteractionParameters, True, Object.AccountID);
		
		If Not IsBlankString(vResult.Raw) Then
			vValueTree = Catalogs.DataConvertationRules.JSONtoValueTree(vResult.Raw);
			ValueToFormAttribute(vValueTree, "DataViewTree");
		EndIf;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function Save_AtServer()
	
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	BeginTransaction();
	
	Try  
		SetPrivilegedMode(True);
		SaveInteractionParameters();
		SaveReservationStatuses();
		 
		// Delete from channel
		vVirtualRoomTypes = DataDeletionTable.FindRows(New Structure("DataType", "roomtypes_virtual"));
		
		// Virtual room types must be deleted before parents
		For Each vRow In vVirtualRoomTypes Do
			vResult = OTAGateway.DeleteRoomType(Object.InteractionParameters, , Object.AccountID, vRow.DataID);
			CheckServiceResult(vResult);
		EndDo;
		
		For Each vRow In DataDeletionTable Do
			If vRow.DataType = "roomtypes" Then
				vResult = OTAGateway.DeleteRoomType(Object.InteractionParameters, , Object.AccountID, vRow.DataID);
				CheckServiceResult(vResult);
			ElsIf vRow.DataType = "roomrates" Then
				vResult = OTAGateway.DeleteRoomRate(Object.InteractionParameters, , Object.AccountID, vRow.DataID);
				CheckServiceResult(vResult);
			EndIf;
		EndDo;

		UpdateRoomTypesAtChannel();
		
		vResult = OTAGateway.CreateAndUpdateRoomRates(Object.InteractionParameters, , RoomRates, Object.AccountID);
		CheckServiceResult(vResult);
		SaveRoomRatesTable();
		SaveAgents();
		SaveAgentsData();
		SaveHotelData();
		
		// Save DP parameters
		If ValueIsFilled(DataProcessorFullSync) And DataProcessorFullSync <> DataProcessorChangesSync Then
			vObj = FormAttributeToValue("Object");
			vObj.DataProcessor = DataProcessorFullSync;
			vObj.DoFullSync = True;
			vObj.pmSaveDataProcessorAttributes();
			ValueToFormAttribute(vObj, "Object");
		EndIf;
		If ValueIsFilled(DataProcessorChangesSync) Then
			vObj = FormAttributeToValue("Object");
			vObj.DataProcessor = DataProcessorChangesSync;
			vObj.DoFullSync = False;
			vObj.pmSaveDataProcessorAttributes();
			ValueToFormAttribute(vObj, "Object");
		EndIf;

		SetPrivilegedMode(False);
		CommitTransaction();

		Return True;
	Except
		RollbackTransaction();
		vError = cmGetRootErrorDescription(ErrorInfo());
		tcCommonFunctionOnClientServer.TextMessage(vError);

		Return False;
	EndTry;
	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveRoomTypesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "roomtypes");
	
	vMainRoomTypes = RoomTypes.GetItems();
	
	For Each vMainTypeRow In vMainRoomTypes Do
		If ValueIsFilled(vMainTypeRow.RoomType) And ValueIsFilled(vMainTypeRow.AccommodationTemplate) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "UUID", 		vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, vMainTypeRow.UUID, 			vMainTypeRow.UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "ID", 			vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, vMainTypeRow.ID, 			vMainTypeRow.UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "Name", 		vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, vMainTypeRow.Name, 			vMainTypeRow.UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "DefaultPrice", vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, vMainTypeRow.DefaultPrice, 	vMainTypeRow.UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "Description", 	vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, vMainTypeRow.Description, 	vMainTypeRow.UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "Enabled", 		vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, vMainTypeRow.Enabled, 		vMainTypeRow.UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "EnabledOTA", 	vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, vMainTypeRow.EnabledOTA, 	vMainTypeRow.UUID);
			
			vVirtualRoomTypes = vMainTypeRow.GetItems();
			For Each vVirtualTypeRow In vVirtualRoomTypes Do
				If ValueIsFilled(vVirtualTypeRow.RoomType) And ValueIsFilled(vVirtualTypeRow.AccommodationTemplate) Then
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "parentUUID", 	vVirtualTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vMainTypeRow.UUID, 			vVirtualTypeRow.UUID);
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "ID", 			vVirtualTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vVirtualTypeRow.ID, 			vVirtualTypeRow.UUID);
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "parentid", 	vVirtualTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vMainTypeRow.ID, 				vVirtualTypeRow.UUID);
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "Name", 		vVirtualTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vVirtualTypeRow.Name, 			vVirtualTypeRow.UUID);
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "DefaultPrice", vVirtualTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vVirtualTypeRow.DefaultPrice, 	vVirtualTypeRow.UUID);
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "Description", 	vVirtualTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vVirtualTypeRow.Description, 	vVirtualTypeRow.UUID);
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "Enabled", 		vVirtualTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vVirtualTypeRow.Enabled, 		vVirtualTypeRow.UUID);
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "EnabledOTA", 	vVirtualTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vVirtualTypeRow.EnabledOTA, 	vVirtualTypeRow.UUID);
				EndIf;	
			EndDo;
			
		EndIf;
	EndDo;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadRoomTypesTable()
	
	vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "roomtypes");
	
	If vRoomTypes.Count() > 0 Then
		vRoomTypes.Sort("UUID Desc");
		
		vParentUUIDColumnExists = False;
		vUUIDColumnExists 		= False;
		If vRoomTypes.Columns.Find("parentUUID") <> Undefined Then
			vParentUUIDColumnExists = True;
		EndIf;
		If vRoomTypes.Columns.Find("UUID") <> Undefined Then
			vUUIDColumnExists = True
		EndIf;
		
		vTreeItems	= RoomTypes.GetItems();
		For Each vRoomTypeRow In vRoomTypes Do
			vParentUUID = Undefined;
			vUUID		= Undefined;
			
			If vParentUUIDColumnExists Then
				vParentUUID = vRoomTypeRow.parentUUID;
			EndIf;
			
			If vUUIDColumnExists Then
				vUUID = vRoomTypeRow.UUID;
			EndIf;
			
			If ValueIsFilled(vUUID) And Not ValueIsFilled(vParentUUID) Then  
				vNewRow 						= vTreeItems.Add();
				vNewRow.RoomType 				= vRoomTypeRow.RefKey1;
				vNewRow.AccommodationTemplate 	= vRoomTypeRow.RefKey2;
				FillPropertyValues(vNewRow, vRoomTypeRow);
			ElsIf Not ValueIsFilled(vUUID) And ValueIsFilled(vParentUUID) Then
				vParentRow = Undefined;
				For Each vTreeRow In vTreeItems Do
					If vTreeRow.UUID = vParentUUID Then
						vParentRow = vTreeRow;
						Break;
					EndIf;
				EndDo;
				If vParentRow <> Undefined Then
					vNewRow 						= vParentRow.GetItems().Add();
					vNewRow.RoomType 				= vRoomTypeRow.RefKey1;
					vNewRow.AccommodationTemplate 	= vRoomTypeRow.RefKey2;
					vNewRow.Virtual					= True;
					FillPropertyValues(vNewRow, vRoomTypeRow);
				Else
					tcCommonFunctionOnClientServer.TextMessage("Error loading room types table!");
				EndIf;
			Else
				tcCommonFunctionOnClientServer.TextMessage("Error loading room types table!");
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveRoomRatesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "roomrates");
	
	For Each vRoomRateRow In RoomRates Do
		If ValueIsFilled(vRoomRateRow.RoomRate) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "ID", 						vRoomRateRow.RoomRate, Undefined, vRoomRateRow.ID, 						vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "Name", 					vRoomRateRow.RoomRate, Undefined, vRoomRateRow.Name, 					vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "Description", 				vRoomRateRow.RoomRate, Undefined, vRoomRateRow.Description, 			vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "Enabled", 					vRoomRateRow.RoomRate, Undefined, vRoomRateRow.Enabled, 				vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "EnabledOTA", 				vRoomRateRow.RoomRate, Undefined, vRoomRateRow.EnabledOTA, 				vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "CancellationRules", 		vRoomRateRow.RoomRate, Undefined, vRoomRateRow.CancellationRules, 		vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "Default", 					vRoomRateRow.RoomRate, Undefined, vRoomRateRow.Default, 				vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "Breakfast", 				vRoomRateRow.RoomRate, Undefined, vRoomRateRow.Breakfast, 				vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "Lunch", 					vRoomRateRow.RoomRate, Undefined, vRoomRateRow.Lunch, 					vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "Dinner", 					vRoomRateRow.RoomRate, Undefined, vRoomRateRow.Dinner, 					vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "IndexNumber", 				vRoomRateRow.RoomRate, Undefined, vRoomRateRow.IndexNumber, 			vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "MinHoursBeforeArrival", 	vRoomRateRow.RoomRate, Undefined, vRoomRateRow.MinHoursBeforeArrival, 	vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "MaxHoursBeforeArrival", 	vRoomRateRow.RoomRate, Undefined, vRoomRateRow.IndexNumber, 			vRoomRateRow.ID);
		EndIf;
	EndDo;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadRoomRatesTable()
	
	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "roomrates");
	
	If vRoomRates.Count() > 0 Then
		vRoomRates.Sort("IndexNumber Desc");
		
		For Each vRoomRateRow In vRoomRates Do
			vNewRow 					= RoomRates.Add();
			vNewRow.RoomRate 			= vRoomRateRow.RefKey1; 
			FillPropertyValues(vNewRow, vRoomRateRow);		
		EndDo;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveReservationStatuses()
	
 	If ValueIsFilled(ReservationStatus_New) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_New, Undefined, 1, 1);
	EndIf;
	
	If ValueIsFilled(ReservationStatus_Cancel) Then
 		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_Cancel, Undefined, 2, 2);
	EndIf;

	If ValueIsFilled(ReservationStatus_Pending) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_Pending, Undefined, 3, 3);
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadReservationStatuses()
	
	vReservationStatuses = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "reservationstatuses");
	
	If vReservationStatuses.Columns.Find("ID") <> Undefined And vReservationStatuses.Count() > 0 Then
		For Each vReservationStatus In vReservationStatuses Do
			If vReservationStatus.ID = 1 Then
				ReservationStatus_New = vReservationStatus.RefKey1;
			ElsIf vReservationStatus.ID = 2 Then
				ReservationStatus_Cancel = vReservationStatus.RefKey1;
			ElsIf vReservationStatus.ID = 3 Then
				ReservationStatus_Pending = vReservationStatus.RefKey1;
			EndIf;
		EndDo;
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateRoomTypesAtChannel(pFull = False)
	
	vRoomTypes 	= RoomTypes.GetItems();
	vResult 	= OTAGateway.CreateAndUpdateRoomTypes(Object.InteractionParameters,, vRoomTypes, ,Object.AccountID, pFull);
	
	CheckServiceResult(vResult, pFull);
	
	For Each vRoomType In vRoomTypes Do
		vVirtualRoomTypes 	= vRoomType.GetItems();
		vResult	 			= OTAGateway.CreateAndUpdateRoomTypes(Object.InteractionParameters,, vVirtualRoomTypes, vRoomType.ID, Object.AccountID, pFull);
		CheckServiceResult(vResult, pFull);
	EndDo;
	
	SaveRoomTypesTable();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	vIntParObj = Object.InteractionParameters.GetObject();
	vIntParObj.Login = Username;	
	vIntParObj.Password = Password;	
	vIntParObj.HttpServer = HTTPServer;
	vIntParObj.Hotel = Hotel;
	vIntParObj.Allotment = Allotment;
	vIntParObj.IsActive = Active;
	vIntParObj.DebugMode = Debug;
	vIntParObj.HttpAddress = HTTPAddress;
	vIntParObj.HttpUseSsl = HTTPUseSSL;
	vIntParObj.ClientType = ClientType;
	vIntParObj.Currency = Currency;
	vIntParObj.ConvertCurrency = ConvertCurrency;
	vIntParObj.MaxLogLenght = MaxLogLenght;
	If LastExportTimestampForInventoryWasChanged Then
		vIntParObj.LastExportTimestampForInventory = LastExportTimestampForInventory;
	EndIf;
	If LastExportTimestampForPricesWasChanged Then
		vIntParObj.LastExportTimestampForPrices = LastExportTimestampForPrices;
	EndIf;
	If LastExportTimestampForRestrictionsWasChanged Then
		vIntParObj.LastExportTimestampForRestrictions = LastExportTimestampForRestrictions;
	EndIf;
	vIntParObj.Write();
	
	LastExportTimestampForInventoryWasChanged = False;
	LastExportTimestampForPricesWasChanged = False;
	LastExportTimestampForRestrictionsWasChanged = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	vIP = Object.InteractionParameters;
	If Not ValueIsFilled(vIP) Then
		Return;
	EndIf;
	
	Username = vIP.Login;	
	Password = vIP.Password;	
	HTTPServer = vIP.HttpServer;
	Hotel = vIP.Hotel;
	Allotment = vIP.Allotment;
	Active = vIP.IsActive;
	Debug = vIP.DebugMode;
	HTTPAddress = vIP.HttpAddress;
	HTTPUseSSL = vIP.HttpUseSsl;
	ClientType = vIP.ClientType;
	Currency = vIP.Currency;
	ConvertCurrency = vIP.ConvertCurrency;
	MaxLogLenght = vIP.MaxLogLenght;

	LastFullSynchronizationTime = vIP.LastFullSynchronizationTime;
	
	LastExportTimestampForInventory = vIP.LastExportTimestampForInventory;
	LastExportTimestampForPrices = vIP.LastExportTimestampForPrices;
	LastExportTimestampForRestrictions = vIP.LastExportTimestampForRestrictions;
	
	IntegrationStatus = vIP.Status;
	
	LastExportTimestampForInventoryWasChanged = False;
	LastExportTimestampForPricesWasChanged = False;
	LastExportTimestampForRestrictionsWasChanged = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function LoadRoomRatesFromOTA()
	
	If Save_AtServer() Then
		vRoomRates = OTAGateway.GetRoomRates(Object.InteractionParameters,, Object.AccountID);
		CheckServiceResult(vRoomRates);
		If vRoomRates.ResultMap <> Undefined Then
			vRoomRatesMap = vRoomRates.ResultMap.Get("plans");
			If vRoomRatesMap <> Undefined Then
				For Each vRoomRateMap In vRoomRatesMap Do
					vID = Format(vRoomRateMap.Get("id"), "NG=");
					vCreateNew = True;
					For Each vRoomRateRow In RoomRates Do
						If vRoomRateRow.ID = vID Then
							vCreateNew = False;
							Break;
						EndIf;
					EndDo;
					
					If vCreateNew Then
						vNewRow 					= RoomRates.Add();
						vNewRow.ID 					= vID;
						vNewRow.isModified 			= True;
						vNewRow.Name 				= vRoomRateMap.Get("name");
						vNewRow.Default 			= vRoomRateMap.Get("default");
						vNewRow.Enabled 			= vRoomRateMap.Get("enabled");
						vNewRow.EnabledOTA 			= vRoomRateMap.Get("enabled_ota");
						vNewRow.Description 		= vRoomRateMap.Get("description");
						vNewRow.CancellationRules 	= vRoomRateMap.Get("cancellation_rules");
						vNewRow.Name 				= vRoomRateMap.Get("name");
						
						vRestrictionPlanID = vRoomRateMap.Get("restriction_plan_id");
						If vRestrictionPlanID <> Undefined And vRestrictionPlanID > 0 Then
							vRestrictionPlan = OTAGateway.GetRestrictionPlans(Object.InteractionParameters,, Object.AccountID, vRestrictionPlanID);	
							CheckServiceResult(vRestrictionPlan);

							If vRestrictionPlan.ResultMap <> Undefined Then
								vRestrictionMap = vRestrictionPlan.ResultMap.Get("restriction_plan");
								If vRestrictionMap <> Undefined Then
									vNewRow.MinHoursBeforeArrival 	= vRestrictionMap.Get("min_hours_before_arrival"); 
									vNewRow.MaxHoursBeforeArrival 	= vRestrictionMap.Get("max_hours_before_arrival");
									vNewRow.RestrictionPlanID		= Format(vRestrictionPlanID, "NG=");
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function LoadRoomTypesFromOTA()
	
	If Save_AtServer() Then
		vRoomTypes = OTAGateway.GetRoomTypes(Object.InteractionParameters,, Object.AccountID);
		CheckServiceResult(vRoomTypes);
		
		If vRoomTypes.ResultMap <> Undefined Then
			vRoomTypesMap = vRoomTypes.ResultMap.Get("roomtypes");
			If vRoomTypesMap <> Undefined Then
				For Each vRoomTypeKeyAndValue In vRoomTypesMap Do
					If TypeOf(vRoomTypeKeyAndValue) = Type("Map") Then
						vRoomTypeMap = vRoomTypeKeyAndValue;	
					Else
						vRoomTypeMap = vRoomTypeKeyAndValue.Value;
					EndIf;
					Try
						vID 		= Format(vRoomTypeMap.Get("id"), "NG=");
					Except
						vRoomTypeMap	= vRoomTypeKeyAndValue;
						vID 			= Format(vRoomTypeMap.Get("id"), "NG=");	
					EndTry;
					vParentID 		= vRoomTypeMap.Get("parent_id");
					
					vCreateNew = True;
					If vParentID > 0 Then
						vRoomTypesTree = RoomTypes.GetItems();
						For Each vRoomTypeRow In vRoomTypesTree Do
							vChildRoomTypes = vRoomTypeRow.GetItems();
							For Each vChildRoomTypeRow In vChildRoomTypes Do
								If vChildRoomTypeRow.ID = vID Then
									vCreateNew = False;
									Break;
								EndIf;
							EndDo;
							If Not vCreateNew Then
								Break;
							EndIf;
						EndDo;	
					Else
						vRoomTypesTree = RoomTypes.GetItems();
						For Each vRoomTypeRow In vRoomTypesTree Do
							If vRoomTypeRow.ID = vID Then
								vCreateNew = False;
								Break;
							EndIf;
						EndDo;
					EndIf;
					
					If vCreateNew Then
						vNewRow = Undefined;
						If vParentID > 0 Then
							vRoomTypesTree = RoomTypes.GetItems();
							For Each vRoomTypeRow In vRoomTypesTree Do
								If vRoomTypeRow.ID = Format(vParentID, "NG=") Then
									vNewRow = vRoomTypeRow.GetItems().Add();
									Break;	
								EndIf;
							EndDo;

						Else
							vNewRow = RoomTypes.GetItems().Add();
						EndIf;
						
						If vNewRow <> Undefined Then
							vNewRow.UUID 		= String(New UUID);
							vNewRow.ID			= vID;
							vNewRow.Virtual		= vParentID > 0;
							vNewRow.Name		= vRoomTypeMap.Get("name");
							vNewRow.Description	= vRoomTypeMap.Get("description");
							vNewRow.DefaultPrice= vRoomTypeMap.Get("price");
							vNewRow.Enabled		= vRoomTypeMap.Get("enabled");
							vNewRow.EnabledOTA	= vRoomTypeMap.Get("enabled_ota");
							vNewRow.isModified	= True;
						Else
							tcCommonFunctionOnClientServer.TextMessage("Failed to find parent room type for ID:" + vID + " and ParentID:" + vParentID);
						EndIf;
					EndIf;
					
				EndDo;
			EndIf;
		EndIf;
		
	EndIf;
	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function LoadAgents()
	
	If ValueIsFilled(Username) And ValueIsFilled(Object.AccountID) Then
		vAgents = OTAGateway.GetOTAsList(Object.InteractionParameters);
		CheckServiceResult(vAgents);
		
		If vAgents.ResultMap <> Undefined Then
			vLoadedAgents 	= InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "agents");
			vAgentsMap 		= vAgents.ResultMap.Get("otas");
			For Each vAgent In vAgentsMap Do
				vNewRow 		= Agents.Add();
				vNewRow.ID 		= vAgent.Get("ota_id");
				vNewRow.Name 	= vAgent.Get("ota_name");
				
				If vLoadedAgents.Count() > 0 Then
					vLoadedRow				= vLoadedAgents.Find(vNewRow.ID, "ID");
					If vLoadedRow <> Undefined Then 
						vNewRow.Agent			= vLoadedRow.RefKey1;
						If vLoadedAgents.Columns.Find("OTAGatewayID") <> Undefined Then 
							vNewRow.OTAGatewayID	= vLoadedRow.OTAGatewayID;
						EndIf;
						If vLoadedAgents.Columns.Find("ExternalHotelID") <> Undefined Then 
							vNewRow.ExternalHotelID	= vLoadedRow.ExternalHotelID;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			
			Agents.Sort("Agent DESC, Name");
		EndIf;
		
	EndIf;
	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveAgents()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "agents");
	
	For Each vAgentRow In Agents Do
		If ValueIsFilled(vAgentRow.Agent) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agents", "ID", 				vAgentRow.Agent, Undefined, vAgentRow.ID, 			vAgentRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agents", "Name", 			vAgentRow.Agent, Undefined, vAgentRow.Name, 		vAgentRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agents", "OTAGatewayID", 	vAgentRow.Agent, Undefined, vAgentRow.OTAGatewayID, vAgentRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agents", "ExternalHotelID", vAgentRow.Agent, Undefined, vAgentRow.ExternalHotelID, vAgentRow.ID);
		EndIf;
	EndDo;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadAgentsData()
	
	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "agentsRoomRates");
	
	If vRoomRates.Count() > 0 Then
		For Each vRoomRateRow In vRoomRates Do
			vNewRow 		= AgentsRoomRates.Add();
			vNewRow.Agent 	= vRoomRateRow.RefKey1; 
			FillPropertyValues(vNewRow, vRoomRateRow);
		EndDo;
	EndIf;

	vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "agentsRoomTypes");
	
	If vRoomTypes.Count() > 0 Then		
		For Each vRoomTypeRow In vRoomTypes Do
			vNewRow 		= AgentsRoomTypes.Add();
			vNewRow.Agent 	= vRoomTypeRow.RefKey1; 
			FillPropertyValues(vNewRow, vRoomTypeRow);
		EndDo;
	EndIf;

	vOccupancies = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "agentsOccupancies");
	
	If vOccupancies.Count() > 0 Then		
		For Each vOccupancy In vOccupancies Do
			vNewRow 		= AgentsOccupancies.Add();
			vNewRow.Agent 	= vOccupancy.RefKey1; 
			FillPropertyValues(vNewRow, vOccupancy);
		EndDo;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveAgentsData()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "agentsRoomRates");
	
	For Each vAgentRow In AgentsRoomRates Do
		If ValueIsFilled(vAgentRow.Agent) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsRoomRates", "RoomRateID", 		vAgentRow.Agent, Undefined, vAgentRow.RoomRateID, 			vAgentRow.OTARoomRateID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsRoomRates", "OTARoomRateName", 	vAgentRow.Agent, Undefined, vAgentRow.OTARoomRateName, 		vAgentRow.OTARoomRateID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsRoomRates", "OTARoomRateID", 		vAgentRow.Agent, Undefined, vAgentRow.OTARoomRateID, 		vAgentRow.OTARoomRateID);
		EndIf;
	EndDo;
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "agentsRoomTypes");
	
	For Each vAgentRow In AgentsRoomTypes Do
		If ValueIsFilled(vAgentRow.Agent) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsRoomTypes", "RoomTypeID", 		vAgentRow.Agent, Undefined, vAgentRow.RoomTypeID, 			vAgentRow.OTARoomTypeID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsRoomTypes", "OTARoomTypeName", 	vAgentRow.Agent, Undefined, vAgentRow.OTARoomTypeName, 		vAgentRow.OTARoomTypeID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsRoomTypes", "OTARoomTypeID", 		vAgentRow.Agent, Undefined, vAgentRow.OTARoomTypeID, 		vAgentRow.OTARoomTypeID);
		EndIf;
	EndDo;

	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "agentsOccupancies");
	
	For Each vAgentRow In AgentsOccupancies Do
		If ValueIsFilled(vAgentRow.Agent) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsOccupancies", "RoomTypeID", 			vAgentRow.Agent, Undefined, vAgentRow.RoomTypeID, 			vAgentRow.OTARoomOccupancyID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsOccupancies", "OTARoomOccupancyID", 	vAgentRow.Agent, Undefined, vAgentRow.OTARoomOccupancyID, 	vAgentRow.OTARoomOccupancyID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsOccupancies", "OTARoomOccupancyName", vAgentRow.Agent, Undefined, vAgentRow.OTARoomOccupancyName, vAgentRow.OTARoomOccupancyID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsOccupancies", "OTARoomTypeID", 		vAgentRow.Agent, Undefined, vAgentRow.OTARoomTypeID, 		vAgentRow.OTARoomOccupancyID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agentsOccupancies", "Capacity", 			vAgentRow.Agent, Undefined, vAgentRow.Capacity, 			vAgentRow.OTARoomOccupancyID);
		EndIf;
	EndDo;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadAgentData_AtServer(pAgent)
		
	vAgentIDTable = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "agents", "OTAGatewayID", pAgent);

	If vAgentIDTable <> Undefined And vAgentIDTable.Count() > 0 Then 	
		vAgentID 	= vAgentIDTable[0].OTAGatewayID;
		vResult 	= OTAGateway.GetOTAData(Object.InteractionParameters, Object.AccountID, vAgentID);
		
		If vResult.Success Then
			vPlans 			= vResult.ResultMap.Get("plans");
			vRooms 			= vResult.ResultMap.Get("rooms");
			vOccupancies 	= vResult.ResultMap.Get("occupancies");

			For Each vRow In vPlans Do
				vID 	= Format(vRow.Get("id"), "NG=");
				vName 	= vRow.Get("name");
				
				vLoadedRows = AgentsRoomRates.FindRows(New Structure("Agent, OTARoomRateID", Agent, vID));
				
				If vLoadedRows.Count() > 0 Then
					vNewRow = vLoadedRows[0];
				Else
					vNewRow = AgentsRoomRates.Add();
				EndIf;
				
				vNewRow.Agent 			= Agent;
				vNewRow.OTARoomRateID 	= vID;
				vNewRow.OTARoomRateName = vName;
			EndDo;
			
			For Each vRow In vRooms Do
				vID 	= Format(vRow.Get("id"), "NG=");
				vName 	= vRow.Get("name");
				
				vLoadedRows = AgentsRoomTypes.FindRows(New Structure("Agent, OTARoomTypeID", Agent, vID));
				
				If vLoadedRows.Count() > 0 Then
					vNewRow = vLoadedRows[0];
				Else
					vNewRow = AgentsRoomTypes.Add();
				EndIf;
				
				vNewRow.Agent 			= Agent;
				vNewRow.OTARoomTypeID 	= vID;
				vNewRow.OTARoomTypeName = vName;
			EndDo;
			
			For Each vRow In vOccupancies Do
				vID 		= Format(vRow.Get("id"), "NG=");
				vRoomID 	= Format(vRow.Get("room_id"), "NG=");
				vName 		= vRow.Get("name");
				vCapacity 	= vRow.Get("capacity");
			
				vLoadedRows = AgentsOccupancies.FindRows(New Structure("Agent, OTARoomOccupancyID", Agent, vID));
				
				If vLoadedRows.Count() > 0 Then
					vNewRow = vLoadedRows[0];
				Else
					vNewRow = AgentsOccupancies.Add();
				EndIf;
				
				vNewRow.Agent 					= Agent;
				vNewRow.OTARoomOccupancyID 		= vID;
				vNewRow.OTARoomOccupancyName 	= vName;
				vNewRow.OTARoomTypeID 			= vRoomID;
				vNewRow.Capacity 				= vCapacity;
			EndDo;

		Else
			tcCommonFunctionOnClientServer.TextMessage(vResult.Error);
		EndIf;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateAgentDataInGateway(pAgent)
	
	vResult 	= OTAGateway.SaveOTADataMappings(Object.InteractionParameters, Object.AccountID, pAgent);
	If vResult.Success Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Saved'; de = 'Saved'; ru = 'Сохранено'"));
	Else
		tcCommonFunctionOnClientServer.TextMessage(vResult.Error);
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveHotelData()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "hotelData");

	vUUID = String(New UUID);
	If ValueIsFilled(DefaultCheckInTime) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "hotelData", "CheckInTime", Undefined, Undefined, DefaultCheckInTime, vUUID);
	EndIf;
	
	If ValueIsFilled(DefaultCheckOutTime) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "hotelData", "CheckOutTime", Undefined, Undefined, DefaultCheckOutTime, vUUID);
	EndIf;

	If ValueIsFilled(HotelPhone) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "hotelData", "Phone", Undefined, Undefined, HotelPhone, vUUID);
	EndIf;

	If ValueIsFilled(HotelTimezone) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "hotelData", "Timezone", Undefined, Undefined, HotelTimezone, vUUID);
	EndIf;
	
	If ValueIsFilled(HotelEmail) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "hotelData", "Email", Undefined, Undefined, HotelEmail, vUUID);
	EndIf;


EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadHotelData()
	
	vHotelData = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "hotelData");
	
	If vHotelData.Count() > 0 Then
		If vHotelData.Columns.Find("CheckInTime") <> Undefined Then
			DefaultCheckInTime = vHotelData[0].CheckInTime;
		EndIf;
		If vHotelData.Columns.Find("CheckOutTime") <> Undefined Then
			DefaultCheckInTime = vHotelData[0].CheckOutTime;
		EndIf;
		If vHotelData.Columns.Find("Phone") <> Undefined Then
			HotelPhone = vHotelData[0].Phone;
		EndIf;
		If vHotelData.Columns.Find("Timezone") <> Undefined Then
			HotelTimezone = vHotelData[0].Timezone;
		EndIf;
		If vHotelData.Columns.Find("Email") <> Undefined Then
			HotelEmail = vHotelData[0].Email;
		EndIf;
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&Atserver
Function FillHotelPhonesChoiceList()
	
	Items.HotelPhone.ChoiceList.Clear();
	
	If ValueIsFilled(Hotel) Then
		vPhones = StrSplit(Hotel.Phones, ",");
		For Each vPhone In vPhones Do
			Items.HotelPhone.ChoiceList.Add(vPhone);	
		EndDo;
	EndIf;
	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function SetDefaultCheckTimes()
	
	If ValueIsFilled(Hotel) Then
		If ValueIsFilled(Hotel.RoomRate) Then
			DefaultCheckInTime 	= Hotel.RoomRate.DefaultCheckInTime;
			DefaultCheckOutTime = Hotel.RoomRate.DefaultCheckOutTime;
		EndIf;
	EndIf;
	
EndFunction

// -----------------------------------------------------------------------------
&AtClientAtServerNoContext
Function GetFormItemsColors()
	
	vResult = New Structure;
	
	vResult.Insert("Success", New Color(204, 255, 204));
	vResult.Insert("Failure", New Color(255, 204, 204));
                                  	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Function GetToolTipTextForCurrentPage(pCurrentPage)
		
	vToolTips = New Structure;
	vToolTips.Insert("SettingsPages_MainInfo", 			NStr("en = 'Connection settings'; de = 'Verbindungseinstellungen'; ru = 'Параметры подключения'"));
	vToolTips.Insert("SettingsPages_RoomTypes", 		NStr("en = 'Room types'; de = 'Zimmertypen'; ru = 'Типы номеров'"));
	vToolTips.Insert("SettingsPages_RoomRates", 		NStr("en = 'Room rates'; de = 'Zimmerpreise'; ru = 'Тарифы'"));
	vToolTips.Insert("SettingsPages_Statuses", 			NStr("en = 'Reservation statuses'; de = 'Reservierungsstatus'; ru = 'Статусы брони'"));
	vToolTips.Insert("SettingsPages_Agents", 			NStr("en = 'Agents'; de = 'Agenten'; ru = 'Агенты'"));
	vToolTips.Insert("SettingsPages_AgentsDataMapping", NStr("en = 'Agents data'; de = 'Agentendaten'; ru = 'Данные агентов'"));
	vToolTips.Insert("SettingsPages_HotelData",			NStr("en = 'Hotel info'; de = 'Hotelinformationen'; ru = 'Информация о гостинице'"));
	vToolTips.Insert("MainPages_View", 					NStr("en = 'Channel data view'; de = 'Kanaldatenansicht'; ru = 'Просмотр данных каналов'"));
	vToolTips.Insert("MainPages_ManualSync", 			NStr("en = 'Manual sync'; de = 'Manuelle Synchronisierung'; ru = 'Обмен данными вручную'"));
	vToolTips.Insert("MainPages_BackgroundJob", 		NStr("en = 'Automatic data sync'; de = 'Automatische Datensynchronisierung'; ru = 'Автоматический обмен данными'"));	

	vResult = "";
	
	If pCurrentPage.Name = "MainPages_Settings" Then		
		vCurrentPageName 	= Items.Settings_SettingsPages.CurrentPage.Name;
		vResult 			= vToolTips[vCurrentPageName];		
	Else	
		vResult 			= vToolTips[pCurrentPage.Name];
	EndIf;
	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
&AtClientAtServerNoContext
Function CheckServiceResult(pResult, pMessageIfSuccess = False)
		
	If pResult = Undefined Then
		tcCommonFunctionOnClientServer.TextMessage("Unknown error!");
		Return False;
	EndIf;
	
	If pResult.Success And pMessageIfSuccess Then
		tcCommonFunctionOnClientServer.TextMessage("Success");
		Return True;
	ElsIf Not pResult.Success Then 
		tcCommonFunctionOnClientServer.TextMessage("Failed to execute API function, error:" + chars.LF + pResult.Error);
		Return False;
	Else
		Return True;
	EndIf;
	
	Return False;

EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterAgentsData()
	
	If ValueIsFilled(Agent) Then
		Items.AgentsRoomRates.RowFilter	= New FixedStructure("Agent", Agent);
		Items.AgentsRoomTypes.RowFilter	= New FixedStructure("Agent", Agent);
	Else
		Items.AgentsRoomRates.RowFilter = New FixedStructure("Agent", Undefined);
		Items.AgentsRoomTypes.RowFilter = New FixedStructure("Agent", Undefined);	
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird In Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileFileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich In Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations In 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen In 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadFromFileInstallingFileSystemExtensionResult

// -----------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en = 'Selecting a file with reservations'; de = 'Auswählen einer Datei mit Vorbehalten'; ru = 'Выбор файла с бронями'");
	vFileOpen.Preview = False;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisForm));
EndProcedure // OpenFileDialogToChooseFile

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		LoadReservationsFromFile = pFileArray[0];
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// -----------------------------------------------------------------------------
&AtServer
Procedure SetupBackgroundJobChangesSyncSchedule_AtServer(pRead = False)
	If Not pRead Then 
		If Not CheckFilling() Then
			UseBackgroundJobChangesSync = False;
		EndIf;
	EndIf;
	
	Try
		vArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", DataProcessorChangesSync.Key));
		If vArrayScheduledJob.Count() > 0 Then
			vScheduledJob = vArrayScheduledJob[0];
			If pRead Then
				EmployeeChangesSync = cmGetEmployeeByUserName(vScheduledJob.UserName);
				ScheduleChangesSync = vScheduledJob.Schedule;
				UseBackgroundJobChangesSync = vScheduledJob.Use;	
			Else
				vUserNames = cmGetUserUUIDsByEmployee(EmployeeChangesSync);
				If vUserNames.Count() > 0 Then
					vUsrName = vUserNames[0].UserName;
				Else
					vMessage = NStr("en='The user of the information base was not found!';
									|ru='Пользователь информационной базы не найден!';
									|de='Der Benutzer der Informationsbasis wurde nicht gefunden!'");
					tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Endif;
				
				vScheduledJob.UserName = vUsrName;
				vScheduledJob.Schedule = ScheduleChangesSync;
				vScheduledJob.Use = UseBackgroundJobChangesSync;
			EndIf;
			
			If vScheduledJob.Parameters.Count() = 0 Then
				vScheduledJob.Parameters.Add(DataProcessorChangesSync.Key);
			EndIf;
		Else 	
			For Each vScheduledJobItem In Metadata.ScheduledJobs Do
				If vScheduledJobItem.Name = "RunDataProcessor" Then
					vScheduledJob = ScheduledJobs.CreateScheduledJob(vScheduledJobItem);
				EndIf;
			EndDo;
			
			vUserNames = cmGetUserUUIDsByEmployee(EmployeeChangesSync);
			If vUserNames.Count() > 0 Then
				vUsrName = vUserNames[0].UserName;
			Else
				vMessage = NStr("en='The user of the information base was not found!';
								|ru='Пользователь информационной базы не найден!';
								|de='Der Benutzer der Informationsbasis wurde nicht gefunden!'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
			Endif;
			
			vScheduledJob.Description = DataProcessorChangesSync.Description;
			vScheduledJob.Key = DataProcessorChangesSync.Key;
			vScheduledJob.Use = UseBackgroundJobChangesSync;
			vScheduledJob.UserName = vUsrName;
			vScheduledJob.RestartCountOnFailure = 0;
			vScheduledJob.RestartIntervalOnFailure = 0;
			
			If ScheduleChangesSync = Undefined or pRead Then
				ScheduleChangesSync = vScheduledJob.Schedule;
			Else
				vScheduledJob.Schedule = ScheduleChangesSync;
			EndIf;
			
			If vScheduledJob.Parameters.Count() = 0 Then
				vScheduledJob.Parameters.Add(DataProcessorChangesSync.Key);
			EndIf;
		EndIf;
		
		vScheduledJob.Write();
	Except	
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);	
	EndTry;
	
	If UseBackgroundJobChangesSync Then
		Items.Text_BackgroundJobInfo_ChangesSync.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
	Else 
		Items.Text_BackgroundJobInfo_ChangesSync.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
	EndIf;
EndProcedure // SetupBackgroundJobChangesSyncSchedule_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetupBackgroundJobFullSyncSchedule_AtServer(pRead = False)
	If Not pRead Then 
		If Not CheckFilling() Then
			UseBackgroundJobFullSync = False;
		EndIf;
	EndIf;
	
	Try
		vArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", DataProcessorFullSync.Key));
		If vArrayScheduledJob.Count() > 0 Then
			vScheduledJob = vArrayScheduledJob[0];
			If pRead Then
				EmployeeFullSync = cmGetEmployeeByUserName(vScheduledJob.UserName);
				ScheduleFullSync = vScheduledJob.Schedule;
				UseBackgroundJobFullSync = vScheduledJob.Use;	
			Else
				vUserNames = cmGetUserUUIDsByEmployee(EmployeeFullSync);
				If vUserNames.Count() > 0 Then
					vUsrName = vUserNames[0].UserName;
				Else
					vMessage = NStr("en='The user of the information base was not found!';
									|ru='Пользователь информационной базы не найден!';
									|de='Der Benutzer der Informationsbasis wurde nicht gefunden!'");
					tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Endif;
				
				vScheduledJob.UserName = vUsrName;
				vScheduledJob.Schedule = ScheduleFullSync;
				vScheduledJob.Use = UseBackgroundJobFullSync;
			EndIf;
			
			If vScheduledJob.Parameters.Count() = 0 Then
				vScheduledJob.Parameters.Add(DataProcessorFullSync.Key);
			EndIf;
		Else 	
			For Each vScheduledJobItem In Metadata.ScheduledJobs Do
				If vScheduledJobItem.Name = "RunDataProcessor" Then
					vScheduledJob = ScheduledJobs.CreateScheduledJob(vScheduledJobItem);
				EndIf;
			EndDo;
			
			vUserNames = cmGetUserUUIDsByEmployee(EmployeeFullSync);
			If vUserNames.Count() > 0 Then
				vUsrName = vUserNames[0].UserName;
			Else
				vMessage = NStr("en='The user of the information base was not found!';
								|ru='Пользователь информационной базы не найден!';
								|de='Der Benutzer der Informationsbasis wurde nicht gefunden!'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
			Endif;
			
			vScheduledJob.Description = DataProcessorFullSync.Description;
			vScheduledJob.Key = DataProcessorFullSync.Key;
			vScheduledJob.Use = UseBackgroundJobFullSync;
			vScheduledJob.UserName = vUsrName;
			vScheduledJob.RestartCountOnFailure = 0;
			vScheduledJob.RestartIntervalOnFailure = 0;
			
			If ScheduleFullSync = Undefined or pRead Then
				ScheduleFullSync = vScheduledJob.Schedule;
			Else
				vScheduledJob.Schedule = ScheduleFullSync;
			EndIf;
			
			If vScheduledJob.Parameters.Count() = 0 Then
				vScheduledJob.Parameters.Add(DataProcessorFullSync.Key);
			EndIf;
		EndIf;
		
		vScheduledJob.Write();
	Except	
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);	
	EndTry;
	
	If UseBackgroundJobFullSync Then
		Items.Text_BackgroundJobInfo_FullSync.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
	Else 
		Items.Text_BackgroundJobInfo_FullSync.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
	EndIf;
EndProcedure // SetupBackgroundJobFullSyncSchedule_AtServer

#EndRegion
