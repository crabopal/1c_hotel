
#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadInitalList(pCommand)
	LoadInitalListAtServer();
EndProcedure // LoadInitalList

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadInitalListAtServer()
	Catalogs.TripPurposes.mmLoadFromDictionary();
EndProcedure // LoadInitalListAtServer

#EndRegion