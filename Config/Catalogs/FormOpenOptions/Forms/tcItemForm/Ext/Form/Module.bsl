
#Region FormEventHandlers

 // -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;	
	// For new items set activ
	If Object.Ref.IsEmpty() Then
		Object.IsActive = True;
	EndIf;	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Сheck the completion of the required form attributes
	vCount = Catalogs.FormOpenOptions.Select();
	If Not vCount.Next() Then
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Initial filling is required.'; de = 'Es ist notwendig, das erste Füllen des Verzeichnisses durchzuführen.'; ru = 'Необходимо выполнить первоначальное заполнение справочника.'"));
		pCancel = True;
		Return;
	EndIf;	
	If IsBlankString(Object.Parent.SystemName) Or Not ValueIsFilled(Object.Parent.Parent) Then
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Select the object for which you want to configure the form'; de = 'Wählen Sie das Objekt aus, für das Sie das Formular konfigurieren möchten'; ru = 'Выберите объект, для которого создается настройка формы'"));
		pCancel = True;
		Return;
	EndIf;	
	vFormList = Object.Parent.Forms.Get();
	If TypeOf(vFormList) = Type("ValueList") Then
		For Each vStr In vFormList Do
			Items.FormItem.ChoiceList.Add(vStr.Value, vStr.Presentation);
		EndDo;
	EndIf;	
	Object.SystemName = Object.Parent.SystemName;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Not IsBlankString(Object.Form) Then
		FilingFormAttributes();
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	vObj = FormAttributeToValue("Object");
	pCancel = tcOnServer.cmFillCheckProcessingForm(pCheckedAttributes, CheckedAttributesManual, vObj);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FormItemOnChange(Item)
	If ValueIsFilled(Item.EditText) Then
		Object.Description = String(Object.Parent) + "." + Items.FormItem.EditText;
		Object.PropertiesForm.Clear();
		FilingFormAttributes();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PropertiesFormsItemChoiceProcessing(Item, SelectedValue, StandardProcessing)
	vTab = Object.PropertiesForm;
	If vTab.Count() > 0 Then
		If vTab.FindRows(New Structure("Item", SelectedValue)).Count() > 0 Then   
			vMsg = Nstr("en = 'The setting for this field already exists, select another'; 
						|de = 'Die Einstellung für dieses Feld ist bereits vorhanden, wählen Sie eine andere aus'; 
						|ru = 'Настройка для этого поля уже существует, выберите другое'");
			tcCommonFunctionOnClientServer.UserMessage(vMsg, , Item.Name);
			StandardProcessing = False;
		EndIf;	
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FormItemChoiceProcessing(Item, SelectedValue, StandardProcessing)
	If IsDuplication(SelectedValue, Object.SystemName, Object.Code) Then   
		vMsg = Nstr("en = 'The setting for this form already exists, select another'; 
					|de = 'Die Einstellung für dieses Formular ist bereits vorhanden, wählen Sie eine andere aus'; 
					|ru = 'Настройка для этой формы уже существует, выберите другую'");
		tcCommonFunctionOnClientServer.UserMessage(vMsg, , Item.Name);
		StandardProcessing = False;
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure FilingFormAttributes() 
	// BSLLS:GetFormMethod-off
	vForm = GetForm(Object.SystemName + ".Form." + Object.Form, New Structure("AvtoTest", True));
	Items.PropertiesFormsItem.ChoiceList.Clear();
	For Each vId In vForm.Items Do
		If TypeOf(vId) = Type("FormField") Then  
			vNameItem = vId.Title;
			If IsBlankString(vId.Title) Then
			   vNameItem = vId.Name;
			EndIf;
			Items.PropertiesFormsItem.ChoiceList.Add(vId.Name, vNameItem);
		EndIf;	
	EndDo;
	Items.PropertiesFormsItem.ChoiceList.SortByPresentation();
	
	If vForm.AutoFillCheck = False Then
		Items.PropertiesFormsFilling.Visible = False;
	Else	
		Try
			vExist = vForm.CheckedAttributesManual;
			Items.PropertiesFormsFilling.Visible = True;
		Except
			Items.PropertiesFormsFilling.Visible = False;
		EndTry;
	EndIf; 
	// BSLLS:GetFormMethod-on
EndProcedure

// -----------------------------------------------------------------------------
//
// Parameters:
//  pForm		 - ClientApplicationForm - Form
//  pSystemName	 - String - System name
//  pCode		 - String - Code
// 
// Returns:
//  Boolean - True or false
//
&AtServerNoContext
Function IsDuplication(pForm, pSystemName, pCode)  
	vIsDuplication = False;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	FormOpenOptions.Ref AS Ref
		|FROM
		|	Catalog.FormOpenOptions AS FormOpenOptions
		|WHERE
		|	FormOpenOptions.IsActive
		|	AND FormOpenOptions.SystemName = &qSystemName
		|	AND FormOpenOptions.Form = &qForm";
	
	vQuery.SetParameter("qForm", pForm);
	vQuery.SetParameter("qSystemName", pSystemName);          
	
	vResQuery = vQuery.Execute();
	If vResQuery.IsEmpty() Then
		vIsDuplication = False;
	Else
		vRes = vResQuery.Select();
		vRes.Next();
		If vRes.Ref.Code <> pCode Then
			vIsDuplication = True;
		EndIf;	
	EndIf;	
	Return vIsDuplication;
EndFunction

#EndRegion
