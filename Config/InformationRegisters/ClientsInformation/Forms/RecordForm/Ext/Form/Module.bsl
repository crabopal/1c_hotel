#Region FormEventHandlers
// ---------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill history dynamic list parameters
	History.Parameters.SetParameterValue("qClient", Record.Client);
	History.Parameters.SetParameterValue("qInformationType", Record.InformationType);
	History.Parameters.SetParameterValue("qPeriod", Record.Period);
	
	Record.Hotel = SessionParameters.CurrentHotel;
	
	FillAttributes();
EndProcedure // OnCreateAtServer

// ---------------------------------------------------------------------
&AtClient
Procedure OnClose()
	CheckIfSomethingHasChangedAtServer();
EndProcedure // OnClose

// ---------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If Not IsBlankString(pCurrentObject.Remarks) And Not ValueIsFilled(pCurrentObject.RemarksAuthor) Then
		pCurrentObject.RemarksAuthor = SessionParameters.CurrentUser;
		pCurrentObject.Period = CurrentSessionDate();
	EndIf;
	If Not IsBlankString(pCurrentObject.ActionTaken) And Not ValueIsFilled(pCurrentObject.ActionAuthor) Then
		pCurrentObject.ActionAuthor = SessionParameters.CurrentUser;
		pCurrentObject.ActionDate = CurrentSessionDate();
	EndIf;
	
	FillAttributes();
	
EndProcedure // BeforeWriteAtServer

// ---------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("ClientInformationHasChanged", Record.Client);
EndProcedure // AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// ---------------------------------------------------------------------
&AtClient
Procedure ActionTakenOnChange(pItem)
	Record.ActionDate = '00010101';
	Record.ActionAuthor = "";
EndProcedure // ActionTakenOnChange

// ---------------------------------------------------------------------
&AtClient
Procedure RemarksStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vArr = GetChoiceValues();
	vValueList = New ValueList;
	For Each vRow In vArr Do
		vValueList.Add(vRow);
	EndDo;
	vNotification = New NotifyDescription("AfterChoose", ThisObject);
	vValueList.ShowChooseItem(vNotification, "Выберите значение:");
EndProcedure // RemarksStartChoice

#EndRegion

#Region Private

// ---------------------------------------------------------------------
&AtServer
Procedure DeleteThisRecordAtServer()
	vRcdMgr = InformationRegisters.ClientsInformation.CreateRecordManager();
	vRcdMgr.Period = Record.Period;
	vRcdMgr.Client = Record.Client;
	vRcdMgr.InformationType = Record.InformationType;
	vRcdMgr.Room = Record.Room;
	vRcdMgr.CheckInDate = Record.CheckInDate;
	vRcdMgr.CheckOutDate = Record.CheckOutDate;
	
	vRcdMgr.Read();
	If vRcdMgr.Selected() Then
		vRcdMgr.Period = Record.Period;
		vRcdMgr.Client = Record.Client;
		vRcdMgr.InformationType = Record.InformationType;
		vRcdMgr.Room = Record.Room;
		vRcdMgr.CheckInDate = Record.CheckInDate;
		vRcdMgr.CheckOutDate = Record.CheckOutDate;
		vRcdMgr.Delete();
	EndIf;
EndProcedure // DeleteThisRecordAtServer

// ---------------------------------------------------------------------
&AtServer
Procedure CheckIfSomethingHasChangedAtServer()
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	ClientsInformation.Period,
	|	ClientsInformation.Client,
	|	ClientsInformation.InformationType,
	|	ClientsInformation.Hotel,
	|	ClientsInformation.Remarks,
	|	ClientsInformation.ActionTaken
	|FROM
	|	InformationRegister.ClientsInformation AS ClientsInformation
	|WHERE
	|	ClientsInformation.Client = &qClient
	|	AND ClientsInformation.InformationType = &qInformationType
	|	AND ClientsInformation.Period < &qPeriod
	|ORDER BY
	|	ClientsInformation.Period DESC";
	vQry.SetParameter("qPeriod", Record.Period);
	vQry.SetParameter("qClient", Record.Client);
	vQry.SetParameter("qInformationType", Record.InformationType);
	vRcd = vQry.Execute().Unload();
	If vRcd.Count() > 0 Then
		vRcdRow = vRcd.Get(0);
		If TrimAll(vRcdRow.Remarks) = TrimAll(Record.Remarks) And TrimAll(vRcdRow.ActionTaken) = TrimAll(Record.ActionTaken) Then
			DeleteThisRecordAtServer();
		ElsIf TrimAll(vRcdRow.Remarks) = TrimAll(Record.Remarks) And TrimAll(vRcdRow.ActionTaken) <> TrimAll(Record.ActionTaken) And IsBlankString(vRcdRow.ActionTaken) Then
			// Update previous record
			UpdatePreviousRecordAtServer(vRcdRow.Period);
			// Delete this one
			DeleteThisRecordAtServer();
		EndIf;
	EndIf;
EndProcedure // CheckIfSomethingHasChangedAtServer

// ---------------------------------------------------------------------
&AtServer
Procedure UpdatePreviousRecordAtServer(pPeriod)
	vRcdMgr = InformationRegisters.ClientsInformation.CreateRecordManager();
	vRcdMgr.Period = pPeriod;
	vRcdMgr.Client = Record.Client;
	vRcdMgr.InformationType = Record.InformationType;
	vRcdMgr.Room = Record.Room;
	vRcdMgr.CheckInDate = Record.CheckInDate;
	vRcdMgr.CheckOutDate = Record.CheckOutDate;
	vRcdMgr.Read();
	If vRcdMgr.Selected() Then
		vRcdMgr.Period = pPeriod;
		vRcdMgr.Client = Record.Client;
		vRcdMgr.InformationType = Record.InformationType;
		vRcdMgr.Room = Record.Room;
		vRcdMgr.CheckInDate = Record.CheckInDate;
		vRcdMgr.CheckOutDate = Record.CheckOutDate;
		vRcdMgr.ActionTaken = Record.ActionTaken;
		vRcdMgr.ActionAuthor = Record.ActionAuthor;
		vRcdMgr.ActionDate = Record.ActionDate;
		vRcdMgr.Hotel = Record.Hotel;
		vRcdMgr.Write();
	EndIf;
EndProcedure // UpdatePreviousRecordAtServer

&AtClient
Procedure AfterChoose(pChosenValue, pParams) Export 
	If pChosenValue <> Undefined Then 
		Record.Remarks = pChosenValue.Value;
	EndIf;
EndProcedure // AfterChoose

// ---------------------------------------------------------------------
Function GetChoiceValues()
	vVT = Record.InformationType.ChoiceValues.Unload();
	vArr = New Array;
	For Each vRow In vVT Do 
		vArr.Add(vRow.ChoiceValue);
	EndDo;
	Return vArr;
EndFunction // GetChoiceValues

// ---------------------------------------------------------------------
&AtServer
Procedure FillAttributes()
	vQry = New Query;
	vQry.Text = "SELECT TOP 1
	|	Accommodation.Room AS Room,
	|	Accommodation.CheckInDate AS CheckInDate,
	|	Accommodation.CheckOutDate AS CheckOutDate
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Guest = &qGuest
	|	AND Accommodation.AccommodationStatus.IsInHouse = TRUE
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Posted = TRUE"; 
	
	vQry.SetParameter("qGuest", Record.Client);
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	
	vRcd = vQry.Execute().Unload(); 
	
	If vRcd.Count() > 0 Then
		vRcdRow = vRcd.Get(0);
		Record.Room = vRcdRow.Room;
		Record.CheckInDate = vRcdRow.CheckInDate;
		Record.CheckOutDate = vRcdRow.CheckOutDate;
	Else
		vQry = New Query;
		vQry.Text = "SELECT TOP 1
		|	Accommodation.Room AS Room,
		|	Accommodation.CheckInDate AS CheckInDate,
		|	Accommodation.CheckOutDate AS CheckOutDate
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	Accommodation.Guest = &qGuest
		|	AND Accommodation.Hotel = &qHotel
		|	AND Accommodation.AccommodationStatus.IsCheckOut = TRUE
		|
		|ORDER BY
		|	CheckOutDate DESC"; 
		
		vQry.SetParameter("qGuest", Record.Client);
		vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
		
		vRcd = vQry.Execute().Unload();
		If vRcd.Count() > 0 Then
			vRcdRow = vRcd.Get(0);
			Record.Room = vRcdRow.Room;
			Record.CheckInDate = vRcdRow.CheckInDate;
			Record.CheckOutDate = vRcdRow.CheckOutDate;
		EndIf;
	EndIf;
EndProcedure // FillAttributes

#EndRegion

	
