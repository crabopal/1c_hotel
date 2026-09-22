
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
	
	Items.FormActionsExecute.Enabled = Not Obj.IsRunning;
	Items.FormActionsStop.Enabled = Obj.IsRunning; 
	
	Items.HTTP.Visible = Object.UseHTTP;
	Items.TCP.Visible = Not Object.UseHTTP; 
	Items.AutoUpdateInterfaceState.Visible = Not Object.UseHTTP;
	Items.AutoUpdatePeriod.Visible = Not Object.UseHTTP;
	Items.FormActionsStop.Visible = Not Object.UseHTTP; 
		
	If  IsInRoleAtServer("Administrator") And Not(vDataProcessor = Undefined) Then
		
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
		
	FillRoomStatusesTable();
	FillRoomInterfaceTypesTable();
	FillEmployeesTable();
	FillRoomsTable();
	AutoUpdateInterfaceState = True;
	AutoUpdatePeriod = 2;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)  
	If Not Object.UseHTTP Then
		RefreshInterfaceState();
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure UseHTTPOnChange(pItem) 
	Items.HTTP.Visible = Object.UseHTTP;
	Items.TCP.Visible = Not Object.UseHTTP;
	Items.AutoUpdateInterfaceState.Visible = Not Object.UseHTTP;
	Items.AutoUpdatePeriod.Visible = Not Object.UseHTTP;
	Items.FormActionsStop.Visible = Not Object.UseHTTP;
EndProcedure // UseHTTPOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	If Not tcOnServer.cmIsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // HotelClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure AutoUpdateInterfaceStateOnChange(pItem)
	If Not Object.UseHTTP Then	
		If AutoUpdateInterfaceState And CheckingRunningBackgroundJob(Object.DataProcessor) Then
			vPeriod = 2;
			If AutoUpdatePeriod > 0 Then
				vPeriod = AutoUpdatePeriod;	
			EndIf;
			AttachIdleHandler("RefreshInterfaceState", vPeriod, True);
		EndIf;
	EndIf;
EndProcedure // AutoUpdateInterfaceStateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InteractionParametersOnChange(pItem)
	LoadInteractionParameters();
	FillRoomStatusesTable();
EndProcedure // InteractionParametersOnChange

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
				RefreshInterfaceState();
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
Procedure RoomStatusesRoomStatusClearing(pItem, pStandardProcessing)
	DeleteExternalSystemRow(pItem.Parent.CurrentData.Code, pItem.Parent.CurrentData.RoomStatus, "RoomStatuses", Hotel, InteractionID);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStatusesRoomStatusChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	ChangeExternalSystemRow(pItem.Parent.CurrentData.Code, pItem.Parent.CurrentData.RoomStatus, pItem.Parent.CurrentData.Code, pSelectedValue, "RoomStatuses", Hotel, InteractionID, False);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStatusesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
EndProcedure // RoomStatusesBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStatusesBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
EndProcedure // RoomStatusesBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomInterfaceTypesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	vRoomInterfaceTypes = GetRoomInterfaceTypes();
	If vRoomInterfaceTypes.Count() > 0 Then
		vParams = New Structure("ValueList, MultipleChoice, Title", vRoomInterfaceTypes, False, NStr("en = 'Select room interface type'; de = 'Wählen Sie die Art des zusätzlichen Service im Zimmern'; ru = 'Выберите вид доп. услуги в номерах'"));
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,, New NotifyDescription("AfterChoiceRoomInterfaceType", ThisForm));
	EndIf;
EndProcedure // RoomInterfaceTypesBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceRoomInterfaceType(pItem, pExtraParams) Export 
	If pItem <> Undefined And ValueIsFilled(pItem.Value) Then
		vCode = tcOnServer.cmGetAttributeByRef(pItem.Value, "Code");
		ChangeExternalSystemRow(vCode, pItem.Value, vCode, pItem.Value, "RoomInterfaceTypes", Hotel, InteractionID, False);	
		FillRoomInterfaceTypesTable();
	EndIf;
EndProcedure // AfterChoiceRoomInterfaceType

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomInterfaceTypesBeforeDeleteRow(pItem, pCancel)
	DeleteExternalSystemRow(pItem.CurrentData.Code, pItem.CurrentData.RoomInterfaceType, "RoomInterfaceTypes", Hotel, InteractionID);	
EndProcedure // RoomInterfaceTypesBeforeDeleteRow
// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	vEmployeesList = GetEmployees();
	If vEmployeesList.Count() > 0 Then
		vParams = New Structure("MultipleChoice, Title, ValueList", False, NStr("en='Select employee...'; ru='Выберите сотрудника...'; de='Wählen Sie einen Mitarbeiter aus...'"), vEmployeesList);
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID, , , New NotifyDescription("AfterChoiceEmployees", ThisForm));
	EndIf;
EndProcedure // EmployeesBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceEmployees(pItem, pExtraParams) Export 
	If pItem <> Undefined And ValueIsFilled(pItem.Value) Then
		ShowInputString(New NotifyDescription("AfterInputEmployeeCode", ThisForm, pItem.Value),, NStr("en = 'Input employee code'; de = 'Geben Sie den Mitarbeitercode ein'; ru = 'Введите код сотрудника'"), 16, False); 
	EndIf;
EndProcedure // AfterChoiceEmployees

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeesBeforeDeleteRow(pItem, pCancel)
	DeleteExternalSystemRow(pItem.CurrentData.Code, pItem.CurrentData.Employee, "Employees", Hotel, InteractionID);
EndProcedure // EmployeesBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomsBeforeDeleteRow(pItem, pCancel)
	DeleteExternalSystemRow(pItem.CurrentData.Code, pItem.CurrentData.Room, "Rooms", Hotel, InteractionID);
EndProcedure // RoomsBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomsBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	vRoomsList = GetRooms();
	If vRoomsList.Count() > 0 Then
		vParams = New Structure("MultipleChoice, Title, ValueList", False, NStr("en='Select room...'; ru='Выберите номер...'; de='Wählen Sie einen Zimmer aus...'"), vRoomsList);
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID, , , New NotifyDescription("AfterChoiceRooms", ThisForm));
	EndIf;
EndProcedure // RoomsBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceRooms(pItem, pExtraParams) Export 
	If pItem <> Undefined And ValueIsFilled(pItem.Value) Then
		ShowInputString(New NotifyDescription("AfterInputRoomsCode", ThisForm, pItem.Value),, NStr("en = 'Input room code'; de = 'Geben Sie den Zimmercode ein'; ru = 'Введите код номера'"), 16, False); 
	EndIf;
EndProcedure // AfterChoiceRooms

// -----------------------------------------------------------------------------
&AtClient
Procedure IgnoreRoomStatusChangesOnChange(pItem)
	Items.RoomStatuses.Enabled = Not Object.IgnoreRoomStatusChanges;	
EndProcedure // IgnoreRoomStatusChangesOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure // Save

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	ActionsExecuteAtServer();
	ShowMessageBox(,NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure // ActionsExecute

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsStop(pCommand)
	If UseBackgroundJob Then
		UseBackgroundJob = False;
		SetupBackgroundJobSchedule_AtServer();
	EndIf;
	If ActionsStopAtServer() Then
		RefreshInterfaceState();
		AutoUpdateInterfaceStateOnChange(Items.AutoUpdateInterfaceState);
	EndIf;
EndProcedure // ActionsStop

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateInterfaceState(pCommand)
	RefreshInterfaceState();
EndProcedure // UpdateInterfaceState

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadDefaultSetting(pCommand)
	If ValueIsFilled(InteractionID) And ValueIsFilled(Hotel) Then 
		ActionsLoadDefaultSettingRecordsAtServer(StrReplace(pCommand.Name, "LoadDefaultSetting_", ""));
		ShowMessageBox(,NStr("en='Completed'; ru='Выполнено'; de='Abgeschlossen'")); 
	EndIf;
EndProcedure // ActionsLoadDefaultSettingRecords

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
Procedure GenerateToken(pCommand)
	InteractionID = String(New UUID);
EndProcedure // GenerateToken

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutAllGuestsInTheRoom(pCommand)
	If Object.UseHTTP Then
		vRoomList = GetAllRooms();
		If vRoomList.Count() > 0 Then
			vNotifyDescription = New NotifyDescription("AfterChoiceRoomsByChechOut", ThisForm);
			vParams = New Structure("ValueList, MultipleChoice, Title", vRoomList, True, NStr("en = 'Select rooms'; de = 'Zimmer auswählen'; ru = 'Выберите номера'"));
			OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,, vNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);	
		EndIf;
	EndIf;
EndProcedure // CheckOutAllGuestsInTheRoom

// -----------------------------------------------------------------------------
&AtClient
Procedure Synchronization(pCommand)
	SynchronizationAtServer();
EndProcedure // Synchronization

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshInterfaceState()
	RefreshInterfaceStateAtServer();
	If AutoUpdateInterfaceState And CheckingRunningBackgroundJob(Object.DataProcessor) Then
		vPeriod = 2;
		If AutoUpdatePeriod > 0 Then
			vPeriod = AutoUpdatePeriod;	
		EndIf;
		AttachIdleHandler("RefreshInterfaceState", vPeriod, True);	
	EndIf;
EndProcedure // RefreshInterfaceState

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckingRunningBackgroundJob(pDataProcessor)
	Return BackgroundJobs.GetBackgroundJobs(New Structure("Key, State", pDataProcessor.Key, BackgroundJobState.Active)).Count() > 0;
EndFunction // CheckingRunningBackgroundJob

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshInterfaceStateAtServer()
	// Load data processor catalog item attributes
	vObj = FormAttributeToValue("Object");
	vObj.pmLoadDataProcessorAttributes();
	vIsRunning = CheckingRunningBackgroundJob(vObj.DataProcessor);
	ValueToFormAttribute(vObj, "Object");
	If vObj.StopInterface Then
		Items.Group_Main_Pages.Visible = Not vIsRunning;
		Items.GroupStoppingInterface.Visible = vIsRunning;
	Else
		Items.Group_Main_Pages.Visible = True;
		Items.GroupStoppingInterface.Visible = False;	
	EndIf;      
	Items.TCP.Visible = Not Object.UseHTTP; 
	Items.HTTP.Visible = Object.UseHTTP;
	Items.FormSave.Enabled = Not vIsRunning;
	Items.FormActionsExecute.Enabled = Not vIsRunning;
	Items.FormActionsStop.Enabled = vIsRunning;
	Items.GroupMainSettings.Enabled = Not vIsRunning;
	Items.GroupLoadPhoneCalls.Enabled = vIsRunning;
	FillRoomStatusesTable();
	FillRoomInterfaceTypesTable();
	FillEmployeesTable();
	FillRoomsTable();
EndProcedure // RefreshInterfaceStateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	If CheckFilling() Then
		SaveInteractionParameters();
				
		For Each vRow In RoomStatuses Do
			vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vRecordManager.Hotel 				= Hotel;
			vRecordManager.ExternalSystemCode 	= InteractionID;
			vRecordManager.ObjectTypeName 		= "RoomStatuses";
			vRecordManager.ObjectExternalCode 	= vRow.Code;
			vRecordManager.ObjectRef 			= vRow.RoomStatus;
			vRecordManager.Read();
			
			If NOT vRecordManager.Selected() Then
				vRecordManager.Hotel 				= Hotel;
				vRecordManager.ExternalSystemCode 	= InteractionID;
				vRecordManager.ObjectTypeName 		= "RoomStatuses";
				vRecordManager.ObjectExternalCode 	= vRow.Code;
				vRecordManager.ObjectRef 			= vRow.RoomStatus;		
				vRecordManager.Write(True);
			EndIf;
		EndDo;
				
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
		RefreshInterfaceStateAtServer();
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
	If Object.UseHTTP Then
		If Not ValueIsFilled(Object.InteractionParameters.HttpServer) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'HTTP Server not specified!'; de = 'HTTP-Server nicht angegeben!'; ru = 'Не указан HTTP Server!'"));
			Return;
		EndIf;	
	Else	
		If Object.Port = 0 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Interface server port should be filled!';ru='Не указан сетевой порт, на котором должен работать интерфейсный сервер!';de='Port sollten ausgefüllt werden!'"));
			Return;
		EndIf; 
	EndIf;
	
	vObj = FormAttributeToValue("Object");
	vObj.pmRun();
	ValueToFormAttribute(vObj,"Object");
EndProcedure // ActionsExecuteAtServer

// -----------------------------------------------------------------------------
&AtServer
Function ActionsStopAtServer()
	vResult = False;
	For i = 0 To 3 Do
		Try
			BeginTransaction(DataLockControlMode.Managed);
			vDataLock = New DataLock();
			vDataLockItem = vDataLock.Add("Catalog.DataProcessors");
			vDataLockItem.Mode = DataLockMode.Exclusive;
			vDataLockItem.SetValue("Ref", Object.DataProcessor);
			vDataLock.Lock();
			vObj = FormAttributeToValue("Object");
			StopInterface = True; 
			// Do processing
			While True Do
				Try
					vObj.pmLoadDataProcessorAttributes();
					vObj.StopInterface = True;
					vObj.pmSaveDataProcessorAttributes();
					Break;
				Except
				EndTry;
			EndDo;
			ValueToFormAttribute(vObj, "Object");
			CommitTransaction();
			vErrorInfo = Undefined;
			vResult = True;
			Break;
		Except
			vErrorInfo = ErrorInfo();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
		EndTry;
	EndDo;
	If vErrorInfo <> Undefined Then
		tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(vErrorInfo));
	EndIf;		
	Return vResult;
EndFunction // ActionsStopAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsLoadDefaultSettingRecordsAtServer(pName)
	// Read template with default settings and write it to the Room interface types catalog
	vRITList = DataProcessors.FIASDriver.GetTemplate(pName);
	vCount = vRITList.TableHeight - 1;
	For i = 2 To (vCount + 1) Do
		Try
			vCode = Upper(Left(Hotel.Code, 1)) + TrimAll(vRITList.Area(i, 1, i, 1).Text);
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
			vManualCancelIsForbidden = Upper(TrimAll(vRITList.Area(i, 8, i, 8).Text));
			If vManualCancelIsForbidden = "TRUE" Then
				vRITObj.ManualCancelIsForbidden = True;
			Else
				vRITObj.ManualCancelIsForbidden = False;
			EndIf;
			vInterfaceTypes = Upper(TrimAll(vRITList.Area(i, 9, i, 9).Text)); 
			If vInterfaceTypes = "INTERNET" Then 
				vRITObj.InterfaceType = Enums.InterfaceTypes.Internet;
			ElsIf vInterfaceTypes = "MINIBAR" Then
				vRITObj.InterfaceType = Enums.InterfaceTypes.Minibar;
			ElsIf vInterfaceTypes = "PHONE" Then
				vRITObj.InterfaceType = Enums.InterfaceTypes.Phone;
			ElsIf vInterfaceTypes = "TV" Then
				vRITObj.InterfaceType = Enums.InterfaceTypes.TV;
			Else
				vRITObj.InterfaceType = Enums.InterfaceTypes.Others;
			EndIf;
			vRITObj.Write();			
			ChangeExternalSystemRow(vRITObj.Code, vRITObj.Ref, vRITObj.Code, vRITObj.Ref, "RoomInterfaceTypes", Hotel, InteractionID, False); 
		Except
			vErrorMsg = ErrorDescription(); 
			tcCommonFunctionOnClientServer.TextMessage(vErrorMsg);
		EndTry;
	EndDo;
	FillRoomInterfaceTypesTable();
EndProcedure // ActionsLoadDefaultSettingRecords

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
	
	Hotel			= Object.InteractionParameters.Hotel;
	InteractionID	= Object.InteractionParameters.InteractionID;
	DebugMode		= Object.InteractionParameters.DebugMode; 
	HttpServer		= Object.InteractionParameters.HttpServer;	
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
		
	vIntParObj					= Object.InteractionParameters.GetObject();
	vIntParObj.Hotel			= Hotel;
	vIntParObj.InteractionID	= InteractionID;
	vIntParObj.DebugMode		= DebugMode;  
	vIntParObj.HttpServer		= HttpServer;
	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomStatusesTable()
	If Not ValueIsFilled(Hotel) Or Not ValueIsFilled(InteractionID) Then
		Return;	
	EndIf;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomStatuses""";
	
	vQuery.SetParameter("qExternalSystemCode", InteractionID);
	vQuery.SetParameter("qHotel", Hotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	RoomStatuses.Clear();
	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "1";
	vNewRow.Description = NStr("en = 'Dirty/Vacant'; de = 'Dirty/Vacant'; ru = 'Грязный/Свободный'");
	vRow = vQueryResult.Find("1", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;
	
	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "2";
	vNewRow.Description = NStr("en = 'Dirty/Occupied'; de = 'Dirty/Occupied'; ru = 'Грязный/Занят'");
	vRow = vQueryResult.Find("2", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;

	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "3";
	vNewRow.Description = NStr("en = 'Clean/Vacant'; de = 'Clean/Vacant'; ru = 'Чистый/Свободный'");
	vRow = vQueryResult.Find("3", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;

	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "4";
	vNewRow.Description = NStr("en = 'Clean/Occupied'; de = 'Clean/Occupied'; ru = 'Чистый/Занят'");
	vRow = vQueryResult.Find("4", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;

	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "5";
	vNewRow.Description = NStr("en = 'Inspected/Vacant'; de = 'Inspected/Vacant'; ru = 'Инспекция/Свободный'");
	vRow = vQueryResult.Find("5", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;

	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "6";
	vNewRow.Description = NStr("en = 'Inspected/Occupied'; de = 'Inspected/Occupied'; ru = 'Инспекция/Занят'");
	vRow = vQueryResult.Find("6", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;
EndProcedure // FillRoomStatusesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomInterfaceTypesTable()
	If Not ValueIsFilled(Hotel) Or Not ValueIsFilled(InteractionID) Then
		Return;	
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomInterfaceTypes""";
	
	vQuery.SetParameter("qExternalSystemCode", InteractionID);
	vQuery.SetParameter("qHotel", Hotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	RoomInterfaceTypes.Clear();
	
	For Each vRow In vQueryResult Do
		vNewRow = RoomInterfaceTypes.Add();
		vNewRow.Code = vRow.ObjectExternalCode;
		vNewRow.RoomInterfaceType = vRow.ObjectRef; 
	EndDo;
EndProcedure // FillRoomStatusesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEmployeesTable()
	If Not ValueIsFilled(Hotel) Or Not ValueIsFilled(InteractionID) Then
		Return;	
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Employees""";
	
	vQuery.SetParameter("qExternalSystemCode", InteractionID);
	vQuery.SetParameter("qHotel", Hotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	Employees.Clear();
	
	For Each vRow In vQueryResult Do
		vNewRow = Employees.Add();
		vNewRow.Code = vRow.ObjectExternalCode;
		vNewRow.Employee = vRow.ObjectRef; 
	EndDo;
EndProcedure // FillEmployeesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomsTable()
	If Not ValueIsFilled(Hotel) Or Not ValueIsFilled(InteractionID) Then
		Return;	
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Rooms""";
	
	vQuery.SetParameter("qExternalSystemCode", InteractionID);
	vQuery.SetParameter("qHotel", Hotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	Rooms.Clear();
	
	For Each vRow In vQueryResult Do
		vNewRow = Rooms.Add();
		vNewRow.Code = vRow.ObjectExternalCode;
		vNewRow.Room = vRow.ObjectRef; 
	EndDo;	
EndProcedure // FillRoomsTable

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteExternalSystemRow(pCode, pObjectRef, pObjectTypeName, pHotel, pInteractionID)
	If ValueIsFilled(pHotel) And ValueIsFilled(pInteractionID) Then
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionID;
		vRecordManager.ObjectTypeName 		= pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pCode;
		vRecordManager.ObjectRef 			= pObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
		
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionID;
		vRecordManager.ObjectTypeName 		= "Virtual" + pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pCode;
		vRecordManager.ObjectRef 			= pObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeExternalSystemRow(pOldCode, pOldObjectRef, pCode, pObjectRef, pObjectTypeName, pHotel, pInteractionID, pIsVirtual)
	If ValueIsFilled(pHotel) And ValueIsFilled(pInteractionID) Then
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionID;
		vRecordManager.ObjectTypeName 		= pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pOldCode;
		vRecordManager.ObjectRef 			= pOldObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
		
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionID;
		vRecordManager.ObjectTypeName 		= "Virtual" + pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pOldCode;
		vRecordManager.ObjectRef 			= pOldObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
		
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionID;
		If pIsVirtual Then
			vRecordManager.ObjectTypeName 	= "Virtual" + pObjectTypeName;	
		Else
			vRecordManager.ObjectTypeName 	= pObjectTypeName;
		EndIf;
		vRecordManager.ObjectExternalCode 	= pCode;
		vRecordManager.ObjectRef 			= pObjectRef;
		vRecordManager.Write(true);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomInterfaceTypes()
	vRoomInterfaceTypesList = New ValueList();
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	RoomInterfaceTypes.Ref AS Ref,
	|	RoomInterfaceTypes.Description AS Description
	|FROM
	|	Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
	|WHERE
	|	NOT RoomInterfaceTypes.DeletionMark
	|	AND RoomInterfaceTypes.Hotel = &qHotel
	|	AND NOT RoomInterfaceTypes.Ref IN (&qRoomInterfaceTypesArr)";
	vQuery.SetParameter("qHotel", Hotel);
	vQuery.SetParameter("qRoomInterfaceTypesArr", RoomInterfaceTypes.Unload(, "RoomInterfaceType"));
	vResult = vQuery.Execute().Unload();
	For Each vRow In vResult Do
		vRoomInterfaceTypesList.Add(vRow.Ref, vRow.Description);  	
	EndDo;
	Return vRoomInterfaceTypesList;
EndFunction // GetRoomInterfaceTypes

// -----------------------------------------------------------------------------
&AtServer
Function GetEmployees()
	vEmployeesList = New ValueList();
	vEmployees = cmGetAllEmployees(Hotel);	
	vEmployeesList.LoadValues(vEmployees.UnloadColumn("Employee"));
	Return vEmployeesList;
EndFunction // GetEmployees

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputRoomsCode(pText, pExtraParams) Export 
	If ValueIsFilled(pText) And ValueIsFilled(pExtraParams) Then 
		ChangeExternalSystemRow(pText, pExtraParams, pText, pExtraParams, "Rooms", Hotel, InteractionID, False);	
		FillRoomsTable();
	EndIf;
EndProcedure // AfterInputRoomsCode

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputEmployeeCode(pText, pExtraParams) Export 
	If ValueIsFilled(pText) And ValueIsFilled(pExtraParams) Then 
		ChangeExternalSystemRow(pText, pExtraParams, pText, pExtraParams, "Employees", Hotel, InteractionID, False);	
		FillEmployeesTable();
	EndIf;
EndProcedure // AfterChoiceEmployees

// -----------------------------------------------------------------------------
&AtServer
Function GetRooms()
	vRoomsList = New ValueList();
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Rooms.Ref AS Room
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND Rooms.Owner = &qHotel
	|
	|ORDER BY
	|	Rooms.SortCode";
	vQuery.SetParameter("qHotel", Hotel);
	vRoomsList.LoadValues(vQuery.Execute().Unload().UnloadColumn("Room")); 
	Return vRoomsList;
EndFunction // GetEmployees

// -----------------------------------------------------------------------------
&AtServer
Function GetAllRooms()
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	Rooms.Ref AS Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND Rooms.Owner = &qHotel
	|
	|ORDER BY
	|	Rooms.SortCode";
	vQ.SetParameter("qHotel", Object.InteractionParameters.Hotel);
	vRoomsList = New ValueList; 
	vRoomsList.LoadValues(vQ.Execute().Unload().UnloadColumn("Ref"));
	Return vRoomsList;
EndFunction // GetAllRooms

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceRoomsByChechOut(pRoomsList, pExtraParams) Export 
	If pRoomsList <> Undefined Then
		vRoomArr = New Array;
		For Each vRoom In pRoomsList Do
			If vRoom.Check Then
				vRoomArr.Add(vRoom.Value);	
			EndIf;
		EndDo;
		If vRoomArr.Count() > 0 Then
			CheckOutGuestAtServer(vRoomArr);
		EndIf;
	EndIf;
EndProcedure // AfterChoiceRooms

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutGuestAtServer(pRooms)
	If Not ValueIsFilled(Object.InteractionParameters.HttpServer) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'HTTP Server not specified!'; de = 'HTTP-Server nicht angegeben!'; ru = 'Не указан HTTP Server!'"));
		Return;
	EndIf;
	
	vObj = FormAttributeToValue("Object");
	vObj.pmRun(pRooms);
	ValueToFormAttribute(vObj,"Object");
	tcCommonFunctionOnClientServer.TextMessage(NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SynchronizationAtServer()
	If Not ValueIsFilled(Object.InteractionParameters.HttpServer) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'HTTP Server not specified!'; de = 'HTTP-Server nicht angegeben!'; ru = 'Не указан HTTP Server!'"));
		Return;
	EndIf;
	
	vObj = FormAttributeToValue("Object");
	vObj.SynchronizationAtServer();
	ValueToFormAttribute(vObj,"Object");
	tcCommonFunctionOnClientServer.TextMessage(NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure // Synchronization

#EndRegion

