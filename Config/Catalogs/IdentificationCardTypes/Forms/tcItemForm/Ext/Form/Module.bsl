
#Region FormEventHandlers

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	// Check user rights to edit item
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = true;
			Return;
		Else
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
	// Get type color
	vColor = GetTypeColor();
	If TypeOf(vColor) = Type("Color") Then
		ThisForm.Items.SetColor.BackColor = vColor;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	ClearTypeColor();
	ThisForm.Items.SetColor.BackColor = ThisForm.Items.ClearColor.BackColor;
EndProcedure // ClearColor

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = GetTypeColor();
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisForm));
EndProcedure // SetColor

#EndRegion

#Region Private

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		SetTypeColor(pColor);
		ThisForm.Items.SetColor.BackColor = pColor;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetTypeColor()
	Return tcOnServer.HexToColor(Object.ColorHexString);
EndFunction // GetTypeColor

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure SetTypeColor(pColor)
	Object.ColorHexString = tcOnServer.ColorToHex(pColor);
EndProcedure // SetTypeColor

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure ClearTypeColor()
	Object.ColorHexString = "";
EndProcedure // ClearTypeColor

&AtServer
Procedure BeforeWriteAtServer(Cancel, pCurrentObject, WriteParameters)
	If Object.ColorHexString <> "" Then
		pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(Object.ColorHexString));
	Else
		pCurrentObject.Color = New ValueStorage(Undefined);
	EndIf;
EndProcedure

#EndRegion

