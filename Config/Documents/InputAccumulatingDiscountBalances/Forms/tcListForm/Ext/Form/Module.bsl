
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
	
	vHotel = SessionParameters.CurrentHotel;
	If Parameters.Property("Hotel") and ValueIsFilled(Parameters.Hotel) Then
		vHotel = Parameters.Hotel;
	Else
		If Parameters.Property("Filter") And Parameters.Filter.Property("Hotel") And ValueIsFilled(Parameters.Filter.Hotel) Then
			vHotel = Parameters.Filter.Hotel;
		EndIf;
	EndIf;
	If ValueIsFilled(vHotel) Then	
		vFilterList	= New ValueList;
		vFilterList.Add(Catalogs.Hotels.EmptyRef());
		vFilterList.Add(vHotel);
		tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Hotel", vFilterList, , , True);
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
