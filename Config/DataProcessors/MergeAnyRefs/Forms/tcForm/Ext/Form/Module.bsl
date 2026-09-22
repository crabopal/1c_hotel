#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelDefaultTypeDescription") Then
		SelDefaultTypeDescription = Parameters.SelDefaultTypeDescription;
	EndIf;
	If Parameters.Property("SelMergedRef") Then
		If ValueIsFilled(SelDefaultTypeDescription) And SelDefaultTypeDescription.Types()[0] = TypeOf(Parameters.SelMergedRef) Or Not ValueIsFilled(SelDefaultTypeDescription) Then  
			Object.MergedRef = Parameters.SelMergedRef;
		EndIf;
	EndIf;
	If Parameters.Property("SelMainRef") Then
		If ValueIsFilled(SelDefaultTypeDescription) And SelDefaultTypeDescription.Types()[0] = TypeOf(Parameters.SelMainRef) Or Not ValueIsFilled(SelDefaultTypeDescription) Then
			Object.MainRef = Parameters.SelMainRef;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.MergedRef) Then
		SelMergedCode = tcOnServer.cmGetAttributeByRef(Object.MergedRef, "Code");	
	Else
		SelMergedCode = "";	
	EndIf;
	If ValueIsFilled(Object.MainRef) Then
		SelMainCode = tcOnServer.cmGetAttributeByRef(Object.MainRef, "Code");	
	Else
		SelMainCode = "";	
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If ValueIsFilled(SelDefaultTypeDescription) Then
		Items.MergedRef.TypeRestriction = SelDefaultTypeDescription;
		Items.MainRef.TypeRestriction = SelDefaultTypeDescription;
		Items.MergedRef.ChooseType = False;
		Items.MainRef.ChooseType = False;
	Else
		Items.MergedRef.TypeRestriction = New TypeDescription();
		Items.MainRef.TypeRestriction = New TypeDescription();	
		Items.MergedRef.ChooseType = True;
		Items.MainRef.ChooseType = True;
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionMerge(pCommand)
	vMesseg = "";
	If ActionMergeAtServer(vMesseg) Then	
		Notify("MergeAnyRefs.Change", Object.MainRef);
		MergedRefOnChange(Items.MergedRef);
		MainRefOnChange(Items.MainRef);
	EndIf;
	If ValueIsFilled(vMesseg) Then 
		ShowMessageBox(, vMesseg);
	EndIf;
EndProcedure // ActionMerge

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionSwap(pCommand)
	vMergedRef = Object.MergedRef;
	vMainRef = Object.MainRef;
	Object.MainRef = vMergedRef;
	Object.MergedRef = vMainRef;
	MergedRefOnChange(Items.MergedRef);
	MainRefOnChange(Items.MainRef);
EndProcedure // ActionSwap

#EndRegion

#Region FormItemsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure MergedRefOnChange(pItem)
	If ValueIsFilled(Object.MergedRef) And ValueIsFilled(Object.MainRef) And Object.MergedRef = Object.MainRef Then
		Object.MergedRef = Undefined;
		ShowMessageBox(,NStr("en = 'Reference cannot be the same!'; de = 'Referenz kann nicht gleich Referenz sein!'; ru = 'Ссылки не могут быть одинаковыми!'"));
		Return;
	EndIf;
	ClearAttributes();
	If Not ValueIsFilled(Object.MergedRef) And TypeOf(Object.MergedRef) = Type("Undefined") Then
		Items.MergedRef.TypeRestriction = GetTypeDescriptionByType(TypeOf(Object.MainRef));		
	EndIf;
	If ValueIsFilled(Object.MergedRef) Then
		SelMergedCode = tcOnServer.cmGetAttributeByRef(Object.MergedRef, "Code");	
	Else
		SelMergedCode = "";	
	EndIf;
EndProcedure // MergedRefOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure MainRefOnChange(pItem)
	If ValueIsFilled(Object.MergedRef) And ValueIsFilled(Object.MainRef) And Object.MergedRef = Object.MainRef Then
		Object.MainRef = Undefined;
		ShowMessageBox(,NStr("en = 'Reference cannot be the same!'; de = 'Referenz kann nicht gleich Referenz sein!'; ru = 'Ссылки не могут быть одинаковыми!'"));
		Return;
	EndIf;
	ClearAttributes();
	If Not ValueIsFilled(Object.MainRef) And TypeOf(Object.MainRef) = Type("Undefined") Then
		Items.MainRef.TypeRestriction = GetTypeDescriptionByType(TypeOf(Object.MergedRef));		
	EndIf;
	If ValueIsFilled(Object.MainRef) Then
		SelMainCode = tcOnServer.cmGetAttributeByRef(Object.MainRef, "Code");	
	Else
		SelMainCode = "";	
	EndIf;
EndProcedure // MainRefOnChange

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function ActionMergeAtServer(rMesseg)
	vResult = False;
	If CheckFilling() Then
		vObj = FormAttributeToValue("Object");
		If vObj.pmMerge(rMesseg) Then
			rMesseg = NStr("en='Success!';ru='Выполнено!';de='Ausgeführt!'");
			vResult = True;	
			ValueToFormAttribute(vObj,"Object");
		EndIf;
	EndIf;
	Return vResult;
EndFunction // ActionMergeAtServer

// -----------------------------------------------------------------------------
&AtClient
Function GetTypeDescriptionByType(pType)
	If ValueIsFilled(SelDefaultTypeDescription) Then
		Return SelDefaultTypeDescription; 	
	EndIf;
	If pType <> Type("Undefined") Then
		vArrType = New Array();
		vArrType.Add(pType);
		vTypeDescription = New TypeDescription(vArrType);	
	Else
		vTypeDescription = New TypeDescription();	
	EndIf;
	Return vTypeDescription;
EndFunction // GetEmptyRefByType

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearAttributes()
	If Not ValueIsFilled(Object.MergedRef) And Not ValueIsFilled(Object.MainRef) Then
		Object.MergedRef = Undefined;
		Object.MainRef = Undefined;
		If ValueIsFilled(SelDefaultTypeDescription) Then
			Items.MergedRef.TypeRestriction = SelDefaultTypeDescription;
			Items.MainRef.TypeRestriction = SelDefaultTypeDescription;
			Items.MergedRef.ChooseType = False;
			Items.MainRef.ChooseType = False;
		Else
			Items.MergedRef.TypeRestriction = New TypeDescription();
			Items.MainRef.TypeRestriction = New TypeDescription();	
			Items.MergedRef.ChooseType = True;
			Items.MainRef.ChooseType = True;
		EndIf;
	EndIf;
EndProcedure // ClearAttributes

#EndRegion