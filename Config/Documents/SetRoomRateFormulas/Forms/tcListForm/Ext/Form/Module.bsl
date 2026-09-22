
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Filter by hotel
	If Not Parameters.Filter.Property("Hotel", Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;	
	If Not IsInRole("RightsToChooseHotel") Then
		Items.Hotel.ReadOnly = True;
		Items.Hotel.ChoiceButton = False;
		Items.Hotel.ClearButton = False;
	EndIf;	
	SetHotelFilter();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	SetHotelFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	If Not IsInRoleAtServer("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRoleName)
	Return IsInRole(pRoleName);
EndFunction // IsInRoleAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Create(pCommand)
	If FormOwner <> Undefined And ValueIsFilled(FormOwner.Object.Ref) Then 
		OpenForm("Document.SetRoomRateFormulas.Form.tcDocumentForm", New Structure("RoomRate", FormOwner.Object.Ref));
	Else
		OpenForm("Document.SetRoomRateFormulas.Form.tcDocumentForm");
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetHotelFilter()
	If Not ValueIsFilled(Hotel) Then
		tcCommonFunctionOnClientServer.cmDeleteDynamicListSelectionGroupItems(List, "Hotel");
	Else
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Hotel", Hotel, DataCompositionComparisonType.Equal, , True);
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
EndProcedure

#EndRegion
