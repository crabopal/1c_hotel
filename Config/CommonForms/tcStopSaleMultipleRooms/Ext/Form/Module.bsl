
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToStopSaleRoomTypes") And IsRoomTypes Then
		Items.StopSalePeriods.Enabled = False;
	ElsIf Not cmCheckUserPermissions("HavePermissionToStopSaleRooms") And Not IsRoomTypes Then
		Items.StopSalePeriods.Enabled = False;
	Else
		Items.StopSalePeriods.Enabled = True;	
	EndIf;
	vListRef = Undefined;
	If Parameters.Property("SelListRef") Then
		vListRef = Parameters.SelListRef; 
		If vListRef.Count() > 0 Then
			vBeginRow = True;
			For Each vItem In vListRef Do
				If vItem.Value.DeletionMark Then
					Continue;
				EndIf;
				If vBeginRow Then
					If TypeOf(vItem.Value) = Type("CatalogRef.RoomTypes") Then
						IsRoomTypes = True;	
					Else
						IsRoomTypes = False;	
					EndIf;
					vBeginRow = False;
				EndIf;
				If vItem.Value.IsFolder Then
					vArrRefs = GetArrRefByFolder(vItem.Value, vListRef, IsRoomTypes);
					For Each vRef In vArrRefs Do
						If IsRoomTypes Then
							vNewRow = ListRoomTypesRef.Add();
							vNewRow.Ref = vRef;
							vNewRow.Hotel = vRef.Owner;
							vNewRow.ParentFolder = vRef.Parent;
							vNewRow.Description = vRef.Description;
						Else
							vNewRow = ListRoomsRef.Add();
							vNewRow.Ref = vRef;
							vNewRow.Hotel = vRef.Owner;
							vNewRow.ParentFolder = vRef.Parent;
							vNewRow.Description = vRef.Description;	
						EndIf;	
					EndDo;
					Continue;
				EndIf;
				If IsRoomTypes Then
					vNewRow = ListRoomTypesRef.Add();
					vNewRow.Ref = vItem.Value;
					vNewRow.Hotel = vItem.Value.Owner;
					vNewRow.ParentFolder = vItem.Value.Parent;
					vNewRow.Description = vItem.Value.Description;
				Else
					vNewRow = ListRoomsRef.Add();
					vNewRow.Ref = vItem.Value;
					vNewRow.Hotel = vItem.Value.Owner;
					vNewRow.ParentFolder = vItem.Value.Parent;
					vNewRow.Description = vItem.Value.Description;	
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If vListRef = Undefined Or vListRef.Count() = 0 Then
		Items.StopSalePeriods.Enabled = False;
		Items.ListRoomTypesRef.Visible = False;
		Items.ListRoomsRef.Visible = False;
		Items.FormActionExecute.Enabled = False;
	ElsIf IsRoomTypes Then
		Items.ListRoomTypesRef.Visible = True;
		Items.ListRoomsRef.Visible = False;
		Items.StopSalePeriodsStopInternetSale.Visible = True;
		Items.FormActionExecute.Enabled = True;
		ListRoomTypesRef.Sort("Description, ParentFolder");
	Else
		Items.ListRoomTypesRef.Visible = False;
		Items.ListRoomsRef.Visible = True;	
		Items.StopSalePeriodsStopInternetSale.Visible = False;
		Items.FormActionExecute.Enabled = True;
		ListRoomsRef.Sort("Description, ParentFolder");
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure StopSalePeriodsOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow Then
		pItem.CurrentData.StopSale = True;	
	EndIf;
EndProcedure // StopSalePeriodsOnStartEdit

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionExecute(pCommand)	
	If StopSalePeriods.Count() > 0 Then
		If ActionExecuteAtServer() Then
			Notify("tcStopSaleMultipleRooms.Execute");
			ShowMessageBox(New NotifyDescription("ShowMessageBoxCompleted", ThisForm, UUID), NStr("en = 'Completed'; de = 'Abgeschlossen'; ru = 'Завершено'"));	
		Else
			Notify("tcStopSaleMultipleRooms.Execute");
			ShowMessageBox(, NStr("en = 'An error occurred while recording stop sales'; de = 'Beim Aufzeichnen von Verkaufsstopps ist ein Fehler aufgetreten'; ru = 'Возникла ошибка при записи стоп-продаж'"));	
		EndIf;
	Else
		ShowMessageBox(, NStr("en = 'The list stop sale is empty'; de = 'Die Liste Stop Sale ist leer'; ru = 'Список стоп-продаж пуст'"));	
	EndIf;
EndProcedure // ActionExecute

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function ActionExecuteAtServer()
	If IsRoomTypes Then
		vListVT = ListRoomTypesRef;
	Else
		vListVT = ListRoomsRef;	
	EndIf;
	vArrErr = New Array();
	For Each vRow In vListVT Do
		Try
			vObj = vRow.Ref.GetObject();
			vStopSalePeriods = vObj.StopSalePeriods;
			For Each vStopSaleRow In StopSalePeriods Do
				vNewStopSalePeriod = vStopSalePeriods.Add();
				If IsRoomTypes Then
					vNewStopSalePeriod.StopInternetSale = vStopSaleRow.StopInternetSale;	
				EndIf;
				vNewStopSalePeriod.PeriodFrom = vStopSaleRow.PeriodFrom;
				vNewStopSalePeriod.PeriodTo = vStopSaleRow.PeriodTo;
				vNewStopSalePeriod.Remarks = vStopSaleRow.Remarks;
				vNewStopSalePeriod.StopSale = vStopSaleRow.StopSale;
				If Not IsRoomTypes Then
					vObj.pmSetStopSaleFlag();
				Else
					vObj.StopSale = CheckStopSaleFlag(vObj);	
				EndIf;
				vNewStopSalePeriod.CreateDate = CurrentSessionDate();
				vNewStopSalePeriod.Author = SessionParameters.CurrentUser;
			EndDo;
			vObj.Write();
		Except
			vErr = ErrorDescription();
			vArrErr.Add(vRow.GetID());
			WriteLogEvent("tcStopSaleMultipleRooms.Execute", EventLogLevel.Error,,, vErr);
			tcCommonFunctionOnClientServer.TextMessage(vErr);
		EndTry;
	EndDo;
	For Each vErr In vArrErr Do
		vListVT.Delete(vListVT.FindByID(vErr));	
	EndDo;
	If vArrErr.Count() > 0 Then
		Return False;	
	Else
		Return True;	
	EndIf;
EndFunction // ActionExecuteAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetArrRefByFolder(pFolderRef, pArrRef, pIsRoomTypes)
	If pIsRoomTypes Then
		vQueryText = 
		"SELECT
		|	RoomTypes.Ref AS Ref
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|	AND NOT RoomTypes.Ref IN (&qArrRef)
		|	AND RoomTypes.Parent = &qFolder";	
	Else
		vQueryText = 
		"SELECT
		|	Rooms.Ref AS Ref
		|FROM
		|	Catalog.Rooms AS Rooms
		|WHERE
		|	NOT Rooms.DeletionMark
		|	AND NOT Rooms.IsFolder
		|	AND NOT Rooms.Ref IN (&qArrRef)
		|	AND Rooms.Parent = &qFolder";		
	EndIf;
	vQuery = New Query();
	vQuery.Text = vQueryText;
	vQuery.SetParameter("qArrRef", pArrRef);
	vQuery.SetParameter("qFolder", pFolderRef);
	vResult = vQuery.Execute().Unload();
	Return vResult.UnloadColumn("Ref");
EndFunction // GetArrRefByFolder    

// --------------------------------------------------------------------------------
&AtServer
Function CheckStopSaleFlag(Val pObj)
	vStopSale = False;
	For Each vRow In pObj.StopSalePeriods Do
		If vRow.StopSale Or vRow.StopInternetSale Then
			If Not ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) Then
				vStopSale = True;
				Break;
			ElsIf Not ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) Then
				If vRow.PeriodTo > CurrentSessionDate() Then
					vStopSale = True;
					Break;
				EndIf;
			ElsIf ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) Then
				vStopSale = True;
				Break;
			ElsIf ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) Then
				If vRow.PeriodTo > CurrentSessionDate() Then
					vStopSale = True;
					Break;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	Return vStopSale;
EndFunction // RefreshDisplay

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowMessageBoxCompleted(pExtraParam) Export 
	Close();
EndProcedure // ShowMessageBoxCompleted

#EndRegion


