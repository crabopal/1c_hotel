
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)  
	If DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
Function pmGetDescription(pLang) Export
	Return Catalogs.PaymentSections.pmGetDescription(Ref, pLang);
EndFunction // pmGetDescription

#EndRegion
