
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill form attributes
	FillPropertyValues(ThisForm, Parameters);
	
	// Check if report attribute is defined
	If Not ValueIsFilled(Report) Then
		pCancel = True;
		Return;
	EndIf;
	
	// Report name
	ReportName = TrimAll(Report.Code) + " - " + cmNStr(Report.Description);
	
	// Restore selected fields value table
	vAppearances = Undefined;
	If IsBlankString(AppearanceAddress) Then
		vAppearances = New ValueTable();
		vAppearances.Columns.Add("Title", cmGetStringTypeDescription(1000));
		vAppearances.Columns.Add("Name", cmGetStringTypeDescription(1000));
		vAppearances.Columns.Add("Value");
		vAppearances.Columns.Add("ValueType");
		vAppearances.Columns.Add("Use", cmGetBooleanTypeDescription());
		
		// Initialize value table with rows
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Text color'; ru='Цвет текста'; de='Vordergrundfarbe'");
		vRow.Name = "TextColor";
		vRow.Value = New Color;
		vTypesArray = New Array;
		vTypesArray.Add(Type("Color"));
		vRow.ValueType = New TypeDescription(vTypesArray);
		vRow.Use = False;
		
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Back color'; ru='Цвет фона'; de='Hintergrundfarbe'");
		vRow.Name = "BackColor";
		vRow.Value = New Color;
		vTypesArray = New Array;
		vTypesArray.Add(Type("Color"));
		vRow.ValueType = New TypeDescription(vTypesArray);
		vRow.Use = False;
		
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Font'; ru='Шрифт'; de='Schrift'");
		vRow.Name = "Font";
		vRow.Value = New Font;
		vTypesArray = New Array;
		vTypesArray.Add(Type("Font"));
		vRow.ValueType = New TypeDescription(vTypesArray);
		vRow.Use = False;
		
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Format'; ru='Формат'; de='Format'");
		vRow.Name = "Format";
		vRow.Value = "";
		vRow.ValueType = cmGetStringTypeDescription();
		vRow.Use = False;
		
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Horizontal align'; ru='Горизонтальное положение'; de='Horizontale Ausrichtung'");
		vRow.Name = "HorizontalAlign";
		vRow.Value = HorizontalAlign.Left;
		vTypesArray = New Array;
		vTypesArray.Add(TypeOf(HorizontalAlign.Left));
		vRow.ValueType = New TypeDescription(vTypesArray);
		vRow.Use = False;
		
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Vertical align'; ru='Вертикальное положение'; de='Vertikale Ausrichtung'");
		vRow.Name = "VerticalAlign";
		vRow.Value = VerticalAlign.Top;
		vTypesArray = New Array;
		vTypesArray.Add(TypeOf(VerticalAlign.Top));
		vRow.ValueType = New TypeDescription(vTypesArray);
		vRow.Use = False;
		
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Text orientation'; ru='Ориентация текста'; de='Text Ausrichtung'");
		vRow.Name = "TextOrientation";
		vRow.Value = 0;
		vRow.ValueType = cmGetNumberTypeDescription(3, 0);
		vRow.Use = False;
		
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Indent'; ru='Отступ'; de='Einzug'");
		vRow.Name = "Indent";
		vRow.Value = 0;
		vRow.ValueType = cmGetNumberTypeDescription(6, 0);
		vRow.Use = False;
		
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Autoindent'; ru='Автоотступ'; de='Autoeinzug'");
		vRow.Name = "AutoIndent";
		vRow.Value = 0;
		vRow.ValueType = cmGetNumberTypeDescription(6, 0);
		vRow.Use = False;
		
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Mark negatives'; ru='Выделять отрицательные'; de='Negative hervorheben'");
		vRow.Name = "MarkNegatives";
		vRow.Value = False;
		vRow.ValueType = cmGetBooleanTypeDescription();
		vRow.Use = False;
		
		vRow = vAppearances.Add();
		vRow.Title = NStr("en='Text'; ru='Текст'; de='Text'");
		vRow.Name = "Text";
		vRow.Value = "";
		vRow.ValueType = cmGetStringTypeDescription();
		vRow.Use = False;
	Else
		vAppearances = GetFromTempStorage(AppearanceAddress);
	EndIf;
	If vAppearances = Undefined Or TypeOf(vAppearances) <> Type("ValueTable") Then
		pCancel = True;
		Return;
	EndIf;
	Appearances.Clear();
	For Each vAppearancesRow In vAppearances Do
		vRowItem = Appearances.Add();
		FillPropertyValues(vRowItem, vAppearancesRow);
	EndDo;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AppearancesValueOnChange(pItem)
	vCurData = Items.Appearances.CurrentData;
	If vCurData <> Undefined Then
		vCurData.Use = True;
	EndIf;
EndProcedure // AppearancesValueOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure AppearancesValueStartChoice(pItem, pChoiceData, pStandardProcessing)
	vCurData = Items.Appearances.CurrentData;
	If vCurData <> Undefined Then
		If vCurData.ValueType = Type("Color") Then
			pStandardProcessing = False;
			vColorPicker = New ColorChooseDialog;
			vColorPicker.Color = vCurData.Value;
			vColorPicker.Show(New NotifyDescription("ColorPickerAfterChoice", ThisForm));
		ElsIf vCurData.ValueType = Type("Font") Then
			pStandardProcessing = False;
			vFontPicker = New FontChooseDialog;
			vFontPicker.Font = vCurData.Value;
			vFontPicker.Show(New NotifyDescription("FontPickerAfterChoice", ThisForm));
		ElsIf vCurData.Name = "Format" Then
			pStandardProcessing = False;
			#If Not MobileClient Then
				vFormatStringWizard = New FormatStringWizard;
				vFormatStringWizard.Text = vCurData.Value;
				vFormatStringWizard.Show(New NotifyDescription("FormatStringWizardAfterChoice", ThisForm));
			#EndIf
		EndIf;
	EndIf;
EndProcedure // AppearancesValueStartChoice


#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	vAppearancePresentation = "";
	vAppearanceAddress = GetAppearanceAddressAtServer(vAppearancePresentation);
	NotifyChoice(New Structure("Report, AppearanceAddress, AppearancePresentation", Report, vAppearanceAddress, vAppearancePresentation));
EndProcedure // SaveSettings

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function GetAppearanceAddressAtServer(rAppearancePresentation)
	rAppearancePresentation = "";
	vAppearances = FormAttributeToValue("Appearances");
	For Each vAppearancesRow In vAppearances Do
		If vAppearancesRow.Use Then
			rAppearancePresentation = rAppearancePresentation + 
			                          ?(IsBlankString(rAppearancePresentation), "", "; ") + 
								      TrimAll(vAppearancesRow.Title);
		EndIf;
	EndDo;
	vAppearanceAddress = PutToTempStorage(vAppearances, ThisForm.UUID);
	Return vAppearanceAddress;
EndFunction // GetAppearanceAddressAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ColorPickerAfterChoice(pColor, pExtraParams) Export
	If pColor <> Undefined And TypeOf(pColor) = Type("Color") Then
		vCurData = Items.Appearances.CurrentData;
		If vCurData <> Undefined Then
			vCurData.Value = pColor;
			vCurData.Use = True;
		EndIf;
	EndIf;
EndProcedure // ColorPickerAfterChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure FontPickerAfterChoice(pFont, pExtraParams) Export
	If pFont <> Undefined And TypeOf(pFont) = Type("Font") Then
		vCurData = Items.Appearances.CurrentData;
		If vCurData <> Undefined Then
			vCurData.Value = pFont;
			vCurData.Use = True;
		EndIf;
	EndIf;
EndProcedure // FontPickerAfterChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure FormatStringWizardAfterChoice(pFormatString, pExtraParams) Export
	If pFormatString <> Undefined And TypeOf(pFormatString) = Type("String") Then
		vCurData = Items.Appearances.CurrentData;
		If vCurData <> Undefined Then
			vCurData.Value = pFormatString;
			vCurData.Use = True;
		EndIf;
	EndIf;
EndProcedure // FormatStringWizardAfterChoice

#EndRegion
