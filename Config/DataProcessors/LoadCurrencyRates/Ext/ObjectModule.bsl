
#Region Variables

Var FileName;

#EndRegion

#Region Public


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
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(CurrencyRatesSource) Then
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.Citizenship) Then
				If TrimAll(Hotel.Citizenship.ISOCode) = "RU" Then
					CurrencyRatesSource = Enums.CurrencyRatesSources.RU1C;
				ElsIf TrimAll(Hotel.Citizenship.ISOCode) = "KG" Then
					CurrencyRatesSource = Enums.CurrencyRatesSources.Kato;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate() + 24*3600); // For tomorrow
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Fill currencies list
	pmFillCurrenciesList();
	// Load rates
	pmLoadCurrencyRates(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure pmFillCurrenciesList() Export
	Currencies.Clear();
	vAllCurrencies = cmGetAllCurrencies();
	For Each vAllCurrenciesRow In vAllCurrencies Do
		// Skip base currency
		If ValueIsFilled(Hotel) Then
			If vAllCurrenciesRow.Currency = Hotel.BaseCurrency Then
				Continue;
			EndIf;
		EndIf;
		// Add row
		vRow = Currencies.Add();
		vRow.Currency = vAllCurrenciesRow.Currency;
	EndDo;
EndProcedure // pmFillCurrenciesList
	
// -----------------------------------------------------------------------------
Procedure pmLoadCurrencyRates(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	If CurrencyRatesSource = Enums.CurrencyRatesSources.RU1C Then
		pmLoadCurrencyRatesFrom1C(pIsInteractive);
	ElsIf CurrencyRatesSource = Enums.CurrencyRatesSources.RBC Then
		pmLoadCurrencyRatesFromRBC(pIsInteractive);
	ElsIf CurrencyRatesSource = Enums.CurrencyRatesSources.Kato Then
		pmLoadCurrencyRatesFrom1CKato(pIsInteractive);
	ElsIf CurrencyRatesSource = Enums.CurrencyRatesSources.BNM Then
		pmLoadCurrencyRatesFromBNM(pIsInteractive);
	EndIf;
	WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmLoadCurrencyRates	

// -----------------------------------------------------------------------------
Procedure pmLoadCurrencyRatesFrom1C(pIsInteractive) Export
	Var vHTTP;
	
	vCurrencyRatesMgr = InformationRegisters.CurrencyRates.CreateRecordManager();

	vText = New TextDocument();

	vSourceCite = "currencyrates.1c.ru/exchangerate/v1/";

	vAddress = "";
	vPeriod = "";
	If BegOfDay(PeriodFrom) = BegOfDay(PeriodTo) Then
		vAddress = "tsv/";
		vPeriod = "/" + Format(Year(PeriodTo),"NGS=; NG=0") + 
		          "/" + Format(Month(PeriodTo), "ND=2; NFD=0; NLZ=") + 
		          "/" + Format(Day(PeriodTo), "ND=2; NFD=0; NLZ=");
	Else
		vAddress = "tsv/cb/";
		vPeriod = "";
	EndIf;

	vTmpDir = TempFilesDir() + "LoadRates";
	CreateDirectory(vTmpDir);
	DeleteFiles(vTmpDir, "*.*");
	
	For Each vCurrencyRow In Currencies Do
		vCurCurrency = vCurrencyRow.Currency;
			
		// Read currency rate for the start of the period to get bonus rate last used
		vLastCurrencyRates = InformationRegisters.CurrencyRates.SliceLast(PeriodFrom, New Structure("Hotel, Currency", Hotel, vCurCurrency));
	
		vRcvFileName = "" + vTmpDir + "\" + FileName;
		vRcvFileAddress = vAddress + Right(vCurCurrency.Code, 3) + vPeriod + ".tsv";
		
		Try
			vProxyServer = cmGetInternetProxy(InternetConnectionSettings, False, vSourceCite);
			If vProxyServer = Undefined Then
				vHTTP = New HTTPConnection(vSourceCite, , , , , , New OpenSSLSecureConnection());
			Else
				vHTTP = New HTTPConnection(vSourceCite, , , , vProxyServer, , New OpenSSLSecureConnection());
			EndIf;
			vHTTP.Get(New HTTPRequest(vRcvFileAddress), vRcvFileName);
		Except
			vMessage = NStr("ru = 'Не удалось получить ресурс для валюты " + TrimAll(vCurCurrency.Description) + "! Курс для валюты не загружен.'; 
			                |de = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'; 
			                |en = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'");
			WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Warning, ThisObject.Metadata(), vCurCurrency, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Continue;
			Else
				Raise vMessage;
			EndIf;
		EndTry; 

		vRcvFile = New File(vRcvFileName);
		If Not tcCommonFunctionOnClientServer.cmExists(vRcvFile) Then
			vMessage = NStr("ru = 'Не удалось получить ресурс для валюты " + TrimAll(vCurCurrency.Description) + "! Курс для валюты не загружен.'; 
			                |de = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'; 
			                |en = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'");
			WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Warning, ThisObject.Metadata(), vCurCurrency, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Continue;
			Else
				Raise vMessage;
			EndIf;
		EndIf;

		vText.Read(vRcvFileName, TextEncoding.ANSI);
		vLineCount = vText.LineCount();
		For i = 1 To vLineCount Do
			vStr = vText.GetLine(i);
			If (vStr = "") Or (Find(vStr, Chars.Tab) = 0) Then
			   Continue;
			EndIf;
			vExchangeRateDate = Undefined;
			If BegOfDay(PeriodFrom) = BegOfDay(PeriodTo) Then
				vExchangeRateDate = BegOfDay(PeriodTo);
			Else 
				vDateStr = ExtractWord(vStr);
				vExchangeRateDate = Date(Left(vDateStr, 4), Mid(vDateStr, 5, 2), Mid(vDateStr, 7, 2));
			EndIf;
			vFactor = Number(ExtractWord(vStr));
			vRate = Number(ExtractWord(vStr));

			If vExchangeRateDate > BegOfDay(PeriodTo) Then
				Break;
			EndIf;

			If vExchangeRateDate < BegOfDay(PeriodFrom) Then
			   Continue;
			EndIf;

            vCurrencyRatesMgr.Hotel = Hotel;
            vCurrencyRatesMgr.Currency = vCurCurrency;
			vCurrencyRatesMgr.Period = vExchangeRateDate;
			vCurrencyRatesMgr.Read();
			
            vCurrencyRatesMgr.Hotel = Hotel;
            vCurrencyRatesMgr.Currency = vCurCurrency;
			vCurrencyRatesMgr.Period = vExchangeRateDate;
			vCurrencyRatesMgr.Rate = vRate;
			vCurrencyRatesMgr.Factor = vFactor;
			
			If vLastCurrencyRates.Count() > 0 Then
				vLastCurrencyRatesRow = vLastCurrencyRates.Get(0);
				vCurrencyRatesMgr.BonusRate = vLastCurrencyRatesRow.BonusRate;
			EndIf;
			
			vCurrencyRatesMgr.Write();
		EndDo;
			
		// Log current state
		vMessage = NStr("ru = 'Загружены курсы для валюты " + TrimAll(vCurCurrency) + "'; 
		                |de = 'Exchange rates for " + TrimAll(vCurCurrency) + " currency were loaded'; 
		                |en = 'Exchange rates for " + TrimAll(vCurCurrency) + " currency were loaded'");
		WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Information, ThisObject.Metadata(), vCurCurrency, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
		EndIf;
	EndDo;	
	
	DeleteFiles(vTmpDir, "*.*");
EndProcedure // pmLoadCurrencyRatesFrom1C

// -----------------------------------------------------------------------------
Procedure pmLoadCurrencyRatesFromRBC(pIsInteractive) Export
	Var vHTTP;
	
	vCurrencyRatesMgr = InformationRegisters.CurrencyRates.CreateRecordManager();

	vText = New TextDocument();

	vSourceCite = "cbrates.rbc.ru";

	vAddress = "";
	vPeriod = "";
	If BegOfDay(PeriodFrom) = BegOfDay(PeriodTo) Then
		vAddress = "tsv/";
		vPeriod = "/" + Format(Year(PeriodTo),"NGS=; NG=0") + 
		          "/" + Format(Month(PeriodTo), "ND=2; NFD=0; NLZ=") + 
		          "/" + Format(Day(PeriodTo), "ND=2; NFD=0; NLZ=");
	Else
		vAddress = "tsv/cb/";
		vPeriod = "";
	EndIf;

	vTmpDir = TempFilesDir() + "LoadRates";
	CreateDirectory(vTmpDir);
	DeleteFiles(vTmpDir, "*.*");
	
	For Each vCurrencyRow In Currencies Do
		vCurCurrency = vCurrencyRow.Currency;
			
		// Read currency rate for the start of the period to get bonus rate last used
		vLastCurrencyRates = InformationRegisters.CurrencyRates.SliceLast(PeriodFrom, New Structure("Hotel, Currency", Hotel, vCurCurrency));
	
		vRcvFileName = "" + vTmpDir + "\" + FileName;
		vRcvFileAddress = vAddress + Right(vCurCurrency.Code, 3) + vPeriod + ".tsv";
		
		Try
			vProxyServer = cmGetInternetProxy(InternetConnectionSettings, False, vSourceCite);
			If vProxyServer = Undefined Then
				vHTTP = New HTTPConnection(vSourceCite);
			Else
				vHTTP = New HTTPConnection(vSourceCite, , , , vProxyServer);
			EndIf;
			vHTTP.Get(New HTTPRequest(vRcvFileAddress), vRcvFileName);
		Except
			vMessage = NStr("ru = 'Не удалось получить ресурс для валюты " + TrimAll(vCurCurrency.Description) + "! Курс для валюты не загружен.'; 
			                |de = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'; 
			                |en = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'");
			WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Warning, ThisObject.Metadata(), vCurCurrency, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Continue;
			Else
				Raise vMessage;
			EndIf;
		EndTry; 

		vRcvFile = New File(vRcvFileName);
		If Not tcCommonFunctionOnClientServer.cmExists(vRcvFile) Then
			vMessage = NStr("ru = 'Не удалось получить ресурс для валюты " + TrimAll(vCurCurrency.Description) + "! Курс для валюты не загружен.'; 
			                |de = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'; 
			                |en = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'");
			WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Warning, ThisObject.Metadata(), vCurCurrency, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Continue;
			Else
				Raise vMessage;
			EndIf;
		EndIf;

		vText.Read(vRcvFileName, TextEncoding.ANSI);
		vLineCount = vText.LineCount();
		For i = 1 To vLineCount Do
			vStr = vText.GetLine(i);
			If (vStr = "") Or (Find(vStr, Chars.Tab) = 0) Then
			   Continue;
			EndIf;
			vExchangeRateDate = Undefined;
			If BegOfDay(PeriodFrom) = BegOfDay(PeriodTo) Then
				vExchangeRateDate = BegOfDay(PeriodTo);
			Else 
				vDateStr = ExtractWord(vStr);
				vExchangeRateDate = Date(Left(vDateStr, 4), Mid(vDateStr, 5, 2), Mid(vDateStr, 7, 2));
			EndIf;
			vFactor = Number(ExtractWord(vStr));
			vRate = Number(ExtractWord(vStr));

			If vExchangeRateDate > BegOfDay(PeriodTo) Then
				Break;
			EndIf;

			If vExchangeRateDate < BegOfDay(PeriodFrom) Then
			   Continue;
			EndIf;

            vCurrencyRatesMgr.Hotel = Hotel;
            vCurrencyRatesMgr.Currency = vCurCurrency;
			vCurrencyRatesMgr.Period = vExchangeRateDate;
			vCurrencyRatesMgr.Read();
			
            vCurrencyRatesMgr.Hotel = Hotel;
            vCurrencyRatesMgr.Currency = vCurCurrency;
			vCurrencyRatesMgr.Period = vExchangeRateDate;
			vCurrencyRatesMgr.Rate = vRate;
			vCurrencyRatesMgr.Factor = vFactor;
			
			If vLastCurrencyRates.Count() > 0 Then
				vLastCurrencyRatesRow = vLastCurrencyRates.Get(0);
				vCurrencyRatesMgr.BonusRate = vLastCurrencyRatesRow.BonusRate;
			EndIf;
			
			vCurrencyRatesMgr.Write();
		EndDo;
			
		// Log current state
		vMessage = NStr("ru = 'Загружены курсы для валюты " + TrimAll(vCurCurrency) + "'; 
		                |de = 'Exchange rates for " + TrimAll(vCurCurrency) + " currency were loaded'; 
		                |en = 'Exchange rates for " + TrimAll(vCurCurrency) + " currency were loaded'");
		WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Information, ThisObject.Metadata(), vCurCurrency, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
		EndIf;
	EndDo;	
	
	DeleteFiles(vTmpDir, "*.*");
EndProcedure // pmLoadCurrencyRatesFromRBC

// -----------------------------------------------------------------------------
Procedure pmLoadCurrencyRatesFromBNM(pIsInteractive) Export
	Var vHTTP;
	
	vCurrencyRatesMgr = InformationRegisters.CurrencyRates.CreateRecordManager();
	
	vSourceCite = "www.bnm.md/";
	
	vAddress = "";
	vPresPeriod = "";
	
	vCurrPeriod = PeriodFrom;
	
	While  BegOfDay(vCurrPeriod) <= BegOfDay(PeriodTo) Do
		vAddress = "md/official_exchange_rates?get_xml=1&date=";
		vPresPeriod = TrimAll(Format(vCurrPeriod,"ДФ=dd.MM.yyyy"));
		
		vTmpDir = TempFilesDir() + "LoadRates";
		CreateDirectory(vTmpDir);
		DeleteFiles(vTmpDir, "*.*");
		
		vRcvFileName = "" + vTmpDir + "\" + "courses_" + StrReplace(vPresPeriod,".","_") + ".xml";
		vRcvFileAddress = vAddress + vPresPeriod;
		
		Try
			vProxyServer = cmGetInternetProxy(InternetConnectionSettings, False, vSourceCite);
			If vProxyServer = Undefined Then
				vHTTP = New HTTPConnection(vSourceCite);
			Else
				vHTTP = New HTTPConnection(vSourceCite, , , , vProxyServer);
			EndIf;
			vHTTP.Get(New HTTPRequest(vRcvFileAddress), vRcvFileName);
		Except
			vMessage = NStr("ru = 'Не удалось получить ресурс! Курсы для валют на дату "+vPresPeriod+" не загружен.'; 
			|de = 'Failed to receive data on date "+vPresPeriod+". Currency rates were not loaded.'; 
			|en = 'Failed to receive data on date "+vPresPeriod+". Currency rates were not loaded.'");
			WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				vCurrPeriod = vCurrPeriod+86400;
				Continue;
			Else
				Raise vMessage;
			EndIf;
		EndTry; 
		
		
		vRcvFile = New File(vRcvFileName);
		If Not tcCommonFunctionOnClientServer.cmExists(vRcvFile) Or vRcvFile.Size()=0 Then
			vMessage = NStr("ru = 'Не удалось получить ресурс! Курсы для валют на дату "+vPresPeriod+" не загружен.'; 
			|de = 'Failed to receive data on date "+vPresPeriod+". Currency rates were not loaded.'; 
			|en = 'Failed to receive data on date "+vPresPeriod+". Currency rates were not loaded.'");
			WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				vCurrPeriod = vCurrPeriod+86400;
				Continue;
			Else
				Raise vMessage;
			EndIf;
		EndIf;
		
		vListCurr = new ValueTable;
		vListCurr.Columns.Add("Code");
		vListCurr.Columns.Add("Currency");
		
		For Each vCurrencyRow In Currencies Do
			vStr = vListCurr.Add();
			vStr.Code = vCurrencyRow.Currency.Code;
			vStr.Currency = vCurrencyRow.Currency; 
		EndDo; 
		
		
		vXMLReader = New XMLReader;
		vXMLReader.OpenFile(vRcvFileName);
		
		While vXMLReader.Read() Do
			If vXMLReader.NodeType = XMLNodeType.EndElement Then
				Continue;;
			EndIf;; 
			
			vNodeName = vXMLReader.LocalName;
			
			If vNodeName = "Valute" Then
				
				vCurCode = "";
				vCurName = "";
				vCurFullName = "";
				vFactor = 0;
				vRate = 0;
				
				While vXMLReader.Read() Do
					If vXMLReader.NodeType = XMLNodeType.EndElement Then
						Continue;
					EndIf; 
					
					vNodeName = vXMLReader.LocalName;
					
					If vNodeName = "NumCode" Then
						vXMLReader.Read();
						
						vCurCode = String(vXMLReader.Value);
					ElsIf  vNodeName = "CharCode" Then
						vXMLReader.Read();
						
						vCurName = String(vXMLReader.Value);
					ElsIf  vNodeName = "Name" Then
						vXMLReader.Read();
						
						vCurFullName = String(vXMLReader.Value);
					ElsIf  vNodeName = "Nominal" Then
						vXMLReader.Read();
						
						vFactor = Число(vXMLReader.Value);
					ElsIf  vNodeName = "Value" Then
						vXMLReader.Read();
						
						vRate = Число(vXMLReader.Value);
						Break;
					EndIf; 
				EndDo;
				
				vRowListCurr = vListCurr.Find(Number(vCurCode),"Code");
				
				If vRowListCurr <> Undefined Then
					If Not (vFactor * vRate) = 0 Then
						
						// Read currency rate for the start of the period to get bonus rate last used
						vLastCurrencyRates = InformationRegisters.CurrencyRates.SliceLast(vCurrPeriod, New Structure("Hotel, Currency", Hotel, vRowListCurr.Currency));
						
						vCurrencyRatesMgr.Hotel = Hotel;
						vCurrencyRatesMgr.Currency = vRowListCurr.Currency;
						vCurrencyRatesMgr.Period = vCurrPeriod;
						vCurrencyRatesMgr.Read();
						
						vCurrencyRatesMgr.Hotel = Hotel;
						vCurrencyRatesMgr.Currency = vRowListCurr.Currency;
						vCurrencyRatesMgr.Period = vCurrPeriod;
						vCurrencyRatesMgr.Rate = vRate;
						vCurrencyRatesMgr.Factor = vFactor;
						
						If vLastCurrencyRates.Count() > 0 Then
							vLastCurrencyRatesRow = vLastCurrencyRates.Get(0);
							vCurrencyRatesMgr.BonusRate = vLastCurrencyRatesRow.BonusRate;
						EndIf;
						
						vCurrencyRatesMgr.Write();
					EndIf;
				EndIf; 
			EndIf; 
		EndDo;
		
		vXMLReader.Close();
		
		//Log current state
		vMessage = NStr("en = 'Exchange rates currency were loaded on date "+vPresPeriod+"'; ru = 'Курсы  валют загружены на "+vPresPeriod+"'; de = 'Exchange rates currency were loaded on date "+vPresPeriod+"'");
		WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Information, ThisObject.Metadata(), , vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
		EndIf;
		
		DeleteFiles(vTmpDir, "*.*");
		
		vCurrPeriod = vCurrPeriod+86400;
	EndDo;

EndProcedure // pmLoadCurrencyRatesFromBNM

// -----------------------------------------------------------------------------
Procedure pmLoadCurrencyRatesFrom1CKato(pIsInteractive) Export
	Var vHTTP;
	
	vCurrencyRatesMgr = InformationRegisters.CurrencyRates.CreateRecordManager();

	vText = New TextDocument();

	vSourceCite = "1c-kato.kg";

	vAddress = "/kato/currency.php";
	vParams = "";
	If BegOfDay(PeriodFrom) = BegOfDay(PeriodTo) Then
		vPeriod = "/" + Format(Year(PeriodTo),"NGS=; NG=0") + 
		          "/" + Format(Month(PeriodTo), "ND=2; NFD=0; NLZ=") + 
		          "/" + Format(Day(PeriodTo), "ND=2; NFD=0; NLZ=");
		vParams = "&year="+Format(Year(PeriodTo),"NGS=; NG=0") + 
		          "&month="+Format(Month(PeriodTo),"ND=2; NFD=0; NLZ=") + 
				  "&day="+Format(Day(PeriodTo),"ND=2; NFD=0; NLZ=");
	EndIf;

	vTmpDir = TempFilesDir() + "LoadRates";
	CreateDirectory(vTmpDir);
	DeleteFiles(vTmpDir, "*.*");
	
	For Each vCurrencyRow In Currencies Do
		vCurCurrency = vCurrencyRow.Currency;
			
		// Read currency rate for the start of the period to get bonus rate last used
		vLastCurrencyRates = InformationRegisters.CurrencyRates.SliceLast(PeriodFrom, New Structure("Hotel, Currency", Hotel, vCurCurrency));
		
		vRcvFileName = "" + vTmpDir + "\" + FileName;
		vRcvFileAddress = vAddress + "?currency=" + Right(vCurCurrency.Code, 3) + vParams;
		
		Try
			vProxyServer = cmGetInternetProxy(InternetConnectionSettings, False, vSourceCite);
			If vProxyServer = Undefined Then
				vHTTP = New HTTPConnection(vSourceCite);
			Else
				vHTTP = New HTTPConnection(vSourceCite, , , , vProxyServer);
			EndIf;
			vHTTP.Get(New HTTPRequest(vRcvFileAddress), vRcvFileName);
		Except
			vMessage = NStr("ru = 'Не удалось получить ресурс для валюты " + TrimAll(vCurCurrency.Description) + "! Курс для валюты не загружен.';
			                |de = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'; 
			                |en = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'");
			WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Warning, ThisObject.Metadata(), vCurCurrency, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Continue;
			Else
				Raise vMessage;
			EndIf;
		EndTry; 

		vRcvFile = New File(vRcvFileName);
		If Not tcCommonFunctionOnClientServer.cmExists(vRcvFile) Then
			vMessage = NStr("ru = 'Не удалось получить ресурс для валюты " + TrimAll(vCurCurrency.Description) + "! Курс для валюты не загружен.'; 
			                |de = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'; 
			                |en = 'Failed to receive data for the " + TrimAll(vCurCurrency.Description) + "! Currency rates were not loaded.'");
			WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Warning, ThisObject.Metadata(), vCurCurrency, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Continue;
			Else
				Raise vMessage;
			EndIf;
		EndIf;

		vText.Read(vRcvFileName, TextEncoding.ANSI);
		vLineCount = vText.LineCount();
		For i = 1 To vLineCount Do
			vStr = vText.GetLine(i);
			If (vStr = "") Or (Find(vStr, Chars.Tab) = 0) Then
			   Continue;
			EndIf;
			vExchangeRateDate = Undefined;
			If BegOfDay(PeriodFrom) = BegOfDay(PeriodTo) Then
				vExchangeRateDate = BegOfDay(PeriodTo);
			Else 
				vDateStr = ExtractWord(vStr);
				vExchangeRateDate = Date(Left(vDateStr, 4), Mid(vDateStr, 5, 2), Mid(vDateStr, 7, 2));
			EndIf;
			vFactor = Number(ExtractWord(vStr));
			vRate = Number(ExtractWord(vStr));
			
			If vRate <= 0 Or vFactor <= 0 Then
			   Continue;
			EndIf;

			If vExchangeRateDate > BegOfDay(PeriodTo) Then
				Break;
			EndIf;

			If vExchangeRateDate < BegOfDay(PeriodFrom) Then
			   Continue;
			EndIf;

            vCurrencyRatesMgr.Hotel = Hotel;
            vCurrencyRatesMgr.Currency = vCurCurrency;
			vCurrencyRatesMgr.Period = vExchangeRateDate;
			vCurrencyRatesMgr.Read();
			
            vCurrencyRatesMgr.Hotel = Hotel;
            vCurrencyRatesMgr.Currency = vCurCurrency;
			vCurrencyRatesMgr.Period = vExchangeRateDate;
			vCurrencyRatesMgr.Rate = vRate;
			vCurrencyRatesMgr.Factor = vFactor;
			
			If vLastCurrencyRates.Count() > 0 Then
				vLastCurrencyRatesRow = vLastCurrencyRates.Get(0);
				vCurrencyRatesMgr.BonusRate = vLastCurrencyRatesRow.BonusRate;
			EndIf;
			
			vCurrencyRatesMgr.Write();
		EndDo;
			
		// Log current state
		vMessage = NStr("ru = 'Загружены курсы для валюты " + TrimAll(vCurCurrency) + "'; 
		                |de = 'Exchange rates for " + TrimAll(vCurCurrency) + " currency were loaded'; 
		                |en = 'Exchange rates for " + TrimAll(vCurCurrency) + " currency were loaded'");
		WriteLogEvent(NStr("en='DataProcessor.LoadCurrencyRates';ru='Обработка.ЗагрузкаКурсовВалют';de='Обработка.ЗагрузкаКурсовВалют'"), EventLogLevel.Information, ThisObject.Metadata(), vCurCurrency, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
		EndIf;
	EndDo;	
	
	DeleteFiles(vTmpDir, "*.*");
EndProcedure // pmLoadCurrencyRatesFrom1CKato

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// Extracts characters before first TAB
Function ExtractWord(pStr)
	vWord = "";
    vPos = Find(pStr, Chars.Tab);
	If vPos > 0 Then
		vWord = Left(pStr, vPos-1);
		pStr = Mid(pStr, vPos+1);
	Else
		vWord = pStr;
		pStr = "";
	EndIf;
	Return vWord;
EndFunction // ExtractWord

#EndRegion

#Region Initialize

FileName = "CurrencyRates.txt";  

#EndRegion
