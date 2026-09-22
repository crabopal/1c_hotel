
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vHotelsList = New ValueList();
		vHotelsList.Add(SessionParameters.CurrentHotel);
		vHotelsList.Add(Catalogs.Hotels.EmptyRef());
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Hotel", vHotelsList, DataCompositionComparisonType.InList, , True);
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

