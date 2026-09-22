
#Region Public

// -----------------------------------------------------------------------------
Function GetCreditCardsProcessingSystemConnectionParameters(pCreditCardsProcessingSystemParameters) Export
	If TypeOf(pCreditCardsProcessingSystemParameters.ConnectionParameters) = Type("ValueStorage") Then 
		Return pCreditCardsProcessingSystemParameters.ConnectionParameters.Get();
	Else
		Return pCreditCardsProcessingSystemParameters.ConnectionParameters;	
	EndIf;
EndFunction // GetCreditCardsProcessingSystemConnectionParameters

// -----------------------------------------------------------------------------
Procedure SetCreditCardsProcessingSystemConnectionParameters(pCreditCardsProcessingSystemParameters, pConnParameters) Export 
	If pCreditCardsProcessingSystemParameters <> Undefined Then
		vObj = pCreditCardsProcessingSystemParameters.GetObject();
		vObj.ConnectionParameters = New ValueStorage(pConnParameters);
		vObj.Write();
	EndIf;	
EndProcedure // SetCreditCardsProcessingSystemConnectionParameters

// -----------------------------------------------------------------------------
Function GetTotalPreauthorizationAmountByTransactionID(pTransactionID) Export 
	vAmount  = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(Preauthorisation.Sum) AS Sum
	|FROM
	|	Document.Preauthorisation AS Preauthorisation
	|WHERE
	|	Preauthorisation.Posted
	|	AND Preauthorisation.Status = &qStatus
	|	AND Preauthorisation.TransactionID = &qTransactionID";
	vQry.SetParameter("qStatus", Enums.PreauthorisationStatuses.Authorised);
	vQry.SetParameter("qTransactionID", TrimAll(pTransactionID));
	vTotals = vQry.Execute().Unload();
	If vTotals.Count() > 0 Then
		vAmount = vTotals.Total("Sum");
	EndIf;
	Return vAmount;
EndFunction // GetTotalPreauthorizationAmountByTransactionID

// -------------------------------------------------------------------------
Function GetCreditCardType(pCardName, pCardType = "") Export
	vType = Catalogs.CreditCardTypes.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CardTypes.Ref AS Ref,
	|	CardTypes.SortCode AS SortCode,
	|	CardTypes.Code AS Code
	|FROM
	|	(SELECT
	|		CreditCardTypes.Ref AS Ref,
	|		CreditCardTypes.SortCode AS SortCode,
	|		CreditCardTypes.Code AS Code
	|	FROM
	|		Catalog.CreditCardTypes AS CreditCardTypes
	|	WHERE
	|		(&qCardNameIsFilled
	|					AND (CreditCardTypes.Code = &qCardName
	|						OR CreditCardTypes.Description = &qCardName)
	|				OR &qCardTypeIsFilled
	|					AND (CreditCardTypes.Code = &qCardType
	|						OR CreditCardTypes.Description = &qCardType))
	|		AND NOT CreditCardTypes.DeletionMark
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CreditCardTypeSynonyms.Ref,
	|		CreditCardTypeSynonyms.Ref.SortCode,
	|		CreditCardTypeSynonyms.Ref.Code
	|	FROM
	|		Catalog.CreditCardTypes.Synonyms AS CreditCardTypeSynonyms
	|	WHERE
	|		(&qCardNameIsFilled
	|					AND CreditCardTypeSynonyms.Synonym = &qCardName
	|				OR &qCardTypeIsFilled
	|					AND CreditCardTypeSynonyms.Synonym = &qCardType)
	|		AND NOT CreditCardTypeSynonyms.Ref.DeletionMark) AS CardTypes
	|
	|GROUP BY
	|	CardTypes.Ref,
	|	CardTypes.SortCode,
	|	CardTypes.Code
	|
	|ORDER BY
	|	CardTypes.SortCode,
	|	CardTypes.Code";
	vQry.SetParameter("qCardName", pCardName);
	vQry.SetParameter("qCardNameIsFilled", Not IsBlankString(pCardName));
	vQry.SetParameter("qCardType", pCardType);
	vQry.SetParameter("qCardTypeIsFilled", Not IsBlankString(pCardType));
	vTypes = vQry.Execute().Unload();
	For Each vTypesRow In vTypes Do
		vType = vTypesRow.Ref;
		Break;
	EndDo;
	Return vType;
EndFunction // GetCreditCardType

// -----------------------------------------------------------------------------
Function GetDateFromString(pStr, pFormat = "") Export  
	If StrLen(pStr) = 4 Then
		Try
			If pFormat <> "yyMM" Then
				Return BegOfMonth(Date(2000 + Number(Right(pStr, 2)), Number(Left(pStr, 2)), 01));
			Else
				Return BegOfMonth(Date(2000 + Number(Left(pStr, 2)), Number(Right(pStr, 2)), 01));	
			EndIf;
		Except
			Return BegOfMonth(Date(2000 + Number(Left(pStr, 2)), Number(Right(pStr, 2)), 01));
		EndTry;
	Else
		Return '00010101';
	EndIf;
EndFunction // GetDateFromString

// -----------------------------------------------------------------------------
Function SaveCreditCardData(pOutParams, Val pObj) Export
	vCardNumber = GetCardNumber(pOutParams);
	vCardEncData = GetCardEncData(pOutParams);
	vCardRef = Undefined;
	If ValueIsFilled(vCardEncData) Then
		vCardRef = Catalogs.CreditCards.FindByAttribute("CardDataEnc", vCardEncData);
		If ValueIsFilled(vCardRef) And vCardRef.DeletionMark Then
			vCardRef = Undefined;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vCardRef) Then
		vCardObj = Catalogs.CreditCards.CreateItem();
		vMaskedCardNumber =  GetMaskedCardNumber(pOutParams);
		If IsBlankString(vMaskedCardNumber) Then
			vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
		Else
			vCardObj.Description = vMaskedCardNumber;
		EndIf;
		vCardObj.CardOwner = GetCardOwner(pObj);
		vCardObj.CardType = GetCardType(pOutParams);
		vCardObj.CardNumber = vCardNumber;
		vCardObj.CardHolder = GetCardHolder(pOutParams);
		vCardObj.CardValidTillDate = GetCardExpDate(pOutParams);
		vCardObj.CardDataEnc = vCardEncData;
		vCardObj.Author = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		vCardObj.CreateDate = tcOnServer.cmGetServerCurrentSessionDate();
		vCardObj.Write();
		vCardRef = vCardObj.Ref;
	Else
		vCardType = GetCardType(pOutParams);
		If ValueIsFilled(vCardType) And Not ValueIsFilled(vCardRef.CardType) Then
			vCardObj = vCardRef.GetObject();
			vCardObj.CardType = vCardType;
			vCardObj.Write();
		EndIf;
	EndIf;
	Return vCardRef;
EndFunction // SaveCreditCardData

// -----------------------------------------------------------------------------
Function SaveCreditCardDataUCS(pCardNumber, Val pObj) Export
	vCardNumber = TrimAll(pCardNumber);
	vCardRef = Undefined;
	If Not IsBlankString(vCardNumber) Then
		vCardRef = Catalogs.CreditCards.FindByAttribute("CardNumber", vCardNumber);
		If ValueIsFilled(vCardRef) And vCardRef.DeletionMark Then
			vCardRef = Undefined;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vCardRef) Then
		vCardObj = Catalogs.CreditCards.CreateItem();
		vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
		vCardObj.CardOwner = GetCardOwner(pObj);
		vCardObj.CardNumber = vCardNumber;
		vCardObj.CardDataEnc = vCardNumber;
		vCardObj.Author = SessionParameters.CurrentUser;
		vCardObj.CreateDate = CurrentSessionDate();
		vCardObj.Write();
		vCardRef = vCardObj.Ref;
	EndIf;
	Return vCardRef;
EndFunction // SaveCreditCardData

// -----------------------------------------------------------------------------
Function SaveCreditCardDataByCardNumber(Val pCardNumber, Val pObj, pExtraParams = Undefined) Export
	vCardRef = Undefined;
	vCardNumber = TrimAll(pCardNumber);
	vCardOwner = GetCardOwner(pObj);
	
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	CreditCards.Ref AS Ref
	|FROM
	|	Catalog.CreditCards AS CreditCards
	|WHERE
	|	NOT CreditCards.DeletionMark
	|	AND CreditCards.CardNumber = &qCardNumber
	|	AND CreditCards.CardOwner = &qCardOwner";
	vQ.SetParameter("qCardNumber", vCardNumber);
	vQ.SetParameter("qCardOwner", vCardOwner);
	vSelect = vQ.Execute().Select();
	
	If vSelect.Next() Then
		vCardRef = vSelect.Ref;
	EndIf;
	
	If Not ValueIsFilled(vCardRef) Then
		vCardObj = Catalogs.CreditCards.CreateItem();
		vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
		vCardObj.CardOwner = vCardOwner;
		vCardObj.CardNumber = vCardNumber;
		vCardObj.Author = SessionParameters.CurrentUser;
		vCardObj.CreateDate = CurrentSessionDate();
		
		If pExtraParams <> Undefined Then
			For Each vExtraParamRow In pExtraParams Do
				vCardObj[vExtraParamRow.Key] = vExtraParamRow.Value;
			EndDo;
		EndIf;
		
		vCardObj.Write();
		vCardRef = vCardObj.Ref;
	EndIf;
	Return vCardRef;
EndFunction // SaveCreditCardData

// -----------------------------------------------------------------------------
Function FormatSum(pSum, pPaymentCurrency) Export 
	Return cmFormatSum(pSum, pPaymentCurrency);	
EndFunction // FormatSum

// -----------------------------------------------------------------------------
Function GetCardType(pOutParams) Export
	vCardTypeRef = Catalogs.CreditCardTypes.EmptyRef();
	vCardType = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "IssuerName=");
		If vPos > 0 Then
			vCardType = TrimAll(Mid(vTxtLine, vPos + 11));
			Break;
		EndIf;
	EndDo;
	If Not IsBlankString(vCardType) Then
		vCardTypeRef = GetCreditCardType(vCardType);
	EndIf;
	Return vCardTypeRef;
EndFunction // GetCardType

#EndRegion

#Region Internal

// -----------------------------------------------------------------------------
Function GetCreditCardRef(Val pObj, pCardNumber = "", pMaskedCardNumber = "", pCardDataEnc = "", pCardTypeCode = "",
						  pCardValidTillDate = '00010101', pCardHolder = "", pCardSecurityCode = "", pCardIssuer = "") Export
	vCreditCardRef = Catalogs.CreditCards.EmptyRef();
	If ValueIsFilled(pCardDataEnc) Then
		vCreditCardRef = GetCreditCardRefByCardDataEnc(pCardDataEnc);		
		If Not ValueIsFilled(vCreditCardRef) Then
			vCreditCardObj = Catalogs.CreditCards.CreateItem();
			If ValueIsFilled(pCardNumber) Or ValueIsFilled(pMaskedCardNumber) Then
				If ValueIsFilled(pMaskedCardNumber) Then  
					vCreditCardObj.Description = pMaskedCardNumber;
				Else
					vCreditCardObj.Description = cmGetCreditCardDescription(pCardNumber);
				EndIf;
			Else
				vCreditCardObj.Description = pCardDataEnc;	
			EndIf;
			vCreditCardObj.CardOwner = GetCardOwner(pObj);
			If ValueIsFilled(pCardTypeCode) Then
				vCreditCardObj.CardType = GetCreditCardType(pCardTypeCode);
			EndIf;
			vCreditCardObj.CardNumber = pCardNumber;
			vCreditCardObj.CardHolder = pCardHolder;
			vCreditCardObj.CardValidTillDate = pCardValidTillDate;
			vCreditCardObj.CardDataEnc = pCardDataEnc;
			vCreditCardObj.CardSecurityCode = pCardSecurityCode;
			vCreditCardObj.CardIssuer = pCardIssuer;
			vCreditCardObj.Author = SessionParameters.CurrentUser;
			vCreditCardObj.CreateDate = CurrentSessionDate();
			vCreditCardObj.Write();
			vCreditCardRef = vCreditCardObj.Ref;
		Else
			If ValueIsFilled(pCardTypeCode) And Not ValueIsFilled(vCreditCardRef.CardType) Then
				vCardType = GetCreditCardType(pCardTypeCode);
				If ValueIsFilled(vCardType) Then
					vCreditCardObj = vCreditCardRef.GetObject();
					vCreditCardObj.CardType = vCardType;
					vCreditCardObj.Write();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vCreditCardRef;
EndFunction // GetCreditCardRef

// -----------------------------------------------------------------------------
Function GetCreditCardRefByCardDataEnc(pCardDataEnc)
	vCreditCardRef = Catalogs.CreditCards.EmptyRef();
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	CreditCards.Ref AS Ref
	|FROM
	|	Catalog.CreditCards AS CreditCards
	|WHERE
	|	NOT CreditCards.DeletionMark
	|	AND CreditCards.CardDataEnc = &qCardDataEnc";
	vQ.SetParameter("qCardDataEnc", pCardDataEnc);
	vResult = vQ.Execute().Unload();
	If vResult.Count() > 0 Then
		vCreditCardRef = vResult[0].Ref; 
	EndIf;
	Return vCreditCardRef;
EndFunction // GetCreditCardRefByCardDataEnc

// -----------------------------------------------------------------------------
Function GetCardExpDate(pOutParams)
	vCardExpDateStr = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "ExpDate=");
		If vPos > 0 Then
			vCardExpDateStr = TrimAll(Mid(vTxtLine, vPos + 8));
			Break;
		EndIf;
	EndDo;
	Return GetDateFromString(vCardExpDateStr);
EndFunction // GetCardExpDate

// -----------------------------------------------------------------------------
Function GetCardHolder(pOutParams)
	vCardHolder = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "Cardholder=");
		If vPos > 0 Then
			vCardHolder = TrimAll(Mid(vTxtLine, vPos + 11));
			Break;
		EndIf;
	EndDo;
	Return vCardHolder;
EndFunction // GetCardHolder

// -----------------------------------------------------------------------------
Function GetCardOwner(Val pObj)
	vCardOwner = Undefined;
	If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or 
	   TypeOf(pObj.Ref) = Type("DocumentRef.Return") Or 
	   TypeOf(pObj.Ref) = Type("DocumentRef.Preauthorisation") Then
		vCardOwner = pObj.Payer;
	ElsIf TypeOf(pObj.Ref) = Type("DocumentRef.CustomerPayment") Then 
		vCardOwner = pObj.AccountingCustomer;
	EndIf;
	Return vCardOwner;
EndFunction // GetCardOwner

// -----------------------------------------------------------------------------
Function GetMaskedCardNumber(pOutParams)
	vCardNumber = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "PANhide=");
		If vPos > 0 Then
			vCardNumber = TrimAll(Mid(vTxtLine, vPos + 8));
			Break;
		EndIf;
	EndDo;
	Return vCardNumber;
EndFunction // GetMaskedCardNumber

// -----------------------------------------------------------------------------
Function GetCardEncData(pOutParams)
	vCardEncData = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "CardDataEnc=");
		If vPos > 0 Then
			vCardEncData = TrimAll(Mid(vTxtLine, vPos + 12));
			Break;
		EndIf;
	EndDo;
	Return vCardEncData;
EndFunction // GetCardEncData

// -----------------------------------------------------------------------------
Function GetCardNumber(pOutParams)
	vCardNumber = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "PAN=");
		If vPos > 0 Then
			vCardNumber = TrimAll(Mid(vTxtLine, vPos + 4));
			Break;
		EndIf;
	EndDo;
	Return vCardNumber;
EndFunction // GetCardNumber

#EndRegion
