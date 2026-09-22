
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If Not ValueIsFilled(Object.Ref) Then
		If Not ValueIsFilled(Object.Client) Then
			vObj = FormAttributeToValue("Object");
			vObj.pmFillAttributesWithDefaultValues();
			ValueToFormAttribute(vObj, "Object");
		EndIf;
	Else
		If Object.IsProcessed Then
			ReadOnly = True;
		EndIf;
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

#EndRegion
