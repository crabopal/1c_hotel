
#Region Variables

&AtClient
Var DoDrag;

#EndRegion

#Region FormEventHandlers

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
		Return;
	EndIf;  
EndProcedure

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Do form initialization
	ItemName = "";
	DoDrag = False;
	vClientDisplays = GetClientDisplaysInformation();
	vClientDisplay = vClientDisplays.Get(0);
	FormWidth = vClientDisplay.Width;
	FormHeight = vClientDisplay.Height;
	CurPageIndex = 1;
	PagesCount = 0;
	BlocksGroupCount = 0;
	NumberOfBlocksGroupOnPage = 2;
	NumberOfColumnsInBlock = 1;
	MaxNumberOfRowsInTable = 999999;
	NumberOfEmployeeTablesInRow = Int(FormWidth/(?(vClientDisplay.DPI = 0, 96, vClientDisplay.DPI)/96)/350);
	// Read data
	OnOpenAtServer();
	// Set form presentation
	Items.FormCommandLabelPage.Title = NStr("en='Page №';ru='Страница №';de='Seite Nr.'")+String(CurPageIndex);
	Items.FormCommandLabelShow.Title = NStr("en='Employees is shown 1 ... ';ru='Горничных показано с 1 по ';de='Zimmermädchen angezeigt ab 1 bis '")+String(Min(NumberOfEmployees, NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage))+NStr("en=' of ';de=' von ';ru=' из '")+String(NumberOfEmployees);
	Items.FormCommandPrev.Enabled = False;
	If CurPageIndex = PagesCount Then
		Items.FormCommandNext.Enabled = False;
	Else
		Items.FormCommandNext.Enabled = True;
	EndIf;
	If NumberOfEmployees > 0 Then
		For vInd = 1 To NumberOfEmployees Do
			Try
				vEmployeeTableContextMenu = Items["Employee"+String(vInd)+"ContextMenu"];
				For Each vItem In vEmployeeTableContextMenu.ChildItems Do
					vItem.Enabled = False;
				EndDo;
			Except
			EndTry;
		EndDo;
	EndIf;
	RefreshDataRepresentation();
	AttachIdleHandler("Refresh", 60, False);
EndProcedure //  OnOpen

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
EndProcedure //  OnActivateCell

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure DragStart(pItem, pDragParameters, pStandardProcessing)
	DoDrag = False;
	ItemName = pItem.Name;
	If Left(ItemName, 8) = "Employee" Then
		For Each vParamtersRow In pDragParameters.Value Do
			If TypeOf(vParamtersRow) = Type("Number") Then
				vRow = ThisObject[ItemName].FindByID(vParamtersRow);
				If vRow <> Undefined And vRow.IsFinished Then
					pStandardProcessing = False;
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure //  DragStart

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure OnDrag(pItem, pDragParameters, pStandardProcessing, pRow, pField)
	pStandardProcessing = False;
	If pItem.Name = "Clipboard" Then
		// Do drag
		If ActionHistory.Count() > 0 Then
			vHistoryIndex = ActionHistory.Get(ActionHistory.Count()-1).HistoryIndex + 1;
		Else
			vHistoryIndex = 1;
		EndIf;
		For Each vParamtersRow In pDragParameters.Value Do
			If TypeOf(vParamtersRow) = Type("FormDataCollectionItem") Then
				// Add new row in Clipboard table
				vNewStr = Clipboard.Add();
				vNewStr.RoomType = vParamtersRow.RoomType;
				vNewStr.RoomTypeRef = vParamtersRow.RoomTypeRef;
				vNewStr.Room = vParamtersRow.Room;
				vNewStr.RoomRef = vParamtersRow.RoomRef;
				vNewStr.Operation = vParamtersRow.Operation;
				vNewStr.OperationRef = vParamtersRow.OperationRef;
				vNewStr.NumberOfGuests = vParamtersRow.NumberOfGuests;
				vNewStr.Icon = vParamtersRow.Icon;
				vNewStr.CheckInIcon = vParamtersRow.CheckInIcon;
				vNewStr.IsFinished = vParamtersRow.IsFinished;
				vNewStr.EmployeeOperation = vParamtersRow.EmployeeOperation;
				vNewStr.ClientType = vParamtersRow.ClientType;
				// Update employee operation document
				vEmpOpRef = vParamtersRow.EmployeeOperation;
				If ValueIsFilled(vEmpOpRef) Then
					ClearEmployeeOperationDocument(vEmpOpRef);
				Else
					tcCommonFunctionOnClientServer.TextMessage("Failed to get employee operation!", MessageStatus.Attention);
				EndIf;
				vFindedRowsByCurRoom = Operations.FindRows(New Structure("Room, Operation", vParamtersRow.RoomRef, vParamtersRow.OperationRef));
				For Each vFindedRowByCurRoom In vFindedRowsByCurRoom Do
					vFindedRowByCurRoom.Employee = tcOnServer.cmGetCatalogItemRefByCode("Employees",,True);
					vFindedRowByCurRoom.BlockIndex = 0;
					vFindedRowByCurRoom.BlocksGroupIndex = 0;
					vFindedRowByCurRoom.EmployeeTableIndex = 0;
					// Get operation standards
					If ValueIsFilled(vFindedRowByCurRoom.Operation) Then
						vStandards = GetOperationRowStandards(vFindedRowByCurRoom.Operation, vFindedRowByCurRoom.RoomType, vFindedRowByCurRoom.Room, vFindedRowByCurRoom.Employee, Hotel);
						If vStandards <> Undefined Then
							vFindedRowByCurRoom.OperationDuration = vStandards.Duration;
							vFindedRowByCurRoom.RoomSpace = vStandards.RoomSpace;
							vFindedRowByCurRoom.Price = vStandards.Price;
						EndIf;
					EndIf;
				EndDo;
				// Add operation to history
				vActionHistoryRow = ActionHistory.Add();
				vActionHistoryRow.HistoryIndex = vHistoryIndex;
				vActionHistoryRow.Icon = vParamtersRow.Icon;
				vActionHistoryRow.CheckInIcon = vParamtersRow.CheckInIcon;
				vActionHistoryRow.RoomRef = vParamtersRow.RoomRef; 
				vActionHistoryRow.RoomTypeRef = vParamtersRow.RoomTypeRef;
				vActionHistoryRow.OperationRef = vParamtersRow.OperationRef;
				vActionHistoryRow.NumberOfGuests = vParamtersRow.NumberOfGuests;
				vActionHistoryRow.IsFinished = vParamtersRow.IsFinished;
				vActionHistoryRow.EmployeeOperation = vParamtersRow.EmployeeOperation;
				vActionHistoryRow.ClientType = vParamtersRow.ClientType;
				vActionHistoryRow.BlockIndexTo = 0;
				vActionHistoryRow.BlocksGroupIndexTo = 0;
				vActionHistoryRow.EmployeeTableIndexTo = 0;
				DoDrag = True;
			EndIf;
		EndDo;
		Clipboard.Sort("Room");
	Else
		// Index (XX) of current employee table (EmployeeXX)
		vIndex = Number(Mid(pItem.Name,9));
		// Col (XX) - index of current block (BlockXX)
		If Int(vIndex/NumberOfColumnsInBlock)*NumberOfColumnsInBlock = vIndex Then
			vCol = vIndex/NumberOfColumnsInBlock;
		ElsIf Int(vIndex/NumberOfColumnsInBlock)*NumberOfColumnsInBlock < vIndex Then
			vCol = Int(vIndex/NumberOfColumnsInBlock)+1;
		EndIf;
		// BlocksGroupIndex (X) - index of current blocks group (BlocksGroupX)
		If Int(vCol/NumberOfEmployeeTablesInRow)=vCol/NumberOfEmployeeTablesInRow Then
			vBlocksGroupIndex = vCol/NumberOfEmployeeTablesInRow;
		Else
			vBlocksGroupIndex = Int(vCol/NumberOfEmployeeTablesInRow)+1;
		EndIf;
		vCountOfRows = 0;
		vFieldWithMinCountOfRows = Undefined;
		// Get emplyee table in current block with min count of rows
		vInd = NumberOfColumnsInBlock-1;
		While vInd > -1 Do
			vCount = ThisObject["Employee"+String(vCol*NumberOfColumnsInBlock-vInd)].Count();
			If vCount < vCountOfRows Then
				vFieldWithMinCountOfRows = "Employee"+String(vCol*NumberOfColumnsInBlock-vInd);
				Break;
			Else
				vCountOfRows = ThisObject["Employee"+String(vCol*NumberOfColumnsInBlock-vInd)].Count();
			EndIf;
			vInd = vInd - 1;
		EndDo;
		If vFieldWithMinCountOfRows = Undefined Then
			vFieldWithMinCountOfRows = "Employee"+String(vCol*NumberOfColumnsInBlock-(NumberOfColumnsInBlock-1));
		EndIf;
		If ActionHistory.Count() > 0 Then
			vHistoryIndex = ActionHistory.Get(ActionHistory.Count()-1).HistoryIndex + 1;
		Else
			vHistoryIndex = 1;
		EndIf;
		// Do drag
		vEmployeeTable = ThisObject[vFieldWithMinCountOfRows];
		For Each vParamtersRow In pDragParameters.Value Do
			If TypeOf(vParamtersRow) = Type("FormDataCollectionItem") Then
				Try
					If vEmployeeTable.Count() = MaxNumberOfRowsInTable Then
						DoDrag = False;
						Break;
					Else
						// Add new row in EmployeeTable
						vNewStr = vEmployeeTable.Add();
						vNewStr.RoomType = vParamtersRow.RoomType;
						vNewStr.RoomTypeRef = vParamtersRow.RoomTypeRef;
						vNewStr.Room = vParamtersRow.Room;
						vNewStr.RoomRef = vParamtersRow.RoomRef;
						vNewStr.Operation = vParamtersRow.Operation;
						vNewStr.OperationRef = vParamtersRow.OperationRef;
						vNewStr.NumberOfGuests = vParamtersRow.NumberOfGuests;
						vNewStr.Icon = vParamtersRow.Icon;
						vNewStr.CheckInIcon = vParamtersRow.CheckInIcon;
						vNewStr.IsFinished = vParamtersRow.IsFinished;
						vNewStr.EmployeeOperation = vParamtersRow.EmployeeOperation;
						vNewStr.ClientType = vParamtersRow.ClientType;
						// Change row in operations tabular section
						vEmployeeRef = ThisObject["EmployeeRef"+String(vCol)];
						vEmpOpRef = vParamtersRow.EmployeeOperation;
						If ValueIsFilled(vEmpOpRef) Then
							UpdateEmployeeOperationDocument(vEmpOpRef, vEmployeeRef, WorkingHours);
							vFoundRowsByCurRoom = Operations.FindRows(New Structure("Room, Operation", vParamtersRow.RoomRef, vParamtersRow.OperationRef));
							If vFoundRowsByCurRoom.Count() > 0 Then
								vFoundRowByCurRoom = vFoundRowsByCurRoom.Get(0);
								vFoundRowByCurRoom.Employee = vEmployeeRef;
								vFoundRowByCurRoom.BlockIndex = vCol;
								vFoundRowByCurRoom.BlocksGroupIndex = vBlocksGroupIndex;
								vFoundRowByCurRoom.EmployeeTableIndex = vIndex;
								// Get operation standards
								If ValueIsFilled(vFoundRowByCurRoom.Operation) Then
									vStandards = GetOperationRowStandards(vFoundRowByCurRoom.Operation, vFoundRowByCurRoom.RoomType, vFoundRowByCurRoom.Room, vFoundRowByCurRoom.Employee, Hotel);
									If vStandards <> Undefined Then
										vFoundRowByCurRoom.OperationDuration = vStandards.Duration;
										vFoundRowByCurRoom.RoomSpace = vStandards.RoomSpace;
										vFoundRowByCurRoom.Price = vStandards.Price;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
						// Add operation to history
						vActionHistoryRow = ActionHistory.Add();
						vActionHistoryRow.HistoryIndex = vHistoryIndex;
						vActionHistoryRow.Icon = vParamtersRow.Icon;
						vActionHistoryRow.CheckInIcon = vParamtersRow.CheckInIcon;
						vActionHistoryRow.RoomRef = vParamtersRow.RoomRef; 
						vActionHistoryRow.RoomTypeRef = vParamtersRow.RoomTypeRef;
						vActionHistoryRow.OperationRef = vParamtersRow.OperationRef;
						vActionHistoryRow.NumberOfGuests = vParamtersRow.NumberOfGuests;
						vActionHistoryRow.IsFinished = vParamtersRow.IsFinished;
						vActionHistoryRow.EmployeeOperation = vParamtersRow.EmployeeOperation;
						vActionHistoryRow.ClientType = vParamtersRow.ClientType;
						vActionHistoryRow.BlockIndexTo = vCol;
						vActionHistoryRow.BlocksGroupIndexTo = vBlocksGroupIndex;
						vActionHistoryRow.EmployeeTableIndexTo = vIndex;
						Items.CommandUnDo.Enabled = True;
						DoDrag = True;
					EndIf;
				Except
					DoDrag = False;
				EndTry;
			EndIf;
		EndDo;
		vEmployeeTable.Sort("Room");
		GetTotalTitleByBlock(vCol, "Label"+String(vCol), Items["Label"+String(vCol)].ToolTip);
	EndIf;
	OnDragEnd(pDragParameters.Value);
EndProcedure //  OnDrag

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	
	RebuildAtServer();
EndProcedure

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure RoomGroupOnChange(Item)
	RefreshAtServer();
EndProcedure

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure RoomSectionOnChange(Item)
	RefreshAtServer();
EndProcedure

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure ShowCompletedOperationsOnChange(pItem)
	RefreshAtServer();
EndProcedure //  ShowCompletedOperationsOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandNext(pCommand)
	If CurPageIndex*NumberOfBlocksGroupOnPage<=BlocksGroupCount Then
		Try
			Items["BlocksGroup"+String(CurPageIndex*NumberOfBlocksGroupOnPage-1)].Visible = False;
			Items["BlocksGroup"+String(CurPageIndex*NumberOfBlocksGroupOnPage)].Visible = False;
			Items.FormCommandPrev.Enabled = True;
			CurPageIndex = CurPageIndex + 1;
			Items.FormCommandLabelPage.Title = NStr("en='Page №';ru='Страница №';de='Seite Nr.'")+String(CurPageIndex);
			If NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage*CurPageIndex > NumberOfEmployees Then
				vShowTo = NumberOfEmployees;
			Else
				vShowTo = NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage*CurPageIndex;
			EndIf;
			Items.FormCommandLabelShow.Title = NStr("en='Employees is shown ';ru='Горничных показано с ';de='Zimmermädchen angezeigt ab '")+String(NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage*CurPageIndex-NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage+1)+NStr("en=' ... ';ru=' по ';de=' bis '")+String(Min(NumberOfEmployees, vShowTo))+NStr("en=' of ';de=' von ';ru=' из '")+String(NumberOfEmployees);
			If CurPageIndex = PagesCount Then
				Items.FormCommandNext.Enabled = False;
			EndIf;	
			If CurPageIndex*NumberOfBlocksGroupOnPage>BlocksGroupCount Then
				Items["BlocksGroup"+String(CurPageIndex*NumberOfBlocksGroupOnPage-1)].Visible = True;
			Else
				Items["BlocksGroup"+String(CurPageIndex*NumberOfBlocksGroupOnPage-1)].Visible = True;
				Items["BlocksGroup"+String(CurPageIndex*NumberOfBlocksGroupOnPage)].Visible = True;
			EndIf;
		Except
		EndTry;	
	EndIf;		
EndProcedure //  CommandNext

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandPrev(pCommand)
	Try
		Items["BlocksGroup"+String(CurPageIndex*NumberOfBlocksGroupOnPage-1)].Visible = False;
		If CurPageIndex*NumberOfBlocksGroupOnPage<=BlocksGroupCount Then
			Items["BlocksGroup"+String(CurPageIndex*NumberOfBlocksGroupOnPage)].Visible = False;
		EndIf;
		Items.FormCommandNext.Enabled = True;
		CurPageIndex = CurPageIndex - 1;
		Items["BlocksGroup"+String(CurPageIndex*NumberOfBlocksGroupOnPage-1)].Visible = True;
		Items["BlocksGroup"+String(CurPageIndex*NumberOfBlocksGroupOnPage)].Visible = True;
		Items.FormCommandLabelPage.Title = NStr("en='Page №';ru='Страница №';de='Seite Nr.'")+String(CurPageIndex);
		If NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage*CurPageIndex > NumberOfEmployees Then
			vShowTo = NumberOfEmployees;
		Else
			vShowTo = NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage*CurPageIndex;
		EndIf;
		Items.FormCommandLabelShow.Title = NStr("en='Employees is shown ';ru='Горничных показано с ';de='Zimmermädchen angezeigt ab '")+String(NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage*CurPageIndex-NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage+1)+NStr("en=' ... ';ru=' по ';de=' bis '")+String(Min(NumberOfEmployees,vShowTo))+NStr("en=' of ';de=' von ';ru=' из '")+String(NumberOfEmployees);
		If CurPageIndex = 1 Then
			Items.FormCommandPrev.Enabled = False;
		EndIf;
	Except
	EndTry;	
EndProcedure //  CommandPrev

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandUnDo(pCommand)
	If ActionHistory.Count() > 0 Then
		vLastOperation = ActionHistory.Get(ActionHistory.Count()-1);
		vLastOperationHistoryIndex = vLastOperation.HistoryIndex;
		vActionRows = ActionHistory.FindRows(New Structure("HistoryIndex", vLastOperationHistoryIndex));
		For Each vActionRow In vActionRows Do
			If vActionRow.EmployeeTableIndexFrom = 0 Then
				vTableIn = Clipboard;
			Else
				Try
					vTableIn = ThisObject["Employee"+String(vActionRow.EmployeeTableIndexFrom)];
				Except
				EndTry;
			EndIf;
			If vActionRow.EmployeeTableIndexTo = 0 Then
				vTableOut = Clipboard;
			Else
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
			vNewRowIn.IsFinished = vActionRow.IsFinished;
			vNewRowIn.EmployeeOperation = vActionRow.EmployeeOperation;
			vNewRowIn.ClientType = vActionRow.ClientType;
			// Delete row
			vOldRowOut = vTableOut.FindRows(New Structure("EmployeeOperation", vActionRow.EmployeeOperation)).Get(0);
			vOldEmployee = PredefinedValue("Catalog.Employees.EmptyRef");
			If vActionRow.EmployeeTableIndexFrom > 0 Then
				vOldEmployee = EmployeeList.Get(vActionRow.EmployeeTableIndexFrom - 1).Value;
			EndIf;
			vTableOut.Delete(vOldRowOut);
			
			// Delete row from history 
			ActionHistory.Delete(ActionHistory.FindByID(vActionRow.GetID()));
			
			// Update operation document
			vEmpOpRef = vNewRowIn.EmployeeOperation;
			If vTableIn = Clipboard Then
				ClearEmployeeOperationDocument(vEmpOpRef);
			Else
				UpdateEmployeeOperationDocument(vEmpOpRef, vOldEmployee, WorkingHours);
			EndIf;
		EndDo;
		If vActionRow.BlockIndexTo <> 0 Then
			GetTotalTitleByBlock(vLastOperation.BlockIndexTo, "Label" + String(vLastOperation.BlockIndexTo), Items["Label" + String(vLastOperation.BlockIndexTo)].ToolTip);
		EndIf;
		If vActionRow.BlockIndexFrom <> 0 Then
			GetTotalTitleByBlock(vLastOperation.BlockIndexFrom, "Label" + String(vLastOperation.BlockIndexFrom), Items["Label" + String(vLastOperation.BlockIndexFrom)].ToolTip);
		EndIf;
		If ActionHistory.Count() = 0 Then
			Items.CommandUnDo.Enabled = False;
		EndIf;
	EndIf;
EndProcedure // CommandUnDo

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandRefresh(pCommand)
	RefreshAtServer();
EndProcedure //  CommandRefresh

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandAddEmployee(pCommand)
	vParams = New Structure("ChoiceMode", True);
	OpenForm("Catalog.Employees.ChoiceForm", vParams, ThisObject);
EndProcedure //  CommandAddEmployee

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandDeleteOperation(pCommand)
	vClipboardData = Items.Clipboard.CurrentData;
	If vClipboardData <> Undefined And ValueIsFilled(vClipboardData.EmployeeOperation) Then
		DeleteOperationAtServer(vClipboardData.EmployeeOperation);
		Clipboard.Delete(Items.Clipboard.CurrentData);
	EndIf;
EndProcedure //  CommandDeleteOperation

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandPrintOperations(pCommand)
	OpenForm("CommonForm.tcPrintEmployeeRoomAssignment", New Structure("Hotel, Room, RoomSection, HousekeepingDepartment, WorkingHours, Employee, EmployeeIndex", Hotel, Room, RoomSection, HousekeepingDepartment, WorkingHours, Undefined, 0));
EndProcedure

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure CommandPrintEmployeeOperations(pCommand)
	vEmployeeIndex = Number(Mid(CurrentItem.Name, 14));
	vEmployee = EmployeeList.Get(vEmployeeIndex - 1).Value;
	OpenForm("CommonForm.tcPrintEmployeeRoomAssignment", New Structure("Hotel, Room, RoomSection, HousekeepingDepartment, WorkingHours, Employee, EmployeeIndex", Hotel, Room, RoomSection, HousekeepingDepartment, WorkingHours, vEmployee, vEmployeeIndex));
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure AddNewBlock(pNumber, pEmployeeName, pEmployee, FormWidth)
	// Get Index of current group of blocks
	If Int(pNumber/NumberOfEmployeeTablesInRow) = pNumber/NumberOfEmployeeTablesInRow Then
		vIndexOfBlocksGroup = pNumber/NumberOfEmployeeTablesInRow;
	Else
		vIndexOfBlocksGroup = Int(pNumber/NumberOfEmployeeTablesInRow)+1;
	EndIf;
		
	// Get current group of blocks
	Try
		vCurBlocksGroup = Items["BlocksGroup" + String(vIndexOfBlocksGroup)];
	Except
		// Create new group of blocks 
		vCurBlocksGroup = Items.Add("BlocksGroup" + String(vIndexOfBlocksGroup), Type("FormGroup"), Items.MainGroup);
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
		DynItems.Add(vCurBlocksGroup.Name);
	EndTry;
	
	// Create new group (BlockAndLabelGroup) 
	vBlockAndLabelGroup = Items.Add("BlockAndLabelGroup"+String(pNumber), Type("FormGroup"), vCurBlocksGroup);
	vBlockAndLabelGroup.Type = FormGroupType.UsualGroup;
	vBlockAndLabelGroup.Representation = UsualGroupRepresentation.StrongSeparation;
	vBlockAndLabelGroup.Group = ChildFormItemsGroup.Vertical;
	vBlockAndLabelGroup.Title = pEmployeeName;
	vBlockAndLabelGroup.ToolTip = pEmployeeName;
	vBlockAndLabelGroup.ShowTitle = True;
	vBlockAndLabelGroup.HorizontalStretch = True;
	vBlockAndLabelGroup.VerticalStretch = True;
	DynItems.Add(vBlockAndLabelGroup.Name);
	
	// Create new group (Block)
	vBlock = Items.Add("Block"+String(pNumber), Type("FormGroup"), vBlockAndLabelGroup);
	vBlock.Type = FormGroupType.UsualGroup;
	vBlock.Representation = UsualGroupRepresentation.None;
	vBlock.Group = ChildFormItemsGroup.Horizontal;
	vBlock.ShowTitle = False;
	vBlock.ChildItemsWidth = ChildFormItemsWidth.Equal;
	vBlock.HorizontalStretch = True;
	vBlock.VerticalStretch = True;
	DynItems.Add(vBlock.Name);
	
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
	DynItems.Add(vLabelGroup.Name);
	
	// Create new Label and Employee attributes
	vTempArray = New Array;
	vTempArray.Add(New FormAttribute("Label"+String(pNumber), New TypeDescription("String")));
	vTempArray.Add(New FormAttribute("EmployeeRef"+String(pNumber), New TypeDescription("CatalogRef.Employees")));
	ChangeAttributes(vTempArray);
	For Each vElement In vTempArray Do
		DynAttributes.Add(vElement.Name);
	EndDo;
	
	// Create new Label (Label) 
	vLabel = Items.Add("Label"+String(pNumber), Type("FormField"), vLabelGroup);
	vLabel.Type = FormFieldType.LabelField;
	vLabel.DataPath = "Label"+String(pNumber);
	vlabel.TitleLocation = FormItemTitleLocation.None;
	vLabel.ToolTip = "";
	DynItems.Add(vLabel.Name);
	
	// Create new Button (PrintEmployee)>
	vPrintButton = Items.Add("PrintEmployee"+String(pNumber), Type("FormButton"), vLabelGroup);
	vPrintButton.Type = FormButtonType.UsualButton;
	vPrintButton.Enabled = True;
	vPrintButton.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	vPrintButton.CommandName = "CommandPrintEmployeeOperations";
	vPrintButton.SkipOnInput = True;
	vPrintButton.Representation = ButtonRepresentation.Picture;
	DynItems.Add(vPrintButton.Name);
	
	// Fill Employee attributes (EmployeeRefX)
	ThisObject["EmployeeRef"+String(pNumber)] = pEmployee;
	
	vRowsArray = Operations.FindRows(New Structure("Employee", pEmployee));
	vNumber = vRowsArray.Count();
	// Create new form attribute\
	vNumberOfColumns = NumberOfColumnsInBlock;
	vInd = vNumberOfColumns-1;
	rCounter = 0;
	While vInd > -1 Do
		vIndStr = String(pNumber*vNumberOfColumns-vInd);
		
		vTempArray.Clear();
		vTempArray.Add(New FormAttribute("Employee"+vIndStr, New TypeDescription("ValueTable")));
		DynAttributes.Add("Employee"+vIndStr);
		vTempArray.Add(New FormAttribute("Icon", New TypeDescription("Picture"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("CheckInIcon", New TypeDescription("Picture"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("Room", New TypeDescription("String"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("RoomType", New TypeDescription("String"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("RoomTypeRef", New TypeDescription("CatalogRef.RoomTypes"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("OperationRef", New TypeDescription("CatalogRef.Operations"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("Operation", New TypeDescription("String"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("RoomRef", New TypeDescription("CatalogRef.Rooms"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("NumberOfGuests", New TypeDescription("Number"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("IsFinished", New TypeDescription("Boolean"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("EmployeeOperation", New TypeDescription("DocumentRef.EmployeeOperation"), "Employee"+vIndStr));
		vTempArray.Add(New FormAttribute("ClientType", New TypeDescription("CatalogRef.ClientTypes"), "Employee"+vIndStr));
		ChangeAttributes(vTempArray);
		
		// Fill attributes with value 
		If (vNumber-Int(vNumber/vNumberOfColumns)*vNumberOfColumns)>1 Then
			vNumberOfRowsInCurColumn = Int(vNumber/vNumberOfColumns)+1;
		Else
			vNumberOfRowsInCurColumn = Int(vNumber/vNumberOfColumns)+vNumber-Int(vNumber/vNumberOfColumns)*vNumberOfColumns;
		EndIf;
     	FillAttributesWithValue(vTempArray.Get(0), vNumberOfRowsInCurColumn, vRowsArray, rCounter, pNumber*vNumberOfColumns-vInd, pNumber, vIndexOfBlocksGroup);
		
		// Create new EmployeeRooms table
		vNewEmployeeRooms = ThisForm.Items.Add("Employee"+vIndStr, Type("FormTable"), vBlock);
		vNewEmployeeRooms.DataPath = "Employee"+vIndStr; 
		vNewEmployeeRooms.CommandBarLocation = FormItemCommandBarLabelLocation.None;
		vNewEmployeeRooms.Header = False;
		vNewEmployeeRooms.Footer = False;
		vNewEmployeeRooms.TitleLocation = FormItemTitleLocation.None;
		vNewEmployeeRooms.HorizontalScrollBar = ScrollBarUse.DontUse;
		vNewEmployeeRooms.HorizontalLines = False;
		vNewEmployeeRooms.VerticalLines = False;
		vNewEmployeeRooms.Width = 60;
		vNewEmployeeRooms.RowSelectionMode = TableRowSelectionMode.Row;
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
		DynItems.Add(vNewEmployeeRooms.Name);
		
		// Create new column of EmployeeRooms table (Icon) 
		vIconCol = ThisForm.Items.Add(vNewEmployeeRooms.Name+"Icon", Type("FormField"), vNewEmployeeRooms);
		vIconCol.DataPath = "Employee"+vIndStr+".Icon";
		vIconCol.Type = FormFieldType.PictureField;
		vIconCol.Width = 1;
		DynItems.Add(vIconCol.Name);
		// Create new column of EmployeeRooms table (CheckInIcon) 
		vCheckInIconCol = ThisForm.Items.Add(vNewEmployeeRooms.Name+"CheckInIcon", Type("FormField"), vNewEmployeeRooms);
		vCheckInIconCol.DataPath = "Employee"+vIndStr+".CheckInIcon";
		vCheckInIconCol.Type = FormFieldType.PictureField;
		vCheckInIconCol.Width = 1;
		DynItems.Add(vCheckInIconCol.Name);
		// Create new column of EmployeeRooms table (Room) 
		vRoomsCol = ThisForm.Items.Add(vNewEmployeeRooms.Name+"Room", Type("FormField"), vNewEmployeeRooms);
		vRoomsCol.DataPath = "Employee"+vIndStr+".Room";
		vRoomsCol.Type = FormFieldType.InputField;
		vRoomsCol.Title = NStr("ru=' ';en=' ';de=' '");
		vRoomsCol.Width = 8;
		vRoomsCol.HorizontalStretch = True;
		vRoomsCol.VerticalStretch = True;
		vRoomsCol.TextEdit = False;
		vRoomsCol.Font = New Font(,,True);
		vRoomsCol.HorizontalAlign = ItemHorizontalLocation.Left;
		vRoomsCol.ReadOnly = True;
		DynItems.Add(vRoomsCol.Name);
		// Create new column of EmployeeRooms table (RoomTypes) 
		vRoomTypesCol = ThisForm.Items.Add(vNewEmployeeRooms.Name+"RoomType", Type("FormField"), vNewEmployeeRooms);
		vRoomTypesCol.DataPath = "Employee"+vIndStr+".RoomType";
		vRoomTypesCol.Type = FormFieldType.InputField;
		vRoomTypesCol.Title = NStr("ru=' ';en=' ';de=' '");
		vRoomTypesCol.Width = 5;
		vRoomTypesCol.HorizontalStretch = True;
		vRoomTypesCol.VerticalStretch = True;
		vRoomTypesCol.TextEdit = False;
		vRoomTypesCol.HorizontalAlign = ItemHorizontalLocation.Left;
		vRoomTypesCol.ReadOnly = True;
		DynItems.Add(vRoomTypesCol.Name);
        // Create new column of EmployeeRooms table (Operation) 
		vOperationCol = ThisForm.Items.Add(vNewEmployeeRooms.Name+"Operation", Type("FormField"), vNewEmployeeRooms);
		vOperationCol.DataPath = "Employee"+vIndStr+".Operation";
		vOperationCol.Type = FormFieldType.InputField;
		vOperationCol.Title = NStr("ru=' ';en=' ';de=' '");
		vOperationCol.Width = 8;
		vOperationCol.HorizontalStretch = True;
		vOperationCol.VerticalStretch = True;
		vOperationCol.TextEdit = False;
		vOperationCol.HorizontalAlign = ItemHorizontalLocation.Left;
		vOperationCol.ReadOnly = True;
		DynItems.Add(vOperationCol.Name);
		// Create new column of EmployeeRooms table (GuestCount) 
		vNumberOfGuestsCol = ThisForm.Items.Add(vNewEmployeeRooms.Name+"NumberOfGuests", Type("FormField"), vNewEmployeeRooms);
		vNumberOfGuestsCol.DataPath = "Employee"+vIndStr+".NumberOfGuests";
		vNumberOfGuestsCol.Type = FormFieldType.InputField;
		vNumberOfGuestsCol.Title = NStr("en='G.';ru='Г.';de='G.'");
		vNumberOfGuestsCol.Width = 2;
		vNumberOfGuestsCol.HorizontalStretch = True;
		vNumberOfGuestsCol.VerticalStretch = True;
		vNumberOfGuestsCol.TextEdit = False;
		vNumberOfGuestsCol.HorizontalAlign = ItemHorizontalLocation.Left;
		vNumberOfGuestsCol.ReadOnly = True;
		DynItems.Add(vNumberOfGuestsCol.Name);
		// Create new column of EmployeeRooms table (IsFinished) >
		vIsFinishedCol = ThisForm.Items.Add(vNewEmployeeRooms.Name+"IsFinished", Type("FormField"), vNewEmployeeRooms);
		vIsFinishedCol.DataPath = "Employee"+vIndStr+".IsFinished";
		vIsFinishedCol.Type = FormFieldType.CheckBoxField;
		vIsFinishedCol.Title = NStr("en='Finished';ru='Завершена';de='Fertig'");
		vIsFinishedCol.ReadOnly = True;
		vIsFinishedCol.Visible = True;
		DynItems.Add(vIsFinishedCol.Name);
		// Create new column of EmployeeRooms table (ClientType) >
		vClientTypeCol = ThisForm.Items.Add(vNewEmployeeRooms.Name+"ClientType", Type("FormField"), vNewEmployeeRooms);
		vClientTypeCol.DataPath = "Employee"+vIndStr+".ClientType";
		vClientTypeCol.Type = FormFieldType.InputField;
		vClientTypeCol.Title = NStr("en='Client type';ru='Тип клиента';de='Kundentyp'");
		vClientTypeCol.ReadOnly = True;
		vClientTypeCol.Visible = False;
		DynItems.Add(vClientTypeCol.Name);

        vNumber = vNumber - vNumberOfRowsInCurColumn;
		vNumberOfColumns = vNumberOfColumns - 1;
		vInd = vInd - 1;
	EndDo;
	
	// Font color for finshed operations
	vEmployeeIsFinished = ThisForm.ConditionalAppearance.Items.Add();
	vEmployeeIsFinished.Appearance.Items[1].Value = WebColors.MediumGray;
	vEmployeeIsFinished.Appearance.Items[1].Use = True;
	// Filter
	vEmployeeIsFinishedFilter = vEmployeeIsFinished.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vEmployeeIsFinishedFilter.LeftValue = New DataCompositionField("Employee" + pNumber + ".IsFinished");
	vEmployeeIsFinishedFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vEmployeeIsFinishedFilter.RightValue = True;
	vEmployeeIsFinishedFilter.Use = True;
	// Fields
	vEmployeeIsFinishedField = vEmployeeIsFinished.Fields.Items.Add();
	vEmployeeIsFinishedField.Field = New DataCompositionField("Employee" + String(pNumber) + "Room");
	vEmployeeIsFinishedField.Use = True;
	vEmployeeIsFinishedField = vEmployeeIsFinished.Fields.Items.Add();
	vEmployeeIsFinishedField.Field = New DataCompositionField("Employee" + String(pNumber) + "RoomType");
	vEmployeeIsFinishedField.Use = True;
	vEmployeeIsFinishedField = vEmployeeIsFinished.Fields.Items.Add();
	vEmployeeIsFinishedField.Field = New DataCompositionField("Employee" + String(pNumber) + "Operation");
	vEmployeeIsFinishedField.Use = True;
	vEmployeeIsFinishedField = vEmployeeIsFinished.Fields.Items.Add();
	vEmployeeIsFinishedField.Field = New DataCompositionField("Employee" + String(pNumber) + "NumberOfGuests");
	vEmployeeIsFinishedField.Use = True;
	
	vAllOperations = cmGetAllOperations(Hotel);
	For Each vOperationRow In vAllOperations Do
		// New conditional appearance
		vNewConditionalAppearance = ThisForm.ConditionalAppearance.Items.Add();
		vNewConditionalAppearance.Appearance.Items[0].Value = vOperationRow.Operation.Color.Get();
		vNewConditionalAppearance.Appearance.Items[0].Use = True;
		// Filter
		vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilterForAppearance.LeftValue = New DataCompositionField("Employee"+String(pNumber)+".Operation");
		vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
		vNewFilterForAppearance.RightValue = TrimAll(vOperationRow.Operation.Code);
		vNewFilterForAppearance.Use = True;
		// Fields
		vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
		vNewFieldsForApperance.Field = New DataCompositionField("Employee"+String(pNumber)+"Operation");
		vNewFieldsForApperance.Use = True;
	EndDo;
				
	vAllClientTypes = cmGetAllClientTypes(Hotel);
	For Each vClientTypeRow In vAllClientTypes Do
		vColor = vClientTypeRow.ClientType.Color.Get();
		// Color for client types
		vNewConditionalAppearance = ThisForm.ConditionalAppearance.Items.Add();
		vNewConditionalAppearance.Appearance.Items[0].Value = vColor;
		vNewConditionalAppearance.Appearance.Items[0].Use = True;
		// Filter
		vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilterForAppearance.LeftValue = New DataCompositionField("Employee"+String(pNumber)+".ClientType");
		vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
		vNewFilterForAppearance.RightValue = TrimAll(vClientTypeRow.ClientType);
		vNewFilterForAppearance.Use = True;
		// Fields
		vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
		vNewFieldsForApperance.Field = New DataCompositionField("Employee"+String(pNumber)+"Room");
		vNewFieldsForApperance.Use = True;
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
	vFindedRowsInOperationsTableByCurEmployee = Operations.FindRows(New Structure("Employee", ThisForm["EmployeeRef"+String(pBlockIndex)]));
	If vFindedRowsInOperationsTableByCurEmployee.Count() > 0 Then
		vOperationCodesArray = New Array;
		For Each vOperationRow In vFindedRowsInOperationsTableByCurEmployee Do
			If vOperationCodesArray.Find(vOperationRow.Operation) = Undefined Then
				vOperationCodesArray.Add(vOperationRow.Operation);
			EndIf;	
			vTotalDuration = vTotalDuration + ?(vOperationRow.OperationDuration = Null, 0, vOperationRow.OperationDuration);
			vTotalRoomSpace = vTotalRoomSpace + ?(vOperationRow.RoomSpace = Null, 0, vOperationRow.RoomSpace);
			vTotalPrice = vTotalPrice + ?(vOperationRow.Price = Null, 0, vOperationRow.Price); 
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
	ThisForm[pLabelName] = vLabel;
	rLabelToolTip = vLabel;
EndProcedure //  GetTotalTitleByBlock

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure UpdateBlockTotals(pBlockIndex, pLabelName, rLabelToolTip)
	// Block totals
	vTotalDuration = 0;
	vTotalRoomSpace = 0;
	vTotalPrice = 0;
	vOperationCodesArray = New Array;
	vFindedRowsInOperationsTableByCurEmployee = Operations.FindRows(New Structure("Employee", ThisForm["EmployeeRef"+String(pBlockIndex)]));
	If vFindedRowsInOperationsTableByCurEmployee.Count() > 0 Then
		vOperationCodesArray = New Array;
		For Each vOperationRow In vFindedRowsInOperationsTableByCurEmployee Do
			If vOperationCodesArray.Find(vOperationRow.Operation) = Undefined Then
				vOperationCodesArray.Add(vOperationRow.Operation);
			EndIf;	
			vTotalDuration = vTotalDuration + ?(vOperationRow.OperationDuration = Null, 0, vOperationRow.OperationDuration);
			vTotalRoomSpace = vTotalRoomSpace + ?(vOperationRow.RoomSpace = Null, 0, vOperationRow.RoomSpace);
			vTotalPrice = vTotalPrice + ?(vOperationRow.Price = Null, 0, vOperationRow.Price);	
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
	ThisForm[pLabelName] = vLabel;
	rLabelToolTip = vLabel;
EndProcedure //  UpdateBlockTotals

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure FillAttributesWithValue(pAttribute, pNumberOfRowsInCurColumn, pRowsArray, rCounter, pEmployeeTableIndex, pBlockIndex, pBlocksGroupIndex)
	For vInd = rCounter To rCounter+pNumberOfRowsInCurColumn-1 Do
		vCurRowsArrayRow = pRowsArray.Get(vInd);
		If pEmployeeTableIndex = -1 Then
			// Check, if it the additional guest in cur room
			vFindedRows = Operations.FindRows(New Structure("Room", vCurRowsArrayRow.Room));
			// Add new row in Clipboard
			vNewClipboardRow = Clipboard.Add();
			vIcon = GetRoomStatusIcon(vCurRowsArrayRow.Room);;
			vCheckInIcon = PictureLib.Empty;
			If vCurRowsArrayRow.IsCheckInWaiting Then
				vCheckInIcon = PictureLib.CheckIn;
			EndIf;
			vNewClipboardRow.Icon = vIcon;
			vNewClipboardRow.CheckInIcon = vCheckInIcon;
			vNewClipboardRow.Room = TrimAll(vCurRowsArrayRow.Room.Description);
			vNewClipboardRow.RoomType = TrimAll(vCurRowsArrayRow.RoomType.Code);
			vNewClipboardRow.Operation = TrimAll(vCurRowsArrayRow.Operation.Code);
			vNewClipboardRow.RoomRef = vCurRowsArrayRow.Room;
			vNewClipboardRow.RoomTypeRef = vCurRowsArrayRow.RoomType;
			vNewClipboardRow.OperationRef = vCurRowsArrayRow.Operation;
			vNewClipboardRow.IsFinished = vCurRowsArrayRow.IsFinished;
			vNewClipboardRow.EmployeeOperation = vCurRowsArrayRow.EmployeeOperation;
			vNewClipboardRow.ClientType = vCurRowsArrayRow.ClientType;
		Else
			// Add new row in EmployeeTable
			vNewRoomStr = ThisForm[pAttribute.Name].Add();
			vNewRoomStr.RoomRef = vCurRowsArrayRow.Room;
			vNewRoomStr.Room = TrimAll(vCurRowsArrayRow.Room.Description);
			vNewRoomStr.RoomTypeRef = vCurRowsArrayRow.RoomType;
			vNewRoomStr.RoomType = TrimAll(vCurRowsArrayRow.RoomType.Code);
			vNewRoomStr.OperationRef = vCurRowsArrayRow.Operation;
			vNewRoomStr.Operation = TrimAll(vCurRowsArrayRow.Operation.Code);
			vNewRoomStr.NumberOfGuests = vCurRowsArrayRow.NumberOfGuests;
			vNewRoomStr.IsFinished = vCurRowsArrayRow.IsFinished;
			vNewRoomStr.EmployeeOperation = vCurRowsArrayRow.EmployeeOperation;
			vNewRoomStr.ClientType = vCurRowsArrayRow.ClientType;
			vIcon = GetRoomStatusIcon(vCurRowsArrayRow.Room);
			vCheckInIcon = PictureLib.Empty;
			If vCurRowsArrayRow.IsCheckInWaiting Then
				vCheckInIcon = PictureLib.CheckIn;
			EndIf;
			vNewRoomStr.Icon = vIcon;
			vNewRoomStr.CheckInIcon = vCheckInIcon;
			// Change row in operations table
			vOperationsRow = Operations.FindByID(vCurRowsArrayRow.GetID());
			vOperationsRow.BlockIndex = pBlockIndex;
			vOperationsRow.BlocksGroupIndex = pBlocksGroupIndex;
			vOperationsRow.EmployeeTableIndex = pEmployeeTableIndex;
		EndIf;
	EndDo;
	rCounter = rCounter + pNumberOfRowsInCurColumn;
EndProcedure //  FillAttributesWithValue

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure OnOpenAtServer()
	WorkingHours = 12;
	Hotel = SessionParameters.CurrentHotel;
	// Add some attributes
	vTempArray = New Array;
	vTempArray.Add(New FormAttribute("BlockIndex", New TypeDescription("Number"), "Operations"));
	vTempArray.Add(New FormAttribute("BlocksGroupIndex", New TypeDescription("Number"), "Operations"));
	vTempArray.Add(New FormAttribute("EmployeeTableIndex", New TypeDescription("Number"), "Operations"));
	ChangeAttributes(vTempArray); 	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	// Check if hotel can be changed
	If Not IsInRole("RightsToChooseHotel") Then
		Items.Hotel.ReadOnly = True;
		Items.Hotel.ChoiceButton = False;
		Items.Hotel.ClearButton = False;
	EndIf;
	// Build at server
	BuildAtServer();
EndProcedure //  OnOpenAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetEmployees(pRebuildList = False) Export
	If pRebuildList Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Operations.Employee
		|FROM
		|	Document.EmployeeOperation AS Operations
		|WHERE
		|	Operations.Posted
		|	AND Operations.Employee <> &qEmptyEmployee
		|	AND (Operations.OperationEndTime = &qEmptyDate
		|			OR Operations.OperationEndTime <> &qEmptyDate
		|				AND Operations.OperationEndTime <= &qPeriodTo
		|				AND Operations.OperationEndTime >= &qPeriodFrom)
		|	AND (Operations.Hotel = &qHotel
		|			OR &qIsEmptyHotel)
		|	AND (Operations.Room IN HIERARCHY (&qRoom)
		|			OR &qIsEmptyRoom)
		|	AND (Operations.Room.RoomSection IN HIERARCHY (&qRoomSection)
		|			OR &qIsEmptyRoomSection)
		|	AND (Operations.Employee.Department IN HIERARCHY (&qDepartment)
		|			OR &qIsEmptyDepartment)
		|
		|GROUP BY
		|	Operations.Employee
		|
		|ORDER BY
		|	Operations.Employee.SortCode,
		|	Operations.Employee.Department.SortCode,
		|	Operations.Employee.Description";
		vQry.SetParameter("qPeriodFrom", CurrentSessionDate() - WorkingHours*3600);
		vQry.SetParameter("qPeriodTo", CurrentSessionDate() + WorkingHours*3600);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(Hotel));
		vQry.SetParameter("qRoom", Room);
		vQry.SetParameter("qIsEmptyRoom", Not ValueIsFilled(Room));
	    vQry.SetParameter("qRoomSection", RoomSection);
	    vQry.SetParameter("qIsEmptyRoomSection", Not ValueIsFilled(RoomSection));
		vQry.SetParameter("qDepartment", HousekeepingDepartment);
		vQry.SetParameter("qIsEmptyDepartment", Not ValueIsFilled(HousekeepingDepartment));
		vQry.SetParameter("qEmptyEmployee", Catalogs.Employees.EmptyRef());
		vEmployees = vQry.Execute().Unload();
		vEmployeesList = New ValueList();
		vEmployeesList.LoadValues(vEmployees.UnloadColumn("Employee"));
		Return vEmployeesList;
	Else
		Return EmployeeList;
	EndIf;
EndFunction //  GetEmployees

// -----------------------------------------------------------------------------
&AtServer
Procedure GetOperations() Export
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	ShiftOperations.Ref AS Ref,
	|	ShiftOperations.Operation AS Operation,
	|	ShiftOperations.Employee AS Employee,
	|	ShiftOperations.Hotel AS Hotel,
	|	ShiftOperations.RoomType AS RoomType,
	|	ShiftOperations.Room AS Room,
	|	ShiftOperations.OperationStartTime AS OperationStartTime,
	|	ShiftOperations.OperationEndTime AS OperationEndTime,
	|	ShiftOperations.NumberOfPersons AS NumberOfGuests,
	|	ShiftOperations.Quantity AS Quantity
	|INTO ShiftOperations
	|FROM
	|	Document.EmployeeOperation AS ShiftOperations
	|WHERE
	|	(ShiftOperations.Hotel = &qHotel
	|			OR &qIsEmptyHotel)
	|	AND (ShiftOperations.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (ShiftOperations.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
	|	AND (ShiftOperations.Employee.Department IN HIERARCHY (&qDepartment)
	|			OR &qIsEmptyDepartment)
	|	AND ShiftOperations.Posted
	|	AND (ShiftOperations.OperationEndTime = &qEmptyDate
	|			OR &qShowCompleted
	|				AND ShiftOperations.OperationEndTime <> &qEmptyDate
	|				AND ShiftOperations.OperationEndTime <= &qPeriodTo
	|				AND ShiftOperations.OperationEndTime >= &qPeriodFrom)
	|	AND ShiftOperations.Room IN HIERARCHY(&qRoomGroup)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ShiftOperations.Ref AS Ref,
	|	ShiftOperations.Operation AS Operation,
	|	ShiftOperations.Employee AS Employee,
	|	ShiftOperations.Employee.SortCode AS EmployeeSortCode,
	|	ShiftOperations.Employee.Description AS EmployeeDescription,
	|	ShiftOperations.Hotel AS Hotel,
	|	ShiftOperations.RoomType AS RoomType,
	|	ShiftOperations.Room AS Room,
	|	ShiftOperations.Room.SortCode AS RoomSortCode,
	|	ShiftOperations.OperationStartTime AS OperationStartTime,
	|	ShiftOperations.OperationEndTime AS OperationEndTime,
	|	ShiftOperations.NumberOfGuests AS NumberOfGuests,
	|	ShiftOperations.Quantity AS Quantity,
	|	CASE
	|		WHEN ShiftOperations.Employee = OperationStandards.Employee
	|				AND OperationStandards.Employee <> VALUE(Catalog.Employees.EmptyRef)
	|			THEN CASE
	|					WHEN ShiftOperations.Room = OperationStandards.Room
	|							AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|						THEN 250
	|					WHEN ShiftOperations.Room.Parent = OperationStandards.Room
	|							AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
	|							AND ShiftOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|						THEN 240
	|					WHEN ShiftOperations.RoomType = OperationStandards.RoomType
	|							AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|						THEN 230
	|					WHEN ShiftOperations.RoomType.Parent = OperationStandards.RoomType
	|							AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
	|							AND ShiftOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|						THEN 220
	|					ELSE 210
	|				END
	|		WHEN ShiftOperations.Employee.Parent = OperationStandards.Employee
	|				AND ISNULL(OperationStandards.Employee.IsFolder, FALSE)
	|				AND ShiftOperations.Employee <> VALUE(Catalog.Employees.EmptyRef)
	|			THEN CASE
	|					WHEN ShiftOperations.Room = OperationStandards.Room
	|							AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|						THEN 150
	|					WHEN ShiftOperations.Room.Parent = OperationStandards.Room
	|							AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
	|							AND ShiftOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|						THEN 140
	|					WHEN ShiftOperations.RoomType = OperationStandards.RoomType
	|							AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|						THEN 130
	|					WHEN ShiftOperations.RoomType.Parent = OperationStandards.RoomType
	|							AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
	|							AND ShiftOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|						THEN 120
	|					ELSE 110
	|				END
	|		ELSE CASE
	|				WHEN ShiftOperations.Room = OperationStandards.Room
	|						AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|					THEN 50
	|				WHEN ShiftOperations.Room.Parent = OperationStandards.Room
	|						AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
	|						AND ShiftOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|					THEN 40
	|				WHEN ShiftOperations.RoomType = OperationStandards.RoomType
	|						AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|					THEN 30
	|				WHEN ShiftOperations.RoomType.Parent = OperationStandards.RoomType
	|						AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
	|						AND ShiftOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|					THEN 20
	|				ELSE 10
	|			END
	|	END AS Weight,
	|	ISNULL(OperationStandards.Duration, 0) AS OperationDuration,
	|	ISNULL(OperationStandards.RoomSpace, 0) AS RoomSpace,
	|	ISNULL(OperationStandards.Price, 0) AS Price
	|INTO ShiftOperationsWithAllStandards
	|FROM
	|	ShiftOperations AS ShiftOperations
	|		LEFT JOIN InformationRegister.OperationStandards AS OperationStandards
	|		ON ShiftOperations.Operation = OperationStandards.Operation
	|			AND (OperationStandards.Operation <> VALUE(Catalog.Operations.EmptyRef))
	|			AND (ShiftOperations.Employee = OperationStandards.Employee
	|					AND OperationStandards.Employee <> VALUE(Catalog.Employees.EmptyRef)
	|				OR ShiftOperations.Employee.Parent = OperationStandards.Employee
	|					AND ISNULL(OperationStandards.Employee.IsFolder, FALSE)
	|					AND ShiftOperations.Employee <> VALUE(Catalog.Employees.EmptyRef)
	|				OR OperationStandards.Employee = VALUE(Catalog.Employees.EmptyRef))
	|			AND (ShiftOperations.Room = OperationStandards.Room
	|					AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|				OR ShiftOperations.Room.Parent = OperationStandards.Room
	|					AND ISNULL(OperationStandards.Room.IsFolder, FALSE)
	|					AND ShiftOperations.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|				OR OperationStandards.Room = VALUE(Catalog.Rooms.EmptyRef))
	|			AND (ShiftOperations.RoomType = OperationStandards.RoomType
	|					AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR ShiftOperations.RoomType.Parent = OperationStandards.RoomType
	|					AND ISNULL(OperationStandards.RoomType.IsFolder, FALSE)
	|					AND ShiftOperations.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR OperationStandards.RoomType = VALUE(Catalog.RoomTypes.EmptyRef))
	|			AND (OperationStandards.Duration <> 0
	|				OR OperationStandards.Price <> 0
	|				OR OperationStandards.RoomSpace <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WeightedShiftOperations.Ref AS Ref,
	|	MAX(WeightedShiftOperations.Weight) AS MaxWeight
	|INTO WeightedShiftOperations
	|FROM
	|	ShiftOperationsWithAllStandards AS WeightedShiftOperations
	|
	|GROUP BY
	|	WeightedShiftOperations.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Operations.Ref AS Ref,
	|	CASE
	|		WHEN Reservations.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS IsCheckInWaiting
	|INTO CheckInWaitingOperations
	|FROM
	|	ShiftOperationsWithAllStandards AS Operations
	|		INNER JOIN WeightedShiftOperations AS WeightedShiftOperations
	|		ON Operations.Ref = WeightedShiftOperations.Ref
	|			AND Operations.Weight = WeightedShiftOperations.MaxWeight
	|		LEFT JOIN Document.Reservation AS Reservations
	|		ON (Reservations.Posted)
	|			AND (Reservations.ReservationStatus.IsActive)
	|			AND (Reservations.CheckInDate >= &qPeriodFrom)
	|			AND (Reservations.CheckInDate <= &qPeriodTo)
	|			AND (Reservations.Room = Operations.Room)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Accommodations.Ref AS Ref,
	|	Accommodations.Room AS Room,
	|	Accommodations.SortCode AS SortCode,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.Guest.Code AS GuestCode,
	|	Accommodations.ClientType AS ClientType
	|INTO AllAccommodations
	|FROM
	|	Document.Accommodation AS Accommodations
	|		INNER JOIN ShiftOperationsWithAllStandards AS Operations
	|		ON Accommodations.Room = Operations.Room
	|WHERE
	|	Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.CheckInDate < &qPeriodTo
	|	AND Accommodations.CheckOutDate > &qPeriodFrom
	|	AND Accommodations.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|	AND Accommodations.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WeightedAccommodations1.Room AS Room,
	|	MIN(WeightedAccommodations1.SortCode) AS MinSortCode
	|INTO WeightedAccommodations1
	|FROM
	|	AllAccommodations AS WeightedAccommodations1
	|
	|GROUP BY
	|	WeightedAccommodations1.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WeightedAccommodations2.Room AS Room,
	|	WeightedAccommodations2.SortCode AS MinSortCode,
	|	MIN(WeightedAccommodations2.GuestCode) AS MinGuestCode
	|INTO WeightedAccommodations2
	|FROM
	|	AllAccommodations AS WeightedAccommodations2
	|		INNER JOIN WeightedAccommodations1 AS WeightedAccommodations1
	|		ON WeightedAccommodations2.Room = WeightedAccommodations1.Room
	|			AND WeightedAccommodations2.SortCode = WeightedAccommodations1.MinSortCode
	|
	|GROUP BY
	|	WeightedAccommodations2.Room,
	|	WeightedAccommodations2.SortCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Accommodations.Room AS Room,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.ClientType AS ClientType
	|INTO Accommodations
	|FROM
	|	AllAccommodations AS Accommodations
	|		INNER JOIN WeightedAccommodations2 AS WeightedAccommodations2
	|		ON Accommodations.Room = WeightedAccommodations2.Room
	|			AND Accommodations.SortCode = WeightedAccommodations2.MinSortCode
	|			AND Accommodations.GuestCode = WeightedAccommodations2.MinGuestCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operations.Ref AS EmployeeOperation,
	|	Operations.Room AS Room,
	|	Operations.RoomSortCode AS RoomSortCode,
	|	Operations.RoomType AS RoomType,
	|	Operations.RoomType.SortCode AS RoomTypeSortCode,
	|	Operations.Room.RoomStatus AS RoomStatus,
	|	Operations.Operation AS Operation,
	|	Operations.Operation.SortCode AS OperationSortCode,
	|	Operations.OperationStartTime AS OperationStartTime,
	|	Operations.OperationEndTime AS OperationEndTime,
	|	Operations.Employee AS Employee,
	|	Operations.NumberOfGuests AS NumberOfGuests,
	|	CASE
	|		WHEN Operations.OperationEndTime > &qEmptyDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsFinished,
	|	ISNULL(CheckInWaitingOperations.IsCheckInWaiting, FALSE) AS IsCheckInWaiting,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.ClientType AS ClientType,
	|	Operations.Quantity * Operations.OperationDuration AS OperationDuration,
	|	Operations.RoomSpace AS RoomSpace,
	|	Operations.Price AS Price
	|FROM
	|	ShiftOperationsWithAllStandards AS Operations
	|		INNER JOIN WeightedShiftOperations AS WeightedShiftOperations
	|		ON Operations.Ref = WeightedShiftOperations.Ref
	|			AND Operations.Weight = WeightedShiftOperations.MaxWeight
	|		LEFT JOIN CheckInWaitingOperations AS CheckInWaitingOperations
	|		ON Operations.Ref = CheckInWaitingOperations.Ref
	|		LEFT JOIN Accommodations AS Accommodations
	|		ON (Accommodations.Room = Operations.Room)
	|
	|ORDER BY
	|	Operations.EmployeeSortCode,
	|	Operations.EmployeeDescription,
	|	IsFinished,
	|	Operations.RoomSortCode";
	vQry.SetParameter("qPeriodFrom", CurrentSessionDate() - WorkingHours*3600);
	vQry.SetParameter("qPeriodTo", CurrentSessionDate() + WorkingHours*3600);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	vQry.SetParameter("qIsEmptyRoom", Not ValueIsFilled(Room));
    vQry.SetParameter("qRoomSection", RoomSection);
    vQry.SetParameter("qIsEmptyRoomSection", Not ValueIsFilled(RoomSection));
	vQry.SetParameter("qDepartment", HousekeepingDepartment);
	vQry.SetParameter("qIsEmptyDepartment", Not ValueIsFilled(HousekeepingDepartment));
	vQry.SetParameter("qRoomGroup", RoomGroup);
	vQry.SetParameter("qShowCompleted", ShowCompletedOperations);
	vOperations = vQry.Execute().Unload();
	// Fill form attribute
	Operations.Clear();
	For Each vOprRow In vOperations Do
		OprRow = Operations.Add();
		FillPropertyValues(OprRow, vOprRow);
	EndDo;
EndProcedure // GetOperations

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure CalculateTotals()
	vEmployeesCount = EmployeeList.Count();
	vOperationsCount = Operations.Count();
	DocumentDate = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	TotalOperations = Format(vOperationsCount, "ND=10; NFD=");
	TotalEmployees = "";
	AveragePerEmployee = NStr("en='Average per employee: '; ru='В среднем на сотрудника: '; de='Im Schnitt pro Mitarbeiter: '");
	If vEmployeesCount > 0 Then
		TotalEmployees = TotalEmployees + Format(EmployeeList.Count(), "ND=10; NFD=");
		AveragePerEmployee = AveragePerEmployee + Format(Round(vOperationsCount/vEmployeesCount, 0), "ND=10; NFD=");
	EndIf;
	vCheckOutOperations = 0;
	vOccupiedOperations = 0;
	vVacantOperations = 0;
	vRepairEndOperations = 0;
	For Each vOprRow In Operations Do
		If vOprRow.Operation = Hotel.CheckOutCleaning Then
			vCheckOutOperations = vCheckOutOperations + 1;
		ElsIf vOprRow.Operation = Hotel.RegularCleaning Then
			vOccupiedOperations = vOccupiedOperations + 1;
		ElsIf vOprRow.Operation = Hotel.VacantRoomCleaning Then
			vVacantOperations = vVacantOperations + 1;
		ElsIf vOprRow.Operation = Hotel.RepairEndCleaning Then
			vRepairEndOperations = vRepairEndOperations + 1;
		EndIf;
	EndDo;
	CheckOutCleaningCount = "          " + NStr("en='Check-out: '; ru='Выездные: '; de='Check-out: '") + Format(vCheckOutOperations, "ND=10; NFD=");
	CheckedOutLabel = NStr("en='Check-out: '; ru='Выездные: '; de='Check-out: '");
	If vEmployeesCount > 0 Then
		CheckedOutLabel = CheckedOutLabel + Format(Round(vCheckOutOperations/vEmployeesCount, 0), "ND=10; NFD=");
	EndIf;
	OccupiedRoomCleaningCount = "          " + NStr("en='Occupied: '; ru='В занятых номерах: '; de='In belegten Zimmern: '") + Format(vOccupiedOperations, "ND=10; NFD=");
	OccupiedLabel = NStr("en='Occupied: '; ru='В занятых номерах: '; de='In belegten Zimmern: '");
	If vEmployeesCount > 0 Then
		OccupiedLabel = OccupiedLabel + Format(Round(vOccupiedOperations/vEmployeesCount, 0), "ND=10; NFD=");
	EndIf;
	VacantRoomCleaningCount = "          " + NStr("en='Vacant: '; ru='В свободных номерах: '; de='In freien Zimmern: '") + Format(vVacantOperations, "ND=10; NFD=");
	VacantLabel = NStr("en='Vacant: '; ru='В свободных номерах: '; de='In freien Zimmern: '");
	If vEmployeesCount > 0 Then
		VacantLabel = VacantLabel + Format(Round(vVacantOperations/vEmployeesCount, 0), "ND=10; NFD=");
	EndIf;
	RepairEndCleaningCount = "          " + NStr("en='Repair end: '; ru='После ремонта: '; de='Nach Reparaturen: '") + Format(vRepairEndOperations, "ND=10; NFD=");
	RepairLabel = NStr("en='Repair end: '; ru='После ремонта: '; de='Nach Reparaturen: '");
	If vEmployeesCount > 0 Then
		RepairLabel = RepairLabel + Format(Round(vRepairEndOperations/vEmployeesCount, 0), "ND=10; NFD=");
	EndIf;
	
	vShowTo = NumberOfEmployees;
	If NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage*CurPageIndex <= NumberOfEmployees Then
		vShowTo = NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage*CurPageIndex;
	EndIf;
	Items.FormCommandLabelShow.Title = NStr("en='Employees is shown ';ru='Горничных показано с ';de='Zimmermädchen angezeigt ab '")+String(NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage*CurPageIndex-NumberOfEmployeeTablesInRow*NumberOfBlocksGroupOnPage+1)+NStr("en=' ... ';ru=' по ';de=' bis '")+String(Min(NumberOfEmployees, vShowTo))+NStr("en=' of ';de=' von ';ru=' из '")+String(NumberOfEmployees);
	
	If CurPageIndex = PagesCount Then
		Items.FormCommandNext.Enabled = False;
	Else
		Items.FormCommandNext.Enabled = True;
	EndIf;
	If NumberOfEmployees > 0 Then
		For vInd = 1 To NumberOfEmployees Do
			Try
				vEmployeeTableContextMenu = Items["Employee"+String(vInd)+"ContextMenu"];
				For Each vItem In vEmployeeTableContextMenu.ChildItems Do
					vItem.Enabled = False;
				EndDo;
			Except
			EndTry;
		EndDo;
	EndIf;
EndProcedure //  CalculateTotals 

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure OnDragEnd(pDragParametersValue)
	If DoDrag Then
		If ItemName = "Clipboard" Then
			vIndex = 0;
			vCol = 0;
			vBlocksGroupIndex = 0;
			//Delete row
			For Each vParamtersRow In pDragParametersValue Do
				ThisForm.Clipboard.Delete(vParamtersRow);
			EndDo;
		Else
			// Index (XX) of current employee table (EmployeeXX)
			vIndex = Number(Mid(ItemName,9));
			// Col (XX) - index of current block (BlockXX)
			If Int(vIndex/NumberOfColumnsInBlock)*NumberOfColumnsInBlock = vIndex Then
				vCol = vIndex/NumberOfColumnsInBlock;
			ElsIf Int(vIndex/NumberOfColumnsInBlock)*NumberOfColumnsInBlock < vIndex Then
				vCol = Int(vIndex/NumberOfColumnsInBlock)+1;
			EndIf;
			// BlocksGroupIndex (X) - index of current blocks group (BlocksGroupX)
			If Int(vCol/NumberOfEmployeeTablesInRow)=vCol/NumberOfEmployeeTablesInRow Then
				vBlocksGroupIndex = vCol/NumberOfEmployeeTablesInRow;
			Else
				vBlocksGroupIndex = Int(vCol/NumberOfEmployeeTablesInRow)+1;
			EndIf;
			vRowsInCurrentBlock = Operations.FindRows(New Structure("BlockIndex", vCol));
			vFirstEmployeeTableInBlock = ThisForm["Employee"+String(vCol*NumberOfColumnsInBlock-(NumberOfColumnsInBlock-1))];
			For Each vParamtersRow In pDragParametersValue Do
				// Delete row
				ThisForm[ItemName].Delete(vParamtersRow);
			EndDo;
			GetTotalTitleByBlock(vCol, "Label"+String(vCol), Items["Label"+String(vCol)].ToolTip);
		EndIf;
		If ActionHistory.Count() > 0 Then
			vLastHistoryIndex = ActionHistory.Get(ActionHistory.Count()-1).HistoryIndex;
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
EndProcedure //  DragEnd

// --------------------------------------------------------------------------------------------------
&AtServerNoContext
Procedure ClearEmployeeOperationDocument(pEmpOpRef)
	vEmpOpObj = pEmpOpRef.GetObject();
	vEmpOpObj.Employee = Catalogs.Employees.EmptyRef();
	vEmpOpObj.EmployeeAssignmentTime = '00010101';
	// Get operation standards
	If ValueIsFilled(vEmpOpObj.Operation) Then
		vStds = Catalogs.Operations.GetOperationStandards(vEmpOpObj.Operation, vEmpOpObj.Hotel, vEmpOpObj.RoomType, vEmpOpObj.Room, vEmpOpObj.Employee);
		If vStds.Count() > 0 then
			vStdsRow = vStds.Get(0);
			vEmpOpObj.Duration = vStdsRow.Duration;
			vEmpOpObj.RoomSpace = ?(vEmpOpObj.Quantity = 0, 1, vEmpOpObj.Quantity) * vStdsRow.RoomSpace;
			vEmpOpObj.Price = ?(vEmpOpObj.Quantity = 0, 1, vEmpOpObj.Quantity) * vStdsRow.Price;
		EndIf;
	EndIf;
	// Recalculate durations
	vEmpOpObj.pmCalculateDurations();
	// Save operation
	vEmpOpObj.Write(DocumentWriteMode.Posting);
EndProcedure //  ClearEmployeeOperationDocument

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure UpdateEmployeeOperationDocument(pEmpOpRef, pEmployee, pWorkingHours) 
	vEmpOpObj = pEmpOpRef.GetObject();
	vEmpOpObj.Employee = pEmployee;
	vEmpOpObj.EmployeeAssignmentTime = CurrentSessionDate();
	// Get operation standards
	If ValueIsFilled(vEmpOpObj.Operation) Then
		vStds = Catalogs.Operations.GetOperationStandards(vEmpOpObj.Operation, vEmpOpObj.Hotel, vEmpOpObj.RoomType, vEmpOpObj.Room, vEmpOpObj.Employee);
		If vStds.Count() > 0 then
			vStdsRow = vStds.Get(0);
			vEmpOpObj.Duration = vStdsRow.Duration;
			vEmpOpObj.RoomSpace = ?(vEmpOpObj.Quantity = 0, 1, vEmpOpObj.Quantity) * vStdsRow.RoomSpace;
			vEmpOpObj.Price = ?(vEmpOpObj.Quantity = 0, 1, vEmpOpObj.Quantity) * vStdsRow.Price;
		EndIf;
	EndIf;
	// Recalculate durations
	vEmpOpObj.pmCalculateDurations();
	// Save operation
	vEmpOpObj.Write(DocumentWriteMode.Posting);
EndProcedure //  UpdateEmployeeOperationDocument

// --------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomStatusIcon(pRoom)
	vIcon = PictureLib.Empty;
	If ValueIsFilled(pRoom) Then
		vRoomStatus = pRoom.RoomStatus;
		If ValueIsFilled(vRoomStatus) And ValueIsFilled(vRoomStatus.RoomStatusIcon) Then
			If vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.None Then
				vIcon = PictureLib.Empty;
			ElsIf vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
				vIcon = PictureLib.RoomStatusReserved;
			ElsIf vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
				vIcon = PictureLib.Occupied;
			ElsIf vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
				vIcon = PictureLib.OccupiedDirty;
			ElsIf vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
				vIcon = PictureLib.Waiting;
			ElsIf vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
				vIcon = PictureLib.RoomStatusCleaning;
			ElsIf vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
				vIcon = PictureLib.TidyingUp;
			ElsIf vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
				vIcon = PictureLib.Vacant;
			ElsIf vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
				vIcon = PictureLib.RoomStatusRepair;
			ElsIf vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
				vIcon = PictureLib.RoomStatusLuggage;
			ElsIf vRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
				vIcon = PictureLib.RoomStatusMalfunction;
			Else
				vIcon = PictureLib.Empty;
			EndIf;
		EndIf;
	EndIf;
	Return vIcon;
EndFunction //  GetRoomStatusIcon

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure UpdateNotAssignedRooms()
	Clipboard.Clear();
	vRows = Operations.FindRows(New Structure("Employee, IsFinished", Catalogs.Employees.EmptyRef(), False));
	FillAttributesWithValue("", vRows.Count(), vRows, 0, -1, -1, -1);
EndProcedure //  UpdateNotAssignedRooms

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure RefreshAtServer()
	// Get employees
	EmployeeList = GetEmployees(False);
	NumberOfEmployees = EmployeeList.Count();
	// Get operations
	GetOperations();
	// Update not assigned rooms
	UpdateNotAssignedRooms();
	// Update blocks
	For vInd = 1 To NumberOfEmployees Do
		vTableItem = ThisForm.Items["Employee"+vInd];
		vTable = ThisForm["Employee"+vInd];
		vTable.Clear();
		vLabelName = "Label"+String(vInd);
		vLabel = ThisForm.Items[vLabelName];
		vEmployee = EmployeeList.Get(vInd - 1).Value;
		vRowsArray = Operations.FindRows(New Structure("Employee", vEmployee));
		vNumber = vRowsArray.Count();
		vNumberOfColumns = NumberOfColumnsInBlock;
		vColInd = vNumberOfColumns-1;
		rCounter = 0;
		If Int(vInd/NumberOfEmployeeTablesInRow) = vInd/NumberOfEmployeeTablesInRow Then
			vIndexOfBlocksGroup = vInd/NumberOfEmployeeTablesInRow;
		Else
			vIndexOfBlocksGroup = Int(vInd/NumberOfEmployeeTablesInRow)+1;
		EndIf;
		If (vNumber-Int(vNumber/vNumberOfColumns)*vNumberOfColumns)>1 Then
			vNumberOfRowsInCurColumn = Int(vNumber/vNumberOfColumns)+1;
		Else
			vNumberOfRowsInCurColumn = Int(vNumber/vNumberOfColumns)+vNumber-Int(vNumber/vNumberOfColumns)*vNumberOfColumns;
		EndIf;
     	FillAttributesWithValue(vTableItem, vNumberOfRowsInCurColumn, vRowsArray, rCounter, vInd*vNumberOfColumns-vColInd, vInd, vIndexOfBlocksGroup);
		UpdateBlockTotals(vInd, vLabelName, vLabel.ToolTip);
	EndDo;
	// Calculate totals
	CalculateTotals();
EndProcedure //  RefreshAtServer

// --------------------------------------------------------------------------------------------------
&AtServer 
Procedure BuildAtServer()
	DynAttributes.Clear();
	DynItems.Clear();
	// Read employees
	EmployeeList = GetEmployees(True);
	NumberOfEmployees = EmployeeList.Count();
	// Read operations
	GetOperations();
	// Add operations to Clipboard with no employee
	vFindedRows = Operations.FindRows(New Structure("Employee, IsFinished", Catalogs.Employees.EmptyRef(), False));
	FillAttributesWithValue("", vFindedRows.Count(), vFindedRows, 0, -1, -1, -1);
	// Font color for finshed operations
	vNewConditionalAppearance = ThisForm.ConditionalAppearance.Items.Add();
	vNewConditionalAppearance.Appearance.Items[1].Value = WebColors.MediumGray;
	vNewConditionalAppearance.Appearance.Items[1].Use = True;
	// Filter
	vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilterForAppearance.LeftValue = New DataCompositionField("Clipboard.IsFinished");
	vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
	vNewFilterForAppearance.RightValue = True;
	vNewFilterForAppearance.Use = True;
	// Fields
	vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
	vNewFieldsForApperance.Field = New DataCompositionField("ClipboardRoom");
	vNewFieldsForApperance.Use = True;
	vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
	vNewFieldsForApperance.Field = New DataCompositionField("ClipboardRoomType");
	vNewFieldsForApperance.Use = True;
	vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
	vNewFieldsForApperance.Field = New DataCompositionField("ClipboardOperation");
	vNewFieldsForApperance.Use = True;
	vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
	vNewFieldsForApperance.Field = New DataCompositionField("ClipboardNumberOfGuests");
	vNewFieldsForApperance.Use = True;
	// Add clipboard appearance for operations
	vAllOperations = cmGetAllOperations(Hotel);
	For Each vOperationRow In vAllOperations Do
		// Color for operations
		vNewConditionalAppearance = ThisForm.ConditionalAppearance.Items.Add();
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
	EndDo;
	// Add clipboard appearance for client types
	vAllClientTypes = cmGetAllClientTypes(Hotel);
	For Each vClientTypesRow In vAllClientTypes Do
		vColor = vClientTypesRow.ClientType.Color.Get();
		// Color for client types
		vNewConditionalAppearance = ThisForm.ConditionalAppearance.Items.Add();
		vNewConditionalAppearance.Appearance.Items[0].Value = vColor;
		vNewConditionalAppearance.Appearance.Items[0].Use = True;
		// Filter
		vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilterForAppearance.LeftValue = New DataCompositionField("Clipboard.ClientType");
		vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
		vNewFilterForAppearance.RightValue = TrimAll(vClientTypesRow.ClientType);
		vNewFilterForAppearance.Use = True;
		// Fields
		vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
		vNewFieldsForApperance.Field = New DataCompositionField("ClipboardRoom");
		vNewFieldsForApperance.Use = True;
	EndDo;
	// Create blocks
	If EmployeeList.Count() > 0 Then
		For Each vEmployeeListRow In EmployeeList Do
			AddNewBlock(EmployeeList.IndexOf(vEmployeeListRow)+1, TrimAll(vEmployeeListRow.Value.Description), vEmployeeListRow.Value, FormWidth);
		EndDo;
	EndIf;
	// Calculate totals
	CalculateTotals();	
EndProcedure //  BuildAtServer

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure RebuildAtServer()
	// Clear conditional appearances
	ThisForm.ConditionalAppearance.Items.Clear();
	// Clear undo history
	ActionHistory.Clear();
	// Clear clipboard
	Clipboard.Clear();
	// Delete form items
	vDynItemsCount = DynItems.Count();
	For i = 1 To vDynItemsCount Do
		ThisForm.Items.Delete(ThisForm.Items[DynItems.Get(vDynItemsCount - i).Value]);
	EndDo;
	DynItems.Clear();
	// Delete attributes
	vAttrArray = New Array();
	For Each vAttrItem In DynAttributes Do
		vAttrArray.Add(vAttrItem.Value);
	EndDo;
	ChangeAttributes(, vAttrArray);
	DynAttributes.Clear();
	// Build at server
	BuildAtServer();
EndProcedure //  RebuildAtServer

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure Refresh() Export
	RefreshAtServer();
EndProcedure //  Refresh
	
// --------------------------------------------------------------------------------------------------
&AtClient
Procedure AddEmployee(pEmployee) Export
	If EmployeeList.FindByValue(pEmployee) = Undefined Then
		vEmployeeListRow = EmployeeList.Add(pEmployee);
		NumberOfEmployees = EmployeeList.Count();
		AddNewBlock(EmployeeList.IndexOf(vEmployeeListRow)+1, TrimAll(vEmployeeListRow.Value), vEmployeeListRow.Value, FormWidth);
		// Calculate totals
		CalculateTotals();	
	EndIf;
EndProcedure //  AddEmployee

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("CatalogRef.Employees") And ValueIsFilled(pSelectedValue) Then
		AddEmployee(pSelectedValue);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure DeleteOperationAtServer(pDocRef)
	pDocRef.GetObject().SetDeletionMark(True);
EndProcedure

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

