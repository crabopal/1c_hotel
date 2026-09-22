
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	vObj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If Parameters.Property("DataProcessor", vDataProcessor) Then
		vObj.DataProcessor = vDataProcessor;
	EndIf;
	vObj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(vObj, "Object");
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
    	vObj.pmRun();
    	pCancel = True;
	EndIf;
EndProcedure //  OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	HotelClearingAtServer(pStandardProcessing);
EndProcedure // HotelClearing

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	If ValueIsFilled(Object.DataProcessor) Then
		SaveSettingsAtServer();
	EndIf;
EndProcedure //  SaveSettings 

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	vStructureMessage = tcOnClient.ExtendInHouseGuestsPeriodOfStay(Object.Hotel, Object.FreeOfChargeCheckOutDelay);
	If Not IsBlankString(vStructureMessage.Message) Then
		tcCommonFunctionOnClientServer.TextMessage(vStructureMessage.Message);
	EndIf;
	If  vStructureMessage.ListStatus Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'There are no guests whose stay time is over, but the free delay time is not over yet'; de = 'Es gibt keine Gäste, die keine Zeit mehr haben, aber die Zeit der kostenlosen Verspätung ist noch nicht abgelaufen'; ru = 'Нет гостей, у которых время проживания закончилось, но время бесплатной задержки еще не вышло'"));
	EndIf;

	Notify("Subsystem.Accounts.Changed");
EndProcedure // ActionsExecute

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveSettingsAtServer()
	If ValueIsFilled(Object.DataProcessor) Then
		// Save DP parameters
		vObj = FormAttributeToValue("Object");
		vObj.pmSaveDataProcessorAttributes();
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // SaveSettingsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelClearingAtServer(pStandardProcessing)
	If Not IsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // HotelClearingAtServer

#EndRegion    
