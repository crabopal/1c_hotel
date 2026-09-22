
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Document = Parameters.Document;
	Room = Parameters.Room;
	HousekeepingRemarks = Parameters.HousekeepingRemarks;
	If Not ValueIsFilled(Document) Then
		pCancel = True;
	EndIf;
	If TypeOf(Document) <> Type("DocumentRef.Accommodation") And TypeOf(Document) <> Type("DocumentRef.Reservation") Then
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HousekeepingRemarksStartChoice(pItem, pChoiceData, pStandardProcessing)
	vAmenitiesList = GetAmenitiesList(pItem.EditText);
	vAmenitiesList.ShowCheckItems(New NotifyDescription("AmenitiesAfterChoice", ThisForm, "HousekeepingRemarks"), NStr("en='Choose amenities'; ru='Отметьте доп. удобства'; de='Wählen Sie Amenities'"));
EndProcedure // HousekeepingRemarksStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure WriteAndClose(pCommand)
	WriteAtServer();
	ThisForm.Close();
	Notify("tcEditHousekeepingRemarks.Write", New Structure("Room, Document, HousekeepingRemarks", Room, Document, TrimAll(HousekeepingRemarks)));
EndProcedure // WriteAndClose

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure WriteAtServer()
	vDocObj = Document.GetObject();
	vDocObj.HousekeepingRemarks = TrimAll(HousekeepingRemarks);
	If vDocObj.Posted Then
		vDocObj.Write(DocumentWriteMode.Posting);
	Else
		If vDocObj.DeletionMark Then
			vDocObj.DeletionMark = False;
		EndIf;
		vDocObj.Write(DocumentWriteMode.Write);
	EndIf;
	If TypeOf(Document) = Type("DocumentRef.Accommodation") Then
		vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	ElsIf TypeOf(Document) = Type("DocumentRef.Reservation") Then
		vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndIf;
EndProcedure // WriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AmenitiesAfterChoice(pUC, pExtraParams) Export
	vSTag = Char(8226) + " ";
	vETag = " " + Char(8226);
	If pUC <> Undefined Then
		vAmenitiesStr = "";
		For Each vUCItem In pUC Do
			If vUCItem.Check Then
				vAmenitiesStr = vAmenitiesStr + ?(IsBlankString(vAmenitiesStr), vSTag, ", ") + 
				                TrimAll(vUCItem.Value);
			EndIf;
		EndDo;
		If Not IsBlankString(vAmenitiesStr) Then
			vAmenitiesStr = vAmenitiesStr + vETag;
		EndIf;
		// Remove old amenities block from the remarks and add new amenities as first string
		vRemarks = Items[pExtraParams].EditText;
		vSPos = StrFind(vRemarks, vSTag);
		If vSPos > 0 Then
			vEPos = StrFind(vRemarks, vETag, , vSPos + 1);
			If vEPos > 0 Then
				vRemarks = TrimAll(Mid(vRemarks, vEPos + 3));
			EndIf;
		EndIf;
		ThisForm[pExtraParams] = TrimAll(vAmenitiesStr + Chars.LF + vRemarks);
	EndIf;
EndProcedure // AmenitiesAfterChoice

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAmenitiesList(pRemarks)
	vAmenitiesList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Amenities.Description AS Description,
	|	Amenities.Ref AS Ref
	|FROM
	|	Catalog.Amenities AS Amenities
	|WHERE
	|	NOT Amenities.DeletionMark
	|	AND (Amenities.Availability = 0
	|			OR Amenities.Availability = 2)
	|
	|ORDER BY
	|	Description";
	vAmenities = vQry.Execute().Unload();
	For Each vAmenitiesRow In vAmenities Do
		vAmenitiesListItem = vAmenitiesList.Add(vAmenitiesRow.Ref);
		If StrFind(pRemarks, TrimAll(vAmenitiesRow.Description)) > 0 Then
			vAmenitiesListItem.Check = True;
		EndIf;
	EndDo;
	Return vAmenitiesList;
EndFunction // GetAmenitiesList

#EndRegion
