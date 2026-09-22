
#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	If amPersistentObjects.Property("IsLockApplication") Then
		If amPersistentObjects.IsLockApplication Then
			Return;	
		EndIf;	
	EndIf;
	vParams = New Structure("NumberOfRooms", 1);
	#IF MobileClient THEN
		OpenForm("Catalog.Rooms.Form.mcChoiceForm", vParams, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
	#ELSE
		OpenForm("Catalog.Rooms.Form.tcChoiceForm", vParams, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
	#ENDIF
EndProcedure // CommandProcessing

#EndRegion

