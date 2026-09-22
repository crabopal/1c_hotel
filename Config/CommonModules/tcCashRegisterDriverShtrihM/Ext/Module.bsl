
#Region Public

// -----------------------------------------------------------------------------
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False, pCashRegister) Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else // Cash register was connected
		// Retrieve cash register state
		vFR.GetECRStatus();
		If vFR.ECRMode = 3 Then // Open session, 24 hours finished
			If Not pSkip24HoursLimitWarning Then
				rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
				Disconnect(vFR);
				Return False;
			EndIf;
		ElsIf Not CheckResultCode(vFR.ResultCode) Then
			rMessage = NStr("ru='Ошибка получения состояния ККМ!'; en='Failed to check cash register state!'; de='Failed to check cash register state!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check paper
		If vFR.ReceiptRibbonIsPresent = 0 Then
			rMessage = NStr("ru = 'В ККМ закончилась чековая лента!'; en = 'Cash register is out of paper!'; de = 'Cash register is out of paper!'");
			Disconnect(vFR);
			Return False;
		EndIf;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmIsReadyToPrint

// -----------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	vIsPrepayment = False;

	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister,pPasswordKKM);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;		
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			
			// Open session if is closed
			If vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Тогда
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					Else
						tcOnServer.Wait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Open cheque
			If pSum < 0 Then
            	vFR.CheckType = 2;
			Else
            	vFR.CheckType = 0;
			EndIf;
            vFR.OpenCheck();
			
			// Print cheque
			vFR.UseJournalRibbon = 1;
			vFR.UseReceiptRibbon = 1;
			
			vFR.Tax1 = 0; vFR.Tax2 = 0; vFR.Tax3 = 0; vFR.Tax4 = 0;
			vFR.Summ1 = 0; vFR.Summ2 = 0; vFR.Summ3 = 0; vFR.Summ4 = 0; vFR.Summ5 = 0; vFR.Summ6 = 0; vFR.Summ7 = 0; vFR.Summ8 = 0; vFR.Summ9 = 0; vFR.Summ10 = 0; vFR.Summ11 = 0; vFR.Summ12 = 0; vFR.Summ13 = 0; vFR.Summ14 = 0; vFR.Summ15 = 0; vFR.Summ16 = 0;
			
			// Print slip if payment was made by credit card
			If vArrCashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					PrintSlipLines(vFR, tcOnServer.GetTextLinesArray(pObj.SlipText), vArrCashRegister);
					// Print cheque header
					vFR.PrintHeader();
					If Not CheckResultCode(vFR.ResultCode) Then
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
					// Department and cheque postion
					vPaymentSection = Undefined;
					vFR.Department = 0;
					vFR.StringForPrinting = "";
					If ValueIsFilled(vSrvRow.Service) Then
						vService = vSrvRow.Service;
						vFR.StringForPrinting = GetString(tcOnServer.cmGetServiceDescription(vService), vArrCashRegister);
						vPaymentSection = tcOnServer.cmGetAttributeByRef(vService, "PaymentSection");
						If ValueIsFilled(vPaymentSection) Then
							vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
						EndIf;
					EndIf;
					
					// Do sale
					vFR.Quantity = vSrvRow.Quantity;
					vFR.Price = vSrvRow.Price;
					vFR.Sale();
					If Not CheckResultCode(vFR.ResultCode) Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;	
				EndDo;
			Else
				// Print number and sections
				If pObj.PaymentSections.Count() > 0 Then
					If Not vArrCashRegister.PrintFolioHeader Then
						vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
						vFR.PrintString();
						If Not CheckResultCode(vFR.ResultCode) Then
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
							If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
								vSectionAmount = -vSectionAmount;
							EndIf;
							
							// Department and cheque postion
							vFR.Department = 0;
							vPaymentSection = Undefined;
							vFR.StringForPrinting = NStr("en='Hotel services'; de='Hotel Dienstleistungen'; ru='Гостиничные услуги'");
							If ValueIsFilled(vPSRow.ChequeService) Then
								vPaymentSection = vPSRow.PaymentSection;
								If ValueIsFilled(vPaymentSection) Then
									vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
								EndIf;
								vFR.StringForPrinting = GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vArrCashRegister);
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
								vFR.StringForPrinting = GetString(tcOnServer.cmGetAttributeByRef(vPaymentSection, "Description"), vArrCashRegister);
							Else
								If vSectionAmount >=0 Then
									vFR.StringForPrinting = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"), vArrCashRegister);
								Else
									vFR.StringForPrinting = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"), vArrCashRegister);
								EndIf;
							EndIf;
							
							// Do sale
							If ValueIsFilled(vPSRow.ChequeService) Then
								If vPSRow.ChequeServiceQuantity <> 0 Then
									vFR.Quantity = Round(vPSRow.ChequeServiceQuantity, 6);
								Else
									vFR.Quantity = 1;
								EndIf;
								If vSectionAmount >= 0 Then
									vFR.Price = Round(vSectionAmount / vFR.Quantity, 2);
									If vFR.Price <> 0 Then
										vFR.Quantity = Round(vSectionAmount / vFR.Price, 6);
									EndIf;
									vFR.Sale();
								Else
									vFR.Price = Round(-vSectionAmount / vFR.Quantity, 2);
									If vFR.Price <> 0 Then
										vFR.Quantity = Round(-vSectionAmount / vFR.Price, 6);
									EndIf;
									vFR.ReturnSale();
								EndIf;
							Else
								vFR.Quantity = 1;
								If vSectionAmount >= 0 Then
									vFR.Price = vSectionAmount;
									vFR.Sale();
								Else
									vFR.Price = -vSectionAmount;
									vFR.ReturnSale();
								EndIf;
							EndIf;
							If Not CheckResultCode(vFR.ResultCode) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;	
						EndDo;
					ElsIf Not vArrCashRegister.DoNotPrintPaymentSections Then
						pSum  = 0;
						For Each vPSRow In vPSRows Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								Continue;
							Else
								pSum = pSum + vPSRow.Sum;
							EndIf;
							vSectionAmount = vPSRow.Sum;
							If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
								vSectionAmount = -vSectionAmount;
							EndIf;
							
							// Department and cheque postion
							vPaymentSection = vPSRow.PaymentSection;
							vFR.Department = 0;
							vFR.StringForPrinting = "";
							If ValueIsFilled(vPSRow.ChequeService) Then
								vPaymentSection = vPSRow.PaymentSection;
								If ValueIsFilled(vPaymentSection) Then
									vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
								EndIf;
								vFR.StringForPrinting = GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vArrCashRegister);
							ElsIf ValueIsFilled(vPaymentSection) Then
								vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
								vFR.StringForPrinting = GetString(TrimAll(vFR.Department), vArrCashRegister);
							Else
								If vSectionAmount >=0 Then
									vFR.StringForPrinting = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"), vArrCashRegister);
								Else
									vFR.StringForPrinting = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"), vArrCashRegister);
								EndIf;
							EndIf;
							
							// Do sale
							If ValueIsFilled(vPSRow.ChequeService) Then
								If vPSRow.ChequeServiceQuantity <> 0 Then
									vFR.Quantity = Round(vPSRow.ChequeServiceQuantity, 6);
								Else
									vFR.Quantity = 1;
								EndIf;
								If vSectionAmount >= 0 Then
									vFR.Price = Round(vSectionAmount / vFR.Quantity, 2);
									If vFR.Price <> 0 Then
										vFR.Quantity = Round(vSectionAmount / vFR.Price, 6);
									EndIf;
									vFR.Sale();
								Else
									vFR.Price = Round(-vSectionAmount / vFR.Quantity, 2);
									If vFR.Price <> 0 Then
										vFR.Quantity = Round(-vSectionAmount / vFR.Price, 6);
									EndIf;
									vFR.ReturnSale();
								EndIf;
							Else
								vFR.Quantity = 1;
								If vSectionAmount >= 0 Then
									vFR.Price = vSectionAmount;
									vFR.Sale();
								Else
									vFR.Price = -vSectionAmount;
									vFR.ReturnSale();
								EndIf;
							EndIf;
							If Not CheckResultCode(vFR.ResultCode) Then
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
							Else
								vAmount = vAmount + vPSRow.Sum;
							EndIf;
							vVATAmount = vVATAmount + vPSRow.VATSum;
						EndDo;
						
						// Department and cheque postion
						vFR.Department = 0;
						vFR.StringForPrinting = NStr("en='Hotel services';ru='Услуги гостиницы';de='Hotel Dienstleistungen'");
						
						// Do sale
						vFR.Quantity = 1;
						If vAmount >= 0 Then
							vFR.Price = vAmount;
							vFR.Sale();
						Else
							vFR.Price = -vAmount;
							vFR.ReturnSale();
						EndIf;
						If Not CheckResultCode(vFR.ResultCode) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;	
					EndIf;
				Else
					vFR.StringForPrinting = NStr("en='Hotel services';ru='Услуги гостиницы';de='Hotel Dienstleistungen'");
					If Not vArrCashRegister.PrintFolioHeader Then
						vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
					EndIf;
					
					// Department and cheque postion
					vPaymentSection = Undefined;
					vFR.Department = 0;
					If ValueIsFilled(pObj.PaymentSection) Then
						vPaymentSection = pObj.PaymentSection;
						vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
						If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
							If vArrCashRegister.PrintFolioHeader Then
								vFR.StringForPrinting = GetString(TrimR(vFR.StringForPrinting) + " - " + tcOnServer.cmGetAttributeByRef(vPaymentSection, "Description"), vArrCashRegister);
							Else
								vFR.StringForPrinting = GetString(tcOnServer.cmGetAttributeByRef(vPaymentSection, "Description"), vArrCashRegister);
							EndIf;
						EndIf;
					EndIf;
					
					// Do sale
					vFR.Quantity = 1;
					vFR.Price = ?(pSum >= 0, pSum, -pSum);
					If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
						vFR.ReturnSale();
					Else
						vFR.Sale();
					EndIf;
					If Not CheckResultCode(vFR.ResultCode) Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;	
				EndIf;
			EndIf;
			
			// Print VAT sum if neccessary
			If vArrCashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT"), False);
				If vNoVAT Then
					vFR.StringForPrinting = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"), vArrCashRegister);
				Else
					vFR.StringForPrinting = GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="), vArrCashRegister);
				EndIf;
				vFR.PrintString();
				If Not CheckResultCode(vFR.ResultCode) Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			ElsIf vArrCashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				vFR.StringForPrinting = GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"), vArrCashRegister);
				vFR.PrintString();
				If Not CheckResultCode(vFR.ResultCode) Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			
			// Close cheque
			vTypeClose = 0;
			If ValueIsFilled(pObj.PaymentMethod) Then
				vTypeClose = vArrPaymentMethod.CashRegisterChequeCloseType;
			EndIf;
			vCloseSum = pSum;
			If pSum < 0 Then
				vCloseSum = -pSum;
			EndIf;
			
			vOpenDrawer = False;
			vFR.StringForPrinting = "";
			
			If vTypeClose = 4 Then
				vFR.Summ4 = vCloseSum;
			ElsIf vTypeClose = 3 Then
				vFR.Summ3 = vCloseSum;
			ElsIf vTypeClose = 2 Then
				vFR.Summ2 = vCloseSum;
			Else
				vOpenDrawer = True;
				vFR.Summ1 = vCloseSum;
			EndIf;				
			vFR.CloseCheck();
			If Not CheckResultCode(vFR.ResultCode) Then
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
Function pmPrintZReport(rMessage,pObj,pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister,pPasswordKKM);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;		
			// Check if the session is already closed
			If vFR.ECRMode = 4 Then
				// Session is closed
				rMessage = NStr("ru = 'Смена уже закрыта!'; en = 'Session is already closed!'; de = 'Session is already closed!'");
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"),,,,rMessage);
				Return False;
			EndIf;
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			// Print report
			vFR.PrintReportWithCleaning();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			// Check time difference between workstation and cash register and correct 
			// device time if difference is more then 5 minutes
			vFR.GetECRStatus();
			If CheckResultCode(vFR.ResultCode) Then
				vFRDate = vFR.Date;
				vFRDate = vFRDate + Number(Left(vFR.TimeStr, 2)) * 3600 + Number(Mid(vFR.TimeStr, 4, 2)) * 60 + Number(Mid(vFR.TimeStr, 7, 2));
				If BegOfDay(CurrentDate()) = BegOfDay(vFRDate) Then
					vTimeDiff = CurrentDate() - vFRDate;
					If vTimeDiff < 0 Then 
						vTimeDiff = -vTimeDiff;
					EndIf;
					If vTimeDiff > 300 Then // > 5 minutes
						// Set current time
						Return SetDeviceTime(vFR, rMessage);
					EndIf;
				Else
					// Date is different, need to set correct date manually
					Raise NStr("en='Check date in the cash register!'; de='Check date in the cash register!'; ru='Проверьте дату в ККМ!'");
				EndIf;
			Else
				ProcessResultCode(vFR, NStr("en='CashRegister.CheckTimeDifference'; de='CashRegister.CheckTimeDifference'; ru='ККМ.ПроверкаВремени'"), rMessage);
				Return False;
			EndIf;

			// Open new session
			If Not vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				vFR.OpenSession();
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
Function pmPrintXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister,pPasswordKKM);

	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;		
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			// Do report
			vFR.PrintReportWithoutCleaning();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
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
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintXReport

// -----------------------------------------------------------------------------
Function pmPrintHourXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	rMessage = NStr("ru = 'Печать почасового отчета не поддерживается драйвером!'; en = 'Hourly X Report is not supported by driver!'; de = 'Hourly X Report is not supported by driver!'");
	Return False;
EndFunction // pmPrintHourXReport

// -----------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage,pCashRegister,pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister,pPasswordKKM);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			// Print report
			vFR.FNBuildCalculationStateReport();
			If Not CheckResultCode(vFR.ResultCode) Then
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
Function pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, pPassword, pOneCopyOnly = False) Export
	If TypeOf(pCashRegister) = Type("Structure") Then  
		vArrCashRegister = pCashRegister;
	Else 
		vArrCashRegister =  tcOnServer.cmGetAtributeAsArray(pCashRegister);
	EndIf;

	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister,pPassword);

	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;				
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			
			// Open session if is closed
			If vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				If Not vArrCashRegister.PrintVATSumInCheques And Not vArrCashRegister.PrintInclVATStrInCheques Then
					If vFR.ECRMode = 4 Тогда
						vFR.OpenSession();
						If Not CheckResultCode(vFR.ResultCode) Then
							ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						Else
							tcOnServer.Wait(5);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			// Print all strings in the array
			PrintSlipLines(vFR, pSlipTextArr, vArrCashRegister, pOneCopyOnly);
			If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
				Return False;
			EndIf;
			
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
Function pmPrintNonFiscalCheque(pSum, pVATSum, pObj, pChequeTemplate, rMessage, pPassword="") Export
	vArrCashRegister =  tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);

	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister, pPassword);

	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;				
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			
			vChequeType = ?(pSum >= 0, "ПРИХОД", "ВОЗВРАТ ПРИХОДА");
			
			// Convert cheque template to the array of strings
			vTextArr = tcCashRegisters.GetTextLinesArray(pChequeTemplate);
			
			// Print all strings in the array
			vDoPrintClicheAtEnd = False;
			vFR.UseJournalRibbon=0; 
			vFR.UseReceiptRibbon=1;
			
			// Print first slip for the hotel
			i = 0;
			For Each vStr In vTextArr Do
				i = i + 1;
				If vStr = "&Cliche" And i = 1 Then
					vFR.PrintCliche();
					If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf vStr = "&Cliche" And i = vTextArr.Count() Then
					vDoPrintClicheAtEnd = True;
					Continue;
				ElsIf vStr = "&FolioHeader" Then
					Try
						PrintFolioHeader(vFR, pObj, vArrCashRegister);
						If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
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
					vFR.StringForPrinting = GetString(vStr, vArrCashRegister);
					vFR.PrintString();
					If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndDo;
			
			// Print cliche
			If vDoPrintClicheAtEnd Then
				vFR.PrintCliche();
				If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
					Return False;
				EndIf;
			Else
				vFR.StringQuantity = 6;
				vFR.FeedDocument();
			EndIf;
			
			// Cut off cheque
			vFR.CutType = True;
			vFR.CutCheck();
			
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
Function pmPrintCashIncome(Val pSum, pObj, rMessage, pPassword="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister, pPassword);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;		
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			
			// Open session if is closed
			If vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Тогда
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
						Return False;
					Else
						tcOnServer.Wait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Do cash income
			vFR.Summ1 = pSum;
			vFR.CashIncome();
			If Not CheckResultCode(vFR.ResultCode) Then
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
Function pmPrintCashOutcome(Val pSum, pObj, rMessage, pPassword="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister, pPassword);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;		
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			
			// Open session if is closed
			If vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Тогда
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
						Return False;
					Else
						tcOnServer.Wait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Do cash outcome
			vFR.Summ1 = pSum;
			vFR.CashOutcome();
			If Not CheckResultCode(vFR.ResultCode) Then
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
		CloseOpenCheque(vFR, vArrCashRegister);
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

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function IsNumber(pStr)
	Try 
		vNumStr = Number(pStr);
		Return True;
	Except
	EndTry;
	Return False;
EndFunction // IsNumber

// -----------------------------------------------------------------------------
Function GetPortNumber(pCashRegister)
	vPort = TrimAll(pCashRegister.Port);
	If vPort = "" Then
		Return 1; //COM1 by default
	Else
		vPortNumber = 0;
		If Upper(Left(vPort, 3)) = "COM" Then
			vPortNumber = Number(Mid(vPort, 4, StrLen(vPort)-3));
		ElsIf IsNumber(vPort) Then
			vPortNumber = Number(vPort);
		EndIf;
		Return vPortNumber;
	EndIf;
EndFunction // GetPortNumber

// -----------------------------------------------------------------------------
Function GetBaudRate(pCashRegister)
	vBaudRate = pCashRegister.BaudRate;
	If vBaudRate = 2400 Then
		Return 0;
	ElsIf vBaudRate = 4800 Then
		Return 1;
	ElsIf vBaudRate = 9600 Then
		Return 2;
	ElsIf vBaudRate = 19200 Then
		Return 3;
	ElsIf vBaudRate = 38400 Then
		Return 4;
	ElsIf vBaudRate = 57600 Then
		Return 5;
	ElsIf vBaudRate = 115200 Then
		Return 6;
	ElsIf vBaudRate = 0 Then
		Return 6;
	EndIf;		
	Return 0;
EndFunction // GetBaudRate

// -----------------------------------------------------------------------------
Function Connect(rMessage,vArrCashRegister,pPassword="")
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try     
		// ACC:561-off
		Try
			AttachAddIn("AddIn.DrvFR");
			vFR = New("AddIn.DrvFR");
		Except
			LoadAddIn("DrvFR.dll");
			vFR = New("AddIn.DrvFR");
		EndTry;
        // ACC:561-on
		// Set active logical device
		If vArrCashRegister.UseLogicalDevice And vArrCashRegister.LogicalDeviceNumber > 0 Then
			vFR.LDNumber = vArrCashRegister.LogicalDeviceNumber;
			vFR.SetActiveLD();
		EndIf;
		vFR.Password = pPassword;
		If Not IsBlankString(vArrCashRegister.DriverProtocol) And TrimAll(vArrCashRegister.DriverProtocol) = "1" Then
			vFR.ProtocolType = 1;
		EndIf;
		If Not IsBlankString(vArrCashRegister.ConnectionType) Then
			Try
				vFR.ConnectionType = Number(TrimAll(vArrCashRegister.ConnectionType));
			Except
				vFR.ConnectionType = 0;
			EndTry;
		EndIf;
		vPortNumber = GetPortNumber(vArrCashRegister);
		vBaudRate = GetBaudRate(vArrCashRegister);
		If vPortNumber > 0 Then
			If vFR.ConnectionType = 6 Then
				vFR.TCPPort = vPortNumber;
			Else
				vFR.ComNumber = vPortNumber;
			EndIf;
		EndIf;
		If vBaudRate > 0 Then
			vFR.BaudRate = vBaudRate;
		EndIf;
		If Not IsBlankString(vArrCashRegister.Address) Then
			vAddress = StrSplit(vArrCashRegister.Address, ":", False);
			If vAddress.Count() = 2 Then
				vFR.ComputerName = TrimAll(TrimAll(vAddress[0]));
				vFR.TCPPort = Number(TrimAll(vAddress[1]));
			Else
				vFR.ComputerName = TrimAll(vArrCashRegister.Address);
			EndIf;
		EndIf;
		If Not IsBlankString(vArrCashRegister.OFDServer) Тогда
			vFR.OFDServer = TrimAll(vArrCashRegister.OFDServer);
		EndIf;
		If vArrCashRegister.OFDPort <> 0 Тогда
			vFR.OFDPort = vArrCashRegister.OFDPort;
		EndIf;
		If vArrCashRegister.OFDPollPeriod <> 0 Тогда
			vFR.OFDPollPeriod = vArrCashRegister.OFDPollPeriod;
		EndIf;
		// Try to enable device
		vFR.Connect();
		// Check result code
		If Not CheckResultCode(vFR.ResultCode) Then
			// Error connecting to the device
			rMessage = TrimAll(vFR.ResultCodeDescription);
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
		pFR.Disconnect();
		pFR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function CheckPaper(pFR, pFunction, rMessage)
	If pFR.ECRAdvancedMode = 0 Then
		Return True;
	ElsIf pFR.ECRAdvancedMode = 3 Then
		pFR.ContinuePrint();
		Return True;
	Else
		rMessage = pFR.ECRAdvancedModeDescription;
		tcOnServer.cmWriteLogEventAtServer(pFunction,  ,  ,  , "Mode: " + pFR.ECRAdvancedMode + ", description: " + rMessage);
		Return false;
	EndIf;
EndFunction // CheckPaper

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
Procedure CloseOpenCheque(pFR, pArrCashRegister)
	If pFR.ECRMode = 8 Тогда
		// Close cheque with sys admin password
		vPassword = pFR.Password;
		pFR.Password = TrimR(pArrCashRegister.AccessPassword);
		pFR.ContinuePrint();
		pFR.ResetECR();
		pFR.Password = vPassword;
	EndIf;
EndProcedure // CloseOpenCheque

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.ResultCodeDescription);
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,,"Result code: " + pFR.ResultCode + ", result description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure PrintSlipLines(pFR, pSlipTextArr, pArrCashRegister, pOneCopyOnly = False)
	vArrCashRegister = pArrCashRegister;
	pFR.UseJournalRibbon=0; 
	pFR.UseReceiptRibbon=1;
	// Print first slip for the hotel
	For Each vStr In pSlipTextArr Do
		pFR.StringForPrinting = GetString(vStr, vArrCashRegister);
		pFR.PrintString();
		If pFR.ResultCode <> 0 Then
			Return;
		EndIf;
	EndDo;
	If pOneCopyOnly Then
		pFR.StringQuantity = 4;
		pFR.FeedDocument();
		pFR.CutType = True;
		pFR.CutCheck();
		// Print cliche
		pFR.PrintCliche();
		If pFR.ResultCode <> 0 Then
			pFR.StringForPrinting = Left(TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "LegacyName")), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
			pFR.PrintString();
			pFR.StringForPrinting = Left(NStr("en='TIN/KPP '; ru='ИНН/КПП '; de='TIN/KPP '") + (TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "TIN")) + "/" + TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "KPP"))), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
			pFR.PrintString();
			pFR.StringForPrinting = Left(NStr("en='WELKOME'; ru='ДОБРО ПОЖАЛОВАТЬ'; de='WELKOME'"), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
			pFR.PrintString();
			pFR.StringForPrinting = Left("=======================================================================", ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
			pFR.PrintString();
		EndIf;
	EndIf;
	// Print second slip for the client
	pFR.StringForPrinting = " ";
	pFR.PrintString();
	pFR.StringForPrinting = GetString("-8<--------------------------------------------------------------------",vArrCashRegister);
	pFR.PrintString();
	pFR.StringQuantity = 4;
	pFR.FeedDocument();
	pFR.CutType = True;
	pFR.CutCheck();
	pFR.StringForPrinting = NStr("ru = 'ДЛЯ КЛИЕНТА'; en = 'FOR THE CLIENT'; de = 'FOR THE CLIENT'");
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	// Print cliche
	pFR.PrintCliche();
	If pFR.ResultCode <> 0 Then
		pFR.StringForPrinting = Left(TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "LegacyName")), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='TIN/KPP '; ru='ИНН/КПП '; de='TIN/KPP '") + (TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "TIN")) + "/" + TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "KPP"))), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='WELKOME'; ru='ДОБРО ПОЖАЛОВАТЬ'; de='WELKOME'"), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left("=======================================================================", ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
	EndIf;
	For Each vStr In pSlipTextArr Do
		pFR.StringForPrinting = GetString(vStr, vArrCashRegister);
		pFR.PrintString();
		If pFR.ResultCode <> 0 Then
			Return;
		EndIf;
	EndDo;
	pFR.StringQuantity = 4;
	pFR.FeedDocument();
	pFR.CutType = True;
	pFR.CutCheck();
	// Print cliche
	pFR.PrintCliche();
	If pFR.ResultCode <> 0 Then
		pFR.StringForPrinting = Left(TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "LegacyName")), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='TIN/KPP '; ru='ИНН/КПП '; de='TIN/KPP '") + (TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "TIN")) + "/" + TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "KPP"))), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='WELKOME'; ru='ДОБРО ПОЖАЛОВАТЬ'; de='WELKOME'"), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left("=======================================================================", ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
	EndIf;
EndProcedure // PrintSlipLines

// -----------------------------------------------------------------------------
Procedure PrintFolioHeader(pFR, pObj, pArrCashRegister)
	vArrCashRegister	= pArrCashRegister;
	vArrFolio			= tcOnServer.cmGetAtributeAsArray(pObj.Folio);
	pFR.UseJournalRibbon=0; 
	pFR.UseReceiptRibbon=1;
	// Header start delimeter
	pFR.StringForPrinting = GetString("-----------------------------------------------------------------------",vArrCashRegister);
	pFR.PrintString();
	// Folio #
	pFR.StringForPrinting = GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio # '") + tcOnServer.GetDocumentNumberPresentation(tcOnServer.cmGetAttributeByRef(pObj.Folio,"Number")),vArrCashRegister);
	pFR.PrintString();
	// Room
	If Not vArrCashRegister.DoNotPrintRoom Then
		pFR.StringForPrinting = GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer: '") + TrimAll(vArrFolio.Room),vArrCashRegister); 
		pFR.PrintString();
	EndIf;
	// Guest
	If Not vArrCashRegister.DoNotPrintClient Then
		If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) And ValueIsFilled(pObj.Payer) Then
			pFR.StringForPrinting = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Payer),vArrCashRegister); 
		Else
			pFR.StringForPrinting = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(vArrFolio.Client),vArrCashRegister);
		EndIf;
		pFR.PrintString();
	EndIf;
	// Guest group
	pFR.StringForPrinting = GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(pObj.GuestGroup),vArrCashRegister);  
	pFR.PrintString();
	// Document
	pFR.StringForPrinting = GetString(NStr("ru = 'Док.  № '; en='Doc.  # '; de='Dok.  Nr. '") + tcOnServer.GetDocumentNumberPresentation(TrimAll(pObj.Number)),vArrCashRegister);
	pFR.PrintString();
	// Header end delimeter
	pFR.StringForPrinting = GetString("-----------------------------------------------------------------------",vArrCashRegister); 
	pFR.PrintString();
EndProcedure // PrintFolioHeader

// -----------------------------------------------------------------------------
Procedure CancelCheque(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.ResultCodeDescription);
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,,"Result code: " + pFR.ResultCode + ", result description: " + rMessage);
	Try
		pFR.CancelCheck();
	Except
	EndTry;
	Disconnect(pFR);
EndProcedure // CancelCheque

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, rMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,, "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

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
Function CheckResultCode(pResultCode)
	If pResultCode <> 0 Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // Not CheckResultCode

#EndRegion

