
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);

	pObject = FormAttributeToValue("Object");
	pTableBoxCharacteristics = FormAttributeToValue("TableBoxCharacteristics");
	// Load service characteristics
	pTableBoxCharacteristics = pObject.pmGetServiceCharacteristics();
	
	ValueToFormAttribute(pTableBoxCharacteristics,"TableBoxCharacteristics");
	
	// Protect service filter from change
	ServicePrices.Parameters.SetParameterValue("Service", pObject.Ref);
	
	ServicePrices.DynamicDataRead = True;
		
	// Enable service prices
	If Parameters.Key.IsEmpty() Then
		Items.ServicePrices.ReadOnly = True;
	Else
		Items.ServicePrices.ReadOnly = False;
	EndIf;
	
	// Resore setting of prices filter	
	vShowAllPrices = (Items.ServicePricesActionPricesSliceLast.Check);
	
	If vShowAllPrices Then
		Items.ServicePricesActionPricesSliceLast.Check = False;
		Items.ServicePricesActionPricesShowAll.Check = True;
	Else
		Items.ServicePricesActionPricesSliceLast.Check = True;
		Items.ServicePricesActionPricesShowAll.Check = False;
	EndIf;
	
	If Object.IsAgentService Then
		Items.Principal.Enabled = True;
		Items.PrincipalType.Enabled = True;
	Else
		Items.Principal.Enabled = False;
		Items.PrincipalType.Enabled = False;
	EndIf;
	
	If Object.ChequeItemType = Enums.ChequeItemTypes.ExcisableGoods Or 
	   Object.ChequeItemType = Enums.ChequeItemTypes.ExciseWithMarking Or
	   Object.ChequeItemType = Enums.ChequeItemTypes.ExciseWithoutMarking Then
		Items.ExciseDutyType.Enabled = True;
	Else
		Items.ExciseDutyType.Enabled = False;
	EndIf;
	
	If Object.ExciseDutyType = Catalogs.ExciseDutyTypes.SugarContainingBeveragesRU Then
		Items.Volume.Enabled = True;
	Else
		Items.Volume.Enabled = False;
	EndIf;
	
	Items.MarkingCodeType.Enabled = Object.UseMarking;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	If GetCurrentHotel() Then
		If Not ValueIsFilled(Object.PaymentSection) Then
			If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPostPaymentsWithEmptyPaymentSections") Then
				Cancel = True;
				ShowMessageBox(,NStr("en='Payment section should be filled!';ru='Секция оплаты должна быть заполнена!';de='Sektion der Bezahlung muss ausgefüllt sein!'"));
				CurrentItem = Items.PaymentSection;
			EndIf;
		EndIf;
	EndIf;
	If (Not Parameters.Key.IsEmpty()) Then
		// Check if service items are with prices
		vServicePriceFromItems = 0;
		vServicePriceFromItemsCurrency = Undefined;
		vThereAreServiceItemsWithPrices = False;
		If Object.ServiceItems.Count() > 0 Then
			For Each vSrvItemRow In Object.ServiceItems Do
				If vSrvItemRow.Sum <> 0 Then
					vThereAreServiceItemsWithPrices = True;
					vServicePriceFromItems = vServicePriceFromItems + vSrvItemRow.Sum;
					If vServicePriceFromItemsCurrency = Undefined Then
						vServicePriceFromItemsCurrency = vSrvItemRow.Currency;
					ElsIf vServicePriceFromItemsCurrency <> vSrvItemRow.Currency Then
						vThereAreServiceItemsWithPrices = False;
						Break;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		If vThereAreServiceItemsWithPrices Then
			vActivePrices = CurrentHotelServer();
			If vActivePrices <> Undefined Then
				vActivePricesRow = vActivePrices;
				If vActivePricesRow.Currency = vServicePriceFromItemsCurrency Then
					If vActivePricesRow.Price <> vServicePriceFromItems Then
						
						ShowQueryBox(New NotifyDescription("UpdateServicePriceFrom", ThisObject, New Structure("vActivePricesRow,vServicePriceFromItemsCurrency,vServicePriceFromItems", vActivePricesRow, vServicePriceFromItemsCurrency, vServicePriceFromItems)),
						NStr("en='Update service price from " + FormatSumServer(vActivePricesRow.Price, vActivePricesRow.Currency) + " to " + FormatSumServer(vServicePriceFromItems, vServicePriceFromItemsCurrency) + " taken from service item prices?'; 
							               |de='Update service price from " + FormatSumServer(vActivePricesRow.Price, vActivePricesRow.Currency) + " to " + FormatSumServer(vServicePriceFromItems, vServicePriceFromItemsCurrency) + " taken from service item prices?'; 
						                   |ru='Изменить цену услуги с " + FormatSumServer(vActivePricesRow.Price, vActivePricesRow.Currency) + " на " + FormatSumServer(vServicePriceFromItems, vServicePriceFromItemsCurrency) + " рассчитанную по позициям меню?'"), 
						              QuestionDialogMode.YesNo, 60, DialogReturnCode.No);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	
	// Check user rights to use item
	If Parameters.Key.IsEmpty() Then
		If CheckUserServer("HavePermissionToManagePrices") Then
			Cancel = True;
			ShowMessageBox(,NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
		EndIf;
	EndIf;
	
	// Check user rights to edit service
	If CheckUserServer("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;

EndProcedure

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
	
	If vEventData.DeviceType = "BarCodeScaner" Then
		// Check if this is the only service with this bar code
		vServices = CheckServiceBarCode(Object.Ref, vEventData.DeviceData);
		If vServices.Count() > 0 Then
			vService = vServices.Get(0);
			ShowMessageBox(,NStr("en='There is already a service with given bar code! Service is: '; 
								 |ru='Уже есть услуга с данным штрих-кодом! Услуга: '; 
								 |de='There is already a service with given bar code! Service is: '") + TrimAll(vService.Code) + " - " + TrimAll(vService.Description));
			// Clear bar code
			Object.BarCode = "";
		Else
			// Fill bar code
			Object.BarCode = vEventData.DeviceData;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("CatalogRef.ServiceItems") Then
		vSIRow = Object.ServiceItems.Add();
		vSIRow.ServiceItem = pSelectedValue;
		vServiceItemArr = tcOnServer.cmGetAtributeAsArray(pSelectedValue);
		vSIRow.Output = vServiceItemArr.Output;
		If vSIRow.Quantity = 0 Then
			vSIRow.Quantity = vServiceItemArr.Quantity;
		EndIf;
		vSIRow.Unit = vServiceItemArr.Unit;
		vSIRow.Price = vServiceItemArr.Price;
		vSIRow.Currency = vServiceItemArr.Currency;
		If Not ValueIsFilled(vSIRow.Currency) Then
			vHotel = ?(ValueIsFilled(Object.Hotel), Object.Hotel, tcOnServer.cmGetSessionParametersAttribute("CurrentHotel"));
			If ValueIsFilled(vHotel) Then
				vSIRow.Currency = tcOnServer.cmGetAttributeByRef(vHotel, "BaseCurrency");
			EndIf;
		EndIf;
		vSIRow.CostPrice = vServiceItemArr.CostPrice;
		vSIRow.Sum = Round(vSIRow.Quantity * vSIRow.Price, 2);
		vSIRow.CostSum = Round(vSIRow.Quantity * vSIRow.CostPrice, 2);
	EndIf;
EndProcedure // ChoiceProcessing

// -----------------------------------------------------------------------------
&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	vChars = InformationRegisters.ServiceCharacteristics.CreateRecordSet();
	vChars.Filter.Service.Set(Object.Ref);
	For Each vRow In TableBoxCharacteristics Do
		vCharsRec = vChars.Add();
		vCharsRec.Service = Object.Ref;
		vCharsRec.ServiceCharacteristic = vRow.ServiceCharacteristic;
		vCharsRec.ServiceCharacteristicValue = vRow.ServiceCharacteristicValue;
	EndDo;
	vChars.Write(True);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	vObj = FormAttributeToValue("Object");
	pCancel = tcOnServer.cmFillCheckProcessingForm(pCheckedAttributes, CheckedAttributesManual, vObj);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsPriceOnChange(Item)
	ServiceItemsPriceOnChangeServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text",Object.DescriptionTranslations), pItem);	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UnitStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Units.ChoiceForm", , pItem);	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsAgentServiceOnChange(pItem)
	If Object.IsAgentService Then
		Items.Principal.Enabled = True;
		Items.PrincipalType.Enabled = True;
	Else
		Items.Principal.Enabled = False;
		Items.PrincipalType.Enabled = False;
	EndIf;
EndProcedure // IsAgentServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsServiceItemOnChange(pItem)
	ServiceItemsServiceItemOnChangeAtServer(Items.ServiceItems.CurrentRow);
EndProcedure // ServiceItemsServiceItemOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsQuantityOnChange(pItem)
	vSrvItemRow = Items.ServiceItems.CurrentData;
	If vSrvItemRow <> Undefined Then
		vSrvItemRow.Sum = Round(vSrvItemRow.Quantity * vSrvItemRow.Price, 2);
		vSrvItemRow.CostSum = Round(vSrvItemRow.Quantity * vSrvItemRow.CostPrice, 2);
	EndIf;
EndProcedure // ServiceItemsQuantityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsSumOnChange(pItem)
	vSrvItemRow = Items.ServiceItems.CurrentData;
	If vSrvItemRow <> Undefined Then
		If vSrvItemRow.Price = 0 Then
			vSrvItemRow.Price = vSrvItemRow.Sum;
		EndIf;
		vSrvItemRow.Quantity = Round(vSrvItemRow.Sum / vSrvItemRow.Price, 2);
		vSrvItemRow.CostSum = Round(vSrvItemRow.Quantity * vSrvItemRow.CostPrice, 2);
	EndIf;
EndProcedure // ServiceItemsSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsCostPriceOnChange(pItem)
	vSrvItemRow = Items.ServiceItems.CurrentData;
	If vSrvItemRow <> Undefined Then
		vSrvItemRow.CostSum = Round(vSrvItemRow.Quantity * vSrvItemRow.CostPrice, 2);
	EndIf;
EndProcedure // ServiceItemsCostPriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceItemsCostSumOnChange(pItem)
	vSrvItemRow = Items.ServiceItems.CurrentData;
	If vSrvItemRow <> Undefined Then
		If vSrvItemRow.Quantity = 0 Then
			vSrvItemRow.Quantity = 1;
		EndIf;
		vSrvItemRow.CostPrice = Round(vSrvItemRow.CostSum / vSrvItemRow.Quantity, 2);
	EndIf;
EndProcedure // ServiceItemsCostSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BarCodeOnChange(Item)
	If Not IsBlankString(Object.BarCode) Then
		// Check if this is the only service with this bar code
		vServices = CheckServiceBarCode(Object.Ref, Object.BarCode);
		If vServices.Count() > 0 Then
			vService = vServices.Get(0);
			ShowMessageBox(,NStr("en='There is already a service with given bar code! Service is: '; ru='Уже есть услуга с данным штрих-кодом! Услуга: '; de='There is already a service with given bar code! Service is: '") + TrimAll(vService.Code) + " - " + TrimAll(vService.Description));
			// Clear bar code
			Object.BarCode = "";
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChequeItemTypeOnChange(pItem)
	ChequeItemTypeOnChangeAtServer();
EndProcedure // ChequeItemTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExciseDutyTypeOnChange(pItem)
	ExciseDutyTypeOnChangeAtServer();
EndProcedure // ExciseDutyTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure UseMarkingOnChange(pItem)
	Items.MarkingCodeType.Enabled = Object.UseMarking;
	If Not Object.UseMarking Then
		If ValueIsFilled(Object.MarkingCodeType) Then
			Object.MarkingCodeType = Undefined;
		EndIf;
	EndIf;
EndProcedure // UseMarkingOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionPricesSliceLast(Command)
		ActionPricesShowAll(Command);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionPricesShowAll(Command)
	
	If Items.ServicePricesActionPricesShowAll.Check Then
		Items.ServicePricesActionPricesSliceLast.Check = True;
		Items.ServicePricesActionPricesShowAll.Check = False;
		
		ReplaceQueryTextServer(True);
	Else
		Items.ServicePricesActionPricesSliceLast.Check = False;
		Items.ServicePricesActionPricesShowAll.Check = True;
		
		ReplaceQueryTextServer(False);
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionFillComposition(Command)
	ActionFillCompositionServer();	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MenuItemsSelection(pCommand)
	OpenForm("Catalog.ServiceItems.ChoiceForm", New Structure("CloseOnChoice", False), ThisObject, Object.Ref, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // MenuItemsSelection

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ReplaceQueryTextServer(vParamLast)
	
	If vParamLast Then
		ServicePrices.QueryText = StrReplace(ServicePrices.QueryText,"InformationRegister.ServicePrices","InformationRegister.ServicePrices.SliceLast(, )");
		ServicePrices.MainTable = "InformationRegister.ServicePrices.SliceLast";
	Else
		ServicePrices.QueryText = StrReplace(ServicePrices.QueryText,"InformationRegister.ServicePrices.SliceLast(, )","InformationRegister.ServicePrices");
		ServicePrices.MainTable = "InformationRegister.ServicePrices";
	EndIf;
	
	
EndProcedure	
	
// -----------------------------------------------------------------------------
&AtServer
Procedure ActionFillCompositionServer()

If Object.ServiceItems.Count() > 0 Then
		Object.Composition = "";
		For Each vSIRow In Object.ServiceItems Do
			If ValueIsFilled(vSIRow.ServiceItem) Then
				Object.Composition = Object.Composition + TrimAll(vSIRow.ServiceItem.Description) + ?(IsBlankString(vSIRow.Output), "", " (" + TrimAll(vSIRow.Output) + ")") + " - " + cmFormatSum(vSIRow.Price, vSIRow.Currency) + " x " + Format(vSIRow.Quantity, "ND=10; NFD=1; NG=") + TrimAll(vSIRow.Unit) + " = " + cmFormatSum(vSIRow.Sum, vSIRow.Currency) + Chars.LF;
			EndIf;
		EndDo;
		Object.Composition = TrimAll(Object.Composition);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function CheckUserServer(pCheckUser)
	
    Return (Not cmCheckUserPermissions(pCheckUser));	
	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function FormatSumServer(pPrice,pCurrency)
	
	
	Return cmFormatSum(pPrice, pCurrency);
	
		
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function CurrentHotelServer()
	
	  pObject = FormAttributeToValue("Object");
	
	  pSesPar = pObject.pmGetServicePrices(SessionParameters.CurrentHotel, '39991231235959');
	  
	  StructurPriceRow = Undefined;
	  
	  If pSesPar.Count() > 0 Then
		  
		 vActivePricesRow = pSesPar.Get(0); 
		 
		 StructurPriceRow = New Structure("ClientType,Currency,Hotel,Period,Price,Service,VATRate,",vActivePricesRow.ClientType,vActivePricesRow.Currency,vActivePricesRow.Hotel,vActivePricesRow.Period,vActivePricesRow.Price,vActivePricesRow.Service,vActivePricesRow.VATRate);
		 
	  EndIf;
	  
	 
	
	  Return StructurPriceRow;
	
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateServicePriceFrom(resultQuery,param) Export
	
	If resultQuery <> Undefined And resultQuery = DialogReturnCode.Yes Then
		UpdateServicePriceFromServer(param);
	EndIf;
	
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateServicePriceFromServer(param)
	
	vActivePricesRow =  param.vActivePricesRow;
	vServicePriceFromItemsCurrency = param.vServicePriceFromItemsCurrency;
	vServicePriceFromItems = param.vServicePriceFromItems;
	
	vMgr = InformationRegisters.ServicePrices.CreateRecordManager();
	vMgr.Period = vActivePricesRow.Period;
	vMgr.Hotel = vActivePricesRow.Hotel;
	vMgr.ClientType = vActivePricesRow.ClientType;
	vMgr.Service = vActivePricesRow.Service;
	vMgr.Read();
	If vMgr.Selected() Then
		vMgr.Period = vActivePricesRow.Period;
		vMgr.Hotel = vActivePricesRow.Hotel;
		vMgr.ClientType = vActivePricesRow.ClientType;
		vMgr.Service = vActivePricesRow.Service;
		vMgr.Currency = vServicePriceFromItemsCurrency;
		vMgr.Price = vServicePriceFromItems;
		vMgr.Write(True);
	EndIf;
	
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCurrentHotel() 
	
	p = ValueIsFilled(SessionParameters.CurrentHotel) And SessionParameters.CurrentHotel.SplitFolioBalanceByPaymentSections;
    Return p;	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure ServiceItemsPriceOnChangeServer()
	vCurRow = Object.ServiceItems.FindByID(Items.ServiceItems.CurrentRow);
	If vCurRow <> Undefined Then
	   vCurRow.Sum = Round(vCurRow.Price * vCurRow.Quantity, 2);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function  CheckServiceBarCode(pRef, pBarCode)
	
	// Check if this is the only service with this bar code
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Services.Ref
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	NOT Services.IsFolder
	|	AND NOT Services.DeletionMark
	|	AND Services.Ref <> &qThisRef
	|	AND Services.BarCode = &qBarCode";
	vQry.SetParameter("qThisRef", pRef);
	vQry.SetParameter("qBarCode", pBarCode);
	vServices = vQry.Execute().Unload().UnloadColumn("Ref");

	Return vServices;

EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure ServiceItemsServiceItemOnChangeAtServer(pRowId)
	vSrvItemRow = Object.ServiceItems.FindByID(pRowId);
	If vSrvItemRow <> Undefined Then
		If ValueIsFilled(vSrvItemRow.ServiceItem) Then
			If TypeOf(vSrvItemRow.ServiceItem) = Type("CatalogRef.ServiceItems") Then
				FillPropertyValues(vSrvItemRow, vSrvItemRow.ServiceItem);
			EndIf;
			If Not ValueIsFilled(vSrvItemRow.Currency) Then
				vHotel = ?(ValueIsFilled(Object.Hotel), Object.Hotel, SessionParameters.CurrentHotel);
				If ValueIsFilled(vHotel) Then
					vSrvItemRow.Currency = vHotel.BaseCurrency;
				EndIf;
			EndIf;
			If vSrvItemRow.Quantity = 0 Then
				vSrvItemRow.Quantity = 1;
			EndIf;
			vSrvItemRow.Sum = Round(vSrvItemRow.Quantity * vSrvItemRow.Price, 2);
			vSrvItemRow.CostSum = Round(vSrvItemRow.Quantity * vSrvItemRow.CostPrice, 2);
		EndIf;
	EndIf;
EndProcedure // ServiceItemsServiceItemOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ChequeItemTypeOnChangeAtServer()
	If Object.ChequeItemType = Enums.ChequeItemTypes.ExcisableGoods Or 
	   Object.ChequeItemType = Enums.ChequeItemTypes.ExciseWithMarking Or
	   Object.ChequeItemType = Enums.ChequeItemTypes.ExciseWithoutMarking Then
		Items.ExciseDutyType.Enabled = True;
	Else
		Items.ExciseDutyType.Enabled = False;
		
		If ValueIsFilled(Object.ExciseDutyType) Then
			Object.ExciseDutyType = Undefined;
		EndIf;
	EndIf;
	
	If Object.ExciseDutyType = Catalogs.ExciseDutyTypes.SugarContainingBeveragesRU Then
		Items.Volume.Enabled = True;
	Else
		Items.Volume.Enabled = False;
	EndIf;
EndProcedure // ChequeItemTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ExciseDutyTypeOnChangeAtServer()
	If Object.ExciseDutyType = Catalogs.ExciseDutyTypes.SugarContainingBeveragesRU Then
		Items.Volume.Enabled = True;
	Else
		Items.Volume.Enabled = False;
	EndIf;
EndProcedure // ExciseDutyTypeOnChangeAtServer

#EndRegion
