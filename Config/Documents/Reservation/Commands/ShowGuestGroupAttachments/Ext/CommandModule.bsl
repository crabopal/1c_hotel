// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	If ValueIsFilled(pCommandParameter) Then
		vGuestGroup = tcOnServer.cmGetAttributeByRef(pCommandParameter, "GuestGroup");
		vReservationNumber = tcOnServer.cmGetAttributeByRef(pCommandParameter, "Number");
		vParams = New Structure("Filter", New Structure("GuestGroup, ReservationNumber", vGuestGroup, vReservationNumber));
		OpenForm("InformationRegister.GuestGroupAttachments.ListForm", vParams, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
	EndIf;
EndProcedure // CommandProcessing
