
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManagePrices") And Object.Ref.IsEmpty() Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
		pCancel = True;
	EndIf;
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Form appearance
	SetFormAttributesAppearance(); 
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Object.Hotel, "BackgroundColorImportant");

	// Fill services compact representation
	FillPreServicesFromServices();
	
	// Fill client types filter
	vClientTypes = GetClientTypes();
	Items.ClientType.ChoiceList.Add(Catalogs.ClientTypes.EmptyRef(), NStr("en = 'Empty client type'; ru = 'Пустой тип клиента'; de = 'Leerer Kundentyp!'"));	
	For Each vClientTypesRow In vClientTypes Do
		Items.ClientType.ChoiceList.Add(vClientTypesRow.ClientType, TrimAll(vClientTypesRow.Description));
	EndDo;
	Items.ClientType.ColumnsCount = vClientTypes.Count() + 1;
	
	// Get dates of price versions
	AllDates = NStr("en = '<All dates>'; de = '<Alle Termine>'; ru = '<Все даты>'");
	vDates = GetServicesDates();
	Items.PriceIsCreated.ChoiceList.Add(AllDates);
	For Each vDate In vDates Do
		Items.PriceIsCreated.ChoiceList.Add(vDate);
	EndDo;
	If Items.PriceIsCreated.ChoiceList.Count() > 1 Then
		PriceIsCreated = Items.PriceIsCreated.ChoiceList.FindByValue(GetLastDate()).Value;
	Else
		PriceIsCreated = Items.PriceIsCreated.ChoiceList.Get(0).Value;
	EndIf;
	
	// Apply filter by date
	SetFilter();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManagePrices") Then
		ShowMessageBox(, NStr("en = 'You do not have rights for services and prices management!'; 
							  |de = 'Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'; 
							  |ru = 'Нет прав на управление услугами и ценами!'"));
		ReadOnly = True;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "ServicePackageServicesCopyRows" Then
		If Not ReadOnly Then
			vCopyValueButton = Items.PreServicesButtonCopy;
			vPasteValueButton = Items.PreServicesButtonPaste;
			If amClipboard.Property("ServicePackageServices") Then
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en = 'Paste selected rows'; de = 'Gewählte Zeilen einsetzen'; ru = 'Вставить выб. строки'");
			EndIf;
		EndIf;
	ElsIf pEventName = "ServicePackageServicesCancelCopyRows" Then
		vCopyValueButton = Items.PreServicesButtonCopy;
		vPasteValueButton = Items.PreServicesButtonPaste;
		ColumnCopied = Undefined;
		ValueCopied = Undefined;
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	For Each vCurData In PreServices Do
		If CheckPreServicesRowForErrors(vCurData) Then
			pCancel = True;
			Return;
		EndIf;
	EndDo;
	FillServicesFromPreServices();
EndProcedure // BeforeWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations), pItem);	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure IsBBOnChange(pItem)
	If Object.IsBB Then
		If Object.IsHB Then	
			Object.IsHB = False;
		EndIf;
		If Object.IsFB Then	
			Object.IsFB = False;
		EndIf;
		If Object.IsAI Then	
			Object.IsAI = False;
		EndIf;
		If Object.IsUAI Then	
			Object.IsUAI = False;
		EndIf;
		If Object.IsFC Then	
			Object.IsFC = False;
		EndIf;
	EndIf;
EndProcedure // IsBBOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsHBOnChange(pItem)
	If Object.IsHB Then
		If Object.IsBB Then	
			Object.IsBB = False;
		EndIf;
		If Object.IsFB Then	
			Object.IsFB = False;
		EndIf;
		If Object.IsAI Then	
			Object.IsAI = False;
		EndIf;
		If Object.IsUAI Then	
			Object.IsUAI = False;
		EndIf;
		If Object.IsFC Then	
			Object.IsFC = False;
		EndIf;
	EndIf;
EndProcedure // IsHBOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsFBOnChange(pItem)
	If Object.IsFB Then
		If Object.IsBB Then	
			Object.IsBB = False;
		EndIf;
		If Object.IsHB Then	
			Object.IsHB = False;
		EndIf;
		If Object.IsAI Then	
			Object.IsAI = False;
		EndIf;
		If Object.IsUAI Then	
			Object.IsUAI = False;
		EndIf;
		If Object.IsFC Then	
			Object.IsFC = False;
		EndIf;
	EndIf;
EndProcedure // IsFBOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsAIOnChange(pItem)
	If Object.IsAI Then
		If Object.IsBB Then	
			Object.IsBB = False;
		EndIf;
		If Object.IsHB Then	
			Object.IsHB = False;
		EndIf;
		If Object.IsFB Then	
			Object.IsFB = False;
		EndIf;
		If Object.IsUAI Then	
			Object.IsUAI = False;
		EndIf;
		If Object.IsFC Then	
			Object.IsFC = False;
		EndIf;
	EndIf;
EndProcedure // IsAIOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsUAIOnChange(pItem)
	If Object.IsUAI Then
		If Object.IsBB Then	
			Object.IsBB = False;
		EndIf;
		If Object.IsHB Then	
			Object.IsHB = False;
		EndIf;
		If Object.IsFB Then	
			Object.IsFB = False;
		EndIf;
		If Object.IsAI Then	
			Object.IsAI = False;
		EndIf;
		If Object.IsFC Then	
			Object.IsFC = False;
		EndIf;
	EndIf;
EndProcedure // IsUAIOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsFCOnChange(pItem)
	If Object.IsFC Then
		If Object.IsBB Then	
			Object.IsBB = False;
		EndIf;
		If Object.IsHB Then	
			Object.IsHB = False;
		EndIf;
		If Object.IsFB Then	
			Object.IsFB = False;
		EndIf;
		If Object.IsAI Then	
			Object.IsAI = False;
		EndIf;
		If Object.IsUAI Then	
			Object.IsUAI = False;
		EndIf;
	EndIf;
EndProcedure // IsFCOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsMealBoardTermOnChange(pItem)
	If Object.IsMealBoardTerm Then	
		If Object.IsMedicine Then	
			Object.IsMedicine = False;
		EndIf;
		If Object.Duration <> 0 Then
			Object.Duration = 0;
		EndIf;
	Else
		If Object.IsBB Then
			Object.IsBB = False;
		EndIf;
		If Object.IsHB Then
			Object.IsHB = False;
		EndIf;
		If Object.IsFB Then
			Object.IsFB = False;
		EndIf;
		If Object.IsAI Then	
			Object.IsAI = False;
		EndIf;
		If Object.IsUAI Then	
			Object.IsUAI = False;
		EndIf;
		If Object.IsFC Then
			Object.IsFC = False;
		EndIf;
		If ValueIsFilled(Object.RoomRevenueService) Then
			Object.RoomRevenueService = PredefinedValue("Catalog.Services.EmptyRef");
		EndIf;
	EndIf;
	SetFormAttributesAppearance();
EndProcedure // IsMealBoardTermOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsMedicineOnChange(pItem)
	If Object.IsMedicine Then	
		If Object.IsMealBoardTerm Then
			Object.IsMealBoardTerm = False;
		EndIf;
		If Object.IsBB Then
			Object.IsBB = False;
		EndIf;
		If Object.IsHB Then
			Object.IsHB = False;
		EndIf;
		If Object.IsFB Then
			Object.IsFB = False;
		EndIf;
		If Object.IsAI Then	
			Object.IsAI = False;
		EndIf;
		If Object.IsUAI Then	
			Object.IsUAI = False;
		EndIf;
		If Object.IsFC Then
			Object.IsFC = False;
		EndIf;
		If ValueIsFilled(Object.RoomRevenueService) Then
			Object.RoomRevenueService = PredefinedValue("Catalog.Services.EmptyRef");
		EndIf;
	EndIf;
	SetFormAttributesAppearance();
EndProcedure // IsMedicineOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure PreServicesBeforeDeleteRow(pItem, pCancel)
	Modified = True;
EndProcedure // PreServicesBeforeDeleteRow 

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	SetFilter();	
EndProcedure // ClientTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure PriceIsCreatedOnChange(pItem) 
	SetFilter();
EndProcedure // PriceIsCreatedOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenServicesRowForEdit(pRowData)
	// Open form to edit services row data
	pParams = New Structure;
	pParams.Insert("RowID", pRowData.GetID());
	pParams.Insert("Period", pRowData.Period);
	pParams.Insert("ClientType", pRowData.ClientType);
	pParams.Insert("RoomClass", pRowData.RoomClass);
	pParams.Insert("RoomClassExcluding", pRowData.RoomClassExcluding);
	pParams.Insert("RoomType", pRowData.RoomType);
	pParams.Insert("RoomTypeExcluding", pRowData.RoomTypeExcluding);
	pParams.Insert("AccommodationType", pRowData.AccommodationType);
	pParams.Insert("AccommodationTypeExcluding", pRowData.AccommodationTypeExcluding);
	pParams.Insert("Service", pRowData.Service);
	pParams.Insert("Price", pRowData.Price);
	pParams.Insert("Currency", pRowData.Currency);
	pParams.Insert("Quantity", pRowData.Quantity);
	pParams.Insert("Unit", pRowData.Unit);
	pParams.Insert("VATRate", pRowData.VATRate);
	pParams.Insert("Remarks", pRowData.Remarks);
	pParams.Insert("IsInPrice", pRowData.IsInPrice);
	pParams.Insert("IsServicePerPerson", pRowData.IsServicePerPerson);
	pParams.Insert("QuantityCalculationRule", pRowData.QuantityCalculationRule);
	pParams.Insert("CalendarDayType", pRowData.CalendarDayType);
	pParams.Insert("AccountingDate", pRowData.AccountingDate);
	pParams.Insert("AccountingDayNumber", pRowData.AccountingDayNumber);
	pParams.Insert("PeriodFrom", pRowData.PeriodFrom);
	pParams.Insert("PeriodTo", pRowData.PeriodTo);
	pParams.Insert("Hotel", Object.Hotel); 
	pParams.Insert("ReadOnly", ReadOnly);
	
	vNotifyDescription = New NotifyDescription("OnEditOfExistingServiceFormClose", ThisObject);
	
	OpenForm("Catalog.ServicePackages.Form.tcServiceEditForm", pParams, ThisObject, , , , vNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // OpenServicesRowForEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure PreServicesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	
	vCurrentData = Items.PreServices.CurrentData;
	If vCurrentData <> Undefined Then
		// Open form to edit row data
		OpenServicesRowForEdit(vCurrentData);
	EndIf;
EndProcedure // PreServicesSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure PriceIsCreatedClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // PriceIsCreatedClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure PreServicesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If pClone Then
		pCancel = True;
		CopyRow(Commands.CopyRow);
	EndIf;
EndProcedure // PreServicesBeforeAddRow

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AddRow(pCommand)
	Modified = True;
	vNotifyDescription = New NotifyDescription("OnEditOfNewServiceFormClose", ThisObject);
	
	pParams = New Structure;
	If ValueIsFilled(PriceIsCreated) And PriceIsCreated <> AllDates Then
		pParams.Insert("Period", GetDateFromPresentation(PriceIsCreated));
	EndIf;
	pParams.Insert("ClientType", ClientType);
	pParams.Insert("ReadOnly", ThisObject.ReadOnly);

	OpenForm("Catalog.ServicePackages.Form.tcServiceEditForm", pParams, ThisObject, , , , vNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // AddRow

// --------------------------------------------------------------------------------
&AtClient
Procedure CopyRow(pCommand)
	vCurrentData = Items.PreServices.CurrentData;
	If vCurrentData <> Undefined Then
		// Create new row as copy of the one selected
		vNewRow = PreServices.Add();
		FillPropertyValues(vNewRow, vCurrentData);
		CurrentRowID = vNewRow.GetID();
		AttachIdleHandler("PositionToRowHandler", 0.1, True);
		
		// Open form to edit row data
		OpenServicesRowForEdit(vNewRow);
	EndIf;
EndProcedure // CopyRow

// --------------------------------------------------------------------------------
&AtClient
Procedure PositionToRowHandler()
	Items.PreServices.CurrentRow = CurrentRowID;
EndProcedure // PositionToRowHandler

// --------------------------------------------------------------------------------
&AtClient
Procedure CopyValue(pCommand)
	vCopyValueButton = Items.PreServicesButtonCopy;
	vPasteValueButton = Items.PreServicesButtonPaste;
	amClipboard.Delete("ServicePackageServices");
	If vCopyValueButton.Check Then
		ColumnCopied = Undefined;
		ValueCopied = Undefined;
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en = 'Paste'; de = 'Einsetzen'; ru = 'Вставить'");
		Notify("ServicePackageServicesCancelCopyRows", Undefined, ThisObject);
	Else
		vCurRow = Items.PreServices.CurrentRow;
		If vCurRow <> Undefined Then
			vSelectedRows = Items.PreServices.SelectedRows;
			
			If vSelectedRows.Count() > 1 Then				
				ColumnCopied = "SelectedRows";
				ValueCopied = GetRows(vSelectedRows);
				amClipboard.Insert("ServicePackageServices", ValueCopied);
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en = 'Paste selected rows'; de = 'Gewählte Zeilen einsetzen'; ru = 'Вставить выб. строки'");
				Notify("ServicePackageServicesCopyRows", ValueCopied, ThisObject);				
			Else
				ColumnCopied = StrReplace(Items.PreServices.CurrentItem.Name, "PreServices", "");
				ValueCopied = Items.PreServices.CurrentData[ColumnCopied];
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en = 'Paste '; de = 'Einsetzen '; ru = 'Вставить '") + TrimAll(ValueCopied);
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Row is not selected!'; de = 'Keine Zeile ist gewählt!'; ru = 'Не выбрана строка!'"));
			ColumnCopied = Undefined;
			ValueCopied = Undefined;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en = 'Paste'; de = 'Einsetzen'; ru = 'Вставить'");
		EndIf;
	EndIf;
EndProcedure // CopyValue

// --------------------------------------------------------------------------------
&AtClient
Procedure PasteValue(pCommand)
	vCopyValueButton = Items.PreServicesButtonCopy;
	vPasteValueButton = Items.PreServicesButtonPaste;
	
	vSelectedRows = Undefined;
	
	If amClipboard.Property("ServicePackageServices") Then
		UploadTable(amClipboard.ServicePackageServices);
		amClipboard.Delete("ServicePackageServices");
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en = 'Paste'; de = 'Einsetzen'; ru = 'Вставить'");
		Notify("ServicePackageServicesCancelCopyRows", Undefined, ThisObject);
	Else
		vSelectedRows = Items.PreServices.SelectedRows;
		If vSelectedRows.Count() > 0 Then
			For Each vRow In vSelectedRows Do
				vCurRow = PreServices.FindByID(vRow);
				vCurRow[ColumnCopied] = ValueCopied;
				If ValueIsFilled(vCurRow.QuantityCalculationRule) Then
					vCurRow.AccountingDate = '00010101';
					vCurRow.AccountingDayNumber = 0;
				ElsIf ValueIsFilled(vCurRow.AccountingDate) Then
					vCurRow.QuantityCalculationRule = Undefined;
					vCurRow.AccountingDayNumber = 0;
				ElsIf vCurRow.AccountingDayNumber <> 0 Then
					vCurRow.QuantityCalculationRule = Undefined;
					vCurRow.AccountingDate = '00010101';
				EndIf;
			EndDo;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en = 'Paste'; de = 'Einsetzen'; ru = 'Вставить'");
		Else
			ShowMessageBox(, NStr("en = 'There is no selected rows!'; de = 'Es gibt keine markierten Zeilen!'; ru = 'Нет выделенных строк!'"));
		EndIf;
	EndIf;
EndProcedure // PasteValue

// --------------------------------------------------------------------------------
&AtClient
Procedure AddDate(pCommand)
	vNotifyDescription = New NotifyDescription("OnCreateNewDateFormClose", ThisObject);
	OpenForm("Catalog.ServicePackages.Form.tcCreateNewDateForm", , ThisObject, , , , vNotifyDescription,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // AddDate

// -----------------------------------------------------------------------------
&AtClient
Procedure FillCopyByClientType(pCommand)	
	// Clear rows for client type selected
	vRows = New Array();
	If ValueIsFilled(PriceIsCreated) And PriceIsCreated <> AllDates Then
		vRows = PreServices.FindRows(New Structure("ClientType, Period", ClientType, GetDateFromPresentation(PriceIsCreated)));
	Else
		vRows = PreServices.FindRows(New Structure("ClientType", ClientType));
	EndIf;
	If vRows.Count() > 0 Then
		vText = NStr("en='Clear current rows for client type selected?';ru='Удалить существующие строки для выбранного типа клиента?';de='Zeilen für den ausgewählten Kundentyp löschen?'");
		ShowQueryBox(New NotifyDescription("DeleteClientTypeRowsQueryAnswer", ThisObject), vText, QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
	Else
		Items.ClientType.ChoiceList.ShowChooseItem(New NotifyDescription("ClientTypeUserChoice", ThisObject), NStr("en='Choose client type to copy rows from';ru='Выберите тип клиента, у которого скопировать строки';de='Wählen Sie den Clienttyp aus, von dem Zeilen kopiert werden sollen'"));		
	EndIf;	
EndProcedure // FillCopyByClientType

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteClientTypeRowsQueryAnswer(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		Items.ClientType.ChoiceList.ShowChooseItem(New NotifyDescription("ClientTypeUserChoice", ThisObject), NStr("en='Choose client type to copy rows from';ru='Выберите тип клиента, у которого скопировать строки';de='Wählen Sie den Clienttyp aus, von dem Zeilen kopiert werden sollen'"));		
	EndIf;	
EndProcedure // DeleteClientTypeRowsQueryAnswer

// -----------------------------------------------------------------------------
Procedure FillAsCopyClientType(pClientType)
	// Clear rows for client type selected
	vRows = New Array();
	vOldRows = New Array();
	If ValueIsFilled(PriceIsCreated) And PriceIsCreated <> AllDates Then
		vOldRows = PreServices.FindRows(New Structure("ClientType, Period", ClientType, GetDateFromPresentation(PriceIsCreated)));
		vRows = PreServices.FindRows(New Structure("ClientType, Period", pClientType, GetDateFromPresentation(PriceIsCreated)));
	Else
		vOldRows = PreServices.FindRows(New Structure("ClientType", ClientType));
		vRows = PreServices.FindRows(New Structure("ClientType", pClientType));
	EndIf;
	For Each vOldRow In vOldRows Do
		PreServices.Delete(vOldRow);
	EndDo;
	For Each vRow In vRows Do
		vNewRow = PreServices.Add();
		FillPropertyValues(vNewRow, vRow);
		vNewRow.ClientType = ClientType;
	EndDo;
		
	// Reapply filter
	SetFilter();
	
	Modified = True;
EndProcedure // FillAsCopyClientType

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeUserChoice(pUserChoice, pExtraParams) Export
	If pUserChoice <> Undefined Then
		FillAsCopyClientType(pUserChoice.Value);	
	EndIf;
EndProcedure // ClientTypeUserChoice

// --------------------------------------------------------------------------------
&AtServer
Procedure SetFormAttributesAppearance()
	If Object.IsMealBoardTerm Then
		Items.RoomRevenueService.Enabled = True;
		Items.IsBB.Enabled = True;
		Items.IsHB.Enabled = True;
		Items.IsFB.Enabled = True;
		Items.IsAI.Enabled = True;
		Items.IsUAI.Enabled = True;
		Items.IsFC.Enabled = True;
	Else
		Items.RoomRevenueService.Enabled = False;
		Items.IsBB.Enabled = False;
		Items.IsHB.Enabled = False;
		Items.IsFB.Enabled = False;
		Items.IsAI.Enabled = False;
		Items.IsUAI.Enabled = False;
		Items.IsFC.Enabled = False;
	EndIf;
	If Object.IsMedicine Then	
		Items.Duration.Enabled = True;
	Else
		Items.Duration.Enabled = False;
	EndIf;
EndProcedure // SetFormAttributesAppearance

// --------------------------------------------------------------------------------
&AtServer 
Procedure FillServicesFromPreServices()
	Object.Services.Clear();
	For Each vRow In PreServices Do
		If vRow.RoomType.Count() > 0 Then
			vRoomTypes = vRow.RoomType;	
			For Each vRoomType In vRoomTypes Do
				If vRow.AccommodationType.Count() > 0 Then
					vAccommodationTypes = vRow.AccommodationType;
					For Each vAccommodationType In vAccommodationTypes Do 
						vNewServiceRow = Object.Services.Add();
						FillPropertyValues(vNewServiceRow, vRow);
						vNewServiceRow.RoomType = vRoomType.Value;
						vNewServiceRow.AccommodationType = vAccommodationType.Value;
					EndDo;
				ElsIf vRow.AccommodationTypeExcluding.Count() > 0 Then
					vAccommodationTypesExcluding = vRow.AccommodationTypeExcluding;
					For Each vAccommodationType In vAccommodationTypesExcluding Do 
						vNewServiceRow = Object.Services.Add();
						FillPropertyValues(vNewServiceRow, vRow);
						vNewServiceRow.RoomType = vRoomType.Value;
						vNewServiceRow.AccommodationTypeExcluding = vAccommodationType.Value;
					EndDo;
				Else
					vNewServiceRow = Object.Services.Add();
					FillPropertyValues(vNewServiceRow, vRow);
					vNewServiceRow.RoomType = vRoomType.Value;
				EndIf;
			EndDo;
		ElsIf vRow.RoomClass.Count() > 0 Then
			vRoomClasses = vRow.RoomClass;	
			For Each vRoomClass In vRoomClasses Do
				If vRow.AccommodationType.Count() > 0 Then
					vAccommodationTypes = vRow.AccommodationType;
					For Each vAccommodationType In vAccommodationTypes Do 
						vNewServiceRow = Object.Services.Add();
						FillPropertyValues(vNewServiceRow, vRow);
						vNewServiceRow.RoomClass = vRoomClass.Value;
						vNewServiceRow.AccommodationType = vAccommodationType.Value;
					EndDo;
				ElsIf vRow.AccommodationTypeExcluding.Count() > 0 Then
					vAccommodationTypesExcluding = vRow.AccommodationTypeExcluding;
					For Each vAccommodationType In vAccommodationTypesExcluding Do 
						vNewServiceRow = Object.Services.Add();
						FillPropertyValues(vNewServiceRow, vRow);
						vNewServiceRow.RoomType = vRoomClass.Value;
						vNewServiceRow.AccommodationTypeExcluding = vAccommodationType.Value;
					EndDo;
				Else
					vNewServiceRow = Object.Services.Add();
					FillPropertyValues(vNewServiceRow, vRow);
					vNewServiceRow.RoomClass = vRoomClass.Value;
				EndIf;
			EndDo;
		ElsIf vRow.RoomTypeExcluding.Count() > 0 Then
			vRoomTypeExcluding = vRow.RoomTypeExcluding;	
			For Each vRoomType In vRoomTypeExcluding Do
				If vRow.AccommodationType.Count() > 0 Then
					vAccommodationTypes = vRow.AccommodationType;
					For Each vAccommodationType In vAccommodationTypes Do 
						vNewServiceRow = Object.Services.Add();
						FillPropertyValues(vNewServiceRow, vRow);
						vNewServiceRow.RoomType = vRoomType.Value;
						vNewServiceRow.AccommodationType = vAccommodationType.Value;
					EndDo;
				ElsIf vRow.AccommodationTypeExcluding.Count() > 0 Then
					vAccommodationTypesExcluding = vRow.AccommodationTypeExcluding;
					For Each vAccommodationType In vAccommodationTypesExcluding Do 
						vNewServiceRow = Object.Services.Add();
						FillPropertyValues(vNewServiceRow, vRow);
						vNewServiceRow.RoomType = vRoomType.Value;
						vNewServiceRow.AccommodationTypeExcluding = vAccommodationType.Value;
					EndDo;
				Else
					vNewServiceRow = Object.Services.Add();
					FillPropertyValues(vNewServiceRow, vRow);
					vNewServiceRow.RoomType = vRoomType.Value;
				EndIf;
			EndDo;
		ElsIf vRow.RoomClassExcluding.Count() > 0 Then
			vRoomClassExcluding = vRow.RoomClass;	
			For Each vRoomClass In vRoomClasses Do
				If vRow.AccommodationType.Count() > 0 Then
					vAccommodationTypes = vRow.AccommodationType;
					For Each vAccommodationType In vAccommodationTypes Do 
						vNewServiceRow = Object.Services.Add();
						FillPropertyValues(vNewServiceRow, vRow);
						vNewServiceRow.RoomClass = vRoomClass.Value;
						vNewServiceRow.AccommodationType = vAccommodationType.Value;
					EndDo;
				ElsIf vRow.AccommodationTypeExcluding.Count() > 0 Then
					vAccommodationTypesExcluding = vRow.AccommodationTypeExcluding;
					For Each vAccommodationType In vAccommodationTypesExcluding Do 
						vNewServiceRow = Object.Services.Add();
						FillPropertyValues(vNewServiceRow, vRow);
						vNewServiceRow.RoomType = vRoomClass.Value;
						vNewServiceRow.AccommodationTypeExcluding = vAccommodationType.Value;
					EndDo;
				Else
					vNewServiceRow = Object.Services.Add();
					FillPropertyValues(vNewServiceRow, vRow);
					vNewServiceRow.RoomClass = vRoomClass.Value;
				EndIf;
			EndDo;
		ElsIf vRow.AccommodationType.Count() > 0 Then
			vAccommodationTypes = vRow.AccommodationType;
			For Each vAccommodationType In vAccommodationTypes Do 
				vNewServiceRow = Object.Services.Add();
				FillPropertyValues(vNewServiceRow, vRow);
				vNewServiceRow.AccommodationType = vAccommodationType.Value;
			EndDo;
		ElsIf vRow.AccommodationTypeExcluding.Count() > 0 Then
			vAccommodationTypesExcluding = vRow.AccommodationTypeExcluding;
			For Each vAccommodationType In vAccommodationTypesExcluding Do 
				vNewServiceRow = Object.Services.Add();
				FillPropertyValues(vNewServiceRow, vRow);
				vNewServiceRow.AccommodationTypeExcluding = vAccommodationType.Value;
			EndDo;
		Else
			vNewServiceRow = Object.Services.Add();
			FillPropertyValues(vNewServiceRow, vRow);
		EndIf;
	EndDo;
EndProcedure // FillServicesFromPreServices

// --------------------------------------------------------------------------------
&AtServer
Procedure FillPreServicesFromServices()
	PreServices.Clear();
	VT = Object.Services.Unload();
	VT.GroupBy("Period, ClientType, Service, Price, Currency, Quantity, Unit, VATRate, Remarks, IsInPrice, IsServicePerPerson, QuantityCalculationRule, CalendarDayType, AccountingDate, AccountingDayNumber, PeriodFrom, PeriodTo","RoomClass, RoomClassExcluding, RoomType, RoomTypeExcluding, AccommodationType, AccommodationTypeExcluding"); // 
	PreServices.Load(VT);
	For Each vService In Object.Services Do
		For Each vRow In PreServices Do
			If vService.Period = vRow.Period And vService.ClientType = vRow.ClientType 
				And vService.Service = vRow.Service And vService.Price = vRow.Price 
				And vService.Currency = vRow.Currency And vService.Quantity = vRow.Quantity 
				And vService.Unit = vRow.Unit And vService.VATRate = vRow.VATRate 
				And vService.Remarks = vRow.Remarks And vService.IsInPrice = vRow.IsInPrice 
				And vService.IsServicePerPerson = vRow.IsServicePerPerson And vService.QuantityCalculationRule = vRow.QuantityCalculationRule 
				And vService.CalendarDayType = vRow.CalendarDayType And vService.AccountingDate = vRow.AccountingDate 
				And vService.AccountingDayNumber = vRow.AccountingDayNumber And vService.PeriodFrom = vRow.PeriodFrom 
				And vService.PeriodTo = vRow.PeriodTo Then
				If ValueIsFilled(vService.RoomClass) And vRow.RoomClass.FindByValue(vService.RoomClass) = Undefined Then
					vRow.RoomClass.Add(vService.RoomClass);
					vRow.RoomClassCheck = True;
				EndIf;
				If ValueIsFilled(vService.AccommodationType) And vRow.AccommodationType.FindByValue(vService.AccommodationType) = Undefined Then
					vRow.AccommodationType.Add(vService.AccommodationType);
					vRow.AccommodationTypeCheck = True;
				EndIf;
				If ValueIsFilled(vService.RoomType) And vRow.RoomType.FindByValue(vService.RoomType) = Undefined Then
					vRow.RoomType.Add(vService.RoomType);
					vRow.RoomTypeCheck = True;
				EndIf;
				If ValueIsFilled(vService.RoomClassExcluding) And vRow.RoomClassExcluding.FindByValue(vService.RoomClassExcluding) = Undefined Then
					vRow.RoomClassExcluding.Add(vService.RoomClassExcluding);
				EndIf;
				If ValueIsFilled(vService.RoomTypeExcluding) And vRow.RoomTypeExcluding.FindByValue(vService.RoomTypeExcluding) = Undefined Then
					vRow.RoomTypeExcluding.Add(vService.RoomTypeExcluding);
				EndIf;
				If ValueIsFilled(vService.AccommodationTypeExcluding) And vRow.AccommodationTypeExcluding.FindByValue(vService.AccommodationTypeExcluding) = Undefined Then
					vRow.AccommodationTypeExcluding.Add(vService.AccommodationTypeExcluding);
				EndIf;
			EndIf;	
		EndDo;
	EndDo;
EndProcedure // FillPreServicesFromServices

// --------------------------------------------------------------------------------
&AtClient
Procedure OnEditOfExistingServiceFormClose(pParameter, pExtraAttrs) Export
	If pParameter <> Undefined And pParameter.Property("RowID") Then 
		vPreServicesRow = PreServices.FindByID(pParameter.RowID);
		FillPropertyValues(vPreServicesRow, pParameter);
	EndIf;
	SetConditionalAppearance(vPreServicesRow);
EndProcedure // OnEditOfExistingServiceFormClose

// --------------------------------------------------------------------------------
&AtClient
Procedure OnEditOfNewServiceFormClose(pParameter, pExtraAttrs) Export
	If pParameter <> Undefined Then 
		vNewRow = PreServices.Add();
		FillPropertyValues(vNewRow, pParameter);
		vNewRowIndex = PreServices.IndexOf(vNewRow);
		vNewPeriod = vNewRow.Period;
		vNewPeriodPresentation = Format(vNewPeriod, "DF='dd.MM.yyyy HH:mm:ss'");
		
		// Get dates of price versions
		vPriceIsCreatedItem = Items.PriceIsCreated.ChoiceList.FindByValue(vNewPeriodPresentation);
		If vPriceIsCreatedItem = Undefined Then
			vInserted = False;
			For Each vPriceIsCreatedChoiceListItem In Items.PriceIsCreated.ChoiceList Do
				If vPriceIsCreatedChoiceListItem.Value <> AllDates Then
					vPeriod = GetDateFromPresentation(vPriceIsCreatedChoiceListItem.Value);
					If vPeriod > vNewPeriod Then
						Items.PriceIsCreated.ChoiceList.Insert(vNewPeriodPresentation, Items.PriceIsCreated.ChoiceList.IndexOf(vPriceIsCreatedChoiceListItem));
						vInserted = True;
					EndIf;
				EndIf;
			EndDo;
			If Not vInserted Then
				Items.PriceIsCreated.ChoiceList.Add(vNewPeriodPresentation);
			EndIf;
		EndIf;
		PriceIsCreated = vNewPeriodPresentation;
		
		// Reapply filter
		SetFilter();
		
		// Try to position to this new row
		Items.PreServices.CurrentItem = PreServices.Get(vNewRowIndex).GetID();
	EndIf;
EndProcedure // OnEditOfNewServiceFormClose 

// --------------------------------------------------------------------------------
&AtClient
Procedure OnCreateNewDateFormClose(pParameter, pExtraAttrs) Export
	If ValueIsFilled(pParameter) Then
		vOldPeriod = '00010101';
		If PriceIsCreated <> AllDates Then
			vOldPeriod = GetDateFromPresentation(PriceIsCreated);
		EndIf;
		
		vNewPeriod = Format(pParameter, "DF='dd.MM.yyyy HH:mm:ss'");
		If Items.PriceIsCreated.ChoiceList.FindByValue(vNewPeriod) = Undefined Then
			Items.PriceIsCreated.ChoiceList.Add(vNewPeriod);
		EndIf;
		PriceIsCreated = vNewPeriod;
		
		// Copy services from old date to the new one
		FillServicesFromPreServices();
		vOldServicesRows = Object.Services.FindRows(New Structure("Period", vOldPeriod));
		For Each vOldServicesRow In vOldServicesRows Do
			vNewServicesRow = Object.Services.Add();
			FillPropertyValues(vNewServicesRow, vOldServicesRow);
			vNewServicesRow.Period = pParameter;
		EndDo;
		FillPreServicesFromServices();
		
		// Apply filter
		SetFilter();
		
		// Set form is mofified flag
		Modified = True;
	EndIf;
EndProcedure // OnCreateNewDateFormClose

// --------------------------------------------------------------------------------
&AtServer
Procedure UploadTable(pTempStorage)
	vTable = GetFromTempStorage(pTempStorage);	
	For Each vRow In vTable Do
		vNewRow = PreServices.Add();
		FillPropertyValues(vNewRow, vRow, , "ClientType");
		vNewRow.ClientType = ClientType;
	EndDo;
EndProcedure // UploadTable

// --------------------------------------------------------------------------------
&AtServer
Procedure SetFilter()
	vFilter = New Structure();
	vFilter.Insert("ClientType", ClientType);	
	If ValueIsFilled(PriceIsCreated) And PriceIsCreated <> AllDates Then
		vFilter.Insert("Period", GetDateFromPresentation(PriceIsCreated));	
	EndIf;
	vFilterStruct = New FixedStructure(vFilter);
	Items.PreServices.RowFilter = vFilterStruct;
EndProcedure // SetFilter

// --------------------------------------------------------------------------------
&AtServer
Function GetClientTypes()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientTypes.Ref AS ClientType,
	|	ClientTypes.IsFolder AS IsFolder,
	|	ClientTypes.Code AS Code,
	|	ClientTypes.Description AS Description,
	|	ClientTypes.SortCode AS SortCode
	|FROM
	|	Catalog.ClientTypes AS ClientTypes
	|WHERE
	|	ClientTypes.DeletionMark = FALSE
	|	AND ClientTypes.Parent = &qEmptyClientType
	|	AND (NOT &qHotelIsEmptyRef
	|				AND ClientTypes.Hotel = &qHotel
	|			OR ClientTypes.Hotel = &qEmptyHotel
	|			OR &qHotelIsEmptyRef)
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qHotel", ?(Object.Hotel = Catalogs.Hotels.EmptyRef(), SessionParameters.CurrentHotel, Object.Hotel));
	vQry.SetParameter("qHotelIsEmptyRef", ?(Object.Hotel = Catalogs.Hotels.EmptyRef(), True, False));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qEmptyClientType", Catalogs.ClientTypes.EmptyRef());
	vElements = vQry.Execute().Unload();
	// Check user permissions
	vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermissionGroup) Then
		If vPermissionGroup.ClientTypesAllowed.Count() > 0 Then
			vInt = 0;
			While vInt < vElements.Count() Do
				vRow = vElements.Get(vInt);
				If Not vRow.IsFolder And vPermissionGroup.ClientTypesAllowed.Find(vRow.ClientType, "ClientType") = Undefined Then
					vElements.Delete(vInt);
				Else
					vInt = vInt + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;	
	Return vElements;
EndFunction // GetClientTypes 

// --------------------------------------------------------------------------------
&AtServer
Function GetServicesDates()
	vDates = New ValueList();
	For i = 0 To PreServices.Count() - 1 Do
		vPeriod = PreServices[i].Period;
		If vDates.FindByValue(vPeriod) = Undefined Then
			vDates.Add(vPeriod, Format(vPeriod, "DF=yyyyMMddHHmmss"));
		EndIf;
	EndDo;
	vDates.SortByPresentation();
	vElements = New Array();
	For Each vDatesItem In vDates Do
		vElements.Add(Format(vDatesItem.Value, "DF='dd.MM.yyyy HH:mm:ss'"));
	EndDo;  
	Return vElements;
EndFunction // GetServicesDates

// --------------------------------------------------------------------------------
&AtServer
Function GetLastDate()
	vElements = New Array;
	vLastDate = Date(1, 1, 1);
	For vInt = 0 To PreServices.Count() - 1 Do
		If PreServices[vInt].Period > vLastDate Then
			vLastDate = PreServices[vInt].Period;		
	 	EndIf;
	EndDo;  
	vStr = Format(vLastDate, "DF='dd.MM.yyyy HH:mm:ss'");
	Return vStr;
EndFunction // GetLastDate

// --------------------------------------------------------------------------------
Function GetDateFromPresentation(pPeriodStr)
	Return Date(Number(Mid(pPeriodStr, 7, 4)), Number(MId(pPeriodStr, 4, 2)), Number(Left(pPeriodStr, 2)), Number(Mid(pPeriodStr, 12, 2)), Number(Mid(pPeriodStr, 15, 2)), Number(Right(pPeriodStr, 2)));
EndFunction // GetDateFromPresentation

// --------------------------------------------------------------------------------
&AtServer
Function GetRows(val pSelectedRows)
	vRows = New Array;
	For Each vRow In pSelectedRows Do
		vRows.Add(PreServices.FindByID(vRow));	
	EndDo;
	Return PutToTempStorage(PreServices.Unload(vRows), New UUID);
EndFunction // GetRows

#EndRegion

#Region CopyPaste

// -----------------------------------------------------------------------------
&AtClient
Procedure PreServicesAfterDeleteRow(pItem)
	If Items.PriceIsCreated.ChoiceList.Count() > 1 Then
		PriceIsCreated = Items.PriceIsCreated.ChoiceList.FindByValue(GetLastDate());
	Else
		PriceIsCreated = Items.PriceIsCreated.ChoiceList.Get(0).Value;
	EndIf;
EndProcedure // PreServicesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure SetConditionalAppearance(vLine)
	If vLine = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(vLine.RoomType) Then
		vLine.RoomTypeCheck = True;
		vLine.RoomClass.Clear();
		vLine.RoomClassCheck = False;
		vLine.RoomTypeExcluding.Clear();
	Else
		vLine.RoomTypeCheck = False;
	EndIf;
	If ValueIsFilled(vLine.RoomClass) Then
		vLine.RoomClassCheck = True;
		vLine.RoomType.Clear();
		vLine.RoomTypeCheck = False;
		vLine.RoomClassExcluding.Clear();
	Else
		vLine.RoomClassCheck = False;
	EndIf;  
	If ValueIsFilled(vLine.AccommodationType) Then
		vLine.AccommodationTypeCheck = True;
		vLine.RoomTypeExcluding.Clear();
	Else
		vLine.AccommodationTypeCheck = False;
	EndIf;
	If ValueIsFilled(vLine.RoomType) Then
		vLine.RoomTypeCheck = True;
		vLine.RoomClass.Clear();
		vLine.RoomClassCheck = False;
		vLine.RoomTypeExcluding.Clear();
	Else
		vLine.RoomTypeCheck = False;
	EndIf;
	If ValueIsFilled(vLine.RoomClass) Then
		vLine.RoomClassCheck = True;
		vLine.RoomType.Clear();
		vLine.RoomTypeCheck = False;
		vLine.RoomClassExcluding.Clear();
	Else
		vLine.RoomClassCheck = False;
	EndIf;
	If ValueIsFilled(vLine.AccommodationType) Then
		vLine.AccommodationTypeCheck = True;
		vLine.RoomTypeExcluding.Clear();
	Else
		vLine.AccommodationTypeCheck = False;
	EndIf;
EndProcedure // SetConditionalAppearance

// --------------------------------------------------------------------------------
&AtClient
Function CheckPreServicesRowForErrors(pCurData)
	vRowHasErrors = False;
	vRowIndex = Format(PreServices.IndexOf(pCurData), "NFD=0; NG=");
	vRowLineNumber = Format(PreServices.IndexOf(pCurData) + 1, "NFD=0; NG=");
	If Not ValueIsFilled(pCurData.Period) Then
		vUM = New UserMessage();
		vUM.Field = "PreServices[" + vRowIndex + "].Period";
		vUM.Text = StrTemplate(NStr("en = 'Price creation date should be filled in line %1!'; 
									|de = 'Preiserstellungsdatum sollte in Zeile %1 ausgefüllt werden!'; 
									|ru = 'Дата создания цены должна быть заполнена в строке %1!'"), vRowLineNumber);
		vUM.Message();
		vRowHasErrors = True;
	EndIf;
	If ValueIsFilled(pCurData.AccountingDate) Then
		If ValueIsFilled(pCurData.PeriodFrom) Then
			pCurData.PeriodFrom = '00010101';
		EndIf;
		If ValueIsFilled(pCurData.PeriodTo) Then
			pCurData.PeriodTo = '00010101';
		EndIf;
	EndIf;
	If ValueIsFilled(pCurData.PeriodTo) Then
		If pCurData.PeriodTo < pCurData.PeriodFrom Then
			pCurData.PeriodTo = '00010101';
			vUM = New UserMessage();
			vUM.Field = "PreServices[" + vRowIndex + "].PeriodTo";
			vUM.Text = StrTemplate(NStr("en = 'Service period was wrong in line %1! End of period date was cleared.'; 
										|de = 'In Zeile %1 Periode war falsch! Das Datum des Periodenendes wurde geklärt.'; 
										|ru = 'В строке %1 период действия строки был указан неверно! Дата окончания периода действия была очищена.'"), vRowLineNumber);
			vUM.Message();
			vRowHasErrors = True;
		EndIf;
	EndIf;
	If Not ValueIsFilled(pCurData.Service) Then
		vUM = New UserMessage();
		vUM.Field = "PreServices[" + vRowIndex + "].Service";
		vUM.Text = StrTemplate(NStr("en = 'Service should be filled in line %1!'; 
									|de = 'Dienstleistung sollte in Zeile %1 ausgefüllt werden!'; 
									|ru = 'Услуга должна быть заполнена в строке %1!'"), vRowLineNumber);
		vUM.Message();
		vRowHasErrors = True;
	EndIf;
	If Not ValueIsFilled(pCurData.Currency) Then
		vUM = New UserMessage();
		vUM.Field = "PreServices[" + vRowIndex + "].Currency";
		vUM.Text = StrTemplate(NStr("en = 'Currency should be filled in line %1!'; 
									|de = 'Währung sollte in Zeile %1 ausgefüllt werden!'; 
									|ru = 'Валюта должна быть заполнена в строке %1!'"), vRowLineNumber);
		vUM.Message();
		vRowHasErrors = True;
	EndIf;
	If Not ValueIsFilled(pCurData.VATRate) Then
		vUM = New UserMessage();
		vUM.Field = "PreServices[" + vRowIndex + "].VATRate";
		vUM.Text = StrTemplate(NStr("en = 'VAT rate should be filled in line %1!'; 
									|de = 'Mw.St. sollte in Zeile %1 ausgefüllt werden!'; 
									|ru = 'Ставка НДС должна быть заполнена в строке %1!'"), vRowLineNumber);
		vUM.Message();
		vRowHasErrors = True;
	EndIf;
	If pCurData.Quantity <= 0 Then
		pCurData.Quantity = 0;
		vUM = New UserMessage();
		vUM.Field = "PreServices[" + vRowIndex + "].Quantity";
		vUM.Text = StrTemplate(NStr("en = 'Quantity should be greater then 0 in line %1!'; 
									|de = 'Menge sollte größer als 0 in Zeile %1 sein!'; 
									|ru = 'Количество должно быть больше 0 в строке %1!'"), vRowLineNumber);
		vUM.Message();
		vRowHasErrors = True;
	EndIf;
	Return vRowHasErrors;
EndFunction // CheckPreServicesRowForErrors

// --------------------------------------------------------------------------------
&AtClient
Procedure PreServicesAccomodationTypeMultipleValueOpening(pItem, pID, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PreServicesAccomodationTypeExcludingMultipleValueOpening(pItem, pID, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PreServicesRoomTypeMultipleValueOpening(pItem, pID, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PreServicesRoomTypeExcludingMultipleValueOpening(pItem, pID, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PreServicesRoomClassMultipleValueOpening(pItem, pID, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PreServicesRoomClassExcludingMultipleValueOpening(pItem, pID, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

#EndRegion
