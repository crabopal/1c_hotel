// -----------------------------------------------------------------------------
// Description: Returns list of accumulation discount types
// Parameters: Discount type to return in value table
// Return value: Value table with accumulating discount types
// -----------------------------------------------------------------------------
Function cmGetAccumulatingDiscountTypes(pDiscountType = Undefined, pHotel = Undefined) Export
	Return CachedSettings.cmGetAccumulatingDiscountTypesTable(pDiscountType, pHotel);
EndFunction // cmGetAccumulatingDiscountTypes

// -----------------------------------------------------------------------------
// Description: Returns list of bonus discount types
// Parameters: Discount type to return in value table
// Return value: Value table with bonus discount types
// -----------------------------------------------------------------------------
Function cmGetBonusDiscountTypes(pDiscountType = Undefined, pHotel = Undefined) Export
	// Build and run query
	qAccDisTypes = New Query;
	qAccDisTypes.Text = 
	"SELECT
	|	DiscountTypes.Ref AS DiscountType,
	|	DiscountTypes.SortCode AS SortCode
	|FROM
	|	Catalog.DiscountTypes AS DiscountTypes
	|WHERE
	|	NOT DiscountTypes.DeletionMark
	|	AND NOT DiscountTypes.IsFolder
	|	AND (DiscountTypes.LoyaltyType = VALUE(Enum.LoyaltyType.Bonuses)
	|			OR DiscountTypes.IsAccumulatingDiscount
	|				AND DiscountTypes.BonusCalculationFactor <> 0)
	|	AND (&qDiscountTypeIsEmpty
	|			OR NOT &qDiscountTypeIsEmpty
	|				AND DiscountTypes.Ref = &qDiscountType)
	|	AND (NOT &qHotelIsFilled
	|			OR &qHotelIsFilled
	|				AND (DiscountTypes.Hotel = &qHotel
	|					OR DiscountTypes.Hotel = VALUE(Catalog.Hotels.EmptyRef)))
	|
	|ORDER BY
	|	SortCode";
	vDiscountType = Catalogs.DiscountTypes.EmptyRef();
	If ValueIsFilled(pDiscountType) Then
		If Not pDiscountType.IsFolder And Not pDiscountType.DeletionMark Then
			vDiscountType = pDiscountType;
		EndIf;
	EndIf;
	qAccDisTypes.SetParameter("qDiscountType", vDiscountType);
	qAccDisTypes.SetParameter("qDiscountTypeIsEmpty", Not ValueIsFilled(vDiscountType));
	qAccDisTypes.SetParameter("qHotel", pHotel);
	qAccDisTypes.SetParameter("qHotelIsFilled", ValueIsFilled(pHotel));
	vAccDisTypes = qAccDisTypes.Execute().Unload();
	Return vAccDisTypes;
EndFunction // cmGetBonusDiscountTypes

// -----------------------------------------------------------------------------
// Description: Checks if first discount is greater then second one
// Parameters: First discount percent, Second discount percent
// Return value: True if greater, False if not
// -----------------------------------------------------------------------------
Function cmFirstDiscountIsGreater(pFirstDiscount, pSecondDiscount) Export
	If pFirstDiscount > pSecondDiscount Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmFirstDiscountIsGreater

// -----------------------------------------------------------------------------
// Description: Returns discount dimension type description
// Parameters: None
// Return value: None
// -----------------------------------------------------------------------------
Function cmGetDiscountDimensionTypeDescription() Export
	vTA = New Array;
	vTA.Add(Type("CatalogRef.Customers"));
	vTA.Add(Type("CatalogRef.Contracts"));
	vTA.Add(Type("CatalogRef.Clients"));
	vTA.Add(Type("CatalogRef.DiscountCards"));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetDiscountDimensionTypeDescription

// -----------------------------------------------------------------------------
// Description: Returns accumulating discount resource type description
// Parameters: None
// Return value: None
// -----------------------------------------------------------------------------
Function cmGetAccumulatingDiscountResourceTypeDescription() Export
	vNQ = New NumberQualifiers(19, 7);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, , vNQ);
	Return vTypeDescr;
EndFunction // cmGetAccumulatingDiscountResourceTypeDescription

// -----------------------------------------------------------------------------
// Description: Function tries to find and return discount card by card identifier
// Parameters: Card identifier
// Return value: Discount card reference or empty reference
// -----------------------------------------------------------------------------
Function cmGetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False) Export
	vDiscountCardRef = Catalogs.DiscountCards.EmptyRef();
	// Try to find discount card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	(NOT DiscountCards.DeletionMark OR &qSearchMarkedForDeletion)
	|	AND (DiscountCards.Identifier = &qIdentifier OR DiscountCards.Phone = &qIdentifier)
	|
	|ORDER BY
	|	DiscountCards.Code";
	vQry.SetParameter("qIdentifier", TrimAll(pIdentifier));
	vQry.SetParameter("qSearchMarkedForDeletion", pSearchMarkedForDeletion);
	vDiscountCards = vQry.Execute().Unload();
	If vDiscountCards.Count() > 0 Then
		vDiscountCardRef = vDiscountCards.Get(0).Ref;
	EndIf;
	Return vDiscountCardRef;
EndFunction // cmGetDiscountCardById

// -----------------------------------------------------------------------------
// Description: Function tries to find and return discount card by phone
// Parameters: phone number
// Return value: Discount card reference or empty reference
// -----------------------------------------------------------------------------
Function cmGetDiscountCardByPhone(pPhone, pSearchMarkedForDeletion = False) Export
	vDiscountCardRef = Catalogs.DiscountCards.EmptyRef();
	// Try to find discount card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	(NOT DiscountCards.DeletionMark OR &qSearchMarkedForDeletion)
	|	AND DiscountCards.Phone = &qPhone
	|
	|ORDER BY
	|	DiscountCards.Code";
	vQry.SetParameter("qPhone", TrimAll(pPhone));
	vQry.SetParameter("qSearchMarkedForDeletion", pSearchMarkedForDeletion);
	vDiscountCards = vQry.Execute().Unload();
	If vDiscountCards.Count() > 0 Then
		vDiscountCardRef = vDiscountCards.Get(0).Ref;
	EndIf;
	Return vDiscountCardRef;
EndFunction // cmGetDiscountCardByPhone

// -----------------------------------------------------------------------------
// Description: Function tries to find and return discount card for the client
// Parameters: Client ref
// Return value: Discount card reference or empty reference
// -----------------------------------------------------------------------------
Function cmGetDiscountCardByClient(pClient) Export
	vDiscountCardRef = Catalogs.DiscountCards.EmptyRef();
	// Try to find discount card by client
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	NOT DiscountCards.DeletionMark
	|	AND DiscountCards.Client = &qClient
	|	AND NOT ISNULL(DiscountCards.DiscountType.IsManualDiscount, FALSE)
	|
	|ORDER BY
	|	DiscountCards.Code DESC";
	vQry.SetParameter("qClient", pClient);
	vDiscountCards = vQry.Execute().Unload();
	If vDiscountCards.Count() > 0 Then
		vDiscountCardRef = vDiscountCards.Get(0).Ref;
	EndIf;
	Return vDiscountCardRef;
EndFunction // cmGetDiscountCardById

// -----------------------------------------------------------------------------
// Description: Rounds amount according to the number of decimal digits and type
//              pRoundDigits = -1: 24 -> 30; 29 -> 30; -33 -> -30; -37 -> -30
//              pRoundDigits =  1: 2.43 -> 2.50; 2.49 -> 2.50; -3.33 -> -3.30; -3.37 -> -3.30
// -----------------------------------------------------------------------------
Function cmRoundDiscountAmount(pAmount, pRoundDigits, pRoundType = Undefined) Export
	vAmount = pAmount;
	If pRoundType = Enums.DiscountAmountRoundTypes.EmptyRef() Then
		vAmount = cmRoundUp(pAmount, pRoundDigits);
	ElsIf pRoundType <> Undefined Then
		If pRoundType = Enums.DiscountAmountRoundTypes.Up Then
			vAmount = cmRoundUp(pAmount, pRoundDigits);
		ElsIf pRoundType = Enums.DiscountAmountRoundTypes.Down Then
			vAmount = cmRoundDown(pAmount, pRoundDigits);
		Else
			vAmount = Round(pAmount, pRoundDigits);
		EndIf;
	EndIf;
	Return vAmount;
EndFunction // cmRoundDiscountAmount
