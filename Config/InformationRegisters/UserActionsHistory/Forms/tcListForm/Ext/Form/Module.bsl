
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	 Items.List.Period.Variant = StandardPeriodVariant.Today;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	Items.List.Refresh();
EndProcedure

#EndRegion
