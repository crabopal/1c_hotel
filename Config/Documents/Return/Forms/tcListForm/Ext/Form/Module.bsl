
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing) 
	SelHotel = SessionParameters.CurrentHotel; 
	// Set list mode
	If Parameters.Property("ChoiceMode") Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;	
	// Set default date mode
	SelDateListMode = 0; // By date 
	// Set current date filter
	SelDateFrom = BegOfDay(CurrentSessionDate());
	SelDateTo = EndOfDay(SelDateFrom);   
	ListModes.Clear();
	ListModes.Add(0, NStr("en='By creation timestamp'; ru='По времени создания'; de='Zum Erstellung Zeitpunkt'"), , PictureLib.Today);  
	ListModes.Add(1, NStr("en = 'By accounting date'; de = 'Zum Abrechnungsdatum'; ru = 'По учетной дате'"), , PictureLib.PeriodDay);
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;
	// Set list filter
	SetParameters();	
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SetParameters();
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure // SelHotelOnChange   

// --------------------------------------------------------------------------------
&AtClient
Procedure SelDateFromOnChange(pItem)
	ChangeListDate();
EndProcedure // SelDateFromOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelDateToOnChange(pItem)
	ChangeListDate();
EndProcedure // SelDateToOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	If ValueIsFilled(SelGuestGroup) Then
		AttributeChangeAtServer("GuestGroup", SelGuestGroup);
	Else
		ClearingAttributeAtServer("GuestGroup");
	EndIf;
EndProcedure // SelGuestGroupOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)
	If ValueIsFilled(SelClient) Then
		AttributeChangeAtServer("Payer", SelClient);
	Else
		ClearingAttributeAtServer("Payer");
	EndIf;
EndProcedure // SelClientOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(pItem)
	If ValueIsFilled(SelCustomer) Then
		AttributeChangeAtServer("AccountingCustomer", SelCustomer);
	Else
		ClearingAttributeAtServer("AccountingCustomer");
	EndIf;
EndProcedure // SelCustomerOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelAuthorOnChange(pItem)
	If ValueIsFilled(SelAuthor) Then
		AttributeChangeAtServer("Author", SelAuthor);
	Else
		ClearingAttributeAtServer("Author");
	EndIf;
EndProcedure // SelAuthorOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelCashRegisterOnChange(pItem)
	If ValueIsFilled(SelCashRegister) Then
		AttributeChangeAtServer("CashRegister", SelCashRegister);
	Else
		ClearingAttributeAtServer("CashRegister");
	EndIf;
EndProcedure // SelCashRegisterOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SelPaymentMethodOnChange(pItem)
	If ValueIsFilled(SelPaymentMethod) Then
		AttributeChangeAtServer("PaymentMethod", SelPaymentMethod);
	Else
		ClearingAttributeAtServer("PaymentMethod");
	EndIf;
EndProcedure // SelPaymentMethodOnChange

#EndRegion

#Region FormTableListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If pSelectedRow <> Undefined Then
		vRow = Items.List.CurrentData;
		If vRow <> Undefined And ValueIsFilled(vRow.Ref) Then
			ShowValue(, vRow.Ref);
		EndIf;
	EndIf;
EndProcedure // ListSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure ListOnActivateRow(pItem)
	vCurRow = Items.List.CurrentData;
	If vCurRow <> Undefined And ValueIsFilled(vCurRow.Ref) Then
		If CheckDocumentToEdit(vCurRow.Ref) Then
			Items.ListPostDocument.Enabled = True;	
			Items.ListUndoPostDocument.Enabled = True;
			Items.ListSetDeletionMark.Enabled = True;
			Items.ListContextMenuPostDocument.Enabled = True;	
			Items.ListContextMenuUndoPostDocument.Enabled = True;
			Items.ListContextMenuSetDeletionMark.Enabled = True;
		Else	
			Items.ListPostDocument.Enabled = False;	
			Items.ListUndoPostDocument.Enabled = False;
			Items.ListSetDeletionMark.Enabled = False;
			Items.ListContextMenuPostDocument.Enabled = False;	
			Items.ListContextMenuUndoPostDocument.Enabled = False;
			Items.ListContextMenuSetDeletionMark.Enabled = False;
		EndIf;	
	EndIf;	
EndProcedure // ListOnActivateRow

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ChangeListMode(pCommand)
	ThisForm.ShowChooseFromMenu(New NotifyDescription("ListModesAfterChoice", ThisForm), ListModes, Items.GroupPeriodActions);
EndProcedure // ChangeListMode

// --------------------------------------------------------------------------------
&AtClient
Procedure ChangeDocumentOnClient(pCommand)
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

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = SelDateFrom;
	vChoosePeriodDialog.Period.EndDate = SelDateTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SetParameters()
	List.Parameters.SetParameterValue("qHotel", SelHotel);
	// Set date
	ChangeListDate();
EndProcedure // SetParameters

// --------------------------------------------------------------------------------
&AtServer
Procedure ChangeListDate()
	List.Parameters.SetParameterValue("qDateListMode", SelDateListMode); 
	List.Parameters.SetParameterValue("qDateFrom", SelDateFrom); 
	If ValueIsFilled(SelDateTo) Then
		List.Parameters.SetParameterValue("qDateTo", SelDateTo);
	Else
		List.Parameters.SetParameterValue("qDateTo", Date(3999,12,31,23,59,59));
	EndIf;  
	Items.ChangeListMode.Title = ListModes.Get(SelDateListMode).Presentation;
	Items.ChangeListMode.Picture = ListModes.Get(SelDateListMode).Picture;
EndProcedure // ChangeListDate

// --------------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, pValue, vComparisonType, , True);
	EndIf;
EndProcedure // AttributeChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, , , , False);
EndProcedure // ClearingAttributeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		SelDateFrom = BegOfDay(pPeriod.StartDate);
		SelDateTo = EndOfDay(pPeriod.EndDate);
	EndIf;  
	ChangeListDate();
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ListModesAfterChoice(pItem, pExtraParameters) Export
	If pItem <> Undefined Then
		SelDateListMode = pItem.Value;
		ChangeListDate();
	EndIf;
EndProcedure // ChangeListMode

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
&AtServerNoContext
Function CheckDocumentToEdit(pRef)
	vHotel = pRef.Hotel;
	If ValueIsFilled(vHotel) Then
		If vHotel.DoNotEditClosedDateDocs And ValueIsFilled(vHotel.AccountingDate) Then
			If cmIfChargeIsInClosedDay(pRef) Then
				Return False;
			Endif;
		EndIf;
	EndIf;	
	Return True;
EndFunction	// CheckDocumentToEdit

#EndRegion