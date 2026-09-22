
#Region Variables

Var amSimpleCallsComponent Export; // This is a COM component used to connect Simple Calls
Var amSimpleCallsParameters Export;  // This structure is used to store Simple Calls connection parameters
Var amClipboard Export; // This structure is used to store copy/paste values used in program
Var amReaderMC Export; // Identity cards reader driver COM object
Var amBarcodesScanner Export; // This is barcodes scanner driver data processor object
Var amIdentityCardsProcessing Export; // This structure is used to store identity cards rerader connection parameters
Var amRC Export; // Return code structure
Var amImageScanner Export; // This is COM component used to scan and recognized client identification documents
Var amImageScannerInstance Export; // This is COM component interface used to scan and recognized client identification documents
Var amWacomPad Export; // Wacom driver COM object
Var amHardwarePersistentObjects Export; // This is structure with arbitrary elements that could be added by any other programmers for their own needs
Var amPersistentObjects Export; // This is structure with arbitrary elements that could be added by any other programmers for their own needs
Var amRCErrorDescription Export; //Errors of locking systems
Var amProtection Export; // This is protection system component object variable
Var APDEXParameters Export; // Performance metering parameters
Var amRunExtraSession; // Check if user is allowed to run more then 1 client session at one computer
Var amPermittedLaunchModes; // Permitted launch modes
Var amComponentName Export; // This is protection system comonent name variable. It is initialized according to the protection system type used by program
Var amWebCamera Export; // This is COM component used to make a photo via Web Camera
Var amAskForProgramExitConfirmation; // Ask for program exit confirmation

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeStart(pCancel)
	// Set user interface functional parameters based on the client type
	#If MobileClient Then 
		vFOParams = tcOnServer.GetCommandInterfaceFOParametersAtServer(False, False, True, False);
	#ElsIf WebClient Then 
		vFOParams = tcOnServer.GetCommandInterfaceFOParametersAtServer(False, True, False, False);
	#Else 
		vFOParams = tcOnServer.GetCommandInterfaceFOParametersAtServer(True, False, False, False);
	#EndIf
	
	SetInterfaceFunctionalOptionParameters(vFOParams);
	
	// Check if user is allowed to run more then 1 client session at one computer
	amRunExtraSession = True;
	If tcOnServer.UserIsNotAllowedToRunExtraSession() Then
		amRunExtraSession = False;
	EndIf;
	
	amPermittedLaunchModes = tcOnServer.GetRumModesForPermissionGroup();
	
	// Set user desktop form
	vMobileClientMode = False;
	#If MobileClient Then
		vMobileClientMode = True;
	#EndIf
	
	If tcOnServer.SetDesktop(vMobileClientMode) Then
		Terminate(True);
	EndIf;
	
	If tcOnServer.cmIsInRole("SelfService") Then
		ClientApplication.SetMainWindowMode(MainClientApplicationWindowMode.Kiosk);
	Else
		vCurEmplRef = tcOnServer.cmGetCurrentUserAttribute();
		If ValueIsFilled(vCurEmplRef) Then
			vPermissionGroup = tcOnServer.cmGetEmployeePermissionGroupAtServer(vCurEmplRef);
			If ValueIsFilled(vPermissionGroup) Then
				vAppWindowMode = tcOnServer.cmGetAttributeByRef(vPermissionGroup, "DesktopApplicationWindowMode");
				If vAppWindowMode > 0 Then
					ClientApplication.SetMainWindowMode(?(vAppWindowMode = 1, MainClientApplicationWindowMode.Workplace, MainClientApplicationWindowMode.Kiosk));
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// APDEX
	If APDEXParameters = Undefined Then
		APDEXParameters = New Map;
	EndIf;
	
	// Caching the value to get around the platform bug
	tcOnServer.cmIsInRole("Administrator")
EndProcedure // BeforeStart

// -----------------------------------------------------------------------------
&AtClient
Procedure OnStart()
	// Check if user is allowed to run more then 1 client session at one computer
	If amRunExtraSession = False Then
		ShowMessageBox(, Nstr("en = 'Only one application session allowed!';
							  |de = 'Nur eine Bewerbungssitzung erlaubt!';
							  |ru = 'Разрешено запускать только один сеанс приложения!'"), ,
							  NStr("en = 'Application launch error'; de = 'Fehler beim Anwendungsstart'; ru = 'Ошибка запуска приложения'"));
		tcOnServer.Wait(5);
		Terminate();
		Return;
	EndIf;
	#If ThinClient Then 
		If amPermittedLaunchModes.ThinClientLaunchIsForbidden = True Then
			ShowMessageBox(, Nstr("en = 'Starting the program in thin client mode is prohibited!';
								  |de = 'Das Starten des Programms im Thin-Client-Modus ist verboten!';
								  |ru = 'Запуск программы в режиме тонкого клиента запрещен в наборе прав!'"), ,
								  NStr("en = 'Application launch error'; de = 'Fehler beim Anwendungsstart'; ru = 'Ошибка запуска приложения'"));
			tcOnServer.Wait(5);
			Terminate();
			Return;
		EndIf;
	#ElsIf WebClient Then
		If amPermittedLaunchModes.WebClientLaunchIsForbidden = True Then
			ShowMessageBox(, Nstr("en = 'Starting the program in web-client mode is prohibited!'; 
								  |de = 'Das Starten des Programms im Web-Client-Modus ist verboten!'; 
								  |ru = 'Запуск программы в режиме web-клиента запрещен в наборе прав!'"), ,
								  NStr("en = 'Application launch error'; de = 'Fehler beim Anwendungsstart'; ru = 'Ошибка запуска приложения'"));
			tcOnServer.Wait(5);
			Terminate();
			Return;
		EndIf;
	#ElsIf MobileClient Then
		If amPermittedLaunchModes.MobileClientLaunchIsForbidden = True Then
			ShowMessageBox(, Nstr("en = 'Starting the program in mobile client mode is prohibited!'; 
								  |de = 'Das Starten des Programms im Mobile-Client-M3odus ist verboten!'; 
								  |ru = 'Запуск программы в режиме мобильного клиента запрещен в наборе прав!'"), ,
								  NStr("en = 'Application launch error'; de = 'Fehler beim Anwendungsstart'; ru = 'Ошибка запуска приложения'"));
			tcOnServer.Wait(5);
			Terminate();
			Return;
		EndIf;
	#EndIf
	
	// Current workstation
	#If Not WebClient Then
		vCurEmplRef = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		vCurWstnRef = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
		If ValueIsFilled(vCurEmplRef) Then
			vCurComputerName = ComputerName();
			vCurComputerRef = tcOnServer.FindWorkstationByName(vCurComputerName);
			// If this is a new workstation then create it in the database
			vNewWorkstationWasCreated = False;
			If Not ValueIsFilled(vCurComputerRef) Then
				vCurComputerRef = tcOnServer.AddWorkstation(vCurComputerName, vCurEmplRef);
				vNewWorkstationWasCreated = True;
			EndIf;
			vCurEmplRefWorkstation = tcOnServer.cmGetAttributeByRef(vCurEmplRef, "Workstation");
			If ValueIsFilled(vCurEmplRefWorkstation) Then
				vCurComputerRef = vCurEmplRefWorkstation;
			EndIf;
			If ValueIsFilled(vCurComputerRef) And vCurWstnRef <> vCurComputerRef Then
				tcOnServer.SetSessionParametersCurrentWorkstation(vCurComputerRef);
				tcOnServer.SetTimeZone(vCurComputerRef);
			EndIf;
		EndIf;
	#EndIf
	
	// Load protection system
	vErr = "";
	If Not tcProtection.StartProtection(vErr) Then
		OpenForm("CommonForm.tcProtectionForm", New Structure("ErrorDescription", vErr));
	EndIf;
	
	// Initialize connection hardware
	vHardware = tcDevicesConnection.GetConnectionHardware();
	
	// Initialize connection to the MC reader
	amReaderMC = Undefined;
	amIdentityCardsProcessing = vHardware.IdentityCardsProcessingSystemParameters;
	If amIdentityCardsProcessing.HasConnection  And Not amIdentityCardsProcessing.CardReaderType = PredefinedValue("Enum.CardReaderTypes.ISD") Then
		Status(NStr("en = 'Switching to the card reader...'; de = 'Anschluss an den Kartenleser...'; ru = 'Подключение к считывателю карт...'", CurrentSystemLanguage()));
		amRC.Insert("RC_CODE");
		amReaderMC = tcOnClient.cmConnectReader(amIdentityCardsProcessing, amRC);
		If amReaderMC = Undefined Then
			vCloseMessages = False;
			vErrorCode = amRC.Get("RC_CODE"); 
			vErrorDescription = amRC.Get(vErrorCode); 
			vMessage = StrTemplate(NStr("en = 'Error connecting to MC reader! Error code: %1. Error description: %2'; 
										|de = 'Reader-Verbindungsfehler! Fehlercode: %1. Fehlerbeschreibung: %2'; 
										|ru = 'Ошибка подключения считывателя! Код ошибки: %1. Описание ошибки: %2'"), vErrorCode, vErrorDescription);
			
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
	EndIf;
	
	// Initialize connection to the barcodes scanner
	amBarcodesScanner = Undefined;
	amBarcodesScannerProcessing = vHardware.BarcodesScannerConnectionParameters;
	If amBarcodesScannerProcessing.HasConnection Then
		Status(NStr("en='Switching to the barcodes scanner...';ru='Подключение к сканеру штрихкодов...';de='Anschluss an den Strichcode-Scanner...'"));
		If amRC.Get("RC_CODE") = Undefined Then
			amRC.Insert("RC_CODE");
		EndIf;
		amBarcodesScanner = tcConnectionHardwareAtClient.cmConnectScanner(amBarcodesScannerProcessing, amRC);
		If amBarcodesScanner = Undefined Then
			vCloseMessages = False;
			vErrorCode = amRC.Get("RC_CODE"); 
			vErrorDescription = amRC.Get(vErrorCode); 
			vMessage = StrTemplate(NStr("en = 'Error connecting to barcodes scanner! Error code: %1. Error description: %2'; 
										|de = 'Fehler beim Verbinden mit dem Barcode-Scanner! Fehlercode: %1. Fehlerbeschreibung: %2'; 
										|ru = 'Ошибка подключения сканера штрихкодов! Код ошибки: %1. Описание ошибки: %2'", CurrentSystemLanguage()),
										vErrorCode, vErrorDescription);  
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
	EndIf;
	
	// Initialize Simple Calls driver
	vSimpleCalls = vHardware.SimpleCalls;
	If vSimpleCalls.HasConnection And Not vSimpleCalls.WorkStationAlreadyRun Then
		
		tcSimpleCallsOnClient.ConnectComponents();
		
		If Not amSimpleCallsComponent = Undefined And amSimpleCallsComponent.connectionState = 1 Then
			tcOnServer.cmChangeObjectAttributeByRef(vSimpleCalls.Workstation, "WorkStationAlreadyRun", True);
		EndIf;
	EndIf;
	
	// Check if user is filled
	vHotel = Undefined;
	vCurEmplRef = tcOnServer.cmGetCurrentUserAttribute();
	If ValueIsFilled(vCurEmplRef) Then
		vHotel = tcOnServer.cmGetAttributeByRef(vCurEmplRef, "Hotel");
		
		vPermissionGroup = tcOnServer.cmGetEmployeePermissionGroupAtServer(vCurEmplRef);
		If Not ValueIsFilled(vPermissionGroup) Then
			vDescription = TrimAll(tcOnServer.cmGetAttributeByRef(vCurEmplRef, "Description"));
			If tcOnServer.cmIsInRole("Administrator") Then
				ShowValue(, vCurEmplRef);
			EndIf;
			vMessage = StrTemplate(NStr("en = 'New employee <%1> has been created! It is neccessary to fill employee attributes.';
										|de = 'Neue Mitarbeiter <%1> wurde erstellt! Es ist notwendig, um Mitarbeiter Attributen zu füllen.';
										|ru = 'Зарегистрирован новый сотрудник <%1>! Необходимо установить его параметры.'", CurrentSystemLanguage()), vDescription);
			ShowMessageBox(, vMessage);
		EndIf;
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurEmplRef, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then
			amAskForProgramExitConfirmation = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "AskForProgramExitConfirmation");
		EndIf;
	Else
		OpenForm("DataProcessor.FirstFilling.Form", , , , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	
	// Set application caption
	tcOnClient.ChangeApplicationCaption(tcOnServer.cmGetSessionParametersAttribute("CurrentHotel"));
	
	// Set functional option parameters bound to current hotel
	If ValueIsFilled(vHotel) Then
		SetInterfaceFunctionalOptionParameters(New Structure("Hotel", vHotel));
		// Refresh user interface
		RefreshInterface();
	EndIf;
	
	// Check infobase update
	tcOnClient.DoInfoBaseUpdate();
	
	// User exit   
	tcOnServer.RunUserExitAlgorithm("OnStartSystem");
	
	If ValueIsFilled(vCurEmplRef) Then
		AttachIdleHandler("ApplicationCaptionExt", 1800);
	EndIf;  
	// Open form to change password
	If ValueIsFilled(vCurEmplRef) And tcOnServer.cmGetAttributeByRef(vCurEmplRef, "NeedChangePassword") Then   
		OpenForm("Catalog.Employees.Form.InfobaseUserSettings", New Structure("Employee, ResetNeedChangePassword", vCurEmplRef, True));
	EndIf;
EndProcedure // OnStart

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternEventProcessing(pSource, pEvent, pData)
	If tcOnServer.cmIsInRole("SelfService") Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	
	// Process
	tcConnectionHardwareAtClient.ProcessScannerInputResult(vEventData.DeviceData);
EndProcedure // ExternEventProcessing

// -----------------------------------------------------------------------------
Procedure BeforeExit(pCancel, pMessageText)
	If Not amAskForProgramExitConfirmation Then
		Return;
	EndIf;
	
	pCancel = True;
	pMessageText = NStr("en = 'Exit program?'; de = 'Die Arbeit mit dem Programm beenden?'; ru = 'Завершить работу с программой?'");
EndProcedure // BeforeExit

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
amRC = New Map();
amProtection = Undefined;
amClipboard = New Structure();
amHardwarePersistentObjects = New Structure();
amPersistentObjects = New Structure();
amImageScanner = Undefined;
amWebCamera = Undefined;
amWacomPad = New Structure("WizCtl, SigCtl, DynamicCapture, stdFont, Licence");
amPersistentObjects = New Structure("IsDemoMode", False);
amAskForProgramExitConfirmation = False;

#EndRegion
