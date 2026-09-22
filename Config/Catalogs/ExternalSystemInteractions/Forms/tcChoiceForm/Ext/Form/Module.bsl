
#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Add(Command)
	OpenForm("Catalog.ExternalSystemInteractions.ObjectForm", , UUID, , , , New NotifyDescription("AfterCreateDataprocessor", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  Result				 - Boolean	 - Result 
//  AdditionalParameters - Structure - Additional properties  
//
&AtClient
Procedure AfterCreateDataprocessor(Result, AdditionalParameters) Export
	Items.List.Refresh();	
EndProcedure

#EndRegion
