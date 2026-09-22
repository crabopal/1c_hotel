
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(Parameters.PeriodFrom) Then
		vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilter.LeftValue		= New DataCompositionField("Period");
		vNewFilter.ComparisonType	= DataCompositionComparisonType.GreaterOrEqual;
		vNewFilter.RightValue		= Parameters.PeriodFrom;
		vNewFilter.Use				= True;
		vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.QuickAccess;
	EndIf;
	If ValueIsFilled(Parameters.PeriodTo) Then
		vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilter.LeftValue		= New DataCompositionField("Period");
		vNewFilter.ComparisonType	= DataCompositionComparisonType.LessOrEqual;
		vNewFilter.RightValue		= Parameters.PeriodTo;
		vNewFilter.Use				= True;
		vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.QuickAccess;
	EndIf;

EndProcedure
