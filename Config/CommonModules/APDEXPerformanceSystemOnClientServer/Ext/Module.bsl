
#Region Public

// Activates the timing of a key operation whith remarks
//
// Parameters:
//  pKeyOperation		 - CatalogRef.APDEXKeyOperations - key operation or String - the name of the key operation
//  pRemarks			 - String						 - String(256) for recording arbitrary information when taking measurements
//  pWeight				 - Number						 - Weight
//  pMeasurementShift	 - Array - Array items structure 
// 
// Returns:
//  Date, Number - start time with milliseconds or seconds precision depending on the platform version.
//
Function StartTimeIntervalMeasurementWithRemarks(pKeyOperation, pRemarks, pWeight = Undefined, pMeasurementShift = Undefined) Export
	Return StartTimeIntervalMeasurement(pKeyOperation,, pRemarks, , pWeight, pMeasurementShift);
EndFunction

// Activates the timing of a key operation.
//
// Parameters:
//  pKeyOperation		 - CatalogRef.APDEXKeyOperations - key operation or String - the name of the key operation
//  pUUID				 - UUID							 - 
//  pRemarks			 - String						 - String(256) for recording arbitrary information when taking measurements
//  pAutoCompletion		 - Boolean						 - 
//  pWeight				 - Number						 - Weight
//  pMeasurementShift	 - Array						 - Array items structure								 -
// 
// Returns:
//  Date, Number - start time with milliseconds or seconds precision depending on the platform version.
//
Function StartTimeIntervalMeasurement(pKeyOperation = Undefined, pUUID = Undefined, pRemarks = Undefined, pAutoCompletion = True, pWeight = Undefined, pMeasurementShift = Undefined) Export
	If pUUID = Undefined Then
		pUUID = New UUID("00000000-0000-0000-0000-000000000000");
	EndIf;
	
	If TypeOf(pUUID) <> Type("UUID") Then
		Raise НСтр("en = 'Wrong type of UID metering.'; de = 'Falsche Messtyp-UID.'; ru = 'Неверный тип УИДа замера.'");
	EndIf;
	
	vTimeStart = 0;
	If APDEXPerformanceSystemOnServerReuse.UseAPDEX() Then
		vDateFrom = TimerValue(False);
		vTimeStart = TimerValue();
		#If Client Then
			If Not ValueIsFilled(pKeyOperation) Then
				Raise NStr("en = 'Key operation not specified. '; de = 'Tastenbedienung nicht angegeben.'; ru = 'Не указана ключевая операция.'");
			EndIf;
			
			If pMeasurementShift <> Undefined Then
				vTimeStart = vTimeStart + pMeasurementShift;			
			EndIf;
			
			vParamName = "TimeIntervalMeasurement";  
			If APDEXParameters[vParamName] = Undefined Then
				APDEXParameters.Insert(vParamName, New Structure);
				APDEXParameters[vParamName].Insert("Measurement", New Map);
								
				vCurPeriod = APDEXPerformanceSystemFullRights.RecordingPeriod();
				APDEXParameters[vParamName].Insert("PeriodRecord", vCurPeriod);
				
				vDateOnServer = APDEXPerformanceSystemFullRights.DateOnServer();
				vDateOnClient = CurrentDate();
				APDEXParameters[vParamName].Insert("DateOffset", vDateOnServer - vDateOnClient);
				
				AttachIdleHandler("ResultWriteNotGlobalAuto", vCurPeriod, True);
			EndIf;
			vMeasurements = APDEXParameters[vParamName]["Measurement"]; 
						
			vBufferKeyOperation = vMeasurements.Get(pKeyOperation);
			If vBufferKeyOperation = Undefined Then
				vBufferKeyOperation = New Map;
				vMeasurements.Insert(pKeyOperation, vBufferKeyOperation);
			EndIf;
			
			vDateOffset = APDEXParameters[vParamName]["DateOffset"];
			vDateFrom = vDateFrom + vDateOffset;
			vMeasurementIsStart = vBufferKeyOperation.Get(vDateFrom);
			If vMeasurementIsStart = Undefined Then
				vBuffer = New Map;
				vBuffer.Insert("MeasurementUUID", pUUID);
				vBuffer.Insert("TimeStart", vTimeStart);
				vBuffer.Insert("Remarks", pRemarks);
				vBuffer.Insert("Weight", pWeight);
				vBufferKeyOperation.Insert(vDateFrom, vBuffer);
			EndIf;
			
			If pAutoCompletion Then
				AttachIdleHandler("FinishTimeIntervalMeasurementAuto", 0.1, True);
			EndIf;
		#EndIf
	EndIf;

	Return vTimeStart;
	
EndFunction 

// Activates the timing of the key operation with an explicit completion of the duration of the key operation.
//
// Parameters:
//  pKeyOperation	 - CatalogRef.APDEXKeyOperations - key operation or String - the name of the key operation
//  pUUID			 - UUID							 - 
//  pRemarks		 - String						 - String(256) for recording arbitrary information when taking measurements
//  pWeight			 - Number						 - Weight
// 
// Returns:
//  Date, Number - start time with milliseconds or seconds precision depending on the platform version.
//
Function StartManualTimeIntervalMeasurement(pKeyOperation, pUUID, pRemarks = Undefined, pWeight = Undefined) Export
	Return StartTimeIntervalMeasurement(pKeyOperation, pUUID, pRemarks, False, pWeight);
EndFunction

// Activates the timing of a key operation whith remarks
//
// Parameters:
//  pKeyOperation	 - CatalogRef.APDEXKeyOperations - key operation or String - the name of the key operation
//  pUUID			 - UUID							 - 
//  pRemarks		 - String						 - String(256) for recording arbitrary information when taking measurements
//  pWeight			 - Number						 - Weight
// 
// Returns:
//  Date, Number - start time with milliseconds or seconds precision depending on the platform version.
//
Function StartManualTimeIntervalMeasurementWithRemarks(pKeyOperation, pUUID, pRemarks, pWeight = Undefined) Export
	Return StartManualTimeIntervalMeasurement(pKeyOperation, pUUID, pRemarks, pWeight);
EndFunction

// The procedure ends time measurement on the server and records the result on the server
//
// Parameters:
//  pKeyOperation	 - CatalogRef.APDEXKeyOperations - key operation or String - the name of the key operation
//  pTimeFrom		 - Date, Number					 - 
//  pRemarks		 - String						 - String(256) for recording arbitrary information when taking measurements
//  pWeight			 - Number						 - Weight
//
Procedure FinishTimeIntervalMeasurement(pKeyOperation, pTimeFrom, pRemarks = Undefined, pWeight = Undefined) Export
	If APDEXPerformanceSystemOnServerReuse.UseAPDEX() Then 	
		vDateTo = TimerValue(False);
		vTimeTo = TimerValue();
		If TypeOf(pTimeFrom) = Type("Number") Then
			vDuration = (vTimeTo - pTimeFrom);
			vDateFrom = vDateTo - vDuration;
		Else                                                                   
			vDuration = (vDateTo - pTimeFrom);
			vDateFrom = pTimeFrom;
		EndIf;
		APDEXPerformanceSystemFullRights.KeyOperationDurationCommit(pKeyOperation, vDuration, vDateFrom, vDateTo, pRemarks,	pWeight);
	EndIf;
EndProcedure

// The function is called when timing starts and ends
//
// Parameters:
//  pHighAccuracy	 - Boolean	 - High accuracy
// 
// Returns:
//  Date - measurement start time.
//
Function TimerValue(pHighAccuracy = True) Export
	If pHighAccuracy Then
		vTimerValue = CurrentUniversalDateInMilliseconds() / 1000.0;
		Return vTimerValue;
	Else
		#If Server Или ThickClientOrdinaryApplication Or ExternalConnection Then
			Return CurrentSessionDate();
		#Else
			Return CurrentDate();
		#EndIf
	EndIf;
EndFunction

#EndRegion