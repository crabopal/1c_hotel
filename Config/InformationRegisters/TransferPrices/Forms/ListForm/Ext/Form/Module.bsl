

#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.List.ChangeRowSet = False;
	EndIf;   
	
	SelHotel = SessionParameters.CurrentHotel;
	
	// Filter by hotel
	vFilterList	= New ValueList;
	vFilterList.Add(Catalogs.Hotels.EmptyRef());
	If ValueIsFilled(SelHotel) Then
		vFilterList.Add(SelHotel);
	EndIf;
	
	vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue		= New DataCompositionField("Hotel");
	vNewFilter.ComparisonType	= DataCompositionComparisonType.InList;
	vNewFilter.RightValue		= vFilterList;
	vNewFilter.Use				= True;
	vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "TransferPrices.Change" Then
		Items.List.Refresh();
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CopyPricesWizard(pCommand)
	OpenForm("InformationRegister.TransferPrices.Form.CopyPricesWizard");
EndProcedure

#EndRegion
