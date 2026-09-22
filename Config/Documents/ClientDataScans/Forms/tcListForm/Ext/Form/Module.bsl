
#Region FormEventHandlers

 // -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SelFilter = 0; 
	If Parameters.Property("Filter") And Not Parameters.Filter.Property("Hotel") Then
		SelHotel = SessionParameters.CurrentHotel;
	Else
		SelHotel = Parameters.Filter.Hotel;
	EndIf;
	If ValueIsFilled(SelHotel) Then
		AttributeChangeAtServer("Hotel", SelHotel);
	Else
		ClearingAttributeAtServer("Hotel");
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;
	// Filter by client
	If Parameters.Property("Filter") And Parameters.Filter.Property("Client") Then
		SelClient = Parameters.Filter.Client;
		If ValueIsFilled(SelClient) Then
			SelFilter = 3; 
			AttributeChangeAtServer("Guest", SelClient);
		EndIf;
	EndIf;
	// Filter by document status
	vUse = True;
	If SelFilter = 0 Then
		vRightValue = PredefinedValue("Enum.ScanStatuses.IsNew");
	ElsIf SelFilter = 1 Then	
		vRightValue = PredefinedValue("Enum.ScanStatuses.IsRecognized");
	ElsIf SelFilter = 2 Then	
		vRightValue = PredefinedValue("Enum.ScanStatuses.IsProcessed");  
	Else
		vRightValue = Undefined;
		vUse = False;
	EndIf; 
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Status", vRightValue, , , vUse);
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFilterOnChange(Item)
	ChangeSelFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateOnChange(pItem)
	If ValueIsFilled(SelDate) Then
		AttributeChangeAtServer("AccountingDate", BegOfDay(SelDate), );
	Else
		ClearingAttributeAtServer("AccountingDate");
	EndIf;
EndProcedure // SelDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)
	If ValueIsFilled(SelClient) Then
		AttributeChangeAtServer("Guest", SelClient);
	Else
		ClearingAttributeAtServer("Guest");
	EndIf;
EndProcedure // SelClientOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAuthorOnChange(pItem)
	If ValueIsFilled(SelAuthor) Then
		AttributeChangeAtServer("Author", SelAuthor);
	Else
		ClearingAttributeAtServer("Author");
	EndIf;
EndProcedure // SelAuthorOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	If ValueIsFilled(SelGuestGroup) Then
		AttributeChangeAtServer("GuestGroup", SelGuestGroup);
	Else
		ClearingAttributeAtServer("GuestGroup");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	If ValueIsFilled(SelRoom) Then
		AttributeChangeAtServer("Room", SelRoom);
	Else
		ClearingAttributeAtServer("Room");
	EndIf;
EndProcedure // SelRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCitizenshipOnChange(pItem)
	If ValueIsFilled(SelCitizenship) Then
		AttributeChangeAtServer("Citizenship", SelCitizenship);
	Else
		ClearingAttributeAtServer("Citizenship");
	EndIf;
EndProcedure // SelCitizenshipOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	If ValueIsFilled(SelHotel) Then
		AttributeChangeAtServer("Hotel", SelHotel, DataCompositionComparisonType.InHierarchy);
	Else
		ClearingAttributeAtServer("Hotel");
	EndIf;  
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	If Not IsInRoleAtServer("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // SelHotelClearing

#EndRegion

#Region Internal

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeSelFilter()
	vUse = True;
	If SelFilter = 0 Then
		vRightValue = PredefinedValue("Enum.ScanStatuses.IsNew");
	ElsIf SelFilter = 1 Then	
		vRightValue = PredefinedValue("Enum.ScanStatuses.IsRecognized");
	ElsIf SelFilter = 2 Then	
		vRightValue = PredefinedValue("Enum.ScanStatuses.IsProcessed");  
	Else
		vRightValue = Undefined;
		vUse = False;
	EndIf; 
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Status", vRightValue, , , vUse);
EndProcedure	

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, pValue, vComparisonType, , True);
	EndIf;
EndProcedure // AttributeChangeAtServer 

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, , , , False);
EndProcedure // ClearingAttributeAtServer 

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRoleName)
	Return IsInRole(pRoleName);
EndFunction // IsInRoleAtServer

#EndRegion


