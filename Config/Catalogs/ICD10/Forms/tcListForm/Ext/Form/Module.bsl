
#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure UpdateClassifier(Command)
	UpdateClassifierAtServer();
	Items.List.Refresh();
	ShowMessageBox(, NStr("en = 'ICD classifier was updated!'; 
						  |de = 'Update des ICD-10 Klassifikators abgeschlossen!'; 
						  |ru = 'Обновление классификатора МКБ-10 завершено!'"));
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateClassifierAtServer()
	Catalogs.ICD10.UpdateClassifier("Version10Ru", 5);
EndProcedure

#EndRegion
