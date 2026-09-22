
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Check user rights to edit item
	If Not cmCheckUserPermissions("HavePermissionToManageHousekeeping") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit housekeeping settings!';ru='Нет прав на управление службой горничных!';de='Sie haben keine Rechte, die Einstellungen des Reinigungsdienstes zu verwalten!'"));
			Return;
		Else
			ReadOnly = True;
		EndIf;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
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
EndProcedure

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
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChatbotOperationRegistrationIsUsedOnChange(Item)
	ChatbotOperationRegistrationIsUsedOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OperationRegistrationIsUsedOnChange(Item)
	OperationRegistrationIsUsedOnChangeAtServer();
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
Procedure ChatbotOperationRegistrationIsUsedOnChangeAtServer()
	If Object.ChatbotOperationRegistrationIsUsed Then
		If Object.OperationRegistrationIsUsed Then
			Object.OperationRegistrationIsUsed = False;
		EndIf;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure OperationRegistrationIsUsedOnChangeAtServer()
	If Object.OperationRegistrationIsUsed Then
		If Object.ChatbotOperationRegistrationIsUsed Then
			Object.ChatbotOperationRegistrationIsUsed = False;
		EndIf;
	EndIf;
EndProcedure

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
	Items.ChoiceColor.TextColor = GetButtonTextColor(cmGetAbsoluteColor(Color));	
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetButtonTextColor(pColor)	
	If (1 - (0.299 * pColor.R + 0.587 * pColor.G + 0.114 * pColor.B) / 255 < 0.5) Then
		Return tcCommonFunctionOnClientServer.ColorConstructor();
	Else 
		Return tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 255);
	EndIf;	
EndFunction

#EndRegion
