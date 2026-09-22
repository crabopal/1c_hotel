
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Check Hotel attribute
	If ValueIsFilled(Object.Ref) Then
		For Each vRTRow In Object.RoomTypes Do
			If ValueIsFilled(vRTRow.RoomType) And Not ValueIsFilled(vRTRow.Hotel) Then
				vRTRow.Hotel = vRTRow.RoomType.Owner;
			EndIf;
			If ValueIsFilled(vRTRow.RoomClass) And Not ValueIsFilled(vRTRow.Hotel) Then
				vRTRow.Hotel = vRTRow.RoomClass.Owner;
			EndIf;
		EndDo;
	EndIf; 
	If Not IsInRole("Administrator") Then
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then 
			vMsg = NStr("en = 'You do not have rights (094) for manage accommodation templates!'; 
						|de = 'Sie haben keine Rechte (094) zum Verwalten von Unterkunftsvorlagen!'; 
						|ru = 'Нет прав (094) на управление шаблонами размещения!'");
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
			ReadOnly = True;
		EndIf;	  
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesRoomClassOnChange(pItem)
	vCurRow = Items.RoomTypes.CurrentData;
	If ValueIsFilled(vCurRow.RoomClass) Then
		vCurRow.RoomType = Undefined;
		vCurRow.Hotel = tcOnServer.cmGetAttributeByRef(vCurRow.RoomClass, "Owner");
	EndIf;
EndProcedure // RoomTypesRoomClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesRoomTypeOnChange(pItem)
	vCurRow = Items.RoomTypes.CurrentData;
	If ValueIsFilled(vCurRow.RoomType) Then
		vCurRow.RoomClass = Undefined;
		vCurRow.Hotel = tcOnServer.cmGetAttributeByRef(vCurRow.RoomType, "Owner");
	EndIf;
EndProcedure // RoomTypesRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesOnStartEdit(pItem, pNewRow, pClone)
	vCurRow = Items.RoomTypes.CurrentData;
	If Not ValueIsFilled(vCurRow.Hotel) Then
		vCurRow.Hotel = tcOnServer.cmGetSessionParametersAttribute("CurrentHotel");
	EndIf;
EndProcedure // RoomTypesOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations), pItem);
EndProcedure // DescriptionTranslationsOpening

#EndRegion

#Region FormTableItemsEventHandlersRoomTypes

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomTypesAtServer(pValuesArr)
	For Each vElem In pValuesArr Do
		If vElem.IsFolder Then
			vFoldersItems = cmGetAllRoomTypes(vElem.Owner, vElem.Ref);
			If vFoldersItems.Count() > 0 Then
				For Each vFolderRow In vFoldersItems Do
					vRow = Object.RoomTypes.Add();
					If TypeOf(vElem) = Type("CatalogRef.RoomTypes") Then	
						vRow.RoomType = vFolderRow.RoomType;
						vRow.Hotel = vFolderRow.RoomType.Owner;
					Else
						vRow.RoomClass = vFolderRow.RoomClass;
						vRow.Hotel = vFolderRow.RoomClass.Owner;
					EndIf;
				EndDo;
			EndIf;
		Else
			vRow = Object.RoomTypes.Add();
			If TypeOf(vElem) = Type("CatalogRef.RoomTypes") Then	
				vRow.RoomType = vElem;
			Else
				vRow.RoomClass = vElem;
			EndIf;
			vRow.Hotel = vElem.Owner;
		EndIf;
	EndDo;
EndProcedure // FillRoomTypesAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandFillRoomTypeClasses(pCommand)
	vFillRoomTypes = False;
	ChooseHotel(vFillRoomTypes);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandFillRoomTypes(pCommand)
	vFillRoomTypes = True;
	ChooseHotel(vFillRoomTypes);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure ChooseHotel(pFillRoomTypes) Export 	
	If ValueIsFilled(Object.Hotel) Then
		vFilter = New Structure("Owner", Object.Hotel);
		vFormParams = New Structure("Filter, MultipleChoice, CloseOnChoice, ChoiceFoldersAndItems, ChoiceMode", vFilter, True, False, FoldersAndItemsUse.FoldersAndItems, True);
		OpenForm(?(pFillRoomTypes, "Catalog.RoomTypes.ChoiceForm", "Catalog.RoomTypeClasses.ChoiceForm"), vFormParams, ThisObject);
	Else
		vFormParams = New Structure("MultipleChoice, ChoiceMode", True, True); 
		OpenForm("Catalog.Hotels.ChoiceForm", vFormParams, ThisObject, , , , New NotifyDescription("HotelAnswer", ThisObject, pFillRoomTypes));
	EndIf;
EndProcedure // ChooseHotel

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelAnswer(pHotelsArr, pFillRoomTypes) Export 	
	If ValueIsFilled(pHotelsArr) Then
		vFilter = New Structure("Owner", pHotelsArr);
	Else
		Return;
	Endif;
	vFormParams = New Structure("Filter, MultipleChoice, CloseOnChoice, ChoiceFoldersAndItems, ChoiceMode", vFilter, True, False, FoldersAndItemsUse.FoldersAndItems, True);
	If pFillRoomTypes Then 
		OpenForm("Catalog.RoomTypes.ChoiceForm", vFormParams, ThisObject);
	Else
		OpenForm("Catalog.RoomTypeClasses.ChoiceForm", vFormParams, ThisObject);
	EndIf;
EndProcedure // HotelAnswer

// -----------------------------------------------------------------------------
&AtServer
Procedure ChoiceProcessingAtServer(pValuesArr)
	If TypeOf(pValuesArr) = Type("Array") And pValuesArr.Count() > 0 And Not TypeOf(pValuesArr[0]) = Type("CatalogRef.Hotels") Then
		FillRoomTypesAtServer(pValuesArr);
	Endif;
EndProcedure // ChoiceProcessingAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue)
	ChoiceProcessingAtServer(pSelectedValue);
EndProcedure // ChoiceProcessing

#EndRegion 
