
#Region Public

// Method of final measurement of time on the client
Procedure FinishTimeIntervalMeasurementNotGlobal() Export
	
	FinishTimeIntervalMeasurement();
	
EndProcedure

// Method of final measurement of time on the client
//
// Parameters:
//  pMeasurementUUID - UUID	 - Unique metering identifier
//
Procedure FinishManualTimeIntervalMeasurementNotGlobal(pMeasurementUUID) Export
	
	FinishTimeIntervalMeasurement(pMeasurementUUID);
	
EndProcedure

// Record the accumulated time measurements of key operations on the server
//
// Parameters:
//  pBeforeExit	 - Boolean	 - True if the method is called before closing the application
//
Procedure ResultWriteNotGlobal(pBeforeExit = False) Export
	
	vAPDEX = APDEXParameters["TimeIntervalMeasurement"];
	
	If vAPDEX <> Undefined Then
		
		If vAPDEX["Measurement"].Количество() = 0 Then
			
			vNewPeriodRecord = vAPDEX["PeriodRecord"];
		Иначе
			vCurTimeIntervalMeasurement = vAPDEX["Measurement"];
			vNewPeriodRecord = APDEXPerformanceSystemFullRights.CommitTimeIntervalMeasurement(vCurTimeIntervalMeasurement);
			vAPDEX["PeriodRecord"] = vNewPeriodRecord;
			If pBeforeExit Then
				Return;
			EndIf;
			
			For Each vRowsBuffer Из vCurTimeIntervalMeasurement Do
				vBuffer = vRowsBuffer.Value;
				vDelRowsr = New Array;
				For Each vRow In vBuffer Do
					vDate = vRow.Key;
					vDataValue = vRow.Value;
					vDuration = vDataValue.Get("Duration");
					// This means that the operation has already ended, you need to remove it from the buffer.
					If vDuration <> Undefined Then
						vDelRowsr.Add(vDate);
					EndIf;
				Enddo;
				For Each vDate Из vDelRowsr Do
					vAPDEX["Measurement"][vRowsBuffer.Key].Delete(vDate);
				EndDo;
			EndDo;
		EndIf;
		AttachIdleHandler("ResultWriteNotGlobalAuto", vNewPeriodRecord, True);
	EndIf;
	
EndProcedure

// Called before interactively shutting down a user with a data region
//
// Parameters:
//  pParams	 - Structure - Params for fill
//
Procedure BeforeExit(pParams) Export
	
	ResultWriteNotGlobal(True);
	
EndProcedure

// The procedure ends timing on the client
// Parameters:
//  UUID - UUID - Unique metering identifier
Procedure FinishTimeIntervalMeasurement(pUUID = Undefined)
	If pUUID = Undefined Then
		pUUID = New UUID("00000000-0000-0000-0000-000000000000");
	EndIf;
	
	vAPDEX = APDEXParameters["TimeIntervalMeasurement"];
	If vAPDEX <> Undefined Then
		vDateTo = APDEXPerformanceSystemOnClientServer.TimerValue(False);
		vTimeTo = APDEXPerformanceSystemOnClientServer.TimerValue();
		
		vDateOffset = APDEXParameters["TimeIntervalMeasurement"]["DateOffset"];
		vDateTo = vDateTo + vDateOffset;
		
		vMeasurement = APDEXParameters["TimeIntervalMeasurement"]["Measurement"];
		For Each vKeyOperationCache In vMeasurement Do
			For Each vRow Из vKeyOperationCache.Value Do
				vBuffer = vRow.Value;
				vTimeStart = vBuffer["TimeStart"];
				vDuration = vBuffer.Get("Duration");
				If vDuration = Undefined And vBuffer["MeasurementUUID"] = pUUID Then
					vBuffer.Insert("Duration", vTimeTo - vTimeStart);
					vBuffer.Insert("TimeTo", vTimeTo);
					vBuffer.Insert("DateTo", vDateTo);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
EndProcedure

#EndRegion