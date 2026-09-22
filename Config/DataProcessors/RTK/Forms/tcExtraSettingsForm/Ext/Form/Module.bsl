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
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
		
	vParameters = Undefined;
	If Parameters.Property("ExtraParameters") And ValueIsFilled(TrimAll(Parameters.ExtraParameters)) Then
		vParameters = JSONToMap(TrimAll(Parameters.ExtraParameters));					
	EndIf;
	
	If vParameters <> Undefined Then
		a1 = ?(vParameters["a1"] <> Undefined, vParameters["a1"], 0);
		a2 = ?(vParameters["a2"] <> Undefined, vParameters["a2"], "deny");
		a3 = ?(vParameters["a3"] <> Undefined, vParameters["a3"], 0);
		a8 = ?(vParameters["a8"] <> Undefined, vParameters["a8"], 3);
	Else
		SetDefaultParameters();	
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Change(pCommand)
	vExtraParametersMap = New Map;
	vExtraParametersMap.Insert("a1", a1);
	vExtraParametersMap.Insert("a2", a2);
	vExtraParametersMap.Insert("a3", a3);
	vExtraParametersMap.Insert("a8", a8);
	Close(MapToJSON(vExtraParametersMap));  
EndProcedure // Change

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDefaultParameters()
	a1 = 0;
	a2 = "deny";
	a3 = 0;
	a8 = 3;
EndProcedure // SetDefaultParameters 

// -----------------------------------------------------------------------------
&AtClient
Function MapToJSON(pMap)
	#IF NOT WebClient Then
		Try
			vJSONWriter = New JSONWriter;
			vJSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
			WriteJSON(vJSONWriter, pMap);
			Return vJSONWriter.Close();	
		Except
			Return "";
		EndTry; 
	#ELSE
		Return "";	
	#ENDIF
EndFunction // MapToJSON

// -----------------------------------------------------------------------------
&AtServer
Function JSONToMap(pJSON)
	#IF NOT WebClient Then
		Try
			vJSONReader = New JSONReader();
			vJSONReader.SetString(pJSON);
			Return ReadJSON(vJSONReader, True);	
		Except
			Return Undefined;	
		EndTry;
	#ELSE
		Return Undefined;	
	#ENDIF
EndFunction // JSONToMap

#EndRegion 
