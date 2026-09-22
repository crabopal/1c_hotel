
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Check user rights to use item
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToViewCreditCardsData") Then
			pCancel = True;
		Else
			// Fill attributes with default values
			If Not ValueIsFilled(Object.Author) Then
				Object.Author = SessionParameters.CurrentUser;
				Object.CreateDate = CurrentSessionDate();
			EndIf;
		EndIf;
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Filling values
	If Parameters.Property("FillingValues") Then
		If Parameters.FillingValues.Property("CardOwner") Then
			Object.CardOwner = Parameters.FillingValues.CardOwner;
		EndIf;
		If Parameters.FillingValues.Property("CardNumber") Then
			Object.CardNumber = Parameters.FillingValues.CardNumber;
			CardNumberOnChangeAtServer();
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("CreditCard.Write", Object.Ref, FormOwner);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CardNumberOnChange(pItem)
	CardNumberOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CardValidTillDateOnChange(pItem)
	Object.CardValidTillDate = BegOfMonth(Object.CardValidTillDate);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CardNumberOnChangeAtServer()
	Object.Description = cmGetCreditCardDescription(Object.CardNumber);
EndProcedure

#EndRegion    

