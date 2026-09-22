

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
	If Object.Ref = vCommonPerformance Then
		pCancel = True;
		Return;
	EndIf;

EndProcedure // OnCreateAtServer

#EndRegion

