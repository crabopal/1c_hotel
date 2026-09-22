
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
	
	InteractionID = "SamsungLYNK";	
	
	Items.FullSynchronizationTime.Enabled = Object.IsAutomaticallySyncData;
	
	#If NOT MobileClient Then
		If tcOnServer.cmIsInRole("Administrator") And vDataProcessor <> Undefined Then
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
			Items.MainPage_BackgroundJob.Visible = False;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'"));
		EndIf;
	#Else
		Items.MainPage_BackgroundJob.Visible = False;
	 	tcCommonFunctionOnClientServer.TextMessage("Background job cant be configured on mobile client!");
	#EndIf	
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

 // -----------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	If Debug Then
		Active = True;
	EndIf;
EndProcedure // DebugOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	If Not Active Then
		Debug = False;
	EndIf;
EndProcedure // ActiveOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DefaultChannelListClearing(pItem, pStandardProcessing)
	DeleteExternalSystem("DefaultChannel", DefaultChannelList, "RoomInterfaceTypes", Hotel, Object.ExternalInteraction);
EndProcedure // DefaultChannelListClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure DefaultChannelListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(Hotel) Then 
		vChannelListStart = GetRoomInterfaceTypesList(Hotel);
		If vChannelListStart.Count() > 0 Then
			vParams = New Structure("ValueList, MultipleChoice, Title", vChannelListStart, False, NStr("en = 'Select channel list'; de = 'Kanalliste auswählen'; ru = 'Выберите список каналов'"));
			OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,, New NotifyDescription("AfterChoiceChannelList", ThisForm));
		Else
			tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Add types of additional services in the rooms'; de = 'Fügen Sie Arten von zusätzlichen Dienstleistungen in den Zimmern hinzu'; ru = 'Добавьте виды дополнительных услуг в номерах'"));	
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'It is necessary to fill the hotel'; de = 'Es ist notwendig, das hotel zu füllen'; ru = 'Необходимо заполнить гостиницу'"));
	EndIf;
EndProcedure // DefaultChannelListStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceChannelList(pItem, pExtraParams) Export 
	If pItem <> Undefined Then
		If Not ValueIsFilled(pItem.Value) And ValueIsFilled(DefaultChannelList) Then
			DeleteExternalSystem("DefaultChannel", DefaultChannelList, "RoomInterfaceTypes", Hotel, Object.ExternalInteraction); 	
		Else
			ChangeExternalSystem("DefaultChannel", DefaultChannelList, "DefaultChannel", pItem.Value, "RoomInterfaceTypes", Hotel, Object.ExternalInteraction);     	
		EndIf;
		DefaultChannelList = pItem.Value;
	EndIf;
EndProcedure // AfterChoiceChannelList

// -----------------------------------------------------------------------------
&AtClient
Procedure UseBackgroundJobOnChange(pItem)
	If ValueIsFilled(Employee) Then
		If Object.Schedule <> Undefined Then
			If UseBackgroundJob Then
				If Not tcOnServer.cmIsInRole("Administrator") Then
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

&AtClient
Procedure IsAutomaticallySyncDataOnChange(pItem)
	Items.FullSynchronizationTime.Enabled = Object.IsAutomaticallySyncData;
EndProcedure // IsAutomaticallySyncDataOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ManualSync(pCommand)
	vMessage = ""; ;
	ManualSync_AtServer(vMessage);
	If ValueIsFilled(vMessage) Then
		ShowMessageBox(, vMessage);
	EndIf;
EndProcedure // ManualSync

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionExecute(pCommand)
	ActionExecute_AtServer();
	ShowMessageBox(, NStr("en = 'Completed'; de = 'Abgeschlossen'; ru = 'Завершено'"));
EndProcedure // ActionExecute

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateRoomInterfaceTypes(pCommand)
	OpenForm("DataProcessor.SamsungLYNK.Form.tcChoiceExtraParameters",, ThisForm, UUID,,, New NotifyDescription("AfterChoiceExtraParameters", ThisForm));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(pCommand)
	If ValueIsFilled(Employee)  Then
		If  Not tcOnServer.cmIsInRole("Administrator") Then
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

#Region Internal

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If Not ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	Hotel  						= Object.ExternalInteraction.Hotel;
	Active  					= Object.ExternalInteraction.IsActive;
	Debug  					    = Object.ExternalInteraction.DebugMode;
	InteractionID   			= Object.ExternalInteraction.InteractionID;
	HttpServer  				= Object.ExternalInteraction.HttpServer;
	HttpPort   					= Object.ExternalInteraction.HttpPort;
	MaxLogLenght				= Object.ExternalInteraction.MaxLogLenght;
	LastFullSynchronizationTime = Object.ExternalInteraction.LastFullSynchronizationTime;
	FullSynchronizationTime		= Object.ExternalInteraction.FullSynchronizationTime;

	vDefaultChannel = cmGetObjectRefByExternalSystemCode(Hotel, "SamsungLYNK", "RoomInterfaceTypes", "DefaultChannel", False);
	If vDefaultChannel <> Undefined Then
		DefaultChannelList = vDefaultChannel;	
	EndIf;
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomInterfaceTypesList(pHotel)
	vChannelListStart = New ValueList();
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	RoomInterfaceTypes.Ref AS Ref
	|FROM
	|	Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
	|WHERE
	|	NOT RoomInterfaceTypes.DeletionMark
	|	AND RoomInterfaceTypes.Hotel = &qHotel
	|	AND RoomInterfaceTypes.InterfaceType = VALUE(Enum.InterfaceTypes.TV)
	|	AND (RoomInterfaceTypes.TurnOnParameters LIKE ""PPVSet_0;""
	|			OR RoomInterfaceTypes.TurnOnParameters LIKE ""PPVSet_1;""
	|			OR RoomInterfaceTypes.TurnOnParameters LIKE ""PPVSet_2;""
	|			OR RoomInterfaceTypes.TurnOnParameters LIKE ""PPVSet_3;"")";
	vQuery.SetParameter("qHotel", pHotel);
	vResult = vQuery.Execute().Unload();
	For Each vRow In vResult Do
		vChannelListStart.Add(vRow.Ref)	
	EndDo;
	Return vChannelListStart;
EndFunction // GetRoomInterfaceTypesList

// -----------------------------------------------------------------------------
&AtServer
Procedure ManualSync_AtServer(rMessage)
	If SamsungLYNK.Hello(Object.ExternalInteraction, rMessage) Then
		vObj = Object.ExternalInteraction.GetObject();
		vObj.LastFullSynchronizationTime = CurrentSessionDate();
		vObj.Write();	
		LastFullSynchronizationTime = vObj.LastFullSynchronizationTime;
	EndIf;
EndProcedure // ActionExecute_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionExecute_AtServer()
	SamsungLYNK.Sync(Object.ExternalInteraction);		
EndProcedure // ActionExecute_AtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceExtraParameters(pExtraParamssStructure, pExtraParams) Export
	If pExtraParamssStructure <> Undefined Then
		AfterChoiceExtraParametersAtServer(pExtraParamssStructure, pExtraParams);
		ShowMessageBox(, NStr("en = 'Completed'; de = 'Abgeschlossen'; ru = 'Завершено'"));
	EndIf;
EndProcedure // AfterChoiceExtraParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterChoiceExtraParametersAtServer(pExtraParamssStructure, pExtraParams) 
	vParameters = New ValueTable;
	vParameters.Columns.Add("Description");
	vParameters.Columns.Add("TurnOnParameters");
	vParameters.Columns.Add("TurnOffParameters");
	
	vExtraParamsForCheckIn = "";
	vExtraParamsForCheckInDes = "(";
	If pExtraParamssStructure.Property("poweron") And ValueIsFilled(pExtraParamssStructure.poweron) Then
		vExtraParamsForCheckIn = vExtraParamsForCheckIn + "poweron=" + pExtraParamssStructure.poweron + ";";
		vExtraParamsForCheckInDes = vExtraParamsForCheckInDes + NStr("en = 'Power on: '; de = 'Power on:'; ru = 'Power on: '") + pExtraParamssStructure.poweron; 
	EndIf;
	If pExtraParamssStructure.Property("smarthubapp") And ValueIsFilled(pExtraParamssStructure.smarthubapp) Then
		vExtraParamsForCheckIn = vExtraParamsForCheckIn + "smarthubapp=" + pExtraParamssStructure.smarthubapp + ";";
		vExtraParamsForCheckInDes = vExtraParamsForCheckInDes + ?(vExtraParamsForCheckInDes <> "(", ", ", "") + NStr("en = 'Smart Hub: '; de = 'Smart Hub: '; ru = 'Smart Hub: '") + pExtraParamssStructure.smarthubapp;
	EndIf;
	vExtraParamsForCheckInDes = vExtraParamsForCheckInDes + ")";
	vNewRow 					= vParameters.Add();
	vNewRow.Description 		= NStr("en = 'Check in / Check out '; de = 'Check in / Check out '; ru = 'Заезд / Выезд '") + ?(vExtraParamsForCheckInDes <> "()", vExtraParamsForCheckInDes, "");
	vNewRow.TurnOnParameters 	= "CheckIn;" + vExtraParamsForCheckIn;
	vNewRow.TurnOffParameters 	= "CheckOut;";
	
	vExtraParamsForMessage = "";
	vExtraParamsForMessageDes = "(";
	If pExtraParamssStructure.Property("messagetype") And ValueIsFilled(pExtraParamssStructure.messagetype) Then
		vExtraParamsForMessage = vExtraParamsForMessage + "messagetype=" + pExtraParamssStructure.messagetype + ";"; 	
		vExtraParamsForMessageDes = vExtraParamsForMessageDes + NStr("en = 'Message type: '; de = 'Message type: '; ru = 'Message type: '") + pExtraParamssStructure.messagetype;
	EndIf;
	If pExtraParamssStructure.Property("closetime") And ValueIsFilled(pExtraParamssStructure.closetime) Then
		vExtraParamsForMessage = vExtraParamsForMessage + "closetime=" + pExtraParamssStructure.closetime + ";"; 	
		vExtraParamsForMessageDes = vExtraParamsForMessageDes + ?(vExtraParamsForMessageDes <> "(", ", ", "") + NStr("en = 'Close time: '; de = 'Close time: '; ru = 'Close time: '") + pExtraParamssStructure.closetime + "S";
	EndIf;
	vExtraParamsForMessageDes = vExtraParamsForMessageDes + ")";
	
	vNewRow 					= vParameters.Add();
	vNewRow.Description 		= NStr("en = 'Message '; de = 'Message '; ru = 'Сообщение '") + ?(vExtraParamsForMessageDes <> "()", vExtraParamsForMessageDes, "");
	vNewRow.TurnOnParameters 	= "Message;" + vExtraParamsForMessage;
	vNewRow.TurnOffParameters 	= "";
	
	vNewRow 					= vParameters.Add();
	vNewRow.Description 		= NStr("en = 'Enable smart hub app'; de = 'Aktivieren Sie die Smart Hub-App'; ru = 'Включить Smart hub app'");
	vNewRow.TurnOnParameters 	= "SmartHubOn;";
	vNewRow.TurnOffParameters 	= "";
	
	vNewRow 					= vParameters.Add();
	vNewRow.Description 		= NStr("en = 'Disable smart hub app'; de = 'Deaktivieren Sie die Smart Hub-App'; ru = 'Отключить Smart hub app'");
	vNewRow.TurnOnParameters 	= "SmartHubOff;";
	vNewRow.TurnOffParameters 	= "";
	
	vNewRow 					= vParameters.Add();
	vNewRow.Description 		= NStr("en = 'Bill info update for specific guest'; de = 'Rechnungsinfo-Update für einen bestimmten Gast'; ru = 'Обновление информации о счете для конкретного гостя'");
	vNewRow.TurnOnParameters 	= "BillingInfoUpdated;";
	vNewRow.TurnOffParameters 	= "";
	
	vNewRow 					= vParameters.Add();
	vNewRow.Description 		= NStr("en = 'Channel list 0st level'; de = 'Kanalliste 0st Level'; ru = 'Список каналов 0-го уровня'");
	vNewRow.TurnOnParameters 	= "PPVSet_0;";
	vNewRow.TurnOffParameters 	= "";
	
	vNewRow 					= vParameters.Add();
	vNewRow.Description 		= NStr("en = 'Channel list 1st level'; de = 'Kanalliste 1st Level'; ru = 'Список каналов 1-го уровня'");
	vNewRow.TurnOnParameters 	= "PPVSet_1;";
	vNewRow.TurnOffParameters 	= "";
	
	vNewRow 					= vParameters.Add();
	vNewRow.Description 		= NStr("en = 'Channel list 2st level'; de = 'Kanalliste 2st Level'; ru = 'Список каналов 2-го уровня'");
	vNewRow.TurnOnParameters 	= "PPVSet_2;";
	vNewRow.TurnOffParameters 	= "";
	
	vNewRow 					= vParameters.Add();
	vNewRow.Description 		= NStr("en = 'Channel list 3st level'; de = 'Kanalliste 3st Level'; ru = 'Список каналов 3-го уровня'");
	vNewRow.TurnOnParameters 	= "PPVSet_3;";
	vNewRow.TurnOffParameters 	= "";

	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	RoomInterfaceTypes.TurnOnParameters AS TurnOnParameters,
		|	RoomInterfaceTypes.Code AS Code
		|FROM
		|	Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
		|WHERE
		|	NOT RoomInterfaceTypes.DeletionMark
		|	AND RoomInterfaceTypes.Hotel = &qHotel
		|	AND RoomInterfaceTypes.InterfaceType = &qInterfaceType";
	
	vQuery.SetParameter("qHotel", Hotel);
	vQuery.SetParameter("qInterfaceType", Enums.InterfaceTypes.TV);
	
	vQueryResult = vQuery.Execute().Unload();
	
	vCode = 0;
	For Each vRow In vQueryResult Do
		Try
			If StrFind(vRow.Code, "S") Then 
				vRCode = Number(TrimAll(StrReplace(vRow.Code, "S", ""))); 
				If vCode < vRCode Then
					vCode = vRCode;
				EndIf;
			EndIf;
		Except
		EndTry;
	EndDo;
	vCode = vCode + 1;	
	For Each vRow In vParameters Do
		vFindRow = vQueryResult.Find(vRow.TurnOnParameters, "TurnOnParameters");
		If vFindRow = Undefined Then
			vNewObj 				= Catalogs.RoomInterfaceTypes.CreateItem();
			vNewObj.Code			= "S" + TrimAll(vCode);
			vNewObj.Hotel 			= Hotel;
			vNewObj.InterfaceType 	= Enums.InterfaceTypes.TV;
			FillPropertyValues(vNewObj, vRow);
			vNewObj.Write();
			vCode = vCode + 1;
		EndIf;
	EndDo;
EndProcedure // CreateRoomInterfaceTypes_AtServer

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
	
	If Not ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
		
	vIntParObj 				 		   = Object.ExternalInteraction.GetObject();
	vIntParObj.IsActive 	 		   = Active;
	vIntParObj.Hotel 			 	   = Hotel;
	vIntParObj.DebugMode 	 		   = Debug;
	vIntParObj.InteractionID 		   = InteractionID;
	vIntParObj.HttpServer    		   = HttpServer;
	vIntParObj.HttpPort   			   = HttpPort;
	vIntParObj.MaxLogLenght  		   = MaxLogLenght;
	vIntParObj.FullSynchronizationTime = FullSynchronizationTime;

	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteExternalSystem(pCode, pObjectRef, pObjectTypeName, pHotel, pInteractionParameters)
	If ValueIsFilled(pInteractionParameters) Then
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 		= pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pCode;
		vRecordManager.ObjectRef 			= pObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
	EndIf;
EndProcedure // DeleteExternalSystem

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeExternalSystem(pOldCode, pOldObjectRef, pCode, pObjectRef, pObjectTypeName, pHotel, pInteractionParameters)
	If ValueIsFilled(pInteractionParameters) Then
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 		= pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pOldCode;
		vRecordManager.ObjectRef 			= pOldObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
				
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 		= pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pCode;
		vRecordManager.ObjectRef 			= pObjectRef;
		vRecordManager.Write(true);
	EndIf;
EndProcedure // ChangeExternalSystem

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

#EndRegion

