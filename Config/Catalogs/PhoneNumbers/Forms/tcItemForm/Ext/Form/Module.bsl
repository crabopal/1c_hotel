// --------------------------------------------------------------------------------
&AtClient
Procedure PhoneNumberOnChange(pItem)
	If IsBlankString(Object.Description) Then
		Object.Description = Object.PhoneNumber;
	EndIf;
EndProcedure // PhoneNumberOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Object.Owner) Then
		Object.Owner = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // OnCreateAtServer
