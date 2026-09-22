
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	LoadParameters();
	
	UpdLabelWebServer();
	If Parameters.Property("ErrorDescription") And Not IsBlankString(Parameters.ErrorDescription) Then
		If StrFind(Parameters.ErrorDescription, "OldVersion") > 0 Then     
			vMsg =  Nstr("en = 'You must download and install the component manually'; 
						 |de = 'Sie müssen die Komponente manuell herunterladen und installieren'; 
						 |ru = 'Необходимо скачать и установить компоненту вручную'");
			tcCommonFunctionOnClientServer.UserMessage(vMsg);
			ServerStatus = 1;
		Else	
			ServerStatus = 0;	
		EndIf;	
	Else	
		ServerStatus = 0;
	EndIf;
	vCurVersion = tcProtectionAtServerReuse.GetLastComponentVersion();
	vCurVersion 	= StrReplace(vCurVersion, ".", "_");
	
	RefServerSLK   	= "http://www.1chotel.ru/support/slk/server_" + vCurVersion + ".exe";
	RefComponentSLK = "http://www.1chotel.ru/support/slk/licenceaddin_" + vCurVersion + ".exe";
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pStandardProcessing)
	If IsClose = False Then
		pCancel = True;
	EndIf;	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ServerOnChange(Item)
	UpdLabelWebServer();
	RefreshReusableValues();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure WebServerClick(Item, StandardProcessing)
	StandardProcessing = False;
	GotoURL(WebServer + "/?menu=false&header=true");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PortOnChange(Item)
	UpdLabelWebServer();
	RefreshReusableValues();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationComponentSLKClick(Item)
	GotoURL(RefComponentSLK);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationServerSLKClick(Item)
	GotoURL(RefServerSLK);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Connection(pCommand)
	ClearMessages();
	If IsBlankString(ProtectionSystemServer) Then
		vErr = NStr("en = 'Error: Protection system server name is empty!'; 
					|de = 'Fehler: Der Name des Schutzsystem-Servers ist nicht angegeben!'; 
					|ru = 'Ошибка: не указано имя сервера системы защиты!'"); 
		tcCommonFunctionOnClientServer.UserMessage(vErr, , "ProtectionSystemServer");
		Return;
	EndIf;
	If IsBlankString(Port) Then
		vErr = NStr("en = 'Error: Port is empty!'; 
					|de = 'Fehler: Der Name des Port-Servers ist nicht angegeben!'; 
					|ru = 'Ошибка: не указан порт сервера системы защиты!'");    
		tcCommonFunctionOnClientServer.UserMessage(vErr, , "Port");
		Return;
	EndIf;
	vMsg = "";
	Try
		ConnectionAtServer(vMsg);
		If IsBlankString(vMsg) Then
			IsClose = True;
			Close();
		EndIf;
	Except
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());
	EndTry;    
	tcOnClient.ChangeApplicationCaption(tcOnServer.cmGetCurrentHotelAttribute());
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DemoMode(pCommand)
	IsClose = True;
	Close();  
	vIsDemoMode = tcOnServer.cmGetSessionParametersAttribute("IsDemoMode");    
	If vIsDemoMode Then
		ShowMessageBox(, NStr("en = 'The program is open for viewing.'; de = 'Das Programm ist zur Ansicht geöffnet.'; ru = 'Программа открыта на просмотр.'"));  
	EndIf;
	tcOnClient.ChangeApplicationCaption(tcOnServer.cmGetCurrentHotelAttribute());
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ConnectionAtServer(pMsg)
	tcProtection.cmSaveProtectionSystemServerParameters(ProtectionSystemServer, Port);
	tcProtection.StartProtection(pMsg);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdLabelWebServer()
	WebServer = "http://" + ProtectionSystemServer + ":" + Port; 
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadParameters()
	vParam = tcProtection.cmLoadProtectionSystemServerParameters();
	ProtectionSystemServer = vParam.Server;
	If vParam.Port = "" Then  
		Port = "9099";
	Else
		Port = vParam.Port;
	EndIf;	
	IsClose = False;
EndProcedure	

#EndRegion        
