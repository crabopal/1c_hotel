
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Object.Ref.IsEmpty() Then
		Object.IsActive = True;
	EndIf;
	
	TypeDescription = cmGetObjectTypeDescription(Object.ObjectType);
	Items.ObjectType.AvailableTypes = cmGetObjectsTypeDescription();
	Items.ObjectType.TypeDomainEnabled = False;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ButtonCaptionOpening(pItem, pStandardProcessing)
	pStandardProcessing = false;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.ButtonCaption), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ButtonToolTipOpening(pItem, pStandardProcessing)
	pStandardProcessing = false;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.ButtonCaption), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ObjectTypeOnChange(pItem)
	Object.ObjectType = TypeDescription.AdjustValue();
EndProcedure

#EndRegion

