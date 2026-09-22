 
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
    If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Ref) Or ValueIsFilled(Ref) And 
	  (TrimAll(AgreementText) <> TrimAll(Ref.AgreementText) Or 
	   TrimAll(ShortAgreementText) <> TrimAll(Ref.ShortAgreementText)) Then
		ChangeAuthor = SessionParameters.CurrentUser;
		ChangeDate = CurrentSessionDate();
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnCopy(CopiedObject)
	ChangeDate = '00010101';
	ChangeAuthor = Catalogs.Employees.EmptyRef();
EndProcedure

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion
