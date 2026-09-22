#Region FormEventHandlers

// ----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	Else
		vDataProcessor = Catalogs.DataProcessors.FindByAttribute("Processing","WebHotelierWizard");
		If vDataProcessor = Catalogs.DataProcessors.EmptyRef() Then
			vNewDP 				= Catalogs.DataProcessors.CreateItem();
			vNewDP.Description 	= "WebHotelier";
			vNewDP.Key 			= "WebHotelier";
			vNewDP.Processing 	= "WebHotelierWizard";
			vNewDP.Write();
			vDataProcessor = vNewDP.Ref;
		EndIf;
		
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");

	If Object.AmountOfDaysToUpdate <= 0 Then
		Object.AmountOfDaysToUpdate = 100;	
	EndIf;
	
	LoadInteractionParameters();
	LoadReservationStatuses();	
	GetMappingsAndLoadThem();
	
	If IsInRoleAtServer("Administrator") And vDataProcessor <> Undefined Then
		If IsBlankString(vDataProcessor.Key) Then
			dpObj = vDataProcessor.GetObject();
			dpObj.Key = "WebHotelier";
			dpObj.Write();
		EndIf;	
		SetupBackgroundJobSchedule_AtServer(True);
		
		If UseBackgroundJob Then
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
		Else 
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
		EndIf;
	Else
		Items.MainPages_BackgroundJob.Visible = False;
     	Items.SettingsPages_MainInfo.ReadOnly = True;
	EndIf;

	CheckHotelUseRoomRateDailyPrices();
	
EndProcedure

// ----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(Items.Group_MainPages.CurrentPage);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	
	CheckHotelUseRoomRateDailyPrices();
	
EndProcedure // HotelOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesRoomRateOnChange(pItem)
	
	If Items.RoomRates.CurrentData <> Undefined Then
		vAccommodationRows = Accommodations.FindRows(New Structure("id", RoomRateIdBuffer));
		If Not ValueIsFilled(Items.RoomRates.CurrentData.RoomRate) Then 
			For Each vRow In vAccommodationRows Do
				Accommodations.Delete(vRow);		
			EndDo;
		Else
			For Each vRow In vAccommodationRows Do
				vRow.RoomRate 	= Items.RoomRates.CurrentData.RoomRate;
				vRow.id 		= Items.RoomRates.CurrentData.id;
			EndDo;	
		EndIf;
	EndIf;
	
EndProcedure // RoomRatesRoomRateOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesRoomRateClearing(pItem, pStandardProcessing)
	
	vAccommodationRows = Accommodations.FindRows(New FixedStructure("id", RoomRateIdBuffer));
	For Each vRow In vAccommodationRows Do
		Accommodations.Delete(vRow);		
	EndDo;
	
EndProcedure // RoomRatesRoomRateClearing

// ----------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	
	If Debug Then
		Active = True;
	EndIf;
		
EndProcedure // DebugOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	
	If Not Active Then
		Debug = False;
	EndIf;
	
EndProcedure // ActiveOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure Group_MainPagesOnCurrentPageChange(pItem, pCurrentPage)
	
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(pCurrentPage);
	
EndProcedure // Group_MainPagesOnCurrentPageChange

// ----------------------------------------------------------------------------
&AtClient
Procedure Settings_SettingsPagesOnCurrentPageChange(pItem, pCurrentPage)
	
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(pCurrentPage);
	
EndProcedure // Settings_SettingsPagesOnCurrentPageChange

// ----------------------------------------------------------------------------
&AtClient
Procedure UseBackgroundJobOnChange(pItem)
	
	If ValueIsFilled(Employee) Then
		If Object.Schedule <> Undefined Then
			If UseBackgroundJob Then
				If Not IsInRoleAtServer("Administrator") Then
					Raise(NStr("en='A background job should be configured by administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
				EndIf;
				Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
			Else 
				Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
			EndIf;
			If Not Object.Schedule = Undefined Then
				Save_AtServer();
				SetupBackgroundJobSchedule_AtServer();
			EndIf;
		Else
			UseBackgroundJob = False;
			Raise(NStr("en='Schedule not setuped!';ru='Не настроено расписание!';"));
		EndIf;
	Else 
		UseBackgroundJob = False;
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
	
EndProcedure // UseBackgroundJobOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure InteractionParametersOnChange(pItem)
	
	LoadInteractionParameters();
	LoadReservationStatuses();	
	GetMappingsAndLoadThem();
	
EndProcedure // InteractionParametersOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesOnActivateRow(pItem)
	
	If Items.RoomTypes.CurrentData <> Undefined Then
		Items.RoomRates.RowFilter = New FixedStructure("room", Items.RoomTypes.CurrentData.code);
	Else
		Items.RoomRates.RowFilter = New FixedStructure("room", Undefined);	
	EndIf;
	
EndProcedure // RoomTypesOnActivateRow

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesOnActivateRow(pItem)
	
	If Items.RoomRates.CurrentData <> Undefined Then
		RoomRateIdBuffer = Items.RoomRates.CurrentData.id;
		Items.Accommodations.RowFilter = New FixedStructure("id", Items.RoomRates.CurrentData.id);
	Else
		Items.Accommodations.RowFilter = New FixedStructure("id", Undefined);	
	EndIf;

EndProcedure // RoomRatesOnActivateRow

#EndRegion

#Region FormCommandsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure AddAccommodation(pCommand)
	
	If Items.RoomRates.CurrentData <> Undefined And ValueIsFilled(Items.RoomRates.CurrentData.RoomRate) And ValueIsFilled(Items.RoomRates.CurrentData.id) Then
		vNewRow 			= Accommodations.Add();
		vNewRow.RoomRate	= Items.RoomRates.CurrentData.RoomRate;
		vNewRow.id			= Items.RoomRates.CurrentData.id;
	EndIf;
	
	Items.Accommodations.Refresh();
	
EndProcedure // AddAccommodation

// ----------------------------------------------------------------------------
&AtClient
Procedure DeleteAccommodation(pCommand)
	
	If Items.Accommodations.CurrentData <> Undefined Then
		Accommodations.Delete(Accommodations.IndexOf(Items.Accommodations.CurrentData));
	EndIf;
	
EndProcedure // DeleteAccommodation

// ----------------------------------------------------------------------------
&AtClient
Procedure ConnectionTest(pCommand)
	
	If Save_AtServer() Then
		GetMappingsAndLoadThem();
	EndIf;
	
EndProcedure // ConnectionTest

// ----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	
	Save_AtServer();
	
EndProcedure // Save

// ----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(pCommand)
	If ValueIsFilled(Employee)  Then
		If  Not IsInRoleAtServer("Administrator") Then
			Raise(NStr("en='A background job can be configured by system administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
		Else 				
			vScheduleDlg = New ScheduledJobDialog(Object.Schedule);
			
			vScheduleDlg.Show(New NotifyDescription("SetupBackgroundJobSchedule_AfterInput", ThisForm, New Structure()));		
		EndIf;
	Else 
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure // SetupBackgroundJobSchedule

// ----------------------------------------------------------------------------
&AtClient
Procedure ReloadData(pCommand)
	
	If Save_AtServer() Then
		GetMappingsAndLoadThem();
	EndIf;
	
EndProcedure // ReloadData

// ----------------------------------------------------------------------------
&AtClient
Procedure UpdateAvailability(pCommand)
	
	UpdateAvailability_AtServer()
	
EndProcedure // UpdateAvailability

// ----------------------------------------------------------------------------
&AtClient
Procedure UpdatePrices(pCommand)
	
	UpdatePrices_AtServer();
	
EndProcedure // UpdatePrices

// ----------------------------------------------------------------------------
&AtClient
Procedure GetReservations(pCommand)
	GetReservations_AtServer();
EndProcedure // GetReservations

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule_AfterInput(pValue, pParametrs) Export
	If pValue <> Undefined Then
		Object.Schedule = pValue;
	EndIf;
	
	SetupBackgroundJobSchedule_AtServer();
	
	If UseBackgroundJob Then
		Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
	Else 
		Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
	EndIf;
	
EndProcedure // SetupBackgroundJobSchedule_AfterInput

// ----------------------------------------------------------------------------
&AtServer
Procedure UpdateAvailability_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) And ValueIsFilled(Object.HotelCode) Then
		vResult 		= WebHotelier.UpdateAvailability(Object.InteractionParameters, Object.HotelCode, Object.AmountOfDaysToUpdate, Not SyncChangesOnly, True, Object.GetVacantRoomsAtMidnight);
		ManualSyncLogs	= ManualSyncLogs + Chars.LF + "//////////////// Sync availability ////////////////";
		ManualSyncLogs 	= ManualSyncLogs + Chars.LF + "Request:" + Chars.LF + vResult.RawRequest + Chars.LF + Chars.LF + "Response:" + Chars.LF + vResult.RawResponse;
		ManualSyncLogs	= ManualSyncLogs + Chars.LF + "//////////////// Sync availability ////////////////";	
	EndIf;
	
EndProcedure // UpdateAvailability_AtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure UpdatePrices_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) And ValueIsFilled(Object.HotelCode) Then
		vResult 		= WebHotelier.UpdateRates(Object.InteractionParameters, Object.HotelCode, Object.AmountOfDaysToUpdate, Not SyncChangesOnly, False, True);
		ManualSyncLogs	= ManualSyncLogs + Chars.LF + "//////////////// Sync prices ////////////////";
		ManualSyncLogs 	= ManualSyncLogs + Chars.LF + "Request:" + Chars.LF + vResult.RawRequest + Chars.LF + Chars.LF + "Response:" + Chars.LF + vResult.RawResponse;
		ManualSyncLogs	= ManualSyncLogs + Chars.LF + "//////////////// Sync prices ////////////////";	
	EndIf;
	
EndProcedure // UpdatePrices_AtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure GetReservations_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) And ValueIsFilled(Object.HotelCode) Then
		WebHotelier.GetAndLoadReservations(Object.InteractionParameters, Object.HotelCode);
	EndIf;
	
EndProcedure // GetReservations_AtServer

// ----------------------------------------------------------------------------
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
		SaveBoardTypes();
		SaveSourcesTable();
		
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();    
		SetPrivilegedMode(False);
	Except
		RollbackTransaction();
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError);
		Return False;
	EndTry;

	CommitTransaction();
	
	Return True;
	
EndFunction // Save_AtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure SaveAccommodationTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "accommodationtemplates");
	
	For Each vAccommodationRow In Accommodations Do
		If ValueIsFilled(vAccommodationRow.RoomRate) And ValueIsFilled(vAccommodationRow.AccommodationTemplate)Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "accommodationtemplates", "id", vAccommodationRow.AccommodationTemplate, vAccommodationRow.RoomRate, vAccommodationRow.id, vAccommodationRow.id);
		EndIf;
	EndDo;
	
EndProcedure // SaveAccommodationTable

// ----------------------------------------------------------------------------
&AtServer
Procedure LoadAccommodationTable()
	
	vAccommodations = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "accommodationtemplates");
	
	If vAccommodations.Count() > 0 Then		
		For Each vAccommodationRow In vAccommodations Do
			vNewRow 						= Accommodations.Add();
			vNewRow.AccommodationTemplate 	= vAccommodationRow.RefKey1;
		    vNewRow.RoomRate 				= vAccommodationRow.RefKey2;
			vNewRow.id 						= vAccommodationRow.id;
		EndDo;
	EndIf;
	
EndProcedure // LoadAccommodationTable

// ----------------------------------------------------------------------------
&AtServer
Procedure SaveRoomRatesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "roomrates");
	
	For Each vRoomRateRow In RoomRates Do
		If ValueIsFilled(vRoomRateRow.RoomRate) Then
			vRoomType 	= Undefined;
			vRoomTypes 	= RoomTypes.FindRows(New Structure("code", vRoomRateRow.room));
			If vRoomTypes.Count() > 0 Then
				vRoomType = vRoomTypes[0].RoomType;	
			EndIf;
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "id", 			vRoomRateRow.RoomRate, vRoomType, vRoomRateRow.id, 			vRoomRateRow.id);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "name", 		vRoomRateRow.RoomRate, vRoomType, vRoomRateRow.name, 		vRoomRateRow.id);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "active", 		vRoomRateRow.RoomRate, vRoomType, vRoomRateRow.active, 		vRoomRateRow.id);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "parent", 		vRoomRateRow.RoomRate, vRoomType, vRoomRateRow.parent,	 	vRoomRateRow.id);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "room", 		vRoomRateRow.RoomRate, vRoomType, vRoomRateRow.room,	 	vRoomRateRow.id);
		EndIf;
	EndDo;
	
EndProcedure // SaveRoomRatesTable

// ----------------------------------------------------------------------------
&AtServer
Procedure LoadRoomRatesTable()
	
	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "roomrates");
	
	If vRoomRates.Count() > 0 Then		
		For Each vRoomRateRow In vRoomRates Do
			For Each vLoadedRoomRateRow In RoomRates Do
				If vRoomRateRow.id = vLoadedRoomRateRow.id Then 
					vLoadedRoomRateRow.RoomRate = vRoomRateRow.RefKey1;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure // LoadRoomRatesTable

// ----------------------------------------------------------------------------
&AtServer
Procedure SaveRoomsTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "roomtypes");
			
	For Each vRoomTypeRow In RoomTypes Do
		If ValueIsFilled(vRoomTypeRow.RoomType) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "code", 		vRoomTypeRow.RoomType, Undefined, vRoomTypeRow.code, 		vRoomTypeRow.code);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "Name", 		vRoomTypeRow.RoomType, Undefined, vRoomTypeRow.Name, 		vRoomTypeRow.code);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "active", 		vRoomTypeRow.RoomType, Undefined, vRoomTypeRow.active, 		vRoomTypeRow.code);						
		EndIf;
	EndDo;

EndProcedure // SaveRoomsTable

// ----------------------------------------------------------------------------
&AtServer
Procedure LoadRoomsTable()
	
	vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "roomtypes");
	
	Try
		If vRoomTypes.Count() > 0 Then			
			For Each vRoomTypeRow In vRoomTypes Do
				For Each vLoadedRoomTypeRow In RoomTypes Do
					If vRoomTypeRow.code = vLoadedRoomTypeRow.code Then 
						vLoadedRoomTypeRow.RoomType = vRoomTypeRow.RefKey1;
					EndIf;
				EndDo;
			EndDo;
		EndIf;

	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load room types mappings!");
	EndTry;
	
EndProcedure // LoadRoomsTable

// ----------------------------------------------------------------------------
&AtServer
Procedure SaveServicesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "services");
	
	For Each vServiceRow In Services Do
		If ValueIsFilled(vServiceRow.Service) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "services", "id", 		vServiceRow.Service, Undefined, vServiceRow.id, 		vServiceRow.id);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "services", "name", 		vServiceRow.Service, Undefined, vServiceRow.name, 		vServiceRow.id);
		EndIf;
	EndDo;
	
EndProcedure // SaveServicesTable

// ----------------------------------------------------------------------------
&AtServer
Procedure LoadServicesTable()
	
	vServices = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "services");
	
	If vServices.Count() > 0 Then
		vServices.Sort("ID Desc");
		
		For Each vServiceRow In vServices Do
			For Each vLoadedServiceRow In Services Do
				If vServiceRow.id = vLoadedServiceRow.id Then 
					vLoadedServiceRow.Service = vServiceRow.RefKey1;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure // LoadServicesTable

// ----------------------------------------------------------------------------
&AtServer
Procedure SaveReservationStatuses()
	
	If ValueIsFilled(ReservationStatus_New) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_New, Undefined, 1, "1");
	EndIf;
	
	If ValueIsFilled(ReservationStatus_Cancel) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_Cancel, Undefined, 0, "0");
	EndIf;

EndProcedure // SaveReservationStatuses

// ----------------------------------------------------------------------------
&AtServer
Procedure LoadReservationStatuses()
	
	vReservationStatuses = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "reservationstatuses");
	
	If vReservationStatuses.Columns.Find("ID") <> Undefined And vReservationStatuses.Count() > 0 Then
		For Each vReservationStatus In vReservationStatuses Do
			If vReservationStatus.ID = 1 Then
				ReservationStatus_New = vReservationStatus.RefKey1;
			ElsIf vReservationStatus.ID = 0 Then
				ReservationStatus_Cancel = vReservationStatus.RefKey1;
			EndIf;
		EndDo;
	EndIf;

EndProcedure // LoadReservationStatuses

// ----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	vIntParObj 				= Object.InteractionParameters.GetObject();
	vIntParObj.Login 		= Username;	
	vIntParObj.Password 	= Password;	
	vIntParObj.HttpServer 	= HTTPServer;
	vIntParObj.Hotel 		= Hotel;
	vIntParObj.Allotment 	= Allotment;
	vIntParObj.IsActive 	= Active;
	vIntParObj.DebugMode 	= Debug;
	vIntParObj.HttpAddress 	= HTTPAddress;
	vIntParObj.HttpUseSsl 	= HTTPUseSSL;
	vIntParObj.ClientType 	= ClientType;
	vIntParObj.Currency 	= Currency;
	vIntParObj.ConvertCurrency 	= ConvertCurrency;
	vIntParObj.MaxLogLenght 	= MaxLogLenght;
	vIntParObj.Write();
	
EndProcedure // SaveInteractionParameters

// ----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	Username  		= Object.InteractionParameters.Login;	
	Password  		= Object.InteractionParameters.Password;	
	HTTPServer  	= Object.InteractionParameters.HttpServer;
	Hotel  			= Object.InteractionParameters.Hotel;
	Allotment  		= Object.InteractionParameters.Allotment;
	Active  		= Object.InteractionParameters.IsActive;
	Debug  			= Object.InteractionParameters.DebugMode;
	HTTPAddress  	= Object.InteractionParameters.HttpAddress;
	HTTPUseSSL  	= Object.InteractionParameters.HttpUseSsl;
	ClientType  	= Object.InteractionParameters.ClientType;
	Currency  		= Object.InteractionParameters.Currency;
	ConvertCurrency = Object.InteractionParameters.ConvertCurrency;
	MaxLogLenght    = Object.InteractionParameters.MaxLogLenght;
EndProcedure // LoadInteractionParameters

// ----------------------------------------------------------------------------
&AtServer
Procedure GetMappingsAndLoadThem()
			
	If ValueIsFilled(Object.InteractionParameters) And ValueIsFilled(Object.HotelCode) Then
		
		vRooms 	= WebHotelier.GetRoomListing(Object.InteractionParameters, Object.HotelCode);			
		If vRooms.Success And vRooms.Result <> Undefined Then
			RoomTypes.Clear();
			For Each vRow In vRooms.Result Do
				vNewRow = RoomTypes.Add();
				FillTableRowFromMap(vNewRow, vRow);
			EndDo;
			LoadRoomsTable();		
		Else
			tcCommonFunctionOnClientServer.TextMessage("Failed to load room types mappings: " + vRooms.Error);
			Return;
		EndIf;
		
		vRates 	= WebHotelier.GetRatesListing(Object.InteractionParameters, Object.HotelCode);
		If vRates.Success And vRates.Result <> Undefined Then
			RoomRates.Clear();
			For Each vRow In vRates.Result Do
				vNewRow = RoomRates.Add();
				FillTableRowFromMap(vNewRow, vRow);
				If vRow["parent"] > 0 Then
					vNewRow.parent = True;
				Else
					vNewRow.parent = False;
				EndIf;
			EndDo;
			LoadRoomRatesTable();		
		Else
			tcCommonFunctionOnClientServer.TextMessage("Failed to load room rates mappings: " + vRates.Error);
			Return;
		EndIf;
		
		Accommodations.Clear();
		LoadAccommodationTable();

		vExtras = WebHotelier.GetExtrasListing(Object.InteractionParameters, Object.HotelCode);
		If vExtras.Success And vExtras.Result <> Undefined Then
			Services.Clear();
			For Each vRow In vExtras.Result Do
				vNewRow = Services.Add();
				FillTableRowFromMap(vNewRow, vRow);
			EndDo;
			LoadServicesTable();		
		Else
			tcCommonFunctionOnClientServer.TextMessage("Failed to load extras mappings: " + vExtras.Error);
			Return;
		EndIf;
		
		vSources = WebHotelier.GetSourcesListing(Object.InteractionParameters);
		If vSources.Success And vSources.Result <> Undefined Then
			Sources.Clear();
			For Each vRow In vSources.Result Do
				If Sources.Count() = 0 Then
					// Add line with ID -99 for the hotel web-site
					vNewRow = Sources.Add();
					vNewRow.ID = -99;
					vNewRow.Name = "Hotel web-site";
				EndIf;
				vNewRow = Sources.Add();
				FillTableRowFromMap(vNewRow, vRow);
			EndDo;
			LoadSourcesTable();		
		Else
			tcCommonFunctionOnClientServer.TextMessage("Failed to load sources mappings: " + vSources.Error);
			Return;
		EndIf;
	EndIf;
	
	LoadBoardTypes();
	
EndProcedure // GetMappingsAndLoadThem

// ----------------------------------------------------------------------------
&AtServer
Procedure LoadBoardTypes()
	
	BoardTypes.Clear();
	
	vBoardTypesList 	= GetBoardTypesList();
	vBoardTypes	 		= InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "boardtypes");
	
	If vBoardTypes.Columns.Find("ID") <> Undefined Then
		vLoad = True;
	Else
		vLoad = False;
	EndIf;
	
	For Each vRow In vBoardTypesList Do
		vNewRow = BoardTypes.Add();
		FillPropertyValues(vNewRow, vRow);
		
		If vLoad Then
			vFoundRow = vBoardTypes.Find(vRow.ID, "ID");
			If vFoundRow <> Undefined Then
				vNewRow.ServicePackage = vFoundRow.RefKey1; 	
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure // LoadBoardTypes

// ----------------------------------------------------------------------------
&AtServer
Procedure SaveBoardTypes()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "boardtypes");
	
	For Each vBoardTypeRow In BoardTypes Do
		If ValueIsFilled(vBoardTypeRow.ServicePackage) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "boardtypes", "id", 		vBoardTypeRow.ServicePackage, Undefined, vBoardTypeRow.id, 		vBoardTypeRow.id);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "boardtypes", "name", 	vBoardTypeRow.ServicePackage, Undefined, vBoardTypeRow.name, 		vBoardTypeRow.id);
		EndIf;
	EndDo;
	
EndProcedure // SaveBoardTypes

// ----------------------------------------------------------------------------
&AtServer
Procedure LoadSourcesTable()
	
	vSources = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "sources");
	
	Try
		If vSources.Count() > 0 Then			
			For Each vSourceRow In vSources Do
				For Each vLoadedSourceRow In Sources Do
					If vSourceRow.id = vLoadedSourceRow.id Then 
						vLoadedSourceRow.Agent = vSourceRow.RefKey1;
					EndIf;
				EndDo;
			EndDo;
		EndIf;

		Sources.Sort("ID");
		
	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load sources mappings!");
	EndTry;
	
EndProcedure // LoadSourcesTable

// ----------------------------------------------------------------------------
&AtServer
Procedure SaveSourcesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "sources");
			
	For Each vSourceRow In Sources Do
		If ValueIsFilled(vSourceRow.Agent) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "sources", "ID", 	vSourceRow.Agent, Undefined, vSourceRow.ID, 		vSourceRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "sources", "Name", 	vSourceRow.Agent, Undefined, vSourceRow.Name, 		vSourceRow.ID);					
		EndIf;
	EndDo;

EndProcedure // SaveSourcesTable

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetBoardTypesList()
	
	vResult = New ValueTable;
	vResult.Columns.Add("ID");
	vResult.Columns.Add("Name");
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 0;
	vNewRow.Name	= "No board or N/A";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 1;
	vNewRow.Name	= "All inclusive";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 2;
	vNewRow.Name	= "American";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 3;
	vNewRow.Name	= "Bed & breakfast";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 4;
	vNewRow.Name	= "Buffet breakfast";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 5;
	vNewRow.Name	= "Caribbean breakfast";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 6;
	vNewRow.Name	= "Continental breakfast";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 7;
	vNewRow.Name	= "English breakfast";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 8;
	vNewRow.Name	= "European plan";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 9;
	vNewRow.Name	= "Family plan";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 10;
	vNewRow.Name	= "Full board";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 11;
	vNewRow.Name	= "Full breakfast";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 12;
	vNewRow.Name	= "Half board";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 13;
	vNewRow.Name	= "As brochured";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 14;
	vNewRow.Name	= "Room only";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 15;
	vNewRow.Name	= "Self catering";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 16;
	vNewRow.Name	= "Bermuda";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 17;
	vNewRow.Name	= "Dinner bed and breakfast plan";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 18;
	vNewRow.Name	= "Family American";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 19;
	vNewRow.Name	= "Breakfast";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 20;
	vNewRow.Name	= "Modified";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 21;
	vNewRow.Name	= "Lunch";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 22;
	vNewRow.Name	= "Dinner";
	
	vNewRow 		= vResult.Add();
	vNewRow.ID 		= 23;
	vNewRow.Name	= "Breakfast & lunch";

	Return vResult;
	
EndFunction // GetBoardTypesList

// ----------------------------------------------------------------------------
&AtClient
Function GetToolTipTextForCurrentPage(pCurrentPage)
	
	//#TODO Translate
	
	vToolTips = New Structure;
	vToolTips.Insert("SettingsPages_MainInfo", 			NStr("en = 'Connection settings tooltip'; de = 'Connection settings tooltip'; ru = 'Connection settings tooltip'"));
	vToolTips.Insert("SettingsPages_RoomTypes", 		NStr("en = 'Room types tooltip'; de = 'Room types tooltip'; ru = 'Room types tooltip'"));
	vToolTips.Insert("SettingsPages_RoomRates", 		NStr("en = 'Room rates tooltip'; de = 'Room rates tooltip'; ru = 'Room rates tooltip'"));
	vToolTips.Insert("SettingsPages_Statuses", 			NStr("en = 'Reservation statuses tooltip'; de = 'Reservation statuses tooltip'; ru = 'Reservation statuses tooltip'"));
	vToolTips.Insert("MainPages_View", 					NStr("en = 'Channel data view tooltip'; de = 'Channel data view tooltip'; ru = 'Channel data view tooltip'"));
	vToolTips.Insert("MainPages_ManualSync", 			NStr("en = 'Manual sync tooltip'; de = 'Manual sync tooltip'; ru = 'Manual sync tooltip'"));
	vToolTips.Insert("MainPages_BackgroundJob", 		NStr("en = 'BackgroundJob tooltip'; de = 'BackgroundJob tooltip'; ru = 'BackgroundJob tooltip'"));	
	vToolTips.Insert("SettingsPages_Services", 			NStr("en = 'Services tooltip'; de = 'Services tooltip'; ru = 'Services tooltip'")); 
	vToolTips.Insert("SettingsPages_ServicePackages", 	NStr("en = 'Services packages tooltip'; de = 'Services packages tooltip'; ru = 'Services packages tooltip'")); 
	vToolTips.Insert("SettingsPages_Agents", 			NStr("en = 'Agents tooltip'; de = 'Agents tooltip'; ru = 'Agents tooltip'")); 
	vResult = "";
	
	If pCurrentPage.Name = "MainPages_Settings" Then		
		vCurrentPageName 	= Items.Settings_SettingsPages.CurrentPage.Name;
		vResult 			= vToolTips[vCurrentPageName];		
	Else	
		vResult 			= vToolTips[pCurrentPage.Name];
	EndIf;
	
	Return vResult;
	
EndFunction // GetToolTipTextForCurrentPage

// ----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction // IsInRoleAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure SetupBackgroundJobSchedule_AtServer(pRead = False)
	If Not pRead Then 
		If Not CheckFilling() Then
			UseBackgroundJob = False;
		EndIf;
	EndIf;
	
	Try
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key",Object.DataProcessor.Key));
		
		If ArrayScheduledJob.Count() > 0 Then
			ScheduledJob 			= ArrayScheduledJob[0];
			
			If pRead Then
				Employee  				= cmGetEmployeeByUserName(ScheduledJob.UserName);
				Object.Schedule  		= ScheduledJob.Schedule;
				UseBackgroundJob  		= ScheduledJob.Use;	
			Else				
				vUserNames = cmGetUserUUIDsByEmployee(Employee);
				If vUserNames.Count() > 0 Then
					vUsrName = vUserNames[0].UserName;
				Else
					vMessage = NStr("en='The user of the information base was not found!';
									|ru='Пользователь информационной базы не найден!';
									|de='Der Benutzer der Informationsbasis wurde nicht gefunden!'");
					tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Endif;

				ScheduledJob.UserName 	= vUsrName;
				ScheduledJob.Schedule 	= Object.Schedule;
				ScheduledJob.Use 		= UseBackgroundJob;
			EndIf;
			
			If ScheduledJob.Parameters.Count() = 0 Then
				ScheduledJob.Parameters.Add(Object.DataProcessor.Key);
			EndIf;
			
		Else 	
			
			For Each vScheduledJob In Metadata.ScheduledJobs Do   
				If vScheduledJob.Name="RunDataProcessor" Then
					
					ScheduledJob = ScheduledJobs.CreateScheduledJob(vScheduledJob);
					
				EndIf;
			EndDo;
			
			vUserNames = cmGetUserUUIDsByEmployee(Employee);
			If vUserNames.Count() > 0 Then
				vUsrName = vUserNames[0].UserName;
			Else
				vMessage = NStr("en='The user of the information base was not found!';
								|ru='Пользователь информационной базы не найден!';
								|de='Der Benutzer der Informationsbasis wurde nicht gefunden!'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
			Endif;
			
			ScheduledJob.Description 				= Object.DataProcessor.Description;
			ScheduledJob.Key 						= Object.DataProcessor.Key;
			ScheduledJob.Use 						= UseBackgroundJob;
			ScheduledJob.UserName 					= vUsrName;
			ScheduledJob.RestartCountOnFailure 		= 0;
			ScheduledJob.RestartIntervalOnFailure 	= 0;
			
			If Object.Schedule = Undefined or pRead Then 
				Object.Schedule  					= ScheduledJob.Schedule;
			Else
				ScheduledJob.Schedule   			= Object.Schedule;
			EndIf;
			
			If ScheduledJob.Parameters.Count() = 0 Then
				ScheduledJob.Parameters.Add(Object.DataProcessor.Key);
			EndIf;
			
		EndIf;
		
		ScheduledJob.Write();
		
	Except	
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);	
	EndTry;
EndProcedure // SetupBackgroundJobSchedule_AtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure CheckHotelUseRoomRateDailyPrices()
		
	If ValueIsFilled(Hotel) And Not Hotel.UseRoomRateDailyPrices Then
		Items.Hotel_UseRoomRateDailyPrices_Text.Visible = True;
	Else
		Items.Hotel_UseRoomRateDailyPrices_Text.Visible = False;	
	EndIf;
	
EndProcedure // CheckHotelUseRoomRateDailyPrices

// ----------------------------------------------------------------------------
&AtServer
Procedure FillTableRowFromMap(pReciever, pMap)
	
	For Each vKeyAndValue In pMap Do
		If pReciever.Property(vKeyAndValue.Key) Then 
			pReciever[vKeyAndValue.Key] = vKeyAndValue.Value;
		EndIf;
	EndDo;
	
EndProcedure // FillTableRowFromMap

#EndRegion