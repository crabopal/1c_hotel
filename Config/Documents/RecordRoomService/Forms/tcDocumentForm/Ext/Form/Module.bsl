
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)  	
	vObj = FormAttributeToValue("Object"); 
	If vObj.IsNew() Then
		// Use current time by default
		vObj.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
	EndIf;
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(vObj.Hotel) And SessionParameters.CurrentHotel <> vObj.Hotel Then
			pCancel = True;
		EndIf;
	EndIf;	
	// Check edit prohibited date
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Hotel.EditProhibitedDate) And 
		   BegOfDay(vObj.Hotel.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	// Check user permissions to edit discounts
	If Not cmCheckUserPermissions("HavePermissionToAddManualDiscounts") Then
		Items.DiscountCard.Enabled = False;
		Items.DiscountType.Enabled = False;
		Items.Discount.Enabled = False;
		Items.DiscountServiceGroup.Enabled = False;
		Items.DiscountSumInFolioCurrency.Enabled = False;
		Items.VATDiscountSumInFolioCurrency.Enabled = False;
		Items.FixedServiceDiscountSumInFolioCurrency.Enabled = False;
		Items.FixedServiceVATDiscountSumInFolioCurrency.Enabled = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToChooseClientTypeManually") Then
		Items.ClientType.Enabled = False;
		ClientTypeIsDisabled = True;
	EndIf;
	// Fill folio descriptions
	FillFolioDescriptions(vObj);
	// Set document number and date appearances
	If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
		Items.Number.ReadOnly = True;
		Items.Number.Enabled = False;
		Items.Date.ReadOnly = True;
		Items.Date.Enabled = False;
		Items.Date.ChoiceButton = False;
	EndIf;
	// Check if this document is closed by settlement
	If vObj.Posted Then
		If ValueIsFilled(vObj.Hotel) And vObj.Hotel.DoNotEditSettledDocs And 
		  (vObj.Sum <> 0 Or vObj.Quantity <> 0) And ValueIsFilled(vObj.Folio) And vObj.Folio.IsClosed And 
		   cmGetRoomServiceDocumentCharges(vObj.Ref).Count() > 0 Then
			vDocBalanceIsZero = False;
			vDocBalancesRow = cmGetRoomServiceDocumentCurrentAccountsReceivableBalance(vObj.Ref);
			If vDocBalancesRow <> Undefined Then
				If vDocBalancesRow.SumBalance = 0 And vDocBalancesRow.QuantityBalance = 0 Then
					vDocBalanceIsZero = True;
				EndIf;
			Else
				vDocBalanceIsZero = True;
			EndIf;
			If vDocBalanceIsZero Then
				ReadOnly = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'This charge is closed by settlement! Charge will be opened read only.'; 
																|de = 'Die Anrechnung wurde bereits über ein Übergabeprotokoll über die Erbringung von Dienstleistungen geschlossen! Die Bearbeitung einer solchen Anrechnung ist verboten.'; 
																|ru = 'Начисление уже закрыто актом об оказании услуг! Редактирование такого начисления запрещено.'"));
			EndIf;
		EndIf;
	EndIf;
	// Save current document date
	OldDate = vObj.Date;
	ValueToFormAttribute(vObj, "Object");   
	
	ClientTypeIsDisabled = False; 
	RefreshDisplay();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel,pWriteParameters)
	Var vMessage; 
	Var vAttributeInErr;
	// Before posting actions
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Check document attributes 		
		pCancel = CheckDocumentAttributesAtServer(vMessage, vAttributeInErr);
		If pCancel Then
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
		Else
			// Always undo posting first to repost document
			If Object.Posted Then
				pWriteParameters.WriteMode = DocumentWriteMode.Write;
			EndIf;
		EndIf;
	EndIf; 
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	// Notify changes in the accounts subsystem
	Notify("Subsystem.Accounts.Changed", Object.Folio); 
EndProcedure // AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	CompanyOnChangeAtServer();
EndProcedure // CompanyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(pItem)
	RoomOnChangeAtServer();
EndProcedure // RoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioOnChange(pItem)
	FolioOnChangeAtServer();
EndProcedure // FolioOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	ClientTypeOnChangeAtServer();
EndProcedure // ClientTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceDateOnChange(pItem)
	ServiceDateOnChangeAtServer();
EndProcedure // ServiceDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceOnChange(pItem)
	PriceOnChangeAtServer();
EndProcedure // PriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure QuantityOnChange(pItem)
	QuantityOnChangeAtServer();
EndProcedure // QuantityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomServicePriceIsWithVATOnChange(pItem)
	RoomServicePriceIsWithVATOnChangeAtServer();
EndProcedure // RoomServicePriceIsWithVATOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomServiceOnChange(pItem)
	RoomServiceOnChangeAtServer();
EndProcedure // RoomServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure VATRateOnChange(pItem)
	VATRateOnChangeAtServer();
EndProcedure // VATRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SumOnChange(pItem)
	SumOnChangeAtServer();
EndProcedure // SumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedServiceVATRateOnChange(pItem)
	FixedServiceVATRateOnChangeAtServer();
EndProcedure // FixedServiceVATRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedServiceSumOnChange(pItem)
	FixedServiceSumOnChangeAtServer();
EndProcedure // FixedServiceSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedServiceOnChange(pItem)
	FixedServiceOnChangeAtServer();
EndProcedure // FixedServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardOnChange(pItem)
	DiscountCardOnChangeAtServer();
EndProcedure // DiscountCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(pItem)
	DiscountTypeOnChangeAtServer();
EndProcedure // DiscountTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountOnChange(pItem)
	DiscountOnChangeAtServer();
EndProcedure // DiscountOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountServiceGroupOnChange(pItem)
	DiscountServiceGroupOnChangeAtServer();
EndProcedure // DiscountServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionOnChange(pItem)
	AgentCommissionOnChangeAtServer();
EndProcedure // AgentCommissionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionTypeOnChange(pItem)
	AgentCommissionTypeOnChangeAtServer();
EndProcedure // AgentCommissionTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionServiceGroupOnChange(pItem)
	AgentCommissionServiceGroupOnChangeAtServer();
EndProcedure // AgentCommissionServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeRateDateOnChange(pItem)
	ExchangeRateDateOnChangeAtServer();
EndProcedure // ExchangeRateDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrencyOnChange(pItem)
	CurrencyOnChangeAtServer();
EndProcedure // CurrencyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioCurrencyExchangeRateOnChange(pItem)
	FolioCurrencyExchangeRateOnChangeAtServer();
EndProcedure // FolioCurrencyExchangeRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrencyExchangeRateOnChange(pItem)
	CurrencyExchangeRateOnChangeAtServer();
EndProcedure // CurrencyExchangeRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReportingCurrencyOnChange(pItem)
	ReportingCurrencyOnChangeAtServer();
EndProcedure // ReportingCurrencyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFolioDescriptions(pObj)
	If ValueIsFilled(pObj.Folio) Then
		FolioDescription = ?(IsBlankString(pObj.Folio.Description), "", TrimAll(pObj.Folio.Description) + ", ") + ?(ValueIsFilled(pObj.Folio.Client), TrimAll(pObj.Folio.Client) + ", ", ?(ValueIsFilled(pObj.Folio.Customer), TrimAll(pObj.Folio.Customer) + ", ", "")) + 
		                   ?(ValueIsFilled(pObj.Folio.Room), TrimAll(pObj.Folio.Room) + ", ", "") + 
		                   ?(ValueIsFilled(pObj.Folio.DateTimeFrom), Format(pObj.Folio.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + Format(pObj.Folio.DateTimeTo, "DF='dd.MM.yy HH:mm'"), "");
		FolioCustomerDescription = TrimAll(pObj.Folio.Customer) + ?(ValueIsFilled(pObj.Folio.Contract), " - " + TrimAll(pObj.Folio.Contract), "");
		FolioParentDocDescription = TrimAll(pObj.Folio.ParentDoc);
	Else
		FolioDescription = "";
		FolioCustomerDescription = "";
		FolioParentDocDescription = "";
	EndIf;
EndProcedure // FillFolioDescriptions

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(pMessage, pAttributeInErr)
	vObj = FormAttributeToValue("Object");	
	Return vObj.pmCheckDocumentAttributes(pMessage, pAttributeInErr);  
EndFunction // CheckDocumentAttributesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		//Get object value
		vObj = FormAttributeToValue("Object");
	EndIf;
	If ValueIsFilled(vObj.Company) Then
		If Not ValueIsFilled(vObj.RoomService) Then
			vObj.VATRate = vObj.Company.VATRate;
		EndIf;
		If Not ValueIsFilled(vObj.FixedService) Then
			vObj.FixedServiceVATRate = vObj.Company.VATRate;
		EndIf;
	EndIf;
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // CompanyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Room) Then
		vFolio = vObj.pmGetFolioToChargeTo();
		If ValueIsFilled(vFolio) And vFolio <> vObj.Folio Then
			vObj.Folio = vFolio;
			FolioOnChangeAtServer(vObj);
		EndIf;
		If Not ValueIsFilled(vObj.Folio) Then
			If ValueIsFilled(vObj.Room.Company) Then
				vObj.Company = vObj.Room.Company;
				CompanyOnChangeAtServer(vObj);
			EndIf;
		EndIf;
	EndIf; 
	ValueToFormAttribute(vObj, "Object");
EndProcedure // RoomOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FolioOnChangeAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	vObj.pmFillByFolio();
	FillFolioDescriptions(vObj);
	vObj.pmRecalculateSums();
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // FolioOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClientTypeOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	If ValueIsFilled(vObj.RoomService) Then
		vSrvPrices = vObj.RoomService.GetObject().pmGetServicePrices(vObj.Hotel, vObj.Date, vObj.ClientType);
		For Each vSrvPricesRow In vSrvPrices Do
			If ValueIsFilled(vSrvPricesRow.VATRate) Then
				vObj.VATRate = vSrvPricesRow.VATRate;
			EndIf;
			Break;
		EndDo;
	EndIf;
	If ValueIsFilled(vObj.FixedService) Then
		vSrvPrices = vObj.FixedService.GetObject().pmGetServicePrices(vObj.Hotel, vObj.Date, vObj.ClientType);
		For Each vSrvPricesRow In vSrvPrices Do
			If ValueIsFilled(vSrvPricesRow.VATRate) Then
				vObj.FixedServiceSum = Round(cmConvertCurrencies(vSrvPricesRow.Price, vSrvPricesRow.Currency, , 
		                                                    vObj.Currency, vObj.CurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
				vObj.FixedServiceVATRate = vSrvPricesRow.VATRate;
			EndIf;
			Break;
		EndDo;
	EndIf;
	// Fill discount type and other discount parameters if filled
	If ValueIsFilled(vObj.ClientType) Then
		If ValueIsFilled(vObj.ClientType.DiscountType) Then
			vObj.DiscountType = vObj.ClientType.DiscountType;
			vObj.DiscountServiceGroup = vObj.DiscountType.DiscountServiceGroup;
			vDiscountTypeObj = vObj.DiscountType.GetObject();
			vObj.Discount = vDiscountTypeObj.pmGetDiscount(vObj.Date, , vObj.Hotel);
		EndIf;
	EndIf;
	// Recalculate all sums
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");  
	RefreshDisplay();
EndProcedure // ClientTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServiceDateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vFolio = vObj.pmGetFolioToChargeTo();
	If ValueIsFilled(vFolio) Then
		vObj.Folio = vFolio;
		ValueToFormAttribute(vObj, "Object");
		FolioOnChangeAtServer();
	EndIf;
	ValueToFormAttribute(vObj, "Object");  
EndProcedure // ServiceDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PriceOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object"); 
EndProcedure // PriceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure QuantityOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // QuantityOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomServicePriceIsWithVATOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // RoomServicePriceIsWithVATOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomServiceOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	If ValueIsFilled(vObj.RoomService) Then
		vSrvPrices = vObj.RoomService.GetObject().pmGetServicePrices(vObj.Hotel, vObj.Date, vObj.ClientType);
		For Each vSrvPricesRow In vSrvPrices Do
			If ValueIsFilled(vSrvPricesRow.VATRate) Then
				vObj.VATRate = vSrvPricesRow.VATRate;
			EndIf;
			Break;
		EndDo;
		If IsBlankString(vObj.Unit) Then
			vObj.Unit = vObj.RoomService.Unit;
		EndIf;
		If IsBlankString(vObj.RoomServiceChargeType) Then
			vObj.pmFillRoomServiceChargeType();
		EndIf;
		If ValueIsFilled(vObj.Room) Then
			vFolio = vObj.pmGetFolioToChargeTo();
			If ValueIsFilled(vFolio) And vFolio <> vObj.Folio Then
				vObj.Folio = vFolio;
				ValueToFormAttribute(vObj, "Object");
				FolioOnChangeAtServer();
			EndIf;
		EndIf;
	EndIf;
	vObj.pmRecalculateSums(); 
	ValueToFormAttribute(vObj, "Object");
EndProcedure // RoomServiceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure VATRateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // VATRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SumOnChangeAtServer()  	
	vObj = FormAttributeToValue("Object");	
	vRecalculatePrice = True;
	If ValueIsFilled(vObj.RoomService) Then
		vRecalculatePrice = vObj.RoomService.RecalculatePriceWhenSumChanged;
	EndIf;
	If vRecalculatePrice Then
		// Recalculate price
		If vObj.RoomServicePriceIsWithVAT Then
			vObj.Price = Round(vObj.Sum/?(vObj.Quantity = 0, 1, vObj.Quantity), 2);
		Else
			vSumWithoutVAT = vObj.Sum;
			If ValueIsFilled(vObj.VATRate) Then
				vSumWithoutVAT = Round(vObj.Sum * 100/(100 + cmGetVATTaxRate(vObj.VATRate, vObj.Date)), 2);
				vObj.Price = Round(vSumWithoutVAT/?(vObj.Quantity = 0, 1, vObj.Quantity), 2);
			EndIf;
		EndIf;
	Else
		// Recalculate quantity
		If vObj.RoomServicePriceIsWithVAT Then
			vObj.Quantity = Round(vObj.Sum/?(vObj.Price = 0, 0, vObj.Price), 7);
		Else
			vSumWithoutVAT = vObj.Sum;
			If ValueIsFilled(vObj.VATRate) Then
				vSumWithoutVAT = Round(vObj.Sum * 100/(100 + cmGetVATTaxRate(vObj.VATRate, vObj.Date)), 2);
				vObj.Quantity = Round(vSumWithoutVAT/?(vObj.Price = 0, 0, vObj.Price), 7);
			EndIf;
		EndIf;
	EndIf;
	// Recalculate bound sums
	vObj.pmRecalculateSums();
EndProcedure // SumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FixedServiceVATRateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // FixedServiceVATRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FixedServiceSumOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // FixedServiceSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FixedServiceOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	If ValueIsFilled(vObj.FixedService) Then
		vSrvPrices = vObj.FixedService.GetObject().pmGetServicePrices(vObj.Hotel, vObj.Date, vObj.ClientType);
		For Each vSrvPricesRow In vSrvPrices Do
			If ValueIsFilled(vSrvPricesRow.VATRate) Then
				vObj.FixedServiceSum = Round(cmConvertCurrencies(vSrvPricesRow.Price, vSrvPricesRow.Currency, , 
		                                                    vObj.Currency, vObj.CurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
				vObj.FixedServiceVATRate = vSrvPricesRow.VATRate;
			EndIf;
			Break;
		EndDo;
	EndIf;
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // FixedServiceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountCardOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	If ValueIsFilled(vObj.DiscountCard) Then
		If BegOfDay(vObj.ServiceDate) >= vObj.DiscountCard.ValidFrom And
		   BegOfDay(vObj.ServiceDate) < ?(ValueIsFilled(vObj.DiscountCard.ValidTo), vObj.DiscountCard.ValidTo, EndOfDay(vObj.ServiceDate)) Then
			vObj.DiscountType = vObj.DiscountCard.DiscountType;
			// Add card ID to the discount confirmation text
			DiscountTypeOnChangeAtServer();
		Else
			vMessage = "ru='Дисконтная карта не действует на дату оказания услуги!'; 
			           |de='Discount card is not valid on charging date!'; 
			           |en='Discount card is not valid on charging date!'";
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage));
			vObj.DiscountCard = Catalogs.DiscountCards.EmptyRef();
		EndIf;
	EndIf; 
	ValueToFormAttribute(vObj, "Object");  
EndProcedure // DiscountCardOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountTypeOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Discount
	If ValueIsFilled(vObj.DiscountType) Then
		vObj.DiscountServiceGroup = vObj.DiscountType.DiscountServiceGroup;
		vDiscountTypeObj = vObj.DiscountType.GetObject();
		vObj.Discount = vDiscountTypeObj.pmGetDiscount(vObj.Date, vObj.RoomService, vObj.Hotel);
	Else
		vObj.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		vObj.Discount = 0;
	EndIf;
	vObj.pmRecalculateSums(); 
	ValueToFormAttribute(vObj, "Object");
EndProcedure // DiscountTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // DiscountOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountServiceGroupOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // DiscountServiceGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentCommissionOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // AgentCommissionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentCommissionTypeOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // AgentCommissionTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentCommissionServiceGroupOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // AgentCommissionServiceGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ExchangeRateDateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Currency) Then
			vObj.CurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.Currency, vObj.ExchangeRateDate);
		Else
			vObj.CurrencyExchangeRate = 0;
		EndIf;
		If ValueIsFilled(vObj.FolioCurrency) Then
			vObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.FolioCurrency, vObj.ExchangeRateDate);
		Else
			vObj.FolioCurrencyExchangeRate = 0;
		EndIf;
		If ValueIsFilled(vObj.ReportingCurrency) Then
			vObj.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.ReportingCurrency, vObj.ExchangeRateDate);
		Else
			vObj.ReportingCurrencyExchangeRate = 0;
		EndIf;
	Else
		vObj.CurrencyExchangeRate = 0;
		vObj.FolioCurrencyExchangeRate = 0;
		vObj.ReportingCurrencyExchangeRate = 0;
	EndIf;
	vObj.pmRecalculateSums(); 
	ValueToFormAttribute(vObj, "Object");
EndProcedure // ExchangeRateDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CurrencyOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Currency) Then
			vObj.CurrencyExchangeRate = cmGetCurrencyExchangeRate(vObj.Hotel, vObj.Currency, vObj.ExchangeRateDate);
		Else
			vObj.CurrencyExchangeRate = 0;
		EndIf;
	Else
		vObj.CurrencyExchangeRate = 0;
	EndIf;
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // CurrencyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FolioCurrencyExchangeRateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // FolioCurrencyExchangeRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CurrencyExchangeRateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	vObj.pmRecalculateSums();
	ValueToFormAttribute(vObj, "Object");     
EndProcedure // CurrencyExchangeRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ReportingCurrencyOnChangeAtServer()
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.ReportingCurrency) Then
			Object.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.ReportingCurrency, Object.ExchangeRateDate);
		Else
			Object.ReportingCurrencyExchangeRate = 0;
		EndIf;
	Else
		Object.ReportingCurrencyExchangeRate = 0;
	EndIf;
EndProcedure // ReportingCurrencyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	// Automatically assign new document number if year has changed
	If ValueIsFilled(vObj.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(vObj.Date) Then
			vObj.SetNewNumber();
		EndIf;
		OldDate = vObj.Date;
	EndIf;
	ValueToFormAttribute(vObj, "Object");     
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()    	
	vClientTypesAllowed = cmGetAllClientTypes();
	// Set client type appearance
	If Not ClientTypeIsDisabled Then
		If vClientTypesAllowed.Count() > 0 Then
			If ValueIsFilled(Object.ClientType) Then
				If vClientTypesAllowed.Find(Object.ClientType, "ClientType") = Undefined Then
					Items.ClientType.Enabled = False;
				Else
					Items.ClientType.Enabled = True;
				EndIf;
			Else
				Items.ClientType.Enabled = True;
			EndIf;
		EndIf;
	EndIf; 	     
EndProcedure // RefreshDisplay 

#EndRegion
   