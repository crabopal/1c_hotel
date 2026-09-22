
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	UpdateFormAppearance();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure IsManualOnChange(pItem)
	UpdateFormAppearance();
EndProcedure // IsManualOnChange

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SegmentationAlgorithmTypeOnChange(Item)
	SegmentationAlgorithmTypeOnChangeAtServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = Items.SetColor.BackColor;
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisForm));
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	ClearColorAtServer();
	Items.SetColor.BackColor = ThisForm.Items.ClearColor.BackColor;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateFormAppearance()
	vColor = Undefined;
	If Not IsBlankString(Object.ColorHexString) Then
		vColor = tcOnServer.HexToColor(Object.ColorHexString);
	EndIf;
	If vColor <> Undefined And TypeOf(vColor) = Type("Color") Then
		Items.SetColor.BackColor = vColor;
	EndIf;
EndProcedure // UpdateFormAppearance

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure SegmentationAlgorithmTypeOnChangeAtServer()
	Object.Parameters.Clear();	
	Object.Parameters.Load(Object.SegmentationAlgorithmType.Parameters.Unload());	
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
			SaveColor(tcOnServer.HexToColor(tcOnServer.ColorToHex(pColor)));
			Items.SetColor.BackColor = pColor;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure SaveColor(pColor)
	Object.ColorHexString = tcOnServer.ColorToHex(pColor);
	ThisObject.Modified = True;
EndProcedure // SetGroupColor

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure ClearColorAtServer()
	Object.ColorHexString = "";
EndProcedure // ClearGroupColor

&AtServer
Procedure BeforeWriteAtServer(Cancel, pCurrentObject, WriteParameters)
	If Object.ColorHexString <> "" Then
		pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(Object.ColorHexString));
	Else
		pCurrentObject.Color = New ValueStorage(Undefined);
	EndIf;
EndProcedure

#EndRegion

