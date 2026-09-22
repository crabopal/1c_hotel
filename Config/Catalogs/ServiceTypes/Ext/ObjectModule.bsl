
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		pCancel = True; 
		vMsg = NStr("en = 'You do not have rights for services and prices management! (094)'; 
					|de = 'Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten! (094)'; 
					|ru = 'Нет прав на управление услугами и ценами! (094)'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
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
Function pmGetServiceTypeDescription(pLang) Export
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
EndFunction // pmGetServiceTypeDescription

#EndRegion
