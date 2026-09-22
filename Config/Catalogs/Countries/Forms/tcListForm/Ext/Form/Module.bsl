
#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure UpdateCountriesList(pCommand)
	// Ask for language code
	vLanguageCode = "Ru";
	vLanguages = New ValueList();
	vLanguages.Add("Ru", NStr("en='Load country names in Russian (RU)'; ru='Загрузить названия стран на русском (RU)'; de='Ländernamen auf Russisch herunterladen (RU)'"));
	vLanguages.Add("En", NStr("en='Load country names in English (EN)'; ru='Загрузить названия стран на английском (EN)'; de='Ländernamen auf English herunterladen (EN)'"));
	ThisForm.ShowChooseFromMenu(New NotifyDescription("UpdateCountriesListAfterLanguageChoice", ThisForm), vLanguages);
EndProcedure // UpdateCountriesList

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateCountriesListAtServer(pLanguageCode)
	Catalogs.Countries.UpdateCountriesList(pLanguageCode);
EndProcedure // UpdateCountriesListAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure UpdateCountriesListAfterLanguageChoice(pLanguageItem, pExtraParams) Export
	If pLanguageItem <> Undefined Then
		UpdateCountriesListAtServer(pLanguageItem.Value);
		ShowMessageBox(, NStr("en='Completed!'; ru='Выполнено!'; de='Fertiggestellt!'"), 3);
		Items.Tree.Refresh();
		Items.List.Refresh();
	EndIf;
EndProcedure // UpdateCountriesListAfterLanguageChoice

#EndRegion
