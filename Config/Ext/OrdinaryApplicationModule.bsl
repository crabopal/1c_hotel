
#Region Variables

Var amWSHShell Export; // Windows WScript.Shell COM object variable. Is used to close messages window automatically and shut down system if necessary
Var amPersistentObjects Export; // This is structure with arbitrary elements that could be added by any other programmers for their own needs
Var amHardwarePersistentObjects Export; // This is structure with arbitrary elements that could be added by any other programmers for their own needs
Var amClipboard Export; // This structure to store copy/paste values used in program
Var amProtection Export; // This is protection system component object variable
Var amComponentName Export; // This is protection system comonent name variable. It is initialized according to the protection system type used by program
Var amIdentityCardSystemDriver Export; // This is client identification cards driver data processor object
Var amReaderMC Export; // This is Scaner1C.dll COM component to work with Magnetic Card (MC) readers and barcode scanners
Var amRibbonPrinterIsAttached Export; // This is boolean flag indicating that ribbon printer add-in was already loaded
Var amBarcodesScannerDriver Export; // This is barcodes scanner driver data processor object
Var amImageScanner Export; // This is COM component used to scan and recognized client identification documents
Var amImageScannerInstance Export; // This is COM component interface used by the Cognitive scanify API
Var amImageScannerDriver Export; // This is images scanner driver data processor object
Var amDoNotHideOneRoomGuestsAttributes Export; // This is permission group attribute used to draw one room guests
Var amSimpleCallsComponent Export;  // This is a COM component used to connect Simple Calls
Var amSimpleCallsParameters Export; // This structure is used to store Simple Calls connection parameters
Var amWacomPad Export;  // Wacom driver COM object
Var amRCErrorDescription Export; // Errors of locking systems
Var APDEXParameters Export; // Performance metering parameters
Var amRunExtraSession; // Check if user is allowed to run more then 1 client session at one computer
Var amPermittedLaunchModes; // Permitted launch modes
Var amWebCamera Export; //This is COM component used to make a photo via Web Camera


#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnStart()
	vOpenFirstFillingForm = False;
	// Check if user is allowed to run more then 1 client session at one computer
	If amRunExtraSession = False Then
		ShowMessageBox(, Nstr("en = 'Only one application session allowed!'; de = 'Nur eine Bewerbungssitzung erlaubt!'; ru = 'Разрешено запускать только один сеанс приложения!'"), ,
		                 NStr("en = 'Application launch error'; de = 'Fehler beim Anwendungsstart'; ru = 'Ошибка запуска приложения'"));
		AttachIdleHandler("amExit", 2, True);
		Return;
	EndIf;	 
	// Check permitted launch modes 
	If amPermittedLaunchModes.ThickClientLaunchIsForbidden = True Then
		ShowMessageBox(, NStr("en = 'Starting the program in thick client mode is prohibited!'; de = 'Das Starten des Programms im Thick-Client-Modus ist verboten!'; ru = 'Запуск программы в режиме толстого клиента запрещен в наборе прав!'"), ,
		                 NStr("en = 'Application launch error'; de = 'Fehler beim Anwendungsstart'; ru = 'Ошибка запуска приложения'"));
		AttachIdleHandler("amExit", 2, True);
		Return;
	EndIf;	

	// Initialize program run mode
	amPersistentObjects.Insert("IsDemoMode", False);
	
	// Load protection system
	Status(NStr("en='Loading protection system...';ru='Инициализация системы защиты...';de='Initialisierung des Schutzsystems...'"));
	If Not Protection.cmLoad() Then
		amPersistentObjects.IsDemoMode = True;
		vMsg = NStr("en='DEMO MODE! Dongle not found. Reports will not be formatted.'; 
					 |de='DEMO MODE! Dongle nicht gefunden. Das Programm erstellt Berichte ohne Formatierung.'; 
					 |ru='ДЕМО-РЕЖИМ! Не обнаружен ключ защиты программы. Программа будет формировать отчеты без форматирования.'", CurrentSystemLanguage());  
		Message = New UserMessage;
		Message.Text = vMsg;
		Message.Message();
	EndIf;
	
	// Check platform version
	vMinVersion = "";
	If Not cmCheckPlatformVersion(vMinVersion) Then
		vError = NStr("en = 'The program must run on platform with version not lower then version %1!'; 
					  |ru = 'Для работы программы необходима версия платформы не ниже %1!'; 
					  |de = 'Das Programm muss die Plattform-Version nicht weniger als %1!'");
		Raise StrTemplate(vError, vMinVersion);
	EndIf;
	
	// Check platform type
	vPlatformType = cmGetPlatformType();
	If Not vPlatformType = PlatformType.Windows_x86 Then
		vMsg = NStr("en = 'You have installed the platform type ""%1"". For this type of platform, work with equipment and a graphics card is not supported. It is recommended to install a 32-bit 1C platform.'; 
					|de = 'Sie haben den Plattformtyp ""%1"" installiert. Für diesen Plattformtyp wird die Arbeit mit Geräten und einer Grafikkarte nicht unterstützt. Es wird empfohlen, eine 32-Bit-1C-Plattform zu installieren.'; 
					|ru = 'Установлен тип платформы ""%1"". Для данного типа  платформы не поддерживается работа с оборудованием и графической картой. Рекомендуется установить 32-х битную платформу 1С.'");
		Message = New UserMessage;
		Message.Text = StrTemplate(vMsg, vPlatformType);
		Message.Message();
	EndIf;	
		
	// Current workstation
	vCurEmplRef = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
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
		If vNewWorkstationWasCreated And ValueIsFilled(vCurComputerRef) Then
			tcOnServer.SetSessionParametersCurrentWorkstation(vCurComputerRef);
		EndIf;
	Else
		vOpenFirstFillingForm = True;
	EndIf;
	
	// Initialize connection to the MC reader
	amReaderMC = Undefined;
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And 
	   SessionParameters.CurrentWorkstation.HasConnectionToIdentityCardsProcessingSystem And 
	   ValueIsFilled(SessionParameters.CurrentWorkstation.IdentityCardsProcessingSystemParameters) Then
		amIdentityCardSystemDriver = cmGetClientIdentityCardsSystemDataProcessor();
		If amIdentityCardSystemDriver <> Undefined And 
		   ValueIsFilled(amIdentityCardSystemDriver.IdentityCardSystemParameters) And 
		   (amIdentityCardSystemDriver.IdentityCardSystemParameters.CardReaderType = Enums.CardReaderTypes.RS232 Or 
		    amIdentityCardSystemDriver.IdentityCardSystemParameters.CardReaderType = Enums.CardReaderTypes.RS232_1C Or
		    amIdentityCardSystemDriver.IdentityCardSystemParameters.CardReaderType = Enums.CardReaderTypes.IronLogicZ2) Then
			Status(NStr("en='Switching to the card reader...';ru='Подключение к считывателю карт...';de='Anschluss an den Kartenleser...'"));
			amReaderMC = amIdentityCardSystemDriver.pmConnect();
			If amReaderMC = Undefined Then
				vCloseMessages = False;
				vErrorDescription = "";
				vErrorCode = amIdentityCardSystemDriver.pmGetLastError(vErrorDescription);
				vMessage = StrTemplate(NStr("en = 'Error connecting to MC reader! Error code: %1. Error description: %2'; 
										 |de = 'Reader-Verbindungsfehler! Fehlercode: %1. Fehlerbeschreibung: %2'; 
										 |ru = 'Ошибка подключения считывателя! Код ошибки: %1. Описание ошибки: %2'", CurrentSystemLanguage()), vErrorCode, vErrorDescription); 
			
				Message = New UserMessage;
				Message.Text = vMessage;
				Message.Message();
			EndIf;
		EndIf;
	EndIf;
	
	// Initialize connection to the barcodes scanner
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And 
	   SessionParameters.CurrentWorkstation.HasConnectionToBarcodesScanner And 
	   ValueIsFilled(SessionParameters.CurrentWorkstation.BarcodesScannerConnectionParameters) Then
		amBarcodesScannerDriver = cmGetBarcodesScannerDriverDataProcessor();
		If amBarcodesScannerDriver <> Undefined Then
			Status(NStr("en='Switching to the barcodes scanner...';ru='Подключение к сканеру штрихкодов...';de='Anschluss an den Strichcode-Scanner...'"));
			vScanner = amBarcodesScannerDriver.pmConnect(amReaderMC);
			If vScanner = Undefined Then
				vCloseMessages = False;
				vErrorDescription = "";
				vErrorCode = amBarcodesScannerDriver.pmGetLastError(vErrorDescription);
				vMessage = StrTemplate(NStr("en = 'Error connecting to barcodes scanner! Error code: %1. Error description: %2'; 
										|de = 'Fehler beim Verbinden mit dem Barcode-Scanner! Fehlercode: %1. Fehlerbeschreibung: %2'; 
										|ru = 'Ошибка подключения сканера штрихкодов! Код ошибки: %1. Описание ошибки: %2'", CurrentSystemLanguage()), 
									vErrorCode, vErrorDescription);  
				Message = New UserMessage;
				Message.Text = vMessage;
				Message.Message();
			Else
				If amReaderMC = Undefined Then
					amReaderMC = vScanner;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Initialize image scanner driver
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And 
	   SessionParameters.CurrentWorkstation.HasConnectionToImagesScanner And 
	   ValueIsFilled(SessionParameters.CurrentWorkstation.ImagesScannerConnectionParameters) Then
		amImageScannerDriver = cmGetImagesScannerDriverDataProcessor();
	EndIf;
	
	// Initialize Simple Calls driver
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And 
	   SessionParameters.CurrentWorkstation.HasConnectionToSimpleCalls And 
	    Not SessionParameters.CurrentWorkstation.WorkStationAlreadyRun Then
		
		tcSimpleCallsOnClient.ConnectComponents();
		
		If Not amSimpleCallsComponent = Undefined And amSimpleCallsComponent.connectionState=1 Then
			vWorkStation = SessionParameters.CurrentWorkstation.GetObject();
			vWorkStation.WorkStationAlreadyRun = True;
			vWorkStation.Write();
		EndIf;
	EndIf;
	
	// Initialize settings used to draw gui forms
	amDoNotHideOneRoomGuestsAttributes = False;
	vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermissionGroup) Then
		amDoNotHideOneRoomGuestsAttributes = vPermissionGroup.DoNotHideOneRoomGuestsAttributes;
	EndIf;
	
	// Open main menu
	Status(NStr("en='Opening main menu...';ru='Инициализация главного меню...';de='Initialisierung des Hauptmenüs...'"));
	vCurUser = InfoBaseUsers.CurrentUser();
	vMainMenuFormName = "MainMenuCompleteSetOfFunctions";
	If vCurUser.DefaultInterface <> Undefined Then
		If TrimAll(vCurUser.DefaultInterface.Name) = "Kiosk" Then
			vMainMenuFormName = "Kiosk";
		Else
			vMainMenuFormName = "MainMenu" + TrimAll(vCurUser.DefaultInterface.Name);
		EndIf;
	EndIf;
	vMainMenu = Undefined;
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.PermissionGroup) And 
	   ValueIsFilled(SessionParameters.CurrentUser.PermissionGroup.DesktopExternalDataProcessor) Then
		Try
			vDesktopObj = cmGetExternalDataProcessorObject(SessionParameters.CurrentUser.PermissionGroup.DesktopExternalDataProcessor);
			vMainMenu = vDesktopObj.GetForm();
			vMainMenu.Open();
		Except
			vMainMenu = Undefined;
		EndTry;
	EndIf;
	If vMainMenu = Undefined Then
		If vMainMenuFormName = "Kiosk" Then
			vKioskFolio = SessionParameters.CurrentWorkstation.KioskFolio;
			vMainMenu = Catalogs.Services.GetForm("KioskForm");
			vMainMenu.ChoiceMode = True;
			vMainMenu.MultipleChoice = True;
			vMainMenu.CloseOnChoice = False;
			vMainMenu.CloseOnOwnerClose = False;
			vMainMenu.SelKioskFolio = vKioskFolio;
			vMainMenu.SelHotel = SessionParameters.CurrentHotel;
			vMainMenu.DesktopMode = True;
		Else
			vMainMenu = GetCommonForm(vMainMenuFormName);
		EndIf;
		vMainMenu.Open();
	EndIf;
	amPersistentObjects.Insert("MainMenuForm", vMainMenu);
	amPersistentObjects.Insert("OpenForms", New ValueList());
	
	// Show success status
	Status(NStr("en='Successfull system start!';ru='Программа успешно запущена!';de='Das Programm wurde erfolgreich gestartet!'"));
	
	If vOpenFirstFillingForm Then
		vResult = OpenFormModal("DataProcessor.FirstFilling.Form");
		If TypeOf(vResult) = Type("Structure") Then
			If vResult.Close Then
				Exit( , vResult.Restart);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnStart

// -----------------------------------------------------------------------------
Procedure BeforeStart(pCancel)
	// Current workstation
	vCurComputer = ComputerName();
	vCurComputerRef = Catalogs.Workstations.FindByCode(vCurComputer);
	If ValueIsFilled(vCurComputerRef) And vCurComputerRef.IsFolder Then
		vCurComputerRef = Undefined;
	EndIf;
	// If this is a new workstation then create it in the database
	If Not ValueIsFilled(vCurComputerRef) Then
		vNewWstn = Catalogs.Workstations.CreateItem();
		vNewWstn.Code = vCurComputer;
		vSysInfo = New SystemInfo();
		vNewWstn.SysInfo = StrTemplate("Processor: %1; RAM: %2Mb; OS Version: %3", vSysInfo.Processor, vSysInfo.RAM, vSysInfo.OSVersion);  
		vNewWstn.Write();
		vCurComputerRef = vNewWstn.Ref;
		vMessage = StrTemplate(NStr("ru = 'Зарегистрировано новое рабочее место <%1>! Необходимо установить его параметры.'; 
		           |de = 'Зарегистрировано новое рабочее место <%1>! Необходимо установить его параметры.'; 
		           |en = 'New workstation <%1> has been created! It is neccessary to fill workstation attributes.';", CurrentSystemLanguage()), TrimAll(vCurComputerRef.Code)); 
		WriteLogEvent(NStr("en='System.OnStart';ru='Программа.Запуск';de='Программа.Запуск'"), EventLogLevel.Information, vCurComputerRef.Metadata(), vCurComputerRef, vMessage);
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			cmSendMessageToEmployee(SessionParameters.CurrentUser, vMessage);
		EndIf;
	EndIf;
	vHotel = Undefined;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vHotel = SessionParameters.CurrentUser.Hotel;
		
		vEmployeeNonReplicatingAttributes = SessionParameters.CurrentUser.GetObject().pmGetNonReplicatingAttributes();
		If vEmployeeNonReplicatingAttributes.Count() > 0 And 
		   ValueIsFilled(vEmployeeNonReplicatingAttributes.Get(0).Workstation) Then
			SessionParameters.CurrentWorkstation = vEmployeeNonReplicatingAttributes.Get(0).Workstation;
		ElsIf vEmployeeNonReplicatingAttributes.Count() = 0 And ValueIsFilled(SessionParameters.CurrentUser.Workstation) Then
			SessionParameters.CurrentWorkstation = SessionParameters.CurrentUser.Workstation;
		ElsIf cmCheckUserPermissions("HavePermissionToChooseWorkstationOnProgramStartUp") Then
			vWstns = cmGetWorkstationsList(True);
			vWstnItem = vWstns.ChooseItem(NStr("en='Choose workstation...';ru='Выберите рабочее место...';de='Wählen Sie den Arbeitsplatz...'"), vCurComputerRef);
			If vWstnItem = Undefined Then
				SessionParameters.CurrentWorkstation = vCurComputerRef;
			Else
				SessionParameters.CurrentWorkstation = vWstnItem.Value;
			EndIf;
		Else
			SessionParameters.CurrentWorkstation = vCurComputerRef;
		EndIf;
	Else
		SessionParameters.CurrentWorkstation = vCurComputerRef;
	EndIf;
	// Register current session and set functional option parameters
	vFOParams = tcOnServer.GetCommandInterfaceFOParametersAtServer(False, False, False, True);
	SetInterfaceFunctionalOptionParameters(vFOParams);
	If ValueIsFilled(vHotel) Then
		SetInterfaceFunctionalOptionParameters(New Structure("Hotel", vHotel));
		// Refresh user interface
		RefreshInterface();
	EndIf;
	// Check if user is allowed to run more then 1 client session at one computer
	amRunExtraSession = True;
	If tcOnServer.UserIsNotAllowedToRunExtraSession() Then
		amRunExtraSession = False;
	EndIf;  
	amPermittedLaunchModes = tcOnServer.GetRumModesForPermissionGroup();
	// Load windows scripting host shell
	Try
		amWSHShell = New COMObject("WScript.Shell");
	Except
		WriteLogEvent(NStr("en='System.OnStart';ru='Программа.Запуск';de='System.OnStart'"), EventLogLevel.Note, vCurComputerRef.Metadata(), vCurComputerRef, ErrorDescription());
		amWSHShell = Undefined;
	EndTry;
	// APDEX
	If APDEXParameters = Undefined Then
		APDEXParameters = New Map;
	EndIf;
EndProcedure // BeforeStart

// -----------------------------------------------------------------------------
Procedure BeforeExit(pCancel)
	// Program exit confirmation only if program exits normally 
	// (not because of protection system command)
	vProtectionIsOn = Protection.cmIsProtectionActive();
	If vProtectionIsOn Then
		vEmployee = SessionParameters.CurrentUser;
		If ValueIsFilled(vEmployee) Then
			If ValueIsFilled(vEmployee.EmployeePreferences) Then
				If vEmployee.EmployeePreferences.AskForProgramExitConfirmation Then
					If DoQueryBox(NStr("en='Exit program?';ru='Завершить работу с программой?';de='Die Arbeit mit dem Programm beenden?'"), QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes) = DialogReturnCode.No Then
						pCancel = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// APDEX
	APDEXPerformanceSystemOnClient.BeforeExit(pCancel);
EndProcedure // BeforeExit

// -----------------------------------------------------------------------------
Procedure OnExit()
	Try
		// Close TrPosX connection
		If ValueIsFilled(SessionParameters.CurrentWorkstation) And 
		   SessionParameters.CurrentWorkstation.HasConnectionToCreditCardsProcessingSystem And 
		   ValueIsFilled(SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters) And
		   (SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.TrPosPOSTerminalsDriver Or 
		    SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.INPASPulsarSystemDriver Or 
		    SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.INPASDualConnectorDriver82 Or 
		    SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.INPASDualConnectorDriver83 Or 
		    SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.SberbankSBRFCOMSystemDriver Or 
		    SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.UCSSystemDriver) Then
			vPayCardProcessor = cmGetPayCardDataProcessor(SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters);
			vPayCardProcessor.pmDisconnect();
		EndIf;
	Except
	EndTry;
	Try
		// Close reader MC connection
		If amIdentityCardSystemDriver <> Undefined Then
			amIdentityCardSystemDriver.pmDisconnect(amReaderMC);
			amIdentityCardSystemDriver = Undefined;
		EndIf;
	Except
	EndTry;
	Try
		// Close barcodes scanner connection
		If amBarcodesScannerDriver <> Undefined Then
			amBarcodesScannerDriver.pmDisconnect(amReaderMC);
			amBarcodesScannerDriver = Undefined;
		EndIf;
		amReaderMC = Undefined;
	Except
	EndTry;
	Try
		// Close image scanner connection
		If amImageScannerDriver <> Undefined Then
			amImageScannerDriver.pmDisconnect(amImageScanner, amImageScannerInstance);
			amImageScannerDriver = Undefined;
		EndIf;
		amImageScanner = Undefined;
		amImageScannerInstance = Undefined;
	Except
	EndTry;
	Try
		// Shutdown protection system
		Protection.cmShutdown();
		// Log off Windows if necessary
		If cmCheckUserPermissions("LogOffAfterProgramExit") Then
			amLogOffWindows();
		EndIf;
	Except
	EndTry;
	
	// Release windows scripting host shell object
	amWSHShell = Undefined;
	
	Try
		If ValueIsFilled(SessionParameters.CurrentWorkstation) And 
		   SessionParameters.CurrentWorkstation.HasConnectionToSimpleCalls And 
		    SessionParameters.CurrentWorkstation.WorkStationAlreadyRun Then
			tcSimpleCallsOnClient.Disconnect();
			vWorkStation = SessionParameters.CurrentWorkstation.GetObject();
			vWorkStation.WorkStationAlreadyRun = False;
			vWorkStation.Write();
		EndIf;
	Except
	EndTry;
EndProcedure // OnExit

// -----------------------------------------------------------------------------
Procedure ExternEventProcessing(pSource, pEvent, pData)
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If vEventData.DeviceType <> "BarCodeScaner" Then
		Return;
	EndIf;
	
	// Get Reservation
	Try
		vUUID = New UUID(vEventData.DeviceData);
	Except
		Return;
	EndTry;
	
	vReservation = Documents.Reservation.GetRef(vUUID);
	If Not ValueIsFilled(vReservation) Then
		ShowMessageBox(,NStr("en='Clients are not found';ru='Гости не найдены';de='Kunden nicht gefunden'"));
		Return;
	EndIf;
	
	// Get Expected Check-In form
	vFrm = GetForm("CommonForm.tcExpressCheckInForm", New Structure("Key", vReservation));
	If vFrm <> Undefined Then
		If vFrm.IsOpen() Then
			vFrm.Close();
			vFrm = GetForm("CommonForm.tcExpressCheckInForm", New Structure("Key", vReservation));
		EndIf;
		vFrm.Open();
	Else
		If vReservation.ReservationStatus.IsCheckIn Then
			ShowMessageBox(,NStr("ru='Гость уже заехал.'; en='Guest have already checked-in'; de='Gäste haben bereits eingecheckt'"));
		ElsIf vReservation.ReservationStatus.IsAnnulation Then
			ShowMessageBox(,NStr("ru='Бронь была аннулирована'; en='Reservation is canceled'; de='Reservierung storniert'"));
		ElsIf BegOfDay(vReservation.CheckInDate) <> BegOfDay(CurrentSessionDate()) Then
			ShowMessageBox(,NStr("ru='Дата заезда не совпадает с текущей датой'; en='Check-in date is not the same as the current date'; de='Check-in-Datum ist nicht das gleiche wie das aktuelle Datum'"));
		Else
			ShowMessageBox(,NStr("ru='Неизвестная ошибка! Проверьте бронь. '; en='Unknown error! Check the reservation.'; de='Unbekannter Fehler! Überprüfen Sie die Reservierung.'"));
		EndIf;
	EndIf;
EndProcedure // ExternEventProcessing

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// Description: Closes messages window using windows scripting host
//              Special keys are: "%" - alt, "+" - Shift, "^" - Ctrl
// -----------------------------------------------------------------------------
Procedure amCloseMessages() Export
	If amWSHShell <> Undefined Then
		Try
			// Sending Ctrl+Shift+Z combination of keys
		    amWSHShell.SendKeys("^+Z");
		Except
		EndTry;
	EndIf;
EndProcedure // amCloseMessages

// -----------------------------------------------------------------------------
// Description: Closes all windows using windows scripting host
//              Special keys are: "%" - alt, "+" - Shift, "^" - Ctrl
// -----------------------------------------------------------------------------
Procedure amCloseAllWindows() Export
	If amWSHShell <> Undefined Then
		Try
			// Sending Alt+О combination of keys and then С
		    amWSHShell.SendKeys("%+О");
		    amWSHShell.SendKeys("С");
		Except
		EndTry;
	EndIf;
EndProcedure // amCloseAllWindows

// -----------------------------------------------------------------------------
Procedure amExit() Export 
	Terminate();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// Logs off current user from Windows
// -----------------------------------------------------------------------------
Procedure amLogOffWindows()
	If amWSHShell <> Undefined Then
		Try
			// Calling command shell program "shutdown -l -f"
		    amWSHShell.Exec("shutdown -l -f");
		Except
		EndTry;
	EndIf;
EndProcedure // amLogOffWindows

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
amWSHShell = Undefined;
amHardwarePersistentObjects = New Structure();
amPersistentObjects = New Structure();
amClipboard = New Structure();
amProtection = Undefined;
If Constants.ProtectionSystemType.Get() = Enums.ProtectionSystemTypes.Guardant Then
	amComponentName = "Roomba";
Else
	amComponentName = "LicenceAddIn";
EndIf;
amRibbonPrinterIsAttached = False;
amImageScanner = Undefined;
amImageScannerInstance = Undefined;
amWacomPad = New Structure("WizCtl, SigCtl, DynamicCapture, stdFont, Licence");
amRCErrorDescription = "";  
amWebCamera = Undefined;
#EndRegion