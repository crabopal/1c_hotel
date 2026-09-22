
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	vObj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		vObj.DataProcessor = vDataProcessor;
	EndIf;
	vObj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(vObj, "Object");
	
	UseBackgroundJob = False;
	If IsInRoleAtServer("Administrator") And ValueIsFilled(vDataProcessor) Then
		SetupBackgroundJobSchedule_AtServer(True);
		If UseBackgroundJob Then
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
		Else 
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
		EndIf;
	Else
		Items.MainPage_BackgroundJob.Visible = False;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'"));
	EndIf;
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
    	vObj.pmRun();
    	pCancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandExecute(pCommand)
	ExecuteAtServer();
	ShowMessageBox(,NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure // CommandExecute

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(pCommand)
	If ValueIsFilled(Employee)  Then
		If Not IsInRoleAtServer("Administrator") Then
			Raise(NStr("en='A background job can be configured by system administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
		Else 				
			vScheduleDlg = New ScheduledJobDialog(Object.Schedule);
			
			vScheduleDlg.Show(New NotifyDescription("SetupBackgroundJobSchedule_AfterInput", ThisForm, New Structure()));		
		EndIf;
	Else 
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure UseBackgroundJobOnChange(pItem)	
	If ValueIsFilled(Employee) Then
		If Object.Schedule <> Undefined Then
			vDPKey = CheckAndCreateDPKeyAtServer();
			If UseBackgroundJob Then
				If Not IsInRoleAtServer("Administrator") Then
					Raise(NStr("en='A background job should be configured by administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
				EndIf;
				Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
			Else 
				Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
			EndIf;
			Save_AtServer();
			If Not IsBlankString(vDPKey) Then
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
&AtServer
Function CheckAndCreateDPKeyAtServer()
	If UseBackgroundJob And IsBlankString(Object.DataProcessor.Key) Then
		dpObj = Object.DataProcessor.GetObject();
		dpObj.Key = String(Object.DataProcessor.UUID());
		dpObj.Write();
		
		Object.DataProcessor = dpObj.Ref;
	EndIf;
	Return Object.DataProcessor.Key;
EndFunction // CheckAndCreateDPKeyAtServer

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ExecuteAtServer()
	// If changed, then save settings
	Save_AtServer();
	// Run processing
	vObj = FormAttributeToValue("Object");
	vObj.pmWriteOffBonuses(True);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		// Save DP parameters
		vObj = FormAttributeToValue("Object");
		vObj.pmSaveDataProcessorAttributes();

		CommitTransaction();
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage("Failed to save:" + vError);
		RollbackTransaction();
	EndTry;
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
Procedure SetupBackgroundJobSchedule_AtServer(pRead = False)
	If Not CheckFilling() Then
		UseBackgroundJob = False;
	EndIf;
	If Not ValueIsFilled(Object.DataProcessor.Key) Then
		UseBackgroundJob = False;
	EndIf;
	
	Try
		If ValueIsFilled(Object.DataProcessor.Key) Then
			ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", Object.DataProcessor.Key));
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
		EndIf;
	Except	
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);	
	EndTry;
EndProcedure // SetupBackgroundJobSchedule_AtServer

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

#EndRegion

 