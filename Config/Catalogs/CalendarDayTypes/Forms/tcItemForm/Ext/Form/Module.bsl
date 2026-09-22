
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
	
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;
	
	// Set color
	vColor = GetColor();
	If vColor <> Undefined Then
		Color = vColor;
		SetColor(Color);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If ClearColor Then
		pCurrentObject.Color = New ValueStorage(Undefined);
		pCurrentObject.ColorHexString = "";
	Else
		If PickColor Then
			pCurrentObject.ColorHexString = tcOnServer.ColorToHex(Color);
			pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(pCurrentObject.ColorHexString));
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsStartListChoice(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations), pItem);	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceColor(pCommand)
	vDialog = New ColorChooseDialog();
	vDialog.Color = Color;
	vDialog.Show(New NotifyDescription("ColorPick", ThisObject));	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	ClearColor = True;
	PickColor = False;
	Items.ChoiceColor.BackColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 255);
	Items.ChoiceColor.TextColor = tcCommonFunctionOnClientServer.ColorConstructor(0, 0, 0); 
	Modified = True;	
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure ColorPick(pColor, pParametr) Export
	If pColor <> Undefined Then
		ClearColor = False;
		PickColor = True;
		SetColor(pColor);
		Modified = True;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SetColor(pColor)	
	Color = pColor;
	Items.ChoiceColor.BackColor = Color;
	Items.ChoiceColor.TextColor = GetButtonTextColor(cmGetAbsoluteColor(Color));	
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

// ------------------------------------------------------------------------------------------------
// 
// Returns:
//  Color - the color recieved from Color Hex String
//
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

#EndRegion
