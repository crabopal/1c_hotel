
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	Else
		vDataProcessor = Catalogs.DataProcessors.FindByAttribute("Processing","ExportOrdersToExternalSystem");
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
				dpObj.Key = String(vDataProcessor.UUID());
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
	Items.ActiveDays.Visible = Not Object.DoNotUseOrderTime;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	ChangeActiveDaysToolTip()
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	
	If Debug Then
		Active = True;
	EndIf;
		
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	
	If NOT Active Then
		Debug = False;
	EndIf;
	
EndProcedure

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
Procedure ActiveDaysOnChange(Item)
	ChangeActiveDaysToolTip();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DoNotUseOrderTimeOnChange(Item)
	Items.ActiveDays.Visible = Not Object.DoNotUseOrderTime;
	If Object.DoNotUseOrderTime Then
		ActiveDays = 0;
	EndIf;	
	ChangeActiveDaysToolTip();
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
Procedure ActionsExecute(pCommand)
	ActionsExecuteAtServer();
	ShowMessageBox(,NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure // ActionsExecute

// -----------------------------------------------------------------------------
&AtClient
Procedure GenerateID(Command)
	InteractionID = String(New UUID);
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
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

// --------------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	
	If NOT CheckFilling() Then
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

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	vIntParObj 					= Object.ExternalInteraction.GetObject();
	vIntParObj.Hotel 			= Hotel;
	vIntParObj.ActiveDays 		= ActiveDays;
	vIntParObj.IsActive 		= Active;
	vIntParObj.DebugMode 		= Debug;
	vIntParObj.Login 			= Username;	
	vIntParObj.Password 		= Password;	
	vIntParObj.WebhookURL 		= HttpAddress;
	vIntParObj.HttpServer       = HttpServer;
	vIntParObj.HttpPort         = HttpPort;
	vIntParObj.HttpUseSsl       = HttpUseSsl;
	vIntParObj.InteractionID    = InteractionID;
	vIntParObj.LastFullSynchronizationTime = LastFullSynchronization;
	vIntParObj.Write();
	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	Hotel  			= Object.ExternalInteraction.Hotel;
	ActiveDays  	= Object.ExternalInteraction.ActiveDays;
	Active  		= Object.ExternalInteraction.IsActive;
	Debug  			= Object.ExternalInteraction.DebugMode;
	Username  		= Object.ExternalInteraction.Login;	
	Password  		= Object.ExternalInteraction.Password;
	HttpAddress		= Object.ExternalInteraction.WebhookURL;
	HttpServer      = Object.ExternalInteraction.HttpServer;
	HttpPort        = Object.ExternalInteraction.HttpPort;
	HttpUseSsl      = Object.ExternalInteraction.HttpUseSsl;
	InteractionID   = Object.ExternalInteraction.InteractionID;
	LastFullSynchronization = Object.ExternalInteraction.LastFullSynchronizationTime;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

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

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsExecuteAtServer()
	// If changed, then save settings
	Save_AtServer();
	
	vObj = FormAttributeToValue("Object");
	vObj.Sync();
	ValueToFormAttribute(vObj,"Object");
	// After sync load actual settings
	LoadInteractionParameters();
EndProcedure // ActionsExecuteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeActiveDaysToolTip()
	Items.ActiveDays.ToolTip = "";
	If ActiveDays = 0  And Object.DoNotUseOrderTime = False Then
		vStr = Nstr("en = 'Orders with the execution date > %1 will be unloaded'; 
					|de = 'Aufträge mit dem Ausführungsdatum > %1 werden entladen'; 
					|ru = 'Будут выгружены заказы, у которых дата изменения больше %1'");
		Items.ActiveDays.ToolTip = StrTemplate(vStr,LastFullSynchronization);
	ElsIf 	ActiveDays > 0 And ValueIsFilled(LastFullSynchronization) Then
		vDateTo = EndOfDay(LastFullSynchronization + ActiveDays*86400); 
		vStr = Nstr("en = 'Orders with the execution date from %1 to %2 will be unloaded'; 
					|de = 'Aufträge mit dem Ausführungsdatum von %1 bis %2 werden entladen'; 
					|ru = 'Будут выгружены заказы у которых дата исполнения  с %1 по %2'");
		Items.ActiveDays.ToolTip = StrTemplate(vStr,LastFullSynchronization, vDateTo);
	EndIf;	
EndProcedure

#EndRegion




