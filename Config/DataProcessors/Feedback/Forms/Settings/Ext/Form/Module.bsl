
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
EndProcedure

&AtServer
Procedure SaveAtServer()
	// Save DP parameters
	Obj = FormAttributeToValue("Object");
	Obj.pmSaveDataProcessorAttributes();
EndProcedure

&AtClient
Procedure Save(pCommand)
	SaveAtServer();
EndProcedure

