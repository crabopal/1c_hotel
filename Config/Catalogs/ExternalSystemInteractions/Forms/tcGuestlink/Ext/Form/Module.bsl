	
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Items.GroupMinPrice.Enabled = Object.CalcMinPrice;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CalcMinPriceOnChange(pItem)
	Items.GroupMinPrice.Enabled = Object.CalcMinPrice;
EndProcedure

#EndRegion
