#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	ClearColor = False;
	ColorIsEmpty = True;
	vColor = Undefined;
	If Not IsBlankString(Object.ColorHexString) Then
		vColor = tcOnServer.HexToColor(Object.ColorHexString);
	EndIf;
	If vColor <> Undefined And TypeOf(vColor) = Type("Color") Then
		ColorIsEmpty = False;
		Color = vColor;
		SetColor(Color);
	EndIf;
	
	// Check user rights to edit item
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
		Else
			ThisForm.ReadOnly = True;
		EndIf;
	Else
		SetFormAppearance();
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If ClearColor Then
		pCurrentObject.ColorHexString = "";
		pCurrentObject.Color = Undefined;
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
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure IsRoomRepairOnChange(pItem)
	SetFormAppearance();
EndProcedure // IsRoomRepairOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceColor(pCommand)
	vDialog = New ColorChooseDialog();
	vDialog.Color = Color;
	vDialog.Show(New NotifyDescription("ColorPick",ThisForm));	
EndProcedure // ChoiceColor

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	ClearColor = True;
	ColorIsEmpty = True;
	Items.ChoiceColor.BackColor = New Color(255,255,255);
	Items.ChoiceColor.TextColor = New Color(0,0,0); 
	ThisForm.Modified = True;	
EndProcedure // ClearColor

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure ColorPick(pColor, pParametr) Export
	If pColor <> Undefined Then
		ClearColor = False;
		ColorIsEmpty = False;
		
		SetColor(pColor);
		ThisForm.Modified = True;
	EndIf;	
EndProcedure // ColorPick

// -----------------------------------------------------------------------------
&AtServer
Procedure SetColor(pColor)	
	Color = pColor;
	Items.ChoiceColor.BackColor = Color;
	Items.ChoiceColor.TextColor = GetButtonTextColor(cmGetAbsoluteColor(Color));	
EndProcedure // SetColor

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetButtonTextColor(pColor)	
	If (1 - (0.299 * pColor.R + 0.587 * pColor.G + 0.114 * pColor.B) / 255 < 0.5) Then
		Return New Color(0,0,0);
	else
		Return New Color(255,255,255);
	EndIf;	
EndFunction // GetButtonTextColor

// -----------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearance()
	If Object.IsRoomRepair Then
		If ValueIsFilled(Object.RoomStatusAtBlockStart) Then
			Object.RoomStatusAtBlockStart = Undefined;
		EndIf;
		If ValueIsFilled(Object.RoomStatusAtBlockEnd) Then
			Object.RoomStatusAtBlockEnd = Undefined;
		EndIf;
		Items.RowRoomStatus.Enabled = False;
	Else
		Items.RowRoomStatus.Enabled = True;
	EndIf;
EndProcedure // SetFormAppearance

#EndRegion
