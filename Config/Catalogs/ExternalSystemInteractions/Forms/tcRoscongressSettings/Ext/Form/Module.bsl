#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnReadAtServer(CurrentObject)
	LoadReservationStatuses();
	LoadAccommodationTemplates();
	LoadHotels();
	LoadRoomRate();
EndProcedure // OnReadAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure OnWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	SaveReservationStatuses();
	SaveAccommodationTemplates();
	SaveHotels();
	SaveRoomRate();
EndProcedure // OnWriteAtServer

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function GetItems(pCatalogName)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.Hotel AS Hotel,
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode AS ExternalSystemCode,
	|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName,
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
	|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
	|
	|ORDER BY
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode";
	vQry.SetParameter("qExternalSystemCode", TrimR(Object.InteractionID));
	vQry.SetParameter("qHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qObjectTypeName", pCatalogName);
	Return vQry.Execute().Unload();
EndFunction // GetItems

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadReservationStatuses()
	vStatuses = GetItems("ReservationStatuses");
	// Check some standard values
	If vStatuses.Find("Book", "ObjectExternalCode") = Undefined Then
		vStatusesRow = vStatuses.Add();
		vStatusesRow.Hotel = Undefined;
		vStatusesRow.ExternalSystemCode = TrimR(Object.InteractionID);
		vStatusesRow.ObjectTypeName = "ReservationStatuses";
		vStatusesRow.ObjectExternalCode = "Book";
		vStatusesRow.ObjectRef = Undefined;
	EndIf;
	If vStatuses.Find("Canceled", "ObjectExternalCode") = Undefined Then
		vStatusesRow = vStatuses.Add();
		vStatusesRow.Hotel = Undefined;
		vStatusesRow.ExternalSystemCode = TrimR(Object.InteractionID);
		vStatusesRow.ObjectTypeName = "ReservationStatuses";
		vStatusesRow.ObjectExternalCode = "Canceled";
		vStatusesRow.ObjectRef = Undefined;
	EndIf;
	If vStatuses.Find("Payed", "ObjectExternalCode") = Undefined Then
		vStatusesRow = vStatuses.Add();
		vStatusesRow.Hotel = Undefined;
		vStatusesRow.ExternalSystemCode = TrimR(Object.InteractionID);
		vStatusesRow.ObjectTypeName = "ReservationStatuses";
		vStatusesRow.ObjectExternalCode = "Payed";
		vStatusesRow.ObjectRef = Undefined;
	EndIf;
	// Load table to the form
	ReservationStatuses.Clear();
	For Each vStatusesRow In vStatuses Do
		vReservationStatusesRow = ReservationStatuses.Add();
		vReservationStatusesRow.Code = vStatusesRow.ObjectExternalCode;
		vReservationStatusesRow.ReservationStatus = vStatusesRow.ObjectRef;
	EndDo;
EndProcedure // LoadReservationStatuses

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadAccommodationTemplates()
	vTemplates = GetItems("AccommodationTemplates");
	// Check some standard values
	If vTemplates.Find("Single", "ObjectExternalCode") = Undefined Then
		vTemplatesRow = vTemplates.Add();
		vTemplatesRow.Hotel = Undefined;
		vTemplatesRow.ExternalSystemCode = TrimR(Object.InteractionID);
		vTemplatesRow.ObjectTypeName = "AccommodationTemplates";
		vTemplatesRow.ObjectExternalCode = "Single";
		vTemplatesRow.ObjectRef = Undefined;
	EndIf;
	If vTemplates.Find("Double", "ObjectExternalCode") = Undefined Then
		vTemplatesRow = vTemplates.Add();
		vTemplatesRow.Hotel = Undefined;
		vTemplatesRow.ExternalSystemCode = TrimR(Object.InteractionID);
		vTemplatesRow.ObjectTypeName = "AccommodationTemplates";
		vTemplatesRow.ObjectExternalCode = "Double";
		vTemplatesRow.ObjectRef = Undefined;
	EndIf;
	// Load table to the form
	AccommodationTemplates.Clear();
	For Each vTemplatesRow In vTemplates Do
		vAccommodationTemplatesRow = AccommodationTemplates.Add();
		vAccommodationTemplatesRow.Code = vTemplatesRow.ObjectExternalCode;
		vAccommodationTemplatesRow.AccommodationTemplate = vTemplatesRow.ObjectRef;
	EndDo;
EndProcedure // LoadAccommodationTemplates

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadHotels()
	vBuildings = GetItems("Hotels");
	// Check some standard values
	If vBuildings.Count() = 0 Then
		vAllHotels = cmGetAllHotels();
		For Each vAllHotelsRow In vAllHotels Do
			vBuildingsRow = vBuildings.Add();
			vBuildingsRow.Hotel = Undefined;
			vBuildingsRow.ExternalSystemCode = TrimR(Object.InteractionID);
			vBuildingsRow.ObjectTypeName = "Hotels";
			vBuildingsRow.ObjectExternalCode = "";
			vBuildingsRow.ObjectRef = vAllHotelsRow.Hotel;
		EndDo;
	EndIf;
	// Load table to the form
	Hotels.Clear();
	For Each vBuildingsRow In vBuildings Do
		vHotelsRow = Hotels.Add();
		vHotelsRow.Code = vBuildingsRow.ObjectExternalCode;
		vHotelsRow.Hotel = vBuildingsRow.ObjectRef;
	EndDo;
EndProcedure // LoadHotels

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadRoomRate()
	RoomRate = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), TrimR(Object.InteractionID), "RoomRates", TrimR(Object.InteractionID));
EndProcedure // LoadMappingPermissionGroups

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearExistingSettingRecords(pObjectTypeName)
	If Not IsBlankString(pObjectTypeName) Then
		vItems = GetItems(pObjectTypeName);
		For Each vItemsRow In vItems Do
			vRcdMgr = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vRcdMgr.Hotel = vItemsRow.Hotel;
			vRcdMgr.ExternalSystemCode = vItemsRow.ExternalSystemCode;
			vRcdMgr.ObjectTypeName = vItemsRow.ObjectTypeName;
			vRcdMgr.ObjectExternalCode = vItemsRow.ObjectExternalCode;
			vRcdMgr.Read();
			If vRcdMgr.Selected() Then
				vRcdMgr.Delete();
			EndIf;
		EndDo;
	EndIf;
EndProcedure // ClearExistingSettingRecords

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveReservationStatuses()
	vObjectTypeName = "ReservationStatuses";
	// Clear old settings
	ClearExistingSettingRecords(vObjectTypeName);
	// Write new settings
	For Each vSettingsRow In ReservationStatuses Do
		If Not IsBlankString(vSettingsRow.Code) And ValueIsFilled(vSettingsRow.ReservationStatus) Then
			vRcdMgr = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vRcdMgr.Hotel = Catalogs.Hotels.EmptyRef();
			vRcdMgr.ExternalSystemCode = TrimR(Object.InteractionID);
			vRcdMgr.ObjectTypeName = vObjectTypeName;
			vRcdMgr.ObjectExternalCode = TrimAll(vSettingsRow.Code);
			vRcdMgr.ObjectRef = vSettingsRow.ReservationStatus;
			vRcdMgr.Write(True);
		EndIf;
	EndDo;
EndProcedure // SaveReservationStatuses

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveAccommodationTemplates()
	vObjectTypeName = "AccommodationTemplates";
	// Clear old settings
	ClearExistingSettingRecords(vObjectTypeName);
	// Write new settings
	For Each vSettingsRow In AccommodationTemplates Do
		If Not IsBlankString(vSettingsRow.Code) And ValueIsFilled(vSettingsRow.AccommodationTemplate) Then
			vRcdMgr = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vRcdMgr.Hotel = Catalogs.Hotels.EmptyRef();
			vRcdMgr.ExternalSystemCode = TrimR(Object.InteractionID);
			vRcdMgr.ObjectTypeName = vObjectTypeName;
			vRcdMgr.ObjectExternalCode = TrimAll(vSettingsRow.Code);
			vRcdMgr.ObjectRef = vSettingsRow.AccommodationTemplate;
			vRcdMgr.Write(True);
		EndIf;
	EndDo;
EndProcedure // SaveAccommodationTemplates

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveHotels()
	vObjectTypeName = "Hotels";
	// Clear old settings
	ClearExistingSettingRecords(vObjectTypeName);
	// Write new settings
	For Each vSettingsRow In Hotels Do
		If Not IsBlankString(vSettingsRow.Code) And ValueIsFilled(vSettingsRow.Hotel) Then
			vRcdMgr = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vRcdMgr.Hotel = Catalogs.Hotels.EmptyRef();
			vRcdMgr.ExternalSystemCode = TrimR(Object.InteractionID);
			vRcdMgr.ObjectTypeName = vObjectTypeName;
			vRcdMgr.ObjectExternalCode = TrimAll(vSettingsRow.Code);
			vRcdMgr.ObjectRef = vSettingsRow.Hotel;
			vRcdMgr.Write(True);
		EndIf;
	EndDo;
EndProcedure // SaveHotels

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveRoomRate()
	vObjectTypeName = "RoomRates";
	// Clear old settings
	ClearExistingSettingRecords(vObjectTypeName);
	// Write new settings
	If ValueIsFilled(RoomRate) Then
		vRcdMgr = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRcdMgr.Hotel = Catalogs.Hotels.EmptyRef();
		vRcdMgr.ExternalSystemCode = TrimR(Object.InteractionID);
		vRcdMgr.ObjectTypeName = vObjectTypeName;
		vRcdMgr.ObjectExternalCode = TrimR(Object.InteractionID);
		vRcdMgr.ObjectRef = RoomRate;
		vRcdMgr.Write(True);
	EndIf;
EndProcedure // SaveRoomRate

#EndRegion
