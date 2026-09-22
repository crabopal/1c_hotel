
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If AdditionalProperties.Property("CheckedAttributes") Then
		For Each vId In AdditionalProperties.CheckedAttributes Do
			CheckedAttributes.Add(vId);       
		EndDo;	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	If Not IsFolder Then
		ExternalCode = ""; 
		BarCode = "";
	EndIf;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

#EndRegion

#Region Public

// See Catalogs.Services. ------------------------------------------------------
Function pmGetServiceDescription(pLang, pUseGroupByDescription = False) Export
	Return Catalogs.Services.pmGetServiceDescription(Ref, pLang, pUseGroupByDescription = False);
EndFunction // pmGetServiceDescription

// See Catalogs.Services. ------------------------------------------------------
Function pmGetServiceUnitDescription(pLang) Export
	Return Catalogs.Services.pmGetServiceUnitDescription(Ref, pLang);
EndFunction // pmGetServiceUnitDescription

// See Catalogs.Services. ------------------------------------------------------
Function pmGetServiceQuantityPresentation(pQuantity, pLang) Export
	Return Catalogs.Services.pmGetServiceQuantityPresentation(Ref, pQuantity, pLang);
EndFunction // pmGetServiceQuantityPresentation	

// -----------------------------------------------------------------------------
Function pmGetServicePrices(pHotel, pDate = Undefined, pClientType = Undefined) Export
	Return cmGetServicePrice(Ref, pHotel, pDate, pClientType);
EndFunction // pmGetServicePrices

// See Catalogs.Services. ------------------------------------------------------
// Get service characteristics
// Returns ValueTable 
// -----------------------------------------------------------------------------
Function pmGetServiceCharacteristics() Export
	Return Catalogs.Services.pmGetServiceCharacteristics(Ref);
EndFunction // pmGetServiceCharacteristics

// See Catalogs.Services. ------------------------------------------------------
// Get service characteristic value
// Returns Value
// -----------------------------------------------------------------------------
Function pmGetServiceCharacteristicValue(pServiceCharacteristic) Export
	Return Catalogs.Services.pmGetServiceCharacteristicValue(Ref, pServiceCharacteristic);
EndFunction // pmGetServiceCharacteristicValue

// See Catalogs.Services. ------------------------------------------------------
Procedure pmSaveServiceCharacteristicValue(pServiceCharacteristic, pServiceCharacteristicValue) Export  
	Catalogs.Services.pmSaveServiceCharacteristicValue(Ref, pServiceCharacteristic, pServiceCharacteristicValue);
EndProcedure // pmSaveServiceCharacteristicValue

#EndRegion
