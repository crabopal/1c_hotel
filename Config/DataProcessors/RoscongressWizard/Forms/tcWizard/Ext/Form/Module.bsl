
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj, "Object");

	#If NOT MobileClient Then
		If  IsInRoleAtServer("Administrator") And Not(vDataProcessor = Undefined) Then
					
			ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", vDataProcessor.Key));	
			
			If ArrayScheduledJob.Count() > 0 Then
				Object.Schedule = ArrayScheduledJob[0].Schedule;
				UseJob =ArrayScheduledJob[0].Use;
				Employee = cmGetEmployeeByUserName(ArrayScheduledJob[0].UserName);
				
				If UseJob Then
					vMsg = NStr("en='Background job is configured and started'; 
								|ru='Фоновое задание настроено и запущено'; 
								|de='Ein Hintergrundjob ist konfiguriert und läuft'");
					Items.Text_BackgroundJobInfo.Title = vMsg;
				Else 
					Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
				EndIf;
			Else
				Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is not configured'; ru='Фоновое задание не настроено'; de='Ein Hintergrundjob ist nicht konfiguriert'");
			EndIf;
		Else
			Items.Group_BackgroundJob.Visible = False;
			tcCommonFunctionOnClientServer.TextMessage("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'");
		EndIf;
	#Else
		Items.Group_BackgroundJob.Visible = False;
	 	ShowMessageBox(, "Background job cant be configured on mobile client!");
	#EndIf
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomTypesBeforeDeleteRow(Item, Cancel)
	If ValueIsFilled(Item.CurrentData.TrueCode) Then		
		DeleteExternalSystemRow(Item.CurrentData.TrueCode, Item.CurrentData.RoomType, "RoomTypes")
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomTypesBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	If Clone Then 
		Cancel = True;
		vNewRow 		= RoomTypes.Add();
		vNewRow.Code 	= Item.CurrentData.Code;
	EndIf; 
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure UseBackgroundJobOnChange(Item)
	If ValueIsFilled(Employee) Then
		If CheckInteractionParametersDate() Then
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
					SaveRoomTypes("Roscongress");
					SetupBackgroundJobSchedule_AtServer();
				EndIf;
			Else
				UseBackgroundJob = False;
				Raise(NStr("en='Schedule not setuped!';ru='Не настроено расписание!';"));
			EndIf;
		Else
			UseBackgroundJob = False;	
		EndIf;
	Else 
		UseBackgroundJob = False;
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Save(Command)
	If CheckRoomTypeCodes() Then 
		SaveRoomTypes("Roscongress");
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(Command)
	#If NOT MobileClient Then
		If ValueIsFilled(Employee)  Then
			If  Not IsInRoleAtServer("Administrator") Then
				Raise(NStr("en='A background job can be configured by system administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
			Else 				
				//vScheduleDlg = New ScheduledJobDialog(Object.Schedule);
				//
				//vScheduleDlg.Show(New NotifyDescription);		
			EndIf;
		Else 
			Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
		EndIf;
	#Else
	 	ShowMessageBox(,"Background job cant be configured on mobile client!");
	#EndIf
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure TestAllotment(Command)
	TestAllotment_AtServer();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure OnOpenAtServer()
	Object.InteractionParameters = GetInterectionParameter("Roscongress");
	LoadRoomTypes("Roscongress");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

// --------------------------------------------------------------------------------
&AtClient
Function CheckRoomTypeCodes()
	For each vRow in RoomTypes Do
		If StrFind(vRow.Code,"[") > 0 or StrFind(vRow.Code,"]") > 0 Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Code cannot contain ""["" and ""]"" symbols'; ru = 'Код не может содержать символы ""["" и ""]""'")); //#Translate
			Return False;
		EndIf;
	EndDo;
	Return True;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Function GetInterectionParameter(pInterectionID)
	vResult = Undefined;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	ExternalSystemInteractions.Ref
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	ExternalSystemInteractions.InteractionID = &qInteractionID
	|	AND NOT ExternalSystemInteractions.DeletionMark";
	
	vQuery.SetParameter("qInteractionID", pInterectionID);
	
	vQueryResult = vQuery.Execute().Unload();
	
	For each vQueryResultRow in vQueryResult Do
		vResult = vQueryResultRow.Ref; 
	EndDo;
	
	If vResult = Undefined Then
		vExtSystemInteractionObj 				= Catalogs.ExternalSystemInteractions.CreateItem();
		vExtSystemInteractionObj.Description 	= "Росконгресс";
		vExtSystemInteractionObj.Code 			= String(New UUID);
		vExtSystemInteractionObj.InteractionID 	= pInterectionID;
		vExtSystemInteractionObj.WSHost 		= "booking.forumvostok.ru";
		vExtSystemInteractionObj.Write();
		vResult = vExtSystemInteractionObj.Ref;
	EndIf;
	
	Return vResult;	
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadRoomTypes(pExternalSystemCode)
	RoomTypes.Clear();
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectRef,
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomTypes""
	|
	|ORDER BY
	|	ObjectExternalCode";
	
	vQuery.SetParameter("qExternalSystemCode", pExternalSystemCode);
	
	vQueryResult = vQuery.Execute().Unload();
	
	For each vRow in vQueryResult Do
		vCode = vRow.ObjectExternalCode;
		vExtraCodeStartPos 	= StrFind(vRow.ObjectExternalCode,"[");
		If  vExtraCodeStartPos > 0 Then
			vCode = Left(vRow.ObjectExternalCode, vExtraCodeStartPos - 2);	
		EndIf;
		vNewRow 			= RoomTypes.Add();
		vNewRow.Code 		= vCode;
		vNewRow.RoomType	= vRow.ObjectRef;
		vNewRow.OldRoomType	= vRow.ObjectRef;
		vNewRow.TrueCode	= vRow.ObjectExternalCode;
	EndDo;
	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveRoomTypes(pExternalSystemCode)
	If ValueIsFilled(Object.InteractionParameters.Allotment) Then
		For each vRow in RoomTypes Do
			If ValueIsFilled(vRow.TrueCode) Then
				
				vCode = vRow.TrueCode;
				vExtraCodeStartPos 	= StrFind(vRow.TrueCode,"[");
				If  vExtraCodeStartPos > 0 Then
					vCode = Left(vRow.TrueCode, vExtraCodeStartPos - 2);	
				EndIf;
				
				If vCode <> vRow.Code Then
					DeleteExternalSystemRow(vRow.TrueCode, vRow.RoomType, "RoomTypes");
					vTrueCode = GetLastTrueCode(pExternalSystemCode, vRow.Code);
					
					vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();			
					vRecordManager.Hotel 				= vRow.RoomType.Owner;
					vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
					vRecordManager.ObjectTypeName 		= "RoomTypes";
					vRecordManager.ObjectExternalCode 	= vTrueCode;
					vRecordManager.ObjectRef 			= vRow.RoomType;
					vRecordManager.Write(True);
				ElsIf vRow.RoomType <> vRow.OldRoomType Then  
					DeleteExternalSystemRow(vRow.TrueCode, vRow.RoomType, "RoomTypes");
					
					vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();			
					vRecordManager.Hotel 				= vRow.RoomType.Owner;
					vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
					vRecordManager.ObjectTypeName 		= "RoomTypes";
					vRecordManager.ObjectExternalCode 	= vRow.TrueCode;
					vRecordManager.ObjectRef 			= vRow.RoomType;
					vRecordManager.Write(True);	
				Else
					vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
					vRecordManager.Hotel 				= vRow.RoomType.Owner;
					vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
					vRecordManager.ObjectTypeName 		= "RoomTypes";
					vRecordManager.ObjectExternalCode 	= vRow.TrueCode;
					vRecordManager.ObjectRef 			= vRow.RoomType;
					vRecordManager.Read();
					
					If NOT vRecordManager.Selected() Then
						vRecordManager.Hotel 				= vRow.RoomType.Owner;
						vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
						vRecordManager.ObjectTypeName 		= "RoomTypes";
						vRecordManager.ObjectExternalCode 	= vRow.TrueCode;
						vRecordManager.ObjectRef 			= vRow.RoomType;
						vRecordManager.Write(True);
					EndIf;	
				EndIf;			
			Else
				vTrueCode = GetLastTrueCode(pExternalSystemCode, vRow.Code);
				
				vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();			
				vRecordManager.Hotel 				= vRow.RoomType.Owner;
				vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
				vRecordManager.ObjectTypeName 		= "RoomTypes";
				vRecordManager.ObjectExternalCode 	= vTrueCode;
				vRecordManager.ObjectRef 			= vRow.RoomType;
				vRecordManager.Write(True);
			EndIf;
		EndDo;
		LoadRoomTypes(pExternalSystemCode);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill allotemnt in interaction parameters!'; ru = 'Выберите квоту в параметрах взаимодействия!'")); //#Translate
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function GetLastTrueCode(pExternalSystemCode, pObjectExternalCode)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomTypes""
	|	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode LIKE &qObjectExternalCode
	|
	|ORDER BY
	|	ObjectExternalCode";
	
	vQuery.SetParameter("qExternalSystemCode", pExternalSystemCode);
	vQuery.SetParameter("qObjectExternalCode", "%" + pObjectExternalCode + "%");
	
	vQueryResult = vQuery.Execute().Unload();
	
	vResult = pObjectExternalCode;
	
	vMaxExtraCode = 0;
	For each vRow in vQueryResult Do
		vExtraCodeStartPos 	= StrFind(vRow.ObjectExternalCode,"[");
		vExtraCodeEndPos 	= StrFind(vRow.ObjectExternalCode,"]");
		vExtraCode = 1;
		If  vExtraCodeStartPos > 0 Then
			vExtraCode = Number(Mid(vRow.ObjectExternalCode, vExtraCodeStartPos + 1, vExtraCodeEndPos - vExtraCodeStartPos - 1)) + 1;
		EndIf;
		If vMaxExtraCode < vExtraCode Then
			vMaxExtraCode = vExtraCode;
		EndIf;		  
	EndDo;
	
	If vMaxExtraCode <> 0 Then 
		vResult = pObjectExternalCode + " [" + String(vMaxExtraCode) + "]";
	EndIf;
	
	Return vResult; 
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure DeleteExternalSystemRow(pCode, pObjectRef, pObjectTypeName)
	vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
	vRecordManager.Hotel 				= pObjectRef.Owner;
	vRecordManager.ExternalSystemCode 	= Object.InteractionParameters.InteractionID;
	vRecordManager.ObjectTypeName 		= pObjectTypeName;
	vRecordManager.ObjectExternalCode 	= pCode;
	vRecordManager.ObjectRef 			= pObjectRef;
	vRecordManager.Read();
	
	If  vRecordManager.Selected() Then
		vRecordManager.Delete();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function CheckInteractionParametersDate()
	If ValueIsFilled(Object.InteractionParameters.ActiveFromDate) and ValueIsFilled(Object.InteractionParameters.ActiveToDate) Then
		Return True;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill active date in interaction parameters!'; ru = 'Заполните период использования параметров взаимодействия!'"));
		Return False;
	EndIf;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure SetupBackgroundJobSchedule_AtServer()
	Try
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key",Object.DataProcessor.Key));
		
		If ArrayScheduledJob.Count() > 0 Then
			
			ScheduledJob = ArrayScheduledJob[0];
			
			vUserNames = cmGetUserUUIDsByEmployee(Employee);
			If vUserNames.Count() > 0 Then
				vUsrName = vUserNames[0].UserName;
			Else
				vMessage = NStr("en='The user of the information base was not found!';
								|ru='Пользователь информационной базы не найден!';
								|de='Der Benutzer der Informationsbasis wurde nicht gefunden!'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);	
			Endif;
			
			ScheduledJob.UserName = vUsrName;
			ScheduledJob.Schedule = Object.Schedule;
			ScheduledJob.Use = UseBackgroundJob;
			
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
			
			ScheduledJob.Description = Object.DataProcessor.Description;
			ScheduledJob.Key = Object.DataProcessor.Key;
			ScheduledJob.Use = UseBackgroundJob;
			ScheduledJob.UserName = vUsrName;
			ScheduledJob.RestartCountOnFailure = 0;
			ScheduledJob.RestartIntervalOnFailure = 0;
			ScheduledJob.Schedule = Object.Schedule;
			
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
Procedure TestAllotment_AtServer()
	ProlongedOperations.Roscongress_SendAllotment();
EndProcedure

#EndRegion



