 
 #Region Public
 
 // --------------------------------------------------------------------------------
 //  Function - Labeled good paid
 //
 // Parameters:
 //  pMarkingCode - String						 - Marking code
 //  pHotel		 - CatalogRef.Hotels			 - Hotel ref
 //  pDateTo		 - Date							 - Date
 //  pService	 - CatalogRef.Services, Undefined - ref
 // 
 // Returns:
 //  Boolean - True or False, was paid
 //
 Function LabeledGoodPaid(pMarkingCode, pHotel, pDateTo = Undefined, pService = Undefined) Export 
	 
	 vQuery = New Query;
	 vQuery.Text = 
	 "SELECT
	 |	LabeledGoodsBalance.MarkingCode AS MarkingCode,
	 |	LabeledGoodsBalance.Service AS Service,
	 |	LabeledGoodsBalance.Folio AS Folio,
	 |	LabeledGoodsBalance.SumBalance AS SumBalance,
	 |	LabeledGoodsBalance.QuantityBalance AS QuantityBalance
	 |FROM
	 |	AccumulationRegister.LabeledGoods.Balance(
	 |			&qDateTo,
	 |			(&qServiceNotFilled
	 |				OR NOT &qServiceNotFilled
	 |					AND Service = &qService)
	 |				AND MarkingCode = &qMarkingCode
	 |				AND Folio.Hotel = &qHotel) AS LabeledGoodsBalance";
	 
	 vQuery.SetParameter("qDateTo", pDateTo);
	 vQuery.SetParameter("qMarkingCode", pMarkingCode);
	 vQuery.SetParameter("qHotel", pHotel); 
	 vQuery.SetParameter("qService", pService);
	 vQuery.SetParameter("qServiceNotFilled", Not ValueIsFilled(pService));
	 
	 vQueryResult = vQuery.Execute();
	 
	 Return vQueryResult.IsEmpty()
 EndFunction
 
// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - DataRow	 - Data
//  pReceiverNode	 - Node		 - Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	 // NOTHING SO FAR	
 EndProcedure // ExchangePlansRecordChanges
 
 #EndRegion
 