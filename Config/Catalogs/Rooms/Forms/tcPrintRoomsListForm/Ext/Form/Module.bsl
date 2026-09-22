
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("TableBoxRooms") Then
		FillTableBoxRooms(Parameters.TableBoxRooms);	
	EndIf;
 	If Parameters.Property("SelFilter1") Then
		SelFilter1 = Parameters.SelFilter1;	
	EndIf;
	 If Parameters.Property("SelFilter2") Then
		SelFilter2 = Parameters.SelFilter2;	
	EndIf;
	If Parameters.Property("SelFilter3") Then
		SelFilter3 = Parameters.SelFilter3;	
	EndIf;
	If Parameters.Property("UseBedsSetup") Then
		UseBedsSetup = Parameters.UseBedsSetup;	
	EndIf;
	PageOrientationStr = "Portrait";
	FillColumns();
	FillColumnsPresentation();
	PrintRoomsList();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadSettings(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		LoadSettingsAtServer(pItem.Value);
		PrintRoomsList();
	EndIf;
EndProcedure // LoadSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCheckColumnsStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure("MultipleChoice, Title, ValueList", True, NStr("en = 'Check Columns...'; de = 'Markieren Säulen...'; ru = 'Отметьте колонки...'"), SelColumns);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID, , , New NotifyDescription("ColumnsStartChoice_AfterInput", ThisForm));
EndProcedure // SelCheckColumnsStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCheckColumnsClearing(pItem, pStandardProcessing)
	SelColumns.FillChecks(False);
	FillColumnsPresentation();
	PrintRoomsList();
EndProcedure // SelCheckColumnsClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure NotPrintFoldersOnChange(pItem)
	PrintRoomsList();
EndProcedure // NotPrintFoldersOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PageOrientationOnChange(pItem)
	PrintRoomsList();
EndProcedure // PageOrientationOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	Spreadsheet.Print();
	Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	Spreadsheet.Print(PrintDialogUseMode.Use);
	Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	tcOnClient.SaveSpreadsheetToFile(SpreadsheetDocumentFileType.PDF, NStr("en = 'Rooms list'; de = 'Zimmerliste'; ru = 'Список номеров'"), Spreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionSaveSettings(pCommand)
	// Ask user to give name to the current settings
	ShowInputString(New NotifyDescription("ActionSaveSettingsAtServer", ThisForm), "", NStr("en='Please give name to your settings!';ru='Пожалуйста укажите название новой настройки!';de='Bitte geben Sie den Namen der neuen Einstellung ein!'"), 150, False)		
EndProcedure // ActionSaveSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionLoadSettings(pCommand)
	vListSettings = ListSettings();
	If vListSettings.Count() > 0 Then
		vListSettings.ShowChooseItem(New NotifyDescription("LoadSettings", ThisForm),,vListSettings);
	Else
		ShowMessageBox(, NStr("en = 'Saved settings not found'; de = 'Gespeicherte Einstellungen nicht gefunden'; ru = 'Сохраненные настройки не найдены'"));
	EndIf;
EndProcedure // ActionLoadSettings

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintRoomsList()
	Spreadsheet.Clear();
	Spreadsheet.FitToPage = True;
	If ValueIsFilled(PageOrientationStr) Then
		If PageOrientationStr = "Portrait" Then
			Spreadsheet.PageOrientation = PageOrientation.Portrait;
		ElsIf PageOrientationStr = "Landscape" Then 
			Spreadsheet.PageOrientation = PageOrientation.Landscape;
		Else
			Spreadsheet.PageOrientation = PageOrientation.Portrait;
		EndIf;
	Else
		Spreadsheet.PageOrientation = PageOrientation.Portrait;	
	EndIf;
	vTemplate = Catalogs.Rooms.GetTemplate("PrintRoomsList");
	vHeader = vTemplate.GetArea("TopHeader|Description");
	vCountCels = 0;
	For Each vRow In SelColumns Do
		If vRow.Check Then
			vCountCels = vCountCels + 1;	
		EndIf;
	EndDo;
	If vCountCels = 0 Then
		vCountCels = 1;	
	EndIf;
	
	vHeader.Parameters.mFilter1 = SelFilter1;
	vHeader.Parameters.mFilter2 = SelFilter2;
	vHeader.Parameters.mFilter3 = SelFilter3;
	vHeader.Parameters.mDate = CurrentSessionDate();
	Spreadsheet.Put(vHeader);
	vHeaderSpreadsheetDocument = New SpreadsheetDocument();
	vHeaderSpreadsheetDocument.PageOrientation = Spreadsheet.PageOrientation;
	For Each vRow In SelColumns Do
		If vRow.Check Then
			vHeaderSpreadsheetDocument.Join(vTemplate.GetArea("HeaderTable|" + TrimAll(vRow.Value)));
		EndIf;
	EndDo;
	Spreadsheet.Put(vHeaderSpreadsheetDocument);
	For Each vRowRooms In TableBoxRooms Do
		If vRowRooms.IsFolder And NotPrintFolders Then
			Continue;	
		EndIf;
		vRowSpreadsheetDocument = Undefined;
		For Each vRow In SelColumns Do
			If vRow.Check Then
				If vRowSpreadsheetDocument = Undefined Then 
					vRowSpreadsheetDocument = New SpreadsheetDocument();
				EndIf;
				vRowT = vTemplate.GetArea("RowTable|" + TrimAll(vRow.Value));
				vParametrcArr = StrSplit(vRow.Value, "_", False);
				If vRow.Value <> "Remarks" Then 
					If vParametrcArr.Count() = 1 Then
						vRowT.Parameters[TrimAll(vRow.Value)] = vRowRooms[TrimAll(vParametrcArr[0])];
					ElsIf vParametrcArr.Count() = 2 Then 
						vRowT.Parameters[TrimAll(vRow.Value)] = ?(ValueIsFilled(vRowRooms[TrimAll(vParametrcArr[0])]), vRowRooms[TrimAll(vParametrcArr[0])][TrimAll(vParametrcArr[1])], "");	
					EndIf;
				Else
					vRowT.Parameters[TrimAll(vRow.Value)] = vRowRooms["Remarks"];
					If ValueIsFilled(vRowT.Parameters[TrimAll(vRow.Value)]) Then
						vRowT.Parameters[TrimAll(vRow.Value)] = vRowT.Parameters[TrimAll(vRow.Value)] + Chars.LF +  vRowRooms["TaskRemarks"];	
					Else
						vRowT.Parameters[TrimAll(vRow.Value)] = vRowRooms["TaskRemarks"];	
					EndIf;
				EndIf;
				vRowSpreadsheetDocument.Join(vRowT);
			EndIf;
		EndDo;
		If vRowSpreadsheetDocument <> Undefined Then 
			Spreadsheet.Put(vRowSpreadsheetDocument);
		EndIf;
	EndDo;
	For Each vRow In SelColumns Do
		i = SelColumns.IndexOf(vRow) + 1;
		vColumn = Spreadsheet.Area(, i, , i);
		If vRow.Value = "Description" Then
			vColumn.ColumnWidth = 12;
		ElsIf vRow.Value = "RoomType_Code" Then
			vColumn.ColumnWidth = 12;
		ElsIf vRow.Value = "RoomStatus" Then
			vColumn.ColumnWidth = 24;
		ElsIf vRow.Value = "RegularOperations" Then
			vColumn.ColumnWidth = 12;
		ElsIf vRow.Value = "Condition" Then
			vColumn.ColumnWidth = 30;
		ElsIf vRow.Value = "Remarks" Then
			vColumn.ColumnWidth = 30;
		ElsIf vRow.Value = "ClientType" Then
			vColumn.ColumnWidth = 16;
		ElsIf vRow.Value = "Customer" Then
			vColumn.ColumnWidth = 20;
		ElsIf vRow.Value = "NumberOfGuests" Then
			vColumn.ColumnWidth = 10;
		ElsIf vRow.Value = "NumberOfGuestsOnArrival" Then
			vColumn.ColumnWidth = 10;
		ElsIf vRow.Value = "Floor" Then
			vColumn.ColumnWidth = 10;
		ElsIf vRow.Value = "BedsSetup" Then
			vColumn.ColumnWidth = 16;
		ElsIf vRow.Value = "BedsSetupInReservation" Then
			vColumn.ColumnWidth = 16;
		ElsIf vRow.Value = "RoomPropertiesCodes" Then
			vColumn.ColumnWidth = 20;
		ElsIf vRow.Value = "HasRoomBlocks" Then
			vColumn.ColumnWidth = 10;
		ElsIf vRow.Value = "StopSale" Then
			vColumn.ColumnWidth = 10;
		ElsIf vRow.Value = "IsVirtual" Then
			vColumn.ColumnWidth = 10;
		ElsIf vRow.Value = "RoomStatusLastChangeTime" Then
			vColumn.ColumnWidth = 26;
		EndIf;
	EndDo;
	Spreadsheet.Area(1, 1, 1, vCountCels).Merge(); 
	Spreadsheet.Area(2, 1, 2, vCountCels).Merge();
	Spreadsheet.Area(3, 1, 3, vCountCels).Merge(); 
	Spreadsheet.Area(4, 1, 4, vCountCels).Merge();
	// Check authorities
	cmSetSpreadsheetProtection(Spreadsheet);
EndProcedure // PrintRoomsList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillColumns()
	SelColumns.Clear();
	SelColumns.Add("Description", NStr("en = 'Room'; de = 'Zimmer'; ru = 'Номер'"), True);
	SelColumns.Add("RoomType_Code", NStr("en = 'Type'; de = 'Typ'; ru = 'Тип'"), True);
	SelColumns.Add("RoomStatus", NStr("en = 'Room status'; de = 'Status des Zimmers'; ru = 'Статус номера'"), True);
	SelColumns.Add("RegularOperations", NStr("en = 'Regular'; de = 'Routine'; ru = 'Регл. раб.'"));
	SelColumns.Add("Condition", NStr("en = 'Condition'; de = 'Zustand'; ru = 'Состояние'"), True);	
	SelColumns.Add("Remarks", NStr("en = 'Remarks'; de = 'Anmerkungen'; ru = 'Примечания'"), True);
	SelColumns.Add("ClientType", NStr("en = 'Client type'; de = 'Client-Typ'; ru = 'Тип клиента'"));	
	SelColumns.Add("Customer", NStr("en = 'Customer'; de = 'Firma'; ru = 'Контрагент'"));
	SelColumns.Add("NumberOfGuests", NStr("en = 'In-house'; de = 'In-house'; ru = 'Прож.'"), True);
	SelColumns.Add("NumberOfGuestsOnArrival", NStr("en = 'On arrival'; de = 'Anreise'; ru = 'На заезде'"), True);
	SelColumns.Add("Floor", NStr("en = 'Floor'; de = 'Etage'; ru = 'Этаж'"));
	If UseBedsSetup Then
		SelColumns.Add("BedsSetup", NStr("en = 'Beds'; de = 'Betten'; ru = 'Кровати'"));
		SelColumns.Add("BedsSetupInReservation", NStr("en = 'Beds in reservation'; de = 'Betten in Reservierung'; ru = 'Кровати в брони'"));
	EndIf;
	SelColumns.Add("RoomPropertiesCodes", NStr("en = 'Properties codes'; de = 'Eigenschaftencodes'; ru = 'Коды свойств'"));
	SelColumns.Add("HasRoomBlocks", NStr("en = 'Is blocked'; de = 'Ist blockiert'; ru = 'Есть блок.'"));
	SelColumns.Add("StopSale", NStr("en = 'Out of sale'; de = 'Ausverkauft'; ru = 'Снят с прод.'"));
	SelColumns.Add("IsVirtual", NStr("en = 'Is virtual room'; de = 'Virtuelles Zimmer'; ru = 'Вирт. номер'"));
	SelColumns.Add("RoomStatusLastChangeTime", NStr("en = 'Change time'; de = 'Zeit des Statusänderung'; ru = 'Время изм.'"));
EndProcedure // FillDefaultColumns

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTableBoxRooms(pValueTree)
	For Each vRow In pValueTree.GetItems() Do
		vNewRow = TableBoxRooms.Add();
		FillPropertyValues(vNewRow, vRow); 
		FillTableBoxRooms(vRow);
	EndDo;
EndProcedure // FillTableBoxRooms

// -----------------------------------------------------------------------------
&AtServer
Function ListSettings()
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ObjectFormActions.Ref AS Ref,
	|	ObjectFormActions.Description AS Description
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	NOT ObjectFormActions.DeletionMark
	|	AND NOT ObjectFormActions.IsFolder
	|	AND ObjectFormActions.IsActive
	|	AND ObjectFormActions.ObjectType = &qObjectType
	|	AND ObjectFormActions.Code = &qCode";
	vQry.SetParameter("qObjectType", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qCode", "CRL");
	vList = vQry.Execute().Unload();
	vListSettings = new ValueList();
	For Each vListSettingsRow In vList Do
		vListSettings.Add(vListSettingsRow.Ref, vListSettingsRow.Description);
	EndDo;
	Return vListSettings; 
EndFunction // ListSettings

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadSettingsAtServer(pRef)
	If ValueIsFilled(pRef) Then
		vSettingsStruct = pRef.Settings.Get();
		If ValueIsFilled(vSettingsStruct) Then
			If vSettingsStruct.Property("SelColumns") Then
				For Each vItem In vSettingsStruct.SelColumns Do
					vItemColumn = SelColumns.FindByValue(vItem.Value);
					If vItemColumn <> Undefined Then
						vItemColumn.Check = vItem.Check;			
					EndIf;
				EndDo;
				FillColumnsPresentation();
			EndIf;
			If vSettingsStruct.Property("NotPrintFolders") Then 
				NotPrintFolders = vSettingsStruct.NotPrintFolders;
			EndIf;
			If vSettingsStruct.Property("PageOrientationStr") Then 
				PageOrientationStr = vSettingsStruct.PageOrientationStr;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // LoadSettingsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionSaveSettingsAtServer(pSettingName, pExtraParams) Export 
	If pSettingName <> Undefined And ValueIsFilled(pSettingName) Then 
		// Create item
		vSettingObj = Catalogs.ObjectFormActions.CreateItem();
		vSettingObj.Code = "CRL";
		vSettingObj.Description = pSettingName;
		vSettingObj.Parent = Catalogs.ObjectFormActions.FindByCode("400");
		vSettingObj.ObjectType = Catalogs.Rooms.EmptyRef();
		vSettingObj.IsActive = True;
		vSettingObj.Remarks = TColumnsPresentation;
		vSettingObj.Settings = New ValueStorage(GetSettingsStructure());
		vSettingObj.Write();
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Settings were saved successfully!';ru='Настройки были успешно сохранены!';de='Die Einstellungen wurden erfolgreich gespeichert!'"));
	EndIf;
EndProcedure // ActionSaveSettingsAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetSettingsStructure()
	vSettingsStruct = New Structure();
	vSettingsStruct.Insert("SelColumns", SelColumns);
	vSettingsStruct.Insert("NotPrintFolders", NotPrintFolders);
	vSettingsStruct.Insert("PageOrientationStr", PageOrientationStr);
	Return vSettingsStruct;
EndFunction // GetSettingsStructure

// -----------------------------------------------------------------------------
&AtClient
Procedure ColumnsStartChoice_AfterInput(pValueList, pExtraParametrs) Export 
	If pValueList <> Undefined Then
		For Each vItem In pValueList Do
			vItemColumn = SelColumns.FindByValue(vItem.Value);
			If vItemColumn <> Undefined Then
				vItemColumn.Check = vItem.Check;			
			EndIf;
		EndDo;	
		FillColumnsPresentation();
		PrintRoomsList();
	EndIf;
EndProcedure // ColumnsStartChoice_AfterInput

// -----------------------------------------------------------------------------
&AtServer
Procedure FillColumnsPresentation()
	// Service packages
	TColumnsPresentation = "";
	For Each ColumnsRow In SelColumns Do
		If ColumnsRow.Check Then
			If ValueIsFilled(ColumnsRow.Presentation) Then
				vTPresentation = ColumnsRow.Presentation; 
			Else
				vTPresentation = ColumnsRow.Value;	
			EndIf;
			If ValueIsFilled(vTPresentation) Then
				If IsBlankString(TColumnsPresentation) Then
					TColumnsPresentation = TrimAll(vTPresentation);
				Else
					TColumnsPresentation = TColumnsPresentation + ", " + TrimAll(vTPresentation);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillColumnsPresentation

#EndRegion
