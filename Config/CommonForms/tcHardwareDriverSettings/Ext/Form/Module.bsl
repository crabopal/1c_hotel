
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Parameters.Property("Hardware", Hardware);
	
	vDataDevicesMap = tcConnectedHardwareOnClientServer.GetDataDevices(Hardware);
	If vDataDevicesMap = Undefined Then
		pCancel = True;
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to get device data.'; de = 'Gerätedaten konnten nicht abgerufen werden.'; ru = 'Не удалось получить данные устройства.'"));
		Return;
	EndIf;
	
	HardwareDriver = vDataDevicesMap.HardwareDriver;
	ParametersValue = vDataDevicesMap.ParametersValue;
	HardwareData = vDataDevicesMap;
	
	If Not ValueIsFilled(ParametersValue) Then
		ParametersValue = New Structure;
	EndIf;
	
	Title = NStr("en = 'Hardware: '; de = 'Hardware: '; ru = 'Оборудование: '") + TrimAll(Hardware);
	
	MagneticCardReader = HardwareData.ConnectedHardwareType = Enums.ConnectedHardwareTypes.CardReader;
	If MagneticCardReader Then
		vTrackParameters = Undefined;
		If Not ParametersValue.Property("TrackParameters", vTrackParameters) Then
			vTrackParameters = New Array();
			For i = 1 To 3 Do
				vNewRow = New Structure();
				vNewRow.Insert("TrackNumber", i);
				vNewRow.Insert("Prefix", 0);
				vNewRow.Insert("Suffix", ?(i = 2, 13, 0));
				vNewRow.Insert("Use", ?(i = 2, True, False));
				vTrackParameters.Add(vNewRow);
			EndDo;
		EndIf;
		For Each vRowTrack In vTrackParameters Do
			vNewRow = TrackParameters.Add();
			vNewRow.TrackNumber	= vRowTrack.TrackNumber;
			vNewRow.Prefix			= vRowTrack.Prefix;
			vNewRow.Suffix			= vRowTrack.Suffix;
			vNewRow.Use				= vRowTrack.Use;
		EndDo;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	UpdateHardwareDriverInformation(True);
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationEnvironmentInformationClick(pItem)
	DoMessageBoxAsync(EnvironmentInformation, , NStr("en = 'Information about the environment'; de = 'Informationen zur Umwelt'; ru = 'Информация об окружении'"));
EndProcedure // DecorationEnvironmentInformationClick

// --------------------------------------------------------------------------------
&AtClient
Async Procedure GoToManufacturWebsiteClick(pItem)
	If Not IntegrationComponent Then
		Return;
	EndIf;
	
	vMessage =
	NStr("en = 'To go to the manufacturer''s website, you need an Internet connection.
	|Continue the operation?'; de = 'Um auf die Website des Herstellers zugreifen zu können, benötigen Sie eine Internetverbindung.
	|Sollten Sie den Vorgang fortsetzen?'; ru = 'Для перехода на сайт производителя необходимо подключение к Интернету.
	|Продолжить выполнение операции?'");
	
	vResult = Await DoQueryBoxAsync(vMessage, QuestionDialogMode.YesNo);
	
	If vResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Await RunAppAsync(DownloadURL, , False);
	
	tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Installation of the main driver distribution has begun.'; de = 'Die Installation der Haupttreiberverteilung hat begonnen.'; ru = 'Начата установка основной поставки драйвера.'"));
EndProcedure // GoToManufacturWebsiteClick

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure WriteAndClose(pCommand)
	vSettings = GetSettings();
	If MagneticCardReader Then
		vConfiguredTracks = 0;
		vTrackWithEmptySuffix = False;
		vTrackParameters = New Array();
		vDriverPrefix = -1;
		vDriverSuffix = -1;
		
		For i = 1 To 3 Do
			If TrackParameters[3 - i].Use Then
				vTrackWithEmptySuffix = vTrackWithEmptySuffix Or (TrackParameters[3 - i].Suffix = 0);
				vConfiguredTracks = vConfiguredTracks + 1;
			EndIf;
		EndDo;
		
		If Not vTrackWithEmptySuffix Then
			For i = 1 To 3 Do
				vNewRow = New Structure();
				vNewRow.Insert("TrackNumber", TrackParameters[i - 1].TrackNumber);
				vNewRow.Insert("Use", TrackParameters[i - 1].Use);
				vNewRow.Insert("Prefix" , TrackParameters[i - 1].Prefix);
				vNewRow.Insert("Suffix" , TrackParameters[i - 1].Suffix);
				vTrackParameters.Add(vNewRow);
			EndDo;
			
			For i = 1 To 3 Do
				If vTrackParameters[i - 1].Use Then
					vDriverPrefix = vTrackParameters[i - 1].Prefix;
					vDriverPrefix = ?(vDriverPrefix = 0, -1, vDriverPrefix);
					vSettings.ParametersValue.Insert("P_Prefix", vDriverPrefix);
					Break;
				EndIf;
			EndDo;
			
			For i = 1 To 3 Do
				If vTrackParameters[3 - i].Use Then
					vDriverSuffix = vTrackParameters[3 - i].Suffix;
					vDriverSuffix = ?(vDriverSuffix = 0, -1, vDriverSuffix);
					vSettings.ParametersValue.Insert("P_Suffix", vDriverSuffix);
					Break;
				EndIf;
			EndDo;
			
			vSettings.ParametersValue.Insert("TrackParameters", vTrackParameters);
		EndIf;
		
		If vDriverPrefix > 0 And vDriverSuffix > 0 And vDriverPrefix = vDriverSuffix Then
			vTextMessage = НСтр("en = 'The prefix of the first track used is the same as the suffix of the last track used.'; de = 'Das Präfix des ersten verwendeten Titels ist identisch mit dem Suffix des letzten verwendeten Titels.'; ru = 'Префикс первой используемой дорожки совпадает с суффикс последней используемой дорожки'");
			tcCommonFunctionOnClientServer.UserMessage(vTextMessage);
		ElsIf vConfiguredTracks > 0 And Not vTrackWithEmptySuffix Then
			SaveConnectionParameters(vSettings);
			tcConnectedHardwareOnClientServer.DisconnectHardware(HardwareData, True);
			Close();
		ElsIf vConfiguredTracks = 0 Then
			vTextMessage = НСтр("en = 'You must specify the use of at least one track for the reader.'; de = 'Sie müssen die Verwendung von mindestens einer Spur für das Lesegerät angeben.'; ru = 'Необходимо указать использование хотя бы одной дорожки для считывателя'");
			tcCommonFunctionOnClientServer.UserMessage(vTextMessage);
		ElsIf vTrackWithEmptySuffix Then
			vTextMessage = НСтр("en = 'Each track used must have a suffix specified.'; de = 'Für jeden verwendeten Titel muss ein Suffix angegeben werden.'; ru = 'Для каждой используемой дорожки должен быть указан суффикс'");
			tcCommonFunctionOnClientServer.UserMessage(vTextMessage);
		EndIf;
	Else
		SaveConnectionParameters(vSettings);
		tcConnectedHardwareOnClientServer.DisconnectHardware(HardwareData, True);
		Close();
	EndIf;
EndProcedure // WriteAndClose

// --------------------------------------------------------------------------------
&AtClient
Async Procedure InstallDriver(pCommand)
	ClearCustomInterface();
	Await tcConnectionHardwareAtClient.InstallDriverAsync(HardwareDriver);
	UpdateHardwareDriverInformation(True);
EndProcedure // InstallDriver

// --------------------------------------------------------------------------------
&AtClient
Procedure TestConnections(pCommand)
	ClearMessages();
	ReadOnly = True;
	CommandBar.Enabled = False;
	DemoMode = "";
	
	vHardwareData = tcConnectedHardwareOnServer.GetCopyStructure(HardwareData);
	vHardwareData.Insert("ParametersValue", GetSettings().ParametersValue);
	vHardwareData.Insert("ParametersValueXML", tcConnectedHardwareOnClientServer.GetParametersXML(vHardwareData.ParametersValue, vHardwareData.ConnectedHardwareType));
	vResultOperation = tcConnectedHardwareOnClientServer.TestConnections(vHardwareData);
	
	ReadOnly = False;
	CommandBar.Enabled = True;
	
	If vResultOperation.Result Then
		vAdditionalDescription = vResultOperation.ResultOperation;
		DemoMode = vResultOperation.ActivatedDemoMode;
		Items.GroupDemoMode.Visible = Not IsBlankString(DemoMode);
		vTextMessage = NStr("en = 'The test was completed successfully.'; de = 'Der Test wurde erfolgreich abgeschlossen.'; ru = 'Тест успешно выполнен.'");
		If Not ПустаяСтрока(vAdditionalDescription) Then
			vTextMessage = vTextMessage + Chars.NBSp + vAdditionalDescription;
		EndIf
	Else
		vTextMessage = StrTemplate(NStr("en = 'Test failed. %1'; de = 'Test fehlgeschlagen. %1'; ru = 'Тест не пройден. %1'"), vResultOperation.ErrorDescription);
	EndIf;
	tcCommonFunctionOnClientServer.UserMessage(vTextMessage);
EndProcedure // TestConnections

// --------------------------------------------------------------------------------
&AtClient
Procedure HardwareAutoSetup(pCommand)
	ClearMessages();
	ReadOnly = True;
	CommandBar.Enabled = False;
	DemoMode = "";
	
	vHardwareData = tcConnectedHardwareOnServer.GetCopyStructure(HardwareData);
	vHardwareData.Insert("ParametersValue", GetSettings().ParametersValue);
	vHardwareData.Insert("ParametersValueXML", tcConnectedHardwareOnClientServer.GetParametersXML(vHardwareData.ParametersValue, vHardwareData.ConnectedHardwareType));
	
	vResultOperation = tcConnectedHardwareOnClientServer.HardwareAutoSetup(vHardwareData);
	
	ReadOnly = False;
	CommandBar.Enabled = True;
	vTextMessage = ?(vResultOperation.Result, NStr("en = 'The operation was completed successfully.'; de = 'Der Vorgang wurde erfolgreich abgeschlossen.'; ru = 'Операция выполнена успешно.'"), NStr("en = 'Operation failed.'; de = 'Vorgang fehlgeschlagen.'; ru = 'Операция не выполнена.'"));
	
	If vResultOperation.Result Then
		If vResultOperation.ParametersValue.Count() > 0 Then
			AutoSetupSetParameters(vResultOperation.ParametersValue);
		Else
			vTextMessage = NStr("en = 'Driver setup parameters are not defined.'; de = 'Die Treiber-Setup-Parameter sind nicht definiert.'; ru = 'Параметры настройки драйвера не определены.'");
		EndIf;
	EndIf;
	
	tcCommonFunctionOnClientServer.UserMessage(vTextMessage);
EndProcedure // HardwareAutoSetup

// --------------------------------------------------------------------------------
&AtClient
Procedure AdditionalAction(pCommand)
	vNameActions = Mid(pCommand.Name, 3);
	vExecutionParameters = New Structure("NameActions", vNameActions);
	
	vHardwareData = tcConnectedHardwareOnServer.GetCopyStructure(HardwareData);
	vHardwareData.Insert("ParametersValue", GetSettings().ParametersValue);
	vHardwareData.Insert("ParametersValueXML", tcConnectedHardwareOnClientServer.GetParametersXML(vHardwareData.ParametersValue, vHardwareData.ConnectedHardwareType));
	
	vResultOperation = tcConnectedHardwareOnClientServer.AdditionalCommands(vHardwareData, vExecutionParameters);
	
	vTextMessage = ?(vResultOperation.Result, NStr("en = 'The operation was completed successfully.'; de = 'Der Vorgang wurde erfolgreich abgeschlossen.'; ru = 'Операция выполнена успешно.'"), NStr("en = 'Operation execution error:'; de = 'Fehler bei der Ausführung des Vorgangs:'; ru = 'Ошибка выполнения операции: '") + vResultOperation.ErrorDescription);
	tcCommonFunctionOnClientServer.UserMessage(vTextMessage);
	
	ClearCustomInterface();
	
	UpdateHardwareDriverInformation(False);
EndProcedure // AdditionalAction

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearSettings(pCommand)
	ClearSettingsAtServer();
EndProcedure // ClearSettings

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function GetSettings()
	vDriverParametersAttributes = GetAttributes();
	
	vNewDriverParametersAttributes = New Structure;
	For Each vParameter In vDriverParametersAttributes Do
		If Left(vParameter.Имя, 2) <> "P_" Then
			Continue;
		EndIf;
		
		vNewDriverParametersAttributes.Insert(vParameter.Name, ThisObject[vParameter.Name]);
	EndDo;
	
	vResult = New Structure;
	vResult.Insert("ParametersValue", vNewDriverParametersAttributes);
	vResult.Insert("HardwareParameters", HardwareParameters);
	
	Return vResult;
EndFunction // GetSettings

// --------------------------------------------------------------------------------
&AtServer
Procedure AutoSetupSetParameters(pParametersValue)
	ClearSettingsAtServer();
	FillPropertyValues(ThisObject, pParametersValue);
EndProcedure // AutoSetupSetParameters

// --------------------------------------------------------------------------------
&AtClient
Procedure UpdateHardwareDriverInformation(pFirstLaunch)
	vHardwareData = tcConnectedHardwareOnServer.GetCopyStructure(HardwareData);
	
	vHardwareDriverDescription = tcConnectedHardwareOnClientServer.GetHardwareDriverDescription(vHardwareData);
	
	If TypeOf(vHardwareDriverDescription) <> Type("Structure") Then
		Return;
	EndIf;
	
	UpdateInterfaceForms(pFirstLaunch, vHardwareDriverDescription);
EndProcedure // UpdateHardwareDriverInformation

// --------------------------------------------------------------------------------
&AtClient
Procedure UpdateInterfaceForms(pFirstLaunch, pHardwareDriverDescription)
	If pHardwareDriverDescription.Result Then
		Items.StatusComponents.CurrentPage = Items.ComponentInstalled;
		vDriverReadyToWork = False;
		Items.GroupMainDriver.Visible = False;
		
		FillPropertyValues(ThisObject, pHardwareDriverDescription.DriverDescription);
		
		Items.IsEmulator.Visible = IsEmulator;
		Items.DecorationEnvironmentInformation.Visible = Not IsBlankString(EnvironmentInformation);
		
		If IntegrationComponent Then
			If Not MainDriverInstalled Then
				ThisObject.Height = 14;
				Items.StatusComponents.CurrentPage = Items.DriverIntegrationComponent;
				DriverInstalled = NStr("en = 'Integration component installed'; de = 'Integrationskomponente installiert'; ru = 'Установлен интеграционный компонент'");
				DriverVersion = NStr("en = 'Not defined'; de = 'Nicht definiert'; ru = 'Не определена'");
				Items.DriverWarning.Visible = Not IsBlankString(Name);
				Items.DriverWarning.Title = StrTemplate(Items.DriverWarning.Title, Name);
				Items.GoToManufacturWebsite.Visible = Not IsBlankString(HardwareDriver);
			Else
				vDriverReadyToWork = True;
				DriverInstalled = NStr("en = 'Installed'; de = 'Installiert'; ru = 'Установлен'");
				Items.GroupMainDriver.Visible = True;
				Items.MainDriverInstalled.Title = StrTemplate(
				NStr("en = 'The main driver distribution has been installed. Version %1.'; de = 'Die Haupttreiberverteilung wurde installiert. Version %1.'; ru = 'Установлена основная поставка драйвера. Версия %1.'"),
				pHardwareDriverDescription.DriverDescription.DriverVersion);
				DriverVersion = pHardwareDriverDescription.DriverDescription.IntegrationComponentVersion;
			EndIf;
		Else
			DriverInstalled = NStr("en = 'Installed'; de = 'Installiert'; ru = 'Установлен'");
			vDriverReadyToWork = True;
		EndIf;
	Else
		ThisObject.Height = 14;
		Items.StatusComponents.CurrentPage = Items.ComponentNotInstalled;
		vDriverReadyToWork = False;
		DriverInstalled = NStr("en = 'Not installed'; de = 'Nicht installiert'; ru = 'Не установлен'");
		DriverVersion = NStr("en = 'Not defined'; de = 'Nicht definiert'; ru = 'Не определена'");
		If Not IsBlankString(pHardwareDriverDescription.ErrorDescription) Then
			tcCommonFunctionOnClientServer.UserMessage(pHardwareDriverDescription.ErrorDescription);
		EndIf;
	EndIf;
	
	If IsBlankString(HardwareParameters) And Not HardwareData.Property("HardwareParameters", HardwareParameters) Then
		HardwareParameters = "";
	EndIf;
	
	If Not IsBlankString(HardwareParameters) Then
		UpdateCustomInterface(HardwareParameters, AdditionalActions, pFirstLaunch);
	EndIf;
	
	Items.FormWriteAndClose.Visible = Not IsBlankString(HardwareParameters);
	Items.FormTestConnections.Visible = vDriverReadyToWork;
	Items.FormHardwareAutoSetup.Visible = vDriverReadyToWork And AutoSetup;
	Items.GroupHardwareDriver.Visible = vDriverReadyToWork;
	Items.Actions.Visible = vDriverReadyToWork;
	Items.Description.Visible = vDriverReadyToWork And Not IsBlankString(Description);
EndProcedure // UpdateInterfaceForms

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateCustomInterface(pHardwareParameters, pAdditionalActions, pFirstLaunch)
	vSuffix = False;
	vPrefix = False;
	vBasicGroup = Undefined;
	vElement = Undefined;
	vIndexGroups = 0;
	vNumberOfPages = 0;
	vCurrentPage = Items.Add("MainPage", Type("FormGroup"), Items.Pages);
	
	vXMLReader = New XMLReader;
	vXMLReader.SetString(pHardwareParameters);
	vXMLReader.MoveToContent();
	
	If vXMLReader.Name = "Settings" And vXMLReader.NodeType = XMLNodeType.StartElement Then
		While vXMLReader.Read() Do
			If vXMLReader.Name = "Parameter" And vXMLReader.NodeType = XMLNodeType.StartElement Then
				vReadOnly = ?(Upper(vXMLReader.AttributeValue("ReadOnly")) = "TRUE", True, False) Or ?(Upper(vXMLReader.AttributeValue("ReadOnly")) = "ИСТИНА", True, False);
				vOriginalName = vXMLReader.AttributeValue("Name");
				vParameterName = ?(vReadOnly, "R_", "P_") + vOriginalName;
				vParameterHeader = vXMLReader.AttributeValue("Caption");
				vParameterType = Upper(vXMLReader.AttributeValue("TypeValue"));
				vParameterType = ?(Not IsBlankString(vParameterType), vParameterType, "STRING");
				vParameterValue = vXMLReader.AttributeValue("DefaultValue");
				vParameterDescription = vXMLReader.AttributeValue("Description");
				vFormattingString = vXMLReader.AttributeValue("FieldFormat");
				
				If MagneticCardReader Then
					vSuffix = Upper(vOriginalName) = "SUFFIX" Or ?(Upper(vXMLReader.AttributeValue("Suffix")) = "TRUE", True, False);
					vPrefix = Upper(vOriginalName) = "PREFIX" Or ?(Upper(vXMLReader.AttributeValue("Prefix")) = "TRUE", True, False);
				EndIf;
				
				vParameterExists = False;
				vDriverParametersAttributes = GetAttributes();
				For Each vDriverParametersAttribute In vDriverParametersAttributes Do
					If vDriverParametersAttribute.Name = vParameterName Then
						vParameterExists = True;
						Break;
					EndIf;
				EndDo;
				
				If Not vParameterExists Then
					If vParameterType = "NUMBER" Then
						vAttribute = New FormAttribute(vParameterName, New TypeDescription("Number"), , vParameterHeader, True);
					ElsIf vParameterType = "BOOLEAN" Then
						vAttribute = New FormAttribute(vParameterName, New TypeDescription("Boolean"), , vParameterHeader, True);
					Else
						vAttribute = New FormAttribute(vParameterName, New TypeDescription("String"), , vParameterHeader, True);
					EndIf;
					
					vAddedAttributes = New Array;
					vAddedAttributes.Add(vAttribute);
					ChangeAttributes(vAddedAttributes);
				EndIf;
				
				If vSuffix Then
					vElement = Items.TrackParametersSuffix
				ElsIf vPrefix Then
					vElement = Items.TrackParametersPrefix;
				ElsIf Items.Find(vParameterName) = Undefined Then
					If vBasicGroup = Undefined Then
						vBasicGroup = Items.Add("BasicGroup" + vNumberOfPages, Type("FormGroup"), vCurrentPage);
						vBasicGroup.Type = FormGroupType.UsualGroup;
						vBasicGroup.Representation = Items.GroupHardwareDriver.Representation;
						vBasicGroup.HorizontalStretch = True;
						vBasicGroup.Title = NStr("en = 'Parameters'; de = 'Parameter'; ru = 'Параметры'");
						vBasicGroup.Group = Items.GroupHardwareDriver.Group;
					EndIf;
					vElement = Items.Add(vParameterName, Type("FormField"), vBasicGroup);
					If vParameterType = "BOOLEAN" Then
						vElement.Type = FormFieldType.CheckBoxField
					Else
						vElement.Type = FormFieldType.InputField;
						vElement.AutoMaxWidth = False;
						vElement.HorizontalStretch = True;
						vElement.Format = vFormattingString;
						vElement.EditFormat = vFormattingString;
					EndIf;
					vElement.DataPath = vParameterName;
					vElement.ToolTip = vParameterDescription;
					vElement.ReadOnly = vReadOnly;
				EndIf;
				
				vStoredValue = Undefined;
				If ParametersValue.Property(vParameterName, vStoredValue) Then
					vParameterValue = vStoredValue
				Else
					If Not IsBlankString(vParameterValue) Then
						If vParameterType = "BOOLEAN" Then
							vParameterValue = ?(Upper(vParameterValue) = "TRUE", True, False) Or ?(Upper(vParameterValue) = "ИСТИНА", True, False);
						ElsIf vParameterType = "STRING" Then
							vParameterValue = String(vParameterValue);
						EndIf;
					EndIf;
				EndIf;
				
				ThisObject[vParameterName] = vParameterValue;
			EndIf;
			
			If vXMLReader.Name = "ChoiceList" And vXMLReader.NodeType = XMLNodeType.StartElement Then
				If Not (vElement = Undefined) And Not (vElement.Type = FormFieldType.CheckBoxField) Then
					vElement.ListChoiceMode = True;
					vElement.ChoiceListHeight = 10;
					vElement.TextEdit = False;
					If vSuffix Or vPrefix Then
						vElement.ChoiceList.Add(0, "<NONE>");
					EndIf;
				EndIf;
				
				While vXMLReader.Read() And Not (vXMLReader.Name = "ChoiceList") Do
					If vXMLReader.Name = "Item" And vXMLReader.NodeType = XMLNodeType.StartElement Then
						vAttributeValue = vXMLReader.AttributeValue("Value");
						If vXMLReader.Read() Then
							vAttributeRepresentation = vXMLReader.Value;
						EndIf;
						If IsBlankString(vAttributeValue) Then
							vAttributeValue = vAttributeRepresentation;
						EndIf;
						
						If vSuffix Or vPrefix Then
							If Number(vAttributeValue) > 0 Then
								vElement.ChoiceList.Add(Number(vAttributeValue), vAttributeRepresentation);
							EndIf;
						ElsIf vParameterType = "NUMBER" Then
							vElement.ChoiceList.Add(Number(vAttributeValue), vAttributeRepresentation);
						Else
							vElement.ChoiceList.Add(vAttributeValue, vAttributeRepresentation);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			
			If vXMLReader.Name = "Page" And vXMLReader.NodeType = XMLNodeType.StartElement Then
				vPageTitle = vXMLReader.AttributeValue("Caption");
				vPageTitle = ?(IsBlankString(vPageTitle), NStr("en = 'Parameters'; de = 'Parameter'; ru = 'Параметры'"), vPageTitle);
				
				vNumberOfPages = vNumberOfPages + 1;
				If vNumberOfPages > 1 Then
					Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
					vCurrentPage = Items.Add("Page" + vNumberOfPages, Type("FormGroup"), Items.Pages);
					vBasicGroup = Undefined;
				EndIf;
				vCurrentPage.Title = vPageTitle;
			EndIf;
			
			If vXMLReader.Name = "Group" And vXMLReader.NodeType = XMLNodeType.StartElement Then
				vGroupTitle = vXMLReader.AttributeValue("Caption");
				vGroupTitle = ?(IsBlankString(vGroupTitle), NStr("en = 'Parameters'; de = 'Parameter'; ru = 'Параметры'"), vGroupTitle);
				
				vBasicGroup = Items.Add("Group" + vIndexGroups, Type("FormGroup"), vCurrentPage);
				vBasicGroup.Type = FormGroupType.UsualGroup;
				vBasicGroup.Representation = Items.GroupHardwareDriver.Representation;
				vBasicGroup.HorizontalStretch = True;
				vBasicGroup.Group = Items.GroupHardwareDriver.Group;
				vBasicGroup.Title = vGroupTitle;
				vIndexGroups = vIndexGroups + 1;
			EndIf;
		EndDo;
	EndIf;
	vXMLReader.Close();
	
	If pFirstLaunch And Not IsBlankString(pAdditionalActions) Then
		vXMLReader = New XMLReader;
		vXMLReader.SetString(pAdditionalActions);
		vXMLReader.MoveToContent();
		If vXMLReader.Name = "Actions" And vXMLReader.NodeType = XMLNodeType.StartElement Then
			While vXMLReader.Read() Do
				If vXMLReader.Name = "Action" And vXMLReader.NodeType = XMLNodeType.StartElement Then
					vActionName = "M_" + vXMLReader.AttributeValue("Name");
					vActionTitle = vXMLReader.AttributeValue("Caption");
					
					vCommand = Commands.Add("A_" + vXMLReader.AttributeValue("Name"));
					vCommand.Title = vActionTitle;
					vCommand.Action = "AdditionalAction";
					
					vItemMenu = Items.Add(vActionName, Type("FormButton"), Items.ExtraActions);
					vItemMenu.Type = FormButtonType.CommandBarButton;
					vItemMenu.Title = vActionTitle;
					vItemMenu.CommandName = "A_" + vXMLReader.AttributeValue("Name");
				EndIf;
			EndDo;
		EndIf;
		vXMLReader.Close();
	EndIf;
	Items.TrackPrefixesAndSuffixes.Visible = MagneticCardReader;
EndProcedure // UpdateCustomInterface

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearCustomInterface()
	While Items.Pages.ChildItems.Count() > 0 Do
		Items.Delete(Items.Pages.ChildItems.Get(0));
	EndDo;
EndProcedure // ClearCustomInterface

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearSettingsAtServer()
	vDriverParametersAttributes = GetAttributes();
	For Each vParameters In vDriverParametersAttributes Do
		If Left(vParameters.Name, 2) <> "P_" Then
			Continue;
		EndIf;
		
		ThisObject[vParameters.Name] = Undefined;
	EndDo;
EndProcedure // ClearSettingsAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveConnectionParameters(pValue)
	If Not ValueIsFilled(Hardware) Then
		Return;
	EndIf;
	
	vHardwareObj = Hardware.GetObject();
	vHardwareObj.ConnectionParameters = New ValueStorage(pValue);
	vHardwareObj.Write();
EndProcedure // SaveConnectionParameters

#EndRegion