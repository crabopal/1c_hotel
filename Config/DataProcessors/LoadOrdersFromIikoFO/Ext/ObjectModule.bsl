Var TraktirDB;

// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(DateFrom) Then
		DateFrom = BegOfDay(CurrentSessionDate()) - 24*3600;
		DateTo = EndOfDay(DateFrom);
	EndIf;
	If IsBlankString(ExternalSystemCode) Then
		ExternalSystemCode = "IIKO";
	EndIf;
	If IsBlankString(OrdersFileName) Then
		OrdersFileName = "Заказы (счета).csv";
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Load Traktir orders
	pmLoadOrders(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Function DateFromString(Val pStr)
	vDate = '00010101';
	If Not IsBlankString(pStr) Then
		vPos = Find(pStr, ".");
		If vPos = 0 Then
			vPos = Find(pStr, "-");
		EndIf;
		If vPos = 3 Then // DD.MM.YYYY
			If StrLen(pStr) = 10 Then
				vDate = Date(Number(Mid(pStr, 7, 4)), Number(Mid(pStr, 4, 2)), Number(Left(pStr, 2)), 0, 0, 0);
			ElsIf StrLen(pStr) = 16 Then
				vDate = Date(Number(Mid(pStr, 7, 4)), Number(Mid(pStr, 4, 2)), Number(Left(pStr, 2)), Number(Mid(pStr, 12, 2)), Number(Mid(pStr, 15, 2)), 0);
			ElsIf StrLen(pStr) = 19 Then
				vDate = Date(Number(Mid(pStr, 7, 4)), Number(Mid(pStr, 4, 2)), Number(Left(pStr, 2)), Number(Mid(pStr, 12, 2)), Number(Mid(pStr, 15, 2)), Number(Right(pStr, 2)));
			EndIf;
		ElsIf vPos = 5 Then //YYYY.MM.DD
			If StrLen(pStr) = 10 Then
				vDate = Date(Number(Left(pStr, 4)), Number(Mid(pStr, 6, 2)), Number(Mid(pStr, 9, 2)), 0, 0, 0);
			ElsIf StrLen(pStr) = 16 Then
				vDate = Date(Number(Left(pStr, 4)), Number(Mid(pStr, 6, 2)), Number(Mid(pStr, 9, 2)), Number(Mid(pStr, 12, 2)), Number(Mid(pStr, 15, 2)), 0);
			ElsIf StrLen(pStr) = 19 Then
				vDate = Date(Number(Left(pStr, 4)), Number(Mid(pStr, 6, 2)), Number(Mid(pStr, 9, 2)), Number(Mid(pStr, 12, 2)), Number(Mid(pStr, 15, 2)), Number(Right(pStr, 2)));
			EndIf;
		EndIf;
	EndIf;
	Return vDate;
EndFunction // DateFromString

// -----------------------------------------------------------------------------
Function ParseLine(pRow, Val pLine, pRefsCache)
	vSkipLine = False;
	
	i = 0;
	While True Do
		vWord = "";
		vWordIsFound = False;
		
		vPos = Find(pLine, ";");
		If vPos = 1 Then
			vWord = "";
			vWordIsFound = True;
			
			pLine = Mid(pLine, vPos + 1);
		ElsIf vPos > 1 Then
			vWord = Left(pLine, vPos - 1);
			vWordIsFound = True;
			
			pLine = Mid(pLine, vPos + 1);
		Else
			If Not IsBlankString(pLine) Then
				vWord = pLine;
				vWordIsFound = True;
				
				pLine = "";
			EndIf;
		EndIf;
		
		If Not vWordIsFound Then
			Break;
		EndIf;
		
		If i = 0 Then // Accounting date
			pRow.AccountingDate = DateFromString(vWord);
			If ValueIsFilled(pRow.AccountingDate) Then
				If ValueIsFilled(DateFrom) And pRow.AccountingDate < BegOfDay(DateFrom) Then
					vSkipLine = True;
					Break;
				EndIf;
				If ValueIsFilled(DateTo) And pRow.AccountingDate > EndOfDay(DateTo) Then
					vSkipLine = True;
					Break;
				EndIf;
			Else
				Raise NStr("en='Order with empty accounting date is found!'; ru='Найден заказ с пустой учетной датой!'; de='Auftrag mit leerem Buchungsdatum gefunden!'");
			EndIf;				
		ElsIf i = 2 Then // Is posted
			If Lower(vWord) = "false" Then
				vSkipLine = True;
				Break;
			EndIf;
		ElsIf i = 4 Then // Operation type
			pRow.OperationType = Number(vWord);
		ElsIf i = 6 Then // Hotel
			pRow.HotelDescription = vWord;
			If Not IsBlankString(pRow.HotelDescription) Then
				pRow.Hotel = pRefsCache.Hotels.Get(Trimall(pRow.HotelDescription));
				If Not ValueIsFilled(pRow.Hotel) Then
					pRow.Hotel = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), TrimAll(ExternalSystemCode), "Hotels", Trimall(pRow.HotelDescription));
				EndIf;
				// Check if mapping is filled 
				If Not ValueIsFilled(pRow.Hotel) Then
					CheckMappings = True;
				Else
					If ValueIsFilled(Hotel) And pRow.Hotel <> Hotel Then
						vSkipLine = True;
						Break;
					EndIf;
				EndIf;
				// Fill mapping
				If HotelMappings.Find(TrimAll(pRow.HotelDescription), "IIKOBusiness") = Undefined Then
					vMPRow = HotelMappings.Add();
					vMPRow.Hotel = pRow.Hotel;
					vMPRow.IIKOBusiness = TrimAll(pRow.HotelDescription);
				EndIf;
			EndIf;
		ElsIf i = 8 Then // Company
			pRow.CompanyDescription = vWord;
			If Not IsBlankString(pRow.CompanyDescription) Then
				pRow.Company = pRefsCache.Companies.Get(Trimall(pRow.CompanyDescription));
				If Not ValueIsFilled(pRow.Company) Then
					pRow.Company = cmGetObjectRefByExternalSystemCode(Hotel, TrimAll(ExternalSystemCode), "Companies", TrimAll(pRow.CompanyDescription));
				EndIf;
				// Check if mapping is filled 
				If Not ValueIsFilled(pRow.Company) Then
					CheckMappings = True;
				EndIf;
				// Fill mapping
				If CompanyMappings.Find(TrimAll(pRow.CompanyDescription), "IIKOCompany") = Undefined Then
					vMPRow = CompanyMappings.Add();
					vMPRow.Company = pRow.Company;
					vMPRow.IIKOCompany = TrimAll(pRow.CompanyDescription);
				EndIf;
			EndIf;
		ElsIf i = 11 Then // Cash register day number
			pRow.CashRegisterDayNumber = vWord;
		ElsIf i = 13 Then // Cash register number
			pRow.CashRegisterNumber = vWord;
		ElsIf i = 14 Then // Cash register serial number
			pRow.CashRegisterSerialNumber = vWord;
			If Not IsBlankString(pRow.CashRegisterSerialNumber) Then
				pRow.CashRegister = pRefsCache.CashRegisters.Get(TrimAll(pRow.CashRegisterSerialNumber));
				If Not ValueIsFilled(pRow.CashRegister) Then
					pRow.CashRegister = cmGetObjectRefByExternalSystemCode(Hotel, TrimAll(ExternalSystemCode), "CashRegisters", TrimAll(pRow.CashRegisterSerialNumber));
				EndIf;
				// Check if mapping is filled
				If Not ValueIsFilled(pRow.CashRegister) Then
					CheckMappings = True;
				EndIf;
				// Fill mapping
				If CashRegisterMappings.Find(TrimAll(pRow.CashRegisterSerialNumber), "IIKOCashRegisterSerialNumber") = Undefined Then
					vMPRow = CashRegisterMappings.Add();
					vMPRow.CashRegister = pRow.CashRegister;
					vMPRow.IIKOCashRegisterSerialNumber = TrimAll(pRow.CashRegisterSerialNumber);
				EndIf;
			EndIf;
		ElsIf i = 15 Then // Order number
			pRow.OrderNumber = vWord;
		ElsIf i = 16 Then // Order GUID
			pRow.OrderGUID = vWord;
		ElsIf i = 18 Then // Order is closed date
			pRow.OrderIsClosedDate = DateFromString(vWord);
		ElsIf i = 20 Then // Kind of activity
			pRow.KindOfActivity = vWord;
		ElsIf i = 23 Then // Menu item code
			pRow.MenuItemCode = vWord;
		ElsIf i = 24 Then // Menu item description
			pRow.MenuItemDescription = vWord;
			If Not IsBlankString(pRow.MenuItemDescription) Then
				pRow.Service = pRefsCache.Services.Get(TrimAll(pRow.MenuItemDescription));
				If Not ValueIsFilled(pRow.Service) Then
					pRow.Service = cmGetObjectRefByExternalSystemCode(Hotel, TrimAll(ExternalSystemCode), "Services", TrimAll(pRow.MenuItemDescription));
				EndIf;
				// Check if mapping is filled
				If Not ValueIsFilled(pRow.Service) Then
					CheckMappings = True;
				EndIf;
				// Fill mapping
				If ServiceMappings.Find(TrimAll(pRow.MenuItemDescription), "IIKOMenuItem") = Undefined Then
					vMPRow = ServiceMappings.Add();
					vMPRow.Service = pRow.Service;
					vMPRow.IIKOMenuItem = TrimAll(pRow.MenuItemDescription);
				EndIf;
			EndIf;
		ElsIf i = 25 Then // Menu item group code
			pRow.MenuItemGroupCode = vWord;
		ElsIf i = 26 Then // Menu item group description
			pRow.MenuItemGroupDescription = vWord;
		ElsIf i = 27 Then // Menu item type code
			pRow.MenuItemTypeCode = vWord;
		ElsIf i = 28 Then // Menu item type description
			pRow.MenuItemTypeDescription = vWord;
		ElsIf i = 29 Then // Menu item unit code
			pRow.MenuItemUnitCode = vWord;
		ElsIf i = 30 Then // Menu item unit description
			pRow.MenuItemUnitDescription = vWord;
			If Not IsBlankString(pRow.MenuItemUnitDescription) Then
				pRow.Unit = pRefsCache.Units.Get(TrimAll(pRow.MenuItemUnitDescription));
				If Not ValueIsFilled(pRow.Unit) Then
					pRow.Unit = cmGetObjectRefByExternalSystemCode(Hotel, TrimAll(ExternalSystemCode), "Units", TrimAll(pRow.MenuItemUnitDescription));
				EndIf;
				// Check if mapping is filled
				If Not ValueIsFilled(pRow.Unit) Then
					CheckMappings = True;
				EndIf;
				// Fill mapping
				If UnitMappings.Find(TrimAll(pRow.MenuItemUnitDescription), "IIKOUnitName") = Undefined Then
					vMPRow = UnitMappings.Add();
					vMPRow.Unit = pRow.Unit;
					vMPRow.IIKOUnitName = TrimAll(pRow.MenuItemUnitDescription);
				EndIf;
			EndIf;
		ElsIf i = 33 Then // Menu item price
			If Not IsBlankString(vWord) Then
				pRow.Price = Number(vWord);
			Else
				pRow.Price = 0;
			EndIf;
		ElsIf i = 34 Then // Menu item quantity
			If Not IsBlankString(vWord) Then
				pRow.Quantity = Number(vWord);
			Else
				pRow.Quantity = 0;
			EndIf;
		ElsIf i = 35 Then // Menu item amount
			If Not IsBlankString(vWord) Then
				pRow.Sum = Number(vWord);
			Else
				pRow.Sum = 0;
			EndIf;
		ElsIf i = 36 Then // Menu item discount amount
			If Not IsBlankString(vWord) Then
				pRow.DiscountSum = Number(vWord);
			Else
				pRow.DiscountSum = 0;
			EndIf;
		ElsIf i = 37 Then // Menu item VAT rate as number
			pRow.VATRateRate = vWord;
			If Not IsBlankString(pRow.VATRateRate) Then
				pRow.VATRate = pRefsCache.VATRates.Get(TrimAll(pRow.VATRateRate));
				If Not ValueIsFilled(pRow.VATRate) Then
					pRow.VATRate = cmGetObjectRefByExternalSystemCode(Hotel, TrimAll(ExternalSystemCode), "VATRates", TrimAll(pRow.VATRateRate));
				EndIf;
				// Check if mapping is filled
				If Not ValueIsFilled(pRow.VATRate) Then
					CheckMappings = True;
				EndIf;
				// Fill mapping
				If VATRateMappings.Find(TrimAll(pRow.VATRateRate), "IIKOVATRate") = Undefined Then
					vMPRow = VATRateMappings.Add();
					vMPRow.VATRate = pRow.VATRate;
					vMPRow.IIKOVATRate = TrimAll(pRow.VATRateRate);
				EndIf;
			EndIf;
		ElsIf i = 38 Then // Menu item VAT amount
			If Not IsBlankString(vWord) Then
				pRow.VATSum = Number(vWord);
			Else
				pRow.VATSum = 0;
			EndIf;
		ElsIf i = 39 Then // Payment method code
			pRow.PaymentMethodCode = vWord;
		ElsIf i = 40 Then // Payment method description
			pRow.PaymentMethodDescription = vWord;
			If Not IsBlankString(pRow.PaymentMethodDescription) Then
				pRow.PaymentMethod = pRefsCache.PaymentMethods.Get(TrimAll(pRow.PaymentMethodDescription));
				If Not ValueIsFilled(pRow.PaymentMethod) Then
					pRow.PaymentMethod = cmGetObjectRefByExternalSystemCode(Hotel, TrimAll(ExternalSystemCode), "PaymentMethods", TrimAll(pRow.PaymentMethodDescription));
				EndIf;
				// Check if mapping is filled
				If Not ValueIsFilled(pRow.PaymentMethod) Then
					CheckMappings = True;
				EndIf;
				// Fill mapping
				If PaymentMethodMappings.Find(TrimAll(pRow.PaymentMethodDescription), "IIKOPaymentMethodName") = Undefined Then
					vMPRow = PaymentMethodMappings.Add();
					vMPRow.PaymentMethod = pRow.PaymentMethod;
					vMPRow.IIKOPaymentMethodName = TrimAll(pRow.PaymentMethodDescription);
				EndIf;
			EndIf;
		ElsIf i = 41 Then // Payment amount
			If Not IsBlankString(vWord) Then
				pRow.PaymentSum = Number(vWord);
			Else
				pRow.PaymentSum = 0;
			EndIf;
		ElsIf i = 42 Then // Payment is fiscal
			If Lower(vWord) = "true" Then
				pRow.PaymentIsFiscal = True;
			Else
				pRow.PaymentIsFiscal = False;
			EndIf;
		ElsIf i = 43 Then // Customer code
			pRow.CustomerCode = vWord;
		ElsIf i = 44 Then // Customer description
			pRow.CustomerDescription = vWord;
			If Not IsBlankString(pRow.CustomerDescription) Then
				pRow.Customer = pRefsCache.Customers.Get(TrimAll(pRow.CustomerDescription));
				If Not ValueIsFilled(pRow.Customer) Then
					pRow.Customer = cmGetObjectRefByExternalSystemCode(Hotel, TrimAll(ExternalSystemCode), "Customers", TrimAll(pRow.CustomerDescription));
				EndIf;
				// Check if mapping is filled
				If Not ValueIsFilled(pRow.Customer) Then
					CheckMappings = True;
				EndIf;
				// Fill mapping
				If CustomerMappings.Find(TrimAll(pRow.CustomerDescription), "IIKOCustomerName") = Undefined Then
					vMPRow = CustomerMappings.Add();
					vMPRow.Customer = pRow.Customer;
					vMPRow.IIKOCustomerName = TrimAll(pRow.CustomerDescription);
				EndIf;
			EndIf;
		ElsIf i = 50 Then // Remarks
			pRow.Remarks = vWord;
		ElsIf i = 51 Then // Credit card type
			pRow.CreditCardTypeDescription = vWord;
			If Not IsBlankString(pRow.CreditCardTypeDescription) Then
				pRow.CreditCardType = pRefsCache.CreditCardTypes.Get(TrimAll(pRow.CreditCardTypeDescription));
				If Not ValueIsFilled(pRow.CreditCardType) Then
					pRow.CreditCardType = cmGetObjectRefByExternalSystemCode(Hotel, TrimAll(ExternalSystemCode), "CreditCardTypes", TrimAll(pRow.CreditCardTypeDescription));
				EndIf;
				// Check if mapping is filled
				If Not ValueIsFilled(pRow.CreditCardType) Then
					CheckMappings = True;
				EndIf;
				// Fill mapping
				If CreditCardTypeMappings.Find(TrimAll(pRow.CreditCardTypeDescription), "IIKOCreditCardTypeName") = Undefined Then
					vMPRow = CreditCardTypeMappings.Add();
					vMPRow.CreditCardType = pRow.CreditCardType;
					vMPRow.IIKOCreditCardTypeName = TrimAll(pRow.CreditCardTypeDescription);
				EndIf;
			EndIf;
		EndIf;
		
		i = i + 1;
	EndDo;
	
	If Not vSkipLine Then
		If TrimAll(pRow.MenuItemTypeCode) = "2" Then
			If pRow.Sum = 0 And pRow.PaymentSum = 0 Then
				vSkipLine = True;
			EndIf;
		EndIf;
	EndIf;
	
	Return vSkipLine;
EndFunction // ParseLine

// -----------------------------------------------------------------------------
Function pmReadOrdersData() Export
	CheckMappings = False;
	
	// Create value table with orders data
	vOrdersData = New ValueTable();
	vOrdersData.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vOrdersData.Columns.Add("OperationType", cmGetNumberTypeDescription(2, 0)); // 1 - charge, 2 - payment, 3 - discount
	vOrdersData.Columns.Add("HotelDescription", cmGetStringTypeDescription()); // hotel name 
	vOrdersData.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels")); // hotel ref
	vOrdersData.Columns.Add("CompanyDescription", cmGetStringTypeDescription()); // company name 
	vOrdersData.Columns.Add("Company", cmGetCatalogTypeDescription("Companies")); // company ref
	vOrdersData.Columns.Add("CashRegisterDayNumber", cmGetStringTypeDescription()); // cash register day number 
	vOrdersData.Columns.Add("CashRegisterNumber", cmGetStringTypeDescription()); // cash register ID
	vOrdersData.Columns.Add("CashRegisterSerialNumber", cmGetStringTypeDescription()); // cash register serial number
	vOrdersData.Columns.Add("CashRegister", cmGetCatalogTypeDescription("CashRegisters")); // cash register ref
	vOrdersData.Columns.Add("OrderNumber", cmGetStringTypeDescription()); // order number
	vOrdersData.Columns.Add("OrderGUID", cmGetStringTypeDescription()); // order number
	vOrdersData.Columns.Add("OrderIsClosedDate", cmGetDateTimeTypeDescription()); // date and time when order was closed
	vOrdersData.Columns.Add("KindOfActivity", cmGetStringTypeDescription()); // kind of activity name
	vOrdersData.Columns.Add("MenuItemCode", cmGetStringTypeDescription()); // menu item code
	vOrdersData.Columns.Add("MenuItemDescription", cmGetStringTypeDescription()); // menu item name
	vOrdersData.Columns.Add("Service", cmGetCatalogTypeDescription("Services")); // service ref
	vOrdersData.Columns.Add("MenuItemGroupCode", cmGetStringTypeDescription()); // menu item group code (1 - Good)
	vOrdersData.Columns.Add("MenuItemGroupDescription", cmGetStringTypeDescription()); // menu item group description (Good)
	vOrdersData.Columns.Add("MenuItemTypeCode", cmGetStringTypeDescription()); // menu item type code (1 - Сourse, 2 - Modifier)
	vOrdersData.Columns.Add("MenuItemTypeDescription", cmGetStringTypeDescription()); // menu item type description (Сourse, Modifier)
	vOrdersData.Columns.Add("MenuItemUnitCode", cmGetStringTypeDescription()); // menu item unit code (5 - Portion, ...)
	vOrdersData.Columns.Add("MenuItemUnitDescription", cmGetStringTypeDescription()); // menu item type description (Сourse, Modifier)
	vOrdersData.Columns.Add("Unit", cmGetCatalogTypeDescription("Units")); // unit ref
	vOrdersData.Columns.Add("Price", cmGetNumberTypeDescription(17, 2)); // menu item price
	vOrdersData.Columns.Add("Quantity", cmGetNumberTypeDescription(19, 7)); // menu item quantity
	vOrdersData.Columns.Add("Sum", cmGetNumberTypeDescription(17, 2)); // menu item amount
	vOrdersData.Columns.Add("DiscountSum", cmGetNumberTypeDescription(17, 2)); // menu item discount amount
	vOrdersData.Columns.Add("VATRateRate", cmGetStringTypeDescription()); // menu item VAT rate as number
	vOrdersData.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates")); // VAT rate ref
	vOrdersData.Columns.Add("VATSum", cmGetNumberTypeDescription(17, 2)); // menu item VAT amount
	vOrdersData.Columns.Add("PaymentMethodCode", cmGetStringTypeDescription()); // payment method code
	vOrdersData.Columns.Add("PaymentMethodDescription", cmGetStringTypeDescription()); // payment method name
	vOrdersData.Columns.Add("PaymentMethod", cmGetCatalogTypeDescription("PaymentMethods")); // payment method ref
	vOrdersData.Columns.Add("CreditCardTypeDescription", cmGetStringTypeDescription()); // payment card type description
	vOrdersData.Columns.Add("CreditCardType", cmGetCatalogTypeDescription("CreditCardTypes")); // credit card type
	vOrdersData.Columns.Add("PaymentSum", cmGetNumberTypeDescription(17, 2)); // payment amount
	vOrdersData.Columns.Add("PaymentIsFiscal", cmGetBooleanTypeDescription()); // payment is fiscal
	vOrdersData.Columns.Add("CustomerCode", cmGetStringTypeDescription()); // customer code
	vOrdersData.Columns.Add("CustomerDescription", cmGetStringTypeDescription()); // customer name
	vOrdersData.Columns.Add("Customer", cmGetCatalogTypeDescription("Customers")); // customer ref
	vOrdersData.Columns.Add("Contract", cmGetCatalogTypeDescription("Contracts")); // contract ref
	vOrdersData.Columns.Add("Remarks", cmGetStringTypeDescription()); // remarks
	
	// Build catalog item references cache
	vRefsCache = New Structure("Hotels, Companies, CashRegisters, Services, Units, VATRates, PaymentMethods, CreditCardTypes, Customers, Contracts", 
	                           New Map(), New Map(), New Map(), New Map(), New Map(), New Map(), New Map(), New Map(), New Map(), New Map());
	
	// Read file and fill orders value table and mappings
	vTextReader = New TextReader(cmGetFullFileName(TrimAll(OrdersFileName), TrimAll(ExportDirectory)), TextEncoding.ANSI);
	vLine = vTextReader.ReadLine(); // This is header line. We should skip it
	If vLine <> Undefined Then
		vLine = vTextReader.ReadLine();
		While vLine <> Undefined Do
			vOrdersRow = vOrdersData.Add();
			
			// Parse line of csv text
			If ParseLine(vOrdersRow, vLine, vRefsCache) Then
				// Skip this row
				vOrdersData.Delete(vOrdersRow);
			EndIf;
	
			vLine = vTextReader.ReadLine();
		EndDo;
	EndIf;
	
	// Return
	Return vOrdersData;
EndFunction // pmReadOrdersData

// -----------------------------------------------------------------------------
Procedure pmLoadOrders(pIsInteractive, pMappingsCheckMode = False) Export
	// Check parameters
	If Not ValueIsFilled(Hotel) Then
		vMessage = NStr("en='Hotel is not specified. Execution is canceled!';ru='Не задана гостиница. Обработка прервана!';de='Keine Hotel! Die Bearbeitung wurde abgebrochen!'");
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;
		WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromIIKO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзIIKO';de='DataProcessor.LoadOrdersFromIIKO'"), EventLogLevel.Warning, ThisObject.Metadata(), DataProcessor, vMessage);
		Return;
	EndIf;
	If IsBlankString(ExportDirectory) Then
		vMessage = NStr("en='IIKO system export data directory is not specified. Execution is canceled!';ru='Не задана папка с данными из IIKO. Обработка прервана!';de='Keine Angaben Ordner mit Daten aus Iiko! Die Bearbeitung wurde abgebrochen!'");
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;
		WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromIIKO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзIIKO';de='DataProcessor.LoadOrdersFromIIKO'"), EventLogLevel.Warning, ThisObject.Metadata(), DataProcessor, vMessage);
		Return;
	EndIf;	
	If IsBlankString(OrdersFileName) Then
		vMessage = NStr("en='Orders file name is not specified. Execution is canceled!';ru='Не задано имя файла с данными заказов. Обработка прервана!';de='Die Dateinamen mit der Auftragsdaten ist nicht festgelegt! Die Bearbeitung wurde abgebrochen!'");
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;
		WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromIIKO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзIIKO';de='DataProcessor.LoadOrdersFromIIKO'"), EventLogLevel.Warning, ThisObject.Metadata(), DataProcessor, vMessage);
		Return;
	EndIf;
	If IsBlankString(ExternalSystemCode) Then
		ExternalSystemCode = "IIKO";
	EndIf;
	
	vDoNotEditClosedDateDocs = Hotel.DoNotEditClosedDateDocs;
	
	Try
		// Check and change hotel parameters
		vHotelObj = Hotel.GetObject();
		If vDoNotEditClosedDateDocs Then
			vHotelObj.DoNotEditClosedDateDocs = False;
			vHotelObj.Write();
		EndIf;
		
		// Load data
		LoadData(pMappingsCheckMode);
		
		// Restore hotel settings
		If vDoNotEditClosedDateDocs Then
			vHotelObj.DoNotEditClosedDateDocs = True;
			vHotelObj.Write();
		EndIf;
		
		If CheckMappings Then
			If pIsInteractive Then
				Return;
			Else
				Raise NStr("en='Check mappings!'; ru='Не заполнены соответствия данных!'; de='Überprüfen Sie die mappings!'");
			EndIf;
		EndIf;
	Except
		vErrorDescription = ErrorDescription();
		
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		// Restore hotel settings
		If vDoNotEditClosedDateDocs Then
			vHotelObj.DoNotEditClosedDateDocs = True;
			vHotelObj.Write();
		EndIf;
		
		Raise vErrorDescription;
	EndTry;
	
	// Log that processing is finished
	WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromIIKO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзIIKO';de='DataProcessor.LoadOrdersFromIIKO'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of loading restaurant orders!';ru='Выполнение процедуры загрузки заказов ресторана закончено!';de='Das Laden von Restaurantbestellungen ist abgeschlossen!'"));
EndProcedure // pmLoadOrders

// -----------------------------------------------------------------------------
Function GetFolio(pContract, pCompany, pPlaceOfSale = Undefined)
	vFolioObj = Documents.Folio.CreateDocument();
	vFolioObj.pmFillAttributesWithDefaultValues();
	vFolioObj.Company = pCompany;
	vFolioObj.Date = CurrentSessionDate();
	vFolioObj.DateTimeFrom = DateFrom;
	vFolioObj.DateTimeTo = DateTo;
	If BegOfDay(DateFrom) = BegOfDay(DateTo) Then
		vFolioObj.Description = Format(DateFrom, "DF=dd.MM.yyyy") + NStr("en=' - Load from IIKO';ru=' - Загрузка из IIKO';de=' - Laden aus IIKO'") + ?(ValueIsFilled(pPlaceOfSale), ", " + pPlaceOfSale, "");
	Else
		vFolioObj.Description = Format(DateFrom, "DF=dd.MM.yyyy") + " - " + Format(DateTo, "DF=dd.MM.yyyy") + NStr("en=' - Load from IIKO';ru=' - Загрузка из IIKO';de=' - Laden aus IIKO'") + ?(ValueIsFilled(pPlaceOfSale), ", " + pPlaceOfSale, "");
	EndIf;
	If ValueIsFilled(pContract) Then
		vFolioObj.Customer = pContract.Owner;
		vFolioObj.Contract = pContract;
	EndIf;
	vFolioObj.Write();
	Return vFolioObj.Ref;
EndFunction // GetFolio

// -----------------------------------------------------------------------------
Procedure LoadData(pMappingsCheckMode = False)
	// Read file data
	vTOrders = pmReadOrdersData();
	If CheckMappings Or pMappingsCheckMode Then
		Return;
	EndIf;
	
	// Build value table with payments
	vTPayments = vTOrders.Copy();
	vTPayments.Clear();
	
	vAlreadyLoadedOrders = New ValueList();
	
	// Fill payments and delete unneccessary records
	i = 0;
	While i < vTOrders.Count() Do
		vOrderRow = vTOrders.Get(i);
		
		If vOrderRow.Sum = 0 And vOrderRow.Quantity = 0 And vOrderRow.OperationType = 1 Then
			vTOrders.Delete(i);
			Continue;
		EndIf;
		
		// Skip this order if it is already loaded
		vExtCode = TrimAll(vOrderRow.OrderGUID);
		If vAlreadyLoadedOrders.FindByValue(vExtCode) <> Undefined Then
			vTOrders.Delete(i);
			Continue;
		Else
			vPaymentDoc = GetPaymentByExtCode(vExtCode);
			If ValueIsFilled(vPaymentDoc) Then
				vAlreadyLoadedOrders.Add(vExtCode);
				vTOrders.Delete(i);
				Continue;
			EndIf;
		EndIf;
		
		If vOrderRow.OperationType = 2 Then
			vPaymentRow = vTPayments.Add();
			FillPropertyValues(vPaymentRow, vOrderRow);
			vTOrders.Delete(i);
			Continue;
		ElsIf vOrderRow.OperationType <> 1 Then
			vTOrders.Delete(i);
			Continue;
		EndIf;
		
		i = i + 1;
	EndDo;
	
	// Delete orders and payments that should be skipped
	vOrdersToDeleteList = New ValueList();
	For Each vPMToSkipRow In PaymentMethodsToSkip Do
		vPaymentMethodToSkip = vPMToSkipRow.PaymentMethod;
		If ValueIsFilled(vPaymentMethodToSkip) Then
			i = 0;
			While i < vTPayments.Count() Do
				vPaymentRow = vTPayments.Get(i);
				
				If vPaymentRow.PaymentMethod = vPaymentMethodToSkip Then
					If vOrdersToDeleteList.FindByValue(TrimAll(vPaymentRow.OrderGUID)) = Undefined Then
						vOrdersToDeleteList.Add(TrimAll(vPaymentRow.OrderGUID));
					EndIf;
					
					vTPayments.Delete(i);
					Continue;
				EndIf;
				
				i = i + 1;
			EndDo;
		EndIf;
	EndDo;
	If vOrdersToDeleteList.Count() > 0 Then
		For Each vOrdersToDeleteItem In vOrdersToDeleteList Do
			vOrderToDeleteGUID = vOrdersToDeleteItem.Value;
			If Not IsBlankString(vOrderToDeleteGUID) Then
				vOrdersToDeleteRows = vTOrders.FindRows(New Structure("OrderGUID", vOrderToDeleteGUID));
				For Each vOrdersToDeleteRow In vOrdersToDeleteRows Do
					vTOrders.Delete(vOrdersToDeleteRow);
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	// Write folio orders and payments
	vCurFolio = Undefined;
	vCurContract = Undefined;
	vCurOrderGUID = "";
	For Each vOrderRow In vTOrders Do
		If vCurContract = Undefined Then
			vCurContract = vOrderRow.Contract;
		EndIf;
		If vCurFolio = Undefined Then
			vCurFolio = GetFolio(vCurContract, vOrderRow.Company);
		EndIf;
		
		// Check if order has changed
		If IsBlankString(vCurOrderGUID) Then
			vCurOrderGUID = TrimAll(vOrderRow.OrderGUID);
			
			BeginTransaction(DataLockControlMode.Managed);
		ElsIf vCurOrderGUID <> TrimAll(vOrderRow.OrderGUID) Then
			// Do payment
			vOrderPayments = vTPayments.FindRows(New Structure("OrderGUID", vCurOrderGUID));
			j = 0;
			For Each vPaymentRow In vOrderPayments Do
				If vPaymentRow.PaymentSum >= 0 Then
					CreatePayment(vCurFolio, vPaymentRow, j);
				Else
					CreateReturn(vCurFolio, vPaymentRow, j);
				EndIf;
				j = j + 1;
			EndDo; 
			
			If TransactionActive() Then
				CommitTransaction();
			EndIf;
			
			vCurOrderGUID = TrimAll(vOrderRow.OrderGUID);
			
			BeginTransaction(DataLockControlMode.Managed);
		EndIf;
		
		// Always create new folio to see what was loaded this time only
		If vCurContract <> vOrderRow.Contract Then
			// Close folio
			If ValueIsFilled(vCurFolio) Then
				vFolioObj = vCurFolio.GetObject();
				vFolioObj.IsClosed = True;
				vFolioObj.Write();
				
				// Create settlement by folio
				If CreateSettlement Then
					CreateSettlement(vFolioObj.Ref);
				EndIf;
			EndIf;
			
			vCurContract = vOrderRow.Contract;
			vCurFolio = GetFolio(vCurContract, vOrderRow.Company);
		EndIf;
		
		// Do charge
		CreateCharge(vCurFolio, vOrderRow);
		
		#IF CLIENT THEN		
			Status(NStr("en='Loaded ';ru='Загружено ';de='Geladen '") + Format(vTOrders.IndexOf(vOrderRow) + 1, "ND=10; NFD=0; NZ=; NG=") + NStr("en=' order items from ';ru=' позиций заказов из ';de=' Bestellungen aus '") + Format(vTOrders.Count(), "ND=10; NFD=0; NZ=; NG=") + "...");
			UserInterruptProcessing();
		#ENDIF
	EndDo; // By orders
	
	// Do payment for last order
	vOrderPayments = vTPayments.FindRows(New Structure("OrderGUID", vCurOrderGUID));
	j = 0;
	For Each vPaymentRow In vOrderPayments Do
		If vPaymentRow.PaymentSum >= 0 Then
			CreatePayment(vCurFolio, vPaymentRow, j);
		Else
			CreateReturn(vCurFolio, vPaymentRow, j);
		EndIf;
		j = j + 1;
	EndDo; 
	
	If TransactionActive() Then
		CommitTransaction();
	EndIf;
	
	// Close last folio
	If vCurFolio <> Undefined Then
		vFolioObj = vCurFolio.GetObject();
		vFolioObj.IsClosed = True;
		vFolioObj.Write();
		
		// Create settlement by folio
		If CreateSettlement Then
			CreateSettlement(vFolioObj.Ref);
		EndIf;
	EndIf;
	
	// Close or repost cash register days
	vTCashRegisters = vTPayments.Copy();
	vTCashRegisters.GroupBy("CashRegister, Company", );
	For Each vCashRegisterRow In vTCashRegisters Do
		If Not ValueIsFilled(vCashRegisterRow.CashRegister) Then
			Continue;
		EndIf;
		
		vCashRegisterRef = vCashRegisterRow.CashRegister;
		vCompanyRef = vCashRegisterRow.Company;
		
		vCurDate = EndOfDay(DateFrom);
		While vCurDate <= EndOfDay(DateTo) Do
			// Check if close cash register day document exists. Repost it if yes
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	CloseOfCashRegisterDay.Ref
			|FROM
			|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
			|WHERE
			|	CloseOfCashRegisterDay.Posted
			|	AND CloseOfCashRegisterDay.CashRegister = &qCashRegister
			|	AND CloseOfCashRegisterDay.Date = &qDate";
			vQry.SetParameter("qCashRegister", vCashRegisterRef);
			vQry.SetParameter("qDate", vCurDate);
			vQryRes = vQry.Execute().Unload();
			If vQryRes.Count() > 0 Then
				vCloseOfCRD = vQryRes.Get(0).Ref.GetObject();
				vCloseOfCRD.Write(DocumentWriteMode.Posting);
				
				vCurDate = vCurDate + 24*3600;
				Continue;
			EndIf;
			
			// Write new close of cash register day document
			CreateCloseOfCashRegisterDay(vCompanyRef, vCashRegisterRef, vCurDate);
			
			vMessage = Format(vCurDate, "DF=dd.MM.yyyy") + NStr("en=' - Cash register day is closed for ';ru=' - Закрыта смена по ККМ ';de=' - Schichtnach der Registrierkasse geschlossen '") + TrimAll(vCashRegisterRef) + "...";
			WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromIIKO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзIIKO';de='DataProcessor.LoadOrdersFromIIKO'"), EventLogLevel.Information, ThisObject.Metadata(), DataProcessor, vMessage);
			#IF CLIENT THEN
				Status(vMessage);
				UserInterruptProcessing();
			#ENDIF
			
			vCurDate = vCurDate + 24*3600;
		EndDo;
	EndDo; // By cash registers
EndProcedure // LoadData

// -----------------------------------------------------------------------------
Procedure CreatePayment(vCurFolio, vPaymentRow, pIndex)
	vPaymentObj = Documents.Payment.CreateDocument();
	If ValueIsFilled(vPaymentRow.OrderIsClosedDate) And BegOfDay(vPaymentRow.OrderIsClosedDate) = vPaymentRow.AccountingDate Then
		vPaymentObj.Date = vPaymentRow.OrderIsClosedDate;
	Else
		vPaymentObj.Date = vPaymentRow.AccountingDate;
	EndIf;
	vPaymentObj.Author = SessionParameters.CurrentUser;
	vPaymentObj.Hotel = vCurFolio.Hotel;
	If Year(vPaymentObj.Date) <> Year(CurrentSessionDate()) Then
		vPaymentObj.SetNewNumber();
	EndIf;
	vPaymentObj.AuthorizationCode = "0";
	vPaymentObj.ReferenceNumber = "0";
	vPaymentObj.Folio = vCurFolio;
	vPaymentObj.CashRegister = vPaymentRow.CashRegister;
	vPaymentObj.Company = vCurFolio.Company;
	If ValueIsFilled(vCurFolio.Customer) Then
		vPaymentObj.AccountingCustomer = vCurFolio.Customer;
		vPaymentObj.AccountingContract = vCurFolio.Contract;
	Else
		vPaymentObj.AccountingCustomer = Hotel.IndividualsCustomer;
		vPaymentObj.AccountingContract = Hotel.IndividualsContract;
	EndIf;
	vPaymentObj.ExchangeRateDate = BegOfDay(vPaymentRow.AccountingDate);
	vPaymentObj.FolioCurrency = vCurFolio.FolioCurrency;
	vPaymentObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vPaymentObj.Hotel, vPaymentObj.FolioCurrency, vPaymentObj.ExchangeRateDate);
	vPaymentObj.PaymentCurrency = vPaymentObj.FolioCurrency;
	vPaymentObj.PaymentCurrencyExchangeRate = vPaymentObj.FolioCurrencyExchangeRate;
	vPaymentObj.PaymentMethod = vPaymentRow.PaymentMethod;
	vPaymentObj.CardType = vPaymentRow.CreditCardType;
	vPaymentObj.Remarks = NStr("en='Order N ';ru='Заказ № ';de='Bestellung Nr.'") + vPaymentRow.OrderNumber + ?(IsBlankString(vPaymentRow.Remarks), "", " - " + TrimAll(vPaymentRow.Remarks));
	vPaymentObj.ExternalCode = TrimAll(vPaymentRow.OrderGUID) + ?(pIndex = 0, "", "/" + TrimAll(pIndex)); 
	vPaymentObj.Sum = vPaymentRow.PaymentSum;
	vPaymentObj.SumInFolioCurrency = vPaymentRow.PaymentSum;
	vPaymentObj.VATRate = vPaymentRow.Company.VATRate;
	vPaymentObj.VATSum = cmCalculateVATSum(vPaymentObj.VATRate, vPaymentObj.Sum, vPaymentObj.Date);
	vPaymentObj.VATSumInFolioCurrency = cmCalculateVATSum(vPaymentObj.VATRate, vPaymentObj.SumInFolioCurrency, vPaymentObj.Date);
	vPaymentObj.PaymentSection = PaymentSection;	
	vPaymentObj.Write(DocumentWriteMode.Posting);
EndProcedure // CreatePayment

// -----------------------------------------------------------------------------
Procedure CreateReturn(vCurFolio, vPaymentRow, pIndex)
	vReturnObj = Documents.Return.CreateDocument();
	If ValueIsFilled(vPaymentRow.OrderIsClosedDate) And BegOfDay(vPaymentRow.OrderIsClosedDate) = vPaymentRow.AccountingDate Then
		vReturnObj.Date = vPaymentRow.OrderIsClosedDate;
	Else
		vReturnObj.Date = vPaymentRow.AccountingDate;
	EndIf;
	vReturnObj.Author = SessionParameters.CurrentUser;
	vReturnObj.Hotel = vCurFolio.Hotel;
	If Year(vReturnObj.Date) <> Year(CurrentSessionDate()) Then
		vReturnObj.SetNewNumber();
	EndIf;
	vReturnObj.AuthorizationCode = "0";
	vReturnObj.ReferenceNumber = "0";
	vReturnObj.Folio = vCurFolio;
	vReturnObj.CashRegister = vPaymentRow.CashRegister;
	vReturnObj.Company = vCurFolio.Company;
	If ValueIsFilled(vCurFolio.Customer) Then
		vReturnObj.AccountingCustomer = vCurFolio.Customer;
		vReturnObj.AccountingContract = vCurFolio.Contract;
	Else
		vReturnObj.AccountingCustomer = Hotel.IndividualsCustomer;
		vReturnObj.AccountingContract = Hotel.IndividualsContract;
	EndIf;
	vReturnObj.ExchangeRateDate = BegOfDay(vPaymentRow.AccountingDate);
	vReturnObj.FolioCurrency = vCurFolio.FolioCurrency;
	vReturnObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vReturnObj.Hotel, vReturnObj.FolioCurrency, vReturnObj.ExchangeRateDate);
	vReturnObj.PaymentCurrency = vReturnObj.FolioCurrency;
	vReturnObj.PaymentCurrencyExchangeRate = vReturnObj.FolioCurrencyExchangeRate;
	vReturnObj.PaymentMethod = vPaymentRow.PaymentMethod;
	vReturnObj.CardType = vPaymentRow.CreditCardType;
	vReturnObj.Remarks = NStr("en='Order N ';ru='Заказ № ';de='Bestellung Nr.'") + vPaymentRow.OrderNumber + ?(IsBlankString(vPaymentRow.Remarks), "", " - " + TrimAll(vPaymentRow.Remarks));
	vReturnObj.ExternalCode = TrimAll(vPaymentRow.OrderGUID) + ?(pIndex = 0, "", "/" + TrimAll(pIndex)); 
	vReturnObj.Sum = -vPaymentRow.PaymentSum;
	vReturnObj.SumInFolioCurrency = -vPaymentRow.PaymentSum;
	vReturnObj.VATRate = vPaymentRow.Company.VATRate;
	vReturnObj.VATSum = cmCalculateVATSum(vReturnObj.VATRate, vReturnObj.Sum, vReturnObj.Date);
	vReturnObj.VATSumInFolioCurrency = cmCalculateVATSum(vReturnObj.VATRate, vReturnObj.SumInFolioCurrency, vReturnObj.Date);
	vReturnObj.Write(DocumentWriteMode.Posting);
EndProcedure // CreateReturn

// -----------------------------------------------------------------------------
Procedure CreateCharge(vCurFolio, vOrderRow)
	vChargeObj = Documents.Charge.CreateDocument();
	If ValueIsFilled(vOrderRow.OrderIsClosedDate) And BegOfDay(vOrderRow.OrderIsClosedDate) = vOrderRow.AccountingDate Then
		vChargeObj.Date = vOrderRow.OrderIsClosedDate;
	Else
		vChargeObj.Date = vOrderRow.AccountingDate; 
	EndIf;
	vChargeObj.Author = SessionParameters.CurrentUser;
	vChargeObj.pmFillByFolio(vCurFolio);
	If Year(vChargeObj.Date) <> Year(CurrentSessionDate()) Then
		vChargeObj.SetNewNumber();
	EndIf;
	vChargeObj.IsAdditional = True;
	vChargeObj.Quantity = ?(vOrderRow.Quantity = 0, 1, vOrderRow.Quantity);
	If vOrderRow.DiscountSum = 0 Then
		vChargeObj.Sum = vOrderRow.Sum;
		vChargeObj.Price = Round(vOrderRow.Sum/vOrderRow.Quantity, 2);
	Else
		vBruttoSum = vOrderRow.Sum + vOrderRow.DiscountSum;
		vChargeObj.Sum = vBruttoSum;
		vChargeObj.Price = Round(vBruttoSum/vOrderRow.Quantity, 2);
		vChargeObj.Discount = Round(vOrderRow.DiscountSum/(vBruttoSum/100), 3);
		vChargeObj.DiscountSum = vOrderRow.DiscountSum;
	EndIf;
	vChargeObj.Remarks = NStr("en='Order N ';ru='Заказ № ';de='Bestellung Nr.'") + vOrderRow.OrderNumber + " - " + TrimAll(vOrderRow.MenuItemDescription);
	vChargeObj.Details = TrimAll(vOrderRow.Remarks);
	vChargeObj.ExchangeRateDate = BegOfDay(vOrderRow.AccountingDate); 
	vChargeObj.ReportingCurrency = vChargeObj.Hotel.ReportingCurrency;
	vChargeObj.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.ReportingCurrency, vChargeObj.ExchangeRateDate);
	vChargeObj.Service = vOrderRow.Service;
	If ValueIsFilled(vOrderRow.Service) Then
		vChargeObj.PaymentSection = vOrderRow.Service.PaymentSection;
	EndIf;
	vChargeObj.Unit = TrimAll(vOrderRow.Unit);
	vChargeObj.VATRate = vOrderRow.VATRate;
	vChargeObj.VATSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.Sum, vChargeObj.Date);
	vChargeObj.Write(DocumentWriteMode.Posting);
EndProcedure // CreateCharge

// -----------------------------------------------------------------------------
Procedure CreateSettlement(vCurFolio);
	vSettlementObj = Documents.Settlement.CreateDocument();
	vSettlementObj.pmFillAttributesWithDefaultValues();
	vSettlementObj.pmFillByFolio(vCurFolio);
	vSettlementObj.Remarks = NStr("en='Load from IIKO';ru='Загрузка из IIKO';de='Ladevorgang aus dem IIKO'");
	vSettlementObj.DoNotExportToTheAccountingSystem = SetDoNotExportToTheAccountingSystem;
	vSettlementObj.Write();
	vSettlementObj.Write(DocumentWriteMode.Posting);
EndProcedure // CreateSettlement

// -----------------------------------------------------------------------------
Procedure CreateCloseOfCashRegisterDay(vCompanyRef, vCashRegisterRef, vCurDate)
	vCloseOfCRD = Documents.CloseOfCashRegisterDay.CreateDocument();
	vCloseOfCRD.Company = vCompanyRef;
	vCloseOfCRD.pmFillAttributesWithDefaultValues();
	vCloseOfCRD.Date = EndOfDay(vCurDate);
	If Year(vCloseOfCRD.Date) <> Year(CurrentSessionDate()) Then
		vCloseOfCRD.SetNewNumber();
	EndIf;
	vCloseOfCRD.CashRegister = vCashRegisterRef;
	vCloseOfCRD.ZReportType = vCashRegisterRef.ZReportType;
	If Not ValueIsFilled(vCloseOfCRD.ZReportType) Then
		vCloseOfCRD.ZReportType = Enums.ZReportTypes.Transactions;
	EndIf;
	vDateFrom = vCloseOfCRD.pmCalculateDateFrom(vCloseOfCRD.Date);
	If Not ValueIsFilled(vDateFrom) Then
		vCloseOfCRD.DateFrom = '20000101';
	Else
		vCloseOfCRD.DateFrom = vDateFrom;
	EndIf;
	If BegOfDay(DateFrom) = BegOfDay(DateTo) Then
		vCloseOfCRD.Remarks = Format(DateFrom, "DF=dd.MM.yyyy") + NStr("en=' - Load orders from IIKO FO'; ru=' - Загрузка заказов из IIKO ФО'; de=' - Load orders from IIKO FO'");
	Else
		vCloseOfCRD.Remarks = Format(DateFrom, "DF=dd.MM.yyyy") + " - " + Format(DateTo, "DF=dd.MM.yyyy") + NStr("en=' - Load orders from IIKO FO'; ru=' - Загрузка заказов из IIKO ФО'; de=' - Load orders from IIKO FO'");
	EndIf;
	vCloseOfCRD.Write(DocumentWriteMode.Posting);
	// Check if there are close of shift documents after current one. If yes we need to repost it
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CloseOfCashRegisterDay.Ref
	|FROM
	|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
	|WHERE
	|	CloseOfCashRegisterDay.Date > &qPeriod
	|	AND CloseOfCashRegisterDay.CashRegister = &qCashRegister
	|	AND CloseOfCashRegisterDay.Posted
	|
	|ORDER BY
	|	CloseOfCashRegisterDay.Date";
	vQry.SetParameter("qPeriod", EndOfDay(vCurDate));
	vQry.SetParameter("qCashRegister", vCashRegisterRef);
	vFutureDocs = vQry.Execute().Unload();
	For Each vFutureDocsRow In vFutureDocs Do
		vFutureCloseOfCRD = vFutureDocsRow.Ref.GetObject();
		vFutureCloseOfCRD.Write(DocumentWriteMode.UndoPosting);
	EndDo;
	For Each vFutureDocsRow In vFutureDocs Do
		vFutureCloseOfCRD = vFutureDocsRow.Ref.GetObject();
		vFutureCloseOfCRD.Write(DocumentWriteMode.Posting);
	EndDo;
EndProcedure // CreateCloseOfCashRegisterDay

// -----------------------------------------------------------------------------
Procedure pmSaveExternalSystemObjectMapping(pHotelRef, pExternalSystemCode, pObjectTypeName, pObjectCode, pExtObjectCode) Export
	// Try to find object ref by code
	If pObjectTypeName = "CashRegisters" Then
		vObjectRef = Catalogs[pObjectTypeName].FindByCode(TrimR(pObjectCode), False);
	Else
		vObjectRef = Catalogs[pObjectTypeName].FindByCode(TrimR(pObjectCode), False, , pHotelRef);
	EndIf;
	// Try to update existing mapping or create new one
	vMgrObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
	vMgrObj.Hotel = pHotelRef;
	vMgrObj.ExternalSystemCode = TrimR(pExternalSystemCode);
	vMgrObj.ObjectTypeName = TrimR(pObjectTypeName);
	vMgrObj.ObjectExternalCode = TrimR(pExtObjectCode);
	vMgrObj.ObjectRef = vObjectRef;
	vMgrObj.Write(True);
EndProcedure // pmSaveExternalSystemObjectMapping

// -----------------------------------------------------------------------------
Function GetPaymentByExtCode(pExtCode)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Payments.Ref AS Ref
	|FROM
	|	Document.Payment AS Payments
	|WHERE
	|	Payments.ExternalCode = &qExternalCode
	|	AND Payments.Posted
	|	AND Payments.Hotel = &qHotel
	|
	|ORDER BY
	|	Payments.PointInTime DESC";
	vQry.SetParameter("qExternalCode", TrimAll(pExtCode));
	vQry.SetParameter("qHotel", Hotel);
	vPayments = vQry.Execute().Unload();
	If vPayments.Count() > 0 Then
		Return vPayments.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetPaymentByExtCode
