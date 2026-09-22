
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	tcCommonFunctionOnClientServer.cmSetFilterItems(
		List.Filter,
		"DeletionMark",
		False,
		DataCompositionComparisonType.Equal);

EndProcedure // OnCreateAtServer

#EndRegion






