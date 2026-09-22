#Region FormEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Documents.CashIncomeOutcome.Write" Then
		Items.List.Refresh();
	EndIf;
EndProcedure

#EndRegion

