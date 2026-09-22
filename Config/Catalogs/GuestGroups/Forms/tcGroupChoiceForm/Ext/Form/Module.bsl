
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Owner", SessionParameters.CurrentHotel, DataCompositionComparisonType.Equal, , True);
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

