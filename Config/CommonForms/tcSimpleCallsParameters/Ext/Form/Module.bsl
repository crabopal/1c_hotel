
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("SelData") Then
		FillPropertyValues(ThisObject, Parameters.SelData);	
	EndIf;
	
	website = "www.prostiezvonki.ru";
	TechnicalSupport = "www.prostiezvonki.ru/support";
	GetLastVersions();	
EndProcedure

&AtClient
Procedure OnOpen(Отказ)
	
	vStatus = 0;
	Try
		If Not amSimpleCallsComponent = Undefined Then
			vStatus = amSimpleCallsComponent.ConnectionState;
		EndIf;
	Except
	EndTry;
	
	RefrashStatus(vStatus);
	
	Version1C = tcSimpleCallsOnClient.GetVersionModul();
	VersionActiveX = tcSimpleCallsOnClient.GetActiveXVersion();

	If Version1C = ActualVersion1C Then
		Items.GroupActualVersion.Visible = False;
	Else
		Items.ThisActualVersion.Visible = False;
	EndIf;
	
	If VersionActiveX = ActualVersionActiveX Then
		Items.GroupActualVersionActiveX.Visible = False;
	Else
		Items.ThisActualVersionActiveX.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	OnCloseAtServer();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "SimpleCalls_ChageState" Then
		RefrashStatus(Parameter);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WebSiteClick(Item, StandardProcessing)
	StandardProcessing = False;
	#If ThinClient or WebClient Then
		GotoURL("http://prostiezvonki.ru");	
	#Else
		BeginRunningApplication(New NotifyDescription, "http://prostiezvonki.ru");
	#EndIf
EndProcedure

&AtClient
Procedure ServerATCOnChange(Item)
	amSimpleCallsParameters["ServerATC"] = ServerATC;
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	amSimpleCallsParameters["Password"] = Password;
EndProcedure

&AtClient
Procedure Version1CDonloadClick(Item)
	#If ThinClient or WebClient Then
		GotoURL("http://www.prostiezvonki.ru/download");	
	#Else
		BeginRunningApplication(New NotifyDescription, "http://www.prostiezvonki.ru/download");
	#EndIf
EndProcedure

&AtClient
Procedure VersionComponentDonloadClick(Item)
	#If ThinClient or WebClient Then
		GotoURL("http://www.prostiezvonki.ru/download");	
	#Else
		BeginRunningApplication(New NotifyDescription, "http://www.prostiezvonki.ru/download");
	#EndIf
EndProcedure

&AtClient
Procedure TechnicalSupportClick(Item, StandardProcessing)
	StandardProcessing = False;
	#If ThinClient or WebClient Then
		GotoURL("http://prostiezvonki.ru/support");	
	#Else
		BeginRunningApplication(New NotifyDescription, "http://prostiezvonki.ru/support");
	#EndIf
EndProcedure

&AtClient
Procedure ParametersStartListChoice(Item, StandardProcessing)
	
	vChoiceList = Item.ChoiceList;
	
	vChoiceList.Clear();
	
	If Item.Name = "ShowWindowIncomingCall" Then
		vChoiceList.Add(Nstr("en = 'Never'; 						 ru = 'Никогда'; 				 de = 'Nie'"));
		vChoiceList.Add(Nstr("en = 'When a call'; 					 ru = 'При поступлении звонка';  de = 'Wenn ein Anruf eingeht'"));
		vChoiceList.Add(Nstr("en = 'By lifting the handset'; 		 ru = 'По поднятию трубки'; 	 de = 'Durch Abheben des Hörers'"));
		vChoiceList.Add(Nstr("en = 'At the end of the conversation'; ru = 'По завершению разговора'; de = 'Am Ende des Gesprächs'"));
	ElsIf  Item.Name = "ShowWindowOutCall" Then 
		vChoiceList.Add(Nstr("en = 'Never'; 						 ru = 'Никогда'; 				 de = 'Nie'"));
		vChoiceList.Add(Nstr("en = 'At the beginning of the call'; 	 ru = 'При начале звонка'; 		 de = 'Zu Beginn des Anrufs'"));
		vChoiceList.Add(Nstr("en = 'By lifting the handset'; 		 ru = 'По поднятию трубки'; 	 de = 'Durch Abheben des Hörers'"));
		vChoiceList.Add(Nstr("en = 'At the end of the conversation'; ru = 'По завершению разговора'; de = 'Am Ende des Gesprächs'"));
	ElsIf Item.Name = "SaveHistoryCalls" Then
		vChoiceList.Add(Nstr("en = 'Never'; 						 ru = 'Никогда'; 				 de = 'Nie'"));
		vChoiceList.Add(Nstr("en = 'Only incoming'; 				 ru = 'Только входящие'; 		 de = 'Nur eingehende'"));
		vChoiceList.Add(Nstr("en = 'Only outgoing'; 				 ru = 'Только исходящие'; 		 de = 'Nur ausgeh'"));
		vChoiceList.Add(Nstr("en = 'Incoming and outgoing'; 		 ru = 'Входящие и исходящие'; 	 de = 'Eingehende und ausgehende'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ParametersOnChange(pItem)
	amSimpleCallsParameters[pItem.Name] = ThisForm[pItem.Name];
EndProcedure

&AtClient
Procedure CloseWindowOnChange(pItem)
	amSimpleCallsParameters["CloseWindows"] = CloseWindows;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Connect(pCommand)
	OnCloseAtServer();
	tcSimpleCallsOnClient.Connect();	
EndProcedure

&AtClient
Procedure Disconnect(pCommand)
	tcSimpleCallsOnClient.Disconnect();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GetLastVersions() 
	
	vFileName = TempFilesDir() + "CTI_version.xml";
	
	Try
		vConnect = New HTTPConnection("prostiezvonki.ru", , , , , , New OpenSSLSecureConnection());
		vConnect.Get(New HTTPRequest("version.xml"), vFileName);                   
	Except
		Return;
	EndTry;
	
	vRead = New XMLReader;
	
	Try
		vRead.OpenFile(vFileName);
		vRead.Read();
	Except
		Return;
	EndTry;
	
	vVersions = New ValueTable;
	vVersions.Columns.Add("Name");
	vVersions.Columns.Add("Version");
	vVersions.Columns.Add("Description");
	vVersions.Columns.Add("Path");
	
	While vRead.Read() Do
		
		If vRead.AttributeCount() > 0 Then
			vStr = vVersions.Add();
			
			While vRead.ReadAttribute() Do
				vAttributeName = Lower(vRead.Name);
				If vAttributeName = "name" Then
				    vStr.Name = vRead.Value;
				ElsIf vAttributeName = "version" Then
					vStr.Version = vRead.Value;
				ElsIf vAttributeName = "description" Then
					vStr.Description = vRead.Value;
				ElsIf vAttributeName = "path" Then
					vStr.Path = vRead.Value;
				EndIf;
			EndDo;
			
			If vStr.Name = "1C_UF" Then
				ActualVersion1C = vStr.Version;
			ElsIf vStr.Name = "CTIControl_1C" Then
				ActualVersionActiveX = vStr.Version;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure OnCloseAtServer()
	vGuid = ?(GUID = "", TrimAll(New UUID()), GUID);
	
	vData = New Structure;
	vData.Insert("ShowWindowIncomingCall",			ShowWindowIncomingCall);
	vData.Insert("ShowWindowOutCall",				ShowWindowOutCall);
	vData.Insert("SaveHistoryCalls",				SaveHistoryCalls);
	vData.Insert("UseAutomaticRedirection",			UseAutomaticRedirection);
	vData.Insert("UserPhoneNumber",					Workstation.PhoneNumberInternal);
	vData.Insert("GUID",							vGuid);
	vData.Insert("ServerATC",						ServerATC);
	vData.Insert("Password",						Password);
	vData.Insert("CloseWindows",					CloseWindows);
	
	SetPrivilegedMode(True);
	SystemSettingsStorage.Save("SimpleCalls", TrimAll(Workstation), vData, , TrimAll(Workstation));
	SetPrivilegedMode(False);
EndProcedure

&AtClient
Procedure RefrashStatus(pStatus = Undefined)
	
	If pStatus = Undefined Then
		pStatus = tcSimpleCallsOnClient.GetState();
	EndIf;
	
	If pStatus = 1 Then
		ConnectionStatus = NStr("en = 'Connected'; ru = 'Есть соединение'; de = 'Connected'");
		Items.ConnectionStatus.TextColor = WebColors.Green;
	Else
		If pStatus = 0 Then
			ConnectionStatus = NStr("en = 'No connection'; ru = 'Нет соединения'; de = 'No connection'");
		ElsIf  pStatus = 2 Then
			ConnectionStatus = NStr("en = 'License expired'; ru = 'Лицензия истекла'; de = 'Lizenz abgelaufen'");
		ElsIf pStatus = 3 Then
			ConnectionStatus = NStr("en = 'Customer Limit Exceeded'; ru = 'Превышен лимит клиентов'; de = 'Kunden Limit überschritten'");
		EndIf;
		Items.ConnectionStatus.TextColor = WebColors.FireBrick;
	EndIf;
	
EndProcedure

#EndRegion
