
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	Else
		vDataProcessor = Catalogs.DataProcessors.FindByAttribute("Processing","SKK");
		If vDataProcessor = Catalogs.DataProcessors.EmptyRef() Then
			newDP = Catalogs.DataProcessors.CreateItem();
			newDP.Description = "SKK";
			newDP.Key = "SKK";
			newDP.Processing = "SKK";
			newDP.Write();
			vDataProcessor = newDP.Ref;
		EndIf;
	EndIf;
	
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	InteractionParameters 	= SKKConnect.GetInteractionParameters();
	LastSyncDate			= InteractionParameters.LastFullSynchronizationTime;
	MaxLogLenght			= InteractionParameters.MaxLogLenght;

	If ValueIsFilled(InteractionParameters) Then
		FillMilitaryRanks();
		LoadRoomRatesTable();
		ReservationStatusOrder 			= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), InteractionParameters.InteractionID, "ReservationStatusesDefault", "Order", False);
		ReservationStatusQuota 			= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), InteractionParameters.InteractionID, "ReservationStatusesDefault", InteractionParameters.InteractionID, False);
		ReservationStatusAnnulation		= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), InteractionParameters.InteractionID, "ReservationStatusesDefault", "GuestAnnulation", False);
		
		vDefaultReservationStatuses = InformationRegisters.ExternalSystemIntegrationData.GetData(InteractionParameters, "DefaultReservationStatus");	
		If vDefaultReservationStatuses.Count() > 0 Then
			DefaultReservationStatus 		= vDefaultReservationStatuses[0].RefKey1;
			DefaultReservationStatusCode	= cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), InteractionParameters.InteractionID, "ReservationStatuses", DefaultReservationStatus);  
		EndIf;

		vHotels = InformationRegisters.ExternalSystemIntegrationData.GetData(InteractionParameters, "Hotels");	
		For each vRow in vHotels Do
			vNewRow 		= Hotels.Add();
			vNewRow.Hotel 	= vRow.RefKey1;
			vNewRow.Code 	= vRow.ID;
		EndDo;
		
		vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(InteractionParameters, "RoomTypes");	
		For each vRow in vRoomTypes Do
			vNewRow 		 = RoomTypes.Add();
			vNewRow.RoomType = vRow.RefKey1;
			vNewRow.Hotel 	 = vRow.RefKey2;
		EndDo;
		
	EndIf;

	LoadClientTypesTable();
	
	If  IsInRoleAtServer("Administrator") And Not(vDataProcessor = Undefined) Then
		If IsBlankString(vDataProcessor.Key) Then
			dpObj = vDataProcessor.GetObject();
			dpObj.Key = "SKK";
			dpObj.Write();
		EndIf;	
		SetupBackgroundJobSchedule_AtServer(True);
		
		If UseBackgroundJob Then
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
		Else 
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
		EndIf;
	Else
		Items.MainPage_BackgroundJob.Visible = False;
		tcCommonFunctionOnClientServer.TextMessage("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'");
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseBackgroundJobOnChange(Item)	
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
				SaveAtServer();
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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	SaveAtServer();
EndProcedure

&AtClient
Procedure SetupBackgroundJobSchedule(Command)
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

&AtClient
Procedure SetLastSyncDate(Command)
	SetLastSyncDateAtServer();
EndProcedure

&AtClient
Procedure UpdateToken(Command)
	
	UpdateTokenAtServer();
	
EndProcedure

&AtClient
Procedure SendQuota(Command)
	SendQuotaAtServer();
EndProcedure

&AtClient
Procedure Subscribe(Command)
	SubscribeAtServer();
EndProcedure

&AtClient
Procedure Unubscribe(Command)
	UnubscribeAtServer();
EndProcedure

&AtClient
Procedure GetOrders(Command)
	GetOrdersAtServer();
EndProcedure

&AtClient
Procedure UpdateQuota(Command)
	UpdateQuotaAtServer();
EndProcedure

&AtClient
Procedure UpdateOrder(Command)
	UpdateOrderAtServer();
EndProcedure

&AtClient
Procedure GetReservationsToSync(Command)
	GetReservationsToSyncAtServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SaveAtServer()
	
	If NOT CheckFilling() Then
		Return;
	EndIf;
	
	vEmptyHotel = Catalogs.Hotels.EmptyRef();
	SaveMappingRow(vEmptyHotel, InteractionParameters.InteractionID, "ReservationStatusesDefault", "Order", ReservationStatusOrder);
	SaveMappingRow(vEmptyHotel, InteractionParameters.InteractionID, "ReservationStatusesDefault", InteractionParameters.InteractionID, ReservationStatusQuota);
	SaveMappingRow(vEmptyHotel, InteractionParameters.InteractionID, "ReservationStatusesDefault", "GuestAnnulation", ReservationStatusAnnulation);
	
	CleanMappingTable(vEmptyHotel, InteractionParameters.InteractionID, "MilitaryRanksActive");
	For each vRow in MilitaryRanksActive Do
		SaveMappingRow(vEmptyHotel, InteractionParameters.InteractionID, "MilitaryRanksActive", vRow.ID, vRow.ClientType, vRow.Description);
	EndDo;
	
	CleanMappingTable(vEmptyHotel, InteractionParameters.InteractionID, "MilitaryRanksInactive");
	For each vRow in MilitaryRanksInacctive Do
		SaveMappingRow(vEmptyHotel, InteractionParameters.InteractionID, "MilitaryRanksInactive", vRow.ID, vRow.ClientType, vRow.Description);
	EndDo;
			
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(InteractionParameters, "DefaultReservationStatus");
	If ValueIsFilled(DefaultReservationStatus) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "DefaultReservationStatus", "ID", DefaultReservationStatus, , "0", "0");
		SaveMappingRow(vEmptyHotel, InteractionParameters.InteractionID, "ReservationStatuses", DefaultReservationStatusCode, DefaultReservationStatus);
	EndIf;

	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(InteractionParameters, "Hotels");

	For each vRow in Hotels Do
		If ValueIsFilled(vRow.Hotel) AND ValueIsFilled(vRow.Code) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "Hotels", "ID", vRow.Hotel, , vRow.Code, vRow.Code);
		EndIf;
	EndDo;
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(InteractionParameters, "RoomTypes");

	For each vRow in RoomTypes Do
		If ValueIsFilled(vRow.RoomType) AND ValueIsFilled(vRow.Hotel) Then
			vUUID = String(New UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "RoomTypes", "ID", vRow.RoomType, vRow.Hotel , vUUID, vUUID);
		EndIf;
	EndDo;
	
	SaveRoomRatesTable();	
	SaveClientTypesTable();
	SaveInteractionParameters();
EndProcedure

&AtServer
Procedure CleanMappingTable(pHotel, pExternalSystemCode, pObjectTypeName)
	
	vRecSet 									= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordSet();
	vRecSet.Filter.Hotel.Value 					= pHotel;
	vRecSet.Filter.Hotel.Use 					= True;
	vRecSet.Filter.ExternalSystemCode.Value 	= pExternalSystemCode;
	vRecSet.Filter.ExternalSystemCode.Use 		= True;
	vRecSet.Filter.ObjectTypeName.Value 		= pObjectTypeName;
	vRecSet.Filter.ObjectTypeName.Use 			= True;
	vRecSet.Write(True);
	
EndProcedure

&AtServer
Procedure SaveMappingRow(pHotel, pExternalSystemCode, pObjectTypeName, pObjectExternalCode, pObjectRef, pObjectDescription = "")
	
	vRecMng 					= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
	vRecMng.Hotel 				= pHotel;
	vRecMng.ExternalSystemCode 	= pExternalSystemCode;
	vRecMng.ObjectExternalCode 	= pObjectExternalCode;
	vRecMng.ObjectTypeName 		= pObjectTypeName;
	vRecMng.ObjectRef 			= pObjectRef;
	vRecMng.ObjectDescription 	= pObjectDescription;
	vRecMng.Write(True);	
	
EndProcedure	

&AtServer
Procedure FillMilitaryRanks()
	
	vObjectTypeNames = New Array;
	vObjectTypeNames.Add("MilitaryRanksActive");
	vObjectTypeNames.Add("MilitaryRanksInactive");
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef,
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectDescription AS ObjectDescription
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName IN(&qObjectTypeName)";
	
	vQuery.SetParameter("qExternalSystemCode", InteractionParameters.InteractionID);
	vQuery.SetParameter("qHotel", Catalogs.Hotels.EmptyRef());
	vQuery.SetParameter("qObjectTypeName", vObjectTypeNames);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		If Upper(vSelectionDetailRecords.ObjectTypeName) = Upper("MilitaryRanksActive") Then
			vNewRow 			= MilitaryRanksActive.Add();
			vNewRow.ClientType 	= vSelectionDetailRecords.ObjectRef;
			vNewRow.ID 			= vSelectionDetailRecords.ObjectExternalCode;
			vNewRow.Description = vSelectionDetailRecords.ObjectDescription;
		ElsIf Upper(vSelectionDetailRecords.ObjectTypeName) = Upper("MilitaryRanksInactive") Then
			vNewRow 			= MilitaryRanksInacctive.Add();
			vNewRow.ClientType 	= vSelectionDetailRecords.ObjectRef;
			vNewRow.ID 			= vSelectionDetailRecords.ObjectExternalCode;
			vNewRow.Description = vSelectionDetailRecords.ObjectDescription;
		EndIf;
	EndDo;
		
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
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

&AtServer
Procedure SetupBackgroundJobSchedule_AtServer(pRead = False)
	If NOT CheckFilling() Then
		UseBackgroundJob = False;
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
EndProcedure

&AtServer
Procedure SetLastSyncDateAtServer()
	
	vObj = InteractionParameters.GetObject();
	vObj.LastFullSynchronizationTime = LastSyncDate;
	vObj.Write();

EndProcedure

&AtServer
Procedure SaveClientTypesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(InteractionParameters, "clienttypes");
	InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "DefaultClientType", "DefaultClientType", DefaultClientType, Undefined, "DefaultClientType", "DefaultClientType");
	For each vClientTypeRow in ClientTypes Do
		vUUID	= String(New UUID);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "clienttypes", "Applicant", 		vClientTypeRow.ClientType, Undefined, vClientTypeRow.Applicant, 		vUUID);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "clienttypes", "ClientTypeID", 		vClientTypeRow.ClientType, Undefined, vClientTypeRow.ClientTypeID, 		vUUID);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "clienttypes", "MilitaryGroupID", 	vClientTypeRow.ClientType, Undefined, vClientTypeRow.MilitaryGroupID, 	vUUID);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "clienttypes", "RelationID", 		vClientTypeRow.ClientType, Undefined, vClientTypeRow.RelationID,	 	vUUID);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "clienttypes", "AgeFrom", 			vClientTypeRow.ClientType, Undefined, vClientTypeRow.AgeFrom,	 		vUUID);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "clienttypes", "AgeTo", 			vClientTypeRow.ClientType, Undefined, vClientTypeRow.AgeTo,	 			vUUID);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "clienttypes", "MilitaryRankID", 	vClientTypeRow.ClientType, Undefined, vClientTypeRow.MilitaryRankID,	vUUID);	
	EndDo;

EndProcedure

&AtServer
Procedure LoadClientTypesTable()
	
	vClientTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(InteractionParameters, "clienttypes");
	
	For each vClientType in vClientTypes Do
		vNewRow = ClientTypes.Add();
		FillPropertyValues(vNewRow, vClientType);
		vNewRow.ClientType	= vClientType.RefKey1;
	EndDo;
	
	vClientTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(InteractionParameters, "DefaultClientType");
	If vClientTypes.Count() > 0 Then
		DefaultClientType = vClientTypes[0].RefKey1;	
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveRoomRatesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(InteractionParameters, "ExceptionalRoomRates");
	For each vRoomRateRow in FullPriceRoomRates Do
		InformationRegisters.ExternalSystemIntegrationData.WriteData(InteractionParameters, "ExceptionalRoomRates", "RoomRate", vRoomRateRow.Hotel, vRoomRateRow.ClientType, vRoomRateRow.RoomRate);
	EndDo;

EndProcedure

&AtServer
Procedure LoadRoomRatesTable()
	
	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(InteractionParameters, "ExceptionalRoomRates");
	
	For each vRoomRate in vRoomRates Do
		vNewRow = FullPriceRoomRates.Add();
		FillPropertyValues(vNewRow, vRoomRate);
		vNewRow.Hotel		= vRoomRate.RefKey1;
		vNewRow.ClientType	= vRoomRate.RefKey2;
	EndDo;
		
EndProcedure

&AtServer
Procedure UpdateTokenAtServer()
	
	SKKConnect.UpdateToken(InteractionParameters);
	
EndProcedure

&AtServer
Procedure SendQuotaAtServer()
	
	SKKConnect.SendQuota(InteractionParameters);
	
EndProcedure

&AtServer
Procedure SubscribeAtServer()
	
	SKKConnect.Subscribe(InteractionParameters);

EndProcedure

&AtServer
Procedure UnubscribeAtServer()
	
	SKKConnect.Unsubscribe(InteractionParameters);

EndProcedure

&AtServer
Procedure GetOrdersAtServer()
	
	SKKConnect.GetOrders(InteractionParameters);

EndProcedure

&AtServer
Procedure UpdateQuotaAtServer()
	
	SKKConnect.UpdateQuota(InteractionParameters);

EndProcedure

&AtServer
Procedure UpdateOrderAtServer()
	
	SKKConnect.UpdateOrder(InteractionParameters, Reservation);

EndProcedure

&AtServer
Procedure GetReservationsToSyncAtServer()
	If ValueIsFilled(PeriodFrom) Then
		ReservationsToSync.Clear();
		vReservations = SKKConnect.GetReservationsToUpdate(PeriodFrom, InteractionParameters);
		For each vRow in vReservations Do
			ReservationsToSync.Add(vRow);
		EndDo;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(InteractionParameters) Then
		Return;
	EndIf;
		
	vIntParObj 				 = InteractionParameters.GetObject();
	vIntParObj.MaxLogLenght  = MaxLogLenght;

	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

&AtClient
Procedure AnnulQuota(Command)
	SKKConnect.AnnulQuota(InteractionParameters);
EndProcedure

#EndRegion


