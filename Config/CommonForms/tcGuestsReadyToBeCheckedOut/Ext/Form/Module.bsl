
#Region FormEventHandlers

// -----------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AccommodationsForCheckout") Then
		For Each vDocsStruct In Parameters.AccommodationsForCheckout Do
			vNewStr = Docs.Add();
			vNewStr.Ref = vDocsStruct.Ref;
			vNewStr.Room = vDocsStruct.Room;
			vNewStr.Guest = vDocsStruct.Guest;
			vNewStr.CheckInDate = vDocsStruct.CheckInDate;
			vNewStr.CheckOutDate = vDocsStruct.CheckOutDate;
			If vDocsStruct.CheckOutDate < CurrentSessionDate() Then
				vNewStr.Icon = PictureLib.RedCube;
			Else
				vNewStr.Icon = PictureLib.YellowCube;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	vFrequency = GetFrequencyFromCurrentWorkstation();
	vFrequency = ?(vFrequency = 0, 300, vFrequency*60);
	ThisForm.AttachIdleHandler("RefreshDocsList", vFrequency);
EndProcedure // OnOpen

// -----------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Document.Accommodation.WriteNew" 
	   Or pEventName = "Document.Accommodation.Write" Then
		RefreshDocsListAtServer();
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------
&AtClient
Procedure DocsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If pField.Name = "Guest" Then
		vCurrData = pItem.CurrentData;
		vFrm = vCurrData.Ref.GetForm();
		vFrm.Open();
	EndIf;
EndProcedure // DocsSelection

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------
&AtClient
Procedure Refresh(pCommand)
	RefreshDocsList();
EndProcedure // Refresh

#EndRegion

#Region Private

// -----------------------------------------------------------
&AtServer
Function GetFrequencyFromCurrentWorkstation()
	Return SessionParameters.CurrentWorkstation.InHouseGuestsPeriodOfStayAutoExtensionFrequency;
EndFunction // GetFrequencyFromCurrentWorkstation()

// -----------------------------------------------------------
&AtClient
Procedure ProlongForHour(pCommand)
	vCurrData = Items.Docs.CurrentData;
	If vCurrData <> Undefined Then
		vFrm = vCurrData.Ref.GetForm();
		vFrm.Open();
		vCheckOutDate = vFrm.CheckOutDate+3600;
		vFrm.CheckOutDate = vCheckOutDate;
		vFrm.CheckOutTime = ExtractTime(vCheckOutDate);
		vFrm.CheckOutDateOnChange(vFrm.Controls.CheckOutDate);
	EndIf;
EndProcedure // ProlongForHour

// -----------------------------------------------------------
&AtServer
Function ExtractTime(pDate)
	Return cmExtractTime(pDate);
EndFunction // ExtractTime

// -----------------------------------------------------------
&AtClient
Procedure ProlongFor2Hour(pCommand)
	vCurrData = Items.Docs.CurrentData;
	If vCurrData <> Undefined Then
		vFrm = vCurrData.Ref.GetForm();
		vFrm.Open();
		vCheckOutDate = vFrm.CheckOutDate+7200;
		vFrm.CheckOutDate = vCheckOutDate;
		vFrm.CheckOutTime = ExtractTime(vCheckOutDate);
		vFrm.CheckOutDateOnChange(vFrm.Controls.CheckOutDate);
	EndIf;
EndProcedure // ProlongFor2Hour

// -----------------------------------------------------------
&AtClient
Procedure RefreshDocsList()
	RefreshDocsListAtServer();
EndProcedure // RefreshDocsList

// -----------------------------------------------------------
&AtServer
Procedure RefreshDocsListAtServer()
	If Docs.Count()>0 Then
		vAccRef = Docs.Get(0).Ref;
		// Build list of accommodations to checking out
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Accommodation.Ref AS Ref,
		|	Accommodation.Room AS Room,
		|	Accommodation.Guest.FullName AS Guest,
		|	Accommodation.CheckInDate AS CheckInDate,
		|	Accommodation.CheckOutDate AS CheckOutDate
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	(&qHotelIsEmpty
		|			OR Accommodation.Hotel = &qHotel)
		|	AND Accommodation.Posted
		|	AND Accommodation.AccommodationStatus.IsActive
		|	AND Accommodation.AccommodationStatus.IsInHouse
		|	AND (Accommodation.AccommodationType.Type = &qRoom
		|			OR Accommodation.AccommodationType.Type = &qBeds)
		|	AND Accommodation.CheckOutDate < &qCheckOutDate
		|
		|ORDER BY
		|	Accommodation.PointInTime";
		vQry.SetParameter("qHotel", vAccRef.Hotel);
		vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(vAccRef.Hotel));
		vQry.SetParameter("qCheckOutDate", CurrentSessionDate()+900);
		vQry.SetParameter("qRoom", Enums.AccomodationTypes.Room);
		vQry.SetParameter("qBeds", Enums.AccomodationTypes.Beds);
		vAccDocs = vQry.Execute().Select();
		Docs.Clear();
		While vAccDocs.Next() Do
			vNewStr = Docs.Add();
			vNewStr.Ref = vAccDocs.Ref;
			vNewStr.Room = vAccDocs.Room;
			vNewStr.Guest = vAccDocs.Guest;
			vNewStr.CheckInDate = vAccDocs.CheckInDate;
			vNewStr.CheckOutDate = vAccDocs.CheckOutDate;
			If vAccDocs.CheckOutDate < CurrentSessionDate() Then
				vNewStr.Icon = PictureLib.RedCube;
			Else
				vNewStr.Icon = PictureLib.YellowCube;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // RefreshDocsListAtServer


#EndRegion


