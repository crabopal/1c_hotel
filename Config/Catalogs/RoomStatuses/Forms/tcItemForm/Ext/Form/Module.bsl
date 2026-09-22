
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
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Check user rights to use item
	If Not cmCheckUserPermissions("HavePermissionToManageHousekeeping") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit housekeeping settings!';ru='Нет прав на управление службой горничных!';de='Sie haben keine Rechte, die Einstellungen des Reinigungsdienstes zu verwalten!'"));
			Return;
		Else
			ReadOnly = True;
		EndIf;
	EndIf;
	
	ClearColor = False;
	ColorIsEmpty = True;
	vColor = Undefined;
	If Not IsBlankString(Object.ColorHexString) Then
		vColor = tcOnServer.HexToColor(Object.ColorHexString);
	EndIf;
	If vColor <> Undefined And TypeOf(vColor) = Type("Color") Then
		ColorIsEmpty = False;
		SetColor(vColor);
	EndIf;
	RefreshDisplay();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If ClearColor Then
		pCurrentObject.ColorHexString = "";
		pCurrentObject.Color = New ValueStorage(Undefined);
		ClearColor = False;
	Else
		If ColorIsEmpty Then
			pCurrentObject.ColorHexString = "";
			pCurrentObject.Color = Undefined;
		Else
			pCurrentObject.ColorHexString = tcOnServer.ColorToHex(Color);
			pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(pCurrentObject.ColorHexString));
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStatusIconOnChange(pItem)
	RefreshDisplay();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OperationsScheduleWeekDaysStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurRow = Items.OperationsSchedule.CurrentData;
	If vCurRow <> Undefined Then
		vWeekDaysList = New ValueList();
		For i = 1 To 7 Do
			vCheck = False;
			If Find(vCurRow.WeekDays, String(i)) > 0 Then
				vCheck = True;
			EndIf;
			vWeekDaysList.Add(i,tcOnClient.cmGetDayOfWeekNameOnClient(i, False), vCheck);
		EndDo;
		vWeekDaysList.ShowCheckItems(New NotifyDescription("CheckWeekDays", ThisObject, vCurRow), NStr("en='Check week days'; ru='Отметьте дни недели'; de='Wählen Sie Tage der Woche'"));
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChooseColor(pCommand)
	vDialog = New ColorChooseDialog();
	vDialog.Color = Color;
	vDialog.Show(New NotifyDescription("ColorPick", ThisObject));	
EndProcedure // ChooseColor

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	ClearColor = True;
	ColorIsEmpty = True;
	Items.ChoiceColor.BackColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 255);
	Items.ChoiceColor.TextColor = tcCommonFunctionOnClientServer.ColorConstructor(); 
	Modified = True;	
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	vRoomStatusIcon = Object.RoomStatusIcon;
	// Show room status icon
	If ValueIsFilled(vRoomStatusIcon) Then
		If vRoomStatusIcon = Enums.RoomStatusesIcons.None Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.Empty;
			Object.IconIndex = 5;
		ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.RoomStatusReserved;
			Object.IconIndex = 6;
		ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.Occupied;
			Object.IconIndex = 2;
		ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.OccupiedDirty;
			Object.IconIndex = 7;			
		ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.Waiting;
			Object.IconIndex = 1;
		ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.RoomStatusCleaning;
			Object.IconIndex = 0;
		ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.TidyingUp;
			Object.IconIndex = 3;
		ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.Vacant;
			Object.IconIndex = 4;
		ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.RoomStatusRepair;
			Object.IconIndex = 8;
		ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.RoomStatusLuggage;
			Object.IconIndex = 9;			
		ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.RoomStatusMalfunction;
			Object.IconIndex = 10;
		Else
			Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.Empty;
			Object.IconIndex = 5;			
		EndIf;
	Else
		Items.RoomStatusIcon.ChoiceButtonPicture = PictureLib.Empty;
		Object.IconIndex = 5;
	EndIf; 
EndProcedure // RefreshDisplay

// -----------------------------------------------------------------------------
&AtClient
Procedure ColorPick(pColor,pParametr) Export
	If pColor <> Undefined Then
		ClearColor = False;
		ColorIsEmpty = False;
		
		SetColor(pColor);
		Modified = True;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SetColor(pColor)
	Color = pColor;
	Items.ChoiceColor.BackColor = Color;
	If Color <> New Color() Then
		Items.ChoiceColor.TextColor = GetButtonTextColor(cmGetAbsoluteColor(Color));
	Else
		Items.ChoiceColor.TextColor = Color;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetButtonTextColor(pColor)	
	If (1 - (0.299 * pColor.R + 0.587 * pColor.G + 0.114 * pColor.B) / 255 < 0.5) Then
		Return tcCommonFunctionOnClientServer.ColorConstructor(0, 0, 0);
	Else
		Return tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 255);
	EndIf;	
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckWeekDays(pList,pParametr) Export
	vCurRow = pParametr;
	vCurRow.WeekDays = "";
	For Each vWeekDaysListItem In pList Do
		If vWeekDaysListItem.Check Then
			If IsBlankString(vCurRow.WeekDays) Then
				vCurRow.WeekDays = String(vWeekDaysListItem.Value);
			Else
				vCurRow.WeekDays = vCurRow.WeekDays + ", " + String(vWeekDaysListItem.Value);
			EndIf;
		EndIf;
	EndDo;
EndProcedure

#EndRegion
