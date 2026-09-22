
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vReservationFilled 		= False;
	vAccommodationFilled 	= False;
	List.Parameters.SetParameterValue("qAccommodation", Documents.Accommodation.EmptyRef());
	List.Parameters.SetParameterValue("qReservation", Documents.Reservation.EmptyRef());
	If Parameters.Property("Accommodation") Then
		List.Parameters.SetParameterValue("qAccommodation", Parameters.Accommodation);
		If ValueIsFilled(Parameters.Accommodation) Then
			vAccommodationFilled 	= True;
			vReservationFilled 		= True;
			List.Parameters.SetParameterValue("qReservation", Parameters.Accommodation.Reservation);
		Else
			List.Parameters.SetParameterValue("qReservation", Documents.Reservation.EmptyRef());
		EndIf;
	ElsIf Parameters.Filter.Property("Accommodation") Then
		pStandardProcessing = False;
		List.Parameters.SetParameterValue("qAccommodation", Parameters.Filter.Accommodation);
		If ValueIsFilled(Parameters.Filter.Accommodation) Then
			vAccommodationFilled 	= True;
			vReservationFilled 		= True;
			List.Parameters.SetParameterValue("qReservation", Parameters.Filter.Accommodation.Reservation);
		Else
			List.Parameters.SetParameterValue("qReservation", Documents.Reservation.EmptyRef());
		EndIf;
	EndIf;   
	// Filter by period
	If ValueIsFilled(Parameters.PeriodFrom) Then 
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Period", Parameters.PeriodFrom, DataCompositionComparisonType.GreaterOrEqual, , True, DataCompositionSettingsItemViewMode.QuickAccess); 
	EndIf;
	If ValueIsFilled(Parameters.PeriodTo) Then    
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Period", Parameters.PeriodTo, DataCompositionComparisonType.LessOrEqual, , True, DataCompositionSettingsItemViewMode.QuickAccess); 
	EndIf;   
	// Set list params
	List.Parameters.SetParameterValue("qReservationFilled", vReservationFilled);
	List.Parameters.SetParameterValue("qAccommodationFilled", vAccommodationFilled);
EndProcedure // OnCreateAtServer()

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	OneGuestMode = False;
	If Window <> Undefined And Window.Content.Count() > 0 Then
		For Each vOwnersForm In Window.Content Do
			If vOwnersForm.FormName = "Document.Accommodation.Form.tcDocumentForm" Then
				OneGuestMode = vOwnersForm.OneGuestMode;
				Break;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Restore(pCommand)
	vRow = Items.List.CurrentData;
	If Not vRow = Undefined And ValueIsFilled(vRow.Accommodation) And TypeOf(vRow.Accommodation) = Type("DocumentRef.Accommodation") Then 
		vParam = New Structure;
		vParam.Insert("RestoreObject", New Structure("Period, Document", vRow.Period, vRow.Accommodation)); 
		vParam.Insert("OneGuestMode", OneGuestMode);
		OpenForm("Document.Accommodation.ObjectForm", vParam);
	ElsIf Not vRow = Undefined And ValueIsFilled(vRow.Accommodation) And TypeOf(vRow.Accommodation) = Type("DocumentRef.Reservation") Then  
		vMsg = NStr("en = 'It is necessary to highlight the line with the accommodation, not the reservation'; 
					|de = 'Es ist notwendig, die Zeile mit der Unterkunft hervorzuheben, nicht die Reservierung'; 
					|ru = 'Необходимо выделить строку с размещением, а не брони'");
		ShowMessageBox(, vMsg);
	EndIf;
EndProcedure // Restore()

#EndRegion
