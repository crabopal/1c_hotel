
#Region Public

// --------------------------------------------------------------------------------
Function GetActiveDiscountCards(pIdentifier, pDateOfBirth = Undefined, pRequestDate = Undefined) Export
	
	vResult = Undefined;
	
	If NOT ValueIsFilled(pIdentifier) Then
		Return vResult;
	EndIf;
	
	If pRequestDate = Undefined Then
		vRequestDate = CurrentSessionDate();
	Else
		vRequestDate = pRequestDate;
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	DiscountCards.Ref AS Ref,
		|	DiscountCards.Client AS Client
		|FROM
		|	Catalog.DiscountCards AS DiscountCards
		|WHERE
		|	NOT DiscountCards.DeletionMark
		|	AND NOT DiscountCards.IsBlocked
		|	AND (DiscountCards.Identifier = &qIdentifier
		|			OR DiscountCards.Client.Phone = &qIdentifier)
		|	AND CASE
		|			WHEN &qDateOfBirthFilled
		|				THEN DiscountCards.Client.DateOfBirth = &qDateOfBirth
		|			ELSE TRUE
		|		END
		|	AND DiscountCards.ValidFrom >= &qRequestDate
		|	AND DiscountCards.ValidTo <= &qRequestDate
		|
		|ORDER BY
		|	DiscountCards.Code DESC";
	
	vQuery.SetParameter("qDateOfBirth", 		pDateOfBirth);
	vQuery.SetParameter("qDateOfBirthFilled", 	ValueIsFilled(pDateOfBirth));
	vQuery.SetParameter("qIdentifier", 			pIdentifier);
	vQuery.SetParameter("qRequestDate", 		vRequestDate);
	
	vResult = vQuery.Execute().Unload();

	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
Function CreateFolio(pIdentifier, pLoyaltyType, pClient, pCustomer) Export
	vFolioObj = Documents.Folio.CreateDocument();
	vFolioObj.Hotel = SessionParameters.CurrentHotel;
	vFolioObj.pmFillAttributesWithDefaultValues();
	vFolioObj.Description = TrimAll(pIdentifier) + " - " + TrimAll(pLoyaltyType);
	vFolioObj.Client = pClient; 
	vFolioObj.Customer = pCustomer;
	vFolioObj.Write(DocumentWriteMode.Write);
	Return vFolioObj.Ref;
EndFunction // CreateFolio

// --------------------------------------------------------------------------------
Function GetTotalByCard(pCard) Export 
	vVal = "0.00";
    vLoyaltyType = pCard.LoyaltyType;
    vDiscountType  = pCard.DiscountType;
	If Not ValueIsFilled(vDiscountType) Then
		Return vVal;
	EndIf;	
	If vLoyaltyType = Enums.LoyaltyType.Bonuses Or vLoyaltyType = Enums.LoyaltyType.Certificate Then
		vVal = AccumulationRegisters.Bonuses.mmGetBalanceByCard(pCard);
	ElsIf vLoyaltyType = Enums.LoyaltyType.Discount Then 
		If vDiscountType.IsAmountDiscount Then
			vVal = NStr("en = 'Discount amount'; de = 'Rabattbetrag'; ru = 'Суммовая скидка'");
		ElsIf vDiscountType.IsAccumulatingDiscount Then
			If vDiscountType.BonusCalculationFactor = 0 Then
				vVal = "";

				vQuery = New Query;
				vQuery.Text = 
				"SELECT
				|	AccumulatingDiscountsSliceLast.Discount AS Discount
				|FROM
				|	InformationRegister.AccumulatingDiscounts.SliceLast(, DiscountType = &qDiscountType) AS AccumulatingDiscountsSliceLast
				|
				|GROUP BY
				|	AccumulatingDiscountsSliceLast.Discount";
				vQuery.SetParameter("qDiscountType", vDiscountType);
				vQueryResult = vQuery.Execute();
				
				vRes = vQueryResult.Select();
				While vRes.Next() Do
					If vVal = "" Then
						vVal = String(vRes.Discount) + "%";
					Else	
						vVal = vVal + ", " + String(vRes.Discount) + "%";
					EndIf;
				EndDo;
			Else
	        	vVal = NStr("en = 'Balance: '; de = 'Saldo: '; ru = 'Баланс: '");
				
				vBonuses = vDiscountType.GetObject().pmGetAccumulatingDiscountResources(, , , , pCard);
				For Each vBonusesRow In vBonuses Do
					vVal = vVal + Format(?(vBonusesRow.Bonus = Null, 0, vBonusesRow.Bonus), "NFD=2; NZ=0.00");
					Break;
				EndDo;
			EndIf;
		Else 
			vVal = "";

			vQuery = New Query;
			vQuery.Text = 
			"SELECT
			|	DiscountsSliceLast.Discount AS Discount
			|FROM
			|	InformationRegister.Discounts.SliceLast(, DiscountType = &qDiscountType) AS DiscountsSliceLast
			|
			|GROUP BY
			|	DiscountsSliceLast.Discount";
			vQuery.SetParameter("qDiscountType", vDiscountType);
			vQueryResult = vQuery.Execute();
			
			vRes = vQueryResult.Select();
			While vRes.Next() Do
				If vVal = "" Then
					vVal = String(vRes.Discount) + "%";
				Else	
					vVal = vVal + ", " + String(vRes.Discount) + "%";
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vVal;
EndFunction //  GetTotalByCard()

// --------------------------------------------------------------------------------
Function GetActiveBonusesCards(pIdentifier, pRequestDate = Undefined) Export
	
	vResult = Undefined;
	
	If NOT ValueIsFilled(pIdentifier) Then
		Return vResult;
	EndIf;
	
	If pRequestDate = Undefined Then
		vRequestDate = CurrentSessionDate();
	Else
		vRequestDate = pRequestDate;
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	DiscountCards.Ref AS Ref,
		|	DiscountCards.Client AS Client
		|FROM
		|	Catalog.DiscountCards AS DiscountCards
		|WHERE
		|	NOT DiscountCards.DeletionMark
		|	AND NOT DiscountCards.IsBlocked
		|	AND (DiscountCards.Identifier = &qIdentifier
		|			OR DiscountCards.Phone = &qIdentifier
		|			OR DiscountCards.Client.Phone = &qIdentifier)
		|	AND (DiscountCards.ValidTo <= &qRequestDate
		|			OR DiscountCards.ValidTo = DATETIME(1, 1, 1))
		|	AND DiscountCards.LoyaltyType = VALUE(Enum.LoyaltyType.Bonuses)
		|
		|ORDER BY
		|	DiscountCards.Code DESC";
	
	vQuery.SetParameter("qIdentifier", 			pIdentifier);
	vQuery.SetParameter("qRequestDate", 		vRequestDate);
	
	vResult = vQuery.Execute().Unload();

	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
Procedure FormGetProcessing(pFormType, pParameters, pSelectedForm, pAdditionalInformation, pStandardProcessing)
	SetPrivilegedMode(True);
	vCurSession = GetCurrentInfoBaseSession();
	SetPrivilegedMode(False);
	vSessionNumber = vCurSession.SessionNumber;
	vSessionStartTime = vCurSession.SessionStarted;
	vAppRunMode = CachedCommonFunctions.cmGetAppRunMode(vSessionNumber, vSessionStartTime);
	If vAppRunMode.MobileDeviceMode Then 
		If pFormType = "ListForm" Or pSelectedForm = "tcListForm" Then
			pStandardProcessing = False;
			pSelectedForm = "mcListForm";
		ElsIf pFormType = "ObjectForm" Or pSelectedForm = "tcItemForm" Then
          	pStandardProcessing = False;
			pSelectedForm = "mcItemForm";
		EndIf; 
	EndIf;
EndProcedure // FormGetProcessing

// -----------------------------------------------------------------------------
Function GetCardDescription(pCard) Export
	If Not Constants.UseDiscountCardIdentifierAsCardDescription.Get() Then
		vDescription = TrimAll(pCard.Client);
	Else
		vDescription = TrimAll(pCard.Identifier);
	EndIf;
	If ValueIsFilled(pCard.DiscountType) And Not IsBlankString(pCard.DiscountType.DiscountCardDescriptionTemplate) Then
		wDescription = "";
		Try
			wDescription = TrimAll(pCard.DiscountType.DiscountCardDescriptionTemplate);
			While True Do
				vBrPosStart = StrFind(wDescription, "[");
				vBrPosEnd = StrFind(wDescription, "]");
				If vBrPosStart > 0 And vBrPosEnd > 0 And (vBrPosEnd - 1) > vBrPosStart Then
					vAttrName = Mid(wDescription, vBrPosStart + 1, vBrPosEnd - vBrPosStart - 1);
					wDescription = StrReplace(wDescription, "[" + vAttrName + "]", TrimAll(pCard[vAttrName]));
				Else
					Break;
				EndIf;
			EndDo;
		Except
			wDescription = "";
		EndTry;
		If Not IsBlankString(wDescription) Then
			vDescription = wDescription;
		EndIf;
	EndIf;
	Return vDescription;
EndFunction // GetCardDescription

// --------------------------------------------------------------------------------
Function GetBonusesCardByDiscountType(pClient, pDiscountType) Export
	
	vBonusesCard = Undefined;
	
	If NOT ValueIsFilled(pClient) Or NOT ValueIsFilled(pDiscountType) Then
		Return vBonusesCard;
	EndIf;
		
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	DiscountCards.Ref AS Ref
		|FROM
		|	Catalog.DiscountCards AS DiscountCards
		|WHERE
		|	NOT DiscountCards.DeletionMark
		|	AND NOT DiscountCards.IsBlocked
		|	AND DiscountCards.DiscountType = &qDiscountType
		|	AND DiscountCards.Client = &qClient
		|	AND DiscountCards.LoyaltyType = VALUE(Enum.LoyaltyType.Bonuses)
		|
		|ORDER BY
		|	DiscountCards.Code DESC";
	
	vQuery.SetParameter("qClient", 		 pClient);
	vQuery.SetParameter("qDiscountType", pDiscountType);
	
	vResult = vQuery.Execute().Unload();
	
	If vResult.Count() > 0 Then 
		vBonusesCard = vResult[0].Ref; 
	EndIf;

	Return vBonusesCard;
	
EndFunction  

// --------------------------------------------------------------------------------
Function GetDiscountCardByPromoCode(pPromoCode, pCheckInDate = '00010101', pCheckOutDate = '00010101') Export
	vDiscountCard = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref AS DiscountCard,
	|	DiscountCards.Code AS Code
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	DiscountCards.Identifier = &qPromoCode
	|	AND NOT DiscountCards.DeletionMark
	|	AND DiscountCards.DiscountType <> VALUE(Catalog.DiscountTypes.EmptyRef)
	|	AND DiscountCards.ValidFrom <= &qCheckInDate
	|	AND (DiscountCards.ValidTo = &qEmptyDate
	|			OR DiscountCards.ValidTo >= &qCheckOutDate)
	|	AND DiscountCards.DiscountType.DateValidFrom <= &qCheckInDate
	|	AND (DiscountCards.DiscountType.DateValidTo = &qEmptyDate
	|			OR DiscountCards.DiscountType.DateValidTo >= &qCheckOutDate)
	|
	|ORDER BY
	|	Code";
	vQry.SetParameter("qPromoCode", Upper(TrimAll(pPromoCode)));
	vQry.SetParameter("qCheckInDate", BegOfDay(pCheckInDate));
	vQry.SetParameter("qCheckOutDate", BegOfDay(pCheckOutDate));
	vQry.SetParameter("qEmptyDate", '00010101');
	vCards = vQry.Execute().Unload();
	For Each vCardsRow In vCards Do
		vDiscountCard = vCardsRow.DiscountCard;
		Break;
	EndDo;
	Return vDiscountCard;
EndFunction // GetDiscountCardByPromoCode

// -----------------------------------------------------------------------------
Function GetBonusesCardByClient(pClient) Export
	vDiscountCard = Catalogs.DiscountCards.EmptyRef();
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	DiscountCards.Ref AS Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	DiscountCards.Client = &qClient
	|	AND NOT DiscountCards.DeletionMark
	|	AND (DiscountCards.LoyaltyType = VALUE(Enum.LoyaltyType.Bonuses)
	|			OR DiscountCards.LoyaltyType = VALUE(Enum.LoyaltyType.Certificate))
	|
	|ORDER BY
	|	DiscountCards.CreateDate DESC";
	vQuery.SetParameter("qClient", pClient);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		vDiscountCard = vResult.Get(0).Ref;		
	EndIf;
	Return vDiscountCard;
EndFunction // GetBonusesCardByClient

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.CreateHotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
// Function - Get last gift ID
//
// Parameters:
//  pDiscountType	 - CatalogRef.DiscountTypes - Ref
// 
// Returns:
//  Number - Last ID
//
Function GetLastGiftID(pDiscountType) Export  
	vID = 0;	
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	DiscountCards.Identifier AS Identifier,
		|	DiscountCards.CreateDate AS CreateDate
		|FROM
		|	Catalog.DiscountCards AS DiscountCards
		|WHERE
		|	DiscountCards.DiscountType = &qDiscountType
		|	AND DiscountCards.Identifier > """"
		|
		|ORDER BY
		|	CreateDate DESC";
	
	vQuery.SetParameter("qDiscountType", pDiscountType);
	
	vRes = vQuery.Execute();
	
	vSel = vRes.Select();
	
	While vSel.Next() Do
		vID = vSel.Identifier;
	EndDo;
	
	Return vID;	
EndFunction	
	
#EndRegion
