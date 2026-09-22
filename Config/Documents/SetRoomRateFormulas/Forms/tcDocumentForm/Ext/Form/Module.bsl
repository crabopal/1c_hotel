
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Fill attributes from parameters
	If Parameters.Property("RoomRate") Then
		 Object.RoomRate = Parameters.RoomRate;
	EndIf;
	If ValueIsFilled(Object.RoomRate) And Not ValueIsFilled(Object.RoomRate.BasedOnRoomRate) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Select bound room rate!'; ru='Выберите тариф по связям!'; de='Gebundenen Tariff auswählen!'"));
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
			Return;
		EndIf;
	EndIf;
	 
	// Write button appearance
	If Object.Posted Then
		Items.FormWrite.Enabled = False;
		Items.FormWrite.Visible = False;
	EndIf;
   	Items.ChangeProtection.Visible = False;
	
	vObject = FormAttributeToValue("Object");
	
	// Check user rights to use document
	If vObject.IsNew() Then
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage prices!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
		EndIf;		
		vObject.SetTime(AutoTimeMode.DontUse);
		If Not ValueIsFilled(vObject.Author) Then
			vObject.pmFillAttributesWithDefaultValues();
		Else
			vObject.pmFillAuthorAndDate();
		EndIf;				
		If ValueIsFilled(vObject.RoomRate) Then
			GetDefaultDocumentDate(vObject);
		EndIf;
	EndIf;
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(vObject.Hotel) And SessionParameters.CurrentHotel <> vObject.Hotel Then
			pCancel = True;
		EndIf;
	EndIf;
	
	ValueToFormAttribute(vObject, "Object");
	
	OldDate = Object.Date;
	
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	Else
		// Check if there are any reservation with Price calculation date grater than document date.
		If NOT vObject.IsNew() Then
			If RatesManagement.IsRoomRateInUse(vObject.Date, vObject.RoomRate) Then
				ReadOnly = True;
				Items.ChangeProtection.Visible = True;
			EndIf;
		EndIf;
		// Check user rights to edit room rates
		If Not cmCheckUserPermissions("HavePermissionToApproveRoomRates") Then
			Items.RoomRatesApproved.Enabled = False;
		Else
			Items.RoomRatesApproved.Enabled = True;
		EndIf;
	EndIf;
	
	// Client types choice
	vClientTypes = GetClientTypes();
	Items.ClientType.ChoiceList.Add(Catalogs.ClientTypes.EmptyRef(), NStr("en = 'Empty client type'; ru = 'Пустой тип клиента'; de = 'Leerer Kundentyp!'"));	
	For Each vClientTypesRow In vClientTypes Do
		Items.ClientType.ChoiceList.Add(vClientTypesRow.ClientType, TrimAll(vClientTypesRow.Description));
	EndDo;
	Items.ClientType.ColumnsCount = vClientTypes.Count() + 1;
	
	// Document form appearance
	DocumentMode = 0;
	If Object.Discount <> 0 Then
		DocumentMode = 1;
	ElsIf Object.Formulas.Count() > 0 Then
		DocumentMode = 2;
	EndIf;
	SetDocumentFormAppearanceAtServer();
	
	// Appearance of prices are approved items
	RoomRatesApprovedAppearance();
	
	// Fill room type parent column
	FillRoomTypeParentColumn("Formulas");
	
	// Set default filter by empty client type
	SetFilter();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// APDEX
		vKeyOperation = "Document.SetRoomRateFormulas.Form.tcDocumentForm.Posting";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Not ReadOnly Then
		vCopyValueButton = Items.FormulasCopy;
		vPasteValueButton = Items.FormulasPaste;
		If amClipboard.Property("SetRoomRateFormulasFormulas") Then
			vCopyValueButton.Check = True;
			vPasteValueButton.Enabled = True;
			vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SetRoomRateFormulasActionRestore" Then		
		Restore(pParameter);		
	ElsIf pEventName = "SetRoomRateFormulasCopyRows" Then
		If Not ReadOnly Then
			vCopyValueButton = Items.FormulasCopy;
			vPasteValueButton = Items.FormulasPaste;
			If amClipboard.Property("SetRoomRateFormulasFormulas") Then
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
			EndIf;
		EndIf;
	ElsIf pEventName = "SetRoomRateFormulasCopyRowsFormulas" Then
		If Not ReadOnly Then
			vCopyValueButton = Items.FormulasCopy;
			vPasteValueButton = Items.FormulasPaste;
			If amClipboard.Property("SetRoomRateFormulasFormulas") Then
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
			EndIf;
		EndIf;
	ElsIf pEventName = "SetRoomRateFormulasCancelCopyRowsFormulas" Then
		vCopyValueButton = Items.FormulasCopy;
		vPasteValueButton = Items.FormulasPaste;
		ColumnCopiedFormulas = Undefined;
		ValueCopiedFormulas = Undefined;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	// Check document attributes
	vMessage = "";
	vAttributeInErr = "";
	pCancel = pCurrentObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
	If pCancel Then
		SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
		vUM = New UserMessage();
		vUM.SetData(pCurrentObject);
		vUM.Field = vAttributeInErr;
		vUM.Text = NStr(vMessage);
		vUM.Message();
	Else
		If pCurrentObject.Date > CurrentSessionDate() Then
			pCurrentObject.IsInFuture = True;
		Else
			pCurrentObject.IsInFuture = False;
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	pCurrentObject.pmWriteToSetRoomRateFormulasChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
EndProcedure // AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Document.SetRoomRateFormulas.Write", Object.Ref, ThisObject);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	SetFilter();	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypeOnChange(pItem)
	SetFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomClassOnChange(pItem)
	SetFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(pItem)
	SetFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceOnChange(pItem)
	SetFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasOnStartEdit(pItem, pNewRow, pClone)
	pItem.CurrentData.Char1 = " = (";
	pItem.CurrentData.Char2 = "+";
	pItem.CurrentData.Char3 = ") x";
	pItem.CurrentData.Char4 = "+";
	If pNewRow Then
		pItem.CurrentData.ClientType = ClientType;	
	EndIf;
EndProcedure // FormulasOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesApprovedOnChange(pItem)
	RoomRatesApprovedAppearance();
	GetDefaultDocumentDate();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	RoomRateOnChangeAtServer();
EndProcedure // RoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentModeOnChange(pItem)
	SetDocumentFormAppearanceAtServer();
EndProcedure // DocumentModeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	Object.Number = "";
EndProcedure // HotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasRoomClassOnChange(pItem)
	vCurRow = Items.Formulas.CurrentData;
	If ValueIsFilled(vCurRow.RoomClass) Then
		vCurRow.RoomType = Undefined;
	EndIf;
EndProcedure // FormulasRoomClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasRoomTypeOnChange(pItem)
	vCurRow = Items.Formulas.CurrentData;
	If ValueIsFilled(vCurRow.RoomType) Then
		vCurRow.RoomClass = Undefined;
	EndIf;
EndProcedure // FormulasRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasOnEditEnd(pItem, pNewRow, pCancelEdit)
	TabularPartRowOnEditEnd("Formulas");
EndProcedure // FormulasOnEditEnd

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FillCopyForFormulas(pCommand)	
	// Clear rows for client type selected
	vRows = Object.Formulas.FindRows(New Structure("ClientType", ClientType));
	If vRows.Count() > 0 Then
		vText = NStr("en='Clear rows for client type selected?';ru='Удалить строки для выбранного типа клиента?';de='Zeilen für den ausgewählten Kundentyp löschen?'");
		ShowQueryBox(New NotifyDescription("DeleteAnswerCopyForFormulas", ThisObject), vText, QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
	Else
		Items.ClientType.ChoiceList.ShowChooseItem(New NotifyDescription("ClientTypeForFormulasAnswer", ThisObject), NStr("en='Choose client type';ru='Выберите тип клиента';de='Wählen Sie den Kundentyp'"));		
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeForFormulas(pCommand)
	vFormulasList = New ValueList();
	For Each vRow In Object.Formulas Do
		If ValueIsFilled(vRow.RoomType) Then
			If vFormulasList.FindByValue(vRow.RoomType) = Undefined Then
				vFormulasList.Add(vRow.RoomType);
			EndIf;
		EndIf;
	EndDo;
	vFormulasList.ShowChooseItem(New NotifyDescription("FillByTemplateRoomTypeForFormulasAnswer", ThisObject),NStr("en='Choose template room type';ru='Выберите тип номера - шаблон';de='Wählen Sie die Zimmertyp - Vorlage'"));			
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassForFormulas(pCommand)
	vFormulasList = New ValueList();
	For Each vRow In Object.Formulas Do
		If ValueIsFilled(vRow.RoomClass) Then
			If vFormulasList.FindByValue(vRow.RoomClass) = Undefined Then
				vFormulasList.Add(vRow.RoomClass);
			EndIf;
		EndIf;
	EndDo;
	vFormulasList.ShowChooseItem(New NotifyDescription("FillByTemplateRoomClassForFormulasAnswer", ThisObject),NStr("en='Choose template room class';ru='Выберите класс номера - шаблон';de='Wählen Sie die Zimmerklass - Vorlage'"));			
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyFormulas(pCommand)
	vCopyValueButton = Items.FormulasCopy;
	vPasteValueButton = Items.FormulasPaste;
	amClipboard.Delete("SetRoomRateFormulasFormulas");
	If vCopyValueButton.Check Then
		ColumnCopiedFormulas = Undefined;
		ValueCopiedFormulas = Undefined;
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("SetRoomRateFormulasCancelCopyRowsFormulas", Undefined, ThisObject);
	Else
		vCurRow = Items.Formulas.CurrentRow;
		If vCurRow <> Undefined Then
			vSelectedRows = Items.Formulas.SelectedRows;
			
			If vSelectedRows.Count() > 1 Then				
				ColumnCopiedFormulas = "SelectedRows";
				ValueCopiedFormulas = GetRowsFormulas(vSelectedRows);
				amClipboard.Insert("SetRoomRateFormulasFormulas", ValueCopiedFormulas);
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
				Notify("SetRoomRateFormulasCopyRowsFormulas", ValueCopiedFormulas, ThisObject);				
			Else
				ColumnCopiedFormulas = StrReplace(Items.Formulas.CurrentItem.Name, "Formulas", "");
				ValueCopiedFormulas = Items.Formulas.CurrentData[ColumnCopiedFormulas];
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste ';ru='Вставить ';de='Einsetzen '") + TrimAll(ValueCopiedFormulas);				
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Row is not selected!';ru='Не выбрана строка!';de='Keine Zeile ist gewählt!'"));
			ColumnCopiedFormulas = Undefined;
			ValueCopiedFormulas = Undefined;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PasteFormulas(pCommand)
	vCopyValueButton = Items.FormulasCopy;
	vPasteValueButton = Items.FormulasPaste;
	
	vSelectedRows = Undefined;
	
	If amClipboard.Property("SetRoomRateFormulasFormulas") Then
		UploadTableFormulas(amClipboard.SetRoomRateFormulasFormulas);
		amClipboard.Delete("SetRoomRateFormulasFormulas");
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("SetRoomRateFormulasCancelCopyRowsFormulas", Undefined, ThisObject);
	Else
		vSelectedRows = Items.Formulas.SelectedRows;
		If vSelectedRows.Count() > 0 Then
			For Each vRow In vSelectedRows Do				
				Object.Formulas.FindByID(vRow)[ColumnCopiedFormulas] = ValueCopiedFormulas;			
			EndDo;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Else
			ShowMessageBox(, NStr("en='There is no selected rows!';ru='Нет выделенных строк!';de='Es gibt keine markierten Zeilen!'"));
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyDocument(Command) 
	If ValueIsFilled(Object.Ref) Then
		OpenForm("Document.SetRoomRateFormulas.ObjectForm", New Structure("CopyingValue", Object.Ref));       
		Close();
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDocumentFormAppearanceAtServer()
	If DocumentMode = 0 Then
		If Object.Discount <> 0 Then
			Object.Discount = 0;
		EndIf;
		If Object.Formulas.Count() > 0 Then
			Object.Formulas.Clear();
		EndIf;
		Items.GroupDiscount.Visible = False;
		Items.GroupFormulas.Visible = False;
	ElsIf DocumentMode = 1 Then
		If Object.Formulas.Count() > 0 Then
			Object.Formulas.Clear();
		EndIf;
		Items.GroupDiscount.Visible = True;
		Items.GroupFormulas.Visible = False;
	Else
		If Object.Discount <> 0 Then
			Object.Discount = 0;
		EndIf;
		Items.GroupDiscount.Visible = False;
		Items.GroupFormulas.Visible = True;
	EndIf;
EndProcedure // SetDocumentFormAppearanceAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomTypeParentColumn(pTabularPartName)
	For Each vRow In Object[pTabularPartName] Do
		If ValueIsFilled(vRow.RoomType) Then
			vRowRoomType = vRow.RoomType;
			If vRowRoomType.IsFolder Then
				vRow.RoomTypeParent = vRowRoomType;
			Else
				vRow.RoomTypeParent = vRowRoomType.Parent;
			EndIf;
		Else
			vRow.RoomTypeParent = Undefined;
		EndIf;
	EndDo;		
EndProcedure // FillRoomTypeParentColumn

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomRatesApprovedAppearance()
	If Object.RoomRatesApproved Or ValueIsFilled(Object.RoomRate) And Object.RoomRate.RoomRatesApproved Then
		Items.Hotel.ReadOnly = True;
		Items.RoomRate.ReadOnly = True;
		Items.Formulas.ReadOnly = True;
		Items.FormulasFillCopyForFormulas.Enabled = False;
		Items.FormulasFillByTemplateRoomTypeForFormulas.Enabled = False;
		Items.FormulasFillByTemplateRoomClassForFormulas.Enabled = False;
		Items.FormulasCopy.Enabled = False;
		Items.FormulasPaste.Enabled = False;
	Else
		Items.Hotel.ReadOnly = False;
		Items.RoomRate.ReadOnly = False;
		Items.Formulas.ReadOnly = False;
		Items.FormulasFillCopyForFormulas.Enabled = True;
		Items.FormulasFillByTemplateRoomTypeForFormulas.Enabled = True;
		Items.FormulasFillByTemplateRoomClassForFormulas.Enabled = True;
		Items.FormulasCopy.Enabled = True;
		Items.FormulasPaste.Enabled = True;
	EndIf;
EndProcedure // RoomRatesApprovedAppearance

// -----------------------------------------------------------------------------
&AtServer
Function GetClientTypes()
	vQry = New Query();
	vQry.Text = 
	"   SELECT
	|		ClientTypes.Ref AS ClientType,
	|		ClientTypes.IsFolder AS IsFolder,
	|		ClientTypes.Code AS Code,
	|		ClientTypes.Description AS Description,
	|		ClientTypes.SortCode AS SortCode
	|	FROM
	|		Catalog.ClientTypes AS ClientTypes
	|	WHERE
	|		ClientTypes.DeletionMark = FALSE
	|		AND ClientTypes.Parent = &qEmptyClientType
	|		AND (NOT &qHotelIsEmptyRef AND ClientTypes.Hotel = &qHotel 
	|		      OR ClientTypes.Hotel = &qEmptyHotel 
	|		      OR &qHotelIsEmptyRef)
	|	
	|	ORDER BY
	|		SortCode,
	|		Description";
	vQry.SetParameter("qHotel", ?(Object.Hotel = Catalogs.Hotels.EmptyRef(), SessionParameters.CurrentHotel, Object.Hotel));
	vQry.SetParameter("qHotelIsEmptyRef", ?(Object.Hotel = Catalogs.Hotels.EmptyRef(), True, False));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qEmptyClientType", Catalogs.ClientTypes.EmptyRef());
	vElements = vQry.Execute().Unload();
	// Check user permissions
	vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermissionGroup) Then
		If vPermissionGroup.ClientTypesAllowed.Count() > 0 Then
			i = 0;
			While i < vElements.Count() Do
				vRow = vElements.Get(i);
				If Not vRow.IsFolder And vPermissionGroup.ClientTypesAllowed.Find(vRow.ClientType, "ClientType") = Undefined Then
					vElements.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;	
	Return vElements;
EndFunction // GetClientTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure GetDefaultDocumentDate(pObject = Undefined)
	vObject = pObject;
	If pObject = Undefined Then
		vObject = Object;
	EndIf;
	If Not ValueIsFilled(vObject.Date) Then
		vObject.Date = CurrentSessionDate();
		DateOnChangeAtServer(vObject);
	EndIf;
EndProcedure // GetDefaultDocumentDate

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer(pObject = Undefined)
	vObject = pObject;
	If pObject = Undefined Then
		vObject = Object;
	EndIf;
	// Automatically assign new document number if year has changed
	If ValueIsFilled(vObject.Date) Then
		If ValueIsFilled(OldDate) And Year(OldDate) <> Year(vObject.Date) Then
			If TypeOf(vObject) = Type("DocumentObject.SetRoomRateFormulas") Then
				vObject.SetNewNumber();
			Else
				vObj = FormAttributeToValue("Object");
				vObj.SetNewNumber();
				ValueToFormAttribute(vObj, "Object");
				vObject = Object;
			EndIf;
		EndIf;
		OldDate = vObject.Date;
		If vObject.Date > CurrentSessionDate() Then
			vObject.IsInFuture = True;
			Items.Date.ToolTip = NStr("en='Prices will be effective after the specified date and time'; 
			                          |ru='Цены вступят в силу после указанной даты и времени'; 
									  |de='Die Preise werden nach dem angegebenen Datum und der angegebenen Uhrzeit wirksam'");
			Items.Date.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		Else
			vObject.IsInFuture = False;
			Items.Date.ToolTip = "";
			Items.Date.ToolTipRepresentation = ToolTipRepresentation.None;
		EndIf;
	EndIf;
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetFilter()
	vFilter = New Structure();	
	vFilter.Insert("ClientType", ClientType);	
	If ValueIsFilled(AccommodationType) Then
		vFilter.Insert("AccommodationType", AccommodationType);	
	EndIf;	
	If ValueIsFilled(RoomClass) Then
		vFilter.Insert("RoomClass", RoomClass);	
	EndIf;	
	If ValueIsFilled(RoomType) Then
		If RoomType.IsFolder Then
			vFilter.Insert("RoomTypeParent", RoomType);
		Else
			vFilter.Insert("RoomType", RoomType);	
		EndIf;
	EndIf;	
	If ValueIsFilled(Service) Then
		vFilter.Insert("Service", Service);	
	EndIf;
	vFilterStruct = New FixedStructure(vFilter);
	Items.Formulas.RowFilter = vFilterStruct;	
EndProcedure // SetFilter

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomRateOnChangeAtServer()
	If ValueIsFilled(Object.RoomRate) And Not ValueIsFilled(Object.RoomRate.BasedOnRoomRate) Then
		Object.RoomRate = Undefined;
		vUM = New UserMessage();
		vUM.SetData(FormAttributeToValue("Object"));
		vUM.Field = "RoomRate";
		vUM.Text = NStr("en='Select bound room rate!'; ru='Выберите тариф по связям!'; de='Gebundenen Tariff auswählen!'");
		vUM.Message();
	Else
		RoomRatesApprovedAppearance();
		GetDefaultDocumentDate();	
	EndIf;
EndProcedure // RoomRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure Restore(pDate)
	vObj = FormAttributeToValue("Object");	
	vRChg = InformationRegisters.SetRoomRateFormulasChangeHistory;
	vRChgRec = vRChg.Get(pDate, New Structure("SetRoomRateFormulas", vObj.Ref));
	vObj.pmRestoreAttributesFromHistory(vRChgRec);
	ValueToFormAttribute(vObj, "Object");	
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteAnswerCopyForFormulas(pAnswer, pParametr) Export 	
	If pAnswer = DialogReturnCode.Yes Then			
		Items.ClientType.ChoiceList.ShowChooseItem(New NotifyDescription("ClientTypeForFormulasAnswer", ThisObject), NStr("en='Choose client type';ru='Выберите тип клиента';de='Wählen Sie den Kundentyp'"));		
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeForFormulasAnswer(pAnswer, pParametr) Export
	If pAnswer <> Undefined Then
		FillAsCopyForFormulasAction(pAnswer.Value);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Procedure FillAsCopyForFormulasAction(pClientType)
	// Clear rows for client type selected
	vRows = Object.Formulas.FindRows(New Structure("ClientType", ClientType));
	For Each vRow In vRows Do
		Object.Formulas.Delete(vRow);
	EndDo;
	// Retrieve rows of the type choosen
	vRows = Object.Formulas.FindRows(New Structure("ClientType", pClientType));
	For Each vRow In vRows Do
		vNewRow = Object.Formulas.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.ClientType = ClientType;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeForFormulasAnswer(pAnswer,pParametr) Export
	If pAnswer <> Undefined Then
		// APDEX
		vKeyOperation = "Catalog.RoomTypes.Form.tcChoiceForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", New Structure("Hotel", Object.Hotel), ThisObject, , , , New NotifyDescription("FillByTemplateRoomTypeForFormulasAnswer2", ThisObject, pAnswer.Value));	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomTypeForFormulasAnswer2(pAnswer, pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplateRoomTypeForFormulasAction(pAnswer, pParametr);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateRoomTypeForFormulasAction(pNewRoomType, pTemplateRoomType)
	vRows = Object.Formulas.FindRows(New Structure("ClientType, RoomType", ClientType, pTemplateRoomType));
	For Each vRow In vRows Do
		vNewRow = Object.Formulas.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.RoomType = pNewRoomType;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassForFormulasAnswer(pAnswer,pParametr) Export
	If pAnswer <> Undefined Then
		OpenForm("Catalog.RoomTypeClasses.Form.tcChoiceForm", New Structure("Hotel", Object.Hotel), ThisObject, , , , New NotifyDescription("FillByTemplateRoomClassForFormulasAnswer2", ThisObject, pAnswer.Value));	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillByTemplateRoomClassForFormulasAnswer2(pAnswer, pParametr) Export
	If ValueIsFilled(pAnswer) Then
		FillByTemplateRoomClassForFormulasAction(pAnswer, pParametr);	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillByTemplateRoomClassForFormulasAction(pNewRoomClass, pTemplateRoomClass)
	vRows = Object.Formulas.FindRows(New Structure("ClientType, RoomClass", ClientType, pTemplateRoomClass));
	For Each vRow In vRows Do
		vNewRow = Object.Formulas.Add();
		FillPropertyValues(vNewRow, vRow, , "LineNumber");
		vNewRow.RoomClass = pNewRoomClass;
	EndDo;
	// Filter
	SetFilter();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TabularPartRowOnEditEnd(pTPName)
	vCurRowID = Items[pTPName].CurrentRow;
	If vCurRowID <> Undefined Then
		vCurRow = Object[pTPName].FindByID(vCurRowID);
		If ValueIsFilled(vCurRow.RoomType) Then
			If tcOnServer.cmGetAttributeByRef(vCurRow.RoomType, "IsFolder") Then
				vCurRow.RoomTypeParent = vCurRow.RoomType;
			Else
				vCurRow.RoomTypeParent = tcOnServer.cmGetAttributeByRef(vCurRow.RoomType, "Parent");
			EndIf;
		Else
			vCurRow.RoomTypeParent = Undefined;
		EndIf;
	EndIf;
EndProcedure // TabularPartRowOnEditEnd

// -----------------------------------------------------------------------------
&AtServer
Procedure UploadTableFormulas(pTempStorage)
	vTable = GetFromTempStorage(pTempStorage);	
	For Each vRow In vTable Do
		vNewRow = Object.Formulas.Add();
		FillPropertyValues(vNewRow, vRow);
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetRowsFormulas(val vSelectedRows)
	vRows = New Array;
	For Each vRow In vSelectedRows Do
		vRows.Add(Object.Formulas.FindByID(vRow));	
	EndDo;
	Return PutToTempStorage(Object.Formulas.Unload(vRows), New UUID); 	
EndFunction

#EndRegion
 