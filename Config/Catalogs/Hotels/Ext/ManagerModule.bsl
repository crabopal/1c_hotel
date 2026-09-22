
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure FormGetProcessing(pFormType, pParameters, pSelectedForm, pAdditionalInformation, pStandardProcessing)
	SetPrivilegedMode(True);
	vCurSession = GetCurrentInfoBaseSession();
	SetPrivilegedMode(False);
	vSessionNumber = vCurSession.SessionNumber;
	vSessionStartTime = vCurSession.SessionStarted;
	vAppRunMode = CachedCommonFunctions.cmGetAppRunMode(vSessionNumber, vSessionStartTime);
	If vAppRunMode.MobileDeviceMode Then 
		If pFormType = "ListForm" Or pSelectedForm = "tcListForm" Then
			pStandardProcessing = False;
			pSelectedForm = "mcListForm";
		ElsIf pFormType = "ChoiceForm" Or pSelectedForm = "tcChoiceForm" Then
          	pStandardProcessing = False;
			pSelectedForm = "mcChoiceForm";
		EndIf; 
	EndIf;
EndProcedure // FormGetProcessing 

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
// 
// Returns:
//  ValueList - List hotels allowed
//
Function GetHotelAllowedList() Export 
	vList = New ValueList;
	vPermissionGroups = SessionParameters.CurrentUser.PermissionGroup;
	If Not vPermissionGroups.IsEmpty() Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	PermissionGroupsHotelAllowed.Hotel
		|FROM
		|	Catalog.PermissionGroups.HotelAllowed AS PermissionGroupsHotelAllowed
		|WHERE
		|	PermissionGroupsHotelAllowed.Ref = &qRefPermissionGroups
		|
		|GROUP BY
		|	PermissionGroupsHotelAllowed.Hotel";
		
		vQuery.SetParameter("qRefPermissionGroups", vPermissionGroups);
		
		QueryResult = vQuery.Execute();
		
		vTrans = QueryResult.Select();
		
		While vTrans.Next() Do
			vList.Add(vTrans.Hotel);
		EndDo;
	EndIf;
	Return vList;
EndFunction // GetHotelAllowedList()

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
//  pLang	 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Print name
//
Function pmGetHotelPrintName(pHotel, pLang) Export     
	If pHotel.IsFolder Then
		Return TrimAll(pHotel.Description);
	EndIf;
	If Not ValueIsFilled(pLang) Then
		Return TrimAll(pHotel.PrintName);
	EndIf;
	If IsBlankString(pHotel.PrintNameTranslations) Then
		Return TrimAll(pHotel.PrintName);
	EndIf;
	Return TrimAll(cmNStr(pHotel.PrintNameTranslations, pLang));
EndFunction // pmGetHotelPrintName

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
//  pLang	 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Post address presentation
//
Function pmGetHotelPostAddressPresentation(pHotel, pLang) Export
	vPostAddress = "";
	If Not ValueIsFilled(pLang) Then
		vPostAddress = TrimAll(pHotel.PostAddress);
	Else
		If IsBlankString(pHotel.PostAddressTranslations) Then
			vPostAddress = TrimAll(pHotel.PostAddress);
		Else
			vPostAddress = TrimAll(cmNStr(pHotel.PostAddressTranslations, pLang));
		EndIf;
	EndIf;
	Return cmGetAddressPresentation(vPostAddress);
EndFunction // pmGetHotelPostAddressPresentation

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
//  pLang	 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - How to drive to the hotel description
//
Function pmGetHotelHowToDriveToTheHotelDescription(pHotel, pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(pHotel.HowToDriveToTheHotel);
	Else
		If IsBlankString(pHotel.HowToDriveToTheHotelTranslations) Then
			vDescr = TrimAll(pHotel.HowToDriveToTheHotel);
		Else
			vDescr = TrimAll(cmNStr(pHotel.HowToDriveToTheHotelTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetHotelHowToDriveToTheHotelDescription

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
//  pLang	 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Reservation division
//
Function pmGetHotelReservationDivisionContacts(pHotel, pLang) Export
	vCont = "";
	If Not ValueIsFilled(pLang) Then
		vCont = TrimAll(pHotel.ReservationDivisionContacts);
	Else
		If IsBlankString(pHotel.ReservationDivisionContactsTranslations) Then
			vCont = TrimAll(pHotel.ReservationDivisionContacts);
		Else
			vCont = TrimAll(cmNStr(pHotel.ReservationDivisionContactsTranslations, pLang));
		EndIf;
	EndIf;
	Return vCont;
EndFunction // cmGetHotelReservationDivisionContacts

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
//  pLang	 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Sales division
//
Function pmGetHotelSalesDivisionContacts(pHotel, pLang) Export
	vCont = "";
	If Not ValueIsFilled(pLang) Then
		vCont = TrimAll(pHotel.SalesDivisionContacts);
	Else
		If IsBlankString(pHotel.SalesDivisionContactsTranslations) Then
			vCont = TrimAll(pHotel.SalesDivisionContacts);
		Else
			vCont = TrimAll(cmNStr(pHotel.SalesDivisionContactsTranslations, pLang));
		EndIf;
	EndIf;
	Return vCont;
EndFunction // pmGetHotelSalesDivisionContacts

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  ValueTable - Replicating attributes
//
Function pmGetNonReplicatingAttributes(pHotel) Export
	Return CachedSettings.cmGetNonReplicatingHotelAttributes(pHotel);
EndFunction // pmGetNonReplicatingAttributes

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref 
// 
// Returns:
//  String - Prefix
//
Function pmGetPrefix(pHotel) Export
	vAttrs = pmGetNonReplicatingAttributes(pHotel);
	If vAttrs.Count() = 0 Then
		Return TrimAll(pHotel.Prefix);
	Else
		vAttrsRow = vAttrs.Get(0);
		Return TrimAll(vAttrsRow.Prefix);
	EndIf;
EndFunction // pmGetPrefix

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref 
// 
// Returns:
//  CatalogRef.Hotels - ref hotel guest group folder
//
Function pmGetGuestGroupFolder(pHotel) Export
	vAttrs = pmGetNonReplicatingAttributes(pHotel);
	If vAttrs.Count() = 0 Then
		Return pHotel.GuestGroupFolder;
	Else
		vAttrsRow = vAttrs.Get(0);
		Return vAttrsRow.GuestGroupFolder;
	EndIf;
EndFunction // pmGetGuestGroupFolder

#EndRegion
