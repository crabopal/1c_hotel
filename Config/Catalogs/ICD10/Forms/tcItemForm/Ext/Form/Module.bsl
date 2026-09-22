
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vObj = FormAttributeToValue("Object");
	If Not ValueIsFilled(vObj.Ref) Then
		vObj.SetNewCode();
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure

#EndRegion        
