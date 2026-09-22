
#Region FormEventHandlers

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Color
	vColor = GetColor();
	If vColor <> Undefined Then
		ItemColor = vColor;
		ItemColorIsSet = True;
		ThisForm.Items.FormSetColor.BackColor = vColor;
	Else
		ItemColor = Undefined;
		ItemColorIsSet = False;
	EndIf;
EndProcedure // OnCreateAtServer

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If ItemColorIsSet Then
		pCurrentObject.ColorHexString = tcOnServer.ColorToHex(ItemColor);
		pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(pCurrentObject.ColorHexString));
	Else
		pCurrentObject.ColorHexString = "";
		pCurrentObject.Color = Undefined;
	EndIf;
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = ItemColor;
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisForm))
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	ItemColor = Undefined;
	ItemColorIsSet = False;
	ThisForm.Items.FormSetColor.BackColor = ThisForm.Items.FormClearColor.BackColor;
EndProcedure // ClearColor

#EndRegion

#Region Private

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetColor()
	vColor = Undefined;
	If Not IsBlankString(Object.ColorHexString) Then
		vColor = tcOnServer.HexToColor(Object.ColorHexString);
		If TypeOf(vColor) <> Type("Color") Then
			vColor = Undefined;
		EndIf;
	EndIf;
	Return vColor;
EndFunction // GetColor

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		ItemColor = pColor;
		ItemColorIsSet = True;
		ThisForm.Items.FormSetColor.BackColor = pColor;
	EndIf;
EndProcedure // SetColorAfterUserChoice

#EndRegion

