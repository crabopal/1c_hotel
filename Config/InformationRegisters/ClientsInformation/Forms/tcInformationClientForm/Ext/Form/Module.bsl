
#Region FormEventHandlers

//-----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Client = Parameters.Client;
	ClientInformationTree.Parameters.SetParameterValue("qClient", Client);
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "ClientInformationHasChanged" And pParameter = Client Then
		Items.ClientInformationTree.Refresh();
	EndIf;
EndProcedure

#EndRegion

#Region Private

//-----------------------------------------------------------------------------
&AtClient
Procedure ClientInformationTreeSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If pSelectedRow <> Undefined And ValueIsFilled(Client) Then
		vRowData = Items.ClientInformationTree.RowData(pSelectedRow);
		If vRowData <> Undefined Then
			vInformationType = vRowData.Ref;
			If ValueIsFilled(vInformationType) And Not GetIsFolder(vInformationType) Then
				vCurrentDate = CurrentDate();
				// Create record if necessary
				CheckRecordExists(vCurrentDate, Client, vInformationType, vRowData.Remarks, vRowData.RemarksAuthor, vRowData.ActionTaken, vRowData.ActionAuthor, vRowData.ActionDate, vRowData.Hotel);
				// Open record form
				vArray = New Array();
				vArray.Add(New Structure("Period, Client, InformationType", vCurrentDate, Client, vInformationType));
				vRcdKey = New("InformationRegisterRecordKey.ClientsInformation", vArray);
				OpenForm("InformationRegister.ClientsInformation.RecordForm", New Structure("Key", vRcdKey), ThisObject);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

//-----------------------------------------------------------------------------
&AtServerNoContext
Function GetIsFolder(pRef)
	Return pRef.IsFolder;
EndFunction // GetIsFolder

//-----------------------------------------------------------------------------
&AtServerNoContext
Procedure CheckRecordExists(pPeriod, pClient, pInformationType, pRemarks, pRemarksAuthor, pActionTaken, pActionAuthor, pActionDate, pHotel)
	vRcdMgr = InformationRegisters.ClientsInformation.CreateRecordManager();
	vRcdMgr.Period = pPeriod;
	vRcdMgr.Client = pClient;
	vRcdMgr.InformationType = pInformationType;
	vRcdMgr.Read();
	If Not vRcdMgr.Selected() Then
		vRcdMgr.Period = pPeriod;
		vRcdMgr.Client = pClient;
		vRcdMgr.InformationType = pInformationType;
		vRcdMgr.Remarks = pRemarks;
		vRcdMgr.RemarksAuthor = pRemarksAuthor;
		vRcdMgr.ActionTaken = pActionTaken;
		If Not IsBlankString(pActionTaken) Then
			vRcdMgr.ActionAuthor = pActionAuthor;
			vRcdMgr.ActionDate = pActionDate;
		EndIf;
		vRcdMgr.Hotel = pHotel;
		vRcdMgr.Write();
	EndIf;
EndProcedure // CheckRecordExists

#EndRegion
