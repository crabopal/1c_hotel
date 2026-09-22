
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Hide elements marked for deletion
	vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue		= New DataCompositionField("DeletionMark");
	vNewFilter.ComparisonType	= DataCompositionComparisonType.Equal;
	vNewFilter.RightValue		= False;
	vNewFilter.Use				= True;
	vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
EndProcedure // OnCreateAtServer

#EndRegion
