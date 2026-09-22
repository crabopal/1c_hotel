
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnSetNewCode(pStandardProcessing, pPrefix)
	pStandardProcessing = False;
	vUUID = New UUID();
	Code = String(vUUID);
EndProcedure // OnSetNewCode

// -----------------------------------------------------------------------------
Procedure OnCopy(CopiedObject)
	DataProcessor = Undefined;
EndProcedure

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmClearSessionAttributes() Export
	SessionID = "";
	SessionStartTime = '00010101';
	SessionLastActivityTime = '00010101';
EndProcedure // pmClearSessionAttributes

// -----------------------------------------------------------------------------
Procedure pmSetNewSessionAttributes(pSessionID) Export
	SessionID = TrimR(pSessionID);
	SessionStartTime = CurrentSessionDate();
	SessionLastActivityTime = SessionStartTime;
EndProcedure // pmSetNewSessionAttributes

// -----------------------------------------------------------------------------
Procedure pmUpdateSessionAttributes(pFull = True) Export
	SessionLastActivityTime = CurrentSessionDate();
	If pFull Then
		LastFullSynchronizationTime = SessionLastActivityTime;
	EndIf;
EndProcedure // pmUpdateSessionAttributes

#EndRegion
