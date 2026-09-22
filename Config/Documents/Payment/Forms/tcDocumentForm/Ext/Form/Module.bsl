
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Save current user
	CurrentUser = SessionParameters.CurrentUser;
	
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
			
	// Fill default values
	FillDocumentObjectParameters(pCancel, pStandardProcessing);
	
	// Initialize some attributes
	ChequeIsPrinted = False;
	PaymentIsAuthorized = False;
	If ValueIsFilled(Object.PaymentMethod) Then
		ExternalSystem = Object.PaymentMethod.ExternalSystem;
		If ValueIsFilled(ExternalSystem) And Object.PaymentMethod.IsByCreditCard Then  
			If ValueIsFilled(Object.OrderURL) And ValueIsFilled(Object.OrderID) And Not ValueIsFilled(Object.ReferenceNumber) And Not ValueIsFilled(Object.AuthorizationCode) Then	 
				Items.FormOrderRevokeQr.Visible = True;
			EndIf;
		EndIf;
	EndIf; 
		
	Items.UpdateCardBalance.Visible = ValueIsFilled(ExternalSystem);
	
	// Set appearance of payment sections tabular part
	SetAppearancePaymentSections();
	
	// Correction cheque attributes parameters
	SetCorrectionChequeAttributes();
	
	// Payment card
	Items.PaymentCardDataGroup.Visible = HasPaymentCardData();
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Fill balance by discount card or certificate
	FillBalanceByCard(True);
	
	Items.PrintSlip.Enabled = Not IsBlankString(Object.SlipText);
	Items.PrintAnnulationSlip.Enabled = Not IsBlankString(Object.AnnulationSlipText);
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	FillDiscountCard();
	
	If Parameters.Property("ErrorMSG") Then
		tcCommonFunctionOnClientServer.TextMessage(Parameters.ErrorMSG);	
	EndIf;
	
	// View of payer contact data
	If ValueIsFilled(Object.Ref) Then
		SendPayerContactsRefresh(True, False, False, False);
	EndIf;
	
	FillCompanyAndCashRegisterCollapsedRepresentation(); 
	
	// Set payment section filter  
	vFilterIterms  = New Array;
	vFilterIterms.Add(Object.Hotel);
	vFilterIterms.Add(Catalogs.Hotels.EmptyRef());   
	
	tcCommonFunctionOnClientServer.cmChangeItemChoiceParameters(Items.PaymentSection, "Hotel", vFilterIterms); 
	tcCommonFunctionOnClientServer.cmChangeItemChoiceParameters(Items.PaymentSectionsPaymentSection, "Hotel", vFilterIterms);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// On open form at server
	OnOpenForm();
	// Save currency attributes
	SavePaymentCurrencyAttributes();
	// Check if advance settlement mode is correct
	If AdvanceSettlementMode And Object.PaymentMethod <> PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
		AdvanceSettlementMode = False;
		ShowMessageBox(, NStr("en='Failed to fill advance settlement payment! Check please amount and payment method!'; 
		                      |ru='Не удалось сформировать зачет аванса/предоплаты! Проверьте сумму платежа и способ оплаты!'; 
							  |de='Die vorauszahlungsberechnung konnte nicht erstellt werden! Überprüfen Sie den Zahlungsbetrag und die Zahlungsmethode!'"));
	EndIf;
	// Set default cash register
	If IsNew Then
		If tcOnServer.cmCheckUserPermissionsAtServer("DoNotFillDefaultPaymentMethodInPayments") Then
			If Object.PaymentMethod <> PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") And Not ValueIsFilled(Object.Preauthorisation) Then
				Object.PaymentMethod = Undefined;
			EndIf;
		EndIf;
		vResult = SetDefaultCashRegister(True);
		If vResult Then
			AttachIdleHandler("OpenCashRegistersList", 0.1, True);
		Else
			If Not AdvanceSettlementMode Then
				If CheckInvoices() Then
					If UnpaidInvoicesWereFound Then
						AttachIdleHandler("OpenInvoicesList", 0.1, True);
					Else
						AttachIdleHandler("OpenProformaInvoicesList", 0.1, True);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCloseQRCodePaymentForm(pResult, pExtraParams) Export 
	Read();
	If pResult <> Undefined Then
		If pResult Then
			If ValueIsFilled(Object.ReferenceNumber) And ValueIsFilled(Object.AuthorizationCode) Then 
				If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
					Close();
				EndIf;
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Reference number and authorization code are not filled in'; de = 'Referenznummer und Autorisierungscode sind nicht ausgefüllt'; ru = 'Референс номер и код авторизации не заполнены'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // AfterCloseQRCodePaymentForm

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCloseInputAuthorizationCodeForm(pResult, pExtraParams) Export 
	If pResult <> Undefined Then
		If ValueIsFilled(ExternalSystem) Then
			If Not IsBlankString(pResult.AuthorizationCode) Then
				If fmFinishExternalPayment(pResult.AuthorizationCode) Then
					Object.BonusesAreProcessed = True; 
					// Call procedure to save payment to the database
					AttachIdleHandler("SaveDocumentToPendingList", 0.1, True);
					If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
						Close();
					EndIf;
				EndIf;		
			EndIf;	
		Else	
			If pResult Then
				IsCardVerified = True;
				If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
					Close();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If pCancel Then Return EndIf;
	Try
		// Get credit cards processing system
		vPaymentMethodArr = Undefined;
		If ValueIsFilled(Object.PaymentMethod) Then
			vPaymentMethodArr = tcOnServer.cmGetAtributeAsArray(Object.PaymentMethod);
			If CreditCardProcessingSystem.IsEmpty() And vPaymentMethodArr.IsByCreditCard Then
				vTempArr = GetCreditCardProcessingSystem();
				If vTempArr.Count() > 1 Then
					pCancel = True;
					vParams = New Structure("Arr", vTempArr);
					OpenForm("CommonForm.tcCreditCardProcessingSystemChoiceForm", vParams, ThisObject, UUID);
					Return;
				ElsIf vTempArr.Count() = 1 Then
					CreditCardProcessingSystem = vTempArr[0];
				EndIf; 
			EndIf;
		EndIf;
		
		// Get cash register attributes structure
		vCashRegisterArr = Undefined;
		If ValueIsFilled(Object.CashRegister) Then
			vCashRegisterArr = tcOnServer.cmGetAtributeAsArray(Object.CashRegister);
		EndIf;
		
		vMessage = ""; 
		ClearMessages();
		
		If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
			// Check document attributes
			If Not CheckDocumentAttributesAtServer(vMessage) Then
				pCancel = True;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,,tcOnServer.cmNStrAtServer(vMessage));
				Return;
			EndIf;
			SetNewObjectRefAtServer();
			vMessage = "";
			If ValueIsFilled(Object.DiscountCard) And (vPaymentMethodArr.IsByBonuses Or vPaymentMethodArr.IsByGiftCertificate) Then
				If ValueIsFilled(ExternalSystem) Then
					If Not Object.BonusesAreProcessed Then
						vDiscountCardStruct = tcOnServer.cmGetAtributeAsArray(Object.DiscountCard);
						If tcOnServer.cmGetAttributeByRef(vDiscountCardStruct.DiscountType, "VerifyClientBySMS") And (vDiscountCardStruct.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Bonuses") Or vDiscountCardStruct.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Certificate")) Then
							pCancel = True;
							If fmStartExternalPayment() Then
								If Not IsBlankString(Object.ExternalCode) Then
									OpenForm("CommonForm.tcInputAuthorizationCode", New Structure("ExternalSystem, CountCharacter", ExternalSystem, tcOnServer.cmGetAttributeByRef(ExternalSystem, "AuthorizationCodeNumberOfCharacters")) , ThisObject, , , , New NotifyDescription("AfterCloseInputAuthorizationCodeForm", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
									Return;
								EndIf;
							EndIf;
						Else
							If fmFinishExternalPayment("", True) Then
								Object.BonusesAreProcessed = True;
								// Call procedure to save payment to the database
								AttachIdleHandler("SaveDocumentToPendingList", 0.1, True);
							Else
								pCancel = True;
								Return;
							EndIf;
						EndIf;
					EndIf;
				Else
					vDiscountCardStruct = tcOnServer.cmGetAtributeAsArray(Object.DiscountCard);
					If tcOnServer.cmGetAttributeByRef(vDiscountCardStruct.DiscountType,"VerifyClientBySMS") And (vDiscountCardStruct.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Bonuses") Or vDiscountCardStruct.LoyaltyType = PredefinedValue("Enum.LoyaltyType.Certificate")) Then 
						If vDiscountCardStruct.Client <> Object.Payer Then
							If Not IsCardVerified Then
								pCancel = True;
								vPhone = tcOnServer.cmGetAttributeByRef(vDiscountCardStruct.Client,"Phone");
								vLanguage = tcOnServer.cmGetAttributeByRef(vDiscountCardStruct.Client,"Language");
								OpenForm("CommonForm.tcInputAuthorizationCode", New Structure("SelPhone, SelLanguage", vPhone, vLanguage), ThisObject, , , , New NotifyDescription("AfterCloseInputAuthorizationCodeForm", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
								Return;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			// Check user PIN if necessary
			If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
				OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "BeforeWrite"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
				pCancel = True;
				Return;
			EndIf;
			EmployeePINCodeChecked = False;
			// Actions for the first document write
			If Not Object.Posted And Not Object.DeletionMark Then
				// Ask for payment method confirmation
				If Not ConfirmPaymentMethodChoice() Then
					pCancel = True;
					Return;
				EndIf;
				// Check if it is possible to print cheque
				If ValueIsFilled(Object.CashRegister) And ValueIsFilled(Object.PaymentMethod) Then
					// Lock payment amount and other important parameters to avoid cases when amount or payment method is changed by user during the operation
					Items.HeaderGroup.ReadOnly = True;
					Items.GroupCCParams.ReadOnly = True;
					Items.GroupSlip.ReadOnly = True;
					Items.PaymentSection.ReadOnly = True;
					Items.PaymentSectionsGroup.ReadOnly = True;
					// Check if cash register is connected and ready to process commands
					If vPaymentMethodArr.BookByCashRegister Then
						If vCashRegisterArr.IsControlledByProgram Then
							If vPaymentMethodArr.PrintCheque And Not ChequeIsPrinted Then
								If Object.Sum <> 0 Or Object.Sum = 0 And Object.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
									If Not IsReadyToPrintCheque(vMessage, Object.CashRegister) Then
										pCancel = True;
										tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, tcOnServer.cmNStrAtServer(vMessage));
										ShowMessageBox(,tcOnServer.cmNStrAtServer(vMessage),,NStr("en = 'Error cash register'; de = 'Fehler Registrierkasse'; ru = 'Ошибка ККМ'"));
										Return;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					// Process payment by the credit card processing system
					If vPaymentMethodArr.IsByCreditCard Then 
						If ValueIsFilled(ExternalSystem) Then
							If Not ValueIsFilled(Object.ReferenceNumber) And Not ValueIsFilled(Object.AuthorizationCode) Then
								pCancel = True;
								If Not ValueIsFilled(Object.OrderID) And Not ValueIsFilled(Object.OrderURL) Then
									If Not fmStartCreditCardExternalPayment() Then
										Return;		
									EndIf; 
									Items.FormOrderRevokeQr.Visible = True;
								EndIf;      
								SetReadOnlyByQrExternalPayment();
								// Call procedure to save payment to the database
								AttachIdleHandler("SaveDocumentToOpenQRCodePaymentForm", 0.1, True);  	
								Return;
							Else
								PaymentIsAuthorized = True;	
							EndIf;	
						ElsIf Not vPaymentMethodArr.ExternalBankTerminalIsUsed Then
							// If payment was earlier authorized manually (reference number is filled) or automatically then skip this step
							If IsBlankString(Object.ReferenceNumber) And Not PaymentIsAuthorized Then
								If CheckCreditCardsProcessingSystem() Then
									If Object.Sum <> 0 Then
										If Not AuthorizePayment(vMessage) Then
											pCancel = True;
											tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
											ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
											If Not IsBlankString(Object.ReferenceNumber) Then
												// Most likely payment was authorized but slip was not printed due to out of paper or no connection to the printer error
												PaymentIsAuthorized = True;
												// Call procedure to save payment to the database
												AttachIdleHandler("SaveDocumentToPendingList", 0.1, True);
											EndIf;
											Return;
										Else
											PaymentIsAuthorized = True;
										EndIf;
									Else
										pCancel = True;
										vMessage = NStr("en='Payment amount should be entered!';ru='Не введена сумма платежа!';de='Die Zahlungssumme wurde nicht eingegeben!'");
										tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, vMessage);
										ShowMessageBox(,vMessage);
										Return;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
						// Check payment method card type
						If Not Object.Posted Then
							If ValueIsFilled(Object.CardType) And ValueIsFilled(vPaymentMethodArr.CardType) Then
								If Object.CardType <> vPaymentMethodArr.CardType Then
									For Each vPMItem In Items.PaymentMethod.ChoiceList Do
										vPMCardType = tcOnServer.cmGetAttributeByRef(vPMItem.Value, "CardType");
										If vPMCardType = Object.CardType Then
											If tcOnServer.cmGetAttributeByRef(vPMItem.Value, "IsByCreditCard") Then
												Object.PaymentMethod = vPMItem.Value;
												Break;
											EndIf;
										EndIf;
									EndDo;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If vPaymentMethodArr.BookByCashRegister Then
						If vCashRegisterArr.IsControlledByProgram Then
							If vPaymentMethodArr.PrintCheque And Not ChequeIsPrinted Then
								If Object.Sum <> 0 Or Object.Sum = 0 And Object.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
									// Print cheque at cash register
									StartPrintCheque(vMessage, pCancel);
									If pCancel And Not IsBlankString(vMessage) Then
										tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
										ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage),,NStr("en = 'Error cash register'; de = 'Fehler Registrierkasse'; ru = 'Ошибка ККМ'"));
										If ValueIsFilled(Object.ReferenceNumber) Or PaymentIsAuthorized Then
											// Call procedure to save payment to the database
											AttachIdleHandler("SaveDocumentToPendingList", 0.1, True);		
										EndIf;	
										Return;
									EndIf;
								Else
									pCancel = True;
									vMessage = NStr("en='Payment amount should be entered!';ru='Не введена сумма платежа!';de='Die Zahlungssumme wurde nicht eingegeben!'");
									tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, vMessage);
									ShowMessageBox(,vMessage);
									If ValueIsFilled(Object.ReferenceNumber) Or PaymentIsAuthorized Then
										// Call procedure to save payment to the database
										AttachIdleHandler("SaveDocumentToPendingList", 0.1, True);		
									EndIf;
									Return;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	Except
		vErrorText = BriefErrorDescription(ErrorInfo());
		pCancel = True;
		ShowMessageBox(, vErrorText, , NStr("en='Error'; ru='Ошибка'; de='Fehler'"));
	EndTry;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveDocumentToPendingListAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Write(DocumentWriteMode.Write);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SaveDocumentToPendingListAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveDocumentToPendingList() Export
	SaveDocumentToPendingListAtServer();
EndProcedure // SaveDocumentToPendingList 

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveDocumentToOpenQRCodePaymentForm() Export
	SaveDocumentToPendingListAtServer();
	If ValueIsFilled(Object.Ref) Then
		OpenForm("CommonForm.tcQRCodePaymentForm", New Structure("SelPayment, SelExternalSystem", Object.Ref, ExternalSystem), ThisObject, UUID,,, New NotifyDescription("AfterCloseQRCodePaymentForm", ThisObject), FormWindowOpeningMode.LockWholeInterface); 
	EndIf;
EndProcedure // SaveDocumentToPendingList

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If Not ValueIsFilled(pCurrentObject.Ref) And ValueIsFilled(NewObjectRef) Then
		pCurrentObject.SetNewObjectRef(NewObjectRef);
	EndIf;
	If ValueIsFilled(pCurrentObject.Folio) Then
		If pCurrentObject.PaymentMethod = Catalogs.PaymentMethods.Settlement Then
			If ValueIsFilled(pCurrentObject.Payer) And TypeOf(pCurrentObject.Payer) = Type("CatalogRef.Customers") And pCurrentObject.Payer <> pCurrentObject.Hotel.IndividualsCustomer Then
				If ValueIsFilled(pCurrentObject.Hotel) And pCurrentObject.Hotel.IndividualsCustomer <> pCurrentObject.AccountingCustomer Then
					If pCurrentObject.AccountingCustomer <> pCurrentObject.Folio.Customer And pCurrentObject.Payer = pCurrentObject.AccountingCustomer Then
						vFolioObj = pCurrentObject.Folio.GetObject();
						vFolioObj.Customer = pCurrentObject.AccountingCustomer;
						vFolioObj.Contract = pCurrentObject.AccountingContract;
						vFolioObj.Write();
					EndIf;
				EndIf;
			ElsIf Not cmCheckUserPermissions("HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios") Then
				pCancel = True;
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "Payer";
				vUM.Text = NStr("en='Payer should be filled and be customer!'; de='Zahler sollte gefüllt werden und Firma sein!'; ru='Плательщик должен быть указан и быть контрагентом!'");
				vUM.Message();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Document.Payment.Write", Object.Ref, ThisObject);
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("DocumentRef.ProformaInvoice") Or 
	   TypeOf(pSelectedValue) = Type("DocumentRef.Settlement") Or 
	   TypeOf(pSelectedValue) = Type("DocumentRef.DebitNote") Or 
	   TypeOf(pSelectedValue) = Type("DocumentRef.CreditNote") Then
		If Object.AccountingCustomer = tcOnServer.cmGetAttributeByRef(pSelectedValue, "AccountingCustomer") And 
		   Object.GuestGroup = tcOnServer.cmGetAttributeByRef(pSelectedValue, "GuestGroup") Then
			InvoiceOnChangeAtServer(pSelectedValue);
		EndIf;
	ElsIf TypeOf(pSelectedValue) = Type("Structure") And pSelectedValue.Property("CreditCardProcessingSystem") Then
		CreditCardProcessingSystem = pSelectedValue.CreditCardProcessingSystem;
		Write(New Structure("WriteMode", DocumentWriteMode.Posting));
	EndIf;
EndProcedure // ChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		OnCloseAtServer();
	EndIf;
EndProcedure // OnClose

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SessionParameters.CurrentUser.Change" Then
		EmployeePINCodeChecked = True;
		If Not ValueIsFilled(Object.Ref) Then
			Object.Author = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		EndIf;
		If pParameter.ModeAfterCheck = "BeforeWrite" Then
			If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
				Close();
			EndIf;
		EndIf;
	ElsIf pEventName = "CreditCard.Write" And pSource = Items.CreditCard And ValueIsFilled(pParameter) And tcOnServer.cmGetAttributeByRef(pParameter, "CardOwner") = Object.Payer Then
		If Items.CreditCard.ChoiceList.FindByValue(pParameter) = Undefined Then
			Items.CreditCard.ChoiceList.Add(pParameter);
		EndIf;
		Object.CreditCard = pParameter;
		CreditCardOnChange(Items.CreditCard);
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	ProcessingReadCard(vEventData.DeviceData);
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SumOnChange(pItem)
	If Object.Sum = -0.01 And Items.Sum.DropListButton Then
		Object.Sum = Sum;
		Items.Sum.ChoiceList.Clear();
		ShowAllDatesMode = True;
		vAmountsList = FillListOfDefaultPaymentAmounts();
		If vAmountsList.Count() > 0 Then
			For Each vAmountsListItem In vAmountsList Do
				Items.Sum.ChoiceList.Add(vAmountsListItem.Value, vAmountsListItem.Presentation);
			EndDo;
			// Open choice list
			ShowChooseFromList(New NotifyDescription("AccountingDateChoiceCompleted", ThisObject), Items.Sum.ChoiceList, Items.Sum);
			// Return
			Return;
		EndIf;
	EndIf;
	SumOnChangeAtServer();
EndProcedure // SumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SumStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	If MultipleAdvanceSectionsMode Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // SumStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingDateChoiceCompleted(pListItem, pExtraParams) Export
	If pListItem <> Undefined Then
		Object.Sum = pListItem.Value;
		SumOnChange(Items.Sum);
	EndIf;
	Items.Sum.ChoiceList.Clear();
	ShowAllDatesMode = False;
	vAmountsList = FillListOfDefaultPaymentAmounts();
	If vAmountsList.Count() > 0 Then
		For Each vAmountsListItem In vAmountsList Do
			Items.Sum.ChoiceList.Add(vAmountsListItem.Value, vAmountsListItem.Presentation);
		EndDo;
	EndIf;
EndProcedure // AccountingDateChoiceCompleted

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearPreauthorisation()
	Object.Preauthorisation = Undefined;
	Object.AuthorizationCode = "";
	Object.CardType = Undefined;
	Object.CardOperationDate = Undefined;
	Object.CreditCard = Undefined;
	Object.TerminalNumber = "";
	Items.GroupPreauthorisationCalculation.ShowTitle = False;
	Items.ClearLinkToPreauthorisation.Visible = False;
	Items.ClearLinkToPreauthorisation.Enabled = False;
EndProcedure // ClearPreauthorisation

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentMethodOnChange(pItem)
	// Fill list of cash registers allowed for the current user
	FillListOfCashRegisters();
	// Set default cash register
	vSetDefaultCashRegister = False;
	If ValueIsFilled(Object.PaymentMethod) Then 
		If tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "BookByCashRegister") Then
			If Not ValueIsFilled(Object.CashRegister) Then
				vSetDefaultCashRegister = True;
			Else 
				If CashRegistersList.FindByValue(Object.CashRegister) = Undefined Then
					vSetDefaultCashRegister = True;
				EndIf;
			EndIf;
		Else
			Object.CashRegister = Undefined;
			SetIsCorrectionAppearance();
		EndIf;
		// Clear preauth ref if it's not by bank card
		If Not tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "IsByCreditCard") Then
			If ValueIsFilled(Object.Preauthorisation) Then
				ClearPreauthorisation();
			EndIf;
		EndIf;
	EndIf;
	If vSetDefaultCashRegister Then
		If SetDefaultCashRegister() Then
			vNotify = New NotifyDescription("AfterCashRegisterChoice", ThisObject, New Structure("CheckInvoices", False));
			CashRegistersList.ShowChooseItem(vNotify, NStr("en='Select cash register please!';ru='Выберите ККМ!';de='Wählen Sie Registrierkasse!'"));
		Else
			CashRegisterOnChangeAtServer();
		EndIf;
	EndIf;
	// Check if there are advance rows
	If Object.PaymentSections.Count() > 1 And Object.PaymentMethod <> PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
		vRecalcTotals = False;
		i = 0;
		While i < Object.PaymentSections.Count() Do
			vPSRow = Object.PaymentSections.Get(i);
			If vPSRow.Sum < 0 Then
				Object.PaymentSections.Delete(i);
				vRecalcTotals = True;
			Else
				i = i + 1;
			EndIf;
		EndDo;
		If vRecalcTotals Then
			Object.SumInFolioCurrency = Object.PaymentSections.Total("SumInFolioCurrency");
			Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
			Object.Sum = Object.PaymentSections.Total("Sum");
			Object.VATSum = Object.PaymentSections.Total("VATSum");
			FillPrintableChequePositions();
		EndIf;
	EndIf;
	ExternalSystem = tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "ExternalSystem");
	Items.UpdateCardBalance.Visible = ValueIsFilled(ExternalSystem);
	If ExternalSystem.IsEmpty() Then
		// Discount card
		vCard = Object.DiscountCard;
		If ValueIsFilled(vCard) And ValueIsFilled(Object.PaymentMethod) Then
			vLoyaltyType = tcOnServer.cmGetAttributeByRef(vCard, "LoyaltyType");
			If vLoyaltyType = PredefinedValue("Enum.LoyaltyType.Certificate") And tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "IsByBonuses") Then
				Object.DiscountCard = Undefined;
				tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'The gift card has been cleared because does not match the payment method'; de = 'Das Geschenkkarte wurde gelöscht, da es nicht mit der Zahlungsmethode übereinstimmt'; ru = 'Номер подарочной карты был очищен, т.к. не соответствует  способу оплаты'"));
			ElsIf vLoyaltyType = PredefinedValue("Enum.LoyaltyType.Bonuses") And tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "IsByGiftCertificate") Then
				Object.DiscountCard = Undefined;
				tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Bonus card has been cleared because does not match the payment method'; de = 'Die Bonuskarte wurde gelöscht, da sie nicht mit der Zahlungsmethode übereinstimmt'; ru = 'Бонусная карта была очищена, т.к. не соответствует  способу оплаты'"));
			EndIf;	
		EndIf;
		FillBalanceByCard(True);
	EndIf;
	If IsNew Then
		If ValueIsFilled(Object.PaymentMethod) And tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "NoAdvances") Then 
			If ValueIsFilled(Object.Hotel) And (tcOnServer.cmGetAttributeByRef(Object.Hotel, "SplitFolioBalanceByPaymentSections") Or tcOnServer.cmGetAttributeByRef(Object.Hotel, "SplitFolioBalanceByServicesAndPrices")) Then
				vDoPaymentRefill = True;
				If ValueIsFilled(Object.PaymentSection) Then
					If tcOnServer.cmGetAttributeByRef(Object.PaymentSection, "ChequeItemType") <> PredefinedValue("Enum.ChequeItemTypes.Payment") Then
						vDoPaymentRefill = False;
					EndIf;
				Else
					If Object.PaymentSections.Count() = 0 Then
						vDoPaymentRefill = False;
					Else
						For Each vPSRow In Object.PaymentSections Do
							If Not ValueIsFilled(vPSRow.PaymentSection) Then
								vDoPaymentRefill = False;
								Break;
							ElsIf ValueIsFilled(vPSRow.PaymentSection) And tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "ChequeItemType") <> PredefinedValue("Enum.ChequeItemTypes.Payment") Then
								vDoPaymentRefill = False;
								Break;
							EndIf;
						EndDo;
					EndIf;
				EndIf;
				If vDoPaymentRefill Then
					// Fill payment services
					RefillPaymentWithServices();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// City ledger payment
	Items.Payer.ChooseType = True;
	Items.Payer.AutoMarkIncomplete = False;
	Items.Payer.AutoChoiceIncomplete = False;
	If Object.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.Settlement") Then
		If ValueIsFilled(Object.Folio) And ValueIsFilled(Object.Hotel) Then
			vCustomer = tcOnServer.cmGetAttributeByRef(Object.Folio, "Customer");
			vIndividualsCustomer = tcOnServer.cmGetAttributeByRef(Object.Hotel, "IndividualsCustomer");
			If ValueIsFilled(vCustomer) And vCustomer <> vIndividualsCustomer Then
				Object.Payer = vCustomer;
			Else
				Object.Payer = PredefinedValue("Catalog.Customers.EmptyRef");
			EndIf;
			Items.Payer.ChooseType = False;
			Items.Payer.AutoMarkIncomplete = True;
			Items.Payer.AutoChoiceIncomplete = True;
		EndIf;
	EndIf;
	FillDiscountCard(True);
	FillCompanyAndCashRegisterCollapsedRepresentation();
	SendPayerContactsRefresh(False, False, False, True);
EndProcedure // PaymentMethodOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure RefillPaymentWithServices()
	vObj = FormAttributeToValue("Object");
	vObj.AdditionalProperties.Insert("AdvanceMode", False);
	vObj.AdditionalProperties.Insert("PrepaymentMode", False);
	vObj.AdditionalProperties.Insert("SkipFillPaymentMethod", True);
	vObj.PaymentSections.Clear();
	If ValueIsFilled(vObj.PaymentSection) And vObj.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
		vObj.PaymentSection = Undefined;
	EndIf;
	vObj.Sum = 0;
	vObj.SumInFolioCurrency = 0;
	vObj.VATSum = 0;
	vObj.VATSumInFolioCurrency = 0;
	vObj.Remarks = "";
	vObj.Fill(vObj.Folio); 
	ValueToFormAttribute(vObj, "Object");
	// Set appearance of payment sections tabular part
	SetAppearancePaymentSections();
EndProcedure // RefillPaymentWithServices

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentCurrencyOnChange(pItem)
	PaymentCurrencyOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeRateDateOnChange(pItem)
	PaymentCurrencyOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsCorrectionChequeOnChange(pItem)
	Items.CorrectionChequeParametersGroup.Visible = IsCorrectionCheque;
EndProcedure // IsCorrectionChequeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoiceChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If ValueIsFilled(pSelectedValue) And TypeOf(pSelectedValue) <> Type("Type") Then
		pStandardProcessing = False;
		InvoiceOnChangeAtServer(pSelectedValue);
	EndIf;
EndProcedure // InvoiceChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardOnChange(pItem)
	If ValueIsFilled(Object.DiscountCard) And tcOnServer.cmGetAttributeByRef(Object.DiscountCard, "LoyaltyType") = PredefinedValue("Enum.LoyaltyType.Bonuses") Then
		vDiscountCardClient = tcOnServer.cmGetAttributeByRef(Object.DiscountCard, "Client");
		vFolioClient = tcOnServer.cmGetAttributeByRef(Object.Folio, "Client");
		If ValueIsFilled(vDiscountCardClient) And ValueIsFilled(vFolioClient) And vDiscountCardClient <> vFolioClient Then
			If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt") Then
				Object.DiscountCard = Undefined;
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'There is no right to use a client''s discount card in documents of other clients!'; de = 'Es besteht kein Recht, die Rabattkarte eines Kunden in Dokumenten anderer Kunden zu verwenden!'; ru = 'Нет права использовать дисконтную карту клиента в документах других клиентов!'"));
			EndIf;
		EndIf;
	EndIf;
		
	If Not ValueIsFilled(ExternalSystem) Then
		vPMHasChanged = FillBalanceByCard();
		IsPhysicalCard = False;
		If vPMHasChanged Then
			PaymentMethodOnChange(Items.PaymentMethod);
		EndIf;
	Else
		If ValueIsFilled(Object.DiscountCard) Then
			fmGetExternalCardBalance(Object.DiscountCard);
		Else
			FillCardBalanceTitle();
		EndIf;
	EndIf;
EndProcedure // DiscountCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	pStandardProcessing = False;
	If StrLen(pText) > 2 Then
		vChoiceDataUID = DiscountCardAutoCompleteAtServer(pText);
		vChoiceData = GetFromTempStorage(vChoiceDataUID);
		If vChoiceData.Count() = 0 And Not ValueIsFilled(ExternalSystem) Then
			vChoiceData.Add(pText, NStr("en='--Not found--';ru='--Не найдена--';de='--Nicht gefunden--'"));
		EndIf; 
		pChoiceData = vChoiceData;
	EndIf;
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	pStandardProcessing = False;
	// Use external loyalty system
	If ValueIsFilled(ExternalSystem) And StrLen(pText) > 9 Then
		// 1. Get card and balance
		fmGetExternalCardBalance(pText);	
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionOnChange(pItem)
	PaymentSectionOnChangeAtServer();
EndProcedure // PaymentSectionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SumEditTextChange(pItem, pText, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SumEditTextChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentOnChange(pItem)
	If ValueIsFilled(Object.Payment) Then
		CorrectionDocumentDate = BegOfDay(tcOnServer.cmGetAttributeByRef(Object.Payment, "Date"));
	EndIf;
EndProcedure // PaymentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionClearing(pItem, pStandardProcessing)
	If AdvanceMode Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // PaymentSectionClearing

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsSumOnChange(pItem)
	PaymentSectionsSumOnChangeAtServer();
EndProcedure // PaymentSectionsSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsChequeServiceOnChange(pItem)
	PaymentSectionsChequeServiceOnChangeAtServer();
EndProcedure // PaymentSectionsChequeServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsPaymentSectionOnChange(pItem)
	PaymentSectionsPaymentSectionOnChangeAtServer();
EndProcedure // PaymentSectionsPaymentSectionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsChequeServicePriceOnChange(pItem)
	PaymentSectionsChequeServicePriceOnChangeAtServer();
EndProcedure // PaymentSectionsChequeServicePriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsChequeServiceQuantityOnChange(pItem)
	PaymentSectionsChequeServiceQuantityOnChangeAtServer();
EndProcedure // PaymentSectionsChequeServiceQuantityOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionsSumOnChangeAtServer()
	vCurRow = Items.PaymentSections.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.PaymentSections.FindByID(vCurRow);
		If vCurData <> Undefined Then
			If Items.PaymentSectionsChequeService.Visible Then
				If ValueIsFilled(vCurData.ChequeService) Then
					If vCurData.ChequeServiceQuantity = 0 Then
						vCurData.ChequeServiceQuantity = 1;
					EndIf;
					If vCurData.ChequeServicePrice <> 0 Then
						vCurData.ChequeServiceQuantity = Round(vCurData.Sum / vCurData.ChequeServicePrice, 7);
					ElsIf vCurData.Sum <> 0 And vCurData.ChequeServiceQuantity <> 0 Then
						vCurData.ChequeServicePrice = Round(vCurData.Sum / vCurData.ChequeServiceQuantity, 2);
					Else
						vCurData.ChequeServicePrice = vCurData.Sum;
						vCurData.ChequeServiceQuantity = 1;
					EndIf;
				Else
					vCurData.ChequeServicePrice = vCurData.Sum;
					vCurData.ChequeServiceQuantity = 1;
				EndIf;
			EndIf;
			vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, Object.Date);
			vCurData.SumInFolioCurrency = Round(cmConvertCurrencies(vCurData.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.FolioCurrency, Object.FolioCurrencyExchangeRate,	Object.ExchangeRateDate, Object.Hotel), 2);
			vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, Object.Date);
			// Recalculate payment totals
			Object.SumInFolioCurrency = Object.PaymentSections.Total("SumInFolioCurrency");
			Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
			Object.Sum = Object.PaymentSections.Total("Sum");
			Object.VATSum = Object.PaymentSections.Total("VATSum");
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionsChequeServiceOnChangeAtServer()
	vCurRow = Items.PaymentSections.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.PaymentSections.FindByID(vCurRow);
		If vCurData <> Undefined Then
			If ValueIsFilled(vCurData.ChequeService) Then
				vVATRate = Undefined;
				vChequeService = vCurData.ChequeService;
				vPaymentSection = vChequeService.PaymentSection;
				If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
					vCurData.PaymentSection = vPaymentSection;
					vVATRate = vPaymentSection.VATRate;
				Else
					vServiceAttrs = vChequeService.GetObject().pmGetServicePrices(Object.Hotel, Object.Date);
					For Each vServiceAttrsRow In vServiceAttrs Do
						If ValueIsFilled(vServiceAttrsRow.VATRate) Then
							vVATRate = vServiceAttrsRow.VATRate;
							Break;
						EndIf;
					EndDo;
				EndIf;
				If ValueIsFilled(vVATRate) Then
					vCurData.VATRate = vVATRate;
					vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, Object.Date);
					vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, Object.Date);
					// Recalculate payment totals
					Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
					Object.VATSum = Object.PaymentSections.Total("VATSum");
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsChequeServiceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionsPaymentSectionOnChangeAtServer()
	vCurRow = Items.PaymentSections.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.PaymentSections.FindByID(vCurRow);
		If vCurData <> Undefined Then
			vPaymentSection = vCurData.PaymentSection;
			If ValueIsFilled(vPaymentSection) Then
				vVATRate = ?(Object.Company.IsUsingSimpleTaxSystem, Object.Company.VATRate, vPaymentSection.VATRate);
				If ValueIsFilled(vVATRate) Then
					vCurData.VATRate = vVATRate;
					vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, Object.Date);
					vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, Object.Date);
					// Recalculate payment totals
					Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
					Object.VATSum = Object.PaymentSections.Total("VATSum");
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsPaymentSectionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsOnChange(pItem)
	Object.BonusesAreProcessed = False;
	FillPrintableChequePositions();
EndProcedure // PaymentSectionsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsChequeServiceChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If ValueIsFilled(pSelectedValue) Then
		pStandardProcessing = False;
		vCurRow = Items.PaymentSections.CurrentRow;
		If vCurRow <> Undefined Then
			vCurData = Object.PaymentSections.FindByID(vCurRow);
			If vCurData <> Undefined Then
				vCurData.ChequeService = pSelectedValue;
			EndIf;
			PaymentSectionsChequeServiceOnChangeAtServer();
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsChequeServiceChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsBeforeRowChange(pItem, pCancel)
	vCurRow = Items.PaymentSections.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.PaymentSections.FindByID(vCurRow);
		If vCurData <> Undefined And AdvanceSettlementMode Then
			If IsAdvancePaymentSection(vCurData.PaymentSection) Then
				pCancel = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsBeforeRowChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsBeforeDeleteRow(pItem, pCancel)
	vCurRow = Items.PaymentSections.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.PaymentSections.FindByID(vCurRow);
		If vCurData <> Undefined And AdvanceSettlementMode Then
			If IsAdvancePaymentSection(vCurData.PaymentSection) Then
				pCancel = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsOnEditEnd(pItem, pNewRow, pCancelEdit)
	// Calculate advance settlement amount
	If AdvanceSettlementMode Then
		RecalculateAdvanceAmount();
	EndIf;
EndProcedure // PaymentSectionsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsAfterDeleteRow(pItem)
	// Calculate advance settlement amount
	If AdvanceSettlementMode Then
		RecalculateAdvanceAmount();
	EndIf;
	// Recalculate payment totals
	Object.SumInFolioCurrency = Object.PaymentSections.Total("SumInFolioCurrency");
	Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
	Object.Sum = Object.PaymentSections.Total("Sum");
	Object.VATSum = Object.PaymentSections.Total("VATSum");
EndProcedure // PaymentSectionsAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure SendPayerContactsToOFDOnChange(pItem)
	SendPayerContactsRefresh(False, False, False, False);
EndProcedure // SendPayerContactsToOFDOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterOnChange(pItem)
	SetIsCorrectionAppearance();
	FillCompanyAndCashRegisterCollapsedRepresentation();
	SendPayerContactsRefresh(False, False, True, False);
EndProcedure // CashRegisterOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCompanyAndCashRegisterCollapsedRepresentation()
	Items.CompanyAndCashRegister.CollapsedRepresentationTitle = ?(ValueIsFilled(Object.CashRegister), TrimAll(Object.CashRegister) + ", ", "") + TrimAll(Object.Company);
	Items.CompanyAndCashRegister.Title = Items.CompanyAndCashRegister.CollapsedRepresentationTitle;
	vPOS = Object.CashRegister;
	vPM = Object.PaymentMethod;
	If ValueIsFilled(vPOS) And vPOS.IsControlledByProgram And 
	   ValueIsFilled(vPM) And vPM.BookByCashRegister And vPM.PrintCheque Then
		Items.GroupChequePositions.Visible = True;
		Items.PaymentSectionsGroup.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Items.PaymentSectionsList.ShowTitle = True;
	Else
		Items.GroupChequePositions.Visible = False;
		Items.PaymentSectionsGroup.PagesRepresentation = FormPagesRepresentation.None;
		Items.PaymentSectionsList.ShowTitle = False;
	EndIf;
	FillPrintableChequePositions();
EndProcedure // FillCompanyAndCashRegisterCollapsedRepresentation

// -----------------------------------------------------------------------------
&AtServer
Function FillPrintableChequePositions(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	ChequePositionsTotalSum = "";
	ChequePositions.Clear();
	If Items.GroupChequePositions.Visible Then
		vIsPrepayment = False;
		vUseAveragePrice = False;
		vRowsArray = tcCashRegisters.GetPrintableChequePositions(vObj, vIsPrepayment, vUseAveragePrice);
		For Each vRowStruct In vRowsArray Do
			vChequeRow = ChequePositions.Add();
			FillPropertyValues(vChequeRow, vRowStruct);
			If ValueIsFilled(vRowStruct.Item) Then
				vChequeRow.ChequeService = vRowStruct.Item;
			EndIf;
		EndDo;
		ChequePositionsTotalSum = cmFormatSum(ChequePositions.Total("Sum"), vObj.PaymentCurrency);
		Items.ChequePositions.Footer = Not Items.Sum.Visible;
	EndIf;
EndFunction // FillPrintableChequePositions

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure GetNextGiftCertificate(pCommand)
	vLastNumber = GetNextGiftCertificateAtServer();
	If Not IsBlankString(vLastNumber) Then
		Try 
			vNextNumber = Number(vLastNumber) + 1;
			Object.GiftCertificate = Format(vNextNumber, "ND=12; NFD=0; NG=");
		Except
			Object.GiftCertificate = vLastNumber;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to calculate next vacant gift card number! Number being last used is set instead!'; ru = 'Не удалось вычислить следующий свободный номер подарочной карты. В поле подставлен последний использованный номер.'; de = 'Kann die nächste verfügbare Nummer der Gutschein zu berechnen nicht. Zuletzt benutzte Gutschein Nummer eingestellt wurde.'"));
		EndTry;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Last used gift card number is not found!'; ru = 'Не удалось найти последний использованный номер подарочного сертификата.'; de = 'Die letzte Gutschein Nummer nicht gefunden ist.'"));
	EndIf;
EndProcedure // GetNextGiftCertificate

// -----------------------------------------------------------------------------
&AtClient
Procedure SendOnlineCheque(pCommand)
	If Not ValueIsFilled(Object.Ref) Then
		ShowMessageBox(, NStr("en='Document is new!'; ru='Документ еще не записан!'; de='Dokument ist neu!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(Object.CashRegister) Then
		ShowMessageBox(, NStr("en='Cash register is empty!'; ru='Не указан ККМ!'; de='Kasse ist leer!'"));
		Return;
	EndIf;
	OpenForm("Catalog.CashRegisters.Form.tcSendOnlineCheque", New Structure("Payment", Object.Ref), ThisObject, Object.Ref, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // SendOnlineCheque

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintCorrectionCheque(pCommand)
	vMessage = "";
	vIsPosted = Object.Posted;
	If Not vIsPosted Then
		If Write(New Structure("WriteMode, PostingMode", PredefinedValue("DocumentWriteMode.Posting"), PredefinedValue("DocumentPostingMode.Regular"))) Then
			Close();
		Else
			Return;
		EndIf;
	Else
		If ValueIsFilled(Object.CashRegister) Then
			vCashRegisterArr = tcOnServer.cmGetAtributeAsArray(Object.CashRegister);
			If ValueIsFilled(Object.PaymentMethod) Then
				vPaymentMethodArr = tcOnServer.cmGetAtributeAsArray(Object.PaymentMethod);
				If vCashRegisterArr.IsControlledByProgram Then
					If vPaymentMethodArr.PrintCheque Then
						If Object.Sum <> 0 Then
							If Not ChequeIsPrinted Then
								If IsReadyToPrintCheque(vMessage, Object.CashRegister) Then
									vCancel = False;
									StartPrintCheque(vMessage, vCancel);
									If vCancel Then
										If vMessage <> "" Then
											tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, tcOnServer.cmNStrAtServer(vMessage));
											ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
										EndIf;
									Else
										If Modified Then
											WriteAndCloseForm();
										Else
											Close();
										EndIf;
									EndIf;
								Else
									tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, tcOnServer.cmNStrAtServer(vMessage));
									ShowMessageBox(,tcOnServer.cmNStrAtServer(vMessage));
								EndIf;
							Else
								If Modified Then
									WriteAndCloseForm();
								Else
									Close();
								EndIf;
							EndIf;
						Else
							vMessage = NStr("en='Payment amount should be entered!';ru='Не введена сумма платежа!';de='Die Zahlungssumme wurde nicht eingegeben!'");
							tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, vMessage);
							ShowMessageBox(, vMessage);
						EndIf;
					Else
						vMessage = NStr("en='Payment method settings do not allow posting by cash register!'; ru='Способ оплаты не проводится по ККМ!'; de='Zahlungsmethodeneinstellungen erlauben keine Buchung per Kasse!'");
						tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, vMessage);
						ShowMessageBox(, vMessage);
					EndIf;
				Else
					vMessage = NStr("en='Cash register should be connected to the program!'; ru='ККМ должен быть подключен к программе!'; de='Die Kasse sollte mit dem Programm verbunden sein!'");
					tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, vMessage);
					ShowMessageBox(, vMessage);
				EndIf;
			Else
				vMessage = NStr("en='Payment method should be filled!'; ru='Не указан способ оплаты!'; de='Zahlungsmethode sollte ausgefüllt werden!'");
				tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, vMessage);
				ShowMessageBox(, vMessage);
			EndIf;
		Else
			vMessage = NStr("en='Cash register should be filled!'; ru='Не указан ККМ!'; de='Die Kasse sollte ausgefüllt werden!'");
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,, vMessage);
			ShowMessageBox(, vMessage);
		EndIf;
	EndIf;
EndProcedure // PrintCorrectionCheque

// -----------------------------------------------------------------------------
&AtClient
Procedure SetDeletionMarkAction(pCommand)
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	If Modified Then
		Modified = False;
	EndIf;
	SetDeletionMarkAtServer();
	Read();
	Notify("Document.Payment.Write", Object.Ref, ThisObject);
	Close();
EndProcedure // SetDeletionMarkAction

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintSlip(Command)
	vMessage = "";
	vCashRegister = Object.CashRegister;
	If ValueIsFilled(vCashRegister) And Not IsBlankString(Object.SlipText) Then
		vCashRegisterArr =  tcOnServer.cmGetAtributeAsArray(vCashRegister);
		If IsReadyToPrintCheque(vMessage, vCashRegister) Then
			vSlipTxtArr = tcOnServer.GetTextLinesArray(Object.SlipText);
			vDriver = tcOnClient.cmGetModulTO(vCashRegisterArr);
			If Not vDriver = Undefined Then
				vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, vCashRegisterArr);
				vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
				|de='Input cash register password please...';
				|en='Input cash register password please...'");
				
				If IsBlankString(vPasswordKKM) Then
					pCancel = True;
					vNotifity = New NotifyDescription("PrintSlipAfterInputCashRegisterPassword",ThisObject,New Structure("Driver,rMessage,pCashRegister,pSlipTextArr", vDriver, vMessage, vCashRegisterArr, vSlipTxtArr));
					// Show InputCashRegisterPassword
					OpenForm("CommonForm.tcInputCashRegisterPassword",New Structure("LabelDescription",vQuestion),,,,,vNotifity);
				Else
					vDriver.pmPrintSlip(vSlipTxtArr, vCashRegisterArr, vMessage, vPasswordKKM);
				EndIf;
			Else
				ShowMessageBox(,Nstr("en = 'Work with driver this device is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
				Return;
			EndIf;	
		EndIf;	
	EndIf;	
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(,vMessage,,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintAnnulationSlip(Command)
	vMessage = "";
	vCashRegister = Object.CashRegister;
	If ValueIsFilled(vCashRegister) And Not IsBlankString(Object.AnnulationSlipText) Then
		vCashRegisterArr =  tcOnServer.cmGetAtributeAsArray(vCashRegister);
		If IsReadyToPrintCheque(vMessage, vCashRegister) Then
			vSlipTxtArr = tcOnServer.GetTextLinesArray(Object.AnnulationSlipText);
			vDriver = tcOnClient.cmGetModulTO(vCashRegisterArr);
			If Not vDriver = Undefined Then
				vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(,vCashRegisterArr);
				vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
				|de='Input cash register password please...';
				|en='Input cash register password please...'");
				
				If IsBlankString(vPasswordKKM) Then
					pCancel = True;
					vNotifity = New NotifyDescription("PrintSlipAfterInputCashRegisterPassword",ThisObject,New Structure("Driver,rMessage,pCashRegister,pSlipTextArr", vDriver, vMessage, vCashRegisterArr, vSlipTxtArr));
					// Show InputCashRegisterPassword
					OpenForm("CommonForm.tcInputCashRegisterPassword",New Structure("LabelDescription",vQuestion),,,,,vNotifity);
				Else
					vDriver.pmPrintSlip(vSlipTxtArr, vCashRegisterArr, vMessage, vPasswordKKM);
				EndIf;
			Else
				ShowMessageBox(,Nstr("en = 'Work with driver this device is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
				Return;
			EndIf;
		EndIf;	
	EndIf;	
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(,vMessage,,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OrderRevokeQr(pCommand)
	If fRevokeExternalPayment() Then
		SaveDocumentToPendingListAtServer();	
		SetDeletionMarkAtServer();
		Close();
	EndIf;
EndProcedure // OrderRevokeQr

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowCheque(pCommand)
	OpenForm("Catalog.CashRegisters.Form.tcShowCheque", New Structure("SelDocument", Object.Ref), ThisObject, UUID);
EndProcedure // ShowCheque

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
	EndIf;
EndProcedure // OnCloseAtServer

// -----------------------------------------------------------------------------
&AtServer
Function FillBalanceByCard(pServerMode = False)
	vPMHasChanged = False;
	Items.DecorationBalance.Title = "";
	
	vCard = Object.DiscountCard;
	If ValueIsFilled(vCard) Then
		If ValueIsFilled(vCard.LoyaltyType) Then
			If vCard.LoyaltyType = Enums.LoyaltyType.Bonuses Then
				Items.DiscountCard.Title = Nstr("en = 'Bonus card'; de = 'Bonuskarte'; ru = 'Бонусная карта'");
			ElsIf vCard.LoyaltyType = Enums.LoyaltyType.Certificate Then
				Items.DiscountCard.Title = Nstr("en = 'Gift card'; de = 'Geschenkkarte'; ru = 'Сертификат'");
			EndIf;	
		EndIf;	

		vDataCard = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCard, Object.Date, Object.ExchangeRateDate, Object.Hotel);

		vArrFD = New Array;
		If vCard.LoyaltyType = Enums.LoyaltyType.Bonuses Then
			vText = NStr("en = 'Bonuses available:'; de = 'Verfügbare Boni:'; ru = 'Доступно бонусов:'");
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", vText, New Font(,9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(vDataCard.BalanceAmount, "NFD=2; NDS=.; NZ=0.00; NG=0"), New Font(,11,True), new Color(0,128,0)));
		ElsIf vCard.LoyaltyType = Enums.LoyaltyType.Certificate Then
			vText = NStr("en = 'Balance: '; de = 'Kontostand: '; ru = 'Остаток: '");
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", vText, New Font(,9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(vDataCard.BalanceAmount, "NFD=2; NDS=.; NZ=0.00; NG=0"), New Font(,11,True), new Color(0,128,0)));
		EndIf;
		If ValueIsFilled(vCard.ValidTo) Then
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", NStr("en=' till '; ru=' до '; de=' bis '") + Format(vCard.ValidTo, "DF=dd.MM.yyyy"), New Font(,9), ?(vCard.ValidTo < CurrentSessionDate(), WebColors.Red, Undefined)));
		EndIf;
		If vCard.IsBlocked Then
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", NStr("en=' is blocked'; ru=' заблокирована'; de=' ist blockiert'"), New Font(,9), WebColors.Red));
		EndIf;
		If vArrFD.Count() > 0 Then
			Items.DecorationBalance.Title = tcOnServer.cmGenerateFormattedString(vArrFD);
		EndIf;
		// Change payment method
		If Not pServerMode And Object.PaymentSections.Count() > 0 And ValueIsFilled(Object.PaymentSections.Get(0).ChequeService) Then
			For Each vPMItem In Items.PaymentMethod.ChoiceList Do
				vPM = vPMItem.Value;
				If vCard.LoyaltyType = Enums.LoyaltyType.Bonuses And vPM.IsByBonuses Then
					If Object.PaymentMethod <> vPM Then
						vPMHasChanged = True;
						Object.PaymentMethod = vPM;
					EndIf;
					Break;
				ElsIf vCard.LoyaltyType = Enums.LoyaltyType.Certificate And vPM.IsByGiftCertificate Then
					If Object.PaymentMethod <> vPM Then
						vPMHasChanged = True;
						Object.PaymentMethod = vPM;
					EndIf;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vPMHasChanged;
EndFunction // FillBalanceByCard

// -----------------------------------------------------------------------------
&AtServer
Procedure SetAppearancePaymentSections(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	AdvanceMode = False;
	AdvanceSettlementMode = False;
	If ValueIsFilled(vObj.PaymentSection) And vObj.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
		AdvanceMode = True;
	ElsIf vObj.PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement And vObj.Sum = 0 Then
		AdvanceSettlementMode = True;
	EndIf;
	MultipleAdvanceSectionsMode = MultipleAdvancePaymentSectionsMode();
	vFolio = vObj.Folio;
	vFolioPaymentSection = Undefined;
	If ValueIsFilled(vFolio) Then
		vFolioPaymentSection = vFolio.PaymentSection;
	EndIf;
	If ValueIsFilled(vObj.Hotel) And vObj.Hotel.SplitFolioBalanceByPaymentSections Then
		If AdvanceSettlementMode Then
			Items.PaymentSectionsGroup.Visible = True;
			Items.PaymentSection.Visible = False;
			Items.PaymentSection.ReadOnly = True;
			Items.PaymentSection.ClearButton = False;
			Items.Sum.Visible = False;
			Items.Sum.ReadOnly = True;
			Items.Sum.ChoiceListButton = False;
			Items.Sum.ChoiceButton = False;
			Items.PaymentCurrency.Visible = False;
			Items.PaymentMethod.ReadOnly = True;
			Items.PaymentSections.Visible = True;
			Items.PaymentSections.ReadOnly = False;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = False;
			Items.PaymentSectionsChequeService.Visible = True;
			Items.PaymentSectionsChequeServicePrice.Visible = True;
			Items.PaymentSectionsChequeServiceQuantity.Visible = True;
		ElsIf MultipleAdvanceSectionsMode Then
			Items.PaymentSectionsGroup.Visible = True;
			Items.PaymentSection.Visible = False;
			Items.Sum.Visible = True;
			Items.Sum.ReadOnly = False;
			Items.Sum.TextEdit = False;
			Items.Sum.ChoiceListButton = True;
			Items.Sum.ChoiceButton = False;
			Items.PaymentCurrency.Visible = True;
			Items.PaymentMethod.ReadOnly = False;
			Items.PaymentSections.ReadOnly = False;
			Items.PaymentSections.Visible = True;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = True;
			Items.PaymentSectionsChequeService.Visible = False;
			Items.PaymentSectionsChequeServicePrice.Visible = False;
			Items.PaymentSectionsChequeServiceQuantity.Visible = False;
			Items.PaymentSectionsVATRate.ReadOnly = True;
			Items.PaymentSectionsVATSum.ReadOnly = True;
			Items.PaymentSectionsMarkingCode.Visible = False;
			Items.ChequePositionsPaymentSection.HorizontalStretch = True;
			Items.ChequePositionsChequeService.Visible = False;
			Items.ChequePositionsChequeServicePrice.Visible = False;
			Items.ChequePositionsChequeServiceQuantity.Visible = False;
			Items.ChequePositionsMarkingCode.Visible = False;
		ElsIf AdvanceMode Then
			Items.PaymentSectionsGroup.Visible = False;
			Items.PaymentSection.Visible = True;
			Items.PaymentSection.ReadOnly = True;
			Items.PaymentSection.ClearButton = False;
			Items.Sum.Visible = True;
			Items.Sum.ReadOnly = False;
			Items.Sum.ChoiceListButton = True;
			Items.Sum.ChoiceButton = True;
			Items.PaymentCurrency.Visible = True;
			Items.PaymentMethod.ReadOnly = False;
			Items.PaymentSections.ReadOnly = True;
			Items.PaymentSections.Visible = False;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = True;
			Items.PaymentSectionsChequeService.Visible = False;
			Items.PaymentSectionsChequeServicePrice.Visible = False;
			Items.PaymentSectionsChequeServiceQuantity.Visible = False;
		Else		
			Items.PaymentSectionsGroup.Visible = True;
			Items.PaymentSection.Visible = False;
			Items.PaymentSection.ReadOnly = True;
			Items.PaymentSection.ClearButton = False;
			Items.PaymentSections.Visible = True;
			Items.PaymentSections.ReadOnly = False;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = True;
			Items.Sum.ReadOnly = True;
			Items.Sum.ChoiceListButton = False;
			Items.Sum.ChoiceButton = False;
			Items.PaymentSectionsChequeService.Visible = False;
			Items.PaymentSectionsChequeServicePrice.Visible = False;
			Items.PaymentSectionsChequeServiceQuantity.Visible = False;
		EndIf;
	ElsIf ValueIsFilled(vObj.Hotel) And vObj.Hotel.SplitFolioBalanceByServicesAndPrices Then
		If AdvanceSettlementMode Then
			Items.PaymentSectionsGroup.Visible = True;
			Items.PaymentSection.Visible = False;
			Items.PaymentSection.ReadOnly = True;
			Items.PaymentSection.ClearButton = False;
			Items.Sum.Visible = False;
			Items.Sum.ReadOnly = True;
			Items.Sum.ChoiceListButton = False;
			Items.Sum.ChoiceButton = False;
			Items.PaymentCurrency.Visible = False;
			Items.PaymentMethod.ReadOnly = True;
			Items.PaymentSections.Visible = True;
			Items.PaymentSections.ReadOnly = False;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = False;
			Items.PaymentSectionsChequeService.Visible = True;
			Items.PaymentSectionsChequeServicePrice.Visible = True;
			Items.PaymentSectionsChequeServiceQuantity.Visible = True;
		ElsIf MultipleAdvanceSectionsMode Then
			Items.PaymentSectionsGroup.Visible = True;
			Items.PaymentSection.Visible = False;
			Items.Sum.Visible = True;
			Items.Sum.ReadOnly = False;
			Items.Sum.TextEdit = False;
			Items.Sum.ChoiceListButton = True;
			Items.Sum.ChoiceButton = False;
			Items.PaymentCurrency.Visible = True;
			Items.PaymentMethod.ReadOnly = False;
			Items.PaymentSections.ReadOnly = False;
			Items.PaymentSections.Visible = True;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = True;
			Items.PaymentSectionsChequeService.Visible = False;
			Items.PaymentSectionsChequeServicePrice.Visible = False;
			Items.PaymentSectionsChequeServiceQuantity.Visible = False;
			Items.PaymentSectionsMarkingCode.Visible = False;
			Items.PaymentSectionsVATRate.ReadOnly = True;
			Items.PaymentSectionsVATSum.ReadOnly = True;
			Items.ChequePositionsPaymentSection.HorizontalStretch = True;
			Items.ChequePositionsChequeService.Visible = False;
			Items.ChequePositionsChequeServicePrice.Visible = False;
			Items.ChequePositionsChequeServiceQuantity.Visible = False;
			Items.ChequePositionsMarkingCode.Visible = False;
		ElsIf AdvanceMode Then
			Items.PaymentSectionsGroup.Visible = False;
			Items.PaymentSection.Visible = True;
			Items.PaymentSection.ReadOnly = True;
			Items.PaymentSection.ClearButton = False;
			Items.Sum.Visible = True;
			Items.Sum.ReadOnly = False;
			Items.Sum.ChoiceListButton = True;
			Items.Sum.ChoiceButton = True;
			Items.PaymentCurrency.Visible = True;
			Items.PaymentMethod.ReadOnly = False;
			Items.PaymentSections.ReadOnly = False;
			Items.PaymentSections.Visible = False;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = True;
			Items.PaymentSectionsChequeService.Visible = False;
			Items.PaymentSectionsChequeServicePrice.Visible = False;
			Items.PaymentSectionsChequeServiceQuantity.Visible = False;
		Else		
			Items.PaymentSectionsGroup.Visible = True;
			Items.PaymentSection.Visible = False;
			Items.PaymentSection.ReadOnly = True;
			Items.PaymentSection.ClearButton = False;
			Items.Sum.Visible = True;
			Items.Sum.ReadOnly = True;
			Items.Sum.ChoiceListButton = False;
			Items.Sum.ChoiceButton = False;
			Items.PaymentCurrency.Visible = True;
			Items.PaymentMethod.ReadOnly = False;
			Items.PaymentSections.Visible = True;
			Items.PaymentSections.ReadOnly = False;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = False;
			Items.PaymentSectionsChequeService.Visible = True;
			Items.PaymentSectionsChequeServicePrice.Visible = True;
			Items.PaymentSectionsChequeServiceQuantity.Visible = True;
		EndIf;
	Else
		Items.PaymentSectionsGroup.Visible = False;
		Items.PaymentSection.Visible = True;
		Items.PaymentSection.ReadOnly = False;
		Items.PaymentSection.ClearButton = True;
		Items.PaymentSections.Visible = False;
		Items.PaymentSections.ReadOnly = True;
		Items.PaymentMethod.ReadOnly = False;
		Items.Sum.ReadOnly = False;
		Items.Sum.ChoiceListButton = True;
		Items.Sum.ChoiceButton = True;
	EndIf;
EndProcedure // SetAppearancePaymentSections

// -----------------------------------------------------------------------------
&AtServer
Procedure SetCorrectionChequeAttributes()
	If Not ValueIsFilled(Object.Ref) Then 
		Items.SendOnlineCheque.Enabled = False;
		Items.SendOnlineCheque.Visible = False;
		Items.ShowCheque.Enabled = False;
		Items.ShowCheque.Visible = False;
		Items.PrintCorrectionCheque.Visible = False;
		Items.PrintCorrectionCheque.Enabled = False;
	Else
		vAttrRow = cmGetChequeAttributes(Object.Ref);
		If vAttrRow <> Undefined Then
			Items.SendOnlineCheque.Enabled = True;
			Items.SendOnlineCheque.Visible = True;
			If ValueIsFilled(Object.CashRegister) And Not IsBlankString(Object.CashRegister.ChequeVerificationInternetAddress) Then
				Items.ShowCheque.Enabled = True;
				Items.ShowCheque.Visible = True;
			Else
				Items.ShowCheque.Enabled = False;
				Items.ShowCheque.Visible = False;
			EndIf;
			IsCorrectionCheque = vAttrRow.IsCorrection;
			Items.PrintCorrectionCheque.Enabled = False;
			Items.PrintCorrectionCheque.Visible = False;
			// Fill correction parameters
			If IsCorrectionCheque Then
				CorrectionType = vAttrRow.CorrectionType;
				CorrectionDescription = vAttrRow.CorrectionDescription;
				CorrectionDocumentNumber = vAttrRow.CorrectionDocumentNumber;
				CorrectionDocumentDate = vAttrRow.CorrectionDocumentDate;
			Else
				Items.IsCorrectionCheque.Enabled = False;
			EndIf;
		Else
			If Object.DeletionMark Then
				Items.IsCorrectionCheque.Enabled = False;
			EndIf;
			Items.SendOnlineCheque.Enabled = False;
			Items.SendOnlineCheque.Visible = False;
			Items.ShowCheque.Enabled = False;
			Items.ShowCheque.Visible = False;
			Items.PrintCorrectionCheque.Visible = Object.Posted;
			Items.PrintCorrectionCheque.Enabled = Items.PrintCorrectionCheque.Visible;
		EndIf;
	EndIf;
	If Object.CorrectionOfIncorrectCheque And ValueIsFilled(Object.Payment) And Not ValueIsFilled(CorrectionDocumentDate) Then
		CorrectionDocumentDate = BegOfDay(Object.Payment.Date);
	EndIf;
	SetIsCorrectionAppearance();
EndProcedure // SetCorrectionChequeAttributes

// -----------------------------------------------------------------------------
Procedure SetIsCorrectionAppearance()
	If ValueIsFilled(Object.CashRegister) And Object.CashRegister.IsControlledByProgram And 
	   ValueIsFilled(Object.CashRegister.FiscalDataFormatVersions) Then
		Items.IsCorrectionCheque.Enabled = True;
		Items.IsCorrectionCheque.Visible = True;
		Items.CorrectionOfIncorrectCheque.Enabled = True;
		Items.CorrectionOfIncorrectCheque.Visible = True;
	Else
		If Not IsCorrectionCheque Then
			Items.IsCorrectionCheque.Enabled = False;
			Items.IsCorrectionCheque.Visible = False;
		Else
			Items.IsCorrectionCheque.Enabled = True;
			Items.IsCorrectionCheque.Visible = True;
		EndIf;
		If Not Object.CorrectionOfIncorrectCheque Then
			Items.CorrectionOfIncorrectCheque.Enabled = False;
			Items.CorrectionOfIncorrectCheque.Visible = False;
		Else
			Items.CorrectionOfIncorrectCheque.Enabled = True;
			Items.CorrectionOfIncorrectCheque.Visible = True;
		EndIf;
	EndIf;
	Items.CorrectionChequeParametersGroup.Visible = IsCorrectionCheque;
EndProcedure // SetIsCorrectionAppearance

// -----------------------------------------------------------------------------
&AtServer
Function HasPaymentCardData()
	Return True;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPaymentMethods()
	vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios = cmCheckUserPermissions("HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios");
	vPMs = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser, , Object.CashRegister);
	vIsResortFee = False;
	For Each vRowPS In Object.PaymentSections Do
		If ValueIsFilled(vRowPS.ChequeService) And vRowPS.ChequeService.IsResortFee Then
			 vIsResortFee = True;
			 Break;
		EndIf;	
	EndDo;
	vThereAreResortFeePMs = False;
	i = 0;
	While i < vPMs.Count() Do
		vPM = vPMs.Get(i).Value;
		If vPM.IsForResortFee Then
			vThereAreResortFeePMs = True;
			Break;
		EndIf;
		i = i + 1;
	EndDo;
	i = 0;
	While i < vPMs.Count() Do
		vPM = vPMs.Get(i).Value;
		If vPM = Catalogs.PaymentMethods.DepositTransfer Then
			vPMs.Delete(i);
		ElsIf vPM = Catalogs.PaymentMethods.Settlement And Not vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios And 
		     (Not ValueIsFilled(Object.AccountingCustomer) Or ValueIsFilled(Object.AccountingCustomer) And Object.AccountingCustomer.IsIndividual) Then
			vPMs.Delete(i);
		ElsIf Not vIsResortFee And vPM.IsForResortFee Then
			vPMs.Delete(i);
		ElsIf vIsResortFee And vThereAreResortFeePMs And Not vPM.IsForResortFee Then
			vPMs.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	Items.PaymentMethod.ChoiceList.LoadValues(vPMs.UnloadValues());
	// Check payment modes
	If AdvanceSettlementMode Then
		i = 0;
		While i < Items.PaymentMethod.ChoiceList.Count() Do
			vPMListItem = Items.PaymentMethod.ChoiceList.Get(i);
			If vPMListItem.Value <> Catalogs.PaymentMethods.AdvanceSettlement Then
				Items.PaymentMethod.ChoiceList.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	Else
		For Each vPMListItem In Items.PaymentMethod.ChoiceList Do
			If vPMListItem.Value = Catalogs.PaymentMethods.AdvanceSettlement Then
				Items.PaymentMethod.ChoiceList.Delete(vPMListItem);
				Break;
			EndIf;
		EndDo;
	EndIf;
	vWriteOffBonusesAsDiscounts = False;
	If ValueIsFilled(Object.Hotel) Then
		vWriteOffBonusesAsDiscounts = Object.Hotel.WriteOffBonusesAsDiscounts;
	EndIf;
	i = 0;
	While i < Items.PaymentMethod.ChoiceList.Count() Do
		vPMListItem = Items.PaymentMethod.ChoiceList.Get(i);
		vPM = vPMListItem.Value;
		If vPM.IsCloseToTheFolio Or vPM.IsCloseToTheRoom Or 
		   ValueIsFilled(Object.AccountingCustomer) And Object.AccountingCustomer.IsIndividual And vPM = Catalogs.PaymentMethods.Settlement And Not vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios Or 
		   vPM = Catalogs.PaymentMethods.DepositTransfer Then
			Items.PaymentMethod.ChoiceList.Delete(i);
		ElsIf vWriteOffBonusesAsDiscounts And (vPM.IsByBonuses Or vPM.IsByGiftCertificate) Then
			Items.PaymentMethod.ChoiceList.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Check that current payment method is in the list
	If Object.Posted Then
		If ValueIsFilled(Object.PaymentMethod) Then
			If Items.PaymentMethod.ChoiceList.FindByValue(Object.PaymentMethod) = Undefined Then
				Items.PaymentMethod.ChoiceList.Add(Object.PaymentMethod);
			EndIf;
		EndIf;
	EndIf;
	// 
	// Add icons
	For Each vListItem In Items.PaymentMethod.ChoiceList Do
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
EndProcedure // FillListOfPaymentMethods

// -----------------------------------------------------------------------------
&AtServer
Procedure SumOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If MultipleAdvanceSectionsMode And PaymentServicesPerDates.Count() > 0 Then
		// Clear amounts from payment sections
		For Each vPSRow In vObj.PaymentSections Do
			vPSRow.ChequeServicePrice = 0;
			vPSRow.ChequeServiceQuantity = 0;
			vPSRow.Sum = 0;
			vPSRow.VATSum = 0;
			vPSRow.SumInFolioCurrency = 0;
			vPSRow.VATSumInFolioCurrency = 0;
		EndDo;
		// Find rows for accounting date
		vFailure = False;
		vAccountingDateIdx = -1;
		For Each vSumItem In Items.Sum.ChoiceList Do
			If vSumItem.Value = vObj.Sum Then
				If Items.Sum.ChoiceList.IndexOf(vSumItem) = 0 Then
					vAccountingDateIdx = 1;
				Else
					If Items.Sum.ChoiceList.Count() = 3 And Items.Sum.ChoiceList.Get(1).Value = -0.01 Then
						vAccountingDateIdx = 999999;
						Break;
					EndIf;
					If Items.Sum.ChoiceList.IndexOf(vSumItem) = (Items.Sum.ChoiceList.Count() - 1) Then
						vAccountingDateIdx = 999999;
					Else
						vDotIdx = StrFind(vSumItem.Presentation, ".");
						If vDotIdx > 0 Then
							vAccountingDateIdx = Number(Left(vSumItem.Presentation, vDotIdx - 1));
							Break;
						Else
							vFailure = True;
							Break;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vAccountingDateIdx > 0 Then
			For Each vAccountingDateServicesRow In PaymentServicesPerDates Do
				If vAccountingDateIdx = 999999 Or vAccountingDateServicesRow.AccountingDateIndex < vAccountingDateIdx Then
					If vAccountingDateServicesRow.Sum <> 0 Then
						vSrvVATRate = vAccountingDateServicesRow.VATRate;
						If ValueIsFilled(vSrvVATRate) Then
							vPSRow = vObj.PaymentSections.Find(vSrvVATRate, "VATRate");
							If vPSRow <> Undefined Then
								vPSRow.Sum = vPSRow.Sum + vAccountingDateServicesRow.Sum;
							Else
								Raise NStr("en='No advance section for the VAT rate is found: '; ru='Не найдена авансовая секция для ставки НДС: '; de='Es wurde kein Vorschussabschnitt für den Mehrwertsteuersatz gefunden: '") + TrimAll(vSrvVATRate);
							EndIf;
						Else
							Raise NStr("en='Service without VAT rate is found: '; ru='Найдена услуга без ставки НДС: '; de='Service ohne Mehrwertsteuersatz wird gefunden: '") + TrimAll(vAccountingDateServicesRow.Service);
						EndIf;
					EndIf;
				EndIf;
				If vAccountingDateIdx <> 999999 And vAccountingDateServicesRow.AccountingDateIndex >= vAccountingDateIdx Then
					Break;
				EndIf;
			EndDo;
		Else
			vFailure = True;
		EndIf;
		If vFailure Then
			Sum = 0;
			For Each vPSRow In vObj.PaymentSections Do
				vPSRow.ChequeServicePrice = 0;
				vPSRow.ChequeServiceQuantity = 0;
				vPSRow.Sum = 0;
				vPSRow.VATSum = 0;
				vPSRow.SumInFolioCurrency = 0;
				vPSRow.VATSumInFolioCurrency = 0;
			EndDo;
		Else
			For Each vPSRow In vObj.PaymentSections Do
				vPSRow.ChequeServicePrice = vPSRow.Sum;
				vPSRow.ChequeServiceQuantity = 1;
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vObj.Date);
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vObj.Date);
			EndDo;
		EndIf;
		vObj.pmCalculateTotalsByPaymentSections();
		FillPrintableChequePositions(vObj);
	Else
		vObj.VATSum = cmCalculateVATSum(vObj.VATRate, vObj.Sum, vObj.Date);
		vObj.SumInFolioCurrency = Round(cmConvertCurrencies(vObj.Sum, vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
		vObj.VATSumInFolioCurrency = cmCalculateVATSum(vObj.VATRate, vObj.SumInFolioCurrency, vObj.Date);
		If vObj.PaymentSections.Count() > 0 Then
			If AdvanceMode Then
				i = 0;
				vWasUpdated = False;
				While i < vObj.PaymentSections.Count() Do
					vPSRow = vObj.PaymentSections.Get(i);
					If Not vWasUpdated And vObj.PaymentSection = vPSRow.PaymentSection Then
						vWasUpdated = True;
						vPSRow.Sum = vObj.Sum;
						vPSRow.VATSum = vObj.VATSum;
						vPSRow.SumInFolioCurrency = vObj.SumInFolioCurrency;
						vPSRow.VATSumInFolioCurrency = vObj.VATSumInFolioCurrency;
						If vPSRow.ChequeServiceQuantity <> 0 Then
							vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
						EndIf;
						i = i + 1;
					Else
						vObj.PaymentSections.Delete(i);
					EndIf;
				EndDo;
			Else
				For Each vPSRow In vObj.PaymentSections Do
					vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vObj.Date);
					vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
					vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vObj.Date);
					If vPSRow.ChequeServiceQuantity <> 0 Then
						vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
					EndIf;
				EndDo;
			EndIf;
			vObj.pmCalculateTotalsByPaymentSections();
			FillPrintableChequePositions(vObj);
		EndIf;
	EndIf;
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	Sum = Object.Sum;
EndProcedure // SumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenCashRegistersList() Export
	vNotify = New NotifyDescription("AfterCashRegisterChoice", ThisObject, New Structure("CheckInvoices", True));
	CashRegistersList.ShowChooseItem(vNotify, NStr("en='Select cash register please!';ru='Выберите ККМ!';de='Wählen Sie Registrierkasse!'"));
EndProcedure // OpenCashRegistersList

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenProformaInvoicesList() Export
	OpenForm("Document.ProformaInvoice.Form.tcListForm", New Structure("ChoiceMode, SelHotel, SelGuestGroup", True, Object.Hotel, Object.GuestGroup), ThisObject);
EndProcedure // OpenProformaInvoicesList

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInvoicesList() Export
	OpenForm("Document.Settlement.Form.tcListForm", New Structure("ChoiceMode, SelHotel, SelGuestGroup", True, Object.Hotel, Object.GuestGroup), ThisObject);
EndProcedure // OpenInvoicesList

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCashRegisterChoice(pUserChoiceItem, pExtraParams) Export
	If pUserChoiceItem <> Undefined Then
		Object.CashRegister = pUserChoiceItem.Value;
		CashRegisterOnChangeAtServer();
		If pExtraParams.Property("CheckInvoices") Then
			If pExtraParams.CheckInvoices Then
				If CheckInvoices() Then
					If UnpaidInvoicesWereFound Then
						AttachIdleHandler("OpenInvoicesList", 0.1, True);
					Else
						AttachIdleHandler("OpenProformaInvoicesList", 0.1, True);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	Else
		If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToDoCashAndCreditCardPaymentsWithoutCashRegister") Then
			Object.CashRegister = Undefined;
			SetIsCorrectionAppearance();
			FillCompanyAndCashRegisterCollapsedRepresentation();
		EndIf;
	EndIf;
	SendPayerContactsRefresh(False, False, True, False);
EndProcedure // AfterCashRegisterChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure InvoiceOnChangeAtServer(pInvoice)
	vObj = FormAttributeToValue("Object");
	vObj.Invoice = pInvoice;
	If vObj.Sum = 0 And Not AdvanceSettlementMode And Not AdvanceMode Then
		If ValueIsFilled(vObj.Hotel) And vObj.Hotel.SplitFolioBalanceByPaymentSections Then
			vPSTable = New ValueTable();
			vPSTable.Columns.Add("PaymentSection", cmGetCatalogTypeDescription("PaymentSections"));
			vPSTable.Columns.Add("Sum", cmGetSumTypeDescription());
			vPSTable.Columns.Add("CommissionSum", cmGetSumTypeDescription());
			For Each vInvoiceSrvRow In vObj.Invoice.Services Do
				vPSTableRow = vPSTable.Add();
				If ValueIsFilled(vInvoiceSrvRow.Service) Then
					vPSTableRow.PaymentSection = vInvoiceSrvRow.Service.PaymentSection;
				EndIf;
				vPSTableRow.Sum = vInvoiceSrvRow.Sum;
				vPSTableRow.CommissionSum = vInvoiceSrvRow.CommissionSum;
			EndDo;
			vPSTable.GroupBy("PaymentSection", "Sum, CommissionSum");
			For Each vPSTableRow In vPSTable Do
				vPSRow = vObj.PaymentSections.Add();
				vPSRow.PaymentSection = vPSTableRow.PaymentSection;
				vPSRow.VATRate = ?(vObj.Company.IsUsingSimpleTaxSystem,vObj.Company.VATRate,vPSTableRow.PaymentSection.VATRate);
				If ValueIsFilled(vObj.Invoice.AccountingCustomer) And vObj.Invoice.AccountingCustomer.DoNotPostCommission Then
					vPSRow.Sum = Round(cmConvertCurrencies(vPSTableRow.Sum, vObj.Invoice.AccountingCurrency, , vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
				Else
					vPSRow.Sum = Round(cmConvertCurrencies(vPSTableRow.Sum - vPSTableRow.CommissionSum, vObj.Invoice.AccountingCurrency, , vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
				EndIf;
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vObj.Date);
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vObj.Date);
			EndDo;
			If vObj.PaymentSections.Count() > 1 Then
				v1PSRow = vObj.PaymentSections.Get(0);
				If Not ValueIsFilled(v1PSRow.PaymentSection) And v1PSRow.Sum = 0 Then
					vObj.PaymentSections.Delete(0);
				EndIf;
			EndIf;
			vObj.pmCalculateTotalsByPaymentSections();
			FillPrintableChequePositions(vObj);
		ElsIf ValueIsFilled(vObj.Hotel) And vObj.Hotel.SplitFolioBalanceByPaymentSections Then
			vPSTable = New ValueTable();
			vPSTable.Columns.Add("PaymentSection", cmGetCatalogTypeDescription("PaymentSections"));
			vPSTable.Columns.Add("ChequeService", cmGetCatalogTypeDescription("Services"));
			vPSTable.Columns.Add("ChequeServicePrice", cmGetSumTypeDescription());
			vPSTable.Columns.Add("ChequeServiceQuantity", cmGetQuantityTypeDescription());
			vPSTable.Columns.Add("Sum", cmGetSumTypeDescription());
			vPSTable.Columns.Add("CommissionSum", cmGetSumTypeDescription());
			For Each vInvoiceSrvRow In vObj.Invoice.Services Do
				vPSTableRow = vPSTable.Add();
				vPSTableRow.ChequeService = vInvoiceSrvRow.Service;
				vPSTableRow.ChequeServicePrice = vInvoiceSrvRow.Price;
				vPSTableRow.ChequeServiceQuantity = vInvoiceSrvRow.Quantity;
				If ValueIsFilled(vInvoiceSrvRow.Service) Then
					vPSTableRow.PaymentSection = vInvoiceSrvRow.Service.PaymentSection;
				EndIf;
				vPSTableRow.Sum = vInvoiceSrvRow.Sum;
				vPSTableRow.CommissionSum = vInvoiceSrvRow.CommissionSum;
			EndDo;
			vPSTable.GroupBy("PaymentSection, ChequeService, ChequeServicePrice", "Sum, CommissionSum, ChequeServiceQuantity");
			For Each vPSTableRow In vPSTable Do
				vPSRow = vObj.PaymentSections.Add();
				vPSRow.PaymentSection = vPSTableRow.PaymentSection;
				vPSRow.ChequeService = vPSTableRow.ChequeService;
				vPSRow.ChequeServicePrice = vPSTableRow.ChequeServicePrice;
				vPSRow.ChequeServiceQuantity = vPSTableRow.ChequeServiceQuantity;
				vPSRow.VATRate = ?(vObj.Company.IsUsingSimpleTaxSystem,vObj.Company.VATRate,vPSTableRow.PaymentSection.VATRate);
				If ValueIsFilled(vObj.Invoice.AccountingCustomer) And vObj.Invoice.AccountingCustomer.DoNotPostCommission Then
					vPSRow.Sum = Round(cmConvertCurrencies(vPSTableRow.Sum, vObj.Invoice.AccountingCurrency, , vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
				Else
					vPSRow.Sum = Round(cmConvertCurrencies(vPSTableRow.Sum - vPSTableRow.CommissionSum, vObj.Invoice.AccountingCurrency, , vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
				EndIf;
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vObj.Date);
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vObj.Date);
				If vPSRow.ChequeServiceQuantity <> 0 Then
					vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
				EndIf;
			EndDo;
			If vObj.PaymentSections.Count() > 1 Then
				v1PSRow = vObj.PaymentSections.Get(0);
				If Not ValueIsFilled(v1PSRow.PaymentSection) And v1PSRow.Sum = 0 Then
					vObj.PaymentSections.Delete(0);
				EndIf;
			EndIf;
			vObj.pmCalculateTotalsByPaymentSections();
			FillPrintableChequePositions(vObj);
		ElsIf TypeOf(pInvoice) = Type("DocumentRef.ProformaInvoice") Then
			If ValueIsFilled(vObj.Invoice.AccountingCustomer) And vObj.Invoice.AccountingCustomer.DoNotPostCommission Then
				vObj.Sum = Round(cmConvertCurrencies(vObj.Invoice.Services.Total("Sum"), vObj.Invoice.AccountingCurrency, , vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
			Else
				vObj.Sum = Round(cmConvertCurrencies(vObj.Invoice.Services.Total("Sum") - vObj.Invoice.Services.Total("CommissionSum"), vObj.Invoice.AccountingCurrency, , vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
			EndIf;
			SumOnChangeAtServer(vObj);
		EndIf;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure // InvoiceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckInvoices()
	UnpaidInvoicesWereFound = False;
	If IsNew Then
		// Check if payment folio is based on reservation and there are invoices for this guest group then
		// ask user to choose invoice
		vFolio = Object.Folio;
		If ValueIsFilled(vFolio) And ValueIsFilled(vFolio.GuestGroup) And Not ValueIsFilled(Object.Invoice) Then
			If Not ValueIsFilled(vFolio.ParentDoc) Or ValueIsFilled(vFolio.ParentDoc) And 
				(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) Then
				vGroupObj = vFolio.GuestGroup.GetObject();
				vInvoices = vGroupObj.pmGetInvoices(vFolio.Customer, vFolio.Contract, True);
				For Each vInvRow In vInvoices Do
					If vInvRow.Balance > 0 Then
						If TypeOf(vInvRow.Invoice) = Type("DocumentRef.Settlement") Then
							UnpaidInvoicesWereFound = True;
						EndIf;
						Return True;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	Return False;
EndFunction // CheckInvoices

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDocumentObjectParameters(pCancel = False, pStandardProcessing = True)
	IsNew = False;
	NewObjectRef = Object.Ref;
	// Fill new object ref
	If Not ValueIsFilled(NewObjectRef) Then
		vObj = FormAttributeToValue("Object");
		
		IsNew = True;
		If Not ValueIsFilled(vObj.GetNewObjectRef()) Then
			vObj.SetNewObjectRef(Documents.Payment.GetRef());
		EndIf;
		NewObjectRef = vObj.GetNewObjectRef();
		
		// Additional properties
		If Parameters.Property("AdditionalProperties") And Parameters.Property("Basis") Then
			If Parameters.AdditionalProperties.AdvanceSettlementMode Then
				pStandardProcessing = False;
				vObj.AdditionalProperties.Insert("AdvanceSettlementMode", Parameters.AdditionalProperties.AdvanceSettlementMode);
				vObj.PaymentSections.Clear();
				vObj.Fill(Parameters.Basis);
			EndIf;
		ElsIf Parameters.Property("Basis") And ValueIsFilled(Parameters.Basis) Then
			pStandardProcessing = False;
			vObj.PaymentSections.Clear();
			vObj.Fill(Parameters.Basis);
			If Parameters.Property("Amount") And Parameters.Property("PaymentMethod") Then
				vObj.SumInFolioCurrency = Parameters.Amount;
				vObj.PaymentMethod = Parameters.PaymentMethod;
				vObj.Sum = vObj.SumInFolioCurrency;
				vObj.PaymentCurrency = vObj.FolioCurrency;
				vObj.PaymentCurrencyExchangeRate = vObj.FolioCurrencyExchangeRate;
				vObj.CashRegister = Parameters.CashRegister;
				If vObj.Hotel.SplitFolioBalanceByPaymentSections Then
					vObj.PaymentSections.Clear();
					vPSRow = vObj.PaymentSections.Add();
					vPSRow.PaymentSection = Parameters.Service.PaymentSection;
					vPSRow.Sum = vObj.Sum;
					vPSRow.SumInFolioCurrency = vObj.SumInFolioCurrency;
					vPSRow.VATRate = ?(ValueIsFilled(vPSRow.PaymentSection) And ValueIsFilled(vPSRow.PaymentSection.VATRate), vPSRow.PaymentSection.VATRate, vObj.VATRate);
					vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vObj.Date);
					vPSRow.VATSumInFolioCurrency = vPSRow.VATSum;
				ElsIf vObj.Hotel.SplitFolioBalanceByServicesAndPrices And ValueIsFilled(Parameters.Service) Then
					vObj.PaymentSections.Clear();
					vPSRow = vObj.PaymentSections.Add();
					vPSRow.PaymentSection = Parameters.Service.PaymentSection;
					vPSRow.ChequeService = Parameters.Service;
					vPSRow.ChequeServiceQuantity = ?(Parameters.Quantity <> 0, Parameters.Quantity, 1);
					vPSRow.Sum = vObj.Sum;
					vPSRow.SumInFolioCurrency = vObj.SumInFolioCurrency;
					vPSRow.ChequeServicePrice = ?(Parameters.Quantity <> 0, Round(vPSRow.Sum/Parameters.Quantity, 2), vPSRow.Sum);
					vPSRow.VATRate = ?(ValueIsFilled(vPSRow.PaymentSection) And ValueIsFilled(vPSRow.PaymentSection.VATRate), vPSRow.PaymentSection.VATRate, vObj.VATRate);
					vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vObj.Date);
					vPSRow.VATSumInFolioCurrency = vPSRow.VATSum;
				EndIf;
			EndIf;
		EndIf;
		
		If Parameters.Property("ParentDoc") And ValueIsFilled(Parameters.ParentDoc) Then
			vObj.ParentDoc = Parameters.ParentDoc;
			If TypeOf(Parameters.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(Parameters.ParentDoc) = Type("DocumentRef.Reservation") Then
				vObj.Payer = vObj.ParentDoc.Guest;
				If Not ValueIsFilled(vObj.GuestGroup) Then
					vObj.GuestGroup = vObj.ParentDoc.GuestGroup;
				EndIf;
			ElsIf TypeOf(Parameters.ParentDoc) = Type("DocumentRef.ResourceReservation") Then
				vObj.Payer = vObj.ParentDoc.Client;
				If Not ValueIsFilled(vObj.GuestGroup) Then
					vObj.GuestGroup = vObj.ParentDoc.GuestGroup;
				EndIf;
			EndIf;
			vObj.Remarks = TrimAll(vObj.ParentDoc);
		EndIf;
		
		If Parameters.Property("DiscountCard") And ValueIsFilled(Parameters.DiscountCard) Then
			vObj.DiscountCard = Parameters.DiscountCard;
		EndIf;
		
		If Parameters.Property("OrderNumber") And ValueIsFilled(Parameters.OrderNumber) Then
			vObj.OrderNumber = Parameters.OrderNumber;
		EndIf;
		
		If Parameters.Property("CashRegister") And ValueIsFilled(Parameters.CashRegister) Then
			vObj.CashRegister = Parameters.CashRegister;
		EndIf;
		
		// Fill by list of charges transferred
		If Parameters.Property("SelectedChargesList") And Parameters.SelectedChargesList.Count() > 0 And ValueIsFilled(vObj.Hotel) Then
			vHotel = vObj.Hotel;
			vFolio = vObj.Folio;
			vUseAdvanceMode = False;
			vUsePrepaymentMode = False;
			vAdvancePaymentSection = Undefined;
			vAdvanceSettlementPaymentMethod = Undefined;
			cmFillAdvanceAndAdvanceSettlementParameters(vHotel, vObj.Author, vAdvancePaymentSection, vAdvanceSettlementPaymentMethod);
			If ValueIsFilled(vAdvancePaymentSection) And ValueIsFilled(vFolio) And ValueIsFilled(vFolio.PaymentSection) Then
				vFolioPaymentSection = vFolio.PaymentSection;
				If vFolioPaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment And 
				  (Not ValueIsFilled(vFolioPaymentSection.Hotel) Or vFolioPaymentSection.Hotel = vHotel) Then
					vAdvancePaymentSection = vFolioPaymentSection;
				EndIf;
			EndIf;
			
			vThereAreFutureCharges = False;
			If ValueIsFilled(vAdvancePaymentSection) Then
				vHotelAccountingDate = tcOnServer.GetForecastStartDate(vHotel);
				vMaxChargesDate = '00010101';
				For Each vChargeItem In Parameters.SelectedChargesList Do
					vChargeRef = vChargeItem.Value;
					vServiceDate = vChargeRef.ServiceDate;
					If Not ValueIsFilled(vServiceDate) Then
						vServiceDate = BegOfDay(vChargeRef.Date);
					EndIf;
					If vServiceDate > vHotelAccountingDate Then
						vThereAreFutureCharges = True;
						Break;
					EndIf;
				EndDo;
				If vHotel.AlwaysUseAdvancesIfFolioDescriptionIsEmpty And 
				   ValueIsFilled(vFolio) And IsBlankString(vFolio.Description) Then
					vUseAdvanceMode = True;
				Else
					vAdvancePaymentSectionBalanceIsZero = True;
					vAdvancePaymentSectionBalances = vFolio.GetObject().pmGetPaymentSectionBalances('39991231235959', vHotel, , True);
					If vAdvancePaymentSectionBalances.Count() > 0 Then
						If vAdvancePaymentSectionBalances.Count() = 1 Then
							vPSBalancesRow = vAdvancePaymentSectionBalances.Get(0);
							If vPSBalancesRow.SumBalance <> 0 Then
								vAdvancePaymentSectionBalanceIsZero = False;
							EndIf;
						Else
							vAdvancePaymentSectionBalanceIsZero = False;
						EndIf;
					EndIf;
					If Not vAdvancePaymentSectionBalanceIsZero Then
						vUseAdvanceMode = True;
					Else
						If vThereAreFutureCharges Then
							If vHotel.UsePrepaymentsIfPossible Then
								vUsePrepaymentMode = True;
							Else
								vUseAdvanceMode = True;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If vUseAdvanceMode Then
					vObj.PaymentSection = vAdvancePaymentSection;
				Else
					vObj.PaymentSection = Catalogs.PaymentSections.EmptyRef();
				EndIf;
			EndIf;
			// Change document appearance according to the flags calculated
			SetAppearancePaymentSections(vObj);
			// Fill document
			If Items.PaymentSections.Visible Then
				vPaymentSectionsRow = Undefined;
				vPaymentSections = vObj.PaymentSections.UnloadColumns();
				vPaymentSections.Columns.Add("AccountingDate", cmGetDateTypeDescription());
				vObj.PaymentSections.Clear();
				If vHotel.SplitFolioBalanceByServicesAndPrices Then
					For Each vChargeItem In Parameters.SelectedChargesList Do
						vChargeRef = vChargeItem.Value;
						If vChargeRef.IsMergedToRoomRevenue And ValueIsFilled(vChargeRef.RoomRevenueCharge) And vChargeRef.RoomRevenueCharge <> vChargeRef And vPaymentSectionsRow <> Undefined And vPaymentSectionsRow.ChequeService = vChargeRef.RoomRevenueCharge.Service Then
							vRoomRevenueChargeRef = vChargeRef.RoomRevenueCharge;
							vPaymentSectionsRow.Sum = vPaymentSectionsRow.Sum + Round(cmConvertCurrencies(vChargeRef.Sum - vChargeRef.DiscountSum, vChargeRef.FolioCurrency, , vObj.PaymentCurrency, , vObj.ExchangeRateDate, vHotel), 2);
							vPaymentSectionsRow.ChequeServicePrice = Round(vPaymentSectionsRow.Sum/vPaymentSectionsRow.ChequeServiceQuantity, 2);
							vPaymentSectionsRow.VATSum = cmCalculateVATSum(vPaymentSectionsRow.VATRate, vPaymentSectionsRow.Sum, vObj.Date);
							vPaymentSectionsRow.SumInFolioCurrency = vPaymentSectionsRow.SumInFolioCurrency + vChargeRef.Sum - vChargeRef.DiscountSum;
							vPaymentSectionsRow.VATSumInFolioCurrency = cmCalculateVATSum(vPaymentSectionsRow.VATRate, vPaymentSectionsRow.SumInFolioCurrency, vObj.Date);
							vPaymentSectionsRow.MarkingCode = vRoomRevenueChargeRef.MarkingCode;
						Else
							vPaymentSectionsRow = vPaymentSections.Add();
							If ValueIsFilled(vChargeRef.CorrectedCharge) Then
								vCorrectedCharge = vChargeRef.CorrectedCharge;
								
								vPaymentSectionsRow.AccountingDate = BegOfDay(?(ValueIsFilled(vCorrectedCharge.ServiceDate), vCorrectedCharge.ServiceDate, vCorrectedCharge.Date));
								vPaymentSectionsRow.PaymentSection = ?(ValueIsFilled(vAdvancePaymentSection) And vUsePrepaymentMode, vAdvancePaymentSection, vCorrectedCharge.Service.PaymentSection);
								vPaymentSectionsRow.ChequeService = vCorrectedCharge.Service;
								vPaymentSectionsRow.ChequeServiceQuantity = 0;
								vPaymentSectionsRow.Sum = Round(cmConvertCurrencies(vChargeRef.Sum - vChargeRef.DiscountSum, vChargeRef.FolioCurrency, , vObj.PaymentCurrency, , vObj.ExchangeRateDate, vHotel), 2);
								vPaymentSectionsRow.ChequeServicePrice = Round(Round(cmConvertCurrencies(vCorrectedCharge.Sum - vCorrectedCharge.DiscountSum, vCorrectedCharge.FolioCurrency, , vObj.PaymentCurrency, , vObj.ExchangeRateDate, vHotel), 2)/?(vCorrectedCharge.Quantity = 0, 1, vCorrectedCharge.Quantity), 2);
								vPaymentSectionsRow.VATRate = vCorrectedCharge.VATRate;
								vPaymentSectionsRow.VATSum = 0;
								vPaymentSectionsRow.SumInFolioCurrency = vChargeRef.Sum - vChargeRef.DiscountSum;
								vPaymentSectionsRow.VATSumInFolioCurrency = 0;
								vPaymentSectionsRow.MarkingCode = vCorrectedCharge.MarkingCode;
							Else
								vPaymentSectionsRow.AccountingDate = BegOfDay(?(ValueIsFilled(vChargeRef.ServiceDate), vChargeRef.ServiceDate, vChargeRef.Date));
								vPaymentSectionsRow.PaymentSection = ?(ValueIsFilled(vAdvancePaymentSection) And vUsePrepaymentMode, vAdvancePaymentSection, vChargeRef.Service.PaymentSection);
								vPaymentSectionsRow.ChequeService = vChargeRef.Service;
								vPaymentSectionsRow.ChequeServiceQuantity = ?(vChargeRef.Quantity = 0, 1, vChargeRef.Quantity);
								vPaymentSectionsRow.Sum = Round(cmConvertCurrencies(vChargeRef.Sum - vChargeRef.DiscountSum, vChargeRef.FolioCurrency, , vObj.PaymentCurrency, , vObj.ExchangeRateDate, vHotel), 2);
								vPaymentSectionsRow.ChequeServicePrice = Round(vPaymentSectionsRow.Sum/?(vPaymentSectionsRow.ChequeServiceQuantity = 0, 1, vPaymentSectionsRow.ChequeServiceQuantity), 2);
								vPaymentSectionsRow.VATRate = vChargeRef.VATRate;
								vPaymentSectionsRow.VATSum = 0;
								vPaymentSectionsRow.SumInFolioCurrency = vChargeRef.Sum - vChargeRef.DiscountSum;
								vPaymentSectionsRow.VATSumInFolioCurrency = 0;
								vPaymentSectionsRow.MarkingCode = vChargeRef.MarkingCode;
							EndIf;
						EndIf;
					EndDo;
					vPaymentSections.GroupBy("AccountingDate, PaymentSection, ChequeService, ChequeServicePrice, VATRate, MarkingCode", "ChequeServiceQuantity, Sum, VATSum, SumInFolioCurrency, VATSumInFolioCurrency");
					For Each vPaymentSectionsRow In vPaymentSections Do
						vPaymentSectionsRow.ChequeServicePrice = Round(vPaymentSectionsRow.Sum/?(vPaymentSectionsRow.ChequeServiceQuantity = 0, 1, vPaymentSectionsRow.ChequeServiceQuantity), 2);
						vPaymentSectionsRow.VATSum = cmCalculateVATSum(vPaymentSectionsRow.VATRate, vPaymentSectionsRow.Sum, vObj.Date);
						vPaymentSectionsRow.VATSumInFolioCurrency = cmCalculateVATSum(vPaymentSectionsRow.VATRate, vPaymentSectionsRow.SumInFolioCurrency, vObj.Date);
					EndDo;
					vPaymentSections.GroupBy("PaymentSection, ChequeService, ChequeServicePrice, VATRate, MarkingCode", "ChequeServiceQuantity, Sum, VATSum, SumInFolioCurrency, VATSumInFolioCurrency");
					vObj.PaymentSections.Load(vPaymentSections);
					vObj.Sum = vPaymentSections.Total("Sum");
					vObj.SumInFolioCurrency = vPaymentSections.Total("SumInFolioCurrency");
					vObj.VATSum = vPaymentSections.Total("VATSum");
					vObj.VATSumInFolioCurrency = vPaymentSections.Total("VATSumInFolioCurrency");
				ElsIf vHotel.SplitFolioBalanceByPaymentSections Then
					For Each vChargeItem In Parameters.SelectedChargesList Do
						vChargeRef = vChargeItem.Value;
						If vChargeRef.IsMergedToRoomRevenue And ValueIsFilled(vChargeRef.RoomRevenueCharge) And vChargeRef.RoomRevenueCharge <> vChargeRef And vPaymentSectionsRow <> Undefined And vPaymentSectionsRow.ChequeService = vChargeRef.RoomRevenueCharge.Service Then
							vRoomRevenueChargeRef = vChargeRef.RoomRevenueCharge;
							vPaymentSectionsRow.Sum = vPaymentSectionsRow.Sum + Round(cmConvertCurrencies(vChargeRef.Sum - vChargeRef.DiscountSum, vChargeRef.FolioCurrency, , vObj.PaymentCurrency, , vObj.ExchangeRateDate, vHotel), 2);
							vPaymentSectionsRow.ChequeServicePrice = Round(vPaymentSectionsRow.Sum/vPaymentSectionsRow.ChequeServiceQuantity, 2);
							vPaymentSectionsRow.VATSum = cmCalculateVATSum(vPaymentSectionsRow.VATRate, vPaymentSectionsRow.Sum, vObj.Date);
							vPaymentSectionsRow.SumInFolioCurrency = vPaymentSectionsRow.SumInFolioCurrency + vChargeRef.Sum - vChargeRef.DiscountSum;
							vPaymentSectionsRow.VATSumInFolioCurrency = cmCalculateVATSum(vPaymentSectionsRow.VATRate, vPaymentSectionsRow.SumInFolioCurrency, vObj.Date);
							vPaymentSectionsRow.MarkingCode = vRoomRevenueChargeRef.MarkingCode;
						Else
							vPaymentSectionsRow = vPaymentSections.Add();
							If ValueIsFilled(vChargeRef.CorrectedCharge) Then
								vCorrectedCharge = vChargeRef.CorrectedCharge;
								
								vPaymentSectionsRow.PaymentSection = vCorrectedCharge.Service.PaymentSection;
								vPaymentSectionsRow.ChequeService = Undefined;
								vPaymentSectionsRow.ChequeServiceQuantity = 0;
								vPaymentSectionsRow.Sum = Round(cmConvertCurrencies(vChargeRef.Sum - vChargeRef.DiscountSum, vChargeRef.FolioCurrency, , vObj.PaymentCurrency, , vObj.ExchangeRateDate, vHotel), 2);
								vPaymentSectionsRow.ChequeServicePrice = 0;
								vPaymentSectionsRow.VATRate = vCorrectedCharge.VATRate;
								vPaymentSectionsRow.VATSum = 0;
								vPaymentSectionsRow.SumInFolioCurrency = vChargeRef.Sum - vChargeRef.DiscountSum;
								vPaymentSectionsRow.VATSumInFolioCurrency = 0;
								vPaymentSectionsRow.MarkingCode = "";
							Else
								vPaymentSectionsRow.PaymentSection = vChargeRef.Service.PaymentSection;
								vPaymentSectionsRow.ChequeService = Undefined;
								vPaymentSectionsRow.ChequeServiceQuantity = 0;
								vPaymentSectionsRow.Sum = Round(cmConvertCurrencies(vChargeRef.Sum - vChargeRef.DiscountSum, vChargeRef.FolioCurrency, , vObj.PaymentCurrency, , vObj.ExchangeRateDate, vHotel), 2);
								vPaymentSectionsRow.ChequeServicePrice = 0;
								vPaymentSectionsRow.VATRate = vChargeRef.VATRate;
								vPaymentSectionsRow.VATSum = 0;
								vPaymentSectionsRow.SumInFolioCurrency = vChargeRef.Sum - vChargeRef.DiscountSum;
								vPaymentSectionsRow.VATSumInFolioCurrency = 0;
								vPaymentSectionsRow.MarkingCode = "";
							Endif;
						EndIf;
					EndDo;
					vPaymentSections.GroupBy("PaymentSection, ChequeService, ChequeServicePrice, VATRate, MarkingCode", "ChequeServiceQuantity, Sum, VATSum, SumInFolioCurrency, VATSumInFolioCurrency");
					For Each vPaymentSectionsRow In vPaymentSections Do
						vPaymentSectionsRow.VATSum = cmCalculateVATSum(vPaymentSectionsRow.VATRate, vPaymentSectionsRow.Sum, vObj.Date);
						vPaymentSectionsRow.VATSumInFolioCurrency = cmCalculateVATSum(vPaymentSectionsRow.VATRate, vPaymentSectionsRow.SumInFolioCurrency, vObj.Date);
					EndDo;
					vObj.PaymentSections.Load(vPaymentSections);
					vObj.Sum = vPaymentSections.Total("Sum");
					vObj.SumInFolioCurrency = vPaymentSections.Total("SumInFolioCurrency");
					vObj.VATSum = vPaymentSections.Total("VATSum");
					vObj.VATSumInFolioCurrency = vPaymentSections.Total("VATSumInFolioCurrency");
				Else
					vSum = 0;
					For Each vChargeItem In Parameters.SelectedChargesList Do
						vChargeRef = vChargeItem.Value;
						vSum = vSum + Round(cmConvertCurrencies(vChargeRef.Sum - vChargeRef.DiscountSum, vChargeRef.FolioCurrency, , vObj.PaymentCurrency, , vObj.ExchangeRateDate, vHotel), 2);
					EndDo;
					vObj.Sum = vSum;
					SumOnChangeAtServer(vObj);
				EndIf;
			Else
				vSum = 0;
				For Each vChargeItem In Parameters.SelectedChargesList Do
					vChargeRef = vChargeItem.Value;
					vSum = vSum + Round(cmConvertCurrencies(vChargeRef.Sum - vChargeRef.DiscountSum, vChargeRef.FolioCurrency, , vObj.PaymentCurrency, , vObj.ExchangeRateDate, vHotel), 2);
				EndDo;
				vObj.Sum = vSum;
				SumOnChangeAtServer(vObj);
			EndIf;
		EndIf;
		
		// Put object back to the form attribute
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // FillDocumentObjectParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenForm()
	If Not Object.Posted Then
		// Check if payment is based on preauthorisation and current date is less then expected check-out date then give message
		If ValueIsFilled(Object.Preauthorisation) Then
			Items.GroupPreauthorisationCalculation.Visible = True;
			If IsNew Then
				If ValueIsFilled(Object.ParentDoc) And TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Then
					If BegOfDay(CurrentSessionDate()) < BegOfDay(Object.ParentDoc.CheckOutDate) Then
						vNumDays = Round((BegOfDay(Object.ParentDoc.CheckOutDate) - BegOfDay(CurrentSessionDate()))/(24*3600), 0);
						vMessage = NStr("en='Computation is earlier then expected! ';ru='Расчет выполняется раньше даты планируемого выезда! ';de='Errechnung erfolgt vor dem Datum der geplanten Abreise! '") + 
						NStr("en='(';de='(';ru='(на '") + Format(vNumDays, "ND=6; NFD=0; NZ=; NG=") + NStr("en=' days earlier then ';ru=' дня раньше чем ';de=' Tage vor dem '") + Format(Object.ParentDoc.CheckOutDate, "DF=dd.MM.yyyy") + ")";
						tcCommonFunctionOnClientServer.TextMessage(vMessage)
					EndIf;
				EndIf;
			EndIf;
		Else
			Items.GroupPreauthorisationCalculation.Visible = False;
		EndIf;
	EndIf;
	
	// Check permissions
	If Not IsNew Then
		If Object.Posted Then
			If ValueIsFilled(Object.PaymentMethod) And ValueIsFilled(Object.PaymentMethod.ExternalSystem) And Object.PaymentMethod.ExternalSystem.OnlyOnePayment Then
				If Not Object.Folio.IsClosed And CheckReturnExist() Then
					Items.PaymentCardDataGroup.ReadOnly = True;
					Items.CompanyAndCashRegister.ReadOnly = True;
					Items.GroupCertificate.ReadOnly = True;
					Items.GroupParentDocs.ReadOnly = True;
					Items.GroupPayer.ReadOnly = True;
					Items.SendPayerContacts.ReadOnly = True;
					Items.DiscountCard.ReadOnly = True;
					Items.PaymentMethod.ReadOnly = True;
					Items.FormSetDeletionMarkAction.Visible = False;
				Else
					ReadOnly = True;	
				EndIf; 
			Else
				vHotel = Object.Hotel;
				vCompany = Object.Company;
				// Check rights to edit posted document
				If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
					ReadOnly = True;
					Items.FormSetDeletionMarkAction.Visible = False;
				EndIf;
				// Check edit prohibited dates
				If Not ReadOnly Then
					If ValueIsFilled(vHotel) Then
						If ValueIsFilled(vHotel.EditProhibitedDate) And BegOfDay(vHotel.EditProhibitedDate) >= BegOfDay(Object.Date) Then
							ReadOnly = True;
							Items.FormSetDeletionMarkAction.Visible = False;
						EndIf;
					EndIf;
				EndIf;
				If Not ReadOnly Then
					If ValueIsFilled(vCompany) Then
						If ValueIsFilled(vCompany.EditProhibitedDate) And BegOfDay(vCompany.EditProhibitedDate) >= BegOfDay(Object.Date) Then
							ReadOnly = True;
							Items.FormSetDeletionMarkAction.Visible = False;
						EndIf;
					EndIf;
				EndIf;
				// Check hotel accounting date
				If Not ReadOnly Then
					If ValueIsFilled(vHotel) Then
						If vHotel.DoNotEditClosedDateDocs And ValueIsFilled(vHotel.AccountingDate) And Object.Date < BegOfDay(vHotel.AccountingDate) Then
							ReadOnly = True;
							Items.FormSetDeletionMarkAction.Visible = False;
						Endif;
					EndIf;
				EndIf;
			EndIf;
			// Links appearance
			Items.GroupPreauthorisationCalculation.ShowTitle = False;
			Items.ClearLinkToPreauthorisation.Visible = False;
			Items.ClearLinkToPreauthorisation.Enabled = False;
			Items.GroupLinkToInvoice.ShowTitle = False;
			Items.ClearLinkToInvoice.Visible = False;
			Items.ClearLinkToInvoice.Enabled = False;
			Items.GroupRow2.Group = ChildFormItemsGroup.AlwaysHorizontal;
		Else
			Items.FormSetDeletionMarkAction.Visible = False; 
			If ValueIsFilled(Object.PaymentMethod) And ValueIsFilled(Object.PaymentMethod.ExternalSystem) And Object.PaymentMethod.IsByCreditCard Then
				If ValueIsFilled(Object.OrderID) And ValueIsFilled(Object.OrderURL) Then
					SetReadOnlyByQrExternalPayment();		
				EndIf;
			EndIf;
		EndIf;
	Else
		Items.FormSetDeletionMarkAction.Visible = False;
	EndIf;
	
	// Fill list of payment methods allowed for the current user
	FillListOfPaymentMethods();
	// Set default payment method
	If IsNew Then
		SetDefaultPaymentMethod();
	EndIf;
	
	// Fill list of cash registers allowed for the current user
	FillListOfCashRegisters();
	
	// Fill list of possible document payers
	FillListOfPayers();
	
	// Fill list of payers credit cards
	FillListOfPayersCreditCards();
	
	// Fill customer, contract and guest group
	If IsNew Then
		FillCustomerContractAndGuestGroup();
	EndIf;
	
	If Object.CorrectionOfIncorrectCheque Then
		Items.Payment.Visible = True;
	Else
		Items.Payment.Visible = False;
	EndIf;
	
	// Fill default payment amounts list
	If IsNew And ValueIsFilled(Object.Folio) And Not ValueIsFilled(Object.Preauthorisation) And 
	   Not Object.CorrectionOfIncorrectCheque And 
	   Object.PaymentMethod <> Catalogs.PaymentMethods.AdvanceSettlement And 
	  (Not Items.Sum.ReadOnly Or MultipleAdvancePaymentSectionsMode()) Then
		vAmountsList = FillListOfDefaultPaymentAmounts();
		If vAmountsList.Count() > 0 Then
			Items.Sum.DropListButton = True;
			Items.Sum.ChoiceList.Clear();
			For Each vAmountsListItem In vAmountsList Do
				Items.Sum.ChoiceList.Add(vAmountsListItem.Value, vAmountsListItem.Presentation);
			EndDo;
		EndIf;
	EndIf;
	
	// Save current payment amount
	Sum = Object.Sum;
EndProcedure // OnOpenForm

// -----------------------------------------------------------------------------
&AtServer
Function MultipleAdvancePaymentSectionsMode()
	vMultipleAdvancePaymentSectionsMode = False;
	If Not ValueIsFilled(Object.PaymentSection) Then
		vAdvancePaymentSections = cmGetAdvancePaymentSections(Object.Hotel);
		If vAdvancePaymentSections.Count() > 1 Then
			vMultipleAdvancePaymentSectionsMode = True;
		EndIf;
	EndIf;
	If vMultipleAdvancePaymentSectionsMode Then
		If AdvanceMode And Object.PaymentSections.Count() = 0 Then
			vMultipleAdvancePaymentSectionsMode = False;
		Else
			For Each vPSRow In Object.PaymentSections Do
				If ValueIsFilled(vPSRow.ChequeService) Then
					vMultipleAdvancePaymentSectionsMode = False;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vMultipleAdvancePaymentSectionsMode;
EndFunction // MultipleAdvancePaymentSectionsMode

// -----------------------------------------------------------------------------
&AtServer
Procedure SetReadOnlyByQrExternalPayment()
	Items.HeaderGroup.ReadOnly = True;
	Items.GroupPayer.ReadOnly = True;
	Items.SendPayerContacts.ReadOnly = True;
	Items.MainGroup.ReadOnly = True;
	Items.PaymentSectionsGroup.ReadOnly = True;
	Items.PaymentSection.ReadOnly = True;
	Items.PaymentSection.ClearButton = False;
	Items.GroupParentDocs.ReadOnly = True;
	Items.Remarks.ReadOnly = True;
	Items.CorrectionOfIncorrectCheque.ReadOnly = True;
	Items.Payment.ReadOnly = True;
EndProcedure // SetReadOnlyByQrExternalPayment

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCustomerContractAndGuestGroup()
	vHotel = Object.Hotel;
	vFolio = Object.Folio;
	vPayer = Object.Payer;
	vParentDoc = Object.ParentDoc;
	If ValueIsFilled(vPayer) Then
		If TypeOf(vPayer) = Type("CatalogRef.Customers") Then
			If Object.AccountingCustomer <> vPayer Then
				Object.AccountingCustomer = vPayer;
				If Object.AccountingCustomer = vFolio.Customer Then
					Object.AccountingContract = vFolio.Contract;
				Else
					Object.AccountingContract = vPayer.Contract;
				EndIf;
			EndIf;
		Else
			If ValueIsFilled(vFolio.Customer) Then
				If Object.AccountingCustomer <> vFolio.Customer Then
					Object.AccountingCustomer = vFolio.Customer;
					Object.AccountingContract = vFolio.Contract;
				EndIf;
			Else
				If ValueIsFilled(vHotel) Then
					If Object.AccountingCustomer <> vHotel.IndividualsCustomer Then
						Object.AccountingCustomer = vHotel.IndividualsCustomer;
						Object.AccountingContract = vHotel.IndividualsContract;
					EndIf;
				Else
					Object.AccountingCustomer = Catalogs.Customers.EmptyRef();
					Object.AccountingContract = Catalogs.Contracts.EmptyRef();
				EndIf;
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(vFolio.Customer) Then
			If Object.AccountingCustomer <> vFolio.Customer Then
				Object.AccountingCustomer = vFolio.Customer;
				Object.AccountingContract = vFolio.Contract;
			EndIf;
		Else
			If ValueIsFilled(vHotel) Then
				If Object.AccountingCustomer <> vHotel.IndividualsCustomer Then
					Object.AccountingCustomer = vHotel.IndividualsCustomer;
					Object.AccountingContract = vHotel.IndividualsContract;
				EndIf;
			Else
				Object.AccountingCustomer = Catalogs.Customers.EmptyRef();
				Object.AccountingContract = Catalogs.Contracts.EmptyRef();
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(vFolio) And ValueIsFilled(vFolio.GuestGroup) Then
		If vFolio.GuestGroup <> Object.GuestGroup Then
			Object.GuestGroup = vFolio.GuestGroup;
		EndIf;
	Else
		If ValueIsFilled(vParentDoc) And ValueIsFilled(vParentDoc.GuestGroup) Then
			If vParentDoc.GuestGroup <> Object.GuestGroup Then
				Object.GuestGroup = vParentDoc.GuestGroup;
			EndIf;
		Else
			If ValueIsFilled(Object.GuestGroup) Then
				Object.GuestGroup = Undefined;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillCustomerContractAndGuestGroup

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPayers()
	If ReadOnly Then
		Return;
	EndIf;
	If ValueIsFilled(Object.Folio) Then
		If ValueIsFilled(Object.Folio.Client) Then
			PayerList.Add(Object.Folio.Client, Object.Folio.Client.FullName, , PictureLib.Individual);
		EndIf;
		If ValueIsFilled(Object.Folio.Customer) Then
			PayerList.Add(Object.Folio.Customer, Object.Folio.Customer.Description, , PictureLib.Customer);
		EndIf;
	EndIf;
EndProcedure // FillListOfPayers

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPayersCreditCards()
	Items.CreditCard.ChoiceList.Clear();
	// Add payer cards
	vPayerCards = cmGetListOfPayersCreditCards(Object.Payer);
	For Each vPayerCardsItem In vPayerCards Do
		If Items.CreditCard.ChoiceList.FindByValue(vPayerCardsItem.Value) = Undefined Then
			Items.CreditCard.ChoiceList.Add(vPayerCardsItem.Value);
		EndIf;
	EndDo;
	// Add parent document credit card
	If ValueIsFilled(Object.ParentDoc) Then
		If TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Or
		   TypeOf(Object.ParentDoc) = Type("DocumentRef.Reservation") Or
		   TypeOf(Object.ParentDoc) = Type("DocumentRef.ResourceReservation") Then
			If ValueIsFilled(Object.ParentDoc.CreditCard) Then
				If Items.CreditCard.ChoiceList.FindByValue(Object.ParentDoc.CreditCard) = Undefined Then
					Items.CreditCard.ChoiceList.Add(Object.ParentDoc.CreditCard);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Check that current credit card is in the list
	If ValueIsFilled(Object.CreditCard) Then
		If Items.CreditCard.ChoiceList.FindByValue(Object.CreditCard) = Undefined Then
			Items.CreditCard.ChoiceList.Add(Object.CreditCard);
		EndIf;
	EndIf;
EndProcedure // FillListOfPayersCreditCards

// -----------------------------------------------------------------------------
&AtServer
Procedure CashRegisterOnChangeAtServer()
	// Correction appearance
	SetIsCorrectionAppearance();
	// Fill list of payment methods allowed for the current user
	FillListOfPaymentMethods();
	// Set default payment method
	If IsNew Then
		SetDefaultPaymentMethod();
	EndIf;
	FillCompanyAndCashRegisterCollapsedRepresentation();
EndProcedure // CashRegisterOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfCashRegisters()
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		CashRegistersList = cmGetListOfAllCashRegisters(Object.Company);
	Else
		CashRegistersList = cmGetListOfCashRegistersAllowed(Object.Company, SessionParameters.CurrentWorkstation, Object.PaymentMethod);
	EndIf;
	// Filter cash registers list by hotel
	i = 0;
	While i < CashRegistersList.Count() Do
		vCashRegister = CashRegistersList.Get(i).Value;
		If ValueIsFilled(vCashRegister) Then
			If ValueIsFilled(vCashRegister.Hotel) And vCashRegister.Hotel = Object.Hotel Or 
			   Not ValueIsFilled(vCashRegister.Hotel) Then
				i = i + 1;
			Else
				CashRegistersList.Delete(i);
			EndIf;
		Else
			CashRegistersList.Delete(i);
		EndIf;
	EndDo;
	// Check that current cash register is in the list
	If ValueIsFilled(Object.CashRegister) Then
		If CashRegistersList.FindByValue(Object.CashRegister) = Undefined Then
			If Object.Posted Then
				CashRegistersList.Add(Object.CashRegister);
			EndIf;
		EndIf;
	EndIf;
	// Attach list of cash registers to the form item
	Items.CashRegister.ChoiceList.LoadValues(CashRegistersList.UnloadValues());
EndProcedure // FillListOfCashRegisters

// -----------------------------------------------------------------------------
&AtServer
Function SetDefaultCashRegister(pOnOpenMode = False)
	If ValueIsFilled(Object.CashRegister) Then
		If CashRegistersList.FindByValue(Object.CashRegister) = Undefined Then
			Object.CashRegister = Catalogs.CashRegisters.EmptyRef();
			SetIsCorrectionAppearance();
			If ValueIsFilled(Object.PaymentMethod) Then
				If Object.PaymentMethod.BookByCashRegister Then
					If CashRegistersList.Count() = 1 Then
						Object.CashRegister = CashRegistersList.Get(0).Value;
						SetIsCorrectionAppearance();
					ElsIf CashRegistersList.Count() > 1 Then
						FillCompanyAndCashRegisterCollapsedRepresentation();
						Return True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	ElsIf Not ValueIsFilled(Object.Ref) And CashRegistersList.Count() > 0 Then
		If ValueIsFilled(Object.PaymentMethod) Then
			If Object.PaymentMethod.BookByCashRegister Then
				vFOCashRegister = Undefined;
				For Each vCRItem In CashRegistersList Do
					If vCRItem.Value.UseForFrontOffice Then
						vFOCashRegister = vCRItem.Value;
						Break;
					EndIf;
				EndDo;
				Object.CashRegister = ?(ValueIsFilled(vFOCashRegister), vFOCashRegister, CashRegistersList.Get(0).Value);
				SetIsCorrectionAppearance();
				// Cash register group representation
				If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") And Not ValueIsFilled(vFOCashRegister) Then
					If CashRegistersList.Count() > 1 Then
						FillCompanyAndCashRegisterCollapsedRepresentation();
						Return True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	FillCompanyAndCashRegisterCollapsedRepresentation();
	// Show payer phone and e-mail if necessary
	SendPayerContactsRefresh(pOnOpenMode, False, False, False);
	Return False;
EndFunction // SetDefaultCashRegister

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDefaultPaymentMethod()
	vHotel = Object.Hotel;
	If Not ValueIsFilled(Object.PaymentMethod) Then
		If ValueIsFilled(vHotel) Then
			If ValueIsFilled(vHotel.PlannedPaymentMethod) Then
				Object.PaymentMethod = vHotel.PlannedPaymentMethod;
			EndIf;
		EndIf;
		If ValueIsFilled(Object.ParentDoc) Then
			If ValueIsFilled(Object.ParentDoc.PlannedPaymentMethod) Then
				Object.PaymentMethod = Object.ParentDoc.PlannedPaymentMethod;
			EndIf;
		EndIf;
		If ValueIsFilled(Object.Folio) Then
			If ValueIsFilled(Object.Folio.PaymentMethod) Then
				Object.PaymentMethod = Object.Folio.PaymentMethod;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.PaymentMethod) Then
		If Items.PaymentMethod.ChoiceList.FindByValue(Object.PaymentMethod) = Undefined Then
			Object.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
		EndIf;
	EndIf;
EndProcedure // SetDefaultPaymentMethod

// -----------------------------------------------------------------------------
&AtServer
Function GetNextGiftCertificateAtServer()
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Payments.GiftCertificate AS GiftCertificate
	|FROM
	|	Document.Payment AS Payments
	|WHERE
	|	Payments.Posted
	|	AND Payments.Hotel = &qHotel
	|	AND Payments.GiftCertificate <> &qBlankString
	|
	|ORDER BY
	|	Payments.GiftCertificate DESC";
	vQry.SetParameter("qHotel", Object.Hotel);
	vQry.SetParameter("qBlankString", "");
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vLastNumber = TrimAll(vDocs.Get(0).GiftCertificate);
	Else
		vLastNumber="";
	EndIf;
	Return vLastNumber;
EndFunction // GetNextGiftCertificateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionsChequeServicePriceOnChangeAtServer()
	vCurRow = Items.PaymentSections.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.PaymentSections.FindByID(vCurRow);
		If vCurData <> Undefined Then
			If vCurData.ChequeServiceQuantity = 0 Then
				vCurData.ChequeServiceQuantity = 1;
			EndIf;
			vCurData.Sum = Round(vCurData.ChequeServicePrice * vCurData.ChequeServiceQuantity, 2);
			vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, Object.Date);
			vCurData.SumInFolioCurrency = Round(cmConvertCurrencies(vCurData.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.FolioCurrency, Object.FolioCurrencyExchangeRate,	Object.ExchangeRateDate, Object.Hotel), 2);
			vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, Object.Date);
			// Recalculate payment totals
			Object.SumInFolioCurrency = Object.PaymentSections.Total("SumInFolioCurrency");
			Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
			Object.Sum = Object.PaymentSections.Total("Sum");
			Object.VATSum = Object.PaymentSections.Total("VATSum");
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsChequeServicePriceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionsChequeServiceQuantityOnChangeAtServer()
	vCurRow = Items.PaymentSections.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.PaymentSections.FindByID(vCurRow);
		If vCurData <> Undefined Then
			vCurData.Sum = Round(vCurData.ChequeServicePrice * vCurData.ChequeServiceQuantity, 2);
			vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, Object.Date);
			vCurData.SumInFolioCurrency = Round(cmConvertCurrencies(vCurData.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.FolioCurrency, Object.FolioCurrencyExchangeRate,	Object.ExchangeRateDate, Object.Hotel), 2);
			vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, Object.Date);
			// Recalculate payment totals
			Object.SumInFolioCurrency = Object.PaymentSections.Total("SumInFolioCurrency");
			Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
			Object.Sum = Object.PaymentSections.Total("Sum");
			Object.VATSum = Object.PaymentSections.Total("VATSum");
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsChequeServiceQuantityOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Function IsReadyToPrintCheque(rMessage, pCashRegister)
	rMessage = "";
	If Not ValueIsFilled(pCashRegister) Then
		Return False;
	EndIf;
	vDriver = tcOnClient.cmGetModulTO(pCashRegister);
	If Not vDriver = Undefined Then
		Return vDriver.pmIsReadyToPrint(rMessage, , pCashRegister);
	Else
		ShowMessageBox(, Nstr("en = 'Work with this device driver is not supported!'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;
	Return  False;
EndFunction // IsReadyToPrintCheque

// -----------------------------------------------------------------------------
&AtClient
Procedure StartPrintCheque(rMessage, pCancel)
	vDriver = tcOnClient.cmGetModulTO(Object.CashRegister);
	If Not vDriver = Undefined Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, Object.CashRegister);
		vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
		                  |de='Input cash register password please...';
		                  |en='Eingabe des Kassenpasswortes bitte...'");
		If IsBlankString(vPasswordKKM) Then
			// Break before write event and ask user to input cash register password
			pCancel = True;
			vNotify = New NotifyDescription("AfterInputCashRegisterPassword", ThisObject, New Structure("Driver, rMessage", vDriver, rMessage));
			OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion), ThisObject, , , , vNotify);
			// Attach idle handler to close form when cheque will be printed
			AttachIdleHandler("WriteAndCloseFormAfterChequeBeingPrinted", 1, False);
		Else
			vObject = Object;
			If tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "PrintNonFiscalCheque") Then
				vChequeTemplate = TrimAll(tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "NonFiscalChequeTemplate"));
				If Not IsBlankString(vChequeTemplate) Then
					ChequeIsPrinted = vDriver.pmPrintNonFiscalCheque(Object.Sum, Object.VATSum, vObject, vChequeTemplate, rMessage, vPasswordKKM);
				Else
					rMessage = NStr("en='Non-fiscal cheque template is not filled for payment method!'; ru='У способа оплаты не заполнен шаблон нефискального чека!'; de='Zahlungsmethode hat eine leer Vorlage für die nonfiscal Kassenbon!'");
					ChequeIsPrinted = False;
				EndIf;
			Else
				ChequeIsPrinted = vDriver.pmPrintCheque(Object.Sum, Object.VATSum, vObject, ?(ValueIsFilled(vObject.Ref), vObject.Ref, NewObjectRef), rMessage, vPasswordKKM, , IsCorrectionCheque, CorrectionType, CorrectionDescription, CorrectionDocumentNumber, CorrectionDocumentDate, Object.SendPayerContactsToOFD, Object.EmailToSendToOFD, Object.PhoneToSendToOFD);
			EndIf;
			If Not ChequeIsPrinted Then
				If Not IsBlankString(rMessage) Then
					tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				EndIf;
				// Error printing cheque, so break before write event
				pCancel = True;
			EndIf;
		EndIf;
	Else
		// Device driver was not found
		pCancel = True;
		rMessage = Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'");
	EndIf;	
EndProcedure // StartPrintCheque

// -----------------------------------------------------------------------------
&AtClient
Procedure WriteAndCloseFormAfterChequeBeingPrinted() Export
	If ChequeIsPrinted Then
		DetachIdleHandler("WriteAndCloseFormAfterChequeBeingPrinted");
		WriteAndCloseForm();
	EndIf;
EndProcedure // WriteAndCloseFormAfterChequeBeingPrinted

// -----------------------------------------------------------------------------
&AtClient
Procedure WriteAndCloseForm() Export
	If Write(New Structure("WriteMode, PostingMode", PredefinedValue("DocumentWriteMode.Posting"), PredefinedValue("DocumentPostingMode.Regular"))) Then
		Close();
	EndIf;
EndProcedure // WriteAndCloseForm

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputCashRegisterPassword(pValue, pAdditionalParameters) Export
	vDriver = pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.rMessage;
	If Not pValue = Undefined Then
		vObject = Object;
		If tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "PrintNonFiscalCheque") Then
			vChequeTemplate = TrimAll(tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "NonFiscalChequeTemplate"));
			If Not IsBlankString(vChequeTemplate) Then
				ChequeIsPrinted = vDriver.pmPrintNonFiscalCheque(Object.Sum, Object.VATSum, vObject, vChequeTemplate, vMessage, pValue.Password);
			Else
				vMessage = NStr("en='Non-fiscal cheque template is not filled for payment method!'; ru='У способа оплаты не заполнен шаблон нефискального чека!'; de='Zahlungsmethode hat eine leer Vorlage für die nonfiscal Kassenbon!'");
				ChequeIsPrinted = False;
			EndIf;
		Else
			ChequeIsPrinted = vDriver.pmPrintCheque(Object.Sum, Object.VATSum, vObject, NewObjectRef, vMessage, pValue.Password, , IsCorrectionCheque, CorrectionType, CorrectionDescription, CorrectionDocumentNumber, CorrectionDocumentDate, Object.SendPayerContactsToOFD, Object.EmailToSendToOFD, Object.PhoneToSendToOFD);
		EndIf;
		If Not ChequeIsPrinted Then
			If Not IsBlankString(vMessage) Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
			DetachIdleHandler("WriteAndCloseFormAfterChequeBeingPrinted");
		EndIf;
	Else
		DetachIdleHandler("WriteAndCloseFormAfterChequeBeingPrinted");
	EndIf;
EndProcedure // AfterInputCashRegisterPassword

// -----------------------------------------------------------------------------
&AtClient
Function AuthorizePayment(rMessage)
	rMessage = "";
	If Not ValueIsFilled(Object.AuthorizationCode) Then
		vDriver = tcOnClient.cmGetModulTO(ArrPaymentTerminal);
		If Not vDriver = Undefined Then
			Return vDriver.pmAuthorizePayment(Object.Sum, Object.VATSum, Object, rMessage, ArrPaymentTerminal);
		Else
			ShowMessageBox(, Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		EndIf;	
	EndIf;
	Return True;
EndFunction // AuthorizePayment

// -----------------------------------------------------------------------------
&AtServer
Procedure SetNewObjectRefAtServer()
	If Not IsBlankString(Object.Number) Then
		Return;
	EndIf;
	
	vObj = FormAttributeToValue("Object");
	vObj.SetNewNumber();
	ValueToFormAttribute(vObj, "Object");
EndProcedure //  SetNewObjectRefAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentCurrencyOnChangeAtServer()
	Object.PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.PaymentCurrency, Object.ExchangeRateDate);
	Object.Sum = Round(cmConvertCurrencies(Object.Sum,  OldPaymentCurrency, OldPaymentCurrencyExchangeRate, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
	
	For Each vPSRow In Object.PaymentSections Do
		vPSRow.Sum = Round(cmConvertCurrencies(vPSRow.Sum, OldPaymentCurrency, OldPaymentCurrencyExchangeRate, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
	EndDo;
	
	SavePaymentCurrencyAttributes();
	SumOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SavePaymentCurrencyAttributes()
	OldPaymentCurrency = Object.PaymentCurrency;
	OldPaymentCurrencyExchangeRate = Object.PaymentCurrencyExchangeRate;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetAskForPaymentMethodConfirmation()
	vAskForPaymentMethodConfirmation = False;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
			vAskForPaymentMethodConfirmation = SessionParameters.CurrentUser.EmployeePreferences.AskForPaymentMethodConfirmation;
		EndIf;
	EndIf;
	Return vAskForPaymentMethodConfirmation; 
EndFunction // GetAskForPaymentMethodConfirmation

// -----------------------------------------------------------------------------
&AtClient
Function ConfirmPaymentMethodChoice()
	If Not PostAndCloseConfirmed And GetAskForPaymentMethodConfirmation() Then
		vQuery = NStr("ru = 'В платеже выбран способ оплаты
		              |
		              |" + Upper(TrimAll(Object.PaymentMethod)) + ".
		              |
		              |Подтверждаете выбор этого способа оплаты?
		              |
		              |Ответ ""Да"" - провести документ" + ?(ValueIsFilled(Object.CashRegister), " по ККМ " + Upper(TrimAll(Object.CashRegister)) + ".", ".") + "
		              |Ответ ""Нет"" - вернуться в режим редактирования документа.'; 
					  |en = 'You have choosen 
		              |
		              |" + Upper(TrimAll(Object.PaymentMethod)) + " payment method.
		              |
		              |Would you like to confirm your choice?
		              |
		              |Answer ""Yes"" to post document" + ?(ValueIsFilled(Object.CashRegister), " by " + Upper(TrimAll(Object.CashRegister)) + " cash register.", ".") + "
		              |Answer ""No"" to return to the document form.';
					  |de = 'Sie haben 
		              |
		              |" + Upper(TrimAll(Object.PaymentMethod)) + " Zahlungstyp gewählt.
		              |
		              |Möchten Sie Ihre Wahl bestätigen?
		              |
		              |Beantworten Sie ""Ja"", um das Dokument " + ?(ValueIsFilled(Object.CashRegister), "mit " + Upper(TrimAll(Object.CashRegister)) + " POS zu buchen.", "zu buchen.") + "
		              |Antworten Sie mit ""Nein"", um zum Dokumentformular zurückzukehren.'");
		ShowQueryBox(New NotifyDescription("ConfirmPaymentMethodChoiceAfterUserAnswer", ThisObject), vQuery, QuestionDialogMode.YesNo, , DialogReturnCode.No);
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // ConfirmPaymentMethodChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ConfirmPaymentMethodChoiceAfterUserAnswer(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		PostAndCloseConfirmed = True;
		If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Close();
		Else
			Modified = True;
		EndIf;
	EndIf;
EndProcedure // ConfirmPaymentMethodChoiceAfterUserAnswer

// -----------------------------------------------------------------------------
&AtServer
Function CheckCreditCardsProcessingSystem()
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And Not CreditCardProcessingSystem.IsEmpty() Then
		ArrPaymentTerminal = tcOnServer.cmGetAtributeAsArray(CreditCardProcessingSystem);
		ArrPaymentTerminal.ConnectionParameters = ArrPaymentTerminal.ConnectionParameters.Get();
		Return True
	Else
		Return False;
	EndIf;
EndFunction	//CheckCreditCardsProcessingSystem

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(rMessage)
	vObj = FormAttributeToValue("Object");	
	SetObjectAndFormAttributeConformity(vObj, "Object");
	// Basic checks
	vAttributeInErr = "";
	If vObj.pmCheckDocumentAttributes(rMessage, vAttributeInErr) Then
		vUM = New UserMessage();
		vUM.SetData(vObj);
		vUM.Field = vAttributeInErr;
		vUM.Text = NStr(rMessage);
		vUM.Message();
		Return False;
	ElsIf Not tcCommonFunctionOnClientServer.CheckEmail(vObj.EmailToSendToOFD) Then
		Return False;
	EndIf;
	If ValueIsFilled(vObj.PaymentMethod) And ValueIsFilled(vObj.Hotel) And ValueIsFilled(vObj.Folio) Then
		// Check that payment methos allowed for the current folio
		If vObj.PaymentMethod.IsForExtraServiceFolioOnly And Not IsBlankString(vObj.Hotel.AdditionalServicesFolioCondition) And 
		   StrFind(Upper(TrimAll(vObj.Folio.Description)), Upper(TrimAll(vObj.Hotel.AdditionalServicesFolioCondition))) = 0 Then
			rMessage = "en='Payment is allowed for extra services folio only!';
			           |ru='Оплата выбранным способом оплаты возможна только по лицевому счету доп. услуг!';
			           |de='Die Bezahlung mit gewählter Zahlungsmethode ist nur nach dem Personenkonto zusätzlicher Dienstleistungen möglich!'";
			vUM = New UserMessage();
			vUM.SetData(vObj);
			vUM.Field = "PaymentMethod";
			vUM.Text = NStr(rMessage);
			vUM.Message();
			Return False;
		EndIf;
	EndIf;
	// Check and update payment company
	If ValueIsFilled(vObj.Company) And ValueIsFilled(vObj.Folio) And vObj.Folio.Company <> vObj.Company Then
		Try
			vFolioObj = Object.Folio.GetObject();
			vFolioObj.Company = Object.Company;
			vFolioObj.DoNotUpdateCompany = True;
			vFolioObj.Write(DocumentWriteMode.Write);
		Except
			rMessage = "en='Failed to change folio company!" + Chars.LF + cmGetRootErrorDescription(ErrorInfo()) + "';
			           |ru='Не удалось изменить фирму у лицевого счета!" + Chars.LF + cmGetRootErrorDescription(ErrorInfo()) + "';
					   |de='Die Firma beim Personenkonto konnte nicht geändert werden!" + Chars.LF + cmGetRootErrorDescription(ErrorInfo()) + "'";
			vUM = New UserMessage();
			vUM.SetData(vObj);
			vUM.Field = "Company";
			vUM.Text = NStr(rMessage);
			vUM.Message();
			Return False;
		EndTry;
	EndIf;
	// Check correction
	If IsCorrectionCheque Then
		If Not ValueIsFilled(CorrectionType) Then
			rMessage = "en='Correction type should be filled!';
			           |ru='Тип коррекции должен быть заполнен!';
					   |de='Korrekturentyp müssen ausgefüllt werden!'";
			vUM = New UserMessage();
			vUM.SetData(vObj);
			vUM.Field = "CorrectionType";
			vUM.Text = NStr(rMessage);
			vUM.Message();
			Return False;
		EndIf;
		If CorrectionType = Enums.CorrectionChequeTypes.ByOrder Or 
		   ValueIsFilled(Object.CashRegister) And Object.CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_0_5 Then
			If IsBlankString(CorrectionDescription) Or IsBlankString(CorrectionDocumentNumber) Or Not ValueIsFilled(CorrectionDocumentDate) Then
				rMessage = "en='All attributes must be filled in the correction cheques: the name, date and number of the base document!';
				           |ru='У чеков коррекции должны быть заполнены все реквизиты: наименование, дата и номер документа основания!';
						   |de='Im Falle von Korrekturen müssen alle Voraussetzungen ausgefüllt werden: Name, Datum und Nummer des Basisdokument!'";
				vUM = New UserMessage();
				vUM.SetData(vObj);
				If IsBlankString(CorrectionDescription) Then
					vUM.Field = "CorrectionDescription";
				ElsIf IsBlankString(CorrectionDocumentNumber) Then
					vUM.Field = "CorrectionDocumentNumber";
				ElsIf Not ValueIsFilled(CorrectionDocumentDate) Then
					vUM.Field = "CorrectionDocumentDate";
				EndIf;
				vUM.Text = NStr(rMessage);
				vUM.Message();
				Return False;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction // CheckDocumentAttributesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDeletionMarkAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Read();
	vObj.SetDeletionMark(True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SetDeletionMarkAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function IsAdvancePaymentSection(pPaymentSection)
	If ValueIsFilled(pPaymentSection) And pPaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // IsAdvancePaymentSection

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateAdvanceAmount()
	vAdvanceSettlementAmount = 0;
	vAdvanceSettlementAmountInFolioCurrency = 0;
	vAdvanceSettlementVATAmount = 0;
	vAdvanceSettlementVATAmountInFolioCurrency = 0;
	For Each vPSRow In Object.PaymentSections Do
		If Not IsAdvancePaymentSection(vPSRow.PaymentSection) Then
			vAdvanceSettlementAmount = vAdvanceSettlementAmount + vPSRow.Sum;
			vAdvanceSettlementVATAmount = vAdvanceSettlementVATAmount + vPSRow.VATSum;
			vAdvanceSettlementAmountInFolioCurrency = vAdvanceSettlementAmountInFolioCurrency + vPSRow.SumInFolioCurrency;
			vAdvanceSettlementVATAmountInFolioCurrency = vAdvanceSettlementVATAmountInFolioCurrency + vPSRow.VATSumInFolioCurrency;
		EndIf;
	EndDo;
	vAdvanceRowIsUpdated = False;
	i = Object.PaymentSections.Count() - 1;
	While i >= 0 Do
		vPSRow = Object.PaymentSections.Get(i);
		If IsAdvancePaymentSection(vPSRow.PaymentSection) Then
			If vAdvanceRowIsUpdated Then
				Object.PaymentSections.Delete(i);
			Else
				If Items.PaymentSectionsChequeServicePrice.Visible Then
					vChequeServicePrice = vPSRow.ChequeServicePrice;
					If vChequeServicePrice < 0 Then
						vChequeServicePrice = -vChequeServicePrice;
					EndIf;
					vPSRow.ChequeServicePrice = vChequeServicePrice;
					If vPSRow.ChequeServiceQuantity <> 0 And vPSRow.ChequeServicePrice <> 0 Then
						vPSRow.ChequeServiceQuantity = -Round(vAdvanceSettlementAmount/vChequeServicePrice, 7);
					EndIf;
				EndIf;
				vPSRow.Sum = -vAdvanceSettlementAmount;
				vPSRow.VATSum = -vAdvanceSettlementVATAmount;
				vPSRow.SumInFolioCurrency = -vAdvanceSettlementAmountInFolioCurrency;
				vPSRow.VATSumInFolioCurrency = -vAdvanceSettlementVATAmountInFolioCurrency;
				vAdvanceRowIsUpdated = True;
			EndIf;
		EndIf;
		i = i - 1;
	EndDo;
	// Recalculate payment totals
	Object.SumInFolioCurrency = Object.PaymentSections.Total("SumInFolioCurrency");
	Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
	Object.Sum = Object.PaymentSections.Total("Sum");
	Object.VATSum = Object.PaymentSections.Total("VATSum");
	// Recalculate cheque positions
	FillPrintableChequePositions();
EndProcedure // RecalculateAdvanceAmount

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False)
	vDiscountCardRef = Catalogs.DiscountCards.EmptyRef();
	// Try to find discount card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	(NOT DiscountCards.DeletionMark OR &qSearchMarkedForDeletion)
	|	AND DiscountCards.Identifier = &qIdentifier
	|
	|ORDER BY
	|	DiscountCards.Code";
	vQry.SetParameter("qIdentifier", TrimAll(pIdentifier));
	vQry.SetParameter("qSearchMarkedForDeletion", pSearchMarkedForDeletion);
	vDiscountCards = vQry.Execute().Unload();
	If vDiscountCards.Count() > 0 Then
		vDiscountCardRef = vDiscountCards.Get(0).Ref;
	EndIf;
	Return vDiscountCardRef;
EndFunction // GetDiscountCardById

// -----------------------------------------------------------------------------
&AtClient
Procedure ProcessingReadCard(pCardID)
	// Actions in the document
	If Not IsBlankString(pCardID) Then
		// Try to search discount card with this Id
		vDiscountCard = GetDiscountCardById(pCardID);
		If ValueIsFilled(vDiscountCard) Then
			vPMHasChanged = False;
			vCardholder = tcOnServer.cmGetAttributeByRef(vDiscountCard, "Client");
			If ValueIsFilled(vCardholder) Then
				If vCardholder = Object.Payer Or Not ValueIsFilled(Object.Payer) Or IsNew Then
					Object.DiscountCard = vDiscountCard;
					IsPhysicalCard = True;
					vPMHasChanged = FillBalanceByCard();
					If vPMHasChanged Then
						PaymentMethodOnChange(Items.PaymentMethod);
					EndIf;
				Else
					If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt") Then
						ShowMessageBox(, NStr("en='This card does not belong to the guest! You may clear guest field and try to slip card again.';ru='Чужая карта! Можете очистить поле гостя и заново прокатать карту.';de='Fremde Karte! Sie können das Gastfeld löschen und die Karte neu durchziehen.'"));
					Else
						Object.DiscountCard = vDiscountCard;
						IsPhysicalCard = True;
						vPMHasChanged = FillBalanceByCard();
						If vPMHasChanged Then
							PaymentMethodOnChange(Items.PaymentMethod);
						EndIf;
					EndIf;
				EndIf;
			ElsIf IsNew Then
				Object.DiscountCard = vDiscountCard;
				IsPhysicalCard = True;
				vPMHasChanged = FillBalanceByCard();
				If vPMHasChanged Then
					PaymentMethodOnChange(Items.PaymentMethod);
				EndIf;
			EndIf;
			// Activate form
			If Not vPMHasChanged Then
				Activate();
			EndIf;
		EndIf;
		// Check if something was found
		If Not ValueIsFilled(vDiscountCard) Then
			ShowMessageBox(, NStr("en='Card was not found!';ru='Карта не найдена!';de='Die Karte wurde nicht gefunden!'"), 3);
		EndIf;
	EndIf;	
EndProcedure // ProcessingReadCard

// -----------------------------------------------------------------------------
&AtServerNoContext
Function DiscountCardAutoCompleteAtServer(pText, pCardType = Undefined)
	// 1. Search by ID
	vChoiceDataList = New ValueList;
	vQry = New Query;
	vQry.Text =	"SELECT
	           	|	DiscountCards.Ref AS Ref,
	           	|	DiscountCards.Identifier AS Identifier,
	           	|	DiscountCards.Description AS Description
	           	|FROM
	           	|	Catalog.DiscountCards AS DiscountCards
	           	|WHERE
	           	|	DiscountCards.DeletionMark = FALSE
	           	|	AND DiscountCards.Identifier LIKE &qIdentifier
	           	|	AND (DiscountCards.ValidTo >= &qRequestDate
	           	|			OR DiscountCards.ValidTo = DATETIME(1, 1, 1))
	           	|	AND CASE
	           	|			WHEN &qDiscountType = UNDEFINED
	           	|				THEN TRUE
	           	|			ELSE DiscountCards.DiscountType = &qDiscountType
	           	|		END";
	vQry.SetParameter("qIdentifier", "%"+pText+"%");
	vQry.SetParameter("qRequestDate", CurrentSessionDate());
	vQry.SetParameter("qDiscountType", pCardType);
	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		vChoiceDataList.Add(vQryResult.Ref, vQryResult.Description + " (ID " + vQryResult.Identifier + ")");
	EndDo;
	If vChoiceDataList.Count() > 0 Then
		Return PutToTempStorage(vChoiceDataList);
	EndIf;
	// 2. Search by client phone
	vQry.Text =	"SELECT
	           	|	DiscountCards.Ref AS Ref,
	           	|	DiscountCards.Identifier AS Identifier,
	           	|	DiscountCards.Description AS Description
	           	|FROM
	           	|	Catalog.DiscountCards AS DiscountCards
	           	|WHERE
	           	|	DiscountCards.DeletionMark = FALSE
	           	|	AND DiscountCards.Client.Phone LIKE &qIdentifier
	           	|	AND (DiscountCards.ValidTo >= &qRequestDate
	           	|			OR DiscountCards.ValidTo = DATETIME(1, 1, 1))
	           	|	AND CASE
	           	|			WHEN &qDiscountType = UNDEFINED
	           	|				THEN TRUE
	           	|			ELSE DiscountCards.DiscountType = &qDiscountType
	           	|		END";

	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		vChoiceDataList.Add(vQryResult.Ref, vQryResult.Description + " (Tel." + vQryResult.Identifier + ")");
	EndDo;
	
	Return PutToTempStorage(vChoiceDataList);
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionOnChangeAtServer()
	// Fill VAT rate from the section
	If ValueIsFilled(Object.PaymentSection) Then
		If ValueIsFilled(Object.PaymentSection.VATRate) Then
			Object.VATRate = ?(Object.Company.IsUsingSimpleTaxSystem, Object.Company.VATRate, Object.PaymentSection.VATRate);
			SumOnChangeAtServer();
		EndIf;
	EndIf;
EndProcedure // PaymentSectionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintSlipAfterInputCashRegisterPassword(pValue,pAdditionalParameters) Export
	vDriver = pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.rMessage;
	If Not pValue=Undefined Then
		vDriver.pmPrintSlip(pAdditionalParameters.pSlipTextArr, pAdditionalParameters.pObject, vMessage, pValue.Password);
		If Not IsBlankString(vMessage) Then
			ShowMessageBox(,vMessage,,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		EndIf; 
	EndIf;
EndProcedure // AfterInputCashRegisterPassword()

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardOpening(pItem, pStandardProcessing)
	If Not ValueIsFilled(Object.CreditCard) Then
		pStandardProcessing = False;
	 	OpenForm("Catalog.CreditCards.ObjectForm", New Structure("FillingValues", New Structure("CardOwner, CardNumber", Object.Payer, Items.CreditCard.EditText)), pItem);
	EndIf;
EndProcedure // CreditCardOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardOnChange(pItem)
	If ValueIsFilled(Object.CreditCard) Then
		Object.CardType = tcOnServer.cmGetAttributeByRef(Object.CreditCard, "CardType");
	EndIf;
EndProcedure // CreditCardOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure PayerOnChangeAtServer()
	If ValueIsFilled(Object.Payer) And TypeOf(Object.Payer) = Type("CatalogRef.Customers") Then
		If Object.PaymentMethod = Catalogs.PaymentMethods.Settlement Then
			If Object.AccountingCustomer <> Object.Payer Then
				Object.AccountingCustomer = Object.Payer;
				Object.AccountingContract = Undefined;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PayerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PayerOnChange(pItem)
	PayerOnChangeAtServer(); 
	FillListOfPayersCreditCards();
	SendPayerContactsRefresh(False, True, False, False);
EndProcedure // PayerOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure VATRateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure VATRateOnChange(pItem)
	VATRateOnChangeAtServer();
EndProcedure // VATRateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SendPayerContactsRefresh(pIsOnOpen = False, pIsChangePayer = False, pIsChangeCashRegister = False, pIsChangePaymentMethod = False)
	If ValueIsFilled(Object.CashRegister) And Object.CashRegister.IsControlledByProgram And 
	   ValueIsFilled(Object.PaymentMethod) And Object.PaymentMethod.BookByCashRegister And Object.PaymentMethod.PrintCheque Then
		If pIsOnOpen And Not ValueIsFilled(Object.Ref) Or pIsChangeCashRegister Then
	   		Object.SendPayerContactsToOFD = Object.CashRegister.SendPayerContactsToOFD;
		EndIf;
		Items.SendPayerContacts.Visible = True;
	ElsIf pIsOnOpen Then
		If Not ValueIsFilled(Object.Ref) Then
			Object.SendPayerContactsToOFD = 2;
		EndIf;
		Items.SendPayerContacts.Visible = False;
	ElsIf pIsChangeCashRegister Or pIsChangePaymentMethod Then
		Object.SendPayerContactsToOFD = 2;
		Items.SendPayerContacts.Visible = False;
	EndIf;
	If Object.SendPayerContactsToOFD = 0 Then	
		Items.EmailToSendToOFD.Enabled = True;
		Items.PhoneToSendToOFD.Enabled = False;
	ElsIf Object.SendPayerContactsToOFD = 1 Then
		Items.EmailToSendToOFD.Enabled = False;
		Items.PhoneToSendToOFD.Enabled = True;	
	ElsIf Object.SendPayerContactsToOFD = 2 Then
		Items.EmailToSendToOFD.Enabled = False;
		Items.PhoneToSendToOFD.Enabled = False;	
	EndIf;
	If pIsOnOpen And Not ValueIsFilled(Object.Ref) Or pIsChangePayer Then
		If ValueIsFilled(Object.Payer) Then
			Object.EmailToSendToOFD = Object.Payer.EMail;
			Object.PhoneToSendToOFD = Object.Payer.Phone;
		Else
			Object.EmailToSendToOFD = "";
			Object.PhoneToSendToOFD = "";
		EndIf;
	EndIf;
EndProcedure // SendClientContactsRefresh

// -----------------------------------------------------------------------------
&AtServer
Function fRevokeExternalPayment()
	vDP = ExternalSystem.DataProcessor;
	
	If Not ValueIsFilled(vDP) Then
		Raise Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
	EndIf;	
	
	vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
	
	If vDPO = Undefined Then
		Raise Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");			
	EndIf;
	
	vMessage = "";
	If Not vDPO.RevokeExternalPayment(Object, vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
		Return False;
	 EndIf;
	                             
	Return True;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function fmStartCreditCardExternalPayment()
	vDP = ExternalSystem.DataProcessor;
	
	If Not ValueIsFilled(vDP) Then
		Raise Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
	EndIf;	
	
	vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
	
	If vDPO = Undefined Then
		Raise Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");			
	EndIf;
	
	vMessage = "";
	If Not vDPO.StartExternalPayment(Object, vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
		Return False;
	 EndIf;
	                             
	Return True;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure fmGetExternalCardBalance(pIdentifier); 
	ExternalCardBalance = 0;
	ExternalCardTotalBalance = 0;
	Items.DecorationBalance.Title = "";

	vDP = ExternalSystem.DataProcessor;
	
	If Not ValueIsFilled(vDP) Then
		Raise Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
	EndIf;
	
	vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
	
	If vDPO = Undefined Then
		Raise Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");			
	EndIf;
	
	vIdentifier = pIdentifier;
	If TypeOf(pIdentifier) = Type("CatalogRef.DiscountCards") Then
		vIdentifier = tcOnServer.cmGetAttributeByRef(pIdentifier, "Identifier");	
	EndIf;
	
	vResponse = vDPO.GetCardBalance(TrimAll(vIdentifier), Object, ExternalCardBalance, ExternalCardTotalBalance);

	If vResponse.Success Then
		FillCardBalanceTitle();
	Else
		For Each vRowErr In vResponse.Errors Do
			tcCommonFunctionOnClientServer.TextMessage(vRowErr);
		EndDo;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function fmStartExternalPayment()
	vDP = ExternalSystem.DataProcessor;
	
	If Not ValueIsFilled(vDP) Then
		Raise Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
	EndIf;	
	
	vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
	If vDPO = Undefined Then
		Raise Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");			
	EndIf;
	
	vResponse = vDPO.StartExternalPayment(Object);
	If Not vResponse.Success Then
		For Each vRowErr In vResponse.Errors Do
			tcCommonFunctionOnClientServer.TextMessage(vRowErr);
		EndDo;
		Return False;
	EndIf;
	                             
	Return True;
EndFunction	

// -----------------------------------------------------------------------------
&AtServer
Function fmFinishExternalPayment(pAuthorizationCode = "", pSkipAuthorization = False)
	vDP = ExternalSystem.DataProcessor;
	
	If Not ValueIsFilled(vDP) Then
		Raise Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
	EndIf;
	
	vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
	If vDPO = Undefined Then
		Raise Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");			
	EndIf;
		
	vResponse = vDPO.FinishExternalPayment(pAuthorizationCode, Object, NewObjectRef, pSkipAuthorization);
	
	If Not vResponse.Success Then
		For Each vRowErr In vResponse.Errors Do
			tcCommonFunctionOnClientServer.TextMessage(vRowErr);
		EndDo;
		Return False;
	EndIf;	
	Return True;
EndFunction	

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCardBalanceTitle()
	vArrFD = New Array;
	vCard = Object.DiscountCard; 
	If ValueIsFilled(vCard) Then
		If vCard.LoyaltyType = Enums.LoyaltyType.Bonuses Then
			// Get formating string folio description
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", NStr("en = 'Can be spent:'; de = 'können ausgeben:'; ru = 'Можно потратить:'"), New Font(,9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(ExternalCardBalance,"NFD=2; NDS=.; NZ=0.00; NG=0"), New Font(,11,True), new Color(0,128,0)));
			If ExternalCardTotalBalance > 0 Then
				vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", Chars.LF));
				vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", NStr("en = 'Total bonuses:'; de = 'Gesamtboni:'; ru = 'Всего бонусов:'"), New Font(,9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(ExternalCardTotalBalance,"NFD=2; NDS=.; NZ=0.00; NG=0"), New Font(,11,True), new Color(0,128,0)));
			EndIf;
		ElsIf vCard.LoyaltyType = Enums.LoyaltyType.Certificate Then
			vTextBalance = NStr("en = 'Balance: '; de = 'Kontostand: '; ru = 'Остаток: '");
			// Get formating string folio description
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", vTextBalance, New Font(,9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(ExternalCardBalance,"NFD=2; NDS=.; NZ=0.00; NG=0"), New Font(,11,True), new Color(0,128,0)));
		EndIf;
	EndIf;
	If vArrFD.Count() > 0 Then
		Items.DecorationBalance.Title = tcOnServer.cmGenerateFormattedString(vArrFD);
	Else
		Items.DecorationBalance.Title = "";	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateCardBalance(pCommand)
	If ValueIsFilled(Object.DiscountCard) Then
		fmGetExternalCardBalance(tcOnServer.cmGetAttributeByRef(Object.DiscountCard, "Identifier"));			
	EndIf;
EndProcedure // UpdateCardBalance

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearLinkToInvoice(pCommand)
	Object.Invoice = Undefined;
EndProcedure // ClearLinkToInvoice

// -----------------------------------------------------------------------------
&AtServer
Procedure Folio1OnChangeAtServer()
	If ValueIsFilled(Object.Folio) Then
		Object.FolioCurrency = Object.Folio.FolioCurrency;
		Object.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.FolioCurrency, Object.ExchangeRateDate);
		Object.Company = Object.Folio.Company;
		Object.AccountingCustomer = ?(ValueIsFilled(Object.Folio.Customer), Object.Folio.Customer, Object.Hotel.IndividualsCustomer);
		Object.AccountingContract = ?(ValueIsFilled(Object.Folio.Contract), Object.Folio.Contract, ?(Object.AccountingCustomer = Object.Hotel.IndividualsCustomer, Object.Hotel.IndividualsContract, Catalogs.Contracts.EmptyRef()));
		Object.GuestGroup = Object.Folio.GuestGroup;
	EndIf;
EndProcedure // Folio1OnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure Folio1OnChange(pItem)
	Folio1OnChangeAtServer();
EndProcedure // Folio1OnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CorrectionOfIncorrectChequeOnChange(pItem)
	If Object.CorrectionOfIncorrectCheque Then
		Items.Payment.Visible = True;
	Else
		Object.Payment = Undefined;
		Items.Payment.Visible = False;
	EndIf;
EndProcedure // CorrectionOfIncorrectChequeOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDiscountCard(pIsChangePaymentMethod = False)
	vPaymentMethod = Object.PaymentMethod;
	If ValueIsFilled(vPaymentMethod) Then
		If vPaymentMethod.IsByBonuses Or vPaymentMethod.IsByGiftCertificate Then			
									
			If ValueIsFilled(Object.DiscountCard) Then
				If ValueIsFilled(ExternalSystem) Then
					// 1. Get card and balance;
					fmGetExternalCardBalance(Object.DiscountCard.Identifier);
				EndIf;	
			EndIf; 
			
			vParentDoc = Object.ParentDoc;
			If ValueIsFilled(Object.DiscountCard) And ValueIsFilled(vParentDoc) And vParentDoc.DiscountCard = Object.DiscountCard Then
				Items.DiscountCard.ReadOnly = True;	
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillDiscountCard

// -----------------------------------------------------------------------------
&AtServer
Function CheckReturnExist()
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Return.Ref AS Return
	|FROM
	|	Document.Return AS Return
	|WHERE
	|	NOT Return.DeletionMark
	|	AND Return.Posted
	|	AND Return.Folio = &qFolio
	|	AND Return.Hotel = &qHotel
	|	AND Return.GuestGroup = &qGuestGroup
	|	AND Return.PaymentMethod = &qPaymentMethod
	|	AND Return.Payment = &qPayment";
	vQuery.SetParameter("qFolio", Object.Folio);
	vQuery.SetParameter("qHotel", Object.Hotel);
	vQuery.SetParameter("qGuestGroup", Object.GuestGroup);
	vQuery.SetParameter("qPaymentMethod", Object.PaymentMethod);
	vQuery.SetParameter("qPayment", Object.Ref);
	Return vQuery.Execute().IsEmpty();
EndFunction // CheckReturnExist

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearLinkToPreauthorisation(Command)
	ClearPreauthorisation();
EndProcedure // ClearLinkToPreauthorisation

// -----------------------------------------------------------------------------
&AtClient
Procedure PreauthorisationOnChange(pItem)
	If ValueIsFilled(Object.Preauthorisation) Then
		Items.GroupPreauthorisationCalculation.Visible = True;
	Else
		ClearPreauthorisation();
	EndIf;
EndProcedure // PreauthorisationOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionsVATRateOnChangeAtServer()
	vCurRow = Items.PaymentSections.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.PaymentSections.FindByID(vCurRow);
		If vCurData <> Undefined Then
			vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, Object.Date);
			vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, Object.Date);
			// Recalculate payment totals
			Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
			Object.VATSum = Object.PaymentSections.Total("VATSum");
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsVATRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsVATRateOnChange(pItem)
	PaymentSectionsVATRateOnChangeAtServer();
EndProcedure // PaymentSectionsVATRateOnChange

// -----------------------------------------------------------------------------
&AtServer
Function GetCreditCardProcessingSystem()
	vTempArr = New Array();
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vQry = New Query; 
		vQry.Text = "SELECT
		            |	ConnectedDevices.DeviceSettings AS DeviceSettings
		            |FROM
		            |	InformationRegister.ConnectedDevices AS ConnectedDevices
		            |WHERE
		            |	ConnectedDevices.Workstation = &qCurrentWorkstation
		            |	AND ConnectedDevices.DeviceType = &qCreditCardProcessingSystem
		            |	AND ConnectedDevices.IsActive
		            |	AND (ConnectedDevices.DeviceSettings.Company = VALUE(Catalog.Companies.EmptyRef)
		            |			OR ConnectedDevices.DeviceSettings.Company = &qCompany)";
		vQry.SetParameter("qCurrentWorkStation", SessionParameters.CurrentWorkstation);
		vQry.SetParameter("qCreditCardProcessingSystem", Enums.DeviceTypes.CreditCardsProcessingSystemParameters);
		vQry.SetParameter("qCompany", Object.Company);
		vResult = vQry.Execute().Unload();
		
		vTempArrayWithPaymentMethod = New Array();
		For Each vRow In vResult Do
			vPaymentMethods = vRow.DeviceSettings.PaymentMethods;
			If vPaymentMethods.Count() > 0 Then
				For Each vPaymentRow In vPaymentMethods Do
					If vPaymentRow.PaymentMethod = Object.PaymentMethod Then
						vTempArrayWithPaymentMethod.Add(vRow.DeviceSettings); 
					Else
						vTempArr.Add(vRow.DeviceSettings);
					EndIf;
				EndDo;
			Else
				vTempArr.Add(vRow.DeviceSettings);
			EndIf;
		EndDo;
		
		If vTempArrayWithPaymentMethod.Count() > 0 Then
			Return vTempArrayWithPaymentMethod;
		Else
			Return vTempArr;
		EndIf;
	Else
		Return vTempArr;
	EndIf;
EndFunction // GetCreditCardProcessingSystem 

// -----------------------------------------------------------------------------
&AtServer
Function FillListOfDefaultPaymentAmounts()
	vList = New ValueList();
	PaymentServicesPerDates.Clear();
	
	// Do basic checks
	If Not ValueIsFilled(Object.Hotel) Then
		Return vList;
	EndIf;
	If Not ValueIsFilled(Object.Folio) Then
		Return vList;
	EndIf;
	If Not ValueIsFilled(Object.PaymentCurrency) Then
		Return vList;
	EndIf;
	If Not ValueIsFilled(Object.ExchangeRateDate) Then
		Return vList;
	EndIf;
	vHotelAccountingDate = Object.Hotel.AccountingDate;
	If Not ValueIsFilled(vHotelAccountingDate) Then
		vHotelAccountingDate = BegOfDay(CurrentSessionDate());
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Services.AccountingDate AS AccountingDate,
	|	Services.PaymentSection AS PaymentSection,
	|	Services.ChequeService AS ChequeService,
	|	Services.ChequeServicePrice AS ChequeServicePrice,
	|	Services.VATRate AS VATRate,
	|	Services.FolioCurrency AS FolioCurrency,
	|	Services.MarkingCode AS MarkingCode,
	|	0 AS VATSum,
	|	0 AS SumInFolioCurrency,
	|	0 AS VATSumInFolioCurrency,
	|	0 AS AccountingDateIndex,
	|	SUM(Services.ChequeServiceQuantity) AS ChequeServiceQuantity,
	|	SUM(Services.Sum) AS Sum
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN Transactions.Recorder REFS Document.Storno
	|				THEN BEGINOFPERIOD(Transactions.Recorder.ParentCharge.Date, DAY)
	|			WHEN Transactions.Recorder REFS Document.Charge
	|					AND NOT Transactions.Recorder.CorrectedCharge.Number IS NULL
	|				THEN BEGINOFPERIOD(Transactions.Recorder.CorrectedCharge.Date, DAY)
	|			ELSE BEGINOFPERIOD(Transactions.Recorder.Date, DAY)
	|		END AS AccountingDate,
	|		Transactions.ChequeService.PaymentSection AS PaymentSection,
	|		Transactions.ChequeService AS ChequeService,
	|		Transactions.ChequeServicePrice AS ChequeServicePrice,
	|		Transactions.ChequeServiceQuantity AS ChequeServiceQuantity,
	|		Transactions.Sum AS Sum,
	|		Transactions.VATRate AS VATRate,
	|		Transactions.FolioCurrency AS FolioCurrency,
	|		ISNULL(Transactions.Recorder.MarkingCode, """") AS MarkingCode
	|	FROM
	|		AccumulationRegister.Accounts AS Transactions
	|	WHERE
	|		Transactions.Folio = &qFolio
	|		AND Transactions.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ForecastTransactions.AccountingDate,
	|		ForecastTransactions.Service.PaymentSection,
	|		ForecastTransactions.Service,
	|		ForecastTransactions.Price,
	|		ForecastTransactions.Quantity,
	|		ForecastTransactions.Sales,
	|		ForecastTransactions.VATRate,
	|		ForecastTransactions.FolioCurrency,
	|		""""
	|	FROM
	|		AccumulationRegister.AccountsReceivableForecast AS ForecastTransactions
	|	WHERE
	|		ForecastTransactions.Folio = &qFolio
	|		AND ForecastTransactions.AccountingDate >= &qHotelDate) AS Services
	|
	|GROUP BY
	|	Services.AccountingDate,
	|	Services.PaymentSection,
	|	Services.ChequeService,
	|	Services.ChequeServicePrice,
	|	Services.VATRate,
	|	Services.FolioCurrency,
	|	Services.MarkingCode
	|
	|HAVING
	|	SUM(Services.Sum) > 0
	|
	|ORDER BY
	|	Services.AccountingDate,
	|	Services.ChequeService.SortCode,
	|	Services.ChequeService.Code";
	vQry.SetParameter("qFolio", Object.Folio);
	vQry.SetParameter("qHotelDate", vHotelAccountingDate);
	vServices = vQry.Execute().Unload();
	
	// Recalculate amounts in the table received
	For Each vServicesRow In vServices Do
		If ValueIsFilled(vServicesRow.AccountingDate) And 
		   ValueIsFilled(vServicesRow.ChequeService) And ValueIsFilled(vServicesRow.ChequeService.QuantityCalculationRule) And 
		   (TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(Object.ParentDoc) = Type("DocumentRef.Reservation")) Then
			vAccountingDateMove = cmGetAccountingDateMove(vServicesRow.ChequeService.QuantityCalculationRule, False, Object.ParentDoc);
			If vAccountingDateMove < 0 Then
				vServicesRow.AccountingDate = vServicesRow.AccountingDate - (24*3600);
				vServicesRow.AccountingDateIndex = vServicesRow.AccountingDateIndex - 1;
			EndIf;
		EndIf;
				
		vServicesRow.ChequeServiceQuantity = ?(vServicesRow.ChequeServiceQuantity = 0, 1, vServicesRow.ChequeServiceQuantity);
		vServicesRow.Sum = Round(cmConvertCurrencies(vServicesRow.Sum, vServicesRow.FolioCurrency, , Object.PaymentCurrency, , Object.ExchangeRateDate, Object.Hotel), 2);
		vServicesRow.ChequeServicePrice = Round(vServicesRow.Sum/vServicesRow.ChequeServiceQuantity, 7);
		vServicesRow.VATSum = cmCalculateVATSum(vServicesRow.VATRate, vServicesRow.Sum, Object.Date);
		vServicesRow.SumInFolioCurrency = vServicesRow.Sum;
		vServicesRow.VATSumInFolioCurrency = cmCalculateVATSum(vServicesRow.VATRate, vServicesRow.SumInFolioCurrency, Object.Date);
	EndDo;
	vServices.GroupBy("AccountingDate, AccountingDateIndex, PaymentSection, ChequeService, ChequeServicePrice, VATRate, MarkingCode", "ChequeServiceQuantity, Sum, VATSum, SumInFolioCurrency, VATSumInFolioCurrency");
	vServices.Sort("AccountingDate");
	
	// Fill list
	vCurAccountingDate = '00010101';
	vCurAccountingDateIndex = 0;
	vCurSum = 0;
	vCurDateSum = 0;
	For Each vServicesRow In vServices Do
		vServicesRow.AccountingDateIndex = vCurAccountingDateIndex;
		If vCurAccountingDate = '00010101' Then
			vCurAccountingDate = vServicesRow.AccountingDate;
		Else
			If vCurAccountingDate <> vServicesRow.AccountingDate Then
				If vCurAccountingDateIndex >= 1 And Not ShowAllDatesMode Then
					If vCurAccountingDateIndex = 1 Then
						vList.Add(-0.01, "...");
					EndIf;
				Else
					If vCurDateSum <> 0 Then
						If ShowAllDatesMode Then
							vList.Add(vCurSum, Format(vCurAccountingDateIndex + 1, "NFD=0; NZ=; NG=") + ". " + Format(vCurAccountingDate, "DF='dd.MM.yyyy - ddd'") + " - " + cmFormatSum(vCurDateSum, Object.PaymentCurrency) + ?(vCurAccountingDateIndex > 0, NStr("en=' (Total: '; ru=' (Итого: '; de=' (Total: '") + cmFormatSum(vCurSum, Object.PaymentCurrency) + ")", ""));
						Else
							vList.Add(vCurSum, Format(vCurAccountingDate, "DF='dd.MM.yyyy - ddd'") + " - " + cmFormatSum(vCurSum, Object.PaymentCurrency));
						EndIf;
					EndIf;
				EndIf;
				
				vCurAccountingDate = vServicesRow.AccountingDate;
				vCurAccountingDateIndex = vCurAccountingDateIndex + 1;
				vCurDateSum = 0;

				vServicesRow.AccountingDateIndex = vCurAccountingDateIndex;
			EndIf;
		EndIf;
		vCurSum = vCurSum + vServicesRow.Sum;
		vCurDateSum = vCurDateSum + vServicesRow.Sum;
	EndDo;
	If vCurDateSum > 0 Then
		If ShowAllDatesMode Then
			vList.Add(vCurSum, Format(vCurAccountingDateIndex + 1, "NFD=0; NZ=; NG=") + ". " + Format(vCurAccountingDate, "DF='dd.MM.yyyy - ddd'") + " - " + cmFormatSum(vCurDateSum, Object.PaymentCurrency) + ?(vCurAccountingDateIndex > 0, NStr("en=' (Total: '; ru=' (Итого: '; de=' (Total: '") + cmFormatSum(vCurSum, Object.PaymentCurrency) + ")", ""));
		Else
			vList.Add(vCurSum, NStr("en='Total: '; ru='Итого: '; de='Total: '") + cmFormatSum(vCurSum, Object.PaymentCurrency));
		EndIf;
		vCurAccountingDateIndex = vCurAccountingDateIndex + 1;
	EndIf;
	If Not ShowAllDatesMode And vCurAccountingDateIndex = 1 And vList.Count() = 3 And vList.Get(1).Value = -0.01 Then
		vList.Delete(1);
	EndIf;
	
	// Check type of payment fill
	If Object.Hotel.SplitFolioBalanceByServicesAndPrices Then
		// Fill form table with amounts per dates 
		For Each vServicesRow In vServices Do
			vPaymentServicesPerDatesRow = PaymentServicesPerDates.Add();
			FillPropertyValues(vPaymentServicesPerDatesRow, vServicesRow);
		EndDo;
	ElsIf Object.Hotel.SplitFolioBalanceByPaymentSections Then
		// Fill form table with amounts per dates
		For Each vServicesRow In vServices Do
			vServicesRow.ChequeService = Catalogs.Services.EmptyRef();
			vServicesRow.ChequeServicePrice = 0;
			vServicesRow.ChequeServiceQuantity = 0;
			vServicesRow.MarkingCode = "";
			If ValueIsFilled(vServicesRow.PaymentSection) And ValueIsFilled(vServicesRow.PaymentSection.VATRate) Then
				vServicesRow.VATRate = vServicesRow.PaymentSection.VATRate;
			EndIf;
			vServicesRow.VATSum = 0;
			vServicesRow.VATSumInFolioCurrency = 0;
		EndDo;
		vServices.GroupBy("AccountingDate, AccountingDateIndex, PaymentSection, ChequeService, ChequeServicePrice, VATRate", "ChequeServiceQuantity, Sum, VATSum, SumInFolioCurrency, VATSumInFolioCurrency");
		For Each vServicesRow In vServices Do
			vServicesRow.VATSum = cmCalculateVATSum(vServicesRow.VATRate, vServicesRow.Sum, Object.Date);
			vServicesRow.VATSumInFolioCurrency = cmCalculateVATSum(vServicesRow.VATRate, vServicesRow.SumInFolioCurrency, Object.Date);
			
			vPaymentServicesPerDatesRow = PaymentServicesPerDates.Add();
			FillPropertyValues(vPaymentServicesPerDatesRow, vServicesRow);
		EndDo;
	EndIf;
	
	// Add last row with folio balance
	If ValueIsFilled(Object.PaymentSection) And Object.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
		vFolioBalanceAmount = Object.Folio.GetObject().pmGetBalance('39991231235959', Object.Hotel, Object.PaymentSection); 
		vFolioBalanceAmount = Round(cmConvertCurrencies(vFolioBalanceAmount, Object.FolioCurrency, , Object.PaymentCurrency, , Object.ExchangeRateDate, Object.Hotel), 2);
		If vFolioBalanceAmount < 0 And vCurSum > 0 And vCurSum > -vFolioBalanceAmount Then
			vBalanceAmount = vCurSum + vFolioBalanceAmount;
			vList.Add(vBalanceAmount, NStr("en='Amount left to be paid: '; ru='Сумма, оставшаяся к оплате: '; de='Noch zu zahlender Betrag: '") + cmFormatSum(vBalanceAmount, Object.PaymentCurrency));
		EndIf;
	EndIf;
	
	// Return
	Return vList;
EndFunction // FillListOfDefaultPaymentAmounts

#EndRegion
