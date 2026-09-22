
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Check attributes and rights
	If Not IsInRole("Administrator") Then
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then 
			vMsg = NStr("en='You do not have rights (094) for manage accommodation templates!'; 
			            |de='Sie haben keine Rechte (094) zum Verwalten von Unterkunftsvorlagen!'; 
			            |ru='Нет прав (094) на управление шаблонами размещений!'");
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
			pCancel = True;
			Return;
		EndIf;	  
	EndIf;
	If AccommodationTypes.Count() = 0 And Ref <> Catalogs.AccommodationTemplates.NoTemplate Then
		vMsg = NStr("en='Accommodation types list should be filled!';
		            |ru='Не заполнен список видов размещения!';
					|de='Die Liste der Unterbringungstypen ist nicht ausgefüllt!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
		pCancel = True;
		Return;
	EndIf; 
 
	// Delete empty rows from room types
	vInd = 0;
	While vInd < RoomTypes.Count() Do
		vRRRow = RoomTypes.Get(vInd);
		If Not ValueIsFilled(vRRRow.RoomType) And Not ValueIsFilled(vRRRow.RoomClass) Then
			RoomTypes.Delete(vInd);
		Else
			vInd = vInd + 1;
		EndIf;
	EndDo;
	
	// Delete duplicate rows from room types
	If RoomTypes.Count() > 0 Then
		vRoomTypes = RoomTypes.Unload();
		vRoomTypes.GroupBy("RoomClass, RoomType, Hotel", );
		If vRoomTypes.Count() <> RoomTypes.Count() Then
			RoomTypes.Load(vRoomTypes);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite   

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmGetTemplateDescription(pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(Description);
	Else
		If IsBlankString(DescriptionTranslations) Then
			vDescr = TrimAll(Description);
		Else
			vDescr = TrimAll(cmNStr(DescriptionTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetTemplateDescription

#EndRegion
