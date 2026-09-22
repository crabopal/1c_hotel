
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Fill form attributes
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf; 	
	// Use current date by default
	PeriodFromOnChangeAtServer();
EndProcedure //  OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(Item)
	HotelOnChangeAtServer();
EndProcedure //  HotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodFromOnChange(Item)
	PeriodFromOnChangeAtServer();
EndProcedure //  PeriodFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeeOnChange(Item)
	EmployeeOnChangeAtServer();
EndProcedure //  EmployeeOnChange


#EndRegion

#Region FormTableTableBoxItemsEventHandlers

// -----------------------------------------------------------------------------
// Delete documents for the given room type and operation
// -----------------------------------------------------------------------------
&AtServer
Procedure TableBoxOperationsBeforeDeleteRowAtServer(pCurRowID)
	vCurRow = TableBoxOperations.FindByID(pCurRowID);
	If vCurRow <> Undefined Then     		
		For i = 0 To 30 Do
			If Items.TableBoxOperations.ChildItems[2+i].Visible Then
				// Get all documents for the given day and delete them
				vDocs = GetDayDocuments(vCurRow, i);
				Try
					For Each vDocsRow In vDocs Do
						vDocObj = vDocsRow.Ref.GetObject();
						vDocObj.SetDeletionMark(True);
					EndDo;
				Except
					tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());
					pCancel = True;
					Return;
				EndTry;
			EndIf;
		EndDo;
	EndIf;	
EndProcedure //  TableBoxOperationsBeforeDeleteRowAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxOperationsBeforeDeleteRow(pItem, pCancel)
	// Ask for confirmation
	ShowQueryBox(New NotifyDescription("TableBoxOperationsBeforeDeleteRowEnd", ThisObject), NStr("en='Delete all operation daily totals for the current month?';ru='Удалить итоги по работе за все дни текущего месяца?';de='Arbeitsergebnisse für alle Tage des laufenden Monats löschen?'"), QuestionDialogMode.YesNo);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxOperationsAfterDeleteRow(pItem)
	// Recalculate totals
	CalculateTotalsPerDays();
EndProcedure //  TableBoxOperationsAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxOperationsOnEditEnd(pItem, pNewRow, pCancelEdit)
	vCurRow = Items.TableBoxOperations.CurrentData;
	If vCurRow <> Undefined Then
		vCurRowID = vCurRow.GetID();
		TableBoxOperationsOnEditEndAtServer(vCurRowID);
	EndIf;
EndProcedure //  TableBoxOperationsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxOperationsQuantityOnChange(pItem)  	
	vCurRow = Items.TableBoxOperations.CurrentData;
	If vCurRow <> Undefined Then 
		vCurRowID = vCurRow.GetID();  
		vCurItemName = pItem.Name;
		TableBoxOperationsQuantityOnChangeAtServer(vCurRowID, vCurItemName); 
	EndIf;
EndProcedure //  TableBoxOperationsQuantityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure();
	vFilter	= New Structure();	
	vParams.Insert("ChoiseMode", True);
	If ValueIsFilled(Hotel) Then
		vFilter.Insert("Hotel", Hotel);
	EndIf;
	If ValueIsFilled(Department) Then
		vFilter.Insert("Department", Department);
	EndIf;
	vParams.Insert("Filter", vFilter);
	OpenForm("Catalog.Employees.Form.tcChoiceForm", vParams, pItem);    
EndProcedure  // EmployeeStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionFillFromOtherEmployee(Command)
	// Check that current employee is choosen
	If Not ValueIsFilled(Employee) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Employee should be choosen!';ru='Не выбран сотрудник!';de='Kein Mitarbeiter ist gewählt!'"));
		Return;
	EndIf;
	// Choose template employee first
	vEmployee = Employee;
	ShowInputValue(New NotifyDescription("ShowInputEmplouee", ThisObject, New Structure("vEmployee", vEmployee)), vEmployee, NStr("en='Choose employee!';ru='Выберите сотрудника!';de='Wählen Sie den Mitarbeiter!'"));
EndProcedure //  ActionFillFromOtherEmployee

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintSchedule(Command)
	vReportRef = PredefinedValue("Catalog.Reports.EmployeeOperationsTurnovers");
	vParam = New Structure();
	vParam.Insert("ReportRef",vReportRef);
	If ValueIsFilled(Employee) Then
		vParam.Insert("Employee",Employee);
	EndIf;
	If ValueIsFilled(Hotel) Then
		vParam.Insert("Hotel",Hotel);
	EndIf;
	If ValueIsFilled(PeriodFrom) Then
		vParam.Insert("PeriodFrom",BegOfMonth(PeriodFrom));
		vParam.Insert("PeriodTo",EndOfMonth(PeriodFrom));
	EndIf;
	OpenForm("Report.EmployeeOperationsTurnovers.Form.tcReportForm", New Structure("FillingValues, GenerateOnOpen", vParam, True));  
EndProcedure //  PrintSchedule

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionFillFromPreviousMonth(Command)
	ActionFillFromPreviousMonthAtServer();
EndProcedure //  ActionFillFromPreviousMonth

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowInputEmplouee(pValue, AdditionalParameters) Export
	
	vEmployee = ?(pValue = Undefined, AdditionalParameters.vEmployee, pValue);
	
	If Not (pValue <> Undefined) Then
		vMessage = NStr("en='Wizard was canceled by user!';ru='Работа мастера прервана пользователем!';de='Die Arbeit des Masters wurde vom Nutzer unterbrochen!'"); 
		Message = New UserMessage;
		Message.Text = vMessage;
		Message.Message();
		Return;
	EndIf;
	// Check that template employee is choosen
	If Not ValueIsFilled(vEmployee) Then
		vMessage = NStr("en='Employee should be choosen!';ru='Не выбран сотрудник!';de='Kein Mitarbeiter ist gewählt!'");
		Message = New UserMessage;
		Message.Text = vMessage;
		Message.Field = "Employee";
		Message.Message();
		Return;
	EndIf;
	// Choose month
	vPeriodFrom = PeriodFrom;
	ShowInputDate(New NotifyDescription("ShowChooseMonth", ThisObject, New Structure("vEmployee, vPeriodFrom", vEmployee, vPeriodFrom)), vPeriodFrom, NStr("en='Choose month!';ru='Выберите месяц!';de='Wählen Sie den Monat!'"), DateFractions.Date);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowChooseMonth(pDate, AdditionalParameters1) Export
	vEmployee = AdditionalParameters1.vEmployee;
	vPeriodFrom = ?(pDate = Undefined, AdditionalParameters1.vPeriodFrom, pDate);
	
	If Not (pDate <> Undefined) Then
		vMessage = NStr("en='Wizard was canceled by user!';ru='Работа мастера прервана пользователем!';de='Die Arbeit des Masters wurde vom Nutzer unterbrochen!'"); 
		Message = New UserMessage;
		Message.Text = vMessage;
		Message.Message();
		Return;
	EndIf;
	ActionFillFromOtherEmployeeAtServer(vEmployee, vPeriodFrom);
EndProcedure //  ActionFillFromOtherEmployee

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxOperationsBeforeDeleteRowEnd(pQuestionResult, AdditionalParameters) Export
	
	If pQuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	vCurRow = Items.TableBoxOperations.CurrentData;
	If vCurRow <> Undefined Then
		vCurRowID = vCurRow.GetID();
		// Delete all documents for the current month
		TableBoxOperationsBeforeDeleteRowAtServer(vCurRowID);  
	EndIf;

EndProcedure //  TableBoxOperationsBeforeDeleteRow
// -----------------------------------------------------------------------------
&AtServer
Function GetEmployeeOperations(pEmployee, pHotel, pPeriodFrom, pPeriodTo)
	// Run query to get employee operations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BEGINOFPERIOD(EmployeeOperations.OperationStartTime, DAY) AS Period,
	|	EmployeeOperations.RoomType,
	|	EmployeeOperations.Operation,
	|	SUM(EmployeeOperations.Quantity) AS Quantity
	|FROM
	|	Document.EmployeeOperation AS EmployeeOperations
	|WHERE
	|	EmployeeOperations.Posted
	|	AND EmployeeOperations.Employee = &qEmployee
	|	AND EmployeeOperations.OperationStartTime >= &qPeriodFrom
	|	AND EmployeeOperations.OperationStartTime <= &qPeriodTo
	|	AND (EmployeeOperations.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|GROUP BY
	|	BEGINOFPERIOD(EmployeeOperations.OperationStartTime, DAY),
	|	EmployeeOperations.RoomType,
	|	EmployeeOperations.Operation
	|ORDER BY
	|	EmployeeOperations.RoomType.SortCode,
	|	EmployeeOperations.Operation.SortCode,
	|	Period";
	vQry.SetParameter("qPeriodFrom", BegOfMonth(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfMonth(pPeriodFrom));
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qEmployee", pEmployee);
	Return vQry.Execute().Unload();
EndFunction //  GetEmployeeOperations 

// -----------------------------------------------------------------------------
// Load employee operations list from the documents
&AtServer
Procedure LoadEmployeeOperations()
	// Clear list first
	TableBoxOperations.Clear();
	// Check that employee is choosen
	If Not ValueIsFilled(Employee) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Employee should be choosen!';ru='Не выбран сотрудник!';de='Kein Mitarbeiter ist gewählt!'"));
		Return;
	EndIf;
	// Run query to get employee operations
	vOperations = GetEmployeeOperations(Employee, Hotel, BegOfMonth(PeriodFrom), EndOfMonth(PeriodFrom));
	For Each vOprRow In vOperations Do
		vRows = TableBoxOperations.FindRows(New Structure("RoomType, Operation", vOprRow.RoomType, vOprRow.Operation));
		If vRows.Count() > 1 Then // Remove doubled rows
			While 1 < vRows.Count() Do
				vRow = vRows.Get(1);
				TableBoxOperations.Delete(vRow);
			EndDo;
		EndIf;
		// Add row if nothing found
		If vRows.Count() = 0 Then
			vRow = TableBoxOperations.Add();
			vRow.RoomType = vOprRow.RoomType;
			vRow.Operation = vOprRow.Operation;
		Else
			// Retrieve existing row
			vRow = vRows.Get(0);
		EndIf;
		// Calculate number of the day
		i = Round((BegOfDay(vOprRow.Period) - BegOfMonth(PeriodFrom))/(24*3600), 0);
		vRow["Quantity"+String(i+1)] = vOprRow.Quantity;
	EndDo;
	// Recalculate totals
	For Each vRow In TableBoxOperations Do
		CalculateTotalsPerOperation(vRow);
	EndDo;
	CalculateTotalsPerDays();
EndProcedure //  LoadEmployeeOperations

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateTotalsPerDays()
	// Calculate totals per day
	If TableBoxOperations.Count() > 0 Then 
		For i = 0 To 30 Do
			vDayQty =TableBoxOperations.Total("Quantity"+String(i+1));
			TableBoxOperations[0]["QuantityFooter"+String(i+1)] = Format(vDayQty, "ND=6; NFD=0; NG=");
		EndDo; 
		
	vMonthQty = TableBoxOperations.Total("QuantityPerMonth");
	TableBoxOperations[0]["QuantityPerMonthFooter"] =  Format(vMonthQty, "ND=6; NFD=0; NG=");  
	EndIf;   	
EndProcedure //  CalculateTotalsPerDays   

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	LoadEmployeeOperations();
EndProcedure //  HotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure EmployeeOnChangeAtServer()
	LoadEmployeeOperations(); 
EndProcedure //  EmployeeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PeriodFromOnChangeAtServer(pLoadOperations = True)
	If pLoadOperations = Undefined Then
		pLoadOperations = True;
	EndIf;
	// Reset start of the period to the beginning of month
	If ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfMonth(PeriodFrom);
	Else
		PeriodFrom = BegOfMonth(CurrentSessionDate());
	EndIf;
	// Set form caption
	vMonthName = PeriodPresentation(BegOfMonth(PeriodFrom), EndOfMonth(PeriodFrom), cmLocalizationCode());
	vFrmCaption = TrimAll(ThisForm.Title);
	vPos = Find(vFrmCaption, " - ");
	If vPos = 0 Then
		vFrmCaption = vFrmCaption + " - " + vMonthName;
	Else
		vFrmCaption = Left(vFrmCaption, vPos-1) + " - " + vMonthName;
	EndIf;
	ThisForm.Title = vFrmCaption;
	// Set totals column caption
	Items.TableBoxOperations.ChildItems.TableBoxOperationsQuantityPerMonth.Title = NStr("en='Totals per ';ru='Всего за ';de='Gesamt für '") + vMonthName;
	// Calculate number of days per month
	NumberOfDaysPerMonth = Round((EndOfMonth(PeriodFrom) - BegOfMonth(PeriodFrom))/(24*3600), 0);
	// Fill day of week captions and set columns appearance
	For i = 0 To 30 Do
		If i >= NumberOfDaysPerMonth Then
			// Hide columns
			Items.TableBoxOperations.ChildItems[2+i].Visible = False;
		Else
			// Show columns
			Items.TableBoxOperations.ChildItems[2+i].Visible = True;
			// Add day of week captions
			vWeekDay = WeekDay(PeriodFrom+i*24*3600);
			vWeekDayCaption = cmGetDayOfWeekName(vWeekDay, True);
			Items.TableBoxOperations.ChildItems[2+i].Title = String(i+1) + Chars.LF + vWeekDayCaption;
		EndIf;
	EndDo;
	// Load employee operations
	If pLoadOperations Then
		LoadEmployeeOperations();
	EndIf;                                                                                                                  
EndProcedure //  PeriodFromOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionFillFromPreviousMonthAtServer()
	// Check that employee is choosen
	If Not ValueIsFilled(Employee) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Employee should be choosen!';ru='Не выбран сотрудник!';de='Kein Mitarbeiter ist gewählt!'"));
		Return;
	EndIf;
	// Run query to get employee previous month operations
	vPrevMonthDay = BegOfMonth(PeriodFrom) - 24*3600;
	vOperations = GetEmployeeOperations(Employee, Hotel, BegOfMonth(vPrevMonthDay), EndOfMonth(vPrevMonthDay));
	// Add empty rows from previous month
	For Each vOprRow In vOperations Do
		vRows = TableBoxOperations.FindRows(New Structure("RoomType, Operation", vOprRow.RoomType, vOprRow.Operation));
		If vRows.Count() > 1 Then // Remove doubled rows
			While 1 < vRows.Count() Do
				vRow = vRows.Get(1);
				TableBoxOperations.Delete(vRow);
			EndDo;
		EndIf;
		// Add row if nothing found
		If vRows.Count() = 0 Then
			vRow = TableBoxOperations.Add();
			vRow.RoomType = vOprRow.RoomType;
			vRow.Operation = vOprRow.Operation;
		EndIf;
	EndDo; 
EndProcedure //  ActionFillFromPreviousMonthAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionFillFromOtherEmployeeAtServer(pEmployee, pPeriodFrom)   	
	// Run query to get employee previous month operations
	vOperations = GetEmployeeOperations(pEmployee, Hotel, BegOfMonth(pPeriodFrom), EndOfMonth(pPeriodFrom));
	// Add empty rows from previous month
	For Each vOprRow In vOperations Do
		vRows = TableBoxOperations.FindRows(New Structure("RoomType, Operation", vOprRow.RoomType, vOprRow.Operation));
		If vRows.Count() > 1 Then // Remove doubled rows
			While 1 < vRows.Count() Do
				vRow = vRows.Get(1);
				TableBoxOperations.Delete(vRow);
			EndDo;
		EndIf;
		// Add row if nothing found
		If vRows.Count() = 0 Then
			vRow = TableBoxOperations.Add();
			vRow.RoomType = vOprRow.RoomType;
			vRow.Operation = vOprRow.Operation;
		EndIf;
	EndDo;    
EndProcedure //  ActionFillFromOtherEmployeeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateTotalsPerOperation(pRow)
	// Calculate totals per operation for the given row
	vQty = 0;
	For i = 0 To 30 Do
		If Items.TableBoxOperations.ChildItems[2+i].Visible Then      
			vQty = vQty + pRow["Quantity"+String(i+1)];
		EndIf;
	EndDo;
	pRow.QuantityPerMonth = vQty;
	
	vMonthQty = TableBoxOperations.Total("QuantityPerMonth");
	TableBoxOperations[0]["QuantityPerMonthFooter"] =  Format(vMonthQty, "ND=6; NFD=0; NG=");  
EndProcedure //  CalculateTotalsPerOperation

// ----------------------------------------------------------------------------- 
&AtServer
Function GetDayDocuments(pRow, pDay)
	// Get all documents for the given day
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	EmployeeOperation.Ref
	|FROM
	|	Document.EmployeeOperation AS EmployeeOperation
	|WHERE
	|	EmployeeOperation.OperationStartTime >= &qPeriodFrom
	|			AND EmployeeOperation.OperationStartTime <= &qPeriodTo
	|	AND EmployeeOperation.Posted
	|	AND EmployeeOperation.Employee = &qEmployee
	|	AND EmployeeOperation.RoomType = &qRoomType
	|	AND EmployeeOperation.Operation = &qOperation";
	vQry.SetParameter("qEmployee", Employee);
	vQry.SetParameter("qRoomType", pRow.RoomType);
	vQry.SetParameter("qOperation", pRow.Operation);
	vQry.SetParameter("qPeriodFrom", BegOfMonth(PeriodFrom) + pDay*24*3600);
	vQry.SetParameter("qPeriodTo", EndOfDay(BegOfMonth(PeriodFrom) + pDay*24*3600));
	Return vQry.Execute().Unload();
EndFunction //  GetDayDocuments

// -----------------------------------------------------------------------------
&AtServer
Procedure TableBoxOperationsOnEditEndAtServer(pCurRowID)
	vCurRow = TableBoxOperations.FindByID(pCurRowID);
	If vCurRow <> Undefined Then
		// Check if there is row with same combination of room type and operation
		vRows = TableBoxOperations.FindRows(New Structure("RoomType, Operation", vCurRow.RoomType, vCurRow.Operation));
		For Each vRow In vRows Do
			If vRow <> vCurRow Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='For the combination of room type and operation there could be only one row in the table. Such row already exists! Please edit existing row rather then create new one. Current row will be deleted!';ru='В таблице может быть только одна строка с уникальной комбинацией типа номера и работы. В таблице такая строка уже существует! Пожалуйста редактируйте существующую строку, а не создавайте новую. Текущая строка будет удалена!';de='Die Tabelle kann nur eine Zeile mit einmaliger Kombination aus Zimmertyp und Arbeitstyp enthalten. In der Tabelle ist eine solche Zeile bereits vorhanden! Bitte bearbeiten Sie die bereits vorhandene Zeile und erstellen Sie keine neue. Die aktuelle Zeile wird gelöscht!'"));
				TableBoxOperations.Delete(vCurRow);
				Return;
			EndIf;
		EndDo;
		// Process operation quantities
		For i = 0 To 30 Do
			If Items.TableBoxOperations.ChildItems[2+i].Visible Then
				// Get all documents for the given day
				vDocs = GetDayDocuments(vCurRow, i);
				// If current day quantity is zero then get all documents for the given day and delete them
				If vCurRow["Quantity"+String(i+1)] = 0 Then
					Try
						For Each vDocsRow In vDocs Do
							vDocObj = vDocsRow.Ref.GetObject();
							vDocObj.SetDeletionMark(True);
						EndDo;
					Except
						tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());
						Return;
					EndTry;
					// Go to the next day
					Continue;
				EndIf;
				// Update first one and delete all other
				vDocObj = Undefined;
				If vDocs.Count() > 0 Then
					If vDocs.Count() > 1 Then
						Try
							j = 1;
							While j < vDocs.Count() Do
								vDocObj = vDocs.Get(j).Ref.GetObject();
								vDocObj.SetDeletionMark(True);
								j = j + 1;
							EndDo;
						Except
						EndTry;
					EndIf;
					vDocObj = vDocs.Get(0).Ref.GetObject();
				Else
					vDocObj = Documents.EmployeeOperation.CreateDocument();
					If ValueIsFilled(Hotel) And Not Hotel.IsFolder Then
						vDocObj.Hotel = Hotel;
					EndIf;
					vDocObj.pmFillAttributesWithDefaultValues();
					vDocObj.Quantity = 0; // Reset quantity
					vDocObj.Employee = Employee;
					vDocObj.RoomType = vCurRow.RoomType;
					vDocObj.Operation = vCurRow.Operation;
				EndIf;
				// Write document only if it's quantity has changed
				If vDocObj.Quantity <> vCurRow["Quantity"+String(i+1)] Then
					// Clear room
					vDocObj.Room = Catalogs.Rooms.EmptyRef();
					// Fill quantity
					vDocObj.Quantity = vCurRow["Quantity"+String(i+1)];
					// Get operation room space
					vStds = Catalogs.Operations.GetOperationStandards(vDocObj.Operation, vDocObj.Hotel, vDocObj.RoomType, vDocObj.Room, vDocObj.Employee);
					If vStds.Count() > 0 Then
						vStdsRow = vStds.Get(0);
						vDocObj.Duration = vStdsRow.Duration;
						vDocObj.RoomSpace = vStdsRow.RoomSpace;
						vDocObj.Price = vStdsRow.Price;
					EndIf;
					// Fill number of persons as number of beds in the room
					vDocObj.NumberOfPersons = 1;
					If ValueIsFilled(vDocObj.RoomType) Then
						If Not vDocObj.RoomType.IsFolder Then
							If vDocObj.RoomType.NumberOfBedsPerRoom > 0 Then
								vDocObj.NumberOfPersons = vDocObj.RoomType.NumberOfBedsPerRoom;
							EndIf;
						EndIf;
					EndIf;
					// Fill operation articles consumption standards table
					vDocObj.Articles.Clear();
					vDocObj.pmFillArticles();
					// Post document
					Try
						vDocObj.Write(DocumentWriteMode.Posting);
					Except
						tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());
						Return;
					EndTry;
				EndIf;
			EndIf;
		EndDo; 
		// Recalculate totals
		CalculateTotalsPerDays();
	EndIf;                           	  
EndProcedure //  TableBoxEmployeesOnEditEndAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure TableBoxOperationsQuantityOnChangeAtServer(pCurRowID, pCurItemName)
	vCurRow = TableBoxOperations.FindByID(pCurRowID);
	If vCurRow <> Undefined Then     		
		// Check if there is row with same combination of room type and operation
		vRows = TableBoxOperations.FindRows(New Structure("RoomType, Operation", vCurRow.RoomType, vCurRow.Operation));
		For Each vRow In vRows Do
			If vRow <> vCurRow Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='For the combination of room type and operation there could be only one row in the table. Such row already exists! Please edit existing row rather then create new one. Current row will be deleted!';ru='В таблице может быть только одна строка с уникальной комбинацией типа номера и работы. В таблице такая строка уже существует! Пожалуйста редактируйте существующую строку, а не создавайте новую. Текущая строка будет удалена!';de='Die Tabelle kann nur eine Zeile mit einmaliger Kombination aus Zimmertyp und Arbeitstyp enthalten. In der Tabelle ist eine solche Zeile bereits vorhanden! Bitte bearbeiten Sie die bereits vorhandene Zeile und erstellen Sie keine neue. Die aktuelle Zeile wird gelöscht!'"));
				TableBoxOperations.Delete(vCurRow);
				Return;
			EndIf;
		EndDo;
		// Recalculate totals
		CalculateTotalsPerOperation(vCurRow);
		vName = Right(pCurItemName, StrLen(pCurItemName) - StrLen("TableBoxOperations"));
		vIndex =  Right(pCurItemName, StrLen(pCurItemName) - StrLen("TableBoxOperationsQuantity"));
		
		// Calculate totals per one day
		If cmIsNumber(vIndex) Then 
			vDayQty = TableBoxOperations.Total(vName);
			TableBoxOperations[0]["QuantityFooter"+vIndex] = Format(vDayQty, "ND=6; NFD=0; NG="); 
		EndIf;     
	EndIf;
EndProcedure //  TableBoxOperationsQuantityOnChangeAtServer

#EndRegion


