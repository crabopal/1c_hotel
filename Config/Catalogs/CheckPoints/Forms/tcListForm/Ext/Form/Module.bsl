
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		// Hide elements marked for deletion
		vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilter.LeftValue		= New DataCompositionField("DeletionMark");
		vNewFilter.ComparisonType	= DataCompositionComparisonType.Equal;
		vNewFilter.RightValue		= False;
		vNewFilter.Use				= True;
		vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure UpdateList(pCommand)
	UpdateListAtServer();
	ShowMessageBox(, NStr("en='Completed!'; ru='Обновление выполнено!'; de='Aktualisierung abgeschlossen!'"));
EndProcedure // UpdateList

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateListAtServer()
	Catalogs.CheckPoints.mmLoadFromDictionary();
EndProcedure // UpdateListAtServer

#EndRegion
