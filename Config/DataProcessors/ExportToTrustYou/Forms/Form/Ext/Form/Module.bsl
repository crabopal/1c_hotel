
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
		
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
	
	UnloadPeriodFrom 	= Object.LastUnloadDate;
	UnloadPeriodTo		= CurrentSessionDate();
	
	If Object.Version = 0 Then
		Object.Version = 1;
	EndIf;
	
	If Object.FTPServerPort = 0 Then
		Object.FTPServerPort = 21;
	EndIf;
	
	UpdateItemsVisibility();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
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

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveTypeOnChange(pItem)
	UpdateItemsVisibility();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFilePathStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vFileDialog 			= New FileDialog(FileDialogMode.ChooseDirectory);
	vFileDialog.Multiselect = False;
	vFileDialog.Directory	= Object.SaveFilePath;
	vFileDialog.Show(New NotifyDescription("SaveFilePathStartChoice_AfterInput", ThisForm));
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFilePathStartChoice_AfterInput(pValue, pParameters) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	Object.SaveFilePath = pValue[0];	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure UnloadPeriodOnChange(pItem)
	If UnloadPeriodTo > CurrentDate() Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = '""Period to"" can''t be more than current date'; ru = '""Период по"" не может быть больше текущей даты'; de = '""Zeitraum bis"" kann nicht mehr als das aktuelle Datum sein'"));
		UnloadPeriodTo = CurrentDate();
	EndIf;
	If UnloadPeriodFrom > UnloadPeriodTo Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = '""Period from"" can''t be more than ""period to""'; ru = '""Период c"" не может быть больше, чем ""период по""'; de = '""Zeitraum von"" kann nicht mehr als ""Zeitraum bis"" sein'"));
		UnloadPeriodTo = UnloadPeriodFrom; 	
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
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

// --------------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule_AfterInput(pValue, pParameters) Export
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

// --------------------------------------------------------------------------------
&AtClient
Procedure Unload(pCommand)
	If ValueIsFilled(UnloadPeriodFrom) and ValueIsFilled(UnloadPeriodTo) Then
		Unload_AtServer();
	Else
		vUserMessage 		= New UserMessage;
		vUserMessage.Field 	= "UnloadPeriodFrom";
		vUserMessage.Text	= NStr("en = 'Choose period to unload!'; ru = 'Выберите период выгрузки!'; de = 'Wählen Sie einen Zeitraum zum Entladen aus!'");
		vUserMessage.Message();
		
		vUserMessage 		= New UserMessage;
		vUserMessage.Field 	= "UnloadPeriodTo";
		vUserMessage.Text	= NStr("en = 'Choose period to unload!'; ru = 'Выберите период выгрузки!'; de = 'Wählen Sie einen Zeitraum zum Entladen aus!'");
		vUserMessage.Message();
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	SetupBackgroundJobSchedule_AtServer();
	// Save DP parameters
	Obj = FormAttributeToValue("Object");
	Obj.pmSaveDataProcessorAttributes();
EndProcedure

// --------------------------------------------------------------------------------
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

// --------------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateItemsVisibility()
	If Object.SaveType = 0 Then //File
		Items.Group_Settings_SaveToFTP.Visible 	= False;
	ElsIf Object.SaveType = 1 Then //FTP-server
		Items.Group_Settings_SaveToFTP.Visible 	= True;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure Unload_AtServer()
	Obj = FormAttributeToValue("Object");
	Obj.Unload(UnloadPeriodFrom, UnloadPeriodTo);
	ValueToFormAttribute(Obj, "Object");
EndProcedure

#EndRegion




