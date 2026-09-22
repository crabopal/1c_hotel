
#Region EventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vCurHotel = tcOnServer.cmGetCurrentHotelAttribute();
	If Not ValueIsFilled(vCurHotel) Then
		ShowMessageBox(, NStr("en='Please, choose hotel first!'; ru='Пожалуйста сначала выберите отель!'; de='Bitte wählen Sie zuerst ein Hotel aus!'"));
		Return;
	EndIf;
	OpenForm("Document.Accommodation.ObjectForm");
EndProcedure // CommandProcessing

#EndRegion
