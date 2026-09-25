
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vObj = FormAttributeToValue("Object");
	vObj.pmFillAttributesWithDefaultValues();
	ValueToFormAttribute(vObj, "Object");
	
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	vMessage = ActionsExecuteAtServer();
	ShowMessageBox(, vMessage);
EndProcedure // ActionsExecute

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function ActionsExecuteAtServer()
	vObj = FormAttributeToValue("Object");
	vMessage = vObj.pmRun();
	ValueToFormAttribute(vObj, "Object");
	Return vMessage;
EndFunction // ActionsExecuteAtServer

#EndRegion
