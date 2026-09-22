
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not tcOnServer.cmIsInRole("Administrator") Then
		ReadOnly = True;
	EndIf;
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
EndProcedure 

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure InternetMailSMTPPasswordStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	pItem.PasswordMode = Not pItem.PasswordMode;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure InternetMailPasswordStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	pItem.PasswordMode = Not pItem.PasswordMode;
EndProcedure

#EndRegion