
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SharedGuests.Clear();
	If Parameters.Property("SharedGuests") And TypeOf(Parameters.SharedGuests) = Type("Array") Then
		For Each vSharedGuestStruct In Parameters.SharedGuests Do
			vSharedGuestsRow = SharedGuests.Add();
			FillPropertyValues(vSharedGuestsRow, vSharedGuestStruct);
			vSharedGuestsRow.BalanceAmountPresentation = cmFormatSum(vSharedGuestStruct.Balance, vSharedGuestStruct.BalanceCurrency);
		EndDo;
	EndIf;
	FoliosPage = "Left";
	If Parameters.Property("FoliosPage") Then
		FoliosPage = Parameters.FoliosPage;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SelectAll(pCommand)
	For Each vRow In SharedGuests Do
		vRow.Check = True;
	EndDo;
EndProcedure // SelectAll

// --------------------------------------------------------------------------------
&AtClient
Procedure UnselectAll(pCommand)
	For Each vRow In SharedGuests Do
		vRow.Check = False;
	EndDo;
EndProcedure // UnselectAll

// --------------------------------------------------------------------------------
&AtClient
Procedure Selection(pCommand)
	vSelectedGuests = New Array();
	For Each vSharedGuestsRow In SharedGuests Do
		vSelectedGuests.Add(New Structure("Check, Client, AccommodationType, CheckInDate, Duration, CheckOutDate, Balance, BalanceCurrency", vSharedGuestsRow.Check, vSharedGuestsRow.Client, vSharedGuestsRow.AccommodationType, vSharedGuestsRow.CheckInDate, vSharedGuestsRow.Duration, vSharedGuestsRow.CheckOutDate, vSharedGuestsRow.Balance, vSharedGuestsRow.BalanceCurrency));
	EndDo;
	Notify("Folios.SharedGuestsSelection", New Structure("SelectedGuests, FoliosPage", vSelectedGuests, FoliosPage), FormOwner);
	Close();
EndProcedure // Selection

#EndRegion

#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SharedGuestsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vCurRow = Items.SharedGuests.CurrentData;
	If vCurRow <> Undefined Then
		vCurRow.Check = True;
	EndIf;
	Selection(Commands.Selection);
EndProcedure // SharedGuestsSelection

#EndRegion
