   
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
		vDataProcessor = Catalogs.DataProcessors.FindByAttribute("Processing","GuestJoyExport");
		If vDataProcessor = Catalogs.DataProcessors.EmptyRef() Then
			vNewDP 				= Catalogs.DataProcessors.CreateItem();
			vNewDP.Description 	= "GuestJoyExport";
			vNewDP.Key 			= "GuestJoyExport_" + String(New UUID);;
			vNewDP.Processing 	= "GuestJoyExport_";
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
	
	If IsInRoleAtServer("Administrator") AND vDataProcessor <> Undefined Then
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
		tcCommonFunctionOnClientServer.TextMessage("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'");
	EndIf;

	
	FillPropertyValues(ThisForm, Obj.InteractionParameters);
	
	LoadMappingsTable(ReservationStatusesMapping, 	"reservationStatuses");
	LoadMappingsTable(AccommodationStatusesMapping, "accommodationStatuses");
	LoadMappingsTable(RoomTypesMapping, 			"roomTypes");
	LoadMappingsTable(CurrenciesMapping, 			"currencies");
	LoadMappingsTable(RoomRatesMapping, 			"roomRates");
	LoadMappingsTable(AccommodationTemplatesMapping,"AccommodationTemplates");
	
	If NOT ValueIsFilled(HTTPServer) Then
		HTTPServer = "api.guestjoy.com";
	EndIf;
	
	If NOT ValueIsFilled(HTTPAddress) Then
		HTTPAddress = "guest-import/pms/file";
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
	
EndProcedure

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

// -----------------------------------------------------------------------------
&AtClient
Procedure ExportData(pCommand)
	
	ExportDataAtServer();
	
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function Save_AtServer()
	
	If NOT CheckFilling()Then
		Return False;
	EndIf;
	
	Try
		BeginTransaction();
		
		vObj = Object.InteractionParameters.GetObject();
		FillPropertyValues(vObj, ThisForm);
		vObj.Write();
		
		SaveMappingsTable(ReservationStatusesMapping, 	"reservationStatuses");
		SaveMappingsTable(AccommodationStatusesMapping, "accommodationStatuses");
		SaveMappingsTable(RoomTypesMapping, 			"roomTypes");
		SaveMappingsTable(CurrenciesMapping, 			"currencies");
		SaveMappingsTable(RoomRatesMapping, 			"roomRates");
		SaveMappingsTable(AccommodationTemplatesMapping,"AccommodationTemplates");

		CommitTransaction();
	Except
		RollbackTransaction();
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError);
		
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveMappingsTable(pTable, pDataType)
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, pDataType);
	
	For each vTableRow in pTable Do
		If ValueIsFilled(vTableRow.Ref) AND ValueIsFilled(vTableRow.ExternalCode) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, pDataType, "id", vTableRow.Ref, Undefined, vTableRow.ExternalCode, vTableRow.ExternalCode);
		EndIf;
	EndDo;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadMappingsTable(pTable, pDataType)
	
	vTable = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, pDataType);
	
	If vTable.Count() > 0 Then		
		For each vTableRow in vTable Do
			vNewRow 				= pTable.Add();
			vNewRow.Ref 			= vTableRow.RefKey1;
			vNewRow.ExternalCode 	= vTableRow.id;
		EndDo;
	EndIf;
	
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
	If NOT pRead Then 
		If NOT CheckFilling() Then
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
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ExportDataAtServer()
	
	If Save_AtServer() Then
		Obj = FormAttributeToValue("Object");
		Obj.ExportData();
	EndIf;

EndProcedure

#EndRegion   

