
#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListAfterDeleteRow(pItem)
	Notify("RoomProperties.Deleted", , ThisObject);
EndProcedure // ListAfterDeleteRow

#EndRegion
