// -----------------------------------------------------------------------------
Function IsGuestGroupActive(pGuestGroup, pEditProhibitedDate)
  vIsActive = True;
  If ValueIsFilled(pGuestGroup) And ValueIsFilled(pGuestGroup.Status) Then
    If Not ValueIsFilled(pGuestGroup.CheckOutDate) Or 
       ValueIsFilled(pGuestGroup.CheckOutDate) And BegOfDay(pGuestGroup.CheckOutDate) < pEditProhibitedDate Then
      vGuestGroupStatus = pGuestGroup.Status;
      If TypeOf(vGuestGroupStatus) = Type("CatalogRef.ReservationStatuses") And Not vGuestGroupStatus.IsActive And Not vGuestGroupStatus.IsPreliminary And Not vGuestGroupStatus.IsCheckIn Then
        vIsActive = False;
      ElsIf TypeOf(vGuestGroupStatus) = Type("CatalogRef.ResourceReservationStatuses") And 
           (Not vGuestGroupStatus.IsActive Or vGuestGroupStatus.IsActive And vGuestGroupStatus.ServicesAreDelivered) Then
        vIsActive = False;
      ElsIf TypeOf(vGuestGroupStatus) = Type("CatalogRef.AccommodationStatuses") And 
           (Not vGuestGroupStatus.IsActive Or vGuestGroupStatus.IsActive And Not vGuestGroupStatus.IsInHouse) Then
        vIsActive = False;
      EndIf;
    Else
      vIsActive = True;
    EndIf;
  Else
    vIsActive = False;
  EndIf;
  Return vIsActive; 
EndFunction // IsGuestGroupActive

// -----------------------------------------------------------------------------
// Description: Checks hotel edit prohibition date for the documents
// Parameters: Document object, True if document couldn't be changed,
//             False if change is permitted
// Return value: None
// -----------------------------------------------------------------------------
Procedure HotelDocumentsCheckEditProhibitedDate(pSource, pCancel) Export
	// Check hotel edit prohibited date and cancel operation if necessary
	If ValueIsFilled(pSource.Hotel) Then
		vEditProhibitedDate = pSource.Hotel.EditProhibitedDate;
		If ValueIsFilled(vEditProhibitedDate) Then
			If TypeOf(pSource) = Type("DocumentObject.Accommodation") Or 
			   TypeOf(pSource) = Type("DocumentObject.Reservation") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.CheckOutDate) Then
					vGuestGroup = pSource.GuestGroup;
					If Not IsGuestGroupActive(vGuestGroup, vEditProhibitedDate) Then
						pCancel = True;
					EndIf;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.ForeignerRegistryRecord") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.CheckOutDate) Then
					If ValueIsFilled(pSource.ParentDoc) Then
						vGuestGroup = pSource.ParentDoc.GuestGroup;
						If Not IsGuestGroupActive(vGuestGroup, vEditProhibitedDate) Then
							pCancel = True;
						EndIf;
					Else
						pCancel = True;
					EndIf;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.ResourceReservation") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.DateTimeTo) Then
					vGuestGroup = pSource.GuestGroup;
					If Not IsGuestGroupActive(vGuestGroup, vEditProhibitedDate) Then
						pCancel = True;
					EndIf;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.Folio") Then
				If ValueIsFilled(pSource.DateTimeTo) And BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.DateTimeTo) Then
					If pSource.IsClosed Then
						vGuestGroup = pSource.GuestGroup;
						If Not IsGuestGroupActive(vGuestGroup, vEditProhibitedDate) Then
							pCancel = True;
						EndIf;
					EndIf;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.SetRoomBlock") Then
				If ValueIsFilled(pSource.DateTo) And BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.DateTo) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.SetRoomQuota") Then
				If ValueIsFilled(pSource.DateTo) And BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.DateTo) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.Charge") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					If ValueIsFilled(pSource.ParentDoc) Then
						vParentDoc = pSource.ParentDoc;
						If TypeOf(vParentDoc) = Type("DocumentObject.Accommodation") Or
						   TypeOf(vParentDoc) = Type("DocumentObject.Reservation") Then
							If BegOfDay(vEditProhibitedDate) >= BegOfDay(vParentDoc.CheckOutDate) Then
								vGuestGroup = vParentDoc.GuestGroup;
								If Not IsGuestGroupActive(vGuestGroup, vEditProhibitedDate) Then
									pCancel = True;
								EndIf;
							EndIf;
						ElsIf TypeOf(vParentDoc) = Type("DocumentObject.ResourceReservation") Then
							If BegOfDay(vEditProhibitedDate) >= BegOfDay(vParentDoc.DateTimeTo) Then
								vGuestGroup = vParentDoc.GuestGroup;
								If Not IsGuestGroupActive(vGuestGroup, vEditProhibitedDate) Then
									pCancel = True;
								EndIf;
							EndIf;
						ElsIf TypeOf(vParentDoc) = Type("DocumentObject.SetRoomQuota") Then
							If BegOfDay(vEditProhibitedDate) >= BegOfDay(vParentDoc.DateTo) Then
								pCancel = True;
							EndIf;
						EndIf;
					Else
						pCancel = True;
					EndIf;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.CloseOfPeriod") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.CustomerAdvanceDistribution") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.CustomerPayment") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.EmployeeOperation") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.ProformaInvoice") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					If ValueIsFilled(pSource.ParentDoc) Then
						vParentDoc = pSource.ParentDoc;
						If TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or 
						   TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
							If BegOfDay(vEditProhibitedDate) >= BegOfDay(vParentDoc.CheckOutDate) Then
								vGuestGroup = pSource.GuestGroup;
								If Not IsGuestGroupActive(vGuestGroup, vEditProhibitedDate) Then
									pCancel = True;
								EndIf;
							EndIf;
						ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
							If BegOfDay(vEditProhibitedDate) >= BegOfDay(vParentDoc.DateTimeTo) Then
								vGuestGroup = pSource.GuestGroup;
								If Not IsGuestGroupActive(vGuestGroup, vEditProhibitedDate) Then
									pCancel = True;
								EndIf;
							EndIf;
						Else
							pCancel = True;
						EndIf;
					Else
						If ValueIsFilled(pSource.GuestGroup) Then
							vGuestGroup = pSource.GuestGroup;
							If Not IsGuestGroupActive(vGuestGroup, vEditProhibitedDate) Then
								pCancel = True;
							EndIf;
						Else
							pCancel = True;
						EndIf;
					EndIf;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.IssueHotelProducts") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.OperationSchedule") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.Payment") Or
				  TypeOf(pSource) = Type("DocumentObject.Return") Or 
				  TypeOf(pSource) = Type("DocumentObject.Storno") Then 
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					vParentDoc = pSource.ParentDoc;
					If ValueIsFilled(vParentDoc) And 
					  (TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or
					   TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or 
					   TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Or 
					   TypeOf(vParentDoc) = Type("DocumentRef.Folio")) Then
						vGuestGroup = vParentDoc.GuestGroup;
						If Not IsGuestGroupActive(vGuestGroup, vEditProhibitedDate) Then
							pCancel = True;
						EndIf;
					Else
						pCancel = True;
					EndIf;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.DepositTransfer") Or
			      TypeOf(pSource) = Type("DocumentObject.ChargeTransfer") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					vGuestGroupFrom = pSource.FolioFrom.GuestGroup;
					vGuestGroupTo = pSource.FolioTo.GuestGroup;
					If Not IsGuestGroupActive(vGuestGroupFrom, vEditProhibitedDate) And Not IsGuestGroupActive(vGuestGroupTo, vEditProhibitedDate) Then
						pCancel = True;
					EndIf;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.RecordPhoneCall") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.RecordRoomService") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.Settlement") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // HotelDocumentsCheckEditProhibitedDate

// -----------------------------------------------------------------------------
// Description: Checks company edit prohibition date for the documents
// Parameters: Document object, True if document couldn't be changed,
//             False if change is permitted
// Return value: None
// -----------------------------------------------------------------------------
Procedure CompanyDocumentsCheckEditProhibitedDate(pSource, pCancel) Export
	// Check company edit prohibited date and cancel operation if necessary
	If ValueIsFilled(pSource.Company) Then
		vEditProhibitedDate = pSource.Company.EditProhibitedDate;
		If ValueIsFilled(vEditProhibitedDate) Then
			If TypeOf(pSource) = Type("DocumentObject.CashIncome") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.CashOutcome") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.CloseOfCashRegisterDay") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.CloseOfPeriod") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.CustomerAdvanceDistribution") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.CustomerPayment") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.Payment") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.Return") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.ProformaInvoice") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			ElsIf TypeOf(pSource) = Type("DocumentObject.Settlement") Then
				If BegOfDay(vEditProhibitedDate) >= BegOfDay(pSource.Date) Then
					pCancel = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CompanyDocumentsCheckEditProhibitedDate

// -----------------------------------------------------------------------------
// Description: Documents before write event processing routine
// Parameters: Document object, True if document couldn't be changed,
//             False if change is permitted, Document write mode, Document
//             posting mode
// Return value: None
// -----------------------------------------------------------------------------
Procedure HotelDocumentsBeforeWriteEventsBeforeWrite(pSource, pCancel, pWriteMode, pPostingMode) Export
	If pSource.DataExchange.Load Then
		Return;
	EndIf;
	// Check hotel edit prohibited date and cancel operation if necessary
	HotelDocumentsCheckEditProhibitedDate(pSource, pCancel);
	// Check result
	If pCancel Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Document could not be edited because of edit prohibited date set for the hotel!';ru='Изменение документа запрещено, т.к. у гостиницы установлена дата запрета редактирования!';de='Die Änderung des Dokuments ist verboten, da im Hotel das Datum für das Redaktionsverbot festgelegt wurde!'"), MessageStatus.Important);
	EndIf;
EndProcedure // HotelDocumentsBeforeWriteEventsBeforeWrite

// -----------------------------------------------------------------------------
// Description: Documents before delete event processing routine
// Parameters: Document object, True if document couldn't be deleted,
//             False if deletion is permitted
// Return value: None
// -----------------------------------------------------------------------------
Procedure HotelDocumentsBeforeDeleteEventsBeforeDelete(pSource, pCancel) Export
	If pSource.DataExchange.Load Then
		Return;
	EndIf;
	// Check hotel edit prohibited date and cancel operation if necessary
	HotelDocumentsCheckEditProhibitedDate(pSource, pCancel);
	// Check result
	If pCancel Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Document could not be deleted because of edit prohibited date set for the hotel!';ru='Удаление документа запрещено, т.к. у гостиницы установлена дата запрета редактирования!';de='Löschung des Dokuments ist verboten, weil bei dem Hotel ein Bearbeitungsverbotsdatum definiert ist!'"), MessageStatus.Important);
	EndIf;
EndProcedure // HotelDocumentsBeforeDeleteEventsBeforeDelete

// -----------------------------------------------------------------------------
// Description: Company documents before write event processing routine
// Parameters: Document object, True if document couldn't be changed,
//             False if change is permitted, Document write mode, Document
//             posting mode
// Return value: None
// -----------------------------------------------------------------------------
Procedure CompanyDocumentsBeforeWriteEventsBeforeWrite(pSource, pCancel, pWriteMode, pPostingMode) Export
	If pSource.DataExchange.Load Then
		Return;
	EndIf;
	// Check company edit prohibited date and cancel operation if necessary
	CompanyDocumentsCheckEditProhibitedDate(pSource, pCancel);
	// Check result
	If pCancel Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Document could not be edited because of edit prohibited date set for the company!';ru='Изменение документа запрещено, т.к. у фирмы установлена дата запрета редактирования!';de='Die Änderung des Dokuments ist verboten, da in der Firma das Datum für das Redaktionsverbot festgelegt wurde!'"), MessageStatus.Important);
	EndIf;
EndProcedure // CompanyDocumentsBeforeWriteEventsBeforeWrite

// -----------------------------------------------------------------------------
// Description: Company documents before delete event processing routine
// Parameters: Document object, True if document couldn't be deleted,
//             False if deletion is permitted
// Return value: None
// -----------------------------------------------------------------------------
Procedure CompanyDocumentsBeforeDeleteEventsBeforeDelete(pSource, pCancel) Export
	If pSource.DataExchange.Load Then
		Return;
	EndIf;
	// Check company edit prohibited date and cancel operation if necessary
	CompanyDocumentsCheckEditProhibitedDate(pSource, pCancel);
	// Check result
	If pCancel Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Document could not be deleted because of edit prohibited date set for the company!';ru='Удаление документа запрещено, т.к. у фирмы установлена дата запрета редактирования!';de='Löschung des Dokuments ist verboten, weil bei der Firma ein Bearbeitungsverbotsdatum definiert ist!'"), MessageStatus.Important);
	EndIf;
EndProcedure // CompanyDocumentsBeforeDeleteEventsBeforeDelete

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSource		 - Null				 - Source
//  pCancel		 - Boolean			 - Cancel
//  pWriteMode	 - WriteMode		 - Write mode
//  pPostingMode - PostingModeUse	 - Posting mode use
//
Procedure ExchangePlanRecordChangesForDocuments(pSource, pCancel, pWriteMode, pPostingMode) Export
	If pSource.DataExchange.Load Then
		Return;
	EndIf;
	
	vMetadata = pSource.Metadata();
	
	Try
		Documents[vMetadata.Name].ExchangePlansRecordChanges(pSource);		
	Except 
	EndTry;
EndProcedure // ExchangePlanRecordChangesForDocuments

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSource	 - Null		 - Source
//  pCancel	 - Boolean	 - Cancel
//
Procedure ExchangePlanRecordChangesForObjects(pSource, pCancel) Export
	If pSource.DataExchange.Load Then
		Return;
	EndIf;
	
	vMetadata = pSource.Metadata();

	vFullNameArr = StrSplit(vMetadata.FullName(), ".", False);
	
	If vFullNameArr.Count() > 0 Then
		Try
			If vFullNameArr[0] = "Catalog" Then	
				Catalogs[vMetadata.Name].ExchangePlansRecordChanges(pSource);
			ElsIf vFullNameArr[0] = "ChartOfCharacteristicTypes" Then
				ChartsOfCharacteristicTypes[vMetadata.Name].ExchangePlansRecordChanges(pSource);	
			ElsIf vFullNameArr[0] = "ChartOfAccounts" Then
				ChartsOfAccounts[vMetadata.Name].ExchangePlansRecordChanges(pSource);	
			EndIf;
		Except
		EndTry;     
	EndIf;
EndProcedure // ExchangePlanRecordChangesForObjects

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSource	 - Null		 - Source
//  pCancel	 - Boolean	 - Cancel
//
Procedure ExchangePlanRecordChangesForRegisters(pSource, pCancel, pReplacing) Export
	If pSource.DataExchange.Load Then
		Return;
	EndIf;
	
	vMetadata = pSource.Metadata();
	
	vFullNameArr = StrSplit(vMetadata.FullName(), ".", False);
	
	If vFullNameArr.Count() > 0 Then
		Try
			If vFullNameArr[0] = "InformationRegister" Then 	
				InformationRegisters[vMetadata.Name].ExchangePlansRecordChanges(pSource);
			ElsIf vFullNameArr[0] = "AccountingRegister" Then
				AccountingRegisters[vMetadata.Name].ExchangePlansRecordChanges(pSource);	
			ElsIf vFullNameArr[0] = "AccumulationRegister" Then
				AccumulationRegisters[vMetadata.Name].ExchangePlansRecordChanges(pSource);	
			EndIf;
		Except
		EndTry;
	EndIf;
EndProcedure // ExchangePlanRecordChangesForRegisters

