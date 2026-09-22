
#Region FormEventHandlers   

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then
		vHotel = SessionParameters.CurrentHotel;
		If ValueIsFilled(vHotel) Then
			SelHotel = vHotel;
			AttributeChangeAtServer("Hotel", SelHotel);
		EndIf;
	EndIf; 
	vCurWstn = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vCurWstn) Then
		If vCurWstn.HasConnectionToIdentityCardsProcessingSystem Then
			vIdentityCardSystemParameters = vCurWstn.IdentityCardsProcessingSystemParameters;  
			If ValueIsFilled(vIdentityCardSystemParameters.ExternalInteraction) Then   
				ExternalInteraction = vIdentityCardSystemParameters.ExternalInteraction; 
			EndIf;	
		EndIf;
	EndIf;  
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	If Not tcOnServer.cmIsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;	
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)     
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	// Try convert card id to dec for ISD
	SelCardID = GetCardIDPresantation(vEventData.DeviceData, ExternalInteraction);
	If Not IsBlankString(SelCardID) Then
		AttributeChangeAtServer("Identifier", SelCardID, DataCompositionComparisonType.Contains);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCardIDOnChange(pItem)
	If ValueIsFilled(SelCardID) Then
		AttributeChangeAtServer("Identifier", SelCardID, DataCompositionComparisonType.Contains);
	Else
		ClearingAttributeAtServer("Identifier");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)
	If ValueIsFilled(SelClient) Then
		AttributeChangeAtServer("Guest", SelClient);
	Else
		ClearingAttributeAtServer("Guest");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	If ValueIsFilled(SelGuestGroup) Then
		SelOnlyFAFolios = False;
		AttributeChangeAtServer("GuestGroup", SelGuestGroup);
	Else
		ClearingAttributeAtServer("GuestGroup");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	If ValueIsFilled(SelRoom) Then
		AttributeChangeAtServer("Ref.Room", SelRoom);
	Else
		ClearingAttributeAtServer("Ref.Room");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCheckInDateOnChange(pItem)
	If ValueIsFilled(SelPeriodFrom) Then
		AttributeChangeAtServer("Date.BeginDates.BegOfDay", BegOfDay(SelPeriodFrom), DataCompositionComparisonType.GreaterOrEqual);
	Else
		ClearingAttributeAtServer("Date.BeginDates.BegOfDay");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCheckOutDateOnChange(pItem)
	If ValueIsFilled(SelPeriodTo) Then
		AttributeChangeAtServer("Date.EndDates.EndOfDay", EndOfDay(SelPeriodTo), DataCompositionComparisonType.LessOrEqual);
	Else
		ClearingAttributeAtServer("Date.EndDates.EndOfDay");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDiscountTypeOnChange(Item)
	If ValueIsFilled(SelDiscountType) Then
		AttributeChangeAtServer("DiscountType", SelDiscountType);
	Else
		ClearingAttributeAtServer("DiscountType");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	If ValueIsFilled(SelHotel) Then
		AttributeChangeAtServer("Hotel", SelHotel);
	Else
		ClearingAttributeAtServer("Hotel");
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	If Not tcOnServer.cmIsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // SelHotelClearing

&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vCurRow = Items.List.CurrentData;  
	If vCurRow <> Undefined Then
		ShowValue(, Items.List.CurrentData.Ref);
	EndIf;	
EndProcedure

#EndRegion   

#Region FormCommandsEventHandlers

 // -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = SelPeriodFrom;
	vChoosePeriodDialog.Period.EndDate = SelPeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisObject));
EndProcedure // ChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeDocumentOnClient(pCommand)   
	ClearMessages();
	If Items.List.SelectedRows.Count() > 0 Then
		For Each vCurRowID In Items.List.SelectedRows Do
			If vCurRowID <> Undefined Then
				vCurRow = Items.List.RowData(vCurRowID);
				If vCurRow <> Undefined And ValueIsFilled(vCurRow.Ref) Then
					vRef = vCurRow.Ref;
					If CheckDocumentToEdit(vRef) Then
						ChangeDocument(vRef, pCommand.Name);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		Items.List.Refresh();
	EndIf;
EndProcedure // ChangeDocumentOnClient

#EndRegion

#Region Private

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

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		SelPeriodFrom = pPeriod.StartDate;
		SelPeriodTo = pPeriod.EndDate; 
		If ValueIsFilled(SelPeriodFrom) Then
			AttributeChangeAtServer("Date.BeginDates.BegOfDay", BegOfDay(SelPeriodFrom), DataCompositionComparisonType.GreaterOrEqual);
		Else
			ClearingAttributeAtServer("Date.BeginDates.BegOfDay");
		EndIf; 
		If ValueIsFilled(SelPeriodTo) Then
			AttributeChangeAtServer("Date.EndDates.EndOfDay", EndOfDay(SelPeriodTo), DataCompositionComparisonType.LessOrEqual);
		Else
			ClearingAttributeAtServer("Date.EndDates.EndOfDay");
		EndIf;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
//
// Parameters:
//  pID					 - String - card id
//  pExternalInteraction - CatalogRef.ExternalSystemInteractions - Ref
// 
// Returns:
//  Sring - Formated card id
//
&AtServerNoContext
Function GetCardIDPresantation(pID, pExternalInteraction)  
	If ValueIsFilled(pExternalInteraction) And pExternalInteraction.IntegrationType = Enums.Integrations.ISD Then 
		vID = pID;    
		vDecLen = 20;
		Try
			If Not StrLen(pID) = vDecLen Then
				vID =  Format(Number(GetBinaryDataBufferFromHexString(pID).ReadInt64(0, ByteOrder.BigEndian)), "NG=0");
			EndIf;	
		Except
		EndTry;
	EndIf;
	Return vID;
EndFunction //  GetCardIDPresantation()

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ChangeDocument(pRef, pCMDName = "")
	If pCMDName = "PostDocument" Then
		vObj = pRef.GetObject();
		vObj.Write(DocumentWriteMode.Posting);
	ElsIf pCMDName = "UndoPostDocument" Then
		vObj = pRef.GetObject();
		vObj.Write(DocumentWriteMode.UndoPosting);
	ElsIf pCMDName = "SetDeletionMark" Then
		vObj = pRef.GetObject();
		vObj.SetDeletionMark(Not pRef.DeletionMark);	
	EndIf;	 
EndProcedure // ChangeDocument

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRef - DocumentRef.Carge - document ref
// 
// Returns:
//  Boolean - true or false
//
&AtServerNoContext
Function CheckDocumentToEdit(pRef)
	vHotel = pRef.Hotel;
	If ValueIsFilled(vHotel) Then
		If vHotel.DoNotEditClosedDateDocs And ValueIsFilled(vHotel.AccountingDate) Then
			If cmIfChargeIsInClosedDay(pRef) Then   
				vErr = NStr("en = 'The document %1 from %2 is in a closed date, modification is prohibited.'; 
						|de = 'Das Dokument %1 vom %2 befindet sich in einem geschlossenen Datum, Änderungen sind nicht erlaubt.'; 
						|ru = 'Документ %1 от %2 находится в закрытой дате, изменение запрещено.'");   
				vErr = StrTemplate(vErr, pRef.Number, Format(pRef.Date, "DF=dd.MM.yyyy")); 
				tcCommonFunctionOnClientServer.UserMessage(vErr);
				Return False;
			EndIf;   
		EndIf;
	EndIf;	
	Return True;
EndFunction	// CheckDocumentToEdit

#EndRegion
