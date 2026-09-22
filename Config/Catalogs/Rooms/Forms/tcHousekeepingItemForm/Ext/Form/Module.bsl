
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Set parameters
	RoomBlocks.Parameters.SetParameterValue("qRoom", Object.Ref);
	// Check user permission to change room statuses
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToChangeRoomStatuses") Then
		Items.RoomStatus.ReadOnly = True;
	EndIf;
	// Check user rights to edit room blocks
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetRoomBlocks") Then
		Items.RoomBlocksTable.ReadOnly = True;
	EndIf;
	// Check user permissions to stop sale room
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToStopSaleRooms") Then
		Items.StopSalePeriods.ReadOnly = True;
	EndIf;
	// Room tasks command caption
	SetRoomTasksCommandCaption();
	// Fill room status choice list
	FillRoomStatusChoiceList();
	// Room blocks filter
	RoomBlocks.Parameters.SetParameterValue("qShowAllBlocks", ShowAllRoomBlocks);
	// Fill beds setup list
	FillBedsSetupList();
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Save current room status and beds setup
	SavRoomStatus = Object.RoomStatus;
	SavBedsSetup = Object.BedsSetup;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Document.SetRoomBlock.Write" Then
		If ValueIsFilled(pParameter) And tcOnServer.cmGetAttributeByRef(pParameter, "Room") = Object.Ref Then
			Read();
			Modified = False;
			// Set parameters
			RoomBlocks.Parameters.SetParameterValue("qRoom", Object.Ref);
			// Has room blocks flag
			RoomBlocksTableOnChange(Items.RoomBlocks);
		EndIf;
	ElsIf pEventName = "RoomProperties.Changed" Then
		If ValueIsFilled(pParameter) And pParameter = Object.Ref Then
			Read();
			Modified = False;
		EndIf;
	ElsIf pEventName = "RoomProperties.Deleted" Then
		Read();
		Modified = False;
	EndIf;
	// Room tasks command caption
	SetRoomTasksCommandCaption();
EndProcedure // NotificationProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Catalog.Rooms.Write", Object.Ref, ThisObject);
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If Not pCurrentObject.DeletionMark Then
		If SavRoomStatus <> pCurrentObject.RoomStatus Then
			pCurrentObject.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, "");
			SavRoomStatus = pCurrentObject.RoomStatus;
		EndIf;
		If SavBedsSetup <> pCurrentObject.BedsSetup Then
			pCurrentObject.pmWriteToRoomChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			SavBedsSetup = pCurrentObject.BedsSetup;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	vTasksStructure = GetTasksStructure();
	
	For Each vTasks In vTasksStructure Do
		If	vTasks.Value.PopUp Then
			ShowMessageBox(,vTasks.Value.Remarks,,NStr("en = 'Task'; de = 'Aufgabe'; ru = 'Задача'"));
		EndIf;
	EndDo;
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Not ValueIsFilled(Object.RoomStatus) Then  
		vMsg = NStr("en = 'Room status cannot be empty'; de = 'Der Zimmerstatus darf nicht leer sein'; ru = 'Статус номера не может быть пустым'");
		tcCommonFunctionOnClientServer.UserMessage(vMsg, , "Object.RoomStatus");
		pCancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure StopSalePeriodsOnEditEnd(pItem, pNewRow, pCancelEdit)
	vCurRow = Items.StopSalePeriods.CurrentData;
	If vCurRow <> Undefined Then
		If pNewRow Then
			vCurRow.CreateDate = CurrentDate();
			vCurRow.Author = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		EndIf;
	EndIf;
	StopSalePeriodsOnEditEndAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure StopSalePeriodsAfterDeleteRow(pItem)
	StopSalePeriodsAfterDeleteRowAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure StopSalePeriodsOnStartEdit(pItem, NewRow, Clone)
	If NewRow Then
		Items.StopSalePeriods.CurrentData.StopSale = True;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomBlocksTableBeforeAddRow(pItem, Cancel, Clone, Parent, Folder, Parameter)
	OpenForm("Document.SetRoomBlock.Form.tcDocumentForm", New Structure("Room", Object.Ref), ThisObject, Object.Ref);
	Cancel = True;
EndProcedure // RoomBlocksTableBeforeAddRow

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomBlocksTableOnChange(pItem)
	If Not CheckActiveRoomBlocks(Object.Ref) Then
		If Object.HasRoomBlocks Then
			Object.HasRoomBlocks = False;
			Modified = True;
		EndIf;
	Else
		If Not Object.HasRoomBlocks Then
			Object.HasRoomBlocks = True;
			Modified = True;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomStatusOnChange(pItem)
	// Fill room status choice list
	FillRoomStatusChoiceList();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowAllRoomBlocksOnChange(pItem)
	RoomBlocks.Parameters.SetParameterValue("qShowAllBlocks", ShowAllRoomBlocks);
EndProcedure //ShowAllRoomBlocksOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure BedsSetupOnChange(pItem)
	BedsSetupOnChangeAtServer();
EndProcedure // BedsSetupOnChange

#EndRegion

#Region FormCommandsEventHandlers

 // --------------------------------------------------------------------------------
&AtClient
Procedure CreateRoomTask(Command)
	If ValueIsFilled(Object.Ref) Then
		stParam = New Structure("SetParamObject, Type", Object.Ref, PredefinedValue("Enum.MessageTypes.Task"));
		OpenForm("Document.Message.Form.tcDocumentForm", stParam);
	EndIf;
EndProcedure

&AtClient
Procedure OpenFloorPlans(pCommand)
	OpenForm("CommonForm.tcShowFloorPlans", New Structure("SelRoom", Object.Ref));
EndProcedure // OpenFloorPlans

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowRoomTasks(pCommand)
	If ValueIsFilled(Object.Ref) Then
		stParam = New Structure("SetParamObject", Object.Ref);
		OpenForm("DataProcessor.Messages.Form.tcForm", stParam);
		Notify("DataProcessor.Messages.Form.Open", stParam);
	EndIf;
EndProcedure // ShowRoomTasks

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillRoomStatusChoiceList()
	vRoomStatusesTable = cmGetAllowedRoomStatuses(, Object.RoomStatus);
	Items.RoomStatus.ChoiceList.Clear();
	For Each vRow In vRoomStatusesTable Do
		Items.RoomStatus.ChoiceList.Add(vRow.RoomStatus, ?(ValueIsFilled(vRow.RoomStatus), TrimAll(vRow.RoomStatus), NStr("en='<Empty status>';ru='<Пустой статус>';de='<Leerer Status>'")), , cmGetRoomStatusIcon(vRow.RoomStatus));
	EndDo;
	If Items.RoomStatus.ChoiceList.FindByValue(Object.RoomStatus) = Undefined Then
		Items.RoomStatus.ChoiceList.Insert(0, Object.RoomStatus, ?(ValueIsFilled(Object.RoomStatus), TrimAll(Object.RoomStatus), NStr("en='<Empty status>';ru='<Пустой статус>';de='<Leerer Status>'")), , cmGetRoomStatusIcon(Object.RoomStatus));
	EndIf;
EndProcedure // FillRoomStatusChoiceList

// --------------------------------------------------------------------------------
&AtServer
Procedure SetRoomTasksCommandCaption()
	Items.FormShowRoomTasks.Title = NStr("en='Room tasks'; ru='Задачи номера'; de='Zimmeraufgaben'");
	Items.FormShowRoomTasks.BackColor = New Color;
	If ValueIsFilled(Object.Ref) Then
		vTasksCount = cmGetNumberOfMessagesForObject(Object.Ref);
		If vTasksCount > 0 Then
			Items.FormShowRoomTasks.Title = Items.FormShowRoomTasks.Title + " (" + Format(vTasksCount, "NFD=0; NG=") + ")";
			Items.FormShowRoomTasks.BackColor = WebColors.Yellow;
		EndIf;
	EndIf;
EndProcedure // SetRoomTasksCommandCaption

// --------------------------------------------------------------------------------
&AtServer	
Procedure StopSalePeriodsOnEditEndAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmSetStopSaleFlag();
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure StopSalePeriodsAfterDeleteRowAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmSetStopSaleFlag();
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServerNoContext
Function CheckActiveRoomBlocks(pRoom) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	SetRoomBlocks.Ref AS SetRoomBlock
	|FROM
	|	Document.SetRoomBlock AS SetRoomBlocks
	|WHERE
	|	SetRoomBlocks.Posted
	|	AND SetRoomBlocks.Room = &qRoom
	|	AND SetRoomBlocks.DateFrom <= &qCurrentDate
	|	AND (SetRoomBlocks.DateTo > &qCurrentDate
	|			OR SetRoomBlocks.DateTo = &qEmptyDate)
	|
	|ORDER BY
	|	SetRoomBlocks.DateFrom";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vQry.SetParameter("qEmptyDate", '00010101');
	vBlocks = vQry.Execute().Unload();
	If vBlocks.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckActiveRoomBlocks

// --------------------------------------------------------------------------------
&AtServer
Function  GetTasksStructure()
	vTasksStructure = New Structure();
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref);
		vNumber = 0;
		For Each vTasksRow In vTasks Do
			vTasksStructure.Insert(TrimAll("Tasks" + vNumber), New Structure("PopUp, Remarks", vTasksRow.PopUp, vTasksRow.Remarks));
			vNumber = vNumber + 1;
		EndDo;
	EndIf;
	Return vTasksStructure;
EndFunction // GetTasksStructure

// --------------------------------------------------------------------------------
&AtServer
Procedure FillBedsSetupList()
	vUseBedsSetup = False;
	If ValueIsFilled(Object.Owner) Then
		vUseBedsSetup = Object.Owner.BedsSetups;
	EndIf;
	Items.BedsSetup.Visible = vUseBedsSetup;
	Items.BedsSetup1.Visible = vUseBedsSetup;
	Items.BedsSetup.ChoiceList.Clear();
	Items.BedsSetup1.ChoiceList.Clear();
	If vUseBedsSetup Then
		If ValueIsFilled(Object.RoomType) Then
			If Object.RoomType.AllowedBedsSetups.Count() > 0 Then
				For Each vRow In Object.RoomType.AllowedBedsSetups Do
					If ValueIsFilled(vRow.BedsSetup) Then
						If Items.BedsSetup.ChoiceList.FindByValue(vRow.BedsSetup.Code) = Undefined Then
							Items.BedsSetup.ChoiceList.Add(vRow.BedsSetup.Code);
						EndIf;
					Else
						If Items.BedsSetup.ChoiceList.FindByValue("") = Undefined Then
							Items.BedsSetup.ChoiceList.Insert(0, "", NStr("en='<Empty>'; ru='<Пустая>'; de='<Leer>'"));
						EndIf;
					EndIf;
					If Items.BedsSetup1.ChoiceList.FindByValue(vRow.BedsSetup) = Undefined Then
						If ValueIsFilled(vRow.BedsSetup) Then
							Items.BedsSetup1.ChoiceList.Add(vRow.BedsSetup);
						Else
							Items.BedsSetup1.ChoiceList.Insert(0, vRow.BedsSetup, NStr("en='<Empty>'; ru='<Пустая>'; de='<Leer>'"));
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		BedsSetup = ?(ValueIsFilled(Object.BedsSetup), Object.BedsSetup.Code, "");
		If Items.BedsSetup.ChoiceList.FindByValue(BedsSetup) = Undefined Then
			Items.BedsSetup.ChoiceList.Insert(0, BedsSetup, ?(IsBlankString(BedsSetup), NStr("en='<Empty>'; ru='<Пустая>'; de='<Leer>'"), BedsSetup));
		EndIf;
		If Items.BedsSetup1.ChoiceList.FindByValue(Object.BedsSetup) = Undefined Then
			Items.BedsSetup1.ChoiceList.Insert(0, Object.BedsSetup, ?(Not ValueIsFilled(Object.BedsSetup), NStr("en='<Empty>'; ru='<Пустая>'; de='<Leer>'"), Object.BedsSetup));
		EndIf;
		Items.BedsSetup.ReadOnly = Object.BedsSetupIsFixed;
		Items.BedsSetup1.ReadOnly = Object.BedsSetupIsFixed;
		If Items.BedsSetup1.ChoiceList.Count() > 2 Then
			Items.BedsSetup.Visible = False;
			Items.BedsSetup1.Visible = True;
		Else
			Items.BedsSetup.Visible = True;
			Items.BedsSetup1.Visible = False;
		EndIf;
	EndIf;
EndProcedure // FillBedsSetupList

// --------------------------------------------------------------------------------
&AtServer
Procedure BedsSetupOnChangeAtServer()
	If Not IsBlankString(BedsSetup) Then
		Object.BedsSetup = Catalogs.BedsSetups.FindByCode(BedsSetup, False);
	Else
		Object.BedsSetup = Catalogs.BedsSetups.EmptyRef();
	EndIf;
EndProcedure // BedsSetupOnChangeAtServer

#EndRegion
