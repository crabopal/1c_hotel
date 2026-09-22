
#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadCodes(Command)
	LoadCodesAtServer();
	Items.List.Refresh();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Clear(Command)
	ClearAtServer();
	Items.List.Refresh();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure LoadCodesAtServer()
	InformationRegisters.CodesFMS.pmRun();
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ClearAtServer()
	vRecordManager = InformationRegisters.CodesFMS.CreateRecordSet();
	vRecordManager.Read();
	vRecordManager.Clear();
	vRecordManager.Write();
EndProcedure

#EndRegion
