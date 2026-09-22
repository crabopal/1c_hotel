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
// Description: Returns positive decimal number representing binary string
// Parameters: Binary number presentation as string
// Return value: Decimal number
// -----------------------------------------------------------------------------
Function Bin2Dec(pBin)
	vDec = 0;
	vLen = StrLen(pBin);
	For i = 1 To vLen Do
		vDec = vDec + Number(Mid(pBin, i, 1)) * Pow(2, (vLen - i));
	EndDo;
	Return vDec;
EndFunction // Bin2Dec

// -----------------------------------------------------------------------------
Function GetTaxationSystemCode(pObj, rTaxSystem = Undefined)
	rTaxSystem = Undefined;
	vTaxSystemChar = "";
	vPaymentSection = pObj.PaymentSection;
	If ValueIsFilled(vPaymentSection) Then
		rTaxSystem = tcOnServer.cmGetAttributeByRef(vPaymentSection, "TaxationSystem");
	ElsIf TypeOf(pObj.Ref) <> Type("DocumentRef.CustomerPayment") Then
		For Each vPaymentSectionRow In pObj.PaymentSections Do
			vPaymentSection = vPaymentSectionRow.PaymentSection;
			If vPaymentSectionRow.Sum <> 0 And ValueIsFilled(vPaymentSection) Then
				rTaxSystem = tcOnServer.cmGetAttributeByRef(vPaymentSection, "TaxationSystem");
				If ValueIsFilled(rTaxSystem) Then
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(rTaxSystem) And ValueIsFilled(pObj.Company) Then
		rTaxSystem = tcOnServer.cmGetAttributeByRef(pObj.Company, "TaxationSystem");
	EndIf;
	If ValueIsFilled(rTaxSystem) Then
		vTaxSystemByte = "00000000";
		If rTaxSystem = PredefinedValue("Enum.TaxationSystems.Common") Then
			vTaxSystemByte = "00000001";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncome") Then
			vTaxSystemByte = "00000010";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncomeMinusOutcome") Then
			vTaxSystemByte = "00000100";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedTaxOnImputedIncome") Then
			vTaxSystemByte = "00001000";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedAgriculturalTax") Then
			vTaxSystemByte = "00010000";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.PatentTaxationSystem") Then
			vTaxSystemByte = "00100000";
		EndIf;
		vTaxSystemDec = Bin2Dec(vTaxSystemByte);
		If vTaxSystemDec > 0 Then
			vTaxSystemChar = String(vTaxSystemDec);
		EndIf;			
	EndIf;
	Return vTaxSystemChar;
EndFunction // GetTaxationSystemCode

// -----------------------------------------------------------------------------
Function GetTaxGroup(pObj, rVATRate = Undefined, pRowVATRate = Undefined)
	rVATRate = Undefined;
	If ValueIsFilled(pRowVATRate) Then
		rVATRate = pRowVATRate;
	Else
		If TypeOf(pObj) = Type("FormDataStructure") Then
			rVATRate = pObj.VATRate;
		Else
			rVATRate = tcOnServer.cmGetAttributeByRef(pObj, "VATRate");
		EndIf;
	EndIf;
	If ValueIsFilled(rVATRate) Then
		vTaxRate = tcOnServer.cmGetAttributeByRef(rVATRate, "TaxRate");
		vNoVAT = tcOnServer.cmGetAttributeByRef(rVATRate, "NoVAT");
		vTaxGroup = 0;
		If vNoVAT Then
			vTaxGroup = 4;
		Else
			If vTaxRate = 0 Then
				vTaxGroup = 1;
			ElsIf vTaxRate = 10 Then
				vTaxGroup = 2;
			ElsIf vTaxRate = 20 Or vTaxRate = 18 Then
				vTaxGroup = 3;
			Else
				vTaxGroup = 6;
			EndIf;
		EndIf;
		Return vTaxGroup;
	Else
		Return 0;
	EndIf;
EndFunction // GetTaxGroup

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
			vFR.AccessPassword = "";
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
		If vFR.OutOfPaper = 1 And Not vArrCashRegister.IgnoreEndOfPaperError Then
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
Procedure CloseOpenCheque(pFR, pPasswordKKM="", pOpenSessionIfClosed = False, pIgnoreEndOfPaperError = False)
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
			ElsIf pFR.CheckPaperPresent = 0 And Not pIgnoreEndOfPaperError Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Cheque ribbon is almost over!'; de='Scheck Band ist fast vorbei!'; ru='В ККМ заканчивается бумага!'"), MessageStatus.Attention);
			EndIf;
			If pOpenSessionIfClosed Then
				If pFR.SessionOpened = 0 Then
					// Set cashier name
					vCashier = tcOnServer.cmGetCurrentUserAttribute();
					If ValueIsFilled(vCashier) Then
						vCashierName = tcCashRegisters.GetCashierName(vCashier);
						If Not IsBlankString(vCashierName) Then
							pFR.AttrNumber = 1021;
							pFR.AttrValue = vCashierName;
							pFR.WriteAttribute();
							
							// Set TIN
							vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
							If Not IsBlankString(vEmployeeTIN) Then
								pFR.AttrNumber = 1203;
								pFR.AttrValue = vEmployeeTIN;
								pFR.WriteAttribute();
							EndIf;
						EndIf;
					EndIf;
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
	vIsPrepayment = False;
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError);
			
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
			If Not pIsCorrection Then
				If pSum < 0 Or pSum = 0 And TypeOf(pObjRef) = Type("DocumentRef.Return") Then
					vFR.CheckType = 2;
				Else
					vFR.CheckType = 1;
				EndIf;
			Else
				If pSum < 0 Or pSum = 0 And TypeOf(pObjRef) = Type("DocumentRef.Return") Then
					vFR.CheckType = 8;
				Else
					vFR.CheckType = 7;
				EndIf;
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
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = tcCashRegisters.InitializeChequeAttributes(pObj, pObjRef, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				vFR.AttrNumber = 1173;
				vFR.AttrValue = ?(pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder"), 1, 0);
				vFR.WriteAttribute();
				vChequeAttributes.CorrectionType = pCorrectionType;
				If ValueIsFilled(pCorrectionDocumentDate) Or Not IsBlankString(pCorrectionDocumentNumber) Then
					vFR.AttrNumber = 1174;
					vFR.BeginComplexAttribute();
					If ValueIsFilled(pCorrectionDocumentDate) Then
						vFR.AttrNumber = 1178;
						vFR.AttrValue = (pCorrectionDocumentDate - '19700101');
						vFR.WriteAttribute();
						vChequeAttributes.CorrectionDocumentDate = pCorrectionDocumentDate;
					EndIf;
					If Not IsBlankString(pCorrectionDocumentNumber) Then
						vFR.AttrNumber = 1179;
						vFR.AttrValue = Right(TrimAll(pCorrectionDocumentNumber), 32);
						vFR.WriteAttribute();
						vChequeAttributes.CorrectionDocumentNumber = pCorrectionDocumentNumber;
					EndIf;
					vFR.EndComplexAttribute();
				EndIf;
			EndIf;				
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemCode = GetTaxationSystemCode(pObj, vTaxSystem);
			If Not IsBlankString(vTaxSystemCode) Then
				vFR.AttrNumber = 1055;
				vFR.AttrValue = vTaxSystemCode;
				vFR.WriteAttribute();
				vChequeAttributes.TaxationSystem = vTaxSystem;
			EndIf;
			
			// Set cashier name
			vCashier = pObj.Author;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.AttrNumber = 1021;
					vFR.AttrValue = vCashierName;
					vFR.WriteAttribute();
					vChequeAttributes.CashierName = vCashierName;
					
					// Set TIN
					vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
					If Not IsBlankString(vEmployeeTIN) Then
						vFR.AttrNumber = 1203;
						vFR.AttrValue = vEmployeeTIN;
						vFR.WriteAttribute();
					EndIf;
				EndIf;
			EndIf;
			
			// Payer name and TIN
			vPayerName = "";
			vPayerTIN = "";
			tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			If Not IsBlankString(vPayerTIN) And Not IsBlankString(vPayerName) Then
				vFR.AttrNumber = 1227;
				vFR.AttrValue = vPayerName;
				vFR.WriteAttribute();
				
				vFR.AttrNumber = 1228;
				If StrLen(vPayerTIN) = 10 Then
					vFR.AttrValue = vPayerTIN + "  ";
				Else
					vFR.AttrValue = vPayerTIN;
				EndIf;
				vFR.WriteAttribute();
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
			If Not pIsCorrection Then
				If Not vArrCashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
					For Each vSrvRow In pServices Do
						// Begin format 1.05 item 
						vFR.BeginItem();
						vFR.TestMode = False;
						vFR.EnableCheckSumm = False;
						vFR.TaxMode = 0;
						// Commissioner mark
						If ValueIsFilled(vSrvRow.Service) Then
							vIsAgentService = tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "IsAgentService");
							If vIsAgentService Then
								// Commissioner attribute
								vFR.AttrNumber = 1222;
								If tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "PrincipalType") = 1 Then
									vFR.AttrValue = 64; // 64 - other agent
								Else
									vFR.AttrValue = 32; // 32 - Commission agent
								EndIf;
								vFR.WriteAttribute();
								// Principal
								vPrincipal = tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "Principal");
								If ValueIsFilled(vPrincipal) Then
									vPrincipalTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "TIN"));
									vPrincipalName = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "LegacyName"));
									vPrincipalPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "Phone"));
									If Not IsBlankString(vPrincipalTIN) Then
										vFR.AttrNumber = 1226; 
										If StrLen(vPrincipalTIN) = 10 Then
											vFR.AttrValue = vPrincipalTIN + "  ";
										Else
											vFR.AttrValue = vPrincipalTIN;
										EndIf;
										vFR.WriteAttribute();
									EndIf;
									If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
										vFR.AttrNumber = 1224;
										vFR.BeginComplexAttribute();
										vFR.AttrNumber = 1225;
										vFR.AttrValue = vPrincipalName;
										vFR.WriteAttribute();
										vFR.AttrNumber = 1171;
										vFR.AttrValue = vPrincipalPhone;
										vFR.WriteAttribute();
										vFR.EndComplexAttribute();
									EndIf;
								EndIf;
							EndIf;
						EndIf;
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
						vFR.Summ = vSrvRow.Amount;
						vItemPrice = vSrvRow.Price;
						vItemQuantity = vSrvRow.Quantity;
						tcCashRegisters.ChequeItemAttributesCorrection(vFR.Summ, vItemQuantity, 3, vItemPrice, vItemQuantity);
						vFR.Price = vItemPrice;
						vFR.Quantity = vItemQuantity;
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(vPaymentSection) Then
							vFR.TaxTypeNumber = GetTaxGroup(vPaymentSection, vVATRate, vSrvRow.VATRate);
						Else
							vFR.TaxTypeNumber = GetTaxGroup(pObj, vVATRate, vSrvRow.VATRate);
						EndIf;
						tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRAte, vSrvRow.VATSum);
						// Fill format 1.05 attributes and end item
						vFR.ItemType = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, vSrvRow.Service, vSrvRow.PaymentSection));
						vFR.PaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
						vFR.EndItem();
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
						vPSRows = tcCashRegisters.GetPrintableChequePositions(pObj, vIsPrepayment, vArrCashRegister.AlwaysUseAveragePrice);
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
								// Begin format 1.05 item 
								vFR.BeginItem();
								vFR.TestMode = False;
								vFR.EnableCheckSumm = False;
								vFR.TaxMode = 0;
								// Print name, price and quantity
								If ValueIsFilled(vPSRow.ChequeService) Then
									// Commissioner mark
									vIsAgentService = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "IsAgentService");
									If vIsAgentService Then
										// Commissioner attribute
										vFR.AttrNumber = 1222;
										If tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "PrincipalType") = 1 Then
											vFR.AttrValue = 64; // 64 - other agent
										Else
											vFR.AttrValue = 32; // 32 - Commission agent
										EndIf;
										vFR.WriteAttribute();
										// Principal
										vPrincipal = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Principal");
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "TIN"));
											vPrincipalName = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "LegacyName"));
											vPrincipalPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "Phone"));
											If Not IsBlankString(vPrincipalTIN) Then
												vFR.AttrNumber = 1226; 
												If StrLen(vPrincipalTIN) = 10 Then
													vFR.AttrValue = vPrincipalTIN + "  ";
												Else
													vFR.AttrValue = vPrincipalTIN;
												EndIf;
												vFR.WriteAttribute();
											EndIf;
											If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
												vFR.AttrNumber = 1224;
												vFR.BeginComplexAttribute();
												vFR.AttrNumber = 1225;
												vFR.AttrValue = vPrincipalName;
												vFR.WriteAttribute();
												vFR.AttrNumber = 1171;
												vFR.AttrValue = vPrincipalPhone;
												vFR.WriteAttribute();
												vFR.EndComplexAttribute();
											EndIf;
										EndIf;
									EndIf;
									// Item main attributes
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vFR.Department = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
									Else
										vFR.Department = 0;
									EndIf;
									vFR.Name = GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vArrCashRegister);
									vFR.Summ = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									tcCashRegisters.ChequeItemAttributesCorrection(vFR.Summ, vItemQuantity, 3, vItemPrice, vItemQuantity);
									vFR.Price = vItemPrice;
									vFR.Quantity = vItemQuantity;
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.Department = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
									vFR.Name = GetString(tcOnServer.cmGetPaymentSectionDescription(vPSRow.PaymentSection), vArrCashRegister);
									vFR.Summ = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vFR.Price = vFR.Summ;
									vFR.Quantity = 1;
								Else
									vFR.Department = 0;
									If vSectionAmount >=0 Then
										vFR.Name = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
									Else
										vFR.Name = NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'");
									EndIf;
									vFR.Summ = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vFR.Price = vFR.Summ;
									vFR.Quantity = 1;
								EndIf;
								// Add tax
								vVATRate = Undefined;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.TaxTypeNumber = GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate);
								Else
									vFR.TaxTypeNumber = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate);
								EndIf;
								tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, vPSRow.VATSum);
								// Fill format 1.05 attributes and end item
								vFR.ItemType = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
								vFR.PaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
								vFR.EndItem();
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
								// Begin format 1.05 item 
								vFR.BeginItem();
								vFR.TestMode = False;
								vFR.EnableCheckSumm = False;
								vFR.TaxMode = 0;
								// Print name, price and quantity
								If ValueIsFilled(vPSRow.ChequeService) Then
									// Commissioner mark
									vIsAgentService = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "IsAgentService");
									If vIsAgentService Then
										// Commissioner attribute
										vFR.AttrNumber = 1222;
										If tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "PrincipalType") = 1 Then
											vFR.AttrValue = 64; // 64 - other agent
										Else
											vFR.AttrValue = 32; // 32 - Commission agent
										EndIf;
										vFR.WriteAttribute();
										// Principal
										vPrincipal = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Principal");
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "TIN"));
											vPrincipalName = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "LegacyName"));
											vPrincipalPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "Phone"));
											If Not IsBlankString(vPrincipalTIN) Then
												vFR.AttrNumber = 1226; 
												If StrLen(vPrincipalTIN) = 10 Then
													vFR.AttrValue = vPrincipalTIN + "  ";
												Else
													vFR.AttrValue = vPrincipalTIN;
												EndIf;
												vFR.WriteAttribute();
											EndIf;
											If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
												vFR.AttrNumber = 1224;
												vFR.BeginComplexAttribute();
												vFR.AttrNumber = 1225;
												vFR.AttrValue = vPrincipalName;
												vFR.WriteAttribute();
												vFR.AttrNumber = 1171;
												vFR.AttrValue = vPrincipalPhone;
												vFR.WriteAttribute();
												vFR.EndComplexAttribute();
											EndIf;
										EndIf;
									EndIf;
									// Item main attributes
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vFR.Department = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
									Else
										vFR.Department = 0;
									EndIf;
									vFR.Name = GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vArrCashRegister);
									vFR.Summ = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									tcCashRegisters.ChequeItemAttributesCorrection(vFR.Summ, vItemQuantity, 3, vItemPrice, vItemQuantity);
									vFR.Price = vItemPrice;
									vFR.Quantity = vItemQuantity;
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.Department = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
									vFR.Name = GetString(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Code"), vArrCashRegister);
									vFR.Summ = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vFR.Price = vFR.Summ;
									vFR.Quantity = 1;
								Else
									vFR.Department = 0;
									If vSectionAmount >=0 Then
										vFR.Name = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
									Else
										vFR.Name = NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'");
									EndIf;
									vFR.Summ = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vFR.Price = vFR.Summ;
									vFR.Quantity = 1;
								EndIf;
								// Add tax
								vVATRate = Undefined;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.TaxTypeNumber = GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate);
								Else
									vFR.TaxTypeNumber = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate);
								EndIf;
								tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, vPSRow.VATSum);
								// Fill format 1.05 attributes and end item
								vFR.ItemType = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
								vFR.PaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
								vFR.EndItem();
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
							// Begin format 1.05 item 
							vFR.BeginItem();
							vFR.TestMode = False;
							vFR.EnableCheckSumm = False;
							vFR.TaxMode = 0;
							// Print name, price and quantity
							vFR.Department = 0;
							vFR.Name = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
							vFR.Price = ?(vAmount < 0, -vAmount, vAmount);
							vFR.Summ = vFR.Price;
							vFR.Quantity = 1;
							// Add tax
							vVATRate = Undefined;
							vFR.TaxTypeNumber = GetTaxGroup(pObj, vVATRate);
							tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >=0, vVATAmount, -vVATAmount));
							// Fill format 1.05 attributes and end item
							vFR.ItemType = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined));
							vFR.PaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
							vFR.EndItem();
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
						// Begin format 1.05 item 
						vFR.BeginItem();
						vFR.TestMode = False;
						vFR.EnableCheckSumm = False;
						vFR.TaxMode = 0;
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
									vFR.Name = GetString(tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
								Else
									vFR.Name = GetString(TrimR(vFR.Name) + " - " + tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
								EndIf;
							EndIf;
						EndIf;
						vFR.Quantity = 1;
						vFR.Summ = ?(pSum < 0, -pSum, pSum);
						vFR.Price = vFR.Summ;
						// Add tax
						vVATRate = Undefined;
						vFR.TaxTypeNumber = GetTaxGroup(pObj, vVATRate);
						tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >= 0, vVATAmount, -vVATAmount));
						// Fill format 1.05 attributes and end item
						vFR.ItemType = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined));
						vFR.PaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
						vFR.EndItem();
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
			Else // Correction cheque
				vVATAmount = pObj.VATSum;
				If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
					vVATAmount = -vVATAmount;
				EndIf;
				// Begin format 1.05 item 
				vFR.BeginItem();
				vFR.TestMode = False;
				vFR.EnableCheckSumm = False;
				vFR.TaxMode = 0;
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
							vFR.Name = GetString(tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
						Else
							vFR.Name = GetString(TrimR(vFR.Name) + " - " + tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
						EndIf;
					EndIf;
				EndIf;
				vFR.Quantity = 1;
				vFR.Price = ?(pSum < 0, -pSum, pSum);
				vFR.Summ = vFR.Price;
				// Add tax
				vVATRate = Undefined;
				vFR.TaxTypeNumber = GetTaxGroup(pObj, vVATRate);
				tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >= 0, vVATAmount, -vVATAmount));
				// Fill format 1.05 attributes and end item
				vFR.ItemType = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined));
				vFR.PaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection, vIsPrepayment));
				vFR.EndItem();
				If vFR.ResultCode <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;	
			EndIf;
			
			// Transfer client e-mail
			vEMail = "";
			vPayer = Undefined;
			If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) Then
				If ValueIsFilled(pObj.Payer) Then
					vPayer = pObj.Payer;
				EndIf;
			EndIf;
			If ValueIsFilled(vPayer) Then
				If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
					vEMail = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "EMail"));
				EndIf;
			EndIf;
			If Not IsBlankString(vEMail) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
				vFR.AttrNumber = 1008;
				vFR.AttrValue = vEMail;
				vFR.WriteAttribute();
				If vFR.ResultCode <> 0 And vFR.ResultCode <> -12 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				If pObj.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
					vFR.TypeClose = 2;
				ElsIf vArrPaymentMethod.IsByCash Then
					vFR.TypeClose = 0;
				ElsIf vArrPaymentMethod.IsByCreditCard Or vArrPaymentMethod.IsByBankTransfer Or vArrPaymentMethod.IsViaInternetAcquiring Then
					vFR.TypeClose = 1;
				Else
					vFR.TypeClose = vArrPaymentMethod.CashRegisterChequeCloseType;
				EndIf;
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
			
			// Get current cheque attributes
			If pSum < 0 Or pSum = 0 And TypeOf(pObjRef) = Type("DocumentRef.Return") Then
				vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.ReceiptReturn");
			Else
				vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.Receipt");
			EndIf;
			vFR.RegisterNumber = 19;
			vFR.GetRegister();
			vChequeAttributes.CashDayChequeNumber = vFR.CheckNumber;
			vFR.RegisterNumber = 47;
			vFR.GetRegister();
			vChequeAttributes.FiscalStorageFactoryNumber = vFR.SerialNumber;
			vFR.RegisterNumber = 52;
			vFR.GetRegister();
			vChequeAttributes.ChequeFiscalNumber = vFR.FiscalSign;
			vChequeAttributes.ChequeSequenceNumber = vFR.DocNumber;
			Try
				vChequeAttributes.ChequeDateTime = Date(vFR.Year, vFR.Month, vFR.Day, vFR.Hour, vFR.Minute, 0);
			Except
			EndTry;
			vFR.RegisterNumber = 53;
			vFR.GetRegister();
			vChequeAttributes.CashDay = vFR.Session;
			
			// Log cash register operation
			vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
			           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
			           NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "Description")) + 
			           NStr("ru = ' пробит кассовый чек'; en = ' cheque was issued'; de = ' cheque was issued'");
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"),,,,vMessage);
			tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
			
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
Function pmPrintNonFiscalCheque(pSum, pVATSum, pObj, pChequeTemplate, rMessage, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, False, vArrCashRegister.IgnoreEndOfPaperError);
			
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
						vStr = StrReplace(vStr, "&Cashier", TrimAll(pObj.Author));
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
Procedure ProcessException(pFR, pFunction, rMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,, "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

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
			CloseOpenCheque(vFR, , , vArrCashRegister.IgnoreEndOfPaperError);
			// Do report
			vFR.Mode = 3;
			vFRPassword = pPasswordKKM;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;
			
			// Set cashier name
			vCashier = tcOnServer.cmGetCurrentUserAttribute();
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.AttrNumber = 1021;
					vFR.AttrValue = vCashierName;
					vFR.WriteAttribute();
					
					// Set TIN
					vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
					If Not IsBlankString(vEmployeeTIN) Then
						vFR.AttrNumber = 1203;
						vFR.AttrValue = vEmployeeTIN;
						vFR.WriteAttribute();
					EndIf;
				EndIf;
			EndIf;
			
			// Close session
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
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
		Try
			vBreakOpenNewSession = False;
 			// Check time difference between workstation and cash register and correct 
			// device time if difference is more then 5 minutes
			If Not CheckTimeDifference(vFR, rMessage) Then
				#IF THINCLIENT THEN
					ShowUserNotification(NStr("en = 'Time setting error in cash register'; de = 'Zeiteinstellungsfehler in der Registrierkassen'; ru = 'Ошибка установки времени в ККМ'"), , rMessage, PictureLib.InformationMedium, UserNotificationStatus.Important, pObj.Ref); 	
				#ENDIF
				vBreakOpenNewSession = True;
			EndIf;
			// Open new session
			If Not vArrCashRegister.DoNotOpenNewSessionAfterZReport And Not vBreakOpenNewSession Then
				// Set cashier name
				If ValueIsFilled(vCashier) Then
					If Not IsBlankString(vCashierName) Then
						vFR.AttrNumber = 1021;
						vFR.AttrValue = vCashierName;
						vFR.WriteAttribute();
						
						// Set TIN
						If Not IsBlankString(vEmployeeTIN) Then
							vFR.AttrNumber = 1203;
							vFR.AttrValue = vEmployeeTIN;
							vFR.WriteAttribute();
						EndIf;
					EndIf;
				EndIf;
				// Open session
				vFR.Mode = 1;
				vFR.Caption = "";
				vFR.Password = "";
				vFR.OpenSession();
				tcOnServer.Wait(5);
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			#IF THINCLIENT THEN
				ShowUserNotification(NStr("en = 'Error opening shift in cash register'; de = 'Fehler beim Öffnen der Schicht in der Registrierkasse'; ru = 'Ошибка открытия смены в ККМ'"), , rMessage, PictureLib.InformationMedium, UserNotificationStatus.Important, pObj.Ref); 	
			#ENDIF
		EndTry;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmPrintZReport

// -----------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage, pObj, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, , , vArrCashRegister.IgnoreEndOfPaperError);
			// Do report
			vFR.Mode = 3;
			vFRPassword = pPasswordKKM;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
				Return False;
			EndIf;	
			vFR.ReportType = 42;
			vFR.Report();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
				Return False;
			EndIf;
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), , , , rMessage);
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
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
			ProcessException(pFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			rMessage = NStr("en='Check date in the cash register!'; de='Überprüfen Datum im Kasse!'; ru='Проверьте дату в ККМ!'");
			Return False;
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
			CloseOpenCheque(vFR, , , vArrCashRegister.IgnoreEndOfPaperError);
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
			CloseOpenCheque(vFR, , , vArrCashRegister.IgnoreEndOfPaperError);
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
			CloseOpenCheque(vFR, , , vArrCashRegister.IgnoreEndOfPaperError);
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
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError);
			
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
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError);
			
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
		CloseOpenCheque(vFR, , vArrCashRegister.DoNotOpenNewSessionAfterZReport, True);
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