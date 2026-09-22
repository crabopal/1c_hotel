
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vRepObj = FormAttributeToValue("ReportObj");
	FillingParameters(vRepObj);
	ValueToFormAttribute(vRepObj,"ReportObj");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	OnOpen_AtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpen_AtServer()	
	vRepObj = FormAttributeToValue("ReportObj");
	FillingParameters(vRepObj);	
	cmLoadReportAttributes(vRepObj);
	ValueToFormAttribute(vRepObj,"ReportObj");
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) Then
		If vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
			GenerateAtServer(ReportSpreadsheet);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = GetFileName();
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, ReportSpreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsXLSX(pCommand)
	vFilePath = GetFileName();
	vFileType = SpreadsheetDocumentFileType.XLSX;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, ReportSpreadsheet);
EndProcedure // SaveAsXLSX

// -----------------------------------------------------------------------------
&AtClient
Procedure Generate(pCommand)
	GenerateAtServer(ReportSpreadsheet);
EndProcedure // Generate

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveReportSettings(pCommand)
	SaveReportSettingsAtServer();
EndProcedure // SaveReportSettings

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer 
Procedure FillingParameters(pRepObj)
	vFillingValues = "";
	If Parameters.Property("FillingValues", vFillingValues) And Parameters.FillingValues.Count() > 0 Then
		If vFillingValues.Property("ReportRef") Then
			pRepObj.Report = vFillingValues.ReportRef;
		EndIf;
	EndIf;
EndProcedure // FillingParameters

// -----------------------------------------------------------------------------
&AtServer 
Function GetFileName()
	vFilePath = StrReplace(cmGetValidFileName(cmNStr(TrimAll(ReportObj.Report))), " ", "_") + "_" + Format(CurrentDate(),"DF=dd.MM.yyyy_HH.mm");
	Return vFilePath;
EndFunction // GetFileName

// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateAtServer(pSpreadsheet)
	vObj = FormAttributeToValue("ReportObj");	
		
	If NOT CheckReportSettings() Then
		Return;
	EndIf;
	
	pSpreadsheet.Clear();
			
	// Fill spreadsheet
	vObj.ComposeResult(pSpreadsheet);
	
	// Apply report print settings and do output other then on screen
	vOutputOnScreen = cmApplyReportPrintSettingsAndDoOutput(vObj, pSpreadsheet, 
	                                                        PageOrientation["Portrait"],
	                                                        1, 
	                                                        True, 
	                                                        NStr("ru='Ежедневный доход';de='Tageseinkommen';en='Daily income'"));
EndProcedure // GenerateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveReportSettingsAtServer()
	vObject = FormAttributeToValue("ReportObj"); 
	If ValueIsFilled(vObject.Report) Then
		vObject.pmSaveReportAttributes();
	EndIf;
EndProcedure // SaveReportSettingsAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckReportSettings()
	
	vSettings = ReportObj.SettingsComposer.GetSettings();
	
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
			If vAddPeriod.StartDate <> Undefined Then
				vParameter.Value = True;
			Else
				vParameter.Value = False;	
			EndIf;
		EndIf;
		
	EndDo;

	Return True;
	
EndFunction

#EndRegion

