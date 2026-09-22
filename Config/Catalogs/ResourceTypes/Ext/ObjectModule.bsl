
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not IsFolder Then
		If Left(TrimAll(Description), StrLen(TrimAll(Code))) <> TrimAll(Code) Then
			Description = TrimAll(Code) + ?(IsBlankString(Description), "", " - " + TrimAll(Description));
		EndIf;
	EndIf;
	
	If Not cmCheckUserPermissions("HavePermissionToManageResources") Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for resources management!';ru='Нет прав на управление ресурсами!';de='Sie haben keine Rechte, Ressourcen zu verwalten!'"));
	ENdIf;	
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Current hotel
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmCheckResourceTypeAttributes(pMessage, pAttributeInErr) Export
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
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckResourceTypeAttributes

// -----------------------------------------------------------------------------
//
// Parameters:
//  pLang	 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Item description
//
Function pmGetResourceTypeDescription(pLang) Export
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
EndFunction // pmGetResourceTypeDescription

#EndRegion
