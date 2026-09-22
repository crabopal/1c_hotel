&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Hotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(Hotel) Then
		CurrencyTo = Hotel.BaseCurrency;
	Else
		pCancel = True;
	EndIf;
EndProcedure

&AtServer
Procedure CalculateAtServer()
	If ValueIsFilled(CurrencyFrom) and ValueIsFilled(CurrencyTo) Then   
		AmountTo = Round(cmConvertCurrencies(AmountFrom, CurrencyFrom, , CurrencyTo, , CurrentSessionDate(), Hotel), 2);
	EndIf;	
EndProcedure

&AtServer
Procedure AmountToOnChangeAtServer()
	If ValueIsFilled(CurrencyFrom) and ValueIsFilled(CurrencyTo) Then   	
		AmountFrom = Round(cmConvertCurrencies(AmountTo, CurrencyTo, , CurrencyFrom, , CurrentSessionDate(), Hotel), 2);	
	EndIf;	
EndProcedure

&AtClient
Procedure Calculate(Command)
	CalculateAtServer();
EndProcedure

&AtServer
Procedure CurrencyFromOnChangeAtServer()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CurrencyRatesSliceLast.Rate,
	|	CurrencyRatesSliceLast.Factor,
	|	CurrencyRatesSliceLast.BonusRate,
	|	CurrencyRatesSliceLast.Period
	|FROM
	|	InformationRegister.CurrencyRates.SliceLast AS CurrencyRatesSliceLast
	|WHERE
	|	CurrencyRatesSliceLast.Hotel = &qHotel
	|	AND CurrencyRatesSliceLast.Currency = &qCurrency";
	Query.SetParameter("qCurrency", CurrencyFrom);
	Query.SetParameter("qHotel", Hotel);	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();	
	If SelectionDetailRecords.Next() Then
		RateFrom = String(SelectionDetailRecords.Rate) + " " + NStr(Hotel.BaseCurrency.DescriptionTranslations);
	EndIf;	
	CalculateAtServer();
EndProcedure

&AtClient
Procedure CurrencyFromOnChange(Item)
	CurrencyFromOnChangeAtServer();
EndProcedure

&AtServer
Procedure CurrencyToOnChangeAtServer()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CurrencyRatesSliceLast.Rate,
	|	CurrencyRatesSliceLast.Factor,
	|	CurrencyRatesSliceLast.BonusRate,
	|	CurrencyRatesSliceLast.Period
	|FROM
	|	InformationRegister.CurrencyRates.SliceLast AS CurrencyRatesSliceLast
	|WHERE
	|	CurrencyRatesSliceLast.Hotel = &qHotel
	|	AND CurrencyRatesSliceLast.Currency = &qCurrency";
	Query.SetParameter("qCurrency", CurrencyTo);
	Query.SetParameter("qHotel", Hotel);	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();	
	If SelectionDetailRecords.Next() Then
		RateTo = String(SelectionDetailRecords.Rate) + " " + NStr(Hotel.BaseCurrency.DescriptionTranslations);
	EndIf;	
	CalculateAtServer();
EndProcedure

&AtClient
Procedure CurrencyToOnChange(Item)
	CurrencyToOnChangeAtServer();
EndProcedure

&AtClient
Procedure AmountToOnChange(Item)
	AmountToOnChangeAtServer();
EndProcedure

&AtClient
Procedure AmountFromOnChange(Item)
	CalculateAtServer();
EndProcedure
