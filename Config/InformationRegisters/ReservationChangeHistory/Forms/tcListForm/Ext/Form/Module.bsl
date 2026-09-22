
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(Parameters.PeriodFrom) Then 
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Period", Parameters.PeriodFrom, DataCompositionComparisonType.GreaterOrEqual, , True, DataCompositionSettingsItemViewMode.QuickAccess); 
	EndIf;
	If ValueIsFilled(Parameters.PeriodTo) Then    
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Period", Parameters.PeriodTo, DataCompositionComparisonType.LessOrEqual, , True, DataCompositionSettingsItemViewMode.QuickAccess); 
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	OneGuestMode = False;
	If Window <> Undefined And Window.Content.Count() > 0 Then
		For Each vOwnersForm In Window.Content Do
			If vOwnersForm.FormName = "Document.Reservation.Form.tcDocumentForm" Then
				OneGuestMode = vOwnersForm.OneGuestMode;
				Break;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Restore(pCommand)  
	vRow = Items.List.CurrentData;
	If Not vRow = Undefined And ValueIsFilled(vRow.Reservation) And TypeOf(vRow.Reservation) = Type("DocumentRef.Reservation") Then 
		vParam = New Structure;
		vParam.Insert("RestoreObject", New Structure("Period, Document", vRow.Period, vRow.Reservation)); 
		vParam.Insert("OneGuestMode", OneGuestMode);
		
		OpenForm("Document.Reservation.ObjectForm", vParam);
	EndIf;
EndProcedure

#EndRegion
