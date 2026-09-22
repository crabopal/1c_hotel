
#Region Variables

Var OldDate;
Var ClientTypeIsDisabled ;

#EndRegion 

#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vObj = FormAttributeToValue("Object");
	If vObj.Ref.IsEmpty() Then
		vObj.Date = CurrentSessionDate();
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
	EndIf;
	// Check edit prohibited date
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Hotel.EditProhibitedDate) And 
		   BegOfDay(vObj.Hotel.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
			ThisForm.ReadOnly = True;
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
		Items.PerCallDiscountSumInFolioCurrency.Enabled = False;
		Items.PerCallVATDiscountSumInFolioCurrency.Enabled = False;
		Items.LabelDiscountConfirmationText.Enabled = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToChooseClientTypeManually") Then
		Items.ClientType.Enabled = False;
		Items.LabelClientTypeConfirmationText.Enabled = False;
		ClientTypeIsDisabled = True;
	EndIf;
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
		   vObj.cmGetRoomServiceDocumentCharges(vObj.Ref).Count() > 0 Then
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
				ThisForm.ReadOnly = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This charge is closed by settlement! Charge will be opened read only.';ru='Начисление уже закрыто актом об оказании услуг! Редактирование такого начисления запрещено.';de='Die Anrechnung wurde bereits über ein Übergabeprotokoll über die Erbringung von Dienstleistungen geschlossen! Die Bearbeitung einer solchen Anrechnung ist verboten.'"));
			EndIf;
		EndIf;
	EndIf;
	// Save current document date
	OldDate = vObj.Date;
	ValueToFormData(vObj, Object);
EndProcedure

&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	Var vMessage; 
	Var vAttributeInErr;
	// Clear messages window
	ClearMessages();
	// Before posting actions
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Check document attributes
		pCancel = CheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			ShowMessageBox(,NStr(vMessage));
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributes(pMessage, pAttributeInErr)
	vObj = FormAttributeToValue("Object");
	vCancel = vObj.pmCheckDocumentAttributes(pMessage, pAttributeInErr);
	If vCancel Then
		WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, , vObj.Ref, NStr(pMessage));
	EndIf;
	
	Return vCancel;
EndFunction	

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(WriteParameters)
	// Notify changes in the accounts subsystem
	Notify("Subsystem.Accounts.Changed", Object.Folio);
EndProcedure



#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PhoneNumberOnChange(Item)
	PhoneNumberOnChangeAtServer();
	If ValueIsFilled(Object.Room) Then
		RoomOnChange(Items.Room);
		vFolio = GetFolioToChargeTo();
		If ValueIsFilled(vFolio) Then
			Object.Folio = vFolio;
			FolioOnChange(Items.Folio);
		EndIf;
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(Item)
	RoomOnChangeAtServer();
	If ValueIsFilled(Object.Folio) Then
		FolioOnChange(Items.Folio);
	EndIf;
	If ValueIsFilled(Object.Company) Then
		CompanyOnChange(Items.Company);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioOnChange(Item)
	FolioOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(Item)
	CompanyOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TargetPhoneNumberOnChange(Item)
	TargetPhoneNumberOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateSums(Item)
	RecalculateSumsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(Item)
	ClientTypeOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PhoneCallServiceOnChange(Item)
	PhoneCallServiceOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SumOnChange(Item)
	SumOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PerCallServiceOnChange(Item)
	PerCallServiceOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardOnChange(Item)
	If ValueIsFilled(Object.DiscountCard) Then
		vMessage = "";
		DiscountCardOnChangeAtServer(vMessage);
		If Not IsBlankString(vMessage) Then
			vMessage = "ru='Дисконтная карта не действует на дату оказания услуги!'; 
			|de='Discount card is not valid on charging date!'; 
			|en='Discount card is not valid on charging date!'";
			ShowMessageBox(,NStr(vMessage));
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(Item)
	DiscountTypeOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeRateDateOnChange(Item)
	ExchangeRateDateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CurrencyOnChangeAtServer()
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.Currency) Then
			Object.CurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.Currency, Object.ExchangeRateDate);
		Else
			Object.CurrencyExchangeRate = 0;
		EndIf;
	Else
		Object.CurrencyExchangeRate = 0;
	EndIf;
	// Recalculate all sums
	RecalculateSumsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrencyOnChange(Item)
	CurrencyOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ReportingCurrencyOnChange(Item)
	ReportingCurrencyOnChangeAtServer();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure PhoneNumberOnChangeAtServer()
	If ValueIsFilled(Object.PhoneNumber) Then
		Object.Room = Object.PhoneNumber.Room;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetFolioToChargeTo()
	vObj = FormAttributeToValue("Object");
	Return vObj.pmGetFolioToChargeTo();
EndFunction	

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.PhoneNumber) Then
		Object.Room = vObj.PhoneNumber.Room;
	EndIf;
	If ValueIsFilled(Object.Room) Then
		vFolio = vObj.pmGetFolioToChargeTo();
		If ValueIsFilled(vFolio) Then
			Object.Folio = vFolio;
		EndIf;
		If Not ValueIsFilled(Object.Folio) Then
			If ValueIsFilled(Object.Room.Company) Then
				Object.Company = Object.Room.Company;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FolioOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmFillByFolio();
	vObj.pmRecalculateSums();
	ValueToFormData(vObj, Object);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer()
	If ValueIsFilled(Object.Company) Then
		If Not ValueIsFilled(Object.PhoneCallService) Then
			Object.VATRate = Object.Company.VATRate;
		EndIf;
		If Not ValueIsFilled(Object.PerCallService) Then
			Object.PerCallServiceVATRate = Object.Company.VATRate;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure TargetPhoneNumberOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If Not IsBlankString(Object.TargetPhoneNumber) Then
		vObj.pmFillPhoneCallType();
		vObj.pmFillPhoneCallRegion();
	EndIf;
	ValueToFormData(vObj, Object);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateSumsAtServer()
	// Recalculate all sums
	vObj = FormAttributeToValue("Object");
	vObj.pmRecalculateSums();
	ValueToFormData(vObj, Object);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ClientTypeOnChangeAtServer()
	If ValueIsFilled(Object.PhoneCallService) Then
		vSrvPrices = Object.PhoneCallService.GetObject().pmGetServicePrices(Object.Hotel, Object.Date, Object.ClientType);
		For Each vSrvPricesRow In vSrvPrices Do
			If ValueIsFilled(vSrvPricesRow.VATRate) Then
				Object.VATRate = vSrvPricesRow.VATRate;
			EndIf;
			Break;
		EndDo;
	EndIf;
	If ValueIsFilled(Object.PerCallService) Then
		vSrvPrices = Object.PerCallService.GetObject().pmGetServicePrices(Object.Hotel, Object.Date, Object.ClientType);
		For Each vSrvPricesRow In vSrvPrices Do
			If ValueIsFilled(vSrvPricesRow.VATRate) Then
				Object.PerCallSum = Round(cmConvertCurrencies(vSrvPricesRow.Price, vSrvPricesRow.Currency, , 
		                                              Object. Currency, Object.CurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
				Object.PerCallServiceVATRate = vSrvPricesRow.VATRate;
			EndIf;
			Break;
		EndDo;
	EndIf;
	// Fill discount type and other discount parameters if filled
	If ValueIsFilled(Object.ClientType) Then
		If ValueIsFilled(Object.ClientType.DiscountType) Then
			DiscountType = Object.ClientType.DiscountType;
			Object.DiscountConfirmationText = Object.ClientTypeConfirmationText;
			Object.DiscountServiceGroup = Object.DiscountType.DiscountServiceGroup;
			vDiscountTypeObj = Object.DiscountType.GetObject();
			Object.Discount = vDiscountTypeObj.pmGetDiscount(Object.Date, , Object.Hotel);
		EndIf;
	EndIf;
	// Recalculate all sums
	RecalculateSumsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure PhoneCallServiceOnChangeAtServer()
	If ValueIsFilled(Object.PhoneCallService) Then
		vSrvPrices = Object.PhoneCallService.GetObject().pmGetServicePrices(Object.Hotel, Object.Date, Object.ClientType);
		For Each vSrvPricesRow In vSrvPrices Do
			If ValueIsFilled(vSrvPricesRow.VATRate) Then
				Object.VATRate = vSrvPricesRow.VATRate;
			EndIf;
			Break;
		EndDo;
		If IsBlankString(Object.Unit) Then
			Object.Unit = Object.PhoneCallService.Unit;
		EndIf;
	EndIf;
	// Recalculate all sums
	RecalculateSumsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SumOnChangeAtServer()
	vRecalculatePrice = True;
	If ValueIsFilled(Object.PhoneCallService) Then
		vRecalculatePrice = Object.PhoneCallService.RecalculatePriceWhenSumChanged;
	EndIf;
	If vRecalculatePrice Then
		// Recalculate price
		If Object.PhoneCallPriceIsWithVAT Then
			Object.Price = Round(Object.Sum/?(Object.Quantity = 0, 1, Object.Quantity), 2);
		Else
			vSumWithoutVAT = Object.Sum;
			If ValueIsFilled(Object.VATRate) Then
				vSumWithoutVAT = Round(Object.Sum * 100/(100 + cmGetVATTaxRate(Object.VATRate, Object.Date)), 2);
				Object.Price = Round(vSumWithoutVAT/?(Object.Quantity = 0, 1, Object.Quantity), 2);
			EndIf;
		EndIf;
	Else
		// Recalculate quantity
		If Object.PhoneCallPriceIsWithVAT Then
			Object.Quantity = Round(Object.Sum/?(Object.Price = 0, 0, Object.Price), 7);
		Else
			vSumWithoutVAT = Object.Sum;
			If ValueIsFilled(Object.VATRate) Then
				vSumWithoutVAT = Round(Object.Sum * 100/(100 + cmGetVATTaxRate(Object.VATRate, Object.Date)), 2);
				Object.Quantity = Round(vSumWithoutVAT/?(Object.Price = 0, 0, Object.Price), 7);
			EndIf;
		EndIf;
	EndIf;
	// Recalculate all sums
	RecalculateSumsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure PerCallServiceOnChangeAtServer()
	If ValueIsFilled(Object.PerCallService) Then
		vSrvPrices = Object.PerCallService.GetObject().pmGetServicePrices(Object.Hotel, Object.Date, Object.ClientType);
		For Each vSrvPricesRow In vSrvPrices Do
			If ValueIsFilled(vSrvPricesRow.VATRate) Then
				Object.PerCallSum = Round(cmConvertCurrencies(vSrvPricesRow.Price, vSrvPricesRow.Currency, , 
		                                              Object.Currency, Object.CurrencyExchangeRate, Object.ExchangeRateDate, Object.Hotel), 2);
				Object.PerCallServiceVATRate = vSrvPricesRow.VATRate;
			EndIf;
			Break;
		EndDo;
	EndIf;
	// Recalculate all sums
	RecalculateSumsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountCardOnChangeAtServer(pMessage)
	If BegOfDay(Object.PhoneCallDate) >= Object.DiscountCard.ValidFrom And
		BegOfDay(Object.PhoneCallDate) < ?(ValueIsFilled(Object.DiscountCard.ValidTo), Object.DiscountCard.ValidTo, EndOfDay(Object.PhoneCallDate)) Then
		Object.DiscountType = Object.DiscountCard.DiscountType;
		// Add card ID to the discount confirmation text
		Object.DiscountConfirmationText = Object.DiscountCard.Metadata().Synonym + " " + TrimAll(Object.DiscountCard.Description);
		DiscountTypeOnChangeAtServer();
	Else
		pMessage = "ru='Дисконтная карта не действует на дату оказания услуги!'; 
		|de='Discount card is not valid on charging date!'; 
		|en='Discount card is not valid on charging date!'";
		Object.DiscountCard = Catalogs.DiscountCards.EmptyRef();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountTypeOnChangeAtServer()
	If Not ValueIsFilled(Object.DiscountType) Then
		pAskForConfirmation = False;
	EndIf;
	// Discount
	If ValueIsFilled(Object.DiscountType) Then
		DiscountServiceGroup = Object.DiscountType.DiscountServiceGroup;
		vDiscountTypeObj = Object.DiscountType.GetObject();
		Object.Discount = vDiscountTypeObj.pmGetDiscount(Object.Date, Object.PhoneCallService, Object.Hotel);
	Else
		Object.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		Object.Discount = 0;
	EndIf;
	// Recalculate all sums
	RecalculateSumsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ExchangeRateDateOnChangeAtServer()
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.Currency) Then
			Object.CurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.Currency, Object.ExchangeRateDate);
		Else
			Object.CurrencyExchangeRate = 0;
		EndIf;
		If ValueIsFilled(Object.FolioCurrency) Then
			Object.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.FolioCurrency, Object.ExchangeRateDate);
		Else
			Object.FolioCurrencyExchangeRate = 0;
		EndIf;
		If ValueIsFilled(Object.ReportingCurrency) Then
			Object.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, Object.ReportingCurrency, Object.ExchangeRateDate);
		Else
			Object.ReportingCurrencyExchangeRate = 0;
		EndIf;
	Else
		Object.CurrencyExchangeRate = 0;
		Object.FolioCurrencyExchangeRate = 0;
		Object.ReportingCurrencyExchangeRate = 0;
	EndIf;
	// Recalculate all sums
	RecalculateSumsAtServer();
EndProcedure

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
EndProcedure

#EndRegion




