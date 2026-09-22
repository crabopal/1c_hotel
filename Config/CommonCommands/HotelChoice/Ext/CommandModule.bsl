
#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vNotifyProcessing = New NotifyDescription("HotelChoiceClickContinue", ThisObject);
	ShowQueryBox(vNotifyProcessing,
				 NStr("en = 'After the change of the hotel, all forms will be closed, continue?'; 
					  |de = 'Nach dem Wechsel des Hotels werden Formulare geschlossen, weiter?'; 
					  |ru = 'После смены гостиницы будут закрыты все формы, продолжить?'"),
				 QuestionDialogMode.YesNo,
				 , DialogReturnCode.No);
EndProcedure // CommandProcessing

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient 
Procedure HotelChoiceClickContinue(pResult, pExtraParams) Export 
	If pResult = DialogReturnCode.Yes Then
		// Close all windows
		tcCommonFunctionOnClientServer.cmCloseAllWindows(); 
		vNotifyProcessing = New NotifyDescription("HotelChoiceClickAfterConfirmation", ThisObject);
		OpenForm("Catalog.Hotels.ChoiceForm",New Structure("ChangeSessionParameter", True), ThisObject, , , , vNotifyProcessing);
	EndIf;	
EndProcedure // HotelChoiceClickContinue

// -------------------------------------------------------------------------
&AtClient 
Procedure HotelChoiceClickAfterConfirmation(vSelectedValue, pExtraParams) Export 
	If vSelectedValue <> Undefined 
		And ValueIsFilled(vSelectedValue) 
		And Not tcOnServer.cmGetAttributeByRef(vSelectedValue, "IsFolder") Then
		// Do change hotel
		tcOnServer.ChangeCurrentHotel(vSelectedValue);
		// Change application caption
		tcOnClient.ChangeApplicationCaption(vSelectedValue);
		// Set functional options hotel parameter
		SetInterfaceFunctionalOptionParameters(New Structure("Hotel", vSelectedValue));
		// Notify hotel was changed
	 	Notify("System.Hotel.Changed", vSelectedValue, ThisObject);
	EndIf;	
EndProcedure

#EndRegion
