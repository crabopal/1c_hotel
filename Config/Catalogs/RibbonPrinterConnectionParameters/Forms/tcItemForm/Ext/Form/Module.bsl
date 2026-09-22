
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	RefreshDisplay();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ModelStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If Object.DriverType = PredefinedValue("Enum.RibbonPrinterDrivers.Atol") Then
		vList = GetAtolPrintersList();
	ElsIf Object.DriverType = PredefinedValue("Enum.RibbonPrinterDrivers.Intermec") Then
		vList = GetIntermecPrintersList();
	Else
		vList = New ValueList();
	EndIf;
	vCurModelItem = Undefined;
	Try
		vCurModelItem = vList.FindByValue(Number(TrimAll(Object.Model)));
	Except
	EndTry;
	ShowChooseFromList(New NotifyDescription("ModelAfterUserChoice", ThisObject), vList, pItem, vCurModelItem);
EndProcedure // ModelStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure DriverTypeOnChange(pItem)
	RefreshDisplay();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ModelAfterUserChoice(pListItem, pExtraParams) Export
	If pListItem <> Undefined Then
		Object.Model = pListItem.Value;
	EndIf;
EndProcedure // ModelAfterUserChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure PortStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetAtolPortsList();
	vCurPortItem = Undefined;
	Try
		vCurPortItem = vList.FindByValue(Number(TrimAll(Object.Port)));
	Except
	EndTry;
	ShowChooseFromList(New NotifyDescription("ModelAfterPortChoice", ThisObject), vList, pItem, vCurPortItem);
EndProcedure // PortStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ModelAfterPortChoice(pListItem, pExtraParams) Export
	If pListItem <> Undefined Then
		Object.Port = pListItem.Value;
	EndIf;
EndProcedure // ModelAfterUserChoice

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	If ValueIsFilled(Object.DriverType) Then
		If Object.DriverType = Enums.RibbonPrinterDrivers.Atol Then
			Items.PrinterName.Enabled = False;
			Items.UseLogicalDevice.Enabled = True;
			Items.LogicalDeviceNumber.Enabled = True;
			Items.Port.Enabled = True;
			Items.BaudRate.Enabled = True;
			Items.IPAddress.Enabled = True;
			Items.IPPort.Enabled = True;
			Items.MachineName.Enabled = True;
			Items.FlowControl.Enabled = True;
			Items.ExclusiveAccess.Enabled = True;
			Items.ButtonCheckConnection.Enabled = True;
			If TrimAll(Object.Port) = "99" Or Upper(TrimAll(Object.Port)) = "TCP/IP" Then
				Items.IPAddress.Enabled = True;
				Items.IPPort.Enabled = True;
				Items.BaudRate.Enabled = False;
				Items.MachineName.Enabled = False;
			Else
				Items.IPAddress.Enabled = False;
				Items.IPPort.Enabled = False;
				Items.BaudRate.Enabled = True;
				Items.MachineName.Enabled = True;
			EndIf; 
		Else
			Items.PrinterName.Enabled = True;
			Items.UseLogicalDevice.Enabled = False;
			Items.LogicalDeviceNumber.Enabled = False;
			Items.Port.Enabled = False;
			Items.BaudRate.Enabled = False;
			Items.IPAddress.Enabled = False;
			Items.IPPort.Enabled = False;
			Items.MachineName.Enabled = False;
			Items.FlowControl.Enabled = False;
			Items.ExclusiveAccess.Enabled = False;
			Items.ButtonCheckConnection.Enabled = False;
		EndIf;
		If Object.DriverType = Enums.RibbonPrinterDrivers.SystemPrinter Then
			Items.Model.Enabled = False;
		Else
			Items.Model.Enabled = True;
		EndIf;
	Else
		Items.Model.Enabled = False;
		Items.PrinterName.Enabled = False;
		Items.UseLogicalDevice.Enabled = False;
		Items.LogicalDeviceNumber.Enabled = False;
		Items.Port.Enabled = False;
		Items.BaudRate.Enabled = False;
		Items.IPAddress.Enabled = False;
		Items.IPPort.Enabled = False;
		Items.MachineName.Enabled = False;
		Items.FlowControl.Enabled = False;
		Items.ExclusiveAccess.Enabled = False;
		Items.ButtonCheckConnection.Enabled = False;
	EndIf;
EndProcedure // RefreshDisplay

// -----------------------------------------------------------------------------
&AtClient
Function GetAtolPrintersList()
	vList = New ValueList();
	vList.Add(1, "1 - Star SP2000");
	vList.Add(2, "2 - Star SP298");
	vList.Add(3, "3 - Star TSP600");
	vList.Add(4, "4 - Star TSP700");
	vList.Add(5, "5 - Star TSP800");
	vList.Add(6, "6 - Axiohm 794");
	vList.Add(7, "7 - CBM 1000 II");
	vList.Add(9, "9 - CT-S300");
	vList.Add(10, "10 - CBM 270");
	vList.Add(11, "11 - Posiflex Aura PP7000/PP8000/PP6800");
	vList.Add(12, "12 - Epson TM-T88");
	vList.Add(13, "13 - Posiflex Aura PP5200");
	Return vList;
EndFunction // GetAtolPrintersList

// -----------------------------------------------------------------------------
&AtClient
Function GetIntermecPrintersList()
	vList = New ValueList();
	vList.Add("Intermec EasyCoder 91", "Intermec EasyCoder 91");
	vList.Add("Intermec 201/301/401/501/501 XP/601/601 XP", "Intermec 201/301/401/501/501 XP/601/601 XP");
	vList.Add("Intermec C4/E4/F2/F4", "Intermec C4/E4/F2/F4");
	vList.Add("Intermec PF2i/PF4i/PF4ci/PM4i", "Intermec PF2i/PF4i/PF4ci/PM4i");
	vList.Add("Intermec PD4/PD41/PD42", "Intermec PD4/PD41/PD42");
	vList.Add("Intermec PF8d/t", "Intermec PF8d/t");
	vList.Add("Intermec PX4i/PX6i", "Intermec PX4i/PX6i");
	vList.Add("Intermec 3240/3400/3400e/3440/3600", "Intermec 3240/3400/3400e/3440/3600");
	vList.Add("Intermec 4400/4420/4440/4830", "Intermec 4400/4420/4440/4830");
	vList.Add("Intermec 7421/7422", "Intermec 7421/7422");
	Return vList;
EndFunction // GetIntermecPrintersList

// -----------------------------------------------------------------------------
&AtClient
Function GetAtolPortsList()
	vList = New ValueList();
	vList.Add(1, "1 - COM1");
	vList.Add(2, "2 - COM2");
	vList.Add(3, "3 - COM3");
	vList.Add(4, "4 - COM4");
	vList.Add(5, "5 - COM5");
	vList.Add(6, "6 - COM6");
	vList.Add(7, "7 - COM7");
	vList.Add(8, "8 - COM8");
	vList.Add(9, "9 - COM9");
	vList.Add(10, "10 - COM10");
	vList.Add(11, "11 - COM11");
	vList.Add(12, "12 - COM12");
	vList.Add(13, "13 - COM13");
	vList.Add(14, "14 - COM14");
	vList.Add(15, "15 - COM15");
	vList.Add(16, "16 - COM16");
	vList.Add(17, "17 - COM17");
	vList.Add(18, "18 - COM18");
	vList.Add(19, "19 - COM19");
	vList.Add(20, "20 - COM20");
	vList.Add(21, "21 - COM21");
	vList.Add(22, "22 - COM22");
	vList.Add(23, "23 - COM23");
	vList.Add(24, "24 - COM24");
	vList.Add(25, "25 - COM25");
	vList.Add(26, "26 - COM26");
	vList.Add(27, "27 - COM27");
	vList.Add(28, "28 - COM28");
	vList.Add(29, "29 - COM29");
	vList.Add(30, "30 - COM30");
	vList.Add(31, "31 - COM31");
	vList.Add(32, "32 - COM32");
	vList.Add(33, "33 - LPT1");
	vList.Add(34, "34 - LPT2");
	vList.Add(35, "35 - LPT3");
	vList.Add(36, "36 - LPT4");
	vList.Add(37, "37 - LPT5");
	vList.Add(38, "38 - LPT6");
	vList.Add(39, "39 - LPT7");
	vList.Add(40, "40 - LPT8");
	vList.Add(41, "41 - LPT9");
	vList.Add(42, "42 - LPT10");
	vList.Add(43, "43 - LPT11");
	vList.Add(44, "44 - LPT12");
	vList.Add(45, "45 - LPT13");
	vList.Add(46, "46 - LPT14");
	vList.Add(47, "47 - LPT15");
	vList.Add(48, "48 - LPT16");
	vList.Add(49, "49 - LPT17");
	vList.Add(50, "50 - LPT18");
	vList.Add(51, "51 - LPT19");
	vList.Add(52, "52 - LPT20");
	vList.Add(53, "53 - LPT21");
	vList.Add(54, "54 - LPT22");
	vList.Add(55, "55 - LPT23");
	vList.Add(56, "56 - LPT24");
	vList.Add(57, "57 - LPT25");
	vList.Add(58, "58 - LPT26");
	vList.Add(59, "59 - LPT27");
	vList.Add(60, "60 - LPT28");
	vList.Add(61, "61 - LPT29");
	vList.Add(62, "62 - LPT30");
	vList.Add(63, "63 - LPT31");
	vList.Add(64, "64 - LPT32");
	vList.Add(99, "99 - TCP/IP");
	Return vList;
EndFunction // GetAtolPortsList

#EndRegion    
