
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
	ElsIf Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pLang	 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Description
//
Function pmGetAccommodationTypeDescription(pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(Description);
	Else
		If IsBlankString(DescriptionTranslations) Then
			vDescr = TrimAll(Description);
		Else
			vDescr = TrimAll(cmNStr(DescriptionTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetAccommodationTypeDescription

// -----------------------------------------------------------------------------
//
// Parameters:
//  pMessage		 - String	 - Messages
//  pAttributeInErr	 - String	 - Attribute with errors
// 
// Returns:
//  Boolean - Has errors
//
Function pmCheckAccommodationTypeAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	// Create query object	
	vQuery = New Query();		
	vQuery.Text = "SELECT
	|	AccommodationTypes.SortCode AS Counter
	|FROM
	|	Catalog.AccommodationTypes AS AccommodationTypes
	|WHERE
	|	AccommodationTypes.Ref <> &qRef
	|	AND AccommodationTypes.SortCode = &qSortCode";
	vQuery.SetParameter("qRef", Ref);
	vQuery.SetParameter("qSortCode", SortCode);
	vQryRes = vQuery.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vHasErrors = True; 
        vMsgTextRu = vMsgTextRu + "Реквизит <Порядок сортировки> не уникален! Укажите другой код." + Chars.LF;
        vMsgTextEn = vMsgTextEn + "<Sort code> attribute is not unique! Please, enter another code." + Chars.LF;
        vMsgTextDe = vMsgTextDe + "<Sort code> Attribut ist nicht einzigartig! Bitte geben Sie einen anderen Code." + Chars.LF;
        pAttributeInErr = "SortCode";
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckAccommodationTypeAttributes

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Sort code
//
Function pmSetSortCode() Export
	vSortCode = 0;
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	MAX(AccommodationTypes.SortCode) AS SortCode
	|FROM
	|	Catalog.AccommodationTypes AS AccommodationTypes";
	vQueryResult = vQuery.Execute().Unload();
	If vQueryResult.Count() > 0 Then
		vResRow = vQueryResult.Get(0);
		If cmIsNumber(vResRow.SortCode) Then
			vSortCode = vResRow.SortCode + 10;
		Else
			vSortCode = 10;
		EndIf;
	EndIf;
	Return vSortCode;
EndFunction // pmSetSortCode

#EndRegion

