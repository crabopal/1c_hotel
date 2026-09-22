#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	// Departments
	FillDepartmentsPresentation();
	// Actions after tsk finish
	If Object.Type = Enums.MessageTypes.Task Then
		Items.SetRoomStatusAtTaskEnd.Visible = True;
		Items.SetBedsSetupAtTaskEnd.Visible = True;
	Else
		Items.SetRoomStatusAtTaskEnd.Visible = False;
		Items.SetBedsSetupAtTaskEnd.Visible = False;
	EndIf;
EndProcedure

#EndRegion

// -----------------------------------------------------------------------------
&AtClient
Procedure TDepartmentsPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vDepartmentsList = GetDepartmentsListAtServer();
	vParams = New Structure("MultipleChoice, Title, ValueList", True, NStr("en='Check departments...'; ru='Отметьте отделы...'; de='Markieren Abteilungen...'"), vDepartmentsList);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , New NotifyDescription("DepartmentsStartChoice_AfterInput", ThisObject));
EndProcedure // TDepartmentsPresentationStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure TDepartmentsPresentationClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	DepartmentClearingAtServer();
	RefreshDataRepresentation();
	Modified = True;
EndProcedure // TDepartmentsPresentationClearing

// -----------------------------------------------------------------------------
&AtServer
Function GetDepartmentsListAtServer()
	vDepartmentsList = New ValueList();
	vDepartments = GetAllDepartments(?(ValueIsFilled(Object.Hotel), Object.Hotel, SessionParameters.CurrentHotel));	
	vDepartmentsList.LoadValues(vDepartments.UnloadColumn("Department"));
	If ValueIsFilled(Object.Department) Then
		vItem = vDepartmentsList.FindByValue(Object.Department);
		If vItem <> Undefined Then
			vItem.Check = True;
		EndIf;
	EndIf;
	For Each vRow In Object.ForDepartments Do
		If ValueIsFilled(vRow.Department) Then
			vItem = vDepartmentsList.FindByValue(vRow.Department);
			If vItem <> Undefined Then
				vItem.Check = True;
			EndIf;
		EndIf;
	EndDo;
	Return vDepartmentsList;
EndFunction // GetDepartmentsListAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetAllDepartments(pHotel)
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	Departments.Ref AS Department
	|FROM
	|	Catalog.Departments AS Departments
	|WHERE
	|	NOT Departments.DeletionMark
	|	AND NOT Departments.IsFolder
	|	AND (Departments.Hotel = &qHotel
	|			OR Departments.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|
	|ORDER BY
	|	Departments.SortCode,
	|	Departments.Code";
	vQ.SetParameter("qHotel", pHotel);
	Return vQ.Execute().Unload();
EndFunction // GetAllDepartments

// -----------------------------------------------------------------------------
&AtClient
Procedure DepartmentsStartChoice_AfterInput(pValue, pParametrs) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	SaveDepartmentsAtServer(pValue);
	RefreshDataRepresentation();
	Modified = True;
EndProcedure // DepartmentsStartChoice_AfterInput

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveDepartmentsAtServer(pDepartmentsList)
	If ValueIsFilled(Object.Department) Then
		Object.Department = Catalogs.Departments.EmptyRef();
	EndIf;
	If Object.ForDepartments.Count() > 0 Then
		Object.ForDepartments.Clear();
	EndIf;
	If pDepartmentsList.Count() > 0 Then
		vIsFirstItem = True;
		For Each vItem In pDepartmentsList Do
			If vItem.Check Then
				If vIsFirstItem Then
					vIsFirstItem = False;
					Object.Department = vItem.Value;
				Else
					vSPRow = Object.ForDepartments.Add();
					vSPRow.Department = vItem.Value;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Fill service packages presentation
	FillDepartmentsPresentation();
EndProcedure // SaveDepartmentsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDepartmentsPresentation()
	// Service packages
	TDepartmentsPresentation = "";
	If ValueIsFilled(Object.Department) Then
		TDepartmentsPresentation = TrimAll(Object.Department);
	EndIf;
	For Each vDepartmentRow In Object.ForDepartments Do
		If ValueIsFilled(vDepartmentRow.Department) Then
			If IsBlankString(TDepartmentsPresentation) Then
				TDepartmentsPresentation = TrimAll(vDepartmentRow.Department);
			Else
				TDepartmentsPresentation = TDepartmentsPresentation + ", " + TrimAll(vDepartmentRow.Department);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillDepartmentsPresentation

// -----------------------------------------------------------------------------
&AtServer
Procedure DepartmentClearingAtServer()
	Object.Department = Catalogs.Departments.EmptyRef();
	Object.ForDepartments.Clear();
	FillDepartmentsPresentation();
EndProcedure // DepartmentClearingAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure TypeOnChange(pItem)
	If Object.Type = PredefinedValue("Enum.MessageTypes.Task") Then
		Items.SetRoomStatusAtTaskEnd.Visible = True;
		Items.SetBedsSetupAtTaskEnd.Visible = True;
	Else
		Items.SetRoomStatusAtTaskEnd.Visible = False;
		If Object.SetRoomStatusAtTaskEnd Then
			Object.SetRoomStatusAtTaskEnd = False;
		EndIf;
		Items.SetBedsSetupAtTaskEnd.Visible = False;
		If Object.SetBedsSetupAtTaskEnd Then
			Object.SetBedsSetupAtTaskEnd = False;
		EndIf;
	EndIf;
EndProcedure // TypeOnChange
