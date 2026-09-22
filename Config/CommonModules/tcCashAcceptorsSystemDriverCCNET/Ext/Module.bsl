
#Region Public

// -----------------------------------------------------------------------------
Function pmReset(pDevice) Export
	pAnswerByteArr = Undefined;
	If Not CallRS232Command(pDevice, "0030", Undefined, pAnswerByteArr) Then
		Return False;	
	EndIf;
	If pAnswerByteArr[0] = "00FF" Then
		Return False;	
	EndIf;
	Return True;
EndFunction // pmReset

// -----------------------------------------------------------------------------
Function pmReturn(pDevice) Export
	pAnswerByteArr = Undefined;
	If Not CallRS232Command(pDevice, "0036", Undefined, pAnswerByteArr) Then
		Return False;	
	EndIf;
	Return True;
EndFunction // pmReturn

// -----------------------------------------------------------------------------
Function pmGetStatus(pDevice, rNominal, rSecurity) Export
	pAnswerByteArr = Undefined;
	If Not CallRS232Command(pDevice, "0031", Undefined, pAnswerByteArr) Then
		Return False;	
	EndIf;
	rNominal = New Structure();
	rSecurity = New Structure();
	rNominal.Insert("R10", 	  IsBitSet(pAnswerByteArr[2], 2));
	rNominal.Insert("R50", 	  IsBitSet(pAnswerByteArr[2], 3));
	rNominal.Insert("R100",   IsBitSet(pAnswerByteArr[2], 4));
	rNominal.Insert("R500",   IsBitSet(pAnswerByteArr[2], 5));
	rNominal.Insert("R1000",  IsBitSet(pAnswerByteArr[2], 6));
	rNominal.Insert("R5000",  IsBitSet(pAnswerByteArr[2], 7));
	rSecurity.Insert("R10",   IsBitSet(pAnswerByteArr[5], 2));
	rSecurity.Insert("R50",   IsBitSet(pAnswerByteArr[5], 3));
	rSecurity.Insert("R100",  IsBitSet(pAnswerByteArr[5], 4));
	rSecurity.Insert("R500",  IsBitSet(pAnswerByteArr[5], 5));
	rSecurity.Insert("R1000", IsBitSet(pAnswerByteArr[5], 6));
	rSecurity.Insert("R5000", IsBitSet(pAnswerByteArr[5], 7));
	Return True;
EndFunction // pmGetStatus

// -----------------------------------------------------------------------------
Function pmPool(pDevice, rAnswerHexCode = Undefined, rSum = 0, pIsManagementMod = False, pNotProcessBanknote = False) Export
	If Not CallRS232Command(pDevice, "0033", Undefined, rAnswerHexCode) Then
		Return False;	
	EndIf;
	If Not pIsManagementMod Then
		If rAnswerHexCode[0] = "0010" Or rAnswerHexCode[0] = "0011" Or rAnswerHexCode[0] = "0012" Then
			pmReset(pDevice);
			Return False;	
		ElsIf rAnswerHexCode[0] = "0014" And pNotProcessBanknote Then
			pmReset(pDevice);
		ElsIf rAnswerHexCode[0] = "0041" Then
			pmReset(pDevice);
			Return False;
		ElsIf rAnswerHexCode[0] = "0042" Then
			pmReset(pDevice);
			Return False;     
		ElsIf rAnswerHexCode[0] = "0043" Then
			pmReset(pDevice);
			Return False;
		ElsIf rAnswerHexCode[0] = "0044" Then
			pmReset(pDevice);
			Return False;
		ElsIf rAnswerHexCode[0] = "0045" Then
			pmReset(pDevice);
			Return False;
		ElsIf rAnswerHexCode[0] = "0045" Then
			pmReset(pDevice);
			Return False;
		ElsIf rAnswerHexCode[0] = "0047" Then
			pmReset(pDevice);
			Return False;
		ElsIf rAnswerHexCode[0] = "0081" Then
			If rAnswerHexCode[1] = "0002" Then
				rSum = rSum + 10;		
			ElsIf rAnswerHexCode[1] = "0003" Then
				rSum = rSum + 50;	
			ElsIf rAnswerHexCode[1] = "0004" Then
				rSum = rSum + 100;
			ElsIf rAnswerHexCode[1] = "0005" Then
				rSum = rSum + 500;
			ElsIf rAnswerHexCode[1] = "0006" Then
				rSum = rSum + 1000;	
			ElsIf rAnswerHexCode[1] = "0007" Then
				rSum = rSum + 5000;
			EndIf;
			If Not pNotProcessBanknote Then
				CallRS232Command(pDevice, "0000", Undefined, rAnswerHexCode);
			Else
				Return False;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction // pmReset

// -----------------------------------------------------------------------------
Function pmEnableSequence(pDevice, rSum = 0) Export
	vData = 0;
	vData = vData + ?(pDevice.R10, 4, 0);
	vData = vData + ?(pDevice.R50, 8, 0);
	vData = vData + ?(pDevice.R100, 16, 0);
	vData = vData + ?(pDevice.R500, 32, 0);
	vData = vData + ?(pDevice.R1000, 64, 0);
	vData = vData + ?(pDevice.R5000, 128, 0);
	vCode = Undefined;
	If Not pmPool(pDevice, vCode) Then
		Return False;	
	EndIf;
	If Not pmSetNominal(pDevice, vData) Then
		Return False;	
	EndIf;
	vCode = Undefined;
	If Not pmPool(pDevice, vCode, rSum) Then
		Return False;	
	EndIf;
	Return True;
EndFunction // pmReset

// -----------------------------------------------------------------------------
Function pmDisableSequence(pDevice, rSum = 0) Export
	vCode = Undefined;
	If Not pmPool(pDevice, vCode, rSum) Then
		Return False;	
	EndIf;
	If Not pmSetNominal(pDevice, 0) Then
		Return False;	
	EndIf;
	vCode = Undefined;
	If Not pmPool(pDevice, vCode, rSum) Then
		Return False;	
	EndIf;
	Return True;
EndFunction // pmReset

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pHexCode, rSum = 0) Export
	rSum = 0;
	If pHexCode[0] = "0010" Or pHexCode[0] = "0011" Or pHexCode[0] = "0012" Then
		Return(NStr("en = 'Power on after commands'; de = 'Nach Befehlen einschalten'; ru = 'Включение питания после команд'"));
	ElsIf pHexCode[0] = "0013" Then
		Return(NStr("en = 'Initialization'; de = 'Initialisierung'; ru = 'Инициализация'"));
	ElsIf pHexCode[0] = "0014" Then
		Return(NStr("en = 'Waiting for a cash'; de = 'Warten auf Bargeld'; ru = 'Ожидание приема купюры'"));
	ElsIf pHexCode[0] = "0015" Then
		Return(NStr("en = 'Scanning a banknote and determining its denomination'; de = 'Scannen einer Banknote und Bestimmen ihres Nennwerts'; ru = 'Сканирование банкноты и определяет ее номинал'"));
	ElsIf pHexCode[0] = "0017" Then
		Return(NStr("en = 'Stacking banknotes'; de = 'Banknoten stapeln'; ru = 'Укладка банкноты'"));
	ElsIf pHexCode[0] = "0018" Then
		Return(NStr("en = 'Return of banknotes'; de = 'Rückgabe von Banknoten'; ru = 'Возврат банкноты'"));
	ElsIf pHexCode[0] = "0019" Then
		Return(NStr("en = 'Cash acceptor disabled'; de = 'Bargeldakzeptor deaktiviert'; ru = 'Купюроприемник отключен'"));
	ElsIf pHexCode[0] = "001A" Then
		Return(NStr("en = 'Holding'; de = 'Halten'; ru = 'Удерживание'"));
	ElsIf pHexCode[0] = "001B" Then
		Return(NStr("en = 'At least 100 milliseconds must pass between requests'; de = 'Zwischen den Anforderungen müssen mindestens 100 Millisekunden vergehen'; ru = 'Между запросами должно пройти не менее 100 миллисекунд'"));
	ElsIf pHexCode[0] = "001C" Then
		vMsg = NStr("en = 'Refusal to accept'; de = 'Verweigerung der Annahme'; ru = 'Отказ от приема'") + Chars.LF;
		If pHexCode[1] = "0060" Then
			Return(vMsg + NStr("en = 'Insertion error'; de = 'Einfügefehler'; ru = 'Ошибка вставки'"));	
		ElsIf pHexCode[1] = "0061" Then
			Return(vMsg + NStr("en = 'Dielectric error'; de = 'Dielektrischer Fehler'; ru = 'Диэлектрическая погрешность'"));
		ElsIf pHexCode[1] = "0062" Then
			Return(vMsg);
		ElsIf pHexCode[1] = "0063" Then
			Return(vMsg + NStr("en = 'Multiplying factor error'; de = 'Multiplikationsfaktorfehler'; ru = 'Ошибка множителя'"));
		ElsIf pHexCode[1] = "0064" Then
			Return(vMsg + NStr("en = 'Cash transfer error'; de = 'Bargeldtransferfehler'; ru = 'Ошибка переноса купюры'"));
		ElsIf pHexCode[1] = "0065" Then
			Return(vMsg + NStr("en = 'Identification error'; de = 'Identifikationsfehler'; ru = 'Ошибка идентификации'"));
		ElsIf pHexCode[1] = "0066" Then
			Return(vMsg + NStr("en = 'Verification error'; de = 'Fehler bei der Verifikation'; ru = 'Ошибка проверки'"));
		ElsIf pHexCode[1] = "0067" Then
			Return(vMsg + NStr("en = 'Optic Sensor error'; de = 'Fehler des optischen Sensors'; ru = 'Ошибка оптического датчика'"));
		ElsIf pHexCode[1] = "0068" Then
			Return(vMsg + NStr("en = 'Return by mistake ""prohibited denomination""'; de = 'Rückgabe versehentlich ""verbotene Stückelung""'; ru = 'Возврат по ошибке «запрещенный номинал»'"));
		ElsIf pHexCode[1] = "0069" Then
			Return(vMsg + NStr("en = 'Capacitance error'; de = 'Kapazitätsfehler'; ru = 'Ошибка емкости'"));
		ElsIf pHexCode[1] = "006A" Then
			Return(vMsg + NStr("en = 'Operation error'; de = 'Betriebsfehler'; ru = 'Ошибка работы'"));
		ElsIf pHexCode[1] = "006C" Then
			Return(vMsg + NStr("en = 'Length error'; de = 'Längenfehler'; ru = 'Ошибка длины'"));
		ElsIf pHexCode[1] = "006D" Then	
			Return(vMsg + NStr("en = 'Banknotes do not meet the specified criteria'; de = 'Banknoten erfüllen nicht die angegebenen Kriterien'; ru = 'Банкноты не соответствуют заданным критериям'"));
		EndIf;
		Return(vMsg);
	ElsIf pHexCode[0] = "0041" Then
		Return(NStr("en = 'Cassette full condition'; de = 'Kassette voller Zustand'; ru = 'Кассета заполнена'"));
	ElsIf pHexCode[0] = "0042" Then
		Return(NStr("en = 'The cassette is open or removed'; de = 'Die Kassette ist geöffnet oder entfernt'; ru = 'Кассета открыта или удалена'"));
	ElsIf pHexCode[0] = "0043" Then
		Return(NStr("en = 'A bill has jammed in the acceptance path'; de = 'Eine Rechnung hat sich im Akzeptanzpfad verklemmt'; ru = 'Купюра застряла на пути приема'"));
	ElsIf pHexCode[0] = "0044" Then
		Return(NStr("en = 'A bill has jammed in drop cassette'; de = 'Eine Rechnung hat sich in der Drop-Kassette verklemmt'; ru = 'В кассете застряла банкнота'"));
	ElsIf pHexCode[0] = "0045" Then
		Return(NStr("en = 'Counterfeit bill inserted'; de = 'Gefälschte Rechnung eingefügt'; ru = 'Вставлена поддельная купюра'"));
	ElsIf pHexCode[0] = "0046" Then
		Return(NStr("en = 'The first banknote has not been processed yet'; de = 'Die erste Banknote wurde noch nicht bearbeitet'; ru = 'Первая банкнота еще не обработана'"));
	ElsIf pHexCode[0] = "0047" Then
		vMsg = NStr("en = 'Hardware failure'; de = 'Hardwarefehler'; ru = 'Сбой оборудования'") + Chars.LF;
		If pHexCode[1] = "0050" Then
			Return(vMsg + NStr("en = 'Cassette motor failure'; de = 'Ausfall des Kassettenmotors'; ru = 'Отказ мотора кассеты'"));	
		ElsIf pHexCode[1] = "0051" Then
			Return(vMsg + NStr("en = 'Transport Motor Speed failure'; de = 'Transport Motordrehzahlfehler'; ru = 'Сбой скорости транспортного двигателя'"));	
		ElsIf pHexCode[1] = "0052" Then
			Return(vMsg + NStr("en = 'Transport Motor failure'; de = 'Transportmotorausfall'; ru = 'Транспортная неисправность двигателя'"));	
		ElsIf pHexCode[1] = "0053" Then
			Return(vMsg + NStr("en = 'Aligning failure'; de = 'Fehler ausrichten'; ru = 'Ошибка выравнивания'"));	
		ElsIf pHexCode[1] = "0054" Then
			Return(vMsg + NStr("en = 'Cassette status error'; de = 'Kassettenstatusfehler'; ru = 'Ошибка состояния кассеты'"));	
		ElsIf pHexCode[1] = "0055" Then
			Return(vMsg + NStr("en = 'One of the optic sensors has failed to provide its response'; de = 'Einer der optischen Sensoren hat seine Antwort nicht geliefert'; ru = 'Один из оптических датчиков не смог дать ответ'"));	
		ElsIf pHexCode[1] = "0056" Then
			Return(vMsg + NStr("en = 'Inductive sensor failed to respond'; de = 'Der induktive Sensor reagierte nicht'; ru = 'Индуктивный датчик не ответил'"));	
		ElsIf pHexCode[1] = "005F" Then
			Return(vMsg + NStr("en = 'Capacitance sensor failed to respond'; de = 'Der Kapazitätssensor reagierte nicht'; ru = 'Датчик емкости не ответил'"));	
		EndIf;
		Return(vMsg);
	ElsIf pHexCode[0] = "0081" Then
		vMsg = NStr("en = 'Banknote is not processed'; de = 'Banknote wird nicht verarbeitet'; ru = 'Банкнота не обработана'") + Chars.LF;
		If pHexCode[1] = "0002" Then
			rSum = 10;	
		ElsIf pHexCode[1] = "0003" Then
			rSum = 50;	
		ElsIf pHexCode[1] = "0004" Then
			rSum = 100;	
		ElsIf pHexCode[1] = "0005" Then
			rSum = 500;	
		ElsIf pHexCode[1] = "0006" Then
			rSum = 1000;	
		ElsIf pHexCode[1] = "0007" Then
			rSum = 5000;	
		EndIf;
		Return vMsg;
	EndIf;	
EndFunction // pmGetErrorDescription

#EndRegion

#Region Internal

#Region WorkingWithRS232

// -----------------------------------------------------------------------------
Function GetPersistentObject(pName)
	vObject = Undefined;
	amPersistentObjects.Property(pName, vObject);
	If vObject = Undefined Then
		amPersistentObjects.Insert(pName, vObject);
	EndIf;
	Return vObject;
EndFunction // GetPersistentObject 

// -----------------------------------------------------------------------------
Procedure SetPersistentObject(pName, pValue)
	amPersistentObjects.Insert(pName, pValue);
EndProcedure // SetPersistentObject

// -----------------------------------------------------------------------------
Function Connect(pDevice)
	// Fill system name
	vSystemName = "CashCodeNET";
	vDLSys = GetPersistentObject("CashCodeNET");
	#If Not WebClient And Not MobileClient Then
		If vDLSys = Undefined Then 
			Try
				If Not ValueIsFilled(pDevice) Then
					Return Undefined;
				EndIf;
				
				// Build ActiveX object to work with
				vDLSys = Undefined;
				vDLSys = New COMObject("SPort.SPortAx.1");
				// Set connection parameters
				vDLSys.InitString(GetCOMPortConnectionString(pDevice));
				vDLSys.DTR = pDevice.DTR;
				vDLSys.InBufferSize = 256;
				vDLSys.OutBufferSize = 256;
				// Open COM port
				vIsOpen = vDLSys.Open(TrimAll(pDevice.Port));
				If Not vIsOpen Then
					AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden:'") + TrimAll(pDevice.Port));
					Return Undefined;
				EndIf;
				vDLSys.BlockMode = True; 
				vDLSys.TimeoutReadInterval = pDevice.TimeoutReadInterval;
				vDLSys.TimeoutReadTotalConstant = pDevice.TimeoutReadTotalConstant;
				vDLSys.TimeoutReadTotalMultiplier = pDevice.TimeoutReadTotalMultiplier;
				vDLSys.TimeoutWriteTotalConstant = pDevice.TimeoutWriteTotalConstant;
				vDLSys.TimeoutWriteTotalMultiplier = pDevice.TimeoutWriteTotalMultiplier;
				If Not vDLSys = Undefined Then
					SetPersistentObject("CashCodeNET", vDLSys);
				EndIf;
			Except
				AddError(NStr("ru = 'Ошибка подключения " + vSystemName + ": '; 
				|en = '" + vSystemName + " connection error: ';
				|de = '" + vSystemName + " connection error: '") + ErrorDescription());
				Return Undefined;
			EndTry;
		EndIf;
	#EndIf
	Return vDLSys;
EndFunction // pmConnect

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
Function CallRS232Command(pDevice, pCommandCode, pDta = Undefined, pAnswerByteArr)
	vDLSys = Connect(pDevice); 
	If vDLSys = Undefined Then
		Return False;
	EndIf;
	vResult = New Array();
	vLengthCommandData = 6 + ?(pDta <> Undefined, pDta.Count(), 0);	
	vByteArr = New Array();
	vByteArr.Add(NumberFromHexString("0x0002"));
	vByteArr.Add(NumberFromHexString("0x0003"));
	vByteArr.Add(vLengthCommandData);
	vByteArr.Add(NumberFromHexString("0x" + pCommandCode));	
	If pDta <> Undefined Then
		For Each vByte In pDta Do 
			vByteArr.Add(vByte);
		EndDo;
	EndIf;
	vCRC16 = GetCRC16(vByteArr, vLengthCommandData - 2);
	vByteArr.Add(vCRC16.Get(0));
	vByteArr.Add(vCRC16.Get(1));
	vBytesSent = WriteByte(vDLSys, vByteArr); 
	If vBytesSent <> vByteArr.Count() Then
		Return False;	
	EndIf;
	vResult = ReadByte(vDLSys);
	Return ParseAnswer(vResult, pAnswerByteArr);
EndFunction // CallRS232Command

// -----------------------------------------------------------------------------
Function GetCRC16(Val pByteArr, pLengthByteArr)
	vBuff = New BinaryDataBuffer(2);
	vResult = 0;
	For i = 0 To pLengthByteArr - 1 Do
		TmpCRC = BitwiseXor(vResult, pByteArr[i]); 
		For j = 0 To 7 Do
			If BitwiseAnd(TmpCRC, 0001) <> 0 Then
				TmpCRC = BitwiseShiftRight(TmpCRC, 1);
				TmpCRC = BitwiseXor(TmpCRC,  33800); 
			Else
				TmpCRC = BitwiseShiftRight(TmpCRC, 1); 	
			EndIf;
		EndDo;
		vResult = TmpCRC;
	EndDo;
	vBuff.WriteInt16(0, vResult);
	Return vBuff;	
EndFunction // GetCRC16

// -----------------------------------------------------------------------------
Function ReadByte(pDLSys, pBytesRcv = 256)
	vReply = New Array();
	vVariant = pDLSys.ReadVariant(pBytesRcv); 
	If vVariant <> Undefined Then
		vReply = vVariant.Unload();	
	EndIf;
	Return vReply;
EndFunction // ReadByte

// -----------------------------------------------------------------------------
Function WriteByte(pDLSys, pByteArr)
	vResult = Undefined;
	#If Not WebClient And Not MobileClient Then
		vVaiant = New COMSafeArray(pByteArr, "VT_VARIANT", pByteArr.Count());
		vResult = pDLSys.WriteVariant(vVaiant); 
	#EndIf
	Return vResult;
EndFunction // WriteByte

// -----------------------------------------------------------------------------
Function ParseAnswer(pByteArr, pAnswerByteArr)
	vByteArrCount = pByteArr.Count();
	If vByteArrCount < 6 Then
		Return False;	
	EndIf;
	vCRC16 = GetCRC16(pByteArr, vByteArrCount - 2);
	If vCRC16.Get(0) <> pByteArr[vByteArrCount - 2] And vCRC16.Get(1) <> pByteArr[vByteArrCount - 1] Then
		Return False;
	EndIf;
	pAnswerByteArr = New Array();
	For i = 0 To vByteArrCount - 6 Do
		vBinaryBuffer = New BinaryDataBuffer(2, ByteOrder.BigEndian);
		vBinaryBuffer.WriteInt16(0, pByteArr[i + 3]);
		pAnswerByteArr.Add(GetHexStringFromBinaryDataBuffer(vBinaryBuffer));	
	EndDo;
	Return True; 
EndFunction // ParseAnswer

// -----------------------------------------------------------------------------
Function IsBitSet(pValue, pBitNum)
	Return ?(BitwiseAnd(BitwiseShiftRight(NumberFromHexString("0x" + pValue), pBitNum), 1) = 1, True, False);	
EndFunction // IsBitSet

#EndRegion

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CashAcceptorsSystem.Error'; de = 'CashAcceptorsSystem.Error'; ru = 'СистемаКупюроприемников.Ошибка'"), "Warning", , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmSetNominal(pDevice, pNominal)
	pAnswerByteArr = Undefined;
	vDataArr = New Array();
	vDataArr.Add(0);
	vDataArr.Add(0);
	vDataArr.Add(pNominal);
	vDataArr.Add(0);
	vDataArr.Add(0);
	vDataArr.Add(0);
	If Not CallRS232Command(pDevice, "0034", vDataArr, pAnswerByteArr) Then
		Return False;	
	EndIf;
	If pAnswerByteArr[0] = "00FF" Then
		Return False;	
	EndIf;
	Return True;
EndFunction // pmSetNominal

#EndRegion
