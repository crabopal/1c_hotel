
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		Items.List.ChangeRowSet = False;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadInitialList(pCommand)
	LoadInitialListAtServer();
	ShowMessageBox(, NStr("en = 'Loaded'; de = 'Geladen'; ru = 'Загружено'"));
EndProcedure // LoadInitialList

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInitialListAtServer()
	Catalogs.EntryGoals.mmLoadFromDictionary();
EndProcedure // LoadInitialListAtServer

#EndRegion
