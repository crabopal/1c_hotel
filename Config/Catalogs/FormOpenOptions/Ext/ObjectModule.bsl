
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If AdditionalProperties.Property("CheckedAttributes") Then
		For Each vId In AdditionalProperties.CheckedAttributes Do
			CheckedAttributes.Add(vId);       
		EndDo;	
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
Procedure BeforeWrite(Cancel)       
	If DataExchange.Load Then
		Return;
	EndIf;
	If Ref.DeletionMark = False And DeletionMark = True Then
	     IsActive = False;
	EndIf; 
EndProcedure

#EndRegion
