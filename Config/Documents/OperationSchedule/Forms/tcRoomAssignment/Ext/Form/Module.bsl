
#Region Variables

&AtClient
Var DoDrag;

#EndRegion

#Region FormEventHandlers

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Process parameters
	If Parameters.Property("Operations") Then
		For Each vOpStruct In Parameters.Operations Do
			vOpRow = Operations.Add();
			FillPropertyValues(vOpRow, vOpStruct);
		EndDo;
		FillPropertyValues(ThisObject, Parameters, "Hotel, NumberOfEmployees, TotalEmployees, DocumentDate, TotalOperations, AveragePerEmployee, CheckedOutLabel, OccupiedLabel, RepairLabel, VacantLabel, OtherLabel, CheckOutCleaningCount, OccupiedRoomCleaningCount, RepairEndCleaningCount, VacantRoomCleaningCount, OtherOperationsCount, EmployeeList");
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If FormOwner = Undefined Then
		pCancel = True;
		Return;
	EndIf;
	ItemName = "";
	DoDrag = False;
	vMaxWidth = 0;
	vScreens = GetClientDisplaysInformation();
	For Each vScreen In vScreens Do
		If vScreen.Width <> 0 Then
			vMaxWidth = Int(vScreen.Width/(?(vScreen.DPI = 0, 96, vScreen.DPI)/96));
		EndIf;
	EndDo;
	CurPageIndex = 1;
	PagesCount = 0;
	BlocksGroupCount = 0;
	NumberOfBlocksGroupOnPage = 2;
	NumberOfColumnsInBlock = 1;
	MaxNumberOfRowsInTable = 999999;
	NumberOfEmployeeTablesInRow = Int((vMaxWidth - 30) / 350);
	NumberOfEmployees = EmployeeList.Count();
	Items.FormCommandLabelPage.Title = NStr("en='Page №';ru='Страница №';de='Seite Nr.'") + String(CurPageIndex);
	Items.FormCommandLabelShow.Title = NStr("en='Employees is shown 1 ... ';ru='Горничных показано с 1 по ';de='Zimmermädchen angezeigt ab 1 bis '") + String(Min(NumberOfEmployees, NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage)) + NStr("en=' of ';de=' von ';ru=' из '") + String(NumberOfEmployees);
	OnOpenAtServer();
	Items.FormCommandPrev.Enabled = False;
	If CurPageIndex = PagesCount Then
		Items.FormCommandNext.Enabled = False;
	Else
		Items.FormCommandNext.Enabled = True;
	EndIf;
	If NumberOfEmployees > 0 Then
		For vInd = 1 To NumberOfEmployees Do
			Try
				vEmployeeTableContextMenu = Items["Employee" + String(vInd) + "ContextMenu"];
				For Each vItem In vEmployeeTableContextMenu.ChildItems Do
					vItem.Enabled = False;
				EndDo;
			Except
			EndTry;
		EndDo;
	EndIf;
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		Items.CommandSave.Visible = True;
		Items.CommandSaveAndClose.Visible = True;
	Else
		Items.CommandSave.Visible = False;
		Items.CommandSaveAndClose.Visible = False;
	EndIf;
	RefreshDataRepresentation();
EndProcedure // OnOpen

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		If IsModified Then
			pCancel = True;
			vMsg = NStr("en = 'Save changes?'; de = 'Änderungen speichern?'; ru = 'Сохранить изменения?'");
			vTitle = NStr("en = 'Assign operations to employees'; de = 'Zuweisung von Arbeiten für die Mitarbeiter'; ru = 'Назначение работ сотрудникам'");
			ShowQueryBox(New NotifyDescription("AfterShowQueryBox", ThisObject), vMsg, QuestionDialogMode.YesNoCancel, , , vTitle);
		EndIf;
	EndIf;		
EndProcedure // BeforeClose

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure OnActivateCell(pItem)
	For i = 1 To EmployeeList.Count() Do
		vItem = Items["Employee" + i];
		If vItem <> pItem Then
			vItem.SelectedRows.Clear();
		EndIf;
	EndDo;
EndProcedure // OnActivateCell

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure DragStart(pItem, pDragParameters, pStandardProcessing)
	DoDrag = False;
	ItemName = pItem.Name;
	pDragParameters.Value.Clear();
	For Each vOpRowID In Items[ItemName].SelectedRows Do
		pDragParameters.Value.Add(ThisObject[ItemName].FindByID(vOpRowID));
	EndDo;
EndProcedure // DragStart

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure OnDrag(pItem, pDragParameters, pStandardProcessing, pRow, pField)
	pStandardProcessing = False;
	If pItem.Name = "Clipboard" Then
		// Do drag
		If ActionHistory.Count() > 0 Then
			vHistoryIndex = ActionHistory.Get(ActionHistory.Count() - 1).HistoryIndex + 1;
		Else
			vHistoryIndex = 1;
		EndIf;
		For Each vParametersRow In pDragParameters.Value Do
			If TypeOf(vParametersRow) = Type("FormDataCollectionItem") Then
				// Add new row in Clipboard table
				vNewStr = Clipboard.Add();
				vNewStr.RoomType = vParametersRow.RoomType;
				vNewStr.RoomTypeRef = vParametersRow.RoomTypeRef;
				vNewStr.Room = vParametersRow.Room;
				vNewStr.RoomRef = vParametersRow.RoomRef;
				vNewStr.Operation = vParametersRow.Operation;
				vNewStr.OperationRef = vParametersRow.OperationRef;
				vNewStr.NumberOfGuests = vParametersRow.NumberOfGuests;
				vNewStr.Icon = vParametersRow.Icon;
				vNewStr.CheckInIcon = vParametersRow.CheckInIcon;
				vNewStr.UUID = vParametersRow.UUID;
				// Get empty employee
				vEmployeeRef = PredefinedValue("Catalog.Employees.EmptyRef");
				// Change row in operations tabular section
				vFindedRowsByCurRoom = Operations.FindRows(New Structure("Room, Operation", vParametersRow.RoomRef, vParametersRow.OperationRef));
				For Each vFindedRowByCurRoom In vFindedRowsByCurRoom Do
					vFindedRowByCurRoom.Employee = vEmployeeRef;
					vFindedRowByCurRoom.BlockIndex = 0;
					vFindedRowByCurRoom.BlocksGroupIndex = 0;
					vFindedRowByCurRoom.EmployeeTableIndex = 0;
					// Get operation standards
					If ValueIsFilled(vFindedRowByCurRoom.Operation) Then
						vStandards = GetOperationRowStandards(vFindedRowByCurRoom.Operation, vFindedRowByCurRoom.RoomType, vFindedRowByCurRoom.Room, vFindedRowByCurRoom.Employee, Hotel);
						If vStandards <> Undefined Then
							vFindedRowByCurRoom.Duration = vStandards.Duration;
							vFindedRowByCurRoom.RoomSpace = vStandards.RoomSpace;
							vFindedRowByCurRoom.Price = vStandards.Price;
						EndIf;
					EndIf;
				EndDo;
				// Change row in schedule document operations tabular part
				vFindedRows = Undefined;
				If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
					vDragOperations = DragOperationsList.FindRows(New Structure("Room, UUID", vParametersRow.RoomRef, vParametersRow.UUID));
					If vDragOperations.Count() > 0 Then
						vDragOperations[0].Employee = vEmployeeRef; 	
					Else
						vNewDragOperations = DragOperationsList.Add();
						vNewDragOperations.Room = vParametersRow.RoomRef;
						vNewDragOperations.Employee = vEmployeeRef;
						vNewDragOperations.UUID = vParametersRow.UUID;
					EndIf;
				Else
					vFindedRows = FormOwner.ThisObject.Operations.FindRows(New Structure("Room, Operation", vParametersRow.RoomRef, vParametersRow.OperationRef));
				EndIf;
				If vFindedRows <> Undefined And vFindedRows.Count() > 0 Then
					vFindedRow = vFindedRows.Get(0);
					vFindedRow.Employee = vEmployeeRef;
					vFindedRow.EmployeeSortCode = GetEmployeeSortCode(vFindedRows.Get(0).Employee);
					// Get operation standards
					If ValueIsFilled(vFindedRow.Operation) Then
						vStandards = GetOperationRowStandards(vFindedRow.Operation, vFindedRow.RoomType, vFindedRow.Room, vFindedRow.Employee, Hotel);
						If vStandards <> Undefined Then
							vFindedRow.Duration = vStandards.Duration;
							vFindedRow.RoomSpace = vStandards.RoomSpace;
							vFindedRow.Price = vStandards.Price;
						EndIf;
					EndIf;
				EndIf;
				// Add operation to history
				vActionHistoryRow = ActionHistory.Add();
				vActionHistoryRow.HistoryIndex = vHistoryIndex;
				vActionHistoryRow.Icon = vParametersRow.Icon;
				vActionHistoryRow.CheckInIcon = vParametersRow.CheckInIcon;
				vActionHistoryRow.RoomRef = vParametersRow.RoomRef; 
				vActionHistoryRow.RoomTypeRef = vParametersRow.RoomTypeRef;
				vActionHistoryRow.OperationRef = vParametersRow.OperationRef;
				vActionHistoryRow.NumberOfGuests = vParametersRow.NumberOfGuests;
				vActionHistoryRow.BlockIndexTo = 0;
				vActionHistoryRow.BlocksGroupIndexTo = 0;
				vActionHistoryRow.EmployeeTableIndexTo = 0;
				vActionHistoryRow.UUID = vParametersRow.UUID;
				DoDrag = True;
			EndIf;
		EndDo;
		Clipboard.Sort("Room");
		GetTotalTitleForClipboard();
	Else
		// Index (XX) of current employee table (EmployeeXX)
		vIndex = Number(Mid(pItem.Name,9));
		// vCol (XX) - index of current block (BlockXX)
		If Int(vIndex/NumberOfColumnsInBlock) * NumberOfColumnsInBlock = vIndex Then
			vCol = vIndex/NumberOfColumnsInBlock;
		ElsIf Int(vIndex/NumberOfColumnsInBlock) * NumberOfColumnsInBlock < vIndex Then
			vCol = Int(vIndex/NumberOfColumnsInBlock) + 1;
		EndIf;
		// vBlocksGroupIndex (X) - index of current blocks group (BlocksGroupX)
		If Int(vCol/NumberOfEmployeeTablesInRow)= vCol / NumberOfEmployeeTablesInRow Then
			vBlocksGroupIndex = vCol / NumberOfEmployeeTablesInRow;
		Else
			vBlocksGroupIndex = Int(vCol / NumberOfEmployeeTablesInRow)+1;
		EndIf;
		vCountOfRows = 0;
		vFieldWithMinCountOfRows = Undefined;
		// Get emplyee table in current block with min count of rows
		vInd = NumberOfColumnsInBlock - 1;
		While vInd > -1 Do
			vCount = ThisObject["Employee" + String(vCol * NumberOfColumnsInBlock-vInd)].Count();
			If vCount < vCountOfRows Then
				vFieldWithMinCountOfRows = "Employee" + String(vCol * NumberOfColumnsInBlock-vInd);
				Break;
			Else
				vCountOfRows = ThisObject["Employee" + String(vCol * NumberOfColumnsInBlock-vInd)].Count();
			EndIf;
			vInd = vInd - 1;
		EndDo;
		If vFieldWithMinCountOfRows = Undefined Then
			vFieldWithMinCountOfRows = "Employee"+String(vCol * NumberOfColumnsInBlock - (NumberOfColumnsInBlock - 1));
		EndIf;
		If ActionHistory.Count() > 0 Then
			vHistoryIndex = ActionHistory.Get(ActionHistory.Count() - 1).HistoryIndex + 1;
		Else
			vHistoryIndex = 1;
		EndIf;
		// Do drag
		vEmployeeTable = ThisObject[vFieldWithMinCountOfRows];
		For Each vParametersRow In pDragParameters.Value Do
			If TypeOf(vParametersRow) = Type("FormDataCollectionItem") Then
				Try
					If vEmployeeTable.Count() = MaxNumberOfRowsInTable Then
						DoDrag = False;
						Break;
					Else
						// Add new row in EmployeeTable
						vNewStr = vEmployeeTable.Add();
						vNewStr.RoomType = vParametersRow.RoomType;
						vNewStr.RoomTypeRef = vParametersRow.RoomTypeRef;
						vNewStr.Room = vParametersRow.Room;
						vNewStr.RoomRef = vParametersRow.RoomRef;
						vNewStr.Operation = vParametersRow.Operation;
						vNewStr.OperationRef = vParametersRow.OperationRef;
						vNewStr.NumberOfGuests = vParametersRow.NumberOfGuests;
						vNewStr.Icon = vParametersRow.Icon;
						vNewStr.CheckInIcon = vParametersRow.CheckInIcon;
						vNewStr.UUID = vParametersRow.UUID;
						// Get current employee
						vEmployeeRef = ThisObject["EmployeeRef" + String(vCol)];
						// Change row in form operations table
						vFindedRowsByCurRoom = Operations.FindRows(New Structure("Room, Operation", vParametersRow.RoomRef, vParametersRow.OperationRef));
						If vFindedRowsByCurRoom.Count() > 0 Then
							vFindedRowByCurRoom = vFindedRowsByCurRoom.Get(0);
							vFindedRowByCurRoom.Employee = vEmployeeRef;
							vFindedRowByCurRoom.BlockIndex = vCol;
							vFindedRowByCurRoom.BlocksGroupIndex = vBlocksGroupIndex;
							vFindedRowByCurRoom.EmployeeTableIndex = vIndex;
							// Get operation standards
							If ValueIsFilled(vFindedRowByCurRoom.Operation) Then
								vStandards = GetOperationRowStandards(vFindedRowByCurRoom.Operation, vFindedRowByCurRoom.RoomType, vFindedRowByCurRoom.Room, vFindedRowByCurRoom.Employee, Hotel);
								If vStandards <> Undefined Then
									vFindedRowByCurRoom.Duration = vStandards.Duration;
									vFindedRowByCurRoom.RoomSpace = vStandards.RoomSpace;
									vFindedRowByCurRoom.Price = vStandards.Price;
								EndIf;
							EndIf;
						EndIf;
						// Change row in schedule document operations tabular section
						vFindedRows = Undefined;
						If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
							vDragOperations = DragOperationsList.FindRows(New Structure("Room, UUID", vParametersRow.RoomRef, vParametersRow.UUID));
							If vDragOperations.Count() > 0 Then
								vDragOperations[0].Employee = vEmployeeRef; 	
							Else
								vNewDragOperations = DragOperationsList.Add();
								vNewDragOperations.Room = vParametersRow.RoomRef;
								vNewDragOperations.Employee = vEmployeeRef;
								vNewDragOperations.UUID = vParametersRow.UUID;
							EndIf;
						Else
							vFindedRows = FormOwner.ThisObject.Operations.FindRows(New Structure("Room, Operation", vParametersRow.RoomRef, vParametersRow.OperationRef));
						EndIf;
						If vFindedRows <> Undefined And vFindedRows.Count() > 0 Then
							vFindedRow = vFindedRows.Get(0);
							If vFindedRow.Employee <> vEmployeeRef Then
								vFindedRow.Employee = vEmployeeRef;
								vFindedRow.EmployeeSortCode = GetEmployeeSortCode(vFindedRow.Employee);
								// Get operation standards
								vStandards = GetOperationRowStandards(vFindedRow.Operation, vFindedRow.RoomType, vFindedRow.Room, vFindedRow.Employee, Hotel);
								If vStandards <> Undefined Then
									vFindedRow.Duration = vStandards.Duration;
									vFindedRow.RoomSpace = vStandards.RoomSpace;
									vFindedRow.Price = vStandards.Price;
								EndIf;
							EndIf;
						EndIf;
						// Add operation to history
						vActionHistoryRow = ActionHistory.Add();
						vActionHistoryRow.HistoryIndex = vHistoryIndex;
						vActionHistoryRow.Icon = vParametersRow.Icon;
						vActionHistoryRow.CheckInIcon = vParametersRow.CheckInIcon;
						vActionHistoryRow.RoomRef = vParametersRow.RoomRef; 
						vActionHistoryRow.RoomTypeRef = vParametersRow.RoomTypeRef;
						vActionHistoryRow.OperationRef = vParametersRow.OperationRef;
						vActionHistoryRow.NumberOfGuests = vParametersRow.NumberOfGuests;
						vActionHistoryRow.BlockIndexTo = vCol;
						vActionHistoryRow.BlocksGroupIndexTo = vBlocksGroupIndex;
						vActionHistoryRow.EmployeeTableIndexTo = vIndex;
						vActionHistoryRow.UUID = vParametersRow.UUID;
						Items.CommandUnDo.Enabled = True;
						DoDrag = True;
					EndIf;
				Except
					DoDrag = False;
				EndTry;
			EndIf;
		EndDo;
		vEmployeeTable.Sort("Room");
		GetTotalTitleByBlock(vCol, "Label" + String(vCol), Items["Label" + String(vCol)].ToolTip);
	EndIf;
	IsModified = True;
	OnDragEnd(pDragParameters.Value);
EndProcedure // OnDrag

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandNext(pCommand)
	If CurPageIndex * NumberOfBlocksGroupOnPage<=BlocksGroupCount Then
		Try
			Items["BlocksGroup" + String(CurPageIndex * NumberOfBlocksGroupOnPage-1)].Visible = False;
			Items["BlocksGroup" + String(CurPageIndex * NumberOfBlocksGroupOnPage)].Visible = False;
			Items.FormCommandPrev.Enabled = True;
			CurPageIndex = CurPageIndex + 1;
			Items.FormCommandLabelPage.Title = NStr("en='Page №';ru='Страница №';de='Seite Nr.'") + String(CurPageIndex);
			If NumberOfEmployeeTablesInRow * NumberOfBlocksGroupOnPage*CurPageIndex > NumberOfEmployees Then
				vShowTo = NumberOfEmployees;
			Else
				vShowTo = NumberOfEmployeeTablesInRow * NumberOfBlocksGroupOnPage*CurPageIndex;
			EndIf;
			Items.FormCommandLabelShow.Title = NStr("en='Employees is shown ';ru='Горничных показано с ';de='Zimmermädchen angezeigt ab '") + String(NumberOfEmployeeTablesInRow * NumberOfBlocksGroupOnPage * CurPageIndex-NumberOfEmployeeTablesInRow * NumberOfBlocksGroupOnPage + 1) + NStr("en=' ... ';ru=' по ';de=' bis '") + String(Min(NumberOfEmployees, vShowTo)) + NStr("en=' of ';de=' von ';ru=' из '") + String(NumberOfEmployees);
			If CurPageIndex = PagesCount Then
				Items.FormCommandNext.Enabled = False;
			EndIf;	
			If CurPageIndex * NumberOfBlocksGroupOnPage>BlocksGroupCount Then
				Items["BlocksGroup" + String(CurPageIndex*NumberOfBlocksGroupOnPage - 1)].Visible = True;
			Else
				Items["BlocksGroup" + String(CurPageIndex*NumberOfBlocksGroupOnPage - 1)].Visible = True;
				Items["BlocksGroup" + String(CurPageIndex*NumberOfBlocksGroupOnPage)].Visible = True;
			EndIf;
		Except
		EndTry;	
	EndIf;		
EndProcedure // CommandNext

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandPrev(pCommand)
	Try
		Items["BlocksGroup"+String(CurPageIndex * NumberOfBlocksGroupOnPage - 1)].Visible = False;
		If CurPageIndex * NumberOfBlocksGroupOnPage <= BlocksGroupCount Then
			Items["BlocksGroup" + String(CurPageIndex * NumberOfBlocksGroupOnPage)].Visible = False;
		EndIf;
		Items.FormCommandNext.Enabled = True;
		CurPageIndex = CurPageIndex - 1;
		Items["BlocksGroup" + String(CurPageIndex*NumberOfBlocksGroupOnPage - 1)].Visible = True;
		Items["BlocksGroup" + String(CurPageIndex*NumberOfBlocksGroupOnPage)].Visible = True;
		Items.FormCommandLabelPage.Title = NStr("en='Page №';ru='Страница №';de='Seite Nr.'") + String(CurPageIndex);
		If NumberOfEmployeeTablesInRow * NumberOfBlocksGroupOnPage*CurPageIndex > NumberOfEmployees Then
			vShowTo = NumberOfEmployees;
		Else
			vShowTo = NumberOfEmployeeTablesInRow * NumberOfBlocksGroupOnPage*CurPageIndex;
		EndIf;
		Items.FormCommandLabelShow.Title = NStr("en='Employees is shown ';ru='Горничных показано с ';de='Zimmermädchen angezeigt ab '") + String(NumberOfEmployeeTablesInRow * NumberOfBlocksGroupOnPage * CurPageIndex - NumberOfEmployeeTablesInRow * NumberOfBlocksGroupOnPage + 1) + NStr("en=' ... ';ru=' по ';de=' bis '") + String(Min(NumberOfEmployees, vShowTo)) + NStr("en=' of ';de=' von ';ru=' из '") + String(NumberOfEmployees);
		If CurPageIndex = 1 Then
			Items.FormCommandPrev.Enabled = False;
		EndIf;
	Except
	EndTry;	
EndProcedure // CommandPrev

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandUnDo(pCommand)
	If ActionHistory.Count() > 0 Then
		vLastOperation = ActionHistory.Get(ActionHistory.Count()-1);
		vLastOperationHistoryIndex = vLastOperation.HistoryIndex;
		vActionRows = ActionHistory.FindRows(New Structure("HistoryIndex", vLastOperationHistoryIndex));
		For Each vActionRow In vActionRows Do
			If vActionRow.EmployeeTableIndexFrom = 0 Then
				vEmployeeIn = PredefinedValue("Catalog.Employees.EmptyRef");
				vTableIn = Clipboard;
			Else
				vEmployeeIn = ThisObject["EmployeeRef" + String(vActionRow.EmployeeTableIndexFrom)];
				Try
					vTableIn = ThisObject["Employee" + String(vActionRow.EmployeeTableIndexFrom)];
				Except
				EndTry;
			EndIf;
			If vActionRow.EmployeeTableIndexTo = 0 Then
				vEmployeeOut = PredefinedValue("Catalog.Employees.EmptyRef");
				vTableOut = Clipboard;
			Else
				vEmployeeOut = ThisObject["EmployeeRef" + String(vActionRow.EmployeeTableIndexTo)];
				Try
					vTableOut = ThisObject["Employee" + String(vActionRow.EmployeeTableIndexTo)];
				Except
				EndTry;
			EndIf;
			
			// Add row
			vNewRowIn = vTableIn.Add();
			vNewRowIn.Icon = vActionRow.Icon;
			vNewRowIn.CheckInIcon = vActionRow.CheckInIcon;
			vNewRowIn.Room = TrimAll(tcOnServer.cmGetAttributeByRef(vActionRow.RoomRef, "Description"));
			vNewRowIn.RoomRef = vActionRow.RoomRef;
			vNewRowIn.RoomType = TrimAll(tcOnServer.cmGetAttributeByRef(vActionRow.RoomTypeRef, "Code"));
			vNewRowIn.RoomTypeRef = vActionRow.RoomTypeRef;
			vNewRowIn.Operation = TrimAll(tcOnServer.cmGetAttributeByRef(vActionRow.OperationRef, "Code"));
			vNewRowIn.OperationRef = vActionRow.OperationRef;
			vNewRowIn.NumberOfGuests = vActionRow.NumberOfGuests;
			vNewRowIn.UUID = vActionRow.UUID;
			vFindedRows = Undefined;
			If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
				Notify("OperationSchedule.EmployeeAssignment", New Structure("Room, Operation, Employee, UUID", vNewRowIn.RoomRef, vNewRowIn.OperationRef, vEmployeeIn, vNewRowIn.UUID), FormOwner);
			Else
				vFindedRows = FormOwner.ThisObject.Operations.FindRows(New Structure("Room, Operation", vNewRowIn.RoomRef, vNewRowIn.OperationRef, vEmployeeIn));
			EndIf;
			If vFindedRows <> Undefined And vFindedRows.Count() > 0 Then
				vFindedRow = vFindedRows.Get(0);
				vFindedRow.Employee = vEmployeeIn;
				vFindedRow.EmployeeSortCode = GetEmployeeSortCode(vFindedRow.Employee);
				// Get operation standards
				If ValueIsFilled(vFindedRow.Operation) Then
					vStandards = GetOperationRowStandards(vFindedRow.Operation, vFindedRow.RoomType, vFindedRow.Room, vFindedRow.Employee, Hotel);
					If vStandards <> Undefined Then
						vFindedRow.Duration = vStandards.Duration;
						vFindedRow.RoomSpace = vStandards.RoomSpace;
						vFindedRow.Price = vStandards.Price;
					EndIf;
				EndIf;
			EndIf;
			
			// Delete row
			vUndoRow = vTableOut.FindRows(New Structure("RoomRef", vActionRow.RoomRef)).Get(0);
			vTableOut.Delete(vUndoRow);
			
			// Index (XX) of current employee table (EmployeeXX)
			vIndex = vActionRow.EmployeeTableIndexFrom;
			vCol = 0;
			vBlocksGroupIndex = 0;
			// Col (XX) - index of current block (BlockXX)
			If Int(vIndex / NumberOfColumnsInBlock)*NumberOfColumnsInBlock = vIndex Then
				vCol = vIndex / NumberOfColumnsInBlock;
			ElsIf Int(vIndex / NumberOfColumnsInBlock)*NumberOfColumnsInBlock < vIndex Then
				vCol = Int(vIndex / NumberOfColumnsInBlock) + 1;
			EndIf;
			// BlocksGroupIndex (X) - index of current blocks group (BlocksGroupX)
			If Int(vCol/NumberOfEmployeeTablesInRow)=vCol/NumberOfEmployeeTablesInRow Then
				vBlocksGroupIndex = vCol/NumberOfEmployeeTablesInRow;
			Else
				vBlocksGroupIndex = Int(vCol/NumberOfEmployeeTablesInRow)+1;
			EndIf;
			
			// Update employee in form operations table
			vFindedRowsByCurRoom = Operations.FindRows(New Structure("Room, Operation", vNewRowIn.RoomRef, vNewRowIn.OperationRef));
			For Each vFindedRowByCurRoom In vFindedRowsByCurRoom Do
				vFindedRowByCurRoom.Employee = vEmployeeIn;
				vFindedRowByCurRoom.BlockIndex = vCol;
				vFindedRowByCurRoom.BlocksGroupIndex = vBlocksGroupIndex;
				vFindedRowByCurRoom.EmployeeTableIndex = vIndex;
				// Get operation standards
				If ValueIsFilled(vFindedRowByCurRoom.Operation) Then
					vStandards = GetOperationRowStandards(vFindedRowByCurRoom.Operation, vFindedRowByCurRoom.RoomType, vFindedRowByCurRoom.Room, vFindedRowByCurRoom.Employee, Hotel);
					If vStandards <> Undefined Then
						vFindedRowByCurRoom.Duration = vStandards.Duration;
						vFindedRowByCurRoom.RoomSpace = vStandards.RoomSpace;
						vFindedRowByCurRoom.Price = vStandards.Price;
					EndIf;
				EndIf;
			EndDo;
			
			// Delete row from history
			ActionHistory.Delete(ActionHistory.FindByID(vActionRow.GetID()));
		EndDo;
		vTableIn.Sort("Room");
		If vActionRow.BlockIndexTo <> 0 Then
			GetTotalTitleByBlock(vLastOperation.BlockIndexTo, "Label" + String(vLastOperation.BlockIndexTo), Items["Label" + String(vLastOperation.BlockIndexTo)].ToolTip);
		Else
			GetTotalTitleForClipboard();
		EndIf;
		If vActionRow.BlockIndexFrom <> 0 Then
			GetTotalTitleByBlock(vLastOperation.BlockIndexFrom, "Label" + String(vLastOperation.BlockIndexFrom), Items["Label" + String(vLastOperation.BlockIndexFrom)].ToolTip);
		Else
			GetTotalTitleForClipboard();
		EndIf;
		If ActionHistory.Count() = 0 Then
			Items.CommandUnDo.Enabled = False;
		EndIf;
		If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
			FormOwner.CalculateTotals();
		EndIf;
	EndIf;
EndProcedure // CommandUnDo

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandSave(pCommand)
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		vOperationArr = New Array();
		For Each DragOperationsRow In DragOperationsList Do
			vOperationArr.Add(New Structure("Room, Employee, UUID", DragOperationsRow.Room, DragOperationsRow.Employee, DragOperationsRow.UUID));	
		EndDo;
		If vOperationArr.Count() > 0 Then	
			Notify("OperationSchedule.EmployeeAssignment", vOperationArr, FormOwner);	
		EndIf;
	EndIf;
	IsModified = False;
EndProcedure // CommandSave

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandSaveAndClose(pCommand)
	CommandSave(Commands["CommandSave"]);
	Close();
EndProcedure // CommandSaveAndClose

#EndRegion

#Region Private

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure AddNewBlock(pNumber, pEmployeeName, pEmployee, FormWidth)
	// Get Index of current group of blocks
	If Int(pNumber / NumberOfEmployeeTablesInRow) = pNumber / NumberOfEmployeeTablesInRow Then
		vIndexOfBlocksGroup = pNumber / NumberOfEmployeeTablesInRow;
	Else
		vIndexOfBlocksGroup = Int(pNumber / NumberOfEmployeeTablesInRow) + 1;
	EndIf;
		
	// Get current group of blocks
	Try
		vCurBlocksGroup = Items["BlocksGroup"+String(vIndexOfBlocksGroup)];
	Except
		// Create new group of blocks
		vCurBlocksGroup = Items.Add("BlocksGroup"+String(vIndexOfBlocksGroup), Type("FormGroup"), Items.MainGroup);
		vCurBlocksGroup.Type = FormGroupType.UsualGroup;
		vCurBlocksGroup.Representation = UsualGroupRepresentation.None;
		vCurBlocksGroup.Group = ChildFormItemsGroup.Horizontal;
		vCurBlocksGroup.Title = NStr("ru=' ';en=' ';de=' '");
		vCurBlocksGroup.ShowTitle = False;
		vCurBlocksGroup.HorizontalStretch = True;
		vCurBlocksGroup.VerticalStretch = True;
		vCurBlocksGroup.ChildItemsWidth = ChildFormItemsWidth.Equal;
		If vIndexOfBlocksGroup > NumberOfBlocksGroupOnPage Then
			vCurBlocksGroup.Visible = False;
		EndIf;
		If vIndexOfBlocksGroup > PagesCount*NumberOfBlocksGroupOnPage Then
			PagesCount = PagesCount + 1;
		EndIf;
		BlocksGroupCount = BlocksGroupCount + 1;
	EndTry;
	
	// Create new group (BlockAndLabelGroup)
	vBlockAndLabelGroup = Items.Add("BlockAndLabelGroup" + String(pNumber), Type("FormGroup"), vCurBlocksGroup);
	vBlockAndLabelGroup.Type = FormGroupType.UsualGroup;
	vBlockAndLabelGroup.Representation = UsualGroupRepresentation.StrongSeparation;
	vBlockAndLabelGroup.Group = ChildFormItemsGroup.Vertical;
	vBlockAndLabelGroup.Title = pEmployeeName;
	vBlockAndLabelGroup.ToolTip = pEmployeeName;
	vBlockAndLabelGroup.ShowTitle = True;
	vBlockAndLabelGroup.HorizontalStretch = True;
	vBlockAndLabelGroup.VerticalStretch = True;
	
	// Create new group (Block)
	vBlock = Items.Add("Block"+String(pNumber), Type("FormGroup"), vBlockAndLabelGroup);
	vBlock.Type = FormGroupType.UsualGroup;
	vBlock.Representation = UsualGroupRepresentation.None;
	vBlock.Group = ChildFormItemsGroup.Horizontal;
	vBlock.ShowTitle = False;
	vBlock.ChildItemsWidth = ChildFormItemsWidth.Equal;
	vBlock.HorizontalStretch = True;
	vBlock.VerticalStretch = True;
	
	// Create new group (LabelGroup) 
	vLabelGroup = Items.Add("LabelGroup"+String(pNumber), Type("FormGroup"), vBlockAndLabelGroup);
	vLabelGroup.Type = FormGroupType.UsualGroup;
	vLabelGroup.Representation = UsualGroupRepresentation.None;
	vLabelGroup.Group = ChildFormItemsGroup.Horizontal;
	vLabelGroup.ShowTitle = False;
	vLabelGroup.ChildItemsWidth = ChildFormItemsWidth.Equal;
	vLabelGroup.HorizontalStretch = True;
	vLabelGroup.VerticalStretch = False;
	vLabelGroup.Height = 1;
	
	// Create new Label and Employee attributes
	vTempArray = New Array;
	vTempArray.Add(New FormAttribute("Label" + String(pNumber), New TypeDescription("String")));
	vTempArray.Add(New FormAttribute("EmployeeRef" + String(pNumber), New TypeDescription("CatalogRef.Employees")));
	ChangeAttributes(vTempArray);
	
	// Create new Label (Label)
	vLabel = Items.Add("Label" + String(pNumber), Type("FormField"), vLabelGroup);
	vLabel.Type = FormFieldType.LabelField;
	vLabel.DataPath = "Label" + String(pNumber);
	vlabel.TitleLocation = FormItemTitleLocation.None;
	vLabel.ToolTip = "";
	
	// Fill Employee attributes (EmployeeRefX)
	ThisObject["EmployeeRef" + String(pNumber)] = pEmployee;
	
	vRowsArray = Operations.FindRows(New Structure("Employee", pEmployee));
	vNumber = vRowsArray.Count();
	// Create new form attribute
	vNumberOfColumns = NumberOfColumnsInBlock;
	vInd = vNumberOfColumns-1;
	rCounter = 0;
	While vInd > -1 Do
		vIndStr = String(pNumber*vNumberOfColumns-vInd);
		
		vTempArray.Clear();
		vTempArray.Add(New FormAttribute("Employee" + vIndStr, New TypeDescription("ValueTable")));
		vTempArray.Add(New FormAttribute("Icon", New TypeDescription("Picture"), "Employee" + vIndStr));
		vTempArray.Add(New FormAttribute("CheckInIcon", New TypeDescription("Picture"), "Employee" + vIndStr));
		vTempArray.Add(New FormAttribute("Room", New TypeDescription("String"), "Employee" + vIndStr));
		vTempArray.Add(New FormAttribute("RoomType", New TypeDescription("String"), "Employee" + vIndStr));
		vTempArray.Add(New FormAttribute("RoomTypeRef", New TypeDescription("CatalogRef.RoomTypes"), "Employee" + vIndStr));
		vTempArray.Add(New FormAttribute("OperationRef", New TypeDescription("CatalogRef.Operations"), "Employee" + vIndStr));
		vTempArray.Add(New FormAttribute("Operation", New TypeDescription("String"), "Employee" + vIndStr));
		vTempArray.Add(New FormAttribute("RoomRef", New TypeDescription("CatalogRef.Rooms"), "Employee" + vIndStr));
		vTempArray.Add(New FormAttribute("NumberOfGuests", New TypeDescription("Number"), "Employee" + vIndStr));
		vTempArray.Add(New FormAttribute("UUID", New TypeDescription("UUID"), "Employee" + vIndStr));
		ChangeAttributes(vTempArray);
		
		// Fill attributes with value
		If (vNumber-Int(vNumber / vNumberOfColumns)* vNumberOfColumns) > 1 Then
			vNumberOfRowsInCurColumn = Int(vNumber / vNumberOfColumns) + 1;
		Else
			vNumberOfRowsInCurColumn = Int(vNumber / vNumberOfColumns) + vNumber - Int(vNumber / vNumberOfColumns) * vNumberOfColumns;
		EndIf;
     	FillAttributesWithValue(vTempArray.Get(0), vNumberOfRowsInCurColumn, vRowsArray, rCounter, pNumber * vNumberOfColumns - vInd, pNumber, vIndexOfBlocksGroup);
		
		// Create new EmployeeRooms table
		vNewEmployeeRooms = Items.Add("Employee"+vIndStr, Type("FormTable"), vBlock);
		vNewEmployeeRooms.DataPath = "Employee" + vIndStr; 
		vNewEmployeeRooms.CommandBarLocation = FormItemCommandBarLabelLocation.None;
		vNewEmployeeRooms.Header = False;
		vNewEmployeeRooms.Footer = False;
		vNewEmployeeRooms.TitleLocation = FormItemTitleLocation.None;
		vNewEmployeeRooms.HorizontalScrollBar = ScrollBarUse.DontUse;
		vNewEmployeeRooms.HorizontalLines = False;
		vNewEmployeeRooms.VerticalLines = False;
		vNewEmployeeRooms.Width = 60;
		vNewEmployeeRooms.RowSelectionMode = TableRowSelectionMode.Cell;
		vNewEmployeeRooms.SelectionMode = TableSelectionMode.MultiRow;
		vNewEmployeeRooms.AutoInsertNewRow = False;
		vNewEmployeeRooms.HorizontalStretch = True;
		vNewEmployeeRooms.VerticalStretch = True;
		vNewEmployeeRooms.CommandBarLocation = FormItemCommandBarLabelLocation.None;
		vNewEmployeeRooms.EnableDrag = True;
		vNewEmployeeRooms.EnableStartDrag = True;
		vNewEmployeeRooms.SetAction("OnActivateCell", "OnActivateCell");
		vNewEmployeeRooms.SetAction("DragStart", "DragStart");
		vNewEmployeeRooms.SetAction("Drag", "OnDrag");
		For Each vMenu In vNewEmployeeRooms.ContextMenu.ChildItems Do
			vMenu.Enabled = False;
		EndDo;
		vNewEmployeeRooms.ChangeRowSet = False;
		
		// Create new column of EmployeeRooms table (Icon)
		vIconCol = Items.Add(vNewEmployeeRooms.Name + "Icon", Type("FormField"), vNewEmployeeRooms);
		vIconCol.DataPath = "Employee" + vIndStr + ".Icon";
		vIconCol.Type = FormFieldType.PictureField;
		// Create new column of EmployeeRooms table (CheckInIcon) 
		vCheckInIconCol = Items.Add(vNewEmployeeRooms.Name + "CheckInIcon", Type("FormField"), vNewEmployeeRooms);
		vCheckInIconCol.DataPath = "Employee" + vIndStr + ".CheckInIcon";
		vCheckInIconCol.Type = FormFieldType.PictureField;
		// Create new column of EmployeeRooms table (Room) 
		vRoomsCol = Items.Add(vNewEmployeeRooms.Name + "Room", Type("FormField"), vNewEmployeeRooms);
		vRoomsCol.DataPath = "Employee" + vIndStr + ".Room";
		vRoomsCol.Type = FormFieldType.InputField;
		vRoomsCol.Title = NStr("ru=' ';en=' ';de=' '");
		vRoomsCol.Width = 6;
		vRoomsCol.HorizontalStretch = True;
		vRoomsCol.VerticalStretch = True;
		vRoomsCol.TextEdit = False;
		vRoomsCol.Font = New Font(, , True);
		vRoomsCol.HorizontalAlign = ItemHorizontalLocation.Left;
		vRoomsCol.ReadOnly = True;
		// Create new column of EmployeeRooms table (RoomTypes) 
		vRoomTypesCol = Items.Add(vNewEmployeeRooms.Name + "RoomType", Type("FormField"), vNewEmployeeRooms);
		vRoomTypesCol.DataPath = "Employee" + vIndStr + ".RoomType";
		vRoomTypesCol.Type = FormFieldType.InputField;
		vRoomTypesCol.Title = NStr("ru=' ';en=' ';de=' '");
		vRoomTypesCol.Width = 4;
		vRoomTypesCol.HorizontalStretch = True;
		vRoomTypesCol.VerticalStretch = True;
		vRoomTypesCol.TextEdit = False;
		vRoomTypesCol.HorizontalAlign = ItemHorizontalLocation.Left;
		vRoomTypesCol.ReadOnly = True;
        // Create new column of EmployeeRooms table (Operation) 
		vOperationCol = Items.Add(vNewEmployeeRooms.Name + "Operation", Type("FormField"), vNewEmployeeRooms);
		vOperationCol.DataPath = "Employee"+vIndStr+".Operation";
		vOperationCol.Type = FormFieldType.InputField;
		vOperationCol.Title = NStr("ru=' ';en=' ';de=' '");
		vOperationCol.Width = 3;
		vOperationCol.HorizontalStretch = True;
		vOperationCol.VerticalStretch = True;
		vOperationCol.TextEdit = False;
		vOperationCol.HorizontalAlign = ItemHorizontalLocation.Left;
		vOperationCol.ReadOnly = True;
		// Create new column of EmployeeRooms table (GuestCount) 
		vNumberOfGuestsCol = Items.Add(vNewEmployeeRooms.Name + "NumberOfGuests", Type("FormField"), vNewEmployeeRooms);
		vNumberOfGuestsCol.DataPath = "Employee"+vIndStr+".NumberOfGuests";
		vNumberOfGuestsCol.Type = FormFieldType.InputField;
		vNumberOfGuestsCol.Title = NStr("en='G.';ru='Г.';de='G.'");
		vNumberOfGuestsCol.Width = 2;
		vNumberOfGuestsCol.HorizontalStretch = True;
		vNumberOfGuestsCol.VerticalStretch = True;
		vNumberOfGuestsCol.TextEdit = False;
		vNumberOfGuestsCol.HorizontalAlign = ItemHorizontalLocation.Left;
		vNumberOfGuestsCol.ReadOnly = True;

        vNumber = vNumber - vNumberOfRowsInCurColumn;
		vNumberOfColumns = vNumberOfColumns - 1;
		vInd = vInd - 1;
	EndDo;
	GetTotalTitleByBlock(pNumber, vLabel.Name, vLabel.ToolTip);
EndProcedure // AddNewBlock

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure GetTotalTitleByBlock(pBlockIndex, pLabelName, rLabelToolTip)
	// Total
	vTotalDuration = 0;
	vTotalRoomSpace = 0;
	vTotalPrice = 0;
	vOperationCodesArray = New Array;
	vFindedRowsInOperationsTableByCurEmployee = Operations.FindRows(New Structure("Employee", ThisObject["EmployeeRef"+String(pBlockIndex)]));
	If vFindedRowsInOperationsTableByCurEmployee.Count() > 0 Then
		vOperationCodesArray = New Array;
		For Each vOperationRow In vFindedRowsInOperationsTableByCurEmployee Do
			If vOperationCodesArray.Find(vOperationRow.Operation) = Undefined Then
				vOperationCodesArray.Add(vOperationRow.Operation);
				// New conditional appearance
				vInd = NumberOfColumnsInBlock - 1;
				While vInd > -1 Do
					vNewConditionalAppearance = ConditionalAppearance.Items.Add();
					vNewConditionalAppearance.Appearance.Items[0].Value = vOperationRow.Operation.Color.Get();
					vNewConditionalAppearance.Appearance.Items[0].Use = True;
					// Filter
					vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
					vNewFilterForAppearance.LeftValue = New DataCompositionField("Employee"+String(pBlockIndex*NumberOfColumnsInBlock-vInd)+".Operation");
					vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
					vNewFilterForAppearance.RightValue = TrimAll(vOperationRow.Operation.Code);
					vNewFilterForAppearance.Use = True;
					// Fields
					vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
					vNewFieldsForApperance.Field = New DataCompositionField("Employee"+String(pBlockIndex*NumberOfColumnsInBlock-vInd)+"Operation");
					vNewFieldsForApperance.Use = True;
					
					If (ValueIsFilled(vOperationRow.Guest) And ValueIsFilled(vOperationRow.Guest.ClientType)) Or ValueIsFilled(vOperationRow.ClientType) Then
						vColor = ?(ValueIsFilled(vOperationRow.ClientType), vOperationRow.ClientType.Color.Get(), vOperationRow.Guest.ClientType.Color.Get());
						// Color for client types
						vNewConditionalAppearance = ConditionalAppearance.Items.Add();
						vNewConditionalAppearance.Appearance.Items[0].Value = vColor;
						vNewConditionalAppearance.Appearance.Items[0].Use = True;
						// Filter
						vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
						vNewFilterForAppearance.LeftValue = New DataCompositionField("Employee"+String(pBlockIndex*NumberOfColumnsInBlock-vInd)+".Room");
						vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
						vNewFilterForAppearance.RightValue = TrimAll(vOperationRow.Room.Description);
						vNewFilterForAppearance.Use = True;
						// Fields
						vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
						vNewFieldsForApperance.Field = New DataCompositionField("Employee"+String(pBlockIndex*NumberOfColumnsInBlock-vInd)+"Room");
						vNewFieldsForApperance.Use = True;
					EndIf;
					vInd = vInd - 1;
				EndDo;
			EndIf;
			vTotalDuration = vTotalDuration + vOperationRow.Duration;
			vTotalRoomSpace = vTotalRoomSpace + vOperationRow.RoomSpace;
			vTotalPrice = vTotalPrice + vOperationRow.Price;
		EndDo;
		vCodesCount = vOperationCodesArray.Count();
		If vCodesCount > 0 Then
			vLabel = "";
			vTotalOperationsCount = 0;
			For Each vOperationCode In vOperationCodesArray Do
				vFindedRows = Operations.FindRows(New Structure("BlockIndex, Operation", pBlockIndex, vOperationCode));
				If ValueIsFilled(vOperationCode) Then
					vCode = TrimAll(vOperationCode.Code);
				Else
					vCode = NStr("en='N/O';ru='Н/Р';de='N/D'");
				EndIf;
				vLabel = vLabel + vCode + "=" + String(vFindedRows.Count()) + ", ";
				vTotalOperationsCount = vTotalOperationsCount + vFindedRows.Count();
			EndDo;
			vLabel = vLabel + NStr("en='Σ'; ru='Σ'; de='Σ'") + "=" + String(vTotalOperationsCount);
			If vTotalDuration > 0 Then
				vLabel = vLabel + NStr("en=', T. '; ru=', Вр. '; de=', Zt. '") + 
		                          (Int(vTotalDuration/60)) + NStr("en='h '; ru='ч '; de='h '") + 
		                          (vTotalDuration - Int(vTotalDuration/60)*60) + NStr("en='m'; ru='м'; de='m'");
			EndIf;
			If vTotalRoomSpace > 0 Then
				If ValueIsFilled(vLabel) Then
					vLabel = vLabel + ", "	
				EndIf;
				vLabel = vLabel + NStr("en = 'Sq. '; de = 'Sq. '; ru = 'Пл. '") + vTotalRoomSpace;
			EndIf;
			If vTotalPrice > 0 Then
				If ValueIsFilled(vLabel) Then
					vLabel = vLabel + ", "	
				EndIf;
	            vLabel = vLabel + NStr("en = 'Sum. '; de = 'Sum. '; ru = 'Ст. '") + cmFormatSum(vTotalPrice, Hotel.BaseCurrency);
			EndIf;
		EndIf;
	Else
		vLabel = "";
	EndIf;
	ThisObject[pLabelName] = vLabel;
	rLabelToolTip = vLabel;
EndProcedure // GetTotalTitleByBlock

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure GetTotalTitleForClipboard()
	// Total
	vTotalDuration = 0;
	vTotalRoomSpace = 0;
	vTotalPrice = 0;
	vOperationCodesArray = New Array;
	vNotAssignedOperations = Operations.FindRows(New Structure("Employee", Catalogs.Employees.EmptyRef()));
	If vNotAssignedOperations.Count() > 0 Then
		vOperationCodesArray = New Array;
		For Each vOperationRow In vNotAssignedOperations Do
			If vOperationCodesArray.Find(vOperationRow.Operation) = Undefined Then
				vOperationCodesArray.Add(vOperationRow.Operation);
			EndIf;
			vTotalDuration = vTotalDuration + vOperationRow.Duration;
			vTotalRoomSpace = vTotalRoomSpace + vOperationRow.RoomSpace;
			vTotalPrice = vTotalPrice + vOperationRow.Price;
		EndDo;
		vCodesCount = vOperationCodesArray.Count();
		If vCodesCount > 0 Then
			vLabel = "";
			vTotalOperationsCount = 0;
			For Each vOperationCode In vOperationCodesArray Do
				vFindedRows = Operations.FindRows(New Structure("Employee, Operation", Catalogs.Employees.EmptyRef(), vOperationCode));
				If ValueIsFilled(vOperationCode) Then
					vCode = TrimAll(vOperationCode.Code);
				Else
					vCode = NStr("en='N/O';ru='Н/Р';de='N/D'");
				EndIf;
				vLabel = vLabel + vCode + "=" + String(vFindedRows.Count()) + ", ";
				vTotalOperationsCount = vTotalOperationsCount + vFindedRows.Count();
			EndDo;
			vLabel = vLabel + NStr("en='Σ'; ru='Σ'; de='Σ'") + "=" + String(vTotalOperationsCount);
			If vTotalDuration > 0 Then
				vLabel = vLabel + NStr("en=', T. '; ru=', Вр. '; de=', Zt. '") + 
		                          (Int(vTotalDuration/60)) + NStr("en='h '; ru='ч '; de='h '") + 
		                          (vTotalDuration - Int(vTotalDuration/60)*60) + NStr("en='m'; ru='м'; de='m'");
			EndIf;
			If vTotalRoomSpace > 0 Then
				If ValueIsFilled(vLabel) Then
					vLabel = vLabel + ", "	
				EndIf;
				vLabel = vLabel + NStr("en = 'Sq. '; de = 'Sq. '; ru = 'Пл. '") + vTotalRoomSpace;
			EndIf;
			If vTotalPrice > 0 Then
				If ValueIsFilled(vLabel) Then
					vLabel = vLabel + ", "	
				EndIf;
	            vLabel = vLabel + NStr("en = 'Sum. '; de = 'Sum. '; ru = 'Ст. '") + cmFormatSum(vTotalPrice, Hotel.BaseCurrency);
			EndIf;				  
		EndIf;
	Else
		vLabel = "";
	EndIf;
	Items.ClipboardTotals.Title = vLabel;
	Items.ClipboardTotals.ToolTip = vLabel;
EndProcedure // GetTotalTitleForClipboard

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure FillAttributesWithValue(pAttribute, pNumberOfRowsInCurColumn, pRowsArray, rCounter, pEmployeeTableIndex, pBlockIndex, pBlocksGroupIndex)
	For vInd = rCounter To rCounter+pNumberOfRowsInCurColumn-1 Do
		vCurRowsArrayRow = pRowsArray.Get(vInd);
		If pEmployeeTableIndex = -1 Then
			// Add new row in Clipboard
			vNewClipboardRow = Clipboard.Add();
			vIcon = PictureLib.Empty;
			vCheckInIcon = PictureLib.Empty;
			If vCurRowsArrayRow.IsCheckInWaiting Then
				vCheckInIcon = PictureLib.CheckIn;
			EndIf;
			If ValueIsFilled(vCurRowsArrayRow.Room.RoomStatus) And ValueIsFilled(vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon) Then
				If vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.None Then
					vIcon = PictureLib.Empty;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
					vIcon = PictureLib.RoomStatusReserved;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
					vIcon = PictureLib.Occupied;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
					vIcon = PictureLib.OccupiedDirty;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
					vIcon = PictureLib.Waiting;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
					vIcon = PictureLib.RoomStatusCleaning;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
					vIcon = PictureLib.TidyingUp;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
					vIcon = PictureLib.Vacant;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
					vIcon = PictureLib.RoomStatusRepair;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
					vIcon = PictureLib.RoomStatusLuggage;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
					vIcon = PictureLib.RoomStatusMalfunction;
				Else
					vIcon = PictureLib.Empty;
				EndIf;
			EndIf;
			vNewClipboardRow.Icon = vIcon;
			vNewClipboardRow.CheckInIcon = vCheckInIcon;
			vNewClipboardRow.Room = TrimAll(vCurRowsArrayRow.Room.Description);
			vNewClipboardRow.RoomType = TrimAll(vCurRowsArrayRow.RoomType.Code);
			vNewClipboardRow.Operation = TrimAll(vCurRowsArrayRow.Operation.Code);
			vNewClipboardRow.RoomRef = vCurRowsArrayRow.Room;
			vNewClipboardRow.RoomTypeRef = vCurRowsArrayRow.RoomType;
			vNewClipboardRow.OperationRef = vCurRowsArrayRow.Operation;
			vNewClipboardRow.UUID = vCurRowsArrayRow.UUID;
		Else
			// Add new row in EmployeeTable
			vNewRoomStr = ThisObject[pAttribute.Name].Add();
			vNewRoomStr.RoomRef = vCurRowsArrayRow.Room;
			vNewRoomStr.Room = TrimAll(vCurRowsArrayRow.Room.Description);
			vNewRoomStr.RoomTypeRef = vCurRowsArrayRow.RoomType;
			vNewRoomStr.RoomType = TrimAll(vCurRowsArrayRow.RoomType.Code);
			vNewRoomStr.OperationRef = vCurRowsArrayRow.Operation;
			vNewRoomStr.Operation = TrimAll(vCurRowsArrayRow.Operation.Code);
			vNewRoomStr.NumberOfGuests = vCurRowsArrayRow.NumberOfGuests;
			vIcon = PictureLib.Empty;
			vCheckInIcon = PictureLib.Empty;
			If vCurRowsArrayRow.IsCheckInWaiting Then
				vCheckInIcon = PictureLib.CheckIn;
			EndIf;
			If ValueIsFilled(vCurRowsArrayRow.Room.RoomStatus) And ValueIsFilled(vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon) Then
				If vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.None Then
					vIcon = PictureLib.Empty;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
					vIcon = PictureLib.RoomStatusReserved;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
					vIcon = PictureLib.Occupied;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
					vIcon = PictureLib.OccupiedDirty;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
					vIcon = PictureLib.Waiting;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
					vIcon = PictureLib.RoomStatusCleaning;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
					vIcon = PictureLib.TidyingUp;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
					vIcon = PictureLib.Vacant;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
					vIcon = PictureLib.RoomStatusRepair;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
					vIcon = PictureLib.RoomStatusLuggage;
				ElsIf vCurRowsArrayRow.Room.RoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
					vIcon = PictureLib.RoomStatusMalfunction;
				Else
					vIcon = PictureLib.Empty;
				EndIf;
			EndIf;
			vNewRoomStr.Icon = vIcon;
			vNewRoomStr.CheckInIcon = vCheckInIcon;
			// Change row in operations table
			vOperationsRow = Operations.FindByID(vCurRowsArrayRow.GetID());
			vOperationsRow.BlockIndex = pBlockIndex;
			vOperationsRow.BlocksGroupIndex = pBlocksGroupIndex;
			vOperationsRow.EmployeeTableIndex = pEmployeeTableIndex;
			vNewRoomStr.UUID = vCurRowsArrayRow.UUID;
		EndIf;
	EndDo;
	rCounter = rCounter + pNumberOfRowsInCurColumn;
EndProcedure // FillAttributesWithValue

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure OnOpenAtServer()
	vArrayWithRowsToDelete = New Array;
	For Each vOperRow In Operations Do
		If Not ValueIsFilled(vOperRow.Operation) Then
			vArrayWithRowsToDelete.Add(vOperRow);
		EndIf;
	EndDo;
	For Each vArrayItem In vArrayWithRowsToDelete Do
		Operations.Delete(vArrayItem);
	EndDo;
	vOperationsList = FormAttributeToValue("Operations");
	vOperationsList.Sort("Operation");
	vCurOperation = Undefined;
	// Add clipboard appearance
	For Each vOperationRow In vOperationsList Do
		If ValueIsFilled(vOperationRow.Operation) Then
			If vCurOperation <> vOperationRow.Operation Then
				// Color for operations
				vNewConditionalAppearance = ConditionalAppearance.Items.Add();
				vNewConditionalAppearance.Appearance.Items[0].Value = vOperationRow.Operation.Color.Get();
				vNewConditionalAppearance.Appearance.Items[0].Use = True;
				// Filter
				vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
				vNewFilterForAppearance.LeftValue = New DataCompositionField("Clipboard.Operation");
				vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
				vNewFilterForAppearance.RightValue = TrimAll(vOperationRow.Operation.Code);
				vNewFilterForAppearance.Use = True;
				// Fields
				vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
				vNewFieldsForApperance.Field = New DataCompositionField("ClipboardOperation");
				vNewFieldsForApperance.Use = True;
				vCurOperation = vOperationRow.Operation;
			EndIf;
		EndIf;
		If (ValueIsFilled(vOperationRow.Guest) And ValueIsFilled(vOperationRow.Guest.ClientType)) Or ValueIsFilled(vOperationRow.ClientType) Then
			vColor = ?(ValueIsFilled(vOperationRow.ClientType), vOperationRow.ClientType.Color.Get(), vOperationRow.Guest.ClientType.Color.Get());
			// Color for client types
			vNewConditionalAppearance = ConditionalAppearance.Items.Add();
			vNewConditionalAppearance.Appearance.Items[0].Value = vColor;
			vNewConditionalAppearance.Appearance.Items[0].Use = True;
			// Filter
			vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
			vNewFilterForAppearance.LeftValue = New DataCompositionField("Clipboard.Room");
			vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
			vNewFilterForAppearance.RightValue = TrimAll(vOperationRow.Room.Description);
			vNewFilterForAppearance.Use = True;
			// Fields
			vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
			vNewFieldsForApperance.Field = New DataCompositionField("ClipboardRoom");
			vNewFieldsForApperance.Use = True;
		EndIf;
	EndDo;
	// Add operations to Clipboard with no employee
	vFindedRows = Operations.FindRows(New Structure("Employee", Catalogs.Employees.EmptyRef()));
	FillAttributesWithValue("", vFindedRows.Count(), vFindedRows, 0, -1, -1, -1);
	// Create blocks
	If EmployeeList.Count() > 0 Then
		vTempArray = New Array;
		vTempArray.Add(New FormAttribute("BlockIndex", New TypeDescription("Number"), "Operations"));
		vTempArray.Add(New FormAttribute("BlocksGroupIndex", New TypeDescription("Number"), "Operations"));
		vTempArray.Add(New FormAttribute("EmployeeTableIndex", New TypeDescription("Number"), "Operations"));
		ChangeAttributes(vTempArray);
		For Each vEmployeeListRow In EmployeeList Do
			AddNewBlock(EmployeeList.IndexOf(vEmployeeListRow)+1, TrimAll(vEmployeeListRow.Value.Description), vEmployeeListRow.Value, FormWidth);
		EndDo;
	EndIf;
	GetTotalTitleForClipboard();
EndProcedure // OnOpenAtServer

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure OnDragEnd(pDragParametersValue)
	If DoDrag Then
		If ItemName = "Clipboard" Then
			vIndex = 0;
			vCol = 0;
			vBlocksGroupIndex = 0;
			// Delete row
			For Each vParametersRow In pDragParametersValue Do
				Clipboard.Delete(vParametersRow);
			EndDo;
			GetTotalTitleForClipboard();
		Else
			// Index (XX) of current employee table (EmployeeXX)
			vIndex = Number(Mid(ItemName,9));
			// Col (XX) - index of current block (BlockXX)
			If Int(vIndex / NumberOfColumnsInBlock) * NumberOfColumnsInBlock = vIndex Then
				vCol = vIndex / NumberOfColumnsInBlock;
			ElsIf Int(vIndex / NumberOfColumnsInBlock) * NumberOfColumnsInBlock < vIndex Then
				vCol = Int(vIndex / NumberOfColumnsInBlock) + 1;
			EndIf;
			// BlocksGroupIndex (X) - index of current blocks group (BlocksGroupX)
			If Int(vCol / NumberOfEmployeeTablesInRow)=vCol / NumberOfEmployeeTablesInRow Then
				vBlocksGroupIndex = vCol / NumberOfEmployeeTablesInRow;
			Else
				vBlocksGroupIndex = Int(vCol / NumberOfEmployeeTablesInRow) + 1;
			EndIf;
			For Each vParametersRow In pDragParametersValue Do
				// Delete row
				ThisObject[ItemName].Delete(vParametersRow);
			EndDo;
			GetTotalTitleByBlock(vCol, "Label" + String(vCol), Items["Label" + String(vCol)].ToolTip);
		EndIf;
		If ActionHistory.Count() > 0 Then
			vLastHistoryIndex = ActionHistory.Get(ActionHistory.Count() - 1).HistoryIndex;
			// Change operation in history
			vActionHistoryRows = ActionHistory.FindRows(New Structure("HistoryIndex", vLastHistoryIndex));
			For Each vActionHistoryRow In vActionHistoryRows Do
				vAction = ActionHistory.FindByID(vActionHistoryRow.GetID());
				vAction.BlockIndexFrom = vCol;
				vAction.BlocksGroupIndexFrom = vBlocksGroupIndex;
				vAction.EmployeeTableIndexFrom = vIndex;		
			EndDo;
		EndIf;
	EndIf;
EndProcedure // DragEnd

// --------------------------------------------------------------------------------------------------
&AtClient
Function GetEmployeeSortCode(pEmployeeRef)
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		vFindedRows = FormOwner.ThisObject.Object.Employees.FindRows(New Structure("Employee", pEmployeeRef));
	Else
		vFindedRows = FormOwner.ThisObject.Employees.FindRows(New Structure("Employee", pEmployeeRef));
	EndIf;
	If vFindedRows.Count() > 0 Then
		Return vFindedRows.Get(0).EmployeeSortCode;
	EndIf;
	Return "";
EndFunction // GetEmployeeSortCode

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure AfterShowQueryBox(pResult, pExtraParams) Export 
	If pResult = DialogReturnCode.Yes Then
		CommandSaveAndClose(Commands["CommandSaveAndClose"]);	
	ElsIf pResult = DialogReturnCode.No Then
		IsModified = False;
		Close();	
	EndIf;
EndProcedure // AfterShowQueryBox

// --------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetOperationRowStandards(pOperation, pRoomType, pRoom, pEmployee, pHotel)
	vStruct = Undefined;
	vStds = Catalogs.Operations.GetOperationStandards(pOperation, pHotel, pRoomType, pRoom, pEmployee);
	If vStds.Count() > 0 then
		vStdsRow = vStds.Get(0);
		
		vStruct = New Structure();
		vStruct.Insert("Duration", vStdsRow.Duration);
		vStruct.Insert("RoomSpace", vStdsRow.RoomSpace);
		vStruct.Insert("Price", vStdsRow.Price);
	EndIf;
	Return vStruct;
EndFunction // FillOperationRowStandards

#EndRegion
