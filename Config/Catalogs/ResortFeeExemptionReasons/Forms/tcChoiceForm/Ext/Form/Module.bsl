#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check parameters
	SelIsForTouristTax = False;
	If Parameters.Property("SelIsForTouristTax") And TypeOf(Parameters.SelIsForTouristTax) = Type("Boolean") Then
		SelIsForTouristTax = Parameters.SelIsForTouristTax;
	Else
		vIsForTouristTax = SystemSettingsStorage.Load("ResortFeeExemptionReasons", "IsForTouristTax", "", TrimAll(SessionParameters.CurrentUser));
		If vIsForTouristTax <> Undefined Then
			SelIsForTouristTax = vIsForTouristTax;
		EndIf;
	EndIf;
	SelIsForTouristTaxOnChangeAtServer(True);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure SelIsForTouristTaxOnChangeAtServer(pDoNotSaveSettings = False)
	Items.FormShowTouristTaxItems.Check = SelIsForTouristTax;
	Items.FormShowResortFeeItems.Check = Not SelIsForTouristTax;
	AttributeChangeAtServer("IsForTouristTax", SelIsForTouristTax);
	If Not pDoNotSaveSettings Then
		SystemSettingsStorage.Save("ResortFeeExemptionReasons", "IsForTouristTax", SelIsForTouristTax, "", TrimAll(SessionParameters.CurrentUser));
	EndIf;
EndProcedure // SelIsForTouristTaxOnChangeAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowResortFeeItems(pCommand)
	SelIsForTouristTax = False;
	SelIsForTouristTaxOnChangeAtServer();
EndProcedure // ShowResortFeeItems

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowTouristTaxItems(pCommand)
	SelIsForTouristTax = True;
	SelIsForTouristTaxOnChangeAtServer();
EndProcedure // ShowTouristTaxItems

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, pValue, vComparisonType, , True);
EndProcedure // AttributeChangeAtServer
 
#EndRegion