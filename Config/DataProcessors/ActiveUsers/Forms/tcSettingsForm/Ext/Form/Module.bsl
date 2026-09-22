
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)  
	If Parameters.Property("DataProcessor") Then
		Object.DataProcessor = Parameters.DataProcessor;
	EndIf; 
	
	vDataFromTheObject = FormAttributeToValue("Object");
	vDataFromTheObject.pmLoadDataProcessorAttributes(); 
	ValueToFormAttribute(vDataFromTheObject, "Object");
	If ValueIsFilled(vDataFromTheObject.ClusterAdministratorName) And ValueIsFilled(vDataFromTheObject.CusterAdministratorPassword) Then  	 
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
			
			vAgent.Authenticate(vCluster,vDataFromTheObject.ClusterAdministratorName,vDataFromTheObject.CusterAdministratorPassword);
			vProcesses = vAgent.GetWorkingProcesses(vCluster);        
			For Each vProcess In vProcesses Do
				vPort = vProcess.MainPort;
			EndDo;
			
		EndDo; 
		If Not ValueIsFilled(Object.Username) Then		 
			Object.Username = "";
		EndIf;
		If Not ValueIsFilled(Object.ClusterAdministratorName) Then
			Object.ClusterAdministratorName = ""; 
		EndIf;
		If Not ValueIsFilled(Object.CusterAdministratorPassword) Then
			Object.ClusterAdministratorPassword = "";
		EndIf;
		If Not ValueIsFilled(Object.ServerClusterPort) Then
			Object.ServerClusterPort = vCluster.MainPort;
		EndIf;
		If Not ValueIsFilled(Object.ConnectingToAServerCluster) Then
			Object.ConnectingToAServerCluster = vCluster.ClusterName;
		EndIf;
		If Not ValueIsFilled(Object.Server) Then	
			Object.Server = vAgent.ConnectionString;
		EndIf;
		If Not ValueIsFilled(Object.Port) Then	
			Object.Port = vPort; 
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion 

#Region FormCommandsEventHandlers                                                  

// --------------------------------------------------------------------------------
&AtClient
Procedure Ok(pCommand)
	
	SaveAtServer();
	Close();
	
EndProcedure // Ok

// --------------------------------------------------------------------------------
&AtClient
Procedure Cancel(pCommand)
	Close();
EndProcedure // Cancel

#EndRegion 

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveAtServer()
	
	vObj = FormAttributeToValue("Object");
	vObj.pmSaveDataProcessorAttributes();
	
EndProcedure // SaveAtServer()

#EndRegion     
