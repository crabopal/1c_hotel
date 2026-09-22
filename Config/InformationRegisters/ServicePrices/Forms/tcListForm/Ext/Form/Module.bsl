
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.List.ChangeRowSet = False;
	EndIf;
	// Filter by hotel
	vFilterList	= New ValueList;
	vFilterList.Add(Catalogs.Hotels.EmptyRef());
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vFilterList.Add(SessionParameters.CurrentHotel);
	EndIf;
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Hotel", vFilterList, 
					DataCompositionComparisonType.InList, , 
					True, DataCompositionSettingsItemViewMode.Inaccessible);
EndProcedure // OnCreateAtServer

#EndRegion
