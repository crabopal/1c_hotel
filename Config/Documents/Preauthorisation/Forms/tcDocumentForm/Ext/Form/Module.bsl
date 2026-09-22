 
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	IsNew = Object.Ref.IsEmpty();
	PaymentIsAuthorized = False;
	CancellationIsAuthorized = False;
	
	SavePaymentCurrencyAttributes();
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
	// Set default cash register
	If IsNew Then
		If tcOnServer.cmCheckUserPermissionsAtServer("DoNotFillDefaultPaymentMethodInPayments") Then
			If Object.PaymentMethod <> PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
				Object.PaymentMethod = Undefined;
			EndIf;
		EndIf;
		vResult = SetDefaultCashRegister();
		If vResult Then
			AttachIdleHandler("Attachable_OpenCashRegistersList", 0.1, True);
		Else
			If CheckInvoices() Then
				AttachIdleHandler("OpenProformaInvoicesList", 0.1, True);
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  OnOpen

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
		ElsIf pParameter.ModeAfterCheck = "CancelOperation" Then
			CancelOperation(Commands.CancelOperation);
		EndIf;
	ElsIf pEventName = "CreditCard.Write" And pSource = Items.CreditCard And ValueIsFilled(pParameter) And tcOnServer.cmGetAttributeByRef(pParameter, "CardOwner") = Object.Payer Then
		If Items.CreditCard.ChoiceList.FindByValue(pParameter) = Undefined Then
			Items.CreditCard.ChoiceList.Add(pParameter);
		EndIf;
		Object.CreditCard = pParameter;
		CreditCardOnChange(Items.CreditCard);
	EndIf;
EndProcedure //  NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If pCancel Then Return EndIf;
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
		vMessage = "";
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
			// Actions for not posted document
			If Not Object.Posted Then
				If ValueIsFilled(Object.PaymentMethod) Then
					If vPaymentMethodArr.IsByCreditCard And Not vPaymentMethodArr.ExternalBankTerminalIsUsed Then
						// If payment was earlier authorized manually (reference number is filled) or automatically then skip this step
						If IsBlankString(Object.ReferenceNumber) And Not PaymentIsAuthorized Then
							If CheckCreditCardsProcessingSystem() Then
								If Not Preauthorize(vMessage) Then
									pCancel = True;
									tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
									ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
									Return;
								Else
									PaymentIsAuthorized = True;
									Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Authorised");
								EndIf;
							Else
							    Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Authorised");
							EndIf;
						Else
						    Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Authorised");
						EndIf;
					Else
					    Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Authorised");
					EndIf;
				EndIf;
			EndIf;	
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Document.Preauthorisation.Write", Object.Ref, ThisObject);
EndProcedure //  AfterWrite

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
		EndIf;
	EndIf;
	If vSetDefaultCashRegister Then
		If SetDefaultCashRegister() Then
			vNotify = New NotifyDescription("Attachable_AfterCashRegisterChoice", ThisObject, New Structure("CheckInvoices", False));
			CashRegistersList.ShowChooseItem(vNotify, NStr("en='Select cash register please!';ru='Выберите ККМ!';de='Wählen Sie Registrierkasse!'"));
		Else
			CashRegisterOnChangeAtServer();
		EndIf;
	EndIf;
	ProcessCreditCardPaymentMethodChoice();
EndProcedure //  PaymentMethodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InvoiceStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenProformaInvoicesList();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SumOnChange(Item)
	CalculateSums();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentCurrencyOnChange(Item)
	PaymentCurrencyOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeRateDateOnChange(pItem)
	ExchangeRateDateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardOpening(pItem, pStandardProcessing)
	If Not ValueIsFilled(Object.CreditCard) Then
		pStandardProcessing = False;
	 	OpenForm("Catalog.CreditCards.ObjectForm", New Structure("FillingValues", New Structure("CardOwner, CardNumber", Object.Payer, Items.CreditCard.EditText)), pItem);
	EndIf;
EndProcedure //  CreditCardOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardOnChange(pItem)
	If ValueIsFilled(Object.CreditCard) Then
		Object.CardType = tcOnServer.cmGetAttributeByRef(Object.CreditCard, "CardType");
	EndIf;
EndProcedure //  CreditCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PayerOnChange(pItem)
	FillListOfPayersCreditCards();
EndProcedure //  PayerOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CancelOperation(pCommand)
	vMessage = ""; 
	
	ClearMessages();
	
	vCashRegisterArr = tcOnServer.cmGetAtributeAsArray(Object.CashRegister);
	vPaymentMethodArr = tcOnServer.cmGetAtributeAsArray(Object.PaymentMethod);
	
	If Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Cancelled") Then
		ShowMessageBox(, NStr("en='Preauthorisation is already cancelled';ru='Операция уже отменена!';de='Die Operation ist bereits abgebrochen!'"));
		Return;
	EndIf;   
	
	IsCancelOperation = False;
	If CreditCardProcessingSystem.IsEmpty() And vPaymentMethodArr.IsByCreditCard Then
		vTempArr = GetCreditCardProcessingSystem();
		If vTempArr.Count() > 1 Then
			pCancel = True; 
			IsCancelOperation = True;
			vParams = New Structure("Arr", vTempArr);
			OpenForm("CommonForm.tcCreditCardProcessingSystemChoiceForm", vParams, ThisObject, UUID);
			Return;
		ElsIf vTempArr.Count() = 1 Then
			CreditCardProcessingSystem = vTempArr[0];
		EndIf; 
	EndIf;

	// Check user PIN if necessary
	If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
		OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "CancelOperation"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		pCancel = True;
		Return;
	EndIf;
	EmployeePINCodeChecked = False;
	// Actions for the first document write
	If Object.Posted And Not Object.DeletionMark Then
		If ValueIsFilled(Object.PaymentMethod) Then
			// Annulate operation by the credit card processing system
			If vPaymentMethodArr.IsByCreditCard And Not vPaymentMethodArr.ExternalBankTerminalIsUsed Then
				// If payment was earlier authorized manually (reference number is filled) or automatically then skip this step
				If Not IsBlankString(Object.ReferenceNumber) And Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Authorised") And Not CancellationIsAuthorized Then
					If CheckCreditCardsProcessingSystem() Then
						If Not CancelPreauthorisation(vMessage) Then
							pCancel = True;
							tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.CancelPreauthorisation';ru='Документ.ОтменаПреавторизации';de='Документ.ОтменаПреавторизации'"), , , , tcOnServer.cmNStrAtServer(vMessage));
							ShowMessageBox(, tcOnServer.cmNStrAtServer(vMessage));
							Return;
						Else
							CancellationIsAuthorized = True;
							Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Cancelled");
						EndIf;
					Else
						Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Cancelled");
					EndIf;
				Else
					Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Cancelled");
				EndIf;
			Else
				Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Cancelled");
			EndIf;
			// Post document
			Write(New Structure("WriteMode", DocumentWriteMode.Posting));
			// Notify changes in the accounts subsystem
			Notify("Document.Preauthorisation.Write", Object.Ref, ThisObject);
			// Close form
			Close();
		EndIf;
	EndIf;
EndProcedure //  CancelOperation

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintSlip(pCommand)
	vErrorTitle = NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'");
	
	vMessage = "";
	vCashRegister = Object.CashRegister;
	
	vSlipText = Object.SlipText;
	If pCommand.Name = "PrintAnnulationSlip" Then
		vSlipText = Object.CancellationSlipText;
	EndIf;
	
	If Not ValueIsFilled(vCashRegister) Or IsBlankString(vSlipText) Then
		Return;
	EndIf;
	
	vCashRegisterArr = tcOnServer.cmGetAtributeAsArray(vCashRegister);
	If Not IsReadyToPrintCheque(vMessage, vCashRegister) Then
		ShowMessageBox(, vMessage, , vErrorTitle);
		Return;
	EndIf;
	
	vSlipTxtArr = tcOnServer.GetTextLinesArray(vSlipText);
	vDriver = tcOnClient.cmGetModulTO(vCashRegisterArr);
	If vDriver = Undefined Then
		vMessage = Nstr("en = 'Work with driver this device is not supported'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'; ru = 'Работа с драйвером этого устройства не поддерживается'");
		ShowMessageBox(, vMessage, , vErrorTitle);
		Return;
	EndIf;
	
	vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, vCashRegisterArr);
	vQuestion =  NStr("en = 'Input cash register password please...'; de = 'Input cash register password please...'; ru = 'Пожалуйста введите пароль ККМ...'");
	
	If IsBlankString(vPasswordKKM) Then
		vNotifity = New NotifyDescription("PrintSlipAfterInputCashRegisterPassword", ThisObject, New Structure("Driver, rMessage, pCashRegister, pSlipTextArr", vDriver, vMessage, vCashRegisterArr, vSlipTxtArr));
		OpenForm("CommonForm.tcInputCashRegisterPassword",New Structure("LabelDescription",vQuestion), , , , ,vNotifity);
		Return;
	EndIf;
	
	vDriver.pmPrintSlip(vSlipTxtArr, vCashRegisterArr, vMessage, vPasswordKKM);
	
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(, vMessage, , vErrorTitle);
	EndIf;
EndProcedure // PrintSlip

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
&AtClient
Function IsReadyToPrintCheque(rMessage, pCashRegister)
	rMessage = "";
	
	If Not ValueIsFilled(pCashRegister) Then
		Return False;
	EndIf;
	
	vDriver = tcOnClient.cmGetModulTO(pCashRegister);
	If vDriver = Undefined Then
		ShowMessageBox(, Nstr("en = 'Work with this device driver is not supported!'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return False;
	EndIf;
	
	Return vDriver.pmIsReadyToPrint(rMessage, , pCashRegister);
EndFunction // IsReadyToPrintCheque

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenAtServer()
	// Check edit prohibited date
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.Hotel.EditProhibitedDate) And 
			BegOfDay(Object.Hotel.EditProhibitedDate) >= BegOfDay(Object.Date) Then
			ReadOnly = True;
			Items.CancelOperation.Enabled = False;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.Company) Then
		If ValueIsFilled(Object.Company.EditProhibitedDate) And 
			BegOfDay(Object.Company.EditProhibitedDate) >= BegOfDay(Object.Date) Then
			ReadOnly = True;
			Items.CancelOperation.Enabled = False;
		EndIf;
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
	// Guest group
	If IsNew Then
		If Object.Folio.GuestGroup <> Object.GuestGroup Then
			Object.GuestGroup = Object.Folio.GuestGroup;
		EndIf;
	EndIf;
	// Set view only mode
	If Object.Posted Then
		If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
			ReadOnly = True;
		EndIf;
	EndIf;
	// Set document number and date appearances
	If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
		Items.Number.ReadOnly = True;
		Items.Number.Enabled = False;
		Items.Date.ReadOnly = True;
		Items.Date.Enabled = False;
		Items.Date.ChoiceButton = False;
	EndIf;
	If Object.Status = PredefinedValue("Enum.PreauthorisationStatuses.Authorised") Then
		Items.CancelOperation.Enabled = True;
	Else
		Items.CancelOperation.Enabled = False;
	EndIf;
EndProcedure //  OnOpenAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_OpenCashRegistersList() 
	vNotify = New NotifyDescription("Attachable_AfterCashRegisterChoice", ThisObject, New Structure("CheckInvoices", True));
	CashRegistersList.ShowChooseItem(vNotify, NStr("en='Select cash register please!';ru='Выберите ККМ!';de='Wählen Sie Registrierkasse!'"));
EndProcedure //  OpenCashRegistersList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPaymentMethods()
	vPaymentMethods = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser, , Object.CashRegister, True).UnloadValues();
	Items.PaymentMethod.ChoiceList.LoadValues(vPaymentMethods);
	If vPaymentMethods.Count() = 1 Then
		Object.PaymentMethod = vPaymentMethods[0]; 
	EndIf;	
	// Check that current payment method is in the list
	If Object.Posted Then
		If ValueIsFilled(Object.PaymentMethod) Then
			If Items.PaymentMethod.ChoiceList.FindByValue(Object.PaymentMethod) = Undefined Then
				Items.PaymentMethod.ChoiceList.Add(Object.PaymentMethod);
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  FillListOfPaymentMethods

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
	If Object.Posted Then
		If ValueIsFilled(Object.CashRegister) Then
			If CashRegistersList.FindByValue(Object.CashRegister) = Undefined Then
				CashRegistersList.Add(Object.CashRegister);
			EndIf;
		EndIf;
	EndIf;
	// Attach list of cash registers to the form item
	Items.CashRegister.ChoiceList.LoadValues(CashRegistersList.UnloadValues());
EndProcedure //  FillListOfCashRegisters

// -----------------------------------------------------------------------------
&AtServer
Function SetDefaultCashRegister()
	If CashRegistersList.FindByValue(Object.CashRegister) = Undefined Then
		Object.CashRegister = Catalogs.CashRegisters.EmptyRef();
		If ValueIsFilled(Object.PaymentMethod) Then
			If Object.PaymentMethod.BookByCashRegister Then
				If CashRegistersList.Count() = 1 Then
					Object.CashRegister = CashRegistersList.Get(0).Value;
				ElsIf CashRegistersList.Count() > 1 Then
					Return True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return False;
EndFunction //  SetDefaultCashRegister

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
EndProcedure //  SetDefaultPaymentMethod

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPayers()
	If ReadOnly Then
		Return;
	EndIf;
	If ValueIsFilled(Object.Folio) Then
		If ValueIsFilled(Object.Folio.Client) Then
			Items.Payer.ChoiceList.Add(Object.Folio.Client, Object.Folio.Client.FullName, , PictureLib.Individual);
		EndIf;
		If ValueIsFilled(Object.Folio.Customer) Then
			Items.Payer.ChoiceList.Add(Object.Folio.Customer, Object.Folio.Customer.Description, , PictureLib.Customer);
		EndIf;
	EndIf;
EndProcedure //  FillListOfPayers

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
EndProcedure //  FillListOfPayersCreditCards

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_AfterCashRegisterChoice(pUserChoiceItem, pExtraParams) Export
	If pUserChoiceItem <> Undefined Then
		Object.CashRegister = pUserChoiceItem.Value;
		CashRegisterOnChangeAtServer();
		If pExtraParams.Property("CheckInvoices") Then
			If pExtraParams.CheckInvoices Then
				If CheckInvoices() Then
					AttachIdleHandler("OpenProformaInvoicesList", 0.1, True);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  Attachable_AfterCashRegisterChoice    

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenProformaInvoicesList() 
	OpenForm("Document.ProformaInvoice.Form.tcListForm", New Structure("ChoiceMode, SelHotel, SelGuestGroup", True, Object.Hotel, Object.GuestGroup), Items.Invoice);
EndProcedure //  OpenProformaInvoicesList

// -----------------------------------------------------------------------------
&AtServer
Procedure CashRegisterOnChangeAtServer()
	// Fill list of payment methods allowed for the current user
	FillListOfPaymentMethods();
	// Set default payment method
	If IsNew Then
		SetDefaultPaymentMethod();
	EndIf;
EndProcedure //  CashRegisterOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckInvoices()
	If IsNew Then
		// Check if payment folio is based on reservation and there are invoices for this guest group then
		//  ask user to choose invoice
		vFolio = Object.Folio;
		If ValueIsFilled(vFolio) And ValueIsFilled(vFolio.GuestGroup) And Not ValueIsFilled(Object.Invoice) Then
			If Not ValueIsFilled(vFolio.ParentDoc) Or ValueIsFilled(vFolio.ParentDoc) And 
				(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) Then
				vGroupObj = vFolio.GuestGroup.GetObject();
				vInvoices = vGroupObj.pmGetInvoices(vFolio.Customer, vFolio.Contract);
				For Each vInvRow In vInvoices Do
					If vInvRow.Balance > 0 Then
						Return True;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	Return False;
EndFunction //  CheckInvoices

// -----------------------------------------------------------------------------
&AtServer
Procedure ProcessCreditCardPaymentMethodChoice()
	// Set focus to right controls
	If ValueIsFilled(Object.PaymentMethod) Then
		If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
			If Not SessionParameters.CurrentWorkstation.HasConnectionToCreditCardsProcessingSystem Or 
			   Object.PaymentMethod.ExternalBankTerminalIsUsed Then
				If cmCheckUserPermissions("HavePermissionToSaveCreditCards") Then
					If Object.PaymentMethod.IsByCreditCard Or Object.PaymentMethod.AuthorizationCodeIsRequired Or Object.PaymentMethod.ReferenceCodeIsRequired Then
						CurrentItem = Items.CreditCard;
					EndIf;
				Else
					If Object.PaymentMethod.AuthorizationCodeIsRequired Then
						CurrentItem = Items.AuthorizationCode;
					ElsIf Object.PaymentMethod.ReferenceCodeIsRequired Then
						CurrentItem = Items.ReferenceNumber;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  ProcessCreditCardPaymentMethodChoice

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
EndFunction	// CheckCreditCardsProcessingSystem

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
Function Preauthorize(rMessage)
	rMessage = "";
	If Not ValueIsFilled(Object.AuthorizationCode) Then
		vDriver = tcOnClient.cmGetModulTO(ArrPaymentTerminal);
		If Not vDriver = Undefined Then
			If ArrPaymentTerminal.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.TrPosPOSTerminalsDriver") Then
				SetNewObjectRefAtServer();	
			EndIf;
			Return vDriver.pmPreauthorization(Object.Sum, Object, rMessage, ArrPaymentTerminal);
		Else
			ShowMessageBox(, Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		EndIf;	
	EndIf;
	Return True;
EndFunction //  AuthorizePayment

// -----------------------------------------------------------------------------
&AtServer
Procedure SetNewObjectRefAtServer()
	If Not ValueIsFilled(Object.Number) Then
		vObj = FormAttributeToValue("Object");
		vObj.SetNewNumber();
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure //  SetNewObjectRefAtServer

// -----------------------------------------------------------------------------
&AtClient
Function CancelPreauthorisation(rMessage)
	rMessage = "";
	If ValueIsFilled(Object.AuthorizationCode) And Not ValueIsFilled(Object.CancellationSlipText) Then
		vDriver = tcOnClient.cmGetModulTO(ArrPaymentTerminal);
		If Not vDriver = Undefined Then
			Return vDriver.pmCancelPreauthorization(Object.Sum, Object, rMessage, ArrPaymentTerminal);
		Else
			ShowMessageBox(, Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		EndIf;	
	EndIf;
	Return True;
EndFunction //  AuthorizePayment

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(rMessage)
	vObj = FormAttributeToValue("Object");	
	SetObjectAndFormAttributeConformity(vObj, "Object");
	// Basic checks
	vAttributeInErr = "";
	If Not ValueIsFilled(Object.CashRegister) Then
		vUM = New UserMessage();
		vUM.SetData(vObj);
		vUM.Field = vAttributeInErr;
		vUM.Text = NStr("en='Cash register is empty!'; ru='Не указан ККМ!'; de='Kasse ist leer!'");
		vUM.Message();
		Return False;
	EndIf;
	If Object.Sum = 0 Then
		vUM = New UserMessage();
		vUM.SetData(vObj);
		vUM.Field = vAttributeInErr;
		vUM.Text =NStr("en='Preauthorisation amount should be entered!';ru='Не введена сумма преавторизации!';de='Die Summe der Vorautorisierung wurde nicht angegeben!'");;
		vUM.Message();
		Return False;
	EndIf;
	If vObj.pmCheckDocumentAttributes(rMessage, vAttributeInErr) Then
		vUM = New UserMessage();
		vUM.SetData(vObj);
		vUM.Field = vAttributeInErr;
		vUM.Text = NStr(rMessage);
		vUM.Message();
		Return False;
	EndIf;	
	If ValueIsFilled(vObj.PaymentMethod) And ValueIsFilled(vObj.Hotel) And ValueIsFilled(vObj.Folio) Then
		// Check that payment methos allowed for the current folio
		If vObj.PaymentMethod.IsForExtraServiceFolioOnly And Not IsBlankString(vObj.Hotel.AdditionalServicesFolioCondition) And 
		   StrFind(Upper(TrimAll(vObj.Folio.Description)), Upper(TrimAll(vObj.Hotel.AdditionalServicesFolioCondition))) = 0 Then
			rMessage = "en='Payment is allowed for extra services folio only!';
			           |ru='Оплата выбранным спобом оплаты возможна только по лицевому счету доп. услуг!';
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
	Return True;
EndFunction //  CheckDocumentAttributesAtServer

// -----------------------------------------------------------------------------
&AtClient
Function ConfirmPaymentMethodChoice()
	If Not PostAndCloseConfirmed And GetAskForPaymentMethodConfirmation() Then    
		If ValueIsFilled(Object.CashRegister) Then
			vCR = StrTemplate(NStr("en = 'by %1 cash register.'; de = 'von %1 Kasse.'; ru = 'по ККМ %1.'"), Upper(TrimAll(Object.CashRegister)));	
		Else
			vCR = "";	
		EndIf;	
		vQuery = NStr("ru = 'В платеже выбран способ оплаты
		              |
		              |%1.        
		              |
		              |Вы подтверждаете выбор этого способа оплаты?
		              |
		              |Ответ ""Да"" - провести документ %2
		              |Ответ ""Нет"" - вернуться в режим редактирования документа.'; 
					  |de = 'You have choosen 
		              |
		              |%1 payment method.
		              |
		              |Would you like to confirm your choice?
		              |
		              |Answer ""Yes"" to post document %2
		              |Answer ""No"" to return to the document form.';
					  |en = 'You have choosen 
		              |
		              |%1 payment method.
		              |
		              |Would you like to confirm your choice?
		              |
		              |Answer ""Yes"" to post document %2
		              |Answer ""No"" to return to the document form.'");
		ShowQueryBox(New NotifyDescription("ConfirmPaymentMethodChoiceAfterUserAnswer", ThisObject), StrTemplate(vQuery, Upper(TrimAll(Object.PaymentMethod)), vCR), QuestionDialogMode.YesNo, , DialogReturnCode.No);
		Return False;
	Else
		Return True;
	EndIf;              
EndFunction //  ConfirmPaymentMethodChoice

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
EndFunction //  GetAskForPaymentMethodConfirmation

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
EndProcedure //  ConfirmPaymentMethodChoiceAfterUserAnswer

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateSums()
	Object.SumInFolioCurrency = Round(cmConvertCurrencies(Object.Sum, Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, 
												   Object.FolioCurrency, Object.FolioCurrencyExchangeRate, 
												   Object.ExchangeRateDate, Object.Hotel), 2);

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentCurrencyOnChangeAtServer()
	PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.PaymentCurrency, Object.ExchangeRateDate);
	Object.Sum = Round(cmConvertCurrencies(Object.Sum, OldPaymentCurrency, OldPaymentCurrencyExchangeRate, 
				Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, 
				Object.ExchangeRateDate, Object.Hotel), 2);
	SavePaymentCurrencyAttributes();
	CalculateSums();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SavePaymentCurrencyAttributes()
	OldPaymentCurrency = Object.PaymentCurrency;
	OldPaymentCurrencyExchangeRate = Object.PaymentCurrencyExchangeRate;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ExchangeRateDateOnChangeAtServer()
	Object.PaymentCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.PaymentCurrency, Object.ExchangeRateDate);
	SavePaymentCurrencyAttributes();
	Object.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.FolioCurrency, Object.ExchangeRateDate);
	Object.Sum = Round(cmConvertCurrencies(Object.SumInFolioCurrency, 
									Object.FolioCurrency, Object.FolioCurrencyExchangeRate, 
									Object.PaymentCurrency, Object.PaymentCurrencyExchangeRate, 
									Object.ExchangeRateDate, Object.Hotel), 2);
EndProcedure //  ExchangeRateDateOnChangeAtServer

&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("Structure") And pSelectedValue.Property("CreditCardProcessingSystem") Then
		CreditCardProcessingSystem = pSelectedValue.CreditCardProcessingSystem; 
		If Not IsCancelOperation Then
			Write(New Structure("WriteMode", DocumentWriteMode.Posting));
		Else
			CancelOperation(Undefined);	
		EndIf;
	EndIf;
EndProcedure

#EndRegion 
