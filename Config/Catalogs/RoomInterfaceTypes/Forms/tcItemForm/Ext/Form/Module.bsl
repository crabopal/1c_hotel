
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	Refresh();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers
		
// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalSystemOnChange(pItem)
	Refresh();		
EndProcedure // ExternalSystemOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure InterfaceTypeOnChange(pItem)
	If Object.InterfaceType = PredefinedValue("Enum.InterfaceTypes.Yandex") Then
		If IsBlankString(Object.TurnOnParameters) Then
			Object.TurnOnParameters = "/b2b/api/public/rooms/activate";	
		EndIf;  
		If IsBlankString(Object.TurnOffParameters) Then
			Object.TurnOffParameters = "/b2b/api/public/rooms/reset";	
		EndIf;
	EndIf;	
EndProcedure   

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeExtraParameters(pCommand)
	If Not ValueIsFilled(Object.ExternalSystem) Then
		Return;	
	EndIf;    
	
	vDataProcessor = tcOnServer.cmGetAttributeByRef(Object.ExternalSystem, "DataProcessor");
	If Not ValueIsFilled(vDataProcessor) Then
		Return;	
	EndIf; 
	
	vNameDataProcessor = GetNameDataProcessor(vDataProcessor, "tcExtraSettingsForm");
	If vNameDataProcessor = Undefined Then
		Return;	
	EndIf;       
	
	vParametrs = New Structure("DataProcessor, InteractionParameters, ExtraParameters, RoomInterfaceType", vDataProcessor, Object.ExternalSystem, Object.ExtraParameters, Object.Ref);
	vNotifyDescription = New NotifyDescription("AfterChangeExtraParameters", ThisForm);
	OpenForm(vNameDataProcessor, vParametrs, ThisForm, UUID,,, vNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);   
EndProcedure // ChangeExtraParameters

#EndRegion 

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChangeExtraParameters(pJSON, pExtraParameters) Export 
	If pJSON <> Undefined Then
		Object.ExtraParameters = TrimAll(pJSON); 		
	EndIf;
EndProcedure // AfterChangeExtraParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure Refresh()
	Items.ExtraParameters.TextEdit = Not ValueIsFilled(Object.ExternalSystem);
	Items.FormChangeExtraParameters.Enabled = CheckFormChangeExtraParameters(Object.ExternalSystem);
EndProcedure // Refresh

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckFormChangeExtraParameters(pExternalSystem)
	If Not ValueIsFilled(pExternalSystem) Then
		Return False;	
	EndIf;   
	
	vDataProcessor = pExternalSystem.DataProcessor;
	If Not ValueIsFilled(vDataProcessor) Then
		Return False;	
	EndIf;
	
	vObjDataProcessor = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDataProcessor);
	If vObjDataProcessor = Undefined Then
		Return False;	
	EndIf;
	
	vFormExists = vObjDataProcessor.Metadata().Forms.Find("tcExtraSettingsForm"); 
	If vFormExists = Undefined Then
		Return False;
	EndIf;  
	
	Return True;
EndFunction // CheckFormChangeExtraParameters

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetNameDataProcessor(pDataProcessor, pFormName = "")
	Return Catalogs.DataProcessors.GetNameDataProcessorByProcessing(pDataProcessor, pFormName);	
EndFunction // GetNameDataProcessor

#EndRegion     
