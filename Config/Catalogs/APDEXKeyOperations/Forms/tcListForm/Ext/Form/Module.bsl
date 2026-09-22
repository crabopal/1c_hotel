
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	vCommonPerformance = APDEXPerformanceSystemOnServer.GetItemCommonPerformance();
	If ValueIsFilled(vCommonPerformance) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(
		List,
		"Ref",
		vCommonPerformance,
		DataCompositionComparisonType.NotEqual,,,
		DataCompositionSettingsItemViewMode.Normal);
	EndIf;
	
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure FillOperations(pCommand)
	FillAPDEXKeyOperations();
	Items.List.Refresh();
EndProcedure

#EndRegion      

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillAPDEXKeyOperations()	
	APDEXPerformanceSystemFullRights.FillAPDEXKeyOperation();	
EndProcedure

#EndRegion   
