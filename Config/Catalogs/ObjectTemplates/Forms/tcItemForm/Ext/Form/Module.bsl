
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	For Each vType In Metadata.Catalogs.ObjectTemplates.Attributes["ObjectType"].Type.Types() Do
		Items.ObjectTypeStr.ChoiceList.Add(String(vType));
	EndDo;
	ObjectTypeStr = String(TypeOf(Object.ObjectType));
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ObjectTypeStrOnChange(Item)
	ObjectTypeStrOnChangeAtServer();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure ObjectTypeStrOnChangeAtServer()
	If Not IsBlankString(ObjectTypeStr) Then
		For Each vType In Metadata.Catalogs.ObjectTemplates.Attributes["ObjectType"].Type.Types() Do
			If String(vType) = ObjectTypeStr Then
				vTypesArray = New Array();
				vTypesArray.Add(vType);
				vTypeDef = New TypeDescription(vTypesArray);
				Object.ObjectType = vTypeDef.AdjustValue();
				Break;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

#EndRegion
