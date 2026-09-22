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
		vCurrencyRates = cmGetCurrencyExchangeRates(Hotel, vRow.Currency, Period);
		For Each vCurrencyRatesRow In vCurrencyRates Do
			vRow.Rate = vCurrencyRatesRow.Rate;
			vRow.TravellerChequeRate = vCurrencyRatesRow.TravellerChequeRate;
			vRow.Factor = vCurrencyRatesRow.Factor;
			vRow.BonusRate = vCurrencyRatesRow.BonusRate;
			Break;
		EndDo;
	EndDo;
EndProcedure // pmFillCurrenciesList

// -----------------------------------------------------------------------------
Procedure pmSetCurrencyRates() Export
	vCurrencyRatesMgr = InformationRegisters.CurrencyRates.CreateRecordManager();
	For Each vCurrencyRow In Currencies Do
		vCurrencyRatesMgr.Hotel = Hotel;
		vCurrencyRatesMgr.Currency = vCurrencyRow.Currency;
		vCurrencyRatesMgr.Period = Period;
		vCurrencyRatesMgr.Read();
		
		vCurrencyRatesMgr.Hotel = Hotel;
		vCurrencyRatesMgr.Currency = vCurrencyRow.Currency;
		vCurrencyRatesMgr.Period = Period;
		vCurrencyRatesMgr.Rate = vCurrencyRow.Rate;
		vCurrencyRatesMgr.TravellerChequeRate = vCurrencyRow.TravellerChequeRate;
		vCurrencyRatesMgr.Factor = vCurrencyRow.Factor;
		vCurrencyRatesMgr.BonusRate = vCurrencyRow.BonusRate;
		vCurrencyRatesMgr.Write();
	EndDo;
EndProcedure // pmSetCurrencyRates
