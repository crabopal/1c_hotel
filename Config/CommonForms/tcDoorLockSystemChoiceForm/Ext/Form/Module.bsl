#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("DoorLockSystemsArray") And TypeOf(Parameters.DoorLockSystemsArray) = Type("Array") Then
		For Each vDoorLockSystem In Parameters.DoorLockSystemsArray Do
			vRow = DoorLockSystemTable.Add();
			vRow.DoorLockSystem = vDoorLockSystem;
		EndDo;
	EndIf;
	If Parameters.Property("ParentDoc") Then
		ParentDoc = Parameters.ParentDoc;
	EndIf;
	OneGuestMode = False;
	If Parameters.Property("ParametersOneGuestMode") And 
	   TypeOf(Parameters.ParametersOneGuestMode) = Type("Boolean") And 
	   Parameters.ParametersOneGuestMode Then
		OneGuestMode = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenIssueKeyCardsForm(pRowID)
	If pRowID <> Undefined Then
		vRowData = DoorLockSystemTable.FindByID(pRowID);
		If vRowData <> Undefined And ValueIsFilled(ParentDoc) Then
			vParametersKeyCard = tcOnServer.cmFillParametersKeyCard(ParentDoc);
			vParametersKeyCard.Insert("DoorLockSystem", vRowData.DoorLockSystem);
			vParams = New Structure();
			vParams.Insert("ParametersKeyCard", vParametersKeyCard);
			vParams.Insert("ParametersOneGuestMode", OneGuestMode);
			OpenForm("CommonForm.tcIssueKeyCard", vParams, ThisObject.FormOwner, tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation"), , , , FormWindowOpeningMode.LockOwnerWindow);
			ThisObject.Close();
		EndIf;
	EndIf;
EndProcedure // OpenIssueKeyCardsForm

// --------------------------------------------------------------------------------
&AtClient
Procedure DoorLockSystemSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	OpenIssueKeyCardsForm(pSelectedRow);
EndProcedure // DoorLockSystemSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure DoorLockSystemValueChoice(pItem, pSelectedRow, pStandardProcessing)
	pStandardProcessing = False;
	OpenIssueKeyCardsForm(pSelectedRow);
EndProcedure // DoorLockSystemValueChoice

#EndRegion

