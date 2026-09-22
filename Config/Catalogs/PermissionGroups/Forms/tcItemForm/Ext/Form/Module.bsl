
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
	// Fill permissions table box
	FillPermissionTableBox();
	// Fill roles table box
	LoadMetadataRoles();
	If Not AccessRight("Administration", Metadata) Then
		Items.PageInfobaseUserRoles.Visible = False;
	EndIf;
	// Set form appearance
	SetFormAppearance();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	// Save permissions
	For Each vRow In Permissions Do
		pCurrentObject[vRow.PermissionName] = vRow.PermissionValue;
	EndDo;
	// Check payment methods
	vInt = 0;
	While vInt < pCurrentObject.PaymentMethodsAllowed.Count() Do
		vPMRow = pCurrentObject.PaymentMethodsAllowed.Get(vInt);
		If Not ValueIsFilled(vPMRow.PaymentMethod) Then
			pCurrentObject.PaymentMethodsAllowed.Delete(vInt);
		Else
			vInt = vInt + 1;
		EndIf;
	EndDo;
	// Check room rates
	vInt = 0;
	While vInt < pCurrentObject.RoomRatesAllowed.Count() Do
		vRRRow = pCurrentObject.RoomRatesAllowed.Get(vInt);
		If Not ValueIsFilled(vRRRow.RoomRate) Then
			pCurrentObject.RoomRatesAllowed.Delete(vInt);
		Else
			vInt = vInt + 1;
		EndIf;
	EndDo;
	// Check discount types
	vInt = 0;
	While vInt < pCurrentObject.DiscountTypesAllowed.Count() Do
		vDTRow = pCurrentObject.DiscountTypesAllowed.Get(vInt);
		If Not ValueIsFilled(vDTRow.DiscountType) Then
			pCurrentObject.DiscountTypesAllowed.Delete(vInt);
		Else
			vInt = vInt + 1;
		EndIf;
	EndDo;
	// Check client types
	vInt = 0;
	While vInt < pCurrentObject.ClientTypesAllowed.Count() Do
		vCTRow = pCurrentObject.ClientTypesAllowed.Get(vInt);
		If Not ValueIsFilled(vCTRow.ClientType) Then
			pCurrentObject.ClientTypesAllowed.Delete(vInt);
		Else
			vInt = vInt + 1;
		EndIf;
	EndDo;
	// Check hotels
	vInt = 0;
	While vInt < pCurrentObject.HotelAllowed.Count() Do
		vCTRow = pCurrentObject.HotelAllowed.Get(vInt);
		If Not ValueIsFilled(vCTRow.Hotel) Then
			pCurrentObject.HotelAllowed.Delete(vInt);
		Else
			vInt = vInt + 1;
		EndIf;
	EndDo;
	// Check room statuses
	vInt = 0;
	While vInt < pCurrentObject.RoomStatusesAllowed.Count() Do
		vCTRow = pCurrentObject.RoomStatusesAllowed.Get(vInt);
		If Not ValueIsFilled(vCTRow.RoomStatus) Then
			pCurrentObject.RoomStatusesAllowed.Delete(vInt);
		Else
			vInt = vInt + 1;
		EndIf;
	EndDo;
	// Check door lock system authorizations
	vInt = 0;
	While vInt < pCurrentObject.DoorLockSystemAuthorizations.Count() Do
		vCTRow = pCurrentObject.DoorLockSystemAuthorizations.Get(vInt);
		If Not ValueIsFilled(vCTRow.DoorLockSystemAuthorization) Then
			pCurrentObject.DoorLockSystemAuthorizations.Delete(vInt);
		Else
			vInt = vInt + 1;
		EndIf;
	EndDo;
	// Check folio operations allowed per folio types
	vInt = 0;
	While vInt < pCurrentObject.FolioOperationsAllowed.Count() Do
		vCTRow = pCurrentObject.FolioOperationsAllowed.Get(vInt);
		If Not ValueIsFilled(vCTRow.FolioType) Then
			pCurrentObject.FolioOperationsAllowed.Delete(vInt);
		Else
			vInt = vInt + 1;
		EndIf;
	EndDo;
	// Save Infobase user roles
	pCurrentObject.InfobaseUserRoles.Clear();
	vAdministrator = TableBoxInfobaseUserRoles.FindRows(New Structure("Role", "Administrator"));
	vAdministratorEnabled = False;
	If vAdministrator.Count() > 0 Then
		vAdministratorEnabled = vAdministrator[0].Enabled;	
	EndIf;
	For Each vRole in TableBoxInfobaseUserRoles Do
		If vRole.Role = "SelfService" And vAdministratorEnabled Then
			vRole.Enabled = False;
			Continue;
		EndIf;
		If vRole.Enabled Then
			vNewRow = pCurrentObject.InfobaseUserRoles.Add();
			vNewRow.Role = vRole.Role;
		EndIf;
	EndDo;
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure PermissionsOnActivateRow(pItem)
	If Not Items.Permissions.CurrentData = Undefined Then
		Items.PermissionsExtendedTooltip.Title = Items.Permissions.CurrentData.PermissionSpecification;
	EndIf;	
EndProcedure // PermissionsOnActivateRow

// --------------------------------------------------------------------------------
&AtClient
Procedure SearchStringAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	Items.ShowActivePermission.Check = False;
	Items.Permissions.RowFilter = New FixedStructure("PermissionDescription", pText);
EndProcedure // SearchStringAutoComplete

// --------------------------------------------------------------------------------
&AtClient
Procedure SearchStringClearing(pItem, pStandardProcessing)
	Items.ShowActivePermission.Check = False;
	Items.Permissions.RowFilter = New FixedStructure("PermissionDescription", "");
EndProcedure // SearchStringClearing 

// --------------------------------------------------------------------------------
&AtClient
Procedure PermissionsPermissionValueOnChange(pItem)
	Modified = True;
EndProcedure // PermissionsPermissionValueOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure InfobaseUserRolesEnabledOnChange(pItem)
	Modified = True;
EndProcedure // InfobaseUserRolesEnabledOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure InfobaseUserRolesBeforeRowChange(pItem, pCancel)
	vCurData = Items.InfobaseUserRoles.CurrentData;
	If vCurData.Role = "SelfService" Then                            
		vAdministrator = TableBoxInfobaseUserRoles.FindRows(New Structure("Role", "Administrator"));
		If vAdministrator.Count() > 0 Then
			If vAdministrator[0].Enabled Then
				pCancel = True;	
			EndIf;
		EndIf;
	ElsIf vCurData.Role = "Administrator" Then 
		vSelfService = TableBoxInfobaseUserRoles.FindRows(New Structure("Role", "SelfService"));
		If vSelfService.Count() > 0 Then
			If vSelfService[0].Enabled Then
				pCancel = True;	
			EndIf;
		EndIf;	
	EndIf;
EndProcedure // InfobaseUserRolesBeforeRowChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DesktopExternalDataProcessorOnChange(pItem)
	SetFormAppearance();
EndProcedure // DesktopExternalDataProcessorOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DesktopFormOnChange(pItem)
	SetFormAppearance();
EndProcedure // DesktopFormOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DesktopFormStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	pStandardProcessing = False;
	If pChoiceData = Undefined Then
		pChoiceData = New ValueList();
	EndIf;
	pChoiceData.Add("Document.ServiceRegistration.Form.tcServiceControlForm", NStr("en='Meal control'; ru='Контроль услуг питания'; de='Kontrolle von Essen'"));
	pChoiceData.Add("DataProcessor.Messages.Form.tcForm", NStr("en='Task list of current employee'; ru='Список задач текущего сотрудника'; de='Aufgabenliste des aktuellen Mitarbeiters'"));
EndProcedure // DesktopFormStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckAll(pCommand)
	For Each vRow In Permissions Do
		vRow.PermissionValue = True;
	EndDo;
	Items.Permissions.RowFilter = New FixedStructure("PermissionValue", "");
	Items.ShowActivePermission.Check = False;
	Modified = True;
EndProcedure // CheckAll

// --------------------------------------------------------------------------------
&AtClient
Procedure UnCheckAll(pCommand)
	For Each vRow In Permissions Do
		vRow.PermissionValue = False;
	EndDo;
	Items.Permissions.RowFilter = New FixedStructure("PermissionValue", "");
	Items.ShowActivePermission.Check = False;
	Modified = True;
EndProcedure // UnCheckAll

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowActivePermission(pCommand)
	Items.ShowActivePermission.Check = Not Items.ShowActivePermission.Check;
	If Items.ShowInactivePermission.Check Then
		Items.ShowInactivePermission.Check = Not Items.ShowInactivePermission.Check;
	EndIf;
	If Items.ShowActivePermission.Check Then                                                                
		Items.Permissions.RowFilter = New FixedStructure("PermissionValue", True);
	Else
		Items.Permissions.RowFilter = New FixedStructure("PermissionValue", "");
	EndIf;
EndProcedure // ShowActivePermission

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowInactivePermission(pCommand)
	If Items.ShowActivePermission.Check Then
		Items.ShowActivePermission.Check = Not Items.ShowActivePermission.Check;
	EndIf;
	Items.ShowInactivePermission.Check = Not Items.ShowInactivePermission.Check;
	If Items.ShowInactivePermission.Check Then
		Items.Permissions.RowFilter = New FixedStructure("PermissionValue", False);
	Else
		Items.Permissions.RowFilter = New FixedStructure("PermissionValue", "");
	EndIf;
EndProcedure // ShowInactivePermission

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillPermissionTableBox()
	vObj = FormAttributeToValue("Object");
	Permissions.Clear();
	For Each vMDAttr In vObj.Metadata().Attributes Do
		If Left(vMDAttr.Name, 16) = "HavePermissionTo" Then
			vShowPermission = True;
			If Not IsBlankString(SearchString) Then
				If Find(Upper(vMDAttr.Synonym), Upper(TrimAll(SearchString))) = 0 Then
					vShowPermission = False;
				EndIf;
			EndIf;
			If vShowPermission Then
				vRow = Permissions.Add();
				vRow.PermissionValue = Object[vMDAttr.Name];
				vRow.PermissionName = vMDAttr.Name;
				vRow.PermissionDescription = vMDAttr.Synonym;
				vRow.PermissionSpecification = vMDAttr.ToolTip;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillPermissionTableBox

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadMetadataRoles()
	TableBoxInfobaseUserRoles.Clear();
	For Each vRole In Metadata.Roles Do
		vNewRow = TableBoxInfobaseUserRoles.Add();
		vNewRow.Role = vRole.Name;
		vNewRow.RoleDescription = vRole.Synonym;
		For Each vEnabledRoles In Object.InfobaseUserRoles Do
			If vNewRow.Role = vEnabledRoles.Role Then
				vNewRow.Enabled = True;
				Break;
			EndIf;
		EndDo;
	EndDo;	
EndProcedure // LoadMetadateRoles

// --------------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearance()
	If ValueIsFilled(Object.DesktopExternalDataProcessor) Then
		Items.DesktopForm.Enabled = False;
	Else
		Items.DesktopForm.Enabled = True;
	EndIf;
	If Not IsBlankString(Object.DesktopForm) Then
		Items.DesktopExternalDataProcessor.Enabled = False;
	Else
		Items.DesktopExternalDataProcessor.Enabled = True;
	EndIf;
EndProcedure // SetFormAppearance

#EndRegion    
