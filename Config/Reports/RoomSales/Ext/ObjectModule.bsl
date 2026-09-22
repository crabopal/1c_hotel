// -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure OnComposeResult(pResultDocument, pDetailsData, pStandardProcessing)
	
	pStandardProcessing = False;
	
	pResultDocument.Clear();	
	
	vSchema 			= GetTemplate("MainDataCompositionSchema");
	vSettings 			= SettingsComposer.GetSettings();
	vExternalDataSets	= Undefined;
	FillReportSettings(vSettings);
	pDetailsData		= New DataCompositionDetailsData;
	vTemplateComposer   = New DataCompositionTemplateComposer;
	vTemplate			= vTemplateComposer.Execute(vSchema, vSettings, pDetailsData);
	vComposer			= New DataCompositionProcessor;
	vComposer.Initialize(vTemplate, vExternalDataSets, pDetailsData, True);
	vDocOutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	vDocOutputProcessor.SetDocument(pResultDocument);
	vDocOutputProcessor.Output(vComposer);
	
EndProcedure

Function FillReportSettings(pSettings)
	
	vSettings = pSettings;
	
	vMainPeriod = New Structure("StartDate, EndDate", Undefined, Undefined);
	vAddPeriod 	= New Structure("StartDate, EndDate", Undefined, Undefined);
	vHotel		= Undefined;

	For each vParameter in vSettings.DataParameters.Items Do
		If String(vParameter.Parameter) = "MainPeriod" Then
			FillPropertyValues(vMainPeriod, vParameter.Value);
		EndIf;
		
		If String(vParameter.Parameter) = "AddPeriod" Then
			FillPropertyValues(vAddPeriod, vParameter.Value);
		EndIf;
		
		If String(vParameter.Parameter) = "Hotel" Then
			vHotel = vParameter.Value;
		EndIf;
	EndDo;
	
	If vAddPeriod.StartDate <> Undefined AND vMainPeriod.StartDate <> Undefined Then
		If vAddPeriod.StartDate >= vMainPeriod.StartDate AND vAddPeriod.StartDate <= vMainPeriod.EndDate Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Comparasing period cannot cross with the report period!'; ru = 'Период сравнение не может пересекаться с периодом отчета!'"));
			Return False;
		EndIf;
		
		If vAddPeriod.EndDate <= vMainPeriod.EndDate AND vAddPeriod.EndDate >= vMainPeriod.StartDate Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Comparasing period cannot cross with the report period!'; ru = 'Период сравнение не может пересекаться с периодом отчета!'"));
			Return False;
		EndIf;
	EndIf;
	
	vForecastStartDate = tcOnServer.GetForecastStartDate(vHotel);
	
	For each vParameter in vSettings.DataParameters.Items Do
		
		If String(vParameter.Parameter) = "ForecastPeriodFrom" Then
			vParameter.Value = Max(BegOfDay(vMainPeriod.StartDate), vForecastStartDate);
		EndIf;
		
		If String(vParameter.Parameter) = "ForecastPeriodTo" Then
			vParameter.Value = ?(ValueIsFilled(vMainPeriod.EndDate), Max(vMainPeriod.EndDate, EndOfDay(vForecastStartDate-24*3600)), '00010101')
		EndIf;
		
		If String(vParameter.Parameter) = "UseForecast" Then
			If vMainPeriod.EndDate > CurrentSessionDate() Then
				vParameter.Value = True;
			Else
				vParameter.Value = False;	
			EndIf;
		EndIf
		;
		If String(vParameter.Parameter) = "UseAdditional" Then
			If ValueIsFilled(vAddPeriod.StartDate) Then
				vParameter.Value = True;
			Else
				vParameter.Value = False;	
			EndIf;
		EndIf;
		
	EndDo;

	Return True;
	
EndFunction
