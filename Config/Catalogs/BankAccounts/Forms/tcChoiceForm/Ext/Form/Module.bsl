
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Filter.Property("Hotel") Then	
		If Parameters.Filter.Hotel <> Catalogs.Hotels.EmptyRef() Then       
			SelHotel = Parameters.Filter.Hotel;    
			Parameters.Filter.Delete("Hotel");
		EndIf;
	EndIf;
	// Set hotel color          
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;      
	HotelOnChangeAtServer();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	HotelOnChangeAtServer();
EndProcedure

#EndRegion    

#Region Private
			  
// --------------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()  
	If ValueIsFilled(SelHotel) Then  
		
		vArray = New Array;
		vArray.Add(SelHotel);
		vArray.Add(Catalogs.Hotels.EmptyRef());   
		
		tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Hotel", vArray, DataCompositionComparisonType.InList, , True);
	Else
		tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Hotel", SelHotel, DataCompositionComparisonType.InList, , False);
	EndIf;  
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure

#EndRegion     
