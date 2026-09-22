// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vClearGuestNames = Undefined;
	If Parameters.Property("ClearGuestNames") Then
		vClearGuestNames = Parameters.ClearGuestNames;
	EndIf;
	If vClearGuestNames = Undefined Then
		ClearGuestNames = True;
	Else
		ClearGuestNames = vClearGuestNames;
	EndIf;
	vUseSameFoliosAndBillingInstructions = Undefined;
	If Parameters.Property("UseSameFoliosAndBillingInstructions") Then
		vUseSameFoliosAndBillingInstructions = Parameters.UseSameFoliosAndBillingInstructions;
	EndIf;
	If vUseSameFoliosAndBillingInstructions = Undefined Then
		UseSameFoliosAndBillingInstructions = False;
	Else
		UseSameFoliosAndBillingInstructions = vUseSameFoliosAndBillingInstructions;
	EndIf;
	vCopyToTheNewGuestGroup = Undefined;
	If Parameters.Property("CopyToTheNewGuestGroup") Then
		vCopyToTheNewGuestGroup = Parameters.CopyToTheNewGuestGroup;
	EndIf;
	If vCopyToTheNewGuestGroup = Undefined Then
		CopyToTheNewGuestGroup = True;
	Else
		CopyToTheNewGuestGroup = vCopyToTheNewGuestGroup;
	EndIf;
	vGuestGroup = Undefined;
	If Parameters.Property("GuestGroup") And ValueIsFilled(Parameters.GuestGroup) Then
		vGuestGroup = Parameters.GuestGroup;
	EndIf;
	If ValueIsFilled(vGuestGroup) Then
		GuestGroup = vGuestGroup;
		Hotel = GuestGroup.Owner;
	Else
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	vTemplateDocument = Undefined;
	If Parameters.Property("TemplateDocument") And ValueIsFilled(Parameters.TemplateDocument) Then
		vTemplateDocument = Parameters.TemplateDocument;
	EndIf;
	If ValueIsFilled(vTemplateDocument) Then
		TemplateDocument = vTemplateDocument;
	EndIf;
	// Set form appearance
	SetFormAppearance();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandContinue(pCommand)
	If CopyToTheNewGuestGroup Then
		Notify("CopyReservation.OptionsChoice", New Structure("ClearGuestNames, UseSameFoliosAndBillingInstructions, TemplateDocument, CopyToTheNewGuestGroup", ClearGuestNames, UseSameFoliosAndBillingInstructions, TemplateDocument, True), FormOwner);
	Else
		Notify("CopyReservation.OptionsChoice", New Structure("ClearGuestNames, UseSameFoliosAndBillingInstructions, TemplateDocument, CopyToTheNewGuestGroup, GuestGroup", ClearGuestNames, UseSameFoliosAndBillingInstructions, TemplateDocument, False, GuestGroup), FormOwner);
	EndIf;
	ThisObject.Close();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandCancel(pCommand)
	ThisObject.Close();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CopyToTheNewGuestGroupOnChange(pItem)
	SetFormAppearance();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearance()
	If CopyToTheNewGuestGroup Then
		If UseSameFoliosAndBillingInstructions Then
			UseSameFoliosAndBillingInstructions = False;
		EndIf;
		Items.UseSameFoliosAndBillingInstructions.Enabled = False;
	Else
		Items.UseSameFoliosAndBillingInstructions.Enabled = True;
	EndIf;
EndProcedure
