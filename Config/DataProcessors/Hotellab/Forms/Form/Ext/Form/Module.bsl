
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
			
	If  IsInRoleAtServer("Administrator") And Not(Object.DataProcessor = Undefined) Then
		
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
	Refresh();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	If Object.UseToExportPrices Then
		pCheckedAttributes.Add("WSHost");
		pCheckedAttributes.Add("RoomRate"); 
		pCheckedAttributes.Add("NumberOfDaysToExportPrices");
	Else				
		pCheckedAttributes.Add("HttpServer");
		pCheckedAttributes.Add("HttpAddress");
	EndIf;
EndProcedure // FillCheckProcessingAtServer
 
 #EndRegion
 
 #Region FormHeaderItemsEventHandlers
 
  // -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	If Not tcOnServer.cmIsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // HotelClearing

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

// -----------------------------------------------------------------------------
&AtClient
Procedure InteractionParametersOnChange(pItem)
	LoadInteractionParameters();
EndProcedure // InteractionParametersOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodToOnChange(Item)
	PeriodTo = EndOfDay(PeriodTo); 
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UseToExportPricesOnChange(pItem)
	Refresh();
EndProcedure // UnloadPricesOnChange

 #EndRegion
 
 #Region FormCommandsEventHandlers
 
// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = PeriodFrom;
	vChoosePeriodDialog.Period.EndDate = PeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod
 
// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure // Save
 
// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	ActionsExecuteAtServer();
EndProcedure // ActionsExecute

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateInterfaceState(pCommand)
	RefreshInterfaceStateAtServer();
EndProcedure // UpdateInterfaceState

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


 #EndRegion
 
 #Region Private
 
// -----------------------------------------------------------------------------
&AtServer
Procedure Refresh()
	If Object.UseToExportPrices Then 
		Items.WSHost.Visible = True; 
		Items.WebhookURL.Visible = True;
		Items.RoomRate.Visible = True; 
		Items.NumberOfDaysToExportPrices.Visible = True;
		Items.LastFullSynchronizationTime.Visible = False;
		Items.ManualStartInformation.Visible = False; 
		Items.UnloadFrom.Visible = False;  
		Items.HttpServer.Visible = False; 
		Items.HttpAddress.Visible = False;
		Items.GroupExport.Visible = False;
	Else
		Items.LastFullSynchronizationTime.Visible = True;
		Items.ManualStartInformation.Visible = True; 
		Items.UnloadFrom.Visible = True; 
		Items.HttpServer.Visible = True; 
		Items.HttpAddress.Visible = True;
		Items.GroupExport.Visible = True;
		Items.WSHost.Visible = False;
		Items.WebhookURL.Visible = False;
		Items.RoomRate.Visible = False;
		Items.NumberOfDaysToExportPrices.Visible = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	If CheckFilling() Then
		SaveInteractionParameters();					
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction // IsInRoleAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsExecuteAtServer()
	If CheckFilling() Then
		vObj = FormAttributeToValue("Object");
		vObj.pmRun(New Structure("PeriodFrom, PeriodTo, UnLoadFromCheckInDate", PeriodFrom, PeriodTo, UnLoadFromCheckInDate), True);
		ValueToFormAttribute(vObj,"Object");
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
	EndIf;
EndProcedure // ActionsExecuteAtServer
 
  // -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		PeriodFrom = pPeriod.StartDate;
		PeriodTo = EndOfDay(pPeriod.EndDate);
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

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
Procedure LoadInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	Hotel        	  			= Object.InteractionParameters.Hotel;
	OAuth_AccessToken 			= Object.InteractionParameters.OAuth_AccessToken; 
	LastFullSynchronizationTime = Object.InteractionParameters.LastFullSynchronizationTime;
	HttpServer					= Object.InteractionParameters.HttpServer;
	HttpAddress					= Object.InteractionParameters.HttpAddress;
	HttpPort					= Object.InteractionParameters.HttpPort;
	HttpUseSsl					= Object.InteractionParameters.HttpUseSsl;
	DebugMode     	  			= Object.InteractionParameters.DebugMode;
	MaxLogLenght                = Object.InteractionParameters.MaxLogLenght;
	WSHost						= Object.InteractionParameters.WSHost;
	WebhookURL					= Object.InteractionParameters.WebhookURL;
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
		
	vIntParObj 								  = Object.InteractionParameters.GetObject();
	vIntParObj.Hotel   						  = Hotel;
	vIntParObj.OAuth_AccessToken			  = OAuth_AccessToken;
	vIntParObj.LastFullSynchronizationTime    = LastFullSynchronizationTime;
	vIntParObj.HttpServer					  = HttpServer;
	vIntParObj.HttpAddress					  = HttpAddress;
	vIntParObj.HttpPort						  = HttpPort;
	vIntParObj.HttpUseSsl					  = HttpUseSsl; 
	vIntParObj.WSHost						  = WSHost;     
	vIntParObj.WebhookURL					  = WebhookURL;
	vIntParObj.MaxLogLenght                   = MaxLogLenght;
	vIntParObj.DebugMode                      = DebugMode;
	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshInterfaceStateAtServer()
	// Load data processor catalog item attributes
	vObj = FormAttributeToValue("Object");
	vObj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(vObj, "Object");
	LoadInteractionParameters();
EndProcedure // RefreshInterfaceStateAtServer

#EndRegion


