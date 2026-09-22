
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pPromoCode		 - String	 - Promocode
//  pHotel			 - CatalogRef.Hotels - Ref
//  pCheckInDate	 - Date				 - Date
//  pCheckOutDate	 - Date				 - Date
// 
// Returns:
//  CatalogRef.DiscountTypes - Ref
//
Function GetDiscountTypeByPromoCode(pPromoCode, pHotel, pCheckInDate = '00010101', pCheckOutDate = '00010101') Export
	vDiscountType = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DiscountTypes.Ref AS DiscountType,
	|	DiscountTypes.Code AS Code,
	|	DiscountTypes.SortCode AS SortCode
	|FROM
	|	Catalog.DiscountTypes AS DiscountTypes
	|WHERE
	|	(DiscountTypes.PromoCode = &qPromoCode
	|			OR DiscountTypes.Code = &qPromoCode)
	|	AND (DiscountTypes.Hotel = &qHotel
	|			OR DiscountTypes.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR NOT &qHotelIsFilled)
	|	AND NOT DiscountTypes.DeletionMark
	|	AND NOT DiscountTypes.IsFolder
	|	AND DiscountTypes.DateValidFrom <= &qCheckInDate
	|	AND (DiscountTypes.DateValidTo = &qEmptyDate
	|			OR DiscountTypes.DateValidTo >= &qCheckOutDate)
	|
	|ORDER BY
	|	SortCode,
	|	Code";
	vQry.SetParameter("qPromoCode", Upper(TrimAll(pPromoCode)));
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pHotel));
	vQry.SetParameter("qCheckInDate", BegOfDay(pCheckInDate));
	vQry.SetParameter("qCheckOutDate", BegOfDay(pCheckOutDate));
	vQry.SetParameter("qEmptyDate", '00010101');
	vPromoCodes = vQry.Execute().Unload();
	For Each vPromoCodesRow In vPromoCodes Do
		vDiscountType = vPromoCodesRow.DiscountType;
		Break;
	EndDo;
	Return vDiscountType;
EndFunction // GetDiscountTypeByPromoCode

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
