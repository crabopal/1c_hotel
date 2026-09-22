
#Region Public

// --------------------------------------------------------------------------------
//  Getting a card balance
//
// Parameters:
//  pCard	 - Catalog.DiscountCards - ref on discount card
//  pDate	 - Date, Undefined		 - 
// 
// Returns:
//  Amount - Number - balance by card
//
Function mmGetBalanceByCard(pCard, pDate = Undefined, pExchangeRateDate = Undefined, pHotel = Undefined) Export
	vResult = New Structure;
	vResult.Insert("Balance", 0);
	vResult.Insert("BalanceAmount", 0);
	vResult.Insert("MaxPercentPayment", ?(ValueIsFilled(pCard), ?(ValueIsFilled(pCard.DiscountType), pCard.DiscountType.MaxPercentPayment, 0), 0));
	vResult.Insert("TypeCard", ?(ValueIsFilled(pCard), XMLString(pCard.LoyaltyType), ""));
	vResult.Insert("CertificateNominal", 0);
	vResult.Insert("BonusRate", 1);
	If Not ValueIsFilled(pCard) Then
		Return vResult;
	EndIf;
	If ValueIsFilled(pCard.DiscountType) And pCard.DiscountType.ExternalBonusSystemIsUsed Then  
		// Get a balance in an external system	
		Return vResult;
	EndIf;
	If pDate = Undefined Then
		vDate = CurrentSessionDate();
	Else
		vDate = pDate;
	EndIf;	
	If pExchangeRateDate = Undefined Then
		vExchangeRateDate = vDate;
	Else
		vExchangeRateDate = pExchangeRateDate;
	EndIf;
	// Get bonuses or certificate balance
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BonusesBalance.QuantityBalance AS QuantityBalance
	|FROM
	|	AccumulationRegister.Bonuses.Balance(&qDate, Card = &qCard) AS BonusesBalance";
	Query.SetParameter("qCard", pCard);
	Query.SetParameter("qDate", New Boundary(vDate, BoundaryType.Including));
	QueryResult = Query.Execute();
	vRes = QueryResult.Select();
	If vRes.Next() Then
		vBalance = vRes.QuantityBalance;
	EndIf;
	vHotel = pHotel;
	If Not ValueIsFilled(pHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = pCard.CreateHotel;
	EndIf;
	// Recalculate bonuses to the payment currency
	vResult.BonusRate = ?(ValueIsFilled(pCard.DiscountType), ?(pCard.DiscountType.BonusRateMultiplier = 0, 1, pCard.DiscountType.BonusRateMultiplier), 1);
	vRates = InformationRegisters.CurrencyRates.SliceLast(vExchangeRateDate, New Structure("Hotel, Currency", vHotel, ?(ValueIsFilled(pCard.Folio), pCard.Folio.FolioCurrency, vHotel.FolioCurrency)));
	If vRates.Count() > 0 Then
		vRatesRow = vRates.Get(0);
		If vRatesRow.BonusRate <> 0 Then
			vResult.BonusRate = Round(vRatesRow.BonusRate * vResult.BonusRate, 4);
		ElsIf vRatesRow.Rate <> 0 Then
			vResult.BonusRate = Round(vRatesRow.Rate / ?(vRatesRow.Factor = 0, 1, vRatesRow.Factor) * vResult.BonusRate, 4);
		EndIf;
	EndIf;
	vResult.Balance = vBalance;
	vResult.BalanceAmount = Round(vBalance / vResult.BonusRate, 2);
	// Get certifacate nominal
	If pCard.LoyaltyType = Enums.LoyaltyType.Certificate Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	ISNULL(SUM(Bonuses.Quantity), 0) AS Quantity
		|FROM
		|	AccumulationRegister.Bonuses AS Bonuses
		|WHERE
		|	Bonuses.Card = &qCard
		|	AND Bonuses.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND NOT (Bonuses.Recorder.Payment REFS Document.Return
		|				AND (Bonuses.Recorder.Payment.PaymentMethod.IsByBonuses
		|					OR Bonuses.Recorder.Payment.PaymentMethod.IsByGiftCertificate))";
		Query.SetParameter("qCard", pCard);
		QueryResult = Query.Execute();
		vRes = QueryResult.Select();
		If vRes.Next() Then
			vResult.CertificateNominal = Round(vRes.Quantity / vResult.BonusRate, 2);
		EndIf;
	EndIf;
	Return vResult;
EndFunction //  mmGetBalnceByCard()

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - DataRow	 - Data
//  pReceiverNode	 - Node	 - Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

#EndRegion  
