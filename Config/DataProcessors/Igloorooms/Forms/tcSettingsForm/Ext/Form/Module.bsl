
 #Region FormEventHandlers
 
// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj, "Object");
	Obj.GetTemplates(TemplatesDescriptions);
	
	LoadInteractionParameters();
	
	GetMappings();
			
	If IsInRoleAtServer("Administrator") And Not (Object.DataProcessor = Undefined) Then
		
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
EndProcedure // OnCreateAtServer
 
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

 #EndRegion
   
 #Region FormCommandsEventHandlers
  
// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure // Save

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
			
			vScheduleDlg.Show(New NotifyDescription("SetupBackgroundJobSchedule_AfterInput", ThisObject, New Structure()));		
		EndIf;
	Else 
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure // SetupBackgroundJobSchedule

 #EndRegion
 
 #Region Private
 
 // -----------------------------------------------------------------------------
 &AtServer
Procedure GetMappings()
	// Get from ExternalSystemsObjectCodesMappings
	GetTemplatesMappings();
	GetOtherTablesMappings();
	
	// Get from ExternalSystemIntegrationData 
	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "RoomRates", "id");
	For Each vRow In vRoomRates Do
		vNewRow = RoomRates.Add();
		vNewRow.Code = vRow.ExternalSystemDataCode;
		vNewRow.RoomRate = vRow.RefKey1;
		vNewRow.ServicePackage = vRow.RefKey2;
	EndDo;
EndProcedure // GetMappings
 
// -----------------------------------------------------------------------------
&AtServer
Procedure GetTemplatesMappings()
	vCHMStatusesTable = New ValueTable;
	vCHMStatusesTable.Columns.Add("Code", New TypeDescription("String", New StringQualifiers(50)));
	vCHMStatusesTable.Columns.Add("ObjectTypeName", New TypeDescription("String", New StringQualifiers(36)));
	For Each vRow In TemplatesDescriptions Do
		vDescr = vRow.Description;
		vCodesList = DataProcessors.Igloorooms.GetTemplate(vDescr);
		vCount = vCodesList.TableHeight - 1;
		For i = 2 To (vCount + 1) Do
			Try
				vCode = TrimAll(vCodesList.Area(i, 1, i, 1).Text);
				
				vNewRow = vCHMStatusesTable.Add();
				vNewRow.Code = NStr(vCode, "en");
				vNewRow.ObjectTypeName = vDescr;
			Except
				vErrorMsg = ErrorDescription(); 
				tcCommonFunctionOnClientServer.TextMessage(vErrorMsg);
			EndTry;
		EndDo;
	EndDo;
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Descriptions.Description AS Description
	|INTO Descriptions
	|FROM
	|	&qDescriptions AS Descriptions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CHMStatusesTable.Code AS Code,
	|	CHMStatusesTable.ObjectTypeName AS ObjectTypeName
	|INTO IglooroomsStatuses
	|FROM
	|	&qCHMStatusesTable AS CHMStatusesTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
	|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef,
	|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName
	|INTO Mappings
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName IN
	|			(SELECT
	|				Descriptions.Description AS Description
	|			FROM
	|				Descriptions)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IglooroomsStatuses.Code AS Code,
	|	Mappings.ObjectRef AS Value,
	|	CASE
	|		WHEN Mappings.ObjectTypeName IS NULL
	|			THEN IglooroomsStatuses.ObjectTypeName
	|		ELSE Mappings.ObjectTypeName
	|	END AS ObjectTypeName
	|FROM
	|	IglooroomsStatuses AS IglooroomsStatuses
	|		LEFT JOIN Mappings AS Mappings
	|		ON IglooroomsStatuses.Code = Mappings.ObjectExternalCode
	|
	|UNION ALL
	|
	|SELECT
	|	Mappings.ObjectExternalCode,
	|	Mappings.ObjectRef,
	|	Mappings.ObjectTypeName
	|FROM
	|	Mappings AS Mappings
	|WHERE
	|	NOT Mappings.ObjectExternalCode IN
	|				(SELECT
	|					IglooroomsStatuses.Code AS Code
	|				FROM
	|					IglooroomsStatuses)";
	vQry.SetParameter("qDescriptions", TemplatesDescriptions.Unload());
	vQry.SetParameter("qCHMStatusesTable", vCHMStatusesTable);
	vQry.SetParameter("qExternalSystemCode", TrimAll(Object.InteractionParameters.InteractionID));
	vQry.SetParameter("qHotel", Hotel);
	vRes = vQry.Execute().Unload();
	
	For Each vRow In TemplatesDescriptions Do
		vDescr = vRow.Description;
		ThisObject[vDescr].Clear();
		ThisObject[vDescr].Load(vRes.Copy(vRes.FindRows(New Structure("ObjectTypeName", vDescr))));
	EndDo;
EndProcedure // GetTemplatesMappings

// --------------------------------------------------------------------------------
&AtServer
Procedure GetOtherTablesMappings()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName,
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS Code,
	|	ExternalSystemsObjectCodesMappings.ObjectRef AS Value
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &ObjTypeName";
	vQuery.SetParameter("ObjTypeName", "RoomTypes");
	vQuery.SetParameter("qExternalSystemCode", TrimAll(Object.InteractionParameters.InteractionID));
	vQuery.SetParameter("qHotel", Hotel);
	
	vQueryResult = vQuery.Execute().Unload();
	vRoomTypesResult = vQueryResult.Copy(vQueryResult.FindRows(New Structure("ObjectTypeName", "RoomTypes")));
	RoomTypes.Clear();
	RoomTypes.Load(vRoomTypesResult);
EndProcedure // GetOtherTablesMappings

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveMappings()
	// Save to ExternalSystemsObjectCodesMappings
	vDescripions = TemplatesDescriptions.Unload();
	vNewDescrRT = vDescripions.Add();
	vNewDescrRT.Description = "RoomTypes";
	SaveExtSysObjCodesMappings(vDescripions);
	
	// Save to ExternalSystemIntegrationData
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "RoomRates");
	For Each vRoomRateRow in RoomRates Do
		If ValueIsFilled(vRoomRateRow.RoomRate) Or ValueIsFilled(vRoomRateRow.ServicePackage) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "RoomRates", "id", vRoomRateRow.RoomRate,
																		 vRoomRateRow.ServicePackage, TrimAll(vRoomRateRow.Code), TrimAll(vRoomRateRow.Code));
		EndIf;
	EndDo;
EndProcedure // SaveMappings

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveExtSysObjCodesMappings(pTables)
	For Each vRow In pTables Do
		vDescr = vRow.Description;
		vRecordSet = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordSet();
		vRecordSet.Filter.Hotel.Set(Hotel);
		vRecordSet.Filter.ExternalSystemCode.Set(TrimAll(Object.InteractionParameters.InteractionID));
		vRecordSet.Filter.ObjectTypeName.Set(vDescr);
		vRecordSet.Write(True);
		
		For Each vRow In ThisObject[vDescr] Do
			If Not IsBlankString(vRow.Code) 
			   And ValueIsFilled(vRow.Value) Then
				vNewRecord = vRecordSet.Add();
				
				vNewRecord.Hotel = Hotel;
				vNewRecord.ExternalSystemCode = TrimAll(Object.InteractionParameters.InteractionID);
				vNewRecord.ObjectTypeName = vDescr;
				vNewRecord.ObjectExternalCode = TrimAll(vRow.Code);
				vNewRecord.ObjectRef = vRow.Value;
			EndIf;
		EndDo;
		vRecordSet.Write(True);
	EndDo;
EndProcedure // SaveExtSysObjCodesMappings

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	If CheckFilling() Then
		SaveInteractionParameters();
		
		SaveMappings();

		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Saved!'; de = 'Gerettet!'; ru = 'Сохранено!'"));
	EndIf;
EndProcedure // Save_AtServer

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRole	 - String - Role 
// 
// Returns:
//  Boolean - Is the role available to the user
//
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
				EndIf;

				ScheduledJob.UserName 	= vUsrName;
				ScheduledJob.Schedule 	= Object.Schedule;
				ScheduledJob.Use 		= UseBackgroundJob;
			EndIf;
			
			If ScheduledJob.Parameters.Count() = 0 Then
				ScheduledJob.Parameters.Add(Object.DataProcessor.Key);
			EndIf;
			
		Else 	
			
			For Each vScheduledJob In Metadata.ScheduledJobs Do   
				If vScheduledJob.Name = "RunDataProcessor" Then
					
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
			EndIf;
			
			ScheduledJob.Description 				= Object.DataProcessor.Description;
			ScheduledJob.Key 						= Object.DataProcessor.Key;
			ScheduledJob.Use 						= UseBackgroundJob;
			ScheduledJob.UserName 					= vUsrName;
			ScheduledJob.RestartCountOnFailure 		= 0;
			ScheduledJob.RestartIntervalOnFailure 	= 0;
			
			If Object.Schedule = Undefined Or pRead Then 
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
	LastFullSynchronizationTime = Object.InteractionParameters.LastFullSynchronizationTime;
	HttpServer					= Object.InteractionParameters.HttpServer;
	HttpAddress					= Object.InteractionParameters.HttpAddress;
	HttpUseSsl					= Object.InteractionParameters.HttpUseSsl;
	DebugMode     	  			= Object.InteractionParameters.DebugMode;
	MaxLogLenght                = Object.InteractionParameters.MaxLogLenght;
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
		
	vIntParObj 								  = Object.InteractionParameters.GetObject();
	vIntParObj.Hotel   						  = Hotel;
	vIntParObj.LastFullSynchronizationTime    = LastFullSynchronizationTime;
	vIntParObj.HttpServer					  = HttpServer;
	vIntParObj.HttpAddress					  = HttpAddress;
	vIntParObj.HttpUseSsl					  = HttpUseSsl; 
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

// -----------------------------------------------------------------------------
&AtClient
Procedure ManualSync(Command)
	ManualSyncAtServer();
EndProcedure // ManualSync

// -----------------------------------------------------------------------------
&AtServer
Procedure ManualSyncAtServer()
	If CheckFilling() Then
		vObj = FormAttributeToValue("Object");
		vObj.pmRun();
		ValueToFormAttribute(vObj, "Object");
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
	EndIf;
EndProcedure // ManualSyncAtServer

#EndRegion
