// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure // DescriptionOpening

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// One level of hierarchy is supported so far
	If ValueIsFilled(Object.Parent) Then
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure CodeOnChangeAtServer()
	Object.Code = cmGetValidName(TrimAll(Object.Code));
EndProcedure // CodeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure CodeOnChange(pItem)
	CodeOnChangeAtServer();
EndProcedure // CodeOnChange
