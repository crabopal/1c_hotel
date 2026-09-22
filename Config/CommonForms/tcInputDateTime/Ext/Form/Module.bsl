
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("FillingValues") Then
		FillPropertyValues(ThisForm,Parameters.FillingValues);
		Title = Description;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Check if is in protected mode
	If IsProtected Then
		Items.Date.ReadOnly = True;
		Items.Time.ReadOnly = True;
	EndIf;
	If DateIsProtected Then
		Items.Date.ReadOnly = True;
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure TimeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = TimeStartChoiceAtServer();
	vDayTime = Undefined;

	ShowChooseFromList(New NotifyDescription("TimeStartChoiceEnd", ThisForm), vList, pitem);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// ----------------------------------------------
&AtClient
Procedure Cancel(pCommand)
	ThisForm.Close()
EndProcedure // Cancel

// -----------------------------------------------------------------------------
&AtClient
Procedure OK(pCommand)
	// Check user input
	If Not ValueIsFilled(Date) Then
		ShowMessageBox(New NotifyDescription("OKEnd", ThisForm), NStr("en='Date should be entered!';ru='Дата должна быть указана!';de='Das Datum muss angegeben sein!'"));
		Return;
	Else
		// Build return parameter
		vDateTime = AddTimeAtServer();
		ThisForm.Close(vDateTime);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure TimeStartChoiceEnd(SelectedItem, AdditionalParameters) Export
	
	vDayTime = SelectedItem;
	If vDayTime <> Undefined Then
		Time = vDayTime.Value;
	EndIf;

EndProcedure // TimeStartChoice

// -----------------------------------------------------------------------------
&AtServer
Function TimeStartChoiceAtServer()
	vDayTimes = cmGetDayTimes();
	vList = New ValueList();
	For Each vDayTimesRow In vDayTimes Do
		vList.Add(vDayTimesRow.Time, vDayTimesRow.Presentation);
	EndDo;
	Return vList;
EndFunction // TimeStartChoiceAtServer

&AtClient
Procedure OKEnd(AdditionalParameters) Export
	CurrentItem = Items.Date;
	// Build return parameter
	vDateTime = AddTimeAtServer();
	ThisForm.Close(vDateTime);
EndProcedure // OK

// -----------------------------------------------------------------------------
&AtServer
Function AddTimeAtServer()
	vDateTime = cmAddTime(Date, Time, False);
	Return vDateTime;
EndFunction // AddTimeAtServer

#EndRegion
