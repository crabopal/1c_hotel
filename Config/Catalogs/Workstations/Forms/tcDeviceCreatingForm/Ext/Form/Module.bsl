#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	DeviceType = Parameters.DeviceType;
	If ValueIsFilled(DeviceType) Then
		Items.DeviceType.Enabled = False;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DeviceSettingsStartChoice(pItem, pChoiceData, pStandardProcessing)
	vType = "CatalogRef." + ReturnFilterStatusName(DeviceType);
	pItem.TypeRestriction = New TypeDescription(vType);
EndProcedure // DeviceSettingsStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Add(pCommand)
	NotifyChoice(New Structure("DeviceType, DeviceSettings, IsActive", DeviceType, DeviceSettings, IsActive));
EndProcedure // Add

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function ReturnFilterStatusName(pEnumRef)
	vMetadataName = pEnumRef.Metadata().Name;
	vManagerName = "EnumManager." + vMetadataName;
	vManager = New (vManagerName); 
	vName = pEnumRef.Metadata().EnumValues[vManager.IndexOf(pEnumRef)].Name;

	Return vName;
Endfunction //ReturnFilterStatusName

#EndRegion
