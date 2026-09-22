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
	If ValueIsFilled(Hotel) Then
		If NOT ValueIsFilled(Service) Then
			Service = Hotel.CateringService;
		EndIf;
	EndIf;
	If Not ValueIsFilled(DateFrom) Then
		DateFrom = BegOfDay(CurrentSessionDate()) - 24*3600;
		DateTo = EndOfDay(DateFrom);
	EndIf;
	If IsBlankString(ExternalSystemCode) Then
		ExternalSystemCode = "TraktirFO3";
	EndIf;
	If LoadFromPeriod = 0 Then
		LoadFromPeriod = 2;
	EndIf;
	If IsBlankString(TraktirDBVersion) Then
		TraktirDBVersion = "82";
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
Function pmReadOrderData(pOrder, pTraktirDB) Export
	// Run query to read order data
	vQ = pTraktirDB.NewObject("Query");
	vQ.Text = 
	"ВЫБРАТЬ
	|	КатегорииЗаказа.Заказ,
	|	ЕСТЬNULL(КатегорииЗаказа.КатегорияТовара.Наименование, """") КАК КатегорияТовараНаименование,
	|	КатегорииЗаказа.Сумма,
	|	ЕСТЬNULL(ПротоколРасчетов.СуммаОплаты, 0) КАК СуммаОплаты
	|ИЗ
	|	(ВЫБРАТЬ
	|		ЗаказТовары.Ссылка КАК Заказ,
	|		ЗаказТовары.Товар.Категория КАК КатегорияТовара,
	|		СУММА(ЕСТЬNULL(ЗаказТовары.СуммаРеализации, 0) - ЕСТЬNULL(ВозвратТовары.Сумма, 0)) КАК Сумма
	|	ИЗ
	|		Документ.Заказ.Товары КАК ЗаказТовары
	|			ЛЕВОЕ СОЕДИНЕНИЕ Документ.Возврат.Товары КАК ВозвратТовары
	|			ПО ЗаказТовары.Ссылка = ВозвратТовары.Ссылка.Заказ
	|				И ЗаказТовары.Товар = ВозвратТовары.Товар
	|	ГДЕ
	|		ЗаказТовары.Ссылка = &Заказ
	|		И ЕСТЬNULL(ЗаказТовары.СуммаРеализации, 0) - ЕСТЬNULL(ВозвратТовары.Сумма, 0) > 0
	|	
	|	СГРУППИРОВАТЬ ПО
	|		ЗаказТовары.Ссылка,
	|		ЗаказТовары.Товар.Категория) КАК КатегорииЗаказа
	|		ЛЕВОЕ СОЕДИНЕНИЕ (ВЫБРАТЬ
	|			ПротоколРасчетовПротокол.Ссылка.Заказ КАК Заказ,
	|			СУММА(ЕСТЬNULL(ПротоколРасчетовПротокол.СуммаФакт, 0) - ЕСТЬNULL(Возврат.Сумма, 0)) КАК СуммаОплаты
	|		ИЗ
	|			Документ.ПротоколРасчетов.Протокол КАК ПротоколРасчетовПротокол
	|				ЛЕВОЕ СОЕДИНЕНИЕ Документ.Возврат КАК Возврат
	|				ПО ПротоколРасчетовПротокол.Ссылка.Заказ = Возврат.Заказ
	|		ГДЕ
	|			ПротоколРасчетовПротокол.Ссылка.Заказ = &Заказ
	|			И ПротоколРасчетовПротокол.Ссылка.Проведен
	|			И ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.НаНомер)
	|			И ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.НаФолио)
	|			И ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.Безнал)
	|		
	|		СГРУППИРОВАТЬ ПО
	|			ПротоколРасчетовПротокол.Ссылка.Заказ) КАК ПротоколРасчетов
	|		ПО КатегорииЗаказа.Заказ = ПротоколРасчетов.Заказ";

	vQ.SetParameter("Заказ", pOrder);
	Return vQ.Execute().Unload();
EndFunction // pmReadOrderData

// -----------------------------------------------------------------------------
Procedure pmLoadOrders(pIsInteractive) Export
	// Check parameters
	If IsBlankString(ConnectionString) Then
		vMessage = NStr("en='Restaurant system connectionstring is not specified. Execution is canceled!';ru='Не задана строка соединения с базой Трактира. Обработка прервана!';de='Die Verbindungszeile mit der Traktir-Basis ist nicht angegeben! Die Bearbeitung wurde abgebrochen!'");
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;
		WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromTraktirFO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзТрактирФО';de='DataProcessor.LoadOrdersFromTraktirFO'"), EventLogLevel.Warning, ThisObject.Metadata(), DataProcessor, vMessage);
		Return;
	EndIf;	
	
	Try
		// Build connection string
		vConnectionString = TrimAll(ConnectionString);
		If Not IsBlankString(Password) Then
			If Right(vConnectionString, 1) <> ";" Then
				vConnectionString = vConnectionString + ";";
			EndIf;
			vConnectionString = vConnectionString + "Pwd=""" + TrimR(Password) + """;";
		EndIf;
		
		// Connect to database
		vConnector = New COMObject("V"+TrimAll(TraktirDBVersion)+".COMConnector");
		TraktirDB = vConnector.Connect(vConnectionString);
		
		If LoadFromPeriod = 1 Then
			LoadOrdersFromPeriod();
		Else
			LoadCashRegisterDay();
		EndIf;	
	Except
		vErrorDescription = ErrorDescription();
		
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		Raise vErrorDescription;
	EndTry;
	
	// Log that processing is finished
	WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromTraktirFO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзТрактирФО';de='DataProcessor.LoadOrdersFromTraktirFO'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of loading restaurant orders!';ru='Выполнение процедуры загрузки заказов ресторана закончено!';de='Das Laden von Restaurantbestellungen ist abgeschlossen!'"));
EndProcedure // pmLoadOrders

// -----------------------------------------------------------------------------
Function GetChargeService(pCashRegister, pServiceItemCategory, pHotel)
	// Returns charge service
	// Is based on Traktir's cash register description and service item categories
	// Mapping should be set in the "External systems object codes mappings to the object references in the program" information register
	vService = cmGetObjectRefByExternalSystemCode(pHotel, TrimAll(ExternalSystemCode), "Services", "" + pCashRegister + ?(pServiceItemCategory = "", "", "/" + pServiceItemCategory));
	If Not ValueIsFilled(vService) Then
		vService = Service;
	EndIf;
	Return vService;
EndFunction // GetChargeService

// -----------------------------------------------------------------------------
Function GetCashRegister(pCashRegisterDescription, pHotel)
	// Returns payment cash register
	// Is based on Traktir's cash register description
	// Mapping should be set in the "External systems object codes mappings to the object references in the program" information register
	Return cmGetObjectRefByExternalSystemCode(pHotel, TrimAll(ExternalSystemCode), "CashRegisters", pCashRegisterDescription);
EndFunction // GetCashRegister

// -----------------------------------------------------------------------------
Function GetPaymentMethod(pPaymentType, pCardType, pHotel)
	// Returns payment method
	// Mapping should be set in the "External systems object codes mappings to the object references in the program" information register
	vPM = cmGetObjectRefByExternalSystemCode(pHotel, TrimAll(ExternalSystemCode), "PaymentMethods", pPaymentType + ?(pCardType = "", "", "/" + pCardType));
	If vPM = Undefined Then
		Return cmGetObjectRefByExternalSystemCode(pHotel, TrimAll(ExternalSystemCode), "PaymentMethods", pPaymentType);
	EndIf;
	Return vPM;
EndFunction // GetPaymentMethod

// -----------------------------------------------------------------------------
Function GetCardType(pCardType, pHotel)
	// Returns credit card type
	// Mapping should be set in the "External systems object codes mappings to the object references in the program" information register
	If pCardType = "" Then
		Return Catalogs.CreditCardTypes.EmptyRef();
	Else
		Return cmGetObjectRefByExternalSystemCode(pHotel, TrimAll(ExternalSystemCode), "CreditCardTypes", pCardType);
	EndIf;
EndFunction // GetCardType

// -----------------------------------------------------------------------------
Function GetIndividualsContract(pPaymentType, pCardType, pHotel)
	// Returns contract
	vContract = Catalogs.Contracts.EmptyRef();
	// Mapping should be set in the "External systems object codes mappings to the object references in the program" information register
	vContract = cmGetObjectRefByExternalSystemCode(pHotel, TrimAll(ExternalSystemCode), "Contracts", pPaymentType + ?(pCardType = "", "", "/" + pCardType));
	If vContract = Undefined Then
		Return cmGetObjectRefByExternalSystemCode(pHotel, TrimAll(ExternalSystemCode), "Contracts", pPaymentType);
	EndIf;
	Return vContract;
EndFunction // GetIndividualsContract

// -----------------------------------------------------------------------------
Function GetFolio(pDateFrom, pDateTo, pContract,pPlaceOfSale = Undefined)
	FolioObj = Documents.Folio.CreateDocument();
	FolioObj.pmFillAttributesWithDefaultValues();
	FolioObj.Date = CurrentSessionDate();
	FolioObj.DateTimeFrom = pDateFrom;
	FolioObj.DateTimeTo = pDateTo;
	If BegOfDay(DateFrom) = BegOfDay(DateTo) Then
		FolioObj.Description = Format(DateFrom, "DF=dd.MM.yyyy") + NStr("en=' - Load from Traktir';ru=' - Загрузка из Трактира';de=' - Laden aus Traktir'")+?(ValueIsFilled(pPlaceOfSale),", "+pPlaceOfSale,"");
	Else
		FolioObj.Description = Format(DateFrom, "DF=dd.MM.yyyy") + " - " + Format(DateTo, "DF=dd.MM.yyyy") + NStr("en=' - Load from Traktir';ru=' - Загрузка из Трактира';de=' - Laden aus Traktir'")+?(ValueIsFilled(pPlaceOfSale),", "+pPlaceOfSale,"");
	EndIf;
	vContract = Catalogs.Contracts.EmptyRef();
	If ValueIsFilled(pContract) Then
		vContractUUID = New UUID(pContract);
		vContract = Catalogs.Contracts.GetRef(vContractUUID);
	EndIf;
	If ValueIsFilled(vContract) Then
		FolioObj.Customer = vContract.Owner;
		FolioObj.Contract = vContract;
	EndIf;
	FolioObj.Write();
	Return FolioObj.Ref;
EndFunction // GetFolio

Function GetVATRate(pTaxRate, pCompany)
	vQ = New Query("SELECT
	|	VATRates.Ref
	|FROM
	|	Catalog.VATRates AS VATRates
	|WHERE
	|	NOT VATRates.DeletionMark
	|	AND VATRates.TaxRate = &qTaxRate");
	vQ.SetParameter("qTaxRate",pTaxRate);
	vQRes = vQ.Execute().Select();
	If vQRes.Next() Then
		Return vQRes.Ref;
	EndIf;
	Return pCompany.VATRate;	
EndFunction

// -----------------------------------------------------------------------------
Procedure LoadOrdersFromPeriod()
	// Get list of closed orders
	vQ = TraktirDB.NewObject("Query");
	vQText = 
	"ВЫБРАТЬ
	|	ПРЕДСТАВЛЕНИЕ(ПротоколРасчетовПротокол.ВариантОплаты.Тип),
	|	ПротоколРасчетовПротокол.ВариантОплаты.Наименование КАК ВариантОплатыНаименование,
	|	ЕСТЬNULL(ПротоколРасчетовПротокол.ТипКарты, """") КАК ТипКартыНаименование,
	|	ПРЕДСТАВЛЕНИЕ(ПротоколРасчетовПротокол.Действие),
	|	ПротоколРасчетовПротокол.Ссылка.ККМ КАК ККМ,
	|	ПротоколРасчетовПротокол.Ссылка.ККМ.Код КАК ККМКод,
	|	ПротоколРасчетовПротокол.Ссылка.ККМ.Наименование КАК ККМНаименование,
	|	ПротоколРасчетовПротокол.Ссылка.МестоРеализации.Наименование КАК МестоРеализацииНаименование,
	|	ПротоколРасчетовПротокол.Ссылка.МестоРеализации.Код КАК МестоРеализацииКод,
	|	ПротоколРасчетовПротокол.Ссылка.Заказ.Номер КАК ЗаказНомер,";
	If SplitByVATRate Then
		vQText = vQText+"
		|	ПротоколРасчетовПротокол.Ссылка.Заказ.СтавкаНДС КАК СтавкаНДC,";
	EndIf;
	vQText = vQText+"
	|	ПротоколРасчетовПротокол.Ссылка.Дата КАК ПротоколДата,
	|	ПротоколРасчетовПротокол.Ссылка.Проведен,
	|	ПротоколРасчетовПротокол.Ссылка.Заказ КАК Заказ,
	|	ЕСТЬNULL(ПротоколРасчетовПротокол.СуммаФакт, 0) - ЕСТЬNULL(Возврат.Сумма, 0) КАК СуммаФакт
	|ИЗ
	|	Документ.ПротоколРасчетов.Протокол КАК ПротоколРасчетовПротокол
	|		ЛЕВОЕ СОЕДИНЕНИЕ Документ.Возврат КАК Возврат
	|		ПО ПротоколРасчетовПротокол.Ссылка.Заказ = Возврат.Заказ
	|ГДЕ
	|	ПротоколРасчетовПротокол.Ссылка.Дата >= &ДатаС
	|	И ПротоколРасчетовПротокол.Ссылка.Дата <= &ДатаПо
	|	И ПротоколРасчетовПротокол.Ссылка.Проведен
	|	И ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.НаНомер)
	|	И ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.НаФолио)
	|	И ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.Безнал)
	|	И ЕСТЬNULL(ПротоколРасчетовПротокол.СуммаФакт, 0) - ЕСТЬNULL(Возврат.Сумма, 0) > 0";

	// СуммаФакт - может быть = Undefined так что в запрос надо вставить ЕСТЬNULL = 0.
	// также в запрос надо отбирать только те значения протокола которые не относятся 
	// к виду оплаты На номер и На фолио, 
	// т.е. ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.НаНомер)
	// ИЛИ ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.НаФолио)
	vDateFrom = BegOfDay(DateFrom);
	vDateTo = EndOfDay(DateTo);
	vQ.Text = vQText;
	vQ.SetParameter("ДатаС", vDateFrom);
	vQ.SetParameter("ДатаПо", vDateTo);
	vTPayments = vQ.Execute().Unload();
	
	// Build working table with orderes to be loaded
	vTOrders = vTPayments.Copy();
	If SplitByVATRate Then
		vTOrders.GroupBy("ВариантОплатыНаименование, ТипКартыНаименование, Заказ, ЗаказНомер, ПротоколДата, ККМНаименование, СтавкаНДС", "СуммаФакт");
	Else
		vTOrders.GroupBy("ВариантОплатыНаименование, ТипКартыНаименование, Заказ, ЗаказНомер, ПротоколДата, ККМНаименование", "СуммаФакт");
	EndIf;
	vTOrders.Columns.Add("Contract");
	For Each vOrder In vTOrders Do
		If vOrder.СуммаФакт = 0 Then
			Continue;
		EndIf;
		vContract = GetIndividualsContract(TrimAll(vOrder.ВариантОплатыНаименование), TrimAll(vOrder.ТипКартыНаименование), Hotel);
		If ValueIsFilled(vContract) Then
			vOrder.Contract = String(vContract.UUID());
		Else
			vOrder.Contract = "";
		EndIf;
	EndDo;
	If SplitByVATRate Then
		vTOrders.GroupBy("Contract, Заказ, ЗаказНомер, ПротоколДата, ККМНаименование, СтавкаНДС", "СуммаФакт");
	Else
		vTOrders.GroupBy("Contract, Заказ, ЗаказНомер, ПротоколДата, ККМНаименование", "СуммаФакт");
	EndIf;
	vTOrders.Sort("Contract, ККМНаименование, ПротоколДата, ЗаказНомер");
	
	// Write folio orders and payments
	Folio = Undefined;
	vCurContract = Undefined;
	For Each vOrder In vTOrders Do
		If vOrder.СуммаФакт = 0 Then
			Continue;
		EndIf;
		
		// Skip this order if it is already loaded
		vExtCode = TrimAll(vOrder.ЗаказНомер);
		PayDoc = Documents.Payment.FindByAttribute("ExternalCode", vExtCode);
		If PayDoc <> Documents.Payment.EmptyRef() And PayDoc.Posted Then
			Continue;
		EndIf;
		
		// Always create new folio to see what was loaded this time only
		If vCurContract <> vOrder.Contract Then
			// Close folio
			If Folio <> Undefined Then
				FolioObj = Folio.GetObject();
				FolioObj.IsClosed = True;
				FolioObj.Write();
				
				If CreateSettlement Then
					//create Settlement by folio
					vDocObj = Documents.Settlement.CreateDocument();
					vDocObj.pmFillAttributesWithDefaultValues();
					vDocObj.pmFillByFolio(FolioObj.Ref);
					vDocObj.Remarks = NStr("en='Load from Traktir';ru='Загрузка из Трактира';de='Ladevorgang aus dem Traktir'");
					vDocObj.DoNotExportToTheAccountingSystem = SetDoNotExportToTheAccountingSystem;
					vDocObj.Write();
					vDocObj.Write(DocumentWriteMode.Posting,);
				EndIf;
				
			EndIf;
			vCurContract = vOrder.Contract;
			Folio = GetFolio(vDateFrom, vDateTo, vOrder.Contract);
		EndIf;
		
		// Get orders grouped by service item categories
		vTOrderCategories = pmReadOrderData(vOrder.Заказ, TraktirDB);
		
		BeginTransaction(DataLockControlMode.Managed);
		
		// Do charges
		vPaymentAmount = Undefined;
		For Each vOrderCategory In vTOrderCategories Do
			// Save total amount to be paid
			If vPaymentAmount = Undefined Then
				vPaymentAmount = vOrderCategory.СуммаОплаты;
			EndIf;
			If vPaymentAmount <= 0 Then
				Break;
			EndIf;
			vChargeAmount = vOrderCategory.Сумма;
			If vChargeAmount = 0 Then
				Continue;
			ElsIf vChargeAmount > 0 Then
				vChargeAmount = Min(vPaymentAmount, vChargeAmount);
			EndIf;
			vPaymentAmount = vPaymentAmount - vChargeAmount;
			
			vCharge = Documents.Charge.CreateDocument();
			vCharge.Date = vOrder.ПротоколДата; 
			vCharge.Author = SessionParameters.CurrentUser;
			vCharge.pmFillByFolio(Folio);
			If Year(vCharge.Date) <> Year(CurrentSessionDate()) Then
				vCharge.SetNewNumber();
			EndIf;
			vCharge.IsAdditional = True;
			vCharge.Price = vChargeAmount;
			vCharge.Quantity = 1;
			vCharge.Remarks = NStr("en='Order N ';ru='Заказ № ';de='Bestellung Nr.'") + vOrder.ЗаказНомер;
			vCharge.ExchangeRateDate = BegOfDay(vOrder.ПротоколДата); 
			vCharge.ReportingCurrency = vCharge.Hotel.ReportingCurrency;
			vCharge.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vCharge.Hotel, vCharge.ReportingCurrency, vCharge.ExchangeRateDate);
			vCharge.Service = GetChargeService(TrimAll(vOrder.ККМНаименование), TrimAll(vOrderCategory.КатегорияТовараНаименование), vCharge.Hotel);
			vCharge.Sum = vChargeAmount;
			vCharge.Unit = vCharge.Service.Unit;
			If SplitByVATRate Then
				vCharge.VATRate = GetVATRate(vOrder.СтавкаНДС,vCharge.Company);
			Else
				vCharge.VATRate = vCharge.Company.VATRate;
			EndIf;
			vCharge.VATSum = cmCalculateVATSum(vCharge.VATRate, vCharge.Sum, vCharge.Date);
			vCharge.Write(DocumentWriteMode.Posting);
		EndDo;
		
		// Do payments
		For Each vPayment In vTPayments Do
			If vPayment.Заказ <> vOrder.Заказ Then
				Continue;
			EndIf;
			vPay = Documents.Payment.CreateDocument();
			vPay.Date = vOrder.ПротоколДата;
			vPay.Author = SessionParameters.CurrentUser;
			vPay.Hotel = Folio.Hotel;
			If Year(vPay.Date) <> Year(CurrentSessionDate()) Then
				vPay.SetNewNumber();
			EndIf;
			vPay.AuthorizationCode = "0";
			vPay.ReferenceNumber = "0";
			vPay.Folio = Folio;
			vPay.CashRegister = GetCashRegister(TrimAll(vOrder.ККМНаименование), vPay.Hotel);
			vPay.Company = Folio.Company;
			If ValueIsFilled(Folio.Customer) Then
				vPay.AccountingCustomer = Folio.Customer;
				vPay.AccountingContract = Folio.Contract;
			Else
				vPay.AccountingCustomer = Hotel.IndividualsCustomer;
				vPay.AccountingContract = Hotel.IndividualsContract;
			EndIf;
			vPay.ExchangeRateDate = BegOfDay(vOrder.ПротоколДата);
			vPay.FolioCurrency = Folio.FolioCurrency;
			vPay.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vPay.Hotel, vPay.FolioCurrency, vPay.ExchangeRateDate);
			vPay.PaymentCurrency = vPay.FolioCurrency;
			vPay.PaymentCurrencyExchangeRate = vPay.FolioCurrencyExchangeRate;
			vPay.PaymentMethod = GetPaymentMethod(TrimAll(vPayment.ВариантОплатыНаименование), TrimAll(vPayment.ТипКартыНаименование), vPay.Hotel);
			If Not ValueIsFilled(vPay.PaymentMethod) Then
				vMessage = NStr("en='Failed to set payment method for the order N " + TrimAll(vOrder.ЗаказНомер) + "! Payment type is: " + TrimAll(vPayment.ВариантОплатыНаименование) + "; Card type is: " +  TrimAll(vPayment.ТипКартыНаименование) + "'; 
				                |de='Failed to set payment method for the order N " + TrimAll(vOrder.ЗаказНомер) + "! Payment type is: " + TrimAll(vPayment.ВариантОплатыНаименование) + "; Card type is: " +  TrimAll(vPayment.ТипКартыНаименование) + "'; 
				                |ru='У платежа по заказу " + TrimAll(vOrder.ЗаказНомер) + " не удалось установить способ оплаты! Вариант оплаты: " + TrimAll(vPayment.ВариантОплатыНаименование) + "; тип карты: " +  TrimAll(vPayment.ТипКартыНаименование) + "'");
				WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromTraktirFO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзТрактирФО';de='DataProcessor.LoadOrdersFromTraktirFO'"), EventLogLevel.Warning, ThisObject.Metadata(), DataProcessor, vMessage);
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
			vPay.CardType = GetCardType(TrimAll(vPayment.ТипКартыНаименование), vPay.Hotel);
			vPay.Remarks = NStr("en='Order N ';ru='Заказ № ';de='Bestellung Nr.'") + vOrder.ЗаказНомер;
			vPay.ExternalCode = vExtCode; 
			vPay.Sum = vPayment.СуммаФакт;
			vPay.SumInFolioCurrency = vPay.Sum;
			If SplitByVATRate Then
				vPay.VATRate = GetVATRate(vOrder.СтавкаНДС,vPay.Company);
			Else
				vPay.VATRate = vPay.Company.VATRate;
			EndIf;
			vPay.VATSum = cmCalculateVATSum(vPay.VATRate, vPay.Sum);
			vPay.VATSumInFolioCurrency = cmCalculateVATSum(vPay.VATRate, vPay.SumInFolioCurrency, vPay.Date);
			vPay.Write(DocumentWriteMode.Posting);
			
			FolioObj = Folio.GetObject();
			FolioObj.PaymentMethod = ?(ValueIsFilled(vPay.PaymentMethod),vPay.PaymentMethod,FolioObj.PaymentMethod);
			FolioObj.Write();
		EndDo; 
		
		CommitTransaction();
		
		#IF CLIENT THEN		
			Status(NStr("en='Loaded ';ru='Загружено ';de='Geladen '") + Format(vTOrders.IndexOf(vOrder) + 1, "ND=10; NFD=0; NZ=; NG=") + NStr("en=' orders from ';ru=' заказов из ';de=' Bestellungen aus '") + Format(vTOrders.Count(), "ND=10; NFD=0; NZ=; NG=") + "...");
			UserInterruptProcessing();
		#ENDIF
	EndDo; // By orders
	
	// Close folio
	If Folio <> Undefined Then
		FolioObj = Folio.GetObject();
		FolioObj.IsClosed = True;
		FolioObj.Write();
		
		If CreateSettlement Then
			//create Settlement by folio
			vDocObj = Documents.Settlement.CreateDocument();
			vDocObj.pmFillAttributesWithDefaultValues();
			vDocObj.pmFillByFolio(FolioObj.Ref);
			vDocObj.Remarks = NStr("en='Load from Traktir';ru='Загрузка из Трактира';de='Ladevorgang aus dem Traktir'");
			vDocObj.DoNotExportToTheAccountingSystem = SetDoNotExportToTheAccountingSystem;
			vDocObj.Write();
			vDocObj.Write(DocumentWriteMode.Posting,);
		EndIf;
	EndIf;
	
	// Close or repost cash register days
	vTCashRegisters = vTPayments.Copy();
	vTCashRegisters.GroupBy("ККМНаименование", );
	For Each vCashRegister In vTCashRegisters Do
		If IsBlankString(vCashRegister.ККМНаименование) Then
			vMessage = NStr("en='Payment protocols without cash register was found!';ru='В трактире есть протоколы оплаты без ККМ!';de='Im Traktir gibt es Zahlungsprotokolle ohne Registrierkasse!'");
			WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromTraktirFO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзТрактирФО';de='DataProcessor.LoadOrdersFromTraktirFO'"), EventLogLevel.Warning, ThisObject.Metadata(), DataProcessor, vMessage);
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Continue;
		EndIf;
		vCashRegisterRef = GetCashRegister(TrimAll(vCashRegister.ККМНаименование), Hotel);
		If Not ValueIsFilled(vCashRegisterRef) Then
			vMessage = NStr("en='Cash register not found: ';ru='Не найден ККМ ';de='Registrierkasse nicht gefunden '") + TrimAll(vCashRegister.ККМНаименование);
			WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromTraktirFO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзТрактирФО';de='DataProcessor.LoadOrdersFromTraktirFO'"), EventLogLevel.Warning, ThisObject.Metadata(), DataProcessor, vMessage);
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Continue;
		EndIf;
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
				vCloseOfCCD = vQryRes.Get(0).Ref.GetObject();
				vCloseOfCCD.Write(DocumentWriteMode.Posting);
				
				vCurDate = vCurDate + 24*3600;
				
				Continue;
			EndIf;
			// Write new close of cash register day document
			vCloseOfCCD = Documents.CloseOfCashRegisterDay.CreateDocument();
			vCloseOfCCD.Company = Hotel.Company;
			vCloseOfCCD.pmFillAttributesWithDefaultValues();
			vCloseOfCCD.Date = EndOfDay(vCurDate);
			If Year(vCloseOfCCD.Date) <> Year(CurrentSessionDate()) Then
				vCloseOfCCD.SetNewNumber();
			EndIf;
			vCloseOfCCD.CashRegister = vCashRegisterRef;
			If ValueIsFilled(vCloseOfCCD.CashRegister) Then
				vCloseOfCCD.ZReportType = vCloseOfCCD.CashRegister.ZReportType;
			EndIf;
			vDateFrom = vCloseOfCCD.pmCalculateDateFrom(vCloseOfCCD.Date);
			If Not ValueIsFilled(vDateFrom) Then
				vCloseOfCCD.DateFrom = '20000101';
			Else
				vCloseOfCCD.DateFrom = vDateFrom;
			EndIf;
			If BegOfDay(DateFrom) = BegOfDay(DateTo) Then
				vCloseOfCCD.Remarks = Format(DateFrom, "DF=dd.MM.yyyy") + NStr("en=' - Load orders from Traktir FO'; ru=' - Загрузка заказов из Трактира ФО'; de=' - Load orders from Traktir FO'");
			Else
				vCloseOfCCD.Remarks = Format(DateFrom, "DF=dd.MM.yyyy") + " - " + Format(DateTo, "DF=dd.MM.yyyy") + NStr("en=' - Load orders from Traktir FO'; ru=' - Загрузка заказов из Трактира ФО'; de=' - Load orders from Traktir FO'");
			EndIf;
			vCloseOfCCD.Write(DocumentWriteMode.Posting);
			
			vMessage = Format(vCurDate, "DF=dd.MM.yyyy") + NStr("en=' - Cash register day is closed for ';ru=' - Закрыта смена по ККМ ';de=' - Schichtnach der Registrierkasse geschlossen '") + TrimAll(vCashRegister.ККМНаименование) + "...";
			WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromTraktirFO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзТрактирФО';de='DataProcessor.LoadOrdersFromTraktirFO'"), EventLogLevel.Information, ThisObject.Metadata(), DataProcessor, vMessage);
			#IF CLIENT THEN
				Status(vMessage);
				UserInterruptProcessing();
			#ENDIF
			
			vCurDate = vCurDate + 24*3600;
		EndDo;
	EndDo; // By cash registers
EndProcedure // LoadOrdersFromPeriod

// -----------------------------------------------------------------------------
Procedure LoadCashRegisterDay()
	vDateFrom = BegOfDay(DateFrom);
	vDateTo = EndOfDay(DateTo);
	vQr = TraktirDB.NewObject("Query");
	vQr.SetParameter("ДатаС", vDateFrom);
	vQr.SetParameter("ДатаПо", vDateTo);
	vQr.Text =
	"ВЫБРАТЬ
	|	ЗакрытиеСмены.Номер,
	|	ЗакрытиеСмены.Ссылка КАК Ссылка,
	|	ЗакрытиеСмены.Дата КАК ДатаЗакрытия,
	|	ЗакрытиеСмены.Смена.Дата КАК ДатаОткрытия,
	|	ЗакрытиеСмены.МестоРеализации.Наименование КАК МестоРеализации
	|ИЗ
	|	Документ.ЗакрытиеСмены КАК ЗакрытиеСмены
	|ГДЕ
	|	НЕ ЗакрытиеСмены.ПометкаУдаления И 
	|	ЗакрытиеСмены.Дата МЕЖДУ &ДатаС И &ДатаПО";
	vCashChange = vQr.Execute().Unload();
	
	For Each vChange In vCashChange Do
		
		// Get list of closed orders
		vQ = TraktirDB.NewObject("Query");
		vQText =
		"ВЫБРАТЬ
		|	Протоколы.ВариантОплатыТипПредставление,
		|	Протоколы.ВариантОплатыНаименование,
		|	Протоколы.ТипКартыНаименование,
		|	Протоколы.ДействиеПредставление,
		|	Протоколы.ККМ,
		|	Протоколы.ККМКод,
		|	Протоколы.ККМНаименование КАК ККМНаименование,
		|	Протоколы.МестоРеализацииНаименование,
		|	Протоколы.МестоРеализацииКод,
		|	Протоколы.ЗаказНомер,
		|	Протоколы.ПротоколДата,
		|	Протоколы.Проведен,
		|	Протоколы.Заказ,
		|	Протоколы.СуммаФакт КАК СуммаФакт";
		If SplitByVATRate Then
			vQText=vQText+",
			|	Протоколы.Заказ.СтавкаНДС КАК СтавкаНДС";
		EndIf;
		vQText=vQText+"
		|ИЗ
		|	(ВЫБРАТЬ
		|		ПРЕДСТАВЛЕНИЕ(ПротоколРасчетовПротокол.ВариантОплаты.Тип) КАК ВариантОплатыТипПредставление,
		|		ПротоколРасчетовПротокол.ВариантОплаты.Наименование КАК ВариантОплатыНаименование,
		|		ЕСТЬNULL(ПротоколРасчетовПротокол.ТипКарты, """") КАК ТипКартыНаименование,
		|		ПРЕДСТАВЛЕНИЕ(ПротоколРасчетовПротокол.Действие) КАК ДействиеПредставление,
		|		ПротоколРасчетовПротокол.Ссылка.ККМ КАК ККМ,
		|		ПротоколРасчетовПротокол.Ссылка.ККМ.Код КАК ККМКод,
		|		ПротоколРасчетовПротокол.Ссылка.ККМ.Наименование КАК ККМНаименование,
		|		ПротоколРасчетовПротокол.Ссылка.МестоРеализации.Наименование КАК МестоРеализацииНаименование,
		|		ПротоколРасчетовПротокол.Ссылка.МестоРеализации.Код КАК МестоРеализацииКод,
		|		ПротоколРасчетовПротокол.Ссылка.Заказ.Номер КАК ЗаказНомер,
		|		ПротоколРасчетовПротокол.Ссылка.Дата КАК ПротоколДата,
		|		ПротоколРасчетовПротокол.Ссылка.Проведен КАК Проведен,
		|		ПротоколРасчетовПротокол.Ссылка.Заказ КАК Заказ,
		|		ЕСТЬNULL(ПротоколРасчетовПротокол.СуммаФакт, 0) - ЕСТЬNULL(Возврат.Сумма, 0) КАК СуммаФакт
		|	ИЗ
		|		Документ.ПротоколРасчетов.Протокол КАК ПротоколРасчетовПротокол
		|			ЛЕВОЕ СОЕДИНЕНИЕ Документ.Возврат КАК Возврат
		|			ПО ПротоколРасчетовПротокол.Ссылка.Заказ = Возврат.Заказ
		|	ГДЕ
		|		ПротоколРасчетовПротокол.Ссылка.Проведен
		|		И ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.НаНомер)
		|		И ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.НаФолио)
		|		И ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.Безнал)
		|		И ЕСТЬNULL(ПротоколРасчетовПротокол.СуммаФакт, 0) - ЕСТЬNULL(Возврат.Сумма, 0) > 0) КАК Протоколы
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Документ.ЗакрытиеСмены КАК ЗакрытиеСмены
		|		ПО Протоколы.ПротоколДата >= ЗакрытиеСмены.Смена.Дата
		|			И Протоколы.ПротоколДата <= ЗакрытиеСмены.Дата
		|			И Протоколы.Заказ.МестоРеализации = ЗакрытиеСмены.МестоРеализации
		|ГДЕ
		|	ЗакрытиеСмены.Номер = &Номер";
		vQ.Text = vQText;
		// СуммаФакт - может быть = Undefined так что в запрос надо вставить ЕСТЬNULL = 0.
		// также в запрос надо отбирать только те значения протокола которые не относятся 
		// к виду оплаты На номер и На фолио, 
		// т.е. ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.НаНомер)
		// ИЛИ ПротоколРасчетовПротокол.ВариантОплаты.Тип <> ЗНАЧЕНИЕ(Перечисление.ТипыОплаты.НаФолио)
		vQ.SetParameter("Номер", vChange.Номер);
		vTPayments = vQ.Execute().Unload();
		
		// Build working table with orderes to be loaded
		vTOrders = vTPayments.Copy();
		If SplitByVATRate Then
			vTOrders.GroupBy("ВариантОплатыНаименование, ТипКартыНаименование, Заказ, ЗаказНомер, ПротоколДата, ККМНаименование, СтавкаНДС", "СуммаФакт");
		Else
			vTOrders.GroupBy("ВариантОплатыНаименование, ТипКартыНаименование, Заказ, ЗаказНомер, ПротоколДата, ККМНаименование", "СуммаФакт");
		EndIf;
		vTOrders.Columns.Add("Contract");
		For Each vOrder In vTOrders Do
			If vOrder.СуммаФакт = 0 Then
				Continue;
			EndIf;
			vContract = GetIndividualsContract(TrimAll(vOrder.ВариантОплатыНаименование), TrimAll(vOrder.ТипКартыНаименование), Hotel);
			If ValueIsFilled(vContract) Then
				vOrder.Contract = String(vContract.UUID());
			Else
				vOrder.Contract = "";
			EndIf;
		EndDo;
		If SplitByVATRate Then
			vTOrders.GroupBy("Contract, Заказ, ЗаказНомер, ПротоколДата, ККМНаименование, СтавкаНДС", "СуммаФакт");
		Else
			vTOrders.GroupBy("Contract, Заказ, ЗаказНомер, ПротоколДата, ККМНаименование", "СуммаФакт");
		EndIf;
		vTOrders.Sort("Contract, ККМНаименование, ПротоколДата, ЗаказНомер");
		
		// Write folio orders and payments
		Folio = Undefined;
		vCurContract = Undefined;
		For Each vOrder In vTOrders Do
			If vOrder.СуммаФакт = 0 Then
				Continue;
			EndIf;
			
			// Skip this order if it is already loaded
			vExtCode = TrimAll(vOrder.ЗаказНомер);
			PayDoc = Documents.Payment.FindByAttribute("ExternalCode", vExtCode);
			If PayDoc <> Documents.Payment.EmptyRef() And PayDoc.Posted Then
				Continue;
			EndIf;
			
			// Always create new folio to see what was loaded this time only
			If vCurContract <> vOrder.Contract Then
				// Close folio
				If Folio <> Undefined Then
					FolioObj = Folio.GetObject();
					FolioObj.IsClosed = True;
					FolioObj.Write();
					
					If CreateSettlement Then
						//create Settlement by folio
						vDocObj = Documents.Settlement.CreateDocument();
						vDocObj.pmFillAttributesWithDefaultValues();
						vDocObj.pmFillByFolio(FolioObj.Ref);
						vDocObj.Remarks = NStr("en='Load from Traktir';ru='Загрузка из Трактира';de='Ladevorgang aus dem Traktir'");
						vDocObj.DoNotExportToTheAccountingSystem = SetDoNotExportToTheAccountingSystem;
						vDocObj.Write();
						vDocObj.Write(DocumentWriteMode.Posting,);
					EndIf;
				EndIf;
				vCurContract = vOrder.Contract;
				Folio = GetFolio(vChange.ДатаОткрытия, vChange.ДатаЗакрытия, vOrder.Contract,vChange.МестоРеализации);
			EndIf;
			
			// Get orders grouped by service item categories
			vTOrderCategories = pmReadOrderData(vOrder.Заказ, TraktirDB);
			
			BeginTransaction(DataLockControlMode.Managed);
			
			// Do charges
			vPaymentAmount = Undefined;
			For Each vOrderCategory In vTOrderCategories Do
				// Save total amount to be paid
				If vPaymentAmount = Undefined Then
					vPaymentAmount = vOrderCategory.СуммаОплаты;
				EndIf;
				If vPaymentAmount <= 0 Then
					Break;
				EndIf;
				vChargeAmount = vOrderCategory.Сумма;
				If vChargeAmount = 0 Then
					Continue;
				ElsIf vChargeAmount > 0 Then
					vChargeAmount = Min(vPaymentAmount, vChargeAmount);
				EndIf;
				vPaymentAmount = vPaymentAmount - vChargeAmount;
				
				vCharge = Documents.Charge.CreateDocument();
				vCharge.Date = vChange.ДатаОткрытия; 
				vCharge.Author = SessionParameters.CurrentUser;
				vCharge.pmFillByFolio(Folio);
				If Year(vCharge.Date) <> Year(CurrentSessionDate()) Then
					vCharge.SetNewNumber();
				EndIf;
				vCharge.IsAdditional = True;
				vCharge.Price = vChargeAmount;
				vCharge.Quantity = 1;
				vCharge.Remarks = NStr("en='Order N ';ru='Заказ № ';de='Bestellung Nr. '") + vOrder.ЗаказНомер;
				vCharge.ExchangeRateDate = BegOfDay(vOrder.ПротоколДата); 
				vCharge.ReportingCurrency = vCharge.Hotel.ReportingCurrency;
				vCharge.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vCharge.Hotel, vCharge.ReportingCurrency, vCharge.ExchangeRateDate);
				vCharge.Service = GetChargeService(TrimAll(vOrder.ККМНаименование), TrimAll(vOrderCategory.КатегорияТовараНаименование), vCharge.Hotel);
				vCharge.Sum = vChargeAmount;
				vCharge.Unit = vCharge.Service.Unit;
				If SplitByVATRate Then
					vCharge.VATRate = GetVATRate(vOrder.СтавкаНДС,vCharge.Company);
				Else
					vCharge.VATRate = vCharge.Company.VATRate;
				EndIf;
				vCharge.VATSum = cmCalculateVATSum(vCharge.VATRate, vCharge.Sum, vCharge.Date);
				vCharge.Write(DocumentWriteMode.Posting);
			EndDo;
			
			// Do payments
			For Each vPayment In vTPayments Do
				If vPayment.Заказ <> vOrder.Заказ Then
					Continue;
				EndIf;
				vPay = Documents.Payment.CreateDocument();
				vPay.Date = vChange.ДатаОткрытия;
				vPay.Author = SessionParameters.CurrentUser;
				vPay.Hotel = Folio.Hotel;
				If Year(vPay.Date) <> Year(CurrentSessionDate()) Then
					vPay.SetNewNumber();
				EndIf;
				vPay.AuthorizationCode = "0";
				vPay.ReferenceNumber = "0";
				vPay.Folio = Folio;
				vPay.CashRegister = GetCashRegister(TrimAll(vOrder.ККМНаименование), vPay.Hotel);
				vPay.Company = Folio.Company;
				If ValueIsFilled(Folio.Customer) Then
					vPay.AccountingCustomer = Folio.Customer;
					vPay.AccountingContract = Folio.Contract;
				Else
					vPay.AccountingCustomer = Hotel.IndividualsCustomer;
					vPay.AccountingContract = Hotel.IndividualsContract;
				EndIf;
				vPay.ExchangeRateDate = BegOfDay(vOrder.ПротоколДата);
				vPay.FolioCurrency = Folio.FolioCurrency;
				vPay.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vPay.Hotel, vPay.FolioCurrency, vPay.ExchangeRateDate);
				vPay.PaymentCurrency = vPay.FolioCurrency;
				vPay.PaymentCurrencyExchangeRate = vPay.FolioCurrencyExchangeRate;
				vPay.PaymentMethod = GetPaymentMethod(TrimAll(vPayment.ВариантОплатыНаименование), TrimAll(vPayment.ТипКартыНаименование), vPay.Hotel);
				If Not ValueIsFilled(vPay.PaymentMethod) Then
					vMessage = NStr("en='Failed to set payment method for the order N " + TrimAll(vOrder.ЗаказНомер) + "! Payment type is: " + TrimAll(vPayment.ВариантОплатыНаименование) + "; Card type is: " +  TrimAll(vPayment.ТипКартыНаименование) + "';
					                |de='Failed to set payment method for the order N " + TrimAll(vOrder.ЗаказНомер) + "! Payment type is: " + TrimAll(vPayment.ВариантОплатыНаименование) + "; Card type is: " +  TrimAll(vPayment.ТипКартыНаименование) + "';
					                |ru='У платежа по заказу " + TrimAll(vOrder.ЗаказНомер) + " не удалось установить способ оплаты! Вариант оплаты: " + TrimAll(vPayment.ВариантОплатыНаименование) + "; тип карты: " +  TrimAll(vPayment.ТипКартыНаименование) + "'");
					WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromTraktirFO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзТрактирФО';de='DataProcessor.LoadOrdersFromTraktirFO'"), EventLogLevel.Warning, ThisObject.Metadata(), DataProcessor, vMessage);
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				EndIf;
				vPay.CardType = GetCardType(TrimAll(vPayment.ТипКартыНаименование), vPay.Hotel);
				vPay.Remarks = NStr("en='Order N ';ru='Заказ № ';de='Bestellung Nr. '") + vOrder.ЗаказНомер;
				vPay.ExternalCode = vExtCode; 
				vPay.Sum = vPayment.СуммаФакт;
				vPay.SumInFolioCurrency = vPay.Sum;
				If SplitByVATRate Then
					vPay.VATRate = GetVATRate(vOrder.СтавкаНДС,vPay.Company);
				Else
					vPay.VATRate = vPay.Company.VATRate;
				EndIf;
				vPay.VATSum = cmCalculateVATSum(vPay.VATRate, vPay.Sum, vPay.Date);
				vPay.VATSumInFolioCurrency = cmCalculateVATSum(vPay.VATRate, vPay.SumInFolioCurrency, vPay.Date);
				vPay.Write(DocumentWriteMode.Posting);
				
				FolioObj = Folio.GetObject();
				FolioObj.PaymentMethod = ?(ValueIsFilled(vPay.PaymentMethod),vPay.PaymentMethod,FolioObj.PaymentMethod);
				FolioObj.Write();
			EndDo; 
			
			CommitTransaction();
			
			#IF CLIENT THEN		
				Status(NStr("en='Loaded ';ru='Загружено ';de='Geladen '") + Format(vTOrders.IndexOf(vOrder) + 1, "ND=10; NFD=0; NZ=; NG=") + NStr("en=' orders from ';ru=' заказов из ';de=' Bestellungen aus '") + Format(vTOrders.Count(), "ND=10; NFD=0; NZ=; NG=") + "...");
				UserInterruptProcessing();
			#ENDIF
		EndDo; // By orders         
		
		// Close folio
		If Folio <> Undefined Then
			FolioObj = Folio.GetObject();
			FolioObj.IsClosed = True;
			FolioObj.Write();
			
			If CreateSettlement Then
				//create Settlement by folio
				vDocObj = Documents.Settlement.CreateDocument();
				vDocObj.pmFillAttributesWithDefaultValues();
				vDocObj.pmFillByFolio(FolioObj.Ref);
				vDocObj.Remarks = NStr("en='Load from Traktir';ru='Загрузка из Трактира';de='Ladevorgang aus dem Traktir'");
				vDocObj.DoNotExportToTheAccountingSystem = SetDoNotExportToTheAccountingSystem;
				vDocObj.Write();
				vDocObj.Write(DocumentWriteMode.Posting,);
			EndIf;
		EndIf;
		
		// Close or repost cash register days
		vTCashRegisters = vTPayments.Copy();
		vTCashRegisters.GroupBy("ККМНаименование", );
		For Each vCashRegister In vTCashRegisters Do
			If IsBlankString(vCashRegister.ККМНаименование) Then
				vMessage = NStr("en='Payment protocols without cash register was found!';ru='В трактире есть протоколы оплаты без ККМ!';de='Im Traktir gibt es Zahlungsprotokolle ohne Registrierkasse!'");
				WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromTraktirFO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзТрактирФО';de='DataProcessor.LoadOrdersFromTraktirFO'"), EventLogLevel.Warning, ThisObject.Metadata(), DataProcessor, vMessage);
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Continue;
			EndIf;
			vCashRegisterRef = GetCashRegister(TrimAll(vCashRegister.ККМНаименование), Hotel);
			If Not ValueIsFilled(vCashRegisterRef) Then
				vMessage = NStr("en='Cash register not found ';ru='Не найден ККМ ';de='Registrierkasse nicht gefunden '") + TrimAll(vCashRegister.ККМНаименование);
				WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromTraktirFO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзТрактирФО';de='DataProcessor.LoadOrdersFromTraktirFO'"), EventLogLevel.Warning, ThisObject.Metadata(), DataProcessor, vMessage);
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Continue;
			EndIf;
			
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
			|	AND CloseOfCashRegisterDay.Date = &qDate
			|	AND CloseOfCashRegisterDay.ExternalCode = &qExternalCode";
			vQry.SetParameter("qCashRegister", vCashRegisterRef);
			vQry.SetParameter("qDate", vChange.ДатаЗакрытия);
			vExtCode=TraktirDB.String(vChange.Ссылка.УникальныйИдентификатор());
			vQry.SetParameter("qExternalCode",vExtCode);
			vQryRes = vQry.Execute().Unload();
			
			If vQryRes.Count() > 0 Then
				vCloseOfCCD = vQryRes.Get(0).Ref.GetObject();
				vCloseOfCCD.Write(DocumentWriteMode.Posting);
				Continue;
			EndIf;
			
			// Write new close of cash register day document
			vCloseOfCCD = Documents.CloseOfCashRegisterDay.CreateDocument();
			vCloseOfCCD.Company = Hotel.Company;
			vCloseOfCCD.pmFillAttributesWithDefaultValues();
			vCloseOfCCD.Date = vChange.ДатаЗакрытия;
			vCloseOfCCD.ExternalCode = vExtCode;
			
			If Year(vCloseOfCCD.Date) <> Year(CurrentSessionDate()) Then
				vCloseOfCCD.SetNewNumber();
			EndIf;
			
			vCloseOfCCD.CashRegister = vCashRegisterRef;
			
			If ValueIsFilled(vCloseOfCCD.CashRegister) Then
				vCloseOfCCD.ZReportType = vCloseOfCCD.CashRegister.ZReportType;
			EndIf;
			
			vCloseOfCCD.DateFrom = vChange.ДатаОткрытия;
			vCloseOfCCD.Remarks = Format(vChange.ДатаОткрытия, "DF=dd.MM.yyyy") + " - " + Format(vChange.ДатаЗакрытия, "DF=dd.MM.yyyy") + NStr("en=' - Load orders from Traktir FO'; ru=' - Загрузка заказов из Трактира ФО'; de=' - Load orders from Traktir FO'") + ", " + vChange.МестоРеализации;
			vCloseOfCCD.Write(DocumentWriteMode.Posting);
			
			vMessage = Format(vChange.ДатаЗакрытия, "DF=dd.MM.yyyy") + NStr("en=' - Cash register day is closed for ';ru=' - Закрыта смена по ККМ ';de=' - Schichtnach der Registrierkasse geschlossen '") + TrimAll(vCashRegister.ККМНаименование) + "...";
			WriteLogEvent(NStr("en='DataProcessor.LoadOrdersFromTraktirFO';ru='Обработка.ЗагрузкаЗаказовРесторанаИзТрактирФО';de='DataProcessor.LoadOrdersFromTraktirFO'"), EventLogLevel.Information, ThisObject.Metadata(), DataProcessor, vMessage);
			
			#IF CLIENT THEN
				Status(vMessage);
				UserInterruptProcessing();
			#ENDIF
		EndDo; // By cash registers
	EndDo;
EndProcedure // LoadCashRegisterDay
