#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)	
	MaximumNumber = 100;
	
	For Each vItem In Metadata.IntegrationServices Do
		Items.IntegrationServiceName.ChoiceList.Add(vItem.Name, vItem.Presentation());
	EndDo;
	If Parameters.Property("IntegrationServiceName") Then
		IntegrationServiceName = Parameters.IntegrationServiceName;
		Items.IntegrationServiceName.ReadOnly = True;
	Else
		IntegrationServiceName = Items.IntegrationServiceName.ChoiceList[0].Value;	
	EndIf;
	
	FillIntegrationServiceChannel();
	
	Refresh();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure IntegrationServiceChannelOnChange(pItem)
	Refresh();
EndProcedure // IntegrationServiceChannelOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IntegrationServiceNameOnChange(pItem)
	FillIntegrationServiceChannel();
	Refresh();
EndProcedure // IntegrationServiceNameOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure PeriodFromOnChange(pItem)
	Refresh();
EndProcedure // PeriodFromOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure PeriodToOnChange(pItem)
	Refresh();
EndProcedure // PeriodToOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure RecipientCodeOnChange(pItem)
	Refresh();
EndProcedure // RecipientCodeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SenderCodeOnChange(pItem)
	Refresh();
EndProcedure // SenderCodeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Refresh1(pCommand)
	Refresh();
EndProcedure // Refresh1

// --------------------------------------------------------------------------------
&AtClient
Procedure DeleteMessage(pCommand)
	vCurData = Items.IntegrationServiceMessages.CurrentData;
	If vCurData <> Undefined Then 
		DeleteMessageAtServer(vCurData.ID); 
	EndIf;
EndProcedure // DeleteMessage

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = PeriodFrom;
	vChoosePeriodDialog.Period.EndDate = PeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillIntegrationServiceChannel()
	IntegrationServiceChannel = "";
	Items.IntegrationServiceChannel.ChoiceList.Clear();	
	If ValueIsFilled(IntegrationServiceName) Then
		For Each vItem In Metadata.IntegrationServices[IntegrationServiceName].IntegrationServiceChannels Do
			Items.IntegrationServiceChannel.ChoiceList.Add(vItem.Name, vItem.Presentation());
		EndDo;   
		IntegrationServiceChannel = Items.IntegrationServiceChannel.ChoiceList[0].Value;
	Endif;
EndProcedure // FillIntegrationServiceChannel

// --------------------------------------------------------------------------------
&AtServer
Procedure Refresh()
	IntegrationServiceMessages.Clear();
	If ValueIsFilled(IntegrationServiceName) And ValueIsFilled(IntegrationServiceChannel) Then  
		vParams = New Structure; 
		If ValueIsFilled(PeriodFrom) Then
			vParams.Insert("StartSendDate", PeriodFrom);
		EndIf; 
		If ValueIsFilled(PeriodTo) Then
			vParams.Insert("EndSendDate", PeriodTo);
		EndIf;
		If ValueIsFilled(TrimAll(RecipientCode)) Then
			vParams.Insert("RecipientCode", TrimAll(RecipientCode));	
		EndIf;
		If ValueIsFilled(TrimAll(SenderCode)) Then
			vParams.Insert("SenderCode", TrimAll(SenderCode));	
		EndIf;
		vMessages = IntegrationServices[IntegrationServiceName][IntegrationServiceChannel].SelectMessages(vParams, ?(MaximumNumber = 0, Undefined, MaximumNumber));
		For Each vMessage In vMessages Do
			vNewRow = IntegrationServiceMessages.Add();
			FillPropertyValues(vNewRow, vMessage, "SendDate, ExpirationDate, ID, CorrelationId, SenderCode, RecipientCode");	
			vNewRow.Parameters = MapToJSON(vMessage.Parameters);
			Try
				vNewRow.BodySize = vMessage.BodySize; 				
			Except
			EndTry;
		EndDo;
	EndIf;
EndProcedure // Refresh

// --------------------------------------------------------------------------------
&AtServer
Function MapToJSON(pMap)	
	vJSONWriter = new JSONWriter;
	vJSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(vJSONWriter, pMap);
	Return vJSONWriter.Close();	
EndFunction // MapToJSON

// --------------------------------------------------------------------------------
&AtServer
Procedure DeleteMessageAtServer(pID)
	IntegrationServices[IntegrationServiceName][IntegrationServiceChannel].DeleteMessages(New Structure("ID", pID));	
EndProcedure // DeleteMessageAtServer

  // -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		PeriodFrom = pPeriod.StartDate;
		PeriodTo = EndOfDay(pPeriod.EndDate);
		Refresh();
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

#EndRegion