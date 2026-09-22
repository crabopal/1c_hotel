
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
	
	// Fill ref and is new flag
	FillDocumentObjectParameters(pCancel, pStandardProcessing);
	
	// Initialize some attributes
	ChequeIsPrinted = False;
	PaymentIsAuthorized = False;
	If ValueIsFilled(Object.PaymentMethod) Then
		ExternalSystem = Object.PaymentMethod.ExternalSystem;	
	EndIf;
	
	Items.UpdateCardBalance.Visible = ValueIsFilled(ExternalSystem);
	
	// Set appearance of payment sections tabular part
	AdvanceMode = False;
	AdvanceSettlementMode = False;
	If ValueIsFilled(Object.PaymentSection) And Object.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
		AdvanceMode = True;
	ElsIf Object.PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement And Object.Sum = 0 Then
		AdvanceSettlementMode = True;
	EndIf;
	MultipleAdvanceSectionsMode = MultipleAdvancePaymentSectionsMode();
	If ValueIsFilled(Object.Hotel) And Object.Hotel.SplitFolioBalanceByPaymentSections Then
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
			Items.PaymentSections.ReadOnly = True;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = False;
			Items.PaymentSectionsChequeService.Visible = True;
			Items.PaymentSectionsChequeServicePrice.Visible = True;
			Items.PaymentSectionsChequeServiceQuantity.Visible = True;
		ElsIf MultipleAdvanceSectionsMode Then
			Items.PaymentSectionsGroup.Visible = True;
			Items.PaymentSection.Visible = False;
			Items.Sum.Visible = True;
			Items.Sum.ReadOnly = True;
			Items.Sum.TextEdit = False;
			Items.Sum.ChoiceListButton = False;
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
	ElsIf ValueIsFilled(Object.Hotel) And Object.Hotel.SplitFolioBalanceByServicesAndPrices Then
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
			Items.PaymentSections.ReadOnly = True;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = False;
			Items.PaymentSectionsChequeService.Visible = True;
			Items.PaymentSectionsChequeServicePrice.Visible = True;
			Items.PaymentSectionsChequeServiceQuantity.Visible = True;
		ElsIf MultipleAdvanceSectionsMode Then
			Items.PaymentSectionsGroup.Visible = True;
			Items.PaymentSection.Visible = False;
			Items.Sum.Visible = True;
			Items.Sum.ReadOnly = True;
			Items.Sum.TextEdit = False;
			Items.Sum.ChoiceListButton = False;
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
	
	If ValueIsFilled(Object.PaymentMethod) Then
		vPaymentMethod = Object.PaymentMethod; 
		If vPaymentMethod.IsByBonuses And ValueIsFilled(vPaymentMethod.ExternalSystem) Then
			vExternalSystem = vPaymentMethod.ExternalSystem;
			If vExternalSystem.OnlyOnePayment Then
				Items.HeaderGroup.ReadOnly = True;
				Items.GroupPayer.ReadOnly = True;
				Items.SendPayerContacts.ReadOnly = True;
				Items.MainGroup.ReadOnly = True;
				Items.PaymentSectionsGroup.ReadOnly = True;
				Items.PaymentSection.ReadOnly = True;
				Items.PaymentSection.ClearButton = False;
				Items.GroupParentDocs.ReadOnly = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Correction cheque attributes parameters
	SetCorrectionChequeAttributes();
	
	// Payment card
	Items.PaymentCardDataGroup.Visible = HasPaymentCardData();
	
	// Fill list of cash registers allowed for the current user
	FillListOfCashRegisters();
	
	// Fill list of payment methods allowed for the current user
	FillListOfPaymentMethods();
	
	// Set appearance of the new document form
	If Not Object.Posted Then
		Items.FormSetDeletionMarkAction.Visible = False;
	Else 
		vHotel = Object.Hotel;
		vCompany = Object.Company;
		// Check rights to edit posted document
		If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
			ReadOnly = True;
			Items.FormSetDeletionMarkAction.Visible = False;
		EndIf;
		// Check edit prohibited dates
		If ValueIsFilled(vHotel) Then
			If ValueIsFilled(vHotel.EditProhibitedDate) And BegOfDay(vHotel.EditProhibitedDate) >= BegOfDay(Object.Date) Then
				ReadOnly = True;
				Items.FormSetDeletionMarkAction.Visible = False;
			EndIf;
		EndIf;
		If ValueIsFilled(vCompany) Then
			If ValueIsFilled(vCompany.EditProhibitedDate) And BegOfDay(vCompany.EditProhibitedDate) >= BegOfDay(Object.Date) Then
				ReadOnly = True;
				Items.FormSetDeletionMarkAction.Visible = False;
			EndIf;
		EndIf;
		// Check hotel accounting date
		If ValueIsFilled(vHotel) Then
			If vHotel.DoNotEditClosedDateDocs And ValueIsFilled(vHotel.AccountingDate) And Object.Date < BegOfDay(vHotel.AccountingDate) Then
				ReadOnly = True;
				Items.FormSetDeletionMarkAction.Visible = False;
			Endif;
		Endif;
	EndIf;
	
	// Fill balance by discount card or certificate
	FillBalanceByCard(True);
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Fill list of payers credit cards
	FillListOfPayersCreditCards();
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Print return forms button
	If ValueIsFilled(Object.Ref) And Object.Posted And 
	   Catalogs.ObjectPrintingForms.ReturnFormsSet.IsActive And 
	   Not Catalogs.ObjectPrintingForms.ReturnFormsSet.DeletionMark Then
		Items.FormPrintReturnForms.Visible = True;
	Else
		Items.FormPrintReturnForms.Visible = False;
	EndIf;
	
	// View of payer contact data
	If ValueIsFilled(Object.Ref) Then
		SendPayerContactsRefresh(True, False, False, False);
	EndIf;
	
	If ValueIsFilled(Object.Payment) Then
		Items.ClearPayment.Enabled = True;
	Else
		Items.ClearPayment.Enabled = False;
	EndIf;
	
	FillDiscountCard();
	
	Items.Payment1.Visible = Not Object.CorrectionOfIncorrectCheque;
	Items.ClearPayment.Visible = Not Object.CorrectionOfIncorrectCheque;
	Items.Payment.Visible = Object.CorrectionOfIncorrectCheque;

	FillCompanyAndCashRegisterCollapsedRepresentation();
EndProcedure // OnCreateAtServer

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
				tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
				Return;
			EndIf;
			SetNewObjectRefAtServer();
			vMessage = "";
			If ValueIsFilled(Object.DiscountCard) And (vPaymentMethodArr.IsByBonuses Or vPaymentMethodArr.IsByGiftCertificate) And ValueIsFilled(ExternalSystem) And Not Object.BonusesAreProcessed Then
				If fmReturnExternalPayment() Then   
					Object.BonusesAreProcessed = True;
					// Call procedure to save payment to the database
					AttachIdleHandler("SaveDocumentToPendingList", 0.1, True);	
				Else
					pCancel = True;
					Return;
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
						If vCashRegisterArr.IsControlledByProgram And Not ChequeIsPrinted Then
							If vPaymentMethodArr.PrintCheque Then
								If Object.Sum <> 0 Or Object.Sum = 0 And Object.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
									If Not IsReadyToPrintCheque(vMessage, Object.CashRegister) Then
										pCancel = True;
										tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
										ShowMessageBox(,tcOnServer.cmNStrAtServer(vMessage));
										Return;
									Endif;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					// Process payment by the credit card processing system
					If vPaymentMethodArr.IsByCreditCard Then
						If ValueIsFilled(ExternalSystem) Then
							If Not ValueIsFilled(Object.ReferenceNumber) And Not ValueIsFilled(Object.AuthorizationCode) And ValueIsFilled(Object.OrderID) Then
								If Not IsBlankString(?(ValueIsFilled(Object.Payment) And TypeOf(Object.Payment) <> Type("DocumentRef.DepositTransfer"), tcOnServer.cmGetAttributeByRef(Object.Payment, "ReferenceNumber"), "")) Or Not vPaymentMethodArr.ReferenceCodeIsRequired And
								   Not IsBlankString(?(ValueIsFilled(Object.Payment) And TypeOf(Object.Payment) <> Type("DocumentRef.DepositTransfer"), tcOnServer.cmGetAttributeByRef(Object.Payment, "OrderID"), "")) And Not IsBlankString(?(ValueIsFilled(Object.Payment) And TypeOf(Object.Payment) <> Type("DocumentRef.DepositTransfer"), tcOnServer.cmGetAttributeByRef(Object.Payment, "OrderURL"), "")) Then
								   	pCancel = True;
								   	If Not ValueIsFilled(Object.ExternalCode) Then
										If Not fmReturnCreditCardExternalPayment() Then
											Return;		
										EndIf;
									EndIf;	
									AttachIdleHandler("SaveDocumentToOpenQRCodePaymentForm", 0.1, True);  	
									Return;	  
								EndIf; 
							Else
								PaymentIsAuthorized = True;	
							EndIf;
						ElsIf Not vPaymentMethodArr.ExternalBankTerminalIsUsed Then
							// If payment was earlier authorized manually (reference number is filled) or automatically then skip this step
							If IsBlankString(Object.ReferenceNumber) And Not PaymentIsAuthorized Then
								If CheckCreditCardsProcessingSystem() Then
									vPayment = Object.Payment;
									If ValueIsFilled(vPayment) Then
										While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
											vPayment = tcOnServer.cmGetAttributeByRef(vPayment, "Payment");
											If Not ValueIsFilled(vPayment) Then
												Break;
											EndIf;
										EndDo;
									EndIf;
									vPaymentReferenceCode = "";
									If ValueIsFilled(vPayment) Then
										vPaymentReferenceCode = tcOnServer.cmGetAttributeByRef(vPayment, "ReferenceNumber");
									EndIf;
									If vPaymentMethodArr.ReferenceCodeIsRequired And IsBlankString(vPaymentReferenceCode) Then
										pCancel = True;
										If ValueIsFilled(vPayment) Then
											vMessage = NStr("en='Payment reference number should be set!';ru='В параметрах документа по которому делается возврат должен быть указан референс номер платежа!';de='In den Parametern des Dokuments, nach dem die Rückgabe erfolgt, muss die Zahlungsreferenznummer angegeben sein!'");
										Else
											vMessage = NStr("en='Return should be based on payment! Select payment in the transactions list and press <Return> button.';ru='Возврат должен быть на основании платежа! В списке транзакций выделите платеж и затем нажмите кнопку <Возврат>.';de='Die Rückgabe muss auf der Grundlage einer Zahlung eingegeben werden! Markieren Sie in der Transaktionsliste die Zahlung und drücken Sie die Taste <Rückgabe>.'");
										EndIf;
										tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , vMessage);
										ShowMessageBox(, vMessage);
										Return;
									Else
										If Object.Sum <> 0 Then
											If Not AuthorizePayment(vMessage) Then
												pCancel = True;
												tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
												ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
												Return;
											Else
												PaymentIsAuthorized = True;
											EndIf;
										Else
											pCancel = True;
											vMessage = NStr("en='Refund amount should be entered!';ru='Не введена сумма возврата!';de='Die Rückgabesumme wurde nicht eingegeben!'");
											tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , vMessage);
											ShowMessageBox(,vMessage);
											Return;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					ElsIf vPaymentMethodArr.IsViaInternetAcquiring And IsBlankString(Object.ExternalCode) And 
					      ValueIsFilled(Object.Payment) And TypeOf(Object.Payment) <> Type("DocumentRef.DepositTransfer") Then
	                    // Process payment by the internet acquiring 
	                    vExtPaymentRef = tcOnServer.cmGetAttributeByRef(Object.Payment, "ExternalCode");  
						vRRN = tcOnServer.cmGetAttributeByRef(Object.Payment, "ReferenceNumber"); 
						vAuthorizationCode = ""; 
	                    If Not IsBlankString(vExtPaymentRef) Then
	                        vUUID = "";
	                        If Not InternetAcquiringRefund(Object.Sum, vExtPaymentRef, Object.Hotel, vUUID, vMessage, vRRN, vAuthorizationCode) Then
	                            pCancel = True;
	                            tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
	                            ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage),,NStr("en = 'Internet acquiring'; de = 'Internet-Erwerb'; ru = 'Интернет эквайринг'"));
	                            Return;
							EndIf;  
							Object.ReferenceNumber = vRRN;
							Object.AuthorizationCode = vAuthorizationCode;
	                        Object.ExternalCode = vUUID;
	                    EndIf; 
					EndIf;
					If vPaymentMethodArr.BookByCashRegister Then
						If vCashRegisterArr.IsControlledByProgram Then
							If vPaymentMethodArr.PrintCheque And Not ChequeIsPrinted Then
								If Object.Sum <> 0 Or Object.Sum = 0 And Object.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then					// Print cheque at cash register
									StartPrintCheque(vMessage, pCancel);
									If pCancel And Not IsBlankString(vMessage) Then
										tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , vMessage);
										ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
										Return;
									EndIf;	
								Else
									pCancel = True;
									vMessage = NStr("en='Return sum should be entered!';ru='Не введена сумма возврата!';de='Die Rückgabesumme wurde nicht eingegeben!'");
									tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),  ,   ,  , vMessage);
									ShowMessageBox(, vMessage);
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
&AtClient
Procedure AfterWrite(pWriteParameters)
	PrintReport();
	Notify("Document.Return.Write", Object.Ref, ThisObject);
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Save currency attributes
	SavePaymentCurrencyAttributes();
	// Set default cash register
	If Not Object.Posted And Not ValueIsFilled(Object.CashRegister) Then
		If ValueIsFilled(Object.PaymentMethod) Then 
			If tcOnServer.cmGetAttributeByRef(Object.PaymentMethod, "BookByCashRegister") Then
				If CashRegistersList.Count() = 1 Then
					Object.CashRegister = CashRegistersList[0].Value;
					CashRegisterOnChangeAtServer();
				ElsIf CashRegistersList.Count() > 1 Then
					vFOCashRegister = Undefined;
					For Each vCRItem In CashRegistersList Do
						If tcOnServer.cmGetAttributeByRef(vCRItem.Value, "UseForFrontOffice") Then
							vFOCashRegister = vCRItem.Value;
							Break;
						EndIf;
					EndDo;
					Object.CashRegister = ?(ValueIsFilled(vFOCashRegister), vFOCashRegister, CashRegistersList[0].Value);
					If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToViewAllCashRegisters") Then
						CashRegisterOnChangeAtServer();
					ElsIf Not ValueIsFilled(vFOCashRegister) Then
						SetIsCorrectionAppearance();
						AttachIdleHandler("OpenCashRegistersList", 0.1, True);
					Else
						SetIsCorrectionAppearance();
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If Not ValueIsFilled(pCurrentObject.Ref) And ValueIsFilled(NewObjectRef) Then
		pCurrentObject.SetNewObjectRef(NewObjectRef);
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("DocumentRef.ProformaInvoice") Then
		InvoiceOnChangeAtServer(pSelectedValue);
	ElsIf TypeOf(pSelectedValue) = Type("Structure") And pSelectedValue.Property("CreditCardProcessingSystem") Then
		CreditCardProcessingSystem = pSelectedValue.CreditCardProcessingSystem;
		Write(New Structure("WriteMode", DocumentWriteMode.Posting));
	EndIf;
EndProcedure // ChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		If Object.DeletionMark Then
			Notify("Document.Return.SetDeletionMark", Object.Ref, ThisObject);
		EndIf;
		OnCloseAtServer();
	EndIf;
EndProcedure // OnClose

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

#EndRegion

#Region FormHeaderItemsEventHandlers

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
	EndIf;
	If vSetDefaultCashRegister Then
		If SetDefaultCashRegister() Then
			vNotify = New NotifyDescription("AfterCashRegisterChoice", ThisObject);
			CashRegistersList.ShowChooseItem(vNotify, NStr("en='Select cash register please!';ru='Выберите ККМ!';de='Wählen Sie Registrierkasse!'"));
		Else
			CashRegisterOnChangeAtServer();
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
	FillCompanyAndCashRegisterCollapsedRepresentation();
	SendPayerContactsRefresh(False, False, False, True);
EndProcedure // PaymentMethodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsSumOnChange(pItem)
	PaymentSectionsSumOnChangeAtServer();
EndProcedure

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
Procedure PaymentSectionsAfterDeleteRow(pItem)
	// Recalculate return totals
	Object.SumInFolioCurrency = Object.PaymentSections.Total("SumInFolioCurrency");
	Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
	Object.Sum = Object.PaymentSections.Total("Sum");
	Object.VATSum = Object.PaymentSections.Total("VATSum");
EndProcedure // PaymentSectionsAfterDeleteRow

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
Procedure SumOnChange(pItem)
	SumOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsCorrectionChequeOnChange(pItem)
	Items.CorrectionChequeParametersGroup.Visible = IsCorrectionCheque;
	If IsCorrectionCheque Then
		If Object.CorrectionOfIncorrectCheque And ValueIsFilled(Object.Payment) And Not ValueIsFilled(CorrectionDocumentDate) Then
			CorrectionDocumentDate = BegOfDay(tcOnServer.cmGetAttributeByRef(Object.Payment, "Date"));
		EndIf;
	EndIf;
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
Procedure PaymentSectionOnChange(pItem)
	PaymentSectionOnChangeAtServer();
EndProcedure // PaymentSectionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardOnChange(pItem)
	vPMHasChanged = FillBalanceByCard();
	If vPMHasChanged Then
		PaymentMethodOnChange(Items.PaymentMethod);
	EndIf;
EndProcedure // DiscountCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	pStandardProcessing = False;
	If StrLen(pText) > 2 Then
		vChoiceDataUID = DiscountCardAutoCompleteAtServer(pText);
		pChoiceData = GetFromTempStorage(vChoiceDataUID);
		If pChoiceData.Count() = 0 Then
			pChoiceData.Add(pText, NStr("en='--Not found--';ru='--Не найдена--';de='--Nicht gefunden--'"));
		EndIf;
	EndIf;
	Modified = True;
EndProcedure

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
&AtClient
Procedure PayerOnChange(pItem)
	// Fill list of payers credit cards
	FillListOfPayersCreditCards();
	SendPayerContactsRefresh(False, True, False, False);
EndProcedure // PayerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure VATRateOnChange(pItem)
	VATRateOnChangeAtServer();
EndProcedure // VATRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterOnChange(pItem)
	SetIsCorrectionAppearance();
	FillCompanyAndCashRegisterCollapsedRepresentation();
	SendPayerContactsRefresh(False, False, True, False);
EndProcedure // CashRegisterOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SendPayerContactsToOFDOnChange(pItem)
	SendPayerContactsRefresh(False, False, False, False);
EndProcedure // SendPayerContactsToOFDOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentOnChange(pItem)
	If ValueIsFilled(Object.Payment) Then
		CorrectionDocumentDate = BegOfDay(tcOnServer.cmGetAttributeByRef(Object.Payment, "Date"));
		Items.ClearPayment.Enabled = True;
	Else
		Items.ClearPayment.Enabled = False;
	EndIf;
	FillListOfPaymentMethods();
EndProcedure // PaymentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioOnChange(pItem)
	FolioOnChangeAtServer();
EndProcedure // FolioOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CorrectionOfIncorrectChequeOnChange(pItem)
	CorrectionOfIncorrectChequeOnChangeAtServer();
EndProcedure // CorrectionOfIncorrectChequeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsOnChange(pItem)
	FillPrintableChequePositions();
EndProcedure // PaymentSectionsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsVATRateOnChange(pItem)
	PaymentSectionsVATRateOnChangeAtServer();
EndProcedure // PaymentSectionsVATRateOnChange

#EndRegion

#Region FormCommandsEventHandlers

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
											tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
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
									tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
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
							tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , vMessage);
							ShowMessageBox(, vMessage);
						EndIf;
					Else
						vMessage = NStr("en='Payment method settings do not allow posting by cash register!'; ru='Способ оплаты не проводится по ККМ!'; de='Zahlungsmethodeneinstellungen erlauben keine Buchung per Kasse!'");
						tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , vMessage);
						ShowMessageBox(, vMessage);
					EndIf;
				Else
					vMessage = NStr("en='Cash register should be connected to the program!'; ru='ККМ должен быть подключен к программе!'; de='Die Kasse sollte mit dem Programm verbunden sein!'");
					tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , vMessage);
					ShowMessageBox(, vMessage);
				EndIf;
			Else
				vMessage = NStr("en='Payment method should be filled!'; ru='Не указан способ оплаты!'; de='Zahlungsmethode sollte ausgefüllt werden!'");
				tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , vMessage);
				ShowMessageBox(, vMessage);
			EndIf;
		Else
			vMessage = NStr("en='Cash register should be filled!'; ru='Не указан ККМ!'; de='Die Kasse sollte ausgefüllt werden!'");
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , vMessage);
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
	Notify("Document.Return.Write", Object.Ref, ThisObject);
	Close();
EndProcedure // SetDeletionMarkAction

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintReturnForms(pCommand)
	If Modified Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	PrintReport();
	Notify("Document.Return.Write", Object.Ref, ThisObject);
EndProcedure // PrintReturnForms

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearPayment(pCommand)
	ClearPaymentAtServer();
EndProcedure // ClearPayment

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateCardBalance(pCommand)
	If ValueIsFilled(Object.DiscountCard) Then
		fmGetExternalCardBalance(tcOnServer.cmGetAttributeByRef(Object.DiscountCard, "Identifier"));			
	EndIf;
EndProcedure // UpdateCardBalance

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintSlip(pCommand)
	vErrorTitle = NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'");
	
	vMessage = "";
	vCashRegister = Object.CashRegister;
	If Not ValueIsFilled(vCashRegister) Or IsBlankString(Object.SlipText) Then
		Return;
	EndIf;
	
	vCashRegisterArr = tcOnServer.cmGetAtributeAsArray(vCashRegister);
	If Not IsReadyToPrintCheque(vMessage, vCashRegister) Then
		ShowMessageBox(, vMessage, , vErrorTitle);
		Return;
	EndIf;
	
	vSlipTxtArr = tcOnServer.GetTextLinesArray(Object.SlipText);
	vDriver = tcOnClient.cmGetModulTO(vCashRegisterArr);
	If vDriver = Undefined Then
		vMessage = Nstr("en = 'Work with driver this device is not supported'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'; ru = 'Работа с драйвером этого устройства не поддерживается'");
		ShowMessageBox(, vMessage, , vErrorTitle);
		Return;
	EndIf;
	
	vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, vCashRegisterArr);
	vQuestion =  NStr("en = 'Input cash register password please...'; de = 'Input cash register password please...'; ru = 'Пожалуйста введите пароль ККМ...'");
	
	If IsBlankString(vPasswordKKM) Then
		vNotifity = New NotifyDescription("PrintSlipAfterInputCashRegisterPassword", ThisObject, New Structure("Driver,rMessage,pCashRegister,pSlipTextArr", vDriver, vMessage, vCashRegisterArr, vSlipTxtArr));
		OpenForm("CommonForm.tcInputCashRegisterPassword",New Structure("LabelDescription",vQuestion), , , , ,vNotifity);
		Return;
	EndIf;
	
	vDriver.pmPrintSlip(vSlipTxtArr, vCashRegisterArr, vMessage, vPasswordKKM);
	
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(, vMessage, , vErrorTitle);
	EndIf;
EndProcedure // PrintSlip

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowCheque(pCommand)
	OpenForm("Catalog.CashRegisters.Form.tcShowCheque", New Structure("SelDocument", Object.Ref), ThisObject, UUID);
EndProcedure // ShowCheque

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintSlipAfterInputCashRegisterPassword(pValue, pAdditionalParameters) Export
	vDriver = pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.rMessage;
	If pValue = Undefined Then
		Return;
	EndIf;
	
	vDriver.pmPrintSlip(pAdditionalParameters.pSlipTextArr, pAdditionalParameters.pObject, vMessage, pValue.Password);
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(, vMessage, , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf; 
EndProcedure // AfterInputCashRegisterPassword

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
Function HasPaymentCardData()
	Return True;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCashRegisterChoice(pUserChoiceItem, pExtraParams) Export
	If pUserChoiceItem <> Undefined Then
		Object.CashRegister = pUserChoiceItem.Value;
		CashRegisterOnChangeAtServer();
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
Function SetDefaultCashRegister()
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
		vFOCashRegister = Undefined;
		For Each vCRItem In CashRegistersList Do
			If vCRItem.Value.UseForFrontOffice Then
				vFOCashRegister = vCRItem.Value;
				Break;
			EndIf;
		EndDo;
		Object.CashRegister = ?(ValueIsFilled(vFOCashRegister), vFOCashRegister, CashRegistersList.Get(0).Value);
		SetIsCorrectionAppearance();
		If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") And Not ValueIsFilled(vFOCashRegister) Then
			If CashRegistersList.Count() > 1 Then
				If ValueIsFilled(Object.PaymentMethod) Then
					If Object.PaymentMethod.BookByCashRegister Then
						FillCompanyAndCashRegisterCollapsedRepresentation();
						Return True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	FillCompanyAndCashRegisterCollapsedRepresentation();
	Return False;
EndFunction // SetDefaultCashRegister

// -----------------------------------------------------------------------------
&AtServer
Procedure CashRegisterOnChangeAtServer()
	// Is correction appearance
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
	If ValueIsFilled(Object.Payment) And ValueIsFilled(Object.Payment.PaymentMethod) And Object.Payment.PaymentMethod <> Catalogs.PaymentMethods.DepositTransfer Then
		Object.PaymentMethod = Object.Payment.PaymentMethod;
	EndIf;
	If ValueIsFilled(Object.PaymentMethod) Then
		If Items.PaymentMethod.ChoiceList.FindByValue(Object.PaymentMethod) = Undefined Then
			Object.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
		EndIf;
	EndIf;
	If Not ValueIsFilled(Object.PaymentMethod) Then
		If Items.PaymentMethod.ChoiceList.Count() > 0 Then
			Object.PaymentMethod = Items.PaymentMethod.ChoiceList.Get(0).Value;
		EndIf;
	EndIf;
EndProcedure // SetDefaultPaymentMethod

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPaymentMethods()
	vObj = FormAttributeToValue("Object");
	vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios = cmCheckUserPermissions("HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios");
	vRetPMs = New ValueList();
	vRetPMs.LoadValues(vObj.pmGetPaymentMethodsAllowedForReturn());
	vPMs = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser, True, Object.CashRegister);
	vIsResortFee = False;
	For Each vRowPS In Object.PaymentSections Do
		If ValueIsFilled(vRowPS.ChequeService) And vRowPS.ChequeService.IsResortFee Then
			 vIsResortFee = True;
			 Break;
		EndIf;	
	EndDo;
	vThereAreResortFeePMs = False;
	i = 0;
	While i < vRetPMs.Count() Do
		vPM = vRetPMs.Get(i).Value;
		If vPM.IsForResortFee Then
			vThereAreResortFeePMs = True;
			Break;
		EndIf;
		i = i + 1;
	EndDo;
	i = 0;
	While i < vRetPMs.Count() Do
		vPM = vRetPMs.Get(i).Value;
		If vPM = Catalogs.PaymentMethods.DepositTransfer Then
			vRetPMs.Delete(i);
		ElsIf vPM = Catalogs.PaymentMethods.Settlement And Not vHavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios And 
		     (Not ValueIsFilled(Object.AccountingCustomer) Or ValueIsFilled(Object.AccountingCustomer) And Object.AccountingCustomer.IsIndividual) Then
			vRetPMs.Delete(i);
		ElsIf Not vIsResortFee And vPM.IsForResortFee Then
			vRetPMs.Delete(i);	
		ElsIf vIsResortFee And vThereAreResortFeePMs And Not vPM.IsForResortFee Then
			vRetPMs.Delete(i);	
		ElsIf vPMs.FindByValue(vPM) = Undefined Then
			vRetPMs.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	Items.PaymentMethod.ChoiceList.LoadValues(vRetPMs.UnloadValues());
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
			If vPMListItem.Value = Catalogs.PaymentMethods.AdvanceSettlement And 
			  (Not ValueIsFilled(Object.Payment) Or ValueIsFilled(Object.Payment) And Object.Payment.PaymentMethod <> Catalogs.PaymentMethods.AdvanceSettlement) Then
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
			If ValueIsFilled(vCashRegister.Hotel) And vCashRegister.Hotel = Object.Hotel  
			  Or Not ValueIsFilled(vCashRegister.Hotel) Then
				i = i + 1;
			Else
				CashRegistersList.Delete(i);
			EndIf;
		Else
			CashRegistersList.Delete(i);
		EndIf;
	EndDo;
	// Check that current cash register is in the list
	vDoSetDefaultCashRegister = False;
	If ValueIsFilled(Object.CashRegister) Then
		If CashRegistersList.FindByValue(Object.CashRegister) = Undefined Then
			If Object.Posted Then
				CashRegistersList.Add(Object.CashRegister);
			Else
				Object.CashRegister = Undefined;
				SetIsCorrectionAppearance();
				vDoSetDefaultCashRegister = True;
			EndIf;
		EndIf;
	EndIf;
	// Attach list of cash registers to the form item
	Items.CashRegister.ChoiceList.LoadValues(CashRegistersList.UnloadValues());
	// Set default cash register
	If vDoSetDefaultCashRegister Then
		SetDefaultCashRegister();
	EndIf;
EndProcedure // FillListOfCashRegisters

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
			vObj.SetNewObjectRef(Documents.Return.GetRef());
		EndIf;
		NewObjectRef = vObj.GetNewObjectRef();
		If Parameters.Property("Folio") And ValueIsFilled(Parameters.Folio) Then
			vObj.Folio = Parameters.Folio;
		EndIf;
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	
	// Process parameters	
	If Parameters.Property("Basis") And ValueIsFilled(Parameters.Basis) Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // FillDocumentObjectParameters

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
		vQuery = NStr("ru = 'В возврате выбран способ оплаты
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
Procedure SaveDocumentToPendingListAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Write(DocumentWriteMode.Write);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SaveDocumentToPendingListAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveDocumentToOpenQRCodePaymentForm() 
	SaveDocumentToPendingListAtServer();
	If ValueIsFilled(Object.Ref) Then
		OpenForm("CommonForm.tcQRCodePaymentForm", New Structure("SelPayment, SelExternalSystem", Object.Ref, ExternalSystem), ThisObject, UUID, , , New NotifyDescription("AfterCloseQRCodePaymentForm", ThisObject), FormWindowOpeningMode.LockWholeInterface); 
	EndIf;
EndProcedure // SaveDocumentToPendingList

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionsVATRateOnChangeAtServer()
	vCurRow = Items.PaymentSections.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.PaymentSections.FindByID(vCurRow);
		If vCurData <> Undefined Then
			vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
			vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
			// Recalculate payment totals
			Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
			Object.VATSum = Object.PaymentSections.Total("VATSum");
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsVATRateOnChangeAtServer

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
Procedure SaveDocumentToPendingList() 
	SaveDocumentToPendingListAtServer();
EndProcedure // SaveDocumentToPendingList

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GuestLinkRefund(pExternalSystem, pAmount, pExtPaymentRef, rUUID, rMessage)
	If IsBlankString(pExternalSystem.HttpServer) Then
		Return True;
	EndIf;
	
	Try
		vDefaultResourceAddress = "/hs/api/refund";
		
		vHttp = StrReplace(StrReplace(pExternalSystem.HttpServer, "https://", ""), "http://", "");
		vHTTPServer = Left(vHttp, StrFind(vHttp, "/") - 1);
		vResourceAddress = Right(vHttp, StrLen(vHttp) - StrFind(vHttp, "/") + 1);
		
		If StrFind(vResourceAddress, vDefaultResourceAddress) = 0 Then
			vResourceAddress = vResourceAddress + vDefaultResourceAddress;
		EndIf;
		
		vRequestParam = New Map;
		vRequestParam.Insert("orderId", pExtPaymentRef);
		vRequestParam.Insert("amount", pAmount);
		
		vJSONWriter =New JSONWriter;
		vJSONWriter.SetString();
		WriteJSON(vJSONWriter, vRequestParam);
		
		vRequestJson = vJSONWriter.Close();          
		
		vRequestHeaders = New Map();
		vRequestHeaders.Insert("token",pExternalSystem.InteractionID);
		vResponseStruct = Catalogs.ExternalSystemInteractions.SendHTTPRequest(pExternalSystem, vRequestHeaders, vResourceAddress, "POST", , vRequestJson, "JSON", True, , , , , , vHTTPServer);
		If vResponseStruct.StatusCode <> 200 Then
			Try
				vResponse = Catalogs.DataConvertationRules.JSONtoMap(vResponseStruct.Body);
				rMessage = vResponse["errorDescription"];
			Except
				rMessage = vResponseStruct.Body;
			EndTry;
			Return False;
		EndIf;
					
		vResponse = Catalogs.DataConvertationRules.JSONtoMap(vResponseStruct.Body);
		If vResponse = Undefined Then
			rMessage = vResponseStruct.Body;
			Return False;
		EndIf;
		
		rUUID = vResponse["refundId"];
	Except
		vError = ErrorInfo();
		rMessage = ErrorProcessing.BriefErrorDescription(vError);
		tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , ErrorProcessing.DetailErrorDescription(vError));
		Return False;
	EndTry;
	
	Return True;
EndFunction // GuestLinkRefund

// -----------------------------------------------------------------------------
&AtServerNoContext
Function InternetAcquiringRefund(pAmount, pExtPaymentRef, pHotel, pUUID = "", pMessage, pRRN = "", pAuthorizationCode = "")
	vExtInt = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsGuestlink(pHotel);
	If ValueIsFilled(vExtInt) And vExtInt.IntegrationType = Enums.Integrations.Guestlink Then
		Return GuestLinkRefund(vExtInt, pAmount, pExtPaymentRef, pUUID, pMessage);
	EndIf;
	
	If vExtInt = Undefined Then
		Return True;
	EndIf; 
	
	vLogin = EncodeString(vExtInt.Login, StringEncodingMethod.URLEncoding);
	vPwd = EncodeString(vExtInt.Password, StringEncodingMethod.URLEncoding);
	
	If Not IsBlankString(vLogin) And Not IsBlankString(vPwd) And Not IsBlankString(vExtInt.HttpServer) Then
		Try
			If vExtInt.AcquiringBank = Enums.AcquiringBank.Sberbank Or vExtInt.AcquiringBank = Enums.AcquiringBank.SberbankEPay Then
				
				vHTTPHeader = New Map;
				
				If vExtInt.AcquiringBank = Enums.AcquiringBank.SberbankEPay Then   
					vLogin = TrimAll(vExtInt.Login);
					vPwd = TrimAll(vExtInt.Password);
					
					vRequestStatus = "/ecomm/gw/partner/api/v1/getOrderStatusExtended.do";
					vRequestReturn = "/ecomm/gw/partner/api/v1/refund.do";
				Else	
					vRequestStatus = "/payment/rest/getOrderStatus.do";
					vRequestReturn = "/payment/rest/refund.do";
				EndIf;  
				
				vRequestParam =  New Structure;
				vRequestParam.Insert("orderId",  pExtPaymentRef);
				vRequestParam.Insert("userName", vLogin);
				vRequestParam.Insert("password", vPwd);
				
				If vExtInt.AcquiringBank = Enums.AcquiringBank.SberbankEPay Then  
					vJson = Catalogs.DataConvertationRules.MapToJSON(vRequestParam);
					vResponseStatus	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(vExtInt, vHTTPHeader, vRequestStatus, "POST", , vJson, "JSON");	
				Else	     
					vHTTPHeader.Insert("Content-Type", "application/x-www-form-urlencoded");
					vResponseStatus	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(vExtInt, vHTTPHeader, vRequestStatus, "POST", , , , , vRequestParam);
				EndIf;
				
				// 1. Check order status
				If vResponseStatus.StatusCode = 200 Then
					vResStatus = Catalogs.DataConvertationRules.JSONtoStructure(vResponseStatus.Body);
					If vResStatus.Property("errorCode") And Not vResStatus.errorCode = "0" Then
						pMessage = "Error code: " + vResStatus.errorCode + Chars.LF + "Error: " + vResStatus.errorMessage;  
						Return False;
					EndIf;
					If vExtInt.AcquiringBank = Enums.AcquiringBank.SberbankEPay Then
						If vResStatus.Property("paymentAmountInfo") Then
							vDepositedAmount = vResStatus.paymentAmountInfo.depositedAmount / 100;
						Else
							vDepositedAmount = 0;
						EndIf;
					Else	
						vDepositedAmount = vResStatus.depositAmount / 100;
					EndIf;
					If vDepositedAmount < pAmount Then
						pMessage = StrTemplate(Nstr("en = 'You are trying to return %2 from the available %1'; 
													|de = 'Sie versuchen, %2 von der verfügbaren %1 zurückzugeben'; 
													|ru = 'Пытаетесь вернуть %2 из доступных %1'"), vDepositedAmount, pAmount);
						Return False;	
					EndIf;
				Else
					If IsBlankString(vResponseStatus.Error) Then
						pMessage = "StatusCode: " + vResponseStatus.StatusCode;  
					Else
						pMessage = vResponseStatus.Error;
					EndIf; 
					Return False;
				EndIf; 
				
				// 2. Do return    
				If vExtInt.AcquiringBank = Enums.AcquiringBank.SberbankEPay Then
					vRequestParam.Insert("amount", pAmount * 100);
				Else	
					vRequestParam.Insert("amount", Format(pAmount * 100, "NG=0"));       
				EndIf;
				If vExtInt.AcquiringBank = Enums.AcquiringBank.SberbankEPay Then   
					vJson = Catalogs.DataConvertationRules.MapToJSON(vRequestParam);
					vResponseReturn	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(vExtInt, vHTTPHeader, vRequestReturn, "POST", , vJson, "JSON");
				Else  
					vResponseReturn	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(vExtInt, vHTTPHeader, vRequestReturn, "POST", , , , , vRequestParam);
				EndIf;
				
				If vResponseReturn.StatusCode = 200 Then
					vRetBody = Catalogs.DataConvertationRules.JSONtoStructure(vResponseReturn.Body);
					If Not vRetBody.errorCode = "0" And vRetBody.Property("errorMessage") Then
						pMessage = vRetBody.errorMessage;
						Return False;
					EndIf; 
					pUUID = String(New UUID());
				EndIf; 
			ElsIf vExtInt.AcquiringBank = Enums.AcquiringBank.Gazprombank Then 
				vRequestReturn = "/merchantapi/refund";
				
				vRequestParam =  New Map;
				vRequestParam.Insert("trx_id", pExtPaymentRef);
				vRequestParam.Insert("p.rrn", pRRN);
				vRequestParam.Insert("amount", Format(pAmount * 100, "NG=0"));
				
				vResponseReturn	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(vExtInt, ,vRequestReturn , "GET", , , , True, vRequestParam);
				If vResponseReturn.StatusCode = 200 Then  
					// XML Read
					vReadXML = New XMLReader;
					vReadXML.SetString(vResponseReturn.Body);
					
					vDOMBuilder = New DOMBuilder;
					vDOMDocument = vDOMBuilder.Read(vReadXML);  
					vResp = vDOMDocument.GetElementByTagName("code");
					If vResp.Count() > 0 Then    
						vCode = TrimAll(vResp.Item(0).TextContent);
						If vCode = "1" Then  
							// Successfully
							vRefundParam = vDOMDocument.GetElementByTagName("Refund");	
							If vRefundParam.Count() > 0 Then  
								// Get RRN
								vRRNParam = vDOMDocument.GetElementByTagName("rrn");	
								If vRRNParam.Count() > 0 Then 
									pRRN = TrimAll(vRRNParam.Item(0).TextContent);							
								EndIf; 
								// Get auth code
								vAuthCodeParam = vDOMDocument.GetElementByTagName("authcode");	
								If vAuthCodeParam.Count() > 0 Then 
									pAuthorizationCode = TrimAll(vAuthCodeParam.Item(0).TextContent);							
								EndIf;	
							EndIf;	
						ElsIf vCode = "2" Or vCode = "3" Then	 
							vErrorParam = vDOMDocument.GetElementByTagName("desc");	
							If vErrorParam.Count() > 0 Then 
								pMessage = TrimAll(vErrorParam.Item(0).TextContent);							
							EndIf;	
							Return False;
						EndIf;	
					Else
						pMessage = NStr("en = 'Processing system response parsing error'; de = 'Fehler beim Analysieren der Systemantwort'; ru = 'Ошибка разбора ответа процессинговой системы'");
						Return False;	
					EndIf;	
					pUUID = String(New UUID());
				Else
					pMessage = vResponseReturn.Error;
					Return False;	
				EndIf; 
			Else
				pMessage = StrTemplate(Nstr("en = 'You need to fill in the acquiring bank for integration %1'; 
											|de = 'Sie müssen die erwerbende Bank ausfüllen Zur Integration %1'; 
											|ru = 'Для интеграции %1 необходимо заполнить банк-эквайер'"), TrimAll(vExtInt.Description));
				Return False;	
			EndIf;	
		Except
			vErr = ErrorInfo();
			pMessage = BriefErrorDescription(vErr);
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , DetailErrorDescription(vErr));
			Return False;
		EndTry;
	EndIf; 
	Return True;
EndFunction //  InternetAcquiringRefund() 

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
	// Check that return is made based on payment
	If Not ValueIsFilled(vObj.Payment) Then
		If Not cmCheckUserPermissions("HavePermissionToReturnBasedOnFolio") Then
			rMessage = "ru = 'Есть права только на оформление возврата на основании предыдущего платежа!'; 
			           |en = 'You have rights to return money based on previous payment only!';
					   |de = 'You have rights to return money based on previous payment only!'";
			vUM = New UserMessage();
			vUM.SetData(vObj);
			vUM.Field = "Payment";
			vUM.Text = NStr(rMessage);
			vUM.Message();
			Return False;
		EndIf;
	EndIf;
	// Check that payment methos is allowed for the current folio
	If vObj.PaymentMethod.IsForExtraServiceFolioOnly And Not IsBlankString(vObj.Hotel.AdditionalServicesFolioCondition) And 
	   StrFind(Upper(TrimAll(vObj.Folio.Description)), Upper(TrimAll(vObj.Hotel.AdditionalServicesFolioCondition))) = 0 Then
		rMessage = NStr("en='Payment is allowed for extra services folio only!';
		                |ru='Оплата выбранным способом оплаты возможна только по лицевому счету доп. услуг!';
						|de='Die Bezahlung mit gewählter Zahlungsmethode ist nur nach dem Personenkonto zusätzlicher Dienstleistungen möglich!'");
		vUM = New UserMessage();
		vUM.SetData(vObj);
		vUM.Field = "PaymentMethod";
		vUM.Text = NStr(rMessage);
		vUM.Message();
		Return False;
	EndIf;
	// Check user rights to return cash directly from the cash box
	If ValueIsFilled(vObj.PaymentMethod) Then
		If vObj.PaymentMethod.IsByCash Then
			vHavePermissionToReturnCashDirectlyFromCashBox = cmCheckUserPermissions("HavePermissionToReturnCashDirectlyFromCashBox");
			If ValueIsFilled(vObj.CashRegister) Then
				If vObj.CashRegister.CashReturnDirectlyFromCashBoxIsAllowed Then
					vHavePermissionToReturnCashDirectlyFromCashBox = True;
				EndIf;
			EndIf;
			If Not vHavePermissionToReturnCashDirectlyFromCashBox Then
				If Not vObj.PaymentMethod.IsForReturnOnly Or vObj.PaymentMethod.PrintCheque Then
					rMessage = "ru = 'Нет прав на возврат наличных непосредственно из вашего денежного ящика. Возврат должен быть оформлен из главной кассы бухгалтерии!'; 
					           |en = 'You do not have rights to return cash directly from your cash box. You can return money from the accounting cash office only!';
							   |de = 'You do not have rights to return cash directly from your cash box. You can return money from the accounting cash office only!'";
					vUM = New UserMessage();
					vUM.SetData(vObj);
					vUM.Field = "PaymentMethod";
					vUM.Text = NStr(rMessage);
					vUM.Message();
					Return False;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Check payment company
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
			vUM.Field = "PaymentMethod";
			vUM.Text = NStr(rMessage);
			vUM.Message();
			Return False;
		EndTry;
	EndIf;
	// Check correction
	If IsCorrectionCheque Then
		If Not ValueIsFilled(CorrectionType) Then
			pCancel = True;
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
				pCancel = True;
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
	// OK
	Return True;
EndFunction // CheckDocumentAttributesAtServer

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
EndFunction // CheckCreditCardsProcessingSystem	  

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
EndFunction

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
		                  |en='Input cash register password please...'");
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
					ChequeIsPrinted = vDriver.pmPrintNonFiscalCheque(-Object.Sum, -Object.VATSum, vObject, vChequeTemplate, rMessage, vPasswordKKM);
				Else
					rMessage = NStr("en='Non-fiscal cheque template is not filled for payment method!'; ru='У способа оплаты не заполнен шаблон нефискального чека!'; de='Zahlungsmethode hat eine leer Vorlage für die nonfiscal Kassenbon!'");
					ChequeIsPrinted = False;
				EndIf;
			Else
				ChequeIsPrinted = vDriver.pmPrintCheque(-Object.Sum, -Object.VATSum, vObject, ?(ValueIsFilled(vObject.Ref), vObject.Ref, NewObjectRef), rMessage, vPasswordKKM, , IsCorrectionCheque, CorrectionType, CorrectionDescription, CorrectionDocumentNumber, CorrectionDocumentDate, Object.SendPayerContactsToOFD, Object.EmailToSendToOFD, Object.PhoneToSendToOFD);
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
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintReport()
	vPrintForm = PredefinedValue("Catalog.ObjectPrintingForms.ReturnFormsSet");
	If tcOnServer.cmGetAttributeByRef(vPrintForm, "IsActive") Then
		vReportRef = tcOnServer.cmGetAttributeByRef(vPrintForm, "Report");
		If ValueIsFilled(vReportRef) Then
			vIsExternalReport = tcOnServer.cmGetAttributeByRef(vReportRef, "IsExternal");
			If vIsExternalReport Then
				vExternalReport = tcOnServer.cmGetAttributeByRef(vReportRef, "Report");
				vURL = GetURL(vExternalReport, "ExternalProcessingStorage"); 
				vName = ConnectExternalReport(vURL, "ExternalReportForm");
				vParams = New Structure("Document, ObjectPrintingForm", Object.Ref, vPrintForm);
				OpenForm("ExternalReport." + vName + ".Form.tcReportForm", vParams);
			Else
				tcCommonFunctionOnClientServer.TextMessage("Wrong return print form settings!");
			EndIf;
		Else
			vParameters = New Structure();
			vParameters.Insert("Document", Object.Ref);
			vParameters.Insert("SelObjectPrintForm", vPrintForm);
			OpenForm("Report.PrintReturnForms.Form.tcReportForm", vParameters, ThisObject, UniqueKey);
		EndIf;
	EndIf;
EndProcedure // PrintReport	

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenCashRegistersList() 
	vNotify = New NotifyDescription("AfterCashRegisterChoice", ThisObject, New Structure("CheckInvoices", True));
	CashRegistersList.ShowChooseItem(vNotify, NStr("en='Select cash register please!';ru='Выберите ККМ!';de='Wählen Sie Registrierkasse!'"));
EndProcedure // OpenProformaInvoicesList

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
				ChequeIsPrinted = vDriver.pmPrintNonFiscalCheque(-Object.Sum, -Object.VATSum, vObject, vChequeTemplate, vMessage, pValue.Password);
			Else
				vMessage = NStr("en='Non-fiscal cheque template is not filled for payment method!'; ru='У способа оплаты не заполнен шаблон нефискального чека!'; de='Zahlungsmethode hat eine leer Vorlage für die nonfiscal Kassenbon!'");
				ChequeIsPrinted = False;
			EndIf;
		Else
			ChequeIsPrinted = vDriver.pmPrintCheque(-Object.Sum, -Object.VATSum, vObject, NewObjectRef, vMessage, pValue.Password, , IsCorrectionCheque, CorrectionType, CorrectionDescription, CorrectionDocumentNumber, CorrectionDocumentDate, Object.SendPayerContactsToOFD, Object.EmailToSendToOFD, Object.PhoneToSendToOFD);
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
			Return vDriver.pmAuthorizePayment(-Object.Sum, -Object.VATSum, Object, rMessage, ArrPaymentTerminal);
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
EndProcedure // SetNewObjectRefAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure WriteAndCloseFormAfterChequeBeingPrinted() 
	If ChequeIsPrinted Then
		DetachIdleHandler("WriteAndCloseFormAfterChequeBeingPrinted");
		WriteAndCloseForm();
	EndIf;
EndProcedure // WriteAndCloseFormAfterChequeBeingPrinted

// -----------------------------------------------------------------------------
&AtClient
Procedure WriteAndCloseForm() 
	If Write(New Structure("WriteMode, PostingMode", PredefinedValue("DocumentWriteMode.Posting"), PredefinedValue("DocumentPostingMode.Regular"))) Then
		Close();
	EndIf;
EndProcedure // WriteAndCloseForm

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
			vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
			vCurData.SumInFolioCurrency = Round(cmConvertCurrencies(vCurData.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, 
															       Object.FolioCurrency, Object.FolioCurrencyExchangeRate, 
															       Object.ExchangeRateDate, Object.Hotel), 2);
			vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
			// Recalculate payment totals
			Object.SumInFolioCurrency = Object.PaymentSections.Total("SumInFolioCurrency");
			Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
			Object.Sum = Object.PaymentSections.Total("Sum");
			Object.VATSum = Object.PaymentSections.Total("VATSum");
		EndIf;
	EndIf;
EndProcedure

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
					vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
					vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
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
					vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
					vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
					// Recalculate payment totals
					Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
					Object.VATSum = Object.PaymentSections.Total("VATSum");
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsPaymentSectionOnChangeAtServer

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
			vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
			vCurData.SumInFolioCurrency = Round(cmConvertCurrencies(vCurData.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.FolioCurrency, Object.FolioCurrencyExchangeRate,	Object.ExchangeRateDate, Object.Hotel), 2);
			vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
			// Recalculate return totals
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
			vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
			vCurData.SumInFolioCurrency = Round(cmConvertCurrencies(vCurData.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, Object.FolioCurrency, Object.FolioCurrencyExchangeRate,	Object.ExchangeRateDate, Object.Hotel), 2);
			vCurData.VATSumInFolioCurrency = cmCalculateVATSum(vCurData.VATRate, vCurData.SumInFolioCurrency, ?(ValueIsFilled(Object.Payment), Object.Payment.Date, Object.Date));
			// Recalculate return totals
			Object.SumInFolioCurrency = Object.PaymentSections.Total("SumInFolioCurrency");
			Object.VATSumInFolioCurrency = Object.PaymentSections.Total("VATSumInFolioCurrency");
			Object.Sum = Object.PaymentSections.Total("Sum");
			Object.VATSum = Object.PaymentSections.Total("VATSum");
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsChequeServiceQuantityOnChangeAtServer

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
Procedure SumOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	vObj.VATSum = cmCalculateVATSum(vObj.VATRate, vObj.Sum, ?(ValueIsFilled(vObj.Payment), vObj.Payment.Date, vObj.Date));
	vObj.SumInFolioCurrency = Round(cmConvertCurrencies(vObj.Sum, vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
	vObj.VATSumInFolioCurrency = cmCalculateVATSum(vObj.VATRate, vObj.SumInFolioCurrency, ?(ValueIsFilled(vObj.Payment), vObj.Payment.Date, vObj.Date));
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
				vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, ?(ValueIsFilled(vObj.Payment), vObj.Payment.Date, vObj.Date));
				vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vObj.PaymentCurrency, vObj.PaymentCurrencyExchangeRate, vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
				vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, ?(ValueIsFilled(vObj.Payment), vObj.Payment.Date, vObj.Date));
				If vPSRow.ChequeServiceQuantity <> 0 Then
					vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
				EndIf;
			EndDo;
			vObj.pmCalculateTotalsByPaymentSections();
		EndIf;
	EndIf;
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // SumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure InvoiceOnChangeAtServer(pInvoice)
	Object.Invoice = pInvoice;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDeletionMarkAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Read();
	vObj.SetDeletionMark(True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SetDeletionMarkAtServer

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
	If ValueIsFilled(Object.PaymentMethod) And Object.PaymentMethod.IsByBonuses Then
		Items.DiscountCard.Title = Nstr("en = 'Bonus card'; de = 'Bonuskarte'; ru = 'Бонусная карта'");
	Else
		Items.DiscountCard.Title = Nstr("en = 'Gift card'; de = 'Geschenkkarte'; ru = 'Сертификат'");
	EndIf;	
		
	If ValueIsFilled(vCard) Then
		vArrFD = New Array;
		If vCard.LoyaltyType = Enums.LoyaltyType.Bonuses Then
			vText = NStr("en = 'Bonuses available:'; de = 'Verfügbare Boni:'; ru = 'Доступно бонусов:'");
			vDataCard = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCard, Object.Date, Object.ExchangeRateDate, Object.Hotel); 
			vBalance = cmRoundDown(vDataCard.BalanceAmount/vDataCard.BonusRate, 2);
			// Get formating string folio description
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", vText, tcCommonFunctionOnClientServer.FontConstructor( , 9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(vBalance, "NFD=2; NDS=.; NZ=0.00; NG=0"), tcCommonFunctionOnClientServer.FontConstructor( , 11, True), tcCommonFunctionOnClientServer.ColorConstructor(0, 128, 0)));
		ElsIf vCard.LoyaltyType = Enums.LoyaltyType.Certificate Then
			vDataCard = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCard, Object.Date, Object.ExchangeRateDate, Object.Hotel);
			vTextBalance = NStr("en = 'Balance: '; de = 'Kontostand: '; ru = 'Остаток: '");
			// Get formating string folio description
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", vTextBalance, tcCommonFunctionOnClientServer.FontConstructor( , 9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(vDataCard.BalanceAmount, "NFD=2; NDS=.; NZ=0.00; NG=0"), tcCommonFunctionOnClientServer.FontConstructor(, 11, True), tcCommonFunctionOnClientServer.ColorConstructor(0, 128, 0)));
		EndIf;
		If ValueIsFilled(vCard.ValidTo) Then
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", NStr("en=' till '; ru=' до '; de=' bis '") + Format(vCard.ValidTo, "DF=dd.MM.yyyy"), tcCommonFunctionOnClientServer.FontConstructor( , 9), ?(vCard.ValidTo < CurrentSessionDate(), WebColors.Red, Undefined)));
		EndIf;
		If vCard.IsBlocked Then
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", NStr("en=' is blocked'; ru=' заблокирована'; de=' ist blockiert'"), tcCommonFunctionOnClientServer.FontConstructor( , 9), WebColors.Red));
		EndIf;
		If vArrFD.Count() > 0 Then
			Items.DecorationBalance.Title = tcOnServer.cmGenerateFormattedString(vArrFD);
		EndIf;
		// Change payment method
		If Not pServerMode Then
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
Function GetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False)
	vDiscountCardRef = Catalogs.DiscountCards.EmptyRef();
	// Try to find discount card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref AS Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	(NOT DiscountCards.DeletionMark
	|			OR &qSearchMarkedForDeletion)
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
					vPMHasChanged = FillBalanceByCard();
					If vPMHasChanged Then
						PaymentMethodOnChange(Items.PaymentMethod);
					EndIf;
				Else
					If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt") Then
						ShowMessageBox(, NStr("en='This card does not belong to the guest! You may clear guest field and try to slip card again.';ru='Чужая карта! Можете очистить поле гостя и заново прокатать карту.';de='Fremde Karte! Sie können das Gastfeld löschen und die Karte neu durchziehen.'"));
					Else
						Object.DiscountCard = vDiscountCard;
						vPMHasChanged = FillBalanceByCard();
						If vPMHasChanged Then
							PaymentMethodOnChange(Items.PaymentMethod);
						EndIf;
					EndIf;
				EndIf;
			ElsIf IsNew Then
				Object.DiscountCard = vDiscountCard;
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
Function DiscountCardAutoCompleteAtServer(pText)
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
	           	|			OR DiscountCards.ValidTo = DATETIME(1, 1, 1))";
	vQry.SetParameter("qIdentifier", "%"+pText+"%");
	vQry.SetParameter("qRequestDate", CurrentSessionDate());
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
	|			OR DiscountCards.ValidTo = DATETIME(1, 1, 1))";

	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		vChoiceDataList.Add(vQryResult.Ref, vQryResult.Description + " (Tel." + vQryResult.Identifier + ")");
	EndDo;
	
	Return PutToTempStorage(vChoiceDataList);
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure VATRateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // VATRateOnChangeAtServer

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
Procedure ClearPaymentAtServer()
	If ValueIsFilled(Object.Payment) Then
		Object.Payment = Undefined;
		FillListOfPaymentMethods();
		Items.ClearPayment.Enabled = False;
	EndIf;
EndProcedure // ClearPaymentAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FolioOnChangeAtServer()
	If ValueIsFilled(Object.Folio) Then
		Object.FolioCurrency = Object.Folio.FolioCurrency;
		Object.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.FolioCurrency, Object.ExchangeRateDate);
		Object.Company = Object.Folio.Company;
		Object.AccountingCustomer = ?(ValueIsFilled(Object.Folio.Customer), Object.Folio.Customer, Object.Hotel.IndividualsCustomer);
		Object.AccountingContract = ?(ValueIsFilled(Object.Folio.Contract), Object.Folio.Contract, ?(Object.AccountingCustomer = Object.Hotel.IndividualsCustomer, Object.Hotel.IndividualsContract, Catalogs.Contracts.EmptyRef()));
		Object.GuestGroup = Object.Folio.GuestGroup;
	EndIf;
EndProcedure // FolioOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CorrectionOfIncorrectChequeOnChangeAtServer()
	If Object.CorrectionOfIncorrectCheque And ValueIsFilled(Object.Payment) And Not ValueIsFilled(CorrectionDocumentDate) Then
		CorrectionDocumentDate = BegOfDay(Object.Payment.Date);
	EndIf;
	FillListOfPaymentMethods();
	Items.Payment1.Visible = Not Object.CorrectionOfIncorrectCheque;
	Items.ClearPayment.Visible = Not Object.CorrectionOfIncorrectCheque;
	Items.Payment.Visible = Object.CorrectionOfIncorrectCheque;
EndProcedure // CorrectionOfIncorrectChequeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function fmReturnCreditCardExternalPayment()
	vDP = ExternalSystem.DataProcessor;
	
	If Not ValueIsFilled(vDP) Then
		Raise Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
	EndIf;
	
	vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
	
	If vDPO = Undefined Then
		Raise Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");			
	EndIf;
	
	vMessage = "";	
	If Not vDPO.ReturnExternalPayment(Object, vMessage) Then
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

	vResponse = vDPO.GetCardBalance(TrimAll(pIdentifier), Object, ExternalCardBalance, ExternalCardTotalBalance);

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
Function fmReturnExternalPayment()
	vDP = ExternalSystem.DataProcessor;
	
	If Not ValueIsFilled(vDP) Then
		Raise Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
	EndIf;
	
	vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
	If vDPO = Undefined Then
		Raise Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");			
	EndIf;
	
	vResponse = vDPO.ReturnExternalPayment(Object, NewObjectRef);
	
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
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", NStr("en = 'Can be spent:'; de = 'können ausgeben:'; ru = 'Можно потратить:'"), tcCommonFunctionOnClientServer.FontConstructor( , 9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(ExternalCardBalance, "NFD=2; NDS=.; NZ=0.00; NG=0"), tcCommonFunctionOnClientServer.FontConstructor( , 11, True), tcCommonFunctionOnClientServer.ColorConstructor(0, 128, 0)));
			If ExternalCardTotalBalance > 0 Then
				vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", Chars.LF));
				vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", NStr("en = 'Total bonuses:'; de = 'Gesamtboni:'; ru = 'Всего бонусов:'"), tcCommonFunctionOnClientServer.FontConstructor( , 9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(ExternalCardTotalBalance, "NFD=2; NDS=.; NZ=0.00; NG=0"), tcCommonFunctionOnClientServer.FontConstructor( , 11, True), tcCommonFunctionOnClientServer.ColorConstructor(0, 128, 0)));
			EndIf;
		ElsIf vCard.LoyaltyType = Enums.LoyaltyType.Certificate Then
			vTextBalance = NStr("en = 'Balance: '; de = 'Kontostand: '; ru = 'Остаток: '");
			// Get formating string folio description
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", vTextBalance, tcCommonFunctionOnClientServer.FontConstructor( , 9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(ExternalCardBalance, "NFD=2; NDS=.; NZ=0.00; NG=0"), tcCommonFunctionOnClientServer.FontConstructor( , 11, True), tcCommonFunctionOnClientServer.ColorConstructor(0, 128, 0)));
		EndIf;
	EndIf;
	If vArrFD.Count() > 0 Then
		Items.DecorationBalance.Title = tcOnServer.cmGenerateFormattedString(vArrFD);
	Else
		Items.DecorationBalance.Title = "";	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDiscountCard()
	vPaymentMethod = Object.PaymentMethod;
	If ValueIsFilled(vPaymentMethod) Then
		If vPaymentMethod.IsByBonuses Or vPaymentMethod.IsByGiftCertificate Then			
			If Not Object.Posted And ValueIsFilled(Object.Payment) And TypeOf(Object.Payment) <> Type("DocumentRef.DepositTransfer") Then
				Object.DiscountCard = Object.Payment.DiscountCard; 	
			EndIf;
			
			If ValueIsFilled(Object.DiscountCard) Then
				If ValueIsFilled(ExternalSystem) Then
					// 1. Get card and balance;
					fmGetExternalCardBalance(Object.DiscountCard.Identifier);
				EndIf;	
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillDiscountCard

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

#EndRegion
