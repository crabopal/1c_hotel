// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vReadOnly = False;
	If Parameters.Property("ReadOnly") And TypeOf(Parameters.ReadOnly) = Type("Boolean") Then
		vReadOnly = Parameters.ReadOnly;
	EndIf;
	
	Items.Confirm.Enabled = Not vReadOnly;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Languages.Ref
	|FROM
	|	Catalog.Languages AS Languages
	|WHERE
	|	NOT Languages.DeletionMark
	|
	|ORDER BY
	|	Languages.Code";
	vQueryResult = vQuery.Execute();
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		vName = TrimAll(vSelectionDetailRecords.Ref);
		
		NewAttributes = New Array;
		NewAttribute = New FormAttribute(vName, New TypeDescription("String"), , vName,False);
		NewAttributes.Add(NewAttribute);
		ChangeAttributes(NewAttributes);
		ThisForm[vName] =  NStr(Parameters.Text, vSelectionDetailRecords.Ref);
		tcOnServer.cmCreateItem(ThisForm,Items.GroupBox,TrimAll(vSelectionDetailRecords.Ref), "FormField",
					New Structure("Title, DataPath, Type, HorizontalStretch, VerticalStretch, AutoMaxWidth, MultiLine, ReadOnly",
					TrimAll(vSelectionDetailRecords.Ref), vName, FormFieldType.InputField, True, True, False, True, vReadOnly));	
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure Confirm(pCommand)
	NotifyChoice(ConfirmArServer());
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function ConfirmArServer()
	vText = "";	
	vArray = GetAttributes();
	For Each vAtr In vArray Do
		If ThisForm[vAtr.Name] <> "" Then
			vText = vText + vAtr.Name + "='" + ThisForm[vAtr.Name] + "';";  
		EndIf;
	EndDo;
	Return vText; 
EndFunction

