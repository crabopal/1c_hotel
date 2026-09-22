// -----------------------------------------------------------------------------
&AtServer   
Procedure DeleteAllAtServer();
	// Delete all records
	vManager = InformationRegisters.CurrentPhoneNumberStatuses.CreateRecordManager();
	vSet = InformationRegisters.CurrentPhoneNumberStatuses.CreateRecordSet();
	vSet.Read();
	For Each vRow In vSet Do
		vManager.PhoneNumber = vRow.PhoneNumber;
		vManager.Delete();
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteAll(pCommand)
	pCancel = True;
	// Ask for confirmation
	ShowQueryBox(New NotifyDescription("DeleteAllAfterUserAnswer", ThisForm), NStr("en='Delete all records for all phone numbers?';ru='Удалить все записи для всех тел. номеров?';de='Alle Aufzeichnungen für alle Telefonnummern löschen?'"), QuestionDialogMode.YesNo);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteAllAfterUserAnswer(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	DeleteAllAtServer();
	Items.InformationRegisterList.Refresh(); 
EndProcedure // DeleteAllAfterUserAnswer

// -----------------------------------------------------------------------------
&AtServer   
Procedure DeleteSelectedAtServer(pSelectedRows);
	// Delete selected records
	vManager = InformationRegisters.CurrentPhoneNumberStatuses.CreateRecordManager();
	For Each vRow In pSelectedRows Do
		vManager.PhoneNumber = vRow.PhoneNumber;
		vManager.Delete();
	EndDo;
EndProcedure // DeleteSelectedAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
	vSelectedRows = Items.InformationRegisterList.SelectedRows;
	If vSelectedRows.Count() > 1 Then
		ShowQueryBox(New NotifyDescription("ListBeforeDeleteRowAfterUserAnswer", ThisForm, vSelectedRows), NStr("en='Delete selected rows?';ru='Удалить выбранные строки?';de='Ausgewählte Zeilen löschen?'"), QuestionDialogMode.YesNo);
	ElsIf vSelectedRows.Count() = 1 Then
		ShowQueryBox(New NotifyDescription("ListBeforeDeleteRowAfterUserAnswer", ThisForm, vSelectedRows), NStr("en='Delete selected row?';ru='Удалить выбранную строку?';de='Ausgewählte Zeile löschen?'"), QuestionDialogMode.YesNo);
	Else
		ShowMessageBox(, NStr("en='There is no selected row!';ru='Выберите строку!';de=' Wählen Sie die Zeile!'"));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRowAfterUserAnswer(pUserAnswer, pSelectedRows) Export
	If pUserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	DeleteSelectedAtServer(pSelectedRows);
	Items.InformationRegisterList.Refresh();  
EndProcedure // ListBeforeDeleteRowAfterUserAnswer
