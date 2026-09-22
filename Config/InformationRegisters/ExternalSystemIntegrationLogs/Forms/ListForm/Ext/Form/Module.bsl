
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
    Items.List.Period.Variant = StandardPeriodVariant.Today;
    Items.List.Refresh();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodFromChange(pItem)
	If ValueIsFilled(PeriodFrom) Then
		AttributeChangeAtServer("PeriodFrom", PeriodFrom, DataCompositionComparisonType.GreaterOrEqual);
	Else
		ClearingAttributeAtServer("PeriodFrom");
	EndIf;
EndProcedure // PeriodChange  

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodToChange(pItem)
	If ValueIsFilled(PeriodTo) Then
		AttributeChangeAtServer("PeriodTo", PeriodTo, DataCompositionComparisonType.LessOrEqual);
	Else
		ClearingAttributeAtServer("PeriodTo");
	EndIf;
EndProcedure // PeriodChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EventType1OnChange(pItem)
	If ValueIsFilled(EventType) Then
		AttributeChangeAtServer("EventType", EventType);
	Else
		ClearingAttributeAtServer("EventType");
	EndIf;
EndProcedure // EventType1OnChange

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
	If pPeriod <> Undefined Then
		PeriodFrom = pPeriod.StartDate;
		PeriodTo = pPeriod.EndDate;
		PeriodFromChange(Items.PeriodFrom); 
		PeriodToChange(Items.PeriodTo);
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, pValue, vComparisonType, , True);
	EndIf;
EndProcedure // AttributeChangeAtServer 

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, , , , False);
EndProcedure // ClearingAttributeAtServer

#EndRegion

