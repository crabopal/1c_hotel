#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	#IF NOT WebClient THEN
		If amPersistentObjects.Property("IsLockApplication") Then
			If amPersistentObjects.IsLockApplication Then
				Return;	
			EndIf;	
		EndIf;
		amPersistentObjects.Insert("IsLockApplication", True);
		LockApplication();
		amPersistentObjects.Insert("IsLockApplication", False);
	#ENDIF
EndProcedure // CommandProcessing

#EndRegion
