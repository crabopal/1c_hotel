
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Description = StrReplace(Description, ", ", " ");
	Description = StrReplace(Description, ",", " ");
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
Function pmGetCountryDescription(pLang) Export
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
EndFunction // pmGetCountryDescription

#EndRegion
