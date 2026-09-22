
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
	// Load employees list from the information register
	LoadEmployeesWorkingTimeSchedule();  
EndProcedure // OnCreateAtServer
   
#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodFromOnChange(Item)
	PeriodFromOnChangeAtServer();
EndProcedure // PeriodFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxEmployeesResourceOnChange(pItem) 	
	vCurRow = Items.TableBoxEmployees.CurrentData;
	If vCurRow <> Undefined Then   
		vCurRowID = vCurRow.GetID();  
		vCurItemName = pItem.Name;
		TableBoxEmployeesResourceOnChangeAtServer(vCurRowID, vCurItemName);
	EndIf;
EndProcedure // TableBoxEmployeesResourceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxEmployeesEmployeeOnChange(Item)
	vCurRow = Items.TableBoxEmployees.CurrentData;
	If vCurRow <> Undefined Then
		vCurRowID = vCurRow.GetID();
		TableBoxEmployeesEmployeeOnChangeAtServer(vCurRowID);
	EndIf;
EndProcedure // TableBoxEmployeesEmployeeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DepartmentOnChange(Item)
	DepartmentOnChangeAtServer();
EndProcedure // DepartmentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EmployeeOnChange(Item)
	EmployeeOnChangeAtServer();
EndProcedure // EmployeeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomSectionOnChange(Item)
	RoomSectionOnChangeAtServer();
EndProcedure // RoomSectionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(Item)
	RoomOnChangeAtServer();
EndProcedure // RoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(Item)
	HotelOnChangeAtServer();
EndProcedure // HotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxEmployeesBeforeDeleteRow(pItem, pCancel)
	// Ask for confirmation
	vCurRow = Items.TableBoxEmployees.CurrentRow;
	If vCurRow <> Undefined Then
		pCancel = True;
		ShowQueryBox(New NotifyDescription("TableBoxEmployeesBeforeDeleteAfterUserConfirmation", ThisForm, vCurRow), NStr("en='Delete all employee days for the current month?'; ru='Удалить все дни по сотруднику за текущий месяц?'; de='Alle Tage nach Mitarbeiter für den aktuellen Monat löschen?'"), QuestionDialogMode.YesNo);
	EndIf;
EndProcedure // TableBoxEmployeesBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxEmployeesOnEditEnd(Item, NewRow, CancelEdit)
	vCurRow = Items.TableBoxEmployees.CurrentData;
	If vCurRow <> Undefined Then
		vCurRowID = vCurRow.GetID();
		TableBoxEmployeesOnEditEndOnServer(vCurRowID);
	EndIf;
EndProcedure // TableBoxEmployeesOnEditEnd

// -----------------------------------------------------------------------------
&AtServer
Procedure TableBoxEmployeesOnEditEndOnServer(pCurRowID)
	vCurRow = TableBoxEmployees.FindByID(pCurRowID);
	If vCurRow <> Undefined Then  	
		vManager = InformationRegisters.EmployeeWorkingTimeSchedule.CreateRecordManager();
		If ValueIsFilled(vCurRow.Employee) Then
			For i = 0 To 30 Do
				If Items.TableBoxEmployees.ChildItems[3+i].Visible Then
					Try
						vManager.Employee = vCurRow.Employee;
						vManager.Period = BegOfMonth(PeriodFrom) + i*24*3600;
						vManager.Read();
						If Not vManager.Selected() Then
							vManager.Employee = vCurRow.Employee;
							vManager.Period = BegOfMonth(PeriodFrom) + i*24*3600;
						EndIf;
						vManager.Hotel = Hotel;
						vManager.Department = vCurRow.Department;
						vManager.RoomSection = vCurRow.RoomSection;
						vManager.Room = vCurRow.Room;
						vManager.Hours = vCurRow["Hours"+String(i+1)];
						vManager.ScheduleDayType = vCurRow["ScheduleDayType"+String(i+1)];
						vManager.Write(True);
					Except
						tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());
						Return;
					EndTry;
				EndIf;
			EndDo;
		EndIf;
		// Recalculate totals
		CalculateTotalsPerDays(); 
	EndIf;  	 	
EndProcedure // TableBoxEmployeesOnEditEndOnServer

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxEmployeesAfterDeleteRow(pItem)
	TableBoxEmployeesAfterDeleteRowAtServer();
EndProcedure // TableBoxEmployeesAfterDeleteRow

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
	If ValueIsFilled(RoomSection) Then
		vFilter.Insert("Section", RoomSection);
	EndIf;
	If ValueIsFilled(Room) Then
		vFilter.Insert("Room", Room);
	EndIf;
	vParams.Insert("Filter", vFilter);
	OpenForm("Catalog.Employees.Form.tcChoiceForm", vParams, pItem);  
EndProcedure // EmployeeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomSectionStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure();
	vFilter	= New Structure();	
	vParams.Insert("ChoiseMode", True);
	If ValueIsFilled(Hotel) Then
		vFilter.Insert("Hotel", Hotel);
	EndIf;
	vParams.Insert("Filter", vFilter);
	OpenForm("Catalog.RoomSections.Form.tcChoiceForm", vParams, pItem);  
EndProcedure // RoomSectionStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure DepartmentStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure();
	vFilter	= New Structure();
	vParams.Insert("ChoiseMode", True);
	If ValueIsFilled(Hotel) Then
		vArray = New Array;
		vArray.Add(Hotel);		
		vArray.Add(PredefinedValue("Catalog.Hotels.EmptyRef"));
		vFilter.Insert("Hotel", vArray);
	EndIf;
	vParams.Insert("Filter", vFilter);
	OpenForm("Catalog.Departments.Form.tcChoiceForm", vParams, pItem);  
EndProcedure // DepartmentStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure();
	vFilter	= New Structure();	
	vParams.Insert("ChoiseMode", True);
	If ValueIsFilled(Hotel) Then
		vFilter.Insert("Owner", Hotel);
	EndIf;
	vParams.Insert("Filter", vFilter);
	OpenForm("Catalog.Rooms.Form.tcGroupChoiceForm", vParams, pItem);
EndProcedure // RoomStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintSchedule(pCommand)
	vReportRef = PredefinedValue("Catalog.Reports.EmployeeWorkingTimeSchedule");
	vParam = New Structure();
	vParam.Insert("ReportRef",vReportRef);
	If ValueIsFilled(Employee) Then
		vParam.Insert("Employee",Employee);
	EndIf;
	If ValueIsFilled(Department) Then
		vParam.Insert("Department",Department);
	EndIf;	
	If ValueIsFilled(RoomSection) Then  
	vParam.Insert("RoomSection",RoomSection);
	EndIf;
	If ValueIsFilled(Room) Then
		vParam.Insert("Room",Room);
	EndIf;	
	If ValueIsFilled(Hotel) Then
		vParam.Insert("Hotel",Hotel);
	EndIf;
	If ValueIsFilled(PeriodFrom) Then
		vParam.Insert("PeriodFrom",BegOfMonth(PeriodFrom));
		vParam.Insert("PeriodTo",EndOfMonth(PeriodFrom));
	EndIf;
	OpenForm("Report.EmployeeWorkingTimeSchedule.Form.tcReportForm", New Structure("FillingValues, GenerateOnOpen", vParam, True));  
EndProcedure // PrintSchedule

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// Load employees list from the information register
// -----------------------------------------------------------------------------
&AtServer
Procedure LoadEmployeesWorkingTimeSchedule()
	vTableBoxEmployees = FormAttributeToValue("TableBoxEmployees");	
	// Clear list first
	vTableBoxEmployees.Clear();
	// Run query to get employees
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EmployeeWorkingTimeSchedule.Period,
	|	EmployeeWorkingTimeSchedule.Employee,
	|	EmployeeWorkingTimeSchedule.Department,
	|	EmployeeWorkingTimeSchedule.Room,
	|	EmployeeWorkingTimeSchedule.RoomSection,
	|	EmployeeWorkingTimeSchedule.ScheduleDayType,
	|	EmployeeWorkingTimeSchedule.Timetable,
	|	EmployeeWorkingTimeSchedule.Hours
	|FROM
	|	InformationRegister.EmployeeWorkingTimeSchedule AS EmployeeWorkingTimeSchedule
	|WHERE
	|	EmployeeWorkingTimeSchedule.Period >= &qPeriodFrom
	|	AND EmployeeWorkingTimeSchedule.Period <= &qPeriodTo
	|	AND (EmployeeWorkingTimeSchedule.Hotel IN HIERARCHY (&qHotel)
	|			OR &qIsEmptyHotel)
	|	AND (EmployeeWorkingTimeSchedule.Department IN HIERARCHY (&qDepartment)
	|			OR &qIsEmptyDepartment)
	|	AND (EmployeeWorkingTimeSchedule.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (EmployeeWorkingTimeSchedule.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
	|	AND (EmployeeWorkingTimeSchedule.Employee IN HIERARCHY (&qEmployee)
	|			OR &qIsEmptyEmployee)
	|ORDER BY
	|	EmployeeWorkingTimeSchedule.Employee.SortCode,
	|	EmployeeWorkingTimeSchedule.Employee.Description,
	|	EmployeeWorkingTimeSchedule.Period";
	vQry.SetParameter("qPeriodFrom", BegOfMonth(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfMonth(PeriodFrom));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qDepartment", Department);
	vQry.SetParameter("qIsEmptyDepartment", Not ValueIsFilled(Department));
	vQry.SetParameter("qRoomSection", RoomSection);
	vQry.SetParameter("qIsEmptyRoomSection", Not ValueIsFilled(RoomSection));
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qIsEmptyRoom", Not ValueIsFilled(Room));
	vQry.SetParameter("qEmployee", Employee);
	vQry.SetParameter("qIsEmptyEmployee", Not ValueIsFilled(Employee));
	vEmployees = vQry.Execute().Unload();
	
	For Each vEmpRow In vEmployees Do
		vRow = vTableBoxEmployees.Find(vEmpRow.Employee, "Employee");
		If vRow = Undefined Then
			vRow = vTableBoxEmployees.Add();
			vRow.Employee = vEmpRow.Employee;
			vRow.Department = vEmpRow.Department;
			vRow.RoomSection = vEmpRow.RoomSection;
			vRow.Room = vEmpRow.Room;
		EndIf;
		i = Round((BegOfDay(vEmpRow.Period) - BegOfMonth(PeriodFrom))/(24*3600), 0);
		vRow[4+i] = vEmpRow.Hours;
		vRow[35+i] = vEmpRow.ScheduleDayType;
	EndDo;
	ValueToFormAttribute(vTableBoxEmployees, "TableBoxEmployees");   
	
	// Recalculate totals
	For Each pRow In TableBoxEmployees Do
		CalculateTotalsPerEmployee(pRow);
	EndDo;  
	CalculateTotalsPerDays();
EndProcedure // LoadEmployeesWorkingTimeSchedule

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateTotalsPerDays()
	// Calculate totals per days
	If TableBoxEmployees.Count() > 0 Then
		For i = 0 To 30 Do
			vDayHours =TableBoxEmployees.Total("Hours"+String(i+1));
			TableBoxEmployees[0]["HoursFooter"+String(i+1)] =  cmFormatDurationInHours(vDayHours);
		EndDo; 	
	EndIf;
EndProcedure // CalculateTotalsPerDays

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateTotalsPerEmployee(pRow)
	// Calculate totals per employee for the given row
	vEmpHours = 0;
	For i = 0 To 30 Do 
		If Items.TableBoxEmployees.ChildItems[3+i].Visible Then      
			vEmpHours = vEmpHours + pRow["Hours"+String(i+1)];
		EndIf;
	EndDo;
	pRow.HoursPerMonth = vEmpHours;
	
	vMonthHours = TableBoxEmployees.Total("HoursPerMonth");
	TableBoxEmployees[0]["HoursPerMonthFooter"] =  cmFormatDurationInHours(vMonthHours);    
EndProcedure // CalculateTotalsPerEmployee

// -----------------------------------------------------------------------------
&AtServer
Procedure PeriodFromOnChangeAtServer()
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
	Items.TableBoxEmployees.ChildItems.TableBoxEmployeesHoursPerMonth.Title = NStr("en='Totals per ';ru='Всего за ';de='Gesamt für'") + vMonthName;
	// Calculate number of days per month
	NumberOfDaysPerMonth = Round((EndOfMonth(PeriodFrom) - BegOfMonth(PeriodFrom))/(24*3600), 0);
	// Fill day of week captions and set columns appearance
	For i = 0 To 30 Do 
		If i >= NumberOfDaysPerMonth Then
			// Hide columns
			Items.TableBoxEmployees.ChildItems[3+i].Visible = False;
		Else
			// Show columns
			Items.TableBoxEmployees.ChildItems[3+i].Visible = True;
			// Add day of week captions
			vWeekDay = WeekDay(PeriodFrom+i*24*3600);
			vWeekDayCaption = cmGetDayOfWeekName(vWeekDay, True);
			Items.TableBoxEmployees.ChildItems[3+i].ChildItems[1].Title = vWeekDayCaption;
		EndIf;
	EndDo;
	// Load employees list from the information register
	LoadEmployeesWorkingTimeSchedule(); 
EndProcedure // PeriodFromOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure TableBoxEmployeesResourceOnChangeAtServer(pCurRowID, pCurItemName)
	vCurRow = TableBoxEmployees.FindByID(pCurRowID);
	If vCurRow <> Undefined Then 
		CalculateTotalsPerEmployee(vCurRow); 
			
		vName = Right(pCurItemName, StrLen(pCurItemName) - StrLen("TableBoxEmployees"));
		vIndex =  Right(pCurItemName, StrLen(pCurItemName) - StrLen("TableBoxEmployeesHours"));
		// Calculate totals per one day
		If cmIsNumber(vIndex) Then 
			vDayHours = TableBoxEmployees.Total(vName);
			TableBoxEmployees[0]["HoursFooter"+vIndex] = cmFormatDurationInHours(vDayHours); 
		EndIf;
	EndIf;	
EndProcedure // TableBoxEmployeesResourceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure TableBoxEmployeesEmployeeOnChangeAtServer(pCurRowID)
	vCurRow = TableBoxEmployees.FindByID(pCurRowID);
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.Employee) Then
			vCurRow.Department = vCurRow.Employee.Department;
			vCurRow.RoomSection = vCurRow.Employee.RoomSection;
		Else
			vCurRow.Department = Catalogs.Departments.EmptyRef();
			vCurRow.RoomSection = Catalogs.RoomSections.EmptyRef();
		EndIf;
	EndIf;   
EndProcedure // TableBoxEmployeesEmployeeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DepartmentOnChangeAtServer()
	LoadEmployeesWorkingTimeSchedule();
EndProcedure // DepartmentOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure EmployeeOnChangeAtServer()
	LoadEmployeesWorkingTimeSchedule();
EndProcedure // EmployeeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomSectionOnChangeAtServer()
	LoadEmployeesWorkingTimeSchedule();
EndProcedure // RoomSectionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomOnChangeAtServer()
	LoadEmployeesWorkingTimeSchedule();
EndProcedure // RoomOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	LoadEmployeesWorkingTimeSchedule();
EndProcedure // HotelOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure TableBoxEmployeesBeforeDeleteAfterUserConfirmation(pUserAnswer, pRowID) Export
	If pUserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	If pRowID <> Undefined Then
		TableBoxEmployeesDeleteRowAtServer(pRowID);
	EndIf;
EndProcedure // TableBoxEmployeesBeforeDeleteAfterUserConfirmation

// -----------------------------------------------------------------------------
&AtServer
Procedure TableBoxEmployeesDeleteRowAtServer(pCurRowID)
	vCurRow = TableBoxEmployees.FindByID(pCurRowID);
	If vCurRow <> Undefined Then 
		// Delete all records for the current month
		vManager = InformationRegisters.EmployeeWorkingTimeSchedule.CreateRecordManager();
		If ValueIsFilled(vCurRow.Employee) Then
			For i = 0 To 30 Do
				If Items.TableBoxEmployees.ChildItems[3+i].Visible Then
					vManager.Employee = vCurRow.Employee;
					vManager.Period = BegOfMonth(PeriodFrom) + i*24*3600;
					vManager.Read();
					Try
						If vManager.Selected() Then
							vManager.Delete();
						EndIf;
					Except
						tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());
						pCancel = True;
						Return;
					EndTry;
				EndIf;
			EndDo;
		EndIf; 
		// Delete row from list
		TableBoxEmployees.Delete(TableBoxEmployees.IndexOf(vCurRow));
	EndIf;   	
EndProcedure // TableBoxEmployeesDeleteRowAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure TableBoxEmployeesAfterDeleteRowAtServer()
	// Recalculate totals
	CalculateTotalsPerDays();
EndProcedure // TableBoxEmployeesAfterDeleteRowAtServer

#EndRegion
