
#Region Public

// --------------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	If Not InteractionParameters.IsActive Then
		Return;
	EndIf;
	
	vDB = pmConnect();
	If vDB = Undefined Then
		Return;
	EndIf;
	
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	ExternalSystemIntegrationLogs.ExternalSystem AS ExternalSystem,
	|	ExternalSystemIntegrationLogs.Period AS Period
	|FROM
	|	InformationRegister.ExternalSystemIntegrationLogs AS ExternalSystemIntegrationLogs
	|
	|GROUP BY
	|	ExternalSystemIntegrationLogs.ExternalSystem,
	|	ExternalSystemIntegrationLogs.Period";
	vSelect = vQ.Execute().Select();

	vDB.BeginTransaction(DataLockControlMode.Managed);
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCount = 0;
		While vSelect.Next() Do
			
			vExternalSystem = vSelect.ExternalSystem;
			vExternalSystemUUID = TrimAll(vExternalSystem.UUID());
			
			vDateSetExternalLogs = vDB.Tables.ExternalLogs.CreateRecordSet();
			vDateSetExternalLogs.Filter.ExternalSystemUUID.Set(vExternalSystemUUID);
			vDateSetExternalLogs.Filter.Period.Set(vSelect.Period);
			
			vDataSet = InformationRegisters.ExternalSystemIntegrationLogs.CreateRecordSet();
			vDataSet.Filter.ExternalSystem.Set(vExternalSystem);
			vDataSet.Filter.Period.Set(vSelect.Period);
			vDataSet.Read();
			
			For Each vRec In vDataSet Do    
				vDateSetExternalLog = vDateSetExternalLogs.Add();
				vDateSetExternalLog.Period = vRec.Period;  
				vDateSetExternalLog.ExternalSystemUUID = vExternalSystemUUID; 
				vDateSetExternalLog.ExternalSystemCode = vExternalSystem.Code; 
				vDateSetExternalLog.ExternalSystemDescription = vExternalSystem.Description;
				vDateSetExternalLog.InteractionID = vExternalSystem.InteractionID;
				vDateSetExternalLog.FunctionName = vRec.FunctionName;
				vDateSetExternalLog.UUID = vRec.UUID;
				vDateSetExternalLog.EventType = XMLString(vRec.EventType);
				vDateSetExternalLog.Request = vRec.Request; 
				vDateSetExternalLog.Response = vRec.Response;
				vDateSetExternalLog.Description = vRec.Description;
			EndDo;
			
			vDateSetExternalLogs.Write(True);
			
			vDataSet.Clear(); 
			vDataSet.Write();
			
			vCount = vCount + 1;
			If vCount / 1000 = Int(vCount / 1000) Then
				vDB.CommitTransaction();
				vDB.BeginTransaction(DataLockControlMode.Managed);
				CommitTransaction();
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
		EndDo; 
		
		vDB.CommitTransaction();
		CommitTransaction();
	Except  
		RollbackTransaction();
		vDB.RollbackTransaction();
		
		vErrorDesc = StrTemplate(NStr("en = 'Unload error: %1'; de = 'Unload error: %1'; ru = 'Ошибка выгрузки: %1'"), ErrorDescription()); 
		tcCommonFunctionOnClientServer.UserMessage(vErrorDesc);
		If InteractionParameters.Status <> Enums.IntegrationStatuses.Error Then
			vWriteExt = InteractionParameters.GetObject();
			vWriteExt.ErrorDescription = vErrorDesc;
			vWriteExt.Status = Enums.IntegrationStatuses.Error;
			vWriteExt.Write();
		EndIf;
	EndTry;
EndProcedure // Run

// --------------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // LoadDataProcessorAttributes

// --------------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // FillAttributesWithDefaultValues

// --------------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // SaveDataProcessorAttributes

// --------------------------------------------------------------------------------
Function pmConnect(pIsInteractive = False) Export
	vDB = ExternalDataSources.ExternalLogs;
	
	If vDB.GetState() = ExternalDataSourceState.Connected And InteractionParameters.Status = Enums.IntegrationStatuses.Success Then
		Return ?(pIsInteractive, Undefined, vDB);
	EndIf;
	
	Try
		InitializationDB();
		If InteractionParameters.Status <> Enums.IntegrationStatuses.Success Then
			vWriteExt = InteractionParameters.GetObject();
			vWriteExt.Status = Enums.IntegrationStatuses.Success;
			vWriteExt.ErrorDescription = "";
			vWriteExt.Write();
		EndIf;
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Connected!'; de = 'Connected!'; ru = 'Подключен!'")); 
			Return Undefined;
		EndIf;
		Return vDB; 
	Except
		vErrorSys = BriefErrorDescription(ErrorInfo());
		vErrorDesc = StrTemplate(NStr("en = 'Connection error: %1'; de = 'Connection error: %1'; ru = 'Ошибка соединения: %1'"), vErrorSys);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.UserMessage(vErrorDesc); 
		EndIf;
		If InteractionParameters.Status <> Enums.IntegrationStatuses.Error Then
			vWriteExt = InteractionParameters.GetObject();
			vWriteExt.Status = Enums.IntegrationStatuses.Error; 
			vWriteExt.ErrorDescription = vErrorSys;
			vWriteExt.Write();
		EndIf;
	EndTry;
	Return Undefined;
EndFunction // Connect

// --------------------------------------------------------------------------------
Procedure CreateTable() Export
	Try 
		vDatabaseName = ?(Not IsBlankString(InteractionParameters.HttpAddress), InteractionParameters.HttpAddress, "ExternalLogs");
		
		vConnection = New COMObject("ADODB.Connection");
		If (InteractionParameters.InfobaseURL = "mssql") Then
			vConnection.ConnectionString = "driver={SQL Server};" + "server=" + InteractionParameters.HttpServer + ";" + "uid=" + InteractionParameters.Login + ";" + "pwd=" + InteractionParameters.Password + ";";
		Else
			vConnection.ConnectionString = "driver={PostgreSQL Unicode};" + "server=" + InteractionParameters.HttpServer + ";" + "Port=" + Format(InteractionParameters.HttpPort, "NG=0") + ";Database=postgres;uid=" + InteractionParameters.Login + ";" + "pwd=" + InteractionParameters.Password + ";";	
		EndIf;
		
		vConnection.ConnectionTimeout = 30;
		vConnection.CommandTimeout = 600;
		vConnection.Open();
		vQuerryDB = "CREATE DATABASE """ + vDatabaseName + """";
		
		Try
			vConnection.Execute(vQuerryDB, , 128);
		Except
			tcCommonFunctionOnClientServer.UserMessage(ErrorDescription());
		EndTry;
		
		vConnection.Close();
		
		If (InteractionParameters.InfobaseURL = "mssql") Then
			vQuerry = "CREATE TABLE Logs (Period DATETIME, External_System_UUID CHAR(36), External_System_Code NVARCHAR(36), External_System_Description NVARCHAR(150), Interaction_ID NVARCHAR(72), Function_Name NVARCHAR(300), UUID CHAR(36), Event_Type NVARCHAR(10), Request NTEXT, Response NTEXT, Description NTEXT)";
			vIndexCreate = "CREATE INDEX ExternalSystem ON dbo.Logs(External_System_UUID);";
			vConnection.ConnectionString = "driver={SQL Server};" + "server=" + InteractionParameters.HttpServer + ";" + "uid=" + InteractionParameters.Login + ";" + "pwd=" + InteractionParameters.Password + ";" + "database=" + vDatabaseName + ";";
		Else
			vQuerry = "CREATE TABLE public.Logs (Period TIMESTAMP(3), External_System_UUID CHAR(36), External_System_Code VARCHAR(36), External_System_Description VARCHAR(150), Interaction_ID VARCHAR(72), Function_Name VARCHAR(300), UUID CHAR(36), Event_Type VARCHAR(10), Request TEXT, Response TEXT, Description TEXT)";
			vIndexCreate = "CREATE INDEX ExternalSystem ON """+ vDatabaseName +""".public.Logs(External_System_UUID);";
			vConnection.ConnectionString = "driver={PostgreSQL Unicode};" + "server=" + InteractionParameters.HttpServer + ";" + "Port=" + Format(InteractionParameters.HttpPort, "NG=0") + ";uid=" + InteractionParameters.Login + ";" + "pwd=" + InteractionParameters.Password + ";" + "database=" + vDatabaseName + ";";	
		EndIf;

		vConnection.ConnectionTimeout = 30;
		vConnection.CommandTimeout = 600;
		vConnection.Open();
	Except
		tcCommonFunctionOnClientServer.UserMessage(ErrorDescription());
		Return;
	EndTry;
		
	Try
		vConnection.Execute(vQuerry, , 128);
		vConnection.Execute(vIndexCreate, , 128);
	Except
		tcCommonFunctionOnClientServer.UserMessage(ErrorDescription());
		Return;
	EndTry;
	
	tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Database created'; de = 'Datenbank erstellt'; ru = 'База данных создана'"));
EndProcedure // CreateTable

// --------------------------------------------------------------------------------
Function WriteLog(pTimestamp, pDescription, pExternalSystem, pFunctionName, pEventType, pUUID, pResponse, pRequest) Export
	vDB = pmConnect();
	If vDB = Undefined Then
		Return False;
	EndIf;
	
	Try	
		vRec = vDB.Tables.ExternalLogs.CreateRecordManager();
		vRec.Period = pTimestamp;  
		vRec.ExternalSystemUUID = TrimAll(pExternalSystem.UUID()); 
		vRec.ExternalSystemCode = pExternalSystem.Code; 
		vRec.ExternalSystemDescription = pExternalSystem.Description;
		vRec.InteractionID = pExternalSystem.InteractionID;
		vRec.FunctionName = pFunctionName;
		vRec.UUID = pUUID;
		vRec.EventType = XMLString(pEventType);
		vRec.Request = pRequest; 
		vRec.Response = pResponse;
		vRec.Description = pDescription;
		vRec.Write(False);
		Return True
	Except                     
		vErrorDesc = StrTemplate(NStr("en = 'Connection error: %1'; de = 'Connection error: %1'; ru = 'Ошибка подключения: %1'"), ErrorDescription());
		If InteractionParameters.Status <> Enums.IntegrationStatuses.Error Then
			vWriteExt = InteractionParameters.GetObject();
			vWriteExt.Status = Enums.IntegrationStatuses.Error; 
			vWriteExt.ErrorDescription = vErrorDesc;
			vWriteExt.Write();
		EndIf;
	EndTry;

	Return False;
EndFunction // WriteLog

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Procedure InitializationDB()
	vIP = InteractionParameters;
	
	vConnectionParams = New ExternalDataSourceConnectionParameters;
	vConnectionParams.Password = vIP.Password;
	vConnectionParams.UserName = vIP.Login;
	
	vDatabaseName = ?(Not IsBlankString(vIP.HttpAddress), vIP.HttpAddress, "ExternalLogs");	
	If Lower(vIP.InfobaseURL) =  "postgresql" Then
		vConnectionParams.DBMS = "PostgreSQL";
		vDriver = ?(Not IsBlankString(vIP.WSHost), vIP.WSHost,"PostgreSQL Unicode");
		vConnectionParams.ConnectionString = StrTemplate("Driver={%1};Host=%2;Port=%3;Database=%4;", vDriver, vIP.HttpServer, Format(vIP.HttpPort, "NG=0"), vDatabaseName);
	ElsIf Lower(vIP.InfobaseURL) = "mssql" Then
		vConnectionParams.DBMS = "MSSQLServer";
		vDriver = ?(Not IsBlankString(vIP.WSHost), vIP.WSHost,"SQL Server");
		vConnectionParams.ConnectionString = StrTemplate("Driver={%1};Server=%2;Database=%3;", vDriver, vIP.HttpServer, vDatabaseName);
	Else
		vConnectionParams.DBMS = "Other";
		vDriver = ?(Not IsBlankString(vIP.WSHost), vIP.WSHost,"PostgreSQL Unicode");
		vConnectionParams.ConnectionString = StrTemplate("Driver={%1};Host=%2;Port=%3;User=%4;Password=%5;Database=%6;", vDriver, vIP.HttpServer, Format(vIP.HttpPort, "NG=0"), vIP.Login, vIP.Password, vDatabaseName);
	EndIf;
	
	vDB = ExternalDataSources.ExternalLogs;
	vDB.SetCommonConnectionParameters(vConnectionParams);
	vDB.Connect();
EndProcedure // InitializationDB

#EndRegion
