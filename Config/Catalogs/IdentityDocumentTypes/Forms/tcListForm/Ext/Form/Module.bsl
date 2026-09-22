
// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInitialListAtServer()
	Catalogs.IdentityDocumentTypes.mmLoadFromDictionary();
EndProcedure // LoadInitialListAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadInitialList(Command)
	LoadInitialListAtServer();                                            
	Items.List.Refresh();
	ShowMessageBox(, NStr("en='Loaded';ru='Загружено';de='Geladen'"));
EndProcedure // LoadInitialList
