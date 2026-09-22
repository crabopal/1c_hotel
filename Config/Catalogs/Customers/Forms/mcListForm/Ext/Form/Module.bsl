
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vChoiceMode = False;
	If Parameters.Property("ChoiceMode", vChoiceMode) Then
		Items.List.ChoiceMode = vChoiceMode;
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(Command)
	vRef = Items.List.CurrentRow;
	If Not vRef = Undefined Then
		vParametersStructure = New Structure("ObjectRef", vRef);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisObject, UUID);
	EndIf;
EndProcedure // OpenFolios

#EndRegion
