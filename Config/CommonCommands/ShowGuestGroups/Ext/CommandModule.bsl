#Region EventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	If amPersistentObjects.Property("IsLockApplication") Then
		If amPersistentObjects.IsLockApplication Then
			Return;	
		EndIf;	
	EndIf;
	#IF MobileClient THEN 
		OpenForm("Catalog.GuestGroups.Form.mcListForm", New Structure("ShowRooms", True), pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
	#ELSE
		OpenForm("Catalog.GuestGroups.Form.tcListForm", New Structure("ShowRooms", True), pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
	#ENDIF
EndProcedure // CommandProcessing

#EndRegion
