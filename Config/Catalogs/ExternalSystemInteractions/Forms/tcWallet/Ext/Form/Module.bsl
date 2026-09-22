
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If IsBlankString(Object.HttpServer) Then
		Object.HttpServer = "api.my-wallet.app";
	EndIf;
EndProcedure

#EndRegion


