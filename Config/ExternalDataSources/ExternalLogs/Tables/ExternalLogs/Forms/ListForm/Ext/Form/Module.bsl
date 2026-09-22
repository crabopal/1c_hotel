

#Region FormEventHandlers

// ----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)	
	vFilter = Undefined;
	If Parameters.Property("Filter", vFilter) Then
		vExternalSystem = Undefined;
		If vFilter.Property("ExternalSystem", vExternalSystem) And ValueIsFilled(vExternalSystem) Then
			ExternalSystemUUID = TrimAll(vExternalSystem.UUID()); 	
		EndIf;
	EndIf;
	
	vCurDate = CurrentSessionDate();
	
	PeriodFrom = BegOfDay(vCurDate);
	PeriodTo = EndOfDay(vCurDate);
	
	SetParameters();
EndProcedure // OnCreateAtServer     

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodFromChange(pItem)
	SetParameters();
EndProcedure // PeriodChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodToChange(pItem)
	SetParameters();
EndProcedure // PeriodChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EventType1OnChange(pItem)
	SetParameters();
EndProcedure // EventType1OnChange

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		Try
			vRow.Value.Data["ExternalSystemPresentation"] = Catalogs.ExternalSystemInteractions.GetRef(New UUID(vRow.Value.Data["ExternalSystemUUID"]));
			vRow.Value.Data["EventTypePresentation"] = XMLValue(Type("EnumRef.ExternalSystemEventTypes"), vRow.Value.Data["EventType"]);
		Except
		EndTry;
	EndDo;	
EndProcedure // ListOnGetDataAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = PeriodFrom;
	vChoosePeriodDialog.Period.EndDate = PeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisObject));
EndProcedure // ChoosePeriod

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod = Undefined Then
		Return;	
	EndIf;
	
	PeriodFrom = pPeriod.StartDate;
	PeriodTo = pPeriod.EndDate;
	
	SetParameters();
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure SetParameters()
	List.Parameters.SetParameterValue("PeriodFrom", PeriodFrom);
	List.Parameters.SetParameterValue("PeriodTo", PeriodTo);
	List.Parameters.SetParameterValue("EventType", XMLString(EventType));
	List.Parameters.SetParameterValue("ExternalSystemUUID", ExternalSystemUUID);
EndProcedure // SetParameters

#EndRegion
