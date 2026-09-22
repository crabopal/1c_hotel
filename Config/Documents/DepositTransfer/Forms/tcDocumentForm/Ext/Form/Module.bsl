
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
	
	AdvanceMode = False;
	If ValueIsFilled(Object.PaymentSection) And Object.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
		AdvanceMode = True;
	EndIf;
	MultipleAdvanceSectionsMode = MultipleAdvancePaymentSectionsMode();
	If ValueIsFilled(Object.Hotel) And Object.Hotel.SplitFolioBalanceByPaymentSections Then
		If MultipleAdvanceSectionsMode Then
			Items.PaymentSection.Visible = False;
			Items.Sum.Visible = True;
			Items.Sum.ReadOnly = True;
			Items.Sum.TextEdit = False;
			Items.Sum.ChoiceListButton = False;
			Items.Sum.ChoiceButton = False;
			Items.PaymentSections.ReadOnly = False;
			Items.PaymentSections.Visible = True;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = True;
			Items.PaymentSectionsChequeService.Visible = False;
			Items.PaymentSectionsChequeServicePrice.Visible = False;
			Items.PaymentSectionsChequeServiceQuantity.Visible = False;
		ElsIf AdvanceMode Then
			Items.Sum.ReadOnly = False;
			Items.Sum.ChoiceListButton = False;
			Items.Sum.ChoiceButton = True;
			Items.PaymentSection.ReadOnly = True;
			Items.PaymentSections.Visible = False;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = True;
			Items.PaymentSectionsChequeService.Visible = False;
			Items.PaymentSectionsChequeServicePrice.Visible = False;
			Items.PaymentSectionsChequeServiceQuantity.Visible = False;
		Else
			Items.Sum.ReadOnly = True;
			Items.Sum.ChoiceListButton = False;
			Items.Sum.ChoiceButton = False;
			Items.PaymentSection.ReadOnly = False;
			Items.PaymentSections.Visible = True;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = True;
			Items.PaymentSectionsChequeService.Visible = False;
			Items.PaymentSectionsChequeServicePrice.Visible = False;
			Items.PaymentSectionsChequeServiceQuantity.Visible = False;
		EndIf;
	ElsIf ValueIsFilled(Object.Hotel) And Object.Hotel.SplitFolioBalanceByServicesAndPrices Then
		If MultipleAdvanceSectionsMode Then
			Items.PaymentSection.Visible = False;
			Items.Sum.Visible = True;
			Items.Sum.ReadOnly = True;
			Items.Sum.TextEdit = False;
			Items.Sum.ChoiceListButton = False;
			Items.Sum.ChoiceButton = False;
			Items.PaymentSections.ReadOnly = False;
			Items.PaymentSections.Visible = True;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = True;
			Items.PaymentSectionsChequeService.Visible = False;
			Items.PaymentSectionsChequeServicePrice.Visible = False;
			Items.PaymentSectionsChequeServiceQuantity.Visible = False;
		ElsIf AdvanceMode Then
			Items.Sum.ReadOnly = False;
			Items.Sum.ChoiceListButton = False;
			Items.Sum.ChoiceButton = True;
			Items.PaymentSection.ReadOnly = True;
			Items.PaymentSections.Visible = False;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = False;
			Items.PaymentSectionsChequeService.Visible = False;
			Items.PaymentSectionsChequeServicePrice.Visible = False;
			Items.PaymentSectionsChequeServiceQuantity.Visible = False;
		Else
			Items.Sum.ReadOnly = True;
			Items.Sum.ChoiceListButton = False;
			Items.Sum.ChoiceButton = False;
			Items.PaymentSection.ReadOnly = False;
			Items.PaymentSections.Visible = True;
			Items.PaymentSectionsPaymentSection.HorizontalStretch = False;
			Items.PaymentSectionsChequeService.Visible = True;
			Items.PaymentSectionsChequeServicePrice.Visible = True;
			Items.PaymentSectionsChequeServiceQuantity.Visible = True;
		EndIf;
	Else
		Items.Sum.ReadOnly = False;
		Items.Sum.ChoiceListButton = True;
		Items.Sum.ChoiceButton = True;
		Items.PaymentSections.Visible = False;
	EndIf;
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Check rights to edit posted document
	If ValueIsFilled(Object.Ref) Then
		If Object.Posted Then
			If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
				If Not (ValueIsFilled(Object.Hotel.AccountingDate) And Object.AccountingDate = Object.Hotel.AccountingDate Or
				        Not ValueIsFilled(Object.Hotel.AccountingDate) And BegOfDay(Object.Date) = BegOfDay(CurrentSessionDate())) Then
					ReadOnly = True;
					Items.FormSetDeletionMarkAction.Visible = False;
				EndIf;
			EndIf;
			// Check edit prohibited dates
			vHotel = Object.Hotel;
			If Not ReadOnly Then
				If ValueIsFilled(vHotel) Then
					If ValueIsFilled(vHotel.EditProhibitedDate) And BegOfDay(vHotel.EditProhibitedDate) >= BegOfDay(Object.Date) Then
						ReadOnly = True;
						Items.FormSetDeletionMarkAction.Visible = False;
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(Object.FolioFrom) Then
				vCompany = Object.FolioFrom.Company;
				If Not ReadOnly Then
					If ValueIsFilled(vCompany) Then
						If ValueIsFilled(vCompany.EditProhibitedDate) And BegOfDay(vCompany.EditProhibitedDate) >= BegOfDay(Object.Date) Then
							ReadOnly = True;
							Items.FormSetDeletionMarkAction.Visible = False;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(Object.FolioTo) Then
				vCompany = Object.FolioTo.Company;
				If Not ReadOnly Then
					If ValueIsFilled(vCompany) Then
						If ValueIsFilled(vCompany.EditProhibitedDate) And BegOfDay(vCompany.EditProhibitedDate) >= BegOfDay(Object.Date) Then
							ReadOnly = True;
							Items.FormSetDeletionMarkAction.Visible = False;
						EndIf;
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
		Else
			Items.FormSetDeletionMarkAction.Visible = False;
		EndIf;
	Else
		Items.FormSetDeletionMarkAction.Visible = False;
		
		// Fill payment method
		If Parameters.Property("PaymentMethod") Then
			vPM = Parameters.PaymentMethod;
			If ValueIsFilled(vPM) And TypeOf(vPM) = Type("CatalogRef.PaymentMethods") Then
				Object.PaymentMethod = vPM;
			EndIf;
		EndIf;
		If Parameters.Property("Payment") Then
			vPayment = Parameters.Payment;
			If ValueIsFilled(vPayment) Then
				Object.Payment = vPayment;
			EndIf;
		EndIf;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	Try
		ClearMessages();
		
		vMessage = "";
		// Check document attributes
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
	Notify("Document.DepositTransfer.Write", Object.Ref, ThisObject);
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
	EndIf;
EndProcedure // OnCloseAtServer

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
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SumOnChange(pItem)
	SumOnChangeAtServer();
EndProcedure // SumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SumStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	If MultipleAdvanceSectionsMode Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // SumStartChoice

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsAfterDeleteRow(pItem)
	Object.SumInFolioFromCurrency = Object.PaymentSections.Total("SumInFolioFromCurrency");
	Object.SumInFolioToCurrency = Object.PaymentSections.Total("SumInFolioToCurrency");
EndProcedure // PaymentSectionsAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsOnEditEnd(pItem, pNewRow, pCancelEdit)
	Object.SumInFolioFromCurrency = Object.PaymentSections.Total("SumInFolioFromCurrency");
	Object.SumInFolioToCurrency = Object.PaymentSections.Total("SumInFolioToCurrency");
EndProcedure // PaymentSectionsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentSectionsSumInFolioFromCurrencyOnChange(pItem)
	PaymentSectionsSumInFolioFromCurrencyOnChangeAtServer();
EndProcedure // PaymentSectionsSumInFolioFromCurrencyOnChange

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

#EndRegion

#Region FormCommandsEventHandlers

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
	Notify("Document.DepositTransfer.Write", Object.Ref, ThisObject);
	Close();
EndProcedure // SetDeletionMarkAction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SumOnChangeAtServer()
	Object.SumInFolioToCurrency = Round(cmConvertCurrencies(Object.SumInFolioFromCurrency, Object.FolioFromCurrency, Object.FolioFromCurrencyExchangeRate, Object.FolioToCurrency, Object.FolioToCurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
	If Object.PaymentSections.Count() > 0 Then
		vWasFound = False;
		i = 0;
		While i < Object.PaymentSections.Count() Do
			vPSRow = Object.PaymentSections.Get(i);
			If Not vWasFound And vPSRow.PaymentSection = Object.PaymentSection Then
				vWasFound = True;
				vPSRow.SumInFolioFromCurrency = Object.SumInFolioFromCurrency;
				vPSRow.SumInFolioToCurrency = Object.SumInFolioToCurrency;
				If vPSRow.ChequeServiceQuantity <> 0 Then
					vPSRow.ChequeServicePrice = Round(vPSRow.SumInFolioFromCurrency / vPSRow.ChequeServiceQuantity, 2);
				EndIf;
				i = i + 1;
			Else
				Object.PaymentSections.Delete(i);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // SumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(rMessage)
	vObj = FormAttributeToValue("Object");
	SetObjectAndFormAttributeConformity(vObj, "Object");
	// Basic checks
	rMessage = "";
	vAttributeInErr = "";
	If vObj.pmCheckDocumentAttributes(rMessage, vAttributeInErr) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), vObj, vAttributeInErr, , True);
		Return False;
	Else
		// Check folio from balance
		If Not cmCheckUserPermissions("HavePermissionToTransferMoneyFromFoliosWithDebts") Then
			If vObj.FolioFrom <> vObj.FolioTo And vObj.SumInFolioFromCurrency <> 0 Then
				If vObj.PaymentSections.Count() > 0 Then
					For Each vPaymentSectionsRow In vObj.PaymentSections Do
						vFolioFromBalance = vObj.FolioFrom.GetObject().pmGetBalance(, vObj.Hotel, vPaymentSectionsRow.PaymentSection);
						If (vPaymentSectionsRow.SumInFolioFromCurrency + vFolioFromBalance) > 0 Then
							rMessage = "ru='На лицевом счете источнике не хватает денег!'; 
							           |en='Not enough money at source folio!';
									   |de='Nicht genug Geld an der Quelle folio!'";
							vAttributeInErr = "FolioFrom";
							
							tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), vObj, vAttributeInErr, , True);							
							Return False;
						EndIf;
					EndDo;
				Else
					vFolioFromBalance = 0;
					If ValueIsFilled(vObj.PaymentSection) Then
						vBalanceRows = vObj.FolioFrom.GetObject().pmGetPaymentSectionBalances(, vObj.Hotel, vObj.PaymentSection);
						For Each vBalanceRow In vBalanceRows Do
							vFolioFromBalance = vFolioFromBalance + vBalanceRow.SumBalance;
						EndDo;
					Else
						vFolioFromBalance = vObj.FolioFrom.GetObject().pmGetBalance(, vObj.Hotel);
					EndIf;
					If (vObj.SumInFolioFromCurrency + vFolioFromBalance) > 0 Then
						pCancel = True; 
						If ValueIsFilled(vObj.PaymentSection) Then
							rMessage = "ru='На лицевом счете источнике на секции " + TrimAll(vObj.PaymentSection) + " не хватает денег!'; 
							           |en='Not enough money at source folio and payment section " + TrimAll(vObj.PaymentSection) + "!';
									   |de='Nicht genug Geld an der Quelle folio und Zahlungsektion " + TrimAll(vObj.PaymentSection) + "!'";
						Else
							rMessage = "ru='На лицевом счете источнике не хватает денег!'; 
							           |en='Not enough money at source folio!';
									   |de='Nicht genug Geld an der Quelle folio!'";
						EndIf;
						vAttributeInErr = "FolioFrom";
						tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), vObj, vAttributeInErr, , True);
						Return False;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If Not cmCheckUserPermissions("HavePermissionToTransferDepositsBetweenGuestGroups") Then
			If vObj.FolioFrom.GuestGroup <> vObj.FolioTo.GuestGroup Then
				rMessage = "ru='Нет прав на перемещение депозита между лицевыми счетами разных групп гостей!'; 
				           |en='You do not have rights to transfer deposits between folios of different guest groups!';
						   |de='Sie haben kein Recht, Einzahlungen zwischen folios verschiedener Gästegruppen zu übertragen!'";
				vAttributeInErr = "FolioTo";
				
				tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), vObj, vAttributeInErr, , True); 
				Return False;
			Else
				If Not cmCheckUserPermissions("HavePermissionToTransferDepositsBetweenGuestsOfOneGuestGroup") Then
					If vObj.FolioFrom.Client <> vObj.FolioTo.Client And 
					   TypeOf(vObj.FolioFrom.ParentDoc) <> Type("DocumentRef.Reservation") And 
					   TypeOf(vObj.FolioFrom.ParentDoc) <> Type("DocumentRef.ResourceReservation") Then
						pCancel = True; 
						rMessage = "ru='Нет прав на перемещение депозита между лицевыми счетами разных клиентов!'; 
						           |en='You do not have rights to transfer deposits between folios of different clients!';
						           |de='Sie haben keine Rechte, Einlagen zwischen folios verschiedener Kunden zu übertragen!'";
						vAttributeInErr = "FolioTo";
						
						tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), vObj, vAttributeInErr, , True);
						Return False;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If Not cmCheckUserPermissions("HavePermissionToTransferDepositsBetweenHotels") Then
			If vObj.FolioFrom.Hotel <> vObj.FolioTo.Hotel Then
				rMessage = "en = 'You do not have rights to transfer deposits between folios of different hotels!'; 
						   |de = 'Sie sind nicht berechtigt, Einzahlungen zwischen Folios verschiedener hotels zu übertragen!'; 
						   |ru = 'Нет прав на перемещение депозита между лицевыми счетами разных отелей!'";
				vAttributeInErr = "FolioTo";    
				tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), vObj, vAttributeInErr, , True);
				Return False;
			EndIf;
		EndIf;
		Return True;
	EndIf;				
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
&AtServer
Procedure FillDocumentObjectParameters(pCancel = False, pStandardProcessing = True)
	// Actions for the new document
	If Not ValueIsFilled(Object.Ref) Then
		If Parameters.Property("Basis") And ValueIsFilled(Parameters.Basis) Then
			pStandardProcessing = False;
			vObj = FormAttributeToValue("Object");
			vObj.PaymentSections.Clear();
			vObj.Fill(Parameters.Basis);
			If Parameters.Property("FolioTo") And ValueIsFilled(Parameters.FolioTo) Then
				vObj.FolioTo = Parameters.FolioTo;
				vObj.pmFolioToOnChange();
			EndIf;
			ValueToFormAttribute(vObj, "Object");
		EndIf;
		If Parameters.Property("EmployeePINCodeChecked") And Parameters.EmployeePINCodeChecked Then
			EmployeePINCodeChecked = True;
		EndIf;
	EndIf;
EndProcedure // FillDocumentObjectParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionsSumInFolioFromCurrencyOnChangeAtServer()
	vCurRow = Object.PaymentSections[Items.PaymentSections.CurrentRow];
	If vCurRow <> Undefined Then
		vCurRow.SumInFolioToCurrency = Round(cmConvertCurrencies(vCurRow.SumInFolioFromCurrency, Object.FolioFromCurrency, Object.FolioFromCurrencyExchangeRate, 
														         Object.FolioToCurrency, Object.FolioToCurrencyExchangeRate, 
														         Object.ExchangeRateDate, Object.Hotel), 2);
		If Items.PaymentSectionsChequeService.Visible Then
			If ValueIsFilled(vCurRow.ChequeService) Then
				If vCurRow.ChequeServiceQuantity = 0 Then
					vCurRow.ChequeServiceQuantity = 1;
				EndIf;
				If vCurRow.ChequeServicePrice <> 0 Then
					vCurRow.ChequeServiceQuantity = Round(vCurRow.SumInFolioFromCurrency / vCurRow.ChequeServicePrice, 7);
				ElsIf vCurRow.SumInFolioFromCurrency <> 0 And vCurRow.ChequeServiceQuantity <> 0 Then
					vCurRow.ChequeServicePrice = Round(vCurRow.SumInFolioFromCurrency / vCurRow.ChequeServiceQuantity, 2);
				Else
					vCurRow.ChequeServicePrice = vCurRow.SumInFolioFromCurrency;
					vCurRow.ChequeServiceQuantity = 1;
				EndIf;
			Else
				vCurRow.ChequeServicePrice = vCurRow.SumInFolioFromCurrency;
				vCurRow.ChequeServiceQuantity = 1;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PaymentSectionsSumInFolioFromCurrencyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionsChequeServicePriceOnChangeAtServer()
	vCurRow = Object.PaymentSections[Items.PaymentSections.CurrentRow];
	If vCurRow <> Undefined Then
		vCurRow.SumInFolioFromCurrency = Round(vCurRow.ChequeServicePrice * vCurRow.ChequeServiceQuantity, 2);
		vCurRow.SumInFolioToCurrency = Round(cmConvertCurrencies(vCurRow.SumInFolioFromCurrency, Object.FolioFromCurrency, Object.FolioFromCurrencyExchangeRate, 
														         Object.FolioToCurrency, Object.FolioToCurrencyExchangeRate, 
														         Object.ExchangeRateDate, Object.Hotel), 2);
	EndIf;
EndProcedure // PaymentSectionsChequeServicePriceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PaymentSectionsChequeServiceQuantityOnChangeAtServer()
	vCurRow = Object.PaymentSections[Items.PaymentSections.CurrentRow];
	If vCurRow <> Undefined Then
		vCurRow.SumInFolioFromCurrency = Round(vCurRow.ChequeServicePrice * vCurRow.ChequeServiceQuantity, 2);
		vCurRow.SumInFolioToCurrency = Round(cmConvertCurrencies(vCurRow.SumInFolioFromCurrency, Object.FolioFromCurrency, Object.FolioFromCurrencyExchangeRate, 
														         Object.FolioToCurrency, Object.FolioToCurrencyExchangeRate, 
														         Object.ExchangeRateDate, Object.Hotel), 2);
	EndIf;
EndProcedure // PaymentSectionsChequeServiceQuantityOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function MultipleAdvancePaymentSectionsMode()
	vMultipleAdvancePaymentSectionsMode = False;
	vAdvancePaymentSections = cmGetAdvancePaymentSections(Object.Hotel);
	If vAdvancePaymentSections.Count() > 1 Then
		vMultipleAdvancePaymentSectionsMode = True;
	EndIf;
	If vMultipleAdvancePaymentSectionsMode Then
		For Each vPSRow In Object.PaymentSections Do
			If ValueIsFilled(vPSRow.ChequeService) Then
				vMultipleAdvancePaymentSectionsMode = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	Return vMultipleAdvancePaymentSectionsMode;
EndFunction // MultipleAdvancePaymentSectionsMode

#EndRegion    
