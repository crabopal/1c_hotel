#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	Else
		vDataProcessor = Catalogs.DataProcessors.FindByAttribute("Processing","AleanCRSSystemInventorySynchronization3");
		If vDataProcessor = Catalogs.DataProcessors.EmptyRef() Then
			vNewDP 				= Catalogs.DataProcessors.CreateItem();
			vNewDP.Description 	= "Alean CRS system synchronization v.3";
			vNewDP.Key 			= "AleanCRSSystemInventorySynchronization3";
			vNewDP.Processing 	= "AleanCRSSystemInventorySynchronization3";
			vNewDP.Write();
			vDataProcessor = vNewDP.Ref;
		EndIf;
		
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.ExternalInteraction = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	LoadInteractionParameters();
	
	#If NOT MobileClient Then
		If IsInRoleAtServer("Administrator") AND vDataProcessor <> Undefined Then
			If IsBlankString(vDataProcessor.Key) Then
				dpObj = vDataProcessor.GetObject();
				dpObj.Key = "AleanCRSSystemInventorySynchronization3";
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
			tcCommonFunctionOnClientServer.TextMessage("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'");
		EndIf;
	#Else
		Items.MainPages_BackgroundJob.Visible = False;
	 	ShowMessageBox(,"Background job cant be configured on mobile client!");
	#EndIf
	SynchronizationRoomPricesOnChangeAtServer();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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

// -----------------------------------------------------------------------------
&AtClient
Procedure SynchronizationRoomPricesOnChange(pItem)
	SynchronizationRoomPricesOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow Then
		vNewRow = Items.RoomRates.CurrentData;
		vNewRow.InnerCode = "";
	EndIf;	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Sync(Command)
	SyncAtServer();
	
	// Processing completed
	ShowMessageBox(, NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	
	Save_AtServer();
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(pCommand)
	#If NOT MobileClient Then
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
	#Else
	 	ShowMessageBox(,"Background job cant be configured on mobile client!");
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GenerateID(pCommand)
	InteractionID = String(New UUID);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		SaveInteractionParameters();
			
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
		CommitTransaction();
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage("Failed to save:" + vError);
		RollbackTransaction();
	EndTry;
		
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	vInteraction = Object.ExternalInteraction;
	If Not ValueIsFilled(vInteraction) Then
		Return;
	EndIf;
	
	vIntParObj = vInteraction.GetObject();
	vIntParObj.Hotel 					= Hotel;
	vIntParObj.Allotment 				= Allotment;
	vIntParObj.IsActive 				= Active;
	vIntParObj.DebugMode 				= Debug;
	vIntParObj.Login 					= Username;	
	vIntParObj.Password 				= Password;	
	vIntParObj.InteractionID 			= InteractionID;
	vIntParObj.ActiveFromDate 			= ActiveFromDate;
	vIntParObj.ActiveToDate 			= ActiveToDate;
	vIntParObj.FullSynchronizationTime	= FullSynchronizationTime;
	vIntParObj.IsByAllotments			= IsByAllotments;
	vIntParObj.IsByCheckInPeriods		= IsByCheckInPeriods;
	vIntParObj.MaxLogLenght				= MaxLogLenght; 
	vIntParObj.UniqueProfilesControl	= UniqueProfilesControl;
	
	vIntParObj.Write();
	
	// Save room rates mapping
	vListMapping = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "RoomRates");
	vRoomRatesIsEmpty = vListMapping.Count() = 0;
	For Each vRoomRateRow In RoomRates Do
		vUUID = String(New UUID);
		vRoomRate = vRoomRateRow.RoomRate;
		vPriceTag = vRoomRateRow.PriceTag;
		If vRoomRatesIsEmpty Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, vRoomRate.Metadata().Name, vRoomRate.Metadata().Synonym, vRoomRate, vPriceTag, vUUID);
		Else
			If IsBlankString(vRoomRateRow.InnerCode) Then
				InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, vRoomRate.Metadata().Name, vRoomRate.Metadata().Synonym, vRoomRate, vPriceTag, vUUID);
			Else	
				vUUID = vRoomRateRow.InnerCode;
				vRateRows = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "RoomRates",,,, vUUID);
				If vRateRows.Count() = 0 Then
					InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, vRoomRate.Metadata().Name, vRoomRate.Metadata().Synonym, vRoomRate, vPriceTag, vUUID );
				Else
					vMGR = vRateRows[0];
					InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, vRoomRate.Metadata().Name, vRoomRate.Metadata().Synonym, vRoomRate, vPriceTag, vUUID, vRateRows[0].ExternalSystemDataCode);
				EndIf;	
			EndIf;
		EndIf;
	EndDo;
	
	// Delete old refs
	For Each vListRow In vListMapping Do
		vFilterRows = RoomRates.FindRows(New Structure("RoomRate, PriceTag", vListRow.RefKey1,vListRow.RefKey2));
		If vFilterRows.Count() = 0 Then 
			vRmg = InformationRegisters.ExternalSystemIntegrationData.CreateRecordManager(); 
			FillPropertyValues(vRmg, vListRow);
			vRmg.Delete();
		EndIf;
	EndDo;
	
	// Save room rates mapping
	vListMapping = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "ServiceGroups");
	vServicePackagesIsEmpty = vListMapping.Count() = 0;
	For Each vServiceRow In AdditionalServices Do
		vUUID = String(New UUID);
		vServicePackage = vServiceRow.ServicePackages;
		vDiscount = vServiceRow.Discount;
		If vServicePackagesIsEmpty Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "ServiceGroups", vServicePackage.Metadata().Synonym, vServicePackage, vDiscount, vUUID);
		Else
			If IsBlankString(vServiceRow.InnerCode) Then
				InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "ServiceGroups", vServicePackage.Metadata().Synonym, vServicePackage, vDiscount, vUUID);
			Else	
				vUUID = vServiceRow.InnerCode;
				vServiceGroupsRows = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "ServiceGroups",,,, vUUID);
				If vServiceGroupsRows.Count() = 0 Then
					InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "ServiceGroups", vServicePackage.Metadata().Synonym, vServicePackage, vDiscount, vUUID );
				Else
					vMGR = vServiceGroupsRows[0];
					InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "ServiceGroups", vServicePackage.Metadata().Synonym, vServicePackage, vDiscount, vUUID, vServiceGroupsRows[0].ExternalSystemDataCode);
				EndIf;	
			EndIf;
		EndIf;
	EndDo;

	// Delete old refs
	For Each vListRow In vListMapping Do
		vFilterRows = AdditionalServices.FindRows(New Structure("ServicePackages, Discount", vListRow.RefKey1,vListRow.RefKey2));
		If vFilterRows.Count() = 0 Then 
			vRmg = InformationRegisters.ExternalSystemIntegrationData.CreateRecordManager(); 
			FillPropertyValues(vRmg, vListRow);
			vRmg.Delete();
		EndIf;
	EndDo;

	// Room quota
	If ValueIsFilled(Allotment) Then
		cmClearExternalSystemObjectMapping(vInteraction.Hotel, vInteraction.InteractionID, Allotment.Metadata().Name);  
		cmSaveExternalSystemObjectMapping(vInteraction.Hotel, vInteraction.InteractionID, Allotment.Metadata().Name, TrimAll(Allotment.Code), TrimAll(Allotment.Code));
	Else
		cmClearExternalSystemObjectMapping(vInteraction.Hotel, vInteraction.InteractionID, Allotment.Metadata().Name);  
	EndIf;	
	
	// Refresh
	LoadInteractionParameters();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	vInteraction = Object.ExternalInteraction;
	If Not ValueIsFilled(vInteraction) Then
		Return;
	EndIf;
	
	Hotel  						= vInteraction.Hotel;
	Allotment  					= vInteraction.Allotment;
	Active  					= vInteraction.IsActive;
	Debug  						= vInteraction.DebugMode;
	Username  					= vInteraction.Login;	
	Password  					= vInteraction.Password;
	InteractionID				= vInteraction.InteractionID;
	ActiveFromDate  			= vInteraction.ActiveFromDate;
	ActiveToDate				= vInteraction.ActiveToDate;
	FullSynchronizationTime		= vInteraction.FullSynchronizationTime;
	LastFullSynchronizationTime	= vInteraction.LastFullSynchronizationTime;
	SessionLastActivityTime		= vInteraction.SessionLastActivityTime;
	IsByAllotments				= vInteraction.IsByAllotments;
	IsByCheckInPeriods			= vInteraction.IsByCheckInPeriods;
	MaxLogLenght                = vInteraction.MaxLogLenght;
	UniqueProfilesControl       = vInteraction.UniqueProfilesControl; 
	
	// Fill room rates
	RoomRates.Clear();
	vRoomRatesList = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "RoomRates");
	For Each vRoomRateRow In vRoomRatesList Do
		vNewRow = RoomRates.Add();
		vNewRow.RoomRate = vRoomRateRow.RefKey1;
		vNewRow.PriceTag = vRoomRateRow.RefKey2;
		vNewRow.InnerCode = vRoomRateRow.DataValue;
	EndDo;
	
	// Fill service group
	AdditionalServices.Clear();
	vServiceGroupsList = InformationRegisters.ExternalSystemIntegrationData.GetDataList(vInteraction, "ServiceGroups");
	For Each vServiceGroupRow In vServiceGroupsList Do
		vNewRow = AdditionalServices.Add();
		vNewRow.ServicePackages = vServiceGroupRow.RefKey1;
		vNewRow.Discount = vServiceGroupRow.RefKey2;
		vNewRow.InnerCode = vServiceGroupRow.DataValue;
	EndDo;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SyncAtServer()
	Obj = FormAttributeToValue("Object");
	Obj.pmRun(, True);
EndProcedure

// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure SetupBackgroundJobSchedule_AtServer(pRead = False)
	If Not CheckFilling() Then
		UseBackgroundJob = False;
	EndIf;
	
	Try
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key",Object.DataProcessor.Key));
		
		If ArrayScheduledJob.Count() > 0 Then
			ScheduledJob = ArrayScheduledJob[0];
			
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
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SynchronizationRoomPricesOnChangeAtServer()
	Items.ForceFullRoomPricesSynchronization.Enabled = Object.SynchronizationRoomPrices;
	If Not Object.SynchronizationRoomPrices Then
		Object.ForceFullRoomPricesSynchronization = False;
	EndIf;	
EndProcedure

#EndRegion




