// -----------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
EndProcedure // ListBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckStatus(pCommand)
	vError = "";
	SMS.CheckSMSStatuses(vError);
	If ValueIsFilled(vError) Then
		ShowMessageBox(,vError);
	EndIf;
	Items.List.Refresh();
EndProcedure // CheckStatus
