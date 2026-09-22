
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Hotel = Parameters.Hotel;
	GuestGroup = Parameters.GuestGroup;
	Event = Parameters.Event;
	GuestGroup = Parameters.GuestGroup;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOpening(pItem, pStandardProcessing)
	If Not ValueIsFilled(GuestGroup) Then
		pStandardProcessing = False;
		CreateNewGuestgroupAtServer();
	EndIf;
EndProcedure // GuestGroupOpening

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandSelection(pCommand)
	If Not ValueIsFilled(GuestGroup) Then
		CreateNewGuestGroupAtServer();
	EndIf;
	Notify("GroupForMergeIsChoosen", GuestGroup);
	ThisForm.Close();
EndProcedure // CommandSelection

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure CreateNewGuestgroupAtServer()
	vGuestGroupFolder = Hotel.GetObject().pmGetGuestGroupFolder();
	
	vGuestGroupObj = Catalogs.GuestGroups.CreateItem();
	vGuestGroupObj.Owner = Hotel;
	If ValueIsFilled(vGuestGroupFolder) Then
		vGuestGroupObj.Parent = vGuestGroupFolder;
		vGuestGroupObj.SetNewCode();
	EndIf;
	vGuestGroupObj.OneCustomerPerGuestGroup = Hotel.OneCustomerPerGuestGroup;
	vGuestGroupObj.Event = Event;
	vGuestGroupObj.Allotment = Allotment;
	
	vGuestGroupObj.Write();
	
	// Fill ref
	GuestGroup = vGuestGroupObj.Ref;
EndProcedure // CreateNewGuestgroupAtServer

#EndRegion

