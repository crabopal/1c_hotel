#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Arr") Then
		vArr = Parameters.Arr;
		For Each vRow In vArr Do
			vNewRow = CreditCardProcessingSystemTable.Add();
			vNewRow.CreditCardProcessingSystem = vRow;
		EndDo;
	EndIf;
	If Parameters.Property("ExtraParams") Then
		ExtraParams = Parameters.ExtraParams;	
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure CreditCardProcessingSystemParametersSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	NotifyChoice(New Structure("CreditCardProcessingSystem, ExtraParams", CreditCardProcessingSystemTable.FindByID(pSelectedRow).CreditCardProcessingSystem, ExtraParams));
EndProcedure // CreditCardProcessingSystemParametersSelection

#EndRegion
