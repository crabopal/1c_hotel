// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not IsInRole("RightsToChooseHotel") And ValueIsFilled(SessionParameters.CurrentHotel) Then
		If Not ValueIsFilled(Record.Hotel) Then
			Record.Hotel = SessionParameters.CurrentHotel;
		EndIf;
		Items.Hotel.ReadOnly = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ThisObject.ReadOnly = True;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypeStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	If ValueIsFilled(Record.AccommodationTemplate) Then
		pStandardProcessing = False;
		pChoiceData = GetTemplateAccommodationTypesList(Record.AccommodationTemplate);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetTemplateAccommodationTypesList(pAccommodationTemplate)
	vList = New ValueList();
	If ValueIsFilled(pAccommodationTemplate) Then
		For Each vAccTypesRow In pAccommodationTemplate.AccommodationTypes Do
			If vList.FindByValue(vAccTypesRow.AccommodationType) = Undefined Then
				vList.Add(vAccTypesRow.AccommodationType);
			EndIf;
		EndDo;
	EndIf;
	Return vList;
EndFunction // GetTemplateAccommodationTypesList
