
#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut1Click(pItem)
	vCommandURL = "e1cib/command/CommonCommand.ShowExpectedArrival";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut1Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut2Click(pItem)
	vCommandURL = "e1cib/command/CommonCommand.ReportsCommand";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut2Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut3Click(pItem)
	vCommandURL = "e1cib/command/CommonCommand.ShowInHouseGuests";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut3Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut4Click(pItem)
	vCommandURL = "e1cib/command/CommonCommand.ShowExpectedDeparture";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut4Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut6Click(pItem)
	vCommandURL = "e1cib/command/CommonCommand.AvailableRoomsReportCommand";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut6Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut7Click(pItem)
	vCommandURL = "e1cib/command/CommonCommand.Kiosk";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut7Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut8Click(pItem)
	vCommandURL = "e1cib/command/CommonCommand.ShowRoomsGanttChart";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut8Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut10Click(pItem)
	vCommandURL = "e1cib/command/CommonCommand.ShowGuestGroups";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut10Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut13Click(pItem)
	vCommandURL = "e1cib/command/CommonCommand.ReservationCommand";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut13Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut14Click(pItem)
	vCommandURL = "e1cib/command/Catalog.Resources.Command.OpenResourcePlanner";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut14Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut15Click(pItem)
	vCommandURL = "e1cib/command/CommonCommand.ResourceReservationCommand";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut15Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut16Click(pItem)
	vCommandURL = "e1cib/command/Catalog.Rooms.Command.OpenSearchRoomsForm";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut16Click

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationShortcut17Click(pItem)
	vCommandURL = "e1cib/command/Catalog.Rooms.Command.OpenHousekeepingRoomsForm";
	GotoURL(vCommandURL);
EndProcedure // DecorationShortcut17Click

#EndRegion

