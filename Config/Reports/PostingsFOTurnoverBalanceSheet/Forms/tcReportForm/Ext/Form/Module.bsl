#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    // Fill report attributes from parameters
	FillingParameters();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
    OnOpenAtServer();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, MessageText, StandardProcessing)
    ThisObject.VariantModified = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(Command)
    SaveSettingsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = GetFileName(TrimAll(ReportObj.Report));
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, Result);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsXLSX(pCommand)
	vFilePath = GetFileName(TrimAll(ReportObj.Report));
	vFileType = SpreadsheetDocumentFileType.XLSX;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, Result);
EndProcedure // SaveAsXLSX

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveSettingsAtServer()
    FormAttributeToValue("ReportObj").pmSaveReportAttributes();
    ThisForm.VariantModified = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenAtServer()
   vReportObj = FormAttributeToValue("ReportObj");
   vReportObj.pmLoadReportAttributes();
   ValueToFormAttribute(vReportObj,"ReportObj");
   ComposeResult();
EndProcedure

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
&AtServerNoContext
Function GetFileName(pRepName)
	vFilePath = StrReplace(cmGetValidFileName(cmNStr(pRepName)), " ", "_") + "_" + Format(CurrentSessionDate(),"DF=dd.MM.yyyy_HH.mm");
	Return vFilePath;
EndFunction // GetFileName

#EndRegion