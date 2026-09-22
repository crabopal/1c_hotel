		
#Region FormEventHandlers
// ----------------------------------------------------------------------------- 
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
  Items.FormAdd.Visible = tcOnServer.cmIsInRole("Administrator");
EndProcedure

#EndRegion
		
 #Region FormTableItemsEventHandlers
 
// ----------------------------------------------------------------------------- 
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		vRow.Value.Data.Description = cmNStr(vRow.Value.Data.Description, SessionParameters.CurrentLanguage);
	EndDo;
EndProcedure
 
#EndRegion
 
#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Add(Command)
	OpenForm("Catalog.ExternalDataProcessors.ObjectForm",,ThisObject.UUID,,,, New NotifyDescription("AfterCreateDataprocessor", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
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
 

