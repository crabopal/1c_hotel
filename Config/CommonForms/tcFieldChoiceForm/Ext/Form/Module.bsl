
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	IsField = False;
	IsFilter = False;
	IsDimension = False;
	IsRowDimension = False;
	IsColumnDimension = False;
	IsOrder = False;
	IsConditionalAppearance = False;
	
	// Fill form attributes
	FillPropertyValues(ThisForm, Parameters);
	If IsBlankString(AvailableFieldsAddress) Then
		pCancel = True;
		Return;
	EndIf;
	IsDimension = IsRowDimension Or IsColumnDimension;
	If IsField Then
		Mode = "Field";
	ElsIf IsFilter Then
		Mode = "Filter";
	ElsIf IsRowDimension Then
		Mode = "RowDimension";
	ElsIf IsColumnDimension Then
		Mode = "ColumnDimension";
	ElsIf IsOrder Then
		Mode = "Order";
	ElsIf IsConditionalAppearance Then
		Mode = "ConditionalAppearance";
	Else
		Mode = "";
	EndIf;
	
	// Restore available fields value tree
	vAvailableFields = GetFromTempStorage(AvailableFieldsAddress);
	If vAvailableFields = Undefined Or TypeOf(vAvailableFields) <> Type("ValueTree") Then
		pCancel = True;
		Return;
	EndIf;
	AvailableFields.GetItems().Clear();
	For Each vAvailableFieldsRow In vAvailableFields.Rows Do
		AddFieldToValueTree(AvailableFields.GetItems(), vAvailableFieldsRow);
	EndDo;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AvailableFieldsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	FieldSelection(Commands.FieldSelection);
EndProcedure // AvailableFieldsSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure AvailableFieldsBeforeExpand(pItem, pRowId, pCancel)
	vRowData = Items.AvailableFields.RowData(pRowId);
	vRowDataItems = vRowData.GetItems();
	If vRowDataItems.Count() = 1 Then
		vItemsValueList = AvailableFieldsBeforeExpandAtServer(vRowData.ValueType, vRowData.DataPath);
		If vItemsValueList.Count() > 1 Then
			vFirstChildItem = vRowDataItems.Get(0);
			For Each vItemsValueListItem In vItemsValueList Do
				vStruct = vItemsValueListItem.Value;
				If vStruct.DataPath <> vFirstChildItem.DataPath Then
					vNewChildItem = vRowDataItems.Add();
					FillPropertyValues(vNewChildItem, vStruct);
					If vStruct.ChildStruct <> Undefined Then
						vNewChildItem = vNewChildItem.GetItems().Add();
						FillPropertyValues(vNewChildItem, vStruct.ChildStruct);
					EndIf;
				Else
					If vStruct.ChildStruct <> Undefined Then
						vNewChildItem = vFirstChildItem.GetItems().Add();
						FillPropertyValues(vNewChildItem, vStruct.ChildStruct);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // AvailableFieldsBeforeExpand

#EndRegion  

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldSelection(pCommand)
	vCurData = Items.AvailableFields.CurrentData;
	If vCurData <> Undefined Then
		NotifyChoice(New Structure("Report, Mode, Name, DataPath, Presentation, ValueType, ValueList", Report, Mode, vCurData.Name, vCurData.DataPath, vCurData.Presentation, vCurData.ValueType, vCurData.ValueList));
	EndIf;
EndProcedure // FieldSelection

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetSynonym(pStr)
	If pStr = "IsFolder" Then
		Return NStr("en='Is folder'; ru='Это группа'; de='Ist Ordner'");
	ElsIf pStr = "Parent" Then
		Return NStr("en='Parent'; ru='Родитель'; de='Elternteil'");
	ElsIf pStr = "Code" Then
		Return NStr("en='Code'; ru='Код'; de='Code'");
	ElsIf pStr = "Description" Then
		Return NStr("en='Description'; ru='Наименование'; de='Beschreibung'");
	ElsIf pStr = "DeletionMark" Then
		Return NStr("en='Deletion mark'; ru='Пометка удаления'; de='Löschzeichen'");
	ElsIf pStr = "Number" Then
		Return NStr("en='Number'; ru='Номер'; de='Nummer'");
	ElsIf pStr = "Date" Then
		Return NStr("en='Date'; ru='Дата'; de='Datum'");
	ElsIf pStr = "Posted" Then
		Return NStr("en='Posted'; ru='Проведен'; de='Posted'");
	EndIf;
	Return pStr;
EndFunction // GetSynonym

// --------------------------------------------------------------------------------
&AtServer
Procedure AddFieldToValueTree(pRows, pRow)
	If (IsField And pRow.Field) Or 
	   (IsFilter And pRow.Filter) Or 
	   (IsDimension And pRow.Dimension) Or
	   (IsOrder And pRow.Order) Then
		vFieldRow = pRows.Add();
		FillPropertyValues(vFieldRow, pRow);
		For Each vRowRow In pRow.Rows Do
			AddFieldToValueTree(vFieldRow.GetItems(), vRowRow);
		EndDo;
	EndIf;
EndProcedure // AddFieldToValueTree

// --------------------------------------------------------------------------------
&AtServerNoContext
Function AvailableFieldsBeforeExpandAtServer(pValueType, pBasePath)
	vPathesUsed = New ValueList();
	vItemsList = New ValueList();
	vTypes = pValueType.Types();
	For Each vType In vTypes Do
		vMetadata = Metadata.FindByType(vType);
		For Each vMetadataItem In vMetadata.StandardAttributes Do
			If vMetadataItem.Name = "PredefinedDataName" Or vMetadataItem.Name = "Predefined" Or vMetadataItem.Name = "Ref" Then
				Continue;
			EndIf;
			ProcessMetadataItem(vMetadataItem, vItemsList, pBasePath, vPathesUsed);
		EndDo;
		For Each vMetadataItem In vMetadata.Attributes Do
			ProcessMetadataItem(vMetadataItem, vItemsList, pBasePath, vPathesUsed);
		EndDo;
	EndDo;
	Return vItemsList;
EndFunction // AvailableFieldsBeforeExpandAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure ProcessMetadataItem(vMetadataItem, vItemsList, pBasePath, vPathesUsed)
	vChildStruct = Undefined;
	vPath = pBasePath + "." + vMetadataItem.Name;
	If vPathesUsed.FindByValue(vPath) = Undefined Then
		vPathesUsed.Add(vPath);
		vItemTypes = vMetadataItem.Type.Types();
		vChildMetadata = Metadata.FindByType(vItemTypes[0]);
		If vChildMetadata <> Undefined Then
			Try
				vChildMetadataItem = vChildMetadata.Attributes.Get(0);
				vChildStruct = New Structure("Name, DataPath, Presentation, ValueType, ValueList", 
				                             vChildMetadataItem.Name,
				                             vPath + "." + vChildMetadataItem.Name,
				                             ?(IsBlankString(vChildMetadataItem.Synonym), GetSynonym(vChildMetadataItem.Name), vChildMetadataItem.Synonym),
				                             vChildMetadataItem.Type,
				                             Undefined);
			Except
			EndTry;
		EndIf;
		vStruct = New Structure("Name, DataPath, Presentation, ValueType, ValueList, ChildStruct", 
		                        vMetadataItem.Name,
								vPath,
								?(IsBlankString(vMetadataItem.Synonym), GetSynonym(vMetadataItem.Name), vMetadataItem.Synonym),
								vMetadataItem.Type,
								Undefined,
								vChildStruct);
		vItemsList.Add(vStruct);
	EndIf;
EndProcedure // ProcessMetadataItem

#EndRegion
