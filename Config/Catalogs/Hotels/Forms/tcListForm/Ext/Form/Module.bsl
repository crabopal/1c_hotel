
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not tcOnServer.cmIsInRole("RightsToChooseHotel") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You have no rights for this operation!'; de = 'Sie haben keine Rechte an dieser Aktion!'; ru = 'Нет прав на это действие!'"));
		pCancel = True;
		Return;
	EndIf;	
	vHotels = Catalogs.Hotels.GetHotelAllowedList();
	If vHotels.Count() > 0 Then
		Parameters.Filter.Insert("Ref",vHotels);
	EndIf;
	List.Parameters.SetParameterValue("qCurrHotel",SessionParameters.CurrentHotel);
EndProcedure // OnCreateAtServer

#EndRegion

