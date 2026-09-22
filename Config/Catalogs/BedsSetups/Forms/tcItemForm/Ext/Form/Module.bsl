#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
		Else	
			ThisObject.ReadOnly = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If Not ReadOnly Then
		OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations) , pItem, ThisObject, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SingleBedClick(pItem)
	Object.Code = TrimR(Object.Code) + "▌";
EndProcedure // SingleBedClick

// --------------------------------------------------------------------------------
&AtClient
Procedure DoubleBedClick(pItem)
	Object.Code = TrimR(Object.Code) + "█";
EndProcedure // DoubleBedClick

// --------------------------------------------------------------------------------
&AtClient
Procedure ExtraBedClick(pItem)
	Object.Code = TrimR(Object.Code) + "■";
EndProcedure // ExtraBedClick

// --------------------------------------------------------------------------------
&AtClient
Procedure InfantBedClick(pItem)
	Object.Code = TrimR(Object.Code) + "□";
EndProcedure // InfantBedClick

#EndRegion
