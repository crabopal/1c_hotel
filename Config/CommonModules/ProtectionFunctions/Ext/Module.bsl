
#Region Public

// -----------------------------------------------------------------------------
Function GetAmComponentName() Export
	#IF CLIENT THEN
		Return amComponentName;
	#ELSE
		Return "";
	#ENDIF
EndFunction // GetAmComponentName

// -----------------------------------------------------------------------------
Function GetAmProtection() Export
	#IF CLIENT THEN
		Return amProtection;
	#ELSE
		Return Undefined;
	#ENDIF
EndFunction // GetAmProtection

// -----------------------------------------------------------------------------
Function GetAmPersistentObjects() Export
	#IF CLIENT THEN
		Return amPersistentObjects;
	#ELSE
		Return New Structure();
	#ENDIF
EndFunction // GetAmPersistentObjects

#EndRegion
