
#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FormExecute(pCommand)
	FormExecuteAtServer();
EndProcedure // FormExecute

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FormExecuteAtServer()
	vObject = FormAttributeToValue("Object");
	vObject.pmExecute();
	ValueToFormAttribute(vObject, "Object");
EndProcedure // FormExecuteAtServer

#EndRegion
