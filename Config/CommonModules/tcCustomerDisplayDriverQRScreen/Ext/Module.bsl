#Region WorkingWithRS232

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString(pCashAcceptorSystemParameters)
	vStr = ""; // "4800,N,8,1" by default
	// Baudrate
	If pCashAcceptorSystemParameters.BaudRate > 0 Then
		vStr = vStr + Format(pCashAcceptorSystemParameters.BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "4800";
	EndIf;
	// Parity
	If ValueIsFilled(pCashAcceptorSystemParameters.Parity) Then
		If pCashAcceptorSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Even") Then
			vStr = vStr + ",E";
		ElsIf pCashAcceptorSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Odd") Then
			vStr = vStr + ",O";
		ElsIf pCashAcceptorSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.None") Then
			vStr = vStr + ",N";
		ElsIf pCashAcceptorSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Mark") Then
			vStr = vStr + ",M";
		ElsIf pCashAcceptorSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Space") Then
			vStr = vStr + ",S";
		EndIf;
	Else
		vStr = vStr + ",E";
	EndIf;
	// Data length
	If ValueIsFilled(pCashAcceptorSystemParameters.DataBits) Then
		If pCashAcceptorSystemParameters.DataBits = PredefinedValue("Enum.DataBits.Bits8") Then
			vStr = vStr + ",8";
		ElsIf pCashAcceptorSystemParameters.DataBits = PredefinedValue("Enum.DataBits.Bits7") Then
			vStr = vStr + ",7";
		EndIf;
	Else
		vStr = vStr + ",7";
	EndIf;
	// Stop bits
	If ValueIsFilled(pCashAcceptorSystemParameters.StopBits) Then
		If pCashAcceptorSystemParameters.StopBits = PredefinedValue("Enum.StopBits.Bits1") Then
			vStr = vStr + ",1";
		ElsIf pCashAcceptorSystemParameters.StopBits = PredefinedValue("Enum.StopBits.Bits2") Then
			vStr = vStr + ",2";
		EndIf;
	Else
		vStr = vStr + ",1";
	EndIf;
	Return vStr;		
EndFunction // GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function Connect(pDevice, rMessage)
	vDLSys = Undefined;
	#IF NOT MobileClient THEN
		Try
			If Not ValueIsFilled(pDevice) Then
				Return Undefined;
			EndIf;
			
			// Build ActiveX object to work with
			vDLSys = New COMObject("SPort.SPortAx.1");
			// Set connection parameters
			vDLSys.InitString(GetCOMPortConnectionString(pDevice));
			// Open COM port
			vIsOpen = vDLSys.Open(TrimAll(pDevice.Port));
			If Not vIsOpen Then
				rMessage = NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden:'") + TrimAll(pDevice.Port);
				AddError(rMessage);
				Return Undefined;
			EndIf;
			vDLSys.BlockMode = True; 
			vDLSys.TimeoutReadInterval = pDevice.TimeoutReadInterval;
			vDLSys.TimeoutReadTotalConstant = pDevice.TimeoutReadTotalConstant;
			vDLSys.TimeoutReadTotalMultiplier = pDevice.TimeoutReadTotalMultiplier;
			vDLSys.TimeoutWriteTotalConstant = pDevice.TimeoutWriteTotalConstant;
			vDLSys.TimeoutWriteTotalMultiplier = pDevice.TimeoutWriteTotalMultiplier;
		Except
			rMessage = NStr("ru = 'Ошибка подключения " + pDevice.Description + ": '; 
			|en = '" + pDevice.Description + " connection error: ';
			|de = '" + pDevice.Description + " connection error: '") + ErrorDescription(); 
			AddError(rMessage);
			Return Undefined;
		EndTry;
	#ENDIF
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure Disconnect(pDLSys, pSystemName)
	Try
		pDLSys.Close();  
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + pSystemName + ": '; 
		              |de = '" + pSystemName + " system disconnect error: '; 
		              |en = '" + pSystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function CheckResult(pResult, pCommandCode, pSystemName, rMessage)
	vResult = StrReplace(StrReplace(StrReplace(pResult, "[" + pCommandCode + "]", ""), Chars.CR, ""), Chars.LF, ""); 
	If vResult <> "OK" Then
		If ValueIsFilled(vResult) Then 
			rMessage = vResult;
		Else
			rMessage = pSystemName + NStr("en = ' not responding';
										  |de = ' reagiert nicht';
										  |ru = ' не отвечает'");		
		EndIf;
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // CheckResult

// -----------------------------------------------------------------------------
Function CallRS232Command(pDevice, pData, rMessage)	
	If TypeOf(pDevice) = Type("CatalogRef.CustomerDisplayParameters") Then 
		vDevice = tcOnServer.cmGetAtributeAsArray(pDevice);
	Else
		vDevice = pDevice; 	
	EndIf;
	vDLSys = Connect(vDevice, rMessage); 
	If vDLSys = Undefined Then
		Return False;
	EndIf;
	vResult = True; 
	For Each vCommand In pData Do 
		vDLSys.PurgeQueue();
		vBuff = GetBinaryDataBufferFromString("[" + vCommand.Key + "]" + TrimAll(vCommand.Value) + Chars.CR + Chars.LF, TextEncoding.UTF8, False);
		For Each vBite In vBuff Do
			If vDLSys.Write(vBite, 1) <> 1 Then
				rMessage = NStr("en = 'Command sending error'; de = 'Fehler beim Senden des Befehls'; ru = 'Ошибка отправки команды'");	
				Return False;
			EndIF;
		EndDo;
		For i = 0 To 3 Do
			vResponse = vDLSys.ReadStr();
			If ValueIsFilled(vResponse) Then
				Break;	
			EndIf;
		EndDo;
		If Not CheckResult(vResponse, vCommand.Key, vDevice.Description, rMessage) Then
			vResult = False;
			If vCommand.Key <> "CQL" Then  
				vDLSys.WriteStr("[CQL]" + Chars.CR + Chars.LF);
			EndIf;
			Break;
		EndIf;
	EndDo; 
	Disconnect(vDLSys, vDevice.Description);
	Return vResult;
EndFunction // CallRS232Command

#EndRegion

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='CustomerDisplayDriver.Error';ru='ДрайверДисплеяПокупателя.Ошибка';de='CustomerDisplayDriver.Error'"),"Warning",,,pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmShowQRCode(pDevice, pDataStructure, rMessage) Export
	Return CallRS232Command(pDevice, New Structure("Q, T1, T2", pDataStructure.QRCode, ?(pDataStructure.Property("Header"), pDataStructure.Header, ""), ?(pDataStructure.Property("Footer"), pDataStructure.Footer, "")), rMessage);
EndFunction // pmShowQRCode

// -----------------------------------------------------------------------------
Function pmClearQRCode(pDevice, rMessage) Export
	Return CallRS232Command(pDevice, New Structure("CQL, T1, T2"), rMessage);
EndFunction // pmClearQRCode