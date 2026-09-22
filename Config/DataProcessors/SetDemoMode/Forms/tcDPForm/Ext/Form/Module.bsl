
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Try
		// Load DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmLoadDataProcessorAttributes();
		ValueToFormAttribute(Obj,"Object");
	Except
		Obj.pmFillAttributesWithDefaultValues();
		ValueToFormAttribute(Obj,"Object");
	EndTry;   
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		ReadOnly = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

//-----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure Run(pCommand)
	RunAtServer();
	// Processing completed
	ShowMessageBox(, NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure 

#EndRegion

#Region Private

//-----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	// Save DP parameters
	Try
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
	Except
	EndTry;
EndProcedure

//-----------------------------------------------------------------------------
&AtServer
Procedure RunAtServer()
	// Save DP parameters
	Obj = FormAttributeToValue("Object");
	Obj.pmRun();
EndProcedure

#EndRegion  
