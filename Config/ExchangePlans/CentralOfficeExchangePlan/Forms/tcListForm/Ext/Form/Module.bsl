#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "tcWriteExchangePlanNodeChanges.Сompleted" Or pEventName = "tcReadExchangePlanNodeChanges.Сompleted" Then
		Items.List.Refresh();	
	EndIf;		
EndProcedure // NotificationProcessing

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ListOnActivateRow(pItem)
	vCurNode = Items.List.CurrentRow;
	If vCurNode <> Undefined Then
		vThisNode = ExchangePlansProcessing.GetThisNode(vCurNode);
		If vThisNode = vCurNode Then
			Items.FormActionWriteChanges.Enabled = False;
			Items.FormActionReadChanges.Enabled = False;
		Else
			Items.FormActionWriteChanges.Enabled = True;
			Items.FormActionReadChanges.Enabled = True;
		EndIf;
	Else
		Items.FormActionWriteChanges.Enabled = False;
		Items.FormActionReadChanges.Enabled = False;
	EndIf;
EndProcedure // ListOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not ExchangePlansProcessing.CheckExclusiveMode() Then
		ShowMessageBox(, NStr("ru='Первоначальное создание узла плана обмена должно выполняться в монопольном режиме!'; 
			                  |de='Führen Programm im exklusiven Modus zum Austausch Planknoten erstellen!'; 
			                  |en='Run program in the exclusive mode to create exchange plan node!'"));
		pCancel = True;	
	EndIf;
EndProcedure // ListBeforeAddRow

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionWriteChanges(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow <> Undefined Then
		OpenForm("CommonForm.tcWriteExchangePlanNodeChanges", New Structure("SelNode", vCurRow), ThisForm, UUID,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // ActionWriteChanges

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionReadChanges(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow <> Undefined Then
		OpenForm("CommonForm.tcReadExchangePlanNodeChanges", New Structure("SelNode", vCurRow), ThisForm, UUID,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // ActionReadChanges

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionResetMaster(pCommand)
	ExchangePlansProcessing.SetMaster();
	Items.List.Refresh();
EndProcedure // ActionResetMaster

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionRecordChanges(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow <> Undefined And vCurRow <> ExchangePlansProcessing.GetThisNode(vCurRow) Then
		ExchangePlansProcessing.SetAllRecordChangesByFilter(vCurRow);
		Items.List.Refresh();
	EndIf;
EndProcedure // ActionRecordChanges

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionClearNodeChanges(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow <> Undefined And vCurRow <> ExchangePlansProcessing.GetThisNode(vCurRow) Then
		ExchangePlansProcessing.ClearNodeChanges(vCurRow);
		Items.List.Refresh();
	EndIf;
EndProcedure // ActionClearNodeChanges

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionSetMaster(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow <> Undefined And vCurRow <> ExchangePlansProcessing.GetThisNode(vCurRow) Then
		ExchangePlansProcessing.SetMaster(vCurRow);
		Items.List.Refresh();
	EndIf;
EndProcedure // ActionSetMaster

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteIntegrationServiceMessageFromReceiverNode(pCommand)
	vCurData = Items.List.CurrentData; 
	If vCurData <> Undefined Then
		DeleteIntegrationServiceMessageFromReceiverNodeAtServer(vCurData);
	EndIf;
EndProcedure // DeleteIntegrationServiceMessageFromReceiverNode

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteIntegrationServiceMessageFromSenderNode(pCommand)
	vCurData = Items.List.CurrentData; 
	If vCurData <> Undefined Then
		DeleteIntegrationServiceMessageFromSenderNodeAtServer(vCurData);
	EndIf;
EndProcedure // DeleteIntegrationServiceMessageFromSenderNode

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowIntegrationServiceMessage(pCommand)
	OpenForm("CommonForm.tcIntegrationServiceMessageList", New Structure("IntegrationServiceName", "DataExchangeInterfaces"), ThisForm, UUID);
EndProcedure // ShowIntegrationServiceMessage

#EndRegion 

#Region Private

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DeleteIntegrationServiceMessageFromSenderNodeAtServer(pNode)
	IntegrationServices.DataExchangeInterfaces.SenderNode.DeleteMessages(New Structure("SenderCode", TrimAll(pNode.Code)));
EndProcedure // DeleteIntegrationServiceMessageFromSenderNodeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DeleteIntegrationServiceMessageFromReceiverNodeAtServer(pNode)
	IntegrationServices.DataExchangeInterfaces.ReceiverNode.DeleteMessages(New Structure("ReceiverCode", TrimAll(pNode.Code)));
EndProcedure // DeleteIntegrationServiceMessageFromReceiverNodeAtServer

#EndRegion