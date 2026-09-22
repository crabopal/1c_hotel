

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	Else
		vDataProcessor = Catalogs.DataProcessors.FindByAttribute("Processing", "AvailproWizard");
		If vDataProcessor = Catalogs.DataProcessors.EmptyRef() Then
			vNewDP 				= Catalogs.DataProcessors.CreateItem();
			vNewDP.Description 	= "Availpro";
			vNewDP.Key 			= "Availpro";
			vNewDP.Processing 	= "AvailproWizard";
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
	ValueToFormAttribute(Obj, "Object");

	If Object.AmountOfDaysToUpdate <= 0 Then
		Object.AmountOfDaysToUpdate = 100;	
	EndIf;
	
	LoadInteractionParameters();
	LoadReservationStatuses();	
	GetMappingsAndLoadThem();
	
	If IsInRoleAtServer("Administrator") And vDataProcessor <> Undefined Then
		If IsBlankString(vDataProcessor.Key) Then
			dpObj = vDataProcessor.GetObject();
			dpObj.Key = "Availpro";
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
	SetDecorationText();
	SetPaymentsVisibility();
	
EndProcedure

&AtClient
Procedure OnOpen(pCancel)
	
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(Items.Group_MainPages.CurrentPage);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DebugOnChange(pItem)
	
	If Debug Then
		Active = True;
	EndIf;
		
EndProcedure

&AtClient
Procedure ActiveOnChange(pItem)
	
	If Not Active Then
		Debug = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure Group_MainPagesOnCurrentPageChange(pItem, pCurrentPage)
	
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(pCurrentPage);
	
EndProcedure

&AtClient
Procedure Settings_SettingsPagesOnCurrentPageChange(pItem, pCurrentPage)
	
	Items.Decoration_Main_ToolTip.Title = GetToolTipTextForCurrentPage(pCurrentPage);
	
EndProcedure

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
	
EndProcedure

&AtClient
Procedure InteractionParametersOnChange(pItem)
	
	LoadInteractionParameters();
	LoadReservationStatuses();	
	GetMappingsAndLoadThem();
	
EndProcedure

&AtClient
Procedure HotelOnChange(pItem)
	
	CheckHotelUseRoomRateDailyPrices();
	
EndProcedure

&AtClient
Procedure AmountOfDaysToUpdateOnChange(pItem)
	
	SetDecorationText();
	
EndProcedure

&AtClient
Procedure CreatePaymentsOnChange(pItem)
	
	 SetPaymentsVisibility();
	 
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConnectionTest(pCommand)
	
	Save_AtServer();
	ConnectionTest_AtServer();
	
EndProcedure

&AtClient
Procedure Save(pCommand)
	
	Save_AtServer();
	
EndProcedure

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
EndProcedure

&AtClient
Procedure ReloadData(pCommand)
	
	If Save_AtServer() Then
		GetMappingsAndLoadThem();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAvailability(pCommand)
	
	UpdateAvailability_AtServer()
	
EndProcedure

&AtClient
Procedure UpdatePrices(pCommand)
	
	UpdatePrices_AtServer();
	
EndProcedure

&AtClient
Procedure GetReservations(pCommand)
	GetReservations_AtServer();
EndProcedure

&AtClient
Procedure AddAccommodation(pCommand)
	
	If Items.RoomTypes.CurrentData <> Undefined Then
		vRowID 	= Items.RoomTypes.CurrentData.GetID();
		vRow 	= RoomTypes.FindByID(vRowID);
		vParent = vRow.GetParent();
		If vParent <> Undefined And ValueIsFilled(vParent.RoomType) Then
			vNewRow = vParent.GetItems().Add();
			FillPropertyValues(vNewRow, vParent,, "AccommodationTemplate, isChild");
			vNewRow.isChild = True;
		ElsIf  ValueIsFilled(vRow.RoomType) Then
			vNewRow = vRow.GetItems().Add();
			FillPropertyValues(vNewRow, vRow,, "AccommodationTemplate, isChild");
			vNewRow.isChild = True;
		Else
			tcCommonFunctionOnClientServer.TextMessage("Fill room type first!");
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure DeleteAccommodation(pCommand)
	
	If Items.RoomTypes.CurrentData <> Undefined Then
		vRowID 	= Items.RoomTypes.CurrentData.GetID();
		vRow 	= RoomTypes.FindByID(vRowID);
		vParent = vRow.GetParent();
		If vParent <> Undefined Then
			vParent.GetItems().Delete(vRow);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GeneratePassword(pCommand)
	
	NewPassword = String(New UUID);
	NewPassword	= StrReplace(NewPassword, "-", "");
	
EndProcedure

&AtClient
Procedure ChangePassword(pCommand)
	
	ChangePassword_AtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	
	vRoomTypesCheck = New Array;
	vRoomTypesCheck.Add("RoomType");
	vRoomTypesCheck.Add("AccommodationTemplate");
	
	vRoomRatesCheck = New Array;
	vRoomRatesCheck.Add("RoomRate");
	
	If Object.CreatePayments Then
		If Not ValueIsFilled(Object.PaymentMethod) Then
			vUserMsg 			= New UserMessage;
			vUserMsg.Text 		= NStr("en = 'Choose payment method!'; de = 'Choose payment method!'; ru = 'Выберите вариант оплаты платежей!'");
			vUserMsg.Field		= "PaymentMethod";
			vUserMsg.DataPath 	= "PaymentMethod";
			vUserMsg.Message();
			Return;			
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure ConnectionTest_AtServer()
	
	vColors = GetFormItemsColors();
	
	vPingResult = Availpro.Ping(Object.InteractionParameters);
	
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

	If vPingResult.Success Then
		vUserMsg 		= New UserMessage;
		vUserMsg.Text 	= NStr("en = 'Successful connection!'; de = 'Erfolgreiche Verbindung!'; ru = 'Успешное подключение!'");
		vUserMsg.Field	= "Ping";
		vUserMsg.Message();
	EndIf;
	
EndProcedure

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
	
EndProcedure

&AtServer
Procedure UpdateAvailability_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) And ValueIsFilled(Object.HotelCode) Then
		vResult 		= Availpro.DataUpdate(Object.InteractionParameters, Object.HotelCode, True, False, Object.AmountOfDaysToUpdate, Not SyncChangesOnly,, True);
		ManualSyncLogs	= ManualSyncLogs + Chars.LF + "//////////////// Sync availability ////////////////";
		ManualSyncLogs 	= ManualSyncLogs + Chars.LF + "Request:" + Chars.LF + vResult.RawRequest + Chars.LF + Chars.LF + "Response:" + Chars.LF + vResult.RawResponse;
		ManualSyncLogs	= ManualSyncLogs + Chars.LF + "//////////////// Sync availability ////////////////";	
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePrices_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) And ValueIsFilled(Object.HotelCode) Then
		vResult 		= Availpro.DataUpdate(Object.InteractionParameters, Object.HotelCode, False, True, Object.AmountOfDaysToUpdate, Not SyncChangesOnly,, True);
		ManualSyncLogs	= ManualSyncLogs + Chars.LF + "//////////////// Sync prices ////////////////";
		ManualSyncLogs 	= ManualSyncLogs + Chars.LF + "Request:" + Chars.LF + vResult.RawRequest + Chars.LF + Chars.LF + "Response:" + Chars.LF + vResult.RawResponse;
		ManualSyncLogs	= ManualSyncLogs + Chars.LF + "//////////////// Sync prices ////////////////";	
	EndIf;
	
EndProcedure

&AtServer
Procedure GetReservations_AtServer()
	
	Save_AtServer();
	If ValueIsFilled(Object.InteractionParameters) And ValueIsFilled(Object.HotelCode) Then
		Availpro.GetBookings(Object.InteractionParameters, Object.HotelCode, False, Object.CreatePayments, Object.PaymentMethod);
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangePassword_AtServer()
	
	If ValueIsFilled(NewPassword) Then
		vResult = Availpro.SetNewCredentials(Object.InteractionParameters, Object.HotelCode, NewPassword);
		If vResult.Success = True Then
			Password = NewPassword;
			SaveInteractionParameters();
			NewPassword = "";
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function Save_AtServer()
	SetPrivilegedMode(True);
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	BeginTransaction();
	
	Try
		SaveInteractionParameters();	
		SaveReservationStatuses();
		SaveRoomRatesTable();
		SaveRoomsTable();
	    SaveRoomTypeAndRateMappings();
		SaveServicesTable();
		SaveAgentsTable();
		
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes(); 
		SetPrivilegedMode(False);
	Except
		RollbackTransaction();
		Return False;
	EndTry;

	CommitTransaction();
	
	Return True;
	
EndFunction

&AtServer
Procedure SaveRoomRatesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "roomrates");
	
	For Each vRoomRateRow In RoomRates Do
		If ValueIsFilled(vRoomRateRow.RoomRate) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "ID", 			vRoomRateRow.RoomRate, Undefined, vRoomRateRow.ID, 			vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "Name", 		vRoomRateRow.RoomRate, Undefined, vRoomRateRow.Name, 		vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "isActive", 	vRoomRateRow.RoomRate, Undefined, vRoomRateRow.isActive, 	vRoomRateRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomrates", "isDerivated", 	vRoomRateRow.RoomRate, Undefined, vRoomRateRow.isDerivated, vRoomRateRow.ID);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure LoadRoomRatesTable()
	
	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "roomrates");
	
	If vRoomRates.Count() > 0 Then
		vRoomRates.Sort("ID Desc");
		
		For Each vRoomRateRow In vRoomRates Do
			For Each vLoadedRoomRateRow In RoomRates Do
				If vRoomRateRow.ID = vLoadedRoomRateRow.ID Then 
					vLoadedRoomRateRow.RoomRate = vRoomRateRow.RefKey1;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveRoomsTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "roomtypes");
		
	vMainRoomTypes = RoomTypes.GetItems();
	
	For Each vMainTypeRow In vMainRoomTypes Do
		If ValueIsFilled(vMainTypeRow.RoomType) And ValueIsFilled(vMainTypeRow.AccommodationTemplate) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "isChildRow", 	vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, False, 					vMainTypeRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "ID", 			vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, vMainTypeRow.ID, 		vMainTypeRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "Name", 		vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, vMainTypeRow.Name, 		vMainTypeRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "isActive", 	vMainTypeRow.RoomType, vMainTypeRow.AccommodationTemplate, vMainTypeRow.isActive, 	vMainTypeRow.ID);
			
			vVirtualRoomTypes = vMainTypeRow.GetItems();
			For Each vVirtualTypeRow In vVirtualRoomTypes Do
				If ValueIsFilled(vVirtualTypeRow.RoomType) And ValueIsFilled(vVirtualTypeRow.AccommodationTemplate) Then
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "isChildRow", 	vMainTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, True, 					vMainTypeRow.ID);
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "ID", 			vMainTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vMainTypeRow.ID, 			vMainTypeRow.ID);
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "Name", 		vMainTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vMainTypeRow.Name, 		vMainTypeRow.ID);
					InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "roomtypes", "isActive", 	vMainTypeRow.RoomType, vVirtualTypeRow.AccommodationTemplate, vMainTypeRow.isActive, 	vMainTypeRow.ID);;
				EndIf;	
			EndDo;
			
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure LoadRoomsTable()
	
	vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "roomtypes");
	
	Try
		If vRoomTypes.Count() > 0 Then
			vRoomTypes.Sort("ID Desc");
			
			vMainRoomTypes = RoomTypes.GetItems();
			For Each vRoomTypeRow In vRoomTypes Do
				For Each vLoadedRoomTypeRow In vMainRoomTypes Do
					If vRoomTypeRow.ID = vLoadedRoomTypeRow.ID Then 
						If vRoomTypeRow.isChildRow = False Then 
							vLoadedRoomTypeRow.RoomType 				= vRoomTypeRow.RefKey1;
							vLoadedRoomTypeRow.AccommodationTemplate 	= vRoomTypeRow.RefKey2;
							vLoadedRoomTypeRow.isChild 					= False;
						Else
							vNewRow = vLoadedRoomTypeRow.GetItems().Add();
							FillPropertyValues(vNewRow, vLoadedRoomTypeRow); 
		                    vNewRow.RoomType 				= vRoomTypeRow.RefKey1;
							vNewRow.AccommodationTemplate 	= vRoomTypeRow.RefKey2;
							vNewRow.isChild 				= True;
						EndIf;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
	Except
		tcCommonFunctionOnClientServer.TextMessage("Failed to load room types mappings!");
	EndTry;
	
EndProcedure

&AtServer
Procedure SaveRoomTypeAndRateMappings()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "RoomTypeAndRateMappings");
	
	For Each vRoomMappingsRow In RoomTypeAndRateMappings Do
		If ValueIsFilled(vRoomMappingsRow.RoomID) And ValueIsFilled(vRoomMappingsRow.RateID) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "RoomTypeAndRateMappings", "RoomID", 	Undefined, Undefined, vRoomMappingsRow.RoomID, 	vRoomMappingsRow.UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "RoomTypeAndRateMappings", "RateID", 	Undefined, Undefined, vRoomMappingsRow.RateID, 	vRoomMappingsRow.UUID);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveServicesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "services");
	
	For Each vServiceRow In Services Do
		If ValueIsFilled(vServiceRow.Service) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "services", "ID", 		vServiceRow.Service, Undefined, vServiceRow.ID, 		vServiceRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "services", "Name", 		vServiceRow.Service, Undefined, vServiceRow.Name, 		vServiceRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "services", "isActive", 	vServiceRow.Service, Undefined, vServiceRow.isActive, 	vServiceRow.ID);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure LoadServicesTable()
	
	vServices = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "services");
	
	If vServices.Count() > 0 Then
		vServices.Sort("ID Desc");
		
		For Each vServiceRow In vServices Do
			For Each vLoadedServiceRow In Services Do
				If vServiceRow.ID = vLoadedServiceRow.ID Then 
					vLoadedServiceRow.Service = vServiceRow.RefKey1;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveAgentsTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "agents");
	
	For Each vAgentsRow In Agents Do
		If ValueIsFilled(vAgentsRow.Customer) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agents", "ID", 			vAgentsRow.Customer, Undefined, vAgentsRow.ID, 		vAgentsRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "agents", "Name", 		vAgentsRow.Customer, Undefined, vAgentsRow.Name, 	vAgentsRow.ID);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure LoadAgentsTable()
	
	vAgents = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "agents");
	
	If vAgents.Count() > 0 Then
		vAgents.Sort("ID Desc");
		
		For Each vAgentsRow In vAgents Do
			For Each vLoadedAgentsRow In Agents Do
				If vAgentsRow.ID = vLoadedAgentsRow.ID Then 
					vLoadedAgentsRow.Customer = vAgentsRow.RefKey1;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveReservationStatuses()
	
	If ValueIsFilled(ReservationStatus_New) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_New, Undefined, "Create", "Create");
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_New, Undefined, "Modify", "Modify");
	EndIf;
	
	If ValueIsFilled(ReservationStatus_Cancel) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "reservationstatuses", "ID", ReservationStatus_Cancel, Undefined, "Cancel", "Cancel");
	EndIf;

EndProcedure

&AtServer
Procedure LoadReservationStatuses()
	
	vReservationStatuses = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "reservationstatuses");
	
	If vReservationStatuses.Columns.Find("ID") <> Undefined And vReservationStatuses.Count() > 0 Then
		For Each vReservationStatus In vReservationStatuses Do
			If vReservationStatus.ID = "Create" Then
				ReservationStatus_New = vReservationStatus.RefKey1;
			ElsIf vReservationStatus.ID = "Cancel" Then
				ReservationStatus_Cancel = vReservationStatus.RefKey1;
			EndIf;
		EndDo;
	EndIf;

EndProcedure

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
	vIntParObj.Write();
	
EndProcedure

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
	
EndProcedure

&AtServer
Procedure GetMappingsAndLoadThem()
	
	If ValueIsFilled(Object.InteractionParameters) And ValueIsFilled(Object.HotelCode) Then
		vMappings = Availpro.GetHotelMapping(Object.InteractionParameters, Object.HotelCode);
		
		If vMappings.Success And vMappings.Result <> Undefined Then
			RoomRates.Clear();
			For Each vRow In vMappings.Result.Rates Do
				vNewRow = RoomRates.Add();
				FillPropertyValues(vNewRow, vRow);
			EndDo;
			LoadRoomRatesTable();
			
			vRoomTypes = RoomTypes.GetItems();
			vRoomTypes.Clear();;
			For Each vRow In vMappings.Result.Rooms Do
				vNewRow = vRoomTypes.Add();
				FillPropertyValues(vNewRow, vRow);
			EndDo;
			LoadRoomsTable();
			
			RoomTypeAndRateMappings.Clear();
			For Each vRow In vMappings.Result.RoomsMapping Do
				vNewRow 		= RoomTypeAndRateMappings.Add();
				vNewRow.UUID 	= String(New UUID);
				FillPropertyValues(vNewRow, vRow);	
			EndDo;
			
			Services.Clear();
			For Each vRow In vMappings.Result.Extras Do
				vNewRow = Services.Add();
				FillPropertyValues(vNewRow, vRow);
			EndDo;
			LoadServicesTable();

			For Each vRow In vMappings.Result.Agents Do
				vNewRow = Agents.Add();
				FillPropertyValues(vNewRow, vRow);
			EndDo;
			LoadAgentsTable();

		Else
			tcCommonFunctionOnClientServer.TextMessage(vMappings.Error);
		EndIf;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function GetFormItemsColors()
	
	vResult = New Structure;
	
	vResult.Insert("Success", New Color(204, 255, 204));
	vResult.Insert("Failure", New Color(255, 204, 204));
                                  	
	Return vResult;
	
EndFunction

&AtClient
Function GetToolTipTextForCurrentPage(pCurrentPage)
	
	// Translate
	
	vToolTips = New Structure;
	vToolTips.Insert("SettingsPages_MainInfo", 		NStr("en = 'Connection settings tooltip'; de = 'Connection settings tooltip'; ru = 'Connection settings tooltip'"));
	vToolTips.Insert("SettingsPages_RoomTypes", 	NStr("en = 'Room types tooltip'; de = 'Room types tooltip'; ru = 'Room types tooltip'"));
	vToolTips.Insert("SettingsPages_RoomRates", 	NStr("en = 'Room rates tooltip'; de = 'Room rates tooltip'; ru = 'Room rates tooltip'"));
	vToolTips.Insert("SettingsPages_Statuses", 		NStr("en = 'Reservation statuses tooltip'; de = 'Reservation statuses tooltip'; ru = 'Reservation statuses tooltip'"));
	vToolTips.Insert("MainPages_View", 				NStr("en = 'Channel data view tooltip'; de = 'Channel data view tooltip'; ru = 'Channel data view tooltip'"));
	vToolTips.Insert("MainPages_ManualSync", 		NStr("en = 'Manual sync tooltip'; de = 'Manual sync tooltip'; ru = 'Manual sync tooltip'"));
	vToolTips.Insert("MainPages_BackgroundJob", 	NStr("en = 'BackgroundJob tooltip'; de = 'BackgroundJob tooltip'; ru = 'BackgroundJob tooltip'"));	
	vToolTips.Insert("SettingsPages_Services", 		NStr("en = 'Services tooltip'; de = 'Services tooltip'; ru = 'Services tooltip'")); 
	vToolTips.Insert("SettingsPages_Agents", 		NStr("en = 'Agents tooltip'; de = 'Agents tooltip'; ru = 'Agents tooltip'")); 
	vResult = "";
	
	If pCurrentPage.Name = "MainPages_Settings" Then		
		vCurrentPageName = Items.Settings_SettingsPages.CurrentPage.Name;
		vResult = vToolTips[vCurrentPageName];		
	Else	
		vResult = vToolTips[pCurrentPage.Name];
	EndIf;
	
	Return vResult;
EndFunction

&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

&AtServer
Procedure SetupBackgroundJobSchedule_AtServer(pRead = False)
	If Not pRead Then 
		If Not CheckFilling() Then
			UseBackgroundJob = False;
		EndIf;
	EndIf;
	
	Try
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", Object.DataProcessor.Key));
		
		If ArrayScheduledJob.Count() > 0 Then
			ScheduledJob  = ArrayScheduledJob[0];
			
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
				If vScheduledJob.Name = "RunDataProcessor" Then
					
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
EndProcedure

&AtServer
Procedure CheckHotelUseRoomRateDailyPrices()
		
	If ValueIsFilled(Hotel) And Not Hotel.UseRoomRateDailyPrices Then
		Items.Hotel_UseRoomRateDailyPrices_Text.Visible = True;
	Else
		Items.Hotel_UseRoomRateDailyPrices_Text.Visible = False;	
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDecorationText()
	
	vPeriod = Format(CurrentDate(), "DF=dd.MM.yyyy") + " - " + Format(CurrentDate() + 24*60*60 * Object.AmountOfDaysToUpdate, "DF=dd.MM.yyyy");
	Items.Decoration_Text_SyncPeriod.Title = NStr("en = 'Sync Period:'; de = 'Sync Period:'; ru = 'Период синхронизации:'") + " " + vPeriod;
	
EndProcedure

&AtServer
Procedure SetPaymentsVisibility()
	
	If Object.CreatePayments Then
		Items.PaymentMethod.Visible = True;
	Else
		Items.PaymentMethod.Visible = False;	
	EndIf;
	
EndProcedure

#EndRegion
