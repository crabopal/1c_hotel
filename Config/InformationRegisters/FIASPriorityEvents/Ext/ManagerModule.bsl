// -----------------------------------------------------------------------------
Procedure AddEvent(pUUID, pInteractionParameters, pKeyCoder, pWorkstationID, pRequest, pCommandType, pDate, pIsCommandSent = False) Export

	If Not ValueIsFilled(pUUID) Or NOT ValueIsFilled(pInteractionParameters) Then
		Return;
	EndIf;
	
	vRecSet = InformationRegisters.FIASPriorityEvents.CreateRecordSet();
	vRecSet.Filter.KeyCoder.Set(pKeyCoder);
	vRecSet.Write(True);
	
	vRecMng = InformationRegisters.FIASPriorityEvents.CreateRecordManager();
	vRecMng.InteractionParameters = pInteractionParameters;
	vRecMng.CommandUUID = pUUID; 
	vRecMng.KeyCoder = pKeyCoder;
	vRecMng.WorkstationID = pWorkstationID;
	vRecMng.Request = pRequest;
	vRecMng.CommandType = pCommandType;    
	vRecMng.IsCommandSent = pIsCommandSent; 
	vRecMng.Date = pDate;
	vRecMng.Write(True);	
	
EndProcedure // AddEvent        

// -----------------------------------------------------------------------------
Procedure DeleteEvent(pUUID, pInteractionParameters) Export

	If Not ValueIsFilled(pUUID) Or NOT ValueIsFilled(pInteractionParameters) Then
		Return;
	EndIf;
	
	vRecSet = InformationRegisters.FIASPriorityEvents.CreateRecordSet();
	vRecSet.Filter.CommandUUID.Use				= True;
	vRecSet.Filter.CommandUUID.Value			= pUUID;
	vRecSet.Filter.InteractionParameters.Use	= True;
	vRecSet.Filter.InteractionParameters.Value	= pInteractionParameters; 
	vRecSet.Read();
	vRecSet.Clear();
	vRecSet.Write(True);
	
EndProcedure // DeleteEvent      

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR
EndProcedure // ExchangePlansRecordChanges