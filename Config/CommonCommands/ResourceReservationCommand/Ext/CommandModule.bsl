
#Region EventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	#IF NOT MobileClient THEN 
		// APDEX
		vKeyOperation = "Document.ResourceReservation.Form.tcReservationListForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Document.ResourceReservation.ListForm", , pCommandExecuteParameters.Source, "tcReservationsListForm", GetMainWindow());
	#ELSE
		OpenForm("Document.ResourceReservation.Form.mcReservationListForm", , pCommandExecuteParameters.Source, "tcReservationsListForm", GetMainWindow());	
	#ENDIF
EndProcedure // CommandProcessing

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtClient
Function GetMainWindow()
	vWindows = GetWindows();
	vMainWindow = Undefined;
	For Each vWindow In vWindows Do
		If vWindow.IsMain Then
			vMainWindow = vWindow;
			Break;
		EndIf;
	EndDo;
	Return vMainWindow;
EndFunction // GetMainWindow

#EndRegion