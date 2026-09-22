
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	List.Parameters.SetParameterValue("qCurWorkstation",SessionParameters.CurrentWorkstation);
EndProcedure

#EndRegion


