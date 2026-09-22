
#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then		
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel",vArray);
	EndIf;
	If Parameters.Property("HideForManualPackageAssignment") And Parameters.Property("Filter") Then
		If Parameters.HideForManualPackageAssignment <> Undefined Then
			Parameters.Filter.Insert("HideForManualPackageAssignment", Parameters.HideForManualPackageAssignment);
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
