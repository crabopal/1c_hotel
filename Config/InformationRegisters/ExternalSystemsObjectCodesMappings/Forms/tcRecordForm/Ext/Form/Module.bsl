
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vCatalogsList = cmFillCatalogsList();
	Items.ObjectTypeName.ChoiceList.LoadValues(vCatalogsList.UnloadValues());
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ObjectTypeNameOnChange(pItem)
	ObjectTypeNameOnChangeAtServer();
EndProcedure // ObjectTypeNameOnChange

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure ObjectTypeNameOnChangeAtServer()
	If Not IsBlankString(Record.ObjectTypeName) Then
		Record.ObjectRef = Catalogs[TrimAll(Record.ObjectTypeName)].EmptyRef();
	Else
		Record.ObjectRef = Undefined;
	EndIf;
EndProcedure // ObjectTypeNameOnChangeAtServer

#EndRegion
