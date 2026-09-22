Var RC_NO_PAPER;

// -----------------------------------------------------------------------------
Function GetPortNumber()
	vPort = TrimAll(RibbonPrinterConnectionParameters.Port);
	If vPort = "" Then
		Return 1; //COM1 by default
	Else
		If StrLen(vPort) > 2 Then
			If Upper(vPort) = "TCP/IP" Then
				Return 99;
			Else
				If Upper(Left(vPort, 3)) = "COM" Then
					vPortNumber = Number(Mid(vPort, 4, StrLen(vPort)-3));
				ElsIf Upper(Left(vPort, 3)) = "LPT" Then 
					vPortNumber = Number(Mid(vPort, 4, StrLen(vPort)-3)) - 32;
				Else
					Raise NStr("en='Wrong port number format!'; de='Wrong port number format!'; ru='Неверный формат указания номера порта подключения!'");
				EndIf;
			EndIf;
		Else
			vPortNumber = Number(vPort);
		EndIf;
		Return vPortNumber;
	EndIf;
EndFunction // GetPortNumber

// -----------------------------------------------------------------------------
Function GetBaudRate()
	vBaudRate = RibbonPrinterConnectionParameters.BaudRate;
	If vBaudRate = 1200 Then
		Return 3;
	ElsIf vBaudRate = 2400 Then
		Return 4;
	ElsIf vBaudRate = 4800 Then
		Return 5;
	ElsIf vBaudRate = 9600 Then
		Return 7;
	ElsIf vBaudRate = 19200 Then
		Return 10;
	ElsIf vBaudRate = 38400 Then
		Return 12;
	ElsIf vBaudRate = 57600 Then
		Return 14;
	ElsIf vBaudRate = 115200 Then
		Return 18;
	ElsIf vBaudRate = 0 Then
		Return 7; // 9600 by default
	EndIf;		
	Return 0;
EndFunction // GetBaudRate

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		#IF CLIENT THEN
			If Not amRibbonPrinterIsAttached Then
				Try
					AttachAddIn("AddIn.RcpPrn51");
					vPR = New("AddIn.RcpPrn51");
					amRibbonPrinterIsAttached = True;
				Except
					LoadAddIn("RcpPrn1C.dll");
					vPR = New("AddIn.RcpPrn51");
				EndTry;
			Else
				vPR = New("AddIn.RcpPrn51");
			EndIf;
		#ELSE
			vPR = New("AddIn.RcpPrn51");
		#ENDIF
		// Set active logical device
		If RibbonPrinterConnectionParameters.UseLogicalDevice And RibbonPrinterConnectionParameters.LogicalDeviceNumber > 0 Then
			vPR.CurrentDeviceNumber = RibbonPrinterConnectionParameters.LogicalDeviceNumber;
		EndIf;
		// Apply connection parameters
		If Not IsBlankString(RibbonPrinterConnectionParameters.Model) Then
			vPR.Model = Number(RibbonPrinterConnectionParameters.Model);
		EndIf;
		vPortNumber = GetPortNumber();
		vBaudRate = GetBaudRate();
		If vPortNumber > 0 Then
			vPR.PortNumber = vPortNumber;
		EndIf;
		If vBaudRate > 0 Then
			vPR.BaudRate = vBaudRate;
		EndIf;
		If Not IsBlankString(RibbonPrinterConnectionParameters.MachineName) Тогда
			vPR.MachineName = TrimAll(RibbonPrinterConnectionParameters.MachineName);
		EndIf;
		If Not IsBlankString(RibbonPrinterConnectionParameters.IPAddress) Тогда
			vPR.IPAddress = TrimAll(RibbonPrinterConnectionParameters.IPAddress);
		EndIf;
		If Not IsBlankString(RibbonPrinterConnectionParameters.IPPort) Тогда
			vPR.IPPort = TrimAll(RibbonPrinterConnectionParameters.IPPort);
		EndIf;
		vPR.Exclusive = RibbonPrinterConnectionParameters.ExclusiveAccess;
		vPR.FlowControl = RibbonPrinterConnectionParameters.FlowControl;
		vPR.TextWrap = False;
		vPR.BackgroundPrint = False;
		vPR.ProgressButtonsVisible = True;
		vPR.RaiseException = False;
		// Try to enable device
		vPR.DeviceEnabled = 1;
		// Check result code
		If vPR.ResultCode <> 0 And vPR.ResultCode <> RC_NO_PAPER Then
			// Error connecting to the device
			rMessage = TrimAll(vPR.ResultDescription);
			Return Undefined;
		Else
			// OK
			Return vPR;
		EndIf;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pPR)
	Try
		pPR.DeviceEnabled = 0;
		pPR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function pmCheckConnection(rMessage) Export
	// Try to connect
	vPR = Connect(rMessage);
	If vPR = Undefined Then
		Return False;
	Else
		Try
			// Printer was connected, so try to check paper
			If vPR.ResultCode = RC_NO_PAPER Then
				rMessage = NStr("en='Printer error: No paper!'; de='Printer error: No paper!'; ru='Ошибка принтера: Нет бумаги!'");
				Disconnect(vPR);
				Return True;
			EndIf;
			// Check printer status
			vPR.GetStatus();
			If vPR.ResultCode <> 0 And vPR.ResultCode <> RC_NO_PAPER Then
				ProcessResultCode(vPR, NStr("en='RibbonPrinterConnectionParameters.CheckConnection'; de='RibbonPrinterConnectionParameters.CheckConnection'; ru='ЛенточныйПринтер.ПроверкаСвязи'"), rMessage);
				Return False;
			EndIf;
			If vPR.StatusErrorCount > 0 Then
				vErrorsFound = False;
				For i = 0 To vPR.StatusErrorCount Do
					vPR.StatusErrorIndex = i;
					If vPR.StatusErrorValue <> 0 Then
						If Not vErrorsFound Then
							vErrorsFound = True;
							rMessage = rMessage + NStr("en='Printer errors:'; de='Printer errors:'; ru='Ошибки принтера:'") + Chars.LF;
						EndIf;
						rMessage = rMessage + TrimAll(vPR.StatusErrorDescription) + Chars.LF;
					EndIf;
				EndDo;						
				Disconnect(vPR);
				Return True;
			EndIf;
		Except
			rMessage = ErrorDescription();
			Disconnect(vPR);
			Return False;
		EndTry;
	EndIf;
	Return True;
EndFunction // pmCheckConnection

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pPR, pFunction, rMessage)
	rMessage = TrimAll(pPR.ResultDescription);
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, RibbonPrinterConnectionParameters.Metadata(), RibbonPrinterConnectionParameters, "Result code: " + pPR.ResultCode + ", result description: " + rMessage);
	Disconnect(pPR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure ProcessException(pPR, pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, RibbonPrinterConnectionParameters.Metadata(), RibbonPrinterConnectionParameters, "Error description: " + rMessage);
	Disconnect(pPR);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function pmIsReadyToPrint(pPR, rMessage) Export
	// Check demo mode
	//If pPR.IsDemo = 1 Then
	//	rMessage = NStr("ru = 'Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en = 'Atol cash register driver dongle was not found!'");
	//	Disconnect(pPR);
	//	Return False;
	//EndIf;
	// Printer was connected, so try to check paper
	If pPR.ResultCode = RC_NO_PAPER Then
		rMessage = NStr("en='Printer error: No paper!'; de='Printer error: No paper!'; ru='Ошибка принтера: Нет бумаги!'");
		Disconnect(pPR);
		Return False;
	EndIf;
	// Check printer status
	pPR.GetStatus();
	If pPR.ResultCode <> 0 And pPR.ResultCode <> RC_NO_PAPER Then
		ProcessResultCode(pPR, NStr("en='RibbonPrinterConnectionParameters.IsReadyToPrint'; de='RibbonPrinterConnectionParameters.IsReadyToPrint'; ru='ЛенточныйПринтер.ПроверкаВозможностиПечати'"), rMessage);
		Return False;
	EndIf;
	If pPR.StatusErrorCount > 0 Then
		vErrorsFound = False;
		For i = 0 To pPR.StatusErrorCount Do
			pPR.StatusErrorIndex = i;
			If pPR.StatusErrorValue <> 0 Then
				If Not vErrorsFound Then
					vErrorsFound = True;
					rMessage = rMessage + NStr("en='Printer errors:'; de='Printer errors:'; ru='Ошибки принтера:'") + Chars.LF;
				EndIf;
				rMessage = rMessage + TrimAll(pPR.StatusErrorDescription) + Chars.LF;
			EndIf;
		EndDo;
		If vErrorsFound Then
			Disconnect(pPR);
			Return False;
		EndIf;
	EndIf;
	// Check completed successfully
	Return True;
EndFunction // pmIsReadyToPrint

// -----------------------------------------------------------------------------
Function pmPrintCoupons(pObjList, pLang, rMessage) Export
	// Try to connect
	vPR = Connect(rMessage);
	If vPR = Undefined Then
		Return False;
	Else
		// Printer was connected
		Try
			// Create new task
			vPR.ClearTask();
			If vPR.ResultCode <> 0 Then
				ProcessResultCode(vPR, NStr("en='RibbonPrinterConnectionParameters.PrintCoupon'; de='RibbonPrinterConnectionParameters.PrintCoupon'; ru='ЛенточныйПринтер.ПечатьТалона'"), rMessage);
				Return False;
			EndIf;
			// Check if printing is possible
			If pmIsReadyToPrint(vPR, rMessage) Then
				// Do for each object in input list
				For Each vObjListItem In pObjList Do
					vObj = vObjListItem.Value;
					// Print coupon header
					vPR.Caption = vObj.Hotel.GetObject().pmGetHotelPrintName(pLang);
					vPR.Alignment = 1; // Center
					If vPR.CapFontDblWidth Then
						vPR.FontDblWidth = True;
						vPR.FontBold = False;
					Else
						vPR.FontBold = True;
					EndIf;
					If vPR.CapFontDblHeight Then
						vPR.FontDblHeight = True;
					EndIf;
					vPR.FontNegative = False;
					vPR.TextNewLine = True;
					vPR.AddText();
					// Accounting date
					vPR.Caption = Format(vObj.Date, "DF=dd.MM.yyyy");
					vPR.Alignment = 2; // Right
					If vPR.CapFontDblWidth Then
						vPR.FontDblWidth = True;
					EndIf;
					If vPR.CapFontDblHeight Then
						vPR.FontDblHeight = True;
					EndIf;
					vPR.FontBold = True;
					vPR.TextNewLine = True;
					vPR.AddText();
					// Service name
					vPR.Caption = Upper(vObj.Service.GetObject().pmGetServiceDescription(pLang)) + "  ";
					vPR.Alignment = 0; // Left
					vPR.FontDblWidth = False;
					If vPR.CapFontDblHeight Then
						vPR.FontDblHeight = True;
					EndIf;
					vPR.FontBold = True;
					vPR.TextNewLine = False;
					vPR.AddText();
					// Quantity
					vPR.Caption = Format(vObj.Quantity, "ND=5; NFD=0; NZ=; NG=");
					vPR.Alignment = 2; // Right
					vPR.FontDblWidth = False;
					If vPR.CapFontDblHeight Then
						vPR.FontDblHeight = True;
					EndIf;
					vPR.FontBold = True;
					vPR.TextNewLine = True;
					vPR.AddText();
					// Client name
					If ValueIsFilled(vObj.Client) Then
						vPR.Caption = Upper(cmNStr("en='Name: '; de='Name: '; ru='Имя: '", pLang)) + TrimAll(vObj.Client.FullName);
					Else
						vPR.Caption = Upper(cmNStr("en='Name: '; de='Name: '; ru='Имя: '", pLang)) + "******";
					EndIf;
					vPR.Alignment = 0; // Left
					vPR.FontDblWidth = False;
					vPR.FontDblHeight = False;
					vPR.FontBold = False;
					vPR.TextNewLine = True;
					vPR.AddText();
					// Room or resource
					If ValueIsFilled(vObj.Resource) Then
						vPR.Caption = Upper(cmNStr("en='Resource: '; de='Resource: '; ru='Ресурс: '", pLang)) + TrimAll(vObj.Resource);
						vPR.Alignment = 0; // Left
						vPR.FontDblWidth = False;
						vPR.FontDblHeight = False;
						vPR.FontBold = False;
						vPR.TextNewLine = True;
						vPR.AddText();
						// Print guest group period and description
						If ValueIsFilled(vObj.GuestGroup) And 
						   ValueIsFilled(vObj.GuestGroup.CheckInDate) And 
						   ValueIsFilled(vObj.GuestGroup.CheckOutDate) Then
							vPR.Caption = Upper(cmNStr("en='Group: ';ru='Группа: ';de='Gruppe: '", pLang)) + 
										  Format(vObj.GuestGroup.Code, "ND=12; NFD=0; NG=") + ", " + 
										  Format(vObj.GuestGroup.CheckInDate, "DF='dd.MM HH:mm'") + " - " + 
										  Format(vObj.GuestGroup.CheckOutDate, "DF='dd.MM HH:mm'");
							vPR.Alignment = 0; // Left
							vPR.FontDblWidth = False;
							vPR.FontDblHeight = False;
							vPR.FontBold = False;
							vPR.TextNewLine = True;
							vPR.TextWrap = True;
							vPR.AddText();
							// Description
							If Not IsBlankString(vObj.GuestGroup.Description) Then
								vPR.Caption = TrimAll(vObj.GuestGroup.Description);
								vPR.Alignment = 0; // Left
								vPR.FontDblWidth = False;
								vPR.FontDblHeight = False;
								vPR.FontBold = True;
								vPR.TextNewLine = True;
								vPR.TextWrap = True;
								vPR.AddText();
							EndIf;
							vPR.TextWrap = False;
						EndIf;
					ElsIf ValueIsFilled(vObj.Room) Then
						vPR.Caption = Upper(cmNStr("en='Room: ';ru='Номер: ';de='Zimmer: '", pLang)) + TrimAll(vObj.Room);
						vPR.Alignment = 0; // Left
						vPR.FontDblWidth = False;
						vPR.FontDblHeight = False;
						vPR.FontBold = True;
						vPR.TextNewLine = True;
						vPR.AddText();
					EndIf;
					// Add bar code with charge document number
					If ValueIsFilled(RibbonPrinterConnectionParameters.BarCodeType) Then
						vPR.Caption = TrimAll(vObj.CouponBarCode);
						vPR.BarCodePrintText = False;
						If RibbonPrinterConnectionParameters.BarCodeType = Enums.BarCodeTypes.Code39 Then
							vPR.BarCodeType = 1; 
						EndIf;
						vPR.BarCodeControlCode = False;
						vPR.Alignment = 1; // Center
						vPR.AddBarCode();
					EndIf;
					// Do partial cut
					If vPR.CapCutPart Then
						vPR.FeedValue = 1;
						vPR.AddFeed();
						vPR.CutValue = 2;
						vPR.AddCut();
					Else // or print delimeter line
						vPR.Caption = "-----------%<-----------";
						vPR.Alignment = 1; // Center
						vPR.FontDblWidth = False;
						vPR.FontDblHeight = False;
						vPR.FontBold = False;
						vPR.TextNewLine = True;
						vPR.AddText();
					EndIf;
				EndDo;
			Else
				Return False;
			EndIf;
			// Do print
			vPR.UpdatePrinterSettings = True;
			vPR.PrintTask();
			If vPR.ResultCode <> 0 Then
				ProcessResultCode(vPR, NStr("en='RibbonPrinterConnectionParameters.PrintCoupon'; de='RibbonPrinterConnectionParameters.PrintCoupon'; ru='ЛенточныйПринтер.ПечатьТалона'"), rMessage);
				Return False;
			EndIf;
			// Disconnect
			Disconnect(vPR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPR, NStr("en='RibbonPrinterConnectionParameters.PrintCoupon'; de='RibbonPrinterConnectionParameters.PrintCoupon'; ru='ЛенточныйПринтер.ПечатьТалона'"), rMessage);
		EndTry;
	EndIf;
	Return False;
EndFunction // pmPrintCoupons

// -----------------------------------------------------------------------------
RC_NO_PAPER = -6001;
