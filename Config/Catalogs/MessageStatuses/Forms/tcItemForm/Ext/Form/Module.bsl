
#Region Main

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetColor()
	vColor = Undefined;
	If Not IsBlankString(Object.ColorHexString) Then
		vColor = tcOnServer.HexToColor(Object.ColorHexString);
	EndIf;
	Return vColor;
EndFunction // GetColor

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = GetColor();
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisObject));
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		vColor = tcOnServer.HexToColor(tcOnServer.ColorToHex(pColor));
		Items.SetColor.BackColor = vColor;
		Object.ColorHexString = tcOnServer.ColorToHex(pColor); 
	EndIf;
EndProcedure // SetColorAfterUserChoice

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	Object.ColorHexString = "";
	Items.SetColor.BackColor = Items.ClearColor.BackColor;
	Notify("Subsystem.Accounts.Changed", Object.Ref);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Color
	vColor = GetColor();
	If TypeOf(vColor) = Type("Color") Then
		Items.SetColor.BackColor = vColor;
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(Cancel, pCurrentObject, WriteParameters)
	If pCurrentObject.ColorHexString = "" Then
		pCurrentObject.Color = New ValueStorage(Undefined);
	Else
		pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(pCurrentObject.ColorHexString));
	EndIf;
EndProcedure // BeforeWriteAtServer

#EndRegion