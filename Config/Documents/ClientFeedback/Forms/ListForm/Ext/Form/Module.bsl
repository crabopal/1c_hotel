
#Region FormEventHandlers

//-----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	SelHotel = SessionParameters.CurrentHotel;
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Hotel") Then
			SelHotel = Parameters.Filter.Hotel;
		EndIf;
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
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute,pValue,pComparisonType = Undefined)
	vComparisonType =  ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
	vValue = pValue;	
	If ValueIsFilled(vValue) Then
		vFilter = List.Filter;
		vField = New DataCompositionField(pAttribute);
		If vFilter.Items.Count() = 0 Then	
			vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
			vFilterItem.LeftValue = vField;
			vFilterItem.ComparisonType = vComparisonType;
			vFilterItem.RightValue = vValue;
			vFilterItem.Use = True;
		Else
			// Find field
			vCancel = False;
			For Each int In  vFilter.Items Do
				If  int.LeftValue = vField  Then
					// Field delete
					vFilter.Items.Delete(int);	
					// Add a new
					vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
					vFilterItem.LeftValue = vField;
					vFilterItem.ComparisonType = vComparisonType;
					vFilterItem.RightValue = vValue;
					vFilterItem.Use = True;
					vCancel = True;
					Break;
				EndIf;	
			EndDo;
			If Not vCancel Then
				// The field is not found, we add a new
				vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
				vFilterItem.LeftValue = vField;
				vFilterItem.ComparisonType = vComparisonType;
				vFilterItem.RightValue = vValue;
				vFilterItem.Use = True;
			EndIf;
		EndIf;
	EndIf;
	Items.List.Refresh();
EndProcedure

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
