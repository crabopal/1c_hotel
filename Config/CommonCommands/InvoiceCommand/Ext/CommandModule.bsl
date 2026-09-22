#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	OpenForm("Document.Settlement.ListForm", , pCommandExecuteParameters.Source, "tcSettlementInvoiceListForm", GetMainWindow());
EndProcedure // CommandProcessing

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
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
