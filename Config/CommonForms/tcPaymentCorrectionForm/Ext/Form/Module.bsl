
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Payment") Then
		Payment = Parameters.Payment;
	EndIf;
	If ValueIsFilled(Payment) Then
		// Fill default parameter values
		CorrectCashRegister = Payment.CashRegister;
		If Not IsInRole("Administrator") Then
			Items.PaymentMethodForRefund.ReadOnly = True;
			Items.PaymentMethodForRefund.ChoiceButton = False;
		EndIf;
		
		// Fill list of payment method
		FillListOfCashRegisters();
		
		// Fill list of payment method
		FillListOfPaymentMethods();
		FillListOfPaymentMethodsForRefund();
	Else
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandExecute(pCommand)
	// Do some checks
	If Not ValueIsFilled(CorrectPaymentMethod) Then
		ShowMessageBox(, NStr("en='Correct payment method shoud be filled!'; ru='Необходимо указать правильный способ оплаты!'; de='Die korrekte Zahlungsmethode sollte ausgefüllt werden!'"));
		Return;
	EndIf;
	
	// Create documents
	vDocsToProcess = CreateDocumentsAtServer();
	
	// Post cheques if necessary
	If ValueIsFilled(CorrectCashRegister) And 
	   tcOnServer.cmGetAttributeByRef(CorrectCashRegister, "IsControlledByProgram") And 
	   tcOnServer.cmGetAttributeByRef(CorrectPaymentMethod, "BookByCashRegister") Then
		vDriver = tcOnClient.cmGetModulTO(CorrectCashRegister);
		If vDriver = Undefined Then
			ShowMessageBox(, NStr("en='Failed to connect to cash register!'; ru='Не удалось подключиться к ККМ!'; de='Verbindung zur Kasse fehlgeschlagen!'"));
			Return;
		EndIf;
		
		vPrintChequeParams = New Structure("Driver, DocsToProcess", vDriver, vDocsToProcess);
		
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, CorrectCashRegister);
		If IsBlankString(vPasswordKKM) Then
			ShowInputString(New NotifyDescription("PrintCheques", ThisForm, vPrintChequeParams), vPasswordKKM, NStr("en='Input cash register password!'; ru='Укажите пароль ККМ!'; de='Kassenpasswort eingeben!'"), , False);
		Else
			PrintCheques(vPasswordKKM, vPrintChequeParams);
		EndIf;
	Else
		// Finished
		ShowMessageBox(, NStr("en='Done!'; ru='Выполнено!'; de='Fertig!'"));
		
		// Notification
		Notify("Document.Payment.Write", Payment, FormOwner);
	EndIf;
EndProcedure // CommandExecute

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function CreateDocumentsAtServer()
	// Build value list of documents for wich cheque should be posted
	vDocsToProcess = New ValueList();
	// Get documents to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Payments.Ref AS Ref,
	|	Returns.Ref AS ReturnRef,
	|	ReturnChequeAttributes.ChequeFiscalNumber AS ReturnFiscalNumber,
	|	CorrectPayments.Ref AS CorrectPaymentRef,
	|	CorrectPaymentChequeAttributes.ChequeFiscalNumber AS CorrectPaymentFiscalNumber
	|FROM
	|	Document.Payment AS Payments
	|		LEFT JOIN Document.Return AS Returns
	|		ON Payments.Ref = Returns.Payment
	|			AND (Returns.Posted)
	|			AND (Returns.CorrectionOfIncorrectCheque)
	|		LEFT JOIN InformationRegister.ChequeAttributes AS ReturnChequeAttributes
	|		ON (Returns.Ref = ReturnChequeAttributes.Payment)
	|			AND (Returns.Hotel = ReturnChequeAttributes.Hotel)
	|		LEFT JOIN Document.Payment AS CorrectPayments
	|		ON Payments.Ref = CorrectPayments.Payment
	|			AND (CorrectPayments.Posted)
	|			AND (CorrectPayments.CorrectionOfIncorrectCheque)
	|		LEFT JOIN InformationRegister.ChequeAttributes AS CorrectPaymentChequeAttributes
	|		ON (CorrectPayments.Ref = CorrectPaymentChequeAttributes.Payment)
	|			AND (CorrectPayments.Hotel = CorrectPaymentChequeAttributes.Hotel)
	|WHERE
	|	Payments.Ref = &qPayment
	|	AND Payments.Posted
	|
	|ORDER BY
	|	Payments.PointInTime";
	vQry.SetParameter("qPayment", Payment);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocRef = vDocsRow.Ref;
		
		// Create refund
		If ValueIsFilled(vDocsRow.ReturnRef) Then
			If ValueIsFilled(vDocsRow.ReturnFiscalNumber) Then
				tcCommonFunctionOnClientServer.TextMessage("I - " + NStr("en='refund has already been made: '; ru='возврат уже проведен: '; de='Rückerstattung ist bereits erfolgt: '") + TrimAll(vDocsRow.ReturnRef) + " (" + TrimAll(vDocsRow.ReturnFiscalNumber) + ")");
			Else
				vDocsToProcess.Add(vDocsRow.ReturnRef);
			EndIf;
			
			Refund = vDocsRow.ReturnRef;
		Else
			vReturnObj = Documents.Return.CreateDocument();
			
			vReturnObj.Fill(vDocRef);
			If Items.PaymentMethodForRefund.ChoiceList.FindByValue(PaymentMethodForRefund) <> Undefined Then
				vReturnObj.PaymentMethod = PaymentMethodForRefund;
			EndIf;
			If PaymentMethodForRefund.BookByCashRegister Then
				vReturnObj.CashRegister = vDocRef.CashRegister;
			Else
				vReturnObj.CashRegister = Undefined;
			EndIf;
			vReturnObj.Payment = vDocRef;
			vReturnObj.CorrectionOfIncorrectCheque = True;
			
			vReturnObj.Sum = vDocRef.Sum;
			vReturnObj.SumInFolioCurrency = vDocRef.SumInFolioCurrency;
			vReturnObj.VATSum = vDocRef.VATSum;
			vReturnObj.VATSumInFolioCurrency = vDocRef.VATSumInFolioCurrency;
			
			vReturnObj.PaymentSections.Clear();
			For Each vSrcPSRow In vDocRef.PaymentSections Do
				vTgtPSRow = vReturnObj.PaymentSections.Add();
				FillPropertyValues(vTgtPSRow, vSrcPSRow);
			EndDo;
			
			vReturnObj.Write(DocumentWriteMode.Posting);
			
			vDocsToProcess.Add(vReturnObj.Ref);
			
			Refund = vReturnObj.Ref;
		EndIf;
		
		// Create correct payment
		If ValueIsFilled(vDocsRow.CorrectPaymentRef) Then
			If ValueIsFilled(vDocsRow.CorrectPaymentFiscalNumber) Then
				tcCommonFunctionOnClientServer.TextMessage("I - " + NStr("en='the correct payment has already been made: '; ru='правильный платеж уже проведен: '; de='die korrekte Zahlung ist bereits erfolgt: '") + TrimAll(vDocsRow.CorrectPaymentRef) + " (" + TrimAll(vDocsRow.CorrectPaymentFiscalNumber) + ")");
			Else
				vDocsToProcess.Add(vDocsRow.CorrectPaymentRef);
			EndIf;
			
			CorrectPayment = vDocsRow.CorrectPaymentRef;
		Else
			vPaymentObj = Documents.Payment.CreateDocument();
			
			vPaymentObj.Fill(vDocRef.Folio);
			vPaymentObj.PaymentMethod = CorrectPaymentMethod;
			If CorrectPaymentMethod.BookByCashRegister Then
				vPaymentObj.CashRegister = CorrectCashRegister;
			Else
				vPaymentObj.CashRegister = Undefined;
			EndIf;
			vPaymentObj.Payment = vDocRef;
			vPaymentObj.CorrectionOfIncorrectCheque = True;
			
			vPaymentObj.Sum = vDocRef.Sum;
			vPaymentObj.SumInFolioCurrency = vDocRef.SumInFolioCurrency;
			vPaymentObj.VATSum = vDocRef.VATSum;
			vPaymentObj.VATSumInFolioCurrency = vDocRef.VATSumInFolioCurrency;
			
			vPaymentObj.PaymentSections.Clear();
			For Each vSrcPSRow In vDocRef.PaymentSections Do
				vTgtPSRow = vPaymentObj.PaymentSections.Add();
				FillPropertyValues(vTgtPSRow, vSrcPSRow);
			EndDo;
			
			vPaymentObj.Write(DocumentWriteMode.Posting);
			
			vDocsToProcess.Add(vPaymentObj.Ref);
			
			CorrectPayment = vPaymentObj.Ref;
		EndIf;
	EndDo;
	
	Return vDocsToProcess;
EndFunction // CreateDocumentsAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintCheques(pPasswordKKM, pExtraParams) Export
	If pPasswordKKM <> Undefined Then
		vDriver = pExtraParams.Driver;
		vCorrectPaymentMethodAttrs = tcOnServer.cmGetAtributeAsArray(CorrectPaymentMethod);
		vCorrectCashRegisterAttrs = tcOnServer.cmGetAtributeAsArray(CorrectCashRegister);
		
		// Process documents
		For Each vDocsToProcessItem In pExtraParams.DocsToProcess Do
			vDoc = vDocsToProcessItem.Value;
			vDocAttr = tcOnServer.cmGetAtributeAsArray(vDoc);
			
			vMessage = "";
			
			// Check if it is possible to print something
			vChequeIsPrinted = False;
			If vDriver.pmIsReadyToPrint(vMessage, , CorrectCashRegister) Then
				vChequeIsPrinted = True;
				
				// Process payment by the credit card processing system
				If vCorrectPaymentMethodAttrs.IsByCreditCard And Not vCorrectPaymentMethodAttrs.ExternalBankTerminalIsUsed Then
					vArrPaymentTerminal = Undefined;
					If CheckCreditCardsProcessingSystem(vArrPaymentTerminal) Then
						vPaymentTerminalDriver = tcOnClient.cmGetModulTO(vArrPaymentTerminal);
						If vPaymentTerminalDriver <> Undefined Then
							vTerminalIsProcessed = True;
							If TypeOf(vDoc) = Type("DocumentRef.Return") Then
								vTerminalIsProcessed = vPaymentTerminalDriver.pmAuthorizePayment(-vDocAttr.Sum, -vDocAttr.VATSum, vDocAttr, vMessage, vArrPaymentTerminal);
							Else
								vTerminalIsProcessed = vPaymentTerminalDriver.pmAuthorizePayment(vDocAttr.Sum, vDocAttr.VATSum, vDocAttr, vMessage, vArrPaymentTerminal);
							EndIf;
							If Not vTerminalIsProcessed Then
								vChequeIsPrinted = False;
							EndIf;
						EndIf;	
					EndIf;
				EndIf;
				
				// Print cheque
				If vChequeIsPrinted Then
					If TypeOf(vDoc) = Type("DocumentRef.Return") Then
						If vCorrectPaymentMethodAttrs.PrintCheque Then
							If Not vCorrectPaymentMethodAttrs.PrintNonFiscalCheque Then
								vChequeIsPrinted = vDriver.pmPrintCheque(-vDocAttr.Sum, -vDocAttr.VATSum, vDocAttr, vDoc, vMessage, pPasswordKKM, , False, Undefined, "", "", '00010101', vCorrectCashRegisterAttrs.SendPayerContactsToOFD, "", "");
							Else
								vChequeTemplate = TrimAll(vCorrectPaymentMethodAttrs.NonFiscalChequeTemplate);
								If Not IsBlankString(vChequeTemplate) Then
									vChequeIsPrinted = vDriver.pmPrintNonFiscalCheque(-vDocAttr.Sum, -vDocAttr.VATSum, vDocAttr, vChequeTemplate, vMessage, pPasswordKKM);
									If vChequeIsPrinted Then
										Items.Refund.TextColor = WebColors.Green;
									EndIf;							
								Else
									vMessage = NStr("en='Non-fiscal cheque template is not filled for payment method!'; ru='У способа оплаты не заполнен шаблон нефискального чека!'; de='Zahlungsmethode hat eine leer Vorlage für die nonfiscal Kassenbon!'");
									vChequeIsPrinted = False;
								EndIf;
							EndIf;
						EndIf;
					ElsIf TypeOf(vDoc) = Type("DocumentRef.Payment") Then
						If vCorrectPaymentMethodAttrs.PrintCheque Then
							If Not vCorrectPaymentMethodAttrs.PrintNonFiscalCheque Then
								vChequeIsPrinted = vDriver.pmPrintCheque(vDocAttr.Sum, vDocAttr.VATSum, vDocAttr, vDoc, vMessage, pPasswordKKM, , False, Undefined, "", "", '00010101', vCorrectCashRegisterAttrs.SendPayerContactsToOFD, "", "");
							Else
								vChequeTemplate = TrimAll(vCorrectPaymentMethodAttrs.NonFiscalChequeTemplate);
								If Not IsBlankString(vChequeTemplate) Then
									vChequeIsPrinted = vDriver.pmPrintNonFiscalCheque(vDocAttr.Sum, vDocAttr.VATSum, vDocAttr, vChequeTemplate, vMessage, pPasswordKKM);
									If vChequeIsPrinted Then
										Items.CorrectPayment.TextColor = WebColors.Green;
									EndIf;							
								Else
									vMessage = NStr("en='Non-fiscal cheque template is not filled for payment method!'; ru='У способа оплаты не заполнен шаблон нефискального чека!'; de='Zahlungsmethode hat eine leer Vorlage für die nonfiscal Kassenbon!'");
									vChequeIsPrinted = False;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If Not vChequeIsPrinted Then
				// Unpost new documents created
				UnpostDocumentsCreated();
				
				// Error printing cheque
				tcCommonFunctionOnClientServer.TextMessage("!!! - " + NStr("en='Error in creating a cash register receipt: '; ru='Ошибка создания кассового чека: '; de='Fehler beim Erstellen eines Kassenbons: '") + TrimAll(vDoc) + " - " + vMessage);
				Return;
			Else
				tcCommonFunctionOnClientServer.TextMessage("OK - " + TrimAll(vDoc));
			EndIf;
			tcOnServer.Wait(3);
		EndDo;
	EndIf;
	
	// Finished
	ShowMessageBox(, NStr("en='Done!'; ru='Выполнено!'; de='Fertig!'"));
	
	// Notification
	Notify("Document.Payment.Write", Payment, FormOwner);
EndProcedure // PrintCheques

// -----------------------------------------------------------------------------
&AtServer
Function CheckCreditCardsProcessingSystem(rArrPaymentTerminal)
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		If SessionParameters.CurrentWorkstation.HasConnectionToCreditCardsProcessingSystem Then
			vPaymentTerminalParams = SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters;
			rArrPaymentTerminal = tcOnServer.cmGetAtributeAsArray(vPaymentTerminalParams);
			rArrPaymentTerminal.ConnectionParameters = rArrPaymentTerminal.ConnectionParameters.Get();
			Return True;
		EndIf;	
	EndIf;
	Return False;
EndFunction	//CheckCreditCardsProcessingSystem

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPaymentMethods()
	vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios = cmCheckUserPermissions("HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios");
	vPMs = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser, , CorrectCashRegister);
	vIsResortFee = False;
	For Each vRowPS In Payment.PaymentSections Do
		If ValueIsFilled(vRowPS.ChequeService) And vRowPS.ChequeService.IsResortFee Then
			 vIsResortFee = True;
			 Break;
		EndIf;	
	EndDo;
	i = 0;
	While i < vPMs.Count() Do
		vPM = vPMs.Get(i).Value;
		If vPM = Catalogs.PaymentMethods.DepositTransfer Then
			vPMs.Delete(i);
		ElsIf vPM = Catalogs.PaymentMethods.Settlement And Not vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios And 
		     (Not ValueIsFilled(Payment.AccountingCustomer) Or ValueIsFilled(Payment.AccountingCustomer) And Payment.AccountingCustomer.IsIndividual) Then
			vPMs.Delete(i);
		ElsIf vPM.IsForResortFee <>	vIsResortFee Then
			vPMs.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	Items.CorrectPaymentMethod.ChoiceList.LoadValues(vPMs.UnloadValues());
	// Check payment modes
	i = 0;
	While i < Items.CorrectPaymentMethod.ChoiceList.Count() Do
		vPMListItem = Items.CorrectPaymentMethod.ChoiceList.Get(i);
		If vPMListItem.Value.IsCloseToTheFolio Or vPMListItem.Value.IsCloseToTheRoom Or 
		   ValueIsFilled(Payment.AccountingCustomer) And Payment.AccountingCustomer.IsIndividual And vPMListItem.Value = Catalogs.PaymentMethods.Settlement And Not vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios Or 
		   vPMListItem.Value = Catalogs.PaymentMethods.DepositTransfer Then
			Items.CorrectPaymentMethod.ChoiceList.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Check that current payment method is in the list
	If Payment.Posted Then
		If ValueIsFilled(Payment.PaymentMethod) Then
			If Items.CorrectPaymentMethod.ChoiceList.FindByValue(Payment.PaymentMethod) = Undefined Then
				Items.CorrectPaymentMethod.ChoiceList.Add(Payment.PaymentMethod);
			EndIf;
		EndIf;
	EndIf;
	// Add icons
	FillPMIcons(Items.CorrectPaymentMethod);
EndProcedure // FillListOfPaymentMethods

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPaymentMethodsForRefund()
	vObj = Documents.Return.CreateDocument();
	vObj.Fill(Payment);
	PaymentMethodForRefund = vObj.PaymentMethod;
	
	vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios = cmCheckUserPermissions("HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios");
	vRetPMs = New ValueList();
	vRetPMs.LoadValues(vObj.pmGetPaymentMethodsAllowedForReturn());
	vPMs = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser, True, vObj.CashRegister);
	vIsResortFee = False;
	For Each vRowPS In vObj.PaymentSections Do
		If ValueIsFilled(vRowPS.ChequeService) And vRowPS.ChequeService.IsResortFee Then
			 vIsResortFee = True;
			 Break;
		EndIf;	
	EndDo;
	i = 0;
	While i < vRetPMs.Count() Do
		vPM = vRetPMs.Get(i).Value;
		If vPM = Catalogs.PaymentMethods.DepositTransfer Then
			vRetPMs.Delete(i);
		ElsIf vPM = Catalogs.PaymentMethods.Settlement And Not vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios And 
		     (Not ValueIsFilled(vObj.AccountingCustomer) Or ValueIsFilled(vObj.AccountingCustomer) And vObj.AccountingCustomer.IsIndividual) Then
			vRetPMs.Delete(i);
		ElsIf vPM.IsForResortFee <>	vIsResortFee Then
			vRetPMs.Delete(i);	
		ElsIf vPMs.FindByValue(vPM) = Undefined Then
			vRetPMs.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	Items.PaymentMethodForRefund.ChoiceList.LoadValues(vRetPMs.UnloadValues());
	// Check payment modes
	i = 0;
	While i < Items.PaymentMethodForRefund.ChoiceList.Count() Do
		vPMListItem = Items.PaymentMethodForRefund.ChoiceList.Get(i);
		If vPMListItem.Value.IsCloseToTheFolio Or vPMListItem.Value.IsCloseToTheRoom Or 
		   ValueIsFilled(Payment.AccountingCustomer) And Payment.AccountingCustomer.IsIndividual And vPMListItem.Value = Catalogs.PaymentMethods.Settlement And Not vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios Or 
		   vPMListItem.Value = Catalogs.PaymentMethods.DepositTransfer Then
			Items.PaymentMethodForRefund.ChoiceList.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Check that current payment method is in the list
	If ValueIsFilled(PaymentMethodForRefund) Then
		If Items.PaymentMethodForRefund.ChoiceList.FindByValue(PaymentMethodForRefund) = Undefined Then
			Items.PaymentMethodForRefund.ChoiceList.Add(PaymentMethodForRefund);
		EndIf;
	EndIf;
	// Add icons
	FillPMIcons(Items.PaymentMethodForRefund);
EndProcedure // FillListOfPaymentMethodsForRefund

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPMIcons(pPaymentMethodItem)
	// Add icons
	For Each vListItem In pPaymentMethodItem.ChoiceList Do
		vPM = vListItem.Value;
		If vPM = Catalogs.PaymentMethods.AdvanceSettlement Then
			vListItem.Picture = PictureLib.CheckSyntax;
		ElsIf vPM.IsByCash Then
			vListItem.Picture = PictureLib.Coins;
		ElsIf vPM.IsByCreditCard Then
			vListItem.Picture = PictureLib.CreditCard16;
		ElsIf vPM.IsByBankTransfer Then
			vListItem.Picture = PictureLib.Customers;
		ElsIf vPM = Catalogs.PaymentMethods.Settlement Then
			vListItem.Picture = PictureLib.Customer;
		ElsIf vPM.IsCloseToTheFolio Then
			vListItem.Picture = PictureLib.Adult;
		ElsIf vPM.IsCloseToTheRoom Then
			vListItem.Picture = PictureLib.Rooms;
		ElsIf vPM.IsByGiftCertificate Then
			vListItem.Picture = PictureLib.CalculationType;
		ElsIf vPM.IsByBonuses Then
			vListItem.Picture = PictureLib.AccumulationRegister;
		ElsIf vPM.IsViaInternetAcquiring Then
			vListItem.Picture = PictureLib.GeographicalSchema;
		Else
			vListItem.Picture = PictureLib.Empty;
		EndIf;
	EndDo;
EndProcedure // FillPMIcons

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfCashRegisters()
	vCashRegistersList = New ValueList();
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		vCashRegistersList = cmGetListOfAllCashRegisters(Payment.Company);
	Else
		vCashRegistersList = cmGetListOfCashRegistersAllowed(Payment.Company, SessionParameters.CurrentWorkstation, ?(ValueIsFilled(CorrectPaymentMethod), CorrectPaymentMethod, PaymentMethodForRefund));
	EndIf;
	// Check that current cash register is in the list
	If ValueIsFilled(Payment.CashRegister) Then
		If vCashRegistersList.FindByValue(Payment.CashRegister) = Undefined Then
			If vCashRegistersList.Count() > 0 Then
				CorrectCashRegister = vCashRegistersList.Get(0).Value;
			EndIf;
		EndIf;
	EndIf;
	// Attach list of cash registers to the form item
	Items.CorrectCashRegister.ChoiceList.LoadValues(vCashRegistersList.UnloadValues());
EndProcedure // FillListOfCashRegisters

// -----------------------------------------------------------------------------
&AtServer
Procedure UnpostDocumentsCreated()
	If ValueIsFilled(Refund) And Refund.Posted Then
		vRefundObj = Refund.GetObject();
		vRefundObj.Write(DocumentWriteMode.UndoPosting);
		Items.Refund.TextColor = WebColors.Red;
	EndIf;
	If ValueIsFilled(CorrectPayment) And CorrectPayment.Posted Then
		vCorrectPaymentObj = CorrectPayment.GetObject();
		vCorrectPaymentObj.Write(DocumentWriteMode.UndoPosting);
		Items.CorrectPayment.TextColor = WebColors.Red;
	EndIf;
EndProcedure // UnpostDocumentsCreated

#EndRegion

