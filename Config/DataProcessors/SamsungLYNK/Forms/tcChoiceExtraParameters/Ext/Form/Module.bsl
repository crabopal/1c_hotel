
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	MessageType = "CONFIRM";
	CloseTime = "10"
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionExecute(pCommand)
	vResult = New Structure();
	vResult.Insert("poweron", ?(PowerOn, "True", "False"));
	vResult.Insert("smarthubapp", ?(SmartHub, "True", "False"));
	vResult.Insert("messagetype", MessageType);
	vResult.Insert("closetime", CloseTime);
	Close(vResult)
EndProcedure // ActionExecute

#EndRegion