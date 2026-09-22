
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite   

#EndRegion

#Region Public

// See Catalogs.PaymentMethods. ---------------------------------------------------
Function pmGetPaymentMethodDescription(pLang) Export
	Return Catalogs.PaymentMethods.pmGetPaymentMethodDescription(Ref, pLang);
EndFunction // pmGetPaymentMethodDescription

#EndRegion
