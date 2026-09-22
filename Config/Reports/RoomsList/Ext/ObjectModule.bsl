 // -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	// Setup default attributes
	cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Landscape, True);
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);	
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report");
	
	// Report header
	vHeader = vTemplate.GetArea("Header");
	vCurDateTime = CurrentSessionDate();
	vHeader.Parameters.mDateTime = Format(vCurDateTime, "DF=dd-MM-yy HH:mm");
	If ValueIsFilled(Hotel) Then
		vHeader.Parameters.mHotel = Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage);
		// Load pictures
		If Hotel.Logo <> Undefined Then
			vLogo = Hotel.Logo.Get();
			If vLogo <> Undefined Then
				vHeader.Drawings.Logo.Print = True;
				vHeader.Drawings.Logo.Picture = vLogo;
			Else
				vHeader.Drawings.Delete(vHeader.Drawings.Logo);
			EndIf;
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.Logo);
		EndIf;
	EndIf;
	pSpreadsheet.Put(vHeader);
	
	vRoomList = GetRoomsList();
	
	vRoomStatusList = vRoomList.Copy(, "RoomStatus, CountRoom");
	vRoomStatusList.GroupBy("RoomStatus", "CountRoom");
	For Each vRoomStatusRow In vRoomStatusList Do
		vStatusRow = vTemplate.GetArea("RoomStatusRow");
		vRoomRow = vTemplate.GetArea("RoomRow");
		vCheckPutArr = New Array();
		vCheckPutArr.Add(vStatusRow);
		vCheckPutArr.Add(vRoomRow);
		vStatusRow.Parameters.mRoomStatus = TrimAll(vRoomStatusRow.RoomStatus) + " (" + vRoomStatusRow.CountRoom + ")";
		If pSpreadsheet.CheckPut(vCheckPutArr) Then
			pSpreadsheet.Put(vStatusRow);
		Else
			pSpreadsheet.PutHorizontalPageBreak();
			pSpreadsheet.Put(vStatusRow);
		EndIf;
		vRoomArr = vRoomList.FindRows(New Structure("RoomStatus", vRoomStatusRow.RoomStatus));
		vNumber = 0;
		vCount = vRoomArr.Count() - 1; 
		vRoomRow = Undefined;
		For i = 0 To vCount Do
			If vRoomRow  = Undefined Then
				vRoomRow = vTemplate.GetArea("RoomRow");	
			EndIf;                                                        
			vRoomRow.Parameters["mRoomType_" + vNumber] =  TrimAll(?(vRoomArr[i].DayUse, "#", "") + ?(vRoomArr[i].DueOut, "D", "") + ?(vRoomArr[i].Blocked, "B", "") + " " + TrimAll(vRoomArr[i].RoomType.Code));
			vRoomRow.Parameters["mRoom_" + vNumber] = ?(vRoomArr[i].Sharer, "* ", "") + TrimAll(vRoomArr[i].Room.Description); 	
			If vNumber = 7 Or i = vCount Then
				vNumber = 0;
				If vRoomRow <> Undefined Then
					If pSpreadsheet.CheckPut(vRoomRow) Then
						pSpreadsheet.Put(vRoomRow);
					Else
						pSpreadsheet.PutHorizontalPageBreak();
						pSpreadsheet.Put(vStatusRow);
						pSpreadsheet.Put(vRoomRow);
					EndIf;
				EndIf;
				vRoomRow = Undefined;
			Else	
				vNumber = vNumber + 1;
			EndIf;
		EndDo;
	EndDo;
	vFilter = TrimAll(GetReportParametersPresentation()); 
	If ValueIsFilled(vFilter) Then 
		pSpreadsheet.Header.Enabled = True;
		pSpreadsheet.Header.LeftText = NStr("en = 'Filter: '; de = 'Auswahl: '; ru = 'Отбор: '") + vFilter;
	EndIf;
	pSpreadsheet.Footer.Enabled = True;
	pSpreadsheet.Footer.CenterText = NStr("en = '* - Sharer, # - Day Use, D - Due out, B - Blocked.'; de = '* - Sharer, # - Day Use, D - Due out, B - Blocked.'; ru = '* - Совместные, # - Дневное проживание, D - На выезде, B – Блокировка.'") + 
									 Chars.LF + 
									 NStr("en = 'Page [&PageNumber] of [&PagesTotal]'; de = 'Seite [&PageNumber] von [&PagesTotal]'; ru = 'Страница [&PageNumber] из [&PagesTotal]'");

EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Function GetRoomsList()
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Accommodation.CheckInDate AS CheckInDate,
	|	Accommodation.CheckOutDate AS CheckOutDate,
	|	Accommodation.NumberOfAdults + Accommodation.NumberOfTeenagers + Accommodation.NumberOfChildren + Accommodation.NumberOfInfants AS NumberOfPersons,
	|	Accommodation.Room AS Room,
	|	Accommodation.AccommodationStatus.IsCheckOut AS IsCheckOut
	|INTO Accommodation
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	NOT Accommodation.DeletionMark
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.Hotel = &qHotel
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetRoomBlock.Ref AS Ref,
	|	SetRoomBlock.Room AS Room
	|INTO SetRoomBlock
	|FROM
	|	Document.SetRoomBlock AS SetRoomBlock
	|WHERE
	|	SetRoomBlock.Posted
	|	AND SetRoomBlock.DateFrom <= &qDate
	|	AND CASE
	|			WHEN SetRoomBlock.DateTo <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN SetRoomBlock.DateTo >= &qDate
	|			ELSE TRUE
	|		END
	|	AND SetRoomBlock.Hotel = &qHotel
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Rooms.Ref AS Room,
	|	Rooms.RoomStatus AS RoomStatus,
	|	Rooms.RoomType AS RoomType,
	|	CASE
	|		WHEN NOT Accommodation.NumberOfPersons IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Sharer,
	|	CASE
	|		WHEN NOT Accommodation.CheckInDate IS NULL
	|				AND NOT Accommodation.CheckOutDate IS NULL
	|			THEN CASE
	|					WHEN BEGINOFPERIOD(Accommodation.CheckInDate, DAY) = BEGINOFPERIOD(Accommodation.CheckOutDate, DAY)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE FALSE
	|	END AS DayUse,
	|	CASE
	|		WHEN NOT SetRoomBlock.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Blocked,
	|	CASE
	|		WHEN NOT Accommodation.CheckOutDate IS NULL
	|				AND NOT Accommodation.IsCheckOut IS NULL
	|			THEN CASE
	|					WHEN Accommodation.IsCheckOut
	|							AND BEGINOFPERIOD(Accommodation.CheckOutDate, DAY) = BEGINOFPERIOD(&qDate, DAY)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE FALSE
	|	END AS DueOut,
	|	1 AS CountRoom
	|FROM
	|	Catalog.Rooms AS Rooms
	|		LEFT JOIN Accommodation AS Accommodation
	|		ON Rooms.Ref = Accommodation.Room
	|		LEFT JOIN SetRoomBlock AS SetRoomBlock
	|		ON Rooms.Ref = SetRoomBlock.Room
	|WHERE
	|	Rooms.Owner = &qHotel
	|	AND NOT Rooms.IsFolder
	|	AND NOT Rooms.DeletionMark
	|	AND CASE
	|			WHEN &qRoomStatus <> VALUE(Catalog.RoomStatuses.EmptyRef)
	|				THEN Rooms.RoomStatus = &qRoomStatus
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qRoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				THEN Rooms.RoomType = &qRoomType
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qRoomSection <> VALUE(Catalog.RoomSections.EmptyRef)
	|				THEN Rooms.RoomSection = &qRoomSection
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qRoomGroup <> VALUE(Catalog.Rooms.EmptyRef)
	|				THEN Rooms.Parent = &qRoomGroup
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	Rooms.RoomStatus.SortCode,
	|	Rooms.SortCode";
	vQuery.SetParameter("qHotel", Hotel);
	vQuery.SetParameter("qRoomStatus", RoomStatus);
	vQuery.SetParameter("qRoomType", RoomType);
	vQuery.SetParameter("qRoomSection", RoomSection);
	vQuery.SetParameter("qRoomGroup", RoomGroup);
	vQuery.SetParameter("qDate", CurrentSessionDate());
	Return vQuery.Execute().Unload();
EndFunction // GetRoomsList

// -----------------------------------------------------------------------------
Function GetReportParametersPresentation()
	vParamPresentation = "";
	If ValueIsFilled(Hotel) Then
			vParamPresentation = vParamPresentation + NStr("en = 'Hotel: '; de = 'Hotel: '; ru = 'Гостиница: '") + 
			                     Hotel.Description + 
			                     "; ";
	EndIf;
	If ValueIsFilled(RoomType) Then
			vParamPresentation = vParamPresentation + NStr("en = 'Room type: '; de = 'Zimmertyp: '; ru = 'Тип номеров: '") + 
			                     RoomType.Description + 
			                     "; ";
	EndIf;
	If ValueIsFilled(RoomGroup) Then
			vParamPresentation = vParamPresentation + NStr("en = 'Room group: '; de = 'Zimmer Gruppe: '; ru = 'Группа номеров: '") + 
			                     RoomGroup.Description + 
			                     "; ";
	EndIf;
	If ValueIsFilled(RoomSection) Then
			vParamPresentation = vParamPresentation + NStr("en = 'Room section: '; de = 'Sektion der Zimmer: '; ru = 'Секция номеров: '") + 
			                     RoomSection.Description + 
			                     "; ";
	EndIf;
	If ValueIsFilled(RoomStatus) Then
			vParamPresentation = vParamPresentation + NStr("en = 'Room status: '; de = 'Status der Zimmer: '; ru = 'Статус номеров: '") + 
			                     RoomStatus.Description + 
			                     "; ";
	EndIf;						 
	Return vParamPresentation;
EndFunction // GetReportParametersPresentation