
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Object.DataProcessor = Parameters.DataProcessor;
	vObject = FormAttributeToValue("Object");
	cmLoadDataProcessorAttributes(vObject);
	ValueToFormAttribute(vObject, "Object");
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(Command)
	SaveSettingsAtServer();
	Close();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveSettingsAtServer()
	cmSaveDataProcessorAttributes(FormAttributeToValue("Object"));
EndProcedure

#EndRegion
