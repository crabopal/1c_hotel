
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vObj = FormAttributeToValue("Object");
	 
	// Interaction parameters	
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		vObj.InteractionParameters = vInteractionParameters;
	EndIf;
	vDataProcessor = Undefined;
	If ThisObject.Parameters.Property("DataProcessor", vDataProcessor) Then
		vObj.DataProcessor = vDataProcessor;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
	LoadInteractionParameters();
	SetupBackgroundJobSchedule_AtServer(True);
	
	If UseBackgroundJob Then
		Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
	Else 
		Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
	EndIf;
	Items.DownloadODBCDriver.Title = NStr("en = 'Select BD Type'; de = 'Wählen Sie den BD-Typ'; ru = 'Выберите тип БД'");
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Items.BDtype.EditText= "postgresql" Or Items.BDtype.EditText = "mssql" Then
		Items.DownloadODBCDriver.Title = NStr("en = 'Download ODBC driver'; de = 'Laden Sie den ODBC-Treiber herunter'; ru = 'Скачать ODBC драйвер'");		
	EndIf; 
EndProcedure // OnOpen

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

// -----------------------------------------------------------------------------
&AtClient
Procedure BDtypeOnChange(pItem)
	If BDtype = "mssql" Then
		Driver = "SQL Server";
	ElsIf BDtype = "postgresql" Then	
		Driver = "PostgreSQL Unicode";
	Else
		Driver = "";
	EndIf;
EndProcedure // BDtypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	Save_AtServer();
EndProcedure // SaveSettings

// --------------------------------------------------------------------------------
&AtClient
Procedure TestConnect(pCommand)
	If Not Save_AtServer() Then
		Return;
	EndIf;
	
	TestConnectAtServer();
EndProcedure // TestConnect

// --------------------------------------------------------------------------------
&AtClient
Procedure CreateTable(pCommand)
	If Not Save_AtServer() Then
		Return;
	EndIf;
	
	CreateTableAtServer();
EndProcedure // CreateTable

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJob(pCommand)
	#If NOT MobileClient Then
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
	#Else
		ShowMessageBox(, "Background job cant be configured on mobile client!");
	#EndIf
EndProcedure // SetupBackgroundJob

// --------------------------------------------------------------------------------
&AtClient
Procedure DownloadODBCDriver(pCommand)
	If Items.BDtype.EditText= "postgresql" Then
		GotoURL("https://www.postgresql.org/ftp/odbc/versions/msi/");
	ElsIf Items.BDtype.EditText = "mssql" Then
		GotoURL("https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server?view=sql-server-ver16");
	EndIf;	
EndProcedure // DownloadODBCDriver

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

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
	If Not CheckFilling() Then
		UseBackgroundJob = False;
	EndIf;
	
	vUpdate = False;
	Try
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", Object.DataProcessor.Key));
		If ArrayScheduledJob.Count() > 0 Then
			ScheduledJob = ArrayScheduledJob[0];
			
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
				vUpdate = True;
			EndIf;
			
			If ScheduledJob.Parameters.Count() = 0 Then
				ScheduledJob.Parameters.Add(Object.DataProcessor.Key);
				vUpdate = True;
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
			vUpdate = True;
		EndIf;
		
		If vUpdate Then
			ScheduledJob.Write();
		EndIf;
	Except	
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);	
	EndTry;
EndProcedure // SetupBackgroundJobSchedule_AtServer

// -----------------------------------------------------------------------------
&AtServer
Function Save_AtServer()
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	SaveInteractionParameters();
	vObj = FormAttributeToValue("Object");
	vObj.pmSaveDataProcessorAttributes();
	ValueToFormAttribute(vObj, "Object");
	
	Return True;
EndFunction // Save_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	vIP = Object.InteractionParameters;
	If Not ValueIsFilled(vIP) Then
		Return;
	EndIf;
	
	Login = vIP.Login;	
	Password = vIP.Password;	
	Address = vIP.HttpServer;
	Port = vIP.HttpPort;
	BDtype = vIP.InfobaseURL;
	IsActive = vIP.IsActive;
	DatabaseName = vIP.HttpAddress;
	Driver = vIP.WSHost;
	UnloadOnlyInBackgroundJob = vIP.UseClient;
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	vIntParObj = Object.InteractionParameters.GetObject();
	vIntParObj.Login = Login;
	vIntParObj.Password = Password;
	vIntParObj.HttpServer = Address;
	vIntParObj.HttpPort = Port;
	vIntParObj.InfobaseURL = BDtype;
	vIntParObj.IsActive = IsActive;
	vIntParObj.HttpAddress = DatabaseName;
	vIntParObj.WSHost = Driver;  
	vIntParObj.UseClient = UnloadOnlyInBackgroundJob;
	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure TestConnectAtServer()	
	vObj = FormAttributeToValue("Object");
	vObj.pmConnect(True);
EndProcedure // TestConnectAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CreateTableAtServer()	
	vObj = FormAttributeToValue("Object");
	vObj.CreateTable();
EndProcedure // CreateTableAtServer

#EndRegion