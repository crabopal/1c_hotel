
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelHotel") And ValueIsFilled(Parameters.SelHotel) Then
		SelHotel = Parameters.SelHotel;
	Else
		SelHotel = SessionParameters.CurrentHotel;	
	EndIf; 
	If Parameters.Property("SelCurRoomList") Then
		SelCurRoomList = Parameters.SelCurRoomList;		
	EndIf;
	SelDate = CurrentSessionDate();
	SetFilterCollapsedTitle();
	FillBlockList();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateOnChange(pItem)
	SetFilterCollapsedTitle();
	FillBlockList();
EndProcedure // SelDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	SetFilterCollapsedTitle();
	FillBlockList();
EndProcedure // SelRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomBlockTypeOnChange(pItem)
	SetFilterCollapsedTitle();
	FillBlockList();
EndProcedure // SelRoomBlockTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Rooms.Form.tcChoiceForm", , pItem);
EndProcedure // SelRoomStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomBlockTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.RoomBlockTypes.Form.tcChoiceForm", , pItem);
EndProcedure // SelRoomBlockTypeStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectAll(pCommand)
	For Each vCheckExecute In BlockList Do
		vCheckExecute.CheckExecute = True;		
	EndDo;
EndProcedure // SelectAll

// -----------------------------------------------------------------------------
&AtClient
Procedure Deselect(pCommand)
	For Each vCheckExecute In BlockList Do
		vCheckExecute.CheckExecute = False;		
	EndDo;
EndProcedure // Deselect

// -----------------------------------------------------------------------------
&AtClient
Procedure FormExecute(pCommand)
	ExecuteAtServer();
	ShowMessageBox(, NStr("en = 'Performed'; de = 'Durchgeführt'; ru = 'Выполнено'"));
	Notify("Document.SetRoomBlock.Unblock");
	FillBlockList();
EndProcedure // FormExecute

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetFilterCollapsedTitle()
	vGroupSearchModeTitle = Items.GroupSearchMode.Title + ": ";
	If ValueIsFilled(SelDate) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + Items.SelDate.Title + ": " + TrimAll(SelDate) + "; ";
	EndIf;
	If ValueIsFilled(SelRoom) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + Items.SelRoom.Title + ": " + TrimAll(SelRoom) + "; ";
	EndIf;
	If ValueIsFilled(SelRoomBlockType) Then
		vGroupSearchModeTitle = vGroupSearchModeTitle + Items.SelRoomBlockType.Title + ": " + TrimAll(SelRoomBlockType) + "; ";
	EndIf;
	Items.GroupSearchMode.CollapsedRepresentationTitle = vGroupSearchModeTitle;
EndProcedure // SetFilterCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure FillBlockList()
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	SetRoomBlock.Ref AS Ref,
	|	SetRoomBlock.Room AS Room,
	|	SetRoomBlock.RoomBlockType AS RoomBlockType,
	|	SetRoomBlock.Remarks AS Remarks,
	|	SetRoomBlock.DateFrom AS DateFrom,
	|	SetRoomBlock.DateTo AS DateTo
	|FROM
	|	Document.SetRoomBlock AS SetRoomBlock
	|WHERE
	|	NOT SetRoomBlock.DeletionMark
	|	AND (SetRoomBlock.DateTo >= &qDate
	|			OR SetRoomBlock.DateTo = DATETIME(1, 1, 1, 0, 0, 0)
	|				AND SetRoomBlock.DateFrom < &qDate)
	|	AND (NOT &qRoomIsEmpty
	|				AND SetRoomBlock.Room = &qRoom
	|			OR &qRoomIsEmpty)
	|	AND (NOT &qRoomBlockTypeIsEmpty
	|				AND SetRoomBlock.RoomBlockType = &qRoomBlockType
	|			OR &qRoomBlockTypeIsEmpty)
	|	AND (NOT &qHotelIsEmpty
	|				AND SetRoomBlock.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND NOT SetRoomBlock.IsFinished
	|
	|ORDER BY
	|	SetRoomBlock.Room.SortCode";
	vQuery.SetParameter("qDate", SelDate);
	vQuery.SetParameter("qRoomIsEmpty", Not ValueIsFilled(SelRoom));
	vQuery.SetParameter("qRoom", SelRoom);
	vQuery.SetParameter("qRoomBlockTypeIsEmpty", Not ValueIsFilled(SelRoomBlockType));
	vQuery.SetParameter("qRoomBlockType", SelRoomBlockType);
	vQuery.SetParameter("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	vQuery.SetParameter("qHotel", SelHotel);
	vResult = vQuery.Execute().Unload();
	BlockList.Clear();
	For Each vSetRoomBlock In vResult Do
		vAddItem = BlockList.Add();
		vAddItem.CheckExecute = ?(SelCurRoomList.FindByValue(vSetRoomBlock.Room) <> Undefined, True, False);
		vAddItem.Room = vSetRoomBlock.Room;
		vAddItem.RoomBlockType = vSetRoomBlock.RoomBlockType;
		vAddItem.Remarks = vSetRoomBlock.Remarks;
		vAddItem.DateFrom = vSetRoomBlock.DateFrom;
		vAddItem.DateTo = vSetRoomBlock.DateTo;
		vAddItem.Document = vSetRoomBlock.Ref;
	EndDo;
EndProcedure // FillBlockList

// -----------------------------------------------------------------------------
&AtServer
Procedure ExecuteAtServer()
	For Each vSetRoomBlock In BlockList Do
		If vSetRoomBlock.CheckExecute Then
			vObj = vSetRoomBlock.Document.GetObject();
			vObj.DateTo = CurrentSessionDate();
			vObj.IsFinished = True;
			vObj.pmCalculateDuration();
			vObj.Write(DocumentWriteMode.Posting);
		EndIf;	
	EndDo;
EndProcedure // ExecuteAtServer

#EndRegion
