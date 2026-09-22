
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
		
	// Check rights to use this form
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Process form parameters
	If Parameters.Property("Hotel") Then
		SelHotel = Parameters.Hotel;
	EndIf;
	If Not ValueIsFilled(SelHotel) Then
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.AccountingDate) Then
		SelAccountingDate = SelHotel.AccountingDate;
	Else
		SelAccountingDate = BegOfDay(CurrentSessionDate());
	EndIf;
		
	// Filter by current hotel
	If ValueIsFilled(SelHotel) Then
		vFilter = ServicesGroup.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vFilter.LeftValue = New DataCompositionField("Hotel");
		vFilter.ComparisonType = DataCompositionComparisonType.InList;
		vList = New ValueList;
		vList.Add(Catalogs.Hotels.EmptyRef());
		vList.Add(SelHotel);
		vFilter.RightValue = vList;
		vFilter.Use = True;
	EndIf;
	
	// Filter by service group
	vServicesGroup = Catalogs.ServiceGroups.EmptyRef();
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And ValueIsFilled(SessionParameters.CurrentWorkstation.KioskServiceGroup) Then
		vServicesGroup = SessionParameters.CurrentWorkstation.KioskServiceGroup;
	Else
		vPermGrp = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
		If ValueIsFilled(vPermGrp) And ValueIsFilled(vPermGrp.ServicesServiceGroup) Then
			vServicesGroup = vPermGrp.ServicesServiceGroup;
		EndIf;
	EndIf;
	If ValueIsFilled(vServicesGroup) Then
		vTopLevelParent = Undefined;
		vServicesList = cmGetServiceGroupServices(vServicesGroup, vTopLevelParent);
		
		vFilter = Services.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vFilter.LeftValue = New DataCompositionField("Ref");
		vFilter.ComparisonType = DataCompositionComparisonType.InList;
		vFilter.RightValue = vServicesList;
		vFilter.Use = True;
		
		Items.Services.Representation = TableRepresentation.List;
		
		If vTopLevelParent <> Undefined Then
			Items.Services.TopLevelParent = vTopLevelParent;
			Items.ServicesGroup.TopLevelParent = vTopLevelParent;
		EndIf;
	EndIf;
	
	// Get default folio to be used for the new bill
	ByFolioMode = False;
	If Parameters.Property("Folio") And ValueIsFilled(Parameters.Folio) Then
		ByFolioMode = True;
		SelFolio = Parameters.Folio;
		SelRoom = SelFolio.Room;    
		SelCompany = SelFolio.Company;
		SelClient = SelFolio.Client;
		If ValueIsFilled(SelClient) Then
			SelClientType = SelClient.ClientType;
		Else
			SelClientType = Catalogs.ClientTypes.EmptyRef();
		EndIf;
		Items.SelFolio.ChoiceList.Add(SelFolio);
	Else
		FillDefaultFolio();
	EndIf;
	
	// Get list of POS availabe for the user
	FillListOfCashRegisters();
	
	// Fill list of payment methods available for the user
	FillListOfPaymentMethods();
	
	// Set dynamic parameters for menu items list
	Services.Parameters.SetParameterValue("qParentService", Catalogs.Services.EmptyRef());
	Services.Parameters.SetParameterValue("qHotel", SelHotel);
	Services.Parameters.SetParameterValue("qPeriod", CurrentSessionDate());
	Services.Parameters.SetParameterValue("qAccountingDate", SelAccountingDate);
	Services.Parameters.SetParameterValue("qClientType", SelClientType);
	Services.Parameters.SetParameterValue("qClientTypeIsFilled", ValueIsFilled(SelClientType));
	
	// Client appearance
	Items.SelClient.ListChoiceMode = False;
	Items.SelClient.ChoiceList.Clear();
	Items.SelClient.DropListButton = False;
	Items.SelClient.ChoiceListButton = True;
	Items.SelClient.ChooseType = True;
	
	Items.DecorationBalance.Title = "";
	
	ByRoomMode = False;
	If Parameters.Property("Room") And ValueIsFilled(Parameters.Room) Then
		ByRoomMode = True;
		SelRoom = Parameters.Room;
		SelRoomOnChangeAtServer();
	EndIf;
	If Parameters.Property("Client") And ValueIsFilled(Parameters.Client) Then
		SelClient = Parameters.Client;
		SelClientOnChangeAtServer();
	EndIf;
	
	// Print invoice button appearance
	vPrintBillForm = Catalogs.ObjectPrintingForms.DirectPostingsPrintChargedTransactions;
	If ValueIsFilled(vPrintBillForm) And vPrintBillForm.IsActive Then
		Items.PrintLastBill.Visible = True;
		Items.PrintLastBill.Enabled = False;
	Else
		Items.PrintLastBill.Visible = False;
		Items.PrintLastBill.Enabled = False;
	EndIf;
	
	// Reset flags
	PaymentIsAuthorized = False;
	ChequeIsPrinted = False;
	OperationType = 0;
	BillTotalAmount = 0;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		FillDataByCard(vEventData.DeviceData);
	ElsIf vEventData.DeviceType = "BarCodeScaner" Then
		ChargeServiceByBarcode(vEventData.DeviceData);
	EndIf;
EndProcedure // ExternalEvent

// --------------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("Structure") And pSelectedValue.Property("CreditCardProcessingSystem") Then
		CreditCardProcessingSystem = pSelectedValue.CreditCardProcessingSystem;
		vExtraParams = Undefined;
		If pSelectedValue.Property("ExtraParams") Then
			vExtraParams = pSelectedValue.ExtraParams;	
		EndIf;
		WriteActionConfirmed(DialogReturnCode.Yes, vExtraParams);
	EndIf;
EndProcedure // ChoiceProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ServicesGroupSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	ServicesGroupOnActivateRowAtServer();
EndProcedure // ServicesGroupSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure ServicesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.Services.CurrentData;
	If vCurData <> Undefined Then
		AddService(vCurData.Ref);
	EndIf;
	CalculateBillTotal();
EndProcedure // ServicesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure BillPositionsPriceOnChange(pItem)
	vCurData = Items.BillPositions.CurrentData;
	If vCurData <> Undefined Then
		vCurData.Amount = Round(vCurData.Price * vCurData.Quantity, 2);
	EndIf;
EndProcedure // BillPositionsPriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BillPositionsQuantityOnChange(pItem)
	vCurData = Items.BillPositions.CurrentData;
	If vCurData <> Undefined Then
		If Not IsBlankString(vCurData.MarkingCode) Then
			vCurData.Quantity = 1;
			Return;
		EndIf;
		
		vCurData.Amount = Round(vCurData.Price * vCurData.Quantity, 2);
	EndIf;
EndProcedure // BillPositionsQuantityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BillPositionsAmountOnChange(pItem)
	vCurData = Items.BillPositions.CurrentData;
	If vCurData <> Undefined Then
		If Not IsBlankString(vCurData.MarkingCode) Then
			vCurData.Amount = Round(vCurData.Price * vCurData.Quantity, 2);
			Return;
		EndIf;
		
		If vCurData.Quantity = 0 Then
			vCurData.Quantity = 1;
		EndIf;
		If vCurData.Price = 0 Then
			vCurData.Price = vCurData.Amount;
		EndIf;
		If ValueIsFilled(vCurData.Service) And tcOnServer.cmGetAttributeByRef(vCurData.Service, "RecalculatePriceWhenSumChanged") Then
			vCurData.Price = Round(vCurData.Amount / vCurData.Quantity, 2);
		Else
			vCurData.Quantity = Round(vCurData.Amount / vCurData.Price, 7);
		EndIf;
	EndIf;
EndProcedure // BillPositionsAmountOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCashRegisterOnChange(pItem)
	SelCashRegisterOnChangeAtServer();
	// Fill list of payment methods available for the user
	FillListOfPaymentMethods();
EndProcedure // SelCashRegisterOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientTypeOnChange(pItem)
	SelClientTypeOnChangeAtServer();
EndProcedure // SelClientTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	SelRoomOnChangeAtServer();
EndProcedure // SelRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)
	SelClientOnChangeAtServer();
EndProcedure // SelClientOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFolioOnChange(pItem)
	SelFolioOnChangeAtServer();
EndProcedure // SelFolioOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BillPositionsAfterDeleteRow(pItem)
	CalculateBillTotal();
EndProcedure // BillPositionsAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure BillPositionsOnEditEnd(pItem, pNewRow, pCancelEdit)
	CalculateBillTotal();
EndProcedure // BillPositionsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFolioAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	If Not IsBlankString(pText) Then
		pStandardProcessing = False;
		pChoiceData = New ValueList();
		For Each vListItem In Items.SelFolio.ChoiceList Do
			If StrFind(lower(vListItem.Presentation), lower(TrimAll(pText))) > 0 Then
				pChoiceData.Add(vListItem.Value, vListItem.Presentation);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // SelFolioAutoComplete

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDiscountCardOnChange(pItem)
	vPMHasChanged = FillBalanceByCard();
EndProcedure // SelDiscountCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDiscountCardAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	pStandardProcessing = False;
	If StrLen(pText) > 2 Then
		vChoiceDataUID = SelDiscountCardAutoCompleteAtServer(pText);
		pChoiceData = GetFromTempStorage(vChoiceDataUID);
		If pChoiceData.Count() = 0 Then
			pChoiceData.Add(pText, NStr("en='--Not found--';ru='--Не найдена--';de='--Nicht gefunden--'"));
		EndIf;
	EndIf;
	Modified = True;
EndProcedure // SelDiscountCardAutoComplete

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPaymentMethodOnChange(pItem)
	If ValueIsFilled(SelPaymentMethod) Then
		If tcOnServer.cmGetAttributeByRef(SelPaymentMethod, "IsByGiftCertificate") Or tcOnServer.cmGetAttributeByRef(SelPaymentMethod, "IsByBonuses") Then
			Items.GroupGiftOrBonusCard.Visible = True;
		Else
			SelDiscountCard = Undefined;
			Items.DecorationBalance.Title = "";
			Items.GroupGiftOrBonusCard.Visible = False;
		EndIf;
	Else
		SelDiscountCard = Undefined;
		Items.DecorationBalance.Title = "";
		Items.GroupGiftOrBonusCard.Visible = False;
	EndIf;
EndProcedure // SelPaymentMethodOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure WriteAction(pCommand)
	CreditCardProcessingSystem = PredefinedValue("Catalog.CreditCardsProcessingSystemParameters.EmptyRef");
	// Ask for confirmation
	vQuery = NStr("ru = 'Выбран способ оплаты
	              |
	              |" + Upper(TrimAll(SelPaymentMethod)) + ".
	              |
	              |Подтверждаете выбор этого способа оплаты?
	              |
	              |Ответ ""Да"" - провести документ" + ?(ValueIsFilled(SelCashRegister), " по точке продаж " + Upper(TrimAll(SelCashRegister)) + ".", ".") + "
	              |Ответ ""Нет"" - вернуться в заказ.'; 
				  |en = 'You have chosen 
	              |
	              |" + Upper(TrimAll(SelPaymentMethod)) + " payment method.
	              |
	              |Would you like to confirm your choice?
	              |
	              |Answer ""Yes"" to post ticket" + ?(ValueIsFilled(SelCashRegister), " by POS " + Upper(TrimAll(SelCashRegister)) + ".", ".") + "
	              |Answer ""No"" to return to the ticket form.';
				  |de = 'Sie haben 
	              |
	              |" + Upper(TrimAll(SelPaymentMethod)) + " Zahlungstyp gewählt.
	              |
	              |Möchten Sie Ihre Wahl bestätigen?
	              |
	              |Beantworten Sie ""Ja"", um das Bestellung " + ?(ValueIsFilled(SelCashRegister), "mit " + Upper(TrimAll(SelCashRegister)) + " POS zu buchen.", "zu buchen.") + "
	              |Antworten Sie mit ""Nein"", um zum Bestellformular zurückzukehren.'");
	ShowQueryBox(New NotifyDescription("WriteActionConfirmed", ThisObject), vQuery, QuestionDialogMode.YesNo, , DialogReturnCode.No);
EndProcedure // WriteAction

// --------------------------------------------------------------------------------
&AtClient
Procedure NewBillAction(pCommand)
	NewBillActionAtServer();
EndProcedure // NewBillAction

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowFolioTransactions(pCommand)
	If ValueIsFilled(SelFolio) Then
		// APDEX
		vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", New Structure("ObjectRef", SelFolio)), Items.SelFolio, SelFolio);
	EndIf;
EndProcedure // ShowFolioTransactions

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintLastBill(pCommand)
	If ValueIsFilled(LastFolio) Then
		vCurLanguage = tcOnServer.cmGetSessionParametersAttribute("CurrentLanguage");
		vPrintFormTypeRef = PredefinedValue("Catalog.ObjectPrintingForms.FolioPrintFolioEn");
		If vCurLanguage = PredefinedValue("Catalog.Languages.RU") Then
			vPrintFormTypeRef = PredefinedValue("Catalog.ObjectPrintingForms.FolioPrintFolioRu");
		ElsIf vCurLanguage = PredefinedValue("Catalog.Languages.DE") Then
			vPrintFormTypeRef = PredefinedValue("Catalog.ObjectPrintingForms.FolioPrintFolioDe");
		EndIf;
		vTransactions = New Array();
		For Each vLastTransactionsItem In LastTransactions Do
			vTransactions.Add(vLastTransactionsItem.Value);
		EndDo;
		vParams = New Structure("InputParameter, ObjectPrintingForm, Transactions", LastFolio, vPrintFormTypeRef, vTransactions);
		OpenForm("Document.Folio.Form.tcFolioPrintForm", vParams, ThisObject, New UUID);
	EndIf;
EndProcedure // PrintLastBill

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPaymentMethods()
	vFolioDebitPM = Undefined;
	vFolioDebitPMIsFound = False;
	ByRoomIsNotAvailable = True;
	vPMList = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser, , SelCashRegister);
	For Each vPMListItem In vPMList Do
		vPM = vPMListItem.Value;
		If vPM.IsCloseToTheFolio Then
			vFolioDebitPM = vPM;
			vFolioDebitPMIsFound = True;
			Break;
		ElsIf vPM.IsCloseToTheRoom Then
			ByRoomIsNotAvailable = False;
		EndIf;
	EndDo;
	If vFolioDebitPMIsFound Then
		vCLPMItem = vPMList.FindByValue(Catalogs.PaymentMethods.Settlement);
		If vCLPMItem <> Undefined Then
			If ValueIsFilled(SelFolio) And (Not ValueIsFilled(SelFolio.Customer) Or ValueIsFilled(SelFolio.Customer) And SelFolio.Customer.IsIndividual) Then
				vPMList.Delete(vCLPMItem);
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(SelHotel) And ValueIsFilled(SelFolio) And 
	   Not ValueIsFilled(SelFolio.Client) And (Not ValueIsFilled(SelFolio.Customer) Or SelFolio.Customer = SelHotel.IndividualsCustomer) And 
	   Not ValueIsFilled(SelFolio.ParentDoc) And Not SelFolio.IsForDirectPostings Then
		i = 0;
		While i < vPMList.Count() Do
			vPMListItem = vPMList.Get(i);
			vPM = vPMListItem.Value;
			If vPM.IsCloseToTheFolio Then
				vPMList.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(SelRoom) Then
		i = 0;
		While i < vPMList.Count() Do
			vPMListItem = vPMList.Get(i);
			vPM = vPMListItem.Value;
			If vPM.IsCloseToTheRoom Then
				vPMList.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(SelFolio) Then
		i = 0;
		While i < vPMList.Count() Do
			vPMListItem = vPMList.Get(i);
			vPM = vPMListItem.Value;
			If vPM.IsCloseToTheFolio Then
				vPMList.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	i = 0;
	While i < vPMList.Count() Do
		vPMListItem = vPMList.Get(i);
		vPM = vPMListItem.Value;
		If vPM = Catalogs.PaymentMethods.AdvanceSettlement Or 
		   vPM = Catalogs.PaymentMethods.DepositTransfer Or 
		   vPM.IsForDeposits Or 
		   vPM.IsForReturnOnly Or 
		   vPM.IsViaInternetAcquiring Or
		   vPM.IsByBankTransfer Then
			vPMList.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	vByFolioPaymentMethod = GetByFolioPaymentMethod();
	vByRoomPaymentMethod = GetByRoomPaymentMethod();
	If ValueIsFilled(SelFolio) And (SelFolio.IsForDirectPostings Or ByFolioMode) And ValueIsFilled(vByFolioPaymentMethod) And 
	    vPMList.FindByValue(vByFolioPaymentMethod) <> Undefined Then
		SelPaymentMethod = vByFolioPaymentMethod;
	ElsIf ValueIsFilled(SelRoom) And ValueIsFilled(vByRoomPaymentMethod) And 
	    vPMList.FindByValue(vByRoomPaymentMethod) <> Undefined Then
		SelPaymentMethod = vByRoomPaymentMethod;
	ElsIf ValueIsFilled(SelHotel) And vPMList.FindByValue(SelHotel.PlannedPaymentMethod) <> Undefined Then
		SelPaymentMethod = SelHotel.PlannedPaymentMethod;
	ElsIf vPMList.Count() > 0 Then 
		SelPaymentMethod = vPMList.Get(0).Value;
	EndIf;
	Items.SelPaymentMethod.ChoiceList.LoadValues(vPMList.UnloadValues());
	// Add icons
	For Each vListItem In Items.SelPaymentMethod.ChoiceList Do
		vPM = vListItem.Value;
		If vPM.IsByCash Then
			vListItem.Picture = PictureLib.Coins;
		ElsIf vPM.IsByCreditCard Then
			vListItem.Picture = PictureLib.CreditCard16;
		ElsIf vPM.IsByBankTransfer Then
			vListItem.Picture = PictureLib.Customers;
		ElsIf vPM.IsByGiftCertificate Then
			vListItem.Picture = PictureLib.CalculationType;
		ElsIf vPM.IsByBonuses Then
			vListItem.Picture = PictureLib.AccumulationRegister;
		ElsIf vPM = Catalogs.PaymentMethods.Settlement Then
			vListItem.Picture = PictureLib.Customer;
		ElsIf vPM.IsCloseToTheFolio Then
			vListItem.Picture = PictureLib.Adult;
		ElsIf vPM.IsCloseToTheRoom Then
			vListItem.Picture = PictureLib.Rooms;
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
	vCashRegistersList = New ValueList();
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		vCashRegistersList = cmGetListOfAllCashRegisters(SelCompany);
	Else
		vCashRegistersList = cmGetListOfCashRegistersAllowed(SelCompany, SessionParameters.CurrentWorkstation);
	EndIf;
	// Attach list of cash registers to the form item
	Items.SelCashRegister.ChoiceList.LoadValues(vCashRegistersList.UnloadValues());
	If vCashRegistersList.Count() > 0 Then
		// Try to find cash register dedicated to the direct postings
		vDPCashRegister = Catalogs.CashRegisters.EmptyRef();
		For Each vCashRegistersListItem In vCashRegistersList Do
			vCashRegister = vCashRegistersListItem.Value;
			If ValueIsFilled(vCashRegister) And vCashRegister.UseForDirectPostings Then
				vDPCashRegister = vCashRegister;
				Break;
			EndIf;
		EndDo;
		SelCashRegister = vDPCashRegister;
	Else
		SelCashRegister = Catalogs.CashRegisters.EmptyRef();
	EndIf;
	SelCashRegisterOnChangeAtServer();
EndProcedure // FillListOfCashRegisters

// --------------------------------------------------------------------------------
&AtServer
Function CloseBill(pIsReturn = False, rTransArray, rDocsArray)
	vPaymentRef = Undefined;
	If ValueIsFilled(SelPaymentMethod) Then
		If BillPositions.Count() > 0 Then
			If SelPaymentMethod.IsCloseToTheRoom And Not ValueIsFilled(SelRoom) Then
				Raise NStr("en='Room is empty!'; ru='Номер не указан!'; de='Zimmer ist leer!'");
			EndIf;
			If SelPaymentMethod.IsCloseToTheFolio And Not ValueIsFilled(SelFolio) Then
				Raise NStr("en='Folio is empty!'; ru='Лицевой счет не указан!'; de='Folio ist leer!'");
			EndIf;
			rTransArray = New Array();
			Try
				BeginTransaction(DataLockControlMode.Managed);
				// Do charges to kiosk folio
				If Not SelPaymentMethod.IsCloseToTheRoom And Not SelPaymentMethod.IsCloseToTheFolio Then
					If ValueIsFilled(SelRoom) Or ValueIsFilled(SelFolio) Then
						vPaymentFolio = DoChargesToClientFolio(True, rTransArray, pIsReturn, rDocsArray);
						If ValueIsFilled(vPaymentFolio) Then
							SelFolio = vPaymentFolio;
						EndIf;
						If Not ValueIsFilled(SelFolio) Then
							Raise NStr("en='Failed to get folio to charge room service to!'; ru='Не удалось определить лицевой счет, на который выполнить начисление по номеру комнаты!'; de='Es war nicht möglich, das persönliche Konto zu ermitteln, auf das die Zimmernummer berechnet werden soll!'");
						EndIf;
					Else
						Raise NStr("en='Folio is empty!'; ru='Не удалось определить лицевой счет!'; de='Es war nicht möglich, das persönliche Konto zu ermitteln!'");
					EndIf;
				Else
					If ValueIsFilled(SelRoom) Or ValueIsFilled(SelFolio) Then
						vPaymentFolio = DoChargesToClientFolio(True, rTransArray, pIsReturn, rDocsArray);
						If ValueIsFilled(vPaymentFolio) Then
							SelFolio = vPaymentFolio;
						EndIf;
						If Not ValueIsFilled(SelFolio) Then
							Raise NStr("en='Failed to get folio to charge room service to!'; ru='Не удалось определить лицевой счет, на который выполнить начисление по номеру комнаты!'; de='Es war nicht möglich, das persönliche Konto zu ermitteln, auf das die Zimmernummer berechnet werden soll!'");
						EndIf;
					Else
						Raise NStr("en='Room should be filled!'; ru='Не указан номер комнаты!'; de='Zimmernummer ist leer!'");
					EndIf;
				EndIf;
				// Do payment
				If (Not SelPaymentMethod.IsCloseToTheRoom And Not SelPaymentMethod.IsCloseToTheFolio) Or 
				   ((SelPaymentMethod.IsCloseToTheRoom Or SelPaymentMethod.IsCloseToTheFolio) And SelPaymentMethod.BookByCashRegister) Then
					If pIsReturn Then
						vPaymentObj = Documents.Return.CreateDocument();
					Else
						vPaymentObj = Documents.Payment.CreateDocument();
						vPaymentObj.AdditionalProperties.Insert("AdvanceMode", False);
					EndIf;
					vPaymentObj.Hotel = SelHotel;
					vPaymentObj.Fill(SelFolio);
					vPaymentObj.Remarks = "";
					vPaymentObj.PaymentCurrency = SelFolio.FolioCurrency;
					vPaymentObj.PaymentMethod = SelPaymentMethod;
					vPaymentObj.CashRegister = SelCashRegister;
					vPaymentObj.DiscountCard = SelDiscountCard;
					// Payment sections
					If ValueIsFilled(vPaymentObj.Hotel) And vPaymentObj.Hotel.SplitFolioBalanceByPaymentSections Then
						vPaymentObj.PaymentSection = Catalogs.PaymentSections.EmptyRef();
						vPaymentObj.PaymentSections.Clear();
						vPSTable = New ValueTable();
						vPSTable.Columns.Add("PaymentSection", cmGetCatalogTypeDescription("PaymentSections"));
						vPSTable.Columns.Add("Amount", cmGetSumTypeDescription());
						vPSTable.Columns.Add("MarkingCode", cmGetStringTypeDescription(300));
						For Each vBPRow In BillPositions Do
							vPSTableRow = vPSTable.Add();
							vPSTableRow.PaymentSection = vBPRow.PaymentSection;
							vPSTableRow.Amount = vBPRow.Amount; 
							vPSTableRow.MarkingCode = vBPRow.MarkingCode; 
						EndDo;
						vPSTable.GroupBy("PaymentSection, MarkingCode", "Amount");
						For Each vPSTableRow In vPSTable Do
							vPSRow = vPaymentObj.PaymentSections.Add();
							vPSRow.PaymentSection = vPSTableRow.PaymentSection;
							vPSRow.Sum = vPSTableRow.Amount;
							vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, 
																			      vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, 
																			      vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
							If ValueIsFilled(vPSTableRow.PaymentSection) And ValueIsFilled(vPSTableRow.PaymentSection.VATRate) Then
								vPSRow.VATRate = vPSTableRow.PaymentSection.VATRate;
							Else
								vPSRow.VATRate = vPaymentObj.VATRate;
							EndIf;
							vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vPaymentObj.Date);
							vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, 
																			      vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, 
																			      vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
							vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vPaymentObj.Date);
							vPSRow.MarkingCode = vPSTableRow.MarkingCode; 
						EndDo;
						vPaymentObj.pmCalculateTotalsByPaymentSections();
					ElsIf ValueIsFilled(vPaymentObj.Hotel) And vPaymentObj.Hotel.SplitFolioBalanceByServicesAndPrices Then
						vPaymentObj.PaymentSection = Catalogs.PaymentSections.EmptyRef();
						vPaymentObj.PaymentSections.Clear();
						vPSTable = New ValueTable();
						vPSTable.Columns.Add("Service", cmGetCatalogTypeDescription("Services"));
						vPSTable.Columns.Add("PaymentSection", cmGetCatalogTypeDescription("PaymentSections"));
						vPSTable.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
						vPSTable.Columns.Add("Price", cmGetSumTypeDescription());
						vPSTable.Columns.Add("Amount", cmGetSumTypeDescription());
						vPSTable.Columns.Add("Quantity", cmGetNumberTypeDescription(19, 7));
						vPSTable.Columns.Add("MarkingCode", cmGetStringTypeDescription(300));
						For Each vBPRow In BillPositions Do
							vPSTableRow = vPSTable.Add();
							vPSTableRow.PaymentSection = vBPRow.PaymentSection;
							vPSTableRow.Service = vBPRow.Service;
							vPSTableRow.VATRate = vBPRow.VATRate;
							vPSTableRow.Price = vBPRow.Price;
							vPSTableRow.Amount = vBPRow.Amount;
							vPSTableRow.Quantity = vBPRow.Quantity;
							vPSTableRow.MarkingCode = vBPRow.MarkingCode;
						EndDo;
						vPSTable.GroupBy("PaymentSection, Service, VATRate, Price, MarkingCode", "Amount, Quantity");
						For Each vPSTableRow In vPSTable Do
							vPSRow = vPaymentObj.PaymentSections.Add();
							vPSRow.PaymentSection = vPSTableRow.Service.PaymentSection;
							vPSRow.ChequeService = vPSTableRow.Service;
							vPSRow.ChequeServicePrice = vPSTableRow.Price;
							vPSRow.ChequeServiceQuantity = vPSTableRow.Quantity;
							vPSRow.Sum = vPSTableRow.Amount;
							vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, 
																			      vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, 
																			      vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
							If ValueIsFilled(vPSTableRow.VATRate) Then
								vPSRow.VATRate = vPSTableRow.VATRate;
							ElsIf ValueIsFilled(vPSTableRow.PaymentSection) And ValueIsFilled(vPSTableRow.PaymentSection.VATRate) Then
								vPSRow.VATRate = vPSTableRow.PaymentSection.VATRate;
							Else
								vPSRow.VATRate = vPaymentObj.VATRate;
							EndIf;
							vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vPaymentObj.Date);
							vPSRow.SumInFolioCurrency = Round(cmConvertCurrencies(vPSRow.Sum, vPaymentObj.PaymentCurrency, vPaymentObj.PaymentCurrencyExchangeRate, 
																			      vPaymentObj.FolioCurrency, vPaymentObj.FolioCurrencyExchangeRate, 
																			      vPaymentObj.ExchangeRateDate, vPaymentObj.Hotel), 2);
							vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, vPaymentObj.Date);
							vPSRow.MarkingCode = vPSTableRow.MarkingCode;
						EndDo;
						vPaymentObj.pmCalculateTotalsByPaymentSections();
					Else
						vPaymentObj.PaymentSection = SelFolio.PaymentSection;
						vPaymentObj.Sum = BillTotalAmount;
						vPaymentObj.pmRecalculateSums();
					EndIf;
					// Reference and authorization codes
					vPaymentObj.ReferenceNumber = "";
					vPaymentObj.AuthorizationCode = "";
					// Payment remarks
					vPaymentObj.SlipText = "";
					// External system payment code
					vPaymentObj.ExternalCode = "";
					// Set customer as payer
					If ValueIsFilled(vPaymentObj.AccountingCustomer) And ValueIsFilled(vPaymentObj.PaymentMethod) And vPaymentObj.PaymentMethod.IsByBankTransfer Then
						If ValueIsFilled(vPaymentObj.Hotel) And vPaymentObj.AccountingCustomer <> vPaymentObj.Hotel.IndividualsCustomer Then
							vPaymentObj.Payer = vPaymentObj.AccountingCustomer;
						EndIf;
					EndIf;
					// Post payment
					vPaymentObj.Write(DocumentWriteMode.Posting);
					vPaymentRef = vPaymentObj.Ref;
					// Add document to the operation documents array
					rDocsArray.Add(vPaymentRef);
				EndIf;
				// Commit transaction
				CommitTransaction();
			Except
				vErrorInfo = ErrorInfo();
				If TransactionActive() Then
					RollbackTransaction();
				EndIf;
				Raise cmGetRootErrorDescription(vErrorInfo);
			EndTry;
		Else
			Raise NStr("en='There is no lines in the ticket!'; ru='В заказе нет позиций!'; de='Es sind keine Artikel in der Bestellung!'");
		EndIf;
	Else
		Raise NStr("en='Payment method is empty!'; ru='Не выбран способ оплаты!'; de='Keine Zahlungsmethode ausgewählt!'");
	EndIf;
	Return vPaymentRef;
EndFunction // CloseBill

// -----------------------------------------------------------------------------
&AtServer
Function DoChargesToClientFolio(pDoNotCheckCreditLimit = False, pTransArray = Undefined, pIsReturn = False, pDocsArray)
	vRoomServiceRef = Undefined;
	If BillPositions.Count() > 0 Then
		For Each vRow In BillPositions Do
			If ValueIsFilled(vRow.Service) Then
				vCharge = Undefined;
				If ValueIsFilled(SelFolio) Then
					vErrorText = cmChargeExternalServiceByFolio(TrimAll(SelFolio.Number), TrimAll(vRow.Service.Code), ?(pIsReturn, -vRow.Amount, vRow.Amount), ?(pIsReturn, -vRow.Quantity, vRow.Quantity), "", "", TrimAll(SelHotel.Code), "", TrimAll(SelFolio.FolioCurrency.Code), ?(ValueIsFilled(vRow.VATRate), vRow.VATRate.TaxRate, Undefined), , , pDoNotCheckCreditLimit, vCharge, ?(ValueIsFilled(SelClientType), Trimall(SelClientType.Code), ""));
					If ValueIsFilled(vCharge) Then
						pTransArray.Add(vCharge);
						pDocsArray.Add(vCharge);
					EndIf;
				ElsIf ValueIsFilled(SelRoom) Then
					vErrorText = cmChargeRoomService(TrimAll(SelRoom.Description), CurrentSessionDate(), ?(pIsReturn, -vRow.Amount, vRow.Amount), TrimAll(SelClient.Code), TrimAll(?(ValueIsFilled(SelFolio), SelFolio.FolioCurrency.Code, SelHotel.FolioCurrency.Code)), TrimAll(vRow.Service.Code), ?(pIsReturn, -vRow.Quantity, vRow.Quantity), , , , TrimAll(SelHotel.Code), , ?(ValueIsFilled(vRow.VATRate), vRow.VATRate.TaxRate, Undefined), "", vRoomServiceRef, , , pDoNotCheckCreditLimit, , ?(ValueIsFilled(SelClientType), Trimall(SelClientType.Code), ""));
					If ValueIsFilled(vRoomServiceRef) Then
						vCharge = GetChargeByRoomService(vRoomServiceRef);
						If ValueIsFilled(vCharge) Then
							pTransArray.Add(vCharge);
							pDocsArray.Add(vCharge);
						EndIf;
					EndIf;
				EndIf;	                     
				If ValueIsFilled(vCharge) Then
					vChargeObj = vCharge.GetObject();
					vChargeObj.MarkingCode = vRow.MarkingCode;
					vChargeObj.MarkingCodeCheckUUID = vRow.MarkingCodeCheckUUID;
					vChargeObj.MarkingCodeCheckDate = vRow.MarkingCodeCheckDate;
					vChargeObj.Write(DocumentWriteMode.Posting);
				EndIf;
				If Not IsBlankString(vErrorText) And (Not pDoNotCheckCreditLimit Or Not ValueIsFilled(vCharge)) Then
					Raise vErrorText;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If ValueIsFilled(vRoomServiceRef) Then
		Return vRoomServiceRef.Folio;
	Else
		Return Undefined;
	EndIf;
EndFunction // DoChargesToClientFolio

// -----------------------------------------------------------------------------
&AtServer
Function GetChargeByRoomService(pRoomService)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charge.Ref AS Ref
	|FROM
	|	Document.Charge AS Charge
	|WHERE
	|	Charge.Posted
	|	AND Charge.ParentRoomService = &qRoomService";
	vQry.SetParameter("qRoomService", pRoomService);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		Return vDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetChargeByRoomService

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetReceipt(pFolio, pLanguage, pTransArray, pFormPrintSettings)
	vOperationName = "en='Receipt'; ru='Квитанция'; de='Quittung'";
	vCompanyObj = pFolio.Company.GetObject();
	vDocRef = pTransArray.Get(0);
	
	vTotal = 0;
	
	vReceipt = New TextDocument();
	
	vReceiptTemplateName = "Receipt" + Format(pFormPrintSettings.ReceiptWidth, "ND=2; NFD=0; NZ=; NLZ=; NG=");
	vReceiptTemplate = Documents.Folio.GetTemplate(vReceiptTemplateName);
	
	vTextReceiptTemplateName = vReceiptTemplateName + TrimAll(pLanguage.Code);
	vTextReceiptTemplate = Documents.Folio.GetTemplate(vTextReceiptTemplateName);
	
	vReceiptHeaderArea = vTextReceiptTemplate.GetArea("ReceiptHeader");
	vReceiptHeaderArea.Parameters.Company = vCompanyObj.pmGetCompanyPrintName(pLanguage);
	vReceiptHeaderArea.Parameters.Address = vCompanyObj.pmGetCompanyPostAddressPresentation(pLanguage);
	vReceiptHeaderArea.Parameters.Codes = vCompanyObj.pmGetCompanyIdentificationCodes(pLanguage);
	vReceiptHeaderArea.Parameters.Operation = Upper(cmNStr(vOperationName, pLanguage));
	vReceiptHeaderArea.Parameters.ReceiptN = cmGetDocumentNumberPresentation(vDocRef.Number);
	vReceiptHeaderArea.Parameters.Cashier = TrimAll(SessionParameters.CurrentUser);
	vReceiptHeaderArea.Parameters.Date = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	vReceiptHeaderArea.Parameters.Time = Format(CurrentSessionDate(), "DF=HH:mm:ss");
	vReceipt.Put(vReceiptHeaderArea);
	
	For Each vDocRef In pTransArray Do
		If TypeOf(vDocRef) = Type("DocumentRef.Charge") Then
			vRowSum = vDocRef.Sum - vDocRef.DiscountSum;
			vReceiptDebitRowArea = vTextReceiptTemplate.GetArea("ReceiptDebitRow");
			vReceiptDebitRowArea.Parameters.OperationDescription = vDocRef.Service.GetObject().pmGetServiceDescription(pLanguage);
			If Not IsBlankString(vDocRef.Remarks) Then
				vReceiptDebitRowArea.Parameters.OperationDescription = vReceiptDebitRowArea.Parameters.OperationDescription + " - " + TrimAll(vDocRef.Remarks);
			EndIf;
			vReceiptDebitRowArea.Parameters.Quantity = Format(vDocRef.Quantity, "NFD=3; NZ=");
			vReceiptDebitRowArea.Parameters.Amount = Format(vRowSum, "NFD=2; NZ=");
			vReceiptDebitRowArea.Parameters.Price = Format(Round(vRowSum/?(vDocRef.Quantity = 0, 1, vDocRef.Quantity), 2), "NFD=2; NZ=");
			vReceipt.Put(vReceiptDebitRowArea);
			vTotal = vTotal + vRowSum;
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.Storno") Then
			vChargeRef = vDocRef.ParentCharge;
			vRowSum = -(vChargeRef.Sum - vChargeRef.DiscountSum);
			vReceiptDebitRowArea = vTextReceiptTemplate.GetArea("ReceiptDebitRow");
			vReceiptDebitRowArea.Parameters.OperationDescription = cmNStr("en='Cancel '; ru='Сторно '; de='Stornierung '", pLanguage) + " " + 
			                                                       vChargeRef.Service.GetObject().pmGetServiceDescription(pLanguage);
			vReceiptDebitRowArea.Parameters.Quantity = Format(vChargeRef.Quantity, "NFD=3; NZ=");
			vReceiptDebitRowArea.Parameters.Amount = Format(vRowSum, "NFD=2; NZ=");
			vReceiptDebitRowArea.Parameters.Price = Format(Round(?(vRowSum < 0, -vRowSum, vRowSum)/?(vDocRef.Quantity = 0, 1, ?(vDocRef.Quantity < 0, -vDocRef.Quantity, vDocRef.Quantity)), 2), "NFD=2; NZ=");
			vReceipt.Put(vReceiptDebitRowArea);
			vTotal = vTotal + vRowSum;
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.Payment") Then
			vReceiptCreditRowArea = vTextReceiptTemplate.GetArea("ReceiptCreditRow");
			vReceiptCreditRowArea.Parameters.OperationDescription = vDocRef.PaymentMethod.GetObject().pmGetPaymentMethodDescription(pLanguage);
			If Not IsBlankString(vDocRef.Remarks) Then
				vReceiptCreditRowArea.Parameters.OperationDescription = vReceiptCreditRowArea.Parameters.OperationDescription + " - " + TrimAll(vDocRef.Remarks);
			EndIf;
			vReceiptCreditRowArea.Parameters.Amount = Format(vDocRef.Sum, "NFD=2; NZ=");
			vReceipt.Put(vReceiptCreditRowArea);
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.Return") Then
			vReceiptCreditRowArea = vTextReceiptTemplate.GetArea("ReceiptCreditRow");
			vReceiptCreditRowArea.Parameters.OperationDescription = cmNStr("en='Refund '; ru='Возврат '; de='Rückzahlung '", pLanguage) + " " + 
			                                                        vDocRef.PaymentMethod.GetObject().pmGetPaymentMethodDescription(pLanguage);
			vReceiptCreditRowArea.Parameters.Amount = Format(-vDocRef.Sum, "NFD=2; NZ=");
			vReceipt.Put(vReceiptCreditRowArea);
		ElsIf TypeOf(vDocRef) = Type("DocumentRef.DepositTransfer") Then
			vReceiptCreditRowArea = vTextReceiptTemplate.GetArea("ReceiptCreditRow");
			vReceiptCreditRowArea.Parameters.OperationDescription = vDocRef.PaymentMethod.GetObject().pmGetPaymentMethodDescription(pLanguage);
			If pFolio = vDocRef.FolioFrom Then
				vReceiptCreditRowArea.Parameters.Amount = Format(-vDocRef.SumInFolioFromCurrency, "NFD=2; NZ=");
			Else
				vReceiptCreditRowArea.Parameters.Amount = Format(vDocRef.SumInFolioToCurrency, "NFD=2; NZ=");
			EndIf;
			vReceipt.Put(vReceiptCreditRowArea);
		EndIf;
	EndDo;
		
	vReceiptTotalArea = vTextReceiptTemplate.GetArea("ReceiptTotal");
	vReceiptTotalArea.Parameters.TotalAmount = Format(vTotal, "NFD=2; NZ=");
	vReceipt.Put(vReceiptTotalArea);
		
	vReceiptFooterText = cmNStr(pFormPrintSettings.FooterText, pLanguage);
	vReceiptFooterArray = cmGetTextLinesArray(vReceiptFooterText);
	For Each vReceiptFooterStr In vReceiptFooterArray Do
		vReceiptFooterArea = vTextReceiptTemplate.GetArea("ReceiptFooter");
		If ValueIsFilled(pFolio.Client) Then
			vReceiptFooterArea.Parameters.Client = TrimAll(pFolio.Client.FullName);
		Else
			vReceiptFooterArea.Parameters.Client = "";
		EndIf;
		If ValueIsFilled(pFolio.Room) Then
			vReceiptFooterArea.Parameters.Room = TrimAll(pFolio.Room.Description);
		Else
			vReceiptFooterArea.Parameters.Room = "";
		EndIf;
		vReceiptFooterArea.Parameters.FooterText = vReceiptFooterStr;
		vReceipt.Put(vReceiptFooterArea);
	EndDo;
	
	vReceiptText = vReceipt.GetText();
	vTextRowsArray = cmGetTextLinesArray(vReceiptText);
	
	vReceiptSpreadsheet = New SpreadsheetDocument();
	vReceiptSpreadsheet.FitToPage = True;
	vReceiptSpreadsheet.LeftMargin = 0;
	vReceiptSpreadsheet.RightMargin = 0;
	For Each vTextRow In vTextRowsArray Do
		vReceiptRowArea = vReceiptTemplate.GetArea("ReceiptRow");
		vReceiptRowArea.Parameters.RowText = vTextRow;
		vReceiptSpreadsheet.Put(vReceiptRowArea);
	EndDo;
	
	vTempAddress = PutToTempStorage(vReceiptSpreadsheet);
	
	Return vTempAddress;
EndFunction // GetReceipt

// -----------------------------------------------------------------------------
&AtServer
Function NeedToPrintReceipt(rPrtForm)
	rPrtForm = Catalogs.ObjectPrintingForms.FolioPrintNonFiscalChequeByCharges;
	If rPrtForm.IsActive Then
		Return True;
	EndIf;
	Return False;
EndFunction // NeedToPrintReceipt

// -----------------------------------------------------------------------------
&AtServer
Function GetReceiptPrintSettings(pPrtForm)
	vWidth = 30;
	If ValueIsFilled(pPrtForm) And Not IsBlankString(pPrtForm.Parameter) And cmIsNumber(TrimAll(pPrtForm.Parameter)) Then
		vWidth = Number(TrimAll(pPrtForm.Parameter));
	EndIf;
	vFormPrintSettings = New Structure("ReceiptWidth, FooterText, CashRegister, PrintDirection, PrinterName, FitToPage, PrintScale, Copies, CopiesPerPage, Collate, PageOrientation, PageSize, TopMargin, BottomMargin, LeftMargin, RightMargin, HeaderSize, FooterSize, BlackAndWhite, DuplexPrintingType", 
	                                   vWidth, ?(IsBlankString(pPrtForm.FormText), "en='All taxes included'; ru='Все налоги включены'; de='Alle Steuern inklusive!'", TrimR(pPrtForm.FormText)), Undefined, Undefined, "", True, 0, 1, 1, False, Undefined, "", 0, 0, 0, 0, 0, 0, False, Undefined);
	vFormPrintSettings.CashRegister = SelCashRegister;
	vWstnSettings = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vWstnSettings) And ValueIsFilled(vWstnSettings.WorkstationPrintSettings) Then
		vWstnPrintSettings = vWstnSettings.WorkstationPrintSettings;
		vPrtFrmSettingsRow = vWstnPrintSettings.PrintFormsList.Find(pPrtForm, "ObjectPrintingForm");
		If vPrtFrmSettingsRow <> Undefined And vPrtFrmSettingsRow.IsActive Then
			FillPropertyValues(vFormPrintSettings, vPrtFrmSettingsRow);
		EndIf;
	EndIf;
	Return vFormPrintSettings;
EndFunction // GetReceiptPrintSettings

// --------------------------------------------------------------------------------
&AtClient
Procedure ComplimentaryFolioCheckAfterAnswer(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		ComplimentaryFolioIsChecked = True;
		WriteActionConfirmed(pUserAnswer, pExtraParams);
	EndIf;
EndProcedure // ComplimentaryFolioCheckAfterAnswer

// --------------------------------------------------------------------------------
&AtClient
Procedure WriteActionConfirmed(pReply, pExtraParams) Export
	If pReply <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	vExternalSystem = PredefinedValue("Catalog.ExternalSystemInteractions.EmptyRef");
	If ValueIsFilled(SelPaymentMethod) Then
		vExternalSystem = tcOnServer.cmGetAttributeByRef(SelPaymentMethod, "ExternalSystem");
		If ValueIsFilled(vExternalSystem) And tcOnServer.cmGetAttributeByRef(vExternalSystem, "IntegrationType") = PredefinedValue("Enum.Integrations.QRCodePaySberbank") Then
			If OperationType = 1 And tcOnServer.cmGetAttributeByRef(SelPaymentMethod, "IsByCreditCard") Then
				ShowMessageBox(, NStr("en = 'A refund on a payment made using a QR code (SBP) can only be made from the folio of the payment!'; de = 'Eine Rückerstattung einer Zahlung, die mit einem QR-Code (SBP) getätigt wurde, kann nur aus dem Personenkonten der Zahlung erfolgen!'; ru = 'Возврат по платежу проведенному по QR коду (СБП) можно выполнить только из лицевого счета платежа!'"));
				If pExtraParams <> Undefined Then
					CancelOperationDocuments(pExtraParams.DocsArray);	
				EndIf;
				Return;
			EndIf; 
		EndIf; 
	EndIf;
	// Do some extra checks
	If Not ComplimentaryFolioIsChecked And ValueIsFilled(SelFolio) Then
		If tcOnServer.cmGetAttributeByRef(SelFolio, "IsComplimentary") Then
			If BillPositions.Total("Amount") > 0 Then
				ShowQueryBox(New NotifyDescription("ComplimentaryFolioCheckAfterAnswer", ThisObject, pExtraParams), 
				             NStr("en='You are going to charge fully complimentary folio with amount that is not zero! Do you want to continue?'; 
							      |ru='Собираетесь выполнить не нулевое начисление на бесплатный лицевой счет! Продолжить операцию?'; 
								  |de='Sie sind dabei, keine null-Gebühr auf ein kostenloses Konto durchzuführen! Operation fortsetzen?'"), 
							 QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
				Return;
			EndIf;
		EndIf;
	EndIf;   
	// Get credit cards processing system
	vPaymentMethodArr = Undefined;
	If ValueIsFilled(SelPaymentMethod) And Not ValueIsFilled(vExternalSystem) Then
		vPaymentMethodArr = tcOnServer.cmGetAtributeAsArray(SelPaymentMethod);
		If CreditCardProcessingSystem.IsEmpty() And vPaymentMethodArr.IsByCreditCard Then
			vTempArr = GetCreditCardProcessingSystem();
			If vTempArr.Count() > 1 Then
				pCancel = True;
				vParams = New Structure("Arr, ExtraParams", vTempArr, pExtraParams);
				OpenForm("CommonForm.tcCreditCardProcessingSystemChoiceForm", vParams, ThisObject, UUID);
				Return;
			ElsIf vTempArr.Count() = 1 Then
				CreditCardProcessingSystem = vTempArr[0];
			EndIf; 
		EndIf;
	EndIf;
	// Process ticket
	vCancel = False;
	vMessage = "";
	vChequePrintCalled = False;
	// Do operation at server
	If pExtraParams <> Undefined Then
		vTransArray = pExtraParams.TransArray;
		vDocsArray = pExtraParams.DocsArray;
		vPaymentRef = pExtraParams.PaymentRef; 
	Else
		vTransArray = New Array();
		vDocsArray = New Array();
		vPaymentRef = CloseBill(?(OperationType = 0, False, True), vTransArray, vDocsArray); 
	EndIf;
	// Save last used folio and transactions
	LastFolio = SelFolio;
	LastTransactions.Clear();
	For Each vDocsArrayItem In vDocsArray Do
		LastTransactions.Add(vDocsArrayItem);
	EndDo;
	If Items.PrintLastBill.Visible Then
		Items.PrintLastBill.Enabled = True;
	EndIf;
	// Print cheque
	If ValueIsFilled(SelCashRegister) And ValueIsFilled(SelPaymentMethod) And ValueIsFilled(vPaymentRef) Then
		vPaymentMethodAttr = tcOnServer.cmGetAtributeAsArray(SelPaymentMethod);
		vCashRegisterAttr = tcOnServer.cmGetAtributeAsArray(SelCashRegister);
		vPaymentAttr = tcOnServer.cmGetAtributeAsArray(vPaymentRef);
		// Check if it is possible to print cheque
		If vPaymentMethodAttr.BookByCashRegister And vPaymentMethodAttr.PrintCheque And vCashRegisterAttr.IsControlledByProgram Then
			If vPaymentAttr.Sum <> 0 Then
				vMessage = "";
				If Not IsReadyToPrintCheque(vMessage) Then
					vCancel = True;
					ShowMessageBox(, vMessage);
					CancelOperationDocuments(vDocsArray);
				EndIf;
			EndIf;
		EndIf;
		// Process payment by the credit card processing system
		If Not vCancel And vPaymentMethodAttr.IsByCreditCard Then
			If ValueIsFilled(vExternalSystem) Then 
				If Not ValueIsFilled(vPaymentAttr.ReferenceNumber) And Not ValueIsFilled(vPaymentAttr.AuthorizationCode) Then
					If Not ValueIsFilled(vPaymentAttr.OrderID) And Not ValueIsFilled(vPaymentAttr.OrderURL) Then
						If Not fmStartCreditCardExternalPayment(vExternalSystem, vPaymentAttr) Then
							CancelOperationDocuments(vDocsArray);
							Return;		
						EndIf; 
						FillPaymentByQRCodePayment(vPaymentAttr, vPaymentRef);
					EndIf;
					// Call procedure to save payment to the database
					vExtraParams = New Structure("TransArray, DocsArray, PaymentRef", vTransArray, vDocsArray, vPaymentRef);
					OpenForm("CommonForm.tcQRCodePaymentForm", New Structure("SelPayment, SelExternalSystem", vPaymentRef, vExternalSystem), ThisObject, UUID,,, New NotifyDescription("AfterCloseQRCodePaymentForm", ThisObject, vExtraParams), FormWindowOpeningMode.LockWholeInterface);
					Return;
				Else
					PaymentIsAuthorized = True;	
				EndIf;	
			ElsIf Not vPaymentMethodAttr.ExternalBankTerminalIsUsed Then
				// If payment was earlier authorized manually (reference number is filled) or automatically then skip this step
				If Not PaymentIsAuthorized Then
					If CheckCreditCardsProcessingSystem() Then
						If Not AuthorizePayment(vPaymentAttr, vMessage) Then
							vCancel = True;
							vMessage = tcOnServer.cmNStrAtServer(vMessage);
							ShowMessageBox(, vMessage);
							CancelOperationDocuments(vDocsArray);
						Else
							FillPaymentByAuthorizePayment(vPaymentAttr, vPaymentRef); 
							PaymentIsAuthorized = True;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Print cheque at cash register
		If Not vCancel And vPaymentMethodAttr.BookByCashRegister And vPaymentMethodAttr.PrintCheque And vCashRegisterAttr.IsControlledByProgram Then
			If vPaymentAttr.Sum <> 0 Then
				vChequePrintCalled = True;
				// Print cheque at cash register
				StartPrintCheque(vPaymentRef, vPaymentAttr, vPaymentMethodAttr, vMessage, vCancel, vDocsArray);
				If vCancel Then
					If Not IsBlankString(vMessage) Then
						vMessage = tcOnServer.cmNStrAtServer(vMessage);
						ShowMessageBox(, vMessage);
						CancelOperationDocuments(vDocsArray);
					EndIf;
				EndIf;	
			Else
				vCancel = True;
				vMessage = NStr("en='Bill amount is zero!';ru='Сумма заказа равна нулю!';de='Bestellsumme ist null!'");
				ShowMessageBox(, vMessage);
			EndIf;
		EndIf;
	EndIf;
	// Check if we need to print recipt on a windows printer
	vPrtForm = Undefined;
	If IsBlankString(vMessage) And Not vChequePrintCalled Then
		If NeedToPrintReceipt(vPrtForm) Then
			vFormPrintSettings = GetReceiptPrintSettings(vPrtForm);
			If vFormPrintSettings <> Undefined Then
				If Not IsBlankString(vFormPrintSettings.PrinterName) Then
					// Print receipt on windows printer
					vBatch = New RepresentableDocumentBatch();
					
					vReceiptAddress = GetReceipt(SelFolio, tcOnServer.cmGetSessionParametersAttribute("CurrentLanguage"), vTransArray, vFormPrintSettings);
					vBatch.Content.Add(vReceiptAddress);
					
					vBatch.Collate = vFormPrintSettings.Collate;
					vBatch.Copies = ?(vFormPrintSettings.Copies = 0, Undefined, vFormPrintSettings.Copies);
					vBatch.PrinterName = TrimAll(vFormPrintSettings.PrinterName);
					
					vBatch.Print(?(IsBlankString(TrimAll(vFormPrintSettings.PrinterName)), PrintDialogUseMode.Use, PrintDialogUseMode.DontUse));
				Else
					If ValueIsFilled(SelCashRegister) And ValueIsFilled(SelFolio) Then
						vCashRegisterAttr = tcOnServer.cmGetAtributeAsArray(SelCashRegister);
						If vCashRegisterAttr.IsControlledByProgram Then
							vDriver = tcOnClient.cmGetModulTO(SelCashRegister);
							If Not vDriver = Undefined Then
								vChequeSum = 0;
								vVATRate = Undefined;
								vFolioCurrency = tcOnServer.cmGetAttributeByRef(SelFolio, "FolioCurrency");
								vAuthor = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
								vLanguage = tcOnServer.cmGetSessionParametersAttribute("CurrentLanguage");
								
								// Cheque template
								vChequeText = 
								Upper(NStr("en='Folio charges'; ru='Начисление на лицевой счет'; de='Persönlichen Konto aufladen'")) + "
								|&CurrentDate &CurrentTime
								|&Cashier
								|&FolioHeader
								|--------------------------------------------------------------------------------
								|" + Upper(NStr("en='Services:'; ru='Услуги:'; de='Dienstleistungen:'"));
								For Each vTransRow In vTransArray Do
									vRowSum = 0;
									vRowTxt = GetChequeRowAtServer(vTransRow, SelFolio, vLanguage, vRowSum, vVATRate);
									vChequeText = vChequeText + Chars.LF + vRowTxt;
									
									vChequeSum = vChequeSum + vRowSum;
								EndDo;
								vChequeText = vChequeText + Chars.LF + "--------------------------------------------------------------------------------";
								If vChequeSum <> 0 Then
									vChequeText = vChequeText + Chars.LF + NStr("en='TOTAL '; ru='ИТОГО '; de='TOTAL '") + Format(vChequeSum, "NFD=2") + " &Currency";
								EndIf;
								vChequeText = vChequeText + Chars.LF + "&Cliche";
								
								vMessage = "";
								vStruct = New Structure("Sum, VATSum, CashRegister, Folio, VATRate, Author, PaymentCurrency", vChequeSum, 0, SelCashRegister, SelFolio, vVATRate, vAuthor, vFolioCurrency);
								If Not vDriver.pmPrintNonFiscalCheque(vStruct.Sum, vStruct.VATSum, vStruct, vChequeText, vMessage) Then
									ShowMessageBox(, vMessage);
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Print folio transactions
	vPrintBillForm = PredefinedValue("Catalog.ObjectPrintingForms.DirectPostingsPrintChargedTransactions");
	If ValueIsFilled(vPrintBillForm) Then
		vPrintBillFormAttrs = tcOnServer.cmGetAtributeAsArray(vPrintBillForm);
		If vPrintBillFormAttrs.IsActive And vPrintBillFormAttrs.AutomaticallyPrintOnFirstObjectWrite Then
			PrintLastBill(Commands.PrintLastBill);
		EndIf;
	EndIf;
	// Check success
	If Not vCancel Then
		// Clear services
		NewBillAction(Commands.NewBillAction);
		// Reset flags
		PaymentIsAuthorized = False;
		ChequeIsPrinted = False;
		// Do message
		ShowMessageBox(, NStr("en='Success!'; de='Erfolg!'; ru='Успешно!'"), 1);
		// Send folio refresh message
		Notify("Document.Folio.Edit");
	EndIf;
EndProcedure // WriteActionConfirmed

// -----------------------------------------------------------------------------
&AtServer
Function fmStartCreditCardExternalPayment(pExternalSystem, rPaymentAttr)
	vDP = pExternalSystem.DataProcessor;
	
	If Not ValueIsFilled(vDP) Then
		Raise Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
	EndIf;	
	
	vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
	
	If vDPO = Undefined Then
		Raise Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");			
	EndIf;
	
	vMessage = "";
	If Not vDPO.StartExternalPayment(rPaymentAttr, vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
		Return False;
	 EndIf;
	                             
	Return True;
EndFunction // StartCreditCardExternalPayment

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPaymentByAuthorizePayment(pAuthorize, pPayment)
	vObj = pPayment.GetObject();
	vObj.AuthorizationCode = pAuthorize.AuthorizationCode;
	vObj.ReferenceNumber = pAuthorize.ReferenceNumber;
	vObj.SlipText = pAuthorize.SlipText;
	If TypeOf(vObj) = Type("DocumentObject.Payment") Or TypeOf(vObj) = Type("DocumentObject.CustomerPayment") Then 
		vObj.AnnulationSlipText = pAuthorize.AnnulationSlipText;
	EndIf;
	vObj.TerminalNumber = pAuthorize.TerminalNumber;
	vObj.CreditCard = pAuthorize.CreditCard;
	vObj.CardType = pAuthorize.CardType;
	vObj.PANLast4Digits = pAuthorize.PANLast4Digits;
	vObj.Write(DocumentWriteMode.Posting);
EndProcedure // FillPaymentByAuthorizePayment

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPaymentByQRCodePayment(pPaymentAttr, pPayment)
	vObj = pPayment.GetObject();
	vObj.OrderID = pPaymentAttr.OrderID; 
	vObj.OrderURL = pPaymentAttr.OrderURL;
	vObj.Write(DocumentWriteMode.Posting);
EndProcedure // FillPaymentByAuthorizePayment

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCloseQRCodePaymentForm(pResult, pExtraParams) Export 
	If pResult <> Undefined Then
		If pResult Then
			If ValueIsFilled(tcOnServer.cmGetAttributeByRef(pExtraParams.PaymentRef, "ReferenceNumber")) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(pExtraParams.PaymentRef, "AuthorizationCode")) Then 
				WriteActionConfirmed(DialogReturnCode.Yes, pExtraParams);					
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Reference number and authorization code are not filled in'; de = 'Referenznummer und Autorisierungscode sind nicht ausgefüllt'; ru = 'Референс номер и код авторизации не заполнены'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // AfterCloseQRCodePaymentForm

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function CheckMarkingCode(pMarkingCode)
	vQuery = New Query;
	vQuery.Text = "SELECT
	|	Charge.Ref AS Ref,
	|	Storno.Ref AS Storno
	|FROM
	|	Document.Charge AS Charge
	|		LEFT JOIN Document.Storno AS Storno
	|		ON (Storno.ParentCharge = Charge.Ref)
	|WHERE
	|	Charge.MarkingCode = &qMarkingCode
	|	AND Charge.DeletionMark = FALSE
	|	AND Charge.Posted = TRUE
	|	AND Storno.Number IS NULL";
	
	vQuery.SetParameter("qMarkingCode", pMarkingCode);
	
	vQueryResult = vQuery.Execute();
	If vQueryResult.IsEmpty() Then
		Return Undefined;
	Else	
		vRes = vQueryResult.Select();
		vRes.Next();
		Return vRes.Ref;
	EndIf;
EndFunction // CheckMarkingCode

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetChequeRowAtServer(pRowData, pFolio, pLanguage, rSum, rVATRate)
	vTxt = "";
	rSum = 0;
	rVATRate = pRowData.VATRate;
	rSum = pRowData.Sum;
	vTxt = pRowData.Service.GetObject().pmGetServiceDescription(pLanguage) + 
	       " x " + Format(pRowData.Quantity, "NFD=3; NZ=; NG=") + 
	       " = " + Format(rSum, "NFD=2");
	Return vTxt;
EndFunction // GetChequeRowAtServer
	
// -----------------------------------------------------------------------------
&AtClient
Procedure StartPrintCheque(pPaymentRef, pPaymentObj, pPaymentMethodObj, rMessage, pCancel, pDocsArray)
	vDriver = tcOnClient.cmGetModulTO(SelCashRegister);
	If Not vDriver = Undefined Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, SelCashRegister);
		vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
		                  |de='Input cash register password please...';
		                  |en='Eingabe des Kassenpasswortes bitte...'");
		If IsBlankString(vPasswordKKM) Then
			// Break before write event and ask user to input cash register password
			pCancel = True;
			vNotify = New NotifyDescription("AfterInputCashRegisterPassword", ThisObject, New Structure("PaymentRef, PaymentObj, PaymentMethodObj, Driver, rMessage, DocsArray", pPaymentRef, pPaymentObj, pPaymentMethodObj, vDriver, rMessage, pDocsArray));
			OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion), ThisObject, , , , vNotify);
			// Attach idle handler to close form when cheque will be printed
			AttachIdleHandler("NewTicketAfterChequeWasPrinted", 1, False);
		Else
			If pPaymentMethodObj.PrintNonFiscalCheque Then
				vChequeTemplate = TrimAll(pPaymentMethodObj.NonFiscalChequeTemplate);
				If Not IsBlankString(vChequeTemplate) Then
					ChequeIsPrinted = vDriver.pmPrintNonFiscalCheque(?(OperationType = 0, pPaymentObj.Sum, -pPaymentObj.Sum), ?(OperationType = 0, pPaymentObj.VATSum, -pPaymentObj.VATSum), pPaymentObj, vChequeTemplate, rMessage, vPasswordKKM);
				Else
					rMessage = NStr("en='Non-fiscal cheque template is not filled for payment method!'; ru='У способа оплаты не заполнен шаблон нефискального чека!'; de='Zahlungsmethode hat eine leer Vorlage für die nonfiscal Kassenbon!'");
					ChequeIsPrinted = False;
				EndIf;
			Else
				ChequeIsPrinted = vDriver.pmPrintCheque(?(OperationType = 0, pPaymentObj.Sum, -pPaymentObj.Sum), ?(OperationType = 0, pPaymentObj.VATSum, -pPaymentObj.VATSum), pPaymentObj, pPaymentRef, rMessage, vPasswordKKM, , False, Undefined , "", "", '00010101');
			EndIf;
			If Not ChequeIsPrinted Then
				// Error printing cheque, so break operation
				pCancel = True;
			Else
				// Send folio refresh message
				Notify("Document.Folio.Edit");
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
Procedure NewTicketAfterChequeWasPrinted() Export
	If ChequeIsPrinted Then
		DetachIdleHandler("NewTicketAfterChequeWasPrinted");
		NewBillAction(Commands.NewBillAction);
		// Do message
		ShowMessageBox(, NStr("en='Success!'; de='Erfolg!'; ru='Успешно!'"), 1);
		// Send folio refresh message
		Notify("Document.Folio.Edit");
	EndIf;
EndProcedure // NewTicketAfterChequeWasPrinted

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputCashRegisterPassword(pValue, pAdditionalParameters) Export
	vPaymentRef = pAdditionalParameters.PaymentRef;
	vPaymentObj = pAdditionalParameters.PaymentObj;
	vPaymentMethodObj = pAdditionalParameters.PaymentMethodObj;
	vDriver = pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.rMessage;
	vDocsArray = pAdditionalParameters.DocsArray;
	If Not pValue = Undefined Then
		If vPaymentMethodObj.PrintNonFiscalCheque Then
			vChequeTemplate = TrimAll(vPaymentMethodObj.NonFiscalChequeTemplate);
			If Not IsBlankString(vChequeTemplate) Then
				ChequeIsPrinted = vDriver.pmPrintNonFiscalCheque(vPaymentObj.Sum, vPaymentObj.VATSum, vPaymentObj, vChequeTemplate, vMessage, pValue.Password);
			Else
				vMessage = NStr("en='Non-fiscal cheque template is not filled for payment method!'; ru='У способа оплаты не заполнен шаблон нефискального чека!'; de='Zahlungsmethode hat eine leer Vorlage für die nonfiscal Kassenbon!'");
				ChequeIsPrinted = False;
			EndIf;
		Else
			ChequeIsPrinted = vDriver.pmPrintCheque(?(OperationType = 0, vPaymentObj.Sum, -vPaymentObj.Sum), ?(OperationType = 0, vPaymentObj.VATSum, -vPaymentObj.VATSum), vPaymentObj, vPaymentRef, vMessage, pValue.Password, , False, Undefined, "", "", '00010101');
		EndIf;
		If Not ChequeIsPrinted Then
			CancelOperationDocuments(vDocsArray);
			DetachIdleHandler("NewTicketAfterChequeWasPrinted");
		EndIf;
	Else
		DetachIdleHandler("NewTicketAfterChequeWasPrinted");
	EndIf;
EndProcedure // AfterInputCashRegisterPassword

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure CancelOperationDocuments(pDocsArray)
	BeginTransaction(DataLockControlMode.Managed);
	For Each vDocRef In pDocsArray Do
		vDocObj = vDocRef.GetObject();
		vDocObj.SetDeletionMark(True);
	EndDo;
	CommitTransaction();
EndProcedure // CancelOperationDocuments

// -----------------------------------------------------------------------------
&AtClient
Function IsReadyToPrintCheque(rMessage)
	rMessage = "";
	If Not ValueIsFilled(SelCashRegister) Then
		Return False;
	EndIf;
	vDriver = tcOnClient.cmGetModulTO(SelCashRegister);
	If Not vDriver = Undefined Then
		Return vDriver.pmIsReadyToPrint(rMessage, , SelCashRegister);
	Else
		ShowMessageBox(, Nstr("en = 'Work with this device driver is not supported!'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
	Return  False;
EndFunction // IsReadyToPrintCheque

// -----------------------------------------------------------------------------
&AtClient
Function AuthorizePayment(pPaymentObj, rMessage)
	rMessage = "";
	vDriver = tcOnClient.cmGetModulTO(ArrPaymentTerminal);
	If Not vDriver = Undefined Then
		Return vDriver.pmAuthorizePayment(pPaymentObj.Sum, pPaymentObj.VATSum, pPaymentObj, rMessage, ArrPaymentTerminal);
	Else
		ShowMessageBox(, Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
	Return True;
EndFunction // AuthorizePayment

// -----------------------------------------------------------------------------
&AtServer
Function CheckCreditCardsProcessingSystem()
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And Not CreditCardProcessingSystem.IsEmpty() Then
		ArrPaymentTerminal = tcOnServer.cmGetAtributeAsArray(CreditCardProcessingSystem);
		ArrPaymentTerminal.ConnectionParameters = ArrPaymentTerminal.ConnectionParameters.Get();
		Return True;
	EndIf;
	Return False;
EndFunction	//CheckCreditCardsProcessingSystem

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetClientIdentificationCardById(pIdentifier, pUseDeleted = False) 
    Return cmGetClientIdentificationCardById(pIdentifier, pUseDeleted);
EndFunction // cmGetClientIdentificationCardById

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False) 
	Return cmGetDiscountCardById(pIdentifier);
EndFunction // cmGetDiscountCardById

// -----------------------------------------------------------------------------
&AtServer
Function GetServiceByBarCode(pBarCode, pMarkingCode = "", rMessage)
	vService = Catalogs.Services.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Services.Ref AS Ref
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	NOT Services.IsFolder
	|	AND NOT Services.DeletionMark
	|	AND Services.BarCode = &qBarCode
	|	AND (Services.Hotel = &qHotel
	|			OR Services.Hotel = VALUE(Catalog.Hotels.EmptyRef))";
	vQry.SetParameter("qBarCode", pBarCode);
	vQry.SetParameter("qHotel", SelHotel);
	vServices = vQry.Execute().Unload();
	If vServices.Count() = 0 Or vServices.Count() > 1 Then
		rMessage = StrTemplate(Nstr("en = 'Service with barcode %1 not found!'; 
									|de = 'Service mit Barcode %1 nicht gefunden!'; 
									|ru = 'Услуга с штрихкодом %1 не найдена!
                                	|Выберите услугу из списка после закрытия окна с ошибкой'"), pBarCode);
	Else 
		vService = vServices[0].Ref;
	EndIf;
	Return vService;
EndFunction // GetServiceByBarCode

// --------------------------------------------------------------------------------
&AtServer
Procedure NewBillActionAtServer()
	BillPositions.Clear();
	BillTotalAmount = 0;
	If Not ByFolioMode And Not ByRoomMode Then
		SelRoom = Undefined;
		SelClient = Undefined;
		FillDefaultFolio();
		FillListOfPaymentMethods();
		// Client appearance
		Items.SelClient.ChoiceList.Clear();
		Items.SelClient.ListChoiceMode = False;
		Items.SelClient.ChooseType = True;
		Items.SelClient.DropListButton = False;
		Items.SelClient.ChoiceListButton = True;
	EndIf;
	// Reset flags
	PaymentIsAuthorized = False;
	ChequeIsPrinted = False;
	OperationType = 0;
EndProcedure // NewBillActionAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure FillDefaultFolio()
	vOldFolio = SelFolio;
	If ValueIsFilled(vOldFolio) And Not vOldFolio.IsClosed And 
	   ValueIsFilled(SelHotel) And SelHotel.UseNewFolioForEachKioskOperation And 
	   StrFind(vOldFolio.Description, NStr("en='KIOSK'; ru='КИОСК'; de='KIOSK'")) > 0 Then
		vFolioObj = vOldFolio.GetObject();
		vFolioObj.IsClosed = True;
		vFolioObj.Write(DocumentWriteMode.Write);
	EndIf;
	SelFolio = Undefined;
	ByFolioMode = False;
	ByRoomMode = False;
	UseNewKioskFolio = False;
	If ValueIsFilled(SelHotel) And SelHotel.UseNewFolioForEachKioskOperation Then
		UseNewKioskFolio = True;
	EndIf;		
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And ValueIsFilled(SessionParameters.CurrentWorkstation.KioskFolio) Then
		SelFolio = SessionParameters.CurrentWorkstation.KioskFolio;
	EndIf;
	vDPFolios = cmGetFoliosForDirectPostings(SelHotel, SelCompany);
	If vDPFolios.Count() = 0 And Not ValueIsFilled(SelFolio) Then
		UseNewKioskFolio = True;
	EndIf;
	If UseNewKioskFolio Then
		SelFolio = GetNewFolio(SelFolio);
	EndIf;
	If ValueIsFilled(SelFolio) Then
		If vDPFolios.FindByValue(SelFolio) = Undefined Then
			vDPFolios.Insert(0, SelFolio, NStr("en='N '; ru='№ '; de='Nr. '") + TrimAll(SelFolio.Number) + ?(IsBlankString(SelFolio.Description), "", " - " + TrimAll(SelFolio.Description)) + ?(ValueIsFilled(SelFolio.Client), " - " + TrimAll(SelFolio.Client.FullName), ""));
		EndIf;        
		SelCompany = SelFolio.Company;
		vClient = SelFolio.Client;
		If ValueIsFilled(vClient) Then
			SelClientType = vClient.ClientType;
		Else
			SelClientType = Catalogs.ClientTypes.EmptyRef();
		EndIf;
		Services.Parameters.SetParameterValue("qClientType", SelClientType);
		Services.Parameters.SetParameterValue("qClientTypeIsFilled", ValueIsFilled(SelClientType));
	EndIf;
	Items.SelFolio.ChoiceList.Clear();
	For Each vDPFoliosItem In vDPFolios Do
		Items.SelFolio.ChoiceList.Add(vDPFoliosItem.Value, vDPFoliosItem.Presentation);
	EndDo;
EndProcedure // FillDefaultFolio

// -----------------------------------------------------------------------------
Function GetNewFolio(Val pFolioTemplate)
	vKioskFolioObj = Documents.Folio.CreateDocument();  
	If ValueIsFilled(pFolioTemplate) Then   
		FillPropertyValues(vKioskFolioObj, pFolioTemplate, , "Number, Date, Author");  
		vKioskFolioObj.pmFillAttributesWithDefaultValues();
	Else	
		vKioskFolioObj.Hotel = SelHotel;
		vKioskFolioObj.pmFillAttributesWithDefaultValues();
		vKioskFolioObj.Description = NStr("en='KIOSK'; ru='КИОСК'; de='KIOSK'");
		If ValueIsFilled(vKioskFolioObj.Hotel) Then
			vHotel = vKioskFolioObj.Hotel;
			If ValueIsFilled(vHotel.KioskCustomer) Then
				vKioskFolioObj.Customer = vHotel.KioskCustomer;
			EndIf;
			If ValueIsFilled(vHotel.KioskClient) Then
				vKioskFolioObj.Client = vHotel.KioskClient;
			EndIf;
		EndIf;   
	EndIf;
	vKioskFolioObj.Write(DocumentWriteMode.Write);
	Return vKioskFolioObj.Ref;
EndFunction // GetNewFolio

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure ServicesGroupOnActivateRowAtServer()
	vParent = Catalogs.Services.EmptyRef();
	vTable = Items.ServicesGroup;	
	vRows = vTable.SelectedRows;
	If vRows.Count() >= 1 Then
		vParent = vRows.Get(0);
	EndIf;
	Services.Parameters.SetParameterValue("qParentService", vParent);
	Services.Parameters.SetParameterValue("qHotel", SelHotel);
	Services.Parameters.SetParameterValue("qPeriod", CurrentSessionDate());
	Services.Parameters.SetParameterValue("qAccountingDate", SelAccountingDate);
	Services.Parameters.SetParameterValue("qClientType", SelClientType);
	Services.Parameters.SetParameterValue("qClientTypeIsFilled", ValueIsFilled(SelClientType));
EndProcedure // ServicesGroupOnActivateRowAtServer

// -----------------------------------------------------------------------------
&AtClient 
Procedure CalculateBillTotal()
	BillTotalAmount = BillPositions.Total("Amount");
EndProcedure // CalculateBillTotal

// -----------------------------------------------------------------------------
&AtServer
Procedure AddService(pService, pMarkingCode = "", pMarkingCodeCheckUUID = "", pMarkingCodeCheckDate = "")
	If ValueIsFilled(pService) And Not pService.IsFolder Then
		vRow = Undefined;
		
		vRows = BillPositions.FindRows(New Structure("Service, MarkingCode", pService, pMarkingCode));
		If vRows.Count() = 0 Then
			vRow = BillPositions.Add();
			vRow.LineNumber = BillPositions.Count();
			vRow.Service = pService;
			vRow.MarkingCode = pMarkingCode;
			vRow.MarkingCodeCheckUUID = pMarkingCodeCheckUUID;
			vRow.MarkingCodeCheckDate = pMarkingCodeCheckDate;
			vRow.PaymentSection = vRow.Service.PaymentSection;
			vPrices = pService.GetObject().pmGetServicePrices(SelHotel, CurrentSessionDate(), SelClientType);
			If vPrices.Count() > 0 Then
				vPricesRow = vPrices.Get(0);
				vDiscountType = Undefined;
				If ValueIsFilled(SelClientType) And ValueIsFilled(SelClientType.DiscountType) Then
					vDiscountType = SelClientType.DiscountType;
				EndIf;
				If ValueIsFilled(SelClient) And ValueIsFilled(SelClient.DiscountType) Then
					vDiscountType = SelClient.DiscountType;
				EndIf;
				If ValueIsFilled(vDiscountType) And cmIsServiceInServiceGroup(vRow.Service, vDiscountType.DiscountServiceGroup) Then
					vDiscount = vDiscountType.GetObject().pmGetDiscount(CurrentSessionDate(), vRow.Service, SelHotel);
					If vDiscount <> 0 Then
						vPriceDiscount = Round(vPricesRow.Price * vDiscount / 100, 2);
						If vDiscountType.RoundPrice Then
							vPriceDiscount = cmRoundDiscountAmount(vPriceDiscount, vDiscountType.RoundPriceDigits, vDiscountType.RoundPriceType);
						EndIf;
						vRow.Price = vPricesRow.Price - vPriceDiscount;
						If vRow.Price < 0 Then
							vRow.Price = vPricesRow.Price;
						EndIf;
					Else
						vRow.Price = vPricesRow.Price;
					EndIf;
				Else
					vRow.Price = vPricesRow.Price;
				EndIf;
				If ValueIsFilled(SelFolio) And ValueIsFilled(SelFolio.Company) And SelFolio.Company.IsUsingSimpleTaxSystem Then
					vRow.VATRate = SelFolio.Company.VATRate;
				Else
					vRow.VATRate = vPricesRow.VATRate;
				EndIf;
			EndIf;
		ElsIf IsBlankString(pMarkingCode) Then
			vRow = vRows.Get(0);
		EndIf;
		
		If vRow <> Undefined Then
			vRow.Quantity = vRow.Quantity + 1;
			vRow.Amount = Round(vRow.Price * vRow.Quantity, 2);
		EndIf;
	EndIf;
EndProcedure // AddService

// -----------------------------------------------------------------------------
&AtServer
Procedure SelCashRegisterOnChangeAtServer()
	// Set folio company from cash register
	If ValueIsFilled(SelCashRegister) Then
		If UseNewKioskFolio Then
			If ValueIsFilled(SelFolio) And SelFolio.Company <> SelCashRegister.Owner Then
				vFolioObj = SelFolio.GetObject();
				vFolioObj.Company = SelCashRegister.Owner;
				vFolioObj.Write(DocumentWriteMode.Write);
			EndIf;
		Else
			SelCompany = SelCashRegister.Owner;
			If ValueIsFilled(SelFolio) And SelCompany <> SelFolio.Company Then
				If ValueIsFilled(SelHotel) And SelHotel.UseNewFolioForEachKioskOperation Then
					UseNewKioskFolio = True;
				EndIf;		
				If ValueIsFilled(SessionParameters.CurrentWorkstation) And ValueIsFilled(SessionParameters.CurrentWorkstation.KioskFolio) Then
					SelFolio = SessionParameters.CurrentWorkstation.KioskFolio;
				EndIf;
				vDPFolios = cmGetFoliosForDirectPostings(SelHotel, SelCompany);
				If vDPFolios.Count() = 0 Then
					UseNewKioskFolio = True;
					SelFolio = GetNewFolio(SelFolio);
				Else
					SelFolio = vDPFolios.Get(0).Value;
				EndIf;
				Items.SelFolio.ChoiceList.Clear();
				For Each vDPFoliosItem In vDPFolios Do
					Items.SelFolio.ChoiceList.Add(vDPFoliosItem.Value, vDPFoliosItem.Presentation);
				EndDo;
			EndIf;
			If ValueIsFilled(SelFolio) Then
				vClient = SelFolio.Client;
				If ValueIsFilled(vClient) Then
					SelClientType = vClient.ClientType;
				Else
					SelClientType = Catalogs.ClientTypes.EmptyRef();
				EndIf;
				Services.Parameters.SetParameterValue("qClientType", SelClientType);
				Services.Parameters.SetParameterValue("qClientTypeIsFilled", ValueIsFilled(SelClientType));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SelCashRegisterOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SelClientTypeOnChangeAtServer()
	Services.Parameters.SetParameterValue("qClientType", SelClientType);
	Services.Parameters.SetParameterValue("qClientTypeIsFilled", ValueIsFilled(SelClientType));
EndProcedure // SelClientTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SelRoomOnChangeAtServer()
	vGuestsList = New ValueList();
	If ValueIsFilled(SelRoom) Then
		SelClient = Catalogs.Clients.EmptyRef();
		vGuests = cmGetRoomGuests(SelHotel, SelRoom.RoomType, SelRoom, CurrentSessionDate(), CurrentSessionDate());
		For Each vGuestsRow In vGuests Do
			If ValueIsFilled(vGuestsRow.Guest) And vGuestsList.FindByValue(vGuestsRow.Guest) = Undefined Then
				vGuestsList.Add(vGuestsRow.Guest, TrimAll(vGuestsRow.Guest.FullName));
			EndIf;
		EndDo;
		SelFolio = Undefined;
		vPaymentMethod = GetByRoomPaymentMethod();
		If vPaymentMethod <> Undefined Then
			SelPaymentMethod = vPaymentMethod;
		EndIf;
		// Fill list of clients
		If vGuestsList.Count() > 0 Then
			Items.SelClient.ListChoiceMode = True;
			Items.SelClient.DropListButton = True;
			Items.SelClient.ChoiceListButton = False;
			Items.SelClient.ChooseType = False;
			Items.SelClient.ChoiceList.LoadValues(vGuestsList.UnloadValues());
			SelClient = vGuestsList.Get(0).Value;
			If ValueIsFilled(SelClient) Then
				SelClientType = SelClient.ClientType;
				SelClientTypeOnChangeAtServer();
			EndIf;
		Else
			Items.SelClient.ListChoiceMode = False;
			Items.SelClient.ChoiceList.Clear();
			Items.SelClient.DropListButton = False;
			Items.SelClient.ChoiceListButton = True;
			Items.SelClient.ChooseType = True;
		EndIf;
	Else
		Items.SelClient.ListChoiceMode = False;
		Items.SelClient.ChoiceList.Clear();
		Items.SelClient.DropListButton = False;
		Items.SelClient.ChoiceListButton = True;
		Items.SelClient.ChooseType = True;
		// Get default folio to be used for the new bill
		FillDefaultFolio();
	EndIf;
	// Fill list of payment methods available for the user
	FillListOfPaymentMethods();
EndProcedure // SelRoomOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetByRoomPaymentMethod()
	vPMList = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser);
	For Each vPMListItem In vPMList Do
		vPM = vPMListItem.Value;
		If ValueIsFilled(SelRoom) And vPM.IsCloseToTheRoom Or Not ValueIsFilled(SelRoom) And ValueIsFilled(SelFolio) And vPM.IsCloseToTheFolio Then
			Return vPM;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction // GetByRoomPaymentMethod 

// -----------------------------------------------------------------------------
&AtServer
Function GetByFolioPaymentMethod()
	vPMList = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser);
	For Each vPMListItem In vPMList Do
		vPM = vPMListItem.Value;
		If vPM.IsCloseToTheFolio Then
			Return vPM;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction // GetByFolioPaymentMethod

// -----------------------------------------------------------------------------
&AtServer
Procedure SelClientOnChangeAtServer()
	If ValueIsFilled(SelClient) Then
		// Fill client type
		SelClientType = SelClient.ClientType;
		SelClientTypeOnChangeAtServer();
		// Fill list of client folios
		If Not ValueIsFilled(SelRoom) Then
			vFolios = GetClientFolios();
			If vFolios.Count() > 0 Then
				Items.SelFolio.ChoiceList.Clear();
				For Each vFoliosItem In vFolios Do
					Items.SelFolio.ChoiceList.Add(vFoliosItem.Value, vFoliosItem.Presentation);
				EndDo;
				If vFolios.Count() = 1 Then
					SelFolio = vFolios.Get(0).Value;
				Else
					SelFolio = Undefined;
				EndIf;
				vByFolioPaymentMethod = GetByFolioPaymentMethod();
				If ValueIsFilled(vByFolioPaymentMethod) And Items.SelPaymentMethod.ChoiceList.FindByValue(vByFolioPaymentMethod) <> Undefined Then
					SelPaymentMethod = vByFolioPaymentMethod;
				EndIf;
			EndIf;
		EndIf;
	Else
		If Not ValueIsFilled(SelRoom) Then
			If ValueIsFilled(SelFolio) And TypeOf(SelClient) = Type("CatalogRef.Clients") Then
				SelClient = SelFolio.Client;
				If ValueIsFilled(SelClient) Then
					SelClientType = SelClient.ClientType;
				Else
					SelClientType = Catalogs.ClientTypes.EmptyRef();
				EndIf;
				SelClientTypeOnChangeAtServer();
			EndIf;
		EndIf;
	EndIf;
	// Fill list of payment methods available for the user
	FillListOfPaymentMethods();
EndProcedure // SelClientOnChangeAtServer

// -----------------------------------------------------------------------------
Function GetClientFolios()
	vFoliosList = New ValueList();
	vQry = New Query();
	If TypeOf(SelClient) = Type("CatalogRef.Clients") Then
		vQry.Text =
		"SELECT
		|	Folios.Ref AS Ref,
		|	Folios.Number AS Number,
		|	Folios.Date AS Date,
		|	Folios.Description AS Description,
		|	Folios.Customer AS Customer,
		|	Folios.Client AS Client,
		|	Folios.DateTimeFrom AS DateTimeFrom,
		|	Folios.DateTimeTo AS DateTimeTo,
		|	Folios.Remarks AS Remarks
		|FROM
		|	Document.Folio AS Folios
		|WHERE
		|	Folios.Client = &qClient
		|	AND NOT Folios.DeletionMark
		|	AND NOT Folios.IsClosed
		|	AND Folios.ParentDoc = UNDEFINED
		|	AND Folios.Hotel = &qHotel
		|
		|ORDER BY
		|	Date";
		vQry.SetParameter("qClient", SelClient);
	ElsIf TypeOf(SelClient) = Type("CatalogRef.Customers") Then
		vQry.Text =
		"SELECT
		|	Folios.Ref AS Ref,
		|	Folios.Number AS Number,
		|	Folios.Date AS Date,
		|	Folios.Description AS Description,
		|	Folios.Customer AS Customer,
		|	Folios.Client AS Client,
		|	Folios.DateTimeFrom AS DateTimeFrom,
		|	Folios.DateTimeTo AS DateTimeTo,
		|	Folios.Remarks AS Remarks
		|FROM
		|	Document.Folio AS Folios
		|WHERE
		|	Folios.Customer = &qCustomer
		|	AND NOT Folios.DeletionMark
		|	AND NOT Folios.IsClosed
		|	AND Folios.ParentDoc = UNDEFINED
		|	AND Folios.Hotel = &qHotel
		|
		|ORDER BY
		|	Date";
		vQry.SetParameter("qCustomer", SelClient);
	EndIf;
	vQry.SetParameter("qHotel", SelHotel);
	vFolios = vQry.Execute().Unload();
	For Each vFoliosRow In vFolios Do
		vFoliosList.Add(vFoliosRow.Ref, TrimAll(vFoliosRow.Number) + ?(IsBlankString(vFoliosRow.Description), "", ", " + TrimAll(vFoliosRow.Description)) + ?(ValueIsFilled(vFoliosRow.DateTimeFrom), ", " + Format(vFoliosRow.DateTimeFrom, "DF=dd.MM.yyyy") + " - " + Format(vFoliosRow.DateTimeTo, "DF=dd.MM.yyyy"), ""));
	EndDo;
	Return vFoliosList;
EndFunction // GetClientFolios

// -----------------------------------------------------------------------------
&AtServer
Procedure SelFolioOnChangeAtServer()
	If Not ValueIsFilled(SelFolio) Then
		SelRoom = Undefined;
		SelClient = Undefined;
		SelCompany = Undefined;
		// Get default folio to be used for the new bill
		FillDefaultFolio();
	Else
		SelRoom = SelFolio.Room;
		SelClient = SelFolio.Client; 
		SelCompany = SelFolio.Company;
		If ValueIsFilled(SelClient) Then
			SelClientType = SelClient.ClientType;
		Else
			SelClientType = Catalogs.ClientTypes.EmptyRef();
		EndIf;
		Services.Parameters.SetParameterValue("qClientType", SelClientType);
		Services.Parameters.SetParameterValue("qClientTypeIsFilled", ValueIsFilled(SelClientType));
	EndIf;
	Items.SelClient.ListChoiceMode = False;
	Items.SelClient.ChoiceList.Clear();
	Items.SelClient.DropListButton = False;
	Items.SelClient.ChoiceListButton = True;
	Items.SelClient.ChooseType = True;
	// Fill list of payment methods available for the user
	FillListOfPaymentMethods();
EndProcedure // SelFolioOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function FillBalanceByCard()
	vPMHasChanged = False;
	Items.DecorationBalance.Title = "";
	vCard = SelDiscountCard;
	If ValueIsFilled(SelPaymentMethod) And SelPaymentMethod.IsByBonuses Then
		Items.SelDiscountCard.Title = Nstr("en = 'Bonus card'; de = 'Bonuskarte'; ru = 'Бонусная карта'");
	Else
		Items.SelDiscountCard.Title = Nstr("en = 'Gift card'; de = 'Geschenkkarte'; ru = 'Сертификат'");
	EndIf;	
		
	If ValueIsFilled(vCard) Then
		vArrFD = New Array;
		If vCard.LoyaltyType = Enums.LoyaltyType.Bonuses Then
			vDataCard = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCard); 
			vText = NStr("en = 'Bonuses amount available:'; de = 'Verfügbare Bonibetrag:'; ru = 'Доступно бонусов на сумму:'");
			// Get formating string folio description
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", vText, New Font(,9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(vDataCard.BalanceAmount,"NFD=2; NDS=.; NZ=0.00; NG=0"), New Font(,11,True), new Color(0,128,0)));
		ElsIf vCard.LoyaltyType = Enums.LoyaltyType.Certificate Then
			vDataCard = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCard);
			vTextBalance = NStr("en = 'Balance: '; de = 'Kontostand: '; ru = 'Остаток: '");
			// Get formating string folio description
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", vTextBalance, New Font(,9)));
			vArrFD.Add(New Structure("String, Font, TextColor, BackColor, Ref", " " + Format(vDataCard.BalanceAmount,"NFD=2; NDS=.; NZ=0.00; NG=0"), New Font(,11,True), new Color(0,128,0)));
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
		For Each vPMItem In Items.SelPaymentMethod.ChoiceList Do
			vPM = vPMItem.Value;
			If vCard.LoyaltyType = Enums.LoyaltyType.Bonuses And vPM.IsByBonuses Then
				If SelPaymentMethod <> vPM Then
					vPMHasChanged = True;
					SelPaymentMethod = vPM;
				EndIf;
				Break;
			ElsIf vCard.LoyaltyType = Enums.LoyaltyType.Certificate And vPM.IsByGiftCertificate Then
				If SelPaymentMethod <> vPM Then
					vPMHasChanged = True;
					SelPaymentMethod = vPM;
				EndIf;
				Break;
			EndIf;
		EndDo;
		If ValueIsFilled(SelPaymentMethod) And 
		   Not (vCard.LoyaltyType = Enums.LoyaltyType.Bonuses And SelPaymentMethod.IsByBonuses Or 
		        vCard.LoyaltyType = Enums.LoyaltyType.Certificate And SelPaymentMethod.IsByGiftCertificate) Then
			SelDiscountCard = Undefined;
			Items.DecorationBalance.Title = "";
		EndIf;
	EndIf;
	Return vPMHasChanged;
EndFunction // FillBalanceByCard

// -----------------------------------------------------------------------------
&AtServerNoContext
Function SelDiscountCardAutoCompleteAtServer(pText)
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
EndFunction // SelDiscountCardAutoCompleteAtServer

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FillDataByCard(pCardID)
	If IsBlankString(pCardID) Then
		Return;
	EndIf;
	
	// Try to find client identification card by Id
	vCard = GetClientIdentificationCardById(pCardID);
	vCardAttr = Undefined;
	If ValueIsFilled(vCard) Then
		vCardAttr = tcOnServer.cmGetAtributeAsArray(vCard);
	EndIf;
	If ValueIsFilled(vCard) And vCardAttr.Hotel = SelHotel Then
		If ValueIsFilled(vCardAttr.Folio) Then
			SelRoom = Undefined;
			SelClient = Undefined;
			If ByRoomIsNotAvailable Then
				If Items.SelFolio.ChoiceList.FindByValue(vCardAttr.Folio) = Undefined Then
					Items.SelFolio.ChoiceList.Add(vCardAttr.Folio);
					SelFolio = vCardAttr.Folio;
				EndIf;
			EndIf;
			// Set filter
			If ValueIsFilled(vCardAttr.Room) Then
				SelRoom = vCardAttr.Room;
				SelRoomOnChangeAtServer();
				If ValueIsFilled(vCardAttr.Client) Then
					SelClient = vCardAttr.Client;
					SelClientOnChangeAtServer();
				EndIf;
			Else
				If Items.SelFolio.ChoiceList.FindByValue(vCardAttr.Folio) <> Undefined Then
					SelFolio = vCardAttr.Folio;
					SelFolioOnChangeAtServer();
				EndIf;
			EndIf;
		EndIf;
	Else
		// Try to find discount card by Id
		vDiscountCard = GetDiscountCardById(pCardID);
		vDiscountCardAttr = Undefined;
		If ValueIsFilled(vDiscountCard) Then
			SelDiscountCard = vDiscountCard;
			vDiscountCardAttr = tcOnServer.cmGetAtributeAsArray(vDiscountCard);
			If ValueIsFilled(vDiscountCardAttr.Client) Then
				SelRoom = Undefined;
				SelClient = vDiscountCardAttr.Client;
				SelClientOnChangeAtServer();
			EndIf;
			SelDiscountCardOnChange(Items.SelDiscountCard);
		EndIf;
	EndIf;
EndProcedure // FillDataByCard

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ChargeServiceByBarcode(pMarkingCode)   
	If IsBlankString(pMarkingCode) Then
		Return;
	EndIf;
	
	vMessage = "";
	vService = Undefined;
	vMarkingCode = "";
	If StrLen(pMarkingCode) > 13 Then // it's datamatrix code 
		vMarkingCode = Base64String(GetBinaryDataFromString(pMarkingCode));   
		
		vUseCharge = CheckMarkingCode(vMarkingCode); 
		If ValueIsFilled(vUseCharge) Then
			vFolio = tcOnServer.cmGetAttributeByRef(vUseCharge, "Folio");
			If OperationType = 1 And ValueIsFilled(vFolio) Then
				ShowQueryBox(New NotifyDescription("OpenFolioByCharge", ThisObject, vFolio), StrTemplate(NStr("en = 'Return of services with marking can be performed only from a folio, open a folio: %1?'; 
																	   |de = 'Leistungsrückerstattung mit Kennzeichnung kann nur aus einem Folio erfolgen, Folio öffnen: %1?'; 
																	   |ru = 'Возврат услуг с маркировкой можно выполнить только из лицевого счета, открыть лицевой счет: %1?'"), vFolio),
							QuestionDialogMode.YesNo,,, Nstr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'")); 			
			Else
				ShowMessageBox(, StrTemplate(Nstr("en = 'There is already an accrual with this marking code
	                                              |%1'; de = 'Mit diesem Markierungscode besteht bereits eine Rückstellung
	                                              |%1'; ru = 'Уже есть начисление с таким кодом маркировки 
	                                              |%1'"), vUseCharge), , Nstr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));	   
				
			EndIf; 
			Return; 
		ElsIf OperationType = 1 Then
			ShowMessageBox(, NStr("en = 'Return of services with marking can be performed only from a folio'; 
								  |de = 'Leistungsrückerstattung mit Kennzeichnung kann nur aus einem Folio erfolgen'; 
								  |ru = 'Возврат услуг с маркировкой можно выполнить только из лицевого счета'"), , Nstr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));
			Return; 
		ElsIf BillPositions.FindRows(New Structure("MarkingCode", vMarkingCode)).Count() > 0 Then
				ShowMessageBox(, Nstr("en = 'There is already an accrual with this marking code'; 
									  |de = 'Mit diesem Markierungscode besteht bereits eine Rückstellung'; 
									  |ru = 'Уже есть начисление с таким кодом маркировки'"), , Nstr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));	
		EndIf;  		
		vBarcode = "";
		If StrLen(pMarkingCode) = 29 Then // it's cigarettes 
        	vBarcode = Mid(pMarkingCode, 2, 13); 
		ElsIf StrLen(pMarkingCode) = 20 Then // it's fur coats 
			vBarcode = pMarkingCode;  
		Else
			vBarcode = Mid(pMarkingCode, 4, 13);
		EndIf; 
		vService = GetServiceByBarCode(vBarCode, vMarkingCode, vMessage);
	Else
		vService = GetServiceByBarCode(pMarkingCode,, vMessage);	
	EndIf;  
	If ValueIsFilled(vService) Then     
		AddService(vService, vMarkingCode, MarkingCodeCheckUUID, MarkingCodeCheckDate);
		CalculateBillTotal();
	Else
		ShowMessageBox(New NotifyDescription("ChooseServiceAndCreateCharge", ThisObject, New Structure("MarkingCode", vMarkingCode)), vMessage, , Nstr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));	
	EndIf; 
EndProcedure // ChargeServiceByBarcode

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ChooseServiceAndCreateCharge(pAdditionalParameters) Export
	vFormParam = New Structure("Hotel, ClientType, MultipleChoice, UseMarking", SelHotel, Undefined, False, StrLen(pAdditionalParameters.MarkingCode) > 13);
	OpenForm("Catalog.Services.ChoiceForm", vFormParam, , , , , New NotifyDescription("ChooseServiceAndCreateChargeContinue", ThisObject, pAdditionalParameters),  FormWindowOpeningMode.LockWholeInterface);
EndProcedure // ChooseServiceAndCreateCharge

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ChooseServiceAndCreateChargeContinue(pService, pAdditionalParameters) Export
	If pService <> Undefined And ValueIsFilled(pService) Then 
		AddService(pService, pAdditionalParameters.MarkingCode, MarkingCodeCheckUUID, MarkingCodeCheckDate);
		CalculateBillTotal();
	EndIf;	
EndProcedure // ChooseServiceAndCreateChargeContinue

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure OpenFolioByCharge(pResult, pFolio) Export 
	If pResult = DialogReturnCode.Yes Then 
		vParamsStruct = New Structure("ParametersStructure", New Structure("ObjectRef", pFolio));
		OpenForm("CommonForm.tcFoliosForm", vParamsStruct, ThisObject, UUID);	
	EndIf;
EndProcedure // OpenFolioByCharge

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
		vQry.SetParameter("qCompany", SelCompany);
		vResult = vQry.Execute().Unload();
		
		vTempArrayWithPaymentMethod = New Array();
		For Each vRow In vResult Do
			vPaymentMethods = vRow.DeviceSettings.PaymentMethods;
			If vPaymentMethods.Count() > 0 Then
				For Each vPaymentRow In vPaymentMethods Do
					If vPaymentRow.PaymentMethod = SelPaymentMethod Then
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

#EndRegion         
