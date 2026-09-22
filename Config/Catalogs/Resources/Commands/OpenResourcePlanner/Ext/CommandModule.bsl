
#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	#IF NOT MobileClient THEN 
		OpenForm("Catalog.Resources.Form.tcResourcesCalendar");
	#ELSE
		OpenForm("Catalog.Resources.Form.mcResourcesCalendar");	
	#ENDIF
EndProcedure

#EndRegion

