
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use folder
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManageAllotments") And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage allotments!';ru='Нет прав на управление квотами!';de='Sie haben keine Rechte, Kontingente zu verwalten!'"));
		EndIf;
		If Object.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
			Object.AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed;
		Else
			Object.AllotmentType = Enums.AllotmentTypes.Definite;
		EndIf;
		Object.DoWriteOff = True;
		Object.TreatAsTentativeBooking = False;
	Else
		If Not ValueIsFilled(Object.AllotmentType) Then
			If Object.DoWriteOff Then
				Object.AllotmentType = Enums.AllotmentTypes.Definite;
				Object.TreatAsTentativeBooking = False;
			ElsIf Object.TreatAsTentativeBooking Then
				Object.AllotmentType = Enums.AllotmentTypes.Tentative;
				Object.DoWriteOff = False;
			Else
				Object.AllotmentType = Enums.AllotmentTypes.DoNotChangeAvailability;
			EndIf;
		EndIf;				
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManageAllotments") And Not cmCheckUserPermissions("HavePermissionToManageBusinessBlocks") Then
		ThisForm.ReadOnly = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AllotmentTypeOnChange(pItem)
	AllotmentTypeOnChangeAtServer();
EndProcedure // AllotmentTypeOnChange

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure AllotmentTypeOnChangeAtServer()
	If Not ValueIsFilled(Object.AllotmentType) Then
		Object.AllotmentType = Enums.AllotmentTypes.DoNotChangeAvailability;
	EndIf;
	If Object.AllotmentType = Enums.AllotmentTypes.Definite Then
		Object.DoWriteOff = True;
		Object.TreatAsTentativeBooking = False;
	ElsIf Object.AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed Then
		Object.DoWriteOff = True;
		Object.TreatAsTentativeBooking = False;
	ElsIf Object.AllotmentType = Enums.AllotmentTypes.Tentative Then
		Object.DoWriteOff = False;
		Object.TreatAsTentativeBooking = True;
	Else
		Object.DoWriteOff = False;
		Object.TreatAsTentativeBooking = False;
	EndIf;
EndProcedure // AllotmentTypeOnChangeAtServer

#EndRegion