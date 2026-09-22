// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Filter.Property("Guest") Then
		SelClients = Parameters.Filter.Guest;	
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "InformationRegisters.ClientCertificates.Write" And pParameter = SelClients Then
		Items.List.Refresh();	
	EndIf;	
EndProcedure // NotificationProcessing
