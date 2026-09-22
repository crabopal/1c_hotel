
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pPromoCode		 - String	 - PromoCode
//  pHotel			 - CatalogRef.Hotels - Ref
//  pDate			 - Date				 - Date
//  pCheckInDate	 - Date				 - CheckInDate
//  pCheckOutDate	 - Date				 - CheckOutDate
// 
// Returns:
//  CatalogRef - Special offer
//
Function GetSpecialOfferByPromoCode(pPromoCode, pHotel, pDate = '00010101', pCheckInDate = '00010101', pDuration = 0, pCheckOutDate = '00010101', 
                                    pRoomRate = Undefined, pRoomRateType = Undefined, pClientType = Undefined, pCustomerType = Undefined, 
                                    pSourceOfBusiness = Undefined, pMarketingCode = Undefined, pTripPurpose = Undefined, pRoomType = Undefined, 
									rDatesList = Undefined) Export
	vSpecialOffer = Undefined;
	rDatesList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SpecialOffers.Ref AS SpecialOffer,
	|	SpecialOffers.Code AS Code,
	|	SpecialOfferPeriods.PeriodOfStayFrom AS PeriodOfStayFrom,
	|	SpecialOfferPeriods.PeriodOfStayTo AS PeriodOfStayTo
	|FROM
	|	Catalog.SpecialOffers AS SpecialOffers
	|		INNER JOIN InformationRegister.SpecialOfferPeriods AS SpecialOfferPeriods
	|		ON SpecialOffers.Ref = SpecialOfferPeriods.SpecialOffer
	|			AND (SpecialOfferPeriods.Hotel = &qHotel
	|				OR SpecialOfferPeriods.Hotel = &qHotelParent
	|					AND &qHotelParent <> VALUE(Catalog.Hotels.EmptyRef)
	|				OR SpecialOfferPeriods.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|				OR NOT &qHotelIsFilled)
	|			AND (SpecialOfferPeriods.DateValidFrom <= &qDate)
	|			AND (SpecialOfferPeriods.DateValidTo = &qEmptyDate
	|				OR SpecialOfferPeriods.DateValidTo >= &qDate)
	|			AND (SpecialOfferPeriods.CheckInDateFrom <= &qCheckInDate)
	|			AND (SpecialOfferPeriods.CheckInDateTo = &qEmptyDate
	|				OR SpecialOfferPeriods.CheckInDateTo >= &qCheckInDate)
	|			AND (NOT SpecialOfferPeriods.ApplyToDatesInsidePeriodOfStayOnly
	|					AND SpecialOfferPeriods.PeriodOfStayFrom <= &qCheckInDate
	|					AND (SpecialOfferPeriods.PeriodOfStayTo = &qEmptyDate
	|						OR SpecialOfferPeriods.PeriodOfStayTo >= &qCheckOutDate)
	|				OR SpecialOfferPeriods.ApplyToDatesInsidePeriodOfStayOnly
	|					AND SpecialOfferPeriods.PeriodOfStayFrom < &qCheckOutDate
	|					AND (SpecialOfferPeriods.PeriodOfStayTo = &qEmptyDate
	|						OR SpecialOfferPeriods.PeriodOfStayTo >= &qCheckInDate))
	|		INNER JOIN InformationRegister.SpecialOffersForRoomTypes AS SpecialOffersForRoomTypes
	|		ON SpecialOffers.Ref = SpecialOffersForRoomTypes.SpecialOffer
	|			AND (SpecialOffersForRoomTypes.Hotel = &qHotel
	|				OR SpecialOffersForRoomTypes.Hotel = &qHotelParent
	|				OR SpecialOffersForRoomTypes.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|			AND (SpecialOffersForRoomTypes.RoomType = &qRoomType
	|					AND &qRoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR SpecialOffersForRoomTypes.RoomClass = &qRoomClass
	|					AND &qRoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef)
	|				OR SpecialOffersForRoomTypes.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|					AND SpecialOffersForRoomTypes.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|		INNER JOIN InformationRegister.SpecialOffersForRates AS SpecialOffersForRates
	|		ON SpecialOffers.Ref = SpecialOffersForRates.SpecialOffer
	|			AND (SpecialOffersForRates.Hotel = &qHotel
	|				OR SpecialOffersForRates.Hotel = &qHotelParent
	|				OR SpecialOffersForRates.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|			AND (SpecialOffersForRates.RoomRate = &qRoomRate
	|				OR SpecialOffersForRates.RoomRate = &qRoomRateParent
	|				OR SpecialOffersForRates.RoomRate = &qRoomRateParentParent
	|				OR SpecialOffersForRates.RoomRate = VALUE(Catalog.RoomRates.EmptyRef))
	|			AND (SpecialOffersForRates.RoomRateType = &qRoomRateType
	|				OR SpecialOffersForRates.RoomRateType = &qRoomRateTypeParent
	|				OR SpecialOffersForRates.RoomRateType = VALUE(Catalog.RoomRateTypes.EmptyRef))
	|			AND (SpecialOffersForRates.ClientType = &qClientType
	|				OR SpecialOffersForRates.ClientType = &qClientTypeParent
	|				OR SpecialOffersForRates.ClientType = VALUE(Catalog.ClientTypes.EmptyRef))
	|			AND (SpecialOffersForRates.CustomerType = &qCustomerType
	|				OR SpecialOffersForRates.CustomerType = &qCustomerTypeParent
	|				OR SpecialOffersForRates.CustomerType = VALUE(Catalog.CustomerTypes.EmptyRef))
	|			AND (SpecialOffersForRates.SourceOfBusiness = &qSourceOfBusiness
	|				OR SpecialOffersForRates.SourceOfBusiness = &qSourceOfBusinessParent
	|				OR SpecialOffersForRates.SourceOfBusiness = VALUE(Catalog.SourcesOfBusiness.EmptyRef))
	|			AND (SpecialOffersForRates.MarketingCode = &qMarketingCode
	|				OR SpecialOffersForRates.MarketingCode = &qMarketingCodeParent
	|				OR SpecialOffersForRates.MarketingCode = VALUE(Catalog.MarketingCodes.EmptyRef))
	|			AND (SpecialOffersForRates.TripPurpose = &qTripPurpose
	|				OR SpecialOffersForRates.TripPurpose = VALUE(Catalog.TripPurposes.EmptyRef))
	|			AND (&qDuration >= SpecialOffersForRates.MLOS
	|				OR SpecialOffersForRates.MLOS = 0)
	|			AND (&qDuration <= SpecialOffersForRates.MaxLOS
	|				OR SpecialOffersForRates.MaxLOS = 0)
	|			AND (&qDaysBeforeCheckIn >= SpecialOffersForRates.MinDaysBeforeCheckIn
	|				OR SpecialOffersForRates.MinDaysBeforeCheckIn = 0
	|				OR &qDaysBeforeCheckIn = -1)
	|			AND (&qDaysBeforeCheckIn <= SpecialOffersForRates.MaxDaysBeforeCheckIn
	|				OR SpecialOffersForRates.MaxDaysBeforeCheckIn = 0
	|				OR &qDaysBeforeCheckIn = -1)
	|WHERE
	|	SpecialOffers.PromoCode = &qPromoCode
	|	AND (SpecialOffers.Hotel = &qHotel
	|			OR SpecialOffers.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR NOT &qHotelIsFilled)
	|	AND NOT SpecialOffers.DeletionMark
	|	AND NOT SpecialOffers.IsFolder
	|
	|GROUP BY
	|	SpecialOffers.Ref,
	|	SpecialOffers.Code,
	|	SpecialOfferPeriods.PeriodOfStayFrom,
	|	SpecialOfferPeriods.PeriodOfStayTo
	|
	|ORDER BY
	|	Code";
	vQry.SetParameter("qPromoCode", Upper(TrimAll(pPromoCode)));
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsFilled", ValueIsFilled(pHotel));
	If ValueIsFilled(pHotel) And ValueIsFilled(pHotel.Parent) Then
		vQry.SetParameter("qHotelParent", pHotel.Parent);
	Else
		vQry.SetParameter("qHotelParent", Undefined);
	EndIf;
	vQry.SetParameter("qDate", BegOfDay(pDate));
	vQry.SetParameter("qCheckInDate", BegOfDay(pCheckInDate));
	vQry.SetParameter("qCheckOutDate", BegOfDay(pCheckOutDate));
	vQry.SetParameter("qDuration", pDuration);
	vQry.SetParameter("qEmptyDate", '00010101');
	If ValueIsFilled(pDate) And ValueIsFilled(pCheckInDate) And pCheckInDate > pDate Then
		vQry.SetParameter("qDaysBeforeCheckIn", (BegOfDay(pCheckInDate) - BegOfDay(pDate))/(24*3600));
	Else
		vQry.SetParameter("qDaysBeforeCheckIn", -1);
	EndIf;
	vQry.SetParameter("qRoomType", pRoomType);
	If ValueIsFilled(pRoomType) And ValueIsFilled(pRoomType.RoomClass) Then
		vQry.SetParameter("qRoomClass", pRoomType.RoomClass);
	Else
		vQry.SetParameter("qRoomClass", Catalogs.RoomTypeClasses.EmptyRef());
	EndIf;
	vQry.SetParameter("qRoomRate", pRoomRate);
	If ValueIsFilled(pRoomRate) And ValueIsFilled(pRoomRate.Parent) Then
		vQry.SetParameter("qRoomRateParent", pRoomRate.Parent);
		If ValueIsFilled(pRoomRate.Parent.Parent) Then
			vQry.SetParameter("qRoomRateParentParent", pRoomRate.Parent.Parent);
		Else
			vQry.SetParameter("qRoomRateParentParent", Undefined);
		EndIf;
	Else
		vQry.SetParameter("qRoomRateParent", Undefined);
		vQry.SetParameter("qRoomRateParentParent", Undefined);
	EndIf;
	vQry.SetParameter("qRoomRateType", pRoomRateType);
	If ValueIsFilled(pRoomRateType) And ValueIsFilled(pRoomRateType.Parent) Then
		vQry.SetParameter("qRoomRateTypeParent", pRoomRateType.Parent);
	Else
		vQry.SetParameter("qRoomRateTypeParent", Undefined);
	EndIf;
	vQry.SetParameter("qClientType", pClientType);
	If ValueIsFilled(pClientType) And ValueIsFilled(pClientType.Parent) Then
		vQry.SetParameter("qClientTypeParent", pClientType.Parent);
	Else
		vQry.SetParameter("qClientTypeParent", Undefined);
	EndIf;
	vQry.SetParameter("qCustomerType", pCustomerType);
	If ValueIsFilled(pCustomerType) And ValueIsFilled(pCustomerType.Parent) Then
		vQry.SetParameter("qCustomerTypeParent", pCustomerType.Parent);
	Else
		vQry.SetParameter("qCustomerTypeParent", Undefined);
	EndIf;
	vQry.SetParameter("qSourceOfBusiness", pSourceOfBusiness);
	If ValueIsFilled(pSourceOfBusiness) And ValueIsFilled(pSourceOfBusiness.Parent) Then
		vQry.SetParameter("qSourceOfBusinessParent", pSourceOfBusiness.Parent);
	Else
		vQry.SetParameter("qSourceOfBusinessParent", Undefined);
	EndIf;
	vQry.SetParameter("qMarketingCode", pMarketingCode);
	If ValueIsFilled(pMarketingCode) And ValueIsFilled(pMarketingCode.Parent) Then
		vQry.SetParameter("qMarketingCodeParent", pMarketingCode.Parent);
	Else
		vQry.SetParameter("qMarketingCodeParent", Undefined);
	EndIf;
	vQry.SetParameter("qTripPurpose", pTripPurpose);
	vPromoCodes = vQry.Execute().Unload();
	For Each vPromoCodesRow In vPromoCodes Do
		If vSpecialOffer = Undefined Then
			vSpecialOffer = vPromoCodesRow.SpecialOffer;
		EndIf;
		vCurDate = ?(ValueIsFilled(vPromoCodesRow.PeriodOfStayFrom), Max(BegOfDay(pCheckInDate), vPromoCodesRow.PeriodOfStayFrom), BegOfDay(pCheckInDate));
		vPeriodOfStayTo = ?(ValueIsFilled(vPromoCodesRow.PeriodOfStayTo), Min(BegOfDay(pCheckOutDate), vPromoCodesRow.PeriodOfStayTo), BegOfDay(pCheckOutDate));
		While vCurDate <= vPeriodOfStayTo Do
			rDatesList.Add(vCurDate);
			vCurDate = vCurDate + 24*3600;
		EndDo;
	EndDo;
	Return vSpecialOffer;
EndFunction // GetSpecialOfferByPromoCode

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
