
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);

	// Process parameters	
	If Parameters.Property("SelHotel") Then
		SelHotel = Parameters.SelHotel;
	Else
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Parameters.Property("ChoiceMode") Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	SetParametersDinamicList();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SetParametersDinamicList();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCompanyOnChange(pItem)
	SetParametersDinamicList();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetParametersDinamicList()
	// Set default parameters
	List.Parameters.SetParameterValue("qHotel", SelHotel);
	List.Parameters.SetParameterValue("qCompany", SelCompany);
EndProcedure //  SetParametersDinamicList()

#EndRegion
