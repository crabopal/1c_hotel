// -----------------------------------------------------------------------------
Function GetPortNumber8(pCashRegister)
	vPort = TrimAll(pCashRegister.Port);
	If vPort = "" Then
		Return 1001; //COM1 by default
	ElsIf vPort = "АТОЛ USB" Then
		Return 67;
	ElsIf vPort = "TCP/IP (клиент)" Then
		Return 99;
	ElsIf vPort = "UDP/IP" Then
		Return 110;
	Else
		vPortNumber = 1000 + Number(Mid(vPort, 4, StrLen(vPort)-3));
		Return vPortNumber;
	EndIf;
EndFunction // GetPortNumber8

// -----------------------------------------------------------------------------
Function GetBaudRate(pCashRegister)
	vBaudRate = pCashRegister.BaudRate;
	If vBaudRate = 1200 Then
		Return 3;
	ElsIf vBaudRate = 2400 Then
		Return 4;
	ElsIf vBaudRate = 4800 Then
		Return 5;
	ElsIf vBaudRate = 9600 Then
		Return 7;
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
Function Connect(rMessage,vArrCashRegister)
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		vAddInName = "AddIn.FprnM8";
		Try
			AttachAddIn(vAddInName);
			vFR = New(vAddInName);
		Except
			LoadAddIn("FPrnM1C.dll");
			vFR = New(vAddInName);
		EndTry;
		// Set active logical device
		If vArrCashRegister.UseLogicalDevice And vArrCashRegister.LogicalDeviceNumber > 0 Then
			vFR.CurrentDeviceNumber = vArrCashRegister.LogicalDeviceNumber;
		EndIf;
		If vFR.CurrentDeviceNumber = 0 Then
			vFR.AddDevice();
		EndIf;
		// Apply connection parameters
		If Not IsBlankString(vArrCashRegister.CashRegisterModel) Then
			vFR.Model = Number(vArrCashRegister.CashRegisterModel);
		EndIf;
		If Not IsBlankString(vArrCashRegister.AccessPassword) Then
			vFR.UseAccessPassword = 1;
			vFR.AccessPassword = TrimR(vArrCashRegister.AccessPassword);
		Else
			vFR.UseAccessPassword = 0;
		EndIf;
		vPortNumber = GetPortNumber8(vArrCashRegister);
		vBaudRate = GetBaudRate(vArrCashRegister);
		If vPortNumber > 0 Then
			vFR.PortNumber = vPortNumber;
		EndIf;
		If vBaudRate > 0 Then
			vFR.BaudRate = vBaudRate;
		EndIf;
		If Not IsBlankString(vArrCashRegister.Address) Then
			If TrimAll(vArrCashRegister.Port) = "TCP/IP (клиент)" Or TrimAll(vArrCashRegister.Port) = "UDP/IP" Then
				vFR.HostAddress = TrimAll(vArrCashRegister.Address);
			Else
				vFR.MachineName = TrimAll(vArrCashRegister.Address);
			EndIf;
		EndIf;
		If vArrCashRegister.WriteLogFile Then
			vFR.WriteLogFile = 1;
		Else
			vFR.WriteLogFile = 0;
		EndIf;
		// Do model check for each operation
		vFR.ModelCheck = 1;
		// Try to enable device
		vFR.DeviceEnabled = 1;
		// Check result code
		If vFR.ResultCode <> 0 Then
			// Error connecting to the device
			rMessage = TrimAll(vFR.ResultDescription);
			Return Undefined;
		Else
			// OK
			Return vFR;
		EndIf;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pFR)
	Try
		pFR.ResetMode();
		pFR.DeviceEnabled = 0;
		pFR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False, pCashRegister) Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else // Cash register was connected
		// Check demo mode
		If vFR.IsDemo = 1 Then
			rMessage = NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Retrieve cash register state
		RC_24_HOURS_LIMIT = -3822;
		vFR.GetCurrentMode();
		If vFR.ResultCode = RC_24_HOURS_LIMIT Then
			If Not pSkip24HoursLimitWarning Then
				rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
				Disconnect(vFR);
				Return False;
			EndIf;
		ElsIf vFR.ResultCode <> 0 Then
			rMessage = NStr("ru='Ошибка получения состояния ККМ!'; en='Failed to check cash register state!'; de='Failed to check cash register state!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check paper
		If vFR.OutOfPaper = 1 Then
			rMessage = NStr("ru='В ККМ закончилась чековая лента!'; en='Cash register is out of paper!'; de='Cash register is out of paper!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check cheque printer
		If vFR.PrinterConnectionFailed = 1 Then
			rMessage = NStr("ru='ККМ не может установить связь с принтером чеков!'; en='Cash register failes to connect to the cheque printer!'; de='Cash register failes to connect to the cheque printer!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		If vFR.PrinterMechanismError = 1 Then
			rMessage = NStr("ru='Ошибка принтера чеков!'; en='Cheque printer error!'; de='Cheque printer error!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		If vFR.PrinterOverheatError = 1 Then
			rMessage = NStr("ru='Перегрев принтера чеков! Повторите попытку позже.'; en='Cheque printer overheated! Wait a while and try again.'; de='Cheque printer overheated! Wait a while and try again.'");
			Disconnect(vFR);
			Return False;
		EndIf;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmIsReadyToPrint

// -----------------------------------------------------------------------------
Procedure CloseOpenCheque(pFR, pPasswordKKM="", pOpenSessionIfClosed = False)
	// Connect
	If pFR.DeviceEnabled = 0 Then
		pFR.DeviceEnabled = 1;
	EndIf;

	// Get advanced mode
	If pFR.Mode = 1 Then
		pFR.GetStatus();		
		If pFR.ResultCode = 0 Then
			If pFR.CheckState > 0 Then
				pFR.CancelCheck();
			ElsIf pFR.CheckPaperPresent = 0 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Cheque ribbon is almost over!'; de='Scheck Band ist fast vorbei!'; ru='В ККМ заканчивается бумага!'"), MessageStatus.Attention);
			EndIf;
			If pOpenSessionIfClosed Then
				If pFR.SessionOpened = 0 Then
					// Open session
					pFR.Caption = "";
					vFRPassword = pPasswordKKM;
					pFR.Password = vFRPassword;
					pFR.OpenSession();
					tcOnServer.Wait(5);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CloseOpenCheque

// -----------------------------------------------------------------------------
Procedure CancelCheque(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.ResultDescription);
	tcCommonFunctionOnClientServer.TextMessage(rMessage);
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,,"Result code: " + pFR.ResultCode + ", result description: " + rMessage);
	Try
		pFR.CancelCheck();
	Except
	EndTry;
	Disconnect(pFR);
EndProcedure // CancelCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, vArrCashRegister.DoNotOpenNewSessionAfterZReport);
			
			// Check demo mode
			If vFR.IsDemo = 1 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'"));
				Return False;
			EndIf;
			
			// Set mode
			vFR.Mode = 1;
			vFRPassword = pPasswordKKM;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;	
			
			// Open cheque
			If pSum >= 0 Then
				vFR.CheckType = 1;
			Else
				vFR.CheckType = 2;
			EndIf;
			If ValueIsFilled(pObj.PaymentMethod) And tcOnServer.cmGetAttributeByRef(pObj.PaymentMethod, "ElectronicChequeOnly") Then
				vFR.CheckMode = 1; // Do not print cheque on paper
			Else
				vFR.CheckMode = 0;
			EndIf;
			vFR.OpenCheck();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;	
			
			// Print slip if payment was made by credit card
			If vArrCashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					PrintSlipLines(vFR, tcOnServer.GetTextLinesArray(pObj.SlipText),vArrCashRegister);
					// Print cheque header
					vFR.PrintHeader();
					If vFR.ResultCode <> 0 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Cheque folio header
			If vArrCashRegister.PrintFolioHeader Then
				PrintFolioHeader(vFR, pObj, vArrCashRegister);
			EndIf;
			
			// Print services
			If Not vArrCashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
				For Each vSrvRow In pServices Do
					// Fill item attributes
					vPaymentSection = Undefined;
					vFR.Department = 0;
					vFR.Name = "";
					If ValueIsFilled(vSrvRow.Service) Then
						vFR.Name = GetString(tcOnServer.cmGetServiceDescription(vSrvRow.Service), vArrCashRegister);
						vPaymentSection = tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "PaymentSection");
						If ValueIsFilled(vPaymentSection) Then
							vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
						EndIf;
					EndIf;
					vFR.Quantity = vSrvRow.Quantity;
					vFR.Price = vSrvRow.Price;
					// Add tax
					vVATRate = Undefined;
					// Do registration
					vFR.Registration();
					If vFR.ResultCode <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;	
				EndDo;
			Else
				// Print number and sections
				If pObj.PaymentSections.Count() > 0 Then
					If Not vArrCashRegister.PrintFolioHeader Then
						vFR.Caption = "#" + TrimAll(pObj.Number);
						vFR.PrintString();
						If vFR.ResultCode <> 0 Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
					vPSRows = tcCashRegisters.GetPrintableChequePositions(pObj, , vArrCashRegister.AlwaysUseAveragePrice);
					If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
						pSum = 0;
						For Each vPSRow In vPSRows Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								Continue;
							Else
								pSum = pSum + vPSRow.Sum;
							EndIf;
							vSectionAmount = vPSRow.Sum;
							vSectionVATAmount = vPSRow.VATSum;
							If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
								vSectionAmount = -vSectionAmount;
								vSectionVATAmount = -vSectionVATAmount;
							EndIf;
							// Print name, price and quantity
							If ValueIsFilled(vPSRow.ChequeService) Then
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.Department = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
								Else
									vFR.Department = 0;
								EndIf;
								vFR.Name = GetString(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Description"), vArrCashRegister);
								vFR.Quantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
								vFR.Price = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vFR.Department = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
								vFR.Name = GetString(tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Description"), vArrCashRegister);
								vFR.Quantity = 1;
								vFR.Price = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
							Else
								vFR.Department = 0;
								If vSectionAmount >=0 Then
									vFR.Name = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
								Else
									vFR.Name = NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'");
								EndIf;
								vFR.Quantity = 1;
								vFR.Price = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
							EndIf;
							// Do registration
							If vSectionAmount >= 0 Then
								vFR.Registration();
							Else
								vFR.Return();
							EndIf;
							If vFR.ResultCode <> 0 Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;	
						EndDo;
					ElsIf Not vArrCashRegister.DoNotPrintPaymentSections Then
						pSum = 0;
						For Each vPSRow In vPSRows Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								Continue;
							Else
								pSum = pSum + vPSRow.Sum;
							EndIf;
							vSectionAmount = vPSRow.Sum;
							vSectionVATAmount = vPSRow.VATSum;
							If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
								vSectionAmount = -vSectionAmount;
								vSectionVATAmount = -vSectionVATAmount;
							EndIf;
							// Print name, price and quantity
							If ValueIsFilled(vPSRow.ChequeService) Then
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.Department = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
								Else
									vFR.Department = 0;
								EndIf;
								vFR.Name = GetString(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Description"), vArrCashRegister);
								vFR.Quantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
								vFR.Price = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vFR.Department = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
								vFR.Name = "";
								vFR.Quantity = 1;
								vFR.Price = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
							Else
								vFR.Department = 0;
								vFR.Name = "";
								vFR.Quantity = 1;
								vFR.Price = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
							EndIf;
							// Do registration
							If vSectionAmount >= 0 Then
								vFR.Registration();
							Else
								vFR.Return();
							EndIf;
							If vFR.ResultCode <> 0 Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;	
						EndDo;
					Else
						vAmount = 0;
						vVATAmount = 0;
						pSum = 0;
						For Each vPSRow In vPSRows Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								Continue;
							Else
								pSum = pSum + vPSRow.Sum;
							EndIf;
							If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
								vAmount = vAmount - vPSRow.Sum;
								vVATAmount = vVATAmount - vPSRow.VATSum;
							Else
								vAmount = vAmount + vPSRow.Sum;
								vVATAmount = vVATAmount + vPSRow.VATSum;
							EndIf;
						EndDo;
						// Print name, price and quantity
						vFR.Department = 0;
						vFR.Name = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
						vFR.Quantity = 1;
						vFR.Price = ?(vAmount >=0, vAmount, -vAmount);
						// Do registration
						If vAmount >= 0 Then
							vFR.Registration();
						Else
							vFR.Return();
						EndIf;
						If vFR.ResultCode <> 0 Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;	
					EndIf;
				Else
					vVATAmount = pObj.VATSum;
					If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
						vVATAmount = -vVATAmount;
					EndIf;
					// Print name, price and quantity
					vFR.Name = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
					If Not vArrCashRegister.PrintFolioHeader Then
						vFR.Name = "#" + TrimAll(pObj.Number);
					EndIf;
					vFR.Department = 0;
					If ValueIsFilled(pObj.PaymentSection) Then
						vFR.Department = tcOnServer.cmGetAttributeByRef(pObj.PaymentSection, "Code");
						If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
							If vArrCashRegister.PrintFolioHeader Then
								vFR.Name = GetString(tcOnServer.cmGetAttributeByRef(pObj.PaymentSection, "Description"), vArrCashRegister);
							Else
								vFR.Name = GetString(TrimR(vFR.Name) + " - " + tcOnServer.cmGetAttributeByRef(pObj.PaymentSection, "Description"), vArrCashRegister);
							EndIf;
						EndIf;
					EndIf;
					vFR.Quantity = 1;
					vFR.Price = ?(pSum >= 0, pSum, -pSum);
					// Do registration
					If pSum >= 0 Then
						vFR.Registration();
					Else
						vFR.Return();
					EndIf;
					If vFR.ResultCode <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;	
				EndIf;
			EndIf;
			
			// Print VAT sum if neccessary
			If vArrCashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT"), False);
				If vNoVAT Then
					vFR.Caption = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"), vArrCashRegister);
				Else
					vFR.Caption = GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="), vArrCashRegister);
				EndIf;
				vFR.PrintString();
				If vFR.ResultCode <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			ElsIf vArrCashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				vFR.Caption = GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"), vArrCashRegister);
				vFR.PrintString();
				If vFR.ResultCode <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				vFR.TypeClose = vArrPaymentMethod.CashRegisterChequeCloseType;
			Else
				vFR.TypeClose = 0;
			EndIf;
			vOpenDrawer = False;
			If vFR.TypeClose = 0 Then
				vOpenDrawer = True;
			EndIf;
			vFR.CloseCheck();
			If vFR.ResultCode <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Log cash register operation
			vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
			           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
			           NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "Description")) + 
			           NStr("ru = ' пробит кассовый чек'; en = ' cheque was issued'; de = ' cheque was issued'");
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"),,,,vMessage);
			
			// Open drawer
			Try
				If vOpenDrawer Then
					vFR.OpenDrawer();
				EndIf;
			Except
			EndTry;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCheque

// -----------------------------------------------------------------------------
Function GetString(pStr, pArrCashRegister)
	vChequeWidth = pArrCashRegister.ChequeWidth;
	If vChequeWidth > 0 Then
		Return Left(pStr, vChequeWidth);
	Else
		Return Left(pStr, 24);
	EndIf;
EndFunction // GetString

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.ResultDescription);
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,,"Result code: " + pFR.ResultCode + ", result description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure PrintSlipLines(pFR, pSlipTextArr, pArrCashRegister, pOneCopyOnly = False)
	vArrCashRegister = pArrCashRegister;
	// Print first slip for the hotel
	For Each vStr In pSlipTextArr Do
		pFR.TextWrap = 0;
		pFR.Caption = vStr;
		pFR.PrintString();
		If pFR.ResultCode <> 0 Then
			Return;
		EndIf;
	EndDo;
	If pOneCopyOnly Then
		pFR.TextWrap = 0;
		pFR.Caption = " ";
		pFR.PrintString();
		Return;
	EndIf;
	// Print second slip for the client
	pFR.TextWrap = 0;
	pFR.Caption = " ";
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.TextWrap = 0;
	pFR.Caption = GetString("-8<--------------------------------------------------------------------",vArrCashRegister);
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.TextWrap = 0;
	pFR.Caption = " ";
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.TextWrap = 0;
	pFR.Caption = " ";
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.TextWrap = 0;
	pFR.Caption = " ";
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.TextWrap = 0;
	pFR.Caption = " ";
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.PartialCut();
	pFR.TextWrap = 0;
	pFR.Caption = NStr("ru='ДЛЯ КЛИЕНТА'; en='FOR THE CLIENT'; de='FÜR DEN KUNDEN'");
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	For Each vStr In pSlipTextArr Do
		pFR.TextWrap = 0;
		pFR.Caption = vStr;
		pFR.PrintString();
		If pFR.ResultCode <> 0 Then
			Return;
		EndIf;
	EndDo;
EndProcedure // PrintSlipLines

// -----------------------------------------------------------------------------
Procedure PrintFolioHeader(pFR, pObj, pArrCashRegister)
	vArrCashRegister= pArrCashRegister;
	// Header start delimeter
	pFR.TextWrap = 0;
	pFR.Caption = GetString("-----------------------------------------------------------------------",vArrCashRegister);
	pFR.PrintString();
	// Folio #                                                                      
	pFR.TextWrap = 0;
	vFolioRef = pObj.Folio;
	vFolioNumber = tcOnServer.cmGetAttributeByRef(vFolioRef, "Number");
	pFR.Caption = GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio Nr. '") + tcOnServer.GetDocumentNumberPresentation(vFolioNumber), vArrCashRegister);
	pFR.PrintString();
	// Room
	If Not pArrCashRegister.DoNotPrintRoom Then
		pFR.TextWrap = 0;
		pFR.Caption = GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer:'") + TrimAll(tcOnServer.cmGetAttributeByRef(tcOnServer.cmGetAttributeByRef(vFolioRef, "Room"), "Description")), vArrCashRegister); 
		pFR.PrintString();
	EndIf;
	// Guest
	If Not pArrCashRegister.DoNotPrintClient Then
		pFR.TextWrap = 0;
		If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) And ValueIsFilled(pObj.Payer) Then
			pFR.Caption = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Payer, "Description")), vArrCashRegister);
		Else
			pFR.Caption = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(tcOnServer.cmGetAttributeByRef(tcOnServer.cmGetAttributeByRef(vFolioRef, "Client"), "Description")), vArrCashRegister);
		EndIf;
		pFR.PrintString();
	EndIf;
	// Guest group
	pFR.TextWrap = 0;
	pFR.Caption = GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.GuestGroup, "Code")), vArrCashRegister); 
	pFR.PrintString();
	// Document
	pFR.TextWrap = 0;                                                                 
	pFR.Caption = GetString(NStr("ru = 'Док.  № '; en='Doc.  # '; de='Dok.  Nr. '") + tcOnServer.GetDocumentNumberPresentation(pObj.Number), vArrCashRegister);
	pFR.PrintString();
	// Header end delimeter
	pFR.TextWrap = 0;
	pFR.Caption = GetString("-----------------------------------------------------------------------", vArrCashRegister); 
	pFR.PrintString();
EndProcedure // PrintFolioHeader

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, rMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,, "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function pmPrintNonFiscalCheque(pSum, pVATSum, pObj, pChequeTemplate, rMessage, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, False);
			
			// Set mode
			vFR.Mode = 1;
			vFR.Password = pPasswordKKM;
			vFR.SetMode();
			If vFR.ResultCode <> 0 And vFR.ResultCode <> -3822 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
				Return False;
			EndIf;
			
			vChequeType = ?(pSum >= 0, "ПРИХОД", "ВОЗВРАТ ПРИХОДА");
			
			// Convert cheque template to the array of strings
			vTextArr = tcCashRegisters.GetTextLinesArray(pChequeTemplate);
			
			// Print all strings in the array
			vDoPrintClicheAtEnd = False;
			
			// Print first slip for the hotel
			i = 0;
			For Each vStr In vTextArr Do
				i = i + 1;
				If vStr = "&Cliche" And i = 1 Then
					vFR.PrintHeader();
					If vFR.ResultCode <> 0 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf vStr = "&Cliche" And i = vTextArr.Count() Then
					vDoPrintClicheAtEnd = True;
					Continue;
				ElsIf vStr = "&FolioHeader" Then
					Try
						PrintFolioHeader(vFR, pObj, vArrCashRegister);
						If vFR.ResultCode <> 0 Then
							ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
							Return False;
						EndIf;
					Except
					EndTry;
				Else
					vStr = StrReplace(vStr, "&Type", vChequeType);
					vStr = StrReplace(vStr, "&CurrentDate", Format(CurrentDate(), "DF=dd.MM.yyyy"));
					vStr = StrReplace(vStr, "&CurrentTime", Format(CurrentDate(), "DF=HH:mm"));
					Try
						vStr = StrReplace(vStr, "&Document", ?(pSum >= 0, "Предварительный счет", "Возврат по платежу") + " № " + TrimAll(pObj.Number));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Hotel", tcCashRegisters.GetHotelPrintName(pObj.Hotel));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Currency", TrimAll(pObj.PaymentCurrency));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&VATRate", TrimAll(pObj.VATRate));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Cashier", tcCashRegisters.GetCashierName(pObj.Author));
					Except
					EndTry;
					vStr = StrReplace(vStr, "&Amount", Format(?(pSum < 0, -pSum, pSum), "NFD=2"));
					vFR.TextWrap = 0;
					vFR.Caption = GetString(vStr, vArrCashRegister);
					vFR.PrintString();
					If vFR.ResultCode <> 0 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndDo;
			
			// Print cliche
			If vDoPrintClicheAtEnd Then
				vFR.PrintHeader();
				If vFR.ResultCode <> 0 Then
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
					Return False;
				EndIf;
			Else
				For s = 0 To 5 Do
					vFR.Caption = " ";
					vFR.PrintString();
				EndDo;
			EndIf;
			
			// Cut off cheque
			vFR.FullCut();
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintNonFiscalCheque

// -----------------------------------------------------------------------------
Function pmPrintZReport(rMessage,pObj,pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR);
			// Do report
			vFR.Mode = 3;
			vFRPassword = pPasswordKKM;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			vFR.ReportType = 1;
			vFR.Report();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), , , , rMessage);
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
 			// Check time difference between workstation and cash register and correct 
			// device time if difference is more then 5 minutes
			If Not CheckTimeDifference(vFR, rMessage) Then
				Return False;
			EndIf;
			// Open new session
			If Not vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				vFR.Mode = 1;
				vFR.Caption = "";
				vFR.Password = "";
				vFR.OpenSession();
				tcOnServer.Wait(5);
			EndIf;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintZReport

// -----------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage, pObj, pPasswordKKM="") Export
	rMessage = NStr("en='Not supported!'; ru='Не поддерживается!'; de='Not supported!'");
	Return False;
EndFunction // pmPrintCurrentStateOfCalculationsReport

// -----------------------------------------------------------------------------
Function CheckTimeDifference(pFR, rMessage)
	pFR.GetStatus();
	If pFR.ResultCode = 0 Then
		vFRDate = Date(pFR.Year, pFR.Month, pFR.Day, pFR.Hour, pFR.Minute, pFR.Second);
		If BegOfDay(CurrentDate()) = BegOfDay(vFRDate) Then
			vTimeDiff = CurrentDate() - vFRDate;
			If vTimeDiff < 0 Then 
				vTimeDiff = -vTimeDiff;
			EndIf;
			If vTimeDiff > 300 Then // > 5 minutes
				// Set current time
				Return SetDeviceTime(pFR, rMessage);
			EndIf;
		Else
			// Date is different, need to set correct date manually
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Check date in the cash register!'; de='Überprüfen Datum im Kasse!'; ru='Проверьте дату в ККМ!'"));
		EndIf;
	Else
		ProcessResultCode(pFR, NStr("en='CashRegister.CheckTimeDifference'; de='CashRegister.CheckTimeDifference'; ru='ККМ.ПроверкаВремени'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // CheckTimeDifference

// -----------------------------------------------------------------------------
Function SetDeviceTime(pFR, rMessage)
	vCurDate = tcOnServer.cmGetServerCurrentSessionDate();
	// Connect
	If pFR.DeviceEnabled = 0 Then
		pFR.DeviceEnabled = 1;
	EndIf;
	
	// Set device date
	pFR.Day = Day(vCurDate);
	pFR.Month = Month(vCurDate);
	pFR.Year = Year(vCurDate);
	pFR.SetDate();
	If pFR.ResultCode <> 0 Then
		If pFR.ResultCode = -3893 Then
			// Confirm date change
			pFR.SetDate();
			If pFR.ResultCode <> 0 Then
				ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
				Return False;
			EndIf;
		Else
			ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
			Return False;
		EndIf;
	EndIf;
	
	// Set device time
	pFR.Hour = Hour(vCurDate);
	pFR.Minute = Minute(vCurDate);
	pFR.Second = Second(vCurDate);
	pFR.SetTime();
	If pFR.ResultCode <> 0 Then
		ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // SetDeviceTime

// -----------------------------------------------------------------------------
Function pmPrintXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);

	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR);
			// Do report
			vFR.Mode = 2;
			vFRPassword = pPasswordKKM;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			vFR.ReportType = 2;
			vFR.Report();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), , , , rMessage);
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintXReport

// -----------------------------------------------------------------------------
Function pmPrintHourXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR);
			// Do report
			vFR.Mode = 2;
			vFRPassword = pPasswordKKM;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			vFR.ReportType = 10;
			vFR.Report();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"),  ,  ,  , rMessage);
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintHourXReport

// -----------------------------------------------------------------------------
Function pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, pPasswordKKM="", pOneCopyOnly = False) Export
	If TypeOf(pCashRegister) = Type("Structure") Then  
		vArrCashRegister = pCashRegister;
	Else 
		vArrCashRegister =  tcOnServer.cmGetAtributeAsArray(pCashRegister);
	EndIf;

	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);

	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR);
			// Check demo mode
			If vFR.IsDemo = 1 Then
				Raise NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'");
			EndIf;
			// Set mode
			vFR.Mode = 1;
			vFRPassword = TrimAll(pPasswordKKM);
			If vFRPassword = Undefined Then
				Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
				Return False;
			EndIf;
			// Print all strings in the array
			PrintSlipLines(vFR, pSlipTextArr, vArrCashRegister, pOneCopyOnly);
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
				Return False;
			EndIf;
			// Print cheque header
			vFR.PrintHeader();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
				Return False;
			EndIf;
			vFR.FullCut();
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintSlip

// -----------------------------------------------------------------------------
Function pmPrintCashIncome(Val pSum, pObj, rMessage, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, vArrCashRegister.DoNotOpenNewSessionAfterZReport);
			
			// Check demo mode
			If vFR.IsDemo = 1 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'"));
				Return False;
			EndIf;
			
			// Set mode and password
			vFR.Mode = 1;
			vFR.Password = pPasswordKKM;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;	
			
			// Do cash income
			vFR.Summ = pSum;
			vFR.CashIncome();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;	
			
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCashIncome

// -----------------------------------------------------------------------------
Function pmPrintCashOutcome(Val pSum, pObj, rMessage, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, vArrCashRegister.DoNotOpenNewSessionAfterZReport);
			
			// Check demo mode
			If vFR.IsDemo = 1 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'"));
				Return False;
			EndIf;
			
			// Set mode
			vFR.Mode = 1;
			vFR.Password = pPasswordKKM;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;	
			
			// Do cash outcome
			vFR.Summ = pSum;
			vFR.CashOutcome();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;	
			
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCashOutcome

// -----------------------------------------------------------------------------
Function pmOpenCashDrawer(rMessage, pCashRegister) Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else 
		// Close open cheque if any
		CloseOpenCheque(vFR, , vArrCashRegister.DoNotOpenNewSessionAfterZReport);
		// Check demo mode
		If vFR.IsDemo = 1 Then
			rMessage = NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Open drawer
		Try
			vFR.OpenDrawer();
		Except
			rMessage = ErrorDescription();
			Disconnect(vFR);
			Return false;
		EndTry;		
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmOpenCashDrawer
