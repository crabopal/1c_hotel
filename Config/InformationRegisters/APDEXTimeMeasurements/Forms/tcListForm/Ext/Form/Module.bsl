
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)   
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "PeriodUTC", BegOfDay(CurrentSessionDate()), 
			DataCompositionComparisonType.GreaterOrEqual, , True, DataCompositionSettingsItemViewMode.QuickAccess);
EndProcedure

#EndRegion
