
#Region Public

// -----------------------------------------------------------------------------
// Returns type Number(17, 2)
// -----------------------------------------------------------------------------
Function cmGetSumTypeDescriptionOnClient() Export
	vNQ = New NumberQualifiers(17, 2);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetSumTypeDescriptionOnClient

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDevice	 - CatalogRef	 - Ref  device sales
// 
// Returns:
//  CommonModule - Common module
//
Function cmGetModulTO(pDevice) Export
	vDeviceModul = Undefined;
	If TypeOf(pDevice) = Type("Structure") Then
		vDeviceArr = pDevice;
	Else 
		vDeviceArr =  tcOnServer.cmGetAtributeAsArray(pDevice);
	EndIf;
	// Cash registers
	If TypeOf(vDeviceArr.Ref) = Type("CatalogRef.CashRegisters") Then
		If vDeviceArr.CashRegisterDriver = PredefinedValue("Enum.CashRegisterDrivers.AtolCommonCashRegisterDriver8") Then
			// Atol driver
			vDeviceModul = tcCashRegisterDriverAtol8;  
		ElsIf vDeviceArr.CashRegisterDriver = PredefinedValue("Enum.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZ") Then
			// Atol driver
			vDeviceModul = tcCashRegisterDriverAtol54FZ;
		ElsIf  vDeviceArr.CashRegisterDriver = PredefinedValue("Enum.CashRegisterDrivers.AtolCashRegisterWebService") Then
			// Atol driver
			vDeviceModul = tcCashRegisterDriverAtolWebService; 
		ElsIf  vDeviceArr.CashRegisterDriver = PredefinedValue("Enum.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZVersion10") Then
			// Atol driver
			vDeviceModul = tcCashRegisterDriverAtol54FZVersion10;
		ElsIf vDeviceArr.CashRegisterDriver = PredefinedValue("Enum.CashRegisterDrivers.ShtrihMDriverFR") Then
			// ShtrihM driver
			vDeviceModul = tcCashRegisterDriverShtrihM;
		ElsIf vDeviceArr.CashRegisterDriver = PredefinedValue("Enum.CashRegisterDrivers.ShtrihMDriverFR54FZ") Then
			// ShtrihM driver
			vDeviceModul = tcCashRegisterDriverShtrihM54FZ;
		ElsIf vDeviceArr.CashRegisterDriver = PredefinedValue("Enum.CashRegisterDrivers.AtolCommonCashRegisterDriverOnline") Then
			vDeviceModul = tcCashRegisterDriverAtolOnline;
			// Other devices
			// ...
		Else
			vDeviceModul = Undefined; // Unknown devices
		EndIf;
	ElsIf TypeOf(vDeviceArr.Ref) = Type("CatalogRef.CreditCardsProcessingSystemParameters") Then
		// Credit сards processing systems
		If vDeviceArr.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.SberbankSBRFSystemDriver") Then
			// Sberbank
			vDeviceModul = tcCreditCardsProcessingSystemDriverSberbankSBRF;  
		ElsIf vDeviceArr.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.INPASDualConnectorDriver83") Then
			// INPAS
			vDeviceModul = tcCreditCardsProcessingSystemDriverINPASDualConnectorDriver83;
		ElsIf vDeviceArr.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.NativeDriver1C") Then
			// Native Driver 1C
			vDeviceModul = tcCreditCardsProcessingSystemDriverNativeDriver1C;
		ElsIf vDeviceArr.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.TrPosPOSTerminalsDriver") Then
			// TrPosPOST
			vDeviceModul = tcCreditCardsProcessingSystemDriverTrPosPOST; 
		ElsIf vDeviceArr.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.UCSSystemDriver") Then
			// UCS
			vDeviceModul = tcCreditCardsProcessingSystemDriverUCS;
		ElsIf vDeviceArr.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.UCSNativeSystemDriver") Then
			// UCS Native
			vDeviceModul = tcCreditCardsProcessingSystemDriverUCSNative;
		ElsIf vDeviceArr.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.EMVGateCOM1C") Then
			// Gazprombank
			vDeviceModul = tcCreditCardsProcessingSystemDriverGazprombank;
		ElsIf vDeviceArr.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.Arcus2SystemsDriver") Then
			// Arcus2
			vDeviceModul = tcCreditCardsProcessingSystemDriverArcus2;
		ElsIf vDeviceArr.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.SberbankPilotNTSystemDriver") Or
			vDeviceArr.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.SberbankPilotNT33_33SystemDriver") Then
			// Pilot_nt
			vDeviceModul = tcCreditCardsProcessingSystemDriverSberbankPilotNT;
			// Other devices
			// ...
		Else
			vDeviceModul = Undefined; // Unknown devices
		EndIf;
	ElsIf TypeOf(vDeviceArr.Ref) = Type("CatalogRef.DoorLockSystemParameters") Then
		vSystemName = "";
		vModul 		= "";
		// DoorLockSystem
		If vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OnityHT22") Then
			vSystemName = "Onity HT22";
			vModul = tcDoorLockSystemDriverOnity;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OnityHT24") Then
			vSystemName = "Onity HT24";
			vModul = tcDoorLockSystemDriverOnity;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OnityHT28") Then
			vSystemName = "Onity HT28";
			vModul = tcDoorLockSystemDriverOnity;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Orbita4X") Then
			vSystemName = "Orbita 4X";
			vModul = tcDoorLockSystemDriverOrbita4X;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Orbita5X") Then
			vSystemName = "Orbita 5X";
			vModul = tcDoorLockSystemDriverOrbita5X;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OZLocks") Then
			vSystemName = "OZLocks";
			vModul = tcDoorLockSystemDriverOZLocks;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.KabaIlco") Then
			vSystemName = "Kaba Ilco";
			vModul = tcDoorLockSystemDriverKabaIlco;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.KabaSaflok") Then
			vSystemName = "Kaba Saflok";
			vModul = tcDoorLockSystemDriverKabaSaflok;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Locstar") Then
			vSystemName = "Locstar";
			vModul = tcDoorLockSystemDriverLocstar;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.SaltoHotel") Then
			vSystemName = "Salto Hotel";
			vModul = tcDoorLockSystemDriverOnity;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Bonwin") Then 
			vSystemName = "Bonwin";
			vModul = tcDoorLockSystemDriverBonwin;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.BonwinAutonomous") Then 
			vSystemName = "Bonwin Autonomous";
			vModul = tcDoorLockSystemDriverBonwinAutonomous;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.iLocks") Then 
			vSystemName = "iLocks";
			vModul = tcDoorLockSystemDriveriLocks;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Adel") Then 
			vSystemName = "AIS";
			vModul = tcDoorLockSystemDriverAdel;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.VingCardVision") Then 
			vSystemName = "VingCard Vision";
			vModul = tcDoorLockSystemDriverVingCardVision;	
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.VingCardDavinci") Then 
			vSystemName = "VingCard Davinci";
			vModul = tcDoorLockSystemDriverVingCardVision;		
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.AssaAbloyHospitality") Then 
			vSystemName = "Visionline (AssaAbloy)";
			vModul = tcDoorLockSystemDriverAssaAbloy;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.TimeLox2300") Then 
			vSystemName = "TimeLox 2300";
			vModul = tcDoorLockSystemDriverTimeLox;   
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OmniTec") Then 
			vSystemName = "OmniTec";
			vModul = tcDoorLockSystemDriverOmniTec;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.IronLogic") Then 
			vSystemName = "IronLogic";
			vModul = tcDoorLockSystemDriverIronLogic;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.proUSB") Then 
			vSystemName = "proUSB";
			vModul = tcDoorLockSystemDriverProUSB;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.NORWEQMF") Then 
			vSystemName = "NORWEQ MF";
			vModul = tcDoorLockSystemDriverNORWEQMF;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Novilock") Then 
			vSystemName = "Novilock";
			vModul = tcDoorLockSystemDriverNovilock;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.InhovaMagnetic") 
			Or vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.InhovaProximity") Then
			vSystemName = "Inhova";
			vModul = tcDoorLockSystemDriverInhova;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.HSU") Then
			vSystemName = "HSU";
			vModul = tcDoorLockSystemDriverHSU;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.FHBS") Then 
			vSystemName = "FHBS";
			vModul = tcDoorLockSystemDriverNORWEQMF;
		ElsIf vDeviceArr.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Xeeder") Then 
			vSystemName = "Xeeder";
			vModul = tcDoorLockSystemDriverXeeder;
			// Other devices
			// ...
		Else
			vDeviceModul = Undefined; // Unknown devices
		EndIf;
		vDeviceArr.Insert("Modul", vModul);
		vDeviceArr.Insert("SystemName", vSystemName);
		vDeviceModul = vDeviceArr;
	ElsIf TypeOf(vDeviceArr.Ref) = Type("CatalogRef.CustomerDisplayParameters") Then
		If vDeviceArr.CustomerDisplayType = PredefinedValue("Enum.CustomerDisplayDevices.QRScreen") Then
			vDeviceModul = tcCustomerDisplayDriverQRScreen;
			// Other devices
			// 
		Else
			vDeviceModul = Undefined; // Unknown devices
		EndIf;
	Else 
		vDeviceModul = Undefined; // Unknown devices
	EndIf;
	Return vDeviceModul; // Unknown devices
EndFunction // cmGetModulTO

// -----------------------------------------------------------------------------
//
// Parameters:
//  stIdentityCardSystemParameters	 - CatalogRef.IdentityCardsSystemParameters	 - Ref
//  amRC							 - DeviceDriver								 - Var
// 
// Returns:
//  ComObject - Device ComObject
//
Function cmConnectReader(pIdentityCardSystemParameters, amRC) Export
	Try
		// ACC:561-off
		// Create reader object
		If pIdentityCardSystemParameters.CardReaderType = PredefinedValue("Enum.CardReaderTypes.NativeDriver1C") Then
			vHardwareData = tcConnectedHardwareOnServer.GetDataDevices(pIdentityCardSystemParameters.Ref);
			If vHardwareData = Undefined Then
				Raise NStr("en = 'Error getting hardware parameters'; de = 'Fehler beim Abrufen der Hardwareparameter'; ru = 'Ошибка получения параметров оборудования'");
			EndIf;
			
			vResultOperation = tcConnectedHardwareOnClientServer.ConnectHardware(vHardwareData);
			If Not vResultOperation.Result Then
				Raise vResultOperation.ErrorDescription;
			EndIf;
			Return New Structure("ScanData, DeviceEnabled", "", 1);
		ElsIf pIdentityCardSystemParameters.CardReaderType = PredefinedValue("Enum.CardReaderTypes.RS232_1C") Then
			Try
				AttachAddIn("AddIn.Scanner");
				vReaderMC = New("AddIn.Scanner");
			Except
				LoadAddIn("ScanOPOS.dll");
				vReaderMC = New("AddIn.Scanner");
			EndTry;
		Else
			Try
				AttachAddIn("AddIn.Scaner45");
				vReaderMC = New("AddIn.Scaner45");
			Except
				LoadAddIn("Scaner1C.dll");
				vReaderMC = New("AddIn.Scaner45");
			EndTry;
		EndIf;
		// ACC:561-on
		RC_UNKNOWN = 99;
		RC_LOGICAL_DEVICE_NOT_FOUND = -9;
		// Set current logical device number
		vReaderMC.CurrentDeviceNumber = ?(pIdentityCardSystemParameters.LogicalDeviceNumber = 0, 1, pIdentityCardSystemParameters.LogicalDeviceNumber);
		If vReaderMC.ResultCode = RC_LOGICAL_DEVICE_NOT_FOUND Then
			vReaderMC.AddDevice();
			If CheckResult(vReaderMC, amRC) <> 0 Then
				Return Undefined;
			EndIf;  
			// Save logical device number
			tcOnServer.SaveLogicalDeviceNumber(pIdentityCardSystemParameters.Ref,vReaderMC.CurrentDeviceNumber);
		ElsIf CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;
		
		// Do not lock logical devices
		vReaderMC.LockDevices = 0;
		If CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;  
		
		// Set reader connection parameters
		If pIdentityCardSystemParameters.CardReaderType = PredefinedValue("Enum.CardReaderTypes.IronLogicZ2") Then
			vReaderMC.Model = 13;
			Try
				vReaderMC.DataFormat = 3;
			Except
				vReaderMC.Model = 1;
			EndTry;
		Else	
			vReaderMC.Model = 1;
		EndIf;
		If CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;
		// Port
		vPortNumber = 1;
		If Not IsBlankString(pIdentityCardSystemParameters.Port) Then
			vPortNumber = Number(Mid(TrimAll(pIdentityCardSystemParameters.Port), 4));
		EndIf;
		vReaderMC.PortNumber = vPortNumber;
		If CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;
		// Baud rate
		vBaudRate = 7;
		If pIdentityCardSystemParameters.BaudRate > 0 Then
			If pIdentityCardSystemParameters.BaudRate = 1200 Then
				vBaudRate = 3;
			ElsIf pIdentityCardSystemParameters.BaudRate = 2400 Then
				vBaudRate = 4;
			ElsIf pIdentityCardSystemParameters.BaudRate = 4800 Then
				vBaudRate = 5;
			ElsIf pIdentityCardSystemParameters.BaudRate = 9600 Then
				vBaudRate = 7;
			EndIf;
		EndIf;
		vReaderMC.BaudRate = vBaudRate;
		If CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;
		// Data bits
		vDataBits = 4;
		If ValueIsFilled(pIdentityCardSystemParameters.DataBits) Then
			If pIdentityCardSystemParameters.DataBits = PredefinedValue("Enum.DataBits.Bits7") Then
				vDataBits = 3;
			ElsIf pIdentityCardSystemParameters.DataBits = PredefinedValue("Enum.DataBits.Bits8") Then
				vDataBits = 4;
			EndIf;
		EndIf;
		vReaderMC.DataBits = vDataBits;
		If CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;
		// Parity
		vParity = 0;
		If ValueIsFilled(pIdentityCardSystemParameters.Parity) Then
			If pIdentityCardSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Even") Then
				vParity = 2;
			ElsIf pIdentityCardSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Odd") Then
				vParity = 1;
			ElsIf pIdentityCardSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.None") Then
				vParity = 0;
			ElsIf pIdentityCardSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Mark") Then
				vParity = 3;
			ElsIf pIdentityCardSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Space") Then
				vParity = 4;
			EndIf;
		EndIf;
		vReaderMC.Parity = vParity;
		If CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;
		// Stop bits
		vStopBits = 0;
		If ValueIsFilled(pIdentityCardSystemParameters.StopBits) Then
			If pIdentityCardSystemParameters.StopBits = PredefinedValue("Enum.StopBits.Bits1") Then
				vStopBits = 0;
			ElsIf pIdentityCardSystemParameters.StopBits = PredefinedValue("Enum.StopBits.Bits2") Then
				vStopBits = 2;
			EndIf;
		EndIf;
		vReaderMC.StopBits = vStopBits;
		If CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;
		
		// Prefix and suffix
		If pIdentityCardSystemParameters.CardReaderType <> PredefinedValue("Enum.CardReaderTypes.IronLogicZ2") Then
			vReaderMC.Prefix = GetCharsFromCodes(pIdentityCardSystemParameters.Prefix);
			vReaderMC.Suffix = GetCharsFromCodes(pIdentityCardSystemParameters.Suffix);
		EndIf;
		
		// Set reader object properties
		vReaderMC.DataEventEnabled = 1;
		If CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;  
		vReaderMC.OldVersion = 0;
		If CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;  
		vReaderMC.AutoDisable = 1;
		If CheckResult(vReaderMC, amRC) <> 0 Then
			Return Undefined;
		EndIf;  
		// Switch reader on
		If vReaderMC.DeviceEnabled = 0 Then
			vReaderMC.DeviceEnabled = 1;
			If CheckResult(vReaderMC, amRC) <> 0 Then
				Return Undefined;
			EndIf;  
		EndIf;
		// Clear events
		If vReaderMC.DataCount > 0 Then
			vReaderMC.DeleteEvent();
			vReaderMC.DataEventEnabled = 1;
		EndIf;
	Except
		tcOnServer.AddError(amRC, RC_UNKNOWN, NStr("en='Magnetic cards reader connection error: ';ru='Ошибка подключения ридера магнитных карт: ';de='Fehler beim Anschluss des Magnetkartenlesers: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	
	Return vReaderMC;
EndFunction // cmConnectReader

// -----------------------------------------------------------------------------
//
// Parameters:
//  pReaderMC					 - ComObject	 - Device ComObject
//  amRC						 - DeviceDriver								 - Var 
//  amIdentityCardsProcessing	 - CatalogRef.IdentityCardsSystemParameters	 - Ref 
//
Procedure cmDisconnectReader(pReaderMC, amRC, amIdentityCardsProcessing) Export
	Try
		If amIdentityCardsProcessing.CardReaderType = PredefinedValue("Enum.CardReaderTypes.NativeDriver1C") Then
			vHardwareData = tcConnectedHardwareOnServer.GetDataDevices(amIdentityCardsProcessing.Ref);
			If vHardwareData = Undefined Then
				Raise NStr("en = 'Error getting hardware parameters'; de = 'Fehler beim Abrufen der Hardwareparameter'; ru = 'Ошибка получения параметров оборудования'");
			EndIf;
			
			tcConnectedHardwareOnClientServer.DisconnectHardware(vHardwareData, True);
		ElsIf pReaderMC <> Undefined Then
			pReaderMC.CurrentDeviceNumber = ?(amIdentityCardsProcessing.LogicalDeviceNumber = 0, 1, amIdentityCardsProcessing.LogicalDeviceNumber);
			pReaderMC.DeviceEnabled = 0;
		EndIf;
	Except
		tcOnServer.AddError(amRC, 0, StrTemplate(NStr("en = 'Magnetic cards reader disconnect error: %1'; de = 'Fehler bei Abschalten des Magnetkartenlesers: %1'; ru = 'Ошибка отключения ридера магнитных карт: %1'"), ErrorDescription()));
	EndTry;
EndProcedure // cmDisconnectReader

// -----------------------------------------------------------------------------
//
// Parameters:
//  pReaderMC				 - ComObject	 - Device ComObject 
//  pIdentityCardsProcessing - CatalogRef.IdentityCardsSystemParameters	 - Ref
// 
// Returns:
//  String - Card identifier in Track2
//
Function GetTrack2(pReaderMC, pIdentityCardsProcessing) Export
	pReaderMC.CurrentDeviceNumber = ?(pIdentityCardsProcessing.LogicalDeviceNumber = 0, 1, pIdentityCardsProcessing.LogicalDeviceNumber);
	vTrack2 = TrimAll(pReaderMC.Track2);
	If IsBlankString(vTrack2) Then
		vTrack2 = TrimAll(pReaderMC.ScanData);
	EndIf;
	vTrack2 = GetCardIdentifier(vTrack2);
	Return vTrack2;
EndFunction // GetTrack2

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - String	 - Card in Track2
// 
// Returns:
//  Sting - Card identifier
//
Function GetCardIdentifier(pCardData) Export
	vCardID = pCardData;
	If StrLen(pCardData) > 3 Then
		// Remove prefix and suffix chars
		If Right(pCardData, 3) = "+++" Then
			vCardID = Mid(TrimAll(pCardData), 2);
			vCardID = Left(vCardID, StrLen(vCardID) - 3);
		ElsIf Right(pCardData, 2) = "?," Then
			vCardID = Mid(TrimAll(pCardData), 2);
			vCardID = Left(vCardID, StrLen(vCardID) - 2);
		ElsIf CharCode(Left(pCardData, 1)) = 1110 And CharCode(Mid(pCardData, 14, 1)) = 191 Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf CharCode(Left(pCardData, 1)) = 186 And CharCode(Mid(pCardData, 14, 1)) = 191 Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf Left(pCardData, 1) = ";" And Mid(pCardData, 14, 1) = "?" Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf Upper(Right(pCardData, 7)) = "NO CARD" And StrLen(TrimAll(pCardData)) > 7 Then
			vCardID = TrimAll(Left(TrimAll(pCardData), StrLen(TrimAll(pCardData)) - 7));
		EndIf;
	Else
		vCardID = "";
	EndIf;
	Return vCardID;
EndFunction // GetCardIdentifier

// -----------------------------------------------------------------------------
//
// Parameters:
//  pTag	 - String	 - Tag
//  pData	 - String	 - Data
// 
// Returns:
//  String - TLV Format string
//
Function cmBuildTLVFormatString(pTag, pData) Export
	Return cmDec2HexLE(pTag) + cmDec2HexLE(StrLen(pData)) + pData;
EndFunction // cmBuildTLVFormatString

// -----------------------------------------------------------------------------
//  Description: Returns hex left ended string representing positive decimal number
//
// Parameters:
//  pDec - Number	 - Decimal number
// 
// Returns:
//  String - Hex number presentation as string
//
Function cmDec2HexLE(pDec) Export
	vBase = "123456789ABCDEF";
	vHexLE = "";
	vDiv = pDec;
	While vDiv > 0 Do
		vIntDiv = Int(vDiv / 16);
		vHexChar = "0";
		If vDiv <> vIntDiv * 16 Then
			vHexChar = Mid(vBase, (vDiv - vIntDiv * 16), 1);
		EndIf;
		vHexLE = vHexChar + vHexLE;
		vDiv = vIntDiv;
	EndDo;
	While StrLen(vHexLE) < 4 Do
		vHexLE = "0" + vHexLE;
	EndDo;
	vHexLE = Right(vHexLE, 2) + Left(vHexLE, 2);
	vHexLEStr = Char(cmHexChar2Dec(Mid(vHexLE, 1, 1)) * 16 + cmHexChar2Dec(Mid(vHexLE, 2, 1)));
	vHexLEStr = vHexLEStr + Char(cmHexChar2Dec(Mid(vHexLE, 3, 1)) * 16 + cmHexChar2Dec(Mid(vHexLE, 4, 1)));
	Return vHexLEStr;
EndFunction // cmDec2HexLE

// -----------------------------------------------------------------------------
//  Description: Returns decimal number of the hex char
//
// Parameters:
//  pHexChar - String	 - Hex char as string
// 
// Returns:
//  Number - Decimal number presentation as number
//
Function cmHexChar2Dec(pHexChar) Export  
	vNumberHexChar = 0;
	If pHexChar = "0" Then
		vNumberHexChar = 0;
	ElsIf pHexChar = "1" Then
		vNumberHexChar = 1;
	ElsIf pHexChar = "2" Then
		vNumberHexChar = 2;
	ElsIf pHexChar = "3" Then
		vNumberHexChar = 3;
	ElsIf pHexChar = "4" Then
		vNumberHexChar = 4;
	ElsIf pHexChar = "5" Then
		vNumberHexChar = 5;
	ElsIf pHexChar = "6" Then
		vNumberHexChar = 6;
	ElsIf pHexChar = "7" Then
		vNumberHexChar = 7;
	ElsIf pHexChar = "8" Then
		vNumberHexChar = 8;
	ElsIf pHexChar = "9" Then
		vNumberHexChar = 9;
	ElsIf Upper(pHexChar) = "A" Then
		vNumberHexChar = 10;
	ElsIf Upper(pHexChar) = "B" Then
		vNumberHexChar = 11;
	ElsIf Upper(pHexChar) = "C" Then
		vNumberHexChar = 12;
	ElsIf Upper(pHexChar) = "D" Then
		vNumberHexChar = 13;
	ElsIf Upper(pHexChar) = "E" Then
		vNumberHexChar = 14;
	ElsIf Upper(pHexChar) = "F" Then
		vNumberHexChar = 15; 
	Else
		vNumberHexChar = 0;
	EndIf;                 
	Return vNumberHexChar;
EndFunction // cmHexChar2Dec

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDayOfWeek	 - Number - Day Of Week
//  pShort		 - Boolean	 - 
// 
// Returns:
//  String - Description of the day of the week
//
Function cmGetDayOfWeekNameOnClient(pDayOfWeek, pShort = True) Export  
	vDayPres = "";
	If pDayOfWeek = 1 Then
		If pShort Then
			vDayPres = NStr("en = 'mo'; de = 'Mo'; ru = 'пн'");
		Else
			vDayPres = NStr("en = 'Monday'; de = 'Montag'; ru = 'Понедельник'");
		EndIf;
	ElsIf pDayOfWeek = 2 Then
		If pShort Then
			vDayPres = NStr("en = 'tu'; de = 'Di'; ru = 'вт'");
		Else
			vDayPres = NStr("en = 'Tuesday'; de = 'Dienstag'; ru = 'Вторник'");
		EndIf;
	ElsIf pDayOfWeek = 3 Then
		If pShort Then
			vDayPres = NStr("en = 'we'; de = 'Mi'; ru = 'ср'");
		Else
			vDayPres = NStr("en='Wednesday';ru='Среда';de='Mittwoch'");
		EndIf;
	ElsIf pDayOfWeek = 4 Then
		If pShort Then
			vDayPres = NStr("en = 'th'; de = 'Do'; ru = 'чт'");
		Else
			vDayPres = NStr("en = 'Thursday'; de = 'Donnerstag'; ru = 'Четверг'");
		EndIf;
	ElsIf pDayOfWeek = 5 Then
		If pShort Then
			vDayPres = NStr("en = 'fr'; de = 'Fr'; ru = 'пт'");
		Else
			vDayPres = NStr("en = 'Friday'; de = 'Freitag'; ru = 'Пятница'");
		EndIf;
	ElsIf pDayOfWeek = 6 Then
		If pShort Then
			vDayPres = NStr("en = 'sa'; de = 'Sa'; ru = 'сб'");
		Else
			vDayPres = NStr("en = 'Saturday'; de = 'Samstag'; ru = 'Суббота'");
		EndIf;
	ElsIf pDayOfWeek = 7 Then
		If pShort Then
			vDayPres = NStr("en = 'su'; de = 'So'; ru = 'вс'");
		Else
			vDayPres = NStr("en = 'Sunday'; de = 'Sonntag'; ru = 'Воскресенье'");
		EndIf;  
	Else
		vDayPres = "";	
	EndIf;   
	Return vDayPres;
EndFunction // cmGetDayOfWeekNameOnClient

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueList - ResortFeeExemptionReasonsList
//
Function cmGetResortFeeExemptionReasonsList() Export
	vList = tcOnServer.GetResortFeeExemptionReasonsList();	
	Return vList;
EndFunction // cmGetResortFeeExemptionReasonsList

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueList - TouristTaxExemptionReasonsList
//
Function cmGetTouristTaxExemptionReasonsList() Export
	vList = tcOnServer.GetTouristTaxExemptionReasonsList();	
	Return vList;
EndFunction // cmGetTouristTaxExemptionReasonsList

// -----------------------------------------------------------------------------
//
// Parameters:
//  rDirectoryName	 - String	 - DirectoryName
//  rForm			 - ClientApplicationForm - Form
//  rNotify			 - NotifyDescription - NotifyDescription (Array, AdditionalParameters)
//
Procedure cmGetChooseDirectory(rDirectoryName, rForm, rNotify) Export 
	vFileDialog 			= New FileDialog(FileDialogMode.ChooseDirectory);
	vFileDialog.Multiselect = False;
	vFileDialog.Directory	= rDirectoryName;
	vFileDialog.Show(New NotifyDescription(rNotify, rForm));
EndProcedure	

// -----------------------------------------------------------------------------
//  Check it's main form
//
// Parameters:
//  pForm	 - ClientApplicationForm	 - Form check
// 
// Returns:
//  Boolean - True or false
//
Function IsHomePageWindow(pForm) Export 
	vIsMain = False;
	vWindows = GetWindows();
	If vWindows <> Undefined Then
		If vWindows.Count() = 1 Then
			Return True;
		EndIf;
		For Each vWindow In vWindows Do
			If vWindow.HomePage Then
				If vWindow.Content.Count() > 0 Then
					If Not vWindow.Content.Find(pForm) = Undefined Then
						vIsMain = True;
						Break;
					EndIf;	
				EndIf;	
			EndIf;
		EndDo;
	EndIf;
	Return vIsMain;	
EndFunction // IsHomePageWindow

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
//
Procedure ChangeApplicationCaption(pHotel) Export
	// Build caption
	vCaption = tcOnServer.GetMainFormCaption(pHotel);
	// Demo mode 
	vIsDemoMode = tcOnServer.cmGetSessionParametersAttribute("IsDemoMode");
	If vIsDemoMode Then
		vDemoMode = NStr("en='DEMO MODE - %1';ru='ДЕМО-РЕЖИМ - %1';de='DEMO-Modus - %1'");
		vCaption = StrTemplate(vDemoMode, vCaption);  
	EndIf;  
	// Set caption
	#If ThickClientOrdinaryApplication Then
		SetCaption(vCaption);
	#Else 
		ClientApplication.SetShortCaption(vCaption);
	#EndIf
EndProcedure // ChangeApplicationCaption

// -----------------------------------------------------------------------------
// 
// Returns:
//  Form - HomePageWindow
//
Function GetHomePageWindow() Export
	For Each vWnd In GetWindows() Do
		If vWnd.HomePage Then
			Return vWnd;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction // GetHomePageWindow

// -----------------------------------------------------------------------------
//
// Parameters:
//  pForm	 - ClientApplicationForm - Form
// 
// Returns:
//  ClientApplicationForm - Parent form
//
Function GetParentForm(pForm) Export
	vForm = Undefined;  
	vFormType = Type("ClientApplicationForm");
	If pForm <> Undefined Then
		If TypeOf(pForm) = vFormType Then
			vForm = pForm;
		Else
			vParent = pForm.Parent;
			If TypeOf(vParent) = vFormType Then
				vForm = vParent;
			Else
				While vParent <> Undefined And TypeOf(vParent) <> vFormType Do
					vParent = vParent.Parent;
					If vParent <> Undefined And TypeOf(vParent) = vFormType Then
						vForm = vParent;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	Return vForm;
EndFunction // GetParentForm

// -----------------------------------------------------------------------------
//
// Parameters:
//  pFileType	 - FileType		 - FileType
//  pFilePath	 - String		 - FilePath
//  pSpreadsheet - Spreadsheet	 - Spreadsheet
//
Procedure SaveSpreadsheetToFile(pFileType, pFilePath, pSpreadsheet, pCheckFileSystemExtensionConnection = True) Export
	#If WebClient Then
		If pCheckFileSystemExtensionConnection Then
			vParams = New Structure("FileType, FilePath, Spreadsheet, Installed", pFileType, pFilePath, pSpreadsheet, False);
			BeginAttachingFileSystemExtension(New NotifyDescription("AfterAttachingFileSystemExtension", tcOnClient, vParams));
			Return;
		EndIf;
	#EndIf
	
	vFileDlg = New FileDialog(FileDialogMode.Save);
	vFileDlg.FullFileName = pFilePath;
	vFileDlg.Multiselect = False;
	vFileDlg.Preview = False;
	vFileDlg.Title = NStr("en='Save to file';ru='Сохранить в файл';de='in Datei speichern'");
	If pFileType = SpreadsheetDocumentFileType.MXL Then
		vFileDlg.DefaultExt = "mxl";
		vFileDlg.Filter = NStr("en='1C spreadsheet format (*.mxl)|*.mxl';ru='Формат таблицы 1C (*.mxl)|*.mxl';de='Format der Tabelle 1C (*.mxl)|*.mxl'");
	ElsIf pFileType = SpreadsheetDocumentFileType.XLSX Then
		vFileDlg.DefaultExt = "xlsx";
		vFileDlg.Filter = NStr("en='Microsoft Excel format (*.xlsx)|*.xlsx';ru='Формат Microsoft Excel (*.xlsx)|*.xlsx';de='Format Microsoft Excel (*.xlsx)|*.xlsx'");
	ElsIf pFileType = SpreadsheetDocumentFileType.HTML Then
		vFileDlg.DefaultExt = "html";
		vFileDlg.Filter = NStr("en='HTML format (*.html)|*.html';ru='Формат HTML (*.html)|*.html';de='Format HTML (*.html)|*.html'");
	ElsIf pFileType = SpreadsheetDocumentFileType.PDF Then
		vFileDlg.DefaultExt = "pdf";
		vFileDlg.Filter = NStr("en='Adobe Reader PDF format (*.pdf)|*.pdf';ru='Формат Adobe Reader PDF (*.pdf)|*.pdf';de='Format Adobe Reader PDF (*.pdf)|*.pdf'");
	ElsIf pFileType = SpreadsheetDocumentFileType.DOCX Then
		vFileDlg.DefaultExt = "docx";
		vFileDlg.Filter = NStr("en='Microsoft Word format (*.docx)|*.docx';ru='Формат Microsoft Word (*.docx)|*.docx';de='Format Microsoft Word (*.docx)|*.docx'");
	Else
		Return;
	EndIf;
	vNotifity = New NotifyDescription("SelectFileEnd", tcOnClient, New Structure("FileType, Spreadsheet", pFileType, pSpreadsheet));
	vFileDlg.Show(vNotifity);
EndProcedure // SaveSpreadsheetToFile

// -----------------------------------------------------------------------------
Procedure SelectFileEnd(pSelectedItem, pAdditionalParameters) Export
	If Not pSelectedItem = Undefined Then
		pAdditionalParameters.Spreadsheet.BeginWriting(New NotifyDescription, pSelectedItem.Get(0), pAdditionalParameters.FileType);	
	EndIf;
EndProcedure // SelectFileEnd

// -----------------------------------------------------------------------------
//  Description: Extends period of stay of all hotel in-house guests to the next
//  hour from current time. I.e. if current time is 15:23 then period
//  of stay will be extended to 16:00
//
// Parameters:
//  pHotel				 - CatalogRef.Hotels - Ref
//  pFreeOfChargeMinutes - Number			 - FreeOfChargeMinutes
// 
// Returns:
//  Structure - params
//  * Message
//  * vListStatus
//
Function ExtendInHouseGuestsPeriodOfStay(Val pHotel = Undefined, Val pFreeOfChargeMinutes = 0) Export
	// Fill hotel
	If pHotel = Undefined Then
		pHotel = tcOnServer.cmGetSessionParametersAttribute("CurrentHotel");
		If Not ValueIsFilled(pHotel) Then
			Return "";
		EndIf;
	EndIf;
	// Fill target check-out time 
	vCheckOutDate = CurrentDate();
	// Check free of charge minutes
	If pFreeOfChargeMinutes = 0 Then
		pFreeOfChargeMinutes = 20;
		vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		If ValueIsFilled(vCurrentUser) Then
			vPermissionGroup = tcOnServer.cmGetEmployeePermissionGroupAtServer(vCurrentUser);
			If ValueIsFilled(vPermissionGroup) Then
				vAllowedCheckOutDelayTime = tcOnServer.cmGetAttributeByRef(vPermissionGroup, "AllowedCheckOutDelayTime");
				vRoomExaminationFreeOfChargeTime = tcOnServer.cmGetAttributeByRef(vPermissionGroup, "RoomExaminationFreeOfChargeTime");
				If vAllowedCheckOutDelayTime > 0 And vAllowedCheckOutDelayTime < 1 Then
					pFreeOfChargeMinutes = Round(vAllowedCheckOutDelayTime * 60, 0);
				ElsIf vRoomExaminationFreeOfChargeTime <> 0 Then
					pFreeOfChargeMinutes = Round(vRoomExaminationFreeOfChargeTime * 60, 0);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Build list of accommodations to process
	vMessage = tcOnServer.DoAutoPeriodExtension(pHotel, vCheckOutDate, pFreeOfChargeMinutes);
	// Build list of accommodations to checking out
	vAccDocs = tcOnServer.GetListOfAccommodationsToCheckOut(pHotel, vCheckOutDate, pFreeOfChargeMinutes);
	vListStatus = False;
	If vAccDocs.Count() > 0 Then
		OpenForm("CommonForm.tcGuestsReadyToBeCheckedOut", New Structure("AccommodationsForCheckout", vAccDocs), , "tcGuestsReadyToBeCheckedOut", , , , FormWindowOpeningMode.LockWholeInterface);
	Else
		vListStatus = True;	
	EndIf;
	// Return message
	Return New Structure("Message, ListStatus", vMessage, vListStatus);
EndFunction // ExtendInHouseGuestsPeriodOfStay

// -----------------------------------------------------------------------------
//
Procedure DoInfoBaseUpdate() Export
	// Is first run
	If Not tcInfobaseUpdate.cmIsFirstRun() And Not tcInfobaseUpdate.cmIsRelevantVersion() Then
		// Check user rights for info base update
		If Not tcOnServer.cmIsInRole("Administrator") Then
			vMsg = NStr("en='You do not have enough rights to do info base update! Program will be closed.';
			|ru='Недостаточно прав для выполнения обновления! Работа программы будет завершена.';
			|de='Nicht ausreichend Rechte für die Durchführung einer Aktualisierung! Das Programm wird geschlossen.'");
			vParams = New Structure("MessageText, ButtonExit, TimeToClose", vMsg, True, 5);
			OpenForm("DataProcessor.InfoBaseUpdate.Form.tcErrorForm", vParams);
			Return;
		EndIf;	
		// Confirmation request
		OpenForm("DataProcessor.InfoBaseUpdate.Form.tcForm", , , , , , New NotifyDescription("ContinueInfobaseUpdate", tcOnClient)); 
	Else
		// Set current version
		tcInfobaseUpdate.cmUpdateInfobaseVersion();
	EndIf;
EndProcedure // DoInfoBaseUpdate

// -----------------------------------------------------------------------------
Procedure ContinueInfobaseUpdate(pResult, pParams) Export
	If pResult <> True Then
		Exit(False);
		Return;
	EndIf;	
	
	If Not tcInfobaseUpdate.IsRelevantVersionWithoutAssembly() Then
		vForm = "DataProcessor.InfoBaseUpdate.Form.tcErrorForm";
		
		// Show message
		vMsg = NStr("en = 'The infobase is being updated!'; de = 'Die Informationsbasis wird aktualisiert!'; ru = 'Выполняется обновление информационной базы!'");
		vParams = New Structure("MessageText, DoProcessing", vMsg, True);
		OpenForm(vForm, vParams);
		
		// Do info base update  
		vResult = tcInfobaseUpdate.cmRunUpdate();  
		
		// Close message window
		Notify("InfoBaseUpdate.Done");
		
		If Not vResult Then   
			vMsg = NStr("en='Errors were found while updating info base! Check system log.';
			|ru='В процессе обновления информационной базы были ошибки! Проверьте журнал регистрации.';
			|de='Fehler bei der Aktualisierung der Informationsbasis! Prüfen Sie die Protokolldatei.'");
			vParams = New Structure("MessageText, ButtonContinue", vMsg, True);
			OpenForm(vForm, vParams);  
		EndIf;
		
		// Check info base update status
		If Not tcInfobaseUpdate.cmIsRelevantVersion() Then
			vMsg = NStr("en='Info base update was not done! Continue to run?';
			|ru='Не выполнено обновление информационной базы! Продолжить работу программы?';
			|de='Die Aktualisierung der Informationsbasis wurde nicht durchgeführt! Die Arbeit des Programms fortsetzen?'");
			vParams = New Structure("MessageText, ButtonContinue, ButtonExit", vMsg, True, True);
			OpenForm(vForm, vParams);
		EndIf;   
		// Show progress update
		OpenForm("DataProcessor.InfoBaseUpdate.Form.tcDescriptionUpdate");
	Else
		// Set current version
		tcInfobaseUpdate.cmUpdateInfobaseVersion();
	EndIf;
EndProcedure // ContinueInfobaseUpdate

// -----------------------------------------------------------------------------
//  Description: Builds report form save to file default name based on print form settings
//
// Parameters:
//  pPrintSettings	 - Structure - Structure with print form settings
//  pFileName		 - String	 - Default file name
// 
// Returns:
//  String - Print form save to file name
//
Function GetPrintFormFileNameAtClient(pPrintSettings, pFileName = "") Export
	vFileName = pFileName;
	If pPrintSettings <> Undefined Then
		vFileName = ?(IsBlankString(pPrintSettings.FileName), pFileName, tcOnServer.cmNStrAtServer(pPrintSettings.FileName));
		If pPrintSettings.AddTimeToTheFileName Then
			vFileName = vFileName + " " + Format(CurrentDate(), "DF='yyyy-MM-dd HHmm'");
		EndIf;
	EndIf;
	Return vFileName;
EndFunction // GetPrintFormFileNameAtClient

// -----------------------------------------------------------------------------
//  Description: Asks question if user want to change room price
//  -----------------------------------------------------------------------------
//
// Parameters:
//  pRoom	 - CatalogRef.Rooms	 - Ref
//  pObject	 - DocumentRef	 - Accommodation or Reservation
//
Procedure AskRoomChangeQuestion(pRoom, pObject) Export
	If ValueIsFilled(pRoom) And ValueIsFilled(pObject.RoomType) And Not ValueIsFilled(pObject.RoomTypeUpgrade) Then
		vCurRoomType = tcOnServer.GetRoomRoomType(pRoom, pObject.CheckInDate);
		If ValueIsFilled(vCurRoomType) And vCurRoomType <> pObject.RoomType Then
			vQryText = NStr("en = 'Do you want to save reservation price by the room type '; 
			                |de = 'Möchten Sie reservationspreis durch den Zimmertyp sparen '; 
			                |ru = 'Хотите сохранить цену за проживание по типу номера '") + TrimAll(pObject.RoomType) + "?" + Chars.LF + 
			           NStr("en = 'If you answer <No> then reservation price will be recalculated by the new room type '; 
			                |de = 'Wenn Sie <Nein> Antworten, wird der Reservierungspreis durch den neuen Zimmertyp neu berechnet '; 
			                |ru = 'Если ответите <Нет>, то стоимость бронирования будет пересчитана по новому типу номера '") + TrimAll(vCurRoomType);
			ShowQueryBox(New NotifyDescription("AskRoomChangeQuestionAnswer", tcOnClient, New Structure("Object, RoomType", pObject, pObject.RoomType)), vQryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
	EndIf;
EndProcedure // AskRoomChangeQuestion

// -----------------------------------------------------------------------------
//
Procedure AskRoomChangeQuestionAnswer(pAnswer, pParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		pParams.Object.RoomTypeUpgrade = pParams.RoomType;
		Notify("Reservation.RoomTypeUpgradeWasChanged", pParams.Object.Ref);
	EndIf;
EndProcedure // AskRoomChangeQuestionAnswer

// -----------------------------------------------------------------------------
//
// Parameters:
//  pStr - String	 - Any string
// 
// Returns:
//  String - NonASCIIChars
//
Function RemoveNonASCIIChars(Val pStr) Export
	vStr = pStr;
	vInd = 1;
	While vInd <= StrLen(vStr) Do
		vChar = Mid(vStr, vInd, 1);
		vCharCode = CharCode(vChar);
		If vCharCode < 32 Or vCharCode > 127 Then
			vStr = Left(vStr, vInd - 1) + Mid(vStr, vInd + 1);
		Else
			vInd = vInd + 1;
		EndIf;
	EndDo;
	Return vStr;
EndFunction // RemoveNonASCIIChars

#EndRegion

#Region Private

// ------------------------------------------------------------------------------
//
// Parameters:
//  pReaderMC	 - ComObject - com driver
//  amRC		 - Structure - Params
// 
// Returns:
//  Number - ResultCode
//
Function CheckResult(pReaderMC, amRC)
	vResultCode = pReaderMC.ResultCode;
	vResultDescription = pReaderMC.ResultDescription;
	If vResultCode <> 0 Then
		tcOnServer.AddError(amRC, vResultCode, NStr("en = 'Error using magnetic cards reader! Error code: '; 
		|de = 'Fehler bei der Arbeit mit dem Magnetkartenleser! Fehlercode: '; 
		|ru = 'Ошибка работы с ридером магнитных карт! Код ошибки: '") + TrimAll(vResultCode) 
		+ NStr("en = ' Error description: '; de = ' Fehlerbeschreibung: '; ru = ' Описание ошибки: '") + TrimAll(vResultDescription));
	EndIf;
	Return vResultCode;
EndFunction // CheckResult

// ------------------------------------------------------------------------------
//
// Parameters:
//  pStr - String	 - Any string
// 
// Returns:
//  String - cleared string
//
Function GetCharsFromCodes(pStr) 
	vStr = "";
	If IsBlankString(pStr) Then
		Return vStr;
	EndIf;
	vPos = StrFind(pStr, "#");
	If vPos > 0 Then
		vStrCodes = TrimAll(Mid(pStr, vPos + 1));
		While vPos > 0 Do
			vPos = StrFind(vStrCodes, "#");
			If vPos = 0 Then
				vStr = vStr + Char(Number(vStrCodes));
			Else
				vStr = vStr + Char(Number(Left(vStrCodes, vPos - 1)));
				vStrCodes = TrimAll(Mid(vStrCodes, vPos + 1));
			EndIf;
		EndDo;
	Else
		vStr = TrimR(pStr);
	EndIf;
	Return vStr;
EndFunction // GetCharsFromCodes

// --------------------------------------------------------------------------------
Procedure AfterAttachingFileSystemExtension(pResult, pExtraParams) Export
	If pResult Then
		SaveSpreadsheetToFile(pExtraParams.FileType, pExtraParams.FilePath, pExtraParams.Spreadsheet, False);
		Return;
	EndIf;
	
	If pExtraParams.Property("Installed") And pExtraParams.Installed Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
		Return;
	EndIf;
	
	BeginInstallFileSystemExtension(New NotifyDescription("AfterInstallingFileSystemExtension", tcOnClient, pExtraParams));
EndProcedure // AfterAttachingFileSystemExtension

// --------------------------------------------------------------------------------
Procedure AfterInstallingFileSystemExtension(pExtraParams) Export
	pExtraParams.Insert("Installed", True);
	BeginAttachingFileSystemExtension(New NotifyDescription("AfterAttachingFileSystemExtension", tcOnClient, pExtraParams));
EndProcedure // AfterAttachingFileSystemExtension

#EndRegion
