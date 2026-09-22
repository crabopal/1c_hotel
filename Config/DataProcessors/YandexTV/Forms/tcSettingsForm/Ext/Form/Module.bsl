
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
	ValueToFormAttribute(Obj,"Object");  
	
	LoadInteractionParameters();
	
	#If NOT MobileClient Then
		If tcOnServer.cmIsInRole("Administrator") And vDataProcessor <> Undefined Then
			If IsBlankString(vDataProcessor.Key) Then
				dpObj = vDataProcessor.GetObject();
				dpObj.Key = String(vDataProcessor.UUID());
				dpObj.Write();
			EndIf;	
			SetupBackgroundJobSchedule_AtServer(True);
			
			If UseBackgroundJob Then     
				vMsg = NStr("en = 'Background job is configured and started'; 
														  |de = 'Ein Hintergrundjob ist konfiguriert und läuft'; 
														  |ru = 'Фоновое задание настроено и запущено'");
				Items.Text_BackgroundJobInfo.Title = vMsg;
			Else             
				vMsg = NStr("en = 'Background job not started'; de = 'Ein Hintergrundjob nicht läuft'; ru = 'Фоновое задание не запущено'");
				Items.Text_BackgroundJobInfo.Title = vMsg;
			EndIf;
		Else
			Items.MainPages_BackgroundJob.Visible = False;   
			vMsg = NStr("en = 'You do not have rights to configure background job!'; 
						|de = 'Einen Hintergrundjob Einstellung ist nicht zulässig!'; 
						|ru = 'Нет прав для настройки фонового задания!'");
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
		EndIf;
	#Else
		Items.MainPages_BackgroundJob.Visible = False; 
		vErr =  NStr("en = 'Background job can`t be configured on mobile client!'; 
					 |de = 'Hintergrundjob kann nicht auf mobilem Client konfiguriert werden!'; 
					 |ru = 'Фоновое задание не может быть настроено на мобильном клиенте!'");
	 	tcCommonFunctionOnClientServer.TextMessage(vErr);
	#EndIf	  
	
	SetVisible();
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
Procedure TypeOnChange(Item)
	SetVisible();
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

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateRoomInterfaceTypes(pCommand)
	CreateRoomInterfaceTypes_AtServer();    
	tcCommonFunctionOnClientServer.UserMessage(Nstr("en = 'Done!'; de = 'Erledigt!'; ru = 'Выполнено!'"));
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
	vInteraction = Object.InteractionParameters;
	If Not ValueIsFilled(vInteraction) Then
		Return;
	EndIf;
	
	vIntParObj = vInteraction.GetObject();
	vIntParObj.Hotel 			= Hotel;  
	vIntParObj.Allotment        = Allotment;
	vIntParObj.IsActive 		= Active;
	vIntParObj.DebugMode 		= Debug;
	vIntParObj.InteractionID 	= InteractionID;
	vIntParObj.MaxLogLenght		= MaxLogLenght; 
	vIntParObj.EmailAccount     = EmailAccount;
	vIntParObj.WSHost           = TrimAll(RecipientEmail);   
	vIntParObj.OAuth_AccessToken= OAuthToken;   
	vIntParObj.HttpServer 		= HTTPServer;
	vIntParObj.HTTPUseSSL		= HTTPUseSSL;
	vIntParObj.Write();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	vInteraction = Object.InteractionParameters;
	If Not ValueIsFilled(vInteraction) Then
		Return;
	EndIf;
	
	Hotel  						= vInteraction.Hotel;
	Active  					= vInteraction.IsActive;
	Debug  						= vInteraction.DebugMode;
	Allotment                   = vInteraction.Allotment;
	InteractionID				= vInteraction.InteractionID;
	LastFullSynchronizationTime	= vInteraction.LastFullSynchronizationTime;
	SessionLastActivityTime		= vInteraction.SessionLastActivityTime;
	MaxLogLenght                = vInteraction.MaxLogLenght;
	EmailAccount				= vInteraction.EmailAccount;
	RecipientEmail				= vInteraction.WSHost;
	OAuthToken				    = vInteraction.OAuth_AccessToken;   
	HTTPServer				    = vInteraction.HTTPServer; 
	HTTPUseSSL				    = vInteraction.HTTPUseSSL; 
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
Procedure SetVisible()     
	vTitle = "";
	If Object.Type = 1 Then
		Items.Group_GeneralSettingsForFile.Visible = True;
		Items.Group_GeneralSettingsForAPI.Visible = False;
		vTitle = Nstr("en = 'By clicking the ""Sync"" button, available hotel rooms are synchronized with Yandex TV'; 
					  |de = 'Durch Klicken auf die Schaltfläche „Synchronisieren“ werden verfügbare Hotelzimmer mit Yandex TV synchronisiert'; 
					  |ru = 'По нажатию кнопки «Синхронизировать» свободные номера отеля выгружаются в сервис Яндекс. И далее проиходит сброс станции в свободном номере.'");   
		Items.Decoration.Title = vTitle;
	Else	
		Items.Group_GeneralSettingsForFile.Visible = False;
		Items.Group_GeneralSettingsForAPI.Visible = True; 
		vTitle = Nstr("en = 'By pressing the ""Synchronize"" button, Yandex stations, departed guests will be reset'; 
					  |de = 'Durch Drücken der Schaltfläche „Synchronisieren“ werden die Yandex-Stationen und abgereisten Gäste zurückgesetzt'; 
					  |ru = 'По нажатию кнопки «Синхронизировать», будут сброшены Яндекс станции, выехавших гостей'");	
	EndIf;    
	Items.Decoration.Title = vTitle;
EndProcedure // SetVisible()

// -----------------------------------------------------------------------------
&AtServer
Procedure CreateRoomInterfaceTypes_AtServer()
		vCode = "YSTN";
		vRITRef = Catalogs.RoomInterfaceTypes.FindByCode(vCode, False);
		If ValueIsFilled(vRITRef) Then
			vRITObj = vRITRef.GetObject();
		Else
			vRITObj = Catalogs.RoomInterfaceTypes.CreateItem();
		EndIf;
		vRITObj.Code = vCode;
		vRITObj.ExternalSystem = Object.InteractionParameters;
		vRITObj.InterfaceType = Enums.InterfaceTypes.Yandex;
		vRITObj.Description = NStr("en = 'Yandex station'; de = 'Yandex-Station'; ru = 'Яндекс станция'");
		vRITObj.Remarks = "";
		vRITObj.TurnOnParameters = "/b2b/api/public/rooms/activate";
		vRITObj.TurnOffParameters = "/b2b/api/public/rooms/reset";
		vRITObj.Write(); 
EndProcedure // CreateRoomInterfaceTypes_AtServer

#EndRegion   

