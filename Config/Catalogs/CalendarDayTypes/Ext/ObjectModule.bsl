
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)  
	If DataExchange.Load Then
		Return;
	EndIf;
	
	pCancel = CheckPermissions();
EndProcedure

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	pCancel = CheckPermissions();
EndProcedure

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pLang	 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Item description
//
Function pmGetDayTypeDescription(pLang = Undefined) Export
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
EndFunction // pmGetDayTypeDescription

#EndRegion

#Region Private

Function CheckPermissions()
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
		Return True;
	Else
		Return False;		
	EndIf;
EndFunction

#EndRegion
