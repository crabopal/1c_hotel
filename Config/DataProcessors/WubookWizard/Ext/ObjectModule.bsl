#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameters
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

//  ----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// ----------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Structure - Parameters
//  pIsInteractive	 - Boolean	 - Is interactive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	SyncChanges();
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - Result
//
Function SyncChanges() Export
	If ValueIsFilled(ThisObject.InteractionParameters) and ValueIsFilled(ThisObject.Login) and ValueIsFilled(ThisObject.Password) and ValueIsFilled(ThisObject.HotelCode) Then
		If NOT ThisObject.InteractionParameters.IsActive Then
			vInteractionParametersObj = ThisObject.InteractionParameters.GetObject();
			vInteractionParametersObj.IsActive = True;
			vInteractionParametersObj.Write();
		EndIf;
		
		If ThisObject.FullSyncPeriod > 0 and ThisObject.InteractionParameters.LastFullSynchronizationTime + 60*60*ThisObject.FullSyncPeriod < CurrentSessionDate() Then
			Return WuBook.SyncAllForPeriod(ThisObject.Login, ThisObject.Password, ThisObject.InteractionParameters.WSHost, "1CHOTEL", ThisObject.HotelCode, ThisObject.InteractionParameters, BegOfDay(CurrentSessionDate()), BegOfDay(CurrentSessionDate() + 24*60*60*ThisObject.SyncPeriod), ThisObject.SyncRates, True, GetVacantRoomsAtMidnight);
		Else
			Return WuBook.SyncChanges(ThisObject.Login, ThisObject.Password, ThisObject.InteractionParameters.WSHost, "1CHOTEL", ThisObject.HotelCode, ThisObject.InteractionParameters, True, ThisObject.SyncRates, ThisObject.SyncRestrictions, ThisObject.SyncPeriod, True, GetVacantRoomsAtMidnight);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill all settings!'; ru = 'Введите все настройки!'"));
	EndIf;
	Return Undefined;
EndFunction // SyncChanges

#EndRegion