
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.List.ChangeRowSet = False;
		Items.Tree.ChangeRowSet = False;
	EndIf;
	If Parameters.Property("Hotel") and ValueIsFilled(Parameters.Hotel) Then
		vFilterList	= New ValueList;
		vFilterList.Add(Catalogs.Hotels.EmptyRef());
		vFilterList.Add(Parameters.Hotel);
		tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Hotel", vFilterList, , , True);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then	
		vFilterList	= New ValueList;
		vFilterList.Add(Catalogs.Hotels.EmptyRef());
		vFilterList.Add(SessionParameters.CurrentHotel);
		tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Hotel", vFilterList, , , True);
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
