#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	vCurPres = Data.Description;
	If Not IsBlankString(vCurPres) Then
		vDescription = NStr(vCurPres, SessionParameters.CurrentLanguage);
		If IsBlankString(vDescription) Then
			Presentation = vCurPres;
		Else
			Presentation = vDescription;
		EndIf;	
		StandardProcessing = False;
	EndIf;	
EndProcedure // PresentationGetProcessing

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
Function CreateDataProcessorByProcessing(pDataProcessor, pLoadData = False) Export 
	vDPO = Undefined;
	If ValueIsFilled(pDataProcessor) And ValueIsFilled(pDataProcessor.Processing) Then
		If pDataProcessor.IsExternal And TypeOf(pDataProcessor.Processing) = Type("CatalogRef.ExternalDataProcessors") Then 
			vEDPR = pDataProcessor.Processing;
			vURL = GetURL(vEDPR, "ExternalProcessingStorage"); 
			vName = ExternalDataProcessors.Connect(vURL, cmGetValidName(vEDPR.FileName), False);
			vDPO = ExternalDataProcessors.Create(vName);	
		ElsIf Not pDataProcessor.IsExternal And TypeOf(pDataProcessor.Processing) = Type("String") Then 
			vDPO = DataProcessors[pDataProcessor.Processing].Create();
		EndIf;
	EndIf;
	If vDPO <> Undefined And pLoadData Then 
		vDPO.DataProcessor = pDataProcessor;
		vDPO.pmLoadDataProcessorAttributes();
	EndIf;
	Return vDPO;
EndFunction // CreateDataProcessorByProcessing

// --------------------------------------------------------------------------------
Function GetNameDataProcessorByProcessing(pDataProcessor, pFormName = "") Export 
	vDPN = Undefined;
	If ValueIsFilled(pDataProcessor) And ValueIsFilled(pDataProcessor.Processing) Then
		If pDataProcessor.IsExternal And TypeOf(pDataProcessor.Processing) = Type("CatalogRef.ExternalDataProcessors") Then 
			vEDPR = pDataProcessor.Processing;
			vURL = GetURL(vEDPR, "ExternalProcessingStorage"); 
			vName = ExternalDataProcessors.Connect(vURL, cmGetValidName(vEDPR.FileName), False);	
			vDPN = "ExternalDataProcessor." + vName + ".Form" + ?(Not IsBlankString(pFormName), "." + pFormName, "");
		ElsIf Not pDataProcessor.IsExternal And TypeOf(pDataProcessor.Processing) = Type("String") Then 
			vDPN = "DataProcessor." + pDataProcessor.Processing + ".Form" + ?(Not IsBlankString(pFormName), "." + pFormName, "");
		EndIf;
	EndIf;      
	Return vDPN;
EndFunction // GetNameDataProcessorByProcessing

#EndRegion

