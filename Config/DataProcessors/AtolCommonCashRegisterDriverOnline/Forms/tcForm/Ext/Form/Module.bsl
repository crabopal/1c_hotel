
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisObject.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	LoadInteractionParameters();
	
	FillCashRegisters();
	FillCashRegistersMapping();
	
	If IsInRoleAtServer("Administrator") And vDataProcessor <> Undefined Then
		
		SetupBackgroundJobSchedule_AtServer(True);
		
		Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
		If UseBackgroundJob Then
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
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
Procedure UseBackgroundJobOnChange(pItem)
	If Not CheckFilling() Then
		UseBackgroundJob = False;
		Return;
	EndIf;
	
	If Not ValueIsFilled(Employee) Then
		UseBackgroundJob = False;
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
	
	If Schedule = Undefined Then
		UseBackgroundJob = False;
		Raise(NStr("en='Schedule not setuped!';ru='Не настроено расписание!';"));
	EndIf;
	
	Save_AtServer();
	SetupBackgroundJobSchedule_AtServer();
	
	Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
	If UseBackgroundJob Then
		Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
	EndIf;
EndProcedure // UseBackgroundJobOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeeOnChange(pItem)
	If Not CheckFilling() Then
		UseBackgroundJob = False;
		Return;
	EndIf;
	
	If Not ValueIsFilled(Employee) Then
		UseBackgroundJob = False;
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
	
	If Schedule = Undefined Then
		UseBackgroundJob = False;
		Raise(NStr("en='Schedule not setuped!';ru='Не настроено расписание!';"));
	EndIf;
	
	SetupBackgroundJobSchedule_AtServer();
	
	Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
	If UseBackgroundJob Then
		Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");		
	EndIf;
EndProcedure // EmployeeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Save_AtServer();
EndProcedure // Save

// -----------------------------------------------------------------------------
&AtClient
Async Procedure SetupBackgroundJobSchedule(pCommand)
	If Not ValueIsFilled(Employee) Then
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
	
	If Not IsInRoleAtServer("Administrator") Then
		Raise(NStr("en='A background job can be configured by system administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
	EndIf;
	
	vScheduleDlg = New ScheduledJobDialog(Schedule);
	vSchedule = Await vScheduleDlg.DoAsync();
	If vSchedule = Undefined Then
		Return;
	EndIf;
	
	Schedule = vSchedule;
	SetupBackgroundJobSchedule_AtServer();
	
	Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
	If UseBackgroundJob Then
		Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");		
	EndIf;
EndProcedure // SetupBackgroundJobSchedule

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshToken(pCommand)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	RefreshTokenAtServer();
EndProcedure // RefreshToken

// -----------------------------------------------------------------------------
&AtClient
Async Procedure ExecuteProcessing(pCommand)
	vSpreadsheetDocument = New SpreadsheetDocument;
	If Not ExecuteProcessingAtServer(vSpreadsheetDocument) Then
		vSpreadsheetDocument.Show();
		Return;
	EndIf;
	
	Await DoMessageBoxAsync(NStr("en = 'Completed'; de = 'Vollendet'; ru = 'Выполнено'"));
EndProcedure // ExecuteProcessing

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	SaveInteractionParameters();
	SaveCashRegistersTable();
	Obj = FormAttributeToValue("Object");
	Obj.pmSaveDataProcessorAttributes();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	vInteractionParameters = Object.InteractionParameters;
	
	HttpServer = vInteractionParameters.HttpServer;
	HttpAddress = vInteractionParameters.HttpAddress;
	Login = vInteractionParameters.Login;
	Password = vInteractionParameters.Password;
	AccessToken = vInteractionParameters.OAuth_AccessToken;
	SessionStartTime = vInteractionParameters.SessionStartTime;
	Active = vInteractionParameters.IsActive;
	Debug = vInteractionParameters.DebugMode;
	MaxLogLenght = vInteractionParameters.MaxLogLenght;
	HttpUseSsl = vInteractionParameters.HttpUseSsl;
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	vIntParObj = Object.InteractionParameters.GetObject();
	vIntParObj.HttpServer = HttpServer;
	vIntParObj.HttpAddress = HttpAddress;
	vIntParObj.Login = Login;
	vIntParObj.Password = Password;
	vIntParObj.SessionStartTime = SessionStartTime;
	vIntParObj.IsActive = Active;
	vIntParObj.DebugMode = Debug;
	vIntParObj.MaxLogLenght = MaxLogLenght;
	vIntParObj.HttpUseSsl = HttpUseSsl;
	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction // IsInRoleAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetupBackgroundJobSchedule_AtServer(pRead = False)
	Try
		vWrite = False;
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key",Object.DataProcessor.Key));
		
		If ArrayScheduledJob.Count() > 0 Then
			vScheduledJob = ArrayScheduledJob[0];
			
			If pRead Then
				Employee = cmGetEmployeeByUserName(vScheduledJob.UserName);
				Schedule = vScheduledJob.Schedule;
				UseBackgroundJob = vScheduledJob.Use;
			Else
				vUserNames = cmGetUserUUIDsByEmployee(Employee);
				If vUserNames.Count() > 0 Then
					vUsrName = vUserNames[0].UserName;
				Else
					vMessage = NStr("en = 'The user of the information base was not found!'; de = 'Der Benutzer der Informationsbasis wurde nicht gefunden!'; ru = 'Пользователь информационной базы не найден!'");
					tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Endif;
				vScheduledJob.UserName = vUsrName;
				vScheduledJob.Schedule = Schedule;
				vScheduledJob.Use = UseBackgroundJob;
				vWrite = True;
			EndIf;
			
			If vScheduledJob.Parameters.Count() = 0 Then
				vScheduledJob.Parameters.Add(Object.DataProcessor.Key);
				vWrite = True;
			EndIf;
		Else
			vScheduledJob = ScheduledJobs.CreateScheduledJob(Metadata.ScheduledJobs.RunDataProcessor);
			
			vUserNames = cmGetUserUUIDsByEmployee(Employee);
			If vUserNames.Count() > 0 Then
				vUsrName = vUserNames[0].UserName;
			Else
				vMessage = NStr("en = 'The user of the information base was not found!'; de = 'Der Benutzer der Informationsbasis wurde nicht gefunden!'; ru = 'Пользователь информационной базы не найден!'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
			Endif;
			
			vScheduledJob.Description = Object.DataProcessor.Description;
			vScheduledJob.Key = Object.DataProcessor.Key;
			vScheduledJob.Use = UseBackgroundJob;
			vScheduledJob.UserName = vUsrName;
			vScheduledJob.RestartCountOnFailure = 0;
			vScheduledJob.RestartIntervalOnFailure = 0;
			
			If Schedule = Undefined Or pRead Then
				Schedule = vScheduledJob.Schedule;
			Else
				vScheduledJob.Schedule = Schedule;
			EndIf;
			
			If vScheduledJob.Parameters.Count() = 0 Then
				vScheduledJob.Parameters.Add(Object.DataProcessor.Key);
			EndIf;
			vWrite = True;
		EndIf;
		
		If vWrite Then
			vScheduledJob.Write();
		EndIf;
	Except
		tcCommonFunctionOnClientServer.TextMessage(ErrorProcessing.BriefErrorDescription(ErrorInfo()), MessageStatus.Attention);
	EndTry;
EndProcedure // SetupBackgroundJobSchedule_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCashRegisters()
	CashRegisters.Clear();
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	CashRegisters.Ref AS CashRegister
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	NOT CashRegisters.DeletionMark
	|	AND CashRegisters.CashRegisterDriver = VALUE(Enum.CashRegisterDrivers.AtolCommonCashRegisterDriverOnline)
	|
	|ORDER BY
	|	CashRegisters.SortCode";
	vCashRegisters = vQ.Execute().Unload();
	For Each vCashRegister In vCashRegisters Do
		FillPropertyValues(CashRegisters.Add(), vCashRegister);
	EndDo;
EndProcedure // FillCashRegisters

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCashRegistersMapping()
	vCashRegistersMapping = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "CashRegisters");
	
	Try
		For Each vCashRegisterMappingRow In vCashRegistersMapping Do
			vCashRegistersArr = CashRegisters.FindRows(New Structure("CashRegister", vCashRegisterMappingRow.RefKey1));
			For Each vCashRegistersRow In vCashRegistersArr Do
				vCashRegistersRow.Use = True;
			EndDo;
		EndDo;
	Except
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to load cash registers mappings!'; de = 'Failed to load cash registers mappings!'; ru = 'Не удалось загрузить сопоставления ККМ!'"));
	EndTry;
EndProcedure // FillCashRegistersMapping

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveCashRegistersTable()
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "CashRegisters");
			
	For Each vCashRegister In CashRegisters Do
		If Not vCashRegister.Use Then
			Continue;
		EndIf;
		
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "CashRegisters", "CashRegister", vCashRegister.CashRegister, Undefined, Undefined);
	EndDo;
EndProcedure // SaveCashRegistersTable

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshTokenAtServer()
	Save_AtServer();
	
	vObj = FormAttributeToValue("Object");
	
	vMessage = "";
	If Not vObj.pmRefreshToken(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
		Return;
	EndIf;
	
	LoadInteractionParameters();
EndProcedure // RefreshTokenAtServer

// -----------------------------------------------------------------------------
&AtServer
Function ExecuteProcessingAtServer(rSpreadsheetDocument)
	Save_AtServer();
	
	vObj = FormAttributeToValue("Object");
	If Not vObj.ChecksProcessing(rSpreadsheetDocument) Then
		Return False;
	EndIf;
	
	LoadInteractionParameters();
	Return True;
EndFunction // ExecuteProcessingAtServer

#EndRegion