
#Region FormCommandsEventHandlers

// ---------------------------------------------------------------------------------
&AtClient
Procedure ActionLoadInitialList(Command)
	ActionLoadInitialListAtServer();
	ShowMessageBox(, NStr("en='Loaded';ru='Загружено';de='Geladen'"));
EndProcedure

#EndRegion


#Region Private

// ---------------------------------------------------------------------------------
&AtServer
Procedure ActionLoadInitialListAtServer()
	Catalogs.VisaTypes.mmLoadFromDictionary();
EndProcedure

#EndRegion
