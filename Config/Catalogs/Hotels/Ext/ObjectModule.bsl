
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DeletionMark And Not IsFolder Then
		If ValueIsFilled(IndividualsCustomer) And Not IndividualsCustomer.IsFolder And Not IndividualsCustomer.DeletionMark Then
			If Not IndividualsCustomer.IsIndividual Then
				vCustObj = IndividualsCustomer.GetObject();
				vCustObj.IsIndividual = True;
				Try
					vCustObj.Write();
				Except
				EndTry;
			EndIf;
		EndIf;
		// Clear hotel from billing instructions template folios
		For Each vCRRow In ChargingRules Do
			vChargingFolio = vCRRow.ChargingFolio;
			If ValueIsFilled(vChargingFolio) And ValueIsFilled(vChargingFolio.Hotel) And Not vChargingFolio.IsMaster Then
				vChargingFolioObj = vChargingFolio.GetObject();
				vTransCount = vChargingFolioObj.pmGetAllFolioTransactionsCount();
				If vTransCount = 0 Then
					vChargingFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
					vChargingFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
			If Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
				vCRRow.ChargingRuleValue = Undefined; // Need to clear empty values of some type (like empty Service group or Service)
			EndIf;
		EndDo;
		For Each vCRRow In CustomerChargingRules Do
			vChargingFolio = vCRRow.ChargingFolio;
			If ValueIsFilled(vChargingFolio) And ValueIsFilled(vChargingFolio.Hotel) And Not vChargingFolio.IsMaster Then
				vChargingFolioObj = vChargingFolio.GetObject();
				vTransCount = vChargingFolioObj.pmGetAllFolioTransactionsCount();
				If vTransCount = 0 Then
					vChargingFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
					vChargingFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
			If Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
				vCRRow.ChargingRuleValue = Undefined; // Need to clear empty values of some type (like empty Service group or Service)
			EndIf;
		EndDo;
		For Each vCRRow In ClientChargingRules Do
			vChargingFolio = vCRRow.ChargingFolio;
			If ValueIsFilled(vChargingFolio) And ValueIsFilled(vChargingFolio.Hotel) And Not vChargingFolio.IsMaster Then
				vChargingFolioObj = vChargingFolio.GetObject();
				vTransCount = vChargingFolioObj.pmGetAllFolioTransactionsCount();
				If vTransCount = 0 Then
					vChargingFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
					vChargingFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
			If Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
				vCRRow.ChargingRuleValue = Undefined; // Need to clear empty values of some type (like empty Service group or Service)
			EndIf;
		EndDo;
		For Each vCRRow In RoomChargingRules Do
			vChargingFolio = vCRRow.ChargingFolio;
			If ValueIsFilled(vChargingFolio) And ValueIsFilled(vChargingFolio.Hotel) And Not vChargingFolio.IsMaster Then
				vChargingFolioObj = vChargingFolio.GetObject();
				vTransCount = vChargingFolioObj.pmGetAllFolioTransactionsCount();
				If vTransCount = 0 Then
					vChargingFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
					vChargingFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
			If Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
				vCRRow.ChargingRuleValue = Undefined; // Need to clear empty values of some type (like empty Service group or Service)
			EndIf;
		EndDo;
	EndIf;    
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Initialize default parameters
	ShowSalesInReportsWithVAT = True;
	DoNotEditSettledDocs = True;
EndProcedure // pmFillAttributesWithDefaultValues

// See Catalogs.Hotels. --------------------------------------------------------
Function pmGetHotelPrintName(pLang) Export     
	Return Catalogs.Hotels.pmGetHotelPrintName(Ref, pLang); 
EndFunction // pmGetHotelPrintName

// See Catalogs.Hotels. --------------------------------------------------------
Function pmGetHotelPostAddressPresentation(pLang) Export     
	Return Catalogs.Hotels.pmGetHotelPostAddressPresentation(Ref, pLang);
EndFunction // pmGetHotelPostAddressPresentation

// See Catalogs.Hotels. --------------------------------------------------------
Function pmGetHotelHowToDriveToTheHotelDescription(pLang) Export
	Return Catalogs.Hotels.pmGetHotelHowToDriveToTheHotelDescription(Ref, pLang);
EndFunction // pmGetHotelHowToDriveToTheHotelDescription

// See Catalogs.Hotels. --------------------------------------------------------
Function pmGetHotelReservationDivisionContacts(pLang) Export
	Return Catalogs.Hotels.pmGetHotelReservationDivisionContacts(Ref, pLang);
EndFunction // pmGetHotelReservationDivisionContacts

// See Catalogs.Hotels. --------------------------------------------------------
Function pmGetHotelSalesDivisionContacts(pLang) Export
	Return Catalogs.Hotels.pmGetHotelSalesDivisionContacts(ThisObject, pLang);
EndFunction // pmGetHotelSalesDivisionContacts

// See Catalogs.Hotels. --------------------------------------------------------
Function pmGetNonReplicatingAttributes() Export               
	Return Catalogs.Hotels.pmGetNonReplicatingAttributes(Ref);
EndFunction // pmGetNonReplicatingAttributes

// See Catalogs.Hotels. --------------------------------------------------------
Function pmGetPrefix() Export
	Return Catalogs.Hotels.pmGetPrefix(Ref);
EndFunction // pmGetPrefix

// See Catalogs.Hotels. --------------------------------------------------------
// 
// Returns:
//  CatalogRef.Hotels - ref hotel guest group folder 
//
Function pmGetGuestGroupFolder() Export
	Return Catalogs.Hotels.pmGetGuestGroupFolder(Ref);
EndFunction // pmGetGuestGroupFolder

#EndRegion
