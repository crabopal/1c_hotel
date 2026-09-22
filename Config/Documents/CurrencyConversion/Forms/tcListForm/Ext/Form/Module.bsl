
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintReport(pCommand)
	vReportRef = PredefinedValue("Catalog.Reports.ForeignCurrencyExchange");
	OpenForm("Report.ForeignCurrencyExchange.Form.tcReportForm", New Structure("FillingValues, GenerateOnOpen", New Structure("ReportRef", vReportRef), True));
EndProcedure // PrintReport

#EndRegion

