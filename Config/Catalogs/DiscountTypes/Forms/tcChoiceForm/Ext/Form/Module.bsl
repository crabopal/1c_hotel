
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)    
	vHotel = SessionParameters.CurrentHotel;
	If Parameters.Property("Hotel") and ValueIsFilled(Parameters.Hotel) Then
		vHotel = Parameters.Hotel;
	Else
		If Parameters.Property("Filter") And Parameters.Filter.Property("Hotel") And ValueIsFilled(Parameters.Filter.Hotel) Then
			vHotel = Parameters.Filter.Hotel;
		EndIf;
	EndIf;
	vFilterByItemsList = False;
	vFilterByAllowedItems = False;
	vDiscountTypesList = New ValueList;
	vDiscountTypesAllowedList = New ValueList;
	vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermissionGroup) Then
		If vPermissionGroup.DiscountTypesAllowed.Count() > 0 Then
			vFilterByItemsList = True;
			vFilterByAllowedItems = True;
			For Each vRow In vPermissionGroup.DiscountTypesAllowed Do
				If ValueIsFilled(vRow.DiscountType) Then
					If vRow.DiscountType.Hotel = Catalogs.Hotels.EmptyRef() Or vRow.DiscountType.Hotel = vHotel Then
						If vDiscountTypesAllowedList.FindByValue(vRow.DiscountType) = Undefined Then
							vDiscountTypesAllowedList.Add(vRow.DiscountType);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If Parameters.Property("Source") And Parameters.Source = "InputInitialBalances" Then
		vFilterByItemsList = True;
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	DiscountTypes.Ref AS Ref
		|FROM
		|	Catalog.DiscountTypes AS DiscountTypes
		|WHERE
		|	(DiscountTypes.Hotel = &qHotel
		|			OR DiscountTypes.Hotel = VALUE(Catalog.Hotels.EmptyRef))
		|	AND (DiscountTypes.IsAccumulatingDiscount
		|			OR DiscountTypes.LoyaltyType = VALUE(Enum.LoyaltyType.Bonuses))
		|	AND NOT DiscountTypes.DeletionMark
		|	AND NOT DiscountTypes.IsFolder
		|
		|ORDER BY
		|	DiscountTypes.SortCode,
		|	DiscountTypes.Description";
		vQry.SetParameter("qHotel", vHotel);
		vRefs = vQry.Execute().Unload();
		For Each vRefsRow In vRefs Do
			If Not vFilterByAllowedItems Or vFilterByAllowedItems And vDiscountTypesAllowedList.FindByValue(vRefsRow.Ref) <> Undefined Then
				vDiscountTypesList.Add(vRefsRow.Ref);
			EndIf;
		EndDo;
	ElsIf vFilterByItemsList And vFilterByAllowedItems Then
		vDiscountTypesList.LoadValues(vDiscountTypesAllowedList.UnloadValues());
	EndIf;
	If Not vFilterByItemsList Then
		If ValueIsFilled(vHotel) Then	
			vFilterList	= New ValueList;
			vFilterList.Add(Catalogs.Hotels.EmptyRef());
			vFilterList.Add(vHotel);
			tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Hotel", vFilterList, , , True);
		EndIf;
		If Parameters.Property("HasToBeDirectlyAssigned") And Parameters.Property("Filter") Then
			If Parameters.HasToBeDirectlyAssigned <> Undefined Then
				Parameters.Filter.Insert("HasToBeDirectlyAssigned", Parameters.HasToBeDirectlyAssigned);
			EndIf;
		EndIf;     
	Else
		tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Ref", vDiscountTypesList, , , True);
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
