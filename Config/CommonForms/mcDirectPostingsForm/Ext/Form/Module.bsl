
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
	
	If Parameters.Property("Company") Then
		SelCompany = Parameters.Company;
	EndIf;
	If Not ValueIsFilled(SelCompany) And ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.Company) Then
			SelCompany = SessionParameters.CurrentUser.Company;
		EndIf;
	EndIf;
		
	// Filter by service group
	SelServicesGroup = Catalogs.ServiceGroups.EmptyRef();
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And ValueIsFilled(SessionParameters.CurrentWorkstation.KioskServiceGroup) Then
		SelServicesGroup = SessionParameters.CurrentWorkstation.KioskServiceGroup;
	EndIf;
	
	// Get default folio to be used for the new bill
	ByFolioMode = False;
	If Parameters.Property("Folio") And ValueIsFilled(Parameters.Folio) Then
		ByFolioMode = True;
		SelFolio = Parameters.Folio;
		SelRoom = SelFolio.Room;
		SelClient = SelFolio.Client;
		If ValueIsFilled(SelClient) Then
			SelClientType = SelClient.ClientType;
		Else
			SelClientType = Catalogs.ClientTypes.EmptyRef();
		EndIf;
		Items.SelFolio.ChoiceList.Add(SelFolio);
	Else
		FillDefaultFolio(True);
	EndIf;
	
	// Get list of POS availabe for the user
	FillListOfCashRegisters();
	
	// Fill list of payment methods available for the user
	FillListOfPaymentMethods();
		
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
	FillServicesGroupList();
	FillServicesList();
	
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
		// Try to find client identification card by Id
		vCard = GetClientIdentificationCardById(vEventData.DeviceData);
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
			vDiscountCard = GetDiscountCardById(vEventData.DeviceData);
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
	ElsIf vEventData.DeviceType = "BarCodeScaner" Then
		vMessage = GetServiceByBarCode(vEventData.DeviceData);
		If Not IsBlankString(vMessage) Then
			ShowUserNotification(vMessage,,,, UserNotificationStatus.Information);
		Else
			CalculateBillTotal();
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesGroupOnActivateRow(pItem)
	vRows = pItem.CurrentData;
	If vRows <> Undefined And SelParentService <> vRows.Ref Then
		SelParentService = vRows.Ref;
		FillServicesList();
	EndIf;
EndProcedure // ServicesGroupOnActivateRow

// --------------------------------------------------------------------------------
&AtClient
Procedure ServicesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.Services.CurrentData;
	If vCurData <> Undefined Then
		If AddService(vCurData.Ref) Then
			vCurData.ServiceQuantity = vCurData.ServiceQuantity + 1;	
		EndIf;
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
		vCurData.Amount = Round(vCurData.Price * vCurData.Quantity, 2);
	EndIf;
EndProcedure // BillPositionsQuantityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BillPositionsAmountOnChange(pItem)
	vCurData = Items.BillPositions.CurrentData;
	If vCurData <> Undefined Then
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
	FillServicesList();
EndProcedure // BillPositionsAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure BillPositionsOnEditEnd(pItem, pNewRow, pCancelEdit)
	CalculateBillTotal();
	FillServicesList();
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

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure WriteAction(pCommand)
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
Procedure ServiceSelection(pCommand)
	Items.DirectPostingsPages.CurrentPage = Items.DirectPostingsPage2;
EndProcedure // ServiceSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure Back(pCommand)
	If Items.DirectPostingsPages.CurrentPage = Items.DirectPostingsPage2 Then
		Items.DirectPostingsPages.CurrentPage = Items.DirectPostingsPage1;
	ElsIf Items.DirectPostingsPages.CurrentPage = Items.DirectPostingsPage3 Then
		Items.DirectPostingsPages.CurrentPage = Items.DirectPostingsPage2;	
	EndIf;
EndProcedure // Back

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowBasket(pCommand)
	Items.DirectPostingsPages.CurrentPage = Items.DirectPostingsPage3;
EndProcedure // ShowBasket

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
&AtClient
Procedure NewBillAction(pCommand)
	NewBillActionAtServer();
	Items.DirectPostingsPages.CurrentPage = Items.DirectPostingsPage1;
EndProcedure // NewBillAction

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowFolioTransactions(pCommand)
	If ValueIsFilled(SelFolio) Then
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", New Structure("ObjectRef", SelFolio)), Items.SelFolio, SelFolio);
	EndIf;
EndProcedure // ShowFolioTransactions

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangePaymentMethod(pCommand)
	vParams = New Structure("ValueList, MultipleChoice, Title", SelPaymentMethodList, False, NStr("en = 'Select payment method'; de = 'Wählen Sie die Zahlungsmethode'; ru = 'Выберите способ оплаты'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID,,, New NotifyDescription("AfterChangePaymentMethod", ThisObject));
EndProcedure // ChangePaymentMethod

#EndRegion

#Region Internal

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServicesGroupList()
	ServicesGroup.Clear();
	vServiceGroup = Undefined;
	If ValueIsFilled(SelServicesGroup) Then
		vServiceGroup = cmGetServiceGroupServices(SelServicesGroup);	
	EndIf;
	Services.Clear();
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Services.Ref AS Ref,
	|	Services.Description AS Description
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	Services.IsFolder
	|	AND NOT Services.DeletionMark
	|	AND (Services.Hotel = &qHotel
	|			OR Services.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|
	|ORDER BY
	|	Services.SortCode";
	vQuery.SetParameter("qHotel", SelHotel);
	vServicesList = vQuery.Execute().Unload();
	vNewRow = vServicesList.Insert(0);
	vNewRow.Ref = Catalogs.Services.EmptyRef();
	vNewRow.Description = NStr("en = 'All services'; de = 'Alle Dienstleistungen'; ru = 'Все услуги'");
	ServicesGroup.Load(vServicesList);
EndProcedure // FillServicesGroupList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServicesList()
	vServiceGroup = Undefined;
	If ValueIsFilled(SelServicesGroup) Then
		vServiceGroup = cmGetServiceGroupServices(SelServicesGroup);
	EndIf;
	Services.Clear();
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	CatalogServices.Ref AS Ref,
	|	0 AS ServiceQuantity,
	|	CAST("""" AS STRING) AS PricesPresentation,
	|	CASE
	|		WHEN PricesClientType.Currency IS NULL
	|			THEN PricesEmptyClientType.Currency
	|		ELSE PricesClientType.Currency
	|	END AS Currency,
	|	CASE
	|		WHEN PricesClientType.Price IS NULL
	|			THEN ISNULL(PricesEmptyClientType.Price, 0)
	|		ELSE ISNULL(PricesClientType.Price, 0)
	|	END AS Price,
	|	CatalogServices.AvailableQuantity - ISNULL(AvailableQuantities.Quantity, 0) AS AvailableQuantity
	|FROM
	|	Catalog.Services AS CatalogServices
	|		LEFT JOIN (SELECT
	|			ServicePricesSliceLast.Service AS Service,
	|			ServicePricesSliceLast.Currency AS Currency,
	|			MAX(ServicePricesSliceLast.Price) AS Price
	|		FROM
	|			InformationRegister.ServicePrices.SliceLast(
	|					&qAccountingDate,
	|					(Hotel = &qHotel
	|						OR Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|						AND Currency = &qCurrency
	|						AND ClientType = VALUE(Catalog.ClientTypes.EmptyRef)) AS ServicePricesSliceLast
	|		
	|		GROUP BY
	|			ServicePricesSliceLast.Service,
	|			ServicePricesSliceLast.Currency) AS PricesEmptyClientType
	|		ON CatalogServices.Ref = PricesEmptyClientType.Service
	|		LEFT JOIN (SELECT
	|			ServicePricesSliceLast.Service AS Service,
	|			ServicePricesSliceLast.Currency AS Currency,
	|			MAX(ServicePricesSliceLast.Price) AS Price
	|		FROM
	|			InformationRegister.ServicePrices.SliceLast(
	|					&qAccountingDate,
	|					(Hotel = &qHotel
	|						OR Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|						AND Currency = &qCurrency
	|						AND (ClientType = &qClientType
	|							OR ClientType = &qClientTypeParent
	|								AND &qClientTypeParent <> VALUE(Catalog.ClientTypes.EmptyRef))) AS ServicePricesSliceLast
	|		
	|		GROUP BY
	|			ServicePricesSliceLast.Service,
	|			ServicePricesSliceLast.Currency) AS PricesClientType
	|		ON CatalogServices.Ref = PricesClientType.Service
	|		LEFT JOIN (SELECT
	|			UsedServices.Service AS Service,
	|			SUM(UsedServices.Quantity) AS Quantity
	|		FROM
	|			(SELECT
	|				SalesMovements.Service AS Service,
	|				SalesMovements.Quantity AS Quantity
	|			FROM
	|				AccumulationRegister.Sales AS SalesMovements
	|			WHERE
	|				SalesMovements.AccountingDate = &qAccountingDate
	|				AND SalesMovements.Service.AvailableQuantity > 0
	|				AND NOT SalesMovements.Service.DeletionMark
	|				AND NOT SalesMovements.Service.IsFolder
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				SalesForecastMovements.Service,
	|				SalesForecastMovements.Quantity
	|			FROM
	|				AccumulationRegister.SalesForecast AS SalesForecastMovements
	|			WHERE
	|				SalesForecastMovements.AccountingDate = &qAccountingDate
	|				AND SalesForecastMovements.Service.AvailableQuantity > 0
	|				AND NOT SalesForecastMovements.Service.DeletionMark
	|				AND NOT SalesForecastMovements.Service.IsFolder) AS UsedServices
	|		
	|		GROUP BY
	|			UsedServices.Service) AS AvailableQuantities
	|		ON CatalogServices.Ref = AvailableQuantities.Service
	|WHERE
	|	CatalogServices.Ref IN HIERARCHY(&qParentService)
	|	AND NOT CatalogServices.IsFolder
	|	AND NOT CatalogServices.DeletionMark
	|	AND (CatalogServices.Hotel = &qHotel
	|			OR CatalogServices.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND CASE
	|			WHEN &qServiceGroup <> UNDEFINED
	|				THEN CatalogServices.Ref IN (&qServiceGroup)
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	CatalogServices.SortCode";
	vQuery.SetParameter("qParentService", SelParentService);
	vQuery.SetParameter("qHotel", SelHotel);
	vQuery.SetParameter("qAccountingDate", SelAccountingDate);	
	vQuery.SetParameter("qCurrency", ?(ValueIsFilled(SelFolio), SelFolio.FolioCurrency, Catalogs.Currencies.EmptyRef()));
	vQuery.SetParameter("qClientType", SelClientType);
	vQuery.SetParameter("qClientTypeParent", ?(ValueIsFilled(SelClientType), SelClientType.Parent, Catalogs.ClientTypes.EmptyRef()));
	vQuery.SetParameter("qServiceGroup", vServiceGroup);
	vServicesList = vQuery.Execute().Unload();
	For Each vRow In vServicesList Do
		vRow.PricesPresentation = cmFormatSum(vRow.Price, vRow.Currency);  
		If ValueIsFilled(vRow.Ref) Then
			vBillPositionsArr = BillPositions.FindRows(New Structure("Service", vRow.Ref));
			For Each vRowBillPosition In vBillPositionsArr Do
				vRow.ServiceQuantity = vRow.ServiceQuantity + vRowBillPosition.Quantity; 	
			EndDo;
		EndIf;
	EndDo;
	Services.Load(vServicesList);
EndProcedure // FillServicesList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPaymentMethods()
	SelPaymentMethodList.Clear();
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
	SelPaymentMethodList.LoadValues(vPMList.UnloadValues());
	// Add icons
	For Each vListItem In SelPaymentMethodList Do
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
	SetPaymentMethodPresentation();
EndProcedure // FillListOfPaymentMethods

// -----------------------------------------------------------------------------
&AtServer
Procedure SetPaymentMethodPresentation()
	If ValueIsFilled(SelPaymentMethod) Then
		vItem = SelPaymentMethodList.FindByValue(SelPaymentMethod);	
		If vItem <> Undefined Then
			Items.ChangePaymentMethod.Title = vItem.Value;
			Items.ChangePaymentMethod.Picture = vItem.Picture; 	
		EndIf;
	EndIf;
EndProcedure // SetPaymentMethodPresentation

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
						For Each vBPRow In BillPositions Do
							vPSTableRow = vPSTable.Add();
							vPSTableRow.PaymentSection = vBPRow.PaymentSection;
							vPSTableRow.Amount = vBPRow.Amount;
						EndDo;
						vPSTable.GroupBy("PaymentSection", "Amount");
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
						EndDo;
						vPaymentObj.pmCalculateTotalsByPaymentSections();
					ElsIf ValueIsFilled(vPaymentObj.Hotel) And vPaymentObj.Hotel.SplitFolioBalanceByServicesAndPrices Then
						vPaymentObj.PaymentSection = Catalogs.PaymentSections.EmptyRef();
						vPaymentObj.PaymentSections.Clear();
						vPSTable = New ValueTable();
						vPSTable.Columns.Add("Service", cmGetCatalogTypeDescription("Services"));
						vPSTable.Columns.Add("PaymentSection", cmGetCatalogTypeDescription("PaymentSections"));
						vPSTable.Columns.Add("Price", cmGetSumTypeDescription());
						vPSTable.Columns.Add("Amount", cmGetSumTypeDescription());
						vPSTable.Columns.Add("Quantity", cmGetNumberTypeDescription(19, 7));
						For Each vBPRow In BillPositions Do
							vPSTableRow = vPSTable.Add();
							vPSTableRow.PaymentSection = vBPRow.PaymentSection;
							vPSTableRow.Service = vBPRow.Service;
							vPSTableRow.Price = vBPRow.Price;
							vPSTableRow.Amount = vBPRow.Amount;
							vPSTableRow.Quantity = vBPRow.Quantity;
						EndDo;
						vPSTable.GroupBy("PaymentSection, Service, Price", "Amount, Quantity");
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
				If ValueIsFilled(SelRoom) And Not SelPaymentMethod.IsCloseToTheFolio Then
					vErrorText = cmChargeRoomService(TrimAll(SelRoom.Description), CurrentSessionDate(), ?(pIsReturn, -vRow.Amount, vRow.Amount), TrimAll(SelClient.Code), TrimAll(?(ValueIsFilled(SelFolio), SelFolio.FolioCurrency.Code, SelFolio.FolioCurrency.Code)), TrimAll(vRow.Service.Code), ?(pIsReturn, -vRow.Quantity, vRow.Quantity), , , , TrimAll(SelHotel.Code), , ?(ValueIsFilled(vRow.VATRate), vRow.VATRate.TaxRate, Undefined), "", vRoomServiceRef, , , pDoNotCheckCreditLimit, , ?(ValueIsFilled(SelClientType), Trimall(SelClientType.Code), ""));
					If ValueIsFilled(vRoomServiceRef) Then
						vCharge = GetChargeByRoomService(vRoomServiceRef);
						If ValueIsFilled(vCharge) Then
							pTransArray.Add(vCharge);
							pDocsArray.Add(vCharge);
						EndIf;
					EndIf;
				ElsIf ValueIsFilled(SelFolio) Then
					vCharge = Undefined;
					vErrorText = cmChargeExternalServiceByFolio(TrimAll(SelFolio.Number), TrimAll(vRow.Service.Code), ?(pIsReturn, -vRow.Amount, vRow.Amount), ?(pIsReturn, -vRow.Quantity, vRow.Quantity), "", "", TrimAll(SelHotel.Code), "", TrimAll(SelFolio.FolioCurrency.Code), ?(ValueIsFilled(vRow.VATRate), vRow.VATRate.TaxRate, Undefined), , , pDoNotCheckCreditLimit, vCharge, ?(ValueIsFilled(SelClientType), Trimall(SelClientType.Code), ""));
					If ValueIsFilled(vCharge) Then
						pTransArray.Add(vCharge);
						pDocsArray.Add(vCharge);
					EndIf;
				EndIf;	
				If Not IsBlankString(vErrorText) And Not pDoNotCheckCreditLimit Then
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
	If pReply = DialogReturnCode.No Then
		Return;
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
	// Process ticket
	vCancel = False;
	vMessage = "";
	vChequePrintCalled = False;
	// Do operation at server
	vTransArray = New Array();
	vDocsArray = New Array();
	vPaymentRef = CloseBill(?(OperationType = 0, False, True), vTransArray, vDocsArray);
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
					ShowUserNotification(vMessage,,,, UserNotificationStatus.Information);
					CancelOperationDocuments(vDocsArray);
				EndIf;
			EndIf;
		EndIf;
		// Process payment by the credit card processing system
		If Not vCancel And vPaymentMethodAttr.IsByCreditCard And Not vPaymentMethodAttr.ExternalBankTerminalIsUsed Then
			vCurWstn = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
			If ValueIsFilled(vCurWstn) Then
				If tcOnServer.cmGetAttributeByRef(vCurWstn, "HasConnectionToCreditCardsProcessingSystem") Then
					// If payment was earlier authorized manually (reference number is filled) or automatically then skip this step
					If Not PaymentIsAuthorized Then
						If CheckCreditCardsProcessingSystem() Then
							If Not AuthorizePayment(vPaymentAttr, vMessage) Then
								vCancel = True;
								vMessage = tcOnServer.cmNStrAtServer(vMessage);
								ShowUserNotification(vMessage,,,, UserNotificationStatus.Information);
								CancelOperationDocuments(vDocsArray);
							Else
								FillPaymentByAuthorizePayment(vPaymentAttr, vPaymentRef); 
								PaymentIsAuthorized = True;
							EndIf;
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
						ShowUserNotification(vMessage,,,, UserNotificationStatus.Information);
						CancelOperationDocuments(vDocsArray);
					EndIf;
				EndIf;	
			Else
				vCancel = True;
				vMessage = NStr("en='Bill amount is zero!';ru='Сумма заказа равна нулю!';de='Bestellsumme ist null!'");
				ShowUserNotification(vMessage,,,, UserNotificationStatus.Information);
			EndIf;
		EndIf;
	EndIf;
	// Check if we need to print recipt on a windows printer
	vPrtForm = Undefined;
	If IsBlankString(vMessage) And Not vChequePrintCalled And NeedToPrintReceipt(vPrtForm) Then
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
								ShowUserNotification(vMessage,,,, UserNotificationStatus.Information);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Check success
	If Not vCancel Then
		FillButtonBasket();
		// Clear services
		NewBillAction(Commands.NewBillAction);
		// Reset flags
		PaymentIsAuthorized = False;
		ChequeIsPrinted = False;
		// Do message
		ShowUserNotification(NStr("en='Success!'; de='Erfolg!'; ru='Успешно!'"),,,, UserNotificationStatus.Information);
		// Send folio refresh message
		Notify("Document.Folio.Edit");
	EndIf;
EndProcedure // WriteActionConfirmed

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPaymentByAuthorizePayment(pAuthorize, pPayment)
	vObj = pPayment.GetObject();
	vObj.AuthorizationCode = pAuthorize.AuthorizationCode;
	vObj.ReferenceNumber = pAuthorize.ReferenceNumber;
	vObj.SlipText = pAuthorize.SlipText;
	vObj.AnnulationSlipText = pAuthorize.AnnulationSlipText;
	vObj.TerminalNumber = pAuthorize.TerminalNumber;
	vObj.CreditCard = pAuthorize.CreditCard;
	vObj.CardType = pAuthorize.CardType;
	vObj.Write(DocumentWriteMode.Posting);
EndProcedure // FillPaymentByAuthorizePayment

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
		ShowUserNotification(NStr("en='Success!'; de='Erfolg!'; ru='Успешно!'"),,,, UserNotificationStatus.Information);
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
			ChequeIsPrinted = vDriver.pmPrintCheque(vPaymentObj.Sum, vPaymentObj.VATSum, vPaymentObj, vPaymentRef, vMessage, pValue.Password, , False, Undefined, "", "", '00010101');
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
		ShowUserNotification(Nstr("en = 'Work with this device driver is not supported!'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"),, UserNotificationStatus.Information);
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
		ShowUserNotification(Nstr("en = 'Work with this device driver is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"),, NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"),, UserNotificationStatus.Information);
	EndIf;	
	Return True;
EndFunction // AuthorizePayment

// -----------------------------------------------------------------------------
&AtServer
Function CheckCreditCardsProcessingSystem()
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		If SessionParameters.CurrentWorkstation.HasConnectionToCreditCardsProcessingSystem Then
			vArrPaymentTerminal = SessionParameters.CurrentWorkstation.CreditCardsProcessingSystemParameters;
			ArrPaymentTerminal = tcOnServer.cmGetAtributeAsArray(vArrPaymentTerminal);
			ArrPaymentTerminal.ConnectionParameters = ArrPaymentTerminal.ConnectionParameters.Get();
			Return True;
		EndIf;	
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
Function GetServiceByBarCode(pBarCode)
	vMessage = "";
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
	If vServices.Count() = 0 Then
		vMessage = NStr("en='Service is not found!'; ru='Не найдена услуга по штрих-коду!'; de='Service wird nicht gefunden!'");
	ElsIf vServices.Count() > 1 Then
		vMessage = NStr("en='More then 1 service found for the given bar code!'; ru='По штрих-коду найдено более одной услуги!'; de='Es wurde mehr als 1 Service für den angegebenen Barcode gefunden!'");
	Else
		AddService(vServices.Get(0).Ref);
	EndIf;
	Return vMessage;
EndFunction // GetServiceByBarCode

// --------------------------------------------------------------------------------
&AtServer
Procedure FillDefaultFolio(pOpen = False)
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
		SelFolio = GetNewFolio();
	EndIf;
	If ValueIsFilled(SelFolio) Then
		If vDPFolios.FindByValue(SelFolio) = Undefined Then
			vDPFolios.Insert(0, SelFolio, NStr("en='N '; ru='№ '; de='Nr. '") + TrimAll(SelFolio.Number) + ?(IsBlankString(SelFolio.Description), "", " - " + TrimAll(SelFolio.Description)) + ?(ValueIsFilled(SelFolio.Client), " - " + TrimAll(SelFolio.Client.FullName), ""));
		EndIf;
		vClient = SelFolio.Client;
		If ValueIsFilled(vClient) Then
			SelClientType = vClient.ClientType;
		Else
			SelClientType = Catalogs.ClientTypes.EmptyRef();
		EndIf;
		If Not pOpen Then
			FillServicesList();
		EndIf;
	EndIf;
	Items.SelFolio.ChoiceList.Clear();
	For Each vDPFoliosItem In vDPFolios Do
		Items.SelFolio.ChoiceList.Add(vDPFoliosItem.Value, vDPFoliosItem.Presentation);
	EndDo;
EndProcedure // FillDefaultFolio

// -----------------------------------------------------------------------------
Function GetNewFolio()
	vKioskFolioObj = Documents.Folio.CreateDocument();
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
	vKioskFolioObj.Write(DocumentWriteMode.Write);
	Return vKioskFolioObj.Ref;
EndFunction // GetNewFolio

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FillButtonBasket()
	vTitle = NStr("en = 'Basket'; de = 'Korb'; ru = 'Корзина'");
	vPosCount = 0;
	For Each vRow In BillPositions Do
		vPosCount = vPosCount + vRow.Quantity; 	
	EndDo;	
	If vPosCount > 0 Then
		vTitle = vTitle + " (" + vPosCount + " = " + tcOnServer.cmFormattedSumString(BillTotalAmount, tcOnServer.cmGetAttributeByRef(SelHotel, "BaseCurrency")) + ")";  	
	EndIf;
	Items.FormShowBasket.Title = TrimAll(vTitle);
EndProcedure // FillButtonBasket

// -----------------------------------------------------------------------------
&AtClient 
Procedure CalculateBillTotal()
	BillTotalAmount = BillPositions.Total("Amount");
	FillButtonBasket();
EndProcedure // CalculateBillTotal

// -----------------------------------------------------------------------------
&AtServer
Function AddService(pService)
	vResult = False;
	If ValueIsFilled(pService) And Not pService.IsFolder Then
		vRows = BillPositions.FindRows(New Structure("Service", pService));
		If vRows.Count() = 0 Then
			vRow = BillPositions.Add();
			vRow.LineNumber = BillPositions.Count();
			vRow.Service = pService;
			vRow.PaymentSection = vRow.Service.PaymentSection;
			vPrices = pService.GetObject().pmGetServicePrices(SelHotel, SelAccountingDate, SelClientType);
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
					vDiscount = vDiscountType.GetObject().pmGetDiscount(SelAccountingDate, vRow.Service, SelHotel);
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
		Else
			vRow = vRows.Get(0);
		EndIf;
		vRow.Quantity = vRow.Quantity + 1;
		vRow.Amount = Round(vRow.Price * vRow.Quantity, 2);
		vResult = True;
	EndIf;
	Return vResult;
EndFunction // AddService

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
		For Each vPMItem In SelPaymentMethodList Do
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
		SetPaymentMethodPresentation();
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
&AtServer
Procedure SelClientTypeOnChangeAtServer()
	FillServicesList();
EndProcedure // SelClientTypeOnChangeAtServer

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
					SelFolio = GetNewFolio();
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
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SelCashRegisterOnChangeAtServer

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
			SetPaymentMethodPresentation();
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
				If ValueIsFilled(vByFolioPaymentMethod) And SelPaymentMethodList.FindByValue(vByFolioPaymentMethod) <> Undefined Then
					SelPaymentMethod = vByFolioPaymentMethod;
					SetPaymentMethodPresentation();
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
		// Get default folio to be used for the new bill
		FillDefaultFolio();
	Else
		SelRoom = SelFolio.Room;
		SelClient = SelFolio.Client;
		If ValueIsFilled(SelClient) Then
			SelClientType = SelClient.ClientType;
		Else
			SelClientType = Catalogs.ClientTypes.EmptyRef();
		EndIf;
		FillServicesList();
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
&AtClient
Procedure AfterChangePaymentMethod(pItem, pExtraParams) Export 
	If pItem <> Undefined Then
		SelPaymentMethod = pItem.Value;
		SetPaymentMethodPresentation();
		PaymentMethodOnChange();
	EndIf;
EndProcedure // AfterChangePaymentMethod

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentMethodOnChange()
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
EndProcedure // PaymentMethodOnChange

#EndRegion
