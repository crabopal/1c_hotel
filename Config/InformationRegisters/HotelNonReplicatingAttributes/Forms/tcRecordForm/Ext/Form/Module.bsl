
&AtClient
Procedure BLOBRootFolderStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	tcOnClient.cmGetChooseDirectory(Record.BLOBRootFolder,ThisForm,"SaveFilePathStartChoice_AfterInput");
EndProcedure

&AtClient
Procedure SaveFilePathStartChoice_AfterInput(pValue, pParameters) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	Record.BLOBRootFolder = pValue[0];	
EndProcedure

