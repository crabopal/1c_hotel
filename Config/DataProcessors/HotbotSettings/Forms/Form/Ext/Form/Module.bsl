
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)

	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	
	If Not ValueIsFilled(Obj.InteractionParameters) And ValueIsFilled(vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
		Obj.pmSaveDataProcessorAttributes();
	ElsIf Not ValueIsFilled(Obj.InteractionParameters) Then
		pCancel = True;
	EndIf;
	ValueToFormAttribute(Obj, "Object");
	
	FillPropertyValues(ThisForm, Object.InteractionParameters);
	
	LoadMappingTable(ReservationStatusesMapping, 	"ReservationStatuses");
	LoadMappingTable(AccommodationStatusesMapping, 	"AccommodationStatuses");
	LoadMappingTable(RoomTypesMapping, 				"RoomTypes");
	LoadMappingTable(CurrenciesMapping, 			"Currencies");
	LoadMappingTable(RoomRatesMapping, 				"RoomRates");
	LoadMappingTable(AccommodationTemplatesMapping, "AccommodationTemplates");

	If  IsInRoleAtServer("Administrator") And Not(vDataProcessor = Undefined) Then
		
		SetupBackgroundJobSchedule_AtServer(True);
		
		If UseBackgroundJob Then
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
		Else 
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
		EndIf;
	Else
		Items.Group_Page_BackgroundJob.Visible = False;
		tcCommonFunctionOnClientServer.TextMessage("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'");
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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
EndProcedure // UseBackgroundJobOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	
	If CheckFilling() Then
		Save_AtServer();
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GenerateToken(pCommand)
	
	InteractionID = String(New UUID);
	
EndProcedure

// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandRun(Command)
	CommandRunAtServer();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	
	Try
		BeginTransaction();
		
		vObj = Object.InteractionParameters.GetObject();
		FillPropertyValues(vObj, ThisForm);
		vObj.Write();
		
		SaveMappingTable(ReservationStatusesMapping, 	"ReservationStatuses");
		SaveMappingTable(AccommodationStatusesMapping, 	"AccommodationStatuses");
		SaveMappingTable(RoomTypesMapping, 				"RoomTypes");
		SaveMappingTable(CurrenciesMapping, 			"Currencies");
		SaveMappingTable(RoomRatesMapping, 				"RoomRates");
		SaveMappingTable(AccommodationTemplatesMapping, "AccommodationTemplates");

		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError);
	EndTry;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveMappingTable(pTable, pObjectTypeName)
	
	If pTable.Count() > 0 Then
				
		For each vRow in pTable Do
			vRecMng 					= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vRecMng.Hotel 				= Hotel;
			vRecMng.ExternalSystemCode 	= Code;
			vRecMng.ObjectTypeName 		= pObjectTypeName;
			vRecMng.ObjectExternalCode 	= vRow.ExternalCode;
			vRecMng.ObjectRef 			= vRow.Ref;
			vRecMng.Write(True);
		EndDo;		
				
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadMappingTable(pTable, pObjectTypeName)
	
	pTable.Clear();
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	CASE
		|			WHEN &HotelFilled
		|				THEN ExternalSystemsObjectCodesMappings.Hotel = &Hotel
		|			ELSE TRUE
		|		END
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName";
	
	vQuery.SetParameter("Hotel", 				Hotel);
	vQuery.SetParameter("HotelFilled", 			ValueIsFilled(Hotel));
	vQuery.SetParameter("qExternalSystemCode", 	Code);
	vQuery.SetParameter("qObjectTypeName", 		pObjectTypeName);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vNewRow 				= pTable.Add();
		vNewRow.ExternalCode 	= vSelectionDetailRecords.ObjectExternalCode;
		vNewRow.Ref 			= vSelectionDetailRecords.ObjectRef;
	EndDo;
		
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction // IsInRoleAtServer

// -----------------------------------------------------------------------------
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
EndProcedure // SetupBackgroundJobSchedule_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandRunAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmRun();
	ValueToFormAttribute(vObj,"Object");
	tcCommonFunctionOnClientServer.TextMessage(NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
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
EndProcedure // SetupBackgroundJobSchedule_AfterInput

#EndRegion  

