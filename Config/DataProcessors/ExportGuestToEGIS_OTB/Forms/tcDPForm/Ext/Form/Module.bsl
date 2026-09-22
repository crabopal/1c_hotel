
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
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	Object.PeriodFrom = Date(1,1,1);
	Object.PeriodTo = Date(1,1,1);
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
    	Obj.pmRun();
    	pCancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveFilePathStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	tcOnClientWorkWithFiles.cmChooseDirectoryOnClient("SaveFilePath",Object);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodOnChange(Item)
	Object.PeriodFrom = BegOfDay(Period.StartDate);
	Object.PeriodTo = EndOfDay(Period.EndDate);
EndProcedure

#EndRegion
 
#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Unload(pCommand)
	ClearMessages();
	If Not ThisForm.CheckFilling() Then
		Return;
	EndIf;	
	If ValueIsFilled(Object.PeriodFrom) And ValueIsFilled(Object.PeriodTo) Then
		Unload_AtServer();
	Else
		vUserMessage 		= New UserMessage;
		vUserMessage.Field 	= "Period";
		vUserMessage.Text	= NStr("en = 'Choose period to unload!'; ru = 'Выберите период выгрузки!'; de = 'Wählen Sie einen Zeitraum zum Entladen aus!'");
		vUserMessage.Message();
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure Unload_AtServer()
	vErr = False;
	Obj = FormAttributeToValue("Object");
	Obj.Unload(Object.PeriodFrom, Object.PeriodTo, SpreadsheetErrorsList, vErr);
	Obj.pmSaveDataProcessorAttributes();
	ValueToFormAttribute(Obj, "Object");
	If vErr Then
		Items.GroupPages.CurrentPage = Items.GroupErrors;
	EndIf;	
EndProcedure

#EndRegion

