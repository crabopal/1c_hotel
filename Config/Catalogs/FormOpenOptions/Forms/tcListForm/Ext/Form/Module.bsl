
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FillMetadata(Command)
	FillMetadataAtServer();
	Items.List.Refresh();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillMetadataAtServer()
	tcOnServer.cmFillFormOpenOptionsMetadata();
EndProcedure

#EndRegion
