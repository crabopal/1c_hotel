
#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ButtonApplyFilter(pCommand)
	// Refresh filter
	SelGiftCertificateFind();   
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SelGiftCertificateOnChange(pItem)
	SelGiftCertificateFind();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SelGiftCertificateFind()
	List.SettingsComposer.Settings.Filter.Items.Clear();
	vNewFilter = List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue = New DataCompositionField("GiftCertificate");
	vNewFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	vNewFilter.ComparisonType = DataCompositionComparisonType.Equal;
	If IsBlankString(SelGiftCertificate) Then   
		vNewFilter.RightValue = "";
		vNewFilter.Use = False;
	Else
		vNewFilter.RightValue = TrimAll(SelGiftCertificate); 		
		vNewFilter.Use = True;
	EndIf;	
EndProcedure // SelGiftCertificateFind

#EndRegion