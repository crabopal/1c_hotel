
#Region FormEventHandlers 

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	
	If Parameters.Property("DataProcessor") Then
		Object.DataProcessor = Parameters.DataProcessor;
	EndIf; 
	If Not ValueIsFilled(Object.DataProcessor) Then
		Object.DataProcessor = Catalogs.DataProcessors.ActiveUsers;
	EndIf;	
	vDataFromTheObject = FormAttributeToValue("Object");
	vDataFromTheObject.pmLoadDataProcessorAttributes(); 
	ValueToFormAttribute(vDataFromTheObject, "Object");
	
	UpdateAtServer(); 
	
	If IsInRole("Administrator") = False Or StrFind(InfoBaseConnectionString(), "Srvr") = 0 Then
		Items.FormEndSession.Enabled = False;		
		Items.ActiveUsersSettings.Enabled = False;
	EndIf;	
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers                                                  

// --------------------------------------------------------------------------------
&AtClient
Procedure Settings(pCommand)
	vParametr = New Structure("DataProcessor", Object.DataProcessor);
	OpenForm("DataProcessor.ActiveUsers.Form.tcSettingsForm", vParametr, ThisObject, , , , New NotifyDescription("UpdateAfterSaveSettings", ThisObject), FormWindowOpeningMode.LockOwnerWindow);	
EndProcedure // Settings

// --------------------------------------------------------------------------------
&AtClient
Procedure Update(pCommand)
	UpdateAtServer();
EndProcedure // Update

// --------------------------------------------------------------------------------
&AtClient
Procedure EndSession(pCommand)
	vOpen = False;
	EndSessionAtServer(vOpen);
	If vOpen = True Then   
		vParams = New Structure("DataProcessor", Object.DataProcessor);
		OpenFormModal("DataProcessor.ActiveUsers.Form.tcSettingsForm", vParams);
	EndIf;
EndProcedure // EndSession

#EndRegion

#Region FormHeaderItemsEventHandlers

// -------------------------------------------------------------------------------- 
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If pField.Name = "ActiveUsersUser" Then
		pStandardProcessing = False;
		vRowData = Items.ActiveUsers.RowData(pSelectedRow);
		If ValueIsFilled(vRowData.User) Then
			ShowValue(, vRowData.User);
		EndIf;
	EndIf;
EndProcedure // ListSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure ApplicationOnChange(pItem)
	SetFilter();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PermissionGroupsOnChange(pItem)    
	SetFilter();
EndProcedure // SetOfRightsOnChange

#EndRegion

#Region Private                 

// --------------------------------------------------------------------------------
&AtClient
Procedure UpdateAfterSaveSettings(pResult, pAddParams) Export
	UpdateAtServer();	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateAtServer()
	ActiveUsers.Clear();
	
	Items.Application.ChoiceList.Clear();
	Items.PermissionGroups.ChoiceList.Clear();
	
	vStructureOf = GetAppTranslationss();

	vCurSesNum = InfoBaseSessionNumber();
	For Each vSession In GetInfoBaseSessions() Do
		vStringOfTable = ActiveUsers.Add();
		
		vEmp = cmGetEmployeeByUserUUID(String(vSession.User.UUID));
		vStringOfTable.User = vEmp;
		vStringOfTable.Computer = vSession.ComputerName;
		vStringOfTable.Application = vSession.ApplicationName; 
		vApplication = vStructureOf[vStringOfTable.Application];
		If vApplication <> Undefined Then
			vStringOfTable.Application = vApplication;
		EndIf;
		vStringOfTable.BeginningOfWork = vSession.SessionStarted;
		vStringOfTable.SessionNumber = vSession.SessionNumber;	
		vStringOfTable.PermissionGroups = vEmp.PermissionGroup;
		vStringOfTable.Hotel = vEmp.Hotel;  
		vStringOfTable.CurrentSession = (vCurSesNum = vSession.SessionNumber);
		
		If Items.Application.ChoiceList.FindByValue(vApplication) = Undefined Then
			Items.Application.ChoiceList.Add(vApplication);	
		EndIf; 
		
		If Items.PermissionGroups.ChoiceList.FindByValue(vStringOfTable.PermissionGroups) = Undefined Then
			Items.PermissionGroups.ChoiceList.Add(vEmp.PermissionGroup, String(vEmp.PermissionGroup));	
		EndIf; 			
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetAppTranslationss()
	
	vStructureOf = New Map;
	vStructureOf.Insert("1CV8C", NStr("en = 'Thin client'; de = 'Dünner Kunde'; ru = 'Тонкий клиент'"));
	vStructureOf.Insert("1CV8", NStr("en = 'Thick client'; de = 'Fetter Kunde'; ru = 'Толстый клиент'"));
	vStructureOf.Insert("Designer", NStr("en = 'Configurator'; de = 'Konfigurator'; ru = 'Конфигуратор'"));
	vStructureOf.Insert("BackgroundJob", NStr("en = 'Job processing session identifier'; de = 'ID der Auftragsverarbeitungssitzung'; ru = 'Идентификатор сеанса обработки задания'"));
	vStructureOf.Insert("HTTPServiceConnection", NStr("en = 'http session id-'; de = 'http-Sitzungskennung'; ru = 'идентификатор http-сессии-'"));
	vStructureOf.Insert("COMConnection", NStr("en = 'Session ID of external connection 1C:Enterprise via COM'; de = 'Sitzungs-ID der externen Verbindung 1C:Enterprise über COM'; ru = 'Идентификатор сессии внешнего подключения 1С:Предприятия через COM'"));
	vStructureOf.Insert("WebServerExtension", NStr("en = 'Web Server Extension Plug-in Application ID'; de = 'Anwendungs-ID des Webserver-Erweiterungs-Plug-ins'; ru = 'Идентификатор приложения подключаемого модуля расширения веб-сервера'"));
	vStructureOf.Insert("JobScheduler", NStr("en = 'Job Scheduler Session ID'; de = 'Jobplaner-Sitzungs-ID'; ru = 'Идентификатор сеанса планировщика заданий'"));
	vStructureOf.Insert("SrvrConsole", NStr("en = 'Server console'; de = 'Serverkonsole'; ru = 'Серверная консоль'"));
	vStructureOf.Insert("COMConsole", NStr("en = 'COM console'; de = 'COM-Konsole'; ru = 'COM консоль'"));
	Return vStructureOf;

EndFunction // GetAppTranslationss

// --------------------------------------------------------------------------------
&AtServer
Procedure EndSessionAtServer(pOpen)

	If Parameters.Property("DataProcessor") Then
		Object.DataProcessor = Parameters.DataProcessor;
	EndIf; 
	
	vDataFromTheObject = FormAttributeToValue("Object");
	vDataFromTheObject.pmLoadDataProcessorAttributes(); 
	ValueToFormAttribute(vDataFromTheObject, "Object");
	
	If Find(InfoBaseConnectionString(), "Srvr") > 0 Then
		// Server version (серверный вариант)
		vSearch = Find(InfoBaseConnectionString(), "Srvr=");
		vSearchSubstring = Mid(InfoBaseConnectionString(), vSearch + 6);        
		vServerName = Left(vSearchSubstring, Find(vSearchSubstring, """") - 1);
		// Now we are looking for the database name(теперь ищем имя базы)
		vSearch = Find(InfoBaseConnectionString(), "Ref=");
		vSearchSubstring = Mid(InfoBaseConnectionString(), vSearch + 5);
		vBaseName = Left(vSearchSubstring, Find(vSearchSubstring, """") - 1);
	Else
		// For other connection methods the algorithm is not relevant(для других способов подключения алгоритм не актуален)
		Return;
	EndIf;
	
	vConnector = New COMObject("v83.COMConnector");
	vAgent = vConnector.ConnectAgent(vServerName);
	vClusters = vAgent.GetClusters();
	
	For Each vCluster In vClusters Do
		Try	
			vAgent.Authenticate(vCluster,vDataFromTheObject.ClusterAdministratorName, vDataFromTheObject.CusterAdministratorPassword);		
		Except     
			vErr = NStr("en = 'Enter the correct login and password for the cluster administrator'; 
						|de = 'Geben Sie den richtigen Benutzernamen und das richtige Passwort für den Cluster-Administrator ein'; 
						|ru = 'Введите верные логин и пароль администратора кластера'");
			tcCommonFunctionOnClientServer.UserMessage(vErr);	
			pOpen = True;
			Return;
		EndTry;
		
		vProcesses = vAgent.GetWorkingProcesses(vCluster);        
		For Each vProcess In vProcesses Do 
			If vProcess.Running = 0 Then
				Continue;
			EndIf;
			vPort = vProcess.MainPort;       
			vConnectionString = "tcp://" + vServerName + ":" + Format(vPort, "NG=0");
			// Now there is an address and port to connect to the worker process(теперь есть адрес и порт для подключения к рабочему процессу)
			vSlaveProc = vConnector.ConnectWorkingProcess(vConnectionString);

			vSlaveProc.AddAuthentication(vDataFromTheObject.Username, vDataFromTheObject.Password);
			vInformationBase = "";
			
			vBases = vAgent.GetInfoBases(vCluster);
			For Each vBase In vBases Do
				If vBase.Name = vBaseName Then
					vInformationBase = vBase;
					Break;
				EndIf;
			EndDo;
			If vInformationBase = "" Then
				// Database not found(база не найдена)      
				vErr = NStr("en = 'Database not found'; de = 'Datenbank nicht gefunden'; ru = 'Информационная база не найдена'");
				tcCommonFunctionOnClientServer.UserMessage(vErr);
			EndIf;
			 // Base for sessions
			vSessions = vAgent.GetInfoBaseSessions(vCluster, vInformationBase);
			
			vBases = vSlaveProc.GetInfoBases();
			For Each vBase In vBases Do
				If vBase.Name = vBaseName Then
					vInformationBase = vBase;
					Break;
				EndIf;
			EndDo; 
			
			If vInformationBase = "" Then
				// Database not found(база не найдена)      
				vErr = NStr("en = 'Database not found'; de = 'Datenbank nicht gefunden'; ru = 'Информационная база не найдена'");
				tcCommonFunctionOnClientServer.UserMessage(vErr);
			EndIf;
			  // Base for connections
			vConnections = vSlaveProc.GetInfoBaseConnections(vInformationBase);
			vConnectionsDel = New Array();
			vRowIdentifiers = Items.ActiveUsers.SelectedRows;
			For Each vRowIdentifier In vRowIdentifiers Do 
				vTechData = ActiveUsers.FindByID(vRowIdentifier);
				
				For Each vSession In vSessions Do
					If InfoBaseSessionNumber() <> vSession.SessionID Then 
						If vSession.SessionID =  vTechData.SessionNumber Then    
							If vSession.connection <> Undefined Then
								vConnectionsDel.Add(vSession.connection.ConnID);
							EndIf;       
							vErr = NStr("en = 'The administrator has disconnected the session!'; 
										|de = 'Der Administrator hat die Sitzung getrennt!'; 
										|ru = 'Администратор отключил сеанс!'");
							vAgent.TerminateSession(vCluster, vSession, vErr);
							Break;
						EndIf;
					EndIf;
				EndDo;
				
				// Disconnect client application connections (Разорвать соединения клиентских приложений.)			
				
				For Each vConnection In vConnections Do
					If vConnectionsDel.Find(vConnection.ConnID) <> Undefined Then
						vSlaveProc.Disconnect(vConnection);
					EndIf;
				EndDo;
			EndDo;	
		EndDo;
	EndDo;
	UpdateAtServer();
EndProcedure // EndSessionAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SetFilter()
	If ValueIsFilled(PermissionGroups) And ValueIsFilled(Application) Then 
		Items.ActiveUsers.RowFilter = New FixedStructure("PermissionGroups, Application", PermissionGroups, Application);
	ElsIf Not ValueIsFilled(Application) And ValueIsFilled(PermissionGroups) Then
		Items.ActiveUsers.RowFilter = New FixedStructure("PermissionGroups", PermissionGroups);
	ElsIf ValueIsFilled(Application) And Not ValueIsFilled(PermissionGroups) Then
		Items.ActiveUsers.RowFilter = New FixedStructure("Application", Application);	
	ElsIf Not ValueIsFilled(PermissionGroups) And Not ValueIsFilled(Application) Then
		Items.ActiveUsers.RowFilter = Undefined;
	EndIf;
EndProcedure // ApplicationOnChange

#EndRegion            
