// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill report attributes from parameters
	FillingParameters();
	
	// Initialize report attributes
	vRepObj = FormAttributeToValue("ReportObj");
	If vRepObj.Report.IsEmpty() Then
		If Not vRepObj.Report.IsExternal Then
			vRepObj.Report = Catalogs.Reports[TrimAll(vRepObj.Metadata().Name)];
		EndIf;
	EndIf;
	vRepObj.pmLoadReportAttributes();
	
	ValueToFormAttribute(vRepObj, "ReportObj");	
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer 
Procedure FillingParameters()
	vFillingValues = Undefined;
	If Parameters.Property("FillingValues", vFillingValues) And TypeOf(vFillingValues) = Type("Structure") Then
		If vFillingValues.Property("ReportRef") Then
			ReportObj.Report = vFillingValues.ReportRef;
		EndIf;	
	EndIf;
EndProcedure // FillingParameters	

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveSettingsAtServer()
	vRepObj = FormAttributeToValue("ReportObj");
	If ValueIsFilled(vRepObj.Report) Then
		vRepObj.pmSaveReportAttributes();
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(Command)
	SaveSettingsAtServer();
EndProcedure
