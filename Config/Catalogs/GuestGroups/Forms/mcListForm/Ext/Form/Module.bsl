
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vHotel = SessionParameters.CurrentHotel;
	If Not Parameters.Filter.Property("Owner") Then
		Parameters.Filter.Insert("Owner", vHotel);
	EndIf;
	If Parameters.Property("FilledGroupType") And Parameters.FilledGroupType Then
		SelFilledGroupType = Parameters.FilledGroupType;
	EndIf;
	If SelFilledGroupType Then
		AttributeChangeAtServer("GroupType", True, DataCompositionComparisonType.Filled);
	EndIf;		
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowFiletGroup(pCommand)
	Items.FormShowFiletGroup.Check = Not Items.FormShowFiletGroup.Check;
	If Items.FormShowFiletGroup.Check Then 
		Items.Pages.CurrentPage = Items.PageListSettingsComposerUserSettings;
	Else
		Items.Pages.CurrentPage = Items.PageTreeAndList;	
	EndIf;
EndProcedure // ShowFiletGroup

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, pValue, vComparisonType, , True);
	EndIf;
EndProcedure //AttributeChangeAtServer

#EndRegion
