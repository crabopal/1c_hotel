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
		Obj.ExternalInteraction = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	LoadInteractionParameters();
	
	If IsInRoleAtServer("Administrator") And Not(vDataProcessor = Undefined) Then
		SetupBackgroundJobSchedule_AtServer(True);
		
		If UseBackgroundJob Then
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
		Else 
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
		EndIf;
	Else
		Items.Group_Page_BackgroundJob.Visible = False;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'"));
	EndIf;
EndProcedure // OnCreateAtServer

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
	If NOT Active Then
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
EndProcedure // UseBackgroundJobOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure // Save

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
Procedure CreateRoomInterfaceTypes(pCommand)
	ActionsLoadDefaultSettingRecordsAtServer("DoorLockSystem");
EndProcedure // CreateRoomInterfaceTypes

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	ActionsExecuteAtServer();
	ShowMessageBox(,NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure // ActionsExecute

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction // IsInRoleAtServer

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

// -----------------------------------------------------------------------------
&AtServer
Procedure SetupBackgroundJobSchedule_AtServer(pRead = False)
	If NOT CheckFilling() Then
		UseBackgroundJob = False;
	EndIf;
	
	Try
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", Object.DataProcessor.Key));
		
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
				
				If ScheduledJob.Parameters.Count() = 0 Then
					ScheduledJob.Parameters.Add(Object.DataProcessor.Key);
				EndIf;
				
				ScheduledJob.Write();
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
			
			ScheduledJob.Write();
		EndIf;
	Except
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);	
	EndTry;
EndProcedure // SetupBackgroundJobSchedule_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsLoadDefaultSettingRecordsAtServer(pName)
	vRITList = DataProcessors.iLocksOnlineDoorLockSystemDriver.GetTemplate(pName);
	vCount = vRITList.TableHeight - 1;
	For i = 2 To (vCount + 1) Do
		Try
			vCode = TrimAll(vRITList.Area(i, 1, i, 1).Text);
			vRITRef = Catalogs.RoomInterfaceTypes.FindByCode(vCode, False);
			If ValueIsFilled(vRITRef) Then
				vRITObj = vRITRef.GetObject();
			Else
				vRITObj = Catalogs.RoomInterfaceTypes.CreateItem();
			EndIf;
			vRITObj.Code = vCode;
			vRITObj.Hotel = ?(ValueIsFilled(Hotel), Hotel, SessionParameters.CurrentHotel);
			vRITObj.Description = NStr(TrimAll(vRITList.Area(i, 2, i, 2).Text));
			vRITObj.Remarks = TrimAll(vRITList.Area(i, 3, i, 3).Text);
			vRITObj.TurnOnParameters = TrimAll(vRITList.Area(i, 4, i, 4).Text);
			vRITObj.TurnOffParameters = TrimAll(vRITList.Area(i, 5, i, 5).Text);
			vRITObj.PeriodOfStayExtentionParameters = TrimAll(vRITList.Area(i, 6, i, 6).Text);
			vRITObj.GuestNameChangeParameters = TrimAll(vRITList.Area(i, 7, i, 7).Text);
			vRITObj.RoomChangeParameters = TrimAll(vRITList.Area(i, 8, i, 8).Text);
			vRITObj.ManualCancelIsForbidden = Boolean(TrimAll(vRITList.Area(i, 9, i, 9).Text));
			vRITObj.InterfaceType = Enums.InterfaceTypes[TrimAll(vRITList.Area(i, 10, i, 10).Text)];
			vRITObj.ApplyToAllRoomGuests = Boolean(TrimAll(vRITList.Area(i, 11, i, 11).Text));
			vRITObj.Write();
			Object.RoomInterfaceType = vRITObj.Ref;
		Except
			vErrorInfo = ErrorInfo(); 
			tcCommonFunctionOnClientServer.TextMessage(ErrorProcessing.BriefErrorDescription(vErrorInfo));
		EndTry;
	EndDo;
EndProcedure // ActionsLoadDefaultSettingRecords

// -----------------------------------------------------------------------------
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
EndProcedure // Save_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	vIntParObj						= Object.ExternalInteraction.GetObject();
	vIntParObj.IsActive				= Active;
	vIntParObj.Hotel				= Hotel;
	vIntParObj.DebugMode			= Debug;
	vIntParObj.Login					= Login;
	vIntParObj.Password				= Password;
	vIntParObj.HttpServer			= HttpServer;
	vIntParObj.HttpUseSsl			= HttpUseSsl;
	vIntParObj.MaxLogLenght			= MaxLogLenght;
	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	Hotel					= Object.ExternalInteraction.Hotel;
	Active					= Object.ExternalInteraction.IsActive;
	Debug					= Object.ExternalInteraction.DebugMode;
	OAuth_AccessToken	= Object.ExternalInteraction.OAuth_AccessToken;
	OAuth_RefreshToken 	= Object.ExternalInteraction.OAuth_RefreshToken;
	Login 					= Object.ExternalInteraction.Login;
	Password				= Object.ExternalInteraction.Password;
	SessionStartTime		= Object.ExternalInteraction.SessionStartTime;
	HttpServer				= Object.ExternalInteraction.HttpServer;
	HttpUseSsl				= Object.ExternalInteraction.HttpUseSsl;
	MaxLogLenght			= Object.ExternalInteraction.MaxLogLenght;
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsExecuteAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmRun();
	ValueToFormAttribute(vObj,"Object");
EndProcedure // ActionsExecuteAtServer

#EndRegion
