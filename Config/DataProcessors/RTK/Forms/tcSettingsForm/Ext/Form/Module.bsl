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
	
	FillDefaultInteractionParameters();
	FillServicesTable();
	LoadHotelAndRoomTable();
	LoadCodeHotelAndRoomTable();
EndProcedure // OnCreateAtServer

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
EndProcedure // UseBackgroundJobOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	If ValueIsFilled(Object.InteractionParameters) Then
		vServicesList = GetServices();
		If vServicesList.Count() > 0 Then
			vParams = New Structure("MultipleChoice, Title, ValueList", False, NStr("en='Select service...'; ru='Выберите услугу...'; de='Wählen Sie einen Dienstleistung aus...'"), vServicesList);
			OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID, , , New NotifyDescription("AfterChoiceServices", ThisForm));
		EndIf;
	EndIf;	
EndProcedure // ServicesBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesBeforeDeleteRow(pItem, pCancel)
	If ValueIsFilled(Object.InteractionParameters) Then
		DeleteExternalSystemRow(pItem.CurrentData.Code, pItem.CurrentData.Service, "Services", Object.InteractionParameters);
	Else
		pCancel = True;
	EndIf;	
EndProcedure // ServicesBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelAndRoomBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;	
EndProcedure // HotelAndRoomBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelAndRoomBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
EndProcedure // HotelAndRoomBeforeDeleteRow

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure // Save

// -----------------------------------------------------------------------------
&AtClient
Procedure ManualSync(pCommand)
	ManualSync_AtServer();		
EndProcedure // ManualSync

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateRoomInterfaceTypes(pCommand)
	vParametrs = New Structure("DataProcessor, InteractionParameters, ExtraParameters", Object.DataProcessor, Object.InteractionParameters, "");
	vNotifyDescription = New NotifyDescription("AfterChangeExtraParameters", ThisForm);
	OpenForm("DataProcessor.RTK.Form", vParametrs, ThisForm, UUID,,, vNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // CreateRoomInterfaceTypes

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

&AtServer
Procedure ManualSync_AtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmRun();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputServicesCode(pText, pExtraParams) Export 
	If pText <> Undefined And ValueIsFilled(pText) And ValueIsFilled(pExtraParams) Then 
		ChangeExternalSystemRow(pText, pExtraParams, pText, pExtraParams, "Services",, Object.InteractionParameters);	
		FillServicesTable();
	EndIf;
EndProcedure // AfterInputServicesCode

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceServices(pItem, pExtraParams) Export 
	If pItem <> Undefined And ValueIsFilled(pItem.Value) Then
		ShowInputString(New NotifyDescription("AfterInputServicesCode", ThisForm, pItem.Value),, NStr("en = 'Input service code'; de = 'Geben Sie den Dienstleistungcode ein'; ru = 'Введите код услуги'"),, False); 
	EndIf;
EndProcedure // AfterChoiceServices

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	Active		= Object.InteractionParameters.IsActive;
	Debug			= Object.InteractionParameters.DebugMode;
	WSHost			= Object.InteractionParameters.WSHost;
	HttpUseSsl		= Object.InteractionParameters.HttpUseSsl;			
	MaxLogLenght	= Object.InteractionParameters.MaxLogLenght; 
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	vIntParObj				= Object.InteractionParameters.GetObject();
	vIntParObj.IsActive		= Active;
	vIntParObj.DebugMode	= Debug; 
	vIntParObj.WSHost		= WSHost;
	vIntParObj.HttpUseSsl	= HttpUseSsl;
	vIntParObj.MaxLogLenght = MaxLogLenght;
	
	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

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
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction // IsInRoleAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	If CheckFilling() Then
		SaveInteractionParameters();
		
		SaveHotelAndRoomTable();
		
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
	EndIf;
EndProcedure // Save_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDefaultInteractionParameters()
	If ValueIsFilled(Object.InteractionParameters) And Object.InteractionParameters.InteractionID <> "RTK" Then
		vObj = Object.InteractionParameters.GetObject();
		vObj.InteractionID = "RTK";
		vObj.Write();
	EndIf;
EndProcedure // FillDefaultInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeExternalSystemRow(pOldCode, pOldObjectRef, pCode, pObjectRef, pObjectTypeName, pHotel = Undefined, pInteractionParameters)
	If ValueIsFilled(pInteractionParameters) Then
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel                = pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 		= pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pOldCode;
		vRecordManager.ObjectRef 			= pOldObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
		
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel                = pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 		= pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pCode;
		vRecordManager.ObjectRef 			= pObjectRef;
		vRecordManager.Write(true);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteExternalSystemRow(pCode = Undefined, pObjectRef = Undefined, pObjectTypeName, pInteractionParameters)
	If ValueIsFilled(pInteractionParameters) Then
		vRecordManager 							= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.ExternalSystemCode 		= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 			= pObjectTypeName;
		If pCode <> Undefined Then
			vRecordManager.ObjectExternalCode 	= pCode;
		EndIf; 
		If pObjectRef <> Undefined Then     	
			vRecordManager.ObjectRef 			= pObjectRef;
		EndIf;
		vRecordManager.Read();
		
		While vRecordManager.Selected() Do
			vRecordManager.Delete();
		EndDo;
	EndIf;
EndProcedure // DeleteExternalSystemRow

// -----------------------------------------------------------------------------
&AtServer
Function GetServices()
	vServicesList = New ValueList();
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Services.Ref AS Service
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	NOT Services.DeletionMark
	|	AND NOT Services.IsRoomRevenue
	|	AND NOT Services.IsInPrice
	|	AND NOT Services.IsFolder
	|
	|ORDER BY
	|	Services.SortCode,
	|	Services.Code";
	vServicesList.LoadValues(vQuery.Execute().Unload().UnloadColumn("Service")); 
	Return vServicesList;
EndFunction // GetServices

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServicesTable()
	Services.Clear();
	If Not ValueIsFilled(Object.InteractionParameters) Or Not ValueIsFilled(Object.InteractionParameters.InteractionID) Then
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
		|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Services""";
	
	vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
	
	vQueryResult = vQuery.Execute().Unload();
	
	For Each vRow In vQueryResult Do
		vNewRow = Services.Add();
		vNewRow.Code = vRow.ObjectExternalCode;
		vNewRow.Service = vRow.ObjectRef; 
	EndDo;	
EndProcedure // FillServicesTable

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChangeExtraParameters(pJSON, pExtraParameters) Export 
	If pJSON <> Undefined Then  
		CreateRoomInterfaceTypes_AtServer(TrimAll(pJSON));
	Else
		CreateRoomInterfaceTypes_AtServer();	
	EndIf;
EndProcedure // AfterChangeExtraParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure CreateRoomInterfaceTypes_AtServer(pExtraParameters = "")
		vCode = "RTKCHI";
		vRITRef = Catalogs.RoomInterfaceTypes.FindByCode(vCode, False);
		If ValueIsFilled(vRITRef) Then
			vRITObj = vRITRef.GetObject();
		Else
			vRITObj = Catalogs.RoomInterfaceTypes.CreateItem();
		EndIf;
		vRITObj.Code = vCode;
		vRITObj.ExternalSystem = Object.InteractionParameters;
		vRITObj.InterfaceType = Enums.InterfaceTypes.TV;
		vRITObj.Description = NStr("en = 'Check in / Check out'; ru = 'Заезд / Выезд'; de = 'Check in / Check out'");
		vRITObj.Remarks = "";
		vRITObj.TurnOnParameters = "checkin";
		vRITObj.TurnOffParameters = "checkout";
		vRITObj.PeriodOfStayExtentionParameters = "guestchange";
		vRITObj.GuestNameChangeParameters = "guestchange";
		vRITObj.RoomChangeParameters = "guestchange";
		vRITObj.CommandToChangeExtraParameters = "guestchange";
		vRITObj.ExtraParameters = pExtraParameters; 
		vRITObj.ManualCancelIsForbidden = True;
		vRITObj.ApplyToAllRoomGuests = True;
		vRITObj.Write(); 
		
		vCode = "RTKMES";
		vRITRef = Catalogs.RoomInterfaceTypes.FindByCode(vCode, False);
		If ValueIsFilled(vRITRef) Then
			vRITObj = vRITRef.GetObject();
		Else
			vRITObj = Catalogs.RoomInterfaceTypes.CreateItem();
		EndIf;
		vRITObj.Code = vCode;
		vRITObj.ExternalSystem = Object.InteractionParameters;
		vRITObj.InterfaceType = Enums.InterfaceTypes.TV;
		vRITObj.Description = NStr("en = 'Message'; ru = 'Сообщение'; de = 'Message'");
		vRITObj.Remarks = "";
		vRITObj.TurnOnParameters = "sendmessage";
		vRITObj.TurnOffParameters = "";
		vRITObj.PeriodOfStayExtentionParameters = "";
		vRITObj.GuestNameChangeParameters = "";
		vRITObj.CommandToChangeExtraParameters = "";
		vRITObj.ExtraParameters = ""; 
		vRITObj.ManualCancelIsForbidden = True;
		vRITObj.Write();
EndProcedure // CreateRoomInterfaceTypes_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveHotelAndRoomTable()  
	DeleteExternalSystemRow(,, "Hotels", Object.InteractionParameters);
	DeleteExternalSystemRow(,, "Rooms", Object.InteractionParameters);
	For Each vHotel In HotelAndRoom.GetItems() Do
		If ValueIsFilled(vHotel.Code) Then
			ChangeExternalSystemRow(vHotel.Code, vHotel.Hotel, vHotel.Code, vHotel.Hotel, "Hotels",, Object.InteractionParameters);
		EndIf; 
		For Each vRoom In vHotel.GetItems() Do
			If ValueIsFilled(vRoom.Code) Then
				ChangeExternalSystemRow(vRoom.Code, vRoom.Room, vRoom.Code, vRoom.Room, "Rooms", vHotel.Hotel, Object.InteractionParameters);
			EndIf; 	
		EndDo;
	EndDo;
EndProcedure // SaveTemplatesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadHotelAndRoomTable()
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Rooms.Ref AS Room,
		|	Rooms.Owner AS Hotel,
		|	"""" AS Code
		|FROM
		|	Catalog.Rooms AS Rooms
		|WHERE
		|	NOT Rooms.DeletionMark
		|	AND NOT Rooms.IsFolder
		|
		|ORDER BY
		|	Rooms.Owner.SortCode,
		|	Rooms.SortCode
		|TOTALS BY
		|	Hotel";
	ValueToFormAttribute(vQuery.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy), "HotelAndRoom");
EndProcedure // LoadHotelAndRoomTable

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadCodeHotelAndRoomTable()
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Hotels""";
	
	vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
	vHotelsResult = vQuery.Execute().Unload();
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Rooms""";
	
	vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
	vRoomsResult = vQuery.Execute().Unload();
	
	For Each vHotel In HotelAndRoom.GetItems() Do
		vHotelArr = vHotelsResult.FindRows(New Structure("ObjectRef", vHotel.Hotel));
		If vHotelArr.Count() > 0 Then
			vHotel.Code = vHotelArr[0].ObjectExternalCode;   
		EndIf; 
		For Each vRoom In vHotel.GetItems() Do
			vRoomArr = vRoomsResult.FindRows(New Structure("ObjectRef", vRoom.Room));
			If vRoomArr.Count() > 0 Then
				vRoom.Code = vRoomArr[0].ObjectExternalCode;   
			EndIf;
		EndDo;
	EndDo;
EndProcedure // LoadCodeHotelAndRoomTable

// -----------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	If NOT Active Then
		Debug = False;
	EndIf;
EndProcedure // ActiveOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	If Debug Then
		Active = True;
	EndIf;
EndProcedure // DebugOnChange

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

#EndRegion