&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
		Obj.pmRun();
		pCancel = True;
	EndIf;
EndProcedure

&AtServer
Procedure SaveAtServer()
	Obj = FormAttributeToValue("Object");
	Obj.pmSaveDataProcessorAttributes();
EndProcedure

&AtClient
Procedure Save(Command)
	SaveAtServer();
EndProcedure

