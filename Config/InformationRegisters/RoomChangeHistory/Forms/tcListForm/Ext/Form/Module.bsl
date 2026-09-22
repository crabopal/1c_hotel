&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Use beds setup
	vUseBedsSetups = False;
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(vHotel) Then
		vUseBedsSetups = vHotel.BedsSetups;
	EndIf;
	Items.BedsSetup.Visible = vUseBedsSetups;
EndProcedure // OnCreateAtServer
