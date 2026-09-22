
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCompany		 - CatalogRef.Companies	 - Ref
//  pAccountCurrency - CatalogRef.Currencies - Ref
// 
// Returns:
//  ValueTable - List bank accounts
//
Function pmGetCompanyBankAccounts(pCompany, pAccountCurrency, pHotel = Undefined) Export
	vQry = New Query();
	 
	vQry.Text =	"SELECT
	           	|	BankAccounts.Ref AS BankAccount
	           	|FROM
	           	|	Catalog.BankAccounts AS BankAccounts
	           	|WHERE
	           	|	NOT BankAccounts.DeletionMark
	           	|	AND BankAccounts.Owner = &qOwner
	           	|	AND (&qHotelIsEmpty
	           	|			OR (BankAccounts.Hotel = &qHotel
	           	|				OR BankAccounts.Hotel = VALUE(Catalog.Hotels.EmptyRef)))
	           	|	AND BankAccounts.AccountCurrency = &qAccountCurrency
	           	|
	           	|ORDER BY
	           	|	BankAccounts.Code,
	           	|	BankAccounts.Hotel DESC";
	vQry.SetParameter("qOwner", pCompany);   
	vQry.SetParameter("qHotel", pHotel); 
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qAccountCurrency", pAccountCurrency);
	vAccounts = vQry.Execute().Unload();
	Return vAccounts;
EndFunction // pmGetCompanyBankAccounts

// -----------------------------------------------------------------------------
Function pmGetCompanyIdentificationCodes(pCompany, pLanguage) Export
	vCodes = "";
	If Not IsBlankString(pCompany.KPP) Then
		vCodes = cmNStr("en='Reg. N '; ru='ИНН '; de='Reg. Nr. '") + TrimAll(pCompany.TIN) + "/" + TrimAll(pCompany.KPP);
	ElsIf Not IsBlankString(pCompany.TIN) Then
		If Not IsBlankString(pCompany.VATC) Then
			vCodes = cmNStr("en='TIC '; ru='ИНН '; de='TIC '") + TrimAll(pCompany.TIN) + ", " +
			         cmNStr("en='VAT '; ru='НДС '; de='Mw.St. '") + TrimAll(pCompany.VATC);
		Else
			vCodes = cmNStr("en='Reg. N '; ru='ИНН '; de='Reg. Nr. '") + TrimAll(pCompany.TIN);
		EndIf;
	EndIf;
	Return vCodes;
EndFunction // pmGetCompanyIdentificationCodes

// -----------------------------------------------------------------------------
Function pmGetCompanyPostAddressPresentation(pCompany, pLang) Export
	If Not ValueIsFilled(pLang) Then
		Return cmGetAddressPresentation(pCompany.PostAddress);
	EndIf;
	If IsBlankString(pCompany.PostAddressTranslations) Then
		Return cmGetAddressPresentation(pCompany.PostAddress);
	EndIf;
	Return cmGetAddressPresentation(cmNStr(pCompany.PostAddressTranslations, pLang));
EndFunction // pmGetCompanyPostAddressPresentation        

// -----------------------------------------------------------------------------
Function pmGetCompanyLegacyAddressPresentation(pCompany, pLang) Export
	If Not ValueIsFilled(pLang) Then
		Return cmGetAddressPresentation(pCompany.LegacyAddress);
	EndIf;
	If IsBlankString(pCompany.LegacyAddressTranslations) Then
		Return cmGetAddressPresentation(pCompany.LegacyAddress);
	EndIf;
	Return cmGetAddressPresentation(cmNStr(pCompany.LegacyAddressTranslations, pLang));
EndFunction // pmGetCompanyLegacyAddressPresentation

// -----------------------------------------------------------------------------
Function pmGetCompanyPrintName(pCompany, pLang) Export
	If Not ValueIsFilled(pLang) Then
		Return TrimAll(pCompany.LegacyName);
	EndIf;
	If IsBlankString(pCompany.PrintNameTranslations) Then
		Return TrimAll(pCompany.LegacyName);
	EndIf;
	Return TrimAll(cmNStr(pCompany.PrintNameTranslations, pLang));
EndFunction // pmGetCompanyPrintName

#EndRegion
