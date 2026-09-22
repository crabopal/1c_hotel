// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vCurUser = SessionParameters.CurrentUser;
		If ValueIsFilled(vCurUser.Customer) Then
			SelCustomer = vCurUser.Customer;
			If SelCustomer.IsFolder Then
				AttributeChangeAtServer("Customer", SelCustomer, DataCompositionComparisonType.InHierarchy);
			Else
				AttributeChangeAtServer("Customer", SelCustomer);
			EndIf;
			Items.SelCustomer.ReadOnly = True;
			Items.SelCustomer.ChoiceButton = False;
			Items.SelCustomer.ClearButton = False;
			Items.SelCustomer.OpenButton = False;
		EndIf;
		If ValueIsFilled(vCurUser.RoomType) Then
			SelRoomType = vCurUser.RoomType;
			If SelRoomType.IsFolder Then
				AttributeChangeAtServer("RoomType", SelRoomType, DataCompositionComparisonType.InHierarchy);
			Else
				AttributeChangeAtServer("RoomType", SelRoomType);
			EndIf;
		EndIf;
	EndIf;
	// Current hotel
	SelHotel = SessionParameters.CurrentHotel;
	// Register foreigners action availability
	vRegForeignerObjectFormAction = Catalogs.ObjectFormActions.AccommodationOpenForeignerRegistryRecord;
	If vRegForeignerObjectFormAction.DeletionMark Or Not vRegForeignerObjectFormAction.IsActive Then
		Items.DocumentListIsInHouseFormOpenForeignerRegistryRecord.Visible = False;
		Items.DocumentListAllFormOpenForeignerRegistryRecord.Visible = False;
	EndIf;
	// Scan documents action availability
	vScansObjectFormAction = Catalogs.ObjectFormActions.AccommodationScanClientData;
	// Other parameters
	If Parameters.Property("Room") Then
		SelRoom = Parameters.Room;
		If ValueIsFilled(SelRoom) Then
			AttributeChangeAtServer("Room", SelRoom);   
		EndIf;
	EndIf;
	If Parameters.Property("Client") Then
		SelClient = Parameters.Client;
		If ValueIsFilled(SelClient) Then
			AttributeChangeAtServer("Guest", SelClient);  
		EndIf;
	EndIf;
	If Parameters.Property("Customer") Then
		SelCustomer = Parameters.Customer;
		If ValueIsFilled(SelCustomer) Then
			AttributeChangeAtServer("Customer", SelCustomer);  
		EndIf;
	EndIf;
	If Parameters.Property("RoomType") Then
		SelRoomType = Parameters.RoomType;
		If ValueIsFilled(SelRoomType) Then
			AttributeChangeAtServer("RoomType", SelRoomType);   
		EndIf;
	EndIf;
	If Parameters.Property("SelGuestGroup") Then
		SelGuestGroup = Parameters.SelGuestGroup;
		If ValueIsFilled(SelGuestGroup) Then
			AttributeChangeAtServer("GuestGroup", SelGuestGroup);
		EndIf;
	EndIf;
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		Items.DocumentListAll.ChoiceMode = True;
		Items.DocumentListIsInHouse.ChoiceMode = True;
		Items.DocumentListReservation.ChoiceMode = True;
	EndIf;
	// Fill list types
	If Parameters.Property("SelFilterStatus") Then
		SelFilterStatus = Parameters.SelFilterStatus;
	Else
		SelFilterStatus = 2; // Reservation list is default
	EndIf;
	If Parameters.Property("SelShowAllGuests") Then
		SelShowAllGuests = Parameters.SelShowAllGuests;
	ElsIf SelFilterStatus = 2 Then
		vShowExpectedCheckInListByGuestsByDefault = cmCheckUserPermissions("ShowExpectedCheckInListByGuestsByDefault");
		If vShowExpectedCheckInListByGuestsByDefault Then
			SelShowAllGuests = 1;
		EndIf;
	EndIf;
	// Show only main room guests by default
	AllGuestsOnChangeAtServer();
	// Fill functions
	FillFunctionsButtonReservation();
	FillFunctionsButtonAccommodation();
	// Fill printing forms
	FillPrintingButtonReservation();
	FillPrintingButtonAccommodation();
	// Check if we need to run guests auto extend of period of stay
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		RunInHouseGuestsPeriodOfStayAutoExtension = SessionParameters.CurrentWorkstation.RunInHouseGuestsPeriodOfStayAutoExtension;
		InHouseGuestsPeriodOfStayAutoExtensionFrequency = SessionParameters.CurrentWorkstation.InHouseGuestsPeriodOfStayAutoExtensionFrequency;
	Else
		RunInHouseGuestsPeriodOfStayAutoExtension = False;
		InHouseGuestsPeriodOfStayAutoExtensionFrequency = 0;
	EndIf;
	// Skip first on row activate event
	SkipOnRowActivateEvent = True;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure OnReopenAtServer()
	// Filter by parameters
	If Parameters.Property("Room") And ValueIsFilled(Parameters.Room) Then
		SelRoom = Parameters.Room;
		AttributeChangeAtServer("Room", SelRoom);   
	EndIf;
	If Parameters.Property("RoomType") And ValueIsFilled(Parameters.RoomType) Then
		SelRoomType = Parameters.RoomType;
		AttributeChangeAtServer("RoomType", SelRoomType);   
	EndIf;
	If Parameters.Property("SelGuestGroup") And ValueIsFilled(Parameters.SelGuestGroup) Then
		SelGuestGroup = Parameters.SelGuestGroup;
		AttributeChangeAtServer("GuestGroup", SelGuestGroup);
	EndIf;
EndProcedure // OnReopenAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	OnReopenAtServer();
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
&AtServer
Procedure AllGuestsOnChangeAtServer()
	SetParametersDynamicList();
	If SelShowAllGuests = 1  Then
		// Reservation
		Items.DocumentListReservationAccommodationType.Visible = True;
		Items.DocumentListReservationAccommodationTemplate.Visible = False;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListReservation,"AccommodationTemplate",,,,False);
		// DocumentListArhive
		Items.DocumentListAllAccommodationType.Visible = True;
		Items.DocumentListAllAccommodationTemplate.Visible = False;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListALL,"AccommodationTemplate",,,,False);
		// DocumentListIsInHouse
		Items.DocumentListIsInHouseAccommodationType.Visible = True;
		Items.DocumentListIsInHouseAccommodationTemplate.Visible = False;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListIsInHouse,"AccommodationTemplate",,,,False);
	Else
		// Reservation
		Items.DocumentListReservationAccommodationType.Visible = False;
		Items.DocumentListReservationAccommodationTemplate.Visible = True;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListReservation,"AccommodationTemplate",Catalogs.AccommodationTemplates.EmptyRef(),DataCompositionComparisonType.NotEqual,,True);
		// DocumentListArhive
		Items.DocumentListAllAccommodationType.Visible = False;
		Items.DocumentListAllAccommodationTemplate.Visible = True;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListALL,"AccommodationTemplate",Catalogs.AccommodationTemplates.EmptyRef(),DataCompositionComparisonType.NotEqual,,True);
		// DocumentListIsInHouse
		Items.DocumentListIsInHouseAccommodationType.Visible = False;
		Items.DocumentListIsInHouseAccommodationTemplate.Visible = True;
	    tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(DocumentListIsInHouse,"AccommodationTemplate",Catalogs.AccommodationTemplates.EmptyRef(),DataCompositionComparisonType.NotEqual,,True);
	EndIf; 
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AllGuestsOnChange(Item)
	AllGuestsOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(Item)
	CheckInDateOnChangeAtServer();
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInDateOnChangeAtServer()
	If SelFilterStatus = 0 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;	
	If Not ValueIsFilled(SelCheckInDate) Then
		If SelFilterStatus = 2 Then
			vAccountingDate = BegOfDay(?(ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.AccountingDate), SelHotel.AccountingDate, CurrentSessionDate()));
			DocumentListReservation.Parameters.SetParameterValue("qDateTo", EndOfDay(vAccountingDate));
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], "BegOfCheckInDate", vAccountingDate, DataCompositionComparisonType.LessOrEqual, , True);
		Else															
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], "BegOfCheckInDate", , , , False);
		EndIf;
	Else
		If SelCheckInDate > '20991231' Or SelCheckInDate < '20091231' Then
			SelCheckInDate = CurrentSessionDate();
		EndIf;
		If SelFilterStatus = 2 Then
			DocumentListReservation.Parameters.SetParameterValue("qDateTo", EndOfDay(SelCheckInDate));
		EndIf;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisObject[vPage], "BegOfCheckInDate", BegOfDay(SelCheckInDate), DataCompositionComparisonType.Equal, , True);
	EndIf;
EndProcedure // CheckInDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(Item)
	CheckOutDateOnChangeAtServer();
EndProcedure // CheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutDateOnChangeAtServer()
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;
	If Not ValueIsFilled(SelCheckOutDate) Then
		If SelFilterStatus = 3 Then
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisForm[vPage], "BegOfCheckOutDate", BegOfDay(?(ValueIsFilled(SelHotel) And ValueIsFilled(SelHotel.AccountingDate), SelHotel.AccountingDate, CurrentSessionDate())), DataCompositionComparisonType.LessOrEqual, , True);
		Else	
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisForm[vPage], "BegOfCheckOutDate", , , , False);
		EndIf;
	Else	
		If SelCheckOutDate > '20991231' Or SelCheckOutDate < '20091231' Then
			SelCheckOutDate = CurrentSessionDate();
		EndIf;
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisForm[vPage], "BegOfCheckOutDate", BegOfDay(SelCheckOutDate), DataCompositionComparisonType.Equal, , True);
	EndIf;
EndProcedure // CheckOutDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterStatusOnChange(pItem)
	FilterStatusOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FilterStatusOnChangeAtServer(pCheckOutDate = Undefined)
	If SelFilterStatus = 1 Then
		Items.SelectArrivals.Check = False;
		Items.SelectDepartures.Check = False;
		Items.SelectInHouse.Check = False;
		Items.SelectArchive.Check = True;
		// Accommodations archive
		Items.GroupPages.CurrentPage = Items.GroupArchive;
		// Printing forms and actions
		ShowExpectedRoomMovesOnly = False;
		Items.ShowExpectedRoomMovesOnly.Visible					= False;
		// Settings
		Items.DocumentListInHouseSettings.Visible 				= False;
		Items.DocumentListInHouseOutputList.Visible		 		= False;
		Items.DynamicListAllListSettings.Visible 				= True;
		Items.DynamicListAllOutputList.Visible 					= True;
		Items.DynamicListReservationListSettings.Visible 		= False;
		Items.DynamicListReservationOutputList.Visible 			= False;
		// Commands
		Items.DocumentListCreate.Visible 						= True;
		Items.DocumentListCreate.DefaultButton 					= True;
		Items.NewReservation.Visible 							= False;
		Items.NewReservation.DefaultButton 						= False;
		// Do not rebuild inactive lists
		DocumentListReservation.Parameters.SetParameterValue("qGenerateList", False);
		DocumentListIsInHouse.Parameters.SetParameterValue("qGenerateList", False);
		DocumentListALL.Parameters.SetParameterValue("qGenerateList", True);
	ElsIf SelFilterStatus = 2 Then
		Items.SelectArrivals.Check = True;
		Items.SelectDepartures.Check = False;
		Items.SelectInHouse.Check = False;
		Items.SelectArchive.Check = False;
		// Expected arrivals
		Items.GroupPages.CurrentPage = Items.GroupReservation;
		// Settings
		Items.DocumentListInHouseSettings.Visible 				= False;
		Items.DocumentListInHouseOutputList.Visible		 		= False;
		Items.DynamicListAllListSettings.Visible 				= False;
		Items.DynamicListAllOutputList.Visible 					= False;
		Items.DynamicListReservationListSettings.Visible 		= True;
		Items.DynamicListReservationOutputList.Visible 			= True;
		ShowExpectedRoomMovesOnly = False;
		Items.ShowExpectedRoomMovesOnly.Visible					= False;
		// Commands
		Items.DocumentListCreate.Visible 						= False;
		Items.DocumentListCreate.DefaultButton 					= False;
		Items.NewReservation.Visible 							= True;
		Items.NewReservation.DefaultButton 						= True;
		// Do not rebuild inactive lists
		DocumentListReservation.Parameters.SetParameterValue("qGenerateList", True);
		DocumentListIsInHouse.Parameters.SetParameterValue("qGenerateList", False);
		DocumentListALL.Parameters.SetParameterValue("qGenerateList", False);
	Else 
		// 0 - In house guests or 3 - Expected Departure 
		Items.GroupPages.CurrentPage = Items.GroupInHouse;
		Items.DocumentListCreate.Visible 						= True;
		// Settings
		Items.DocumentListInHouseSettings.Visible 				= True;
		Items.DocumentListInHouseOutputList.Visible		 		= True;
		Items.DynamicListAllListSettings.Visible 				= False;
		Items.DynamicListAllOutputList.Visible 					= False;
		Items.DynamicListReservationListSettings.Visible 		= False;
		Items.DynamicListReservationOutputList.Visible 			= False;
		If SelFilterStatus = 3 Then
			ShowExpectedRoomMovesOnly = False;
			Items.ShowExpectedRoomMovesOnly.Visible				= False;
			Items.SelectArrivals.Check = False;
			Items.SelectDepartures.Check = True;
			Items.SelectInHouse.Check = False;
			Items.SelectArchive.Check = False;
		Else
			Items.ShowExpectedRoomMovesOnly.Visible				= True;
			DocumentListIsInHouse.Parameters.SetParameterValue("qShowExpectedRoomMovesOnly", ShowExpectedRoomMovesOnly);
			Items.SelectArrivals.Check = False;
			Items.SelectDepartures.Check = False;
			Items.SelectInHouse.Check = True;
			Items.SelectArchive.Check = False;
		EndIf;
		// Commands
		Items.NewReservation.Visible 							= False;
		Items.NewReservation.DefaultButton 						= False;
		If SelFilterStatus = 3 Then
			Items.DocumentListCreate.Visible 					= False;
		Else	
			Items.DocumentListCreate.Visible 					= True;
			Items.DocumentListCreate.DefaultButton 				= True;
		EndIf;
		// Do not rebuild inactive lists
		DocumentListReservation.Parameters.SetParameterValue("qGenerateList", False);
		DocumentListIsInHouse.Parameters.SetParameterValue("qGenerateList", True);
		DocumentListALL.Parameters.SetParameterValue("qGenerateList", False);
	EndIf;
	CheckInDateOnChangeAtServer();
	CheckOutDateOnChangeAtServer();
	If ValueIsFilled(SelRoom) Then
		AttributeChangeAtServer("Room", SelRoom);
	Else
		ClearingAttributeAtServer("Room");
	EndIf;
	If ValueIsFilled(SelRoomType) Then
		AttributeChangeAtServer("RoomType", SelRoomType);
	Else
		ClearingAttributeAtServer("RoomType");
	EndIf;
	If ValueIsFilled(SelCustomer) Then
		AttributeChangeAtServer("Customer", SelCustomer);
	Else
		ClearingAttributeAtServer("Customer");
	EndIf;
	If ValueIsFilled(SelAgent) Then
		AttributeChangeAtServer("Agent", SelAgent);
	Else
		ClearingAttributeAtServer("Agent");
	EndIf;
	If ValueIsFilled(SelClient) Then
		AttributeChangeAtServer("Guest", SelClient);
	Else
		ClearingAttributeAtServer("Guest");
	EndIf;
	If ValueIsFilled(SelGuestGroup) Then
		AttributeChangeAtServer("GuestGroup", SelGuestGroup);
	Else
		ClearingAttributeAtServer("GuestGroup");
	EndIf;
	If pCheckOutDate <> Undefined Then
		SelCheckOutDate = pCheckOutDate;
		If ValueIsFilled(SelCheckOutDate) And (SelFilterStatus = 0  Or SelFilterStatus = 3) Then
			AttributeChangeAtServer("CheckOutDate", SelCheckOutDate, DataCompositionComparisonType.LessOrEqual);
		EndIf;
	EndIf;
EndProcedure // FilterStatusOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetMainDocRef(pRef)
	// Fill one room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref,
	|	Accommodation.Guest AS GuestRef
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.GuestGroup = &qGroup
	|	AND (Accommodation.Room = &qRoom
	|				AND &qRoomIsFilled
	|			OR Accommodation.Number = &qNumber
	|				AND NOT &qRoomIsFilled)
	|	AND Accommodation.Posted
	|	AND NOT Accommodation.DeletionMark
	|	AND ((Accommodation.AccommodationStatus.IsActive
	|			OR Accommodation.AccommodationStatus.IsCheckIn)
	|		OR	(Accommodation.AccommodationStatus = &qAccStatus))
	|ORDER BY
	|	Accommodation.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pRef.GuestGroup);
	vQry.SetParameter("qRoom", pRef.Room);
	vQry.SetParameter("qAccStatus", pRef.AccommodationStatus);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRef.Room));
	vQry.SetParameter("qNumber", pRef.Number);
	vQryResult = vQry.Execute().Unload();
	If vQryResult.Count() > 0 Then
		Return vQryResult.Get(0).Ref;
	EndIf;
	Return pRef;
EndFunction // GetMainDocRef

// -----------------------------------------------------------------------------
&AtServer
Procedure AddOneRoomAccommodations(pAccList, pDocRef)
	vOneRoomDocs = cmGetOneRoomAccommodations(pDocRef.Room, pDocRef.GuestGroup, pDocRef.CheckInDate, pDocRef.CheckOutDate);
	For Each vOneRoomDocsRow In vOneRoomDocs Do
		If pAccList.FindByValue(vOneRoomDocsRow.Ref) = Undefined Then
			pAccList.Add(vOneRoomDocsRow.Ref);
		EndIf;
	EndDo;
EndProcedure // AddOneRoomAccommodations

// -----------------------------------------------------------------------------
&AtClient
Function ExtractTime(pDateTime)
	vTime = Date(1, 1, 1, Hour(pDateTime), Minute(pDateTime), 0);
	Return vTime;
EndFunction // ExtractTime

// -----------------------------------------------------------------------------
&AtClient
Procedure GetCheckOutDate(pCheckInDate, pCheckOutDate)
	vCheckOutDateTime = CurrentDate();
	If vCheckOutDateTime < pCheckInDate Then
		vCheckOutDateTime = pCheckInDate;
	EndIf;
	vDate = BegOfDay(CurrentDate());
	vTime = ExtractTime(CurrentDate());
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToUseReferenceHourAsDefaultCheckOutTime") Then
		vDate = BegOfDay(CurrentDate());
		If BegOfDay(pCheckOutDate) = BegOfDay(CurrentDate()) Then
			If CurrentDate() < pCheckOutDate Then
				vTime = ExtractTime(CurrentDate());
			Else
				vTime = ExtractTime(pCheckOutDate);
			EndIf;
		Else
			vTime = ExtractTime(pCheckOutDate);
		EndIf;
	EndIf;
	vDescription = NStr("en = 'Check-out time:'; de = 'Abreisezeit:'; ru = 'Время выселения:'");
	vIsProtected = False;
	vDateIsProtected = False;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCheckOutDateTime") Then
		vIsProtected = True;
	Else
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetCheckOutDateInThePast") Then
			vDateIsProtected = True;
		EndIf;
	EndIf;
	vParams = New Structure("FillingValues", New Structure("Date, Time, Description, IsProtected, DateIsProtected", vDate, vTime, vDescription, vIsProtected, vDateIsProtected));
	OpenForm("CommonForm.tcInputDateTime", vParams, ThisForm, , , , New NotifyDescription("GetCheckOutDateAfterUserInput", ThisForm, New Structure("CheckInDate, CheckOutDate", pCheckInDate, pCheckOutDate)), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // GetCheckOutDate

// -----------------------------------------------------------------------------
&AtClient
Procedure GetCheckOutDateAfterUserInput(pCheckOutDateTime, pExtraParameters) Export
	CheckOutDateTime = '00010101';
	// Check check out date and time entered
	If Not ValueIsFilled(pCheckOutDateTime) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Процедура выселения отменена!';
		                      |de='Das Ausweisungsverfahren wurde abgebrochen'; 
						      |en='Check-out procedure is canceled!'"));
		Return;
	EndIf;
	If pCheckOutDateTime < pExtraParameters.CheckInDate Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Ввели дату и время выселения, которые раньше чем дата и время заезда!';
		                      |de='Sie haben ein Abreisedatum und eine Abreisezeit eingegeben, die vor dem Anreisedatum und der Anreisezeit liegen!'; 
						      |en='You have entered check-out date and time that are earlier then check-in date and time!'"));
		Return;
	EndIf;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetCheckOutDateInThePast") Then
		vAllowedCheckOutDelayTime = 1;
		If ValueIsFilled(tcOnServer.cmGetCurrentUserAttribute()) Then
			vPermissionGroup = tcOnServer.cmGetEmployeePermissionGroupAtServer(tcOnServer.cmGetCurrentUserAttribute());
			If ValueIsFilled(vPermissionGroup) Then
				If tcOnServer.cmGetAttributeByRef(vPermissionGroup, "AllowedCheckOutDelayTime") > 0 Then
					vAllowedCheckOutDelayTime = tcOnServer.cmGetAttributeByRef(vPermissionGroup, "AllowedCheckOutDelayTime");
				EndIf;
			EndIf;
		EndIf;
		vTimeDiff = Round((CurrentDate() - pCheckOutDateTime)/3600, 3);
		If vTimeDiff > vAllowedCheckOutDelayTime Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Ввели дату выселения в прошлом. Есть права на выселение только текущей или будущей датой!';
			                      |de='Sie haben ein Räumungsdatum angegeben, das in der Vergangenheit liegt. Sie sind berechtigt, eine Räumung nur am aktuellen oder künftigen Datum vorzunehmen!'; 
			                      |en='You have entered check-out date in the past. You have rights to do check-out by current or future dates only!'"));
			Return;
		EndIf;
	EndIf;
	CheckOutDateTime = pCheckOutDateTime;
EndProcedure // GetCheckOutDateAfterUserInput

// -----------------------------------------------------------------------------
// Check if there are future reservations in chain
// -----------------------------------------------------------------------------
&AtServer
Function CheckFutureReservationsAtServer(pCurDoc, pCheckOutDate)
	vMessage = "";
	If ValueIsFilled(pCurDoc.AccommodationType) And 
	  (pCurDoc.AccommodationType.Type = Enums.AccomodationTypes.Room Or pCurDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds) Then
		vParentReservation = pCurDoc.GetObject().pmGetParentReservation();
		If ValueIsFilled(vParentReservation) Then
			vParentReservationObj = vParentReservation.GetObject();
			vNextReservationInChain = vParentReservationObj.pmGetNextReservationInChain();
			While ValueIsFilled(vNextReservationInChain) Do
				If ValueIsFilled(vNextReservationInChain.ReservationStatus) And vNextReservationInChain.ReservationStatus.IsActive Then
					If BegOfDay(vNextReservationInChain.CheckInDate) >= BegOfDay(pCheckOutDate) Then
						vMessage = NStr("en='Guest &Guest has active reservation period from &CheckInDate to &CheckOutDate!';
						                |ru='У гостя &Guest есть действующая бронь на период с &CheckInDate по &CheckOutDate!';
								        |de='Gast &Guest hat aktive Reservierungszeit von & CheckInDate zu &CheckOutDate!'");
						vMessage = StrReplace(vMessage, "&Guest", TrimAll(vNextReservationInChain.GuestFullName));
						vMessage = StrReplace(vMessage, "&CheckInDate", Format(vNextReservationInChain.CheckInDate, "DF=dd.MM.yyyy"));
						vMessage = StrReplace(vMessage, "&CheckOutDate", Format(vNextReservationInChain.CheckOutDate, "DF=dd.MM.yyyy"));
						Break;
					EndIf;
				Else
					Break;
				EndIf;
				vNextReservationInChain = vNextReservationInChain.GetObject().pmGetNextReservationInChain();
			EndDo;
		EndIf;
	EndIf;
	Return vMessage;
EndFunction // CheckFutureReservationsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOut(pCommand)
	vPage = "";
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else
		Return;
	EndIf;
	vSelDocRef = Items[vPage].CurrentRow;
	If vSelDocRef <> Undefined Then
		If SelShowAllGuests = 0 Then
			MainRoomDoc = GetMainDocRef(vSelDocRef);
		Else
			MainRoomDoc = vSelDocRef;
		EndIf;
		// Give warning if current date is less then expected check-out date
		vCheckInDate = tcOnServer.cmGetAttributeByRef(MainRoomDoc, "CheckInDate");
		vExpectedCheckOutDate = tcOnServer.cmGetAttributeByRef(MainRoomDoc, "CheckOutDate");
		If BegOfDay(vExpectedCheckOutDate) > BegOfDay(CurrentDate()) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Expected check-out date " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
				         |de='Expected check-out date " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
				         |ru='Дата планируемого выезда " + Format(vExpectedCheckOutDate, "DF=dd.MM.yyyy") + " в будущем!'"), MessageStatus.Important);
		EndIf;
		// Get check-out date
		CheckOutDateTime = '00010101';
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
			GetCheckOutDate(vCheckInDate, vExpectedCheckOutDate);
			AttachIdleHandler("CheckIfCheckOutDateTimeIsFilled", 1, False);
		Else
			CheckOutDateTime = vExpectedCheckOutDate;
			AttachIdleHandler("CheckIfCheckOutDateTimeIsFilled", 0.1, True);
		EndIf;
	EndIf;
EndProcedure // CheckOut

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckIfCheckOutDateTimeIsFilled()
	If ValueIsFilled(CheckOutDateTime) And ValueIsFilled(MainRoomDoc) Then
		DetachIdleHandler("CheckIfCheckOutDateTimeIsFilled");
		
		// Get current documents list name
		vPage = "";
		If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
			vPage = "DocumentListIsInHouse";
		ElsIf SelFilterStatus = 1 Then
			vPage = "DocumentListAll";
		Else
			Return;
		EndIf;
		
		// Add other selected documents
		AccList.Clear();
		For Each vSelDocRef In Items[vPage].SelectedRows Do
			// Check future reservations
			vMessage = CheckFutureReservationsAtServer(vSelDocRef, CheckOutDateTime);
			If Not IsBlankString(vMessage) Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			EndIf;
			
			// Add document to the list of documents to be checked out
			If SelShowAllGuests = 0 Then
				AddOneRoomAccommodations(AccList, vSelDocRef);
			Else
				AccList.Add(vSelDocRef);
			EndIf;
		EndDo;
		
		// Do check-out in a background job
		vOperationName = NStr("en='Checking-out guests'; ru='Выселение гостей'; de='Gästen abreise'");
		
		ListOfMessages.Clear();
		
		vParameters = New Array;
		vParameters.Add(SelHotel);
		vParameters.Add(AccList);
		vParameters.Add(CheckOutDateTime);
		vParameters.Add(False);
		vParameters.Add(tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToCheckOutOnExpectedCheckOutTime"));
		vParameters.Add(tcOnServer.cmGetCurrentUserAttribute());
		
		vBackgroundJob = AsyncCalls.StartBackgroundJobWithRecordInRegister(SelHotel, vOperationName, "ProlongedOperations.AccommodationsList_CheckOut", vParameters);
		CurrentBackgroundJobUUID = vBackgroundJob.UUID;
		
		AttachIdleHandler("Attachable_CheckBackgroundJobs", 1, False);
	
		CheckInOut_ShowProgressBar(vOperationName);
	Else
		Return;
	EndIf;
EndProcedure // CheckIfCheckOutDateTimeIsFilled

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	vBackgroundJob = CheckBackgroundJobStatus(CurrentBackgroundJobUUID);
	BackgroundOperationProgress = vBackgroundJob.Progress;
		
	For Each vMsg in vBackgroundJob.Messages Do
		If ListOfMessages.FindByValue(vMsg) = Undefined Then
			ListOfMessages.Add(vMsg);
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
		EndIf;
	EndDo;
	
	If vBackgroundJob.Status = "Error" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: '; ru = 'Ошибка выполнения фонового задания: '; de = 'Fehler beim Ausführen des Hintergrundjobs: '") + vBackgroundJob.Error);
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		CheckInOut_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled'; ru = 'Фоновое задание - отменено'; de = 'Hintergrundjob - abgebrochen'"));
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		CheckInOut_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Completed" Then
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		CheckInOut_Completed();
	EndIf;
EndProcedure // Attachable_CheckBackgroundJobs

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction // CheckBackgroundJobStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInOut_ShowProgressBar(pOperationName)
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Background operation in progress, you can continue to work in other forms  - '; ru = 'Выполняется фоновая операция, можете продолжать работать в других формах  - '; de = 'Die Hintergrundoperation läuft, Sie können weiterhin in anderen Formen arbeiten - '") + pOperationName;
	Items.BackgroundOperationProgress.Visible = True;
	Items.DocumentListIsInHouseCheckOut.Enabled = False;
	Items.DocumentListAllCheckOut.Enabled = False;
EndProcedure // CheckInOut_ShowProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInOut_HideProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = False;
	Items.DocumentListIsInHouseCheckOut.Enabled = True;
	Items.DocumentListAllCheckOut.Enabled = True;
EndProcedure // CheckInOut_HideProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInOut_Completed()
	CheckInOut_HideProgressBar();
	// Send notification to all open forms
	Notify("Subsystem.Accounts.Changed", MainRoomDoc, ThisForm);
	Notify("Document.ResourceReservation.Write", , ThisForm);
	// Notify that accommodation is changed
	Notify("Document.Accommodation.Write", MainRoomDoc, ThisForm);
	// Refresh lists
	vPage = "";
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else
		Return;
	EndIf;
	Items[vPage].Refresh();
	// Print folios for each checked out accommodation
	If AccList.Count() > 0 And tcOnServer.cmGetAttributeByRef(SelHotel, "PrintCustomerFolioAfterCheckout") Then
		PrintCustomerFolios();
	EndIf;
EndProcedure // CheckInOut_Completed

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintCustomerFolios()
	vLang = tcOnServer.cmGetSessionParametersAttribute("CurrentLanguage");
	If ValueIsFilled(vLang) Then
		vLangCode = tcOnServer.cmGetAttributeByRef(vLang, "Code");
		vPrintFormName = "AfterCheckoutFolioPrintForm" + Title(TrimAll(vLangCode));
		vPrintFormTypeRef = tcOnServer.cmGetAttributeByRef(SelHotel, vPrintFormName);
		If ValueIsFilled(vPrintFormTypeRef) Then
			vCurNumber = "";
			vCurGuestGroup = Undefined;
			For Each vAccListItem In AccList Do
				vCurAccRef = vAccListItem.Value;
				vStatusIsInHouse = CheckIfCheckOutSuccessfull(vCurAccRef);
				If Not vStatusIsInHouse Then
					vNumber = tcOnServer.cmGetAttributeByRef(vCurAccRef, "Number");
					vGuestGroup = tcOnServer.cmGetAttributeByRef(vCurAccRef, "GuestGroup");
					If vNumber <> vCurNumber Or vGuestGroup <> vCurGuestGroup Then
						vCurNumber = vNumber;
						vCurGuestGroup = vGuestGroup;
						// Get list of customer folios for this room
						vFoliosList = GetListOfCustomerFolios(vNumber, vGuestGroup);
						If vFoliosList.Count() > 0 Then
							vParams = New Structure("InputParameter, ObjectPrintingForm, Folios", vFoliosList.Get(0).Value, vPrintFormTypeRef, vFoliosList);
							OpenForm("Document.Folio.Form.tcFolioPrintForm", vParams, ThisForm, new UUID);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Print form is not specified for language '; ru='Не указана печатная форма для языка '; de='Druckformular ist nicht für die Sprache angegeben '") + Upper(vLangCode) + "!");
		EndIf;
	EndIf;
EndProcedure // PrintCustomerFolios

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetListOfCustomerFolios(pNumber, pGuestGroup)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.GuestGroup = &qGuestGroup
	|	AND Folio.ParentDoc.Number = &qNumber
	|	AND NOT Folio.DeletionMark
	|	AND NOT ISNULL(Folio.Customer.IsIndividual, TRUE)
	|
	|ORDER BY
	|	Folio.PointInTime";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qNumber", TrimR(pNumber));
	vFolios = vQry.Execute().Unload();
	vFoliosList = New ValueList();
	vFoliosList.LoadValues(vFolios.UnloadColumn("Ref"));
	Return vFoliosList;
EndFunction // GetListOfCustomerFolios

// -----------------------------------------------------------------------------
&AtServer
Function CheckIfCheckOutSuccessfull(pAccRef)
	vAccObj = pAccRef.GetObject();
	vAccObj.Read();
	Return vAccObj.AccommodationStatus.IsInHouse;
EndFunction // CheckIfCheckOutSuccessfull

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	vCheckOutDate = SelCheckOutDate;
	FilterStatusOnChangeAtServer(vCheckOutDate);
	// Run automatic in-house guests period of stay extension procedure
	If RunInHouseGuestsPeriodOfStayAutoExtension Then
		vFrequency = 300;
		If InHouseGuestsPeriodOfStayAutoExtensionFrequency <> 0 Then
			vFrequency = Round(60 * InHouseGuestsPeriodOfStayAutoExtensionFrequency, 0);
		EndIf;
		AttachIdleHandler("ExtendInHouseGuestsPeriodOfStay", vFrequency);
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtendInHouseGuestsPeriodOfStay() 
	vStructureMessage = tcOnClient.ExtendInHouseGuestsPeriodOfStay(SelHotel);
	If Not IsBlankString(vStructureMessage.Message) Then
		tcCommonFunctionOnClientServer.TextMessage(vStructureMessage.Message);
	EndIf;
	Notify("Subsystem.Accounts.Changed");
EndProcedure // ExtendInHouseGuestsPeriodOfStay

// -----------------------------------------------------------------------------
&AtServer
Procedure SetParametersDynamicList()
	vBalancesAreVisible = Not cmCheckUserPermissions("DoNotShowBalancesInLists");
	
	// Set columns appearance
	Items.DocumentListAllSumBalance.Visible = vBalancesAreVisible;
	Items.DocumentListAllSumBalanceCustomer.Visible = vBalancesAreVisible;
	Items.DocumentListIsInHouseSumBalance.Visible = vBalancesAreVisible;
	Items.DocumentListIsInHouseSumBalanceCustomer.Visible = vBalancesAreVisible;
	Items.DocumentListReservationClientSumBalance.Visible = vBalancesAreVisible;
	Items.DocumentListReservationCustomerSumBalance.Visible = vBalancesAreVisible;
	
	// Set parameters
	DocumentListALL.Parameters.SetParameterValue("qHotel",SelHotel);
	DocumentListALL.Parameters.SetParameterValue("qShowAllGuests", SelShowAllGuests);
	DocumentListALL.Parameters.SetParameterValue("qBalancesAreVisible", vBalancesAreVisible);
	
	DocumentListIsInHouse.Parameters.SetParameterValue("qHotel",SelHotel);
	DocumentListIsInHouse.Parameters.SetParameterValue("qShowAllGuests", SelShowAllGuests);
	DocumentListIsInHouse.Parameters.SetParameterValue("qBalancesAreVisible", vBalancesAreVisible);
	DocumentListIsInHouse.Parameters.SetParameterValue("qAccountingDate", BegOfDay(CurrentSessionDate()));
	DocumentListIsInHouse.Parameters.SetParameterValue("qShowExpectedRoomMovesOnly", ShowExpectedRoomMovesOnly);
	
	DocumentListReservation.Parameters.SetParameterValue("qHotel",SelHotel);
	DocumentListReservation.Parameters.SetParameterValue("qShowAllGuests", SelShowAllGuests);
	DocumentListReservation.Parameters.SetParameterValue("qBalancesAreVisible", vBalancesAreVisible);
	
	Title = NStr("en='Front office console: '; ru='Фронт-офис: '; de='Front-Office-Konsole: '") 
				+ ?(ValueIsFilled(SelHotel), Catalogs.Hotels.pmGetHotelPrintName(SelHotel, SessionParameters.CurrentLanguage), "");
EndProcedure //  SetParametersDynamicList()

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	vItem = Undefined;
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vItem = Items.DocumentListIsInHouse;
	ElsIf SelFilterStatus = 1 Then
		vItem = Items.DocumentListAll;
	Else
		vItem = Items.DocumentListReservation;
	EndIf;
	If pEventName = "System.Hotel.Changed" And pParameter <> SelHotel Then
		SelHotel = tcOnServer.cmGetCurrentHotelAttribute();
		SelRoom = Undefined;
		SelRoomClearing(Items.SelRoom, True);
		SelRoomType = Undefined;
		SelRoomTypeClearing(Items.SelRoomType, True);
		SetParametersDynamicList();
	ElsIf pEventName = "Document.Accommodation.Write" Or 
	      pEventName = "Document.Accommodation.WriteNew" Or 
	      pEventName = "Document.Reservation.Write" Or 
	      pEventName = "Document.Reservation.WriteNew" Or 
		  pEventName = "Document.Charge.Write" Or 
		  pEventName = "Document.Storno.Write" Or 
		  pEventName = "Document.Payment.Write" Or 
		  pEventName = "Document.Return.Write" Or 
		  pEventName = "Document.DepositTransfer.Write" Or 
		  pEventName = "Document.ChargeTransfer.Write" Or 
		  pEventName = "Subsystem.Accounts.Changed" Or
		  pEventName = "Catalog.GuestGroups.Changed" Then
		AttachIdleHandler("RefreshList", 1, True);
	ElsIf pEventName = "Document.Accommodation.ListForm.ExpectedArrival" Then
		If SelFilterStatus <> 2 Then
			SelFilterStatus = 2;
			FilterStatusOnChange(Items.FilterStatus);
		EndIf;
	ElsIf pEventName = "Document.Accommodation.ListForm.ExpectedDeparture" Then
		If SelFilterStatus <> 3 Then
			SelFilterStatus = 3;
			FilterStatusOnChange(Items.FilterStatus);
		EndIf;
	ElsIf pEventName = "Document.Accommodation.ListForm.InHouseGuests" Then
		If SelFilterStatus <> 0 Then
			SelFilterStatus = 0;
			FilterStatusOnChange(Items.FilterStatus);
		EndIf;
	ElsIf pEventName = "Document.Accommodation.ListForm.Archive" Then
		If SelFilterStatus <> 1 Then
			SelFilterStatus = 1;
			FilterStatusOnChange(Items.FilterStatus);
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshListAndTotals() Export
	If IsInputAvailable() Then
		SetParametersDynamicList();
	Else
		AttachIdleHandler("RefreshListAndTotals", 1, True);
	EndIf;
EndProcedure // RefreshListAndTotals

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshList() Export
	If IsInputAvailable() Then
		SetParametersDynamicList();
	Else
		AttachIdleHandler("RefreshList", 1, True);
	EndIf;
EndProcedure // RefreshListAndTotals

// -----------------------------------------------------------------------------
// Procedure - Attribute change at server
//
// Parameters:
//  pAttribute	 - as string name DataCompositionField 
//  pValue		 - ref item 
//  pComparisonType - Data Composition Comparison Type 
// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
			vPage = "DocumentListIsInHouse";
			vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		ElsIf SelFilterStatus = 1 Then
			vPage = "DocumentListAll";
			vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		Else 
			vPage = "DocumentListReservation";	
			vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		EndIf;	
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisForm[vPage], pAttribute, pValue, vComparisonType, , True);
	EndIf;
EndProcedure // AttributeChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;	
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(ThisForm[vPage], pAttribute, , , , False);
EndProcedure // ClearingAttributeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(Item)
	If ValueIsFilled(SelRoom) Then
		If tcOnServer.cmGetAttributeByRef(SelRoom, "IsFolder") Then
			AttributeChangeAtServer("Room", SelRoom, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("Room", SelRoom);
		EndIf;
		SkipOnRowActivateEvent = True;
	Else
		ClearingAttributeAtServer("Room");
	EndIf;
EndProcedure // SelRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeOnChange(Item)
	If ValueIsFilled(SelRoomType) Then
		If tcOnServer.cmGetAttributeByRef(SelRoomType, "IsFolder") Then
			AttributeChangeAtServer("RoomType", SelRoomType, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("RoomType", SelRoomType);
		EndIf;
	Else
		ClearingAttributeAtServer("RoomType");
	EndIf;
EndProcedure // SelRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(Item)
	CurGuestGroup = SelGuestGroup;
	If ValueIsFilled(SelGuestGroup) Then
		If ValueIsFilled(SelCustomer) Then
			SelCustomer = Undefined;
			ClearingAttributeAtServer("Customer");
		EndIf;
		If ValueIsFilled(SelRoom) Then
			SelRoom = Undefined;
			ClearingAttributeAtServer("Room");
		EndIf;
		If ValueIsFilled(SelRoomType) Then
			SelRoomType = Undefined;
			ClearingAttributeAtServer("RoomType");
		EndIf;
		If ValueIsFilled(SelCheckOutDate) Then
			SelCheckOutDate = '00010101';
			ClearingAttributeAtServer("CheckOutDate");
		EndIf;
		AttributeChangeAtServer("GuestGroup", SelGuestGroup);
	Else
		ClearingAttributeAtServer("GuestGroup");
	EndIf;
EndProcedure // SelGuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupClearing(Item, StandardProcessing)
	ClearingAttributeAtServer("GuestGroup");
EndProcedure // SelGuestGroupClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(Item)
	If ValueIsFilled(SelCustomer) Then
		If tcOnServer.cmGetAttributeByRef(SelCustomer, "IsFolder") Then
			AttributeChangeAtServer("Customer", SelCustomer, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("Customer", SelCustomer);
		EndIf;
	Else
		ClearingAttributeAtServer("Customer");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAgentOnChange(Item)
	If ValueIsFilled(SelAgent) Then
		If tcOnServer.cmGetAttributeByRef(SelAgent, "IsFolder") Then
			AttributeChangeAtServer("Agent", SelAgent, DataCompositionComparisonType.InHierarchy);
		Else
			AttributeChangeAtServer("Agent", SelAgent);
		EndIf;
	Else
		ClearingAttributeAtServer("Agent");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(Item)
	If ValueIsFilled(SelClient) Then
		AttributeChangeAtServer("Guest", SelClient);
	Else
		ClearingAttributeAtServer("Guest");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomClearing(Item, StandardProcessing)
	ClearingAttributeAtServer("Room");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeClearing(Item, StandardProcessing)
	ClearingAttributeAtServer("RoomType");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerClearing(Item, StandardProcessing)
	ClearingAttributeAtServer("Customer");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAgentClearing(Item, StandardProcessing)
	ClearingAttributeAtServer("Agent");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientClearing(Item, StandardProcessing)
	ClearingAttributeAtServer("Guest");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NewReservation(Command)
	vDocFormParameters = New Structure("Document", tcOnServer.cmGetDocumentItemRefByDocNumber("Reservation", "", True));
	OpenForm("Document.Reservation.ObjectForm", vDocFormParameters, ThisForm); 
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckIn(pCommand)
	vSelList = Items.DocumentListReservation.SelectedRows;
	If vSelList.Count() > 1 Then
		If Items.BackgroundOperationProgress.Visible Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Please wait while previous background job ends or select one room for check-in!'; 
			                      |ru='Пожалуйста подождите завершения работы активного фонового задания или выберите для поселения один номер!'; 
								  |de='Bitte warten Sie, bis der aktive Hintergrundjob abgeschlossen ist, oder wählen Sie eine Zimmer für die Anreise aus!'"));
			Return;
		Endif;
		PackageCheckIn();
	ElsIf vSelList.Count() = 1 Then
		vSelResRow = vSelList[0];
		CheckInByDoc(vSelResRow);
	Else	
		Return;
	EndIf;	
EndProcedure // CheckIn

// -----------------------------------------------------------------------------
&AtServer
Function GetDocumentsListToCheckIn()
	vDocsList = New ValueList();
	For Each vSelDocRef In Items.DocumentListReservation.SelectedRows Do
		If TypeOf(vSelDocRef) = Type("DocumentRef.Reservation") Then
			If vSelDocRef.Posted And (vSelDocRef.ReservationStatus.IsActive Or vSelDocRef.ReservationStatus.IsPreliminary) Then
				If ValueIsFilled(vSelDocRef.Room) And BegOfDay(vSelDocRef.CheckInDate) <= BegOfDay(CurrentSessionDate()) Then
					If SelShowAllGuests = 0 Then
						vOneRoomReservations = cmGetOneRoomReservations(vSelDocRef.Number, vSelDocRef.GuestGroup, vSelDocRef.CheckInDate, vSelDocRef.CheckOutDate, False);
						For Each vOneRoomReservationsRow In vOneRoomReservations Do
							If vDocsList.FindByValue(vOneRoomReservationsRow.Ref) = Undefined Then
								vDocsList.Add(vOneRoomReservationsRow.Ref);
							EndIf;
						EndDo;
					Else
						vDocsList.Add(vSelDocRef);
					EndIf;
				EndIf;
			EndIf;
		Endif;
	EndDo;
	Return vDocsList;
EndFunction // GetDocumentsListToCheckIn

// -----------------------------------------------------------------------------
&AtClient
Procedure PackageCheckIn()
	vDocsList = GetDocumentsListToCheckIn();
	If vDocsList.Count() > 0 Then
		// Do check-in in a background job
		vOperationName = NStr("en='Checking-in selected guests'; ru='Заселение выделенных гостей'; de='Gästen anreise'");
		
		ListOfMessages.Clear();
		
		vParameters = New Array;
		vParameters.Add(SelHotel);
		vParameters.Add(vDocsList);
		vParameters.Add(CurrentDate());
		vParameters.Add(False);
		vParameters.Add(tcOnServer.cmGetCurrentUserAttribute());
		
		vBackgroundJob = AsyncCalls.StartBackgroundJobWithRecordInRegister(SelHotel, vOperationName, "ProlongedOperations.AccommodationsList_CheckIn", vParameters);
		CurrentBackgroundJobUUID = vBackgroundJob.UUID;
		
		AttachIdleHandler("Attachable_CheckBackgroundJobs", 1, False);
	
		CheckInOut_ShowProgressBar(vOperationName);
	EndIf;
EndProcedure // PackageCheckIn

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInByDoc(pReservation)
	vSelResRow = pReservation;
	vMainRoomRef = GetMainDocRefReservation(vSelResRow);
	If vSelResRow <> Undefined Then
		vResult = CheckInAtServer(vMainRoomRef, false);
		If ValueIsFilled(vResult) Then
			If vResult = "DoQueryBox" Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You are checking-in by inactive reservation!';ru='Селите по не активной брони!';de='Sie bringen nicht nach einer aktiven Reservierung unter!'"), MessageStatus.Important);
			EndIf;
			vHotel = tcOnServer.cmGetAttributeByRef(vMainRoomRef, "Hotel");
			vHotelAccountingDate = '00010101';
			If ValueIsFilled(vHotel) Then
				vHotelAccountingDate = tcOnServer.cmGetAttributeByRef(vHotel, "AccountingDate");
			EndIf;
			If Not ValueIsFilled(vHotelAccountingDate) Then
				vHotelAccountingDate = BegOfDay(CurrentDate());
			EndIf;
			vResult = CheckInAtServer(vMainRoomRef, True);
			If ValueIsFilled(vResult) Then
				If TypeOf(vResult) = Type("ValueList") Then
					vQuestionWasAsked = False;
					vSelResList = New ValueList;
					vSkip = False;
					For Each vItem In vResult Do
						vCheckInDate = tcOnServer.cmGetAttributeByRef(vItem.Value, "CheckInDate");
						If vHotelAccountingDate <> BegOfDay(vCheckInDate) Then
							If Not vQuestionWasAsked Then
								vMessageText = NStr("en='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
								                    |de='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
								                    |ru='В выбранном списке брони есть документы с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!'");
								tcCommonFunctionOnClientServer.TextMessage(vMessageText, MessageStatus.Important);
								vQuestionWasAsked = True;
							EndIf;
						EndIf;
						vSelResList.Add(vItem.Value);
					EndDo; 
					// Check current reservation list deposits
					CheckReservationsDeposits(vSelResList);
					vResult = CheckInAtServer(vMainRoomRef, true, vSelResList);
					If ValueIsFilled(vResult) Then
						If TypeOf(vResult)=Type("Structure") Then
							// Open new accommodation and fill group table from the given list
							OpenForm("Document.Accommodation.Form.mcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisForm);
						ElsIf vResult <> "DoQueryBox" Then
							tcCommonFunctionOnClientServer.TextMessage(vResult);
						EndIf;
					EndIf;
				ElsIf TypeOf(vResult) = Type("Structure") Then
					// Open new accommodation and fill group table from the given list
					OpenForm("Document.Accommodation.Form.mcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisForm);
				ElsIf vResult <> "DoQueryBox" Then
					tcCommonFunctionOnClientServer.TextMessage(vResult);
				EndIf;
			ElsIf TypeOf(vResult) = Type("ValueList") Then
				vQuestionWasAsked = False;
				vSelResList = New ValueList;
				vSkip = False;
				For Each vItem In vResult Do
					vCheckInDate = tcOnServer.cmGetAttributeByRef(vItem.Value, "CheckInDate");
					If vHotelAccountingDate <> BegOfDay(vCheckInDate) Then
						If Not vQuestionWasAsked Then
							vMessageText = NStr("en='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
							                    |de='There are reservations with check-in date " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " in the list of reservations selected. This date differs from todays date " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!';
							                    |ru='В выбранном списке брони есть документы с датой заезда " + Format(vCheckInDate, "DF=dd.MM.yyyy") + " отличающейся от текущей даты " + Format(vHotelAccountingDate, "DF=dd.MM.yyyy") + "!'");
							tcCommonFunctionOnClientServer.TextMessage(vMessageText, MessageStatus.Important);
							vQuestionWasAsked = True;
						EndIf;
					EndIf;
					vSelResList.Add(vItem.Value);
				EndDo;
				// Check current reservation list deposits
				CheckReservationsDeposits(vSelResList);
				vResult = CheckInAtServer(vMainRoomRef, false, vSelResList);
				If ValueIsFilled(vResult) Then
					If TypeOf(vResult)=Type("Structure") Then
						// Open new accommodation and fill group table from the given list
						OpenForm("Document.Accommodation.Form.mcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisForm);
					ElsIf vResult <> "DoQueryBox" Then
						tcCommonFunctionOnClientServer.TextMessage(vResult);
					EndIf;
				EndIf;
			ElsIf TypeOf(vResult)=Type("Structure") Then
				// Open new accommodation and fill group table from the given list
				OpenForm("Document.Accommodation.Form.mcDocumentForm", New Structure("GuestsToCheckInList", vResult.ValueList.Copy()), ThisForm);
			ElsIf vResult <> "DoQueryBox" Then
				tcCommonFunctionOnClientServer.TextMessage(vResult);
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  CheckInByDoc 

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckReservationsDeposits(pResRef)
	vFolios = cmGetDocumentFoliosWithDebts(pResRef, True); // Deposits only
	If vFolios.Count() > 0 Then
		vDebtsMessage = NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF;
		For Each vFoliosRow In vFolios Do
			If ValueIsFilled(vFoliosRow.Folio) Then
				vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFoliosRow.Folio.Number) + " " + 
				TrimAll(vFoliosRow.Folio.Client) + NStr("ru=', номер ';en=', room ';de=', Zimmer '") + 
				TrimAll(vFoliosRow.Folio.Room) + NStr("ru=', период ';en=', period ';de=', Period '") + 
				Format(vFoliosRow.Folio.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
				Format(vFoliosRow.Folio.DateTimeTo, "DF='dd.MM.yy HH:mm'") + " = " + 
				cmFormatSum(vFoliosRow.SumBalance, vFoliosRow.Folio.FolioCurrency, "NZ=");
			Else
				vDebtsMessage = vDebtsMessage + Chars.LF + NStr("en='<Empty folio>';ru='<Пустое фолио>';de='<Leeres Konto>'") + " = " + cmFormatSum(vFoliosRow.SumBalance, "NZ=", , True);
			EndIf;
		EndDo;
		vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEPOSITS!';ru='ЕСТЬ ПРЕДОПЛАТА!';de='ES LIEGT EINE ANZAHLUNG VOR!'");
		tcCommonFunctionOnClientServer.TextMessage(vDebtsMessage);
		WriteLogEvent(NStr("en='Reservation.CheckDeposits';ru='Резервирование.ПроверкаДепозита';de='Reservation.CheckDeposits'"), EventLogLevel.Information, Metadata.Documents.Folio, , vDebtsMessage);
	EndIf;
	Return True;
EndFunction // CheckReservationsDeposits

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckInAtServer(pRef, pQueryBoxInactive = false, pSelResList = Undefined)
	// Build list of selected reservations. We will process reservations from the
	// one room only (or empty one)
	vSelRes = pRef;
	vStopCheckIn = False;
	If Not vSelRes.Posted Then
		vStopCheckIn = True;
	ElsIf Not ValueIsFilled(vSelRes.ReservationStatus) Then
		vStopCheckIn = True;
	ElsIf Not vSelRes.ReservationStatus.IsActive And vSelRes.ReservationStatus <> vSelRes.Hotel.NoShowReservationStatus Then
		vStopCheckIn = True;
	EndIf;
	If vStopCheckIn Then
		If Not cmCheckUserPermissions("HavePermissionToCheckInBasedOnInactiveReservations") And ValueIsFilled(vSelRes.Hotel) Then
			Return NStr("en='You do not have rights to check-in guests based on inactive reservation!';ru='Нет прав на размещение гостей по не активной брони!';de='Sie haben keine Rechte, Gäste nach nicht aktiven Reservierungen zu platzieren! '");
		ElsIf Not pQueryBoxInactive Then
			Return "DoQueryBox"
		EndIf;
	EndIf;
	If vSelRes.Posted Then
		vSelResList = New ValueList();
		vSelRows = GetOneRoomGuests(vSelRes);
		vQuestionWasAsked = False;
		vSkip = False;
		If pSelResList = Undefined Then
			For Each vRow In vSelRows Do
				If Not vRow.Ref.ReservationStatus.IsCheckIn Then
					vSelResList.Add(vRow.Ref, cmBuildAccommodationSortingPresentation(vRow.Ref));
				EndIf;
			EndDo;
		Else
			vSelResList = pSelResList;
		EndIf;
		If pSelResList = Undefined Then
			Return vSelResList;
		EndIf;
		If vSelResList.Count() = 0 Then
			Return NStr("en='Not found documents to check-in';ru='Не найдены документы для размещения';de='Dokumente für Unterbringungen wurde nicht gefunden'");
		Else
			vSelResList.SortByPresentation();
			vSelRes = vSelResList.Get(0).Value;
		EndIf;
		Return New Structure("ValueList", vSelResList);
	Else
		return NStr("en='Check-in is allowed for posted reservation only!';ru='Поселять можно только по проведенной брони!';de='Ein Check-In ist nur nach einer bearbeiteten Reservierung möglich!'");
	EndIf;
EndFunction // CheckInAction

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetOneRoomGuests(pRef)
	// Fill one room guests
	vQry = New Query;
	vQry.Text = "SELECT
	            |	Reservations.Ref AS Ref,
	            |	Reservations.CheckInDate AS CheckInDate,
	            |	Reservations.CheckOutDate AS CheckOutDate,
	            |	Reservations.Guest AS GuestRef,
	            |	Reservations.Guest.FullName AS Guest,
	            |	Reservations.AccommodationType AS AccommodationType,
	            |	0 AS AnnulReserv,
	            |	FALSE AS IsStatusChanged,
	            |	FALSE AS IsAnnulation,
	            |	TRUE AS IsGuest,
	            |	&qEmptyReservationStatusRef AS ReservationStatus
	            |FROM
	            |	Document.Reservation AS Reservations
	            |WHERE
	            |	Reservations.GuestGroup = &qGroup
	            |	AND (Reservations.Room = &qRoom
	            |				AND &qRoomIsFilled
	            |			OR Reservations.Number = &qNumber
	            |				AND NOT &qRoomIsFilled)
	            |	AND Reservations.Posted
	            |	AND NOT Reservations.DeletionMark
	            |	AND (Reservations.ReservationStatus.IsActive
	            |			OR Reservations.ReservationStatus.IsCheckIn
	            |			OR Reservations.ReservationStatus.IsPreliminary
	            |			OR Reservations.ReservationStatus.IsInWaitingList
	            |			OR Reservations.ReservationStatus = &qReservStatus)
	            |
	            |ORDER BY
	            |	Reservations.CheckInDate,
	            |	Reservations.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pRef.GuestGroup);
	vQry.SetParameter("qRoom", pRef.Room);
	vQry.SetParameter("qGuest", pRef.Guest);
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qReservStatus", pRef.ReservationStatus);
	vQry.SetParameter("qAccType", pRef.AccommodationType);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRef.Room));
	vQry.SetParameter("qNumber", pRef.Number);
	vQry.SetParameter("qEmptyReservationStatusRef", Catalogs.ReservationStatuses.EmptyRef());
	vQryResult = vQry.Execute().Unload();
	Return vQryResult;
EndFunction // GetOneRoomGuests

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetMainDocRefReservation(pRef)
	// Fill one room guests
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Reservations.Ref AS Ref,
	|	Reservations.Guest AS GuestRef
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.GuestGroup = &qGroup
	|	AND (Reservations.Room = &qRoom
	|				AND &qRoomIsFilled
	|			OR Reservations.Number = &qNumber
	|				AND NOT &qRoomIsFilled)
	|	AND Reservations.Posted
	|	AND NOT Reservations.DeletionMark
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsCheckIn
	|			OR Reservations.ReservationStatus.IsPreliminary
	|			OR Reservations.ReservationStatus.IsInWaitingList
	|			OR Reservations.ReservationStatus = &qReservStatus)
	|
	|ORDER BY
	|	Reservations.CheckInDate,
	|	Reservations.AccommodationType.SortCode";
	vQry.SetParameter("qGroup", pRef.GuestGroup);
	vQry.SetParameter("qRoom", pRef.Room);
	vQry.SetParameter("qReservStatus", pRef.ReservationStatus);
	vQry.SetParameter("qRoomIsFilled", ValueIsFilled(pRef.Room));
	vQry.SetParameter("qNumber", pRef.Number);
	vQryResult = vQry.Execute().Unload();
	If vQryResult.Count() > 0 Then
		Return vQryResult.Get(0).Ref;
	EndIf;
	Return pRef;
EndFunction // GetMainDocRef

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListIsInHouseSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vRowID = Undefined;
	If TypeOf(pSelectedRow) = Type("Array") Then
		If pSelectedRow.Count() = 1 Then
			vRowID = pSelectedRow.Get(0);
		EndIf;
	Else
		vRowID = pSelectedRow;
	EndIf;
	If vRowID <> Undefined Then
		vRowData = Items.DocumentListIsInHouse.RowData(vRowID);
		If vRowData <> Undefined Then
			pStandardProcessing = False;
			If Items.DocumentListIsInHouse.ChoiceMode Then
				NotifyChoice(vRowData.Ref);
			Else
				If pField.Name = "DocumentListIsInHouseGuestGroup" And ValueIsFilled(vRowData.GuestGroup) Then
					OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
				Else
					OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", vRowData.Ref));
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // DocumentListIsInHouseSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListAllSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vRowID = Undefined;
	If TypeOf(pSelectedRow) = Type("Array") Then
		If pSelectedRow.Count() = 1 Then
			vRowID = pSelectedRow.Get(0);
		EndIf;
	Else
		vRowID = pSelectedRow;
	EndIf;
	If vRowID <> Undefined Then
		vRowData = Items.DocumentListAll.RowData(vRowID);
		If vRowData <> Undefined Then
			pStandardProcessing = False;
			If Items.DocumentListAll.ChoiceMode Then
				NotifyChoice(vRowData.Ref);
			Else
				If pField.Name = "DocumentListAllGuestGroup" And ValueIsFilled(vRowData.GuestGroup) Then
					OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
				Else
					OpenForm("Document.Accommodation.ObjectForm", New Structure("Key", vRowData.Ref));
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // DocumentListAllSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListReservationSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vRowID = Undefined;
	If TypeOf(pSelectedRow) = Type("Array") Then
		If pSelectedRow.Count() = 1 Then
			vRowID = pSelectedRow.Get(0);
		EndIf;
	Else
		vRowID = pSelectedRow;
	EndIf;
	If vRowID <> Undefined Then
		vRowData = Items.DocumentListReservation.RowData(vRowID);
		If vRowData <> Undefined Then
			pStandardProcessing = False;
			If Items.DocumentListReservation.ChoiceMode Then
				NotifyChoice(vRowData.Ref);
			Else
				If pField.Name = "DocumentListReservationGuestGroup" And ValueIsFilled(vRowData.GuestGroup) Then
					OpenForm("Catalog.GuestGroups.Form.tcItemForm", New Structure("Key", vRowData.GuestGroup));
				Else
					OpenForm("Document.Reservation.ObjectForm", New Structure("Key", vRowData.Ref));
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // DocumentListReservationSelection

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetPaymentFolio(pAcc)
	If NOT ValueIsFilled(pAcc) Then
		Return Undefined;
	EndIf;
	vQ = New Query("SELECT
	               |	AccommodationChargingRules.ChargingFolio AS Folio,
	               |	AccommodationChargingRules.LineNumber AS LineNumber
	               |FROM
	               |	Document.Accommodation.ChargingRules AS AccommodationChargingRules
	               |WHERE
	               |	AccommodationChargingRules.Ref = &qAcc
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	GuestGroupsChargingRules.ChargingFolio,
	               |	GuestGroupsChargingRules.LineNumber
	               |FROM
	               |	Catalog.GuestGroups.ChargingRules AS GuestGroupsChargingRules
	               |WHERE
	               |	GuestGroupsChargingRules.Ref = &qGuestGroup
	               |
	               |ORDER BY
	               |	LineNumber");
	vQ.SetParameter("qAcc",pAcc);
	vQ.SetParameter("qGuestGroup",pAcc.GuestGroup);
	qResRows = vQ.Execute().Unload();
	vFolio = Undefined;
	For Each qRes In qResRows Do
		vFolio = qRes.Folio;
		vFolioObj = vFolio.GetObject();
		vBalance = vFolioObj.pmGetBalance();
		If vBalance > 0 Then
			Break;
		EndIf;
	EndDo;
	If vBalance > 0 Then
		Return vFolio;
	EndIf;
	For Each qRes In qResRows Do
		vFolio = qRes.Folio;
		Return vFolio;
	EndDo;
	Return Undefined;
EndFunction // GetPaymentFolio

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetForeignerRegistryRecordsList(pAccRef, rMessage)
	rMessage = "";
	vRecordsList = New ValueList();
	vRecords = pAccRef.GetObject().pmGetForeignerRegistryRecords();
	If vRecords = Undefined Then
		rMessage = NStr("ru='Гость " + String(pAccRef.Guest) + " не иностранец!'; 
		                |de='Gast " + String(pAccRef.Guest) + " sind nicht fremd ist!'; 
		                |en='" + String(pAccRef.Guest) + " guest is not a foreigner!'");
	ElsIf vRecords.Count() > 0 Then
		vRecordsList.LoadValues(vRecords.UnloadColumn("ForeignerRegistryRecord"));
	EndIf;
	Return vRecordsList;
EndFunction // GetForeignerRegistryRecordsList

// -----------------------------------------------------------------------------
&AtClient
Function GetCurrentRowRef()
	vRef = Undefined;
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;	
	vSelList = Items[vPage].SelectedRows;
	If vSelList.Count() > 0 Then
		vRef = vSelList[0];
	EndIf;	
	
	Return vRef
EndFunction //  GetCurrentRowRef()

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure CreateGroupProformaInvoice(pCommand)
	vRef = GetCurrentRowRef();
	OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", New Structure("basis", tcOnServer.cmGetAttributeByRef(vRef, "GuestGroup")));
EndProcedure // CreateGroupProformaInvoice

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenProformaInvoiceList(Command)
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vPage = "DocumentListIsInHouse";
	ElsIf SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	Else 
		vPage = "DocumentListReservation";	
	EndIf;	
		
	vRef = Items[vPage].CurrentRow;

	OpenForm("Document.ProformaInvoice.ListForm", New Structure("SelGuestGroup", tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup")), ThisForm);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInHouseGuests(pCommand)
	vRef = GetCurrentRowRef();
	#IF NOT MobileClient THEN
		OpenForm("Document.Accommodation.ListForm", New Structure("SelGuestGroup,SelFilterStatus, AllGuests", tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup"),0, 1), ThisForm);
	#ELSE
		OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("SelGuestGroup,SelFilterStatus, AllGuests", tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup"),0, 1), ThisForm);	
	#ENDIF
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenReservations(pCommand)
	vRef = GetCurrentRowRef();
	#IF NOT MobileClient THEN 
		OpenForm("Document.Reservation.ListForm", New Structure("SelGuestGroup,SelFilterStatus", tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup"),0), ThisForm);
	#ELSE
		OpenForm("Document.Reservation.Form.mcReservationListForm", New Structure("SelGuestGroup,SelFilterStatus", tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup"),0), ThisForm);	
	#ENDIF
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenChangeHistoryReservation(Command)
	vRef = GetCurrentRowRef();
	vFrm = OpenForm("InformationRegister.ReservationChangeHistory.ListForm", New Structure("Filter", New Structure("Reservation", vRef)), ThisForm);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenChangeHistoryAccommodation(pCommand)
	vRef = GetCurrentRowRef();
	vFrm = OpenForm("InformationRegister.AccommodationChangeHistory.ListForm", New Structure("Accommodation", vRef), ThisForm);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFoliosIsInHouse(Command)
	vRef = GetCurrentRowRef();
	If Not vRef = Undefined Then
		vParametersStructure = New Structure("DocRef", vRef);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure",vParametersStructure), , vRef);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Task(pCommand)
	vRef = GetCurrentRowRef();
	stParam = New Structure("SetParamObject", vRef); 
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam, ThisForm);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Pay(Command)
	vRef = GetCurrentRowRef();
	// Get payment folio
	vFolio = GetPaymentFolio(vRef);
	If ValueIsFilled(vFolio) Then
		// Open payment form
		OpenForm("Document.Payment.ObjectForm", New Structure("Basis", vFolio), ThisForm);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenForeignerRegistryRecord(Command)
	vRef = GetCurrentRowRef();
	OpenForeignerRegistryRecordForm(vRef);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenForeignerRegistryRecordForm(pAccRef)
	If Not ValueIsFilled(pAccRef) Then
		Return;
	EndIf;
	// Check if current guest record exists. If yes then open it
	vMessage = "";
	vRecords = GetForeignerRegistryRecordsList(pAccRef, vMessage);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
	// Get last one from the list
	vDocRef = Undefined;
	If vRecords <> Undefined And vRecords.Count() > 0 Then
		vDocRef = vRecords.Get(vRecords.Count()-1).Value;
	EndIf;
	vFrm = Undefined;
	If ValueIsFilled(vDocRef) Then
		vFrm = OpenForm("Document.ForeignerRegistryRecord.ObjectForm", New Structure("Key", vDocRef), ThisForm, vDocRef);
	Else
		vFrm = OpenForm("Document.ForeignerRegistryRecord.ObjectForm", New Structure("Основание", pAccRef), ThisForm, pAccRef);
	EndIf;
EndProcedure // OpenForeignerRegistryRecordForm

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeRoomWizard(pCommand)
	vRef = GetCurrentRowRef();
	// Add other one room accommodations
	vAccList = New ValueList;
	AddOneRoomAccommodations(vAccList, vRef);
	vOtherRoomGuests = New Array;
	For Each vAccListItem In vAccList Do
		vAccRef = vAccListItem.Value;
		vGuestRef = tcOnServer.cmGetAttributeByRef(vAccRef, "Guest");
		vAccTypeRef = tcOnServer.cmGetAttributeByRef(vAccRef, "AccommodationType");
		vOtherRoomGuests.Add(New Structure("Ref, GuestRef, AccommodationType", vAccRef, vGuestRef, vAccTypeRef));
	EndDo;
	OpenForm("CommonForm.tcChangeRoomWizard", New Structure("DocRef, GuestTable", vRef, vOtherRoomGuests), ThisForm);
EndProcedure // ChangeRoomWizard

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInvoicesList(pCommand)
	vRef = GetCurrentRowRef();
	OpenForm("Document.Settlement.ListForm", New Structure("SelGuestGroup", tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup")), ThisForm);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGroupSettlement(pCommand)
	vRef = GetCurrentRowRef();
	vGuestGroup = tcOnServer.cmGetAttributeByRef(vRef,"GuestGroup");
	vMessage = "";
	vInvoice = Undefined;
	// Try to  search for unposted invoice
	vUnpostedInvoices = GetUnpostedGroupInvoices(vGuestGroup);
	If vUnpostedInvoices.Count() > 0 Then
		vInvoice = vUnpostedInvoices.Get(0).Value;
	EndIf;
	// Fill new or refill existing unposted invoice
	vResult = GuestGroupFillSettlement(vGuestGroup, vMessage, vInvoice);
	If vResult = -1 Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	Else
		If vResult = 0 Then
			vInvList = GetListOfGroupInvoices(vGuestGroup);
			If vInvList.Count() = 0 Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage);
			ElsIf vInvList.Count() = 1 Then
				vInvoice = vInvList.Get(0).Value;
			Else
				If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
					vPage = "DocumentListIsInHouse";
				ElsIf SelFilterStatus = 1 Then
					vPage = "DocumentListAll";
				Else 
					vPage = "DocumentListReservation";	
				EndIf;	
				vRow = Items[vPage].CurrentRow;
				vNotifyDescription = New NotifyDescription("PrintInvoiceAfterInvoiceSelection", ThisForm);
				vParams = New Structure("ValueList, MultipleChoice, Title", vInvList, False);
				OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
			EndIf;
		EndIf;
		If ValueIsFilled(vInvoice) Then
			PrintInvoice(vInvoice);
		EndIf;
	EndIf;
EndProcedure // PrintGroupSettlement

// -----------------------------------------------------------------------------
&AtServer
Function GetUnpostedGroupInvoices(pGuestGroup)
	vDocs = pGuestGroup.GetObject().pmGetUnpostedSettlements();
	vUnpostedInvoicesList = New ValueList();
	vUnpostedInvoicesList.LoadValues(vDocs.UnloadColumn("Invoice"));
	For Each vUnpostedInvoicesListItem In vUnpostedInvoicesList Do
		vInv = vUnpostedInvoicesListItem.Value;
		vUnpostedInvoicesListItem.Presentation = TrimAll(vInv) + " - " + cmFormatSum(vInv.SumDue, vInv.AccountingCurrency);
	EndDo;
	Return vUnpostedInvoicesList;
EndFunction // GetUnpostedGroupInvoices

// -----------------------------------------------------------------------------
&AtServer
Function GuestGroupFillSettlement(pGuestGroup, rMessage = "", rInvoice = Undefined)
	vResult = -1;
	rMessage = "";
	If ValueIsFilled(pGuestGroup) Then
		If rInvoice = Undefined Then
			WriteLogEvent(NStr("en='Document.Create';ru='Документ.СозданиеНового';de='Document.Create'"), EventLogLevel.Information, Metadata.Documents.Settlement, Documents.Settlement.EmptyRef(), NStr("en='Create new';ru='Создание нового';de='Erstellung eines neuen'"));
			vDoc = Documents.Settlement.CreateDocument();
		Else
			vDoc = rInvoice.GetObject();
		EndIf;
		If ValueIsFilled(pGuestGroup.ClientDoc) Then
			vDoc.Fill(pGuestGroup.ClientDoc);
		EndIf;
		vDoc.Fill(pGuestGroup);
		If vDoc.Services.Count() > 0 Then
			vDoc.Write(DocumentWriteMode.Posting);
			rInvoice = vDoc.Ref;
			vResult = 1;
		Else
			rMessage = NStr("en='Nothing to fill invoice for!';ru='Нет начислений для акта!';de='Nichts, um die Rechnung zu füllen!'");
			vResult = 0;
		EndIf;
	Else
		rMessage = NStr("en='No group is selected!';ru='Не выбрана группа!';de='Kein Gruppe ist gewählt!'");
	EndIf;
	Return vResult;
EndFunction // GuestGroupFillSettlement

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintInvoice(pInvoice)
	vLang = Undefined;
	vCustomer = tcOnServer.cmGetAttributeByRef(pInvoice, "AccountingCustomer");
	If ValueIsFilled(vCustomer) Then
		vLang = tcOnServer.cmGetAttributeByRef(vCustomer, "Language");
	EndIf;
	OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language", pInvoice, vLang), ThisForm, pInvoice);
EndProcedure // PrintInvoice

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintInvoiceAfterInvoiceSelection(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		vInvoice = pItem.Value;
		PrintInvoice(vInvoice);
	EndIf;
EndProcedure // PrintInvoiceAfterInvoiceSelection

// -----------------------------------------------------------------------------
&AtServer
Function GetListOfGroupInvoices(pGuestGroup)
	vSettlements = pGuestGroup.GetObject().pmGetSettlements();
	vList = New ValueList();
	vList.LoadValues(vSettlements.UnloadColumn("Invoice"));
	For Each vListItem In vList Do
		vInv = vListItem.Value;
		vListItem.Presentation = TrimAll(vInv) + " - " + cmFormatSum(vInv.SumDue, vInv.AccountingCurrency);
	EndDo;
	Return vList;
EndFunction // GetListOfGroupInvoices

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DocumentListIsInHouseOnGetDataAtServer(pItemName, pSettings, pRows)
	// Balances
	vSelShowAllGuests = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qShowAllGuests"));
	vSelShowAllGuests = ?(vSelShowAllGuests = Undefined, 0, vSelShowAllGuests.Value);
	vBalancesAreVisible = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qBalancesAreVisible"));
	vBalancesAreVisible = ?(vBalancesAreVisible = Undefined, False, vBalancesAreVisible.Value);
	If vBalancesAreVisible Then
		vList = pRows.GetKeys();
		If vSelShowAllGuests = 0 Then
			vBalances = GetBalancesByRooms(vList);
		Else
			vBalances = GetBalancesByGuests(vList);
		EndIf;
	EndIf;
	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		// Balances
		If vBalancesAreVisible Then
			If vSelShowAllGuests = 0 Then
				vDocNumber = vRowValue.Data.RefNumber;
				vBalances.Reset();
				If vBalances.FindNext(New Structure("DocNumber", vDocNumber)) Then
					vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
					vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
					vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
				EndIf;
			Else
				vDocRef = vRowValue.Data.Ref;
				vBalances.Reset();
				If vBalances.FindNext(New Structure("DocRef", vDocRef)) Then
					vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
					vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
					vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
				ElsIf TypeOf(vDocRef) = Type("DocumentRef.Accommodation") And ValueIsFilled(vDocRef.Reservation) Then
					vBalances.Reset();
					If vBalances.FindNext(New Structure("DocRef", vDocRef.Reservation)) Then
						vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
						vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
						vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
					EndIf;
				EndIf;
			EndIf;
			If vRowValue.Data["ClientLimitBalance"] <> 0 Then
				vClientSumBalanceAppearance = vRowValue.Appearance.Get("ClientSumBalance");
				If vClientSumBalanceAppearance <> Undefined Then
					vBalanceText = Format(vRowValue.Data["ClientSumBalance"], "NFD=2") + Chars.LF + Format(-vRowValue.Data["ClientLimitBalance"], "NFD=2");
					vClientSumBalanceAppearance.SetParameterValue("Text", vBalanceText);
					If (vRowValue.Data["ClientSumBalance"] - vRowValue.Data["ClientLimitBalance"]) <= 0 Then
						vClientSumBalanceAppearance.SetParameterValue("TextColor", WebColors.Green);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Add room move
		vRoomAppearance = vRowValue.Appearance.Get("Room");
		If vRoomAppearance <> Undefined Then
			vRoom = vRowValue.Data["Room"];
			vRoomTo = vRowValue.Data["RoomTo"];
			If ValueIsFilled(vRoomTo) And vRoom <> vRoomTo Then
				vRoomText = TrimAll(vRoom) + " -> " + TrimAll(vRoomTo);
				vRoomAppearance.SetParameterValue("Text", vRoomText);
				vRoomAppearance.SetParameterValue("BackColor", WebColors.Yellow);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the customer colors
		vCustomerColorHexString = TrimAll(vRowValue.Data["CustomerColorHexString"]);
		If Not IsBlankString(vCustomerColorHexString) Then
			vCustomerAppearance = vRowValue.Appearance.Get("Customer");
			If vCustomerAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vCustomerColorHexString);
				vCustomerAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the agent colors
		vAgentColorHexString = TrimAll(vRowValue.Data["AgentColorHexString"]);
		If Not IsBlankString(vAgentColorHexString) Then
			vAgentAppearance = vRowValue.Appearance.Get("Agent");
			If vAgentAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vAgentColorHexString);
				vAgentAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the guest group colors
		vGuestGroupColorHexString = TrimAll(vRowValue.Data["GuestGroupColorHexString"]);
		If Not IsBlankString(vGuestGroupColorHexString) Then
			vGuestGroupAppearance = vRowValue.Appearance.Get("GuestGroup");
			If vGuestGroupAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vGuestGroupColorHexString);
				vGuestGroupAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the discount card discount type colors
		vClientTypeColorHexString = TrimAll(vRowValue.Data["ClientTypeColorHexString"]);
		If Not IsBlankString(vClientTypeColorHexString) Then
			vClientTypeAppearance = vRowValue.Appearance.Get("ClientTypeCode");
			If vClientTypeAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vClientTypeColorHexString);
				vClientTypeAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // DocumentListIsInHouseOnGetDataAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DocumentListAllOnGetDataAtServer(pItemName, pSettings, pRows)
	// Balances
	vSelShowAllGuests = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qShowAllGuests"));
	vSelShowAllGuests = ?(vSelShowAllGuests = Undefined, 0, vSelShowAllGuests.Value);
	vBalancesAreVisible = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qBalancesAreVisible"));
	vBalancesAreVisible = ?(vBalancesAreVisible = Undefined, False, vBalancesAreVisible.Value);
	If vBalancesAreVisible Then
		vList = pRows.GetKeys();
		If vSelShowAllGuests = 0 Then
			vBalances = GetBalancesByRooms(vList);
		Else
			vBalances = GetBalancesByGuests(vList);
		EndIf;
	EndIf;
	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		// Balances
		If vBalancesAreVisible Then
			If vSelShowAllGuests = 0 Then
				vDocNumber = vRowValue.Data.RefNumber;
				vBalances.Reset();
				If vBalances.FindNext(New Structure("DocNumber", vDocNumber)) Then
					vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
					vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
					vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
				EndIf;
			Else
				vDocRef = vRowValue.Data.Ref;
				vBalances.Reset();
				If vBalances.FindNext(New Structure("DocRef", vDocRef)) Then
					vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
					vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
					vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
				ElsIf TypeOf(vDocRef) = Type("DocumentRef.Accommodation") And ValueIsFilled(vDocRef.Reservation) Then
					vBalances.Reset();
					If vBalances.FindNext(New Structure("DocRef", vDocRef.Reservation)) Then
						vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
						vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
						vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
					EndIf;
				EndIf;
			EndIf;
			If vRowValue.Data["ClientLimitBalance"] <> 0 Then
				vClientSumBalanceAppearance = vRowValue.Appearance.Get("ClientSumBalance");
				If vClientSumBalanceAppearance <> Undefined Then
					vBalanceText = Format(vRowValue.Data["ClientSumBalance"], "NFD=2") + Chars.LF + Format(-vRowValue.Data["ClientLimitBalance"], "NFD=2");
					vClientSumBalanceAppearance.SetParameterValue("Text", vBalanceText);
					If (vRowValue.Data["ClientSumBalance"] - vRowValue.Data["ClientLimitBalance"]) <= 0 Then
						vClientSumBalanceAppearance.SetParameterValue("TextColor", WebColors.Green);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the customer colors
		vCustomerColorHexString = TrimAll(vRowValue.Data["CustomerColorHexString"]);
		If Not IsBlankString(vCustomerColorHexString) Then
			vCustomerAppearance = vRowValue.Appearance.Get("Customer");
			If vCustomerAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vCustomerColorHexString);
				vCustomerAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the agent colors
		vAgentColorHexString = TrimAll(vRowValue.Data["AgentColorHexString"]);
		If Not IsBlankString(vAgentColorHexString) Then
			vAgentAppearance = vRowValue.Appearance.Get("Agent");
			If vAgentAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vAgentColorHexString);
				vAgentAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the guest group colors
		vGuestGroupColorHexString = TrimAll(vRowValue.Data["GuestGroupColorHexString"]);
		If Not IsBlankString(vGuestGroupColorHexString) Then
			vGuestGroupAppearance = vRowValue.Appearance.Get("GuestGroup");
			If vGuestGroupAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vGuestGroupColorHexString);
				vGuestGroupAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the discount card discount type colors
		vClientTypeColorHexString = TrimAll(vRowValue.Data["ClientTypeColorHexString"]);
		If Not IsBlankString(vClientTypeColorHexString) Then
			vClientTypeAppearance = vRowValue.Appearance.Get("ClientTypeCode");
			If vClientTypeAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vClientTypeColorHexString);
				vClientTypeAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // DocumentListAllOnGetDataAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetBalancesByRooms(pList, pIsReservation = False)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.Number AS Number,
	|	Accommodations.Hotel AS Hotel
	|INTO AccommodationList
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Ref IN(&qList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Ref AS Ref,
	|	Accommodations.Hotel AS Hotel,
	|	Accommodations.Number AS Number
	|INTO TabDocs
	|FROM
	|	Document.Accommodation AS Accommodations
	|		INNER JOIN AccommodationList AS AccommodationList
	|		ON Accommodations.Number = AccommodationList.Number
	|			AND Accommodations.Hotel = AccommodationList.Hotel
	|
	|UNION ALL
	|
	|SELECT
	|	Reservations.Ref,
	|	Reservations.Hotel,
	|	Reservations.Number
	|FROM
	|	Document.Reservation AS Reservations
	|		INNER JOIN AccommodationList AS AccommodationList
	|		ON Reservations.Number = AccommodationList.Number
	|			AND Reservations.Hotel = AccommodationList.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Folio.Ref AS Ref,
	|	TabDocs.Number AS ParentDocNumber,
	|	ISNULL(Customers.IsIndividual, TRUE) AS IsIndividual
	|INTO FolioListByMainGuests
	|FROM
	|	Document.Folio AS Folio
	|		INNER JOIN TabDocs AS TabDocs
	|		ON Folio.ParentDoc = TabDocs.Ref
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.FolioParentDocNumber AS DocNumber,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance
	|FROM
	|	(SELECT
	|		FolioListByMainGuests.ParentDocNumber AS FolioParentDocNumber,
	|		CASE
	|			WHEN FolioListByMainGuests.IsIndividual
	|				THEN ClientAccountsBalance.SumBalance
	|			ELSE 0
	|		END AS ClientSumBalance,
	|		CASE
	|			WHEN FolioListByMainGuests.IsIndividual
	|				THEN -ClientAccountsBalance.LimitBalance
	|			ELSE 0
	|		END AS ClientLimitBalance,
	|		CASE
	|			WHEN FolioListByMainGuests.IsIndividual
	|				THEN 0
	|			ELSE ClientAccountsBalance.SumBalance
	|		END AS CustomerSumBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				,
	|				FolioCurrency = Hotel.FolioCurrency
	|					AND Folio IN
	|						(SELECT
	|							FolioListByMainGuests.Ref AS Ref
	|						FROM
	|							FolioListByMainGuests AS FolioListByMainGuests)) AS ClientAccountsBalance
	|			INNER JOIN FolioListByMainGuests AS FolioListByMainGuests
	|			ON ClientAccountsBalance.Folio = FolioListByMainGuests.Ref) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.FolioParentDocNumber";
	vQry.SetParameter("qList", pList);
	vBalances = vQry.Execute().Select();
	Return vBalances;
EndFunction // GetBalancesByRooms

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetBalancesByGuests(pList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Ref,
	|	Folio.ParentDoc AS ParentDoc,
	|	ISNULL(Customers.IsIndividual, TRUE) AS IsIndividual
	|INTO FolioListByAllGuests
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|	AND Folio.ParentDoc IN(&qList)
	|
	|UNION
	|
	|SELECT
	|	Folio.Ref,
	|	Folio.ParentDoc,
	|	ISNULL(Customers.IsIndividual, TRUE)
	|FROM
	|	Document.Folio AS Folio
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|	AND CAST(Folio.ParentDoc AS Document.Accommodation).ParentDoc IN (&qList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.FolioParentDoc AS DocRef,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance
	|FROM
	|	(SELECT
	|		FolioListByAllGuests.ParentDoc AS FolioParentDoc,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN ClientAccountsBalance.SumBalance
	|			ELSE 0
	|		END AS ClientSumBalance,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN -ClientAccountsBalance.LimitBalance
	|			ELSE 0
	|		END AS ClientLimitBalance,
	|		CASE
	|			WHEN FolioListByAllGuests.IsIndividual
	|				THEN 0
	|			ELSE ClientAccountsBalance.SumBalance
	|		END AS CustomerSumBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				,
	|				FolioCurrency = Hotel.FolioCurrency
	|					AND Folio IN
	|						(SELECT
	|							FolioListByAllGuests.Ref AS Ref
	|						FROM
	|							FolioListByAllGuests AS FolioListByAllGuests)) AS ClientAccountsBalance
	|			INNER JOIN FolioListByAllGuests AS FolioListByAllGuests
	|			ON ClientAccountsBalance.Folio = FolioListByAllGuests.Ref) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.FolioParentDoc";
	vQry.SetParameter("qList", pList);
	vBalances = vQry.Execute().Select();
	vBalances.Reset();
	Return vBalances;
EndFunction // GetBalancesByGuests

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetReservationBalancesByRooms(pList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Number AS Number,
	|	Reservations.Hotel AS Hotel
	|INTO ReservationList
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Ref IN(&qList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Ref AS Ref,
	|	Accommodations.Hotel AS Hotel,
	|	Accommodations.Number AS Number
	|INTO TabDocs
	|FROM
	|	Document.Accommodation AS Accommodations
	|		INNER JOIN ReservationList AS ReservationList
	|		ON Accommodations.Number = ReservationList.Number
	|			AND Accommodations.Hotel = ReservationList.Hotel
	|
	|UNION ALL
	|
	|SELECT
	|	Reservations.Ref,
	|	Reservations.Hotel,
	|	Reservations.Number
	|FROM
	|	Document.Reservation AS Reservations
	|		INNER JOIN ReservationList AS ReservationList
	|		ON Reservations.Number = ReservationList.Number
	|			AND Reservations.Hotel = ReservationList.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Folio.Ref AS Ref,
	|	TabDocs.Number AS ParentDocNumber,
	|	ISNULL(Customers.IsIndividual, TRUE) AS IsIndividual
	|INTO FolioListByMainGuests
	|FROM
	|	Document.Folio AS Folio
	|		INNER JOIN TabDocs AS TabDocs
	|		ON Folio.ParentDoc = TabDocs.Ref
	|		LEFT JOIN Catalog.Customers AS Customers
	|		ON Folio.Customer = Customers.Ref
	|WHERE
	|	NOT Folio.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.FolioParentDocNumber AS DocNumber,
	|	SUM(AccountsBalance.ClientSumBalance) AS ClientSumBalance,
	|	SUM(AccountsBalance.ClientLimitBalance) AS ClientLimitBalance,
	|	SUM(AccountsBalance.CustomerSumBalance) AS CustomerSumBalance
	|FROM
	|	(SELECT
	|		FolioListByMainGuests.ParentDocNumber AS FolioParentDocNumber,
	|		CASE
	|			WHEN FolioListByMainGuests.IsIndividual
	|				THEN ClientAccountsBalance.SumBalance
	|			ELSE 0
	|		END AS ClientSumBalance,
	|		CASE
	|			WHEN FolioListByMainGuests.IsIndividual
	|				THEN -ClientAccountsBalance.LimitBalance
	|			ELSE 0
	|		END AS ClientLimitBalance,
	|		CASE
	|			WHEN FolioListByMainGuests.IsIndividual
	|				THEN 0
	|			ELSE ClientAccountsBalance.SumBalance
	|		END AS CustomerSumBalance
	|	FROM
	|		AccumulationRegister.Accounts.Balance(
	|				,
	|				FolioCurrency = Hotel.FolioCurrency
	|					AND Folio IN
	|						(SELECT
	|							FolioListByMainGuests.Ref AS Ref
	|						FROM
	|							FolioListByMainGuests AS FolioListByMainGuests)) AS ClientAccountsBalance
	|			INNER JOIN FolioListByMainGuests AS FolioListByMainGuests
	|			ON ClientAccountsBalance.Folio = FolioListByMainGuests.Ref) AS AccountsBalance
	|
	|GROUP BY
	|	AccountsBalance.FolioParentDocNumber";
	vQry.SetParameter("qList", pList);
	vBalances = vQry.Execute().Select();
	Return vBalances;
EndFunction // GetReservationBalancesByRooms

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DocumentListReservationOnGetDataAtServer(pItemName, pSettings, pRows)
	// Balances
	vSelShowAllGuests = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qShowAllGuests"));
	vSelShowAllGuests = ?(vSelShowAllGuests = Undefined, 0, vSelShowAllGuests.Value);
	vBalancesAreVisible = pSettings.DataParameters.FindParameterValue(New DataCompositionParameter("qBalancesAreVisible"));
	vBalancesAreVisible = ?(vBalancesAreVisible = Undefined, False, vBalancesAreVisible.Value);
	vBalances = Undefined;
	If vBalancesAreVisible Then
		vList = pRows.GetKeys();
		If vSelShowAllGuests = 0 Then
			vBalances = GetReservationBalancesByRooms(vList);
		Else
			vBalances = GetBalancesByGuests(vList);
		EndIf;
	EndIf;
	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		// Balances
		If vBalancesAreVisible Then
			If vBalances <> Undefined Then
				If vSelShowAllGuests = 0 Then
					vDocNumber = vRowValue.Data.RefNumber;
					vBalances.Reset();
					If vBalances.FindNext(New Structure("DocNumber", vDocNumber)) Then
						vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
						vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
						vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
					EndIf;
				Else
					vDocRef = vRowValue.Data.Ref;
					vBalances.Reset();
					If vBalances.FindNext(New Structure("DocRef", vDocRef)) Then
						vRowValue.Data["ClientSumBalance"] = vBalances.ClientSumBalance;
						vRowValue.Data["CustomerSumBalance"] = vBalances.CustomerSumBalance;
						vRowValue.Data["ClientLimitBalance"] = vBalances.ClientLimitBalance;
					EndIf;
				EndIf;
			EndIf;
			If vRowValue.Data["ClientLimitBalance"] <> 0 Then
				vClientSumBalanceAppearance = vRowValue.Appearance.Get("ClientSumBalance");
				If vClientSumBalanceAppearance <> Undefined Then
					vBalanceText = Format(vRowValue.Data["ClientSumBalance"], "NFD=2") + Chars.LF + Format(-vRowValue.Data["ClientLimitBalance"], "NFD=2");
					vClientSumBalanceAppearance.SetParameterValue("Text", vBalanceText);
					If (vRowValue.Data["ClientSumBalance"] - vRowValue.Data["ClientLimitBalance"]) <= 0 Then
						vClientSumBalanceAppearance.SetParameterValue("TextColor", WebColors.Green);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		vGuestFullNameAppearance = vRowValue.Appearance.Get("GuestFullName");
		If vGuestFullNameAppearance <> Undefined Then
			vGuestFullNameAppearance.SetParameterValue("Font", New Font(StyleFonts.MobileImportantFont,,8));
		EndIf;
		vRoomAppearance = vRowValue.Appearance.Get("Room");
		If vRoomAppearance <> Undefined Then
			vRoomAppearance.SetParameterValue("Font", New Font(StyleFonts.MobileImportantFont,,8));
		EndIf;
		vClientSumBalanceAppearance = vRowValue.Appearance.Get("ClientSumBalance");
		If vClientSumBalanceAppearance <> Undefined Then
			vClientSumBalanceAppearance.SetParameterValue("Font", New Font(StyleFonts.MobileImportantFont,,8));
		EndIf;
		vCustomerSumBalanceAppearance = vRowValue.Appearance.Get("CustomerSumBalance");
		If vCustomerSumBalanceAppearance <> Undefined Then
			vCustomerSumBalanceAppearance.SetParameterValue("Font", New Font(StyleFonts.MobileImportantFont,,8));
		EndIf;
		// Set cell back color for the reservations according to the customer colors
		vCustomerColorHexString = TrimAll(vRowValue.Data["CustomerColorHexString"]);
		If Not IsBlankString(vCustomerColorHexString) Then
			vCustomerAppearance = vRowValue.Appearance.Get("Customer");
			If vCustomerAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vCustomerColorHexString);
				vCustomerAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the agent colors
		vAgentColorHexString = TrimAll(vRowValue.Data["AgentColorHexString"]);
		If Not IsBlankString(vAgentColorHexString) Then
			vAgentAppearance = vRowValue.Appearance.Get("Agent");
			If vAgentAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vAgentColorHexString);
				vAgentAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the guest group colors
		vGuestGroupColorHexString = TrimAll(vRowValue.Data["GuestGroupColorHexString"]);
		If Not IsBlankString(vGuestGroupColorHexString) Then
			vGuestGroupAppearance = vRowValue.Appearance.Get("GuestGroup");
			If vGuestGroupAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vGuestGroupColorHexString);
				vGuestGroupAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the reservation status
		vReservationStatusColorHexString = TrimAll(vRowValue.Data["ReservationStatusColorHexString"]);
		If Not IsBlankString(vReservationStatusColorHexString) Then
			vReservationStatusAppearance = vRowValue.Appearance.Get("ReservationStatus");
			vGuaranteeTypeCodeAppearance = vRowValue.Appearance.Get("GuaranteeTypeCode");
			If vReservationStatusAppearance <> Undefined Or vGuaranteeTypeCodeAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vReservationStatusColorHexString);
				If vReservationStatusAppearance <> Undefined Then
					vReservationStatusAppearance.SetParameterValue("BackColor", vColor);
				EndIf;
				If vGuaranteeTypeCodeAppearance <> Undefined Then
					vGuaranteeTypeCodeAppearance.SetParameterValue("BackColor", vColor);
				EndIf;
			EndIf;
		EndIf;
		// Set cell back color for the reservations according to the discount card discount type colors
		vClientTypeColorHexString = TrimAll(vRowValue.Data["ClientTypeColorHexString"]);
		If Not IsBlankString(vClientTypeColorHexString) Then
			vClientTypeAppearance = vRowValue.Appearance.Get("ClientTypeCode");
			If vClientTypeAppearance <> Undefined Then
				vColor = tcOnServer.HexToColor(vClientTypeColorHexString);
				vClientTypeAppearance.SetParameterValue("BackColor", vColor);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // DocumentListReservationOnGetDataAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListIsInHouseOnActivateRow(pItem)
	vGuestGroup = Undefined;
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		If Not Items.DocumentListIsInHouseSelectedDocumentActions.Enabled Then
			Items.DocumentListIsInHouseSelectedDocumentActions.Enabled = True;
		EndIf;
		vGuestGroup = vCurData.GuestGroup;
	Else
		If Items.DocumentListIsInHouseSelectedDocumentActions.Enabled Then
			Items.DocumentListIsInHouseSelectedDocumentActions.Enabled = False;
		EndIf;
	EndIf;
	If vGuestGroup <> CurGuestGroup Then
		CurGuestGroup = vGuestGroup;
		If SkipOnRowActivateEvent Then
			SkipOnRowActivateEvent = False;
			Return;
		EndIf;
	EndIf;
EndProcedure // DocumentListIsInHouseOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListAllOnActivateRow(pItem)
	vGuestGroup = Undefined;
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		If Not Items.DocumentListAllSelectedDocumentActions.Enabled Then
			Items.DocumentListAllSelectedDocumentActions.Enabled = True;
		EndIf;
		vGuestGroup = vCurData.GuestGroup;
	Else
		If Items.DocumentListAllSelectedDocumentActions.Enabled Then
			Items.DocumentListAllSelectedDocumentActions.Enabled = False;
		EndIf;
	EndIf;
	If vGuestGroup <> CurGuestGroup Then
		CurGuestGroup = vGuestGroup;
		If SkipOnRowActivateEvent Then
			SkipOnRowActivateEvent = False;
			Return;
		EndIf;
	EndIf;
EndProcedure // DocumentListAllOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListReservationOnActivateRow(pItem)
	vGuestGroup = Undefined;
	vCurData = pItem.CurrentData;
	If vCurData <> Undefined Then
		If Not Items.DocumentListReservationSelectedDocumentActions.Enabled Then
			Items.DocumentListReservationSelectedDocumentActions.Enabled = True;
		EndIf;
		vGuestGroup = vCurData.GuestGroup;
	Else
		If Items.DocumentListReservationSelectedDocumentActions.Enabled Then
			Items.DocumentListReservationSelectedDocumentActions.Enabled = False;
		EndIf;
	EndIf;
	If vGuestGroup <> CurGuestGroup Then
		CurGuestGroup = vGuestGroup;
		If SkipOnRowActivateEvent Then
			SkipOnRowActivateEvent = False;
			Return;
		EndIf;
	EndIf;
EndProcedure // DocumentListReservationOnActivateRow

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFunctionsButtonReservation()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectFormActions.Ref,
	|	ObjectFormActions.Code AS Code,
	|	ObjectFormActions.PredefinedDataName,
	|	ObjectFormActions.IsDefault AS IsDefault
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	NOT ObjectFormActions.DeletionMark
	|	AND ObjectFormActions.ObjectType = &ObjectType
	|	AND ObjectFormActions.IsActive = TRUE
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code";
	vQuery.SetParameter("ObjectType", Documents.Reservation.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	vSelectionRecords = vQueryResult.Select();
	ActionsReservation.Clear();
	While vSelectionRecords.Next() Do
		If vSelectionRecords.PredefinedDataName = "" 
			or vSelectionRecords.PredefinedDataName = "ReservationSendMyFolioSMS"
			or vSelectionRecords.PredefinedDataName = "ReservationFillOrder"
			or vSelectionRecords.PredefinedDataName = "ReservationGuestGroupFillInvoice" 
			or vSelectionRecords.PredefinedDataName = "ReservationFillInvoice" Then
			vNewRow = ActionsReservation.Add();
			vNewRow.Action = vSelectionRecords.Ref;
			vNewRow.IsDefault = vSelectionRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("FuncReservation"+vID);
			vCommand.Action = "FuncButtonClickReservation";
			If vSelectionRecords.IsDefault Then
				vStructure = New Structure("Title,CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "FuncReservation"+vID);
			Else
				vStructure = New Structure("Title,CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "FuncReservation"+vID);
			EndIf;
			

			tcOnServer.cmCreateItem(ThisForm, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefaultReservation1, Items.FormGroupFunctionsNotDefaultReservation1), "Func_Reservation_1_"+vID, "FormButton", vStructure);
		EndIf;
	EndDo;
EndProcedure // FillFunctionsButtonReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClickReservation(Command)
	vRowData = Items.DocumentListReservation.CurrentData;
	If vRowData <> Undefined Then
		vActionsNumber = StrReplace(Command.Name, "FuncReservation", "");
		vAction = GetActionForNumberReservation(vActionsNumber);
		
		If ValueIsFilled(vAction.ExternalProcessing) Then
		Else
			If vAction.PredefinedDataName = "ReservationFillInvoice" Then
				vParam = New Structure;
				vParam.Insert("ParentDoc", vRowData.Ref);
				OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisForm, True);	
			ElsIf vAction.PredefinedDataName = "ReservationGuestGroupFillInvoice" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.GuestGroup);
				OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisForm, True);
			ElsIf vAction.PredefinedDataName = "ReservationSendMyFolioSMS" Then
				SendWelcomeSMSReservation(vRowData.Ref);
			ElsIf vAction.PredefinedDataName = "ReservationFillOrder" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.Order.Form.DocumentForm", vParam, ThisForm, True);
			// Run data processor
			ElsIf ValueIsFilled(vAction.DataProcessor) Then     
				vReturnParameter = New Structure("Action, Data, FileName");
				If Not RunDataProcessor(vAction.DataProcessor, vRowData.Ref, True, vReturnParameter) Then
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to run data processor!';ru='Не удалось выполнить обработку!';de='Die Bearbeitung ist fehlgeschlagen!'"));
				Else
					If vReturnParameter <> Undefined And TypeOf(vReturnParameter) = Type("Structure") Then
						If vReturnParameter.Property("Action") And vReturnParameter.Action <> Undefined Then
							If vReturnParameter.Action = "ShowFile" Then
								vFileData = vReturnParameter.Data;
								GetFromTempStorage(vFileData).Write(TempFilesDir() + vReturnParameter.FileName);
								BeginRunningApplication(New NotifyDescription, TempFilesDir() + vReturnParameter.FileName);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='No data processor found for action!';ru='У действия не указан обработчик!';de='Bei der Aktion ist kein Bearbeiter angegeben!'"));
			EndIf;
		EndIf;   
	EndIf;   
EndProcedure // FuncButtonClickReservation

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFunctionsButtonAccommodation()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectFormActions.Ref,
	|	ObjectFormActions.Code AS Code,
	|	ObjectFormActions.PredefinedDataName,
	|	ObjectFormActions.IsDefault AS IsDefault
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	NOT ObjectFormActions.DeletionMark
	|	AND ObjectFormActions.ObjectType = &ObjectType
	|	AND ObjectFormActions.IsActive = TRUE
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code";
	vQuery.SetParameter("ObjectType", Documents.Accommodation.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	vSelectionRecords = vQueryResult.Select();
	ActionsAccommodation.Clear();
	While vSelectionRecords.Next() Do
		If vSelectionRecords.PredefinedDataName = "" 
			or vSelectionRecords.PredefinedDataName = "AccommodationFillOrder"
			or vSelectionRecords.PredefinedDataName = "AccommodationSendWelcomeSMS" 
			or vSelectionRecords.PredefinedDataName = "AccommodationFillClientFeedback" 
			or vSelectionRecords.PredefinedDataName = "AccommodationFillAccommodation" 
			or vSelectionRecords.PredefinedDataName = "AccommodationGuestGroupFillSettlement"
			or vSelectionRecords.PredefinedDataName = "AccommodationGuestGroupFillInvoice" 
			or vSelectionRecords.PredefinedDataName = "AccommodationFillInvoice" Then
			vNewRow = ActionsAccommodation.Add();
			vNewRow.Action = vSelectionRecords.Ref;
			vNewRow.IsDefault = vSelectionRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("FuncAccommodation"+vID);
			vCommand.Action = "FuncButtonClickAccommodation";
			If vSelectionRecords.IsDefault Then
				vStructure = New Structure("Title, CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "FuncAccommodation"+vID);
			Else
				vStructure = New Structure("Title, CommandName",
				TrimAll(vSelectionRecords.Code) + " " + cmNStr(vSelectionRecords.ref), "FuncAccommodation"+vID);
			EndIf;
			
			tcOnServer.cmCreateItem(ThisForm, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefaultAccommodation1, Items.FormGroupFunctionsNotDefaultAccommodation1), "Func_Accommodation_1_"+vID, "FormButton", vStructure);
			tcOnServer.cmCreateItem(ThisForm, ?(vSelectionRecords.IsDefault, Items.FormGroupFunctionsDefaultAccommodation2, Items.FormGroupFunctionsNotDefaultAccommodation2), "Func_Accommodation_2_"+vID, "FormButton", vStructure);
		EndIf;
	EndDo;
EndProcedure // FillFunctionsButtonAccommodation

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClickAccommodation(Command)
	vPage = "DocumentListIsInHouse";
	If SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	EndIf;
	vRowData = Items[vPage].CurrentData;
	If vRowData <> Undefined Then
		vActionsNumber = StrReplace(Command.Name, "FuncAccommodation", "");
		vAction = GetActionForNumberAccommodation(vActionsNumber);
		
		If ValueIsFilled(vAction.ExternalProcessing) Then
		Else
			If vAction.PredefinedDataName = "AccommodationSendWelcomeSMS" Then
				SendWelcomeSMSAccommodation(vRowData.Ref);
			ElsIf vAction.PredefinedDataName = "AccommodationFillClientFeedback" Then
				AccommodationFillClientFeedback(vRowData.Ref);
			ElsIf vAction.PredefinedDataName = "AccommodationFillAccommodation" Then
				vParam = New Structure;
				vParam.Insert("ParentAccommodation", vRowData.Ref);
				OpenForm("Document.Accommodation.Form.mcDocumentForm", vParam, , New UUID);
			ElsIf vAction.PredefinedDataName = "AccommodationGuestGroupFillInvoice" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.GuestGroup);
				OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisForm, True);	
			ElsIf vAction.PredefinedDataName = "AccommodationFillInvoice" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisForm, True);	
			ElsIf vAction.PredefinedDataName = "AccommodationGuestGroupFillSettlement" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.GuestGroup);
				OpenForm("Document.Settlement.Form.tcDocumentForm", vParam, ThisForm, True);	
			ElsIf vAction.PredefinedDataName = "AccommodationFillSettlement" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.Settlement.Form.tcDocumentForm", vParam, ThisForm, True);	
			ElsIf vAction.PredefinedDataName = "AccommodationFillOrder" Then
				vParam = New Structure;
				vParam.Insert("basis", vRowData.Ref);
				OpenForm("Document.Order.Form.DocumentForm",vParam,ThisForm,True);
			// Run data processor
			ElsIf ValueIsFilled(vAction.DataProcessor) Then     
				vReturnParameter = New Structure("Action, Data, FileName");
				If Not RunDataProcessor(vAction.DataProcessor, vRowData.Ref, True, vReturnParameter) Then
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to run data processor!';ru='Не удалось выполнить обработку!';de='Die Bearbeitung ist fehlgeschlagen!'"));
				Else
					If vReturnParameter <> Undefined And TypeOf(vReturnParameter) = Type("Structure") Then
						If vReturnParameter.Property("Action") And vReturnParameter.Action <> Undefined Then
							If vReturnParameter.Action = "ShowFile" Then
								vFileData = vReturnParameter.Data;
								GetFromTempStorage(vFileData).Write(TempFilesDir() + vReturnParameter.FileName);
								BeginRunningApplication(New NotifyDescription, TempFilesDir() + vReturnParameter.FileName);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='No data processor found for action!';ru='У действия не указан обработчик!';de='Bei der Aktion ist kein Bearbeiter angegeben!'"));
			EndIf;
		EndIf;   
	EndIf;   
EndProcedure // FuncButtonClickAccommodation

// -----------------------------------------------------------------------------
&AtServer
Function GetClientFeedback(pDoc)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientFeedback.Ref
	|FROM
	|	Document.ClientFeedback AS ClientFeedback
	|WHERE
	|	ClientFeedback.ParentDoc = &qParentDoc
	|	AND NOT ClientFeedback.DeletionMark
	|
	|ORDER BY
	|	ClientFeedback.PointInTime";
	vQry.SetParameter("qParentDoc", pDoc);
	vReviewDocs = vQry.Execute().Unload();
	If vReviewDocs.Count() > 0 Then
		Return vReviewDocs.Get(0).Ref;
	EndIf;
	Return Undefined;
EndFunction // GetClientFeedback

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationFillClientFeedback(pDocRef)
	If ValueIsFilled(pDocRef.Guest) Then
		// Try to find existing client feedback
		vFeedbackDoc = GetClientFeedback(pDocRef);
		If ValueIsFilled(vFeedbackDoc) Then
			OpenForm("Document.ClientFeedback.ObjectForm", New Structure("Key", vFeedbackDoc), ThisForm);
		Else
			OpenForm("Document.ClientFeedback.ObjectForm", New Structure("Basis", pDocRef), ThisForm);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Guest is not filled!'; ru='В размещении не указан гость!'; de='Gast ist nicht gefüllt!'"));
	EndIf;
EndProcedure // AccommodationFillClientFeedback

// -----------------------------------------------------------------------------
&AtServer
Function GetActionForNumberReservation(pActionsNumber)
	vActions = ActionsReservation.FindByID(Number(pActionsNumber)).Action;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vActions);
	vStruct.Insert("PredefinedDataName",vActions.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vActions.ExternalProcessing);
	vStruct.Insert("DataProcessor",vActions.DataProcessor);
	
	Return vStruct;
EndFunction // GetActionForNumberReservation

// -----------------------------------------------------------------------------
&AtServer
Function GetActionForNumberAccommodation(pActionsNumber)
	vActions = ActionsAccommodation.FindByID(Number(pActionsNumber)).Action;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vActions);
	vStruct.Insert("PredefinedDataName",vActions.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vActions.ExternalProcessing);
	vStruct.Insert("DataProcessor",vActions.DataProcessor);
	
	Return vStruct;
EndFunction // GetActionForNumberAccommodation

// -----------------------------------------------------------------------------
&AtServer
Function RunDataProcessor(pDataProcessor, pParameter, pIsInteractive = False, rReturnParameter)
	vPARAM = New Structure("InputParameter, OutputParameter", pParameter, rReturnParameter);
	vResult = cmRunDataProcessor(pDataProcessor, vPARAM, pIsInteractive);
	rReturnPameter = vPARAM.OutputParameter;
	Return vResult;
EndFunction // RunDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButtonReservation()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND ObjectPrintingForms.ObjectType = &ObjectType
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	vQuery.SetParameter("ObjectType", Documents.Reservation.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	vSelectionRecords = vQueryResult.Select(QueryResultIteration.ByGroups);
	PrintFormsReservation.Clear();
	vLang = Catalogs.Languages.EN;
	If ValueIsFilled(SelHotel) Then
		vLang = SelHotel.Language;
	EndIf;
	While vSelectionRecords.Next() Do
		vSelectionDetailRecords = vSelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = vSelectionRecords.Language or not ValueIsFilled(vSelectionRecords.Language) Then
			vParentLang1 = Items.FormGroupPrintingNotDefaultMainReservation1;
		ElsIf not vLang = vSelectionRecords.Language Then
			vParentLang1 = tcOnServer.cmCreateItem(ThisForm, Items.FormGroupPrintingNotDefaultExtraReservation1, "PrintReservation"+vSelectionRecords.Language+"1", "FormGroup", New Structure("Type,Title", FormGroupType.Popup, vSelectionRecords.Language));
		EndIf;
		
		While vSelectionDetailRecords.Next() Do
			If vSelectionDetailRecords.PredefinedDataName = "" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintHotelProduct" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestGroupHotelProducts"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestFormForm5" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestForm2Forms5" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestFormFreeForm"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestRegistrationForm"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestsFormsForm5"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestsForms2Forms5"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestsFormsFreeForm"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintGuestRegistrationForms"
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationEn"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationDe"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesEn"  		
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationWithServicesDe"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationEn"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationDe"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesEn"  		
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesDe" 
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextRu"  
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextEn"  		
				or vSelectionDetailRecords.PredefinedDataName = "ReservationPrintConfirmationRichTextDe" Then 
				vNewRow = PrintFormsReservation.Add();
				vNewRow.PrintForm = vSelectionDetailRecords.Ref;
				vNewRow.IsDefault = vSelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("PrintReservation"+vID);
				vCommand.Action = "PrintButtonClickReservation";
				If vSelectionDetailRecords.IsDefault Then
					vParent1 = Items.FormGroupPrintingDefaultReservation1;
				Else
					vParent1 = vParentLang1;
				EndIf;
				vStructure = New Structure("Title,CommandName", TrimAll(vSelectionDetailRecords.Code) + " " + cmNStr(vSelectionDetailRecords.ref), "PrintReservation"+vID);
				tcOnServer.cmCreateItem(ThisForm, vParent1, "Print_Reservation_1_"+vID, "FormButton", vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure // FillPrintingButtonReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClickReservation(Command)
	vRowData = Items.DocumentListReservation.CurrentData;
	If vRowData <> Undefined Then
		vPrintNumber = StrReplace(Command.Name, "PrintReservation", "");
		vPrintForm = GetPrintFormForNumberReservation(vPrintNumber);
		
		// Load external print form
		If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
			Try
				OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref, vRowData.Ref);
			Except
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
				vExternalProcessing = Undefined;
			EndTry;
		ElsIf ValueIsFilled(vPrintForm.Report) Then
			Try
				OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref, vRowData.Ref);
			Except
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
			EndTry;
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintHotelProduct" Or
			vPrintForm.PredefinedDataName = "ReservationPrintGuestGroupHotelProducts" Then
			PrintHotelProduct(vPrintForm.Language, vPrintForm.Ref, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationEn" Or
			  vPrintForm.PredefinedDataName = "ReservationPrintConfirmationDe" Then
			WasAlreadyPrint = True;
			vParams = New Structure("SelReservation, SelLanguage, SelObjectPrintForm", vRowData.Ref, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationForm", vParams, ThisForm);
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationEn" Or
			  vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationDe" Then
			vParams = new Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm, CloseOnOwnerClose, SelShowConfirmationForCurrentReservationOnly", 
			                        vRowData.Ref,
			                        , 
			                        tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
			                        vPrintForm.Ref,
			                        False,
			                        True);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationForm", vParams, ThisForm, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesEn" Or
			  vPrintForm.PredefinedDataName = "ReservationPrintConfirmationWithServicesDe" Then
			WasAlreadyPrint = True;
			vParams = New Structure("SelReservation, SelLanguage, SelObjectPrintForm", vRowData.Ref, tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"), vPrintForm.Ref);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationForm", vParams, ThisForm);
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesEn" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintCurrentDocConfirmationWithServicesDe" Then
			vParams = new Structure("SelReservation, SelReservationObj, SelLanguage, SelObjectPrintForm, CloseOnOwnerClose, SelShowConfirmationForCurrentReservationOnly", 
			                        vRowData.Ref,
			                        , 
			                        tcOnServer.cmGetAttributeByRef(vPrintForm.Ref, "Language"),
			                        vPrintForm.Ref,
			                        False,
			                        True);
			OpenForm("Document.Reservation.Form.tcReservationConfirmationWithServicesForm", vParams, ThisForm, New UUID());
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintGuestFormForm5" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintGuestForm2Forms5" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintGuestFormFreeForm" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintGuestRegistrationForm" Then
			WasAlreadyPrint = True;
			PrintGuestForm(vPrintForm.PredefinedDataName, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintGuestsFormsForm5" Or 
		      vPrintForm.PredefinedDataName = "ReservationPrintGuestsForms2Forms5" Or 
			  vPrintForm.PredefinedDataName = "ReservationPrintGuestsFormsFreeForm" Or 
			  vPrintForm.PredefinedDataName = "ReservationPrintGuestRegistrationForms" Then
			WasAlreadyPrint = True;
			PrintGuestsForms(vPrintForm.PredefinedDataName, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRichTextRu" Or
		      vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRichTextEn" Or
			  vPrintForm.PredefinedDataName = "ReservationPrintConfirmationRichTextDe" Then
			vParams = New Structure("InputParameter, ObjectPrintingForm", vRowData.Ref, vPrintForm.Ref);
			OpenForm("DataProcessor.ReservationConfirmationRichTextFormat.Form", vParams, ThisForm, New UUID());
		EndIf;
	EndIf;
EndProcedure // PrintButtonClickReservation

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButtonAccommodation()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND ObjectPrintingForms.ObjectType = &ObjectType
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	vQuery.SetParameter("ObjectType", Documents.Accommodation.EmptyRef());	
	vQueryResult = vQuery.Execute();	
	vSelectionRecords = vQueryResult.Select(QueryResultIteration.ByGroups);
	PrintFormsAccommodation.Clear();
	vLang = Catalogs.Languages.EN;
	If ValueIsFilled(SelHotel) Then
		vLang = SelHotel.Language;
	EndIf;
	While vSelectionRecords.Next() Do
		vSelectionDetailRecords = vSelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = vSelectionRecords.Language or not ValueIsFilled(vSelectionRecords.Language) Then
			vParentLang1 = Items.FormGroupPrintingNotDefaultMainAccommodation1;
			vParentLang2 = Items.FormGroupPrintingNotDefaultMainAccommodation2;
		ElsIf not vLang = vSelectionRecords.Language Then
			vParentLang1 = tcOnServer.cmCreateItem(ThisForm, Items.FormGroupPrintingNotDefaultExtraAccommodation1, "PrintAccommodation"+vSelectionRecords.Language+"1", "FormGroup", New Structure("Type,Title", FormGroupType.Popup, vSelectionRecords.Language));
			vParentLang2 = tcOnServer.cmCreateItem(ThisForm, Items.FormGroupPrintingNotDefaultExtraAccommodation2, "PrintAccommodation"+vSelectionRecords.Language+"2", "FormGroup", New Structure("Type,Title", FormGroupType.Popup, vSelectionRecords.Language));
		EndIf;
		
		While vSelectionDetailRecords.Next() Do
			If vSelectionDetailRecords.PredefinedDataName = "" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintHotelProduct" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestGroupHotelProducts" Or 
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestForm2Forms5" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestFormFreeForm" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestRegistrationForm" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestRegistrationForms" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestsForms2Forms5" Or
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestsFormsFreeForm" Or 
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestPersonalDataProcessingConsent" Or 
			   vSelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestRefusalToPayResortFee" Then
				vNewRow = PrintFormsAccommodation.Add();
				vNewRow.PrintForm = vSelectionDetailRecords.Ref;
				vNewRow.IsDefault = vSelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("PrintAccommodation"+vID);
				vCommand.Action = "PrintButtonClickAccommodation";
				If vSelectionDetailRecords.IsDefault Then
					vParent1 = Items.FormGroupPrintingDefaultAccommodation1;
					vParent2 = Items.FormGroupPrintingDefaultAccommodation2;
				Else
					vParent1 = vParentLang1;
					vParent2 = vParentLang2;
				EndIf;
				vStructure = New Structure("Title,CommandName", TrimAll(vSelectionDetailRecords.Code) + " " + cmNStr(vSelectionDetailRecords.ref), "PrintAccommodation"+vID);
				
				tcOnServer.cmCreateItem(ThisForm, vParent1, "Print_Accommodation_1_"+vID, "FormButton", vStructure);
				tcOnServer.cmCreateItem(ThisForm, vParent2, "Print_Accommodation_2_"+vID, "FormButton", vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure // FillPrintingButtonAccommodation

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClickAccommodation(Command)
	vPage = "DocumentListIsInHouse";
	If SelFilterStatus = 1 Then
		vPage = "DocumentListAll";
	EndIf;
	vRowData = Items[vPage].CurrentData;
	If vRowData <> Undefined Then
		vPrintNumber = StrReplace(Command.Name, "PrintAccommodation", "");
		vPrintForm = GetPrintFormForNumberAccommodation(vPrintNumber);
		
		// Load external print form
		If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
			Try
				OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref, vRowData.Ref);
			Except
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
				vExternalProcessing = Undefined;
			EndTry;
		ElsIf ValueIsFilled(vPrintForm.Report) Then
			Try
				OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref, vRowData.Ref);
			Except
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'")+Chars.LF+BriefErrorDescription(ErrorInfo()), MessageStatus.Attention);
			EndTry;
		ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintHotelProduct" Or
		      vPrintForm.PredefinedDataName = "AccommodationPrintGuestGroupHotelProducts" Then
			PrintHotelProduct(vPrintForm.Language, vPrintForm.Ref, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestForm2Forms5" Or 
		      vPrintForm.PredefinedDataName = "AccommodationPrintGuestFormFreeForm" Or
		      vPrintForm.PredefinedDataName = "AccommodationPrintGuestRegistrationForm" Then
			PrintGuestForm(vPrintForm.PredefinedDataName, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestsForms2Forms5" Or 
		      vPrintForm.PredefinedDataName = "AccommodationPrintGuestsFormsFreeForm" Or
		      vPrintForm.PredefinedDataName = "AccommodationPrintGuestRegistrationForms" Then
			PrintGuestsForms(vPrintForm.PredefinedDataName, vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestPersonalDataProcessingConsent" Then
			PrintGuestPersonalDataProcessingConsent(vRowData.Ref);
		ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestRefusalToPayResortFee" Then
			PrintGuestRefusalToPayResortFee(vRowData.Ref);
		EndIf;
	EndIf;
EndProcedure // PrintButtonClickAccommodation

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestPersonalDataProcessingConsent(pDocRef)
	vLang = Undefined;
	vGuest = tcOnServer.cmGetAttributeByRef(pDocRef, "Guest");
	If ValueIsFilled(vGuest) Then
		vLang = tcOnServer.cmGetAttributeByRef(vGuest, "Language");
	EndIf;
	vInputParameter = New ValueList();
	vInputParameter.Add(pDocRef);
	vPrtForm = PredefinedValue("Catalog.ObjectPrintingForms.AccommodationPrintGuestPersonalDataProcessingConsent");
	vParams = New Structure("InputParameter, ObjectPrintingForm, Lang", vInputParameter, vPrtForm, vLang);
	OpenForm("Document.Accommodation.Form.tcAccommodationPrintForm", vParams, ThisForm, new UUID);
EndProcedure // PrintGuestPersonalDataProcessingConsent

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestRefusalToPayResortFee(pDocRef)
	vLang = Undefined;
	If ValueIsFilled(pDocRef.Guest) Then
		vLang = tcOnServer.cmGetAttributeByRef(pDocRef.Guest, "Language");
	EndIf;
	vInputParameter = New ValueList();
	vInputParameter.Add(pDocRef);
	vPrtForm = PredefinedValue("Catalog.ObjectPrintingForms.AccommodationPrintGuestRefusalToPayResortFee");
	vParams = New Structure("InputParameter, ObjectPrintingForm, Lang", vInputParameter, vPrtForm, vLang);
	OpenForm("Document.Accommodation.Form.tcAccommodationPrintForm", vParams, ThisForm, new UUID);
EndProcedure // PrintGuestRefusalToPayResortFee

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestForm(pTypeOfPrintForm, pDocRef)
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", pTypeOfPrintForm);
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm", pDocRef, Undefined, vObjPrtForm), ThisForm, pDocRef);
EndProcedure // PrintGuestForm

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestsForms(pTypeOfPrintForm, pDocRef)
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", pTypeOfPrintForm);
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm", pDocRef, tcOnServer.cmGetAttributeByRef(pDocRef, "GuestGroup"), vObjPrtForm), ThisForm, pDocRef);
EndProcedure // PrintGuestsForms

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumberReservation(pActionsNumber)
	vPrintForms = PrintFormsReservation.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction // GetPrintFormForNumberReservation

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumberAccommodation(pActionsNumber)
	vPrintForms = PrintFormsAccommodation.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction // GetPrintFormForNumberAccommodation

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef, pDocRef)
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage"); 
	vName = ConnectExternalDataProcessor(vURL, "ExternalReservationConfirmationForm");
	vParams = New Structure("InputParameter, ObjectPrintingForm", pDocRef, pPrintFormTypeRef);;
	OpenForm("ExternalDataProcessor." + vName + ".Form", vParams);
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef, pDocRef)
	#If ThickClientOrdinaryApplication Then
		vExtRepData = pExtRepRef.ExternalProcessingStorage.Get();
		vExtRepPath = GetTempFileName(".erf");
		vExtRepData.Write(vExtRepPath);
		vExtRepObj = ExternalReports.Create(vExtRepPath, False);
		vStruct = New Structure("Document, ObjectPrintingForm", pDocRef, pPrintFormTypeRef);
		FillPropertyValues(vExtRepObj, vStruct);
		// Fill reference to the report catalog item
		vExtRepObj.Report = pPrintFormTypeRef.Report;
		// Load report catalog item attributes
		vExtRepObj.pmLoadReportAttributes(pDocRef);
		// Open report's default form
		vExtRepFrm = vExtRepObj.GetForm();
		vExtRepFrm.GenerateOnFormOpen = True;
		vExtRepFrm.Open();
		BeginDeletingFiles(New NotifyDescription, vExtRepPath); 
	#Else
		vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef,"Report"), "ExternalProcessingStorage"); 
		vName = ConnectExternalReport(vURL, "ExternalReportForm");
		vParams = New Structure("Document, ObjectPrintingForm", pDocRef, pPrintFormTypeRef);
		OpenForm("ExternalReport." + vName + ".Form", vParams);
	#EndIf
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintHotelProduct(pLang, pForm, pDocRef)
	#IF not webclient THEN
		vReport = Undefined;
		If ValueIsFilled(pForm.Report) Then
			vReport = cmBuildReportObject(pForm.Report);
		ElsIf ValueIsFilled(pForm.ExternalProcessing) Then
			vReport = cmGetExternalDataProcessorObject(pForm.ExternalProcessing);
		Else
			vReport = Reports.PrintHotelProducts.Create();
		EndIf;
		If pForm = Catalogs.ObjectPrintingForms.ReservationPrintHotelProduct Then
			vReport.Document = pDocRef;
		EndIf;
		vReport.GuestGroup = pDocRef.GuestGroup;
		Try
			vReport.Room = pDocRef.Room;
			vReport.CheckInDate = BegOfDay(pDocRef.CheckInDate);
		Except
		EndTry;
		vFrm = vReport.GetForm();
		vFrm.SelObjectPrintForm = pForm;
		vFrm.Open();
	#ENDIF
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function SendWelcomeSMSAtServerReservation(pDocRef)
	vMessage = "";
	vExtSys = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(pDocRef.Hotel);
	If NOT ValueIsFilled(vExtSys) Then
		// The integration with hotel365 is not set
		Return NStr("en = 'Integration with the hotel365 service is not configured'; de = 'Die Integration mit hotel365 ist nicht konfiguriert'; ru = 'Не настроена интеграция с сервисом hotel365'");
	EndIf;
	If NOT vExtSys.IsActive Then
		// The integration with hotel365 is switched off
		Return NStr("en = 'The Integration with hotel365 is switched off'; de = 'Die Integration mit hotel365 ist ausgeschaltet'; ru = 'Интеграция с hotel365 отключена'");
	EndIf;

	If ValueIsFilled(pDocRef.ReservationStatus) And (pDocRef.ReservationStatus.IsActive Or pDocRef.ReservationStatus.IsPreliminary) Then
		// Get list of reservations to send message to
		vDocsList = New ValueList();
		vDocsList.Add(pDocRef.Ref);
		// Send SMS to every guest in the list
		For Each vDocItem In vDocsList Do
			vDoc = vDocItem.Value;
			vHotel = vDoc.Hotel;
			vGuest = vDoc.Guest;
			vPhone = ?(Not IsBlankString(vDoc.Phone), TrimAll(vDoc.Phone), TrimAll(vGuest.Phone));
			If Not IsBlankString(vPhone) Then
				vResult = SMS.Hotel365_SendSMS(vHotel, vDoc, vPhone, vGuest);
				If Not vResult.Success Then
					For Each vErrorText In vResult.Errors Do
						vMessage = vMessage + ?(IsBlankString(vMessage), "", Chars.LF) + vErrorText;
					EndDo;
				EndIf;
			Else
				vMessage = vMessage + ?(IsBlankString(vMessage), "", Chars.LF) + NStr("en='Guest phone is not filled!'; ru='В брони не указан телефон гостя!'; de='Gast-Telefon ist nicht gefüllt!'");
			EndIf;
		EndDo;
	EndIf;
	Return vMessage;
EndFunction // SendWelcomeSMSAtServerReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure SendWelcomeSMSReservation(pDocRef)
	vMessage = SendWelcomeSMSAtServerReservation(pDocRef);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // SendWelcomeSMSReservation

// -----------------------------------------------------------------------------
&AtServer
Function SendWelcomeSMSAtServerAccommodation(pDocRef)
	vMessage = "";
	If ValueIsFilled(pDocRef.AccommodationStatus) And pDocRef.AccommodationStatus.IsActive And pDocRef.AccommodationStatus.IsInHouse Then
		
		vExtSys = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(pDocRef.Hotel);
		If Not ValueIsFilled(vExtSys) Then
			// The integration with hotel365 is not set
			Return NStr("en = 'Integration with the hotel365 service is not configured'; de = 'Die Integration mit hotel365 ist nicht konfiguriert'; ru = 'Не настроена интеграция с сервисом hotel365'");
		EndIf;
		If Not vExtSys.IsActive Then
			// The integration with hotel365 is switched off
			Return NStr("en = 'The Integration with hotel365 is switched off'; de = 'Die Integration mit hotel365 ist ausgeschaltet'; ru = 'Интеграция с hotel365 отключена'");
		EndIf;

		// Get list of accommodations to send message to
		vDocsList = New ValueList();
		vDocsList.Add(pDocRef.Ref);
		// Send SMS to every guest in the list
		For Each vDocItem In vDocsList Do
			vDoc = vDocItem.Value;
			vHotel = vDoc.Hotel;
			vGuest = vDoc.Guest;
			vPhone = ?(Not IsBlankString(vDoc.Phone), TrimAll(vDoc.Phone), TrimAll(vGuest.Phone));
			If Not IsBlankString(vPhone) Then
				vResult = SMS.Hotel365_SendSMS(vHotel, vDoc, vPhone, vGuest);
				If Not vResult.Success Then
					For Each vErrorText In vResult.Errors Do
						vMessage = vMessage + ?(IsBlankString(vMessage), "", Chars.LF) + vErrorText;
					EndDo;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vMessage;
EndFunction // SendWelcomeSMSAtServerAccommodation

// -----------------------------------------------------------------------------
&AtClient
Procedure SendWelcomeSMSAccommodation(pDocRef)
	vMessage = SendWelcomeSMSAtServerAccommodation(pDocRef);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // SendWelcomeSMSAccommodation

// -----------------------------------------------------------------------------
&AtServerNoContext
Function IsActiveReservation(pReservation)
	If pReservation.Posted And (pReservation.ReservationStatus.IsActive Or pReservation.ReservationStatus.IsPreliminary) Then
		If BegOfDay(pReservation.CheckOutDate) >= BegOfDay(CurrentSessionDate()) Then
			If pReservation.RoomQuantity = 1 Then
				Return True;
			EndIf;
		EndIf;
	EndIf;
	Return False;
EndFunction // IsActiveReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomAssignment(pCommand)
	If Not ValueIsFilled(SelHotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Hotel should be selected!'; ru='Гостиница должна быть выбрана!'; de='Hotel sollte ausgewählt werden!'"));
		Return;
	EndIf;
	
	vCheckInDate = SelCheckInDate;
	If Not ValueIsFilled(vCheckInDate) Then
		vCheckInDate = BegOfDay(CurrentDate());
	EndIf;
	
	If Items.DocumentListReservation.SelectedRows.Count() > 1 Then
		vReservations = New ValueList();
		For Each vRowIndex In Items.DocumentListReservation.SelectedRows Do
			vRowData = Items.DocumentListReservation.RowData(vRowIndex);
			If ValueIsFilled(vRowData.AccommodationTemplate) Then
				If IsActiveReservation(vRowData.Ref) Then
					vReservations.Add(vRowData.Ref);
				EndIf;
			EndIf;
		EndDo;
		OpenForm("Document.Reservation.Form.tcRoomAssignmentForm", New Structure("SelHotel, SelReservations", SelHotel, vReservations), ThisForm);
	ElsIf ValueIsFilled(vCheckInDate) Then
		OpenForm("Document.Reservation.Form.tcRoomAssignmentForm", New Structure("SelHotel, SelCheckInDate", SelHotel, BegOfDay(vCheckInDate)), ThisForm);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Please specify either check-in date filter or select more then one reservation in the list!'; 
		                      |ru='Пожалуйста либо укажите отбор по дате заезда либо выделите в списке более одной брони!'; 
							  |de='Bitte wählen Sie Anreisedatum-Filter oder wählen Sie mehr als eine Reservierung in der Liste aus!'"));
	EndIf;
EndProcedure // RoomAssignment

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowDirectPostings(pCommand)
	If SelFilterStatus = 0 Or SelFilterStatus = 3 Then
		vSelDocRef = Items.DocumentListIsInHouse.CurrentRow;
		If vSelDocRef <> Undefined Then
			vRoom = tcOnServer.cmGetAttributeByRef(vSelDocRef, "Room");
			vClient = tcOnServer.cmGetAttributeByRef(vSelDocRef, "Guest");
			#IF NOT MobileClient THEN
				OpenForm("CommonForm.tcDirectPostingsForm", New Structure("Room, Client", vRoom, vClient), , vRoom);
			#ELSE
				OpenForm("CommonForm.mcDirectPostingsForm", New Structure("Room, Client", vRoom, vClient), , vRoom);	
			#ENDIF
		EndIf;
	EndIf;
EndProcedure // ShowDirectPostings

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowFiletGroup(pCommand)
	Items.FilterGroup.Visible = Not Items.FilterGroup.Visible; 
	Items.ShowFiletGroup.Check = Items.FilterGroup.Visible;
EndProcedure // ShowFiletGroup

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectArrivals(pCommand)
	SelFilterStatus = 2;
	FilterStatusOnChangeAtServer();	
EndProcedure // SelectArrivals

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectDepartures(pCommand)
	SelFilterStatus = 3;
	FilterStatusOnChangeAtServer();
EndProcedure // SelectDepartures

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectInHouse(pCommand)
	SelFilterStatus = 0;
	FilterStatusOnChangeAtServer();
EndProcedure // SelectInHouse

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectArchive(pCommand)
	SelFilterStatus = 1;
	FilterStatusOnChangeAtServer();
EndProcedure // SelectArchive

// -----------------------------------------------------------------------------
&AtClient
Procedure DocumentListIsInHouseRefreshRequestProcessing()
	SetParametersDynamicList();	
EndProcedure // DocumentListIsInHouseRefreshRequestProcessing

&AtClient
Procedure DocumentListAllRefreshRequestProcessing()
	SetParametersDynamicList();
EndProcedure // DocumentListAllRefreshRequestProcessing

&AtClient
Procedure DocumentListReservationRefreshRequestProcessing()
	SetParametersDynamicList();	
EndProcedure // DocumentListReservationRefreshRequestProcessing

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetClientDataScanDocument(pDocRef)
	vDoc = Undefined;
	// Run query to check whether client data scans were already created
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	ClientDataScans.Ref AS Ref
	|FROM
	|	Document.ClientDataScans AS ClientDataScans
	|WHERE
	|	ClientDataScans.ParentDoc = &qParentDoc
	|	AND (ClientDataScans.Guest = &qClient
	|			OR &qClientIsEmpty)
	|	AND NOT ClientDataScans.DeletionMark
	|
	|ORDER BY
	|	ClientDataScans.Posted DESC,
	|	ClientDataScans.PointInTime DESC";
	vQry.SetParameter("qParentDoc", pDocRef);
	vQry.SetParameter("qClient", pDocRef.Guest);
	vQry.SetParameter("qClientIsEmpty", Not ValueIsFilled(pDocRef.Guest));
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vDoc = vDocs.Get(0).Ref;
	ElsIf ValueIsFilled(pDocRef.Guest) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT TOP 1
		|	ClientDataScans.Ref AS Ref
		|FROM
		|	Document.ClientDataScans AS ClientDataScans
		|WHERE
		|	ClientDataScans.Guest = &qClient
		|	AND ClientDataScans.Hotel = &qHotel
		|	AND NOT ClientDataScans.DeletionMark
		|
		|ORDER BY
		|	ClientDataScans.Posted DESC,
		|	ClientDataScans.PointInTime DESC";
		vQry.SetParameter("qClient", pDocRef.Guest);
		vQry.SetParameter("qHotel", pDocRef.Hotel);
		vDocs = vQry.Execute().Unload();
		If vDocs.Count() > 0 Then
			vDoc = vDocs.Get(0).Ref;
		EndIf;
	EndIf;
	Return vDoc;
EndFunction // GetClientDataScanDocument

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAccommodationByReservation(pRef)
	Return cmGetAccommodationByReservation(pRef);
EndFunction // GetAccommodationByReservation 

// -----------------------------------------------------------------------------
&AtClient
Procedure ScanDocuments(pCommand)
	vRef = GetCurrentRowRef();
	If ValueIsFilled(vRef) And (TypeOf(vRef) = Type("DocumentRef.Accommodation") Or TypeOf(vRef) = Type("DocumentRef.Reservation")) Then
		// Check if there is accommodation for this reservation
		If TypeOf(vRef) = Type("DocumentRef.Reservation") Then
			vAccRef = GetAccommodationByReservation(vRef);
			If ValueIsFilled(vAccRef) Then
				vRef = vAccRef;
			EndIf;
		EndIf;
		// Try to find existing client data scan document
		vScanRef = GetClientDataScanDocument(vRef);
		If ValueIsFilled(vScanRef) Then
			vRefArr = tcOnServer.cmGetAtributeAsArray(vRef);
			OpenForm("Document.ClientDataScans.ObjectForm", New Structure("Key, Guest, ParentDoc, GuestGroup, Room", vScanRef, vRefArr.Guest, vRef, vRefArr.GuestGroup, vRefArr.Room), ThisObject, vRef);
		Else
			OpenForm("Document.ClientDataScans.ObjectForm", New Structure("basis", vRef), ThisObject, vRef);
		EndIf;
	EndIf;
EndProcedure // ScanDocuments
