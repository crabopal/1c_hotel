
#Region FormEventHandlers

// ---------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vSettingStructure = Undefined;
	Parameters.Property("SettingStructure", vSettingStructure);
	If vSettingStructure <> Undefined Then
		If vSettingStructure.Property("Hotel") Then
			Hotel = vSettingStructure.Hotel;
		EndIf;
		If vSettingStructure.Property("PriceChangeReason") Then
			PriceChangeReason = vSettingStructure.PriceChangeReason;
		EndIf;
	EndIf;
	vPCRTable = cmGetAllPriceChangeReasons();
	PriceChangeReasons.LoadValues(vPCRTable.UnloadColumn("Description"));
	For Each vPCRItem In PriceChangeReasons Do
		vPCRText = vPCRItem.Value;
		If StrFind(PriceChangeReason, vPCRText) > 0 Then
			vPCRItem.Check = True;
		EndIf;
	EndDo;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// ---------------------------------------------------------------
&AtClient
Procedure SaveClose(pCommand)
	vResultStructure = New Structure;
	PriceChangeReason = "";
	For Each vPCRItem In PriceChangeReasons Do
		If vPCRItem.Check Then
			PriceChangeReason = PriceChangeReason + ?(IsBlankString(PriceChangeReason), "", " + ") + vPCRItem.Value;
		EndIf;
	EndDo;
	vResultStructure.Insert("PriceChangeReason", PriceChangeReason);
	Close(vResultStructure);
EndProcedure // SaveClose

#EndRegion
