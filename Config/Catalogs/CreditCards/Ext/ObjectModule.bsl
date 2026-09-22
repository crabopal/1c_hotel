
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnSetNewCode(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewCode

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	Author = SessionParameters.CurrentUser;
	CreateDate = CurrentSessionDate();
EndProcedure // OnCopy

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion          

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	Author = SessionParameters.CurrentUser;
	CreateDate = CurrentSessionDate();
EndProcedure // pmFillAttributesWithDefaultValues

#EndRegion
