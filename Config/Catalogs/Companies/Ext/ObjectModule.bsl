
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	ExternalCode = "";
	CloseOfPeriodJobUUID = "";
EndProcedure // OnCopy

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmCheckCompanyAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	If IsBlankString(Code) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Код> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Code> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Code", pAttributeInErr);
	EndIf;
	If IsBlankString(Description) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Наименование> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Description> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Description", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(LegacyName) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Официальное название> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Legacy name> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "LegacyName", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(LegacyAddress) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Юридический адрес> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Legacy address> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "LegacyAddress", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(VATRate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Ставка НДС> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<VAT Rate> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "VATRate", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckCompanyAttributes

// Not use, see Catalogs.Companies. --------------------------------------------
Function pmGetCompanyPrintName(pLang) Export
	Return Catalogs.Companies.pmGetCompanyPrintName(Ref, pLang)
EndFunction // pmGetCompanyPrintName

// Not use, see Catalogs.Companies. --------------------------------------------
Function pmGetCompanyLegacyAddressPresentation(pLang) Export
	Return Catalogs.Companies.pmGetCompanyLegacyAddressPresentation(Ref, pLang)
EndFunction // pmGetCompanyLegacyAddressPresentation

// Not use, see Catalogs.Companies. --------------------------------------------
Function pmGetCompanyPostAddressPresentation(pLang) Export
	Return Catalogs.Companies.pmGetCompanyPostAddressPresentation(Ref, pLang);
EndFunction // pmGetCompanyPostAddressPresentation

// Not use, see Catalogs.Companies.Companies. ----------------------------------
Function pmGetCompanyIdentificationCodes(pLanguage) Export
	Return Catalogs.Companies.pmGetCompanyIdentificationCodes(Ref, pLanguage);
EndFunction // pmGetCompanyIdentificationCodes

// Not use, see Catalogs.Companies. --------------------------------------------
Function pmGetCompanyBankAccounts(pAccountCurrency) Export     
	Return Catalogs.Companies.pmGetCompanyBankAccounts(Ref, pAccountCurrency); 
EndFunction // pmGetCompanyBankAccounts

#EndRegion
