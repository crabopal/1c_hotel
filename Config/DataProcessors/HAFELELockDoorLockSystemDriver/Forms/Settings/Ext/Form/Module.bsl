
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.ExternalInteraction = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	LoadInteractionParameters();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	If Debug Then
		Active = True;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	If NOT Active Then
		Debug = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure // Save

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	
	If NOT CheckFilling() Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		SaveInteractionParameters();
				
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
				
		Obj.pmSaveDataProcessorAttributes();
		CommitTransaction();
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage("Failed to save:" + vError);
		RollbackTransaction();
	EndTry;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	vIntParObj						= Object.ExternalInteraction.GetObject();
	vIntParObj.IsActive				= Active;
	vIntParObj.Hotel				= Hotel;
	vIntParObj.DebugMode			= Debug; 
	vIntParObj.MaxLogLenght			= MaxLogLenght;
	vIntParObj.Write();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If NOT ValueIsFilled(Object.ExternalInteraction) Then
		Return;
	EndIf;
	
	Hotel				= Object.ExternalInteraction.Hotel;
	Active				= Object.ExternalInteraction.IsActive;
	Debug				= Object.ExternalInteraction.DebugMode;
	MaxLogLenght		= Object.ExternalInteraction.MaxLogLenght;    
EndProcedure

#EndRegion


