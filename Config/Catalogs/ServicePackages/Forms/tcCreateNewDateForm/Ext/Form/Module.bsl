
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelDate = CurrentSessionDate();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Choose(pCommand)
	If ValueIsFilled(SelDate) Then 
		ThisForm.Close(SelDate);
	Else
		ShowMessageBox(, NStr("en = 'Date should be filled!'; de = 'Das Datum muss angegeben werden!'; ru = 'Дата должна быть указана!'"));
	EndIf;
EndProcedure // Choose

// --------------------------------------------------------------------------------
&AtClient
Procedure CancelChoice(pCommand)
	Close(Undefined);
EndProcedure

#EndRegion
