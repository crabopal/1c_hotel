#Region EventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	If amPersistentObjects.Property("IsLockApplication") Then
		If amPersistentObjects.IsLockApplication Then
			Return;	
		EndIf;	
	EndIf;
	OpenForm("CommonForm.tcReportsList", , pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window);
EndProcedure // CommandProcessing

#EndRegion
