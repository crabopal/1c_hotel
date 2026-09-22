
#Region FormEventHandlers

 // --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
	EndIf;
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
		// Filter by current hotel
	If Not Parameters.Filter.Property("Hotel") Then		
		vArray = New Array;
		SelHotel = SessionParameters.CurrentHotel;
		vArray.Add(SelHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel", vArray);
	Else
		If TypeOf(Parameters.Filter.Hotel) = Type("Array") Then
			For Each vHotel In Parameters.Filter.Hotel Do
				If ValueIsFilled(vHotel) Then
					SelHotel = vHotel;
					Break;
				EndIf;
			EndDo;
		Else
			SelHotel = Parameters.Filter.Hotel;	
		EndIf;
	EndIf;	
	If Parameters.Property("ChoiceMode") Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;  
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

  // --------------------------------------------------------------------------------
&AtClient
Procedure ShowInvoices(pCommand)
	vDocRef = Items.List.RowData(Items.List.CurrentRow).Ref;
	If ValueIsFilled(vDocRef) Then
		OpenForm("DocumentJournal.CustomerAccountsJournal.ListForm", New Structure("Filter", New Structure("CloseOfPeriod", vDocRef)), ThisObject);
	EndIf;
EndProcedure // ShowInvoices

#EndRegion
