#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Object.HttpServer) Then
		Object.HttpServer = "http://localhost";
	EndIf;
	If Not ValueIsFilled(Object.HttpPort) Then
		Object.HttpPort = 8080;
	EndIf;
	Object.HttpUseSsl = False;
EndProcedure

#EndRegion