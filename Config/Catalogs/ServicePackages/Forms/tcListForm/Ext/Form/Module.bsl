#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
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
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure // OnCreateAtServer

#EndRegion