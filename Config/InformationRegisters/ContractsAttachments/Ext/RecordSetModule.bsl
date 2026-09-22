
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pReplacing)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	For Each vRecRow In ThisObject Do
		If Not ValueIsFilled(vRecRow.Author) Then
			vRecRow.Author = SessionParameters.CurrentUser;
		EndIf;
	EndDo;
EndProcedure // BeforeWrite

#EndRegion
