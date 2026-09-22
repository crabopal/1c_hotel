
  #Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not FilterByActiveState And Not FilterByCanceledState And Not FilterByCompletedState And Not FilterByFailedState Then
		FilterByActiveState 	= True;
		FilterByCanceledState 	= True;
		FilterByCompletedState 	= True;
		FilterByFailedState 	= True;
	EndIf;    
	FilterKindByPeriod = 3; // Current date
	GetListBackgroundJobIsActive = False;     
	Items.Group_Page_LoadingScheduledJobs.Visible = False;
	Items.Group_Page_ScheduledJobs.Visible = True;      
	Items.Group_Page_LoadingBackgroundJobs.Visible = False;
	Items.Group_Page_BackgroundJobs.Visible = True;
	GetListScheduledJobsIsActive = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)      
	StartProlongedOperations(True, True, False);
	UpdateAttachebles();         
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure AutoUpdateOnChange(pItem)
	UpdateAttachebles();
EndProcedure // UpdateScheduledJobs

// -----------------------------------------------------------------------------
&AtClient
Procedure AutoUpdatePeriodOnChange(pItem)
	UpdateAttachebles();
EndProcedure // AutoUpdatePeriodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterKindByPeriodOnChange(pItem)
	RefreshPeriodFilter();
EndProcedure // FilterKindByPeriodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
EndProcedure // BackgroundJobsListBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ListBeforeRowChange(pItem, pCancel)
	pCancel = True;
EndProcedure // BackgroundJobsListBeforeRowChange

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure BackgroundJobsListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vPassedPropertyList =
						"UUID,
						|Key,
						|Description,
						|MethodName,
						|State,
						|Begin,
						|End,
						|Location,
						|ErrorInfo,
						|UserMessages,
						|ScheduledJobID,
						|ScheduledJobDescription";
	vCurrentData = New Structure(vPassedPropertyList);	
	FillPropertyValues(vCurrentData, Items.BackgroundJobsList.CurrentData);
	
	vParametrs = New Structure("BackgroundJobProperties", vCurrentData);
	OpenForm("DataProcessor.ScheduledJobsManagementConsole.Form.tc_BackgroundJobForm", vParametrs, ThisObject);
EndProcedure // BackgroundJobsListSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure ScheduledJobsListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vCurrentData = Items.ScheduledJobsList.CurrentData;  
	vParam = New Structure("SelUUID, SelLastJobUUID", vCurrentData.UUID, vCurrentData.LastJobUUID);     
	vND = New NotifyDescription("AfterCloseForm", ThisObject);
	OpenForm("DataProcessor.ScheduledJobsManagementConsole.Form.tc_ScheduleJobForm", vParam, ThisObject, ThisObject.UUID,,, vND); 	
EndProcedure // ScheduledJobsListSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
EndProcedure // BackgroundJobsListBeforeAddRow

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateBackgroundJobs(pCommand)
	If Not GetListBackgroundJobIsActive Then
		StartProlongedOperations(False, True);
		UpdateAttachebles();
	EndIf;
EndProcedure // UpdateBackgroundJobs

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateScheduledJobs(pCommand)
	If Not GetListScheduledJobsIsActive Then
		StartProlongedOperations(True, False);
	EndIf;
EndProcedure // UpdateScheduledJobs

// -----------------------------------------------------------------------------
&AtClient
Procedure CancelBackgroundJob(pCommand)
	If CancelBackgroundJobAtServer(Items.BackgroundJobsList.CurrentData.UUID) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success'; ru = 'Успешно остановлено'")); //#Translate
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to stop background job'; ru = 'Ошибка остановки фонового задания'")); //#Translate
	EndIf;
	StartProlongedOperations(False, True);
EndProcedure // UpdateScheduledJobs

// -----------------------------------------------------------------------------
&AtClient
Procedure SetSchedule(pCommand)
	vRow = Items.ScheduledJobsList.CurrentData;
	
	If vRow = Undefined Then
		ShowMessageBox(, НСтр("en = 'Select a scheduled task.'; de = 'Wählen Sie eine geplante Aufgabe aus.'; ru = 'Выберите регламентное задание.'"));
	ElsIf Items.ScheduledJobsList.SelectedRows.Count() > 1 Then
		ShowMessageBox(, НСтр("en = 'Select one scheduled task.'; de = 'Wählen Sie eine geplante Aufgabe aus.'; ru = 'Выберите одно регламентное задание.'"));
	Else
		vScheduledJobDialog = New ScheduledJobDialog(GetSchedule(vRow.UUID));
		
		vScheduledJobDialog.Show(New NotifyDescription("OpenScheduleCompletion", ThisObject, vRow));
	EndIf;
EndProcedure // SetSchedule

// -----------------------------------------------------------------------------
&AtClient
Procedure ExecuteScheduledJobManually(pCommand)
	vRow = Items.ScheduledJobsList.CurrentData;
	vExecutionOptions = ExecuteScheduledJobManuallyAtServer(vRow.UUID);
	
	If vExecutionOptions.LaunchCompleted Then
		
		ShowUserNotification(
				NStr("ru = 'Запущена процедура регламентного задания'"), ,
				StrTemplate(NStr("en = '%1.
                                  |Procedure started in background job %2'; de = '%1.
                                  |Die Prozedur wurde im Hintergrundjob gestartet %2'; ru = '%1.
                                  |Процедура запущена в фоновом задании %2'"),
					vRow.Description,
					TrimAll(vExecutionOptions.StartingMoment)),
				PictureLib.ScheduledJob);
		vNewJob = BackgroundJobsIsActive.Add();
		vNewJob.Name 		 	= vRow.Description;
		vNewJob.UUID 		 	= vExecutionOptions.UUIDBackgroundJob;
		vNewJob.UUIDScheduled   = vRow.UUID;
		vNewJob.Status 		 	= "Processing";
		If Not ProcessingBackgroundJobs Then 
			AttachIdleHandler("CheckBackgroundJobs", 1, False);
		EndIf;
		UpdateScheduledJobsListRow(vRow.UUID);
	ElsIf vExecutionOptions.ProcedureAlreadyRunning Then	
		ShowUserNotification(StrTemplate(NStr("en = 'Procedure ScheduledJob ""%1""
                                  |already running in background job ""%2"", started in %3.'; de = 'Vorgehensweise Geplanter Job ""%1""
                                  |läuft bereits im Hintergrundjob ""%2"", gestartet in%3.'; ru = 'Процедура регламентного задания ""%1""
                                  |уже выполняется в фоновом задании ""%2"", начатой в %3.'"),
					vRow.Description,
					vExecutionOptions.BackgroundJobSubmission,
					TrimAll(vExecutionOptions.StartingMoment)),,,
				PictureLib.ScheduledJob);		
	EndIf;
EndProcedure // ExecuteScheduledJobManually

// -----------------------------------------------------------------------------
&AtClient
Procedure AddScheduledJobManually(pCommand)
	OpenForm("DataProcessor.ScheduledJobsManagementConsole.Form.tc_ScheduleJobForm", , ThisObject, ThisObject.UUID,,, New NotifyDescription("AfterCloseForm", ThisObject));	
EndProcedure // AddScheduledJobManually

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyScheduledJob(pCommand)
	vCurrentData = Items.ScheduledJobsList.CurrentData;
	OpenForm("DataProcessor.ScheduledJobsManagementConsole.Form.tc_ScheduleJobForm", New Structure("SelUUID, SelIsCopy", vCurrentData.UUID, True), ThisObject, ThisObject.UUID,,, New NotifyDescription("AfterCloseForm", ThisObject));
EndProcedure // CopyScheduledJob

// -----------------------------------------------------------------------------
&AtClient
Procedure DelScheduledJob(pCommand)
	vCurrentIndex = Items.ScheduledJobsList.CurrentRow; 
	DelScheduledJobAtServer(vCurrentIndex);
	Items.ScheduledJobsList.Refresh();
EndProcedure // DelScheduledJob

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure DelScheduledJobAtServer(vCurrentData)
	Try
		vRow = ScheduledJobsList.FindByID(vCurrentData);
		vJob = ScheduledJobs.FindByUUID(vRow.UUID);
		If vJob.Predefined Then
			Raise(NStr("en='Predefined scheduled jobs could not be deleted: ';ru='Нельзя удалить предопределенное задание: ';de='Eine vorgegebene Aufgabe darf nicht entfernt werden: '") + vJob.Description);
		Else
			vJob.Delete();
			ScheduledJobsList.Delete(ScheduledJobsList.IndexOf(vRow));
		EndIf;
	Except
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());
	EndTry;
EndProcedure // DelScheduledJobAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateScheduledJobsListRow(pResult)
	vScheduledJob =	ScheduledJobs.FindByUUID(pResult);
	If vScheduledJob = Undefined Then
		Return;	
	EndIf;
	vRowArr = ScheduledJobsList.FindRows(New Structure("UUID", pResult));
	If vRowArr.Count() > 0 Then
		vRow = vRowArr.Get(0);
		FillPropertyValues(vRow, vScheduledJob);
		If Not ValueIsFilled(vScheduledJob.Description) Then
			vRow.Description = TrimAll(vScheduledJob.Metadata) 	
		EndIf;
		
		If vScheduledJob.Predefined Then
			vRow.PredefinedPic = 11;	
		Else
			vRow.PredefinedPic = 7;	
		EndIf;
		vBackgroundJobs = BackgroundJobs.GetBackgroundJobs(New Structure("Key", vScheduledJob.UUID));
		If vScheduledJob.LastJob <> Undefined Then
			vRow.StartDate = vScheduledJob.LastJob.Begin;
			vRow.EndDate = vScheduledJob.LastJob.End;
			vRow.State = vScheduledJob.LastJob.State;
			vRow.LastJobUUID = vScheduledJob.LastJob.UUID;
		EndIf;
		
		If vBackgroundJobs.Count() > 0 Then
			vJob = vBackgroundJobs.Get(0);
			If vScheduledJob.LastJob <> Undefined Then
				If vScheduledJob.LastJob <> vJob Then
					If vScheduledJob.LastJob.Begin <= vJob.Begin Then
						vRow.StartDate = vJob.Begin;
						vRow.EndDate = vJob.End;
						vRow.State = vJob.State;
						vRow.LastJobUUID = vJob.UUID;
					EndIf;
				EndIf;
			Else
				vRow.StartDate = vJob.Begin;
				vRow.EndDate = vJob.End;
				vRow.State = vJob.State;
				vRow.LastJobUUID = vJob.UUID;
			EndIf;
		EndIf;
	Else
		vRow = ScheduledJobsList.Add();	
		FillPropertyValues(vRow, vScheduledJob);
		
		If Not ValueIsFilled(vScheduledJob.Description) Then
			vRow.Description = TrimAll(vScheduledJob.Metadata) 	
		EndIf;
		
		If vScheduledJob.Predefined Then
			vRow.PredefinedPic = 11;	
		Else
			vRow.PredefinedPic = 7;	
		EndIf;
		vBackgroundJobs = BackgroundJobs.GetBackgroundJobs(New Structure("Key", vScheduledJob.UUID));
		If vScheduledJob.LastJob <> Undefined Then
			vRow.StartDate = vScheduledJob.LastJob.Begin;
			vRow.EndDate = vScheduledJob.LastJob.End;
			vRow.State = vScheduledJob.LastJob.State;
			vRow.LastJobUUID = vScheduledJob.LastJob.UUID;
		EndIf;
		
		If vBackgroundJobs.Count() > 0 Then
			vJob = vBackgroundJobs.Get(0);
			If vScheduledJob.LastJob <> Undefined Then
				If vScheduledJob.LastJob <> vJob Then
					If vScheduledJob.LastJob.Begin <= vJob.Begin Then
						vRow.StartDate = vJob.Begin;
						vRow.EndDate = vJob.End;
						vRow.State = vJob.State;
						vRow.LastJobUUID = vJob.UUID;
					EndIf;
				EndIf;
			Else
				vRow.StartDate = vJob.Begin;
				vRow.EndDate = vJob.End;
				vRow.State = vJob.State;
				vRow.LastJobUUID = vJob.UUID;
			EndIf;
		EndIf;
	EndIf;
	ScheduledJobsList.Sort("Predefined Desc, Description");
	Items.ScheduledJobsList.Refresh();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function ExecuteScheduledJobManuallyAtServer(pUUID)	
	vExecutionOptions = New Structure();
	vExecutionOptions.Insert("StartingMoment");
	vExecutionOptions.Insert("UUIDBackgroundJob");
	vExecutionOptions.Insert("BackgroundJobSubmission");
	vExecutionOptions.Insert("ProcedureAlreadyRunning", False);
	vExecutionOptions.Insert("LaunchCompleted", False);
	vJob = ScheduledJobs.FindByUUID(pUUID);
	vLastJob = vJob.LastJob;
	If vLastJob <> Undefined And vLastJob.State = BackgroundJobState.Active Then
		vExecutionOptions.StartingMoment = vLastJob.Begin;
		If ValueIsFilled(vLastJob.Description) Then
			vExecutionOptions.BackgroundJobSubmission = vLastJob.Description;
		Else
			vExecutionOptions.BackgroundJobSubmission = vLastJob.MethodName;	
		EndIf;
	Else
		vDescription = StrTemplate(NStr("en = 'Manual start: %1'; de = 'Manueller Start: %1'; ru = 'Запуск вручную: %1'"), ?(ValueIsFilled(vJob.Description), vJob.Description, TrimAll(vJob.Metadata)));
	    vBackgroundJob = BackgroundJobs.Execute(vJob.Metadata.MethodName, vJob.Parameters, TrimAll(vJob.UUID), vDescription);
		vExecutionOptions.UUIDBackgroundJob = vBackgroundJob.UUID;
		vExecutionOptions.StartingMoment = vBackgroundJob.Begin; 
		vExecutionOptions.LaunchCompleted = True;
	EndIf;
	
	vExecutionOptions.ProcedureAlreadyRunning = Not vExecutionOptions.LaunchCompleted;
	Return vExecutionOptions;
EndFunction // ExecuteScheduledJobManuallyAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetSchedule(pUUID)
	Return ScheduledJobs.FindByUUID(pUUID).Schedule;
EndFunction // GetSchedule

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenScheduleCompletion(pNewSchedule, pExtraParams) Export
	If pNewSchedule <> Undefined Then
		SetScheduleNew(pExtraParams.UUID, pNewSchedule);
		StartProlongedOperations(True, False, True);
	EndIf;
EndProcedure // OpenScheduleCompletion

// -----------------------------------------------------------------------------
&AtServer
Procedure SetScheduleNew(pUUID, pNewSchedule)
	vJov = ScheduledJobs.FindByUUID(pUUID);
	vJov.Schedule = pNewSchedule;
	vJov.Write();
EndProcedure // SetScheduleNew

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateAttachebles()
	DetachIdleHandler("Attacheble_AutoUpdaterBackgroundJob");
	
	If AutoUpdateBackgroundJob Then
		If AutoUpdatePeriodBackgroundJob < 10 Then
			AutoUpdatePeriodBackgroundJob = 10;
		EndIf;
		
		Items.AutoUpdatePeriodBackgroundJob.Visible = True;		
		AttachIdleHandler("Attacheble_AutoUpdaterBackgroundJob", AutoUpdatePeriodBackgroundJob, False);
	Else
		Items.AutoUpdatePeriodBackgroundJob.Visible = False;
	EndIf;
EndProcedure // UpdateAttachebles

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCloseForm(pResult, pExtraPatams) Export 
	If pResult <> Undefined Then
		If ValueIsFilled(pResult) Then 
			UpdateScheduledJobsListRow(pResult);
		EndIf;
	EndIf;
EndProcedure // AfterCloseForm

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshPeriodFilter()
	vCurrentDate = CurrentSessionDate();
	If	FilterKindByPeriod = 0 Then
		FilterPeriodFrom  = '00010101';
		FilterPeriodTo = '00010101';
		Items.SettingArbitraryPeriod.Visible = False;	
	ElsIf FilterKindByPeriod = 1 Then
		FilterPeriodFrom  = BegOfDay(vCurrentDate) - 3*3600;
		FilterPeriodTo = BegOfDay(vCurrentDate) + 9*3600;
		Items.SettingArbitraryPeriod.Visible = False;
	ElsIf FilterKindByPeriod = 2 Then
		FilterPeriodFrom  = BegOfDay(vCurrentDate) - 24*3600;
		FilterPeriodTo = EndOfDay(FilterPeriodFrom);
		Items.SettingArbitraryPeriod.Visible = False;
	ElsIf FilterKindByPeriod = 3 Then
		FilterPeriodFrom  = BegOfDay(vCurrentDate);
		FilterPeriodTo = EndOfDay(FilterPeriodFrom);
		Items.SettingArbitraryPeriod.Visible = False;
	ElsIf FilterKindByPeriod = 4 Then
		Items.SettingArbitraryPeriod.Visible = True;
	EndIf;
EndProcedure // RefreshPeriodFilter

// -----------------------------------------------------------------------------
&AtServer
Function CancelBackgroundJobAtServer(pBackgroundJobID)
	Return AsyncCalls.CancelBackgroundJob(pBackgroundJobID);
EndFunction // CancelBackgroundJobAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction // CheckBackgroundJobStatus

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateBackgroundJobsTable(pResultAddress)
	vResult = GetFromTempStorage(pResultAddress);
	BackgroundJobsList.Clear();
	BackgroundJobsList.Load(vResult);
EndProcedure // UpdateBackgroundJobsTable

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateScheduledJobsTable(pResultAddress)
	vResult = GetFromTempStorage(pResultAddress);
	ScheduledJobsList.Clear();
	ScheduledJobsList.Load(vResult);
EndProcedure // UpdateScheduledJobsTable

// -----------------------------------------------------------------------------
&AtClient
Procedure Attacheble_AutoUpdaterBackgroundJob()
	If Not GetListBackgroundJobIsActive Then 
		StartProlongedOperations(False, True, True);
	EndIf;
EndProcedure // Attacheble_AutoUpdaterBackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure StartProlongedOperations(pScheduledJob = False, pBackgroundJobs = False, pUpdateQuietly = False)
	If pBackgroundJobs Then
		RefreshPeriodFilter();
		
		vProcedureParametrs = new Array;
		vSentParameters = New Structure();
		
		vTempStorageAdress = PutToTempStorage(Null);
		vSentParameters.Insert("FilterByActiveState", FilterByActiveState);
		vSentParameters.Insert("FilterByCompletedState", FilterByCompletedState);
		vSentParameters.Insert("FilterByFailedState", FilterByFailedState);
		vSentParameters.Insert("FilterByCanceledState", FilterByCanceledState);
		vSentParameters.Insert("FilterPeriodFrom", FilterPeriodFrom);
		vSentParameters.Insert("FilterPeriodTo", FilterPeriodTo);
		vSentParameters.Insert("FilterKindByPeriod", FilterKindByPeriod);
		
		vProcedureParametrs.Add(vTempStorageAdress);
		vProcedureParametrs.Add(vSentParameters);
		vBackgroundJob          = StartBackgroundJob("ProlongedOperations.ScheduledJobsManagementConsole_GetListBackgroundJob", vProcedureParametrs, "Update Bacground Jobs List", vTempStorageAdress);
		vNewRow 				= BackgroundJobsIsActive.Add();
		vNewRow.Name 		 	= "ScheduledJobsManagementConsole_GetListBackgroundJob";
		vNewRow.UUID 		 	= vBackgroundJob.UUID;
		vNewRow.ResultAddress 	= vBackgroundJob.TempStorageAddress;
		vNewRow.Status 		 	= "Processing";
		GetListBackgroundJobIsActive = True;
		Items.Group_Page_LoadingBackgroundJobs.Visible = Not pUpdateQuietly;
		Items.Group_Page_BackgroundJobs.Visible = pUpdateQuietly;
	EndIf;
	If pScheduledJob Then
		vProcedureParametrs = new Array;
		vTempStorageAdress = PutToTempStorage(Null);
		vProcedureParametrs.Add(vTempStorageAdress);
		
		vBackgroundJob          = StartBackgroundJob("ProlongedOperations.ScheduledJobsManagementConsole_GetListGetListScheduledJobs", vProcedureParametrs, "Update Scheduled Jobs List", vTempStorageAdress);

		vNewRow 				= BackgroundJobsIsActive.Add();
		vNewRow.Name 		 	= "ScheduledJobsManagementConsole_GetListGetListScheduledJobs";
		vNewRow.UUID 		 	= vBackgroundJob.UUID;
		vNewRow.ResultAddress 	= vBackgroundJob.TempStorageAddress;
		vNewRow.Status 		 	= "Processing";
		GetListScheduledJobsIsActive = True;
		Items.Group_Page_LoadingScheduledJobs.Visible = Not pUpdateQuietly;
		Items.Group_Page_ScheduledJobs.Visible = pUpdateQuietly;
	EndIf;
	If Not ProcessingBackgroundJobs Then 
		AttachIdleHandler("CheckBackgroundJobs", 1, False);
	EndIf;
EndProcedure // StartProlongedOperations

// -----------------------------------------------------------------------------
&AtServer                               
Function StartBackgroundJob(pProcedureName, pProcedureParametrs, pBacgroundJobName, pTempStorageAddress)
	Return AsyncCalls.StartBackgroundJob(pProcedureName, pProcedureParametrs,,pBacgroundJobName,pTempStorageAddress);	
EndFunction // StartBackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckBackgroundJobs()
	ProcessingBackgroundJobs = False;
	For Each vJob In BackgroundJobsIsActive Do 
		If vJob.Status = "Processing" Then
			ProcessingBackgroundJobs = True;
			vBackgroundvJob = CheckBackgroundJobStatus(vJob.UUID);
			
			If vBackgroundvJob <> Undefined Then 
				
				If vBackgroundvJob.Status = "Processing" Then 
					vJob.Status = "Processing"; 				
				ElsIf vBackgroundvJob.Status = "Error" Then 
					vJob.Status = "Error";
					tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: " + vJob.Name + "'; ru = 'Ошибка выполнения фонового задания: " + vJob.Name + "'"));		//#Translate			
					ChangeIsDeactivatedJob(vJob);
				ElsIf vBackgroundvJob.Status = "Canceled" Then 
					vJob.Status = "Canceled";
					tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job: " + vJob.Name + " - canceled.'; ru = 'Фоновое задание: " + vJob.Name + " - отменено.'"));   		//#Translate
					ChangeIsDeactivatedJob(vJob);
				ElsIf vBackgroundvJob.Status = "Completed" Then 
					vJob.Status = "Completed";
					ProcessBackgroundJob(vJob);
					ChangeIsDeactivatedJob(vJob);
				EndIf;
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in checking background job: " + vJob.Name + "'; ru = 'Ошибка проверки фонового задания: " + vJob.Name + "'"));	//#Translate	
			EndIf;
		EndIf;
	EndDo;
	
	If NOT ProcessingBackgroundJobs Then
		BackgroundJobsIsActive.Clear();
		DetachIdleHandler("CheckBackgroundJobs");
	EndIf;
EndProcedure // CheckBackgroundJobs

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeIsDeactivatedJob(pBackgroundJob)
	If pBackgroundJob.Name = "ScheduledJobsManagementConsole_GetListBackgroundJob" Then
		GetListBackgroundJobIsActive = False;
		Items.Group_Page_LoadingBackgroundJobs.Visible = False;
		Items.Group_Page_BackgroundJobs.Visible = True;
	ElsIf pBackgroundJob.Name = "ScheduledJobsManagementConsole_GetListGetListScheduledJobs" Then
		GetListScheduledJobsIsActive = False;
		Items.Group_Page_LoadingScheduledJobs.Visible = False;
		Items.Group_Page_ScheduledJobs.Visible = True;
	EndIf;
EndProcedure // ChangeIsDeactivatedJob

// -----------------------------------------------------------------------------
&AtClient
Procedure ProcessBackgroundJob(pBackgroundJob)
	If pBackgroundJob.Name = "ScheduledJobsManagementConsole_GetListBackgroundJob" Then
		Try
			UpdateBackgroundJobsTable(pBackgroundJob.ResultAddress);
		Except
		EndTry;	
	ElsIf pBackgroundJob.Name = "ScheduledJobsManagementConsole_GetListGetListScheduledJobs" Then
		Try
			UpdateScheduledJobsTable(pBackgroundJob.ResultAddress);
		Except
		EndTry;
	Else
		ShowUserNotification(
			NStr("en = 'Scheduled task completed'; de = 'Geplante Aufgabe abgeschlossen'; ru = 'Выполнена процедура регламентного задания'"),
			,
			StrTemplate(
				NStr("en = '%1.
                      |Procedure completed in background job'; de = '%1.
                      |Vorgang im Hintergrundjob abgeschlossen'; ru = '%1.
                      |Процедура завершена в фоновом задании'"),
				pBackgroundJob.Name),
			PictureLib.ScheduledJob);
		UpdateScheduledJobsListRow(pBackgroundJob.UUIDScheduled);	
	EndIf;
EndProcedure // ProcessBackgroundJob

#EndRegion
