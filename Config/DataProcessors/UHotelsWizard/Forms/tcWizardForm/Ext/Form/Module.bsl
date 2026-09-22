
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
		vChangesSyncDPKey = "UHotelsCM_ChangesSync_" + TrimAll(vInteractionParameters.Code);
		vChangesSyncDPDescription = NStr("en='UHotels:CM changes synchronization and reservations import';
		                                 |ru='UHotels:CM синхронизация изменений и загрузка брони';
		                                 |de='UHotels:CM änderungen synchronisieren und Reservierungen laden'") + 
		                            " (" + TrimAll(vHotel) + ")";
		vFullSyncDPKey = "UHotelsCM_FullSync_" + TrimAll(vInteractionParameters.Code);
		vFullSyncDPDescription = NStr("en='UHotels:CM full synchronization';
		                              |ru='UHotels:CM полная синхронизация';
		                              |de='UHotels:CM vollständige Synchronisation'") + 
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
				vNewDP.Processing = "UHotelsWizard";
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
				vNewDP.Processing = "UHotelsWizard";
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
	GetMappingsAndLoadThem();
	
	If NOT ValueIsFilled(HTTPServer) Then
		// HTTPServer = "";
		HTTPUseSSL = True;
	EndIf;
	
	If NOT ValueIsFilled(HTTPAddress) Then
		// HTTPAddress = ""; 	
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

	CheckHotelUseRoomRateDailyPrices();
	
	Items.RoomRatesPriceTag.Visible = Object.UsePriceTags;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(Items.Group_MainPages.CurrentPage);
	
	FillToolTipSyncData();
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	
	If Debug Then
		Active = True;
	EndIf;
		
EndProcedure // DebugOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	
	If NOT Active Then
		Debug = False;
	EndIf;
	
EndProcedure // ActiveOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InteractionParametersOnChange(pItem)
	
	LoadInteractionParameters();
	LoadReservationStatuses();	
	GetMappingsAndLoadThem();
	
EndProcedure // InteractionParametersOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure Group_MainPagesOnCurrentPageChange(pItem, pCurrentPage)
	
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(pCurrentPage);
	
	If pCurrentPage.Name = "MainPages_ManualSync" Then
		UpdateCustomDataTables();
	EndIf;
	
EndProcedure // Group_MainPagesOnCurrentPageChange

// -----------------------------------------------------------------------------
&AtClient
Procedure Settings_SettingsPagesOnCurrentPageChange(pItem, pCurrentPage)
	
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(pCurrentPage);
	
EndProcedure // Settings_SettingsPagesOnCurrentPageChange

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

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	
	CheckHotelUseRoomRateDailyPrices();
	
EndProcedure // HotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BaseByGuestAmtAccommodationTemplateOnChange(pItem)
	
	If Items.BaseByGuestAmt.CurrentData <> Undefined Then
		If ValueIsFilled(Items.BaseByGuestAmt.CurrentData.AccommodationTemplate) Then
			Items.BaseByGuestAmt.CurrentData.GuestAmount = BaseByGuestAmtAccommodationTemplateOnChange_AtServer(Items.BaseByGuestAmt.CurrentData.AccommodationTemplate);
		EndIf;
	EndIf;
	
EndProcedure // BaseByGuestAmtAccommodationTemplateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure UsePriceTagsOnChange(pItem)
	Items.RoomRatesPriceTag.Visible = Object.UsePriceTags;
	If Object.UsePriceTags = False Then
		For Each vRoomRateRow In RoomRates Do
			vRoomRateRow.PriceTag = PredefinedValue("Catalog.PriceTags.EmptyRef");;
		EndDo;
	EndIf;	
		
EndProcedure // UsePriceTagsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AmountOfDaysToUpdateOnChange(pItem)
	FillToolTipSyncData();
EndProcedure // AmountOfDaysToUpdateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectAllRoomTypes(pCommand)
	For Each Id In CustomRoomTypes Do
	   Id.Check = True;
	EndDo;
EndProcedure // SelectAllRoomTypes

// -----------------------------------------------------------------------------
&AtClient
Procedure DeselectAllRoomTypes(pCommand)
	For Each Id In CustomRoomTypes Do
	   Id.Check = False;
	EndDo;
EndProcedure // DeselectAllRoomTypes

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectAllRoomRates(pCommand)
	For Each Id In CustomRoomRates Do
	   Id.Check = True;
	EndDo;
EndProcedure // SelectAllRoomRates

// -----------------------------------------------------------------------------
&AtClient
Procedure DeselectAllRoomRates(pCommand)
	For Each Id In CustomRoomRates Do
	   Id.Check = False;
	EndDo;
EndProcedure // DeselectAllRoomRates

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesOnActivateRow(pItem)
	If pItem.CurrentData <> Undefined Then
		vPricingType = pItem.CurrentData.PricingType;
		If ValueIsFilled(vPricingType) Then
			vDescr = GetPricingTypeDescription(vPricingType);
			Items.ServicesService.TypeRestriction = vDescr;
		EndIF;
	EndIf;
EndProcedure // ServicesOnActivateRow

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ConnectionTest(pCommand)
	
	If Save_AtServer() Then
		GetMappingsAndLoadThem();
	EndIf;
	
EndProcedure // ConnectionTest

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	
	Save_AtServer();
	
EndProcedure // Save

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

// -----------------------------------------------------------------------------
&AtClient
Procedure ReloadData(pCommand)
	
	If Save_AtServer() Then
		GetMappingsAndLoadThem();
	EndIf;
	
EndProcedure // ReloadData

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateRestrictions(pCommand)
	
	UpdateRestrictions_AtServer();
	
EndProcedure // UpdateRestrictions

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdatePrices(pCommand)
	
	UpdatePrices_AtServer();
	
EndProcedure // UpdatePrices

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateAvailability(pCommand)
	
	UpdateAvailability_AtServer()
	
EndProcedure //UpdateAvailability

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomUpdatePrices(pCommand)
	
	CustomUpdatePrices_AtServer();
	
EndProcedure // CustomUpdatePrices

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomUpdateAvailability(pCommand)
	
	CustomUpdateAvailability_AtServer();
	
EndProcedure // CustomUpdateAvailability

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomUpdateRestrictions(pCommand)
	
	CustomUpdateRestrictions_AtServer();
	
EndProcedure // CustomUpdateRestrictions

// -----------------------------------------------------------------------------
&AtClient
Procedure GetReservations(pCommand)
	GetReservations_AtServer();
EndProcedure // GetReservations

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
Procedure UpdateAvailability_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) AND ValueIsFilled(Object.HotelCode) Then
		vResult = UHotels.SendAvailability(Object.InteractionParameters, Object.HotelCode, , , Object.AmountOfDaysToUpdate, NOT SyncChangesOnly, , , , , Object.GetVacantRoomsAtMidnight);
		If NOT vResult.Success Then
			tcCommonFunctionOnClientServer.TextMessage("Failed to send availability: " + vResult.Error);
		EndIf;
	EndIf;
	
EndProcedure // UpdateAvailability_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdatePrices_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) AND ValueIsFilled(Object.HotelCode) Then
		vResult = UHotels.SendPrices(Object.InteractionParameters, Object.HotelCode, , , Object.AmountOfDaysToUpdate, NOT SyncChangesOnly, False,,,,,,Object.UsePriceTags);
		If NOT vResult.Success Then
			tcCommonFunctionOnClientServer.TextMessage("Failed to send prices: " + vResult.Error);
		EndIf;
	EndIf;
	
EndProcedure // UpdatePrices_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateRestrictions_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) AND ValueIsFilled(Object.HotelCode) Then
		vResult = UHotels.SendRestrictions(Object.InteractionParameters, Object.HotelCode, , , Object.AmountOfDaysToUpdate, NOT SyncChangesOnly);	
		If NOT vResult.Success Then
			tcCommonFunctionOnClientServer.TextMessage("Failed to send restrictions: " + vResult.Error);
		EndIf;
	EndIf;
	
EndProcedure // UpdateRestrictions_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CustomUpdateAvailability_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) AND ValueIsFilled(Object.HotelCode) Then
		If NOT (ValueIsFilled(DataSyncPeriod.StartDate) AND ValueIsFilled(DataSyncPeriod.EndDate)) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill data sync period!'; de = 'Fill data sync period!'; ru = 'Заполните период выгрузки данных!'"));
			Return;
		EndIf;
		
		vRoomTypes = New Array;
		For Each vRow in CustomRoomTypes Do
			If vRow.Check Then
				vRoomTypes.Add(vRow.Value);
			EndIf;
		EndDo;
		
		If vRoomTypes.Count() = 0 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Choose room types for sync!'; de = 'Choose room types for sync!'; ru = 'Выберите типы номеров для выгрузки!'"));
			Return;	
		EndIf;
		
		vResult = UHotels.SendAvailability(Object.InteractionParameters, Object.HotelCode, , , Object.AmountOfDaysToUpdate, NOT CustomSyncChangesOnly,, DataSyncPeriod.StartDate, DataSyncPeriod.EndDate, vRoomTypes, Object.GetVacantRoomsAtMidnight);
		If NOT vResult.Success Then
			tcCommonFunctionOnClientServer.TextMessage("Failed to send availability: " + vResult.Error);
		EndIf;
	EndIf;

EndProcedure // CustomUpdateAvailability_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CustomUpdatePrices_AtServer()
	
	Save_AtServer();
	
	If ValueIsFilled(Object.InteractionParameters) AND ValueIsFilled(Object.HotelCode) Then
		
		If NOT (ValueIsFilled(DataSyncPeriod.StartDate) AND ValueIsFilled(DataSyncPeriod.EndDate)) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill data sync period!'; de = 'Fill data sync period!'; ru = 'Заполните период выгрузки данных!'"));
			Return;
		EndIf;
		
		vRoomTypes = New Array;
		For Each vRow in CustomRoomTypes Do
			If vRow.Check Then
				vRoomTypes.Add(vRow.Value);
			EndIf;
		EndDo;
		
		If vRoomTypes.Count() = 0 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Choose room types for sync!'; de = 'Choose room types for sync!'; ru = 'Выберите типы номеров для выгрузки!'"));
			Return;	
		EndIf;

		vRoomRates = New Array;
		For Each vRow in CustomRoomRates Do
			If vRow.Check Then
				vRoomRates.Add(vRow.Value);
			EndIf;
		EndDo;
		
		If vRoomRates.Count() = 0 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Choose room rates for sync!'; de = 'Choose room rates for sync!'; ru = 'Выберите тарифы для выгрузки!'"));
			Return;	
		EndIf;
		
		vResult = UHotels.SendPrices(Object.InteractionParameters, Object.HotelCode, , , Object.AmountOfDaysToUpdate, NOT CustomSyncChangesOnly, False,, DataSyncPeriod.StartDate, DataSyncPeriod.EndDate, vRoomTypes, vRoomRates, Object.UsePriceTags);
		If NOT vResult.Success Then
			tcCommonFunctionOnClientServer.TextMessage("Failed to send prices: " + vResult.Error);
		EndIf;
	EndIf;

EndProcedure // CustomUpdatePrices_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CustomUpdateRestrictions_AtServer()
	
	Save_AtServer();
	
	If ValueIsFilled(Object.InteractionParameters) AND ValueIsFilled(Object.HotelCode) Then
		
		If NOT (ValueIsFilled(DataSyncPeriod.StartDate) AND ValueIsFilled(DataSyncPeriod.EndDate)) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill data sync period!'; de = 'Fill data sync period!'; ru = 'Заполните период выгрузки данных!'"));
			Return;
		EndIf;
		
		vRoomTypes = New Array;
		For Each vRow in CustomRoomTypes Do
			If vRow.Check Then
				vRoomTypes.Add(vRow.Value);
			EndIf;
		EndDo;
		
		If vRoomTypes.Count() = 0 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Choose room types for sync!'; de = 'Choose room types for sync!'; ru = 'Выберите типы номеров для выгрузки!'"));
			Return;	
		EndIf;

		vRoomRates = New Array;
		For Each vRow in CustomRoomRates Do
			If vRow.Check Then
				vRoomRates.Add(vRow.Value);
			EndIf;
		EndDo;
		
		If vRoomRates.Count() = 0 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Choose room rates for sync!'; de = 'Choose room rates for sync!'; ru = 'Выберите тарифы для выгрузки!'"));
			Return;	
		EndIf;

		vResult = UHotels.SendRestrictions(Object.InteractionParameters, Object.HotelCode, , , Object.AmountOfDaysToUpdate, NOT CustomSyncChangesOnly,, DataSyncPeriod.StartDate, DataSyncPeriod.EndDate, vRoomTypes, vRoomRates);	
		If NOT vResult.Success Then
			tcCommonFunctionOnClientServer.TextMessage("Failed to send restrictions: " + vResult.Error);
		EndIf;
	EndIf;

EndProcedure // CustomUpdateRestrictions_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GetReservations_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) AND ValueIsFilled(Object.HotelCode) Then
	 	vResult = UHotels.GetReservations(Object.InteractionParameters, Object.HotelCode, , , False, , Object.GetPrices, , Object.ReceiveBonusPayments);
		If NOT vResult.Success Then
			tcCommonFunctionOnClientServer.TextMessage("Failed to get reservations: " + vResult.Error);
		EndIf;
	EndIf;
	
EndProcedure // GetReservations_AtServer

// -----------------------------------------------------------------------------
&AtServer
Function BaseByGuestAmtAccommodationTemplateOnChange_AtServer(pAccTemplate)
	
	Return pAccTemplate.NumberOfAdults + pAccTemplate.NumberOfTeenagers + pAccTemplate.NumberOfChildren + pAccTemplate.NumberOfInfants;
	
EndFunction // BaseByGuestAmtAccommodationTemplateOnChange_AtServer

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
		SaveRoomRatesTable();
		SaveRoomsTable();
		SaveServicesTable();
		SaveAccommodationTable();
		SaveSourcesTable();
		SaveGuaranteeTypes();
		SavePaymentMethodsTable();
		SaveAllotment();
		SaveCurrenciesTable();
		SaveMarketingAndSource();
		SaveApiVersion();
		SaveDiscounts();
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
	Except
		RollbackTransaction();
		vError = cmGetRootErrorDescription(ErrorInfo());
		tcCommonFunctionOnClientServer.TextMessage(vError);

		Return False;
	EndTry;
	
	Return True;
EndFunction // Save_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveApiVersion()
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "Version");
	If Not IsBlankString(Version) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "Version", "Api_Version", Version, Undefined, Undefined);
	EndIf;
EndProcedure // SaveApiVersion

// -----------------------------------------------------------------------------
&AtServer
Procedure GetMappingsAndLoadThem()
			
	If ValueIsFilled(Object.InteractionParameters) AND ValueIsFilled(Object.HotelCode) Then
		
		vHotelData 	= UHotels.GetHotelData(Object.InteractionParameters, Object.HotelCode);			
		If vHotelData.Success AND vHotelData.Result <> Undefined Then
			// Clear tables
			RoomTypes.Clear();
			RoomRates.Clear();
			Services.Clear();
			GuaranteeTypes.Clear();
			Sources.Clear();
			PaymentMethods.Clear();
			BaseByGuestAmt.Clear();
			AdditionalGuestAmount.Clear();
			Currencies.Clear();
			DiscountsList.Clear();
			
			// Get room stays
			vRoomStays 		= vHotelData.Result.Get("RoomStays");
			If vRoomStays = Undefined Then
				Return;
			EndIf;
			vRoomStayArray 	= PropertyToArray(vRoomStays.Get("RoomStay"));			
			For Each vRoomStay in vRoomStayArray Do
				// Room types
				vRoomTypes		= vRoomStay.Get("RoomTypes");
				If vRoomTypes <> Undefined Then
	                vRoomTypeArray	= PropertyToArray(vRoomTypes.Get("RoomType"));
					For Each vRoomType in vRoomTypeArray Do
						vRoomDescriptionMap = vRoomType.Get("RoomDescription");
						
						vNewRow 		= RoomTypes.Add();
						vNewRow.ID		= Format(vRoomType.Get("RoomTypeCode"), "NG=");			
						vNewRow.Name 	= vRoomDescriptionMap.Get("Name");
					EndDo;
				EndIf;
				// Room rates
				vRatePlans		= vRoomStay.Get("RatePlans");
				If vRatePlans <> Undefined Then
	                vRoomPlanArray	= PropertyToArray(vRatePlans.Get("RatePlan"));
					For Each vRatePlan in vRoomPlanArray Do
						vRoomDescriptionMap = vRatePlan.Get("RatePlanDescription");
						
						vNewRow 		= RoomRates.Add();
						vNewRow.ID		= Format(vRatePlan.Get("RatePlanCode"), "NG=");			
						vNewRow.Name 	= vRoomDescriptionMap.Get("Name");
					EndDo;
				EndIf;
				
				// Guarantee types
				vGuarantees		= vRoomStay.Get("Guarantee");
				If vGuarantees <> Undefined Then
	                vGuaranteeArray	= PropertyToArray(vGuarantees);
					For Each vGuarantee in vGuaranteeArray Do
						vGuaranteeID		= "ID";
						vGuaranteeName		= "Unknown";
						vGuaranteeComments 	= vGuarantee.Get("Comments");
						vCommentArray 		= PropertyToArray(vGuaranteeComments.Get("Comment"));
						For Each vComment in vCommentArray Do
							vCommentName = vComment.Get("Name");
							If vCommentName = "PaymentSystemName" Then
								vCommentText	= vComment.Get("Text");
								vGuaranteeID 	= vCommentText.Get("__TextValue");
							ElsIf vCommentName = "PaymentSystemTitle" Then
								vCommentText	= vComment.Get("Text");
								vGuaranteeName 	= vCommentText.Get("__TextValue"); 
							EndIf;
						EndDo;
						vNewRow 		= PaymentMethods.Add();
						vNewRow.ID		= vGuaranteeID;			
						vNewRow.Name 	= vGuaranteeName;
					EndDo;
					If Object.ReceiveBonusPayments And PaymentMethods.FindRows(New Structure("id", "loyalty")).Count() = 0 Then
						vNewRow 		= PaymentMethods.Add();
						vNewRow.ID		= "loyalty";			
						vNewRow.Name 	= NStr("en = 'Payment of bonuses to the channel manager'; de = 'Auszahlung von Boni an den Channel Manager'; ru = 'Оплата бонусами ченнел менеджеру'");
					EndIf;
				EndIf;
			EndDo;
			// Services
			vServices		=  vHotelData.Result.Get("Services");
			If vServices <> Undefined Then
                vServiceArray	= PropertyToArray(vServices.Get("Service"));
				For Each vService in vServiceArray Do
					If vService = Undefined Then
						Continue;
					EndIf;
					vServiceName		= "Unknown";
					vServiceDetails 	= vService.Get("ServiceDetails");
					vServicePricingType = vService.Get("ServicePricingType");
					vServiceComments 	= vServiceDetails.Get("Comments");
					vCommentArray 		= PropertyToArray(vServiceComments.Get("Comment"));
					For Each vComment in vCommentArray Do
						vCommentName = vComment.Get("Name");
						If vCommentName = "ServiceName" Then
							vCommentText	= vComment.Get("Text");
							vServiceName 	= vCommentText.Get("__TextValue");
						EndIf;
					EndDo;
					vNewRow 			= Services.Add();
					vNewRow.ID			= vService.Get("ServiceInventoryCode");			
					vNewRow.Name 		= vServiceName;
					vServicePricingType = StrReplace((Title(vServicePricingType)), " ", "");
					vNewRow.PricingType = Enums.TLPricingTypes[vServicePricingType];
				EndDo;
			EndIf;
			
			// Discounts
			vDiscounts		=  vHotelData.Result.Get("Discounts");
			If vDiscounts <> Undefined Then
                vDiscountsArray	= PropertyToArray(vDiscounts.Get("Discount"));
				For Each vDiscount in vDiscountsArray Do
					If vDiscount = Undefined Then
						Continue;
					EndIf;
					vDiscountCode	 	= vDiscount.Get("Code");
					vDiscountName		= vDiscount.Get("Name");

					vNewRow 			= DiscountsList.Add();
					vNewRow.ID			= vDiscountCode;
					vNewRow.Name 		= vDiscountName;
				EndDo;
			EndIf;
			
			// Load mapped settings
			LoadRoomsTable();
			LoadRoomRatesTable();
			LoadServicesTable();;
			LoadPaymentMethodsTable();
			LoadAllotment();
			LoadAccommodationTable();
			LoadDiscounts();
			
			vVersion = UHotels.Version(Object.InteractionParameters);
			Version = Items.Version.ChoiceList.FindByValue(vVersion);
		Else
			tcCommonFunctionOnClientServer.TextMessage("Failed to get hotel data from UHotels: " + vHotelData.Error);
			Return;
		EndIf;
	Else
		vVersion = UHotels.Version();
		Version = Items.Version.ChoiceList.FindByValue(vVersion);
	EndIf;
	// Hardcoded data because no API to get such data
	LoadReservationStatuses();
	LoadCurrenciesTable();
	
	FillGuaranteeTypes();
	LoadGuaranteeTypes();
	
	FillSources();
	LoadSourcesTable();
	
	LoadMarketingAndSource();
EndProcedure // GetMappingsAndLoadThem

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveAccommodationTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "BaseByGuestAmt");
	
	For Each vBaseByGuestAmtRow in BaseByGuestAmt Do
		If ValueIsFilled(vBaseByGuestAmtRow.AccommodationTemplate)Then
			vID = String(New UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "BaseByGuestAmt", "GuestAmount", vBaseByGuestAmtRow.AccommodationTemplate, Undefined, vBaseByGuestAmtRow.GuestAmount, vID);
		EndIf;
	EndDo;
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "AdditionalGuestAmount");
	
	For Each vAdditionalGuestAmountRow in AdditionalGuestAmount Do
		If ValueIsFilled(vAdditionalGuestAmountRow.AccommodationType)Then
			vID = String(New UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "AdditionalGuestAmount", "isBaseBedAmount", 		vAdditionalGuestAmountRow.AccommodationType, Undefined, vAdditionalGuestAmountRow.isBaseBedAmount, 		vID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "AdditionalGuestAmount", "MinAge", 				vAdditionalGuestAmountRow.AccommodationType, Undefined, vAdditionalGuestAmountRow.MinAge, 				vID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "AdditionalGuestAmount", "MaxAge", 				vAdditionalGuestAmountRow.AccommodationType, Undefined, vAdditionalGuestAmountRow.MaxAge, 				vID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "AdditionalGuestAmount", "MaxAdditionalGuests", 	vAdditionalGuestAmountRow.AccommodationType, Undefined, vAdditionalGuestAmountRow.MaxAdditionalGuests, 	vID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "AdditionalGuestAmount", "isBedRequired", 		vAdditionalGuestAmountRow.AccommodationType, Undefined, vAdditionalGuestAmountRow.isBedRequired, 		vID);
		EndIf;
	EndDo;

EndProcedure // SaveAccommodationTable

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadAccommodationTable()
	
	vBaseByGuestAmt = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "BaseByGuestAmt");
	
	For Each vRow in vBaseByGuestAmt Do
		vNewRow = BaseByGuestAmt.Add();
		FillPropertyValues(vNewRow, vRow);
		vNewRow.AccommodationTemplate = vRow.RefKey1;
	EndDo;

	vAdditionalGuestAmount = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "AdditionalGuestAmount");
	
	For Each vRow in vAdditionalGuestAmount Do
		vNewRow = AdditionalGuestAmount.Add();
		FillPropertyValues(vNewRow, vRow);
		vNewRow.AccommodationType = vRow.RefKey1;
	EndDo;
	
EndProcedure // LoadAccommodationTable

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveRoomRatesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "roomrates");
	
	For Each vRoomRateRow in RoomRates Do
		If ValueIsFilled(vRoomRateRow.RoomRate) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "id", 	  vRoomRateRow.RoomRate, vRoomRateRow.PriceTag, vRoomRateRow.id, 	 vRoomRateRow.id);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "name",   vRoomRateRow.RoomRate, vRoomRateRow.PriceTag, vRoomRateRow.name,   vRoomRateRow.id);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "Unload", vRoomRateRow.RoomRate, vRoomRateRow.PriceTag, vRoomRateRow.Unload, vRoomRateRow.id);
		EndIf;
	EndDo;
	
EndProcedure // SaveRoomRatesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadRoomRatesTable()
	
	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "roomrates");
	
	If vRoomRates.Count() > 0 Then		
		For Each vRoomRateRow in vRoomRates Do
			For Each vLoadedRoomRateRow in RoomRates Do
				If vRoomRateRow.id = vLoadedRoomRateRow.id Then 
					vLoadedRoomRateRow.RoomRate = vRoomRateRow.RefKey1;
					If Object.UsePriceTags Then
						vLoadedRoomRateRow.PriceTag = vRoomRateRow.RefKey2;
					Else
						vLoadedRoomRateRow.PriceTag = Catalogs.PriceTags.EmptyRef();
					EndIf;
					If vRoomRates.Columns.Find("Unload") = Undefined Or vRoomRateRow.Unload = Undefined Then
						vLoadedRoomRateRow.Unload = True;
					Else	
						vLoadedRoomRateRow.Unload = vRoomRateRow.Unload;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
		RoomRates.Sort("RoomRate DESC, id");
	EndIf;
	
EndProcedure // LoadRoomRatesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveRoomsTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "roomtypes");
			
	For Each vRoomTypeRow in RoomTypes Do
		If ValueIsFilled(vRoomTypeRow.RoomType) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "id", 		vRoomTypeRow.RoomType, Undefined, vRoomTypeRow.id, 		vRoomTypeRow.id);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "Name", 	vRoomTypeRow.RoomType, Undefined, vRoomTypeRow.Name, 	vRoomTypeRow.id);					
		EndIf;
	EndDo;

EndProcedure // SaveRoomsTable

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadRoomsTable()
	
	vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "roomtypes");
	
	Try
		If vRoomTypes.Count() > 0 Then			
			For Each vRoomTypeRow in vRoomTypes Do
				For Each vLoadedRoomTypeRow in RoomTypes Do
					If vRoomTypeRow.id = vLoadedRoomTypeRow.id Then 
						vLoadedRoomTypeRow.RoomType = vRoomTypeRow.RefKey1;
					EndIf;
				EndDo;
			EndDo;
		EndIf;

		RoomTypes.Sort("RoomType DESC, id");
	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load room types mappings!");
	EndTry;
	
EndProcedure // LoadRoomsTable

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveServicesTable()
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "services");
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "servicepackages");
	
	For Each vServiceRow in Services Do
		If ValueIsFilled(vServiceRow.Service) Then
			If TypeOf(vServiceRow.Service) = Type("CatalogRef.Services") Then
				InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "services", "id", vServiceRow.Service, Undefined, vServiceRow.id, 		vServiceRow.id);
				InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "services", "name", vServiceRow.Service, Undefined, vServiceRow.name, 		vServiceRow.id);
				InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "services", "PricingType", vServiceRow.Service, Undefined, vServiceRow.PricingType, 	vServiceRow.id); 
			ElsIf TypeOf(vServiceRow.Service) = Type("CatalogRef.ServicePackages") Then
				InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "servicepackages", "id", vServiceRow.Service, Undefined, vServiceRow.id, vServiceRow.id);
				InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "servicepackages", "name", vServiceRow.Service, Undefined, vServiceRow.name, vServiceRow.id);
				InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "servicepackages", "PricingType", vServiceRow.Service, Undefined, vServiceRow.PricingType, vServiceRow.id); 
			EndIf;
		EndIf;
	EndDo;
EndProcedure // SaveServicesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadServicesTable()
	vServices = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "services");
	For Each vServiceRow in vServices Do
		For Each vLoadedServiceRow in Services Do
			If vServiceRow.id = vLoadedServiceRow.id Then 
				vLoadedServiceRow.Service = vServiceRow.RefKey1;
			EndIf;
		EndDo;
	EndDo;
	
	vServicePackages = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "servicepackages");
	For Each vServicePackagesRow in vServicePackages Do
		For Each vLoadedServiceRow in Services Do
			If vServicePackagesRow.id = vLoadedServiceRow.id Then 
				vLoadedServiceRow.Service = vServicePackagesRow.RefKey1;
			EndIf;
		EndDo;
	EndDo;
EndProcedure // LoadServicesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveReservationStatuses()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "reservationstatuses");

	If ValueIsFilled(ReservationStatus_Confirmed) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_Confirmed, Undefined, "Confirmed", "Confirmed");
	EndIf;
	
	If ValueIsFilled(ReservationStatus_Cancel) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_Cancel, Undefined, "Cancelled", "Cancelled");
	EndIf;

	If ValueIsFilled(ReservationStatus_Unconfirmed) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_Unconfirmed, Undefined, "Unconfirmed", "Unconfirmed");
	EndIf;

	If ValueIsFilled(ReservationStatus_Released) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_Released, Undefined, "Released", "Released");
	EndIf;

	If ValueIsFilled(ReservationStatus_Pending) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_Pending, Undefined, "Pending", "Pending");
	EndIf;

EndProcedure // SaveReservationStatuses

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadReservationStatuses()
	
	vReservationStatuses = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "reservationstatuses");
	
	If vReservationStatuses.Columns.Find("ID") <> Undefined AND vReservationStatuses.Count() > 0 Then
		For Each vReservationStatus in vReservationStatuses Do
			If vReservationStatus.ID = "Confirmed" Then
				ReservationStatus_Confirmed = vReservationStatus.RefKey1;
			ElsIf vReservationStatus.ID = "Cancelled" Then
				ReservationStatus_Cancel = vReservationStatus.RefKey1;
			ElsIf vReservationStatus.ID = "Unconfirmed" Then
				ReservationStatus_Unconfirmed = vReservationStatus.RefKey1;
			ElsIf vReservationStatus.ID = "Released" Then
				ReservationStatus_Released = vReservationStatus.RefKey1;
			ElsIf vReservationStatus.ID = "Pending" Then
				ReservationStatus_Pending = vReservationStatus.RefKey1;
			EndIf;
		EndDo;
	EndIf;

EndProcedure // LoadReservationStatuses

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
	vIntParObj.IsActive = Active;
	vIntParObj.DebugMode = Debug;
	vIntParObj.HttpAddress = HTTPAddress;
	vIntParObj.HttpUseSsl = HTTPUseSSL;
	vIntParObj.ClientType = ClientType;
	vIntParObj.Currency = Currency;
	vIntParObj.ConvertCurrency = ConvertCurrency;
	vIntParObj.UseClient = UseClient;
	vIntParObj.Allotment = Undefined;
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
	vIntParObj.DataProcessor = Object.DataProcessor;
	vIntParObj.Write();
	
	LastExportTimestampForInventoryWasChanged = False;
	LastExportTimestampForPricesWasChanged = False;
	LastExportTimestampForRestrictionsWasChanged = False;
EndProcedure // SaveInteractionParameters

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
	Active = vIP.IsActive;
	Debug = vIP.DebugMode;
	HTTPAddress = vIP.HttpAddress;
	HTTPUseSSL = vIP.HttpUseSsl;
	ClientType = vIP.ClientType;
	Currency = vIP.Currency;
	ConvertCurrency = vIP.ConvertCurrency;
	UseClient = vIP.UseClient;
	MaxLogLenght = vIP.MaxLogLenght;

	LastFullSynchronizationTime = vIP.LastFullSynchronizationTime;
	
	LastExportTimestampForInventory = vIP.LastExportTimestampForInventory;
	LastExportTimestampForPrices = vIP.LastExportTimestampForPrices;
	LastExportTimestampForRestrictions = vIP.LastExportTimestampForRestrictions;
	
	IntegrationStatus = vIP.Status;
	
	LastExportTimestampForInventoryWasChanged = False;
	LastExportTimestampForPricesWasChanged = False;
	LastExportTimestampForRestrictionsWasChanged = False;
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadSourcesTable()
	vSources = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "sources");
	
	Try
		If vSources.Count() > 0 Then			
			For Each vSourceRow in vSources Do  
				vFilterRows = Sources.FindRows(New Structure("ID", vSourceRow.id));   
				vWasAdded = False;
				For Each vLoadedSourceRow in vFilterRows Do
					vLoadedSourceRow.Agent = vSourceRow.RefKey1;
					vWasAdded = True;
				EndDo;	
				If Not vWasAdded Then
					vNewRow 		= Sources.Add();
					vNewRow.id 		= vSourceRow.ID;
					vNewRow.Name 	= vSourceRow.Name;
					vNewRow.Agent 	= vSourceRow.RefKey1;
				EndIf;	
			EndDo;
		EndIf;

		Sources.Sort("Agent DESC, ID");
		
	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load sources mappings!");
	EndTry;
EndProcedure // LoadSourcesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveSourcesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "sources");
			
	For Each vSourceRow in Sources Do
		If ValueIsFilled(vSourceRow.Agent) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "sources", "ID", 	vSourceRow.Agent, Undefined, vSourceRow.ID, 		vSourceRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "sources", "Name", 	vSourceRow.Agent, Undefined, vSourceRow.Name, 		vSourceRow.ID);					
		EndIf;
	EndDo;

EndProcedure // SaveSourcesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadGuaranteeTypes()
	
	vGuarantees = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "guarantees");
	
	Try
		If vGuarantees.Count() > 0 Then			
			For Each vGuaranteeRow in vGuarantees Do
				For Each vLoadedGuaranteeRow in GuaranteeTypes Do
					If vGuaranteeRow.id = vLoadedGuaranteeRow.id Then 
						vLoadedGuaranteeRow.GuaranteeType = vGuaranteeRow.RefKey1;
					EndIf;
				EndDo;
			EndDo;
		EndIf;

		GuaranteeTypes.Sort("GuaranteeType DESC, ID");
		
	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load GuaranteeType mappings!");
	EndTry;
	
EndProcedure // LoadGuaranteeTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveGuaranteeTypes()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "guarantees");
			
	For Each vGuaranteeRow in GuaranteeTypes Do
		If ValueIsFilled(vGuaranteeRow.GuaranteeType) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "guarantees", "id", 		vGuaranteeRow.GuaranteeType, Undefined, vGuaranteeRow.ID, 		vGuaranteeRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "guarantees", "Name", 	vGuaranteeRow.GuaranteeType, Undefined, vGuaranteeRow.Name, 	vGuaranteeRow.ID);					
		EndIf;
	EndDo;

EndProcedure // SaveGuaranteeTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadPaymentMethodsTable()
	
	vPaymentMethods = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "paymentMethods");
	
	Try
		If vPaymentMethods.Count() > 0 Then						
			For Each vGuaranteeRow in vPaymentMethods Do
				For Each vLoadedPaymentMethodsRow in PaymentMethods Do
					If vGuaranteeRow.id = vLoadedPaymentMethodsRow.id Then 
						vLoadedPaymentMethodsRow.PaymentMethod = vGuaranteeRow.RefKey1;
					EndIf;
				EndDo;
			EndDo;
		EndIf;

		PaymentMethods.Sort("PaymentMethod DESC, ID");
		
	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load GuaranteeType mappings!");
	EndTry;
	
EndProcedure // LoadPaymentMethodsTable

// -----------------------------------------------------------------------------
&AtServer
Procedure SavePaymentMethodsTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "paymentMethods");
			
	For Each vPaymentMethod in PaymentMethods Do
		If ValueIsFilled(vPaymentMethod.PaymentMethod) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "paymentMethods", "id", 		vPaymentMethod.PaymentMethod, Undefined, vPaymentMethod.ID, 		vPaymentMethod.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "paymentMethods", "Name", 	vPaymentMethod.PaymentMethod, Undefined, vPaymentMethod.Name, 		vPaymentMethod.ID);					
		EndIf;
	EndDo;

EndProcedure // SavePaymentMethodsTable

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveAllotment()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "allotments");
	
	For Each vRow in Allotments Do
		If ValueIsFilled(vRow.Allotment) AND ValueIsFilled(vRow.id) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "allotments", "ID", vRow.Allotment, Undefined, vRow.id, vRow.id);
		EndIf;
	EndDo;
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "DefaultAllotment");

	InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "DefaultAllotment", "Use", Allotment, Undefined, DoNotUseDefaultAllotment, "Use");	
	
EndProcedure // SaveAllotment

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadAllotment()
	
	vAllotments = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "allotments");
	
	Try
		If vAllotments.Count() > 0 Then			
			For Each vAllotmentRow in vAllotments Do
				vNewRow				= Allotments.Add();
				vNewRow.Allotment 	= vAllotmentRow.RefKey1;
				vNewRow.id 			= vAllotmentRow.id;
			EndDo;
		EndIf;
		
		vDefaultAllotment = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "DefaultAllotment");
		
		If vDefaultAllotment.Count() > 0 Then
			Allotment 					= vDefaultAllotment[0].RefKey1;
			DoNotUseDefaultAllotment 	= vDefaultAllotment[0].Use;
		EndIf;
		
	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load allotment mappings!");
	EndTry;
	
EndProcedure // LoadAllotment

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadDiscounts()
	
	vDiscounts = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "Discounts");
	
	Try
		For Each vDiscountRow In vDiscounts Do
			For Each vLoadedDiscountRow In DiscountsList Do
				If vDiscountRow.id = vLoadedDiscountRow.id Then
					vLoadedDiscountRow.Discount = vDiscountRow.RefKey1;
				EndIf;
			EndDo;
		EndDo;
	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load discounts mappings!");
	EndTry;
	
EndProcedure // LoadDiscounts

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveDiscounts()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "Discounts");
	
	For Each vRow in DiscountsList Do
		If ValueIsFilled(vRow.Discount) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "Discounts", "ID", vRow.Discount, Undefined, vRow.id, vRow.id);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "Discounts", "name", vRow.Discount, Undefined, vRow.name, vRow.name);
		EndIf;
	EndDo;
	
EndProcedure // SaveDiscounts

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadCurrenciesTable()
	
	vCurrencies = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "Currencies");
	
	Try
		If vCurrencies.Count() > 0 Then			
			For Each vCurrencyRow in vCurrencies Do
				vNewRow 			= Currencies.Add();
				vNewRow.name 		= vCurrencyRow.Name;
				vNewRow.id 			= vCurrencyRow.id;
				vNewRow.Currency 	= vCurrencyRow.RefKey1;
			EndDo;
		EndIf;
		
		If Currencies.Count() = 0 Then
			vNewRow 			= Currencies.Add();
			vNewRow.name 		= "Руб.";
			vNewRow.id 			= "RUB";
		EndIf;
		
	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load Currencies mappings!");
	EndTry;
	
EndProcedure // LoadCurrenciesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveCurrenciesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "Currencies");
			
	For Each vCurrencyRow in Currencies Do
		If ValueIsFilled(vCurrencyRow.Currency) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "Currencies", "id", 		vCurrencyRow.Currency, Undefined, vCurrencyRow.ID, 		vCurrencyRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "Currencies", "Name", 	vCurrencyRow.Currency, Undefined, vCurrencyRow.Name, 	vCurrencyRow.ID);					
		EndIf;
	EndDo;

EndProcedure // SaveCurrenciesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveMarketingAndSource()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "SourceOfBusiness");

	If ValueIsFilled(SourceOfBusiness) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "SourceOfBusiness", "ID", SourceOfBusiness, Undefined, "Default", "Default");
	EndIf;

	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "MarketingCode");

	If ValueIsFilled(MarketingCode) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "MarketingCode", "ID", MarketingCode, Undefined, "Default", "Default");
	EndIf;
	
EndProcedure // SaveMarketingAndSource

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadMarketingAndSource()
	
	vSourcesOfBusiness = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "SourceOfBusiness");
		
	For Each vSourceOfBusiness in vSourcesOfBusiness Do
		SourceOfBusiness = vSourceOfBusiness.RefKey1;
	EndDo;

	vMarketingCodes = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "MarketingCode");
		
	For Each vMarketingCode in vMarketingCodes Do
		MarketingCode = vMarketingCode.RefKey1;
	EndDo;
	
EndProcedure // LoadMarketingAndSource

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateCustomDataTables()
	
	CustomRoomRates.Clear();
	For Each vRoomRate in RoomRates Do
		If CustomRoomRates.FindByValue(vRoomRate.RoomRate) = Undefined And ValueIsFilled(vRoomRate.RoomRate) Then
			CustomRoomRates.Add(vRoomRate.RoomRate);
		EndIf;
	EndDo;
	
	CustomRoomTypes.Clear();
	For Each vRoomType in RoomTypes Do
		If CustomRoomTypes.FindByValue(vRoomType.RoomType) = Undefined And ValueIsFilled(vRoomType.RoomType) Then
			CustomRoomTypes.Add(vRoomType.RoomType);
		EndIf;
	EndDo;
	
EndProcedure // UpdateCustomDataTables

// -----------------------------------------------------------------------------
&AtServer
Procedure FillGuaranteeTypes()

	vNewRow = GuaranteeTypes.Add();
	vNewRow.id 		= "PayOnArrival";
	vNewRow.Name 	= "Гарантии нет, гость платит при заселении в гостиницу";

	vNewRow = GuaranteeTypes.Add();
	vNewRow.id 		= "CcDcVoucher";
	vNewRow.Name 	= "Гарантия кредитной картой";
	
	vNewRow = GuaranteeTypes.Add();
	vNewRow.id 		= "PrePay";
	vNewRow.Name 	= "Есть предоплата";

EndProcedure // FillGuaranteeTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure FillSources()
	vObj 					= FormAttributeToValue("Object");
	vChannelCodesTemplate 	= vObj.GetTemplate("ChannelsCodes");
	vDataArea				= vChannelCodesTemplate.GetArea("Channels");
	
	vCurrentRow = 1;
	vName 		= vDataArea.GetArea("R" + Format(vCurrentRow,"NZ=0; NG=") + "C1").CurrentArea.Text;
	vCode 		= vDataArea.GetArea("R" + Format(vCurrentRow,"NZ=0; NG=") + "C2").CurrentArea.Text;	
	Items.SourcesID.ChoiceList.Clear();
	While vName <> "" Do	
		Items.SourcesID.ChoiceList.Add(New Structure("ID, Description", vCode, vName), vName);
		vCurrentRow = vCurrentRow + 1;
		vName 		= vDataArea.GetArea("R" + Format(vCurrentRow,"NZ=0; NG=") + "C1").CurrentArea.Text;
		vCode 		= vDataArea.GetArea("R" + Format(vCurrentRow,"NZ=0; NG=") + "C2").CurrentArea.Text;
	EndDo;
EndProcedure // FillSources

// -----------------------------------------------------------------------------
&AtServer
Function PropertyToArray(pValue)
	
	vResult  = New Array;
	
	If TypeOf(pValue) = Type("Array") Then
		vResult = pValue;
	Else
		vResult.Add(pValue);
	EndIf;
	
	Return vResult;
	
EndFunction // PropertyToArray

// -----------------------------------------------------------------------------
&AtClient
Function GetToolTipTextForCurrentPage(pCurrentPage)
		
	vToolTips = New Structure;
	vToolTips.Insert("SettingsPages_MainInfo", 			NStr("en = 'Basic exchange settings and connection parameters'; de = 'Grundlegende Austauscheinstellungen und Verbindungsparameter'; ru = 'Основные настройки обмена и параметры подключения'"));
	vToolTips.Insert("SettingsPages_RoomTypes", 		NStr("en = 'Room type mappings settings'; de = 'Raumtyp-Matching-Einstellungen'; ru = 'Настройки соответствия типов номеров'"));
	vToolTips.Insert("SettingsPages_RoomRates", 		NStr("en = 'Room rates mappings settings'; de = 'Zuordnungen der Zimmerpreiszuordnungen'; ru = 'Настройки соответствия тарифов'"));
	vToolTips.Insert("SettingsPages_Statuses", 			NStr("en = 'Reservation statuses mappings settings'; de = 'Zuordnungseinstellungen für Reservierungsstatus'; ru = 'Настройки соответствий статусов броней'"));
	vToolTips.Insert("MainPages_View", 					NStr("en = 'Channel data view tooltip'; de = 'Channel data view tooltip'; ru = 'Channel data view tooltip'"));
	vToolTips.Insert("MainPages_ManualSync", 			NStr("en = 'Managing manual data synchronization'; de = 'Manuelle Datensynchronisation verwalten'; ru = 'Управление ручной синхронизацией данных'"));
	vToolTips.Insert("MainPages_BackgroundJob", 		NStr("en = 'Background job settings'; de = 'Einstellungen für Hintergrundjobs'; ru = 'Настройки фонового задания'"));	
	vToolTips.Insert("SettingsPages_Services", 			NStr("en = 'Services mappings settings'; de = 'Einstellungen für Dienstzuordnungen'; ru = 'Настройки соответствия услуг'")); 
	vToolTips.Insert("SettingsPages_Accommodations", 	NStr("en = 'Accommodations mappings settings'; de = 'Einstellungen für die Zuordnung von Unterkünften'; ru = 'Настройки соответствия размещений'")); 
	vToolTips.Insert("SettingsPages_Agents", 			NStr("en = 'Agents mappings settings'; de = 'Einstellungen für Agentenzuordnungen'; ru = 'Настройки соответствия агентов'")); 
	vToolTips.Insert("SettingsPages_PaymentMethods", 	NStr("en = 'Payment methods mappings settings'; de = 'Zuordnungseinstellungen für Zahlungsmethoden'; ru = 'Настройки соответствия методов оплаты'")); 
	vToolTips.Insert("SettingsPages_GuaranteeTypes", 	NStr("en = 'Guarantee types mappings settings'; de = 'Garantietypen Zuordnungseinstellungen'; ru = 'Настройки соответствия видов гарантий'"));
	vToolTips.Insert("SettingsPages_Currencies", 		NStr("en = 'Currencies mappings settings'; de = 'Währungszuordnungseinstellungen'; ru = 'Настройки соответствия валют'"));
	vToolTips.Insert("SettingsPages_Allotments", 		NStr("en = 'Allotments mappings settings'; de = 'Einstellungen für Zuteilungszuordnungen'; ru = 'Настройки соответствия квот'"));
	vToolTips.Insert("SettingsPages_Discounts", 		NStr("en = 'Discounts mappings settings'; de = 'Einstellungen für Rabattzuordnungen'; ru = 'Настройки соответствия скидок'"));


	vResult = "";
	
	If pCurrentPage.Name = "MainPages_Settings" Then		
		vCurrentPageName 	= Items.Settings_SettingsPages.CurrentPage.Name;
		vResult 			= vToolTips[vCurrentPageName];		
	Else	
		vResult 			= vToolTips[pCurrentPage.Name];
	EndIf;
	
	Return vResult;
	
EndFunction // GetToolTipTextForCurrentPage

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction // IsInRoleAtServer

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
			
			vUserNames = cmGetUserUUIDsByEmployee(EmployeeChangesSync);
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

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckHotelUseRoomRateDailyPrices()

	If ValueIsFilled(Hotel) AND NOT Hotel.UseRoomRateDailyPrices Then
		Items.Hotel_UseRoomRateDailyPrices_Text.Visible = True;
	Else
		Items.Hotel_UseRoomRateDailyPrices_Text.Visible = False;	
	EndIf;
	
EndProcedure // CheckHotelUseRoomRateDailyPrices

// -----------------------------------------------------------------------------
&AtClient
Procedure FillToolTipSyncData()
	If Object.AmountOfDaysToUpdate > 0 Then
		vCurDate = GetCurrentSessionDate();
		vLastDayOfUnloading = vCurDate + (Object.AmountOfDaysToUpdate * 86400);  
		Items.ToolTipSyncData.Title = StrTemplate(NStr("en = 'Unload for %1 days (from %2 to %3)'; de = 'Entladen für %1 Tage (von %2 bis %3)'; ru = 'Выгрузка на %1 дней  (с %2 по %3)'"), Object.AmountOfDaysToUpdate, Format(vCurDate, "DF=dd.MM.yyyy"), Format(vLastDayOfUnloading, "DF=dd.MM.yyyy"));
	Else
		Items.ToolTipSyncData.Title = NStr("en = 'Data is synchronized from the current date for N days specified in the settings tab.'; de = 'Data is synchronized from the current date for N days specified in the settings tab.'; ru = 'Данные выгружаются с текущей даты на N дней, указанных на вкладке настроек.'");	
	EndIf;		
EndProcedure // FillToolTipSyncData

// -----------------------------------------------------------------------------
&AtServer
Function GetCurrentSessionDate()
	Return CurrentSessionDate();
EndFunction // GetCurrentSessionDate

// -----------------------------------------------------------------------------
&AtClient
Procedure SourcesIDChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If Not pSelectedValue = Undefined Then
		pStandardProcessing = False;
		vRow = Items.Sources.CurrentData;
		If Not vRow = Undefined Then
			vRow.id = pSelectedValue.ID;
			vRow.Name = pSelectedValue.Description;
		EndIf;	
	EndIf;	
EndProcedure // SourcesIDChoiceProcessing

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetPricingTypeDescription(pType)
	If pType = Enums.TLPricingTypes.PerNight Or
	   pType = Enums.TLPricingTypes.PerPersonPerNight Or 
	   pType = Enums.TLPricingTypes.PerOccupancyPerNight Then
		vDescr = New TypeDescription(); 		
	Else
		vDescr = New TypeDescription("CatalogRef.Services");			
	EndIf;
	
	Return vDescr;
EndFunction // GetTypeDescription

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

#EndRegion
