// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Record.OfferStatus) Then
		Record.OfferStatus = Enums.OfferStatuses.Pending;
	EndIf;
EndProcedure // OnCreateAtServer
