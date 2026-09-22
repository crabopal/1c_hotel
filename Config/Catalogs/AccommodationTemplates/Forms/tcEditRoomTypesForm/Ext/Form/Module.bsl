
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Hotel = SessionParameters.CurrentHotel;
	If Parameters.Property("SelectedTemplates") And Parameters.SelectedTemplates.Count() > 0 Then
		For Each vItem In Parameters.SelectedTemplates Do
			vRow = AccommodationTemplates.Add();
			vRow.AccommodationTemplate = vItem.Value;
		EndDo;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If ValueIsFilled(pSelectedValue) Then
		If TypeOf(pSelectedValue) = Type("CatalogRef.RoomTypes") Then
			If RoomTypes.FindRows(New Structure("RoomType", pSelectedValue)).Count() = 0 Then
				vRow = RoomTypes.Add();
				vRow.RoomType = pSelectedValue;
			EndIf;
		ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.AccommodationTemplates") Then
			If AccommodationTemplates.FindRows(New Structure("AccommodationTemplate", pSelectedValue)).Count() = 0 Then
				vRow = AccommodationTemplates.Add();
				vRow.AccommodationTemplate = pSelectedValue;
			EndIf;
		ElsIf TypeOf(pSelectedValue) = Type("Array") Then
			For Each vRef In pSelectedValue Do
				If TypeOf(vRef) = Type("CatalogRef.RoomTypes") Then
					If RoomTypes.FindRows(New Structure("RoomType", vRef)).Count() = 0 Then
						vRow = RoomTypes.Add();
						vRow.RoomType = vRef;
					EndIf;
				ElsIf TypeOf(vRef) = Type("CatalogRef.AccommodationTemplates") Then 
					If AccommodationTemplates.FindRows(New Structure("AccommodationTemplate", vRef)).Count() = 0 Then
						vRow = AccommodationTemplates.Add();
						vRow.AccommodationTemplate = vRef;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // ChoiceProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	If Not CheckHotelViewAccess() Then
		pStandardProcessing = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ChooseTemplatesAction(pCommand)
	vParams = New Structure("MultipleChoice", True);
	OpenForm("Catalog.AccommodationTemplates.ChoiceForm", vParams, ThisObject);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FormExecute(pCommand)
	vErrorsArray = FormExecuteAtServer();
	For Each vError In vErrorsArray Do
		tcCommonFunctionOnClientServer.TextMessage(vError);
	EndDo;
	ShowMessageBox(, NStr("en='Completed!'; ru='Завершено!'; de='Beendet!'"));
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ChooseRoomTypesAction(pCommand)
	vParams = New Structure("Hotel, MultipleChoice", Hotel, True);
	OpenForm("Catalog.RoomTypes.Form.tcListForm", vParams, ThisObject);
EndProcedure // ChooseRoomTypesAction

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServerNoContext
Function CheckHotelViewAccess()
	Return AccessRight("View", Metadata.Catalogs.Hotels);
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Function FormExecuteAtServer()
	vErrorsArray = New Array;
	For Each vRow In AccommodationTemplates Do
		If ValueIsFilled(vRow.AccommodationTemplate) Then
			Try
				vObj = vRow.AccommodationTemplate.GetObject();
				If ActionType = 1 Then
					vObj.RoomTypes.Clear();
				EndIf;
				For Each vRTRow In RoomTypes Do
					If ValueIsFilled(vRTRow.RoomType) And Not vRTRow.RoomType.IsFolder Then
						If vObj.RoomTypes.Find(vRTRow.RoomType, "RoomType") = Undefined Then
							vTemplateRTRow = vObj.RoomTypes.Add();
							FillPropertyValues(vTemplateRTRow, vRTRow);
						EndIf;
					EndIf;
				EndDo;
				If vObj.Modified() Then
					vObj.Write();
				EndIf;
			Except
				vError = cmGetRootErrorDescription(ErrorInfo());
				vErrorsArray.Add(vError);
			EndTry;
		EndIf;
	EndDo;
	Return vErrorsArray;
EndFunction

#EndRegion

