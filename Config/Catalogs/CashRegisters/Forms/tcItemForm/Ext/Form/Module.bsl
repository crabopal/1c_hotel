
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	FillPortList();
	FillDriverProtocolList();
	FlilATOLModelList();
	RefreshDisplay();
	FillBaudRateList();
	If Object.PrintFolioHeader Then
		Items.DoNotPrintClient.Enabled = True;
		Items.DoNotPrintRoom.Enabled = True;
	Else
		Items.DoNotPrintClient.Enabled = False;
		Items.DoNotPrintRoom.Enabled = False;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure IsControlledByProgramOnChange(pItem)
	RefreshDisplay();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterDriverOnChange(pItem)
	Object.Port = "";
	FillPortList();
	FillDriverProtocolList();
	FlilATOLModelList();	
	RefreshDisplay();
	FillBaudRateList();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintFolioHeaderOnChange(pItem)
	If Object.PrintFolioHeader Then
		Items.DoNotPrintClient.Enabled = True;
		Items.DoNotPrintRoom.Enabled = True;
	Else
		Items.DoNotPrintClient.Enabled = False;
		Items.DoNotPrintRoom.Enabled = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ConnectionTypeOnChange(Item)
	RefreshDisplay();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChequeVerificationInternetAddressStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	pStandardProcessing = False;
	ChequeVerificationInternetAddressStartChoiceAsync();
EndProcedure // ChequeVerificationInternetAddressStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Test(pCommand)
	rMessage = "";
	If ValueIsFilled(Object.Ref) Then
		vDriver = tcOnClient.cmGetModulTO(Object.Ref);  
		vTitle = NStr("en = 'ERROR'; de = 'Fehler'; ru = 'ОШИБКА'");
		If Not vDriver = Undefined Then
			If vDriver.pmIsReadyToPrint(rMessage, , Object.Ref) Then
				ShowMessageBox(, NStr("en = 'Cash register was connected!'; de = 'Kasse war angeschlossen!'; ru = 'Контрольно-Кассовая Машина подключена!'"));
			Else
				ShowMessageBox(, rMessage, , vTitle);
			EndIf;
		Else   
			vErr = Nstr("en = 'Work with this device driver is not supported!'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'; ru = 'Работа с драйвером этого устройства не поддерживается!'");
			ShowMessageBox(, vErr, , vTitle);
		EndIf;		
	EndIf; 	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenCashDrawer(pCommand)
	rMessage = "";
	If ValueIsFilled(Object.Ref) Then
		vDriver = tcOnClient.cmGetModulTO(Object.Ref); 
		vTitle = NStr("en = 'ERROR'; de = 'Fehler'; ru = 'ОШИБКА'");
		If Not vDriver = Undefined Then
			vCheck = vDriver.pmOpenCashDrawer(rMessage, Object.Ref);
			If vCheck Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'drawer open'; de = 'Schublade offen'; ru = 'Ящик открыт'"));		
			Else	
				tcCommonFunctionOnClientServer.TextMessage(rMessage);
			EndIf;
		Else
			vErr = Nstr("en = 'Work with this device driver is not supported!'; 
			|de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'; 
			|ru = 'Работа с драйвером этого устройства не поддерживается!'");
			ShowMessageBox(, vErr, , vTitle);
		EndIf;		
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckVersionWebServer(pCommand)
	If Not Modified Then
		If ValueIsFilled(Object.Ref) Then
			If ValueIsFilled(Object.Address) Then
				vAddress = StrSplit(Object.Address, ":", False);
				If vAddress.Count() > 1 Then
					vConnect = New HTTPConnection(vAddress[0], Number(vAddress[1]), Object.LoginWebServer, Object.PasswordWebServer);
				Else
					vConnect = New HTTPConnection(Object.Address,, Object.LoginWebServer, Object.PasswordWebServer);	
				EndIf;     
				vVersion = "";
				If GetVerWebServer(vConnect, "/api/v2/serverInfo", vVersion) Then
					Object.VerWebService = vVersion;	
				ElsIf GetVerWebServer(vConnect, "/about", Undefined) Then
					Object.VerWebService = "10.6";	
				Else
					Object.VerWebService = "";
					ShowMessageBox(, NStr("en = 'The version could not be determined'; de = 'Die Version konnte nicht ermittelt werden'; ru = 'Не удалось определить версию'"));	
				EndIf;
			EndIf;
		Else
			ShowMessageBox(, NStr("en = 'Please write cash register first!'; de = 'Bitte schreiben Sie zuerst die Kasse!'; ru = 'ККМ должен быть записан!'"));
		EndIf;
	Else
		ShowMessageBox(, NStr("en = 'All changes must be saved!'; de = 'Alle Änderungen müssen gespeichert werden!'; ru = 'Все изменения должны быть сохранены!'"));
	EndIf;
EndProcedure // CheckVersionWebServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckFDF(pCommand)
	rMessage = "";
	If Not Modified Then
		If ValueIsFilled(Object.Ref) Then
			vDriver = tcOnClient.cmGetModulTO(Object.Ref);
			If Not vDriver = Undefined Then
				vFDF = vDriver.pmGetFDF(rMessage, Object.Ref);
				If vFDF <> Undefined Then
					Object.FiscalDataFormatVersions = vFDF;
					Modified = True;
				Else
					ShowMessageBox(, rMessage);	
				EndIf;
			Else       
				vTitle = NStr("en = 'ERROR'; de = 'Fehler'; ru = 'ОШИБКА'");  
				vErr = Nstr("en = 'Work with this device driver is not supported!'; 
				|de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'; 
				|ru = 'Работа с драйвером этого устройства не поддерживается'");
				ShowMessageBox(, vErr, , vTitle);
			EndIf;	
		Else
			ShowMessageBox(, NStr("en = 'Please write cash register first!'; de = 'Bitte schreiben Sie zuerst die Kasse!'; ru = 'ККМ должен быть записан!'"));
		EndIf;
	Else
		ShowMessageBox(, NStr("en = 'All changes must be saved!'; de = 'Alle Änderungen müssen gespeichert werden!'; ru = 'Все изменения должны быть сохранены!'"));
	EndIf;
EndProcedure // CheckFDF

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillConnectionTypesList()	
	If Object.CashRegisterDriver = Enums.CashRegisterDrivers.ShtrihMDriverFR 
		Or Object.CashRegisterDriver = Enums.CashRegisterDrivers.ShtrihMDriverFR54FZ Then
		Items.ConnectionType.ChoiceList.Clear();
		Items.ConnectionType.ChoiceList.Add("0", "0 - Локально");
		Items.ConnectionType.ChoiceList.Add("1", "1 - Сервер ККМ (TCP)");
		Items.ConnectionType.ChoiceList.Add("2", "2 - Сервер ККМ (DCOM)");
		Items.ConnectionType.ChoiceList.Add("3", "3 - ESCAPE");
		Items.ConnectionType.ChoiceList.Add("5", "5 - Эмулятор");
		Items.ConnectionType.ChoiceList.Add("6", "6 - Подключение через TCP-сокет");		
	EndIf;
EndProcedure // FillConnectionTypesList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPortList()	
	Var vID;	
	Items.Port.ChoiceList.Clear();
	Items.Port.ToolTipRepresentation = ToolTipRepresentation.ShowRight;
	vMaxComPorts = 256;
	If Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver8 
		Or Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZ Then
		Items.Port.ChoiceList.Add("АТОЛ USB");
		Items.Port.ChoiceList.Add("TCP/IP (клиент)");
		Items.Port.ChoiceList.Add("UDP/IP");
		For vID = 1 To vMaxComPorts Do
			Items.Port.ChoiceList.Add("COM" + vID);
		EndDo;
	ElsIf Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZVersion10 Then
		Items.Port.ChoiceList.Add("АТОЛ USB");
		Items.Port.ChoiceList.Add("TCP/IP (клиент)");
		For vID = 1 To vMaxComPorts Do
			Items.Port.ChoiceList.Add("COM" + vID);
		EndDo;
	ElsIf Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCashRegisterWebService Then
		Items.Port.ChoiceList.Add("TCP/IP (клиент)");
		Object.Port = "TCP/IP (клиент)";
		Items.Port.ToolTipRepresentation = ToolTipRepresentation.None;
	Else
		For vID = 1 To vMaxComPorts Do
			Items.Port.ChoiceList.Add("COM" + vID);
		EndDo;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDriverProtocolList()	
	If Object.CashRegisterDriver = Enums.CashRegisterDrivers.ShtrihMDriverFR 
		Or Object.CashRegisterDriver = Enums.CashRegisterDrivers.ShtrihMDriverFR54FZ Then
		Items.DriverProtocol.ChoiceList.Clear();
		Items.DriverProtocol.ChoiceList.Add("0", "0 - Cтандартный");
		Items.DriverProtocol.ChoiceList.Add("1", "1 - Протокол ККТ 2.0");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillBaudRateList()
	Items.BaudRate.ChoiceList.Clear();
	If Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZVersion10 Then
		Items.BaudRate.ChoiceList.Add("1200");
		Items.BaudRate.ChoiceList.Add("2400");
		Items.BaudRate.ChoiceList.Add("4800");
		Items.BaudRate.ChoiceList.Add("9600");
		Items.BaudRate.ChoiceList.Add("19200");
		Items.BaudRate.ChoiceList.Add("38400");
		Items.BaudRate.ChoiceList.Add("57600");
		Items.BaudRate.ChoiceList.Add("115200");
		Items.BaudRate.ChoiceList.Add("230400");
		Items.BaudRate.ChoiceList.Add("460800");
		Items.BaudRate.ChoiceList.Add("921600");
	Else
		Items.BaudRate.ChoiceList.Add("300");
		Items.BaudRate.ChoiceList.Add("600");
		Items.BaudRate.ChoiceList.Add("1200");
		Items.BaudRate.ChoiceList.Add("2400");
		Items.BaudRate.ChoiceList.Add("4800");
		Items.BaudRate.ChoiceList.Add("9600");
		Items.BaudRate.ChoiceList.Add("14400");
		Items.BaudRate.ChoiceList.Add("19200");
		Items.BaudRate.ChoiceList.Add("38400");
		Items.BaudRate.ChoiceList.Add("57600");
		Items.BaudRate.ChoiceList.Add("115200");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FlilATOLModelList()
	Items.CashRegisterModel.ChoiceList.Clear();
	If Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver 
		Or Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver8 
		Or Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZ Then
		Items.CashRegisterModel.ChoiceList.Add(0, "0 - ЭЛВЕС-МИКРО-Ф");
		Items.CashRegisterModel.ChoiceList.Add(13, "13 - Триум-Ф");
		Items.CashRegisterModel.ChoiceList.Add(14, "14 - ФЕЛИКС-Р Ф");
		Items.CashRegisterModel.ChoiceList.Add(15, "15 - ФЕЛИКС-02К / ЕНВД");
		Items.CashRegisterModel.ChoiceList.Add(16, "16 - МЕРКУРИЙ-140");
		Items.CashRegisterModel.ChoiceList.Add(17, "17 - МЕРКУРИЙ-114.1Ф");
		Items.CashRegisterModel.ChoiceList.Add(18, "18 - ШТРИХ-ФР-Ф");
		Items.CashRegisterModel.ChoiceList.Add(19, "19 - ЭЛВЕС-МИНИ-ФР-Ф");
		Items.CashRegisterModel.ChoiceList.Add(20, "20 - ТОРНАДО");
		Items.CashRegisterModel.ChoiceList.Add(23, "23 - ТОРНАДО-К");
		Items.CashRegisterModel.ChoiceList.Add(24, "24 - ФЕЛИКС-РК / ЕНВД");
		Items.CashRegisterModel.ChoiceList.Add(25, "25 - ШТРИХ-ФР-К");
		Items.CashRegisterModel.ChoiceList.Add(26, "26 - ЭЛВЕС-ФР-К");
		Items.CashRegisterModel.ChoiceList.Add(27, "27 - ФЕЛИКС-3СК");
		Items.CashRegisterModel.ChoiceList.Add(28, "28 - ШТРИХ-МИНИ-ФР-К");
		Items.CashRegisterModel.ChoiceList.Add(30, "30 - FPrint-02K / ЕНВД");
		Items.CashRegisterModel.ChoiceList.Add(31, "31 - FPrint-03K / ЕНВД");
		Items.CashRegisterModel.ChoiceList.Add(32, "32 - FPrint-88K / ЕНВД");
		Items.CashRegisterModel.ChoiceList.Add(33, "33 - BIXOLON-01K");
		Items.CashRegisterModel.ChoiceList.Add(35, "35 - FPrint-5200K / ЕНВД");
		Items.CashRegisterModel.ChoiceList.Add(41, "41 - PayVKP-80K");
		Items.CashRegisterModel.ChoiceList.Add(42, "42 - Аура-01ФР-KZ");
		Items.CashRegisterModel.ChoiceList.Add(43, "43 - PayVKP-80KZ");
		Items.CashRegisterModel.ChoiceList.Add(45, "45 - PayPPU-700K");
		Items.CashRegisterModel.ChoiceList.Add(46, "46 - PayCTS-2000K");
		Items.CashRegisterModel.ChoiceList.Add(47, "47 - FPrint-55K / ЕНВД");
		Items.CashRegisterModel.ChoiceList.Add(50, "50 - Wincor Nixdorf TH-230K");
		Items.CashRegisterModel.ChoiceList.Add(51, "51 - FPrint-11 ПТК / К/ ЕНВД");
		Items.CashRegisterModel.ChoiceList.Add(52, "52 - FPrint-22 ПТК / K / ЕНВД");
		Items.CashRegisterModel.ChoiceList.Add(53, "53 - Fprint-77 ПТК / ЕНВД");
		Items.CashRegisterModel.ChoiceList.Add(54, "54 - FprintPay-01ПТК");
		Items.CashRegisterModel.ChoiceList.Add(57, "57 - АТОЛ 25Ф");
		Items.CashRegisterModel.ChoiceList.Add(61, "61 - АТОЛ 30Ф");
		Items.CashRegisterModel.ChoiceList.Add(62, "62 - АТОЛ 55Ф");
		Items.CashRegisterModel.ChoiceList.Add(63, "63 - АТОЛ 22Ф / FPrint-22 ПТК");
		Items.CashRegisterModel.ChoiceList.Add(64, "64 - АТОЛ 52Ф");
		Items.CashRegisterModel.ChoiceList.Add(67, "67 - АТОЛ 11Ф");
		Items.CashRegisterModel.ChoiceList.Add(69, "69 - АТОЛ 77Ф");
		Items.CashRegisterModel.ChoiceList.Add(72, "72 - АТОЛ 90Ф");
		Items.CashRegisterModel.ChoiceList.Add(74, "74 - Эвотор СТ2Ф");
		Items.CashRegisterModel.ChoiceList.Add(75, "75 - АТОЛ 60Ф");
		Items.CashRegisterModel.ChoiceList.Add(76, "76 - Казначей ФА");
		Items.CashRegisterModel.ChoiceList.Add(77, "77 - АТОЛ 42ФС");
		Items.CashRegisterModel.ChoiceList.Add(78, "78 - АТОЛ 15Ф");
		Items.CashRegisterModel.ChoiceList.Add(101, "101 - POSPrint FP410K");
		Items.CashRegisterModel.ChoiceList.Add(102, "102 - МSTAR-Ф");
		Items.CashRegisterModel.ChoiceList.Add(103, "103 - Мария-301 МТМ");
		Items.CashRegisterModel.ChoiceList.Add(104, "104 - ПРИМ-88ТК");
		Items.CashRegisterModel.ChoiceList.Add(105, "105 - ПРИМ-08ТК");
		Items.CashRegisterModel.ChoiceList.Add(106, "106 - СП101ФР-К/СП402ФР-К");
		Items.CashRegisterModel.ChoiceList.Add(107, "107 - ШТРИХ-КОМБО-ФР-К");
		Items.CashRegisterModel.ChoiceList.Add(108, "108 - ПРИМ-07К");
		Items.CashRegisterModel.ChoiceList.Add(109, "109 - МИНИ-ФП6");
		Items.CashRegisterModel.ChoiceList.Add(110, "110 - ШТРИХ-М-ФР-К/ПТК");
		Items.CashRegisterModel.ChoiceList.Add(111, "111 - MSTAR-TK.1");
		Items.CashRegisterModel.ChoiceList.Add(113, "113 - ШТРИХ-LIGHT-ФР-К/ ПТК");
		Items.CashRegisterModel.ChoiceList.Add(114, "114 - КРИСТАЛЛ СЕРВИС: ПИРИТ ФР01К");
		Items.CashRegisterModel.ChoiceList.Add(115, "115 - NCR-001K");
		Items.CashRegisterModel.ChoiceList.Add(116, "116 - IKC-E260T/РФ 2160");
		Items.CashRegisterModel.ChoiceList.Add(117, "117 - ПОРТ FP-300/FP-550/FP-1000");
		Items.CashRegisterModel.ChoiceList.Add(118, "118 - ШТРИХ-ФР-Ф (БЕЛАРУСЬ)");
		Items.CashRegisterModel.ChoiceList.Add(119, "119 - Datecs: FP3530T");
		Items.CashRegisterModel.ChoiceList.Add(120, "120 - ПОРТ FP-60");
		Items.CashRegisterModel.ChoiceList.Add(121, "121 - Мебиус-2К/3К");
		Items.CashRegisterModel.ChoiceList.Add(123, "123 - Spark-801T/115K");
		Items.CashRegisterModel.ChoiceList.Add(125, "125 - ШТРИХ-ФР-К-KZ");
		Items.CashRegisterModel.ChoiceList.Add(126, "126 - Штрих-М: ПТК RR-01К,02К,04К");
		Items.CashRegisterModel.ChoiceList.Add(127, "127 - Штрих-М: ПТК Retail-01К");
		Items.CashRegisterModel.ChoiceList.Add(128, "128 - Кристалл Сервис: PiritK");
	ElsIf Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZVersion10 Then
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_AUTO", NStr("en = 'Automatic model detection (KKT ATOL only)'; de = 'Automatische Modellerkennung (nur KKT ATOL)'; ru = 'Автоматическое определение модели (только ККТ АТОЛ)'"));
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_1F", "АТОЛ 1Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_11F", "АТОЛ 11Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_15F", "АТОЛ 15Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_20F", "АТОЛ 20Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_22F", "АТОЛ 22Ф (АТОЛ FPrint-22ПТК)");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_25F", "АТОЛ 25Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_27F", "АТОЛ 27Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_30F", "АТОЛ 30Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_42FS", "АТОЛ 42ФС");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_50F", "АТОЛ 50Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_52F", "АТОЛ 52Ф");	
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_55F", "АТОЛ 55Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_60F", "АТОЛ 60Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_77F", "АТОЛ 77Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_90F", "АТОЛ 90Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_91F", "АТОЛ 91Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_92F", "АТОЛ 92Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_SIGMA_10", "АТОЛ Sigma 10");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_SIGMA_7F", "АТОЛ Sigma 7Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_ATOL_SIGMA_8F", "АТОЛ Sigma 8Ф");
		Items.CashRegisterModel.ChoiceList.Add("LIBFPTR_MODEL_KAZNACHEY_FA", "Казначей ФА");
	ElsIf Object.CashRegisterDriver = Enums.CashRegisterDrivers.ShtrihMDriverFR54FZ Then
		Items.CashRegisterModel.ChoiceList.Add("Addin.DrvFR", NStr("en = 'Driver FR'; de = 'Treiber Fiskaldrucker'; ru = 'Драйвер ФР'"));
		Items.CashRegisterModel.ChoiceList.Add("Addin.KKTDrv", NStr("en = 'KKT driver'; de = 'KKT Treiber'; ru = 'ККТ драйвер'"));
	Else
		Object.CashRegisterModel = "";
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	Items.GroupFRPage.Visible = Object.IsControlledByProgram;
	Items.GroupChequePage.Visible = Object.IsControlledByProgram;
	Items.GroupMarking.Visible = Object.IsControlledByProgram;
	
	Items.Address.Enabled = False;
	Items.Port.Enabled = True;
	Items.BaudRate.Enabled = True;
	Items.Timeout.Enabled = True;
	Items.OFDServer.Enabled = True;
	Items.OFDPort.Enabled = True;
	Items.OFDPollPeriod.Enabled = True;
	Items.ConnectionType.Enabled = False;
	Items.UseLogicalDevice.Enabled = True;
	Items.LogicalDeviceNumber.Enabled = True;
	Items.AccessPassword.Enabled = True;
	Items.CashRegisterPassword.Enabled = True;
	Items.VerWebService.Enabled = False;
	Items.CheckVersionWebServer.Enabled = False;
	Items.DriverProtocol.Enabled = False;
	Items.DriverProtocol.ChoiceButton = False;
	Items.CashRegisterModel.Title = "";
	Items.CashRegisterModel.Enabled = False;
	Items.CashRegisterModel.ChoiceButton = False;
	Items.CashRegisterModel.ClearButton = False;
	Items.DeviceIDInWebServer.Enabled = False;
	Items.LoginWebServer.Enabled = False;
	Items.PasswordWebServer.Enabled = False;
	Items.FormCheckFDF.Enabled = False;
	Items.FiscalDataFormatVersions.Enabled = False;
	Items.FormOpenCashDrawer.Enabled = True;
	Items.GroupLogicalDevice.Enabled = True;
	Items.Port.Enabled = True;
	Items.BaudRate.Enabled = True;
	Items.Test.Enabled = True;
	Items.MarkingCodeVerificationTimeout.Enabled = True;
	
	FillConnectionTypesList();
	
	If ValueIsFilled(Object.CashRegisterDriver) And 
		(Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver Or 
		Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver8 Or 
		Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZ) Then
		Items.Timeout.Enabled = False;
		Items.Timeout.ToolTip = NStr("ru='(используйте форму настройки параметров ККМ на закладке ""Общий драйвер"" в меню ""Сервис/Параметры"")';
		|de='(verwenden Sie das Formular für die Einstellung der Regisitrierkassenparameter auf der Registerkarte ""Allgemeiner Treiber"" im Menü ""Service/Parameter"")';
		|en='(use cash register driver attributes setting form in the ""Tools/Parameters"" menu)'");
	Else
		Items.Timeout.Enabled = True;
		Items.Timeout.ToolTip = NStr("ru='(оставьте 0 для использования значения по умолчанию)';
		|de='(lassen Sie 0, um den Wert stillschweigend zu benutzen)'
		|en='(leave 0 to use default value)'");
	EndIf;
	If ValueIsFilled(Object.CashRegisterDriver) And 
		(Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver  
		Or Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver8 
		Or Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZ) Then
		Items.DriverProtocol.Enabled = False;
		Items.DriverProtocol.ChoiceButton = False;
		Items.DeviceIDInWebServer.Enabled = False;
		Items.LoginWebServer.Enabled = False;
		Items.PasswordWebServer.Enabled = False;
		Items.CashRegisterModel.Enabled = True;
		Items.CashRegisterModel.ChoiceButton = True;
		Items.CashRegisterModel.ClearButton = True;
	ElsIf ValueIsFilled(Object.CashRegisterDriver) And 
		(Object.CashRegisterDriver = Enums.CashRegisterDrivers.ShtrihMDriverFR  
		Or Object.CashRegisterDriver = Enums.CashRegisterDrivers.ShtrihMDriverFR54FZ) Then
		Items.DriverProtocol.Enabled = True;
		Items.DriverProtocol.ChoiceButton = True;
		Items.DeviceIDInWebServer.Enabled = False;
		Items.LoginWebServer.Enabled = False;
		Items.PasswordWebServer.Enabled = False;
		Items.ConnectionType.Enabled = True;
		Items.FiscalDataFormatVersions.Enabled = True;
		If Object.CashRegisterDriver = Enums.CashRegisterDrivers.ShtrihMDriverFR54FZ Then
			Items.CashRegisterModel.Title = NStr("en = 'Driver type'; de = 'Treibertyp'; ru = 'Тип драйвера'");
			Items.CashRegisterModel.Enabled = True;
			Items.CashRegisterModel.ChoiceButton = True;
			Items.CashRegisterModel.ClearButton = True;
		EndIf;
	ElsIf ValueIsFilled(Object.CashRegisterDriver) And
		Object.CashRegisterDriver = Enums.CashRegisterDrivers.CCSUniversalCashRegisterDriver54FZ Then
		Items.DriverProtocol.Enabled = False;
		Items.DriverProtocol.ChoiceButton = False;
		Items.CashRegisterModel.Enabled = False;
		Items.CashRegisterModel.ChoiceButton = False;
		Items.CashRegisterModel.ClearButton = False;
		Items.Address.Enabled = False;
		Items.Port.Enabled = False;
		Items.BaudRate.Enabled = False;
		Items.Timeout.Enabled = False;
		Items.OFDServer.Enabled = False;
		Items.OFDPort.Enabled = False;
		Items.OFDPollPeriod.Enabled = False;
		Items.DeviceIDInWebServer.Enabled = False;
		Items.LoginWebServer.Enabled = False;
		Items.PasswordWebServer.Enabled = False;
	ElsIf Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZVersion10 Then
		Items.DriverProtocol.Enabled = False;
		Items.DriverProtocol.ChoiceButton = False;
		Items.UseLogicalDevice.Enabled = False;
		Items.LogicalDeviceNumber.Enabled = False;
		Items.Address.Enabled = True;
		Items.CashRegisterModel.Enabled = True;
		Items.CashRegisterModel.ChoiceButton = True;
		Items.CashRegisterModel.ClearButton = True;
		Items.DeviceIDInWebServer.Enabled = False;
		Items.LoginWebServer.Enabled = False;
		Items.PasswordWebServer.Enabled = False;
		Items.FormCheckFDF.Enabled = True;
		Items.FiscalDataFormatVersions.Enabled = True;
	ElsIf Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCashRegisterWebService Then
		Items.DriverProtocol.Enabled = False;
		Items.DriverProtocol.ChoiceButton = False;
		Items.CashRegisterModel.Enabled = False;
		Items.CashRegisterModel.ChoiceButton = False;
		Items.CashRegisterModel.ClearButton = False;
		Items.UseLogicalDevice.Enabled = False;
		Items.LogicalDeviceNumber.Enabled = False;
		Items.BaudRate.Enabled = False;
		Items.Port.Enabled = False;
		Items.VerWebService.Enabled = True;
		Items.Address.Enabled = True;
		Items.CheckVersionWebServer.Enabled = True;
		Items.DeviceIDInWebServer.Enabled = True;
		Items.LoginWebServer.Enabled = True;
		Items.PasswordWebServer.Enabled = True;
		Items.FormCheckFDF.Enabled = True;
		Items.FiscalDataFormatVersions.Enabled = True;
	ElsIf Object.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriverOnline Then
		Items.FormOpenCashDrawer.Enabled = False;
		Items.CashRegisterModel.Enabled = False;
		Items.Timeout.Enabled = False;
		Items.MarkingCodeVerificationTimeout.Enabled = False;
		Items.GroupLogicalDevice.Enabled = False;
		Items.OFDServer.Enabled = False;
		Items.OFDPort.Enabled = False;
		Items.OFDPollPeriod.Enabled = False;
		Items.Port.Enabled = False;
		Items.BaudRate.Enabled = False;
		Items.Test.Enabled = False;
	EndIf;
	If Items.ConnectionType.Enabled
		And Object.ConnectionType = "1" Or Object.ConnectionType = "2"
		Or Object.ConnectionType = "6" Then
		Items.Address.Enabled = True;
	EndIf;
EndProcedure // RefreshDisplay

// -----------------------------------------------------------------------------
&AtClient
Function GetVerWebServer(pConnect, pResourceAddress, rVersion)
	vHTTPRequest = New HTTPRequest();
	vHTTPRequest.ResourceAddress = pResourceAddress;
	vVerWebServer = pConnect.CallHTTPMethod("GET", vHTTPRequest);
	If vVerWebServer.StatusCode = 200 Then
		If rVersion <> Undefined Then
			Try   
				rVersion = "10.7";
				vVerMap = ParseJSON(vVerWebServer.GetBodyAsString());
				If vVerMap <> Undefined And vVerMap["driverVersion"] <> Undefined Then
					vVerArr = StrSplit(vVerMap["driverVersion"], ".", False);
					If vVerArr.Count() > 2 Then
						rVersion = vVerArr[0] + "." + vVerArr[1];	
					EndIf;
				EndIf;
			Except
				rVersion = "10.7";
			EndTry;
		EndIf;
		Return True;
	EndIf;
	Return False; 
EndFunction // GetVerWebServer

// -----------------------------------------------------------------------------
&AtClient
Function ParseJSON(pJSON)
	#If Not WebClient Then
		If Not ValueIsFilled(pJSON) Then
			Return Undefined;
		EndIf;
		
		JSONReader = New JSONReader;
		JSONReader.SetString(pJSON);
		
		Return ReadJSON(JSONReader, True);
	#EndIf       
	Return New Map;
EndFunction // ParseJSON

// -----------------------------------------------------------------------------
&AtClient
Async Procedure ChequeVerificationInternetAddressStartChoiceAsync()
	vValueList = New ValueList;
	vValueList.Add("https://lk.platformaofd.ru/web/noauth/cheque/search?fp=%ChequeFiscalNumber%&fn=%FiscalStorageFactoryNumber%&i=%ChequeSequenceNumber%", NStr("en = 'Platform OFD'; de = 'Plattform SDO'; ru = 'Платформа ОФД'"));
	vValueList.Add("https://receipt.taxcom.ru/v01/show?fp=%ChequeFiscalNumber%&fn=%FiscalStorageFactoryNumber%&fd=%ChequeSequenceNumber%", NStr("en = 'Taxcom OFD'; de = 'Taxcom SDO'; ru = 'Такском ОФД'"));
	vValueList.Add("https://cash.kontur.ru/?fnSerialNumber=%FiscalStorageFactoryNumber%&fiscalDocumentNumber=%ChequeSequenceNumber%&fiscalSignature=%ChequeFiscalNumber%", NStr("en = 'Kontur OFD'; de = 'Kontur SDO'; ru = 'Контур ОФД'"));
	
	vItem = Await ChooseFromMenuAsync(vValueList, Items.ChequeVerificationInternetAddress);
	If vItem = Undefined Then
		Return;
	EndIf;

	Object.ChequeVerificationInternetAddress = vItem.Value;
EndProcedure // ChequeVerificationInternetAddressStartChoiceAsync

#EndRegion
